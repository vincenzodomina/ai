---
name: challenge-codebase
description: Challenge implemented features and PRD requirements for simplification. Use only when asked for.
---

Challenge current requirements and implementation, especially accumulated compromises and stale implementation choices. Be bold: Find the lowest-cost ways to make the system materially smaller by proposing substantial refactors, narrower scope or deletion while preserving core product goals.

Review only: report in chat; leave files, configuration and Git state unchanged.

1. **Establish baseline.** Ground the scope and core goals in the conversation, PRD and relevant domain docs/ADRs. Check prior architecture findings and implementation plans against current code, callers and tests. Distinguish shipped behavior, implemented but unreleased behavior, and unbuilt plans.

2. **Challenge cost.** Look for:
   - Private files, wrappers and duplicated logic that can collapse behind the existing public Interface.
   - Parallel tooling, unused configuration and speculative extension paths.
   - Features, inference passes, compatibility breadth and PRD invariants whose complexity or operational cost outweighs their value.

   Propose precise PRD wording changes or deletion where scope should change. Reopen prior user decisions or ADRs when warranted, and make the resulting product decisions explicit. Judge current value independently of sunk implementation cost.

3. **Apply deletion test.** Trace consumers to establish what code and behavior would disappear. Distinguish fewer files, fewer lines and lower operational complexity; moving code is not a net reduction, and deferring unbuilt features saves only future work. Label estimates and overlapping savings. Identify effects outside the target, including shared callers, schemas/migrations, dependencies, deployment and downstream behavior.

4. **Rank findings.** Favor substantial net reduction for low effort and acceptable capability loss. Separate behavior-preserving refactors from feature/requirement sacrifices:

   | Rank | Proposed change and code evidence | Expected reduction | Effort | Behavior lost / PRD or ADR affected | Scope outside target | Recommended action and why |
   |---|---|---|---|---|---|---|

   Use Low/Medium/High effort and Recommend/Conditional/Keep actions. Link files and requirement identifiers; state uncertainties affecting the recommendation. Include tempting cuts worth rejecting when their cost explains the recommendation.

