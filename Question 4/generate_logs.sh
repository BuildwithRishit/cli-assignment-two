#!/bin/bash
#==============================================================================
# generate_logs.sh -- simulate a running web server by APPENDING log lines
# to app.log every second. Run this in a SECOND terminal while monitor.sh
# is running, so you can watch ERROR lines appear live.
#
# Usage: ./generate_logs.sh          (press Ctrl+C to stop)
#==============================================================================

LOG="app.log"
levels=("INFO  Request handled in 10ms" \
        "INFO  Health check OK" \
        "WARN  High latency detected" \
        "ERROR Unhandled exception in worker" \
        "ERROR Connection refused by upstream" \
        "INFO  Background job completed")

i=0
while true; do
    ts="$(date '+%Y-%m-%d %H:%M:%S')"
    line="${levels[$((i % ${#levels[@]}))]}"
    echo "$ts $line" >> "$LOG"
    i=$((i + 1))
    sleep 1
done
