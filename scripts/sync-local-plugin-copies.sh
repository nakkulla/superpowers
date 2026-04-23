#!/usr/bin/env bash
#
# sync-local-plugin-copies.sh — sync this repo's tracked files to installed
# Claude/plugin copies and verify that Codex reads this repo directly.
#
# Usage:
#   sync-local-plugin-copies.sh copy
#   sync-local-plugin-copies.sh verify
#   sync-local-plugin-copies.sh after-commit
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DEFAULT_REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

REPO_ROOT="${SUPERPOWERS_REPO_ROOT:-$DEFAULT_REPO_ROOT}"
GITHUB_MIRROR="${SUPERPOWERS_GITHUB_MIRROR:-$HOME/GitHub/superpowers}"
CLAUDE_MARKETPLACE_ROOT="${SUPERPOWERS_CLAUDE_MARKETPLACE_ROOT:-$HOME/.claude/plugins/marketplaces/superpowers-custom}"
CLAUDE_CACHE_ROOT="${SUPERPOWERS_CLAUDE_CACHE_ROOT:-$HOME/.claude/plugins/cache/superpowers-custom}"
CLAUDE_VERSION_PARENT="${SUPERPOWERS_CLAUDE_VERSION_PARENT:-$HOME/.claude/plugins/cache/superpowers-custom/superpowers}"
CODEX_SKILLS_LINK="${SUPERPOWERS_CODEX_SKILLS_LINK:-$HOME/.agents/skills/superpowers}"

declare -a COPY_TARGET_LABELS=()
declare -a COPY_TARGET_PATHS=()

usage() {
  cat <<'EOF'
Usage: sync-local-plugin-copies.sh copy | verify | after-commit

  copy          Sync tracked working-tree files to installed Claude/plugin copies
  verify        Verify installed Claude/plugin copies and Codex link status
  after-commit  Confirm direct-link Codex setup (no-op when healthy)

Environment overrides:
  SUPERPOWERS_REPO_ROOT
  SUPERPOWERS_GITHUB_MIRROR
  SUPERPOWERS_CLAUDE_MARKETPLACE_ROOT
  SUPERPOWERS_CLAUDE_CACHE_ROOT
  SUPERPOWERS_CLAUDE_VERSION_PARENT
  SUPERPOWERS_CODEX_SKILLS_LINK
EOF
}

require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "error: required command not found: $cmd" >&2
    exit 1
  fi
}

canonical_path() {
  python3 - "$1" <<'PY'
import os
import sys

print(os.path.realpath(sys.argv[1]))
PY
}

same_realpath() {
  local left="$1"
  local right="$2"
  [[ "$(canonical_path "$left")" == "$(canonical_path "$right")" ]]
}

ensure_repo_root() {
  if ! git -C "$REPO_ROOT" rev-parse --show-toplevel >/dev/null 2>&1; then
    echo "error: REPO_ROOT is not a git repository: $REPO_ROOT" >&2
    exit 1
  fi
}

repo_is_dirty() {
  [[ -n "$(git -C "$REPO_ROOT" status --short)" ]]
}

git_worktree_is_dirty() {
  local path="$1"
  [[ -n "$(git -C "$path" status --short)" ]]
}

add_copy_target_if_present() {
  local label="$1"
  local path="$2"

  if [[ ! -e "$path" ]]; then
    return 0
  fi

  if same_realpath "$path" "$REPO_ROOT"; then
    return 0
  fi

  COPY_TARGET_LABELS+=("$label")
  COPY_TARGET_PATHS+=("$path")
}

discover_copy_targets() {
  COPY_TARGET_LABELS=()
  COPY_TARGET_PATHS=()

  add_copy_target_if_present "github-mirror" "$GITHUB_MIRROR"
  add_copy_target_if_present "claude-marketplace" "$CLAUDE_MARKETPLACE_ROOT"
  add_copy_target_if_present "claude-cache" "$CLAUDE_CACHE_ROOT"

  if [[ -d "$CLAUDE_VERSION_PARENT" ]]; then
    local version_dir
    while IFS= read -r version_dir; do
      add_copy_target_if_present "claude-cache-version:$(basename "$version_dir")" "$version_dir"
    done < <(find "$CLAUDE_VERSION_PARENT" -mindepth 1 -maxdepth 1 -type d | sort)
  fi
}

build_snapshot() {
  local snapshot
  snapshot="$(mktemp -d)"
  git -C "$REPO_ROOT" ls-files -z | rsync -a --from0 --files-from=- "$REPO_ROOT/" "$snapshot/"
  printf '%s\n' "$snapshot"
}

