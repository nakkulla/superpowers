# Draft Plan Immediate Beads Linking Implementation Plan
Parent bead: superpowers-5q7

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `writing-plans` register `metadata.plan` on the parent Beads issue as soon as the plan is written and self-reviewed, while keeping `reviewed:plan` as the execution gate.

**Architecture:** Treat `metadata.plan` as the issue's linked plan pointer instead of a post-review approval marker. Update `writing-plans` to link immediately, minimally clarify `executing-plans` so it still treats `reviewed:plan` as the review gate, and add a checked-in eval artifact plus plugin sync so the behavior is documented and deployed consistently.

**Tech Stack:** Markdown skill docs, Beads CLI (`bd`), git diff verification, checked-in eval artifact

---

## File Structure

| File | Responsibility |
| --- | --- |
| `skills/writing-plans/SKILL.md` | Move plan-link timing from post-review wording to immediate post-save/post-self-review wording while preserving parent-only safety rules |
| `skills/executing-plans/SKILL.md` | Clarify that `metadata.plan` may point to a draft plan and that `reviewed:plan` remains the execution gate |
| `docs/superpowers/evals/2026-04-06-draft-plan-beads-linking-eval.md` | Record before/after evidence for the changed semantics and verification results |
| `~/.claude/plugins/marketplaces/superpowers-custom/...` | Synced installed plugin copy of the changed skill files |
| `~/.claude/plugins/cache/superpowers-custom/...` | Synced installed plugin copy of the changed skill files |
| `~/.codex/superpowers/...` | Synced installed plugin copy of the changed skill files |

### Task 1: Update `writing-plans` Beads linkage timing

**Files:**
- Modify: `skills/writing-plans/SKILL.md:24-30`
- Modify: `skills/writing-plans/SKILL.md:163-180`
- Test: `skills/writing-plans/SKILL.md`

- [ ] **Step 1: Capture the current wording baseline**

**REQUIRED SUB-SKILL:** Use superpowers:writing-skills  
**ALSO REQUIRED:** Use skill-creator for the eval-driven iteration in this plan.

Run:

```bash
sed -n '24,30p' skills/writing-plans/SKILL.md
sed -n '163,180p' skills/writing-plans/SKILL.md
```

Expected: the top section says auto mode will "link the plan to the Beads parent issue when enough context exists", and the lower section title still says `### Beads Plan Link (Post-Plan-Review)`.

- [ ] **Step 2: Update the auto-mode sentence and Beads linkage block**

Apply this patch:

```diff
--- a/skills/writing-plans/SKILL.md
+++ b/skills/writing-plans/SKILL.md
@@
-When invoked with `--auto`, this skill must:
+When invoked with `--auto`, this skill must:
 - generate and save the plan,
 - complete the built-in self-review,
- - link the plan to the Beads parent issue when enough context exists,
+- link the plan to the Beads parent issue immediately after plan creation when enough context exists,
 - return the final plan path,
 - exit without asking the execution-choice question.
@@
-### Beads Plan Link (Post-Plan-Review)
+### Beads Plan Link
 
-After the plan review loop passes, connect the plan to the Beads issue tracker
-if `.beads/` directory exists in the project:
+After saving the plan and completing the built-in self-review, connect the plan
+to the Beads issue tracker if `.beads/` directory exists in the project:
 
 **Safety check:** Link the plan to the Beads **parent** issue only.
@@
 2. Do **not** attach `metadata.plan` to a child bead. If a match has a parent, re-resolve to the intended parent issue or ask the user.
 3. If found → `bd update <id> --set-metadata plan=<path> --add-label has:plan`
 4. Re-check that `metadata.plan` is set correctly.
 5. If not found → ask user via AskUserQuestion, then create per the Beads spec/plan linking rules
 6. `bd dolt push`
 
-If `.beads/` does not exist, skip this step entirely.
+If `.beads/` does not exist, skip this step entirely.
+
+This linkage records the current plan document even when the linked bead does not
+yet have `reviewed:plan`.
```

- [ ] **Step 3: Verify the new wording is present**

Run:

```bash
rg -n "immediately after plan creation|### Beads Plan Link$|built-in self-review|does not yet have `reviewed:plan`" skills/writing-plans/SKILL.md
```

Expected: all four updated phrases are present, and no heading contains `Post-Plan-Review`.

- [ ] **Step 4: Verify the old post-review phrasing is gone**

Run:

