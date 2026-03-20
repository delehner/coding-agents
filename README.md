# Wisp

A single Rust binary that turns PRDs into Pull Requests using AI coding agents (Claude Code or Gemini CLI), Ralph Loops, and Dev Containers.

```
Description → wisp generate prd → PRDs + Manifest
Manifest → wisp orchestrate → [Architect → Designer → Migration → Developer → Accessibility →
  Tester → Performance → SecOps → Dependency → Infrastructure → DevOps → Rollback →
  Documentation → Reviewer] → Pull Requests
```

## Install

**Pre-built binary** (recommended):

```bash
curl -fsSL https://raw.githubusercontent.com/delehner/wisp/main/scripts/install.sh | bash
```

**Homebrew:**

```bash
brew tap delehner/tap
brew install wisp
```

> **Homebrew/curl users:** The binary alone isn't enough — you need `agents/`, `templates/`, and `.env`. See [Configuration Guide](docs/configuration.md).

**From source:**

```bash
cargo install wisp
```

**Verify:**

```bash
wisp --version
wisp --help
```

## Prerequisites

| Tool | Required | Install |
|------|----------|---------|
| `git` | Yes | `brew install git` |
| `docker` | Yes | [docker.com](https://docker.com) |
| `devcontainer` | Yes | `npm install -g @devcontainers/cli` |
| `gh` | Yes | `brew install gh` |
| `claude` or `gemini` | Yes (one) | `npm install -g @anthropic-ai/claude-code` or `npm install -g @google/gemini-cli` |

**Note:** `jq` and `node` are not required — the Rust binary handles JSON natively.

## Quick Start

### 1. Authenticate

```bash
claude            # login with Claude Max
gh auth login     # login to GitHub
```

### 2. Generate context for your repo

```bash
wisp generate context \
  --repo https://github.com/you/your-repo \
  --output ./contexts/your-repo
```

### 3. Generate PRDs and a manifest

Wisp will prompt you to describe what you want to build, or you can pass it via `--description`:

```bash
wisp generate prd \
  --output ./prds/your-project \
  --manifest ./manifests/your-project.json \
  --repo https://github.com/you/your-repo \
  --context ./contexts/your-repo
# Prompts: "Describe what you want to build (goals, features, constraints)"

# Or non-interactively:
wisp generate prd ... --description "Build a VS Code extension for Wisp"
```

### 4. Run the pipeline

```bash
wisp orchestrate --manifest ./manifests/your-project.json
```

## Commands

| Command | Description |
|---------|-------------|
| `wisp orchestrate --manifest <path>` | Run all epics/subtasks from a manifest |
| `wisp pipeline --prd <path> --repo <url>` | Run a single PRD against one repo |
| `wisp run --agent <name> --workdir <path> --prd <path>` | Run a single agent (Ralph Loop) |
| `wisp generate prd --output <dir> --manifest <path> --repo <url> --context <path> [--description <text>]` | Generate PRDs (prompts for description or use --description) |
| `wisp generate context --repo <url> --output <dir>` | Generate context skills from a repo |
| `wisp monitor [--agent <name>]` | Tail agent logs in real-time |
| `wisp logs <file.jsonl>` | Re-format raw log files |
| `wisp install skills [--project <path>]` | Install Cursor skills as symlinks |
| `wisp update` | Self-update to latest version |

## Manifest Structure

```json
{
  "name": "My Project",
  "epics": [
    {
      "name": "1 - Foundation",
      "subtasks": [
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

- **Epics** run in parallel by default when multiple (isolated clones under `{work_dir}/epics/{index}/`); use `--sequential-epics` for one-at-a-time on a shared workdir
- **Subtasks within an epic** execute in manifest order (sequential); **repos** under the same subtask can run in parallel within `--max-parallel`
- **Same-repo subtasks** auto-serialize into stacking waves
- **Per-unit agents** combine: PRD agents first, then repo agents

## Agent Pipeline

| Order | Agent | Blocking | Produces |
|-------|-------|----------|----------|
| 1 | Architect | Yes | `architecture.md` |
| 2 | Designer | No | `design.md` |
| 3 | Migration | No | `migration-plan.md` |
| 4 | Developer | Yes | Working code + commits |
| 5 | Accessibility | No | `accessibility-report.md` |
| 6 | Tester | Yes | `test-report.md` |
| 7 | Performance | No | `performance-report.md` |
| 8 | SecOps | Yes | `security-report.md` |
| 9 | Dependency | No | `dependency-report.md` |
| 10 | Infrastructure | Yes | `infrastructure.md` |
| 11 | DevOps | Yes | `devops.md` |
| 12 | Rollback | No | `rollback-plan.md` |
| 13 | Documentation | No | `documentation-summary.md` |
| 14 | Reviewer | Yes | `pr-description.md` |

Blocking agents halt the pipeline on failure. Non-blocking agents log a warning and continue.

## Configuration

Copy `.env.example` to `.env` and edit:

```bash
cp .env.example .env
```

**Installed via Homebrew or curl?** See [Configuration Guide](docs/configuration.md) for `WISP_ROOT_DIR` and `.env` setup.

Key variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `AI_PROVIDER` | `claude` | `claude` or `gemini` |
| `CLAUDE_MODEL` | `sonnet` | Default Claude model |
| `GEMINI_MODEL` | `gemini-2.5-pro` | Default Gemini model |
| `PIPELINE_MAX_ITERATIONS` | `2` | Default Ralph cap when manifest has no `max_iterations` |
| `PIPELINE_MAX_PARALLEL` | `4` | Max concurrent pipelines |
| `PIPELINE_WORK_DIR` | `/tmp/wisp-work` | Clone directory |
| `EVIDENCE_AGENTS` | `tester,performance,...` | Agents whose reports become PR comments |
| `INTERACTIVE` | `false` | Pause between agents/iterations |

Per-agent overrides: `ARCHITECT_MODEL`, `DEVELOPER_MAX_ITERATIONS`, etc. For **`wisp orchestrate`**, prefer manifest `max_iterations` and `agent_max_iterations`; `wisp generate prd` seeds those from your `.env`.

## Project Structure

```
├── Cargo.toml                — Rust project manifest
├── src/                      — Rust source (~4,400 lines)
│   ├── main.rs               — entry point, CLI dispatch
│   ├── cli.rs                — clap subcommands and flags
│   ├── config.rs             — .env loading, per-agent overrides
│   ├── pipeline/             — orchestrator, runner, agent loop, devcontainer
│   ├── provider/             — Claude + Gemini CLI abstraction
│   ├── git/                  — clone, branch, rebase, PR creation
│   ├── manifest/             — manifest JSON parsing (serde)
│   ├── prd/                  — PRD metadata extraction
│   ├── context/              — context skill assembly
│   └── logging/              — JSONL formatting, log tailing
├── agents/                   — Agent prompt markdown files
├── templates/                — PRD, manifest, context templates
├── skills/                   — Cursor-compatible skills
├── contexts/                 — Per-repo context directories
├── manifests/                — Manifest JSON files
├── scripts/install.sh        — Binary download installer
├── .devcontainer/            — Dev Container configs (72 lines of shell — only remaining shell)
├── .github/workflows/        — CI + release automation
└── docs/                     — Architecture documentation
```

## Monitoring

```bash
# Tail all agent logs
wisp monitor

# Filter by agent
wisp monitor --agent developer

# List resumable sessions
wisp monitor --sessions

# Re-format a raw log file
wisp logs ./logs/developer_iteration_1.jsonl

# Resume a session interactively
claude --resume <session-id>
```

## Development

```bash
# Build
cargo build

# Run tests
cargo test

# Lint
cargo clippy

# Format
cargo fmt

# Release build (1.4 MB stripped binary)
cargo build --release
```

## Documentation

See `docs/` for detailed guides:

- [Pipeline Overview](docs/pipeline-overview.md) — end-to-end flow, agent responsibilities, CLI reference
- [Ralph Loop](docs/ralph-loop.md) — iteration mechanism, prompt assembly, completion detection
- [Adding Agents](docs/adding-agents.md) — step-by-step guide for new agents
- [Project Structure](docs/project-structure.md) — directory map, component relationships
- [Prerequisites](docs/prerequisites.md) — required tools, auth setup
- [Configuration](docs/configuration.md) — `.env` and `WISP_ROOT_DIR` for Homebrew/curl installs
- [MCP Integrations](docs/mcp-integrations.md) — Notion, Figma, Slack, Jira

## License

MIT
