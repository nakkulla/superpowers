# Subagent Orchestration Contract Hardening Design
Parent bead: superpowers-86t

**Status:** Draft for review
**Date:** 2026-04-08

## Problem

`bd-ralph` can now route into `subagent-driven-development`, but the execution contract remains too permissive in three places:

1. implementer completion can be accepted from a natural-language report even when the target worktree state does not actually match the report,
2. spec and code-quality reviewers can drift from task-scoped diff review into whole-file review and incorrectly flag pre-existing code, and
3. reviewer waits can stretch into long stalls because timeout handling is not described as a bounded retry policy.

These failures do not require a workflow redesign. They come from underspecified handoff contracts between the controller, implementer, and reviewers.

## Goal

Harden the existing subagent orchestration contract with minimal changes so that:

- implementer completion is grounded in target-worktree evidence,
- reviewers judge only the task-scoped diff for the current task,
- retry behavior stays bounded when a reviewer times out.

## Non-Goals

- Adding runtime enforcement code or new tools
- Adding contract tests, eval harnesses, or pressure-test scripts in this work
- Redesigning the `bd-ralph` or `subagent-driven-development` workflow
- Changing Beads data model or issue lifecycle
- Reworking model selection or role structure for implementer/reviewer subagents

## Current Failure Pattern

### 1. Completion without trustworthy workspace evidence

The controller currently relies on implementer status reporting (`DONE`, `DONE_WITH_CONCERNS`, etc.) without requiring a standard evidence bundle from the exact target workspace. That leaves room for:

- work performed in the wrong workspace,
- stale assumptions about branch or cwd,
- claims of passing verification without corresponding raw command output.

### 2. Review scope drift

The reviewer prompts tell subagents to inspect the implementation carefully, but they do not explicitly anchor the review to a base SHA and task-scoped diff. In practice this allows reviewers to:

- inspect the entire file rather than the current task's changes,
- flag pre-existing code not introduced by the current task,
- treat unrelated scope as a task failure.

### 3. Unbounded review waiting

The current skills mention review-loop failure in general but do not describe a narrow timeout response for slow reviewers. This encourages long waits and ad-hoc retries instead of a small, explicit retry budget.

## Design Principles

### Evidence over narrative

A natural-language completion report is useful context, but it is not sufficient proof of completion. The controller should only advance when the reported completion matches observable target-worktree evidence.

### Diff over file

Task review should be scoped to the changes introduced for that task. Reviewers should not turn unchanged pre-existing code into a task failure unless the current task modified that area.

### Bounded retries

Timeout recovery should be explicit and small. The workflow should allow one tighter retry with a smaller packet, then fail fast instead of drifting into prolonged waiting.

## Proposed Changes

### 1. `skills/subagent-driven-development/implementer-prompt.md`

Strengthen the implementer prompt so that `DONE` and `DONE_WITH_CONCERNS` require explicit target-worktree evidence.

Add requirements that the implementer report include:

- exact `pwd`,
- exact `git branch --show-current`,
- task-scoped diff evidence from the target workspace,
- raw output of the verification commands they actually ran.

Also explicitly state that:

- edits and verification must happen from the exact provided directory,
- working in a different workspace requires reporting `BLOCKED` rather than `DONE`,
- absence of target-worktree diff means completion is not valid.

### 2. `skills/subagent-driven-development/spec-reviewer-prompt.md`

Strengthen the spec-review prompt so that spec compliance is judged against a task-scoped diff, not a whole file.

Add explicit input fields for:

- `BASE_SHA`,
- `CHANGED_FILES`,
- optional changed-hunks summary.

Add explicit reviewer rules:

- review only the changes introduced for this task relative to `BASE_SHA`,
- do not flag pre-existing code outside the touched diff,
- if the diff scope is unclear, return `NEEDS_CONTEXT` instead of broad failure.

### 3. `skills/subagent-driven-development/code-quality-reviewer-prompt.md`

Apply the same scope discipline to code-quality review.

Clarify that the reviewer should:

- report only issues introduced by the task's diff relative to `BASE_SHA`,
- avoid unrelated pre-existing issues,
- prefer concrete file:line references within touched scope.

### 4. `skills/subagent-driven-development/SKILL.md`

Harden the skill-level controller contract without changing the overall workflow shape.

