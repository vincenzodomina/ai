# Test Strategy: Risk-Tiered Suite Design

A test suite that "covers every function" is a waste — most functions are trivial, and one-test-per-function dilutes signal until failures are noise. A test suite *worth* maintaining concentrates on the **specific regressions that would silently corrupt production**.

This file tells you how to decide what to test, what level to test it at, and what to actively *not* test.

## The blast-radius model

For each module, score four dimensions on a 0–2 scale and sum:

| Dimension | 0 | 1 | 2 |
|---|---|---|---|
| **Business criticality** | ergonomic, internal | feature-affecting | data integrity / security |
| **Change risk** | rarely touched | active development | recently refactored |
| **Blast radius** | one caller | a few callers | called by many RPCs / cross-cutting |
| **Observability of failure** | loud (raises) | logged | silent (returns wrong data) |

Sum → tier:

- **Tier-1 (7–8)** — high-leverage integration tests required.
- **Tier-2 (5–6)** — focused integration tests. One fixture covers all branches.
- **Tier-3 (3–4)** — minimal smoke OR no test (covered transitively).
- **Tier-0 (0–2)** — explicitly skipped.

## Pyramid shape

For a Supabase Postgres backend, the pyramid is squat — pgTAP is the affordable level so you can be aggressive there:

```
   App-level integration (Vitest / pytest)         ~minimal — boundary tests only
   ─────────────────────────────────────────
   pgTAP integration (real tables, fixtures)       ← bulk of confidence
   ─────────────────────────────────────────
   pgTAP unit (pure predicates, no I/O)            ← cheapest, broadest tripwire
```

Concurrency, blob storage, and edge functions live above pgTAP — pgTAP can't simulate them.

## Decision protocol — apply to every candidate

Before writing a test, write four sentences:

1. **Behavior change**: what specifically changed or is new.
2. **Primary risk**: the *named* regression this test catches.
3. **Impact if broken**: what user-visible thing breaks; data leak / data loss / silent miscount / loud crash.
4. **Level**: unit / integration / app-level — and why.

If you can't write all four, you don't yet understand the risk well enough to test it. (Often you'll find it should *not* be tested at this level.)

## What deserves a test (in priority order)

1. **Predicates feeding many RPCs** — a wrong WHERE clause in a helper propagates to every caller. Truth-table unit tests, runs in ms, catches whole classes of regressions.
2. **Permission boundaries** — RLS policies, agent capability checks, `SECURITY DEFINER` callers. Failures here are security incidents.
3. **Mutation primitives** — the single function that owns INSERT/UPDATE on a table. Idempotency + scope-match validation.
4. **Lock-key constructors / mutex namespaces** — a typo in a hash key prefix silently breaks mutual exclusion. Collision-resistance tests are cheap and catch corruption that nothing else can.
5. **Error contracts** — every documented `RAISE EXCEPTION`. Use `throws_ok` with both SQLSTATE and message. The brittleness is the point: contract changes must be explicit.
6. **Set-returning helpers** with conditional partition logic — assert *what* is returned, not just *how many*.
7. **Trigger correctness** — generated columns, audit fields, soft-delete cascades.

## What NOT to test (active pruning rules)

1. **Don't unit-test PL/pgSQL whose body is one statement delegating to a tested helper.** Tested transitively. Adding a test here is duplication.
2. **Don't snapshot whole JSON projections.** Assert specific keys. JSON shape evolves; snapshot tests fail every additive change without catching real regressions.
3. **Don't write per-kind tests for kind dispatchers.** One representative-of-each test in the dispatcher's file is enough; per-callsite re-testing is N×M duplication.
4. **Don't test the helper's predicate AND every caller's WHERE clause separately.** Pick ONE level: the helper's truth table (cheapest) plus one integration test that confirms it's wired up. Doing both at every callsite is duplication.
5. **Don't write concurrency tests in pgTAP.** pgTAP can't easily simulate concurrent transactions. Concurrency correctness is asserted by *(a)* lock-key collision tests (mutex correctly named) and *(b)* app-level integration tests with multiple connections. If concurrency bugs slip through both, use `pg_isolation_test` — not pgTAP.
6. **Don't add tests to satisfy a coverage tool.** A schema with 200 trivial helpers and 30+ functions does not need 230+ test files. Aim for ~10–20 files, ~80–150 assertions, focused on the risk matrix above.
7. **Don't assert on default values you didn't set yourself.** `now()`, generated UUIDs, sequence-driven `bigint` ids will differ run to run. Match by user-set columns.

## Pruning policy

When a future change lands:

1. **Look for an existing test file to extend before creating one.** New file only when a genuinely new module is added.
2. **Every PR that adds a test should propose at least one to delete or merge.** If you can't, the new test probably duplicates existing coverage.
3. **Any test that flakes once gets investigated; second flake gets deleted.** No "skip and triage later" — flaky pgTAP tests poison the well.
4. **Snapshot-style assertions that have changed >2× without catching a bug are noise — replace with key-presence assertions or delete.**
5. **When a refactor consolidates N callsites into 1 helper, proactively delete per-callsite tests** and consolidate into helper tests + one integration smoke at the public RPC. Do not keep both.

## File-naming convention

Numbered prefix gives stable runner ordering and reads as a table of contents:

```
01_pure_predicates.test.sql        — fastest tripwire; <100 ms
02_lock_key_registry.test.sql      — mutex correctness
03_<rpc_name>.test.sql             — per-RPC integration tests
…
14_lookup_smoke.sql                — happy-path getters
```

One concern per file. Each file's first comment is `-- Risk: <named regression>` — if the regression isn't named, the file isn't pulling its weight.

## Worked example

**Module**: `finalize_file_publish` — the single insert/update primitive for `public.file`.

| Dimension | Score | Reason |
|---|---:|---|
| Business criticality | 2 | Every workspace mutation flows through here. |
| Change risk | 2 | Recently consolidated (replaced two wrappers). |
| Blast radius | 2 | All higher-level RPCs delegate to it. |
| Observability | 2 | Wrong-scope inserts are silent — file vanishes from its workspace, no error. |
| **Total** | **8** | **Tier-1 → integration test required.** |

Test file: `04_finalize_file_publish.test.sql`. Scenarios:

1. First-time create at session scope.
2. Update existing file at same scope.
3. Idempotent re-finalize (same version_id) returns same row unchanged.
4. Reject scope mismatch → `throws_ok`.
5. Each non-trivial scope path (resource-owned, task-scope).
6. Storage-object-path canonical validation rejects malformed path.

Six scenarios → ~10–12 assertions. One fixture file. Runs in <500 ms. Catches every named regression class for this module without exhaustively re-testing each higher-level RPC.

## When to declare "done"

A module is adequately tested when:

- Every **named regression** in the decision protocol's *Primary risk* line has at least one assertion that catches it.
- The test fails when you mutate the implementation in the relevant way (mutation testing — manually flip `=` to `<>` in the function body and confirm the test goes red).
- The test runs in <500 ms.
- Adding more assertions doesn't decrease the *named* regression class.

Anything past that is decoration.
