---
name: prd-to-tasks
description: >-
  Break down a PRD (Product Requirements Document) into actionable development
  tasks with clear acceptance criteria. Use when the user provides a PRD, feature
  spec, or requirements document and needs it converted into implementation tasks,
  tickets, or a development plan.
---

# PRD to Tasks

## When to Use

- User provides a PRD or feature specification
- User asks to "break this down", "create tasks", or "plan the implementation"
- Converting requirements into a development plan or ticket backlog

## Process

1. **Read the full PRD** — understand scope, constraints, and priorities
2. **Identify workstreams** — group related work (backend, frontend, infra, testing)
3. **Break into tasks** — each task should be independently implementable and verifiable
4. **Order by dependencies** — tasks that unblock others come first
5. **Add acceptance criteria** — every task needs testable completion criteria
6. **Estimate complexity** — S/M/L relative sizing

## Task Breakdown Rules

### Good Tasks
- Independently implementable (one developer, one PR)
- Has clear acceptance criteria (testable)
- Sized to complete in 1-4 hours of focused work
- Describes WHAT, not HOW (implementation is the developer's domain)

### Bad Tasks
- "Build the feature" (too broad)
- "Fix bugs" (no acceptance criteria)
- "Refactor code" (no specific scope)
- "Make it look nice" (not testable)

## Output Format

```markdown
# Implementation Plan: <Feature Name>

## Overview
[1-2 sentences from the PRD]

## Workstreams

### 1. Data Layer
| # | Task | Acceptance Criteria | Size | Depends On |
|---|------|-------------------|------|-----------|
| 1.1 | Create user_preferences table | Migration runs, schema matches spec | S | — |
| 1.2 | Add Prisma model and types | Types are generated, relations correct | S | 1.1 |

### 2. API Layer
| # | Task | Acceptance Criteria | Size | Depends On |
|---|------|-------------------|------|-----------|
| 2.1 | GET /api/preferences endpoint | Returns user prefs, 401 if unauthed | M | 1.2 |
| 2.2 | PUT /api/preferences endpoint | Updates prefs, validates input, returns updated | M | 1.2 |

### 3. UI Layer
| # | Task | Acceptance Criteria | Size | Depends On |
|---|------|-------------------|------|-----------|
| 3.1 | PreferencesForm component | Renders all fields, handles submit | M | — |
| 3.2 | Wire form to API | Loads existing, submits changes, shows success/error | M | 2.1, 2.2, 3.1 |

### 4. Testing
| # | Task | Acceptance Criteria | Size | Depends On |
|---|------|-------------------|------|-----------|
| 4.1 | Unit tests for API endpoints | 90%+ coverage, edge cases tested | M | 2.1, 2.2 |
| 4.2 | Component tests for form | Render, interaction, validation tested | M | 3.1 |

## Dependency Graph
1.1 → 1.2 → 2.1 → 4.1
              2.2 → 4.1
3.1 → 3.2
2.1 + 2.2 + 3.1 → 3.2 → 4.2

## Suggested Implementation Order
1. 1.1, 1.2 (data layer)
2. 2.1, 2.2, 3.1 (API + UI in parallel)
3. 3.2 (integration)
4. 4.1, 4.2 (testing)

## Risks & Assumptions
- [list from PRD or newly identified]
```

## Sizing Guide

| Size | Scope | Time |
|------|-------|------|
| **S** | Single file change, clear implementation | < 1 hour |
| **M** | Multiple files, some decisions needed | 1-4 hours |
| **L** | Cross-cutting, multiple components, research needed | 4-8 hours |
| **XL** | Break this down further — it's too big for one task | > 8 hours |

## Integration with Ticketing

If the project uses Jira or similar, map tasks to ticket format:

```
Title: [workstream] task description
Type: Task | Story | Bug
Labels: backend, frontend, infra, testing
Story Points: S=1, M=3, L=5
Description: <acceptance criteria from the table>
Blocked By: <dependency task IDs>
```
