Caleb Everett
OS Final

# Project 1

## dev/video.c


	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS,
			(CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
	}

This code scrolls the screen when it fills with text

## kern/cpu.c

### cpu_boot()

Add the user code and user data trap stack segments to the global
descriptor table. 

We tried copying the lines that setup the kernel segments,
and we changed references to KCODE and KDATA to UCODE and UDATA.
It took us a while to realise we had to change the permission level from
0 to 3.

### cpu_init()

Setup the trap stack segment for the cpu so that when we trap into the 
kernel we get the correct stack.

Set the stack pointer to point to high kernel memory, and the stack segment
to point at kernel data.

## kern/debug.c

### debug_trace

Follow the ebp chain saving the `eip` of each frame in the stack.
`DEBUG_TRACEFRAMES` stores the number of frames to save.
Insert the last `n` eips in the call stack into an array.
If there are less than `n` frames on the stack we fill the reset of the 
array with 0

## kern/init.c

Create a trap frame that will enter `user()` in user mode using the 
right stack. 

It took a while to track down all of the macros and magic
numbers we had to use, and we had help from posts on piazza.


## kern/mem.c

### mem_init()

Initialize the memory allocator and page info array and build a linked 
list of free pages.

I was confused as to which blocks of memory were meant to be initialized 
free and which were not free. Advice from Piazza helped here.

### mem_alloc()

Remove a page from the free list and marks it as non-free.

This function was pretty easy because I remembered linked lists from the
data structures class.


### mem_free()

Insert a page back into the free list

This function was pretty easy because I remembered linked lists from the
data structures class.

## kern/trap.c

### trap_init_idt()

Initialize the interrupt descriptor table with default, or specified
handlers.


I thought that the SETGATE macro could have been better explained, it
took us a while to realise that the last parameter let the trap be called
from user mode.

## kern/trapasm.S

Use the `TRAPHANDLER` and `TRAPHANDLER_NOEC` macros to build trap
handlers for the different traps using the IA 32 guide. 

Write a function `alltraps` which builds a trap frame by pushing 
the `ds`, `es`, `fs`, `gs` segments, and the registers that track the 
state of a process, then calls `trap` in `trap.c`. 

This was my first experience with ASM and the syntax took a while to
understand. I did not realise that the macros could be used to build the 
trap handlers at first.

## lib/printfmt.c

Implement `%o` flag to print octal numbers. 

This was easy because there were already calls to print base 10 and 16 
numbers so we just had to change 10 to 8.

# Project 2

## kern/init.c

Create a root process which runs the `user` function in user mode
by pointing the process's instruction pointer to the user function,
and the stack pointer to the user stack. Schedule and run the 
process.

We had to track down the proc struct and figure out how to interface 
with it.

## kern/mem.c

Use spinlocks to ensure no two processes can modify the free chain at 
the same time. Anytime items are being added or removed from the free
chain acquire the lock before the operation and released it after.

## kern/proc.c

Create a linked list of ready processes and functions to run, stop,
pause, and schedule processes.

### proc_init

Initialize the ready spinlock and the ready linked list.
Because the list is empty the tail should point at the head of the list.

### proc_ready

Set the process state to ready, and push it onto the end of the ready 
list.

### proc_save

Save the process state by copying it's trapframe into the proc.

### proc_wait

Parent process waits for child process to finish.

Set parent state to waiting, and clear it's running cpu.
Set the parents `waitchild` to a pointer to the child.
Call `proc_save` on the parent, and schedule the next process to run with
`proc_sched`.

### proc_sched

Schedule and run the next process in the ready list. If there are no ready
processes wait for one to be added to the ready list.

Wait for a ready process in the ready list (this code was provided 
on Piazza).
Remove the ready process from the list, ensuring to point the head of the
list at the next process in the list.

Call `proc_run` on the process removed from the ready list.

### proc_run

Set the process's state to running, and it's running cpu to the current cpu.
Set the current cpu's running process to the current process.

Use `trap_return` to load the processes saved trapframe onto the current
cpu, restoring the process's state.

### proc_yield

The current process yields the cpu to the next scheduled process.

Clear the current process's running cpu, save it's state and trapframe,
 and call `proc_ready`.

Call `proc_sched` to run the next scheduled process.

It seems like this could stop a process, then start it again if it is the 
only process being ran, which seems like inefficient. I wonder if you 
could check ready list, and skip `proc_yeild` if it is empty.

### proc_ret

Check that the current process is not the root process by ensuring it has
a parent process. If it is not the root process set it's state to stopped,
and clear it's running cpu then save it with `proc_save`.

If the process's parent process was waiting for it to finish 
(someone called `proc_wait` on it) wake up that process and run it.

Run the next scheduled process by calling `proc_sched`.

## kern/spinlock.c

### spinlock_init_

Initialize a lock in the unlocked state, `locked` and `cpu` both equal 0.
`file` and `line` point to the file and line where the lock was initialized.
`spinlock_init_` should not be called directly, use the macro `spinlock_init`
which calls `spinlock_init_` with the correct file and line arguments.

### spinlock_acquire

Make sure this cpu is not already holding this lock.
Wait for the lock to become free, using `xchg` to atomically check and set 
the value of locked.

### spinlock_release

Make sure this cpu is holding the lock and uses `xchg` to unlock the lock.

### spinlock_holding

Return true if the lock is locked and calling cpu holds that lock.

## kern/trap.c

Add gates IQR and system call traps, and add switch cases for specific traps.
Pass system call traps to `syscall` if they are from user space.

Overflow and breakpoint traps should be passed on to the parent process.

Timer traps should call `proc_yeild` so other process can use the cpu.
