"""
drone_perception.py - The Jetson's perception program (step 5).
Camera -> YOLO11n + ByteTrack -> boxes drawn on the frame -> video + box list to the ground.
Later (4.3): designated target, bearing/range to follow_sim, ACK/NACK.
"""
import json
import socket
import time
import cv2
from ultralytics import YOLO

GROUND_IP = "192.168.4.153"          # the laptop (ground station)
VIDEO_PORT, BOXES_PORT = 5600, 5601
SEND_W, SEND_H = 640, 360
JPEG_QUALITY = 70
MAX_UDP = 65000

GST = ( "nvarguscamerasrc sensor-id=0 ! "
       "video/x-raw(memory:NVMM),width=1920,height=1080,framerate=30/1 ! "
       "nvvidconv flip-method=2 ! video/x-raw,width=1280,height=720,format=BGRx ! "
       "videoconvert ! video/x-raw,format=BGR ! "
       "appsink drop=true max-buffers=1")                         # same pipeline as video_send.py, with flip-method=2

model = YOLO("yolo11n.engine", task="detect")
cap = cv2.VideoCapture(GST, cv2.CAP_GSTREAMER)
if not cap.isOpened():
    raise SystemExit("Camera did not open")
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

frame_no = 0
while True:
    ok, frame = cap.read()                       # 1280x720
    if not ok:
        break
    frame_no += 1

    # Detect + track people on the FULL frame.
    results = model.track(frame, persist=True, classes=[0],
                          tracker="bytetrack.yaml", verbose=False)
    boxes = results[0].boxes

    # Shrink for sending; boxes must shrink by the same factor.
    small = cv2.resize(frame, (SEND_W, SEND_H))
    scale = SEND_W / frame.shape[1]                                 # small width / full width

    box_list = []
    if boxes.id is not None:
        for (x1, y1, x2, y2), tid in zip(boxes.xyxy.tolist(), boxes.id.int().tolist()):
            sx1, sy1, sx2, sy2 = [int(val * scale) for val in [x1, y1, x2, y2]]
            box_list.append([tid, sx1, sy1, sx2, sy2])
            
            # Draw it on the small frame: grey box + "ID n" label (like live_track.py).
            cv2.rectangle(small, (sx1, sy1), (sx2, sy2), (128, 128, 128), 2)
            cv2.putText(small, f"ID {tid}", (sx1, sy1 - 6),
                cv2.FONT_HERSHEY_SIMPLEX, 0.5, (128, 128, 128), 1)


    # Send the picture, then the box list.
    ok, jpg = cv2.imencode(".jpg", small, [cv2.IMWRITE_JPEG_QUALITY, JPEG_QUALITY])
    data = jpg.tobytes()
    if len(data) <= MAX_UDP:
        sock.sendto(data, (GROUND_IP, VIDEO_PORT))
    msg = {"frame": frame_no, "boxes": box_list}
    sock.sendto(json.dumps(msg).encode(), (GROUND_IP, BOXES_PORT))    # same encoding as live_track.py's message