---
name: writing-plans
description: Use when you have a spec or requirements for a multi-step task, before touching code, including non-interactive `--auto` plan generation
---

# Writing Plans

## Overview

Write comprehensive implementation plans assuming the engineer has zero context for our codebase and questionable taste. Document everything they need to know: which files to touch for each task, code, testing, docs they might need to check, how to test it. Give them the whole plan as bite-sized tasks. DRY. YAGNI. TDD. Frequent commits.

Assume they are a skilled developer, but know almost nothing about our toolset or problem domain. Assume they don't know good test design very well.

This skill's normal completion boundary is the saved plan document. After the plan is written, self-reviewed, and linked to Beads when applicable, report the plan path and stop. Do not proactively start implementation or offer execution routing in the same turn.

**Announce at start:** "I'm using the writing-plans skill to create the implementation plan."

**Do NOT use EnterPlanMode** during superpowers skill flows. Use the skill's own plan document workflow instead.

**Context:** This should be run in a dedicated worktree (created by brainstorming skill).

**Save plans to:** `docs/superpowers/plans/YYYY-MM-DD-<feature-name>.md`
- (User preferences for plan location override this default)

## Auto Mode

When invoked with `--auto`, this skill must:
- generate and save the plan,
- complete the built-in self-review,
- link the plan to the Beads parent issue immediately after the built-in self-review when enough context exists,
- return the final plan path,
- exit without asking the execution-choice question.

If the parent issue cannot be resolved safely in auto mode, fail fast instead of asking.
In particular, if the best-matching parent issue is already `resolved` or `closed`, auto mode must fail fast instead of overwriting its `metadata.plan`.

## Skill-Target Hard Gate

