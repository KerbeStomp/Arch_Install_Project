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
	elif [[ "$inst_type" == 4 ]]; then
		echo 4
		return 0
else
	echo -1
	return 1
	fi
}


# inst_pkgs: installs necessary and user packages
inst_pkgs(){
	while true; do
	log "$(pad "1) Minimal")"
	log "$(pad "2) Regular")"
	log "$(pad "3) AMD microcode")"
	log "$(pad "4) Intel microcode")"
	local inst_type="$(get_inst_type "$(qry_usr "$(pad\
		"Pick an installation type: ")")")"
	if [[ "$inst_type" == -1 ]]; then
		log "$(pad "Invalid type specified\n")"
		sleep 1
		continue
	fi

	log "$(pad "Installing packages, please wait...")"
    local core_pkgs="base base-devel linux linux-firmware vim networkmanager \
        man-db man-pages texinfo grub efibootmgr sudo vivaldi git"
    local disp_pkgs="hyprland kitty pipewire pipewire-alsa pipwire-pulse \
        pipewire-jack wireplumber qt5-wayland qt6-wayland \
        xdg-desktop-portal-hyprland xdg-desktop-portal-gtk \
        network-manager-applet hyprpaper hypridle hyprlock wofi \
        udiskie waybar"
	if [[ "$inst_type" == 1 ]]; then
		pacstrap -K /mnt $core_pkgs > /dev/null 2>&1
		local pkgs_stat=$?
    elif [[ "$inst_type" == 2 ]]; then
		pacstrap -K /mnt $core_pkgs $disp_pkgs > /dev/null 2>&1
		local pkgs_stat=$?
	elif [[ "$inst_type" == 3 ]]; then
		pacstrap -K /mnt $core_pkgs $disp_pkgs amd-ucode > /dev/null 2>&1
		local pkgs_stat=$?
	elif [[ "$inst_type" == 4 ]]; then
		pacstrap -K /mnt  $core_pkgs $disp_pkgs intel-ucode > /dev/null 2>&1
		local pkgs_stat=$?
	fi

	if [[ "$pkgs_stat" == 0 ]]; then
		return 0
	else
		return 1
	fi
done
}
