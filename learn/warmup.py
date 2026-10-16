import math
import time
import sys

# def range_bearing(dn, de):
#     """Return (range_m, bearing_deg) from north/east offsets in meters"""

#     range_m = math.hypot(dn, de)
#     bearing_deg = math.degrees(math.atan2(de, dn))
#     return range_m, bearing_deg

# print(range_bearing(3,4))




# start_time = time.time()
# while True: 
#     elapsed = time.time() - start_time
#     if elapsed > 3.0:
#         break
#     print(f"{elapsed:.2f} s")
#     time.sleep(0.1)

# try:
#     while True:
#         print("flying")
#         time.sleep(1/0)
# except KeyboardInterrupt:
#     print("landing:operator abort")
# except Exception as e:
#     print(f"landing:exception {e}")

# print(sys.argv)
# print(len(sys.argv))
# test_name = sys.argv[1] if len(sys.argv) > 1 else "straight"
# print(f"Test name: {test_name}")

# def target_straight(t):
#     return 10.0, 1.5*t

# def target_stationary(t):
#     return 10.0, 0.0

# target = target_straight
# print(target(5))
# target = target_stationary
# print(target(5))

# TEST = {"straight": target_straight, "stationary": target_stationary}
# test_name = sys.argv[1] if len(sys.argv) > 1 else "straight"
# if test_name not in TEST:
#     raise SystemExit(f"Unknown test case: {test_name}. Use one of {list(TEST.keys())}")
# target = TEST[test_name]
# print(f"Test case: {target.__name__}")

class Target:
    def __init__(self,speed):
        self.speed = speed

    def position(self,t):
        """Return (dn, de) target position at time t"""
        return 10.0, self.speed*t

slow = Target(1.5)
fast = Target(3.0)
print(slow.position(5))
print(fast.position(5))