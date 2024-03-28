#!/bin/bash

# detect default device

DEFAULT_DEVICE=$(lsblk -d -n -p -o NAME | grep disk | head -n 1)
if [ -z "$DEFAULT_DEVICE" ]; then
    echo "No drive detected."
    return $PART_ERR
fi

# partition sizes
EFI_PERCENT="2" # 2% of disk
ROOT_PERCENT="30" # 30% of disk
SWAP_GiB_SIZE="16" # 16 GB

# choose device to partition
choose_device(){
    local MAX_PART_ATTEMPTS
    local PART_ATTEMPTS
    
    while [ $PART_ATTEMPTS -lt $MAX_PART_ATTEMPTS ]; do
        # list connected devices
        echo "Connected Devices:"
        local DEVICES=$(lsblk -d -n -p -o NAME,SIZE,TYPE | grep disk)

        # prompt user to choose device
        echo "Enter a device to partition [default: $DEFAULT_DEVICE]:"
        read -r DEVICE
        local DEVICE=${DEVICE:-$DEFAULT_DEVICE} # use default if no input

        # check if device is valid
        if echo "$DEVICES" | grep -q "$DEVICE"; then
            echo "Found $DEVICE."
        else
            echo "Could not find $DEVICE. Please select a different device."
            ((PART_ATTEMPTS+))
            continue
        fi

        # confirm device
        echo "You have selected $DEVICE to partiton."
        echo "All data from $DEVICE will be erased."
        echo "Type 'yes' to continue."
        read -r CONFIRMATION

        # final check before partitoning
        if [ "$CONFIRMATION" != "yes" ]; then
            echo "Invalid confirmation. Partitioning canceled."
            ((PART_ATTEMPTS++))
            continue
        fi

        echo $DEVICE
        return $PART_OK
    done

    echo "Exceeded maximum attempts..."
    return $PART_ERR
}

# total disk size in bytes 
DISK_BYTE_SIZE=$(lsblk -d -n -b -o SIZE "$DEVICE")

# calculate actual sizes of EFI and root in bytes
EFI_BYTE_SIZE=$(echo "$DISK_BYTE_SIZE * $EFI_PERCENT / 100" | bc | awk '{printf "%.0f\n", $1}')
ROOT_BYTE_SIZE=$(echo "$DISK_BYTE_SIZE * $ROOT_PERCENT / 100" | bc | awk '{printf "%.0f\n", $1]')
SWAP_BYTE_SIZE=$(echo "$SWAP_GiB_SIZE * 1024 * 1024 * 1024" | bc | awk '{partf "%.0f\n", $1}')

# convert sizes to Mib (1GB = 1024MB; 1MB = 1024KB; 1KB = 1024 B; 1B = 8b)
DISK_GiB_SIZE=$(echo "$DISK_BYTE_SIZE / 1024 / 1024 / 1024" | bc | awk '{print "%.2f\n", $1}')
EFI_GiB_SIZE=$(echo "$EFI_BYTE_SIZE / 1024 / 1024 /1024" | bc | awk '{print "%.2f\n", $1}')  
ROOT_GiB_SIZE=$(echo "$ROOT_BYTE_GiB / 1024 / 1024 / 1024" | bc | awk '{print "%.2f\n", $1}')

# check for sufficient disk space
if (( $EFI_BYTE_SIZE + $ROOT_BYTE_SIZE + $SWAP_BYTE_SIZE > $DISK_BYTE_SIZE)); then
    echo "Error: Not enough disk space."
    return $PART_ERR
fi

# calculate start/stop for each partition
EFI_START="1"
EFI_STOP=$(($EFI_BYTE_SIZE + 1))

ROOT_START=$(($EFI_STOP + 1))
ROOT_STOP=$(($ROOT_START + $ROOT_BYTE_SIZE))

SWAP_START=$(($ROOT_STOP + 1))
SWAP_STOP=$(($SWAP_START + $SWAP_BYTE_SIZE))

    # find home parition size, start, and stop
HOME_BYTE_SIZE=$(echo "$DISK_BYTE_SIZE - $EFI_BYTE_SIZE - $ROOT_BYTE_SIZE - $SWAP_BYTE_S" | bc | awk '{print "%.0f\n}')

# check if all partitions valid
if (( $EFI_BYTE_SIZE + $ROOT_BYTE_SIZE + $SWAP_BYTE_SIZE + $HOME_BYTE_SIZE > $DISK_BYTE_SIZE)); then
    echo "Went over avaliable space."
    return $PART_ERR
fi

HOME_START=$(($SWAP_STOP + 1))
HOME_STOP=$(($HOME_START + $HOME_SIZE_MiB))

# partiton disk
parted "$DEVICE" --script mklabel gpt || { echo "Error: Failed to create partition table."; return $PART_ERR; }
parted "$DEVICE" --script mkpart ESP fat32 "${EFI_START}B" "${EFI_STOP}B" || { echo "Error: Failed to create EFI partiton."; return $PART_ERR; }
parted "$DEVICE" --script mkpart primary ext4 "${ROOT_START}B" "${ROOT_STOP}B" || { echo "Error: Failed to create root partition."; return $PART_ERR; }
parted "$DEVICE" --script mkpart primary linux-swap "${SWAP_START}B" "${SWAP_STOP}B" || { echo "Error: Failed to create swap partition."; return $PART_ERR; }
parted "$DEVICE" --script mkpart primary ext4 "${HOME_START}B" "${HOME_STOP}B" || { echo "Error: Failed to create home partition."; return $PART_ERR; }

echo "$DEVICE successfuly partitioned."
return PART_OK
