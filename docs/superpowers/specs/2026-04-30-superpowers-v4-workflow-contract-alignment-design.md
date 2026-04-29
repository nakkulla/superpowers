# Superpowers v4 Workflow Contract Alignment Design

Parent bead: superpowers-vhy
Source follow-up: dotfiles-38vj

## Summary

Align the active Superpowers workflow guidance with the `bd-ralph-v4` / `pr-review-v4` workflow evidence contract before v4 promotion. This is a strict v4 vocabulary alignment for active runtime guidance only.

The design updates the active Superpowers instructions that currently own brainstorming, plan writing, and plan execution routing so they use v4 canonical workflow evidence:

- `execution_lane=plan|quick_edit`
- `skill_workflow=none|writing_skills|skill_creator`
- review evidence based on content hashes plus reviewed-at SHAs
- mirror/index labels derived from metadata rather than treated as independent sources of truth

This work intentionally does not port dotfiles' `workflow-contract.yaml` helper stack into this repository. Dotfiles remains the v4 contract owner. Superpowers owns the upstream workflow vocabulary and skill guidance alignment needed before promotion.

## Goals

- Replace active Superpowers skill-routing guidance based on `skill_related` with v4 `skill_workflow` guidance.
- Keep `execution_lane=plan|quick_edit` as the only execution-lane axis.
- Keep `quick_edit` independent from `skill_workflow` and tied to `execution_lane=quick_edit`.
- Replace active review-freshness instructions that store ambiguous legacy fields with content-hash plus reviewed-at SHA evidence.
- Keep active guidance clear that `has:*` and `quick_edit` are mirror/index labels derived from metadata.
- Preserve the brainstorming completion boundary: brainstorming stops after the reviewed spec handoff and does not invoke planning or implementation automatically.
- Provide contract-test and eval evidence for the skill behavior change.

## Non-goals

- Do not promote v4 to canonical `bd-ralph` or `pr-review` routing.
- Do not add `bd-ralph-v4` or `pr-review-v4` skills to this repository.
- Do not copy dotfiles' `shared/contracts/workflow-contract.yaml` or helper library into Superpowers.
- Do not rewrite historical specs, plans, reviews, ledgers, or eval artifacts solely to rename old terminology.
- Do not perform a broad audit of every active skill in this change.
- Do not keep legacy metadata as co-equal canonical v4 evidence.

## Scope

### In scope

- `skills/brainstorming/SKILL.md`
- `skills/writing-plans/SKILL.md`
- `skills/executing-plans/SKILL.md`
- the active Claude contract test for brainstorming / writing-plans / executing-plans routing
- `tests/claude-code/run-skill-tests.sh`, if the contract test is renamed
- `tests/claude-code/README.md`, if the contract test name or semantics change
- one checked-in eval artifact documenting baseline and changed behavior

### Out of scope

- `docs/superpowers/specs/*`, `docs/superpowers/plans/*`, `docs/superpowers/reviews/*`, and existing historical evals, except for the new eval artifact created by this work
- additional active skills such as `subagent-driven-development` or `finishing-a-development-branch`
- Beads UI display changes
- dotfiles v4 contract changes

## Source of Truth

Use the dotfiles v4 final workflow contract semantics as the source of truth for this alignment. For this design, the relevant rules are:

- v4 uses `phase` as the canonical workflow unit.
- `skill-related` is not a v4 core label or metadata key.
- `skill_workflow=none|writing_skills|skill_creator` is the canonical v4 skill-routing metadata.
- `execution_lane=plan|quick_edit` is the canonical execution-lane metadata.
- `quick_edit` is a mirror/index label derived from `execution_lane=quick_edit`.
- `has:spec`, `has:plan`, and `has:handoff` are mirror/index labels derived from artifact metadata.
- review gate evidence uses content hashes plus reviewed-at SHAs.
- freshness strings are computed concepts, not canonical stored metadata.

If a current v4 canary document and the final contract semantics disagree, this Superpowers follow-up should align with the final contract semantics, not preserve the conflicting wording.

`skill_workflow` is a routing classification that records the strongest skill-edit discipline required by the work. It is not a label, not an execution lane, and not permission to skip planning. Downstream workflows use it to decide whether `superpowers:writing-skills` and/or `skill-creator` must run before skill artifact edits.

