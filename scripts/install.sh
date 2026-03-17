#!/bin/bash
set -euo pipefail

# =============================================================================
# Coding Agents Pipeline — Install Script
# =============================================================================
# Installs the `ca` CLI by cloning the repo and symlinking the command.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/delehner/coding-agents/main/scripts/install.sh | bash
#
#   # Or with a custom install directory:
#   curl -fsSL https://raw.githubusercontent.com/delehner/coding-agents/main/scripts/install.sh | bash -s -- --dir ~/.coding-agents
#
#   # Uninstall:
#   curl -fsSL https://raw.githubusercontent.com/delehner/coding-agents/main/scripts/install.sh | bash -s -- --uninstall

REPO_URL="https://github.com/delehner/coding-agents.git"
DEFAULT_INSTALL_DIR="$HOME/.coding-agents"
DEFAULT_BIN_DIR="/usr/local/bin"

# --- Colors ---
if [ -t 1 ]; then
  RESET='\033[0m'
  BOLD='\033[1m'
  DIM='\033[2m'
  GREEN='\033[32m'
  CYAN='\033[36m'
  YELLOW='\033[33m'
  RED='\033[31m'
else
  RESET='' BOLD='' DIM='' GREEN='' CYAN='' YELLOW='' RED=''
fi

info()  { echo -e "${CYAN}${BOLD}==>${RESET} $1"; }
warn()  { echo -e "${YELLOW}${BOLD}warning:${RESET} $1"; }
error() { echo -e "${RED}${BOLD}error:${RESET} $1" >&2; }
ok()    { echo -e "${GREEN}${BOLD}  ✓${RESET} $1"; }

# --- Parse args ---
INSTALL_DIR="$DEFAULT_INSTALL_DIR"
BIN_DIR="$DEFAULT_BIN_DIR"
UNINSTALL=false
BRANCH="main"

while [[ $# -gt 0 ]]; do
  case $1 in
    --dir) INSTALL_DIR="$2"; shift 2 ;;
    --bin-dir) BIN_DIR="$2"; shift 2 ;;
    --branch) BRANCH="$2"; shift 2 ;;
    --uninstall) UNINSTALL=true; shift ;;
    -h|--help)
      cat <<'HELP'
Coding Agents Pipeline — Installer

Usage:
  curl -fsSL <url>/install.sh | bash
  curl -fsSL <url>/install.sh | bash -s -- [options]

Options:
  --dir <path>       Installation directory (default: ~/.coding-agents)
  --bin-dir <path>   Directory for the ca symlink (default: /usr/local/bin)
  --branch <name>    Git branch to install from (default: main)
  --uninstall        Remove ca and the installation directory
  -h, --help         Show this help

What it does:
  1. Clones the coding-agents repo to ~/.coding-agents (or --dir)
  2. Creates a symlink: /usr/local/bin/ca → ~/.coding-agents/ca
  3. Verifies prerequisites (Claude Code CLI, Docker, gh, jq)

After installation, run `ca help` from anywhere.
HELP
      exit 0
      ;;
    *) error "Unknown argument: $1"; exit 1 ;;
  esac
done

# =============================================================================
# Uninstall
# =============================================================================
if [ "$UNINSTALL" = true ]; then
  info "Uninstalling Coding Agents Pipeline..."
  echo ""

  if [ -L "$BIN_DIR/ca" ]; then
    rm -f "$BIN_DIR/ca" 2>/dev/null || sudo rm -f "$BIN_DIR/ca"
    ok "Removed $BIN_DIR/ca"
  else
    warn "$BIN_DIR/ca not found (already removed?)"
  fi

  if [ -d "$INSTALL_DIR" ]; then
    rm -rf "$INSTALL_DIR"
    ok "Removed $INSTALL_DIR"
  else
    warn "$INSTALL_DIR not found (already removed?)"
  fi

  echo ""
  info "Uninstall complete."
  exit 0
fi

# =============================================================================
# Install
# =============================================================================
echo ""
echo -e "${BOLD}Coding Agents Pipeline — Installer${RESET}"
echo ""

# --- Detect OS ---
OS="$(uname -s)"
case "$OS" in
  Darwin) info "Detected macOS" ;;
  Linux)  info "Detected Linux" ;;
  *)      error "Unsupported OS: $OS (only macOS and Linux are supported)"; exit 1 ;;
esac

# --- Check prerequisites ---
info "Checking prerequisites..."

check_cmd() {
  local cmd="$1"
  local name="$2"
  local install_hint="$3"
  if command -v "$cmd" &>/dev/null; then
    local version
    version=$("$cmd" --version 2>&1 | head -1)
    ok "$name ($version)"
    return 0
  else
    warn "$name not found — $install_hint"
    return 1
  fi
}

MISSING=0
check_cmd git "Git" "install with: brew install git (macOS) or apt install git (Linux)" || MISSING=$((MISSING + 1))
check_cmd node "Node.js" "install from https://nodejs.org or: brew install node" || MISSING=$((MISSING + 1))
check_cmd jq "jq" "install with: brew install jq (macOS) or apt install jq (Linux)" || MISSING=$((MISSING + 1))

