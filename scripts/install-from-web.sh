#!/usr/bin/env bash
# Web installer for claude-pager. Users run:
#   curl -fsSL https://raw.githubusercontent.com/REPLACE_OWNER/claude-pager/main/scripts/install-from-web.sh | bash
# It clones the repo to ~/.local/share/claude-pager-src and runs install.sh.
set -euo pipefail

REPO="${CLAUDE_PAGER_REPO:-https://github.com/REPLACE_OWNER/claude-pager.git}"
DEST="${CLAUDE_PAGER_SRC:-$HOME/.local/share/claude-pager-src}"

command -v git >/dev/null || { echo "git is required"; exit 1; }

if [[ -d "$DEST/.git" ]]; then
  echo "updating $DEST"
  git -C "$DEST" fetch --depth=1 origin main
  git -C "$DEST" reset --hard origin/main
else
  echo "cloning into $DEST"
  mkdir -p "$(dirname "$DEST")"
  git clone --depth=1 "$REPO" "$DEST"
fi

exec "$DEST/install.sh"
