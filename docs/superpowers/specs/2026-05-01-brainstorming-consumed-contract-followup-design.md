# Brainstorming Consumed Contract and Follow-up Metadata Design
Parent bead: superpowers-rd0
Source artifact: nakkulla/dotfiles `docs/superpowers/specs/2026-04-30-v4-followup-auto-spec-intake-design.md`
Source parent: dotfiles-6f7h

**Status:** Draft for review  
**Date:** 2026-05-01

## Summary

Align Superpowers' `brainstorming` semantic consumer with the dotfiles v4 workflow contract by importing only the contract semantics that Superpowers actually consumes or emits. The change should make `metadata.execution_lane=quick_edit` the canonical source for quick-edit execution, keep the `quick_edit` label as a mirror/index label, and define a lightweight follow-up evidence model for scope-split follow-ups created by `brainstorming`.

This is not a full byte-for-byte mirror of the dotfiles runtime contract. Superpowers does not own `bd-ralph-v4` or `pr-review-v4` runtime ledgers, phase markers, or auto-spec intake execution. The design uses the dotfiles contract as the upstream semantic reference and records a Superpowers-local consumed subset.

## Problem

The dotfiles v4 contract now treats `metadata.execution_lane` as the source of truth for execution lane decisions and treats labels such as `quick_edit` as mirrors. The `superpowers:brainstorming` skill is the semantic consumer that originally classifies quick-edit work, so it must follow the same contract.

Current Superpowers state is partially aligned:

- `skills/brainstorming/SKILL.md` already says `execution_lane=quick_edit` is the source of truth and `quick_edit` is a mirror label.
- `tests/claude-code/test-brainstorming-v4-workflow-routing-contract.sh` already checks several v4 routing rules.
- `docs/contracts/workflow-contract.yaml` remains a compact `contract` / `vocabulary` contract rather than the dotfiles full v4 contract shape.
- Superpowers does not yet describe the consumed subset of dotfiles mirror-label and follow-up evidence semantics clearly enough to prevent future drift.

The gap is not simply missing text in `brainstorming`; it is an ownership boundary issue. Superpowers should consume the relevant dotfiles semantics without importing dotfiles-only runtime details.

## Goals

1. Define the dotfiles v4 contract as the upstream semantic reference for shared workflow vocabulary.
2. Add or clarify only the Superpowers-consumed subset of that contract.
3. Keep `metadata.execution_lane=quick_edit` canonical and `quick_edit` as a mirror/index label.
4. Prevent standalone `quick_edit` labels from being treated as execution-lane evidence.
5. Define minimum follow-up evidence for `brainstorming` scope-split follow-up creation, using dotfiles follow-up evidence as a reference without requiring auto-spec-intake completeness.
6. Update active guidance and contract tests so future changes preserve the consumed-subset boundary.
7. Record this work as plan-lane skill-contract work: `quick_edit=no`, `execution_lane=plan`, `skill_workflow=skill_creator`.

## Non-goals

- Do not copy the full dotfiles `docs/contracts/workflow-contract.yaml` into Superpowers.
- Do not add dotfiles-owned `bd-ralph-v4` or `pr-review-v4` phase lists, run-ledger schemas, optional evidence JSON schemas, final markers, or migration tables unless a Superpowers consumer actually needs them.
- Do not add Superpowers runtime loading of contract YAML.
- Do not rewrite historical specs, plans, eval artifacts, or reviews solely to remove legacy wording.
- Do not make every small skill change a quick edit.
- Do not create auto-spec intake behavior in Superpowers `brainstorming`.
- Do not add `spec_id`, `reviewed:spec`, `execution_lane`, `quick_edit`, or `skill_workflow` metadata to description-only scope-split follow-ups before their own future spec gate.

## Design

### 1. Upstream contract boundary

Superpowers should treat the dotfiles v4 workflow contract as an upstream semantic reference, not as a runtime dependency. The Superpowers contract should keep its local `contract.type=semantic` and `runtime_loading=false` stance.

The implementation should update `docs/contracts/workflow-contract.yaml` to make the consumed subset explicit. It may keep the current compact shape, but it should include enough structure to express:

