#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BRAINSTORMING="$REPO_ROOT/skills/brainstorming/SKILL.md"
WRITING_PLANS="$REPO_ROOT/skills/writing-plans/SKILL.md"
EXECUTING_PLANS="$REPO_ROOT/skills/executing-plans/SKILL.md"

for path in "$BRAINSTORMING" "$WRITING_PLANS" "$EXECUTING_PLANS"; do
  [ -f "$path" ]
done

rg -q '## skill-related Classification' "$BRAINSTORMING"
rg -q 'skill_related=yes\|no' "$BRAINSTORMING"
rg -q 'skill_related_reason=<short reason>' "$BRAINSTORMING"
rg -q 'quick_edit_decision_reason=<short reason>' "$BRAINSTORMING"
rg -q 'quick_edit_decided_by=brainstorming' "$BRAINSTORMING"
rg -q 'execution_lane=plan\|quick_edit' "$BRAINSTORMING"
rg -q 'Set `execution_lane=quick_edit` only when `quick_edit=yes`' "$BRAINSTORMING"
rg -q 'Never create new `execution_lane=skill_eval_fast_path` output' "$BRAINSTORMING"
rg -q 'Do not invoke `skill-creator` directly from brainstorming' "$BRAINSTORMING"

! rg -q 'Record `skill_eval_fast_path` as the selected execution lane|execution_lane=skill_eval_fast_path|skill_eval_fast_path Preflight Exception' "$BRAINSTORMING" "$WRITING_PLANS" "$EXECUTING_PLANS"

rg -q '## Skill-related Plan Hard Gate' "$WRITING_PLANS"
rg -q 'This plan is skill-related' "$WRITING_PLANS"
rg -q 'plan completeness gate' "$WRITING_PLANS"
rg -q 'not an execution-lane decision' "$WRITING_PLANS"
rg -q 'Use superpowers:writing-skills' "$WRITING_PLANS"
rg -q 'Use skill-creator when creating a new skill, changing skill metadata, restructuring skill resources, changing trigger/routing behavior, or doing eval-driven skill iteration' "$WRITING_PLANS"

rg -q '## Skill-related Task Router' "$EXECUTING_PLANS"
rg -q 'before editing' "$EXECUTING_PLANS"
rg -q 'skill-related` label' "$EXECUTING_PLANS"
rg -q 'skill_related=yes' "$EXECUTING_PLANS"
rg -q 'task touches a skill artifact path' "$EXECUTING_PLANS"
rg -q 'REQUIRED SUB-SKILL: superpowers:writing-skills' "$EXECUTING_PLANS"
rg -q 'ALSO REQUIRED: skill-creator' "$EXECUTING_PLANS"
rg -q 'does not skip plan authoring' "$EXECUTING_PLANS"

echo 'PASS: brainstorming skill-related quick_edit routing contract'
