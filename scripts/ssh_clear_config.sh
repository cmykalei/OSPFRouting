#!/bin/sh
# Path:         COMPX304-A1/scripts/ssh_clear_config.sh
# Brief:        Clears configuration on all routers via SSH using tmux.
# Usage:        `$ ssh-clear-configs <'interface' or 'ospf'>`
#               CONFIG_VERSION 7
set -x

# Function:     main
# Brief:        Main function to start the clear process.
main() {
    if [ ! -f "$CONFIG_VERSION" ]; then
        printf "ERROR: Project configuration %s does not exist.\n" "$CONFIG_VERSION"
        main_exit 1
    else
        # Start the process to ssh and clear specified configs.
        . "$CONFIG_VERSION"               # Load project config file.
        init "$1"                  # Init config type.
        clear                       # Clear configs for all routers.
        clear_exit                  # Exit successfully.
    fi
}


# Function:     init
# Brief:        Validates and initializes parameters.
# Params:       $1=config type
init() {
    case "$1" in
        "host"|"host_interface")
            dev_type="host"
            config_type="host_interface" ;;
        "router"|"router_interface")
            dev_type="router"
            config_type="router_interface" ;;
        "ospf"|"router_ospf")
            dev_type="router"
            config_type="router_ospf" ;;
        *)
            printf "\nERROR: Invalid config type: %s\n" "$1"
            printf "Usage: ssh-clear-configs <'host' 'router' 'ospf'>\n"
            main_exit 1
            ;;
    esac
}


# Function:     clear
# Brief:        Clears configurations on all routers in one go.
clear() {
    SSH_ENV="export SSH_AUTH_SOCK=$SSH_AUTH_SOCK;"
    
    # Start tmux session if it doesn't exist
    if ! tmux has-session -t lab 2>/dev/null; then
        tmux new-session -d -s lab "$SSH_ENV exec ssh $SSH_ALIAS"
        sleep 0.7
    fi

    for location in LOND HAML PARI NEWY TRGA BOST ATLA ZURI; do
        printf "\nClearing config for %s...\n" "$location"

        # Create a new tmux window for each location
        tmux new-window -t lab -n "$location" "$SSH_ENV exec ssh $SSH_ALIAS"
        sleep 1

        # Navigate to the location
        tmux send-keys -t lab:"$location" "./goto.sh $location $dev_type" C-m
        sleep 1

        # Get the appropriate clear commands and apply them
        config_file="${GENERATED_DIR}/${location}_${config_type}_config_clear"
        if [ -f "$config_file" ]; then
            while IFS= read -r line; do
                tmux send-keys -t lab:"$location" "$line" C-m
                sleep 0.5
            done < "$config_file"
        else
            printf "\nERROR: Config file not found for %s\n" "$location"
        fi

        # Exit after clearing configs
        tmux send-keys -t lab:"$location" "exit" C-m
        sleep 0.5
    done

    # Kill the session after all clears
    tmux kill-session -t lab
}


# Function:     clear_exit
# Brief:        Exits successfully after clearing configs.
clear_exit() {
    tmux kill-session -t lab 2>/dev/null
    printf "\nConfiguration cleared successfully on all routers.\n"
    exit 0
}


# Function:     main_exit
# Brief:        Unsets all variables and exits with error.
main_exit() {
    tmux kill-session -t lab 2>/dev/null
    printf "\nERROR: Exiting with error code $1.\n"
    exit "$1"
}


# Call main to execute the script.
main "$@"
