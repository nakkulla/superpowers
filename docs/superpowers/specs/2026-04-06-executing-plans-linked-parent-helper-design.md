# Executing Plans Linked Parent Helper Design

## Problem
`skills/executing-plans/SKILL.md` currently describes linked parent lookup with a simple `bd list --json` + `metadata.plan` match, but does not require a canonical helper or distinguish lookup failure from a verified zero-match result. In practice, an inline shell + Python pattern can silently return an empty match set when JSON plumbing is wrong. That causes two user-visible failures:

1. The workflow incorrectly concludes that no linked parent bead exists.
2. The plan-review gate is skipped even when the real parent bead exists and lacks `reviewed:plan`.

## Goal
Make linked parent lookup in `executing-plans` deterministic, verifiable, and helper-first so that:
- a real linked parent bead is found reliably,
- lookup failure is surfaced as an error rather than treated as "no linked bead",
- the plan-review gate runs whenever a verified linked parent exists without `reviewed:plan`.

## Non-Goals
- No full shared parent-resolution abstraction across every Beads-aware skill yet
- No change to child bead creation or resume logic in `seed-beads-from-plan`
- No change to merge/close behavior in `finishing-a-development-branch`
- No change to issue-ID mode beyond reusing the same verified result model where practical

## Design

### 1. Add an executing-plans-local helper script
Create `skills/executing-plans/scripts/resolve_linked_parent_bead.py`.

This helper owns plan-path-based parent lookup for `executing-plans` only. The workflow should not hand-roll inline JSON parsing for this lookup anymore.

### 2. Define a stable helper contract
Input:
- `plan_path`

Output JSON:
- `status`: one of `ok | none | multiple | error`
- `parent_id`: set only for `ok`
- `matches`: candidate summary list for `ok` and `multiple`
- `reason`: short diagnostic text for `error` and optional for other statuses

Example:
```json
{
  "status": "ok",
  "parent_id": "repo-123",
  "matches": [
    {
      "id": "repo-123",
      "title": "Fix executing-plans linked parent lookup"
    }
  ]
}
```

### 3. Canonical matching rules
The helper should:
1. call `bd list --json` itself,
2. parse JSON inside Python,
3. normalize the input plan path,
4. normalize each candidate issue's `metadata.plan` after removing any `#anchor` suffix,
5. treat only parent issues as direct matches,
6. return `multiple` when more than one parent matches,
7. return `error` when lookup cannot be verified.

This keeps `executing-plans` from conflating malformed lookup execution with a real zero-match case.

### 4. Update executing-plans Step 0-A
In plan-path mode with `.beads/` present, `executing-plans` should call the helper script instead of embedding ad-hoc `bd list --json` parsing.

Step 0-A semantics become:
- `ok` → remember linked parent bead
- `none` → continue as verified no-linked-parent case
- `multiple` → ask the user to choose the intended parent bead
- `error` → stop and report the lookup failure

### 5. Strengthen the plan-review gate
Step 0-B should run immediately after linked parent resolution and before execution strategy / workspace / Beads integration questions.

Rule:
- If a **verified** linked parent bead exists and lacks `reviewed:plan`, ask whether to run `plan-review` first.
- Skip this gate only when the helper returned verified `none`, or the linked parent already has `reviewed:plan`.
- Do not skip this gate because of lookup uncertainty.

### 6. Keep scope intentionally narrow
This helper starts as an `executing-plans` implementation detail.

If later work needs the same normalized parent-resolution behavior in two or more other workflows, we can extract a shared helper then. That follow-up is intentionally out of scope for this change.

## File Changes
- Create: `skills/executing-plans/scripts/resolve_linked_parent_bead.py`
- Modify: `skills/executing-plans/SKILL.md`
- Optional follow-up only if needed later: shared helper extraction

## Expected Outcome
- `executing-plans` no longer misclassifies lookup failures as "no linked bead"
- Existing linked parent beads are found reliably from `metadata.plan`
- The plan-review prompt appears when a verified linked parent exists without `reviewed:plan`
- Future changes to linked-parent matching happen in one helper instead of repeated shell snippets

## Testing Strategy
1. **Single parent match**
   - Helper returns `ok` with the correct `parent_id`.
2. **Verified zero match**
   - Helper returns `none`.
3. **Multiple matches**
   - Helper returns `multiple` with candidate summaries.
4. **Lookup failure**
   - Simulated malformed or failed `bd` output returns `error`.
5. **Anchor handling**
   - `metadata.plan` values with `#task-n` do not break parent matching.
6. **Workflow behavior**
   - `executing-plans` asks the plan-review question when helper returns `ok` and the linked parent lacks `reviewed:plan`.

## Risks and Mitigations
- **Risk:** Another workflow reimplements slightly different parent matching.
  - **Mitigation:** Document this helper as the canonical `executing-plans` resolver and leave an explicit future extraction path.
- **Risk:** The helper becomes too smart too early.
  - **Mitigation:** Limit it to `executing-plans` lookup only; do not absorb child seeding or broader Beads orchestration.
