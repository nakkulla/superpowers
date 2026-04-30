---
name: executing-plans
description: >-
  Use when you have a written implementation plan to execute in a separate session
  with review checkpoints. Accepts plan path or Beads issue ID as input.
  Natively supports Beads issue tracking when .beads/ exists.
argument-hint: "[plan-path | issue-id] [--auto] [--execution direct|subagent] [--workspace current|worktree] [--beads full|parent|skip] [--plan-review run|skip|if-needed] [--finishing run|skip]"
---

# Executing Plans

## Overview

Load plan, review critically, execute all tasks, report when complete.

**Beads Integration:** If `.beads/` directory exists in the project root, this skill automatically detects it and offers Beads issue tracking. All Beads sections below are conditional — when `.beads/` is absent or the user chooses to skip, standard TodoWrite-based tracking is used instead.

## Auto Mode

When invoked with `--auto`, this skill must not call AskUserQuestion.
Instead it reads explicit override flags from the caller.
If an override is absent and the choice is still ambiguous after inspecting the current environment, fail fast.

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
1. `bd list --all --metadata-field plan=<current-plan-path> --json` to find linked issues regardless of status
2. If exactly one match: `bd show <id> --json`으로 다시 확인하고 `metadata.plan`이 현재 plan path와 일치하면 linked bead로 사용
3. If the matched issue is a child bead:
   - default interactive branch: re-resolve to the intended parent bead or ask the user before proceeding
   - `--auto` branch: fail fast instead of asking if parent re-resolution is not unambiguous
4. If multiple matches:
   - default interactive branch: ask the user which issue to use; do not create a new issue until ambiguity is resolved
   - `--auto` branch: fail fast instead of asking
5. If no matches: proceed without linked bead context (the Beads integration choice in Step 0-E still applies)

A linked `metadata.plan` entry is only a plan-document pointer; it does not imply the plan has already passed review.

**Pre-spec follow-up guard:**

A Beads issue with `origin=brainstorming_scope_split` or `spec_policy=future_brainstorming_required` is not execution-ready. Do not infer implementation scope from that description-only follow-up issue. Stop and route it to the future brainstorming/spec workflow so it gets its own reviewed spec before planning or execution.

**0-B. Plan Review Gate (linked bead exists and lacks `reviewed:plan` label):**

Default interactive branch:
- AskUserQuestion: "이 plan은 아직 리뷰되지 않았습니다. Plan review를 먼저 실행할까요?"
- 1. Run plan-review, then continue
- 2. Skip and proceed to execution
- If chosen: invoke `plan-review`, then record `plan_content_hash=$(git hash-object <plan-path>)`, `plan_reviewed_at_sha=$(git rev-parse HEAD)`, and `reviewed:plan` on the linked parent bead.
- Skip this gate when: no linked bead, or issue already has `reviewed:plan` label with matching `plan_content_hash` and compatible `plan_reviewed_at_sha`.

`--auto` branch:
- Read `--plan-review run|skip|if-needed`.
- `run` → invoke `plan-review`, then record `plan_content_hash`, `plan_reviewed_at_sha`, and label the linked bead `reviewed:plan`.
- `skip` → continue without review.
- `if-needed` → run only when the linked bead exists and lacks `reviewed:plan`.
- If no linked bead exists, continue without review regardless of `--plan-review`.

**0-C. Execution Strategy:**

Default interactive branch:
- AskUserQuestion:
  1. Direct execution in this session (executing-plans)
  2. Subagent execution (subagent-driven-development)
- Subagent chosen: invoke `superpowers:subagent-driven-development` and exit this skill
- Direct execution chosen: **Announce:** "I'm using the executing-plans skill to implement this plan." Continue to 0-D.

`--auto` branch:
- Read `--execution direct|subagent`.
- `--execution subagent` → invoke `superpowers:subagent-driven-development` and exit this skill.
- `--execution direct` → announce direct execution and continue.
- If `--execution` is absent and the choice is not otherwise unambiguous, fail fast.

**0-D. Workspace:**

Default interactive branch:
- AskUserQuestion:
  1. Create a worktree (using-git-worktrees)
  2. Continue on the current branch
- Worktree chosen: invoke `superpowers:using-git-worktrees`
- Current branch chosen: proceed in place

`--auto` branch:
- Read `--workspace current|worktree`.
- `--workspace worktree` → invoke `superpowers:using-git-worktrees`.
- `--workspace current` → proceed in place.
- If `--workspace` is absent and the correct workspace is ambiguous, fail fast.

**0-E. Beads Integration (only when `.beads/` exists):**

Default interactive branch:
- AskUserQuestion:
  1. **Full** — parent + child tracking (seed-beads-from-plan + per-task claim/resolve)
  2. **Parent only** — track parent issue only (no child creation, close parent on completion)
  3. **Skip** — proceed without Beads integration

`--auto` branch:
- Read `--beads full|parent|skip`.
- `--beads full` → use parent + child tracking.
- `--beads parent` → use parent-only tracking.
- `--beads skip` → proceed without Beads integration.
- If `.beads/` exists and `--beads` is absent while integration policy remains ambiguous, fail fast.

