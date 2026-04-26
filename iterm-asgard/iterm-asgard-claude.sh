#!/bin/zsh
# Asgard "claude" pane wrapper.
#
# - No arg: orchestrator. Builds the 4-tabs-by-2-panes layout, then runs as the
#   tab-1 left pane for `glass_bio`. This is the entry point bound to Ctrl+N.
# - One arg: just the claude pane for that worktree. Used by the orchestrator
#   when it creates tabs 2-4.

WORKTREE="${1:-glass_bio}"

if [[ -z "$1" ]]; then
  /usr/bin/osascript <<'OSAEND'
tell application "iTerm"
    activate
    set theWindow to current window
    tell current session of theWindow
        split vertically with profile "Asgard + fdr-viewer" command "__HOME__/.iterm-asgard-fdrviewer.sh glass_bio"
    end tell
    set worktrees to {"glass_bio_2", "glass_bio_3", "glass_bio_4"}
    repeat with wt in worktrees
        set wtName to contents of wt
        tell theWindow
            set newTab to (create tab with profile "Asgard + Claude" command ("__HOME__/.iterm-asgard-claude.sh " & wtName))
        end tell
        tell current session of newTab
            split vertically with profile "Asgard + fdr-viewer" command ("__HOME__/.iterm-asgard-fdrviewer.sh " & wtName)
        end tell
    end repeat
    try
        tell first tab of theWindow to select
    end try
end tell
OSAEND
fi

exec ssh -t asgard "cd /home/fdr/repositories/${WORKTREE} && exec env AWS_VAULT_BACKEND=file aws-vault exec claude-viewer-fdr --duration=12h -- zsh -ic 'claude -c; exec zsh -i'"
