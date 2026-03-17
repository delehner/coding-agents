# Coding Agents Pipeline

A generic, extensible AI agent pipeline that turns PRDs into Pull Requests using Claude Code with Ralph Loops and Dev Containers.

## How It Works

```mermaid
flowchart LR
    M["Manifest"] --> O["Orders\n(sequential)"]

    subgraph Order["Each Order"]
        direction TB
        P1["PRD A"] & P2["PRD B"] & P3["PRD C"]
    end
    O --> Order

    subgraph WU["Each PRD × Repo"]
        direction LR
        Ctx["Context\nSkills"] --> Agents
        subgraph Agents["Agent Sequence"]
            direction LR
            A["Architect"] --> Des["Designer"] --> Dev["Developer"] --> T["Tester"] --> S["SecOps"] --> I["Infra"] --> DO["DevOps"] --> R["Reviewer"]
        end
    end
    Order -->|"parallel\n+ per-repo context"| WU

    WU --> PR["Pull\nRequests"]
```

A **manifest** JSON defines the execution plan: a sequence of **orders**, each containing **PRDs** that run in parallel. Each PRD targets one or more **repositories**, each with its own branch and context skills. Every PRD x repo combination runs as an independent pipeline inside a Dev Container, with each agent operating in a Ralph Loop.

### Agent Roles

| Agent | Responsibility | Output |
|-------|---------------|--------|
| **Architect** | System design, tech decisions, file structure | `architecture.md`, dependency plan |
| **Designer** | UI/UX specs, component design, visual specs | Design specs, component hierarchy |
| **Migration** | Database migration generation and validation | `migration-plan.md`, migration files |
| **Developer** | Implementation based on architecture + design | Working code, commits |
| **Accessibility** | WCAG audit, ARIA, keyboard nav, contrast | `accessibility-report.md`, a11y fixes |
| **Tester** | Test strategy, test implementation, coverage | Tests, coverage reports |
| **Performance** | Profiling, benchmarks, query and bundle analysis | `performance-report.md`, optimizations |
| **SecOps** | Security hardening and vulnerability remediation | Security report, security fixes |
| **Dependency** | License compliance, vulnerability and maintenance audit | `dependency-report.md`, audit results |
| **Infrastructure** | Runtime/deployment infrastructure validation | Infrastructure plan, env contracts |
| **DevOps** | CI/CD and release readiness automation | DevOps runbook, pipeline updates |
| **Rollback** | Rollback procedures, feature flags, monitoring triggers | `rollback-plan.md`, rollback runbook |
| **Documentation** | README, API docs, changelog, migration guides | `documentation-summary.md`, doc updates |
| **Reviewer** | Code review, quality gates, final fixes | Review notes, fix commits |

## Installation

### Quick Install (recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/delehner/coding-agents/main/scripts/install.sh | bash
```

This clones the repo to `~/.coding-agents` and symlinks `ca` to `/usr/local/bin/ca` so you can run it from anywhere. Works on macOS and Linux.

Options:

```bash
# Custom install directory
curl -fsSL ... | bash -s -- --dir ~/my-agents

# Custom bin directory (e.g., if /usr/local/bin needs sudo)
curl -fsSL ... | bash -s -- --bin-dir ~/.local/bin

# Uninstall
curl -fsSL ... | bash -s -- --uninstall
```

### Manual Install

```bash
git clone https://github.com/delehner/coding-agents.git
cd coding-agents
chmod +x ca
# Either symlink to PATH:
ln -sf "$(pwd)/ca" /usr/local/bin/ca
# Or use directly:
./ca help
```

### Prerequisites

- [Claude Code CLI](https://docs.claude.com/en/docs/claude-code) — `npm install -g @anthropic-ai/claude-code`
- [Docker Desktop](https://www.docker.com/) + [Dev Containers CLI](https://github.com/devcontainers/cli) — `npm install -g @devcontainers/cli`
- [GitHub CLI](https://cli.github.com/) — `brew install gh && gh auth login`
- **jq** — `brew install jq` (required for manifest parsing)
- **Claude Max subscription** or an **Anthropic API key**
- For Dev Container runs with Claude Max: generate `CLAUDE_CODE_OAUTH_TOKEN` via `claude setup-token` and set it in `.env` if browser login is not detected in containers

> See **[docs/prerequisites.md](docs/prerequisites.md)** for the full setup guide.

## Quick Start

### 1. Configure

```bash
cd ~/.coding-agents   # or wherever you installed
cp .env.example .env
# Edit .env with your preferences
```

### 2. Set Up MCP Servers

```bash
# GitHub (required)
claude mcp add --transport http github https://api.githubcopilot.com/mcp/