## Design

### 1. Brainstorming handoff fields

Update `skills/brainstorming/SKILL.md` so the written spec handoff records v4 fields:

```text
quick_edit=yes|no
quick_edit_decision_reason=<short reason>
quick_edit_decided_by=brainstorming
execution_lane=plan|quick_edit
skill_workflow=none|writing_skills|skill_creator
skill_workflow_reason=<short reason>
```

Rules:

- Default `execution_lane=plan`.
- Set `execution_lane=quick_edit` only when `quick_edit=yes`.
- Choose `quick_edit` from scope, ambiguity, coordination risk, and verification clarity.
- Choose `skill_workflow` from the required downstream skill-edit discipline.
- `skill_workflow=writing_skills` when work edits existing skill artifacts.
- `skill_workflow=skill_creator` when work creates a new skill, changes skill metadata, changes trigger/routing behavior, restructures resources, or performs eval-driven behavior iteration.
- `skill_workflow=none` when no skill-edit discipline is required.
- `skill_workflow` does not skip plan authoring.
- Only `execution_lane=quick_edit` can skip plan authoring.
- Brainstorming does not invoke `writing-plans`, `executing-plans`, `writing-skills`, or `skill-creator` automatically after spec approval.

For this issue, brainstorming should record:

```text
quick_edit=no
quick_edit_decision_reason=Active skill routing and workflow evidence contract changes require a written spec, review gate, plan, and eval evidence.
quick_edit_decided_by=brainstorming
execution_lane=plan
skill_workflow=skill_creator
skill_workflow_reason=The work changes active skill routing and evidence behavior and requires eval evidence.
```

### 2. Beads linkage and mirror labels

Keep Beads artifact linkage in the active guidance, but reframe mirror labels as derived indexes.

- `spec_id=<path>` is the source of truth for spec linkage.
- `metadata.plan=<path>` is the source of truth for plan linkage.
- `metadata.handoff=<path>` is the source of truth for handoff linkage.
- `execution_lane=quick_edit` is the source of truth for the `quick_edit` mirror label.
- `has:spec`, `has:plan`, `has:handoff`, and `quick_edit` must stay aligned with their source metadata.

This design does not require a new helper library in Superpowers. Active command examples may still use the existing `bd update ... --add-label ...` shape where Beads has no v4 helper available, but the surrounding instruction must identify metadata as the source of truth and labels as mirror/index evidence that must be kept aligned.

### 3. Review freshness evidence

Update active review-gate instructions to use v4 review evidence.

For spec review completion:

```text
spec_content_hash=<git hash-object <spec-path>>
spec_reviewed_at_sha=<repo HEAD covered by the passing spec review>
```

For plan review completion:

```text
plan_content_hash=<git hash-object <plan-path>>
plan_reviewed_at_sha=<repo HEAD covered by the passing plan review>
```

For implementation review completion:

```text
impl_reviewed_at_sha=<reviewed implementation HEAD>
impl_reviewed_diff_range=<base>..<head>
```

Rules:

- The reviewed-at SHA is evidence of the repository state covered by the passing review gate.
- The content hash is evidence of the reviewed artifact content.
- Do not advance these values to current `HEAD` without a new passing review.
- When reviewed content or relevant code changes, invalidate the event label and gate evidence, then re-run the gate.
- Do not store `spec_freshness`, `spec_stale_reason`, or equivalent freshness strings as canonical v4 metadata.

### 4. Writing-plans skill workflow gate

Update `skills/writing-plans/SKILL.md` so skill-edit discipline is expressed through `skill_workflow`, not `skill-related`.

For plans that touch skill artifacts, the plan header should include a v4 block like:

```text
skill_workflow=writing_skills|skill_creator
skill_workflow_reason=<short reason>
execution_lane=plan|quick_edit
```

For each task touching skill artifacts, repeat the required discipline in the task itself:

```text
REQUIRED SUB-SKILL: Use superpowers:writing-skills for skill artifact edits.
ALSO REQUIRED: Use skill-creator when creating a new skill, changing skill metadata, restructuring skill resources, changing trigger/routing behavior, or doing eval-driven skill iteration.
```

