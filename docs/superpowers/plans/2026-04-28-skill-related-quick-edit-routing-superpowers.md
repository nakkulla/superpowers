# Skill-Related and Quick Edit Routing for Superpowers Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Align active superpowers skills with the new independent `skill_related` and `quick_edit` routing model without producing new `execution_lane=skill_eval_fast_path` outputs.

**Architecture:** Update only active runtime instructions and the active repo-local contract test. Treat this as skill-related work: every skill-artifact task requires `superpowers:writing-skills`, and tasks that change trigger/routing behavior or eval evidence also require `skill-creator` evidence. Preserve historical docs unless they are active tests or runtime skill instructions.

**Tech Stack:** Markdown skill files, Bash contract tests, ripgrep (`rg`), Beads metadata, local plugin sync script.

**Spec:** `docs/superpowers/specs/2026-04-28-skill-related-quick-edit-routing-superpowers-design.md`
**Parent bead:** `superpowers-3yk`
**Execution lane:** `plan`
**Skill-related:** yes

---

## File Structure

- Modify: `skills/brainstorming/SKILL.md` — replace `skill_eval_fast_path` runtime routing with independent `skill-related Classification` and `quick_edit` execution-lane rules.
- Modify: `skills/writing-plans/SKILL.md` — make skill-related routing a plan completeness gate, not a plan-skip lane.
- Modify: `skills/executing-plans/SKILL.md` — add a task-level skill-related router before edits.
- Modify or rename: `tests/claude-code/test-brainstorming-skill-eval-fast-path-contract.sh` → `tests/claude-code/test-brainstorming-skill-related-quick-edit-routing-contract.sh` — assert the new active runtime contract.
- Create: `docs/superpowers/evals/2026-04-28-skill-related-quick-edit-routing-superpowers-eval.md` — record positive, negative, behavior, and with-vs-without skill eval evidence.

This plan is skill-related.
REQUIRED SUB-SKILL: Use superpowers:writing-skills for skill artifact edits.
ALSO REQUIRED: Use skill-creator when creating a new skill, changing skill metadata, restructuring skill resources, changing trigger/routing behavior, or doing eval-driven skill iteration.

## Task 1: Rewrite the contract test first

**Files:**
- Rename/Modify: `tests/claude-code/test-brainstorming-skill-eval-fast-path-contract.sh` → `tests/claude-code/test-brainstorming-skill-related-quick-edit-routing-contract.sh`

**Skill routing:** REQUIRED SUB-SKILL: Use superpowers:writing-skills. ALSO REQUIRED: Use skill-creator because this changes skill routing behavior and eval evidence.

- [ ] **Step 1: Rename the active test file**

Run:
```bash
mv tests/claude-code/test-brainstorming-skill-eval-fast-path-contract.sh \
  tests/claude-code/test-brainstorming-skill-related-quick-edit-routing-contract.sh
```
Expected: the old path is gone and the new path exists.

- [ ] **Step 2: Replace assertions with the new routing contract**

Write this shell body:
```bash
#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BRAINSTORMING="$REPO_ROOT/skills/brainstorming/SKILL.md"
WRITING_PLANS="$REPO_ROOT/skills/writing-plans/SKILL.md"
EXECUTING_PLANS="$REPO_ROOT/skills/executing-plans/SKILL.md"

for path in "$BRAINSTORMING" "$WRITING_PLANS" "$EXECUTING_PLANS"; do
  [ -f "$path" ]
done

rg -q '## skill-related Classification' "$BRAINSTORMING"
rg -q 'skill_related=yes\|no' "$BRAINSTORMING"
rg -q 'skill_related_reason=<short reason>' "$BRAINSTORMING"
rg -q 'quick_edit_decision_reason=<short reason>' "$BRAINSTORMING"
rg -q 'quick_edit_decided_by=brainstorming' "$BRAINSTORMING"
rg -q 'execution_lane=plan\|quick_edit' "$BRAINSTORMING"
rg -q 'Set `execution_lane=quick_edit` only when `quick_edit=yes`' "$BRAINSTORMING"
rg -q 'Never create new `execution_lane=skill_eval_fast_path` output' "$BRAINSTORMING"
rg -q 'Do not invoke `skill-creator` directly from brainstorming' "$BRAINSTORMING"

! rg -q 'Record `skill_eval_fast_path` as the selected execution lane|execution_lane=skill_eval_fast_path|skill_eval_fast_path Preflight Exception' "$BRAINSTORMING" "$WRITING_PLANS" "$EXECUTING_PLANS"

rg -q '## Skill-related Plan Hard Gate' "$WRITING_PLANS"
rg -q 'This plan is skill-related' "$WRITING_PLANS"
rg -q 'plan completeness gate' "$WRITING_PLANS"
rg -q 'not an execution-lane decision' "$WRITING_PLANS"
rg -q 'Use superpowers:writing-skills' "$WRITING_PLANS"
rg -q 'Use skill-creator when creating a new skill, changing skill metadata, restructuring skill resources, changing trigger/routing behavior, or doing eval-driven skill iteration' "$WRITING_PLANS"

rg -q '## Skill-related Task Router' "$EXECUTING_PLANS"
rg -q 'before editing' "$EXECUTING_PLANS"
rg -q 'skill-related` label' "$EXECUTING_PLANS"
rg -q 'skill_related=yes' "$EXECUTING_PLANS"
rg -q 'task touches a skill artifact path' "$EXECUTING_PLANS"
rg -q 'REQUIRED SUB-SKILL: superpowers:writing-skills' "$EXECUTING_PLANS"
rg -q 'ALSO REQUIRED: skill-creator' "$EXECUTING_PLANS"
rg -q 'does not skip plan authoring' "$EXECUTING_PLANS"

