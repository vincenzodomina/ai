#!/usr/bin/env bash
# =============================================================================
# setup-local-env.sh — one-shot bootstrap + maintenance for <PROJECT>'s local
# dev/test environment. Takes a blank machine (or a re-woken sandbox) to a fully
# runnable stack: <datastores>, <services>, deps, migrations/seed, wired .env.
#
# Idempotent and fast: every step is a no-op if already done, so re-running is
# cheap and safe — use it as a maintenance script after a sandbox sleeps.
#
# Usage:
#   scripts/setup-local-env.sh [--with-dev] [--reseed] [--clean] [-h]
#     --with-dev   after setup, launch the app with the wired env
#     --reseed     force a clean DB reset + re-seed
#     --clean      remove build output first
#   scripts/setup-local-env.sh --print-env    # sourceable export block
#
# Overridable via env: <TOOL>_VERSION, <REPO>_DIR, ...
# Requires: root (to start dockerd), docker, node/npm (or your runtime), ...
#
# NOTE: document here anything non-obvious a reader must know — e.g. which
# integrations get placeholder keys so the app can boot, which auth is remote.
# =============================================================================
set -euo pipefail

# ---- flags -----------------------------------------------------------------
WITH_DEV=0; RESEED=0; CLEAN=0; PRINT_ENV=0
for arg in "$@"; do case "$arg" in
  --with-dev) WITH_DEV=1 ;; --reseed) RESEED=1 ;; --clean) CLEAN=1 ;;
  --print-env) PRINT_ENV=1 ;;
  -h|--help) sed -n '2,30p' "${BASH_SOURCE[0]:-$0}" 2>/dev/null; exit 0 ;;
  *) echo "unknown arg: $arg" >&2; exit 2 ;;
esac; done

# ---- logging: human- and agent-readable, every action announced ------------
c_b=$'\033[1;36m'; c_g=$'\033[1;32m'; c_y=$'\033[1;33m'; c_r=$'\033[1;31m'; c_0=$'\033[0m'
log()  { printf '\n%s▶ %s%s\n' "$c_b" "$*" "$c_0"; }          # start a section
ok()   { printf '%s  ✓ %s%s\n' "$c_g" "$*" "$c_0"; }          # a step succeeded
warn() { printf '%s  ! %s%s\n' "$c_y" "$*" "$c_0"; }          # degraded, continuing
# die(): only for truly unrecoverable state. ALWAYS say what failed + the fix,
# so an agent reading the output can act. Prefer warn+continue where possible.
die()  { printf '%s  ✗ %s%s\n' "$c_r" "$*" "$c_0" >&2; exit 1; }

# ---- locate repos by MARKER files (resilient to stdin/piped invocation) -----
# Never derive paths from ${BASH_SOURCE} alone — it is empty when piped.
_abspath() { (cd "$1" 2>/dev/null && pwd); }
REPO_MARKER="<path/that/uniquely/identifies/this/repo>"
COMMON_ROOTS=("${HOME:-/root}" /home/user /root /workspace /app /src /srv)
locate_repo() {  # $1=marker $2=override $3..=dir-name candidates
  local marker="$1" override="$2"; shift 2
  local src="${BASH_SOURCE[0]:-}" self="" c root hit name
  [ -n "$src" ] && [ -f "$src" ] && self="$(_abspath "$(dirname "$src")/..")"
  for c in "$override" "$self" "$PWD" \
           "$(_abspath "$(git -C "$PWD" rev-parse --show-toplevel 2>/dev/null)")"; do
    [ -n "$c" ] && [ -f "$c/$marker" ] && { _abspath "$c"; return 0; }
  done
  for name in "$@"; do for root in "${COMMON_ROOTS[@]}"; do
    [ -f "$root/$name/$marker" ] && { _abspath "$root/$name"; return 0; }
  done; done
  for root in "${COMMON_ROOTS[@]}" "$(dirname "$PWD")"; do
    hit="$(find "$root" -maxdepth 4 -type f -path "*/$marker" 2>/dev/null | head -1)"
    [ -n "$hit" ] && { _abspath "$(dirname "$(dirname "$hit")")"; return 0; }
  done; return 1
}
resolve_dirs() {
  log "Locating repos"
  set +e; REPO_DIR="$(locate_repo "$REPO_MARKER" "${REPO_DIR:-}" <repo-name>)"; set -e
  [ -n "$REPO_DIR" ] || die "could not locate <repo> — run from inside it, or set REPO_DIR=/path"
  ok "repo: $REPO_DIR"
}

