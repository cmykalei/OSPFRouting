#!/bin/sh
# Path:         COMPX304-A1/scripts/activate.sh
# Brief:        Activate script for this assignment's development environment.
# Usage:        `$ sh scripts/activate.sh`
# Important:    This shell script sis intended to be used for development
#               purposes only. It was written and tested on macOS, but also
#               aims to be POSIX compliant.
#               VERSION 5


# Define the project's top directory name.
PROJECT_NAME="compx304-a1"

# I can't rememver why I did this, but there was a reason...
if [ "${DEACTIVATE_ONLY}" != 1 ]; then
    # Exit if this environment is activated.
    if [ "${PROJECT_NOT_DEACTIVATED+x}" ]; then
        printf "\nERROR: This environment is still active!\n"
        printf "\nUse command \`deactivate\` to exit cleanly."
        printf "\nOr \`source scripts/deactivate.sh\` to explicitly reset the environment.\n\n"
        return 1
    fi

    # Export a flag to say envrionment is active until its unset in deactivate.
    export PROJECT_NOT_DEACTIVATED=$PROJECT_NAME

    # Backup this this user's current environment variables.
    OLD_HOME=$HOME  # User home directory.
    OLD_PATH=$PATH  # Just in case.
    OLD_PS1=$PS1    # Shell prompt PS1.

    # Backup this user's current logging directory.
    OLD_HISTFILE=$OLD_HOME/.bash_history
    OLD_HISTSIZE=$HISTSIZE
    OLD_HISTFILESIZE=$HISTFILESIZE

    # Get the path to this script to define directory structure.
    SCRIPT_DIR=$(CDPATH= command cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")" && pwd)
    PARENT_DIR=$(dirname -- "$SCRIPT_DIR")
    PARENT_NAME=$(basename -- "$PARENT_DIR")

    # Temporarily change this user's environment variables.
    HOME=$PARENT_DIR
    PATH=$PATH:$HOME
    PS1="($PROJECT_NAME) \u@\h: \W $ "

    # Define subdirectories for generated files.
    export LOGS_DIR="$HOME/logs"                  # CLI logs for configs.
    export CONFIG_DIR="$HOME/config"
    export GENERATED_DIR="$CONFIG_DIR/generated"
    export SAVED_DIR="$CONFIG_DIR/saved"
    export CONFIG_VERSION="$CONFIG_DIR/VERSION"

    if [ -z "$PARENT_NAME" ]; then
        echo "\nError: Failed to determine the project directory name.\n"
        return 1
    fi

    # Warn if HOME variables matches the project name.
    if [ "$PARENT_NAME" != "$PROJECT_NAME" ]; then
        printf "\nWarning: The name of this project directory isn't set as expected."
        printf "The expected name is '%s'\n" "$PROJECT_NAME\n"
        printf "The actual name is '%s'\n" "$PARENT_NAME\n"
    fi

    # Exit that the environment was deactivated properly.
    if [ "$HOME" = "$OLD_HOME" ]; then
        printf "\nERROR: Your environment variable HOME has been misconfigured."
        printf "\nCheck that variables HOME and PATH are set correctly."
        return 1
    fi

    printf "\nWelcome to virtual environment for project $PROJECT_NAME!\n"
    printf "\nLogs are recorded in:\n\t$LOGS_DIR"
    printf "\nGenerated configuration lines are in:\n\t$GENERATED_DIR"
    printf "\nYour HOME variable is temporarily set to:\n\t$HOME\n"
    printf "\nUse the command \`deactivate\` to exit this environment.\n"
    cd $HOME
fi


