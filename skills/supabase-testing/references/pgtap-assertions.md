# pgTAP Assertion Reference

Every pgTAP assertion grouped by purpose. Source: https://pgtap.org/documentation.html.

Use this file when picking the strongest assertion for a test. Always prefer a specific assertion over `ok(boolean)` — the failure output of `is(have, want, desc)` shows both sides; `ok(have = want, desc)` shows only "false".

## Plan / lifecycle

- `plan(N)` — declare expected assertion count. **Required at the top** unless using `no_plan()`.
- `no_plan()` — skip the count check; useful while authoring.
- `finish()` — emit the trailing TAP plan. Always `SELECT * FROM finish();` at the end.
- `diag(text)` — emit a diagnostic comment to TAP output. Use to log computed values for debuggability.

## Boolean / scalar

- `ok(boolean, desc)` — last resort. Description is the *only* thing the user sees on failure.
- `is(have, want, desc)` — equality with NULL-safe semantics (`IS NOT DISTINCT FROM`). **Default scalar assertion.**
- `isnt(have, want, desc)` — NULL-safe inequality.
- `cmp_ok(have, op, want, desc)` — apply any SQL operator: `cmp_ok(x, '>', 0, 'positive')`.
- `pass(desc)` / `fail(desc)` — unconditional, useful inside conditional logic.
- `isa_ok(value, type, name)` — type assertion.

## Pattern matching

- `matches(text, regex, desc)` — POSIX regex.
- `imatches(text, regex, desc)` — case-insensitive regex.
- `doesnt_match` / `doesnt_imatch` — inverses.
- `alike(text, like_pattern, desc)` — SQL `LIKE`.
- `ialike(text, pattern, desc)` — case-insensitive LIKE.
- `unalike` / `unialike` — inverses.

## Exception handling

- `throws_ok(sql, sqlstate, errmsg, desc)` — assert SQL raises. Pass `NULL` for `sqlstate` or `errmsg` to skip that part. **Both arguments are optional but strongly recommended** — otherwise any error passes.
- `throws_like(sql, like_pattern, desc)` — message matches LIKE.
- `throws_ilike(sql, pattern, desc)` — case-insensitive LIKE.
- `throws_matching(sql, regex, desc)` — message matches regex.
- `throws_imatching(sql, regex, desc)` — case-insensitive regex.
- `lives_ok(sql, desc)` — SQL must execute without raising.
- `performs_ok(sql, ms, desc)` — SQL completes within ms.
- `performs_within(sql, avg_ms, variance, iterations, desc)` — averaged timing.

## Result sets

Pick deliberately — getting this wrong hides bugs.

- `results_eq(sql_a, sql_b, desc)` — **ordered** row-by-row match. Use only when a query has explicit `ORDER BY`.
- `results_ne(sql_a, sql_b, desc)` — ordered inequality.
- `set_eq(sql_a, sql_b, desc)` — **unordered**, duplicates collapsed. Most common choice.
- `set_ne(sql_a, sql_b, desc)`
- `set_has(sql_a, sql_b, desc)` — A is a superset of B.
- `set_hasnt(sql_a, sql_b, desc)` — A and B share no rows.
- `bag_eq(sql_a, sql_b, desc)` — **unordered, duplicates kept**. Use when row count matters.
- `bag_ne(sql_a, sql_b, desc)`
- `bag_has` / `bag_hasnt`
- `row_eq(sql, record, desc)` — single row matches a composite type / record literal.
- `is_empty(sql, desc)` — query returns zero rows.
- `isnt_empty(sql, desc)` — query returns ≥1 row.

The right-hand side of the result-set assertions takes raw SQL as text:

```sql
SELECT set_eq(
    $$ SELECT slug FROM public.skill WHERE user_id = '…' $$,
    $$ VALUES ('alpha'), ('beta') $$,
    'user has both seeded skills'
);
```

## Schema existence — bulk (fail-fast on drift)

These assert *exactly* the named set; anything extra also fails. Use sparingly — they're brittle on growing schemas. Best for locked-down schemas like `auth`.

- `schemas_are`, `tables_are(schema, names[])`, `views_are`, `materialized_views_are`, `sequences_are`
- `columns_are(table, names[])`, `indexes_are`, `triggers_are`, `rules_are`
- `functions_are(schema, names[])`, `roles_are`, `users_are`, `groups_are`
- `types_are`, `domains_are`, `enums_are`, `casts_are`, `operators_are`
- `extensions_are(schema, names[])`, `languages_are`, `tablespaces_are`, `opclasses_are`
- `partitions_are(table, names[])`, `foreign_tables_are`

## Schema existence — individual

Targeted; safe to use widely. Each has a `hasnt_*` inverse.

- Schemas/relations: `has_schema`, `has_table`, `has_view`, `has_materialized_view`, `has_sequence`, `has_relation`, `has_foreign_table`
- Indexes/triggers/rules: `has_index(name)`, `has_trigger(table, name)`, `has_rule(name, relation)`
- Types: `has_type`, `has_domain`, `has_enum`, `has_composite`
- Casts/operators: `has_cast`, `has_operator`, `has_leftop`, `has_rightop`, `has_opclass`
- Roles: `has_role`, `has_user`, `has_group`, `is_member_of`, `is_superuser`
- Languages/extensions: `has_language`, `language_is_trusted`, `has_extension`, `has_tablespace`

