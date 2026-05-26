#!/bin/sh
# install.sh — Deploy dotfiles to QNAP home directory
# Usage: sh install.sh
# Run from the repo root on the QNAP device.

set -e

HOME_DIR="${HOME:-/root}"
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Installing dotfiles from $REPO_DIR to $HOME_DIR"
echo ""

for f in .commonrc .profile .bashrc .bash_profile .inputrc .vimrc; do
  src="$REPO_DIR/$f"
  dst="$HOME_DIR/$f"
  if [ -f "$src" ]; then
    if [ -f "$dst" ] && ! diff -q "$src" "$dst" >/dev/null 2>&1; then
      echo "  Backing up: $dst -> ${dst}.bak"
      cp "$dst" "${dst}.bak"
    fi
    cp "$src" "$dst"
    echo "  Installed:  $dst"
  fi
done

echo ""
echo "Done. Start a new session or run:"
echo "  . ~/.profile"
