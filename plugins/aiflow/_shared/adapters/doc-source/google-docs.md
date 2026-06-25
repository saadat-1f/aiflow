# Adapter — doc-source: Google Docs / Sheets

Active when `capabilities.docs.tool == "google-docs"`. Source of PRFAQ / specs / business-logic /
QA test cases.

**Load tools:** `ToolSearch "+google-docs readDocument"` and `"+google-docs readSpreadsheet"`.
Discover by capability.

**Verbs:**
| Verb | Tool |
|------|------|
| read doc | `readDocument` (PRFAQ, strategy) → extract problem, solution, metrics, segments, constraints |
| read sheet | `readSpreadsheet` (business logic, QA cases) → extract rules/formulas/thresholds; QA scenarios with inputs + expected |

**Caching:** save fetched content to `conventions.contextCachePath` so downstream skills don't
re-fetch (e.g. `prfaq.md`, `business-logic.md`, `qa-test-cases.md`).

**Auth:** via `GOOGLE_CLIENT_ID`/`GOOGLE_CLIENT_SECRET` env (per `requiredEnv`); never in the repo.
