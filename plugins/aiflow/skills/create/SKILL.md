---
name: create
description: Turn a feature description into a tracked work item (story/issue/ticket) in whatever tracker this project uses. Stack- and tracker-agnostic — reads .claude/pipeline/profile.json to know which tracker/design/doc tools are bound, gathers context through them, drafts a work item from a neutral template, and creates it (Azure DevOps / Jira / Linear / GitHub / local markdown). Run /create <feature description>. Requires /setup to have run first.
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# /create — Feature description → tracked work item

`$ARGUMENTS` is a natural-language feature description. You gather available context, draft a
work item, and create it in the project's bound tracker. Nothing here names a specific provider —
all tool choices come from the profile.

## Phase 0 — Resolve profile
1. Read `.claude/pipeline/profile.json` (overlay `profile.local.json` if present). If absent:
   `> No profile found — run /setup first.` and stop.
2. Build a bindings map from `capabilities`. Print a one-line banner:
   `> tracker:<tool>(<status>) | design:<tool> | docs:<tool>`.
3. Load the matching adapters from `context.adaptersPath`: `work-item/<tracker.tool>.md`,
   `design/<design.tool>.md`, `doc-source/<docs.tool>.md`. These define the ToolSearch query, verb
   mapping, and body format you'll use.

## Phase 1 — Dependency collection (capability-driven prompts)
Prompt only for sources the profile actually binds. Generate each prompt from the bound tool:
- design `figma` → "Paste a Figma URL, `upload` a screenshot, or `skip`"; `local-images` → "Point to a design image in `<dir>` or `skip`"; `none` → don't ask.
- docs `google-docs` → "Paste a Google Doc/Sheet URL or `skip`"; `local-markdown` → "Point to a spec file or `skip`".
- tracker → "Existing `<idLabel>` item id to extend? or `skip`".
Summarize what was collected.

## Phase 2 — Fetch context (through adapters)
For each provided source, follow its adapter's ToolSearch + verbs to fetch content. Save fetched
content to `conventions.contextCachePath` (with a temp slug if no id yet) — e.g. `figma.md`,
`prfaq.md`, `business-logic.md`, `qa-cases.md`, `existing-item.md`. If `design.tool == figma`,
apply `design/figma.md` (sub-frame screenshots, asset size validation).

## Phase 3 — Read codebase context
Read `context.skillPath`'s `feature-catalog.md` to find the closest reference (latest-design
marker) and the matching `feature-checklists/<class>.md` + `common.md`. Match the feature to a
type and note standard items the description omitted (for Phase 4 gap prompts).

## Phase 4 — Draft the work item
Use `assets/work-item-template.md` (provider-neutral). Fill: title, user story, context/strategy,
description (happy path, scope in/out, edge cases), the `| Capability | Provider | Ref |`
Dependencies table (machine-readable — `dev`/`test` parse it), business/logic, acceptance criteria
(binary, testable), test strategy, INVEST check.
- For gaps from Phase 3, ASK the engineer (per `playbook` ask-don't-invent) — never invent
  constraints or placements. Record answers.
- Technical notes pull conventions from the profile (alias/breakpoints/spec language) — not
  hardcoded stack text.
Print the full draft.

## Phase 5 — Refinement loop
Ask: `> Review the draft. Give feedback to adjust, or type **confirm** to create it.` Re-draft and
re-print on any non-confirm. No tool calls here.

## Phase 6 — Create in the tracker (via adapter)
On confirm, follow `work-item/<tracker.tool>.md`:
- Load the create tool by its ToolSearch query.
- Format the body in the tracker's required markup (ADO raw HTML — never entity-escape; Jira ADF;
  GitHub/Linear Markdown).
- Create with the adapter's verb + params from `tracker.config` (org/project/type/etc.).
- **Degradation:** if `tracker.status != available` or `tool == local-markdown`, write the
  finalized item to `conventions.workItemsPath/{slug}.md` and print the path + the install command
  for the intended tracker (from settings-recs).
- Rename the temp context-cache folder to the real id. Print: `> <idLabel>-<id> created: "<title>"`.

## Phase 7 — Optional task breakdown
Ask whether to split into tasks/sub-items. If yes, propose 3–6 concrete tasks (with target
files), confirm, resolve assignee (`me`/name/skip), and create each as a child via the adapter.

## Final
Print the created id, task count, context-cache path, and: `> To implement, run /dev <id>`.

**References:** `assets/work-item-template.md`, `references/invest-criteria.md`,
`references/dependency-sources.md`; profile `context.adaptersPath` for the live adapters.
