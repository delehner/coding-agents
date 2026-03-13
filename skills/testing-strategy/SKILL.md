---
name: testing-strategy
description: >-
  Design test strategies and write comprehensive tests for features. Covers unit,
  integration, and E2E testing with proper mocking and coverage analysis. Use when
  the user asks to write tests, improve test coverage, design a test strategy, or
  create a testing plan.
---

# Testing Strategy

## When to Use

- User asks to "write tests", "add test coverage", or "create a test plan"
- After implementing a feature that needs test coverage
- When auditing existing test quality

## Process

1. **Discover the test framework** — read `package.json`, config files, existing tests
2. **Analyze the code under test** — identify functions, components, integrations to test
3. **Design the test plan** — categorize tests by type and priority
4. **Write tests** — follow existing patterns in the codebase
5. **Run and verify** — execute tests, check coverage, fix failures

## Test Pyramid

Prioritize tests in this order:

```
        /  E2E  \          Few — critical user flows only
       / Integr. \        Some — component interactions, API flows
      /   Unit    \       Many — functions, utils, pure logic
```

## Test Categories

### Unit Tests (highest priority)
Test individual functions and components in isolation.

- Pure functions: all input/output combinations
- Components: rendering, props, user interactions
- Utils/helpers: edge cases, error handling
- Hooks: state changes, side effects

### Integration Tests
Test how components work together.

- API route → service → database flow
- Component → hook → context interactions
- Form submission → validation → API call

### E2E Tests (use sparingly)
Test complete user flows through the real UI.

- Critical happy paths only (login, checkout, etc.)
- Use for flows that span multiple pages
- Skip for features adequately covered by unit + integration

## Test Structure

```
describe('<unit under test>', () => {
  describe('<scenario or method>', () => {
    it('should <expected behavior> when <condition>', () => {
      // Arrange — set up test data and mocks
      // Act — call the function or trigger the interaction
      // Assert — verify the outcome
    });
  });
});
```

## What to Test

| Test This | Example |
|-----------|---------|
| Happy path | `createUser({ name: "Alice" })` → returns user |
| Invalid input | `createUser({})` → throws validation error |
| Boundary values | `paginate({ page: 0 })`, `paginate({ page: MAX })` |
| Empty state | `getUsers()` → returns `[]` when no users |
| Error handling | `fetchData()` → handles network timeout |
| Authorization | `deleteUser()` → rejects unauthorized request |
| Null/undefined | `format(null)` → returns fallback |

## What NOT to Test

- Third-party library internals
- Simple getters/setters with no logic
- CSS class names or styling details
- Implementation details that may change
- Framework boilerplate

## Mocking Guidelines

- **Mock external boundaries** — APIs, databases, file system, timers
- **Don't mock internal modules** — test them directly or via integration tests
- **Keep mocks minimal** — only mock what's necessary for the test
- **Use factories** for test data to keep tests DRY and readable

## Coverage Targets

| Type | Target |
|------|--------|
| New code | 80%+ statement coverage |
| Critical paths | 100% branch coverage |
| Utils/helpers | 90%+ coverage |
| UI components | Focus on interaction testing over line coverage |

## Test Report Template

```markdown
# Test Report

## Summary
- Total: X tests | Passed: X | Failed: X
- Coverage: X% statements, X% branches

## Suites
| Suite | Tests | Status |
|-------|-------|--------|

## Bugs Found
| Bug | Severity | Fixed |
|-----|----------|-------|

## Coverage Gaps
- Areas needing more coverage
```
