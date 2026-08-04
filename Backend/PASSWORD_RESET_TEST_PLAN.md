# Password Reset Feature - Test Plan

## Implementation Summary

### Section 1: Database Changes ✓
- Added `purpose` column to `verification_codes` table (VARCHAR, default='email_verification')
- Created Alembic migration: `607caec66086_add_purpose_to_verification_codes.py`
- Updated email verification code to explicitly set `purpose='email_verification'`
- Updated verification query to filter by `purpose='email_verification'`
- Updated resend-verification to only delete email verification codes

### Section 2: API Endpoints ✓
- **POST /auth/forgot-password**
  - Body: `{email: string}`
  - Returns generic success message regardless of email existence (security)
  - Generates 6-digit code, saves with `purpose='password_reset'`, expires in 10 min
  - Sends code via Resend email

- **POST /auth/reset-password**
  - Body: `{email: string, code: string, new_password: string}`
  - Validates code with `purpose='password_reset'`
  - Updates password (hashed), deletes used code
  - Returns success or AUTH_006 error

### Email Function ✓
- Added `send_password_reset_email(email, code)` to `app/core/email.py`

---

## Test Cases

### Test 1: Existing Email Verification Still Works
**Setup:** Register a new test account
1. Call POST /auth/register with valid student data
2. User should receive email with verification code
3. Call POST /auth/verify-email with that code
4. User should be marked as verified
5. Should be able to login

**Expected Result:** ✓ Email verification works as before
**Actual Result:** [To be tested with running database]

---

### Test 2: Forgot Password for Real Email
**Setup:** Use an existing test account (e.g., testuser@example.com)
1. Call POST /auth/forgot-password with that email
2. Check the inbox for an email from noreply@cosssached.org
3. Extract the 6-digit code from the email

**Expected Result:**
```json
{
  "message": "If an account exists with this email, a password reset code has been sent. Check your inbox.",
  "email": "testuser@example.com"
}
```
- Status: 200
- Email received with subject "CampRide Password Reset Request"
- Code in email format: "XXXXXX" (6 digits)

**Actual Result:** [To be tested]

**Real Evidence Needed:**
- Screenshot of response from /forgot-password
- Screenshot of email inbox showing reset code email
- The actual 6-digit code received

---

### Test 3: Forgot Password for Non-Existent Email (Security Check)
**Setup:** Non-existent email address
1. Call POST /auth/forgot-password with email that does NOT exist (e.g., nonexistent@example.com)

**Expected Result:**
```json
{
  "message": "If an account exists with this email, a password reset code has been sent. Check your inbox.",
  "email": "nonexistent@example.com"
}
```
- Status: 200 (SAME as real email case)
- No email sent
- Response is IDENTICAL to real email case (never reveals whether email exists)

**Actual Result:** [To be tested]

**Real Evidence Needed:**
- Screenshot showing response is identical to Test 2
- Confirmation that NO email was sent to nonexistent address

---

### Test 4: Reset Password with Valid Code
**Setup:** Have a valid code from Test 2
1. Call POST /auth/reset-password with:
   ```json
   {
     "email": "testuser@example.com",
     "code": "XXXXXX",
     "new_password": "NewPassword123"
   }
   ```

**Expected Result:**
```json
{
  "message": "Password reset successfully. You can now log in with your new password.",
  "email": "testuser@example.com"
}
```
- Status: 200

**Actual Result:** [To be tested]

**Real Evidence Needed:**
- Screenshot of reset-password response

---

### Test 5: Login with New Password
**Setup:** Just reset password in Test 4
1. Call POST /auth/login with:
   ```json
   {
     "email": "testuser@example.com",
     "password": "NewPassword123"
   }
   ```

**Expected Result:**
```json
{
  "access_token": "...",
  "refresh_token": "...",
  "token_type": "bearer"
}
```
- Status: 200
- Access token is valid JWT

**Actual Result:** [To be tested]

