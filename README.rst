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

Debian installation ::

	wget -qO - https://apt.thoughtbot.com/thoughtbot.gpg.key | sudo apt-key add -
	echo "deb https://apt.thoughtbot.com/debian/ stable main" | sudo tee
	/etc/apt/sources.list.d/thoughtbot.list
	sudo apt-get update
	sudo apt-get install rcm

Other Apps needed for these dotfiles ::

	sudo apt install vim \
		rst2pdf \
		ctags \
		terminator

Install dotfiles
================

Point to repo and use ``rcup`` ::

	rcup -v -d ~/.dotfiles

Use RCM
=======

`Decent Guide <https://distrotube.com/blog/rcm-guide/>`_

`manpage <http://thoughtbot.github.io/rcm/rcm.7.html>`_

Add new file to rcm control ::

	mkrc -v ~/.thisfile

Will copy file to local ~/.dotfiles (which should be this repo)

View all symlinks ::

	lsrc

Update all symlinks ::

	rcup

Vim Setup
=========

Vim requires a few extra steps after it the dotfiles are updated.

Install Packages
----------------

#. Open vim and install packages with ``:PlugInstall``

#. open ~/.vim/vbas/Align.vba in vim and run ``:source %``

