---
name: test
description: Validate a work item's acceptance criteria empirically, stack-agnostically. Reads .claude/pipeline/profile.json to resolve the tracker and the automation binding (browser via Playwright, or the project's own test runner / HTTP client for backend/CLI/mobile), builds a Test Matrix, executes every row, generates a spec in the project's language, and reports with the mandatory audit tables. Run /test <work-item-id>. Requires /setup first.
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# /test — Validate a work item (empirically)

`$ARGUMENTS` is a work-item id in the tracker's format. You verify each acceptance criterion by
actually exercising the built software — never by code inspection.

## Phase 0 — Resolve profile
1. Read `.claude/pipeline/profile.json` (+ `profile.local.json`). If absent: `> No profile found — run /setup first.` stop.
2. Banner: `> tracker:<…> | automation:<tool> | runtime:<url> | testRunner:<framework>`.
3. Load adapters from `context.adaptersPath`: `work-item/<tracker>`, `browser-test/<automation.tool or project-test-runner>`. Load playbook `test-matrix.md` + `audit-categories.md`, and `visual-diff.md` only if a design source / browser is bound.
**Do NOT modify source code in Phases 1–6; this is read-only/test-only. Phase 7 may update checklists.**

## Phase 1 — Fetch acceptance criteria (via tracker adapter)
Load the fetch tool by the adapter's query; fetch the item; parse acceptance criteria into a
numbered list, plus any Technical Notes / Test Strategy / Dependencies table.

## Phase 2 — Load test context
From `conventions.contextCachePath` read cached `qa-cases`, `business-logic`, design specs if
present (else fetch via the bound doc/design adapter). Identify feature type and read the matching
`feature-checklists/<class>.md` + `common.md` from `context.skillPath`.

## Phase 3 — Unified test plan + Test Matrix
Per `playbook/test-matrix.md`: merge acceptance criteria + cases + checklist into one plan, dedupe,
map cases→AC, and write the **Test Matrix** (ID | scenario | inputs | expected | trace) BEFORE
executing. Variant-state × breakpoint/environment = separate rows. Present it; wait for
`> go` (or `go on <url>` to override `runtime.url`).

## Phase 4 — Execute (via automation adapter)
- **`browser-test/playwright.md`** (web): load Playwright MCP by query; navigate to
  `runtime.url`; for each matrix row drive the real UI, observe, screenshot as evidence; apply
  `visual-diff.md` for UI/interactive-state rows.
- **`browser-test/project-test-runner.md`** (backend/CLI/library/mobile): run
  `testRunner.command` / drive endpoints with an HTTP client against `runtime.url` / invoke the
  binary; assert per row.
Print PASS/FAIL per row with the **trace** that proves it (empirical — never "the code has it").

## Phase 5 — Generate spec
Emit one test per matrix row, grouped by category, in `conventions.specLanguage` to
`conventions.specDir/<id-file>.conventions.specExt` (web → Playwright spec; else the project's
native framework). Use the adapter's selector/wait guidance; relative navigation with baseURL from
config. Stack-specific waits/selectors come from the project's generated `test-patterns`, not from
this skill.

## Phase 6 — Report (with the three audit tables)
Fill `assets/report-template.md`: metadata, results by group, summary. End with the mandatory
`audit-categories.md` output — **fix log, deferred items, final verdict** (each behavioral PASS
cites a matrix trace id; UI categories SKIP-with-reason for non-UI projects).

## Phase 7 — Self-learning
Diff built code vs the feature checklist; propose new checklist items found in the implementation;
on approval append them (marked **(follow)**) to `context.skillPath`'s checklists. This is the
only phase that writes outside reports.

## Phase 8 — Save
Save the report to `conventions.reportsPath/<id>-test-report.md`. Print the result, spec path,
report path, and re-run commands.

**References:** `references/test-merge-strategy.md`, `references/test-patterns.md`,
`assets/report-template.md`; profile `context.playbookPath` + `adaptersPath`.
