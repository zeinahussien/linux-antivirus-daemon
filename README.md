# Linux Antivirus Daemon & Automation Suite

A lightweight, modular Linux security project built using Bash scripting and Makefiles. This suite monitors a target directory for malicious files, quarantines them, and provides an interactive restoration interface for handling false positives.

---

## 1. Project Overview & Folder Hierarchy

The project is structured into an automated workflow separating source scripts, test directories, and quarantine storage.

linux-antivirus-daemon/

│

├── antivirusd.sh        # Background daemon for polling and threat detection

├── restore.sh           # Interactive file review and restoration tool

├── Makefile             # Automation manager for setup, execution, and cleanup

├── README.md            # Project documentation

├── .gitignore           # Excludes temporary snapshots and quarantine contents

├── test_dir/            # Monitored source directory for files

└── quarantine/          # Isolated storage directory for flagged files

---

## 2. Prerequisites & Installation on Ubuntu

This project relies on standard POSIX-compliant Linux utilities available by default on Ubuntu environments.

### Prerequisites:

* Bash (Bourne Again SHell)

* Core utilities: coreutils (ls, mv, rm, mkdir), diff, and make.

### Installation:

1. Clone or copy the project repository onto your local machine:

   git clone https://github.com/zeinahussien/linux-antivirus-daemon.git

   cd linux-antivirus-daemon

2. Run the automated Makefile setup to create required directories and grant execution permissions:

   make setup
   
---

## 3. Step-by-Step Execution Instructions

### A. Running the Antivirus Daemon

The daemon monitors the target directory continuously at a specified interval (e.g., every 5 seconds):

make run

Alternatively, you can run the script manually:

./antivirusd.sh test_dir quarantine 5


### B. Running the Interactive Restore Tool

To review quarantined files and decide whether to restore or permanently delete them:

make restore

### C. Cleaning Up Temporary Files

To clear old directory snapshots (directory-info.last and directory-info.new):

make clean

---

## 4. Detection Engine Rules & Definitions

The detection engine scans files based on strict hardcoded rules defined within antivirusd.sh:

1. Flagged Extensions: Files matching any of the following extensions are flagged immediately:

   * .exe

   * .bat

   * .vbs

   * .scr

   * .ps1

2. Flagged Content Keywords: Files whose text content contains any of the following case-insensitive keywords are flagged:

   * virus

   * trojan

   * malware

   * worm

   * ransomware

---

## Bonus 1: Cron Job Automation

Instead of running as a continuous background loop with `sleep`, the antivirus monitor can be executed on a strict, fixed schedule using Linux `cron`. 

### 1. Script Implementation (`antivirus-cron.sh`)
The cron version performs a single execution cycle: it checks if a previous state (`directory-info.last`) exists. If it is the first run, it initializes the snapshot. On subsequent runs, it captures a new snapshot (`directory-info.new`), compares them using `diff`, and quarantines any flagged files if changes are detected.

### 2. Prerequisites & Absolute Paths
Because `cron` jobs run in a non-interactive background shell with a minimal environment:
* Ensure your script has executable permissions:
  ```bash
  chmod +x antivirus-cron.sh
  ```
* Always use **absolute paths** for both the script and its arguments in your crontab configuration so the system can locate them reliably.

### 3. Step-by-Step Manual to Configure the Cron Job
1. Open your user crontab editor in the terminal:
   ```bash
   crontab -e
   ```
2. Add your scheduled cron job entry. 

#### Example A: Running every 1 minute with a 23-second delay offset
Standard Linux `cron` has a minimum resolution of 1 minute and cannot natively target specific seconds. To run a scan every 1 minute at second 23, configure cron to trigger every minute and use an internal `sleep` command:
```text
* * * * * sleep 23 && /absolute/path/to/linux-antivirus-daemon/antivirus-cron.sh /absolute/path/to/linux-antivirus-daemon/test_dir /absolute/path/to/linux-antivirus-daemon/quarantine
```

#### Example B: Running every 3rd Friday of the month at 12:31 AM
To schedule the scan precisely for 12:31 AM on the third Friday of every month, use the following cron expression combining time fields with the day-of-week `#` modifier (`5#3`):
```text
31 0 * * 5#3 /absolute/path/to/linux-antivirus-daemon/antivirus-cron.sh /absolute/path/to/linux-antivirus-daemon/test_dir /absolute/path/to/linux-antivirus-daemon/quarantine
```
* **`31`**: Minute 31
* **`0`**: Hour 0 (12:31 AM)
* **`*`**: Every day of the month
* **`*`**: Every month
* **`5#3`**: The 3rd Friday (`5`) of the month

---

## Bonus 2: Persistent Whitelist Mechanism

To prevent legitimate files that have been reviewed and restored by the user from being immediately detected and re-quarantined during the next daemon or cron scan, a persistent whitelist mechanism (`whitelist.txt`) is integrated into both the scanner and the restoration utility.

### 1. Whitelist Integration in the Scanner (`antivirusd.sh` & `antivirus-cron.sh`)
Before checking any file against malicious extensions or signature keywords, the scanner verifies whether the file path exists in `whitelist.txt` using a quiet `grep` check:
```bash
if grep -q "$file" whitelist.txt
then
    echo "$file is whitelisted and SKIPPED"
elif [[ "$file" == *.exe || "$file" == *.bat || "$file" == *.vbs || "$file" == *.scr || "$file" == *.ps1 ]] || grep -qiE "virus|trojan|malware|worm|ransomware" "$file"
then
    echo "$file is malicious and DELETED"
    cp "$file" "$malicious_dir"
    rm "$file"
fi
```

### 2. Whitelist Automation in the Restorer (`restore.sh`)
When the user interacts with the `restore.sh` utility and chooses option `1` to restore a quarantined file back to the target directory, the script automatically records the file's path into `whitelist.txt` using the append (`>>`) operator:
```bash
1)
    mv "$file" "$target_dir"
    echo "Restored $file to $target_dir"
    echo "$file" >> whitelist.txt
    break
    ;;
```
This ensures the restoration decision persists across system reboots and subsequent background scans.
