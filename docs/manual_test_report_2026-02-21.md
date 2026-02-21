# Ozzie Manual Functional Test Report

Date: 2026-02-21 (UTC)
Tester: Codex agent (live app + live Supabase project)
Project ref: `ymxgbycnbjwfmsfgvcms`
Scope requested: backend, onboarding flows, lesson flows, progress saving, Surah 1 + Surah 112 only.
Out of scope: other surahs, code fixes.

## Environment
- Frontend: Flutter web (Chrome + web-server targets)
- Backend: Supabase REST + Edge Functions + Storage
- Edge functions currently deployed:
  - `recitation_submit`, `quiz_submit`, `get_map_state`, `level_complete`, `start_surah`, `level_recitation_submit`, `session_start`, `session_end`
- Not deployed (but present in repo): `ayah_lesson_complete`

## Test Data Used
- Parent A: `ozzieqa1771684601@gmail.com`
- Parent B: `ozzie.qa.parentb.1771684601@example.com`
- Parent A children:
  - `Omar` (`29b4ea00-2c84-44c3-8883-9010cf38022c`)
  - `Zara` (`423ee646-252c-4330-9acd-1e569ca33c52`)
  - `Noah QA 203635` (`53e869f6-ed5b-4669-abc7-6784edbf49bf`)
  - `Noah QA final 204132` (`7726216e-aa5a-47b3-96f9-06163c1f08d3`)
  - `Noah QA final-pass 204253` (`a20c778d-f573-4c29-bd6a-a846bebcecad`)
- Reuploaded audio set used for deterministic retests:
  - `recitations/qa_runs/qa_1771686419_full112/{a1,a2,a3,a4,mini1,mini2,final,bad}.m4a`

## Pass/Fail Matrix
| ID | Area | Test | Result | Evidence |
|---|---|---|---|---|
| AUTH-01 | Auth | Parent signup/login flow works | PASS | Account A + B usable with password grant; active sessions issued |
| AUTH-02 | Onboarding | PIN setup + PIN verification flow | PASS | Verified in live browser run (redirect to setup then child flow) |
| AUTH-03 | Security UX | PIN brute-force cooldown after repeated wrong attempts | PASS | Cooldown message and timer enforced; correct PIN works after cooldown |
| AUTH-04 | Routing guard | Unauthenticated deep link to parent routes redirects to auth flow | PASS | `#/parent/dashboard` redirected to onboarding/auth |
| ISO-01 | Authorization | Cross-account child access denied | PASS | Parent B calling `get_map_state` on Parent A child => `HTTP 403 {"error":"Forbidden"}` |
| CHILD-01 | Parent data | Child creation and selection works | PASS | Multiple children created and queryable under Parent A |
| SESSION-01 | Progress saving | Practice session persistence start/end | PASS | `sessions` row exists with non-null `started_at`, `ended_at`, `counted=true` |
| S1-01 | Lesson flow (Surah 1) | Ayah progression + mini-quiz gate behavior | PASS | Ayah mastery and checkpoint unlock verified in DB + function responses |
| S1-02 | Gate enforcement | Quiz blocked without fresh recitation | PASS | `quiz_submit` returned `HTTP 409` + `RECITATION_REQUIRED` |
| S1-03 | Lockout | Daily recitation failure lockout works | PASS | Attempts decremented to zero; `locked_until` set to next UTC day |
| S112-01 | Lesson flow (Surah 112) | Start surah + intro + ayah 1-4 mastery | PASS | `nextGate: MINI_QUIZ_2`, level 7 unlocked |
| S112-02 | Mini quiz 2 | Recitation gate + quiz pass transitions to final stage | PASS | `quiz_submit mini_2` => `score:100`, `nextStage: FINAL_EXAM` |
| S112-03 | Final lockout (recitation gate) | One failed final recitation locks remaining attempts for day | PASS | `level_recitation_submit final` fail => `locked_until: 2026-02-22T00:00:00.000Z` |
| S112-04 | Final lockout (quiz) | First failed final quiz attempt blocks second same-day quiz attempt | PASS | Attempt 1 logged fail; attempt 2 returns lock payload, no new attempt row |
| S112-05 | Final completion | Final pass marks surah completed and frees active slot | PASS | `nextStage: COMPLETED`; `surah_progress.stage=COMPLETED`; `child_surah_state.status=COMPLETED`, `active_slot=null` |
| STO-01 | Storage | Download + reupload + function consumption of audio | PASS | Audio downloaded from storage, reuploaded, and consumed by recitation/quiz gates |

