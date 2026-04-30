# Brainstorming Scope Split Follow-up Contract Implementation Plan
Parent bead: superpowers-h2m

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a Superpowers semantic contract and active skill guidance for description-only brainstorming scope-split follow-up issues.

**Architecture:** This is documentation-as-runtime plus shell contract tests. Add a lightweight `docs/contracts/` semantic vocabulary, update the three active workflow skills that consume it, and register a focused contract test plus eval artifact proving the follow-up boundary.

**Tech Stack:** Markdown skills, YAML semantic contract files, shell contract tests, `rg` assertions, Beads metadata.

**Workflow metadata:**

```text
execution_lane=plan
skill_workflow=skill_creator
skill_workflow_reason=The work changes active skill behavior contracts and adds eval/contract evidence.
quick_edit=no
```

This plan is skill-workflow `skill_creator` because it changes active skill behavior contracts and requires eval evidence. It remains a normal plan lane; `skill_workflow` does not skip plan authoring.

**Spec review handling:** Current-run external spec-review verdict is `APPROVE`; no findings affect plan inputs.

---

### Task 1: Add the Superpowers semantic contract files

**Files:**
- Create: `docs/contracts/README.md`
- Create: `docs/contracts/workflow-contract.yaml`
- Create: `docs/contracts/consumers.yaml`

**Skill discipline:**
- **REQUIRED SUB-SKILL:** Use superpowers:writing-skills for skill artifact and workflow contract edits.
- **ALSO REQUIRED:** Use skill-creator because this task adds behavior-contract vocabulary and eval/contract-test expectations.

- [ ] **Step 1: Write `docs/contracts/README.md`**

  Create a concise README with these sections:

  ```markdown
  # Superpowers Workflow Contracts

  This directory stores Superpowers-local semantic workflow contracts. These files describe shared vocabulary for agent-facing skills and tests; Superpowers skills do not load this YAML at runtime.

  ## Editing workflow

  Before editing a contract-aware Superpowers skill, decide whether the change affects workflow vocabulary, labels, metadata, review evidence, execution lanes, quick-edit routing, skill workflow routing, or brainstorming scope-split follow-up semantics.

  If it does, update these files together:

  - `docs/contracts/workflow-contract.yaml`
  - `docs/contracts/consumers.yaml`
  - affected skill files
  - affected contract tests
  - `tests/claude-code/run-skill-tests.sh`
  - `tests/claude-code/README.md`

  Do not duplicate the full contract schema in global instructions, `AGENTS.md`, or skill references. Do not add runtime YAML loading unless a future reviewed spec explicitly changes Superpowers from semantic consumer to runtime contract owner.

  ## Verification

  Run the focused contract tests listed in `consumers.yaml` after changing this directory or a registered consumer. Behavior-changing skill edits also need `superpowers:writing-skills` evidence and eval evidence.
  ```

- [ ] **Step 2: Write `docs/contracts/workflow-contract.yaml`**

  Define:
  - `contract.name: superpowers-workflow`
  - `contract.version: 1`
  - `contract.type: semantic`
  - `contract.runtime_loading: false`
  - vocabulary for `execution_lane`, `quick_edit`, `quick_edit_decision_reason`, `quick_edit_decided_by`, `skill_workflow`, `skill_workflow_reason`, `spec_id`, `has:spec`, `reviewed:spec`, `spec_content_hash`, `spec_reviewed_at_sha`, `artifact_links`, `review_evidence`, and `scope_split_followup`.

  Ensure `scope_split_followup` includes required metadata `origin`, `source_spec_id`, `source_parent`, `scope_relation`, `spec_policy`; required values `origin=brainstorming_scope_split`, `scope_relation=follow_up`, `spec_policy=future_brainstorming_required`; and forbidden pre-spec fields `spec_id`, `has:spec`, `reviewed:spec`, `spec_content_hash`, `spec_reviewed_at_sha`, `execution_lane`, `quick_edit`, `quick_edit_decision_reason`, `quick_edit_decided_by`, `skill_workflow`, `skill_workflow_reason`.

- [ ] **Step 3: Write `docs/contracts/consumers.yaml`**

  Register these active consumers:
  - `skills/brainstorming/SKILL.md`
  - `skills/writing-plans/SKILL.md`
  - `skills/executing-plans/SKILL.md`
  - `tests/claude-code/test-brainstorming-v4-workflow-routing-contract.sh`
  - `tests/claude-code/test-brainstorming-scope-split-followup-contract.sh`

