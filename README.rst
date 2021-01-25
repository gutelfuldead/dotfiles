======================
Gutelfuldead Dot Files
======================

.. contents:: Table of Contents
.. section-numbering::

About
=====

More of a new system setup. Will do the following with a confirmation [y/n]
prompt first,

* Installs applications

  * Ubuntu

  * CentOS

  * Arch

* Updates all dotfiles

  * Anything that would be replaced is first backed up in ${pwd}/backup

  * ``~/.bashrc`` sources a user generated local ``~/.bash_aliases`` file for anything
    that doesn't belong in a common ``~/.bashrc``

* Updates vim environment

* Adds user to groups required by apps

* Installs Cinnamon Desktop

Packages
========

Full list of packages by distribution `progs.csv <./progs.csv>`_.

Installation
============

The installation script works on Arch, Ubuntu, and Centos ::

        ./install.sh

Otherwise just install rcm ::

        here=$(pwd) &&
        mkdir ~/.rcm &&
        cd ~/.rcm &&
        curl -LO https://thoughtbot.github.io/rcm/dist/rcm-1.3.3.tar.gz &&
        tar -xvf rcm-1.3.3.tar.gz &&
        cd rcm-1.3.3 &&
        ./configure &&
        make &&
        sudo make install &&
        cd $here

and manually add dotfiles ::

        rcup -v -d ./files

Use RCM
=======

`Decent Guide <https://distrotube.com/blog/rcm-guide/>`_

`manish page <http://thoughtbot.github.io/rcm/rcm.7.html>`_

Add new file to rcm control ::

        mkrc -v -d /path/to/this/repo/dotfiles/files ~/.thisfile

Will copy file to local /path/to/this/repo/dotfiles/files

View all symlinks ::

        lsrc

Update all symlinks ::

        rcup
