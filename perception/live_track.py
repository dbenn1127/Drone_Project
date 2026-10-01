import cv2
from ultralytics import YOLO
import math

model = YOLO("yolo11n.pt")
cap = cv2.VideoCapture(0)   # Iriun camera; try 1 or 2 if 0 is wrong
target_id = None
lost_frames = 0

width = cap.get(cv2.CAP_PROP_FRAME_WIDTH)   # frame width in pixels, e.g. 1280
hfov_deg = 65                                # iPhone camera's horizontal field of view (estimate)

cx = width / 2
fx = (width / 2) / math.tan(math.radians(hfov_deg / 2))

print("width:", width, "cx:", cx, "fx:", fx)

while True:
    ok, frame = cap.read()
    if not ok:
        break

    results = model.track(frame, persist=True, tracker="bytetrack.yaml",
                          classes=[0], verbose=False)
    boxes = results[0].boxes
    found = False
    cv2.line(frame, (int(cx), 0), (int(cx), frame.shape[0]), (255, 255, 255), 1)
    # Lock onto the largest person if we don't have a target
    if target_id is None and boxes.id is not None:
        areas = [(x2 - x1) * (y2 - y1) for x1, y1, x2, y2 in boxes.xyxy.tolist()]
        target_id = boxes.id.int().tolist()[areas.index(max(areas))]

    # Draw every person; target is green
    if boxes.id is not None:
        for (x1, y1, x2, y2), tid in zip(boxes.xyxy.tolist(), boxes.id.int().tolist()):
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

    # Count frames the target has been missing; relock after ~1 second
    if found:
        lost_frames = 0
    else:
        lost_frames += 1
        if target_id is not None:
            cv2.putText(frame, "Target lost", (30, 40),
                        cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 0, 255), 2)
        if lost_frames > 30:
            target_id = None
            lost_frames = 0

    cv2.imshow("Follow-me perception", frame)
    key = cv2.waitKey(1) & 0xFF
    if key == ord("q"):
        break
    if key == ord("r"):
        target_id = None

cap.release()
cv2.destroyAllWindows()