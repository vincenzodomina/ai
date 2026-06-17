# RLS and Auth Testing

Row-Level Security correctness is the most consequential database invariant in a Supabase project — a bad policy is a data leak. pgTAP can validate both the policy *metadata* and the *behavior*; the behavior tests are the ones that matter.

## The four corners every RLS policy needs

For any policy that gates user-owned data, the test file must cover all four:

1. **Own row visible / writable** — the user can read/write their own data.
2. **Other user's row hidden / blocked** — a second user can't see or mutate.
3. **Anonymous request blocked** — `anon` role gets nothing.
4. **Service role bypass intact** — `service_role` (or migrations) can still mutate everything.

Skipping any one leaves a class of bugs uncovered. (1) and (3) tend to be obvious; (2) is the leak; (4) catches "fixed the leak by breaking everything".

## Impersonating a user inside a transaction

Supabase RLS reads `auth.uid()`, which is derived from the JWT claims attached to the session. In a pgTAP test you set those manually:

```sql
BEGIN;
SELECT plan(N);

-- seed two users
DO $$
DECLARE
    v_alice uuid := pg_temp.seed_user('alice');
    v_bob   uuid := pg_temp.seed_user('bob');
BEGIN
    PERFORM set_config('test.alice', v_alice::text, true);
    PERFORM set_config('test.bob',   v_bob::text,   true);
    -- seed Alice's note
    INSERT INTO public.note (user_id, body) VALUES (v_alice, 'secret');
END $$;

-- Become Alice
SET LOCAL role authenticated;
SET LOCAL "request.jwt.claim.sub" = current_setting('test.alice');

SELECT isnt_empty(
    $$ SELECT 1 FROM public.note $$,
    'alice can read her own note');

-- Become Bob
SET LOCAL "request.jwt.claim.sub" = current_setting('test.bob');

SELECT is_empty(
    $$ SELECT 1 FROM public.note $$,
    'bob cannot see alice''s note');

-- Anonymous
RESET role;
SET LOCAL role anon;
RESET "request.jwt.claim.sub";

SELECT is_empty(
    $$ SELECT 1 FROM public.note $$,
    'anon cannot see any note');

-- Back to a privileged role for cleanup-by-rollback
RESET role;
SELECT * FROM finish();
ROLLBACK;
```

Key points:

- `SET LOCAL` is **transaction-scoped**, so `ROLLBACK` reverts both the role and the JWT claim. No teardown needed.
- The fully-qualified setting name is `request.jwt.claim.sub` — must be quoted because of the dots.
- `RESET role` *must* come before changing `request.jwt.claim.sub` to a fresh value if you flipped roles, otherwise some queries error on type mismatches.
- For full claims (e.g. role-based authorization), use `request.jwt.claims` (JSON) instead of individual `request.jwt.claim.<key>` settings:
  ```sql
  SET LOCAL "request.jwt.claims" = '{"sub":"<uuid>","role":"authenticated","app_metadata":{"role":"admin"}}';
  ```

## Negative tests must use `is_empty` and `throws_ok`, not silence

A common mistake — and a real source of leaks — is asserting that the *count* dropped instead of asserting that the *result is empty*:

❌ Bad: `SELECT cmp_ok((SELECT count(*) FROM …), '<', 5, 'fewer rows visible')`
✅ Good: `SELECT is_empty($$ SELECT 1 FROM … WHERE id = '<other-user-id>' $$, 'other user invisible')`

The bad form passes when the leak rate is "only one row" — which is still a leak.

## Mutation tests: blocked vs. silent no-op

UPDATE without a SELECT policy returns 0 rows but raises no error. Test both:

```sql
-- Bob tries to update Alice's note
SET LOCAL "request.jwt.claim.sub" = current_setting('test.bob');

-- Mutation must succeed at the SQL level (no RAISE) but affect zero rows.
DO $$
DECLARE v_count int;
BEGIN
    UPDATE public.note SET body = 'pwned' WHERE user_id = current_setting('test.alice')::uuid;
    GET DIAGNOSTICS v_count = ROW_COUNT;
    PERFORM set_config('test.affected', v_count::text, true);
END $$;
SELECT is(current_setting('test.affected')::int, 0, 'bob update touches 0 rows');

-- And the row content is unchanged from Alice's perspective.
SET LOCAL "request.jwt.claim.sub" = current_setting('test.alice');
SELECT is(
    (SELECT body FROM public.note),
    'secret'::text,
    'alice''s note unchanged');
```

This catches the policy that *seemed* to work because Bob's UPDATE didn't error — but actually allowed the write because the SELECT clause was missing.

## Metadata-only policy tests

These don't exercise behavior but catch drift in policy *definitions*. Useful as a fast tripwire alongside the behavior tests above.

```sql
SELECT policies_are(
    'public', 'note',
    ARRAY['note_owner_select', 'note_owner_modify'],
    'note has exactly two policies');

SELECT policy_cmd_is('public', 'note', 'note_owner_select', 'SELECT', 'select policy is for SELECT');
SELECT policy_roles_are('public', 'note', 'note_owner_select', ARRAY['authenticated'], 'select restricted to authenticated');
```

## Common gotchas

1. **Tables in `public` exposed via the Data API can be reachable by `anon`/`authenticated` even without policies.** Always test the anonymous corner — `is_empty` for SELECT, `throws_ok` for INSERT.
2. **Views bypass RLS by default.** In Postgres ≥15, create them `WITH (security_invoker = true)`. Your test must run as `authenticated` and assert the view honors the underlying policy.
3. **`UPDATE` requires a `USING` clause that matches a `SELECT` policy** — otherwise `UPDATE` silently affects 0 rows. The mutation-attempt test above catches this.
4. **`auth.uid()` returns NULL when JWT claim is unset** — meaning policies of the form `user_id = auth.uid()` allow rows where `user_id IS NULL`. Test by seeding a row with `NULL` user_id and asserting it's not visible to a real user.
5. **`SECURITY DEFINER` functions bypass RLS.** Test that:
   - the function is the only intended bypass (audit the schema)
   - the function itself enforces equivalent authorization (e.g. early `IF auth.uid() != p_target_user THEN RAISE …`).

## Service-role and migration tests

Tests that run as the test runner are typically already on a privileged role. To explicitly test service-role behavior:

```sql
SET LOCAL role service_role;
SELECT lives_ok(
    $$ INSERT INTO public.note (user_id, body) VALUES ('…', 'admin write') $$,
    'service_role bypasses RLS');
```

Don't forget to restore an authenticated role for the next assertion.
