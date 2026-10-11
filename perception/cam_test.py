import time
import cv2

# Camera pipeline (same as the test pictures, but feeding Python instead of JPEG files):
#   sensor at 1920x1080 30 fps -> hardware resize to 1280x720 -> BGR for OpenCV.
#   drop=true max-buffers=1: always hand Python the NEWEST frame, never a queue of old ones.
GST = ("nvarguscamerasrc sensor-id=0 ! "
       "video/x-raw(memory:NVMM),width=1920,height=1080,framerate=30/1 ! "
       "nvvidconv ! video/x-raw,width=1280,height=720,format=BGRx ! "
       "videoconvert ! video/x-raw,format=BGR ! "
       "appsink drop=true max-buffers=1")

cap = cv2.VideoCapture(GST, cv2.CAP_GSTREAMER)
print("opened:", cap.isOpened())

t0 = time.time()
for i in range(60):
    ok, frame = cap.read()
    if not ok:
        print("read failed at frame", i)
        break
print(f"60 frames in {time.time() - t0:.2f} s, shape {frame.shape}")
cv2.imwrite("cam_test.jpg", frame)
cap.release()