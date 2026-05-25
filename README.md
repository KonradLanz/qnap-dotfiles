# qnap-dotfiles

Dotfiles for **QNAP QTS** (BusyBox `ash` + firmware-bundled `bash 3.2`).

Focuses on things that are regularly lost or reset after QTS firmware updates:
- Persistent `bash` history across SSH reconnects and abrupt disconnects
- Readline config (arrow-key history search, case-insensitive completion, no bell)
- Minimal `vim` config
- Entware `PATH` integration

## The core problem this solves

QNAP's default login shell is BusyBox `ash`. It does not save history on abrupt
SSH disconnects. Even with `/bin/bash` (v3.2), history is only written on clean
`exit` — not when the connection drops.

This repo ships a `.bashrc` with:
```sh
shopt -s histappend
export PROMPT_COMMAND="history -a${PROMPT_COMMAND:+; $PROMPT_COMMAND}"
```
This writes every command to `~/.bash_history` immediately, surviving any disconnect.

## Files

| File | Purpose |
|---|---|
| `.bashrc` | Main shell config: history, aliases, PATH, prompt |
| `.bash_profile` | Login shell entry point, sources `.bashrc` |
| `.inputrc` | Readline: arrow-key history search, completion, no bell |
| `.vimrc` | Minimal vim config |
| `install.sh` | Deploy script with `.bak` backup of existing files |

## Installation

```sh
# On your QNAP via SSH
cd /share/NFSv=4/homes/admin
git clone https://github.com/KonradLanz/qnap-dotfiles.git
cd qnap-dotfiles
sh install.sh
```

Then reload:
```sh
. ~/.bashrc
```

## After a QTS firmware update

Firmware updates may reset `/bin/bash` or `/etc` but leave
`/share/NFSv=4/homes/admin/` intact. Re-run `sh install.sh` to restore.

The `.bash_history` file itself lives on your data volume and is **not** affected
by firmware updates.

## Relation to qnap-config-keeper

This repo tracks your *shell environment*. The companion project
[qnap-config-keeper](https://github.com/KonradLanz/qnap-config-keeper)
tracks `/etc/config` and system-level config files.

TODO: Decide whether to:
- Keep as a standalone repo (current approach)
- Integrate dotfile tracking into `qnap-config-keeper`
- Package as an Entware `opkg` package

## License

MIT
