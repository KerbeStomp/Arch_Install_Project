#!/bin/bash


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


# chroot: change root into the new system
chroot(){
    log "$(pad "Chrooting into system")"
    show_kb
    arch-chroot /mnt > /dev/null 2>&1
    local chroot_stat=$?
    if [[ "$chroot_stat" == 0 ]]; then
        return 0
    else
        log "$(pad "Error chrooting into system")" 2
        return 1
    fi
} 


# set_tz: set the time zone
set_tz(){
    log "$(pad "Setting time zone")"
    ln -sf usr/share/zoneinfo/US/Pacific /etc/localtime > /dev/null 2>&1
    local tz_stat=$?
    if [[ "$tz_stat" == 0 ]]; then
        return 0
    else
        log "$(pad "Error setting time zone")" 2
        return 1
    fi
}


# upd_clk: update hardware clock
upd_clk(){
    log "$(pad "Updating hardware clock")"
    hwclock --systohc > /dev/null 2>&1
    local tz_stat=$?
    if [[ "$tz_stat" == 0 ]]; then
        return 0
    else
        log "$(pad "Error updating hardware clock")" 2
        return 1
    fi
}

# clk_sync: enable time synchronization with systemd-timesyncd
clk_sync(){
    log "$(pad "Enabling time synchronization")"
    systemctl enable systemd-timesyncd.service > /dev/null 2>&1
    local sync_stat=$?
    if [[ "$sync_stat" == 0 ]]; then
        return 0
    else
        log "$(pad "Error enabling time synchronization")" 2
        return 1
    fi
}


# enb_net: enable NetworkManager
enb_net(){
    log "$(pad "Enabling NetworkManager")"
    systemctl enable NetworkManager > /dev/null 2>&1
    local enb_stat=$?
    if [[ "$enb_stat" == 0 ]]; then
        return 0
    else
        log "$(pad "Error enabling time synchronization")" 2
        return 1
    fi
}


# gen_loc: generates locales
gen_loc(){
    log "$(pad "Generating locales")"
    sed -i '/en_US.UTF-8/ s/^#//' /etc/locale.gen
    locale-gen > /dev/null 2>&1
    echo "LANG=en_US.UTF-8" > /etc/locale.conf
    return 0
}


# set_hn: sets the user hostname
set_hn(){
    while true; do
        local hostname="$(qry_usr "$(pad "Enter a hostname: ")")"

        if [[ -z "$hostname" ]]; then
            log "$(pad "Invalid hostname")" 3
            sleep 1
            continue
        fi
        break
    done

    echo "$hostname" > /etc/hostname
    log "$(pad "Hostname set to ${hostname}")"
    return 0
}


# set_pass: sets the user password
set_pass(){
    while true; do
        local root_pass="$(qry_usr "$(pad "Please set root password: ")")"
        
        if [[ -z "$root_pass" ]]; then
            log "$(pad "Invalid password")" 3
            sleep 1
            continue
        fi

        local conf_pass="$(qry_usr "$(pad "Please confirm root password: ")")"

        if [[ "$root_pass" == "$conf_pass" ]]; then
            break
        else
            log "$(pad "Passwords did not match")"
            continue
        fi
    done 

    echo "$root_ass" | passwd -s root
    local pass_stat=$?
    if [[ "$pass_stat" == 0 ]]; then
        log "$(pad "Root password set")" 1
        return 0
    else
        log "$(pad "Error setting root password")" 2
        return 1
    fi
}


# cfg_sys: configure the user system
cfg_sys(){
    gen_fstab "-U"
    chroot
    set_tz
    upd_clk
    clk_sync
    enb_net
    gen_loc
    set_hn
    set_pass
    return 0
}
