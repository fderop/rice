# Run

```
curl -fsSL https://raw.githubusercontent.com/fderop/rice/main/setup.sh | bash && exec zsh
```

## macOS extras

`setup.sh` targets fresh Linux. macOS-only bits live in their own scripts.

### iTerm2 Asgard layout (`scripts/setup-iterm-asgard.sh`)

Binds Ctrl+N to a one-shot iTerm2 window: 4 tabs (one per `glass_bio*` worktree on asgard), each tab vertically split — left pane runs `claude -c` under `aws-vault exec claude-viewer-fdr`, right pane is a plain zsh under `aws-vault exec fdr-viewer`. All 8 panes ssh to asgard independently.

Install (clean macOS, same user):

```
brew install --cask iterm2     # if missing
open -a iTerm                  # creates the prefs plist, then quit it
./scripts/setup-iterm-asgard.sh
```

The script deploys two wrappers (`~/.iterm-asgard-{claude,fdrviewer}.sh`), two iTerm2 Dynamic Profiles, and the Ctrl+N keybinding. Idempotent. Refuses to run while iTerm2 is open. Templates live in `iterm-asgard/` with `__HOME__` placeholders substituted at install time.

Assumed but not verified: `Host asgard` in `~/.ssh/config`, aws-vault profiles `claude-viewer-fdr` and `fdr-viewer` on asgard, `claude` on PATH on asgard, worktrees `/home/fdr/repositories/glass_bio{,_2,_3,_4}`.

## Codex config sync

Rice pushes Codex config to the local machine with:

```bash
./scripts/setup-codex.sh
```

To make rice match the current local Codex config and permission rules, pull them back with:

```bash
./scripts/sync-codex-from-local.sh
```

That copies the Codex configuration, rules, global instructions, and custom skills into `codex/`. Then it prints the git status.

The setup does not copy authentication, sessions, caches, or system-managed skills. Sign in to Claude and Codex on each new machine.
The installer replaces `__HOME__` in the Codex configuration with the current home directory.
