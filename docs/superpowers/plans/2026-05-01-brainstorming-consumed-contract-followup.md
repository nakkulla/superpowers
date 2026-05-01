# Brainstorming Consumed Contract and Follow-up Metadata Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Align `superpowers:brainstorming` and its Superpowers-local contract/tests with the consumed subset of dotfiles v4 execution-lane, mirror-label, and scope-split follow-up semantics.

**Architecture:** Keep `docs/contracts/workflow-contract.yaml` as a semantic-only Superpowers contract and extend only the vocabulary that `brainstorming` actually consumes. Tighten `skills/brainstorming/SKILL.md` guidance, extend focused shell contract tests, add a small eval artifact, and keep dotfiles runtime-only ledgers/markers/phases out of the local contract.

**Tech Stack:** Markdown skill docs, YAML semantic contract docs, Bash contract tests using `rg`, Beads metadata, and repo-local docs/eval artifacts.

**Spec:** `docs/superpowers/specs/2026-05-01-brainstorming-consumed-contract-followup-design.md`
**Parent bead:** `superpowers-rd0`

```text
skill_workflow=skill_creator
skill_workflow_reason=the reviewed spec requires eval-backed skill behavior/contract iteration for the brainstorming skill and contract tests
execution_lane=plan
```

---

## Files and responsibilities

- Modify: `docs/contracts/workflow-contract.yaml`
  - Declare dotfiles v4 as upstream semantic reference while keeping `runtime_loading: false`.
  - Add explicit consumed metadata keys, mirror-label mapping, review evidence fields, and extended scope-split follow-up evidence.
  - Make runtime-only dotfiles sections intentionally out of scope.
- Modify: `docs/contracts/consumers.yaml`
  - Record that `skills/brainstorming/SKILL.md` consumes execution-lane metadata, quick-edit mirror-label semantics, skill workflow handoff metadata, spec review evidence, and scope-split follow-up metadata.
  - Extend test assertion lists for the consumed-subset boundary.
- Modify: `skills/brainstorming/SKILL.md`
  - Clarify that `metadata.execution_lane=quick_edit` is canonical, standalone `quick_edit` labels are stale mirror drift, and standalone quick-edit issues keep metadata and mirror labels aligned.
  - Extend durable scope-split follow-up required/optional/forbidden evidence without adding pre-spec execution metadata.
  - Preserve stop-after-spec behavior.
- Modify: `tests/claude-code/test-brainstorming-v4-workflow-routing-contract.sh`
  - Assert metadata-vs-label split and reject label-only quick-edit execution evidence.
- Modify: `tests/claude-code/test-brainstorming-scope-split-followup-contract.sh`
  - Assert the extended scope-split follow-up fields and consumed-subset boundary.
- Modify: `tests/claude-code/run-skill-tests.sh`
  - Accept `fast`/`--fast` as a repository-shell contract suite selector because the reviewed spec names `bash tests/claude-code/run-skill-tests.sh fast`; keep it limited to the existing fast shell contract tests so verification does not depend on live Claude CLI worker prompts.
- Modify: `tests/claude-code/test-helpers.sh`
  - Keep existing Claude Code test helper behavior but use `timeout` or `gtimeout` when available, then fall back to a standard-library Python timeout wrapper when neither command exists. This is only to prevent the documented fast verification command from masking invocation errors on macOS.
- Modify: `tests/claude-code/README.md`
  - Update the test descriptions for mirror-label semantics and extended follow-up evidence.
- Create: `docs/superpowers/evals/2026-05-01-brainstorming-consumed-contract-followup-eval.md`
  - Record RED/GREEN eval-style evidence for quick-edit label drift, scope-split follow-up creation, and consumed-subset boundary behavior.
- Create: `docs/superpowers/evals/2026-05-01-brainstorming-consumed-contract-followup-benchmark.json`
  - Canonical skill-creator benchmark shape with top-level `metadata`, `runs`, and `run_summary`.
- Create: `docs/superpowers/evals/2026-05-01-brainstorming-consumed-contract-followup-grading.json`
  - Scenario-level contract-smoke grading records.
