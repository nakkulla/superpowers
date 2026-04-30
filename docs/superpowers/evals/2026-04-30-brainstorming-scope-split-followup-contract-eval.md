# Brainstorming Scope Split Follow-up Contract Eval

Parent bead: `superpowers-h2m`
Spec: `docs/superpowers/specs/2026-04-30-brainstorming-scope-split-followup-contract-design.md`
Plan: `docs/superpowers/plans/2026-04-30-brainstorming-scope-split-followup-contract.md`
Eval type: `contract_smoke`

## Harness boundary

This eval is a reproducible repository contract-smoke record. It uses shell contract tests, focused `rg` checks, and fixed pressure-scenario judgments instead of an external model benchmark. The comparison is the active guidance before implementation (`without_skill`/baseline) versus the changed guidance after implementation (`with_skill`/changed).

## Baseline evidence

Commands and observations captured before implementation:

```bash
bash tests/claude-code/test-brainstorming-v4-workflow-routing-contract.sh
[ -d docs/contracts ] || echo 'NO docs/contracts'
bash tests/claude-code/test-brainstorming-scope-split-followup-contract.sh
```

Result summary:

- Existing routing contract passed: `PASS: brainstorming v4 workflow routing contract`.
- Baseline had no `docs/contracts/` directory, so Superpowers had no local semantic contract registry.
- The new scope-split follow-up contract test failed in RED because the semantic contract files and scope-split guidance did not exist yet.

## Changed evidence

Commands captured after implementation:

```bash
bash tests/claude-code/test-brainstorming-scope-split-followup-contract.sh
bash tests/claude-code/test-brainstorming-v4-workflow-routing-contract.sh
bash tests/claude-code/run-skill-tests.sh --test test-brainstorming-scope-split-followup-contract.sh
rg -n 'runtime_loading: false|scope_split_followup|future_brainstorming_required|not plan-ready|not execution-ready' docs/contracts skills tests/claude-code
```

Result summary:

- New contract test passed: `PASS: brainstorming scope split follow-up contract`.
- Existing v4 routing test still passed: `PASS: brainstorming v4 workflow routing contract`.
- Test runner invocation passed with `STATUS: PASSED` for `test-brainstorming-scope-split-followup-contract.sh`.
- Focused `rg` evidence found semantic-only `runtime_loading: false`, `scope_split_followup`, `future_brainstorming_required`, and the not-plan-ready / not-execution-ready guards.

## Pressure scenario

Prompt:

> During brainstorming, the user wants to update one active skill behavior now, and discussion reveals a related future policy cleanup that should not be included in the current implementation. What should the brainstorming run create?

Expected behavior:

```text
- Write one reviewed main spec for the selected main scope.
- Keep the related work out of the main design except for boundary notes.
- After user approval of the written main spec, create description-only follow-up Beads issues for accepted split work.
- Add origin=brainstorming_scope_split, source_spec_id, source_parent, scope_relation=follow_up, and spec_policy=future_brainstorming_required to follow-up issues.
- Do not add spec_id, has:spec, reviewed:spec, execution_lane, quick_edit, or skill_workflow to pre-spec follow-ups.
```

Judgment: **PASS**. The changed `brainstorming` guidance states exactly this boundary, while `writing-plans` and `executing-plans` stop on `spec_policy=future_brainstorming_required` until the follow-up receives its own future brainstorming/spec gate.

## Before/after conclusion

Before this change, Superpowers had v4 routing vocabulary but no local semantic contract registry or explicit scope-split follow-up semantics. After this change, Superpowers has semantic-only contract files, active skill guidance for one-main-spec-plus-description-only-follow-ups, and fast contract tests registered in the default test runner documentation.
