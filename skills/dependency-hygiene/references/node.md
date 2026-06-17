# Node / JavaScript Reference

## Use This Reference When

The repo uses `package.json` plus one of:

- `package-lock.json`
- `npm`
- `.npmrc`
- `pnpm-lock.yaml`
- `yarn.lock`
- `overrides`, `resolutions`, or similar transitive controls

Default examples here use `npm`.

For deeper remediation patterns, implementation details, and report structures, see [implementation-playbook.md](implementation-playbook.md).

## Quick Reference

| Goal | Primary command(s) |
| --- | --- |
| Check outdated packages | `npm outdated` |
| Audit known vulnerabilities | `npm audit --audit-level=high` |
| Explain why a package exists | `npm explain package-name`, `npm ls package-name` |
| Review duplicate-package pressure | `npm dedupe --dry-run` |
| Refresh lock safely | `npm update --package-lock-only --ignore-scripts --prefer-online` |
| Deterministic CI install | `npm ci --ignore-scripts` |

## Security-First Update Policy

- Exact or intentionally pinned versions:
  - Do not move automatically just because something newer exists.

- Patch or narrow compatible updates:
  - Can be grouped only after dependency analysis, reviewable diffs, and passing CI are in place.

- Major or compatibility-boundary changes:
  - Review individually and keep isolated.

- Overrides:
  - Treat as temporary containment, not as the default upgrade path.

- Malicious or compromised publishes:
  - Move to incident response before doing any routine update workflow.

## New Dependency Intake Audit

Run this before approving a new direct dependency or an `npm install` suggestion.

Check:

- legitimacy:
  - exact package name
  - scope and typosquat risk
  - maintainer and repository metadata
  - recent publish timing and adoption as signals, not automatic blockers
- install behavior:
  - `preinstall`, `install`, and `postinstall` scripts
  - native downloads, binaries, or unexpected setup steps
- suspicious indicators:
  - `child_process`
  - unexpected network or filesystem access
  - obfuscated source
  - recent ownership or maintainer changes
- dependency complexity:
  - direct dependency count
  - transitive size
  - duplicate-package pressure
- optional governance:
  - license or policy review for new direct dependencies when the repo has governance constraints

Useful metadata commands:

```bash
npm view package-name name version license repository maintainers time dist-tags --json
npm view package-name scripts dependencies peerDependencies engines --json
```

Decision:

- `APPROVE`
- `REVIEW`
- `REJECT`

If many new direct dependencies are introduced, review each direct dependency individually.

For the fuller checklist and report template, see [implementation-playbook.md](implementation-playbook.md).

## Dependency Analysis

This is the first operational step.

If the project is fresh, treat this section as setup guidance.

If the project already exists, treat this section as a double-check that the analysis tooling and review habits are actually in place and still useful.

At minimum, inspect:

- outdated direct dependencies
- known vulnerability findings
- dependency-tree paths for risky transitive packages
- duplicate or unexpectedly fragmented packages
- stale overrides and peer-dependency workarounds

### Audit Dependencies

Use the package manager already established by the repo.

For npm, common commands are:

```bash
npm outdated
npm audit

# Use only after reviewing the expected graph change
npm audit fix

# Local/manual manifest analysis, not a CI default
npx npm-check-updates
npx npm-check-updates -u
```

For yarn or pnpm, translate the same intent to the equivalent commands already used in that repo.

### Analyze Dependency Tree

Use these to understand why a package is present and where graph risk is concentrated:

```bash
# Explain why a package is installed
npm explain package-name
npm ls package-name
yarn why package-name
pnpm why package-name

# Check duplicate reduction opportunities before mutating the graph
npm dedupe --dry-run

# Apply only after review
npm dedupe

# Optional local code import graph, useful for spotting package usage concentration
npx madge --image graph.png src/
```

### Diagnosis Mode

Use this when dependency problems are breaking installs or CI:

```bash
npm explain package-name
npm ls package-name
npm dedupe --dry-run
npm audit --json
```

Do not jump straight to deleting `node_modules` and the lockfile unless you are intentionally rebuilding from a pinned manifest or handling incident response.

Fresh project expectations:

- define the baseline analysis commands in docs or CI
- add at least one automated audit or review gate
- make the lockfile and package manager authoritative from day one

Established project expectations:

- verify the commands still match the active package manager
- verify all real package roots and workspaces are covered
- verify audit output is being reviewed instead of ignored
- verify stale overrides and peer-dependency escape hatches are re-evaluated

## Automated Dependency Updates

This is the second operational step.

If the project is fresh, add automated update coverage.

If it already exists, audit whether it is correctly configured and still working.

