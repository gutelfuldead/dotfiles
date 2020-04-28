======================
Gutelfuldead Dot Files
======================

Probably best to checkout to ~/.dotfiles

Manage dotfiles for the following packages,

- vim
- ctags
- terminator
- rst2pdf
- rst2html
- ranger
- tmux

Also manages bashrc

The bashrc used sets up common aliases. Will also source local files on a
machine under `~/.bash_aliases`

Installation of RCM and other apps
==================================

Use `RCM <https://github.com/thoughtbot/rcm>`_ to manage symlinks and installation.

source installation (tested on debian/redhat/WSL) ::

        mkdir ./rcm
        cd ./rcm
        curl -LO https://thoughtbot.github.io/rcm/dist/rcm-1.3.3.tar.gz &&
        tar -xvf rcm-1.3.3.tar.gz &&
        cd rcm-1.3.3 &&
        ./configure &&
        make &&
        sudo make install
        cd ..

Other Apps needed for these dotfiles ::

        sudo apt install vim \
                rst2pdf \
                docutils-common \
                ctags \
                terminator \
                tmux

Install dotfiles
================

Point to repo and use ``rcup`` ::

        rcup -v -d ./files

Vim Setup
=========

#. ``vim .`` and install packages with ``:PlugInstall``

#. ``vim ~/.vim/vbas/Align.vba`` and run ``:source %``

Use RCM
=======

`Decent Guide <https://distrotube.com/blog/rcm-guide/>`_

`manish page <http://thoughtbot.github.io/rcm/rcm.7.html>`_

Add new file to rcm control ::

        mkrc -v -d /path/to/this/repo/dotfiles/files ~/.thisfile

Will copy file to local /path/to/this/repo/dotfiles/files (which should be this repo)

View all symlinks ::

        lsrc

Update all symlinks ::

        rcup

