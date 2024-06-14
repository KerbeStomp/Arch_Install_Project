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


# pad: adds a tab padding to the front of a string
# args: string
pad(){
    local str="$1"
    local pad_char="\t"
    local pad_str="${pad_char}${str}"
    echo "$pad_str"
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
    local max_idx="$((${#arr[@]} - 1))"
    if val_idx "$idx" "$max_idx"; then
        echo "${arr[$idx]}"
        return 0
    else
        return 1
    fi
}


# add_sev: appends a severity to string, seprareted by a pipe
# args: string, severity index
add_sev(){
    local str="$1"
    local sev_idx="$2"
    # 0=INFO; 1=OK; 2=ERROR; 3=WARN
    local sev_arr=("INFO" "OK" "ERROR" "WARN")
    local sev=$(get_elem "$sev_idx" "${sev_arr[@]}")

    if [[ -z "$sev" ]]; then
        echo "${str}|UNKN"
        return 1
    fi

    local new_str="${str}|${sev}"
    echo "$new_str"
    return 0
}


# get_ts: gets timestamp with specified format
# args: format
get_ts(){
    local fmt="$1"
    local ts="$(date +"$fmt")"
    echo "$ts"
    return 0
}


# add_ts: appends a timestamp to string, separeated by a pipe
# args: string, format
add_ts(){
    local str="$1"
    local fmt="$2"
    local ts="$(get_ts "$fmt")"
    local new_str="${str}|${ts}"
    echo "$new_str"
    return 0
}


# add_info: adds timestamp and severity to string
# args: string, severity index
add_info(){
    local str="$1"
    local sev_idx="$2"
    local info_str="$(add_ts "$(add_sev "$str" "$sev_idx")" "%X")"
    echo "$info_str"
    return 0
}


# fmt_str: formats a string for logging purposes
# args: string
fmt_str(){
    local str="$1"
    local fmt_str="$(awk -F '|' '{ printf \
        "%-10s %7s | %s\n", "["$3"]", "["$2"]", $1 }' <<< "$str")"
    echo "$fmt_str"
    return 0
}


# prt_con: prints string to console
# args: string
prt_con(){
    local str="$1"
    echo -e "$str" > /dev/tty
    return $?
}


# prt_dbg: prints string to debug file
# args: string
prt_dbg(){
    local str="$1"
    echo -e "$str" >> "$LOG_FILE"
    return $?
}


# log: prints string to both the console and a debug file
# args: string, severity index (optional)
log(){
    local str="$1"
    local sev_idx="${2:-0}"
    local dbg_str="$(fmt_str "$(add_info "$str" "$sev_idx")")"

    prt_con "$str"
    prt_dbg "$dbg_str"
    return 0
}


# qry_usr: ask the user a question and get input
# args: message, hide (optional)
qry_usr(){
    local msg="$1"
    local hide="${2:-0}"
    local rsp
    echo -e -n "$msg" > /dev/tty

    if [[ 0 == "$hide" ]]; then
        read -e rsp
        prt_dbg "$(fmt_str "$(add_info "$msg" 0)")${rsp}"
        echo "$rsp"
        return 0
    else
        read -e -s rsp
        echo > /dev/tty
        prt_dbg "$(fmt_str "$(add_info "$msg" 0)")"
        echo "$rsp"
        return 0
    fi
}


# wait_usr: prints prompt to user and waits for keypress
# args: message
wait_usr(){
    local msg="$1"
    echo -e -n "$msg" > /dev/tty
    prt_dbg "$(fmt_str "$(add_info "$msg" 0)")"
    read -n 1 -s
    return 0
}


LOG_FILE=$(gen_log_file)
prt_con "Log file located at: ${LOG_FILE}\n"
