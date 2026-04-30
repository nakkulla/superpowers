# Brainstorming Scope Split Follow-up Contract Design
Parent bead: superpowers-h2m

## Summary

Add an explicit scope-split rule to `superpowers:brainstorming`: when brainstorming discovers work that should be separated from the selected main scope, the current run writes only one reviewed main spec. Related future work is captured as description-only Beads follow-up issues with clear provenance, not as additional specs in the same brainstorming run.

Add a lightweight Superpowers-local semantic contract under `docs/contracts/` so active workflow skills share the same vocabulary for execution lanes, skill workflow routing, review evidence, and brainstorming scope-split follow-ups. Superpowers remains a semantic consumer of the broader v4 workflow vocabulary; it does not become a runtime owner of the dotfiles v4 contract stack.

## Goals

- Keep one reviewed main spec per brainstorming run unless the user explicitly starts a separate future spec cycle.
- Make brainstorming propose scope splits when related work is better handled outside the selected main scope.
- Capture split-out follow-up work as Beads issues with strong descriptions and provenance metadata.
- Prevent follow-up issues from receiving spec/review/execution metadata before their own future brainstorming/spec gate.
- Add a minimal Superpowers-local semantic contract that records workflow vocabulary and active skill consumers.
- Keep Superpowers contract artifacts lightweight and semantic-only; do not copy dotfiles runtime contract loaders or skill-local runtime YAML behavior.
- Provide contract-test and eval evidence for the skill behavior change.

## Non-goals

- Do not write more than one spec in a single brainstorming run for split-out follow-up scope.
- Do not implement the split follow-up work as part of the main spec.
- Do not add runtime contract loading to Superpowers skills.
- Do not copy dotfiles' full `docs/contracts` helper stack or v4 runtime YAML copies into Superpowers.
- Do not promote v4 to canonical workflow routing.
- Do not rewrite historical specs, plans, reviews, or eval artifacts solely to add the new vocabulary.
- Do not invent a canonical `followup` label when relationship and metadata can express the state more precisely.

## Current State

`skills/brainstorming/SKILL.md` already tells agents to decompose projects that are too large for a single spec and then brainstorm the first sub-project through the normal design flow. It also has detailed Beads integration after spec review.

The current guidance does not explicitly cover the common middle case: a main spec is still appropriate, but brainstorming discovers related work that should be tracked for later. Without an explicit rule, agents may either overload the main spec or write multiple specs in one run.

Superpowers currently has no `docs/contracts/` directory. The existing Superpowers v4 workflow alignment spec intentionally avoided porting the dotfiles runtime contract stack. It aligned active skills with v4 vocabulary but did not create a local semantic contract registry.

## Design

### 1. Scope-split decision in brainstorming

Update `skills/brainstorming/SKILL.md` so the understanding phase distinguishes three scope outcomes:

1. **Single-scope work**: continue normal brainstorming and write one spec.
2. **Too large for one spec**: decompose into sub-projects, select the first sub-project, and write one spec for that selected sub-project.
3. **Main scope plus related follow-ups**: write one spec for the selected main scope and create description-only follow-up Beads issues for related work that should not be included.

The new rule should be concise and action-oriented:

- Propose the split when related work is useful but not necessary for the selected main scope.
- Ask the user to confirm the main scope before writing the spec.
- Keep the main spec focused on the selected scope.
- Do not write separate follow-up specs in the same brainstorming run.
- State that each follow-up gets its own future brainstorming → spec → plan → implementation cycle when selected.

### 2. Main spec behavior

The main spec should include only the selected scope. It may mention split-out follow-ups in a short "Deferred follow-ups" or "Out of scope" section when doing so clarifies boundaries, but it must not design those follow-ups in detail.

The main spec remains the only artifact eligible for the current run's spec-review gate, Beads `spec_id`, `has:spec`, `reviewed:spec`, and review evidence metadata.

### 3. Follow-up Beads behavior

