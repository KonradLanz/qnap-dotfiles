#!/bin/sh
# =============================================================================
# test-shell.sh — Verify dotfiles are correctly deployed and shell is bash
#
# Run AFTER install.sh and after reconnecting via SSH:
#   sh /share/CACHEDEV2_DATA/repos/qnap-dotfiles/test-shell.sh
#
# Each test prints PASS or FAIL with a short explanation.
# =============================================================================

PASS=0
FAIL=0

ok()   { echo "  PASS  $1"; PASS=$((PASS+1)); }
fail() { echo "  FAIL  $1"; FAIL=$((FAIL+1)); }
info() { echo "  INFO  $1"; }

echo ""
echo "=== test-shell.sh ==="
echo ""

# --- 1. Active shell is bash ---
info "\$0   = $0"
info "\$BASH_VERSION = ${BASH_VERSION:-<not set>}"
case "$0" in
  -bash|bash) ok "Active shell is bash" ;;
  *)          fail "Active shell is NOT bash (got: $0) — reconnect via SSH after install.sh" ;;
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

# --- 8. config-keeper data repo on SSD ---
CK="/share/CACHEDEV2_DATA/config-keeper"
if [ -d "$CK/.git" ]; then
  ok "$CK is a git repo"
  REMOTE=$(git -C "$CK" remote get-url origin 2>/dev/null || echo "")
  if [ -n "$REMOTE" ]; then
    ok "config-keeper remote: $REMOTE"
  else
    fail "config-keeper has no remote — run: git -C $CK remote add origin https://github.com/KonradLanz/qnap-config-keeper.git"
  fi
else
  fail "$CK is not a git repo"
fi

# --- 9. git-filter-repo available ---
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
