#!/usr/bin/env bash
set -euo pipefail

PLIST_PATH="$HOME/Library/LaunchAgents/com.claudepager.daemon.plist"
INSTALL_DIR="$HOME/.local/share/claude-pager"
CONFIG_DIR="$HOME/.config/claude-pager"
CLAUDE_SETTINGS="$HOME/.claude/settings.json"

echo "stopping daemon"
launchctl unload "$PLIST_PATH" 2>/dev/null || true
rm -f "$PLIST_PATH"

echo "removing hook entry from $CLAUDE_SETTINGS"
if [[ -f "$CLAUDE_SETTINGS" ]]; then
  python3 - "$CLAUDE_SETTINGS" <<'PY'
import json, sys
path = sys.argv[1]
with open(path) as f:
    cfg = json.load(f)
hooks = cfg.get("hooks", {})
notif = hooks.get("Notification", [])
def is_ours(entry):
    for h in entry.get("hooks", []):
        cmd = h.get("command", "")
        if "claude-pager-hook" in cmd or "wrist-approve-hook" in cmd:
            return True
    return False
notif = [e for e in notif if not is_ours(e)]
if notif:
    hooks["Notification"] = notif
else:
    hooks.pop("Notification", None)
with open(path, "w") as f:
    json.dump(cfg, f, indent=2)
PY
fi

echo "removing $INSTALL_DIR"
rm -rf "$INSTALL_DIR"

echo "removing shell wrapper from rc files"
for rc in "$HOME/.zshrc" "$HOME/.bashrc"; do
  [[ -f "$rc" ]] || continue
  if grep -q "claude-pager wrapper" "$rc"; then
    python3 - "$rc" <<'PY'
import sys
path = sys.argv[1]
with open(path) as f:
    src = f.read()
start, end = "# >>> claude-pager wrapper >>>", "# <<< claude-pager wrapper <<<"
while start in src and end in src:
    i = src.index(start)
    j = src.index(end) + len(end)
    # Eat surrounding blank lines so we don't leave gaps.
    while i > 0 and src[i-1] == "\n":
        i -= 1
    while j < len(src) and src[j] == "\n":
        j += 1
    src = src[:i] + ("\n" if i > 0 and j < len(src) else "") + src[j:]
with open(path, "w") as f:
    f.write(src)
PY
    echo "  cleaned $rc"
  fi
done

read -r -p "also delete config + secret at $CONFIG_DIR? [y/N] " ans
if [[ "$ans" == "y" || "$ans" == "Y" ]]; then
  rm -rf "$CONFIG_DIR"
  echo "removed."
else
  echo "kept config; reinstall will reuse the same topics/secret."
fi
