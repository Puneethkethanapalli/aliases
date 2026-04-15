# ──────────────────────────────────────────────
#  Shell Aliases — github.com/Puneethkethanapalli/aliases
# ──────────────────────────────────────────────
# Sourced by ~/.bashrc and ~/.zshrc via setup.sh

# Skip in non-interactive shells (scripts, CI, etc.)
case $- in *i*) ;; *) return ;; esac

# Prevent double-loading in the same session
[ -n "$_ALIASES_LOADED" ] && return
_ALIASES_LOADED=1

# ── Node / NPM ───────────────────────────────
alias nd='npm run dev'
alias ns='npm start'
alias ni='npm install'
alias nb='npm run build'
alias nt='npm test'
alias nci='npm ci'

# ── Git ───────────────────────────────────────
alias gs='git status'
alias ga='git add .'
alias gaa='git add --all'
alias gc='git commit -m ""'
alias gp='git push'
alias gl='git pull'
alias gd='git diff'
alias glog='git log --oneline --graph --decorate -20'
alias gb='git branch'
alias gco='git checkout'
alias gsw='git switch'
alias gst='git stash'

# ── System (OS-detected) ─────────────────────
if command -v pacman > /dev/null 2>&1; then
    alias pu='sudo pacman -Syu'
    alias ps='sudo pacman -S'
    alias pr='sudo pacman -Rns'
    alias ps='pacman -Ss'

    # yay (AUR helper) — additive only, does not override pacman aliases
    if command -v yay > /dev/null 2>&1; then
        alias yi='yay -S'                 # install from AUR
        alias yr='yay -Rns'               # remove
        alias ys='yay -Ss'                # search AUR + official
        alias yu='yay -Syu'               # update official + AUR
        alias yc='yay -Sc'                # clean build cache
        alias ycc='yay -Scc'              # clean all cache
        alias ylo='yay -Qdt'              # list orphaned packages
        alias ylu='yay -Qu'               # list upgradable packages
    fi
elif command -v apt > /dev/null 2>&1; then
    alias update='sudo apt update && sudo apt upgrade'
    alias install='sudo apt install'
    alias remove='sudo apt remove'
    alias search='apt search'
elif command -v dnf > /dev/null 2>&1; then
    alias update='sudo dnf upgrade'
    alias install='sudo dnf install'
    alias remove='sudo dnf remove'
    alias search='dnf search'
fi

# ── Navigation ────────────────────────────────
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ls='ls --color=auto'
alias ll='ls -lAh --color=auto'
alias la='ls -A --color=auto'
alias grep='grep --color=auto'

# ── Misc ──────────────────────────────────────
alias c='clear'
alias h='history'
alias ports='ss -tulnp'
alias myip='curl -s ifconfig.me'
mkcd() { mkdir -p "$1" && cd "$1"; }
