#!/bin/bash
# setup_project.sh
# Usage: ./setup_project.sh

section() {
    echo ""
    echo "=================================================="
    echo "$1"
    echo "=================================================="
}

# ------------------------------------------------------------------
# 1. Project name input + collision check
# ------------------------------------------------------------------
section "PROJECT INITIALIZATION"

while true; do
    read -p "Enter project identifier: " PROJECT_NAME
    if [[ -n "$PROJECT_NAME" ]]; then
        break
    fi
    echo "[-] Project name cannot be empty."
done

BASE_DIR="attendance_tracker_${PROJECT_NAME}"

if [[ -d "$BASE_DIR" ]]; then
    echo "[-] Error: directory '$BASE_DIR' already exists. Choose a different suffix."
    exit 1
fi

# ------------------------------------------------------------------
# 2. Signal trap - active from this point on, so any interruption
#    during creation/configuration is caught and cleaned up.
# ------------------------------------------------------------------
cleanup() {
    echo ""
    section "INTERRUPT DETECTED (CTRL+C)"

    if [[ -d "$BASE_DIR" ]]; then
        ARCHIVE_NAME="${BASE_DIR}_archive"
        echo "[*] Archiving current project state -> ${ARCHIVE_NAME}.tar.gz"
        if tar -czf "${ARCHIVE_NAME}.tar.gz" "$BASE_DIR" 2>/dev/null; then
            echo "[+] Archive created."
        else
            echo "[-] Archive creation failed."
        fi

        echo "[*] Removing incomplete project directory."
        rm -rf "$BASE_DIR"
        echo "[+] Workspace cleaned."
    else
        echo "[-] No project directory existed yet, nothing to archive."
    fi

    echo "[+] Safe exit complete."
    exit 1
}

trap cleanup SIGINT

# ------------------------------------------------------------------
# 3. Directory architecture
# ------------------------------------------------------------------
section "PROJECT STRUCTURE CREATION"

mkdir -p "$BASE_DIR/Helpers" "$BASE_DIR/reports"
if [[ $? -ne 0 ]]; then
    echo "[-] Error: could not create project directories (check permissions)."
    exit 1
fi
echo "[+] Directory structure created."

cat <<CSV > "$BASE_DIR/Helpers/assets.csv"
Email,Names,Attendance Count,Absence Count
alice@example.com,Alice Johnson,14,1
bob@example.com,Bob Smith,7,8
charlie@example.com,Charlie Davis,4,11
diana@example.com,Diana Prince,15,0
CSV
if [[ $? -ne 0 ]]; then
    echo "[-] Error: could not write assets.csv (check permissions)."
    exit 1
fi
echo "[+] Helpers/assets.csv created."

cat <<JSON > "$BASE_DIR/Helpers/config.json"
{
  "thresholds": {
    "warning": 75,
    "failure": 50
  },
  "run_mode": "live",
  "total_sessions": 15
}
JSON
if [[ $? -ne 0 ]]; then
    echo "[-] Error: could not write config.json (check permissions)."
    exit 1
fi
echo "[+] Helpers/config.json created."

touch "$BASE_DIR/reports/reports.log"
if [[ $? -ne 0 ]]; then
    echo "[-] Error: could not create reports/reports.log (check permissions)."
    exit 1
fi
echo "[+] reports/reports.log created."

cat <<'PY' > "$BASE_DIR/attendance_checker.py"
import csv, json, os
from datetime import datetime

def run():
    with open('Helpers/config.json') as f:
        config = json.load(f)

    print("Loading configuration...")

    if os.path.exists('reports/reports.log'):
        print("Archiving old logs...")
        os.rename('reports/reports.log',
                  f'reports/reports_{datetime.now().strftime("%Y%m%d_%H%M%S")}.log')

    print("Processing attendance data...")

    with open('Helpers/assets.csv') as f, open('reports/reports.log', 'w') as log:
        reader = csv.DictReader(f)

        for row in reader:
            pct = (int(row['Attendance Count']) / config['total_sessions']) * 100

            print(f"Checking {row['Names']} -> {pct:.1f}%")

            msg = ""
            if pct < config['thresholds']['failure']:
                msg = f"URGENT: {row['Names']}"
            elif pct < config['thresholds']['warning']:
                msg = f"WARNING: {row['Names']}"

            if msg:
                log.write(msg + "\n")

    print("Report generation complete")

