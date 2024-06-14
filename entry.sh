#!/bin/bash


# entry.sh holds the main code for the install process


# log_proc: runs and logs an install process
# args: process name, process function
log_proc(){
    local proc_name="$1"
    local proc_func="$2"
    log "Step: ${proc_name}" 1
    "$proc_func"
    local stat=$?
    log "${proc_func} exited with status ${stat}" 0 1
    return 0
}


# entry: entry point for Arch install
# args: error codes, script dir
entry(){
    local proc_name=("Font" "Keyboard" "Verify Boot" "Network Setup"\
        "System Clock" "Disk Partition" "Disk Format" "Mount Disks"\
        "Install Packages" "Configure System" "Bootloader")
	local proc_func=("set_font" "set_kb" "vboot" "set_net" "set_clk"\
        "part_disk" "fmt_disk" "mnt_disk" "ipkgs"\
        "cfg_sys" "bootldr")

    for proc in {0..1}; do
        log_proc "${proc_name[${proc}]}" "${proc_func[${proc}]}"
    done

    return 0
}

