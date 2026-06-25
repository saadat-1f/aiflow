# Capability Map — deterministic capability → tool/MCP binding

The pipeline needs seven **capabilities**. For each, `/setup` resolves exactly one binding using
the fixed function below. There is **no model judgment** here — the only inputs are (a) the
detected `projectClass`, (b) which MCP servers/tools are already configured, and (c) these fixed
preference lists. Same inputs ⇒ same binding, on every machine.

## Resolution function (applied per capability, in this order)
1. **Profile already binds it** (re-run / second developer) → keep verbatim. Stop.
2. **Existing config wins** → if exactly one configured MCP/tool matches this capability, bind it (`boundFrom: "existing-mcp"` or `"existing-config"`). Do not consult the preference list.
3. **Preference list** → pick the first entry whose MCP/tool is configured (`boundFrom: "rule"`).
4. **Fallback** → if none configured, bind the first entry of the list and set `status` to `unavailable` (or `needs-secret` if configured-but-missing-env). The decision is still recorded and shared.

**Tie-break** when step 2 finds ≥2 configured matches: choose by ascending alphabetical server
name; record the losers in `alternatives[]`. (Deterministic, not "best".)

`status` is the ONLY field allowed to differ between developers. The chosen `tool` is identical
for everyone on the same commit.

## The matrix

| Capability | Profile key | Fixed preference order (first configured wins) | `kind` | Notes |
|------------|-------------|-----------------------------------------------|--------|-------|
| Work-item tracker | `tracker` | `azureDevOps` → `jira` → `linear` → `github-issues` → **`local-markdown`** | mcp / local | `local-markdown` is always available ⇒ tracker never hard-fails. `idLabel` per tool: ADO/JIRA/LIN/GH/WI. |
| Design source | `design` | `figma` → `local-images` → **`none`** | mcp / local | `local-images` chosen only if a `design/`,`mocks/`,`designs/` dir exists. `none` ⇒ visual-diff playbook is skipped. |
| Doc source | `docs` | `google-docs` → `notion` → `confluence` → **`local-markdown`** | mcp / local | Reference docs (PRFAQ/specs). |
| Runtime / preview | `runtime` | derived from `projectClass`, NOT from MCP (see `detection-rules.md`) | command | `{command,url}` from manifest scripts. Replaces hardcoded `localhost:3000`. |
| Browser / device automation | `automation` | web → `playwright` → `none`; mobile → `maestro` → `appium` → `none`; backend → `http-client` → `none`; cli/library → `none` | mcp / command | **Platform-gated** — never offer Playwright to an iOS project. `none` ⇒ test runs via `testRunner` only. |
| Test runner | `testRunner` | detected from manifest (jest/vitest/playwright/pytest/go test/XCTest/JUnit/cargo) | command | The project's own runner; always present for non-trivial projects. |
| VCS | `vcs` | `git` (only option) + `remoteHost` parsed from `git remote` | builtin | Drives branch/commit conventions + PR host. |

## Per-tool `config` fields each binding must capture

| tool | required `config` keys |
|------|------------------------|
| `azureDevOps` | `organizationId`, `projectId`, `storyType`, `taskType`, `idLabel:"ADO"` |
| `jira` | `site`, `projectKey`, `issueType`, `idLabel:"JIRA"` |
| `linear` | `teamId`, `idLabel:"LIN"` |
| `github-issues` | `repo` (`owner/name`), `idLabel:"GH"` |
| `local-markdown` (tracker) | `dir` (default `.claude/pipeline/work-items`), `idLabel:"WI"` |
| `figma` | (none — needs only a URL at call time) |
| `local-images` | `dir` |
| `google-docs`/`notion`/`confluence` | (auth via env; no repo config) |
| `dev-server`/`run-server` | `command`, `url` |
| `playwright` | `specDir`, `specExt` |
| `*-test` runners | `command` |
| `git` | `remoteHost` |

## Capability → ToolSearch query (how a skill loads the tools at run time)

Consuming skills **never hardcode literal MCP tool names** — those change to
`mcp__plugin_<name>_<server>__<tool>` once shipped as a plugin. They discover by capability:

| tool | ToolSearch query | primary verbs → tool |
|------|------------------|----------------------|
| `azureDevOps` | `+azureDevOps work_item` | fetch=`get_work_item`, create=`create_work_item`, me=`get_me` |
| `jira` | `+jira issue` | fetch/create/transition issue |
| `linear` | `+linear issue` | fetch/create issue |
| `github-issues` | `+github issue` | gh issue view/create (CLI) or MCP |
| `figma` | `+figma design_context` then `+figma screenshot` | get_design_context, get_screenshot |
| `google-docs` | `+google-docs readDocument` / `readSpreadsheet` | read doc/sheet |
| `playwright` | `+playwright navigate` (fallback `playwright`) | navigate/click/fill/screenshot/resize |

The full verb→tool + provider-quirk contract for each lives in
`_shared/adapters/<role>/<tool>.md`. The capability map only fixes WHICH tool; the adapter fixes
HOW to drive it.

## Missing tools — deterministic degradation (never auto-install)
- The binding (the decision) is always written + committed. Machine reality → `status`.
- `unavailable`/`needs-secret` ⇒ `/setup` prints the exact install/env command from the fixed
  table in `mcp.snippets/` + `settings-recs.md`; it does not run it.
- Downstream degradation is by rule (documented in each consuming SKILL): no tracker →
  `local-markdown`; no design → skip visual-diff with a logged deferral; no browser →
  `project-test-runner`. Two devs with different installed tools get the **same workflow shape**.
