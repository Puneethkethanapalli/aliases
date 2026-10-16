#!/usr/bin/env bash
# ──────────────────────────────────────────────
#  setup.sh — Interactive aliases bootstrap
#  github.com/Puneethkethanapalli/aliases
# ──────────────────────────────────────────────
set -euo pipefail

# ── Bootstrap from curl | bash ────────────────
# If running via curl (no repo nearby), clone first and re-exec
REPO_URL="https://github.com/Puneethkethanapalli/aliases.git"
CLONE_DIR="$HOME/aliases"

# Checked at top level on purpose: under `bash -c "$(curl ...)"` or `curl | bash`
# BASH_SOURCE is empty here, but inside a function it reads back as $0 ("bash"),
# whose dirname "." would make us adopt whatever directory the user is in.
SCRIPT_DIR=""
if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)" || SCRIPT_DIR=""
fi

if [ -z "$SCRIPT_DIR" ] || [ ! -f "$SCRIPT_DIR/aliases.sh" ]; then
    echo ""
    echo -e "  \033[0;36m·\033[0m Running from remote — cloning repo first..."
    echo ""
    if [ -d "$CLONE_DIR/.git" ]; then
        echo -e "  \033[0;36m·\033[0m Repo already exists at $CLONE_DIR, pulling latest..."
        git -C "$CLONE_DIR" pull --ff-only
    else
        git clone "$REPO_URL" "$CLONE_DIR"
    fi
    exec bash "$CLONE_DIR/setup.sh" "$@"
fi

# ── Constants ─────────────────────────────────
ALIASES_SH="$SCRIPT_DIR/aliases.sh"
ALIASES_FISH="$SCRIPT_DIR/aliases.fish"
FISH_CONF_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/fish/conf.d"
FISH_TARGET="$FISH_CONF_DIR/aliases.fish"
SOURCE_TAG="# aliases-bootstrap"
# Appears in the header of this repo's alias files; used to recognise old installs
REPO_MARKER="github.com/Puneethkethanapalli/aliases"
# Set by -y/--yes: answer yes to every prompt
ASSUME_YES=false

# The source line we inject into bash/zsh rc files
source_line() {
    echo "[ -f \"$ALIASES_SH\" ] && . \"$ALIASES_SH\" $SOURCE_TAG"
}

# ── Colors ────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

log_ok()   { echo -e "  ${GREEN}✓${RESET} $1"; }
log_info() { echo -e "  ${CYAN}·${RESET} $1"; }
log_warn() { echo -e "  ${YELLOW}!${RESET} $1"; }
log_err()  { echo -e "  ${RED}✗${RESET} $1"; }

# ── Shell Detection ───────────────────────────
# Populates parallel arrays: SHELLS[], RC_FILES[]
declare -a SHELLS=()
declare -a RC_FILES=()

# zsh reads $ZDOTDIR/.zshrc, and ZDOTDIR is usually set in ~/.zshenv —
# so ask zsh itself rather than trusting this script's environment
zsh_rc_file() {
    local zdotdir
    zdotdir="$(zsh -c 'printf "%s\n" "${ZDOTDIR:-$HOME}"' 2>/dev/null | tail -n 1)" || true
    echo "${zdotdir:-$HOME}/.zshrc"
}

detect_shells() {
    SHELLS=()
    RC_FILES=()

    if command -v bash > /dev/null 2>&1; then
        SHELLS+=("bash")
        RC_FILES+=("$HOME/.bashrc")
    fi
    if command -v zsh > /dev/null 2>&1; then
        SHELLS+=("zsh")
        RC_FILES+=("$(zsh_rc_file)")
    fi
    if command -v fish > /dev/null 2>&1; then
        SHELLS+=("fish")
        RC_FILES+=("$FISH_TARGET")
    fi
}

# ── Helpers ───────────────────────────────────

