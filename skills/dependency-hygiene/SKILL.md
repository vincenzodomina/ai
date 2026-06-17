---
name: dependency-hygiene
description: Security-first dependency hygiene for Node and Python projects. Use when auditing dependencies, verifying automated dependency updates, reviewing or editing manifests and lockfiles, triaging vulnerability findings, handling supply chain incidents, or maintaining long-term dependency safety practices.
---

# Dependency Maintenance, Hygiene & Security

## Quick Start

Use this skill for requests like:

- "audit dependencies"
- "check for outdated packages"
- "set up dependency hygiene for this repo"
- "verify our dependency bots are configured correctly"
- "update dependencies securely"
- "diagnose dependency problems"
- "review this npm install or pip install suggestion"

## Quick Audit Process

Use this compact flow before diving into deeper remediation:

1. Detect ecosystem, project mode, and lock strategy.
2. Run or review outdated checks and security scans.
3. Explain why risky or surprising packages are present.
4. Check whether automated dependency updates and CI gates exist and still work.
5. Classify the outcome:
   - immediate security fix
   - planned maintenance update
   - cleanup / removal
   - no action required

For the detailed operational patterns behind this, use:

- [references/node.md](references/node.md)
- [references/python.md](references/python.md)
- [references/implementation-playbook.md](references/implementation-playbook.md)

## Use This Skill When

- auditing dependencies for vulnerabilities or supply-chain risk
- checking for outdated packages and safe upgrade paths
- reviewing a new direct dependency before approving install
- verifying or setting up automated dependency updates
- reviewing or editing manifests, lockfiles, overrides, or constraints
- handling dependency incidents or suspicious package releases
- preparing remediation plans or dependency-risk summaries
- onboarding to a legacy project with unclear dependency state

## Do Not Use This Skill When

- the task is unrelated to dependency management
- there are no dependency manifests or lock artifacts to inspect
- the user only wants unrelated application debugging with no dependency angle

## Safety

- Do not publish sensitive unpatched vulnerability details to public channels.
- Verify risky upgrades in staging or an equivalent safe environment before production rollout.
- Treat suspected malicious package installs as incident response, including secrets review and environment rebuilds.

## Scope

Default to application repositories first.

This skill is ecosystem-agnostic in the main file.

Use the ecosystem references for implementation details:

- Node and JavaScript: [references/node.md](references/node.md)
- Python: [references/python.md](references/python.md)

## Supported Ecosystems

| Ecosystem | Primary files | Reference |
| --- | --- | --- |
| Node / JavaScript | `package.json`, lockfile, `.npmrc` | [references/node.md](references/node.md) |
| Python | `pyproject.toml`, requirements files, lock artifacts | [references/python.md](references/python.md) |

## Reference Guides

- [references/node.md](references/node.md)
  - Node workflow, lockfiles, overrides, workspace coverage, CI, and dependency-update automation
- [references/python.md](references/python.md)
  - Python workflow, constraints, lock strategies, CI, and dependency-update automation
- [references/implementation-playbook.md](references/implementation-playbook.md)
  - deeper end-to-end procedures, remediation patterns, and reporting structures

## Core Objectives

- Deterministic installs
- Smallest safe change
- Explicit reasoning for pins and overrides
- Verified remediation
- Clear residual-risk reporting
- Ongoing visibility into dependency health
- Update automation that is present, scoped, and actually working
- Minimal, reviewable dependency footprint
- Recurring maintenance that keeps risk from accumulating silently

## Security-First Update Policy

| Update class | Default posture |
| --- | --- |
| Fixed or exact version | Treat as intentional. Skip unless there is a deliberate reason to move it. |
| Low-risk routine update | Patch or narrow compatible update. Batch only after dependency analysis, working CI, and reviewability are in place. |
| Breaking update | Major or compatibility-boundary change. Review individually and keep isolated. |
| Containment fix | Narrow override, constraint, or patch. Use only with a documented reason and exit plan. |
| Malicious or compromised release | Treat as incident response first, not as a normal update task. |

## Best Practices

### Do

- Commit lockfiles or compiled dependency artifacts.
- Use deterministic install or sync commands in CI.
- Keep one package manager per project unless multiple managers are intentionally designed and documented.
- Document why direct dependencies, pins, constraints, or overrides exist.
- Minimize new direct dependencies and prefer simpler dependency graphs.
- Review license or governance implications for new direct dependencies when policy matters.
- Test, build, and audit after meaningful dependency changes.
- Verify monorepo or workspace coverage instead of assuming the root config covers everything.

