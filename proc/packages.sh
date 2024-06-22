#!/bin/bash


# get_inst_type: gets an install type depending on user input
# args: install type
get_inst_type(){
	local inst_type="$1"

	if [[ "$inst_type" == 1 ]]; then
		echo 1
		return 0
	elif [[ "$inst_type" == 2 ]]; then
		echo 2
		return 0
	elif [[ "$inst_type" == 3 ]]; then
		echo 3
		return 0
else
	echo -1
	return 1
	fi
}


# inst_pkgs: installs necessary and user packages
inst_pkgs(){
	while true; do
	log "$(pad "1) Regular")"
	log "$(pad "2) AMD microcode")"
	log "$(pad "3) Intel microcode")"
	local inst_type="$(get_inst_type "$(qry_usr "$(pad\
		"Pick an installation type: ")")")"
	if [[ "$inst_type" == -1 ]]; then
		log "$(pad "Invalid type specified\n")"
		sleep 1
		continue
	fi

	log "$(pad "Installing packages, please wait...")"
    local core_pkgs="base linux linux-firmware vim networkmanager man-db \
        man-pages texinfo grub efibootmgr"
	if [[ "$inst_type" == 1 ]]; then
		pacstrap -K /mnt $core_pkgs > /dev/null 2>&1
		local pkgs_stat=$?
	elif [[ "$inst_type" == 2 ]]; then
		pacstrap -K /mnt $core_pkgs amd-ucode > /dev/null 2>&1
		local pkgs_stat=$?
	elif [[ "$inst_type" == 3 ]]; then
		pacstrap -K /mnt  $core_pkgs intel-ucode > /dev/null 2>&1
		local pkgs_stat=$?
	fi

	if [[ "$pkgs_stat" == 0 ]]; then
		return 0
	else
		return 1
	fi
done
}
