# Python Reference

## Use This Reference When

The repo uses Python dependency artifacts such as:

- `pyproject.toml`
- `uv.lock`
- `poetry.lock`
- `requirements.txt`
- `requirements-dev.txt`
- `constraints.txt`
- `Pipfile.lock`

Default guidance here assumes modern Python application repos, with `uv` preferred when present.

For deeper remediation patterns, implementation details, and report structures, see [implementation-playbook.md](implementation-playbook.md).

## Quick Reference

| Goal | Primary command(s) |
| --- | --- |
| Check outdated packages | `uv pip list --outdated`, `pip list --outdated`, `poetry show --outdated` |
| Audit known vulnerabilities | `uv run pip-audit`, `pip-audit` |
| Check dependency health | `python -m pip check`, `uv tree`, `poetry show --tree` |
| Explain dependency ancestry | `pipdeptree -r -p package-name` |
| Refresh lock safely | `uv lock --upgrade-package pkg`, `pip-compile --upgrade-package pkg`, `poetry update pkg` |
| Deterministic CI sync | `uv sync --locked`, `pip-sync`, `poetry install --sync` |

## Security-First Update Policy

- Exact pins, compiled requirements, or committed lock artifacts:
  - Treat as intentional and do not loosen or refresh casually.

- Routine compatible updates:
  - Batch only when the resolver diff is reviewable and CI is reliable.

- Compatibility-boundary changes:
  - Review individually when a package crosses a major boundary or a declared version range needs widening.

- Constraints and temporary pins:
  - Treat as containment measures with an explicit exit plan.

- Malicious or compromised packages:
  - Move to incident response before doing any routine update workflow.

## New Dependency Intake Audit

Run this before approving a new direct dependency or a `pip install` style suggestion.

Check:

- legitimacy:
  - exact package name
  - typosquat risk
  - package index metadata
  - maintainer, homepage, and repository presence where available
  - recent publish timing and adoption as signals, not automatic blockers
- install behavior:
  - build backend
  - `setup.py` or dynamic build steps
  - direct URL or VCS installs
  - native extensions or opaque binary artifacts
- suspicious indicators:
  - import-time network or filesystem behavior
  - environment-variable reads in setup code
  - unclear wheel or source provenance
  - recent ownership or maintainer changes
- dependency complexity:
  - direct dependency count
  - transitive size
  - extras that expand the graph unexpectedly
- optional governance:
  - license or policy review for new direct dependencies when the repo has governance constraints

Useful checks:

```bash
pip index versions package-name
pip-audit
pipdeptree -r -p package-name
```

Decision:

- `APPROVE`
- `REVIEW`
- `REJECT`

If many new direct dependencies are introduced, review each direct dependency individually.

For the fuller checklist and report template, see [implementation-playbook.md](implementation-playbook.md).

## Python-Specific Risk Notes

Keep these in mind:

- Source distributions and build backends can execute code during build or install.
- VCS URLs and direct file URLs bypass normal registry review.
- Unhashed `pip install` flows are harder to reproduce and review.
- Extras can quietly expand the transitive graph.
- Different Python and resolver versions can produce different lock outcomes.
- Application repos and published libraries need different pinning strategies.

## Application vs Library Rule

For Python apps:

- Prefer a committed lockfile or compiled requirements artifact.
- Prefer exact, reproducible environments.

For Python libraries:

- Keep declared dependency ranges intentional in `pyproject.toml`.
- Lock the dev and test environment separately.
- Do not over-pin the published library metadata if compatibility is part of the library contract.

## Dependency Analysis

This is the first operational step.

If the project is fresh, treat this section as setup guidance.

If the project already exists, treat this section as a double-check that the analysis path still matches the real environment and still produces actionable results.

At minimum, inspect:

- outdated direct dependencies
- known vulnerability findings
- dependency-tree paths for risky transitive packages
- VCS or direct-URL dependencies
- stale constraints or temporary containment pins

### Audit Dependencies

Use the tool already established by the repo.

Common commands include:

```bash
# uv-based environments
uv pip list --outdated
uv tree
uv run pip-audit

# pip / virtualenv style
pip list --outdated
pip-audit
python -m pip check

# poetry
poetry show --outdated
poetry show --tree
```

### Analyze Dependency Tree

Use tree and reverse-dependency inspection to explain why a package is present:

```bash
# Optional extra tooling for tree analysis
pipdeptree
pipdeptree -r -p package-name
pipdeptree -p package-name
```

### Diagnosis Mode

Use this when installs, locks, or CI environments are breaking:

```bash
python -m pip check
pipdeptree -r -p package-name
uv tree
pip-audit
```

Do not recreate the whole virtual environment as a first response unless you are intentionally re-syncing from a trusted lock or responding to a compromise.

Fresh project expectations:

- choose and document one primary dependency-management flow
- commit the lockfile or compiled requirements artifact for application repos
- add at least one automated vulnerability or dependency review check

Established project expectations:

- verify the commands still match the active toolchain
- verify all requirements, extras, and lock artifacts are covered
- verify transient emergency constraints are still justified
- verify vulnerability output is being triaged instead of ignored

## Automated Dependency Updates

This is the second operational step.

If the project is fresh, add automated update coverage.

If it already exists, audit whether it is correctly configured and still working.

Prefer:

- Renovate when the repo uses `uv`, Poetry, mixed Python formats, or multiple ecosystems
- Dependabot when the repository layout is simple and the supported dependency sources are covered

Verify these points:

- the Python dependency source in use is covered
- all relevant directories are covered
- GitHub Actions updates are also covered
- schedule and pull-request limits are sane
- major updates are separated from lower-risk updates
- lockfile or compiled dependency maintenance is included where needed
- dependency PRs trigger CI and review gates

### Renovate Example

