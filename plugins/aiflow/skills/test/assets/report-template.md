# Test Report Template (provider-neutral)

`/test` Phase 6 fills this; Phase 8 saves it to `conventions.reportsPath/<id>-test-report.md`. The
three audit tables at the end are mandatory (`playbook/audit-categories.md`).

```markdown
# Test Report — <idLabel>-<id>

## Metadata
| Field | Value |
| Work Item | <idLabel>-<id> — <title> |
| Type / State | <type> / <state> |
| Target | <runtime.url or environment> |
| Automation | <playwright / project-test-runner / http-client> |
| Branch | <current branch> |
| Date | <YYYY-MM-DD HH:MM> |
| Class | <projectClass> |

### Context sources
| Source | Status |
| work item / cases / business / design | ✅ / ⏭ |

## Test Matrix results (by group)
(Each row cites the trace that proves PASS — empirical, never code inspection.)

### Functional
| # | Test | Source | AC | Result | Trace |

### Logic / Data accuracy
| # | Scenario | Inputs | Expected | Actual | Result | Trace |

### UI / UX            (SKIP for non-UI — note reason)
### Responsive / Environments
### Content / Contract
### Edge cases
| # | Test | Result | Trace |

## Summary
| Total | Passed | Failed | Skipped | Result |

Failures:
- <group #n>: expected <…> / actual <…> / severity <…> / suggested fix <…>   (or "No failures")

---
## Audit — mandatory output tables (audit-categories.md)

### 1. Fix log
| Cycle | Category/Item | What failed | Fix applied | Status |

### 2. Deferred items
| Item | Why deferred | Re-check when |

### 3. Final verdict
| Cat (A–N) | Result (PASS/FAIL/SKIP) | Evidence (matrix trace id / reason) |

---
## Self-learning (Phase 7)
New patterns found in the implementation not on the checklist; items appended (follow) — or "none".

## Artifacts
| Report | Spec | Screenshots/logs | Context cache |

## Next steps
- [ ] fix failures · re-run spec · re-test
```
