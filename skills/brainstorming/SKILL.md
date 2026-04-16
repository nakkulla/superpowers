---
name: brainstorming
description: "You MUST use this before any creative work - creating features, building components, adding functionality, or modifying behavior. Explores user intent, requirements and design before implementation."
argument-hint: "[issue-id]"
---

# Brainstorming Ideas Into Designs

Help turn ideas into fully formed designs and specs through natural collaborative dialogue.

Start by understanding the current project context, then ask questions one at a time to refine the idea. Once you understand what you're building, present the design and get user approval.

<HARD-GATE>
Do NOT invoke any implementation skill, write any code, scaffold any project, or take any implementation action until you have presented a design and the user has approved it. This applies to EVERY project regardless of perceived simplicity.
</HARD-GATE>

## Anti-Pattern: "This Is Too Simple To Need A Design"

Every project goes through this process. A todo list, a single-function utility, a config change — all of them. "Simple" projects are where unexamined assumptions cause the most wasted work. The design can be short (a few sentences for truly simple projects), but you MUST present it and get approval.

## Checklist

You MUST create a task for each of these items and complete them in order:

1. **Explore project context** — check files, docs, recent commits
2. **Offer visual companion** (if topic will involve visual questions) — this is its own message, not combined with a clarifying question. See the Visual Companion section below.
3. **Ask clarifying questions** — one at a time, understand purpose/constraints/success criteria
4. **Propose 2-3 approaches** — with trade-offs and your recommendation
5. **Optional Codex collaboration (Claude Code only)** — if Claude Code has `codex-plugin-cc` available and a second design pass would materially help, delegate exactly one bounded advisory design-analysis task to Codex. Treat Codex output as advisory only.
6. **Present design** — in sections scaled to their complexity, get user approval after each section
7. **Write design doc** — save to `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md` and commit
8. **Spec self-review** — quick inline check for placeholders, contradictions, ambiguity, scope (see below)
9. **Formal independent spec-review gate** — after self-review and before user review, run a formal `spec-review` through an independent reviewer. This gate is mandatory for written specs. Harness-specific executor:
   - **Codex:** dispatch a bounded read-only subagent via `spawn_agent` and instruct it to invoke the `spec-review` skill on the current spec path.
   - **Claude Code:** use `/codex:rescue` and instruct Codex to invoke the `spec-review` skill on the current spec path and return the formal review block.
   Reading `spec-review` references, doing a checklist pass, or saying "spec-review 기준으로 점검" does **not** satisfy this step. This step is complete only after the transcript contains the formal `## Spec Review` output with `Verdict:` from the harness's independent-review executor, and the main agent has summarized what changed. When the formal review was produced by a sidecar or subagent, the main agent must surface that latest formal review block into the main transcript before or alongside the reconciliation summary.
10. **Automatic independent spec-review loop** — after each **substantive** spec edit and before the User Review Gate, re-run the harness's independent-review executor until the review reaches a non-blocking verdict (`APPROVE` or `APPROVE_WITH_CHANGES`), the pass cap is reached, or the same material findings repeat without substantive progress. The reviewer remains advisory only; the main agent applies revisions and owns final judgment. Cap this loop at 3 automatic passes. Do **not** ask the user whether to run this mandatory loop.
    Hard gate:
    - In Codex, if `spawn_agent` is available, the spec-review subagent path is mandatory.
    - In Claude Code, if `/codex:rescue` is available, the Codex sidecar spec-review path is mandatory.
    - Do NOT silently replace the harness's independent-review executor with a main-agent direct review.
    - If the independent-review executor is unavailable or policy-blocked, say so explicitly. A direct `spec-review` fallback is informational only and does **not** complete the normal gate.
    - Do NOT mark `reviewed:spec`.
    - Do NOT invoke `writing-plans`.
    - Do NOT say the spec gate is complete.
    - Do NOT proceed if the transcript lacks a completed formal `spec-review` result from the harness's independent-review executor and the main agent's reconciliation summary for the latest pass.
    until the latest pass has finished and its findings have been reconciled by the main agent.
