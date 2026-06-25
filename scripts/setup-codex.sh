#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$SCRIPT_DIR/../codex"
CODEX_DIR="$HOME/.codex"

mkdir -p "$CODEX_DIR/rules"

# Rules files: rice owns every *.rules file in codex/rules and overwrites
# matching files under ~/.codex/rules. Extra local sibling files are left alone;
# codex scans the whole rules directory.
for rules_file in "$SRC_DIR"/rules/*.rules; do
    [ -e "$rules_file" ] || continue
    cp "$rules_file" "$CODEX_DIR/rules/$(basename "$rules_file")"
    echo "Codex rules installed at $CODEX_DIR/rules/$(basename "$rules_file")"
done

# config.toml: rice owns it, always overwrite. Put personal codex config
# (trusted projects, model overrides, etc.) in ~/.codex/config.local.toml
# or inline additions that don't conflict with the managed keys.
cp "$SRC_DIR/config.toml" "$CODEX_DIR/config.toml"
echo "Codex config installed at $CODEX_DIR/config.toml"
