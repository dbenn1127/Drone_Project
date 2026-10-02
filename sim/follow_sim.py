"""
follow_sim.py - Follow a simulated moving target with a simulated quadcopter.

Roadmap step 4: the follow controller in ArduPilot SITL, with no camera. A fake
target walks a known path; each loop the script computes range and bearing to
it, the same two numbers the camera code (perception/live_track.py) produces.
Built in stages:
    a. Fake target + range/bearing printout, drone hovering   <- current stage
    b. Yaw control: turn to face the target
    c. Forward speed: hold the standoff distance
    d. Limits and keep-out zone
    e. Logging and 3D replay

Built from pattern_flight.py (sections 1-5 are the same harness).

WHAT IT DOES
    1. Connects to the drone and waits for its heartbeat.
    2. Asks the drone to stream position, battery, and GPS data at 10 Hz.
    3. Defines helper functions used by the rest of the script.
    4. Runs go/no-go checks, asks you to confirm, then arms in GUIDED mode.
    5. Commands a takeoff.
    6. Climbs, then follows the fake target for FOLLOW_SECONDS, then lands.

HOW TO RUN
    Start Mission Planner's Multirotor simulation first, then in Anaconda Prompt:
        cd sim
        python follow_sim.py              (connects to the simulator)

WHO DOES WHAT
    This script plays two roles, and they follow different rules:
      - TEST HARNESS (sections 4-5, and the landing): stands in for the pilot.
        It arms, takes off, and lands, which only the operator may do on the
        real system.
      - FOLLOW LOGIC (the "follow" phase): stands in for the companion computer.
        It must obey SAF-2: send velocity and yaw-rate commands only, never
        arm, take off, land, or change mode.
    ArduPilot, the autopilot, does all the actual flying.

REQUIREMENTS THIS SCRIPT WILL PRODUCE EVIDENCE FOR
    CTL-1  Keep target within ±10° of centerline           (stage b onward)
    CTL-2  Hold 8 m standoff within ±2 m                   (stage c onward)
    CTL-3  Velocity + yaw rate only, >= 10 Hz, 5 m/s, 60°/s (stages b-d)
    CTL-4  No altitude commands                            (stage b onward)
    SAF-4  Never command motion within 5 m of the target   (stage d)

OUTPUT
    follow_log.csv in this folder (gitignored; regenerated every run): one row
    per position update, with time, position (lat/lon and meters north/east of
    home), altitude, climb rate, heading, and flight phase.
"""

# ---------------------------------------------------------------------------
# IMPORTS
# ---------------------------------------------------------------------------
import csv    # writes the flight log as a CSV file
import math   # hypot and atan2 for range and bearing to the target
import sys    # reads anything typed after the script name (the connection)
import time   # clock and stopwatch functions

from pymavlink import mavutil   # speaks MAVLink, the drone's message protocol


# ---------------------------------------------------------------------------
# FLIGHT SETTINGS
# ALL_CAPS names are a Python convention for "set once, don't change later."
# ---------------------------------------------------------------------------
TARGET_ALT_M = 10       # flight altitude, meters above the launch point (CTL-4: held, never changed)
FOLLOW_SECONDS = 60     # how long to follow the fake target before landing

# SCRIPT-SIDE FAILSAFE (mission judgment; only works while the link is up and
# this script is running). The autopilot's own failsafes (SAF-6) are the
# backstop underneath; set those in Mission Planner.
RTL_BATTERY_PCT = 40    # battery below this while following: stop and fly home


# ---------------------------------------------------------------------------
# FAKE TARGET
# Stands in for the person the camera would see. Its position is a known
# function of time, so we can check later how well the drone followed it.
# ---------------------------------------------------------------------------
def target_position(t):
    """Fake target: starts 10 m north of home, walks east at 1.5 m/s."""
    return 10.0, 1.5 * t     # (north_m, east_m)


# ===========================================================================
# SECTION 1: CONNECT TO THE DRONE
# Open a MAVLink link and wait for the drone's heartbeat (a message every
# MAVLink device sends about once per second to say "I'm here").
# ===========================================================================

