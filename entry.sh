#!/bin/bash


# entry.sh holds the main code for the install process


# log_proc: runs and logs an install process
# args: process name, process function
log_proc(){
    local proc_name="$1"
    local proc_func="$2"
    log "Stage: ${proc_name}"
    "$proc_func"
    local stat=$?
    if [[ "$stat" == 1 ]]; then
        log "Fatal error encounted in ${proc_func}" 2 1
        return 1
    elif [[ "$stat" == 2 ]]; then
        log "Non-fatal error encountered in ${proc_func}..." 3 1
        return 2
    else
	log "Successfully exited ${proc_func}" 1 1
	return 0
    fi

}


# entry: entry point for Arch install
# args: error codes, script dir
entry(){
    local proc_name=("Font" "Keyboard" "Verify Boot" "Network Setup"\
        "System Clock" "Disk Partition" "Disk Format" "Mount Disks"\
        "Install Packages" "Configure System" "Bootloader")
    local proc_func=("set_font" "set_kb" "verify_boot" "set_net" "set_clk"\
        "part_disk" "fmt_disk" "mnt_disk" "inst_pkgs" "cfg_sys" "bootldr")

    prt_con ""
    log "Starting Arch Install"
    prt_con ""

    for proc in {0..1}; do
        log_proc "${proc_name[${proc}]}" "${proc_func[${proc}]}"
        local proc_stat=$?
        prt_con ""

        if [[ proc_stat -eq 1 ]]; then
            log "Error during installation..." 2
            prt_con ""
            return 1
        fi
    done

    return 0
}