# Notion (optional)
claude mcp add --transport http notion https://mcp.notion.com/mcp

# Figma (optional — used by the Designer agent)
claude mcp add --transport http figma https://mcp.figma.com/mcp

# Authenticate each server
claude  # then run /mcp inside the session
```

### 3. Create a Manifest

A manifest ties together PRDs, repositories, contexts, and execution order.

```json
{
  "name": "My Project",
  "orders": [
    {
      "name": "1 - Foundation",
      "prds": [
        {
          "prd": "./prds/01-setup.md",
          "agents": ["architect", "designer"],
          "repositories": [
            {
              "url": "https://github.com/org/repo",
              "branch": "main",
              "context": "./contexts/repo",
              "agents": ["developer", "tester", "reviewer"]
            }
          ]
        }
      ]
    }
  ]
}
```

Key concepts:
- **Orders** run sequentially (merge PRs from order 1 before order 2 starts)
- **PRDs** within an order run in parallel. When multiple PRDs target the same repo, they are automatically serialized with **stacked branches** to prevent merge conflicts
- Each **repository** has its own context directory (or file), branch, and URL
- Context skills are assembled into ephemeral `CLAUDE.md` — never committed to the target repo
- **Agents** can be specified per-PRD and/or per-repo — they combine (PRD-level first, then repo-level). Omit both to use the global default

See `templates/manifest.json` for the full template and `manifests/portfolio.json` for a real example.

### 4. Run the Pipeline

The `ca` CLI is the single entry point — it always enables verbose log formatting (thinking, tool calls, results) and always enforces Dev Containers.

```bash
# Run a full manifest (orders execute sequentially, PRDs in parallel)
ca orchestrate --manifest ./manifests/my-project.json

# Run a specific order only
ca orchestrate --manifest ./manifests/my-project.json --order 1

# Skip confirmation prompts between orders
ca orchestrate --manifest ./manifests/my-project.json --auto

# Single PRD × single repo
ca pipeline \
  --prd ./prds/my-feature.md \
  --repo https://github.com/org/repo \
  --context ./contexts/repo
```

### Monitoring & Interaction

```bash
# Interactive mode: pause between agents and iterations for review
ca orchestrate --manifest ./manifests/my-project.json --interactive

# Focus on a specific agent's output
ca orchestrate --manifest ./manifests/my-project.json --follow developer

# Monitor logs from another terminal while the pipeline runs
ca monitor                                    # all logs
ca monitor --agent developer                  # specific agent
ca monitor --sessions                         # list resumable sessions

# Re-format a raw .jsonl log for reading
ca logs ./logs/developer_iteration_1.jsonl

