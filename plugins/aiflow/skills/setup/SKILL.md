---
name: setup
description: Detect this project and wire the dev pipeline (create → dev → test) to the right tools/MCP, deterministically. Run /setup once per project; it writes a committed .claude/pipeline/profile.json so every developer on the same commit gets the identical setup. Use when onboarding a repo to the pipeline, when the pipeline reports "no profile found", or to re-check/reconcile after the stack changes (/setup --check, /setup --reconcile).
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# /setup — Deterministic project detection + pipeline wiring

You configure the create → dev → test pipeline for **any** project (web, backend, mobile, CLI,
library) by detecting what the project is and binding each capability to the best-suited
tool/MCP. The output is a single committed file, `.claude/pipeline/profile.json`, that every
other skill reads. **Determinism is the whole point:** two developers on the same commit must get
byte-identical decisions. You achieve that by (a) rule-based detection, (b) fixed preference
lists, and (c) persisting the result so the second developer never re-decides.

Argument `$ARGUMENTS` may be empty (full setup), `--check` (report drift, write nothing), or
`--reconcile` (re-run rules into a reviewable diff).

**Reference files (read these — they are the spec you execute):**
- `references/detection-rules.md` — the ordered project-detection table + derived values
- `references/capability-map.md` — the capability → tool/MCP resolution function
- `references/profile-schema.md` — the exact shape of `profile.json` you must write
- `references/settings-recs.md` — safe additive settings + secrets handling + install commands
- `scripts/detect.sh` — read-only detector; run it, don't reimplement it
- `assets/profile.template.json` — the skeleton to fill
- `assets/mcp.snippets/*.json` — server templates (env-var placeholders, never secrets)

---

## Phase 0 — Locate existing profile (short-circuit)

1. Print: `> **[Phase 0] Locating profile**`
2. Check `.claude/pipeline/profile.json`.
   - **If it exists and parses and `schemaVersion` is understood:**
     - For `--check` → go to **Drift Check** (do not write).
     - For `--reconcile` → continue to Phase 1 (you WILL re-run rules and produce a diff).
     - For no-arg → run **Drift Check**; if no drift, print `> Profile up to date — no changes.` and STOP. This is the second-developer path: they inherit the committed decisions and never re-decide.
   - **If it does not exist** → continue (first-time setup).

## Phase 1 — Detect (pure function of repo files)

1. Print: `> **[Phase 1] Detecting project**`
2. Run the detector and capture its JSON:
   ```bash
   bash .claude/skills/setup/scripts/detect.sh
   ```
3. Parse the JSON. Record `projectClass`, `candidates`, `markersMatched`, `signals`,
   `packageManager`, `runtime`, `testRunner`, `vcs.remoteHost`, `scanRoots`, `surfaceNoun`.
4. If `projectClass == "monorepo"`, for each workspace dir run `detect.sh <dir>` and collect
   `subProjects[]`. If `projectClass == "unknown"`, do a discovery pre-pass: list top-level dirs,
   propose `scanRoots`, and ask the developer to confirm before proceeding.
5. Print a one-line summary: `> Detected: <projectClass> (<packageManager>) — candidates: <…>`.

## Phase 2 — Inventory existing infrastructure (existing-wins inputs)

1. Print: `> **[Phase 2] Inventorying existing tools**`
2. List configured MCP servers (read-only):
   ```bash
   claude mcp list
   ```
3. Note which servers are present (e.g. `azureDevOps`, `figma`, `playwright`, `google-docs`,
   `linear`, …) and whether each is reachable. Also scan for existing pipeline config
   (`.claude/pipeline/`, prior `.mcp.json`, `CLAUDE.md` pins). These are authoritative inputs:
   you bind to what already works rather than re-ranking.

## Phase 3 — Resolve capabilities (deterministic)

1. Print: `> **[Phase 3] Resolving capabilities**`
2. For each of the seven capabilities (`tracker`, `design`, `docs`, `runtime`, `automation`,
   `testRunner`, `vcs`), apply the **resolution function** from `references/capability-map.md`:
   profile-binds-it → existing-config-wins → first-configured-in-preference-list → fallback
   (`status: unavailable`). Tie-break alphabetically; record `alternatives[]`.
3. Set `status` per machine reality: `available`, `unavailable` (decided tool not configured), or
   `needs-secret` (configured but a `requiredEnv` var is unset — check the environment, never the value).
4. Fill each binding's `config` with the required keys from the capability map's per-tool table.
   For `tracker == azureDevOps`, capture `organizationId`/`projectId`/`storyType`/`taskType` from
   the configured server or by asking the developer once.

## Phase 4 — Derive conventions + context

