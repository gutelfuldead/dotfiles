#!/bin/bash
#  _               _
# | |__   __ _ ___| |__  _ __ ___
# | '_ \ / _` / __| '_ \| '__/ __|
# | |_) | (_| \__ \ | | | | | (__
# |_.__/ \__,_|___/_| |_|_|  \___|

if [ "`id -u`" -eq 0 ]; then
	PS1="[ \[\e[1;31m\]λ\[\e[1;32m\]\[\e[49m\]:\h \W \[\e[0m\]] "
else
	PS1="[ \[\e[1;32m\]λ:\h \W \[\e[0m\]] "
fi

# Some aliases
alias kvivado='kill $(pidof vivado)'
alias mkd="mkdir -pv"
alias pdf='okular'

# Adding color
alias ls='ls -hN --color=auto --group-directories-first'
alias l='ls -hN --color=auto --group-directories-first'
alias ll='ls -lahN --color=auto --group-directories-first'
alias grep='grep --color=auto --exclude=tags --exclude-dir=".svn" --exclude-dir=".git" --line-number'
alias ccat="highlight --out-format=ansi" # Color cat - print file with syntax highlighting.

# Internet
alias yt="youtube-dl --add-metadata -ic" # Download video link
alias ethspeed="speedometer -r enp12s0"
alias wifispeed="speedometer -r wlp3s0"

# Set path
export stand_path=/bin:/usr/bin:/usr/local/sbin:/usr/local/bin
export other_progs=

export PATH=$PATH:$stand_path:$other_progs

if [ -f ~/.bash_extended ]; then
	source ~/.bash_extended
fi
