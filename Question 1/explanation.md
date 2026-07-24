# Question 1: Finding Duplicate Submissions

Write a shell script that finds duplicate student submissions, backs up the
unique ones, prints a report with the counts, and keeps error messages in a
separate file.

## Files in this folder

- `duplicate_manager.sh` is the actual script.
- `run_demo.sh` sets up sample files and runs the script, so the whole thing is
  easy to repeat.
- `submissions/` holds the sample student files. Some of them are copies of each
  other on purpose.
- `backup/`, `report.txt`, and `errors.log` are the things the script produces.
- `output.txt` is what the terminal showed when I ran it.

## How I find duplicates

I compare files by their content, not their name. For each file I make an md5
checksum. If two files have the same checksum, they hold the same bytes, so the
second one is a duplicate. The first file with a given checksum gets backed up.
Any later file with that same checksum is just counted.

## The commands I ran and what I saw

### 1. Make the scripts runnable

```
chmod +x duplicate_manager.sh run_demo.sh
```

This gives both scripts permission to run. It prints nothing, which is normal
for `chmod`.

### 2. Set up the data and run the script

```
./run_demo.sh
```

This wrote six student files (three had repeated content) plus one locked file,
then ran my manager. I saw three files marked UNIQUE and backed up, and three
marked DUPLICATE.

### 3. Read the report

```
cat report.txt
```

The report said 7 files processed, 3 duplicates, and 3 unique files backed up.
That lines up with the sample data.

### 4. Read the error log

```
cat errors.log
```

It showed a "Permission denied" line for the locked file. This proves the errors
land in their own file and do not mix into the report.

### 5. List the backup folder

```
ls -l backup
```

Only three files were there, one per unique submission. The duplicates were left
out, which is what I wanted.

## Why I used these commands

Commands:

- `find "$DIR" -type f` walks the folder and lists only real files.
- `md5sum` makes a short fingerprint of a file's content, which is how I spot
  identical files even if the names differ.
- `awk '{print $1}'` pulls just the checksum out of the md5sum line.
- `cp` copies a unique file into the backup folder.

Redirection operators (the main point of this question):

- `>` starts the report and error files empty at the top of each run.
- `>>` adds lines to those files without wiping what is already there.
- `2>>` is the important one. It sends only error messages (stream 2) into
  `errors.log`, so normal output and errors stay separate.
- `2>/dev/null` throws away output I do not need, like the tool check at the top.

File handling:

- I use the checksum instead of the file name, so renamed copies are still
  caught.
- A small temp file remembers which checksums I have already seen and which file
  they first came from.
- Normal results go to `report.txt` and errors go to `errors.log`, which keeps
  the two kinds of output apart.

Put together, `find` and `md5sum` catch the duplicates, `cp` saves the unique
work, append redirection builds the report, and `2>>` keeps the errors in their
own file. That covers all four parts of the question.