is_configured() {
    local shell="$1"
    case "$shell" in
        bash|zsh)
            local idx
            for idx in "${!SHELLS[@]}"; do
                if [ "${SHELLS[$idx]}" = "$shell" ]; then
                    grep -qF "$SOURCE_TAG" "${RC_FILES[$idx]}" 2>/dev/null && return 0
                    return 1
                fi
            done
            return 1
            ;;
        fish)
            [ -L "$FISH_TARGET" ] &&
                [ "$(readlink -f "$FISH_TARGET" 2>/dev/null)" = "$(readlink -f "$ALIASES_FISH" 2>/dev/null)" ] &&
                return 0
            return 1
            ;;
    esac
    return 1
}

# Only checks names defined on every distro — package aliases like `pi`
# don't exist when no supported package manager is found
verify_shell() {
    local shell="$1"

    case "$shell" in
        bash)
            bash --noprofile --rcfile "$HOME/.bashrc" -ic \
                'alias nd >/dev/null && declare -F mkcd >/dev/null' \
                >/dev/null 2>&1
            ;;
        zsh)
            zsh -ic \
                'alias nd >/dev/null && whence -w mkcd >/dev/null' \
                >/dev/null 2>&1
            ;;
        fish)
            fish -ic \
                'abbr --query nd; and functions --query mkcd' \
                >/dev/null 2>&1
            ;;
        *)
            return 1
            ;;
    esac
}

verify_shells() {
    local failed=0
    local shell

    echo ""
    log_info "Verifying shell startup..."
    for shell in "$@"; do
        if verify_shell "$shell"; then
            log_ok "$shell — aliases load correctly"
        else
            log_err "$shell — configuration exists but aliases failed to load"
            failed=1
        fi
    done

    return "$failed"
}

get_rc_file() {
    local shell="$1"
    local idx
    for idx in "${!SHELLS[@]}"; do
        if [ "${SHELLS[$idx]}" = "$shell" ]; then
            echo "${RC_FILES[$idx]}"
            return
        fi
    done
}

add_source_line() {
    local shell="$1"
    local rc
    rc="$(get_rc_file "$shell")"

    case "$shell" in
        bash|zsh)
            # Create rc file if it doesn't exist (common for zsh on fresh installs)
            if [ ! -f "$rc" ]; then
                mkdir -p "$(dirname "$rc")"
                touch "$rc"
                log_info "Created $rc"
            fi
            if grep -qF "$SOURCE_TAG" "$rc" 2>/dev/null; then
                log_info "$shell — already configured"
                return
            fi
            echo "" >> "$rc"
            source_line >> "$rc"
            log_ok "$shell — added source line to $rc"
            ;;
        fish)
            if is_configured fish; then
                log_info "fish — already configured"
                return
            fi
            mkdir -p "$FISH_CONF_DIR"
            if [ -e "$FISH_TARGET" ] || [ -L "$FISH_TARGET" ]; then
                if [ ! -e "$FISH_TARGET" ] || grep -qF "$REPO_MARKER" "$FISH_TARGET" 2>/dev/null; then
                    # Broken link, or a link/copy from an older install of this repo
                    log_info "fish — replacing old install at $FISH_TARGET"
                else
                    # Someone else's file with the same name — never overwrite it silently
                    local backup
                    backup="$FISH_TARGET.bak.$(date +%Y%m%d-%H%M%S)"
                    log_warn "fish — $FISH_TARGET already exists and isn't from this repo"
                    if ! confirm "Move it to $(basename "$backup") (fish won't load it there) and continue?" "n"; then
                        log_info "Skipped fish — existing file left untouched"
                        return
                    fi
                    mv "$FISH_TARGET" "$backup"
                    log_ok "fish — moved existing file to $backup"
                fi
            fi
            ln -sf "$ALIASES_FISH" "$FISH_TARGET"
            log_ok "fish — symlinked to $FISH_TARGET"
            ;;
    esac
}

