/*
 * Kernel initialization.
 *
 * Copyright (C) 1997 Massachusetts Institute of Technology
 * See section "MIT License" in the file LICENSES for licensing terms.
 *
 * Derived from the MIT Exokernel and JOS.
 * Adapted for PIOS by Bryan Ford at Yale University.
 */

#include <inc/stdio.h>
#include <inc/string.h>
#include <inc/assert.h>
#include <inc/cdefs.h>
#include <inc/elf.h>
#include <inc/vm.h>

#include <kern/init.h>
#include <kern/cons.h>
#include <kern/debug.h>
#include <kern/mem.h>
#include <kern/cpu.h>
#include <kern/trap.h>
#include <kern/spinlock.h>
#include <kern/mp.h>
#include <kern/proc.h>
#include <kern/file.h>

#include <dev/pic.h>
#include <dev/lapic.h>
#include <dev/ioapic.h>
#include <dev/nvram.h>


// User-mode stack for user(), below, to run on.
static char gcc_aligned(16) user_stack[PAGESIZE];

// Lab 3: ELF executable containing root process, linked into the kernel
#ifndef ROOTEXE_START
#define ROOTEXE_START _binary_obj_user_testfs_start
#endif
extern char ROOTEXE_START[];


// Called first from entry.S on the bootstrap processor,
// and later from boot/bootother.S on all other processors.
// As a rule, "init" functions in PIOS are called once on EACH processor.
void
init(void)
{
	extern char start[], edata[], end[];

	// Before anything else, complete the ELF loading process.
	// Clear all uninitialized global data (BSS) in our program,
	// ensuring that all static/global variables start out zero.
	if (cpu_onboot())
		memset(edata, 0, end - edata);

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();

	//copy the low memory bootothers code.
	extern uint8_t _binary_obj_boot_bootother_start[],
			_binary_obj_boot_bootother_size[];
	uint8_t *code = (uint8_t*)lowmem_bootother_vec;
	memmove(code, _binary_obj_boot_bootother_start,
		(uint32_t)_binary_obj_boot_bootother_size);

	// Initialize and load the bootstrap CPU's GDT, TSS, and IDT.
	cpu_init();
	trap_init();

	// Physical memory detection/initialization.
	// Can't call mem_alloc until after we do this!
	mem_init();

	// Lab 2: check spinlock implementation
	if (cpu_onboot())
		spinlock_check();

	// Initialize the paged virtual memory system.
	pmap_init();

	// Find and start other processors in a multiprocessor system
	mp_init();		// Find info about processors in system
	pic_init();		// setup the legacy PIC (mainly to disable it)
	ioapic_init();		// prepare to handle external device interrupts
	lapic_init();		// setup this CPU's local APIC
	cpu_bootothers();	// Get other processors started
//	cprintf("CPU %d (%s) has booted\n", cpu_cur()->id,
//		cpu_onboot() ? "BP" : "AP");

	// Initialize the I/O system.
	file_init();		// Create root directory and console I/O files

	cons_intenable();	// Let the console start producing interrupts

	// Initialize the process management code.
	proc_init();

	if (!cpu_onboot())
		proc_sched();	// just jump right into the scheduler


	// Create our first actual user-mode process
	proc *root = proc_root = proc_alloc(NULL, 0);

	elfhdr *eh = (elfhdr *)ROOTEXE_START;
	assert(eh->e_magic == ELF_MAGIC);

	// Load each program segment
	proghdr *ph = (proghdr *) ((void *) eh + eh->e_phoff);
	proghdr *eph = ph + eh->e_phnum;
	for (; ph < eph; ph++) {
		if (ph->p_type != ELF_PROG_LOAD)
			continue;
	
		void *fa = (void *) eh + ROUNDDOWN(ph->p_offset, PAGESIZE);
		uint32_t va = ROUNDDOWN(ph->p_va, PAGESIZE);
		uint32_t zva = ph->p_va + ph->p_filesz;
		uint32_t eva = ROUNDUP(ph->p_va + ph->p_memsz, PAGESIZE);

		uint32_t perm = SYS_READ | PTE_P | PTE_U;
		if (ph->p_flags & ELF_PROG_FLAG_WRITE)
			perm |= SYS_WRITE | PTE_W;

		for(; va < eva; va += PAGESIZE, fa += PAGESIZE) {
			pageinfo *pi = mem_alloc(); assert(pi != NULL);
			if (va < ROUNDDOWN(zva, PAGESIZE)) // complete page
				memmove(mem_pi2ptr(pi), fa, PAGESIZE);
			else if (va < zva && ph->p_filesz) {	// partial
				memset(mem_pi2ptr(pi), 0, PAGESIZE);
				memmove(mem_pi2ptr(pi), fa, zva-va);
			} else			// all-zero page
				memset(mem_pi2ptr(pi), 0, PAGESIZE);
			pte_t *pte = pmap_insert(root->pdir, pi, va, perm);
			assert(pte != NULL);
		}
	}

	// Start the process at the entry indicated in the ELF header
	root->sv.tf.eip = eh->e_entry;
	root->sv.tf.eflags |= FL_IF;	// enable interrupts

	// Give the process a 1-page stack in high memory
	// (the process can then increase its own stack as desired)
	pageinfo *pi = mem_alloc(); assert(pi != NULL);
	pte_t *pte = pmap_insert(root->pdir, pi, VM_STACKHI-PAGESIZE,
				SYS_READ | SYS_WRITE | PTE_P | PTE_U | PTE_W);
	assert(pte != NULL);
	root->sv.tf.esp = VM_STACKHI;

	// Give the root process an initial file system.
	file_initroot(root);

	proc_ready(root);	// make the root process ready
	proc_sched();		// run it
}

// This is the first function that gets run in user mode (ring 3).
// It acts as PIOS's "root process",
// of which all other processes are descendants.
void
user()
{
	cprintf("in user()\n");
	assert(read_esp() > (uint32_t) &user_stack[0]);
	assert(read_esp() < (uint32_t) &user_stack[sizeof(user_stack)]);


	done();
}

// This is a function that we call when the kernel is "done" -
// it just puts the processor into an infinite loop.
// We make this a function so that we can set a breakpoints on it.
// Our grade scripts use this breakpoint to know when to stop QEMU.
void gcc_noreturn
done()
{
	while (1)
		;	// just spin
}

