#!/usr/bin/env bash
set -euo pipefail

SETTINGS_FILE="$HOME/.claude/settings.json"

mkdir -p "$HOME/.claude"

if [ -f "$SETTINGS_FILE" ]; then
  # Merge hooks into existing settings using jq
  tmp=$(mktemp)
  jq '.hooks = {
    "Notification": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "printf '\''\\a'\''"
          }
        ]
      }
    ]
  }' "$SETTINGS_FILE" > "$tmp" && mv "$tmp" "$SETTINGS_FILE"
else
  cat > "$SETTINGS_FILE" <<'EOF'
{
  "hooks": {
    "Notification": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "printf '\\a'"
          }
        ]
      }
    ]
  }
}
EOF
fi

echo "Claude Code bell notification hook installed in $SETTINGS_FILE"
