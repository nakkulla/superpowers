# Fork Patch Refinement Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refine mechanically-applied fork patches to match upstream's writing style, minimize divergence, and consolidate redundant HARD-GATE blocks.

**Architecture:** Reset each modified skill file closer to upstream (obra/superpowers) baseline, then surgically re-add only the fork-specific content in upstream's English imperative prose. The finishing-a-development-branch file gets the largest change: reverting from 3+3 two-stage options back to upstream's 4-option flow.

**Tech Stack:** Markdown (skill files)

**Repos:**
- Fork: `/Users/isy_macstudio/Documents/GitHub/superpowers` (nakkulla/superpowers)
- Upstream comparison: `upstream/main` remote (obra/superpowers)

---

## File Structure

### Modified files

| File | Change summary |
|------|----------------|
| `skills/brainstorming/SKILL.md` | Restore checklist/graphviz to upstream, consolidate 3 HARD-GATEs → 1, rewrite Beads section in English |
| `skills/finishing-a-development-branch/SKILL.md` | Revert to upstream 4-option flow, remove Step 3.5, add Beads gate sentences |
| `skills/writing-plans/SKILL.md` | Rewrite Beads Plan Link section in English |
| `skills/using-git-worktrees/SKILL.md` | Reorder Beads section, minor wording |

### Unchanged files (verified clean, no action needed)

| File | Reason |
|------|--------|
| `skills/brainstorming/spec-document-reviewer-prompt.md` | `model: sonnet` line already clean |
| `skills/writing-plans/plan-document-reviewer-prompt.md` | `model: sonnet` line already clean |
| `skills/subagent-driven-development/SKILL.md` | `model: sonnet` instruction already clean |
| `skills/subagent-driven-development/spec-reviewer-prompt.md` | `model: sonnet` line already clean |
| `agents/code-reviewer.md` | `model: sonnet` already clean |
| `.claude-plugin/marketplace.json` | Metadata already clean |
| `.claude-plugin/plugin.json` | Metadata already clean |

---

## Task 1: Refine `skills/brainstorming/SKILL.md`

**Files:**
- Modify: `skills/brainstorming/SKILL.md`

**Reference:** upstream at `upstream/main:skills/brainstorming/SKILL.md`

- [ ] **Step 1: Restore checklist to upstream numbering**

Replace the current items 8-10 and the HARD-GATE below them:

```markdown
8. **Beads integration** — connect spec to parent bead if `.beads/` exists (see below)
9. **User reviews written spec** — ask user to review the spec file before proceeding
10. **Transition to implementation** — invoke writing-plans skill to create implementation plan

<HARD-GATE>
If the brainstorming target is a skill (SKILL.md), you MUST use AskUserQuestion to ask: "`skill-creator` or `writing-plans`?" before proceeding. DO NOT default to writing-plans without asking.
</HARD-GATE>
```

With:

```markdown
7. **Spec self-review** — quick inline check for placeholders, contradictions, ambiguity, scope (see below)
8. **User reviews written spec** — ask user to review the spec file before proceeding
9. **Transition to implementation** — invoke writing-plans skill to create implementation plan

<HARD-GATE>
If the brainstorming target is a skill (SKILL.md), you MUST use AskUserQuestion to ask: "`skill-creator` or `writing-plans`?" before proceeding. DO NOT default to writing-plans without asking.
</HARD-GATE>
```

Note: item 7 already exists on the line above — the edit replaces from item 8 onward. The full edit target is lines 31-37 of the current file. Replace:

```
8. **Beads integration** — connect spec to parent bead if `.beads/` exists (see below)
9. **User reviews written spec** — ask user to review the spec file before proceeding
10. **Transition to implementation** — invoke writing-plans skill to create implementation plan
```

With:

```
8. **User reviews written spec** — ask user to review the spec file before proceeding
9. **Transition to implementation** — invoke writing-plans skill to create implementation plan
```

