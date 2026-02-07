# Supabase Edge Functions (ozzie_full_app)

## JWT Verification

This Supabase project issues Auth JWTs that are rejected by the Edge runtime's built-in JWT verifier.
All functions in this repo perform **manual auth** by reading the `Authorization: Bearer <jwt>` header
and calling `supabaseAdmin.auth.getUser(token)`.

Because of that, **deploy functions with** `--no-verify-jwt`:

```bash
supabase functions deploy recitation_submit --use-api --no-verify-jwt
supabase functions deploy quiz_submit --use-api --no-verify-jwt
supabase functions deploy start_surah --use-api --no-verify-jwt
supabase functions deploy get_map_state --use-api --no-verify-jwt
supabase functions deploy level_complete --use-api --no-verify-jwt
```

If you forget this flag, calls to `/functions/v1/*` will fail **before your code runs** with a
`401` response like `{"code":401,"message":"Invalid JWT"}`.

You can confirm the current setting with:

```bash
supabase functions list --output json
```

## Secrets

`recitation_submit` uses OpenAI server-side transcription/scoring. Required secrets:

- `OPENAI_API_KEY`

Optional:

- `OPENAI_TRANSCRIBE_MODEL` (default: `gpt-4o-transcribe`)
- `OPENAI_TRANSCRIBE_ENDPOINT` (default: `https://api.openai.com/v1/audio/transcriptions`)
- `OPENAI_TIMEOUT_MS` (default: `25000`)

