# The `.commonrc` Convention
## A Proposal for a Shell-Agnostic Shared Configuration Standard

**Status:** Draft Proposal  
**Authors:** KonradLanz/qnap-dotfiles contributors  
**Repository:** https://github.com/KonradLanz/qnap-dotfiles  
**License:** AGPLv3

---

## Abstract

Every major Unix shell — bash, zsh, fish, ksh, dash — defines its own
initialisation file convention. As developers maintain configurations across
multiple machines, operating systems, and shell environments, the absence of a
shared, shell-agnostic init file leads to duplicated configuration, diverging
aliases, and subtle inconsistencies. This document proposes `.commonrc`: a
convention for a single POSIX-compatible shared configuration file sourced by
all interactive shells, analogous to the role `.profile` plays for login shells
but scoped to interactive session setup.

---

## 1. Background and Motivation

### 1.1 The Problem

The POSIX standard (IEEE 1003.1, Single UNIX Specification) defines `~/.profile`
as the login shell initialisation file, and specifies `$ENV` as the init file
for non-login interactive POSIX shells. Beyond these two, each shell has grown
its own convention:

| Shell | Interactive RC file | Login file |
|-------|--------------------|-----------|
| bash  | `~/.bashrc`        | `~/.bash_profile` or `~/.profile` |
| zsh   | `~/.zshrc`         | `~/.zprofile` |
| ksh   | `$ENV`             | `~/.profile` |
| fish  | `~/.config/fish/config.fish` | (same) |
| dash/ash | `$ENV`          | `~/.profile` |

A developer who uses zsh on macOS, bash on a Linux server, and busybox ash
on an embedded NAS must either: (a) duplicate configuration in every shell's
RC file, (b) manually `source` a shared file from each RC file, or (c) maintain
divergent environments. None of these are satisfying; none are codified.

### 1.2 Prior Art

The idea of a shared configuration file has been rediscovered independently
multiple times:

- **Michael Currin (2020)** described `.commonrc` as a convention for sharing
  aliases and exports between bash and zsh dotfiles, and demonstrated sourcing
  it from both `~/.bashrc` and `~/.zshrc`. This appears to be the earliest
  named use of `.commonrc` as a dotfiles convention.
- **Dan Cross (2012)** in *"Dotfiles: Stop the Madness"* observed that the
  accumulation of per-shell init files creates unmaintainable duplication, and
  argued for a single source of truth.
- **Arch Linux Wiki — Dotfiles** documents the pattern of a shared file
  without standardising a filename, noting that many dotfile repositories
  implement it under various names (`shell_common`, `shrc`, `aliases.sh`, etc.).
- **POSIX `$ENV`** provides a partial solution: a shell can be configured to
  source an arbitrary file on interactive startup via the `ENV` environment
  variable. However, bash ignores `$ENV` unless invoked as `sh`, and zsh only
  honours `$ZDOTDIR/.zshenv` — making `$ENV` unreliable across shells.
- **XDG Base Directory Specification** (freedesktop.org) establishes a
  convention for configuration file locations (`$XDG_CONFIG_HOME`) but does
  not address shell initialisation.

### 1.3 Why This Matters on Constrained Systems

The problem becomes acute on embedded or appliance Linux systems — NAS devices
(QNAP, Synology), routers (OpenWrt), and containers — where:

- The system shell is busybox ash (not bash, not zsh)
- Third-party shells (bash, zsh) are installed via package managers
  (Entware, Opkg) into non-standard paths (`/opt/bin`)
- Login shell configuration in `/etc/passwd` is reset by firmware on reboot
- The developer needs identical PATH, aliases, and exports regardless of which
  shell process is active at any moment

In these environments, a shared configuration file is not a convenience — it
is the only viable architecture.

---

## 2. The `.commonrc` Convention

### 2.1 Definition

`.commonrc` is a file located at `$HOME/.commonrc` containing POSIX-compatible
shell configuration — environment variable exports, PATH modifications, aliases,
and function definitions — that is explicitly sourced by each shell's own
interactive RC file.

The file MUST:

- Be valid POSIX sh syntax (no bash-isms, no zsh-isms)
- Be sourced, not executed (`. ~/.commonrc`, not `~/.commonrc`)
- Be idempotent — safe to source multiple times
- Contain only configuration meaningful in an interactive session

The file SHOULD NOT:

- Set `PS1` or `PS2` (prompt is shell-specific)
- Enable shell options (`shopt`, `setopt`) — those are shell-specific
- Start background processes or produce output
- Assume a specific shell version beyond POSIX sh

### 2.2 Sourcing Pattern

Each shell's RC file sources `.commonrc` as its first substantive action:

**`~/.bashrc`:**
```sh
[ -f "$HOME/.commonrc" ] && . "$HOME/.commonrc"
```

**`~/.zshrc`:**
```sh
[ -f "$HOME/.commonrc" ] && . "$HOME/.commonrc"
```

**`~/.kshrc` (via `$ENV`):**
```sh
[ -f "$HOME/.commonrc" ] && . "$HOME/.commonrc"
```

The guard (`[ -f ... ] &&`) ensures the file is optional — removing `.commonrc`
does not break any shell.

### 2.3 Relationship to Existing Standards

