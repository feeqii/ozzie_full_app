# Ozzie Architecture

This document describes the current implementation architecture in `lib/` and how feature modules connect to Supabase-backed services.

## 1) System Overview

The app is structured around four runtime layers:

1. App bootstrap + platform shell
2. Navigation and access gates
3. Feature modules (child, parent, map, recitation, quiz, progress)
4. Data access (Supabase repositories + local asset repositories)

At runtime:

- `main.dart` boots a global `ProviderScope`.
- `AppBootstrap` initializes Supabase and function auth headers.
- `GoRouter` resolves auth + child selection + parent-route guard behavior.
- Feature screens interact through Riverpod providers and repository classes.

## 2) Entry, Bootstrap, and Global Wiring

### App entry

- File: `lib/main.dart`
- `OzzieApp` uses `MaterialApp.router`.
- While bootstrap is not ready, app shows `AppStartupScreen`.
- A lifecycle observer (`practiceSessionLifecycleProvider`) is always active after bootstrap to track session boundaries.

### Supabase bootstrap

- File: `lib/core/app_bootstrap.dart`
- Uses `Supabase.initialize(...)`.
- Supports runtime config through:
  - `SUPABASE_URL`
  - `SUPABASE_ANON_KEY`
- Includes fallback values in code for convenience.
- Syncs edge-function auth token:
  - Uses session access token when available.
  - Falls back to anon key if no session.
- Optional HTTP debug logging for function calls:
  - `--dart-define=LOG_FUNCTIONS_HTTP=true`

### Startup states

- Files:
  - `lib/core/app_startup_state.dart`
  - `lib/core/app_startup_screen.dart`
- States: `initial`, `ready`, `error`.
- On error, UI shows a detailed startup failure panel.

## 3) Navigation and Access Gates

### Router provider

- File: `lib/core/router/app_router.dart`
- Provider: `appRouterProvider`
- Initial location: `/auth/onboarding`
- Refresh trigger: auth session stream (`authSessionProvider.stream`)

### Redirect strategy (high-level)

- Unauthenticated users are kept in `/auth/*`.
- Authenticated users must have:
  - profile loaded
  - children loaded
  - valid selected child (except explicitly allowed parent routes)
- Parent-only routes are restricted to:
  - `/parent/dashboard`
  - `/parent/settings`
  - `/parent/child/*`
  - `/parent/pin/*`
- Non-child/non-parent routes after auth redirect to `/child/home`.

### Current route map

Auth:

- `/auth/onboarding`
- `/auth/entry`
- `/auth/signup`
- `/auth/signin`
- `/auth/forgot-password`

Parent:

- `/parent/pin/setup`
- `/parent/pin/verify`
- `/parent/dashboard`
- `/parent/settings`
- `/parent/child/select`
- `/parent/child/add`
- `/parent/child/:childId/dashboard`
- `/parent/child/:childId/profile`
- `/parent/child/:childId/control`
- `/parent/child/:childId/control/notifications`
- `/parent/child/:childId/progress`
- `/parent/child/:childId/progress/streak`
- `/parent/child/:childId/progress/time`
- `/parent/child/:childId/progress/score`

Child:

- `/child/home`
- `/child/map`
- `/child/map/galaxy/:galaxyId`
- `/child/progress`
- `/child/progress/streak`
- `/child/progress/time`
- `/child/progress/score`
- `/child/reward`
- `/child/surah/:surahId`
- `/child/surah/:surahId/journey`
- `/child/surah/:surahId/intro/:levelId`
- `/child/surah/:surahId/ayah/:ayahId`
- `/child/surah/:surahId/ayah/:ayahId/recite`
- `/child/surah/:surahId/quiz/:quizType`

## 4) Module Layout

Top-level structure under `lib/features`:

- `auth`: sign-up/sign-in/reset + auth state controller
- `child`: child home, surah screens, journey UI system
- `content`: local-asset Quran content repository (`assets/content/*.json`)
- `journey`: level graph + per-child level progress composition
- `map`: galaxy/surah availability and activation
- `onboarding`: onboarding design system and auth onboarding pages
- `parent`: parent dashboard, PIN flow, child controls, profile editing
- `progress`: streak/time/score summaries and session lifecycle integration
- `quiz`: quiz state machine + quiz recitation flow
- `recitation`: ayah recitation state machine + comprehension step
- `rewards`: reward event models and reward screen

