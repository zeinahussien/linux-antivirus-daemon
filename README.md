# Simple Antivirus Daemon (CC373 – Lab 2)

A small antivirus written in Bash. A daemon watches a directory, and whenever it changes, scans the files in it. Files that look malicious are reported, copied into a quarantine directory and removed from the original location. A separate interactive tool lets you review the quarantine and restore false positives or delete real threats. Files you restore are remembered in a whitelist so they are not flagged again.

Assumption (as stated in the lab): the monitored directory contains **only files**, with no subdirectories.

---

## 1. Overview and folder hierarchy

```
.
├── antivirusd.sh        # Daemon: polls the directory, scans on change, quarantines files
├── restore.sh           # Interactive tool: restore / delete / skip quarantined files
├── antivirus-cron.sh    # Bonus 1: one-shot version of the daemon, meant to run from cron
├── Makefile             # Targets: all/run, restore, setup (pre-build), clean
├── whitelist.txt        # Bonus 2: filenames marked safe (written by restore.sh)
├── README.md            # This file
├── .gitignore           # Ignores snapshot files and quarantine contents
├── test_dir/            # Monitored directory (created by `make setup`)
└── quarantine/          # Quarantine directory (created by `make setup`)
```

Files generated while running (not committed):

| File | Created by | Purpose |
|---|---|---|
| `directory-info.last` | daemon / cron script | `ls -l` snapshot from the last check |
| `directory-info.new` | daemon / cron script | `ls -l` snapshot taken now, compared with `.last` |

---

## 2. Prerequisites (Ubuntu)

The scripts use only standard tools: `bash`, `ls`, `cp`, `rm`, `mv`, `mkdir`, `grep`, `diff`, `basename`, `sleep`. These are installed on Ubuntu by default. You additionally need `make`, and `cron` for the bonus:

```bash
sudo apt update
sudo apt install -y make cron git
```

Check that everything is available:

```bash
bash --version
make --version
```

> **Line endings:** the scripts must use Unix (LF) line endings. If you edited them on Windows and see `bad interpreter` or `^M` errors, convert them with `sed -i 's/\r$//' antivirusd.sh restore.sh antivirus-cron.sh Makefile`.

---

## 3. How to run

### Step 1 – Get the project

```bash
git clone <your-repository-url>
cd <your-repository-folder>
```

### Step 2 – Run the antivirus daemon

```bash
make
```

`make` (same as `make run`) first runs the pre-build step `setup`, which creates `test_dir/` and `quarantine/` if they do not exist and makes the scripts executable, then starts:

```bash
./antivirusd.sh test_dir quarantine 5
```

The daemon runs until you stop it with `Ctrl+C`.

You can change the settings from the command line:

```bash
make run TARGET=my_folder MALICIOUS=my_quarantine INTERVAL=10
```

Or run the script directly:

```bash
./antivirusd.sh <dir> <malicious_dir> <interval-secs>
```

| Argument | Meaning |
|---|---|
| `dir` | Directory being monitored (files only) |
| `malicious_dir` | Quarantine directory where flagged files are copied |
| `interval-secs` | Seconds to wait between checks |

### Step 3 – Try it

In a second terminal, drop some test files into the monitored directory:

```bash
echo "hello" > test_dir/notes.txt          # clean file, left alone
echo "x" > test_dir/setup.exe              # flagged by extension
echo "this has a Virus in it" > test_dir/readme.txt   # flagged by content
```

Within one interval the daemon prints each flagged file and moves it into `quarantine/`.

### Step 4 – Review the quarantine

Stop the daemon first (`Ctrl+C`). The two scripts are not meant to run at the same time. Then:

```bash
make restore
```

(runs `./restore.sh test_dir quarantine`). You will see a numbered list of quarantined files. Type a number to pick a file, then choose an action:

| Choice | Action |
|---|---|
| `1` | **Restore** the file to `dir` (false positive) and add it to the whitelist |
| `2` | **Permanently delete** the file (it was genuinely malicious) |
| `3` | **Leave** the file as it is and go back to the list |
| `4` | Exit the tool |

Invalid input just asks again. When the quarantine is empty the tool prints `No malicious files to review.` and exits.

### Step 5 – Clean up

```bash
make clean
```

This removes the two snapshot files. It does **not** touch `whitelist.txt` or the quarantine.

---

## 4. How the daemon works

1. **First run:** there is no `directory-info.last` yet, so the daemon scans `dir` immediately, then creates `directory-info.last` with `ls -l dir`.
2. **Every `interval-secs`:** it saves `ls -l dir` to `directory-info.new` and compares it with `directory-info.last` using `diff`.
3. **No difference:** nothing happens, and it waits for the next interval (no scan).
4. **Difference:** it scans `dir`, then copies `directory-info.new` over `directory-info.last`.

For every malicious file found, the scan:

1. prints `<file> is malicious and DELETED`,
2. copies the file into `malicious_dir` under its original name,
3. deletes the original from `dir`.

Because `ls -l` includes modification times, adding, removing, or editing a file all count as a change.

### What counts as malicious

A file is malicious if **either** rule matches (and it is not whitelisted):

* **Flagged extension:** `.exe`, `.bat`, `.vbs`, `.scr`, `.ps1`
* **Flagged content:** the file contains one of `virus`, `trojan`, `malware`, `worm`, `ransomware` (case-insensitive)

