---
name: setup-env
description: Set up the full local development stack and prove it runs end to end. Use when explicitly requested or required by an explicitly invoked workflow.
---

Bring the project's full local stack up and prove it works **end to end**: every app running and used the way a user would use it.

1. **Run the native path.** Run the project's setup script (`scripts/setup-local-env.sh` or similar) with its documented flags, or follow the repository's setup instructions when no script exists. Done when the native setup completes and its checks pass.

2. **Diagnose before you detour.** When something fails, read the setup output and logs from this and earlier runs. Errors often show up in a later step than the one that caused them, so check that the dependency you suspect fails on its own before replacing it. Done when you can state the root cause in one sentence and point to the output that shows it.

3. **Detour around what's unavailable.** If a download, registry, daemon or runtime is missing, the same thing is almost always reachable another way: a package registry instead of a release page, a mirror for container images, a pinned binary instead of a system package manager, or starting the daemon yourself. Use the version the project pins. If the cause is the project's own code or config, fix it at the source. Behind an egress proxy, use its docs and status output to tell a policy block (report it) from a certificate or config problem (fix it). Then rerun the native setup with the detour in place. Done when the native path completes.

4. **Exercise everything.** Run the existing test suites (unit, integration, end-to-end). Use every app in the monorepo: web, CLI, mobile as web, agents, and each major configuration, including parallel implementations kept during a migration. Drive the web UI in a real browser (Playwright or similar is usually installed) and take screenshots as evidence. Done when every app has been used, every suite has run, and every failure is fixed or explained.

"Blocked" is a conclusion you have to earn: a root cause you identified, detours you tried, and the remaining external dependency or constraint. Report it with that evidence.