- canonical metadata keys;
- mirror label source rules;
- review evidence fields;
- scope-split follow-up minimum metadata;
- the fact that dotfiles runtime-only fields are intentionally out of scope.

The contract should mention dotfiles as the upstream basis in comments or descriptions, but Superpowers remains the owner of its local semantic contract and tests.

### 2. Consumed metadata and mirror labels

The Superpowers consumed subset should cover these canonical metadata keys when the corresponding workflow emits or consumes them:

```text
spec_id
metadata.plan
metadata.handoff
metadata.execution_lane
metadata.skill_workflow
metadata.quick_edit
spec_content_hash
spec_reviewed_at_sha
plan_content_hash
plan_reviewed_at_sha
impl_reviewed_at_sha
impl_reviewed_diff_range
```

`metadata.quick_edit=yes|no` remains a brainstorming decision flag that records whether the work qualified for the quick-edit lane. It does not replace the execution-lane source of truth. The canonical lane source is always `metadata.execution_lane=plan|quick_edit`, and `metadata.execution_lane=quick_edit` is the only source for the `quick_edit` mirror label.

The contract shape should represent mirror labels separately from metadata vocabulary. If Superpowers keeps the compact `vocabulary` structure, add an explicit mirror-label vocabulary entry rather than redefining `quick_edit`:

```yaml
vocabulary:
  quick_edit:
    kind: metadata
    allowed_values: [yes, no]
  quick_edit_label:
    kind: mirror_label
    label: quick_edit
    source: metadata.execution_lane=quick_edit
```

If implementation instead introduces a `labels.mirror` section matching the dotfiles shape, the equivalent mapping is:

```yaml
labels:
  mirror:
    quick_edit:
      source: metadata.execution_lane=quick_edit
```

The implementation may choose either contract shape, but tests must assert the semantic mapping exactly. Do not redefine `quick_edit` itself as both metadata and label.

Other mirror label rules should be explicit:

```text
has:spec    <- spec_id
has:plan    <- metadata.plan
has:handoff <- metadata.handoff
quick_edit  <- metadata.execution_lane=quick_edit
```

Rules:

1. Mirror labels are search/index/UX state, not canonical evidence.
2. A `quick_edit` label without `metadata.execution_lane=quick_edit` is stale mirror drift.
3. Execution workflows must not select quick-edit execution from a standalone label.
4. `brainstorming` may add a `quick_edit` label only as a mirror after it records or creates `execution_lane=quick_edit` metadata.
5. `execution_lane=plan` is handoff metadata only; it does not authorize same-turn plan writing or execution.
6. `skill_workflow` is a required skill-edit discipline classification, not a label and not a plan-skip authority.

### 3. `brainstorming` guidance alignment

Update `skills/brainstorming/SKILL.md` only where needed to make the consumed contract unambiguous:

- State that `metadata.execution_lane=quick_edit` is the source of truth for quick-edit execution.
- State that `quick_edit` label-only evidence is stale mirror drift.
- In the pre-spec quick-edit exception, require any standalone execution issue to keep metadata and the mirror label aligned.
- In the reviewed-spec handoff, record `metadata.quick_edit=yes|no`, `quick_edit_decision_reason`, `quick_edit_decided_by=brainstorming`, `metadata.execution_lane=plan|quick_edit`, `metadata.skill_workflow`, and `skill_workflow_reason` on the parent Bead. Use the literal `quick_edit` label name only when discussing the mirror label derived from `metadata.execution_lane=quick_edit`.
- Preserve the stop-after-spec boundary: `brainstorming` must not invoke `writing-plans`, `executing-plans`, `writing-skills`, or `skill-creator` automatically after handoff.

This alignment should be minimal because the current skill already contains much of the target behavior. The implementation should prefer tightening ambiguous wording and adding missing follow-up criteria over broad rewrites.

### 4. Scope-split follow-up creation criteria

When `brainstorming` discovers related work outside the approved main spec, it should create durable follow-up Beads only during final handoff after the user approves the main written spec. The follow-up should be description-only and should require its own future brainstorming/spec gate.

Use the dotfiles follow-up evidence contract as a reference, but extend the existing Superpowers scope-split schema instead of replacing it.

