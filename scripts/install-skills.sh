#!/bin/bash
set -euo pipefail

# Install skills from this project into your Cursor skills directory.
# Usage: ./scripts/install-skills.sh [--project <path>]
#
# Without arguments: installs to ~/.cursor/skills/ (personal)
# With --project: installs to <path>/.cursor/skills/ (project-specific)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_SRC="$SCRIPT_DIR/../skills"
TARGET_DIR="$HOME/.cursor/skills"

while [[ $# -gt 0 ]]; do
  case $1 in
    --project)
      TARGET_DIR="$2/.cursor/skills"
      shift 2
      ;;
    *)
      echo "Usage: $0 [--project <path>]"
      exit 1
      ;;
  esac
done

mkdir -p "$TARGET_DIR"

echo "Installing skills from $SKILLS_SRC to $TARGET_DIR..."

for skill_dir in "$SKILLS_SRC"/*/; do
  skill_name=$(basename "$skill_dir")
  target="$TARGET_DIR/$skill_name"

  if [ -L "$target" ]; then
    echo "  Updating symlink: $skill_name"
    rm "$target"
  elif [ -d "$target" ]; then
    echo "  Skipping $skill_name (directory already exists, not a symlink)"
    continue
  else
    echo "  Installing: $skill_name"
  fi

  ln -s "$(realpath "$skill_dir")" "$target"
done

echo ""
echo "Done. Installed skills:"
ls -la "$TARGET_DIR"/ | grep '^l'
echo ""
echo "Skills are now available in Cursor. Restart Cursor to pick them up."
