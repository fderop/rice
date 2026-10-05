export PATH="$HOME/.local/bin:$HOME/.npm-global/bin:$HOME/.pixi/bin:$HOME/.cargo/bin:$PATH"
export AWS_VAULT_BACKEND=file

codexcalibur() {
  local repo_root common_dir glass_common_dir
  if repo_root=$(git rev-parse --show-toplevel 2>/dev/null) &&
     common_dir=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null) &&
     glass_common_dir=$(git -C "$repo_root/../glass_bio" rev-parse --path-format=absolute --git-common-dir 2>/dev/null) &&
     [[ "${common_dir:A}" == "${glass_common_dir:A}" ]]; then
    aws-vault exec claude-viewer-fdr --duration=12h -- \
      codex resume --last --dangerously-bypass-approvals-and-sandbox "$@"
  else
    command codex resume --last --dangerously-bypass-approvals-and-sandbox "$@"
  fi
}

# `main`: switch this worktree to main and update all main_copy_n worktrees.
main() {
  if ! git switch main 2>/dev/null; then
    local other
    other=$(git worktree list --porcelain | awk '
      /^worktree /{p=substr($0,10)}
      /^branch refs\/heads\/main$/{print p}')
    if [[ -z "$other" ]]; then
      echo "main: could not switch to main (uncommitted changes?)." >&2
      return 1
    fi
    local b
    for b in main_copy_1 main_copy_2 main_copy_3; do
      if git -C "$other" switch "$b" 2>/dev/null || git -C "$other" switch -c "$b" 2>/dev/null; then
        echo "main: parked '$other' on '$b' to free up main." >&2
        git switch main || return 1
        break
      fi
    done
    if [[ "$(git branch --show-current)" != main ]]; then
      echo "main: could not park '$other' on a main_copy_n branch." >&2
      return 1
    fi
  fi

  git pull --ff-only || return 1

  local b copy_path
  for b in main_copy_1 main_copy_2 main_copy_3; do
    git show-ref --verify --quiet "refs/heads/$b" || continue
    if ! git merge-base --is-ancestor "$b" main; then
      echo "main: $b has commits outside main; cannot fast-forward." >&2
      return 1
    fi
    copy_path=$(git worktree list --porcelain | awk -v branch="$b" '
      /^worktree /{p=substr($0,10)}
      $0 == "branch refs/heads/" branch {print p}')
    if [[ -n "$copy_path" ]]; then
      git -C "$copy_path" merge --ff-only main || return 1
    else
      git branch -f "$b" main || return 1
    fi
  done
}

alias codex='codex --dangerously-bypass-approvals-and-sandbox'
alias claude='claude --dangerously-skip-permissions'
