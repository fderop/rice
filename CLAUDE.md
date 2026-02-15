# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Personal terminal setup ("rice") repo. Bash scripts for fresh Linux machines (Ubuntu/Debian, Fedora/RHEL/CentOS, Arch/Manjaro). No build system, linter, or tests.

- **setup.sh** — Installs zsh, Oh My Zsh, Ranger, configures git, sets up Claude Code hooks
- **scripts/setup-claude-hooks.sh** — Adds lifecycle hooks to `~/.claude/settings.json`

Scripts use strict error handling (`set -euo pipefail`) and are idempotent.
