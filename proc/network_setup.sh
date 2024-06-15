#!/bin/bash


# get_intf: gets a specified network interface
# args: interface name
get_intf(){
	local intf_name="$1"
	local intf="$(ip link | grep "$intf_name" | awk '{ print $2 }' |\
		tr -d ':' | head -n 1)"
	if [[ -z "$intf" ]]; then
		return 1
	else
		echo "$intf"
		return 0
	fi
}


# chk_conn: checks if a network interface is connected
# args: network interface
chk_conn(){
	local net_intf="$1"
	local conn_file="/sys/class/net/${net_intf}/carrier"

	if [[ ! -e "$conn_file" ]]; then
		return 1
	fi

	local conn="$(cat "$conn_file")"

	if [[ 0 == "$conn" ]]; then
		return 1
	elif [[ 1 == "$conn" ]]; then
		return 0
	fi
}


# wait_eth: waits until an ethernet connection is established or a key is pressed
# args: network interface
wait_eth(){
	local intf="$1"
    log "$(pad "Please plug in ethernet cable. Press any key to skip.")"
	while true; do
		chk_conn "$intf"
		local ref_conn=$?

		if [[ 0 == "$ref_conn" ]]; then
            log "$(pad "Successfully connected")" 1 
			return 0
		fi

		if read -t 0.1 -n 1 -s; then
            log "$(pad "Skipping ethernet")" 1
			return 1
		fi
	done
}


# try_eth: attempt a ethernet connection
try_eth(){
	local eth_intf="$(get_intf " en\| eth")"

	if [[ -z "$eth_intf" ]]; then
        log "$(pad "No ethernet interface detected")" 3
		return 1
	fi

	chk_conn "$eth_intf"
	local conn=$?

	if [[ 1 == "$conn" ]]; then
		wait_eth "$eth_intf"
		return $?
	elif [[ 0 == "$conn" ]]; then
        log "$(pad "Ethernet plugged in.")" 1
		return 0
	fi
}


# start_iwd: starts iwd service
start_iwd(){
	systemctl start iwd  > /dev/null 2>&1
	local iwd_stat=$?

	if [[ 5 == "$iwd_stat" ]]; then
		return 1
	fi

	return 0
}


# scan_net: scan for networks
# args: network interface
scan_net(){
	local net_intf="$1"
	
	iwctl station "$net_intf" scan > /dev/null 2>&1
	local stat=$?

	if [[ 1 == "$stat" ]]; then
        log "$(pad "Error scanning networks")" 2
		return 1
	fi

	return 0
}


# get_net: get an array of networks
# args: network interface
get_net(){
	local wifi_intf="$1"
	scan_net "$wifi_intf"
	local net_arr=($(iwctl station "$wifi_intf" get-networks |\
		sed 's/\x1b\[0m//g' | awk 'NR>4 {print $1}'|\
		head -n 25))
	echo "${net_arr[@]}"
}


# show_net: show scanned networks
# args: network list
show_net(){
	local net_list=("$@")
    log "$(pad "Avaliable Networks")"
	for i in "${!net_list[@]}"; do
        log "$(pad "$(printf "%3d) %s\n" $((i+1)) "${net_list[$i]}")")"
	done
	return 0
	}


# chk_ssid: check if a SSID is valid
# args: SSID, network interface
chk_ssid(){
    local ssid="$1"
    shift
    local ssid_list=("$@")

    for item in "${ssid_list[@]}"; do
        if [[ "$ssid" == "$item" ]]; then
            return 0
        fi
    done

    return 1
}


# try_net: attempt a network connection with a SSID and password
# args: network interface, SSID, password
try_net(){
	local net_intf="$1"
	local ssid="$2"
	local pass="$3"

	iwctl --passphrase "$pass" station "$net_intf" connect "$ssid" > /dev/null 2>&1
	local conn=$?

	if [[ 1 == "$conn" ]]; then
		log "$(pad "Failed to connect to ${ssid}")"
		return 1
	elif [[ 0 == "$conn" ]]; then
		log "$(pad "Successfully connected to ${ssid}")"
		return 0
	fi
}


# wait_wifi: waits until a wifi connection is established
# args: network interface
wait_wifi(){
    # set up wifi
    	local wifi_intf="$1"
	start_iwd
	local iwd_stat=$?
	if [[ 1 == "$iwd_stat" ]]; then
		log "$(pad "Error with wifi daemon")" 2
		return 1
	fi

	while true; do
		local net_list=($(get_net "$wifi_intf"))
		show_net "${net_list[@]}"

		local ssid="$(qry_usr "$(pad "Please enter an SSID: ")")"

    		chk_ssid "$ssid" "${net_list[@]}"
    		local val_ssid=$?

    		if [[ "$val_ssid" == 1 ]]; then
			log "$(pad "Invalid SSID inputted")" 3
			continue
    		fi

		local pass="$(qry_usr\
		"$(pad "Please enter password for ${ssid}: ")" 1)"

		if try_net "$wifi_intf" "$ssid" "$pass"; then
			return 0
		fi

	done
}


# try_wifi: attempt a wifi connection
try_wifi(){
	local wifi_intf="$(get_intf " wl")"

	if [[ -z "$wifi_intf" ]]; then
		log "$(pad "No wifi interface detected")" 3
		return 1
	fi

	chk_conn "$wifi_intf"
	local wifi_conn=$?

	if [[ 1 == "$wifi_conn" ]]; then
		wait_wifi "$wifi_intf"
		return $?
	else
		log "$(pad "Wifi connected")" 1
		return 0
	fi
}


# set_net: set up a network connection
set_net(){
    log "Starting network setup"
	if try_eth; then
		return 0
	elif try_wifi; then
		return 0
	else
		return 1
	fi
	}
