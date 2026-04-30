# Superpowers v4 Workflow Contract Alignment Eval

Parent bead: `superpowers-vhy`
Spec: `docs/superpowers/specs/2026-04-30-superpowers-v4-workflow-contract-alignment-design.md`
Plan: `docs/superpowers/plans/2026-04-30-superpowers-v4-workflow-contract-alignment.md`
Eval type: `contract_smoke`

## Harness boundary

This eval is a reproducible repository contract-smoke record. It uses shell contract tests plus focused `rg` checks rather than an external model benchmark. The comparison is the active runtime guidance before implementation (`without_skill`/baseline) versus the changed guidance after implementation (`with_skill`/changed).

## Baseline evidence

Command bundle captured before implementation:

```bash
bash tests/claude-code/test-brainstorming-skill-related-quick-edit-routing-contract.sh
rg -n 'skill_related|skill-related|spec_reviewed_sha|spec_review_base_sha|spec_freshness|spec_stale_reason|skill_creator_required' skills/brainstorming/SKILL.md skills/writing-plans/SKILL.md skills/executing-plans/SKILL.md || true
rg -n 'skill_workflow|spec_content_hash|spec_reviewed_at_sha|plan_content_hash|plan_reviewed_at_sha|impl_reviewed_diff_range|execution_lane=plan\|quick_edit' skills/brainstorming/SKILL.md skills/writing-plans/SKILL.md skills/executing-plans/SKILL.md || true
```

Result summary:

- Old contract test passed: `PASS: brainstorming skill-related quick_edit routing contract`.
- Baseline active guidance used `skill-related` / `skill_related` as positive routing vocabulary in `brainstorming`, `writing-plans`, and `executing-plans`.
- Baseline spec review guidance used legacy fields: `spec_reviewed_sha`, `spec_review_base_sha`, `spec_freshness`, and `spec_stale_reason`.
- Baseline v4 target terms were mostly absent except `execution_lane=plan|quick_edit`.

## Changed evidence

Command bundle captured after implementation:

```bash
bash tests/claude-code/test-brainstorming-v4-workflow-routing-contract.sh
rg -n 'skill_related|skill-related|spec_reviewed_sha|spec_review_base_sha|spec_freshness|spec_stale_reason|skill_creator_required' skills/brainstorming/SKILL.md skills/writing-plans/SKILL.md skills/executing-plans/SKILL.md || true
rg -n 'skill_workflow|spec_content_hash|spec_reviewed_at_sha|plan_content_hash|plan_reviewed_at_sha|impl_reviewed_at_sha|impl_reviewed_diff_range|execution_lane=plan\|quick_edit' skills/brainstorming/SKILL.md skills/writing-plans/SKILL.md skills/executing-plans/SKILL.md
```

Result summary:

- New contract test passed: `PASS: brainstorming v4 workflow routing contract`.
- Changed active guidance records `skill_workflow=none|writing_skills|skill_creator` and `skill_workflow_reason`.
- Changed active guidance keeps `execution_lane=plan|quick_edit` independent from `skill_workflow`.
- Changed review evidence uses `spec_content_hash` + `spec_reviewed_at_sha`, `plan_content_hash` + `plan_reviewed_at_sha`, and `impl_reviewed_at_sha` + `impl_reviewed_diff_range`.
- Remaining legacy metadata strings appear only in negative compatibility warnings such as “do not create canonical v4 metadata” or “do not store legacy review metadata.”

## Prompt judgments

### 1. Skill workflow prompt

Prompt:

> A Beads issue asks to update `skills/brainstorming/SKILL.md` trigger/routing behavior and add eval evidence. Decide `quick_edit`, `execution_lane`, and `skill_workflow`.

Expected:

```text
quick_edit=no
execution_lane=plan
skill_workflow=skill_creator
```

Judgment: **PASS**. The changed brainstorming guidance says active skill routing/eval behavior requires `skill_workflow=skill_creator` discipline, while `quick_edit=no` and `execution_lane=plan` are appropriate because this is active routing/evidence contract work that needs a spec, plan, review gate, and eval evidence.

### 2. Non-skill quick edit prompt

Prompt:

> A Beads issue asks to fix a typo in `README.md` with no behavior, contract, or cross-repo impact. Decide `quick_edit`, `execution_lane`, and `skill_workflow`.

Expected:

```text
skill_workflow=none
execution_lane=quick_edit
```

`execution_lane=quick_edit` is acceptable only when the answer states that normal quick-edit criteria are clear, bounded, same-repo, and easy to verify.

Judgment: **PASS**. The changed brainstorming guidance supports `skill_workflow=none` for non-skill work and allows `execution_lane=quick_edit` only for bounded work with clear intent, acceptance, touched surface, and verification path.

## Before/after conclusion

Before this change, active runtime guidance used `skill_related` as a positive routing concept and stored ambiguous review freshness metadata. After this change, active guidance uses v4 `skill_workflow`, keeps `quick_edit` tied to `execution_lane=quick_edit`, treats `has:*` and `quick_edit` labels as mirror/index state, and records review gates with content hashes plus reviewed-at SHAs.
