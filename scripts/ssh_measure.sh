#!/bin/sh
# Path:         COMPX304-A1/scripts/ssh_measure.sh
# Brief:        SSH to hosts, start iperf3 server, and loop through all clients.
# Usage:        `$ ssh-measure-throughput`
#               VERSION 2
set -x

# Function:     main
# Brief:        Main function that starts everything.
main() {
    init "$@"
    if [ $option = "ping" ]; then
        measure_latency
        main_exit 0
    elif [ $option = "iperf3" ]; then
        measure_throughput
        main_exit 0
    elif [ $option = "traceroute" ]; then
        measure_traceroute
        main_exit 0
    elif [ $option = "tcpdump" ]; then
        measure_tcpdump
        main_exit 0
    elif [ $option = "ospf" ]; then
        measure_ospf
        main_exit 0
    elif [ $option = "route" ]; then
        measure_route
        main_exit 0
    elif [ $option = "test" ]; then
        measure_test $2 $3
        main_exit 0
    elif [ $option = "network" ]; then
        measure_network
        main_exit 0
    else
        printf "EXIT: Option wasn't set!\n"
        main_exit 1
    fi
}


# Function:     init
# Brief:        Validates and sets the locations and type.
# Params:       $1=Location A, $2=Location B, $3=['host' or 'router']
init() {
    if [ -z "$1" ]; then
        printf "\nERROR: Incorrect args provided!\n"
        printf "Usage: ssh-measure <option>\n"
        main_exit 1
    elif [ ! -f "$CONFIG_VERSION" ]; then
        printf "ERROR: Project configuration %s does not exist.\n" "$CONFIG_VERSION"
        main_exit 1
    else
        case "$1" in
            "ping"|"latency")
                option="ping" ;;
            "iperf3"|"throughput")
                option="iperf3" ;;
            "trace"|"traceroute")
                option="traceroute" ;;
            "tcp"|"tcpdump")
                option="tcpdump" ;;
            "ospf")
                option="ospf" ;;
            "route")
                option="route" ;;
            "test")
                option="test" ;;
            "network"|"database")
                option="network" ;;
            *)
                printf "\nERROR: Invalid option: %s\n" "$1"
                main_exit 1
                ;;
        esac

        . $CONFIG_VERSION
        ssh-add $SSH_KEY || { 
            printf "Failed to add SSH key.\n"
            main_exit 1
        }
        SSH_ENV="export SSH_AUTH_SOCK=$SSH_AUTH_SOCK;"
        tmux kill-session -t server
        tmux kill-session -t client
    fi
}


# Function:     measure_latency
# Brief:        Starts tmux session for server and goes to all routers to ping.
# Details:      Loops through 1-8 hosts and pings all others to measure latency.
#               Output redirected to 'logs/ping_<router>_<router>'
measure_latency() {
    tmux new-session -d -s server "$SSH_ENV exec ssh $SSH_ALIAS"
    sleep 1

    i=0
    LOCATIONS="LOND HAML PARI TRGA NEWY BOST ATLA ZURI"
    for location in $LOCATIONS; do
        i=$((i+1))

        tmux send-keys -t server "./goto.sh $location router" C-m
        sleep 1

        j=0
        for target in $LOCATIONS; do
            tmux send-keys -t server C-l
            sleep 0.5

            j=$((j+1))
            if [ $j != $i ]; then
                OUTPUT="${LOGS_DIR}/ping_${i}_${j}"
                printf "Measuring latency for $location($i) <-> $target($j)\n" > $OUTPUT

                addr="$AS.10${j}.0.2"
                tmux send-keys -t server "ping ${addr}" C-m
                sleep 5

                tmux capture-pane -p -t server >> $OUTPUT
                tmux send-keys -t server C-c
                sleep 0.5
            fi
        done
        tmux send-keys -t server C-l
        tmux send-keys -t server "exit" C-m
        sleep 0.5
    done
    main_exit 0
}

