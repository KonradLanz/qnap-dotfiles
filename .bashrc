# .bashrc — QNAP QTS (bash 3.2)
# Place in /share/NFSv=4/homes/admin/.bashrc
# Re-apply after QTS firmware update.

# -----------------------------------------------------------------
# History — persistent across reconnects and abrupt SSH drops
# -----------------------------------------------------------------
export HISTSIZE=10000
export HISTFILESIZE=10000
export HISTFILE="$HOME/.bash_history"

# Ignore duplicate entries and commands starting with a space
export HISTCONTROL=ignorespace:ignoredups

# Ignore noisy short commands
export HISTIGNORE="ls:ll:la:cd:pwd:exit:history"

# Append to history file; don't overwrite it on exit
shopt -s histappend

# Write each command to HISTFILE immediately after it is executed
# This survives abrupt SSH disconnects (no clean shell exit needed)
export PROMPT_COMMAND="history -a${PROMPT_COMMAND:+; $PROMPT_COMMAND}"

# -----------------------------------------------------------------
# Shell options
# -----------------------------------------------------------------
shopt -s checkwinsize   # Update LINES/COLUMNS after each command
shopt -s cdspell        # Correct minor typos in cd paths (bash 4+ only; harmless on 3.2)

# -----------------------------------------------------------------
# Prompt
# -----------------------------------------------------------------
# Simple, readable prompt: user@host dir $
PS1='[\u@\h \W]\$ '

# -----------------------------------------------------------------
# PATH — prefer Entware binaries if installed
# -----------------------------------------------------------------
if [ -d /opt/bin ]; then
  export PATH="/opt/bin:/opt/sbin:$PATH"
fi

# -----------------------------------------------------------------
# Aliases
# -----------------------------------------------------------------
alias ll='ls -lah'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'

# History helpers
alias h='history'
alias hg='history | grep'

# Safe defaults for destructive operations
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# -----------------------------------------------------------------
# Entware bash (if available and not already running it)
# -----------------------------------------------------------------
# Uncomment to auto-switch to Entware bash on login:
# if [ -x /opt/bin/bash ] && [ "$BASH" != "/opt/bin/bash" ]; then
#   exec /opt/bin/bash --login
# fi
