#!/usr/bin/env bash

for NIXPKGS_BRANCH in trunk staging-next; do
    export NIXPKGS_BRANCH
    if type -a collect.sh; then
        collect.sh
    else
        ./collect.sh
    fi
done
