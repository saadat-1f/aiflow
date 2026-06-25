# Adapter — vcs: Git

Active for all projects (`capabilities.vcs.tool == "git"`). `remoteHost` from
`capabilities.vcs.config.remoteHost` (`azure-repos` | `github` | `gitlab` | `bitbucket` | `none`).

**Branch + commit conventions (from `conventions`):**
- Branch: `conventions.branchPattern` with `{TRACKER}`→tracker `idLabel`, `{ID}`→work-item id
  (e.g. `feature/ADO-132134`, `feature/GH-42`, `feature/WI-retirement-calc`).
- Commit: `conventions.commitPrefix` + message (e.g. `ADO-132134: add hero section`).

**Verbs:**
| Verb | Action |
|------|--------|
| branch | `git checkout -b <branchPattern>`; if it exists, ask switch-or-fresh |
| commit | atomic commits with the prefix; never force-push or hard-reset in the pipeline |
| open PR | by `remoteHost`: `azure-repos` → `az repos pr create` / ADO MCP; `github` → `gh pr create`; `gitlab` → `glab mr create`; `none` → skip, print branch name |

**Guardrails:** commit/push only when the user asks; if on the default branch, branch first; never
rewrite history in the pipeline flow.
