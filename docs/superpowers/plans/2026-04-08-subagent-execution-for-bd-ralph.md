# subagent-driven-development as bd-ralph Execution Engine — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Allow bd-ralph to execute plans through subagent-driven-development as an alternative to executing-plans, with --auto mode, --finishing flag, and per-task Beads child bead tracking.

**Architecture:** Three files are modified: (1) subagent-driven-development/SKILL.md gets argument-hint, --auto gate, --beads integration, and --finishing flag; (2) bd-ralph/SKILL.md gets execution_strategy branching in Phase 2; (3) bd-ralph default-profile.md gets execution_strategy documentation. No prompt templates or executing-plans are changed.

**Tech Stack:** Markdown skill files (superpowers plugin framework)

---

### Task 1: Add argument-hint and --auto gate to subagent-driven-development

> **REQUIRED SUB-SKILL:** Use superpowers:writing-skills

**Files:**
- Modify: `skills/subagent-driven-development/SKILL.md:1-4` (frontmatter)
- Modify: `skills/subagent-driven-development/SKILL.md:6-12` (after heading, before "When to Use")

- [ ] **Step 1: Add argument-hint to frontmatter**

Open `skills/subagent-driven-development/SKILL.md` and replace the frontmatter:

```markdown
---
name: subagent-driven-development
description: Use when executing implementation plans with independent tasks in the current session
argument-hint: "[plan-path] [--auto] [--parent-issue <id>] [--beads full|parent|skip] [--finishing run|skip]"
---
```

- [ ] **Step 2: Add Auto Mode section after the core principle line (L12) and before "## When to Use" (L14)**

Insert a new section between line 12 ("**Core principle:**...") and line 14 ("## When to Use"):

```markdown

## Auto Mode

When invoked with `--auto`:

- `plan-path` is required (fail fast if missing)
- Do not call `AskUserQuestion` or request human input
- All decision points use explicit override flags; if a flag is missing and the decision is ambiguous, fail fast

| Decision Point | Interactive | --auto |
|----------------|------------|--------|
| Plan file load failure | Ask user for path | Fail fast |
| Subagent BLOCKED | Escalate to user | Context supplement 1x retry, then fail fast |
| Subagent NEEDS_CONTEXT | Supplement context, re-dispatch | Same (already automatic) |
| Review loop fails 3 consecutive times | Ask user for judgment | Fail fast with error report |
| finishing-a-development-branch | Invoke | `--finishing skip`: omit, return control to caller |

```

- [ ] **Step 3: Verify the frontmatter parses correctly**

Read back `skills/subagent-driven-development/SKILL.md` lines 1-30. Confirm:
- frontmatter has `argument-hint` field
- Auto Mode section exists between core principle and When to Use
- No broken markdown formatting

- [ ] **Step 4: Commit**

```bash
git add skills/subagent-driven-development/SKILL.md
git commit -m "feat(subagent-driven-dev): argument-hint와 --auto 게이트 추가"
```

---

### Task 2: Add --finishing flag to subagent-driven-development

> **REQUIRED SUB-SKILL:** Use superpowers:writing-skills

**Files:**
- Modify: `skills/subagent-driven-development/SKILL.md` (new section after Auto Mode, before "## When to Use")
- Modify: `skills/subagent-driven-development/SKILL.md:266-278` (Integration section)

- [ ] **Step 1: Add --finishing section after the Auto Mode section**

Insert after the Auto Mode section (before "## When to Use"):

```markdown

## Finishing Flag

- `--finishing run` (default): invoke `finishing-a-development-branch` after all tasks complete, as described in the Integration section
- `--finishing skip`: omit the finishing step entirely and return control to the caller. Use this when an upper orchestrator (e.g., bd-ralph) owns the finishing workflow.

```

- [ ] **Step 2: Update the Integration section to respect --finishing**

Find the line in the Integration section (around L268-272):

