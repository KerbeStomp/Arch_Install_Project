#!/bin/bash


# get_dflt_kb_layout: gets the default keyboard layout
get_dflt_kb_layout(){
	local dflt_kb_layout="us"
	echo "$dflt_kb_layout"
	return 0
}


# set_keyboard_layout: sets the keyboard layout
set_kb() {
    log "$(pad "Setting keyboard layout")"
    local dft_kb_layout="$(get_dflt_kb_layout)"
    if loadkeys $dft_kb_layout; then
        return 0
    else
        log "$(pad "Error setting keyboard layout")" 3
        return 1
    fi
}
