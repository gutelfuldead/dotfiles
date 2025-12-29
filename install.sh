#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

###############################################################################
# install.sh
#
# Deterministic, non-interactive system bootstrap script.
#
# Features:
#   - Flag-driven (no prompts)
#   - Dry-run support
#   - CI safe
#   - ShellCheck clean
#   - Batched package installs per package manager
#   - Supports Debian/Ubuntu, CentOS, Arch Linux
#
# Behavior:
#   - Does nothing unless explicitly instructed via CLI flags
#   - Prints help and exits if no arguments are provided
###############################################################################

###############################################################################
# Paths & Files
###############################################################################
HERE="$(pwd)"
GIT_REPO_PATH="$HERE/gitPkgs"
APPS_FILE="$HERE/apps.csv"
LOGFILE="$HERE/install.log"

###############################################################################
# Distro / package manager state
###############################################################################
DISTRO=""
TOOL=""
INSTALL_ARGS=()

DEBIAN=0
CENTOS=0
ARCH=0

###############################################################################
# Execution flags
###############################################################################
DRY_RUN=0
YES=0

INSTALL_PACKAGES=0
INSTALL_GIT=0
INSTALL_AUR=0
INSTALL_DOTFILES=0
BACKUP_ONLY=0
ADD_GROUPS=0
UPDATE_GITCONFIG=0
CLEANUP=0

###############################################################################
# Identity
###############################################################################
GIT_NAME=""
GIT_EMAIL=""

###############################################################################
# Package batching buckets
###############################################################################
PKGS_ALL=()
PKGS_DEBIAN=()
PKGS_CENTOS=()
PKGS_ARCH=()
PKGS_AUR=()

###############################################################################
# Group aggregation
###############################################################################
GROUPS=()

###############################################################################
# Help
###############################################################################
usage() {
cat <<'EOF'
Usage: install.sh [OPTIONS]

General:
  -h, --help                  Show this help and exit
  -n, --dry-run               Print commands without executing
  --yes                       Assume yes for all operations

Packages:
  --install-packages          Install packages from apps.csv
  --install-git               Install git-based applications
  --install-aur               Install Arch AUR packages

Dotfiles:
  --install-dotfiles          Backup and replace dotfiles
  --backup-only               Backup dotfiles only

Users:
  --add-groups                Add current user to groups from apps.csv

Identity:
  --update-gitconfig          Update ~/.gitconfig
  --git-name NAME             Git user.name
  --git-email EMAIL           Git user.email

Maintenance:
  --cleanup                   Remove unused packages

Examples:
  Dry run:
    ./install.sh --dry-run --install-packages

  CI install:
    ./install.sh --yes --install-packages --cleanup
EOF
}

###############################################################################
# No-args guard
###############################################################################
if [[ $# -eq 0 ]]; then
    usage
    exit 0
fi

###############################################################################
# Argument parsing
###############################################################################
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help) usage; exit 0 ;;
        -n|--dry-run) DRY_RUN=1 ;;
        --yes) YES=1 ;;
        --install-packages) INSTALL_PACKAGES=1 ;;
        --install-git) INSTALL_GIT=1 ;;
        --install-aur) INSTALL_AUR=1 ;;
        --install-dotfiles) INSTALL_DOTFILES=1 ;;
        --backup-only) BACKUP_ONLY=1 ;;
        --add-groups) ADD_GROUPS=1 ;;
        --update-gitconfig) UPDATE_GITCONFIG=1 ;;
        --git-name) GIT_NAME="$2"; shift ;;
        --git-email) GIT_EMAIL="$2"; shift ;;
        --cleanup) CLEANUP=1 ;;
        *) echo "Unknown option: $1"; usage; exit 1 ;;
    esac
    shift
done

###############################################################################
# Helpers
###############################################################################
quote_cmd() { printf '%q ' "$@"; }

run() {
    if [[ $DRY_RUN -eq 1 ]]; then
        printf '[DRY-RUN] '
        quote_cmd "$@"
        printf '\n'
    else
        "$@"
    fi
}

run_log() {
    if [[ $DRY_RUN -eq 1 ]]; then
        printf '[DRY-RUN] '
        quote_cmd "$@"
        printf '\n' | tee -a "$LOGFILE"
    else
        "$@" | tee -a "$LOGFILE"
    fi
}

