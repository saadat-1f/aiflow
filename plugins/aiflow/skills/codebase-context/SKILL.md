---
name: codebase-context
description: Stack-agnostic codebase reference library for the create → dev → test pipeline. Pre-generated docs (architecture, conventions, module/component catalog, surface map, feature catalog, checklists) so the pipeline skills make informed decisions without re-scanning. Background knowledge — not user-invoked. Regenerated per project from the profile via scripts/regenerate.sh.
user-invocable: false
---

# Codebase Context (agnostic)

Pre-built reference documentation extracted from THIS project's code, so `create`, `dev`, and
`test` reason from a stable map instead of re-scanning every run. Unlike the stack-specific
`1f-codebase-context`, this version is **profile-driven**: the doc set, scan roots, and the noun
for "surfaces" all come from `.claude/pipeline/profile.json`, so the same library shape works for
web, backend, mobile, CLI, or library projects.

## Doc set (fixed filenames; content adapts to `detection.projectClass`)

| File | Purpose | Notes by class |
|------|---------|----------------|
| `references/architecture.md` | structure, build config, entrypoints, dependency graph | every class |
| `references/coding-standards.md` | conventions derived from actual code | every class |
| `references/component-catalog.md` | reusable units | "Component Catalog" (UI) / "Module Catalog" (backend) / "Package Catalog" (library) |
| `references/design-system.md` | tokens/typography/spacing | UI classes only; else a one-line "N/A — no UI layer" |
| `references/surface-map.md` | the app's surfaces | routes (web) / endpoints (backend) / screens (mobile) / commands (CLI) per `surfaceNoun` |
| `references/feature-catalog.md` | features with type, domain, last-git-date, ✅ latest-design marker | every class |
| `references/feature-checklists/common.md` | cross-cutting patterns | always |
| `references/feature-checklists/<class>.md` | class-specific patterns | web → `page.md`,`form.md`; backend → `endpoint.md`,`job.md`; mobile → `screen.md`,`flow.md` |

Filenames are stable so consuming skills can reference them by name; only the **content** varies
by stack. The ✅-latest-design marker (newest implementation per feature type, by `git log` date)
is stack-neutral and preserved.

## How consuming skills read this

The pipeline skills resolve `context.skillPath` from the profile (this dir in-repo;
`${CLAUDE_PLUGIN_ROOT}/skills/codebase-context` as a plugin) and read:
1. `feature-catalog.md` first — find the closest reference (latest-design marker).
2. the matching `feature-checklists/<class>.md` + `common.md`.
3. `architecture.md`, `coding-standards.md`, `component-catalog.md`, `design-system.md`,
   `surface-map.md` on demand.

## Regenerate

```bash
bash .claude/skills/codebase-context/scripts/regenerate.sh          # all docs
bash .claude/skills/codebase-context/scripts/regenerate.sh architecture   # one doc
```

The script reads the profile for `scanRoots`, `surfaceNoun`, `projectClass`, and the references
dir, then runs `claude -p` with **stack-neutral prompts parameterized by the detected class** (see
`references/doc-types.md`). It requires the `claude` CLI and `jq`. Run it after `/setup`, after a
new feature type ships, or when a reference doc gives outdated guidance.

## Freshness
Patterns marked **(follow)** come from the latest implementations and are safe to replicate;
**(verify)** patterns come from older code and should be checked first. `feature-catalog.md`'s
quick-reference table shows the best reference per feature type with its last-modified date.

Treat regenerated docs like a reviewed generated artifact (e.g. a lockfile): the scan roots and
prompts are deterministic (profile-driven), but `claude -p` output is reviewed before commit.