```markdown
**Required workflow skills:**
- **superpowers:using-git-worktrees** - REQUIRED: Set up isolated workspace before starting
- **superpowers:writing-plans** - Creates the plan this skill executes
- **superpowers:requesting-code-review** - Code review template for reviewer subagents
- **superpowers:finishing-a-development-branch** - Complete development after all tasks
```

Replace the finishing line:

```markdown
- **superpowers:finishing-a-development-branch** - Complete development after all tasks (skipped when `--finishing skip`)
```

- [ ] **Step 3: Verify the finishing flag documentation**

Read back the new Finishing Flag section and the updated Integration section. Confirm:
- Both `run` and `skip` behaviors are documented
- Integration section reflects the conditional behavior

- [ ] **Step 4: Commit**

```bash
git add skills/subagent-driven-development/SKILL.md
git commit -m "feat(subagent-driven-dev): --finishing run|skip 플래그 추가"
```

---

### Task 3: Add --beads per-task integration to subagent-driven-development

> **REQUIRED SUB-SKILL:** Use superpowers:writing-skills

**Files:**
- Modify: `skills/subagent-driven-development/SKILL.md` (new section after Finishing Flag, before "## When to Use")

- [ ] **Step 1: Add Beads Integration section**

Insert after the Finishing Flag section (before "## When to Use"):

```markdown

## Beads Integration

Controlled by `--beads` and `--parent-issue` flags. `--parent-issue <id>` is required when `--beads` is `full` or `parent`.

### --beads skip (default)

No Beads updates. TodoWrite progress tracking only.

### --beads parent

- Claim the parent issue at start: `bd update <parent-id> --claim`
- No child issue management
- `bd dolt push` on completion or interruption

### --beads full

- Claim the parent issue at start: `bd update <parent-id> --claim`
- Inspect existing children via `bd children <parent-id> --json` for resume:
  - If children exist: rebuild Task-to-Bead mapping (match plan task titles to child bead titles), mark already-resolved children as completed in TodoWrite
  - If no children exist: invoke `$seed-beads-from-plan --auto`
- Per-task updates (in the main controller loop, NOT inside subagents):
  - Task start: `bd update <child-id> --claim`
  - Task complete (after both review stages pass): `bd update <child-id> --status resolved --set-metadata git_sha=<SHA>`
- `bd dolt push` on completion or interruption
- All `bd` write commands are serialized (no parallel bd writes)

**Important:** Subagents never call `bd` directly. All Beads updates happen in the controller's main loop between subagent dispatches.

**Scope boundary:** This skill does not resolve issue/spec/plan metadata; `bd-ralph` remains responsible for that orchestration.

```

- [ ] **Step 2: Verify the Beads section**

Read back the Beads Integration section. Confirm:
- Three modes documented (skip, parent, full)
- --parent-issue requirement stated
- Per-task update timing is clear (controller loop, not subagents)
- Resume logic documented
- Serialization requirement stated

- [ ] **Step 3: Commit**

```bash
git add skills/subagent-driven-development/SKILL.md
git commit -m "feat(subagent-driven-dev): --beads per-task Beads 통합 추가"
```

---

### Task 4: Add execution_strategy branching to bd-ralph Phase 2

> **REQUIRED SUB-SKILL:** Use superpowers:writing-skills

**Files:**
- Modify: `/Users/isy_macstudio/Documents/GitHub/dotfiles/shared/skills/bd-ralph/SKILL.md:8` (argument-hint)
- Modify: `/Users/isy_macstudio/Documents/GitHub/dotfiles/shared/skills/bd-ralph/SKILL.md:28-33` (workflow-family list)
- Modify: `/Users/isy_macstudio/Documents/GitHub/dotfiles/shared/skills/bd-ralph/SKILL.md:67-72` (Phase 2)

- [ ] **Step 1: Add --execution to argument-hint**

In the frontmatter (line 8), replace:

```
argument-hint: "<issue-id> [--plan-review run|skip] [--implementation-review run|skip] [--workspace worktree|current] [--beads full|parent|skip] [--handoff yes|no|profile] [--action pr]"
```

with:

```
argument-hint: "<issue-id> [--plan-review run|skip] [--implementation-review run|skip] [--execution direct|subagent] [--workspace worktree|current] [--beads full|parent|skip] [--handoff yes|no|profile] [--action pr]"
```

- [ ] **Step 2: Add subagent-driven-development to workflow-family list**

Find the workflow-family list (around L28-33):

```markdown
Workflow-family phases stay in the main orchestrator:
- Invoke `$superpowers:using-git-worktrees --auto`
- Invoke `$seed-beads-from-plan --auto`
- Invoke `$superpowers:executing-plans --auto`
- Invoke `$ho-create`
- Invoke `$superpowers:finishing-a-development-branch --auto`
```

Replace with:

```markdown
Workflow-family phases stay in the main orchestrator:
- Invoke `$superpowers:using-git-worktrees --auto`
- Invoke `$seed-beads-from-plan --auto`
- Invoke `$superpowers:executing-plans --auto` (when `execution_strategy: direct`)
- Invoke `$superpowers:subagent-driven-development --auto` (when `execution_strategy: subagent`)
- Invoke `$ho-create`
- Invoke `$superpowers:finishing-a-development-branch --auto`
```

- [ ] **Step 3: Rewrite Phase 2 with execution strategy branching**

Replace the entire Phase 2 section (lines 67-72) with:

```markdown
## Phase 2: Execute

- If the chosen workspace policy is `worktree`, invoke `$superpowers:using-git-worktrees --auto`; otherwise stay on the current branch. Do not continue until the canonical worktree path, target branch, and baseline verification result are observed.
- Resolve the effective execution strategy from `--execution direct|subagent` and the default profile's `execution_strategy`. Per-run `--execution` overrides the profile value.
- **If `execution_strategy: direct`:**
  - If `beads_mode: full` requires child issue mapping, invoke `$seed-beads-from-plan --auto`. Do not continue until the parent bead, task-to-child mapping, dependency wiring, and `bd dolt push` result are observed.
  - Invoke `$superpowers:executing-plans --auto` with concrete overrides for execution, workspace, beads, plan-review, and finishing behavior. Do not continue until the canonical plan path, effective overrides, and execution completion summary are observed.
- **If `execution_strategy: subagent`:**
  - Invoke `$superpowers:subagent-driven-development --auto --parent-issue <parent-bead-id> --beads <beads_mode> --finishing skip`. The subagent skill handles child seeding internally when `--beads full` (inspect existing children first, seed only if needed). Do not continue until execution completion summary is observed.
- `superpowers:writing-plans`, `superpowers:using-git-worktrees`, `seed-beads-from-plan`, `superpowers:executing-plans`, `superpowers:subagent-driven-development`, and `superpowers:finishing-a-development-branch` are invoked with `--auto` plus concrete overrides.
```

- [ ] **Step 4: Verify the changes**

Read back the full bd-ralph SKILL.md. Confirm:
- argument-hint includes `--execution direct|subagent`
- Workflow-family list includes both execution engines
- Phase 2 has explicit branching for direct vs subagent
- Subagent path uses `--finishing skip`
- Subagent path passes `--parent-issue` and `--beads`
- Phase 3 is unchanged

- [ ] **Step 5: Commit**

```bash
git add /Users/isy_macstudio/Documents/GitHub/dotfiles/shared/skills/bd-ralph/SKILL.md
git commit -m "feat(bd-ralph): Phase 2에 execution_strategy 분기 추가 (direct|subagent)"
```

---

### Task 5: Update bd-ralph default-profile.md

> **REQUIRED SUB-SKILL:** Use superpowers:writing-skills

**Files:**
- Modify: `/Users/isy_macstudio/Documents/GitHub/dotfiles/shared/skills/bd-ralph/references/default-profile.md`

- [ ] **Step 1: Add execution_strategy documentation**

Find the Rules section (line 19-23):

```markdown
## Rules
- This profile is the single editable source of workflow defaults.
- Per-run overrides win over these defaults.
- `--handoff yes|no` overrides the profile value; `--handoff profile` or omitting `--handoff` follows the profile's `handoff:` setting.
- Child skills receive concrete override flags derived from this profile.
```

