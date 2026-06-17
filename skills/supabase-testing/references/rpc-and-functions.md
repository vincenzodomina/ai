# Testing RPCs and PL/pgSQL Functions

Most Supabase backends concentrate domain logic in PL/pgSQL functions exposed via PostgREST RPC. They are the highest-leverage test target: a single bad function corrupts every caller.

## What to assert about a function

A function's contract has six dimensions. Cover whichever apply, not all six for every function:

1. **Signature** — `function_returns`, `has_function(schema, name, args[])`. Catches accidental signature changes.
2. **Security model** — `is_definer` / `isnt_definer`. A SECURITY DEFINER function in an exposed schema is a security incident waiting to happen.
3. **Volatility** — `volatility_is(...)`. `IMMUTABLE` is load-bearing for index expressions; an accidental `VOLATILE` invalidates them.
4. **Happy path** — `lives_ok` + `is`/`set_eq` on the result.
5. **Error contract** — `throws_ok` for every documented `RAISE EXCEPTION`.
6. **Idempotency** — call twice, assert state didn't drift on the second call.

## Happy-path skeleton

```sql
DO $$
DECLARE v_user uuid := pg_temp.seed_user();
BEGIN
    PERFORM set_config('test.user', v_user::text, true);
END $$;

SELECT lives_ok(
    $$ SELECT public.publish_note(p_user_id => current_setting('test.user')::uuid, p_body => 'hi') $$,
    'publish_note succeeds for new note');

SELECT is(
    (SELECT body FROM public.note WHERE user_id = current_setting('test.user')::uuid),
    'hi'::text,
    'publish_note writes the body');
```

## Error-path skeleton

```sql
SELECT throws_ok(
    $$ SELECT public.publish_note(NULL, 'hi') $$,
    'P0001',
    'user_id is required',
    'publish_note rejects NULL user_id');
```

`throws_ok` arguments:
- `sql` — the call wrapped in `$$...$$`. Must include `SELECT` (or `SELECT * FROM ...` for set-returning functions).
- `sqlstate` — 5-char SQLSTATE. `P0001` is the default for `RAISE EXCEPTION` without a custom code. Pass `NULL` to skip.
- `errmsg` — exact message text. Pass `NULL` to skip. Strongly recommended; without it, *any* error matches.
- `desc` — what the test asserts.

For more flexible matching, prefer `throws_like` (LIKE pattern) or `throws_matching` (regex):

```sql
SELECT throws_like(
    $$ SELECT public.publish_note(…) $$,
    '%scope mismatch%',
    'rejects scope mismatch');
```

## Idempotency

A retry-safe RPC must produce the same end state when called twice with the same inputs. Test it:

```sql
SELECT lives_ok($$ SELECT public.finalize_publish(…) $$, 'first call succeeds');
SELECT lives_ok($$ SELECT public.finalize_publish(…) $$, 'second call succeeds');

SELECT is((SELECT count(*) FROM public.file WHERE id = …), 1::bigint, 'still one row');
SELECT is((SELECT version FROM public.file WHERE id = …), 1, 'version unchanged');
```

The two calls **must** use identical arguments — including any "operation id" / `version_id` / dedup token the RPC takes. If your function uses `INSERT ... ON CONFLICT DO NOTHING / DO UPDATE`, idempotency is part of its contract; assert it.

## Set-returning functions

Use `set_eq` (or `bag_eq` if duplicates count):

```sql
SELECT set_eq(
    $$ SELECT path FROM public.list_workspace_files(p_user_id => '…', p_session_id => '…') $$,
    $$ VALUES ('a.md'), ('docs/b.md') $$,
    'list_workspace_files returns both seeded paths');
```

For more shape, build a temp table of expected values:

```sql
CREATE TEMP TABLE expected (path text, kind text) ON COMMIT DROP;
INSERT INTO expected VALUES ('a.md', 'session'), ('docs/b.md', 'project');

SELECT set_eq(
    $$ SELECT path, kind FROM public.list_workspace_files(…) $$,
    $$ SELECT path, kind FROM expected $$,
    'list_workspace_files: paths and kinds match');
```

