# =============================================================================
# .bashrc — bash interactive shell configuration (QNAP QTS + Entware)
#
# Sourced for every new interactive bash session.
# Delegates shared config to .commonrc; bash-specific options live here.
# =============================================================================

# ── Bail out if not interactive ───────────────────────────────────────────────
[[ $- != *i* ]] && return

# ── Source shared config ──────────────────────────────────────────────────────
[ -f "$HOME/.commonrc" ] && . "$HOME/.commonrc"

# ── bash options ─────────────────────────────────────────────────────────────
shopt -s histappend       # append history, don't overwrite
shopt -s checkwinsize     # update LINES/COLUMNS after each command
shopt -s cdspell          # typo correction for cd
shopt -s autocd 2>/dev/null || true   # type directory name to cd (bash 4+)

# ── History: write + reload after every command ───────────────────────────────
PROMPT_COMMAND="history -a; history -c; history -r${PROMPT_COMMAND:+; $PROMPT_COMMAND}"

# ── Prompt ────────────────────────────────────────────────────────────────────
# Green user@host, blue path, reset — safe for both color and no-color terms
if [ -x "$(command -v tput)" ] && tput setaf 1 >/dev/null 2>&1; then
  _PS_USER='\[\033[0;32m\]\u@\h\[\033[0m\]'
  _PS_PATH='\[\033[0;34m\]\w\[\033[0m\]'
else
  _PS_USER='\u@\h'
  _PS_PATH='\w'
fi
PS1="${_PS_USER}:${_PS_PATH}\\$ "
unset _PS_USER _PS_PATH

# ── bash completion (Entware) ─────────────────────────────────────────────────
if [ -f /opt/etc/bash_completion ]; then
  . /opt/etc/bash_completion
elif [ -f /opt/share/bash-completion/bash_completion ]; then
  . /opt/share/bash-completion/bash_completion
fi
