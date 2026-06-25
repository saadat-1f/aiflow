# Section Build Gates

How `dev` builds: one section at a time, each gated by a self-audit and an explicit user "go".
Applies to any unit of work — a UI section, an API endpoint, a CLI subcommand, a module.

## Step 1 — Enumerate units (cross-checked)

Before writing code, list every unit to build, reconciling **three** sources so nothing falls
through the cracks:
1. The spec / acceptance criteria (what's promised).
2. The design or structural reference (how it's shaped) — for UI, the design frames; for backend,
   the API contract / data model; for CLI, the command surface.
3. The existing codebase (route/endpoint/screen map + reference implementation).

Print the enumerated unit list. Each unit is a gate.

## Step 2 — Pick the reference implementation by comparison

If a reference implementation will guide the build, shortlist the top 2–3 candidates (from
`codebase-context`'s `feature-catalog.md` latest-design markers) and compare each against the
spec before locking one in — newest ≠ closest. For UI, render + screenshot-diff the candidates;
for non-UI, read them and diff against the contract. Record the chosen reference + the one-line
reason.

## Step 3 — Build one unit

Implement a single unit. Reuse existing components/modules from the catalog before creating new
ones. Follow the codebase conventions (`coding-standards.md`). If a design source exists, apply
`visual-diff.md` (spec table, literal values, parent/sibling nesting). If business rules apply,
implement them with the two-pass validation pattern (`test-matrix.md`).

## Step 4 — Self-audit (max 3 cycles)

Run the audit from `audit-categories.md` against this unit. If any item fails:
- Fix **all** fails.
- Re-run the **entire** audit (a fix can regress another category).
- Repeat up to **3 cycles**. If still failing after 3, STOP and escalate to the user with the open
  items — do not loop indefinitely.

## Step 5 — Print the three tables, then gate

NEVER ask for "go" without printing (from `audit-categories.md`):
1. **Fix log** — Cycle | Item | What failed | Fix applied | Status
2. **Deferred items** — Item | Why deferred | Re-check when
3. **Final verdict** — the category checklist with PASS / FAIL / SKIP-with-reason

Then ask: `> Section <name> complete. Review the tables above and type "go" for the next section, or give feedback.` Wait for the user. Do not advance on your own.

## Degradation
If a capability needed for a unit is unavailable (no design source, no browser, no business-logic
doc), build what you can, mark the dependent audit categories **SKIP (capability unavailable)** in
the verdict, and add a row to the deferred-items table. Never silently skip.

## Why gated, not big-bang
Across past runs, building a whole page/feature before showing the user repeatedly produced work
that needed 2–3 rounds of human-driven fixes. Per-section gates catch drift while it's one
section wide, not a whole feature wide.
