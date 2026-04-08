# Review State Freshness and Reconciliation Hardening Implementation Plan
Parent bead: superpowers-efy

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Harden review-state propagation, stale-review rejection, subagent lifecycle cleanup, and finish-phase SHA reconciliation across `plan-review`, `implementation-review`, `subagent-driven-development`, and `bd-ralph`.

**Architecture:** This work keeps the existing workflow shape and tightens contracts at the correct layer. Review-family skills become authoritative reporters of post-fix state, while workflow orchestrators validate workspace materialization, reject stale review verdicts, close superseded agents, and reconcile durable Beads SHA metadata. The implementation is mostly skill-documentation edits plus small contract tests that lock the new wording in place.

**Tech Stack:** Markdown skill files, shell contract tests, grep-based verification, Beads metadata

---

### Task 1: Add post-fix state outputs to `plan-review`

> **REQUIRED SUB-SKILL:** Use superpowers:writing-skills

**Files:**
- Modify: `/Users/isy_macstudio/Documents/GitHub/dotfiles/shared/skills/plan-review/SKILL.md:201-241`
- Modify: `/Users/isy_macstudio/Documents/GitHub/dotfiles/tests/review_skill_artifact_mode_contract_test.sh:32-40`

- [ ] **Step 1: Extend the review-skill contract test first**

Add assertions for the new machine-readable fields to `/Users/isy_macstudio/Documents/GitHub/dotfiles/tests/review_skill_artifact_mode_contract_test.sh` immediately after the existing `plan-review` assertions:

```bash
assert_contains "$PLAN_REVIEW_SKILL" "plan-review reports auto-fix applied state" 'Auto-fix applied: <yes|no>'
assert_contains "$PLAN_REVIEW_SKILL" "plan-review reports post-fix head" 'Post-fix HEAD: <sha|unchanged>'
assert_contains "$PLAN_REVIEW_SKILL" "plan-review reports changed files" 'Post-fix changed files: <comma-separated files|none>'
assert_contains "$PLAN_REVIEW_SKILL" "plan-review reports clean working tree" 'Working tree clean: <yes|no>'
```

- [ ] **Step 2: Run the contract test to capture the initial failure**

Run:

```bash
bash /Users/isy_macstudio/Documents/GitHub/dotfiles/tests/review_skill_artifact_mode_contract_test.sh
```

Expected: FAIL because `plan-review` does not yet document the new post-fix output fields.

- [ ] **Step 3: Update the `plan-review` machine-readable summary**

Replace the current automated summary block in `/Users/isy_macstudio/Documents/GitHub/dotfiles/shared/skills/plan-review/SKILL.md` so it reads:

```markdown
When this skill is invoked in an automated subagent flow, end with a compact machine-readable summary in plain text:
- Verdict: <APPROVE|APPROVE_WITH_CHANGES|REVISE|REJECT>
- Iterations: <N/3>
- Fixes applied: <comma-separated IDs or none>
- Output ref: <path, SHA, or other concrete reference>
- Auto-fix applied: <yes|no>
- Post-fix HEAD: <sha|unchanged>
- Post-fix changed files: <comma-separated files|none>
- Working tree clean: <yes|no>
```

Also add one clarifying line under `### 7. Auto-Fix Loop`:

```markdown
- 자동 수정이 실제 파일 변경을 만들었다면, 종료 요약에 post-fix HEAD / changed files / clean state를 반드시 포함한다.
```

- [ ] **Step 4: Re-run the review contract test**

Run:

```bash
bash /Users/isy_macstudio/Documents/GitHub/dotfiles/tests/review_skill_artifact_mode_contract_test.sh
```

Expected: PASS for all `plan-review` assertions, including the new post-fix output fields.

- [ ] **Step 5: Commit**

```bash
git add \
  /Users/isy_macstudio/Documents/GitHub/dotfiles/shared/skills/plan-review/SKILL.md \
  /Users/isy_macstudio/Documents/GitHub/dotfiles/tests/review_skill_artifact_mode_contract_test.sh
git commit -m "docs: plan-review post-fix 상태 출력 계약 추가"
```

---

### Task 2: Add post-fix state and reconciliation signals to `implementation-review`

> **REQUIRED SUB-SKILL:** Use superpowers:writing-skills

**Files:**
- Modify: `/Users/isy_macstudio/Documents/GitHub/dotfiles/shared/skills/implementation-review/SKILL.md:21-30`
- Modify: `/Users/isy_macstudio/Documents/GitHub/dotfiles/shared/skills/implementation-review/SKILL.md:205-245`
- Modify: `/Users/isy_macstudio/Documents/GitHub/dotfiles/tests/review_skill_artifact_mode_contract_test.sh:52-61`

