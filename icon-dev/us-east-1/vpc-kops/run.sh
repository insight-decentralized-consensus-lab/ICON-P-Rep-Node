#!/usr/bin/env bash

find . -type d -name ".terragrunt-cache" -prune -exec rm -rf {} \;
terragrunt get -update
terragrunt init -upgrade