remove_source_line() {
    local shell="$1"

    case "$shell" in
        bash|zsh)
            local rc tmp
            rc="$(get_rc_file "$shell")"
            if [ -f "$rc" ] && grep -qF "$SOURCE_TAG" "$rc" 2>/dev/null; then
                # Drop our line and the blank line install put above it. Write the
                # result back through the file (not sed -i), so a symlinked rc
                # managed by stow/chezmoi etc. stays a symlink.
                tmp="$(mktemp)"
                awk -v tag="$SOURCE_TAG" '
                    index($0, tag) { blank = 0; next }
                    blank          { print ""; blank = 0 }
                    /^$/           { blank = 1; next }
                                   { print }
                    END            { if (blank) print "" }
                ' "$rc" > "$tmp"
                cat "$tmp" > "$rc"
                rm -f "$tmp"
                log_ok "$shell — removed source line from $rc"
            else
                log_info "$shell — not configured, nothing to remove"
            fi
            ;;
        fish)
            # Only remove our own symlink, never a file that just shares the name
            if is_configured fish; then
                rm -f "$FISH_TARGET"
                log_ok "fish — removed $FISH_TARGET"
            else
                log_info "fish — not configured, nothing to remove"
            fi
            ;;
    esac
}

confirm() {
    local prompt="$1"
    local default="${2:-y}"
    local yn

    if [ "$default" = "y" ]; then
        printf "  %s [Y/n]: " "$prompt"
    else
        printf "  %s [y/N]: " "$prompt"
    fi

    if $ASSUME_YES; then
        echo "y (--yes)"
        return 0
    fi
    if ! { read -r yn < /dev/tty; } 2>/dev/null; then
        yn="$default"
        echo "$default (no terminal — using default; pass --yes to accept all)"
    fi
    yn="${yn:-$default}"
    case "$yn" in
        [Yy]*) return 0 ;;
        *) return 1 ;;
    esac
}

# ── Alias Summary ────────────────────────────

_parse_aliases_sh() {
    # Source in a clean interactive bash to get only what's active on this machine.
    # bash is used for zsh too: same file, and zsh has no --norc or declare -F.
    local combined
    combined="$(bash --norc --noprofile -i -c ". '$ALIASES_SH'; alias; declare -F" 2>/dev/null)"

    # Aliases (sorted). bash prints embedded quotes as '\'' — turn them back into '
    local q="'\\''"
    while IFS='=' read -r name value; do
        value="${value#\'}"
        value="${value%\'}"
        value="${value//"$q"/\'}"
        printf "    ${CYAN}%-16s${RESET} %s\n" "$name" "$value"
    done < <(echo "$combined" | sed -n "s/^alias //p" | sort)

    # User-defined functions — skip internal ones (prefixed with _)
    while IFS= read -r fname; do
        printf "    ${CYAN}%-16s${RESET} (function)\n" "$fname"
    done < <(echo "$combined" | awk '/^declare -f [^_]/{print $3}' | sort)
}

