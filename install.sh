#!/bin/bash
here=$(pwd)
appsFile=$here/apps.csv
logfile=$here/install.log
tmpApplist=
archAurRepos=()

# groups to add the user to
groups=(wheel dialout libvirt vboxusers wireshark)

echon ()
{
    echo -e "\n################################################################################" | tee -a $logfile
    echo -e "$1" | tee -a $logfile
    echo -e "################################################################################\n" | tee -a $logfile
    sleep 1
}

getApps () {
    total=$(wc -l < $appsFile)
    d=$1
    tmpApplist=""
    n=0
    while IFS=, read -r appType app manDot description gitRepo wgetRepo; do
        if [ $n -gt 0 ]; then
            if [ $d == "$appType" ]; then
                if [ $d == "AUR" ]; then
                    archAurRepos[${#archAurRepos[@]}]=$gitRepo
                else
                    tmpApplist+=" "$app
                fi
            fi
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

archAurInstall() {
    here=$(pwd)
    gr=$here/archAurPkgs
    repos=$1

    echon "Installing ARCH AUR Repos..."

    # create directory for repos
    if [ ! -d $gr ]; then
        mkdir $gr
    fi
    cd $gr

    # clone all the repos
    for i in ${repos[@]}; do
        git clone $i | tee -a $logfile
    done

    # go in each one and install it
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

# TODO need to automate this with progs.csv
non_pacman_apps () {
    use_git=0
    nonpacmanapps="fzf rcm ranger"
    read -r -p "Install non-pacman < $nonpacmanapps > apps from git/wget tars? [y/n] : " response
    case "$response" in
        [yY][eE][sS]|[yY])
            echon "Installing non package manager apps"
            ;;
        *)
            echon "NOT Installing non package manager apps"
            return 0
            ;;
    esac

    ################################################################################
    # install non-pacman apps option
    ################################################################################
    read -r -p "use git to source latest builds? If not tarballs will be used [y/n] : " response
    case "$response" in
        [yY][eE][sS]|[yY])
            echon "Using GIT to source non package manager apps"
            use_git=1
            ;;
        *)
            echon "Using wget and tarballs to source non package manager apps"
            use_git=0
            ;;
    esac

    ################################################################################
    # fzf
    ################################################################################
    tmp=$(which fzf > /dev/null 2>&1)
    if [ $? -ne 0 ]; then
        if [ $arch -eq 1 ]; then
            sudo pacman -S fzf
        else
            echon "installing fzf ..."
            if [ $use_git -eq 1 ]; then
                git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf | tee -a $logfile
                ~/.fzf/install | tee -a $logfile
            else
                mkdir -pv ~/.fzf
                cd ~/.fzf
                curl -LO https://github.com/junegunn/fzf/archive/0.21.1.zip | tee -a $logfile
                unzip 0.21.1.zip | tee -a $logfile
                ./fzf-0.21.1/install | tee -a $logfile
            fi
            cd $here
        fi
    fi

    ################################################################################
    # rcm
    ################################################################################
    tmp=$(which rcup > /dev/null 2>&1)
    if [ $? -ne 0 ]; then
        echon "installing rcm ..."
        if [ $debian -eq 1 ]; then
            wget -qO - https://apt.thoughtbot.com/thoughtbot.gpg.key | sudo apt-key add - | tee -a $logfile
            echo "deb https://apt.thoughtbot.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/thoughtbot.list | tee -a $logfile
            sudo apt-get update | tee -a $logfile
            sudo apt-get install rcm | tee -a $logfile
        else
            mkdir -p ~/.rcm
            cd ~/.rcm
            curl -LO https://thoughtbot.github.io/rcm/dist/rcm-1.3.3.tar.gz | tee -a $logfile
            tar -xvf rcm-1.3.3.tar.gz | tee -a $logfile
            cd rcm-1.3.3
            ./configure | tee -a $logfile
            make | tee -a $logfile
            sudo make install | tee -a $logfile
            cd $here
        fi
    fi

    ################################################################################
    # ranger
    ################################################################################
     tmp=$(which ranger > /dev/null 2>&1)
     if [ $? -ne 0 ]; then
        echon "installing ranger ..."
        if [ $use_git -eq 1 ]; then
            git clone git@github.com:ranger/ranger.git ~/.ranger | tee -a $logfile
            sudo make -C ~/.ranger install | tee -a $logfile
        else
            mkdir -p ~/.ranger
            cd ~/.ranger
            curl -LO https://github.com/ranger/ranger/archive/v1.9.3.zip | tee -a $logfile
            unzip v1.9.3.zip | tee -a $logfile
            cd ranger-1.9.3
        fi
        sudo make install | tee -a $logfile
        cd $here
     fi
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

    if [ $tool == "yum" ]; then
        sudo $tool groupinstall "Server with GUI" -y
        sudo $tool install -y cinnamon
    elif [ $tool == "apt" ]; then
        sudo $tool install -y cinnamon
    elif [ $tool == "pacman" ]; then
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
distro=""
tool=""
debian=0
centos=0
arch=0
getApps A
applist=$tmpApplist
tmp=$(which apt > /dev/null 2>&1)
if [ $? -eq 0 ]; then
    distro="debian"
    getApps U
    debian=1
    tool="apt"
    toolArgs=""
fi

tmp=$(which yum > /dev/null 2>&1)
if [ $? -eq 0 ]; then
    distro="centos"
    getApps C
    centos=1
    tool="yum"
    toolArgs="--nogpgcheck --skip-broken"
fi

tmp=$(which pacman > /dev/null 2>&1)
if [ $? -eq 0 ]; then
    distro="arch"
    getApps X
    arch=1
    tool="pacman"
    toolArgs=""
fi
applist+=$tmpApplist

if [ $distro == "" ]; then
    echon "unknown distro"
    exit 1
fi

################################################################################
# install pacman apps
################################################################################
echon "Setup for $distro ..."
echon "packages to install : < $applist >"

installPacman=0
read -r -p "Install packages with $tool? [y/n] : " response
case "$response" in
    [yY][eE][sS]|[yY])
        echon "installing and updating apps with $tool ..."
        installPacman=1
        ;;
    *)
        echon "NOT installing and updating apps with $tool ..."
        ;;
