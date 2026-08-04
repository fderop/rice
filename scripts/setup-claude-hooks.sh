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

# Destructive-command permission rules. Ask rules prompt before running;
# deny rules block outright. Leaves .permissions.allow and .defaultMode alone.
ASK_RULES='[
  "Bash(rm:*)",
  "Bash(rmdir:*)",
  "Bash(git reset:*)",
  "Bash(git clean:*)",
  "Bash(git branch -D:*)",
  "Bash(git commit --amend:*)",
  "Bash(git rebase:*)",
  "Bash(git push --force:*)",
  "Bash(git push -f:*)",
  "Bash(git push --force-with-lease:*)",
  "Bash(alembic upgrade:*)",
  "Bash(alembic downgrade:*)",
  "Bash(docker compose down:*)",
  "Bash(docker-compose down:*)",
  "Bash(aws s3 rm:*)",
  "Bash(aws s3 rb:*)",
  "Bash(terraform apply:*)",
  "Bash(terraform destroy:*)"
]'

DENY_RULES='[
  "Bash(rm -rf /:*)",
  "Bash(rm -rf /*)",
  "Bash(rm -fr /:*)",
  "Bash(rm -rf ~:*)",
  "Bash(rm -rf ~/)",
  "Bash(rm -rf $HOME:*)",
  "Bash(git push --force origin main:*)",
  "Bash(git push --force origin master:*)",
  "Bash(git push -f origin main:*)",
  "Bash(git push -f origin master:*)"
]'

if [ -f "$SETTINGS_FILE" ]; then
  tmp=$(mktemp)
  jq \
    --argjson hooks "$FULL_HOOKS" \
    --argjson ask "$ASK_RULES" \
    --argjson deny "$DENY_RULES" \
    '.hooks = $hooks
     | .permissions = (.permissions // {})
     | .permissions.ask = $ask
     | .permissions.deny = $deny
     | .skipWorkflowUsageWarning = true
     | .theme = "auto"
     | .tui = "default"' \
    "$SETTINGS_FILE" > "$tmp" && mv "$tmp" "$SETTINGS_FILE"
else
  jq -n \
    --argjson hooks "$FULL_HOOKS" \
    --argjson ask "$ASK_RULES" \
    --argjson deny "$DENY_RULES" \
    '{hooks: $hooks, permissions: {ask: $ask, deny: $deny}, skipWorkflowUsageWarning: true, theme: "auto", tui: "default"}' \
    > "$SETTINGS_FILE"
fi

echo "Claude Code hooks and permission rules installed in $SETTINGS_FILE"
