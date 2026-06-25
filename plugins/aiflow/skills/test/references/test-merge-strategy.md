# Test Merge Strategy (provider-neutral)

How `/test` Phase 3 merges three sources into one Test Matrix (`playbook/test-matrix.md`). Sources
are tool-neutral: acceptance criteria from the bound tracker, test cases from the bound doc source,
checklist items from `codebase-context`.

## Three inputs
| Source | Origin | Contains |
|--------|--------|----------|
| Acceptance Criteria | tracker work item | high-level pass/fail the item promises |
| Test cases | doc source (sheet/doc/file) | detailed scenarios with inputs + expected |
| Feature checklist | `codebase-context/feature-checklists/<class>.md` + `common.md` | standard items for this feature type |

## Steps
1. **Parse AC** → number each `AC1..ACn`; preserve any Functional/Standard grouping.
2. **Parse cases** → match columns by header (id / scenario / inputs / expected); detect section
   headers → test type; default to Functional. Skip empties; preserve multi-line steps.
3. **Parse checklist** → extract every `- [ ]`; map its category heading to a test type; keep the
   (follow)/(verify) recency tag.
4. **Map cases → AC** (keyword + domain overlap): strong (≥3 shared keywords or AC ⊂ scenario) →
   map; partial (2 + same type) → map with note; none → standalone. One case maps to at most one
   AC; one AC may own many cases. Print the mapping for review.
5. **Dedupe** across sources, preferring the most specific: case (has inputs+expected) > AC > checklist.
   Keep the loser's label for traceability (`Source: case + AC2`).
6. **Group** into: Functional · Logic/Data-accuracy · UI/UX · Responsive/Environments · Content/Contract ·
   Edge cases · (Compatibility/Performance if cases specify). Skip empty groups.
7. **Write the matrix** — one row per surviving item: ID | scenario | inputs | expected | trace.
   Variant-state × breakpoint/environment = separate rows (`playbook/test-matrix.md`).

## Special cases
- No cases → build from AC + checklist; note reduced coverage.
- No AC → derive testable statements from the description (label `AC (derived)`).
- Logic rows without a business-logic source → verify by running, against the cases' expected
  values; do not invent expected values.
