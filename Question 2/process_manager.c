/*
 * This program demonstrates how to:
 *   1. Create child processes with fork().
 *   2. Monitor their execution.
 *   3. Prevent ZOMBIE processes (by reaping children as they exit).
 *   4. Terminate an UNRESPONSIVE child using signals (SIGTERM, then SIGKILL).
 *
 * Build : gcc -o process_manager process_manager.c
 * Run   : ./process_manager
 */

#include <errno.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

#define NUM_CHILDREN 3    /* how many workers to spawn            */
#define MONITOR_TIMEOUT 3 /* seconds parent watches before killing */

static pid_t children[NUM_CHILDREN];
static volatile sig_atomic_t reaped_count = 0; /* updated by the handler */

/*----------------------------------------------------------------------------
 * SIGCHLD handler: reap EVERY finished child immediately.
 * Reaping (via waitpid) is what PREVENTS ZOMBIES. A terminated child stays a
 * "zombie" only until its parent collects its exit status.
 * WNOHANG makes waitpid non-blocking so the handler never stalls.
 *--------------------------------------------------------------------------*/
static void sigchld_handler(int sig) {
  (void)sig;
  int saved_errno = errno; /* handlers must not clobber errno */
  pid_t pid;
  int status;
  while ((pid = waitpid(-1, &status, WNOHANG)) > 0) {
    reaped_count++; /* one more child cleaned up        */
  }
  errno = saved_errno;
}

/*----------------------------------------------------------------------------
 * Work performed by each child.
 *  - children 0 and 1 do a short job and exit on their own (well-behaved).
 *  - child 2 is the "unresponsive" worker: it never finishes by itself and
 *    must be terminated by the parent with a signal.
 *--------------------------------------------------------------------------*/
static void child_work(int index) {
  if (index == NUM_CHILDREN - 1) {
    printf("  [child %d pid=%d] UNRESPONSIVE: entering infinite wait...\n",
           index + 1, (int)getpid());
    fflush(stdout);
    for (;;)
      pause(); /* sleep until a signal arrives     */
  } else {
    int seconds = index + 1; /* child1 -> 1s, child2 -> 2s        */
    printf("  [child %d pid=%d] working for %d second(s)...\n", index + 1,
           (int)getpid(), seconds);
    fflush(stdout);
    sleep(seconds);
    printf("  [child %d pid=%d] finished normally, exiting.\n", index + 1,
           (int)getpid());
    fflush(stdout);
    _exit(0);
  }
}

int main(void) {
  /* Make stdout unbuffered so a not-yet-flushed buffer is never duplicated
     into the children by fork() (keeps the demo output clean). */
  setvbuf(stdout, NULL, _IONBF, 0);

  /* 1) Install the SIGCHLD handler BEFORE forking, so no exit is missed. */
  struct sigaction sa;
  memset(&sa, 0, sizeof(sa));
  sa.sa_handler = sigchld_handler;
  sigemptyset(&sa.sa_mask);
  sa.sa_flags = SA_RESTART | SA_NOCLDSTOP;
  if (sigaction(SIGCHLD, &sa, NULL) == -1) {
    perror("sigaction");
    exit(EXIT_FAILURE);
  }

  printf("[parent pid=%d] creating %d child processes with fork()...\n",
         (int)getpid(), NUM_CHILDREN);

  /* 2) Create the children. */
  for (int i = 0; i < NUM_CHILDREN; i++) {
    pid_t pid = fork();
    if (pid < 0) {
      perror("fork");
      exit(EXIT_FAILURE);
    }
    if (pid == 0) { /* child branch */
      child_work(i);
      _exit(0); /* safety net */
    }
    children[i] = pid; /* parent remembers each child pid  */
  }

  /* 3) Monitor: let well-behaved children finish and be auto-reaped. */
  printf("[parent] monitoring for %d seconds "
         "(SIGCHLD auto-reaps finished children)...\n",
         MONITOR_TIMEOUT);
  for (int t = 0; t < MONITOR_TIMEOUT; t++) {
    sleep(1);
    printf("[parent] tick %d/%d : children reaped so far = %d\n", t + 1,
           MONITOR_TIMEOUT, reaped_count);
  }

  /* 4) Any child STILL alive after the timeout is unresponsive. */
  for (int i = 0; i < NUM_CHILDREN; i++) {
    if (kill(children[i], 0) == 0) { /* signal 0 = "does it exist?" */
      printf("[parent] child %d (pid=%d) is UNRESPONSIVE "
             "-> sending SIGTERM (graceful)\n",
             i + 1, (int)children[i]);
      kill(children[i], SIGTERM);
    }
  }

  sleep(1);

  /* Escalate to SIGKILL for anything that ignored SIGTERM. */
  for (int i = 0; i < NUM_CHILDREN; i++) {
    if (kill(children[i], 0) == 0) {
      printf("[parent] child %d (pid=%d) ignored SIGTERM "
             "-> sending SIGKILL (forceful)\n",
             i + 1, (int)children[i]);
      kill(children[i], SIGKILL);
    }
  }

  /* 5) Final drain: block until there are truly no children left. */
  int status;
  while (waitpid(-1, &status, 0) > 0) { /* reap any straggler */
  }
  /* waitpid now returns -1 (errno ECHILD) = no children remain = no zombies */

  printf("[parent] total children reaped = %d. "
         "No zombie processes remain. Done.\n",
         reaped_count);
  return 0;
}