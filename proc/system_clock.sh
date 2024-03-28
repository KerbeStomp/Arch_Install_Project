#!/bin/bash

# update system clock
update_clock() {
    if timedatectl set-ntp true; then
        return CLK_OK 
    else
        return CLK_ERR
    fi
}