## Columns and constraints

- Existence: `has_column(table, col)`, `hasnt_column(table, col)`
- Type: `col_type_is(table, col, type)` — pass canonical `pg_type` name (e.g. `text`, `bigint`, `timestamp with time zone`).
- Nullability: `col_is_null`, `col_not_null`
- Defaults: `col_has_default`, `col_hasnt_default`, `col_default_is(table, col, value)`
- Primary key: `has_pk(table)`, `col_is_pk(table, col)` (single col or `col[]`)
- Foreign key: `has_fk`, `col_is_fk`, `fk_ok(src_table, src_col, ref_table, ref_col)` — preferred, asserts target.
- Unique: `has_unique`, `col_is_unique`
- Check: `has_check`, `col_has_check`
- Index properties: `index_is_unique`, `index_is_primary`, `index_is_partial`, `index_is_type(idx, 'btree' | 'hash' | …)`
- Partitioning: `is_partitioned`, `is_partition_of(child, parent)`
- Inheritance: `is_ancestor_of`, `is_descendent_of`

## Functions / procedures

Use to enforce RPC contracts so a future change to signature/security/volatility fails the test loudly.

- `has_function(schema, name, args[])` — exact-signature match.
- `function_returns(schema, name, args[], return_type)` — assert return type.
- `function_lang_is(schema, name, args[], 'plpgsql' | 'sql' | 'c' | …)`
- `function_owner_is(schema, name, args[], owner_role)`
- `is_definer` / `isnt_definer` — `SECURITY DEFINER` flag.
- `is_strict` / `isnt_strict` — strict (NULL-in → NULL-out).
- `volatility_is(schema, name, args[], 'IMMUTABLE' | 'STABLE' | 'VOLATILE')`
- `is_aggregate`, `is_window`, `is_procedure`, `is_normal_function` — and inverses.
- `can(schema, function_name)` — function callable by current role.

## Row-Level Security & policies

- `policies_are(table, name[], desc)` — exact-set match of policy names on the table.
- `policy_roles_are(table, policy, role[], desc)` — which roles a policy applies to.
- `policy_cmd_is(table, policy, 'SELECT' | 'INSERT' | 'UPDATE' | 'DELETE' | 'ALL', desc)`

For testing the policies' *behavior* (not just metadata), use `set local role` + `set local request.jwt.claim.sub` and run actual queries — see `references/rls-and-auth.md`.

## Privileges

These check `pg_*` catalog state, not behavior. Useful as drift detectors on grants.

- `database_privs_are(db, role, privs[])`
- `schema_privs_are(schema, role, privs[])`
- `table_privs_are(table, role, privs[])`
- `column_privs_are(table, col, role, privs[])`, `any_column_privs_are`
- `sequence_privs_are`, `function_privs_are`, `language_privs_are`
- `fdw_privs_are`, `server_privs_are`, `tablespace_privs_are`

## Ownership

- `db_owner_is`, `schema_owner_is`, `table_owner_is`, `view_owner_is`, `materialized_view_owner_is`, `sequence_owner_is`
- `function_owner_is`, `index_owner_is`, `type_owner_is`, `composite_owner_is`, `language_owner_is`, `opclass_owner_is`, `tablespace_owner_is`, `foreign_table_owner_is`

## Domain / enum specifics

- `enum_has_labels(enum, labels[])` — exact-set match on enum labels.
- `domain_type_is(domain, type)` / `domain_type_isnt`
- `cast_context_is(source, target, 'a' | 'i' | 'e')` — assignment / implicit / explicit cast.

## TODO and skip

- `skip(reason, count)` — skip N upcoming tests. Use *before* the assertion line.
- `todo(reason, count)` — mark as expected-fail.
- `todo_start(reason)` / `todo_end()` — block form.
- `in_todo()` — predicate, useful in conditional setup.

## Utility / introspection

- `pgtap_version()`, `pg_version()`, `pg_version_num()`
- `os_name()`
- `findfuncs(schema, regex)` — list functions matching a pattern (used in `runtests`).
- `do_tap(sql)` — execute SQL and return TAP result.
- `runtests([schema], [pattern])` — discover and run all `test_*` functions returning `SETOF TEXT`. Alternative to script-style files; see https://pgtap.org/documentation.html#xunit.

## Anti-patterns

- ❌ `SELECT ok(have = want, 'desc')` → ✅ `SELECT is(have, want, 'desc')`. NULL-safe and gives useful failure output.
- ❌ `PERFORM ok(...)` inside `DO $$ ... $$` — emits no TAP. Top-level `SELECT` only.
- ❌ `results_eq` without `ORDER BY` — order is unspecified, test is flaky.
- ❌ asserting `count(*)` instead of the rows themselves — passes silently when the wrong rows are present.
- ❌ raw `INSERT` / `RAISE EXCEPTION` outside an assertion — they don't generate TAP, won't be diagnosed by failure output.