## 5) State Management Pattern

Riverpod usage follows a repository + controller split:

- Repository providers encapsulate external I/O.
- `FutureProvider` / `StreamProvider` expose read models.
- `StateNotifierProvider` manages interactive flow state machines.

Examples:

- Auth:
  - `authSessionProvider` (stream)
  - `authControllerProvider` (`StateNotifier`)
- Child selection:
  - `childrenProvider` + `selectedChildIdProvider`
  - `selected_child_id` persisted in `SharedPreferences`
- Recitation:
  - `recitationControllerProvider(RecitationParams)`
- Quiz:
  - `quizControllerProvider(QuizParams)`
  - `quizRecitationControllerProvider(QuizRecitationParams)`

## 6) Practice Session Lifecycle

Files:

- `lib/features/progress/widgets/practice_session_boundary.dart`
- `lib/core/practice_session_lifecycle_provider.dart`
- `lib/features/progress/providers/practice_session_controller.dart`

Behavior:

- Practice screens wrap content in `PracticeSessionBoundary`.
- Entering a boundary increments practice depth and starts (or reuses) session via `session_start`.
- Exiting decrements depth; when depth hits zero, `session_end` is called.
- App background/resume also ends/restarts sessions to avoid inflated durations.
- After session end, progress providers are invalidated for fresh dashboard data.

## 7) UI Systems and Themes

The app intentionally uses separate visual systems by experience:

- Global app theme:
  - `lib/core/theme/*`
  - Primary fonts: Inter + Baloo2 + NotoNaskhArabic
- Child mission theme:
  - `lib/features/child/ui/mission_tokens.dart`
  - Poppins + Lora styling, mission card/button primitives
- Parent theme:
  - `lib/features/parent/ui/parent_tokens.dart`
- Onboarding theme:
  - `lib/features/onboarding/theme/onboarding_tokens.dart`

Reusable component libraries:

- `lib/core/ui/*` (buttons, app bars, cards, recorder module, option cards, etc.)
- `lib/features/child/ui/*` and `lib/features/parent/ui/*` for mode-specific components

## 8) Core Feature State Machines

### Recitation (ayah-level)

- Controller: `recitation_controller.dart`
- Stages:
  - `idle`
  - `recording`
  - `review`
  - `uploading`
  - `comprehension`
  - `lessonCompleted`
  - `feedbackSuccess`
  - `feedbackFail`
  - `interventionRequired`
  - `lockedOut`
  - `gateToQuiz` (reserved stage)

Key details:

- Ensures microphone permission and app settings fallback.
- Uploads audio to Supabase Storage bucket `recitations`.
- Calls edge function `recitation_submit`.
- For mastered ayah (`passesRemaining == 0`), enters comprehension question flow.
- Completes lesson via `ayah_lesson_complete`, then navigates to next ayah or gate.

### Quiz (checkpoint/final)

- Controllers:
  - `quiz_controller.dart` (question flow and scoring submission)
  - `quiz_recitation_controller.dart` (recitation prompt questions)

Key details:

- Question sets are currently hard-coded for surahs `1` and `112`.
- Recitation prompt questions require `level_recitation_submit`.
- Main quiz submission uses `quiz_submit`.
- Handles lockouts, reward events, and return-to-journey routing.

## 9) Data Boundaries

- Local static content:
  - `assets/content/surah_list.json`
  - `assets/content/surah_1.json`
  - `assets/content/surah_112.json`
- Supabase data:
  - account/child records
  - map + levels + progress graph
  - attempts, sessions, streaks
  - storage objects
- Edge Functions mediate all rule-sensitive writes.

## 10) Architectural Notes and Known Gaps

1. `SelectChildScreen` currently delegates directly to `ParentDashboardScreen`; route naming and behavior can be tightened.
2. Quiz question bank is local code; moving to backend-managed content is tracked by TODO in `quiz_controller.dart`.
3. Several UX settings are local-only placeholders (notifications, parent control toggles, support links, avatar upload).
4. Child learning media playback is scaffolded with placeholders (`lesson-audio`, `quiz-audio` TODOs).
