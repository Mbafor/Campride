#!/usr/bin/env python3
"""Exercise the profile-update API against a deployed Campride backend.

Usage:
    python test_profile_update.py

Optionally override the target or test credentials without editing this file:
    CAMPRIDE_BASE_URL=https://example.com/api/v1 \
    CAMPRIDE_TEST_EMAIL=student@test.com \
    CAMPRIDE_TEST_PASSWORD=password123 python test_profile_update.py
"""
import json
import os
import sys
import urllib.request
import urllib.error

BASE_URL = os.getenv("CAMPRIDE_BASE_URL", "https://campride-production.up.railway.app/api/v1").rstrip("/")
TEST_EMAIL = os.getenv("CAMPRIDE_TEST_EMAIL", "student@test.com")
TEST_PASSWORD = os.getenv("CAMPRIDE_TEST_PASSWORD", "password123")


def call(method, path, token=None, body=None):
    url = BASE_URL + path
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=20) as resp:
            return resp.status, resp.read().decode()
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode()
    except urllib.error.URLError as e:
        return None, f"Network error: {e.reason}"


def response_json(text):
    """Return decoded JSON, or a readable marker for a non-JSON response."""
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        return {"raw_response": text}


def print_result(step, status, text, expected_status=200):
    passed = status == expected_status
    marker = "PASS" if passed else "FAIL"
    print(f"[{step}] {marker}: status={status} (expected {expected_status})")
    print(json.dumps(response_json(text), indent=2)[:800])
    return passed


def main():
    failures = []

    # 1) Login as the known verified test student.
    status, text = call("POST", "/auth/login", body={
        "email": TEST_EMAIL,
        "password": TEST_PASSWORD,
    })
    if not print_result("1 login", status, text):
        print("\nProfile checks were not run because login failed.")
        print("Confirm that the deployed backend has a verified test account and inspect its server logs for the login 500.")
        return 1

    token = response_json(text).get("access_token")
    if not token:
        print("\nLogin response did not contain access_token.")
        return 1

    # 2) GET /users/me to see current user
    status, text = call("GET", "/users/me", token=token)
    if not print_result("2 get initial profile", status, text):
        failures.append("GET /users/me")

    # 3-5) Update each field separately, matching how the mobile app saves edits.
    # Values are safe to run repeatedly against the dedicated test account.
    status, text = call("PUT", "/users/me", token=token, body={"phone_number": "+233240000001"})
    if not print_result("3 update phone", status, text):
        failures.append("PUT phone_number")

    status, text = call("PUT", "/users/me", token=token, body={"name": "Test Student"})
    if not print_result("4 update name", status, text):
        failures.append("PUT name")

    # Keeping the existing email avoids changing the test account's login identity.
    status, text = call("PUT", "/users/me", token=token, body={"email": TEST_EMAIL})
    if not print_result("5 retain email", status, text):
        failures.append("PUT email")

    # 6) Confirm all expected values persisted.
    status, text = call("GET", "/users/me", token=token)
    profile = response_json(text)
    expected = {
        "name": "Test Student",
        "email": TEST_EMAIL,
        "phone_number": "+233240000001",
    }
    persisted = status == 200 and all(profile.get(key) == value for key, value in expected.items())
    print_result("6 verify persisted profile", status, text)
    if not persisted:
        failures.append("profile persistence")

    if failures:
        print("\nFAILED: " + ", ".join(failures))
        return 1

    print("\nPASSED: profile update flow completed successfully.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
