#!/bin/sh
# Path:         COMPX304-A1/scripts/generate_router_ospf.sh
# Brief:        Generates commands for configuring a router's OSPF network.
# Usage:        `$ generate-offset [1-8]`
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
    if [ ! -d "$GENERATED_DIR" ]; then
        printf "ERROR: Directory %s does not exist.\n" "$GENERATED_DIR"
        main_exit 1
    elif [ ! -f "$CONFIG_VERSION" ]; then
        printf "ERROR: Project configuration %s does not exist.\n" "$CONFIG_VERSION"
        main_exit 1
    else
        # Start generating the router's OSPF config.
        . $CONFIG_VERSION                    # Activate project CONFIG_VERSION file.
        init $1                       # Check and initialise location to config.

        # Create the file based on the router location.
        generated_file="$GENERATED_DIR/${location}_router_ospf_config"
        generated_file_clear="$GENERATED_DIR/${location}_router_ospf_config_clear"


        # Generate the command lines for this router.
        generate_ospf_router_id         # 'ip address <AS.[150+OFFSET].0.1/SUBNET_MASK_LO>'
        generate_ospf_network_area      # 'ip address <AS.[100+OFFSET].0.2/SUBNET_MASK_ROUTER>'

        # Print the commands and redirect to the config file.
        generate > $generated_file
        generate_clear > $generated_file_clear
        main_exit 0
    fi
}

# Function:     init
# Brief:        Sets location variable name based on offset.
#               Then sets that location's host subnetwork address, then finally
#               the location's available port subnetwork addresses.
#               Like 'AS.0.[1-13].0/SUBNET_MASK_ROUTER' based on location[1-8]
# Params:       $1=offset[1-8]
init() {
    offset=$1
    #host_subnetwork="$AS.10${offset}.0.2/$SUBNET_MASK_HOST" # Different mask!
    case "$offset" in
        1) location="LOND"
            port_haml="$AS.0.2.0/$SUBNET_MASK_ROUTER"
            port_pari="$AS.0.4.0/$SUBNET_MASK_ROUTER"
            port_bost="$AS.0.7.0/$SUBNET_MASK_ROUTER"
            port_newy="$AS.0.8.0/$SUBNET_MASK_ROUTER" ;;
        2) location="HAML"
            port_pari="$AS.0.1.0/$SUBNET_MASK_ROUTER"
            port_lond="$AS.0.2.0/$SUBNET_MASK_ROUTER" ;;
        3) location="PARI"
            port_haml="$AS.0.1.0/$SUBNET_MASK_ROUTER"
            port_trga="$AS.0.3.0/$SUBNET_MASK_ROUTER"
            port_lond="$AS.0.4.0/$SUBNET_MASK_ROUTER"
            port_newy="$AS.0.5.0/$SUBNET_MASK_ROUTER"
            port_zuri="$AS.0.6.0/$SUBNET_MASK_ROUTER" ;;
        4) location="TRGA"
            port_pari="$AS.0.3.0/$SUBNET_MASK_ROUTER"
            port_zuri="$AS.0.9.0/$SUBNET_MASK_ROUTER" ;;
        5) location="NEWY"
            port_pari="$AS.0.5.0/$SUBNET_MASK_ROUTER"
            port_lond="$AS.0.8.0/$SUBNET_MASK_ROUTER"
            port_bost="$AS.0.10.0/$SUBNET_MASK_ROUTER"
            port_atla="$AS.0.11.0/$SUBNET_MASK_ROUTER"
            port_zuri="$AS.0.12.0/$SUBNET_MASK_ROUTER" ;;
        6) location="BOST"
            port_lond="$AS.0.7.0/$SUBNET_MASK_ROUTER"
            port_newy="$AS.0.10.0/$SUBNET_MASK_ROUTER" ;;
        7) location="ATLA"
           port_newy="$AS.0.11.0/$SUBNET_MASK_ROUTER"
           port_zuri="$AS.0.13.0/$SUBNET_MASK_ROUTER" ;;
        8) location="ZURI"
            port_pari="$AS.0.6.0/$SUBNET_MASK_ROUTER"
            port_trga="$AS.0.9.0/$SUBNET_MASK_ROUTER"
            port_newy="$AS.0.12.0/$SUBNET_MASK_ROUTER"
            port_atla="$AS.0.13.0/$SUBNET_MASK_ROUTER" ;;
        *)
            printf "\nERROR: offset must be a number between 1 and 8.\n"
            main_exit 1
            ;;
    esac
}


