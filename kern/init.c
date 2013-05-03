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
#include <dev/nvram.h>
#include <kern/file.h>
#include <dev/pic.h>
#include <dev/lapic.h>
#include <dev/ioapic.h>

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

  	extern uint8_t _binary_obj_boot_bootother_start[],
    	_binary_obj_boot_bootother_size[];

  	uint8_t *code = (uint8_t*)lowmem_bootother_vec;
  	memmove(code, _binary_obj_boot_bootother_start, (uint32_t) _binary_obj_boot_bootother_size);

	// Lab 1: test cprintf and debug_trace
	cprintf("1234 decimal is %o octal!\n", 1234);
	debug_check();

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

	file_init();		// Create root directory and console I/O files

	// Lab 4: uncomment this when you can handle IRQ_SERIAL and IRQ_KBD.
	cons_intenable();	// Let the console start producing interrupts

	// Initialize the process management code.
	proc_init();
	if(!cpu_onboot())
		proc_sched();
 	proc *root = proc_root = proc_alloc(NULL,0);
  
  	elfhdr *ehs = (elfhdr *)ROOTEXE_START;
  	assert(ehs->e_magic == ELF_MAGIC);

  	proghdr *phs = (proghdr *) ((void *) ehs + ehs->e_phoff);
  	proghdr *ep = phs + ehs->e_phnum;

  	for (; phs < ep; phs++)
	{
    		if (phs->p_type != ELF_PROG_LOAD)
      		continue;

    		void *fa = (void *) ehs + ROUNDDOWN(phs->p_offset, PAGESIZE);
    		uint32_t va = ROUNDDOWN(phs->p_va, PAGESIZE);
    		uint32_t zva = phs->p_va + phs->p_filesz;
    		uint32_t eva = ROUNDUP(phs->p_va + phs->p_memsz, PAGESIZE);

    		uint32_t perm = SYS_READ | PTE_P | PTE_U;
    		if(phs->p_flags & ELF_PROG_FLAG_WRITE) perm |= SYS_WRITE | PTE_W;

    		for (; va < eva; va += PAGESIZE, fa += PAGESIZE) 
		{
    			pageinfo *pi = mem_alloc(); assert(pi != NULL);
      			if(va < ROUNDDOWN(zva, PAGESIZE))
        			memmove(mem_pi2ptr(pi), fa, PAGESIZE);
      			else if (va < zva && phs->p_filesz)
			{
      				memset(mem_pi2ptr(pi),0, PAGESIZE);
      				memmove(mem_pi2ptr(pi), fa, zva-va);
      			} 
			else
        			memset(mem_pi2ptr(pi), 0, PAGESIZE);

      			pte_t *pte = pmap_insert(root->pdir, pi, va, perm);
      			assert(pte != NULL);
      		}
      }

      root->sv.tf.eip = ehs->e_entry;
      root->sv.tf.eflags |= FL_IF;

      pageinfo *pi = mem_alloc(); assert(pi != NULL);
      pte_t *pte = pmap_insert(root->pdir, pi, VM_STACKHI-PAGESIZE,
      SYS_READ | SYS_WRITE | PTE_P | PTE_U | PTE_W);

      assert(pte != NULL);
      root->sv.tf.esp = VM_STACKHI;
			// Give the root process an initial file system.
			file_initroot(root);

			proc_ready(root);
			proc_sched();
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

	// Check the system call and process scheduling code.
  	cprintf("proc_check");
	proc_check();

	// Check that we're in user mode and can handle traps from there.
	trap_check_user();

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

