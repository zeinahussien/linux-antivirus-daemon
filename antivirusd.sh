target_dir=$1
malicious_dir=$2
interval_sec=$3

scan_files() {
        for file in $target_dir/*
        do
            if [[ "$file" == *.exe || "$file" == *.bat || "$file" == *.vbs || "$file" == *.scr || "$file" == *.ps1 ]] || grep -qiE "virus|trojan|malware|worm|ransomware" "$file"
            then
                echo  "$file is malicious and DELETED"
                cp "$file" "$malicious_dir"
                rm "$file"
            fi
        done
}

scan_files
ls -l $target_dir > directory-info.last 

while true
do
    sleep $interval_sec
    ls -l $target_dir > directory-info.new

    if diff directory-info.last directory-info.new 
    then
        continue
    else
        scan_files
        cp directory-info.new directory-info.last
    fi
done