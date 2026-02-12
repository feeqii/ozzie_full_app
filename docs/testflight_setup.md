# App Store Connect + TestFlight (Flutter iOS)

This project is preconfigured with:
- Bundle ID: `com.shafeeqmagdum.ozzie`
- Team ID: `PHUFD6V977`

## 1) Apple one-time prerequisites

1. Join Apple Developer Program (paid account).
2. In App Store Connect, accept any pending agreements.
3. In App Store Connect, create an API key:
   - Users and Access -> Integrations -> App Store Connect API -> `+`
   - Save `Key ID`, `Issuer ID`, and the `.p8` key file.

## 2) Install tooling

From repo root:

```bash
cd ios
bundle install
cp .env.fastlane.example .env.fastlane
```

## 3) Fill env vars

Edit `ios/.env.fastlane` and set values.

For `ASC_KEY_CONTENT`, use base64 of your `.p8` file:

```bash
base64 -i /absolute/path/to/AuthKey_XXXXXX.p8 | pbcopy
```

Paste clipboard value into `ASC_KEY_CONTENT`.

## 4) Create app record in App Store Connect (one-time)

```bash
cd ios
bundle exec fastlane bootstrap
```

If the app already exists, skip this step.

## 5) Build + upload to TestFlight

```bash
cd ios
bundle exec fastlane upload_testflight
```

## 6) Add your co-founder as a tester

1. App Store Connect -> Your app -> TestFlight.
2. Add internal tester (fastest; no review required for internal).
3. Your co-founder installs the TestFlight app and accepts invite.

## Notes

- If upload succeeds but build is not visible yet, wait 5-20 minutes for processing.
- If signing fails, open `ios/Runner.xcworkspace` once in Xcode, enable "Automatically manage signing", choose team `PHUFD6V977`, then rerun upload.
