# Own Your Day (OYD) MVP

Flutter MVP of an AI-driven productivity app inspired by Tiimo visual patterns, with a local-first data layer and smart gentle reminders.

## What Is Included

- Tiimo-inspired onboarding, planner, capture, focus, and insights UI.
- Light + dark themes with serif/sans typography pairing.
- Mock login flow for sprint one.
- Manual task creation + AI-assisted parsing via OpenAI `gpt-5-mini`.
- Rule-based priority inference and smart reminder timing.
- Gentle notification scheduling (primary + one follow-up).
- Local persistence via shared preferences (tasks, settings, notification events).
- Audio capture UI wiring present, implementation intentionally deferred.

## Run

```bash
flutter pub get
flutter run --dart-define=OYD_OPENAI_KEY=your_openai_key_here
```

You can also paste/update the OpenAI key in-app from Profile/Settings.

## Validation

```bash
flutter analyze
flutter test
```

## Architecture (MVP)

- `lib/state/app_controller.dart`: app state orchestration.
- `lib/core/services/openai_task_parser.dart`: AI parsing service.
- `lib/core/services/notification_service.dart`: local notification scheduling.
- `lib/core/services/local_storage_service.dart`: local persistence.
- `lib/app/app_shell.dart`: tab navigation + fade transitions.
- `lib/features/...`: feature-first UI modules.