# Function:     measure_throughout
# Brief:        Starts tmux sessions for each host as an iperf3 server.
# Details:      Loops through 1-8 hosts as iperf3 clients to measure throughput.
#               Output redirected to 'logs/iperf3_<server>_<client>'
measure_throughput() {
    tmux new-session -d -s server "$SSH_ENV exec ssh $SSH_ALIAS"
    tmux new-session -d -s client "$SSH_ENV exec ssh $SSH_ALIAS"
    sleep 1

    i=0
    LOCATIONS="LOND HAML PARI TRGA NEWY BOST ATLA ZURI"
    for location in $LOCATIONS; do
        i=$((i+1))
        addr="$AS.10${i}.0.1"

        tmux send-keys -t server "./goto.sh $location host" C-m
        tmux send-keys -t server "iperf3 -s -D" C-m
        sleep 0.5

        j=0
        for target in $LOCATIONS; do
            tmux send-keys -t client C-l
            sleep 0.5

            j=$((j+1))
            if [ $j != $i ]; then
                OUTPUT="${LOGS_DIR}/iperf_${i}_${j}"
                printf "Measuring throughput for $location($i) <-> $target($j)\n" > $OUTPUT

                tmux send-keys -t client "./goto.sh $target host" C-m
                tmux send-keys -t client "iperf3 -c ${addr} -t 10" C-m
                sleep 10

                tmux capture-pane -p -t client >> $OUTPUT
                tmux send-keys -t client C-c
                tmux send-keys -t client "exit" C-m
                sleep 0.5
            fi
        done
        tmux send-keys -t server "pkill iperf3" C-mm
        tmux send-keys -t server C-c
        tmux send-keys -t server "exit" C-m
        sleep 0.5
    done
    main_exit 0
}


# Function:     measure_traceroute
# Brief:        Starts tmux sessions for each router to run traceroute.
# Details:      Loops through 1-8 hosts and measures traceroute from the router.
#               Output redirected to 'logs/trace_<router>_<router>'
measure_traceroute() {
    tmux new-session -d -s server "$SSH_ENV exec ssh $SSH_ALIAS"
    sleep 1

    i=0
    LOCATIONS="LOND HAML PARI TRGA NEWY BOST ATLA ZURI"
    for location in $LOCATIONS; do
        i=$((i+1))

        tmux send-keys -t server "./goto.sh $location router" C-m
        sleep 0.5

        j=0
        for target in $LOCATIONS; do
            tmux send-keys -t server C-l
            sleep 0.5

            j=$((j+1))
            if [ $j != $i ]; then
                OUTPUT="${LOGS_DIR}/trace_${i}_${j}"
                printf "Measuring traceroute for $location($i) <-> $target($j)\n" > $OUTPUT

                addr="$AS.10${j}.0.2"
                tmux send-keys -t server "traceroute ${addr}" C-m
                sleep 5

                tmux capture-pane -p -t server >> $OUTPUT
                tmux send-keys -t server C-c
                sleep 0.5
            fi
        done
        tmux send-keys -t server C-c
        tmux send-keys -t server "exit" C-m
        sleep 0.5
    done
    main_exit 0
}


# Function:     measure_tcpdump
# Brief:        Starts tmux sessions for each host to run tcdump.
# Details:      Loops through 1-8 hosts and verifies no OSPF packets are leaked.
#               Output redirected to 'logs/tcpdump_<host>'
measure_tcpdump() {
    tmux new-session -d -s server "$SSH_ENV exec ssh $SSH_ALIAS"
    sleep 1

    LOCATIONS="LOND HAML PARI TRGA NEWY BOST ATLA ZURI"
    i=0
    for location in $LOCATIONS; do
        i=$((i+1))
        OUTPUT="${LOGS_DIR}/tcpdump_${i}"

        tmux send-keys -t server C-l
        tmux send-keys -t server "./goto.sh $location host" C-m
        sleep 0.5

        tmux send-keys -t server "tcpdump -i any proto 89"
        sleep 5

        tmux capture-pane -p -t server >> $OUTPUT
        tmux send-keys -t server C-c
        tmux send-keys -t server "exit" C-m
        sleep 0.5
    done
    main_exit 0
}


