#!/bin/bash
here=$(pwd)
autoyes=0
rcmVersion=1.3.6
appsFile=$here/apps.csv
logfile=$here/install.log
debian=0
macos=0
installApps=0
installPip=0
installDotfiles=0
distro=""
tool=""
installArgs=""
groups=()

# parse command line arguments
for arg in "$@"; do
    case "$arg" in
        -y|--yes)
            autoyes=1
            ;;
        -h|--help)
            echo "Usage: $0 [--yes|-y]"
            echo "  --yes, -y    Auto-answer yes to all prompts (unattended mode)"
            exit 0
            ;;
        *)
            echo "Unknown argument: $arg"
            echo "Usage: $0 [--yes|-y]"
            exit 1
            ;;
    esac
done

# confirm prompt helper: returns 0 (yes) or 1 (no)
# in --yes mode, always returns 0 without prompting
confirm()
{
    if [ "$autoyes" -eq 1 ]; then
        return 0
    fi
    read -r -p "$1 [y/n] : " response
    case "$response" in
        [yY][eE][sS]|[yY])
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

echon ()
{
    echo -e "\n################################################################################" | tee -a "$logfile"
    echo -e "$1" | tee -a "$logfile"
    echo -e "################################################################################\n" | tee -a "$logfile"
    sleep 1
}


updateGitConfig()
{
    read -r -p "Enter name : " name
    read -r -p "Enter email : " email
    if [ "$macos" -eq 1 ]; then
        sed -i '' "s/Jason Gutel/$name/g" ~/.gitconfig
        sed -i '' "s/jason.gutel@gmail.com/$email/g" ~/.gitconfig
    else
        sed -i "s/Jason Gutel/$name/g" ~/.gitconfig
        sed -i "s/jason.gutel@gmail.com/$email/g" ~/.gitconfig
    fi
    echon "Overriding default name and email for gitconfig with name=$name email=$email"
}

