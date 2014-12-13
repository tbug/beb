#!/bin/bash

unset CDPATH

# define variables available in all modules
SCRIPT_DIR="$( dirname "${BASH_SOURCE[0]}" )"
MODULES_DIR="$SCRIPT_DIR/modules"
SCRIPT_MAIN="${BASH_SOURCE[0]}"
MODULE_FILE_POSTFIX=".module.sh"

# settings for bashbooster
BB_LOG_USE_COLOR=true
BB_LOG_FORMAT='${TIME} [${LEVEL}] ${MESSAGE}'
# import bashbooster, mostly for logging and assertions.
source "$SCRIPT_DIR/bashbooster.sh"

# import our own lib
source "$SCRIPT_DIR/beb.lib.sh"



#
# function for listing available modules
#
function get_modules {
    local file
    for file in $(ls $MODULES_DIR | grep "$MODULE_FILE_POSTFIX\$")
    do
        echo "${file%$MODULE_FILE_POSTFIX}"
    done
}



#
# Define our top-level usage message
#
function usage {

    cat <<EOL
Usage:
    
    $0 [-d] [-q] <module> [-h] [<args>...]

    -d      Log at debug level
    -q      Log at warning level

Modules available:

$(get_modules | sed 's/^/    /')
EOL
}


function main {

    #
    # Initial check for at least the module name
    #
    if [ "$#" -lt 1 ]; then
        usage
        exit 1
    fi


    OPTIND=1
    while getopts dq opt; do
        case $opt in
        d)
            BB_LOG_LEVEL="$BB_LOG_DEBUG"
        ;;
        q)
            BB_LOG_LEVEL="$BB_LOG_WARNING"
        ;;
        esac
    done
    shift $((OPTIND - 1))

    #
    # Figure out what module to load
    #
    local module="$1"
    shift

    local modulepath="$MODULES_DIR/$module.module.sh"
    local modulemainfunc="${module}_main"

    # Load module and run it's main function
    if [ -f "$modulepath" ]; then
        source "$modulepath"
        "$modulemainfunc" "$@" || bb-exit 1 "Failed to run $module"
    else
        bb-exit 1 "Unknown module '$module'"
    fi
}

main "$@"
exit $?
