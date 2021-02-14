#!/bin/bash
here=$(pwd)
archAurRepo=$here/archAurPkgs
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

overrideDotfiles() {
    read -r -p "Enter name : " name
    read -r -p "Enter email : " email
    sed -i "s/Jason Gutel/$name/g" ~/.gitconfig
    sed -i "s/jason.gutel@gmail.com/$email/g" ~/.gitconfig
    echon "Overriding default name and email for gitconfig with name=$name email=$email"
}

# https://github.com/thoughtbot/rcm
installRcm () {
    ver=1.3.4
    echon "Installing RCM"
    if [ ! -d ~/.rcm ]; then
        echo $here
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

gitInstall() {
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

installAppList() {
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
                AUR ) # install arch aur apps
                    if [ $installAUR -eq 1 ] ; then
                        cloneArchAurRepos $gitRepo
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
                            sudo pip install --upgrade pip
                            pipInit=1
                        fi
                        sudo pip3 install -U $app | tee -a $logfile
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
                    echo "Unknown tag $appType for application $app"
                    ;;
            esac
        fi
        n=$((n+1))
    done < $appsFile
}

backup ()
{
    here=$(pwd)
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

addGroup() {
    user=$(whoami)
    # check to see if the group exists first
    getent group | grep $1 > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echon "adding user $user to $1 ..."
        sudo usermod -a -G $1 $user
    fi
}

cloneArchAurRepos() {
    repo=$1
    # create directory for repos
    if [ ! -d $archAurRepo ]; then
        mkdir $archAurRepo
    fi
    cd $archAurRepo

    # clone all the repos
    git clone $repo | tee -a $logfile

    cd $here
}

archAurInstall() {
    if [ ! -d $archAurRepo ]; then
        return
    fi
    cd $archAurRepo

    # go in each repo and install it
    d=$(find . -maxdepth 1 -type d)
    echo $d
    init=0 # ignore the first entry which is ./
    for i in $d; do
        if [ $init -ne 0 ]; then
            cd $i
            makepkg -si --skippgpcheck | tee -a $logfile
            cd ..
        else
            let init=1
        fi
    done
    cd $here
}

install_cinnamon() {
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
        sudo $tool install -y cinnamon
    elif [ $debian -eq 1 ]; then
        sudo $tool install -y cinnamon
    elif [ $arch -eq 1 ]; then
        sudo $tool -Syu cinnamon
    fi
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
fi

tmp=$(which pacman > /dev/null 2>&1)
if [ $? -eq 0 ]; then
    distro="arch"
    arch=1
    tool="pacman"
    installArgs="-Sy --noconfirm --needed"
fi

if [ $distro == "" ]; then
    echon "unknown distro"
    exit 1
fi

################################################################################
# install pacman apps
################################################################################
echon "Setup for $distro ..."

read -r -p "Install packages from $appsFile with $tool? [y/n] : " response
case "$response" in
    [yY][eE][sS]|[yY])
        echon "installing and updating apps with $tool ..."
        installApps=1
        if [ $centos -eq 1 ] || [ $debian -eq 1 ]; then
            sudo $tool update -y | tee -a $logfile
            sudo $tool upgrade -y | tee -a $logfile
        fi
        if [ $arch -eq 1 ]; then
            sudo pacman -Syu | tee -a $logfile
        fi
        ;;
    *)
        echon "NOT installing and updating apps with $tool ..."
        ;;
esac

################################################################################
# Install git apps
################################################################################
read -r -p "Install GIT based Applications [tag G in apps.csv] from $appsFile [y/n] : " response
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
read -r -p "Install python 3 PIP packages? [y/n] : " response
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
    read -r -p "Install AUR packages ? [y/n] : " response
    case "$response" in
        [yY][eE][sS]|[yY])
            echon "Installing ARCH AUR packages"
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
installAppList
if [ $installAUR -eq 1 ] ; then
    archAurInstall
fi
install_cinnamon

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
    rcup -v -d $here/files | tee -a $logfile
    source ~/.bashrc
    if [ $arch -eq 1 ]; then
        sudo sed -i "s/^#VerbosePkgLists$/VerbosePkgLists/" /etc/pacman.conf
        sudo sed -i "s/^#Color$/Color/" /etc/pacman.conf
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
    read -r -p "Disable system beeps ? [y/n] : " response
    case "$response" in
        [yY][eE][sS]|[yY])
            echon "Disabling system beeps"
            sudo rmmod pcspkr
            echo "blacklist pcspkr" > /etc/modprobe.d/nobeep.conf
            ;;
        *)
            echon "NOT Disabling system beeps"
            ;;
    esac
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
# clean up
################################################################################
read -r -p "Clean unused packages ($tool autoremove)? [y/n] : " response
case "$response" in
    [yY][eE][sS]|[yY])
        sudo $tool autoremove
        if [ $arch -eq 1 ]; then
            sudo $tool --clean --sync
        fi
        ;;
    *)
        echon "NOT cleaning packages"
        ;;
esac
