# =============================================================================
# .profile — POSIX login shell init (sourced by sh, dash, ash, bash --login)
#
# On QNAP QTS:
#   - /etc/passwd uses /bin/sh (busybox ash) as login shell
#   - /etc/passwd is reset on every reboot by the firmware
#   - .profile is the only reliable hook for login sessions
#
# Strategy: set up PATH, then exec bash if available (and not already bash).
# This gives an interactive bash session without changing /etc/passwd.
# =============================================================================

# ── Entware PATH (must come before exec bash check) ──────────────────────────
case ":$PATH:" in
  *:/opt/bin:*) ;;
  *) export PATH="/opt/bin:/opt/sbin:$PATH" ;;
esac

# ── Source .commonrc ─────────────────────────────────────────────────────────
[ -f "$HOME/.commonrc" ] && . "$HOME/.commonrc"

# ── Auto-start bash instead of ash ───────────────────────────────────────────
# Only exec if: bash exists, we are interactive, and we are NOT already bash.
# The 'exec' replaces the ash process — no double shell, no performance cost.
if [ -x "/opt/bin/bash" ]; then
  case "$-" in
    *i*)
      # Interactive session: check if current shell is already bash
      if [ -z "${BASH_VERSION:-}" ]; then
        export SHELL="/opt/bin/bash"
        exec /opt/bin/bash --login
      fi
      ;;
  esac
fi
