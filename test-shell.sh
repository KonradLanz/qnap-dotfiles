#!/bin/sh
# =============================================================================
# test-shell.sh — Verify dotfiles, shell, and git repos are correctly set up
#
# Run AFTER install.sh and after reconnecting via SSH:
#   bash /share/CACHEDEV2_DATA/repos/qnap-dotfiles/test-shell.sh
#
# NOTE: always invoke with 'bash', not 'sh':
#   sh test-shell.sh   → $0 = "test-shell.sh"  (script name, not shell name)
#   bash test-shell.sh → $BASH_VERSION = 5.x   (correct detection)
#
# Why $0 is wrong for shell detection:
#   $0 is the name of the running script when invoked as 'sh script.sh'.
#   It only reflects the shell name for interactive sessions (-bash, -sh).
#   $BASH_VERSION is set by bash itself regardless of how the script is called.
#
# Why config-keeper has no 'origin' remote (by design):
#   config-keeper contains sensitive snapshots (keys, hashes, tokens).
#   It is intentionally NOT pushed to GitHub. The only remote is 'backup',
#   pointing to a local bare repo on CE_CACHEDEV4_DATA.
#   See CONVENTIONS.md for the data/script separation rationale.
# =============================================================================

PASS=0
FAIL=0

ok()   { echo "  PASS  $1"; PASS=$((PASS+1)); }
fail() { echo "  FAIL  $1"; FAIL=$((FAIL+1)); }
info() { echo "  INFO  $1"; }
warn() { echo "  WARN  $1"; }

echo ""
echo "=== test-shell.sh ==="
echo ""

# --- 1. Active shell is bash ---
info "\$0           = $0"
info "\$BASH_VERSION = ${BASH_VERSION:-<not set>}"
info "(tip: run with 'bash test-shell.sh', not 'sh test-shell.sh')"
case "${BASH_VERSION:-}" in
  5.*) ok "Active shell is bash 5.x (BASH_VERSION=$BASH_VERSION)" ;;
  4.*) ok "Active shell is bash 4.x (BASH_VERSION=$BASH_VERSION)" ;;
  3.*) fail "Shell is bash 3.x — this is QNAP's bundled /bin/bash, not Entware. Run: exec /opt/bin/bash --login" ;;
  "")  fail "Active shell is NOT bash (BASH_VERSION not set) — reconnect via SSH after install.sh" ;;
  *)   fail "Unexpected BASH_VERSION=$BASH_VERSION" ;;
esac

# --- 2. Real bash is Entware bash 5.x ---
if [ -x "/opt/bin/bash" ]; then
  VER=$(/opt/bin/bash -c 'echo ${BASH_VERSINFO[0]}')
  if [ "$VER" -ge 5 ] 2>/dev/null; then
    ok "/opt/bin/bash is version 5.x (got: $(/opt/bin/bash --version | head -1))"
  else
    fail "/opt/bin/bash exists but version < 5 (got: $VER)"
  fi
else
  fail "/opt/bin/bash not found — run: opkg install bash"
fi

# --- 3. /bin/bash is NOT the real bash (QNAP symlink trap) ---
REAL=$(readlink /bin/bash 2>/dev/null || echo "")
if [ "$REAL" = "sh" ] || [ "$REAL" = "busybox" ]; then
  ok "/bin/bash → $REAL (expected QNAP symlink — real bash is /opt/bin/bash)"
else
  info "/bin/bash → ${REAL:-<not a symlink>}"
fi

# --- 4. PATH contains /opt/bin ---
case ":$PATH:" in
  *:/opt/bin:*) ok "PATH contains /opt/bin" ;;
  *)            fail "PATH missing /opt/bin (current PATH: $PATH)" ;;
esac

# --- 5. git is available and is Entware git ---
if command -v git >/dev/null 2>&1; then
  GIT_PATH=$(command -v git)
  GIT_VER=$(git --version)
  ok "git found: $GIT_PATH ($GIT_VER)"
else
  fail "git not found — run: opkg install git"
fi

# --- 6. Dotfiles deployed to HOME ---
for f in .commonrc .profile .bashrc .inputrc; do
  if [ -f "$HOME/$f" ]; then
    ok "$HOME/$f exists"
  else
    fail "$HOME/$f missing — run: sh install.sh"
  fi
done

# --- 7. repos/ directory exists on SSD ---
REPOS="/share/CACHEDEV2_DATA/repos"
if [ -d "$REPOS" ]; then
  ok "$REPOS exists"
else
  fail "$REPOS missing — run: mkdir -p $REPOS"
