# Subagent Orchestration Contract Hardening Implementation Plan

Parent bead: superpowers-86t

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Harden the bd-ralph ↔ subagent-driven-development handoff so completion requires target-worktree evidence, reviewers judge task-scoped diff only, and reviewer timeout handling stays bounded.

**Architecture:** This work stays documentation-only and makes minimal contract edits in existing skill artifacts. Four files in the superpowers repo are updated in place (`subagent-driven-development` skill + three prompt templates), and the bd-ralph orchestrator contract is updated in its actual current location at `/Users/isy_macstudio/Documents/GitHub/dotfiles/shared/skills/bd-ralph/SKILL.md` because that skill is not currently present under `superpowers/skills/`.

**Tech Stack:** Markdown skill files, prompt templates, grep/sed-based verification, Beads metadata

---

### Task 1: Tighten implementer completion evidence requirements

> **REQUIRED SUB-SKILL:** Use superpowers:writing-skills

**Files:**
- Modify: `skills/subagent-driven-development/implementer-prompt.md:29-42`
- Modify: `skills/subagent-driven-development/implementer-prompt.md:74-112`

- [ ] **Step 1: Add exact-workspace requirement under `Work from:`**

Edit `skills/subagent-driven-development/implementer-prompt.md` so the section beginning at `Work from: [directory]` becomes:

```markdown
    Work from: [directory]

    You must perform edits and verification from that exact directory.
    If you discover you worked in a different workspace or branch, stop and report BLOCKED.

    **While you work:** If you encounter something unexpected or unclear, **ask questions**.
    It's always OK to pause and clarify. Don't guess or make assumptions.
```

- [ ] **Step 2: Add an evidence gate before the report format**

Insert this new subsection immediately after `If you find issues during self-review, fix them now before reporting.`:

```markdown
    ## Evidence Before Reporting Back

    Before you report DONE or DONE_WITH_CONCERNS, capture evidence from the target workspace:

    - `pwd`
    - `git branch --show-current`
    - `git diff -- [files changed for this task]`
    - raw output of the verification commands you ran

    If there is no diff in the target workspace, do not report DONE.
    If tests were not run in the target workspace, do not claim they passed.
```

- [ ] **Step 3: Expand the report format so DONE requires evidence**

Replace the report-format tail so it reads:

```markdown
    ## Report Format

    When done, report:
    - **Status:** DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT
    - What you implemented (or what you attempted, if blocked)
    - What you tested and test results
    - Files changed
    - Exact `pwd`
    - Exact branch name
    - Exact diff scope
    - Exact verification command outputs
    - Self-review findings (if any)
    - Any issues or concerns

    Use DONE_WITH_CONCERNS if you completed the work but have doubts about correctness.
    Use BLOCKED if you cannot complete the task. Use NEEDS_CONTEXT if you need
    information that wasn't provided. If the evidence above is missing, use BLOCKED or
    NEEDS_CONTEXT instead of DONE. Never silently produce work you're unsure about.
```

- [ ] **Step 4: Verify the new evidence contract is present exactly once**

Run:

```bash
rg -n "You must perform edits and verification from that exact directory|## Evidence Before Reporting Back|Exact `pwd`|If the evidence above is missing" skills/subagent-driven-development/implementer-prompt.md
```

Expected: 4 matching lines covering the workspace guard, the evidence section, and the expanded report contract.

- [ ] **Step 5: Commit**

```bash
git add skills/subagent-driven-development/implementer-prompt.md
git commit -m "docs: implementer 완료 증거 계약 강화"
```

---

### Task 2: Make reviewers judge only the task diff

> **REQUIRED SUB-SKILL:** Use superpowers:writing-skills

**Files:**
- Modify: `skills/subagent-driven-development/spec-reviewer-prompt.md:14-61`
- Modify: `skills/subagent-driven-development/code-quality-reviewer-prompt.md:9-26`

- [ ] **Step 1: Add diff-scope inputs and scope rules to the spec reviewer prompt**

Edit `skills/subagent-driven-development/spec-reviewer-prompt.md` so `## What Was Requested` and the review instructions become:

```markdown
    ## What Was Requested

    [FULL TEXT of task requirements]

    BASE_SHA: [commit before this task]
    CHANGED_FILES: [files changed for this task]
    OPTIONAL_CHANGED_HUNKS_SUMMARY: [brief summary of touched areas]
```

and add these rules before `Report:`:

```markdown
    Review only the changes introduced for this task relative to BASE_SHA.

    Do not flag pre-existing code outside the touched diff unless the current task modified it.
    If the diff scope is missing or ambiguous, return NEEDS_CONTEXT instead of broad speculation.
```

Then replace the `Report:` block with:

```markdown
    Report:
    - ✅ Spec compliant
    - ❌ Issues found: [only issues introduced by this task's diff, with file:line references]
    - NEEDS_CONTEXT: [if BASE_SHA or diff scope is too unclear to judge safely]
```

- [ ] **Step 2: Add matching diff-scope constraints to the code-quality reviewer prompt**

Append these lines after the existing bullet list in `skills/subagent-driven-development/code-quality-reviewer-prompt.md`:

```markdown
- Review only issues introduced by this task's diff relative to `BASE_SHA`.
- Do not report unrelated pre-existing issues outside the touched files or hunks.
- Prefer concrete file:line references within the task's changed scope.
```

- [ ] **Step 3: Verify reviewer prompts now mention `BASE_SHA`-scoped review**

Run:

```bash
rg -n "BASE_SHA|CHANGED_FILES|OPTIONAL_CHANGED_HUNKS_SUMMARY|Review only the changes introduced for this task relative to BASE_SHA|NEEDS_CONTEXT|Review only issues introduced by this task's diff relative to `BASE_SHA`" \
  skills/subagent-driven-development/spec-reviewer-prompt.md \
  skills/subagent-driven-development/code-quality-reviewer-prompt.md
```

Expected: matches in both files, including the new spec-review inputs, `NEEDS_CONTEXT`, and the code-quality diff-scope bullets.

- [ ] **Step 4: Commit**

```bash
git add skills/subagent-driven-development/spec-reviewer-prompt.md skills/subagent-driven-development/code-quality-reviewer-prompt.md
git commit -m "docs: reviewer diff 범위 계약 명시"
```

---

### Task 3: Harden subagent-driven-development controller rules

> **REQUIRED SUB-SKILL:** Use superpowers:writing-skills

**Files:**
- Modify: `skills/subagent-driven-development/SKILL.md:15-29`
- Modify: `skills/subagent-driven-development/SKILL.md:154-170`
- Modify: `skills/subagent-driven-development/SKILL.md:287-317`

- [ ] **Step 1: Add bounded reviewer-timeout handling to `## Auto Mode`**

Insert this paragraph immediately after the decision table in `skills/subagent-driven-development/SKILL.md`:

```markdown
In `--auto`, review-family retries must stay bounded:
- On reviewer timeout, retry at most once with a smaller, more explicit context packet
- If the second reviewer also times out or cannot judge safely, fail fast with a concrete error report
```

- [ ] **Step 2: Replace the `DONE` rule with evidence validation language**

Replace:

```markdown
**DONE:** Proceed to spec compliance review.
```

with:

```markdown
**DONE:** Proceed to spec compliance review only after the controller verifies target-worktree evidence:
- exact `pwd`
- exact branch
- task-scoped diff in the target workspace
- raw verification command output

If the reported completion does not match the target workspace, treat it as invalid completion and re-dispatch instead of reviewing it.
```

- [ ] **Step 3: Add two red flags for false completion and whole-file review**

Add these bullets under `## Red Flags` in `skills/subagent-driven-development/SKILL.md`:

```markdown
- Accept DONE without checking target-worktree diff and raw test output
- Let reviewers judge the whole file when the task should be reviewed against a bounded diff
```

- [ ] **Step 4: Verify the skill now states the bounded retry and evidence gate**

Run:

```bash
rg -n "review-family retries must stay bounded|Proceed to spec compliance review only after the controller verifies target-worktree evidence|invalid completion|Accept DONE without checking target-worktree diff|Let reviewers judge the whole file" skills/subagent-driven-development/SKILL.md
```

Expected: 5 matches covering the new auto-mode retry note, the rewritten DONE semantics, and the two new red flags.

- [ ] **Step 5: Commit**

```bash
git add skills/subagent-driven-development/SKILL.md
git commit -m "docs: subagent 실행 컨트롤러 검증 규칙 강화"
```

---

### Task 4: Harden bd-ralph orchestration outputs and abort conditions

> **REQUIRED SUB-SKILL:** Use superpowers:writing-skills

**Files:**
- Modify: `/Users/isy_macstudio/Documents/GitHub/dotfiles/shared/skills/bd-ralph/SKILL.md:92-94`
- Modify: `/Users/isy_macstudio/Documents/GitHub/dotfiles/shared/skills/bd-ralph/SKILL.md:158-195`
- Modify: `/Users/isy_macstudio/Documents/GitHub/dotfiles/shared/skills/bd-ralph/SKILL.md:196-213`

- [ ] **Step 1: Strengthen the Phase 2 subagent bullet with observable outputs**

In `/Users/isy_macstudio/Documents/GitHub/dotfiles/shared/skills/bd-ralph/SKILL.md`, replace the current subagent branch bullet with:

```markdown
- **If `execution_strategy: subagent`:**
  - Invoke `$superpowers:subagent-driven-development --auto --parent-issue <parent-bead-id> --beads <beads_mode> --finishing skip`. The subagent skill handles child seeding internally when `--beads full` (inspect existing children first, seed only if needed). Do not continue until execution completion summary, canonical worktree path, task-scoped diff evidence, and target-worktree verification results are observed.
```

- [ ] **Step 2: Add a workflow-family expected-output subsection for `subagent-driven-development`**

Insert this subsection between `### executing-plans` and `### ho-create`:

```markdown
### `subagent-driven-development`

Expected outputs:
- canonical worktree path
- base SHA or equivalent review baseline for the current task set
- task-scoped diff evidence from the target worktree
- raw verification results from the target worktree
- execution completion summary

Abort if:
- subagent reports completion but target-worktree diff is missing
- reported cwd/branch does not match the canonical worktree
- review findings clearly refer to pre-existing code outside the task diff
- review timeout persists after one smaller-packet retry
```

- [ ] **Step 3: Add an explicit parent-side interpretation rule in abort/resume guidance**

Insert this paragraph before `## Abort / Resume Rules` or as the first bullet under it:

```markdown
For subagent execution, natural-language completion reports are not sufficient by themselves. The parent must validate completion against observable artifacts in the target worktree before advancing to review or finish phases.
```

- [ ] **Step 4: Verify the bd-ralph contract now names the new outputs and aborts**

Run:

```bash
rg -n "task-scoped diff evidence|target-worktree verification results|### `subagent-driven-development`|review baseline|natural-language completion reports are not sufficient" /Users/isy_macstudio/Documents/GitHub/dotfiles/shared/skills/bd-ralph/SKILL.md
```

Expected: matches in the Phase 2 bullet, the new expected-output subsection, and the new parent-side interpretation rule.

- [ ] **Step 5: Commit**

```bash
git add /Users/isy_macstudio/Documents/GitHub/dotfiles/shared/skills/bd-ralph/SKILL.md
git commit -m "docs: bd-ralph subagent 산출물 계약 강화"
```

---

### Task 5: Final consistency pass and metadata update

> **REQUIRED SUB-SKILL:** Use superpowers:writing-skills

**Files:**
- Verify only

- [ ] **Step 1: Re-read the changed sections together for terminology consistency**

Run:

```bash
sed -n '29,140p' skills/subagent-driven-development/implementer-prompt.md
printf '\n====\n'
sed -n '12,120p' skills/subagent-driven-development/spec-reviewer-prompt.md
printf '\n====\n'
sed -n '9,80p' skills/subagent-driven-development/code-quality-reviewer-prompt.md
printf '\n====\n'
sed -n '15,220p' skills/subagent-driven-development/SKILL.md
printf '\n====\n'
sed -n '85,230p' /Users/isy_macstudio/Documents/GitHub/dotfiles/shared/skills/bd-ralph/SKILL.md
```

Expected: the same concepts appear consistently across all files: target worktree evidence, `BASE_SHA`-scoped diff review, and bounded timeout retry.

- [ ] **Step 2: Verify there are no placeholder markers in touched files**

Run:

```bash
python3 - <<'PY2'
from pathlib import Path
paths = [
    Path("skills/subagent-driven-development/implementer-prompt.md"),
    Path("skills/subagent-driven-development/spec-reviewer-prompt.md"),
    Path("skills/subagent-driven-development/code-quality-reviewer-prompt.md"),
    Path("skills/subagent-driven-development/SKILL.md"),
    Path("/Users/isy_macstudio/Documents/GitHub/dotfiles/shared/skills/bd-ralph/SKILL.md"),
]
needles = ["fix later", "placeholder"]
for path in paths:
    text = path.read_text()
    for needle in needles:
        if needle in text:
            raise SystemExit(f"found {needle!r} in {path}")
print("no placeholder markers found")
PY2
  skills/subagent-driven-development/implementer-prompt.md \
  skills/subagent-driven-development/spec-reviewer-prompt.md \
  skills/subagent-driven-development/code-quality-reviewer-prompt.md \
  skills/subagent-driven-development/SKILL.md \
  /Users/isy_macstudio/Documents/GitHub/dotfiles/shared/skills/bd-ralph/SKILL.md
```

Expected: no matches.

- [ ] **Step 3: Link implementation state to the parent bead when ready**

Run:

```bash
bd update superpowers-86t --claim
bd show superpowers-86t --json
```

Expected: `superpowers-86t` remains the open parent for this follow-up work and is ready for later execution/plan-review flow.

- [ ] **Step 4: Commit**

```bash
git status --short
git commit --allow-empty -m "docs: orchestration contract 하드닝 검증 메타데이터 정리"
```

