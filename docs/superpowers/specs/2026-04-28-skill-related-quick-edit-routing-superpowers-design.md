# Skill-Related and Quick Edit Routing for Superpowers Design
Parent bead: superpowers-3yk
Source issue: dotfiles-n0cr

**Status:** Draft for review
**Date:** 2026-04-28

## Problem

The dotfiles umbrella work in `dotfiles-n0cr` split a previously overloaded runtime concept into two independent decisions:

- `skill-related`: whether the work changes skill artifacts or skill behavior contracts and therefore requires skill-edit discipline.
- `quick_edit`: whether the work is narrow enough to skip separate plan authoring and use the lightweight execution path.

The active superpowers skill instructions still expose the older `skill_eval_fast_path` model in `brainstorming`, while `writing-plans` and `executing-plans` do not yet describe the new split as a consistent cross-skill routing contract. That creates three risks:

1. new work may still emit `execution_lane=skill_eval_fast_path`;
2. skill-relatedness may be mistaken for plan-skip authority;
3. execution may miss the required `skill-creator` / `writing-skills` discipline for skill artifact tasks.

This follow-up keeps the change in the superpowers repo and aligns only active runtime instructions and eval evidence.

## Brainstorming Classification for This Work

This work is itself classified as:

```text
skill_related=yes
skill_related_reason=active superpowers skill routing contract changes
quick_edit=no
quick_edit_decision_reason=multi-skill contract change with full comparison eval and reviewed implementation plan needed
quick_edit_decided_by=brainstorming
execution_lane=plan
```

## Goals

1. Remove `skill_eval_fast_path` as a newly produced active runtime lane in the superpowers skills.
2. Represent skill-relatedness as a domain classification that requires skill-edit discipline, not plan skipping.
3. Keep `quick_edit` as the only active plan-skip lane.
4. Teach `brainstorming` to record both decisions and their reasons.
5. Teach `writing-plans` to require explicit skill-related task routing in plans.
6. Teach `executing-plans` to invoke skill-related execution discipline when linked context or touched files indicate skill work.
7. Require full skill eval evidence, including with-skill vs without-skill comparison, for the implementation.

## Non-Goals

- Do not rewrite historical specs, plans, evals, or review artifacts solely to remove old `skill_eval_fast_path` references. Historical references can remain when they describe past behavior.
- Do not modify dotfiles-owned `bd-ralph`, `bd-ralph-v3`, run-ledger helpers, or dotfiles-owned tests in this superpowers follow-up.
- Do not make every skill-related change a quick edit.
- Do not make every small change a quick edit.
- Do not revert or rewrite unrelated working-tree changes, including the current dirty `skills/writing-skills/SKILL.md` content unless the later implementation explicitly determines that file is in scope and preserves unrelated edits.
- Do not skip repo-local active contract tests. The existing brainstorming fast-path contract test is in scope for rewrite or rename because it validates active runtime behavior, not historical documentation.

## New Routing Model

### Two Independent Axes

`skill-related` is a domain axis.

A work item is skill-related when it creates, modifies, evaluates, or changes routing for skill artifacts such as:

- `SKILL.md` files;
- skill `references/`, `scripts/`, `assets/`, or eval fixtures;
- skill metadata or trigger descriptions;
- workflow instructions that determine when another skill, such as `skill-creator`, is required.

`skill-related` means skill-edit discipline is required. It does not skip plan writing.

`quick_edit` is an execution-shape axis.

A work item qualifies for quick edit only when the existing `brainstorming` quick_edit criteria are conservatively met: bounded same-repo work, low ambiguity, clear touched surface, and clear verification. `quick_edit` is the only active lane that may skip separate plan authoring.

### Decision Matrix

| Classification | Plan authoring | Workspace default | Skill discipline |
| --- | --- | --- | --- |
| `skill_related=no`, `quick_edit=no` | required | normal workflow default | normal execution |
| `skill_related=no`, `quick_edit=yes` | skipped | quick_edit default | normal quick-edit evidence |
| `skill_related=yes`, `quick_edit=no` | required | normal workflow default | `writing-skills`; `skill-creator` when the task creates or modifies skill metadata, triggers, routing behavior, resources, or eval-driven behavior |
| `skill_related=yes`, `quick_edit=yes` | skipped | quick_edit default | `writing-skills` + `skill-creator` full workflow evidence |

New active output must use:

```text
execution_lane=plan|quick_edit
```

New active output must not use:

```text
execution_lane=skill_eval_fast_path
```

## Component Design

### `skills/brainstorming/SKILL.md`

Replace the current `skill_eval_fast_path Preflight Exception` section with a `skill-related Classification` section.

The updated brainstorming contract should state that it records:

```text
skill_related=yes|no
skill_related_reason=<short reason>
quick_edit=yes|no
quick_edit_decision_reason=<short reason>
quick_edit_decided_by=brainstorming
execution_lane=plan|quick_edit
```

Rules:

