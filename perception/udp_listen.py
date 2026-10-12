# udp_listen.py - print every message live_track.py sends (step 5 link test).
import json, socket

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.bind(("127.0.0.1", 5005))      # listen where live_track.py sends
print("Listening on port 5005 ... (Ctrl+C to stop)")
while True:
    data, addr = sock.recvfrom(1024)
    print(json.loads(data))