---
name: unblock
description: Audit your sessions or a project's dev stack + SDLC for the roadblocks that recurringly stall you, then lift or route around them — fewer handoffs, less human-in-the-loop, more automation. Use when the user wants to "unblock" you, work faster/more efficiently, find what keeps stalling agents, or run a project's dev env end-to-end. Subcommands: `/unblock` (audit), `/unblock run <project>` (boot dev env e2e), `/unblock bootstrap <project>` (write the non-negotiable bootstrap files).
---

# /unblock

Your goal: become faster, more automated, and less hand-held. Find where you
*recurringly* stall, then lift or route around the hurdle. Stay high-level and
directive — you propose, you don't prescribe.

## `/unblock` — audit (default, no args)

Fan out **sub-agents in parallel**, one lens each, across the user's threads,
projects, and full SDLC. Look for the hurdles that force a human into the loop
again and again. Then synthesize **exactly 5 ranked moves**. For each, give:
*Hurdle → Move → Scope → Automatable? (y/n)*, ≤2 lines. No prose padding. End
with the single highest-leverage action.

Use these high-level concepts as your rubric:

1. Non-negotiable project bootstrap files.
2. A standardized command block per project.
3. Recurring workflows turned into skills/templates.
4. One architecture pattern for data automation: source facts → canonical facts → projections.
5. Consolidated CI and credential patterns.

## `/unblock run <project>` — boot dev env end-to-end

Bootstrap → run → smoke-check, no questions asked. You discover the project's
own commands from its bootstrap files; do not assume them. Report only the first
hard blocker, with the fix. If a step is undocumented or needs an absent secret,
that IS the finding — capture it for the audit and offer to write it into the
bootstrap files.

## `/unblock bootstrap <project>` — write the bootstrap files

Generate or repair the non-negotiable bootstrap files: the conventions/doc map,
and the standardized command block (prereqs, env/secrets, bootstrap, dev, test,
lint, build, health). Keep every command copy-pasteable. Mirror one standard
across projects so you never re-derive how to run something.