_parse_aliases_fish() {
    # Let fish evaluate the file, so distro/tool conditions resolve exactly as they
    # will at startup. An empty config dir keeps the user's own abbreviations out.
    local cfg out line name value
    local -a fn_names=()

    # Function names (incl. `alias`, which defines a function); `_` ones are internal
    while IFS= read -r name; do
        fn_names+=("$name")
    done < <(sed -nE 's/^[[:space:]]*(function[[:space:]]+([A-Za-z][A-Za-z0-9_-]*)|alias[[:space:]]+([A-Za-z][A-Za-z0-9_-]*)=).*/\2\3/p' "$ALIASES_FISH")

    cfg="$(mktemp -d)"
    out="$(XDG_CONFIG_HOME="$cfg" fish -c '
        source $argv[1]
        abbr --show
        for f in $argv[2..-1]
            functions -q $f; and echo "function $f"
        end
    ' "$ALIASES_FISH" "${fn_names[@]}" 2>/dev/null)" || true
    rm -rf "$cfg"

    # `abbr --show` prints e.g.:  abbr -a -- gs 'git status'
    while IFS= read -r line; do
        [[ "$line" =~ ^abbr\ (-[^\ ]+\ )*--\ ([^\ ]+)\ (.*)$ ]] || continue
        name="${BASH_REMATCH[2]}"
        value="${BASH_REMATCH[3]}"
        if [[ "$value" == \'*\' ]]; then
            value="${value:1:${#value}-2}"
            value="${value//\\\'/\'}"
        fi
        printf "    ${CYAN}%-16s${RESET} %s\n" "$name" "$value"
    done < <(echo "$out" | grep '^abbr ' | sort)

    while IFS= read -r name; do
        printf "    ${CYAN}%-16s${RESET} (function)\n" "$name"
    done < <(echo "$out" | sed -n 's/^function //p' | sort)
}

show_aliases_summary() {
    local -a shells_to_show=("$@")
    local show_fish=false
    local -a sh_shells=()
    local s

    for s in "${shells_to_show[@]}"; do
        case "$s" in
            bash|zsh) sh_shells+=("$s") ;;
            fish)     show_fish=true ;;
        esac
    done

    echo ""
    echo -e "  ${DIM}──────────────────────────────${RESET}"

    # bash and zsh share the same aliases.sh — deduplicate if both configured
    if [ ${#sh_shells[@]} -gt 0 ]; then
        local label
        label="$(printf '%s, ' "${sh_shells[@]}")"
        label="${label%, }"
        echo ""
        echo -e "  ${BOLD}Aliases available in $label:${RESET}"
        echo ""
        _parse_aliases_sh
    fi

    if $show_fish; then
        echo ""
        echo -e "  ${BOLD}Aliases available in fish:${RESET}"
        echo ""
        _parse_aliases_fish
    fi

    echo ""
    echo -e "  ${DIM}(Conditional aliases like yay activate only when the tool is installed)${RESET}"
    echo ""
}

# ── Modes ─────────────────────────────────────

do_install() {
    echo ""
    echo -e "  ${BOLD}Install Aliases${RESET}"
    echo -e "  ${DIM}──────────────────────────────${RESET}"
    echo ""

    # Validate
    if [ ! -f "$ALIASES_SH" ]; then
        log_err "aliases.sh not found in $SCRIPT_DIR"
        log_err "Did you clone the repo correctly?"
        exit 1
    fi

    detect_shells

    if [ ${#SHELLS[@]} -eq 0 ]; then
        log_err "No supported shells found"
        exit 1
    fi

    # Show detected shells
    echo -e "  ${BOLD}Detected shells:${RESET}"
    for idx in "${!SHELLS[@]}"; do
        local shell="${SHELLS[$idx]}"
        local rc="${RC_FILES[$idx]}"
        if is_configured "$shell"; then
            echo -e "    ${GREEN}[✓]${RESET} $shell  ${DIM}($rc — already configured)${RESET}"
        else
            echo -e "    ${CYAN}[+]${RESET} $shell  ${DIM}($rc)${RESET}"
        fi
    done
    echo ""

    if ! confirm "Proceed with installation?"; then
        echo ""
        log_info "Aborted"
        return
    fi

    echo ""
    for shell in "${SHELLS[@]}"; do
        add_source_line "$shell"
    done

    local now_configured=()
    for shell in "${SHELLS[@]}"; do
        if is_configured "$shell"; then
            now_configured+=("$shell")
        fi
    done
    if [ ${#now_configured[@]} -gt 0 ]; then
        verify_shells "${now_configured[@]}" || {
            log_err "Installation verification failed"
            exit 1
        }
        show_aliases_summary "${now_configured[@]}"
    fi

    log_ok "${BOLD}Done!${RESET} Restart your shell or run: ${CYAN}exec \$SHELL${RESET}"
    echo ""
}

do_update() {
    echo ""
    echo -e "  ${BOLD}Update Aliases${RESET}"
    echo -e "  ${DIM}──────────────────────────────${RESET}"
    echo ""

    # Pull latest changes
    if [ -d "$SCRIPT_DIR/.git" ]; then
        log_info "Pulling latest changes..."
        echo ""
        if git -C "$SCRIPT_DIR" pull --ff-only 2>&1 | sed 's/^/    /'; then
            echo ""
            log_ok "Repository updated"
        else
            echo ""
            log_warn "Pull failed — you may have local changes. Resolve manually."
        fi
    else
        log_warn "Not a git repository — skipping pull"
    fi

    echo ""

    # Re-detect shells (may have installed new ones since last run)
    detect_shells

    local new_shells=()
    local existing_shells=()
    local broken_shells=()

    for shell in "${SHELLS[@]}"; do
        if is_configured "$shell"; then
            existing_shells+=("$shell")
        else
            new_shells+=("$shell")
        fi
    done

    # Check for broken configs (source line present but pointing elsewhere)
    for shell in "${existing_shells[@]}"; do
        case "$shell" in
            bash|zsh)
                local rc
                rc="$(get_rc_file "$shell")"
                if ! grep -qF "$ALIASES_SH" "$rc" 2>/dev/null; then
                    broken_shells+=("$shell")
                fi
                ;;
        esac
    done

    # Fix broken configs
    if [ ${#broken_shells[@]} -gt 0 ]; then
        for shell in "${broken_shells[@]}"; do
            log_warn "$shell — source line points to old location, fixing..."
            remove_source_line "$shell"
            add_source_line "$shell"
        done
        echo ""
    fi

    # Offer to configure new shells
    if [ ${#new_shells[@]} -gt 0 ]; then
        echo -e "  ${BOLD}New shells detected:${RESET}"
        for shell in "${new_shells[@]}"; do
            echo -e "    ${CYAN}[+]${RESET} $shell"
        done
        echo ""

        for shell in "${new_shells[@]}"; do
            if confirm "Configure aliases for $shell?"; then
                add_source_line "$shell"
            else
                log_info "Skipped $shell"
            fi
        done
        echo ""
    fi

    if [ ${#new_shells[@]} -eq 0 ] && [ ${#broken_shells[@]} -eq 0 ]; then
        log_ok "All shells up to date"
    fi

    local now_configured=()
    for shell in "${SHELLS[@]}"; do
        if is_configured "$shell"; then
            now_configured+=("$shell")
        fi
    done
    if [ ${#now_configured[@]} -gt 0 ]; then
        verify_shells "${now_configured[@]}" || {
            log_err "Update verification failed"
            exit 1
        }
        show_aliases_summary "${now_configured[@]}"
    fi

    log_ok "${BOLD}Done!${RESET} Restart your shell or run: ${CYAN}exec \$SHELL${RESET}"
    echo ""
}

do_uninstall() {
    echo ""
    echo -e "  ${BOLD}Uninstall Aliases${RESET}"
    echo -e "  ${DIM}──────────────────────────────${RESET}"
    echo ""

    detect_shells

    local configured=()
    for shell in "${SHELLS[@]}"; do
        if is_configured "$shell"; then
            configured+=("$shell")
        fi
    done

    if [ ${#configured[@]} -eq 0 ]; then
        log_info "Nothing to uninstall — no shells are configured"
        echo ""
        return
    fi

    echo -e "  ${BOLD}Will remove aliases from:${RESET}"
    for shell in "${configured[@]}"; do
        local rc
        rc="$(get_rc_file "$shell")"
        echo -e "    ${RED}[-]${RESET} $shell  ${DIM}($rc)${RESET}"
    done
    echo ""

    if ! confirm "Proceed with uninstall?" "n"; then
        echo ""
        log_info "Aborted"
        return
    fi

    echo ""
    for shell in "${configured[@]}"; do
        remove_source_line "$shell"
    done

    echo ""
    log_ok "${BOLD}Done!${RESET} Restart your shell or run: ${CYAN}exec \$SHELL${RESET}"
    echo ""
}

do_status() {
    echo ""
    echo -e "  ${BOLD}Aliases Status${RESET}"
    echo -e "  ${DIM}──────────────────────────────${RESET}"
    echo ""

    detect_shells

    printf "  ${BOLD}%-10s %-14s %s${RESET}\n" "Shell" "Configured" "RC File"
    printf "  ${DIM}%-10s %-14s %s${RESET}\n" "─────" "──────────" "───────"

    local all_shells=("bash" "zsh" "fish")
    for shell in "${all_shells[@]}"; do
        local installed=false
        local configured=false
        local rc="—"

        if command -v "$shell" > /dev/null 2>&1; then
            installed=true
        fi

        if $installed; then
            rc="$(get_rc_file "$shell")"

            if is_configured "$shell"; then
                configured=true
            fi
        fi

        local status_str
        if ! $installed; then
            status_str="${DIM}not installed${RESET}"
            rc="${DIM}—${RESET}"
        elif $configured; then
            status_str="${GREEN}yes${RESET}"
        else
            status_str="${YELLOW}no${RESET}"
        fi

        printf "  %-10s %-25b %b\n" "$shell" "$status_str" "$rc"
    done

    echo ""

    # Show aliases file location
    if [ -f "$ALIASES_SH" ]; then
        log_ok "Aliases: ${DIM}$ALIASES_SH${RESET}"
    else
        log_err "Aliases: ${DIM}$ALIASES_SH (missing!)${RESET}"
    fi

    # Show git info
    if [ -d "$SCRIPT_DIR/.git" ]; then
        local branch
        branch="$(git -C "$SCRIPT_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")"
        local commit
        commit="$(git -C "$SCRIPT_DIR" log -1 --format='%h %s' 2>/dev/null || echo "unknown")"
        log_ok "Branch:  ${DIM}$branch${RESET}"
        log_ok "Latest:  ${DIM}$commit${RESET}"
    fi

    echo ""
}

# ── Menu ──────────────────────────────────────

show_menu() {
    echo ""
    echo -e "  ${BOLD}Aliases Setup${RESET}"
    echo -e "  ${DIM}──────────────────────────────${RESET}"
    echo ""
    echo -e "  ${CYAN}1)${RESET} Install    — set up aliases for detected shells"
    echo -e "  ${CYAN}2)${RESET} Update     — pull latest + reconfigure for new shells"
    echo -e "  ${CYAN}3)${RESET} Uninstall  — remove all aliases and clean up"
    echo -e "  ${CYAN}4)${RESET} Status     — show what's currently configured"
    echo -e "  ${CYAN}q)${RESET} Quit"
    echo ""
    printf "  Choose [1-4/q]: "

    local choice
    if ! { read -r choice < /dev/tty; } 2>/dev/null; then
        echo ""
        log_err "No terminal for the menu — pass a command instead"
        usage
        exit 1
    fi
    case "$choice" in
        1) do_install ;;
        2) do_update ;;
        3) do_uninstall ;;
        4) do_status ;;
        q|Q) echo "" ; exit 0 ;;
        *)
            log_err "Invalid choice: $choice"
            show_menu
            ;;
    esac
}

# ── Entry Point ───────────────────────────────

usage() {
    echo ""
    echo "  Usage: bash setup.sh [install|update|uninstall|status] [-y|--yes]"
    echo ""
}

main() {
    # CLI arg support: bash setup.sh install|update|uninstall|status [-y|--yes]
    local cmd="" arg
    for arg in "$@"; do
        case "$arg" in
            -y|--yes) ASSUME_YES=true ;;
            *)
                if [ -n "$cmd" ]; then
                    log_err "Unexpected argument: $arg"
                    usage
                    exit 1
                fi
                cmd="$arg"
                ;;
        esac
    done

    case "$cmd" in
        install)   do_install ;;
        update)    do_update ;;
        uninstall) do_uninstall ;;
        status)    do_status ;;
        "")        show_menu ;;
        *)
            log_err "Unknown command: $cmd"
            usage
            exit 1
            ;;
    esac
}

main "$@"