### Don't

- Manually edit lockfiles or compiled dependency artifacts.
- Mix package managers accidentally in the same project.
- Use wildcard or `latest` style dependency sources in normal production workflows.
- Blindly run auto-fix or bulk-update commands without reviewing the expected graph change.
- Install unnecessary direct dependencies just because they are convenient.
- Commit installed dependency directories or local environments to version control.

## Threat Model

Dependency hygiene is not just "run the vulnerability scanner sometimes".

The real risks include:

- Version-range drift:
  - Loose version ranges can silently pull in new code during normal installs or updates.

- Lockfile drift:
  - Recreating a lockfile or refresh artifact without first pinning intent can update far more of the graph than expected.

- Malicious releases:
  - A maintainer or publisher account can be compromised and publish trojanized versions for only a short time.

- Install-time execution:
  - Package install, build, or setup hooks can execute code on developer machines and CI runners before runtime behavior is ever observed.

- Ad hoc package fetching:
  - Commands that download tools or packages outside the reviewed lock path create non-deterministic execution and review gaps.

- Toolchain drift:
  - Different language, package-manager, or resolver versions can produce different dependency graphs and verification results.

- Unmaintained dependencies:
  - A package can still be useful while carrying stale vulnerable transitive dependencies or a fix that never shipped to a stable release.

- Override or constraint debt:
  - Overrides, constraints, and patches are sometimes necessary, but they can hide the need for a proper upgrade or replacement if they linger.

- CI runner exposure:
  - If a malicious dependency executes during CI, assume injected secrets, tokens, or build credentials may be exposed.

## Workflow Overview

```text
User Request
    │
    ▼
┌──────────────────────────────────────────────────────────────┐
│ Step 1: DETECT ECOSYSTEM & PROJECT MODE                     │
│ • Node or Python                                            │
│ • App or library                                            │
│ • Fresh-project setup or existing-project audit             │
├──────────────────────────────────────────────────────────────┤
│ Step 2: NEW DEPENDENCY INTAKE AUDIT (CONDITIONAL)           │
│ • Run when a task adds a new direct dependency or install   │
│ • Check legitimacy, install hooks, supply-chain signals     │
│ • Decide: APPROVE / REVIEW / REJECT                         │
├──────────────────────────────────────────────────────────────┤
│ Step 3: DEPENDENCY ANALYSIS                                 │
│ • Outdated scan, vulnerability scan, tree inspection        │
│ • Duplicate / stale override / stale constraint review      │
│ • Set up the analysis path, or verify the current one       │
├──────────────────────────────────────────────────────────────┤
│ Step 4: AUTOMATED DEPENDENCY UPDATES                        │
│ • Add Renovate / Dependabot if missing                      │
│ • Or verify scope, schedules, PR limits, and CI gates       │
├──────────────────────────────────────────────────────────────┤
│ Step 5: INVENTORY THE CURRENT STATE                         │
│ • Record direct, transitive, locked, and toolchain state    │
├──────────────────────────────────────────────────────────────┤
│ Step 6: RESEARCH THE ACTUAL RISK                            │
│ • Confirm affected versions, safe versions, exploit path    │
├──────────────────────────────────────────────────────────────┤
│ Step 7: APPLY THE SMALLEST SAFE REMEDIATION                 │
│ • Pin, constrain, override narrowly, replace if needed      │
├──────────────────────────────────────────────────────────────┤
│ Step 8: REGENERATE, VERIFY, AND CHECK CI                    │
│ • Refresh lock artifacts, install safely, audit, build      │
├──────────────────────────────────────────────────────────────┤
│ Step 9: REPORT FINDINGS, STATUS, AND RESIDUAL RISK          │
│ • Include intake, analysis, and update-automation status    │
└──────────────────────────────────────────────────────────────┘
```

## Mandatory Workflow

1. Detect ecosystem and project mode
   - Determine whether the repository is Node or Python.
   - Determine the package manager or dependency tool in use.
   - Determine whether the repo is an application or a library.
   - Determine whether the task is fresh-project setup or validation of an already-established process.

