#!/bin/bash
rcup -v -d ./files
if [ -d vim-plugged ]; then
    rcup -v -d ./vim-plugged
fi