```bash
if rg -n "Post-Plan-Review|After the plan review loop passes" skills/writing-plans/SKILL.md; then
  echo "unexpected old wording remains"
  exit 1
else
  echo "old wording removed"
fi
```

Expected: `old wording removed`

- [ ] **Step 5: Commit**

```bash
git add skills/writing-plans/SKILL.md
git commit -m "docs(writing-plans): draft plan을 즉시 bead에 연결"
```

### Task 2: Clarify `executing-plans` review-gate semantics

**Files:**
- Modify: `skills/executing-plans/SKILL.md:37-66`
- Test: `skills/executing-plans/SKILL.md`

- [ ] **Step 1: Capture the current linked-plan and gate wording**

**REQUIRED SUB-SKILL:** Use superpowers:writing-skills  
**ALSO REQUIRED:** Use skill-creator for the eval-driven iteration in this plan.

Run:

```bash
sed -n '37,66p' skills/executing-plans/SKILL.md
```

Expected: the file explains lookup via `metadata.plan` and separately gates execution on missing `reviewed:plan`.

- [ ] **Step 2: Add one explicit clarification sentence in Step 0-A and keep Step 0-B unchanged in behavior**

Apply this patch:

```diff
--- a/skills/executing-plans/SKILL.md
+++ b/skills/executing-plans/SKILL.md
@@
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
+
+A linked `metadata.plan` entry is only a plan-document pointer; it does not imply the plan has already passed review.
 
 **0-B. Plan Review Gate (linked bead exists and lacks `reviewed:plan` label):**
```

- [ ] **Step 3: Verify the clarification is present next to the lookup flow**

Run:

```bash
rg -n "plan-document pointer|does not imply the plan has already passed review|Plan Review Gate" skills/executing-plans/SKILL.md
```

Expected: the new clarification line appears before `0-B`, and `0-B` still references `reviewed:plan`.

- [ ] **Step 4: Verify the gate semantics remain unchanged**

Run:

```bash
sed -n '52,66p' skills/executing-plans/SKILL.md
```

Expected: the gate still triggers only when a linked bead exists and lacks `reviewed:plan`; no new bypass wording appears.

- [ ] **Step 5: Commit**

```bash
git add skills/executing-plans/SKILL.md
git commit -m "docs(executing-plans): metadata.plan 의미를 명확화"
```

### Task 3: Add eval evidence for the new semantics

**Files:**
- Create: `docs/superpowers/evals/2026-04-06-draft-plan-beads-linking-eval.md`
- Test: `docs/superpowers/evals/2026-04-06-draft-plan-beads-linking-eval.md`

- [ ] **Step 1: Create the eval artifact with baseline/candidate evidence**

**REQUIRED SUB-SKILL:** Use superpowers:writing-skills  
**ALSO REQUIRED:** Use skill-creator for the eval-driven iteration in this plan.

Create `docs/superpowers/evals/2026-04-06-draft-plan-beads-linking-eval.md` with this content:

```markdown
# Draft Plan Immediate Beads Linking Eval

- **Date:** 2026-04-06
- **Harness:** file-diff evidence + targeted skill-text verification
- **Baseline:** `HEAD~2`
- **Candidate:** working tree / branch tip after implementation
- **Purpose:** Verify that `writing-plans` links plans immediately while `executing-plans` still treats `reviewed:plan` as the execution gate.
- **Limitations:** This is a focused documentation-behavior eval, not a full multi-harness campaign.

## Verification Summary

### Repo-level checks

- `git diff --check` → PASS
- `rg -n "Post-Plan-Review|After the plan review loop passes" skills/writing-plans/SKILL.md` → no matches
- `rg -n "plan-document pointer|passed review" skills/executing-plans/SKILL.md` → matches the new clarification

## Baseline vs Candidate

### 1. `skills/writing-plans/SKILL.md`

**Baseline (`HEAD~2`)**

```text
### Beads Plan Link (Post-Plan-Review)

After the plan review loop passes, connect the plan to the Beads issue tracker
if `.beads/` directory exists in the project:
```

**Candidate**

```text
### Beads Plan Link

