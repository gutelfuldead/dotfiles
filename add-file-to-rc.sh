#!/bin/bash
if [ $# -ne 1 ] || [ ! -f $1 ]; then
    echo "Usage :"
    echo " $0 <file to add to ./files in rf>"
    exit 1
fi

mkrc -v -d files $1
