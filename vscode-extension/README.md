# Wisp for VS Code

[![VS Code Marketplace](https://img.shields.io/visual-studio-marketplace/v/delehner.wisp?label=VS%20Code%20Marketplace)](https://marketplace.visualstudio.com/items?itemName=delehner.wisp)

Run [Wisp](https://github.com/delehner/wisp) AI pipelines directly from VS Code — no terminal switching required. Every Wisp CLI command is available from the Command Palette.

## Requirements

- **VS Code 1.85 or later**
- **wisp CLI installed and on PATH** — the extension is a thin launcher; it requires the `wisp` binary. See the [Installation Guide](https://github.com/delehner/wisp/blob/main/docs/vscode-install.md) for how to install the CLI.

## Quick Start

1. Install this extension from the Marketplace.
2. Open a folder that contains a `manifests/` or `prds/` directory to activate the extension automatically.
3. Open the Command Palette (`Cmd+Shift+P` / `Ctrl+Shift+P`) and run **Wisp: Show Version**.

You should see the `wisp` version string in the output. If the command reports that the binary is not found, see [Configuration](#configuration) below.

## Features

### Commands

| Command | Description |
|---------|-------------|
| **Wisp: Show Version** | Runs `wisp --version` and displays the output — use this to verify the extension can find the `wisp` binary |

> More commands (`orchestrate`, `pipeline`, `run`, `generate`, and others) arrive with upcoming extension updates.

### Binary Auto-Detection

The extension finds `wisp` automatically from your system `PATH`. You can override this with the `wisp.binaryPath` setting to pin to a specific build or a non-PATH location.

## Configuration

### `wisp.binaryPath`

| Property | Value |
|----------|-------|
| Type | `string` |
| Default | `""` (use system `PATH`) |
| Scope | User / Machine settings only |

Set this to the absolute path of the `wisp` binary when `wisp` is not on your system `PATH`.

```jsonc
// settings.json (User or Machine settings)
{
  "wisp.binaryPath": "/usr/local/bin/wisp"
}
```

> **Security:** This setting is `machine-overridable` scope — workspace settings cannot override it. This prevents a repository's `.vscode/settings.json` from redirecting the extension to an untrusted binary.

## Documentation

- [Installation Guide](https://github.com/delehner/wisp/blob/main/docs/vscode-install.md) — install via Marketplace, VSIX, or from source
- [Feature Guide](https://github.com/delehner/wisp/blob/main/docs/vscode-extension.md) — all commands, configuration, and troubleshooting
- [Publishing Guide](https://github.com/delehner/wisp/blob/main/docs/vscode-publish.md) — for maintainers: release process and PAT setup

## Troubleshooting

**Binary not found** — Add `wisp` to your `PATH`, or set `wisp.binaryPath` in User Settings to the absolute path of your `wisp` binary. See the [Installation Guide](https://github.com/delehner/wisp/blob/main/docs/vscode-install.md#troubleshooting).

**Commands don't appear in Command Palette** — The extension activates when the workspace contains `manifests/*.json` or `prds/**/*.md` files. Open a wisp project folder, or trigger activation by searching for "Wisp" in the Command Palette.

---

## For Contributors and Maintainers

### Build and test

From the **repository root** (Rust CLI):

```bash
cargo build --release
cargo test
cargo clippy
```

From **`vscode-extension/`**:

```bash
npm ci
npm run compile
npm test
npm run lint
```

### Try it in the editor

1. Open the `vscode-extension` folder in VS Code (File → Open Folder).
2. Run **Run → Start Debugging** (F5) to launch an Extension Development Host.
3. In that window, run **Wisp: Show Version** from the Command Palette.

### Package a `.vsix`

```bash
cd vscode-extension
npm run package
```

Install the generated `.vsix` via **Extensions → … → Install from VSIX…**.

### Publish

Publishing is automated via `.github/workflows/publish-vscode.yml`. Push a `vscode-v*` tag to trigger it. See the [Publishing Guide](https://github.com/delehner/wisp/blob/main/docs/vscode-publish.md) for one-time setup and release steps.

### Scripts

| Script | Action |
|--------|--------|
| `compile` | esbuild bundle → `out/extension.js` |
| `watch` | Rebuild on file changes |
| `test` | Jest unit tests (mocked `vscode`) |
| `lint` | ESLint on `src/**/*.ts` |
| `package` | `vsce package` → `.vsix` |
