#!/usr/bin/env bash
# =============================================================================
# Update Homebrew formula with SHA256 checksums from GitHub Release assets.
# Used by the release workflow to fix all platform checksums.
#
# Usage:
#   ./scripts/update-homebrew-formula.sh <version> <formula-path>
#   ./scripts/update-homebrew-formula.sh v0.1.2 Formula/wisp.rb
#
# Requires: curl, jq, perl
# =============================================================================
set -euo pipefail

VERSION="${1:?usage: $0 <version> <formula-path>}"
FORMULA_PATH="${2:?usage: $0 <version> <formula-path>}"
REPO="${GITHUB_REPOSITORY:-delehner/wisp}"

# Strip 'v' prefix for formula version (0.1.2 not v0.1.2)
FORMULA_VERSION="${VERSION#v}"

# Order must match the formula: x86_64-apple-darwin, aarch64-apple-darwin,
# x86_64-unknown-linux-gnu, aarch64-unknown-linux-gnu
ASSETS=(
  "wisp-x86_64-apple-darwin.tar.gz"
  "wisp-aarch64-apple-darwin.tar.gz"
  "wisp-x86_64-unknown-linux-gnu.tar.gz"
  "wisp-aarch64-unknown-linux-gnu.tar.gz"
)

echo "Fetching release $VERSION from $REPO..."
RESP=$(curl -sL "https://api.github.com/repos/$REPO/releases/tags/$VERSION")
if echo "$RESP" | jq -e '.assets' >/dev/null 2>&1; then
  : # ok
else
  echo "error: release $VERSION not found or API error" >&2
  exit 1
fi

declare -a SHAS
for asset in "${ASSETS[@]}"; do
  digest=$(echo "$RESP" | jq -r --arg name "$asset" '.assets[] | select(.name == $name) | .digest')
  if [[ -z "$digest" || "$digest" == "null" ]]; then
    echo "error: asset $asset not found in release" >&2
    exit 1
  fi
  # digest format: "sha256:abc123..."
  sha="${digest#sha256:}"
  SHAS+=("$sha")
done

echo "Updating $FORMULA_PATH (version=$FORMULA_VERSION, ${#SHAS[@]} checksums)..."
# Update version
perl -i -pe "s|version \"[^\"]*\"|version \"$FORMULA_VERSION\"|" "$FORMULA_PATH"
# Replace each sha256 line in formula order (x86 mac, arm mac, x86 linux, arm linux).
# The tap commits literal checksums, not PLACEHOLDER — replace all 64-hex digests in order.
export WISP_FORMULA_SHAS="${SHAS[*]}"
perl -i -0777 -pe '
  @shas = split /\s+/, $ENV{WISP_FORMULA_SHAS};
  die "expected 4 checksums, got " . scalar(@shas) unless @shas == 4;
  $i = 0;
  s/sha256 "[^"]+"/qq{sha256 "$shas[$i++]"}/ge;
  die "expected 4 sha256 lines in formula, replaced $i" if $i != 4;
' "$FORMULA_PATH"

echo "Done. Formula updated."