# Where to connect: whatever you type after the script name, or the
# simulator if you type nothing.
#   python follow_sim.py                       -> simulator (default below)
#   python follow_sim.py udp:127.0.0.1:14550   -> a UDP network link
CONNECTION = sys.argv[1] if len(sys.argv) > 1 else "tcp:127.0.0.1:5762"

# Serial speed in bits per second. Only matters for radios on COM ports;
# 57600 is standard for SiK telemetry radios. Ignored for tcp/udp links.
BAUD = int(sys.argv[2]) if len(sys.argv) > 2 else 57600

print(f"Connecting to {CONNECTION} ...")

# Open the link. "m" is the connection; everything else goes through it.
#   tcp:127.0.0.1:5762 = this computer, the simulator's second port
#   (Mission Planner already uses 5760)
m = mavutil.mavlink_connection(
    CONNECTION,
    baud=BAUD,
    source_system=254,  # OUR MAVLink ID. Mission Planner uses 255, so we pick another.
)

# Wait for the drone's first heartbeat. pymavlink then saves its address
# (m.target_system, m.target_component) for every command we send.
m.wait_heartbeat()
print(f"Heartbeat from system {m.target_system}, component {m.target_component}")


# ===========================================================================
# SECTION 2: REQUEST TELEMETRY
# The drone only streams data a connection asks for.
# ===========================================================================

def request_message(msg_id, hz):
    """Ask the autopilot to send one message type at a set rate (hz = per second)."""
    m.mav.command_long_send(
        m.target_system, m.target_component,        # "to" address
        mavutil.mavlink.MAV_CMD_SET_MESSAGE_INTERVAL,
        0,                    # confirmation counter (0 = first attempt)
        msg_id,               # param 1: which message we want
        1_000_000 / hz,       # param 2: time between messages, in microseconds
        0, 0, 0, 0, 0,        # params 3-7: unused by this command
    )


# The main loop runs once per GLOBAL_POSITION_INT message, so its rate sets
# the loop rate. CTL-3 requires >= 10 Hz, so both position messages come at 10 Hz.
#   GLOBAL_POSITION_INT = lat/lon, altitude, and heading
#   LOCAL_POSITION_NED  = meters north/east/down from home, used for range
#                         and bearing to the target
request_message(mavutil.mavlink.MAVLINK_MSG_ID_GLOBAL_POSITION_INT, 10)  # 10x/sec (CTL-3)
request_message(mavutil.mavlink.MAVLINK_MSG_ID_LOCAL_POSITION_NED, 10)   # 10x/sec (CTL-3)
request_message(mavutil.mavlink.MAVLINK_MSG_ID_SYS_STATUS, 2)            # battery, 2x/sec
request_message(mavutil.mavlink.MAVLINK_MSG_ID_GPS_RAW_INT, 2)           # GPS quality, 2x/sec


# ===========================================================================
# SECTION 3: HELPER FUNCTIONS
# Defining a function does NOT run it; it runs each time something calls it.
# ===========================================================================

def position():
    """Return the drone's position estimate as a dictionary, or None if none arrived.

    Waits up to 5 s for the next GLOBAL_POSITION_INT, printing any autopilot
    text messages (warnings, failsafes) that arrive while waiting. MAVLink
    sends whole numbers in small units; each value is converted below.
    """
    deadline = time.time() + 5
    msg = None
    while time.time() < deadline:
        incoming = m.recv_match(type=["GLOBAL_POSITION_INT", "STATUSTEXT"],
                                blocking=True, timeout=1)
        if incoming is None:
            continue
        if incoming.get_type() == "STATUSTEXT":
            print(f"  autopilot says: {incoming.text}")
            continue
        msg = incoming
        break
    if msg is None:
        return None
    return {
        "t_vehicle_s": msg.time_boot_ms / 1000,  # ms -> seconds
        "lat_deg": msg.lat / 1e7,                # degrees x 1e7 -> degrees
        "lon_deg": msg.lon / 1e7,
        "alt_m": msg.relative_alt / 1000,        # mm above home -> meters
        "climb_ms": -msg.vz / 100,               # cm/s -> m/s; NED counts down as +,
                                                 # so flip the sign: + = climbing
        "heading_deg": msg.hdg / 100,            # degrees x 100 -> degrees (0 = north)
    }