# Function:     generate_ospf_router_id
# Brief:        Sets the variable for ospf_router_id_line using the AS and offset.
#               Like 'ospf router-id <AS.[150+offset].0.1>'
generate_ospf_router_id() {
    ospf_router_id_line="ospf router-id ${AS}.15${offset}.0.1\n"
}


# Function:     generate_ospf_network_area
# Brief:        Concats variable for ospf_network_area_lines by concatenating ports.
#               Like 'network <port-ip-address> area <OSPF-BACKBONE-AREA>'
generate_ospf_network_area() {
    ospf_network_area_lines=()
    [ -n "$port_lond" ] && { 
        ospf_network_area_lines+=("network $port_lond area $OSPF_BACKBONE_AREA\n")
    }
    [ -n "$port_haml" ] && { 
        ospf_network_area_lines+=("network $port_haml area $OSPF_BACKBONE_AREA\n")
    }
    [ -n "$port_pari" ] && { 
        ospf_network_area_lines+=("network $port_pari area $OSPF_BACKBONE_AREA\n")
    }
    [ -n "$port_trga" ] && { 
        ospf_network_area_lines+=("network $port_trga area $OSPF_BACKBONE_AREA\n")
    }
    [ -n "$port_newy" ] && { 
        ospf_network_area_lines+=("network $port_newy area $OSPF_BACKBONE_AREA\n")
    }
    [ -n "$port_bost" ] && { 
        ospf_network_area_lines+=("network $port_bost area $OSPF_BACKBONE_AREA\n")
    }
    [ -n "$port_atla" ] && { 
        ospf_network_area_lines+=("network $port_atla area $OSPF_BACKBONE_AREA\n")
    }
    [ -n "$port_zuri" ] && { 
        ospf_network_area_lines+=("network $port_zuri area $OSPF_BACKBONE_AREA\n")
    }
    #ospf_network_area_lines+=("network $host_subnetwork area $OSPF_BACKBONE_AREA\n")
}


# Function:     generate
# Brief:        Calls functions to set command lines for specified location.
# Details:      Prints the lines from the functions, preserves newlines.
generate() {
    # Check if loopback and network area config was set.
    if [ -n "$ospf_router_id_line" ] && [ -n "$ospf_network_area_lines" ]; then
        printf "configure terminal\n"
        printf "router ospf\n"
        printf "%b" "$ospf_router_id_line"
        for line in "${ospf_network_area_lines[@]}"; do
            printf "%b" "$line"
        done
        printf "redistribute connected\n"
    else
        printf "ERROR: OSPF configuration lines not set for %s router.\n" "$location"
        main_exit 1
    fi
}

# Function:     generate_clear
# Brief:        Calls functions to set command lines for specified location.
#               Prints the lines from the functions, preserves newlines.
generate_clear() {
    # Check if loopback and network area config was set.
    if [ -n "$ospf_router_id_line" ] && [ -n "$ospf_network_area_lines" ]; then
        printf "configure terminal\n"
        printf "no ospf router-id\n"
        printf "no router ospf\n"
    else
        printf "ERROR: Loopback address not found for %s.\n" "$location"
        main_exit 1
    fi
}


# Function:     main_exit
# Brief:        Unsets script variables used for generate_ospf.
main_exit() {
    unset offset location
    unset generated_file
    unset ospf_router_id_line ospf_network_area_lines
    unset -f main
    unset -f init
    unset -f generate
    exit "$1"
}


# Call main function to begin process.
main $1
