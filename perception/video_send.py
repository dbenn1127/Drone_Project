"""
video_send.py - Stream the Jetson camera to the ground station (step 5, video piece 1).
Each frame: shrink to 640x360, compress to JPEG, send as ONE UDP packet.
(Orin Nano has no hardware video encoder, so JPEG on the CPU is the simple desk option.)
"""
import socket
import time
import cv2

GROUND_ADDR = ("192.168.4.153", 5600)   # the PC's IPv4 address (ipconfig), video port
SEND_W, SEND_H = 640, 360             # smaller frame = smaller packet, faster to send
JPEG_QUALITY = 70                     # 0-100: lower = smaller packet, blurrier picture
MAX_UDP = 65000                       # one UDP packet can't carry more than ~65 KB

GST = ("nvarguscamerasrc sensor-id=0 ! "
       "video/x-raw(memory:NVMM),width=1920,height=1080,framerate=30/1 ! "
       "nvvidconv flip-method=2 ! video/x-raw,width=1280,height=720,format=BGRx ! "
       "videoconvert ! video/x-raw,format=BGR ! "
       "appsink drop=true max-buffers=1")

cap = cv2.VideoCapture(GST, cv2.CAP_GSTREAMER)
if not cap.isOpened():
    raise SystemExit("Camera did not open")
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
print(f"Streaming to {GROUND_ADDR} ... Ctrl+C to stop")

sent, total_bytes, t0 = 0, 0, time.time()
try:
    while True:
        ok, frame = cap.read()
        if not ok:
            print("camera read failed")
            break
        small = cv2.resize(frame, (SEND_W, SEND_H))
        ok, jpg = cv2.imencode(".jpg", small, [cv2.IMWRITE_JPEG_QUALITY, JPEG_QUALITY])
        data = jpg.tobytes()
        if len(data) > MAX_UDP:
            print(f"frame too big ({len(data)} bytes), skipped")
            continue
        sock.sendto(data, GROUND_ADDR)

        # Every 2 s: frames per second, size per frame, and network load.
        sent += 1
        total_bytes += len(data)
        dt = time.time() - t0
        if dt >= 2.0:
            print(f"{sent / dt:5.1f} fps   {total_bytes / sent / 1000:5.1f} KB/frame   "
                  f"{total_bytes * 8 / dt / 1e6:4.1f} Mbit/s")
            sent, total_bytes, t0 = 0, 0, time.time()
finally:
    cap.release()