# https://github.com/thoughtbot/rcm
installRcm ()
{
    ver=$rcmVersion
    echon "Installing RCM"
    if [ ! -d ~/.rcm ]; then
        curl -LO https://thoughtbot.github.io/rcm/dist/rcm-${ver}.tar.gz
        mkdir ~/.rcm
        tar -xvf rcm-${ver}.tar.gz --directory ~/.rcm
        mv ~/.rcm/rcm-${ver}/* ~/.rcm
        rm -rf ~/.rcm/rcm-${ver}
        rm -f rcm-${ver}.tar.gz
    fi
    (
        cd ~/.rcm || return 1
        ./configure
        make
        sudo make install
    )
}

installAppList()
{
    total=$(wc -l < "$appsFile")
    n=0
    while IFS=, read -r type app description dotfiles debianPkg homebrewPkg; do
        if [ "$n" -gt 0 ]; then # ignore top row of csv
            case "$type" in
                pkg ) # regular packages - check platform-specific columns
                    if [ "$installApps" -eq 1 ]; then
                        pkgname=""
                        if [ "$debian" -eq 1 ] && [ "$debianPkg" != "n/a" ]; then
                            pkgname="$debianPkg"
                        elif [ "$macos" -eq 1 ] && [ "$homebrewPkg" != "n/a" ]; then
                            pkgname="$homebrewPkg"
                        fi

                        if [ -n "$pkgname" ]; then
                            if [ "$macos" -eq 1 ]; then
                                echo "$tool $installArgs $pkgname"
                                $tool $installArgs "$pkgname" </dev/null | tee -a "$logfile"
                            else
                                echo "sudo $tool $installArgs $pkgname"
                                sudo $tool $installArgs "$pkgname" </dev/null | tee -a "$logfile"
                            fi
                        fi
                    fi
                    ;;
                pip ) # python packages via pip (same name across platforms)
                    if [ "$installPip" -eq 1 ] && [ "$debianPkg" != "n/a" ]; then
                        if [ "$macos" -eq 1 ]; then
                            if ! command -v pipx &>/dev/null; then
                                brew install pipx </dev/null | tee -a "$logfile"
                            fi
                            pipx install "$debianPkg" </dev/null | tee -a "$logfile"
                        else
                            pip3 install "$debianPkg" </dev/null | tee -a "$logfile"
                        fi
                    fi
                    ;;
                group ) # groups to add user to
                    if [ "$debian" -eq 1 ] && [ "$debianPkg" != "n/a" ]; then
                        groups[${#groups[@]}]="$debianPkg"
                    elif [ "$macos" -eq 1 ] && [ "$homebrewPkg" != "n/a" ]; then
                        groups[${#groups[@]}]="$homebrewPkg"
                    fi
                    ;;
                * )
                    ;;
            esac
        fi
        n=$((n+1))
    done < "$appsFile"
}

backup ()
{
    backupdir=$here/backup
    if [ -d "$backupdir" ]; then
        if confirm "Overwrite current contents of $backupdir ?"; then
            echon "OVERWRITING CURRENT CONTENTS OF $backupdir"
            rm -rf "$backupdir"
        else
            return
        fi
    fi
    echon "Backing up deployed dot files from ~ to $backupdir ..."
    mkdir -p "$backupdir"
    (
        cd "$here/files" || return 1
        find . -maxdepth 100 -type f | sort | while read -r i; do
            relpath="${i#./}"
            deployed="$HOME/.$relpath"
            if [ -f "$deployed" ] || [ -L "$deployed" ]; then
                mkdir -p "$backupdir/$(dirname "$relpath")"
                cp -v "$deployed" "$backupdir/$relpath" | tee -a "$logfile"
            fi
        done
    )
}

addGroup()
{
    user=$(whoami)
    if [ "$macos" -eq 1 ]; then
        # macOS: check if group exists and user is member
        if dscl . -read /Groups/"$1" &>/dev/null; then
            if ! dscl . -read /Groups/"$1" GroupMembership | grep -q "$user"; then
                echon "adding user $user to $1 ..."
                sudo dseditgroup -o edit -a "$user" -t user "$1"
            else
                echon "user $user already in group $1"
            fi
        else
            echon "group $1 does not exist, ignoring ..."
        fi
    else
        # Linux: use getent and usermod
        getent group | grep "$1" > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            echon "adding user $user to $1 ..."
            sudo usermod -a -G "$1" "$user"
        else
            echon "group $1 does not exist, ignoring ..."
        fi
    fi
}

install_cinnamon()
{
    if [ "$macos" -eq 1 ]; then
        echon "Skipping Cinnamon Desktop (Linux only)"
        return 0
    fi
    if ! confirm "Install Cinnamon Desktop?"; then
        echon "NOT Installing Cinnamon Desktop"
        return 0
    fi
    echon "Installing Cinnamon Desktop"
    sudo $tool $installArgs cinnamon
}

install_oh_my_zsh()
{
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
}

################################################################################
# start main
################################################################################
if [ ! -f "$logfile" ]; then
    touch "$logfile"
fi
echon "$0 ran @ $(date)..."

################################################################################
# get distro
################################################################################
if command -v apt-get &>/dev/null; then
    distro="debian"
    debian=1
    tool="apt-get"
    installArgs="install -y"
elif command -v brew &>/dev/null; then
    distro="macos"
    macos=1
    tool="brew"
    installArgs="install"
fi

if [ "$debian" -eq 0 ] && [ "$macos" -eq 0 ]; then
    echon "unknown distro - no package manager found (apt-get or brew)"
    exit 1
fi

################################################################################
# install pacman apps
################################################################################
echon "Setup for $distro ..."

if [ "$debian" -eq 1 ]; then
    # Prevent apt-get from prompting during package installs
    export DEBIAN_FRONTEND=noninteractive
    echo 'Defaults env_keep += "DEBIAN_FRONTEND"' | sudo tee /etc/sudoers.d/debian_frontend > /dev/null
    sudo chmod 440 /etc/sudoers.d/debian_frontend
    # Pre-seed known interactive package prompts
    if ! command -v debconf-set-selections &>/dev/null; then
        sudo "$tool" install -y -q debconf-utils
    fi
    sudo debconf-set-selections <<< "tzdata tzdata/Areas select Etc"
    sudo debconf-set-selections <<< "tzdata tzdata/Zones/Etc select UTC"
    sudo debconf-set-selections <<< "wireshark-common wireshark-common/install-setuid boolean false"
fi

if confirm "Install packages with $tool from $appsFile ?"; then
    echon "installing and updating apps with $tool ..."
    installApps=1
    if [ "$debian" -eq 1 ]; then
        sudo "$tool" update | tee -a "$logfile"
        sudo "$tool" upgrade -y | tee -a "$logfile"
    fi
else
    echon "NOT installing and updating apps with $tool ..."
fi

################################################################################
# Install pip packages
################################################################################
if confirm "Install Python packages with pip (tag P from $appsFile) ?"; then
    installPip=1
else
    echon "NOT installing pip packages ..."
fi

################################################################################
# Actually install everything
################################################################################
echon "Installing Applications"
installAppList
install_cinnamon

################################################################################
# Install oh my zsh
################################################################################
if confirm "Install oh my zsh?"; then
    install_oh_my_zsh
fi

################################################################################
# update dotfiles if RCM was installed
################################################################################
if confirm "Replace local dotfiles? (current versions will be backed up)"; then
    installDotfiles=1
    backup
    echon "updating dotfiles ..."
    if ! command -v rcup &>/dev/null; then
        installRcm
    fi
    rcup -v -d "$here/files" rcrc | tee -a "$logfile"
    source ~/.rcrc
    rcup -v -d "$here/files" | tee -a "$logfile"
    ###################################
    # install vim dotfiles and packages
    ###################################
    if command -v vim &>/dev/null; then
        echon "installing vim settings ... "
        vim -c 'PlugClean' +qa
        vim -c 'PlugInstall' +qa
        vim ~/.vim/vbas/Align.vba -c 'source %' +qa
    fi
    if command -v texhash &>/dev/null; then
        echon "Running texhash"
        texhash ~/texmf
    fi
else
    echon "NOT replacing dotfiles"
fi

################################################################################
# Add user to groups
################################################################################
if [ "$debian" -eq 1 ]; then
    tmp="${groups[*]}"
    if confirm "Add $(whoami) to groups : < $tmp >"; then
        echon "Adding $(whoami) to groups..."
        for i in "${groups[@]}"; do
            addGroup "$i"
        done
    else
        echon "NOT adding $(whoami) to groups < $tmp >"
    fi
fi

################################################################################
# Get rid of my name from anywhere it doesnt belong
################################################################################
if [ "$installDotfiles" -eq 1 ]; then
    # skip in --yes mode since this requires interactive input
    if [ "$autoyes" -eq 0 ] && confirm "Modify .gitconfig default name and email ?"; then
        updateGitConfig
    fi

fi

################################################################################
# clean up
################################################################################
if confirm "Clean unused packages ($tool autoremove)?"; then
    if [ "$macos" -eq 1 ]; then
        brew cleanup | tee -a "$logfile"
        brew autoremove | tee -a "$logfile"
    else
        sudo "$tool" autoremove -y | tee -a "$logfile"
    fi
else
    echon "NOT cleaning packages"
fi