# ---- portability shims: prefer what exists, cover both worlds ---------------
# docker compose v2 plugin OR docker-compose v1 binary.
dc() {
  if docker compose version >/dev/null 2>&1; then docker compose "$@";
  elif command -v docker-compose >/dev/null 2>&1; then docker-compose "$@";
  else die "no docker compose available — install Docker Compose"; fi
}

# =========================================================================== #
# Each step: CHECK current state → act ONLY on the delta → announce result.
# =========================================================================== #

# 1. A required CLI — install only if absent (respects brew/apt-installed ones).
ensure_cli() {
  log "<tool> CLI"
  if command -v <tool> >/dev/null 2>&1; then ok "already installed ($(<tool> --version|head -1))"; return; fi
  warn "installing <tool>"
  # ... install; on failure, die with the URL/command that failed.
  command -v <tool> >/dev/null 2>&1 || die "<tool> install failed — install it manually and re-run"
  ok "installed"
}

# 2. Docker daemon — start dockerd only if the socket is absent.
ensure_dockerd() {
  log "Docker daemon"
  if pgrep -x dockerd >/dev/null 2>&1 || [ -S /var/run/docker.sock ]; then
    for _ in $(seq 1 30); do docker info >/dev/null 2>&1 && { ok "already running"; return; }; sleep 1; done
  fi
  docker info >/dev/null 2>&1 && { ok "already running"; return; }
  command -v dockerd >/dev/null 2>&1 || die "dockerd not installed"
  warn "starting dockerd"; ( dockerd >/tmp/dockerd.log 2>&1 & )
  for _ in $(seq 1 30); do docker info >/dev/null 2>&1 && break; sleep 1; done
  docker info >/dev/null 2>&1 || die "dockerd did not come up (see /tmp/dockerd.log)"
  ok "dockerd up"
}

# 3. A stateful service (DB/stack) — the CRITICAL wake-safe pattern:
#    healthy → skip; stopped-but-present → restart containers; broken → recycle.
start_stack() {
  log "<service> stack"
  if <service> status >/dev/null 2>&1; then ok "already running"; return; fi
  if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q '^<service>_'; then
    warn "existing stack stopped — restarting its containers"
    docker start $(docker ps -aq --filter 'name=<service>_') >/dev/null 2>&1 || true
    for _ in $(seq 1 60); do <service> status >/dev/null 2>&1 && { ok "restarted"; return; }; sleep 2; done
    warn "restart didn't become healthy — recycling"; <service> stop >/dev/null 2>&1 || true
  fi
  warn "starting (first run pulls images — minutes)"
  <service> start || die "<service> start failed (see output above)"
  ok "stack up"
}

# 4. Native build prerequisites (best-effort; warn on non-apt hosts, don't die).
ensure_native_deps() {
  log "Native build prerequisites"
  <check e.g. pkg-config --exists ...> && { ok "present"; return; }
  command -v apt-get >/dev/null 2>&1 || { warn "install <libs> manually (e.g. brew) if npm/pip build fails"; return; }
  warn "installing <libs> via apt"
  apt-get update -qq >/tmp/apt.log 2>&1 || true
  apt-get install -y -q <libs> >>/tmp/apt.log 2>&1 && ok "installed" || warn "apt failed (see /tmp/apt.log)"
}