11. **Optional Codex challenge re-review loop (Claude Code only)** — if a written spec exists and Claude Code has `codex-plugin-cc` available, default to one bounded advisory Codex critique pass after the formal `spec-review` gate is already non-blocking. If substantive spec edits are made and material findings remain, you may re-run it up to 3 total advisory passes per brainstorming run.
12. **User reviews written spec** — ask user to review the spec file before proceeding
13. **Mark parent bead `reviewed:spec`** — after the full spec gate passes, the main brainstorming flow labels the linked parent bead
14. **Transition to implementation** — invoke writing-plans skill to create implementation plan. Do **not** transition from a chat-only draft: planning starts only after a written spec file exists, is linked via `spec_id`, and passes the spec gate.

## Process Flow

```dot
digraph brainstorming {
    "Explore project context" [shape=box];
    "Visual questions ahead?" [shape=diamond];
    "Offer Visual Companion\n(own message, no other content)" [shape=box];
    "Ask clarifying questions" [shape=box];
    "Propose 2-3 approaches" [shape=box];
    "Need bounded Codex design pass?" [shape=diamond];
    "Run optional Codex collaboration" [shape=box];
    "Present design sections" [shape=box];
    "User approves design?" [shape=diamond];
    "Write design doc" [shape=box];
    "Spec self-review\n(fix inline)" [shape=box];
    "Run formal\nspec-review" [shape=box];
    "Apply spec-review\nfixes" [shape=box];
    "Need another automatic\nspec-review pass?" [shape=diamond];
    "Need optional Claude Code\nchallenge pass?" [shape=diamond];
    "Run optional Codex\nchallenge pass" [shape=box];
    "Claude Code advisory passes\n< 3 and substantive changes remain?" [shape=diamond];
    "User reviews spec?" [shape=diamond];
    "Mark parent bead\nreviewed:spec" [shape=box];
    "Invoke writing-plans skill" [shape=doublecircle];

    "Explore project context" -> "Visual questions ahead?";
    "Visual questions ahead?" -> "Offer Visual Companion\n(own message, no other content)" [label="yes"];
    "Visual questions ahead?" -> "Ask clarifying questions" [label="no"];
    "Offer Visual Companion\n(own message, no other content)" -> "Ask clarifying questions";
    "Ask clarifying questions" -> "Propose 2-3 approaches";
    "Propose 2-3 approaches" -> "Need bounded Codex design pass?";
    "Need bounded Codex design pass?" -> "Run optional Codex collaboration" [label="yes"];
    "Need bounded Codex design pass?" -> "Present design sections" [label="no"];
    "Run optional Codex collaboration" -> "Present design sections";
    "Present design sections" -> "User approves design?";
    "User approves design?" -> "Present design sections" [label="no, revise"];
    "User approves design?" -> "Write design doc" [label="yes"];
    "Write design doc" -> "Spec self-review\n(fix inline)";
    "Spec self-review\n(fix inline)" -> "Run formal\nspec-review";
    "Run formal\nspec-review" -> "Apply spec-review\nfixes";
    "Apply spec-review\nfixes" -> "Need another automatic\nspec-review pass?";
    "Need another automatic\nspec-review pass?" -> "Run formal\nspec-review" [label="yes"];
    "Need another automatic\nspec-review pass?" -> "Need optional Claude Code\nchallenge pass?" [label="no"];
    "Need optional Claude Code\nchallenge pass?" -> "Run optional Codex\nchallenge pass" [label="yes"];
    "Need optional Claude Code\nchallenge pass?" -> "User reviews spec?" [label="no"];
    "Run optional Codex\nchallenge pass" -> "Claude Code advisory passes\n< 3 and substantive changes remain?";
    "Claude Code advisory passes\n< 3 and substantive changes remain?" -> "Run optional Codex\nchallenge pass" [label="yes"];
    "Claude Code advisory passes\n< 3 and substantive changes remain?" -> "User reviews spec?" [label="no"];
    "User reviews spec?" -> "Write design doc" [label="changes requested"];
    "User reviews spec?" -> "Mark parent bead\nreviewed:spec" [label="approved"];
    "Mark parent bead\nreviewed:spec" -> "Invoke writing-plans skill";
}
```

**The terminal state is invoking writing-plans.** Do NOT invoke frontend-design, mcp-builder, or any other implementation skill. The default next skill is writing-plans.

## The Process

### Optional issue-ID entry

If `$ARGUMENTS` contains a recognized Beads issue ID:

1. Require `.beads/` and `bd`
2. Run `bd show <id> --json`
3. Fail fast if the issue cannot be loaded
4. Use the issue's title, description, labels, and dependency relationships as starting context
5. Continue the normal brainstorming flow
6. Do **not** skip clarifying questions; the issue is a seed context, not a finished spec
7. If `$ARGUMENTS` is empty or not a Beads issue ID, stay in the normal brainstorming flow.

**Understanding the idea:**

- Check out the current project state first (files, docs, recent commits)
- If brainstorming started from an issue ID, treat that issue as seed context and still ask follow-up questions until purpose, constraints, and success criteria are clear
- Before asking detailed questions, assess scope: if the request describes multiple independent subsystems (e.g., "build a platform with chat, file storage, billing, and analytics"), flag this immediately. Don't spend questions refining details of a project that needs to be decomposed first.
- If the project is too large for a single spec, help the user decompose into sub-projects: what are the independent pieces, how do they relate, what order should they be built? Then brainstorm the first sub-project through the normal design flow. Each sub-project gets its own spec → plan → implementation cycle.
- For appropriately-scoped projects, ask questions one at a time to refine the idea
- Prefer multiple choice questions when possible, but open-ended is fine too
- Only one question per message - if a topic needs more exploration, break it into multiple questions
- IMPORTANT: Use AskUserQuestion for all clarifying questions instead of plain text output. This provides structured choice UI and better UX.
- Focus on understanding: purpose, constraints, success criteria

**Exploring approaches:**

- Propose 2-3 different approaches with trade-offs
- Present options conversationally with your recommendation and reasoning
- Lead with your recommended option and explain why
- If a second design opinion would materially improve the discussion and optional Codex collaboration is available in Claude Code, you may run one bounded advisory Codex pass here before presenting your final recommendation.
- Treat Codex output as advisory input, not as the final recommendation.

## Optional Codex Collaboration (Claude Code only)

When Claude Code has `codex-plugin-cc` installed and Codex is available, you MAY use Codex as an optional sidecar during brainstorming for ideation-stage advisory work or an optional challenge pass after the mandatory written-spec independent review is already non-blocking. Do **not** use this section to redefine or weaken the mandatory written-spec independent review gate.

Codex collaboration is advisory only. Claude remains responsible for:
- user conversation
- clarifying questions
- approach recommendation
- design presentation
- design approval checkpoints
- spec writing and revision
- transition to writing-plans

Use Codex only for one bounded task at a time, such as:
- proposing additional design approaches
- pressure-testing assumptions
- identifying ambiguities, contradictions, or missing edge cases
- challenging the recommended approach
- challenging a written spec for hidden failure modes after the formal independent review gate is already non-blocking

Do NOT delegate the full brainstorming conversation to Codex.
Do NOT let Codex ask the user clarifying questions in place of Claude.
Do NOT let Codex own the final design or approval flow.
Do NOT treat Codex availability as a hard requirement.
If Codex is unavailable, continue the normal brainstorming flow without it.

Prefer `/codex:rescue --model gpt-5.4-mini --effort medium` for ideation-stage or pre-spec bounded design tasks.
Prefer `/codex:adversarial-review --model gpt-5.4-mini --effort high` only after a written spec exists, the formal independent review gate is already non-blocking, and you want a more attacking challenge review of the current design.

Claude Code invocation rules:
- For ideation-stage or pre-spec sidecar work, use `/codex:rescue` with a compact bounded task packet. Do **not** force the full `brainstorming` skill onto the Codex sidecar for these passes; ask for one bounded advisory task only.
- For written-spec challenge passes with `/codex:adversarial-review`, pass the current spec path plus the explicit challenge focus. Do **not** inject `./spec-document-reviewer-prompt.md` as the baseline rubric.
- Use `gpt-5.4-mini --effort medium` for ideation-stage bounded design passes.
- Use `gpt-5.4-mini --effort high` for adversarial challenge passes.
- Escalate to `gpt-5.4 --effort medium` only for a final high-stakes challenge pass when earlier `gpt-5.4-mini --effort high` passes still leave unresolved critical design-risk findings.

When delegating to Codex, provide a compact task packet:
- Goal
- Constraints
- Relevant existing patterns
- Current recommendation or open question
- Required output format

Explicitly instruct Codex:
- not to ask the user questions
- not to take ownership of the brainstorming flow
- not to implement or edit code
- to return bounded advisory analysis only

After Codex returns:
- extract only the useful findings
- reconcile them against the current project context
- present the integrated recommendation in Claude's own brainstorming flow
- do not outsource final judgment to Codex