# Function:     measure_ospf
# Brief:        Starts tmux sessions for each router to show ospf interface.
# Details:      Loops through 1-8 routers and verifies OSPF configuration.
#               Output redirected to 'logs/ospf_<interface>'
measure_ospf() {
    tmux new-session -d -s server "$SSH_ENV exec ssh $SSH_ALIAS"
    sleep 1

    LOCATIONS="LOND HAML PARI TRGA NEWY BOST ATLA ZURI"
    i=0
    for location in $LOCATIONS; do
        i=$((i+1))
        OUTPUT="${LOGS_DIR}/ospf_${i}"

        tmux send-keys -t server "./goto.sh $location router" C-m
        sleep 0.5
        tmux send-keys -t server "show ip ospf interface" C-m
        sleep 0.5

        tmux capture-pane -p -t server >> $OUTPUT
        tmux send-keys -t server C-c
        tmux send-keys -t server "exit" C-m
        tmux send-keys -t server C-l
        sleep 0.5
    done
    main_exit 0
}


# Function:     measure_route
# Brief:        Starts tmux session for server and goes to each router.
# Details:      Loops through 1-8 hosts and shows ip route for each.
#               Output redirected to 'logs/route_<router>_<router>'
measure_route() {
    tmux new-session -d -s server "$SSH_ENV exec ssh $SSH_ALIAS"
    sleep 1

    i=0
    LOCATIONS="LOND HAML PARI TRGA NEWY BOST ATLA ZURI"
    for location in $LOCATIONS; do
        i=$((i+1))

        tmux send-keys -t server "./goto.sh $location router" C-m
        sleep 1

        j=0
        for target in $LOCATIONS; do
            tmux send-keys -t server C-l
            sleep 0.5

            j=$((j+1))
            if [ $j != $i ]; then
                OUTPUT="${LOGS_DIR}/route_${i}_${j}"
                printf "Measuring route from $location($i) <-> $target($j)\n" > $OUTPUT

                addr="$AS.10${j}.0.2"
                tmux send-keys -t server "show ip route ${addr}" C-m
                sleep 1

                tmux capture-pane -p -t server >> $OUTPUT
                tmux send-keys -t server C-c
                sleep 0.5
            fi
        done
        tmux send-keys -t server C-l
        tmux send-keys -t server "exit" C-m
        sleep 0.5
    done
    main_exit 0
}


