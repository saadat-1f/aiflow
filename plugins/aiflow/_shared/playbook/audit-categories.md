# Audit Categories + Output Tables

The structured self-audit run at the end of **every** section (`section-build-gates.md` Step 4)
and as the backbone of `test`'s report. Fewer categories = blind spots — each guards a class of
bug that has shipped or is likely to. Categories that need an absent capability are marked
**SKIP (capability unavailable)**, never silently dropped.

## The 14 categories

| # | Category | Checks | Needs |
|---|----------|--------|-------|
| A | **Inventory** | Every enumerated unit built; nothing dropped from the 3-source cross-check | — |
| B | **Structure** | Files/modules in the right place; conventions followed; reuse over re-create | — |
| C | **Visual** | Matches the design spec table property-by-property (see `visual-diff.md`) | design source |
| D | **Hygiene** | No debug logs/PII; analytics fire once per intent (not per render); correct event names; no dead code; correct imports/alias; effect deps/cleanup correct | — |
| E | **Interactive states** | Every dropdown/radio/accordion/modal/error/hover screenshotted in its non-resting state and diffed (see `visual-diff.md`) | design + browser |
| F | **Responsive / environments** | Each breakpoint (or runtime environment) verified as its own matrix row | browser (UI) |
| G | **Accessibility** | Roles/labels/focus order/keyboard nav/contrast | UI |
| H | **Console / logs** | No errors or warnings at runtime | runtime |
| I | **Cross-section** | Consistent with sibling sections; shared state/nav intact | — |
| J | **Logical** | Every business rule mapped + empirically traced; two-pass validation; inline errors; hard-cap UI prevention; edge inputs tested (see `test-matrix.md`) | — |
| K | **Performance** | No layout shift; reasonable payloads; no obvious N+1 / blocking work | — |
| L | **Motion** | Transitions/animations settle; no jank; respects reduced-motion | UI |
| M | **Privacy / security / forms** | No secrets/PII leaked to client/logs/analytics; inputs sanitized; auth respected | — |
| N | **Journey / edge UI** | Empty/loading/error states; back/refresh/deep-link; full user journey holds | — |

UI-gated categories (C, E, F, G, L and the UI parts of N) are SKIPPED with reason for non-UI
projects. J, A, B, D, H, I, K, M always apply.

## The three mandatory output tables

Print all three at the end of every section — a pass-only verdict hides the journey and isn't
auditable.

### 1. Fix log
| Cycle | Category/Item | What failed | Fix applied | Status |
|-------|---------------|-------------|-------------|--------|
| 1 | J3 | age 81 accepted | added max bound + inline error | ✅ fixed |

### 2. Deferred items
| Item | Why deferred | Re-check when |
|------|--------------|---------------|
| C visual diff | no design source bound | a design is provided |

### 3. Final verdict
| Cat | Result | Evidence |
|-----|--------|----------|
| A | PASS | all 6 enumerated units present |
| C | SKIP | no design source (capability unavailable) |
| J | PASS | traces T1–T7 (see matrix) |

Every behavioral PASS cites a `test-matrix.md` trace ID. "Rule exists in code" is not a PASS.

## The audit loop
Run the audit → if any FAIL, fix all → re-run the **whole** audit → repeat max **3 cycles** →
escalate to the user if still failing. Only after a clean (or knowingly-deferred) verdict do you
print the tables and ask for "go".
