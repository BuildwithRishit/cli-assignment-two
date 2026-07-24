#!/bin/bash

# Reproduces a vi/vim crash-recovery scenario NON-interactively so the whole
# thing can be run and screenshotted with one command.
#
# Steps:
#   1. Create a config file (app.conf).
#   2. Open it in vim, make an UNSAVED edit (append CRASH_TEST line).
#   3. Hard-kill vim (kill -9) to simulate a system crash / power loss.
#   4. Show the leftover swap file  (.app.conf.swp).
#   5. Recover with 'vim -r' and prove the unsaved change is restored.

FILE="app.conf"

# 1) fresh config file
printf 'port=8080\nhost=localhost\nmax_connections=100\ntimeout=30\nlog_level=info\n' > "$FILE"
rm -f ".${FILE}.swp" keys.in recovered_app.conf recover_transcript.txt

# 2) keystrokes: G=last line, o=open line below, type text, Esc
printf 'GoCRASH_TEST=recovered\x1b' > keys.in

# open vim under a pseudo-terminal (via 'script') so it behaves like a real
# session; swap file enabled and kept in the current directory.
script -q /dev/null vim -X -s keys.in -c 'set directory=.' "$FILE" >/dev/null 2>&1 &
VPID=$!
sleep 2

# 3) simulate the crash
echo ">> Simulating system crash: kill -9 on the vim process..."
kill -9 "$VPID" 2>/dev/null
pkill -9 -P "$VPID" 2>/dev/null
sleep 1

# 4) the swap file survives the crash
echo ""
echo ">> Leftover swap file:"
ls -la ".${FILE}.swp"

echo ""
echo ">> Original file on disk (the unsaved change is MISSING here):"
cat "$FILE"

# 5) recover from the swap file
echo ""
echo ">> Recovering with:  vim -r $FILE"
script -q recover_transcript.txt vim -X -r "$FILE" -c 'w! recovered_app.conf' -c 'qa!' </dev/null >/dev/null 2>&1

echo ""
echo ">> vim recovery messages:"
cat -v recover_transcript.txt | tr '\r' '\n' | grep -iE 'swap|recover|original' | sed 's/\^\[\[[0-9;]*[A-Za-z]//g; s/[[:cntrl:]]//g' | sed '/^$/d'

echo ""
echo ">> Recovered file (the unsaved CRASH_TEST line is BACK):"
cat recovered_app.conf