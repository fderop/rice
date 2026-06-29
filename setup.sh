#!/bin/bash
set -e

# Get the directory where this script is located (save early before any cd commands)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Starting terminal setup ==="

# Self-bootstrap: when piped (e.g. `curl ... | bash`), only setup.sh exists and
# $SCRIPT_DIR has none of the repo's sibling files. Fetch the full repo tarball
# and re-point $SCRIPT_DIR at it so the skills/hooks/codex/prefs steps can run.
# Uses curl+tar (not git) so it works on a fresh machine before git is installed.
if [ ! -d "$SCRIPT_DIR/claude/skills" ]; then
    echo "Repo files not found next to script (piped install?) — fetching full repo..."
    CACHE_DIR="$HOME/.cache/rice-setup"
    rm -rf "$CACHE_DIR"
    mkdir -p "$CACHE_DIR"
    if command -v curl >/dev/null 2>&1 && \
       curl -fsSL "https://github.com/fderop/rice/archive/refs/heads/main.tar.gz" \
         | tar -xz -C "$CACHE_DIR" --strip-components=1; then
        SCRIPT_DIR="$CACHE_DIR"
        echo "Repo fetched to $CACHE_DIR"
    else
        echo "Could not fetch repo — skills, hooks, codex, and prefs steps will be skipped."
    fi
fi

# Detect OS for package manager
if [ "$(uname)" = "Darwin" ]; then
    OS="macos"
