#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SKILL="$REPO_ROOT/skills/brainstorming/SKILL.md"

[ -f "$SKILL" ]
rg -q 'skill_eval_fast_path Preflight Exception' "$SKILL"
rg -q 'skill artifact' "$SKILL"
rg -q 'skill-creator' "$SKILL"
rg -q 'eval-first' "$SKILL"
rg -q 'writing-plans.*not required|not require.*writing-plans' "$SKILL"
rg -q 'plan-review.*skip|skip.*plan-review' "$SKILL"
rg -q 'positive trigger eval' "$SKILL"
rg -q 'negative trigger eval' "$SKILL"
rg -q 'behavior/execution eval' "$SKILL"
rg -q 'implementation-review' "$SKILL"
rg -q 'Record execution lane' "$SKILL"
rg -q 'Stop after spec handoff' "$SKILL"
rg -q 'Do not invoke `writing-plans` or `skill-creator` automatically' "$SKILL"
rg -q 'spec_reviewed_sha' "$SKILL"
rg -q 'bd update <parent-id> --add-label reviewed:spec --set-metadata spec_reviewed_sha=' "$SKILL"
rg -q 'bd update <parent-id> --remove-label reviewed:spec --unset-metadata spec_reviewed_sha' "$SKILL"

echo 'PASS: brainstorming skill eval fast path contract'