## Pure helpers — truth tables

For `IMMUTABLE` / `STABLE` predicates that don't touch tables, write one assertion per row of the input → output table. Each row encodes a *specific* regression, named in the description.

```sql
SELECT ok(
    public.file_in_working_scope(
        pg_temp.mk_file('{"project_id":"22…"}'::jsonb),
        '11…'::uuid, '22…'::uuid, NULL),
    'project-only file in session+project ws -> true (OR-semantics regression)');
```

This style runs in <100 ms and catches the entire class of "I refactored the WHERE clause and broke an edge case" bugs. See repo example: `01_pure_predicates.test.sql`.

`jsonb_populate_record(NULL::public.file, '{...}'::jsonb)` is the trick — it builds a row of the table's type *without* exercising CHECK constraints, which is what you want for predicate-only tests.

## SECURITY DEFINER specifics

SECURITY DEFINER functions execute with the *owner's* privileges, bypassing RLS. The test file must:

1. Verify the flag is intentional: `SELECT is_definer('public', 'admin_op', ARRAY['uuid'], 'admin_op runs as definer');`.
2. Verify the function is **not** in an exposed schema. `SELECT has_schema('private', 'private schema exists');` plus a positive `has_function('private', 'admin_op', …)`.
3. Verify the function enforces its own authorization. Run it as a non-admin user and assert it raises:
   ```sql
   SET LOCAL role authenticated;
   SET LOCAL "request.jwt.claim.sub" = '<non-admin-uuid>';
   SELECT throws_ok(
       $$ SELECT private.admin_op('…') $$,
       NULL, 'forbidden',
       'admin_op rejects non-admin caller');
   ```

## Top-level SELECT vs. PERFORM

pgTAP assertions emit a TAP line *only* from a top-level `SELECT`. This silently fails:

```sql
DO $$ BEGIN
    PERFORM ok(my_func() = 1, 'never emits anything');
END $$;
```

Use `DO` blocks for setup (seeding fixtures, capturing UUIDs into `set_config`), and `SELECT` for every assertion.

## Capturing computed values across statements

`SET LOCAL` is the cleanest way to pass a UUID generated in setup into later assertions:

```sql
DO $$
DECLARE v_user uuid := pg_temp.seed_user();
BEGIN
    PERFORM set_config('test.user', v_user::text, true);
END $$;

-- Then later, anywhere in the same transaction:
SELECT is(
    (SELECT count(*) FROM public.note WHERE user_id = current_setting('test.user')::uuid),
    1::bigint,
    'one note for the seeded user');
```

`set_config(name, value, is_local := true)` is transaction-scoped — `ROLLBACK` discards it.

## Triggers

Triggers are tested *through* the table they fire on:

```sql
INSERT INTO public.note (user_id, body) VALUES ('…', 'hi');
SELECT isnt(
    (SELECT updated_at FROM public.note WHERE …),
    NULL,
    'updated_at trigger populated the column');
```

Plus a metadata check:

```sql
SELECT has_trigger('public', 'note', 'note_set_updated_at', 'updated_at trigger present');
SELECT trigger_is('public', 'note', 'note_set_updated_at', 'public', 'set_updated_at',
    'updated_at trigger calls set_updated_at()');
```

## Volatility correctness

A function used in an index expression or generated column **must** be `IMMUTABLE`. If it later gets relaxed to `STABLE`, the index still exists but stops being usable. Catch it:

```sql
SELECT volatility_is('public', 'normalize_path', ARRAY['text'], 'i',
    'normalize_path stays IMMUTABLE — used by file_logical_path_idx');
```

Volatility codes for `volatility_is`: `'i'` = IMMUTABLE, `'s'` = STABLE, `'v'` = VOLATILE.
