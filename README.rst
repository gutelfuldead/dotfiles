======================
Gutelfuldead Dot Files
======================

Manage dotfiles for the following packages,

- fzf
- rcm
- vim
- ctags
- terminator
- rst2pdf
- rst2html (docutils)
- tmux
- lynx
- clang

Any existing dotfiles for these programs will be backed up before being
overwritten.

Also manages bashrc

Anything machine specific should be placed in `~/.bash_aliases`. The default
`~/.bashrc` will source this file.

Installation
============

The installation script works on Ubuntu and Centos ::

        ./install.sh

If using this installs script then the following packages will be installed,

- tree
- make
- cmake
- clang
- pdftk
- gcc
- gcc-c++
- meld
- xpdf
- curl
- pinta
- git
- wireshark
- htop
- bison
- dropbear
- neofetch
- flex
- ncurses-devel
- sshfs
- wine
- feh
- openssl-devel
- ccrypt
- vim
- rst2pdf
- patch
- ctags
- terminator
- kakuake
- tmux
- lynx

+ more... see the $applist variable in `install.sh`.

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
