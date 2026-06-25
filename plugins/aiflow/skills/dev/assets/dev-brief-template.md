# Dev Brief Template (profile-driven)

`/dev` Phase 4 fills this from the work item + cached context + codebase-context. The engineer
confirms it before Phase 5. All paths/conventions come from `.claude/pipeline/profile.json` — no
hardcoded framework specifics.

```
DEV BRIEF — <idLabel>-<id>: <title>
Type: <type>   State: <state>   Assigned: <name/Unassigned>

## What to build
<2–5 sentences from description + spec + acceptance criteria; user-facing, not internal>

## Context sources
| Source           | Status (✅ loaded / ⏭ none / ⚠️ stale) |
| work item        | … |
| design           | … (or "none — follow reference + design-system") |
| docs / business  | … |
| codebase context | … |
| reference impl   | <name> at <path> (latest-design) |

## Acceptance criteria
- [ ] <criterion>   (each becomes a Test Matrix row in /test)

## Business logic (if any)
Inputs / Rules / Outputs / Edge cases — summarized; two-pass validation planned (test-matrix.md).
(If none: "derive from description; ASK for unspecified bounds — do not invent.")

## Design (only if design bound)
Spec table (Element | property | exact value) per visual-diff.md; component mappings to reuse vs create.
(If none: "Description only — follow reference patterns + design-system.md.")

## Implementation plan
Feature type + chosen reference (compare-then-pick) + checklist file.
File structure — derived from profile conventions + context.scanRoots (NOT hardcoded):
  <surface entry> → <module dir> → <components dir>
Components to CREATE / MODIFY / REUSE.
Integration: endpoints/APIs, state approach, libraries.
Build order: the enumerated units (each is a gated section per section-build-gates.md).

## Branch
<conventions.branchPattern with idLabel + id>
```