if __name__ == "__main__":
    run()
PY
if [[ $? -ne 0 ]]; then
    echo "[-] Error: could not write attendance_checker.py (reconfigure permissions)."
    exit 1
fi
echo "[+] attendance_checker.py created."

# ------------------------------------------------------------------
# 4. Dynamic configuration (stream editing with sed)
# ------------------------------------------------------------------
section "CONFIGURATION SETUP"

read -p "Do you want to update the attendance thresholds? (y/n): " UPDATE_CHOICE

if [[ "$UPDATE_CHOICE" =~ ^[Yy]$ ]]; then

    while true; do
        read -p "Warning threshold % (0-100) [default 75]: " WARNING
        WARNING=${WARNING:-75}
        if [[ "$WARNING" =~ ^[0-9]+$ ]] && (( WARNING >= 0 && WARNING <= 100 )); then
            break
        fi
        echo "[-] Invalid value. Enter a whole number between 0 and 100."
    done

    while true; do
        read -p "Failure threshold % (0-100) [default 50]: " FAILURE
        FAILURE=${FAILURE:-50}
        if [[ "$FAILURE" =~ ^[0-9]+$ ]] && (( FAILURE >= 0 && FAILURE <= 100 )); then
            if (( FAILURE < WARNING )); then
                break
            fi
            echo "[-] Failure threshold must be lower than the warning threshold ($WARNING)."
        else
            echo "[-] Invalid value. Enter a whole number between 0 and 100."
        fi
    done

    JSON_FILE="$BASE_DIR/Helpers/config.json"

    if [[ "$(uname)" == "Darwin" ]]; then
        sed -i '' "s/\"warning\": [0-9]*/\"warning\": $WARNING/" "$JSON_FILE"
        sed -i '' "s/\"failure\": [0-9]*/\"failure\": $FAILURE/" "$JSON_FILE"
    else
        sed -i "s/\"warning\": [0-9]*/\"warning\": $WARNING/" "$JSON_FILE"
        sed -i "s/\"failure\": [0-9]*/\"failure\": $FAILURE/" "$JSON_FILE"
    fi

    echo "[+] Thresholds updated: warning=$WARNING, failure=$FAILURE"
else
    echo "[*] Keeping default thresholds (warning=75, failure=50)."
fi

# ------------------------------------------------------------------
# 5. Environment validation (health check)
# ------------------------------------------------------------------
section "ENVIRONMENT VALIDATION"

if python3 --version >/dev/null 2>&1; then
    echo "[+] Python3 detected: $(python3 --version 2>&1)"
else
    echo "[-] Warning: Python3 is not installed. attendance_checker.py will not run without it."
fi

ALL_OK=true
for path in \
    "$BASE_DIR/attendance_checker.py" \
    "$BASE_DIR/Helpers/assets.csv" \
    "$BASE_DIR/Helpers/config.json" \
    "$BASE_DIR/reports/reports.log"
do
    if [[ -e "$path" ]]; then
        echo "[+] Found ${path#$BASE_DIR/}"
    else
        echo "[-] Missing ${path#$BASE_DIR/}"
        ALL_OK=false
    fi
done

if [[ "$ALL_OK" == false ]]; then
    echo "[-] Project structure is incomplete."
    exit 1
fi

# ------------------------------------------------------------------
# Done
# ------------------------------------------------------------------
section "COMPLETION"
echo "[+] Project successfully generated at ./$BASE_DIR"
echo ""
echo "Next steps:"
echo "  cd $BASE_DIR"
echo "  python3 attendance_checker.py"
