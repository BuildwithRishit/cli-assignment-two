/*============================================================================
 * A secure file-processing utility built on raw Linux SYSTEM CALLS
 * (open/read/write/lseek/close) instead of the stdio library (fopen/fread...).
 *
 * It demonstrates:
 *   1. Creating a file.
 *   2. Writing fixed-size employee records.
 *   3. Updating ONE record in place (without rewriting the whole file).
 *   4. Retrieving a record from ANY location efficiently (random access).
 *
 * Build : gcc -o employee_records employee_records.c
 * Run   : ./employee_records
 *==========================================================================*/

#include <fcntl.h> /* open, O_* flags                 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <unistd.h> /* read, write, lseek, close       */

#define DB_FILE "employees.dat"
#define NAME_LEN 32

/* Fixed-size record => record N always lives at byte offset N*sizeof(record).
   This constant size is what makes random access by lseek possible. */
struct Employee {
  int id;
  char name[NAME_LEN];
  double salary;
};

static void print_record(const struct Employee *e) {
  printf("     id=%-4d name=%-10s salary=%.2f\n", e->id, e->name, e->salary);
}

int main(void) {
  const size_t RSZ = sizeof(struct Employee);

  struct Employee staff[] = {
      {101, "Alice", 50000.0},
      {102, "Bob", 55000.0},
      {103, "Carol", 60000.0},
      {104, "David", 65000.0},
  };
  int n = (int)(sizeof(staff) / sizeof(staff[0]));

  /*----------------------------------------------------------------------
   * 1) open()  -- CREATE the file for reading and writing.
   *    O_CREAT  : create if it does not exist
   *    O_RDWR   : we will both write and read
   *    O_TRUNC  : start empty on each run
   *    0644     : owner rw, group/others r  (secure default)
   *--------------------------------------------------------------------*/
  int fd = open(DB_FILE, O_RDWR | O_CREAT | O_TRUNC, 0644);
  if (fd < 0) {
    perror("open");
    exit(EXIT_FAILURE);
  }
  printf("[1] open(): created '%s' (fd=%d), record size=%zu bytes\n", DB_FILE,
         fd, RSZ);

  /*----------------------------------------------------------------------
   * 2) write()  -- store all records sequentially.
   *    The file offset advances automatically after each write.
   *--------------------------------------------------------------------*/
  for (int i = 0; i < n; i++) {
    if (write(fd, &staff[i], RSZ) != (ssize_t)RSZ) {
      perror("write");
      close(fd);
      exit(EXIT_FAILURE);
    }
  }
  printf("[2] write(): stored %d records (%zu bytes total)\n", n, n * RSZ);

  /*----------------------------------------------------------------------
   * 3) lseek() + read()  -- RANDOM ACCESS: jump straight to record #2
   *    (Carol) at offset 2*RSZ and read only that record. We do NOT read
   *    records 0 and 1 -- this is the efficiency the question asks for.
   *--------------------------------------------------------------------*/
  struct Employee tmp;
  off_t offset2 = (off_t)2 * RSZ;
  lseek(fd, offset2, SEEK_SET);
  read(fd, &tmp, RSZ);
  printf("[3] lseek()+read(): random read of record #2 at offset %lld:\n",
         (long long)offset2);
  print_record(&tmp);

  /*----------------------------------------------------------------------
   * 4) lseek() + write()  -- UPDATE IN PLACE: give Bob (record #1) a raise
   *    by seeking to his slot and overwriting ONLY his record. The other
   *    records are never touched and the file is not rewritten.
   *--------------------------------------------------------------------*/
  struct Employee raised = {102, "Bob", 72000.0};
  off_t offset1 = (off_t)1 * RSZ;
  lseek(fd, offset1, SEEK_SET);
  write(fd, &raised, RSZ);
  printf("[4] lseek()+write(): updated record #1 in place "
         "(Bob salary 55000 -> 72000)\n");

  /*----------------------------------------------------------------------
   * 5) Prove only record #1 changed: rewind and read the whole file.
   *--------------------------------------------------------------------*/
  printf("[5] Full file after update:\n");
  lseek(fd, 0, SEEK_SET);
  while (read(fd, &tmp, RSZ) == (ssize_t)RSZ)
    print_record(&tmp);

  /*----------------------------------------------------------------------
   * 6) close()  -- release the file descriptor and flush to disk.
   *--------------------------------------------------------------------*/
  if (close(fd) == 0)
    printf("[6] close(): file descriptor released.\n");

  return 0;
}