# Non-blocking checks (pipeline needs these but install can proceed)
OPTIONAL_MISSING=0
check_cmd claude "Claude Code CLI" "install with: npm install -g @anthropic-ai/claude-code" || OPTIONAL_MISSING=$((OPTIONAL_MISSING + 1))
check_cmd docker "Docker" "install from https://docker.com" || OPTIONAL_MISSING=$((OPTIONAL_MISSING + 1))
check_cmd devcontainer "Dev Containers CLI" "install with: npm install -g @devcontainers/cli" || OPTIONAL_MISSING=$((OPTIONAL_MISSING + 1))
check_cmd gh "GitHub CLI" "install with: brew install gh (macOS) or see https://cli.github.com" || OPTIONAL_MISSING=$((OPTIONAL_MISSING + 1))

if [ "$MISSING" -gt 0 ]; then
  echo ""
  error "Missing $MISSING required tool(s). Install them and re-run."
  exit 1
fi

if [ "$OPTIONAL_MISSING" -gt 0 ]; then
  echo ""
  warn "$OPTIONAL_MISSING optional tool(s) missing. Install them before running the pipeline."
fi

# --- Clone or update ---
echo ""
if [ -d "$INSTALL_DIR/.git" ]; then
  info "Updating existing installation at $INSTALL_DIR..."
  git -C "$INSTALL_DIR" fetch origin "$BRANCH" --quiet
  git -C "$INSTALL_DIR" checkout "$BRANCH" --quiet 2>/dev/null || true
  git -C "$INSTALL_DIR" pull origin "$BRANCH" --quiet
  ok "Updated to latest"
else
  if [ -d "$INSTALL_DIR" ]; then
    warn "$INSTALL_DIR exists but is not a git repo — removing and re-cloning"
    rm -rf "$INSTALL_DIR"
  fi
  info "Cloning coding-agents to $INSTALL_DIR..."
  git clone --branch "$BRANCH" "$REPO_URL" "$INSTALL_DIR" --quiet
  ok "Cloned successfully"
fi

# --- Make scripts executable ---
chmod +x "$INSTALL_DIR/ca"
chmod +x "$INSTALL_DIR"/pipeline/*.sh 2>/dev/null || true
chmod +x "$INSTALL_DIR"/pipeline/lib/*.sh 2>/dev/null || true
chmod +x "$INSTALL_DIR"/scripts/*.sh 2>/dev/null || true

# --- Create symlink ---
echo ""
info "Creating symlink: $BIN_DIR/ca → $INSTALL_DIR/ca"

if [ -L "$BIN_DIR/ca" ]; then
  rm -f "$BIN_DIR/ca" 2>/dev/null || sudo rm -f "$BIN_DIR/ca"
fi

if [ -w "$BIN_DIR" ]; then
  ln -sf "$INSTALL_DIR/ca" "$BIN_DIR/ca"
else
  warn "$BIN_DIR is not writable — using sudo"
  sudo ln -sf "$INSTALL_DIR/ca" "$BIN_DIR/ca"
fi

ok "Symlink created"

# --- Verify ---
echo ""
if command -v ca &>/dev/null; then
  ok "ca is available globally"
else
  warn "ca was installed but not found in PATH"
  warn "Add $BIN_DIR to your PATH if it's not already there:"
  echo ""
  echo "  export PATH=\"$BIN_DIR:\$PATH\""
  echo ""
fi

# --- Setup .env if not present ---
if [ ! -f "$INSTALL_DIR/.env" ] && [ -f "$INSTALL_DIR/.env.example" ]; then
  cp "$INSTALL_DIR/.env.example" "$INSTALL_DIR/.env"
  ok "Created .env from .env.example — edit $INSTALL_DIR/.env with your settings"
fi

# --- Done ---
echo ""
echo -e "${GREEN}${BOLD}Installation complete!${RESET}"
echo ""
echo "  Next steps:"
echo ""
echo "    1. Configure authentication:"
echo "       claude                     # login with Claude Max"
echo "       gh auth login              # login to GitHub"
echo ""
echo "    2. Set up your environment:"
echo "       Edit $INSTALL_DIR/.env"
echo ""
echo "    3. Generate context for a repo:"
echo "       ca generate context --repo https://github.com/you/repo --output ./contexts/repo"
echo ""
echo "    4. Generate PRDs and run:"
echo "       ca generate prd --output ./prds/app --manifest ./manifests/app.json \\"
echo "         --repo https://github.com/you/repo --context ./contexts/repo"
echo "       ca orchestrate --manifest ./manifests/app.json"
echo ""
echo "    Run 'ca help' for full usage."
echo ""
echo "  To update:  re-run this install script"
echo "  To remove:  curl ... | bash -s -- --uninstall"
echo ""
