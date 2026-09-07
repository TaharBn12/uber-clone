# FCM service-account key (users app)

`uber_users_app` sends the "New trip request" push notification to drivers by
calling the **FCM HTTP v1 API** (`PushNotificationService`). That API needs an
OAuth2 token created from a Firebase **service-account key**.

## Setup

1. Firebase console → ⚙ **Project settings** → **Service accounts** →
   **Generate new private key**.
2. Save the downloaded file as
   `uber_users_app/assets/firebase/service_account.json`.
3. Rebuild the app (the whole `assets/firebase/` folder is bundled, so the file
   is picked up automatically).

`service_account.json` is listed in `.gitignore`, so your real key is never
committed. `service_account.example.json` shows the expected shape.

## Behaviour without a key

If the file is missing (fresh clone) or contains placeholder values, the app
still builds and runs normally – it only logs
`FCM: ... Push notifications are disabled` and skips the notification.

## CI

The GitHub Actions workflow (`.github/workflows/build-apks.yml`) writes the
key from the `FCM_SERVICE_ACCOUNT_JSON` repository secret before building, so
the APK it produces can send notifications.

> ⚠️ Anyone who can extract the APK can read this key. For production, move the
> sending logic to a Cloud Function / backend instead of shipping the key in the
> client.
