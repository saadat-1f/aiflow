# Detection Rules — ordered, pure-function project classification

Detection is a **pure function of files committed to the repo**. No model judgment, no recency,
no "looks like". `scripts/detect.sh` implements this table; this doc is the spec it follows and
the reference a human uses to audit a `projectClass`.

## How the table is evaluated
1. Evaluate rows **top-to-bottom**. Each row is a boolean predicate over the presence/contents of marker files at the repo root (and a bounded set of well-known subpaths).
2. **First matching row wins** — its `projectClass` is recorded. Order IS the tie-break.
3. Record **every** matching row into `detection.candidates[]` (table order) for auditability.
4. Record the evidence as `markersMatched` (`file:signal` strings).
5. If matches span **separate workspace directories** (not the repo root), escalate to `monorepo` (row 17) and re-run this whole table inside each workspace dir to fill `subProjects[]`.

Predicates check existence or a quoted dependency key (`grep -E '"<dep>"\s*:'` in the manifest).
Never substring-match loosely. Versions are read into `signals` but never branch detection.

## The table

| # | Predicate (paths relative to repo root) | `projectClass` |
|---|-----------------------------------------|----------------|
| 1 | `*.xcodeproj/` or `*.xcworkspace/` present, or `ios/` contains an `*.xcodeproj` | `ios` |
| 2 | `pubspec.yaml` contains a `flutter:` key | `flutter` |
| 3 | `package.json` deps include `react-native` AND `expo` (and/or `app.json`/`app.config.js`) | `react-native-expo` |
| 4 | `package.json` deps include `react-native` (no `expo`), or sibling native `android/`+`ios/` with a JS `package.json` | `react-native` |
| 5 | `build.gradle`/`build.gradle.kts` AND (`AndroidManifest.xml` anywhere OR the `com.android.application` plugin) | `android` |
| 6 | `package.json` deps/devdeps include `next` | `web-next` |
| 7 | `package.json` deps include `nuxt` | `web-nuxt` |
| 8 | `angular.json` present | `web-angular` |
| 9 | `package.json` deps include `@sveltejs/kit` | `web-sveltekit` |
| 10 | `package.json` deps include `react`/`vue`/`svelte` + a bundler (`vite`/`webpack`) but no SSR framework above | `web-spa` |
| 11 | `package.json` deps include `express`/`fastify`/`@nestjs/core`/`koa`/`hapi` (no dominating front-end framework) | `backend-node` |
| 12 | `manage.py` present (Django), OR `pyproject.toml`/`requirements.txt` deps include `fastapi`/`flask` | `backend-python` |
| 13 | `go.mod` present | `backend-go` |
| 14 | `pom.xml`, or `build.gradle` with a `spring-boot` plugin | `backend-java` |
| 15 | `Cargo.toml` with `[[bin]]` or `src/main.rs` | `backend-rust` |
| 16 | `*.csproj`/`*.sln` referencing `Microsoft.NET.Sdk.Web` | `backend-dotnet` |
| 17 | A monorepo manifest (`pnpm-workspace.yaml`, `turbo.json`, `nx.json`, `lerna.json`, `go.work`, Cargo `[workspace]`), OR ≥2 of rows 1–16 matched in **distinct** workspace dirs | `monorepo` |
| 18 | A package manifest with a `main`/`exports`/`lib.rs`/published metadata and NO app entrypoint | `library` |
| 19 | none of the above | `unknown` |

## Per-class derived values

After the class is fixed, derive (deterministically, from manifests/config):

**Package manager** (web/node): `pnpm-lock.yaml`→`pnpm`, `yarn.lock`→`yarn`, `bun.lockb`→`bun`,
`package-lock.json`→`npm`, else `npm`. (python: `poetry.lock`→`poetry`, `uv.lock`→`uv`, else `pip`.)

**Runtime command + url** — first present script wins:
| class | command precedence | default url |
|-------|--------------------|-------------|
| web-* | `scripts.dev` → `scripts.start` → `scripts.serve` | next `:3000`, vite `:5173`, nuxt `:3000`, angular `:4200` |
| backend-node | `scripts.dev` → `scripts.start` | `:3000` |
| backend-python | `manage.py`→`python manage.py runserver`; fastapi→declared `uvicorn` script | `:8000` |
| backend-go | `go run ./...` if a `main` package exists | `:8080` |
| ios/android/flutter/rn | platform run command (`xcodebuild`/`gradlew`/`flutter run`/`expo start`) | n/a |
| library | (none) | n/a |
Port is parsed from the script/config when present; else the per-framework default above.

**Test runner** — detected from manifest + config files:
`jest`/`vitest`/`@playwright/test` (node, by dep + config file), `pytest` (`pytest.ini`/`pyproject`),
`go test` (go), `XCTest` (ios), JUnit (`pom.xml`/gradle), `cargo test` (rust). Record
`{ "framework": "...", "command": "..." }`.

**VCS remote host** — parse `git remote get-url origin`:
`dev.azure.com`/`visualstudio.com`→`azure-repos`, `github.com`→`github`, `gitlab`→`gitlab`,
`bitbucket`→`bitbucket`, else `unknown`.

**scanRoots + surfaceNoun** — for `context`/`codebase-context`:
| class | surfaces | modules | components | surfaceNoun |
|-------|----------|---------|------------|-------------|
| web-next | `pages`, `app` | `source/modules`, `src` | `source/modules/components`, `components` | route |
| web-* (other) | `src/pages`, `src/routes`, `app` | `src` | `src/components` | route |
| backend-* | `routes`, `controllers`, `api`, `cmd`, `handlers` | `src`, `internal`, `pkg`, `app` | `services`, `modules` | endpoint |
| ios/android/flutter/rn | `Screens`, `screens`, `lib`, `app/src/main` | `Sources`, `lib`, `src` | `Views`, `components`, `widgets` | screen |
| cli/library | `cmd`, `bin`, `src` | `src`, `lib`, `internal` | `src` | command |
Only roots that actually exist on disk are kept. For `unknown`/`monorepo` the SKILL runs a
discovery pre-pass and writes proposed roots into the profile for human review.

## Determinism holes & how this table closes them
- **Multiple manifests** → ordered table (lower row wins) + recorded `candidates[]`; separate-workspace matches → `monorepo`. Same commit ⇒ same class.
- **Ecosystem drift** (a new framework) → falls to `unknown` (a first-class outcome) until a row is added. Adding support = one new ordered row + a `prompts/<class>` entry in `regenerate.sh`, versioned by `schemaVersion`.
- **Version skew** → versions live in `signals` only; never alter the branch taken.