- [ ] **Step 4: Verify YAML text shape with `rg`**

  Run:

  ```bash
  rg -n 'runtime_loading: false|scope_split_followup|future_brainstorming_required|forbidden_pre_spec_fields|skills/brainstorming/SKILL.md|test-brainstorming-scope-split-followup-contract.sh' docs/contracts
  ```

  Expected: all contract vocabulary and consumer paths are present.

- [ ] **Step 5: Commit Task 1**

  ```bash
  git add docs/contracts/README.md docs/contracts/workflow-contract.yaml docs/contracts/consumers.yaml
  git commit -m "문서: Superpowers semantic contract 추가"
  ```

### Task 2: Update active skill guidance for scope-split follow-ups

**Files:**
- Modify: `skills/brainstorming/SKILL.md`
- Modify: `skills/writing-plans/SKILL.md`
- Modify: `skills/executing-plans/SKILL.md`

**Skill discipline:**
- **REQUIRED SUB-SKILL:** Use superpowers:writing-skills for skill artifact edits.
- **ALSO REQUIRED:** Use skill-creator because this task changes active skill behavior contracts.

- [ ] **Step 1: Update brainstorming scope assessment**

  In `skills/brainstorming/SKILL.md`, extend the scope assessment near the project-scope bullets so it distinguishes:
  - single-scope work;
  - too-large work that needs sub-project decomposition;
  - main scope plus related follow-ups.

  Add rules that the current run writes only the selected main spec, asks the user to confirm the main scope before writing, and does not write separate follow-up specs in the same brainstorming run.

- [ ] **Step 2: Update brainstorming Beads handoff**

  In the Beads review/completion area, add a concise `Scope-split follow-up handoff` subsection saying durable follow-up issues are created only during final brainstorming handoff after the user approves the written main spec. The handoff should first confirm the approved main spec is linked to its parent bead, then create/link any accepted description-only follow-up issues; do not create durable follow-up issues before that approval gate.

  Include the canonical metadata block:

  ```text
  origin=brainstorming_scope_split
  source_spec_id=<main spec path>
  source_parent=<main parent bead id>
  scope_relation=follow_up
  spec_policy=future_brainstorming_required
  ```

  Also list forbidden pre-spec fields: `spec_id`, `has:spec`, `reviewed:spec`, `spec_content_hash`, `spec_reviewed_at_sha`, `execution_lane`, `quick_edit`, `quick_edit_decision_reason`, `quick_edit_decided_by`, `skill_workflow`, `skill_workflow_reason`.

- [ ] **Step 3: Update writing-plans pre-spec follow-up guard**

  In `skills/writing-plans/SKILL.md`, add a guard near the scope or Beads linkage guidance: a Beads issue with `origin=brainstorming_scope_split` or `spec_policy=future_brainstorming_required` is not plan-ready. Stop and require a future brainstorming/spec gate before writing a plan from that issue.

- [ ] **Step 4: Update executing-plans pre-spec follow-up guard**

  In `skills/executing-plans/SKILL.md`, add a guard before plan/task execution: a Beads issue with `origin=brainstorming_scope_split` or `spec_policy=future_brainstorming_required` is not execution-ready. Stop and route to the future brainstorming/spec workflow instead of inferring implementation scope from the description.

- [ ] **Step 5: Verify skill guidance**

  Run:

  ```bash
  rg -n 'brainstorming_scope_split|future_brainstorming_required|description-only|forbidden pre-spec|not plan-ready|not execution-ready|do not write separate follow-up specs' skills/brainstorming/SKILL.md skills/writing-plans/SKILL.md skills/executing-plans/SKILL.md
  ```

  Expected: all new scope-split terms and guards are present.

- [ ] **Step 6: Commit Task 2**

  ```bash
  git add skills/brainstorming/SKILL.md skills/writing-plans/SKILL.md skills/executing-plans/SKILL.md
  git commit -m "문서: scope-split follow-up skill guidance 추가"
  ```

### Task 3: Add and register the scope-split contract test

**Files:**
- Create: `tests/claude-code/test-brainstorming-scope-split-followup-contract.sh`
- Modify: `tests/claude-code/run-skill-tests.sh`
- Modify: `tests/claude-code/README.md`

**Skill discipline:**
- **REQUIRED SUB-SKILL:** Use superpowers:writing-skills for active skill contract tests.
- **ALSO REQUIRED:** Use skill-creator because this task adds eval/contract evidence for skill behavior.