1. Print: `> **[Phase 4] Deriving conventions**`
2. Fill `conventions` from detection: `runtime` → no longer hardcodes a URL; `testRunner` +
   `automation` → `specLanguage`/`specDir`/`specExt`; `vcs` + tracker `idLabel` →
   `branchPattern`/`commitPrefix`. Include `breakpoints`/`sourceImportAlias` only for UI classes.
3. Fill `context.scanRoots`/`surfaceNoun` from detection, and set
   `referenceDocs`/`checklists` per class (see `codebase-context`'s `doc-types.md`).
4. **Resolve library + docs paths by run mode** (so the same skills work in-repo AND as a plugin).
   Check the mode: `bash -lc 'echo "${CLAUDE_PLUGIN_ROOT:-}"'` — non-empty ⇒ installed plugin.
   - **Plugin mode:** set `context.playbookPath` = `${CLAUDE_PLUGIN_ROOT}/_shared/playbook`,
     `context.adaptersPath` = `${CLAUDE_PLUGIN_ROOT}/_shared/adapters` (write the literal
     `${CLAUDE_PLUGIN_ROOT}` string — the harness expands it when a consuming skill runs), and
     `context.skillPath` = `.claude/pipeline/context` (generated docs go into the consuming
     project, since the plugin install is shared/read-only).
   - **In-repo mode:** set `context.playbookPath` = `.claude/skills/_shared/playbook`,
     `context.adaptersPath` = `.claude/skills/_shared/adapters`,
     `context.skillPath` = `.claude/skills/codebase-context`.

## Phase 5 — Present plan + confirm (the only interactive gate)

1. Print the full proposed `profile.json` and, separately, the proposed **settings diff**
   (additive permissions from `references/settings-recs.md`) and any `.mcp.json` you would write.
2. List every `unavailable`/`needs-secret` capability with the **exact install/env command**
   (from `settings-recs.md`) — to be run by the developer, not by you.
3. Ask: `> Apply this setup? (yes / edit <field> / no)`. Confirmation authorizes the write; it
   does not change any decision. Loop on edits.

## Phase 6 — Write (canonical + idempotent)

Once confirmed:
1. Build the profile in memory, **canonicalize** (sorted keys, fixed array order, two-space
   indent, trailing newline, **no `generatedAt`**), and compare to any on-disk profile's canonical
   form. If identical → print `> No changes.` and write nothing (keeps `git diff` empty).
2. Otherwise write `.claude/pipeline/profile.json`.
3. Write `.claude/pipeline/.env.example` (required-env names + blank values + one-line comments).
   Ensure `.gitignore` covers `.env`, `.env.local`, `*.local.json`.
4. **Greenfield only:** if a capability needs a server and none is configured, write a project
   `.mcp.json` from `assets/mcp.snippets/` — server names + `${ENV}` placeholders only. **Refuse**
   to write any `env` value that is a literal token (hard secret guard). Skip if an equivalent
   server is already configured (existing-wins).
5. **Settings:** with confirmation, add the narrow permission entries to `.claude/settings.json`
   and record `settingsApplied.permissionsAdded` + a `fingerprint` hash.
6. Print: `> Profile written. Capabilities: tracker:<…> design:<…> automation:<…> …`

## Phase 7 — Offer to bootstrap context

Ask: `> Generate the codebase-context reference docs now? (yes/no)` — if yes, run
`bash .claude/skills/codebase-context/scripts/regenerate.sh` (it reads the profile you just wrote).

---

## Drift Check (`/setup --check`)

Read the profile, re-run `detect.sh`, recompute would-be bindings, and report WITHOUT writing:
- **Detection drift** — `projectClass`/signals changed since the profile was written → suggest `/setup --reconcile`.
- **Availability drift** — a bound tool's MCP is no longer configured, or a `requiredEnv` var is now unset → report the `status` mismatch (do not change bindings).
- **Settings drift** — `settingsApplied.fingerprint` no longer matches `.claude/settings.json`.
Print a table of drifts (or `> No drift.`). `--reconcile` is the only mode that changes bindings,
and it does so by producing a normal reviewable diff the developer commits.

## How a consuming skill uses the profile

Each of `create`, `dev`, `test`, `codebase-context` begins with **Phase 0 — Resolve Profile**:
read `.claude/pipeline/profile.json` (overlay `profile.local.json` if present), fail fast with
`> No profile found — run /setup first.` if absent, then branch on `capabilities.<cap>.tool` +
`status`, loading the matching adapter from `context.adaptersPath` and discovering tools by
capability via ToolSearch. They never hardcode a provider, a tool name, or a path.
