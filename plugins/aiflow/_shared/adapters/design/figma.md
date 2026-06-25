# Adapter — design: Figma

Active when `capabilities.design.tool == "figma"`. Pairs with `playbook/visual-diff.md` (the
discipline); this file is the mechanics.

**Load tools:** `ToolSearch "+figma design_context"` then `"+figma screenshot"` (also
`get_metadata`, `get_variable_defs` as needed). Discover by capability.

**URL → fileKey/nodeId:**
- `figma.com/design/<fileKey>/<name>?node-id=<nodeId>` → convert `-` to `:` in nodeId
- `figma.com/design/<fileKey>/branch/<branchKey>/…` → use branchKey as fileKey
- `figma.com/file/<fileKey>/…` → same extraction

**Verbs:**
| Verb | Tool + params |
|------|---------------|
| fetch spec | `get_design_context` { fileKey, nodeId, clientFrameworks, clientLanguages } — returns literal values + asset URLs |
| screenshot | `get_screenshot` { fileKey, nodeId } — capture at **sub-frame** level (full pages render blurry); batch 4–5 per wave |
| tokens | `get_variable_defs` for exact hex/scale |

**Authority order:** design_context (literal values) > tokens > screenshot. Copy literal pixel/hex
values from design_context — never eyeball.

**Asset download:** asset URLs in the design_context response are valid ~7 days; download to the
project's asset dir, then **assert each file ≥ ~5KB** (valid PNG header ≠ rendered content).

**Font trap (generic):** a design's display font name (e.g. "Spirits Soft") often differs from the
CSS family the codebase loads (e.g. `spirits-soft`). Grep prior codebase usage for the actual
loaded family name — never paste the display name into CSS.
