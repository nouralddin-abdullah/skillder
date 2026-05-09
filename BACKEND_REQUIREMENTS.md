# Skillder — Backend Requirements

Quick spec for what the Flutter app sends to the backend.

---

## 1. Auth

### `POST /auth/signup`
**Body:** `{ name, email, password }`

### `POST /auth/login`
**Body:** `{ email, password }`

### `POST /auth/forgot-password`
**Body:** `{ email }`

### `POST /auth/google`  *(NEW — needed for Sign in with Google)*
**Body:** `{ idToken }`

The Flutter app uses the official `google_sign_in` SDK to get a Google ID token natively (no in-app browser / redirect). It then POSTs that token here. The backend should:

1. Verify `idToken` against Google's JWKS, with **audience = our Web Client ID**: `125212125733-ke01ioteqb7v882bnt3sr360fhbsttjv.apps.googleusercontent.com`
2. Extract `email`, `name`, `sub` (Google user ID) from the token
3. Look up the user by email; if not found, create a new one (no password) with `onboardingComplete: false`. Use Google's `name` claim as a temporary name — the user will confirm/replace it during onboarding.
4. Return: `{ accessToken, expiresIn, tokenType, userId, isNewUser }` — the client uses `isNewUser` to show a "Confirm your full name" field on the Identity step (so users aren't stuck with whatever Google has on file).

> The existing `GET /auth/google` + `GET /auth/google/callback` redirect endpoints are not used by the mobile app; they can stay for a future website.

> After login/signup we expect a token to use as a bearer in the `Authorization` header for all subsequent requests.

---

## 2. Onboarding

The onboarding flow has 7 steps. **Steps 0–3 are mandatory, 4–5 skippable, 6 is just House Rules acceptance.**

We patch the user incrementally after each step (so partial progress survives).

### Fields collected (in order)

| Step | Field(s) | Type | Required |
|------|----------|------|----------|
| 0 | `profilePhoto` (multipart upload) | image | yes |
| 0 | `name` | string | only if Google new-user (`isNewUser: true`) |
| 0 | `headline` | string | yes |
| 1 | `giveSkills` | string[] (max 10) | yes, ≥1 |
| 2 | `getSkills` | string[] (max 10) | yes, ≥1 |
| 3 | `intents` | string[] from `["swap", "colearn", "mentor"]` | yes, ≥1 |
| 4 | `education` | enum: High School / In College / Bachelors / In Grad School / Masters / PhD / Trade School | optional |
| 4 | `careerStage` | enum: Student / Intern / Junior / Mid-level / Senior / Lead / Manager / Founder | optional |
| 4 | `domain` | enum: Technology / Finance / HR / Marketing / Design / Healthcare / Education / Legal / Sales / Operations | optional |
| 4 | `workStyle` | enum: Remote / Office / Hybrid | optional |
| 5 | `fuelSource` | enum: Coffee / Matcha / Tea / Energy Drinks / Photosynthesizing | optional |
| 5 | `focusSoundtrack` | enum: Lofi Beats / Silence / Heavy Metal / Spotify Random | optional |
| 5 | `rechargeMode` | enum: Cozy Gaming / Gym / Touching Grass / Reading / Sleeping | optional |
| 6 | `acceptedHouseRules: true` + `onboardingComplete: true` | bool | yes |

### `POST /users/me/photos` (multipart)
For step 0 profile photo upload.

---

## 3. User (Profile)

### `GET /users/me`
Used to hydrate the Profile tab and Edit Profile screen.

### `PATCH /users/me`
Partial update — send only changed fields. Used by every Edit Profile section (About Me, Prompts, Skills, Intent, Basics, Lifestyle).

**Body examples:**
```json
{ "bio": "new about me text" }
```
```json
{ "prompts": [{ "prompt": "...", "answer": "..." }] }
```
```json
{ "giveSkills": ["Flutter", "UI Design"] }
```

### `POST /users/me/photos` (multipart)
Add a new photo. Field name: `photo`. Content-Type must be set on the part (`image/jpeg`, `image/png`, etc).

### `DELETE /users/me/photos/{photoId}`
Remove the photo with the given ID.

### `PATCH /users/me/photos/order`
Reorder photos. **Body:** `{ "order": ["id-a", "id-b", ...] }`

---

## Notes

- All enums above should be validated server-side; client sends the exact strings shown.
- Photos: max 9 per user, JPEG/PNG.
- Skills lists are free-form strings (the client picks from a curated list, but treat as plain `string[]`).
