---
name: gap-analysis
description: Review a codebase implementation against a PRD or specification document and produce a structured gap analysis report. Use this skill whenever the user asks to compare code to a PRD, audit implementation completeness, check what's missing vs a spec, do a gap analysis, review implementation against requirements, or assess how much of a design document has been built. Also trigger when the user says things like "what's left to build", "how far along are we", or "does the code match the spec".
---

# Gap Analysis: Code vs PRD

Compare an implementation codebase against a Product Requirements Document (or any specification) and produce a structured, honest assessment of what's done, what's partial, and what's missing.

## Why this approach works

A gap analysis is only useful if it's grounded in both the spec AND the actual code. Reading just the PRD leads to optimistic "yeah that's probably done" assessments. Reading just the code leads to missing requirements entirely. The two-phase approach (read spec first, then exhaustively map the code) forces you to check every claim against evidence.

## Procedure

### Phase 1: Absorb the specification

Read the PRD or spec document completely before touching the codebase. While reading, build a mental inventory of:

- **Numbered requirements** (FR-1, NFR-2, etc.) -- these are your primary checklist
- **Acceptance criteria** -- often buried in a later section, these define "done"
- **Architectural decisions** -- specific technical choices the spec mandates (e.g., "content-addressed storage", "no Git dependency")
- **Data model descriptions** -- table shapes, relationships, access patterns
- **Operational requirements** -- install flow, CI/CD, packaging, deployment
- **Non-functional requirements** -- performance, security, observability
- **"Nice to haves" or "out of scope"** -- track these separately so you can note if any were implemented or still missing
- **Section-level mandates** -- PRDs often have important requirements embedded in prose, not just in numbered lists. Capture these too.

### Phase 2: Map the codebase exhaustively

Use an Explore agent (subagent_type: "Explore", thoroughness: "very thorough") to survey the entire codebase. The prompt should ask for:

- Top-level directory structure
- Every source directory -- all files, their purposes, key exports
- Schema/migration files and what they define
- Package manifests -- dependencies, scripts, bin entries
- Config files (.env.example, tsconfig, etc.)
- Test files (or lack thereof)
- Install scripts, CI/CD configs
- Line counts per component

The reason for using an Explore agent rather than piecemeal Grep/Glob calls: a gap analysis needs the full picture. Piecemeal searching biases you toward finding what you're looking for and missing what you're not. The Explore agent returns a comprehensive map you can cross-reference against every requirement.

### Phase 3: Cross-reference requirement by requirement

Go through every requirement from Phase 1 and find the corresponding implementation evidence from Phase 2. For each requirement, determine:

- **Fully implemented**: Code exists, logic matches spec semantics, edge cases handled
- **Partially implemented**: Code exists but doesn't fully match spec (missing a mode, wrong deletion semantics, missing a trigger, etc.)
- **Not implemented**: No corresponding code found

Important nuances that catch people:
- **"Code exists" is not "requirement met."** Check that the logic matches the spec's semantics. Example: if the spec says "soft-delete for auditability" but the code does hard delete, that's a gap even though delete handling exists.
- **"Functionally equivalent" is worth noting.** If the spec says "HEAD check before upload" but the code handles 409 Conflict instead, note it as "functionally correct but not per-spec" -- it's useful context for prioritization.
- **Check schema against data model descriptions.** Column names, types, relationships, indexes, RLS policies -- these are easy to miss but matter for correctness.
- **Check for denormalization violations.** If the spec says "don't duplicate user_id on child rows", verify that.

### Phase 4: Check beyond numbered requirements

Some gaps hide outside the numbered requirement list:

- **Schema/data model gaps**: columns missing, wrong types, missing indexes, RLS policy mismatches
- **Operational gaps**: no CI/CD, no test suite, missing bucket creation, missing documentation
- **Security gaps**: credential handling, auth boundaries, data protection
- **Observability gaps**: structured logging, metrics, health endpoints

### Phase 5: Produce the report

## Output format

Structure the report exactly as follows. Use markdown tables throughout for scanability.

### 1. Overview paragraph
One paragraph summarizing the codebase size, what's implemented, and the overall assessment.

### 2. Fully Implemented (Green)

| Requirement | Status | Evidence |
|---|---|---|
| **FR-1** Description | Done | [file.ts](path/to/file.ts) -- brief explanation |

Link to actual source files as evidence. Keep evidence column concise.

### 3. Partially Implemented (Yellow)

| Requirement | Gap | Detail |
|---|---|---|
| **FR-5** Description | What's missing | What exists vs what the spec requires |

Be specific about what's done and what's not. "Partial" with no detail is useless.

### 4. Not Implemented (Red)

| Requirement / PRD Section | Gap |
|---|---|
| **PRD section reference** | What's missing and why it matters |

### 5. Schema / Data Model Gaps

| Area | Finding |
|---|---|
| Table or column name | Specific mismatch between spec and schema |

### 6. Operational / Packaging Gaps

| Area | Finding |
|---|---|
| CI/CD, testing, install, infra | What's missing |

### 7. Summary Scorecard

| Category | Coverage |
|---|---|
| Category name | X% -- brief rationale |

Be honest. 0% for testing if no tests exist. Don't inflate numbers to make things look better.

### 8. Recommended Priority Actions

Numbered list, ordered by impact (highest first). Each item should be actionable: what to do, not just what's wrong. Note the effort level (small change vs major work) where possible.

## Guidance on tone

- Be factual, not judgmental. "No tests exist" not "the team neglected testing."
- Distinguish between "not yet done" and "done wrong" -- they have different priorities.
- When something is a spec nice-to-have that's not implemented, say so -- it's lower priority than a core requirement gap.
- If the spec is ambiguous about a requirement and the code makes a reasonable interpretation, note the ambiguity rather than marking it as a gap.
