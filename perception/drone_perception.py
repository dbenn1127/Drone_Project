"""
drone_perception.py - The Jetson's perception program (step 5).
Camera -> YOLO11n + ByteTrack -> boxes drawn on the frame -> video + box list to the ground.
Later (4.3): designated target, bearing/range to follow_sim, ACK/NACK.
"""
import json
import math
import socket
import time
import cv2
from ultralytics import YOLO

GROUND_IP = "192.168.4.153"          # the laptop (ground station)
VIDEO_PORT, BOXES_PORT = 5600, 5601
DESIGNATE_PORT = 5602
SEND_W, SEND_H = 640, 360
JPEG_QUALITY = 70
MAX_UDP = 65000
# ← NEW (part 6): perception message to the follow logic
PERCEPTION_ADDR = (GROUND_IP, 5005)   # laptop for testing; PC (follow_sim) in 4.4
HFOV_DEG = 62.2           # IMX219 horizontal field of view, deg. [TBR - see note]
PERSON_HEIGHT_M = 1.88    # EST-2: assumed target height (you, 6'2")
LOST_TIMEOUT_S = 2.0      # SAF-3: lost this long -> hover

GST = ( "nvarguscamerasrc sensor-id=0 ! "
       "video/x-raw(memory:NVMM),width=1920,height=1080,framerate=30/1 ! "
       "nvvidconv flip-method=2 ! video/x-raw,width=1280,height=720,format=BGRx ! "
       "videoconvert ! video/x-raw,format=BGR ! "
       "appsink drop=true max-buffers=1")                         # same pipeline as video_send.py, with flip-method=2

model = YOLO("yolo11n.engine", task="detect")
cap = cv2.VideoCapture(GST, cv2.CAP_GSTREAMER)
if not cap.isOpened():
    raise SystemExit("Camera did not open")

# ← NEW: pinhole camera numbers for the FULL frame we run YOLO on (1280 wide)
FRAME_W = 1280
cx = FRAME_W / 2                                           # bearing = 0 at this column
fx = (FRAME_W / 2) / math.tan(math.radians(HFOV_DEG / 2))  # focal length, pixels
print(f"cx {cx:.0f}  fx {fx:.0f}")

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

# ← NEW: socket for receiving designation commands (bound, so it gets mail on 5602)
cmd_sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
cmd_sock.bind(("0.0.0.0", DESIGNATE_PORT))
cmd_sock.setblocking(False)  # never wait; the camera loop must keep running

target_id = None             # PER-3: the operator-designated track ID, None = no target
last_reply = None            # newest ACK/NACK, repeated in every box list message
lost_since = None            # ← NEW: SAF-3: when the target went missing; None = not lost
frame_no = 0

def newest_command():
    """Read every waiting command; return only the newest (or None if none waiting)."""
    newest = None
    while True:
        try:
            data, addr = cmd_sock.recvfrom(1024)
            newest = json.loads(data)
        except BlockingIOError:
            break
    return newest
        

while True:
    ok, frame = cap.read()                       # 1280x720
    if not ok:
        break
    frame_no += 1

    # Detect + track people on the FULL frame.
    results = model.track(frame, persist=True, classes=[0],
                          tracker="bytetrack.yaml", verbose=False)
    boxes = results[0].boxes

        # IDs the tracker sees in THIS frame
    current_ids = boxes.id.int().tolist() if boxes.id is not None else []

    # designation command from the ground? Check it, then ACK or NACK.
    cmd = newest_command()
    if cmd is not None:
        if cmd["designate"] in current_ids:
            target_id = cmd["designate"]
            last_reply = {"seq": cmd["seq"], "ok": True, "target": target_id}
        else:
            # Never substitute someone else (PER-3): refuse and let the operator click again.
            last_reply = {"seq": cmd["seq"], "ok": False,
                          "reason": f"ID {cmd['designate']} not in view"}
        print("designation:", last_reply)

    # where is the designated target? (full-frame pixels, so use cx/fx from 1280)
    bearing = None       # deg, + = right of center. None unless seen THIS frame
    range_m = None       # meters, from box height
    found = False
    if target_id is not None and boxes.id is not None:
        for (x1, y1, x2, y2), tid in zip(boxes.xyxy.tolist(), current_ids):
            if tid == target_id:
                u = (x1 + x2) / 2                                  # EST-1: box center column
                bearing = math.degrees(math.atan((u - cx) / fx))
                h_px = y2 - y1                                     # EST-2: box height
                if h_px > 0:
                    range_m = fx * PERSON_HEIGHT_M / h_px
                found = True

    # status for the follow logic (SAF-3)
    #   none     = nobody designated
    #   tracking = target seen this frame
    #   lost     = missing less than LOST_TIMEOUT_S
    #   hover    = missing longer -> operator must click again (PER-3: no substitutes)
    if target_id is None:
        status = "none"
    elif found:
        status = "tracking"
        lost_since = None
    else:
        if lost_since is None:
            lost_since = time.time()          # just went missing: start the clock
        if time.time() - lost_since < LOST_TIMEOUT_S:
            status = "lost"
        else:
            status = "hover"

    # ← TEMP (6b test): once a second, show what we computed
    if frame_no % 30 == 0:
        b = f"{bearing:+.1f} deg" if bearing is not None else "-"
        r = f"{range_m:.1f} m" if range_m is not None else "-"
        print(f"{status:8}  bearing {b:>10}  range {r:>7}")

    # Shrink for sending; boxes must shrink by the same factor.
    small = cv2.resize(frame, (SEND_W, SEND_H))
    scale = SEND_W / frame.shape[1]                                 # small width / full width

    box_list = []
    if boxes.id is not None:
        for (x1, y1, x2, y2), tid in zip(boxes.xyxy.tolist(), boxes.id.int().tolist()):
            sx1, sy1, sx2, sy2 = [int(val * scale) for val in [x1, y1, x2, y2]]
            box_list.append([tid, sx1, sy1, sx2, sy2])
            
            # Draw it on the small frame: grey box + "ID n" label (like live_track.py).
            color = (0, 255, 0) if tid == target_id else (128, 128, 128)   # ← NEW: green = target
            cv2.rectangle(small, (sx1, sy1), (sx2, sy2), color, 2)          # ← CHANGED: color
            cv2.putText(small, f"ID {tid}", (sx1, sy1 - 6),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.5, color, 1)            # ← CHANGED: color

    # Send the picture, then the box list.
    ok, jpg = cv2.imencode(".jpg", small, [cv2.IMWRITE_JPEG_QUALITY, JPEG_QUALITY])
    data = jpg.tobytes()
    if len(data) <= MAX_UDP:
        sock.sendto(data, (GROUND_IP, VIDEO_PORT))
    msg = {"frame": frame_no, "boxes": box_list,
        "target": target_id, "reply": last_reply}                       # ← CHANGED: 2 new fields
    sock.sendto(json.dumps(msg).encode(), (GROUND_IP, BOXES_PORT))    # same encoding as live_track.py's message