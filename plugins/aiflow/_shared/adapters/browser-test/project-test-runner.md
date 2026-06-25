# Adapter — browser-test: Project test runner (non-web / no browser)

Active when `capabilities.automation.tool` is `none` or a non-browser runner — i.e. backend, CLI,
library, or mobile-without-device-tools. This is what makes the pipeline work off the web.

**No browser.** Verify each Test Matrix row through the profile's own runner / a client:
- **`testRunner`** — run `capabilities.testRunner.config.command` (`pytest`, `go test ./...`,
  `cargo test`, `mvn test`, `npm test`). Parse pass/fail per row.
- **HTTP client** (`automation.tool == "http-client"`, backends) — drive endpoints with `curl`
  against `runtime.url`; assert status + response body per matrix row.
- **CLI** — invoke the built binary with the row's inputs; assert stdout/exit code.
- **Mobile device tools** (`maestro`/`appium`, when bound) — run the device flow; assert per row.

**Spec generation:** emit/extend tests in the project's native test framework + language (from
`testRunner.framework` and `conventions.specLanguage`), one per matrix row, to the conventional
test dir.

**Audit impact:** visual/interactive/responsive categories (C, E, F-UI, L) are SKIPPED with reason
(no UI); logical (J), structure (B), hygiene (D), console/logs (H), security (M), journey (N)
fully apply and are traced via the runner. Verdicts still cite the exact trace (test name / curl
output), never code inspection.
