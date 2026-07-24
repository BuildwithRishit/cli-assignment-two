# Question 3: A File Utility Built on System Calls

## What the question asked

Write a program that creates a file, writes employee records, updates one record
without rewriting the whole file, and reads a record from any spot quickly. It
has to use raw system calls like `open`, `read`, `write`, `lseek`, and `close`
instead of the usual library functions.

## Files in this folder

- `employee_records.c` is the program.
- `employees.dat` is the data file it makes.
- `output.txt` is what the terminal showed when I ran it.

## The main idea

Every record is the same size, 48 bytes. So record number N always sits at byte
N times 48. Because the size never changes, I can jump straight to any record
with `lseek`, read just that one, or overwrite just that one.

## The commands I ran and what I saw

### 1. Compile the program

```
gcc -Wall -o employee_records employee_records.c
```

This built the program with no warnings, so the code is fine.

### 2. Run it

```
./employee_records
```

Step by step it created the file, wrote 4 records, jumped to record 2 and read
Carol, then updated Bob in place. The full list at the end showed only Bob's
salary changed, from 55000 to 72000. Everyone else stayed the same.

### 3. Check the file on disk

```
ls -l employees.dat
```

The file was 192 bytes, which is 4 records times 48 bytes each. That confirms the
records are a fixed size.

### 4. Look at the raw bytes (optional)

```
xxd employees.dat
```

The dump showed the names Alice, Bob, Carol, and David at neat 48 byte gaps. This
is a nice way to see the record layout.

## What each system call does

- `open` makes the file and gives me a file descriptor, which is a small number I
  use for every call after this. The `0644` mode sets safe permissions.
- `write` copies one record's bytes into the file. After each write the position
  moves forward on its own.
- `lseek` is the key one. It moves the read/write position to any byte I want. To
  read record 2 I seek to byte 96 first. To update Bob I seek to his slot and
  write over it, which is why the rest of the file is never touched.
- `read` copies one record's bytes back into a struct. With `lseek` this gives me
  random access to any record.
- `close` releases the file descriptor when I am done.

## Why system calls instead of fopen and fread

- They talk to the file directly, so an in place update lands exactly where I put
  it, with no hidden buffering to worry about.
- `lseek` gives me byte level positioning, which is perfect for a fixed size
  record file.
- `open` lets me set the file permissions right when I create it.

So `open` sets up the file, `write` fills it, `lseek` moves to the exact record,
`read` pulls records back, and `close` cleans up. That covers all four parts of
the question.