- Create: `docs/superpowers/evals/2026-05-01-brainstorming-consumed-contract-followup-timing.json`
  - Timestamp/duration record for reproducible repo-shell eval commands.

---

### Task 1: Extend the contract tests first (RED)

skill_workflow=skill_creator
skill_workflow_reason=eval-backed skill contract change requires test-first pressure coverage before modifying active guidance
REQUIRED SUB-SKILL: Use superpowers:writing-skills for skill artifact edits.
ALSO REQUIRED: Use skill-creator because this task changes eval-backed behavior/contract routing evidence.

**Files:**
- Modify: `tests/claude-code/test-brainstorming-v4-workflow-routing-contract.sh`
- Modify: `tests/claude-code/test-brainstorming-scope-split-followup-contract.sh`
- Modify: `tests/claude-code/run-skill-tests.sh`
- Modify: `tests/claude-code/test-helpers.sh`

- [ ] **Step 1: Add failing quick-edit mirror assertions**

Add assertions in `test-brainstorming-v4-workflow-routing-contract.sh` for these exact semantic phrases or their updated final wording:

```bash
rg -q 'standalone `quick_edit` label is stale mirror drift' "$BRAINSTORMING"
rg -q 'A `quick_edit` label without `metadata.execution_lane=quick_edit` is stale mirror drift' "$BRAINSTORMING"
rg -q 'metadata.execution_lane=quick_edit' "$BRAINSTORMING" "$WORKFLOW_CONTRACT"
rg -q 'quick_edit_label:' "$WORKFLOW_CONTRACT"
rg -q 'source: metadata.execution_lane=quick_edit' "$WORKFLOW_CONTRACT"
```

Also add `WORKFLOW_CONTRACT="$REPO_ROOT/docs/contracts/workflow-contract.yaml"` and include it in the existence check.

- [ ] **Step 2: Add failing scope-split extension assertions**

Add assertions in `test-brainstorming-scope-split-followup-contract.sh` that `scope_split_followup.required_metadata` includes:

```bash
- classification
- target_repo
- required_action
- human_decision_required
```

Add guidance assertions for:

```bash
classification=<scope_split_followup|cross_repo_followup|human_followup>
target_repo=<owner/repo or tracker repo>
required_action=<future work request>
human_decision_required=yes|no
optional evidence fields
source_artifact
source_summary
component
target_paths
acceptance_notes
verification_notes
Do not guess `target_paths`
auto_spec_eligible
missing_spec_evidence
```

The `auto_spec_eligible` and `missing_spec_evidence` assertions must prove these dotfiles auto-spec-intake fields are not required for Superpowers brainstorming follow-ups.

- [ ] **Step 3: Add consumed-subset boundary assertions**

In the scope-split test, assert that the local contract keeps the runtime boundary out of scope:

```bash
rg -q 'upstream_semantic_reference: dotfiles-v4-workflow-contract' "$WORKFLOW_CONTRACT"
rg -q 'runtime_loading: false' "$WORKFLOW_CONTRACT"
rg -q 'dotfiles_runtime_only:' "$WORKFLOW_CONTRACT"
rg -q 'run_ledgers: out_of_scope' "$WORKFLOW_CONTRACT"
rg -q 'phase_markers: out_of_scope' "$WORKFLOW_CONTRACT"
rg -q 'final_markers: out_of_scope' "$WORKFLOW_CONTRACT"
! rg -q 'phase_evidence_requirements:' "$WORKFLOW_CONTRACT"
```

- [ ] **Step 4: Make the documented fast command runnable**

In `run-skill-tests.sh`, add a parser case before `--help`:

```bash
fast|--fast)
    RUN_FAST_CONTRACTS=true
    shift
    ;;
```

In `test-helpers.sh`, optionally replace direct `timeout` use with a local helper that chooses `timeout` first, `gtimeout` second, and then a standard-library Python timeout wrapper if neither binary exists:

```bash
timeout_bin() {
    if command -v timeout >/dev/null 2>&1; then
        printf '%s\n' timeout
    elif command -v gtimeout >/dev/null 2>&1; then
        printf '%s\n' gtimeout
    else
        printf '%s\n' python3
    fi
}
```

