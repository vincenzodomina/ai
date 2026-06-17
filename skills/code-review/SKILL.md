---
name: code-review
description: Conduct thorough code reviews with structured feedback on security, performance, quality, and testing. Generates trackable review documents with prioritized issues (critical/required/suggestions) and educational content. Use when reviewing PRs or code changes. Triggers on "review this code", "code review", "review PR".
---

# Code Review Process

Review thoroughly the code pointed at or the recent changes by viewing the latest git commits. Also review how this code is integrated and interacts with the rest of the codebase.

Mindset:
- How would a senior expert approach the intended code?
- Which issues would he spot?
- Which potential problems would he point out?

## Review Preparation

Before starting the review, check for documents to review against:
- Vision/goals documents
- Requirements or user stories
- Technical / Architecture specifications
- Implementation plans
- Style guides / Coding standards / Design documents

Reference these throughout the review to ensure consistency, matching specs, find gaps or deviations and ensure the implementation satisfies stated requirements.

## Review Categories

### 1. Security
Check for:
- Injection vulnerabilities
- Known web attack surfaces (XSS, SQL injection, etc.)
- Authentication and authorization
- Data exposure risks
- Command injection
- Insecure deserialization
- Hardcoded secrets/credentials
- Improper authentication/authorization
- Insecure direct object references
- Input validation and sanitization

### 2. Performance
Check for:
- Obvious performance issues
- N+1 queries
- Missing database indexes
- Unnecessary re-renders (React)
- Memory leaks
- Blocking operations in async code
- Missing caching opportunities
- Large bundle sizes
- Unnecessary computations

### 3. Code Quality
Check for:
- Code duplication (DRY violations)
- Functions doing too much (SRP violations)
- Deep nesting / complex conditionals
- Magic numbers/strings
- Poor naming
- Missing error handling
- Incomplete type coverage
- Unnecessary complexity
- Unnecessary edits
- Brittle code
- Overly defensive code instead of clear boundaries and interfaces
- Fit into the overall architecture and design patterns
- Potential for lean and clean code
- Types/Interfaces defined and used
- Magic numbers and hardcoded values

### 4. Inconsintencies / Unexpected behaviors
Check for:
- Spec / comments mismatch to actual code
- Obvious misconfigurations
- Potential errors in code behavior
- Code resulting in bad user experience
- Typos and Grammar of user facing strings
- Breaking changes documented

## Output Format

1. **Be constructive and educational** - Help developers learn, don't just criticize
2. **Provide context** - Explain why something matters
3. **Show examples** - Code speaks louder than descriptions
4. **Be specific** - Exact files and lines, not vague references
5. **Prioritize correctly** - Not everything is critical
6. **Reference:** Check existing testing documentation to refer to

```markdown
### 🔴 Critical (Must Fix)
- **[File:Line]** [Issue description]
  - **Why:** [Explanation]
  - **Fix:** [Suggested fix]

### 🟡 Suggestions (Should Consider)
- **[File:Line]** [Issue description]
  - **Why:** [Explanation]
  - **Fix:** [Suggested fix]

### 🟢 Nits (Optional)
- **[File:Line]** [Minor suggestion]

### ✅ What's Good
- [Positive feedback on good patterns]
```

## Success Criteria

A successful review:
- ✅ Scans the entire pointed at code and surrounding codebase thoroughly
- ✅ Cross-checks against documentation and references
- ✅ Identifies all critical issues
- ✅ Provides code review in the correct output format
