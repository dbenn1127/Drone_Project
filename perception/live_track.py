"""
live_track.py - Follow-me perception prototype: detect, designate, and range a person.

WHAT IT DOES
    1. Reads frames from the camera (iPhone via Iriun webcam).
    2. Detects people with YOLO11n and tracks them across frames with ByteTrack.
    3. Lets the operator designate ONE person as the target by clicking them.
    4. For the target, estimates bearing (from box center) and range (from box height).
    5. If the target disappears, shows LOST, then HOVER after LOST_TIMEOUT_S.
       It never switches to a different person on its own.

HOW TO RUN (Anaconda Prompt, from the repo folder)
    python perception\live_track.py
    Click a person to designate them. Press r to clear the target, q to quit.

REQUIREMENTS TRACEABILITY
    Requirement  What this script does                               Status
    -----------  --------------------------------------------------  ----------------------------
    PER-1        Detects persons with YOLO11n (class 0 = person)     Implemented; range limits untested
    PER-2        Keeps target identity across frames via ByteTrack   Partial: ByteTrack drops a lost
                                                                      ID after ~30 frames (~1 s)
    PER-3        Target set ONLY by operator click; no auto-lock      Implemented; second-person test open
                 and no automatic switch to another person
    PER-4        Frame rate >= 10 Hz                                  Not yet measured
    EST-1        Bearing from box center via pinhole model           Implemented; fx from estimated FOV
    EST-2        Range from box height via pinhole model             Implemented; tape test pending
    SAF-3        Target lost > LOST_TIMEOUT_S -> HOVER + alert        Implemented (display only;
                                                                      no vehicle commands yet)

    Model elements: Logical::DetectPersons, TrackDesignatedTarget, EstimateTarget;
    Behavior::FollowModeController states tracking -> lost -> hover.

KNOWN LIMITATIONS
    - fx comes from an ESTIMATED horizontal field of view (hfov_deg). Bearing and
      range accuracy (EST-1, EST-2) stay TBR until checkerboard calibration (roadmap step 3).
    - Range assumes the target's real height (PERSON_HEIGHT_M) and a full-body box.
      Sitting, crouching, or legs cut off by the frame make range read too far.
    - Range is unfiltered; smoothing is roadmap step 2.
"""

import math
import time

import cv2
from ultralytics import YOLO


# ---------------------------------------------------------------------------
# SETTINGS
# ---------------------------------------------------------------------------
hfov_deg = 65            # Camera horizontal field of view in degrees (ESTIMATE).
                         # Drives fx, so it affects EST-1 and EST-2. [TBR until calibration]
LOST_TIMEOUT_S = 2.0     # SAF-3: seconds lost before LOST becomes HOVER. [TBR]
PERSON_HEIGHT_M = 1.88   # EST-2: assumed target height in meters (Derek, 6'2").
                         # Open design question: real system can't know target height.


# ---------------------------------------------------------------------------
# SETUP: model, camera, and state
# ---------------------------------------------------------------------------
model = YOLO("yolo11n.pt")       # PER-1: person detector (downloads on first run)
cap = cv2.VideoCapture(0)        # Iriun camera; try 1 or 2 if 0 is wrong

target_id = None    # PER-3: track ID of the operator-designated target; None = no target
lost_since = None   # SAF-3: time the target went missing; None = not lost
last_boxes = []     # This frame's boxes as (x1, y1, x2, y2, tid), read by on_click

# Pinhole camera model (EST-1, EST-2).
#   cx = image center column in pixels (where bearing = 0)
#   fx = focal length in pixels, from: tan(hfov/2) = (width/2) / fx
width = cap.get(cv2.CAP_PROP_FRAME_WIDTH)   # frame width in pixels, e.g. 1280
cx = width / 2
fx = (width / 2) / math.tan(math.radians(hfov_deg / 2))

print("width:", width, "cx:", cx, "fx:", fx)


