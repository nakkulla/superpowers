# Brainstorming Quick Edit Owner Alignment Implementation Plan
Parent bead: superpowers-a91

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Align `skills/brainstorming/SKILL.md` so `quick_edit` is documented as a conservative brainstorming-owned preflight exception, not a general shortcut or parent-bead state, while preserving the existing normal spec-path Beads contract.

**Architecture:** Keep the change narrow and skill-local. Capture RED/GREEN evidence in a checked-in eval artifact, update `skills/brainstorming/SKILL.md` with one explicit `quick_edit` guidance block plus minimal Beads issue-handling wording, then run targeted smoke checks and sync installed plugin copies so the updated skill is actually deployable from this repo.

**Tech Stack:** Markdown skill docs, Claude CLI smoke tests, `rg`, `sed`, `git diff`, Beads CLI (`bd`), plugin sync script

---

## File Structure

| File | Responsibility |
| --- | --- |
| `skills/brainstorming/SKILL.md` | Add the brainstorming-owned `quick_edit` preflight exception guidance, allowed/disallowed examples, and standalone-issue labeling rules without changing normal spec-path parent linkage semantics |
| `docs/superpowers/evals/2026-04-22-brainstorming-quick-edit-owner-alignment-eval.md` | Record before/after eval evidence, prompt cases, observed baseline/candidate behavior, and verification results |
| `$HOME/.claude/plugins/marketplaces/superpowers-custom/skills/brainstorming/SKILL.md` | Synced installed Claude plugin copy |
| `$HOME/.claude/plugins/cache/superpowers-custom/skills/brainstorming/SKILL.md` | Synced installed Claude cache copy |
| `$HOME/.codex/superpowers/skills/brainstorming/SKILL.md` | Synced installed Codex copy after repo commit/push via `scripts/sync-local-plugin-copies.sh after-commit` |

### Task 1: Capture baseline evidence for quick_edit behavior gaps

**Files:**
- Create: `docs/superpowers/evals/2026-04-22-brainstorming-quick-edit-owner-alignment-eval.md`
- Test: `skills/brainstorming/SKILL.md`

- [ ] **Step 1: Capture the current quick_edit text baseline**

**REQUIRED SUB-SKILL:** Use superpowers:writing-skills
**ALSO REQUIRED:** Use skill-creator because this is an eval-driven edit of an existing skill artifact.

Run:

```bash
rg -n 'quick_edit|quick-edit|standalone issue|reviewed:spec|spec path' skills/brainstorming/SKILL.md || true
sed -n '1,220p' skills/brainstorming/SKILL.md
```

Expected: `skills/brainstorming/SKILL.md` has no dedicated `quick_edit` guidance block describing a conservative preflight exception, allowed/disallowed examples, or standalone quick-edit issue rules.

- [ ] **Step 2: Run an eligible one-shot baseline smoke session**

Create a temporary prompt and run Claude against the repo-local plugin copy:

```bash
cat >/tmp/brainstorming-quick-edit-eligible.txt <<'PROMPT'
Please use the brainstorming skill.
I have a tiny one-shot copy edit in a Beads-enabled repo: rename one button label and ship it safely.
Should this stay on the normal spec path or qualify for a quick_edit-style exception?
PROMPT

claude -p "$(cat /tmp/brainstorming-quick-edit-eligible.txt)" \
  --plugin-dir "$PWD" \
  --dangerously-skip-permissions \
  --max-turns 3 \
  > /tmp/brainstorming-quick-edit-eligible.out 2>&1 || true
```

Expected: baseline output does **not** yet cleanly describe the new brainstorming-owned `quick_edit` exception and standalone issue labeling rule.

- [ ] **Step 3: Run an ineligible shared-contract baseline smoke session**

```bash
cat >/tmp/brainstorming-quick-edit-ineligible.txt <<'PROMPT'
Please use the brainstorming skill.
I need to align shared quick_edit policy wording across skills and repos.
Can we just treat this as quick_edit and skip the normal design path?
PROMPT

claude -p "$(cat /tmp/brainstorming-quick-edit-ineligible.txt)" \
  --plugin-dir "$PWD" \
  --dangerously-skip-permissions \
  --max-turns 3 \
  > /tmp/brainstorming-quick-edit-ineligible.out 2>&1 || true
```

Expected: baseline output may reject quick_edit implicitly, but it still lacks the explicit owner-boundary wording and standalone-issue semantics required by the new spec.

- [ ] **Step 4: Create the eval artifact shell with baseline placeholders replaced by real observations**

Create `docs/superpowers/evals/2026-04-22-brainstorming-quick-edit-owner-alignment-eval.md` with sections for:
- harness + purpose
- baseline observations from the two smoke sessions
- candidate observations to fill after the skill edit
- direct text verification commands
- plugin sync verification

Expected: the eval document exists and already contains the RED-phase baseline findings from Steps 1-3.

- [ ] **Step 5: Commit**

```bash
git add docs/superpowers/evals/2026-04-22-brainstorming-quick-edit-owner-alignment-eval.md
git commit -m "docs(eval): quick_edit brainstorming 기준선 기록"
```

### Task 2: Add brainstorming-owned quick_edit guidance to the skill

