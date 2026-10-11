---
name: forge
description: Adversarial full-stack review, fixing, and end-to-end verification of recent changes before PR handoff. Only use when explicitly requested or required by an explicitly invoked workflow.
disable-model-invocation: true
---

# Forge

Challenge recent (or pointed at) changes in the real running system, fix what breaks, and repeat until the result is verified. Optimize for demonstrated reliability, not test count.

## 1. Map the changes

- Fetch the latest code. Prioritize PRs created, updated, or merged in the last 72 hours, unless another scope is specified.
- Record the tested branches/SHAs and uncommitted changes; distinguish merged changes from open PRs requiring separate checkouts.
- Trace changed behavior through consumers, dependencies, specifications, and major configurations. Build a short review/verification matrix.

Gate: Every in-scope change and affected application/configuration has a verification path.

## 2. Prove the stack

Follow [setup-env](../setup-env/SKILL.md) using isolated test data. Carry its results into the verification matrix; reuse checks while the tested code and configuration remain unchanged.

Gate: Every applicable app/configuration passes runtime checks or has an evidenced blocker. Continue all unblocked verification.

## 3. Review and test adversarially

- Apply [code-review](../code-review/SKILL.md) to changed code and affected integrations; use [test-suite-strategy](../test-suite-strategy/SKILL.md) for coverage decisions.
- Run relevant unit, integration, E2E, type, lint, and build checks. Investigate failures and gaps.
- Use a real browser through real owned services: exercise changed journeys, negative paths, persistence, and relevant responsive/configuration variants. Inspect console/network/backend effects; capture screenshots at meaningful checkpoints. Exercise equivalent real flows for CLI and agents.

Gate: Each material risk is assessed, with verification evidence or an explicit gap.

## 4. Fix → prove → repeat

- Reproduce each actionable in-scope defect; diagnose the cause and make a focused fix following [implement](../implement/SKILL.md).
- Add regression coverage where justified; rerun the failing path, affected automated tests, and real-browser/runtime journeys. Re-review the final diff.
- Resolve and verify critical/high-severity in-scope issues. Classify remaining findings as pre-existing, out of scope, blocked, or deferred lower-severity issues, with reasons and evidence.

Gate: Each fix has passed affected automated and runtime checks, or has an evidenced blocker.

## 5. Ship the evidence

- Report reviewed PRs/SHAs, findings and fixes, matrix results (pass/fail/blocked/not tested), tests/commands and outcomes, browser journeys/screenshots, and remaining risks.
- Commit verified changes and open a PR with that report as its body. If no changes are needed, report without an empty PR; if blocked, state what remains unverified.

Gate: Pass requires all required checks to pass and all critical/high in-scope defects to be resolved; otherwise report failed or incomplete.
