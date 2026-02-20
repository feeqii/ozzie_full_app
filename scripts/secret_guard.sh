#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/secret_guard.sh --staged
  scripts/secret_guard.sh --range <git-range>

Examples:
  scripts/secret_guard.sh --staged
  scripts/secret_guard.sh --range origin/main...HEAD
EOF
}

scan_mode="${1:-}"
scan_range="${2:-}"

if [[ "$scan_mode" != "--staged" && "$scan_mode" != "--range" ]]; then
  usage
  exit 2
fi

if [[ "$scan_mode" == "--range" && -z "$scan_range" ]]; then
  echo "Missing git range for --range mode." >&2
  usage
  exit 2
fi

allow_env_example() {
  local path="$1"
  [[ "$path" == ".env.example" || "$path" == */".env.example" || "$path" == "ios/.env.fastlane.example" ]]
}

is_blocked_path() {
  local path="$1"

  case "$path" in
    notes|.kilocode/mcp.json)
      return 0
      ;;
    .env|.env.*|*/.env|*/.env.*)
      if allow_env_example "$path"; then
        return 1
      fi
      return 0
      ;;
    ios/AuthKey_*.p8|*.pem|*.p12)
      return 0
      ;;
  esac

  return 1
}

collect_changed_paths() {
  if [[ "$scan_mode" == "--staged" ]]; then
    git diff --cached --name-only --diff-filter=ACMR
  else
    git diff --name-only --diff-filter=ACMR "$scan_range"
  fi
}

collect_added_lines() {
  if [[ "$scan_mode" == "--staged" ]]; then
    git diff --cached --no-color --unified=0
  else
    git log --format=%H "$scan_range" | while read -r sha; do
      git show --format= --no-color --unified=0 "$sha"
    done
  fi | awk '
    /^\+\+\+ / { next }
    /^\+/ { print substr($0, 2) }
  '
}

changed_paths="$(collect_changed_paths || true)"
if [[ -z "${changed_paths}" ]]; then
  exit 0
fi

blocked=()
while IFS= read -r path; do
  [[ -z "$path" ]] && continue
  if is_blocked_path "$path"; then
    blocked+=("$path")
  fi
done <<<"$changed_paths"

if (( ${#blocked[@]} > 0 )); then
  echo "Blocked commit: secret-bearing file path detected." >&2
  printf ' - %s\n' "${blocked[@]}" >&2
  echo "Keep these files local only; do not commit them." >&2
  exit 1
fi

added_lines="$(collect_added_lines || true)"
if [[ -z "${added_lines}" ]]; then
  exit 0
fi

declare -a hits=()
check_pattern() {
  local label="$1"
  local regex="$2"
  if printf '%s\n' "$added_lines" | LC_ALL=C grep -Eq -- "$regex"; then
    hits+=("$label")
  fi
}

check_pattern "Supabase PAT token" 'sbp_[A-Za-z0-9]{20,}'
check_pattern "OpenAI API key" 'sk-[A-Za-z0-9-]{20,}'
check_pattern "GitHub personal token" 'ghp_[A-Za-z0-9]{20,}'
check_pattern "AWS access key id" 'AKIA[0-9A-Z]{16}'
check_pattern "Slack token" 'xox[baprs]-[A-Za-z0-9-]{10,}'
check_pattern "Private key block" '-----BEGIN [A-Z ]*PRIVATE KEY-----'
check_pattern "Supabase service role assignment" 'SUPABASE_SERVICE_ROLE_KEY[[:space:]]*[:=][[:space:]]*[^[:space:]]+'
check_pattern "OpenAI key assignment" 'OPENAI_API_KEY[[:space:]]*[:=][[:space:]]*["'"'"']?sk-[A-Za-z0-9-]{20,}'
check_pattern "Raw password marker" 'db pass[[:space:]]*-[[:space:]]*[^[:space:]]+'

if (( ${#hits[@]} > 0 )); then
  echo "Blocked commit: secret-like content detected in added lines." >&2
  printf ' - %s\n' "${hits[@]}" >&2
  echo "Move secrets to local environment variables or secret managers." >&2
  exit 1
fi

exit 0
