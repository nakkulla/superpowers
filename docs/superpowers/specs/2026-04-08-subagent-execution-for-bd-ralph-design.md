# subagent-driven-development as bd-ralph Execution Engine

**Status:** Draft for review
**Date:** 2026-04-08

## Problem

`bd-ralph` currently only supports `superpowers:executing-plans` as its execution engine (Phase 2). The `superpowers:subagent-driven-development` skill exists as an alternative execution model with per-task subagent isolation and built-in review loops, but `bd-ralph` cannot route into it because:

1. `subagent-driven-development` has no `--auto` mode (no non-interactive contract)
2. `subagent-driven-development` has no `--finishing` flag (would conflict with bd-ralph Phase 3)
3. `subagent-driven-development` has no Beads integration (no child bead tracking)
4. `bd-ralph` has no execution strategy branching in Phase 2

## Goal

Allow `bd-ralph` to execute plans through either `executing-plans` or `subagent-driven-development`, selected via `execution_strategy` profile value or `--execution` per-run flag.

The subagent path provides:
- **Subagent isolation**: each task runs in a fresh subagent with clean context
- **Per-task review loops**: spec compliance + code quality review after each task
- **Per-task Beads tracking**: child bead claim/resolved updates in real-time

## Non-Goals

- Making `subagent-driven-development` a clone of `executing-plans`
- Moving workspace/finishing/PR ownership out of `bd-ralph`
- Changing `executing-plans` behavior
- Modifying subagent prompt templates (`implementer-prompt.md`, `spec-reviewer-prompt.md`, `code-quality-reviewer-prompt.md`)
- Adding parallel task execution to `subagent-driven-development`

## Responsibility Boundaries

### bd-ralph owns

- Beads issue/spec/plan resolution (Phase 0-1)
- Default profile interpretation
- Plan review and implementation review policy
- Workspace preparation (using-git-worktrees)
- Beads child seeding (seed-beads-from-plan)
- Finishing / PR / resolved workflow (Phase 3)

### subagent-driven-development owns

- Reading the plan file and extracting tasks
- Running implementer / spec-review / code-quality loops per task
- Task-level execution progress (TodoWrite)
- Task-level Beads child updates (when instructed by flags)

## Design

### 1. subagent-driven-development: New Argument Contract

```text
argument-hint: "[plan-path] [--auto] [--parent-issue <id>] [--beads full|parent|skip] [--finishing run|skip]"
```

#### --auto Mode

Non-interactive execution. Required by `bd-ralph` and available for standalone automation.

| Decision Point | Interactive | --auto |
|----------------|------------|--------|
| Plan file load failure | Ask user for path | Fail fast |
| Subagent returns BLOCKED | Escalate to user | Context supplement 1x retry, then fail fast |
| Subagent returns NEEDS_CONTEXT | Supplement context and re-dispatch | Same (already automatic) |
| Review loop fails 3 consecutive times | Ask user for judgment | Fail fast with error report |
| finishing-a-development-branch | Invoke | `--finishing skip`: omit, return control to caller |

`--auto` requires `plan-path` to be explicitly provided.

#### --beads Flag

Three modes, matching `executing-plans` semantics:

**`--beads skip` (default)**
- No Beads updates
- TodoWrite progress tracking only

**`--beads parent`**
- Requires `--parent-issue <id>`
- Claim parent issue at start
- No child issue management
- `bd dolt push` on completion or interruption

**`--beads full`**
- Requires `--parent-issue <id>`
- Claim parent issue at start
- Inspect existing children via `bd children <parent-id>` for resume
  - If children exist: rebuild Task-to-Bead mapping, mark already-resolved as completed
  - If no children exist: invoke `seed-beads-from-plan --auto`
- Per-task updates:
  - Task start: `bd update <child-id> --claim`
  - Task complete (after review pass): `bd update <child-id> --status resolved --set-metadata git_sha=<sha>`
- `bd dolt push` on completion or interruption
- bd write serialization enforced (no parallel bd writes)

**Task-to-Bead mapping**: Match plan task titles to child bead titles. Same matching logic as `executing-plans`.

#### --finishing Flag

- `--finishing run` (default): invoke `finishing-a-development-branch` after all tasks complete
- `--finishing skip`: omit finishing, return control to caller

#### --parent-issue Flag

- Required when `--beads full|parent`
- The parent Beads issue ID for child resolution and claiming

### 2. bd-ralph: Phase 2 Execution Routing

#### Profile Extension

`execution_strategy` in `default-profile.md` accepts:

```yaml
execution_strategy: direct | subagent
```

- `direct` (default): invoke `superpowers:executing-plans --auto`
- `subagent`: invoke `superpowers:subagent-driven-development --auto`

Per-run override: `--execution direct|subagent`

#### Phase 2 Branch Logic

