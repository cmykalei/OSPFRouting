#!/bin/sh
# Path:         COMPX304-A1/scripts/ssh_goto_pair.sh
# Brief:        SSH to two locations in parallel via tmux.
# Usage:        `$ ssh-pair <Location A> <Location B> <'host' or 'router'>`
#               CONFIG_VERSION 4


# Function:     main
# Brief:        Main function that starts everything.
main() {
    init "$@"           # Initialise locations to ssh to.
    ssh_goto_pair $location_a $location_b $location_type
    main_exit 0
}


# Function:     init
# Brief:        Validates and sets the locations and type.
# Params:       $1=Location A, $2=Location B, $3=['host' or 'router']
init() {
    if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
        printf "\nERROR: Incorrect args provided!\n"
        printf "Usage: ssh-pair <Location A> <Location B> <'host' or 'router'>\n"
        main_exit 1
    elif [ ! -f "$CONFIG_VERSION" ]; then
        printf "ERROR: Project configuration %s does not exist.\n" "$CONFIG_VERSION"
        main_exit 1
    else
        . $CONFIG_VERSION
        ssh-add $SSH_KEY || { 
            printf "Failed to add SSH key.\n"
            main_exit 1
        }

        # Set location A if valid.
        case "$1" in
            "LOND"|"HAML"|"PARI"|"NEWY"|"TRGA"|"BOST"|"ATLA"|"ZURI") location_a="$1" ;;
            *) 
                printf "\nERROR: Invalid location: %s\n" "$1"
                main_exit 1
                ;;
        esac

        # Set location B if valid.
        case "$2" in
            "LOND"|"HAML"|"PARI"|"NEWY"|"TRGA"|"BOST"|"ATLA"|"ZURI") location_b="$2" ;;
            *) 
                printf "\nERROR: Invalid location: %s\n" "$2"
                main_exit 1
                ;;
        esac

        # Exit if locations are the same.
        if [ "$location_a" = "$location_b" ]; then
            printf "\nERROR: Locations must be different.\n"
            main_exit 1
        fi

        # Set the type to connect to.
        case "$3" in
            "host"|"router") location_type="$3" ;;
            *) 
                printf "\nERROR: Invalid type: %s\n" "$3"
                main_exit 1
                ;;
        esac
    fi
}


# Function:     ssh_start_tmux
# Brief:        Starts a new tmux session and splits panes.
ssh_goto_pair() {
    SSH_ENV="export SSH_AUTH_SOCK=$SSH_AUTH_SOCK;"

    tmux new-session -d -s lab "$SSH_ENV exec ssh $SSH_ALIAS"
    tmux split-window -t lab "$SSH_ENV exec ssh $SSH_ALIAS"
    tmux select-layout -t lab tiled

    tmux send-keys -t 0 "./goto.sh $location_a $location_type" C-m
    tmux send-keys -t 1 "./goto.sh $location_b $location_type" C-m
    exec tmux attach -t lab     # Attach the session's tab as lab.
}


# Function:     main_exit
# Brief:        Unsets all variables and exits.
main_exit() {
    tmux kill-session -t lab
    unset SSH_KEY SSH_ALIAS
    unset -f ssh_start_tmux
    unset -f ssh_send_commands
    unset -f init
    unset -f main
    exit "$1"
}


# Call main to execute the script.
main "$@"
