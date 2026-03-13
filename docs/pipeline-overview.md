# Pipeline Overview

The Coding Agents Pipeline transforms PRDs into Pull Requests by running specialized AI agents in sequence inside Dev Containers. A **manifest** JSON defines the execution plan: sequential **orders**, each containing **PRDs** that run in parallel, each targeting **repositories** with their own context and branch.

## End-to-End Flow

```mermaid
flowchart TD
    Input["📋 Manifest JSON\n(orders → PRDs → repos)"]
    Input --> Orch["orchestrator.sh\n(manifest orchestrator)"]

    Orch --> O1["Order 1\n(sequential)"]
    Orch --> O2["Order 2\n(waits for Order 1)"]
    Orch --> On["Order N"]

    subgraph O1Detail["Order 1 — PRDs run in parallel"]
        WU1["PRD A × Repo 1\n(context: repo-1.md)"]
        WU2["PRD A × Repo 2\n(context: repo-2.md)"]
        WU3["PRD B × Repo 1\n(context: repo-1.md)"]
    end
    O1 --> O1Detail

    subgraph Pipeline["Each Work Unit"]
        DC["🐳 Dev Container"] --> AgentSeq
        subgraph AgentSeq["Agent Sequence"]
            direction LR
            A1["🏗️ Architect"] --> A2["🎨 Designer"]
            A2 --> A3["💻 Developer"]
            A3 --> A4["🧪 Tester"]
            A4 --> A5["🔍 Reviewer"]
        end
    end

    WU1 --> Pipeline
    Pipeline --> PR["📬 Pull Request"]
```

## Three-Layer Architecture

```mermaid
flowchart LR
    subgraph Layer1["Layer 1: Manifest Orchestrator"]
        Orch["orchestrator.sh\nOrders → PRDs → repos\nSequential orders,\nparallel PRDs"]
    end

    subgraph Layer2["Layer 2: Single Pipeline"]
        Run["run-pipeline.sh\n1 PRD × 1 repo\nDev Container lifecycle\nAgent sequence"]
    end

    subgraph Layer3["Layer 3: Agent Runner"]
        Agent["run-agent.sh\nRalph Loop\n1 agent × 1 repo\n(inside container)"]
    end

    Orch -->|"per PRD×repo"| Run
    Run -->|"per agent\n(devcontainer exec)"| Agent
```

| Script | Scope | Responsibility |
|--------|-------|---------------|
| `orchestrator.sh` | Manifest → orders → PRDs → repos | Parse manifest, execute orders sequentially, dispatch PRDs in parallel, pause between orders |
| `run-pipeline.sh` | 1 PRD × 1 repo | Clone repo, start Dev Container, inject context, run agents, stop container, create PR |
| `run-agent.sh` | 1 agent | Ralph Loop: build prompt, run Claude Code, check completion |

## Manifest Structure

```json
{
  "name": "Project Name",
  "orders": [
    {
      "name": "1 - Foundation",
      "prds": [
        {
          "prd": "./prds/01-setup.md",
          "repositories": [
            {
              "url": "https://github.com/org/repo",
              "branch": "main",
              "context": "./contexts/repo.md"
            }
          ]
        }
      ]
    }
  ]
}
```

- **Orders** execute sequentially — merge PRs from order N before order N+1 starts
- **PRDs within an order** execute in parallel
- Each **repository** has its own context file, branch, and URL
- **Context** is per-repo (injected as ephemeral `CLAUDE.md`, never committed)

## Orchestrator Lifecycle

```mermaid
flowchart TD
    Start([Start]) --> LoadEnv[Load .env]
    LoadEnv --> Validate[Validate environment]
    Validate --> Mode{Manifest\nor legacy?}

    Mode -->|Manifest| ParseManifest[Parse manifest JSON\nwith jq]
    Mode -->|Legacy| CollectPRDs[Collect PRD files\nfrom --prd / --prd-dir]

    ParseManifest --> OrderLoop

    subgraph OrderLoop["For Each Order (sequential)"]
        BuildUnits[Build work units\nPRD × repo × context]
        BuildUnits --> Execute[Execute work units\nin parallel]
        Execute --> Pause{More orders\nremaining?}
        Pause -->|Yes| Prompt[Pause for review\nand PR merge]
        Prompt --> BuildUnits
        Pause -->|No| OrderDone[All orders done]
    end

    CollectPRDs --> LegacyExec[Build and execute\nwork units]

    OrderLoop --> Summary[Print results]
    LegacyExec --> Summary
```

## Single Pipeline Lifecycle (run-pipeline.sh)

```mermaid
flowchart TD
    Start([Start]) --> Clone[Clone repo\nor fetch latest]
    Clone --> Branch[Create feature branch]
    Branch --> InjectCtx[Inject context file\nas ephemeral CLAUDE.md]
    InjectCtx --> CopyPRD[Copy PRD into\nrepo docs/]
    CopyPRD --> StartDC["🐳 Start Dev Container\n(devcontainer up)"]
    StartDC --> AuthCheck{"Claude auth\navailable?"}
    AuthCheck -->|No| Fail([Pipeline Failed])
    AuthCheck -->|Yes| Loop

    subgraph Loop["For Each Agent (inside container)"]
        Check{Already\ncompleted?}
        Check -->|Yes| Skip[Skip agent]
        Check -->|No| Run["devcontainer exec\nrun-agent.sh\n(Ralph Loop)"]
        Run --> ValidateOut{Agent\ncompleted?}
        ValidateOut -->|Yes| Next[Next agent]
        ValidateOut -->|No, non-critical| Next
        ValidateOut -->|No, critical| Fail([Pipeline Failed])
        Skip --> Next
    end

    Loop --> StopDC["🐳 Stop Dev Container\n(docker stop)"]
    StopDC --> CreatePR{--skip-pr?}
    CreatePR -->|No| PR[Push branch &\ngh pr create]
    CreatePR -->|Yes| Done
    PR --> Done([Pipeline Complete])
```

