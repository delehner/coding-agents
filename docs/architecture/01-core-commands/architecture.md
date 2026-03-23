# Architecture: VSCode Extension — Core Command Palette Integration

## Overview

Extend the existing `vscode-extension/` scaffold to expose all 9 wisp CLI subcommands as VS Code command palette entries. Each command collects required inputs via QuickInput APIs, streams output line-by-line to a shared Output Channel, and reflects pipeline state in a status bar item. A `cancel()` method is added to `WispCli` to support stopping in-flight processes.

---

## System Design

### Components

| Component | File | Responsibility |
|-----------|------|----------------|
| `WispCli` (extended) | `src/wispCli.ts` | Stores active `ChildProcess`; exposes `cancel()` / `isRunning` |
| `WispStatusBar` | `src/statusBar.ts` | Status bar item; shows Running/Idle state; click reveals Output Channel |
| `activate()` (extended) | `src/extension.ts` | Creates shared Output Channel + StatusBar; registers all commands; tracks active CLI ref |
| `registerOrchestrateCommand` | `src/commands/orchestrate.ts` | File picker → `wisp orchestrate --manifest <path>` |
| `registerPipelineCommand` | `src/commands/pipeline.ts` | PRD picker + repo/branch inputs → `wisp pipeline` |
| `registerRunCommand` | `src/commands/run.ts` | Agent QuickPick + workdir + PRD → `wisp run` |
| `registerGeneratePrdCommand` | `src/commands/generate.ts` | Description input + repeatable repo URLs → `wisp generate prd` |
| `registerGenerateContextCommand` | `src/commands/generate.ts` | Repo URL + branch → `wisp generate context` |
| `registerMonitorCommand` | `src/commands/monitor.ts` | Session QuickPick → `wisp monitor` |
| `registerInstallSkillsCommand` | `src/commands/utils.ts` | No inputs → `wisp install skills` |
| `registerUpdateCommand` | `src/commands/utils.ts` | No inputs → `wisp update` |
| `runWithOutput` (shared helper) | `src/commands/utils.ts` | Resolves CLI, calls `cli.run()`, streams to Output Channel, updates StatusBar |

### Data Flow

```
User triggers palette command
  → command handler collects inputs (QuickPick / showInputBox)
  → runWithOutput(cli, args, cwd, outputChannel, statusBar)
      → statusBar.setRunning()
      → activeCli = cli  (stored in extension.ts scope)
      → cli.run(args, cwd, onStdout, onStderr)
          → spawns child process; stores ChildProcess ref on cli instance
          → readline lines → outputChannel.appendLine()
      → on exit: statusBar.setIdle(); activeCli = null
  → show success/error notification
```

### Active Process Tracking

`extension.ts` holds `let activeCli: WispCli | null = null`. Commands set this before calling `runWithOutput` and clear it on completion. `wisp.stopPipeline` reads `activeCli` and calls `activeCli.cancel()`.

This is simpler than a registry pattern and matches the single-pipeline-at-a-time mental model (simultaneous pipelines are the orchestrator's concern, not the extension's).

### Data Models

No new data models. Existing types:
- `RunOptions` — already in `wispCli.ts` (has `outputChannel` field)
- `CaptureResult` — unchanged

New type additions to `wispCli.ts`:
```typescript
// on WispCli class:
cancel(): void          // sends SIGTERM to active ChildProcess; noop if not running
get isRunning(): boolean
```

### API Contracts

No HTTP APIs. The extension shells out to the `wisp` binary.

**`runWithOutput` signature** (in `src/commands/utils.ts`):
```typescript
async function runWithOutput(
  cli: WispCli,
  args: string[],
  cwd: string,
  outputChannel: vscode.OutputChannel,
  statusBar: WispStatusBar,
  onActivate?: (cli: WispCli) => void,
  onDone?: () => void,
): Promise<number>
```

**File picker helpers** (in `src/commands/utils.ts`):
```typescript
async function pickManifestFile(cwd: string): Promise<string | undefined>
async function pickPrdFile(cwd: string): Promise<string | undefined>
```

---

## File Structure

```
vscode-extension/
├── package.json                          # Modified: add 9 new commands to contributes.commands
└── src/
    ├── extension.ts                      # Modified: registers all commands + statusBar
    ├── wispCli.ts                        # Modified: add cancel(), isRunning, store ChildProcess ref
    ├── statusBar.ts                      # New: WispStatusBar class
    ├── commands/
    │   ├── orchestrate.ts                # New: registerOrchestrateCommand()
    │   ├── pipeline.ts                   # New: registerPipelineCommand()
    │   ├── run.ts                        # New: registerRunCommand()
    │   ├── generate.ts                   # New: registerGeneratePrdCommand(), registerGenerateContextCommand()
    │   ├── monitor.ts                    # New: registerMonitorCommand()
    │   └── utils.ts                      # New: runWithOutput(), pickManifestFile(), pickPrdFile(), registerInstallSkillsCommand(), registerUpdateCommand()
    ├── __mocks__/
    │   └── vscode.ts                     # Modified: add showQuickPick, showWarningMessage, StatusBarItem mocks
    └── __tests__/
        ├── wispCli.test.ts               # Modified: add cancel() / isRunning tests
        ├── orchestrate.test.ts           # New
        ├── pipeline.test.ts              # New
        ├── run.test.ts                   # New
        ├── generate.test.ts              # New
        ├── monitor.test.ts               # New
        └── commandUtils.test.ts          # New
```

---

## Technical Decisions

