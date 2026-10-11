"""
jetson_live.py - Live perception timing test on the Jetson (headless).

Grabs frames from the CSI camera, runs YOLO11n (TensorRT) + ByteTrack on each,
and measures how long every frame takes. No window, no click-to-designate:
it tracks every person in view, which costs the same time as tracking one.
Evidence for PER-4 (perception rate).
"""
import time
import cv2
import numpy as np
from ultralytics import YOLO

N_FRAMES = 300      # how many frames to time (~10 s at 30 fps)
WARMUP = 10       # frames to skip at the start (first frames are slow; why?)

GST = ("nvarguscamerasrc sensor-id=0 ! "
       "video/x-raw(memory:NVMM),width=1920,height=1080,framerate=30/1 ! "
       "nvvidconv ! video/x-raw,width=1280,height=720,format=BGRx ! "
       "videoconvert ! video/x-raw,format=BGR ! "
       "appsink drop=true max-buffers=1")         

model = YOLO("yolo11n.engine", task="detect")
cap = cv2.VideoCapture(GST, cv2.CAP_GSTREAMER)
if not cap.isOpened():
    raise SystemExit("Camera did not open")

read_ms, track_ms, loop_ms = [], [], []
last_loop_start = None

for i in range(N_FRAMES + WARMUP):
    loop_start = time.perf_counter()     # precise stopwatch, made for timing code

    ok, frame = cap.read()
    t_read = time.perf_counter()
    if not ok:
        print("camera read failed")
        break

    results = model.track(frame, persist=True, classes=[0],
                          tracker="bytetrack.yaml", verbose=False)
    t_track = time.perf_counter()

    if i >= WARMUP:
        read_ms.append((t_read - loop_start) * 1000)
        track_ms.append((t_track - t_read) * 1000)                         # detection + tracking time, in ms
        if last_loop_start is not None:
            loop_ms.append((loop_start - last_loop_start) * 1000)                      # time since the PREVIOUS loop started, in ms
    last_loop_start = loop_start

cap.release()

def report(name, values):
    v = np.array(values)
    print(f"{name:12s} mean {v.mean():6.1f} ms   p95 {np.percentile(v, 95):6.1f} ms   max {v.max():6.1f} ms")

print(f"\n{len(loop_ms)} frames timed")
report("camera wait", read_ms)
report("track", track_ms)
report("loop period", loop_ms)
print(f"loop rate    {1000 / np.mean(loop_ms):.1f} Hz (PER-4 needs >= 10)")