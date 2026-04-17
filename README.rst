======================
Gutelfuldead Dot Files
======================

.. contents:: Table of Contents
.. section-numbering::

About
=====

https://github.com/gutelfuldead/dotfiles

More of a new system setup. ``install.sh`` Will do the following with a confirmation [y/n]
prompt first,

* Installs applications

  * Ubuntu/Debian

  * macOS

  * Common Python-Pip packages

  * Common applications from Github

* Updates all dotfiles

  * Anything that would be replaced is first backed up in ``$(pwd)/backup``
    maintaining folder hierarchy

  * ``~/.bashrc`` sources a user generated local ``~/.bash_aliases`` file for anything
    machine specific that doesn't belong in a common ``~/.bashrc`` like ``cd``
    aliases, license server environment variables, etc.

* Updates VIM environment

* Adds user to groups required by apps

* Installs Cinnamon Desktop

Also has my rEFIND theme. To access pull the submodule then check the ``README.rst``, ::

    git submodule init
    git submodule update

Packages
========

Full list of packages by distribution `apps.csv <./apps.csv>`_.

The CSV format uses columns for each package manager:

.. csv-table::
        :header: "Column","Description"

        "Type","Package type: pkg, pip, group, git"
        "Application","Logical application name"
        "Debian","Package name for apt (or n/a if not available)"
        "Homebrew","Package name for brew (or n/a if not available)"
        "ManagedDotfile","Y if dotfiles are managed, N otherwise"
        "Description","Description of the package"
        "Repository","Git repository URL (for git type packages)"

Package types:

.. csv-table::
        :header: "Type","Description"

        "pkg","Regular package available on Debian and/or macOS"
        "pip","Python package installed via pip"
        "group","System group to add the user to"
        "git","Package installed from git repository"

macOS Installation
==================

On macOS, first install Homebrew if not already installed::

    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

Then run the installer::

    git clone https://github.com/gutelfuldead/dotfiles.git ~/.dotfiles
    cd ~/.dotfiles
    ./install.sh

The script will detect macOS and use Homebrew for package installation.

Note: Some Linux-specific packages (gparted, evince, remmina, Cinnamon desktop) will be skipped on macOS.

Just install dotfiles
=====================

Install rcm ::

        here=$(pwd) &&
        mkdir ~/.rcm &&
        cd ~/.rcm &&
        curl -LO https://thoughtbot.github.io/rcm/dist/rcm-1.3.4.tar.gz &&
        tar -xvf rcm-1.3.4.tar.gz &&
        cd rcm-1.3.4 &&
        ./configure &&
        make &&
        sudo make install &&
        cd $here

and manually add dotfiles ::

        rcup -v -d ./files

Use RCM
=======

`Decent Guide <https://thoughtbot.com/blog/rcm-for-rc-files-in-dotfiles-repos>`_

`man page <http://thoughtbot.github.io/rcm/rcm.7.html>`_

Add new file to rcm control ::

        mkrc -v -d /path/to/this/repo/dotfiles/files ~/.thisfile

Will copy file to local /path/to/this/repo/dotfiles/files

View all symlinks ::

        lsrc

Update all symlinks ::

        rcup

