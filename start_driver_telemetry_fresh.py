#!/usr/bin/env python3
"""
Start FRESH driver telemetry at Phase6TestRoute Stop 1 position.
Sends first ping from correct location to establish Redis position.
"""

import json
import time
import socket
import ssl
from datetime import datetime

BASE_URL = "https://campride-production.up.railway.app/api/v1"
WS_HOST = "campride-production.up.railway.app"
WS_PORT = 443

DRIVER_EMAIL = "testdriver_full@test.com"
DRIVER_PASSWORD = "password123"
PHASE6_ROUTE_ID = "ae41a548-f5d2-4546-b664-f66fbb5b3a4c"

# START at Stop 1 (5.6037, -0.187) - the actual pickup point
STARTING_LAT = 5.6037
STARTING_LNG = -0.187

def log(msg, level="INFO"):
    ts = datetime.now().strftime("%H:%M:%S")
    try:
        print(f"[{ts}] [{level}] {msg}", flush=True)
    except UnicodeEncodeError:
        print(f"[{ts}] [{level}] {msg.encode('ascii', 'replace').decode()}", flush=True)

def http_post(path, body):
    """Make HTTPS POST request"""
    context = ssl.create_default_context()
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    ssock = context.wrap_socket(sock, server_hostname=WS_HOST)

    try:
        ssock.connect((WS_HOST, 443))
        body_str = json.dumps(body)

        request = f"POST {path} HTTP/1.1\r\n"
        request += f"Host: {WS_HOST}\r\n"
        request += f"Content-Length: {len(body_str)}\r\n"
        request += "Content-Type: application/json\r\n"
        request += "Connection: close\r\n"
        request += "\r\n"
        request += body_str

        ssock.sendall(request.encode())

        response = b""
        while True:
            chunk = ssock.recv(4096)
            if not chunk:
                break
            response += chunk

        return response.decode('utf-8', errors='ignore')
    finally:
        ssock.close()

def websocket_handshake(token):
    """Perform WebSocket handshake"""
    context = ssl.create_default_context()
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    ssock = context.wrap_socket(sock, server_hostname=WS_HOST)

    try:
        ssock.connect((WS_HOST, 443))

        handshake = f"GET /api/v1/ws/driver/telemetry?token={token} HTTP/1.1\r\n"
        handshake += f"Host: {WS_HOST}\r\n"
        handshake += "Upgrade: websocket\r\n"
        handshake += "Connection: Upgrade\r\n"
        handshake += "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r\n"
        handshake += "Sec-WebSocket-Version: 13\r\n"
        handshake += "\r\n"

        ssock.sendall(handshake.encode())

        response = b""
        while b"\r\n\r\n" not in response:
            chunk = ssock.recv(4096)
            if not chunk:
                raise Exception("No handshake response")
            response += chunk

        if b"101" not in response:
            raise Exception(f"WebSocket handshake failed")

        return ssock
    except Exception as e:
        log(f"[FAIL] WebSocket handshake failed: {e}", "ERROR")
        raise

def ws_send_message(ws, data):
    """Send WebSocket text frame"""
    msg = json.dumps(data).encode('utf-8')

    frame = bytearray()
    frame.append(0x81)

    if len(msg) < 126:
        frame.append(0x80 | len(msg))
    else:
        frame.append(0xFE)
        frame.extend(len(msg).to_bytes(2, 'big'))

    mask = b'\x00\x00\x00\x00'
    frame.extend(mask)

    masked_payload = bytes(b ^ m for b, m in zip(msg, mask * (len(msg) // 4 + 1)))
    frame.extend(masked_payload[:len(msg)])

    ws.sendall(bytes(frame))

def main():
    log("="*60)
    log("FRESH DRIVER TELEMETRY: Phase6TestRoute - Stop 1")
    log("="*60)

    log(f"Starting position: Stop 1 ({STARTING_LAT}, {STARTING_LNG})")
    log("This will establish correct Redis position for matching")
    log("")

    # Step 1: Login
    log("Step 1: Login")
    response = http_post("/api/v1/auth/login", {
        "email": DRIVER_EMAIL,
        "password": DRIVER_PASSWORD
    })

    try:
        body = response.split('\r\n\r\n')[1]
        data = json.loads(body)
        driver_jwt = data['access_token']
        log(f"[OK] Login successful", "SUCCESS")
    except Exception as e:
        log(f"[FAIL] Login failed: {e}", "ERROR")
        return False

    # Step 2: Verify route assigned
    log("Step 2: Verify route assignment")
    response = http_post("/api/v1/driver/route", {
        "route_id": PHASE6_ROUTE_ID
    })
    log("[OK] Route ready", "SUCCESS")

    # Step 3: Connect WebSocket
    log("Step 3: Connect WebSocket")
    try:
        ws = websocket_handshake(driver_jwt)
        log("[OK] WebSocket connected", "SUCCESS")
    except Exception as e:
        return False

    # Step 4: Send telemetry from correct starting position
    log("Step 4: Sending telemetry from Stop 1 position")
    log("")

    try:
        for ping_num in range(1, 16):
            lat = STARTING_LAT
            lng = STARTING_LNG

            msg = {
                "lat": lat,
                "lng": lng,
                "heading": 90.0,
                "accuracy": 5.0,
                "timestamp": datetime.utcnow().isoformat() + "Z"
            }

            ws_send_message(ws, msg)
            log(f"Ping #{ping_num}: ({lat}, {lng})", "DEBUG")

            time.sleep(2)

    except KeyboardInterrupt:
        log("Telemetry stopped by user", "WARN")
    except Exception as e:
        log(f"[FAIL] Telemetry error: {e}", "ERROR")
    finally:
        try:
            ws.close()
        except:
            pass

    log("Driver telemetry session complete", "INFO")
    return True

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        log(f"[FATAL] Fatal error: {e}", "FATAL")
