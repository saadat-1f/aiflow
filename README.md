# aiflow — Claude Code marketplace

A single-plugin marketplace distributing **aiflow**: a deterministic, stack-agnostic
spec → build → validate pipeline for Claude Code (`/setup → create → dev → test`).

## Install

```
# 1) add this marketplace (git URL once it's pushed, or a local path for testing)
/plugin marketplace add <git-url-of-this-repo>
#    e.g. local:   /plugin marketplace add /path/to/aiflow

# 2) install the plugin
/plugin install aiflow@aiflow
```

Then, in any project repo:

```
/aiflow:setup            # detect + wire the pipeline → commits .claude/pipeline/profile.json
/aiflow:create <desc>    # → tracked work item
/aiflow:dev <id>         # → gated implementation
/aiflow:test <id>        # → empirical validation + report
```

See [`plugins/aiflow/README.md`](plugins/aiflow/README.md) for the full onboarding, secrets handling,
and what gets committed per repo.

## Updating

Bump `version` in `plugins/aiflow/.claude-plugin/plugin.json` and in this repo's
`.claude-plugin/marketplace.json`, push, and consumers run `/plugin marketplace update aiflow`.

## Repo layout

```
.claude-plugin/marketplace.json     # marketplace manifest (lists the aiflow plugin)
plugins/aiflow/                     # the plugin
├── .claude-plugin/plugin.json
├── skills/                         # setup · create · dev · test · codebase-context
├── _shared/                        # playbook (build discipline) + adapters (provider contracts)
└── README.md
LICENSE
```