**Files:**
- Modify: `skills/brainstorming/SKILL.md`
- Test: `skills/brainstorming/SKILL.md`

- [ ] **Step 1: Capture the current insertion context**

**REQUIRED SUB-SKILL:** Use superpowers:writing-skills
**ALSO REQUIRED:** Use skill-creator because this task changes an existing skill artifact.

Run:

```bash
sed -n '13,80p' skills/brainstorming/SKILL.md
sed -n '236,390p' skills/brainstorming/SKILL.md
```

Expected: the anti-pattern / process guidance exists, but there is no dedicated section that defines `quick_edit` as a conservative brainstorming-owned exception.

- [ ] **Step 2: Insert a dedicated quick_edit guidance block**

Apply a narrow patch that adds a section near the top-level process guidance with these requirements:
- `quick_edit` is a conservative preflight exception, not the default path
- ambiguous cases stay on normal brainstorming → spec
- allowed examples: small bugfix, copy/text edit, config/path tweak, other narrow one-shot changes
- disallowed examples: multi-step work, broad behavior changes, shared contract/policy wording, cross-skill or cross-repo changes
- when selected in a Beads-enabled repo, create a new standalone execution issue and label **that new issue** `quick_edit`
- explicitly say this does not rewrite the normal spec-path parent/`spec_id`/`reviewed:spec` behavior

- [ ] **Step 3: Verify the required quick_edit phrases are present**

Run:

```bash
rg -n 'conservative preflight exception|ambiguous cases stay on the normal brainstorming → spec path|small bugfix|copy / text edit|shared contract / policy wording|cross-skill|cross-repo|new standalone execution issue|label that new issue `quick_edit`|does not change the normal spec-path parent' skills/brainstorming/SKILL.md
```

Expected: each required phrase is present exactly once in the new quick_edit block.

- [ ] **Step 4: Verify the existing normal spec gate language still remains**

Run:

```bash
rg -n 'Mark parent bead `reviewed:spec`|Do \*\*not\*\* attach the spec to a child issue|bd update <parent-id> --add-label reviewed:spec' skills/brainstorming/SKILL.md
```

Expected: the legacy parent-only spec-path safety lines still exist unchanged alongside the new quick_edit wording.

- [ ] **Step 5: Commit**

```bash
git add skills/brainstorming/SKILL.md
git commit -m "docs(brainstorming): quick_edit owner 경계 명확화"
```

### Task 3: Verify candidate behavior, sync plugin copies, and finalize eval evidence

**Files:**
- Modify: `docs/superpowers/evals/2026-04-22-brainstorming-quick-edit-owner-alignment-eval.md`
- Modify: `skills/brainstorming/SKILL.md`
- Test: `docs/superpowers/evals/2026-04-22-brainstorming-quick-edit-owner-alignment-eval.md`
- Test: `scripts/sync-local-plugin-copies.sh`

- [ ] **Step 1: Re-run both smoke sessions against the candidate skill**

**REQUIRED SUB-SKILL:** Use superpowers:writing-skills
**ALSO REQUIRED:** Use skill-creator because this task closes the eval loop for a skill edit.

Run the same two Claude commands from Task 1 again after the skill edit.

Expected:
- eligible prompt: candidate output explicitly describes `quick_edit` as a narrow brainstorming-owned exception and distinguishes the standalone quick-edit issue from the normal spec-path parent
- ineligible prompt: candidate output explicitly keeps shared contract / policy wording work on the normal design path

- [ ] **Step 2: Run direct text verification checks**

```bash
git diff --check
rg -n 'quick_edit|quick-edit|standalone execution issue|normal brainstorming → spec|shared contract / policy wording' skills/brainstorming/SKILL.md
```

Expected: `git diff --check` passes and the new wording is visible in one focused section.

- [ ] **Step 3: Sync installed Claude/plugin copies and verify parity**

```bash
scripts/sync-local-plugin-copies.sh copy
scripts/sync-local-plugin-copies.sh verify
```

Expected: copy completes without errors and verify reports no drift for the installed Claude/plugin copies; the verify output may still note that the Codex clone must be compared after commit/push.

- [ ] **Step 4: Finalize the eval artifact with before/after findings**

Update `docs/superpowers/evals/2026-04-22-brainstorming-quick-edit-owner-alignment-eval.md` so it records:
- baseline vs candidate observations for both prompts
- exact verification commands and PASS/FAIL results
- sync verification result, including the fact that Codex clone fast-forward happens only after commit/push
- remaining limitations (targeted smoke tests, not a full exhaustive campaign)

Expected: the eval file is ready to cite in the PR as before/after evidence.

- [ ] **Step 5: Commit**

```bash
git add skills/brainstorming/SKILL.md docs/superpowers/evals/2026-04-22-brainstorming-quick-edit-owner-alignment-eval.md
git commit -m "test(brainstorming): quick_edit 정렬 검증 기록"
```

- [ ] **Step 6: Fast-forward the Codex clone after commit/push**

After the repo commit is pushed, run:

```bash
scripts/sync-local-plugin-copies.sh after-commit
```

Expected: `~/.codex/superpowers` fast-forwards to the same `HEAD` as the repo and the script prints an `OK [codex]` line.
