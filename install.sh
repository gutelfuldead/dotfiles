#!/bin/bash
here=$(pwd)
aurinit=0
gitRepoPath=$here/gitPkgs
appsFile=$here/apps.csv
logfile=$here/install.log
installPip=0
debian=0
centos=0
arch=0
pipInit=0
installApps=0
installAUR=0
gitinstall=0
wgetinstall=0
installDotfiles=0
distro=""
tool=""
installArgs=""
groups=()

echon ()
{
    echo -e "\n################################################################################" | tee -a $logfile
    echo -e "$1" | tee -a $logfile
    echo -e "################################################################################\n" | tee -a $logfile
    sleep 1
}

overrideDotfiles()
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
    ver=1.3.4
    echon "Installing RCM"
    if [ ! -d ~/.rcm ]; then
        curl -LO https://thoughtbot.github.io/rcm/dist/rcm-${ver}.tar.gz
        mkdir ~/.rcm
        tar -xvf rcm-${ver}.tar.gz --directory ~/.rcm
        mv ~/.rcm/rcm-${ver}/* ~/.rcm
        rm -rf ~/.rcm/rcm-${ver}
        rm -f rcm-${ver}.tar.gz
    fi
    cd ~/.rcm
    ./configure
    make
    sudo make install
    cd $here
}

# manually install i3 on CentOS 7.1 which has deprecated packages in yum
installCentosI3 ()
{
    read -r -p "Install i3? [y/n] : " response
    case "$response" in
        [yY][eE][sS]|[yY])
            echon "Installing i3 Desktop"
            ;;
        *)
            echon "NOT Installing i3 Desktop"
            return 0
            ;;
    esac

    if [ ! -d $gitRepoPath ]; then
        mkdir -pv $gitRepoPath
    fi

    # pre-reqs for i3-gaps and i3status
    sudo yum install -y -q "xcb-util*-devel" \
            "xorg-x11-font*" \
            autoconf \
            automake \
            gcc \
            git \
            libev-devel \
            libX11-devel \
            libxcb-devel \
            libXinerama-devel \
            libxkbcommon-devel \
            libxkbcommon-x11-devel \
            libXrandr-devel \
            libconfuse-devel \
            pulseaudio-libs-devel \
            libnl-devel \
            libnl3-devel \
            alsa-lib-devel
            make \
            pango-devel \
            pcre-devel \
            startup-notification-devel \
            wget \
            xcb-util-cursor-devel \
            xcb-util-devel \
            xcb-util-keysyms-devel \
            xcb-util-wm-devel \
            xcb-util-xrm-devel \
            xorg-x11-util-macros \
            i3 \
            i3lock \
            i3status \
            yajl-devel \
            xterm

    git clone --recursive https://github.com/Airblader/xcb-util-xrm $gitRepoPath/xcb-util-xrm
    cd $gitRepoPath/xcb-util-xrm
    git submodule update --init
    ./autogen.sh --prefix=/usr --libdir=/usr/lib64
    make
    sudo make install

    git clone https://www.github.com/Airblader/i3 $gitRepoPath/i3-gaps
    cd $gitRepoPath/i3-gaps
    mkdir -p build && cd build
    meson ..
    ninja
    sudo make install

    git clone https://github.com/i3/i3status.git $gitRepoPath/i3status
    cd $gitRepoPath/i3status
    autoreconf -fi
    mkdir -p build && cd build
    ../configure --disable-sanitizers
    make -j$(nproc)
    sudo make install

    git clone https://github.com/vivien/i3blocks $gitRepoPath/i3blocks
    cd $gitRepoPath/i3blocks
    ./autogen.sh
    ./configure
    make
    make install

    cd $here
}

gitInstall()
{
    app=$1
    repo=$2
    tmp=$(which $app > /dev/null 2>&1)
    if [ $? -ne 0 ] && [ ! -d ~/.$app ]; then
        git clone --depth 1 $repo ~/.$app | tee -a $logfile
        cd ~/.$app
        if [ -f configure ]; then
            ./configure | tee -a $logfile
        fi
        if [ -f install ]; then
            ./install | tee -a $logfile
        elif [ -f makefile ] || [ -f Makefile ]; then
            make | tee -a $logfile
            sudo make install | tee -a $logfile
        fi
        cd $here
    else
        echo "$app already installed, skipping"
    fi
}

installAppList()
{
    total=$(wc -l < $appsFile)
    n=0
    while IFS=, read -r appType app manDot description gitRepo wgetRepo; do
        if [ $n -gt 0 ]; then # ignore top row of csv
            case $appType in
                A ) # install all distros
                    if [ $installApps -eq 1 ]; then
                        echo "sudo $tool $installArgs $app"
                        sudo $tool $installArgs $app | tee -a $logfile
                    fi
                    ;;
                C ) # install all centos apps
                    if [ $installApps -eq 1 ] && [ $centos -eq 1 ]; then
                        sudo $tool $installArgs $app | tee -a $logfile
                    fi
                    ;;
                RC) # uninstall centos app
                    if [ $installApps -eq 1 ] && [ $centos -eq 1 ]; then
                        sudo $tool $uninstallArgs $app | tee -a $logfile
                    fi
                    ;;
                U ) # install all ubuntu/debian apps
                    if [ $installApps -eq 1 ] && [ $debian -eq 1 ]; then
                        sudo $tool $installArgs $app | tee -a $logfile
                    fi
                    ;;
                X ) # install all arch apps
                    if [ $installApps -eq 1 ] && [ $arch -eq 1 ]; then
                        sudo $tool $installArgs $app | tee -a $logfile
                    fi
                    ;;
                AUR ) # install arch aur apps using paru
                    if [ $installAUR -eq 1 ] ; then
                        if [ $aurinit -eq 0 ]; then
                            # https://github.com/Morganamilo/paru
                            tmp=$(which paru > /dev/null 2>&1)
                            if [ $? -ne 0 ]; then
                                sudo $tool $installArgs --needed base-devel
                                if [ ! -d $gitRepoPath ]; then
                                    mkdir -pv $gitRepoPath
                                fi
                                git clone https://aur.archlinux.org/paru.git $gitRepoPath/paru
                                cd $gitRepoPath/paru
                                makepkg -si --skippgpcheck --needed --noconfirm --noprogressbar | tee -a $logfile
                                cd $here
                            fi
                            aurinit=1
                        fi
                        paru $installArgs $app
                    fi
                    ;;
                P ) # python pip
                    if [ $installPip -eq 1 ]; then
                        if [ $pipInit -eq 0 ]; then
                            tmp=$(which pip > /dev/null 2>&1)
                            if [ $? -ne 0 ]; then
                                sudo $tool $installArgs pip | tee -a $logfile
                            fi
                            echon "Updating PIP"
                            sudo python3 -m pip install --upgrade pip | tee -a $logfile
                            pipInit=1
                        fi
                        pip install -U $app | tee -a $logfile
                    fi
                    ;;
                GP ) # append group list, dont add now wait for everything to be installed, just aggregate
                    groups[${#groups[@]}]=$app
                    ;;
                G ) # TODO git repo
                    if [ $gitinstall -eq 1 ]; then
                        gitInstall $app $gitRepo
                    fi
                    if [ $wgetinstall -eq 1 ]; then
                        echo "todo"
                    fi
                    ;;
                * )
                    ;;
            esac
        fi
        n=$((n+1))
    done < $appsFile
}

backup ()
{
    backupdir=$here/backup
    overwrite=0
    if [ -d $backupdir ]; then
        read -r -p "Overwrite current contents of $backupdir ? [y/n] : " response
        case "$response" in
            [yY][eE][sS]|[yY])
                echon "OVERWRITING CURRENT CONTENTS OF $backupdir"
                overwrite=1
                ;;
            *)
                return
                overwrite=0
                ;;
        esac
    fi
    echon "Backing up current existing dot files to $backupdir ..."
    cd files
    all=$(find . -maxdepth 100 -type f -not -path '/*\.*' | sort)
    if [ ! -d $here/backup ]; then
        mkdir $here/backup
    fi
    if [ $overwrite -eq 1 ]; then
        for i in $all; do
            cp --verbose --parents $i $here/backup | tee -a $logfile
        done
    fi
    cd $here
}

addGroup()
{
    user=$(whoami)
    # check to see if the group exists first
    getent group | grep $1 > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echon "adding user $user to $1 ..."
        sudo usermod -a -G $1 $user
    else
        echon "group $1 does not exist, ignoring ..."
    fi
}

install_cinnamon()
{
    read -r -p "Install Cinnamon Desktop? [y/n] : " response
    case "$response" in
        [yY][eE][sS]|[yY])
            echon "Installing Cinnamon Desktop"
            ;;
        *)
            echon "NOT Installing Cinnamon Desktop"
            return 0
            ;;
    esac

    if [ $centos -eq 1 ]; then
        sudo $tool groupinstall "Server with GUI" -y
    fi
    sudo $tool $installArgs cinnamon
}

################################################################################
# start main
################################################################################
if [ ! -f $logfile ]; then
    touch $logfile
fi
echon "$0 ran @ $(date)..."

################################################################################
# get linux distro
################################################################################
tmp=$(which apt-get > /dev/null 2>&1)
if [ $? -eq 0 ]; then
    distro="debian"
    debian=1
    tool="apt-get"
    installArgs="install -y"
fi

tmp=$(which yum > /dev/null 2>&1)
if [ $? -eq 0 ]; then
    distro="centos"
    centos=1
    tool="yum"
    installArgs="install -y --nogpgcheck --skip-broken"
    uninstallArgs="uninstall -y"
fi

tmp=$(which pacman > /dev/null 2>&1)
if [ $? -eq 0 ]; then
    distro="arch"
    arch=1
    tool="pacman"
    installArgs="-Sy --noconfirm --needed --noprogressbar"
fi

if [ $arch -eq 0 ] && [ $centos -eq 0 ] && [ $debian -eq 0 ]; then
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

read -r -p "Install packages with $tool (tag(s) A|C|U|X from $appsFile) ? [y/n] : " response
case "$response" in
    [yY][eE][sS]|[yY])
        echon "installing and updating apps with $tool ..."
        installApps=1
        if [ $centos -eq 1 ] || [ $debian -eq 1 ]; then
            sudo $tool update --skip-broken -y | tee -a $logfile
            sudo $tool upgrade --skip-broken -y | tee -a $logfile
        fi
        if [ $arch -eq 1 ]; then
            sudo pacman -Syu --noconfirm --needed --noprogressbar | tee -a $logfile
        fi
        ;;
    *)
        echon "NOT installing and updating apps with $tool ..."
        ;;
esac

################################################################################
# Install git apps
################################################################################
read -r -p "Install GIT based Applications (tag G from $appsFile) ? [y/n] : " response
case "$response" in
    [yY][eE][sS]|[yY])
        read -r -p "Source build files from Git [g] or Wget [w] [g/w] : " response
        case "$response" in
            [gG])
                gitinstall=1
                ;;
            [wW])
                wgetinstall=1
                ;;
            *)
                echo "Invalid response $response not installing these applications"
                ;;
        esac
        ;;
    *)
        echon "NOT installing git applications ..."
        ;;
esac

################################################################################
# Install python packages
################################################################################
read -r -p "Install python 3 PIP packages (tag P from $appsFile) ? [y/n] : " response
case "$response" in
    [yY][eE][sS]|[yY])
        installPip=1
        ;;
    *)
        echon "NOT Installing PIP packages"
        ;;
esac

################################################################################
# install all arch AUR apps
################################################################################
if [ $arch -eq 1 ]; then
    read -r -p "Install AUR packages (tag AUR from $appsFile) ? [y/n] : " response
    case "$response" in
        [yY][eE][sS]|[yY])
            installAUR=1
            ;;
        *)
            echon "NOT Installing ARCH AUR packages"
            ;;
    esac
fi

################################################################################
# Actually install everything
################################################################################
echon "Installing Applications"
installAppList
install_cinnamon
if [ $centos -eq 1 ]; then
    installCentosI3
fi

################################################################################
# update dotfiles if RCM was installed
################################################################################
read -r -p "Replace local dotfiles? (current versions will be backed up) [y/n] : " response
case "$response" in
[yY][eE][sS]|[yY])
    installDotfiles=1
    backup
    echon "updating dotfiles ..."
    tmp=$(which rcup > /dev/null 2>&1)
    if [ $? -eq 1 ]; then
        installRcm
    fi
    rcup -v -d $here/files/rcrc | tee -a $logfile
    source ~/.rcrc
    rcup -v -d $here/files | tee -a $logfile
    source ~/.bashrc
    if [ $arch -eq 1 ]; then
        rcup -v -d $here/arch-files | tee -a $logfile
        sudo sed -i "s/^#VerbosePkgLists$/VerbosePkgLists/" /etc/pacman.conf
        sudo sed -i "s/^#Color$/Color/" /etc/pacman.conf
        # use this for i3 so we can share the .conf across multiple OS'
        if [ ! -f /usr/bin/urxvt256c ]; then
            sudo ln -s /usr/bin/urxvt /usr/bin/urxvt256c
        fi
    fi
    sudo sed -i "s/-j2/-j$(nproc)/;s/^#MAKEFLAGS/MAKEFLAGS/" /etc/makepkg.conf
    ###################################
    # install vim dotfiles and packages
    ###################################
    tmp=$(which vim > /dev/null 2>&1)
    if [ $? -eq 0 ]; then
        echon "installing vim settings ... "
        vim -c 'PlugClean' +qa
        vim -c 'PlugInstall' +qa
        vim ~/.vim/vbas/Align.vba 'source %' +qa
    fi
    tmp=$(which texhash > /dev/null 2>&1)
    if [ $? -eq 0 ]; then
        echon "Running texhash"
        texhash ~/texmf
    fi
    ;;
*)
    echon "NOT replacing dotfiles"
    ;;
esac

################################################################################
# Add user to groups
################################################################################
tmp="${groups[@]}"
read -r -p "Add $(whoami) to groups : < $tmp > [y/n] : " response
case "$response" in
    [yY][eE][sS]|[yY])
        echon "Adding $(whoami) to groups..."
        for i in ${groups[@]}; do
            addGroup $i
        done
        ;;
    *)
        echon "NOT adding $(whoami) to groups < $tmp >"
        ;;
esac

################################################################################
# Kill the arch beeps
################################################################################
if [ $arch -eq 1 ]; then
    tmp=$(grep "blacklist pcspkr" /etc/modprobe.d/nobeep.conf > /dev/null 2>&1)
    if [ $? -ne 0 ]; then
        read -r -p "Disable system beeps ? [y/n] : " response
        case "$response" in
            [yY][eE][sS]|[yY])
                echon "Disabling system beeps"
                lsmod | grep pcspkr && sudo rmmod pcspkr
                sudo echo "blacklist pcspkr" | sudo tee /etc/modprobe.d/nobeep.conf
                ;;
            *)
                echon "NOT Disabling system beeps"
                ;;
        esac
    fi
fi

################################################################################
# Get rid of my name from anywhere it doesnt belong
################################################################################
if [ $installDotfiles -eq 1 ]; then
    read -r -p "Modify .gitconfig default name and email ? [y/n] : " response
    case "$response" in
        [yY][eE][sS]|[yY])
            overrideDotfiles
            ;;
        *)
            ;;
    esac
fi

################################################################################
# Enable GNOME Display Manager for Arch if it isnt already
################################################################################
if [ $arch -eq 1 ]; then
    systemctl is-enabled gdm > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        systemctl enable gdm
        echon "GNOME Display Manager Enabled, reboot to load into GNOME/Cinnamon"
    fi
fi

################################################################################
# clean up
################################################################################
read -r -p "Clean unused packages ($tool autoremove)? [y/n] : " response
case "$response" in
    [yY][eE][sS]|[yY])
        sudo $tool autoremove -y | tee -a $logfile
        if [ $arch -eq 1 ]; then
            sudo $tool --clean --sync --noconfirm --noprogressbar | tee -a $logfile
        fi
        ;;
    *)
        echon "NOT cleaning packages"
        ;;
esac
