"""
video_view.py - Ground station video window (step 5, video piece 1).
Shows the Jetson's camera. Later: boxes, click-to-designate, HUD.
Press q in the window to quit.
"""
import socket
import time
import cv2
import numpy as np

LISTEN = ("0.0.0.0", 5600)   # 0.0.0.0 = accept packets from any computer on the network

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.bind(LISTEN)
sock.setblocking(False)      # never wait; the window must stay responsive

def newest_packet():
    """Read every waiting packet; return only the newest (or None if none waiting)."""
    newest = None
    while True:
        try:
            data, addr = sock.recvfrom(65536)   # up to 64 KB: big enough for one JPEG frame
            newest = data                       # keep the raw JPEG bytes; the main loop decodes them
        except BlockingIOError:
            break                               # nothing left waiting
    return newest

fps, last = 0.0, time.perf_counter()
print("Waiting for video on port 5600 ... (q in the window to quit)")
while True:
    data = newest_packet()
    if data is None:
        time.sleep(0.005)                  # nothing new; don't spin the CPU
        if cv2.waitKey(1) & 0xFF == ord("q"):
            break
        continue

    frame = cv2.imdecode(np.frombuffer(data, np.uint8), cv2.IMREAD_COLOR)
    if frame is None:                      # damaged packet; skip it
        continue

    now = time.perf_counter()
    fps = 0.9 * fps + 0.1 / (now - last)   # smoothed, like live_track.py
    last = now
    cv2.putText(frame, f"{fps:4.1f} FPS", (10, 25),
                cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255, 255, 255), 2)
    cv2.imshow("Ground view", frame)
    if cv2.waitKey(1) & 0xFF == ord("q"):
        break

cv2.destroyAllWindows()