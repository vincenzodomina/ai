---
name: code-review
description: Conduct thorough code reviews with structured feedback on security, performance, quality, and testing. Generates trackable review documents with prioritized issues (critical/required/suggestions) and educational content. Use when reviewing PRs or code changes. Triggers on "review this code", "code review", "review PR".
---

# Code Review

Review the code pointed at or the recent changes by viewing the latest git commits. Also review how this code is integrated and interacts with the rest of the codebase.

## Criteria

### 0. Questions
- How would a senior expert approach the intended code?
- Which issues would he spot?
- Which potential problems would he point out?

### 1. Security Review
Check for:
- SQL injection vulnerabilities
- XSS (Cross-Site Scripting)
- Command injection
- Insecure deserialization
- Hardcoded secrets/credentials
- Improper authentication/authorization
- Insecure direct object references

### 2. Performance Review
Check for:
- N+1 queries
- Missing database indexes
- Unnecessary re-renders (React)
- Memory leaks
- Blocking operations in async code
- Missing caching opportunities
- Large bundle sizes

### 3. Code Quality Review
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
- Redundancy
- Brittle code
- Overly defensive code instead of clear boundaries and interfaces
- Fit into the overall architecture and design patterns
- Potential for lean and clean code

### 4. Inconsintencies / Unexpected behaviors
Check for:
- Spec / comments mismatch to actual code
- Obvious misconfigurations
- Potential errors in code behavior
- Code resulting in bad user experience
- Typos and Grammar of user facing strings

## Output Format

```markdown
## Code Review Summary

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

## Checklist

- [ ] No hardcoded secrets
- [ ] Input validation present
- [ ] Types/interfaces defined
- [ ] No obvious performance issues
- [ ] Code is readable and documented
- [ ] Breaking changes documented