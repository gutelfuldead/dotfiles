======================
Gutelfuldead Dot Files
======================

Manage dotfiles for the following packages (installed as part of script),

- fzf
- rcm
- vim
- ctags
- terminator
- rst2pdf
- rst2html (docutils)
- tmux
- lynx

Also manages bashrc

The bashrc used sets up common aliases. Will also source local files on a
machine under `~/.bash_aliases`


Installation
============

The installation script works on Ubuntu and Centos ::

        ./install.sh

If using this installs script then the following packages will be installed,

- tree
- make
- cmake
- meld
- curl
- pinta
- wireshark
- htop
- bison
- flex
- sshfs
- feh
- ccrypt
- vim
- rst2pdf
- $docutils
- ctags
- terminator
- tmux
- lynx

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

Will copy file to local /path/to/this/repo/dotfiles/files (which should be this repo)

View all symlinks ::

        lsrc

Update all symlinks ::

        rcup

