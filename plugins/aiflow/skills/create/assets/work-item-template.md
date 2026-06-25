# Work Item Template (provider-neutral)

Canonical format `/create` Phase 4 fills, then `/create` Phase 6 renders into the bound tracker's
markup (ADO HTML / Jira ADF / GitHub-Linear Markdown / local file). `dev` and `test` parse the
Dependencies table and Acceptance Criteria — keep section headers stable.

```
TITLE: <concise, action-oriented>
ORIGIN: <existing tracker id if extending, else "New">

USER STORY:
As a <user type>, I want <goal> so that <value>.

## Context & Strategy
- Objective: <why this matters>
- Target user: <who benefits>
- Success metrics: <how measured>
- Constraints: <decisions, timelines, deps>
(If no strategy docs: "Derived from description + codebase analysis.")

## Description
Happy path:
1. <user action> → <system response> → <outcome>
Scope IN:  - <included>
Scope OUT: - <explicitly excluded>
Edge cases: - <scenario> → <expected behavior>
Variants (state × environment/breakpoint): - <variant> → <expected>

## Dependencies
(Machine-readable — dev/test parse this. One row per bound capability.)

| Capability | Provider     | Ref                          |
|------------|--------------|------------------------------|
| design     | <figma/local-images/none> | <URL / path / "Not provided"> |
| docs       | <google-docs/notion/local> | <URL / path / "Not provided"> |
| business   | <doc-source> | <URL / path / "Not provided"> |
| test-cases | <doc-source> | <URL / path / "Not provided"> |
| origin     | <tracker>    | <id or "None">               |

## Business / Logic
### Inputs
| Field | Type | Range / Constraints | Default |
### Calculations / Rules
- <rule>: <plain language> `<formula/pseudocode>`
### Outputs
| Field | Format | Display / Serialization rule |
### Edge Cases
| Scenario | Expected behavior |
(If none provided: "To be derived during implementation; ASK for unspecified bounds — do not invent.")

## Acceptance Criteria
(Each binary pass/fail — testable.)
Functional:
- [ ] AC1: <testable criterion>
Standard (from feature checklist):
- [ ] <responsive/environments per profile conventions>
- [ ] <analytics/telemetry on key actions>
- [ ] <SEO/metadata or API contract, per class>
- [ ] <error states for invalid input>

## Test Strategy
Source: <test-cases ref or "Pending">
| # | Scenario | Inputs | Expected | AC |
(plus calculation-accuracy and edge-case rows where applicable)

## INVEST Check
- Independent / Negotiable / Valuable / Estimable / Small / Testable — <yes/no + justification>
```

Notes: do not hardcode framework specifics in Technical Notes — pull conventions
(import alias, breakpoints/environments, spec language) from `.claude/pipeline/profile.json`.
Reference the chosen implementation from `codebase-context/feature-catalog.md` (latest-design).
