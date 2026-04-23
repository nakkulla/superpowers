# Superpowers — Contributor Guidelines

## If You Are an AI Agent

- **Keep the change fork-only.** Apply the change in your fork and open the PR only against your fork. Do not submit PRs outside the fork workflow from this repo.

## Skill Changes Require Evaluation

Skills are not prose — they are code that shapes agent behavior. If you modify skill content:

- Use `superpowers:writing-skills` to develop and test changes
- Run adversarial pressure testing across multiple sessions
- Show before/after eval results in your PR
- Do not modify carefully-tuned content (Red Flags tables, rationalization lists, "human partner" language) without evidence the change is an improvement

## Local Plugin Sync

This repo is the **source of truth**.

- **Codex:** `install-codex.sh` should point `~/.agents/skills/superpowers` directly at this repo's `skills/` directory, so local edits here take effect immediately.
- **Claude/plugin caches:** still use separate copies and must be synced from this repo.

**Preferred workflow:** Always edit in this repo first, then use the sync script for Claude/plugin copies:

```bash
scripts/sync-local-plugin-copies.sh copy
scripts/sync-local-plugin-copies.sh verify
```

- `copy` syncs tracked working-tree files to installed Claude/plugin copies, including discovered Claude cache version directories
- `verify` checks those copies for drift and also confirms whether Codex is reading this repo directly
- `after-commit` is a lightweight health check for the direct-link Codex setup
- Do **not** hand-copy files into Codex runtime paths

## General

- One problem per PR
- Test on at least one harness and report results in the environment table
- Describe the problem you solved, not just what you changed
