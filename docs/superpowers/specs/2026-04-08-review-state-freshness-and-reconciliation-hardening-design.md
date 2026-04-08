# Review State Freshness and Reconciliation Hardening Design
Parent bead: superpowers-efy

**Status:** Draft for review
**Date:** 2026-04-08

## Problem

`bd-ralph`, `subagent-driven-development`, `plan-review`, and `implementation-review` now cover the core subagent orchestration path, but actual runs still expose four state-management gaps:

1. `plan-review --auto-fix` can change a plan without guaranteeing that the corrected plan is materialized into the next execution workspace,
2. task-level reviewers can still judge stale state or findings outside the current diff even when diff-scoped review is intended,
3. completed or superseded subagents can remain open long enough to hit thread or lifecycle pressure, and
4. finish-phase `implementation-review --auto-fix` can create additional commits after task completion, leaving parent/child Beads SHA metadata out of sync with the final branch state.

These failures are not a workflow redesign problem. They come from an underspecified contract about who reports post-fix state, who validates that state, and who reconciles durable metadata after automated review changes.

## Goals

Harden the follow-up orchestration contract so that:

- review-family skills emit authoritative post-fix state when they modify files,
- workflow orchestrators validate that state before advancing phases,
- task-level review stays fresh and scoped to the current diff,
- completed and superseded subagents are explicitly closed, and
- finish-phase auto-fix cannot leave parent/child SHA metadata stale.

## Non-Goals

- Adding new runtime enforcement tools or daemons
- Redesigning the overall `bd-ralph` / `subagent-driven-development` workflow shape
- Changing the Beads schema or lifecycle model
- Making generic review skills infer child-task ownership by themselves
- Reworking model selection or parallel execution strategy

## Current Failure Pattern

### 1. Plan fixes can be invisible to the next workspace

When `plan-review --auto-fix` edits a plan in the current workspace, the next execution workspace may still be created from an older `HEAD` or from a tree that never materialized the review changes. The review skill can therefore succeed while the execution phase still reads stale planning input.

### 2. Diff-scoped review can still read stale context

Even after diff-scoped review was introduced, a reviewer can still respond from an older snapshot or from an insufficiently anchored packet. That creates false findings against pre-existing code or against code that has already been revised.

### 3. Agent lifecycle remains implicit

The controller logic assumes fresh subagents per task and review round, but it does not explicitly require completed or superseded agents to be closed. Long runs can therefore accumulate idle agents and hit thread limits.

### 4. Finish-phase auto-fix can drift durable SHA state

Task-level child beads already record a `git_sha` when a task completes. But if `implementation-review --auto-fix` produces new changes after those task completions, the final branch `HEAD` can diverge from the child metadata unless the orchestrator performs a reconciliation step.

## Design Principles

### Post-fix state must be observable

If a review skill changes files, the caller must not infer the resulting state indirectly. The review skill should report explicit, machine-readable post-fix state.

### Responsibility should stay local to the right layer

Review skills know exactly what they changed and what diff they reviewed. Orchestrators know task ownership, phase boundaries, and Beads state. The contract should preserve that split instead of collapsing workflow state management into a generic review skill.

### Freshness beats narrative

A reviewer verdict is only useful when it is anchored to the current diff and current branch state. If the verdict cannot be tied to the active diff, it should be treated as stale rather than as implementation truth.

### Durable metadata must follow final branch state

If finish-phase automation changes the branch, durable parent/child metadata must either be reconciled or the run must stop before claiming completion.

## Responsibility Boundary

### `plan-review`

`plan-review` is responsible for reporting whether auto-fix changed the plan and what post-fix state now exists.

It is responsible for emitting:
- whether auto-fix was applied,
- the post-fix `HEAD` (or explicit unchanged state),
- the changed plan files, and
- whether the working tree is clean after review.

It is not responsible for:
- materializing that corrected plan into a later worktree,
- choosing the next workspace strategy,
- or updating Beads metadata.

### `implementation-review`

`implementation-review` is responsible for reporting the review baseline and the post-fix implementation state when auto-fix changes code.

