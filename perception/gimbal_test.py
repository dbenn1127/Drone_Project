"""
gimbal_test.py - Step 1 of gimbal control: read the SIYI A8 mini's angles.
Asks the gimbal "where are you pointing?" 5x per second and prints the answer.
Run on the Jetson (camera on 192.168.144.25). Ctrl+C to stop.
"""
import binascii
import socket
import struct
import time

GIMBAL = ("192.168.144.25", 37260)   # SIYI SDK address (UDP)
CMD_ATTITUDE = 0x0D                  # "acquire gimbal attitude"


def packet(cmd_id, data=b""):
    """Build one SIYI SDK message: header + data + checksum (all little-endian)."""
    head = struct.pack("<BBBHHB",
                       0x55, 0x66,      # STX: every message starts with these 2 bytes
                       0x01,            # CTRL: 1 = please reply
                       len(data),       # data length (2 bytes)
                       0,               # SEQ: message counter (not needed here)
                       cmd_id)          # which command
    body = head + data
    crc = binascii.crc_hqx(body, 0)     # CRC16 checksum so the gimbal can spot corruption
    return body + struct.pack("<H", crc)


sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.settimeout(1.0)                    # wait at most 1 s for a reply

while True:
    sock.sendto(packet(CMD_ATTITUDE), GIMBAL)
    try:
        reply, addr = sock.recvfrom(1024)
    except socket.timeout:
        print("no reply")
        continue

    # Reply = 8-byte header, then 6 numbers (2 bytes each, tenths of a degree), then CRC.
    if reply[7] == CMD_ATTITUDE and len(reply) >= 8 + 12:
        yaw, pitch, roll, yaw_v, pitch_v, roll_v = struct.unpack("<hhhhhh", reply[8:20])
        print(f"yaw {yaw / 10:+7.1f}   pitch {pitch / 10:+7.1f}   roll {roll / 10:+7.1f}  deg")
    time.sleep(0.2)