elif [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "Cannot detect OS. Exiting."
    exit 1
fi

# Install dependencies via the platform package manager
if [[ "$OS" == "macos" ]]; then
    # macOS uses Homebrew (no sudo). zsh and curl already ship with macOS.
    echo "Installing dependencies via Homebrew..."
    if ! command -v brew >/dev/null 2>&1; then
        echo "Homebrew not found. Installing Homebrew..."
        NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    # Ensure brew is on PATH for this session (Apple Silicon and Intel locations)
    if [ -x /opt/homebrew/bin/brew ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -x /usr/local/bin/brew ]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
    if command -v brew >/dev/null 2>&1; then
        set +e
        brew install git python3 node jq
        if [ $? -ne 0 ]; then
            echo "Some Homebrew packages failed to install. Continuing..."
        fi
        set -e
    else
        echo "Homebrew unavailable — install git, python3, node, and jq manually."
    fi
# Check if user has sudo access (prompts once, caches creds)
elif echo "Checking for sudo access..." && sudo -v 2>/dev/null; then
    echo "Sudo access detected. Installing dependencies..."
    set +e  # Temporarily disable exit on error
    if [[ "$OS" == "ubuntu" ]] || [[ "$OS" == "debian" ]]; then
        sudo apt-get update && sudo apt-get install -y git curl zsh python3 python3-venv nodejs npm jq
        if [ $? -ne 0 ]; then
            echo "Package installation failed. Skipping..."
        fi
    elif [[ "$OS" == "fedora" ]] || [[ "$OS" == "rhel" ]] || [[ "$OS" == "centos" ]]; then
        sudo dnf install -y git curl zsh python3 nodejs npm jq
        if [ $? -ne 0 ]; then
            echo "Package installation failed. Skipping..."
        fi
    elif [[ "$OS" == "arch" ]] || [[ "$OS" == "manjaro" ]]; then
        sudo pacman -S --noconfirm git curl zsh python nodejs npm jq
        if [ $? -ne 0 ]; then
            echo "Package installation failed. Skipping..."
        fi
    else
        echo "Unsupported OS. Please install git, curl, zsh, python3, nodejs/npm, and jq manually if needed."
    fi
    set -e  # Re-enable exit on error
else
    echo "No sudo access detected. Skipping package installation."
    echo "Please ensure git, curl, zsh, python3, nodejs/npm, and jq are installed."
fi

# Install Oh My Zsh
echo "Installing Oh My Zsh..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
    echo "Oh My Zsh already installed, skipping..."
fi

# Set zsh as default shell
echo "Setting zsh as default shell..."
ZSH_PATH="$(which zsh)"
if [ "$SHELL" != "$ZSH_PATH" ]; then
    if chsh -s "$ZSH_PATH" 2>/dev/null; then
        echo "Default shell changed to zsh. Log out and back in for this to take effect."
    elif sudo chsh -s "$ZSH_PATH" "$USER" 2>/dev/null; then
        echo "Default shell changed to zsh via sudo. Log out and back in for this to take effect."
    else
        echo "Could not change default shell automatically."
        echo "  Run manually: sudo chsh -s $ZSH_PATH $USER"
    fi
fi

# Configure git (skip if already configured)
echo "Configuring git..."
existing_name=$(git config --global user.name || true)
existing_email=$(git config --global user.email || true)
DEFAULT_GIT_USERNAME="fderop"
DEFAULT_GIT_EMAIL="florian.van.de.rop@gmail.com"
if [ -n "$existing_name" ] && [ -n "$existing_email" ]; then
    echo "Git already configured: $existing_name <$existing_email>"
else
    git_username="${GIT_USERNAME:-$DEFAULT_GIT_USERNAME}"
    git_email="${GIT_EMAIL:-$DEFAULT_GIT_EMAIL}"
    git config --global user.name "$git_username"
    git config --global user.email "$git_email"
    echo "Git configured with user: $git_username <$git_email>"
    echo "  (Override with GIT_USERNAME=... GIT_EMAIL=... ./setup.sh)"
fi

# Install Ranger
# Clear any existing GitHub HTTPS->SSH rewrite so the anonymous ranger pull works
# even on re-runs where a previous setup already configured the rewrite globally.
git config --global --unset-all url."git@github.com:".insteadOf 2>/dev/null || true

echo "Installing Ranger..."
if [ ! -d "$HOME/ranger" ]; then
    git clone https://github.com/ranger/ranger.git "$HOME/ranger"
else
    echo "Ranger already installed, updating..."
    cd "$HOME/ranger" && git pull
fi

# Rewrite GitHub HTTPS remotes to SSH (after ranger pull, which is anonymous HTTPS)
echo "Configuring git to use SSH for GitHub..."
git config --global url."git@github.com:".insteadOf "https://github.com/"

# Create Python virtual environment for Ranger
echo "Creating Python virtual environment..."
if [ ! -d "$HOME/.venv" ]; then
    python3 -m venv "$HOME/.venv"
fi

# Create ranger config directory
mkdir -p "$HOME/.config/ranger"

# Add alias to .zshrc
echo "Adding ranger alias to .zshrc..."
# Ensure .zshrc exists (Oh My Zsh should have created it)
if [ ! -f "$HOME/.zshrc" ]; then
    touch "$HOME/.zshrc"
fi

# Note: alias starts with a space so 'r' commands won't be saved to history
ALIAS_LINE="alias r=' ~/.venv/bin/python ~/ranger/ranger.py --choosedir=\$HOME/.config/ranger/.rangerdir; LASTDIR=\`cat \$HOME/.config/ranger/.rangerdir\`; cd \"\$LASTDIR\"; echo -en \"\\e[?25h\"'"

if ! grep -q "alias r=" "$HOME/.zshrc"; then
    echo "" >> "$HOME/.zshrc"
    echo "# Ranger file manager alias (starts with space to avoid history)" >> "$HOME/.zshrc"
    echo "$ALIAS_LINE" >> "$HOME/.zshrc"
    echo "" >> "$HOME/.zshrc"
    echo "# ZSH History Configuration" >> "$HOME/.zshrc"
    echo "HISTFILE=~/.zsh_history" >> "$HOME/.zshrc"
    echo "HISTSIZE=100000" >> "$HOME/.zshrc"
    echo "SAVEHIST=100000" >> "$HOME/.zshrc"
    echo "setopt HIST_IGNORE_DUPS" >> "$HOME/.zshrc"
    echo "setopt HIST_IGNORE_SPACE" >> "$HOME/.zshrc"
    echo "bindkey '^R' history-incremental-search-backward" >> "$HOME/.zshrc"
    echo "Alias and history configuration added to .zshrc"
else
    echo "Ranger alias already exists in .zshrc"
fi

# Add `main` git helper function to .zshrc
if ! grep -q "^main() {" "$HOME/.zshrc"; then
    echo "Adding 'main' git helper to .zshrc..."
    cat >> "$HOME/.zshrc" <<'MAIN_FUNC'

# `main`: switch this worktree to main and pull. If main is checked out in
# another worktree, park that worktree on placeholder `test` (or `test2` if
# test is taken) to free up main, then switch here.
main() {
  if git switch main 2>/dev/null; then
    git pull
    return
  fi
  local other
  other=$(git worktree list --porcelain | awk '
    /^worktree /{p=substr($0,10)}
    /^branch refs\/heads\/main$/{print p}')
  if [[ -z "$other" ]]; then
    echo "main: could not switch to main (uncommitted changes?)." >&2
    return 1
  fi
  local b
  for b in test test2; do
    if git -C "$other" switch "$b" 2>/dev/null || git -C "$other" switch -c "$b" 2>/dev/null; then
      echo "main: parked '$other' on '$b' to free up main." >&2
      git switch main
      git pull
      return
    fi
  done
  echo "main: could not park '$other' on test or test2." >&2
  return 1
}
MAIN_FUNC
else
    echo "'main' git helper already exists in .zshrc"
fi

# Persist Homebrew on PATH for future shells (macOS)
if [[ "$OS" == "macos" ]] && command -v brew >/dev/null 2>&1; then
    BREW_BIN="$(command -v brew)"
    if ! grep -q "brew shellenv" "$HOME/.zshrc" 2>/dev/null; then
        echo "" >> "$HOME/.zshrc"
        echo "# Homebrew" >> "$HOME/.zshrc"
        echo "eval \"\$($BREW_BIN shellenv)\"" >> "$HOME/.zshrc"
    fi
fi

# Install Claude Code and Codex CLIs via npm (user-global, no sudo)
echo "Installing Claude Code and Codex CLIs..."
if command -v npm >/dev/null 2>&1; then
    NPM_PREFIX="$HOME/.npm-global"
    mkdir -p "$NPM_PREFIX"
    npm config set prefix "$NPM_PREFIX"
    export PATH="$NPM_PREFIX/bin:$PATH"

    if ! grep -q "\.npm-global/bin" "$HOME/.zshrc" 2>/dev/null; then
        echo "" >> "$HOME/.zshrc"
        echo "# npm user-global bin" >> "$HOME/.zshrc"
        echo "export PATH=\"\$HOME/.npm-global/bin:\$PATH\"" >> "$HOME/.zshrc"
    fi

    set +e
    npm install -g @anthropic-ai/claude-code
    if [ $? -ne 0 ]; then
        echo "Claude Code install failed. Continuing..."
    fi
    npm install -g @openai/codex
    if [ $? -ne 0 ]; then
        echo "Codex install failed. Continuing..."
    fi
    set -e
else
    echo "npm not found — skipping Claude Code and Codex CLI install."
fi

# Install repo helper scripts onto PATH
echo "Installing helper scripts from bin/..."
BIN_SRC="$SCRIPT_DIR/bin"
LOCAL_BIN="$HOME/.local/bin"
if [ -d "$BIN_SRC" ]; then
    mkdir -p "$LOCAL_BIN"
    for f in "$BIN_SRC"/*; do
        [ -e "$f" ] || continue
        ln -sf "$f" "$LOCAL_BIN/$(basename "$f")"
    done
    echo "Helper scripts symlinked into $LOCAL_BIN"

    if ! grep -q "\.local/bin" "$HOME/.zshrc" 2>/dev/null; then
        echo "" >> "$HOME/.zshrc"
        echo "# user-local bin (repo helper scripts)" >> "$HOME/.zshrc"
        echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> "$HOME/.zshrc"
    fi
else
    echo "Helper scripts source not found at $BIN_SRC — skipping."
fi

# Install global Claude Code preferences
echo "Installing Claude Code preferences..."
CLAUDE_SRC="$SCRIPT_DIR/claude/CLAUDE.md"
CLAUDE_DEST="$HOME/.claude/CLAUDE.md"
if [ -f "$CLAUDE_SRC" ]; then
    mkdir -p "$HOME/.claude"
    if [ -f "$CLAUDE_DEST" ] && cmp -s "$CLAUDE_SRC" "$CLAUDE_DEST"; then
        echo "Claude Code preferences already up to date, skipping..."
    else
        cp "$CLAUDE_SRC" "$CLAUDE_DEST"
        echo "Claude Code preferences installed at $CLAUDE_DEST"
    fi
else
    echo "Claude Code preferences source not found at $CLAUDE_SRC — skipping."
    echo "  (This happens when running via 'bash <(curl ...)' since \$SCRIPT_DIR is /dev/fd.)"
    echo "  To install Claude Code and its preferences:"
    echo "    1. Install Claude Code: https://claude.com/claude-code"
    echo "    2. Clone this repo: git clone https://github.com/fderop/rice.git"
    echo "    3. Re-run ./setup.sh from the cloned directory"
fi

# Install global Claude Code skills
echo "Installing Claude Code skills..."
SKILLS_SRC="$SCRIPT_DIR/claude/skills"
SKILLS_DEST="$HOME/.claude/skills"
if [ -d "$SKILLS_SRC" ]; then
    mkdir -p "$SKILLS_DEST"
    cp -r "$SKILLS_SRC/." "$SKILLS_DEST/"
    echo "Claude Code skills installed at $SKILLS_DEST"
else
    echo "Claude Code skills source not found at $SKILLS_SRC — skipping."
fi

# Setup Claude Code hooks
echo "Setting up Claude Code hooks..."
if [ -f "$SCRIPT_DIR/scripts/setup-claude-hooks.sh" ]; then
    "$SCRIPT_DIR/scripts/setup-claude-hooks.sh"
else
    echo "Hook script not found at $SCRIPT_DIR/scripts/setup-claude-hooks.sh — skipping."
    echo "  (Clone the repo and re-run ./setup.sh to install hooks.)"
fi

# Setup Codex CLI safety config
echo "Setting up Codex CLI safety config..."
if [ -f "$SCRIPT_DIR/scripts/setup-codex.sh" ]; then
    "$SCRIPT_DIR/scripts/setup-codex.sh"
else
    echo "Codex setup script not found at $SCRIPT_DIR/scripts/setup-codex.sh — skipping."
    echo "  (Clone the repo and re-run ./setup.sh to install.)"
fi

echo ""
echo "=== Setup complete! ==="
echo ""
echo "To start using your new setup:"
echo "1. Log out and log back in (or run: exec zsh)"
echo "2. Run 'r' to launch ranger"
echo "3. Claude Code hooks and Codex safety rules are configured"
echo ""
