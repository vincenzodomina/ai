---
name: supabase-testing
description: "Use when writing, reviewing, or running tests for anything Postgres-related in a Supabase project — database schema, RPCs / SECURITY DEFINER functions, triggers, RLS policies, migrations, extensions. Triggers: pgTAP, supabase test db, .test.sql files, has_table/has_column/results_eq/throws_ok/lives_ok, RLS policy testing, set local role, request.jwt.claim, plan()/finish(), pg_prove."
metadata:
  version: "0.1.0"
  author: vdomina
  date: 2026-05-08
---

# Supabase Testing

Authoritative guide for writing **proper** Postgres-side tests in a Supabase project — schema invariants, PL/pgSQL RPCs, triggers, RLS, and migrations — using **pgTAP** as the test runner and the **Supabase CLI** (`supabase test db`) as the harness.

## Decide first: pgTAP or app-level?

| Concern | Use pgTAP (`.test.sql`) | Use app-level (Vitest / pytest with supabase-js / postgrest) |
|---|---|---|
| Schema shape (tables, columns, FKs, indexes) | ✅ | — |
| PL/pgSQL functions / RPCs / triggers | ✅ | only if the RPC's contract is "what the client sees" |
| RLS correctness for one role at a time | ✅ (via `set local role` + JWT claims) | ✅ (more realistic — actual JWT, network) |
| Storage buckets, signed URLs, blob bytes | — | ✅ |
| Concurrency / isolation level bugs | ❌ pgTAP can't run parallel txns | ✅ (or `pg_isolation_test`) |
| Edge Functions | — | ✅ (Deno test against `supabase functions serve`) |

Default to pgTAP for everything that lives **inside** the database. Pull up to app-level only when the test crosses the DB boundary or needs concurrency.

## File layout & runner

```
supabase/
  tests/
    database/
      _fixtures.sql                  -- shared pg_temp helpers (NOT a test)
      01_<module>.test.sql           -- numbered for stable ordering
      02_<module>.test.sql
      ...
```

- File names **must** end in `.test.sql`. The CLI globs that suffix.
- `_fixtures.sql` (leading underscore) is loaded inside each test via `\ir _fixtures.sql`; the underscore stops the runner from executing it as a test.
- Run everything: `supabase test db` (requires `supabase start` first).
- Run one file: `pg_prove -d postgres://… supabase/tests/database/04_*.test.sql`
- Create a new file via the CLI when you don't want to think about the path:
  `supabase test new <name>` → writes `supabase/tests/database/<name>.test.sql`.

## The canonical test skeleton

```sql
-- Risk: <one line — what regression this catches>
BEGIN;
\ir _fixtures.sql              -- only if this file uses shared helpers
SELECT plan(<N>);              -- exact assertion count

-- ... assertions, each as its own top-level SELECT ...

SELECT * FROM finish();
ROLLBACK;
```

Hard rules:

1. **Wrap everything in `BEGIN; … ROLLBACK;`.** Never `COMMIT` in tests; ROLLBACK is the isolation mechanism.
2. **Each assertion is a top-level `SELECT`.** Calling assertions inside `DO $$ … PERFORM ok(...) $$` discards the TAP line — the test will look like it "passed" but emitted nothing. Use `PERFORM` only for non-assertion setup.
3. **`plan(N)` must equal the actual assertion count.** pgTAP fails the file if they disagree. When in doubt during authoring, use `SELECT * FROM no_plan();` and switch to `plan(N)` once stable.
4. **Lead the file with a `-- Risk:` comment** explaining what regression the file catches. This is the test's reason to exist; without it you can't decide later whether to delete it.
5. **One concern per file, numbered prefix.** Splitting reduces blast radius when one fixture goes stale.

## Assertion families — pick the strongest one available

Always prefer a more specific assertion over `ok(boolean)` — the failure message is dramatically better.

