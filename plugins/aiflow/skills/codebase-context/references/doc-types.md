# Doc Types — stack-neutral generation prompts

The spec for each reference doc `regenerate.sh` produces. Prompts are **generic**, with scan
roots and the surface noun interpolated from the profile (`{{surfaces}}`, `{{modules}}`,
`{{components}}`, `{{surfaceNoun}}`, `{{projectClass}}`). `{{REFS}}` = the references dir.

## architecture.md (all classes)
> "Scan {{modules}} and the project root. Regenerate {{REFS}}/architecture.md: framework + version, build/config files, directory layout, entrypoints, module/dependency graph, env vars, run/build scripts. Write directly."

## coding-standards.md (all classes)
> "Scan {{modules}} for conventions. Regenerate {{REFS}}/coding-standards.md: naming, import/module organization, state/data patterns, error handling, styling approach (if UI), testing conventions. Derive from actual code; prioritize the most recently modified areas (git log). Write directly."

## component-catalog.md (title adapts)
- UI classes → "Component Catalog": "Scan {{components}}. For each reusable component: name, import path, brief purpose, key props. Group by category."
- backend → "Module/Service Catalog": "Scan {{modules}} and {{components}}. For each service/module: name, path, responsibility, key exports."
- library → "Package/Export Catalog": public exports + signatures.
> "…Regenerate {{REFS}}/component-catalog.md. Write directly."

## design-system.md (UI only)
> If `capabilities.design != none` AND class is UI: "Scan styles/components of the newest features (git log). Extract color tokens, typography, spacing scale, breakpoints, border/shadow/radius, button/input styles. Write directly."
> Else write the single line: `N/A — no UI layer for {{projectClass}}.`

## surface-map.md (noun adapts)
> "Scan {{surfaces}}. Map every {{surfaceNoun}} to its implementation in {{modules}}. Format: {{surfaceNoun}} → impl path → brief description. Group by domain. Run `git log -1 --format=%ai` per dir for last-modified. Include any special/entry files. Write directly."
(`{{surfaceNoun}}` = route | endpoint | screen | command.)

## feature-catalog.md (all classes)
> "Scan ALL of {{surfaces}} and {{modules}}. For each feature: type, domain, layout/shape, inputs, outputs, key behaviors, implementation path. Run `git log -1 --format=%ai` per dir. Mark the most recently modified feature of each type '✅ Latest design'; older ones '⚠️ may use older patterns'. Group by type; add a quick-reference table. Write directly."

## feature-checklists/ (common + class-specific)
> "Analyze all features in {{surfaces}}/{{modules}} grouped by type; find common patterns (prioritize recent, by git log). Regenerate {{REFS}}/feature-checklists/common.md (cross-cutting) plus the class-specific files for {{projectClass}}:"
> - web → `page.md` (page structure, SEO/meta, responsive, analytics, forms), `form.md` (validation, state, submit)
> - backend → `endpoint.md` (routing, validation, auth, error shape, status codes), `job.md` (idempotency, retries, logging)
> - mobile → `screen.md` (navigation, lifecycle, state), `flow.md` (multi-screen journeys)
> - cli/library → `command.md` (args/flags, output, exit codes), or `api.md` (public surface, versioning)
> "Format as checklists; mark recent patterns (follow), older-only (verify). Write all files directly."

## Discovery pre-pass (`unknown` / `monorepo`)
If `projectClass` is `unknown` or scan roots are empty, first run:
> "List top-level directories and identify where surfaces, modules, and reusable units live. Propose scanRoots as JSON."
Write the proposed roots into the profile for human review, then run the per-doc prompts.

## allowedTools
All `claude -p` calls use read-only tools: `Read,Write,Glob,Grep,Bash(git:*),Bash(ls:*)` plus any
read-only language command the class needs. The docs are advisory artifacts, reviewed before commit.
