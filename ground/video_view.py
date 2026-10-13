"""
video_view.py - Ground station video window (step 5, video piece 1).
Shows the Jetson's camera. Later: boxes, click-to-designate, HUD.
Press q in the window to quit.
"""
import socket
import time
import cv2
import numpy as np
import json

LISTEN = ("0.0.0.0", 5600)   # 0.0.0.0 = accept packets from any computer on the network
JETSON_IP = "192.168.4.26"    # ← NEW: the Jetson's address (hostname -I on the Jetson)
DESIGNATE_PORT = 5602        # ← NEW: where designation commands go
seq = 0                      # ← NEW: request counter; each click gets the next number

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.bind(LISTEN)
sock.setblocking(False)      # never wait; the window must stay responsive

# Second socket for the box list (port 5601). Separate port = separate "mailbox".
box_sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
box_sock.bind(("0.0.0.0", 5601))
box_sock.setblocking(False)     # newest box list from the Jetson (a dict), or None
latest_boxes = None

def newest_packet(s):
    """Read every waiting packet; return only the newest (or None if none waiting)."""
    newest = None
    while True:
        try:
            data, addr = s.recvfrom(65536)   # up to 64 KB: big enough for one JPEG frame
            newest = data                       # keep the raw JPEG bytes; the main loop decodes them
        except BlockingIOError:
            break                               # nothing left waiting
    return newest

def on_click(event, x, y, flags, param):
    """OpenCV calls this for every mouse event in the window. Left click = pick a person."""
    global seq                                   # we CHANGE seq, so it needs global
    if event != cv2.EVENT_LBUTTONDOWN:
        return
    if not latest_boxes:
        print("no box list yet")
        return
    for tid, x1, y1, x2, y2 in latest_boxes["boxes"]:
        if x1 <= x <= x2 and y1 <= y <= y2:
            # build the command, number it, send it to the Jetson
            seq += 1
            cmd = {"seq": seq, "designate": tid}
            sock.sendto(json.dumps(cmd).encode(), (JETSON_IP, DESIGNATE_PORT))
            print(f"sent: designate ID {tid} (request #{seq})")
            return
    print("no box there")

fps, last = 0.0, time.perf_counter()
print("Waiting for video on port 5600 ... (q in the window to quit)")

cv2.namedWindow("Ground view")                   # create the window now, before any video
cv2.setMouseCallback("Ground view", on_click)    # send its mouse events to on_click

while True:
    box_data = newest_packet(box_sock)
    if box_data is not None:
        latest_boxes = json.loads(box_data)

    data = newest_packet(sock)
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