It is responsible for emitting:
- the review `BASE_SHA`,
- the review `HEAD_SHA`,
- whether auto-fix was applied,
- the post-fix `HEAD`,
- the changed files after auto-fix, and
- whether metadata reconciliation is required.

It is not responsible for:
- deciding which child beads own the changed files,
- writing parent/child SHA metadata,
- or advancing finish-phase workflow state by itself.

### `subagent-driven-development`

`subagent-driven-development` is responsible for task-loop freshness and agent lifecycle.

It is responsible for:
- dispatching reviewers with current diff context,
- rejecting stale reviewer findings,
- closing completed or superseded subagents,
- and recording child `git_sha` at task completion.

It is not responsible for:
- finish-phase parent/child SHA reconciliation,
- resolving spec/plan metadata for the parent issue,
- or re-owning `bd-ralph` finish behavior.

### `bd-ralph`

`bd-ralph` is responsible for phase advancement and durable state reconciliation.

It is responsible for:
- validating that plan-review output was materialized before execution starts,
- interpreting finish-phase `implementation-review` output,
- reconciling parent/child SHA metadata when post-fix changes occur,
- and refusing to mark the workflow complete while required reconciliation is still pending.

It is not responsible for:
- reimplementing review-family logic inline,
- or inferring post-fix review state without explicit artifacts from the review skills.

## Proposed Changes

### 1. Review Output Contract Hardening

#### `plan-review`

Extend the machine-readable summary for automated runs so it always reports:

- `Auto-fix applied: yes|no`
- `Post-fix HEAD: <sha|unchanged>`
- `Post-fix changed files: <comma-separated files|none>`
- `Working tree clean: yes|no`

If `Auto-fix applied=yes`, these fields become required phase outputs for any caller that intends to continue directly into execution.

#### `implementation-review`

Extend the machine-readable summary for automated runs so it always reports:

- `Review BASE_SHA: <sha>`
- `Review HEAD_SHA: <sha>`
- `Auto-fix applied: yes|no`
- `Post-fix HEAD: <sha|unchanged>`
- `Post-fix changed files: <comma-separated files|none>`
- `Metadata reconciliation required: yes|no`

`Metadata reconciliation required` must be `yes` whenever auto-fix created a real code diff after the incoming review baseline.

### 2. Plan State Propagation Hardening

When `bd-ralph` runs `plan-review --auto-fix`, it must not advance into execution until the reviewed plan is known to exist in the actual execution workspace.

Two valid strategies are allowed:

1. **Commit-first**
   - auto-fix creates a commit,
   - the execution workspace is created from that updated `HEAD`, and
   - the plan file in the execution workspace matches the reviewed plan.

2. **Copy-forward**
   - auto-fix remains uncommitted,
   - the corrected plan is explicitly copied into the target execution workspace,
   - and the base workspace is restored to a clean state afterward.

If neither strategy is observed, execution must stop instead of silently using stale planning state.

### 3. Review Freshness Hardening

Task-level reviewer prompts and controller rules must include a stronger freshness contract.

Required reviewer inputs:
- `BASE_SHA`
- `HEAD_SHA`
- `CHANGED_FILES`
- optional changed-hunks summary when the touched surface is still ambiguous

Required reviewer behavior:
- review only the current task diff relative to `BASE_SHA`,
- anchor findings to concrete file:line references in the touched scope,
- treat unclear scope as `NEEDS_CONTEXT`, not speculation.

Required controller behavior:
- treat findings outside the current diff as `STALE_REVIEW`,
- discard stale verdicts instead of turning them into implementation failures,
- and prefer a fresh reviewer for re-review after stale state or timeout.

### 4. Agent Lifecycle Hardening

`subagent-driven-development` must make agent lifecycle explicit.

Required rules:
- after an implementer result is harvested and no immediate follow-up is pending, close that implementer agent,
- after a reviewer verdict is harvested, close that reviewer agent,
- before dispatching a superseding reviewer or retry agent, close the superseded one,
- maintain a bounded live-agent budget during long runs.

This change is operational rather than architectural: it does not change task order, but it makes cleanup mandatory instead of implicit.