- [ ] **Step 1: Add implementation-review contract assertions first**

Append these assertions after the existing `implementation-review` assertions in `/Users/isy_macstudio/Documents/GitHub/dotfiles/tests/review_skill_artifact_mode_contract_test.sh`:

```bash
assert_contains "$IMPL_REVIEW_SKILL" "implementation-review reports base sha" 'Review BASE_SHA: <sha>'
assert_contains "$IMPL_REVIEW_SKILL" "implementation-review reports head sha" 'Review HEAD_SHA: <sha>'
assert_contains "$IMPL_REVIEW_SKILL" "implementation-review reports auto-fix applied state" 'Auto-fix applied: <yes|no>'
assert_contains "$IMPL_REVIEW_SKILL" "implementation-review reports post-fix head" 'Post-fix HEAD: <sha|unchanged>'
assert_contains "$IMPL_REVIEW_SKILL" "implementation-review reports changed files" 'Post-fix changed files: <comma-separated files|none>'
assert_contains "$IMPL_REVIEW_SKILL" "implementation-review reports reconciliation requirement" 'Metadata reconciliation required: <yes|no>'
```

- [ ] **Step 2: Run the contract test and confirm the new assertions fail**

Run:

```bash
bash /Users/isy_macstudio/Documents/GitHub/dotfiles/tests/review_skill_artifact_mode_contract_test.sh
```

Expected: FAIL on the newly added `implementation-review` assertions.

- [ ] **Step 3: Document the new summary fields in `implementation-review`**

In `/Users/isy_macstudio/Documents/GitHub/dotfiles/shared/skills/implementation-review/SKILL.md`, keep the existing `metadata.sha` diff rule and replace the automated summary block with:

```markdown
When this skill is invoked in an automated subagent flow, end with a compact machine-readable summary in plain text:
- Verdict: <APPROVE|APPROVE_WITH_CHANGES|REVISE|REJECT>
- Iterations: <N/3>
- Fixes applied: <comma-separated IDs or none>
- Output ref: <path, SHA, or other concrete reference>
- Review BASE_SHA: <sha>
- Review HEAD_SHA: <sha>
- Auto-fix applied: <yes|no>
- Post-fix HEAD: <sha|unchanged>
- Post-fix changed files: <comma-separated files|none>
- Metadata reconciliation required: <yes|no>
```

Then add one explicit auto-fix loop rule under `### 7. Auto-Fix Loop`:

```markdown
- finish-phase caller가 post-fix metadata 재조정을 판단할 수 있도록, 자동 수정이 코드 diff를 만들면 `Metadata reconciliation required: yes`를 반환한다.
```

- [ ] **Step 4: Re-run the contract test**

Run:

```bash
bash /Users/isy_macstudio/Documents/GitHub/dotfiles/tests/review_skill_artifact_mode_contract_test.sh
```

Expected: PASS for the full review-skill contract test, including the new `implementation-review` output fields.

- [ ] **Step 5: Commit**

```bash
git add \
  /Users/isy_macstudio/Documents/GitHub/dotfiles/shared/skills/implementation-review/SKILL.md \
  /Users/isy_macstudio/Documents/GitHub/dotfiles/tests/review_skill_artifact_mode_contract_test.sh
git commit -m "docs: implementation-review 재조정 신호 출력 계약 추가"
```

---

### Task 3: Harden `subagent-driven-development` freshness and agent lifecycle

> **REQUIRED SUB-SKILL:** Use superpowers:writing-skills

**Files:**
- Modify: `skills/subagent-driven-development/SKILL.md:15-64`
- Modify: `skills/subagent-driven-development/SKILL.md:96-130`
- Modify: `skills/subagent-driven-development/spec-reviewer-prompt.md:14-71`
- Modify: `skills/subagent-driven-development/code-quality-reviewer-prompt.md:13-29`
- Add: `tests/claude-code/test-subagent-driven-development-contracts.sh`
- Modify: `tests/claude-code/run-skill-tests.sh:54-71`

- [ ] **Step 1: Add a contract test for freshness and lifecycle wording**

Create `tests/claude-code/test-subagent-driven-development-contracts.sh` with this content:

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$ROOT/skills/subagent-driven-development/SKILL.md"
SPEC_PROMPT="$ROOT/skills/subagent-driven-development/spec-reviewer-prompt.md"
QUALITY_PROMPT="$ROOT/skills/subagent-driven-development/code-quality-reviewer-prompt.md"
PASS=0
FAIL=0