sync_snapshot_to_target() {
  local snapshot="$1"
  local label="$2"
  local target="$3"
  local -a rsync_args

  rsync_args=(-a --delete --exclude '.git/')

  if [[ "$label" == "claude-cache" ]]; then
    rsync_args+=(--exclude 'superpowers/')
  fi

  mkdir -p "$target"
  rsync "${rsync_args[@]}" "$snapshot/" "$target/"
  echo "SYNCED  [$label] $target"
}

verify_snapshot_against_target() {
  local snapshot="$1"
  local label="$2"
  local target="$3"
  local diff_output
  local -a rsync_args

  rsync_args=(-ain --delete --exclude '.git/')

  if [[ "$label" == "claude-cache" ]]; then
    rsync_args+=(--exclude 'superpowers/')
  fi

  if [[ ! -e "$target" ]]; then
    echo "SKIP    [$label] missing: $target"
    return 0
  fi

  diff_output="$(rsync "${rsync_args[@]}" "$snapshot/" "$target/" || true)"
  if [[ -n "$diff_output" ]]; then
    diff_output="$(printf '%s\n' "$diff_output" | grep -vF '.d..t.... ' | sed '/^$/d' || true)"
  fi
  if [[ -z "$diff_output" ]]; then
    echo "OK      [$label] $target"
    return 0
  fi

  echo "DRIFT   [$label] $target"
  printf '%s\n' "$diff_output" | sed 's/^/  /'
  return 1
}

verify_codex_link_status() {
  if [[ ! -e "$CODEX_SKILLS_LINK" ]]; then
    echo "SKIP    [codex] missing skills link: $CODEX_SKILLS_LINK"
    return 0
  fi

  if same_realpath "$CODEX_SKILLS_LINK" "$REPO_ROOT/skills"; then
    echo "OK      [codex] skills link points to repo: $CODEX_SKILLS_LINK"
    return 0
  fi

  echo "DRIFT   [codex] skills link points elsewhere"
  echo "        link path: $CODEX_SKILLS_LINK"
  echo "        resolved:  $(canonical_path "$CODEX_SKILLS_LINK")"
  echo "        expected:  $(canonical_path "$REPO_ROOT/skills")"
  return 1
}

cmd_copy() {
  ensure_repo_root
  require_cmd git
  require_cmd rsync
  require_cmd python3

  discover_copy_targets
  if [[ "${#COPY_TARGET_PATHS[@]}" -eq 0 ]]; then
    echo "No installed Claude/plugin copy targets found."
    echo "Nothing to sync."
    return 0
  fi

  local snapshot
  snapshot="$(build_snapshot)"
  trap 'rm -rf "$snapshot"' RETURN

  local i
  for i in "${!COPY_TARGET_PATHS[@]}"; do
    sync_snapshot_to_target "$snapshot" "${COPY_TARGET_LABELS[$i]}" "${COPY_TARGET_PATHS[$i]}"
  done

  echo ""
  echo "Done. Run '$0 verify' to confirm parity."
  echo "Codex should usually read this repo directly via $CODEX_SKILLS_LINK."
}

cmd_verify() {
  ensure_repo_root
  require_cmd git
  require_cmd rsync
  require_cmd python3

  discover_copy_targets

  local snapshot failures=0
  snapshot="$(build_snapshot)"
  trap 'rm -rf "$snapshot"' RETURN

  local i
  if [[ "${#COPY_TARGET_PATHS[@]}" -eq 0 ]]; then
    echo "No installed Claude/plugin copy targets found."
  else
    for i in "${!COPY_TARGET_PATHS[@]}"; do
      if ! verify_snapshot_against_target "$snapshot" "${COPY_TARGET_LABELS[$i]}" "${COPY_TARGET_PATHS[$i]}"; then
        failures=$((failures + 1))
      fi
    done
  fi

  if ! verify_codex_link_status; then
    failures=$((failures + 1))
  fi

  if [[ "$failures" -gt 0 ]]; then
    echo ""
    echo "Verification found $failures issue(s)."
    return 1
  fi

  echo ""
  echo "All checked targets are in sync."
}

cmd_after_commit() {
  ensure_repo_root
  require_cmd git

  if [[ -e "$CODEX_SKILLS_LINK" ]] && same_realpath "$CODEX_SKILLS_LINK" "$REPO_ROOT/skills"; then
    echo "OK      [codex] direct repo link already active: $CODEX_SKILLS_LINK"
    return 0
  fi

  echo "error: Codex is not reading this repo directly. Re-run install-codex.sh to restore the direct skills link." >&2
  exit 1
}

case "${1:-}" in
  copy)
    cmd_copy
    ;;
  verify)
    cmd_verify
    ;;
  after-commit)
    cmd_after_commit
    ;;
  --help|-h|"")
    usage
    ;;
  *)
    echo "error: unknown command '${1:-}'" >&2
    echo "" >&2
    usage >&2
    exit 1
    ;;
esac
