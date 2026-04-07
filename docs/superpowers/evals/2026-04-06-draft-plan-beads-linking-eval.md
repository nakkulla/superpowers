# Draft Plan Immediate Beads Linking Eval

- **Date:** 2026-04-06
- **Harness:** file-diff evidence + targeted skill-text verification
- **Baseline:** `HEAD~2`
- **Candidate:** working tree / branch tip after implementation
- **Purpose:** Verify that `writing-plans` links plans immediately while `executing-plans` still treats `reviewed:plan` as the execution gate.
- **Limitations:** This is a focused documentation-behavior eval, not a full multi-harness campaign.

## Verification Summary

### Repo-level checks

- `git diff --check` → PASS
- `rg -n "Post-Plan-Review|After the plan review loop passes" skills/writing-plans/SKILL.md` → no matches
- `rg -n "plan-document pointer|passed review" skills/executing-plans/SKILL.md` → matches the new clarification

### Adversarial CLI checks

- **Session A — `writing-plans` auto-mode timing**
  - Prompt: “In `--auto` mode, when `.beads/` exists and the parent bead can be resolved safely, what happens after the plan is written?”
  - Observed result: the Claude CLI answer explicitly said linkage happens **after the built-in self-review** and that execution-choice prompting is skipped.
- **Session B — `executing-plans` gate semantics**
  - Prompt: “A linked bead has `metadata.plan` but does NOT have `reviewed:plan`. In `--auto` mode, can execution proceed just because the plan is linked?”
  - Observed result: the Claude CLI answer explicitly said **no**; `metadata.plan` is only a document pointer and `--plan-review` controls whether execution may continue.

## Baseline vs Candidate

### 1. `skills/writing-plans/SKILL.md`

**Baseline (`HEAD~2`)**

```text
### Beads Plan Link (Post-Plan-Review)

After the plan review loop passes, connect the plan to the Beads issue tracker
if `.beads/` directory exists in the project:
```

**Candidate**

```text
### Beads Plan Link

After saving the plan and completing the built-in self-review, connect the plan
to the Beads issue tracker if `.beads/` directory exists in the project:
```

**Observed effect**

- Confirms `metadata.plan` linkage happens at draft-plan time rather than after plan review.

### 2. `skills/executing-plans/SKILL.md`

**Baseline (`HEAD~2`)**

```text
Plan path mode + `.beads/` exists:
1. `bd list --all --metadata-field plan=<current-plan-path> --json` to find linked issues regardless of status
```

**Candidate**

```text
Plan path mode + `.beads/` exists:
1. `bd list --all --metadata-field plan=<current-plan-path> --json` to find linked issues regardless of status
...
A linked `metadata.plan` entry is only a plan-document pointer; it does not imply the plan has already passed review.
```

**Observed effect**

- Confirms the lookup pointer meaning is explicit while the `reviewed:plan` gate remains the execution approval signal.

## Adversarial Evaluation Notes

- Harness: Claude CLI with `--plugin-dir` pointed at the modified worktree
- Sessions run after the change: **2**
- Outcome shift:
  - Before this change, the skill text left room to read `metadata.plan` as a post-review signal and to describe plan linkage as post-review only.
  - After this change, both adversarial prompts produced the intended answer:
    1. `writing-plans --auto` links after self-review and skips execution-choice prompts
    2. `executing-plans` does not treat `metadata.plan` alone as execution approval
