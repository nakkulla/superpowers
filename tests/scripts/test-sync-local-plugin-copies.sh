#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="$ROOT/scripts/sync-local-plugin-copies.sh"

if [[ ! -f "$SCRIPT" ]]; then
  echo "FAIL: missing script: $SCRIPT" >&2
  exit 1
fi

if grep -Eiq 'codex|CODEX' "$SCRIPT"; then
  echo "FAIL: sync script should be Claude-only and must not check or sync Codex paths" >&2
  exit 1
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

repo="$tmp/repo"
marketplace="$tmp/marketplace/superpowers-custom"
cache="$tmp/cache/superpowers-custom"
version="$cache/superpowers/5.0.7-fork.1"

mkdir -p "$repo/skills/demo" "$repo/scripts" "$marketplace" "$cache" "$version"
cat > "$repo/skills/demo/SKILL.md" <<'SKILL'
---
name: demo
---

# Demo Skill

fresh source
SKILL
cat > "$repo/CLAUDE.md" <<'DOC'
# Demo Project
DOC
cat > "$repo/.gitignore" <<'GITIGNORE'
.DS_Store
GITIGNORE
printf 'stale\n' > "$marketplace/stale.txt"
printf 'stale\n' > "$cache/stale.txt"
printf 'stale\n' > "$version/stale.txt"
printf 'keep-version-parent\n' > "$cache/superpowers/keep.txt"

git -C "$repo" init -q
git -C "$repo" add CLAUDE.md .gitignore skills/demo/SKILL.md

SUPERPOWERS_REPO_ROOT="$repo" \
SUPERPOWERS_CLAUDE_MARKETPLACE_ROOT="$marketplace" \
SUPERPOWERS_CLAUDE_CACHE_ROOT="$cache" \
SUPERPOWERS_CLAUDE_VERSION_PARENT="$cache/superpowers" \
  bash "$SCRIPT" copy

SUPERPOWERS_REPO_ROOT="$repo" \
SUPERPOWERS_CLAUDE_MARKETPLACE_ROOT="$marketplace" \
SUPERPOWERS_CLAUDE_CACHE_ROOT="$cache" \
SUPERPOWERS_CLAUDE_VERSION_PARENT="$cache/superpowers" \
  bash "$SCRIPT" verify

for target in "$marketplace" "$cache" "$version"; do
  diff -u "$repo/skills/demo/SKILL.md" "$target/skills/demo/SKILL.md"
  [[ ! -e "$target/stale.txt" ]]
done

# The top-level cache sync must not delete versioned package directories before
# they are synced as their own targets.
[[ -f "$version/skills/demo/SKILL.md" ]]

echo "PASS: Claude plugin copy sync script"
