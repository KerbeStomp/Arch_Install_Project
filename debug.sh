#!/bin/bash

# log.sh holds functions used for printing to console and debug files


# gen_pad: creates padding of spaces
# args: pad level
gen_pad(){
	local pad_lvl="$1"
	local pad=$(printf "%*s" $pad_lvl "") # create padding of width pad_lvl
	echo "$pad"
	return 0
}

# rplc_spc: replace spaces in a string with a character
# args: string, character 
rplc_spc(){
	local str="$1"
	local char="$2"
	echo "$str" | tr ' ' "$char"
	return 0
}

# pad_str: adds padding to the front of a string
# args: string, pad level (optional), padding char (optional)
pad_str(){
	local str="$1"
	local pad_lvl="${2:-0}"
	local pad_char="${3:-$'\t'}"
	local pad=$(gen_pad $pad_lvl)
	local new_pad=$(rplc_spc $pad_char)
	local new_str="${new_pad}${str}"
	echo "$new_str"
	return 0
}


# val_tag: validates tag index based on max index
# args: tag index, max index
val_tag(){
	local tag_idx="$1"
	local max_idx="$2"
	if [[ tag_idx -ge 0 && tag_idx -lt max_idx ]]; then
		return 0
	else
		return 1
	fi
}


# get_tag: determines the tag used for a message
# args: tag index
get_tag(){
	local tag_idx="$1"
	local tag_arr=("DEBUG" "OK" "INFO" "WARN" "ERROR" "UKWN")
	local max_idx=$((${#tag_arr[@]} - 1))
	if val_tag $tag_idx $max_idx; then
		echo "${tag_arr[$tag_idx]}"
		return 0
	else
		echo "UKWN"
		return 1
	fi
}


# get_ts: get timestamp
# args: format (optional)
get_ts(){
	local fmt="${1:-"%D %T"}"
	local ts=$(date +"$fmt")
	echo "$ts"
	return 0
}


# fmt_str: format string for logging
# args: string, tag index (optional)
fmt_str(){
	local str="$1"
	local tag_idx="${2:-0}"
	local tag=$(get_tag $tag_idx)
	local ts=$(get_ts)
	local new_str="[${ts}] - [${tag}] |${str}"
	echo "$new_str"
	return 0
}


# prt_con: prints string to console
# args: string
prt_con(){
	local str="$1"
	if echo -e "$str\n"; then
		return 0
	else
		return 1
	fi
}


# prt_dbg: print string to debug file
# args: string, debug file (optional)
prt_dbg(){
	local str="$1"
	local file="${2:-./debug.log}"
	if echo "$str" >> "$file"; then
		return 0
	else
		return 1
	fi
}


# log: prints string to both console and debug file
# args: string, tag index (optional), debug file (optional)
# (optional)
log(){
	local str="$1"
	local tag_idx="${2:-0}"
	local file="${3:-./debug.log}"
	local con_str=$(pad_str "$str")
	local dbg_str=$(fmt_str "$con_str" "$tag_idx")

	prt_con "$con_str"
	prt_dbg "$dbg_str" "$file"
	return 0
}


# add_ts: adds timestamp to the beginning of a string
# args: string, format (optional)
add_ts(){
	local str="$1"
	local fmt="${2:-'%D %T'}"
	local ts=$(get_ts $fmt)
	local new_str="[$ts] - $str"
	echo "$new_str"
	return 0
}


# add_tag: applys tag to string for logging
# args: string, tag index (optional)
add_tag(){
	local str="$1"
	local tag_idx="${2:-0}"
	local tag=$(get_tag $tag_idx)
	local new_str="[$tag] | $str"
	echo "$new_str"
	return 0
}