1. Default `execution_lane=plan`.
2. Set `execution_lane=quick_edit` only when `quick_edit=yes`.
3. Never create new `execution_lane=skill_eval_fast_path` output.
4. Evaluate `quick_edit` independently from `skill_related`: `skill_related=yes` does not force `quick_edit=no`, and `quick_edit=yes` does not imply `skill_related=yes`. Record a `quick_edit_decision_reason` for both yes and no decisions, especially when work is plausibly small or skill-related, so later workflows know whether plan authoring was intentional.
5. Preserve the existing quick_edit standalone Beads issue semantics for cases where brainstorming explicitly chooses quick_edit.
6. Do not invoke `skill-creator` directly from brainstorming unless the user explicitly asks to continue execution in the same session.

Brainstorming still stops after the reviewed, linked spec and recorded execution lane. It does not invoke `writing-plans`, `executing-plans`, or `skill-creator` automatically.

### `skills/writing-plans/SKILL.md`

Rename or extend the current `Skill-Target Hard Gate` into a skill-related plan hard gate.

For a skill-related plan, the plan must include:

```markdown
This plan is skill-related.
REQUIRED SUB-SKILL: Use superpowers:writing-skills for skill artifact edits.
ALSO REQUIRED: Use skill-creator when creating a new skill, changing skill metadata, restructuring skill resources, changing trigger/routing behavior, or doing eval-driven skill iteration.
```

The plan should repeat the routing requirement inside every task that touches a skill artifact, so task executors do not need to infer it from the header alone.

The self-review checklist should check that skill-related tasks include the required `writing-skills` and `skill-creator` instructions. This is a completeness gate for the plan, not an execution-lane decision.

### `skills/executing-plans/SKILL.md`

Add a skill-related task router before executing each task.

The executor should treat a task as skill-related when any of these are true:

- the linked Beads issue has a `skill-related` label or equivalent metadata;
- the linked spec or plan records `skill_related=yes`;
- the task touches a skill artifact path;
- the task text explicitly says it changes skill routing, metadata, evals, resources, or trigger behavior.

For such tasks, executing-plans must invoke the skill-edit discipline before editing:

```text
REQUIRED SUB-SKILL: superpowers:writing-skills
ALSO REQUIRED: skill-creator when the task changes metadata, triggers, routing behavior, resources, or eval-driven skill behavior.
```

This router does not replace plan review, Beads lifecycle, verification, or finishing workflows. It also does not skip plan authoring. It only controls how skill artifact tasks are executed.

### `skills/writing-skills/SKILL.md` and `skill-creator` Relationship

The implementation should inspect `writing-skills` and skill-creator guidance for consistency, but should avoid rewriting unrelated local edits.

The design requirement is that skill-related work uses skill-edit discipline and full eval evidence. If `writing-skills` already expresses that sufficiently, the implementation may leave it unchanged. If it needs a minimal wording alignment, the implementation must preserve unrelated existing changes and stage only intended paths.

## Data and Metadata Flow

When Beads is available, the parent bead for a reviewed spec should store the classification metadata after the user approves the spec:

```text
skill_related=yes|no
skill_related_reason=<short reason>
quick_edit=yes|no
quick_edit_decision_reason=<short reason>
quick_edit_decided_by=brainstorming
execution_lane=plan|quick_edit
```

For this parent bead, the expected values are the values listed in “Brainstorming Classification for This Work.”

If Beads is unavailable, the same fields should be included in the final handoff summary.


### Beads Handling for Quick Edit Metadata

There are two Beads shapes, and the implementation must keep them distinct:

1. **Pre-spec quick_edit exception:** when brainstorming chooses the existing quick_edit exception instead of writing a spec, create the standalone quick_edit execution issue described by the current quick_edit contract. The standalone issue gets the `quick_edit` label.
2. **Reviewed-spec execution metadata:** when brainstorming has written and reviewed a parent spec, record `quick_edit=yes|no` and `execution_lane=plan|quick_edit` on the parent bead as execution metadata. Do not create a second standalone quick_edit issue for this reviewed-spec parent.

A skill-related quick edit can exist in either shape, but `skill_related=yes` still only means skill-edit discipline is required. It does not decide the Beads shape by itself.

## Eval and Verification Requirements

Because this changes skill behavior, implementation must use eval-first skill development.

### Required Eval Cases

1. Positive trigger eval
   - Prompt: skill artifact routing or `SKILL.md` contract change.
   - Expected: `skill_related=yes`, `skill-creator` requirement appears, and `quick_edit` is decided independently.

2. Negative trigger eval
   - Prompt: non-skill documentation typo or unrelated config path tweak.
   - Expected: `skill_related=no`; no `skill-creator` requirement appears; quick_edit is evaluated only by normal quick_edit criteria.

3. Behavior / execution eval
   - Prompt: skill-related plan execution task.
   - Expected: plan is not skipped because of skill-relatedness; the task routes through `writing-skills`, and through `skill-creator` when it changes metadata, triggers, routing behavior, resources, or eval-driven behavior.

4. With-skill vs without-skill comparison
   - Run comparable prompts against the baseline and changed skill text.
   - Expected improvement: changed instructions separate `skill-related` from `quick_edit`, avoid new `execution_lane=skill_eval_fast_path`, and preserve skill-creator evidence requirements.


### Repo-Local Contract Test Updates

