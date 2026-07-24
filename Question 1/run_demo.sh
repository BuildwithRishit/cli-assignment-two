#!/bin/bash
#==============================================================================
# run_demo.sh - prepares sample data and runs duplicate_manager.sh
# This makes the whole demonstration reproducible with ONE command.
#==============================================================================

# 1) Build a fresh set of sample submissions 
rm -rf submissions backup
mkdir -p submissions

# Three DISTINCT contents (A, B, C) spread across six students so that
# some submissions are exact duplicates of others.
printf 'Assignment 1: Linux file systems.\nAnswer by student.\n' > submissions/student101_assignment.txt   # content A
printf 'Assignment 1: Process scheduling.\nDifferent answer.\n'   > submissions/student102_assignment.txt   # content B
printf 'Assignment 1: Linux file systems.\nAnswer by student.\n' > submissions/student103_assignment.txt   # content A (dup)
printf 'Assignment 1: Memory management essay.\nUnique work.\n'   > submissions/student104_assignment.txt   # content C
printf 'Assignment 1: Process scheduling.\nDifferent answer.\n'   > submissions/student105_assignment.txt   # content B (dup)
printf 'Assignment 1: Linux file systems.\nAnswer by student.\n' > submissions/student106_assignment.txt   # content A (dup)

# 2) Create ONE unreadable file to demonstrate error handling 
printf 'corrupt/locked submission\n' > submissions/student107_locked.txt
chmod 000 submissions/student107_locked.txt

# 3) Run the manager 
echo "########## RUNNING duplicate_manager.sh ##########"
./duplicate_manager.sh

# 4) Show the separate error log 
echo ""
echo "########## CONTENTS OF errors.log ##########"
cat errors.log

# 5) Show what ended up in the backup directory 
echo ""
echo "########## FILES IN backup/ (unique only) ##########"
ls -1 backup

# 6) Restore permission so the tree stays readable/cleanable 
chmod 644 submissions/student107_locked.txt