If the plan creates or modifies any skill artifact (`SKILL.md`, `agents/openai.yaml`, or files under a skill's `references/`, `scripts/`, or `assets/`), treat it as a skill-targeted plan.

For skill-targeted plans:
- **REQUIRED SUB-SKILL:** Use superpowers:writing-skills
- **ALSO REQUIRED:** Use skill-creator when creating a new skill, changing skill metadata, restructuring the skill layout, or doing eval-driven iteration

If this routing is missing from the relevant tasks, the plan is incomplete.

## Scope Check

If the spec covers multiple independent subsystems, it should have been broken into sub-project specs during brainstorming. If it wasn't, suggest breaking this into separate plans — one per subsystem. Each plan should produce working, testable software on its own.

## File Structure

Before defining tasks, map out which files will be created or modified and what each one is responsible for. This is where decomposition decisions get locked in.

- Design units with clear boundaries and well-defined interfaces. Each file should have one clear responsibility.
- You reason best about code you can hold in context at once, and your edits are more reliable when files are focused. Prefer smaller, focused files over large ones that do too much.
- Files that change together should live together. Split by responsibility, not by technical layer.
- In existing codebases, follow established patterns. If the codebase uses large files, don't unilaterally restructure - but if a file you're modifying has grown unwieldy, including a split in the plan is reasonable.

This structure informs the task decomposition. Each task should produce self-contained changes that make sense independently.

## Bite-Sized Task Granularity

**Each step is one action (2-5 minutes):**
- "Write the failing test" - step
- "Run it to make sure it fails" - step
- "Implement the minimal code to make the test pass" - step
- "Run the tests and make sure they pass" - step
- "Commit" - step

## Plan Document Header

**Every plan MUST start with this header:**

```markdown
# [Feature Name] Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** [One sentence describing what this builds]

**Architecture:** [2-3 sentences about approach]

**Tech Stack:** [Key technologies/libraries]

---
```

## Task Structure

````markdown
### Task N: [Component Name]

**Files:**
- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py:123-145`
- Test: `tests/exact/path/to/test.py`

- [ ] **Step 1: Write the failing test**

```python
def test_specific_behavior():
    result = function(input)
    assert result == expected
```

- [ ] **Step 2: Run test to verify it fails**

Run: `pytest tests/path/test.py::test_name -v`
Expected: FAIL with "function not defined"

- [ ] **Step 3: Write minimal implementation**

```python
def function(input):
    return expected
```

- [ ] **Step 4: Run test to verify it passes**

Run: `pytest tests/path/test.py::test_name -v`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add tests/path/test.py src/path/file.py
git commit -m "feat: add specific feature"
```
````

> If a task touches any skill artifact (`SKILL.md`, `agents/openai.yaml`, or a skill's `references/`, `scripts/`, `assets/` files):
> - **REQUIRED SUB-SKILL:** Use superpowers:writing-skills
> - **ALSO REQUIRED:** Use skill-creator when creating a new skill, changing metadata, restructuring the skill, or doing eval-driven iteration

## No Placeholders

Every step must contain the actual content an engineer needs. These are **plan failures** — never write them:
- "TBD", "TODO", "implement later", "fill in details"
- "Add appropriate error handling" / "add validation" / "handle edge cases"
- "Write tests for the above" (without actual test code)
- "Similar to Task N" (repeat the code — the engineer may be reading tasks out of order)
- Steps that describe what to do without showing how (code blocks required for code steps)
- References to types, functions, or methods not defined in any task

## Remember
- Exact file paths always
- Complete code in every step — if a step changes code, show the code
- Exact commands with expected output
- DRY, YAGNI, TDD, frequent commits

## Self-Review

After writing the complete plan, look at the spec with fresh eyes and check the plan against it. This is a checklist you run yourself — not a subagent dispatch.

**1. Spec coverage:** Skim each section/requirement in the spec. Can you point to a task that implements it? List any gaps.

**2. Placeholder scan:** Search your plan for red flags — any of the patterns from the "No Placeholders" section above. Fix them.

**3. Type consistency:** Do the types, method signatures, and property names you used in later tasks match what you defined in earlier tasks? A function called `clearLayers()` in Task 3 but `clearFullLayers()` in Task 7 is a bug.

**4. Skill routing check:** If any task touches a skill artifact, verify that `superpowers:writing-skills` is explicitly required, and that `skill-creator` is also required when applicable.

If you find issues, fix them inline. No need to re-review — just fix and move on. If you find a spec requirement with no task, add the task.

### Beads Plan Link

After saving the plan and completing the built-in self-review, connect the plan
to the Beads issue tracker if `.beads/` directory exists in the project:

**Hard gate:** When `.beads/` exists, the plan is not complete until one of the
following is true:
- an `open` or `in_progress` parent bead is linked to the current plan
- a new follow-up parent bead has been created and linked to the current spec/plan
- the user explicitly chose to defer bead creation/linkage for now

Do **not** stop with "no matching parent bead found" or "linkage not done yet".
If the closest related bead is `resolved` or `closed`, treat that as
"new follow-up parent bead required", not as a reason to end the turn.

**Safety check:** Link the plan to the Beads **parent** issue only.

1. Search for a related **parent** bead via `bd list --json` (priority order):
   - A bead whose `spec-id` matches the original spec path (created during brainstorming)
   - A bead whose `metadata.plan` matches the current plan path
   - A bead whose title matches the same topic
2. Do **not** attach `metadata.plan` to a child bead. If a match has a parent, re-resolve to the intended parent issue or ask the user.
3. If a matching parent bead exists, inspect its status first via `bd show <id> --json`.
4. If the matched parent bead status is `open` or `in_progress` → `bd update <id> --set-metadata plan=<path> --add-label has:plan`
5. Re-check that `metadata.plan` is set correctly.
6. If the matched parent bead status is `resolved` or `closed`, do **not** overwrite its `metadata.plan`.
   - Treat this as follow-up work beyond the original bead scope.
   - Ask the user via the platform-appropriate confirmation tool whether to create a new follow-up parent bead instead.
   - If approved, create the new bead and connect it back to the original bead with `discovered-from` when possible (for example: `bd dep add <new-id> <old-id> --type discovered-from`).
   - If the current plan was written from a saved spec, set the new bead's `spec_id` to that spec path before finishing linkage.
   - Immediately after creation: `bd update <new-id> --set-metadata plan=<path> --add-label has:plan`
   - Re-check that both `spec_id` (when applicable) and `metadata.plan` are set correctly on the new parent bead.
7. If not found:
   - Ask the user via the platform-appropriate confirmation tool whether to create a new parent bead now or explicitly defer it.
   - If approved, create the new parent bead per the Beads spec/plan linking rules.
   - If the current plan was written from a saved spec, set the new bead's `spec_id` to that spec path.
   - Immediately after creation: `bd update <new-id> --set-metadata plan=<path> --add-label has:plan`
   - Re-check that both `spec_id` (when applicable) and `metadata.plan` are set correctly on the new parent bead.
   - If the user explicitly defers creation, report that choice clearly instead of implying linkage is already done.
8. `bd dolt push`

If `.beads/` does not exist, skip this step entirely.

This linkage records the current plan document even when the linked bead does not
yet have `reviewed:plan`.

**IMPORTANT: If you dispatch a plan-document-reviewer subagent using the companion prompt template, you MUST include `model: "sonnet"` in the Agent tool call parameters.**

## Completion Boundary

### Default interactive branch

After saving the plan, completing the built-in self-review, and finishing any
Beads linkage:

- If `.beads/` exists, do **not** stop until the current plan is linked to an
  active parent bead, a new follow-up parent bead has been created and linked,
  or the user explicitly deferred bead creation/linkage.
- Report that the plan was saved and include the final plan path.
- Stop after planning in this turn.
- Do **not** proactively offer execution choices in the same response.

If the user later asks how to execute the plan or asks you to start
implementation, that later turn may invoke:
- **superpowers:subagent-driven-development** for subagent execution
- **superpowers:executing-plans** for direct execution

### `--auto` branch

Return the plan path and stop.
즉, `--auto`에서는 execution choice 질문 없이 종료한다.