The current Superpowers scope-split contract already requires these pre-spec fields:

```text
origin=brainstorming_scope_split
source_spec_id stores the main spec repo-relative path
source_parent stores the main parent Bead id
scope_relation=follow_up
spec_policy=future_brainstorming_required
```

Those existing fields remain mandatory. This spec adds a small dotfiles-derived evidence extension for durable follow-up creation. Required fields for a newly created durable scope-split follow-up become the existing required fields above plus:

```text
classification
target_repo
required_action
human_decision_required
```

Field meanings:

- `classification`: the follow-up class, such as `scope_split_followup`, `cross_repo_followup`, or `human_followup`.
- `target_repo`: the repository/tracker that owns the future work.
- `required_action`: the requested future work in wording a later spec author can understand.
- `human_decision_required`: `yes` when a policy/product/workflow choice is required before execution, otherwise `no`.

Migration and compatibility rules:

1. Do not remove or rename the existing `origin`, `source_spec_id`, `source_parent`, `scope_relation`, or `spec_policy` fields.
2. Existing tests for the original scope-split schema should continue to pass after their assertions are extended.
3. Existing follow-up Beads created before this spec are not retroactively invalid just because they lack the new dotfiles-derived evidence fields.
4. New `brainstorming` follow-ups created after implementation should include the extended required fields when a durable Beads issue is created.
5. If `target_repo` or `required_action` cannot be determined, do not create a durable follow-up; leave a proposal or ask for clarification according to the existing cross-repo follow-up policy.

Optional evidence fields that should be recorded when known, but must not block follow-up creation when unknown:

```text
source_artifact
source_summary
component
target_paths
acceptance_notes
verification_notes
```

Rules:

1. Do not guess `target_paths`; record them only when concrete and reliable.
2. If optional evidence is missing, describe the gap in prose and state that future brainstorming/spec work is required.
3. Create the follow-up in the target tracker repo when available. If the target repo has no tracker, leave a proposal/pointer instead of creating it in the wrong repo.
4. Preserve provenance with a `discovered-from` dependency when supported.
5. Do not add pre-spec execution/review fields to these follow-ups.

Forbidden pre-spec fields on scope-split follow-ups remain:

```text
spec_id
has:spec
reviewed:spec
spec_content_hash
spec_reviewed_at_sha
artifact_links
review_evidence
execution_lane
quick_edit
quick_edit_decision_reason
quick_edit_decided_by
skill_workflow
skill_workflow_reason
```

`auto_spec_eligible` and `missing_spec_evidence` are dotfiles auto-spec-intake fields. Superpowers should not require them for `brainstorming` scope-split follow-ups unless a future reviewed spec makes Superpowers an auto-spec-intake consumer.

### 5. Contract consumer and test updates

Update `docs/contracts/consumers.yaml` to describe the new consumed subset and keep it distinct from dotfiles runtime ownership. The consumer map should say that `skills/brainstorming/SKILL.md` consumes:

- execution lane metadata;
- quick-edit mirror label semantics;
- skill workflow handoff metadata;
- spec review evidence;
- scope-split follow-up metadata.

The active contract tests should verify at least these properties:

1. Superpowers contract defines `metadata.execution_lane` values `plan` and `quick_edit`.
2. Superpowers contract keeps `metadata.quick_edit=yes|no` as a decision flag.
3. Superpowers contract defines the `quick_edit` label, via either `quick_edit_label` or `labels.mirror.quick_edit`, as a mirror of `metadata.execution_lane=quick_edit`.
4. Active `brainstorming` guidance says label-only `quick_edit` is not canonical execution evidence.
5. Active `brainstorming` guidance preserves the existing scope-split required fields and extends them with `classification`, `target_repo`, `required_action`, and `human_decision_required` for newly created durable follow-ups.
6. Active `brainstorming` guidance separates required and optional follow-up evidence fields.
7. Active `brainstorming` guidance forbids pre-spec execution/review metadata on description-only follow-ups.
8. Active Superpowers contract/tests do not require dotfiles-only run-ledger, phase-marker, or final-marker schemas.
9. Existing v4 workflow routing assertions still pass.

