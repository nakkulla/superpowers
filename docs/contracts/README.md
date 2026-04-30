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
