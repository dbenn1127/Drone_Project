# Follow-Me Drone Requirements

Baseline v0.1 · Source of truth: `Model/follow_me_drone.sysml` (draft 0.3)

TBR = to be resolved (first-pass value, confirmed by bench test, calibration, or SITL).
Pending = design decision awaiting confirmation.

## Stakeholder needs

| ID | Need |
|---|---|
| N-1 | The drone follows a person using its own camera, without the person carrying a device or transmitting their position. |
| N-2 | The operator can take back control or abort at any time. |
| N-3 | The system flies safely and within FAA recreational rules. |
| N-4 | The system uses affordable, open components (ArduPilot, MAVLink, commodity compute) so it can be studied, modified, and shown as portfolio work. |

## Perception

| ID | Requirement | Verify | Traces to | Satisfied by | Status |
|---|---|---|---|---|---|
| PER-1 | Detect persons in camera imagery at ranges from 3 m to 20 m. | Test | N-1 | Jetson (autonomy) | TBR |
| PER-2 | Maintain the designated target's identity through viewpoint changes (front, side, rear) and occlusions of up to 1.0 s. | Test | N-1 | Jetson (autonomy) | TBR |
| PER-3 | Acquire a target only by operator designation; do not transfer to a different person during flight without operator action. | Simulation | N-1, N-2 | Follow-mode state machine | Confirmed |
| PER-4 | Process frames for detection and tracking at no less than 10 Hz on the companion computer. | Test | N-1 | Jetson (autonomy) | |
v
## Estimation

| ID | Requirement | Verify | Traces to | Satisfied by | Status |
|---|---|---|---|---|---|
| EST-1 | Estimate horizontal bearing to the target within ±3° over the detection range. | Test | N-1 | Jetson (autonomy) | TBR |
| EST-2 | Estimate range to the target within ±20% over the detection range. | Test | N-1 | Jetson (autonomy) | TBR |
| EST-3 | Estimate the target's horizontal velocity within ±0.5 m/s for control feedforward. | Simulation | N-1 | Jetson (autonomy) | TBR |
| EST-4 | Compensate target estimates for vehicle attitude and heading using flight controller telemetry. | Simulation | N-1 | Jetson (autonomy) | |

## Control

| ID | Requirement | Verify | Traces to | Satisfied by | Status |
|---|---|---|---|---|---|
| CTL-1 | Keep the target within ±10° of the camera centerline while the target walks at up to 2 m/s. | Simulation | N-1 | Jetson (autonomy) | TBR |
| CTL-2 | Hold an operator-set standoff distance (default 8 m, settable 5–20 m) within ±2 m while the target walks steadily. | Simulation | N-1, N-3 | Jetson (autonomy) | TBR |
| CTL-3 | Command horizontal velocity and yaw rate only, at no less than 10 Hz, limited to 5 m/s and 60°/s. | Test | N-3 | Jetson (autonomy) | TBR |
| CTL-4 | The follow function shall not command altitude changes; the vehicle holds the operator-set altitude. | Simulation | N-3 | Jetson (autonomy) | |

## Safety

| ID | Requirement | Verify | Traces to | Satisfied by | Status |
|---|---|---|---|---|---|
| SAF-1 | The companion sends motion commands only while the vehicle is in Guided mode; an operator mode change out of Guided returns full control immediately. | Test | N-2 | Follow-mode state machine | |
| SAF-2 | The companion shall not arm, take off, land, or change flight mode; these are reserved for the operator. | Inspection | N-2 | Follow-mode state machine | Confirmed |
| SAF-3 | If the target is lost for more than 2 s, command zero velocity (hover) and alert the operator via the GCS. | Simulation | N-3 | Follow-mode state machine | TBR |
| SAF-4 | The vehicle shall remain at least 5m horizontally from the target, including braking distance. | Simulation | N-3 | Jetson (autonomy) | |
| SAF-5 | If motion commands stop arriving for more than 3 s, the vehicle stops and holds position. | Test | N-3 | Pixhawk 6C (avionics) | TBR |
| SAF-6 | Return to launch on RC signal loss, low battery, or geofence breach. Geofence: 150 m radius, 30 m AGL. All failsafes verified before first flight. | Test | N-3 | Pixhawk 6C (avionics) | TBR |
| SAF-7 | The operator's RC transmitter provides a motor emergency stop switch. | Test | N-2 | RC transmitter (ground) | |
| SAF-8 | Operate only in open areas with no obstacles within 15 m horizontally of the operator's planned route. Version 1 provides no obstacle avoidance; the operator selects the site and keeps the vehicle in sight. | Inspection | N-3 | Drone system (operating procedure) | TBR |

## Interfaces, performance, and regulatory

| ID | Requirement | Verify | Traces to | Satisfied by | Status |
|---|---|---|---|---|---|
| INT-1 | The companion communicates with the flight controller using MAVLink 2 over serial (TELEM2). | Inspection | N-4 | Air vehicle (MAVLink link) | |
| INT-2 | The operator's RC link is independent of the companion computer and the GCS. | Inspection | N-2 | Drone system | |
| INT-3 | The GCS displays flight mode, battery, position, tracking status (searching, tracking, lost), bearing, and range over 915 MHz telemetry. | Test | N-2 | Ground control station | |
| PRF-1 | Latency from camera frame capture to the corresponding motion command does not exceed 200 ms. | Test | N-1 | Air vehicle | TBR |
| PRF-2 | The vehicle flies at least 10 min with the full payload. | Test | N-1 | Air vehicle | TBR |
| PRF-3 | The system operates in daylight, dry conditions, with wind up to 5 m/s. | Test | N-3 | Drone system | TBR |
| REG-1 | Operated under FAA recreational rules: registered, Remote ID compliant, TRUST certificate, visual line of sight, ≤ 400 ft AGL. | Inspection | N-3 | Remote ID module (avionics) | |

