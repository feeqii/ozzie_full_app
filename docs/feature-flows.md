# Feature Flows

This document captures the implemented user journeys and behavior contracts across child and parent experiences.

## 1) Parent Onboarding and Access Flow

### Account creation/sign-in

Routes:

- `/auth/onboarding`
- `/auth/entry`
- `/auth/signup`
- `/auth/signin`
- `/auth/forgot-password`

Behavior:

- Sign-up calls `AuthController.signUp` and upserts parent profile.
- Sign-in calls `AuthController.signIn`.
- Both success paths route to:
  - `/parent/pin/verify?next=/parent/child/select`

### Parent PIN gate

Routes:

- `/parent/pin/setup`
- `/parent/pin/verify`

Behavior:

- PIN setup stores `pin_hash` in `profiles`.
- PIN verify enforces attempt cooldown after repeated failures:
  - starts with 5 attempts
  - on exhaustion, 30-second cooldown
- Successful verify sets in-memory `pinVerifiedProvider = true`.
- Parent route helper `openParentRouteWithPin(...)` redirects through PIN as needed.

## 2) Child Selection and Profile Management

### Add child

Route:

- `/parent/child/add`

Behavior:

- Requires name, birth year, and gender.
- Inserts child row and ensures child settings row exists.
- Invalidates `childrenProvider`.
- Clears selected child and routes to `/parent/child/select`.

### Child selection

Provider behavior:

- `selectedChildIdProvider` persists selected id in `SharedPreferences`.
- `selectedChildProvider` resolves selected child model from loaded children.

Current note:

- `/parent/child/select` currently renders `ParentDashboardScreen` directly.

### Parent child profile

Route:

- `/parent/child/:childId/profile`

Behavior:

- Editable fields:
  - name
  - age (mapped back to `birth_year`)
- Non-persistent placeholder:
  - avatar upload (planned)
- Pulls progress summary for profile stats cards.

## 3) Child Learning Navigation Flow

Primary child routes:

- `/child/home`
- `/child/map`
- `/child/map/galaxy/:galaxyId`
- `/child/surah/:surahId`
- `/child/surah/:surahId/journey`
- `/child/surah/:surahId/intro/:levelId`
- `/child/surah/:surahId/ayah/:ayahId`
- `/child/surah/:surahId/ayah/:ayahId/recite`
- `/child/surah/:surahId/quiz/:quizType`

### Home and map

- Child home and galaxy map both consume `mapStateProvider`.
- Planet map allows surah activation:
  - calls `start_surah` if not yet active/completed
  - navigates into surah overview

### Surah overview and intro

- Surah overview loads static content from assets and marks intro level complete (best effort) before opening journey.
- Intro screen explicitly completes intro level (`level_complete`) before returning.

### Surah journey

- Journey list is assembled from:
  - `levels` (definition)
  - `child_level_progress` (status)
- Tapping unlocked steps routes by level type:
  - `SURAH_INTRO` -> intro route
  - `VERSE_LESSON` -> ayah learn route
  - `CHECKPOINT` -> quiz route by `quiz_type`
  - `FINAL_EXAM` -> quiz final route

## 4) Ayah Practice Flow

### Learn screen

Route:

- `/child/surah/:surahId/ayah/:ayahId`

Behavior:

- Shows Arabic + transliteration + meaning.
- Primary action navigates to recitation practice.
- Wrapped with `PracticeSessionBoundary` to ensure session tracking.

### Recitation practice

Route:

- `/child/surah/:surahId/ayah/:ayahId/recite`

Controller:

- `recitationControllerProvider(RecitationParams)`

State stages:

- `idle`, `recording`, `review`, `uploading`
- `feedbackSuccess`, `feedbackFail`
- `interventionRequired`, `lockedOut`
- `comprehension`, `lessonCompleted`

Behavior highlights:

1. Requests mic permission on first frame.
2. Uploads audio and calls `recitation_submit`.
3. On response:
   - lockout -> prompt and return to journey
   - fail + intervention required -> send child back to learn step
   - success with passes remaining -> continue reciting
   - success with mastery (`lessonReadyForComprehension`) -> comprehension questions
4. Comprehension completion triggers `ayah_lesson_complete`.
5. On lesson complete:
   - navigate to next ayah, or
   - prompt mini quiz gate, or
   - return to journey

## 5) Checkpoint and Final Quiz Flow

### Quiz screen

Route:

- `/child/surah/:surahId/quiz/:quizType`

Controllers:

- `quizControllerProvider(QuizParams)`
- `quizRecitationControllerProvider(QuizRecitationParams)`

Question model behavior:

- Supports recitation prompts and option-based questions.
- Current question bank is code-defined for surahs 1 and 112.

### Recitation prompt gate inside quiz

- For `recitePrompt` questions:
  - child must record and submit via `level_recitation_submit`
  - without pass, cannot continue to objective questions

### Objective quiz submission

- `quiz_submit` enforces:
  - stage/level allowance for quiz type
  - recitation prerequisite freshness
  - lockout rules
  - stage transitions

On pass:

- emits reward event:
  - checkpoint -> hasanat style reward
  - final exam -> trophy reward

On fail:

- shows retry flow and resets quiz/recitation local state as needed.

## 6) Progress and Analytics Flow

### Session boundaries

Practice session starts/ends are triggered by:

- entering/leaving `PracticeSessionBoundary`
- app lifecycle background/resume observer

Backend functions:

- `session_start`
- `session_end`

### Progress summaries

Repository:

- `ProgressRepository`

Sources:

- `streaks` -> streak summary
- `sessions` -> recitation time summary
- `recitation_attempts` + `quiz_attempts` -> merged score summary

UI consumers:

- Child:
  - `/child/progress`
  - `/child/progress/streak`
  - `/child/progress/time`
  - `/child/progress/score`
- Parent:
  - `/parent/child/:childId/progress`
  - child-specific streak/time/score pages

## 7) Parent Controls and Settings Flow

Implemented:

- child delete flow
- child add flow
- sign out
- PIN reset route access

Current placeholders (UI state only, not persisted):

- daily time goal
- show illustrations toggle
- notification preference toggles
- support/feedback action
- terms/privacy links
- account delete backend flow

## 8) Known Product/Flow Gaps

1. Lesson and quiz audio playback sources are TODO placeholders.
2. Quiz content source is local code; backend question-bank TODO remains.
3. Several parent settings are intentionally scaffolded until backend endpoints are finalized.
4. `SelectChildScreen` route currently forwards to parent dashboard implementation.
