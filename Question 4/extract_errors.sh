#!/bin/bash

# Same idea as monitor.sh but on the EXISTING log, so it finishes immediately
# and is easy to screenshot / capture. Demonstrates grep + pipe + redirection
# + /dev/null on the current contents of app.log.

LOG="app.log"
REPORT="error_report.txt"

# Extract ERROR lines -> write a SEPARATE report AND show on screen (tee).
# 2>/dev/null suppresses any error (e.g. if a log file were missing).
echo ">> Extracting ERROR lines from $LOG ..."
grep "ERROR" "$LOG" 2>/dev/null | tee "$REPORT"

echo ""
echo ">> ERROR count: $(grep -c 'ERROR' "$LOG")"
echo ">> Report saved to: $REPORT"

# Example of /dev/null suppressing UNWANTED output:
# count INFO lines but throw away the lines themselves, keep only the number.
info_count=$(grep "INFO" "$LOG" | tee /dev/null | wc -l | tr -d ' ')
echo ">> INFO lines were suppressed to /dev/null (count only = $info_count)"