def command(cmd, *params, timeout=3):
    """Send a command and return the autopilot's answer as text.

    Waits for COMMAND_ACK instead of assuming success, and prints any
    autopilot text explaining a failure.
    Returns e.g. "MAV_RESULT_ACCEPTED", "MAV_RESULT_FAILED", or "NO REPLY".
    """
    params = list(params) + [0] * (7 - len(params))   # pad to the 7 params every command has
    m.mav.command_long_send(m.target_system, m.target_component, cmd, 0, *params)

    deadline = time.time() + timeout
    while time.time() < deadline:
        msg = m.recv_match(type=["COMMAND_ACK", "STATUSTEXT"], blocking=True, timeout=1)
        if msg is None:
            continue
        if msg.get_type() == "STATUSTEXT":
            print("  autopilot says:", msg.text)
        elif msg.command == cmd:           # make sure the reply is for OUR command
            return mavutil.mavlink.enums["MAV_RESULT"][msg.result].name
    return "NO REPLY"


def local_position():
    """Return (north_m, east_m): where the drone is on the home grid, or None.

    Reads the latest LOCAL_POSITION_NED from pymavlink's message store.
    Instant; doesn't wait.
    """
    msg = m.messages.get("LOCAL_POSITION_NED")
    if msg is None:
        return None
    return msg.x, msg.y


def failsafe(reason, mode, t):
    """Abort the mission: say why, then hand control to an autopilot mode.

    The script doesn't fly the drone home itself; it switches to a mode
    where the AUTOPILOT does (RTL = return to launch, LAND = land in place),
    so recovery keeps working even if this script stops.
    """
    print(f"  !! {t:6.1f} s  FAILSAFE: {reason} -> switching to {mode}")
    m.set_mode(m.mode_mapping()[mode])


def go_no_go(min_battery_pct=80, min_satellites=8):
    """Return a list of reasons NOT to fly. An empty list means GO.

    Mission checks owned by this script, stricter than the autopilot's own
    pre-arm checks.
    """
    problems = []
    status = m.recv_match(type="SYS_STATUS", blocking=True, timeout=5)   # battery
    gps = m.recv_match(type="GPS_RAW_INT", blocking=True, timeout=5)     # GPS

    # battery_remaining is a percent; -1 means the autopilot doesn't know.
    if status is None:
        problems.append("No battery data received")
    elif status.battery_remaining < min_battery_pct:
        problems.append(f"Battery at {status.battery_remaining}% (need {min_battery_pct}%+)")

    # fix_type 3 = 3D fix. Lower = not good enough to fly.
    if gps is None:
        problems.append("No GPS data received")
    elif gps.fix_type < 3 or gps.satellites_visible < min_satellites:
        problems.append(f"GPS fix type {gps.fix_type} with {gps.satellites_visible} satellites "
                        f"(need 3+ and {min_satellites}+)")
    return problems


# ===========================================================================
# SECTION 4: PRE-FLIGHT CHECKS, OPERATOR CONFIRMATION, GUIDED MODE, ARM
# Test harness acting as the pilot. Order matters:
#   check -> human says go -> switch mode -> spin up motors.
# ===========================================================================

# 4a. Mission go/no-go checks. Stop here if anything fails.
print("Running go/no-go checks ...")
problems = go_no_go()
if problems:
    for problem in problems:
        print("  NO-GO:", problem)
    raise SystemExit("Pre-flight checks failed. Fix the items above and run again.")
print("GO: battery and GPS checks passed")

# 4b. Safety interlock: a human makes the final call before motors spin.
input("Press Enter to ARM, or Ctrl+C to abort ... ")

# 4c. Switch to GUIDED, then arm. Both are retried: the autopilot may refuse
# until its GPS and position estimate (EKF) settle after the simulator starts.
print("Setting GUIDED and arming (can take up to a minute while GPS and EKF settle) ...")
start = time.time()

