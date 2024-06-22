#!/bin/bash


# get_inst_dev: gets the block device used for installation
get_inst_dev(){
    local dev="$(cat /tmp/inst_dev)"
    echo "$dev"
    return 0
}


# gen_fstab: generates an fstab file
# args: define type
gen_fstab(){
    log "$(pad "Generating fstab file")"
    local def_type="$1"
    genfstab "$def_type" /mnt >> /mnt/etc/fstab > /dev/null 2>&1
    local fstab_stat=$?
    if [[ "$fstab_stat" == 0 ]]; then
        return 0
    else
        log "$(pad "Error generating fstab file")" 2
        return 1
    fi
}


# cp_cfg: copys a chroot config script to new system
cp_cfg(){
    log "$(pad "Copying chroot config script")"
    cp chroot_cfg.sh /mnt/
    cp_stat=$?
    if [[ "$cp_stat" == 0 ]]; then
        return 0
    else
        log "$(pad "Error copying chroot config script")"
        return 1
    fi
}


# cfg_perms: enables execute permissions for chroot config script
cfg_perms(){
    log "$(pad "Enabling permissions for chroot config script")"
    chmod +x /mnt/chroot_cfg.sh 
    perm_stat=$?
    if [[ "$perm_stat" == 0 ]]; then
        return 0
    else
        log "$(pad "Error enabling permissions for chroot config script")"
        return 1
    fi
}



# chroot: change root into the new system
# args: block device
chroot(){
    local dev="$1"
    log "$(pad "Chrooting into system")"
    show_kb
    arch-chroot /mnt /chroot_cfg.sh "$dev"
    hide_kb
    local chroot_stat=$?
    if [[ "$chroot_stat" == 0 ]]; then
        return 0
    else
        log "$(pad "Error chrooting into system")" 2
        return 1
    fi
} 


# rm_cfg: removes a chroot config script from new system
rm_cfg(){
    log "$(pad "Removing chroot config script")"
    rm /mnt/chroot_cfg.sh
    rm_stat=$?
    if [[ "$rm_stat" == 0 ]]; then
        return 0
    else
        log "$(pad "Error removing chroot config script")"
        return 1
    fi
}


# cfg_sys: configure the user system
cfg_sys(){
    local dev="$(get_inst_dev)"
    gen_fstab "-U"
    cp_cfg
    cfg_perms
    chroot "$dev"
    rm_cfg
        return 0
}