Replace with:

```markdown
## Rules
- This profile is the single editable source of workflow defaults.
- Per-run overrides win over these defaults.
- `--handoff yes|no` overrides the profile value; `--handoff profile` or omitting `--handoff` follows the profile's `handoff:` setting.
- `execution_strategy: direct` invokes `superpowers:executing-plans` for inline task execution; `subagent` invokes `superpowers:subagent-driven-development` for per-task subagent execution with built-in review loops. Per-run `--execution direct|subagent` overrides this value.
- Child skills receive concrete override flags derived from this profile.
```

- [ ] **Step 2: Verify the profile documentation**

Read back the full default-profile.md. Confirm:
- `execution_strategy: direct` is still the default value in the YAML block
- The new rule explains both `direct` and `subagent` values
- Per-run override behavior is documented

- [ ] **Step 3: Commit**

```bash
git add /Users/isy_macstudio/Documents/GitHub/dotfiles/shared/skills/bd-ralph/references/default-profile.md
git commit -m "docs(bd-ralph): execution_strategy direct|subagent 설명 추가"
```

---

### Task 6: Sync plugin copies and verify

**Files:**
- Sync target: `/Users/isy_macstudio/GitHub/superpowers/skills/subagent-driven-development/SKILL.md`
- Sync target: `~/.claude/plugins/marketplaces/superpowers-custom/skills/subagent-driven-development/SKILL.md`
- Sync target: `~/.claude/plugins/cache/superpowers-custom/skills/subagent-driven-development/SKILL.md`
- Sync target: `~/.codex/superpowers/skills/subagent-driven-development/SKILL.md`

- [ ] **Step 1: Sync subagent-driven-development to plugin locations**

```bash
cp skills/subagent-driven-development/SKILL.md /Users/isy_macstudio/GitHub/superpowers/skills/subagent-driven-development/SKILL.md
cp skills/subagent-driven-development/SKILL.md ~/.claude/plugins/marketplaces/superpowers-custom/skills/subagent-driven-development/SKILL.md
cp skills/subagent-driven-development/SKILL.md ~/.claude/plugins/cache/superpowers-custom/skills/subagent-driven-development/SKILL.md
```

- [ ] **Step 2: Verify sync parity**

```bash
diff skills/subagent-driven-development/SKILL.md /Users/isy_macstudio/GitHub/superpowers/skills/subagent-driven-development/SKILL.md
diff skills/subagent-driven-development/SKILL.md ~/.claude/plugins/marketplaces/superpowers-custom/skills/subagent-driven-development/SKILL.md
diff skills/subagent-driven-development/SKILL.md ~/.claude/plugins/cache/superpowers-custom/skills/subagent-driven-development/SKILL.md
```

Expected: no diff output (files are identical).

- [ ] **Step 3: Update the Codex installation**

After the final commit/push from this repo, run `git pull` in `~/.codex/superpowers` so the Codex-installed copy reflects the same skill content.
Verify the pulled file with `git -C ~/.codex/superpowers diff -- skills/subagent-driven-development/SKILL.md` (expected: no diff).

- [ ] **Step 4: Verify spec verification checklist**

Manually confirm against the spec's Verification section:
1. `bd-ralph/SKILL.md` declares `--execution direct|subagent` in argument-hint
2. `bd-ralph` Phase 2 documents both execution branches
3. Subagent branch invokes `superpowers:subagent-driven-development --auto --finishing skip`
4. `bd-ralph` still owns workspace preparation and finishing/PR flow
5. `default-profile.md` documents `execution_strategy: direct|subagent`
6. `subagent-driven-development/SKILL.md` declares the argument contract
7. `subagent-driven-development` documents `--auto` as non-interactive with decision table
8. `subagent-driven-development` requires `--parent-issue` for `--beads full|parent`
9. `subagent-driven-development` includes per-task Beads child update logic
10. No prompt template files were changed
11. `executing-plans` was not modified
