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

  * Arch

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

        "Type","Package type: pkg, arch, aur, pip, group, git"
        "Application","Logical application name"
        "Arch","Package name for pacman (or n/a if not available)"
        "Debian","Package name for apt (or n/a if not available)"
        "Homebrew","Package name for brew (or n/a if not available)"
        "ManagedDotfile","Y if dotfiles are managed, N otherwise"
        "Description","Description of the package"
        "Repository","Git repository URL (for git type packages)"

Package types:

.. csv-table::
        :header: "Type","Description"

        "pkg","Regular package available on multiple platforms"
        "arch","Arch Linux specific package"
        "aur","Arch User Repository package"
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

XPS 13
======

Notes specific to `XPS13 laptop setup with Arch <./xps13.rst>`_.

Dual Boot with Windows 10
=========================

Hardrive Partition Scheme example ::

    $ fdisk -l
    Device         Start       End   Sectors  Size Type                          Comment
    /dev/sda1       2048   1581055   1579008  771M EFI System                    FAT32 Make at least 500 MB
    /dev/sda2    1581056   1613823     32768   16M Microsoft basic data
    /dev/sda3    1613824 150919167 149305344 71.2G Microsoft basic data          NTFS Windows installation path
    /dev/sda4  150919168 490692607 339773440  162G Linux filesystem              ARCH Installatin ext4
    /dev/sda5  490692608 499081215   8388608    4G Linux filesystem              Swap
    /dev/sda6  499081216 500115455   1034240  505M Windows recovery environment  Created by Windows automatically

    $ lsblk
    NAME   MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
    sda      8:0    0 238.5G  0 disk
    ├─sda1   8:1    0   771M  0 part /boot
    ├─sda2   8:2    0    16M  0 part
    ├─sda3   8:3    0  71.2G  0 part
    ├─sda4   8:4    0   162G  0 part /
    ├─sda5   8:5    0     4G  0 part [SWAP]
    └─sda6   8:6    0   505M  0 part

Install Windows before Arch pointing to /dev/sdx3 for the installation directory.

Notes on Installing Arch (general)
==================================

Follow the `official Arch Installation Guide <https://wiki.archlinux.org/title/installation_guide>`_ these are just things that made it easier for me covering missing or ambiguous parts of the installation guide.

Bring up network
----------------

Connect with ``iwctl`` ::

    [iwd]# station device scan
    [iwd]# station device get-networks
    [iwd]# station device connect SSID

Pacstrap
--------

Always seem to run into a keyring issue when performing ``pacstrap``. This is resolved by running the following before the ``pacstrap`` command, ::

    pacman-key --init
    pacman-key --populate archlinux

After performing ``arch-chroot`` install, ::

    pacman -Sy networkmanager git vi vim sudo which

Add User
--------
::

    useradd user-name
    passwd user-name
    usermod -aG wheel user-name
    mkdir /home/user-name
    chown user-name:user-name /home/user-name

rEFIND Setup
------------

When setting up with ``refind-install --usedefault /dev/sdaX`` and ``mkrlconf``.

Default file ``/boot/refind_linux.conf`` will be autopopulated incorrectly... Use ``blkid`` to get the correct UUID/PARTUUID values, ::

    "Boot using default options" "root=PARTUUID=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX rw add_efi_memmap"

    "Boot using fallback initramfs" "root=PARTUUID=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX rw add_efi_memmap initrd=/boot/initramfs-%v-fallback.img"

    "Boot to terminal" "root=PARTUUID=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX rw add_efi_memmap systemd.unit=multi-user.target"

To add BIOS entry add the rEFIND boot option @ ::

    FSx/EFI/Boot/BOOTX64.EFI

First bootup
------------

Enable root privileges with wheel group using ``visudo`` un-commenting ::

    %wheel ALL=(ALL:ALL) ALL

Enable wifi ::

    systemctl enable NetworkManager
    systemctl start NetworkManager
    nmtui

Run this bootstrap ::

    git clone https://github.com/gutelfuldead/dotfiles.git ~/.dotfiles
    cd ~/.dotfiles
    ./install.sh

To use the rEFIND theme pull the submodule and see the ``README.rst`` in there ::

    git submodule init
    git submodule update