Prefer:

- Renovate when you want the most control and broad ecosystem coverage
- Dependabot when a simpler built-in setup is sufficient

Verify these points:

- the active package manager is covered
- all relevant directories and workspaces are covered
- GitHub Actions updates are also covered
- schedule and pull-request limits are sane
- major updates are separated from lower-risk updates
- lockfile maintenance is handled
- automerge, if any, is narrow and intentional
- dependency PRs trigger CI and review gates

### Renovate Example

```json
{
  "extends": ["config:base", ":dependencyDashboard"],
  "rangeStrategy": "pin",
  "lockFileMaintenance": {
    "enabled": true
  },
  "schedule": ["before 3am on Monday"],
  "prConcurrentLimit": 5,
  "packageRules": [
    {
      "matchManagers": ["npm"],
      "matchUpdateTypes": ["patch", "minor"],
      "groupName": "npm non-major updates",
      "automerge": false
    },
    {
      "matchUpdateTypes": ["major"],
      "labels": ["major-update"],
      "automerge": false
    },
    {
      "matchManagers": ["github-actions"],
      "groupName": "github actions"
    }
  ]
}
```

### Dependabot Example

```yaml
version: 2
updates:
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 5
    labels:
      - "dependencies"
    commit-message:
      prefix: "chore"

  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
```

Fresh project expectations:

- add Renovate or Dependabot immediately
- include manifests plus CI workflow dependencies
- choose bounded PR volume and explicit scheduling

Established project expectations:

- verify the bot is not stale, disabled, or mis-scoped
- verify it still covers the current monorepo or workspace layout
- verify security and version-update PRs are actually arriving
- simplify noisy rules and remove broken or misleading automerge settings

## Monorepo / Workspace Hygiene

Use this section when the Node repo has multiple packages, workspaces, or app directories.

Verify:

- all workspace manifests are included in dependency analysis
- update automation covers every workspace or package root that matters
- the lockfile strategy matches the repo layout
  - one root lockfile when intentionally centralized
  - per-package lockfiles only when intentionally split
- CI runs installs and verification from the correct root or workspace entry point
- unexpected extra lockfiles are treated as hygiene issues, not ignored

Common hygiene failures:

- root automation but uncovered workspace packages
- stale subpackage manifests
- accidental `npm` plus `yarn` plus `pnpm` mixing
- dependency PRs that update only one workspace while silently breaking another

## Inventory

Read these first:

- `package.json`
- lockfile
- `.npmrc`
- Node version file like `.nvmrc` or `.node-version`
- CI workflows

Record:

- direct dependency names and declared versions
- currently resolved direct versions from the lockfile
- risky transitive packages and their exact resolved versions
- existing overrides
- current Node and npm expectations

## Safe Remediation Procedure

Use this sequence for normal hardening:

1. Read `package.json`, lockfile, `.npmrc`, toolchain files, and CI settings.
2. Inventory direct dependencies and currently resolved versions.
3. Research flagged packages and record:
   - affected versions
   - safe versions
   - whether the issue is direct or transitive
   - whether it is a normal vulnerability or a malicious publish compromise
4. Rewrite direct dependencies to exact versions.
5. Add narrow `overrides` only where needed.
6. Refresh the lockfile with:
   - `npm update --package-lock-only --ignore-scripts --prefer-online`
7. Sync `node_modules` from the hardened lockfile if needed:
   - `npm install --ignore-scripts`
8. Verify with:
   - `npm audit`
   - build
   - stable tests, if the suite is trustworthy
9. Report residual risk explicitly.

If the goal is only to record the already-resolved versions, pin the direct dependency versions first and only then recreate or refresh the lockfile.

Do not blindly delete a lockfile in a drifting repo.

## Manifest Checklist

- Exact versions in `dependencies`
- Exact versions in `devDependencies`
- `packageManager` pinned
- `engines.node` declared
- Minimal dependency set: remove unused packages
- Targeted `overrides` only

## `.npmrc` Defaults

Useful defaults:

- `save-exact=true`
- `audit=true`

Use care with:

- `ignore-scripts=true`
  - Good for install-only CI jobs
  - Bad as a blanket default when the repo actually depends on lifecycle scripts

- `legacy-peer-deps=true`
  - Keep only when the repo still truly needs it, check every time if still needed

## Lockfile Guidance

- Commit the lockfile
- Review lockfile churn, not just manifest changes
- Prefer deliberate lock refreshes over ad hoc reinstalls
- Use `npm ci` in CI
- Avoid `npm install` in CI except for intentional graph changes

## Package Manager Hygiene