| Family | Use when… | Most useful |
|---|---|---|
| Schema existence | verifying migrations applied a structure | `has_table`, `has_column`, `has_index`, `has_function`, `has_trigger`, `has_extension` |
| Column shape | guarding against drift in types/defaults/nullability | `col_type_is`, `col_not_null`, `col_has_default`, `col_default_is`, `col_is_pk`, `col_is_unique`, `fk_ok` |
| Function shape | RPC contract: signature + volatility + security | `function_returns`, `function_lang_is`, `is_definer`, `volatility_is`, `is_strict` |
| RLS / policy | which roles can do what on a table | `policies_are`, `policy_roles_are`, `policy_cmd_is`, `table_privs_are`, `column_privs_are` |
| Equality | scalar equality with NULL-safe semantics | `is(have, want, desc)` ← **never use `=` for assertions** |
| Pattern | regex / LIKE on text | `matches`, `imatches`, `alike`, `ialike` |
| Result sets | comparing query output | `results_eq` (ordered), `set_eq` (unordered, dedup), `bag_eq` (unordered, with dups), `is_empty`, `isnt_empty` |
| Errors | RPC must raise on bad input | `throws_ok(sql, errcode, errmsg, desc)`, `throws_like`, `throws_matching` |
| Success | RPC must succeed | `lives_ok(sql, desc)` |
| Plain boolean | last resort, when nothing fits | `ok(boolean, desc)` — write a clear `desc` |

Full categorized reference (~250 functions): [references/pgtap-assertions.md](references/pgtap-assertions.md)

## Patterns you will reach for constantly

### 1. Fixtures via `pg_temp` helpers

`pg_temp.*` functions live only for the connection's lifetime — `ROLLBACK` discards them automatically. Put shared inserters in `_fixtures.sql` and `\ir` it inside each `BEGIN`.

```sql
-- _fixtures.sql
CREATE OR REPLACE FUNCTION pg_temp.seed_user() RETURNS uuid LANGUAGE plpgsql AS $$
DECLARE v_id uuid := gen_random_uuid();
BEGIN
    INSERT INTO auth.users (id, email, …) VALUES (v_id, …);
    INSERT INTO public.user_profile (id, email) VALUES (v_id, …);
    RETURN v_id;
END $$;
```

Full template: [assets/fixtures.example.sql](assets/fixtures.example.sql).
Why this beats raw `INSERT` everywhere: [references/fixtures-and-isolation.md](references/fixtures-and-isolation.md).

### 2. Impersonating an authenticated user (RLS tests)

```sql
-- Inside the BEGIN block, before the queries you want to test:
SET LOCAL role authenticated;
SET LOCAL "request.jwt.claim.sub" = '<user_uuid>';
-- ... run the query / RPC as that user ...
RESET role;       -- if subsequent assertions need a different role
```

`SET LOCAL` is scoped to the transaction, so `ROLLBACK` reverts it. Test **all four** of: own row visible, other user's row hidden, write succeeds for own row, write blocked for other's row. See [references/rls-and-auth.md](references/rls-and-auth.md).

### 3. Asserting an RPC's error contract

`throws_ok` matches by SQLSTATE + message; pass `NULL` for either to skip that part.

```sql
SELECT throws_ok(
    $$ SELECT public.finalize_file_publish(NULL, …) $$,
    'P0001',                              -- SQLSTATE (NULL = any)
    'scope mismatch',                     -- exact message (NULL = any)
    'finalize rejects scope mismatch'
);
```

For RAISE EXCEPTION without a custom SQLSTATE, pass NULL for the code and match the message text. See [references/rpc-and-functions.md](references/rpc-and-functions.md).

### 4. Comparing result sets

Pick the right family — getting this wrong hides bugs:

- `results_eq` — order matters. Use only when the query has explicit `ORDER BY`.
- `set_eq` — order doesn't matter, duplicates collapsed. Most common choice.
- `bag_eq` — order doesn't matter, duplicates count. Use when row count is meaningful.

```sql
SELECT set_eq(
    $$ SELECT path FROM public.list_workspace_files(…) $$,
    $$ VALUES ('a.md'), ('docs/b.md') $$,
    'workspace shows both seeded files'
);
```

### 5. Idempotency tests for RPCs that retry

Call the RPC twice with the same inputs; assert state didn't change on the second call. Most publish/upsert pipelines need this — without it, retry storms duplicate rows.

