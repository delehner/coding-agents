# [Project Name]

> This file provides project context for AI coding agents.
> **Compatible with**: Claude Code (as CLAUDE.md) and Cursor (as .cursor/rules/*.md or .cursorrules)
>
> **Setup**:
> - Claude Code: Copy this file as `CLAUDE.md` to your project root
> - Cursor: Copy this file as `.cursor/rules/project-context.md` or `.cursorrules`
> - Or keep it in both locations and sync manually

## Project Overview

[1-2 paragraphs describing what this project is, what problem it solves, and who uses it.]

**Tech Stack**: [e.g., Next.js 15, TypeScript, Tailwind CSS, PostgreSQL, Prisma]
**Repository**: [github-url]
**Documentation**: [link to docs if available]

## Architecture

### High-Level Structure
```
src/
├── app/              # [e.g., Next.js app router pages]
├── components/       # [e.g., Shared React components]
│   ├── ui/           # [e.g., Design system primitives]
│   └── features/     # [e.g., Feature-specific components]
├── lib/              # [e.g., Utilities, helpers, clients]
├── services/         # [e.g., Business logic, API integrations]
├── types/            # [e.g., Shared TypeScript types]
└── [other dirs]/     # [describe]
```

### Key Patterns
- [Pattern 1: e.g., "Server Components by default, Client Components only when needed"]
- [Pattern 2: e.g., "Repository pattern for data access via /src/repositories/"]
- [Pattern 3: e.g., "Zod schemas for all API input validation"]

### Data Flow
[Brief description of how data flows through the app: client → API → service → database]

## Coding Conventions

### General
- [e.g., Use TypeScript strict mode — no `any` types]
- [e.g., Prefer named exports over default exports]
- [e.g., Use early returns to reduce nesting]
- [e.g., Maximum function length: ~50 lines]

### Naming
- **Files**: [e.g., kebab-case for files: `user-profile.tsx`]
- **Components**: [e.g., PascalCase: `UserProfile`]
- **Functions**: [e.g., camelCase: `getUserProfile`]
- **Constants**: [e.g., UPPER_SNAKE: `MAX_RETRY_COUNT`]
- **Types/Interfaces**: [e.g., PascalCase with prefix: `IUserProfile` or `UserProfileProps`]

### Code Style
- [e.g., Formatter: Prettier with project config]
- [e.g., Linter: ESLint with project config]
- [e.g., Import order: external → internal → relative, auto-sorted]

## Component Conventions

> Remove this section if not a frontend project.

- [e.g., Use Shadcn/ui components from `@/components/ui`]
- [e.g., Style with Tailwind CSS utility classes, not CSS modules]
- [e.g., Colocate component tests: `component.test.tsx` next to `component.tsx`]
- [e.g., Props interface named `<Component>Props`, e.g., `ButtonProps`]

## API Conventions

> Remove this section if not applicable.

- [e.g., RESTful endpoints under `/api/v1/`]
- [e.g., Use Zod for request validation, return standardized error format]
- [e.g., Error response shape: `{ error: { code: string, message: string } }`]
- [e.g., Authentication via Bearer token in Authorization header]

## Database Conventions

> Remove this section if not applicable.

- [e.g., ORM: Prisma — schema in `prisma/schema.prisma`]
- [e.g., Migrations: `npx prisma migrate dev --name <description>`]
- [e.g., Naming: snake_case for tables and columns]
- [e.g., Always include `created_at` and `updated_at` timestamps]

## Testing

- **Framework**: [e.g., Vitest for unit/integration, Playwright for E2E]
- **Run**: [e.g., `npm test` for unit, `npm run test:e2e` for E2E]
- **Location**: [e.g., Co-located `*.test.ts` files, E2E in `/e2e/`]
- **Coverage**: [e.g., Minimum 80% for new code]
- **Patterns**: [e.g., Use `vi.mock()` for module mocks, test factories in `/tests/factories/`]

## Build & Deploy

- **Dev**: [e.g., `npm run dev` — starts on port 3000]
- **Build**: [e.g., `npm run build`]
- **Lint**: [e.g., `npm run lint`]
- **Type Check**: [e.g., `npm run type-check` or `tsc --noEmit`]
- **Deploy**: [e.g., Vercel auto-deploy on push to main]

## Environment Variables

Key environment variables (see `.env.example` for full list):
- `DATABASE_URL`: [PostgreSQL connection string]
- `[OTHER_VAR]`: [description]

## Git Conventions

- **Branch naming**: [e.g., `feat/description`, `fix/description`, `chore/description`]
- **Commit messages**: [e.g., Conventional Commits — `type(scope): description`]
- **PR process**: [e.g., Require 1 approval, all checks must pass]

## Common Tasks

### Adding a new feature
1. [Step 1: e.g., Create route in app router]
2. [Step 2: e.g., Add service logic in /services/]
3. [Step 3: e.g., Add tests]
4. [Step 4: e.g., Update API docs]

### Adding a new API endpoint
1. [Step 1]
2. [Step 2]

## Known Issues & Technical Debt

- [Issue 1: description and context]
- [Issue 2: description and context]

## External Services & Integrations

| Service | Purpose | Docs |
|---------|---------|------|
| [Service A] | [What it's used for] | [Link] |
| [Service B] | [What it's used for] | [Link] |