while not (m.motors_armed() and m.flightmode == "GUIDED"):
    if m.flightmode != "GUIDED":
        m.set_mode(m.mode_mapping()["GUIDED"])
    elif not m.motors_armed():
        result = command(mavutil.mavlink.MAV_CMD_COMPONENT_ARM_DISARM, 1)   # 1 = arm
        print("  arm request:", result)

    # Listen for 2 s before retrying; heartbeats update the mode and armed state.
    deadline = time.time() + 2
    while time.time() < deadline:
        msg = m.recv_match(type=["HEARTBEAT", "STATUSTEXT"], blocking=True, timeout=1)
        if msg and msg.get_type() == "STATUSTEXT":
            print("  autopilot says:", msg.text)   # e.g. "PreArm: ..." reasons

    if time.time() - start > 120:
        raise SystemExit("Could not arm in GUIDED. See the 'autopilot says' lines above.")
print("Armed in GUIDED")


# ===========================================================================
# SECTION 5: TAKE OFF
# Test harness acting as the pilot. The autopilot handles the climb itself.
# ===========================================================================
m.mav.command_long_send(
    m.target_system, m.target_component,
    mavutil.mavlink.MAV_CMD_NAV_TAKEOFF,
    0,                          # confirmation counter
    0, 0, 0, 0, 0, 0,           # params 1-6: unused for a copter takeoff
    TARGET_ALT_M,               # param 7: target altitude in meters
)
print(f"Taking off to {TARGET_ALT_M} m")


# ===========================================================================
# SECTION 6: FOLLOW THE TARGET AND LOG DATA
# A simple state machine. "phase" holds the current state:
#   climb  -> (reach 95% of target altitude)        -> follow
#   follow -> (FOLLOW_SECONDS elapsed)              -> land
#   land   -> (on the ground and disarmed)          -> done
#   return -> battery failsafe fired; autopilot flying home in RTL
#             (ends like land: on the ground and disarmed)
# Each pass through the loop (about 10 per second, set by the position rate):
#   1. read position   2. log a row   3. print status   4. check for a phase change
# ===========================================================================

