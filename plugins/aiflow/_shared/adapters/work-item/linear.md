# Adapter — work-item: Linear

Active when `capabilities.tracker.tool == "linear"`. `idLabel = LIN`.

**Load tools:** `ToolSearch "+linear issue"`. Discover by capability.

**Config (from `capabilities.tracker.config`):** `teamId`.

**Verbs:**
| Verb | Tool + params |
|------|---------------|
| fetch | get issue by id/identifier (e.g. `ENG-123`) |
| create | create issue { teamId, title, description } |
| sub-issue | create issue with `parentId` |
| update state | set workflow state |

**Body format:** Markdown (Linear renders GitHub-flavored Markdown). Use the same section
structure as the work-item template (## Description, ## Acceptance Criteria, …).

**ID parsing:** team identifier + number (e.g. `ENG-123`). Branch/commit use the identifier.
