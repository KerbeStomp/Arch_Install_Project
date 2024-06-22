#!/bin/bash


# prt_con: prints string to console
# args: string
prt_con(){
    local str="$1"
    echo -e "$str" > /dev/tty
    return $?
}


# pad: adds a tab padding to the front of a string
# args: string
pad(){
    local str="$1"
    local pad_char="\t"
    local pad_str="${pad_char}${str}"
    echo "$pad_str"
    return 0
}


# show_kb: allows keyboard input in the terminal
show_kb(){
	while read -r -t 0.1; do : ; done
	stty ixon ixoff echo icanon
	return 0
}


# hide_kb: disables keyboard input in the terminal
hide_kb(){
	stty -ixon -ixoff -echo -icanon min 1 time 0
	return 0
}


# qry_usr: ask the user a question and get input
# args: message, hide (optional)
qry_usr(){
    local msg="$1"
    local hide="${2:-0}"
    local rsp
    echo -e -n "$msg" > /dev/tty

    show_kb
    if [[ 0 == "$hide" ]]; then
       	read rsp
        echo "$rsp"
    else
        read -s rsp
        echo > /dev/tty
        echo "$rsp"
    fi
    hide_kb
    return 0
}


# set_tz: set the time zone
set_tz(){
    prt_con "$(pad "$(pad "Setting time zone")")"
    ln -sf usr/share/zoneinfo/US/Pacific /etc/localtime > /dev/null 2>&1
    local tz_stat=$?
    if [[ "$tz_stat" == 0 ]]; then
        return 0
    else
        prt_con "$(pad "$(pad "$(pad "Error setting time zone")")")"
        return 1
    fi
}


# upd_clk: update hardware clock
upd_clk(){
    prt_con "$(pad "$(pad "Updating hardware clock")")"
    hwclock --systohc > /dev/null 2>&1
    local tz_stat=$?
    if [[ "$tz_stat" == 0 ]]; then
        return 0
    else
        prt_con "$(pad "$(pad "$(pad "Error updating hardware clock")")")"
        return 1
    fi
}

# clk_sync: enable time synchronization with systemd-timesyncd
clk_sync(){
    prt_con "$(pad "$(pad "Enabling time synchronization")")"
    systemctl enable systemd-timesyncd.service > /dev/null 2>&1
    local sync_stat=$?
    if [[ "$sync_stat" == 0 ]]; then
        return 0
    else
        prt_con "$(pad "$(pad "$(pad "Error enabling time synchronization")")")"
        return 1
    fi
}


# enb_net: enable NetworkManager
enb_net(){
    prt_con "$(pad "$(pad "Enabling NetworkManager")")"
    systemctl enable NetworkManager > /dev/null 2>&1
    local enb_stat=$?
    if [[ "$enb_stat" == 0 ]]; then
        return 0
    else
        prt_con "$(pad "$(pad "$(pad "Error NetworkManager")")")"
        return 1
    fi
}


# gen_loc: generates locales
gen_loc(){
    prt_con "$(pad "$(pad "Generating locales")")"
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
            prt_con "$(pad "$(pad "Invalid hostname")")"
            sleep 1
            continue
        fi
        break
    done

    echo "$hostname" > /etc/hostname
    prt_con "$(pad "$(pad "Hostname set to ${hostname}")")"
    return 0
}


# set_pass: sets the user password
set_pass(){
    while true; do
        local root_pass="$(qry_usr "$(pad "Please set root password: ")" 1)"
        
        if [[ -z "$root_pass" ]]; then
            prt_con "$(pad "$(pad "Invalid password")")"
            sleep 1
            continue
        fi

        local conf_pass="$(qry_usr "$(pad "Please confirm root password: ")" 1)"

        if [[ "$root_pass" == "$conf_pass" ]]; then
            break
        else
            prt_con "$(pad "$(pad "Passwords did not match")")"
            sleep 1
            continue
        fi
    done 

    echo "$root_pass" | passwd -s root
    local pass_stat=$?
    if [[ "$pass_stat" == 0 ]]; then
        prt_con "$(pad "$(pad "Root password set")")"
        return 0
    else
        prt_con "$(pad "$(pad "Error setting root password")")"
        return 1
    fi
}

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


set_grub(){
    local dev="$1"
    local efi="$(chk_esp)"

    if [[ -z "$efi" ]]; then
        # grub with MBR
        grub-install --target=i386-pc "$dev"
    else
        # grub with UEFI
        mount --mkdir "$efi" /mnt/boot > /dev/null 2>&1
        mkdir -p /mnt/boot/EFI/GRUB > /dev/null 2>&1
	prt_con "$(pad "Installing GRUB")"
        grub-install --target=x86_64-efi --efi-directory=/mnt/boot \
            --bootloader-id=GRUB > /dev/null 2>&1
    fi

    # generate grub file
    prt_con "$(pad "Generating GRUB config file")"
    grub-mkconfig -o /boot/grub/grub.cfg > /dev/null 2>&1
    umount /mnt/boot > /dev/null 2>&1
    return 0
}


set_chroot(){
    local dev="$1"
    set_tz
    upd_clk
    clk_sync
    enb_net
    gen_loc
    set_hn
    set_pass
    set_grub "$dev"
    exit
}

dev="$1"
set_chroot "$dev"
