# Aliases

A single-command bootstrap for shell aliases that works across distro-hops.

Supports **bash**, **zsh**, and **fish**.

## Quick Start

One-liner (fresh machine, works in any shell including fish):
```sh
bash -c "$(curl -sL https://raw.githubusercontent.com/Puneethkethanapalli/aliases/main/setup.sh)"
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
```

## Update After Editing on GitHub

```bash
cd ~/aliases && bash setup.sh update
```

This pulls the latest changes and reconfigures any newly installed shells.

## What Gets Installed

| Alias   | Command                               |
|---------|---------------------------------------|
| `nd`    | `npm run dev`                         |
| `ns`    | `npm start`                           |
| `ni`    | `npm install`                         |
| `nb`    | `npm run build`                       |
| `gs`    | `git status`                          |
| `ga`    | `git add`                             |
| `gc`    | `git commit`                          |
| `gp`    | `git push`                            |
| `gl`    | `git pull`                            |
| `glog`  | `git log --oneline --graph`           |
| `ll`    | `ls -lAh`                             |
| `..`    | `cd ..`                               |
| `c`     | `clear`                               |
| `update`| `sudo pacman -Syu` (or apt/dnf)      |
| `myip`  | `curl -s ifconfig.me`                 |

See [`aliases.sh`](aliases.sh) for the full list.

## How It Works

- `setup.sh install` adds a single source line to your shell's rc file (`.bashrc`, `.zshrc`, or fish `conf.d`)
- Aliases are loaded directly from the cloned repo — no copies, no symlinks for bash/zsh
- `git pull` updates aliases instantly (no reinstall needed for content changes)
- `setup.sh update` is for when you've installed a new shell or moved the repo

## Uninstall

```bash
bash ~/aliases/setup.sh uninstall
```

Cleanly removes all source lines and fish symlinks. Does not delete the repo itself.
