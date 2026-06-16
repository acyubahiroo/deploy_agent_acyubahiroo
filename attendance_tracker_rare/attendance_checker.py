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
