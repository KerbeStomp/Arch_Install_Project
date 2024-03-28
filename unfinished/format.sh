#!/bin/bash

# detect default device
local DEFAULT_DEVICE=$(lsblk -d -n -p -o NAME | grep disk | head -n 1)
if [ -z "$DEFAULT_DEVICE" ]; then
    echo "No drive detected."
    return $FM_ERR
fi

# func: format partitions
format_partitions() {
    
    # format each partition

    # format EFI
    mkfs.fat -F 32 "${1}1" || { echo "Error: Failed to format EFI partition."; exit 1; }

    # format ROOT
    mkfs.ext4 "${1}2" || { echo "Error: Failed to format ROOT partition."; exit 1; }

    # format swap
    mkswap "${1}3" || { echo "Error: Failed to format SWAP partition."; exit 1; }
    swapon "${1}3"

    # format home
    mkfs.ext4 "${1}4" || { echo "Error: Failed to format HOME partition."; exit 1; }

    echo "Formatted ${1} successfuly."
}


# main script

format_device() {
    # list connected devices
    echo "Connected devices:"
    lsblk -d -n -p -o NAME,SIZE,TYPE | grep disk

    # prompt user to choose device
    echo "Enter a device to format [defalt: $DEFAULT_DEVICE]:"
    read -r DEVICE
    DEVICE=${DEVICE:-$DEFAULT_DEVICE}

    # confirm device
    echo "You have selected $DEVICE to format"
    echo "All data from $DEVICE will be erased."

    # list out format mapping
    echo "EFI: ${DEVICE}1"
    echo "ROOT: ${DEVICE}2"
    echo "SWAP: ${DEVICE}3"
    echo "HOME: ${DEVICE}4"
    echo "Type 'yes' to continue."
    read -r CONFIRMATION

    # final check before formating
    if [ "$CONFIRMATION" != "yes" ]; then
        echo "Formatting canceled."
        exit 1
    fi

    if format_partitions "$DEVICE"; then
        FORMATTED="0"
    fi
}

if ! $FORMATTED; then
    format_device
fi
echo "Formatting complete."