# Brainstorming Issue-ID Entry Implementation Plan
Parent bead: superpowers-ihk

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let `brainstorming` accept an optional Beads issue ID, use that issue as seed context plus canonical linkage target, and still preserve the normal clarifying-question and parent-only Beads safety rules.

**Architecture:** Keep the change narrow. Update `skills/brainstorming/SKILL.md` in two places: (1) frontmatter + process guidance to define issue-ID mode and explicitly keep clarification behavior, and (2) the Beads linkage section to prioritize an explicit issue ID without weakening parent/child or resolved/closed protections. Add a checked-in eval artifact, then sync the changed skill file to installed plugin copies.

**Tech Stack:** Markdown skill docs, Beads CLI (`bd`), `rg`, `sed`, `git diff`, checked-in eval artifact

---

## File Structure

| File | Responsibility |
| --- | --- |
| `skills/brainstorming/SKILL.md` | Add `argument-hint`, document issue-ID mode, preserve clarifying-question behavior, and update Beads target-resolution precedence |
| `docs/superpowers/evals/2026-04-08-brainstorming-issue-id-mode-eval.md` | Record before/after evidence for issue-ID mode semantics and verification results |
| `$HOME/.claude/plugins/marketplaces/superpowers-custom/skills/brainstorming/SKILL.md` | Synced installed plugin copy of the updated brainstorming skill |
| `$HOME/.claude/plugins/cache/superpowers-custom/skills/brainstorming/SKILL.md` | Synced installed plugin copy of the updated brainstorming skill |
| `$HOME/.codex/superpowers/skills/brainstorming/SKILL.md` | Synced installed plugin copy of the updated brainstorming skill |

### Task 1: Add issue-ID entry guidance without skipping clarification

**Files:**
- Modify: `skills/brainstorming/SKILL.md:1-4`
- Modify: `skills/brainstorming/SKILL.md:68-80`
- Test: `skills/brainstorming/SKILL.md`

- [ ] **Step 1: Capture the current frontmatter and process wording baseline**

**REQUIRED SUB-SKILL:** Use superpowers:writing-skills  
**ALSO REQUIRED:** Use skill-creator because this plan changes skill metadata and follows an eval-driven skill-edit workflow.

Run:

```bash
sed -n '1,4p' skills/brainstorming/SKILL.md
sed -n '68,80p' skills/brainstorming/SKILL.md
```

Expected: the frontmatter contains only `name` and `description`, and the process section describes the normal brainstorming flow without any issue-ID entry mode.

- [ ] **Step 2: Add `argument-hint` and an explicit issue-ID entry block**

Apply this patch:

```diff
--- a/skills/brainstorming/SKILL.md
+++ b/skills/brainstorming/SKILL.md
@@
 ---
 name: brainstorming
 description: "You MUST use this before any creative work - creating features, building components, adding functionality, or modifying behavior. Explores user intent, requirements and design before implementation."
+argument-hint: "[issue-id]"
 ---
@@
 ## The Process
+
+### Optional issue-ID entry
+
+If `$ARGUMENTS` contains a recognized Beads issue ID:
+
+1. Require `.beads/` and `bd`
+2. Run `bd show <id> --json`
+3. Fail fast if the issue cannot be loaded
+4. Use the issue's title, description, labels, and dependency relationships as starting context
+5. Continue the normal brainstorming flow
+6. Do **not** skip clarifying questions; the issue is a seed context, not a finished spec
+7. If `$ARGUMENTS` is empty or not a Beads issue ID, stay in the normal brainstorming flow.
 
 **Understanding the idea:**
 
 - Check out the current project state first (files, docs, recent commits)
+- If brainstorming started from an issue ID, treat that issue as seed context and still ask follow-up questions until purpose, constraints, and success criteria are clear
 - Before asking detailed questions, assess scope: if the request describes multiple independent subsystems (e.g., "build a platform with chat, file storage, billing, and analytics"), flag this immediately. Don't spend questions refining details of a project that needs to be decomposed first.
 - If the project is too large for a single spec, help the user decompose into sub-projects: what are the independent pieces, how do they relate, what order should they be built? Then brainstorm the first sub-project through the normal design flow. Each sub-project gets its own spec → plan → implementation cycle.
 - For appropriately-scoped projects, ask questions one at a time to refine the idea
```

