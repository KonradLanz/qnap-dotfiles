#!/bin/sh
# =============================================================================
# install.sh — Deploy dotfiles + optionally migrate repos
#
# Usage:
#   sh install.sh           — deploy dotfiles to $HOME
#   sh install.sh migrate   — deploy dotfiles + migrate repos to CACHEDEV2_DATA
#
# See CONVENTIONS.md for the full directory layout rationale.
# =============================================================================

set -e

HOME_DIR="${HOME:-/share/CE_CACHEDEV4_DATA/homes/admin}"
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
REPOS_DIR="/share/CACHEDEV2_DATA/repos"

# ── Deploy dotfiles ──────────────────────────────────────────────────────
echo "=== dotfiles: $REPO_DIR → $HOME_DIR ==="
echo ""

for f in .commonrc .profile .bashrc .bash_profile .inputrc .vimrc; do
  src="$REPO_DIR/$f"
  dst="$HOME_DIR/$f"
  if [ -f "$src" ]; then
    if [ -f "$dst" ] && ! diff -q "$src" "$dst" >/dev/null 2>&1; then
      echo "  backup:   $dst → ${dst}.bak"
      cp "$dst" "${dst}.bak"
    fi
    cp "$src" "$dst"
    echo "  installed: $dst"
  fi
done

echo ""
echo "Dotfiles deployed. Reload with: . ~/.profile"

# ── Migrate repos (optional) ─────────────────────────────────────────────────
[ "${1:-}" = "migrate" ] || exit 0

echo ""
echo "=== migrate: repos → $REPOS_DIR ==="
echo ""

mkdir -p "$REPOS_DIR"

migrate_repo() {
  NAME="$1"
  SRC="$HOME_DIR/$NAME"
  DST="$REPOS_DIR/$NAME"

  if [ ! -d "$SRC/.git" ]; then
    echo "  skip (no .git): $SRC"
    return
  fi

  if [ -d "$DST" ]; then
    echo "  already exists: $DST — skipping"
    return
  fi

  # Ensure remote is set before moving
  REMOTE=$(git -C "$SRC" remote get-url origin 2>/dev/null || echo "")
  if [ -z "$REMOTE" ]; then
    echo "  WARN: $NAME has no remote origin — skipping (set remote first)"
    return
  fi

  echo "  moving: $SRC → $DST"
  mv "$SRC" "$DST"

  # Fix upstream tracking
  git -C "$DST" branch --set-upstream-to=origin/main main 2>/dev/null || true
  echo "  done: $DST"
}

migrate_repo "qnap-config-keeper"
migrate_repo "qnap-dotfiles"
migrate_repo "entware-packages"

# config-keeper data repo stays where it is (CACHEDEV2_DATA/config-keeper)
echo ""
echo "Note: config-keeper data repo stays at /share/CACHEDEV2_DATA/config-keeper/"
echo "      (cron job — must remain on SSD, see CONVENTIONS.md)"
echo ""
echo "Migration done. New repo root: $REPOS_DIR"
echo "Reload shell: exec bash --login"
