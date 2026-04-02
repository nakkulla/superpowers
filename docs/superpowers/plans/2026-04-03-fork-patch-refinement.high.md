# Fork Patch Refinement

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refine mechanically-applied fork patches to match upstream's writing style, minimize divergence, and consolidate redundant HARD-GATE blocks.

**Architecture:** For each modified skill file, compare current fork state against `upstream/main` (obra/superpowers). Remove structural divergence (renumbered checklists, restructured option flows, extra graphviz nodes). Keep fork-specific functionality (Beads integration, skill-creator routing, model overrides) but reword in upstream's English imperative prose and place as minimal insertions into existing sections.

**Tech Stack:** Markdown (skill files)

---

## Scope

4 files need changes. 7 files are already clean and stay as-is.

| File | What changes |
|------|-------------|
| `skills/brainstorming/SKILL.md` | Restore checklist numbering (8,9 not 9,10), remove Beads graphviz node, consolidate HARD-GATEs, English-ify Beads section |
| `skills/finishing-a-development-branch/SKILL.md` | Revert to upstream 4-option flow, remove Step 3.5, simplify Beads gate wording |
| `skills/writing-plans/SKILL.md` | Translate Beads Plan Link section to English |
| `skills/using-git-worktrees/SKILL.md` | Fix section ordering (Beads after setup, not before), clean wording |

---

## Task 1: `skills/brainstorming/SKILL.md`

- [ ] **Step 1: Restore checklist numbering**

Remove the inserted "Beads integration" item. The HARD-GATE stays, only the numbering changes.

**Replace:**
```
8. **Beads integration** — connect spec to parent bead if `.beads/` exists (see below)
9. **User reviews written spec** — ask user to review the spec file before proceeding
10. **Transition to implementation** — invoke writing-plans skill to create implementation plan
```

**With:**
```
8. **User reviews written spec** — ask user to review the spec file before proceeding
9. **Transition to implementation** — invoke writing-plans skill to create implementation plan
```

- [ ] **Step 2: Remove Beads diamond from graphviz**

Remove this node declaration:
```
    "Beads integration\n(.beads/ exists?)" [shape=diamond];
```

Replace these two edges:
```
    "Spec self-review\n(fix inline)" -> "Beads integration\n(.beads/ exists?)";
    "Beads integration\n(.beads/ exists?)" -> "User reviews spec?";
```
With the upstream original:
```
    "Spec self-review\n(fix inline)" -> "User reviews spec?";
```

### Step 3: Rewrite Beads Integration section in English

**Replace:**
```
After the spec self-review passes and before presenting the spec to the user for review,
connect the spec to a **parent bead** if `.beads/` directory exists in the project.
This step only creates or links a parent bead (feature/epic) — child task beads are created later during plan execution via `seed-beads-from-plan`.

1. Search for a related parent bead via `bd list --json`:
```

**With:**
```
After the spec review loop passes and before presenting the spec to the user for review,
connect the spec to the Beads issue tracker if `.beads/` directory exists in the project:

1. Search for a related bead via `bd list --json`:
```

(Rest of the numbered list is already English — no change needed.)

### Step 4: Update User Review Gate example options

**Replace:**
```
- "skill-creator" (optimized for skill authoring/editing)
- "writing-plans" (general implementation plan)
```

**With:**
```
- "Use skill-creator" (optimized for skill authoring/editing)
- "Use writing-plans" (general implementation plan)
```

### Verification

Run: `git diff upstream/main -- skills/brainstorming/SKILL.md`

Only these fork additions should remain:
1. HARD-GATE after checklist item 9
2. Terminal state paragraph extended with skill-creator mention
3. AskUserQuestion bullet in "Understanding the idea"
4. `### Beads Integration (Post-Spec-Review)` section in English
5. `model: sonnet` IMPORTANT line
6. User Review Gate HARD-GATE with English options
7. Implementation section with skill-creator line

---

## Task 2: `skills/finishing-a-development-branch/SKILL.md`

### Step 1: Restore Step 3 to upstream 4-option flow

**Replace the entire Step 3 + Step 3.5 block** (lines 49–82):

```
### Step 3: Finish Mode

Present exactly these 3 options:

\```
Implementation complete. How would you like to finish this work?

1. Run implementation review first
2. Continue directly to branch handling
3. Discard this work


Which option?
\```

**Don't add explanation** - keep options concise.

### Step 3.5: Branch Action

If the user selects **1. Run implementation review first**:
1. Invoke `implementation-review`
2. Show the review body before any follow-up question
3. If fixes are applied, re-run the relevant verification
4. If the user wants to continue, proceed to Branch Action selection below

If the user selects **2. Continue directly to branch handling**, present exactly these 3 options:

\```
1. Merge back to <base-branch> locally
2. Push and create a Pull Request
3. Keep the branch as-is (I'll handle it later)
\```

If the user selects **3. Discard this work**, skip Branch Action and proceed directly to the discard confirmation in Step 4.
```

