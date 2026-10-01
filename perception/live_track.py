import cv2
from ultralytics import YOLO
import math
import time

model = YOLO("yolo11n.pt")
cap = cv2.VideoCapture(0)   # Iriun camera; try 1 or 2 if 0 is wrong
target_id = None
lost_since = None
last_boxes=[]

width = cap.get(cv2.CAP_PROP_FRAME_WIDTH)   # frame width in pixels, e.g. 1280
hfov_deg = 65                                # iPhone camera's horizontal field of view (estimate)
LOST_TIMEOUT_S = 2.0 #SAAF-3 [TBR]

cx = width / 2
fx = (width / 2) / math.tan(math.radians(hfov_deg / 2))

print("width:", width, "cx:", cx, "fx:", fx)

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


while True:
    ok, frame = cap.read()
    if not ok:
        break

    results = model.track(frame, persist=True, tracker="bytetrack.yaml",
                          classes=[0], verbose=False)
    boxes = results[0].boxes
    found = False
    last_boxes.clear()

    cv2.line(frame, (int(cx), 0), (int(cx), frame.shape[0]), (255, 255, 255), 1)
   
    # Draw every person; target is green
    if boxes.id is not None:
        for (x1, y1, x2, y2), tid in zip(boxes.xyxy.tolist(), boxes.id.int().tolist()):
            last_boxes.append((x1, y1, x2, y2, tid))
            if tid == target_id:
                u= (x1+x2)/2
                bearing = math.degrees(math.atan((u-cx)/fx))
                cv2.putText(frame, f"Bearing: {bearing:.1f} deg", (30, 80),
                    cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 0), 2)
                found = True
            color = (0, 255, 0) if tid == target_id else (128, 128, 128)
            cv2.rectangle(frame, (int(x1), int(y1)), (int(x2), int(y2)), color, 2)
            cv2.putText(frame, f"ID {tid}", (int(x1), int(y1) - 8),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.8, color, 2)

    # Target-loss handling: never drops the target on its own (PER-3, SAF-3)
    if found:
        lost_since = None
    elif target_id is not None:
        if lost_since is None:
            lost_since = time.time()
        lost_for = time.time() - lost_since
        if lost_for < LOST_TIMEOUT_S:
            cv2.putText(frame, f"LOST {lost_for:.1f} s", (30, 40),
                                    cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 0, 255), 2)
        else:
            cv2.putText(frame, "Hover - click to redesignate", (30, 40), 
                        cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 0, 255), 2)

    cv2.imshow("Follow-me perception", frame)
    key = cv2.waitKey(1) & 0xFF
    if key == ord("q"):
        break
    if key == ord("r"):
        target_id = None

cap.release()
cv2.destroyAllWindows()