- Prefer one package manager per project.
- If multiple package managers are intentional, document which directories use which tool and why.
- Treat unexpected presence of `package-lock.json`, `pnpm-lock.yaml`, or `yarn.lock` together as a hygiene problem to investigate.
- Keep docs, CI, dependency bots, and local commands aligned with the chosen package manager.

## Toolchain

- Add `.nvmrc`, `.node-version`, or equivalent
- Align local dev and CI on the same supported Node line
- Prefer a declared `packageManager` field
- Treat unsupported Node versions as a source of audit and resolver drift

## CI / CD Baseline

For npm repos, default to:

- Install: `npm ci --ignore-scripts`
- Audit: `npm audit --audit-level=high`
- Verification: `npm run build`
- PR guardrail: dependency review action

Add tests only when the suite is already stable enough to be a reliable gate.

Avoid:

- `npx @latest`
- install commands that mutate the lockfile during CI
- auto-merge for dependency PRs without review

## Dependency PR Review Checklist

Review dependency changes with these questions:

- Does this PR add a new direct dependency?
- Is the version exact, or is it reintroducing semver drift?
- Does the package use lifecycle scripts?
- Does it download binaries or native artifacts at install time?
- Is it installed from a Git URL instead of the registry?
- Is the lockfile diff narrowly scoped or unexpectedly broad?
- Is an override being added? If yes, is there a documented reason and exit plan?
- Is the package maintained and publishing recent safe releases?
- Does a new direct dependency introduce a license or governance concern?
- Does the update require a toolchain bump?

## Override Policy

Overrides are appropriate when:

- A transitive package has a known bad version and a safe compatible version exists.
- A direct dependency is unmaintained but upstream has a documented workaround.
- The override is narrower and safer than a rushed package replacement.

Overrides are not appropriate when:

- They are speculative.
- They hide a necessary major upgrade forever.
- No compatibility check is performed.

Whenever you add an override, document:

- why it exists
- which package chain requires it
- which version is being forced
- what would allow its removal later

## Incident Response

If a malicious or compromised package may have been installed:

1. Identify whether the affected version was actually installed.
2. Determine where it ran:
   - developer machine
   - CI runner
   - production image build
3. Rotate all potentially exposed secrets.
4. Search logs for known indicators of compromise and suspicious outbound traffic.
5. Remove caches, `node_modules`, and compromised artifacts.
6. Rebuild from a known-good lockfile and clean environment.
7. Assume CI-injected secrets may be exposed if the install happened on CI.
8. Report what is known, what is assumed, and what remains unverified.

## Node Examples

### Exact-Version Manifest Pattern

```json
{
  "packageManager": "npm@11.4.2",
  "engines": {
    "node": "^22.13.0 || >=24.0.0"
  },
  "dependencies": {
    "next": "15.5.14",
    "react": "19.2.4",
    "react-dom": "19.2.4"
  },
  "devDependencies": {
    "typescript": "5.9.3",
    "vitest": "4.1.1"
  }
}
```

### Narrow Override Pattern

Use overrides for specific known-bad transitive packages or documented upstream workarounds:

```json
{
  "overrides": {
    "axios": "1.14.0",
    "react-simple-maps": {
      "d3-geo": "3.1.1",
      "d3-selection": "3.0.0",
      "d3-zoom": "3.0.0",
      "d3-transition": "3.0.1",
      "d3-interpolate": "3.0.1",
      "d3-color": "3.1.0"
    }
  }
}
```

Use the `axios` pattern for a malicious publish or known-bad version.

Use the `react-simple-maps` pattern when the stable package line is stale, upstream has a documented fix path, and the override is safer than a rushed package replacement.

### `.npmrc` Pattern

```ini
save-exact=true
audit=true
legacy-peer-deps=true
```

### Node Version File

```text
22.13.0
```

### CI Pattern

```yaml
name: CI

on:
  pull_request:
  push:
    branches:
      - main

permissions:
  contents: read

jobs:
  install-audit-build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version-file: .nvmrc
          cache: npm
      - run: npm ci --ignore-scripts
      - run: npm audit --audit-level=high
      - run: npm run build
```

### Dependency Review Pattern

```yaml
name: Dependency Review

on:
  pull_request:

permissions:
  contents: read

jobs:
  dependency-review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/dependency-review-action@v4
        with:
          fail-on-severity: high
```

### Safe Regeneration Sequence

```bash
# 1. Pin direct dependencies to exact versions first

# 2. Refresh the lockfile without lifecycle scripts
npm update --package-lock-only --ignore-scripts --prefer-online

# 3. Sync node_modules if needed
npm install --ignore-scripts

# 4. Verify
npm audit
npm run build
```
