# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Personal terminal setup ("rice") repo. Bash scripts for fresh Linux machines (Ubuntu/Debian, Fedora/RHEL/CentOS, Arch/Manjaro). No build system, linter, or tests.

- **setup.sh** — Installs zsh, Oh My Zsh, Ranger, configures git, installs Claude Code preferences, sets up Claude Code hooks
- **scripts/setup-claude-hooks.sh** — Adds lifecycle hooks and PreToolUse safety hooks to `~/.claude/settings.json`; installs hook scripts to `~/.claude/hooks/`
- **claude/CLAUDE.md** — Personal Claude Code preferences for all projects; installed to `~/.claude/CLAUDE.md`
- **claude/hooks/** — Safety hooks installed to `~/.claude/hooks/`; block destructive commands (rm -rf /, DROP TABLE, alembic migrations, curl-pipe-sh) and protect sensitive files (.env, .pem, .key)

Scripts use strict error handling (`set -euo pipefail`) and are idempotent.
