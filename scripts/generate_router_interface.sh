#!/bin/sh
# Path:         COMPX304-A1/scripts/generate_router_interface.sh
# Brief:        Generates commands for configuring a router's interfaces.
# Usage:        `$ generate-interface [1-8]`
#               offset {'1' '2' '3' '4' '5' '6' '7' '8'}
#               CONFIG_VERSION 3

# Declare location variable to configure.
location=""
offset=""


# Function:     main
# Brief:        Starts the generation by calling script functions.
# Details:      Required variables should be set in config/CONFIG_VERSION.
# Params:       $1=offset[1-8]
main() {
    if [ ! -d "$CONFIG_DIR" ] ||  [ ! -d "$GENERATED_DIR" ]; then
        printf "ERROR: Directory %s does not exist.\n" "$GENERATED_DIR"
        main_exit 1
    elif [ ! -f "$CONFIG_VERSION" ]; then
        printf "ERROR: Project configuration %s does not exist.\n" "$CONFIG_VERSION"
        main_exit 1
    else
        # Start generating the configuration the router's interface.
        . $CONFIG_VERSION                    # Activate project CONFIG_VERSION file.
        init $1                       # Check and initialise location to config.

        # Create the interface config file based on the router location.
        generated_file="$GENERATED_DIR/${location}_router_interface_config"
        generated_file_clear="$GENERATED_DIR/${location}_router_interface_config_clear"

        # Generate the command lines for this interface.
        generate_interface_lo         # 'ip address <AS.[150+OFFSET].0.1/SUBNET_MASK_LO>'
        generate_interface_host       # 'ip address <AS.[100+OFFSET].0.2/SUBNET_MASK>'

        # Print the result and redirect the output to the location's config file.
        generate > $generated_file
        generate_clear > $generated_file_clear
        main_exit 0
    fi
}


# Function:     init
# Brief:        Sets location variable name based on offset.
#               Like 'AS.0.[1-13].0/SUBNET_MASK' based on location[1-8]
# Params:       $1=offset[1-8]
init() {
    offset=$1
    case "$offset" in
        1) location="LOND" ;;
        2) location="HAML" ;;
        3) location="PARI" ;;
        4) location="TRGA" ;;
        5) location="NEWY" ;;
        6) location="BOST" ;;
        7) location="ATLA" ;;
        8) location="ZURI" ;;
        *)
            printf "\nERROR: OFFSET must be a number between 1 and 8.\n"
            main_exit 1
            ;;
    esac
}


# Function:     generate_interface_lo
# Brief:        Sets the variable for interface_lo_line using the AS and OFFSET.
#               Like 'ip address <AS.[150+OFFSET].0.1/SUBNET_MASK_LO>'
generate_interface_lo() {
    interface_lo="${AS}.15${offset}.0.1"
    interface_lo_line="ip address ${interface_lo}/${SUBNET_MASK_LO}\n"
}


# Function:     generate_interface_host
# Brief:        Sets the variable for interface_host_line using AS and offset.
#               Like 'ip address <AS.[100+offset].0.2/SUBNET_MASK_HOST>'
generate_interface_host() {
    interface_host="${AS}.10${offset}.0.2"
    interface_host_line="ip address ${interface_host}/${SUBNET_MASK_HOST}\n"
}


# Function:     generate
# Brief:        Calls functions to set command lines for specified location.
#               Prints the lines from the functions, preserves newlines.
generate() {
    # Check if loopback and network area config was set.
    if [ -n "$interface_lo_line" ] && [ -n "$interface_host_line" ]; then
        printf "configure terminal\n"
        printf "interface lo\n"
        printf "%b" "$interface_lo_line"
        printf "exit\n"
        printf "interface host\n"
        printf "%b" "$interface_host_line"
    else
        printf "ERROR: Loopback address not found for %s.\n" "$location"
        main_exit 1
    fi
}

# Function:     generate_clear
# Brief:        Calls functions to set command lines for specified location.
#               Prints the lines from the functions, preserves newlines.
generate_clear() {
    # Check if loopback and network area config was set.
    if [ -n "$interface_lo_line" ] && [ -n "$interface_host_line" ]; then
        printf "configure terminal\n"
        printf "interface lo\n"
        printf "%b" "no $interface_lo_line"
        printf "exit\n"
        printf "interface host\n"
        printf "%b" "no $interface_host_line"
    else
        printf "ERROR: Loopback address not found for %s.\n" "$location"
        main_exit 1
    fi
}


# Function:     main_exit
# Brief:        Unsets script variables used for init.
main_exit() {
    unset offset location
    unset generated_file
    unset interface_lo_line interface_host_line
    unset interface_lo interface_host
    unset -f main
    unset -f init
    unset -f generate
    exit "$1"
}


# Call main function to begin process.
main $1
