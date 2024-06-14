#!/bin/bash


# debug.sh holds functions used for printing to console and debug files


# gen_uniq_fn: generates a unique filename
gen_uniq_fn(){
    local proc_name="AIP"
    local ts="$(get_ts "%y%m%d_%H%M%S")"
    local filename="${proc_name}_${ts}.log"
    if [ ! -e "$filename" ]; then
        echo "$filename"
        return 0
    else
        return 1
    fi
}


# gen_log_dir: generates a directory to hold log files
gen_log_dir(){
    local dir="logs"
    mkdir -p "$dir"
    echo "$dir"
    return 0
}


# gen_log_file: generates a log file to record debug information
gen_log_file(){
    local dir="$(gen_log_dir)"
    local file="$(gen_uniq_fn)"
    if [ -z "$file" ]; then
        local dflt_log="./${dir}/default_$(date +%H%M%S).log"
        echo "${dflt_log}"
        return 1
    else

        echo "./${dir}/$file"
        return 0
    fi
}


# gen_pad: creates padding of spaces
# args: pad level
gen_pad(){
    local pad_lvl="$1"
    local pad=$(printf "%*s" "$pad_lvl" "")
    echo "$pad"
    return 0
}


# rplc_spc: replaces all space a string with a character
# args: string, character 
rplc_spc(){
    local str="$1"
    local char="$2"
    local new_str=$(echo "$str" | tr ' ' $char)
    echo "$new_str"
    return 0
}


# add_pad: adds padding to the front of a string
# args: string, pad level (optional), padding char (optional)
add_pad(){
    local str="$1"
    local pad_lvl="${2:-0}"
    local pad_char="${3:-\t}"
    local pad=$(gen_pad "$pad_lvl")
    local new_pad=$(rplc_spc "$pad" "$pad_char")
    local new_str="${new_pad}${str}"
    echo "$new_str"
    return 0
}


# val_idx: checks if an index is valid
# args: index, max index
val_idx(){
    local idx="$1"
    local max_idx="$2"
    if [[ "$idx" -ge 0 && "$idx" -le "$max_idx" ]]; then
        return 0
    else
        return 1
    fi
}


# get_elem: gets an item from an array based on an index
# args: index, array
get_elem(){
    local idx="$1"
    shift
    local arr=("$@")
    local max_idx=$((${#arr[@]} - 1))
    if val_idx "$idx" "$max_idx"; then
        echo "${arr[$idx]}"
        return 0
    else
        return 1
    fi
}


# add_tag: applys tag to string for logging, separated by pipe |
# args: string, tag index
add_tag(){
    local str="$1"
    local tag_idx="$2"
    # 0=DEBUG; 1=OK; 2=INFO; 3=WARN; 4=ERROR; 5=UKWN
    local tag_arr=("INFO" "OK" "ERROR" "WARN")
    local tag=$(get_elem "$tag_idx" "${tag_arr[@]}")
    local new_str="${tag}|${str}"
    echo "$new_str"
    return 0
}


# get_ts: gets timestamp with specified format
# args: format
get_ts(){
    local fmt="$1"
    local ts=$(date +"$fmt")
    echo "$ts"
    return 0
}


# add_ts: adds timestamp to the beginning of a string, separeated by pipe |
# args: string, format
add_ts(){
    local str="$1"
    local fmt="$2"
    local ts=$(get_ts "$fmt")
    local new_str="${ts}|${str}"
    echo "$new_str"
    return 0
}


# add_info: adds timestamp and debug tag to string
# args: string, tag index
add_info(){
    local str="$1"
    local tag_idx="$2"
    local tag_str=$(add_tag "$str" "$tag_idx")
    local ts_tag_str=$(add_ts "$tag_str" "%X")
    echo "$ts_tag_str"
    return 0
}


# fmt_str: formats a string for logging purposes
# args: string
fmt_str(){
    local str="$1"
    local fmt_str=$(awk -F '|' '{ printf \
        "%-10s %-7s | %s\n", "["$1"]", "["$2"]", $3 }' <<< "$str")
            echo "$fmt_str"
            return 0
        }


# prt_con: prints string to console
# args: string
prt_con(){
    local str="$1"
    if echo "$str"; then
        return 0
    else
        return 1
    fi
}



# prt_file: prints string to file
# args: string, file
prt_file(){
    local str="$1"
    local file="$2"
    if echo "$str" >> "$file"; then
        return 0
    else
        return 1
    fi
}


# log: prints string to both console and debug file
# args: string, tag index (optional), pad level (optional), file (optional)
log(){
    local str="$1"
    local tag_idx="${2:-0}"
    local pad_lvl="${3:-0}"
    local file="${4:-$LOG_FILE}"
    local con_str=$(add_pad "$str" "$pad_lvl")
    local dbg_str=$(add_info "$con_str" "$tag_idx")
    local fmt_dbg_str=$(fmt_str "$dbg_str")

    prt_con "$con_str"
    prt_file "$fmt_dbg_str" "$file"
    return 0
}

LOG_FILE=$(gen_log_file)
echo "Log file located at: ${LOG_FILE}"
