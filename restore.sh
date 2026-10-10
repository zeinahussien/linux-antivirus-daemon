#!/bin/bash

target_dir=$1
malicious_dir=$2

echo "Files in $malicious_dir:"
ls -l "$malicious_dir"

if [[ ! -d "$malicious_dir" || -z "$(ls -A "$malicious_dir")" ]]
then
    echo "No malicious files to review."
    exit 0
fi

while true 
do
    echo "Files in $malicious_dir:"
    ls -l "$malicious_dir"
    select file in "$malicious_dir"/*
    do
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
        read -p "Enter your choice (1, 2, 3, or 4):" choice

        case $choice in
            1)
                mv "$file" "$target_dir"
                echo "Restored $file to $target_dir"
                echo "$file" >> whitelist.txt
                break
                ;;
            2)
                rm "$file"
                echo "Permanently deleted $file"
                break
                ;;
            3)
                echo "Skipped $file"
                break
                ;;
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
