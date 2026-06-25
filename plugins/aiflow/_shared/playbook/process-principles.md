# Build Discipline — Process Principles (stack-agnostic)

Hard-won rules distilled from many real builds. They are **process discipline**, independent of
any framework, tracker, or design tool. `dev` and `test` load this file every run. The
UI-specific rules live in `visual-diff.md` and load **only** when the profile has a design source
or a real browser (`capabilities.design != none` or a browser `automation`); everything here
applies to a Go CLI as much as a Next.js page.

Companion files: `section-build-gates.md` (the build loop), `test-matrix.md` (assertions +
verdicts), `audit-categories.md` (the audit taxonomy + output tables), `visual-diff.md` (UI-only).

---

## The non-negotiables (apply to every build)

1. **Build in sections, gated — never end-to-end.** Enumerate the regions/units first, then loop:
   build one → self-audit → fix → get explicit user "go" → next. Approval is **per section**, not
   per milestone. Full detail in `section-build-gates.md`. (Big-bang builds reliably need 2–3
   rounds of human-driven rework.)

2. **Pick the reference by comparison, not by date.** When a reference implementation guides the
   build, shortlist the top 2–3 candidates and compare them against the spec before locking one
   in. The newest is not always the closest. Building from the wrong reference causes structural
   rework. (For UI, "compare" = render + screenshot-diff; for non-UI, = read + diff against the
   contract.)

3. **Cross-check sources before enumerating work.** When listing what to build, reconcile **at
   least three** independent sources (e.g. the spec's acceptance criteria, the design/structure,
   and the existing code/route map). Small units fall between the obvious ones and are missed when
   you trust a single source.

4. **Write the Test Matrix BEFORE building.** Every behavioral assertion (business rule, edge
   case, state variant) becomes a row with an expected result and how it will be traced. A medium
   matrix rigorously executed beats an exhaustive checklist lazily executed. See `test-matrix.md`.

5. **Self-audit after every section. Max 3 cycles, then escalate.** Run the audit
   (`audit-categories.md`); if any item fails, fix all fails and re-run the **whole** audit
   (fixing one thing can break another). After 3 cycles, stop and escalate to the user instead of
   looping. NEVER ask the user "go" without printing the audit's three output tables.

6. **Verdicts are empirical, never declarative.** "The rule exists in the code" is NOT a pass.
   Every behavioral PASS must cite the exact trace (a test run, a tool call, an observed output)
   that proved it. Code inspection cannot catch control-flow shortcuts. See `test-matrix.md`.

7. **Validate logic empirically — it has no visual signature.** Visual diffs catch UI bugs; they
   never catch "age 234 accepted" or "cap of N not enforced". Map every business rule to
   validation code and test edge inputs (empty, zero, negative, max+1, boundary) by actually
   running them.

8. **Validation must not be bypassable by control flow.** Two-pass pattern: Pass 1 = pure
   cross-unit aggregation (counts, totals, duplicate detection) with **no early returns**; Pass 2
   = per-unit local checks (may early-return, since they only affect that unit). Any aggregation
   left inside a per-unit loop with early-returns is a bypass hazard.

9. **Every per-unit error needs a visible, specific message** — not just a state/colour change.
   A red border with no text leaves the user guessing. Render the actual reason inline.

10. **Hard caps need prevention, not just reaction.** For a "max N of type X" rule, disable the
    offending choice in the UI/API once the cap is reached — in addition to validating. Validation
    alone tells the user only after the wrong choice.

11. **When the spec names something the design/structure doesn't place — ASK, don't invent.** If
    an acceptance criterion mentions a feature but the design's main flow doesn't show where it
    goes (it's only in a "variants/documentation" frame, or absent), STOP and ask the user. A
    component existing in a library is not a placement spec. Inventing placement is the same class
    of bug as inventing a constraint.

11b. **Never invent soft constraints.** If a bound or rule isn't in the spec, ask — don't silently
    pick a number. Record the answer so it isn't re-asked.

12. **End every section with the three output tables.** Fix log, deferred items, final verdict.
    A pass-only verdict hides the journey and isn't auditable. Detail in `audit-categories.md`.

13. **Use the full audit taxonomy.** ~14 categories, each guarding a class of bug that has shipped
    or is likely to. Dropping categories = accepting blind spots. See `audit-categories.md`.

---

## Where each principle is enforced

| Principle | Enforced in | When |
|-----------|-------------|------|
| Section gates, reference pick, source cross-check | `section-build-gates.md` | `dev` build, every section |
| Test matrix, empirical verdicts, logic validation, two-pass, inline errors, hard caps, variant×breakpoint | `test-matrix.md` | `dev` (before/while building) + `test` |
| Audit taxonomy + 3 output tables + 3-cycle loop | `audit-categories.md` | end of every section |
| Spec-table, data-authority, literal values, parent/sibling, interactive states, carousel full-scan, asset validation | `visual-diff.md` | **only** when a design source / real browser exists |
| Ask-don't-invent | `create` + `dev` | spec-gap moments |

If a capability is absent (no design, no browser, no business logic), the corresponding discipline
is **skipped with a logged deferral** in the section's deferred-items table — never silently
dropped.
