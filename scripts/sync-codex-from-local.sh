#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SRC_CODEX_DIR="${CODEX_HOME:-$HOME/.codex}"
DEST_CODEX_DIR="$REPO_DIR/codex"

if [ ! -f "$SRC_CODEX_DIR/config.toml" ]; then
    echo "Missing local Codex config: $SRC_CODEX_DIR/config.toml" >&2
    exit 1
fi

if [ ! -d "$SRC_CODEX_DIR/rules" ]; then
    echo "Missing local Codex rules directory: $SRC_CODEX_DIR/rules" >&2
    exit 1
fi

if [ ! -f "$SRC_CODEX_DIR/AGENTS.md" ]; then
    echo "Missing local Codex instructions: $SRC_CODEX_DIR/AGENTS.md" >&2
    exit 1
fi

if [ ! -d "$SRC_CODEX_DIR/skills" ]; then
    echo "Missing local Codex skills directory: $SRC_CODEX_DIR/skills" >&2
    exit 1
fi

mkdir -p "$DEST_CODEX_DIR/rules" "$DEST_CODEX_DIR/skills"
config_contents=$(<"$SRC_CODEX_DIR/config.toml")
printf '%s\n' "${config_contents//$HOME/__HOME__}" > "$DEST_CODEX_DIR/config.toml"
cp "$SRC_CODEX_DIR/AGENTS.md" "$DEST_CODEX_DIR/AGENTS.md"

# Make rice reflect the current local rule set exactly.
find "$DEST_CODEX_DIR/rules" -maxdepth 1 -type f -name '*.rules' -delete
for rules_file in "$SRC_CODEX_DIR"/rules/*.rules; do
    [ -e "$rules_file" ] || continue
    cp "$rules_file" "$DEST_CODEX_DIR/rules/$(basename "$rules_file")"
done

# Make rice reflect the current custom skill set exactly. Ignore hidden,
# system-managed skills such as ~/.codex/skills/.system.
find "$DEST_CODEX_DIR/skills" -mindepth 1 -maxdepth 1 ! -name '.*' -exec rm -rf {} +
for skill_dir in "$SRC_CODEX_DIR"/skills/*; do
    [ -d "$skill_dir" ] || continue
    cp -R "$skill_dir" "$DEST_CODEX_DIR/skills/$(basename "$skill_dir")"
done

echo "Synced Codex configuration, rules, instructions, and custom skills from $SRC_CODEX_DIR into $DEST_CODEX_DIR"
if command -v git >/dev/null 2>&1 && git -C "$REPO_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git -C "$REPO_DIR" status --short -- codex scripts/setup-codex.sh scripts/sync-codex-from-local.sh
fi
