#line 2 "../kern/cpu.c"
/*
 * CPU setup and management of key protected-mode data structures,
 * such as global descriptor table (GDT) and task state segment (TSS).
 *
 * Copyright (C) 2010 Yale University.
 * See section "MIT License" in the file LICENSES for licensing terms.
 *
 * Primary author: Bryan Ford
 */

#include <inc/assert.h>
#include <inc/string.h>

#include <kern/mem.h>
#include <kern/cpu.h>
#include <kern/init.h>

#line 20 "../kern/cpu.c"
#include <dev/lapic.h>
#line 22 "../kern/cpu.c"


cpu cpu_boot = {

	// Global descriptor table for bootstrap CPU.
	// The GDTs for other CPUs are copied from this and fixed up.
	//
	// The kernel and user segments are identical except for the DPL.
	// To load the SS register, the CPL must equal the DPL.  Thus,
	// we must duplicate the segments for the user and the kernel.
	//
	// The only descriptor that differs across CPUs is the TSS descriptor.
	//
	gdt: {
		// 0x0 - unused (always faults: for trapping NULL far pointers)
		[0] = SEGDESC_NULL,

		// 0x08 - kernel code segment
		[CPU_GDT_KCODE >> 3] = SEGDESC32(1, STA_X | STA_R, 0x0,
					0xffffffff, 0),

		// 0x10 - kernel data segment
		[CPU_GDT_KDATA >> 3] = SEGDESC32(1, STA_W, 0x0,
					0xffffffff, 0),
#line 47 "../kern/cpu.c"

		// 0x18 - user code segment
		[CPU_GDT_UCODE >> 3] = SEGDESC32(1, STA_X | STA_R,
					0x00000000, 0xffffffff, 3),

		// 0x20 - user data segment
		[CPU_GDT_UDATA >> 3] = SEGDESC32(1, STA_W,
					0x00000000, 0xffffffff, 3),

#line 62 "../kern/cpu.c"
		// 0x30 - tss, initialized in cpu_init()
		[CPU_GDT_TSS >> 3] = SEGDESC_NULL,
#line 65 "../kern/cpu.c"
	},

	magic: CPU_MAGIC
};

#line 135 "../kern/cpu.c"

void cpu_init()
{
	cpu *c = cpu_cur();

#line 145 "../kern/cpu.c"

	// Setup the TSS for this cpu so that we get the right stack
	// when we trap into the kernel from user mode.
	c->tss.ts_esp0 = (uint32_t) c->kstackhi;
	c->tss.ts_ss0 = CPU_GDT_KDATA;

	// Initialize the non-constant part of the cpu's GDT:
	// the TSS descriptor is different for each cpu.
	c->gdt[CPU_GDT_TSS >> 3] = SEGDESC16(0, STS_T32A, (uint32_t) (&c->tss),
					sizeof(taskstate)-1, 0);

#line 157 "../kern/cpu.c"
	// Load the GDT
	struct pseudodesc gdt_pd = {
		sizeof(c->gdt) - 1, (uint32_t) c->gdt };
	asm volatile("lgdt %0" : : "m" (gdt_pd));

	// Reload all segment registers.
	asm volatile("movw %%ax,%%gs" :: "a" (CPU_GDT_UDATA|3));
	asm volatile("movw %%ax,%%fs" :: "a" (CPU_GDT_UDATA|3));
	asm volatile("movw %%ax,%%es" :: "a" (CPU_GDT_KDATA));
	asm volatile("movw %%ax,%%ds" :: "a" (CPU_GDT_KDATA));
	asm volatile("movw %%ax,%%ss" :: "a" (CPU_GDT_KDATA));
	asm volatile("ljmp %0,$1f\n 1:\n" :: "i" (CPU_GDT_KCODE)); // reload CS

	// We don't need an LDT.
	asm volatile("lldt %%ax" :: "a" (0));
#line 173 "../kern/cpu.c"

	// Load the TSS (from the GDT)
	ltr(CPU_GDT_TSS);
#line 177 "../kern/cpu.c"
}

#line 180 "../kern/cpu.c"
// Allocate an additional cpu struct representing a non-bootstrap processor.
cpu *
cpu_alloc(void)
{
	// Pointer to the cpu.next pointer of the last CPU on the list,
	// for chaining on new CPUs in cpu_alloc().  Note: static.
	static cpu **cpu_tail = &cpu_boot.next;

	pageinfo *pi = mem_alloc();
	assert(pi != 0);	// shouldn't be out of memory just yet!

	cpu *c = (cpu*) mem_pi2ptr(pi);

	// Clear the whole page for good measure: cpu struct and kernel stack
	memset(c, 0, PAGESIZE);

	// Now we need to initialize the new cpu struct
	// just to the same degree that cpu_boot was statically initialized.
	// The rest will be filled in by the CPU itself
	// when it starts up and calls cpu_init().

	// Initialize the new cpu's GDT by copying from the cpu_boot.
	// The TSS descriptor will be filled in later by cpu_init().
	assert(sizeof(c->gdt) == sizeof(segdesc) * CPU_GDT_NDESC);
	memmove(c->gdt, cpu_boot.gdt, sizeof(c->gdt));

	// Magic verification tag for stack overflow/cpu corruption checking
	c->magic = CPU_MAGIC;

	// Chain the new CPU onto the tail of the list.
	*cpu_tail = c;
	cpu_tail = &c->next;

	return c;
}

void
cpu_bootothers(void)
{
	extern uint8_t _binary_obj_boot_bootother_start[],
			_binary_obj_boot_bootother_size[];

	if (!cpu_onboot()) {
		// Just inform the boot cpu we've booted.
		xchg(&cpu_cur()->booted, 1);
		return;
	}

	// Write bootstrap code to unused memory at 0x1000.
	uint8_t *code = (uint8_t*)0x1000;
	//memmove(code, _binary_obj_boot_bootother_start,
	//	(uint32_t)_binary_obj_boot_bootother_size);

	cpu *c;
	for(c = &cpu_boot; c; c = c->next){
		if(c == cpu_cur())  // We''ve started already.
			continue;

		// Fill in %esp, %eip and start code on cpu.
		*(void**)(code-4) = c->kstackhi;
		*(void**)(code-8) = init;
		uint8_t *bootother = (uint8_t*)0x1010;
		lapic_startcpu(c->id, (uint32_t)code);
		//lapic_startcpu(c->id, (uint32_t)bootother);

		// Wait for cpu to get through bootstrap.
		while(c->booted == 0)
			;
	}
}
#line 251 "../kern/cpu.c"