# Function: deactivate
# Brief:    Unsets the environment variables to their previous values.
# Usage:    `$ deactivate` or `$ ./deactivate.sh`
deactivate() {
    # Reset this user's HOME, PATH, and PS1.
    export HOME=$OLD_HOME
    export PATH=$OLD_PATH
    export PS1=$OLD_PS1

    # Unset local variables just in case.
    unset OLD_HOME
    unset OLD_PS1
    unset OLD_PATH
    unset LOGS_DIR
    unset CONFIG_DIR
    unset GENERATED_DIR
    unset SAVED_DIR
    unset CONFIG_VERSION
    unset SSH_KEY
    unset SSH_ALIAS
    unset AS
    unset SUBNET_MASK_LO
    unset SUBNET_MASK_HOST
    unset SUBNET_MASK_ROUTER
    unset OSPF_BACKBONE_AREA

    # Reset this user's logging settings.
    export HISTFILE=$OLD_HISTFILE
    export HISTSIZE=$OLD_HISTSIZE
    export HISTFILESIZE=$OLD_HISTFILESIZE

    # Flag this project environment as deactivated.
    unset PROJECT_NOT_DEACTIVATED
    unset PROJECT_NAME
    unset PARENT_NAME

    # Unset function names.
    unset -f generate-host-interface
    unset -f generate-host-interface-configs
    unset -f generate-router-interface
    unset -f generate-router-interface-configs
    unset -f generate-router-ospf
    unset -f generate-router-ospf-configs
    unset -f generate-configs

    # Print a message to say process is done.
    printf "\nVirtual environment was closed successfully!\n\n"
}


# Function:     generate-host-interface
# Brief:        Calls generate interfaces script to print configuration line.
# Params:       $1=OFFSET (host location number 1–8)
# Usage:        `$ generate-host-interface [1-9]`
generate-host-interface() {
    sh "$SCRIPT_DIR/generate_host_interface.sh" "$1"
}


# Function:     generate-host-interface-configs
# Brief:        Calls generate function to print all configuration lines.
#               For each type and for every location, writes to 'addresses.txt'.
# Usage:        `$ generate-host-interface-configs`
generate-host-interface-configs() {
    i=1
    while [ "$i" -le 8 ]; do
        generate-host-interface "$i"
        i=$((i+1))
    done
}


# Function:     generate-router-interface
# Brief:        Calls generate interfaces script to print configuration line.
# Params:       $1=OFFSET (router location number 1–8)
# Usage:        `$ generate-router-interface [1-9]`
generate-router-interface() {
    sh "$SCRIPT_DIR/generate_router_interface.sh" "$1"
}


# Function:     generate-router-interface-configs
# Brief:        Calls generate function to print all configuration lines.
#               For each type and for every location, writes to 'addresses.txt'.
# Usage:        `$ generate-router-interface-configs`
generate-router-interface-configs() {
    i=1
    while [ "$i" -le 8 ]; do
        generate-router-interface "$i"
        i=$((i+1))
    done
}


# Function:     generate-router-ospf
# Brief:        Calls generate_ospf script to print OSPF configuration lines.
# Params:       $1=OFFSET (router location number 1–8)
# Usage:        `$ generate-router-ospf [1-9]`
generate-router-ospf() {
    sh "$SCRIPT_DIR/generate_router_ospf.sh" "$1"
}


# Function:     generate-router-ospf-configs
# Brief:        Calls generate-router-ospf function for each of the 8 routers.
# Usage:        `$ generate-router-ospf-configs`
generate-router-ospf-configs() {
    i=1
    while [ "$i" -le 8 ]; do
        generate-router-ospf $i
        i=$((i+1))
    done
}


# Function:     generate-configs
# Usage:        `$ generate-configs`
generate-configs() {
    generate-host-interface-configs
    generate-router-interface-configs
    generate-router-ospf-configs
}


# Function:     ssh-goto-pair
# Brief:        Calls ssh_goto_pair script to open tmux sessions for locations.
# Params:       $1=Location A, $2=Location B, $3=['host' or 'router']
# Usage:        `$ ssh-goto-pair <Location A> <Location B> <'host' or 'router>`
ssh-goto-pair() {
    sh $SCRIPT_DIR/ssh_goto_pair.sh $1 $2 $3
}


