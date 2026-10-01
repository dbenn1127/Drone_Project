"""
first_flight.py - Fly a simulated quadcopter: take off to 10 m, hover, land.

WHAT IT DOES
    1. Connects to the drone and waits for its heartbeat.
    2. Asks the drone to stream position, battery, and GPS data.
    3. Defines helper functions used by the rest of the script.
    4. Runs go/no-go checks, asks you to confirm, then arms in GUIDED mode.
    5. Commands a takeoff.
    6. Watches the flight (climb -> hover -> land), logging data to a CSV file.

HOW TO RUN
    Start Mission Planner's Multirotor simulation first, then in Command Prompt:
        python first_flight.py              (connects to the simulator)
        python first_flight.py COM3         (connects to a real telemetry radio)

WHO DOES WHAT
    This script only sends high-level requests (change mode, arm, take off,
    land) and records what happens. ArduPilot, the autopilot, does all the
    actual flying: stabilizing, climbing, holding position, and landing.

OUTPUT
    altitude_log.csv in this folder: one row per position update, with time,
    position, altitude, climb rate, heading, and flight phase.
"""

# ---------------------------------------------------------------------------
# IMPORTS: load code other people wrote so we don't have to.
# ---------------------------------------------------------------------------
import csv    # writes the flight log as a spreadsheet-friendly CSV file
import sys    # reads anything typed after the script name (the connection)
import time   # clock and stopwatch functions

from pymavlink import mavutil   # speaks MAVLink, the drone's message protocol


# ---------------------------------------------------------------------------
# FLIGHT SETTINGS: change these to change the flight.
# ALL_CAPS names are a Python convention for "set once, don't change later."
# ---------------------------------------------------------------------------
TARGET_ALT_M = 10     # takeoff altitude, meters above the launch point
HOVER_SECONDS = 10    # how long to hover before landing


# ===========================================================================
# SECTION 1: CONNECT TO THE DRONE
# Open a MAVLink link and wait for the drone's heartbeat (a message every
# MAVLink device sends about once per second to say "I'm here").
# ===========================================================================

# Where to connect: whatever you type after the script name, or the
# simulator if you type nothing. sys.argv is the list of words you typed:
# sys.argv[0] is the script name, sys.argv[1] is the next word, and so on.
#   python first_flight.py                       -> simulator (default below)
#   python first_flight.py COM3                  -> telemetry radio on COM3
#   python first_flight.py udp:127.0.0.1:14550   -> a UDP network link
CONNECTION = sys.argv[1] if len(sys.argv) > 1 else "tcp:127.0.0.1:5762"

# Serial speed in bits per second. Only matters for radios on COM ports;
# 57600 is standard for SiK telemetry radios. Ignored for tcp/udp links.
BAUD = int(sys.argv[2]) if len(sys.argv) > 2 else 57600

print(f"Connecting to {CONNECTION} ...")

# Open the link. "m" is the connection; everything else goes through it.
# Connection string format: transport:address:port
#   tcp        = the network protocol
#   127.0.0.1  = "this same computer"
#   5762       = the simulator's port (Mission Planner already uses 5760)
m = mavutil.mavlink_connection(
    CONNECTION,
    baud=BAUD,
    source_system=254,  # OUR MAVLink ID, the "from" address on our messages.
                        # Mission Planner uses 255, so we pick something else.
)

# Block (pause) until the drone's first heartbeat arrives. pymavlink then
# saves the sender's address as the "to" address for our commands:
#   m.target_system    = which vehicle (1 = the drone)
#   m.target_component = which device on it (0 = all devices, 1 = autopilot)
m.wait_heartbeat()
print(f"Heartbeat from system {m.target_system}, component {m.target_component}")


# ===========================================================================
# SECTION 2: REQUEST TELEMETRY
# The drone only streams data a connection asks for. We ask for exactly the
# messages we use, at set rates, to save radio bandwidth.
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