Call the chosen path in `run_claude` if this helper is touched; for `python3`, invoke a tiny inline `subprocess.run(..., timeout=seconds)` wrapper. This keeps invocation errors visible without requiring GNU coreutils on macOS. The `fast` selector itself should avoid Claude prompt tests, so this helper change is only needed if the run still exercises `test-subagent-driven-development.sh`.

- [ ] **Step 5: Run RED checks and capture expected failures**

Run:

```bash
bash tests/claude-code/test-brainstorming-v4-workflow-routing-contract.sh
bash tests/claude-code/test-brainstorming-scope-split-followup-contract.sh
bash tests/claude-code/run-skill-tests.sh fast
```

Expected before implementation: at least the new routing/scope assertions fail. If `run-skill-tests.sh fast` fails only because active shell contract tests fail, that is expected RED evidence. If it runs Claude CLI prompt tests or fails because `fast` is not parsed after the parser edit, fix only the parser/selector before proceeding; the selector is justified solely by the reviewed spec verification command and must remain limited to the existing shell contract tests.

---

### Task 2: Update the semantic contract and consumer registry (GREEN)

skill_workflow=skill_creator
skill_workflow_reason=contract vocabulary changes are part of the eval-backed skill behavior contract
REQUIRED SUB-SKILL: Use superpowers:writing-skills for skill artifact edits.
ALSO REQUIRED: Use skill-creator because this task changes active contract semantics and eval-backed behavior.

**Files:**
- Modify: `docs/contracts/workflow-contract.yaml`
- Modify: `docs/contracts/consumers.yaml`

- [ ] **Step 1: Extend `workflow-contract.yaml` metadata vocabulary**

Keep the existing shape and add/clarify these entries:

```yaml
contract:
  name: superpowers-workflow
  version: 1
  type: semantic
  runtime_loading: false
  upstream_semantic_reference: dotfiles-v4-workflow-contract

vocabulary:
  execution_lane:
    kind: metadata
    allowed_values: [plan, quick_edit]
  quick_edit:
    kind: metadata
    allowed_values: [yes, no]
    meaning: brainstorming decision flag, not the mirror label
  quick_edit_label:
    kind: mirror_label
    label: quick_edit
    source: metadata.execution_lane=quick_edit
  plan:
    kind: metadata
    key: metadata.plan
    mirror_label: has:plan
  handoff:
    kind: metadata
    key: metadata.handoff
    mirror_label: has:handoff
  has:plan:
    kind: mirror_label
    source: metadata.plan
  has:handoff:
    kind: mirror_label
    source: metadata.handoff
  impl_reviewed_at_sha:
    kind: metadata
    value: git_commit_sha
  impl_reviewed_diff_range:
    kind: metadata
    value: git_diff_range
```

Preserve existing `spec_id`, `has:spec`, `reviewed:spec`, `spec_content_hash`, and `spec_reviewed_at_sha` entries.

- [ ] **Step 2: Extend `scope_split_followup`**

Append the required fields without removing existing required fields:

```yaml
scope_split_followup:
  required_metadata:
    - origin
    - source_spec_id
    - source_parent
    - scope_relation
    - spec_policy
    - classification
    - target_repo
    - required_action
    - human_decision_required
  optional_metadata:
    - source_artifact
    - source_summary
    - component
    - target_paths
    - acceptance_notes
    - verification_notes
  dotfiles_auto_spec_intake_fields:
    auto_spec_eligible: not_required
    missing_spec_evidence: not_required
```

Keep the forbidden pre-spec fields unchanged and do not add `execution_lane`, `quick_edit`, or `skill_workflow` to required fields.

- [ ] **Step 3: Declare runtime-only exclusions**

Add a compact boundary section:

```yaml
dotfiles_runtime_only:
  run_ledgers: out_of_scope
  phase_markers: out_of_scope
  final_markers: out_of_scope
  migration_tables: out_of_scope
```

Do not add `phase_evidence_requirements:`.

- [ ] **Step 4: Extend `consumers.yaml`**

