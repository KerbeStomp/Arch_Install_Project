#!/bin/bash

# entry.sh holds the main code for the install process



# entry: entry point for Arch install
# args: error codes, script dir
entry(){
	FUNCS=("set_font", "set_kb", "vboot", "set_net", "set_clk", "part_disk", "fmt_disk", "mnt_disk", "ipkgs", "cfg_sys", "bootldr")

	log "Starting Install"
	
	return 0
}