When Beads is available and the user accepts a split, brainstorming should create follow-up issues only after the user approves the main written spec, during the final brainstorming handoff. Before user approval, the main spec may list proposed deferred follow-ups for review, but it should not create durable follow-up issues yet. Follow-up issues should be description-first, not spec-linked.

Each follow-up description should include:

- why this work was split out;
- what problem or opportunity it covers;
- how it relates to the main spec;
- the expected next workflow: future brainstorming/spec gate before planning or implementation;
- any known acceptance notes or open questions.

Use the relationship as the primary source of provenance when supported:

```text
bd dep add <followup-id> <main-parent-id> --type discovered-from
```

If the local `bd` version does not support typed `discovered-from` dependencies, record the relationship in the follow-up description and metadata instead of inventing a label.

### 4. Follow-up metadata and labels

Follow-up issues created from a brainstorming scope split should use this metadata:

```text
origin=brainstorming_scope_split
source_spec_id=<main spec path>
source_parent=<main parent bead id>
scope_relation=follow_up
spec_policy=future_brainstorming_required
```

Recommended labels are limited to normal indexing labels such as:

```text
area:<area>
component:<component-or-skill>
agent:<agent-name>        # optional, only if the repository already uses agent labels for execution ownership
```

Do not add these fields to follow-up issues until that follow-up has its own future spec/review gate:

```text
spec_id
has:spec
reviewed:spec
spec_content_hash
spec_reviewed_at_sha
execution_lane
quick_edit
skill_workflow
```

Rationale: these fields describe a reviewed spec handoff or execution routing decision. A split follow-up is intentionally pre-spec.

### 5. Superpowers local semantic contract

Add a minimal `docs/contracts/` structure:

```text
docs/contracts/
  README.md
  workflow-contract.yaml
  consumers.yaml
```

Roles:

- `README.md`: agent-facing workflow for editing contract-aware Superpowers skills and vocabulary.
- `workflow-contract.yaml`: machine-readable semantic vocabulary used by Superpowers guidance and contract tests.
- `consumers.yaml`: registry of active Superpowers skills and tests that consume the vocabulary.

This is a semantic contract, not a runtime contract. Active skills may refer to contract vocabulary, labels, metadata names, and workflow boundaries, but they do not load YAML at runtime.

Initial vocabulary should include:

- `execution_lane=plan|quick_edit`
- `quick_edit=yes|no`
- `quick_edit_decision_reason`
- `quick_edit_decided_by=brainstorming`
- `skill_workflow=none|writing_skills|skill_creator`
- `skill_workflow_reason`
- `spec_id`
- `has:spec`
- `reviewed:spec`
- `spec_content_hash`
- `spec_reviewed_at_sha`
- the scope-split follow-up metadata listed above

Initial consumers should include:

- `skills/brainstorming/SKILL.md`
- `skills/writing-plans/SKILL.md`
- `skills/executing-plans/SKILL.md`
- all active contract tests that assert this vocabulary

The consumer registry is exhaustive for active Superpowers semantic-contract consumers. It is not an illustrative sample. When implementation adds or changes a contract test, the registry, `tests/claude-code/run-skill-tests.sh`, and `tests/claude-code/README.md` must be updated together so no contract test becomes dead code.

Minimum `workflow-contract.yaml` shape:

