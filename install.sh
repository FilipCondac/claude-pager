#!/usr/bin/env bash
# Source-checkout installer. Copies the binaries into ~/.local/share/claude-pager,
# adds them to PATH for this process, and runs claude-pager-setup for the
# per-user wiring. Idempotent.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$HOME/.local/share/claude-pager"

command -v python3 >/dev/null || { echo "python3 required"; exit 1; }
if ! command -v tmux >/dev/null; then
  if command -v brew >/dev/null; then
    echo "installing tmux via brew"
    brew install tmux
  else
    echo "install tmux first: brew install tmux"; exit 1
  fi
fi

echo "installing binaries to $INSTALL_DIR"
mkdir -p "$INSTALL_DIR/bin" "$INSTALL_DIR/launchd"
cp "$REPO_DIR/bin/claude-pager-hook"    "$INSTALL_DIR/bin/"
cp "$REPO_DIR/bin/claude-pager-daemon"  "$INSTALL_DIR/bin/"
cp "$REPO_DIR/bin/claude-pager-setup"   "$INSTALL_DIR/bin/"
cp "$REPO_DIR/bin/claude-pager-status"  "$INSTALL_DIR/bin/"
cp "$REPO_DIR/bin/claude-pager-test"    "$INSTALL_DIR/bin/"
cp "$REPO_DIR/launchd/com.claudepager.daemon.plist.template" "$INSTALL_DIR/launchd/"
chmod 755 "$INSTALL_DIR/bin/"*

export PATH="$INSTALL_DIR/bin:$PATH"
export CLAUDE_PAGER_PLIST_TEMPLATE="$INSTALL_DIR/launchd/com.claudepager.daemon.plist.template"
exec "$INSTALL_DIR/bin/claude-pager-setup"
