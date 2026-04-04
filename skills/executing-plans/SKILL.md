---
name: executing-plans
description: Use when you have a written implementation plan to execute in a separate session with review checkpoints
---

# Executing Plans

## Overview

Load plan, review critically, execute all tasks, report when complete.

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

Connect Beads issues?
1. Connect Beads issues (create child issues via seed-beads-from-plan + per-task tracking)
2. Proceed without Beads integration

If `.beads/` does not exist, skip this question and proceed with Beads integration OFF.

### Step 1: Load and Review Plan
1. Read plan file
2. Review critically - identify any questions or concerns about the plan
3. If concerns: Raise them with your human partner before starting
4. If no concerns: Create TodoWrite and proceed

### Step 2: Execute Tasks

For each task:
1. Mark as in_progress
2. Follow each step exactly (plan has bite-sized steps)
3. Run verifications as specified
4. Mark as completed

### Step 3: Complete Development

After all tasks complete and verified:
- Announce: "I'm using the finishing-a-development-branch skill to complete this work."
- **REQUIRED SUB-SKILL:** Use superpowers:finishing-a-development-branch
- Follow that skill to verify tests, present options, execute choice

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

## Remember
- Review plan critically first
- Follow plan steps exactly
- Don't skip verifications
- Reference skills when plan says to
- Stop when blocked, don't guess
- Never start implementation on main/master branch without explicit user consent

## Integration

**Required workflow skills:**
- **superpowers:using-git-worktrees** - REQUIRED: Set up isolated workspace before starting
- **superpowers:writing-plans** - Creates the plan this skill executes
- **superpowers:finishing-a-development-branch** - Complete development after all tasks
