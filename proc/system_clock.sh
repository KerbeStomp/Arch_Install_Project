#!/bin/bash

# set_clk: sets the systemclock
set_clk()
{
	timedatectl > /dev/null 2>&1
	clk_stat=$?
    if [[ "$clk_stat" == 0 ]]; then
	    log "$(pad "Set system clock")" 1
        return 0 
    else
	    log "$(pad "Unable to set system clock...")" 3
        return 1
    fi
}
