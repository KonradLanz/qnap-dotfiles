#!/bin/sh
# install.sh — Deploy dotfiles to QNAP home directory
# Usage: sh install.sh
# Run from the repo root on the QNAP device.
#
# TODO: Decide whether to integrate with qnap-config-keeper
#       or ship as a standalone Entware package.

set -e

HOME_DIR="${HOME:-/share/NFSv=4/homes/admin}"
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Installing dotfiles from $REPO_DIR to $HOME_DIR"

for f in .bashrc .bash_profile .inputrc .vimrc; do
  src="$REPO_DIR/$f"
  dst="$HOME_DIR/$f"
  if [ -f "$src" ]; then
    if [ -f "$dst" ]; then
      echo "  Backing up existing $dst -> ${dst}.bak"
      cp "$dst" "${dst}.bak"
    fi
    cp "$src" "$dst"
    echo "  Installed: $dst"
  fi
done

# Reload history config in current shell if bash is running
if [ -n "$BASH_VERSION" ]; then
  # shellcheck disable=SC1090
  . "$HOME_DIR/.bashrc"
  echo "  Reloaded .bashrc in current bash session"
fi

echo "Done. Reconnect or run: . ~/.bashrc"
