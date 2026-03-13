---
name: pr-creation
description: >-
  Create well-structured pull requests with comprehensive descriptions, proper
  branch management, and review-ready summaries. Use when the user asks to create
  a PR, open a pull request, prepare changes for review, or push a feature branch.
---

# PR Creation

## When to Use

- User asks to "create a PR", "open a pull request", or "push this for review"
- After completing a feature or fix that's ready for review
- When preparing a branch for merge

## Process

1. **Verify readiness** — build passes, tests pass, no linter errors
2. **Review changes** — `git diff` to understand the full scope
3. **Create branch** (if not on one) — follow project naming conventions
4. **Stage and commit** — atomic commits with conventional messages
5. **Push branch** — `git push -u origin HEAD`
6. **Create PR** — via `gh pr create` with structured description

## Pre-PR Checklist

Run these before creating the PR:

```bash
# Build check
npm run build      # or project-specific build command

# Test check
npm test           # or project-specific test command

# Lint check
npm run lint       # or project-specific lint command

# Type check (TypeScript)
npx tsc --noEmit   # if applicable
```

## Branch Naming

Follow the project's convention. Common patterns:

| Type | Pattern | Example |
|------|---------|---------|
| Feature | `feat/<description>` | `feat/user-auth-oauth` |
| Fix | `fix/<description>` | `fix/login-redirect-loop` |
| Chore | `chore/<description>` | `chore/update-dependencies` |

## Commit Messages

Use [Conventional Commits](https://www.conventionalcommits.org/):

```
type(scope): concise description

Optional body explaining WHY, not WHAT.
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

## PR Description Template

```markdown
## Summary
[1-3 bullet points describing the change and its purpose]

## Changes
- **[area]**: [what changed and why]
- **[area]**: [what changed and why]

## Testing
- [ ] Unit tests added/updated
- [ ] Integration tests pass
- [ ] Manual testing completed
- [ ] Edge cases verified

## Screenshots
[If UI changes — before/after screenshots]

## Notes for Reviewers
[Any context that helps the reviewer understand decisions]
```

## Creating the PR

```bash
gh pr create \
  --title "feat(scope): description" \
  --body "$(cat <<'EOF'
## Summary
- description

## Changes
- **area**: change

## Testing
- [x] Tests pass

EOF
)"
```

## After Creation

- Link related issues: `gh pr edit <number> --add-label "enhancement"`
- Request reviewers if needed: `gh pr edit <number> --add-reviewer @username`
- Monitor CI checks: `gh pr checks <number>`