```
┌─────────────────────────────────────────────────────────┐
│                    Login Shell                          │
│  ~/.profile  ──source──►  ~/.commonrc                   │
│  (POSIX, all shells)       (proposed convention)        │
└──────────────────┬──────────────────────────────────────┘
                   │ exec
     ┌─────────────┼──────────────┐
     ▼             ▼              ▼
 ~/.bashrc    ~/.zshrc      $ENV file
     │             │              │
     └─────────────┴──────────────┘
           │ all source
           ▼
      ~/.commonrc
```

---

## 3. Filename Candidates

The choice of `.commonrc` over competing names is deliberate but not final.
Known alternatives and their trade-offs:

| Name | Pros | Cons |
|------|------|------|
| `.commonrc` | Readable, follows `*rc` convention, not in use by any tool | Not a POSIX term, no prior art beyond Currin 2020 |
| `.shrc` | Suggests POSIX sh, short | Easily confused with ksh's `$ENV` |
| `.shell_common` | Descriptive | Verbose, not consistent with `*rc` idiom |
| `.env` | Short | Conflicts with direnv, Docker, and many other tools |
| `.aliases` | Common in dotfile repos | Implies aliases only, not exports or functions |
| `.shellrc` | Suggests generic shell | Not used by any existing standard |

**Recommendation:** `.commonrc` — familiar pattern, no conflicts, readable intent.

---

## 4. Relationship to POSIX `$ENV`

POSIX specifies that an interactive shell sources the file named in `$ENV`
at startup. This could theoretically be used to auto-source `.commonrc`
without modifying each shell's RC file:

```sh
export ENV="$HOME/.commonrc"
```

However, this approach has significant limitations:

- `bash` ignores `$ENV` when invoked as `bash` (only honours it when invoked
  as `sh`)
- `zsh` uses `$ZDOTDIR/.zshenv` instead and does not honour `$ENV`
- `fish` has no concept of `$ENV`
- The explicit `source` pattern (Section 2.2) is more portable and transparent

`$ENV` may be used as an additional mechanism for ash/dash/ksh compatibility,
but cannot replace explicit sourcing.

---

## 5. Implementation Notes

### 5.1 PATH Idempotency

PATH modification is the most common reason `.commonrc` gets sourced multiple
times (e.g., login shell sources `.profile` which sources `.commonrc`, then
bash sources `.bashrc` which sources `.commonrc` again). Use a guard:

```sh
case ":$PATH:" in
  *:/opt/bin:*) ;;
  *) export PATH="/opt/bin:/opt/sbin:$PATH" ;;
esac
```

### 5.2 POSIX Compliance Testing

Before adding any construct to `.commonrc`, verify it under a strict POSIX
sh interpreter. On systems with dash:

```sh
dash -n ~/.commonrc   # syntax check
dash ~/.commonrc      # execution check
```

On QNAP/busybox:

```sh
sh -n ~/.commonrc
```

### 5.3 Auto-starting bash on ash systems

On systems where `/etc/passwd` is reset to `/bin/sh` on reboot (QNAP, some
OpenWrt configurations), the recommended pattern is to `exec` bash from
`~/.profile` rather than modifying `/etc/passwd`:

```sh
# ~/.profile
[ -f "$HOME/.commonrc" ] && . "$HOME/.commonrc"
if [ -x "/opt/bin/bash" ] && [ -z "${BASH_VERSION:-}" ]; then
  case "$-" in *i*) exec /opt/bin/bash --login ;; esac
fi
```

This `exec` replaces the ash process with bash — no subshell overhead, and
`.commonrc` is then sourced again by `~/.bashrc`, which is idempotent.

---

## 6. Open Questions

1. **Should `.commonrc` be located at `$HOME/.commonrc` or
   `$XDG_CONFIG_HOME/shell/commonrc`?** XDG compliance would reduce home
   directory clutter but requires `$XDG_CONFIG_HOME` to be set before sourcing.

2. **Should a reference implementation be published as a standalone package**
   (e.g., an Entware/Homebrew formula that installs a minimal `.commonrc`
   and patches each shell's RC file)?

3. **Should dotfile managers** (chezmoi, yadm, GNU Stow) add native support
   for `.commonrc` as a recognised file?

4. **fish compatibility:** fish does not source POSIX sh files. A
   `~/.config/fish/conf.d/commonrc.fish` shim could translate key exports,
   but the mechanism would differ fundamentally.

---

## 7. References

- IEEE Std 1003.1-2024 (POSIX) — Shell Command Language:
  https://pubs.opengroup.org/onlinepubs/9799919799/utilities/V3_chap02.html
- Single UNIX Specification V5 (2024):
  https://www.unix.org/overview.html
- Michael Currin, *"Dotfiles — Shared Config for ZSH and Bash"*, dev.to, 2020:
  https://dev.to/michaelcurrin/dotfiles-shared-config-for-zsh-and-bash-4ff9
- Dan Cross, *"Dotfiles: Stop the Madness"*, 2012:
  https://pub.gajendra.net/2012/09/dotfiles
- Arch Linux Wiki — Dotfiles:
  https://wiki.archlinux.org/title/Dotfiles
- XDG Base Directory Specification, freedesktop.org:
  https://specifications.freedesktop.org/basedir-spec/latest/
- Entware — Alternative package manager for embedded systems:
  https://github.com/Entware/Entware
- KonradLanz/qnap-dotfiles (reference implementation):
  https://github.com/KonradLanz/qnap-dotfiles
