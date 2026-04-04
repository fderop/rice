#!/usr/bin/env bash
set -euo pipefail

command=$(jq -r '.tool_input.command // ""' </dev/stdin)

if echo "$command" | grep -qE 'rm\s+-rf\s+(/|~)'; then
  echo "Blocked: rm -rf / or rm -rf ~ requires explicit user approval." >&2
  exit 2
fi

if echo "$command" | grep -qiE 'DROP\s+(TABLE|DATABASE)'; then
  echo "Blocked: DROP TABLE/DATABASE requires explicit user approval." >&2
  exit 2
fi

if echo "$command" | grep -qE 'alembic\s+(upgrade|downgrade|revision)'; then
  echo "Blocked: alembic upgrade/downgrade/revision requires explicit user approval." >&2
  exit 2
fi

if echo "$command" | grep -qE '(curl|wget)\s+.*\|\s*(ba)?sh'; then
  echo "Blocked: piping curl/wget to sh/bash requires explicit user approval." >&2
  exit 2
fi

exit 0