request_message(mavutil.mavlink.MAVLINK_MSG_ID_GLOBAL_POSITION_INT, 4)  # position, 4x/sec
request_message(mavutil.mavlink.MAVLINK_MSG_ID_SYS_STATUS, 2)           # battery, 2x/sec
request_message(mavutil.mavlink.MAVLINK_MSG_ID_GPS_RAW_INT, 2)          # GPS quality, 2x/sec


# ===========================================================================
# SECTION 3: HELPER FUNCTIONS
# A function ("def") is a named, reusable block of code. Defining it here
# does NOT run it; it runs later, each time something calls it by name.
# Python reads top to bottom, so functions must be defined before they're used.
# ===========================================================================

def position():
    """Return the drone's position estimate as a dictionary, or None if none arrived.

    A dictionary is a set of labeled values, e.g. p["alt_m"] gives the altitude.
    MAVLink sends whole numbers in small units to keep messages compact, so
    each value is converted to normal units below.
    """
    # Wait up to 5 seconds for the next position message. While waiting,
    # print any text messages from the autopilot (warnings, "Land complete",
    # failsafes) instead of silently skipping past them.
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
        msg = incoming      # got a position message; stop waiting
        break
    if msg is None:          # None = Python's "nothing"; no message arrived
        return None
    return {
        "t_vehicle_s": msg.time_boot_ms / 1000,  # autopilot's clock: ms -> seconds
        "lat_deg": msg.lat / 1e7,                # degrees x 10,000,000 -> degrees
        "lon_deg": msg.lon / 1e7,
        "alt_m": msg.relative_alt / 1000,        # mm above home -> meters
        "climb_ms": -msg.vz / 100,               # cm/s -> m/s. MAVLink counts
                                                 # "down" as positive (NED frame),
                                                 # so we flip the sign: + = climbing
        "heading_deg": msg.hdg / 100,            # degrees x 100 -> degrees
    }


def altitude_m():
    """Return just the altitude. No longer used by this script; safe to delete."""
    p = position()
    return p["alt_m"] if p else None


def command(cmd, *params, timeout=3):
    """Send a command and return the autopilot's answer as text.

    Every MAVLink command gets a reply (COMMAND_ACK) saying whether it was
    accepted. We wait for that reply instead of assuming success.
      *params  = accept any number of values; we pad them to the 7 every
                 command carries.
      Returns  e.g. "MAV_RESULT_ACCEPTED", "MAV_RESULT_FAILED", or "NO REPLY".
    """
    params = list(params) + [0] * (7 - len(params))   # pad to exactly 7 numbers
    m.mav.command_long_send(m.target_system, m.target_component, cmd, 0, *params)

    deadline = time.time() + timeout
    while time.time() < deadline:
        # Listen for the reply AND for text messages. The reply says THAT a
        # command failed; the text message says WHY, so we print it.
        msg = m.recv_match(type=["COMMAND_ACK", "STATUSTEXT"], blocking=True, timeout=1)
        if msg is None:
            continue                       # nothing yet; keep waiting
        if msg.get_type() == "STATUSTEXT":
            print("  autopilot says:", msg.text)
        elif msg.command == cmd:           # make sure the reply is for OUR command
            # Replies are numbers; this looks up the readable name.
            return mavutil.mavlink.enums["MAV_RESULT"][msg.result].name
    return "NO REPLY"


def go_no_go(min_battery_pct=80, min_satellites=8):
    """Return a list of reasons NOT to fly. An empty list means GO.

    These are MISSION checks owned by this script. The autopilot runs its own
    flight-safety checks separately; ours can be stricter (e.g. it may allow
    takeoff at 50% battery, but our mission requires 80%).
    The "=80" and "=8" are defaults; override with go_no_go(min_battery_pct=50).
    """
    problems = []   # start with an empty list; add a line for each failure
    status = m.recv_match(type="SYS_STATUS", blocking=True, timeout=5)   # battery
    gps = m.recv_match(type="GPS_RAW_INT", blocking=True, timeout=5)     # GPS

    # Each failure message includes the MEASURED value, so you can see why.
    # battery_remaining is a percent; -1 means the autopilot doesn't know.
    if status is None:
        problems.append("No battery data received")
    elif status.battery_remaining < min_battery_pct:
        problems.append(f"Battery at {status.battery_remaining}% (need {min_battery_pct}%+)")

    # fix_type 3 = 3D fix (position + altitude). Lower = not good enough to fly.
    if gps is None:
        problems.append("No GPS data received")
    elif gps.fix_type < 3 or gps.satellites_visible < min_satellites:
        problems.append(f"GPS fix type {gps.fix_type} with {gps.satellites_visible} satellites "
                        f"(need 3+ and {min_satellites}+)")
    return problems