- [ ] **Step 1: Write the contract test**

  Create a shell test that sets `REPO_ROOT`, points to `skills/brainstorming/SKILL.md`, `skills/writing-plans/SKILL.md`, `skills/executing-plans/SKILL.md`, `docs/contracts/workflow-contract.yaml`, and `docs/contracts/consumers.yaml`, verifies `rg` is available, and asserts:
  - contract metadata contains `name: superpowers-workflow`, `type: semantic`, and `runtime_loading: false`;
  - `scope_split_followup` has the required metadata, required values, and forbidden fields;
  - brainstorming contains the scope split rules, metadata, forbidden fields, and description-only follow-up language;
  - writing-plans contains the not-plan-ready guard;
  - executing-plans contains the not-execution-ready guard;
  - consumer registry lists the three skills and both active contract tests.

  End with:

  ```bash
  echo 'PASS: brainstorming scope split follow-up contract'
  ```

- [ ] **Step 2: Register the test runner entry**

  Add `test-brainstorming-scope-split-followup-contract.sh` to `tests/claude-code/run-skill-tests.sh` help output and the fast `tests=(...)` array.

- [ ] **Step 3: Update test README**

  Add the new test to `tests/claude-code/README.md` specific-test examples and current fast test list. Describe that it verifies description-only scope-split follow-up semantics and the Superpowers semantic contract registry.

- [ ] **Step 4: Run focused tests**

  ```bash
  bash tests/claude-code/test-brainstorming-scope-split-followup-contract.sh
  bash tests/claude-code/test-brainstorming-v4-workflow-routing-contract.sh
  ```

  Expected: both tests print `PASS`.

- [ ] **Step 5: Commit Task 3**

  ```bash
  git add tests/claude-code/test-brainstorming-scope-split-followup-contract.sh tests/claude-code/run-skill-tests.sh tests/claude-code/README.md
  git commit -m "테스트: scope-split follow-up contract 추가"
  ```

### Task 4: Add eval artifact and final implementation verification

**Files:**
- Create: `docs/superpowers/evals/2026-04-30-brainstorming-scope-split-followup-contract-eval.md`

**Skill discipline:**
- **REQUIRED SUB-SKILL:** Use superpowers:writing-skills for skill behavior eval evidence.
- **ALSO REQUIRED:** Use skill-creator because this task records eval evidence for behavior-changing skill guidance.

- [ ] **Step 1: Create the eval artifact**

  Record:
  - baseline evidence: existing `test-brainstorming-v4-workflow-routing-contract.sh` passed before implementation, while no `docs/contracts/` directory or scope-split test existed;
  - changed behavior: new semantic contract, scope-split skill guidance, not-plan-ready and not-execution-ready guards, new test registration;
  - pressure scenario: a brainstorming run discovers a main spec plus related future work, and the expected behavior is one main spec plus description-only follow-up issue metadata, not two specs;
  - verification commands and results from the focused tests.

- [ ] **Step 2: Run final focused verification**

  ```bash
  bash tests/claude-code/test-brainstorming-scope-split-followup-contract.sh
  bash tests/claude-code/test-brainstorming-v4-workflow-routing-contract.sh
  bash tests/claude-code/run-skill-tests.sh --test test-brainstorming-scope-split-followup-contract.sh
  rg -n 'runtime_loading: false|scope_split_followup|future_brainstorming_required|not plan-ready|not execution-ready' docs/contracts skills tests/claude-code docs/superpowers/evals/2026-04-30-brainstorming-scope-split-followup-contract-eval.md
  ```

  Expected: shell tests pass; runner can invoke the new fast test; focused `rg` evidence shows contract vocabulary and guards.

- [ ] **Step 3: Commit Task 4**

  ```bash
  git add docs/superpowers/evals/2026-04-30-brainstorming-scope-split-followup-contract-eval.md
  git commit -m "문서: scope-split follow-up eval 기록"
  ```

### Task 5: Review readiness and finish evidence

**Files:**
- No planned source edits beyond review fixes.

- [ ] **Step 1: Inspect implementation range**

  ```bash
  git diff --name-only main...HEAD
  git log --oneline --decorate --max-count=12
  ```

  Expected: changed files are limited to the approved spec/plan, `docs/contracts/`, active skills, contract tests/README/runner, eval artifact, and workflow ledger artifacts.

- [ ] **Step 2: Prepare implementation-review packet**

  Include:
  - changed file list;
  - direct focused test results;
  - runner result for the new test;
  - eval artifact path;
  - confirmation that no runtime YAML loading was added.

- [ ] **Step 3: Apply review fixes if needed**

  For blocking findings, fix, verify, commit, and request focused re-review. For non-blocking findings, record triage in the finish evidence.

> Note: bd-ralph-v4 finish helper, post-finish audit, self-audit, self-improve, final summary gate, ledger patching, PR creation, and parent Beads resolution are orchestrator responsibilities outside this implementation plan.