### Dev Container Execution Notes

- `run-pipeline.sh` starts the container with `.devcontainer/agent/devcontainer.json`.
- Per-agent `devcontainer exec` uses that same config file, so target repos do not need their own `.devcontainer/devcontainer.json`.
- Pipeline logs are written to the repository root `logs/` directory by default.
- Agent commit identity is propagated from host git config (`user.name` / `user.email`) into container execution.
- Agent runtime logs inside containers are written under `.pipeline/logs` (excluded from git), not the target repo `logs/`.
- Per-agent progress files are cleared at the start of each PRD run to avoid cross-PRD completion leakage.

## Agent Responsibilities

```mermaid
flowchart TD
    subgraph Architect["🏗️ Architect"]
        A_In[Reads: PRD] --> A_Out[Produces: architecture.md\nFile structure, data models,\nAPI contracts, impl tasks]
    end

    subgraph Designer["🎨 Designer"]
        D_In[Reads: PRD +\narchitecture.md] --> D_Out[Produces: design.md\nUX flows, component specs,\nvisual specs, accessibility]
    end

    subgraph Developer["💻 Developer"]
        Dev_In[Reads: PRD +\narchitecture.md +\ndesign.md] --> Dev_Out[Produces: Working code\nImplementation, commits,\nbuild verification]
    end

    subgraph Tester["🧪 Tester"]
        T_In[Reads: PRD +\narchitecture.md +\ncode] --> T_Out[Produces: test-report.md\nUnit/integration/E2E tests,\ncoverage, bug fixes]
    end

    subgraph Reviewer["🔍 Reviewer"]
        R_In[Reads: All prior\nagent output + code] --> R_Out[Produces: pr-description.md\nReview fixes, quality gates,\nfinal verification]
    end

    Architect --> Designer --> Developer --> Tester --> Reviewer
```

## Context Passing Between Agents

Agents don't communicate directly. Each agent writes artifacts to disk, and subsequent agents read them:

```mermaid
flowchart LR
    subgraph Filesystem["Shared Filesystem (workspace inside container)"]
        Progress[".agent-progress/\n├── architect.md\n├── designer.md\n├── developer.md\n├── tester.md\n└── reviewer.md"]
        Docs["docs/architecture/prd-slug/\n├── prd.md\n├── architecture.md\n├── design.md\n├── test-report.md\n└── pr-description.md"]
        Code["src/\n└── (implemented code)"]
        Context["CLAUDE.md\n(ephemeral, from contexts/)"]
    end

    A1[Architect] -->|writes| Progress
    A1 -->|writes| Docs
    A2[Designer] -->|reads| Progress
    A2 -->|reads| Docs
    A2 -->|writes| Progress
    A2 -->|writes| Docs
    A3[Developer] -->|reads all| Filesystem
    A3 -->|writes| Code
```

## CLI Reference

```bash
# Manifest mode (recommended)
./pipeline/orchestrator.sh --manifest ./manifests/my-project.json
./pipeline/orchestrator.sh --manifest ./manifests/my-project.json --order 1
./pipeline/orchestrator.sh --manifest ./manifests/my-project.json --auto

# Legacy mode (single PRD)
./pipeline/orchestrator.sh --prd ./prds/feature.md --repo <url> --context ./contexts/repo.md

# Direct single pipeline (no orchestrator)
./pipeline/run-pipeline.sh --prd <path> --repo <url> --context <path>

# Single agent
./pipeline/run-agent.sh --agent <name> --workdir <path> --prd <path>
```

### Orchestrator Options

| Option | Description | Default |
|--------|-------------|---------|
| `--manifest <path>` | Manifest JSON file | — |
| `--order <n>` | Run only the nth order (1-based) | All orders |
| `--auto` | Skip confirmation prompts between orders | Interactive |
| `--prd <path>` | Legacy: PRD file (repeatable) | — |
| `--prd-dir <dir>` | Legacy: directory of PRD files | — |
| `--repo <url>` | Override repo for all PRDs | From manifest |
| `--branch <name>` | Override branch for all PRDs | From manifest |
| `--agents <list>` | Comma-separated agent list | All five |
| `--sequential` | Run work units one at a time | Parallel |
| `--max-parallel <n>` | Max concurrent pipelines | 4 |
| `--skip-pr` | Don't create PRs | false |
| `--no-devcontainer` | Run on host instead of in containers | false |
| `--no-context-update` | Don't update CLAUDE.md after agents | false |
| `--model <name>` | Claude model | claude-opus-4-6 |
| `--max-iterations <n>` | Per-agent iteration cap | 10 |
