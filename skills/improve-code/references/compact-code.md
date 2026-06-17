# Task: Compact Code

## Primary goal:
Reduce code line count and indirection without changing behavior. Favor fewer, denser, coherent functions over many tiny private helpers.

## Working style:
- Prefer inlining small private helpers that are used only once.
- It is fine if the caller becomes a bit busier; do not extract a helper just to keep a function visually short.
- Especially inline thin wrappers around env parsing, simple formatting, path composition, trivial coercions, simple dispatch, and one-time pre/post steps.
- In config/setup code, prefer local parsing inside the main config builder instead of one-use helper functions.
- Avoid introducing new top-level helpers unless they are clearly justified.
- Remove dead private helpers instead of leaving them around.
- Optimize for fewer jumps between definitions, not for “abstraction purity.”
- Prefer readable dense code, not clever dense code.
- Reuse existing project patterns and naming where they already fit.
- Make the smallest effective change; no speculative abstractions, no architecture churn, no workaround-style code.

## Why this matters:
- Optimize for both value and structure: working code is not enough if the shape of the code makes future changes harder.
- Clean code helps both humans and coding agents stay effective; poor structure increases cognitive load, change surface area, bug risk, and long-term cost.
- Agents are context-limited, so disorganized code forces them to read and modify more files than necessary, which degrades quality and increases token cost.
- Prefer changes that keep logic local, reduce unnecessary indirection, and let a future task be completed by reading only a small number of relevant files.
- Clean code should stay readable, simple, modular, and testable; optimize for easier understanding and safer future edits, not just fewer lines.

## Practical guidance:
- When compacting code, improve structure as well as density; do not optimize only for output behavior while making organization worse.
- Follow the style already established in the repo when it is clean and coherent; models pick up local patterns well.
- Keep related logic close together so a future reader or agent can understand and change it without chasing definitions across the codebase.
- Review the final shape critically; compact code is only good if the result is still clean, easy to reason about, and easy to test.

## When to inline:
- The helper is private.
- The helper is used only once.
- The logic is straightforward and local.
- The helper mainly saves vertical space rather than expressing a meaningful reusable concept.

## When to keep a named helper:
- It is reused in multiple places.
- It encodes an important invariant, policy, or safety boundary.
- It isolates recursion, thread/offload boundaries, or nontrivial state-recovery logic.
- It materially improves comprehension of a large control-flow block.
- It contains a long user-facing error message or other content that would make the caller significantly noisier.

## Non-negotiables:
- Preserve behavior exactly.
- Preserve safety checks, path normalization, session/state handling, and clear error behavior.
- Do not delete or weaken important guardrails just to save lines.
- If a helper is kept, it should earn its existence.

## Verification:
- After changes, run the relevant tests.
- Prefer targeted tests first, then broader coverage if the module sits on shared execution paths.
- Ensure the edited module still compiles and passes lint/type checks if applicable.