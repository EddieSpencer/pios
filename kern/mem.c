/*
 * Physical memory management.
 *
 * Copyright (C) 1997 Massachusetts Institute of Technology
 * See section "MIT License" in the file LICENSES for licensing terms.
 *
 * Derived from the MIT Exokernel and JOS.
 * Adapted for PIOS by Bryan Ford at Yale University.
 */

#include <inc/x86.h>
#include <inc/mmu.h>
#include <inc/string.h>
#include <inc/assert.h>

#include <kern/cpu.h>
#include <kern/mem.h>
#include <kern/spinlock.h>
#include <kern/pmap.h>

size_t mem_max;			// Maximum physical address
size_t mem_npage;		// Total number of physical memory pages

pageinfo *mem_pageinfo;		// Metadata array indexed by page number

pageinfo *mem_freelist;		// Start of free page list
spinlock mem_freelock;		// Spinlock protecting the free page list


void mem_check(void);

void
mem_init(void)
{
	if (!cpu_onboot())	// only do once, on the boot CPU
		return;

	// make an int 0x15, e820 call
	// to determine physical memory.	
	// refer to link: http://www.uruk.org/orig-grub/mem64mb.html	

	struct e820_mem_map mem_array[MEM_MAP_MAX];	
	uint16_t mem_map_entries = detect_memory_e820(mem_array);
	uint16_t temp_ctr;
	uint64_t total_ram_size = 0;
	mem_max = 0;
	int i,j,k;

	for(i=0;i<mem_map_entries;i++)
	{
		//the memory should be usable!
		assert(mem_array[i].type == E820TYPE_MEMORY 
				|| mem_array[i].type == E820TYPE_ACPI); 
		
		total_ram_size += mem_array[i].size;

		mem_max = MAX(mem_max,mem_array[i].base+mem_array[i].size);

	}
	cprintf("Physical memory: %dK available\n",total_ram_size/(1024));

	//total no of pages
	mem_npage = (int)mem_max / PAGESIZE; //there are many pages in between
					     //that cannot be used.
					     //hence we initialize all the
	                                    //ref counts to 1 (in later code)
	// Now that we know the size of physical memory,
	// reserve enough space for the pageinfo array
	// just past our statically-assigned program code/data/bss,
	// which the linker placed at the start of extended memory.
	// Make sure the pageinfo entries are naturally aligned.
	mem_pageinfo = (pageinfo *) ROUNDUP((size_t) end, sizeof(pageinfo));

	// Initialize the entire pageinfo array to zero for good measure.
	memset(mem_pageinfo, 0, sizeof(pageinfo) * mem_npage);

	// Free extended memory starts just past the pageinfo array.
	void *freemem = &mem_pageinfo[mem_npage];

	// Align freemem to page boundary.
	freemem = ROUNDUP(freemem, PAGESIZE);

	// Chain all the available physical pages onto the free page list.
	spinlock_init(&mem_freelock);
	pageinfo **freetail = &mem_freelist;
	
	for(i=0;i<mem_npage;i++) {
		mem_pageinfo[i].refcount = 1;
	}

	for(i=0;i<mem_map_entries;i++) {
		
		//The memory layout is as under
		// -------------------------------------------------
		// | p0 | p1 | p2 | ... | basemem | kernel | freemem
		// -------------------------------------------------
		// | B  | B  | F  | F   |           B      | F
		// -------------------------------------------------
		// here B indicates "not-free" and F indicates "free"
		// we need to check if the memory map region lies in 
		// the "F" region if it does not, 
		// we try to clamp it so that it does.

		int region_start = mem_array[i].base;
		int region_end = region_start + mem_array[i].size;

		if(region_start < 2*PAGESIZE ) {
			region_start = 2*PAGESIZE;
		}
		else if (region_start < mem_phys(freemem) 
				&& region_end > mem_phys(start)) {
			region_start = mem_phys(freemem);
		}

		//need to start and end at page boundaries.
		region_start = ROUNDUP(region_start, PAGESIZE);
		region_end = ROUNDDOWN(region_end, PAGESIZE);

		for(j=region_start;j<region_end;j+=PAGESIZE) {

			//get the page index into the page info table
			int page_no;
			page_no = j/PAGESIZE;
			assert(page_no<mem_npage);
			//mark the page as unused
			mem_pageinfo[page_no].refcount = 0;
			// Add the page to the end of the free list.
			*freetail = &mem_pageinfo[page_no];
			freetail = &mem_pageinfo[page_no].free_next;
		}

	}

	*freetail = NULL;	// null-terminate the freelist


	// Check to make sure the page allocator seems to work correctly.
	mem_check();
}

