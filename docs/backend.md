# Backend and Supabase Documentation

This document describes the current backend architecture implemented in:

- `supabase/migrations/*.sql`
- `supabase/functions/*/index.ts`
- Flutter repositories under `lib/features/**/repo/*.dart`

## 1) Backend Architecture at a Glance

The app uses Supabase in three roles:

1. Auth:
   - Parent account authentication (email/password)
2. Postgres:
   - Child profiles, progress state, map graph, attempts, sessions, streaks
3. Storage + Edge Functions:
   - Audio uploads into `recitations` bucket
   - Rule-enforced scoring and progression through server-side functions

Guiding rule: writes that affect progression, lockouts, scores, or stage movement are enforced in edge functions using service-role access.

## 2) Database Schema

Key schema is assembled through these migrations:

- `20260204233109_baseline_core_tables.sql`
- `20260203134000_phase1_backend.sql`
- `20260205001924_seed_surahs_verses.sql`
- `20260207103000_map_and_levels.sql`
- `20260207195500_seed_checkpoint_defs.sql`
- `20260204233200_storage_recitations.sql`

### Core account and child tables

- `profiles`
  - `id` (matches `auth.users.id`)
  - `display_name`
  - `pin_hash`
- `children`
  - `id`, `parent_id`, `name`, `avatar_key`, `birth_year`, `gender`
- `child_settings`
  - `daily_attempt_cap` (default 6)
  - `realtime_feedback_cap` (default 3)
  - `passes_required` (default 3)
  - `pass_threshold` (default 80)
  - `blur_after_attempt` (nullable)

### Progress and analytics tables

- `surah_progress`
  - stage enum-like text:
    - `LEARN_1_2`, `MINI_QUIZ_1`, `LEARN_3_4`, `MINI_QUIZ_2`, `LEARN_REST`, `FINAL_EXAM`, `COMPLETED`
- `ayah_progress`
  - tracks pass totals, daily attempts, failures, locks
- `recitation_attempts`
  - immutable ayah recitation logs
- `quiz_attempts`
  - checkpoint/final quiz logs
- `sessions`
  - session start/end windows
- `streaks`
  - rolling streak counters

### Map and level graph tables

- `galaxies`
- `galaxy_surahs`
- `surah_checkpoint_defs`
- `child_surah_state`
  - `NOT_STARTED`, `ACTIVE`, `COMPLETED`
  - `active_slot` constrained to 1..3
- `child_galaxy_state`
- `levels`
  - `SURAH_INTRO`, `VERSE_LESSON`, `CHECKPOINT`, `FINAL_EXAM`
- `child_level_progress`
  - `LOCKED`, `UNLOCKED`, `IN_PROGRESS`, `COMPLETED`
- `level_attempts`
  - attempt logs tied to level graph nodes

### Content tables used for scoring reference

- `surahs`
- `verses`

The app UI reads ayah content from bundled assets; backend scoring reads from `verses` to get Arabic reference text.

## 3) RLS Strategy

RLS is enabled on child-sensitive tables. Parent ownership checks generally use:

- match child row by `child_id`
- verify `children.parent_id = auth.uid()`

App-side direct writes are allowed for safe records (e.g., child CRUD, profile updates) but progression-sensitive mutations are performed inside edge functions using service role.

Storage RLS for `recitations` bucket is owner-based:

- insert/select/delete allowed where `auth.uid() = owner`

## 4) Edge Functions

All functions manually validate bearer tokens by calling:

- `supabaseAdmin.auth.getUser(token)`

Because of this, they must be deployed with `--no-verify-jwt`.

### 4.1 `recitation_submit`

Purpose:

- Score a single ayah recitation.
- Enforce daily failure caps and lockout.
- Update `ayah_progress`.
- Mirror attempts into level graph (`level_attempts`, `child_level_progress`) when level exists.
- Update streaks.

Input:

- `child_id`
- `surah_id`
- `ayah_id`
- `audio_path`
- optional `meta`

Important rules:

- Uses `child_settings`:
  - `daily_attempt_cap`
  - `realtime_feedback_cap`
  - `passes_required`
  - `pass_threshold`
  - `blur_after_attempt`
- Lockout logic is failure-based (not total attempts):
  - once failures today reach cap, lock until UTC tomorrow
- Detailed feedback only when:
  - failed
  - failure index > 3
  - detailed quota still available
- `mustReplayLearnStep` when consecutive fails >= 2
- Mastery requires cumulative passes (`passes_required`)

Scoring:

- If `OPENAI_API_KEY` present:
  - transcribes with OpenAI (`gpt-4o-transcribe` default)
  - computes normalized Arabic similarity via Levenshtein
- If no OpenAI key and `MOCK_SCORING=true|1|yes`:
  - mock pass flow for development

Returns (key fields):

- `score`, `passed`, `mistakeType`
- `passCountTotal`, `passesRemaining`
- `lessonReadyForComprehension`
- `attemptsToday`, `attemptsLeftToday`
- `showDetailedFeedback`
- `mustReplayLearnStep`
- `shouldBlurVerse`
- `ayahMasteredNow`
- `locked_until`

