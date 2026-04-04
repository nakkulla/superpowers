---
name: executing-plans
description: >-
  Use when you have a written implementation plan to execute in a separate session
  with review checkpoints. Accepts plan path or Beads issue ID as input.
  Natively supports Beads issue tracking when .beads/ exists.
argument-hint: "[plan-path | issue-id]"
---

# Executing Plans

## Overview

Load plan, review critically, execute all tasks, report when complete.

**Beads Integration:** If `.beads/` directory exists in the project root, this skill automatically detects it and offers Beads issue tracking. All Beads sections below are conditional — when `.beads/` is absent or the user chooses to skip, standard TodoWrite-based tracking is used instead.

## The Process

### Step 0: Preflight Decisions

**0-A. Input Parsing:**

```
$ARGUMENTS:
  ends with .md  → plan path mode
  number/ID      → Beads issue ID mode (.beads/ required)
  empty           → error ("Provide a plan path or issue ID")
```

Issue ID mode:
1. `bd show <id> --json` → extract plan path from `metadata.plan`
2. If no plan path: error "This issue has no linked plan."

Plan path mode + `.beads/` exists:
1. `bd list --json` to find issues where `metadata.plan` matches the current plan path
2. If found: load issue context (remember as beads integration candidate)

**0-B. Execution Strategy (AskUserQuestion):**

How should this plan be executed?
1. Direct execution in this session (executing-plans)
2. Subagent execution (subagent-driven-development)

- Subagent chosen: invoke `superpowers:subagent-driven-development` and exit this skill
- Direct execution chosen: **Announce:** "I'm using the executing-plans skill to implement this plan." Continue to 0-C.

**0-C. Workspace (AskUserQuestion):**

Where should the work happen?
1. Create a worktree (using-git-worktrees)
2. Continue on the current branch

- Worktree chosen: invoke `superpowers:using-git-worktrees`
- Current branch chosen: proceed in place

**0-D. Beads Integration (AskUserQuestion, only when `.beads/` exists):**

`.beads/` detected — choose integration level:
1. **Full** — parent + child tracking (seed-beads-from-plan + per-task claim/resolve)
2. **Parent only** — track parent issue only (no child creation, close parent on completion)
3. **Skip** — proceed without Beads integration

If `.beads/` does not exist, skip this question and proceed with Beads integration OFF.

**0-E. Plan Review Gate (Beads Full or Parent only, issue lacks `reviewed:plan` label):**

AskUserQuestion: "이 plan은 아직 리뷰되지 않았습니다. Plan review를 먼저 실행할까요?"
1. Run plan-review, then continue
2. Skip and proceed to execution

If chosen: invoke `plan-review` skill, then `bd update <id> --add-label reviewed:plan`.
If issue already has `reviewed:plan` label, skip this gate entirely.

### Step 1: Load and Review Plan
1. Read plan file
2. Review critically - identify any questions or concerns about the plan
3. If concerns: Raise them with your human partner before starting
4. If no concerns: Create TodoWrite and proceed
5. **When Beads Full:**
   - Check for existing children: `bd children <parent-id> --json`
   - **If children exist (Resume):** Reconstruct Task→Bead mapping from existing children. Mark tasks corresponding to `resolved`/`closed` children as completed. Announce: "Resuming execution — N tasks already completed." Skip `seed-beads-from-plan`.
   - **If no children (Fresh start):** Invoke `seed-beads-from-plan` (pass plan path + parent issue ID). Receive and retain the mapping table (Task → Bead ID).

### Step 2: Execute Tasks

For each task:
1. Mark as in_progress (TodoWrite)
2. **Beads Full:** `bd update <child-id> --claim`
3. Follow each step exactly (plan has bite-sized steps)
4. Run verifications as specified
5. Mark as completed (TodoWrite)
6. **Beads Full:** `bd update <child-id> --status resolved --set-metadata git_sha=$(git rev-parse HEAD)`

**Parent only mode:** No child claim/resolve — track progress via TodoWrite only. Parent close is handled in Step 3 by finishing-a-development-branch.

**bd dolt push timing:** Do NOT push after each task. Push once after the last task completes (in Step 3), or when execution is interrupted. This minimizes conflict risk and serialization overhead.

**bd write serialization:** bd write operations (`update`, `dolt push`) must not run in parallel. Complete the beads update for one task before proceeding to the next.

### Step 3: Complete Development

After all tasks complete and verified:
1. **Beads Full:** `bd dolt push` (flush all resolved states from Step 2)
2. **Beads Full or Parent only:** Declare context: "이 작업은 Beads issue `<id>`에 연결되어 있습니다."
3. Announce: "I'm using the finishing-a-development-branch skill to complete this work."
4. **REQUIRED SUB-SKILL:** Use superpowers:finishing-a-development-branch
5. Follow that skill to verify tests, present options, execute choice

## When to Stop and Ask for Help

**STOP executing immediately when:**
- Hit a blocker (missing dependency, test fails, instruction unclear)
- Plan has critical gaps preventing starting
- You don't understand an instruction
- Verification fails repeatedly

**Ask for clarification rather than guessing.**

## When to Revisit Earlier Steps

**Return to Review (Step 1) when:**
- Partner updates the plan based on your feedback
- Fundamental approach needs rethinking

**Don't force through blockers** - stop and ask.

## Interrupted Execution

When execution is stopped before all tasks complete (blocker, user request, session end):

1. Keep current child states as-is (resolved/in_progress/open — do not roll back)
2. **Beads Full:** `bd dolt push` (preserve progress)
3. Suggest handoff creation: "실행이 중단되었습니다. Handoff 문서를 생성할까요?" → invoke `ho-create` skill if accepted

## Remember
- Review plan critically first
- Follow plan steps exactly
- Don't skip verifications
- Reference skills when plan says to
- Stop when blocked, don't guess
- Never start implementation on main/master branch without explicit user consent

## Integration

**Required workflow skills:**
- **superpowers:using-git-worktrees** - Set up isolated workspace (when chosen in Step 0-C)
- **superpowers:writing-plans** - Creates the plan this skill executes
- **superpowers:finishing-a-development-branch** - Complete development after all tasks

**Optional workflow skills:**
- **superpowers:subagent-driven-development** - Delegate execution (when chosen in Step 0-B)
- **seed-beads-from-plan** - Create child beads from plan (Beads Full mode)
- **plan-review** - Review plan before execution (Step 0-E gate)
- **ho-create** - Generate handoff on interruption
