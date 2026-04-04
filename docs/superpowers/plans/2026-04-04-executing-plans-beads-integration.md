# executing-plans Beads 통합 + UX 개선 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** executing-plans 스킬에 Beads 네이티브 연동, 워크스페이스 선택, 실행 전략 선택을 추가한다.

**Architecture:** 기존 3단계(Load → Execute → Complete)에 Step 0(Preflight Decisions)를 추가하고, Step 1과 Step 2에 beads 연동 로직을 조건부로 삽입. `.beads/` 존재 + 사용자 opt-in 시에만 활성화되어 기존 동작에 영향 없음.

**Tech Stack:** SKILL.md (마크다운 스킬 정의), bd CLI, seed-beads-from-plan 스킬

**Target files:**
- Source: `skills/executing-plans/SKILL.md` (레포)
- Sync targets: `~/.claude/plugins/marketplaces/superpowers-custom/skills/executing-plans/SKILL.md`, `~/.claude/plugins/cache/superpowers-custom/skills/executing-plans/SKILL.md`

---

### Task 1: Step 0 — Preflight Decisions 추가

**REQUIRED SUB-SKILL:** Use superpowers:writing-skills

**Files:**
- Modify: `skills/executing-plans/SKILL.md:1-71`

- [ ] **Step 1: 현재 SKILL.md 읽기 및 구조 확인**

Read `skills/executing-plans/SKILL.md`. 현재 구조:
- frontmatter (1-4)
- Overview (6-14)
- The Process: Step 1, 2, 3 (16-37)
- When to Stop (39-47)
- When to Revisit (49-55)
- Remember (57-63)
- Integration (65-71)

- [ ] **Step 2: Note 블록을 Step 0 섹션으로 교체**

현재 14행의 `**Note:** Tell your human partner...` 블록을 제거하고, Overview 다음에 Step 0 섹션을 삽입.

기존:
```markdown
**Note:** Tell your human partner that Superpowers works much better with access to subagents. The quality of its work will be significantly higher if run on a platform with subagent support (such as Claude Code or Codex). If subagents are available, use superpowers:subagent-driven-development instead of this skill.

## The Process

### Step 1: Load and Review Plan
```

변경:
```markdown
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
```

- [ ] **Step 3: Edit 도구로 실제 교체 실행**

Edit 도구를 사용하여 `skills/executing-plans/SKILL.md`에서 old_string/new_string으로 교체:
- old_string: `**Note:** Tell your human partner...` 부터 `## The Process` 전까지
- new_string: 위의 Step 0 섹션 전체

- [ ] **Step 4: 변경 확인**

Read `skills/executing-plans/SKILL.md`로 Step 0이 올바르게 삽입되었는지 확인. Overview → Step 0 → Step 1 순서가 맞는지 검증.

- [ ] **Step 5: 커밋**

```bash
git add skills/executing-plans/SKILL.md
git commit -m "feat(executing-plans): add Step 0 preflight decisions

Add execution strategy, workspace, and beads integration choices
before plan execution begins."
```

---

### Task 2: Step 1 — Beads Seeding 추가

**REQUIRED SUB-SKILL:** Use superpowers:writing-skills

**Files:**
- Modify: `skills/executing-plans/SKILL.md` (Step 1 섹션)

- [ ] **Step 1: 현재 Step 1 섹션 확인**

Read `skills/executing-plans/SKILL.md`에서 Step 1 섹션 확인. 현재:
```markdown
### Step 1: Load and Review Plan
1. Read plan file
2. Review critically - identify any questions or concerns about the plan
3. If concerns: Raise them with your human partner before starting
4. If no concerns: Create TodoWrite and proceed
```

- [ ] **Step 2: Beads seeding 로직 추가**

기존 Step 1 끝에 beads seeding 블록을 추가.

기존:
```markdown
### Step 1: Load and Review Plan
1. Read plan file
2. Review critically - identify any questions or concerns about the plan
3. If concerns: Raise them with your human partner before starting
4. If no concerns: Create TodoWrite and proceed
```

변경:
```markdown
### Step 1: Load and Review Plan
1. Read plan file
2. Review critically - identify any questions or concerns about the plan
3. If concerns: Raise them with your human partner before starting
4. If no concerns: Create TodoWrite and proceed
5. **Beads 연동 ON일 때:**
   - Invoke `seed-beads-from-plan` (plan path + parent issue ID 전달)
   - 매핑 테이블(Task → Bead ID) 수신 및 보관
```

- [ ] **Step 3: Edit 도구로 실제 교체 실행**

Edit 도구로 Step 1 내용을 교체.

- [ ] **Step 4: 변경 확인**

Read로 Step 1이 올바르게 수정되었는지 확인.

- [ ] **Step 5: 커밋**

```bash
git add skills/executing-plans/SKILL.md
git commit -m "feat(executing-plans): add beads seeding to Step 1

Invoke seed-beads-from-plan to create child beads when beads
integration is enabled."
```

