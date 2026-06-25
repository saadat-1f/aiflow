# Settings Recommendations — additive, narrow, reproducible

`/setup` may write two kinds of additive config. Both are **additive only** (never remove or
loosen existing entries), shown as a diff, and confirmed before writing.

## 1. Permission allowlist (`.claude/settings.json`)

Add ONLY the narrowest permissions the pipeline provably needs, derived from the resolved
profile. Prefer the project `settings.json` (shared, reproducible) over `settings.local.json`.

| Source | Permission to add (narrowest form) |
|--------|-----------------------------------|
| `runtime.config.command` | `Bash(<command>:*)` — e.g. `Bash(npm run dev:*)`, `Bash(go run ./...:*)` |
| `testRunner.config.command` | `Bash(<command>:*)` — e.g. `Bash(npx playwright test:*)`, `Bash(pytest:*)` |
| `vcs` | `Bash(git checkout:*)`, `Bash(git branch:*)` (only if not already present) |
| any `unavailable` tool | `Bash(claude mcp add:*)` (so the dev can self-install) |
| `codebase-context` regen | `Bash(bash .claude/skills/codebase-context/scripts/regenerate.sh:*)` |

Rules: never widen (`Bash(npm run dev:*)`, **not** `Bash(npm:*)`); never add network/`rm`/force
permissions; the exact set written is hashed into `profile.settingsApplied.fingerprint` so
`/setup --check` can flag manual drift.

## 2. MCP servers (`.mcp.json`) — only for greenfield

Write a project `.mcp.json` **only when no equivalent server is already configured**
(existing-wins). For a project that already has the server configured at user/global scope (like
this repo's Azure DevOps / Figma / Playwright), record the binding + `status` and do **not** write
a competing `.mcp.json`.

When written, the snippets in `assets/mcp.snippets/` are the starting templates. They contain
**server names + `${ENV_VAR}` placeholders only — never literal secrets**. Hard guard: refuse to
write any `env` value that is a literal token rather than `${VAR}`.

The snippets are reference shapes — a consuming team adjusts the package/endpoint to its
actual server. Each snippet's `env` block doubles as the declaration of that tool's `requiredEnv`.

## 3. Secrets — never written, supplied per developer

`/setup` records `capabilities.<cap>.requiredEnv[]` and generates a committed, secret-free
`.claude/pipeline/.env.example` listing those var **names** with blank values + a one-line comment
each. It ensures `.gitignore` covers `.env`, `.env.local`, and `*.local.json`. Developers set the
real values via one of (recorded in the profile so the team is consistent):

1. **`.env` + `${VAR}` interpolation** in a committed `.mcp.json` (Claude Code expands `${VAR}` at load).
2. **`claude mcp add --scope user …`** — secret lives in the dev's private `~/.claude.json`.
3. **OS keychain / secret manager** referenced via an env var.

If a `requiredEnv` var is unset on the current machine, the capability is marked
`status: "needs-secret"` and `/setup` prints the exact channel to set it — it never prompts for,
echoes, or stores the value.

## Install-command table (printed for `unavailable` tools; never auto-run)

| tool | command to print |
|------|------------------|
| azureDevOps | `claude mcp add azureDevOps --scope user -- npx -y @tiberriver256/mcp-server-azure-devops` (then set `AZURE_DEVOPS_*` env) |
| figma | `claude mcp add --transport http figma https://mcp.figma.com/mcp` |
| playwright | `claude mcp add playwright --scope user -- npx @playwright/mcp@latest` |
| google-docs | `claude mcp add google-docs --scope user -- npx -y @a-bonus/google-docs-mcp` (then set `GOOGLE_CLIENT_ID`/`GOOGLE_CLIENT_SECRET`) |
| linear | `claude mcp add --transport sse linear https://mcp.linear.app/sse` |
| github | `claude mcp add --transport http github https://api.githubcopilot.com/mcp/` — or use the `gh` CLI (no MCP) |
| jira | `claude mcp add jira --scope user -- npx -y <your-jira-mcp>` (then set `JIRA_*` env) |
