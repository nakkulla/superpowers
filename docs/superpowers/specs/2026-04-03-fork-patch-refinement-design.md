# Fork Patch Refinement Design

## Goal

Refine the mechanically-applied patches in the superpowers fork (nakkulla/superpowers) to follow upstream's writing style, minimize divergence from obra/superpowers, and keep only what's truly necessary.

## Principles

1. **Minimal insertion** — add fork-specific content as conditional sentences within existing sections, not as separate headings wherever possible
2. **Upstream voice** — all additions in English imperative prose matching upstream's tone
3. **Preserve upstream structure** — don't restructure upstream sections (e.g., keep 4-option flow in finishing-a-development-branch)
4. **HARD-GATE economy** — use HARD-GATE blocks only where the gate is genuinely critical; consolidate duplicates

## Scope

All 11 files modified in commit `511e88b`. The categories:

| Category | Files | Action |
|----------|-------|--------|
| Beads integration | brainstorming, writing-plans, using-git-worktrees, finishing-branch | Rewrite in upstream prose, remove Korean |
| Skill-creator routing | brainstorming | Consolidate 3 HARD-GATEs → 1, inline text changes |
| Finishing branch restructure | finishing-a-development-branch | Revert to upstream 4-option, add Beads gates as 1-line sentences |
| Model overrides | 5 files (reviewers, code-reviewer agent) | Keep as-is (already clean) |
| Metadata | marketplace.json, plugin.json | Keep as-is |
| Minor tweaks | AskUserQuestion, EnterPlanMode, pyproject.toml | Keep, adjust voice only |

---

## File-by-File Design

### 1. `skills/brainstorming/SKILL.md`

**Checklist (items 1-9):**
- Restore upstream numbering (8 items, no separate "Beads integration" item)
- Keep items 1-7 identical to upstream
- Item 8: "User reviews written spec" (upstream)
- Item 9: "Transition to implementation" (upstream)
- Place a single HARD-GATE block immediately after item 9 for skill-creator routing

**Process Flow (graphviz):**
- Restore upstream graphviz exactly (no Beads diamond node)

**Terminal state paragraph:**
- Keep upstream first sentence verbatim
- Append: `The default next skill is writing-plans. **For skill/agent targets (SKILL.md), you MUST use AskUserQuestion to ask whether to use \`skill-creator\` or \`writing-plans\` before proceeding.**`

**Understanding the idea (bullet list):**
- Keep the AskUserQuestion bullet: `IMPORTANT: Use AskUserQuestion for all clarifying questions instead of plain text output. This provides structured choice UI and better UX.`

**Beads Integration section:**
- Keep as a `### Beads Integration (Post-Spec-Review)` sub-heading after Spec Self-Review
- Rewrite entirely in English:

```
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

**model: sonnet instruction:**
- Keep: `**IMPORTANT: If you dispatch a spec-document-reviewer subagent using the companion prompt template, you MUST include \`model: "sonnet"\` in the Agent tool call parameters.**`

**User Review Gate:**
- Single HARD-GATE (consolidate from 3 → 1), placed before the user review prompt
- Use English for example options: "Use skill-creator", "Use writing-plans", "Revise spec", "Stop here"

**Implementation section:**
- Keep upstream structure with added skill-creator line:
  - `Invoke the writing-plans skill to create a detailed implementation plan`
  - `For skill/agent targets (SKILL.md), use AskUserQuestion to ask whether to use \`skill-creator\` or \`writing-plans\`.`

### 2. `skills/finishing-a-development-branch/SKILL.md`

**Step 3: Revert to upstream**
- Title: "Present Options" (not "Finish Mode")
- "Present exactly these 4 options" (not 3)
- All 4 options with original wording restored

**Step 3.5: Remove entirely**
- Delete the Branch Action step — not needed with 4-option flow

**Step 4: Add Beads merge gate as 1-sentence per option**

Each gate sentence goes immediately after the `#### Option N` heading, before the bash block or other content:

- Option 1 (Merge Locally): `If this work is tied to a Beads issue, this is the only close-ready path. Run \`bd close\` only after the merge completes successfully.`
- Option 2 (Push and Create PR): `If this work is tied to a Beads issue, creating a PR does not count as merged — keep the issue open or mark it \`resolved\`.`
- Option 3 (Keep As-Is): `If this work is tied to a Beads issue, do not close it while the branch remains unmerged.`

**Common Mistakes / Red Flags:**
- Restore: "Present exactly 4 structured options" and "Present exactly 4 options"

### 3. `skills/writing-plans/SKILL.md`

**EnterPlanMode line:**
- Keep as-is: `**Do NOT use EnterPlanMode** during superpowers skill flows. Use the skill's own plan document workflow instead.`

**Beads Plan Link section:**
- Keep `### Beads Plan Link (Post-Plan-Review)` heading
- Rewrite in English:

```
After the plan review loop passes, connect the plan to the Beads issue tracker
if `.beads/` directory exists in the project:

1. Search for a related bead via `bd list --json` (priority order):
   - A bead whose `spec-id` matches the original spec path (created during brainstorming)
   - A bead whose `metadata.plan` matches the current plan path
   - A bead whose title matches the same topic
2. If found → `bd update <id> --set-metadata plan=<path> --add-label has:plan`
3. If not found → ask user via AskUserQuestion, then create per the Beads spec/plan linking rules
4. `bd dolt push`

If `.beads/` does not exist, skip this step entirely.
```

**model: sonnet instruction:**
- Keep as-is

### 4. `skills/using-git-worktrees/SKILL.md`

**pyproject.toml change:**
- Keep as-is (sensible safety guard, 1-line change)

**Beads Integration section:**
- Keep `### 3.5. Beads Integration` heading between steps 3 and 4
- Rewrite description in English:

```
After worktree creation and before project setup, check if the main repo uses Beads:

(bash block with MAIN_REPO_ROOT detection)

If `.beads/` exists:
1. Check for `bd-adopt-worktree`: `command -v bd-adopt-worktree`
2. If available → `bd-adopt-worktree <worktree-path>`
3. If not available → warn: "bd-adopt-worktree not in PATH, .beads/ will be an independent copy"
```

### 5. Small files (no changes needed)

| File | Status |
|------|--------|
| `spec-document-reviewer-prompt.md` | Keep `model: sonnet` line |
| `plan-document-reviewer-prompt.md` | Keep `model: sonnet` line |
| `subagent-driven-development/SKILL.md` | Keep `model: sonnet` instruction |
| `subagent-driven-development/spec-reviewer-prompt.md` | Keep `model: sonnet` line |
| `agents/code-reviewer.md` | Keep `model: sonnet` |
| `.claude-plugin/marketplace.json` | Keep metadata changes |
| `.claude-plugin/plugin.json` | Keep metadata changes |

---

## What Gets Removed

1. **Checklist item 8 "Beads integration"** — folded into spec self-review flow
2. **Process flow Beads diamond node** — upstream graphviz restored
3. **2 of 3 HARD-GATE blocks in brainstorming** — consolidated to 1
4. **Step 3.5 Branch Action in finishing-branch** — upstream 4-option restored
5. **All Korean text in skill files** — English only for upstream consistency
6. **"Finish Mode" / "Branch Action" terminology** — upstream "Present Options" restored

## What Gets Kept

1. All Beads integration logic (reworded in English)
2. Skill-creator routing (1 HARD-GATE + inline text)
3. All model: sonnet overrides
4. AskUserQuestion, EnterPlanMode, pyproject.toml tweaks
5. Beads merge gates in finishing-branch (as 1-sentence additions)
6. All metadata changes
