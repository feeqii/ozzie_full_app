# Development Guide

This guide covers local setup, run/test routines, Supabase operations, and common troubleshooting steps.

## 1) Prerequisites

- Flutter SDK compatible with Dart `^3.9.2`
- Xcode (for iOS builds) and/or Android Studio SDK tooling
- Supabase CLI (for migrations and edge functions)
- Node/Deno runtime support required by Supabase functions toolchain

Optional:

- Ruby + Bundler (for iOS Fastlane/TestFlight workflow)

## 2) Project Setup

1. Install Flutter dependencies:

```bash
flutter pub get
```

2. Install local pre-commit hooks:

```bash
./scripts/install-git-hooks.sh
```

3. Review `.env.example` for expected runtime vars.

## 3) Running the App

Basic run:

```bash
flutter run
```

Explicit Supabase runtime configuration:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

Enable function HTTP diagnostics:

```bash
flutter run --dart-define=LOG_FUNCTIONS_HTTP=true
```

## 4) Supabase Workflow

### Apply migrations

Use your preferred Supabase flow (local linked project or remote project). Typical command:

```bash
supabase db push
```

### Deploy edge functions

All functions must be deployed with manual JWT verification disabled:

```bash
supabase functions deploy recitation_submit --use-api --no-verify-jwt
supabase functions deploy quiz_submit --use-api --no-verify-jwt
supabase functions deploy level_recitation_submit --use-api --no-verify-jwt
supabase functions deploy ayah_lesson_complete --use-api --no-verify-jwt
supabase functions deploy start_surah --use-api --no-verify-jwt
supabase functions deploy get_map_state --use-api --no-verify-jwt
supabase functions deploy level_complete --use-api --no-verify-jwt
supabase functions deploy session_start --use-api --no-verify-jwt
supabase functions deploy session_end --use-api --no-verify-jwt
```

Confirm function settings:

```bash
supabase functions list --output json
```

### Required function secrets

Set at project level:

- `SUPABASE_URL`
- `SERVICE_ROLE_KEY` or `SUPABASE_SERVICE_ROLE_KEY`
- `SUPABASE_ANON_KEY`

Set for production scoring:

- `OPENAI_API_KEY`

Optional:

- `OPENAI_TRANSCRIBE_MODEL`
- `OPENAI_TRANSCRIBE_ENDPOINT`
- `OPENAI_TIMEOUT_MS`
- `MOCK_SCORING`

## 5) Test Strategy and Commands

Run all tests:

```bash
flutter test
```

Run targeted suites:

```bash
flutter test test/features/quiz/quiz_controller_test.dart
flutter test test/arabic_similarity_test.dart
flutter test test/ui_overhaul_smoke_test.dart
```

Coverage areas currently emphasized:

- Arabic normalization/similarity utility
- quiz controller correctness/feedback behavior
- child progress screen layout stability
- UI smoke regression for major mission/map/quiz/recitation screens

## 6) iOS TestFlight

See detailed steps in `docs/testflight_setup.md`.

Fastlane lane references:

- `ios bootstrap`: one-time App Store Connect app record
- `ios upload_testflight`: build + upload IPA

## 7) Secret Scanning Guardrails

Before commit:

```bash
./scripts/secret_guard.sh --staged
```

Scan commit range:

```bash
./scripts/secret_guard.sh --range origin/main...HEAD
```

Path and content checks block common accidental secret leaks (env files, keys, token-like strings).

## 8) Troubleshooting

### Startup screen shows "Supabase init failed"

Checks:

1. Ensure `SUPABASE_URL` and `SUPABASE_ANON_KEY` are valid.
2. Ensure network access to Supabase project is available.
3. Re-run with explicit `--dart-define` values.

### Edge function returns `401 Invalid JWT` before code runs

Cause:

- Function deployed without `--no-verify-jwt`.

Fix:

- Re-deploy affected function with `--no-verify-jwt`.

### Function returns auth/session errors during recitation/quiz

Checks:

1. Confirm user is signed in (session exists).
2. Confirm app session token is still valid.
3. Inspect logs with `LOG_FUNCTIONS_HTTP=true`.

### Recitation scoring fails with configuration errors

Checks:

1. `SUPABASE_ANON_KEY` present in function env.
2. `OPENAI_API_KEY` present (unless intentionally using mock scoring).
3. `MOCK_SCORING` set only for development fallback use.

### Map or journey shows content locked unexpectedly

Checks:

1. Verify level rows exist for target surah in `levels`.
2. Confirm `child_level_progress` rows initialized via `start_surah`.
3. Confirm active slot limit (max 3 active surahs) has not been reached.