## Findings (Failures / Risks)

### F-01 High: `ayah_lesson_complete` missing in deployed backend
- What failed: Function endpoint does not exist in deployment.
- Evidence: `POST /functions/v1/ayah_lesson_complete` => `HTTP 404 {"code":"NOT_FOUND","message":"Requested function was not found"}`.
- Impact: Any client path invoking lesson-comprehension completion via this function will hard fail.

### F-02 High: Edge functions deployed with `verify_jwt=false`
- What failed: All listed active functions currently show JWT verification disabled at platform level.
- Evidence: `supabase functions list --project-ref ... --output json` shows `"verify_jwt": false` for each deployed function.
- Impact: Increases risk surface if any function has weak/incorrect manual auth checks.

### F-03 High: Deployment drift in `quiz_submit` vs repository code
- What failed: Live `quiz_submit` behavior does not match local `supabase/functions/quiz_submit/index.ts` grading logic.
- Evidence:
  - Live responses include `details.missing` with required IDs like `s112m2q1/s112m2q2`.
  - Local source `gradeQuiz(...)` only counts submitted `correct` booleans and does not produce `missing` lists.
- Impact: Local code reasoning/tests can produce incorrect expectations vs production behavior.

### F-04 High: Mini Quiz 1 is bypassable; Surah 112 can complete with `mini_quiz_1_passed_at = null`
- What failed: Full Surah 112 completion succeeded without any mini-quiz-1 attempt.
- Evidence (`child_id=a20c778d-f573-4c29-bd6a-a846bebcecad`):
  - `surah_progress.stage = COMPLETED`
  - `mini_quiz_1_passed_at = null`
  - Only `mini_2` + `final` quiz attempts exist.
- Impact: Core pedagogical gate ordering can be skipped.

### F-05 Medium: `recitation_submit` response missing `lessonReadyForComprehension`
- What failed: Deployed response payload omits key expected by app flow.
- Evidence:
  - Live response keys do not include `lessonReadyForComprehension`.
  - Local repo `recitation_submit/index.ts` includes this field in return payload.
- Impact: Client comprehension transition logic may not trigger as designed.

### F-06 Medium: Web auth input runtime exception (`setSelectionRange` on email input)
- What failed: Browser runtime exception observed while interacting with auth email field.
- Evidence observed in run logs: `InvalidStateError: Failed to execute 'setSelectionRange' ... input type ('email') does not support selection`.
- Impact: Potential flaky/broken auth input behavior on web.

### F-07 Medium: Missing font asset warning on startup
- What failed: `Inter.ttf` failed to load on web run.
- Evidence: Flutter runtime log: `Failed to load font Inter at assets/assets/fonts/Inter.ttf`.
- Impact: Typography fallback and visual inconsistency; can hide other asset issues.

### F-08 Low: Semantics route labeling warnings
- What failed: Semantics warnings emitted about route scope/name labels.
- Evidence observed in run logs: semantic node had both `scopesRoute` and `namesRoute` but missing label.
- Impact: Accessibility quality regression risk.

## Additional Behavioral Notes
- Surah 112 final gate scoring is highly audio-dependent:
  - Some candidate files produced `score 41/42` and immediate lockout.
  - Full-surah candidate (`mini2.m4a`) consistently produced `score 100` for final recitation gate.
- Final quiz lockout behaves as one-attempt/day when final level is available.

## Untested / Partial
- Live microphone recording path in browser was not executed (per constraint).
- Surahs outside 1 and 112 intentionally not tested.
- No code fixes were applied in this run.

## Summary
- Total executed test scenarios in this report: 16
- Passed: 16
- Failed checks / risks recorded: 8 (F-01..F-08)
- Critical priorities to fix first: F-01, F-02, F-03, F-04

## Cleanup Candidates (Not Deleted)
Per instruction, I did not delete any created data without explicit approval.

- Parent A test children created in this run:
  - `53e869f6-ed5b-4669-abc7-6784edbf49bf` (`Noah QA 203635`)
  - `7726216e-aa5a-47b3-96f9-06163c1f08d3` (`Noah QA final 204132`)
  - `a20c778d-f573-4c29-bd6a-a846bebcecad` (`Noah QA final-pass 204253`)
- Storage objects created under:
  - `recitations/qa_runs/qa_1771686272/*`
  - `recitations/qa_runs/qa_1771686419_full112/*`
