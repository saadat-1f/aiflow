# Dependency Sources

The capability roles `/create` gathers context from, and how each is fetched. The concrete
provider for each comes from `.claude/pipeline/profile.json`; the mechanics live in the bound
adapter under `context.adaptersPath`.

| Capability | Profile key | Bound provider examples | Fetched via adapter | Cached as |
|------------|-------------|-------------------------|---------------------|-----------|
| Design | `design` | figma · local-images · none | `design/<tool>.md` | `figma.md` / image refs |
| Product spec / strategy | `docs` | google-docs · notion · confluence · local | `doc-source/<tool>.md` | `prfaq.md`, `strategy.md` |
| Business logic / rules | `docs` | (a sheet/doc/file) | `doc-source/<tool>.md` | `business-logic.md` |
| Test cases | `docs` | (a sheet/doc/file) | `doc-source/<tool>.md` | `qa-cases.md` |
| Existing/origin item | `tracker` | azureDevOps · jira · linear · github · local | `work-item/<tool>.md` | `existing-item.md` |

Rules:
- Prompt only for capabilities the profile actually binds; generate the prompt wording from the bound tool.
- Save everything to `conventions.contextCachePath` so `dev`/`test` never re-fetch.
- If a needed source is `none`/unavailable, proceed and log the gap; ASK the engineer for any
  rule/bound the description leaves unspecified — never invent one.