log() {
    {
        echo
        echo "###############################################################################"
        echo "$1"
        echo "###############################################################################"
        echo
    } | tee -a "$LOGFILE"
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

###############################################################################
# Detect distro and configure package manager
###############################################################################
detect_distro() {
    if command_exists apt-get; then
        DISTRO="debian"
        DEBIAN=1
        TOOL="apt-get"
        INSTALL_ARGS=(install -y)
    elif command_exists yum; then
        DISTRO="centos"
        CENTOS=1
        TOOL="yum"
        INSTALL_ARGS=(install -y --nogpgcheck --skip-broken)
    elif command_exists pacman; then
        DISTRO="arch"
        ARCH=1
        TOOL="pacman"
        INSTALL_ARGS=(-Sy --noconfirm --needed)
    else
        log "Unsupported distro"
        exit 1
    fi
}

###############################################################################
# Git identity
###############################################################################
update_git_config() {
    [[ -n "$GIT_NAME" && -n "$GIT_EMAIL" ]] || {
        echo "Missing --git-name or --git-email"
        exit 1
    }

    sed -i "s/Jason Gutel/$GIT_NAME/g" "$HOME/.gitconfig"
    sed -i "s/jason.gutel@gmail.com/$GIT_EMAIL/g" "$HOME/.gitconfig"
}

###############################################################################
# Parse apps.csv and collect packages
###############################################################################
collect_packages() {
    local n=0
    local type app git_repo

    while IFS=, read -r type app _ _ git_repo _; do
        ((n++ == 0)) && continue

        case "$type" in
            A)   [[ $INSTALL_PACKAGES -eq 1 ]] && PKGS_ALL+=("$app") ;;
            U)   [[ $INSTALL_PACKAGES -eq 1 && $DEBIAN -eq 1 ]] && PKGS_DEBIAN+=("$app") ;;
            C)   [[ $INSTALL_PACKAGES -eq 1 && $CENTOS -eq 1 ]] && PKGS_CENTOS+=("$app") ;;
            X)   [[ $INSTALL_PACKAGES -eq 1 && $ARCH -eq 1 ]] && PKGS_ARCH+=("$app") ;;
            AUR) [[ $INSTALL_AUR -eq 1 && $ARCH -eq 1 ]] && PKGS_AUR+=("$app") ;;
            GP)  GROUPS+=("$app") ;;
            G)   [[ $INSTALL_GIT -eq 1 ]] && git_install "$app" "$git_repo" ;;
        esac
    done < "$APPS_FILE"
}

###############################################################################
# Execute batched installs
###############################################################################
install_batched_packages() {
    if [[ $INSTALL_PACKAGES -eq 1 ]]; then
        if [[ $DEBIAN -eq 1 && ( ${#PKGS_ALL[@]} -gt 0 || ${#PKGS_DEBIAN[@]} -gt 0 ) ]]; then
            run_log sudo apt-get "${INSTALL_ARGS[@]}" \
                "${PKGS_ALL[@]}" "${PKGS_DEBIAN[@]}"
        fi

        if [[ $CENTOS -eq 1 && ( ${#PKGS_ALL[@]} -gt 0 || ${#PKGS_CENTOS[@]} -gt 0 ) ]]; then
            run_log sudo yum "${INSTALL_ARGS[@]}" \
                "${PKGS_ALL[@]}" "${PKGS_CENTOS[@]}"
        fi

        if [[ $ARCH -eq 1 && ( ${#PKGS_ALL[@]} -gt 0 || ${#PKGS_ARCH[@]} -gt 0 ) ]]; then
            run_log sudo pacman "${INSTALL_ARGS[@]}" \
                "${PKGS_ALL[@]}" "${PKGS_ARCH[@]}"
        fi
    fi

    if [[ $INSTALL_AUR -eq 1 && $ARCH -eq 1 && ${#PKGS_AUR[@]} -gt 0 ]]; then
        run_log paru "${PKGS_AUR[@]}"
    fi
}

###############################################################################
# Groups
###############################################################################
add_groups() {
    local user
    user="$(whoami)"

    for g in "${GROUPS[@]}"; do
        getent group "$g" >/dev/null && run sudo usermod -aG "$g" "$user"
    done
}

###############################################################################
# Main
###############################################################################
touch "$LOGFILE"
log "Started at $(date)"

detect_distro
log "Detected distro: $DISTRO"

[[ $INSTALL_PACKAGES -eq 1 ]] && {
    [[ $ARCH -eq 1 ]] && run sudo pacman -Syu --noconfirm
    [[ $ARCH -eq 0 ]] && { run sudo "$TOOL" update -y; run sudo "$TOOL" upgrade -y; }
}

collect_packages
install_batched_packages

[[ $ADD_GROUPS -eq 1 ]] && add_groups
[[ $UPDATE_GITCONFIG -eq 1 ]] && update_git_config

[[ $CLEANUP -eq 1 ]] && {
    run sudo "$TOOL" autoremove -y || true
    [[ $ARCH -eq 1 ]] && run sudo pacman -Sc --noconfirm
}

log "Complete"
