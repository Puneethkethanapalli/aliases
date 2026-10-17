# ──────────────────────────────────────────────
#  Fish Shell Aliases — github.com/Puneethkethanapalli/aliases
# ──────────────────────────────────────────────
# Symlinked to ~/.config/fish/conf.d/aliases.fish via setup.sh
# Abbreviations use -g so fish < 3.6 doesn't save them as universal
# variables (which would outlive an uninstall).

# Privilege prefix: doas where sudo isn't installed (e.g. Alpine), else sudo
set -l sudo sudo
if not command -q sudo; and command -q doas
    set sudo doas
end

# ── Node / NPM ───────────────────────────────
abbr -a -g nd 'npm run dev'
abbr -a -g ns 'npm start'
abbr -a -g ni 'npm install'
abbr -a -g nb 'npm run build'
abbr -a -g nt 'npm test'
abbr -a -g nci 'npm ci'

# ── Git ───────────────────────────────────────
# (gad/gdf rather than ga/gd: Omarchy uses those for git worktree add/remove)
abbr -a -g gs 'git status'
abbr -a -g gad 'git add'
abbr -a -g gaa 'git add --all'
abbr -a -g gc 'git commit'
abbr -a -g gcm 'git commit -m'
abbr -a -g gp 'git push'
abbr -a -g gl 'git pull'
abbr -a -g gdf 'git diff'
abbr -a -g glog 'git log --oneline --graph --decorate -20'
abbr -a -g gb 'git branch'
abbr -a -g gco 'git checkout'
abbr -a -g gsw 'git switch'
abbr -a -g gst 'git stash'

# ── Packages (same names on every distro) ─────
#   pu = update system   pi = install   pr = remove   pss = search
if command -q pacman
    abbr -a -g pu "$sudo pacman -Syu"
    abbr -a -g pi "$sudo pacman -S"
    abbr -a -g pr "$sudo pacman -Rns"
    abbr -a -g pss 'pacman -Ss'

    # yay (AUR helper) — additive only, does not override pacman aliases
    if command -q yay
        abbr -a -g yi 'yay -S'
        abbr -a -g yr 'yay -Rns'
        abbr -a -g ys 'yay -Ss'
        abbr -a -g yu 'yay -Syu'
        abbr -a -g pyu 'yay -Syu'
        abbr -a -g yc 'yay -Sc'
        abbr -a -g ycc 'yay -Scc'
        abbr -a -g ylo 'yay -Qdt'
        abbr -a -g ylu 'yay -Qu'
    end
else if command -q apt
    abbr -a -g pu "$sudo apt update && $sudo apt upgrade"
    abbr -a -g pi "$sudo apt install"
    abbr -a -g pr "$sudo apt remove"
    abbr -a -g pss 'apt search'
else if command -q dnf
    abbr -a -g pu "$sudo dnf upgrade"
    abbr -a -g pi "$sudo dnf install"
    abbr -a -g pr "$sudo dnf remove"
    abbr -a -g pss 'dnf search'
else if command -q zypper
    # Tumbleweed is rolling and must use `dup`; Leap uses `update`
    if grep -qs tumbleweed /etc/os-release
        abbr -a -g pu "$sudo zypper dup"
    else
        abbr -a -g pu "$sudo zypper update"
    end
    abbr -a -g pi "$sudo zypper install"
    abbr -a -g pr "$sudo zypper remove --clean-deps"
    abbr -a -g pss 'zypper search'
else if command -q apk
    abbr -a -g pu "$sudo apk update && $sudo apk upgrade"
    abbr -a -g pi "$sudo apk add"
    abbr -a -g pr "$sudo apk del"
    abbr -a -g pss 'apk search'
else if command -q xbps-install
    abbr -a -g pu "$sudo xbps-install -Su"
    abbr -a -g pi "$sudo xbps-install -S"
    abbr -a -g pr "$sudo xbps-remove -R"
    abbr -a -g pss 'xbps-query -Rs'
end

# ── Navigation ────────────────────────────────
abbr -a -g .. 'cd ..'
abbr -a -g ... 'cd ../..'
abbr -a -g .... 'cd ../../..'
# `command` skips any `ls` wrapper function (e.g. Omarchy's eza one) to match bash
alias ll='command ls -lAh --color=auto'
alias la='command ls -A --color=auto'

# ── Power / System ────────────────────────────
function rs -V sudo --description 'Reboot'
    $sudo reboot
end

function po -V sudo --description 'Power off'
    $sudo poweroff
end

function _confirm_power
    read -l -P "$argv[1] now? [y/N] " reply
    string match -qi 'y*' -- $reply
end

function halt -V sudo --description 'Halt (asks first)'
    _confirm_power Halt; and $sudo halt
end

# Skip if the `sd` find-and-replace tool is installed, so we don't shadow it
if not command -q sd
    function sd -V sudo --description 'Shut down'
        $sudo shutdown -h now
    end
end

# ── Firewall (UFW) ────────────────────────────
if command -q ufw
    abbr -a -g ufwe "$sudo ufw enable"
    abbr -a -g ufwd "$sudo ufw disable"
    abbr -a -g ufws "$sudo ufw status verbose"
    abbr -a -g ufwa "$sudo ufw allow"
    abbr -a -g ufwden "$sudo ufw deny"
    abbr -a -g ufwr "$sudo ufw reload"
end

# ── Omarchy ───────────────────────────────────
# `o` + group + action; `pu` stays plain pacman, `ou` is the Omarchy way
if command -q omarchy
    abbr -a -g ou 'omarchy update'
    abbr -a -g opi 'omarchy pkg install'
    abbr -a -g opr 'omarchy pkg remove'
    abbr -a -g opa 'omarchy pkg aur install'
    abbr -a -g ots 'omarchy theme set'
    abbr -a -g otl 'omarchy theme list'
    abbr -a -g otc 'omarchy theme current'
    abbr -a -g obg 'omarchy theme bg next'
    abbr -a -g ors 'omarchy restart shell'
    abbr -a -g ort 'omarchy restart terminal'
    abbr -a -g orw 'omarchy restart wifi'
    abbr -a -g orb 'omarchy restart bluetooth'
    abbr -a -g ora 'omarchy restart audio'
    abbr -a -g onl 'omarchy toggle nightlight'
    abbr -a -g oidle 'omarchy toggle idle'
    abbr -a -g olk 'omarchy system lock'
    abbr -a -g okb 'omarchy menu keybindings'
    abbr -a -g orem 'omarchy reminder'
end

# ── Path Management (current session only) ───
function pathadd --description 'Prepend current directory to PATH (this session only)'
    set -gx PATH $PWD $PATH
end

function pathappend --description 'Append current directory to PATH (this session only)'
    set -gx PATH $PATH $PWD
end

# ── Misc ──────────────────────────────────────
# (cls/hist rather than c/h: Omarchy uses those for opencode and herdr)
abbr -a -g cls clear
abbr -a -g hist history
abbr -a -g ports 'ss -tulnp'
abbr -a -g myip 'curl -s ifconfig.me'
if command -q btop
    abbr -a -g bp 'btop --force-utf'
end

function mkcd
    # builtin cd: skip cd wrappers like Omarchy's zoxide one, which mishandle `--`
    mkdir -p -- $argv[1]; and builtin cd -- $argv[1]
end
