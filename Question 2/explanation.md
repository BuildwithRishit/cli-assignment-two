# Question 2: Stopping Zombies and Runaway Child Processes

## What the question asked
Write a C program that makes child processes with `fork()`, watches them,
stops zombie processes from piling up, and kills a child that will not finish
on its own using signals.

## Files in this folder
- `process_manager.c` is the program.
- `output.txt` is what the terminal showed when I ran it.

## The commands I ran and what I saw

### 1. Compile the program
```
gcc -Wall -o process_manager process_manager.c
```
This built the program and printed no warnings, so the code is clean. On my Mac
`gcc` is actually clang, which is fine.

### 2. Run it
```
./process_manager
```
The parent made three children. Children 1 and 2 did a short job and were cleaned
up right away, so the reap count went up to 2. Child 3 was stuck on purpose, so
after the timeout the parent sent it SIGTERM. The last line said all three were
reaped and no zombies were left.

### 3. Check for zombies
```
ps aux | grep -w '<defunct>' | grep -v grep
```
This looks for zombie processes, which show up as `<defunct>`. It printed
nothing, so there were no zombies left behind.

## How the pieces work together

### Making the children with fork()
`fork()` copies the process. It returns 0 in the child and the child's PID in the
parent, so each side knows who it is. The parent saves every child PID so it can
check on them and signal them later.

### Cleaning up with waitpid()
When a child ends it does not vanish. It stays as a zombie until the parent reads
its exit status. I read it with `waitpid(-1, &status, WNOHANG)`. The `-1` means
any child and `WNOHANG` means do not block if nobody has exited yet. Reading the
status is what clears the zombie.

### Signals tie it all together
- SIGCHLD is sent to the parent every time a child exits. My handler catches it
  and reaps the finished children in a loop. This is the automatic cleanup that
  keeps zombies from building up, and the parent never has to sit and wait.
- SIGTERM is what the parent sends to the stuck child after the timeout. It asks
  the child to shut down nicely.
- SIGKILL is the backup. If a child ignored SIGTERM, SIGKILL cannot be blocked,
  so it forces the child to stop.
- `kill(pid, 0)` sends no signal at all. It just checks if the process is still
  alive, which is how I decide who is stuck.

### Why they need each other
`fork()` on its own makes children but leaves the parent blind to what happens to
them. `waitpid()` on its own would make the parent stop and wait. Signals fix
both problems. SIGCHLD tells the parent when to reap without blocking, and
SIGTERM or SIGKILL let the parent remove a child that will never finish. Together
they let a server start workers, keep the process table clean, and shut down a
worker that hangs.

## A few safety notes
- The SIGCHLD handler only calls `waitpid` and bumps a counter, and it saves and
  restores `errno`, so it cannot mess up the main program.
- I set stdout to unbuffered so `fork()` does not copy a half printed line into
  the children and double it up.