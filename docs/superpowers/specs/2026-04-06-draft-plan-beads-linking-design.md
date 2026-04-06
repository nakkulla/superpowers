# Draft Plan Immediate Beads Linking Design

**Status:** Draft for review  
**Date:** 2026-04-06

## Problem

`writing-plans` currently links `metadata.plan` only after the plan review loop passes.  
This makes plan tracking inconsistent with spec tracking:

- `brainstorming` links `spec-id` to the parent bead as soon as the spec is ready
- `writing-plans` delays plan linkage until after plan review

As a result, draft plans can exist on disk without an issue-level pointer, which weakens traceability during the review window.

## Goal

Register the plan path on the parent Beads issue immediately after the plan file is written, while preserving the existing review gate for execution.

## Non-Goals

- Removing the `reviewed:plan` gate from execution
- Introducing a new metadata field such as `plan_draft` or `plan_status`
- Changing child-bead restrictions for plan linkage
- Changing spec linkage behavior

## Current Behavior

### `brainstorming`

- Writes the spec
- Links `spec-id` to the Beads parent issue after spec review
- Treats `spec-id` as the canonical pointer from issue → spec

### `writing-plans`

- Writes the plan
- Performs self-review
- Defers `metadata.plan` linking until after the plan review loop passes

### `executing-plans`

- Uses `metadata.plan` to resolve a linked plan
- Uses the `reviewed:plan` label as the review gate before execution

## Proposed Behavior

### Semantic Model

- `metadata.plan` means: the issue's currently linked plan document
- `reviewed:plan` means: the linked plan has passed plan review and is ready to execute without additional plan-review prompting

This change intentionally separates:

1. **document linkage timing** — when the issue starts pointing at the plan
2. **execution readiness** — whether the plan has passed review

### `writing-plans` changes

When `.beads/` exists and the parent issue can be safely resolved:

1. Save the plan file
2. Run the built-in self-review
3. Resolve the parent bead
4. Immediately set:
   - `metadata.plan=<path>`
   - label `has:plan`
5. Re-check that `metadata.plan` is set correctly
6. `bd dolt push`
7. Continue with the existing user-facing handoff

This linkage no longer waits for the plan review loop to pass.

### `executing-plans` behavior

No functional relaxation of the review gate:

- if a linked bead exists and lacks `reviewed:plan`, keep the current plan-review gate
- if `reviewed:plan` is present, execution can proceed without that extra gate

`executing-plans` should therefore treat `metadata.plan` as a document pointer, not as proof that the plan is reviewed.

## Parent/Child Safety Rules

The parent-only rule remains unchanged:

- attach `metadata.plan` only to the parent bead
- never attach `metadata.plan` to a child bead
- if a matched issue is a child, re-resolve to the intended parent or ask the user

## Auto Mode

`writing-plans --auto` should keep its current safety rule:

- if the parent issue can be resolved safely, link immediately
- if the parent issue cannot be resolved safely, fail fast instead of guessing

## Rationale

This design gives spec and plan a more consistent UX:

- spec gets linked as soon as it becomes the working document
- plan also gets linked as soon as it becomes the working document

At the same time, it avoids collapsing "linked" and "reviewed" into the same concept.  
That preserves execution safety without requiring new metadata fields.

## Required Skill Updates

### `skills/writing-plans/SKILL.md`

Update the Beads linkage section so that:

- immediate parent-bead linkage happens after the plan is written and self-reviewed
- the wording no longer says "Post-Plan-Review"
- `metadata.plan` is described as immediate linkage, not post-review linkage

### `skills/executing-plans/SKILL.md`

Review for wording consistency so it is clear that:

- `metadata.plan` may reference a draft plan
- `reviewed:plan` remains the review gate

If the current wording already supports this model, only minimal clarification should be made.

## Verification

1. Read `skills/writing-plans/SKILL.md` and confirm the linkage step is moved earlier
2. Read `skills/executing-plans/SKILL.md` and confirm the review gate still depends on `reviewed:plan`
3. Verify no instruction now implies that `metadata.plan` alone means "ready to execute"
4. If related docs or evals explicitly encode the old semantics, update only the minimum necessary references

## Risks and Mitigations

### Risk: `metadata.plan` is interpreted as execution approval

**Mitigation:** keep `reviewed:plan` as the explicit gate in `executing-plans`.

### Risk: wrong bead gets linked

**Mitigation:** retain existing parent-only resolution and fail-fast behavior in auto mode.

### Risk: downstream docs still describe old timing

**Mitigation:** do a targeted wording pass on directly affected skill documentation.
