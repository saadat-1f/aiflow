# Adapter — doc-source: Local files (fallback)

Active when `capabilities.docs.tool == "local-markdown"` (no doc MCP configured). Specs live in
the repo (e.g. `docs/`, `specs/`).

**No tools to load** — read local files with Read/Glob/Grep.

**Verbs:**
| Verb | Action |
|------|--------|
| read spec | read the markdown/text file the developer points to (or glob a `docs/`/`specs/` dir) |
| business logic | read a local rules/spec file or a CSV |

**Caching:** copy/reference into `conventions.contextCachePath` for downstream skills.

**Degradation:** if no doc source and none provided, proceed from the work-item description alone
and note the gap in the audit's deferred-items table. ASK the developer for any rule/bound the
description doesn't specify — never invent.
