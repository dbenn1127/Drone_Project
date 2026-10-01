"""
pattern_flight.py - Fly a simulated quadcopter around a square, then land.

Built from first_flight.py (kept unchanged as the working baseline). The new
pieces are the PATTERN list, the fly_to / local_position / distance_to
helpers, and the "pattern" phase in section 6.

WHAT IT DOES
    1. Connects to the drone and waits for its heartbeat.
    2. Asks the drone to stream position, battery, and GPS data.
    3. Defines helper functions used by the rest of the script.
    4. Runs go/no-go checks, asks you to confirm, then arms in GUIDED mode.
    5. Commands a takeoff.
    6. Flies the pattern (climb -> each waypoint in turn -> land), logging data.

HOW TO RUN
    Start Mission Planner's Multirotor simulation first, then in Command Prompt:
        python pattern_flight.py              (connects to the simulator)
        python pattern_flight.py COM3         (connects to a real telemetry radio)
    Watch the drone on Mission Planner's Flight Data map while it flies.

WHO DOES WHAT
    This script decides WHERE to go and WHEN to move on. ArduPilot, the
    autopilot, does all the actual flying: stabilizing, accelerating toward
    each point, holding altitude, and landing.

OUTPUT
    pattern_log.csv in this folder: one row per position update, with time,
    position (lat/lon AND meters north/east of home), altitude, climb rate,
    heading, flight phase, and the waypoint being flown to.
    Tip: in Excel, a scatter chart of east_m (x) vs north_m (y) shows the
    ground track, the actual shape the drone flew.
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
TARGET_ALT_M = 10     # flight altitude, meters above the launch point

# The pattern: a list (the square brackets) of waypoints, flown in order.
# Each waypoint is a "tuple" (the parentheses): two numbers kept together,
# (meters NORTH of the launch point, meters EAST of the launch point).
# Negative numbers mean south or west. All waypoints are flown at TARGET_ALT_M.
# This one is a 20 m square that ends back over home. Edit it to fly any shape.
PATTERN = [
    (20, 0),    # waypoint 1: 20 m north
    (20, 20),   # waypoint 2: 20 m north, 20 m east
    (0, 20),    # waypoint 3: 20 m east
    (0, 0),     # waypoint 4: back over home
]

# How close counts as "arrived." Too small and the drone may never quite
# count as there; too big and it cuts corners because the next waypoint is
# sent early. 1 m is a reasonable starting point for a 20 m pattern.
ARRIVE_RADIUS_M = 1.0

# SCRIPT-SIDE FAILSAFES (mission judgment; they only work while the link is
# up and this script is running). The autopilot's own failsafes are the
# backstop underneath these; set those in Mission Planner.
RTL_BATTERY_PCT = 40      # battery below this mid-pattern: skip the rest, fly home
WAYPOINT_TIMEOUT_S = 60   # still not at a waypoint after this long: give up, fly home


# ===========================================================================
# SECTION 1: CONNECT TO THE DRONE
# Open a MAVLink link and wait for the drone's heartbeat (a message every
# MAVLink device sends about once per second to say "I'm here").
# ===========================================================================

# Where to connect: whatever you type after the script name, or the
# simulator if you type nothing. sys.argv is the list of words you typed:
# sys.argv[0] is the script name, sys.argv[1] is the next word, and so on.
#   python pattern_flight.py                       -> simulator (default below)
#   python pattern_flight.py COM3                  -> telemetry radio on COM3
#   python pattern_flight.py udp:127.0.0.1:14550   -> a UDP network link
# Reads as: "use sys.argv[1] IF anything was typed, OTHERWISE the simulator."
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
                              #   (the _ is just a readable comma: 1,000,000)
        0, 0, 0, 0, 0,        # params 3-7: unused by this command
    )


# Two different position messages, because each is useful for something:
#   GLOBAL_POSITION_INT = latitude/longitude on the Earth, plus altitude
#   LOCAL_POSITION_NED  = meters north/east/down from home on a flat grid,
#                         which is what the waypoints in PATTERN use
request_message(mavutil.mavlink.MAVLINK_MSG_ID_GLOBAL_POSITION_INT, 4)  # lat/lon/alt, 4x/sec
request_message(mavutil.mavlink.MAVLINK_MSG_ID_SYS_STATUS, 2)           # battery, 2x/sec
request_message(mavutil.mavlink.MAVLINK_MSG_ID_GPS_RAW_INT, 2)          # GPS quality, 2x/sec
request_message(mavutil.mavlink.MAVLINK_MSG_ID_LOCAL_POSITION_NED, 4)   # meters N/E/down, 4x/sec


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
    msg = None                     # stays None unless a position message arrives
    while time.time() < deadline:
        # Accept either message type; timeout=1 means check the clock every second.
        incoming = m.recv_match(type=["GLOBAL_POSITION_INT", "STATUSTEXT"],
                                blocking=True, timeout=1)
        if incoming is None:
            continue               # nothing this second; go around again
        if incoming.get_type() == "STATUSTEXT":
            print(f"  autopilot says: {incoming.text}")
            continue               # printed it; keep waiting for position
        msg = incoming             # it's a position message: keep it...
        break                      # ...and leave the loop
    if msg is None:                # None = Python's "nothing"; no message arrived
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
    # [0] * 3 makes [0, 0, 0], so this adds however many zeros are missing.
    params = list(params) + [0] * (7 - len(params))
    # The * in *params "unpacks" the list into 7 separate values.
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
    return "NO REPLY"                      # timed out with no answer


def fly_to(north_m, east_m, alt_m):
    """Tell the autopilot to fly to a point, in meters from the launch point.

    Sends SET_POSITION_TARGET_LOCAL_NED, the GUIDED-mode "go here" message.
    It only works in GUIDED mode, which section 4 sets. The command is sent
    once; the autopilot keeps flying toward it until it gets a new target.
    """
    # The message has room for a target position, velocity, acceleration,
    # and yaw. The type_mask says which of those to IGNORE, one bit per field:
    # a 1 bit means "ignore this field." Read right to left in groups:
    #   ...1 1 0 | 1 1 1 | 1 1 1 | 0 0 0
    #    yaw etc.  accel   veloc   position
    # The three 0s on the right keep x, y, z (position). Everything else is
    # ignored, so the autopilot picks its own speed to get there.
    POSITION_ONLY = 0b110111111000   # 0b = binary; same number as 3576
    m.mav.set_position_target_local_ned_send(
        0,                                        # time_boot_ms (not needed)
        m.target_system, m.target_component,      # "to" address
        mavutil.mavlink.MAV_FRAME_LOCAL_NED,      # coordinate frame (see below)
        POSITION_ONLY,                            # which fields to use
        # LOCAL_NED = a flat grid centered near home, in meters:
        #   x = north, y = east, z = DOWN. So altitude goes in as a NEGATIVE z:
        #   10 m up is z = -10. Mixing this up would command the drone downward.
        north_m, east_m, -alt_m,                  # target position (x, y, z)
        0, 0, 0,                                  # velocity x, y, z (ignored)
        0, 0, 0,                                  # acceleration x, y, z (ignored)
        0, 0,                                     # yaw, yaw rate (ignored)
    )


def local_position():
    """Return (north_m, east_m): where the drone is on the home grid, or None."""
    # m.messages is pymavlink's store of the LATEST copy of every message type
    # it has received. .get() returns None instead of crashing if a message
    # type hasn't arrived yet. No waiting: this is instant.
    msg = m.messages.get("LOCAL_POSITION_NED")
    if msg is None:
        return None
    # Returning two values with a comma packs them into a tuple: (north, east).
    return msg.x, msg.y


def distance_to(north_m, east_m):
    """Horizontal distance in meters from the drone to a point, or None."""
    here = local_position()
    if here is None:
        return None
    dn = north_m - here[0]    # how far north still to go (here[0] = our north)
    de = east_m - here[1]     # how far east still to go  (here[1] = our east)
    # Pythagorean theorem: straight-line distance = sqrt(dn^2 + de^2).
    # In Python, ** means "to the power of," and ** 0.5 is a square root.
    # Altitude is left out on purpose: we only care about arriving over the spot.
    return (dn ** 2 + de ** 2) ** 0.5


def failsafe(reason, mode, t):
    """Abort the mission: say why, then hand control to an autopilot mode.

    The script doesn't try to fly the drone home itself. It switches to a
    mode where the AUTOPILOT does it:
      RTL  = Return To Launch: climb to a safe altitude, fly home, land.
      LAND = descend straight down from where it is, and disarm on touchdown.
    Handing off this way means the recovery keeps working even if this
    script stops right afterward.
    """
    print(f"  !! {t:6.1f} s  FAILSAFE: {reason} -> switching to {mode}")
    m.set_mode(m.mode_mapping()[mode])


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
# SECTION 6: FLY THE PATTERN AND LOG DATA
# A simple state machine. "phase" holds the current state:
#   climb   -> (reach 95% of target altitude)          -> pattern
#   pattern -> (arrive at each waypoint in turn)       -> land, after the last one
#   land    -> (on the ground and disarmed)            -> done
#   return  -> a failsafe fired; the autopilot is flying home in RTL mode
#              (ends like land: on the ground and disarmed)
# Each pass through the loop (about 4 per second, set by the position rate):
#   1. read position   2. log a row   3. print status   4. check for a phase change
# ===========================================================================

# FAILSAFE 3 (Ctrl+C): everything below sits inside "try". If you press
# Ctrl+C mid-flight, Python jumps straight to the "except KeyboardInterrupt"
# part at the bottom, which commands LAND before the script exits. Without
# this, the script would just stop and leave the drone hovering with nobody
# in charge of it.
try:
    # "with open(...)" opens the file and closes it automatically when done.
    # "w" = write (replaces the file if it already exists).
    with open("pattern_log.csv", "w", newline="") as f:
        log = csv.writer(f)
        log.writerow(["time_s", "t_vehicle_s", "lat_deg", "lon_deg",      # column headers
                      "north_m", "east_m", "alt_m", "climb_ms", "heading_deg",
                      "phase", "waypoint"])
        t0 = time.time()   # stopwatch start for the time_s column

        # State that carries over from one pass of the loop to the next:
        phase = "climb"      # current state of the state machine
        wp_index = 0         # which waypoint we're flying to. Python counts from 0,
                             # so PATTERN[0] is waypoint 1, PATTERN[1] is waypoint 2...
        last_state = None    # last (mode, armed) we announced; used to spot changes
        rows = []            # a copy of key values, kept for the summary at the end
        wp_started = None    # when we started flying to the current waypoint
        abort_reason = None  # stays None unless a failsafe fires

        # Battery level at takeoff, to compute "battery used" in the summary.
        batt_msg = m.messages.get("SYS_STATUS")
        start_batt = batt_msg.battery_remaining if batt_msg else None

        while True:   # loop forever; the "break" in the land phase ends it

            # --- 1. Read position ---------------------------------------------
            p = position()
            if p is None:
                # position() already waited 5 s. Say so instead of retrying silently.
                print("  !! WARNING: no position data for 5 s. Retrying ...")
                continue
            alt = p["alt_m"]
            t = round(time.time() - t0, 2)   # seconds since takeoff command (laptop clock)

            # --- 2. Log a row -------------------------------------------------
            # "A or B" gives B when A is None. So if there's no local position
            # yet, "here" becomes (None, None) and those cells are left blank.
            here = local_position() or (None, None)
            north = round(here[0], 2) if here[0] is not None else ""
            east = round(here[1], 2) if here[1] is not None else ""
            # Waypoint number for the log: 1-based for humans, blank outside the pattern.
            waypoint = wp_index + 1 if phase == "pattern" else ""
            log.writerow([t, p["t_vehicle_s"], p["lat_deg"], p["lon_deg"],
                          north, east, round(alt, 2), round(p["climb_ms"], 2),
                          p["heading_deg"], phase, waypoint])
            # .append adds one item to the end of a list. Each item here is a
            # tuple of 4 values: (time, altitude, climb rate, phase).
            rows.append((t, alt, p["climb_ms"], phase))

            # --- 3. Print status ----------------------------------------------
            # Announce mode or armed-state changes the moment they happen.
            # state is a tuple like ("GUIDED", True); comparing it to last time
            # tells us whether anything changed.
            state = (m.flightmode, m.motors_armed())
            if state != last_state:
                print(f"  >> {t:6.1f} s  mode {state[0]}, {'ARMED' if state[1] else 'DISARMED'}")
                last_state = state

            # Live status line. Battery and GPS come from m.messages (the latest
            # copy of each), so reading them here doesn't slow the loop down.
            # m.time_since("HEARTBEAT") = seconds since the drone's last heartbeat;
            # normally under 1 s. Growing past 3 s means the link is in trouble.
            batt = m.messages.get("SYS_STATUS")
            gps = m.messages.get("GPS_RAW_INT")
            # voltage_battery arrives in millivolts, so / 1000 gives volts.
            # "--" is shown if that message hasn't arrived yet.
            batt_txt = f"{batt.battery_remaining}% {batt.voltage_battery / 1000:.1f}V" if batt else "--"
            gps_txt = f"{gps.satellites_visible} sats" if gps else "--"
            link_age = m.time_since("HEARTBEAT")
            # f-string formats: {alt:5.1f} = 5 characters wide, 1 decimal place.
            print(f"{t:6.1f} s  alt {alt:5.1f} m  climb {p['climb_ms']:5.2f} m/s  "
                  f"batt {batt_txt}  gps {gps_txt}  link {link_age:.1f}s  ({phase})")
            if link_age > 3:
                print(f"  !! WARNING: no heartbeat for {link_age:.1f} s. Link may be down.")

            # --- 4. Check for a phase change ----------------------------------
            # if / elif: only ONE branch runs per pass, the first whose test is true.
            if phase == "climb" and alt >= TARGET_ALT_M * 0.95:
                # Within 5% of target altitude: start the pattern by sending
                # waypoint 1. PATTERN[0] is the tuple (20, 0); [0][0] is its
                # north value and [0][1] its east value.
                phase, wp_index = "pattern", 0
                fly_to(PATTERN[0][0], PATTERN[0][1], TARGET_ALT_M)
                wp_started = time.time()   # start the timeout clock for this waypoint
                print(f"  >> {t:6.1f} s  phase climb -> pattern, flying to waypoint 1 {PATTERN[0]}")

            elif phase == "pattern":
                # Every pass: how far are we from the waypoint we're flying to?
                target = PATTERN[wp_index]
                dist = distance_to(target[0], target[1])
                # FAILSAFE 1: battery too low to finish the pattern.
                # "0 <=" skips the check if the battery reads -1 (unknown).
                if batt and 0 <= batt.battery_remaining < RTL_BATTERY_PCT:
                    abort_reason = f"battery at {batt.battery_remaining}% (limit {RTL_BATTERY_PCT}%)"
                    failsafe(abort_reason, "RTL", t)
                    phase = "return"
                    continue   # skip the rest of this pass; the next pass is in "return"

                # FAILSAFE 2: taking too long to reach this waypoint.
                if time.time() - wp_started > WAYPOINT_TIMEOUT_S:
                    abort_reason = (f"waypoint {wp_index + 1} not reached in "
                                    f"{WAYPOINT_TIMEOUT_S} s ({dist:.1f} m away)"
                                    if dist is not None else
                                    f"waypoint {wp_index + 1} not reached in {WAYPOINT_TIMEOUT_S} s")
                    failsafe(abort_reason, "RTL", t)
                    phase = "return"
                    continue

                # "dist is not None" guards against having no local position yet.
                if dist is not None and dist < ARRIVE_RADIUS_M:
                    print(f"  >> {t:6.1f} s  reached waypoint {wp_index + 1} of {len(PATTERN)} {target}")
                    wp_index += 1                       # += 1 means "add 1": next waypoint
                    # len(PATTERN) = how many waypoints (4). If wp_index is now
                    # less than that, there's another waypoint to fly to.
                    if wp_index < len(PATTERN):
                        nxt = PATTERN[wp_index]
                        fly_to(nxt[0], nxt[1], TARGET_ALT_M)
                        wp_started = time.time()   # reset the timeout clock
                        print(f"  >> {t:6.1f} s  flying to waypoint {wp_index + 1} {nxt}")
                    else:
                        # That was the last waypoint. LAND mode makes the autopilot
                        # descend straight down from where it is and disarm on touchdown.
                        m.set_mode(m.mode_mapping()["LAND"])
                        phase = "land"
                        print(f"  >> {t:6.1f} s  pattern complete -> land (LAND mode requested)")

            elif phase in ("land", "return") and alt < 0.3 and not m.motors_armed():
                # "in (...)" = matches either phase: a normal landing or a failsafe return.
                # Within 30 cm of the ground AND the autopilot has disarmed:
                # the flight is over, so leave the loop (and close the log file).
                break

except KeyboardInterrupt:
    # Ctrl+C lands here. Hand off to the autopilot, then exit.
    print("\n  !! FAILSAFE: operator pressed Ctrl+C -> switching to LAND")
    m.set_mode(m.mode_mapping()["LAND"])
    raise SystemExit("Script stopped. The autopilot is landing on its own; "
                     "watch it on the Mission Planner map.")

print("Landed and disarmed. Flight log saved to pattern_log.csv")

# ===========================================================================
# FLIGHT SUMMARY: an automatic mini test report from the data we kept.
# Each item in "rows" is (time, altitude, climb rate, phase), so for a row r:
#   r[0] = time, r[1] = altitude, r[2] = climb rate, r[3] = phase.
# ===========================================================================

# A "list comprehension": build a new list in one line. Reads as "the
# altitude of every row, but only rows where the phase was pattern."
hover = [r[1] for r in rows if r[3] == "pattern"]
print("\nFLIGHT SUMMARY")
print(f"  Mission result:    {'ABORTED: ' + abort_reason if abort_reason else 'completed'}")
print(f"  Flight time:       {rows[-1][0]:.1f} s")      # rows[-1] = the LAST row
print(f"  Max altitude:      {max(r[1] for r in rows):.2f} m (target {TARGET_ALT_M} m)")
if hover:   # skip this line if the pattern phase never happened
    # How well altitude was held while moving between waypoints.
    print(f"  Pattern altitude:  avg {sum(hover) / len(hover):.2f} m, "
          f"range {min(hover):.2f} to {max(hover):.2f} m")
print(f"  Max climb rate:    {max(r[2] for r in rows):.2f} m/s")
# Descent shows as a negative climb rate, so the most negative value is the
# fastest descent; the minus sign turns it back into a positive number.
print(f"  Max descent rate:  {-min(r[2] for r in rows):.2f} m/s")
end_batt = m.messages.get("SYS_STATUS")
if start_batt is not None and end_batt:
    print(f"  Battery used:      {start_batt - end_batt.battery_remaining}% "
          f"({start_batt}% -> {end_batt.battery_remaining}%)")