The implementation must update the existing fast-path contract test instead of leaving it to enforce the old lane. The expected target is:

```text
tests/claude-code/test-brainstorming-skill-eval-fast-path-contract.sh
```

Acceptable implementation choices are:

1. rename it to `tests/claude-code/test-brainstorming-skill-related-quick-edit-routing-contract.sh`; or
2. keep the filename temporarily but rewrite its assertions to test the new `skill-related` / `quick_edit` split.

The updated test must assert all of the following against active skill files:

- `brainstorming` contains `skill-related Classification`;
- `brainstorming` records `skill_related_reason`, `quick_edit_decision_reason`, and `execution_lane=plan|quick_edit`;
- active skills do not instruct agents to create new `execution_lane=skill_eval_fast_path`;
- `writing-plans` treats skill-related routing as plan completeness, not plan skipping;
- `executing-plans` has task-level skill-related routing before skill artifact edits;
- `skill-creator` evidence remains required for metadata, trigger, routing, resource, or eval-driven skill changes.

If the test is renamed, update any runner or documentation references needed for repeatable execution. At minimum, verification must run the rewritten/renamed test directly, for example:

```bash
bash tests/claude-code/test-brainstorming-skill-related-quick-edit-routing-contract.sh
```

### Contract Checks

Implementation should include targeted checks such as:

```bash
rg -n 'skill_eval_fast_path|execution_lane=skill_eval_fast_path' skills/brainstorming/SKILL.md skills/writing-plans/SKILL.md skills/executing-plans/SKILL.md
rg -n 'skill_related|skill-related|quick_edit_decision_reason|execution_lane=plan\|quick_edit|skill-creator' skills/brainstorming/SKILL.md skills/writing-plans/SKILL.md skills/executing-plans/SKILL.md
```

The first command is not automatically a failure when old terms appear in historical docs outside active runtime skills. It is a failure if active skill instructions still tell agents to create new `execution_lane=skill_eval_fast_path` output.


### Eval Artifact Location and Harness

Record eval evidence in:

```text
docs/superpowers/evals/2026-04-28-skill-related-quick-edit-routing-superpowers-eval.md
```

The artifact must include:

- the prompt for each required eval case;
- baseline / without-skill observed behavior, using the current checked-in text before the implementation change or a copied baseline excerpt;
- changed / with-skill observed behavior after the implementation change;
- pass/fail judgment for each assertion;
- exact commands used for contract tests and grep checks.

The harness can be a documented manual skill-eval transcript plus deterministic repo-local contract tests. It does not need a new automation framework unless the implementation plan chooses one.

### Plugin Sync Checks

After skill changes, run:

```bash
scripts/sync-local-plugin-copies.sh copy
scripts/sync-local-plugin-copies.sh verify
```

## Error Handling and Ambiguity

- If `quick_edit` is ambiguous, record `quick_edit=no` and keep `execution_lane=plan`.
- If a task touches skill artifacts, classify it as skill-related unless there is a clear reason not to.
- If a plan omits skill-related routing for skill artifact tasks, the plan is incomplete.
- If execution discovers a skill artifact task without routing guidance, executing-plans should use the skill-related task router rather than proceeding as a generic edit.
- If unrelated dirty files overlap an implementation target, stop and ask before editing. If dirty files are disjoint, preserve them and stage only requested paths.

## Acceptance Criteria

1. Active superpowers skill instructions do not create new `execution_lane=skill_eval_fast_path` output.
2. `brainstorming` records `skill_related`, `skill_related_reason`, `quick_edit`, `quick_edit_decision_reason`, `quick_edit_decided_by`, and `execution_lane=plan|quick_edit`.
3. `skill-related` is documented as skill-edit / skill-creator routing, not plan-skip authority.
4. `quick_edit` remains the only plan-skip lane.
5. `writing-plans` requires skill-related plans and tasks to include `writing-skills` and applicable `skill-creator` routing.
6. `executing-plans` has a task-level skill-related router for skill artifact work.
7. Implementation includes positive, negative, behavior, and with-vs-without eval evidence in `docs/superpowers/evals/2026-04-28-skill-related-quick-edit-routing-superpowers-eval.md`.
8. The existing brainstorming fast-path contract test is rewritten or renamed to assert the new `skill-related` / `quick_edit` routing model.
9. Historical docs may retain `skill_eval_fast_path` references, but active runtime instructions and new eval expectations use the new model.
10. Plugin copies are synced and verified after implementation.

## Risks and Mitigations

### Risk: `skill-related` becomes a new shortcut name

Mitigation: State repeatedly that `skill-related` is not a plan-skip authority. Only `quick_edit` can set `execution_lane=quick_edit`.

### Risk: quick_edit becomes too broad for skill changes

Mitigation: Keep quick_edit conservative and require a decision reason. Skill-related + quick_edit is allowed only when normal quick_edit criteria are independently satisfied.

### Risk: historical references cause false failures

Mitigation: Verification distinguishes active runtime instructions from historical specs, plans, evals, and reviews.

### Risk: unrelated dirty skill edits are overwritten

Mitigation: Implementation must inspect dirty paths first, preserve unrelated edits, and stage only intended files.