# Ctrl+C failsafe: if you press Ctrl+C mid-flight, the "except" at the bottom
# commands LAND before the script exits, so the drone is never left hovering
# with nobody in charge.
try:
    with open("follow_log.csv", "w", newline="") as f:
        log = csv.writer(f)
        log.writerow(["time_s", "t_vehicle_s", "lat_deg", "lon_deg",
                      "north_m", "east_m", "alt_m", "climb_ms", "heading_deg",
                      "phase"])
        t0 = time.time()   # stopwatch start for the time_s column

        # State that carries over from one pass of the loop to the next:
        phase = "climb"         # current state: climb -> follow -> land
        last_state = None       # last (mode, armed) announced; used to spot changes
        rows = []               # (time, altitude, climb rate, phase) for the summary
        follow_started = None   # when following began; the fake target's clock starts here
        abort_reason = None     # stays None unless a failsafe fires

        # Battery level at takeoff, for "battery used" in the summary.
        batt_msg = m.messages.get("SYS_STATUS")
        start_batt = batt_msg.battery_remaining if batt_msg else None

        while True:   # the "break" in the land/return check ends it

            # --- 1. Read position ---------------------------------------------
            p = position()
            if p is None:
                print("  !! WARNING: no position data for 5 s. Retrying ...")
                continue
            alt = p["alt_m"]
            t = round(time.time() - t0, 2)   # seconds since takeoff command (laptop clock)

            # --- 2. Log a row -------------------------------------------------
            # If there's no local position yet, those cells are left blank.
            here = local_position() or (None, None)
            north = round(here[0], 2) if here[0] is not None else ""
            east = round(here[1], 2) if here[1] is not None else ""
            log.writerow([t, p["t_vehicle_s"], p["lat_deg"], p["lon_deg"],
                          north, east, round(alt, 2), round(p["climb_ms"], 2),
                          p["heading_deg"], phase])
            rows.append((t, alt, p["climb_ms"], phase))

            # --- 3. Print status ----------------------------------------------
            # Announce mode or armed-state changes the moment they happen.
            state = (m.flightmode, m.motors_armed())
            if state != last_state:
                print(f"  >> {t:6.1f} s  mode {state[0]}, {'ARMED' if state[1] else 'DISARMED'}")
                last_state = state

            # Live status line. Battery and GPS come from m.messages (latest copy),
            # so reading them doesn't slow the loop. Heartbeat age over 3 s means
            # the link is in trouble.
            batt = m.messages.get("SYS_STATUS")
            gps = m.messages.get("GPS_RAW_INT")
            batt_txt = f"{batt.battery_remaining}% {batt.voltage_battery / 1000:.1f}V" if batt else "--"
            gps_txt = f"{gps.satellites_visible} sats" if gps else "--"
            link_age = m.time_since("HEARTBEAT")
            print(f"{t:6.1f} s  alt {alt:5.1f} m  climb {p['climb_ms']:5.2f} m/s  "
                  f"batt {batt_txt}  gps {gps_txt}  link {link_age:.1f}s  ({phase})")
            if link_age > 3:
                print(f"  !! WARNING: no heartbeat for {link_age:.1f} s. Link may be down.")

            # --- 4. Check for a phase change ----------------------------------
            # if / elif: only ONE branch runs per pass, the first whose test is true.
            if phase == "climb" and alt >= TARGET_ALT_M * 0.95:
                phase = "follow"
                follow_started = time.time()     # the fake target's clock starts now
                print(f"  >> {t:6.1f} s  phase climb -> follow")

            elif phase == "follow":
                # Battery failsafe. "0 <=" skips the check if battery reads -1 (unknown).
                if batt and 0 <= batt.battery_remaining < RTL_BATTERY_PCT:
                    abort_reason = f"battery at {batt.battery_remaining}% (limit {RTL_BATTERY_PCT}%)"
                    failsafe(abort_reason, "RTL", t)
                    phase = "return"
                    continue

                # ---- STAGE A: Derek writes this part ----
                t_follow = time.time() - follow_started   # seconds since following began
                tn, te = target_position(t_follow)        # where the target is now (m north, m east)
                if here[0] is None:
                    continue                              # no local position yet; skip this pass
                dn, de = tn - here[0], te - here[1]
                range_m =  math.hypot(dn, de)   
                compass_bearing = math.degrees(math.atan2(de, dn))      
                rel_bearing = (compass_bearing - p["heading_deg"] + 180) % 360 - 180
                print(f"  follow t {t_follow:5.1f} s  target N {tn:5.1f} E {te:5.1f}  "
                      f"range {range_m:5.1f} m  bearing {rel_bearing:+6.1f} deg")
                if t_follow > FOLLOW_SECONDS:
                    m.set_mode(m.mode_mapping()["LAND"])   # test harness lands (pilot's role)
                    phase = "land"
                    print(f"  >> {t:6.1f} s  follow complete -> land (LAND mode requested)")

            elif phase in ("land", "return") and alt < 0.3 and not m.motors_armed():
                # On the ground and disarmed: the flight is over.
                break

except KeyboardInterrupt:
    print("\n  !! FAILSAFE: operator pressed Ctrl+C -> switching to LAND")
    m.set_mode(m.mode_mapping()["LAND"])
    raise SystemExit("Script stopped. The autopilot is landing on its own; "
                     "watch it on the Mission Planner map.")

print("Landed and disarmed. Flight log saved to follow_log.csv")


# ===========================================================================
# FLIGHT SUMMARY: an automatic mini test report.
# Each item in "rows" is (time, altitude, climb rate, phase).
# ===========================================================================
following = [r[1] for r in rows if r[3] == "follow"]   # altitudes while following
print("\nFLIGHT SUMMARY")
print(f"  Mission result:    {'ABORTED: ' + abort_reason if abort_reason else 'completed'}")
print(f"  Flight time:       {rows[-1][0]:.1f} s")
print(f"  Max altitude:      {max(r[1] for r in rows):.2f} m (target {TARGET_ALT_M} m)")
if following:
    # CTL-4: altitude should hold steady while following.
    print(f"  Follow altitude:   avg {sum(following) / len(following):.2f} m, "
          f"range {min(following):.2f} to {max(following):.2f} m")
print(f"  Max climb rate:    {max(r[2] for r in rows):.2f} m/s")
print(f"  Max descent rate:  {-min(r[2] for r in rows):.2f} m/s")
end_batt = m.messages.get("SYS_STATUS")
if start_batt is not None and end_batt:
    print(f"  Battery used:      {start_batt - end_batt.battery_remaining}% "
          f"({start_batt}% -> {end_batt.battery_remaining}%)")