assert_contains() {
  local file="$1" needle="$2" label="$3"
  if grep -Fq -- "$needle" "$file"; then
    PASS=$((PASS + 1))
  else
    echo "FAIL: $label"
    FAIL=$((FAIL + 1))
  fi
}

assert_contains "$SKILL" 'STALE_REVIEW' 'controller names stale review handling'
assert_contains "$SKILL" 'close that reviewer agent' 'controller closes completed reviewers'
assert_contains "$SKILL" 'close that implementer agent' 'controller closes completed implementers'
assert_contains "$SKILL" 'bounded live-agent budget' 'controller documents live-agent budget'
assert_contains "$SPEC_PROMPT" 'HEAD_SHA: [current commit for this review]' 'spec reviewer prompt includes head sha'
assert_contains "$SPEC_PROMPT" 'If your finding does not map to the current diff scope, return NEEDS_CONTEXT instead of speculating.' 'spec reviewer prompt rejects stale findings'
assert_contains "$QUALITY_PROMPT" 'CHANGED_FILES: [files changed for this task]' 'code quality prompt includes changed files'
assert_contains "$QUALITY_PROMPT" 'If a concern is outside the current diff, treat it as out of scope for this review.' 'code quality prompt rejects out-of-scope findings'

echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ]
```

- [ ] **Step 2: Wire the new contract test into the Claude test runner and confirm it fails**

Update `tests/claude-code/run-skill-tests.sh` so the fast test list becomes:

```bash
tests=(
    "test-subagent-driven-development.sh"
    "test-subagent-driven-development-contracts.sh"
)
```

Run:

```bash
bash tests/claude-code/test-subagent-driven-development-contracts.sh
```

Expected: FAIL because the skill/prompt files do not yet document stale-review handling and explicit close rules.

- [ ] **Step 3: Update the reviewer prompt templates for freshness inputs**

In `skills/subagent-driven-development/spec-reviewer-prompt.md`, replace the request header and add the explicit stale-review instruction:

```markdown
## What Was Requested

[FULL TEXT of task requirements]

