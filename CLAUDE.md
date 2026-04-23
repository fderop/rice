# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Personal terminal setup ("rice") repo. Bash scripts for fresh Linux machines (Ubuntu/Debian, Fedora/RHEL/CentOS, Arch/Manjaro). No build system, linter, or tests.

- **setup.sh** — Installs zsh, Oh My Zsh, Ranger, configures git, installs Claude Code preferences and skills, sets up Claude Code hooks, sets up Codex CLI safety rules
- **scripts/setup-claude-hooks.sh** — Adds lifecycle hooks, PreToolUse safety hooks, and ask/deny permission rules for destructive commands to `~/.claude/settings.json`; installs hook scripts to `~/.claude/hooks/`
- **scripts/setup-codex.sh** — Installs Codex CLI safety rules to `~/.codex/rules/default.rules` and writes `~/.codex/config.toml`; both always overwrite. User rules go in sibling `.rules` files; personal config entries (e.g. `[projects.*]` trust_level) get clobbered on re-run.
- **claude/CLAUDE.md** — Personal Claude Code preferences for all projects; installed to `~/.claude/CLAUDE.md`
- **claude/hooks/** — Safety hooks installed to `~/.claude/hooks/`; block destructive commands (rm -rf /, DROP TABLE, alembic migrations, curl-pipe-sh) and protect sensitive files (.env, .pem, .key)
- **claude/skills/** — Personal Claude Code skills (codex, new, ship); installed to `~/.claude/skills/`
- **codex/config.toml** — Codex CLI mode: `approval_policy = "on-request"` + `sandbox_mode = "workspace-write"` (autonomous inside workspace, prompts to leave it)
- **codex/rules/default.rules** — Starlark prefix_rule entries marking destructive commands as prompt/forbidden; mirrors the Claude ask/deny list

Scripts use strict error handling (`set -euo pipefail`) and are idempotent.
