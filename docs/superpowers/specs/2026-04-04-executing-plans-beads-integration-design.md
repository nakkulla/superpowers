# executing-plans Beads 통합 + UX 개선 설계

> executing-plans 스킬에 Beads 네이티브 연동, 워크스페이스 선택, 실행 전략 선택을 추가한다.

## 배경

현재 `executing-plans`는:
- Beads 이슈 시스템과 완전히 분리되어 있어 실행 단계에서 이슈 추적 공백이 발생
- 워크트리가 REQUIRED이지만 사용자에게 선택지를 명시적으로 제시하지 않음
- subagent-driven-development와의 선택을 에이전트가 자동 판단하여 사용자 제어권 부족
- plan path로만 진입 가능하여 Beads issue ID로의 직접 진입 불가

## 목표

1. `.beads/` 존재 시 Beads child issue 추적을 opt-in으로 지원
2. 각 task 완료 시 `resolved` + `git_sha` metadata 기록
3. 워크트리 vs 현재 브랜치 선택을 AskUserQuestion으로 제시
4. executing-plans vs subagent-driven-development 선택을 AskUserQuestion으로 제시
5. Beads issue ID로 직접 진입 지원 (plan path 자동 추출)
6. Beads가 없는 프로젝트에서는 기존 동작 완전 유지

## 비목표

- `finishing-a-development-branch` Beads 확장 (별도 작업)
- `bd-execute` 축소/전환 (별도 작업)
- `subagent-driven-development` Beads 연동 (별도 작업)
- Blocker check, resume 지원, 신규 작업 발견 추적 (향후 확장)

## 적용 범위

개인 플러그인(`superpowers-custom`)에만 적용. upstream superpowers 본 레포에는 PR하지 않음.

---

## 프로세스 변경

### 현재 → 변경 후

```
현재:  Step 1(Load) → Step 2(Execute) → Step 3(Complete)

변경:  Step 0(Preflight) → Step 1(Load + Seed) → Step 2(Execute + Track) → Step 3(Complete)
```

---

## Step 0: Preflight Decisions

### 0-A. 입력 파싱

```
$ARGUMENTS 분석:
  .md로 끝남  → plan path 모드
  숫자/ID     → Beads issue ID 모드 (.beads/ 필수)
  없음        → 에러 ("plan path 또는 issue ID를 지정하세요")
```

**Issue ID 모드:**
1. `bd show <id> --json` → `metadata.plan` 필드에서 plan path 추출
2. plan path 없으면 에러: "이 이슈에 plan이 연결되어 있지 않습니다."

**Plan path 모드 + .beads/ 존재:**
1. `bd list --json`으로 `metadata.plan`이 현재 plan path와 일치하는 이슈 검색
2. 있으면 해당 이슈의 context 로드 (beads 연동 후보로 기억)

### 0-B. 실행 전략 선택 (AskUserQuestion)

```
이 plan을 어떻게 실행할까요?

1. 이 세션에서 직접 실행 (executing-plans)
2. Subagent로 실행 (subagent-driven-development)
```

- "Subagent로 실행" 선택 시: `superpowers:subagent-driven-development` invoke 후 이 스킬 종료
- "직접 실행" 선택 시: 계속 진행

### 0-C. 워크스페이스 선택 (AskUserQuestion)

```
어디에서 작업할까요?

1. 워크트리 생성 (using-git-worktrees 사용)
2. 현재 브랜치에서 진행
```

- "워크트리 생성" 선택 시: `superpowers:using-git-worktrees` invoke
- "현재 브랜치" 선택 시: 현재 위치에서 그대로 진행

### 0-D. Beads 연동 선택 (AskUserQuestion, `.beads/` 존재 시만)

```
Beads 이슈를 연결할까요?

1. Beads 이슈 연결 (seed-beads-from-plan으로 child issue 생성 + task별 추적)
2. Beads 연동 없이 진행
```

`.beads/`가 없으면 이 질문을 건너뛰고 Beads 연동 OFF로 진행.

---

## Step 1: Load Plan + Beads Seeding

기존 Step 1에 Beads 시딩 추가.

1. Plan 파일 읽기
2. 비판적 검토 — 의문점 있으면 사용자에게 먼저 제기
3. 의문 없으면 TodoWrite 생성
4. **Beads 연동 ON일 때:**
   - `superpowers:seed-beads-from-plan` invoke (plan path + parent issue ID 전달)
   - 매핑 테이블(Task → Bead ID) 수신 및 보관

---

## Step 2: Execute Tasks + Track

기존 실행 루프에 Beads 추적 추가.

각 task마다:

1. TodoWrite에서 in_progress 표시
2. **Beads 연동 시:** `bd update <child-id> --claim` (assignee 설정 + status를 in_progress로 변경)
3. Plan에 명시된 각 step 실행
4. Plan에 명시된 verification 수행
5. TodoWrite에서 completed 표시
6. **Beads 연동 시:**
   - `git_sha=$(git rev-parse HEAD)`
   - `bd update <child-id> --status resolved --set-metadata git_sha=<git_sha>`
   - `bd dolt push`

### bd 명령어 직렬화

기존 정책 유지: `bd update`, `bd dolt push` 등 write 작업은 병렬 실행하지 않음. 한 task의 beads 업데이트가 완료된 후 다음 task로 진행.

---

## Step 3: Complete

기존과 동일:
- "I'm using the finishing-a-development-branch skill to complete this work."
- `superpowers:finishing-a-development-branch` invoke
- 이 스킬이 이미 merge 시 `bd close`를 처리하므로 추가 변경 불필요

---

## 호환성

### .beads/ 없는 프로젝트

모든 Beads 관련 로직은 `.beads/` 존재 + 사용자 opt-in으로 게이트됨:
- Step 0-D 질문 자체가 스킵됨
- Step 1: TodoWrite만 생성 (현재와 동일)
- Step 2: TodoWrite만 업데이트 (현재와 동일)

### .beads/ 있는 프로젝트

사용자가 "Beads 연동 없이 진행"을 선택하면 위와 동일하게 동작.

---

## 외부 스킬 참조

| 스킬 | 호출 위치 | 용도 |
|------|----------|------|
| `subagent-driven-development` | Step 0-B | SDD 선택 시 위임 |
| `using-git-worktrees` | Step 0-C | 워크트리 생성 |
| `seed-beads-from-plan` | Step 1 | child bead 일괄 생성 |
| `finishing-a-development-branch` | Step 3 | 브랜치 완료 + close flow |

## bd 명령어 사용

| 명령어 | 호출 위치 | 용도 |
|--------|----------|------|
| `bd show <id> --json` | Step 0-A | issue ID에서 plan path 추출 |
| `bd list --json` | Step 0-A | plan path로 연결된 이슈 검색 |
| `bd update <id> --claim` | Step 2 | task 시작 (assignee + in_progress) |
| `bd update <id> --status resolved --set-metadata git_sha=<sha>` | Step 2 | task 완료 + SHA 기록 |
| `bd dolt push` | Step 2 | 상태 동기화 (각 task 완료 후) |
