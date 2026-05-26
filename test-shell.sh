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
# $0 trap: when run as 'sh test-shell.sh', $0 = script path, not shell name.
# Use $BASH_VERSION instead — set by bash itself unconditionally.
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

# --- 8. config-keeper data repo: exists, has remote, can fetch ---
CK="/share/CACHEDEV2_DATA/config-keeper"
if [ -d "$CK/.git" ]; then
  ok "$CK is a git repo"

  REMOTE=$(git -C "$CK" remote get-url origin 2>/dev/null || echo "")
  if [ -n "$REMOTE" ]; then
    ok "config-keeper remote: $REMOTE"
  else
    fail "config-keeper has no remote — run: git -C $CK remote add origin https://github.com/KonradLanz/qnap-config-keeper.git"
  fi

  # git fetch (read-only connectivity check)
  if git -C "$CK" fetch --dry-run origin 2>/dev/null; then
    ok "config-keeper: git fetch origin reachable"
  else
    warn "config-keeper: git fetch --dry-run failed (network issue or remote wrong?)"
  fi

  # check for unpushed commits
  AHEAD=$(git -C "$CK" rev-list origin/main..HEAD 2>/dev/null | wc -l | tr -d ' ')
  if [ "${AHEAD:-0}" -eq 0 ]; then
    ok "config-keeper: no unpushed commits"
  else
    fail "config-keeper: $AHEAD unpushed commit(s) — run: git -C $CK push origin main"
  fi

  # check for uncommitted changes
  if git -C "$CK" diff --quiet HEAD 2>/dev/null; then
    ok "config-keeper: working tree clean"
  else
    warn "config-keeper: uncommitted changes present (run: git -C $CK status)"
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
  warn "qnap-dotfiles not found at $DOTFILES (run from the repo itself?)"
fi

# --- 10. git-filter-repo available ---
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
