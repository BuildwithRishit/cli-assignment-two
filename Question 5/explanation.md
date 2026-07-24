# Question 5: Getting a File Back in vi After a Crash

## What the question asked
A developer is editing a config file in vi and the system crashes before they
save. Look at the different ways vi can recover the file (swap files, undo
history, registers, backup files, auto recovery), then pick the most reliable one
and explain why.

## Files in this folder
- `app.conf` is the config file being edited.
- `simulate_crash.sh` recreates the whole crash and recovery in one command.
- `.app.conf.swp` is the swap file left behind by the crash.
- `recovered_app.conf` is what came back after recovery.
- `output.txt` is what the terminal showed.

## What my demo proves
I opened `app.conf` in vim and added a line, `CRASH_TEST=recovered`, but never
saved it. Then I killed vim with `kill -9` to act like a crash. The line was
never written into `app.conf`. But `vim -r app.conf` brought it back from the
swap file. So work that looked lost was recovered.

## The commands I ran and what I saw

### 1. Run the crash demo
```
./simulate_crash.sh
```
It made the config file, added an unsaved line, then hard killed vim. After that
it showed the leftover swap file and ran the recovery.

### 2. Look for the swap file
```
ls -a
```
There was a hidden file called `.app.conf.swp`. vim made it automatically when I
opened the file, and it survived the crash.

### 3. Recover the file
```
vim -r app.conf
```
vim said "Using swap file .app.conf.swp" and "Recovery completed". The buffer had
my unsaved `CRASH_TEST` line back in it, so the recovery worked.

## Looking at each recovery method

### Swap files (.swp) - the real crash recovery
As soon as you open a file, vim makes a hidden swap file and keeps writing your
changes into it while you type. It lives on disk, not in memory, so a crash does
not wipe it. `vim -r file` reads it back.

Good: it survives a crash and it holds unsaved work. This is the one that
actually solves the problem.
Limit: it only goes up to the last time vim flushed to the swap, and it is no
help if the disk itself is gone.

### Undo history - dies with the crash
`u` and `Ctrl-r` step back and forward through your edits, but that history sits
in memory. When the machine crashes it goes with it.

Good: great for fixing mistakes while you are working.
Limit: useless after a crash, unless you turned on `:set undofile` beforehand,
which is off by default.

### Registers - just a clipboard
Registers hold text you yanked or deleted. They are a manual copy paste store
that lives in memory for that session only.

Good: handy for keeping a snippet while editing.
Limit: in memory, manual, and gone after a crash. Not a recovery tool at all.

### Backup files (~) - protects the last saved version
With `:set backup`, vim keeps a copy of what the file looked like before your
last save.

Good: lets you undo a bad save.
Limit: it only has saved content, so your unsaved edits are still lost. It
protects against a bad write, not a crash.

### Auto recovery - the way you use the swap file
This is vim noticing the leftover swap file when you reopen the file and offering
to recover, or you running `vim -r` yourself.

Good: finds the problem for you and restores in one step.
Limit: it is only as good as the swap file behind it.

## My answer: which one is best

The swap file with `vim -r` is the most reliable way to get unsaved work back
after a crash. It is the only method that is written to disk while you type, and
the only one that holds changes you never saved. My demo above proves it.

For a config file that actually matters, I would layer a few things so one
failure does not lose the work:

1. Leave swap files on, since that is the main safety net. After a crash, run
   `vim -r file` and then diff it against the file on disk before overwriting.
2. Turn on `:set undofile` so undo history survives between sessions.
3. Turn on `:set backup` so a bad save can be rolled back.
4. Save often and keep the file in git, which is the strongest history of all.

The reason is simple. The swap file handles the exact problem in the question,
which is unsaved work plus a crash. The undo file and backups cover the gaps that
swap files do not, and saving often plus git means the file is still safe even if
the swap file itself is lost.

One small note: after recovering, delete the old swap file with
`rm .app.conf.swp` so vim stops warning you about it next time.