# ===========================================================================
# SECTION 4: PRE-FLIGHT CHECKS, OPERATOR CONFIRMATION, GUIDED MODE, ARM
# Order matters: check -> human says go -> switch mode -> spin up motors.
# ===========================================================================

# 4a. Mission go/no-go checks. Stop here if anything fails.
print("Running go/no-go checks ...")
problems = go_no_go()
if problems:                        # true when the list isn't empty
    for problem in problems:        # print each reason, one per line
        print("  NO-GO:", problem)
    raise SystemExit("Pre-flight checks failed. Fix the items above and run again.")
print("GO: battery and GPS checks passed")

# 4b. Safety interlock: a human makes the final call before motors spin.
# input() pauses until you press Enter. Ctrl+C stops the script instead.
input("Press Enter to ARM, or Ctrl+C to abort ... ")

# 4c. Switch to GUIDED (the mode that takes commands from scripts), then arm.
# Both steps get retried: the autopilot may refuse until its GPS and position
# estimate (EKF) settle, which can take a minute after the simulator starts.
print("Setting GUIDED and arming (can take up to a minute while GPS and EKF settle) ...")
start = time.time()   # stopwatch start, used for the 2-minute timeout below

# Keep looping until the drone reports BOTH armed AND in GUIDED mode.
# m.motors_armed() and m.flightmode come from the drone's latest heartbeat.
while not (m.motors_armed() and m.flightmode == "GUIDED"):
    # One step per pass, in order: mode first, then arm.
    if m.flightmode != "GUIDED":
        # MAVLink sends modes as numbers; mode_mapping() looks up GUIDED's number.
        m.set_mode(m.mode_mapping()["GUIDED"])
    elif not m.motors_armed():
        # Param 1 = 1 means ARM (0 would mean disarm).
        result = command(mavutil.mavlink.MAV_CMD_COMPONENT_ARM_DISARM, 1)
        print("  arm request:", result)

    # Listen for 2 seconds before trying again. Receiving heartbeats is what
    # updates m.flightmode and the armed state, so we have to keep listening.
    deadline = time.time() + 2
    while time.time() < deadline:
        msg = m.recv_match(type=["HEARTBEAT", "STATUSTEXT"], blocking=True, timeout=1)
        if msg and msg.get_type() == "STATUSTEXT":
            print("  autopilot says:", msg.text)   # e.g. "PreArm: ..." reasons

    # Give up after 2 minutes instead of waiting forever.
    if time.time() - start > 120:
        raise SystemExit("Could not arm in GUIDED. See the 'autopilot says' lines above.")
print("Armed in GUIDED")


# ===========================================================================
# SECTION 5: TAKE OFF
# One command; the autopilot handles the climb itself.
# (Exercise: switch this to use command() so you see the acknowledgment.)
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
# SECTION 6: FLY THE PROFILE AND LOG DATA
# A simple state machine with three phases:
#   climb -> (reach 95% of target) -> hover -> (after HOVER_SECONDS) -> land
#   land  -> (on the ground and disarmed) -> done
# Each pass through the loop: read position, log one row, check for a phase change.
# ===========================================================================

