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

  * Anything that would be replaced is first backed up in ``$(pwd)/backup``
    maintaining folder hierarchy

  * ``~/.bashrc`` sources a user generated local ``~/.bash_aliases`` file for anything
    machine specific that doesn't belong in a common ``~/.bashrc`` like ``cd``
    aliases, license server environment variables, etc.

* Updates VIM environment

* Adds user to groups required by apps

* Installs Cinnamon Desktop

XPS13
=====

Notes specific to `XPS13 laptop setup with ARCH <./xps13.rst>`_...

Packages
========

Full list of packages by distribution `apps.csv <./apps.csv>`_.

First column (AppType) uses key,

.. csv-table::
        :header: "Key","Descrption"

        "A","Common package for All distributions"
        "C","CentOS only package (uses yum)"
        "U","Ubuntu/Debian only package (uses apt)"
        "X","Arch only package (uses pacman)"
        "AUR","Arch User Repository Package"
        "P","Python package uses pip2/pip3"
        "G","Git build with make/configure"

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
