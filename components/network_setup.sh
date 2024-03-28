#!/bin/bash

# main script


network_setup(){
    local MAX_ATTEMPTS=5
    local ATTEMPTS=0
    local ATTEMPT_CODE

    echo -e "\nStarting network setup."
    while [ $ATTEMPTS -lt $MAX_ATTEMPTS ]; do

        # try wired connection
        echo -e "\tAttempting wired connection."
        attempt_wired_connection
        ATTEMPT_CODE=$?
        if [ $ATTEMPT_CODE -eq $NET_TYPE_WIRED ]; then
            return $NET_TYPE_WIRED
        fi

        echo -e "\tWired connection failed."

        # try wireless connection
        echo -e "\n\tAttempting wireless connection."
        attempt_wireless_connection
        ATTEMPT_CODE=$?
        if [ $ATTEMPT_CODE -eq $NET_TYPE_WIRELESS ]; then
            return $NET_TYPE_WIRELESS
        fi

        echo -e "\tWireless connection failed.\n"

        ((ATTEMPTS++))
    done
    return $NET_ERR
}

# get wired interface
get_wired_interface() {
    local WIRED_INTERFACE
    WIRED_INTERFACE=$(ip link | grep -E 'en|eth' | awk '{print$2}' | tr -d ':' | head -n 1)
    if [ -z "$WIRED_INTERFACE" ]; then
        return $NET_ERR

    fi
    echo $WIRED_INTERFACE
    return $NET_TYPE_WIRED
}

# check for wired connection
attempt_wired_connection() {
    echo -e "\t\tObtaining wired interface"
    local INTERFACE
    INTERFACE=$(get_wired_interface)
    local RETURN_CODE=$?

    # prompt user to plug Ethernet; add new error code to detect
    # when no interface is detected, handle echos in higher functions
    if [ $RETURN_CODE -eq $NET_ERR ]; then
        echo -e "\t\t\tNo wired interface detected."
        return $NET_ERR
    fi

    echo -e "\t\t\tDetected wired interface: $INTERFACE"
    
    echo -e "\t\tPlease ensure Ethernet is plugged in.\n\t\tPress any key to continue"
    read -n1 -s # wait for any key press
    sleep 2

    ip link set "$INTERFACE" up &> /dev/null
    dhcpcd "$INTERFACE" &> /dev/null

    if ip link show "$INTERFACE" | grep -q 'state UP'; then
        return $NET_TYPE_WIRED
    else
        return $NET_ERR
    fi
}

# get wireless interface
get_wireless_interface() {
    local WIRELESS_INTERFACE
    WIRELESS_INTERFACE=$(ip link | grep -E 'wl' | awk '{print$2}' | tr -d ':' | head -n 1)
    if [ -z "$WIRELESS_INTERFACE" ]; then
        return $NET_ERR
    fi
    echo $WIRELESS_INTERFACE
    return $NET_TYPE_WIRELESS
}

# check wireless connection
attempt_wireless_connection(){
    local INTERFACE
    echo -e "\t\tObtaining wireless interface."
    INTERFACE=$(get_wireless_interface)
    local RETURN_CODE=$?

    # check for invalid return code
    if [ $RETURN_CODE -eq $NET_ERR ]; then
        echo -e "\t\t\tNo wireless interface detected."
        return $NET_ERR
    fi
    
    echo -e "\t\t\tDetected wireless interface: $INTERFACE" >&2

    # start iwd service
    systemctl start iwd

    # scan for networks
    echo -e "\t\tScanning for networks..."
    iwctl station "$INTERFACE" scan
    
    # get proper indents for echo lines
    iwctl station "$INTERFACE" get-networks | while read -r line; do
        echo -e "\t\t\t$line"
    done

    # prompt user for network
    read -r -p "$(printf '\t\t')Please enter SSID of network to connect to: " SSID

    # prompt user for password
    read r -p "\t\tPlease enter password for $SSID: " -s PASS

    # attempt connection to wi-fi
    if iwctl --passphrase "$PASS" station "$INTERFACE" connect "$SSID"; then
        echo -e "\t\t\tConnected to $SSID."
        return $NET_TYPE_WIRELESS
    else
        echo -e "\t\t\tFailed to connect to  $SSID."
        return $NET_ERR
    fi
}

