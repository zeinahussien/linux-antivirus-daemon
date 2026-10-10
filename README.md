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