# ---------------------------------------------------------------------------
# OPERATOR DESIGNATION (PER-3)
# OpenCV calls this on every mouse event in the window. A left click inside a
# person's box makes that person the target. A click on empty space does
# nothing, so a stray click can never change or clear the target.
# ---------------------------------------------------------------------------
def on_click(event, x, y, flags, param):
    global target_id
    if event == cv2.EVENT_LBUTTONDOWN:
        for x1, y1, x2, y2, tid in last_boxes:
            if x1 <= x <= x2 and y1 <= y <= y2:
                target_id = tid
                print(f"Target designated: ID {tid}")
                break


cv2.namedWindow("Follow-me perception", cv2.WINDOW_NORMAL)
cv2.setMouseCallback("Follow-me perception", on_click)


# ---------------------------------------------------------------------------
# MAIN LOOP: one pass = one camera frame
# ---------------------------------------------------------------------------
while True:
    ok, frame = cap.read()
    if not ok:
        break

    # Detect and track people (PER-1, PER-2). classes=[0] keeps only "person".
    # persist=True keeps ByteTrack's IDs from frame to frame.
    results = model.track(frame, persist=True, tracker="bytetrack.yaml",
                          classes=[0], verbose=False)
    boxes = results[0].boxes
    found = False          # becomes True if the designated target is seen this frame
    last_boxes.clear()     # start fresh each frame

    # Vertical line at the image center: bearing = 0 here.
    cv2.line(frame, (int(cx), 0), (int(cx), frame.shape[0]), (255, 255, 255), 1)

    # Draw every person; the designated target is green, everyone else grey.
    if boxes.id is not None:
        for (x1, y1, x2, y2), tid in zip(boxes.xyxy.tolist(), boxes.id.int().tolist()):
            last_boxes.append((x1, y1, x2, y2, tid))   # available to on_click

            if tid == target_id:
                # EST-1: bearing from the horizontal offset of the box center.
                # Positive = target right of center, negative = left.
                u = (x1 + x2) / 2
                bearing = math.degrees(math.atan((u - cx) / fx))

                # EST-2: range from box height (pinhole model):
                #   distance = fx * real height / height in pixels
                h_px = y2 - y1                              # box height in pixels
                if h_px > 0:
                    distance = fx * PERSON_HEIGHT_M / h_px      # meters
                    cv2.putText(frame, f"Range: {distance:.1f} m", (30, 120),
                                                cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 0), 2)
                cv2.putText(frame, f"Bearing: {bearing:.1f} deg", (30, 80),
                            cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 0), 2)
                
                found = True

            color = (0, 255, 0) if tid == target_id else (128, 128, 128)
            cv2.rectangle(frame, (int(x1), int(y1)), (int(x2), int(y2)), color, 2)
            cv2.putText(frame, f"ID {tid}", (int(x1), int(y1) - 8),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.8, color, 2)

    # Target-loss handling (PER-3, SAF-3). Mirrors the model's state machine:
    #   tracking -> lost   (target not seen this frame)
    #   lost -> tracking   (SAME track ID seen again)
    #   lost -> hover      (lost longer than LOST_TIMEOUT_S)
    #   hover -> tracking  (operator clicks a person)
    # target_id is NEVER cleared here, so the system can't switch people on its own.
    if found:
        lost_since = None
    elif target_id is not None:
        if lost_since is None:
            lost_since = time.time()               # target just went missing
        lost_for = time.time() - lost_since        # seconds missing (clock, not frames)
        if lost_for < LOST_TIMEOUT_S:
            cv2.putText(frame, f"LOST {lost_for:.1f} s", (30, 40),
                        cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 0, 255), 2)
        else:
            # SAF-3: on the vehicle this is where the companion commands zero
            # velocity and alerts the GCS. Here it is a display-only alert.
            cv2.putText(frame, "Hover - click to redesignate", (30, 40),
                        cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 0, 255), 2)

    cv2.imshow("Follow-me perception", frame)

    # Keyboard: q = quit, r = operator clears the target (an operator action,
    # so it's allowed under PER-3).
    key = cv2.waitKey(1) & 0xFF
    if key == ord("q"):
        break
    if key == ord("r"):
        target_id = None

cap.release()
cv2.destroyAllWindows()