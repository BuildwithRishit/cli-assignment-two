#!/bin/bash

SUBMISSIONS_DIR="${1:-submissions}"     # where student files live
BACKUP_DIR="${2:-backup}"               # where unique files are copied
REPORT_FILE="report.txt"                # human-readable summary
ERROR_LOG="errors.log"                  # All errors are redirected here

# Pick a checksum tool that exists
if command -v md5sum >/dev/null 2>&1; then
    CHECKSUM="md5sum"                 
elif command -v shasum >/dev/null 2>&1; then
    CHECKSUM="shasum -a 256"
else
    echo "FATAL: no checksum utility (md5sum/shasum) found" >&2
    exit 1
fi

# Fresh start: reset outputs
mkdir -p "$BACKUP_DIR"
: > "$REPORT_FILE"      # truncate report  ( : is a no-op, > empties the file )
: > "$ERROR_LOG"        # truncate error log

# Counters 
total=0
duplicates=0
backed_up=0

# A temp "map" file remembers  <checksum> <first-file-with-that-checksum> -
# (Used instead of an associative array so the script also runs on old bash 3.2)
MAP="$(mktemp)"

# Main loop: walk every regular file under the submissions directory
# 'find ... 2>>' sends directory-traversal errors straight to the error log.
while IFS= read -r file; do
    total=$((total + 1))

    # Compute the checksum. Any error (e.g. unreadable file) -> error log.
    sum="$($CHECKSUM "$file" 2>>"$ERROR_LOG" | awk '{print $1}')"

    if [ -z "$sum" ]; then
        # No checksum produced => the file could not be read.
        echo "ERROR: could not checksum '$file'" >>"$ERROR_LOG"
        continue
    fi

    # Have we seen this exact content before?
    original="$(awk -v s="$sum" '$1==s {sub($1 FS,""); print; exit}' "$MAP")"

    if [ -n "$original" ]; then
        # Duplicate content: do NOT back it up, just record it.
        duplicates=$((duplicates + 1))
        echo "DUPLICATE : $file   (same content as $original)" >>"$REPORT_FILE"
    else
        # First time we see this content: remember it and back it up.
        echo "$sum $file" >>"$MAP"
        if cp "$file" "$BACKUP_DIR/" 2>>"$ERROR_LOG"; then
            backed_up=$((backed_up + 1))
            echo "UNIQUE    : $file   -> backed up" >>"$REPORT_FILE"
        fi
    fi
done < <(find "$SUBMISSIONS_DIR" -type f 2>>"$ERROR_LOG")

rm -f "$MAP"

# Summary block appended to the report
{
    echo ""
    echo "================ SUBMISSION PROCESSING REPORT ================"
    echo " Generated on    : $(date)"
    echo " Submissions dir : $SUBMISSIONS_DIR"
    echo " Backup dir      : $BACKUP_DIR"
    echo " -----------------------------------------------------------"
    echo " Files processed : $total"
    echo " Duplicates found: $duplicates"
    echo " Unique backed up: $backed_up"
    echo " Errors logged   : $(wc -l < "$ERROR_LOG" | tr -d ' ')"

} >>"$REPORT_FILE"

# Show the report on screen as well.
cat "$REPORT_FILE"