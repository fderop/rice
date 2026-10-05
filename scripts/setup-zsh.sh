#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST_DIR="$HOME/.config/rice"
mkdir -p "$DEST_DIR"
cp "$SCRIPT_DIR/../zsh/rice.zsh" "$DEST_DIR/rice.zsh"
touch "$HOME/.zshrc"
SOURCE_LINE='source "$HOME/.config/rice/rice.zsh"'
if ! grep -Fxq "$SOURCE_LINE" "$HOME/.zshrc"; then
    printf '\n%s\n' "$SOURCE_LINE" >> "$HOME/.zshrc"
fi
echo "Rice zsh settings installed at $DEST_DIR/rice.zsh"
