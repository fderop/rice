#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$SCRIPT_DIR/../codex"
CODEX_DIR="$HOME/.codex"

mkdir -p "$CODEX_DIR/rules"
mkdir -p "$CODEX_DIR/skills"

# Rules: make the local managed rule set match rice.
find "$CODEX_DIR/rules" -maxdepth 1 -type f -name '*.rules' -delete
for rules_file in "$SRC_DIR"/rules/*.rules; do
    [ -e "$rules_file" ] || continue
    cp "$rules_file" "$CODEX_DIR/rules/$(basename "$rules_file")"
    echo "Codex rules installed at $CODEX_DIR/rules/$(basename "$rules_file")"
done

# Configuration: make the local configuration match rice.
config_contents=$(<"$SRC_DIR/config.toml")
printf '%s\n' "${config_contents//__HOME__/$HOME}" > "$CODEX_DIR/config.toml"
echo "Codex config installed at $CODEX_DIR/config.toml"

# Global instructions: make the local instructions match rice.
cp "$SRC_DIR/AGENTS.md" "$CODEX_DIR/AGENTS.md"
echo "Codex global instructions installed at $CODEX_DIR/AGENTS.md"

# Skills: make custom skills match rice. Preserve hidden system-managed skills.
if [ -d "$SRC_DIR/skills" ]; then
    for skill_dir in "$CODEX_DIR"/skills/*; do
        [ -e "$skill_dir" ] || continue
        if [ ! -d "$SRC_DIR/skills/$(basename "$skill_dir")" ]; then
            rm -rf "$skill_dir"
            echo "Removed stale Codex skill at $skill_dir"
        fi
    done

    for skill_dir in "$SRC_DIR"/skills/*; do
        [ -d "$skill_dir" ] || continue
        dest="$CODEX_DIR/skills/$(basename "$skill_dir")"
        rm -rf "$dest"
        cp -R "$skill_dir" "$dest"
        echo "Codex skill installed at $dest"
    done
fi