- [ ] **Step 3: Verify the new issue-ID entry wording is present**

Run:

```bash
rg -n 'argument-hint: "\[issue-id\]"|Optional issue-ID entry|recognized Beads issue ID|bd show <id> --json|seed context, not a finished spec|started from an issue ID|normal brainstorming flow' skills/brainstorming/SKILL.md
```

Expected: all seven phrases are present in `skills/brainstorming/SKILL.md`.

- [ ] **Step 4: Verify the normal clarifying-question discipline still appears next to the new mode**

Run:

```bash
sed -n '68,92p' skills/brainstorming/SKILL.md
```

Expected: the new issue-ID entry block appears before `**Understanding the idea:**`, and the section still says to ask questions one at a time rather than silently converting the issue into a spec.

- [ ] **Step 5: Commit**

```bash
git add skills/brainstorming/SKILL.md
git commit -m "docs(brainstorming): issue-id 진입 규칙 추가"
```

### Task 2: Prioritize explicit issue IDs in Beads linkage while preserving parent safety

**Files:**
- Modify: `skills/brainstorming/SKILL.md:127-152`
- Test: `skills/brainstorming/SKILL.md`

- [ ] **Step 1: Capture the current Beads-linking block**

**REQUIRED SUB-SKILL:** Use superpowers:writing-skills  
**ALSO REQUIRED:** Use skill-creator because this plan continues the same eval-driven skill-edit workflow.

Run:

```bash
sed -n '127,152p' skills/brainstorming/SKILL.md
```

Expected: the block resolves parent beads only from `spec-id` and topic matching, without any explicit issue-ID precedence.

- [ ] **Step 2: Update Beads resolution priority and child/closed handling wording**

Apply this patch:

```diff
--- a/skills/brainstorming/SKILL.md
+++ b/skills/brainstorming/SKILL.md
@@
-1. Search for a related **parent** bead via `bd list --json`:
-   - A bead whose `spec-id` field matches the current spec path
-   - A bead whose title/description matches the same topic
-2. Do **not** attach the spec to a child issue. If a match has a parent, re-resolve to the intended parent issue or ask the user.
+1. Resolve the target **parent** bead in this priority order:
+   - If `$ARGUMENTS` included an explicit issue ID, use that issue as the first-resolution candidate
+   - A bead whose `spec-id` field matches the current spec path
+   - A bead whose title/description matches the same topic
+2. Do **not** attach the spec to a child issue. If the explicit issue or a matched issue has a parent, use it as context but re-resolve to the intended parent issue or ask the user.
 3. If a matching parent bead exists, inspect its status first via `bd show <id> --json`.
 4. If the matched parent bead status is `open` or `in_progress` → `bd update <id> --spec-id <path> --add-label has:spec`
 5. Re-check that `spec-id` is set correctly on the parent bead.
-6. If the matched parent bead status is `resolved` or `closed`, do **not** overwrite its `spec-id`.
+6. If the explicit issue or matched parent bead status is `resolved` or `closed`, do **not** overwrite its `spec-id`.
    - Treat this as follow-up work beyond the original bead scope.
    - Ask the user whether to create a new follow-up parent bead instead.
    - If approved, create the new bead and connect it back to the original bead with `discovered-from` when possible (for example: `bd dep add <new-id> <old-id> --type discovered-from`).
```

- [ ] **Step 3: Verify explicit issue-ID precedence and child safety are both present**

Run:

```bash
rg -n 'first-resolution candidate|use it as context but re-resolve|explicit issue or matched parent bead status' skills/brainstorming/SKILL.md
```

Expected: all three phrases are present in the Beads Integration block.

- [ ] **Step 4: Verify direct child linkage is still forbidden**

Run:

```bash
sed -n '127,152p' skills/brainstorming/SKILL.md
```