If current tests already cover a property, prefer extending those tests instead of creating redundant new tests. Preserve existing `tests/claude-code/test-brainstorming-*.sh` assertion coverage and exact phrases/regexes unless the implementation intentionally updates the test and active guidance together in the same change.

### 6. Eval evidence

Because this changes active skill behavior, implementation should use `superpowers:writing-skills` and `skill-creator` discipline during execution and record eval evidence.

Minimum eval scenarios:

1. **Quick-edit label drift scenario**
   - Prompt or fixture describes a Bead with a standalone `quick_edit` label but no `metadata.execution_lane=quick_edit`.
   - Expected behavior: the workflow treats it as stale mirror drift, not quick-edit execution evidence.

2. **Scope-split follow-up scenario**
   - Prompt or fixture asks `brainstorming` to split a related follow-up out of a main spec.
   - Expected behavior: after main spec approval, the follow-up uses the required minimum fields, records optional fields only when known, and does not add pre-spec execution/review metadata.

3. **Consumed-subset boundary scenario**
   - Prompt or fixture asks whether Superpowers should copy the full dotfiles workflow contract.
   - Expected behavior: the response keeps only consumed semantics and excludes dotfiles runtime-only ledgers/markers/phases.

The eval artifact should cite before/after evidence and the focused contract commands that prove the behavior.

## Implementation touchpoints

Expected touchpoints:

- `docs/contracts/workflow-contract.yaml`
- `docs/contracts/consumers.yaml`
- `skills/brainstorming/SKILL.md`
- `tests/claude-code/test-brainstorming-v4-workflow-routing-contract.sh`
- `tests/claude-code/test-brainstorming-scope-split-followup-contract.sh`
- `tests/claude-code/run-skill-tests.sh` if test names or groupings change
- `tests/claude-code/README.md` if test descriptions change
- `docs/superpowers/evals/2026-05-01-brainstorming-consumed-contract-followup-eval.md`

Implementation should inspect nearby docs and tests before editing and should avoid unrelated rewrites.

## Verification plan

Run focused contract checks after implementation:

```bash
bash tests/claude-code/test-brainstorming-v4-workflow-routing-contract.sh
bash tests/claude-code/test-brainstorming-scope-split-followup-contract.sh
bash tests/claude-code/run-skill-tests.sh fast
```

Run targeted searches to confirm active guidance:

```bash
rg -n 'metadata.execution_lane=quick_edit|quick_edit.*mirror|stale mirror drift' docs/contracts skills/brainstorming tests/claude-code
rg -n 'classification|source_parent|target_repo|required_action|human_decision_required' docs/contracts skills/brainstorming tests/claude-code
rg -n 'final_markers|ledgers|phase_evidence_requirements' docs/contracts/workflow-contract.yaml
```

The final `rg` should not require those dotfiles runtime-only sections in the Superpowers local contract unless the implementation has a specific Superpowers consumer for them.

## Acceptance criteria

1. Superpowers contract documents the consumed subset of dotfiles v4 semantics instead of copying the full dotfiles runtime contract.
2. `quick_edit` label-only evidence is explicitly rejected as canonical execution-lane evidence.
3. `brainstorming` standalone quick-edit issue guidance keeps `execution_lane=quick_edit` metadata and the mirror label aligned.
4. `brainstorming` scope-split follow-up guidance preserves the existing required schema and adds only the dotfiles-derived minimum evidence needed for new durable follow-ups.
5. Scope-split follow-ups remain pre-spec description-only work and do not receive execution/review metadata early.
6. Contract tests prove the consumed-subset boundary, quick-edit metadata-vs-label split, and scope-split schema compatibility.
7. Eval evidence exists for quick-edit label drift, scope-split follow-up creation, and consumed-subset boundary behavior.

## Brainstorming classification for this work

```text
quick_edit=no
quick_edit_decision_reason=contract and skill behavior alignment across brainstorming guidance, workflow contract docs, tests, and eval evidence needs reviewed plan execution
quick_edit_decided_by=brainstorming
execution_lane=plan
skill_workflow=skill_creator
skill_workflow_reason=the work changes skill workflow contract/routing guidance and eval-backed skill behavior, so implementation must use skill-creator discipline in addition to writing-skills
```
