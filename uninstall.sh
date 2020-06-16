#!/bin/bash

set -e

function main() {
    source install.sh --source-only
    
    uninstall

    cloudshell_cleanup
}

if [ "${1}" != "--source-only" ]; then
    main
fi