- [ ] **Step 2: Restore upstream graphviz (remove Beads diamond node)**

Replace the entire graphviz block (lines 41-70) with the upstream original. The specific changes:

Remove this line from the node declarations:
```
    "Beads integration\n(.beads/ exists?)" [shape=diamond];
```

Replace these two edge lines:
```
    "Spec self-review\n(fix inline)" -> "Beads integration\n(.beads/ exists?)";
    "Beads integration\n(.beads/ exists?)" -> "User reviews spec?";
```

With the upstream original:
```
    "Spec self-review\n(fix inline)" -> "User reviews spec?";
```

- [ ] **Step 3: Rewrite Beads Integration section in English**

Replace the current Beads Integration section (lines 134-150):

```markdown
### Beads Integration (Post-Spec-Review)

After the spec self-review passes and before presenting the spec to the user for review,
connect the spec to a **parent bead** if `.beads/` directory exists in the project.
This step only creates or links a parent bead (feature/epic) — child task beads are created later during plan execution via `seed-beads-from-plan`.

1. Search for a related parent bead via `bd list --json`:
   - A bead whose `spec-id` field matches the current spec path
   - A bead whose title/description matches the same topic
2. If a matching bead exists → `bd update <id> --spec-id <path> --add-label has:spec`
3. If no match → ask user via AskUserQuestion, then create:
   - Type: `epic` if child task decomposition is expected, `feature` otherwise
   - `bd create --type <type> --title "<title>"`
   - Immediately after: `bd update <id> --spec-id <path> --add-label has:spec`
4. `bd dolt push`

If `.beads/` does not exist, skip this step entirely.
```

With:

```markdown
### Beads Integration (Post-Spec-Review)

After the spec review loop passes and before presenting the spec to the user for review,
connect the spec to the Beads issue tracker if `.beads/` directory exists in the project:

1. Search for a related bead via `bd list --json`:
   - A bead whose `spec-id` field matches the current spec path
   - A bead whose title/description matches the same topic
2. If a matching bead exists → `bd update <id> --spec-id <path> --add-label has:spec`
3. If no match → ask user via AskUserQuestion, then create:
   - Type: `epic` if child task decomposition is expected, `feature` otherwise
   - `bd create --type <type> --title "<title>"`
   - Immediately after: `bd update <id> --spec-id <path> --add-label has:spec`
4. `bd dolt push`

If `.beads/` does not exist, skip this step entirely.
```

- [ ] **Step 4: Update User Review Gate HARD-GATE example options to English**

Replace:

```markdown
- "skill-creator" (optimized for skill authoring/editing)
- "writing-plans" (general implementation plan)
- "Revise spec"
- "Stop here"
```

With:

```markdown
- "Use skill-creator" (optimized for skill authoring/editing)
- "Use writing-plans" (general implementation plan)
- "Revise spec"
- "Stop here"
```

- [ ] **Step 5: Verify diff against upstream**

Run: `git diff upstream/main -- skills/brainstorming/SKILL.md`

Expected: Only these fork additions remain:
1. HARD-GATE block after checklist item 9 (skill-creator routing)
2. Terminal state paragraph extended with skill-creator mention
3. AskUserQuestion bullet in "Understanding the idea"
4. Beads Integration section (English) after Spec Self-Review
5. `model: sonnet` IMPORTANT line
6. User Review Gate HARD-GATE (English options)
7. Implementation section with skill-creator line

No Korean text. No Beads diamond in graphviz. Upstream numbering (8, 9 not 9, 10).

---

## Task 2: Revert `skills/finishing-a-development-branch/SKILL.md` to upstream 4-option flow

**Files:**
- Modify: `skills/finishing-a-development-branch/SKILL.md`

**Reference:** upstream at `upstream/main:skills/finishing-a-development-branch/SKILL.md`

- [ ] **Step 1: Restore Step 3 to upstream "Present Options"**

Replace lines 49-64 (Step 3: Finish Mode + its options):