```json
{
  "extends": ["config:base", ":dependencyDashboard"],
  "lockFileMaintenance": {
    "enabled": true
  },
  "schedule": ["before 3am on Monday"],
  "prConcurrentLimit": 5,
  "packageRules": [
    {
      "matchManagers": ["pep621", "poetry", "pip_requirements"],
      "matchUpdateTypes": ["patch", "minor"],
      "groupName": "python non-major updates",
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
  - package-ecosystem: "pip"
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

- add Renovate or Dependabot as soon as the dependency layout is stable enough
- cover Python dependencies plus CI workflow dependencies
- keep the schedule explicit and the PR volume bounded

Established project expectations:

- verify the bot still understands the repository's dependency format
- verify update PRs are still arriving and not silently failing
- verify lock-refresh or compiled-requirements behavior is still correct
- remove noisy rules and stale exceptions that cause update fatigue

## Multi-Package / Multi-Directory Hygiene

Use this section when the Python repo has multiple services, packages, apps, or dependency roots.

Verify:

- each dependency root is included in analysis and update automation
- each directory uses the intended dependency-management tool
- lock or compiled-requirements strategy is documented for each package root
- CI runs sync, audit, and tests from the correct package or service entry point
- unexpected extra dependency-management files are treated as hygiene issues, not ignored

Common hygiene failures:

- root automation but uncovered service directories
- mixed `uv`, `poetry`, and raw `pip` flows with no documented boundaries
- stale compiled requirements in one directory while another root is updated
- dependency PRs that touch one package root but silently miss another

## Inventory

Read these first:

- `pyproject.toml`
- `uv.lock`, `poetry.lock`, or compiled requirements files
- Python version files such as `.python-version`
- CI workflows
- any private index or package source configuration

Record:

- direct dependency declarations
- current locked or compiled versions
- risky transitive packages and their exact locked versions
- current Python version expectations
- current package-management toolchain

## Safe Remediation Procedure

Use this sequence for normal hardening:

1. Read the manifest, lockfile or compiled requirements, Python version settings, and CI configuration.
2. Inventory direct dependencies and currently resolved versions.
3. Research flagged packages and record:
   - affected versions
   - safe versions
   - whether the issue is direct or transitive
   - whether install-time execution is relevant
4. Update the direct dependency or constraint with the smallest safe change.
5. Refresh the locked environment using the repo's tool:
   - `uv lock --upgrade-package <pkg>`
   - `pip-compile --upgrade-package <pkg>`
   - `poetry update <pkg>`
6. Sync the environment from the hardened lock or compiled requirements.
7. Verify with:
   - `pip-audit`
   - `python -m pip check` when appropriate
   - build, tests, and type checks relevant to the repo
8. Report residual risk explicitly.

Avoid ad hoc `pip install -U` flows when the repo already has a lock or compiled requirements process.

## Artifact Guidance

### `pyproject.toml`

- Apps can be more aggressively pinned.
- Libraries should use deliberate compatibility ranges.
- Keep optional extras intentional and reviewed.

### Lockfile or Compiled Requirements

- Commit `uv.lock`, `poetry.lock`, or compiled requirements for application repos.
- Prefer deterministic regeneration commands over manual editing.
- Review large transitive refreshes carefully.

## Package Manager Hygiene

- Prefer one primary dependency-management flow per Python project or per clearly documented package root.
- If multiple tools are intentional, document directory boundaries and CI behavior explicitly.
- Treat unexpected coexistence of unrelated dependency-management files as a hygiene problem to investigate.
- Keep docs, CI, dependency bots, and local commands aligned with the chosen flow.

### Hashes

When using `requirements.txt` style workflows, prefer hashes where practical:

- `pip-compile --generate-hashes`
- `pip install --require-hashes -r requirements.txt`

## Toolchain

- Pin the Python version in a version file or CI config.
- Align local dev and CI on the same supported Python line.
- Prefer a single primary dependency-management tool per repo.

## CI / CD Baseline

Use the repo's lock-aware install flow:

- `uv sync --locked`
- `pip-sync`
- `poetry install --sync`

Then run:

- `pip-audit`
- tests
- build or packaging validation if relevant

Avoid:

- unreviewed VCS or direct-URL dependencies in CI
- resolver-mutating install commands in CI
- mixing multiple package-management flows without reason

## Dependency PR Review Checklist

Review dependency changes with these questions:

- Is this an application repo or a library repo?
- Does the PR add a new direct dependency?
- Is the dependency declared with intentional bounds?
- Does it introduce a VCS URL, direct URL, or private source?
- Does it require building from source or native extensions?
- Is there a committed lock or compiled requirements change?
- Is the diff narrowly scoped or unexpectedly broad?
- Does a new direct dependency introduce a license or governance concern?
- Does the update require a Python version bump?
- Is there a safer wheel-based or maintained alternative?

## Constraint / Pin Policy

Use constraints, lockfiles, or compiled requirements when:

- a transitive dependency has a known bad version and a safe compatible version exists
- a safe lock refresh alone does not pick up the fix
- a temporary containment measure is safer than a rushed package replacement

Do not add speculative constraints that hide the need for a real upgrade plan.

Document:

- why the constraint exists
- which package chain requires it
- which version is being forced or excluded
- what would allow its removal later

## Incident Response

If a malicious or compromised Python package may have been installed:

1. Identify whether the affected version was actually installed.
2. Determine where it ran:
   - developer machine
   - CI runner
   - build image
3. Rotate exposed secrets and credentials.
4. Remove virtual environments, caches, and compromised build artifacts.
5. Rebuild from a known-good lock or compiled requirements set.
6. Review logs for suspicious network or filesystem behavior during install or build.
7. Report what is confirmed, assumed, and still unverified.

## Python Examples

### Application-Style `pyproject.toml`

```toml
[project]
name = "my-app"
requires-python = ">=3.12,<3.13"
dependencies = [
  "fastapi==0.115.12",
  "pydantic==2.11.4",
]
```

### Library-Style `pyproject.toml`

```toml
[project]
name = "my-library"
requires-python = ">=3.10"
dependencies = [
  "httpx>=0.27,<0.29",
  "pydantic>=2.8,<3",
]
```

### `uv` Flow

```bash
# Refresh one package safely
uv lock --upgrade-package httpx

# Sync exactly from lock
uv sync --locked

# Verify
uv run pip-audit
uv run pytest
```

### `pip-tools` Flow

```bash
# Refresh one package in compiled requirements
pip-compile --generate-hashes --upgrade-package httpx pyproject.toml

# Sync environment exactly
pip-sync

# Verify
pip-audit
pytest
```

### `poetry` Flow

```bash
# Refresh one package
poetry update httpx

# Sync environment
poetry install --sync

# Verify
poetry run pip-audit
poetry run pytest
```

### Minimal CI Pattern

```yaml
name: CI

on:
  pull_request:

jobs:
  verify:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: "3.12"
      - run: pip install uv
      - run: uv sync --locked
      - run: uv run pip-audit
      - run: uv run pytest
```
