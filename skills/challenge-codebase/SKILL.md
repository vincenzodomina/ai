---
name: challenge-codebase
description: Bold challenging of requirements and current implementation. Use when asked to challenge implemented features or PRD requirements for simplification.
---

Challenge whether the current requirements and implementation still justify their complexity. Revisit accumulated compromises, superseded assumptions and features whose value no longer warrants their cost. Propose substantial refactors, narrower scope or deletion while preserving the main product goals.

Find the lowest-cost ways to make the system materially smaller while preserving its main product goals. Challenge the requirements that create complexity, beyond finding unused code.

Review only. No edits. Report in chat. Leave source, documentation, configuration, dependencies and Git state unchanged.

1. **Establish the baseline.** Identify the target scope and core user goals from the conversation, PRD and relevant domain docs/ADRs. Carry forward prior architecture findings, then check current code, callers and tests. Treat implementation plans as claims to verify; distinguish shipped behavior, implemented but unreleased behavior, and unbuilt plans.

2. **Challenge both implementation and scope.** Look for:
   - Private files, wrappers and duplicated logic that can collapse without widening a Module's public Interface.
   - Parallel tooling, unused configuration and speculative extension paths whose maintenance exceeds their present value.
   - Implemented features, inference passes, compatibility breadth or PRD invariants that could be narrowed, made deterministic or deferred for a worthwhile reduction.
   - Which PRD invariants have the highest cost in terms of code, complexity, and operational burden compared to the value they provide. Propose wording edits or deletion.
   - Revisit low-value PRD requirements and stale implementation decisions accumulated through repeated iteration.
   - include worthwhile proposals that reopen prior user decisions or ADRs. State the evidence, capability lost and decision required; existing implementation is not itself a justification for keeping a feature.

3. **Apply the deletion test.** Trace enough consumers to identify the actual removable code and affected behavior. Distinguish fewer files, fewer lines and lower operational complexity; moving code elsewhere is not a net reduction. Deferring an unbuilt feature saves future work, not current code. Label estimates and overlapping savings. Identify effects outside the target, including shared callers, schemas/migrations, dependencies, deployment and downstream behavior.

4. **Rank the useful findings.** Favor substantial net reduction for low effort and acceptable capability loss. Report behavior-preserving refactors separately from feature/requirement sacrifices, using this table:

   | Rank | Proposed change and code evidence | Expected reduction | Effort | Behavior lost / PRD or ADR affected | Scope outside target | Recommended action and why |
   |---|---|---|---|---|---|---|

   Use Low/Medium/High effort and Recommend/Conditional/Keep actions. Link relevant files and requirement identifiers; state uncertainties that affect the recommendation. Include tempting cuts worth rejecting when their cost explains the recommendation, without padding the table.

End with the smallest recommended package, the essential guarantees to retain, and any product decisions needed before implementation.