2. New dependency intake audit, when applicable
   - Trigger this step when a task:
     - introduces a new direct dependency
     - proposes `npm install`, `pip install`, or an equivalent install command
     - suggests a package the project has not already standardized on
   - Check package legitimacy:
     - exact name and typosquat risk
     - publisher or maintainer identity
     - repository presence and project metadata
     - publish recency and adoption as signals, not sole approval criteria
   - Check package behavior and risk:
     - install, build, or setup hooks
     - suspicious filesystem, environment, process, or network behavior
     - transitive dependency size and complexity
     - optional license or governance review when repo policy or commercial constraints matter
   - Classify the intake decision as:
     - `APPROVE`
     - `REVIEW`
     - `REJECT`
   - If a task introduces many new direct dependencies, review each direct dependency individually rather than batch-approving the set.
   - When uncertainty remains and the package is small enough, inspect package source or install scripts before approving.

3. Dependency Analysis
   - Start by determining the ecosystem, package manager, manifest files, lock artifacts, toolchain version settings, and CI coverage.
   - Run or review the project's dependency analysis path:
     - outdated dependency checks
     - vulnerability or SCA scanning
     - dependency-tree inspection for risky transitive packages
     - duplicate-package or graph-drift checks where relevant
     - stale override, constraint, or patch review
   - If this is a fresh project with no dependency-analysis workflow yet:
     - treat this step as setup guidance and define the baseline analysis commands, files, and CI checks
   - If the project already has dependency-analysis practices:
     - treat this step as a double-check that the setup still exists, still covers the real dependency graph, and still produces useful results

4. Automated Dependency Updates
   - Determine whether the project already has automated update tooling such as Renovate, Dependabot, or an equivalent service.
   - If this is a fresh project without update automation:
     - treat this step as setup guidance and add a minimal safe configuration
   - If update automation already exists:
     - treat this step as a correctness audit and verify:
       - all relevant ecosystems and directories are covered
       - lockfile or compiled dependency maintenance is included where appropriate
       - schedule and pull-request limits are sane
       - major updates are separated from low-risk updates
       - CI and review gates actually run on dependency PRs
       - the automation is still creating usable PRs rather than silently failing or being ignored
   - Prefer conservative defaults:
     - explicit schedules
     - bounded PR volume
     - no broad silent automerge for risky updates

5. Inventory the current state
   - Read the dependency manifest(s), lockfile(s), package-manager config, toolchain version settings, and CI workflows.
   - Separate direct dependencies from transitive dependencies.
   - Record the currently resolved versions before changing anything.

6. Research the actual risk
   - Confirm advisories from authoritative sources: ecosystem audit tools, GitHub advisories, upstream security notices, registry metadata, and trusted incident writeups.
   - Identify affected versions, safe versions, exploit conditions, and whether the risk is direct, transitive, or install-time compromise.

7. Choose the smallest safe remediation
   - For applications, prefer exact direct dependency pins or an equally deterministic lock artifact.
   - For libraries, keep compatibility ranges deliberate and lock the dev/test environment separately.
   - Refresh the lock or compiled dependency artifact after pinning intent.
   - Add targeted overrides, constraints, or patches only for specific known-bad transitive packages or documented workarounds.
   - Replace, remove, or isolate a package when no stable safe line exists.
   - Treat installs during a malicious publish window as incident response, not routine maintenance.

8. Regenerate safely
   - Use the ecosystem-specific command sequence from the relevant reference file.
   - If the manifest still contains loose ranges, pin to the currently resolved versions before deleting or recreating any lock artifact.
   - Do not blindly delete a lockfile or compiled requirements artifact in a drifting repo.

9. Verify
   - Run the ecosystem's audit or SCA tool.
   - Sync the environment from the hardened lock or compiled dependency artifact.
   - Run the repo's relevant build and test commands.
   - Confirm the resolved versions of any previously risky packages in the lock artifact or installed graph.

10. Report
   - Summarize the threat or advisory.
   - State the safe versions used.
   - List exact changes made.
   - Call out residual risk, compatibility trade-offs, and anything not yet verified.

## Step 2 Intent: New Dependency Intake Audit

Treat new package approval as a separate security decision, not just part of a later upgrade.

The goal is to answer:

- Is this the intended package?
- Is it plausibly legitimate?
- Does it behave safely enough to allow installation?
- Is its dependency tree and governance acceptable for this repo?
- Should we approve it now, hold for review, or reject it?

Use recent publish timing, low adoption, or maintainer churn as signals that increase scrutiny, not as sole rejection criteria.

## Step 3 Intent: Dependency Analysis

