# Profile Schema — `.claude/pipeline/profile.json`

The profile is the **single committed source of truth** for how the create → dev → test
pipeline runs in this project. It is written by `/setup`, committed to version control, and
read (never re-decided) by every other skill. Two developers on the same commit must see the
same profile, so the file is **canonical**: keys sorted, arrays in fixed order, no
timestamps/usernames/paths-that-vary, two-space indent, trailing newline.

`schemaVersion` lets the skill evolve without invalidating old profiles.

---

## Top-level shape (`schemaVersion: 1`)

```json
{
  "schemaVersion": 1,
  "generatedBy": "setup@1.0.0",
  "detection": { ... },
  "conventions": { ... },
  "capabilities": { ... },
  "context": { ... },
  "settingsApplied": { ... }
}
```

`generatedAt` is intentionally **absent** — a timestamp would break byte-identical re-emission.
If a human wants provenance, that belongs in the git commit, not the file.

---

## `detection` — what the project IS (pure function of repo files)

```json
"detection": {
  "projectClass": "web-next",
  "candidates": ["web-next", "backend-node"],
  "markersMatched": ["package.json:next", "package.json:express"],
  "signals": { "next": "14.2.32", "react": "18.2.0", "packageManager": "npm" },
  "subProjects": []
}
```

- `projectClass` — the single winning class from `detection-rules.md` (first matching row).
- `candidates` — every row that matched, in table order. Lets anyone audit the decision.
- `markersMatched` — `file:signal` evidence strings proving the classification.
- `signals` — literal versions/values read from manifests (advisory; never branch detection on these).
- `subProjects[]` — for `monorepo`, one entry per workspace dir: `{ "path": "apps/web", "projectClass": "web-next", "...": "..." }` (each carries its own `conventions`/`capabilities`).

## `conventions` — derived constants the old skills used to hardcode

```json
"conventions": {
  "contextCachePath": ".claude/pipeline/context-cache/{ID}",
  "workItemsPath": ".claude/pipeline/work-items",
  "reportsPath": ".claude/pipeline/reports",
  "branchPattern": "feature/{TRACKER}-{ID}",
  "commitPrefix": "{TRACKER}-{ID}: ",
  "specLanguage": "javascript",
  "specDir": "tests",
  "specExt": "spec.js",
  "breakpoints": [1200, 992, 540],
  "sourceImportAlias": "source/*"
}
```

Substitution tokens: `{ID}` = work-item id, `{TRACKER}` = `capabilities.tracker.config.idLabel`
(e.g. `ADO`, `JIRA`, `GH`). Fields that don't apply to a stack are omitted (a backend has no
`breakpoints`). Skills read these instead of literals — this is how `localhost:3000`,
`feature/ADO-{ID}`, JS-vs-TS, `source/*`, and `1200/992/540` stop being hardcoded.

## `capabilities` — the binding for each pipeline role

Each capability is resolved once by `/setup` and recorded here. Downstream skills branch on
`tool` + `status`; they never re-rank.

```json
"capabilities": {
  "tracker":    { "tool": "azureDevOps", "kind": "mcp",     "status": "available",
                  "boundFrom": "existing-mcp", "requiredEnv": ["AZURE_DEVOPS_PAT"],
                  "config": { "organizationId": "1Finance", "projectId": "1 Finance Website2.0",
                              "storyType": "User Story", "taskType": "Task", "idLabel": "ADO" },
                  "alternatives": [] },
  "design":     { "tool": "figma",      "kind": "mcp",     "status": "available",
                  "boundFrom": "existing-mcp", "requiredEnv": [], "config": {} },
  "docs":       { "tool": "google-docs","kind": "mcp",     "status": "available",
                  "boundFrom": "existing-mcp", "requiredEnv": ["GOOGLE_CLIENT_ID","GOOGLE_CLIENT_SECRET"], "config": {} },
  "runtime":    { "tool": "dev-server", "kind": "command", "status": "available",
                  "config": { "command": "npm run dev", "url": "http://localhost:3000" } },
  "automation": { "tool": "playwright", "kind": "mcp",     "status": "available",
                  "boundFrom": "existing-mcp", "config": { "specDir": "tests", "specExt": "spec.js" } },
  "testRunner": { "tool": "playwright-test", "kind": "command", "status": "available",
                  "config": { "command": "npx playwright test" } },
  "vcs":        { "tool": "git",        "kind": "builtin", "status": "available",
                  "config": { "remoteHost": "azure-repos" } }
}
```

Field meanings:
- `tool` — the bound provider id (must be one of the values listed in `capability-map.md`).
- `kind` — `mcp` | `command` | `builtin` | `local`. Tells the consuming skill HOW to invoke it.
- `status` — `available` (usable now) | `unavailable` (decided tool not configured on this machine) | `needs-secret` (configured but a `requiredEnv` var is unset). Only `status` may differ between developers; `tool` may not.
- `boundFrom` — `existing-mcp` | `existing-config` | `rule` — provenance of the decision.
- `requiredEnv[]` — names of env vars the tool needs (never values). Drives `.env.example`.
- `config` — per-tool parameters (the old hardcoded ADO org/project, Playwright spec dir/ext, runtime url, etc.).
- `alternatives[]` — other configured tools that could have filled this role (recorded for transparency; not used).

## `context` — where the codebase-context library + playbook live

```json
"context": {
  "skillPath": ".claude/skills/codebase-context",
  "playbookPath": ".claude/skills/_shared/playbook",
  "adaptersPath": ".claude/skills/_shared/adapters",
  "referenceDocs": ["architecture","coding-standards","component-catalog","design-system","surface-map","feature-catalog"],
  "checklists": ["common","page","form"],
  "scanRoots": { "surfaces": ["pages"], "modules": ["source/modules"], "components": ["source/modules/components"] },
  "surfaceNoun": "route"
}
```

`scanRoots` + `surfaceNoun` are what make the agnostic `regenerate.sh` work for any stack
(`route`/`endpoint`/`screen`/`command`). When promoted to a plugin, the three `*Path` fields are
replaced at read-time by `${CLAUDE_PLUGIN_ROOT}/...`; in-repo they are literal paths so no skill
hardcodes a sibling location.

## `settingsApplied` — audit of additive settings writes

```json
"settingsApplied": {
  "permissionsAdded": ["Bash(npm run dev:*)", "Bash(npx playwright test:*)"],
  "fingerprint": "sha256:<hash of the exact permission set written>"
}
```

`fingerprint` lets `/setup --check` detect manual edits to `settings.json`.

---

## Per-developer overrides — `.claude/pipeline/profile.local.json` (gitignored)

A shallow-merge layer applied at READ time. It may set **environment values only** — never a
binding identity. Schema-enforced allowlist of keys: `capabilities.<cap>.config.url`,
`capabilities.<cap>.config.command`, and `capabilities.<cap>.status`. Any attempt to override
`tool`/`kind`/`boundFrom` is ignored (and `/setup --check` warns). This keeps shared decisions
identical while letting one dev point at a personal staging URL or mark a tool available locally.

---

## Determinism guarantees this schema enforces
1. **No volatile fields** in the committed file (no `generatedAt`, no absolute paths, no usernames).
2. **Canonical serialization** — sorted keys + fixed array order ⇒ byte-identical re-emission ⇒ empty `git diff` on a no-op re-run.
3. **Availability quarantined** — only `status` (and the local-override layer) may vary by machine; `tool`/`kind`/`config` are shared.
4. **Auditable** — `markersMatched` + `candidates` + `boundFrom` let any developer reproduce and verify every decision from the repo alone.
