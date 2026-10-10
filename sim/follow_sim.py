"""
follow_sim.py - Follow a simulated moving target with a simulated quadcopter.

Roadmap step 4: the follow controller in ArduPilot SITL, with no camera. A fake
target walks a known path; each loop the script computes range and bearing to
it, the same two numbers the camera code (perception/live_track.py) produces.
Built in stages:
    a. Fake target + range/bearing printout, drone hovering   [done]
    b. Yaw control: turn to face the target                   [done]
    c. Forward speed: hold the standoff distance              [done]
    d. Limits, keep-out zone, gain tuning                     [done]
    e. Test cases by name, target logging, 3D replay          [done]

Built from pattern_flight.py (sections 1-5 are the same harness).

WHAT IT DOES
    1. Connects to the drone and waits for its heartbeat.
    2. Asks the drone to stream position, battery, and GPS data at 10 Hz.
    3. Defines helper functions used by the rest of the script.
    4. Runs go/no-go checks, asks you to confirm, then arms in GUIDED mode.
    5. Commands a takeoff.
    6. Climbs, then follows the fake target for FOLLOW_SECONDS, then lands.

HOW TO RUN
    Restart Mission Planner's Multirotor simulation first (fresh position and
    battery every run), then in Anaconda Prompt (yolo environment):
        python follow_sim.py              (straight walk, simulator)
        python follow_sim.py circle       (circling target)

WHO DOES WHAT
    This script plays two roles, and they follow different rules:
      - TEST HARNESS (sections 4-5, the landing, and the failsafes): stands in
        for the pilot. It arms, takes off, and lands, which only the operator
        may do on the real system.
      - FOLLOW LOGIC (the "follow" phase): stands in for the companion computer.
        It must obey SAF-2: send velocity and yaw-rate commands only, never
        arm, take off, land, or change mode.
    ArduPilot, the autopilot, does all the actual flying.

CONTROL LAW (one pass, 10 Hz)
    yaw_rate = YAW_GAIN * bearing                        capped at +/-60 deg/s
    speed    = RANGE_GAIN * (range - STANDOFF_M)         capped at +/-5 m/s
    speed    = min(speed, KEEP_OUT_GAIN * (range - KEEP_OUT_M))   keep-out ramp
    speed    = min(speed, soft_cap)   soft start: cap ramps 1 -> 5 m/s over 5 s after a (re)start
    velocity = speed along the line to the target (split into north/east)

REQUIREMENTS THIS SCRIPT PRODUCES EVIDENCE FOR
    CTL-1  Keep target within +/-10 deg of centerline       PASS: straight 5.2° max then 0°; circle 4.3° steady
    CTL-2  Hold 8 m standoff within +/-2 m                  PASS: 9.5 m (0.5 m margin)
    CTL-3  Velocity + yaw rate only, >= 10 Hz, 5 m/s, 60 deg/s   implemented (mask, clamps, 10 Hz loop)
    CTL-4  No altitude commands                             PASS: vz always 0; altitude 5.76-6.06 m
    SAF-1  Stop commanding when mode leaves GUIDED          PASS: stops same pass; no forced LAND after takeover
    SAF-4  Remain at least 5 m horizontally from the target, including braking distance, and shall not fly directly over people.                PASS (fault injection, keep-out v2)

FINDINGS (fake target walking east at 1.5 m/s; see the project brief for full logs)
    Stage a: loop runs at 10 Hz; range and bearing match hand calculation.
    Stage b: proportional yaw lags a moving target by about (angular rate) / YAW_GAIN.
      Gain 0.5 gave 2-3 deg at 25-30 m but predicts ~21 deg at 8 m. Raised to 2.0.
    Stage c: proportional range control settles at STANDOFF + target speed / RANGE_GAIN.
      Gain 0.5 -> 11.0 m (predicted 11, FAILS CTL-2). Gain 1.0 -> 9.51 m (predicted 9.5, PASSES).
    Stage d, SAF-4 fault injection (STANDOFF_M deliberately set to 3.0):
      v1 "zero the approach speed inside 5 m" FAILED: momentum carried the drone
        to 3.2 m, then it cycled 4.4-6.2 m (40% of samples inside 5 m).
        Commanding zero at the line is not the same as staying outside the line.
      v2 "approach speed ramps down to zero at 5 m" PASSED: closest 6.9 m, settled
        at 8.0 m (where 0.5 * (r - 5) = 1.5 m/s), 0 samples inside 5 m.
    Safety harness: mode changes are confirmed, not fire-and-forget (an unconfirmed
      Ctrl+C LAND once left the drone hovering); any crash in the loop also lands.

OUTPUT
    follow_log.csv in this folder (gitignored; regenerated every run): one row
    per position update, with time, position (lat/lon and meters north/east of
    home), altitude, climb rate, heading, and flight phase plus target position, range, bearing, and the yaw and speed commands while following.
"""

