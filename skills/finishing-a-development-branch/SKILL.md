---
name: finishing-a-development-branch
description: Use when implementation is complete, all tests pass, and you need to decide how to integrate the work, including non-interactive `--auto` policy-driven completion for merge, PR, or cleanup
---

# Finishing a Development Branch

## Overview

Guide completion of development work by presenting clear options and handling chosen workflow.

**Core principle:** Verify tests → Present options → Execute choice → Clean up.

**Announce at start:** "I'm using the finishing-a-development-branch skill to complete this work."

`--auto` is supported for policy-driven non-interactive completion.

## Auto Mode

When invoked with `--auto`, this skill must not ask the user to choose an option.
The caller is responsible for passing explicit policy overrides such as `--action`, `--impl-review`, `--handoff`, `--close-children`, and `--close-parent`.
If a destructive action would be required and no explicit policy is provided, fail fast.

## The Process

### Step 0: Beads Context Detection

Detect Beads issue context via 3-step fallback:

1. **Conversation context** — If a Beads issue ID was passed from executing-plans (e.g., "이 작업은 Beads issue `<id>`에 연결되어 있습니다"), use it directly.
2. **Branch name matching** — If `.beads/` exists: `bd list --json`, search for an issue whose branch or metadata matches the current git branch name.
3. **No match** — Proceed with Beads OFF, even if `.beads/` exists.

If Beads ON (= issue detected, Full or Parent only): load issue context via `bd show <id> --json` (labels, deps, children).

### Step 1: Verify Tests

**Before presenting options, verify tests pass:**

```bash
# Run project's test suite
npm test / cargo test / pytest / go test ./...
```

**If tests fail:**
```
Tests failing (<N> failures). Must fix before completing:

[Show failures]

Cannot proceed with merge/PR until tests pass.
```

Stop. Don't proceed to Step 2.

**If tests pass:** Continue to Step 2.

### Step 2: Determine Base Branch

```bash
# Try common base branches
git merge-base HEAD main 2>/dev/null || git merge-base HEAD master 2>/dev/null
```

Or ask: "This branch split from main - is that correct?"

### Step 2.5: Implementation Review Gate

**Condition:** Beads ON AND issue lacks `reviewed:impl` label.

AskUserQuestion: "Implementation review를 실행할까요?"
1. Run implementation-review, then continue
2. Skip and proceed to options

Branch action은 이 review gate 뒤에만 온다. linked issue에 `reviewed:impl`가 없으면
merge / PR / keep / discard를 먼저 묻지 않는다.
If chosen: invoke `implementation-review` as an embedded sub-step of this finishing flow.
After the review result is shown and any `reviewed:impl` labeling is complete,
immediately continue in the same turn to Step 3.
Do not end the turn after the review message.
`implementation-review`가 현재 issue + resolved child들의 `reviewed:impl` 라벨링을 담당한다.
If issue already has `reviewed:impl` label, skip this gate entirely.

`--auto` branch:
- Read `--impl-review run|skip|if-needed`.
- `run` → invoke `implementation-review`.
- `skip` → continue without review.
- `if-needed` → run only when Beads is ON and the issue lacks `reviewed:impl`.
- If Beads is OFF, continue without review regardless of `--impl-review`.

### Step 3: Present Options

Present exactly these 4 options using AskUserQuestion (Codex: `request_user_input`):

```
Implementation complete. What would you like to do?

1. Merge back to <base-branch> locally
2. Push and create a Pull Request
3. Keep the branch as-is (I'll handle it later)
4. Discard this work

Which option?
```

**Don't add explanation** - keep options concise. Use AskUserQuestion so the user gets a structured choice UI, not plain text.

`--auto` branch:
- Read `--action merge|pr|keep|discard`.
- `--action merge` → execute Option 1.
- `--action pr` → execute Option 2.
- `--action keep` → execute Option 3.
- `--action discard` → execute Option 4 only when the caller has provided explicit destructive confirmation policy.
- If `--action` is absent, fail fast instead of presenting the 4-option prompt.

### Step 4: Execute Choice

#### Option 1: Merge Locally

```bash
# Switch to base branch
git checkout <base-branch>

# Pull latest
git pull

# Merge feature branch
git merge <feature-branch>

# Verify tests on merged result
<test command>

# If tests pass
git branch -d <feature-branch>
```

**Beads close flow (only when Beads ON):**

This is the only close-ready path. After merge succeeds and merged-result verification passes:

1. Verify child beads attached to the linked issue: `bd children <id> --json`
   - If unresolved children remain: AskUserQuestion "미완료 child가 있습니다. 그래도 close flow를 진행할까요?"
2. Present a post-merge close question using AskUserQuestion / `request_user_input`:
   - Close all (Recommended)
   - Keep resolved
   - Select manually
3. If the user chooses Close all:
   - close resolved child beads first with `bd close <child-id>`
   - then ask whether to close the current issue `<id>`
4. If the user chooses Keep resolved:
   - do not run `bd close`
   - keep current issue and child issues as-is
5. If the user chooses Select manually:
   - ask follow-up question(s) for child close scope and current issue close
6. Parent check: if this issue has a parent bead and all related child issues are now closed → AskUserQuestion whether to close the parent issue
7. `bd dolt push`

