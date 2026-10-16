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
| `ga`    | `git add`                                    |
| `gaa`   | `git add --all`                              |
| `gc`    | `git commit`                                 |
| `gcm`   | `git commit -m` (e.g. `gcm "fix typo"`)      |
| `gp`    | `git push`                                   |
| `gl`    | `git pull`                                   |
| `glog`  | `git log --oneline --graph --decorate -20`   |
| `ll`    | `ls -lAh`                                    |
| `..`    | `cd ..`                                      |
| `c`     | `clear`                                      |
| `myip`  | `curl -s ifconfig.me`                        |

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