**Presenting the design:**

- Once you believe you understand what you're building, present the design
- Scale each section to its complexity: a few sentences if straightforward, up to 200-300 words if nuanced
- Ask after each section whether it looks right so far
- Cover: architecture, components, data flow, error handling, testing
- Be ready to go back and clarify if something doesn't make sense

**Design for isolation and clarity:**

- Break the system into smaller units that each have one clear purpose, communicate through well-defined interfaces, and can be understood and tested independently
- For each unit, you should be able to answer: what does it do, how do you use it, and what does it depend on?
- Can someone understand what a unit does without reading its internals? Can you change the internals without breaking consumers? If not, the boundaries need work.
- Smaller, well-bounded units are also easier for you to work with - you reason better about code you can hold in context at once, and your edits are more reliable when files are focused. When a file grows large, that's often a signal that it's doing too much.

**Working in existing codebases:**

- Explore the current structure before proposing changes. Follow existing patterns.
- Where existing code has problems that affect the work (e.g., a file that's grown too large, unclear boundaries, tangled responsibilities), include targeted improvements as part of the design - the way a good developer improves code they're working in.
- Don't propose unrelated refactoring. Stay focused on what serves the current goal.

## After the Design

**Documentation:**

- Write the validated design (spec) to `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`
  - (User preferences for spec location override this default)
- Use elements-of-style:writing-clearly-and-concisely skill if available
- Commit the design document to git

**Spec Self-Review:**
After writing the spec document, look at it with fresh eyes:

1. **Placeholder scan:** Any "TBD", "TODO", incomplete sections, or vague requirements? Fix them.
2. **Internal consistency:** Do any sections contradict each other? Does the architecture match the feature descriptions?
3. **Scope check:** Is this focused enough for a single implementation plan, or does it need decomposition?
4. **Ambiguity check:** Could any requirement be interpreted two different ways? If so, pick one and make it explicit.

Fix any issues inline before moving to the formal review pass.

**Formal independent spec-review gate:**
After self-review, run a formal `spec-review` through an independent reviewer before the User Review Gate. This gate is mandatory for written specs.

Harness-specific executor:
- **Codex:** `spawn_agent` subagent (bounded, read-only)
- **Claude Code:** `/codex:rescue`

In both harnesses, instruct the independent reviewer to invoke the `spec-review` skill on the current spec path and return the formal review block. Resolve the resulting findings inline before continuing. The main agent owns the final judgment, decides what changes to apply, and remains responsible for the user-facing summary and approval flow.

Do **not** substitute this with a self-check against `spec-review/references/*`, a generic criteria read-through, or wording like "spec-review 기준으로 점검했다." The requirement is satisfied only when the transcript actually contains the formal `spec-review` output before continuing.

Completion evidence for this step:
- The user-facing transcript contains the formal `spec-review` output block, including `## Spec Review` and `Verdict:`.
- That review block came from the harness's independent-review executor, not from the main agent standing in for it.
- The main agent records what changed after that review, even if the answer is "no spec changes were needed."
- If you cannot produce that formal review output yet, you are still before the User Review Gate.

**Automatic independent spec-review loop:**
After each substantive spec edit and before the User Review Gate, re-run the harness's independent-review executor on the current spec path.

- **Codex:** prefer the `code-reviewer` agent type and use `spawn_agent` for this pass when that tool is available.
- **Claude Code:** use `/codex:rescue` for the mandatory written-spec independent review pass.
- Instruct the reviewer to invoke the `spec-review` skill on the current spec path. Do **not** inject `./spec-document-reviewer-prompt.md`.
- Do **not** ask the user whether to run this mandatory loop.
- Treat reviewer output as advisory only; the main agent remains responsible for deciding what to change and for applying revisions inline.
- Re-run the review only after **substantive spec edits** — edits that materially resolve findings, clarify requirements, tighten scope, or change implementation-planning readiness. Do not spend a pass on cosmetic wording-only changes.
- Cap the automatic loop at **3 total independent-review spec-review passes per brainstorming run**, counted cumulatively across the entire run, including any later user-requested spec revision cycles.
- Stop the loop when the latest formal verdict is non-blocking (`APPROVE` or `APPROVE_WITH_CHANGES`), or when repeated blocking findings show no substantive progress. If the cap is reached while the verdict is still blocking, surface the remaining blockers to the user instead of silently proceeding.
- If the harness's independent-review executor is unavailable or policy-blocked, state that explicitly. You may run a direct `spec-review` only as an informational degraded fallback, but do **not** mark the spec gate complete, do **not** mark `reviewed:spec`, and do **not** invoke `writing-plans` until a proper independent-review pass succeeds.

Completion evidence for this step:
- The transcript shows the actual independent-review executor result plus a completed result, unless that executor is unavailable or policy-blocked.
- If the review was performed by a sidecar or subagent, the main agent surfaces the latest formal `## Spec Review` block in the main transcript before or alongside its reconciliation summary.
- The main agent then summarizes what it adopted, deferred, or rejected from that review pass.
- If the harness's independent-review executor is available and you skipped it anyway, the spec gate has not passed.

If a written spec exists and optional Codex collaboration is available in Claude Code, you may run a bounded Codex advisory challenge pass after the formal `spec-review` gate is already non-blocking and before the User Review Gate.

- Default to **one** advisory Codex challenge pass.
- Re-run it only after **substantive spec edits** and only when material findings still remain.
- Cap it at **3 total advisory Codex challenge passes per brainstorming run**, counted cumulatively across the entire run.
- Treat Codex output as advisory only; Claude Code remains responsible for final judgment, revisions, and user-facing review flow.
- Prefer `/codex:adversarial-review --model gpt-5.4-mini --effort high` when you want a more attacking challenge pass against the written design.
- For `/codex:adversarial-review` written-spec passes, pass the current spec path plus explicit instructions to aggressively challenge hidden assumptions, contradictions, and failure modes. Do **not** inject `./spec-document-reviewer-prompt.md`.
- Escalate to `/codex:adversarial-review --model gpt-5.4 --effort medium` only for a final high-stakes challenge pass when earlier `gpt-5.4-mini --effort high` passes still leave unresolved critical design-risk findings.

Use this only when a real second-opinion challenge review would materially improve the design quality.

### Beads Integration (Post-Spec-Review)

After self-review, the formal `spec-review` gate, and any Codex challenge pass have been resolved, and before presenting the spec to the user for review,
connect the spec to the Beads issue tracker if `.beads/` directory exists in the project:

**HARD GATE:** If `.beads/` exists and `bd` is available, do not proceed to the User Review Gate until the spec is linked to a Beads **parent** issue, or the explicit open standalone issue has been promoted in place to the appropriate parent type and linked.

1. If you need to search beyond an explicit issue ID, start by collecting candidate beads with `bd list --json`.
2. Resolve the target **parent** bead in this priority order:
   - If `$ARGUMENTS` included an explicit issue ID, use that issue as the first-resolution candidate
   - A bead whose `spec-id` field matches the current spec path
   - A bead whose title/description matches the same topic
3. Do **not** attach the spec to a child issue. If the explicit issue or a matched issue has a parent, use it as context but re-resolve to the intended parent issue or ask the user.
4. If the explicit issue is `open` or `in_progress`, has no parent, and the approved design is a concretization of the same scope rather than new follow-up scope:
   - Reuse that issue as the canonical Beads identity.
   - Do **not** create a new bead just to change its type.
   - If the issue type is too narrow for the approved design, promote it in place to the appropriate parent type (usually `feature`, or `epic` when child decomposition is now expected) before linking the spec.
   - Then attach the spec to that same issue with `bd update <id> --type <type> --spec-id <path> --add-label has:spec`.
   - Re-check that both `issue_type` and `spec-id` are set correctly on that same issue.
5. If a matching parent bead exists and the same-scope in-place rule above does not apply, inspect its status first via `bd show <id> --json`.
6. If the matched parent bead status is `open` or `in_progress` → `bd update <id> --spec-id <path> --add-label has:spec`
7. Re-check that `spec-id` is set correctly on the parent bead.
8. If the explicit issue or matched parent bead status is `resolved` or `closed`, do **not** overwrite its `spec-id`.
   - Treat this as follow-up work beyond the original bead scope.
   - Ask the user whether to create a new follow-up parent bead instead.
   - If approved, create the new bead and connect it back to the original bead with `discovered-from` when possible (for example: `bd dep add <new-id> <old-id> --type discovered-from`).
   - Immediately after creation: `bd update <new-id> --spec-id <path> --add-label has:spec`
   - Re-check that `spec-id` is set correctly on the new parent bead.
9. If no match → ask user via AskUserQuestion, then create:
   - Type: `epic` if child task decomposition is expected, `feature` otherwise
   - `bd create --type <type> --title "<title>"`
   - Treat `bd create --json` output as a single issue object and extract the id from `["id"]`, not `[0]["id"]`.
   - If create-response parsing fails, do **not** run a second `bd create` immediately; first verify via an independent read path such as `bd list --json`, `bd show`, or a title/spec-id match and reuse the already-created bead when found.
   - Immediately after: `bd update <id> --spec-id <path> --add-label has:spec`
   - Re-check that `spec-id` is set correctly
10. `bd dolt push`

If `.beads/` does not exist, skip this step entirely.

**User Review Gate:**

After self-review, the formal `spec-review` gate, and any Codex challenge pass are complete, ask the user to review the written spec before proceeding.

Do **not** enter this gate unless all of the following are true:
- the spec is written to a real file path
- the latest formal `spec-review` output was actually produced
- the resulting fixes were reconciled
- any mandatory Codex automatic review pass was completed and reconciled
- any required Beads parent linkage via `spec_id` is already in place

Then ask the user:

> "Spec written and committed to `<path>`. Please review it and let me know if you want to make any changes before we proceed to the next step."

Wait for the user's response. If they request changes, make them and re-run self-review, the formal `spec-review` gate, and any applicable Codex automatic review loop. Only proceed once the user approves.

### Beads Review Gate Completion

After the user approves the written spec, the **brainstorming** flow owns the final Beads review-gate transition.

- If `.beads/` does not exist, skip this step.
- Reuse the same **parent** bead resolved in the Beads Integration step. Do **not** label a child issue.
- Add the label only after the full spec gate passes: self-review, the formal `spec-review` gate, any applicable Codex/Claude challenge loops, and user approval of the written spec.
- Apply the label with:
  - `bd update <parent-id> --add-label reviewed:spec`
  - `bd dolt push`
- If the label already exists, leave it in place.
- If substantive spec edits are made **after** `reviewed:spec` was applied, first invalidate the stale label with:
  - `bd update <parent-id> --remove-label reviewed:spec`
  - `bd dolt push`
  Then re-run the full spec gate and re-apply the label only after the updated spec passes again.
- `spec-review` itself remains review-only and does not own this label.

**Implementation:**

- Invoke the writing-plans skill to create a detailed implementation plan

## Key Principles

- **One question at a time** - Don't overwhelm with multiple questions
- **Multiple choice preferred** - Easier to answer than open-ended when possible
- **YAGNI ruthlessly** - Remove unnecessary features from all designs
- **Explore alternatives** - Always propose 2-3 approaches before settling
- **Incremental validation** - Present design, get approval before moving on
- **Be flexible** - Go back and clarify when something doesn't make sense

## Visual Companion

A browser-based companion for showing mockups, diagrams, and visual options during brainstorming. Available as a tool — not a mode. Accepting the companion means it's available for questions that benefit from visual treatment; it does NOT mean every question goes through the browser.

**Offering the companion:** When you anticipate that upcoming questions will involve visual content (mockups, layouts, diagrams), offer it once for consent:
> "Some of what we're working on might be easier to explain if I can show it to you in a web browser. I can put together mockups, diagrams, comparisons, and other visuals as we go. This feature is still new and can be token-intensive. Want to try it? (Requires opening a local URL)"

**This offer MUST be its own message.** Do not combine it with clarifying questions, context summaries, or any other content. The message should contain ONLY the offer above and nothing else. Wait for the user's response before continuing. If they decline, proceed with text-only brainstorming.

**Per-question decision:** Even after the user accepts, decide FOR EACH QUESTION whether to use the browser or the terminal. The test: **would the user understand this better by seeing it than reading it?**

- **Use the browser** for content that IS visual — mockups, wireframes, layout comparisons, architecture diagrams, side-by-side visual designs
- **Use the terminal** for content that is text — requirements questions, conceptual choices, tradeoff lists, A/B/C/D text options, scope decisions

A question about a UI topic is not automatically a visual question. "What does personality mean in this context?" is a conceptual question — use the terminal. "Which wizard layout works better?" is a visual question — use the browser.

If they agree to the companion, read the detailed guide before proceeding:
`skills/brainstorming/visual-companion.md`
