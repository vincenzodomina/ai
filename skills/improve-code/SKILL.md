---
name: improve-code
description: Gated code-improvement workflow. Walk recently written or changed code through a sequence of focused quality gates before finalizing or merging it. Each gate covers one improvement domain, has explicit PASS/FAIL criteria, and keeps its full rules in its own reference doc. Use when improving, cleaning up, or doing a maintainability pass on code, or to apply one domain (e.g. only Simplicity or only Comments) to a diff. Active domains, Simplicity (smallest correct implementation; remove accidental complexity) and Comments (intent, contracts, why-not-what, and where non-code context belongs). Planned, Magic Strings and more. For architecture-level refactoring, use improve-codebase-architecture instead.
metadata:
  short-description: Improve code as a sequence of focused PASS/FAIL quality gates, one domain each.
---

# Improve Code

## Core Principle

Improving code is not a vague "make it nicer" pass. It is a **sequence of gates**.

Each gate isolates **one** improvement domain, defines what PASS and FAIL look like for that domain, and keeps its detailed rules in its own reference doc. You walk the changed code through each gate in order. A gate is either **PASS** (the domain is satisfied) or **FAIL** (there is concrete work to do before the change is done).

This keeps improvement work:

- **focused** — one domain at a time, not a sprawling rewrite
- **reviewable** — each gate produces a clear PASS/FAIL with specific findings
- **extensible** — new domains become new gates without disturbing existing ones
- **bounded** — gates operate on the diff/changed surface, not the whole repo

The goal is **higher-signal code**: smaller, clearer, harder to misuse, cheaper to maintain — not more code and not more comments.

---

## Use This Skill When

- finishing a change and you want a deliberate improvement pass before review or merge
- improving or cleaning up recently generated or recently edited code for maintainability
- a reviewer asked for an "improvement", "cleanup", "polish", or "maintainability" pass
- you want to apply one specific domain (for example, only Simplicity, or only Comments) to a diff

## Do Not Use This Skill When

- behavior is still exploratory and the design is not settled yet
- the task needs an **architecture-level** redesign — use `improve-codebase-architecture` instead; gating local quality would disguise the bigger decision
- there is no recent change to improve and the request is unrelated to code quality

---

## Scope

By default, run gates over the **changed surface**: the current diff, the files you just wrote, or the range the user pointed at. Do not expand a focused improvement into a whole-repo sweep unless the user explicitly asks for it.

Each gate is a single **improvement domain** with its own reference doc. Walk them in registry order: shape the code first (Simplicity), then document the result (Comments), then the remaining domains. Simpler code passes the later gates more easily.

---

## The Gate Workflow

```text
                 Changed code (diff / recent edits)
                              │
                              ▼
        ┌─────────────────────────────────────────────┐
        │ GATE 1: SIMPLICITY  → references/simplicity.md│
        │ Smallest correct implementation; remove       │
        │ duplication, dead branches, over-defensive    │
        │ logic, and speculative abstractions.          │
        │ Evaluate → fix → PASS / FAIL                   │
        ├─────────────────────────────────────────────┤
        │ GATE 2: COMMENTS    → references/comments.md  │
        │ Intent, contracts, why-not-what, docstrings,  │
        │ and where non-code context lives.             │
        │ Evaluate → fix → PASS / FAIL                   │
        ├─────────────────────────────────────────────┤
        │ GATE 3: MAGIC STRINGS  (planned)              │
        ├─────────────────────────────────────────────┤
        │ GATE n: ...            (planned)              │
        └─────────────────────────────────────────────┘
                              │
                              ▼
                 All gates PASS → improvement complete
```

### How to run a gate

For each active gate, in order:

1. **Open the gate's reference doc.** It holds the full criteria, examples, and the gate checklist. Do not run a gate from memory; the reference doc is the source of truth.
2. **Evaluate the changed code against the gate checklist.** List concrete findings, each tied to a `file:line`.
3. **Fix the violations** (or, where a fix needs a wider decision, mark it **Escalate** and say why).
4. **Record the verdict** — `PASS` or `FAIL` — with the findings and what you changed.
5. **Move to the next gate.** Only declare the work complete when every active gate is `PASS` (or its remaining items are explicitly escalated).

A gate that finds nothing is a valid, fast `PASS`. Say so plainly rather than inventing churn.

---

## Gate Registry

