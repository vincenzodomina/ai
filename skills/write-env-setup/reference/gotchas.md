# Catalogued gotchas

Real failures that static reading misses. You find these by **running the script
for real and reading the errors** — then you fix the script so the next agent
does not. Add to this list as you meet new ones.

## Native module build failures
`npm install` (or pip) dies compiling a native dep (`canvas` → cairo/pango,
`bcrypt` → a compiler). The cloud image lacks the system libs.
→ Add a best-effort native-deps step: apt-install the libs when apt exists;
warn (do not die) elsewhere so brew users are not blocked.

## App crashes at boot on a blank key
The app compiles and connects to the DB, then dies at startup:
`Missing API key…` / `supabaseUrl is required` / `Missing <X> key`. A provider
is constructed eagerly and throws on empty config.
→ Find every one by rebooting until it starts. Write a placeholder for each,
**only when blank** (env-wiring.md). Confirm the app reaches "started".

## CLI telemetry exits non-zero behind a proxy
A CLI finishes its work but its telemetry client (PostHog, analytics) blocks on
shutdown and returns non-zero when it cannot reach its host — failing an
otherwise-successful command.
→ Export the opt-out (`DO_NOT_TRACK=1`, `<TOOL>_TELEMETRY=0`) for all its calls.

## `docker compose` vs `docker-compose`
The repo's npm scripts call `docker-compose` (v1) but the host only has the
`docker compose` (v2) plugin (or vice-versa).
→ Use a `dc()` shim that picks whichever exists; do not hardcode either.

## Restarting a stopped stack
On a woken sandbox the containers are stopped-but-present. Calling the stack's
`start` may refuse ("start is already running") instead of restarting.
→ `docker start` the existing containers and wait for health; recycle
(`stop && start`) only if that fails. See idempotency.md.

## Egress-proxy blocks a download / self-signed CA
Behind an egress proxy, GitHub-release or CDN downloads may 403, and
`npx`-spawned tools may fail TLS with SELF_SIGNED_CERT_IN_CHAIN.
→ Report a blocked host (policy denial) rather than routing around it. For TLS,
point tools at the proxy CA (`NODE_EXTRA_CA_CERTS`, npm `cafile`, etc.). Prefer a
package-registry install path when the direct download host is blocked.

## Compile-then-fork servers
`nest start` / `next dev` compile, then fork the real `node` process. Killing the
wrapper leaves the child (and its port) alive.
→ Stop by port owner or the child pid, and never `pkill -f <pattern>` when the
pattern also matches your own kill command — it self-terminates the shell.

## Runtime artifacts dirty the tree
A step generates files (`supabase init` → `supabase/`, build output). If tracked,
a per-run mutation re-dirties them.
→ Commit generated config in the state the script expects (so re-runs are
no-ops), or gitignore pure runtime dirs. Keep the working tree clean after a run.

## Health-check races
The DB container is "up" before it accepts connections; migrations then fail.
→ Poll readiness (`pg_isready`, a `select 1`, or the stack's `status`) before the
step that depends on it.

## Verify the app, not the plumbing
A green script that never started the app proves nothing.
→ Boot the app and assert the real observable (health 2xx, a login token, a
rendered page) as the final step / a `--smoke` mode.