If `.beads/` does not exist, skip this question and proceed with Beads integration OFF.

### Step 1: Load and Review Plan
1. Read plan file
2. Review critically - identify any questions or concerns about the plan
3. If concerns: Raise them with your human partner before starting
4. If no concerns: Create TodoWrite and proceed
5. **When Beads Full or Parent only and a linked parent bead exists:**
   - Claim the linked parent bead before execution begins: `bd update <parent-id> --claim`
   - If the parent bead is already `in_progress`, continue without changing it
6. **When Beads Full:**
   - Check for existing children: `bd children <parent-id> --json`
   - **If children exist (Resume):** Reconstruct Task→Bead mapping from existing children. Mark tasks corresponding to `resolved`/`closed` children as completed. Announce: "Resuming execution — N tasks already completed." Skip `seed-beads-from-plan`.
   - **If no children (Fresh start):** Invoke `seed-beads-from-plan` (pass plan path + parent issue ID). Receive and retain the mapping table (Task → Bead ID).

## skill_workflow Task Router

Before editing for each task, classify the task's `skill_workflow`. Use the linked issue, spec, or plan `skill_workflow` as the first input, then validate it against task paths and task text. If the recorded workflow conflicts with task evidence, stop and reconcile before editing.

A task requires `skill_workflow=writing_skills` when it edits a skill artifact path such as:

- `skills/*/SKILL.md`
- `skills/*/references/*`
- `skills/*/scripts/*`
- `skills/*/assets/*`
- skill eval fixtures or active skill contract tests
- agent/plugin skill manifests that affect skill behavior

A task requires `skill_workflow=skill_creator` when it creates a new skill, changes skill metadata, changes trigger/routing behavior, restructures skill resources, or performs eval-driven behavior iteration.

For tasks with `skill_workflow=writing_skills` or `skill_workflow=skill_creator`, invoke the required skill-edit discipline before editing:

```text
REQUIRED SUB-SKILL: superpowers:writing-skills
ALSO REQUIRED: skill-creator when the task changes metadata, triggers, routing behavior, resources, or eval-driven skill behavior.
```

This router does not skip plan authoring, Beads lifecycle, task verification, implementation review, or finishing workflows. It only controls how skill artifact tasks are executed. Do not create canonical v4 metadata named `skill_related` or `skill_creator_required`; migrate legacy inputs to `skill_workflow` when encountered.

### Step 2: Execute Tasks

For each task:
1. Mark as in_progress (TodoWrite)
2. **Beads Full:** `bd update <child-id> --claim`
3. Follow each step exactly (plan has bite-sized steps)
4. Run verifications as specified
5. Mark as completed (TodoWrite)
6. **Beads Full:** `bd update <child-id> --status resolved --set-metadata git_sha=$(git rev-parse HEAD)`

**Parent only mode:** Claim the parent bead once at the start of execution. Do not create or claim child beads. Parent close is handled in Step 3 by finishing-a-development-branch.

**bd dolt push timing:** Do NOT push after each task. Push once after the last task completes (in Step 3), or when execution is interrupted. This minimizes conflict risk and serialization overhead.

**bd write serialization:** bd write operations (`update`, `dolt push`) must not run in parallel. Complete the beads update for one task before proceeding to the next.

### Step 3: Complete Development

After all tasks complete and verified:
1. **Beads Full or Parent only:** `bd dolt push` (flush child resolved states and/or the parent claim state)
2. **Beads Full or Parent only:** Declare context: "이 작업은 Beads issue `<id>`에 연결되어 있습니다."
3. Announce: "I'm using the finishing-a-development-branch skill to complete this work."
4. **REQUIRED SUB-SKILL:** Use superpowers:finishing-a-development-branch
5. Follow that skill to verify tests, present options, execute choice
6. If `--finishing skip` is passed, stop after execution, return control to the caller, and do not invoke `finishing-a-development-branch`.

When implementation review is completed by the finishing workflow or caller, record v4 evidence on the linked parent bead:

```text
impl_reviewed_at_sha=<reviewed implementation HEAD>
impl_reviewed_diff_range=<base>..<head>
```

Do not advance these values without a new passing implementation review.

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

1. Keep current Beads states as-is (parent and child `resolved`/`in_progress`/`open` — do not roll back)
2. **Beads Full or Parent only:** `bd dolt push` (preserve parent claim and any child progress)
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
- **superpowers:using-git-worktrees** - Set up isolated workspace (when chosen in Step 0-D)
- **superpowers:writing-plans** - Creates the plan this skill executes
- **superpowers:finishing-a-development-branch** - Complete development after all tasks

**Optional workflow skills:**
- **superpowers:subagent-driven-development** - Delegate execution (when chosen in Step 0-C)
- **seed-beads-from-plan** - Create child beads from plan (Beads Full mode)
- **plan-review** - Review plan before execution (Step 0-B gate)
- **ho-create** - Generate handoff on interruption