Update the brainstorming consumer to list these consumed semantics:

```yaml
- execution_lane_metadata
- quick_edit_mirror_label
- skill_workflow_handoff_metadata
- spec_review_evidence
- scope_split_followup_metadata
```

Add test assertions for `vocabulary.quick_edit_label`, `vocabulary.plan`, `vocabulary.handoff`, `vocabulary.impl_reviewed_at_sha`, `vocabulary.impl_reviewed_diff_range`, `scope_split_followup.optional_metadata`, and `dotfiles_runtime_only`.

---

### Task 3: Tighten `brainstorming` active guidance (GREEN)

skill_workflow=skill_creator
skill_workflow_reason=active SKILL.md behavior guidance changes need eval-backed skill discipline
REQUIRED SUB-SKILL: Use superpowers:writing-skills for skill artifact edits.
ALSO REQUIRED: Use skill-creator because this task changes active skill behavior guidance and eval evidence.

**Files:**
- Modify: `skills/brainstorming/SKILL.md`

- [ ] **Step 1: Update quick-edit preflight Beads guidance**

Revise the quick-edit Beads bullets so they state:

```markdown
- record `metadata.execution_lane=quick_edit` before or with the mirror label
- label that new issue `quick_edit` only as the mirror/index label for `metadata.execution_lane=quick_edit`
- a `quick_edit` label without `metadata.execution_lane=quick_edit` is stale mirror drift, not execution-lane evidence
```

Preserve the existing standalone execution issue and parent-bead distinction.

- [ ] **Step 2: Update the skill_workflow classification rules**

Keep `metadata.quick_edit=yes|no` as the decision flag. Add one rule that explicitly says:

```markdown
- Treat `metadata.execution_lane=quick_edit` as the only canonical source for quick-edit execution; never select quick-edit execution from a standalone `quick_edit` label.
```

Do not change the stop-after-spec boundary.

- [ ] **Step 3: Extend scope-split follow-up metadata guidance**

Add required fields under the existing scope-split metadata block:

```text
classification=<scope_split_followup|cross_repo_followup|human_followup>
target_repo=<owner/repo or tracker repo>
required_action=<future work request>
human_decision_required=yes|no
```

Add optional fields under a separate heading:

```text
source_artifact=<upstream artifact path or URL>
source_summary=<short summary>
component=<component name>
target_paths=<known repo-relative paths>
acceptance_notes=<known acceptance notes>
verification_notes=<known verification notes>
```

Add prose that optional fields are recorded only when known, `target_paths` must not be guessed, and missing optional fields should be described in prose.

- [ ] **Step 4: Add dotfiles auto-spec-intake boundary guidance**

Add one sentence that `auto_spec_eligible` and `missing_spec_evidence` are dotfiles auto-spec-intake fields and are not required for Superpowers `brainstorming` scope-split follow-ups unless a future reviewed spec changes the consumer boundary.

---

### Task 4: Add eval evidence and docs updates (GREEN)

skill_workflow=skill_creator
skill_workflow_reason=the reviewed spec requires eval evidence for quick-edit label drift, scope-split follow-up creation, and consumed-subset boundary behavior
REQUIRED SUB-SKILL: Use superpowers:writing-skills for skill artifact edits.
ALSO REQUIRED: Use skill-creator because this task creates eval evidence for skill behavior.

**Files:**
- Create: `docs/superpowers/evals/2026-05-01-brainstorming-consumed-contract-followup-eval.md`
- Create: `docs/superpowers/evals/2026-05-01-brainstorming-consumed-contract-followup-benchmark.json`
- Create: `docs/superpowers/evals/2026-05-01-brainstorming-consumed-contract-followup-grading.json`
- Create: `docs/superpowers/evals/2026-05-01-brainstorming-consumed-contract-followup-timing.json`
- Modify: `tests/claude-code/README.md`

- [ ] **Step 1: Capture eval baseline evidence before guidance changes**

After Task 1 test edits and before Tasks 2-3 guidance changes, capture RED evidence in `tmp/brainstorming-consumed-contract-red.log` with:

