#!/bin/bash
rcup -v -d ./files
if [ -d smi-files ]; then
    rcup -v -d ./smi-files
fi
