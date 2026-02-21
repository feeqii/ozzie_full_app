# Ozzie Quran App

Ozzie is a Flutter + Supabase app for guided Quran learning, with distinct child and parent experiences:

- Child mode: map-based surah journey, ayah recitation practice, checkpoint/final quizzes, rewards, and progress tracking.
- Parent mode: secured PIN-gated controls, child profile management, and per-child progress dashboards.
- Backend-enforced learning rules: attempt budgets, lockouts, stage gating, and scoring are handled server-side in Supabase Edge Functions.

## Documentation Index

- `docs/architecture.md`: app architecture, module boundaries, routing, and state flow.
- `docs/feature-flows.md`: end-to-end parent and child user journeys.
- `docs/backend.md`: Supabase schema, edge functions, scoring rules, and deployment contracts.
- `docs/development.md`: local setup, environment variables, run/test workflow, and operations.
- `docs/testflight_setup.md`: iOS TestFlight pipeline and Fastlane setup.

## Tech Stack

- Flutter (Dart 3.9)
- Riverpod (state management)
- go_router (routing)
- supabase_flutter (auth/db/storage/functions)
- record + just_audio (recitation capture/playback)
- permission_handler, shared_preferences, http

## Quick Start

1. Install dependencies:

```bash
flutter pub get
```

2. (Recommended) install local git hooks:

```bash
./scripts/install-git-hooks.sh
```

3. Run the app:

```bash
flutter run
```

You can override Supabase values at runtime:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

## Testing

Run all tests:

```bash
flutter test
```

Targeted examples:

```bash
flutter test test/features/quiz/quiz_controller_test.dart
flutter test test/ui_overhaul_smoke_test.dart
```

## Secret Guardrails

Local pre-commit secret scanning is enabled via `.githooks/pre-commit`.

Install hooks:

```bash
./scripts/install-git-hooks.sh
```

Manual scans:

```bash
# Staged changes
./scripts/secret_guard.sh --staged

# Commit range
./scripts/secret_guard.sh --range origin/main...HEAD
```

The guard blocks common secret-bearing files (`.env`, key files, etc.) and token-like patterns.

## Supabase Function Deployment Note

This project manually validates JWTs inside Edge Functions using `supabaseAdmin.auth.getUser(token)`.

Deploy with `--no-verify-jwt`:

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

See `docs/backend.md` for full backend details.
