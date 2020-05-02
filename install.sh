#!/bin/bash
here=$(pwd)
logfile=$here/install.log
rm -f $logfile
touch $logfile

echon ()
{
	echo -e "\n################################################################################" | tee -a $logfile
	echo -e "$1" | tee -a $logfile
	echo -e "################################################################################\n" | tee -a $logfile
	sleep 1
}

################################################################################
# get linux distro
################################################################################
distro=""
tool=""
tmp=$(which apt > /dev/null 2>&1)
if [ $? -eq 0 ]; then
	distro="debian"
	tool=apt
	docutils=docutils-common
fi

tmp=$(which yum > /dev/null 2>&1)
if [ $? -eq 0 ]; then
	distro="centos"
	tool=yum
	docutils=geany-plugins-geanygendoc
fi

if [ $distro == "" ]; then
	echon "unknown distro"
	exit 1
fi

read -r -p "use git to source latest builds? If not tarballs will be used [y/n] : " response
case "$response" in
	[yY][eE][sS]|[yY])
		use_git=1
	;;
	[nN][oO]|[nN])
		use_git=0
	;;
	*)
		echo "Must choose y/n..."
		exit 1
	;;
esac

echon "Installing on $distro ..."

################################################################################
# fzf
################################################################################
tmp=$(which fzf > /dev/null 2>&1)
if [ $? -ne 0 ]; then
	echon "installing fzf ..."
	if [ $use_git -eq 1 ]; then
		git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf | tee -a $logfile
		~/.fzf/install | tee -a $logfile
	else
		mkdir -pv ~/.fzf | tee -a $logfile
		cd ~/.fzf
		curl -LO https://github.com/junegunn/fzf/archive/0.21.1.zip | tee -a $logfile
		unzip 0.21.1.zip | tee -a $logfile
		./fzf-0.21.1/install | tee -a $logfile
	fi
	cd $here
fi

################################################################################
# rcm
################################################################################
tmp=$(which rcup > /dev/null 2>&1)
if [ $? -ne 0 ]; then
	echon "installing rcm ..."
	if [ $distro -eq "debian" ]; then
		wget -qO - https://apt.thoughtbot.com/thoughtbot.gpg.key | sudo apt-key add - | tee -a $logfile
		echo "deb https://apt.thoughtbot.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/thoughtbot.list | tee -a $logfile
		sudo apt-get update | tee -a $logfile
		sudo apt-get install rcm | tee -a $logfile
	else
		mkdir ~/.rcm | tee -a $logfile
		cd ~/.rcm | tee -a $logfile
		curl -LO https://thoughtbot.github.io/rcm/dist/rcm-1.3.3.tar.gz | tee -a $logfile
		tar -xvf rcm-1.3.3.tar.gz | tee -a $logfile
		cd rcm-1.3.3 | tee -a $logfile
		./configure | tee -a $logfile
		make | tee -a $logfile
		sudo make install | tee -a $logfile
		cd $here | tee -a $logfile
	fi
fi

################################################################################
# ranger
################################################################################
 tmp=$(which ranger > /dev/null 2>&1)
 if [ $? -ne 0 ]; then
	echon "installing ranger ..." | tee -a $logfile
	if [ $use_git -eq 1 ]; then
		git clone git@github.com:ranger/ranger.git ~/.ranger | tee -a $logfile
		sudo make -C ~/.ranger install | tee -a $logfile
	else
		mkdir ~/.ranger
		cd ~/.ranger
		curl -LO https://github.com/ranger/ranger/archive/v1.9.3.zip | tee -a $logfile
		unzip v1.9.3.zip | tee -a $logfile
		cd ranger-1.9.3
	fi
	sudo make install | tee -a $logfile
	cd $here
 fi

################################################################################
# install common apps
################################################################################
echon "installing apps with $tool ..."
sudo $tool install -y \
	vim \
	rst2pdf \
	$docutils \
	ctags \
	terminator \
	tmux \
	lynx \
	| tee -a $logfile

################################################################################
# update dotfiles
################################################################################
echon "updating dotfiles ..."
rcup -v -d $here/files | tee -a $logfile
source ~/.bashrc

################################################################################
# install vim plugins
################################################################################
echon "installing vim settings ... "
vim -c 'PlugClean' +qa
vim -c 'PlugInstall' +qa
vim ~/.vim/vbas/Align.vba 'source %' +qa

sudo $tool autoremove