---

### Task 3: Step 2 — Beads Tracking 추가

**REQUIRED SUB-SKILL:** Use superpowers:writing-skills

**Files:**
- Modify: `skills/executing-plans/SKILL.md` (Step 2 섹션)

- [ ] **Step 1: 현재 Step 2 섹션 확인**

Read `skills/executing-plans/SKILL.md`에서 Step 2 섹션 확인. 현재:
```markdown
### Step 2: Execute Tasks

For each task:
1. Mark as in_progress
2. Follow each step exactly (plan has bite-sized steps)
3. Run verifications as specified
4. Mark as completed
```

- [ ] **Step 2: Beads tracking 로직 추가**

각 task 루프에 beads 추적 동작을 삽입.

기존:
```markdown
### Step 2: Execute Tasks

For each task:
1. Mark as in_progress
2. Follow each step exactly (plan has bite-sized steps)
3. Run verifications as specified
4. Mark as completed
```

변경:
```markdown
### Step 2: Execute Tasks

For each task:
1. Mark as in_progress
2. **Beads 연동 시:** `bd update <child-id> --claim`
3. Follow each step exactly (plan has bite-sized steps)
4. Run verifications as specified
5. Mark as completed
6. **Beads 연동 시:**
   - `bd update <child-id> --status resolved --set-metadata git_sha=$(git rev-parse HEAD)`
   - `bd dolt push`

**bd 명령어 직렬화:** bd write 작업(`update`, `dolt push`)은 병렬 실행하지 않음. 한 task의 beads 업데이트가 완료된 후 다음 task로 진행.
```

- [ ] **Step 3: Edit 도구로 실제 교체 실행**

Edit 도구로 Step 2 내용을 교체.

- [ ] **Step 4: 변경 확인**

Read로 Step 2가 올바르게 수정되었는지 확인.

- [ ] **Step 5: 커밋**

```bash
git add skills/executing-plans/SKILL.md
git commit -m "feat(executing-plans): add beads tracking to Step 2

Claim child beads at task start, mark resolved with git SHA at
task completion."
```

---

### Task 4: Integration 섹션 업데이트 + Sync

**REQUIRED SUB-SKILL:** Use superpowers:writing-skills

**Files:**
- Modify: `skills/executing-plans/SKILL.md` (Integration 섹션)
- Sync: `~/.claude/plugins/marketplaces/superpowers-custom/skills/executing-plans/SKILL.md`
- Sync: `~/.claude/plugins/cache/superpowers-custom/skills/executing-plans/SKILL.md`

- [ ] **Step 1: Integration 섹션 업데이트**

기존:
```markdown
## Integration

**Required workflow skills:**
- **superpowers:using-git-worktrees** - REQUIRED: Set up isolated workspace before starting
- **superpowers:writing-plans** - Creates the plan this skill executes
- **superpowers:finishing-a-development-branch** - Complete development after all tasks
```

변경:
```markdown
## Integration

**Required workflow skills:**
- **superpowers:using-git-worktrees** - Set up isolated workspace (Step 0-C에서 선택 시)
- **superpowers:writing-plans** - Creates the plan this skill executes
- **superpowers:finishing-a-development-branch** - Complete development after all tasks

**Optional workflow skills:**
- **superpowers:subagent-driven-development** - Step 0-B에서 선택 시 위임
- **seed-beads-from-plan** - Step 1에서 Beads 연동 시 child bead 생성
```

- [ ] **Step 2: Edit 도구로 실제 교체 실행**

Edit 도구로 Integration 섹션을 교체.

- [ ] **Step 3: 전체 SKILL.md 최종 확인**

Read로 전체 파일을 읽어 구조와 일관성 확인:
- Step 0 → Step 1 → Step 2 → Step 3 순서
- Beads 관련 내용이 조건부(`.beads/` 존재 + opt-in) 구조인지
- 기존 섹션(When to Stop, When to Revisit, Remember)이 유지되는지

- [ ] **Step 4: 커밋**

```bash
git add skills/executing-plans/SKILL.md
git commit -m "feat(executing-plans): update integration section

Add optional skills for SDD delegation and beads seeding."
```

- [ ] **Step 5: 플러그인 디렉토리로 Sync**

```bash
cp skills/executing-plans/SKILL.md ~/.claude/plugins/marketplaces/superpowers-custom/skills/executing-plans/SKILL.md
cp skills/executing-plans/SKILL.md ~/.claude/plugins/cache/superpowers-custom/skills/executing-plans/SKILL.md
```

- [ ] **Step 6: Sync 확인**

```bash
diff skills/executing-plans/SKILL.md ~/.claude/plugins/marketplaces/superpowers-custom/skills/executing-plans/SKILL.md
diff skills/executing-plans/SKILL.md ~/.claude/plugins/cache/superpowers-custom/skills/executing-plans/SKILL.md
```

두 diff 모두 출력 없으면 sync 완료.
