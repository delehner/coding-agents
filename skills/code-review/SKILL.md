---
name: code-review
description: >-
  Perform comprehensive code review following production quality standards.
  Checks for correctness, security, performance, accessibility, and code style.
  Use when reviewing pull requests, examining code changes, auditing code quality,
  or when the user asks for a code review.
---

# Code Review

## When to Use

- User asks to "review this code", "check this PR", or "audit this"
- After implementing a feature, before creating a PR
- When examining unfamiliar code for quality issues

## Review Process

1. **Understand context** — read the PR description, related issue, or architecture doc
2. **Review holistically first** — understand the overall change before line-by-line review
3. **Check each category** — work through the checklist systematically
4. **Prioritize findings** — separate critical issues from suggestions
5. **Provide actionable feedback** — include fix suggestions, not just problem descriptions

## Review Checklist

### Correctness
- [ ] Logic handles all expected inputs and edge cases
- [ ] Error paths are handled (null, undefined, empty, network failure)
- [ ] State management is consistent (no race conditions, stale data)
- [ ] Types are accurate (no `any`, no incorrect casts)

### Security
- [ ] User input is validated and sanitized
- [ ] No SQL injection, XSS, or command injection vectors
- [ ] Authentication/authorization checks present on protected routes
- [ ] Secrets are not hardcoded or logged
- [ ] Sensitive data is not exposed in error messages

### Performance
- [ ] No N+1 queries or unnecessary database calls
- [ ] Large lists use pagination or virtualization
- [ ] Expensive computations are memoized where appropriate
- [ ] Event listeners and subscriptions are cleaned up
- [ ] Images and assets are optimized

### Code Quality
- [ ] Functions are small and single-purpose (< ~50 lines)
- [ ] Variable names are descriptive and consistent
- [ ] No duplicated logic (DRY)
- [ ] No leftover debug code, console.logs, or placeholder TODOs
- [ ] Imports are clean and organized

### Testing
- [ ] New code has adequate test coverage
- [ ] Tests verify behavior, not implementation
- [ ] Edge cases are tested
- [ ] Test descriptions are clear

### Accessibility (for UI changes)
- [ ] Interactive elements have ARIA labels
- [ ] Keyboard navigation works
- [ ] Color contrast meets WCAG AA
- [ ] Focus management is correct for dynamic content

## Feedback Format

Categorize each finding:

- **CRITICAL** — Must fix before merge. Bugs, security issues, data loss risks.
- **IMPORTANT** — Should fix. Performance issues, missing error handling, poor patterns.
- **SUGGESTION** — Consider improving. Style, naming, minor refactors.
- **QUESTION** — Need clarification on intent or approach.
- **PRAISE** — Highlight good patterns worth noting.

For each finding, provide:
```
**[CATEGORY]** `file:line` — Brief description
Current: what the code does now
Suggested: what it should do instead (with code if helpful)
Why: impact of not fixing
```

## Review Summary Template

```markdown
## Review Summary

### Overview
[1-2 sentences on the overall quality and approach]

### Critical Issues (must fix)
[List or "None found"]

### Important Issues (should fix)
[List or "None found"]

### Suggestions (consider)
[List or "None"]

### Verdict
APPROVE / REQUEST_CHANGES / NEEDS_DISCUSSION
```
