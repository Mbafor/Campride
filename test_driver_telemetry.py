#!/usr/bin/env python3
"""
Test driver telemetry for Phase6TestRoute
This script:
1. Logs in as testdriver_full@test.com
2. Assigns Phase6TestRoute
3. Connects WebSocket and sends telemetry
"""

import json
import time
import socket
import ssl
import base64
from datetime import datetime

BASE_URL = "https://campride-production.up.railway.app/api/v1"
WS_URL = "wss://campride-production.up.railway.app/api/v1/ws/driver/telemetry"
DRIVER_EMAIL = "testdriver_full@test.com"
DRIVER_PASSWORD = "password123"
PHASE6_ROUTE_ID = "ae41a548-f5d2-4546-b664-f66fbb5b3a4c"

# Phase6TestRoute stop coordinates
STOP_1_LAT = 5.6037
STOP_1_LNG = -0.187

def log(msg: str, level: str = "INFO"):
    """Log with timestamp"""
    timestamp = datetime.now().strftime("%H:%M:%S.%f")[:-3]
    print(f"[{timestamp}] [{level}] {msg}")

def section(title: str):
    """Print section header"""
    print(f"\n{'='*60}")
    print(f"  {title}")
    print(f"{'='*60}\n")

def http_request(method: str, path: str, token: str = None, body: dict = None) -> tuple:
    """Make HTTP request using socket (no requests library)"""
    host = "campride-production.up.railway.app"

    # Create SSL socket
    context = ssl.create_default_context()
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    ssock = context.wrap_socket(sock, server_hostname=host)

    try:
        ssock.connect((host, 443))

        # Build request
        headers = f"{method} {path} HTTP/1.1\r\n"
        headers += f"Host: {host}\r\n"
        headers += "Connection: close\r\n"

        if token:
            headers += f"Authorization: Bearer {token}\r\n"

        if body:
            body_str = json.dumps(body)
            headers += f"Content-Length: {len(body_str)}\r\n"
            headers += "Content-Type: application/json\r\n"
            headers += "\r\n"
            headers += body_str
        else:
            headers += "\r\n"

        ssock.sendall(headers.encode())

        # Read response
        response = b""
        while True:
            chunk = ssock.recv(4096)
            if not chunk:
                break
            response += chunk

        # Parse response
        response_str = response.decode('utf-8', errors='ignore')
        parts = response_str.split('\r\n\r\n', 1)
        status_line = parts[0].split('\r\n')[0]
        body = parts[1] if len(parts) > 1 else ""

        return status_line, body

    finally:
        ssock.close()

def main():
    section("Step 1: Driver Login")

    log(f"Logging in as {DRIVER_EMAIL}...")
    status, body = http_request("POST", "/api/v1/auth/login", body={
        "email": DRIVER_EMAIL,
        "password": DRIVER_PASSWORD
    })

    log(f"Status: {status}")

    try:
        response = json.loads(body)
        driver_jwt = response.get('access_token')
        if not driver_jwt:
            log(f"❌ Failed to get JWT: {body[:200]}", "ERROR")
            return False
        log(f"✅ Login successful! JWT: {driver_jwt[:50]}...", "SUCCESS")
    except:
        log(f"❌ Failed to parse login response: {body[:200]}", "ERROR")
        return False

    time.sleep(1)

    section("Step 2: Assign Route")

    log(f"Assigning Phase6TestRoute to driver...")
    status, body = http_request("PUT", "/api/v1/driver/route", token=driver_jwt, body={
        "route_id": PHASE6_ROUTE_ID
    })

    log(f"Status: {status}")
    log(f"Response: {body[:200]}")

    if "200" in status:
        log(f"✅ Route assigned successfully!", "SUCCESS")
    else:
        log(f"⚠️  Route assignment returned: {status}", "WARN")

    time.sleep(1)

    section("Step 3: Get Current Route")

    log("Verifying assigned route...")
    status, body = http_request("GET", "/api/v1/driver/route", token=driver_jwt)

    log(f"Status: {status}")
    try:
        route = json.loads(body)
        route_name = route.get('name', 'Unknown')
        log(f"✅ Current route: {route_name}", "SUCCESS")
    except:
        log(f"Response: {body[:200]}")

    time.sleep(2)

    section("Step 4: Connect WebSocket Telemetry")

    log(f"Starting WebSocket connection to telemetry endpoint...")
    log(f"URL: {WS_URL}?token={driver_jwt[:30]}...")

    try:
        import websocket

        def on_message(ws, message):
            log(f"WebSocket message: {message}", "DEBUG")

        def on_error(ws, error):
            log(f"WebSocket error: {error}", "ERROR")

        def on_close(ws, close_status_code, close_msg):
            log(f"WebSocket closed", "WARN")

        def on_open(ws):
            log(f"✅ WebSocket connected!", "SUCCESS")

            # Send telemetry
            for i in range(5):
                lat = STOP_1_LAT + (i * 0.001)  # Move slightly along route
                lng = STOP_1_LNG

                msg = json.dumps({
                    "lat": lat,
                    "lng": lng,
                    "heading": 90.0,
                    "accuracy": 5.0
                })

                ws.send(msg)
                log(f"Sent telemetry {i+1}: ({lat}, {lng})", "DEBUG")
                time.sleep(1)

            ws.close()

        ws = websocket.WebSocketApp(
            f"{WS_URL}?token={driver_jwt}",
            on_open=on_open,
            on_message=on_message,
            on_error=on_error,
            on_close=on_close
        )

        ws.run_forever(sslopt={"cert_reqs": ssl.CERT_NONE})

    except ImportError:
        log("WebSocket library not available, using manual socket approach...", "WARN")
        log("⚠️  Cannot send WebSocket without websocket-client library", "WARN")
        return None
    except Exception as e:
        log(f"WebSocket error: {e}", "ERROR")
        return None

    log("✅ Telemetry test complete", "SUCCESS")
    return True

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        log("Test interrupted", "WARN")
    except Exception as e:
        log(f"Fatal error: {e}", "FATAL")
