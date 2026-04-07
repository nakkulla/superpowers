# Brainstorming Issue-ID Entry Design

**Status:** Draft for review  
**Date:** 2026-04-08

## Problem

`skills/brainstorming/SKILL.md` currently has no explicit issue-ID input mode.
That creates friction for follow-up work tracked in Beads, especially `discovered-from`
issues that do not yet have a spec:

- the user may already know which issue should drive the spec work,
- but brainstorming still has to infer the target issue later from title or spec-path matching,
- and there is no documented way to say "start from this issue".

This increases ambiguity exactly when the user is trying to create the missing spec for a known follow-up issue.

## Goal

Allow `brainstorming` to accept a Beads issue ID as an optional input so the skill can:

1. load that issue as the starting context,
2. keep asking clarifying questions as normal,
3. treat the explicit issue as the canonical Beads target when it is safe to do so,
4. link the written spec back to the intended parent issue without fuzzy matching.

## Non-Goals

- Skipping the normal brainstorming conversation or clarifying questions
- Auto-generating a full design from the issue text alone
- Allowing `spec-id` linkage to child issues
- Overwriting `spec-id` on `resolved` or `closed` issues
- Changing `writing-plans` or `executing-plans` behavior in this work
- Adding a new Beads metadata field for brainstorming drafts

## Current Behavior

### `brainstorming`

- has no documented `argument-hint`
- assumes a normal conversational entry point
- writes the spec and then resolves a related parent bead by:
  - matching `spec-id`, or
  - matching title/description topic
- links `spec-id` only after the spec review loop passes

### User-visible limitation

If the user already has a known follow-up issue, there is no explicit way to say:

> "Use this issue as the seed context and write the missing spec for it."

As a result, the later Beads-linking step may have to guess which issue to use.

## Proposed Behavior

### Input Model

Add an `argument-hint` to `skills/brainstorming/SKILL.md`:

```yaml
argument-hint: "[issue-id]"
```

Interpret `$ARGUMENTS` as:

- empty → normal brainstorming mode
- Beads issue ID → issue-ID mode (`.beads/` and `bd` required)
- anything else → not issue-ID mode; proceed with normal brainstorming flow

The skill should not require an issue ID. This is an additive entry path, not a replacement for the default flow.

### Issue-ID Mode

When the input looks like a Beads issue ID:

1. Run `bd show <id> --json`
2. Fail fast if the issue cannot be loaded
3. Use the issue's available context as brainstorming seed material, especially:
   - title
   - description
   - labels
   - dependency relationships such as `discovered-from`
4. Continue the normal brainstorming process:
   - explore project context
   - ask clarifying questions one at a time
   - propose approaches
   - present and validate the design
   - write the spec

**Important:** issue-ID mode provides starting context and a canonical linkage target. It does **not** mean the issue already contains enough detail to skip clarification.

### Clarification Rule

The skill must explicitly preserve the current brainstorming discipline:

- issue text is a starting point, not a complete spec
- the assistant should still ask follow-up questions whenever scope, constraints, or success criteria are unclear
- if the user says only "use issue X", the skill should still refine the design through normal questioning before writing the spec

This keeps issue-ID mode aligned with the purpose of brainstorming instead of turning it into a silent conversion step.

## Beads Linking Rules

### Canonical target precedence

When an explicit issue ID was provided, the Beads-linking step should use it as the first-resolution candidate instead of starting from fuzzy matching.

Safe precedence order:

1. explicit issue ID from `$ARGUMENTS`
2. existing `spec-id` match for the current spec path
3. title/description topic match

### Parent-only safety

The existing parent-only rule remains unchanged:

- attach `spec-id` only to a parent bead
- do not attach `spec-id` to a child bead
- if the explicit issue is a child bead, use it as context but re-resolve to the intended parent before linking, or ask the user if the parent is not unambiguous

### Status safety

If the explicit issue resolves to a parent bead:

- `open` or `in_progress` → update that bead with `--spec-id <path> --add-label has:spec`
- `resolved` or `closed` → do not overwrite its `spec-id`

If the explicit issue is `resolved` or `closed`, treat the new spec as follow-up work beyond that issue's completed scope:

- ask the user whether to create a new follow-up parent bead,
- if approved, create the new bead,
- connect it back with `discovered-from` when applicable,
- then link the new spec to the new parent bead.

### No explicit issue ID

If no issue ID was provided, keep the current matching behavior.

This preserves backward compatibility for ordinary brainstorming sessions.

## Rationale

This design solves the specific follow-up workflow without weakening existing safety rules:

- users can point brainstorming at a known issue,
- brainstorming still does real design work instead of pretending the issue is already a spec,
- `spec-id` linkage becomes more deterministic,
- parent/child and status protections stay intact.

It also keeps responsibility boundaries simple:

- `brainstorming` owns spec creation and spec linkage,
- `writing-plans` can continue relying on the resulting `spec-id` linkage,
- no new metadata model is introduced.

## Required Skill Updates

### `skills/brainstorming/SKILL.md`

Update the skill so that it:

1. declares `argument-hint: "[issue-id]"`
2. documents issue-ID mode near the beginning of the process
3. explains that issue-ID mode loads Beads context via `bd show <id> --json`
4. explicitly says clarifying questions still apply in issue-ID mode
5. updates the Beads-linking section so explicit issue ID takes precedence when resolving the target parent bead
6. preserves the existing parent-only and resolved/closed safety rules

## Verification

1. Read `skills/brainstorming/SKILL.md` and confirm it now declares `argument-hint: "[issue-id]"`
2. Confirm the skill documents issue-ID mode and `bd show <id> --json`
3. Confirm the skill explicitly says issue-ID mode does not skip clarifying questions
4. Confirm the Beads-linking section gives explicit issue ID higher precedence than fuzzy matching
5. Confirm child-bead linkage is still forbidden
6. Confirm `resolved` / `closed` issues still cannot have `spec-id` overwritten
7. Confirm no instructions imply that issue-ID mode bypasses the normal design-review flow

## Risks and Mitigations

### Risk: issue-ID mode is interpreted as "no questions needed"

**Mitigation:** explicitly document that issue-ID mode seeds context only; it does not replace clarification.

### Risk: a child issue is linked directly

**Mitigation:** preserve the existing parent-only rule and require parent re-resolution before linking.

### Risk: users expect all arbitrary arguments to be parsed as issue IDs

**Mitigation:** scope the new behavior narrowly to recognized Beads issue IDs and otherwise preserve normal brainstorming entry.

### Risk: completed issues get silently repurposed

**Mitigation:** keep the existing `resolved` / `closed` follow-up rule and require a new parent bead for new scope.
