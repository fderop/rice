#!/usr/bin/env bash
set -euo pipefail

# Adds iTerm2 triggers for Claude Code hooks to the active profile.
# Triggers run `afplay` to play sounds when hook markers appear in terminal output.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
AUDIO_DIR="$SCRIPT_DIR/audio"
PLIST="$HOME/Library/Preferences/com.googlecode.iterm2.plist"

if [ ! -f "$PLIST" ]; then
  echo "Error: iTerm2 preferences not found at $PLIST"
  exit 1
fi

python3 - "$AUDIO_DIR" "$PLIST" <<'PYEOF'
import sys, plistlib, copy

audio_dir = sys.argv[1]
plist_path = sys.argv[2]

triggers_to_add = [
    {
        "action": "ScriptTrigger",
        "contentregex": "",
        "disabled": False,
        "matchType": 0,
        "name": "Claude Stop",
        "parameter": f"afplay {audio_dir}/aoe-reliq.mp3",
        "partial": True,
        "regex": "@@HOOK:Stop@@",
    },
    {
        "action": "ScriptTrigger",
        "contentregex": "",
        "disabled": False,
        "matchType": 0,
        "name": "Claude Notification",
        "parameter": f"afplay {audio_dir}/aoe-reliq.mp3",
        "partial": True,
        "regex": "@@HOOK:Notification@@",
    },
    {
        "action": "ScriptTrigger",
        "contentregex": "",
        "disabled": False,
        "matchType": 0,
        "name": "Claude Permission request",
        "parameter": f"afplay {audio_dir}/villager-creation.mp3",
        "partial": True,
        "regex": "@@HOOK:PermissionRequest@@",
    },
]

with open(plist_path, "rb") as f:
    prefs = plistlib.load(f)

profiles = prefs.get("New Bookmarks", [])
if not profiles:
    print("Error: No iTerm2 profiles found.")
    sys.exit(1)

# Find the default profile (the one marked as default, or first)
default_guid = prefs.get("Default Bookmark Guid", "")
target = None
for p in profiles:
    if p.get("Guid") == default_guid:
        target = p
        break
if target is None:
    target = profiles[0]

print(f"Updating profile: {target.get('Name', 'unnamed')}")

existing = target.get("Triggers", [])
existing_regexes = {t.get("regex") for t in existing}

added = 0
for trigger in triggers_to_add:
    if trigger["regex"] in existing_regexes:
        # Update in place (fixes path/parameter if changed)
        for i, t in enumerate(existing):
            if t.get("regex") == trigger["regex"]:
                existing[i] = trigger
                print(f"  Updated: {trigger['name']}")
                break
    else:
        existing.append(trigger)
        added += 1
        print(f"  Added: {trigger['name']}")

target["Triggers"] = existing

with open(plist_path, "wb") as f:
    plistlib.dump(prefs, f)

if added == 0:
    print("All triggers already present (paths updated).")
else:
    print(f"Added {added} new trigger(s).")
print("Restart iTerm2 or open a new tab for changes to take effect.")
PYEOF
