---
name: architecture-review
description: >-
  Review and design system architecture from a PRD or feature request. Produces
  architecture documents with component design, data models, API contracts, and
  implementation tasks. Use when the user asks to architect a feature, design a
  system, create an architecture document, or plan a technical implementation.
---

# Architecture Review

## When to Use

- User asks to "architect", "design the system", or "plan the implementation"
- A PRD or feature request needs to be broken into technical components
- Reviewing or improving an existing architecture

## Process

1. **Read the PRD or requirements** — understand scope, constraints, and goals
2. **Explore existing code** — understand current architecture patterns using file tree, grep, and reading key files
3. **Identify components** — break the feature into logical components with clear boundaries
4. **Define interfaces** — API contracts, data models, component props
5. **Document decisions** — every choice needs a rationale and considered alternatives
6. **Create implementation tasks** — ordered, granular tasks with acceptance criteria

## Architecture Document Template

Produce a document at `docs/architecture/<feature-slug>/architecture.md`:

```markdown
# Architecture: <Feature Name>

## Overview
What this feature does, why it exists, and how it fits into the system.

## System Design

### Components
List each component with its responsibility, inputs, and outputs.

### Data Flow
How data moves through the system (request → service → database → response).

### Data Models
New or modified schemas with field types and constraints.

### API Contracts
Endpoints with method, path, request/response shapes, status codes.

## File Structure
Where new code lives, following existing project conventions.

## Technical Decisions
| Decision | Choice | Rationale | Alternatives |
|----------|--------|-----------|-------------|

## Implementation Tasks
Ordered list with acceptance criteria per task.
```

## Key Principles

- **Conservative over novel** — extend existing patterns before introducing new ones
- **Interface-first** — define contracts before implementation details
- **Testability** — every component should be independently testable
- **Minimal surface area** — expose only what consumers need
- **Document the "why"** — decisions without rationale are tech debt

## Common Mistakes to Avoid

- Designing in isolation without reading existing code
- Over-engineering for hypothetical future requirements
- Skipping data model definitions (causes ambiguity for developers)
- Listing tasks without acceptance criteria
- Ignoring error paths and failure modes
