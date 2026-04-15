# ──────────────────────────────────────────────
#  Fish Shell Aliases — github.com/Puneethkethanapalli/aliases
# ──────────────────────────────────────────────
# Symlinked to ~/.config/fish/conf.d/aliases.fish via setup.sh

# Prevent double-loading
if set -q _ALIASES_LOADED
    exit
end
set -g _ALIASES_LOADED 1

# ── Node / NPM ───────────────────────────────
abbr -a nd 'npm run dev'
abbr -a ns 'npm start'
abbr -a ni 'npm install'
abbr -a nb 'npm run build'
abbr -a nt 'npm test'
abbr -a nci 'npm ci'

# ── Git ───────────────────────────────────────
abbr -a gs 'git status'
abbr -a ga 'git add .'
abbr -a gaa 'git add --all'
abbr -a gc 'git commit -m ""'
abbr -a gp 'git push'
abbr -a gl 'git pull'
abbr -a gd 'git diff'
abbr -a glog 'git log --oneline --graph --decorate -20'
abbr -a gb 'git branch'
abbr -a gco 'git checkout'
abbr -a gsw 'git switch'
abbr -a gst 'git stash'

# ── System (OS-detected) ─────────────────────
if command -q pacman
    abbr -a pu 'sudo pacman -Syu'
    abbr -a ps 'sudo pacman -S'
    abbr -a pr 'sudo pacman -Rns'
    abbr -a ps 'pacman -Ss'

    # yay (AUR helper) — additive only, does not override pacman aliases
    if command -q yay
        abbr -a yi 'yay -S'
        abbr -a yr 'yay -Rns'
        abbr -a ys 'yay -Ss'
        abbr -a yu 'yay -Syu'
        abbr -a yc 'yay -Sc'
        abbr -a ycc 'yay -Scc'
        abbr -a ylo 'yay -Qdt'
        abbr -a ylu 'yay -Qu'
    end
else if command -q apt
    abbr -a update 'sudo apt update && sudo apt upgrade'
    abbr -a install 'sudo apt install'
    abbr -a remove 'sudo apt remove'
    abbr -a search 'apt search'
else if command -q dnf
    abbr -a update 'sudo dnf upgrade'
    abbr -a install 'sudo dnf install'
    abbr -a remove 'sudo dnf remove'
    abbr -a search 'dnf search'
end

# ── Navigation ────────────────────────────────
abbr -a .. 'cd ..'
abbr -a ... 'cd ../..'
abbr -a .... 'cd ../../..'
alias ll='ls -lAh --color=auto'
alias la='ls -A --color=auto'

# ── Misc ──────────────────────────────────────
abbr -a c clear
abbr -a h history
abbr -a ports 'ss -tulnp'
abbr -a myip 'curl -s ifconfig.me'

function mkcd
    mkdir -p $argv[1]; and cd $argv[1]
end
