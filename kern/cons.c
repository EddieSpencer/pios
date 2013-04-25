/*
 * Main console driver for PIOS, which manages lower-level console devices
 * such as video (dev/video.*), keyboard (dev/kbd.*), and serial (dev/serial.*)
 *
 * Copyright (c) 2010 Yale University.
 * Copyright (c) 1993, 1994, 1995 Charles Hannum.
 * Copyright (c) 1990 The Regents of the University of California.
 * See section "BSD License" in the file LICENSES for licensing terms.
 *
 * This code is derived from the NetBSD pcons driver, and in turn derived
 * from software contributed to Berkeley by William Jolitz and Don Ahn.
 * Adapted for PIOS by Bryan Ford at Yale University.
 */

#include <inc/stdio.h>
#include <inc/stdarg.h>
#include <inc/x86.h>
#include <inc/string.h>
#include <inc/assert.h>
#line 21 "../kern/cons.c"
#include <inc/syscall.h>
#line 23 "../kern/cons.c"

#include <kern/cpu.h>
#include <kern/cons.h>
#include <kern/mem.h>
#line 28 "../kern/cons.c"
#include <kern/spinlock.h>
#line 31 "../kern/cons.c"
#include <kern/file.h>
#line 33 "../kern/cons.c"

#include <dev/video.h>
#include <dev/kbd.h>
#include <dev/serial.h>

void cons_intr(int (*proc)(void));
static void cons_putc(int c);

#line 42 "../kern/cons.c"
spinlock cons_lock;	// Spinlock to make console output atomic
#line 44 "../kern/cons.c"

/***** General device-independent console code *****/
// Here we manage the console input buffer,
// where we stash characters received from the keyboard or serial port
// whenever the corresponding interrupt occurs.

#define CONSBUFSIZE 512

static struct {
	uint8_t buf[CONSBUFSIZE];
	uint32_t rpos;
	uint32_t wpos;
} cons;

#line 59 "../kern/cons.c"
static int cons_outsize;	// Console output already written by root proc
#line 61 "../kern/cons.c"

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
void
cons_intr(int (*proc)(void))
{
	int c;

#line 70 "../kern/cons.c"
	spinlock_acquire(&cons_lock);
#line 72 "../kern/cons.c"
	while ((c = (*proc)()) != -1) {
		if (c == 0)
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
#line 80 "../kern/cons.c"
	spinlock_release(&cons_lock);

#line 83 "../kern/cons.c"
	// Wake the root process
	file_wakeroot();
#line 87 "../kern/cons.c"
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
	}
	return 0;
}

// output a character to the console
static void
cons_putc(int c)
{
	serial_putc(c);
	video_putc(c);
}

// initialize the console devices
void
cons_init(void)
{
	if (!cpu_onboot())	// only do once, on the boot CPU
		return;

#line 127 "../kern/cons.c"
	spinlock_init(&cons_lock);
#line 129 "../kern/cons.c"
	video_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
		warn("Serial port does not exist!\n");
}

#line 138 "../kern/cons.c"
// Enable console interrupts.
void
cons_intenable(void)
{
	if (!cpu_onboot())	// only do once, on the boot CPU
		return;

	kbd_intenable();
	serial_intenable();
}
#line 149 "../kern/cons.c"

// `High'-level console I/O.  Used by readline and cprintf.
void
cputs(const char *str)
{
#line 155 "../kern/cons.c"
	if (read_cs() & 3)
		return sys_cputs(str);	// use syscall from user mode

	// Hold the console spinlock while printing the entire string,
	// so that the output of different cputs calls won't get mixed.
	// Implement ad hoc recursive locking for debugging convenience.
	bool already = spinlock_holding(&cons_lock);
	if (!already)
		spinlock_acquire(&cons_lock);

#line 166 "../kern/cons.c"
	char ch;
	while (*str)
		cons_putc(*str++);
#line 170 "../kern/cons.c"

	if (!already)
		spinlock_release(&cons_lock);
#line 174 "../kern/cons.c"
}

#line 177 "../kern/cons.c"
// Synchronize the root process's console special files
// with the actual console I/O device.
bool
cons_io(void)
{
#line 183 "../kern/cons.c"
	spinlock_acquire(&cons_lock);
	bool didio = 0;

	// Console output from the root process's console output file
	fileinode *outfi = &files->fi[FILEINO_CONSOUT];
	const char *outbuf = FILEDATA(FILEINO_CONSOUT);
	assert(cons_outsize <= outfi->size);
	while (cons_outsize < outfi->size) {
		cons_putc(outbuf[cons_outsize++]);
		didio = 1;
	}

	// Console input to the root process's console input file
	fileinode *infi = &files->fi[FILEINO_CONSIN];
	char *inbuf = FILEDATA(FILEINO_CONSIN);
	int amount = cons.wpos - cons.rpos;
	if (infi->size + amount > FILE_MAXSIZE)
		panic("cons_io: root process's console input file full!");
	assert(amount >= 0 && amount <= CONSBUFSIZE);
	if (amount > 0) {
		memmove(&inbuf[infi->size], &cons.buf[cons.rpos], amount);
		infi->size += amount;
		cons.rpos = cons.wpos = 0;
		didio = 1;
	}

	spinlock_release(&cons_lock);
	return didio;
#line 216 "../kern/cons.c"
}
#line 218 "../kern/cons.c"

