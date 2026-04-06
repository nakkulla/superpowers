# Brainstorming Skill Routing Simplification Design

## Problem
`skills/brainstorming/SKILL.md` currently special-cases skill and agent targets by forcing a user-facing `skill-creator` vs `writing-plans` decision. This adds a routing question in the brainstorming phase even though `skills/writing-plans/SKILL.md` already contains the downstream rules for skill work.

## Goal
Make `brainstorming` always transition to `writing-plans`, and let `writing-plans` decide whether `writing-skills` and `skill-creator` are needed for `SKILL.md` work.

## Non-Goals
- No change to Beads integration
- No change to `writing-plans` logic
- No change to visual companion or spec review flow

## Design
1. Remove the brainstorming hard gate that requires asking the user to choose between `skill-creator` and `writing-plans`.
2. Remove duplicated wording in the terminal-state, user-review-gate, and implementation sections that repeats the same routing rule.
3. Keep the default implementation transition as `writing-plans` only.
4. Rely on existing `writing-plans` guidance for `SKILL.md` tasks:
   - `writing-skills` is required
   - `skill-creator` is additionally used for new skill creation or eval-driven iteration

## Expected Outcome
- Brainstorming stays focused on design/spec creation
- User no longer sees an internal routing choice during brainstorming
- Skill-specific routing logic lives in one place: `writing-plans`
