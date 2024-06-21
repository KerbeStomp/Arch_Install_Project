#!/bin/bash


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
    echo "$(pad "Setting time zone")"
    ln -sf usr/share/zoneinfo/US/Pacific /etc/localtime > /dev/null 2>&1
    local tz_stat=$?
    if [[ "$tz_stat" == 0 ]]; then
        return 0
    else
        echo "$(pad "Error setting time zone")"
        return 1
    fi
}


# upd_clk: update hardware clock
upd_clk(){
    echo "$(pad "Updating hardware clock")"
    hwclock --systohc > /dev/null 2>&1
    local tz_stat=$?
    if [[ "$tz_stat" == 0 ]]; then
        return 0
    else
        echo "$(pad "Error updating hardware clock")"
        return 1
    fi
}

# clk_sync: enable time synchronization with systemd-timesyncd
clk_sync(){
    echo "$(pad "Enabling time synchronization")"
    systemctl enable systemd-timesyncd.service > /dev/null 2>&1
    local sync_stat=$?
    if [[ "$sync_stat" == 0 ]]; then
        return 0
    else
        echo "$(pad "Error enabling time synchronization")"
        return 1
    fi
}


# enb_net: enable NetworkManager
enb_net(){
    echo "$(pad "Enabling NetworkManager")"
    systemctl enable NetworkManager > /dev/null 2>&1
    local enb_stat=$?
    if [[ "$enb_stat" == 0 ]]; then
        return 0
    else
        echo "$(pad "Error NetworkManager")" 
        return 1
    fi
}


# gen_loc: generates locales
gen_loc(){
    echo "$(pad "Generating locales")"
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
            echo "$(pad "Invalid hostname")" 
            sleep 1
            continue
        fi
        break
    done

    echo "$hostname" > /etc/hostname
    echo "$(pad "Hostname set to ${hostname}")"
    return 0
}


# set_pass: sets the user password
set_pass(){
    while true; do
        local root_pass="$(qry_usr "$(pad "Please set root password: ")")"
        
        if [[ -z "$root_pass" ]]; then
            echo "$(pad "Invalid password")" 
            sleep 1
            continue
        fi

        local conf_pass="$(qry_usr "$(pad "Please confirm root password: ")")"

        if [[ "$root_pass" == "$conf_pass" ]]; then
            break
        else
            echo "$(pad "Passwords did not match")"
            sleep 1
            continue
        fi
    done 

    echo "$root_pass" | passwd -s root
    local pass_stat=$?
    if [[ "$pass_stat" == 0 ]]; then
        echo "$(pad "Root password set")"
        return 0
    else
        echo "$(pad "Error setting root password")"
        return 1
    fi
}


set_chroot(){
    set_tz
    upd_clk
    clk_sync
    enb_net
    gen_loc
    set_hn
    set_pass
    exit
}

set_chroot
