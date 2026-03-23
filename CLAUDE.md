# Wisp

Wisp is a CLI tool that automates the path from PRD (Product Requirements Document) to Pull Request using a sequential pipeline of specialized AI agents. Given a manifest file describing PRDs and target repositories, wisp clones each repo, creates a feature branch, runs a configurable sequence of agents (architect → developer → tester → reviewer → ...) inside Dev Containers, and opens a GitHub PR with evidence comments.

It is used by engineers who want to delegate feature implementation, code review, test generation, or documentation across multiple repositories in parallel — with each agent responsible for one concern.

**Tech Stack**: Rust (edition 2021), Tokio 1 (async runtime), Clap 4 (CLI), Serde 1 (JSON deserialization)
**Repository**: https://github.com/delehner/wisp
**Key Dependencies**:
- `tokio` — async runtime; all pipeline execution is async with `JoinSet` + `Semaphore` for parallelism
- `clap` (derive feature) — all CLI subcommands and flags via derive macros
- `serde` / `serde_json` — manifest deserialization and JSONL log parsing
- `anyhow` / `thiserror` — error handling throughout
- `notify` — filesystem watcher for real-time log monitoring (`wisp logs tail`)
- `tracing` / `tracing-subscriber` — structured logging with JSONL output
- `dotenvy` — `.env` file loading for config
- `which` — runtime check for `claude`, `gemini`, `gh`, `docker` availability
- `indicatif` — progress bars and spinners during pipeline execution
- `dialoguer` — interactive prompts in interactive mode

---

# Architecture

## Directory Structure

```
wisp/
├── src/
│   ├── main.rs              # CLI entry point, command dispatch
│   ├── cli.rs               # Clap derive structs (all subcommands + flags)
│   ├── config.rs            # Config struct, .env loading, per-agent overrides
│   ├── utils.rs             # exec_streaming, exec_capture, command_exists, repo_name_from_url
│   ├── manifest/mod.rs      # Manifest, Order, PrdEntry, Repository (serde deserialization)
│   ├── prd/mod.rs           # Prd struct, markdown frontmatter extraction (title, branch, status)
│   ├── context/mod.rs       # assemble_skills() — ordered skill file concatenation
│   ├── git/
│   │   ├── mod.rs           # clone, prepare_repo, create_feature_branch, push
│   │   └── pr.rs            # gh pr create, evidence comment posting
│   ├── provider/
│   │   ├── mod.rs           # Provider trait, RunOutcome, RunOpts, create_provider()
│   │   ├── claude.rs        # ClaudeProvider: claude CLI invocation
│   │   └── gemini.rs        # GeminiProvider: gemini CLI invocation
│   ├── pipeline/
│   │   ├── mod.rs           # DEFAULT_AGENTS, NON_BLOCKING_AGENTS, is_blocking()
│   │   ├── orchestrator.rs  # Manifest dispatch, order sequencing, wave stacking, parallel execution
│   │   ├── runner.rs        # Single PRD × repo pipeline (clone → branch → devcontainer → agents → PR)
│   │   ├── agent.rs         # Ralph Loop: prompt assembly, iteration, completion detection
│   │   └── devcontainer.rs  # Dev Container RAII lifecycle (Drop impl stops/removes container)
│   └── logging/
│       ├── mod.rs           # Tracing subscriber initialization
│       ├── formatter.rs     # JSONL stream formatting (Claude + Gemini event types)
│       └── monitor.rs       # Real-time log tailing (notify-based), session listing
├── agents/                  # Agent prompt files: _base-system.md + <name>/prompt.md
├── templates/               # PRD, manifest, and context templates
├── skills/                  # Cursor-compatible skill files per agent
├── contexts/                # Per-repository context skill directories
├── manifests/               # Manifest JSON files
├── docs/                    # Mermaid diagrams and reference documentation
├── config/                  # AI CLI settings templates
├── .devcontainer/           # Dev Container configs (firewall + tool setup hooks)
└── .github/workflows/       # CI (clippy/fmt/test/build) + release (cross-compile)
```

## Key Patterns

