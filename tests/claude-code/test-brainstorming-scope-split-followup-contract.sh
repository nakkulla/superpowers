#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BRAINSTORMING="$REPO_ROOT/skills/brainstorming/SKILL.md"
WRITING_PLANS="$REPO_ROOT/skills/writing-plans/SKILL.md"
EXECUTING_PLANS="$REPO_ROOT/skills/executing-plans/SKILL.md"
WORKFLOW_CONTRACT="$REPO_ROOT/docs/contracts/workflow-contract.yaml"
CONSUMERS="$REPO_ROOT/docs/contracts/consumers.yaml"

for path in "$BRAINSTORMING" "$WRITING_PLANS" "$EXECUTING_PLANS" "$WORKFLOW_CONTRACT" "$CONSUMERS"; do
  [ -f "$path" ]
done

if ! command -v rg >/dev/null 2>&1; then
  echo "ERROR: ripgrep (rg) is required for this contract test." >&2
  echo "Install ripgrep, then rerun $0." >&2
  exit 1
fi

rg -q 'name: superpowers-workflow' "$WORKFLOW_CONTRACT"
rg -q 'type: semantic' "$WORKFLOW_CONTRACT"
rg -q 'runtime_loading: false' "$WORKFLOW_CONTRACT"
rg -q 'scope_split_followup:' "$WORKFLOW_CONTRACT"
rg -q 'required_metadata:' "$WORKFLOW_CONTRACT"
rg -q -- '- origin' "$WORKFLOW_CONTRACT"
rg -q -- '- source_spec_id' "$WORKFLOW_CONTRACT"
rg -q -- '- source_parent' "$WORKFLOW_CONTRACT"
rg -q -- '- scope_relation' "$WORKFLOW_CONTRACT"
rg -q -- '- spec_policy' "$WORKFLOW_CONTRACT"
rg -q 'origin: brainstorming_scope_split' "$WORKFLOW_CONTRACT"
rg -q 'scope_relation: follow_up' "$WORKFLOW_CONTRACT"
rg -q 'spec_policy: future_brainstorming_required' "$WORKFLOW_CONTRACT"
rg -q 'forbidden_pre_spec_fields:' "$WORKFLOW_CONTRACT"
for forbidden in spec_id has:spec reviewed:spec spec_content_hash spec_reviewed_at_sha artifact_links review_evidence execution_lane quick_edit quick_edit_decision_reason quick_edit_decided_by skill_workflow skill_workflow_reason; do
  rg -q -- "- $forbidden" "$WORKFLOW_CONTRACT"
done

rg -q 'main scope plus related follow-ups' "$BRAINSTORMING"
rg -q 'description-only follow-up Beads issues' "$BRAINSTORMING"
rg -q 'Do not write separate follow-up specs in the same brainstorming run' "$BRAINSTORMING"
rg -q 'origin=brainstorming_scope_split' "$BRAINSTORMING"
rg -q 'source_spec_id=<main spec path>' "$BRAINSTORMING"
rg -q 'source_parent=<main parent bead id>' "$BRAINSTORMING"
rg -q 'scope_relation=follow_up' "$BRAINSTORMING"
rg -q 'spec_policy=future_brainstorming_required' "$BRAINSTORMING"
rg -q 'forbidden pre-spec fields' "$BRAINSTORMING"
rg -q 'artifact_links.*,.*review_evidence' "$BRAINSTORMING"

rg -q 'not plan-ready' "$WRITING_PLANS"
rg -q 'spec_policy=future_brainstorming_required' "$WRITING_PLANS"
rg -q 'future brainstorming/spec gate' "$WRITING_PLANS"

rg -q 'not execution-ready' "$EXECUTING_PLANS"
rg -q 'spec_policy=future_brainstorming_required' "$EXECUTING_PLANS"
rg -q 'future brainstorming/spec workflow' "$EXECUTING_PLANS"

rg -q 'skills/brainstorming/SKILL.md' "$CONSUMERS"
rg -q 'skills/writing-plans/SKILL.md' "$CONSUMERS"
rg -q 'skills/executing-plans/SKILL.md' "$CONSUMERS"
rg -q 'tests/claude-code/test-brainstorming-v4-workflow-routing-contract.sh' "$CONSUMERS"
rg -q 'tests/claude-code/test-brainstorming-scope-split-followup-contract.sh' "$CONSUMERS"
for routing_assert in \
  vocabulary.execution_lane.allowed_values \
  vocabulary.quick_edit.allowed_values \
  vocabulary.quick_edit_decision_reason \
  vocabulary.quick_edit_decided_by.allowed_values \
  vocabulary.skill_workflow.allowed_values \
  vocabulary.skill_workflow_reason \
  vocabulary.spec_id \
  vocabulary.has:spec.source \
  vocabulary.reviewed:spec.required_metadata \
  vocabulary.spec_content_hash \
  vocabulary.spec_reviewed_at_sha \
  vocabulary.artifact_links \
  vocabulary.review_evidence; do
  rg -q -- "- $routing_assert" "$CONSUMERS"
done

echo 'PASS: brainstorming scope split follow-up contract'