After saving the plan and completing the built-in self-review, connect the plan
to the Beads issue tracker if `.beads/` directory exists in the project:
```

**Observed effect**

- Confirms `metadata.plan` linkage happens at draft-plan time rather than after plan review.

### 2. `skills/executing-plans/SKILL.md`

**Baseline (`HEAD~2`)**

```text
Plan path mode + `.beads/` exists:
1. `bd list --all --metadata-field plan=<current-plan-path> --json` to find linked issues regardless of status
```

**Candidate**

```text
Plan path mode + `.beads/` exists:
1. `bd list --all --metadata-field plan=<current-plan-path> --json` to find linked issues regardless of status
...
A linked `metadata.plan` entry is only a plan-document pointer; it does not imply the plan has already passed review.
```

**Observed effect**

- Confirms the lookup pointer meaning is explicit while the `reviewed:plan` gate remains the execution approval signal.
```

- [ ] **Step 2: Run targeted verification commands and update the eval doc if wording differs**

Run:

```bash
git diff --check
rg -n "### Beads Plan Link$|built-in self-review|reviewed:plan" skills/writing-plans/SKILL.md skills/executing-plans/SKILL.md
git show HEAD~2:skills/writing-plans/SKILL.md | sed -n '163,170p'
sed -n '163,172p' skills/writing-plans/SKILL.md
git show HEAD~2:skills/executing-plans/SKILL.md | sed -n '41,55p'
sed -n '41,57p' skills/executing-plans/SKILL.md
```

Expected: `git diff --check` passes, baseline excerpts show post-review wording, and candidate excerpts show immediate-link + pointer-only wording.

- [ ] **Step 3: Commit**

```bash
git add docs/superpowers/evals/2026-04-06-draft-plan-beads-linking-eval.md
git commit -m "docs(evals): draft plan beads linking 증거 추가"
```

### Task 4: Sync installed plugin copies and verify parity

**Files:**
- Modify: `~/.claude/plugins/marketplaces/superpowers-custom/skills/writing-plans/SKILL.md`
- Modify: `~/.claude/plugins/marketplaces/superpowers-custom/skills/executing-plans/SKILL.md`
- Modify: `~/.claude/plugins/cache/superpowers-custom/skills/writing-plans/SKILL.md`
- Modify: `~/.claude/plugins/cache/superpowers-custom/skills/executing-plans/SKILL.md`
- Modify: `~/.codex/superpowers/skills/writing-plans/SKILL.md`
- Modify: `~/.codex/superpowers/skills/executing-plans/SKILL.md`
- Test: synced plugin copies above

- [ ] **Step 1: Copy the changed skill files into every installed plugin location**

Run:

```bash
cp -f skills/writing-plans/SKILL.md ~/.claude/plugins/marketplaces/superpowers-custom/skills/writing-plans/SKILL.md
cp -f skills/executing-plans/SKILL.md ~/.claude/plugins/marketplaces/superpowers-custom/skills/executing-plans/SKILL.md
cp -f skills/writing-plans/SKILL.md ~/.claude/plugins/cache/superpowers-custom/skills/writing-plans/SKILL.md
cp -f skills/executing-plans/SKILL.md ~/.claude/plugins/cache/superpowers-custom/skills/executing-plans/SKILL.md
cp -f skills/writing-plans/SKILL.md ~/.codex/superpowers/skills/writing-plans/SKILL.md
cp -f skills/executing-plans/SKILL.md ~/.codex/superpowers/skills/executing-plans/SKILL.md
```

Expected: all six copy commands exit successfully with no prompts.

- [ ] **Step 2: Verify every installed copy matches the repo version**

Run:

```bash
diff -u skills/writing-plans/SKILL.md ~/.claude/plugins/marketplaces/superpowers-custom/skills/writing-plans/SKILL.md
diff -u skills/executing-plans/SKILL.md ~/.claude/plugins/marketplaces/superpowers-custom/skills/executing-plans/SKILL.md
diff -u skills/writing-plans/SKILL.md ~/.claude/plugins/cache/superpowers-custom/skills/writing-plans/SKILL.md
diff -u skills/executing-plans/SKILL.md ~/.claude/plugins/cache/superpowers-custom/skills/executing-plans/SKILL.md
diff -u skills/writing-plans/SKILL.md ~/.codex/superpowers/skills/writing-plans/SKILL.md
diff -u skills/executing-plans/SKILL.md ~/.codex/superpowers/skills/executing-plans/SKILL.md
```

Expected: every `diff -u` exits with status 0 and no output.

- [ ] **Step 3: Commit**

```bash
git add skills/writing-plans/SKILL.md skills/executing-plans/SKILL.md docs/superpowers/evals/2026-04-06-draft-plan-beads-linking-eval.md
git commit -m "docs(skills): draft plan beads linking 규칙 반영"
```
