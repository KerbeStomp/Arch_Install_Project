#!/bin/bash
# Use Terminus-16 in chroot
DEFAULT_FONT="ter-v18n"

set_font() {
    echo -e "\nSetting terminal font to $DEFAULT_FONT."
    if setfont "$DEFAULT_FONT"; then
        return $FONT_OK
    else
        return $FONT_ERR
    fi
}