`--auto` branch for Option 1:
- Read `--close-children yes|no` and `--close-parent yes|no`.
- If unresolved children remain and no explicit close policy covers that case, fail fast instead of asking.
- `--close-children yes` → close resolved child issues after merge.
- `--close-children no` → keep child issues in `resolved` without prompting.
- `--close-parent yes` → close the linked issue after merge, and close its parent only when `--close-parent yes` explicitly authorizes that transition.
- `--close-parent no` → keep the linked issue and any parent issue in `resolved` without prompting.
- If the required close policy is absent, fail fast instead of falling back to AskUserQuestion.

Then: Cleanup worktree (Step 5)

#### Option 2: Push and Create PR

If this work is tied to a Beads issue, creating a PR does not count as merged — mark the linked issue `resolved`, not `closed`.

```bash
# Push branch
git push -u origin <feature-branch>

# Create PR
gh pr create --title "<title>" --body "$(cat <<'EOF'
## Summary
<2-3 bullets of what changed>

## Test Plan
- [ ] <verification steps>
EOF
)"
```

**Beads state (only when Beads ON):**

- Mark the linked issue `resolved`: `bd update <id> -s resolved`
- In `--auto` mode, `--action pr --close-children no --close-parent no` must allow the `resolved` transition without any close prompt.
- Persist the state: `bd dolt push`

Then: Cleanup worktree (Step 5)

#### Option 3: Keep As-Is

If this work is tied to a Beads issue, do not close it while the branch remains unmerged.

Report: "Keeping branch <name>. Worktree preserved at <path>."

**Don't cleanup worktree.**

#### Option 4: Discard

**Confirm first** using AskUserQuestion (Codex: `request_user_input`):
```
This will permanently delete:
- Branch <name>
- All commits: <commit-list>
- Worktree at <path>

Type 'discard' to confirm.
```

Wait for exact confirmation.

If confirmed:
```bash
git checkout <base-branch>
git branch -D <feature-branch>
```

**Beads state (only when Beads ON):**

AskUserQuestion: "Beads 이슈 상태를 어떻게 할까요?"
1. Close (작업 폐기)
2. Open 유지 (나중에 다시 시도)
3. Deferred (보류)

Execute chosen action:
- Close: `bd close <id>`
- Open: no action needed
- Deferred: `bd update <id> --defer "discarded branch"`
- Then: `bd dolt push`

Then: Cleanup worktree (Step 5)

### Step 4.5: Resolved Residual Check

**Condition:** After Option 1 completes AND Beads ON.

```bash
bd list -s resolved --json
```

If resolved issues remain:

AskUserQuestion: "resolved 상태 이슈가 N건 남아있습니다. Close할까요?"
[issue list displayed]
1. Close all
2. Select which to close
3. Skip

Execute chosen action, then `bd dolt push` if any changes made.

`--auto` branch:
- Reuse `--close-children` / `--close-parent` as the residual close policy.
- If those overrides do not explicitly authorize closing additional resolved issues, skip the residual close prompt and leave them as `resolved`.

### Step 5: Cleanup Worktree

**For Options 1, 2, 4:**

Check if in worktree:
```bash
git worktree list | grep $(git branch --show-current)
```

If yes:
```bash
git worktree remove <worktree-path>
```

**For Option 3:** Keep worktree.

### Step 6: Handoff Offer

**Condition:** After Option 1 or Option 2 completes.

AskUserQuestion: "Handoff 문서를 생성할까요?"
1. Generate handoff (ho-create)
2. Skip

If chosen: invoke `ho-create` skill.
**Beads ON:** `bd update <id> --set-metadata handoff=<path> --add-label has:handoff` → `bd dolt push`.

`--auto` branch:
- Read `--handoff yes|no`.
- `--handoff no` → suppress the extra handoff offer and stop.
- `--handoff yes` → invoke `ho-create` without prompting.

## Quick Reference

| Option | Merge | Push | Keep Worktree | Cleanup Branch | Beads Close |
|--------|-------|------|---------------|----------------|-------------|
| 1. Merge locally | ✓ | - | - | ✓ | ✓ (confirm) |
| 2. Create PR | - | ✓ | ✓ | - | - (resolved) |
| 3. Keep as-is | - | - | ✓ | - | - |
| 4. Discard | - | - | - | ✓ (force) | ask |

## Common Mistakes

**Skipping test verification**
- **Problem:** Merge broken code, create failing PR
- **Fix:** Always verify tests before offering options

**Open-ended questions**
- **Problem:** "What should I do next?" → ambiguous
- **Fix:** Present exactly 4 structured options

**Automatic worktree cleanup**
- **Problem:** Remove worktree when might need it (Option 2, 3)
- **Fix:** Only cleanup for Options 1 and 4

**No confirmation for discard**
- **Problem:** Accidentally delete work
- **Fix:** Require typed "discard" confirmation

## Red Flags

**Never:**
- Proceed with failing tests
- Merge without verifying tests on result
- Delete work without confirmation
- Force-push without explicit request

**Always:**
- Verify tests before offering options
- Present exactly 4 options
- Get typed confirmation for Option 4
- Clean up worktree for Options 1 & 4 only

## Integration

**Called by:**
- **subagent-driven-development** (Step 7) - After all tasks complete
- **executing-plans** (Step 3) - After all tasks complete

**Pairs with:**
- **using-git-worktrees** - Cleans up worktree created by that skill
- **implementation-review** - Review gate before presenting options (Step 2.5)
- **ho-create** - Generate handoff document (Step 6)