esac

if [ $installPacman -eq 1 ]; then
    if [ $arch -eq 1 ]; then
        sudo pacman $toolArgs -S $applist | tee -a $logfile
    elif [ $debian -eq 1 ]; then
        sudo $tool update -y | tee -a $logfile
        sudo $tool upgrade -y | tee -a $logfile
        sudo $tool install $toolArgs -y $applist | tee -a $logfile
    elif [ $centos -eq 1 ]; then
        sudo $tool install epel-release -y | tee -a $logfile
        sudo $tool update -y | tee -a $logfile
        sudo $tool upgrade -y | tee -a $logfile
        sudo $tool $toolArgs install -y $applist | tee -a $logfile
    else
        exit 1
    fi
fi

install_cinnamon

################################################################################
# Install non package manager apps
################################################################################
non_pacman_apps

################################################################################
# Install python packages
################################################################################
getApps P
pipPackages=$tmpApplist
read -r -p "Install python 2/3 PIP packages $pipPackages? [y/n] : " response
case "$response" in
    [yY][eE][sS]|[yY])
        sudo pip2 install --upgrade pip
        sudo pip3 install --upgrade pip
        sudo pip2 install -U $pipPackages
        sudo pip3 install -U $pipPackages
        ;;
    *)
        echon "NOT Installing PIP packages"
        ;;
esac

################################################################################
# install all arch AUR apps
################################################################################
if [ $arch -eq 1 ]; then
    getApps AUR
    read -r -p "Install AUR packages $archAurRepos ? [y/n] : " response
    case "$response" in
        [yY][eE][sS]|[yY])
            echon "Installing ARCH AUR packages"
            archAurInstall $archAurRepos
            ;;
        *)
            echon "NOT Installing ARCH AUR packages"
            ;;
    esac
fi

################################################################################
# update dotfiles if RCM was installed
################################################################################
source ~/.bashrc
tmp=$(which rcm > /dev/null 2>&1)
if [ $? -eq 1 ]; then
    read -r -p "Replace local dotfiles? (current versions will be backed up) [y/n] : " response
    case "$response" in
        [yY][eE][sS]|[yY])
            backup
            echon "updating dotfiles ..."
            rcup -v -d $here/files | tee -a $logfile
            source ~/.bashrc
            ###################################
            # install vim dotfiles and packages
            ###################################
            echon "installing vim settings ... "
            vim -c 'PlugClean' +qa
            vim -c 'PlugInstall' +qa
            vim ~/.vim/vbas/Align.vba 'source %' +qa
            ;;
        *)
            echon "NOT replacing dotfiles"
            ;;
    esac
else
    echon "RCM was not installed, not updating dotfiles"
fi

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
# clean up
################################################################################
read -r -p "Clean unused packages ($tool autoremove)? [y/n] : " response
case "$response" in
    [yY][eE][sS]|[yY])
        sudo $tool autoremove
        ;;
    *)
        echon "NOT cleaning packages"
        ;;
esac
