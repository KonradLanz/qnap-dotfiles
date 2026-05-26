# QNAP Development Conventions

This document defines where things live on the NAS and why.
It is the source of truth for directory layout, repo placement, and user conventions.

---

## Directory Layout

```
/share/CACHEDEV2_DATA/          ← SSD (fast, survives reboot)
├── config-keeper/              ← git repo: system config snapshots (must be on SSD)
└── repos/                      ← all other development repos
    ├── qnap-dotfiles/            ← this repo
    ├── qnap-config-keeper/       ← config-keeper script source
    └── entware-packages/         ← custom Entware package builds

/share/CE_CACHEDEV4_DATA/homes/admin/    ← admin home (HDD)
    ├── .commonrc                 ← deployed by install.sh
    ├── .profile                  ← deployed by install.sh
    ├── .bashrc                   ← deployed by install.sh
    └── .bash_history             ← persists across reboots (not tracked)
```

### Why SSD for repos?

- HDD volumes spin down after idle periods
- A `git status` or cron snap on a spun-down HDD wakes it up — defeating HDD sleep
- `CACHEDEV2_DATA` is the designated SSD/NVMe cache volume on this NAS
- `config-keeper` runs 4x daily via cron — must never wake HDDs

### Why not `~/` (admin home) for repos?

- Admin home lives on `CE_CACHEDEV4_DATA` (HDD)
- Dotfiles (`.bashrc`, `.profile`) belong there — they are small and only read at login
- Dev repos do not belong there — they involve frequent I/O

---

## User Convention

- **Always work as `admin`** — never directly as `root`
- `admin` has persistent home, root-equivalent rights via QNAP ACL
- `root` home (`/root`) is reset-prone and has no dotfiles support
- Exception: `su` to root only for system-level one-off operations

---

## Git Repo Placement Rules

| Repo | Location | Reason |
|---|---|---|
| `config-keeper` (data) | `/share/CACHEDEV2_DATA/config-keeper/` | Cron job — must be on SSD |
| All dev repos | `/share/CACHEDEV2_DATA/repos/<name>/` | SSD, centrally managed |
| Per-user projects | `~/projects/<name>/` (on own volume) | User-scoped, not admin concern |

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

- Login shell in `/etc/passwd`: `ash` (QNAP default, reset on reboot — do not change)
- Effective interactive shell: `bash` (auto-started via `.profile` using `exec`)
- Shared config: `~/.commonrc` (POSIX sh, sourced by both bash and any future zsh)
- See [commonrc-spec.md](commonrc-spec.md) for the rationale

---

## install.sh Behaviour

`sh install.sh` from the repo root:

1. Deploys dotfiles (`.commonrc`, `.profile`, `.bashrc`, `.inputrc`, `.vimrc`) to `$HOME`
2. Creates `/share/CACHEDEV2_DATA/repos/` if missing
3. With `migrate`: moves existing repos from admin home into `repos/`
4. Backs up any existing dotfile before overwriting (`.bak` suffix)

```sh
sh install.sh           # deploy dotfiles only
sh install.sh migrate   # deploy + migrate repos to CACHEDEV2_DATA/repos/
```
