# Test Matrix + Logical Validation

The discipline that separates "looks done" from "is done". Used by `dev` (write the matrix before
building; implement validation correctly) and `test` (execute every row, verdicts must be
empirical). Stack-agnostic — a matrix row is verified by a browser action, an HTTP call, a CLI
invocation, or a unit test, whatever the profile's `automation`/`testRunner` provides.

## 1. Write the matrix BEFORE building

Enumerate every behavioral assertion first. One row each:

| ID | Scenario | Inputs | Expected result | Trace (how it's verified) |
|----|----------|--------|-----------------|---------------------------|
| T1 | valid input accepted | age=30 | accepted, result shown | browser fill + read / API 200 / `expect(...)` |
| T2 | boundary max | age=80 | accepted | … |
| T3 | over-max rejected | age=81 | inline error "Age must be 18–80" | … |
| T4 | cap enforced | add 4th item of type X (max 3) | option disabled + no 4th added | … |

Rules:
- Cover the happy path, **every** business rule, and edge inputs: empty, zero, negative, max, max+1, wrong type, duplicate.
- **Variant state × breakpoint/environment = separate rows.** An open modal at desktop and at
  mobile are two rows with two expected results. Never infer one from the other. (For non-UI:
  each environment/config variant is its own row.)
- A medium matrix executed rigorously beats an exhaustive checklist executed lazily.

## 2. Verdicts are empirical — never declarative

A row is **PASS only** when you cite the exact trace that proved it:
- ✅ `T3 PASS — trace: typed 81 → inline text "Age must be 18–80" appeared (screenshot us-…-edge-3)`
- ❌ NOT `T3 PASS — the code has an age check` (code inspection can't catch a control-flow bypass).

Every PASS in the audit's final verdict references a matrix trace ID. No trace ⇒ not a pass.

## 3. Logical validation has no visual signature — test it by running it

Visual diffs catch UI bugs; they never catch "age 234 accepted" or "cap not enforced". For every
business rule:
- Map it to a concrete validation in code.
- Drive the real inputs (via browser/API/CLI) and observe the actual output.
- Verify duplicate-prevention fires at selection time, not just at submit.

## 4. Two-pass validation (no control-flow bypass)

Cross-unit rules must not be skippable by an early return:

```
// Pass 1 — pure aggregation, NO early returns
const counts = tally(rows)         // counts, totals, duplicates across ALL rows
const capViolations = findCaps(counts)

// Pass 2 — per-row local checks (may early-return; only affects that row)
for (const row of rows) {
  if (localInvalid(row)) { markError(row); continue }
  ...
}
```

Any aggregation computed *inside* a per-row loop that can `return`/`continue` early is a bypass
hazard — hoist it into Pass 1.

## 5. Every per-unit error needs visible, specific text

Render the actual reason inline (e.g. a `fieldError` span / an API error body / a CLI stderr
line), not just a colour/state change. "Red border, no message" = user confusion = a bug.

## 6. Hard caps need prevention + validation

For "max N of type X": once N is reached, **disable** the offending option in the UI (or reject at
the API with a clear code) so the wrong choice can't be made — *and* keep the validation as the
backstop. Prevention stops the error; validation explains it.

## 7. Ask, don't invent

If a bound/rule/placement isn't in the spec, ASK the user and record the answer (so it isn't
re-asked) — never silently choose a number or a location. A library/variants frame is not a
placement spec.