# ---------------------------------------------------------------------------
# IMPORTS
# ---------------------------------------------------------------------------
import csv    # writes the flight log as a CSV file
import math   # hypot and atan2 for range and bearing; radians for yaw rate
import sys    # reads the test name and optional connection typed after the script name
import time   # clock and stopwatch functions

from pymavlink import mavutil   # speaks MAVLink, the drone's message protocol


# ---------------------------------------------------------------------------
# FLIGHT SETTINGS
# ALL_CAPS names are a Python convention for "set once, don't change later."
# ---------------------------------------------------------------------------
TARGET_ALT_M = 6.0      # flight altitude, meters above home (CTL-4: held, never changed)
FOLLOW_SECONDS = 60     # how long to follow the fake target before landing
RESUME_DELAY_S = 3.0    # wait in "searching" before following again; stands in for the
                        # operator re-designating the target (PER-3)

# Follow controller
STANDOFF_M = 8.0        # CTL-2: default follow distance (m)
YAW_GAIN = 2.0          # deg/s of turn per deg of bearing error (proportional)
RANGE_GAIN = 1.0        # m/s of speed per m of range error (proportional)

# Command limits (CTL-3)
MAX_SPEED_MS = 5.0      # max horizontal speed command, m/s [TBR]
MAX_YAW_RATE_DPS = 60   # max yaw-rate command, deg/s [TBR]
SOFT_START_MS = 1.0     # forward speed limit right after following (re)starts (m/s)
SOFT_START_S = 5.0      # seconds to ramp the forward limit up to MAX_SPEED_MS

# Keep-out (SAF-4)
KEEP_OUT_M = 5.0        # the drone must stay at least this far from the target (m)
KEEP_OUT_GAIN = 0.5     # m/s of allowed approach speed per m outside the keep-out

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

def target_circle(t):
    """Fake target: circles (20, 0) at 10 m radius, 1.5 m/s, counterclockwise. Starts at (10, 0) heading east."""
    radius = 10.0
    speed = 1.5
    center_n, center_e = 20, 0
    angle = (speed / radius) * t  # radians since start
    return center_n - (radius * math.cos(angle)), center_e + (radius * math.sin(angle))   # (north_m, east_m)

# ===========================================================================
# SECTION 1: CONNECT TO THE DRONE
# Open a MAVLink link and wait for the drone's heartbeat (a message every
# MAVLink device sends about once per second to say "I'm here").
# ===========================================================================

# Where to connect: whatever you type after the script name, or the
# simulator if you type nothing.
#   python follow_sim.py circle                         -> simulator (default below)
#   python follow_sim.py circle udp:127.0.0.1:14550     -> a UDP network link
CONNECTION = sys.argv[2] if len(sys.argv) > 2 else "tcp:127.0.0.1:5762"

# Serial speed in bits per second. Only matters for radios on COM ports;
# 57600 is standard for SiK telemetry radios. Ignored for tcp/udp links.
BAUD = int(sys.argv[3]) if len(sys.argv) > 3 else 57600

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


