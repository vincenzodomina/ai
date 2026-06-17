---
name: write-prd
description: How to write or edit a PRD for the given user request. Use when user wants to write a PRD, create a product requirements document, or plan a new feature.
---

# Write PRD

### Context

1. Asses the user request if he is missing something or is not clear enough.
   --> If the user input is clear, un-ambigous enough, proceed.
   --> If not, mention those points you find and ask for clarification.

### Don'ts

- Do not mention any internal implementation details like database table names or field names or method or variable names.
- Do not mention parts from previous versions of the PRD or implementation. Only the current state is relevant. If necessary or requested, mention it only in a dedicated Decisions section.
- Do not repeat the same facts or information (across sections) if not really necessary. Optimize for brevity and clarity.
- Do not mention non-goals outside of the non-goals section.
- Do not re-write too much at once. Optimize for small, incremental edits for better diff readability and reviewability.
- Do NOT include specific file paths or code snippets. They may end up being outdated very quickly.

### Do's

- Optimize for least amount of edits necessary to bring the PRD up to a new correctness state when editing based on user requests.
- Use clear, concise, and easy to understand language, yet professional and formal.
- Stay high level and abstract. Details are reserved for the separate implementation plan.

<prd-template>
# <title>

## 1. Executive Summary

## 2. Problem Statement

The problem faced, from the user's perspective.

# 3. Scope

## 3.1 Goals

A concise list of the things that are in scope for this PRD.

This section is intended to give a high level overview of the scopes, not to reflect atomic invariants or requirements which belong into the requirements section instead.

## 2.2 Non-Goals

A concise list of the things that are out of scope for this PRD.

This section is intended to clarify the boundary of the goal scopes, not to repeat the inverse of the goals section.

## 3. Constraints

A list of technical/product/architectural decisions that were made that impose and narrow/guardrail the solution space but are distinct from functional requirements, user stories and expected behaviors (separating the "what" from the "how") and should not repeat any information from the requirements section.

This can include:

- The modules that will be used/built/modified
- The interfaces of those modules that will be used/built/modified
- Technical clarifications from the developer
- Architectural decisions
- API contracts
- Specific interactions

# 4. Requirements

## 4.1 <requirements-sub-group-title>

| **FR-1.**  | Description or User Story |

A long, numbered table of user stories. Each user story should be in the format of:

<user-story-example>
As a mobile bank customer, I want to see balance on my accounts, so that I can make better informed decisions about my spending
</user-story-example>

Requirements are meant to be atomic invariants that capture expected functional behavior from the perspective of stakeholders. They should not contain any implementation details or technical clarifications, which belong into the constraints section instead.

## 5. Testing

A list of testing decisions that were made. Include:

- A description of what makes a good test (only test external behavior, not implementation details)
- Which modules will be tested
- Prior art for the tests (i.e. similar types of tests in the codebase)

## 6. Risks and Mitigations

| Risk | Mitigation |
|---|---|
| Risk 1 | Mitigation 1 |
| Risk 2 | Mitigation 2 |
| ... | ... |

## 7. Further Notes (optional)

Any additional specific notes about any feature, functionalities or concepts in dedicated sections, if really necessary and not already sufficiently and clearly covered in the requirements section.

This can include:
- Flows, diagrams, or other visual representations in ASCII art to help the reader understand intents.
- Interactions/dependencies/relationships between requirements.

This section should not duplicate information already covered in the other sections, but rather provide additional context or clarification.

## Appendix A. Glossary

A list of terms and their definitions that are used in the PRD.
The goal is to provide a concise and clear explanation, to consolidate descriptive information in one place and avoid similar terms used for the same meaning.

</prd-template>