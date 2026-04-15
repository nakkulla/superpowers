#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SYNC_SCRIPT="$REPO_ROOT/scripts/sync-local-plugin-copies.sh"

TEST_ROOT="$(mktemp -d)"
SOURCE_REPO="$TEST_ROOT/source-repo"
GITHUB_MIRROR="$TEST_ROOT/github-mirror"
CLAUDE_MARKETPLACE="$TEST_ROOT/claude-marketplace"
CLAUDE_CACHE="$TEST_ROOT/claude-cache"
CLAUDE_VERSION_PARENT="$CLAUDE_CACHE/superpowers"
CLAUDE_VERSION_DIR="$CLAUDE_VERSION_PARENT/9.9.9-test"
CODEX_CLONE="$TEST_ROOT/codex-clone"

cleanup() {
  rm -rf "$TEST_ROOT"
}
trap cleanup EXIT

pass() {
  echo "  [PASS] $1"
}

fail() {
  echo "  [FAIL] $1"
  exit 1
}

run_sync() {
  SUPERPOWERS_REPO_ROOT="$SOURCE_REPO" \
  SUPERPOWERS_GITHUB_MIRROR="$GITHUB_MIRROR" \
  SUPERPOWERS_CLAUDE_MARKETPLACE_ROOT="$CLAUDE_MARKETPLACE" \
  SUPERPOWERS_CLAUDE_CACHE_ROOT="$CLAUDE_CACHE" \
  SUPERPOWERS_CLAUDE_VERSION_PARENT="$CLAUDE_VERSION_PARENT" \
  SUPERPOWERS_CODEX_ROOT="$CODEX_CLONE" \
  "$SYNC_SCRIPT" "$@"
}

echo "=== Test: sync-local-plugin-copies.sh ==="

mkdir -p "$SOURCE_REPO/skills/demo" "$SOURCE_REPO/docs"
cat > "$SOURCE_REPO/skills/demo/SKILL.md" <<'EOF'
# Demo Skill

version one
EOF
cat > "$SOURCE_REPO/docs/readme.md" <<'EOF'
demo docs
EOF

git -C "$SOURCE_REPO" init --quiet
git -C "$SOURCE_REPO" config user.email "test@example.com"
git -C "$SOURCE_REPO" config user.name "Test User"
git -C "$SOURCE_REPO" add .
git -C "$SOURCE_REPO" commit -m "initial snapshot" --quiet

mkdir -p "$GITHUB_MIRROR" "$CLAUDE_MARKETPLACE" "$CLAUDE_CACHE" "$CLAUDE_VERSION_DIR"
git clone --quiet "$SOURCE_REPO" "$CODEX_CLONE"

cat > "$SOURCE_REPO/skills/demo/SKILL.md" <<'EOF'
# Demo Skill

version two
EOF

echo "Test 1: copy syncs tracked working-tree files..."
run_sync copy >/tmp/superpowers-sync-copy.out
for target in "$GITHUB_MIRROR" "$CLAUDE_MARKETPLACE" "$CLAUDE_CACHE" "$CLAUDE_VERSION_DIR"; do
  if grep -q "version two" "$target/skills/demo/SKILL.md"; then
    :
  else
    fail "copy did not update $target"
  fi
done
pass "copy updated all copy targets"

echo "Test 2: verify detects drift and stale files..."
echo "tampered" > "$CLAUDE_MARKETPLACE/skills/demo/SKILL.md"
echo "stale" > "$CLAUDE_CACHE/stale.txt"
if run_sync verify >/tmp/superpowers-sync-verify-drift.out 2>&1; then
  fail "verify should fail when targets drift"
fi
pass "verify failed on drift as expected"

echo "Test 3: copy repairs drift and removes stale files..."
run_sync copy >/tmp/superpowers-sync-copy-repair.out
if [[ -e "$CLAUDE_CACHE/stale.txt" ]]; then
  fail "copy did not remove stale tracked-target drift"
fi
if run_sync verify >/tmp/superpowers-sync-verify-clean.out 2>&1; then
  :
else
  cat /tmp/superpowers-sync-verify-clean.out
  fail "verify should pass after repair"
fi
pass "copy repaired drift and verify passed"

echo "Test 4: after-commit rejects dirty source repo..."
if run_sync after-commit >/tmp/superpowers-sync-after-commit-dirty.out 2>&1; then
  fail "after-commit should fail for dirty repo"
fi
pass "after-commit rejected dirty repo"

echo "Test 5: after-commit fast-forwards Codex clone after commit..."
git -C "$SOURCE_REPO" add skills/demo/SKILL.md
git -C "$SOURCE_REPO" commit -m "update demo skill" --quiet
run_sync after-commit >/tmp/superpowers-sync-after-commit-clean.out

repo_sha="$(git -C "$SOURCE_REPO" rev-parse HEAD)"
codex_sha="$(git -C "$CODEX_CLONE" rev-parse HEAD)"
if [[ "$repo_sha" != "$codex_sha" ]]; then
  fail "Codex clone SHA did not match source repo"
fi
if grep -q "version two" "$CODEX_CLONE/skills/demo/SKILL.md"; then
  pass "after-commit fast-forwarded Codex clone"
else
  fail "Codex clone content did not update"
fi

echo ""
echo "=== All sync-local-plugin-copies tests passed ==="
