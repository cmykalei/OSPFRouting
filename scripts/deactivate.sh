#!/bin/sh
# Path:         COMPX304-A1/scripts/deactivate.sh
# Brief:        Deactivate script for this assignment's virtual environment.
# Usage:        `$ sh scripts/deaactivate.sh`
#               VERSION 1


# Get the script path and directory name.
SCRIPT_PATH=$(CDPATH= command cd -- "$(dirname -- "$0")" && pwd)/$(basename -- "$0")
SCRIPT_DIR=$(CDPATH= command cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")" && pwd)


# Set temporary flag for activate script to not run when sourced.
export DEACTIVATE_ONLY=1
ACTIVATE_SCRIPT_DIR=$SCRIPT_DIR/activate.sh
. $ACTIVATE_SCRIPT_DIR
unset DEACTIVATE_ONLY


# Call the deactivate function from the activate script.
deactivate
