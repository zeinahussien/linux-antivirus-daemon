#!/bin/bash
script_dir="$(cd "$(dirname "$0")" && pwd)"
whitelist="$script_dir/whitelist.txt"
touch "$whitelist"

target_dir=$1
malicious_dir=$2


while true 
do
    if [[ ! -d "$malicious_dir" || -z "$(ls "$malicious_dir")" ]]
    then
    echo "No malicious files to review."
    exit 0
    fi

    echo "Files in $malicious_dir:"
    ls -l "$malicious_dir"

    handled=0
    select file in "$malicious_dir"/*
    do
        handled=1
        if [ -z "$file" ]
        then
            echo "Invalid selection. Please try again."
            break
        fi

        echo "You selected: $file"
        echo "Choose an action:"
        echo "1. Restore the file to $target_dir"
        echo "2. Delete the file permanently"
        echo "3. Skip / Leave the file as-is"
        echo "4. Exit"

        while true
        do
            read -r -p "Enter your choice (1, 2, 3, or 4):" choice || exit 0
            case $choice in
                1)
                    if mv "$file" "$target_dir/"
                    then
                        echo "Restored $file to $target_dir"
                        echo "$(basename "$file")" >> "$whitelist"
                    fi
                    break 2;;
                2)
                    rm "$file" && echo "Permanently deleted $file"
                    break 2;;
                3)
                    echo "Skipped $file"
                    break 2;;
                4) 
                    echo "Exiting the review process."
                    exit 0
                    ;;
                *)
                    echo "Invalid choice. Please try again."
                    ;;
            esac
        done
    done

    if [ $handled -eq 0 ]
    then
        exit 0
    fi
done