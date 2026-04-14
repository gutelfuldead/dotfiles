#!/bin/bash
# docker-test.sh - Run install.sh inside a throwaway Docker container.
# Nothing is written to your real home directory.
#
# Usage:
#   ./docker-test.sh              # test Ubuntu (default)
#   ./docker-test.sh --arch       # test Arch Linux
#   ./docker-test.sh --both       # test both sequentially

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
LOGDIR="$DOTFILES/docker-test-logs"

green='\033[0;32m'; red='\033[0;31m'; bold='\033[1m'; yellow='\033[0;33m'; reset='\033[0m'

pass() { echo -e "  ${green}PASS${reset}  $1"; }
fail() { echo -e "  ${red}FAIL${reset}  $1"; }
warn() { echo -e "  ${yellow}WARN${reset}  $1"; }
section() { echo -e "\n${bold}=== $1 ===${reset}"; }

DISTROS=()

while [[ $# -gt 0 ]]; do
    case $1 in
        --ubuntu) DISTROS+=("ubuntu"); shift ;;
        --arch)   DISTROS+=("arch");   shift ;;
        --both)   DISTROS+=("ubuntu" "arch"); shift ;;
        -h|--help)
            echo "Usage: $0 [--ubuntu|--arch|--both]"
            echo "  Default: --ubuntu"
            exit 0
            ;;
        *) echo "Unknown argument: $1"; exit 1 ;;
    esac
done

# Default to ubuntu if no distro specified
[ ${#DISTROS[@]} -eq 0 ] && DISTROS=("ubuntu")

################################################################################
# Preflight
################################################################################

if ! command -v docker &>/dev/null; then
    echo -e "${red}docker not found in PATH${reset}"
    exit 1
fi

# Determine whether to use plain docker or sudo docker
DOCKER="docker"
if ! docker info &>/dev/null; then
    if sudo docker info &>/dev/null; then
        DOCKER="sudo docker"
        echo -e "${yellow}Note: using sudo docker (run 'sudo usermod -aG docker \$USER' and re-login to avoid this)${reset}"
    else
        echo -e "${red}Docker daemon not running or no permission even with sudo${reset}"
        exit 1
    fi
fi

mkdir -p "$LOGDIR"

################################################################################
# Run one distro test
################################################################################

run_test() {
    local distro="$1"
    local image setup_cmds
    local logfile="$LOGDIR/${distro}-$(date +%Y%m%d-%H%M%S).log"

    case "$distro" in
        ubuntu)
            image="ubuntu:22.04"
            setup_cmds="apt-get update -qq \
                && apt-get install -y -qq --no-install-recommends sudo make curl git"
            ;;
        arch)
            image="archlinux:latest"
            setup_cmds="pacman -Sy --noconfirm --needed sudo curl git"
            ;;
    esac

    section "Testing on $distro ($image)"
    echo -e "  Log: $logfile\n"
    echo -e "  ${yellow}Note: this pulls an image and installs packages — it will take a few minutes.${reset}\n"

    # What happens inside the container:
    # 1. Install minimal base deps (sudo, curl, git)
    # 2. Create a non-root user with passwordless sudo (mirrors a real install)
    # 3. Copy dotfiles into the user's home (volume mount is read-only)
    # 4. Run install.sh -y as that user
    local exit_code=0
    $DOCKER run --rm \
        -v "$DOTFILES:/dotfiles:ro" \
        "$image" \
        bash -c "
            $setup_cmds
            useradd -m -s /bin/bash tester 2>/dev/null || true
            echo 'tester ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/tester
            echo 'Defaults env_keep += "DEBIAN_FRONTEND"' > /etc/sudoers.d/env_keep
            chmod 440 /etc/sudoers.d/tester /etc/sudoers.d/env_keep
            cp -r /dotfiles /home/tester/dotfiles
            chown -R tester:tester /home/tester/dotfiles
            su - tester -c 'export DEBIAN_FRONTEND=noninteractive TZ=UTC; cd ~/dotfiles && bash install.sh -y'
        " 2>&1 | tee "$logfile" || exit_code=${PIPESTATUS[0]}

    echo ""
    section "Results for $distro"

    # Exit code
    if [ "$exit_code" -eq 0 ]; then
        pass "install.sh exited cleanly (exit 0)"
    else
        fail "install.sh exited with code $exit_code"
    fi

    # Spot-check the log for known success indicators
    check_log() {
        local desc="$1" pattern="$2"
        if grep -q "$pattern" "$logfile"; then
            pass "$desc"
        else
            warn "$desc (pattern not found — check log)"
        fi
    }

    check_log "distro detected"                   "Setup for"
    check_log "packages installed"                "Installing Applications"
    check_log "dotfiles step reached"             "replacing dotfiles\|updating dotfiles\|NOT replacing dotfiles"
    check_log "groups step reached"               "adding.*to groups\|NOT adding"
    check_log "cleanup step reached"              "cleaning packages\|NOT cleaning"

    # Flag known non-fatal expected failures in Docker
    if grep -q "systemctl" "$logfile" && grep -q "Failed\|not found\|inactive" "$logfile"; then
        warn "systemctl calls failed (expected — no systemd in Docker)"
    fi
    if grep -qi "E: Unable to locate package\|error: target not found" "$logfile"; then
        warn "one or more packages not found — review log for details"
    fi

    echo ""
    if [ "$exit_code" -ne 0 ]; then
        echo -e "${bold}Last 40 lines of log:${reset}"
        tail -40 "$logfile"
    else
        echo -e "Full log saved to: $logfile"
    fi

    return "$exit_code"
}

################################################################################
# Main
################################################################################

overall=0
for distro in "${DISTROS[@]}"; do
    run_test "$distro" || overall=1
done

echo ""
if [ "$overall" -eq 0 ]; then
    echo -e "${green}${bold}All tests passed.${reset}"
else
    echo -e "${red}${bold}One or more tests failed. Check logs in $LOGDIR/${reset}"
fi

exit "$overall"
