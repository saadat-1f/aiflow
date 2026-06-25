# INVEST Criteria

Validate every drafted work item against INVEST before creating it. If it fails **Small**, suggest
a split and ask the engineer.

- **Independent** — self-contained; no hidden dependency on unfinished work.
- **Negotiable** — describes the *what* and *why*, not a rigid *how*.
- **Valuable** — clear user or business value stated.
- **Estimable** — scoped tightly enough to estimate effort.
- **Small** — completable in a single iteration; if not, propose how to split.
- **Testable** — every acceptance criterion is binary pass/fail (each maps to a Test Matrix row in `/test`).
