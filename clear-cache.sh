#!/usr/bin/env bash

COMMAND='find . -type d -name ".terragrunt-cache" -prune -exec rm -rf {} \;'
find `pwd` -iname ".terragrunt-cache" -printf "%h\n" | sort -u | while read i; do
    cd "$i" && pwd && $COMMAND
done