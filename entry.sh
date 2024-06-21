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
    if [[ "$stat" == 1 || "$stat" == 127 ]]; then
        log "$(pad "Fatal error encounted in ${proc_func}...")" 2
        return 1
    elif [[ "$stat" == 2 ]]; then
        log "$(pad "Non-fatal error encountered in ${proc_func}...")" 3
        return 2
    else
        log "$(pad "Successfully exited ${proc_func}")" 1
	return 0
    fi

}


# entry: entry point for Arch install
# args: error codes, script dir
entry(){
    local proc_name=("Font" "Keyboard" "Verify Boot" "Network Setup"\
        "System Clock" "Disk Setup" "Install Packages"\
        "Configure System" "Bootloader")
    local proc_func=("set_font" "set_kb" "verify_boot" "set_net" "set_clk"\
        "set_dev" "inst_pkgs" "cfg_sys" "bootldr")

    hide_kb
    log "Starting Arch installation"
    log ""

    for proc in {0..8}; do
	    log_proc "${proc_name[${proc}]}" "${proc_func[${proc}]}"
	    local proc_stat=$?
        log ""

        if [[ "$proc_stat" == 1 ]]; then
            log "Error during installation..." 2
            log ""
            return 1
        fi
    done

    show_kb
    return 0
}

