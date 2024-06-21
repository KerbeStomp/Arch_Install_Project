#!/bin/bash


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


# get_dev: gets an array of block devices
get_dev(){
    local dev_arr=($(lsblk -d -n -p -o NAME,TYPE | grep "disk" |\
	    awk '{ print $1 }'))
    echo "${dev_arr[@]}"
    return 0
}

    
# show_dev: displays block devices
# args: device list
show_dev(){
    local dev_list=("$@")
    log "$(pad "Avaliable Devices")"
    for i in "${!dev_list[@]}"; do
	    log "$(pad "$(printf "%3d) %s\n" $((i+1)) "${dev_list[$i]}")")"
    done
    return 0
}


# chk_dev: checks if a block device exists
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
    parted --script "$dev" mkpart "$part_type" "$fs_type" "$start" "$stop" > /dev/null 2>&1
    return $?
}


# get_dev_size: gets the size of a block device in bytes
# args: block device
get_dev_size(){
    local dev="$1"
    local dev_size=$(lsblk -d -n -p -b -o NAME,SIZE | grep "$dev" |\
	    awk '{ print $2 }')
    echo "$dev_size"
    return 0
}


# part_dev: partitions a block device
# args: block device, boot type
part_dev(){
    local dev="$1"
    local boot_type="$2"
    local dev_size="$(get_dev_size "$dev")"
    
    if [[ "$dev_size" -lt 42949672960 ]]; then
        log "$(pad "Not enough space to install, at least 40 GB needed")" 2
        return 1
    fi

    if [[ "BIOS" == "$boot_type" ]]; then
	    gen_part_tbl "$dev" "msdos"
	    gen_part "$dev" "primary" "linux-swap" "1MiB" "8193MiB"
	    gen_part "$dev" "primary" "ext4" "8193MiB" "38913MiB"
	    gen_part "$dev" "primary" "ext4" "38913MiB" "100%"
        return 0
    elif [[ "UEFI" == "$boot_type" ]]; then
    	gen_part_tbl "$dev" "gpt"
    	gen_part "$dev" "EFI" "fat32" "1MiB" "1025MiB"
	    parted --script "$dev" set 1 esp on
    	gen_part "$dev" "Swap" "linux-swap" "1025MiB" "9217MiB"
    	gen_part "$dev" "Root" "ext4" "9217MiB" "39937MiB"
	    parted --script "$dev" type 3 \
		    4F68BCE3-E8CD-4DB1-96E7-FBCAF984B709 > /dev/null 2>&1
    	gen_part "$dev" "Home" "ext4" "39937MiB" "100%"
	parted --script "$dev" set 4 linux-home on
        return 0
    else
        return 1
    fi
}


# fmt_part: formats a partition
# args: partition, partition type
fmt_part(){
    local part="$1"
    local part_type="$2"

	log "$(pad "$(pad "Formatting ${part} as ${part_type}")")"
    if [[ "Root" == "$part_type" ]]; then
        mkfs.ext4 "$part" > /dev/null 2>&1
        return $?
    elif [[ "Swap" == "$part_type" ]]; then
        mkswap "$part" > /dev/null 2>&1
        return $?
    elif [[ "EFI" == "$part_type" ]]; then
        mkfs.fat -F 32 "$part" > /dev/null 2>&1
        return $?
    else
        return 1
    fi
}


# fmt_dev: formats a block device
# args: block device, boot type
fmt_dev(){
    local dev="$1"
    local boot_type="$2"

    log "$(pad "Formatting Disk")"
    if [[ "BIOS" == "$boot_type" ]]; then
        fmt_part "${dev}1" "Swap"
        fmt_part "${dev}2" "Root"
	log "$(pad "$(pad "Successfully formatted disk")")" 1
    elif [[ "UEFI" == "$boot_type" ]]; then
        fmt_part "${dev}1" "EFI"
        fmt_part "${dev}2" "Swap"
        fmt_part "${dev}3" "Root"
	log "$(pad "$(pad "Successfully formatted disk")")" 1
    else
	log "$(pad "$(pad "Error formatting disk")")" 1
        return 1
    fi
}


# mnt_part: mounts a partition
# args: partition, partition type
mnt_part(){
    local part="$1"
    local part_type="$2"

	log "$(pad "$(pad "Mounting ${part} as ${part_type}")")"
    if [[ "Root" == "$part_type" ]]; then
        mount "$part" /mnt > /dev/null 2>&1
        return $?
    elif [[ "Swap" == "$part_type" ]]; then
        swapon "$part" > /dev/null 2>&1
        return $?
    elif [[ "EFI" == "$part_type" ]]; then
        mount --mkdir "$part" /mnt/boot > /dev/null 2>&1
        return $?
    else
        return 1
    fi
}


# mnt_dev: mounts a block device
# args: block device, boot type
mnt_dev(){
    local dev="$1"
    local boot_type="$2"

    log "$(pad "Mounting disk")"
    if [[ "BIOS" == "$boot_type" ]]; then
        mnt_part "${dev}1" "Swap"
        mnt_part "${dev}2" "Root"
	log "$(pad "$(pad "Successfully mounted disk")")" 1
	return 0
    elif [[ "UEFI" == "$boot_type" ]]; then
        mnt_part "${dev}1" "EFI"
        mnt_part "${dev}2" "Swap"
        mnt_part "${dev}3" "Root"
	log "$(pad "$(pad "Successfully mounted disk")")" 1
	return 0
    else
	log "$(pad "$(pad "Error mounting disk")")" 2
        return 1
    fi
}


# set_dev: sets up a block device for installation
set_dev(){
    local boot_type="$(chk_boot)"

    while true; do
    	local dev_list=($(get_dev))
    	show_dev "${dev_list[@]}"
	local dev="$(qry_usr "$(pad "Please choose a device to use: ")")"
	if ! chk_dev "$dev" "${dev_list[@]}"; then
		log "$(pad "$(pad "Invalid device")")"
		continue
	fi

    local conf=$(qry_usr \
        "$(pad "All data from ${dev} will be erased, type YES to confirm: ")")

    if [[ "$conf" != "YES" ]]; then
        continue
    fi

    part_dev "$dev" "$boot_type"
    local part_stat=$?
    if [[ 1 == "$part_stat" ]];then
        return 1
    fi

    if [[ "$dev" == /dev/nvme* ]]; then
    	fmt_dev "${dev}p" "$boot_type"
    	mnt_dev "${dev}p" "$boot_type"
    elif [[ "$dev" == /dev/sda* ]]; then
	fmt_dev "$dev" "$boot_type"
	mnt_dev "$dev" "$boot_type"
    fi
    return 0
    done
} 