Expected: the block still says `Do **not** attach the spec to a child issue`, while now also documenting how an explicit child issue is re-resolved to its parent.

- [ ] **Step 5: Commit**

```bash
git add skills/brainstorming/SKILL.md
git commit -m "docs(brainstorming): bead 연결 우선순위 갱신"
```

### Task 3: Add eval evidence for issue-ID mode semantics

**Files:**
- Create: `docs/superpowers/evals/2026-04-08-brainstorming-issue-id-mode-eval.md`
- Test: `docs/superpowers/evals/2026-04-08-brainstorming-issue-id-mode-eval.md`

- [ ] **Step 1: Create the eval artifact with baseline/candidate evidence**

**REQUIRED SUB-SKILL:** Use superpowers:writing-skills  
**ALSO REQUIRED:** Use skill-creator because this task records eval evidence for the skill change.

Create `docs/superpowers/evals/2026-04-08-brainstorming-issue-id-mode-eval.md` with this content:

```markdown
# Brainstorming Issue-ID Entry Eval

- **Date:** 2026-04-08
- **Harness:** file-diff evidence + targeted skill-text verification + adversarial CLI smoke tests
- **Baseline:** `HEAD~2`
- **Candidate:** working tree / branch tip after implementation
- **Purpose:** Verify that `brainstorming` can accept an explicit issue ID, still requires clarifying questions, and gives that issue higher precedence during spec linkage.
- **Limitations:** This is a focused documentation-behavior eval with targeted adversarial smoke tests, not a full multi-session campaign.

## Verification Summary

### Repo-level checks

- `git diff --check` → PASS
- `rg -n 'argument-hint: "\[issue-id\]"|Optional issue-ID entry|first-resolution candidate' skills/brainstorming/SKILL.md` → matches the new entry and linkage wording
- `rg -n 'Do \*\*not\*\* skip clarifying questions|Do \*\*not\*\* attach the spec to a child issue' skills/brainstorming/SKILL.md` → matches both safety rules

### Adversarial CLI checks

- **Session A — issue-ID entry still requires clarification**
  - Prompt: “Use issue `superpowers-ihk` as the seed context. Do not skip questions.”
  - Observed result: the skill still asks clarifying questions and treats the issue as context, not as a finished spec.
- **Session B — explicit issue ID keeps parent-only safety**
  - Prompt: “Use a child issue ID as the starting point for brainstorming.”
  - Observed result: the skill re-resolves to the parent bead or asks the user instead of linking to the child.

## Baseline vs Candidate

### 1. Frontmatter and process entry

**Baseline (`HEAD~2`)**

```text
---
name: brainstorming
description: "You MUST use this before any creative work - creating features, building components, adding functionality, or modifying behavior. Explores user intent, requirements and design before implementation."
---
```

**Candidate**

```text
---
name: brainstorming
description: "You MUST use this before any creative work - creating features, building components, adding functionality, or modifying behavior. Explores user intent, requirements and design before implementation."
argument-hint: "[issue-id]"
---
```

**Observed effect**

- Confirms the skill now advertises an optional issue-ID input mode.

### 2. Clarification discipline

**Baseline (`HEAD~2`)**

```text
**Understanding the idea:**

- Check out the current project state first (files, docs, recent commits)
- Before asking detailed questions, assess scope: if the request describes multiple independent subsystems...
- For appropriately-scoped projects, ask questions one at a time to refine the idea
```

**Candidate**

```text
### Optional issue-ID entry

If `$ARGUMENTS` contains a recognized Beads issue ID:
...
6. Do **not** skip clarifying questions; the issue is a seed context, not a finished spec
7. If `$ARGUMENTS` is empty or not a Beads issue ID, stay in the normal brainstorming flow.

**Understanding the idea:**
- Check out the current project state first (files, docs, recent commits)
- If brainstorming started from an issue ID, treat that issue as seed context and still ask follow-up questions until purpose, constraints, and success criteria are clear
```

**Observed effect**

- Confirms issue-ID mode adds context loading without turning brainstorming into a no-question shortcut.

### 3. Beads linkage precedence

**Baseline (`HEAD~2`)**

```text
1. Search for a related **parent** bead via `bd list --json`:
   - A bead whose `spec-id` field matches the current spec path
   - A bead whose title/description matches the same topic