# Resume an agent session interactively (from session ID)
claude --resume <session-id>
```

### 5. Dev Containers (Default)

Agents run inside Dev Containers automatically — each PRD x repo gets its own isolated container. No extra setup beyond having Docker running. The `ca` CLI enforces this (the `--no-devcontainer` flag is blocked).

## Project Structure

```
coding-agents/
├── ca                           # Unified CLI (always verbose logs, always dev containers)
├── scripts/
│   ├── install.sh               # curl-based installer for macOS and Linux
│   └── install-skills.sh        # Install Cursor skills locally
├── pipeline/
│   ├── orchestrator.sh          # Manifest orchestrator: orders → PRDs → repos → PRs
│   ├── run-pipeline.sh          # Single PRD × single repo pipeline
│   ├── run-agent.sh             # Ralph Loop wrapper for a single agent
│   ├── generate-context.sh      # Context skill generator (analyzes repos)
│   ├── generate-prd.sh          # PRD and manifest generator (interactive prompt)
│   ├── monitor.sh               # Real-time log monitor (tail, filter, session list)
│   └── lib/
│       ├── prd-parser.sh        # Parse PRD metadata (status, title)
│       ├── git-utils.sh         # Branch management, rebase, and PR creation
│       ├── progress.sh          # Progress tracking between iterations
│       ├── validation.sh        # Completion criteria checks
│       ├── context.sh           # Context skill assembly
│       └── log-formatter.sh     # Stream-json → human-readable log formatter
├── agents/
│   ├── _base-system.md          # Shared base instructions for all agents
│   ├── architect/prompt.md
│   ├── designer/prompt.md
│   ├── migration/prompt.md
│   ├── developer/prompt.md
│   ├── accessibility/prompt.md
│   ├── tester/prompt.md
│   ├── performance/prompt.md
│   ├── secops/prompt.md
│   ├── dependency/prompt.md
│   ├── infrastructure/prompt.md
│   ├── devops/prompt.md
│   ├── rollback/prompt.md
│   ├── documentation/prompt.md
│   ├── reviewer/prompt.md
│   ├── context-generator/prompt.md
│   └── prd-generator/prompt.md
├── manifests/                   # Manifest JSON files (orders + PRDs + repos + contexts)
│   └── portfolio.json
├── prds/                        # Product Requirements Documents
├── contexts/                    # Per-repo context skill directories
│   └── <repo-name>/            # Skills: overview.md, architecture.md, conventions.md, ...
├── templates/
│   ├── manifest.json            # Manifest template
│   ├── prd.md                   # PRD template
│   ├── project-context.md       # Legacy single-file context template
│   └── context-skill.md         # Context skill template (directory-based)
├── skills/                      # Cursor-compatible agent skills
├── .devcontainer/
│   ├── devcontainer.json        # Dev Container for editing this repo
│   ├── agent/                   # Dev Container for running agents (headless)
│   │   ├── devcontainer.json
│   │   └── Dockerfile
│   ├── Dockerfile
│   └── init-firewall.sh
├── docs/                        # Documentation with diagrams
├── config/
│   └── settings.json            # Claude Code settings template
├── .mcp.json                    # MCP server configuration
├── .env.example                 # Environment variables template
├── CLAUDE.md                    # Instructions for this repo
└── README.md
```

## Adapting to Your Project

### For Personal Projects

1. Generate context skills for your repo: `ca generate context --repo <path-or-url> --output ./contexts/my-repo`
2. Review and refine the generated skills in `contexts/my-repo/`
3. Generate PRDs and a manifest — the script prompts you to describe what you want built:
   ```bash
   ca generate prd \
     --output ./prds/my-app \
     --manifest ./manifests/my-app.json \
     --repo https://github.com/org/my-repo --context ./contexts/my-repo

   # What do you want to build?
   # > Fix the CI/CD pipeline, add Terraform IaC, set up monitoring
   # >
   ```
4. Review the generated PRDs and manifest, then run: `ca orchestrate --manifest ./manifests/my-app.json`

> You can also write PRDs manually using `templates/prd.md`.

### For Company Projects

Context skills are injected as ephemeral `CLAUDE.md` that **never gets committed** to target repos.

1. Generate context skills for each repo: `ca generate context --repo <url> --output ./contexts/my-repo`
2. Review and customize the skills — add company-specific conventions, security policies, etc.
3. Generate PRDs and manifest — the script prompts you to describe the work:
   ```bash
   ca generate prd \
     --output ./prds/platform \
     --manifest ./manifests/platform.json \
     --repo https://github.com/org/api --context ./contexts/api \
     --repo https://github.com/org/web --context ./contexts/web
   ```
4. Review, adjust, and run. Connect Jira/Notion MCPs for ticket tracking

### Adding New Agents

Create a new directory under `agents/` with a `prompt.md` file following the existing format. Register the agent in `run-pipeline.sh`. See `docs/adding-agents.md` for a step-by-step guide.

## Configuration

### Environment Variables

See `.env.example` for all available configuration options.
You can keep costs down with `CLAUDE_MODEL=sonnet` and optionally override specific agents (for example `REVIEWER_MODEL=opus`).

### MCP Servers

Edit `.mcp.json` to add or remove MCP server integrations. The file is committed to git so your team shares the same integrations.

## Cost Considerations

Ralph Loops consume API tokens per iteration. With a **Claude Max subscription**, usage is unlimited (subject to rate limits). With **API keys**, typical costs per agent per PRD:

| Agent | Iterations (avg) | Est. Cost (API) |
|-------|------------------|-----------------|
| Architect | 2-4 | $2-8 |
| Designer | 2-5 | $2-10 |
| Developer | 5-15 | $10-30 |
| Tester | 3-8 | $5-15 |
| SecOps | 2-5 | $3-8 |
| Infrastructure | 2-4 | $2-6 |
| DevOps | 2-4 | $2-6 |
| Reviewer | 2-5 | $2-10 |

## License

MIT