# Function:     measure_test
# Brief:        Starts tmux session for specified locations to run tests.
# Params:       $1=location_name $2=location_name
#               Output redirected to 'logs/test_<router>_<router>'
measure_test() {
    case "$1" in
        "lond"|"LOND")
            location_i="LOND"
            i=1 ;;
        "haml"|"HAML")
            location_i="HAML"
            i=2 ;;
        "pari"|"PARI")
            location_i="PARI"
            i=3 ;;
        "trga"|"TRGA")
            location_i="TRGA"
            i=4 ;;
        "newy"|"NEWY")
            location_i="NEWY"
            i=5 ;;
        "bost"|"BOST")
            location_i="BOST"
            i=6 ;;
        "atla"|"ATLA")
            location_i="ATLA"
            i=7 ;;
        "zuri"|"ZURI")
            location_i="ZURI"
            i=8 ;;
        *)
            printf "\nERROR: Location wasn't valid.\n"
            main_exit 1
            ;;
    esac
    case "$2" in
        "lond"|"LOND")
            location_j="LOND"
            j=1 ;;
        "haml"|"HAML")
            location_j="HAML"
            j=2 ;;
        "pari"|"PARI")
            location_j="PARI"
            j=3 ;;
        "trga"|"TRGA")
            location_j="TRGA"
            j=4 ;;
        "newy"|"NEWY")
            location_j="NEWY"
            j=5 ;;
        "bost"|"BOST")
            location_j="BOST"
            j=6 ;;
        "atla"|"ATLA")
            location_j="ATLA"
            j=7 ;;
        "zuri"|"ZURI")
            location_j="ZURI"
            j=8 ;;
        *)
            printf "\nERROR: Location wasn't valid.\n"
            main_exit 1
            ;;
    esac

    if [ -z "$location_i" ] && [ -z "$location_j" ]; then
        printf "Usage: measure <Location A> <Location B>\n"
        main_exit 1
    else
        OUTPUT="${LOGS_DIR}/test_${location_i}_${location_j}"
        printf "Tests for link $location_i($i) <-> $location_j($j)\n" > $OUTPUT

        router_ip_i="$AS.10${i}.0.2"
        router_ip_j="$AS.10${j}.0.2"
        host_ip_i="$AS.10${i}.0.1"
        host_ip_j="$AS.10${j}.0.1"

        tmux new-session -d -s server "$SSH_ENV exec ssh $SSH_ALIAS"
        tmux new-session -d -s client "$SSH_ENV exec ssh $SSH_ALIAS"
        tmux send-keys -t server C-l
        sleep 1

        # Start ping test.
        tmux send-keys -t server "./goto.sh $location_i router" C-m
        sleep 1
        tmux send-keys -t server "ping ${router_ip_j}" C-m
        sleep 5
        tmux send-keys -t server "pkill ping" C-m
        tmux send-keys -t server C-c
        sleep 1

        # Start traceroute test.
        tmux send-keys -t server "traceroute ${router_ip_j}" C-m
        sleep 5
        tmux send-keys -t server C-c
        sleep 1
        tmux capture-pane -p -t server >> $OUTPUT

        # Start iperf3 test.
        tmux send-keys -t server "exit" C-m
        sleep 1
        tmux send-keys -t server "./goto.sh $location_i host" C-m
        tmux send-keys -t client "./goto.sh $location_j host" C-m
        sleep 1
        tmux send-keys -t server "iperf3 -s" C-m
        sleep 1
        tmux send-keys -t client "iperf3 -c ${host_ip_i}" C-m
        sleep 10
        tmux capture-pane -p -t client >> $OUTPUT

        # End test.
        tmux send-keys -t server C-c
        tmux send-keys -t server "pkill iperf3" C-m
        tmux send-keys -t client C-c
        sleep 1
        tmux send-keys -t server "exit" C-m
        sleep 1
        main_exit 0
    fi
}


# Function:     measure_network
# Brief:        Starts tmux session for server and goes to all routers.
# Details:      Prints `show ip ospf database network` for each location.
#               Output redirected to 'logs/ospf_network_<router>_<router>'
measure_network() {
    tmux set -g history-limit 10000
    tmux new-session -d -s server "$SSH_ENV exec ssh $SSH_ALIAS"
    sleep 1

    i=0
    LOCATIONS="LOND HAML PARI TRGA NEWY BOST ATLA ZURI"
    for location in $LOCATIONS; do
        i=$((i+1))
        OUTPUT="${LOGS_DIR}/ospf_network_${location}"

        tmux send-keys -t server C-l
        tmux send-keys -t server "./goto.sh $location router" C-m
        sleep 1
        tmux send-keys -t server "show ip ospf database network" C-m
        sleep 1
        tmux pipe-pane -o -t server "cat > $OUTPUT"
        tmux send-keys -t server "exit" C-m
        sleep 0.5
    done
    main_exit 0
}


# Function:     main_exit
# Brief:        Unsets all variables and exits.
main_exit() {
    tmux kill-session -t server
    tmux kill-session -t host
    unset SSH_KEY SSH_ALIAS
    unset OUTPUT
    unset ping iperf3
    unset option
    unset -f init
    unset -f measure_latency
    unset -f measure_throughput
    unset -f main
    exit "$1"
}


# Call main to execute the script.
main "$@"
