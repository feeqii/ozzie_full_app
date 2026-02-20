#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

chmod +x scripts/secret_guard.sh .githooks/pre-commit
git config core.hooksPath .githooks

echo "Installed git hooks path: $(git config --get core.hooksPath)"
echo "Pre-commit secret guard is now active for this clone."
