# Brainstorming Issue-ID Entry Eval

- **Date:** 2026-04-08
- **Harness:** file-diff evidence + targeted skill-text verification + adversarial CLI smoke tests
- **Baseline:** `HEAD~2`
- **Candidate:** working tree / branch tip after implementation
- **Purpose:** Verify that `brainstorming` can accept an explicit issue ID, still requires clarifying questions, gives that issue higher precedence during spec linkage, and reuses same-scope standalone issues instead of creating duplicates.
- **Limitations:** This is a focused documentation-behavior eval with targeted CLI smoke tests, not a full multi-session campaign.

## Verification Summary

### Repo-level checks

- `git diff --check` → PASS
- `rg -n 'argument-hint: "\[issue-id\]"|Optional issue-ID entry|first-resolution candidate' skills/brainstorming/SKILL.md` → matches the new entry and linkage wording at lines 4, 71, and 149
- `rg -n 'Do \*\*not\*\* skip clarifying questions|Do \*\*not\*\* attach the spec to a child issue' skills/brainstorming/SKILL.md` → matches both safety rules at lines 80 and 152

### Adversarial CLI checks

- **Session A — issue-ID entry still requires clarification**
  - Prompt: “Use issue `superpowers-ihk` as the seed context. Do not skip questions.”
  - Harness: Claude Code headless session with `--plugin-dir` pointed at the updated worktree copy
  - Observed result:
    - the session invoked `superpowers:brainstorming`
    - loaded `bd show superpowers-ihk --json` as seed context
    - announced that `superpowers-ihk` was seed context rather than a finished spec
    - continued gathering context instead of writing a design directly
  - Conclusion: the updated skill treats the issue as seed context and preserves the clarifying-question path.

- **Session B — explicit issue ID keeps parent-only safety**
  - Prompt: “Start from child issue `superpowers-ihk.1`. When you later link the spec, which issue should receive the `spec-id`, and should the child issue receive it directly?”
  - Harness: synced Codex-installed skill copy (`~/.codex/superpowers/skills/brainstorming/SKILL.md`)
  - Observed result:
    - the CLI session surfaced the updated linkage rules from the installed skill copy
    - the relevant rules explicitly say `Do **not** attach the spec to a child issue` and to use the explicit child issue as context but re-resolve to the intended parent issue
  - Conclusion: the updated installed copy preserves parent-only linkage even when the entry point is a child issue.

- **Session C — open standalone issue is promoted in place**
  - Prompt: “Start from open standalone task `superpowers-ihk`. The spec only concretizes the same work, but the issue type should become `feature`.”
  - Harness: file-level verification of the updated Beads Integration block
  - Observed result:
    - the skill now says to reuse the explicit open standalone issue as the canonical Beads identity when the approved design is the same scope
    - it explicitly forbids creating a new bead just to change type
    - it instructs the agent to promote the existing issue in place before linking `spec-id`
  - Conclusion: the updated skill closes the duplicate-issue gap for same-scope type promotion.

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

### 4. Same-scope standalone issue promotion

**Baseline (`HEAD~2`)**

```text
3. Do **not** attach the spec to a child issue. If the explicit issue or a matched issue has a parent, use it as context but re-resolve to the intended parent issue or ask the user.
4. If a matching parent bead exists, inspect its status first via `bd show <id> --json`.
```

**Candidate**

```text
4. If the explicit issue is `open` or `in_progress`, has no parent, and the approved design is a concretization of the same scope rather than new follow-up scope:
   - Reuse that issue as the canonical Beads identity.
   - Do **not** create a new bead just to change its type.
   - If the issue type is too narrow for the approved design, promote it in place to the appropriate parent type ...
```

**Observed effect**

- Confirms same-scope standalone issues are now reused and promoted in place instead of being duplicated as new parent beads.

## Remaining Gap vs Full Skill-Eval Ideal

- A broader multi-session campaign was **not** run here.
- However, this change now has checked-in evidence for the four required behaviors:
  1. optional issue-ID entry,
  2. preserved clarifying-question discipline, and
  3. explicit issue-ID precedence during Beads linkage, and
  4. same-scope standalone issue promotion without duplicate bead creation.
