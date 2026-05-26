# QNAP Development Conventions

This document defines where things live on the NAS and why.
It is the source of truth for directory layout, repo placement, and user conventions.

---

## Directory Layout

```
/root/                           ← admin HOME (UID 0, persists across reboots)
    ├── .commonrc                ← deployed by install.sh
    ├── .profile                 ← deployed by install.sh
    ├── .bashrc                  ← deployed by install.sh
    └── .bash_history            ← persists across reboots (not tracked)

/share/CACHEDEV2_DATA/          ← SSD (fast, survives reboot)
├── config-keeper/              ← git repo: system config snapshots (must be on SSD)
└── repos/                      ← all other development repos
    ├── qnap-dotfiles/           ← this repo
    ├── qnap-config-keeper/      ← config-keeper script source
    └── entware-packages/        ← custom Entware package builds
```

### Why /root as admin home?

On QNAP, `admin` is UID 0. `/etc/passwd` maps admin → `/root` and resets on
every reboot. `/root` itself persists on the system volume across reboots.
`/share/CE_CACHEDEV4_DATA/homes/admin/` is the QTS file-manager view of the
same user but is **not** the shell home — do not use it for dotfiles.

### Why SSD for repos?

- HDD volumes spin down after idle periods
- A `git status` or cron snap on a spun-down HDD wakes it up — defeating HDD sleep
- `CACHEDEV2_DATA` is the designated SSD/NVMe cache volume on this NAS
- `config-keeper` runs 4x daily via cron — must never wake HDDs

---

## User Convention

- **Always work as `admin`** via SSH — this is UID 0 on QNAP
- `admin` = root on QNAP. There is no separate `root` user to switch to.
- Never rely on `sudo` — it is not installed by default
- Per-user projects (koni, georg, etc.) live on their own volumes, not under admin

---

## Git Repo Placement Rules

| Repo | Location | Reason |
|---|---|---|
| `config-keeper` (data) | `/share/CACHEDEV2_DATA/config-keeper/` | Cron job — must be on SSD |
| All dev repos | `/share/CACHEDEV2_DATA/repos/<name>/` | SSD, centrally managed |
| Per-user projects | user home on own volume | User-scoped, not admin concern |

---

## Clone Convention

All repos under `/share/CACHEDEV2_DATA/repos/` are cloned via HTTPS:

```sh
cd /share/CACHEDEV2_DATA/repos
git clone https://github.com/KonradLanz/<repo>.git
```

This ensures `git pull` and `git push` work without SSH key setup on the NAS.

---

## Repos Tracked Here

| Repo | GitHub | Notes |
|---|---|---|
| `qnap-dotfiles` | [KonradLanz/qnap-dotfiles](https://github.com/KonradLanz/qnap-dotfiles) | This repo |
| `qnap-config-keeper` | [KonradLanz/qnap-config-keeper](https://github.com/KonradLanz/qnap-config-keeper) | System config tracker |
| `entware-packages` | [KonradLanz/entware-packages](https://github.com/KonradLanz/entware-packages) | Custom Entware builds |

> `pct-scanner-py` is developed under the `koni` user and is not an admin/NAS concern.

---

## Shell Convention

- Login shell in `/etc/passwd`: `sh` → BusyBox ash (QNAP default, reset on every reboot)
- `/bin/bash` is a symlink to `sh` on stock QNAP — it is NOT real bash
- Real bash: `/opt/bin/bash` (Entware, bash 5.x)
- Effective interactive shell: `/opt/bin/bash` (auto-started via `.profile` using `exec`)
- `.profile` only fires on **new SSH login** — sourcing it manually does not trigger `exec`
- Shared config: `~/.commonrc` (POSIX sh, sourced by both bash and any future zsh)
- See [commonrc-spec.md](commonrc-spec.md) for the rationale

### How to verify the active shell

```sh
echo $0              # -bash = bash login shell, -sh = ash
echo $BASH_VERSION   # empty if not bash
/opt/bin/bash --version  # should show 5.x
```

### Why .profile does not work when sourced manually

`.profile` uses `exec /opt/bin/bash --login` to replace the ash process.
`exec` replaces the current process — when you `source` (`. ~/.profile`) inside
an already-running ash, the `exec` fires immediately and replaces that shell.
If nothing happens, ash is already being replaced but the terminal re-attaches.
The reliable way to activate: **open a new SSH session**.

---

## install.sh Behaviour

`sh install.sh` from the repo root:

1. Deploys dotfiles (`.commonrc`, `.profile`, `.bashrc`, `.inputrc`, `.vimrc`) to `$HOME` (`/root`)
2. Creates `/share/CACHEDEV2_DATA/repos/` if missing
3. With `migrate`: moves existing repos from admin home into `repos/`
4. Backs up any existing dotfile before overwriting (`.bak` suffix)

```sh
sh install.sh           # deploy dotfiles only
sh install.sh migrate   # deploy + migrate repos to CACHEDEV2_DATA/repos/
```

After install: **disconnect and reconnect via SSH** — do not source `.profile` manually.
