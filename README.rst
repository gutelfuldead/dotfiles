=====================
Gutelfuldead DotFiles
=====================

This repo should be checked out to ~./dotfiles so... ::

	git clone https://github.com/gutelfuldead/dotfiles.git ~/.dotfiles

Packages with dotfiles
======================

Bashrc is managed as well as...

- vim
- ctags
- terminator
- rst2pdf
- rst2html
- ranger

Installation of RCM and other apps
==================================

Use `RCM <https://github.com/thoughtbot/rcm>`_ to manage symlinks and installation.

source installation ::

	mkdir ~/rcm
	cd ~/rcm
	curl -LO https://thoughtbot.github.io/rcm/dist/rcm-1.3.3.tar.gz &&
	tar -xvf rcm-1.3.3.tar.gz &&
	cd rcm-1.3.3 &&
	./configure &&
	make &&
	sudo make install

Other Apps needed for these dotfiles ::

	sudo apt install vim \
		rst2pdf \
		ctags \
		terminator

Install dotfiles
================

Point to repo and use ``rcup`` ::

	rcup -v -d ~/.dotfiles

Vim Setup
=========

#. Open vim and install packages with ``:PlugInstall``

#. open ~/.vim/vbas/Align.vba in vim and run ``:source %``

Use RCM
=======

`Decent Guide <https://distrotube.com/blog/rcm-guide/>`_

`manish page <http://thoughtbot.github.io/rcm/rcm.7.html>`_

Add new file to rcm control ::

	mkrc -v ~/.thisfile

Will copy file to local ~/.dotfiles (which should be this repo)

View all symlinks ::

	lsrc

Update all symlinks ::

	rcup

