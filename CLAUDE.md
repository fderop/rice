# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Personal terminal setup ("rice") repo. Bash scripts for fresh Linux machines (Ubuntu/Debian, Fedora/RHEL/CentOS, Arch/Manjaro). No build system, linter, or tests.

- **setup.sh** — Installs zsh, Oh My Zsh, Ranger, configures git, deploys `utils/` scripts to `~/utils`
- **setup-claude-hooks.sh** — Adds bell notification hook to `~/.claude/settings.json`
- **utils/pr_comments** — Fetches unresolved PR comments via GitHub GraphQL (requires `gh`, env `AUTHOR` defaults to `jkhales`)

Scripts use strict error handling (`set -euo pipefail`) and are idempotent.
