# Brainstorming Consumed Contract and Follow-up Metadata Eval

Parent bead: `superpowers-rd0`
Spec: `docs/superpowers/specs/2026-05-01-brainstorming-consumed-contract-followup-design.md`
Plan: `docs/superpowers/plans/2026-05-01-brainstorming-consumed-contract-followup.md`
Eval type: `contract_smoke`

## Harness boundary

This eval is a reproducible repository contract-smoke record. It compares the active guidance before this implementation (`without_skill` / RED assertions against baseline files) with the changed guidance after implementation (`with_skill` / GREEN shell contract tests). Live external model benchmarks were skipped because the required behavior is deterministic contract wording plus shell-test coverage; the checked-in markdown and JSON artifacts are the review surface.

## RED baseline

RED commands were captured in `tmp/brainstorming-consumed-contract-red.log` before the GREEN contract and guidance updates:

```bash
bash tests/claude-code/test-brainstorming-v4-workflow-routing-contract.sh
bash tests/claude-code/test-brainstorming-scope-split-followup-contract.sh
bash tests/claude-code/run-skill-tests.sh fast
```

Result summary:

- Routing test failed after adding assertions for `metadata.execution_lane=quick_edit`, `quick_edit_label`, and stale mirror drift wording.
- Scope-split test failed after adding assertions for extended follow-up evidence fields and the consumed-subset runtime boundary.
- `run-skill-tests.sh fast` parsed and ran only shell contract tests after the selector update; it failed only because the new contract assertions were still RED.

## GREEN verification

GREEN commands after implementation:

```bash
bash tests/claude-code/test-brainstorming-v4-workflow-routing-contract.sh
bash tests/claude-code/test-brainstorming-scope-split-followup-contract.sh
bash tests/claude-code/run-skill-tests.sh fast
```

Expected result: all commands pass after the contract, guidance, and README updates.

## Scenario 1: quick-edit label drift

Prompt/fixture idea:

> A Beads issue has a standalone `quick_edit` label but no `metadata.execution_lane=quick_edit`. Should the next workflow treat it as quick-edit execution evidence?

Expected behavior:

- Treat `metadata.execution_lane=quick_edit` as the canonical quick-edit execution source.
- Treat a standalone `quick_edit` label as stale mirror drift.
- Do not select quick-edit execution from the label alone.

Evidence type: `contract_smoke`.

## Scenario 2: scope-split follow-up creation

Prompt/fixture idea:

> Brainstorming writes a main spec and discovers a related future follow-up. What durable Beads evidence belongs on the follow-up after the main spec is approved?

Expected behavior:

- Preserve existing fields: `origin`, `source_spec_id`, `source_parent`, `scope_relation`, and `spec_policy`.
- Add required evidence: `classification`, `target_repo`, `required_action`, and `human_decision_required`.
- Record optional fields only when known and do not guess `target_paths`.
- Do not add pre-spec execution/review metadata to the follow-up.

Evidence type: `contract_smoke`.

## Scenario 3: consumed-subset boundary

Prompt/fixture idea:

> Should Superpowers copy the full dotfiles v4 workflow contract, including runtime ledgers, phases, final markers, and migration tables?

Expected behavior:

- Keep `docs/contracts/workflow-contract.yaml` semantic-only with `runtime_loading: false`.
- Record dotfiles v4 as the upstream semantic reference.
- Mark dotfiles runtime-only ledgers, phase markers, final markers, and migration tables as out of scope.
- Do not add `phase_evidence_requirements` to the Superpowers contract.

Evidence type: `contract_smoke`.

## Commands

Focused commands used for final verification:

```bash
bash tests/claude-code/test-brainstorming-v4-workflow-routing-contract.sh
bash tests/claude-code/test-brainstorming-scope-split-followup-contract.sh
bash tests/claude-code/run-skill-tests.sh fast
rg -n 'metadata.execution_lane=quick_edit|quick_edit.*mirror|stale mirror drift' docs/contracts skills/brainstorming tests/claude-code
rg -n 'classification|source_parent|target_repo|required_action|human_decision_required' docs/contracts skills/brainstorming tests/claude-code
rg -n 'final_markers|ledgers|phase_evidence_requirements' docs/contracts/workflow-contract.yaml
```

## Benchmark artifacts

- `docs/superpowers/evals/2026-05-01-brainstorming-consumed-contract-followup-benchmark.json`
- `docs/superpowers/evals/2026-05-01-brainstorming-consumed-contract-followup-grading.json`
- `docs/superpowers/evals/2026-05-01-brainstorming-consumed-contract-followup-timing.json`

## Result

PASS when the focused shell contract tests and JSON schema checks pass. The eval demonstrates positive contract alignment without importing dotfiles runtime-only contract sections.
