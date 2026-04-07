# writing-plans stop-after-plan design

## Goal
Make `writing-plans` stop after plan creation in the normal interactive flow instead of immediately offering execution choices.

## Problem
`skills/writing-plans/SKILL.md` currently treats post-plan execution handoff as part of the default interactive flow. That causes the agent to move directly from plan authoring into `subagent-driven-development` or `executing-plans`, which blurs the boundary between planning and implementation.

## Desired Behavior
- In the default interactive branch, `writing-plans` should save the plan, complete self-review, perform any Beads linkage, report the plan path, and stop.
- It should not proactively offer execution choices in the same turn.
- Execution skills should run only when the user explicitly asks to execute the plan in a later turn.
- `--auto` should keep its existing stop-after-plan behavior.

## Scope
### In scope
- `skills/writing-plans/SKILL.md`
- `README.md` workflow wording
- Prompt fixtures that currently assume `writing-plans` proactively offers execution choices

### Out of scope
- Changing `executing-plans` or `subagent-driven-development`
- Rewriting historical specs, plans, or eval artifacts

## Acceptance Criteria
1. `skills/writing-plans/SKILL.md` no longer instructs the default interactive branch to offer execution choices.
2. The skill explicitly says to stop after reporting the saved plan path unless the user later asks to execute it.
3. `README.md` reflects that execution starts only when separately requested.
4. Prompt fixtures no longer encode the old automatic handoff wording.
