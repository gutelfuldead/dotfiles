#!/bin/bash
here=$(pwd)
aurinit=0
autoyes=0
rcmVersion=1.3.6
gitRepoPath=$here/gitPkgs
appsFile=$here/apps.csv
logfile=$here/install.log
debian=0
arch=0
installApps=0
installAUR=0
gitinstall=0
installPip=0
wgetinstall=0
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
    sed -i "s/Jason Gutel/$name/g" ~/.gitconfig
    sed -i "s/jason.gutel@gmail.com/$email/g" ~/.gitconfig
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

gitInstall()
{
    app=$1
    repo=$2
    if ! command -v "$app" &>/dev/null && [ ! -d ~/."$app" ]; then
        git clone --depth 1 "$repo" ~/."$app" | tee -a "$logfile"
        (
            cd ~/."$app" || return 1
            if [ -f configure ]; then
                ./configure | tee -a "$logfile"
            fi
            if [ -f install ]; then
                ./install | tee -a "$logfile"
            elif [ -f makefile ] || [ -f Makefile ]; then
                make | tee -a "$logfile"
                sudo make install | tee -a "$logfile"
            fi
        )
    else
        echo "$app already installed, skipping"
    fi
}

installAppList()
{
    total=$(wc -l < "$appsFile")
    n=0
    while IFS=, read -r appType app manDot description gitRepo wgetRepo; do
        if [ "$n" -gt 0 ]; then # ignore top row of csv
            case "$appType" in
                A ) # install all distros
                    if [ "$installApps" -eq 1 ]; then
                        echo "sudo $tool $installArgs $app"
                        sudo $tool $installArgs "$app" | tee -a "$logfile"
                    fi
                    ;;
                U ) # install all ubuntu/debian apps
                    if [ "$installApps" -eq 1 ] && [ "$debian" -eq 1 ]; then
                        sudo $tool $installArgs "$app" | tee -a "$logfile"
                    fi
                    ;;
                X ) # install all arch apps
                    if [ "$installApps" -eq 1 ] && [ "$arch" -eq 1 ]; then
                        sudo $tool $installArgs "$app" | tee -a "$logfile"
                    fi
                    ;;
                AUR ) # install arch aur apps using paru TODO FIX THIS
                    if [ "$installAUR" -eq 1 ] ; then
                        if [ "$aurinit" -eq 0 ]; then
                            # https://github.com/Morganamilo/paru
                            if ! command -v paru &>/dev/null; then
                                sudo $tool $installArgs --needed base-devel
                                if [ ! -d "$gitRepoPath" ]; then
                                    mkdir -pv "$gitRepoPath"
                                fi
                                git clone https://aur.archlinux.org/paru.git "$gitRepoPath/paru"
                                (
                                    cd "$gitRepoPath/paru" || exit 1
                                    makepkg -si --skippgpcheck --needed --noconfirm --noprogressbar | tee -a "$logfile"
                                )
                            fi
                            aurinit=1
                        fi
                        paru $installArgs $app
                    fi
                    ;;
                GP ) # append group list, dont add now wait for everything to be installed, just aggregate
                    groups[${#groups[@]}]="$app"
                    ;;
                G ) # TODO git repo
                    if [ "$gitinstall" -eq 1 ]; then
                        gitInstall "$app" "$gitRepo"
                    fi
                    ;;
                P ) # install python packages via pip
                    if [ "$installPip" -eq 1 ]; then
                        pip3 install "$app" | tee -a "$logfile"
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
    # check to see if the group exists first
    getent group | grep "$1" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echon "adding user $user to $1 ..."
        sudo usermod -a -G "$1" "$user"
    else
        echon "group $1 does not exist, ignoring ..."
    fi
}

install_cinnamon()
{
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
# get linux distro
################################################################################
if command -v pacman &>/dev/null; then
    distro="arch"
    arch=1
    tool="pacman"
    installArgs="-Sy --noconfirm --needed --noprogressbar"
elif command -v apt-get &>/dev/null; then
    distro="debian"
    debian=1
    tool="apt-get"
    installArgs="install -y"
fi

if [ "$arch" -eq 0 ] && [ "$debian" -eq 0 ]; then
    # arch is so OP it doesnt come with which
    sudo pacman -Sy which
    if [ $? -ne 0 ]; then
        echon "unknown distro"
        exit 1
    else
        distro="arch"
        arch=1
        tool="pacman"
        installArgs="-Sy --noconfirm --needed --noprogressbar"
    fi
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

if confirm "Install packages with $tool (tag(s) A|U|X from $appsFile) ?"; then
    echon "installing and updating apps with $tool ..."
    installApps=1
    if [ "$debian" -eq 1 ]; then
        sudo "$tool" update | tee -a "$logfile"
        sudo "$tool" upgrade -y | tee -a "$logfile"
    fi
    if [ "$arch" -eq 1 ]; then
        sudo pacman -Syu --noconfirm --needed --noprogressbar | tee -a "$logfile"
    fi
else
    echon "NOT installing and updating apps with $tool ..."
fi

################################################################################
# Install git apps
################################################################################
if confirm "Install GIT based Applications (tag G from $appsFile) ?"; then
    gitinstall=1
else
    echon "NOT installing git applications ..."
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
# install all arch AUR apps
################################################################################
if [ "$arch" -eq 1 ]; then
    if confirm "Install AUR packages (tag AUR from $appsFile) ?"; then
        installAUR=1
    else
        echon "NOT Installing ARCH AUR packages"
    fi
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
    if [ "$arch" -eq 1 ]; then
        rcup -v -d "$here/arch-files" | tee -a "$logfile"
        sudo sed -i "s/^#VerbosePkgLists$/VerbosePkgLists/" /etc/pacman.conf
        sudo sed -i "s/^#Color$/Color/" /etc/pacman.conf

        sudo sed -i "s/^#*MAKEFLAGS=.*/MAKEFLAGS=\"-j$(nproc)\"/" /etc/makepkg.conf
    fi
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
tmp="${groups[*]}"
if confirm "Add $(whoami) to groups : < $tmp >"; then
    echon "Adding $(whoami) to groups..."
    for i in "${groups[@]}"; do
        addGroup "$i"
    done
else
    echon "NOT adding $(whoami) to groups < $tmp >"
fi

################################################################################
# Kill the arch beeps
################################################################################
if [ "$arch" -eq 1 ]; then
    if ! grep -q "blacklist pcspkr" /etc/modprobe.d/nobeep.conf 2>/dev/null; then
        if confirm "Disable system beeps ?"; then
            echon "Disabling system beeps"
            lsmod | grep pcspkr && sudo rmmod pcspkr
            sudo echo "blacklist pcspkr" | sudo tee /etc/modprobe.d/nobeep.conf
        else
            echon "NOT Disabling system beeps"
        fi
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
# Enable GNOME Display Manager for Arch if it isnt already
################################################################################
if [ "$arch" -eq 1 ]; then
    systemctl is-enabled gdm > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        sudo systemctl enable gdm
        echon "GNOME Display Manager Enabled, reboot to load into GNOME/Cinnamon"
    fi
fi


################################################################################
# clean up
################################################################################
if confirm "Clean unused packages ($tool autoremove)?"; then
    if [ "$arch" -eq 0 ]; then
        sudo "$tool" autoremove -y | tee -a "$logfile"
    else
        orphans=$(pacman -Qdtq)
        if [ -n "$orphans" ]; then
            sudo pacman -Rns $orphans --noconfirm
        fi
        sudo pacman -Sc --noconfirm --noprogressbar | tee -a "$logfile"
    fi
else
    echon "NOT cleaning packages"
fi
