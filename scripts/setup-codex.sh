#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$SCRIPT_DIR/../codex"
CODEX_DIR="$HOME/.codex"

mkdir -p "$CODEX_DIR/rules"

# Rules file: rice owns it, always overwrite. User-added rules go in a
# sibling file (e.g. ~/.codex/rules/local.rules) — codex scans the dir.
cp "$SRC_DIR/rules/default.rules" "$CODEX_DIR/rules/default.rules"
echo "Codex safety rules installed at $CODEX_DIR/rules/default.rules"

# config.toml: rice owns it, always overwrite. Put personal codex config
# (trusted projects, model overrides, etc.) in ~/.codex/config.local.toml
# or inline additions that don't conflict with the managed keys.
cp "$SRC_DIR/config.toml" "$CODEX_DIR/config.toml"
echo "Codex config installed at $CODEX_DIR/config.toml"
