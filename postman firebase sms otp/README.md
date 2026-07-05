Testing Firebase Phone/SMS Authentication directly inside **Postman** requires using the Google Identity Toolkit REST API.

Because production SMS requests require client app verification (like reCAPTCHA or Play Integrity tokens) to prevent spam abuse, you **cannot** easily trigger a real SMS to a real phone number straight from Postman without passing those client tokens.

However, Firebase provides a built-in mechanism for **fictional phone numbers** precisely for testing APIs, Postman collections, and CI/CD pipelines.

---

## Step 1: Pre-requisites in Firebase Console

1. Go to the **Firebase Console** and select your project.
2. Navigate to **Build > Authentication > Sign-in method**.
3. Enable **Phone** authentication.
4. Scroll down to **Phone numbers for testing (optional)**.
5. Add a fictional phone number (e.g., `+1 650-555-1234`) and a 6-digit test OTP (e.g., `123456`).
6. Copy your **Web API Key** from **Project Settings (Gear Icon) > General**.

---

## Step 2: Send the Verification Code (Request OTP)

This step mimics the app asking Firebase to send an SMS. It will return a `sessionInfo` token required for the next step.

* **HTTP Method:** `POST`
* **URL:** `https://identitytoolkit.googleapis.com/v1/accounts:sendVerificationCode?key=YOUR_WEB_API_KEY`
* **Headers:** `Content-Type: application/json`

**Request Body (JSON):**

```json
{
  "phoneNumber": "+16505551234"
}

```

**Expected Response (JSON):**

```json
{
  "sessionInfo": "AIzaSyA1...VERY_LONG_ENCRYPTED_STRING...7wQ"
}

```

> 💡 *Copy the entire `sessionInfo` value from the response.*

---

## Step 3: Verify the OTP & Sign In

Now, pass the `sessionInfo` along with the OTP code you configured in the Firebase Console to log the user in and receive a Firebase Auth ID token.

* **HTTP Method:** `POST`
* **URL:** `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPhoneNumber?key=YOUR_WEB_API_KEY`
* **Headers:** `Content-Type: application/json`

**Request Body (JSON):**

```json
{
  "sessionInfo": "PASTE_YOUR_SESSION_INFO_STRING_HERE",
  "code": "123456"
}

```

**Expected Response (JSON):**

```json
{
  "idToken": "eyJhbGciOiJSUzI1NiIs...",
  "refreshToken": "AMf-vByY...",
  "expiresIn": "3600",
  "localId": "U1serIdAbCdEfGhIj...",
  "isNewUser": false,
  "phoneNumber": "+16505551234"
}

```

---

## 🛠️ Postman Pro-Tip: Automate the Flow

Instead of manually copying and pasting the `sessionInfo`, you can save it into a Postman variable.

In your **Send Verification Code** request, go to the **Tests** tab and add this script:

```javascript
const response = pm.response.json();
if (response.sessionInfo) {
    pm.environment.set("firebase_session", response.sessionInfo);
}

```

In your **Verify OTP** request body, simply reference it like this:

```json
{
  "sessionInfo": "{{firebase_session}}",
  "code": "123456"
}

```
