#!/bin/bash
set -e

# Get the directory where this script is located (save early before any cd commands)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Starting terminal setup ==="

# Detect OS for package manager
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "Cannot detect OS. Exiting."
    exit 1
fi

# Check if user has sudo access
echo "Checking for sudo access..."
if sudo -n true 2>/dev/null; then
    echo "Sudo access detected. Installing dependencies..."
    set +e  # Temporarily disable exit on error
    if [[ "$OS" == "ubuntu" ]] || [[ "$OS" == "debian" ]]; then
        sudo apt-get update && sudo apt-get install -y git curl zsh python3 python3-venv
        if [ $? -ne 0 ]; then
            echo "Package installation failed. Skipping..."
        fi
    elif [[ "$OS" == "fedora" ]] || [[ "$OS" == "rhel" ]] || [[ "$OS" == "centos" ]]; then
        sudo dnf install -y git curl zsh python3
        if [ $? -ne 0 ]; then
            echo "Package installation failed. Skipping..."
        fi
    elif [[ "$OS" == "arch" ]] || [[ "$OS" == "manjaro" ]]; then
        sudo pacman -S --noconfirm git curl zsh python
        if [ $? -ne 0 ]; then
            echo "Package installation failed. Skipping..."
        fi
    else
        echo "Unsupported OS. Please install git, curl, zsh, and python3 manually if needed."
    fi
    set -e  # Re-enable exit on error
else
    echo "No sudo access detected. Skipping package installation."
    echo "Please ensure git, curl, zsh, and python3 are installed."
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
if [ "$SHELL" != "$(which zsh)" ]; then
    chsh -s "$(which zsh)"
    echo "Default shell changed to zsh. You'll need to log out and back in for this to take effect."
fi

# Configure git (skip if already configured)
echo "Configuring git..."
existing_name=$(git config --global user.name || true)
existing_email=$(git config --global user.email || true)
if [ -n "$existing_name" ] && [ -n "$existing_email" ]; then
    echo "Git already configured: $existing_name <$existing_email>"
else
    read -p "Enter your git username: " git_username
    read -p "Enter your git email: " git_email
    git config --global user.name "$git_username"
    git config --global user.email "$git_email"
    echo "Git configured with user: $git_username <$git_email>"
fi

# Install Ranger
echo "Installing Ranger..."
if [ ! -d "$HOME/ranger" ]; then
    git clone https://github.com/ranger/ranger.git "$HOME/ranger"
else
    echo "Ranger already installed, updating..."
    cd "$HOME/ranger" && git pull
fi

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

# Setup Claude Code hooks
echo "Setting up Claude Code hooks..."
"$SCRIPT_DIR/scripts/setup-claude-hooks.sh"

echo ""
echo "=== Setup complete! ==="
echo ""
echo "To start using your new setup:"
echo "1. Log out and log back in (or run: exec zsh)"
echo "2. Run 'r' to launch ranger"
echo "3. Claude Code hooks are configured"
echo ""
