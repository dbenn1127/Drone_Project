# udp_listen.py - print every message arriving on a UDP port (link test tool).
#   python udp_listen.py          -> port 5005 (perception messages)
#   python udp_listen.py 5602     -> port 5602 (designation commands)
import json, socket, sys

PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 5005
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.bind(("0.0.0.0", PORT))        # 0.0.0.0 = accept from any computer on the network
print(f"Listening on port {PORT} ... (Ctrl+C to stop)")
while True:
    data, addr = sock.recvfrom(65536)
    print(addr[0], json.loads(data))