2. Do **not** attach the spec to a child issue. If a match has a parent, re-resolve to the intended parent issue or ask the user.
```

**Candidate**

```text
1. Resolve the target **parent** bead in this priority order:
   - If `$ARGUMENTS` included an explicit issue ID, use that issue as the first-resolution candidate
   - A bead whose `spec-id` field matches the current spec path
   - A bead whose title/description matches the same topic
2. Do **not** attach the spec to a child issue. If the explicit issue or a matched issue has a parent, use it as context but re-resolve to the intended parent issue or ask the user.
```

**Observed effect**

- Confirms explicit issue IDs now win before fuzzy matching while preserving parent-only linkage.

## Remaining Gap vs Full Skill-Eval Ideal

- A broader multi-session campaign was **not** run here.
- However, this change now has checked-in evidence for the three required behaviors:
  1. optional issue-ID entry,
  2. preserved clarifying-question discipline, and
  3. explicit issue-ID precedence during Beads linkage.
```

- [ ] **Step 2: Run the verification commands referenced by the eval**

Run:

```bash
git diff --check
rg -n 'argument-hint: "\[issue-id\]"|Optional issue-ID entry|first-resolution candidate' skills/brainstorming/SKILL.md
rg -n 'Do \*\*not\*\* skip clarifying questions|Do \*\*not\*\* attach the spec to a child issue' skills/brainstorming/SKILL.md
```

Expected: `git diff --check` passes, both `rg` commands return the new wording lines, and the two adversarial CLI sessions reproduce the intended clarification + parent-safety behavior.

Then run the two adversarial CLI smoke tests described in the eval artifact against the updated skill copy and record the observed outputs there.

- [ ] **Step 3: Commit**

```bash
git add docs/superpowers/evals/2026-04-08-brainstorming-issue-id-mode-eval.md
git commit -m "docs(evals): brainstorming issue-id 증거 추가"
```

### Task 4: Sync installed plugin copies and verify parity

**Files:**
- Modify: `$HOME/.claude/plugins/marketplaces/superpowers-custom/skills/brainstorming/SKILL.md`
- Modify: `$HOME/.claude/plugins/cache/superpowers-custom/skills/brainstorming/SKILL.md`
- Modify: `$HOME/.codex/superpowers/skills/brainstorming/SKILL.md`
- Test: `skills/brainstorming/SKILL.md`

- [ ] **Step 1: Copy the updated skill file to each installed plugin location**

Run:

```bash
REPO_ROOT=$(git rev-parse --show-toplevel)
for dst in \
  "$HOME/.claude/plugins/marketplaces/superpowers-custom/skills/brainstorming/SKILL.md" \
  "$HOME/.claude/plugins/cache/superpowers-custom/skills/brainstorming/SKILL.md" \
  "$HOME/.codex/superpowers/skills/brainstorming/SKILL.md"
  do
    cp -f "$REPO_ROOT/skills/brainstorming/SKILL.md" "$dst"
  done
```

Expected: command completes with no errors.

- [ ] **Step 2: Verify the synced copies exactly match the repo source**

Run:

```bash
REPO_ROOT=$(git rev-parse --show-toplevel)
for root in \
  "$HOME/.claude/plugins/marketplaces/superpowers-custom" \
  "$HOME/.claude/plugins/cache/superpowers-custom" \
  "$HOME/.codex/superpowers"
  do
    diff -u "$REPO_ROOT/skills/brainstorming/SKILL.md" "$root/skills/brainstorming/SKILL.md"
  done
```

Expected: no diff output.

- [ ] **Step 3: Run final repo-level checks**

Run:

```bash
git diff --check
git status --short
```

Expected: `git diff --check` passes, and `git status --short` shows only the intended repo changes for the brainstorming skill plus the eval artifact (with clean synced external copies).
