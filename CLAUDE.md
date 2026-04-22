# Superpowers — Contributor Guidelines

## If You Are an AI Agent

- **Keep the change fork-only.** Apply the change in your fork and open the PR only against your fork. Do not submit PRs to upstream (`obra/superpowers`) from this workflow.

## Skill Changes Require Evaluation

Skills are not prose — they are code that shapes agent behavior. If you modify skill content:

- Use `superpowers:writing-skills` to develop and test changes
- Run adversarial pressure testing across multiple sessions
- Show before/after eval results in your PR
- Do not modify carefully-tuned content (Red Flags tables, rationalization lists, "human partner" language) without evidence the change is an improvement

## Local Plugin Sync

This repo is the **source of truth**. After making any changes here, you MUST sync them to all installed plugin locations:

```
/Users/isy_macstudio/GitHub/superpowers
~/.claude/plugins/marketplaces/superpowers-custom
~/.claude/plugins/cache/superpowers-custom
~/.claude/plugins/cache/superpowers-custom/superpowers/<active-version>  # if present
~/.codex/superpowers
```

These are separate copies (not symlinks). Changes made only in the repo will not take effect until synced. Changes made only in the plugin directories will be lost on next sync/install.

**Preferred workflow:** Always edit in this repo first, then use the sync script instead of hand-copying paths:

```bash
scripts/sync-local-plugin-copies.sh copy
scripts/sync-local-plugin-copies.sh verify
scripts/sync-local-plugin-copies.sh after-commit
```

- `copy` syncs tracked working-tree files to installed Claude/plugin copies, including discovered Claude cache version directories
- `verify` checks those copies for drift and also reports whether `~/.codex/superpowers` matches repo HEAD
- `after-commit` is the Codex step: commit/push from this repo first, then let the script run `git pull --ff-only` in `~/.codex/superpowers`
- Do **not** sync `~/.codex/superpowers` via `cp`

## General

- One problem per PR
- Test on at least one harness and report results in the environment table
- Describe the problem you solved, not just what you changed
