# Adapter — design: Screenshots / local images

Active when `capabilities.design.tool == "local-images"` (a `design/`, `mocks/`, or `designs/`
dir of exported images) or when the developer pastes screenshots. The fallback when no design MCP
is configured. Pairs with `playbook/visual-diff.md`.

**No tools to load** — read images from `capabilities.design.config.dir`, or accept pasted
screenshots in chat.

**Verbs:**
| Verb | Action |
|------|--------|
| fetch spec | read the image(s) for the section; ask the developer for exact values the image can't convey (hex, spacing) |
| screenshot | use the provided images as the reference to diff against |

**Limits vs Figma:** no literal pixel/hex extraction — the spec table (visual-diff.md §1) must be
filled from the image plus developer-provided values. When a value can't be read, ASK (don't
eyeball/invent). Match structure, nesting, and states from the images; confirm exact numbers with
the developer.

**Degradation:** if no design source at all (`tool == none`), visual categories (C, E, L) are
SKIPPED with reason in the audit verdict and logged in deferred-items.