Make this explicit every time.

You are not only looking for known CVEs. You are trying to answer:

- What is installed?
- Why is it installed?
- Which parts are stale?
- Which parts are risky?
- Which parts are poorly understood?
- Which parts are not being checked automatically?

For a fresh project:

- establish a repeatable analysis path
- document which files are authoritative
- add the first CI or scheduled checks

For an established project:

- verify the analysis path still exists
- verify it still matches the actual package manager and repository layout
- verify it still catches stale dependencies, risky transitive packages, and broken automation

## Step 4 Intent: Automated Dependency Updates

Treat automated updates as part of the security posture, not just convenience.

The goal is not "enable a bot".

The goal is:

- safe update cadence
- reviewable PRs
- bounded change size
- working CI on update PRs
- clear human review for risky changes

For a fresh project:

- add a minimal Renovate or Dependabot configuration
- cover all active ecosystems and directories
- include lockfile or compiled dependency maintenance where relevant

For an established project:

- verify the bot is configured for the current repository layout
- verify it still covers package-manager files and CI action updates
- verify schedules, labels, and PR limits are still appropriate
- verify major updates are separated and not silently merged
- verify update PRs are not piling up ignored or failing forever
- tighten or simplify the config when it has become noisy or misleading

## Hard Rules

- For applications, prefer exact direct dependency pins or a fully committed deterministic lock artifact.
- For libraries, keep dependency ranges intentional and keep the dev/test environment locked.
- Commit and review the lockfile or compiled dependency artifact.
- Do not manually edit lockfiles or compiled dependency artifacts.
- Pin the toolchain with version files and CI config.
- Every maintained project should have an explicit dependency-analysis path.
- Every maintained project should have automated dependency-update coverage or a documented reason not to.
- Do not mix package managers accidentally in one project; if multiple package managers are intentional, document the boundaries clearly.
- Minimize new direct dependencies and review license or governance implications when policy matters.
- In monorepos or multi-package repos, verify every workspace or package root is covered by analysis, automation, and CI.
- Never auto-approve install commands for unfamiliar new packages.
- Review each new direct dependency individually when many packages are introduced at once.
- Do not auto-apply all patch or minor updates blindly.
- Use deterministic install or sync commands in CI.
- Prefer disabling install hooks for install-only CI jobs when the workflow allows it.
- Gate PRs with dependency review plus audit and build checks.
- Do not let update bots silently merge risky changes.
- Do not use "latest" or ad hoc package-fetching commands in CI.
- Do not add broad overrides, constraints, or patches "just in case".
- Do not declare a package safe without citing a version and source.

## Decision Guide

Use this decision flow:

- New direct dependency or install command:
  - Run the intake audit first and classify the package as `APPROVE`, `REVIEW`, or `REJECT`.

- Manifest drift only:
  - Pin direct dependencies to the exact currently resolved versions.

- Transitive vulnerability fixable within existing ranges:
  - Refresh the lock artifact first before adding overrides or constraints.

- Transitive vulnerability not picked up automatically:
  - Add a narrow override, constraint, or equivalent mechanism and verify compatibility.

- Stable package line unpatched:
  - Prefer a documented upstream workaround.
  - Otherwise recommend replacement, fork, or explicitly risky beta adoption with residual risk called out.

- Malicious publish or compromised maintainer incident:
  - Move into incident response: rotate secrets, inspect CI and developer machines, rebuild from known-good inputs.

## Ecosystem References

Use these for concrete commands, file patterns, and examples:

- Node and JavaScript: [references/node.md](references/node.md)
- Python: [references/python.md](references/python.md)

## Output Requirements

When acting under this skill, include:

1. Threat or advisory summary
2. Direct vs transitive impact
3. Dependency-intake status, when new packages or install commands are involved
   - `APPROVE`, `REVIEW`, or `REJECT`
   - package legitimacy notes
   - suspicious-behavior notes
   - dependency-complexity notes
   - optional license or governance notes when relevant
4. Dependency-analysis status
   - what is installed
   - why the risky packages are present
   - what is stale, risky, poorly understood, or not being checked automatically
5. Automated-update status
   - whether automation exists
   - whether this task set it up or audited it
   - what scope gaps, CI gaps, or noisy misconfigurations remain
6. Chosen remediation and why
7. Priority classification and timeline when useful
8. Files changed
9. Verification results
10. Residual risks and follow-ups
