# Workflow and CI

How to scaffold, run, and integrate Supabase database tests into CI.

## Local prerequisites

- Supabase CLI ≥ v1.11.4 (≥ v2.x recommended). Check: `supabase --version`. Upgrade per https://github.com/supabase/cli/releases.
- A running local stack: `supabase start`. The CLI brings up a Postgres + Studio + Realtime + Auth + Storage stack via Docker. Confirm with `supabase status`.
- `pgtap` extension installed in the local DB (handled by `supabase start` if pgtap is declared in `supabase/config.toml` or installed via migration).

If the test runner errors with `extension "pgtap" is not installed`, add it to a migration:

```sql
create extension if not exists pgtap with schema extensions;
```

Best practice: install pgTAP into a dedicated `extensions` schema, not `public`, to keep the public namespace clean.

## Directory layout

The Supabase CLI globs `supabase/tests/**/*.test.sql`. Recommended layout:

```
supabase/
  config.toml
  migrations/
  schemas/
  seeds/
  tests/
    database/
      _fixtures.sql                  # shared pg_temp helpers
      01_pure_predicates.test.sql    # numbered prefix → stable order
      02_lock_key_registry.test.sql
      …
```

The leading underscore on `_fixtures.sql` keeps the runner from picking it up as a test.

## CLI commands

| Command | What it does |
|---|---|
| `supabase test new <name>` | Scaffold `supabase/tests/database/<name>.test.sql`. Saves you remembering the path. |
| `supabase test db` | Run **every** `*.test.sql` file. The default. |
| `supabase test db <file>` | Run one file. Use during authoring. |
| `supabase db reset` | Drop & recreate the local DB and re-run migrations + seed. Run this when fixtures depend on schema changes you just edited. |

`supabase test db` runs each file in its own connection. Tests inside the file share the connection (so `\ir _fixtures.sql` works), but state never leaks across files.

## Direct `pg_prove` (alternative)

If you want richer output during authoring:

```bash
pg_prove -d "postgres://postgres:postgres@localhost:54322/postgres" \
    --ext .sql -r supabase/tests/database
```

Useful flags:
- `-v` verbose (one line per assertion)
- `--lib supabase/tests/database` makes `\ir _fixtures.sql` resolve relative to that dir
- `--directives` shows TODO/SKIP reasons

`supabase test db` is just a wrapper around the same TAP machinery — `pg_prove` is fine to use during local iteration when you need finer control.

## CI: GitHub Actions

```yaml
# .github/workflows/db-tests.yml
name: Database Tests
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: supabase/setup-cli@v1
        with:
          version: latest
      - run: supabase start
      - run: supabase test db
```

Notes:

- `supabase start` boots the full local stack in Docker. Cold start ~30–60 s; warm with the Docker layer cache it's ~10 s.
- Pin the CLI version in CI when you depend on a specific feature; otherwise `latest` is fine.
- For monorepos, add `working-directory: <subdir>` to each step.
- If tests touch `auth` schema (most do, since Supabase ties RLS to `auth.users`), no extra setup is needed — `supabase start` brings that schema up with the right shape.

## Common failure modes and fixes

| Symptom | Cause | Fix |
|---|---|---|
| `extension "pgtap" is not installed` | pgtap not in any migration | Add `create extension pgtap with schema extensions;` to a migration; rerun `supabase db reset`. |
| TAP output stops mid-test, no error | Assertion ran inside `PERFORM` in a `DO` block | Convert to top-level `SELECT`. |
| `Number of tests planned: N, ran: M` | `plan(N)` doesn't match assertion count | Update `plan()` or use `no_plan()` while iterating. |
| Same row appears across runs after refactor | Test calls `COMMIT` somewhere (often inside a fixture function) | Remove the COMMIT; rely on outer `BEGIN/ROLLBACK`. |
| `\ir: file not found` | `pg_prove` invoked from a directory other than the test file's | Pass `--lib supabase/tests/database` or `cd` into it before running. |
| Hung test, no output | Likely awaiting a `LOCK` (probably on a row from a prior test that didn't roll back) | `supabase db reset`; investigate any `COMMIT` calls in test code. |
| Tests pass locally, fail in CI | Time-zone or `now()` drift | Make assertions tz-agnostic; never assert on raw timestamps. |
| `current_setting("test.…")` returns NULL | Forgot `is_local := true`, OR earlier `RESET` cleared it | Always pass `true` as third arg; don't `RESET ALL` mid-test. |

## Iteration loop while authoring

1. `supabase start` (once, leave running).
2. Edit `supabase/tests/database/04_<name>.test.sql`.
3. `supabase test db supabase/tests/database/04_*.test.sql` — fast inner loop.
4. When green, run the whole suite: `supabase test db`.
5. If any earlier test broke because of a new fixture entry, that's a sign your fixture file is being edited in two places and they've drifted; fold them into one definition.

## Migrations and tests interact

When you change schema, two things must happen before tests pass:

1. Re-run the migration locally: `supabase db reset` (drops & recreates the DB, runs every migration in order, applies seed).
2. Update test fixtures if column shapes changed.

Don't skip step 1 — `supabase test db` on its own does **not** re-apply migrations; it runs against whatever schema currently exists in the local DB.

## Performance budgets

For a healthy suite:

- Whole suite: <10 s.
- Per file: <500 ms (integration), <100 ms (pure predicates).
- Per assertion: ms-range. If one assertion takes >100 ms, the helper it tests has a missing index that production also lacks — fix the production query first.

`supabase test db` doesn't print timings by default. Use `pg_prove -v -t 1` style output during investigation.

## CI gating

For a database PR:

- Require `db-tests` to pass before merge.
- Require `supabase db advisors` (CLI ≥ 2.81.3) or MCP `get_advisors` — catches missing-index, RLS-disabled, definer-in-public-schema warnings before they ship.
- For schemas you ship to production, also require `supabase db diff` to be empty — guarantees migrations capture every schema change.
