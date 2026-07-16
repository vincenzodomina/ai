---
name: write-env-setup
description: >-
  Author, curate, or repair a repo's local-environment bootstrap script — one
  idempotent, maintenance-grade script that takes a blank machine OR a re-woken
  sandbox to a fully runnable, end-to-end-testable system: databases, Docker,
  services (Redis, Supabase, workflow SDKs), native build deps, and wired .env
  files. Use when a repo has no setup/bootstrap/onboarding script and needs one,
  when asked to "set up local env" or write a "dev environment script", or when
  an existing setup script needs checking, repairing, or updating.
---

# Write env setup

Produce ONE script that boots a repo's entire local stack end to end — from a
blank machine or a slept sandbox — and re-runs safely as a maintenance tool. The
bar is **a system that actually runs and is ready for e2e / browser / real-key
tests**, not a database that merely starts.

The single most important rule: **you are not done until you have run the script
for real and watched the app boot and serve a request.** Everything else is in
service of that.

## The contract

The finished script must guarantee all of these. Each is testable — verify it,
do not assume it.

1. **Boots to green for real.** After a run, the app process starts and answers
   a request (health endpoint, login, or a rendered page). Setting up the DB is
   not the finish line; the running app is.
2. **Idempotent and maintenance-grade.** Re-running does only what is missing or
   broken. Every step checks current state first and acts only on the delta.
3. **Blank machine AND re-woken sandbox.** First run provisions from nothing;
   later runs on a sandbox whose containers were stopped restart only what is
   down and leave data intact.
4. **Cloud sandbox AND local dev.** No assumption of a pre-provisioned image:
   detect tools, prefer what is on PATH, and cover both apt and brew, both
   `docker compose` (v2) and `docker-compose` (v1).
5. **Fails soft and loud.** No silent or opaque failure. Every stop prints what
   failed, why, and the fix; degradable steps warn and continue. A coding agent
   reading the output mid-run can act on every message.
6. **Wires env without clobbering.** Creates missing `.env` files from running
   services; fills blanks; never overwrites a value a human already set.
7. **Readable by humans and agents.** A step-by-step comment header, numbered
   sections, and one announced action per step.

## Process

Work these in order. Do not skip step 6 — it is where the real requirements are
discovered.

### 1. Map the repo
Read, do not guess. Gather the prerequisite list from:
- `package.json` / `pyproject.toml` scripts (dev, start, migrate, seed, test)
- `docker-compose*.yml`, `Dockerfile` (what services + ports)
- `.env.example` (every var; note which are secrets vs local)
- `prisma/`, `migrations/`, ORM config (how the schema is applied)
- `README`, `CLAUDE.md`, `AGENTS.md` (the canonical "run it locally" steps)
- CI workflow files (the real, working setup sequence)

**Done when** you can name every service, port, migration/seed command, and
external dependency the app needs to boot.

### 2. Define "ready"
Write the end-state as a sentence: which processes run, on which ports, and the
one request that proves it works (e.g. "API on :8000 answers `/health` 204 and
`admin/admin` login returns a JWT; frontend on :3000 renders"). This sentence is
your acceptance test for step 6.

**Done when** "ready" names a concrete, checkable observable.

### 3. Draft from the skeleton
Start from `skeleton.sh` (in this skill folder). Keep its comment header,
`log/ok/warn/die` helpers, numbered section layout, `main()` ordering, and the
resilient repo-locator. Replace the example steps with this repo's real ones.

**Done when** the script has a readable header, the helpers, and one function
per prerequisite, wired into `main()`.

### 4. Make every step idempotent
Each step is `check state → act only on the delta`. Load `reference/idempotency.md`
for the exact patterns (state check, service restart, wake recovery, tool-present
guard).

**Done when** a second run with everything already up prints "already …" for
every step and changes nothing.

### 5. Wire the env files
Create each `.env` from `.env.example` only if absent, then set values from the
running services (a started service is the source of truth — e.g. Supabase CLI
emits URL + keys on `supabase status`). Follow `reference/env-wiring.md`:
create-if-missing, set-known-keys, fill-placeholders-only-when-blank, never
clobber a set value.

**Done when** re-running leaves an already-wired `.env` byte-identical, and a
human-set value survives a run.

### 6. Run it for real and close the discovery loop
Execute the script end to end in the target environment. Then start the app and
check the step-2 observable. When something fails — and it will — read the error,
fix the script, and re-run. Expect to discover, in this loop, things static
reading misses: native build libs, services that crash on a blank key at boot,
CLI telemetry that exits non-zero behind a proxy, health-check races. Load
`reference/gotchas.md` for the ones already catalogued.

**Done when** the script ends green AND the step-2 observable passes against the
running app.

### 7. Prove it is wake-safe
Stop the stack's containers (simulate a slept sandbox) and re-run. Confirm it
restarts only what is down, reports migrations as a no-op, and reaches green
again in seconds — no re-provision, no data loss.

**Done when** a stop-then-rerun ends green and the DB still holds its seed.

### 8. Finalize
Leave a clean working tree (no runtime artifacts as uncommitted files, no
committed local-only tweaks). Confirm the header's usage/flags match the code.

**Done when** `git status` is clean and `--help` matches behavior.

## Repairing an existing script
When a script already exists, do not rewrite blind — **curate**:
1. Run it as-is; record where it fails or does redundant work.
2. Check it against the 7-point contract above; note each gap.
3. Repair the gaps in place, preserving its structure and any working parts.
4. Update the header and flags to match reality.
5. Re-validate with steps 6 and 7 (run for real; prove wake-safe).

**Done when** the existing script satisfies the contract and passes 6 and 7.

## Reference (load on demand)
- `skeleton.sh` — annotated, copy-and-adapt template with the header, helpers,
  idempotent sections, wake-restart, and non-clobbering env writer.
- `reference/idempotency.md` — state-check, restart, and wake-recovery patterns.
- `reference/env-wiring.md` — create/set/fill-if-blank rules; source-of-truth.
- `reference/gotchas.md` — catalogued real-world failures and their fixes.
