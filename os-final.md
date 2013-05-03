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

We added the user code, user data trap stack segments to the global
descriptor table. We tried copying the lines that setup the kernel segments,
and we changed references to KCODE and KDATA to UCODE and UDATA.
It took us a while to realise we had to change the permission level from
0 to 3.

### cpu_init()

We setup the trap stack segment for the cpu so that when we trap into the 
kernel we get the correct stack.

We set the stack pointer to point to high kernel memory, and the stack segment
to point at kernel data.

## kern/debug.c

### debug_trace

Follow the ebp chain saving the eip of each frame in the stack.
We insert the last `DEBUG_TRACEFRAMES`  eips in the call stack into an array.
If there are less than that many frames on the stack we insert 0's.

## kern/init.c

We had to create a trap frame that would enter user() in user mode using 
the right stack. It took a while to track down all of the macros and magic
numbers we had to use, and we had help from posts on piazza.


## kern/mem.c

### mem_init()

Initialize the memory allocator and page info array and build a linked list of free pages.

I was confused as to which blocks of memory were meant to be initialized 
free and which were not free. Advice from Piazza helped here.

### mem_alloc()

Removes a page from the free list and marks it as non-free.
This function was pretty easy because I remembered linked lists from the
data structures class.


### mem_free()

Inserts a page back into the free list
This function was pretty easy because I remembered linked lists from the
data structures class.

## kern/trap.c

### trap_init_idt()

Initialized the interrupt descriptor table with default, or specified
handlers.


I thought that the SETGATE macro could have been better defined, it
took a while to realise that the last parameter let the trap be called
from user mode.

## kern/trapasm.S

We had to use the TRAPHANDLER and TRAPHANDLER_NOEC macros to build trap
handlers for the different traps. We had to write a function `alltraps`
which builds a trap frame by pushing the ds, es, fs, gs segments, and the
registers that track the state of a process, then calls trap in trap.c.
This was my first experience with AMS and the syntax took a while to
understand. I didn't realise that the macros could be used to build the 
trap handlers.

## lib/printfmt.c

Implemented flag to print octal numbers. This was easy because there were
already calls to print base 10 and 16 numbers so we just had to change 10
to 8.
