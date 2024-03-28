#`!/bin/bash

# install.sh handles the permissions and sourcing
# necessary to run the install

# get_inst_dir: gets install directory
# args: install directory (optional)
get_inst_dir(){
	local dir="${1:-.}"
	echo "$dir"
	return 0
}


# get_path: makes file path by subpath to directory
# args: directory, subpath
get_path(){
	local dir="$1"
	local subpath="$2"
	echo "${dir}/${subpath}"
	return 0
}


# get_files: gets all .sh files in a directory
# args: file directory
get_files(){
	local dir="$1"
	if [[ -d "$dir" ]]; then
		local files=($(find "$dir" -type f -name "*.sh"))
		echo "${files[@]}"
		return 0
	else
		return 1
	fi
}


# file_perms: enables execute permissions for a file
# args: file path
file_perms(){
	local file="$1"
	if [[ -f "$file" ]]; then
		chmod +x "$file"
		return 0
	else
		return 152
	fi
}


# src_file: sources file into current script
src_file(){
	local file="$1"
	if [[ -f "$file" ]]; then
		source "$file"
	else
		return 1
	fi
	return 0
}


# map: apply function to array of items
# args: function, array
map(){
	local func="$1"
	shift
	for item in "$@"; do
		"$func" "$item" || return 1
	done
	return 0
}


# filter: filter array based on condition function
# args: condition function, array
filter(){
	local cond="$1"
	shift
	local in_arr=("$@")
	local out_arr=()

	for item in "${in_arr[@]}"; do
		if "$cond" "$item"; then
			out_arr+=("$item")
		fi
	done
	echo "${out_arr[@]}"
}

# is_needed: determine if a .sh is needed for install
# args: file path
is_needed(){
	local file="$1"
	return 1
}


# start_install: sources necessary files and starts install
start_install(){
	# get file paths
	local inst_dir=$(get_inst_dir)
	local dbg_path=$(get_path "$inst_dir" "debug.sh")
	local exit_path=$(get_path "$inst_dir" "exit_codes.sh")
	local proc_path=$(get_path "$inst_dir" "proc")
	local proc_files=($(get_files "$proc_path"))
	local flt_files=($(filter is_needed ${proc_files[@]}))
	local entry_path=$(get_path "$inst_dir" "entry.sh")

	# enable execute permissions
	file_perms "$dbg_path" || return 1
	file_perms "$exit_path" || return 1
	map file_perms "${flt_files[@]}" || return 1
	file_perms "$entry_path" || return 1

	# source files
	src_file "$dbg_path" || return 1
	src_file "$exit_path" || return 1
	map src_file "${flt_files[@]}" || return 1
	src_file "$entry_path" || return 1

	echo "${flt_files[@]}"

	return -1
	entry
}

start_install
exit_status="$?"
echo "Exit status: "${exit_status}
