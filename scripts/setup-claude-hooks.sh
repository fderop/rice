#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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

HOOKS_DIR="$HOME/.claude/hooks"
mkdir -p "$HOOKS_DIR"

# Install safety hook scripts
cp "$SCRIPT_DIR/../claude/hooks/block-dangerous.sh" "$HOOKS_DIR/block-dangerous.sh"
cp "$SCRIPT_DIR/../claude/hooks/protect-files.sh" "$HOOKS_DIR/protect-files.sh"
chmod +x "$HOOKS_DIR/block-dangerous.sh" "$HOOKS_DIR/protect-files.sh"

PRE_TOOL_HOOKS=$(jq -n \
  --arg block "$HOOKS_DIR/block-dangerous.sh" \
  --arg protect "$HOOKS_DIR/protect-files.sh" \
  '[
    {"matcher":"Bash","hooks":[{"type":"command","command":$block}]},
    {"matcher":"Edit|Write","hooks":[{"type":"command","command":$protect}]}
  ]')

FULL_HOOKS=$(jq -n \
  --argjson lifecycle "$HOOKS_JSON" \
  --argjson preTool "$PRE_TOOL_HOOKS" \
  '$lifecycle + {"PreToolUse": $preTool}')

if [ -f "$SETTINGS_FILE" ]; then
  # Merge hooks into existing settings using jq
  tmp=$(mktemp)
  jq --argjson hooks "$FULL_HOOKS" '.hooks = $hooks' "$SETTINGS_FILE" > "$tmp" && mv "$tmp" "$SETTINGS_FILE"
else
  jq -n --argjson hooks "$FULL_HOOKS" '{hooks: $hooks}' > "$SETTINGS_FILE"
fi

echo "Claude Code hooks installed in $SETTINGS_FILE"
