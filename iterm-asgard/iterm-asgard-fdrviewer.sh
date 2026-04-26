#!/bin/zsh
# Asgard "fdr-viewer" pane wrapper. Plain zsh, no claude. Worktree from $1.
WORKTREE="${1:-glass_bio}"
exec ssh -t asgard "cd /home/fdr/repositories/${WORKTREE} && exec env AWS_VAULT_BACKEND=file aws-vault exec fdr-viewer --duration=12h -- zsh -i"