def send_velocity_yaw_rate(vn, ve, yaw_rate_dps):
    """Command horizontal velocity (m/s, north/east) and yaw rate (deg/s).

    The ONLY motion command the follow logic sends (SAF-2, CTL-3).
    Vertical velocity is always 0, so the autopilot holds altitude (CTL-4).
    Must be resent every loop: in GUIDED, ArduPilot stops the vehicle if
    velocity commands stop arriving for a few seconds (ties to SAF-5).
    """
    # type_mask: one switch per field; 1 = IGNORE that field. Read right to left:
    #   yaw_rate yaw | accel | velocity | position
    #      0      1  | 1 1 1 |  0 0 0   |  1 1 1
    # Uses velocity and yaw rate; ignores position, acceleration, and yaw angle.
    # (Bit 9, between accel and yaw, is the unused "accel is force" flag = 0.)
    VELOCITY_AND_YAW_RATE = 0b010111000111   # = 1479
    m.mav.set_position_target_local_ned_send(
        0,                                        # time_boot_ms (not needed)
        m.target_system, m.target_component,
        mavutil.mavlink.MAV_FRAME_LOCAL_NED,      # north/east/down frame
        VELOCITY_AND_YAW_RATE,
        0, 0, 0,                                  # position (ignored)
        vn, ve, 0,                                # velocity north, east, down (0 = hold altitude)
        0, 0, 0,                                  # acceleration (ignored)
        0,                                        # yaw angle (ignored)
        math.radians(yaw_rate_dps),               # yaw rate: MAVLink wants radians/s
    )


def set_mode_confirmed(mode, timeout=5):
    """Change flight mode and wait until the drone confirms it.

    Resends the request about once a second until a heartbeat reports the
    new mode, or the timeout runs out. Returns True if confirmed, False if not.
    Safety actions must be verified, not fire-and-forget.
    """
    deadline = time.time() + timeout
    last_sent = 0
    while time.time() < deadline:
        if time.time() - last_sent > 1:
            m.set_mode(m.mode_mapping()[mode])
            last_sent = time.time()
        msg = m.recv_match(type=["HEARTBEAT", "STATUSTEXT"], blocking=True, timeout=0.5)
        if msg and msg.get_type() == "STATUSTEXT":
            print("  autopilot says:", msg.text)
        if m.flightmode == mode:
            return True
    return False


def failsafe(reason, mode, t):
    """Abort the mission: say why, then hand control to an autopilot mode.

    The script doesn't fly the drone home itself; it switches to a mode
    where the AUTOPILOT does (RTL = return to launch, LAND = land in place),
    so recovery keeps working even if this script stops. The mode change is
    confirmed, not fire-and-forget.
    """
    print(f"  !! {t:6.1f} s  FAILSAFE: {reason} -> switching to {mode}")
    if set_mode_confirmed(mode):
        print(f"  {mode} confirmed. The autopilot has control.")
    else:
        print(f"  !! {mode} NOT confirmed. Take over from Mission Planner or RC.")


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
# ---- Test case selection (before arming, so a typo never flies) ----
if len(sys.argv) > 1:
    test_name = sys.argv[1]
else:
    test_name = "straight"

if test_name == "straight":
    target = target_position
elif test_name == "circle":
    target = target_circle   
else:
    raise SystemExit(f"Unknown test '{test_name}'. Use: straight, circle")
print(f"  Test case: {test_name}")

print("Running go/no-go checks ...")

# 4a. Mission go/no-go checks. Stop here if anything fails.
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
#   climb     -> (reach 95% of target altitude)                         -> follow
#   follow    -> (FOLLOW_SECONDS since last (re)start)                  -> land
#   follow    -> (mode left GUIDED: pilot or autopilot failsafe, SAF-1) -> idle
#   follow    -> (battery below RTL_BATTERY_PCT)                        -> return
#   idle      -> sends nothing; (back in GUIDED and armed)              -> searching
#   searching -> sends nothing; (left GUIDED)                           -> idle
#   searching -> (RESUME_DELAY_S elapsed; stands in for re-designation) -> follow
#   land, return, idle -> (on the ground and disarmed)                  -> done
# Each pass through the loop (about 10 per second, set by the position rate):
#   1. read position   2. prepare log values   3. print status
#   4. check for a phase change   5. log a row
# ===========================================================================

