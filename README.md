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

## Codex skill updates on Linux and macOS

Rice stores a shared snapshot of custom Codex skills. Changes reach another machine after publication to `main` and a local update.

On the source machine, copy the current custom skills into Rice:

```bash
cd ~/rice
./scripts/sync-codex-from-local.sh --skills-only
git diff -- codex/skills
```

Review and commit the changes, then publish them through the repository's normal review process.
This repository is public. Include only skills that you intend to publish.

On another machine, clone Rice once if it is absent:

```bash
git clone https://github.com/fderop/rice.git ~/rice
```

For an existing clone, first switch to `main` and run `git pull --ff-only` to obtain the update script.
Then run this command whenever you want the latest shared skills:

```bash
~/rice/scripts/update-codex-skills.sh
```

The command pulls the current branch with `--ff-only` and installs the shared skills into `${CODEX_HOME:-$HOME/.codex}/skills`.
Use the `main` branch on machines that receive updates. A failed pull stops the installation.
The command preserves configuration, permission rules, global instructions, authentication, system skills, and local skills absent from Rice.
It replaces same-named skill directories. Export local edits before updating those skills.

To install skills from the current checkout without a Git pull, run `./scripts/setup-codex.sh --skills-only`.

## Full Codex config sync

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

## Zsh settings

Install the shared aliases, PATH entries, AWS Vault backend, and Git helpers with:

```bash
./scripts/setup-zsh.sh
```

The installer adds a source line to `.zshrc` and copies the settings to `~/.config/rice/rice.zsh`.
Run it again to update those settings. It preserves other `.zshrc` content, including local database settings.
The `main()` helper updates `main` and fast-forwards the `main_copy_1` through `main_copy_3` worktrees.
