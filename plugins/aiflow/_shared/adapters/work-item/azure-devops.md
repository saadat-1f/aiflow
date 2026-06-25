# Adapter — work-item: Azure DevOps

Active when `capabilities.tracker.tool == "azureDevOps"`. `idLabel = ADO`.

**Load tools:** `ToolSearch "+azureDevOps work_item"` (also `select:mcp__azureDevOps__create_work_item`, `select:mcp__azureDevOps__get_me` as needed). Never hardcode the literal tool name — discover by capability (names change under a plugin namespace).

**Config (from `capabilities.tracker.config`):** `organizationId`, `projectId`, `storyType` (e.g. "User Story"), `taskType` (e.g. "Task").

**Verbs:**
| Verb | Tool + params |
|------|---------------|
| fetch | `get_work_item` with the numeric id |
| create story | `create_work_item` { workItemType: `<storyType>`, title, description (HTML), projectId, organizationId, parentId? } |
| create task | `create_work_item` { workItemType: `<taskType>`, …, parentId: story id, assignedTo? } |
| resolve assignee | `get_me` → email for "me" |

**Body format — RAW HTML (critical quirk):** the `description` and `AcceptanceCriteria` fields must contain **literal** `<p>`, `<strong>`, `<h3>`, `<ul>`, `<li>` tags. **Never** entity-escape (`&lt;p&gt;`) — Azure renders escaped HTML as literal text. Self-check before the API call: if the string contains `&lt;` or `&gt;`, fix it. Do not wrap in code fences.

**ID parsing:** numeric. Branch/commit tokens use `ADO-<id>` via `conventions.branchPattern`/`commitPrefix`.
