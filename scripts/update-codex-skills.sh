#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

git -C "$REPO_DIR" pull --ff-only
"$SCRIPT_DIR/setup-codex.sh" --skills-only
