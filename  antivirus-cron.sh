target_dir=$1
malicious_dir=$2
interval_sec=$3

scan_files() {
        for file in $target_dir/*
        do
            if grep -q "$file" whitelist.txt
            then
                echo "$file is whitelisted and SKIPPED"
            
            elif [[ "$file" == *.exe || "$file" == *.bat || "$file" == *.vbs || "$file" == *.scr || "$file" == *.ps1 ]] || grep -qiE "virus|trojan|malware|worm|ransomware" "$file"
            then
                echo  "$file is malicious and DELETED"
                cp "$file" "$malicious_dir"
                rm "$file"
            fi
        done
}

scan_files

if  [[ -f "directory-info.last" ]]
then
    ls -l $target_dir > directory-info.new
    if ! diff directory-info.last directory-info.new 
    then
        scan_files
        cp directory-info.new directory-info.last
    fi
else
    ls -l $target_dir > directory-info.last 
fi
