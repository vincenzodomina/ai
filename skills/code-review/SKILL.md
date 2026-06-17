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

1. **Security**
   - Input validation and sanitization
   - Authentication and authorization
   - Data exposure risks
   - Injection vulnerabilities
   - Sensitive data handling
   - Access control patterns

2. **Performance & Efficiency**
   - Algorithm complexity
   - Memory usage patterns
   - Database/data store query optimization
   - Caching strategies
   - Unnecessary computations
   - Resource management

3. **Code Quality & Patterns**
   - Readability and maintainability
   - Naming conventions (functions, variables, classes)
   - Function/class size and Single Responsibility
   - Code duplication (DRY principle)
   - Consistency with established patterns
   - Magic numbers and hardcoded values

4. **Architecture & Design**
   - Design pattern usage and appropriateness
   - Separation of concerns
   - Dependency management
   - Error handling strategy
   - API/interface design
   - Data modeling decisions
   - Module organization and coupling

5. **Testing Coverage**
   - Test completeness and quality
   - Test organization and naming
   - Mock/stub usage patterns
   - Edge case coverage
   - Test maintainability
   - Integration vs unit test balance

6. **Documentation**
   - API documentation (language-appropriate: YARD, TSDoc, JSDoc, docstrings, etc.)
   - Code comments (what/why, not how)
   - README updates if needed
   - Breaking changes documented
   - Migration/upgrade guides if needed

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
