#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BRAINSTORMING="$REPO_ROOT/skills/brainstorming/SKILL.md"
WRITING_PLANS="$REPO_ROOT/skills/writing-plans/SKILL.md"
EXECUTING_PLANS="$REPO_ROOT/skills/executing-plans/SKILL.md"
WORKFLOW_CONTRACT="$REPO_ROOT/docs/contracts/workflow-contract.yaml"

for path in "$BRAINSTORMING" "$WRITING_PLANS" "$EXECUTING_PLANS" "$WORKFLOW_CONTRACT"; do
  [ -f "$path" ]
done

if ! command -v rg >/dev/null 2>&1; then
  echo "ERROR: ripgrep (rg) is required for this contract test." >&2
  echo "Install ripgrep, then rerun $0." >&2
  exit 1
fi

rg -q '## skill_workflow Classification' "$BRAINSTORMING"
rg -q 'quick_edit=yes\|no' "$BRAINSTORMING"
rg -q 'quick_edit_decision_reason=<short reason>' "$BRAINSTORMING"
rg -q 'quick_edit_decided_by=brainstorming' "$BRAINSTORMING"
rg -q 'execution_lane=plan\|quick_edit' "$BRAINSTORMING"
rg -q 'skill_workflow=none\|writing_skills\|skill_creator' "$BRAINSTORMING"
rg -q 'skill_workflow_reason=<short reason>' "$BRAINSTORMING"
rg -q 'Set `execution_lane=quick_edit` only when `quick_edit=yes`' "$BRAINSTORMING"
rg -q 'execution_lane=quick_edit` as the source of truth; the `quick_edit` label is a mirror/index label' "$BRAINSTORMING"
rg -q 'metadata.execution_lane=quick_edit' "$BRAINSTORMING" "$WORKFLOW_CONTRACT"
rg -q 'standalone `quick_edit` label is stale mirror drift' "$BRAINSTORMING"
rg -q 'A `quick_edit` label without `metadata.execution_lane=quick_edit` is stale mirror drift' "$BRAINSTORMING"
rg -q 'quick_edit_label:' "$WORKFLOW_CONTRACT"
rg -q 'source: metadata.execution_lane=quick_edit' "$WORKFLOW_CONTRACT"
rg -q 'Only `execution_lane=quick_edit` can skip a separate plan' "$BRAINSTORMING"
rg -q 'Do not invoke `writing-plans`, `executing-plans`, `writing-skills`, or `skill-creator` automatically' "$BRAINSTORMING"
rg -q 'Then ask the user only about the written spec' "$BRAINSTORMING"
rg -q 'Do not bundle spec approval with the next workflow' "$BRAINSTORMING"
rg -q '`execution_lane=plan` is handoff metadata only' "$BRAINSTORMING"
rg -q 'separate explicit user request' "$BRAINSTORMING"

rg -q 'SPEC_CONTENT_HASH=.*git hash-object <spec-path>' "$BRAINSTORMING"
rg -q 'SPEC_REVIEWED_AT_SHA=.*git rev-parse HEAD' "$BRAINSTORMING"
rg -q 'spec_id=<path>` as the source of truth; `has:spec` is a mirror/index label' "$BRAINSTORMING"

rg -q '## skill_workflow Plan Completeness Gate' "$WRITING_PLANS"
rg -q 'skill_workflow=writing_skills\|skill_creator' "$WRITING_PLANS"
rg -q 'skill_workflow_reason=<short reason>' "$WRITING_PLANS"
rg -q 'execution_lane=plan\|quick_edit' "$WRITING_PLANS"
rg -q 'plan completeness gate, not an execution-lane decision' "$WRITING_PLANS"
rg -q 'Only `execution_lane=quick_edit` can skip separate plan authoring' "$WRITING_PLANS"
rg -q 'REQUIRED SUB-SKILL: Use superpowers:writing-skills' "$WRITING_PLANS"
rg -q 'ALSO REQUIRED: Use skill-creator when creating a new skill, changing skill metadata, restructuring skill resources, changing trigger/routing behavior, or doing eval-driven skill iteration' "$WRITING_PLANS"
rg -q 'plan_content_hash=<git hash-object <plan-path>>' "$WRITING_PLANS"
rg -q 'plan_reviewed_at_sha=<repo HEAD covered by the passing plan review>' "$WRITING_PLANS"

rg -q '## skill_workflow Task Router' "$EXECUTING_PLANS"
rg -q 'Before editing for each task, classify the task' "$EXECUTING_PLANS"
rg -q 'Use the linked issue, spec, or plan `skill_workflow` as the first input' "$EXECUTING_PLANS"
rg -q 'A task requires `skill_workflow=writing_skills`' "$EXECUTING_PLANS"
rg -q 'A task requires `skill_workflow=skill_creator`' "$EXECUTING_PLANS"
rg -q 'REQUIRED SUB-SKILL: superpowers:writing-skills' "$EXECUTING_PLANS"
rg -q 'ALSO REQUIRED: skill-creator' "$EXECUTING_PLANS"
rg -q 'does not skip plan authoring' "$EXECUTING_PLANS"
rg -q 'plan_content_hash' "$EXECUTING_PLANS"
rg -q 'plan_reviewed_at_sha' "$EXECUTING_PLANS"
rg -q 'impl_reviewed_at_sha=<reviewed implementation HEAD>' "$EXECUTING_PLANS"
rg -q 'impl_reviewed_diff_range=<base>..<head>' "$EXECUTING_PLANS"

! rg -q 'Record `skill_eval_fast_path` as the selected execution lane|skill_eval_fast_path Preflight Exception|`skill_eval_fast_path`: record|execution_lane=skill_eval_fast_path.*→' "$BRAINSTORMING" "$WRITING_PLANS" "$EXECUTING_PLANS"
! rg -q '승인\+plan 작성|Approve \+ write plan \(Recommended\)|proceed to the next step' "$BRAINSTORMING"
! rg -q '## Skill-related|This plan is skill-related|skill-related` label|records `skill_related=yes`' "$BRAINSTORMING" "$WRITING_PLANS" "$EXECUTING_PLANS"
legacy_output="$(rg -n 'skill_related|skill-related|skill_creator_required|spec_reviewed_sha|spec_review_base_sha|spec_freshness|spec_stale_reason' "$BRAINSTORMING" "$WRITING_PLANS" "$EXECUTING_PLANS" || true)"
if [ -n "$legacy_output" ]; then
  while IFS= read -r line; do
    case "$line" in
      *'Do not create canonical v4 metadata named'*|*'Do not store'*|*'Compatibility warning: do not create new canonical v4 metadata named'*) ;;
      *)
        echo "Unexpected active legacy metadata guidance: $line" >&2
        exit 1
        ;;
    esac
  done <<< "$legacy_output"
fi

echo 'PASS: brainstorming v4 workflow routing contract'
