# ozzie

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Security Guardrails

- Local pre-commit secret scanning is managed by `.githooks/pre-commit`.
- Install hooks for this clone:

```bash
./scripts/install-git-hooks.sh
```

- Manual scans:

```bash
# Staged changes only
./scripts/secret_guard.sh --staged

# Commits in a range
./scripts/secret_guard.sh --range origin/main...HEAD
```

- CI enforcement runs in `.github/workflows/secret-guard.yml` on pull requests and pushes.
