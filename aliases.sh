# ──────────────────────────────────────────────
#  Shell Aliases — github.com/Puneethkethanapalli/aliases
# ──────────────────────────────────────────────
# Sourced by ~/.bashrc and ~/.zshrc via setup.sh
# Safe to re-source (e.g. `source ~/.bashrc`) to pick up changes.

# Skip in non-interactive shells (scripts, CI, etc.)
case $- in *i*) ;; *) return ;; esac

# Privilege prefix: doas where sudo isn't installed (e.g. Alpine), else sudo
if ! command -v sudo > /dev/null 2>&1 && command -v doas > /dev/null 2>&1; then
    _sudo='doas'
else
    _sudo='sudo'
fi

# ── Node / NPM ───────────────────────────────
alias nd='npm run dev'
alias ns='npm start'
alias ni='npm install'
alias nb='npm run build'
alias nt='npm test'
alias nci='npm ci'

# ── Git ───────────────────────────────────────
# (gad/gdf rather than ga/gd: Omarchy uses those for git worktree add/remove)
alias gs='git status'
alias gad='git add'
alias gaa='git add --all'
alias gc='git commit'
alias gcm='git commit -m'
alias gp='git push'
alias gl='git pull'
alias gdf='git diff'
alias glog='git log --oneline --graph --decorate -20'
alias gb='git branch'
alias gco='git checkout'
alias gsw='git switch'
alias gst='git stash'

# ── Packages (same names on every distro) ─────
#   pu = update system   pi = install   pr = remove   pss = search
if command -v pacman > /dev/null 2>&1; then
    alias pu="$_sudo pacman -Syu"
    alias pi="$_sudo pacman -S"
    alias pr="$_sudo pacman -Rns"
    alias pss='pacman -Ss'

    # yay (AUR helper) — additive only, does not override pacman aliases
    if command -v yay > /dev/null 2>&1; then
        alias yi='yay -S'                 # install from AUR
        alias yr='yay -Rns'               # remove
        alias ys='yay -Ss'                # search AUR + official
        alias yu='yay -Syu'               # update official + AUR
        alias pyu='yay -Syu'              # same as yu (yay already runs pacman -Syu first)
        alias yc='yay -Sc'                # clean build cache
        alias ycc='yay -Scc'              # clean all cache
        alias ylo='yay -Qdt'              # list orphaned packages
        alias ylu='yay -Qu'               # list upgradable packages
    fi
elif command -v apt > /dev/null 2>&1; then
    alias pu="$_sudo apt update && $_sudo apt upgrade"
    alias pi="$_sudo apt install"
    alias pr="$_sudo apt remove"
    alias pss='apt search'
elif command -v dnf > /dev/null 2>&1; then
    alias pu="$_sudo dnf upgrade"
    alias pi="$_sudo dnf install"
    alias pr="$_sudo dnf remove"
    alias pss='dnf search'
elif command -v zypper > /dev/null 2>&1; then
    # Tumbleweed is rolling and must use `dup`; Leap uses `update`
    if grep -qs tumbleweed /etc/os-release; then
        alias pu="$_sudo zypper dup"
    else
        alias pu="$_sudo zypper update"
    fi
    alias pi="$_sudo zypper install"
    alias pr="$_sudo zypper remove --clean-deps"
    alias pss='zypper search'
elif command -v apk > /dev/null 2>&1; then
    alias pu="$_sudo apk update && $_sudo apk upgrade"
    alias pi="$_sudo apk add"
    alias pr="$_sudo apk del"
    alias pss='apk search'
elif command -v xbps-install > /dev/null 2>&1; then
    alias pu="$_sudo xbps-install -Su"
    alias pi="$_sudo xbps-install -S"
    alias pr="$_sudo xbps-remove -R"
    alias pss='xbps-query -Rs'
fi

# ── Navigation ────────────────────────────────
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
# Keep an `ls` someone already set up (e.g. Omarchy's eza one); ll/la always
# use the real ls via `command`, so they behave the same everywhere
alias ls > /dev/null 2>&1 || alias ls='ls --color=auto'
alias ll='command ls -lAh --color=auto'
alias la='command ls -A --color=auto'
alias grep='grep --color=auto'

# ── Power / System (each asks before acting) ──
_confirm_power() {
    local reply
    printf '%s now? [y/N] ' "$1"
    read -r reply
    case "$reply" in [yY]*) return 0 ;; *) return 1 ;; esac
}
alias rs="_confirm_power Reboot && $_sudo reboot"
alias po="_confirm_power 'Power off' && $_sudo poweroff"
alias halt="_confirm_power Halt && $_sudo halt"
# Skip if the `sd` find-and-replace tool is installed, so we don't shadow it
if ! command -v sd > /dev/null 2>&1; then
    alias sd="_confirm_power 'Shut down' && $_sudo shutdown -h now"
fi

# ── Firewall (UFW) ────────────────────────────
if command -v ufw > /dev/null 2>&1; then
    alias ufwe="$_sudo ufw enable"
    alias ufwd="$_sudo ufw disable"
    alias ufws="$_sudo ufw status verbose"
    alias ufwa="$_sudo ufw allow"
    alias ufwden="$_sudo ufw deny"
    alias ufwr="$_sudo ufw reload"
fi

# ── Path Management (current session only) ───
alias pathadd='export PATH="$(pwd):$PATH"'
alias pathappend='export PATH="$PATH:$(pwd)"'

# ── Misc ──────────────────────────────────────
# (cls/hist rather than c/h: Omarchy uses those for opencode and herdr)
alias cls='clear'
alias hist='history'
alias ports='ss -tulnp'
alias myip='curl -s ifconfig.me'
if command -v btop > /dev/null 2>&1; then
    alias bp='btop --force-utf'
fi
# builtin cd: skip cd wrappers like Omarchy's zoxide one, which mishandle `--`
mkcd() { mkdir -p -- "$1" && builtin cd -- "$1"; }

unset _sudo
