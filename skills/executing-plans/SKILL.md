---
name: executing-plans
description: Use when you have a written implementation plan to execute in a separate session with review checkpoints
---

# Executing Plans

## Overview

Load plan, review critically, execute all tasks, report when complete.

**Announce at start:** "I'm using the executing-plans skill to implement this plan."

## The Process

### Step 0: Preflight Decisions

**0-A. Input Parsing:**

```
$ARGUMENTS 분석:
  .md로 끝남  → plan path 모드
  숫자/ID     → Beads issue ID 모드 (.beads/ 필수)
  없음        → 에러 ("plan path 또는 issue ID를 지정하세요")
```

Issue ID 모드:
1. `bd show <id> --json` → `metadata.plan` 필드에서 plan path 추출
2. plan path 없으면 에러: "이 이슈에 plan이 연결되어 있지 않습니다."

Plan path 모드 + `.beads/` 존재:
1. `bd list --json`으로 `metadata.plan`이 현재 plan path와 일치하는 이슈 검색
2. 있으면 해당 이슈의 context 로드 (beads 연동 후보로 기억)

**0-B. Execution Strategy (AskUserQuestion):**

이 plan을 어떻게 실행할까요?
1. 이 세션에서 직접 실행 (executing-plans)
2. Subagent로 실행 (subagent-driven-development)

- "Subagent로 실행" 선택 시: `superpowers:subagent-driven-development` invoke 후 이 스킬 종료
- "직접 실행" 선택 시: 계속 진행

**0-C. Workspace (AskUserQuestion):**

어디에서 작업할까요?
1. 워크트리 생성 (using-git-worktrees 사용)
2. 현재 브랜치에서 진행

- "워크트리 생성" 선택 시: `superpowers:using-git-worktrees` invoke
- "현재 브랜치" 선택 시: 현재 위치에서 그대로 진행

**0-D. Beads Integration (AskUserQuestion, `.beads/` 존재 시만):**

Beads 이슈를 연결할까요?
1. Beads 이슈 연결 (seed-beads-from-plan으로 child issue 생성 + task별 추적)
2. Beads 연동 없이 진행

`.beads/`가 없으면 이 질문을 건너뛰고 Beads 연동 OFF로 진행.

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
