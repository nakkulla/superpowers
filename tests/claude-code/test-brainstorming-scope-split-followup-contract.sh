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
rg -q 'upstream_semantic_reference: dotfiles-v4-workflow-contract' "$WORKFLOW_CONTRACT"
rg -q 'dotfiles_runtime_only:' "$WORKFLOW_CONTRACT"
rg -q 'run_ledgers: out_of_scope' "$WORKFLOW_CONTRACT"
rg -q 'phase_markers: out_of_scope' "$WORKFLOW_CONTRACT"
rg -q 'final_markers: out_of_scope' "$WORKFLOW_CONTRACT"
! rg -q 'phase_evidence_requirements:' "$WORKFLOW_CONTRACT"
rg -q 'scope_split_followup:' "$WORKFLOW_CONTRACT"
rg -q 'required_metadata:' "$WORKFLOW_CONTRACT"
rg -q -- '- origin' "$WORKFLOW_CONTRACT"
rg -q -- '- source_spec_id' "$WORKFLOW_CONTRACT"
rg -q -- '- source_parent' "$WORKFLOW_CONTRACT"
rg -q -- '- scope_relation' "$WORKFLOW_CONTRACT"
rg -q -- '- spec_policy' "$WORKFLOW_CONTRACT"
rg -q -- '- classification' "$WORKFLOW_CONTRACT"
rg -q -- '- target_repo' "$WORKFLOW_CONTRACT"
rg -q -- '- required_action' "$WORKFLOW_CONTRACT"
rg -q -- '- human_decision_required' "$WORKFLOW_CONTRACT"
rg -q 'origin: brainstorming_scope_split' "$WORKFLOW_CONTRACT"
rg -q 'scope_relation: follow_up' "$WORKFLOW_CONTRACT"
rg -q 'spec_policy: future_brainstorming_required' "$WORKFLOW_CONTRACT"
rg -q 'dotfiles_auto_spec_intake_fields:' "$WORKFLOW_CONTRACT"
rg -q 'auto_spec_eligible: not_required' "$WORKFLOW_CONTRACT"
rg -q 'missing_spec_evidence: not_required' "$WORKFLOW_CONTRACT"
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
rg -q 'classification=<scope_split_followup\|cross_repo_followup\|human_followup>' "$BRAINSTORMING"
rg -q 'target_repo=<owner/repo or tracker repo>' "$BRAINSTORMING"
rg -q 'required_action=<future work request>' "$BRAINSTORMING"
rg -q 'human_decision_required=yes\|no' "$BRAINSTORMING"
rg -q 'Optional evidence fields' "$BRAINSTORMING"
rg -q 'source_artifact=<upstream artifact path or URL>' "$BRAINSTORMING"
rg -q 'source_summary=<short summary>' "$BRAINSTORMING"
rg -q 'component=<component name>' "$BRAINSTORMING"
rg -q 'target_paths=<known repo-relative paths>' "$BRAINSTORMING"
rg -q 'acceptance_notes=<known acceptance notes>' "$BRAINSTORMING"
rg -q 'verification_notes=<known verification notes>' "$BRAINSTORMING"
rg -q 'Do not guess `target_paths`' "$BRAINSTORMING"
rg -q 'auto_spec_eligible.*missing_spec_evidence' "$BRAINSTORMING"
rg -q 'not required for Superpowers `brainstorming` scope-split follow-ups' "$BRAINSTORMING"
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
  vocabulary.quick_edit_label \
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
  vocabulary.review_evidence \
  dotfiles_runtime_only; do
  rg -q -- "- $routing_assert" "$CONSUMERS"
done

echo 'PASS: brainstorming scope split follow-up contract'
