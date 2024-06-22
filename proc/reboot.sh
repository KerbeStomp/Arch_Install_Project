#!/bin/bash


# chk_esp: check if a EFI system partition is used
chk_esp(){
    local esp_dev="$(fdisk -l | grep EFI | awk '{ print $1 }' | head -n 1)"
    if [[ -z "$esp_dev" ]]; then
        return 1
    else
        echo "$esp_dev"
        return 0
    fi
}


# get_inst_dev: gets the device mounted to run installer
get_inst_dev(){
    local inst_dev="$(lsblk -n -o MOUNTPOINT,TYPE | grep -v "loop" | \
        grep "/mnt" | awk '{ print $1 }' | head -n 1)"
    echo "$inst_dev"
    return 0
}


# rbt_sys: reboot the system
rbt_sys(){
    local efi="$(chk_esp)"
    local inst_dev="$(get_inst_dev)"

    umount /mnt

    if [[ -n "$efi" ]]; then
        umount /mnt/boot
    fi

    wait_usr "$(pad \
        "Please remove installation medium. Press any key to continue")"

    reboot
    return 0
}




