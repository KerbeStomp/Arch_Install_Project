#!/bin/bash
# Use Terminus-16 in chroot; note for chroot module

# get_dflt_font: gets default font used for terminal
get_dflt_font(){
	local dflt_font="ter-v32n"
	echo "$dflt_font"
	return 0
}


set_font() {
    # echo -e "\nSetting terminal font to $DEFAULT_FONT."
    local font=$(get_dflt_font)
    if setfont "$font"; then
        return 0
        return 1
    fi
}
