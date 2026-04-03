# Fork Patch Refinement — Review Fix Eval

- **Date:** 2026-04-03
- **Harness:** Codex CLI (`codex exec`)
- **Baseline:** `HEAD^` (`b53a927`)
- **Candidate:** current branch tip (`6d4180d`)
- **Purpose:** Add concrete verification evidence for the 4 skill-file changes called out in implementation review.
- **Limitations:** This is a focused smoke/evidence pass, not a full adversarial multi-session campaign.

## Verification Summary

### Repo-level checks

- `git diff --check` → PASS
- `git diff upstream/main -- <file>` reviewed for all 4 target files
- `npm test` → FAIL (`Missing script: "test"`)
  - This repo does not currently expose a package-script test suite, so skill-specific validation used file diff checks plus harness smoke tests.

### Harness smoke tests

Two Codex CLI smoke tests were run against `HEAD^` and the candidate content using a generic `case.md` filename to avoid triggering installed skill names.

#### H1 — finishing-a-development-branch: next options block

**Prompt**

```text
Read only case.md. Treat it as the only source of truth. Implementation is complete and tests already passed. Output exactly the next user-facing options block required by that file, and nothing else.
```

**Baseline (`HEAD^`)**

```text
Implementation complete. How would you like to finish this work?

1. Run implementation review first
2. Continue directly to branch handling
3. Discard this work


Which option?
```

**Candidate**

```text
Implementation complete. What would you like to do?

1. Merge back to <base-branch> locally
2. Push and create a Pull Request
3. Keep the branch as-is (I'll handle it later)
4. Discard this work

Which option?
```

**Observed effect**

- Confirms the candidate restores the upstream 4-option flow and removes the intermediate Finish Mode / Branch Action split.

#### H2 — brainstorming: checklist items immediately after item 7

**Prompt**

```text
Read only case.md. Output the checklist items that come immediately after item 7, exactly as written, and nothing else.
```

**Baseline (`HEAD^`)**

```text
8. **Beads integration** — connect spec to parent bead if `.beads/` exists (see below)
9. **User reviews written spec** — ask user to review the spec file before proceeding
10. **Transition to implementation** — invoke writing-plans skill to create implementation plan
```

**Candidate**

```text
8. **User reviews written spec** — ask user to review the spec file before proceeding
9. **Transition to implementation** — invoke writing-plans skill to create implementation plan
```

**Observed effect**

- Confirms the inserted checklist item was removed and the upstream numbering restored.

## File-by-file Evidence

### 1. `skills/finishing-a-development-branch/SKILL.md`

**Baseline (`HEAD^`)**

- `### Step 3: Finish Mode`
- `Present exactly these 3 options:`
- includes `### Step 3.5: Branch Action`
- uses bold `**Beads Merge Gate:**` prefixes

**Candidate**

- `### Step 3: Present Options`
- `Present exactly these 4 options:`
- `Step 3.5` removed
- Beads merge notes reduced to one plain sentence per option

**Conclusion:** Matches spec/plan intent and the smoke test confirms the user-facing prompt changed as intended.

### 2. `skills/brainstorming/SKILL.md`

**Baseline (`HEAD^`)**

- checklist contains item `8. **Beads integration**`
- graphviz contains Beads diamond node
- Beads intro says `connect the spec to a **parent bead**`
- User Review Gate examples use `"skill-creator"` / `"writing-plans"`

**Candidate**

- checklist resumes at `8. **User reviews written spec**`
- graphviz routes directly from spec self-review to user review
- Beads intro now says `connect the spec to the Beads issue tracker`
- User Review Gate examples use `"Use skill-creator"` / `"Use writing-plans"`

**Conclusion:** Matches the plan’s intended upstream-structure restoration while preserving fork-specific routing.

### 3. `skills/writing-plans/SKILL.md`

**Baseline (`HEAD^`)**

```text
1. `bd list --json`으로 관련 bead 검색 (우선순위):
   - `spec-id`가 원본 spec 경로와 일치하는 bead (brainstorming에서 생성된 것)
   - `metadata.plan`이 현재 plan 경로와 일치하는 bead
   - 제목이 동일 주제인 bead
2. 기존 bead 있으면 → `bd update <id> --set-metadata plan=<path> --add-label has:plan`
3. 없으면 → AskUserQuestion으로 확인 후 beads.md "Spec/Plan 작성 후 Bead 연결" 규칙에 따라 생성
4. `bd dolt push`
```

**Candidate**

```text
1. Search for a related bead via `bd list --json` (priority order):
   - A bead whose `spec-id` matches the original spec path (created during brainstorming)
   - A bead whose `metadata.plan` matches the current plan path
   - A bead whose title matches the same topic
2. If found → `bd update <id> --set-metadata plan=<path> --add-label has:plan`
3. If not found → ask user via AskUserQuestion, then create per the Beads spec/plan linking rules
4. `bd dolt push`
```

**Conclusion:** The remaining Korean in the Beads Plan Link block was fully translated to upstream-style English.

### 4. `skills/using-git-worktrees/SKILL.md`

**Baseline (`HEAD^`)**

- `### 3.5. Beads Integration (Post-Creation)` appears before the setup commands
- first sentence: `After worktree creation and setup, check if main repo has '.beads/':`
- `bd-adopt-worktree` line includes `(cooperative mode, default)`

**Candidate**

- project setup commands remain directly under `### 3. Run Project Setup`
- `### 3.5. Beads Integration` moved after the setup block
- first sentence: `After worktree creation and project setup, check if the main repo uses Beads:`
- `(cooperative mode, default)` removed

**Conclusion:** The document order now matches the intended execution order and the wording is aligned with the reviewed plan/spec.

## Remaining Gap vs Full Skill-Eval Ideal

- A full adversarial multi-session campaign was **not** run here.
- However, the implementation review’s concrete blockers are addressed:
  1. there is now explicit harness evidence for changed user-facing behavior, and
  2. there is a checked-in eval artifact with baseline/candidate comparisons for all 4 files.