#### DONE handling

Update the `DONE` guidance so that the controller must validate target-worktree evidence before dispatching spec review.

If the implementer report and target worktree do not match, the controller must treat that as invalid completion and re-dispatch instead of reviewing a false state.

#### Timeout policy

Add a bounded policy for reviewer timeout in `--auto` mode:

- one retry is allowed using a smaller, more explicit context packet,
- if that retry still times out or cannot judge safely, fail fast with a concrete error report.

#### Red flags

Add explicit red flags against:

- accepting `DONE` without target-worktree diff and raw verification output,
- allowing whole-file review when the task should be judged against a bounded diff.

### 5. `skills/bd-ralph/SKILL.md`

Harden the parent orchestrator contract so that `bd-ralph` does not accept a subagent execution phase as complete based only on natural-language summary.

#### Phase 2 execution requirement

When the execution strategy is `subagent`, require the parent to observe:

- canonical worktree path,
- task-scoped diff evidence,
- target-worktree verification results,
- execution completion summary.

#### Workflow-family expected outputs

Add an explicit `subagent-driven-development` subsection under workflow-family expected outputs with:

Expected outputs:
- canonical worktree path,
- review baseline (`BASE_SHA` or equivalent),
- task-scoped diff evidence from the target worktree,
- raw verification results from the target worktree,
- execution completion summary.

Abort if:
- completion is reported but target-worktree diff is missing,
- reported cwd or branch does not match the canonical worktree,
- review findings clearly refer to pre-existing code outside the task diff,
- reviewer timeout persists after one smaller-packet retry.

#### Parent-side interpretation rule

Add one explicit statement that natural-language completion reports are insufficient by themselves; phase advancement requires observable target-worktree artifacts.

## Data Flow

### Implementer loop

1. Controller dispatches implementer with exact target worktree and task scope.
2. Implementer performs work in that workspace.
3. Implementer reports status plus evidence bundle.
4. Controller validates the evidence against the actual target worktree.
5. Only then does the controller dispatch review.

### Review loop

1. Controller passes `BASE_SHA` and task-scoped diff context to reviewer.
2. Reviewer inspects only the relevant diff.
3. If scope is unclear, reviewer returns `NEEDS_CONTEXT`.
4. If reviewer times out, controller retries once with a smaller packet.
5. If retry also fails, the task fails fast instead of drifting.

## Error Handling

### Invalid completion report

If the implementer reports `DONE` but the target worktree does not contain matching diff or verification evidence, the controller must not enter review. It must re-dispatch or fail the task with a concrete mismatch summary.

### Reviewer scope mismatch

If a reviewer returns findings that clearly refer to unchanged pre-existing code outside the task diff, the controller should treat that as a review-scope failure, not as implementation failure.

### Reviewer timeout

Timeout is handled as a bounded orchestration error, not an open-ended waiting state.

## Verification

This design is complete when the resulting implementation updates the following behavior contracts:

1. `implementer-prompt.md` requires target-worktree evidence before valid `DONE`
2. `spec-reviewer-prompt.md` requires `BASE_SHA`-scoped diff review
3. `code-quality-reviewer-prompt.md` limits findings to issues introduced by the task diff
4. `subagent-driven-development/SKILL.md` requires controller validation of `DONE`
5. `subagent-driven-development/SKILL.md` documents a one-retry timeout policy in `--auto`
6. `bd-ralph/SKILL.md` adds `subagent-driven-development` expected outputs and abort conditions
7. `bd-ralph/SKILL.md` states that natural-language completion reports are insufficient without observable artifacts

## Risks and Mitigations

### Risk: prompt churn spills beyond minimal scope

**Mitigation:** limit changes to evidence requirements, diff scoping, and timeout policy wording only.

### Risk: reviewers become too strict to proceed

**Mitigation:** allow `NEEDS_CONTEXT` when diff scope is unclear instead of forcing a speculative failure.

### Risk: future work still needs runtime enforcement

**Mitigation:** keep runtime guards and contract tests explicitly out of scope so they can be evaluated separately as a follow-up.

## Relationship to Existing Specs

This design is a follow-up refinement to the existing 2026-04-08 work that introduced `subagent-driven-development` as a `bd-ralph` execution path. It does not replace that routing design. It tightens the orchestration contract around the same architecture.
