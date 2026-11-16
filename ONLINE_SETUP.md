# Online setup (for the parent — do this once)

Online play needs a real Firebase project. Until these steps are done the
app still starts fine and Vs Computer / Pass & Play work fully; the
Online button shows "online setup pending".

## 1. Create the Firebase project

1. Go to https://console.firebase.google.com → Add project.
2. Name it e.g. `tam-ludo`. Google Analytics is optional — skip it.
3. In the project, go to **Build → Realtime Database → Create database**.
   - Start in **locked mode** first, then replace the rules with the ones
     in step 3 below.
   - Location: pick the nearest region (e.g. `asia-southeast1`).

## 2. Register the Android app

1. Project settings → **Your apps → Add app → Android**.
2. Android package name: `com.tam.ludo`
3. App nickname: `TAM Ludo`.
4. Download **`google-services.json`** and place it at:
   `android/app/google-services.json`
5. In `android/settings.gradle.kts`, add the Google services plugin to
   the plugins block:
   ```kotlin
   plugins {
       id("com.google.gms.google-services") version "4.4.2" apply false
   }
   ```
6. In `android/app/build.gradle.kts`, add at the top of the plugins block:
   ```kotlin
   plugins {
       id("com.google.gms.google-services")
       // ...existing plugins
   }
   ```
   (Do NOT add the plugin before `google-services.json` is in place —
   the build fails without it. That is why the plugin is deliberately
   absent from this source.)

## 3. Realtime Database rules

Rooms are addressed by their 6-character code, which acts as the shared
secret. Anyone with the code can read/write that room — that is the
casual-game tradeoff (no accounts, no sign-up). It is NOT production
authentication; do not store anything sensitive in rooms.

```json
{
  "rules": {
    "rooms": {
      "$code": {
        ".read": true,
        ".write": true
      }
    }
  }
}
```

If you want a little more safety later, add a size cap and a
`createdAt` check, or move to Firebase Auth anonymous sign-in and
restrict writes to room members. For a casual Ludo game the rules above
are the intended starting point.

## 4. Verify

1. `flutter pub get`
2. Run the app on two phones/emulators.
3. Phone A: Online → Create Room → share the code.
4. Phone B: Online → Join Room → enter the code.
5. Host taps Start Game once both are listed. Both boards should show
   the same dice, tokens and turn.
