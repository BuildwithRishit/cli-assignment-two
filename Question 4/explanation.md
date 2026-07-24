# Question 4: Watching a Log File in Real Time

## What the question asked
Build a command pipeline that shows new log lines as they appear, pulls out the
ERROR messages, keeps them in a separate report file, and hides the output I do
not need.

## Files in this folder
- `app.log` is the sample log with INFO, WARN, and ERROR lines.
- `monitor.sh` runs the live version that watches the file as it grows.
- `generate_logs.sh` pretends to be a running server and keeps adding new lines.
- `extract_errors.sh` is the one shot version, which is easier to screenshot.
- `error_report.txt` is the report it produces.
- `output.txt` is what the terminal showed.

## The pipeline
```
tail -f app.log 2>/dev/null | grep --line-buffered "ERROR" | tee -a error_report.txt
```

## The commands I ran and what I saw

### 1. Make the scripts runnable
```
chmod +x monitor.sh generate_logs.sh extract_errors.sh
```
This gives the three scripts permission to run. It prints nothing, which is
normal.

### 2. Pull the errors out of the log
```
./extract_errors.sh
```
It printed the 3 ERROR lines from the log and said the error count was 3. It also
noted that 5 INFO lines were sent to `/dev/null`, so they were counted but not
shown.

### 3. Check the report file
```
cat error_report.txt
```
It held exactly those 3 ERROR lines and nothing else. That shows the report is
kept separate from the full log.

### 4. Watch it live (two terminals)
```
./monitor.sh          # terminal 1
./generate_logs.sh    # terminal 2
```
Terminal 2 kept adding new log lines. Every time an ERROR line was written, it
popped up in terminal 1 straight away and got added to the report. That is the
real time part working.

## Why each piece is there

- `tail -f` keeps the file open and prints each new line the moment it is added.
  This is much lighter than re reading a huge log over and over, because it only
  handles the new bytes.
- The pipe `|` sends the output of one command straight into the next one in
  memory. No temp files are made, so the data flows line by line.
- `grep "ERROR"` throws away the INFO and WARN noise and keeps only what matters.
  I added `--line-buffered` so grep sends each match through immediately instead
  of waiting for its buffer to fill, which is what makes it feel live.
- `tee -a error_report.txt` splits the stream. It writes the ERROR lines into the
  report and still prints them on screen, so I get both from one command.
- `2>/dev/null` sends unwanted messages to the trash. `/dev/null` is a special
  file that throws away anything written to it, so `tail`'s own notices do not
  clutter my alerts.

## Why this is efficient
It reacts to new data instead of scanning the file again and again. The pipes
keep everything in memory. `grep` drops the noise early so the report stays
small. And `/dev/null` gets rid of only the output I do not want, so what I see
on screen is actually useful.