| # | Gate (domain) | Status | Concern | Reference |
| --- | --- | --- | --- | --- |
| 1 | Simplicity | **Active** | Smallest correct implementation; remove accidental complexity, duplication, over-defensive logic, and speculative abstractions | [references/simplicity.md](references/simplicity.md) |
| 2 | Comments | **Active** | Comments and docstrings carry intent/contracts/why, not noise; non-code context lives in the right layer | [references/comments.md](references/comments.md) |
| 3 | Magic Strings | Planned | Unnamed literals (strings, numbers, keys) that should be named constants/enums/config | _to be added_ |

Default policy: **each improvement domain is its own gate, on by default.** When a gate is added, it is part of the standard sweep unless the user opts out of it for a given run.

---

## Gate 1: Simplicity (summary)

Full rules and the gate checklist: **[references/simplicity.md](references/simplicity.md)**.

The model the gate enforces (Bill Atkinson's "-2000 lines"):

> **Progress is not measured by how much code was added. It is measured by how much unnecessary complexity was removed while preserving or improving behavior, clarity, and performance.**

This gate FAILS when, in the changed code, any of the following are true (non-exhaustive — see the reference):

- the same problem is **solved more than once** (duplicated branches, repeated normalization/parsing, near-identical helpers)
- **over-defensive logic** guards impossible or already-validated states (redundant null checks, fallbacks for impossible states, catch-all recovery)
- **speculative abstractions** exist without real reuse (single-use wrappers, pass-through layers, one-strategy factories, unused extension points)
- control flow is needlessly **branchy or stateful** where early returns / one canonical representation would do
- the interface is **broader or easier to misuse** than the use case requires (boolean mode flags, multi-shape returns, leaking internals)
- the change is **longer without being clearer**

It PASSES when the result is the **smallest correct implementation** that fits the surrounding codebase, with clear behavior, explicit contracts, low duplication/branching, and a narrow interface. Default bias: **Delete → Merge → Simplify → Add.**

---

## Gate 2: Comments (summary)

Full rules and the gate checklist: **[references/comments.md](references/comments.md)**.

The one-line model the gate enforces:

> **Code says what happens. Names and types say what things are. Tests say what must stay true. Comments and docs say why, when, and what can go wrong.**

This gate FAILS when, in the changed code, any of the following are true (non-exhaustive — see the reference):

- a comment **restates the code** or compensates for a bad name instead of fixing the name
- a public module / class / function / method / CLI entry point lacks a docstring of its **contract** (side effects, raised exceptions, idempotency, units, security/concurrency expectations)
- a **non-obvious "why"** is missing at a danger point (security ordering, library quirk, performance trade-off, deliberate "ugly" code, an invariant that must not break)
- there are **vague TODOs**, commented-out code, changelog/author history, or emotional notes ("hack", "do not touch", "for performance" with no concrete reason)
- paragraphs of architectural rationale are wedged into a code comment instead of an **ADR/design doc** with a short pointer from the code

It PASSES when comments and docstrings are **necessary, local, specific, verifiable, and non-duplicative**, and when context that the code cannot carry lives in the right layer (comment, docstring, test, ADR, or docs).

---

## Output Requirements

When acting under this skill, report per gate:

1. **Gate** name and **verdict** (`PASS` / `FAIL`).
2. **Findings** — each as `file:line` + the concrete problem (skip for a clean PASS, just say it's clean).
3. **Fixes applied** — what you changed and why.
4. **Escalations** — anything that needs a wider decision (e.g. "this rationale belongs in an ADR", "this needs an architecture change"), left for the user.
5. **Net effect** — when relevant, lines/branches/comments removed vs added; improvement should usually trend toward less code and less noise.

If no gate has anything to do, say so explicitly instead of forcing changes.

---

## Adding a New Gate

The skill is designed to grow one gate at a time (Magic Strings is next). To add a gate:

1. Create `references/<gate-name>.md` as the gate's source of truth. Mirror the existing reference structure: **Purpose → Principle → What good/bad looks like → The Gate (PASS/FAIL checklist) → Review questions → Worked example.**
2. Add a row to the **Gate Registry** table (status `Active`) and slot it into **The Gate Workflow** diagram in order.
3. Add a short in-`SKILL.md` summary section (like "Gate 2: Comments (summary)") that points to the new reference doc.
4. Keep the gate **single-domain**. If it starts covering two unrelated concerns, split it into two gates.

---

## Final Standard

A change has passed improvement when every active gate is `PASS`: the code is the smallest correct implementation, its comments and docs are signal rather than noise, and the context a future maintainer needs lives where they will actually find it.
