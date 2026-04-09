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

_script_dir() {
    cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd
}

SCRIPT_DIR="$(_script_dir 2>/dev/null || echo "")"

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
FISH_CONF_DIR="$HOME/.config/fish/conf.d"
FISH_TARGET="$FISH_CONF_DIR/aliases.fish"
SOURCE_TAG="# aliases-bootstrap"

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

detect_shells() {
    SHELLS=()
    RC_FILES=()

    if command -v bash > /dev/null 2>&1; then
        SHELLS+=("bash")
        RC_FILES+=("$HOME/.bashrc")
    fi
    if command -v zsh > /dev/null 2>&1; then
        SHELLS+=("zsh")
        RC_FILES+=("$HOME/.zshrc")
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
            [ -L "$FISH_TARGET" ] || [ -f "$FISH_TARGET" ] && return 0
            return 1
            ;;
    esac
    return 1
}

get_rc_file() {
    local shell="$1"
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
            mkdir -p "$FISH_CONF_DIR"
            ln -sf "$ALIASES_FISH" "$FISH_TARGET"
            log_ok "fish — symlinked to $FISH_TARGET"
            ;;
    esac
}

remove_source_line() {
    local shell="$1"

    case "$shell" in
        bash|zsh)
            local rc
            rc="$(get_rc_file "$shell")"
            if [ -f "$rc" ] && grep -qF "$SOURCE_TAG" "$rc" 2>/dev/null; then
                sed -i "/$SOURCE_TAG/d" "$rc"
                # Clean up any trailing blank lines we left behind
                sed -i -e :a -e '/^\n*$/{$d;N;ba' -e '}' "$rc"
                log_ok "$shell — removed source line from $rc"
            else
                log_info "$shell — not configured, nothing to remove"
            fi
            ;;
        fish)
            if [ -L "$FISH_TARGET" ] || [ -f "$FISH_TARGET" ]; then
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

    read -r yn
    yn="${yn:-$default}"
    case "$yn" in
        [Yy]*) return 0 ;;
        *) return 1 ;;
    esac
}

# ── Alias Summary ────────────────────────────

_parse_aliases_sh() {
    # Source in a clean interactive subshell to get only what's active on this machine
    local shell_bin="$1"  # bash or zsh
    local combined
    combined="$("$shell_bin" --norc --noprofile -i -c ". '$ALIASES_SH'; alias; declare -F" 2>/dev/null)"

    # Aliases (sorted)
    while IFS='=' read -r name value; do
        value="${value#\'}"
        value="${value%\'}"
        printf "    ${CYAN}%-16s${RESET} %s\n" "$name" "$value"
    done < <(echo "$combined" | sed -n "s/^alias //p" | sort)

    # User-defined functions — skip internal ones (prefixed with _)
    while IFS= read -r fname; do
        printf "    ${CYAN}%-16s${RESET} (function)\n" "$fname"
    done < <(echo "$combined" | awk '/^declare -f [^_]/{print $3}' | sort)
}

_parse_aliases_fish() {
    local file="$1"
    while IFS= read -r line; do
        if [[ "$line" =~ ^#\ ──\ (.+)$ ]]; then
            local section="${BASH_REMATCH[1]}"
            section="${section%%─*}"
            section="${section% }"
            printf "\n    ${DIM}%s${RESET}\n" "$section"
        elif [[ "$line" =~ ^[[:space:]]*abbr\ -a\ ([^[:space:]]+)[[:space:]]\'([^\']+)\' ]]; then
            printf "    ${CYAN}%-16s${RESET} %s\n" "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"
        elif [[ "$line" =~ ^function[[:space:]]+([a-z_][a-z0-9_]*) ]]; then
            printf "    ${CYAN}%-16s${RESET} (function)\n" "${BASH_REMATCH[1]}"
        fi
    done < "$file"
}

show_aliases_summary() {
    local -a shells_to_show=("$@")
    local show_fish=false
    local -a sh_shells=()

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
        label="$(IFS=', '; echo "${sh_shells[*]}")"
        echo ""
        echo -e "  ${BOLD}Aliases available in $label:${RESET}"
        echo ""
        # Use the first configured sh-compatible shell to evaluate
        _parse_aliases_sh "${sh_shells[0]}"
    fi

    if $show_fish; then
        echo ""
        echo -e "  ${BOLD}Aliases available in fish:${RESET}"
        _parse_aliases_fish "$ALIASES_FISH"
        echo ""
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
    [ ${#now_configured[@]} -gt 0 ] && show_aliases_summary "${now_configured[@]}"

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

    # Verify existing shells still have source line
    for shell in "${existing_shells[@]}"; do
        if ! is_configured "$shell"; then
            log_warn "$shell — source line was removed, re-adding..."
            add_source_line "$shell"
        fi
    done

    if [ ${#new_shells[@]} -eq 0 ] && [ ${#broken_shells[@]} -eq 0 ]; then
        log_ok "All shells up to date"
    fi

    local now_configured=()
    for shell in "${SHELLS[@]}"; do
        if is_configured "$shell"; then
            now_configured+=("$shell")
        fi
    done
    [ ${#now_configured[@]} -gt 0 ] && show_aliases_summary "${now_configured[@]}"

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
            # Find rc file
            case "$shell" in
                bash) rc="$HOME/.bashrc" ;;
                zsh)  rc="$HOME/.zshrc" ;;
                fish) rc="$FISH_TARGET" ;;
            esac

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
    read -r choice
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

main() {
    # CLI arg support: bash setup.sh install|update|uninstall|status
    case "${1:-}" in
        install)   do_install ;;
        update)    do_update ;;
        uninstall) do_uninstall ;;
        status)    do_status ;;
        "")        show_menu ;;
        *)
            log_err "Unknown command: $1"
            echo ""
            echo "  Usage: bash setup.sh [install|update|uninstall|status]"
            echo ""
            exit 1
            ;;
    esac
}

main "$@"
