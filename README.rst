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

  * Ubuntu

  * CentOS

  * Arch

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

First column (AppType) uses key,

.. csv-table::
        :header: "Key","Descrption"

        "A","Common package for All distributions"
        "C","CentOS only package (uses yum)"
        "U","Ubuntu/Debian only package (uses apt)"
        "X","Arch only package (uses pacman)"
        "AUR","Arch User Repository Package"
        "P","Python package uses pip2/pip3, ensure these occur AFTER the local
        python-pip installations using the package manager"
        "G","Git build with make/configure"
        "GP","Group to add user to (if it exists on the system)"
        "RC","Remove CentOS package from base distro install"
        "S","Snap packages"

Just install dotfiles
=====================

Install rcm ::

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

`Decent Guide <https://thoughtbot.com/blog/rcm-for-rc-files-in-dotfiles-repos>`_

`man page <http://thoughtbot.github.io/rcm/rcm.7.html>`_

Add new file to rcm control ::

        mkrc -v -d /path/to/this/repo/dotfiles/files ~/.thisfile

Will copy file to local /path/to/this/repo/dotfiles/files

View all symlinks ::

        lsrc

Update all symlinks ::

        rcup

XPS 13
======

Notes specific to `XPS13 laptop setup with Arch <./xps13.rst>`_.

Notes on Installing Arch (general)
==================================

Bring up network
----------------

edit ``/etc/iwd/main.conf``, ::

    [General]
    EnableNetworkConfiguration=true

Connect with ``iwctl`` ::

    [iwd]# station device scan
    [iwd]# station device get-networks
    [iwd]# station device connect SSID

Pacstrap
--------

Always seem to run into a keyring issue when performing ``pacstrap``. This is resolved by running the following before the ``pacstrap`` command, ::

    pacman-key --populate archlinux

After performing ``arch-chroot`` install, ::

    pacman -Sy networkmanager git vim sudo which

After finishing installation and booting into image and enable wheel group with sudo privileges ``EDITOR=vim && visudo`` to use the script which requires sudo.

rEFIND Setup
------------

When setting up with ``refind-install --usedefault /dev/sdaX`` and ``mkrlconf``.

Default file ``/boot/refind_linux.conf`` will be autopopulated incorrectly... Use ``blkid`` to get the correct UUID/PARTUUID values, ::

    "Boot using default options" "root=PARTUUID=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX rw add_efi_memmap"

    "Boot using fallback initramfs" "root=PARTUUID=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX rw add_efi_memmap initrd=/boot/initramfs-%v-fallback.img"

    "Boot to terminal" "root=PARTUUID=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX rw add_efi_memmap systemd.unit=multi-user.target"

TODO
====