echo 'PASS: brainstorming skill-related quick_edit routing contract'
```

- [ ] **Step 3: Verify RED**

Run:
```bash
bash tests/claude-code/test-brainstorming-skill-related-quick-edit-routing-contract.sh
```
Expected: FAIL before skill files are updated because `## skill-related Classification` and executor routing are missing.

- [ ] **Step 4: Commit the failing contract test**

Run:
```bash
git add tests/claude-code/test-brainstorming-skill-related-quick-edit-routing-contract.sh
git add -u tests/claude-code/test-brainstorming-skill-eval-fast-path-contract.sh
git commit -m "테스트: skill-related 라우팅 계약 추가"
```

## Task 2: Update active skill routing instructions

**Files:**
- Modify: `skills/brainstorming/SKILL.md`
- Modify: `skills/writing-plans/SKILL.md`
- Modify: `skills/executing-plans/SKILL.md`

**Skill routing:** REQUIRED SUB-SKILL: Use superpowers:writing-skills. ALSO REQUIRED: Use skill-creator because this changes trigger/routing behavior.

- [ ] **Step 1: Replace brainstorming fast-path runtime section**

In `skills/brainstorming/SKILL.md`, replace `## skill_eval_fast_path Preflight Exception` through `### Beads handling for skill_eval_fast_path` with a `## skill-related Classification` section that records:
```text
skill_related=yes|no
skill_related_reason=<short reason>
quick_edit=yes|no
quick_edit_decision_reason=<short reason>
quick_edit_decided_by=brainstorming
execution_lane=plan|quick_edit
```
Required rules:
```text
Default `execution_lane=plan`.
Set `execution_lane=quick_edit` only when `quick_edit=yes`.
Never create new `execution_lane=skill_eval_fast_path` output.
Evaluate `quick_edit` independently from `skill_related`.
Do not invoke `skill-creator` directly from brainstorming unless the user explicitly asks to continue execution in the same session.
```

- [ ] **Step 2: Update brainstorming checklist and terminal state**

Replace the checklist step that currently says to select `skill_eval_fast_path` with:
```text
Record skill-related and quick_edit decisions and stop — default `execution_lane=plan`; use `execution_lane=quick_edit` only when `quick_edit=yes`. Do not invoke `writing-plans` or `skill-creator` automatically.
```
Update the quick reference near the end so it maps only:
```text
execution_lane=plan → writing-plans / executing-plans
execution_lane=quick_edit → bounded quick_edit execution with any required skill-related discipline
```

- [ ] **Step 3: Update writing-plans hard gate**

Rename `## Skill-Target Hard Gate` to `## Skill-related Plan Hard Gate` and require the exact plan header block:
```markdown
This plan is skill-related.
REQUIRED SUB-SKILL: Use superpowers:writing-skills for skill artifact edits.
ALSO REQUIRED: Use skill-creator when creating a new skill, changing skill metadata, restructuring skill resources, changing trigger/routing behavior, or doing eval-driven skill iteration.
```
State that this is a plan completeness gate, not an execution-lane decision, and that relevant tasks must repeat the routing requirement.

- [ ] **Step 4: Add executing-plans task router**