## Verification evidence

SITL results from `sim/follow_sim.py` (ArduPilot SITL via Mission Planner). Rows marked "logged" come from the flight log's own range, bearing, and command columns; the others were read from console output. Status values stay TBR until the values are confirmed for the final design.

| Date | Requirement | Test | Result | Verdict |
|---|---|---|---|---|
| 2026-10-02 | CTL-2 | Target walks straight at 1.5 m/s; standoff 8 m; range gain 0.5 | Settled at 11.0 m | Fail (gain too low) |
| 2026-10-02 | CTL-2 | Same; range gain 1.0 | Settled at 9.51 m (predicted 9.5 m) | Pass, 0.5 m margin |
| 2026-10-02 | CTL-1 | Same run, bearing to target | ≤ 5.2° | Pass, straight path |
| 2026-10-02 | CTL-3 | Command limits in code | 5 m/s, 60°/s, 10 Hz loop | Implemented; rate not yet measured |
| 2026-10-02 | CTL-4 | Same run, altitude | Steady; vz always 0 | Pass |
| 2026-10-02 | CTL-1 | Target circles 10 m radius at 1.5 m/s (logged) | Bearing settled −4.29° (predicted 4.3°); max 4.47° | Pass |
| 2026-10-02 | CTL-2 | Same run | Range settled 8.83–8.86 m | Pass |
| 2026-10-02 | CTL-3 | Same run, loop timing from log | 10.0 Hz mean, longest gap 0.14 s; max commands 8.9°/s, 2.1 m/s | Pass |
| 2026-10-02 | CTL-4 | Same run, altitude | 9.57–10.04 m | Pass |
| 2026-10-05 | CTL-2 | Straight walk at 1.5 m/s, standoff 8 m, altitude 6 m (logged) | Settled 9.47–9.53 m (predicted 9.5 m) | Pass |
| 2026-10-05 | CTL-1 | Same run | Max 5.24° while catching up; settled 0.0° | Pass |
| 2026-10-05 | CTL-3 | Same run | 10.0 Hz, longest gap 0.13 s; max commands 10.5°/s, 2.0 m/s | Pass |
| 2026-10-05 | CTL-4 | Same run | 5.76–6.06 m at a 6 m setting | Pass |
| 2026-10-06 | SAF-1 | Mid-follow, operator switches to BRAKE in Mission Planner (logged) | Commands stop on the same 10 Hz pass (last command 11.24 s, idle from 11.33 s); 0 commands afterward; script makes no mode change | Pass |
| 2026-10-06 | SAF-1 | Same run: operator keeps control past the end-of-test time | Hovered at 6.07 m through the 60 s follow mark with no forced LAND; operator then chose RTL; script ended at disarm | Pass |
| 2026-10-03 | PER-4 | `live_track.py` on desktop GPU (RTX 3090 Ti), live camera | 30 FPS loop (camera-limited); YOLO 7–8 ms (CUDA), 3–4 ms (TensorRT FP16) | Pass on desktop; Jetson measurement pending |
| 2026-10-02 | SAF-4 | Fault injection: standoff 3 m; keep-out v1 (zero approach command inside 5 m) | Closest 3.2 m; 237 of 600 samples inside 5 m | Fail |
| 2026-10-02 | SAF-4 | Same; keep-out v2 (approach speed ≤ 0.5 × (range − 5)) | Closest 6.86 m; 0 of 600 samples inside 5 m; settled 8.0 m | Pass |

Finding: SAF-4 as written limits commands ("do not command motion within 5 m"), but v1 met that wording and still let the vehicle reach 3.2 m. Proposed rewording to the vehicle outcome is listed under open items.

## Open items

- [ ] Resolve PER-1, PER-2 on the bench with the Jetson.
- [ ] Resolve EST-1 to EST-3 after camera calibration.
- [ ] Confirm CTL-1 to CTL-4 on hardware. (SITL evidence complete: straight and circle runs, logged, recorded above.)
- [ ] Decide SAF-4 wording: change to the vehicle outcome, e.g. "The vehicle shall remain at least 5 m horizontally from the target, including braking distance."
- [ ] Resolve SAF-3, SAF-5, SAF-6 in SITL.
- [ ] Hand-back after a takeover: re-entering Guided should go to searching and wait for operator designation (model transition idle → searching). Today the script stays idle.
- [ ] Resolve PRF-1 to PRF-3 once hardware is chosen.
- [ ] Size the companion regulator (Jetson input voltage from battery).
- [ ] Obstacle avoidance (planned upgrade, after flight hardware): forward lidar rangefinder with ArduPilot's built-in avoidance, tested in SITL first. Would relax SAF-8.
- [ ] GPS-denied navigation (version 2): would add a stakeholder need (e.g. N-5, "operate when GPS is unavailable") and its own requirements (position accuracy, drift, compute budget shared with perception). Visual SLAM on the Jetson with a stereo depth camera, feeding ArduPilot as an external position source.