### 5. Finish-State Reconciliation Hardening

When `bd-ralph` invokes `implementation-review --auto-fix` in the finish phase, it must interpret the review output as a possible state transition.

Rules:
- if `Auto-fix applied=no` and `Metadata reconciliation required=no`, the workflow may continue without reconciliation,
- if either value indicates post-fix state drift, reconciliation is mandatory before finish completion.

The reconciliation step must:
1. update the parent bead `metadata.sha` to the post-fix `HEAD`,
2. compare `Post-fix changed files` against child-task ownership evidence,
3. update only the affected child beads' `metadata.git_sha`,
4. push Beads state, and
5. stop the workflow if reconciliation cannot be completed safely.

### 6. Child Ownership Interpretation

The orchestrator must not guess child ownership from review output alone. It should use the best available evidence in this order:

1. child bead plan section or task identity,
2. known owned files or changed-file evidence gathered during task completion,
3. explicit ambiguity handling when ownership cannot be resolved safely.

If ownership remains ambiguous, the orchestrator may update the parent SHA but must not silently rewrite unrelated child SHA metadata.

## Data Flow

### Plan Review → Execute

1. `plan-review --auto-fix` runs.
2. The review skill emits post-fix state.
3. `bd-ralph` verifies materialization into the execution workspace.
4. Only then does execution begin.

### Task Loop

1. An implementer works on one task.
2. Reviewers judge the current task diff.
3. Stale verdicts are discarded and retried with fresh context when needed.
4. On task completion, the child bead records the task-completion `git_sha`.
5. Completed/superseded agents are closed before the next loop continues.

### Finish Loop

1. `implementation-review --auto-fix` runs.
2. The review skill emits post-fix state and reconciliation requirement.
3. `bd-ralph` reconciles parent/child SHA metadata if needed.
4. Finish completion is allowed only after reconciliation succeeds.

## Error Handling

### Missing post-fix review output

If an automated review skill omits required post-fix state fields, the caller must treat the phase as failed rather than infer missing state.

### Stale review verdict

If a reviewer finding clearly points outside the current diff or current file state, it is a stale review problem. The controller should discard it and re-dispatch review with a fresher packet.

### Missing plan materialization

If plan-review changed the plan but the execution workspace still contains the older version, execution must stop instead of proceeding with mismatched inputs.

### Reconciliation failure

If finish-phase auto-fix changed the branch but parent/child SHA metadata cannot be reconciled safely, the workflow must stop before claiming final completion.

## Verification

This design is complete when the resulting implementation demonstrates the following:

1. `plan-review --auto-fix` emits explicit post-fix state,
2. `bd-ralph` verifies plan materialization before execution begins,
3. task-level reviewers receive current diff freshness inputs,
4. stale review findings are rejected instead of treated as implementation truth,
5. completed and superseded subagents are closed during long runs,
6. child task completion still records a task-level `git_sha`,
7. finish-phase `implementation-review --auto-fix` emits reconciliation signals,
8. `bd-ralph` updates parent and affected child SHA metadata before final completion.

## Risks and Mitigations

### Risk: review outputs become too verbose

**Mitigation:** keep the new fields in a compact machine-readable tail rather than expanding the main prose review body.

### Risk: child ownership is not explicit enough for safe reconciliation

**Mitigation:** prefer parent-only SHA updates plus explicit ambiguity reporting over guessing and rewriting unrelated child metadata.

### Risk: freshness checks become noisy

**Mitigation:** only classify a result as stale when it clearly does not match the current diff or file state; ambiguous cases should request context instead.

## Relationship to Existing Specs

This design is a follow-up to the 2026-04-08 subagent orchestration hardening work.

That earlier design hardened:
- target-worktree completion evidence,
- diff-scoped task review,
- and bounded reviewer timeout behavior.

This follow-up design hardens:
- post-fix state reporting from review-family skills,
- workspace materialization of reviewed plans,
- stale-review rejection,
- explicit subagent lifecycle cleanup,
- and finish-state SHA reconciliation.

It extends the same architecture rather than replacing it.
