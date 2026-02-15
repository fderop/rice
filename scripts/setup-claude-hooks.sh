#!/usr/bin/env bash
set -euo pipefail

SETTINGS_FILE="$HOME/.claude/settings.json"

mkdir -p "$HOME/.claude"

HOOKS_JSON='{
  "UserPromptSubmit": [
    {
      "hooks": [
        {
          "type": "command",
          "command": "printf '\''\\0337@@HOOK:UserPromptSubmit@@\\0338'\'' > /dev/tty",
          "async": true
        }
      ]
    }
  ],
  "PermissionRequest": [
    {
      "hooks": [
        {
          "type": "command",
          "command": "printf '\''\\0337@@HOOK:PermissionRequest@@\\0338'\'' > /dev/tty",
          "async": true
        }
      ]
    }
  ],
  "Notification": [
    {
      "hooks": [
        {
          "type": "command",
          "command": "printf '\''\\0337@@HOOK:Notification@@\\0338'\'' > /dev/tty",
          "async": true
        }
      ]
    }
  ],
  "Stop": [
    {
      "hooks": [
        {
          "type": "command",
          "command": "printf '\''\\0337@@HOOK:Stop@@\\0338'\'' > /dev/tty",
          "async": true
        }
      ]
    }
  ]
}'

if [ -f "$SETTINGS_FILE" ]; then
  # Merge hooks into existing settings using jq
  tmp=$(mktemp)
  jq --argjson hooks "$HOOKS_JSON" '.hooks = $hooks' "$SETTINGS_FILE" > "$tmp" && mv "$tmp" "$SETTINGS_FILE"
else
  jq -n --argjson hooks "$HOOKS_JSON" '{hooks: $hooks}' > "$SETTINGS_FILE"
fi

echo "Claude Code hooks installed in $SETTINGS_FILE"
