# Visual Diff Discipline (UI only — load only when a design source / real browser exists)

Loaded by `dev`/`test` **only** when `capabilities.design != none` or a browser `automation` is
bound. For a backend/CLI/library these rules don't apply and the audit's visual categories (C, E,
L, parts of N) are SKIPPED with reason. Tool-neutral: "design source" = Figma MCP, a `design/`
image dir, or pasted screenshots, per the bound `design` adapter.

## 1. Establish the design Spec table upfront (the contract)

Before building a section, extract a spec table from the highest-authority source:

| Element | Property | Exact value |
|---------|----------|-------------|
| Card | padding | 24px |
| Card | border-radius | 4px |
| Title | font / size / weight | <family> / 24px / 600 |
| Section | gap | 16px |

Audit category **C** passes only by comparing the built CSS to this table property-by-property —
no gestalt "looks right" approvals.

## 2. Data-source authority: spec/design-context > tokens > screenshot

- **Design-context / inspected spec** (exact, literal values) is the source of truth for
  dimensions, spacing, colour hex, typography.
- **Tokens** fill exact hex/scale values a screenshot can't be eyeballed for.
- **Screenshot** shows *structure* (nesting, dividers, accents, elevation) that values miss.
Never rely on one alone. **Never eyeball pixel/spacing values** — copy the literal value from the
spec (eyeballing yields 1–2px and 22-vs-24px drift on every section).

## 3. Map design nodes to their parent/siblings before building

A node named "form card" is often a **child** of the real wrapper (the white card with the shadow
is usually the parent), and its siblings (intros, headings) belong inside the same wrapper. Trace
parent + siblings first; render the wrapper as the parent with siblings as its children. Picking
the wrong nesting level causes layout regressions.

## 4. Visual diff must be thorough, not plausible

Explicitly scan — don't just glance — for: background tint (white vs off-white), borders/dividers
(vertical rules, section separators), padding insets (a hint of card-within-card), subtle
shadows/elevation, left-edge accents, and state indicators. Aggregated "layout matches" hides
these.

## 5. Screenshot every interactive state — not just resting

For each dropdown / radio / accordion / modal / error-input / hover / focus, drive it into the
non-resting state with the browser tool, screenshot, and diff against the design's state node.
Closed-state-only diffs miss native browser chrome, wrong option counts, and placeholder/copy
errors.

## 6. Variant state × breakpoint = separate checks

Each (state × breakpoint) is its own matrix row with its own design reference. Check screenshot
dimensions: mobile-only frames (≈319/335/375 wide) are NOT authoritative for desktop. If only one
breakpoint exists for a state, fetch the other before building — never infer desktop from mobile.

## 7. Iterate carousels / grids / lists over EVERY item

A single screenshot at one scroll position only captures the visible items. Scroll/navigate to
each item, screenshot, and diff. Silent failures hide in items outside the initial frame.

## 8. Validate downloaded design assets — size AND content

After downloading image assets, assert each file is non-trivial (e.g. ≥ ~5KB). A valid PNG header
with HTTP 200 does not mean the content rendered — empty/blank assets pass header checks. Check
the byte size of each downloaded asset; flag anything suspiciously small.

## Tool-specific quirks
Live in the bound design adapter (`<adaptersPath>/design/<tool>.md`) — e.g. how to fetch
design-context vs screenshots, how to download assets, display-name-vs-loaded-name font traps.
This file is the discipline; the adapter is the mechanics.