- **Provider trait**: `src/provider/mod.rs` defines `Provider` with `build_run_args()`, `extract_session_id()`, etc. `ClaudeProvider` and `GeminiProvider` implement it. `create_provider(config)` returns `Box<dyn Provider>`.
- **RAII Dev Containers**: `DevContainer` in `devcontainer.rs` implements `Drop` — container stops and is removed when the struct goes out of scope regardless of success/failure.
- **Wave stacking for same-repo PRDs**: When multiple PRDs in an order target the same repository, the orchestrator serializes them into waves. Each wave branches from the previous wave's feature branch, preventing merge conflicts.
- **Ralph Loop**: Agent iteration loop in `agent.rs`. Each iteration assembles a fresh prompt (base system + PRD + previous progress), invokes the AI CLI, and checks `.agent-progress/<name>.md` for `Status: COMPLETED` or `Status: BLOCKED`.
- **Blocking vs. non-blocking agents**: `NON_BLOCKING_AGENTS` in `pipeline/mod.rs` — failure of these agents does not abort the pipeline. All others are blocking.

## Data Flow

```
Manifest JSON
  → Orchestrator (orders sequentially, PRDs in parallel via JoinSet)
    → [wave grouping for same-repo PRDs]
    → Runner (per PRD × repo)
      → git clone + feature branch
      → assemble_skills() → CLAUDE.md / GEMINI.md written to workdir
      → DevContainer start
        → AgentRunner (for each agent in sequence)
          → prompt assembly (base-system + PRD + context + progress)
          → Provider::build_run_args() → exec_streaming(claude/gemini)
          → read .agent-progress/<name>.md → check COMPLETED/BLOCKED
          → repeat up to max_iterations
      → DevContainer drop (cleanup)
      → git push → gh pr create → evidence comments
```

## Module Boundaries

- `cli.rs` owns all input parsing — nothing else touches `clap`
- `config.rs` owns all env/`.env` resolution — modules receive `&Config`
- `pipeline/` owns execution logic — `git/` and `provider/` are utilities it calls
- `context/mod.rs` is stateless — pure file assembly with no pipeline knowledge
- `logging/` is initialized once in `main.rs` and produces side effects (files, stdout)

---

# Coding Conventions

## General Rules

- Rust edition 2021. Run `cargo fmt` before every commit; CI enforces `cargo fmt --check`.
- `cargo clippy -- -D warnings` must pass — all clippy warnings are treated as errors in CI.
- The binary must cross-compile for macOS arm64/x86_64 and Linux arm64/x86_64 (`profile.release` uses `opt-level = "z"`, `lto = true`, `codegen-units = 1`, `strip = true`).
- Async code uses `tokio` with `#[tokio::main]`. Blocking I/O is not allowed on the async runtime — use `tokio::fs`, `tokio::process::Command`, or `spawn_blocking`.
- All fallible functions return `anyhow::Result<T>`. Use `.with_context(|| "message")` on every `?` where the error lacks context.
- Use `thiserror` for library-style error types when a module needs typed errors (e.g., pipeline errors).

## Naming

- Modules follow Rust snake_case (`pipeline/orchestrator.rs`, `git/pr.rs`).
- Structs are PascalCase: `Config`, `RunOutcome`, `PrdEntry`, `DevContainer`.
- Constants are SCREAMING_SNAKE_CASE: `DEFAULT_AGENTS`, `NON_BLOCKING_AGENTS`.
- CLI subcommands in `cli.rs` use PascalCase enum variants: `Commands::Orchestrate`, `Commands::Run`.
- Agent names are lowercase kebab-case strings matching directory names under `agents/`: `"architect"`, `"developer"`, `"tester"`.
- Environment variables follow `UPPER_SNAKE_CASE` matching `.env.example` exactly.

## Code Style

- Imports: standard library first, then external crates, then internal (`crate::`) — separated by blank lines. `cargo fmt` enforces ordering.
- Prefer explicit file paths in `git add` over `git add .` (enforced by agent prompt conventions; applies to manual commits too).
- Struct construction: use named fields, not positional.
- String formatting: prefer `format!()` over string concatenation.
- Use `Option<String>` (not empty strings) to represent "not set" config values. `env_opt()` in `config.rs` filters empty strings to `None`.

## Error Handling

- All public functions return `anyhow::Result`. Internal helpers may return `Result<(), anyhow::Error>`.
- `.context("...")` is preferred over `.unwrap()` or `.expect()` except in tests.
- Pipeline errors are logged via `tracing::error!` before propagation.
- Agent-level errors write to `.agent-progress/<name>.md` with `Status: BLOCKED` for recoverable failures; hard errors bubble up.
- `exec_streaming` and `exec_capture` in `utils.rs` are the only places that call `tokio::process::Command` — do not spawn processes directly elsewhere.

