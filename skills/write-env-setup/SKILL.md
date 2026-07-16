---
name: write-env-setup
description: >-
  Create, repair, or review repository-local environment bootstrap scripts that
  reconcile dependencies, services, configuration, and data into a runnable
  development stack. Use when a project needs a setup script, an existing
  bootstrap is unreliable, or blank and re-woken environments must recover
  predictably.
---

# Write environment setup

Build or curate one repository-native bootstrap script that converges the
current machine on a runnable development system. Treat it as a
**reconciliation loop**, not a one-time installer: cold starts, healthy re-runs,
and wake recovery are all normal paths.

The finish line is an app-level observable—a successful health request, login,
or rendered page—not merely installed dependencies or running containers.

## Outcomes

The script should:

- provision the required local stack from the least-prepared supported host;
- repair only missing, stopped, or unhealthy state on later runs;
- preserve data and human-owned configuration;
- explain each action and make failures actionable;
- leave the application ready for realistic development and testing.

Support the environments the repository actually targets. Detect compatible
tools and interfaces where those environments vary; avoid speculative platform
branches.

## Workflow

### 1. Discover the local-system contract

Read the repository's manifests, task scripts, lockfiles, container definitions,
example environment files, migrations, documentation, agent instructions, and
CI setup. Trace the dependency order from host tools through services and data
to the application.

When repairing an existing script, run it first and preserve its working
structure. Repair observed gaps rather than replacing it from assumptions.

**Complete when:** every required process, port, configuration source,
migration or seed action, and external dependency needed for startup is
accounted for.

### 2. Define readiness

State the end condition as a concrete observable: what must be running and which
request or user flow proves the system works. This becomes the acceptance test.

**Complete when:** readiness can be checked automatically against the running
application.

### 3. Implement reconciliation

Follow established repository patterns. If none exists, `skeleton.sh` is an
optional structural starting point; adapt it to the project rather than copying
its examples literally.

Order steps by their real dependencies. Give each step a state check, the
smallest corrective action, and clear output. Distinguish fatal prerequisites
from optional or degradable capabilities, and include the likely remedy in any
failure message.

**Complete when:** every action has a checkable desired state and re-running a
healthy step leaves it unchanged.

### 4. Close the runtime feedback loop

Run the script in the target environment, start the application, and exercise
the readiness check. Treat each failure as missing system knowledge: update the
script or its assumptions, then run the full path again.

**Complete when:** the script finishes successfully and the application-level
observable passes.

### 5. Rehearse the lifecycle

Run again while healthy, then stop the local services to simulate a sleeping
environment and run once more. Confirm that stopped state recovers, persistent
data remains, user configuration survives, and no runtime artifacts dirty the
repository.

**Complete when:** cold, warm, and wake-recovery runs all converge on the same
ready system.

## Agent discoverability

Add or update a local-environment section in the applicable `AGENTS.md`. Briefly
state what the setup script provisions and verifies, point to its canonical
repository path, and instruct agents to read the script before running,
changing, or troubleshooting the environment. Keep `AGENTS.md` as a discovery
pointer; leave commands and implementation details in the script as the single
source of truth.

**Complete when:** an agent entering the repository can discover the script,
understand its role, and know when to consult it.

## State reconciliation

Model services as three states: healthy, present but stopped or unhealthy, and
absent. Skip healthy state, recover existing state when possible, and provision
only when necessary. A process being present is weaker evidence than its
readiness check.

Apply the same distinction to artifacts:

- installed artifacts are reused while valid;
- cheap derived artifacts may be regenerated to repair partial state;
- migrations should naturally no-op when current;
- repeatable seeds preserve or upsert existing data unless reset is explicit.

A warm run should be dominated by health checks, not downloads, installs, or
re-provisioning.

## Environment configuration

Wire configuration after local services are ready so real endpoints and local
credentials are available. Start from the repository's example file when a
local file is absent, and keep separate applications' configuration coherent.

Classify values by ownership:

- **service-owned values** are deterministic outputs of the local stack and may
  be refreshed from that source of truth;
- **human-owned values** are filled only when missing or blank and otherwise
  preserved;
- **boot placeholders** are acceptable only when an integration requires a
  non-empty value to start and the placeholder leaves that integration inert.

Local secret files remain uncommitted. Verify ownership by pre-setting a human
value, running twice, and confirming it is unchanged.

## Runtime learnings

Static inspection rarely reveals the full environment. Use observed failures to
refine the system contract:

- build failures expose genuinely required host libraries;
- startup failures expose eager configuration requirements;
- early migrations expose service-readiness races;
- stopped resources expose gaps between existence and health;
- wrapper processes expose child-process or port cleanup needs;
- network and TLS errors expose policy, trust, or distribution constraints;
- generated files expose what must be tracked, ignored, or stabilized;
- equivalent tool variants expose where capability detection is needed.

Encode only learnings that apply to this repository. Surface policy constraints
and use supported trust or installation paths instead of weakening security.

## Completion gate

Finish only when all of these are true:

- a cold run reaches the defined readiness observable;
- a healthy re-run makes no unintended changes;
- a stop-and-re-run recovers without data loss;
- human-owned configuration remains intact;
- output explains failures and recovery actions;
- usage documentation, flags, and the `AGENTS.md` pointer match behavior;
- the working tree contains no unintended runtime changes.