Rules:

- This is a plan completeness gate, not an execution-lane decision.
- `skill_workflow` does not make a plan optional.
- `quick_edit` remains the only plan-skip lane.
- Relevant tasks must repeat the required skill discipline so executors do not need to infer it from the header alone.

### 5. Executing-plans task router

Update `skills/executing-plans/SKILL.md` so each task is classified before editing by `skill_workflow`.

A task requires `skill_workflow=writing_skills` when it edits a skill artifact path such as:

- `skills/*/SKILL.md`
- `skills/*/references/*`
- `skills/*/scripts/*`
- `skills/*/assets/*`
- skill eval fixtures or active skill contract tests
- agent/plugin skill manifests that affect skill behavior

A task requires `skill_workflow=skill_creator` when it creates a new skill, changes skill metadata, changes trigger/routing behavior, restructures skill resources, or does eval-driven behavior iteration.

Before editing, execution must invoke the required skill-edit discipline:

```text
REQUIRED SUB-SKILL: superpowers:writing-skills
ALSO REQUIRED: skill-creator when the task changes metadata, triggers, routing behavior, resources, or eval-driven skill behavior.
```

If the linked issue, spec, or plan already records `skill_workflow`, execution should use that value as the first classification input and then validate it against task paths and task text. If they conflict, stop and reconcile before editing.

## Safety Rules

- Do not create new v4 canonical metadata named `skill_related`, `skill_creator_required`, `skill_eval_fast_path`, `spec_freshness`, `spec_stale_reason`, `spec_reviewed_sha`, or `spec_review_base_sha`.
- Do not treat `skill_workflow` as a label.
- Do not attach `quick_edit` or `has:*` labels as independent source-of-truth state.
- Do not treat skill workflow classification as permission to skip planning.
- Do not chain brainstorming into planning or execution in the same handoff.
- Do not rewrite historical artifacts just to remove old terminology.

## Validation Plan

### Contract test

Update or rename the current active contract test to a v4-focused name such as:

```text
tests/claude-code/test-brainstorming-v4-workflow-routing-contract.sh
```

If the test is renamed, update every active entry point that names the old test:

- `tests/claude-code/run-skill-tests.sh` help text
- `tests/claude-code/run-skill-tests.sh` fast `tests=(...)` array
- `tests/claude-code/README.md` current test list and description

The test must assert that active runtime guidance:

- records `skill_workflow=none|writing_skills|skill_creator`;
- records `skill_workflow_reason=<short reason>`;
- keeps `execution_lane=plan|quick_edit`;
- ties `quick_edit` to `execution_lane=quick_edit`;
- does not create new `execution_lane=skill_eval_fast_path` output;
- does not use `skill_related` as v4 canonical metadata;
- does not use `skill_creator_required` as v4 canonical metadata;
- uses `spec_content_hash` and `spec_reviewed_at_sha` for spec review evidence;
- uses `plan_content_hash` and `plan_reviewed_at_sha` for plan review evidence;
- uses `impl_reviewed_at_sha` and `impl_reviewed_diff_range` for implementation review evidence;
- keeps `writing-plans` skill workflow guidance as a plan completeness gate;
- keeps `executing-plans` skill workflow classification before edits;
- preserves the brainstorming stop-after-spec handoff boundary.

Legacy terms may appear only in negative assertions or explicit migration/compatibility warnings in active runtime guidance.

### Eval artifact

Create a checked-in eval artifact under:

```text
docs/superpowers/evals/2026-04-30-superpowers-v4-workflow-contract-alignment-eval.md
```

It should include:

- baseline evidence from the current active skills and contract test;
- changed evidence after implementation;
- at least two prompt judgments with fixed input prompts, expected fields, and pass/fail notes:
  - **Skill workflow prompt:** "A Beads issue asks to update `skills/brainstorming/SKILL.md` trigger/routing behavior and add eval evidence. Decide `quick_edit`, `execution_lane`, and `skill_workflow`." Expected: `quick_edit=no`, `execution_lane=plan`, `skill_workflow=skill_creator`, with a reason that routing/eval behavior changes require skill-creator discipline and a written spec/plan.
  - **Non-skill quick edit prompt:** "A Beads issue asks to fix a typo in `README.md` with no behavior, contract, or cross-repo impact. Decide `quick_edit`, `execution_lane`, and `skill_workflow`." Expected: `skill_workflow=none`; `execution_lane=quick_edit` is acceptable only when the answer also states that normal quick-edit criteria are clear, bounded, same-repo, and easy to verify.