**Where these lists are defined:** both lists are hardcoded in the single `elif` condition inside the `scan_files` function:

* `antivirusd.sh` – **line 19** (extensions are the `*.exe`, `*.bat`, `*.vbs`, `*.scr`, `*.ps1` tests; keywords are in the `grep -qiE "virus|trojan|malware|worm|ransomware"` pattern)
* `antivirus-cron.sh` – **line 22** (same condition)

---

## 5. Bonus 1 – Cron job

`antivirus-cron.sh` does the same job as the daemon but runs **once per invocation** and then exits, so cron provides the schedule instead of a `while`/`sleep` loop.

* If `directory-info.last` does not exist (first run), it scans immediately and then creates the snapshot.
* Otherwise it takes a new snapshot, compares it with the last one, and scans only if they differ.
* It stores `directory-info.*` and reads `whitelist.txt` **next to the script itself**, so it works no matter which directory cron starts it from.

```bash
./antivirus-cron.sh <dir> <malicious_dir>
```

### Prerequisites

* `cron` installed and running:
  ```bash
  sudo apt install -y cron
  sudo systemctl enable --now cron
  systemctl status cron        # should say "active (running)"
  ```
* The script must be executable: `chmod +x antivirus-cron.sh` (or run `make setup`).
* The monitored and quarantine directories must already exist (run `make setup` once).
* Use **absolute paths** in the crontab. Find the project path with `pwd`.

### Step-by-step setup

1. Go to the project folder and note its absolute path:
   ```bash
   cd <project-folder>
   make setup
   pwd
   ```
   In the examples below, replace `/home/user/lab2` with your real path.
2. Open your crontab:
   ```bash
   crontab -e
   ```
   (choose an editor if asked).
3. Add the line for the schedule you want (see below), save and exit.
4. Confirm it was installed:
   ```bash
   crontab -l
   ```
5. Test it: drop a `.exe` file into `test_dir/`, wait for the next run, and check that it appears in `quarantine/`. To see output, you can append `>> /home/user/lab2/cron.log 2>&1` to the line.

### Every 1 minute at second 23

Cron's smallest unit is one minute, so it cannot start a job at "second 23" by itself. Run the job every minute and delay it by 23 seconds:

```
* * * * * sleep 23 && /home/user/lab2/antivirus-cron.sh /home/user/lab2/test_dir /home/user/lab2/quarantine
```

### Every 3rd Friday of the month at 12:31 AM

```
31 0 15-21 * * [ "$(date +\%u)" = 5 ] && /home/user/lab2/antivirus-cron.sh /home/user/lab2/test_dir /home/user/lab2/quarantine
```

Why it is written this way:

* `31 0` = 00:31 (12:31 AM).
* The third Friday of any month always falls between the **15th and 21st**, so the day-of-month field is `15-21`.
* If both day-of-month and day-of-week are set, cron runs the job when **either** matches, so a plain `15-21 * * 5` would also run on every Friday. Instead, the day-of-week field stays `*`, and the command itself checks that today is Friday (`date +%u` prints `5` on Friday).
* In a crontab, `%` is a special character, so it must be written as `\%`.

---

## 6. Bonus 2 – Whitelist

Restoring a file marks it as safe so the next scan does not flag it again, even though its extension or content still matches the rules.

### How a file gets added

In `restore.sh`, choosing option **1 (Restore)**:

1. moves the file from `malicious_dir` back to `dir`,
2. prints that it was restored,
3. appends the file's **name** (just the filename, not the path) as one line to `whitelist.txt`, which lives in the same folder as the scripts.

### How the daemon checks it

At the start of each file's check in `scan_files` (`antivirusd.sh` line 15, `antivirus-cron.sh` line 18), the scanner takes the file's name and runs:

```bash
grep -Fxq -- "$name" "$whitelist"
```

* `-F`: treat the name as plain text (so `.` is not a wildcard),
* `-x`: the whole line must match (so `a.exe` does not match `data.exe` or `a.exe2`),
* `-q`: no output, only the result.

If it matches, the file is skipped; otherwise it goes through the extension and keyword rules.

### Persistence

`whitelist.txt` is a plain file on disk, read again on every scan, so entries survive stopping and restarting the daemon (and are shared with the cron script). To un-whitelist a file, delete its line from `whitelist.txt`.

**Limitation:** the whitelist matches by filename only. A different file with the same name in `dir` is also treated as safe.

---

## 7. Troubleshooting

| Problem | Likely cause / fix |
|---|---|
| `bad interpreter: No such file or directory` | Windows line endings. Convert to LF (see Prerequisites). |
| `Permission denied` | Run `chmod +x antivirusd.sh restore.sh antivirus-cron.sh` or `make setup`. |
| `*** missing separator` from `make` | Makefile recipe lines must start with a tab, not spaces. |
| Cron job does nothing | Check `systemctl status cron`, use absolute paths, check `crontab -l` and a log file. |
| A restored file is flagged again | Check that its filename is in `whitelist.txt`. |

## 8. Notes and limitations

* Only regular files directly inside `dir` are handled; subdirectories are not supported.
* The extension check is case-sensitive (`.EXE` is not matched), exactly as the lists are written in the lab.
* Hidden files (names starting with `.`) are not scanned.