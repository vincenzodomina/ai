# Env-file wiring rules

Goal: produce complete, coherent `.env` files that let the whole system boot —
without ever corrupting a value a human set.

## The source of truth is the running service
A started service tells you its real local credentials. Read them from it, do not
invent them:
- Supabase CLI: `supabase status -o env` → API URL, anon key, service role key,
  DB URL, JWT secret.
- A DB container: the compose file's user/password/port → the connection URL.
- Any service that prints or exposes its local endpoint on start.

Wire the env AFTER the service is up, so the values are real.

## Three write modes — pick per key
1. **Create if missing.** `[ -f .env ] || cp .env.example .env`. Never start
   from empty; the example carries the full key list and comments.
2. **Set from services (always overwrite).** Keys whose correct local value is
   deterministic and service-derived: `DB_URL`, `SUPABASE_URL`, anon/service
   keys, service host/port. Re-running yields the same value, so this stays
   idempotent.
3. **Fill only when blank (never clobber).** Everything a human might set —
   secrets, real API keys, and boot-crash placeholders. If the line has a
   non-empty value, leave it. Only write when the value is empty or the key is
   absent.

```python
# mode 3: fill-if-blank
m = re.search(rf'^{re.escape(k)}=(.*)$', env, re.M)
if not m:                      env += f'\n{k}={v}'        # add missing
elif not m.group(1).strip():   env = set_line(k, v)       # fill blank
# else: a value exists — DO NOT TOUCH
```

## Boot-crash placeholders
Some apps construct service clients eagerly at startup and throw on an empty key
(e.g. an email/payments/auth SDK). The app then cannot boot at all. Write a
harmless placeholder for those — **only when blank** — so `start` succeeds; the
feature stays inert until a real key is pasted. Find them by running the app and
reading the boot error (see gotchas.md), not by guessing.

## Multiple apps / repos
Wire each app's own `.env` (API and frontend often differ: server keys vs
`NEXT_PUBLIC_*`, DB URL vs API base URL). Point the frontend at the local API;
point both at the local auth/service endpoints.

## Never
- Never commit a wired `.env` (they are gitignored; they hold local secrets).
- Never overwrite a set value on re-run — verify by wiring twice and diffing.
- Never leave a required key blank if a running service can supply it.