In `skills/executing-plans/SKILL.md`, add `## Skill-related Task Router` before `### Step 2: Execute Tasks`. It must say to classify a task as skill-related before editing when the linked issue/metadata/spec/plan/touched paths/task text indicate skill work, then require:
```text
REQUIRED SUB-SKILL: superpowers:writing-skills
ALSO REQUIRED: skill-creator when the task changes metadata, triggers, routing behavior, resources, or eval-driven skill behavior.
```
It must also say the router does not skip plan authoring, Beads lifecycle, verification, review, or finishing.

- [ ] **Step 5: Verify GREEN**

Run:
```bash
bash tests/claude-code/test-brainstorming-skill-related-quick-edit-routing-contract.sh
rg -n 'skill_eval_fast_path|execution_lane=skill_eval_fast_path' skills/brainstorming/SKILL.md skills/writing-plans/SKILL.md skills/executing-plans/SKILL.md
rg -n 'skill_related|skill-related|quick_edit_decision_reason|execution_lane=plan\|quick_edit|skill-creator' skills/brainstorming/SKILL.md skills/writing-plans/SKILL.md skills/executing-plans/SKILL.md
```
Expected: contract test PASS; first `rg` prints no active runtime instructions telling agents to create new `execution_lane=skill_eval_fast_path`; second `rg` finds the new routing fields.

- [ ] **Step 6: Commit skill routing changes**

Run:
```bash
git add skills/brainstorming/SKILL.md skills/writing-plans/SKILL.md skills/executing-plans/SKILL.md
git commit -m "수정: skill-related와 quick_edit 라우팅 분리"
```

## Task 3: Record eval evidence and sync plugin copies

**Files:**
- Create: `docs/superpowers/evals/2026-04-28-skill-related-quick-edit-routing-superpowers-eval.md`
- Plugin copy side effects: local Claude/plugin cache paths touched by `scripts/sync-local-plugin-copies.sh copy`

**Skill routing:** REQUIRED SUB-SKILL: Use superpowers:writing-skills. ALSO REQUIRED: Use skill-creator because eval evidence is required for the skill routing behavior change.

- [ ] **Step 1: Record eval-first evidence**

Create `docs/superpowers/evals/2026-04-28-skill-related-quick-edit-routing-superpowers-eval.md` with sections:
```markdown
# Skill-Related and Quick Edit Routing Superpowers Eval

## Summary
## Baseline / without-skill evidence
## Changed / with-skill evidence
## Positive trigger eval
## Negative trigger eval
## Behavior / execution eval
## With-skill vs without-skill comparison
## Commands and results
## Skipped layers
```
Include the actual prompt, observed baseline behavior, changed behavior, and pass/fail judgment for each eval case.

- [ ] **Step 2: Run final local verification**

Run:
```bash
bash tests/claude-code/test-brainstorming-skill-related-quick-edit-routing-contract.sh
rg -n 'skill_eval_fast_path|execution_lane=skill_eval_fast_path' skills/brainstorming/SKILL.md skills/writing-plans/SKILL.md skills/executing-plans/SKILL.md || true
rg -n 'skill_related|skill-related|quick_edit_decision_reason|execution_lane=plan\|quick_edit|skill-creator' skills/brainstorming/SKILL.md skills/writing-plans/SKILL.md skills/executing-plans/SKILL.md
scripts/sync-local-plugin-copies.sh copy
scripts/sync-local-plugin-copies.sh verify
```
Expected: contract test PASS, no active new fast-path lane instruction, routing fields found, plugin sync verify PASS.

- [ ] **Step 3: Commit eval and sync-visible tracked changes**

Run:
```bash
git add docs/superpowers/evals/2026-04-28-skill-related-quick-edit-routing-superpowers-eval.md
git status --short
git commit -m "문서: skill-related 라우팅 평가 기록"
```
If plugin sync changes tracked files inside this repo, stage only files directly caused by the sync and commit them with the same commit or a separate Korean message.

## Self-Review

- Spec coverage: Tasks cover active runtime instruction changes, contract test rewrite/rename, eval evidence, and plugin sync checks.
- Placeholder scan: No TODO/TBD placeholders are present; every task has paths, commands, and expected results.
- Type consistency: Field names match the spec: `skill_related`, `skill_related_reason`, `quick_edit`, `quick_edit_decision_reason`, `quick_edit_decided_by`, `execution_lane=plan|quick_edit`.
- Skill routing check: Each skill-artifact task explicitly requires `superpowers:writing-skills`; each routing/eval task also requires `skill-creator`.
