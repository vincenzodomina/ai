# Fixtures and Isolation

The biggest source of pgTAP flakiness and slow suites is poor fixture hygiene. The right pattern is small, fast, transaction-isolated, and uses `pg_temp` so cleanup is automatic.

## The isolation contract

Every `.test.sql` file is a single connection that does:

```sql
BEGIN;
-- … setup, assertions, finish …
ROLLBACK;
```

`ROLLBACK` is the **only** cleanup mechanism you need. Don't write `DELETE FROM …` teardown blocks. Don't `TRUNCATE`. If a row leaked past `ROLLBACK`, you've called `COMMIT` somewhere and the test is broken.

Implications:

- Sequence values may advance and not roll back (Postgres design). Don't assert specific generated IDs — match by columns *you* set.
- `set_config(..., is_local := true)` is also transaction-scoped. Use it freely to pass values across statements.
- `CREATE TABLE … ON COMMIT DROP` (TEMP tables) is also automatically cleaned up.

## `pg_temp` helpers — the cornerstone

`pg_temp.*` functions live only for the connection. They vanish on disconnect; they roll back to their definition state on `ROLLBACK`. This makes them perfect fixture builders:

```sql
-- _fixtures.sql — included via \ir _fixtures.sql inside each BEGIN

CREATE OR REPLACE FUNCTION pg_temp.seed_user(p_label text DEFAULT 'u')
RETURNS uuid LANGUAGE plpgsql AS $$
DECLARE
    v_id    uuid := gen_random_uuid();
    v_email text := p_label || '_' || replace(v_id::text, '-', '') || '@test.local';
BEGIN
    INSERT INTO auth.users (id, email, role, …) VALUES (v_id, v_email, 'authenticated', …);
    INSERT INTO public.user_profile (id, email) VALUES (v_id, v_email);
    RETURN v_id;
END $$;

CREATE OR REPLACE FUNCTION pg_temp.seed_note(p_user uuid, p_body text)
RETURNS uuid LANGUAGE plpgsql AS $$
DECLARE v_id uuid := gen_random_uuid();
BEGIN
    INSERT INTO public.note (id, user_id, body) VALUES (v_id, p_user, p_body);
    RETURN v_id;
END $$;
```

Why this beats raw `INSERT`:

- Each test gets a fresh user with a unique email — no collisions across tests.
- The `auth.users` row has all the columns Supabase expects NOT NULL; you write that boilerplate once.
- Composing fixtures becomes one line: `v_user := pg_temp.seed_user();`
- You can build complete scenarios fluently in a `DO $$ … $$` block and capture the IDs via `set_config`.

## Loading the helpers

```sql
BEGIN;
\ir _fixtures.sql              -- relative to the test file's directory
SELECT plan(N);
-- …
```

`\ir` is `psql`'s "include relative" — it resolves relative to the current file. The leading underscore on `_fixtures.sql` keeps the test runner from globbing it as a test (the runner picks up `*.test.sql`).

## Capturing IDs across statements

Setup happens inside `DO $$ … $$` (so you can `DECLARE` and call functions); assertions are top-level `SELECT`. To pass a generated UUID from one to the other, use `set_config`:

```sql
DO $$
DECLARE
    v_user uuid := pg_temp.seed_user();
    v_note uuid := pg_temp.seed_note(v_user, 'hi');
BEGIN
    PERFORM set_config('test.user', v_user::text, true);   -- third arg = is_local
    PERFORM set_config('test.note', v_note::text, true);
END $$;

SELECT is(
    (SELECT body FROM public.note WHERE id = current_setting('test.note')::uuid),
    'hi'::text,
    'note exists with body');
```

`current_setting(name)::type` reads it back. The `is_local := true` argument scopes the setting to the transaction — `ROLLBACK` reverts it.

## Predicate-only fixtures: `jsonb_populate_record`

For testing pure predicates on a row type without inserting (and thus without firing CHECK constraints):

```sql
CREATE OR REPLACE FUNCTION pg_temp.mk_file(p_attrs jsonb)
RETURNS public.file LANGUAGE sql AS $$
    SELECT jsonb_populate_record(NULL::public.file, p_attrs)
$$;

SELECT ok(
    public.file_in_working_scope(
        pg_temp.mk_file('{"project_id":"22…"}'::jsonb),
        '11…'::uuid, '22…'::uuid, NULL),
    'project file in session+project ws -> true');
```

This is the fastest possible test pattern — no I/O, no CHECK overhead. Reserve it for `IMMUTABLE` / `STABLE` predicates.

## Avoid these isolation pitfalls

1. **Don't depend on database state outside the transaction.** Other tests, seed data, or migrations may not be present. Every test seeds what it needs.
2. **Don't share state via `pg_temp` *table* across tests.** `pg_temp` schema is connection-scoped — the next test in `pg_prove` runs in a *new* connection. Tables don't survive. Functions are fine because each test recreates them via `\ir`.
3. **Don't assert on `created_at`, `updated_at`, or any `now()`-defaulted column.** Match by user-set columns. If you need temporal assertions, freeze time with a fixture function or assert ranges (`cmp_ok`).
4. **Don't assert on auto-incrementing `bigint` IDs.** Sequences advance globally and don't roll back fully. Use UUIDs, or capture the assigned id immediately:
   ```sql
   INSERT … RETURNING id INTO v_id;
   PERFORM set_config('test.row_id', v_id::text, true);
   ```
5. **Don't `TRUNCATE` or `DELETE FROM` for cleanup.** `ROLLBACK` does it for free. Manual cleanup hides leaks.

## Speed targets

A healthy pgTAP suite finishes in <10 seconds total. Per-file budget:

- Pure-predicate / unit files: <100 ms.
- Integration files with fixtures: <500 ms.
- If a file exceeds 1 s, look for: missing indexes on test columns, accidental cross joins in `set_eq`, redundant fixtures.

Profile a slow file with `EXPLAIN (ANALYZE, BUFFERS)` of its setup query (extracted into a one-shot psql session); the bottleneck is almost always a missing index that production also misses.

## Multi-file fixture sharing

When two test files share fixtures *and* are commonly edited together, factor the helpers into `_fixtures.sql` and `\ir` from both. When they share fixtures *but* evolve independently, duplicate is better than coupled — copy the fixture function into each. The cost of duplication is a small upfront diff; the cost of coupling is one file's edits silently breaking the other.

## Resetting auto-incrementing sequences inside a test

If you must assert on a sequence-driven id, set the sequence at the start of the test:

```sql
SELECT setval(pg_get_serial_sequence('public.task', 'id'), 1, false);
-- now the next inserted task has id = 1 within this transaction
```

`setval` is rolled back by `ROLLBACK` — but other connections may have advanced it in the meantime, so this is brittle. Better: don't assert on the id, assert on what you wrote.
