#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$SCRIPT_DIR/../codex"
CODEX_DIR="${CODEX_HOME:-$HOME/.codex}"

SKILLS_ONLY=false
case "${1:-}" in
    --skills-only) SKILLS_ONLY=true ;;
    "") ;;
    *) echo "Usage: $0 [--skills-only]" >&2; exit 2 ;;
esac

mkdir -p "$CODEX_DIR/skills"

if [ "$SKILLS_ONLY" = false ]; then
    mkdir -p "$CODEX_DIR/rules"

    # Rules: make the local managed rule set match rice.
    find "$CODEX_DIR/rules" -maxdepth 1 -type f -name '*.rules' -delete
    for rules_file in "$SRC_DIR"/rules/*.rules; do
        [ -e "$rules_file" ] || continue
        cp "$rules_file" "$CODEX_DIR/rules/$(basename "$rules_file")"
        echo "Codex rules installed at $CODEX_DIR/rules/$(basename "$rules_file")"
    done

    config_contents=$(<"$SRC_DIR/config.toml")
    printf '%s\n' "${config_contents//__HOME__/$HOME}" > "$CODEX_DIR/config.toml"
    echo "Codex config installed at $CODEX_DIR/config.toml"

    cp "$SRC_DIR/AGENTS.md" "$CODEX_DIR/AGENTS.md"
    echo "Codex global instructions installed at $CODEX_DIR/AGENTS.md"
fi

# Skills: make custom skills match rice. Preserve hidden system-managed skills.
if [ -d "$SRC_DIR/skills" ]; then
    if [ "$SKILLS_ONLY" = false ]; then
        for skill_dir in "$CODEX_DIR"/skills/*; do
            [ -e "$skill_dir" ] || continue
            if [ ! -d "$SRC_DIR/skills/$(basename "$skill_dir")" ]; then
                rm -rf "$skill_dir"
                echo "Removed stale Codex skill at $skill_dir"
            fi
        done
    fi

    for skill_dir in "$SRC_DIR"/skills/*; do
        [ -d "$skill_dir" ] || continue
        dest="$CODEX_DIR/skills/$(basename "$skill_dir")"
        rm -rf "$dest"
        cp -R "$skill_dir" "$dest"
        echo "Codex skill installed at $dest"
    done
fi
