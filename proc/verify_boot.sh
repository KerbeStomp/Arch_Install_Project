#!/bin/bash


# get_bitness: get the UEFI bitness
get_bitness(){
	local file="/sys/firmware/efi/fw_platform_size"
	if [[ ! -e "$file" ]]; then
		return 1
	else
		return 0
	fi
}


# verify_boot: verifies the current boot mode
verify_boot() {
    log "$(pad "Verifying boot mode")"
    if get_bitness; then
        log "$(pad "UEFI boot mode detected")"
        return 0
    else
        log "$("BIOS boot mode detected")" 
        return 0
    fi
}
