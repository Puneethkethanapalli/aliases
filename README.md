# Aliases

A single-command bootstrap for shell aliases that works across distro-hops.

Supports **bash**, **zsh**, and **fish** on Arch, Debian/Ubuntu, Fedora, openSUSE, Alpine, and Void
(package aliases use the same names everywhere — see below).

## Quick Start

One-liner (fresh machine, works in any shell including fish):
```sh
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Puneethkethanapalli/aliases/main/setup.sh)"
```

Or clone manually:
```bash
git clone https://github.com/Puneethkethanapalli/aliases.git ~/aliases
bash ~/aliases/setup.sh
```

Choose `1) Install` and you're done.

## Usage

```bash
bash setup.sh              # interactive menu
bash setup.sh install      # set up aliases for all detected shells
bash setup.sh update       # pull latest + configure any new shells
bash setup.sh uninstall    # remove everything cleanly
bash setup.sh status       # show what's configured
bash setup.sh install -y   # answer yes to every prompt (no terminal needed)
```

## Update After Editing on GitHub

```bash
cd ~/aliases && bash setup.sh update
```

This pulls the latest changes and reconfigures any newly installed shells.

## What Gets Installed

| Alias   | Command                                      |
|---------|----------------------------------------------|
| `nd`    | `npm run dev`                                |
| `ns`    | `npm start`                                  |
| `ni`    | `npm install`                                |
| `nb`    | `npm run build`                              |
| `gs`    | `git status`                                 |
| `gad`   | `git add`                                    |
| `gaa`   | `git add --all`                              |
| `gc`    | `git commit`                                 |
| `gcm`   | `git commit -m` (e.g. `gcm "fix typo"`)      |
| `gp`    | `git push`                                   |
| `gl`    | `git pull`                                   |
| `gdf`   | `git diff`                                   |
| `glog`  | `git log --oneline --graph --decorate -20`   |
| `ll`    | `ls -lAh`                                    |
| `..`    | `cd ..`                                      |
| `cls`   | `clear`                                      |
| `hist`  | `history`                                    |
| `myip`  | `curl -s ifconfig.me`                        |

Names are picked so they don't override Omarchy's own (`c`, `ga`, `gd`, `h`), and an `ls` that's
already set up (like Omarchy's eza one) is left alone.

### Packages — same names on every distro

| Alias | Does           | Arch            | Debian/Ubuntu                 | Fedora        | openSUSE                   | Alpine                     | Void              |
|-------|----------------|-----------------|-------------------------------|---------------|----------------------------|----------------------------|-------------------|
| `pu`  | update system  | `pacman -Syu`   | `apt update && apt upgrade`   | `dnf upgrade` | `zypper dup` (TW) / `update` | `apk update && apk upgrade` | `xbps-install -Su` |
| `pi`  | install        | `pacman -S`     | `apt install`                 | `dnf install` | `zypper install`           | `apk add`                  | `xbps-install -S` |
| `pr`  | remove         | `pacman -Rns`   | `apt remove`                  | `dnf remove`  | `zypper remove --clean-deps` | `apk del`                | `xbps-remove -R`  |
| `pss` | search         | `pacman -Ss`    | `apt search`                  | `dnf search`  | `zypper search`            | `apk search`               | `xbps-query -Rs`  |

Commands that need root use `sudo`, or `doas` where sudo isn't installed. On Arch with `yay`,
the `y*` aliases (`yi`, `yu`, `ys`, …) are added too.

### Only defined when the tool is installed

`ufw*` (UFW firewall), `bp` (btop), and `sd` (skipped if the `sd` find-and-replace tool is installed,
so it isn't shadowed).

### Power

`rs` (reboot), `po` (power off), `sd` (shut down) and `halt` ask for confirmation before acting.

See [`aliases.sh`](aliases.sh) for the full list.

## Omarchy

Omarchy ships with bash only. On Omarchy, `setup.sh install` (and `update`):

- If fish isn't installed, asks whether to install it with `omarchy pkg add omarchy-fish`
  (fish plus Omarchy's fish config). Yes installs it, sets up the aliases for fish and makes fish
  your default shell.
- If fish is installed but isn't your default yet, asks whether to make it the default.

"Default" works the way Omarchy's own `omarchy-setup-fish` does it: your login shell stays bash,
and a short marked block in `~/.bashrc` hands interactive terminals over to fish. Everything your
`~/.bashrc` exports is still set up, and running `bash` from fish still gives you bash. Unlike
`omarchy-setup-fish`, it doesn't replace your `~/.bashrc`. `setup.sh uninstall` asks whether to
remove the block and go back to bash.

## How It Works

- `setup.sh install` adds a single source line to your shell's rc file (`.bashrc`, `.zshrc` — respecting
  `ZDOTDIR` — or fish `conf.d`)
- Aliases are loaded directly from the cloned repo — no copies, no symlinks for bash/zsh
- After `git pull`, open a new shell (or `source ~/.bashrc`) to pick up changes — no reinstall needed
- `setup.sh update` is for when you've installed a new shell or moved the repo
- If you already have your own `~/.config/fish/conf.d/aliases.fish`, install asks before moving it aside

## Uninstall

```bash
bash ~/aliases/setup.sh uninstall
```

Cleanly removes all source lines and fish symlinks (symlinked rc files stay symlinks). Does not delete
the repo itself.