**With the upstream original:**

```
### Step 3: Present Options

Present exactly these 4 options:

\```
Implementation complete. What would you like to do?

1. Merge back to <base-branch> locally
2. Push and create a Pull Request
3. Keep the branch as-is (I'll handle it later)
4. Discard this work

Which option?
\```

**Don't add explanation** - keep options concise.
```

### Step 2: Simplify Beads gate sentences in Options 1-3

For each option, replace the bold "**Beads Merge Gate:**" prefix with a plain sentence.

**Option 1 — Replace:**
```
**Beads Merge Gate:** If this work is tied to a Beads issue, this is the only close-ready path. `bd close` is allowed only after the target branch merge completes successfully. After a successful merge, clean up the feature branch and worktree automatically.
```
**With:**
```
If this work is tied to a Beads issue, this is the only close-ready path. Run `bd close` only after the merge completes successfully.
```

**Option 2 — Replace:**
```
**Beads Merge Gate:** Creating a PR does **not** count as merged. If this work is tied to a Beads issue, keep the issue open or `resolved`; do **not** `bd close` it yet.
```
**With:**
```
If this work is tied to a Beads issue, creating a PR does not count as merged — keep the issue open or mark it `resolved`.
```

**Option 3 — Replace:**
```
**Beads Merge Gate:** Keeping the branch/worktree as-is means the work is not merged. If this work is tied to a Beads issue, do **not** `bd close` it.
```
**With:**
```
If this work is tied to a Beads issue, do not close it while the branch remains unmerged.
```

### Step 3: Restore Common Mistakes and Red Flags text

**Replace** (in Common Mistakes):
```
- **Fix:** Present exactly 3 Finish Mode options, then 3 Branch Action options
```
**With:**
```
- **Fix:** Present exactly 4 structured options
```

**Replace** (in Red Flags):
```
- Present exactly 3 Finish Mode options, then 3 Branch Action options
```
**With:**
```
- Present exactly 4 options
```

### Verification

Run: `git diff upstream/main -- skills/finishing-a-development-branch/SKILL.md`

Only these fork additions should remain: one Beads gate sentence per Option (1, 2, 3). Everything else identical to upstream.

---

## Task 3: `skills/writing-plans/SKILL.md`

### Step 1: Translate Beads Plan Link section to English

**Replace:**
```
1. `bd list --json`으로 관련 bead 검색 (우선순위):
   - `spec-id`가 원본 spec 경로와 일치하는 bead (brainstorming에서 생성된 것)
   - `metadata.plan`이 현재 plan 경로와 일치하는 bead
   - 제목이 동일 주제인 bead
2. 기존 bead 있으면 → `bd update <id> --set-metadata plan=<path> --add-label has:plan`
3. 없으면 → AskUserQuestion으로 확인 후 beads.md "Spec/Plan 작성 후 Bead 연결" 규칙에 따라 생성
4. `bd dolt push`
```

**With:**
```
1. Search for a related bead via `bd list --json` (priority order):
   - A bead whose `spec-id` matches the original spec path (created during brainstorming)
   - A bead whose `metadata.plan` matches the current plan path
   - A bead whose title matches the same topic
2. If found → `bd update <id> --set-metadata plan=<path> --add-label has:plan`
3. If not found → ask user via AskUserQuestion, then create per the Beads spec/plan linking rules
4. `bd dolt push`
```

### Verification

Run: `git diff upstream/main -- skills/writing-plans/SKILL.md`

Only these fork additions should remain: EnterPlanMode line, Beads Plan Link section (English), model: sonnet IMPORTANT line.

---

## Task 4: `skills/using-git-worktrees/SKILL.md`

### Step 1: Move Beads section after project setup

Currently Step 3.5 sits between the `### 3. Run Project Setup` heading and its actual content ("Auto-detect and run..."). Move it after the setup bash block.

**Current order (broken):**
```
### 3. Run Project Setup
### 3.5. Beads Integration (Post-Creation)
  ...beads content...
Auto-detect and run appropriate setup:
  ...bash block...
### 4. Verify Clean Baseline
```

**Target order (fixed):**
```
### 3. Run Project Setup
Auto-detect and run appropriate setup:
  ...bash block...
### 3.5. Beads Integration
  ...beads content (reworded)...
### 4. Verify Clean Baseline
```

Also clean up wording:
- Heading: `### 3.5. Beads Integration` (drop "(Post-Creation)")
- Body: "After worktree creation and project setup" (drop "and setup, check if main repo has")
- Remove "(cooperative mode, default)" from the bd-adopt-worktree line

### Verification

Run: `git diff upstream/main -- skills/using-git-worktrees/SKILL.md`

Only these fork additions should remain: pyproject.toml non-poetry warning, Step 3.5 Beads Integration (correctly positioned after setup).