| Decision | Choice | Rationale | Alternatives Considered |
|----------|--------|-----------|------------------------|
| Active CLI tracking | `let activeCli` in `extension.ts` module scope | Simple, matches single-pipeline mental model | Registry pattern (overkill for one active process) |
| Shared run helper | `runWithOutput()` in `commands/utils.ts` | All 7 streaming commands are identical except args; DRY | Inline per command (repetitive) |
| File pickers | `vscode.workspace.findFiles()` + `showQuickPick` | No new deps; respects workspace | `showOpenDialog` (less integrated feel) |
| Status bar state | Callback-based via `runWithOutput` | StatusBar has no business knowing about WispCli | Observer pattern (overkill) |
| Cancel mechanism | SIGTERM via `proc.kill()` | Standard Unix process termination; `cp.spawn` gives direct access | `proc.kill('SIGKILL')` (forceful; try SIGTERM first) |

---

## Dependencies

No new npm dependencies. All required APIs are in:
- `vscode` — `StatusBarItem`, `QuickPick`, `showInputBox`, `showQuickPick`, `workspace.findFiles`
- `node:child_process` — already used via `cp.spawn` in `wispCli.ts`

---

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| `wisp generate prd --interactive` requires stdin | Medium | Use `--description` flag only; skip `--interactive` mode in this PRD |
| Long-running pipelines produce very large Output Channel output | Low | VS Code Output Channel handles this natively; no action needed |
| Multiple commands triggered in parallel | Low | `runWithOutput` checks `activeCli?.isRunning` and shows error message if already running |
| `workspace.findFiles` returns no results (manifest/prd not in workspace) | Low | Fall back to `showInputBox` for manual path entry |

---

## Implementation Tasks

Ordered for the Developer agent:

1. **Extend `WispCli`** — Add private `_proc: cp.ChildProcess | null = null` field. Store `proc` reference in `run()`. Implement `cancel()` (SIGTERM + clear `_proc`). Implement `get isRunning()`. AC: existing tests still pass; new `cancel()` test passes.

2. **Create `src/statusBar.ts`** — `WispStatusBar` class wrapping `vscode.StatusBarItem`. Constructor creates item with `command: 'wisp.showOutput'`. `setRunning()` sets text to `$(sync~spin) Wisp: Running`. `setIdle()` sets text to `$(check) Wisp: Idle`. `dispose()` cleans up. AC: item visible when extension active; click shows Output Channel.

3. **Create `src/commands/utils.ts`** — `runWithOutput()` helper; `pickManifestFile()` using `workspace.findFiles('**/manifests/*.json')`; `pickPrdFile()` using `workspace.findFiles('**/prds/**/*.md')`; `registerInstallSkillsCommand()`; `registerUpdateCommand()`; `KNOWN_AGENTS` constant (14 agents). AC: unit tests for arg construction pass.

4. **Create `src/commands/orchestrate.ts`** — `registerOrchestrateCommand()`. Calls `pickManifestFile()`; falls back to `showInputBox` if none found. Builds `['orchestrate', '--manifest', path]`. AC: command appears as "Wisp: Orchestrate Manifest"; args constructed correctly.

5. **Create `src/commands/pipeline.ts`** — `registerPipelineCommand()`. PRD file picker, repo URL `showInputBox` with `https://` or `git@` validation, branch `showInputBox` defaulting to `main`. Builds `['pipeline', '--prd', prd, '--repo', repo, '--branch', branch]`. AC: validation rejects invalid URLs.

6. **Create `src/commands/run.ts`** — `registerRunCommand()`. `showQuickPick(KNOWN_AGENTS)` for agent selection, workdir picker defaulting to workspace root, PRD file picker. Builds `['run', '--agent', agent, '--workdir', workdir, '--prd', prd]`. AC: all 14 agents listed.

7. **Create `src/commands/generate.ts`** — `registerGeneratePrdCommand()` and `registerGenerateContextCommand()`. Generate PRD: `showInputBox` for description, repeatable repo URL input via loop. Generate context: repo URL + branch inputs. AC: args contain no shell interpolation.

8. **Create `src/commands/monitor.ts`** — `registerMonitorCommand()`. List sessions from `wisp logs list` output (captured); show in QuickPick; if empty show informational message. Builds `['monitor', '--session', session]`. AC: graceful empty state.

9. **Extend `src/extension.ts`** — Import and register all command modules. Create `WispStatusBar`. Add `wisp.stopPipeline` inline (calls `activeCli?.cancel()`). Add `wisp.showOutput` inline (shows Output Channel). Pass `outputChannel`, `statusBar`, `activeCli` setter to each `register*Command()`. AC: all commands registered; `activate()` compiles under strict mode.

10. **Update `package.json`** — Add all 9 new commands (+ `stopPipeline` + `showOutput`) to `contributes.commands` with correct `command` and `title` keys. AC: commands appear in palette.

11. **Update `src/__mocks__/vscode.ts`** — Add mocks for `showQuickPick`, `showWarningMessage`, `window.createStatusBarItem`, `workspace.findFiles`. AC: all test files compile without type errors.

12. **Write tests** — One test file per command module verifying arg construction. `wispCli.test.ts` additions for `cancel()` / `isRunning`. AC: `npm test` passes.

---

## Security Considerations

- All child process arguments are passed as array entries to `cp.spawn(binaryPath, args)` — no shell string interpolation. This is already the pattern in `wispCli.ts` and must be maintained in every command's arg-building logic.
- `wisp.binaryPath` is `machine-overridable` scope (already set) — workspace settings cannot override the binary path, preventing workspace-level binary hijacking.
- User-provided strings (repo URLs, file paths) are passed as array elements to `cp.spawn`, never concatenated into a shell command string.

## Performance Considerations

- Output streaming: `readline` interface on `proc.stdout` already emits lines as they arrive — no buffering of entire run. This satisfies the 100ms latency requirement.
- `workspace.findFiles()` is async and non-blocking; results are cached by VS Code internally.
- Output Channel does not need pagination — VS Code handles large output natively.
