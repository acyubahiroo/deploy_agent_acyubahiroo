WATCH A VIDEO THAT EXPLAINS HOW THE CODE WORKS IN DETAIL: 
https://youtu.be/MQ5P-9FjU_k


# deploy_agent_acyubahiroo
This repository is created and contains a script to build a "Project Factory"; a shell script that automates the creation of the workspace, configures settings via the command line, and handles system signals gracefully.

#DETAILS ON HOW THIS WORKS:

# Attendance Tracker Bootstrapper

This script (`setup_project.sh`) automatically sets up an "Attendance Tracker" project: it creates folders, writes starter files, and checks your computer is ready.

## Requirements

- Bash
- Python 3

## How to run

```bash
chmod +x setup_project.sh
./setup_project.sh
```

## What it does

1. **Asks for a project name.** It creates a folder called `attendance_tracker_<name>`. If that folder already exists, it stops and asks for a different name. The "name" variable is the user input.

2. **Creates the project files as shown with the below hierarchy:
```
attendance_tracker_<name>/
├── attendance_checker.py
├── Helpers/
│   ├── assets.csv      (sample student attendance data)
│   └── config.json     (warning/failure thresholds)
└── reports/
    └── reports.log
```

3. **Asks if you want to change the thresholds.** Default is 75% (warning) and 50% (failure). If you say yes, it checks your numbers are valid before saving them. The user can change 

4. **Checks Python 3 is installed** and confirms all files were created.

## The Ctrl+C safety net

If you press **Ctrl+C** while the script is running, it won't leave a mess. Instead it:
- zips the current progress into `attendance_tracker_<name>_archive.tar.gz`
- deletes the incomplete folder

To open the backup later:
```bash
tar -xzf attendance_tracker_<name>_archive.tar.gz
```

## Running the checker

```bash
cd attendance_tracker_<name>
python3 attendance_checker.py
```

This reads the student data, compares it to your thresholds, and writes warnings to `reports/reports.log`.

5.How to trigger the archive feature

You can test this safely using a throwaway project name, like test.

Run the script: ./setup_project.sh
When asked for a project name, type test
Wait until you see [+] Directory structure created. — or any point after that, including during the threshold questions
Press Ctrl+C
