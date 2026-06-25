# Adapter — work-item: Local Markdown (offline fallback)

Active when `capabilities.tracker.tool == "local-markdown"` (no tracker MCP configured, or chosen
deliberately). `idLabel = WI`. **Always available** — this is why the tracker capability never
hard-fails and the whole pipeline can run offline.

**No tools to load** — work items are plain files under `capabilities.tracker.config.dir`
(default `.claude/pipeline/work-items/`).

**Verbs:**
| Verb | Action |
|------|--------|
| fetch | read `<dir>/{ID}.md` |
| create | write `<dir>/{slug}.md`; the slug (or a zero-padded counter) is the ID |
| update | edit the file |
| list | glob `<dir>/*.md` |

**File format:** Markdown with the same sections as the work-item template — frontmatter
(`id`, `title`, `type`, `state`) + `## Description`, `## Dependencies` (the
`| Capability | Provider | Ref |` table), `## Business Logic`, `## Acceptance Criteria`,
`## Test Strategy`.

**Degradation note:** `create` writes the finalized story here and prints the path; `dev`/`test`
read it as the work item. No network, no MCP, fully deterministic. Branch/commit use `WI-<slug>`.