BASE_SHA: [commit before this task]
HEAD_SHA: [current commit for this review]
CHANGED_FILES: [files changed for this task]
OPTIONAL_CHANGED_HUNKS_SUMMARY: [brief summary of touched areas]
```

and add:

```markdown
If your finding does not map to the current diff scope, return NEEDS_CONTEXT instead of speculating.
```

In `skills/subagent-driven-development/code-quality-reviewer-prompt.md`, extend the packet header to:

```markdown
WHAT_WAS_IMPLEMENTED: [from implementer's report]
PLAN_OR_REQUIREMENTS: Task N from [plan-file]
BASE_SHA: [commit before task]
HEAD_SHA: [current commit]
CHANGED_FILES: [files changed for this task]
DESCRIPTION: [task summary]
```

and append:

```markdown
- If a concern is outside the current diff, treat it as out of scope for this review.
```

- [ ] **Step 4: Update the controller rules in `skills/subagent-driven-development/SKILL.md`**

Add these rules under `## Auto Mode` / process guidance:

```markdown
- Reviewer packets must include `BASE_SHA`, `HEAD_SHA`, and `CHANGED_FILES` for the current task.
- If a reviewer reports findings outside the current diff, treat that verdict as `STALE_REVIEW`, discard it, and re-dispatch a fresh reviewer with a tighter context packet.
- Maintain a bounded live-agent budget during long runs; close completed or superseded agents before dispatching replacements.
- After an implementer result is harvested and no immediate follow-up is pending, close that implementer agent.
- After a reviewer verdict is harvested, close that reviewer agent.
```

Also update the process section so the per-task loop explicitly closes harvested reviewers before re-review and before moving to the next task.

- [ ] **Step 5: Run the new contract test and the existing skill smoke test**

Run:

```bash
bash tests/claude-code/test-subagent-driven-development-contracts.sh
bash tests/claude-code/test-subagent-driven-development.sh
```

Expected: both PASS, confirming the new contract wording and the existing descriptive behavior still align.

- [ ] **Step 6: Commit**

```bash
git add \
  skills/subagent-driven-development/SKILL.md \
  skills/subagent-driven-development/spec-reviewer-prompt.md \
  skills/subagent-driven-development/code-quality-reviewer-prompt.md \
  tests/claude-code/test-subagent-driven-development-contracts.sh \
  tests/claude-code/run-skill-tests.sh
git commit -m "docs: subagent freshness와 lifecycle 계약 강화"
```

---

### Task 4: Add `bd-ralph` plan materialization and finish reconciliation gates

> **REQUIRED SUB-SKILL:** Use superpowers:writing-skills

**Files:**
- Modify: `/Users/isy_macstudio/Documents/GitHub/dotfiles/shared/skills/bd-ralph/SKILL.md:80-103`
- Modify: `/Users/isy_macstudio/Documents/GitHub/dotfiles/shared/skills/bd-ralph/SKILL.md:128-229`
- Modify: `/Users/isy_macstudio/Documents/GitHub/dotfiles/tests/bd_ralph_contract_test.sh:21-75`

- [ ] **Step 1: Extend the `bd-ralph` contract test first**

Add these assertions to `/Users/isy_macstudio/Documents/GitHub/dotfiles/tests/bd_ralph_contract_test.sh` near the existing Phase 1/Phase 3 checks:

```bash
assert_contains "$BD_RALPH" 'Post-fix HEAD' "bd-ralph observes review post-fix head"
assert_contains "$BD_RALPH" 'Working tree clean' "bd-ralph observes review working-tree cleanliness"
assert_contains "$BD_RALPH" 'Commit-first' "bd-ralph documents commit-first plan propagation"
assert_contains "$BD_RALPH" 'Copy-forward' "bd-ralph documents copy-forward plan propagation"
assert_contains "$BD_RALPH" 'Metadata reconciliation required' "bd-ralph consumes implementation-review reconciliation signal"
assert_contains "$BD_RALPH" 'update the parent bead `metadata.sha`' "bd-ralph documents parent sha reconciliation"
assert_contains "$BD_RALPH" 'update only the affected child beads'"'"' `metadata.git_sha`' "bd-ralph documents selective child sha reconciliation"
```

- [ ] **Step 2: Run the contract test and confirm the new assertions fail**

Run:

```bash
bash /Users/isy_macstudio/Documents/GitHub/dotfiles/tests/bd_ralph_contract_test.sh
```

Expected: FAIL because `bd-ralph` does not yet document plan materialization gates or finish-phase reconciliation inputs.

- [ ] **Step 3: Update `bd-ralph` Phase 1 and Phase 3 contracts**

In `/Users/isy_macstudio/Documents/GitHub/dotfiles/shared/skills/bd-ralph/SKILL.md`, add the following requirements:

Under Phase 1 after plan review:

```markdown
- If `plan-review --auto-fix` changed the plan, do not enter execution until the parent observes:
  - `Post-fix HEAD`
  - `Post-fix changed files`
  - `Working tree clean`
- The reviewed plan must be materialized into the execution workspace by one of two explicit strategies:
  - **Commit-first**
  - **Copy-forward**
```

Under Phase 3 after `implementation-review --auto-fix`:

```markdown
- Treat `implementation-review` output as a state-transition artifact, not just a verdict.
- If `Auto-fix applied=yes` or `Metadata reconciliation required=yes`, run a reconciliation step before finish completion:
  - update the parent bead `metadata.sha` to the post-fix `HEAD`
  - update only the affected child beads' `metadata.git_sha`
  - `bd dolt push`
- Do not treat the finish phase as complete until reconciliation succeeds or is explicitly proven unnecessary.
```

- [ ] **Step 4: Update expected outputs and abort/resume guidance**

In the workflow-family expected outputs / abort section, add:

```markdown
Expected outputs from review-family auto-fix consumers:
- `Post-fix HEAD`
- `Post-fix changed files`
- `Working tree clean`
- `Metadata reconciliation required` when implementation-review changes code
```

and in abort/resume guidance add:

```markdown
- If plan-review changed the plan but the execution workspace still has the older version, stop before execution.
- If finish-phase auto-fix changed the branch but parent/child SHA metadata was not reconciled, stop before final completion.
```

- [ ] **Step 5: Re-run the `bd-ralph` contract test**

Run:

```bash
bash /Users/isy_macstudio/Documents/GitHub/dotfiles/tests/bd_ralph_contract_test.sh
```

Expected: PASS, including the new plan-materialization and reconciliation assertions.

- [ ] **Step 6: Commit**

```bash
git add \
  /Users/isy_macstudio/Documents/GitHub/dotfiles/shared/skills/bd-ralph/SKILL.md \
  /Users/isy_macstudio/Documents/GitHub/dotfiles/tests/bd_ralph_contract_test.sh
git commit -m "docs: bd-ralph 상태 전파와 SHA 재조정 게이트 추가"
```

---

### Task 5: Final consistency, sync, and metadata verification

> **REQUIRED SUB-SKILL:** Use superpowers:writing-skills

**Files:**
- Verify only (plus installed-copy sync)

- [ ] **Step 1: Re-read the changed contract surfaces together**

Run:

```bash
sed -n '200,250p' /Users/isy_macstudio/Documents/GitHub/dotfiles/shared/skills/plan-review/SKILL.md
printf '\n====\n'
sed -n '205,250p' /Users/isy_macstudio/Documents/GitHub/dotfiles/shared/skills/implementation-review/SKILL.md
printf '\n====\n'
sed -n '15,80p' skills/subagent-driven-development/SKILL.md
printf '\n====\n'
sed -n '12,80p' skills/subagent-driven-development/spec-reviewer-prompt.md
printf '\n====\n'
sed -n '9,40p' skills/subagent-driven-development/code-quality-reviewer-prompt.md
printf '\n====\n'
sed -n '80,230p' /Users/isy_macstudio/Documents/GitHub/dotfiles/shared/skills/bd-ralph/SKILL.md
```

Expected: the same concepts appear consistently across the surfaces — post-fix state outputs, freshness inputs, explicit close rules, and finish-phase reconciliation.

- [ ] **Step 2: Run the targeted regression suite**

Run:

```bash
bash /Users/isy_macstudio/Documents/GitHub/dotfiles/tests/review_skill_artifact_mode_contract_test.sh
bash /Users/isy_macstudio/Documents/GitHub/dotfiles/tests/bd_ralph_contract_test.sh
bash tests/claude-code/test-subagent-driven-development-contracts.sh
bash tests/claude-code/test-subagent-driven-development.sh
```

Expected: all PASS.

- [ ] **Step 3: Sync the updated subagent skill files to installed plugin copies**

Run:

```bash
cp -f skills/subagent-driven-development/SKILL.md /Users/isy_macstudio/GitHub/superpowers/skills/subagent-driven-development/SKILL.md
cp -f skills/subagent-driven-development/spec-reviewer-prompt.md /Users/isy_macstudio/GitHub/superpowers/skills/subagent-driven-development/spec-reviewer-prompt.md
cp -f skills/subagent-driven-development/code-quality-reviewer-prompt.md /Users/isy_macstudio/GitHub/superpowers/skills/subagent-driven-development/code-quality-reviewer-prompt.md

cp -f skills/subagent-driven-development/SKILL.md ~/.claude/plugins/marketplaces/superpowers-custom/skills/subagent-driven-development/SKILL.md
cp -f skills/subagent-driven-development/spec-reviewer-prompt.md ~/.claude/plugins/marketplaces/superpowers-custom/skills/subagent-driven-development/spec-reviewer-prompt.md
cp -f skills/subagent-driven-development/code-quality-reviewer-prompt.md ~/.claude/plugins/marketplaces/superpowers-custom/skills/subagent-driven-development/code-quality-reviewer-prompt.md

cp -f skills/subagent-driven-development/SKILL.md ~/.claude/plugins/cache/superpowers-custom/skills/subagent-driven-development/SKILL.md
cp -f skills/subagent-driven-development/spec-reviewer-prompt.md ~/.claude/plugins/cache/superpowers-custom/skills/subagent-driven-development/spec-reviewer-prompt.md
cp -f skills/subagent-driven-development/code-quality-reviewer-prompt.md ~/.claude/plugins/cache/superpowers-custom/skills/subagent-driven-development/code-quality-reviewer-prompt.md
```

Then verify parity:

```bash
diff -u skills/subagent-driven-development/SKILL.md /Users/isy_macstudio/GitHub/superpowers/skills/subagent-driven-development/SKILL.md
diff -u skills/subagent-driven-development/spec-reviewer-prompt.md /Users/isy_macstudio/GitHub/superpowers/skills/subagent-driven-development/spec-reviewer-prompt.md
diff -u skills/subagent-driven-development/code-quality-reviewer-prompt.md /Users/isy_macstudio/GitHub/superpowers/skills/subagent-driven-development/code-quality-reviewer-prompt.md
```

Expected: no diff output.

- [ ] **Step 4: Refresh the Codex-installed copy after the final commit/push**

Run:

```bash
git -C ~/.codex/superpowers pull --ff-only
git -C ~/.codex/superpowers diff -- \
  skills/subagent-driven-development/SKILL.md \
  skills/subagent-driven-development/spec-reviewer-prompt.md \
  skills/subagent-driven-development/code-quality-reviewer-prompt.md
```

Expected: no diff output.

- [ ] **Step 5: Record the final plan/Beads state and commit**

Run:

```bash
bd show superpowers-efy --json
git status --short
git commit --allow-empty -m "docs: review 상태 하드닝 최종 검증 정리"
```

Expected: `superpowers-efy` remains the open parent with this plan linked, and the working tree is clean after the verification commit.
