#!/bin/sh
# Path:         COMPX304-A1/scripts/ssh_update_config.sh
# Brief:        Updates configuration on all routers via SSH using tmux.
# Usage:        `$ ssh-update-configs <'interface' or 'ospf'>`
#               CONFIG_VERSION 6
set -x

# Function:     main
# Brief:        Main function to start the update process.
main() {
    if [ ! -f "$CONFIG_VERSION" ]; then
        printf "ERROR: Project configuration %s does not exist.\n" "$CONFIG_VERSION"
        main_exit 1
    else
        # Start the process to ssh and update specified configs.
        . "$CONFIG_VERSION"               # Load project config file.
        init "$1"                  # Init config type.
        update                     # Update configs for all routers.
        update_exit                # Exit successfully.
    fi
}


# Function:     init
# Brief:        Initialises parameters.
# Params:       $1=config-type
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
            printf "Usage: ssh-update-configs <'host_interface' 'router_interface' 'router_ospf'>\n"
            main_exit 1
            ;;
    esac
}

update() {
    SSH_ENV="export SSH_AUTH_SOCK=$SSH_AUTH_SOCK;"
    
    # Start tmux session if it doesn't exist
    if ! tmux has-session -t lab 2>/dev/null; then
        tmux new-session -d -s lab "$SSH_ENV exec ssh $SSH_ALIAS"
        sleep 1
    fi

    for location in LOND HAML PARI NEWY TRGA BOST ATLA ZURI; do
        printf "\nUpdating config for %s...\n" "$location"

        # Create a new tmux window for each location
        tmux new-window -t lab -n "$location" "$SSH_ENV exec ssh $SSH_ALIAS"
        sleep 1

        # Navigate to the router
        tmux send-keys -t lab:"$location" "./goto.sh $location $dev_type" C-m
        sleep 1

        # Get config file and apply commands
        config_file="${GENERATED_DIR}/${location}_${config_type}_config"
        if [ -f "$config_file" ]; then
            while IFS= read -r line; do
                tmux send-keys -t lab:"$location" "$line" C-m
                sleep 0.5
            done < "$config_file"
        else
            printf "\nERROR: Config file not found for %s\n" "$location"
        fi

        # Exit after applying configs
        tmux send-keys -t lab:"$location" "exit" C-m
        sleep 0.5
    done

    # Kill the session after all updates
    tmux kill-session -t lab
}


# Function:     ssh_kill_pane
# Brief:        Sends clean exit commands to leave the session.
ssh_kill_pane() {
    pane=$1
    tmux send-keys -t 0 "exit" C-m      # Exit config mode cleanly
    sleep 0.5
    tmux send-keys -t 0 "exit" C-m      # Exit session
    sleep 0.5
}


# Function:     ssh_update_exit
# Brief:        Kills tmux session and exits successfully.
update_exit() {
    tmux kill-session -t lab 2>/dev/null
    printf "\nConfiguration updated successfully on all routers.\n"
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