# 5. Deps — install only if absent; always (re)generate cheap derived artifacts.
install_deps() {
  log "deps"
  [ -d "$REPO_DIR/node_modules" ] && ok "node_modules present" || { (cd "$REPO_DIR" && npm install --no-audit --no-fund); ok "installed"; }
  (cd "$REPO_DIR" && npm run <generate-client> >/tmp/gen.log 2>&1) || { cat /tmp/gen.log >&2; die "<generate> failed"; }
}

# 6. Env files — create-if-missing; set known keys; fill placeholders only when
#    blank; NEVER clobber a human-owned value. See SKILL.md.
write_env() {
  log "<app>/.env"
  local f="$REPO_DIR/.env"; [ -f "$f" ] || cp "$REPO_DIR/.env.example" "$f"
  # read source-of-truth from the running service, e.g.:  eval "$(<service> status -o env)"
  KEY1="$val1" KEY2="$val2" python3 - "$f" <<'PY'
import os, re, sys
path=sys.argv[1]; env=open(path).read()
known = {k: os.environ[k] for k in ('KEY1','KEY2')}          # always set from services
fill_if_blank = {'SOME_KEY':'local-placeholder'}             # only when empty (boot-crash guards)
for k,v in known.items():
    pat=re.compile(rf'^{re.escape(k)}=.*$', re.M)
    env=pat.sub(f'{k}={v}', env) if pat.search(env) else env+f'\n{k}={v}'
for k,v in fill_if_blank.items():
    m=re.search(rf'^{re.escape(k)}=(.*)$', env, re.M)
    if not m: env+=f'\n{k}={v}'
    elif not m.group(1).strip(): env=re.sub(rf'^{re.escape(k)}=.*$', f'{k}={v}', env, flags=re.M)
open(path,'w').write(env)
PY
  ok "wired <app>/.env"
}

# 7. Migrations + seed — idempotent (deploy = no-op when applied; seed upserts).
init_db() {
  log "migrations + seed"
  [ "$RESEED" = 1 ] && { warn "resetting DB"; (cd "$REPO_DIR" && npx <orm> reset --force); }
  (cd "$REPO_DIR" && npx <orm> migrate deploy) || die "migrate failed — check DB_URL and that the stack is up"
  (cd "$REPO_DIR" && npm run seed) || die "seed failed — see output above"
  ok "migrated + seeded"
}

# 8. Optional SDK/service that needs its own install+state — gate it: no-op with
#    a clear message until it is present (e.g. a workflow SDK planned for later).
provision_optional() {
  log "<optional SDK> — provisioning"
  local marker="$REPO_DIR/node_modules/<sdk>/bin/setup.js"
  [ -f "$marker" ] || { warn "<sdk> not installed yet — skipping (safe no-op)"; return; }
  <run its setup> || die "<sdk> setup failed (see log)"
  ok "provisioned"
}

# 9. Verify: prove the observable from your 'ready' sentence, not just 'it ran'.
verify() {
  log "Verify"
  <check DB reachable> && ok "db reachable" || die "db not reachable"
  <check seeded row/user exists> && ok "seed present" || warn "seed missing"
}

finish() { log "Ready"; cat <<EOF
  <URLs, login, how to start each process, gotchas>
EOF
}

# --print-env: sourceable exports; everything else goes to stderr in this mode.
print_env_block() { printf 'export KEY1="%s"\n' "$val1"; }

main() {
  if [ "$PRINT_ENV" = 1 ]; then resolve_dirs >&2; print_env_block; exit 0; fi
  resolve_dirs
  [ "$CLEAN" = 1 ] && rm -rf "$REPO_DIR/<build-output>"
  ensure_cli
  ensure_dockerd
  start_stack
  write_env
  ensure_native_deps
  install_deps
  init_db
  provision_optional
  verify
  if [ "$WITH_DEV" = 1 ]; then cd "$REPO_DIR"; eval "$(print_env_block)"; exec npm run dev; else finish; fi
}
[ "${SETUP_NO_RUN:-0}" = 1 ] || main