# "with open(...)" opens the file and closes it automatically when done.
# "w" = write (replaces the file if it already exists).
with open("altitude_log.csv", "w", newline="") as f:
    log = csv.writer(f)
    log.writerow(["time_s", "t_vehicle_s", "lat_deg", "lon_deg",      # column headers
                  "alt_m", "climb_ms", "heading_deg", "phase"])
    t0 = time.time()   # stopwatch start for the time_s column

    phase = "climb"
    hover_start = None   # set when the hover begins
    last_state = None    # last (mode, armed) we announced; used to spot changes
    rows = []            # a copy of key values, kept for the summary at the end
    batt_msg = m.messages.get("SYS_STATUS")
    start_batt = batt_msg.battery_remaining if batt_msg else None

    while True:   # loop forever; the "break" below ends it
        p = position()
        if p is None:
            continue   # no data this time; try again
        alt = p["alt_m"]
        t = round(time.time() - t0, 2)   # seconds since takeoff command (laptop clock)

        # Write one row of data to the CSV, and keep a copy for the summary.
        log.writerow([t, p["t_vehicle_s"], p["lat_deg"], p["lon_deg"],
                      round(alt, 2), round(p["climb_ms"], 2), p["heading_deg"], phase])
        rows.append((t, alt, p["climb_ms"], phase))

        # Announce mode or armed-state changes the moment they happen.
        state = (m.flightmode, m.motors_armed())
        if state != last_state:
            print(f"  >> {t:6.1f} s  mode {state[0]}, {'ARMED' if state[1] else 'DISARMED'}")
            last_state = state

        # Live status line. m.messages holds the LATEST copy of every message
        # type pymavlink has received, so we can read battery and GPS here
        # without waiting for them. m.time_since() = seconds since last heartbeat.
        batt = m.messages.get("SYS_STATUS")
        gps = m.messages.get("GPS_RAW_INT")
        batt_txt = f"{batt.battery_remaining}% {batt.voltage_battery / 1000:.1f}V" if batt else "--"
        gps_txt = f"{gps.satellites_visible} sats" if gps else "--"
        link_age = m.time_since("HEARTBEAT")
        print(f"{t:6.1f} s  alt {alt:5.1f} m  climb {p['climb_ms']:5.2f} m/s  "
              f"batt {batt_txt}  gps {gps_txt}  link {link_age:.1f}s  ({phase})")
        if link_age > 3:
            print(f"  !! WARNING: no heartbeat for {link_age:.1f} s. Link may be down.")

        # Phase changes (only one can happen per pass):
        if phase == "climb" and alt >= TARGET_ALT_M * 0.95:
            # Close enough to target altitude: start the hover timer.
            phase, hover_start = "hover", time.time()
            print(f"  >> {t:6.1f} s  phase climb -> hover")
        elif phase == "hover" and time.time() - hover_start >= HOVER_SECONDS:
            # Hover time is up: switch to LAND mode; the autopilot lands itself.
            m.set_mode(m.mode_mapping()["LAND"])
            phase = "land"
            print(f"  >> {t:6.1f} s  phase hover -> land (LAND mode requested)")
        elif phase == "land" and alt < 0.3 and not m.motors_armed():
            # On the ground and the autopilot has disarmed: flight complete.
            break

print("Landed and disarmed. Altitude log saved to altitude_log.csv")

# ===========================================================================
# FLIGHT SUMMARY: an automatic mini test report from the data we kept.
# Each row in "rows" is (time, altitude, climb rate, phase); r[1] = altitude.
# ===========================================================================
hover = [r[1] for r in rows if r[3] == "hover"]   # altitudes during hover only
print("\nFLIGHT SUMMARY")
print(f"  Flight time:       {rows[-1][0]:.1f} s")
print(f"  Max altitude:      {max(r[1] for r in rows):.2f} m (target {TARGET_ALT_M} m)")
if hover:
    print(f"  Hover altitude:    avg {sum(hover) / len(hover):.2f} m, "
          f"range {min(hover):.2f} to {max(hover):.2f} m")
print(f"  Max climb rate:    {max(r[2] for r in rows):.2f} m/s")
print(f"  Max descent rate:  {-min(r[2] for r in rows):.2f} m/s")
end_batt = m.messages.get("SYS_STATUS")
if start_batt is not None and end_batt:
    print(f"  Battery used:      {start_batt - end_batt.battery_remaining}% "
          f"({start_batt}% -> {end_batt.battery_remaining}%)")