- verification command output for the updated contract test;
- a short before/after conclusion showing that v4 vocabulary replaced active `skill_related` routing semantics.

The eval artifact passes when each prompt judgment includes the three fields (`quick_edit`, `execution_lane`, `skill_workflow`) plus a reason, and the reason matches the expected boundary above. A judgment fails if it uses `skill_related` or `skill_creator_required` as v4 canonical metadata, selects `execution_lane=skill_eval_fast_path`, or treats `skill_workflow` as a plan-skip lane.

### Suggested verification commands

```bash
bash tests/claude-code/test-brainstorming-v4-workflow-routing-contract.sh
rg -n 'skill_related|skill-related|spec_reviewed_sha|spec_review_base_sha|spec_freshness|spec_stale_reason|skill_creator_required' skills/brainstorming/SKILL.md skills/writing-plans/SKILL.md skills/executing-plans/SKILL.md || true
rg -n 'skill_workflow|spec_content_hash|spec_reviewed_at_sha|plan_content_hash|plan_reviewed_at_sha|impl_reviewed_diff_range|execution_lane=plan\|quick_edit' skills/brainstorming/SKILL.md skills/writing-plans/SKILL.md skills/executing-plans/SKILL.md
```

The legacy-term `rg` should have no active positive canonical instructions. Any retained match must be a negative assertion or compatibility warning.

## Acceptance Criteria

The future implementation is complete when:

1. `skills/brainstorming/SKILL.md` records v4 `skill_workflow` and v4 review evidence fields.
2. `skills/writing-plans/SKILL.md` uses `skill_workflow` for skill-edit plan completeness guidance.
3. `skills/executing-plans/SKILL.md` routes skill artifact tasks by `skill_workflow` before editing.
4. Active guidance no longer creates new `skill_related`, `skill_creator_required`, `skill_eval_fast_path`, `spec_freshness`, `spec_stale_reason`, `spec_reviewed_sha`, or `spec_review_base_sha` as v4 canonical metadata.
5. Active guidance treats `has:*` and `quick_edit` as mirror/index labels aligned to metadata.
6. `tests/claude-code/test-brainstorming-v4-workflow-routing-contract.sh` passes, or the existing contract test path is intentionally retained and updated in place.
7. The eval artifact records baseline and changed evidence.
8. If the contract test is renamed, `tests/claude-code/run-skill-tests.sh` and `tests/claude-code/README.md` reference the new name and v4 semantics.
9. Claude local plugin copies are synced and verified from the main checkout after tracked skill changes, if the implementation changes tracked skill/plugin files from main.
10. The parent bead `superpowers-vhy` is linked to this spec and receives `reviewed:spec` only after the full spec gate and user approval.

## Risks and Mitigations

| Risk | Mitigation |
| --- | --- |
| Existing tooling expects legacy metadata | Call out the v4-only transition and require downstream migration/compatibility follow-up if implementation exposes a concrete blocker. |
| Active skills drift from dotfiles v4 contract | Align with the final contract semantics and add a focused contract test. |
| `skill_workflow` is mistaken for a plan-skip lane | Repeat that only `execution_lane=quick_edit` can skip plan authoring. |
| Mirror labels become independent state again | State that metadata is source of truth and labels are aligned indexes. |
| Historical docs create search confusion | Leave history unchanged, but active contract tests target runtime files only. |
| Skill changes lack evaluation evidence | Require a checked-in before/after eval artifact. |

## Brainstorming Workflow Classification

```text
quick_edit=no
quick_edit_decision_reason=Active skill routing and workflow evidence contract changes require a written spec, review gate, plan, and eval evidence.
quick_edit_decided_by=brainstorming
execution_lane=plan
skill_workflow=skill_creator
skill_workflow_reason=The work changes active skill routing and evidence behavior and requires eval evidence.
```