```sql
SELECT lives_ok($$ SELECT public.finalize_file_publish(…same args…) $$, 'second call succeeds');
SELECT is((SELECT count(*) FROM public.file WHERE id = …), 1::bigint, 'still one row');
```

### 6. RAISING the right SQLSTATE

When you want pgTAP to assert on SQLSTATE, raise a custom one in the function:

```sql
RAISE EXCEPTION USING errcode = 'P0001', message = 'scope mismatch';
```

Then `throws_ok(..., 'P0001', 'scope mismatch', ...)` is brittle in the right way — message text changes will fail the test loudly.

## What good test files look like

- 5–25 assertions per file. Beyond that, split.
- Lead with `-- Risk: …`. Name what would silently break without this file.
- Each scenario gets a comment block (`-- Scenario: project-only file in session+project ws`).
- All assertion descriptions end with the *expected outcome*, not the input — readers see the failure description first when something breaks.
- Use `diag(...)` to log values when an assertion involves a computed UUID or generated id, so failures are debuggable from the TAP output alone.

## What to NOT test

These look like good ideas and waste maintenance:

1. **Don't snapshot whole JSON projections.** Assert the keys / specific fields. JSON shape evolves; snapshot tests fail every additive change without catching real regressions.
2. **Don't write one test per function.** Test by *risk*, not by surface area. A pure helper called by 9 RPCs gets one truth-table test; the 9 RPCs share one integration test that confirms wiring. Doing both N×M is duplication.
3. **Don't test concurrency in pgTAP.** It can't run parallel transactions. Use lock-key collision tests (mutual exclusion is *named* correctly) plus app-level integration tests.
4. **Don't paper over flakes with retries.** A pgTAP test that flakes is broken — fix the missing `ORDER BY` or the timing-dependent assertion. If a test flakes twice, delete it.
5. **Don't assert default values you didn't set yourself in a fixture.** Generated UUIDs / `now()` will differ run to run. Match by the columns *you* control.

## Strategy for sizing a test suite

Risk-tier the modules; concentrate tests where blast radius is highest:

- **Tier-1 (silent correctness, security boundaries, mutex correctness)** → integration tests with real fixtures.
- **Tier-2 (set-returning helpers feeding multiple RPCs)** → integration tests, one fixture covering all branches.
- **Tier-3 (pure helpers, projections)** → unit truth-tables, no INSERT.
- **Tier-0 (deleted code, transitively-tested code)** → no tests.

Full risk-scoring framework with worked examples: [references/test-strategy.md](references/test-strategy.md).

## CLI workflow & CI

```bash
supabase start                # Local stack must be running
supabase test db              # Runs every *.test.sql file
supabase test new <name>      # Scaffold a new test file
```

GitHub Actions snippet, CLI version requirements, common failure modes: [references/workflow-and-ci.md](references/workflow-and-ci.md).

## Reference index (load on demand)

- [references/pgtap-assertions.md](references/pgtap-assertions.md) — every pgTAP assertion grouped by purpose
- [references/rls-and-auth.md](references/rls-and-auth.md) — role / JWT impersonation, four-corner RLS coverage
- [references/rpc-and-functions.md](references/rpc-and-functions.md) — testing PL/pgSQL RPCs, errors, idempotency, security definer
- [references/fixtures-and-isolation.md](references/fixtures-and-isolation.md) — `pg_temp` helpers, transactional isolation, fast resets
- [references/test-strategy.md](references/test-strategy.md) — risk-tier framework, what NOT to test, pruning policy
- [references/workflow-and-ci.md](references/workflow-and-ci.md) — Supabase CLI commands, GitHub Actions, troubleshooting
- [assets/template.test.sql](assets/template.test.sql) — starter file
- [assets/fixtures.example.sql](assets/fixtures.example.sql) — `pg_temp` helper template

## Authoritative external sources

- pgTAP — https://pgtap.org/documentation.html
- Supabase database testing — https://supabase.com/docs/guides/database/testing
- pgTAP in Supabase — https://supabase.com/docs/guides/database/extensions/pgtap
- Local testing overview — https://supabase.com/docs/guides/local-development/testing/overview
