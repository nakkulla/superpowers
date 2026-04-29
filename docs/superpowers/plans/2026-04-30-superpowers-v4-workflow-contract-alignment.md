# Superpowers v4 Workflow Contract Alignment Implementation Plan
Parent bead: superpowers-vhy

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Align active Superpowers skill routing and evidence guidance with the v4 workflow contract vocabulary.

**Architecture:** This is a documentation-as-runtime change. Update the three active skills that own brainstorming handoff, plan authoring, and plan execution routing, then enforce the new vocabulary with a renamed contract test and a checked-in eval artifact.

**Tech Stack:** Markdown skills, shell contract tests, ripgrep assertions, Beads metadata.

**Workflow metadata:**

```text
execution_lane=plan
skill_workflow=skill_creator
skill_workflow_reason=The work changes active skill routing and evidence behavior and requires eval evidence.
quick_edit=no
```

This plan is skill-workflow `skill_creator` because it changes active skill routing/evidence behavior and includes eval evidence. It is still a normal plan lane; `skill_workflow` does not skip plan authoring.

---

### Task 1: Update brainstorming v4 handoff and review evidence guidance

**Files:**
- Modify: `skills/brainstorming/SKILL.md`

**Skill discipline:**
- **REQUIRED SUB-SKILL:** Use superpowers:writing-skills for skill artifact edits.
- **ALSO REQUIRED:** Use skill-creator because this task changes skill routing/evidence behavior.

- [ ] **Step 1: Replace the skill-related classification section with v4 skill workflow terminology**

  In `skills/brainstorming/SKILL.md`, replace `## skill-related Classification` with a `## skill_workflow Classification` section that records:

  ```text
  quick_edit=yes|no
  quick_edit_decision_reason=<short reason>
  quick_edit_decided_by=brainstorming
  execution_lane=plan|quick_edit
  skill_workflow=none|writing_skills|skill_creator
  skill_workflow_reason=<short reason>
  ```

  Include these rules:
  - Default `execution_lane=plan`.
  - Set `execution_lane=quick_edit` only when `quick_edit=yes`.
  - Choose `skill_workflow` from required downstream skill-edit discipline.
  - `skill_workflow=writing_skills` for existing skill artifact edits.
  - `skill_workflow=skill_creator` for new skills, metadata, trigger/routing behavior, resource restructure, or eval-driven behavior iteration.
  - `skill_workflow=none` for non-skill work.
  - `skill_workflow` never skips plan authoring.

- [ ] **Step 2: Update the brainstorming checklist and completion boundary**

  Replace checklist/final handoff wording that says to record `skill_related`/`skill_related_reason` with `skill_workflow`/`skill_workflow_reason`. Preserve the stop-after-spec boundary and the rule that brainstorming does not invoke planning or implementation automatically.

- [ ] **Step 3: Update Beads mirror label guidance**

  Reword `has:spec` examples so `spec_id=<path>` is the source of truth and `has:spec` is a mirror/index label that must stay aligned. Keep command examples only where useful, but explain metadata-first semantics.

- [ ] **Step 4: Update spec review freshness guidance**

  Replace legacy canonical review fields with:

  ```text
  spec_content_hash=<git hash-object <spec-path>>
  spec_reviewed_at_sha=<repo HEAD covered by the passing spec review>
  ```

  State that these values must not be advanced without a new passing review, and stale review evidence should remove/invalidate `reviewed:spec` rather than store canonical `spec_freshness` strings.

- [ ] **Step 5: Verify focused brainstorming guidance**

  Run:

  ```bash
  rg -n 'skill_workflow|spec_content_hash|spec_reviewed_at_sha|execution_lane=plan\|quick_edit|mirror/index' skills/brainstorming/SKILL.md
  rg -n 'skill_related|spec_reviewed_sha|spec_review_base_sha|spec_freshness|spec_stale_reason|skill_creator_required' skills/brainstorming/SKILL.md || true
  ```

  Expected: required v4 terms are present; any legacy matches are absent or only negative/migration warnings.

- [ ] **Step 6: Commit Task 1**

  ```bash
  git add skills/brainstorming/SKILL.md
  git commit -m "문서: brainstorming v4 workflow handoff 반영"
  ```

### Task 2: Update plan authoring and execution routing skill guidance

**Files:**
- Modify: `skills/writing-plans/SKILL.md`
- Modify: `skills/executing-plans/SKILL.md`

**Skill discipline:**
- **REQUIRED SUB-SKILL:** Use superpowers:writing-skills for skill artifact edits.
- **ALSO REQUIRED:** Use skill-creator because this task changes skill routing/evidence behavior.

