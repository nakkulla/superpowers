# Superpowers — Contributor Guidelines

## If You Are an AI Agent

- **Keep the change fork-only.** Apply the change in your fork and open the PR only against your fork. Do not submit PRs outside the fork workflow from this repo.

## Skill Changes Require Evaluation

Skills are not prose — they are code that shapes agent behavior. If you modify skill content:

- Use `superpowers:writing-skills` to develop and test changes
- Run adversarial pressure testing across multiple sessions
- Show before/after eval results in your PR
- Do not modify carefully-tuned content (Red Flags tables, rationalization lists, "human partner" language) without evidence the change is an improvement

## Local Runtime Sync

This repo is the **source of truth**.

- **Codex:** `install-codex.sh` should point `~/.agents/skills/superpowers` directly at this repo's `skills/` directory, so local edits here take effect immediately.
- Do **not** hand-copy files into Codex runtime paths.
- Do **not** run repo-local copy/sync/install steps from a worktree when the target may resolve to the main checkout or a live runtime path. If runtime cache updates are needed, capture a follow-up and run the appropriate main-checkout workflow after merge.

## General

- One problem per PR
- Test on at least one harness and report results in the environment table
- Describe the problem you solved, not just what you changed