## Async Conventions

- Top-level concurrency: `tokio::task::JoinSet` for spawning parallel pipelines, `tokio::sync::Semaphore` for rate limiting (max parallel = `Config::max_parallel`).
- Shared state across tasks: `Arc<Mutex<T>>` or channels — no raw `Mutex` across await points.
- Log output from child processes uses `exec_streaming` with closure callbacks — not `.output().await` which buffers everything.

---

# Testing

**Framework**: Rust built-in test harness (`cargo test`)
**Run**: `cargo test`
**Location**: Inline `#[cfg(test)]` modules within source files — no separate `tests/` directory
**Coverage**: No coverage threshold configured

## Patterns

Tests live in `#[cfg(test)]` blocks at the bottom of their source file. Three modules have tests:

**`src/context/mod.rs`** — tests `strip_frontmatter()`:
```rust
#[test]
fn test_strip_frontmatter() {
    let with_fm = "---\nname: test\ndescription: foo\n---\n# Content\nHello";
    assert_eq!(strip_frontmatter(with_fm), "# Content\nHello");
    let without_fm = "# Content\nHello";
    assert_eq!(strip_frontmatter(without_fm), "# Content\nHello");
}
```

**`src/prd/mod.rs`** — tests markdown metadata extraction (title, status, branch, priority parsing from frontmatter).

**`src/utils.rs`** — tests `repo_name_from_url()`:
```rust
#[test]
fn test_repo_name() {
    assert_eq!(repo_name_from_url("https://github.com/org/my-repo.git"), "my-repo");
    assert_eq!(repo_name_from_url("git@github.com:org/my-repo.git"), "my-repo");
}
```

## Mocking

No mocking framework in use. Tests exercise pure functions (string parsing, path manipulation) that don't require I/O. Integration behavior (git, docker, AI CLI invocations) is not unit-tested — it is validated by running the pipeline against real repos.

## Notes

- Tests must pass in CI: `cargo test` runs in the `check` job in `.github/workflows/ci.yml`
- No async tests currently — all tested functions are synchronous
- If adding async tests, use `#[tokio::test]`

---

# Build & Deploy

## Commands

- **Build (dev)**: `cargo build`
- **Build (release)**: `cargo build --release`
- **Run**: `cargo run -- <subcommand>`
- **Lint**: `cargo clippy -- -D warnings`
- **Format check**: `cargo fmt --check`
- **Format fix**: `cargo fmt`
- **Test**: `cargo test`

## Release Profile

`Cargo.toml` configures an aggressive release profile:
```toml
[profile.release]
opt-level = "z"   # optimize for binary size
lto = true
codegen-units = 1
strip = true
```

## Deployment

Wisp is distributed as a single static binary. The install script (`scripts/install.sh`) downloads a pre-built binary from GitHub Releases and places it in the user's PATH.

Users can also install from source: `cargo install --path .`

The binary looks for `agents/` and `templates/` directories by walking up from the executable location, then falls back to `~/.wisp/`. The `WISP_ROOT_DIR` env var can override this.

## CI/CD

**CI** (`.github/workflows/ci.yml`) — triggers on pushes/PRs to `src/**` and `Cargo.toml`:
1. `cargo fmt --check`
2. `cargo clippy -- -D warnings`
3. `cargo test`
4. `cargo build --release`

**Release** (`.github/workflows/release.yml`) — cross-compiles for four targets:
- `aarch64-apple-darwin` (macOS ARM)
- `x86_64-apple-darwin` (macOS Intel)
- `aarch64-unknown-linux-gnu` (Linux ARM)
- `x86_64-unknown-linux-gnu` (Linux x86)

Artifacts are uploaded to GitHub Releases on version tags.

---

# Environment Variables

Source: `.env.example`. Copy to `.env` in the wisp root directory. CLI flags take precedence over `.env` values.

## AI Provider

| Variable | Default | Description |
|----------|---------|-------------|
| `AI_PROVIDER` | `claude` | `claude` or `gemini` |

## Authentication

| Variable | Description |
|----------|-------------|
| `ANTHROPIC_API_KEY` | API key for Claude (leave blank if using Claude Max subscription) |
| `CLAUDE_CODE_OAUTH_TOKEN` | OAuth token for headless/containerized Claude runs (`claude setup-token`) |
| `GEMINI_API_KEY` | API key for Gemini CLI (leave blank to use `gemini auth login`) |
| `GOOGLE_API_KEY` | Alternative Google Cloud API key for Gemini |
| `GITHUB_TOKEN` | GitHub PAT (or use `gh auth login`) |