- [ ] **Step 1: Update writing-plans skill workflow gate**

  Replace the `Skill-related Plan Hard Gate` wording with v4 `skill_workflow` wording. The plan header block for skill artifact work should include:

  ```text
  skill_workflow=writing_skills|skill_creator
  skill_workflow_reason=<short reason>
  execution_lane=plan|quick_edit
  ```

  Keep the rule that this is a plan completeness gate, not an execution-lane decision, and that only `execution_lane=quick_edit` can skip plan authoring.

- [ ] **Step 2: Update writing-plans task template and self-review**

  Update task guidance so every skill artifact task repeats:

  ```text
  REQUIRED SUB-SKILL: Use superpowers:writing-skills for skill artifact edits.
  ALSO REQUIRED: Use skill-creator when creating a new skill, changing skill metadata, restructuring skill resources, changing trigger/routing behavior, or doing eval-driven skill iteration.
  ```

  Update self-review to check `skill_workflow` rather than `This plan is skill-related`.

- [ ] **Step 3: Update executing-plans task router**

  Replace the skill-related router with a `## skill_workflow Task Router` section. It should classify each task before editing using linked issue/spec/plan `skill_workflow`, then validate against task paths/text. If recorded workflow and task evidence conflict, stop and reconcile before editing.

  A task requires `skill_workflow=writing_skills` when it edits skill artifact paths such as `skills/*/SKILL.md`, `skills/*/references/*`, `skills/*/scripts/*`, `skills/*/assets/*`, active skill contract tests, eval fixtures, or manifests affecting skill behavior.

  A task requires `skill_workflow=skill_creator` when it creates a new skill, changes skill metadata, trigger/routing behavior, resource structure, or eval-driven behavior.

- [ ] **Step 4: Verify focused writing/executing guidance**

  Run:

  ```bash
  rg -n 'skill_workflow|plan completeness gate|execution_lane=plan\|quick_edit|REQUIRED SUB-SKILL|ALSO REQUIRED' skills/writing-plans/SKILL.md skills/executing-plans/SKILL.md
  rg -n 'skill_related|skill-related|skill_creator_required|skill_eval_fast_path' skills/writing-plans/SKILL.md skills/executing-plans/SKILL.md || true
  ```

  Expected: required v4 terms are present; any legacy matches are absent or only negative/migration warnings.

- [ ] **Step 5: Commit Task 2**

  ```bash
  git add skills/writing-plans/SKILL.md skills/executing-plans/SKILL.md
  git commit -m "문서: plan execution skill_workflow 라우팅 반영"
  ```

### Task 3: Rename and update the v4 contract test

**Files:**
- Rename: `tests/claude-code/test-brainstorming-skill-related-quick-edit-routing-contract.sh` → `tests/claude-code/test-brainstorming-v4-workflow-routing-contract.sh`
- Modify: `tests/claude-code/run-skill-tests.sh`
- Modify: `tests/claude-code/README.md`

**Skill discipline:**
- **REQUIRED SUB-SKILL:** Use superpowers:writing-skills for skill artifact edits.
- **ALSO REQUIRED:** Use skill-creator because this task changes active skill contract tests and eval behavior.

- [ ] **Step 1: Rename the shell contract test**

  ```bash
  git mv tests/claude-code/test-brainstorming-skill-related-quick-edit-routing-contract.sh tests/claude-code/test-brainstorming-v4-workflow-routing-contract.sh
  ```

- [ ] **Step 2: Rewrite assertions for v4 vocabulary**

  Update the renamed test to assert:
  - `skill_workflow=none|writing_skills|skill_creator`
  - `skill_workflow_reason=<short reason>`
  - `execution_lane=plan|quick_edit`
  - `quick_edit` only maps to `execution_lane=quick_edit`
  - no new `execution_lane=skill_eval_fast_path`
  - no `skill_related` or `skill_creator_required` as canonical v4 metadata
  - `spec_content_hash` and `spec_reviewed_at_sha`
  - `plan_content_hash` and `plan_reviewed_at_sha`
  - `impl_reviewed_at_sha` and `impl_reviewed_diff_range`
  - writing-plans treats `skill_workflow` as a plan completeness gate
  - executing-plans classifies skill workflow before edits
  - brainstorming preserves stop-after-spec handoff.

- [ ] **Step 3: Update active test entry points**

  Replace old test path/name in:
  - `tests/claude-code/run-skill-tests.sh` help text
  - `tests/claude-code/run-skill-tests.sh` fast `tests=(...)` array
  - `tests/claude-code/README.md` specific-test example and current test list.

