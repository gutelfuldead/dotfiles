#!/bin/bash
rcup -v -d ./files
if [ -d smi-files ]; then
    rcup -v -d ./smi-files
    chmod go-w ~/.ssh/config # otherwise ssh wont read the file
fi