**Real Evidence Needed:**
- Screenshot of login response with tokens

---

### Test 6: Old Password No Longer Works
**Setup:** Account from Test 5 with new password
1. Try to login with the OLD password (before reset)
2. Use original password that was set during registration or previous reset

**Expected Result:**
```json
{
  "error_code": "AUTH_001",
  "message": "Invalid credentials"
}
```
- Status: 401

**Actual Result:** [To be tested]

**Real Evidence Needed:**
- Screenshot showing login failure with old password

---

### Test 7: Code Cannot Be Reused
**Setup:** Already used the code from Test 2 in Test 4
1. Call POST /auth/reset-password again with the SAME code and a different new password:
   ```json
   {
     "email": "testuser@example.com",
     "code": "XXXXXX",
     "new_password": "AnotherPassword456"
   }
   ```

**Expected Result:**
```json
{
  "error_code": "AUTH_006",
  "message": "Invalid or expired password reset code"
}
```
- Status: 400
- Clear error message indicating code is no longer valid

**Actual Result:** [To be tested]

**Real Evidence Needed:**
- Screenshot showing reset-password fails with "Invalid or expired password reset code"

---

### Test 8: Invalid/Made-Up Code Rejected
**Setup:** Any valid email
1. Call POST /auth/reset-password with a made-up code:
   ```json
   {
     "email": "testuser@example.com",
     "code": "999999",
     "new_password": "SomePassword789"
   }
   ```

**Expected Result:**
```json
{
  "error_code": "AUTH_006",
  "message": "Invalid or expired password reset code"
}
```
- Status: 400

**Actual Result:** [To be tested]

**Real Evidence Needed:**
- Screenshot showing clear error message

---

## Security Validations

- [ ] **No Email Enumeration:** Forgot-password returns identical response for existing and non-existing emails
- [ ] **Purpose Separation:** Password reset codes cannot be used for email verification and vice versa
- [ ] **Code Expiration:** Codes expire after 10 minutes
- [ ] **Code Invalidation:** Used codes cannot be reused
- [ ] **Password Hashing:** New password is properly hashed with argon2
- [ ] **Timing Attack Prevention:** Non-existent email path has slight delay to avoid timing differences

---

## Backward Compatibility

- [ ] Existing email verification flow still works (Test 1)
- [ ] Old verification codes in database still work (have null/default purpose='email_verification')
- [ ] No breaking changes to existing endpoints

---

## Notes for Testing

### Test Environment
- Use a real email account for testing (recommend Gmail or similar with inbox access)
- Ensure Resend API key is configured in .env
- Database must be running and migration applied
- Server must be running (flask run or similar)

### Test Accounts Needed
1. One existing account with verified email (for Test 2-8)
2. Or create new account during Test 1

### How to Run Tests
```bash
# Terminal 1: Start the server
cd Backend
flask run

# Terminal 2: Run tests
python -m pytest tests/test_password_reset.py -v

# Or manually with curl/Postman:
curl -X POST http://localhost:5000/api/v1/auth/forgot-password \
  -H "Content-Type: application/json" \
  -d '{"email":"testuser@example.com"}'
```

---

## Expected Test Results Summary

| Test # | Test Name | Expected Status | Security Critical |
|--------|-----------|-----------------|------------------|
| 1 | Email Verification | ✓ Working | - |
| 2 | Forgot Password (Real Email) | 200 | - |
| 3 | Forgot Password (Fake Email) | 200 | **YES** |
| 4 | Reset Password (Valid) | 200 | - |
| 5 | Login with New Password | 200 | - |
| 6 | Old Password Fails | 401 | - |
| 7 | Code Reuse Blocked | 400 | **YES** |
| 8 | Invalid Code Rejected | 400 | - |

---

## Sign-Off

Once all tests pass with real evidence:
- [ ] Feature complete and tested
- [ ] Security requirements met
- [ ] Backward compatibility verified
- [ ] Ready for code review