```
Phase 2: Execute
  |-- workspace == "worktree" --> Invoke $superpowers:using-git-worktrees --auto
  |-- beads_mode == "full"    --> Invoke $seed-beads-from-plan --auto  [direct path only]
  |
  |-- IF execution_strategy == "direct":
  |     Invoke $superpowers:executing-plans --auto
  |       --execution direct
  |       --workspace <workspace>
  |       --beads <beads_mode>
  |       --plan-review skip        (already handled in Phase 1)
  |       --finishing skip           (bd-ralph Phase 3 handles it)
  |
  |-- IF execution_strategy == "subagent":
        Invoke $superpowers:subagent-driven-development --auto
          --parent-issue <parent-bead-id>
          --beads <beads_mode>
          --finishing skip           (bd-ralph Phase 3 handles it)
```

Note: For the subagent path with `--beads full`, `subagent-driven-development` handles `seed-beads-from-plan` internally (inspect children first, seed only if needed). So bd-ralph skips the explicit seed step for the subagent path.

#### Phase 3: No Changes

Phase 3 (implementation-review, finishing-a-development-branch, resolved marking) remains identical regardless of execution strategy. Both paths use `--finishing skip` so bd-ralph retains finishing ownership.

### 3. bd-ralph default-profile.md Update

Add documentation for `execution_strategy: subagent`:

```yaml
execution_strategy: direct
  # direct  -> superpowers:executing-plans (inline task execution)
  # subagent -> superpowers:subagent-driven-development (per-task subagent with review loops)
```

### 4. Review Layer Interaction

When using the subagent execution path, two review layers coexist:

| Layer | Owner | Scope | When |
|-------|-------|-------|------|
| Per-task spec compliance + code quality | subagent-driven-development | Each task individually | During execution |
| Implementation review | bd-ralph Phase 3 | Entire implementation | After all tasks complete |

These are complementary: per-task reviews catch local issues, implementation review catches integration issues across the whole changeset.

## Required Skill Updates

### 1. `skills/subagent-driven-development/SKILL.md` (superpowers repo)

1. Add `argument-hint` declaration
2. Add `--auto` gate section with decision table
3. Add `--beads full|parent|skip` with per-task update logic
4. Add `--parent-issue <id>` requirement for beads modes
5. Add `--finishing run|skip` flag
6. Add resume logic for `--beads full` (inspect existing children)
7. Document that issue/spec/plan resolution is NOT part of this skill

### 2. `bd-ralph/SKILL.md` (dotfiles repo)

1. Add `--execution direct|subagent` to `argument-hint`
2. Add execution strategy routing to Phase 2
3. Document the subagent invoke with `--auto --finishing skip --beads <mode> --parent-issue <id>`
4. Note: seed-beads-from-plan is handled by subagent-driven-development in the subagent path

### 3. `bd-ralph/references/default-profile.md` (dotfiles repo)

1. Document `execution_strategy: direct | subagent` with descriptions

## Edge Cases

| Situation | Handling |
|-----------|----------|
| `seed-beads-from-plan` produces no children | `--beads full` per-task updates become no-op (no child mapping) |
| Subagent BLOCKED + `--auto` | Context supplement 1x retry, then fail fast and halt execution |
| `bd dolt push` failure | Stop all subsequent bd writes, switch to recovery (per Beads policy) |
| `--beads skip` standalone use | Works without Beads. Preserves existing standalone use case |
| Partial task completion + interruption | Push current bead state (`bd dolt push`), leave incomplete tasks as-is |
| Resume with existing children | Rebuild mapping, skip already-resolved tasks, continue from first pending |

## Verification

1. `bd-ralph/SKILL.md` declares `--execution direct|subagent` in argument-hint
2. `bd-ralph` Phase 2 documents both execution branches
3. Subagent branch invokes `superpowers:subagent-driven-development --auto --finishing skip`
4. `bd-ralph` still owns workspace preparation and finishing/PR flow
5. `default-profile.md` documents `execution_strategy: direct|subagent`
6. `subagent-driven-development/SKILL.md` declares the argument contract
7. `subagent-driven-development` documents `--auto` as non-interactive with decision table
8. `subagent-driven-development` requires `--parent-issue` for `--beads full|parent`
9. `subagent-driven-development` includes per-task Beads child update logic
10. No prompt template files were changed
11. `executing-plans` was not modified

## Risks and Mitigations

### Risk: Responsibility drift between execution skills

**Mitigation:** Keep `subagent-driven-development` plan-centric and thin. Issue resolution, workspace setup, and finishing remain with `bd-ralph`.

### Risk: Finishing responsibility becomes ambiguous

**Mitigation:** `bd-ralph` always passes `--finishing skip` on the subagent path. Phase 3 is the single owner.

### Risk: Double review overhead (per-task + implementation review)

**Mitigation:** The reviews serve different purposes (local correctness vs integration correctness). Both layers are opt-in via bd-ralph profile. If overhead is excessive, `implementation_review: skip` can be set in the profile.

### Risk: Beads write contention in subagent context

**Mitigation:** All bd writes are serialized within the controller (subagent-driven-development's main loop). Subagents themselves never call `bd` directly.

### Risk: Future contributors assume subagent-driven-development can resolve issue IDs

**Mitigation:** Document explicitly that issue/spec/plan resolution remains with `bd-ralph`.
