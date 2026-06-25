# Adapter — work-item: GitHub Issues

Active when `capabilities.tracker.tool == "github-issues"`. `idLabel = GH`.

**Load tools:** prefer the GitHub MCP (`ToolSearch "+github issue"`); fallback to the `gh` CLI
(no MCP needed) — `gh issue view <n>`, `gh issue create`, `gh issue edit`.

**Config (from `capabilities.tracker.config`):** `repo` (`owner/name`).

**Verbs:**
| Verb | MCP / CLI |
|------|-----------|
| fetch | get issue `#<n>` / `gh issue view <n> --json title,body,labels` |
| create | create issue { title, body, labels } / `gh issue create --title … --body …` |
| link sub-tasks | task-list checkboxes in the body (GitHub has no native sub-issue) |

**Body format:** GitHub-Flavored Markdown. Use `## Description`, `## Acceptance Criteria`
(checkbox list `- [ ]`), `## Technical Notes`, `## Sources`.

**ID parsing:** `#<n>` or `owner/repo#<n>`. Branch/commit use `GH-<n>`.
