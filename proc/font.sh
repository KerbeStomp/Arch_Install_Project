#!/bin/bash
# Use Terminus-16 in chroot; note for chroot module


# get_dflt_font: gets the default terminal font
get_dflt_font(){
	local dflt_font="ter-v24n"
	echo "$dflt_font"
	return 0
}


# set_font: sets the terminal font
set_font() {
    log "$(pad "Setting terminal font")"
    local font=$(get_dflt_font)
    if setfont "$font"; then
        return 0
    else
        log "$(pad "Error setting terminal font")" 3
        return 2
    fi
}
