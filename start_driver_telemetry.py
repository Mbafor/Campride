#!/usr/bin/env python3
"""
Start active driver telemetry on Phase6TestRoute
Continuously sends WebSocket telemetry pings to keep driver location active
"""

import json
import time
import threading
import socket
import ssl
from datetime import datetime

BASE_URL = "https://campride-production.up.railway.app/api/v1"
WS_HOST = "campride-production.up.railway.app"
WS_PORT = 443

DRIVER_EMAIL = "testdriver_full@test.com"
DRIVER_PASSWORD = "password123"
PHASE6_ROUTE_ID = "ae41a548-f5d2-4546-b664-f66fbb5b3a4c"

# Phase6TestRoute coordinates - simulate driving along the route
TELEMETRY_POINTS = [
    (5.6037, -0.187),  # Stop 1 - Start
    (5.6082, -0.187),  # Between Stop 1 and 2
    (5.6127, -0.187),  # Stop 2
    (5.6172, -0.187),  # Between Stop 2 and 3
    (5.6217, -0.187),  # Stop 3
]

def log(msg, level="INFO"):
    ts = datetime.now().strftime("%H:%M:%S.%f")[:-3]
    try:
        print(f"[{ts}] [{level}] {msg}", flush=True)
    except UnicodeEncodeError:
        # Handle Windows encoding issues
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
    """Perform WebSocket handshake and return socket"""
    context = ssl.create_default_context()
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    ssock = context.wrap_socket(sock, server_hostname=WS_HOST)

    try:
        ssock.connect((WS_HOST, 443))

        # WebSocket handshake
        handshake = f"GET /api/v1/ws/driver/telemetry?token={token} HTTP/1.1\r\n"
        handshake += f"Host: {WS_HOST}\r\n"
        handshake += "Upgrade: websocket\r\n"
        handshake += "Connection: Upgrade\r\n"
        handshake += "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r\n"
        handshake += "Sec-WebSocket-Version: 13\r\n"
        handshake += "\r\n"

        ssock.sendall(handshake.encode())

        # Read handshake response
        response = b""
        while b"\r\n\r\n" not in response:
            chunk = ssock.recv(4096)
            if not chunk:
                raise Exception("No handshake response")
            response += chunk

        if b"101" not in response:
            raise Exception(f"WebSocket handshake failed: {response.decode('utf-8', errors='ignore')[:200]}")

        return ssock
    except Exception as e:
        log(f"WebSocket handshake failed: {e}", "ERROR")
        raise

def ws_send_message(ws, data):
    """Send WebSocket text frame (simplified - assumes small messages)"""
    msg = json.dumps(data).encode('utf-8')

    # Simple WebSocket frame: FIN=1, opcode=1 (text)
    frame = bytearray()
    frame.append(0x81)  # FIN + opcode 1 (text)

    if len(msg) < 126:
        frame.append(0x80 | len(msg))  # MASK + length
    else:
        frame.append(0xFE)  # MASK + 126
        frame.extend(len(msg).to_bytes(2, 'big'))

    # Masking key (for client-to-server, must be masked)
    mask = b'\x00\x00\x00\x00'
    frame.extend(mask)

    # Masked payload
    masked_payload = bytes(b ^ m for b, m in zip(msg, mask * (len(msg) // 4 + 1)))
    frame.extend(masked_payload[:len(msg)])

    ws.sendall(bytes(frame))

def main():
    log("=" * 60)
    log("DRIVER TELEMETRY: Phase6TestRoute")
    log("=" * 60)

    # Step 1: Login
    log("Step 1: Logging in as testdriver_full@test.com")
    response = http_post("/api/v1/auth/login", {
        "email": DRIVER_EMAIL,
        "password": DRIVER_PASSWORD
    })

    try:
        body = response.split('\r\n\r\n')[1]
        data = json.loads(body)
        driver_jwt = data['access_token']
        log(f"[OK] Login successful: {driver_jwt[:50]}...", "SUCCESS")
    except Exception as e:
        log(f"[FAIL] Login failed: {e}", "ERROR")
        return False

    time.sleep(1)

    # Step 2: Assign route
    log("Step 2: Assigning Phase6TestRoute")
    response = http_post("/api/v1/driver/route", {
        "route_id": PHASE6_ROUTE_ID
    })

    if "Route updated" in response or "Phase6TestRoute" in response:
        log("[OK] Route assigned", "SUCCESS")
    else:
        log(f"[WARN] Route assignment response: {response[:100]}", "WARN")

    time.sleep(1)

    # Step 3: Connect WebSocket
    log("Step 3: Connecting WebSocket telemetry")
    try:
        ws = websocket_handshake(driver_jwt)
        log("[OK] WebSocket connected!", "SUCCESS")
    except Exception as e:
        log(f"[FAIL] WebSocket connection failed: {e}", "ERROR")
        return False

    # Step 4: Send telemetry in loop
    log("Step 4: Sending telemetry pings every 2 seconds")
    log("This keeps driver active in Redis for matching")
    log("")

    try:
        ping_count = 0
        point_index = 0

        while True:
            lat, lng = TELEMETRY_POINTS[point_index % len(TELEMETRY_POINTS)]

            msg = {
                "lat": lat,
                "lng": lng,
                "heading": 90.0,
                "accuracy": 5.0,
                "timestamp": datetime.utcnow().isoformat() + "Z"
            }

            ws_send_message(ws, msg)
            ping_count += 1
            point_index += 1

            log(f"Ping #{ping_count}: ({lat}, {lng})", "DEBUG")

            # Keep sending every 2 seconds (well under 2-minute stale threshold)
            time.sleep(2)

    except KeyboardInterrupt:
        log("", "INFO")
        log("Telemetry stopped by user", "WARN")
        log(f"Total pings sent: {ping_count}", "INFO")
    except Exception as e:
        log(f"[FAIL] Telemetry error: {e}", "ERROR")
    finally:
        try:
            ws.close()
        except:
            pass

    log("Driver telemetry ended", "INFO")
    return True

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        log(f"[FATAL] Fatal error: {e}", "FATAL")
