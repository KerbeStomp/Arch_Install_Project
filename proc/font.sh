#!/bin/bash
# Use Terminus-16 in chroot; note for chroot module
DEFAULT_FONT="ter-v32n"

set_font() {
    # echo -e "\nSetting terminal font to $DEFAULT_FONT."
    # Should this print to console always, or should it just preform the function
    # Module functions should only preform their purpose; logging should be handled by entry.sh
    # Reasoning: debug functions are not sourced directly, so modules should preform by themselves
    if setfont "$DEFAULT_FONT"; then
        return $FONT_OK
    else
        return $FONT_ERR
    fi
}