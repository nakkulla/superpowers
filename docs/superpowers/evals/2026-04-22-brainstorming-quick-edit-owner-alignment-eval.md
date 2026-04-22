# Brainstorming Quick Edit Owner Alignment Eval

- **Date:** 2026-04-22
- **Harness:** repo-local `claude -p` smoke sessions + targeted skill-text verification + plugin sync verification
- **Baseline:** current `skills/brainstorming/SKILL.md` before quick_edit wording update
- **Candidate:** working tree after the brainstorming skill update in this run
- **Purpose:** Verify that `brainstorming` owns the `quick_edit` recommendation boundary explicitly in the skill text, keeps ambiguous/shared-policy work on the normal spec path, and distinguishes the standalone quick-edit execution issue from the normal spec-path parent bead.
- **Limitations:** Focused smoke-test evidence only. This is not a full trigger-eval matrix or exhaustive multi-session benchmark.

## Verification Summary

### Repo text baseline

Run:

```bash
rg -n 'quick_edit|quick-edit|standalone issue|reviewed:spec|spec path' skills/brainstorming/SKILL.md || true
sed -n '1,220p' skills/brainstorming/SKILL.md
```

Observed baseline:
- `skills/brainstorming/SKILL.md` has no dedicated `quick_edit` guidance block.
- Matches are only incidental references such as `reviewed:spec`, `spec path`, and Beads parent-linkage rules.
- There is no skill-local wording that says `quick_edit` is a conservative brainstorming-owned preflight exception.
- There are no allowed/disallowed quick_edit examples.
- There is no skill-local rule that says a new standalone execution issue gets the `quick_edit` label.

### Baseline smoke session A — eligible one-shot copy change

Prompt:

```text
Please use the brainstorming skill.
I have a tiny one-shot copy edit in a Beads-enabled repo: rename one button label and ship it safely.
Should this stay on the normal spec path or qualify for a quick_edit-style exception?
```

Observed baseline result:
- The response reaches the desired semantics only by leaning on the checked-in spec draft and global workflow docs, not on a dedicated `brainstorming` skill section.
- It explains the four conservative quick_edit questions and correctly says the new standalone execution issue, not the parent, gets the `quick_edit` label.
- This is useful behavior, but it is **not skill-owned yet**: the answer is reconstructed from other repo context instead of being anchored in `skills/brainstorming/SKILL.md` itself.

Representative excerpt:

> "이 repo의 `2026-04-22-brainstorming-quick-edit-owner-alignment-design.md`는 ... 네 가지 보수 질문 전부에 yes일 때만 quick_edit를 허용"

### Baseline smoke session B — ineligible shared-contract/policy change

Prompt:

```text
Please use the brainstorming skill.
I need to align shared quick_edit policy wording across skills and repos.
Can we just treat this as quick_edit and skip the normal design path?
```

Observed baseline result:
- The response correctly rejects quick_edit for shared contract / cross-repo wording work.
- Again, it justifies that answer by quoting or interpreting the current spec draft, not by pointing to explicit quick_edit wording in the brainstorming skill.
- The response also reveals the current ambiguity pressure: the agent frames the question as interpreting an already-written policy rather than following a skill-owned quick_edit rule.

Representative excerpt:

> "이 spec 자체가 방금 하신 질문에 대한 답을 이미 명시"

## Baseline Assessment

- **What already works:** Repo context is rich enough that the agent can sometimes infer the intended quick_edit boundary from the spec draft.
- **What is still missing:** The `brainstorming` skill itself does not own that contract text yet, so the behavior is not anchored where future runs should discover it.
- **Why this change is still needed:** Without a skill-local quick_edit block, future runs can regress, under-explain the owner boundary, or treat the parent-bead/spec-path rules as the only visible Beads model.

## Candidate Checks (to fill after implementation)

### Candidate smoke session A — eligible one-shot copy change
- Expected: the response explicitly describes `quick_edit` as a brainstorming-owned conservative preflight exception using skill-local wording.
- Expected: the response distinguishes the standalone quick-edit execution issue from the normal spec-path parent bead.

### Candidate smoke session B — ineligible shared-contract/policy change
- Expected: the response explicitly keeps shared contract / policy wording work on the normal brainstorming → spec path.
- Expected: the response uses the disallowed examples and owner-boundary wording from `skills/brainstorming/SKILL.md`, not only from the spec draft.

### Direct text verification
- `git diff --check`
- `rg -n 'quick_edit|quick-edit|standalone execution issue|normal brainstorming → spec|shared contract / policy wording' skills/brainstorming/SKILL.md`

### Plugin sync verification
- `scripts/sync-local-plugin-copies.sh copy`
- `scripts/sync-local-plugin-copies.sh verify`
- `scripts/sync-local-plugin-copies.sh after-commit` (after repo commit/push)
