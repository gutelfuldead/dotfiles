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

