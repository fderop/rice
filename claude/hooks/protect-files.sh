#!/usr/bin/env bash
set -euo pipefail

file_path=$(jq -r '.tool_input.file_path // ""' </dev/stdin)
basename=$(basename "$file_path")

if echo "$basename" | grep -qE '^\.env(\..*)?$'; then
  echo "Blocked: editing .env files requires explicit user approval." >&2
  exit 2
fi

if echo "$basename" | grep -qE '\.(pem|key)$'; then
  echo "Blocked: editing .pem/.key files requires explicit user approval." >&2
  exit 2
fi

exit 0