```bash
{
  echo '### red routing'; bash tests/claude-code/test-brainstorming-v4-workflow-routing-contract.sh || true
  echo '### red scope'; bash tests/claude-code/test-brainstorming-scope-split-followup-contract.sh || true
  echo '### red fast'; bash tests/claude-code/run-skill-tests.sh fast || true
} 2>&1 | tee tmp/brainstorming-consumed-contract-red.log
```

Expected: routing/scope contract assertions fail on the newly added checks, while the `fast` alias itself parses. Do not commit `tmp/`. Summarize exact failing assertions in the eval markdown.

- [ ] **Step 2: Write the eval markdown artifact**

Create the eval artifact with these sections:

```markdown
# Brainstorming Consumed Contract and Follow-up Metadata Eval

Parent bead: superpowers-rd0
Spec: `docs/superpowers/specs/2026-05-01-brainstorming-consumed-contract-followup-design.md`
Plan: `docs/superpowers/plans/2026-05-01-brainstorming-consumed-contract-followup.md`
Eval type: `contract_smoke`

## Harness boundary
## RED baseline
## GREEN verification
## Scenario 1: quick-edit label drift
## Scenario 2: scope-split follow-up creation
## Scenario 3: consumed-subset boundary
## Commands
## Benchmark artifacts
## Result
```

For each scenario, include the prompt/fixture idea, expected behavior, before evidence from the RED log or baseline file inspection, after evidence from the updated contract tests, and whether it is `contract_smoke` or `skill_lift`. This run uses contract-smoke evidence instead of live external model benchmarks because the changed behavior is deterministic repository guidance and shell-contract coverage is more discriminating; record that skip reason truthfully.

- [ ] **Step 3: Create canonical benchmark/grading/timing JSON artifacts**

Create `docs/superpowers/evals/2026-05-01-brainstorming-consumed-contract-followup-benchmark.json` with top-level `metadata`, `runs`, and `run_summary`. Use this shape:

```json
{
  "metadata": {
    "schema": "superpowers.skill_eval_benchmark.v1",
    "eval_type": "contract_smoke",
    "parent_bead": "superpowers-rd0",
    "spec": "docs/superpowers/specs/2026-05-01-brainstorming-consumed-contract-followup-design.md",
    "plan": "docs/superpowers/plans/2026-05-01-brainstorming-consumed-contract-followup.md",
    "benchmark_md": "docs/superpowers/evals/2026-05-01-brainstorming-consumed-contract-followup-eval.md",
    "executor": "repo-shell",
    "executor_model": "not_applicable_repo_shell",
    "with_skill_count": 3,
    "without_skill_count": 3,
    "grading_json": "docs/superpowers/evals/2026-05-01-brainstorming-consumed-contract-followup-grading.json",
    "timing_json": "docs/superpowers/evals/2026-05-01-brainstorming-consumed-contract-followup-timing.json",
    "skipped_layers": []
  },
  "runs": [],
  "run_summary": {
    "status": "pass",
    "with_skill": {"count": 3, "pass_count": 3, "summary": "GREEN contract-smoke scenarios passed."},
    "without_skill": {"count": 3, "pass_count": 0, "summary": "RED contract-smoke scenarios exposed missing consumed-subset assertions."},
    "delta": {"status": "positive_contract_alignment", "summary": "Changed guidance and contract tests now enforce consumed dotfiles v4 semantics without importing runtime-only details."},
    "with_skill_count": 3,
    "without_skill_count": 3
  }
}
```

Populate `runs` with one `without_skill` and one `with_skill` record for each of the three scenarios. Create `grading.json` with scenario pass/fail judgments and `timing.json` with the RED/GREEN command timestamps or durations. If live external model benchmarks are skipped, set `metadata.skipped_layers` to include `external_model_benchmark` and `review_viewer` with reasons; do not leave the fields absent.

- [ ] **Step 4: Validate eval artifacts**

Run:

