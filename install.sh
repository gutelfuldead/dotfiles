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
	distro="ubuntu"
	tool=apt
	docutils=docutils-common
	geany-plugins-geanygendoc \ # doc utils for centos
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

echon "Installing on $distro ..."

################################################################################
# fzf
################################################################################
tmp=$(which fzf > /dev/null 2>&1)
if [ $? -ne 0 ]; then
	echon "installing fzf ..."
	git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf | tee -a $logfile
	~/.fzf/install | tee -a $logfile
fi

################################################################################
# rcm
################################################################################
tmp=$(which rcup > /dev/null 2>&1)
if [ $? -ne 0 ]; then
	echon "installing rcm ..."
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

################################################################################
# ranger
################################################################################
# tmp=$(which ranger > /dev/null 2>&1)
# if [ $? -ne 0 ]; then
#	echon "installing ranger ..." | tee -a $logfile
#	mkdir ~/.ranger
#	cd ~/.ranger
#	curl -LO https://github.com/ranger/ranger/archive/v1.9.3.zip | tee -a $logfile
#	unzip v1.9.3.zip | tee -a $logfile
#	cd ranger-1.9.3
#	# git clone git@github.com:ranger/ranger.git ~/.ranger | tee -a $logfile
#	sudo make install | tee -a $logfile
#	cd $here
# fi

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