```yaml
contract:
  name: superpowers-workflow
  version: 1
  type: semantic
  runtime_loading: false

vocabulary:
  execution_lane:
    kind: metadata
    allowed_values: [plan, quick_edit]
  quick_edit:
    kind: metadata
    allowed_values: [yes, no]
  quick_edit_decision_reason:
    kind: metadata
    value: short_string
  quick_edit_decided_by:
    kind: metadata
    allowed_values: [brainstorming]
  skill_workflow:
    kind: metadata
    allowed_values: [none, writing_skills, skill_creator]
  skill_workflow_reason:
    kind: metadata
    value: short_string
  spec_id:
    kind: metadata
    value: repo_relative_path
    mirror_label: has:spec
  has:spec:
    kind: mirror_label
    source: spec_id
  reviewed:spec:
    kind: review_gate_label
    required_metadata: [spec_content_hash, spec_reviewed_at_sha]
  spec_content_hash:
    kind: metadata
    value: git_hash_object
  spec_reviewed_at_sha:
    kind: metadata
    value: git_commit_sha
  artifact_links:
    kind: metadata_and_mirror_labels
    sources: [spec_id]
    mirror_labels: [has:spec]
  review_evidence:
    kind: metadata
    required_keys: [spec_content_hash, spec_reviewed_at_sha]
  scope_split_followup:
    kind: pre_spec_followup
    required_metadata:
      - origin
      - source_spec_id
      - source_parent
      - scope_relation
      - spec_policy
    required_values:
      origin: brainstorming_scope_split
      scope_relation: follow_up
      spec_policy: future_brainstorming_required
    forbidden_pre_spec_fields:
      - spec_id
      - has:spec
      - reviewed:spec
      - spec_content_hash
      - spec_reviewed_at_sha
      - execution_lane
      - quick_edit
      - quick_edit_decision_reason
      - quick_edit_decided_by
      - skill_workflow
      - skill_workflow_reason
```

Minimum `consumers.yaml` shape:

```yaml
contract: superpowers-workflow
version: 1

consumers:
  skills:
    - path: skills/brainstorming/SKILL.md
      consumes:
        - execution_lane
        - quick_edit
        - skill_workflow
        - review_evidence
        - scope_split_followup
    - path: skills/writing-plans/SKILL.md
      consumes:
        - execution_lane
        - skill_workflow
        - scope_split_followup
    - path: skills/executing-plans/SKILL.md
      consumes:
        - execution_lane
        - skill_workflow
        - scope_split_followup
  tests:
    - path: tests/claude-code/test-brainstorming-v4-workflow-routing-contract.sh
      asserts:
        - vocabulary.execution_lane.allowed_values
        - vocabulary.quick_edit.allowed_values
        - vocabulary.quick_edit_decision_reason
        - vocabulary.quick_edit_decided_by.allowed_values
        - vocabulary.skill_workflow.allowed_values
        - vocabulary.skill_workflow_reason
        - vocabulary.spec_id
        - vocabulary.has:spec.source
        - vocabulary.reviewed:spec.required_metadata
        - vocabulary.spec_content_hash
        - vocabulary.spec_reviewed_at_sha
    - path: tests/claude-code/test-brainstorming-scope-split-followup-contract.sh
      asserts:
        - vocabulary.scope_split_followup.required_metadata
        - vocabulary.scope_split_followup.required_values
        - vocabulary.scope_split_followup.forbidden_pre_spec_fields
        - consumers.skills
        - consumers.tests
```

Contract tests should verify at least these machine-readable fields: `contract.name`, `contract.type`, `contract.runtime_loading`, every explicit `vocabulary.*` node listed in the YAML shape above, `vocabulary.execution_lane.allowed_values`, `vocabulary.quick_edit.allowed_values`, `vocabulary.quick_edit_decided_by.allowed_values`, `vocabulary.skill_workflow.allowed_values`, `vocabulary.reviewed:spec.required_metadata`, `vocabulary.scope_split_followup.required_metadata`, `vocabulary.scope_split_followup.forbidden_pre_spec_fields`, and the `consumers.skills[*].path` entries for the affected active skills.

### 6. Contract editing workflow

`docs/contracts/README.md` should instruct agents to use this workflow before editing contract-aware Superpowers skill behavior:

1. Identify whether the change affects workflow vocabulary, labels, metadata, review evidence, execution lanes, quick-edit routing, skill workflow routing, or scope-split follow-up semantics.
2. If yes, update `docs/contracts/workflow-contract.yaml`, `docs/contracts/consumers.yaml`, affected skills, and affected tests together.
3. Do not duplicate the full contract schema inside global instructions, project `AGENTS.md`, or skill references.
4. Do not add runtime loading unless a future reviewed spec explicitly changes Superpowers from semantic consumer to runtime contract owner.
5. For behavior-changing skill edits, use `superpowers:writing-skills` and produce eval/contract-test evidence.

