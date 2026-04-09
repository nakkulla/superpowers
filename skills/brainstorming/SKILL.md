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
9. **Optional Codex challenge pass (Claude Code only)** — if a written spec exists and a challenge review would materially help, run one bounded Codex critique pass. Treat Codex output as advisory only.
10. **User reviews written spec** — ask user to review the spec file before proceeding
11. **Transition to implementation** — invoke writing-plans skill to create implementation plan

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
    "Need bounded Codex challenge pass?" [shape=diamond];
    "Run optional Codex challenge pass" [shape=box];
    "User reviews spec?" [shape=diamond];
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
    "Spec self-review\n(fix inline)" -> "Need bounded Codex challenge pass?";
    "Need bounded Codex challenge pass?" -> "Run optional Codex challenge pass" [label="yes"];
    "Need bounded Codex challenge pass?" -> "User reviews spec?" [label="no"];
    "Run optional Codex challenge pass" -> "User reviews spec?";
    "User reviews spec?" -> "Write design doc" [label="changes requested"];
    "User reviews spec?" -> "Invoke writing-plans skill" [label="approved"];
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

When Claude Code has `codex-plugin-cc` installed and Codex is available, you MAY use Codex as an optional sidecar during brainstorming.

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
- reviewing a written spec for hidden failure modes

Do NOT delegate the full brainstorming conversation to Codex.
Do NOT let Codex ask the user clarifying questions in place of Claude.
Do NOT let Codex own the final design or approval flow.
Do NOT treat Codex availability as a hard requirement.
If Codex is unavailable, continue the normal brainstorming flow without it.

Prefer `/codex:rescue` for ideation-stage or pre-spec bounded design tasks.
Prefer `/codex:adversarial-review` only after a written spec exists and you want a challenge review of the current design.

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

Fix any issues inline. No need to re-review — just fix and move on.

If a written spec exists and optional Codex collaboration is available in Claude Code, you may run one bounded Codex challenge pass after self-review and before the User Review Gate. Use this only when a real second-opinion challenge review would materially improve the design quality.

### Beads Integration (Post-Spec-Review)

After the spec review loop passes and before presenting the spec to the user for review,
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
   - Immediately after: `bd update <id> --spec-id <path> --add-label has:spec`
   - Re-check that `spec-id` is set correctly
10. `bd dolt push`

If `.beads/` does not exist, skip this step entirely.

**IMPORTANT: If you dispatch a spec-document-reviewer subagent using the companion prompt template, you MUST include `model: "sonnet"` in the Agent tool call parameters.**

**User Review Gate:**

After the spec review loop passes, ask the user to review the written spec before proceeding:

> "Spec written and committed to `<path>`. Please review it and let me know if you want to make any changes before we proceed to the next step."

Wait for the user's response. If they request changes, make them and re-run the spec review loop. Only proceed once the user approves.

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
