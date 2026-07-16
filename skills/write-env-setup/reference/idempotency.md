# Idempotency & maintenance patterns

The rule for every step: **check current state, act only on the delta, announce
the result.** A second run on a healthy machine must change nothing and print
"already …" for each step.

## State-check gate
Guard each action behind a check so re-runs are cheap:
```bash
if command -v tool >/dev/null 2>&1; then ok "already installed"; return; fi
[ -d node_modules ] && { ok "deps present"; return; }
grep -qE '^KEY=.+' .env && ok "KEY set" || set_it
```

## Service state has THREE cases, not two
`docker ps` lists only *running* containers, so "not running" ≠ "not present".
Handle all three, or a woken sandbox breaks:

| State | Detect | Action |
|---|---|---|
| healthy & running | `svc status` returns 0 | skip |
| present but stopped | `docker ps -a` shows it, status ≠ 0 | **restart** the containers |
| absent / broken | no containers, or restart didn't heal | fresh start (or recycle) |

```bash
if svc status >/dev/null 2>&1; then ok "already running"; return; fi
if docker ps -a --format '{{.Names}}' | grep -q '^svc_'; then
  docker start $(docker ps -aq --filter 'name=svc_') >/dev/null 2>&1 || true
  for _ in $(seq 1 60); do svc status >/dev/null 2>&1 && { ok "restarted"; return; }; sleep 2; done
  svc stop >/dev/null 2>&1 || true      # recycle keeps the data volume by default
fi
svc start || die "svc start failed"
```
Why not just call `svc start`? Some CLIs (e.g. Supabase) refuse to start a
half-up project ("start is already running") — they neither restart nor error
usefully. Restarting the existing containers is faster and preserves data.

`docker compose up -d <svc>` already does the right thing for compose-managed
services (starts if stopped, no-op if up) — use it directly for those.

## Derived vs installed artifacts
- **Installed** (node_modules, apt libs): gate on presence, install once.
- **Derived & cheap** (ORM client generate, codegen): regenerate every run — it
  is idempotent and repairs a pruned/half-built artifact after a wake.
- **Migrations**: `migrate deploy` is a no-op when up to date. `--reseed` does a
  reset first. Seeds must upsert so they re-run clean.

## Efficiency
Skip the expensive thing when its output exists; never re-pull images, re-install
deps, or re-apply migrations that are already applied. A warm re-run should take
seconds, dominated only by the app's own compile/boot.