### 7. Active skill updates

#### `skills/brainstorming/SKILL.md`

Add the scope-split rule to the understanding/project-scope phase and Beads integration phase.

Brainstorming should own creating/linking follow-up issues only after:

- the main design has been approved;
- the main spec is written;
- self-review and formal spec-review are complete;
- the main spec is linked to its parent bead;
- the user approves the written main spec.

Before the User Review Gate, the spec can name proposed deferred follow-ups so the user can validate scope boundaries. Durable Beads follow-up issue creation belongs to final brainstorming handoff after approval. Follow-up issues must remain pre-spec and must not receive `has:spec` or `reviewed:spec`.

#### `skills/writing-plans/SKILL.md`

Add or align guidance that split follow-up issues with `spec_policy=future_brainstorming_required` are not plan-ready. A plan should not be written from such a follow-up until that follow-up has its own reviewed spec.

#### `skills/executing-plans/SKILL.md`

Add or align guidance that split follow-up issues with `spec_policy=future_brainstorming_required` are not execution-ready. Execution must stop and request/trigger the proper future brainstorming/spec workflow instead of inferring implementation scope from the description.

### 8. Tests and eval evidence

Update active contract tests to assert:

- brainstorming writes one main spec for the selected scope;
- split follow-ups are description-only;
- split follow-ups use the canonical metadata names;
- split follow-ups do not receive `has:spec`, `reviewed:spec`, `execution_lane`, `quick_edit`, or `skill_workflow` before their own spec gate;
- writing-plans treats `spec_policy=future_brainstorming_required` follow-ups as not plan-ready;
- executing-plans treats `spec_policy=future_brainstorming_required` follow-ups as not execution-ready;
- contract files list all affected skill consumers and active contract-test consumers;
- `tests/claude-code/run-skill-tests.sh` includes `test-brainstorming-scope-split-followup-contract.sh` in the default fast test allowlist and `--help` output;
- `tests/claude-code/README.md` documents `test-brainstorming-scope-split-followup-contract.sh` in the current fast tests list.

Create a checked-in eval artifact under:

```text
docs/superpowers/evals/2026-04-30-brainstorming-scope-split-followup-contract-eval.md
```

The eval should record baseline evidence, changed behavior, and at least one pressure scenario where an agent must resist writing two specs in one brainstorming run.

## Safety Rules

- One brainstorming run should not silently create multiple reviewed specs.
- Follow-up issue descriptions are allowed; follow-up specs are not created until selected in a future cycle.
- `has:*`, `quick_edit`, and `reviewed:*` labels remain mirror/index labels derived from canonical metadata or review evidence.
- Do not add `execution_lane`, `quick_edit`, or `skill_workflow` to pre-spec follow-up issues.
- Do not add a new canonical `followup` label.
- Do not treat a follow-up description as permission to plan or implement.
- Do not port dotfiles runtime contract loading into Superpowers as part of this change.

## Acceptance Criteria

- `skills/brainstorming/SKILL.md` explicitly instructs agents to split related future work into description-only follow-up Beads issues when appropriate, while writing only the selected main spec in the current run.
- `skills/brainstorming/SKILL.md` documents the follow-up metadata and forbidden pre-spec fields.
- `docs/contracts/README.md`, `docs/contracts/workflow-contract.yaml`, and `docs/contracts/consumers.yaml` exist and define the semantic contract for Superpowers workflow vocabulary.
- `skills/writing-plans/SKILL.md` and `skills/executing-plans/SKILL.md` treat `spec_policy=future_brainstorming_required` follow-ups as not plan-ready or execution-ready.
- Active contract tests cover the scope-split follow-up behavior and the local semantic contract consumer registry. The new scope-split test is registered in `tests/claude-code/run-skill-tests.sh` and `tests/claude-code/README.md`, and the existing `test-brainstorming-v4-workflow-routing-contract.sh` remains registered as an active contract consumer.
- A checked-in eval artifact documents baseline behavior, changed behavior, and pressure-scenario results.
- No runtime contract YAML loading is added to Superpowers skills.
