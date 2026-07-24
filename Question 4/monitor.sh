#!/bin/bash

# Shows newly added log lines as they arrive, keeps ONLY the ERROR messages,
# writes them to a separate report file, and shows them on screen too.
#
# Pipeline explained:
#   tail -f app.log        -> stream the log, including lines added in real time
#      2>/dev/null         -> suppress tail's own error/notice messages
#   | grep --line-buffered "ERROR"
#                          -> keep only ERROR lines; --line-buffered flushes each
#                             match immediately (needed inside a pipe)
#   | tee -a error_report.txt
#                          -> APPEND matches to the report AND print to screen
#
# Usage: ./monitor.sh

LOG="app.log"
REPORT="error_report.txt"

echo ">> Monitoring '$LOG' for ERROR entries (Ctrl+C to stop)..."
echo ">> Errors are also being appended to '$REPORT'"

tail -f "$LOG" 2>/dev/null \
    | grep --line-buffered "ERROR" \
    | tee -a "$REPORT"
