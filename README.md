# qnap-dotfiles

Dotfiles and development conventions for **QNAP QTS** (BusyBox `ash` + Entware `bash`).

Companion project: [qnap-config-keeper](https://github.com/KonradLanz/qnap-config-keeper) — tracks `/etc/config` system files.

---

## Quick Start

```sh
# On your QNAP via SSH (as admin)
export PATH="/opt/bin:/opt/sbin:$PATH"
cd /share/CACHEDEV2_DATA/repos
git clone https://github.com/KonradLanz/qnap-dotfiles.git
cd qnap-dotfiles
sh install.sh migrate   # deploy dotfiles + move repos to CACHEDEV2_DATA/repos/
```

Then reload:
```sh
. ~/.profile   # or reconnect via SSH — bash starts automatically
```

---

## What This Repo Does

| File | Purpose |
|---|---|
| `.commonrc` | Shared POSIX config: PATH, aliases, exports (bash + zsh) |
| `.profile` | Login hook: source `.commonrc` + `exec bash` auto-start |
| `.bashrc` | bash options, prompt, completion |
| `.bash_profile` | Login shell entry point, sources `.bashrc` |
| `.inputrc` | Readline: arrow-key history search, no bell |
| `.vimrc` | Minimal vim config |
| `install.sh` | Deploy dotfiles + optional repo migration |
| `CONVENTIONS.md` | Directory layout, user, and repo placement rules |
| `commonrc-spec.md` | Proposal for a shell-agnostic `.commonrc` standard |

---

## Directory Layout

See [CONVENTIONS.md](CONVENTIONS.md) for the full rationale. In brief:

```
/share/CACHEDEV2_DATA/
├── config-keeper/      ← system config snapshots (cron — must be on SSD)
└── repos/
    ├── qnap-dotfiles/
    ├── qnap-config-keeper/
    └── entware-packages/
```

---

## The `.commonrc` Convention

A single POSIX-compatible file sourced by both `.bashrc` and `.zshrc`.
No duplication, no shell-specific drift. See [commonrc-spec.md](commonrc-spec.md)
for the full proposal and prior art.

---

## Why `exec bash` Instead of Changing `/etc/passwd`

QNAP resets `/etc/passwd` on every reboot. `.profile` uses `exec /opt/bin/bash --login`
to replace the ash process with bash — no subshell overhead, no `/etc/passwd` hacks.

---

## License

AGPLv3
