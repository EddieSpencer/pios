#line 2 "../kern/mem.h"
/*
 * Physical memory management definitions.
 *
 * Copyright (C) 1997 Massachusetts Institute of Technology
 * See section "MIT License" in the file LICENSES for licensing terms.
 *
 * Derived from the MIT Exokernel and JOS.
 * Adapted for PIOS by Bryan Ford at Yale University.
 */


#ifndef PIOS_KERN_MEM_H
#define PIOS_KERN_MEM_H
#ifndef PIOS_KERNEL
# error "This is a kernel header; user programs should not #include it"
#endif


/* Macros common to C and asm code */

//SMAP value as needed by e820 bios call
#define SMAP 0x534D4150

//offsets for registers used as input to bios calls (refer to struct bios_regs)
//offsets are in bytes
#define BIOSREGS_SIZE 30 //size in bytes
#define BIOSREGS_LOC 0x1000
#define BIOSREGS_EAX 0
#define BIOSREGS_EBX 4
#define BIOSREGS_ECX 8
#define BIOSREGS_EDX 12
#define BIOSREGS_ESI 16
#define BIOSREGS_EDI 20
#define BIOSREGS_DS 24
#define BIOSREGS_ES 26
#define BIOSREGS_INT_NO 28
#define BIOSREGS_CF  29

//memory locations to store bios buffer (buffer filled by the bios is <= 24 bytes as per ACPI 3.x)
#define BIOS_BUFF_ES 0x0
#define BIOS_BUFF_DI 0x0DAC //3500

#ifdef __ASSEMBLER__ /* ASSEMBLER MACROS FOR BIOS CALLS */

//memory locations needed during bios call to save stuff 
#define REAL_STACK_HI 0xBB8 //3000

#define BIOSCALL_MEM_START 0xBE8 //this is where we start saving the gdt,idt,esp etc. during a bios call
				// the location is chosen arbitrarily.
//offsets into the MEM_START area for various fields (in bytes)
#define PROT_ESP    0 //3048
#define PAGING_BIT  4 //3052
#define IDT_MEM_LOC 8 //3056 (idt needs 6 bytes)
#define GDT_MEM_LOC 14 //3062


#else 
/*ASSEMBLER MACROS END*/


#include <inc/types.h>
#include <inc/assert.h>
#include <inc/mmu.h>
#include <inc/x86.h>


// At physical address MEM_IO (640K) there is a 384K hole for I/O.
// The hole ends at physical address MEM_EXT, where extended memory begins.
#define MEM_IO		0x0A0000
#define MEM_EXT		0x100000

//low memory vectors
#define lowmem_bootother_vec 0x1000
#define lowmem_bioscall_vec 0x1004
#define E820TYPE_MEMORY         1       // Usable memory
#define E820TYPE_RESERVED       2       // Reserved by the BIOS
#define E820TYPE_ACPI           3       // Usable after reading ACPI tables
#define E820TYPE_NVS            4       // Reserved for NVS sleep
#define E820TYPE_UNUSABLE       5       // Memory unusable due to errors


// Given a physical address,
// return a C pointer the kernel can use to access it.
// This macro does nothing in PIOS because physical memory
// is mapped into the kernel's virtual address space at address 0,
// but this is not the case for many other systems such as JOS or Linux,
// which must do some translation here (usually just adding an offset).
#define mem_ptr(physaddr)	((void*)(physaddr))

// The converse to the above: given a C pointer, return a physical address.
#define mem_phys(ptr)		((uint32_t)(ptr))



// A pageinfo struct holds metadata on how a particular physical page is used.
// On boot we allocate a big array of pageinfo structs, one per physical page.
// This could be a union instead of a struct,
// since only one member is used for a given page state (free, allocated) -
// but that might make debugging a bit more challenging.
typedef struct pageinfo {
	struct pageinfo	*free_next;	// Next page number on free list
	int32_t	refcount;		// Reference count on allocated pages
#line 110 "../kern/mem.h"
} pageinfo;


// The pmem module sets up the following globals during mem_init().
extern size_t mem_max;		// Maximum physical address
extern size_t mem_npage;	// Total number of physical memory pages
extern pageinfo *mem_pageinfo;	// Metadata array indexed by page number

// Convert between pageinfo pointers, page indexes, and physical page addresses
#define mem_phys2pi(phys)	(&mem_pageinfo[(phys)/PAGESIZE])
#define mem_pi2phys(pi)		(((pi)-mem_pageinfo) * PAGESIZE)
#define mem_ptr2pi(ptr)		(mem_phys2pi(mem_phys(ptr)))
#define mem_pi2ptr(pi)		(mem_ptr(mem_pi2phys(pi)))


// The linker defines these special symbols to mark the start and end of
// the program's entire linker-arranged memory region,
// including the program's code, data, and bss sections.
// Use these to avoid treating kernel code/data pages as free memory!
extern char start[], end[];


// Detect available physical memory and initialize the mem_pageinfo array.
void mem_init(void);

// Allocate a physical page and return a pointer to its pageinfo struct.
// Returns NULL if no more physical pages are available.
pageinfo *mem_alloc(void);

// Return a physical page to the free list.
void mem_free(pageinfo *pi);

#line 143 "../kern/mem.h"
extern uint8_t pmap_zero[PAGESIZE];	// for the asserts below
#line 150 "../kern/mem.h"


// Atomically increment the reference count on a page.
static gcc_inline void
mem_incref(pageinfo *pi)
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
#line 158 "../kern/mem.h"
	assert(pi != mem_ptr2pi(pmap_zero));	// Don't alloc/free zero page!
#line 160 "../kern/mem.h"
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));

	lockadd(&pi->refcount, 1);
}

// Atomically decrement the reference count on a page,
// freeing the page with the provided function if there are no more refs.
static gcc_inline void
mem_decref(pageinfo* pi, void (*freefun)(pageinfo *pi))
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
#line 172 "../kern/mem.h"
	assert(pi != mem_ptr2pi(pmap_zero));	// Don't alloc/free zero page!
#line 174 "../kern/mem.h"
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));

	if (lockaddz(&pi->refcount, -1))
#line 180 "../kern/mem.h"
			freefun(pi);
	assert(pi->refcount >= 0);
}

struct e820_mem_map {
	uint64_t base;
	uint64_t size;
	uint32_t type;
};

#define MEM_MAP_MAX 10

int detect_memory_e820(struct e820_mem_map m[MEM_MAP_MAX]); //returns number of memory map entries


//Register values as needed by BIOS calls.
struct bios_regs {
	uint32_t   eax;
	uint32_t   ebx;
	uint32_t   ecx;
	uint32_t   edx;
	uint32_t   esi;
	uint32_t   edi;
	uint16_t   ds; 
	uint16_t   es; 
	uint8_t    int_no;
	uint8_t    cf; //read-only memory to see carry flag.

}__attribute__((packed));


void bios_call(struct bios_regs *inp);


#endif /* ASSEMBLER MACROS FOR BIOS CALLS */

#endif /* !PIOS_KERN_MEM_H */
