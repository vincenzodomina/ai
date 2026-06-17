# Gate 1: Simplicity

Source of truth for the **Simplicity** gate of `improve-code`. Run the changed code through the [gate checklist](#the-gate-passfail) at the end. Everything before it is the reasoning and the worked targets behind those checks.

This gate is a deliberate **simplification pass** over generated or recently edited code, so the final result is smaller, easier to reason about, harder to misuse, cheaper to maintain, and no slower (often faster).

---

## Purpose

Run this gate after code has been drafted, generated, or patched, to:

- simplify AI-generated code before finalizing it
- reduce duplication or repeated logic
- remove over-engineering or speculative abstractions
- tighten contracts and make interfaces easier to understand
- reduce defensive branches that protect impossible or already-validated states
- shrink the public surface area of a module or helper
- improve performance by replacing a complicated approach with a simpler one
- turn a correct-but-noisy implementation into a lean, reviewable change

Skip or soften this gate when the code is intentionally verbose for a real reason — generated schemas, protocol bindings, required framework ceremony — or when removing a guard would weaken a real boundary against untrusted input, external systems, or unstable dependencies.

---

## The Principle

Treat code quality like Bill Atkinson's "-2000 lines" result:

> **Progress is not measured by how much code was added. It is measured by how much unnecessary complexity was removed while preserving or improving behavior, clarity, and performance.**

Prefer **negative code** when it improves the design. The primary objective is the **smallest correct implementation** that satisfies the requirement and fits the surrounding codebase.

Optimize for: clear behavior, explicit contracts, low duplication, low branching and state count, narrow interfaces, maintainable performance, minimal blast radius. Do **not** optimize for cleverness, novelty, or abstraction count.

If you cannot explain why a line, branch, helper, parameter, or abstraction still needs to exist, it is a candidate for removal or consolidation.

---

## The simplification pass

Before finalizing, work through these steps in order:

1. **Restate preserved behavior.** What must remain true after simplification? What user-visible behavior, API behavior, or invariants cannot change?
2. **Identify accidental complexity.** Which parts solve the same problem more than once? Which branches, helpers, options, or layers exist "just in case"? Which abstractions lack enough reuse or leverage?
3. **Tighten the contract.** Decide what inputs are actually valid, where validation belongs, and how to make invalid states harder to represent or pass through.
4. **Delete before adding.** Remove dead code, duplicate checks, wrapper helpers, and redundant transformations first. Only add code if deletion alone cannot achieve the goal.
5. **Collapse to the simplest valid structure.** Fewer branches, fewer mutable states, fewer representations of the same data, fewer public entry points.
6. **Verify behavior.** Re-run the relevant checks, tests, or validations. Confirm simplification did not silently weaken correctness.

Default bias: **Delete → Merge → Simplify → Add.**

---

## Simplification targets

### 1. Duplication (attack first)

Look for repeated condition trees, repeated error mapping, repeated normalization or parsing, repeated data-shape conversion, repeated loops over the same collection, near-identical helpers split only by tiny variations.

Preferred actions: merge the shared path; extract one meaningful helper *only* if it clarifies; normalize data once, then operate on the normalized form; move repeated policy into one well-named boundary. Do not extract helpers that hide important behavior or force readers to jump unnecessarily.

### 2. Over-defensive code

Generated code often adds protection everywhere instead of designing a better contract. Look for: redundant `None`/null checks after a value was already validated; default fallbacks for impossible states; catch-all exception handling with generic recovery; flag combinations that should be disallowed rather than supported; deeply nested guards compensating for unclear data flow.

Preferred actions: validate once at the boundary; make preconditions explicit; fail clearly for invalid usage; remove branches that protect impossible states; reduce optionality the domain does not require.

Keep real boundary checks for: external input, storage and network calls, parsing, security-sensitive operations, concurrency or race-prone behavior.

### 3. Contracts and interfaces

Improve by: reducing argument count; removing boolean flag arguments that encode multiple modes; replacing vague parameter combinations with clearer call shapes; making return values consistent and unsurprising; reducing mutation and hidden side effects; shrinking public API surface to the truly needed entry points; making ownership and lifecycle expectations explicit.

> Can this interface become harder to misuse and easier to read **without** adding machinery?

### 4. Control flow and state

Simplify toward: early returns instead of nested pyramids; one canonical representation of data; fewer mutable accumulators; fewer mode switches; straight-line code where possible; smaller functions with one coherent responsibility.

### 5. Abstractions

Keep an abstraction only when it provides at least one of: meaningful reuse, a cleaner boundary, a clearer domain concept, reduced coupling, safer composition.

Delete or inline abstractions that are: single-use wrappers, pass-through layers, speculative extension points, generic helpers with unclear semantics, strategy/factory patterns with only one real strategy.

### 6. Performance through simplicity

Prefer performance gains from simpler data flow or simpler algorithms: avoid repeated scans when one pass is enough; avoid repeated conversions or allocations; avoid building intermediate structures that are immediately re-walked; choose a simpler algorithm that reduces both code and runtime cost. Do not add micro-optimizations that hurt readability unless the need is established and the trade-off justified.

---

## Anti-patterns to remove aggressively

- single-use helper layers
- boolean flag arguments that switch behavior
- duplicated branch bodies
- premature generic abstractions
- fallback values hiding invalid state
- repeated validation of already-normalized data
- nested conditionals that can be flattened
- "just in case" retries, caches, indirection, or configurability
- comments explaining code that should instead be simplified (then hand the rest to the Comments gate)
- defensive copying or transformation without a real mutation risk
- APIs returning multiple shapes for the same conceptual result

---

## Decision framework

For each notable piece of code, classify it as exactly one of:

- **Keep** — necessary and already simple enough
- **Simplify** — keep the behavior but reduce complexity
- **Merge** — combine with nearby duplicated logic
- **Inline** — remove an unnecessary wrapper or abstraction
- **Delete** — adds no justified value
- **Escalate** — simplification would require a wider design decision (hand to `improve-codebase-architecture`)

Default bias: **Delete → Merge → Simplify → Add.**

---

## The Gate (PASS / FAIL)

Walk the changed code through this checklist. The gate is **FAIL** while any item below is true; fix or escalate each, then re-check.

- [ ] No problem is **solved more than once** — duplicated branches, repeated normalization/parsing/error-mapping, and near-identical helpers have been merged.
- [ ] No **over-defensive logic** guards impossible or already-validated states; real boundaries (external input, I/O, parsing, security, concurrency) still keep their checks.
- [ ] The **contract is tight** — invalid inputs are validated once at the boundary, not re-checked everywhere; invalid states are hard to represent.
- [ ] No **speculative abstraction** without concrete current use — single-use wrappers, pass-through layers, one-strategy factories, and unused extension points are inlined or deleted.
- [ ] Control flow is as **straight as it can be** — early returns over nested pyramids, one canonical data representation, fewest mutable accumulators and mode switches.
- [ ] The **interface is narrow** — minimal arguments, no boolean mode flags, consistent return shape, smallest public surface, no leaked internals.
- [ ] Performance work (if any) comes from **simpler data flow/algorithms**, not readability-hurting micro-optimizations without a demonstrated need.
- [ ] The change is **not longer without being clearer**; the blast radius stayed small (no focused fix turned into a broad rewrite).
- [ ] **Behavior is verified** — relevant checks/tests/validations were re-run and still pass.

A gate run that finds nothing simplifiable is a clean **PASS** — record it and move on without forcing churn.

---

## Review questions

1. What is the single responsibility of this code path?
2. Where is the real boundary that deserves validation?
3. Which checks are duplicated because the contract is weak?
4. Which parameters, modes, or options are not earning their cost?
5. Which helper or abstraction is only moving complexity around?
6. Can the same behavior be expressed with fewer states or branches?
7. Can the interface be narrower and clearer?
8. Can the algorithm become both shorter and faster?
9. Am I preserving boilerplate because it is necessary, or because it was generated?
10. If I had to delete 20% of this code safely, where would I start?

---

## Worked example: collapse over-defensive, duplicated code

Before — duplicated normalization, a fallback for an impossible state, a boolean mode flag, and a nested guard pyramid:

```python
def load_users(rows, validate=True):
    result = []
    for row in rows:
        if row is not None:
            if validate:
                if "email" in row and row["email"]:
                    email = row["email"].strip().lower()
                    name = row["name"].strip() if row.get("name") else "unknown"
                    result.append(User(email=email, name=name))
            else:
                email = row["email"].strip().lower()
                name = row["name"].strip() if row.get("name") else "unknown"
                result.append(User(email=email, name=name))
    return result
```

After — validate once at the boundary, one normalization path, early `continue`, no mode flag:

```python
def load_users(rows: Iterable[RawRow]) -> list[User]:
    users = []
    for row in rows:
        email = (row.get("email") or "").strip().lower()
        if not email:
            continue  # rows without an email are not users; skip at the boundary
        name = (row.get("name") or "unknown").strip()
        users.append(User(email=email, name=name))
    return users
```

Why this passes: duplication merged into one path, the `validate` boolean mode flag is gone, the impossible-`None`-row and missing-field branches collapse into one boundary check, control flow is straight-line, and the interface is narrower — fewer lines, clearer behavior, no lost correctness.

---

## When no change is justified

If no meaningful simplification is warranted, say so explicitly instead of forcing churn. Reject the implementation and keep simplifying only while one of these is true: the code is longer without being clearer; multiple branches encode the same policy; the contract is still ambiguous; a helper hides more than it clarifies; the public interface is broader than the use case requires; the code handles impossible states instead of preventing them; performance work added complexity without a demonstrated need; or the change duplicates patterns the surrounding codebase already solves more simply.