### 4.2 `ayah_lesson_complete`

Purpose:

- Completes a verse lesson node after recitation mastery.
- Unlocks the next level node.
- Updates `surah_progress` stage when moving into checkpoint/final nodes.

Input:

- `child_id`, `surah_id`, `ayah_id`

Returns:

- completion metadata
- `nextAyahId` or `nextGate` (`MINI_QUIZ_1`, `MINI_QUIZ_2`, `FINAL_EXAM`)

### 4.3 `level_recitation_submit`

Purpose:

- Handles memorization recitation for checkpoint/final quiz gates.
- Scores recitation across ayah range:
  - checkpoint uses `surah_checkpoint_defs`
  - final uses full surah (`1..ayah_count`)
- Writes to `level_attempts` with `attempt_kind = memorization_recitation`
- Updates `child_level_progress`
- Enforces gate lockout rules

Input:

- `child_id`
- `surah_id`
- `quiz_type` (`mini_1`, `mini_2`, `final`)
- `audio_path`

Thresholds:

- checkpoint pass threshold: `child_settings.pass_threshold` (default 80)
- final pass threshold: 75

Failure caps:

- checkpoint: 2 failures/day (combined recitation + quiz failures for that gate)
- final: 1 failure/day

Returns:

- `score`, `passed`, `transcript`, `mistakeType`
- `attemptsLeftToday`, `locked_until`
- evaluated ayah range (`from_ayah`, `to_ayah`)

### 4.4 `quiz_submit`

Purpose:

- Grades objective quiz answers.
- Requires a fresh server-graded recitation pass before quiz attempt.
- Logs `quiz_attempts`.
- Moves `surah_progress` stage on pass.
- Advances `child_level_progress`.
- On final pass:
  - marks surah completed
  - frees active slot
  - marks galaxy complete and unlocks next galaxy when applicable

Input:

- `child_id`, `surah_id`, `quiz_type`, `answers.items[]`
- each item includes `correct` from client-side objective grading

Scoring:

- score = correct/answered ratio
- threshold:
  - 70 for `mini_1` / `mini_2`
  - 75 for `final`

Returns:

- `score`, `passed`
- `nextStage`
- `attemptsLeftToday`
- `locked_until`

### 4.5 Map and progression support functions

- `start_surah`
  - activates a surah slot (max 3 active)
  - initializes level graph rows for the child
  - enforces galaxy unlock order
- `get_map_state`
  - returns child map state with lock reasons:
    - `GALAXY_LOCKED`
    - `NO_SLOTS`
    - `COMING_SOON`
- `level_complete`
  - generic level completion + next-level unlock helper
- `session_start`
  - starts or reuses open session within a 30-minute reuse window
- `session_end`
  - marks session counted and sets `ended_at`

## 5) Flutter-to-Function Contracts

Repository mapping in Flutter:

- `RecitationRepository.submitRecitation` -> `recitation_submit`
- `RecitationRepository.completeAyahLesson` -> `ayah_lesson_complete`
- `QuizRecitationRepository.submitLevelRecitation` -> `level_recitation_submit`
- `QuizRepository.submitQuiz` -> `quiz_submit`
- `MapRepository.fetchMapState` -> `get_map_state`
- `MapRepository.startSurah` -> `start_surah`
- `MapRepository.completeLevel` -> `level_complete`
- `PracticeSessionRepository.startSession` -> `session_start`
- `PracticeSessionRepository.endSession` -> `session_end`

All function invocations include bearer auth when session token is available.

## 6) Required Environment Variables

### Flutter runtime (`--dart-define` recommended)

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- optional: `LOG_FUNCTIONS_HTTP`

### Edge Functions

Required:

- `SUPABASE_URL`
- `SERVICE_ROLE_KEY` (or `SUPABASE_SERVICE_ROLE_KEY`)
- `SUPABASE_ANON_KEY` (for user-scoped storage download in scoring functions)

For real scoring:

- `OPENAI_API_KEY`

Optional scoring tunables:

- `OPENAI_TRANSCRIBE_MODEL` (default `gpt-4o-transcribe`)
- `OPENAI_TRANSCRIBE_ENDPOINT` (default OpenAI transcription endpoint)
- `OPENAI_TIMEOUT_MS` (default `25000`)
- `MOCK_SCORING` (`true|1|yes` to enable dev fallback if OpenAI key missing)

## 7) Deployment Commands

From project root:

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

Verify deployment flags:

```bash
supabase functions list --output json
```

## 8) Operational Caveats

1. The level graph is currently seeded for playable surahs `1` and `112`; other surahs can appear as map metadata but may return `COMING_SOON`.
2. Quiz objective grading currently relies on client-provided `correct` flags for objective question items; progression still remains server-gated.
3. `recitation_submit` currently returns `nextGate: null`; checkpoint transition is completed after comprehension via `ayah_lesson_complete`.