# Function:     ssh-update-config
# Brief:        Calls ssh_<type>_config script to execute batch commands in tmux.
# Params:       $1=config-type
# Usage:        `$ ssh-update-config <'host_interface' router_interface' 'router_ospf'>`
ssh-update-configs() {
    sh $SCRIPT_DIR/ssh_update_config.sh $1
}


# Function:     ssh-clear-config
# Brief:        Calls ssh_<type>_config script to execute batch commands in tmux.
# Params:       $1=config-type
# Usage:        `$ ssh-clear-config <'host_interface' router_interface' 'router_ospf'>`
ssh-clear-configs() {
    sh $SCRIPT_DIR/ssh_clear_config.sh $1
}


# Function:     ssh-refresh
# Brief:        Calls ssh_<type>_config script to execute batch commands in tmux.
ssh-refresh() {
    ssh-clear-configs "host"
    ssh-update-configs "host"
    ssh-clear-configs "router"
    ssh-update-configs "router"
    ssh-clear-configs "ospf"
    ssh-update-configs "ospf"
}

# Function:     ssh-ping
# Brief:        Records ping measurements in logs.
ssh-ping() {
    sh $SCRIPT_DIR/ssh_measure.sh "ping"
}


# Function:     ssh-iperf
# Brief:        Records iperf3 measurements in logs.
ssh-iperf() {
    sh $SCRIPT_DIR/ssh_measure.sh "iperf3"
}


# Function:     ssh-traceroute
# Brief:        Records traceroute output in logs.
ssh-traceroute() {
    sh $SCRIPT_DIR/ssh_measure.sh "traceroute"
}

# Function:     ssh-tcpdump
# Brief:        Records 'tcpdump -i any proto 89' output in logs.
ssh-tcpdump() {
    sh $SCRIPT_DIR/ssh_measure.sh "tcpdump"
}

# Function:     ssh-ospf
# Brief:        Records 'show ip ospf interface' output in logs.
ssh-ospf() {
    sh $SCRIPT_DIR/ssh_measure.sh "ospf"
}

# Function:     ssh-route
# Brief:        Records 'show ip route' output in logs.
ssh-route() {
    sh $SCRIPT_DIR/ssh_measure.sh "route"
}

# Function:     ssh-test-pair
# Brief:        Records 'ping', 'traceroute', and 'iperf3' output in logs.
# Params:       $1=location $2=location
ssh-test-pair() {
    sh $SCRIPT_DIR/ssh_measure.sh "test" $1 $2
}

# Function:     ssh-test
# Brief:        Records 'ping', 'traceroute', and 'iperf3' output in logs.
# Details:      These are just the links shown in the assignment PDF.
ssh-test() {
    sh $SCRIPT_DIR/ssh_measure.sh "test" LOND BOST
    sh $SCRIPT_DIR/ssh_measure.sh "test" LOND NEWY
    sh $SCRIPT_DIR/ssh_measure.sh "test" LOND PARI
    sh $SCRIPT_DIR/ssh_measure.sh "test" LOND HAML
    sh $SCRIPT_DIR/ssh_measure.sh "test" NEWY BOST
    sh $SCRIPT_DIR/ssh_measure.sh "test" NEWY PARI
    sh $SCRIPT_DIR/ssh_measure.sh "test" NEWY ZURI
    sh $SCRIPT_DIR/ssh_measure.sh "test" NEWY ATLA
    sh $SCRIPT_DIR/ssh_measure.sh "test" ZURI ATLA
    sh $SCRIPT_DIR/ssh_measure.sh "test" ZURI TRGA
    sh $SCRIPT_DIR/ssh_measure.sh "test" ZURI PARI
    sh $SCRIPT_DIR/ssh_measure.sh "test" PARI TRGA
    sh $SCRIPT_DIR/ssh_measure.sh "test" PARI HAML
}


# Function:     ssh-verify
# Brief:        Records 'show ip ospf database network' output in logs.
ssh-verify() {
    sh $SCRIPT_DIR/ssh_measure.sh "network"
}
