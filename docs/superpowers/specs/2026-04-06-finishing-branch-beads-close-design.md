# Finishing Branch Beads Close Design

## Problem
`skills/finishing-a-development-branch/SKILL.md` currently describes a merge close flow that asks to close the current Beads issue before closing any parent issue, and it does not explicitly say to close child issues first. For PR creation, it says to keep the issue open or mark it `resolved`, but it does not clearly make the linked parent issue transition from `in_progress` to `resolved`.

## Goal
Make the Beads status flow align with delivery semantics:
- Local merge closes related child issues first, then the linked issue, then any higher-level parent if applicable.
- PR creation marks the linked issue `resolved` instead of leaving it `in_progress`.

## Non-Goals
- No change to test verification or branch handling
- No change to discard flow
- No change to how `executing-plans` marks child beads `resolved`

## Design
1. Rewrite the merge close flow so it starts by checking child beads attached to the linked issue.
2. If child beads exist, close merged/resolved child issues before asking to close the linked issue itself.
3. After child closure, ask to close the linked issue.
4. If the linked issue has a parent and all siblings/children are now closed, ask to close that parent as a final step.
5. In the PR path, explicitly mark the linked Beads issue `resolved` and persist that state with `bd dolt push`.

## Expected Outcome
- Merge locally behaves like a full completion path: child first, then issue, then parent
- PR creation leaves the issue in the correct post-implementation state: `resolved`
- The Beads workflow wording matches the intended state machine more closely