int detect_memory_e820(struct e820_mem_map mem_array[MEM_MAP_MAX])
{
	struct bios_regs regs; 
	
	//variables for e820 memory map
	uint32_t *e820_base_low = (uint32_t*)(BIOS_BUFF_DI);
	uint32_t *e820_base_high = (uint32_t*)(BIOS_BUFF_DI+4);
	uint32_t *e820_size_low = (uint32_t*)(BIOS_BUFF_DI+8);
	uint32_t *e820_size_high = (uint32_t*)(BIOS_BUFF_DI+12);
	uint32_t *e820_type = (uint32_t*)(BIOS_BUFF_DI + 16);
	
	int e820_ctr = 0;

	regs.ebx = 0x00000000; //must be set to 0 for initial call
	regs.cf = 0x00; //initialize this to 0

	do
	{
		regs.int_no = 0x15; //interrupt number
		regs.eax = 0xe820; //BIOS function to call
		regs.edx = SMAP; //must be set to SMAP value.
		regs.ecx = 0x00000018; //ask the BIOS to fill 24 bytes 
		                //(24 is the buffer size as needed by ACPI 3.x).
		regs.es = BIOS_BUFF_ES; //segment number of the buffer
		                        //the BIOS fills
		regs.edi = BIOS_BUFF_DI;//offset of the buffer BIOS fills
		                        //(es and di determine buffer address).
		regs.ds = 0x0000; //ds is not needed
		regs.esi = 0x00000000; //esi is not needed

		bios_call(&regs);

		//read the e820 memory map

		//check if bios has trashed these registers
  	        //we use these macros to read memory map
		assert(regs.es == BIOS_BUFF_ES && regs.edi == BIOS_BUFF_DI);
		
		// check for usable memory
		if (*e820_type == E820TYPE_MEMORY 
				|| *e820_type == E820TYPE_ACPI) 
		{
			assert(e820_ctr < MEM_MAP_MAX); 

			mem_array[e820_ctr].base = ((uint64_t)(*e820_base_high)<<32) + (*e820_base_low);
			mem_array[e820_ctr].size = ((uint64_t)(*e820_size_high)<<32) + (*e820_size_low);
			mem_array[e820_ctr].type = (*e820_type);
			e820_ctr++;
		}

		
	}
	while(regs.ebx!=0 && regs.cf == 0 && regs.eax == SMAP);

	if(regs.eax!=SMAP) {
		warn("\nBIOS does not support e820 call!\n");
	}

	return e820_ctr;
}

void bios_call(struct bios_regs *inp)
{
	struct bios_regs *lowmem_bios_regs = 
		(struct bios_regs *)
			(lowmem_bootother_vec - sizeof(struct bios_regs));

	//just a check to see if the struct and macro are updated and in sync
	assert(BIOSREGS_SIZE == sizeof(struct bios_regs));

	//now copy register values to low memory
	*lowmem_bios_regs = *inp;
	
	asm volatile("call *0x1004": : :
			"eax","ebx","ecx","edx","esi","memory");

	//copy the values back into the regs structure.
	*inp = *lowmem_bios_regs;
	return;
}

//
// Allocates a physical page from the page free list.
// Does NOT set the contents of the physical page to zero -
// the caller must do that if necessary.
//
// RETURNS 
//   - a pointer to the page's pageinfo struct if successful
//   - NULL if no available physical pages.
//
// Hint: pi->refs should not be incremented 
// Hint: be sure to use proper mutual exclusion for multiprocessor operation.
pageinfo *
mem_alloc(void)
{
	// Fill this function in
	spinlock_acquire(&mem_freelock);

	pageinfo *pi = mem_freelist;
	if (pi != NULL) {
		mem_freelist = pi->free_next;	// Remove page from free list
		pi->free_next = NULL;		// Mark it not on the free list
	}

	spinlock_release(&mem_freelock);

	return pi;	// Return pageinfo pointer or NULL

}

//
// Return a page to the free list, given its pageinfo pointer.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
mem_free(pageinfo *pi)
{
	if (pi->refcount != 0)
		panic("mem_free: attempt to free in-use page");
	if (pi->free_next != NULL)
		panic("mem_free: attempt to free already free page!");

	spinlock_acquire(&mem_freelock);

	// Insert the page at the head of the free list.
	pi->free_next = mem_freelist;
	mem_freelist = pi;

	spinlock_release(&mem_freelock);
}

//
// Check the physical page allocator (mem_alloc(), mem_free())
// for correct operation after initialization via mem_init().
//
void
mem_check()
{
	pageinfo *pp, *pp0, *pp1, *pp2;
	pageinfo *fl;
	int i;

        // if there's a page that shouldn't be on
        // the free list, try to make sure it
        // eventually causes trouble.
	int freepages = 0;
	for (pp = mem_freelist; pp != 0; pp = pp->free_next) {
		memset(mem_pi2ptr(pp), 0x97, 128);
		freepages++;
	}
	cprintf("mem_check: %d free pages\n", freepages);
	assert(freepages < mem_npage);	// can't have more free than total!
	assert(freepages > 16000);	// make sure it's in the right ballpark

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	pp0 = mem_alloc(); assert(pp0 != 0);
	pp1 = mem_alloc(); assert(pp1 != 0);
	pp2 = mem_alloc(); assert(pp2 != 0);

	assert(pp0);
	assert(pp1 && pp1 != pp0);
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
        assert(mem_pi2phys(pp0) < mem_npage*PAGESIZE);
        assert(mem_pi2phys(pp1) < mem_npage*PAGESIZE);
        assert(mem_pi2phys(pp2) < mem_npage*PAGESIZE);

	// temporarily steal the rest of the free pages
	fl = mem_freelist;
	mem_freelist = 0;

	// should be no free memory
	assert(mem_alloc() == 0);

        // free and re-allocate?
        mem_free(pp0);
        mem_free(pp1);
        mem_free(pp2);
	pp0 = pp1 = pp2 = 0;
	pp0 = mem_alloc(); assert(pp0 != 0);
	pp1 = mem_alloc(); assert(pp1 != 0);
	pp2 = mem_alloc(); assert(pp2 != 0);
	assert(pp0);
	assert(pp1 && pp1 != pp0);
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
	assert(mem_alloc() == 0);

	// give free list back
	mem_freelist = fl;

	// free the pages we took
	mem_free(pp0);
	mem_free(pp1);
	mem_free(pp2);

	cprintf("mem_check() succeeded!\n");
}

