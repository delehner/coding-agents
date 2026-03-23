# Changelog

All notable changes to the Wisp VS Code extension will be documented here.

## [Unreleased]

### Added

- **Wisp Explorer sidebar** — Activity Bar panel (custom Wisp icon) with two sections:
  - **Manifests** — parses all `manifests/*.json` in the workspace and displays epics, subtasks, and target repos as a collapsible tree; malformed JSON shows an error node
  - **PRDs** — lists all `prds/**/*.md` files grouped by subdirectory; clicking a node opens the file in the editor with title and status shown as tooltip/description
- **Context menus** on tree nodes:
  - Manifest nodes: "Run Orchestrate" (inline), "Open File"
  - Epic nodes: "Run Orchestrate (this epic only)" (inline)
  - Subtask nodes: "Run Pipeline" (inline)
  - PRD file nodes: "Open File"
- **Auto-refresh** — file system watcher detects changes to `**/manifests/*.json` and `**/prds/**/*.md` and refreshes the tree automatically (500 ms debounce)
- **Refresh button** (`$(refresh)`) in the Wisp Explorer toolbar for manual rescan

## [0.1.0] — 2026-03-20

### Added

- **Full command palette surface** — 11 commands covering all wisp CLI subcommands:
  - `Wisp: Orchestrate Manifest` — run a full manifest pipeline with a file picker
  - `Wisp: Run Pipeline` — run a single PRD against one repository
  - `Wisp: Run Agent` — run any of the 14 named agents directly
  - `Wisp: Generate PRDs` — generate PRD files from a plain-text description, with repeatable repo URL input
  - `Wisp: Generate Context` — generate context skill files for a repository
  - `Wisp: Monitor Logs` — tail logs from a previous pipeline session
  - `Wisp: Install Skills` — install Cursor-compatible skill files into the workspace
  - `Wisp: Update` — self-update the wisp binary
  - `Wisp: Stop Pipeline` — kill the currently-running pipeline process
  - `Wisp: Show Output` — reveal the Wisp Output Channel
- **Streaming output** — agent stdout/stderr appears line-by-line in a dedicated "Wisp" Output Channel
- **Status bar indicator** — shows running/idle state; click to reveal output
- **File pickers** — manifest picker (searches `**/manifests/*.json`) and PRD picker (searches `**/prds/**/*.md`) with fallback to manual path input
- **Process cancellation** — `wisp.stopPipeline` sends SIGTERM to the active process and resets the status bar
- **Concurrent pipeline guard** — attempting to start a second pipeline while one is running shows a warning
