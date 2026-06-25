# Test Patterns (generic)

Tool-neutral patterns for executing matrix rows and writing specs. The concrete waits/selectors
for THIS project's components live in the project's generated
`codebase-context/feature-checklists` / a `test-patterns` doc — keep stack specifics there, not
here. The bound automation adapter (`browser-test/<tool>.md`) supplies the live mechanics.

## Selector priority (UI / browser)
`data-testid` → role (getByRole) → text (getByText) → label → CSS (last resort). With build-hashed
class names, use partial attribute matches (`[class*="…"]`), never exact hashed names.

## Wait strategies (UI)
After navigation: wait for network idle + DOM ready. Conditionally-rendered content: wait for the
element's visible/hidden state. Animations: wait for the transition to settle. Async data: wait for
the response, then for the rendered result. (A charting lib's ready signal, currency parsing, an
analytics-layer interception, etc. are project-specific — pull them from the project's generated
patterns.)

## Assertion patterns
Visibility, exact/partial text, element count, attribute/CSS state, value. For data accuracy, read
the rendered output, normalize formatting, and compare to the expected value (allow a small
tolerance for rounding when appropriate).

## Non-UI execution (project-test-runner adapter)
- Backend/API: drive endpoints with an HTTP client against `runtime.url`; assert status + body per row.
- CLI: invoke the binary with the row's inputs; assert stdout + exit code.
- Library: call the public API; assert return/throws.
Run the project's `testRunner.command` for the generated spec.

## Spec generation
Emit one test per matrix row, grouped by category, in `conventions.specLanguage` to
`conventions.specDir/<id>.conventions.specExt`. Use relative navigation with the base URL from
config (not a literal). Each assertion reflects what was verified live and cites its matrix trace id.

## Empirical verdicts
Every PASS cites the trace (a browser action + observed result, an HTTP response, a CLI output, a
passing test) — never "the code contains the check" (`playbook/test-matrix.md` §2).
