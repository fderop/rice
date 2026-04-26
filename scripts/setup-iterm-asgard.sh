#!/usr/bin/env bash
set -euo pipefail

# Installs the iTerm2 "Asgard layout":
#   - 2 wrappers in $HOME (claude pane + fdr-viewer pane)
#   - 2 Dynamic Profiles in iTerm2's DynamicProfiles dir
#   - 1 GlobalKeyMap entry: Ctrl+N opens the layout
#
# Idempotent: re-running overwrites in place.
# Targets a clean macOS install for the same user.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASSETS="$(cd "$SCRIPT_DIR/../iterm-asgard" && pwd)"
PLIST="$HOME/Library/Preferences/com.googlecode.iterm2.plist"
DP_DIR="$HOME/Library/Application Support/iTerm2/DynamicProfiles"

echo "=== iTerm2 Asgard layout install ==="

# --- Preflight ---------------------------------------------------------------

if [[ ! -d "/Applications/iTerm.app" && ! -d "$HOME/Applications/iTerm.app" ]]; then
  echo "  ⚠ iTerm.app not found. Install it first:  brew install --cask iterm2"
  exit 1
fi

if [[ ! -f "$PLIST" ]]; then
  echo "  ⚠ iTerm2 prefs plist missing. Launch iTerm2 once to create it, then re-run."
  exit 1
fi

if pgrep -x iTerm2 >/dev/null; then
  echo "  ⚠ iTerm2 is running. Quit it before installing — otherwise the keybinding"
  echo "    edit will be overwritten when iTerm2 next saves prefs."
  exit 1
fi

# --- Substitute __HOME__ → $HOME and deploy ---------------------------------

deploy() {
  local src="$1" dest="$2" mode="$3"
  install -d "$(dirname "$dest")"
  sed "s|__HOME__|$HOME|g" "$src" > "$dest"
  chmod "$mode" "$dest"
  echo "  + $dest"
}

deploy "$ASSETS/iterm-asgard-claude.sh"     "$HOME/.iterm-asgard-claude.sh"          0755
deploy "$ASSETS/iterm-asgard-fdrviewer.sh"  "$HOME/.iterm-asgard-fdrviewer.sh"       0755
deploy "$ASSETS/asgard-claude.json"         "$DP_DIR/asgard-claude.json"             0644
deploy "$ASSETS/asgard-fdrviewer.json"      "$DP_DIR/asgard-fdrviewer.json"          0644

# --- Keybinding: Ctrl+N → "Asgard + Claude" profile -------------------------

python3 - "$PLIST" <<'PYEOF'
import plistlib, sys

plist_path = sys.argv[1]
with open(plist_path, "rb") as f:
    prefs = plistlib.load(f)

# n=110 (0x6e), Control mod=0x40000, virtual keycode N=45 (0x2d)
key = "0x6e-0x40000-0x2d"

prefs.setdefault("GlobalKeyMap", {})[key] = {
    "Version": 2,
    "Apply Mode": 0,
    "Action": 28,                         # New Window with Profile
    "Text": "asgard-claude-fdr-001",      # GUID of Asgard + Claude
    "Escaping": 2,
}

with open(plist_path, "wb") as f:
    plistlib.dump(prefs, f)

print("  + Ctrl+N keybinding -> Asgard + Claude")
PYEOF

# Flush prefs cache so iTerm2 picks up the change on next launch.
killall cfprefsd 2>/dev/null || true

# --- Done -------------------------------------------------------------------

cat <<EOF

=== Done ===

Launch iTerm2 and press Ctrl+N. On first run:
  • macOS will prompt "iTerm wants to control iTerm" — approve it.
  • aws-vault will ask for the file-backend password 8x (once per pane).

NOT verified by this script — set up these yourself if missing:
  • SSH config: Host asgard reachable (~/.ssh/config).
  • Remote: aws-vault profiles 'claude-viewer-fdr' and 'fdr-viewer' exist on asgard.
  • Remote: 'claude' CLI is on PATH inside the aws-vault'd zsh.
  • Remote: /home/fdr/repositories/glass_bio{,_2,_3,_4} exist.

To uninstall:
  rm "\$HOME/.iterm-asgard-claude.sh" "\$HOME/.iterm-asgard-fdrviewer.sh"
  rm "$DP_DIR/asgard-claude.json" "$DP_DIR/asgard-fdrviewer.json"
  /usr/libexec/PlistBuddy -c "Delete :GlobalKeyMap:0x6e-0x40000-0x2d" "$PLIST"
  killall cfprefsd
EOF
