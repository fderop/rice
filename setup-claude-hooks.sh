#!/usr/bin/env bash
set -euo pipefail

# Adds Claude Code lifecycle hooks to ~/.claude/settings.json if not already present.
# Requires: jq

if ! command -v jq &>/dev/null; then
  echo "Error: jq is required. Install it with: brew install jq (macOS) or apt install jq (Linux)"
  exit 1
fi

SETTINGS_FILE="$HOME/.claude/settings.json"
mkdir -p "$HOME/.claude"

# Start from existing settings or empty object
if [ -f "$SETTINGS_FILE" ]; then
  settings=$(cat "$SETTINGS_FILE")
else
  settings='{}'
fi

# Define the hooks we want to ensure exist
# Each hook event gets a marker entry that echoes @@HOOK:<event>@@
# Notification also gets the terminal bell entry

add_marker_hook() {
  local event="$1"
  local marker="@@HOOK:${event}@@"

  # Check if this marker already exists in the event's hooks
  if echo "$settings" | jq -e --arg evt "$event" --arg marker "$marker" \
    '.hooks[$evt] // [] | map(.hooks[]?.command) | any(contains($marker))' &>/dev/null; then
    echo "  $event marker hook already present, skipping."
  else
    echo "  Adding $event marker hook."
    settings=$(echo "$settings" | jq --arg evt "$event" --arg marker "$marker" \
      '.hooks[$evt] = (.hooks[$evt] // []) + [{
        "hooks": [{"type": "command", "command": ("echo \u0027" + $marker + "\u0027")}]
      }]')
  fi
}

add_notification_bell() {
  # Check if the bell hook already exists
  if echo "$settings" | jq -e \
    '.hooks.Notification // [] | map(.hooks[]?.command) | any(contains("\\a"))' &>/dev/null; then
    echo "  Notification bell hook already present, skipping."
  else
    echo "  Adding Notification bell hook."
    settings=$(echo "$settings" | jq \
      '.hooks.Notification = [{
        "matcher": "",
        "hooks": [{"type": "command", "command": "printf '\''\\a'\''"}]
      }] + (.hooks.Notification // [])')
  fi
}

echo "Setting up Claude Code hooks in $SETTINGS_FILE..."

# Add the terminal bell for notifications (first, so it appears before the marker)
add_notification_bell

# Add marker hooks for each lifecycle event
for event in UserPromptSubmit PermissionRequest Notification Stop; do
  add_marker_hook "$event"
done

# Write back
echo "$settings" | jq '.' > "$SETTINGS_FILE"

echo "Done. Hooks installed in $SETTINGS_FILE"
