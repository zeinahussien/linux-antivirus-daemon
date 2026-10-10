#!/bin/bash

script_dir="$(cd "$(dirname "$0")" && pwd)"
whitelist="$script_dir/whitelist.txt"
touch "$whitelist"

last="$script_dir/directory-info.last"
new="$script_dir/directory-info.new"

target_dir=$1
malicious_dir=$2
interval_sec=$3

mkdir -p "$malicious_dir"

scan_files() {
        for file in "$target_dir"/*
        do
            [ -f "$file" ] || continue
            name=$(basename "$file")
            if grep -Fxq -- "$name" "$whitelist"
            then
                echo "$file is whitelisted and SKIPPED"
            
            elif [[ "$file" == *.exe || "$file" == *.bat || "$file" == *.vbs || "$file" == *.scr || "$file" == *.ps1 ]] || grep -qiE "virus|trojan|malware|worm|ransomware" "$file"
            then
                echo  "$file is malicious and DELETED"
                cp "$file" "$malicious_dir" && rm "$file"
            fi
        done
}

if  [[ -f "$last" ]]
then
    ls -l "$target_dir" > "$new"
    if ! cmp -s "$last" "$new" 
    then
        scan_files
        ls -l "$target_dir" > "$last"
    fi
else
    scan_files 
    ls -l "$target_dir" > "$last" 
fi