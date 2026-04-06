# Executing Plans Parent Claim Design

## Problem
`skills/executing-plans/SKILL.md` claims child beads during task execution, but direct `executing-plans` entry can leave the linked parent bead in `ready`. This creates an inconsistent state where children are `in_progress` or `resolved` while the parent issue still appears unclaimed.

## Goal
Ensure `executing-plans` claims the linked parent bead before task execution whenever Beads integration is active and a linked parent issue exists.

## Non-Goals
- No change to child claim/resolve behavior
- No change to `bd-execute` claim behavior
- No change to close/merge behavior in `finishing-a-development-branch`
- No change to resume semantics beyond preserving the parent claim

## Design
1. Keep linked-bead discovery in Step 0 exactly as-is.
2. In Step 1, after plan review passes and before task execution begins, claim the linked parent bead when Beads integration is `Full` or `Parent only`.
3. If the parent is already `in_progress`, proceed without an additional status change.
4. Preserve that parent claim with the same `bd dolt push` points already used for execution progress and interruption handling.
5. Continue claiming child beads per task in `Full` mode.
6. Keep `Parent only` mode child-free, but make its description accurate by ensuring the parent issue is actually tracked in-progress.

## Expected Outcome
- Direct `executing-plans` runs no longer leave the parent bead in `ready`
- `bd-execute` and direct `executing-plans` flows converge on the same parent status behavior
- `Parent only` wording matches actual behavior