# Abort handlers at the bottom: Ctrl+C (operator abort) or any crash in this
# loop commands a confirmed LAND before the script exits, so the drone is never
# left hovering with nobody in charge.
try:
    with open("follow_log.csv", "w", newline="") as f:
        log = csv.writer(f)
        log.writerow(["time_s", "t_vehicle_s", "lat_deg", "lon_deg",
                      "north_m", "east_m", "alt_m", "climb_ms", "heading_deg",
                      "phase",
                      "target_n", "target_e", "range_m", "bearing_deg",
                      "yaw_cmd_dps", "speed_cmd_ms"])
        t0 = time.time()   # stopwatch start for the time_s column

        # State that carries over from one pass of the loop to the next:
        phase = "climb"         # current state: climb, follow, idle, searching, land, return (see the list above)
        last_state = None       # last (mode, armed) announced; used to spot changes
        rows = []               # (time, altitude, climb rate, phase) for the summary
        follow_started = None   # when following began; the fake target's clock starts here
        abort_reason = None     # stays None unless a failsafe fires
        searching_started = None   # when "searching" began; the resume delay counts from here
        follow_resumed = None      # when following last (re)started; the end-of-test timer counts from here

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

            # --- 2. Prepare log values -------------------------------------------------
            # If there's no local position yet, those cells are left blank.
            here = local_position() or (None, None)
            north = round(here[0], 2) if here[0] is not None else ""
            east = round(here[1], 2) if here[1] is not None else ""
            
            # Follow-phase values, blank unless the follow branch fills them in below.
            tn = te = range_m = rel_bearing = yaw_rate = speed = ""
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
                follow_resumed = time.time() #end-of-test timer starts now
                print(f"  >> {t:6.1f} s  phase climb -> follow")
            
            elif phase == "follow" and m.flightmode != "GUIDED":
                # The autopilot is no longer in GUIDED, so the follow logic can't run.
                # This can happen if the operator switches to another mode (e.g. RTL)
                # or if a failsafe fires (e.g. low battery). Either way, the follow
                # phase is over.
                phase = "idle"
                print(f"  >> {t:6.1f} s  phase follow -> {phase} (autopilot switched to {m.flightmode})")

            elif phase == "idle" and m.flightmode == "GUIDED" and m.motors_armed():
                phase = "searching"
                searching_started = time.time()
                print(f"  >> {t:6.1f} s  phase idle -> searching (autopilot back in GUIDED)")

            elif phase == "searching" and m.flightmode != "GUIDED":
                phase = "idle"
                print(f"  >> {t:6.1f} s  phase searching -> idle (autopilot switched to {m.flightmode})")

            elif phase == "searching" and RESUME_DELAY_S < time.time() - searching_started:
                phase = "follow"
                follow_resumed = time.time()     # end of test timer restarts; target's clock keeps running
                print(f"  >> {t:6.1f} s  phase searching -> follow (resuming after {RESUME_DELAY_S} s)")

            elif phase == "follow":
                # Battery failsafe. "0 <=" skips the check if battery reads -1 (unknown).
                if batt and 0 <= batt.battery_remaining < RTL_BATTERY_PCT:
                    abort_reason = f"battery at {batt.battery_remaining}% (limit {RTL_BATTERY_PCT}%)"
                    failsafe(abort_reason, "RTL", t)
                    phase = "return"
                    continue

                # --- Where is the target? (stands in for the camera estimate) ---
                t_follow = time.time() - follow_started   # seconds since following began
                tn, te = target(t_follow)        # where the target is now (m north, m east)
                if here[0] is None:
                    continue                              # no local position yet; skip this pass

                # --- Range and bearing (same quantities perception produces) ---
                dn, de = tn - here[0], te - here[1]       # target relative to drone (m north, m east)
                range_m = math.hypot(dn, de)              # straight-line distance (m)
                compass_bearing = math.degrees(math.atan2(de, dn))   # direction to target; 0 = north, 90 = east
                # Relative to the nose, wrapped to -180..+180. + = target to the right.
                rel_bearing = (compass_bearing - p["heading_deg"] + 180) % 360 - 180
                
                # --- Soft start: no lunge after (re)starting to follow ---
                # Right after following starts or resumes after a hand-back, the
                # target may be far away, and the drone would otherwise jump straight
                # to MAX_SPEED_MS. Instead, the forward speed limit starts at
                # SOFT_START_MS and grows in a straight line to MAX_SPEED_MS over
                # SOFT_START_S seconds (e.g. 1.0 -> 5.0 m/s over 5 s).
                since_resume = time.time() - follow_resumed     # seconds since following (re)started
                ramp = min(1.0, since_resume / SOFT_START_S)    # 0 at (re)start, 1 when fully ramped up
                soft_cap = SOFT_START_MS + ramp * (MAX_SPEED_MS - SOFT_START_MS)   # this pass's forward speed limit (m/s)
                
                # --- Control (stage d: yaw + standoff, with limits and keep-out) ---
                # Yaw: turn rate proportional to how far off-center the target is,
                # capped at +/-60 deg/s (CTL-3). + = turn right.
                yaw_rate = max(-MAX_YAW_RATE_DPS, min(MAX_YAW_RATE_DPS, YAW_GAIN * rel_bearing))
                
                # Speed: proportional to range error, capped at +/-5 m/s (CTL-3).
                # + = toward the target, - = away from it.
                speed = max(-MAX_SPEED_MS, min(MAX_SPEED_MS, RANGE_GAIN * (range_m - STANDOFF_M)))

                # Keep-out (SAF-4): the closer to 5 m, the slower the allowed approach;
                # zero at 5 m, negative (back away) inside it. Runs every pass so the
                # drone is already braking when it reaches the line.
                speed = min(speed, KEEP_OUT_GAIN * (range_m - KEEP_OUT_M))
                
                # Soft start limits toward-target speed only; backing away (keep-out) is never slowed.
                speed = min(speed, soft_cap)

                # Split speed into north/east along the line to the target.
                # Guard: no direction exists if the drone is exactly on the target.
                if range_m > 0:
                    vn = speed * dn / range_m
                    ve = speed * de / range_m
                else:
                    vn = 0
                    ve = 0
                send_velocity_yaw_rate(vn, ve, yaw_rate)   # the only command the follow logic sends (SAF-2)

                print(f"  follow t {t_follow:5.1f} s  target N {tn:5.1f} E {te:5.1f}  "
                      f"range {range_m:5.1f} m  bearing {rel_bearing:+6.1f} deg  "
                      f"yaw {yaw_rate:+6.1f} deg/s  speed {speed:+5.1f} m/s")

                # --- End of test: the harness lands (pilot's role, not the follow logic) ---
                # If LAND isn't confirmed, phase stays "follow" and it retries next pass.
                if time.time() - follow_resumed > FOLLOW_SECONDS:
                    if set_mode_confirmed("LAND"):
                        phase = "land"
                        print(f"  >> {t:6.1f} s  follow complete -> LAND confirmed")
                    else:
                        print(f"  !! {t:6.1f} s  LAND NOT confirmed; retrying. Land manually if this repeats.")

            elif phase in ("land", "return", "idle") and alt < 0.3 and not m.motors_armed():
                # On the ground and disarmed: the flight is over.
                break
            
            # --- 5. Log a row (last, so it includes this pass's target and commands) ---
            log.writerow([t, p["t_vehicle_s"], p["lat_deg"], p["lon_deg"],
                          north, east, round(alt, 2), round(p["climb_ms"], 2),
                          p["heading_deg"], phase,
                          tn, te, range_m, rel_bearing, yaw_rate, speed])

except KeyboardInterrupt:
    # Operator pressed Ctrl+C. (KeyboardInterrupt is NOT caught by
    # "except Exception" below, so it needs its own handler.)
    print("\n  !! FAILSAFE: operator pressed Ctrl+C -> switching to LAND")
    if set_mode_confirmed("LAND"):
        print("  LAND confirmed. The autopilot is landing.")
    else:
        print("  !! LAND NOT confirmed. Land manually from Mission Planner (Actions > LAND).")
    raise SystemExit("Script stopped.")

except Exception as e:
    # Any crash in the loop (typo, bad value, lost connection): land, then
    # re-raise so the original error and line number are still shown.
    print(f"\n  !! FAILSAFE: script error ({e}) -> switching to LAND")
    if set_mode_confirmed("LAND"):
        print("  LAND confirmed. The autopilot is landing.")
    else:
        print("  !! LAND NOT confirmed. Land manually from Mission Planner (Actions > LAND).")
    raise

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