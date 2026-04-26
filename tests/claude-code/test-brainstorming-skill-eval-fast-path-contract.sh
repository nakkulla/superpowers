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
rg -q 'Select execution lane' "$SKILL"
rg -q 'Invoke skill-creator eval loop' "$SKILL"

echo 'PASS: brainstorming skill eval fast path contract'
