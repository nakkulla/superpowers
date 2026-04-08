# bd-ralph Subagent Execution Minimal Design

**Status:** Draft for review  
**Date:** 2026-04-08

## Problem

`bd-ralph` currently assumes `superpowers:executing-plans` as its execution phase.
That prevents `bd-ralph` from selecting `superpowers:subagent-driven-development`
as an alternative execution engine, even when the desired workflow is same-session
subagent coordination.

The repo already has both execution styles:

- `executing-plans` for direct plan execution,
- `subagent-driven-development` for same-session subagent execution.

But `bd-ralph` cannot currently route into the second path in a documented,
automatic, and non-interactive way.

## Goal

Allow `bd-ralph` to execute a plan through either:

1. `superpowers:executing-plans`, or
2. `superpowers:subagent-driven-development`

while keeping the change set minimal and preserving clear responsibility boundaries.

## Non-Goals

- Making `subagent-driven-development` a full clone of `executing-plans`
- Moving workspace policy ownership out of `bd-ralph`
- Moving finishing / PR / resolved ownership out of `bd-ralph`
- Changing prompt templates for implementer or reviewer subagents
- Changing `executing-plans` behavior in this work
- Adding new default-profile fields beyond extending the existing execution strategy semantics

## Current Behavior

### `bd-ralph`

- reads a default profile and derives child-skill overrides,
- owns plan phase, execution phase, finish phase, and PR handoff,
- documents only one execution child:
  - `superpowers:executing-plans --auto`

### `subagent-driven-development`

- describes the same-session subagent workflow,
- does not declare a machine-oriented argument contract,
- does not define a minimal `--auto` invocation contract for an upper orchestrator like `bd-ralph`.

## Proposed Behavior

### Responsibility Boundaries

Keep the ownership split explicit:

- `bd-ralph` remains the top-level orchestrator
- `subagent-driven-development` becomes a plan-centric execution engine with a thin `--auto` interface

That means:

### `bd-ralph` continues to own

- Beads issue/spec/plan resolution
- default profile interpretation
- plan review and implementation review policy
- workspace preparation
- finishing / PR / resolved workflow

### `subagent-driven-development` owns

- reading the plan file
- extracting tasks
- running implementer / spec-review / code-quality loops
- task-level execution progress
- task-level Beads updates when explicitly instructed by flags

### Minimal Execution Routing

Add execution routing to `bd-ralph`:

- `execution_strategy: direct` → invoke `superpowers:executing-plans --auto`
- `execution_strategy: subagent` → invoke `superpowers:subagent-driven-development --auto`

Also allow an explicit per-run override:

```text
--execution direct|subagent
```

### Thin Auto Contract for `subagent-driven-development`

Do not give this skill full issue-resolution or workspace-selection logic.
Instead, add a minimal plan-centric contract:

```text
[plan-path] [--auto] [--parent-issue <id>] [--beads full|parent|skip] [--finishing run|skip]
```

Behavior:

- `plan-path` is required for `--auto`
- `--beads full|parent` requires `--parent-issue <id>`
- `--finishing skip` is used when an upper orchestrator owns finishing
- `--finishing run` remains available for standalone execution if needed later

### Beads Scope

The thin contract supports only three explicit modes:

### `--beads skip`

- no Beads updates
- TodoWrite only

### `--beads parent`

- claim the parent issue at start
- do not create or manage child issues
- push bead state on completion or interruption

### `--beads full`

- claim the parent issue at start
- inspect existing children for resume
- if no children exist, invoke `seed-beads-from-plan --auto`
- claim/resolve children per task
- push bead state on completion or interruption

`subagent-driven-development` remains plan-centric. It does not resolve issue metadata by itself.

## Required Skill Updates

### 1. `bd-ralph/SKILL.md`

Update the skill so that it:

1. adds `--execution direct|subagent` to `argument-hint`
2. documents execution routing in Phase 2
3. invokes `superpowers:subagent-driven-development --auto ... --finishing skip` for the subagent path
4. keeps workspace setup in `bd-ralph`
5. keeps finishing ownership in `bd-ralph`

### 2. `bd-ralph/references/default-profile.md`

Update the default profile documentation so that:

- `execution_strategy` supports both `direct` and `subagent`
- `direct` means `superpowers:executing-plans`
- `subagent` means `superpowers:subagent-driven-development`

### 3. `skills/subagent-driven-development/SKILL.md`

Update the skill so that it:

1. declares the thin `argument-hint`
2. defines `--auto` as a non-interactive mode
3. requires `plan-path` in `--auto`
4. requires `--parent-issue` when `--beads full|parent` is used
5. defines `--beads full|parent|skip`
6. defines `--finishing run|skip`
7. makes clear that issue/spec/plan resolution is not part of this skill

## Verification

1. Confirm `bd-ralph/SKILL.md` declares `--execution direct|subagent`
2. Confirm `bd-ralph` Phase 2 documents both execution branches
3. Confirm the subagent branch invokes `superpowers:subagent-driven-development --auto`
4. Confirm `bd-ralph` still owns workspace preparation
5. Confirm `bd-ralph` still owns finishing / PR flow
6. Confirm `bd-ralph/references/default-profile.md` documents `execution_strategy: direct|subagent`
7. Confirm `skills/subagent-driven-development/SKILL.md` declares the thin argument contract
8. Confirm `subagent-driven-development` documents `--auto` as non-interactive
9. Confirm `subagent-driven-development` requires `--parent-issue` for `--beads full|parent`
10. Confirm no prompt template files were changed by this work
11. Confirm `executing-plans` was not modified by this work

## Risks and Mitigations

### Risk: responsibility drift between execution skills

**Mitigation:** keep `subagent-driven-development` plan-centric and thin; do not copy full orchestration behavior from `executing-plans`.

### Risk: finishing responsibility becomes ambiguous

**Mitigation:** require `bd-ralph` to pass `--finishing skip` on the subagent path and keep finishing in Phase 3.

### Risk: future contributors assume `subagent-driven-development` can resolve issue IDs

**Mitigation:** document explicitly that issue/spec/plan resolution remains with `bd-ralph`.

### Risk: the change spreads into prompt template churn

**Mitigation:** keep prompt templates out of scope for this minimal design.
