---
name: test-suite-strategy
description: Design and evolve software test suites using strict risk-based decision making and active test suite pruning. Use when deciding what tests to write, update, delete, or avoid; when preventing over-mocking and low-value tests; and when maintaining a high-signal, non-bloated balance of unit, integration, and end-to-end tests aligned with real system risk.
---

# Test Suite Strategy (High-Signal Mode)

## Core Principle

Treat the test suite as a **risk-control system**, not a coverage checklist.

Goal: maximize confidence per cost.

Every test must justify its existence through **explicit risk coverage**.

---

## Mandatory Decision Protocol (Do Not Skip)

For every change, you MUST produce:

1. **Behavior Change (1 sentence)**
2. **Primary Risk (1 sentence)** — what could realistically break
3. **Impact if Broken (1 sentence)** — why it matters
4. **Chosen Test Level + Justification (1 sentence)**

If you cannot clearly state these → DO NOT add a test.

---

## Risk Scoring (Make It Concrete)

Score each axis from 0–2:

* **Business criticality** (0 = irrelevant, 2 = critical path)
* **Change risk** (0 = trivial, 2 = complex/fragile)
* **Blast radius** (0 = isolated, 2 = system-wide)
* **Observability gap** (0 = obvious failure, 2 = silent failure)

Total score:

* **0–2 → No test or minimal extension**
* **3–5 → Unit OR integration test**
* **6–8 → Integration test required (default)**
* **7–8 + user-facing → Consider E2E**

This removes subjective "gut feeling" decisions.

---

## Test Level Selection

### Unit Tests

Use for:

* Pure logic
* Business rules
* Edge cases
* Algorithms
* Bug reproduction

Avoid:

* Trivial passthroughs
* Implementation details

Rule: protect **logic**, not structure.

---

### Integration Tests (Default Workhorse)

Use for:

* Service + DB
* API behavior
* Module boundaries
* Persistence
* Event flows

Preferred over mocked unit tests when signal is higher.

---

### End-to-End Tests

Use only for:

* Core user journeys
* Revenue-critical paths
* Auth/onboarding

Hard cap mindset: minimal set only.

---

## Mocking Policy

* Mock only **external/uncontrollable systems**
* Prefer real or lightweight fakes for owned components
* Never mock the behavior you need confidence in

Over-mocking = false confidence

---

## Action Selection (Exactly One)

For every change, choose ONE:

* No test
* Extend existing test
* Add unit test
* Add/extend integration test
* Add/extend E2E test

Default bias:
→ Extend existing test
→ Prefer integration over unit when uncertain

---

## Mandatory Deletion & Consolidation Rule

For EVERY new or modified test, you MUST also evaluate:

* Can an existing test be **removed**?
* Can multiple tests be **merged**?
* Is there **duplicate coverage across layers**?
* Is there a **flaky or low-signal test** that should be deleted?

If the suite grows without increasing signal → you are degrading it.

Adding tests without removing or consolidating is considered a failure.

---

## Hard Constraints

* No tests for coverage alone
* No duplication across layers without strong reason
* No tests for trivial code
* No forcing "unit" via mocking
* No implementation-detail assertions

Every test must answer:

> What regression does this protect against?

---

## Quality Gate (Reject Test if ANY Fail)

* Protects meaningful behavior
* Failure would matter
* Lowest-cost effective level chosen
* Behavior-focused (not implementation)
* Survives refactoring
* Setup simpler than tested behavior
* Non-duplicative
* Low flake risk

---

## Anti-Patterns (Strictly Forbidden)

* One-test-per-function policies
* Coverage-driven testing
* Mock-heavy "unit" tests with no real behavior
* Snapshot spam
* Same scenario tested at all layers
* Keeping obsolete tests
* Expanding E2E suites without strict justification

---

## Suite Shape Guidelines

* Many small, fast tests (logic)
* Strong integration layer (primary confidence)
* Very few E2E tests (critical flows only)

Shape follows architecture — not dogma.

---

## Maintenance Policy (Active Pruning)

Continuously:

* Remove redundant tests
* Delete flaky tests immediately
* Consolidate overlapping coverage
* Refactor tests when behavior evolves

A larger test suite is NOT a better test suite.

A test suite that does not shrink over time is unhealthy.

---

## Output Rule for AI

When proposing or writing tests:

1. Provide the **mandatory decision protocol (4 statements)**
2. Show **risk score (0–8)**
3. Justify **why this test improves suite-level confidence**
4. Identify at least **one candidate for removal, merge, or simplification**

If you cannot justify the test → do NOT write it