- [ ] **Step 4: Run contract test**

  ```bash
  bash tests/claude-code/test-brainstorming-v4-workflow-routing-contract.sh
  ```

  Expected: `PASS: brainstorming v4 workflow routing contract`.

- [ ] **Step 5: Commit Task 3**

  ```bash
  git add tests/claude-code/test-brainstorming-v4-workflow-routing-contract.sh tests/claude-code/run-skill-tests.sh tests/claude-code/README.md
  git add -u tests/claude-code/test-brainstorming-skill-related-quick-edit-routing-contract.sh
  git commit -m "테스트: v4 workflow routing contract 반영"
  ```

### Task 4: Add eval artifact and run final focused verification

**Files:**
- Create: `docs/superpowers/evals/2026-04-30-superpowers-v4-workflow-contract-alignment-eval.md`

**Skill discipline:**
- **REQUIRED SUB-SKILL:** Use superpowers:writing-skills for skill artifact edits.
- **ALSO REQUIRED:** Use skill-creator because this task records eval evidence for skill behavior changes.

- [ ] **Step 1: Create the eval artifact**

  Create `docs/superpowers/evals/2026-04-30-superpowers-v4-workflow-contract-alignment-eval.md` with:
  - baseline command evidence from the old contract test and legacy `rg` findings captured before implementation;
  - changed command evidence from the renamed v4 contract test and focused `rg` checks;
  - two fixed prompt judgments from the spec:
    - skill workflow prompt → `quick_edit=no`, `execution_lane=plan`, `skill_workflow=skill_creator`;
    - README typo prompt → `skill_workflow=none`, `execution_lane=quick_edit` only when bounded quick-edit criteria are stated;
  - a before/after conclusion that v4 vocabulary replaced active `skill_related` routing semantics.

- [ ] **Step 2: Run final focused verification**

  ```bash
  bash tests/claude-code/test-brainstorming-v4-workflow-routing-contract.sh
  rg -n 'skill_related|skill-related|spec_reviewed_sha|spec_review_base_sha|spec_freshness|spec_stale_reason|skill_creator_required' skills/brainstorming/SKILL.md skills/writing-plans/SKILL.md skills/executing-plans/SKILL.md || true
  rg -n 'skill_workflow|spec_content_hash|spec_reviewed_at_sha|plan_content_hash|plan_reviewed_at_sha|impl_reviewed_diff_range|execution_lane=plan\|quick_edit' skills/brainstorming/SKILL.md skills/writing-plans/SKILL.md skills/executing-plans/SKILL.md
  ```

  Expected: contract test passes; legacy-term matches are absent or only negative/migration warnings; v4 terms are present.

- [ ] **Step 3: Commit Task 4**

  ```bash
  git add docs/superpowers/evals/2026-04-30-superpowers-v4-workflow-contract-alignment-eval.md
  git commit -m "문서: v4 workflow contract eval 기록"
  ```

### Task 5: Final verification and implementation-review readiness

**Files:**
- No planned source edits beyond review fixes.

- [ ] **Step 1: Verify the committed implementation range**

  Record the implementation range from the spec/plan commits through the latest implementation commit:

  ```bash
  git log --oneline --decorate --max-count=12
  git diff --name-only main...HEAD
  ```

  Expected: changed files are limited to the approved spec, plan, active skills, renamed contract test, test runner/README references, and the new eval artifact.

- [ ] **Step 2: Run the focused contract test through the test runner when available**

  ```bash
  bash tests/claude-code/run-skill-tests.sh --test test-brainstorming-v4-workflow-routing-contract.sh
  ```

  Expected: renamed focused test passes. If `claude` CLI is unavailable, record that as an environment limitation and keep the direct shell contract test from Task 4 as the primary runnable verification.

- [ ] **Step 3: Prepare implementation-review packet**

  The review target is the full implementation range after Task 4. Include:
  - changed file list from `git diff --name-only main...HEAD`;
  - direct contract test output;
  - focused `rg` evidence for legacy and v4 terms;
  - eval artifact path `docs/superpowers/evals/2026-04-30-superpowers-v4-workflow-contract-alignment-eval.md`.

- [ ] **Step 4: Apply review fixes if needed**

  For blocking findings, fix, verify, commit, and re-run a focused implementation review. For non-blocking findings, record triage.

> Note: bd-ralph-v4 finish helper, post-finish audit, self-audit, self-improve, final summary gate, ledger patching, PR creation, and parent Beads resolution are orchestrator responsibilities outside this implementation plan. They are not repo-local implementation tasks.
