# Skill-Related and Quick Edit Routing Superpowers Eval

Parent bead: `superpowers-3yk`
Plan: `docs/superpowers/plans/2026-04-28-skill-related-quick-edit-routing-superpowers.md`
Baseline ref: `97ed97d96cccee82edbc29388520bf4e85924560`
Changed ref: `7618b7cf5d727c149e72a7b49d6f2aa4deb9d8d0`

## Summary

Result: PASS.

The changed active instructions separate `skill_related` from `quick_edit`, preserve `quick_edit` as the only plan-skip lane, and add task-level skill routing for execution. The only remaining `skill_eval_fast_path` matches in active files are negative assertions forbidding new `execution_lane=skill_eval_fast_path` output.

## Baseline / without-skill evidence

Raw evidence was captured under the local uncommitted scratch directory `docs/superpowers/evals/2026-04-28-skill-related-quick-edit-routing-superpowers-raw/` and summarized here.

Commands:

```bash
BASELINE_REF=97ed97d96cccee82edbc29388520bf4e85924560
for f in skills/brainstorming/SKILL.md skills/writing-plans/SKILL.md skills/executing-plans/SKILL.md; do
  git show "$BASELINE_REF:$f" > ".../baseline/$f"
done
rg -n 'skill_eval_fast_path|execution_lane=skill_eval_fast_path|skill-creator|writing-plans.*not required|plan-review.*skip' ".../baseline" > baseline-routing-rg.txt || true
rg -n 'Skill-Target Hard Gate|Skill-related Task Router|skill_related=yes|quick_edit_decision_reason' ".../baseline" > baseline-new-routing-rg.txt || true
```

Observed baseline:

- `skills/brainstorming/SKILL.md` contained `## skill_eval_fast_path Preflight Exception`.
- Baseline brainstorming explicitly said `writing-plans` was not required and `plan-review` may be skipped for that lane.
- Baseline brainstorming instructed recording `execution_lane=skill_eval_fast_path`.
- Baseline writing-plans had `## Skill-Target Hard Gate`, not skill-related plan completeness wording.
- Baseline executing-plans had no `Skill-related Task Router`.

## Changed / with-skill evidence

Commands:

```bash
bash tests/claude-code/test-brainstorming-skill-related-quick-edit-routing-contract.sh
rg -n 'skill_eval_fast_path|execution_lane=skill_eval_fast_path' skills/brainstorming/SKILL.md skills/writing-plans/SKILL.md skills/executing-plans/SKILL.md tests/claude-code/test-brainstorming-skill-related-quick-edit-routing-contract.sh || true
rg -n 'skill_related|skill-related|quick_edit_decision_reason|execution_lane=plan\|quick_edit|skill-creator|Skill-related Task Router' skills/brainstorming/SKILL.md skills/writing-plans/SKILL.md skills/executing-plans/SKILL.md
```

Observed changed behavior:

- Contract test output: `PASS: brainstorming skill-related quick_edit routing contract`.
- `skills/brainstorming/SKILL.md` now records `skill_related`, `skill_related_reason`, `quick_edit`, `quick_edit_decision_reason`, `quick_edit_decided_by=brainstorming`, and `execution_lane=plan|quick_edit`.
- `skills/writing-plans/SKILL.md` now has `## Skill-related Plan Hard Gate` and says this is a plan completeness gate, not an execution-lane decision.
- `skills/executing-plans/SKILL.md` now has `## Skill-related Task Router` before task execution.

## Positive trigger eval

Prompt: A Beads issue asks to change a `SKILL.md` trigger description and update eval prompts; decide `skill_related`, `quick_edit`, `execution_lane`, and required downstream discipline.

Baseline observation: The old brainstorming text could select `skill_eval_fast_path` for skill artifacts and skip a separate plan artifact.

Changed observation: The new text classifies this as `skill_related=yes`, requires an independent `quick_edit` decision, limits `execution_lane` to `plan|quick_edit`, and requires downstream `writing-skills` plus `skill-creator` for trigger/routing/eval behavior.

Judgment: PASS.

## Negative trigger eval

Prompt: A Beads issue asks to fix a typo in `README.md`; decide `skill_related`, `quick_edit`, `execution_lane`, and whether `skill-creator` is required.

Baseline observation: The old skill-specific fast path was not directly relevant, but there was no explicit `skill_related=no` metadata contract.

Changed observation: The new classification supports `skill_related=no`; `quick_edit` is evaluated only by normal quick_edit criteria; `skill-creator` is not required for a non-skill typo.

Judgment: PASS.

## Behavior / execution eval

Prompt: Execute a plan task that edits `skills/executing-plans/SKILL.md` routing behavior; decide whether plan authoring is skipped and which sub-skills must run before editing.

Baseline observation: `executing-plans` had no task-level router for skill artifact work, so the executor had to infer routing from other context.

Changed observation: `executing-plans` now classifies tasks as skill-related when labels, metadata/spec/plan, touched paths, or task text indicate skill work. It requires `superpowers:writing-skills` and `skill-creator` for metadata, trigger, routing, resource, or eval-driven skill changes. It explicitly says the router does not skip plan authoring, Beads lifecycle, verification, review, or finishing.

Judgment: PASS.

## With-skill vs without-skill comparison

Without-skill baseline selected or preserved an overloaded `skill_eval_fast_path` lane for skill artifacts and had no execution task router. With-skill changed instructions separate the domain axis (`skill_related`) from the execution-shape axis (`quick_edit`), keep plan skipping exclusive to `quick_edit`, and route skill artifact execution through the required skill-edit discipline.

Judgment: PASS; changed behavior is meaningfully better for the target routing contract.

## Commands and results

```bash
bash tests/claude-code/test-brainstorming-skill-related-quick-edit-routing-contract.sh
# PASS: brainstorming skill-related quick_edit routing contract

rg -n 'skill_eval_fast_path|execution_lane=skill_eval_fast_path' skills/brainstorming/SKILL.md skills/writing-plans/SKILL.md skills/executing-plans/SKILL.md tests/claude-code/test-brainstorming-skill-related-quick-edit-routing-contract.sh || true
# Only negative assertion matches remain in brainstorming/test.

rg -n 'skill_related|skill-related|quick_edit_decision_reason|execution_lane=plan\|quick_edit|skill-creator|Skill-related Task Router' skills/brainstorming/SKILL.md skills/writing-plans/SKILL.md skills/executing-plans/SKILL.md
# New routing fields, plan gate, and task router found.
```

## Skipped layers

No required eval layer was skipped. The with-vs-without comparison used deterministic baseline/changed instruction snapshots and manual prompt judgments rather than a new automated model benchmark harness, as allowed by the reviewed spec.
