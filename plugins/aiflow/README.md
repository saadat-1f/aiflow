# aiflow

A **deterministic, stack-agnostic** spec → build → validate pipeline for Claude Code.

`/setup` detects your project and wires the best-suited tools/MCP into a **committed profile**, so
every developer on the same commit gets the identical setup. Then `create → dev → test` run
section-by-section with a shared **build-discipline playbook** (gated builds, write-the-test-matrix-first,
empirical/traced audit verdicts, two-pass validation, a 14-category audit).

Works on **web, backend, mobile, CLI, or library** projects, across **Azure DevOps / Jira / Linear /
GitHub** issues, **Figma** or local designs, and **Playwright** or your project's own test runner.

## Commands

| Command | What it does |
|---|---|
| `/aiflow:setup` | Detect the project, bind capabilities → tools/MCP, write `.claude/pipeline/profile.json`. Run once per repo. (`--check` / `--reconcile` for drift.) |
| `/aiflow:create <description>` | Turn a feature description into a tracked work item (in your bound tracker). |
| `/aiflow:dev <work-item-id>` | Implement the item, gated section-by-section with self-audit. |
| `/aiflow:test <work-item-id>` | Validate it empirically; generate a spec + report with the audit tables. |

`codebase-context` is a background library (not a command) the other skills read.

## Onboarding (per developer)

1. **Install** (see the marketplace README): `/plugin install aiflow@aiflow`.
2. **Configure your tools + secrets.** aiflow never ships secrets. Provide them one of three ways
   (the profile records which the team uses):
   - env-var interpolation in a committed `.mcp.json` (`${AZURE_DEVOPS_PAT}` etc.) + a gitignored `.env`,
   - `claude mcp add --scope user …` (secret stays in your private `~/.claude.json`),
   - OS keychain referenced via an env var.
   `/setup` writes a secret-free `.claude/pipeline/.env.example` listing exactly which vars you need.
3. **Run `/aiflow:setup`** → writes the committed profile. (Developer #2 just inherits it — no re-decide.)
4. **Generate codebase docs once:** ask Claude to "regenerate the codebase-context docs" (runs
   `regenerate.sh` → writes `.claude/pipeline/context/`). Optional but improves `/dev` and `/test`.
5. **Use** `/aiflow:create → /aiflow:dev → /aiflow:test`.

## What's committed vs not (per consuming repo)

- **Committed:** `.claude/pipeline/profile.json` (the determinism anchor), `.env.example`,
  `.claude/pipeline/context/` (generated codebase docs), `work-items/` (if using local-markdown tracker).
- **Gitignored:** `.claude/pipeline/.env`, `context-cache/`, `reports/`, `*.local.json`.

## Determinism

Two developers on the same commit converge because: detection is rule-based (`detect.sh` +
`detection-rules.md`), tool choice uses fixed preference lists (`capability-map.md`, no model
judgment), and the result is persisted to a committed, canonical `profile.json`. `/aiflow:setup --check`
reports drift; `--reconcile` re-runs the rules into a reviewable diff.

## Layout

```
skills/   setup · create · dev · test · codebase-context
_shared/  playbook/ (the build discipline)  ·  adapters/ (per-provider contracts)
```

Adapters decouple the pipeline from any provider; tools are discovered by capability via ToolSearch
(so they keep working under the `aiflow:` plugin namespace). See `skills/setup/references/` for the
detection table, capability matrix, and profile schema.