## Pipeline Defaults

| Variable | Default | Description |
|----------|---------|-------------|
| `PIPELINE_MAX_ITERATIONS` | `10` | Max Ralph Loop iterations per agent |
| `PIPELINE_MAX_PARALLEL` | `4` | Max concurrent PRD × repo pipelines |
| `PIPELINE_WORK_DIR` | `/tmp/wisp-work` | Working directory for cloned repos |
| `PIPELINE_CLEANUP` | `false` | Delete work directory after PR creation |
| `DEFAULT_BASE_BRANCH` | `main` | Base branch for PRs |
| `USE_DEVCONTAINER` | `true` | Run agents inside Dev Containers |
| `UPDATE_PROJECT_CONTEXT` | `true` | Rewrite `CLAUDE.md`/`GEMINI.md` after each agent |
| `EVIDENCE_AGENTS` | `tester,performance,secops,dependency,infrastructure,devops` | Agents whose reports are posted as PR comments |

## Provider Model Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `CLAUDE_MODEL` | `sonnet` | Default Claude model (short names accepted: `sonnet`, `opus`) |
| `CLAUDE_ALLOWED_TOOLS` | `Edit,Write,Bash,Read,MultiEdit` | Tools available to Claude in headless mode |
| `GEMINI_MODEL` | `gemini-2.5-pro` | Default Gemini model |

## Per-Agent Overrides

Each agent supports `<AGENT>_MODEL` and `<AGENT>_MAX_ITERATIONS` overrides:

```
ARCHITECT_MODEL=       ARCHITECT_MAX_ITERATIONS=
DEVELOPER_MODEL=       DEVELOPER_MAX_ITERATIONS=
TESTER_MODEL=          TESTER_MAX_ITERATIONS=
REVIEWER_MODEL=        REVIEWER_MAX_ITERATIONS=
# ... same pattern for all 14 agents
```

## Logging

| Variable | Default | Description |
|----------|---------|-------------|
| `LOG_LEVEL` | `info` | `debug`, `info`, `warn`, `error` |
| `LOG_DIR` | `./logs` | Log output directory |
| `VERBOSE_LOGS` | `false` | Show agent thinking, tool calls, and results |
| `INTERACTIVE` | `false` | Pause between agents for human review |

## Optional Integrations (MCP)

| Variable | Description |
|----------|-------------|
| `NOTION_TOKEN` | Notion integration token |
| `FIGMA_ACCESS_TOKEN` | Figma access token |
| `SLACK_TEAM_ID` | Slack team ID |
| `JIRA_URL`, `JIRA_EMAIL`, `JIRA_API_TOKEN` | Jira credentials |

---

# External Integrations

## Required Runtime Dependencies

These must be installed and authenticated for wisp to function:

| Tool | Purpose | Check |
|------|---------|-------|
| `claude` (Claude Code CLI) | AI agent execution (default provider) | `claude --version` |
| `gemini` (Gemini CLI) | AI agent execution (alternative provider) | `gemini --version` |
| `gh` (GitHub CLI) | PR creation, evidence comments | `gh auth status` |
| `docker` | Dev Container lifecycle | `docker info` |
| `git` | Clone, branch, push | `git --version` |

Wisp uses `which::which()` (the `which` crate) to check for these at startup.

## MCP Servers (`.mcp.json`)

Configured MCP servers available to AI agents during pipeline execution:

| Service | Purpose | Config Key |
|---------|---------|------------|
| GitHub | Repository operations, issue/PR access | `GITHUB_TOKEN` |
| Notion | PRD/doc retrieval from Notion databases | `NOTION_TOKEN` |
| Figma | Design asset access for designer agent | `FIGMA_ACCESS_TOKEN` |
| Slack | Team communication context | `SLACK_TEAM_ID` |

## CI/CD

| Service | Purpose |
|---------|---------|
| GitHub Actions | CI (clippy/fmt/test) and release (cross-compile binary distribution) |
| GitHub Releases | Binary distribution for `scripts/install.sh` |

## Dev Containers

Dev Container configs in `.devcontainer/` set up isolated environments with:
- Firewall rules restricting network access
- Pre-installed AI CLI tools (`claude`, `gemini`, `gh`, `docker`)
- Auth token injection from host environment
