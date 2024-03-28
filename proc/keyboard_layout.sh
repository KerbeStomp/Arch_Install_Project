#!/bin/bash
DEFAULT_LAYOUT=us

#set keyboard layout
set_keyboard_layout() {
    echo -e "\tSetting keyboard layout to $DEFAULT_LAYOUT."
    if loadkeys $DEFAULT_LAYOUT; then
        return $KB_OK
    else
        return $KB_ERR 
    fi
}