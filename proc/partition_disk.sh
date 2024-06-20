#!/bin/bash

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

# chk_boot: checks the boot mode
chk_boot(){
    local file="/sys/firmware/efi/fw_platform_size"
    if [[ ! -e "$file" ]]; then
        echo "BIOS"
        return 1
    else
        echo "UEFI"
        return 0
    fi
}


# get_dev: get an array of block devices
get_dev(){
    local dev_arr=($(lsblk -d -n -p -o NAME,TYPE | grep "disk" |\
	    awk '{ print $1 }'))
    echo "${dev_arr[@]}"
    return 0
}

    
# show_dev: show block devices
# args: device list
show_dev(){
    local dev_list=("$@")
    log "$(pad "Avaliable Devices")"
    for i in "${!dev_list[@]}"; do
	    log "$(pad "$(printf "%3d) %s\n" $((i+1)) "${dev_list[$i]}")")"
    done
    return 0
}


# chk_dev: checks if a device exists
# args: device, device list
chk_dev(){
    local dev="$1"
    shift
    local dev_list=("$@")

    for item in "${dev_list[@]}"; do
        if [[ "$dev" == "$item" ]]; then
            return 0
        fi
    done
    return 1
}


# gen_part_tbl: create a partiton table
# args: device, table type
gen_part_tbl(){
    local dev="$1"
    local tbl_type="$2"
    parted --script "$dev" mklabel "$tbl_type" > /dev/null 2>&1
    return $?
}
    
# gen_part: creates a partiton
# args: device, partition type, file system type, start, stop
gen_part(){
    local dev="$1"
    local part_type="$2"
    local fs_type="$3"
    local start="$4"
    local stop="$5"
    parted --script "$dev" mkpart "$part_type" "$fs_type" "$start" "$stop"
    return $?
}


# part_disk: partitions a disk for installation
# args: block device, boot type
part_disk(){
    local dev="$1"
    local boot_type="$2"

    if [[ "BIOS" == "$boot_type" ]]; then
	    gen_part_tbl "$dev" "msdos"
	    gen_part "$dev" "Swap" "linux-swap" "1MiB" "8193MiB"
	    gen_part "$dev" "Root" "ext4" "8193MiB" "38913MiB"
	    gen_part "$dev" "Home" "ext4" "38913MiB" "100%"
    elif [[ "UEFI" == "$boot_type" ]]; then
    	gen_part_tbl "$dev" "gpt"
    	gen_part "$dev" "EFI" "fat32" "1MiB" "1025MiB"
    	gen_part "$dev" "Swap" "linux-swap" "1025MiB" "9217MiB"
    	gen_part "$dev" "Root" "ext4" "9217MiB" "39937MiB"
    	gen_part "$dev" "Home" "ext4" "39937MiB" "100%"
    else
        return 1
    fi
}


# fmt_disk: formats a disk for installation
# args: block device, boot type
fmt_disk(){
    local dev="$1"
    local boot_type="$2"

    if [[ "BIOS" == "$boot_type" ]]; then
        fmt_part "${dev}1" "EFI"
        fmt_part "${dev}2" "Swap"
        fmt_part "${dev}3" "Root"
    elif [[ "UEFI" == "$boot_type" ]]; then
        fmt_part "${dev}1" "Swap"
        fmt_part "${dev}2" "Root"
    else
        return 1
    fi
}


# mnt_disk: mounts a disk for installation
# args: block device, boot type
fmt_disk(){
    local dev="$1"
    local boot_type="$2"

    if [[ "BIOS" == "$boot_type" ]]; then
        mnt_part "${dev}1" "EFI"
        mnt_part "${dev}2" "Swap"
        mnt_part "${dev}3" "Root"
    elif [[ "UEFI" == "$boot_type" ]]; then
        mnt_part "${dev}1" "Swap"
        mnt_part "${dev}2" "Root"
    else
        return 1
    fi
}


# set_disk: sets up a block device for installation
set_disk(){
    local boot_type="$(chk_boot)"

    while true; do
    	local dev_list=($(get_dev))
    	show_dev "${dev_list[@]}"
	local dev=$(qry_usr "$(pad "Please choose a device to use: ")")
	if ! chk_dev "$dev" "${dev_list[@]}"; then
		log "$(pad "$(pad "Invalid device")")"
		continue
	fi

    local conf=$(qry_usr \
        "$(pad "All data from ${dev} will be erased, type YES to confirm: ")")

    if [[ "$conf" != "YES" ]]; then
        continue
    fi
    done

    part_disk "$dev" "$boot_type"
    fmt_disk "$dev" "$boot_type"
    mount_disk "$dev" "$boot_type"
    return 0
} 
