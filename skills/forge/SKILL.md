---
name: forge
description: Adversarial full-stack review, fixing, and end-to-end verification of recent changes before PR handoff.
disable-model-invocation: true
---

# Forge

Challenge recent (or pointed at) changes in the real running system, fix what breaks, and repeat until the result is verified. Optimize for demonstrated reliability, not test count.

## 1. Map the changes

- Fetch the latest code. Prioritize PRs created, updated, or merged in the last 72 hours, unless another scope is specified.
- Record branches/SHAs; distinguish merged changes from open PRs requiring separate checkouts.
- Trace changed behavior through consumers, dependencies, specifications, and major configurations. Build a short review/verification matrix.

Gate: Every in-scope change and affected application/configuration has a verification path.

## 2. Boot and exercise the stack

- Use the repo-native setup script (typically: `scripts/setup-local-env.sh`) and start all required local services, databases, migrations, apps, and workers. Check/start Docker if necessary; try compatible trusted registries or other supported sources if images are unavailable.
- Discover existing Playwright/browser tooling and install it if needed before declaring browser testing unavailable.
- Smoke-test all applicable surfaces: web, CLI, mobile-web, agents/workers, and parallel implementations or major feature/configuration variants during migrations.
- Confirm actual cross-service behavior, not merely healthy processes. Use isolated test data.

Gate: All applicable surfaces run and pass smoke checks, or each blockage has concrete evidence.

## 3. Review and test adversarially

- Follow [code-review](../code-review/SKILL.md): review changed code and affected integrations against requirements; probe correctness, security, permissions, data integrity, failure handling, performance, compatibility, and maintainability.
- Follow [test-suite-strategy](../test-suite-strategy/SKILL.md): assess existing tests and regression risks before selecting tests to extend, add, consolidate, or remove. Favor high-signal integration tests; add E2E only for valuable journeys, especially package/interface changes.
- Run relevant unit, integration, E2E, type, lint, and build checks. Investigate failures and gaps.
- Use a real browser on the local stack: interact with changed journeys, negative paths, persistence, and relevant responsive/configuration variants. Inspect console/network/backend effects; capture screenshots at meaningful checkpoints. Exercise equivalent real flows for CLI and agents.

Gate: Each material risk has review findings and appropriate test/runtime evidence; gaps are explicit.

## 4. Fix → prove → repeat

- Reproduce each actionable in-scope defect; diagnose the cause and make a focused fix following [implement](../implement/SKILL.md).
- Add regression coverage where justified; rerun the failing path, affected automated tests, and real-browser/runtime journeys. Re-review the final diff.
- Iterate until critical/high-severity in-scope issues are resolved and verified. Classify remaining issues as pre-existing, out of scope, or blocked, with evidence.

Gate: Fixes demonstrably work end to end, with no known unverified critical/high-severity regressions.

## 5. Ship the evidence

- Report reviewed PRs/SHAs, findings and fixes, matrix results (pass/fail/blocked/not tested), tests/commands and outcomes, browser journeys/screenshots, and remaining risks.
- Commit verified changes and open a PR with that report as its body. If no changes are needed, report without an empty PR; if blocked, state what remains unverified.

Gate: Each success claim is supported by observed evidence; verified improvements are submitted for review.