```markdown
### Step 3: Finish Mode

Present exactly these 3 options:

```
Implementation complete. How would you like to finish this work?

1. Run implementation review first
2. Continue directly to branch handling
3. Discard this work


Which option?
```

**Don't add explanation** - keep options concise.
```

With the upstream original:

```markdown
### Step 3: Present Options

Present exactly these 4 options:

```
Implementation complete. What would you like to do?

1. Merge back to <base-branch> locally
2. Push and create a Pull Request
3. Keep the branch as-is (I'll handle it later)
4. Discard this work

Which option?
```

**Don't add explanation** - keep options concise.
```

- [ ] **Step 2: Remove Step 3.5 Branch Action entirely**

Delete lines 66-82 (the entire `### Step 3.5: Branch Action` section):

```markdown
### Step 3.5: Branch Action

If the user selects **1. Run implementation review first**:
1. Invoke `implementation-review`
2. Show the review body before any follow-up question
3. If fixes are applied, re-run the relevant verification
4. If the user wants to continue, proceed to Branch Action selection below

If the user selects **2. Continue directly to branch handling**, present exactly these 3 options:

```
1. Merge back to <base-branch> locally
2. Push and create a Pull Request
3. Keep the branch as-is (I'll handle it later)
```

If the user selects **3. Discard this work**, skip Branch Action and proceed directly to the discard confirmation in Step 4.
```

- [ ] **Step 3: Simplify Beads Merge Gate in Option 1**

Replace:

```markdown
#### Option 1: Merge Locally

**Beads Merge Gate:** If this work is tied to a Beads issue, this is the only close-ready path. `bd close` is allowed only after the target branch merge completes successfully. After a successful merge, clean up the feature branch and worktree automatically.
```

With:

```markdown
#### Option 1: Merge Locally

If this work is tied to a Beads issue, this is the only close-ready path. Run `bd close` only after the merge completes successfully.
```

- [ ] **Step 4: Simplify Beads Merge Gate in Option 2**

Replace:

```markdown
#### Option 2: Push and Create PR

**Beads Merge Gate:** Creating a PR does **not** count as merged. If this work is tied to a Beads issue, keep the issue open or `resolved`; do **not** `bd close` it yet.
```

With:

```markdown
#### Option 2: Push and Create PR

If this work is tied to a Beads issue, creating a PR does not count as merged — keep the issue open or mark it `resolved`.
```

- [ ] **Step 5: Simplify Beads Merge Gate in Option 3**

Replace:

```markdown
#### Option 3: Keep As-Is

**Beads Merge Gate:** Keeping the branch/worktree as-is means the work is not merged. If this work is tied to a Beads issue, do **not** `bd close` it.
```

With:

```markdown
#### Option 3: Keep As-Is

If this work is tied to a Beads issue, do not close it while the branch remains unmerged.
```

- [ ] **Step 6: Restore Common Mistakes text**

Replace:

```markdown
- **Fix:** Present exactly 3 Finish Mode options, then 3 Branch Action options
```

With:

```markdown
- **Fix:** Present exactly 4 structured options
```

- [ ] **Step 7: Restore Red Flags text**

Replace:

```markdown
- Present exactly 3 Finish Mode options, then 3 Branch Action options
```

With:

```markdown
- Present exactly 4 options
```

- [ ] **Step 8: Verify diff against upstream**

Run: `git diff upstream/main -- skills/finishing-a-development-branch/SKILL.md`

Expected: Only these fork additions remain:
1. One Beads gate sentence per Option (1, 2, 3) — each a single line after the `#### Option N` heading
No Korean text. No Step 3.5. No "Finish Mode" / "Branch Action" terminology. Upstream 4-option structure intact.

---

## Task 3: Rewrite `skills/writing-plans/SKILL.md` Beads section in English

**Files:**
- Modify: `skills/writing-plans/SKILL.md`

- [ ] **Step 1: Replace Korean text in Beads Plan Link section**

Replace lines 141-147:

```markdown
1. `bd list --json`으로 관련 bead 검색 (우선순위):
   - `spec-id`가 원본 spec 경로와 일치하는 bead (brainstorming에서 생성된 것)
   - `metadata.plan`이 현재 plan 경로와 일치하는 bead
   - 제목이 동일 주제인 bead
2. 기존 bead 있으면 → `bd update <id> --set-metadata plan=<path> --add-label has:plan`
3. 없으면 → AskUserQuestion으로 확인 후 beads.md "Spec/Plan 작성 후 Bead 연결" 규칙에 따라 생성
4. `bd dolt push`
```

With:

```markdown
1. Search for a related bead via `bd list --json` (priority order):
   - A bead whose `spec-id` matches the original spec path (created during brainstorming)
   - A bead whose `metadata.plan` matches the current plan path
   - A bead whose title matches the same topic
2. If found → `bd update <id> --set-metadata plan=<path> --add-label has:plan`
3. If not found → ask user via AskUserQuestion, then create per the Beads spec/plan linking rules
4. `bd dolt push`
```

- [ ] **Step 2: Verify diff against upstream**

Run: `git diff upstream/main -- skills/writing-plans/SKILL.md`

Expected: Only these fork additions remain:
1. `**Do NOT use EnterPlanMode**` line
2. Beads Plan Link section (English)
3. `model: sonnet` IMPORTANT line
No Korean text.

---

## Task 4: Fix ordering in `skills/using-git-worktrees/SKILL.md`

**Files:**
- Modify: `skills/using-git-worktrees/SKILL.md`

- [ ] **Step 1: Move Beads section after "Auto-detect" block**

Currently the Beads section (3.5) is between the `### 3. Run Project Setup` heading and the "Auto-detect and run appropriate setup" paragraph. This breaks the flow because Step 3's actual content (the auto-detect block) appears after Step 3.5.

Move Step 3.5 to after the auto-detect bash block (after the closing ` ``` ` of the Go setup), before `### 4. Verify Clean Baseline`.

The result should read:

```markdown
### 3. Run Project Setup

Auto-detect and run appropriate setup:

```bash
# Node.js
if [ -f package.json ]; then npm install; fi

# Rust
if [ -f Cargo.toml ]; then cargo build; fi

# Python
if [ -f requirements.txt ]; then pip install -r requirements.txt; fi
if [ -f pyproject.toml ]; then if grep -q "\[tool\.poetry\]" pyproject.toml; then poetry install; else echo 'WARNING: non-poetry pyproject.toml detected; Python setup is ambiguous, skipping editable install' >&2; fi; fi

# Go
if [ -f go.mod ]; then go mod download; fi
```

### 3.5. Beads Integration

After worktree creation and project setup, check if the main repo uses Beads:

```bash
MAIN_REPO_ROOT=$(git worktree list --porcelain | head -1 | sed 's/^worktree //')
test -d "$MAIN_REPO_ROOT/.beads"
```

If `.beads/` exists:
1. Check for `bd-adopt-worktree`: `command -v bd-adopt-worktree`
2. If available → `bd-adopt-worktree <worktree-path>`
3. If not available → warn: "bd-adopt-worktree not in PATH, .beads/ will be an independent copy"

### 4. Verify Clean Baseline
```

Note the wording change: "After worktree creation and setup" → "After worktree creation and project setup" and removing "(cooperative mode, default)" and "(Post-Creation)" from the heading for cleaner style.

- [ ] **Step 2: Verify diff against upstream**

Run: `git diff upstream/main -- skills/using-git-worktrees/SKILL.md`

Expected: Only these fork additions remain:
1. Step 3.5 Beads Integration (between project setup and baseline verification)
2. pyproject.toml non-poetry warning
No "(Post-Creation)" in heading. No "(cooperative mode, default)". Correct ordering (setup → beads → verify).