```bash
python3 - <<'PY'
import json, pathlib
for name in [
  'benchmark',
  'grading',
  'timing',
]:
    path = pathlib.Path(f'docs/superpowers/evals/2026-05-01-brainstorming-consumed-contract-followup-{name}.json')
    data = json.loads(path.read_text())
    print(path, 'ok')
bench = json.loads(pathlib.Path('docs/superpowers/evals/2026-05-01-brainstorming-consumed-contract-followup-benchmark.json').read_text())
assert set(['metadata', 'runs', 'run_summary']).issubset(bench)
assert bench['run_summary']['with_skill_count'] > 0
assert bench['run_summary']['without_skill_count'] > 0
PY
```

Expected: all JSON parses and benchmark top-level schema/count assertions pass.

- [ ] **Step 5: Update the README descriptions**

Update `tests/claude-code/README.md` so the two brainstorming contract test sections mention:

```markdown
- quick-edit execution uses `metadata.execution_lane=quick_edit`, with `quick_edit` as a mirror/index label
- standalone `quick_edit` labels are stale mirror drift
- scope-split follow-ups include classification, target_repo, required_action, and human_decision_required for new durable follow-ups
- Superpowers keeps dotfiles runtime-only ledgers/markers/phases out of the local semantic contract
```

---

### Task 5: Verify, review, and commit

skill_workflow=skill_creator
skill_workflow_reason=final skill-contract work must prove tests/eval and preserve runtime artifact hygiene
REQUIRED SUB-SKILL: Use superpowers:writing-skills for skill artifact edits.
ALSO REQUIRED: Use skill-creator because final evidence includes eval-backed contract behavior.

**Files:**
- Verify all modified files above.
- Do not modify unrelated files.

- [ ] **Step 1: Run focused verification**

Run:

```bash
bash tests/claude-code/test-brainstorming-v4-workflow-routing-contract.sh
bash tests/claude-code/test-brainstorming-scope-split-followup-contract.sh
bash tests/claude-code/run-skill-tests.sh fast
```

Expected: all pass.

- [ ] **Step 2: Run targeted searches from the spec**

Run:

```bash
rg -n 'metadata.execution_lane=quick_edit|quick_edit.*mirror|stale mirror drift' docs/contracts skills/brainstorming tests/claude-code
rg -n 'classification|source_parent|target_repo|required_action|human_decision_required' docs/contracts skills/brainstorming tests/claude-code
rg -n 'final_markers|ledgers|phase_evidence_requirements' docs/contracts/workflow-contract.yaml
```

Expected: the first two commands show the intended contract/guidance/test coverage; the final command shows only the explicit out-of-scope `final_markers`/`run_ledgers` boundary and no `phase_evidence_requirements` requirement.

- [ ] **Step 3: Inspect runtime artifact hygiene**

Run:

```bash
git status --short
git diff --check
```

Expected: only intended files are changed and no whitespace errors are reported.

- [ ] **Step 4: Record Beads and review evidence**

Use the parent bead `superpowers-rd0` as the parent execution issue. After implementation-review passes, set implementation review metadata only from current-run evidence. Child task beads created by the orchestrator should be marked `resolved`, not closed, in `beads_mode=full`.

- [ ] **Step 5: Commit**

Stage only intended paths and commit:

```bash
git add docs/contracts/workflow-contract.yaml docs/contracts/consumers.yaml skills/brainstorming/SKILL.md tests/claude-code/test-brainstorming-v4-workflow-routing-contract.sh tests/claude-code/test-brainstorming-scope-split-followup-contract.sh tests/claude-code/run-skill-tests.sh tests/claude-code/test-helpers.sh tests/claude-code/README.md docs/superpowers/evals/2026-05-01-brainstorming-consumed-contract-followup-eval.md docs/superpowers/evals/2026-05-01-brainstorming-consumed-contract-followup-benchmark.json docs/superpowers/evals/2026-05-01-brainstorming-consumed-contract-followup-grading.json docs/superpowers/evals/2026-05-01-brainstorming-consumed-contract-followup-timing.json docs/superpowers/plans/2026-05-01-brainstorming-consumed-contract-followup.md
git diff --cached --name-only
git commit -m "기획: brainstorming 계약 소비 범위 정렬"
```