fi

# --- 8. config-keeper data repo: exists, has local backup remote (NOT GitHub) ---
CK="/share/CACHEDEV2_DATA/config-keeper"
BACKUP_REMOTE="/share/CE_CACHEDEV4_DATA/backup/config-keeper.git"
if [ -d "$CK/.git" ]; then
  ok "$CK is a git repo"

  # config-keeper must NOT have an origin remote (data stays local)
  ORIGIN=$(git -C "$CK" remote get-url origin 2>/dev/null || echo "")
  if [ -n "$ORIGIN" ]; then
    fail "config-keeper has 'origin' remote set to $ORIGIN — sensitive data repo must NOT push to GitHub. Run: git -C $CK remote remove origin"
  else
    ok "config-keeper: no 'origin' remote (correct — data stays local)"
  fi

  # config-keeper must have a local backup remote
  BACKUP=$(git -C "$CK" remote get-url backup 2>/dev/null || echo "")
  if [ -n "$BACKUP" ]; then
    ok "config-keeper backup remote: $BACKUP"
  else
    fail "config-keeper has no 'backup' remote — run: git -C $CK remote add backup $BACKUP_REMOTE"
  fi

  # check local backup bare repo exists
  if [ -d "$BACKUP_REMOTE" ]; then
    ok "backup bare repo exists: $BACKUP_REMOTE"
  else
    fail "backup bare repo missing — run: git clone --bare $CK $BACKUP_REMOTE"
  fi

  # check for uncommitted changes
  if git -C "$CK" diff --quiet HEAD 2>/dev/null; then
    ok "config-keeper: working tree clean"
  else
    warn "config-keeper: uncommitted changes present (run: git -C $CK status)"
  fi

  # check for unpushed commits to backup
  AHEAD=$(git -C "$CK" rev-list backup/main..HEAD 2>/dev/null | wc -l | tr -d ' ')
  if [ "${AHEAD:-0}" -eq 0 ]; then
    ok "config-keeper: backup is up-to-date"
  else
    fail "config-keeper: $AHEAD unpushed commit(s) to backup — run: git -C $CK push backup main"
  fi
else
  fail "$CK is not a git repo"
fi

# --- 9. dotfiles repo: check for unpushed commits ---
DOTFILES="$REPOS/qnap-dotfiles"
if [ -d "$DOTFILES/.git" ]; then
  AHEAD=$(git -C "$DOTFILES" rev-list origin/main..HEAD 2>/dev/null | wc -l | tr -d ' ')
  if [ "${AHEAD:-0}" -eq 0 ]; then
    ok "qnap-dotfiles: no unpushed commits"
  else
    fail "qnap-dotfiles: $AHEAD unpushed commit(s) — run: git -C $DOTFILES push origin main"
  fi
else
  warn "qnap-dotfiles not found at $DOTFILES"
fi

# --- 10. qnap-config-keeper script repo ---
KEEPER="$REPOS/qnap-config-keeper"
if [ -d "$KEEPER/.git" ]; then
  REMOTE=$(git -C "$KEEPER" remote get-url origin 2>/dev/null || echo "")
  if [ -n "$REMOTE" ]; then
    ok "qnap-config-keeper script repo remote: $REMOTE"
  else
    fail "qnap-config-keeper has no remote — run: git -C $KEEPER remote add origin https://github.com/KonradLanz/qnap-config-keeper.git"
  fi
  AHEAD=$(git -C "$KEEPER" rev-list origin/main..HEAD 2>/dev/null | wc -l | tr -d ' ')
  if [ "${AHEAD:-0}" -eq 0 ]; then
    ok "qnap-config-keeper: no unpushed commits"
  else
    fail "qnap-config-keeper: $AHEAD unpushed commit(s) — run: git -C $KEEPER push origin main"
  fi
else
  fail "qnap-config-keeper script repo missing — run: git clone https://github.com/KonradLanz/qnap-config-keeper.git $KEEPER"
fi

# --- 11. git-filter-repo available ---
if [ -x "/opt/bin/git-filter-repo" ]; then
  ok "git-filter-repo found at /opt/bin/git-filter-repo"
else
  fail "git-filter-repo missing — run: curl -L https://raw.githubusercontent.com/newren/git-filter-repo/main/git-filter-repo -o /opt/bin/git-filter-repo && chmod +x /opt/bin/git-filter-repo"
fi

# --- Summary ---
echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
echo ""
[ "$FAIL" -eq 0 ] && echo "All good!" || echo "Fix the FAILs above, then re-run."
echo ""
