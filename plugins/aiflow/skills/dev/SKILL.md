---
name: dev
description: Implement a tracked work item, stack-agnostically, with disciplined section-by-section gated builds. Reads .claude/pipeline/profile.json to resolve the tracker/design/runtime/vcs bindings and the build conventions, then fetches the item, produces a Dev Brief, and implements section by section with a self-audit at each gate. Run /dev <work-item-id>. Requires /setup first.
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# /dev — Work item → implementation

`$ARGUMENTS` is a work-item id in the bound tracker's format (numeric for ADO, `PROJ-n` for Jira,
`#n` for GitHub, a slug/path for local-markdown). You implement it following the build discipline.

## Phase 0 — Resolve profile
1. Read `.claude/pipeline/profile.json` (+ `profile.local.json`). If absent: `> No profile found — run /setup first.` stop.
2. Build the bindings map; print a banner: `> tracker:<…> | design:<…> | runtime:<url> | automation:<…> | vcs:<host>`.
3. Load adapters from `context.adaptersPath`: `work-item/<tracker>`, `design/<design>`,
   `doc-source/<docs>`, `vcs/git.md`. Load the playbook from `context.playbookPath`:
   `process-principles.md`, `section-build-gates.md`, `test-matrix.md`, `audit-categories.md`, and
   `visual-diff.md` **only if** `design != none`.

## Phase 1 — Fetch work item (via tracker adapter)
Validate the id matches the tracker format. Load the fetch tool by the adapter's ToolSearch query;
fetch the item. Extract title, type, state, description, acceptance criteria, and **all URLs**.
Parse the machine-readable Dependencies table (`| Capability | Provider | Ref |`) if `create`
authored it. **Key principle: never re-fetch what's cached.**

## Phase 2 — Load feature context
If `conventions.contextCachePath` (id-substituted) exists, read the cached files (design, prfaq,
business-logic, qa-cases) — do not re-fetch. Otherwise fetch the URLs from the Dependencies table
through the bound `design`/`doc-source` adapters and cache them. If `design != none` and no design
reference is available, prompt for one or proceed with a logged deferral.

## Phase 3 — Read codebase context
From `context.skillPath`: read `feature-catalog.md` → identify feature type + the latest-design
reference; read the matching `feature-checklists/<class>.md` + `common.md`; read
`architecture.md`/`coding-standards.md`/`component-catalog.md`/`design-system.md`/`surface-map.md`
on demand. Apply `section-build-gates.md` Step 2 (compare-then-pick the reference).

## Phase 4 — Dev Brief
Fill `assets/dev-brief-template.md` from Phases 1–3: what to build, context sources, acceptance
criteria, business logic, design (if bound), and an implementation plan whose file structure comes
from the profile conventions + scanRoots (not hardcoded paths). Print it. Ask:
`> Ready? Type **go**, or give feedback.` Do not proceed until confirmed.

## Phase 5 — Implementation (gated, section by section)
This phase IS `playbook/section-build-gates.md`. For the whole feature:
1. **Branch** via `vcs/git.md`: `conventions.branchPattern` (e.g. `feature/ADO-<id>`).
2. **Enumerate units** (3-source cross-check). Then, per unit:
   - Build it (reuse catalog components; follow coding-standards; `source` alias etc. from conventions).
   - If `design != none`: apply `visual-diff.md` (spec table, literal values, parent/sibling nesting).
   - Implement business rules with the **two-pass** pattern + inline errors + hard-cap UI prevention (`test-matrix.md`).
   - Run the **self-audit** (`audit-categories.md`), max 3 cycles, then print the **three tables** and ask for "go".
3. **Commit** atomically with `conventions.commitPrefix` before/after each unit.
After all units: print the quality verdict and `> Branch <branch> ready. To validate, run /test <id>.`

## Degradation
No design → build from reference + `design-system.md`, mark visual categories SKIP (deferred). No
business-logic doc → derive from description, flag assumptions, ASK for unspecified bounds. No
tracker → accept a pasted spec / `conventions.workItemsPath/<id>.md` as the work item.

**References:** `assets/dev-brief-template.md`; profile `context.playbookPath` + `adaptersPath`.
