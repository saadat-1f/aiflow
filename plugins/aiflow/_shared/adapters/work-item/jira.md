# Adapter — work-item: Jira

Active when `capabilities.tracker.tool == "jira"`. `idLabel = JIRA`.

**Load tools:** `ToolSearch "+jira issue"` (Atlassian MCP). Discover by capability.

**Config (from `capabilities.tracker.config`):** `site`, `projectKey`, `issueType` (e.g. "Story").

**Verbs:**
| Verb | Tool + params |
|------|---------------|
| fetch | get issue by key (e.g. `PROJ-123`) |
| create story | create issue { project: `<projectKey>`, issuetype: `<issueType>`, summary, description } |
| create subtask | create issue { issuetype: "Sub-task", parent: `<key>`, … } |
| transition | transition issue (To Do → In Progress → Done) |

**Body format:** Atlassian Document Format (ADF) or wiki markup, per the server. Structure the
description with headings (Description, Acceptance Criteria, Technical Notes, Sources) — same
sections as the work-item template, expressed in the tracker's markup.

**ID parsing:** `PROJ-<n>` (project key + number). Branch/commit use the full key.
