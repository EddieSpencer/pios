
obj/kern/kernel:     file format elf32-i386

Disassembly of section .text:

00100000 <_start-0xc>:
.long CHECKSUM

.globl		start,_start
start: _start:
	movw	$0x1234,0x472			# warm boot BIOS flag
  100000:	02 b0 ad 1b 03 00    	add    0x31bad(%eax),%dh
  100006:	00 00                	add    %al,(%eax)
  100008:	fb                   	sti    
  100009:	4f                   	dec    %edi
  10000a:	52                   	push   %edx
  10000b:	e4 66                	in     $0x66,%al

0010000c <_start>:
  10000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
  100013:	34 12 

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
  100015:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Leave a few words on the stack for the user trap frame
	movl	$(cpu_boot+4096-SIZEOF_STRUCT_TRAPFRAME),%esp
  10001a:	bc b4 ff 10 00       	mov    $0x10ffb4,%esp

	# now to C code
	call	init
  10001f:	e8 04 00 00 00       	call   100028 <init>

00100024 <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
  100024:	eb fe                	jmp    100024 <spin>
  100026:	90                   	nop    
  100027:	90                   	nop    

00100028 <init>:
// and later from boot/bootother.S on all other processors.
// As a rule, "init" functions in PIOS are called once on EACH processor.
void
init(void)
{
  100028:	55                   	push   %ebp
  100029:	89 e5                	mov    %esp,%ebp
  10002b:	53                   	push   %ebx
  10002c:	83 ec 64             	sub    $0x64,%esp
	extern char start[], edata[], end[];

	// Before anything else, complete the ELF loading process.
	// Clear all uninitialized global data (BSS) in our program,
	// ensuring that all static/global variables start out zero.
	if (cpu_onboot())
  10002f:	e8 25 04 00 00       	call   100459 <cpu_onboot>
  100034:	85 c0                	test   %eax,%eax
  100036:	74 28                	je     100060 <init+0x38>
		memset(edata, 0, end - edata);
  100038:	ba 08 50 18 00       	mov    $0x185008,%edx
  10003d:	b8 2c b7 17 00       	mov    $0x17b72c,%eax
  100042:	89 d1                	mov    %edx,%ecx
  100044:	29 c1                	sub    %eax,%ecx
  100046:	89 c8                	mov    %ecx,%eax
  100048:	89 44 24 08          	mov    %eax,0x8(%esp)
  10004c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  100053:	00 
  100054:	c7 04 24 2c b7 17 00 	movl   $0x17b72c,(%esp)
  10005b:	e8 91 bb 00 00       	call   10bbf1 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
  100060:	e8 d1 05 00 00       	call   100636 <cons_init>

	//copy the low memory bootothers code.
	extern uint8_t _binary_obj_boot_bootother_start[],
			_binary_obj_boot_bootother_size[];
	uint8_t *code = (uint8_t*)lowmem_bootother_vec;
  100065:	c7 45 b0 00 10 00 00 	movl   $0x1000,0xffffffb0(%ebp)
	memmove(code, _binary_obj_boot_bootother_start,
  10006c:	b8 c0 01 00 00       	mov    $0x1c0,%eax
  100071:	89 44 24 08          	mov    %eax,0x8(%esp)
  100075:	c7 44 24 04 6c b5 17 	movl   $0x17b56c,0x4(%esp)
  10007c:	00 
  10007d:	8b 45 b0             	mov    0xffffffb0(%ebp),%eax
  100080:	89 04 24             	mov    %eax,(%esp)
  100083:	e8 e2 bb 00 00       	call   10bc6a <memmove>
		(uint32_t)_binary_obj_boot_bootother_size);

	// Initialize and load the bootstrap CPU's GDT, TSS, and IDT.
	cpu_init();
  100088:	e8 67 19 00 00       	call   1019f4 <cpu_init>
	trap_init();
  10008d:	e8 b0 2f 00 00       	call   103042 <trap_init>

	// Physical memory detection/initialization.
	// Can't call mem_alloc until after we do this!
	mem_init();
  100092:	e8 d5 0c 00 00       	call   100d6c <mem_init>

	// Lab 2: check spinlock implementation
	if (cpu_onboot())
  100097:	e8 bd 03 00 00       	call   100459 <cpu_onboot>
  10009c:	85 c0                	test   %eax,%eax
  10009e:	74 05                	je     1000a5 <init+0x7d>
		spinlock_check();
  1000a0:	e8 ea 3f 00 00       	call   10408f <spinlock_check>

	// Initialize the paged virtual memory system.
	pmap_init();
  1000a5:	e8 4e 5e 00 00       	call   105ef8 <pmap_init>

	// Find and start other processors in a multiprocessor system
	mp_init();		// Find info about processors in system
  1000aa:	e8 e0 3b 00 00       	call   103c8f <mp_init>
	pic_init();		// setup the legacy PIC (mainly to disable it)
  1000af:	e8 60 a8 00 00       	call   10a914 <pic_init>
	ioapic_init();		// prepare to handle external device interrupts
  1000b4:	e8 83 ae 00 00       	call   10af3c <ioapic_init>
	lapic_init();		// setup this CPU's local APIC
  1000b9:	e8 d9 aa 00 00       	call   10ab97 <lapic_init>
	cpu_bootothers();	// Get other processors started
  1000be:	e8 5f 1b 00 00       	call   101c22 <cpu_bootothers>
//	cprintf("CPU %d (%s) has booted\n", cpu_cur()->id,
//		cpu_onboot() ? "BP" : "AP");

	// Initialize the I/O system.
	file_init();		// Create root directory and console I/O files
  1000c3:	e8 7c 9c 00 00       	call   109d44 <file_init>

	cons_intenable();	// Let the console start producing interrupts
  1000c8:	e8 35 06 00 00       	call   100702 <cons_intenable>

	// Initialize the process management code.
	proc_init();
  1000cd:	e8 5a 44 00 00       	call   10452c <proc_init>

	if (!cpu_onboot())
  1000d2:	e8 82 03 00 00       	call   100459 <cpu_onboot>
  1000d7:	85 c0                	test   %eax,%eax
  1000d9:	75 05                	jne    1000e0 <init+0xb8>
		proc_sched();	// just jump right into the scheduler
  1000db:	e8 15 49 00 00       	call   1049f5 <proc_sched>


	// Create our first actual user-mode process
	proc *root = proc_root = proc_alloc(NULL, 0);
  1000e0:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1000e7:	00 
  1000e8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  1000ef:	e8 da 44 00 00       	call   1045ce <proc_alloc>
  1000f4:	a3 b0 24 18 00       	mov    %eax,0x1824b0
  1000f9:	a1 b0 24 18 00       	mov    0x1824b0,%eax
  1000fe:	89 45 b4             	mov    %eax,0xffffffb4(%ebp)

	elfhdr *eh = (elfhdr *)ROOTEXE_START;
  100101:	c7 45 b8 58 63 15 00 	movl   $0x156358,0xffffffb8(%ebp)
	assert(eh->e_magic == ELF_MAGIC);
  100108:	8b 45 b8             	mov    0xffffffb8(%ebp),%eax
  10010b:	8b 00                	mov    (%eax),%eax
  10010d:	3d 7f 45 4c 46       	cmp    $0x464c457f,%eax
  100112:	74 24                	je     100138 <init+0x110>
  100114:	c7 44 24 0c c0 c0 10 	movl   $0x10c0c0,0xc(%esp)
  10011b:	00 
  10011c:	c7 44 24 08 d9 c0 10 	movl   $0x10c0d9,0x8(%esp)
  100123:	00 
  100124:	c7 44 24 04 6e 00 00 	movl   $0x6e,0x4(%esp)
  10012b:	00 
  10012c:	c7 04 24 ee c0 10 00 	movl   $0x10c0ee,(%esp)
  100133:	e8 00 08 00 00       	call   100938 <debug_panic>

	// Load each program segment
	proghdr *ph = (proghdr *) ((void *) eh + eh->e_phoff);
  100138:	8b 45 b8             	mov    0xffffffb8(%ebp),%eax
  10013b:	8b 40 1c             	mov    0x1c(%eax),%eax
  10013e:	03 45 b8             	add    0xffffffb8(%ebp),%eax
  100141:	89 45 bc             	mov    %eax,0xffffffbc(%ebp)
	proghdr *eph = ph + eh->e_phnum;
  100144:	8b 45 b8             	mov    0xffffffb8(%ebp),%eax
  100147:	0f b7 40 2c          	movzwl 0x2c(%eax),%eax
  10014b:	0f b7 c0             	movzwl %ax,%eax
  10014e:	c1 e0 05             	shl    $0x5,%eax
  100151:	03 45 bc             	add    0xffffffbc(%ebp),%eax
  100154:	89 45 c0             	mov    %eax,0xffffffc0(%ebp)
	for (; ph < eph; ph++) {
  100157:	e9 1c 02 00 00       	jmp    100378 <init+0x350>
		if (ph->p_type != ELF_PROG_LOAD)
  10015c:	8b 45 bc             	mov    0xffffffbc(%ebp),%eax
  10015f:	8b 00                	mov    (%eax),%eax
  100161:	83 f8 01             	cmp    $0x1,%eax
  100164:	0f 85 0a 02 00 00    	jne    100374 <init+0x34c>
			continue;
	
		void *fa = (void *) eh + ROUNDDOWN(ph->p_offset, PAGESIZE);
  10016a:	8b 45 bc             	mov    0xffffffbc(%ebp),%eax
  10016d:	8b 40 04             	mov    0x4(%eax),%eax
  100170:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)
  100173:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  100176:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  10017b:	03 45 b8             	add    0xffffffb8(%ebp),%eax
  10017e:	89 45 cc             	mov    %eax,0xffffffcc(%ebp)
		uint32_t va = ROUNDDOWN(ph->p_va, PAGESIZE);
  100181:	8b 45 bc             	mov    0xffffffbc(%ebp),%eax
  100184:	8b 40 08             	mov    0x8(%eax),%eax
  100187:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
  10018a:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  10018d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  100192:	89 45 d0             	mov    %eax,0xffffffd0(%ebp)
		uint32_t zva = ph->p_va + ph->p_filesz;
  100195:	8b 45 bc             	mov    0xffffffbc(%ebp),%eax
  100198:	8b 50 08             	mov    0x8(%eax),%edx
  10019b:	8b 45 bc             	mov    0xffffffbc(%ebp),%eax
  10019e:	8b 40 10             	mov    0x10(%eax),%eax
  1001a1:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1001a4:	89 45 d4             	mov    %eax,0xffffffd4(%ebp)
		uint32_t eva = ROUNDUP(ph->p_va + ph->p_memsz, PAGESIZE);
  1001a7:	c7 45 e8 00 10 00 00 	movl   $0x1000,0xffffffe8(%ebp)
  1001ae:	8b 45 bc             	mov    0xffffffbc(%ebp),%eax
  1001b1:	8b 50 08             	mov    0x8(%eax),%edx
  1001b4:	8b 45 bc             	mov    0xffffffbc(%ebp),%eax
  1001b7:	8b 40 14             	mov    0x14(%eax),%eax
  1001ba:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1001bd:	03 45 e8             	add    0xffffffe8(%ebp),%eax
  1001c0:	83 e8 01             	sub    $0x1,%eax
  1001c3:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  1001c6:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  1001c9:	ba 00 00 00 00       	mov    $0x0,%edx
  1001ce:	f7 75 e8             	divl   0xffffffe8(%ebp)
  1001d1:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  1001d4:	29 d0                	sub    %edx,%eax
  1001d6:	89 45 d8             	mov    %eax,0xffffffd8(%ebp)

		uint32_t perm = SYS_READ | PTE_P | PTE_U;
  1001d9:	c7 45 dc 05 02 00 00 	movl   $0x205,0xffffffdc(%ebp)
		if (ph->p_flags & ELF_PROG_FLAG_WRITE)
  1001e0:	8b 45 bc             	mov    0xffffffbc(%ebp),%eax
  1001e3:	8b 40 18             	mov    0x18(%eax),%eax
  1001e6:	83 e0 02             	and    $0x2,%eax
  1001e9:	85 c0                	test   %eax,%eax
  1001eb:	0f 84 77 01 00 00    	je     100368 <init+0x340>
			perm |= SYS_WRITE | PTE_W;
  1001f1:	81 4d dc 02 04 00 00 	orl    $0x402,0xffffffdc(%ebp)

		for(; va < eva; va += PAGESIZE, fa += PAGESIZE) {
  1001f8:	e9 6b 01 00 00       	jmp    100368 <init+0x340>
			pageinfo *pi = mem_alloc(); assert(pi != NULL);
  1001fd:	e8 63 12 00 00       	call   101465 <mem_alloc>
  100202:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
  100205:	83 7d f0 00          	cmpl   $0x0,0xfffffff0(%ebp)
  100209:	75 24                	jne    10022f <init+0x207>
  10020b:	c7 44 24 0c fa c0 10 	movl   $0x10c0fa,0xc(%esp)
  100212:	00 
  100213:	c7 44 24 08 d9 c0 10 	movl   $0x10c0d9,0x8(%esp)
  10021a:	00 
  10021b:	c7 44 24 04 81 00 00 	movl   $0x81,0x4(%esp)
  100222:	00 
  100223:	c7 04 24 ee c0 10 00 	movl   $0x10c0ee,(%esp)
  10022a:	e8 09 07 00 00       	call   100938 <debug_panic>
			if (va < ROUNDDOWN(zva, PAGESIZE)) // complete page
  10022f:	8b 45 d4             	mov    0xffffffd4(%ebp),%eax
  100232:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  100235:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  100238:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  10023d:	3b 45 d0             	cmp    0xffffffd0(%ebp),%eax
  100240:	76 2f                	jbe    100271 <init+0x249>
				memmove(mem_pi2ptr(pi), fa, PAGESIZE);
  100242:	8b 55 f0             	mov    0xfffffff0(%ebp),%edx
  100245:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  10024a:	89 d3                	mov    %edx,%ebx
  10024c:	29 c3                	sub    %eax,%ebx
  10024e:	89 d8                	mov    %ebx,%eax
  100250:	c1 e0 09             	shl    $0x9,%eax
  100253:	89 c2                	mov    %eax,%edx
  100255:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  10025c:	00 
  10025d:	8b 45 cc             	mov    0xffffffcc(%ebp),%eax
  100260:	89 44 24 04          	mov    %eax,0x4(%esp)
  100264:	89 14 24             	mov    %edx,(%esp)
  100267:	e8 fe b9 00 00       	call   10bc6a <memmove>
  10026c:	e9 96 00 00 00       	jmp    100307 <init+0x2df>
			else if (va < zva && ph->p_filesz) {	// partial
  100271:	8b 45 d0             	mov    0xffffffd0(%ebp),%eax
  100274:	3b 45 d4             	cmp    0xffffffd4(%ebp),%eax
  100277:	73 65                	jae    1002de <init+0x2b6>
  100279:	8b 45 bc             	mov    0xffffffbc(%ebp),%eax
  10027c:	8b 40 10             	mov    0x10(%eax),%eax
  10027f:	85 c0                	test   %eax,%eax
  100281:	74 5b                	je     1002de <init+0x2b6>
				memset(mem_pi2ptr(pi), 0, PAGESIZE);
  100283:	8b 55 f0             	mov    0xfffffff0(%ebp),%edx
  100286:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  10028b:	89 d1                	mov    %edx,%ecx
  10028d:	29 c1                	sub    %eax,%ecx
  10028f:	89 c8                	mov    %ecx,%eax
  100291:	c1 e0 09             	shl    $0x9,%eax
  100294:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  10029b:	00 
  10029c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1002a3:	00 
  1002a4:	89 04 24             	mov    %eax,(%esp)
  1002a7:	e8 45 b9 00 00       	call   10bbf1 <memset>
				memmove(mem_pi2ptr(pi), fa, zva-va);
  1002ac:	8b 55 d0             	mov    0xffffffd0(%ebp),%edx
  1002af:	8b 45 d4             	mov    0xffffffd4(%ebp),%eax
  1002b2:	89 c1                	mov    %eax,%ecx
  1002b4:	29 d1                	sub    %edx,%ecx
  1002b6:	8b 55 f0             	mov    0xfffffff0(%ebp),%edx
  1002b9:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  1002be:	89 d3                	mov    %edx,%ebx
  1002c0:	29 c3                	sub    %eax,%ebx
  1002c2:	89 d8                	mov    %ebx,%eax
  1002c4:	c1 e0 09             	shl    $0x9,%eax
  1002c7:	89 c2                	mov    %eax,%edx
  1002c9:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  1002cd:	8b 45 cc             	mov    0xffffffcc(%ebp),%eax
  1002d0:	89 44 24 04          	mov    %eax,0x4(%esp)
  1002d4:	89 14 24             	mov    %edx,(%esp)
  1002d7:	e8 8e b9 00 00       	call   10bc6a <memmove>
  1002dc:	eb 29                	jmp    100307 <init+0x2df>
			} else			// all-zero page
				memset(mem_pi2ptr(pi), 0, PAGESIZE);
  1002de:	8b 55 f0             	mov    0xfffffff0(%ebp),%edx
  1002e1:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  1002e6:	89 d1                	mov    %edx,%ecx
  1002e8:	29 c1                	sub    %eax,%ecx
  1002ea:	89 c8                	mov    %ecx,%eax
  1002ec:	c1 e0 09             	shl    $0x9,%eax
  1002ef:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  1002f6:	00 
  1002f7:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1002fe:	00 
  1002ff:	89 04 24             	mov    %eax,(%esp)
  100302:	e8 ea b8 00 00       	call   10bbf1 <memset>
			pte_t *pte = pmap_insert(root->pdir, pi, va, perm);
  100307:	8b 55 dc             	mov    0xffffffdc(%ebp),%edx
  10030a:	8b 45 b4             	mov    0xffffffb4(%ebp),%eax
  10030d:	8b 88 a0 06 00 00    	mov    0x6a0(%eax),%ecx
  100313:	89 54 24 0c          	mov    %edx,0xc(%esp)
  100317:	8b 45 d0             	mov    0xffffffd0(%ebp),%eax
  10031a:	89 44 24 08          	mov    %eax,0x8(%esp)
  10031e:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  100321:	89 44 24 04          	mov    %eax,0x4(%esp)
  100325:	89 0c 24             	mov    %ecx,(%esp)
  100328:	e8 22 67 00 00       	call   106a4f <pmap_insert>
  10032d:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
			assert(pte != NULL);
  100330:	83 7d f4 00          	cmpl   $0x0,0xfffffff4(%ebp)
  100334:	75 24                	jne    10035a <init+0x332>
  100336:	c7 44 24 0c 05 c1 10 	movl   $0x10c105,0xc(%esp)
  10033d:	00 
  10033e:	c7 44 24 08 d9 c0 10 	movl   $0x10c0d9,0x8(%esp)
  100345:	00 
  100346:	c7 44 24 04 8a 00 00 	movl   $0x8a,0x4(%esp)
  10034d:	00 
  10034e:	c7 04 24 ee c0 10 00 	movl   $0x10c0ee,(%esp)
  100355:	e8 de 05 00 00       	call   100938 <debug_panic>
  10035a:	81 45 d0 00 10 00 00 	addl   $0x1000,0xffffffd0(%ebp)
  100361:	81 45 cc 00 10 00 00 	addl   $0x1000,0xffffffcc(%ebp)
  100368:	8b 45 d0             	mov    0xffffffd0(%ebp),%eax
  10036b:	3b 45 d8             	cmp    0xffffffd8(%ebp),%eax
  10036e:	0f 82 89 fe ff ff    	jb     1001fd <init+0x1d5>
  100374:	83 45 bc 20          	addl   $0x20,0xffffffbc(%ebp)
  100378:	8b 45 bc             	mov    0xffffffbc(%ebp),%eax
  10037b:	3b 45 c0             	cmp    0xffffffc0(%ebp),%eax
  10037e:	0f 82 d8 fd ff ff    	jb     10015c <init+0x134>
		}
	}

	// Start the process at the entry indicated in the ELF header
	root->sv.tf.eip = eh->e_entry;
  100384:	8b 45 b8             	mov    0xffffffb8(%ebp),%eax
  100387:	8b 50 18             	mov    0x18(%eax),%edx
  10038a:	8b 45 b4             	mov    0xffffffb4(%ebp),%eax
  10038d:	89 90 88 04 00 00    	mov    %edx,0x488(%eax)
	root->sv.tf.eflags |= FL_IF;	// enable interrupts
  100393:	8b 45 b4             	mov    0xffffffb4(%ebp),%eax
  100396:	8b 80 90 04 00 00    	mov    0x490(%eax),%eax
  10039c:	89 c2                	mov    %eax,%edx
  10039e:	80 ce 02             	or     $0x2,%dh
  1003a1:	8b 45 b4             	mov    0xffffffb4(%ebp),%eax
  1003a4:	89 90 90 04 00 00    	mov    %edx,0x490(%eax)

	// Give the process a 1-page stack in high memory
	// (the process can then increase its own stack as desired)
	pageinfo *pi = mem_alloc(); assert(pi != NULL);
  1003aa:	e8 b6 10 00 00       	call   101465 <mem_alloc>
  1003af:	89 45 c4             	mov    %eax,0xffffffc4(%ebp)
  1003b2:	83 7d c4 00          	cmpl   $0x0,0xffffffc4(%ebp)
  1003b6:	75 24                	jne    1003dc <init+0x3b4>
  1003b8:	c7 44 24 0c fa c0 10 	movl   $0x10c0fa,0xc(%esp)
  1003bf:	00 
  1003c0:	c7 44 24 08 d9 c0 10 	movl   $0x10c0d9,0x8(%esp)
  1003c7:	00 
  1003c8:	c7 44 24 04 94 00 00 	movl   $0x94,0x4(%esp)
  1003cf:	00 
  1003d0:	c7 04 24 ee c0 10 00 	movl   $0x10c0ee,(%esp)
  1003d7:	e8 5c 05 00 00       	call   100938 <debug_panic>
	pte_t *pte = pmap_insert(root->pdir, pi, VM_STACKHI-PAGESIZE,
				SYS_READ | SYS_WRITE | PTE_P | PTE_U | PTE_W);
  1003dc:	8b 45 b4             	mov    0xffffffb4(%ebp),%eax
  1003df:	8b 90 a0 06 00 00    	mov    0x6a0(%eax),%edx
  1003e5:	c7 44 24 0c 07 06 00 	movl   $0x607,0xc(%esp)
  1003ec:	00 
  1003ed:	c7 44 24 08 00 f0 ff 	movl   $0xeffff000,0x8(%esp)
  1003f4:	ef 
  1003f5:	8b 45 c4             	mov    0xffffffc4(%ebp),%eax
  1003f8:	89 44 24 04          	mov    %eax,0x4(%esp)
  1003fc:	89 14 24             	mov    %edx,(%esp)
  1003ff:	e8 4b 66 00 00       	call   106a4f <pmap_insert>
  100404:	89 45 c8             	mov    %eax,0xffffffc8(%ebp)
	assert(pte != NULL);
  100407:	83 7d c8 00          	cmpl   $0x0,0xffffffc8(%ebp)
  10040b:	75 24                	jne    100431 <init+0x409>
  10040d:	c7 44 24 0c 05 c1 10 	movl   $0x10c105,0xc(%esp)
  100414:	00 
  100415:	c7 44 24 08 d9 c0 10 	movl   $0x10c0d9,0x8(%esp)
  10041c:	00 
  10041d:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
  100424:	00 
  100425:	c7 04 24 ee c0 10 00 	movl   $0x10c0ee,(%esp)
  10042c:	e8 07 05 00 00       	call   100938 <debug_panic>
	root->sv.tf.esp = VM_STACKHI;
  100431:	8b 45 b4             	mov    0xffffffb4(%ebp),%eax
  100434:	c7 80 94 04 00 00 00 	movl   $0xf0000000,0x494(%eax)
  10043b:	00 00 f0 

	// Give the root process an initial file system.
	file_initroot(root);
  10043e:	8b 45 b4             	mov    0xffffffb4(%ebp),%eax
  100441:	89 04 24             	mov    %eax,(%esp)
  100444:	e8 93 99 00 00       	call   109ddc <file_initroot>

	proc_ready(root);	// make the root process ready
  100449:	8b 45 b4             	mov    0xffffffb4(%ebp),%eax
  10044c:	89 04 24             	mov    %eax,(%esp)
  10044f:	e8 dd 43 00 00       	call   104831 <proc_ready>
	proc_sched();		// run it
  100454:	e8 9c 45 00 00       	call   1049f5 <proc_sched>

00100459 <cpu_onboot>:
}

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  100459:	55                   	push   %ebp
  10045a:	89 e5                	mov    %esp,%ebp
  10045c:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  10045f:	e8 0d 00 00 00       	call   100471 <cpu_cur>
  100464:	3d 00 f0 10 00       	cmp    $0x10f000,%eax
  100469:	0f 94 c0             	sete   %al
  10046c:	0f b6 c0             	movzbl %al,%eax
}
  10046f:	c9                   	leave  
  100470:	c3                   	ret    

00100471 <cpu_cur>:
  100471:	55                   	push   %ebp
  100472:	89 e5                	mov    %esp,%ebp
  100474:	83 ec 28             	sub    $0x28,%esp
static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  100477:	89 65 fc             	mov    %esp,0xfffffffc(%ebp)
        return esp;
  10047a:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  10047d:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  100480:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  100483:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  100488:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	assert(c->magic == CPU_MAGIC);
  10048b:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  10048e:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  100494:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  100499:	74 24                	je     1004bf <cpu_cur+0x4e>
  10049b:	c7 44 24 0c 11 c1 10 	movl   $0x10c111,0xc(%esp)
  1004a2:	00 
  1004a3:	c7 44 24 08 d9 c0 10 	movl   $0x10c0d9,0x8(%esp)
  1004aa:	00 
  1004ab:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  1004b2:	00 
  1004b3:	c7 04 24 27 c1 10 00 	movl   $0x10c127,(%esp)
  1004ba:	e8 79 04 00 00       	call   100938 <debug_panic>
	return c;
  1004bf:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
}
  1004c2:	c9                   	leave  
  1004c3:	c3                   	ret    

001004c4 <user>:
}

// This is the first function that gets run in user mode (ring 3).
// It acts as PIOS's "root process",
// of which all other processes are descendants.
void
user()
{
  1004c4:	55                   	push   %ebp
  1004c5:	89 e5                	mov    %esp,%ebp
  1004c7:	83 ec 28             	sub    $0x28,%esp
	cprintf("in user()\n");
  1004ca:	c7 04 24 34 c1 10 00 	movl   $0x10c134,(%esp)
  1004d1:	e8 97 b3 00 00       	call   10b86d <cprintf>
static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  1004d6:	89 65 f8             	mov    %esp,0xfffffff8(%ebp)
        return esp;
  1004d9:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1004dc:	89 c2                	mov    %eax,%edx
	assert(read_esp() > (uint32_t) &user_stack[0]);
  1004de:	b8 00 c0 17 00       	mov    $0x17c000,%eax
  1004e3:	39 c2                	cmp    %eax,%edx
  1004e5:	77 24                	ja     10050b <user+0x47>
  1004e7:	c7 44 24 0c 40 c1 10 	movl   $0x10c140,0xc(%esp)
  1004ee:	00 
  1004ef:	c7 44 24 08 d9 c0 10 	movl   $0x10c0d9,0x8(%esp)
  1004f6:	00 
  1004f7:	c7 44 24 04 a8 00 00 	movl   $0xa8,0x4(%esp)
  1004fe:	00 
  1004ff:	c7 04 24 ee c0 10 00 	movl   $0x10c0ee,(%esp)
  100506:	e8 2d 04 00 00       	call   100938 <debug_panic>
static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  10050b:	89 65 fc             	mov    %esp,0xfffffffc(%ebp)
        return esp;
  10050e:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  100511:	89 c2                	mov    %eax,%edx
	assert(read_esp() < (uint32_t) &user_stack[sizeof(user_stack)]);
  100513:	b8 00 d0 17 00       	mov    $0x17d000,%eax
  100518:	39 c2                	cmp    %eax,%edx
  10051a:	72 24                	jb     100540 <user+0x7c>
  10051c:	c7 44 24 0c 68 c1 10 	movl   $0x10c168,0xc(%esp)
  100523:	00 
  100524:	c7 44 24 08 d9 c0 10 	movl   $0x10c0d9,0x8(%esp)
  10052b:	00 
  10052c:	c7 44 24 04 a9 00 00 	movl   $0xa9,0x4(%esp)
  100533:	00 
  100534:	c7 04 24 ee c0 10 00 	movl   $0x10c0ee,(%esp)
  10053b:	e8 f8 03 00 00       	call   100938 <debug_panic>


	done();
  100540:	e8 00 00 00 00       	call   100545 <done>

00100545 <done>:
}

// This is a function that we call when the kernel is "done" -
// it just puts the processor into an infinite loop.
// We make this a function so that we can set a breakpoints on it.
// Our grade scripts use this breakpoint to know when to stop QEMU.
void gcc_noreturn
done()
{
  100545:	55                   	push   %ebp
  100546:	89 e5                	mov    %esp,%ebp
	while (1)
		;	// just spin
  100548:	eb fe                	jmp    100548 <done+0x3>
  10054a:	90                   	nop    
  10054b:	90                   	nop    

0010054c <cons_intr>:
// called by device interrupt routines to feed input characters
// into the circular console input buffer.
void
cons_intr(int (*proc)(void))
{
  10054c:	55                   	push   %ebp
  10054d:	89 e5                	mov    %esp,%ebp
  10054f:	83 ec 18             	sub    $0x18,%esp
	int c;

	spinlock_acquire(&cons_lock);
  100552:	c7 04 24 40 1d 18 00 	movl   $0x181d40,(%esp)
  100559:	e8 5c 39 00 00       	call   103eba <spinlock_acquire>
	while ((c = (*proc)()) != -1) {
  10055e:	eb 33                	jmp    100593 <cons_intr+0x47>
		if (c == 0)
  100560:	83 7d fc 00          	cmpl   $0x0,0xfffffffc(%ebp)
  100564:	74 2d                	je     100593 <cons_intr+0x47>
			continue;
		cons.buf[cons.wpos++] = c;
  100566:	8b 15 04 d2 17 00    	mov    0x17d204,%edx
  10056c:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  10056f:	88 82 00 d0 17 00    	mov    %al,0x17d000(%edx)
  100575:	8d 42 01             	lea    0x1(%edx),%eax
  100578:	a3 04 d2 17 00       	mov    %eax,0x17d204
		if (cons.wpos == CONSBUFSIZE)
  10057d:	a1 04 d2 17 00       	mov    0x17d204,%eax
  100582:	3d 00 02 00 00       	cmp    $0x200,%eax
  100587:	75 0a                	jne    100593 <cons_intr+0x47>
			cons.wpos = 0;
  100589:	c7 05 04 d2 17 00 00 	movl   $0x0,0x17d204
  100590:	00 00 00 
  100593:	8b 45 08             	mov    0x8(%ebp),%eax
  100596:	ff d0                	call   *%eax
  100598:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  10059b:	83 7d fc ff          	cmpl   $0xffffffff,0xfffffffc(%ebp)
  10059f:	75 bf                	jne    100560 <cons_intr+0x14>
	}
	spinlock_release(&cons_lock);
  1005a1:	c7 04 24 40 1d 18 00 	movl   $0x181d40,(%esp)
  1005a8:	e8 08 3a 00 00       	call   103fb5 <spinlock_release>

	// Wake the root process
	file_wakeroot();
  1005ad:	e8 57 9c 00 00       	call   10a209 <file_wakeroot>
}
  1005b2:	c9                   	leave  
  1005b3:	c3                   	ret    

001005b4 <cons_getc>:

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
  1005b4:	55                   	push   %ebp
  1005b5:	89 e5                	mov    %esp,%ebp
  1005b7:	83 ec 18             	sub    $0x18,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
  1005ba:	e8 e5 a1 00 00       	call   10a7a4 <serial_intr>
	kbd_intr();
  1005bf:	e8 18 a1 00 00       	call   10a6dc <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
  1005c4:	8b 15 00 d2 17 00    	mov    0x17d200,%edx
  1005ca:	a1 04 d2 17 00       	mov    0x17d204,%eax
  1005cf:	39 c2                	cmp    %eax,%edx
  1005d1:	74 39                	je     10060c <cons_getc+0x58>
		c = cons.buf[cons.rpos++];
  1005d3:	8b 15 00 d2 17 00    	mov    0x17d200,%edx
  1005d9:	0f b6 82 00 d0 17 00 	movzbl 0x17d000(%edx),%eax
  1005e0:	0f b6 c0             	movzbl %al,%eax
  1005e3:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  1005e6:	8d 42 01             	lea    0x1(%edx),%eax
  1005e9:	a3 00 d2 17 00       	mov    %eax,0x17d200
		if (cons.rpos == CONSBUFSIZE)
  1005ee:	a1 00 d2 17 00       	mov    0x17d200,%eax
  1005f3:	3d 00 02 00 00       	cmp    $0x200,%eax
  1005f8:	75 0a                	jne    100604 <cons_getc+0x50>
			cons.rpos = 0;
  1005fa:	c7 05 00 d2 17 00 00 	movl   $0x0,0x17d200
  100601:	00 00 00 
		return c;
  100604:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  100607:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  10060a:	eb 07                	jmp    100613 <cons_getc+0x5f>
	}
	return 0;
  10060c:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  100613:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
}
  100616:	c9                   	leave  
  100617:	c3                   	ret    

00100618 <cons_putc>:

// output a character to the console
static void
cons_putc(int c)
{
  100618:	55                   	push   %ebp
  100619:	89 e5                	mov    %esp,%ebp
  10061b:	83 ec 08             	sub    $0x8,%esp
	serial_putc(c);
  10061e:	8b 45 08             	mov    0x8(%ebp),%eax
  100621:	89 04 24             	mov    %eax,(%esp)
  100624:	e8 98 a1 00 00       	call   10a7c1 <serial_putc>
	video_putc(c);
  100629:	8b 45 08             	mov    0x8(%ebp),%eax
  10062c:	89 04 24             	mov    %eax,(%esp)
  10062f:	e8 e4 9c 00 00       	call   10a318 <video_putc>
}
  100634:	c9                   	leave  
  100635:	c3                   	ret    

00100636 <cons_init>:

// initialize the console devices
void
cons_init(void)
{
  100636:	55                   	push   %ebp
  100637:	89 e5                	mov    %esp,%ebp
  100639:	83 ec 18             	sub    $0x18,%esp
	if (!cpu_onboot())	// only do once, on the boot CPU
  10063c:	e8 56 00 00 00       	call   100697 <cpu_onboot>
  100641:	85 c0                	test   %eax,%eax
  100643:	74 50                	je     100695 <cons_init+0x5f>
		return;

	spinlock_init(&cons_lock);
  100645:	c7 44 24 08 6e 00 00 	movl   $0x6e,0x8(%esp)
  10064c:	00 
  10064d:	c7 44 24 04 a0 c1 10 	movl   $0x10c1a0,0x4(%esp)
  100654:	00 
  100655:	c7 04 24 40 1d 18 00 	movl   $0x181d40,(%esp)
  10065c:	e8 2f 38 00 00       	call   103e90 <spinlock_init_>
	video_init();
  100661:	e8 ea 9b 00 00       	call   10a250 <video_init>
	kbd_init();
  100666:	e8 85 a0 00 00       	call   10a6f0 <kbd_init>
	serial_init();
  10066b:	e8 b1 a1 00 00       	call   10a821 <serial_init>

	if (!serial_exists)
  100670:	a1 00 50 18 00       	mov    0x185000,%eax
  100675:	85 c0                	test   %eax,%eax
  100677:	75 1c                	jne    100695 <cons_init+0x5f>
		warn("Serial port does not exist!\n");
  100679:	c7 44 24 08 ac c1 10 	movl   $0x10c1ac,0x8(%esp)
  100680:	00 
  100681:	c7 44 24 04 74 00 00 	movl   $0x74,0x4(%esp)
  100688:	00 
  100689:	c7 04 24 a0 c1 10 00 	movl   $0x10c1a0,(%esp)
  100690:	e8 61 03 00 00       	call   1009f6 <debug_warn>
}
  100695:	c9                   	leave  
  100696:	c3                   	ret    

00100697 <cpu_onboot>:
}

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  100697:	55                   	push   %ebp
  100698:	89 e5                	mov    %esp,%ebp
  10069a:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  10069d:	e8 0d 00 00 00       	call   1006af <cpu_cur>
  1006a2:	3d 00 f0 10 00       	cmp    $0x10f000,%eax
  1006a7:	0f 94 c0             	sete   %al
  1006aa:	0f b6 c0             	movzbl %al,%eax
}
  1006ad:	c9                   	leave  
  1006ae:	c3                   	ret    

001006af <cpu_cur>:
  1006af:	55                   	push   %ebp
  1006b0:	89 e5                	mov    %esp,%ebp
  1006b2:	83 ec 28             	sub    $0x28,%esp
static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  1006b5:	89 65 fc             	mov    %esp,0xfffffffc(%ebp)
        return esp;
  1006b8:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  1006bb:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  1006be:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1006c1:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1006c6:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	assert(c->magic == CPU_MAGIC);
  1006c9:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  1006cc:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  1006d2:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  1006d7:	74 24                	je     1006fd <cpu_cur+0x4e>
  1006d9:	c7 44 24 0c c9 c1 10 	movl   $0x10c1c9,0xc(%esp)
  1006e0:	00 
  1006e1:	c7 44 24 08 df c1 10 	movl   $0x10c1df,0x8(%esp)
  1006e8:	00 
  1006e9:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  1006f0:	00 
  1006f1:	c7 04 24 f4 c1 10 00 	movl   $0x10c1f4,(%esp)
  1006f8:	e8 3b 02 00 00       	call   100938 <debug_panic>
	return c;
  1006fd:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
}
  100700:	c9                   	leave  
  100701:	c3                   	ret    

00100702 <cons_intenable>:

// Enable console interrupts.
void
cons_intenable(void)
{
  100702:	55                   	push   %ebp
  100703:	89 e5                	mov    %esp,%ebp
  100705:	83 ec 08             	sub    $0x8,%esp
	if (!cpu_onboot())	// only do once, on the boot CPU
  100708:	e8 8a ff ff ff       	call   100697 <cpu_onboot>
  10070d:	85 c0                	test   %eax,%eax
  10070f:	74 0a                	je     10071b <cons_intenable+0x19>
		return;

	kbd_intenable();
  100711:	e8 df 9f 00 00       	call   10a6f5 <kbd_intenable>
	serial_intenable();
  100716:	e8 ce a1 00 00       	call   10a8e9 <serial_intenable>
}
  10071b:	c9                   	leave  
  10071c:	c3                   	ret    

0010071d <cputs>:

// `High'-level console I/O.  Used by readline and cprintf.
void
cputs(const char *str)
{
  10071d:	55                   	push   %ebp
  10071e:	89 e5                	mov    %esp,%ebp
  100720:	53                   	push   %ebx
  100721:	83 ec 14             	sub    $0x14,%esp
static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  100724:	8c 4d f6             	movw   %cs,0xfffffff6(%ebp)
        return cs;
  100727:	0f b7 45 f6          	movzwl 0xfffffff6(%ebp),%eax
	if (read_cs() & 3)
  10072b:	0f b7 c0             	movzwl %ax,%eax
  10072e:	83 e0 03             	and    $0x3,%eax
  100731:	85 c0                	test   %eax,%eax
  100733:	74 12                	je     100747 <cputs+0x2a>
  100735:	8b 45 08             	mov    0x8(%ebp),%eax
  100738:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %0" :
  10073b:	b8 00 00 00 00       	mov    $0x0,%eax
  100740:	8b 5d f8             	mov    0xfffffff8(%ebp),%ebx
  100743:	cd 30                	int    $0x30
		return sys_cputs(str);	// use syscall from user mode
  100745:	eb 54                	jmp    10079b <cputs+0x7e>

	// Hold the console spinlock while printing the entire string,
	// so that the output of different cputs calls won't get mixed.
	// Implement ad hoc recursive locking for debugging convenience.
	bool already = spinlock_holding(&cons_lock);
  100747:	c7 04 24 40 1d 18 00 	movl   $0x181d40,(%esp)
  10074e:	e8 bc 38 00 00       	call   10400f <spinlock_holding>
  100753:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
	if (!already)
  100756:	83 7d f0 00          	cmpl   $0x0,0xfffffff0(%ebp)
  10075a:	75 23                	jne    10077f <cputs+0x62>
		spinlock_acquire(&cons_lock);
  10075c:	c7 04 24 40 1d 18 00 	movl   $0x181d40,(%esp)
  100763:	e8 52 37 00 00       	call   103eba <spinlock_acquire>

	char ch;
	while (*str)
  100768:	eb 15                	jmp    10077f <cputs+0x62>
		cons_putc(*str++);
  10076a:	8b 45 08             	mov    0x8(%ebp),%eax
  10076d:	0f b6 00             	movzbl (%eax),%eax
  100770:	0f be c0             	movsbl %al,%eax
  100773:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  100777:	89 04 24             	mov    %eax,(%esp)
  10077a:	e8 99 fe ff ff       	call   100618 <cons_putc>
  10077f:	8b 45 08             	mov    0x8(%ebp),%eax
  100782:	0f b6 00             	movzbl (%eax),%eax
  100785:	84 c0                	test   %al,%al
  100787:	75 e1                	jne    10076a <cputs+0x4d>

	if (!already)
  100789:	83 7d f0 00          	cmpl   $0x0,0xfffffff0(%ebp)
  10078d:	75 0c                	jne    10079b <cputs+0x7e>
		spinlock_release(&cons_lock);
  10078f:	c7 04 24 40 1d 18 00 	movl   $0x181d40,(%esp)
  100796:	e8 1a 38 00 00       	call   103fb5 <spinlock_release>
}
  10079b:	83 c4 14             	add    $0x14,%esp
  10079e:	5b                   	pop    %ebx
  10079f:	5d                   	pop    %ebp
  1007a0:	c3                   	ret    

001007a1 <cons_io>:

// Synchronize the root process's console special files
// with the actual console I/O device.
bool
cons_io(void)
{
  1007a1:	55                   	push   %ebp
  1007a2:	89 e5                	mov    %esp,%ebp
  1007a4:	83 ec 38             	sub    $0x38,%esp
	spinlock_acquire(&cons_lock);
  1007a7:	c7 04 24 40 1d 18 00 	movl   $0x181d40,(%esp)
  1007ae:	e8 07 37 00 00       	call   103eba <spinlock_acquire>
	bool didio = 0;
  1007b3:	c7 45 e8 00 00 00 00 	movl   $0x0,0xffffffe8(%ebp)

	// Console output from the root process's console output file
	fileinode *outfi = &files->fi[FILEINO_CONSOUT];
  1007ba:	a1 d4 de 10 00       	mov    0x10ded4,%eax
  1007bf:	05 10 10 00 00       	add    $0x1010,%eax
  1007c4:	05 b8 00 00 00       	add    $0xb8,%eax
  1007c9:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
	const char *outbuf = FILEDATA(FILEINO_CONSOUT);
  1007cc:	c7 45 f0 00 00 80 80 	movl   $0x80800000,0xfffffff0(%ebp)
	assert(cons_outsize <= outfi->size);
  1007d3:	a1 08 d2 17 00       	mov    0x17d208,%eax
  1007d8:	89 c2                	mov    %eax,%edx
  1007da:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  1007dd:	8b 40 4c             	mov    0x4c(%eax),%eax
  1007e0:	39 c2                	cmp    %eax,%edx
  1007e2:	76 4c                	jbe    100830 <cons_io+0x8f>
  1007e4:	c7 44 24 0c 01 c2 10 	movl   $0x10c201,0xc(%esp)
  1007eb:	00 
  1007ec:	c7 44 24 08 df c1 10 	movl   $0x10c1df,0x8(%esp)
  1007f3:	00 
  1007f4:	c7 44 24 04 a3 00 00 	movl   $0xa3,0x4(%esp)
  1007fb:	00 
  1007fc:	c7 04 24 a0 c1 10 00 	movl   $0x10c1a0,(%esp)
  100803:	e8 30 01 00 00       	call   100938 <debug_panic>
	while (cons_outsize < outfi->size) {
		cons_putc(outbuf[cons_outsize++]);
  100808:	8b 0d 08 d2 17 00    	mov    0x17d208,%ecx
  10080e:	89 c8                	mov    %ecx,%eax
  100810:	03 45 f0             	add    0xfffffff0(%ebp),%eax
  100813:	0f b6 00             	movzbl (%eax),%eax
  100816:	0f be d0             	movsbl %al,%edx
  100819:	8d 41 01             	lea    0x1(%ecx),%eax
  10081c:	a3 08 d2 17 00       	mov    %eax,0x17d208
  100821:	89 14 24             	mov    %edx,(%esp)
  100824:	e8 ef fd ff ff       	call   100618 <cons_putc>
		didio = 1;
  100829:	c7 45 e8 01 00 00 00 	movl   $0x1,0xffffffe8(%ebp)
  100830:	a1 08 d2 17 00       	mov    0x17d208,%eax
  100835:	89 c2                	mov    %eax,%edx
  100837:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  10083a:	8b 40 4c             	mov    0x4c(%eax),%eax
  10083d:	39 c2                	cmp    %eax,%edx
  10083f:	72 c7                	jb     100808 <cons_io+0x67>
	}

	// Console input to the root process's console input file
	fileinode *infi = &files->fi[FILEINO_CONSIN];
  100841:	a1 d4 de 10 00       	mov    0x10ded4,%eax
  100846:	05 10 10 00 00       	add    $0x1010,%eax
  10084b:	83 c0 5c             	add    $0x5c,%eax
  10084e:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	char *inbuf = FILEDATA(FILEINO_CONSIN);
  100851:	c7 45 f8 00 00 40 80 	movl   $0x80400000,0xfffffff8(%ebp)
	int amount = cons.wpos - cons.rpos;
  100858:	8b 15 04 d2 17 00    	mov    0x17d204,%edx
  10085e:	a1 00 d2 17 00       	mov    0x17d200,%eax
  100863:	89 d1                	mov    %edx,%ecx
  100865:	29 c1                	sub    %eax,%ecx
  100867:	89 c8                	mov    %ecx,%eax
  100869:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	if (infi->size + amount > FILE_MAXSIZE)
  10086c:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  10086f:	8b 50 4c             	mov    0x4c(%eax),%edx
  100872:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  100875:	8d 04 02             	lea    (%edx,%eax,1),%eax
  100878:	3d 00 00 40 00       	cmp    $0x400000,%eax
  10087d:	76 1c                	jbe    10089b <cons_io+0xfa>
		panic("cons_io: root process's console input file full!");
  10087f:	c7 44 24 08 20 c2 10 	movl   $0x10c220,0x8(%esp)
  100886:	00 
  100887:	c7 44 24 04 ae 00 00 	movl   $0xae,0x4(%esp)
  10088e:	00 
  10088f:	c7 04 24 a0 c1 10 00 	movl   $0x10c1a0,(%esp)
  100896:	e8 9d 00 00 00       	call   100938 <debug_panic>
	assert(amount >= 0 && amount <= CONSBUFSIZE);
  10089b:	83 7d fc 00          	cmpl   $0x0,0xfffffffc(%ebp)
  10089f:	78 09                	js     1008aa <cons_io+0x109>
  1008a1:	81 7d fc 00 02 00 00 	cmpl   $0x200,0xfffffffc(%ebp)
  1008a8:	7e 24                	jle    1008ce <cons_io+0x12d>
  1008aa:	c7 44 24 0c 54 c2 10 	movl   $0x10c254,0xc(%esp)
  1008b1:	00 
  1008b2:	c7 44 24 08 df c1 10 	movl   $0x10c1df,0x8(%esp)
  1008b9:	00 
  1008ba:	c7 44 24 04 af 00 00 	movl   $0xaf,0x4(%esp)
  1008c1:	00 
  1008c2:	c7 04 24 a0 c1 10 00 	movl   $0x10c1a0,(%esp)
  1008c9:	e8 6a 00 00 00       	call   100938 <debug_panic>
	if (amount > 0) {
  1008ce:	83 7d fc 00          	cmpl   $0x0,0xfffffffc(%ebp)
  1008d2:	7e 53                	jle    100927 <cons_io+0x186>
		memmove(&inbuf[infi->size], &cons.buf[cons.rpos], amount);
  1008d4:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  1008d7:	a1 00 d2 17 00       	mov    0x17d200,%eax
  1008dc:	8d 88 00 d0 17 00    	lea    0x17d000(%eax),%ecx
  1008e2:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  1008e5:	8b 40 4c             	mov    0x4c(%eax),%eax
  1008e8:	03 45 f8             	add    0xfffffff8(%ebp),%eax
  1008eb:	89 54 24 08          	mov    %edx,0x8(%esp)
  1008ef:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  1008f3:	89 04 24             	mov    %eax,(%esp)
  1008f6:	e8 6f b3 00 00       	call   10bc6a <memmove>
		infi->size += amount;
  1008fb:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  1008fe:	8b 50 4c             	mov    0x4c(%eax),%edx
  100901:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  100904:	01 c2                	add    %eax,%edx
  100906:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  100909:	89 50 4c             	mov    %edx,0x4c(%eax)
		cons.rpos = cons.wpos = 0;
  10090c:	c7 05 04 d2 17 00 00 	movl   $0x0,0x17d204
  100913:	00 00 00 
  100916:	a1 04 d2 17 00       	mov    0x17d204,%eax
  10091b:	a3 00 d2 17 00       	mov    %eax,0x17d200
		didio = 1;
  100920:	c7 45 e8 01 00 00 00 	movl   $0x1,0xffffffe8(%ebp)
	}

	spinlock_release(&cons_lock);
  100927:	c7 04 24 40 1d 18 00 	movl   $0x181d40,(%esp)
  10092e:	e8 82 36 00 00       	call   103fb5 <spinlock_release>
	return didio;
  100933:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
}
  100936:	c9                   	leave  
  100937:	c3                   	ret    

00100938 <debug_panic>:
// Panic is called on unresolvable fatal errors.
// It prints "panic: mesg", and then enters the kernel monitor.
void
debug_panic(const char *file, int line, const char *fmt,...)
{
  100938:	55                   	push   %ebp
  100939:	89 e5                	mov    %esp,%ebp
  10093b:	83 ec 58             	sub    $0x58,%esp
static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  10093e:	8c 4d fa             	movw   %cs,0xfffffffa(%ebp)
        return cs;
  100941:	0f b7 45 fa          	movzwl 0xfffffffa(%ebp),%eax
	va_list ap;
	int i;

	// Avoid infinite recursion if we're panicking from kernel mode.
	if ((read_cs() & 3) == 0) {
  100945:	0f b7 c0             	movzwl %ax,%eax
  100948:	83 e0 03             	and    $0x3,%eax
  10094b:	85 c0                	test   %eax,%eax
  10094d:	75 15                	jne    100964 <debug_panic+0x2c>
		if (panicstr)
  10094f:	a1 0c d2 17 00       	mov    0x17d20c,%eax
  100954:	85 c0                	test   %eax,%eax
  100956:	0f 85 95 00 00 00    	jne    1009f1 <debug_panic+0xb9>
			goto dead;
		panicstr = fmt;
  10095c:	8b 45 10             	mov    0x10(%ebp),%eax
  10095f:	a3 0c d2 17 00       	mov    %eax,0x17d20c
	}

	// First print the requested message
	va_start(ap, fmt);
  100964:	8d 45 10             	lea    0x10(%ebp),%eax
  100967:	83 c0 04             	add    $0x4,%eax
  10096a:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
	cprintf("kernel panic at %s:%d: ", file, line);
  10096d:	8b 45 0c             	mov    0xc(%ebp),%eax
  100970:	89 44 24 08          	mov    %eax,0x8(%esp)
  100974:	8b 45 08             	mov    0x8(%ebp),%eax
  100977:	89 44 24 04          	mov    %eax,0x4(%esp)
  10097b:	c7 04 24 79 c2 10 00 	movl   $0x10c279,(%esp)
  100982:	e8 e6 ae 00 00       	call   10b86d <cprintf>
	vcprintf(fmt, ap);
  100987:	8b 55 10             	mov    0x10(%ebp),%edx
  10098a:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  10098d:	89 44 24 04          	mov    %eax,0x4(%esp)
  100991:	89 14 24             	mov    %edx,(%esp)
  100994:	e8 6b ae 00 00       	call   10b804 <vcprintf>
	cprintf("\n");
  100999:	c7 04 24 91 c2 10 00 	movl   $0x10c291,(%esp)
  1009a0:	e8 c8 ae 00 00       	call   10b86d <cprintf>
static gcc_inline uint32_t
read_ebp(void)
{
        uint32_t ebp;
        __asm __volatile("movl %%ebp,%0" : "=rm" (ebp));
  1009a5:	89 6d fc             	mov    %ebp,0xfffffffc(%ebp)
        return ebp;
  1009a8:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  1009ab:	89 c2                	mov    %eax,%edx
	va_end(ap);

	// Then print a backtrace of the kernel call chain
	uint32_t eips[DEBUG_TRACEFRAMES];
	debug_trace(read_ebp(), eips);
  1009ad:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
  1009b0:	89 44 24 04          	mov    %eax,0x4(%esp)
  1009b4:	89 14 24             	mov    %edx,(%esp)
  1009b7:	e8 83 00 00 00       	call   100a3f <debug_trace>
	for (i = 0; i < DEBUG_TRACEFRAMES && eips[i] != 0; i++)
  1009bc:	c7 45 f4 00 00 00 00 	movl   $0x0,0xfffffff4(%ebp)
  1009c3:	eb 1b                	jmp    1009e0 <debug_panic+0xa8>
		cprintf("  from %08x\n", eips[i]);
  1009c5:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  1009c8:	8b 44 85 c8          	mov    0xffffffc8(%ebp,%eax,4),%eax
  1009cc:	89 44 24 04          	mov    %eax,0x4(%esp)
  1009d0:	c7 04 24 93 c2 10 00 	movl   $0x10c293,(%esp)
  1009d7:	e8 91 ae 00 00       	call   10b86d <cprintf>
  1009dc:	83 45 f4 01          	addl   $0x1,0xfffffff4(%ebp)
  1009e0:	83 7d f4 09          	cmpl   $0x9,0xfffffff4(%ebp)
  1009e4:	7f 0b                	jg     1009f1 <debug_panic+0xb9>
  1009e6:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  1009e9:	8b 44 85 c8          	mov    0xffffffc8(%ebp,%eax,4),%eax
  1009ed:	85 c0                	test   %eax,%eax
  1009ef:	75 d4                	jne    1009c5 <debug_panic+0x8d>

dead:
	done();		// enter infinite loop (see kern/init.c)
  1009f1:	e8 4f fb ff ff       	call   100545 <done>

001009f6 <debug_warn>:
}

/* like panic, but don't */
void
debug_warn(const char *file, int line, const char *fmt,...)
{
  1009f6:	55                   	push   %ebp
  1009f7:	89 e5                	mov    %esp,%ebp
  1009f9:	83 ec 28             	sub    $0x28,%esp
	va_list ap;

	va_start(ap, fmt);
  1009fc:	8d 45 10             	lea    0x10(%ebp),%eax
  1009ff:	83 c0 04             	add    $0x4,%eax
  100a02:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	cprintf("kernel warning at %s:%d: ", file, line);
  100a05:	8b 45 0c             	mov    0xc(%ebp),%eax
  100a08:	89 44 24 08          	mov    %eax,0x8(%esp)
  100a0c:	8b 45 08             	mov    0x8(%ebp),%eax
  100a0f:	89 44 24 04          	mov    %eax,0x4(%esp)
  100a13:	c7 04 24 a0 c2 10 00 	movl   $0x10c2a0,(%esp)
  100a1a:	e8 4e ae 00 00       	call   10b86d <cprintf>
	vcprintf(fmt, ap);
  100a1f:	8b 55 10             	mov    0x10(%ebp),%edx
  100a22:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  100a25:	89 44 24 04          	mov    %eax,0x4(%esp)
  100a29:	89 14 24             	mov    %edx,(%esp)
  100a2c:	e8 d3 ad 00 00       	call   10b804 <vcprintf>
	cprintf("\n");
  100a31:	c7 04 24 91 c2 10 00 	movl   $0x10c291,(%esp)
  100a38:	e8 30 ae 00 00       	call   10b86d <cprintf>
	va_end(ap);
}
  100a3d:	c9                   	leave  
  100a3e:	c3                   	ret    

00100a3f <debug_trace>:

// Record the current call stack in eips[] by following the %ebp chain.
void gcc_noinline
debug_trace(uint32_t ebp, uint32_t eips[DEBUG_TRACEFRAMES])
{
  100a3f:	55                   	push   %ebp
  100a40:	89 e5                	mov    %esp,%ebp
  100a42:	83 ec 10             	sub    $0x10,%esp
	const uint32_t *frame = (const uint32_t*)ebp;
  100a45:	8b 45 08             	mov    0x8(%ebp),%eax
  100a48:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
	int i;

	for (i = 0; i < 10 && frame; i++) {
  100a4b:	c7 45 fc 00 00 00 00 	movl   $0x0,0xfffffffc(%ebp)
  100a52:	eb 21                	jmp    100a75 <debug_trace+0x36>
		eips[i] = frame[1];		// saved %eip
  100a54:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  100a57:	c1 e0 02             	shl    $0x2,%eax
  100a5a:	89 c2                	mov    %eax,%edx
  100a5c:	03 55 0c             	add    0xc(%ebp),%edx
  100a5f:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  100a62:	83 c0 04             	add    $0x4,%eax
  100a65:	8b 00                	mov    (%eax),%eax
  100a67:	89 02                	mov    %eax,(%edx)
		frame = (uint32_t*)frame[0];	// saved ebp
  100a69:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  100a6c:	8b 00                	mov    (%eax),%eax
  100a6e:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  100a71:	83 45 fc 01          	addl   $0x1,0xfffffffc(%ebp)
  100a75:	83 7d fc 09          	cmpl   $0x9,0xfffffffc(%ebp)
  100a79:	7f 1b                	jg     100a96 <debug_trace+0x57>
  100a7b:	83 7d f8 00          	cmpl   $0x0,0xfffffff8(%ebp)
  100a7f:	75 d3                	jne    100a54 <debug_trace+0x15>
	}
	for (; i < 10; i++)	// zero out rest of eips
  100a81:	eb 13                	jmp    100a96 <debug_trace+0x57>
		eips[i] = 0;
  100a83:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  100a86:	c1 e0 02             	shl    $0x2,%eax
  100a89:	03 45 0c             	add    0xc(%ebp),%eax
  100a8c:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  100a92:	83 45 fc 01          	addl   $0x1,0xfffffffc(%ebp)
  100a96:	83 7d fc 09          	cmpl   $0x9,0xfffffffc(%ebp)
  100a9a:	7e e7                	jle    100a83 <debug_trace+0x44>
}
  100a9c:	c9                   	leave  
  100a9d:	c3                   	ret    

00100a9e <f3>:


static void gcc_noinline f3(int r, uint32_t *e) { debug_trace(read_ebp(), e); }
  100a9e:	55                   	push   %ebp
  100a9f:	89 e5                	mov    %esp,%ebp
  100aa1:	83 ec 18             	sub    $0x18,%esp
static gcc_inline uint32_t
read_ebp(void)
{
        uint32_t ebp;
        __asm __volatile("movl %%ebp,%0" : "=rm" (ebp));
  100aa4:	89 6d fc             	mov    %ebp,0xfffffffc(%ebp)
        return ebp;
  100aa7:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  100aaa:	89 c2                	mov    %eax,%edx
  100aac:	8b 45 0c             	mov    0xc(%ebp),%eax
  100aaf:	89 44 24 04          	mov    %eax,0x4(%esp)
  100ab3:	89 14 24             	mov    %edx,(%esp)
  100ab6:	e8 84 ff ff ff       	call   100a3f <debug_trace>
  100abb:	c9                   	leave  
  100abc:	c3                   	ret    

00100abd <f2>:
static void gcc_noinline f2(int r, uint32_t *e) { r & 2 ? f3(r,e) : f3(r,e); }
  100abd:	55                   	push   %ebp
  100abe:	89 e5                	mov    %esp,%ebp
  100ac0:	83 ec 08             	sub    $0x8,%esp
  100ac3:	8b 45 08             	mov    0x8(%ebp),%eax
  100ac6:	83 e0 02             	and    $0x2,%eax
  100ac9:	85 c0                	test   %eax,%eax
  100acb:	74 14                	je     100ae1 <f2+0x24>
  100acd:	8b 45 0c             	mov    0xc(%ebp),%eax
  100ad0:	89 44 24 04          	mov    %eax,0x4(%esp)
  100ad4:	8b 45 08             	mov    0x8(%ebp),%eax
  100ad7:	89 04 24             	mov    %eax,(%esp)
  100ada:	e8 bf ff ff ff       	call   100a9e <f3>
  100adf:	eb 12                	jmp    100af3 <f2+0x36>
  100ae1:	8b 45 0c             	mov    0xc(%ebp),%eax
  100ae4:	89 44 24 04          	mov    %eax,0x4(%esp)
  100ae8:	8b 45 08             	mov    0x8(%ebp),%eax
  100aeb:	89 04 24             	mov    %eax,(%esp)
  100aee:	e8 ab ff ff ff       	call   100a9e <f3>
  100af3:	c9                   	leave  
  100af4:	c3                   	ret    

00100af5 <f1>:
static void gcc_noinline f1(int r, uint32_t *e) { r & 1 ? f2(r,e) : f2(r,e); }
  100af5:	55                   	push   %ebp
  100af6:	89 e5                	mov    %esp,%ebp
  100af8:	83 ec 08             	sub    $0x8,%esp
  100afb:	8b 45 08             	mov    0x8(%ebp),%eax
  100afe:	83 e0 01             	and    $0x1,%eax
  100b01:	84 c0                	test   %al,%al
  100b03:	74 14                	je     100b19 <f1+0x24>
  100b05:	8b 45 0c             	mov    0xc(%ebp),%eax
  100b08:	89 44 24 04          	mov    %eax,0x4(%esp)
  100b0c:	8b 45 08             	mov    0x8(%ebp),%eax
  100b0f:	89 04 24             	mov    %eax,(%esp)
  100b12:	e8 a6 ff ff ff       	call   100abd <f2>
  100b17:	eb 12                	jmp    100b2b <f1+0x36>
  100b19:	8b 45 0c             	mov    0xc(%ebp),%eax
  100b1c:	89 44 24 04          	mov    %eax,0x4(%esp)
  100b20:	8b 45 08             	mov    0x8(%ebp),%eax
  100b23:	89 04 24             	mov    %eax,(%esp)
  100b26:	e8 92 ff ff ff       	call   100abd <f2>
  100b2b:	c9                   	leave  
  100b2c:	c3                   	ret    

00100b2d <debug_check>:

// Test the backtrace implementation for correct operation
void
debug_check(void)
{
  100b2d:	55                   	push   %ebp
  100b2e:	89 e5                	mov    %esp,%ebp
  100b30:	81 ec c8 00 00 00    	sub    $0xc8,%esp
	uint32_t eips[4][DEBUG_TRACEFRAMES];
	int r, i;

	// produce several related backtraces...
	for (i = 0; i < 4; i++)
  100b36:	c7 45 fc 00 00 00 00 	movl   $0x0,0xfffffffc(%ebp)
  100b3d:	eb 2a                	jmp    100b69 <debug_check+0x3c>
		f1(i, eips[i]);
  100b3f:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  100b42:	89 d0                	mov    %edx,%eax
  100b44:	c1 e0 02             	shl    $0x2,%eax
  100b47:	01 d0                	add    %edx,%eax
  100b49:	c1 e0 03             	shl    $0x3,%eax
  100b4c:	89 c2                	mov    %eax,%edx
  100b4e:	8d 85 58 ff ff ff    	lea    0xffffff58(%ebp),%eax
  100b54:	01 d0                	add    %edx,%eax
  100b56:	89 44 24 04          	mov    %eax,0x4(%esp)
  100b5a:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  100b5d:	89 04 24             	mov    %eax,(%esp)
  100b60:	e8 90 ff ff ff       	call   100af5 <f1>
  100b65:	83 45 fc 01          	addl   $0x1,0xfffffffc(%ebp)
  100b69:	83 7d fc 03          	cmpl   $0x3,0xfffffffc(%ebp)
  100b6d:	7e d0                	jle    100b3f <debug_check+0x12>

	// ...and make sure they come out correctly.
	for (r = 0; r < 4; r++)
  100b6f:	c7 45 f8 00 00 00 00 	movl   $0x0,0xfffffff8(%ebp)
  100b76:	e9 bc 00 00 00       	jmp    100c37 <debug_check+0x10a>
		for (i = 0; i < DEBUG_TRACEFRAMES; i++) {
  100b7b:	c7 45 fc 00 00 00 00 	movl   $0x0,0xfffffffc(%ebp)
  100b82:	e9 a2 00 00 00       	jmp    100c29 <debug_check+0xfc>
			assert((eips[r][i] != 0) == (i < 5));
  100b87:	8b 55 f8             	mov    0xfffffff8(%ebp),%edx
  100b8a:	8b 4d fc             	mov    0xfffffffc(%ebp),%ecx
  100b8d:	89 d0                	mov    %edx,%eax
  100b8f:	c1 e0 02             	shl    $0x2,%eax
  100b92:	01 d0                	add    %edx,%eax
  100b94:	01 c0                	add    %eax,%eax
  100b96:	01 c8                	add    %ecx,%eax
  100b98:	8b 84 85 58 ff ff ff 	mov    0xffffff58(%ebp,%eax,4),%eax
  100b9f:	85 c0                	test   %eax,%eax
  100ba1:	0f 95 c2             	setne  %dl
  100ba4:	83 7d fc 04          	cmpl   $0x4,0xfffffffc(%ebp)
  100ba8:	0f 9e c0             	setle  %al
  100bab:	31 d0                	xor    %edx,%eax
  100bad:	84 c0                	test   %al,%al
  100baf:	74 24                	je     100bd5 <debug_check+0xa8>
  100bb1:	c7 44 24 0c ba c2 10 	movl   $0x10c2ba,0xc(%esp)
  100bb8:	00 
  100bb9:	c7 44 24 08 d7 c2 10 	movl   $0x10c2d7,0x8(%esp)
  100bc0:	00 
  100bc1:	c7 44 24 04 69 00 00 	movl   $0x69,0x4(%esp)
  100bc8:	00 
  100bc9:	c7 04 24 ec c2 10 00 	movl   $0x10c2ec,(%esp)
  100bd0:	e8 63 fd ff ff       	call   100938 <debug_panic>
			if (i >= 2)
  100bd5:	83 7d fc 01          	cmpl   $0x1,0xfffffffc(%ebp)
  100bd9:	7e 4a                	jle    100c25 <debug_check+0xf8>
				assert(eips[r][i] == eips[0][i]);
  100bdb:	8b 55 f8             	mov    0xfffffff8(%ebp),%edx
  100bde:	8b 4d fc             	mov    0xfffffffc(%ebp),%ecx
  100be1:	89 d0                	mov    %edx,%eax
  100be3:	c1 e0 02             	shl    $0x2,%eax
  100be6:	01 d0                	add    %edx,%eax
  100be8:	01 c0                	add    %eax,%eax
  100bea:	01 c8                	add    %ecx,%eax
  100bec:	8b 94 85 58 ff ff ff 	mov    0xffffff58(%ebp,%eax,4),%edx
  100bf3:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  100bf6:	8b 84 85 58 ff ff ff 	mov    0xffffff58(%ebp,%eax,4),%eax
  100bfd:	39 c2                	cmp    %eax,%edx
  100bff:	74 24                	je     100c25 <debug_check+0xf8>
  100c01:	c7 44 24 0c f9 c2 10 	movl   $0x10c2f9,0xc(%esp)
  100c08:	00 
  100c09:	c7 44 24 08 d7 c2 10 	movl   $0x10c2d7,0x8(%esp)
  100c10:	00 
  100c11:	c7 44 24 04 6b 00 00 	movl   $0x6b,0x4(%esp)
  100c18:	00 
  100c19:	c7 04 24 ec c2 10 00 	movl   $0x10c2ec,(%esp)
  100c20:	e8 13 fd ff ff       	call   100938 <debug_panic>
  100c25:	83 45 fc 01          	addl   $0x1,0xfffffffc(%ebp)
  100c29:	83 7d fc 09          	cmpl   $0x9,0xfffffffc(%ebp)
  100c2d:	0f 8e 54 ff ff ff    	jle    100b87 <debug_check+0x5a>
  100c33:	83 45 f8 01          	addl   $0x1,0xfffffff8(%ebp)
  100c37:	83 7d f8 03          	cmpl   $0x3,0xfffffff8(%ebp)
  100c3b:	0f 8e 3a ff ff ff    	jle    100b7b <debug_check+0x4e>
		}
	assert(eips[0][0] == eips[1][0]);
  100c41:	8b 95 58 ff ff ff    	mov    0xffffff58(%ebp),%edx
  100c47:	8b 45 80             	mov    0xffffff80(%ebp),%eax
  100c4a:	39 c2                	cmp    %eax,%edx
  100c4c:	74 24                	je     100c72 <debug_check+0x145>
  100c4e:	c7 44 24 0c 12 c3 10 	movl   $0x10c312,0xc(%esp)
  100c55:	00 
  100c56:	c7 44 24 08 d7 c2 10 	movl   $0x10c2d7,0x8(%esp)
  100c5d:	00 
  100c5e:	c7 44 24 04 6d 00 00 	movl   $0x6d,0x4(%esp)
  100c65:	00 
  100c66:	c7 04 24 ec c2 10 00 	movl   $0x10c2ec,(%esp)
  100c6d:	e8 c6 fc ff ff       	call   100938 <debug_panic>
	assert(eips[2][0] == eips[3][0]);
  100c72:	8b 55 a8             	mov    0xffffffa8(%ebp),%edx
  100c75:	8b 45 d0             	mov    0xffffffd0(%ebp),%eax
  100c78:	39 c2                	cmp    %eax,%edx
  100c7a:	74 24                	je     100ca0 <debug_check+0x173>
  100c7c:	c7 44 24 0c 2b c3 10 	movl   $0x10c32b,0xc(%esp)
  100c83:	00 
  100c84:	c7 44 24 08 d7 c2 10 	movl   $0x10c2d7,0x8(%esp)
  100c8b:	00 
  100c8c:	c7 44 24 04 6e 00 00 	movl   $0x6e,0x4(%esp)
  100c93:	00 
  100c94:	c7 04 24 ec c2 10 00 	movl   $0x10c2ec,(%esp)
  100c9b:	e8 98 fc ff ff       	call   100938 <debug_panic>
	assert(eips[1][0] != eips[2][0]);
  100ca0:	8b 55 80             	mov    0xffffff80(%ebp),%edx
  100ca3:	8b 45 a8             	mov    0xffffffa8(%ebp),%eax
  100ca6:	39 c2                	cmp    %eax,%edx
  100ca8:	75 24                	jne    100cce <debug_check+0x1a1>
  100caa:	c7 44 24 0c 44 c3 10 	movl   $0x10c344,0xc(%esp)
  100cb1:	00 
  100cb2:	c7 44 24 08 d7 c2 10 	movl   $0x10c2d7,0x8(%esp)
  100cb9:	00 
  100cba:	c7 44 24 04 6f 00 00 	movl   $0x6f,0x4(%esp)
  100cc1:	00 
  100cc2:	c7 04 24 ec c2 10 00 	movl   $0x10c2ec,(%esp)
  100cc9:	e8 6a fc ff ff       	call   100938 <debug_panic>
	assert(eips[0][1] == eips[2][1]);
  100cce:	8b 95 5c ff ff ff    	mov    0xffffff5c(%ebp),%edx
  100cd4:	8b 45 ac             	mov    0xffffffac(%ebp),%eax
  100cd7:	39 c2                	cmp    %eax,%edx
  100cd9:	74 24                	je     100cff <debug_check+0x1d2>
  100cdb:	c7 44 24 0c 5d c3 10 	movl   $0x10c35d,0xc(%esp)
  100ce2:	00 
  100ce3:	c7 44 24 08 d7 c2 10 	movl   $0x10c2d7,0x8(%esp)
  100cea:	00 
  100ceb:	c7 44 24 04 70 00 00 	movl   $0x70,0x4(%esp)
  100cf2:	00 
  100cf3:	c7 04 24 ec c2 10 00 	movl   $0x10c2ec,(%esp)
  100cfa:	e8 39 fc ff ff       	call   100938 <debug_panic>
	assert(eips[1][1] == eips[3][1]);
  100cff:	8b 55 84             	mov    0xffffff84(%ebp),%edx
  100d02:	8b 45 d4             	mov    0xffffffd4(%ebp),%eax
  100d05:	39 c2                	cmp    %eax,%edx
  100d07:	74 24                	je     100d2d <debug_check+0x200>
  100d09:	c7 44 24 0c 76 c3 10 	movl   $0x10c376,0xc(%esp)
  100d10:	00 
  100d11:	c7 44 24 08 d7 c2 10 	movl   $0x10c2d7,0x8(%esp)
  100d18:	00 
  100d19:	c7 44 24 04 71 00 00 	movl   $0x71,0x4(%esp)
  100d20:	00 
  100d21:	c7 04 24 ec c2 10 00 	movl   $0x10c2ec,(%esp)
  100d28:	e8 0b fc ff ff       	call   100938 <debug_panic>
	assert(eips[0][1] != eips[1][1]);
  100d2d:	8b 95 5c ff ff ff    	mov    0xffffff5c(%ebp),%edx
  100d33:	8b 45 84             	mov    0xffffff84(%ebp),%eax
  100d36:	39 c2                	cmp    %eax,%edx
  100d38:	75 24                	jne    100d5e <debug_check+0x231>
  100d3a:	c7 44 24 0c 8f c3 10 	movl   $0x10c38f,0xc(%esp)
  100d41:	00 
  100d42:	c7 44 24 08 d7 c2 10 	movl   $0x10c2d7,0x8(%esp)
  100d49:	00 
  100d4a:	c7 44 24 04 72 00 00 	movl   $0x72,0x4(%esp)
  100d51:	00 
  100d52:	c7 04 24 ec c2 10 00 	movl   $0x10c2ec,(%esp)
  100d59:	e8 da fb ff ff       	call   100938 <debug_panic>

	cprintf("debug_check() succeeded!\n");
  100d5e:	c7 04 24 a8 c3 10 00 	movl   $0x10c3a8,(%esp)
  100d65:	e8 03 ab 00 00       	call   10b86d <cprintf>
}
  100d6a:	c9                   	leave  
  100d6b:	c3                   	ret    

00100d6c <mem_init>:
  100d6c:	55                   	push   %ebp
  100d6d:	89 e5                	mov    %esp,%ebp
  100d6f:	53                   	push   %ebx
  100d70:	81 ec 44 01 00 00    	sub    $0x144,%esp
  100d76:	e8 23 04 00 00       	call   10119e <cpu_onboot>
  100d7b:	85 c0                	test   %eax,%eax
  100d7d:	0f 84 12 04 00 00    	je     101195 <mem_init+0x429>
  100d83:	8d 85 dc fe ff ff    	lea    0xfffffedc(%ebp),%eax
  100d89:	89 04 24             	mov    %eax,(%esp)
  100d8c:	e8 78 04 00 00       	call   101209 <detect_memory_e820>
  100d91:	66 89 45 a4          	mov    %ax,0xffffffa4(%ebp)
  100d95:	c7 45 a8 00 00 00 00 	movl   $0x0,0xffffffa8(%ebp)
  100d9c:	c7 45 ac 00 00 00 00 	movl   $0x0,0xffffffac(%ebp)
  100da3:	c7 05 dc 1d 18 00 00 	movl   $0x0,0x181ddc
  100daa:	00 00 00 
  100dad:	c7 45 b0 00 00 00 00 	movl   $0x0,0xffffffb0(%ebp)
  100db4:	e9 45 01 00 00       	jmp    100efe <mem_init+0x192>
  100db9:	8b 55 b0             	mov    0xffffffb0(%ebp),%edx
  100dbc:	89 d0                	mov    %edx,%eax
  100dbe:	c1 e0 02             	shl    $0x2,%eax
  100dc1:	01 d0                	add    %edx,%eax
  100dc3:	c1 e0 02             	shl    $0x2,%eax
  100dc6:	8d 55 f8             	lea    0xfffffff8(%ebp),%edx
  100dc9:	01 d0                	add    %edx,%eax
  100dcb:	2d 0c 01 00 00       	sub    $0x10c,%eax
  100dd0:	8b 00                	mov    (%eax),%eax
  100dd2:	83 f8 01             	cmp    $0x1,%eax
  100dd5:	74 42                	je     100e19 <mem_init+0xad>
  100dd7:	8b 55 b0             	mov    0xffffffb0(%ebp),%edx
  100dda:	89 d0                	mov    %edx,%eax
  100ddc:	c1 e0 02             	shl    $0x2,%eax
  100ddf:	01 d0                	add    %edx,%eax
  100de1:	c1 e0 02             	shl    $0x2,%eax
  100de4:	8d 4d f8             	lea    0xfffffff8(%ebp),%ecx
  100de7:	01 c8                	add    %ecx,%eax
  100de9:	2d 0c 01 00 00       	sub    $0x10c,%eax
  100dee:	8b 00                	mov    (%eax),%eax
  100df0:	83 f8 03             	cmp    $0x3,%eax
  100df3:	74 24                	je     100e19 <mem_init+0xad>
  100df5:	c7 44 24 0c c4 c3 10 	movl   $0x10c3c4,0xc(%esp)
  100dfc:	00 
  100dfd:	c7 44 24 08 0f c4 10 	movl   $0x10c40f,0x8(%esp)
  100e04:	00 
  100e05:	c7 44 24 04 3f 00 00 	movl   $0x3f,0x4(%esp)
  100e0c:	00 
  100e0d:	c7 04 24 24 c4 10 00 	movl   $0x10c424,(%esp)
  100e14:	e8 1f fb ff ff       	call   100938 <debug_panic>
  100e19:	8b 55 b0             	mov    0xffffffb0(%ebp),%edx
  100e1c:	89 d0                	mov    %edx,%eax
  100e1e:	c1 e0 02             	shl    $0x2,%eax
  100e21:	01 d0                	add    %edx,%eax
  100e23:	c1 e0 02             	shl    $0x2,%eax
  100e26:	8d 5d f8             	lea    0xfffffff8(%ebp),%ebx
  100e29:	01 d8                	add    %ebx,%eax
  100e2b:	2d 1c 01 00 00       	sub    $0x11c,%eax
  100e30:	8b 50 0c             	mov    0xc(%eax),%edx
  100e33:	8b 40 08             	mov    0x8(%eax),%eax
  100e36:	01 45 a8             	add    %eax,0xffffffa8(%ebp)
  100e39:	11 55 ac             	adc    %edx,0xffffffac(%ebp)
  100e3c:	a1 dc 1d 18 00       	mov    0x181ddc,%eax
  100e41:	89 45 c4             	mov    %eax,0xffffffc4(%ebp)
  100e44:	8b 55 b0             	mov    0xffffffb0(%ebp),%edx
  100e47:	89 d0                	mov    %edx,%eax
  100e49:	c1 e0 02             	shl    $0x2,%eax
  100e4c:	01 d0                	add    %edx,%eax
  100e4e:	c1 e0 02             	shl    $0x2,%eax
  100e51:	8d 55 f8             	lea    0xfffffff8(%ebp),%edx
  100e54:	01 d0                	add    %edx,%eax
  100e56:	2d 1c 01 00 00       	sub    $0x11c,%eax
  100e5b:	8b 08                	mov    (%eax),%ecx
  100e5d:	8b 58 04             	mov    0x4(%eax),%ebx
  100e60:	8b 55 b0             	mov    0xffffffb0(%ebp),%edx
  100e63:	89 d0                	mov    %edx,%eax
  100e65:	c1 e0 02             	shl    $0x2,%eax
  100e68:	01 d0                	add    %edx,%eax
  100e6a:	c1 e0 02             	shl    $0x2,%eax
  100e6d:	8d 55 f8             	lea    0xfffffff8(%ebp),%edx
  100e70:	01 d0                	add    %edx,%eax
  100e72:	2d 1c 01 00 00       	sub    $0x11c,%eax
  100e77:	8b 50 0c             	mov    0xc(%eax),%edx
  100e7a:	8b 40 08             	mov    0x8(%eax),%eax
  100e7d:	01 c8                	add    %ecx,%eax
  100e7f:	11 da                	adc    %ebx,%edx
  100e81:	89 45 c8             	mov    %eax,0xffffffc8(%ebp)
  100e84:	89 55 cc             	mov    %edx,0xffffffcc(%ebp)
  100e87:	8b 45 c4             	mov    0xffffffc4(%ebp),%eax
  100e8a:	ba 00 00 00 00       	mov    $0x0,%edx
  100e8f:	8b 4d c8             	mov    0xffffffc8(%ebp),%ecx
  100e92:	8b 5d cc             	mov    0xffffffcc(%ebp),%ebx
  100e95:	89 8d c8 fe ff ff    	mov    %ecx,0xfffffec8(%ebp)
  100e9b:	89 9d cc fe ff ff    	mov    %ebx,0xfffffecc(%ebp)
  100ea1:	89 85 d0 fe ff ff    	mov    %eax,0xfffffed0(%ebp)
  100ea7:	89 95 d4 fe ff ff    	mov    %edx,0xfffffed4(%ebp)
  100ead:	8b 9d cc fe ff ff    	mov    0xfffffecc(%ebp),%ebx
  100eb3:	39 9d d4 fe ff ff    	cmp    %ebx,0xfffffed4(%ebp)
  100eb9:	77 34                	ja     100eef <mem_init+0x183>
  100ebb:	8b 85 cc fe ff ff    	mov    0xfffffecc(%ebp),%eax
  100ec1:	39 85 d4 fe ff ff    	cmp    %eax,0xfffffed4(%ebp)
  100ec7:	72 0e                	jb     100ed7 <mem_init+0x16b>
  100ec9:	8b 95 c8 fe ff ff    	mov    0xfffffec8(%ebp),%edx
  100ecf:	39 95 d0 fe ff ff    	cmp    %edx,0xfffffed0(%ebp)
  100ed5:	73 18                	jae    100eef <mem_init+0x183>
  100ed7:	8b 8d c8 fe ff ff    	mov    0xfffffec8(%ebp),%ecx
  100edd:	8b 9d cc fe ff ff    	mov    0xfffffecc(%ebp),%ebx
  100ee3:	89 8d d0 fe ff ff    	mov    %ecx,0xfffffed0(%ebp)
  100ee9:	89 9d d4 fe ff ff    	mov    %ebx,0xfffffed4(%ebp)
  100eef:	8b 85 d0 fe ff ff    	mov    0xfffffed0(%ebp),%eax
  100ef5:	a3 dc 1d 18 00       	mov    %eax,0x181ddc
  100efa:	83 45 b0 01          	addl   $0x1,0xffffffb0(%ebp)
  100efe:	0f b7 45 a4          	movzwl 0xffffffa4(%ebp),%eax
  100f02:	3b 45 b0             	cmp    0xffffffb0(%ebp),%eax
  100f05:	0f 8f ae fe ff ff    	jg     100db9 <mem_init+0x4d>
  100f0b:	8b 45 a8             	mov    0xffffffa8(%ebp),%eax
  100f0e:	8b 55 ac             	mov    0xffffffac(%ebp),%edx
  100f11:	0f ac d0 0a          	shrd   $0xa,%edx,%eax
  100f15:	c1 ea 0a             	shr    $0xa,%edx
  100f18:	89 44 24 04          	mov    %eax,0x4(%esp)
  100f1c:	89 54 24 08          	mov    %edx,0x8(%esp)
  100f20:	c7 04 24 34 c4 10 00 	movl   $0x10c434,(%esp)
  100f27:	e8 41 a9 00 00       	call   10b86d <cprintf>
  100f2c:	a1 dc 1d 18 00       	mov    0x181ddc,%eax
  100f31:	89 c2                	mov    %eax,%edx
  100f33:	89 d0                	mov    %edx,%eax
  100f35:	c1 f8 1f             	sar    $0x1f,%eax
  100f38:	c1 e8 14             	shr    $0x14,%eax
  100f3b:	01 d0                	add    %edx,%eax
  100f3d:	c1 f8 0c             	sar    $0xc,%eax
  100f40:	a3 d8 1d 18 00       	mov    %eax,0x181dd8
  100f45:	c7 45 d0 08 00 00 00 	movl   $0x8,0xffffffd0(%ebp)
  100f4c:	b8 08 50 18 00       	mov    $0x185008,%eax
  100f51:	83 e8 01             	sub    $0x1,%eax
  100f54:	03 45 d0             	add    0xffffffd0(%ebp),%eax
  100f57:	89 45 d4             	mov    %eax,0xffffffd4(%ebp)
  100f5a:	8b 45 d4             	mov    0xffffffd4(%ebp),%eax
  100f5d:	ba 00 00 00 00       	mov    $0x0,%edx
  100f62:	f7 75 d0             	divl   0xffffffd0(%ebp)
  100f65:	8b 45 d4             	mov    0xffffffd4(%ebp),%eax
  100f68:	29 d0                	sub    %edx,%eax
  100f6a:	a3 e0 1d 18 00       	mov    %eax,0x181de0
  100f6f:	a1 d8 1d 18 00       	mov    0x181dd8,%eax
  100f74:	c1 e0 03             	shl    $0x3,%eax
  100f77:	8b 15 e0 1d 18 00    	mov    0x181de0,%edx
  100f7d:	89 44 24 08          	mov    %eax,0x8(%esp)
  100f81:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  100f88:	00 
  100f89:	89 14 24             	mov    %edx,(%esp)
  100f8c:	e8 60 ac 00 00       	call   10bbf1 <memset>
  100f91:	a1 d8 1d 18 00       	mov    0x181dd8,%eax
  100f96:	c1 e0 03             	shl    $0x3,%eax
  100f99:	89 c2                	mov    %eax,%edx
  100f9b:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  100fa0:	8d 04 02             	lea    (%edx,%eax,1),%eax
  100fa3:	89 45 bc             	mov    %eax,0xffffffbc(%ebp)
  100fa6:	c7 45 d8 00 10 00 00 	movl   $0x1000,0xffffffd8(%ebp)
  100fad:	8b 45 bc             	mov    0xffffffbc(%ebp),%eax
  100fb0:	03 45 d8             	add    0xffffffd8(%ebp),%eax
  100fb3:	83 e8 01             	sub    $0x1,%eax
  100fb6:	89 45 dc             	mov    %eax,0xffffffdc(%ebp)
  100fb9:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  100fbc:	ba 00 00 00 00       	mov    $0x0,%edx
  100fc1:	f7 75 d8             	divl   0xffffffd8(%ebp)
  100fc4:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  100fc7:	29 d0                	sub    %edx,%eax
  100fc9:	89 45 bc             	mov    %eax,0xffffffbc(%ebp)
  100fcc:	c7 44 24 08 60 00 00 	movl   $0x60,0x8(%esp)
  100fd3:	00 
  100fd4:	c7 44 24 04 24 c4 10 	movl   $0x10c424,0x4(%esp)
  100fdb:	00 
  100fdc:	c7 04 24 a0 1d 18 00 	movl   $0x181da0,(%esp)
  100fe3:	e8 a8 2e 00 00       	call   103e90 <spinlock_init_>
  100fe8:	c7 45 c0 80 1d 18 00 	movl   $0x181d80,0xffffffc0(%ebp)
  100fef:	c7 45 b0 00 00 00 00 	movl   $0x0,0xffffffb0(%ebp)
  100ff6:	eb 1b                	jmp    101013 <mem_init+0x2a7>
  100ff8:	8b 45 b0             	mov    0xffffffb0(%ebp),%eax
  100ffb:	c1 e0 03             	shl    $0x3,%eax
  100ffe:	89 c2                	mov    %eax,%edx
  101000:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  101005:	8d 04 02             	lea    (%edx,%eax,1),%eax
  101008:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
  10100f:	83 45 b0 01          	addl   $0x1,0xffffffb0(%ebp)
  101013:	8b 55 b0             	mov    0xffffffb0(%ebp),%edx
  101016:	a1 d8 1d 18 00       	mov    0x181dd8,%eax
  10101b:	39 c2                	cmp    %eax,%edx
  10101d:	72 d9                	jb     100ff8 <mem_init+0x28c>
  10101f:	c7 45 b0 00 00 00 00 	movl   $0x0,0xffffffb0(%ebp)
  101026:	e9 4f 01 00 00       	jmp    10117a <mem_init+0x40e>
  10102b:	8b 55 b0             	mov    0xffffffb0(%ebp),%edx
  10102e:	89 d0                	mov    %edx,%eax
  101030:	c1 e0 02             	shl    $0x2,%eax
  101033:	01 d0                	add    %edx,%eax
  101035:	c1 e0 02             	shl    $0x2,%eax
  101038:	8d 5d f8             	lea    0xfffffff8(%ebp),%ebx
  10103b:	01 d8                	add    %ebx,%eax
  10103d:	2d 1c 01 00 00       	sub    $0x11c,%eax
  101042:	8b 50 04             	mov    0x4(%eax),%edx
  101045:	8b 00                	mov    (%eax),%eax
  101047:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)
  10104a:	8b 55 b0             	mov    0xffffffb0(%ebp),%edx
  10104d:	89 d0                	mov    %edx,%eax
  10104f:	c1 e0 02             	shl    $0x2,%eax
  101052:	01 d0                	add    %edx,%eax
  101054:	c1 e0 02             	shl    $0x2,%eax
  101057:	8d 55 f8             	lea    0xfffffff8(%ebp),%edx
  10105a:	01 d0                	add    %edx,%eax
  10105c:	2d 1c 01 00 00       	sub    $0x11c,%eax
  101061:	8b 50 0c             	mov    0xc(%eax),%edx
  101064:	8b 40 08             	mov    0x8(%eax),%eax
  101067:	89 c2                	mov    %eax,%edx
  101069:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  10106c:	8d 04 02             	lea    (%edx,%eax,1),%eax
  10106f:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
  101072:	81 7d e0 ff 1f 00 00 	cmpl   $0x1fff,0xffffffe0(%ebp)
  101079:	7f 09                	jg     101084 <mem_init+0x318>
  10107b:	c7 45 e0 00 20 00 00 	movl   $0x2000,0xffffffe0(%ebp)
  101082:	eb 1c                	jmp    1010a0 <mem_init+0x334>
  101084:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  101087:	8b 55 bc             	mov    0xffffffbc(%ebp),%edx
  10108a:	39 d0                	cmp    %edx,%eax
  10108c:	73 12                	jae    1010a0 <mem_init+0x334>
  10108e:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  101091:	ba 0c 00 10 00       	mov    $0x10000c,%edx
  101096:	39 d0                	cmp    %edx,%eax
  101098:	76 06                	jbe    1010a0 <mem_init+0x334>
  10109a:	8b 45 bc             	mov    0xffffffbc(%ebp),%eax
  10109d:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)
  1010a0:	c7 45 e8 00 10 00 00 	movl   $0x1000,0xffffffe8(%ebp)
  1010a7:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  1010aa:	03 45 e8             	add    0xffffffe8(%ebp),%eax
  1010ad:	83 e8 01             	sub    $0x1,%eax
  1010b0:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  1010b3:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  1010b6:	ba 00 00 00 00       	mov    $0x0,%edx
  1010bb:	f7 75 e8             	divl   0xffffffe8(%ebp)
  1010be:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  1010c1:	29 d0                	sub    %edx,%eax
  1010c3:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)
  1010c6:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  1010c9:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
  1010cc:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  1010cf:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1010d4:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
  1010d7:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  1010da:	89 45 b4             	mov    %eax,0xffffffb4(%ebp)
  1010dd:	e9 88 00 00 00       	jmp    10116a <mem_init+0x3fe>
  1010e2:	8b 55 b4             	mov    0xffffffb4(%ebp),%edx
  1010e5:	89 d0                	mov    %edx,%eax
  1010e7:	c1 f8 1f             	sar    $0x1f,%eax
  1010ea:	c1 e8 14             	shr    $0x14,%eax
  1010ed:	01 d0                	add    %edx,%eax
  1010ef:	c1 f8 0c             	sar    $0xc,%eax
  1010f2:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
  1010f5:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  1010f8:	a1 d8 1d 18 00       	mov    0x181dd8,%eax
  1010fd:	39 c2                	cmp    %eax,%edx
  1010ff:	72 24                	jb     101125 <mem_init+0x3b9>
  101101:	c7 44 24 0c 54 c4 10 	movl   $0x10c454,0xc(%esp)
  101108:	00 
  101109:	c7 44 24 08 0f c4 10 	movl   $0x10c40f,0x8(%esp)
  101110:	00 
  101111:	c7 44 24 04 89 00 00 	movl   $0x89,0x4(%esp)
  101118:	00 
  101119:	c7 04 24 24 c4 10 00 	movl   $0x10c424,(%esp)
  101120:	e8 13 f8 ff ff       	call   100938 <debug_panic>
  101125:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  101128:	c1 e0 03             	shl    $0x3,%eax
  10112b:	89 c2                	mov    %eax,%edx
  10112d:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  101132:	8d 04 02             	lea    (%edx,%eax,1),%eax
  101135:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
  10113c:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  10113f:	c1 e0 03             	shl    $0x3,%eax
  101142:	89 c2                	mov    %eax,%edx
  101144:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  101149:	01 c2                	add    %eax,%edx
  10114b:	8b 45 c0             	mov    0xffffffc0(%ebp),%eax
  10114e:	89 10                	mov    %edx,(%eax)
  101150:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  101153:	c1 e0 03             	shl    $0x3,%eax
  101156:	89 c2                	mov    %eax,%edx
  101158:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  10115d:	8d 04 02             	lea    (%edx,%eax,1),%eax
  101160:	89 45 c0             	mov    %eax,0xffffffc0(%ebp)
  101163:	81 45 b4 00 10 00 00 	addl   $0x1000,0xffffffb4(%ebp)
  10116a:	8b 45 b4             	mov    0xffffffb4(%ebp),%eax
  10116d:	3b 45 e4             	cmp    0xffffffe4(%ebp),%eax
  101170:	0f 8c 6c ff ff ff    	jl     1010e2 <mem_init+0x376>
  101176:	83 45 b0 01          	addl   $0x1,0xffffffb0(%ebp)
  10117a:	0f b7 45 a4          	movzwl 0xffffffa4(%ebp),%eax
  10117e:	3b 45 b0             	cmp    0xffffffb0(%ebp),%eax
  101181:	0f 8f a4 fe ff ff    	jg     10102b <mem_init+0x2bf>
  101187:	8b 45 c0             	mov    0xffffffc0(%ebp),%eax
  10118a:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  101190:	e8 91 03 00 00       	call   101526 <mem_check>
  101195:	81 c4 44 01 00 00    	add    $0x144,%esp
  10119b:	5b                   	pop    %ebx
  10119c:	5d                   	pop    %ebp
  10119d:	c3                   	ret    

0010119e <cpu_onboot>:
}

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  10119e:	55                   	push   %ebp
  10119f:	89 e5                	mov    %esp,%ebp
  1011a1:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  1011a4:	e8 0d 00 00 00       	call   1011b6 <cpu_cur>
  1011a9:	3d 00 f0 10 00       	cmp    $0x10f000,%eax
  1011ae:	0f 94 c0             	sete   %al
  1011b1:	0f b6 c0             	movzbl %al,%eax
}
  1011b4:	c9                   	leave  
  1011b5:	c3                   	ret    

001011b6 <cpu_cur>:
  1011b6:	55                   	push   %ebp
  1011b7:	89 e5                	mov    %esp,%ebp
  1011b9:	83 ec 28             	sub    $0x28,%esp
static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  1011bc:	89 65 fc             	mov    %esp,0xfffffffc(%ebp)
        return esp;
  1011bf:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  1011c2:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  1011c5:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1011c8:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1011cd:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	assert(c->magic == CPU_MAGIC);
  1011d0:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  1011d3:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  1011d9:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  1011de:	74 24                	je     101204 <cpu_cur+0x4e>
  1011e0:	c7 44 24 0c 66 c4 10 	movl   $0x10c466,0xc(%esp)
  1011e7:	00 
  1011e8:	c7 44 24 08 0f c4 10 	movl   $0x10c40f,0x8(%esp)
  1011ef:	00 
  1011f0:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  1011f7:	00 
  1011f8:	c7 04 24 7c c4 10 00 	movl   $0x10c47c,(%esp)
  1011ff:	e8 34 f7 ff ff       	call   100938 <debug_panic>
	return c;
  101204:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
}
  101207:	c9                   	leave  
  101208:	c3                   	ret    

00101209 <detect_memory_e820>:
  101209:	55                   	push   %ebp
  10120a:	89 e5                	mov    %esp,%ebp
  10120c:	56                   	push   %esi
  10120d:	53                   	push   %ebx
  10120e:	83 ec 50             	sub    $0x50,%esp
  101211:	c7 45 e0 ac 0d 00 00 	movl   $0xdac,0xffffffe0(%ebp)
  101218:	c7 45 e4 b0 0d 00 00 	movl   $0xdb0,0xffffffe4(%ebp)
  10121f:	c7 45 e8 b4 0d 00 00 	movl   $0xdb4,0xffffffe8(%ebp)
  101226:	c7 45 ec b8 0d 00 00 	movl   $0xdb8,0xffffffec(%ebp)
  10122d:	c7 45 f0 bc 0d 00 00 	movl   $0xdbc,0xfffffff0(%ebp)
  101234:	c7 45 f4 00 00 00 00 	movl   $0x0,0xfffffff4(%ebp)
  10123b:	c7 45 c6 00 00 00 00 	movl   $0x0,0xffffffc6(%ebp)
  101242:	c6 45 df 00          	movb   $0x0,0xffffffdf(%ebp)
  101246:	c6 45 de 15          	movb   $0x15,0xffffffde(%ebp)
  10124a:	c7 45 c2 20 e8 00 00 	movl   $0xe820,0xffffffc2(%ebp)
  101251:	c7 45 ce 50 41 4d 53 	movl   $0x534d4150,0xffffffce(%ebp)
  101258:	c7 45 ca 18 00 00 00 	movl   $0x18,0xffffffca(%ebp)
  10125f:	66 c7 45 dc 00 00    	movw   $0x0,0xffffffdc(%ebp)
  101265:	c7 45 d6 ac 0d 00 00 	movl   $0xdac,0xffffffd6(%ebp)
  10126c:	66 c7 45 da 00 00    	movw   $0x0,0xffffffda(%ebp)
  101272:	c7 45 d2 00 00 00 00 	movl   $0x0,0xffffffd2(%ebp)
  101279:	8d 45 c2             	lea    0xffffffc2(%ebp),%eax
  10127c:	89 04 24             	mov    %eax,(%esp)
  10127f:	e8 59 01 00 00       	call   1013dd <bios_call>
  101284:	0f b7 45 dc          	movzwl 0xffffffdc(%ebp),%eax
  101288:	66 85 c0             	test   %ax,%ax
  10128b:	75 0a                	jne    101297 <detect_memory_e820+0x8e>
  10128d:	8b 45 d6             	mov    0xffffffd6(%ebp),%eax
  101290:	3d ac 0d 00 00       	cmp    $0xdac,%eax
  101295:	74 24                	je     1012bb <detect_memory_e820+0xb2>
  101297:	c7 44 24 0c 8c c4 10 	movl   $0x10c48c,0xc(%esp)
  10129e:	00 
  10129f:	c7 44 24 08 0f c4 10 	movl   $0x10c40f,0x8(%esp)
  1012a6:	00 
  1012a7:	c7 44 24 04 e2 00 00 	movl   $0xe2,0x4(%esp)
  1012ae:	00 
  1012af:	c7 04 24 24 c4 10 00 	movl   $0x10c424,(%esp)
  1012b6:	e8 7d f6 ff ff       	call   100938 <debug_panic>
  1012bb:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  1012be:	8b 00                	mov    (%eax),%eax
  1012c0:	83 f8 01             	cmp    $0x1,%eax
  1012c3:	74 0e                	je     1012d3 <detect_memory_e820+0xca>
  1012c5:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  1012c8:	8b 00                	mov    (%eax),%eax
  1012ca:	83 f8 03             	cmp    $0x3,%eax
  1012cd:	0f 85 bd 00 00 00    	jne    101390 <detect_memory_e820+0x187>
  1012d3:	83 7d f4 09          	cmpl   $0x9,0xfffffff4(%ebp)
  1012d7:	7e 24                	jle    1012fd <detect_memory_e820+0xf4>
  1012d9:	c7 44 24 0c c0 c4 10 	movl   $0x10c4c0,0xc(%esp)
  1012e0:	00 
  1012e1:	c7 44 24 08 0f c4 10 	movl   $0x10c40f,0x8(%esp)
  1012e8:	00 
  1012e9:	c7 44 24 04 e8 00 00 	movl   $0xe8,0x4(%esp)
  1012f0:	00 
  1012f1:	c7 04 24 24 c4 10 00 	movl   $0x10c424,(%esp)
  1012f8:	e8 3b f6 ff ff       	call   100938 <debug_panic>
  1012fd:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  101300:	89 d0                	mov    %edx,%eax
  101302:	c1 e0 02             	shl    $0x2,%eax
  101305:	01 d0                	add    %edx,%eax
  101307:	c1 e0 02             	shl    $0x2,%eax
  10130a:	89 c6                	mov    %eax,%esi
  10130c:	03 75 08             	add    0x8(%ebp),%esi
  10130f:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  101312:	8b 00                	mov    (%eax),%eax
  101314:	ba 00 00 00 00       	mov    $0x0,%edx
  101319:	89 c1                	mov    %eax,%ecx
  10131b:	89 d3                	mov    %edx,%ebx
  10131d:	89 cb                	mov    %ecx,%ebx
  10131f:	b9 00 00 00 00       	mov    $0x0,%ecx
  101324:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  101327:	8b 00                	mov    (%eax),%eax
  101329:	ba 00 00 00 00       	mov    $0x0,%edx
  10132e:	01 c8                	add    %ecx,%eax
  101330:	11 da                	adc    %ebx,%edx
  101332:	89 06                	mov    %eax,(%esi)
  101334:	89 56 04             	mov    %edx,0x4(%esi)
  101337:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  10133a:	89 d0                	mov    %edx,%eax
  10133c:	c1 e0 02             	shl    $0x2,%eax
  10133f:	01 d0                	add    %edx,%eax
  101341:	c1 e0 02             	shl    $0x2,%eax
  101344:	89 c6                	mov    %eax,%esi
  101346:	03 75 08             	add    0x8(%ebp),%esi
  101349:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  10134c:	8b 00                	mov    (%eax),%eax
  10134e:	ba 00 00 00 00       	mov    $0x0,%edx
  101353:	89 c1                	mov    %eax,%ecx
  101355:	89 d3                	mov    %edx,%ebx
  101357:	89 cb                	mov    %ecx,%ebx
  101359:	b9 00 00 00 00       	mov    $0x0,%ecx
  10135e:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  101361:	8b 00                	mov    (%eax),%eax
  101363:	ba 00 00 00 00       	mov    $0x0,%edx
  101368:	01 c8                	add    %ecx,%eax
  10136a:	11 da                	adc    %ebx,%edx
  10136c:	89 46 08             	mov    %eax,0x8(%esi)
  10136f:	89 56 0c             	mov    %edx,0xc(%esi)
  101372:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  101375:	89 d0                	mov    %edx,%eax
  101377:	c1 e0 02             	shl    $0x2,%eax
  10137a:	01 d0                	add    %edx,%eax
  10137c:	c1 e0 02             	shl    $0x2,%eax
  10137f:	89 c2                	mov    %eax,%edx
  101381:	03 55 08             	add    0x8(%ebp),%edx
  101384:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  101387:	8b 00                	mov    (%eax),%eax
  101389:	89 42 10             	mov    %eax,0x10(%edx)
  10138c:	83 45 f4 01          	addl   $0x1,0xfffffff4(%ebp)
  101390:	8b 45 c6             	mov    0xffffffc6(%ebp),%eax
  101393:	85 c0                	test   %eax,%eax
  101395:	74 16                	je     1013ad <detect_memory_e820+0x1a4>
  101397:	0f b6 45 df          	movzbl 0xffffffdf(%ebp),%eax
  10139b:	84 c0                	test   %al,%al
  10139d:	75 0e                	jne    1013ad <detect_memory_e820+0x1a4>
  10139f:	8b 45 c2             	mov    0xffffffc2(%ebp),%eax
  1013a2:	3d 50 41 4d 53       	cmp    $0x534d4150,%eax
  1013a7:	0f 84 99 fe ff ff    	je     101246 <detect_memory_e820+0x3d>
  1013ad:	8b 45 c2             	mov    0xffffffc2(%ebp),%eax
  1013b0:	3d 50 41 4d 53       	cmp    $0x534d4150,%eax
  1013b5:	74 1c                	je     1013d3 <detect_memory_e820+0x1ca>
  1013b7:	c7 44 24 08 d8 c4 10 	movl   $0x10c4d8,0x8(%esp)
  1013be:	00 
  1013bf:	c7 44 24 04 f5 00 00 	movl   $0xf5,0x4(%esp)
  1013c6:	00 
  1013c7:	c7 04 24 24 c4 10 00 	movl   $0x10c424,(%esp)
  1013ce:	e8 23 f6 ff ff       	call   1009f6 <debug_warn>
  1013d3:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  1013d6:	83 c4 50             	add    $0x50,%esp
  1013d9:	5b                   	pop    %ebx
  1013da:	5e                   	pop    %esi
  1013db:	5d                   	pop    %ebp
  1013dc:	c3                   	ret    

001013dd <bios_call>:
  1013dd:	55                   	push   %ebp
  1013de:	89 e5                	mov    %esp,%ebp
  1013e0:	56                   	push   %esi
  1013e1:	53                   	push   %ebx
  1013e2:	83 ec 10             	sub    $0x10,%esp
  1013e5:	c7 45 f4 e2 0f 00 00 	movl   $0xfe2,0xfffffff4(%ebp)
  1013ec:	8b 4d f4             	mov    0xfffffff4(%ebp),%ecx
  1013ef:	8b 55 08             	mov    0x8(%ebp),%edx
  1013f2:	8b 02                	mov    (%edx),%eax
  1013f4:	89 01                	mov    %eax,(%ecx)
  1013f6:	8b 42 04             	mov    0x4(%edx),%eax
  1013f9:	89 41 04             	mov    %eax,0x4(%ecx)
  1013fc:	8b 42 08             	mov    0x8(%edx),%eax
  1013ff:	89 41 08             	mov    %eax,0x8(%ecx)
  101402:	8b 42 0c             	mov    0xc(%edx),%eax
  101405:	89 41 0c             	mov    %eax,0xc(%ecx)
  101408:	8b 42 10             	mov    0x10(%edx),%eax
  10140b:	89 41 10             	mov    %eax,0x10(%ecx)
  10140e:	8b 42 14             	mov    0x14(%edx),%eax
  101411:	89 41 14             	mov    %eax,0x14(%ecx)
  101414:	8b 42 18             	mov    0x18(%edx),%eax
  101417:	89 41 18             	mov    %eax,0x18(%ecx)
  10141a:	0f b7 42 1c          	movzwl 0x1c(%edx),%eax
  10141e:	66 89 41 1c          	mov    %ax,0x1c(%ecx)
  101422:	ff 15 04 10 00 00    	call   *0x1004
  101428:	8b 4d 08             	mov    0x8(%ebp),%ecx
  10142b:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  10142e:	8b 02                	mov    (%edx),%eax
  101430:	89 01                	mov    %eax,(%ecx)
  101432:	8b 42 04             	mov    0x4(%edx),%eax
  101435:	89 41 04             	mov    %eax,0x4(%ecx)
  101438:	8b 42 08             	mov    0x8(%edx),%eax
  10143b:	89 41 08             	mov    %eax,0x8(%ecx)
  10143e:	8b 42 0c             	mov    0xc(%edx),%eax
  101441:	89 41 0c             	mov    %eax,0xc(%ecx)
  101444:	8b 42 10             	mov    0x10(%edx),%eax
  101447:	89 41 10             	mov    %eax,0x10(%ecx)
  10144a:	8b 42 14             	mov    0x14(%edx),%eax
  10144d:	89 41 14             	mov    %eax,0x14(%ecx)
  101450:	8b 42 18             	mov    0x18(%edx),%eax
  101453:	89 41 18             	mov    %eax,0x18(%ecx)
  101456:	0f b7 42 1c          	movzwl 0x1c(%edx),%eax
  10145a:	66 89 41 1c          	mov    %ax,0x1c(%ecx)
  10145e:	83 c4 10             	add    $0x10,%esp
  101461:	5b                   	pop    %ebx
  101462:	5e                   	pop    %esi
  101463:	5d                   	pop    %ebp
  101464:	c3                   	ret    

00101465 <mem_alloc>:
  101465:	55                   	push   %ebp
  101466:	89 e5                	mov    %esp,%ebp
  101468:	83 ec 18             	sub    $0x18,%esp
  10146b:	c7 04 24 a0 1d 18 00 	movl   $0x181da0,(%esp)
  101472:	e8 43 2a 00 00       	call   103eba <spinlock_acquire>
  101477:	a1 80 1d 18 00       	mov    0x181d80,%eax
  10147c:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  10147f:	83 7d fc 00          	cmpl   $0x0,0xfffffffc(%ebp)
  101483:	74 13                	je     101498 <mem_alloc+0x33>
  101485:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  101488:	8b 00                	mov    (%eax),%eax
  10148a:	a3 80 1d 18 00       	mov    %eax,0x181d80
  10148f:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  101492:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  101498:	c7 04 24 a0 1d 18 00 	movl   $0x181da0,(%esp)
  10149f:	e8 11 2b 00 00       	call   103fb5 <spinlock_release>
  1014a4:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  1014a7:	c9                   	leave  
  1014a8:	c3                   	ret    

001014a9 <mem_free>:
  1014a9:	55                   	push   %ebp
  1014aa:	89 e5                	mov    %esp,%ebp
  1014ac:	83 ec 18             	sub    $0x18,%esp
  1014af:	8b 45 08             	mov    0x8(%ebp),%eax
  1014b2:	8b 40 04             	mov    0x4(%eax),%eax
  1014b5:	85 c0                	test   %eax,%eax
  1014b7:	74 1c                	je     1014d5 <mem_free+0x2c>
  1014b9:	c7 44 24 08 fc c4 10 	movl   $0x10c4fc,0x8(%esp)
  1014c0:	00 
  1014c1:	c7 44 24 04 44 01 00 	movl   $0x144,0x4(%esp)
  1014c8:	00 
  1014c9:	c7 04 24 24 c4 10 00 	movl   $0x10c424,(%esp)
  1014d0:	e8 63 f4 ff ff       	call   100938 <debug_panic>
  1014d5:	8b 45 08             	mov    0x8(%ebp),%eax
  1014d8:	8b 00                	mov    (%eax),%eax
  1014da:	85 c0                	test   %eax,%eax
  1014dc:	74 1c                	je     1014fa <mem_free+0x51>
  1014de:	c7 44 24 08 24 c5 10 	movl   $0x10c524,0x8(%esp)
  1014e5:	00 
  1014e6:	c7 44 24 04 46 01 00 	movl   $0x146,0x4(%esp)
  1014ed:	00 
  1014ee:	c7 04 24 24 c4 10 00 	movl   $0x10c424,(%esp)
  1014f5:	e8 3e f4 ff ff       	call   100938 <debug_panic>
  1014fa:	c7 04 24 a0 1d 18 00 	movl   $0x181da0,(%esp)
  101501:	e8 b4 29 00 00       	call   103eba <spinlock_acquire>
  101506:	a1 80 1d 18 00       	mov    0x181d80,%eax
  10150b:	8b 55 08             	mov    0x8(%ebp),%edx
  10150e:	89 02                	mov    %eax,(%edx)
  101510:	8b 45 08             	mov    0x8(%ebp),%eax
  101513:	a3 80 1d 18 00       	mov    %eax,0x181d80
  101518:	c7 04 24 a0 1d 18 00 	movl   $0x181da0,(%esp)
  10151f:	e8 91 2a 00 00       	call   103fb5 <spinlock_release>
  101524:	c9                   	leave  
  101525:	c3                   	ret    

00101526 <mem_check>:
  101526:	55                   	push   %ebp
  101527:	89 e5                	mov    %esp,%ebp
  101529:	83 ec 38             	sub    $0x38,%esp
  10152c:	c7 45 fc 00 00 00 00 	movl   $0x0,0xfffffffc(%ebp)
  101533:	a1 80 1d 18 00       	mov    0x181d80,%eax
  101538:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
  10153b:	eb 35                	jmp    101572 <mem_check+0x4c>
  10153d:	8b 55 e4             	mov    0xffffffe4(%ebp),%edx
  101540:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  101545:	89 d1                	mov    %edx,%ecx
  101547:	29 c1                	sub    %eax,%ecx
  101549:	89 c8                	mov    %ecx,%eax
  10154b:	c1 e0 09             	shl    $0x9,%eax
  10154e:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
  101555:	00 
  101556:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
  10155d:	00 
  10155e:	89 04 24             	mov    %eax,(%esp)
  101561:	e8 8b a6 00 00       	call   10bbf1 <memset>
  101566:	83 45 fc 01          	addl   $0x1,0xfffffffc(%ebp)
  10156a:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  10156d:	8b 00                	mov    (%eax),%eax
  10156f:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
  101572:	83 7d e4 00          	cmpl   $0x0,0xffffffe4(%ebp)
  101576:	75 c5                	jne    10153d <mem_check+0x17>
  101578:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  10157b:	89 44 24 04          	mov    %eax,0x4(%esp)
  10157f:	c7 04 24 51 c5 10 00 	movl   $0x10c551,(%esp)
  101586:	e8 e2 a2 00 00       	call   10b86d <cprintf>
  10158b:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  10158e:	a1 d8 1d 18 00       	mov    0x181dd8,%eax
  101593:	39 c2                	cmp    %eax,%edx
  101595:	72 24                	jb     1015bb <mem_check+0x95>
  101597:	c7 44 24 0c 6b c5 10 	movl   $0x10c56b,0xc(%esp)
  10159e:	00 
  10159f:	c7 44 24 08 0f c4 10 	movl   $0x10c40f,0x8(%esp)
  1015a6:	00 
  1015a7:	c7 44 24 04 b6 01 00 	movl   $0x1b6,0x4(%esp)
  1015ae:	00 
  1015af:	c7 04 24 24 c4 10 00 	movl   $0x10c424,(%esp)
  1015b6:	e8 7d f3 ff ff       	call   100938 <debug_panic>
  1015bb:	81 7d fc 80 3e 00 00 	cmpl   $0x3e80,0xfffffffc(%ebp)
  1015c2:	7f 24                	jg     1015e8 <mem_check+0xc2>
  1015c4:	c7 44 24 0c 81 c5 10 	movl   $0x10c581,0xc(%esp)
  1015cb:	00 
  1015cc:	c7 44 24 08 0f c4 10 	movl   $0x10c40f,0x8(%esp)
  1015d3:	00 
  1015d4:	c7 44 24 04 b7 01 00 	movl   $0x1b7,0x4(%esp)
  1015db:	00 
  1015dc:	c7 04 24 24 c4 10 00 	movl   $0x10c424,(%esp)
  1015e3:	e8 50 f3 ff ff       	call   100938 <debug_panic>
  1015e8:	c7 45 f0 00 00 00 00 	movl   $0x0,0xfffffff0(%ebp)
  1015ef:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  1015f2:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  1015f5:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  1015f8:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  1015fb:	e8 65 fe ff ff       	call   101465 <mem_alloc>
  101600:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  101603:	83 7d e8 00          	cmpl   $0x0,0xffffffe8(%ebp)
  101607:	75 24                	jne    10162d <mem_check+0x107>
  101609:	c7 44 24 0c 93 c5 10 	movl   $0x10c593,0xc(%esp)
  101610:	00 
  101611:	c7 44 24 08 0f c4 10 	movl   $0x10c40f,0x8(%esp)
  101618:	00 
  101619:	c7 44 24 04 bb 01 00 	movl   $0x1bb,0x4(%esp)
  101620:	00 
  101621:	c7 04 24 24 c4 10 00 	movl   $0x10c424,(%esp)
  101628:	e8 0b f3 ff ff       	call   100938 <debug_panic>
  10162d:	e8 33 fe ff ff       	call   101465 <mem_alloc>
  101632:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  101635:	83 7d ec 00          	cmpl   $0x0,0xffffffec(%ebp)
  101639:	75 24                	jne    10165f <mem_check+0x139>
  10163b:	c7 44 24 0c 9c c5 10 	movl   $0x10c59c,0xc(%esp)
  101642:	00 
  101643:	c7 44 24 08 0f c4 10 	movl   $0x10c40f,0x8(%esp)
  10164a:	00 
  10164b:	c7 44 24 04 bc 01 00 	movl   $0x1bc,0x4(%esp)
  101652:	00 
  101653:	c7 04 24 24 c4 10 00 	movl   $0x10c424,(%esp)
  10165a:	e8 d9 f2 ff ff       	call   100938 <debug_panic>
  10165f:	e8 01 fe ff ff       	call   101465 <mem_alloc>
  101664:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
  101667:	83 7d f0 00          	cmpl   $0x0,0xfffffff0(%ebp)
  10166b:	75 24                	jne    101691 <mem_check+0x16b>
  10166d:	c7 44 24 0c a5 c5 10 	movl   $0x10c5a5,0xc(%esp)
  101674:	00 
  101675:	c7 44 24 08 0f c4 10 	movl   $0x10c40f,0x8(%esp)
  10167c:	00 
  10167d:	c7 44 24 04 bd 01 00 	movl   $0x1bd,0x4(%esp)
  101684:	00 
  101685:	c7 04 24 24 c4 10 00 	movl   $0x10c424,(%esp)
  10168c:	e8 a7 f2 ff ff       	call   100938 <debug_panic>
  101691:	83 7d e8 00          	cmpl   $0x0,0xffffffe8(%ebp)
  101695:	75 24                	jne    1016bb <mem_check+0x195>
  101697:	c7 44 24 0c ae c5 10 	movl   $0x10c5ae,0xc(%esp)
  10169e:	00 
  10169f:	c7 44 24 08 0f c4 10 	movl   $0x10c40f,0x8(%esp)
  1016a6:	00 
  1016a7:	c7 44 24 04 bf 01 00 	movl   $0x1bf,0x4(%esp)
  1016ae:	00 
  1016af:	c7 04 24 24 c4 10 00 	movl   $0x10c424,(%esp)
  1016b6:	e8 7d f2 ff ff       	call   100938 <debug_panic>
  1016bb:	83 7d ec 00          	cmpl   $0x0,0xffffffec(%ebp)
  1016bf:	74 08                	je     1016c9 <mem_check+0x1a3>
  1016c1:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  1016c4:	3b 45 e8             	cmp    0xffffffe8(%ebp),%eax
  1016c7:	75 24                	jne    1016ed <mem_check+0x1c7>
  1016c9:	c7 44 24 0c b2 c5 10 	movl   $0x10c5b2,0xc(%esp)
  1016d0:	00 
  1016d1:	c7 44 24 08 0f c4 10 	movl   $0x10c40f,0x8(%esp)
  1016d8:	00 
  1016d9:	c7 44 24 04 c0 01 00 	movl   $0x1c0,0x4(%esp)
  1016e0:	00 
  1016e1:	c7 04 24 24 c4 10 00 	movl   $0x10c424,(%esp)
  1016e8:	e8 4b f2 ff ff       	call   100938 <debug_panic>
  1016ed:	83 7d f0 00          	cmpl   $0x0,0xfffffff0(%ebp)
  1016f1:	74 10                	je     101703 <mem_check+0x1dd>
  1016f3:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  1016f6:	3b 45 ec             	cmp    0xffffffec(%ebp),%eax
  1016f9:	74 08                	je     101703 <mem_check+0x1dd>
  1016fb:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  1016fe:	3b 45 e8             	cmp    0xffffffe8(%ebp),%eax
  101701:	75 24                	jne    101727 <mem_check+0x201>
  101703:	c7 44 24 0c c4 c5 10 	movl   $0x10c5c4,0xc(%esp)
  10170a:	00 
  10170b:	c7 44 24 08 0f c4 10 	movl   $0x10c40f,0x8(%esp)
  101712:	00 
  101713:	c7 44 24 04 c1 01 00 	movl   $0x1c1,0x4(%esp)
  10171a:	00 
  10171b:	c7 04 24 24 c4 10 00 	movl   $0x10c424,(%esp)
  101722:	e8 11 f2 ff ff       	call   100938 <debug_panic>
  101727:	8b 55 e8             	mov    0xffffffe8(%ebp),%edx
  10172a:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  10172f:	89 d1                	mov    %edx,%ecx
  101731:	29 c1                	sub    %eax,%ecx
  101733:	89 c8                	mov    %ecx,%eax
  101735:	c1 e0 09             	shl    $0x9,%eax
  101738:	89 c2                	mov    %eax,%edx
  10173a:	a1 d8 1d 18 00       	mov    0x181dd8,%eax
  10173f:	c1 e0 0c             	shl    $0xc,%eax
  101742:	39 c2                	cmp    %eax,%edx
  101744:	72 24                	jb     10176a <mem_check+0x244>
  101746:	c7 44 24 0c e4 c5 10 	movl   $0x10c5e4,0xc(%esp)
  10174d:	00 
  10174e:	c7 44 24 08 0f c4 10 	movl   $0x10c40f,0x8(%esp)
  101755:	00 
  101756:	c7 44 24 04 c2 01 00 	movl   $0x1c2,0x4(%esp)
  10175d:	00 
  10175e:	c7 04 24 24 c4 10 00 	movl   $0x10c424,(%esp)
  101765:	e8 ce f1 ff ff       	call   100938 <debug_panic>
  10176a:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
  10176d:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  101772:	89 d1                	mov    %edx,%ecx
  101774:	29 c1                	sub    %eax,%ecx
  101776:	89 c8                	mov    %ecx,%eax
  101778:	c1 e0 09             	shl    $0x9,%eax
  10177b:	89 c2                	mov    %eax,%edx
  10177d:	a1 d8 1d 18 00       	mov    0x181dd8,%eax
  101782:	c1 e0 0c             	shl    $0xc,%eax
  101785:	39 c2                	cmp    %eax,%edx
  101787:	72 24                	jb     1017ad <mem_check+0x287>
  101789:	c7 44 24 0c 0c c6 10 	movl   $0x10c60c,0xc(%esp)
  101790:	00 
  101791:	c7 44 24 08 0f c4 10 	movl   $0x10c40f,0x8(%esp)
  101798:	00 
  101799:	c7 44 24 04 c3 01 00 	movl   $0x1c3,0x4(%esp)
  1017a0:	00 
  1017a1:	c7 04 24 24 c4 10 00 	movl   $0x10c424,(%esp)
  1017a8:	e8 8b f1 ff ff       	call   100938 <debug_panic>
  1017ad:	8b 55 f0             	mov    0xfffffff0(%ebp),%edx
  1017b0:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  1017b5:	89 d1                	mov    %edx,%ecx
  1017b7:	29 c1                	sub    %eax,%ecx
  1017b9:	89 c8                	mov    %ecx,%eax
  1017bb:	c1 e0 09             	shl    $0x9,%eax
  1017be:	89 c2                	mov    %eax,%edx
  1017c0:	a1 d8 1d 18 00       	mov    0x181dd8,%eax
  1017c5:	c1 e0 0c             	shl    $0xc,%eax
  1017c8:	39 c2                	cmp    %eax,%edx
  1017ca:	72 24                	jb     1017f0 <mem_check+0x2ca>
  1017cc:	c7 44 24 0c 34 c6 10 	movl   $0x10c634,0xc(%esp)
  1017d3:	00 
  1017d4:	c7 44 24 08 0f c4 10 	movl   $0x10c40f,0x8(%esp)
  1017db:	00 
  1017dc:	c7 44 24 04 c4 01 00 	movl   $0x1c4,0x4(%esp)
  1017e3:	00 
  1017e4:	c7 04 24 24 c4 10 00 	movl   $0x10c424,(%esp)
  1017eb:	e8 48 f1 ff ff       	call   100938 <debug_panic>
  1017f0:	a1 80 1d 18 00       	mov    0x181d80,%eax
  1017f5:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
  1017f8:	c7 05 80 1d 18 00 00 	movl   $0x0,0x181d80
  1017ff:	00 00 00 
  101802:	e8 5e fc ff ff       	call   101465 <mem_alloc>
  101807:	85 c0                	test   %eax,%eax
  101809:	74 24                	je     10182f <mem_check+0x309>
  10180b:	c7 44 24 0c 5a c6 10 	movl   $0x10c65a,0xc(%esp)
  101812:	00 
  101813:	c7 44 24 08 0f c4 10 	movl   $0x10c40f,0x8(%esp)
  10181a:	00 
  10181b:	c7 44 24 04 cb 01 00 	movl   $0x1cb,0x4(%esp)
  101822:	00 
  101823:	c7 04 24 24 c4 10 00 	movl   $0x10c424,(%esp)
  10182a:	e8 09 f1 ff ff       	call   100938 <debug_panic>
  10182f:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  101832:	89 04 24             	mov    %eax,(%esp)
  101835:	e8 6f fc ff ff       	call   1014a9 <mem_free>
  10183a:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  10183d:	89 04 24             	mov    %eax,(%esp)
  101840:	e8 64 fc ff ff       	call   1014a9 <mem_free>
  101845:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  101848:	89 04 24             	mov    %eax,(%esp)
  10184b:	e8 59 fc ff ff       	call   1014a9 <mem_free>
  101850:	c7 45 f0 00 00 00 00 	movl   $0x0,0xfffffff0(%ebp)
  101857:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  10185a:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  10185d:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  101860:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  101863:	e8 fd fb ff ff       	call   101465 <mem_alloc>
  101868:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  10186b:	83 7d e8 00          	cmpl   $0x0,0xffffffe8(%ebp)
  10186f:	75 24                	jne    101895 <mem_check+0x36f>
  101871:	c7 44 24 0c 93 c5 10 	movl   $0x10c593,0xc(%esp)
  101878:	00 
  101879:	c7 44 24 08 0f c4 10 	movl   $0x10c40f,0x8(%esp)
  101880:	00 
  101881:	c7 44 24 04 d2 01 00 	movl   $0x1d2,0x4(%esp)
  101888:	00 
  101889:	c7 04 24 24 c4 10 00 	movl   $0x10c424,(%esp)
  101890:	e8 a3 f0 ff ff       	call   100938 <debug_panic>
  101895:	e8 cb fb ff ff       	call   101465 <mem_alloc>
  10189a:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  10189d:	83 7d ec 00          	cmpl   $0x0,0xffffffec(%ebp)
  1018a1:	75 24                	jne    1018c7 <mem_check+0x3a1>
  1018a3:	c7 44 24 0c 9c c5 10 	movl   $0x10c59c,0xc(%esp)
  1018aa:	00 
  1018ab:	c7 44 24 08 0f c4 10 	movl   $0x10c40f,0x8(%esp)
  1018b2:	00 
  1018b3:	c7 44 24 04 d3 01 00 	movl   $0x1d3,0x4(%esp)
  1018ba:	00 
  1018bb:	c7 04 24 24 c4 10 00 	movl   $0x10c424,(%esp)
  1018c2:	e8 71 f0 ff ff       	call   100938 <debug_panic>
  1018c7:	e8 99 fb ff ff       	call   101465 <mem_alloc>
  1018cc:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
  1018cf:	83 7d f0 00          	cmpl   $0x0,0xfffffff0(%ebp)
  1018d3:	75 24                	jne    1018f9 <mem_check+0x3d3>
  1018d5:	c7 44 24 0c a5 c5 10 	movl   $0x10c5a5,0xc(%esp)
  1018dc:	00 
  1018dd:	c7 44 24 08 0f c4 10 	movl   $0x10c40f,0x8(%esp)
  1018e4:	00 
  1018e5:	c7 44 24 04 d4 01 00 	movl   $0x1d4,0x4(%esp)
  1018ec:	00 
  1018ed:	c7 04 24 24 c4 10 00 	movl   $0x10c424,(%esp)
  1018f4:	e8 3f f0 ff ff       	call   100938 <debug_panic>
  1018f9:	83 7d e8 00          	cmpl   $0x0,0xffffffe8(%ebp)
  1018fd:	75 24                	jne    101923 <mem_check+0x3fd>
  1018ff:	c7 44 24 0c ae c5 10 	movl   $0x10c5ae,0xc(%esp)
  101906:	00 
  101907:	c7 44 24 08 0f c4 10 	movl   $0x10c40f,0x8(%esp)
  10190e:	00 
  10190f:	c7 44 24 04 d5 01 00 	movl   $0x1d5,0x4(%esp)
  101916:	00 
  101917:	c7 04 24 24 c4 10 00 	movl   $0x10c424,(%esp)
  10191e:	e8 15 f0 ff ff       	call   100938 <debug_panic>
  101923:	83 7d ec 00          	cmpl   $0x0,0xffffffec(%ebp)
  101927:	74 08                	je     101931 <mem_check+0x40b>
  101929:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  10192c:	3b 45 e8             	cmp    0xffffffe8(%ebp),%eax
  10192f:	75 24                	jne    101955 <mem_check+0x42f>
  101931:	c7 44 24 0c b2 c5 10 	movl   $0x10c5b2,0xc(%esp)
  101938:	00 
  101939:	c7 44 24 08 0f c4 10 	movl   $0x10c40f,0x8(%esp)
  101940:	00 
  101941:	c7 44 24 04 d6 01 00 	movl   $0x1d6,0x4(%esp)
  101948:	00 
  101949:	c7 04 24 24 c4 10 00 	movl   $0x10c424,(%esp)
  101950:	e8 e3 ef ff ff       	call   100938 <debug_panic>
  101955:	83 7d f0 00          	cmpl   $0x0,0xfffffff0(%ebp)
  101959:	74 10                	je     10196b <mem_check+0x445>
  10195b:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  10195e:	3b 45 ec             	cmp    0xffffffec(%ebp),%eax
  101961:	74 08                	je     10196b <mem_check+0x445>
  101963:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  101966:	3b 45 e8             	cmp    0xffffffe8(%ebp),%eax
  101969:	75 24                	jne    10198f <mem_check+0x469>
  10196b:	c7 44 24 0c c4 c5 10 	movl   $0x10c5c4,0xc(%esp)
  101972:	00 
  101973:	c7 44 24 08 0f c4 10 	movl   $0x10c40f,0x8(%esp)
  10197a:	00 
  10197b:	c7 44 24 04 d7 01 00 	movl   $0x1d7,0x4(%esp)
  101982:	00 
  101983:	c7 04 24 24 c4 10 00 	movl   $0x10c424,(%esp)
  10198a:	e8 a9 ef ff ff       	call   100938 <debug_panic>
  10198f:	e8 d1 fa ff ff       	call   101465 <mem_alloc>
  101994:	85 c0                	test   %eax,%eax
  101996:	74 24                	je     1019bc <mem_check+0x496>
  101998:	c7 44 24 0c 5a c6 10 	movl   $0x10c65a,0xc(%esp)
  10199f:	00 
  1019a0:	c7 44 24 08 0f c4 10 	movl   $0x10c40f,0x8(%esp)
  1019a7:	00 
  1019a8:	c7 44 24 04 d8 01 00 	movl   $0x1d8,0x4(%esp)
  1019af:	00 
  1019b0:	c7 04 24 24 c4 10 00 	movl   $0x10c424,(%esp)
  1019b7:	e8 7c ef ff ff       	call   100938 <debug_panic>
  1019bc:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  1019bf:	a3 80 1d 18 00       	mov    %eax,0x181d80
  1019c4:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  1019c7:	89 04 24             	mov    %eax,(%esp)
  1019ca:	e8 da fa ff ff       	call   1014a9 <mem_free>
  1019cf:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  1019d2:	89 04 24             	mov    %eax,(%esp)
  1019d5:	e8 cf fa ff ff       	call   1014a9 <mem_free>
  1019da:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  1019dd:	89 04 24             	mov    %eax,(%esp)
  1019e0:	e8 c4 fa ff ff       	call   1014a9 <mem_free>
  1019e5:	c7 04 24 6b c6 10 00 	movl   $0x10c66b,(%esp)
  1019ec:	e8 7c 9e 00 00       	call   10b86d <cprintf>
  1019f1:	c9                   	leave  
  1019f2:	c3                   	ret    
  1019f3:	90                   	nop    

001019f4 <cpu_init>:
};


void cpu_init()
{
  1019f4:	55                   	push   %ebp
  1019f5:	89 e5                	mov    %esp,%ebp
  1019f7:	53                   	push   %ebx
  1019f8:	83 ec 14             	sub    $0x14,%esp
	cpu *c = cpu_cur();
  1019fb:	e8 23 01 00 00       	call   101b23 <cpu_cur>
  101a00:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)


	// Setup the TSS for this cpu so that we get the right stack
	// when we trap into the kernel from user mode.
	c->tss.ts_esp0 = (uint32_t) c->kstackhi;
  101a03:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  101a06:	05 00 10 00 00       	add    $0x1000,%eax
  101a0b:	89 c2                	mov    %eax,%edx
  101a0d:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  101a10:	89 50 3c             	mov    %edx,0x3c(%eax)
	c->tss.ts_ss0 = CPU_GDT_KDATA;
  101a13:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  101a16:	66 c7 40 40 10 00    	movw   $0x10,0x40(%eax)

	// Initialize the non-constant part of the cpu's GDT:
	// the TSS descriptor is different for each cpu.
	c->gdt[CPU_GDT_TSS >> 3] = SEGDESC16(0, STS_T32A, (uint32_t) (&c->tss),
  101a1c:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  101a1f:	83 c0 38             	add    $0x38,%eax
  101a22:	89 c2                	mov    %eax,%edx
  101a24:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  101a27:	83 c0 38             	add    $0x38,%eax
  101a2a:	c1 e8 10             	shr    $0x10,%eax
  101a2d:	89 c1                	mov    %eax,%ecx
  101a2f:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  101a32:	83 c0 38             	add    $0x38,%eax
  101a35:	c1 e8 18             	shr    $0x18,%eax
  101a38:	89 c3                	mov    %eax,%ebx
  101a3a:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  101a3d:	66 c7 40 30 67 00    	movw   $0x67,0x30(%eax)
  101a43:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  101a46:	66 89 50 32          	mov    %dx,0x32(%eax)
  101a4a:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  101a4d:	88 48 34             	mov    %cl,0x34(%eax)
  101a50:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  101a53:	0f b6 42 35          	movzbl 0x35(%edx),%eax
  101a57:	83 e0 f0             	and    $0xfffffff0,%eax
  101a5a:	83 c8 09             	or     $0x9,%eax
  101a5d:	88 42 35             	mov    %al,0x35(%edx)
  101a60:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  101a63:	0f b6 42 35          	movzbl 0x35(%edx),%eax
  101a67:	83 e0 ef             	and    $0xffffffef,%eax
  101a6a:	88 42 35             	mov    %al,0x35(%edx)
  101a6d:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  101a70:	0f b6 42 35          	movzbl 0x35(%edx),%eax
  101a74:	83 e0 9f             	and    $0xffffff9f,%eax
  101a77:	88 42 35             	mov    %al,0x35(%edx)
  101a7a:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  101a7d:	0f b6 42 35          	movzbl 0x35(%edx),%eax
  101a81:	83 c8 80             	or     $0xffffff80,%eax
  101a84:	88 42 35             	mov    %al,0x35(%edx)
  101a87:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  101a8a:	0f b6 42 36          	movzbl 0x36(%edx),%eax
  101a8e:	83 e0 f0             	and    $0xfffffff0,%eax
  101a91:	88 42 36             	mov    %al,0x36(%edx)
  101a94:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  101a97:	0f b6 42 36          	movzbl 0x36(%edx),%eax
  101a9b:	83 e0 ef             	and    $0xffffffef,%eax
  101a9e:	88 42 36             	mov    %al,0x36(%edx)
  101aa1:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  101aa4:	0f b6 42 36          	movzbl 0x36(%edx),%eax
  101aa8:	83 e0 df             	and    $0xffffffdf,%eax
  101aab:	88 42 36             	mov    %al,0x36(%edx)
  101aae:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  101ab1:	0f b6 42 36          	movzbl 0x36(%edx),%eax
  101ab5:	83 c8 40             	or     $0x40,%eax
  101ab8:	88 42 36             	mov    %al,0x36(%edx)
  101abb:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  101abe:	0f b6 42 36          	movzbl 0x36(%edx),%eax
  101ac2:	83 e0 7f             	and    $0x7f,%eax
  101ac5:	88 42 36             	mov    %al,0x36(%edx)
  101ac8:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  101acb:	88 58 37             	mov    %bl,0x37(%eax)
					sizeof(taskstate)-1, 0);

	// Load the GDT
	struct pseudodesc gdt_pd = {
		sizeof(c->gdt) - 1, (uint32_t) c->gdt };
  101ace:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  101ad1:	66 c7 45 ee 37 00    	movw   $0x37,0xffffffee(%ebp)
  101ad7:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
	asm volatile("lgdt %0" : : "m" (gdt_pd));
  101ada:	0f 01 55 ee          	lgdtl  0xffffffee(%ebp)

	// Reload all segment registers.
	asm volatile("movw %%ax,%%gs" :: "a" (CPU_GDT_UDATA|3));
  101ade:	b8 23 00 00 00       	mov    $0x23,%eax
  101ae3:	8e e8                	movl   %eax,%gs
	asm volatile("movw %%ax,%%fs" :: "a" (CPU_GDT_UDATA|3));
  101ae5:	b8 23 00 00 00       	mov    $0x23,%eax
  101aea:	8e e0                	movl   %eax,%fs
	asm volatile("movw %%ax,%%es" :: "a" (CPU_GDT_KDATA));
  101aec:	b8 10 00 00 00       	mov    $0x10,%eax
  101af1:	8e c0                	movl   %eax,%es
	asm volatile("movw %%ax,%%ds" :: "a" (CPU_GDT_KDATA));
  101af3:	b8 10 00 00 00       	mov    $0x10,%eax
  101af8:	8e d8                	movl   %eax,%ds
	asm volatile("movw %%ax,%%ss" :: "a" (CPU_GDT_KDATA));
  101afa:	b8 10 00 00 00       	mov    $0x10,%eax
  101aff:	8e d0                	movl   %eax,%ss
	asm volatile("ljmp %0,$1f\n 1:\n" :: "i" (CPU_GDT_KCODE)); // reload CS
  101b01:	ea 08 1b 10 00 08 00 	ljmp   $0x8,$0x101b08

	// We don't need an LDT.
	asm volatile("lldt %%ax" :: "a" (0));
  101b08:	b8 00 00 00 00       	mov    $0x0,%eax
  101b0d:	0f 00 d0             	lldt   %ax
  101b10:	66 c7 45 fa 30 00    	movw   $0x30,0xfffffffa(%ebp)

static gcc_inline void
ltr(uint16_t sel)
{
	__asm __volatile("ltr %0" : : "r" (sel));
  101b16:	0f b7 45 fa          	movzwl 0xfffffffa(%ebp),%eax
  101b1a:	0f 00 d8             	ltr    %ax

	// Load the TSS (from the GDT)
	ltr(CPU_GDT_TSS);
}
  101b1d:	83 c4 14             	add    $0x14,%esp
  101b20:	5b                   	pop    %ebx
  101b21:	5d                   	pop    %ebp
  101b22:	c3                   	ret    

00101b23 <cpu_cur>:

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  101b23:	55                   	push   %ebp
  101b24:	89 e5                	mov    %esp,%ebp
  101b26:	83 ec 28             	sub    $0x28,%esp
static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  101b29:	89 65 fc             	mov    %esp,0xfffffffc(%ebp)
        return esp;
  101b2c:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  101b2f:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  101b32:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  101b35:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  101b3a:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	assert(c->magic == CPU_MAGIC);
  101b3d:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  101b40:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  101b46:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  101b4b:	74 24                	je     101b71 <cpu_cur+0x4e>
  101b4d:	c7 44 24 0c 83 c6 10 	movl   $0x10c683,0xc(%esp)
  101b54:	00 
  101b55:	c7 44 24 08 99 c6 10 	movl   $0x10c699,0x8(%esp)
  101b5c:	00 
  101b5d:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  101b64:	00 
  101b65:	c7 04 24 ae c6 10 00 	movl   $0x10c6ae,(%esp)
  101b6c:	e8 c7 ed ff ff       	call   100938 <debug_panic>
	return c;
  101b71:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
}
  101b74:	c9                   	leave  
  101b75:	c3                   	ret    

00101b76 <cpu_alloc>:

// Allocate an additional cpu struct representing a non-bootstrap processor.
cpu *
cpu_alloc(void)
{
  101b76:	55                   	push   %ebp
  101b77:	89 e5                	mov    %esp,%ebp
  101b79:	83 ec 28             	sub    $0x28,%esp
	// Pointer to the cpu.next pointer of the last CPU on the list,
	// for chaining on new CPUs in cpu_alloc().  Note: static.
	static cpu **cpu_tail = &cpu_boot.next;

	pageinfo *pi = mem_alloc();
  101b7c:	e8 e4 f8 ff ff       	call   101465 <mem_alloc>
  101b81:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
	assert(pi != 0);	// shouldn't be out of memory just yet!
  101b84:	83 7d f8 00          	cmpl   $0x0,0xfffffff8(%ebp)
  101b88:	75 24                	jne    101bae <cpu_alloc+0x38>
  101b8a:	c7 44 24 0c bb c6 10 	movl   $0x10c6bb,0xc(%esp)
  101b91:	00 
  101b92:	c7 44 24 08 99 c6 10 	movl   $0x10c699,0x8(%esp)
  101b99:	00 
  101b9a:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
  101ba1:	00 
  101ba2:	c7 04 24 c3 c6 10 00 	movl   $0x10c6c3,(%esp)
  101ba9:	e8 8a ed ff ff       	call   100938 <debug_panic>

	cpu *c = (cpu*) mem_pi2ptr(pi);
  101bae:	8b 55 f8             	mov    0xfffffff8(%ebp),%edx
  101bb1:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  101bb6:	89 d1                	mov    %edx,%ecx
  101bb8:	29 c1                	sub    %eax,%ecx
  101bba:	89 c8                	mov    %ecx,%eax
  101bbc:	c1 e0 09             	shl    $0x9,%eax
  101bbf:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)

	// Clear the whole page for good measure: cpu struct and kernel stack
	memset(c, 0, PAGESIZE);
  101bc2:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  101bc9:	00 
  101bca:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  101bd1:	00 
  101bd2:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  101bd5:	89 04 24             	mov    %eax,(%esp)
  101bd8:	e8 14 a0 00 00       	call   10bbf1 <memset>

	// Now we need to initialize the new cpu struct
	// just to the same degree that cpu_boot was statically initialized.
	// The rest will be filled in by the CPU itself
	// when it starts up and calls cpu_init().

	// Initialize the new cpu's GDT by copying from the cpu_boot.
	// The TSS descriptor will be filled in later by cpu_init().
	assert(sizeof(c->gdt) == sizeof(segdesc) * CPU_GDT_NDESC);
	memmove(c->gdt, cpu_boot.gdt, sizeof(c->gdt));
  101bdd:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  101be0:	c7 44 24 08 38 00 00 	movl   $0x38,0x8(%esp)
  101be7:	00 
  101be8:	c7 44 24 04 00 f0 10 	movl   $0x10f000,0x4(%esp)
  101bef:	00 
  101bf0:	89 04 24             	mov    %eax,(%esp)
  101bf3:	e8 72 a0 00 00       	call   10bc6a <memmove>

	// Magic verification tag for stack overflow/cpu corruption checking
	c->magic = CPU_MAGIC;
  101bf8:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  101bfb:	c7 80 b8 00 00 00 32 	movl   $0x98765432,0xb8(%eax)
  101c02:	54 76 98 

	// Chain the new CPU onto the tail of the list.
	*cpu_tail = c;
  101c05:	8b 15 00 00 11 00    	mov    0x110000,%edx
  101c0b:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  101c0e:	89 02                	mov    %eax,(%edx)
	cpu_tail = &c->next;
  101c10:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  101c13:	05 a8 00 00 00       	add    $0xa8,%eax
  101c18:	a3 00 00 11 00       	mov    %eax,0x110000

	return c;
  101c1d:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
}
  101c20:	c9                   	leave  
  101c21:	c3                   	ret    

00101c22 <cpu_bootothers>:

void
cpu_bootothers(void)
{
  101c22:	55                   	push   %ebp
  101c23:	89 e5                	mov    %esp,%ebp
  101c25:	83 ec 18             	sub    $0x18,%esp
	extern uint8_t _binary_obj_boot_bootother_start[],
			_binary_obj_boot_bootother_size[];

	if (!cpu_onboot()) {
  101c28:	e8 9e 00 00 00       	call   101ccb <cpu_onboot>
  101c2d:	85 c0                	test   %eax,%eax
  101c2f:	75 1c                	jne    101c4d <cpu_bootothers+0x2b>
		// Just inform the boot cpu we've booted.
		xchg(&cpu_cur()->booted, 1);
  101c31:	e8 ed fe ff ff       	call   101b23 <cpu_cur>
  101c36:	05 b0 00 00 00       	add    $0xb0,%eax
  101c3b:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  101c42:	00 
  101c43:	89 04 24             	mov    %eax,(%esp)
  101c46:	e8 98 00 00 00       	call   101ce3 <xchg>
		return;
  101c4b:	eb 7c                	jmp    101cc9 <cpu_bootothers+0xa7>
	}

	// Write bootstrap code to unused memory at 0x1000.
	uint8_t *code = (uint8_t*)0x1000;
  101c4d:	c7 45 f4 00 10 00 00 	movl   $0x1000,0xfffffff4(%ebp)
	//memmove(code, _binary_obj_boot_bootother_start,
	//	(uint32_t)_binary_obj_boot_bootother_size);

	cpu *c;
	for(c = &cpu_boot; c; c = c->next){
  101c54:	c7 45 f8 00 f0 10 00 	movl   $0x10f000,0xfffffff8(%ebp)
  101c5b:	eb 66                	jmp    101cc3 <cpu_bootothers+0xa1>
		if(c == cpu_cur())  // We''ve started already.
  101c5d:	e8 c1 fe ff ff       	call   101b23 <cpu_cur>
  101c62:	3b 45 f8             	cmp    0xfffffff8(%ebp),%eax
  101c65:	74 50                	je     101cb7 <cpu_bootothers+0x95>
			continue;

		// Fill in %esp, %eip and start code on cpu.
		*(void**)(code-4) = c->kstackhi;
  101c67:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  101c6a:	83 e8 04             	sub    $0x4,%eax
  101c6d:	89 c2                	mov    %eax,%edx
  101c6f:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  101c72:	05 00 10 00 00       	add    $0x1000,%eax
  101c77:	89 02                	mov    %eax,(%edx)
		*(void**)(code-8) = init;
  101c79:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  101c7c:	83 e8 08             	sub    $0x8,%eax
  101c7f:	c7 00 28 00 10 00    	movl   $0x100028,(%eax)
		uint8_t *bootother = (uint8_t*)0x1010;
  101c85:	c7 45 fc 10 10 00 00 	movl   $0x1010,0xfffffffc(%ebp)
		lapic_startcpu(c->id, (uint32_t)code);
  101c8c:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  101c8f:	89 c2                	mov    %eax,%edx
  101c91:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  101c94:	0f b6 80 ac 00 00 00 	movzbl 0xac(%eax),%eax
  101c9b:	0f b6 c0             	movzbl %al,%eax
  101c9e:	89 54 24 04          	mov    %edx,0x4(%esp)
  101ca2:	89 04 24             	mov    %eax,(%esp)
  101ca5:	e8 64 91 00 00       	call   10ae0e <lapic_startcpu>
		//lapic_startcpu(c->id, (uint32_t)bootother);

		// Wait for cpu to get through bootstrap.
		while(c->booted == 0)
  101caa:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  101cad:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
  101cb3:	85 c0                	test   %eax,%eax
  101cb5:	74 f3                	je     101caa <cpu_bootothers+0x88>
  101cb7:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  101cba:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
  101cc0:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  101cc3:	83 7d f8 00          	cmpl   $0x0,0xfffffff8(%ebp)
  101cc7:	75 94                	jne    101c5d <cpu_bootothers+0x3b>
			;
	}
}
  101cc9:	c9                   	leave  
  101cca:	c3                   	ret    

00101ccb <cpu_onboot>:
}

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  101ccb:	55                   	push   %ebp
  101ccc:	89 e5                	mov    %esp,%ebp
  101cce:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  101cd1:	e8 4d fe ff ff       	call   101b23 <cpu_cur>
  101cd6:	3d 00 f0 10 00       	cmp    $0x10f000,%eax
  101cdb:	0f 94 c0             	sete   %al
  101cde:	0f b6 c0             	movzbl %al,%eax
}
  101ce1:	c9                   	leave  
  101ce2:	c3                   	ret    

00101ce3 <xchg>:

// Atomically set *addr to newval and return the old value of *addr.
static inline uint32_t
xchg(volatile uint32_t *addr, uint32_t newval)
{
  101ce3:	55                   	push   %ebp
  101ce4:	89 e5                	mov    %esp,%ebp
  101ce6:	53                   	push   %ebx
  101ce7:	83 ec 14             	sub    $0x14,%esp
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
  101cea:	8b 4d 08             	mov    0x8(%ebp),%ecx
  101ced:	8b 55 0c             	mov    0xc(%ebp),%edx
  101cf0:	8b 45 08             	mov    0x8(%ebp),%eax
  101cf3:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  101cf6:	89 d0                	mov    %edx,%eax
  101cf8:	8b 5d e8             	mov    0xffffffe8(%ebp),%ebx
  101cfb:	f0 87 01             	lock xchg %eax,(%ecx)
  101cfe:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  101d01:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  101d04:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
	       "+m" (*addr), "=a" (result) :
	       "1" (newval) :
	       "cc");
	return result;
  101d07:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
}
  101d0a:	83 c4 14             	add    $0x14,%esp
  101d0d:	5b                   	pop    %ebx
  101d0e:	5d                   	pop    %ebp
  101d0f:	c3                   	ret    

00101d10 <trap_init_idt>:
  101d10:	55                   	push   %ebp
  101d11:	89 e5                	mov    %esp,%ebp
  101d13:	83 ec 10             	sub    $0x10,%esp
  101d16:	c7 45 fc 00 00 00 00 	movl   $0x0,0xfffffffc(%ebp)
  101d1d:	e9 b5 00 00 00       	jmp    101dd7 <trap_init_idt+0xc7>
  101d22:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  101d25:	b8 34 3a 10 00       	mov    $0x103a34,%eax
  101d2a:	66 89 04 d5 20 d2 17 	mov    %ax,0x17d220(,%edx,8)
  101d31:	00 
  101d32:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  101d35:	66 c7 04 c5 22 d2 17 	movw   $0x8,0x17d222(,%eax,8)
  101d3c:	00 08 00 
  101d3f:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  101d42:	0f b6 04 d5 24 d2 17 	movzbl 0x17d224(,%edx,8),%eax
  101d49:	00 
  101d4a:	83 e0 e0             	and    $0xffffffe0,%eax
  101d4d:	88 04 d5 24 d2 17 00 	mov    %al,0x17d224(,%edx,8)
  101d54:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  101d57:	0f b6 04 d5 24 d2 17 	movzbl 0x17d224(,%edx,8),%eax
  101d5e:	00 
  101d5f:	83 e0 1f             	and    $0x1f,%eax
  101d62:	88 04 d5 24 d2 17 00 	mov    %al,0x17d224(,%edx,8)
  101d69:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  101d6c:	0f b6 04 d5 25 d2 17 	movzbl 0x17d225(,%edx,8),%eax
  101d73:	00 
  101d74:	83 e0 f0             	and    $0xfffffff0,%eax
  101d77:	83 c8 0e             	or     $0xe,%eax
  101d7a:	88 04 d5 25 d2 17 00 	mov    %al,0x17d225(,%edx,8)
  101d81:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  101d84:	0f b6 04 d5 25 d2 17 	movzbl 0x17d225(,%edx,8),%eax
  101d8b:	00 
  101d8c:	83 e0 ef             	and    $0xffffffef,%eax
  101d8f:	88 04 d5 25 d2 17 00 	mov    %al,0x17d225(,%edx,8)
  101d96:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  101d99:	0f b6 04 d5 25 d2 17 	movzbl 0x17d225(,%edx,8),%eax
  101da0:	00 
  101da1:	83 e0 9f             	and    $0xffffff9f,%eax
  101da4:	88 04 d5 25 d2 17 00 	mov    %al,0x17d225(,%edx,8)
  101dab:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  101dae:	0f b6 04 d5 25 d2 17 	movzbl 0x17d225(,%edx,8),%eax
  101db5:	00 
  101db6:	83 c8 80             	or     $0xffffff80,%eax
  101db9:	88 04 d5 25 d2 17 00 	mov    %al,0x17d225(,%edx,8)
  101dc0:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  101dc3:	b8 34 3a 10 00       	mov    $0x103a34,%eax
  101dc8:	c1 e8 10             	shr    $0x10,%eax
  101dcb:	66 89 04 d5 26 d2 17 	mov    %ax,0x17d226(,%edx,8)
  101dd2:	00 
  101dd3:	83 45 fc 01          	addl   $0x1,0xfffffffc(%ebp)
  101dd7:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  101dda:	3d ff 00 00 00       	cmp    $0xff,%eax
  101ddf:	0f 86 3d ff ff ff    	jbe    101d22 <trap_init_idt+0x12>
  101de5:	b8 d0 38 10 00       	mov    $0x1038d0,%eax
  101dea:	66 a3 20 d2 17 00    	mov    %ax,0x17d220
  101df0:	66 c7 05 22 d2 17 00 	movw   $0x8,0x17d222
  101df7:	08 00 
  101df9:	0f b6 05 24 d2 17 00 	movzbl 0x17d224,%eax
  101e00:	83 e0 e0             	and    $0xffffffe0,%eax
  101e03:	a2 24 d2 17 00       	mov    %al,0x17d224
  101e08:	0f b6 05 24 d2 17 00 	movzbl 0x17d224,%eax
  101e0f:	83 e0 1f             	and    $0x1f,%eax
  101e12:	a2 24 d2 17 00       	mov    %al,0x17d224
  101e17:	0f b6 05 25 d2 17 00 	movzbl 0x17d225,%eax
  101e1e:	83 e0 f0             	and    $0xfffffff0,%eax
  101e21:	83 c8 0e             	or     $0xe,%eax
  101e24:	a2 25 d2 17 00       	mov    %al,0x17d225
  101e29:	0f b6 05 25 d2 17 00 	movzbl 0x17d225,%eax
  101e30:	83 e0 ef             	and    $0xffffffef,%eax
  101e33:	a2 25 d2 17 00       	mov    %al,0x17d225
  101e38:	0f b6 05 25 d2 17 00 	movzbl 0x17d225,%eax
  101e3f:	83 e0 9f             	and    $0xffffff9f,%eax
  101e42:	a2 25 d2 17 00       	mov    %al,0x17d225
  101e47:	0f b6 05 25 d2 17 00 	movzbl 0x17d225,%eax
  101e4e:	83 c8 80             	or     $0xffffff80,%eax
  101e51:	a2 25 d2 17 00       	mov    %al,0x17d225
  101e56:	b8 d0 38 10 00       	mov    $0x1038d0,%eax
  101e5b:	c1 e8 10             	shr    $0x10,%eax
  101e5e:	66 a3 26 d2 17 00    	mov    %ax,0x17d226
  101e64:	b8 da 38 10 00       	mov    $0x1038da,%eax
  101e69:	66 a3 28 d2 17 00    	mov    %ax,0x17d228
  101e6f:	66 c7 05 2a d2 17 00 	movw   $0x8,0x17d22a
  101e76:	08 00 
  101e78:	0f b6 05 2c d2 17 00 	movzbl 0x17d22c,%eax
  101e7f:	83 e0 e0             	and    $0xffffffe0,%eax
  101e82:	a2 2c d2 17 00       	mov    %al,0x17d22c
  101e87:	0f b6 05 2c d2 17 00 	movzbl 0x17d22c,%eax
  101e8e:	83 e0 1f             	and    $0x1f,%eax
  101e91:	a2 2c d2 17 00       	mov    %al,0x17d22c
  101e96:	0f b6 05 2d d2 17 00 	movzbl 0x17d22d,%eax
  101e9d:	83 e0 f0             	and    $0xfffffff0,%eax
  101ea0:	83 c8 0e             	or     $0xe,%eax
  101ea3:	a2 2d d2 17 00       	mov    %al,0x17d22d
  101ea8:	0f b6 05 2d d2 17 00 	movzbl 0x17d22d,%eax
  101eaf:	83 e0 ef             	and    $0xffffffef,%eax
  101eb2:	a2 2d d2 17 00       	mov    %al,0x17d22d
  101eb7:	0f b6 05 2d d2 17 00 	movzbl 0x17d22d,%eax
  101ebe:	83 e0 9f             	and    $0xffffff9f,%eax
  101ec1:	a2 2d d2 17 00       	mov    %al,0x17d22d
  101ec6:	0f b6 05 2d d2 17 00 	movzbl 0x17d22d,%eax
  101ecd:	83 c8 80             	or     $0xffffff80,%eax
  101ed0:	a2 2d d2 17 00       	mov    %al,0x17d22d
  101ed5:	b8 da 38 10 00       	mov    $0x1038da,%eax
  101eda:	c1 e8 10             	shr    $0x10,%eax
  101edd:	66 a3 2e d2 17 00    	mov    %ax,0x17d22e
  101ee3:	b8 e4 38 10 00       	mov    $0x1038e4,%eax
  101ee8:	66 a3 30 d2 17 00    	mov    %ax,0x17d230
  101eee:	66 c7 05 32 d2 17 00 	movw   $0x8,0x17d232
  101ef5:	08 00 
  101ef7:	0f b6 05 34 d2 17 00 	movzbl 0x17d234,%eax
  101efe:	83 e0 e0             	and    $0xffffffe0,%eax
  101f01:	a2 34 d2 17 00       	mov    %al,0x17d234
  101f06:	0f b6 05 34 d2 17 00 	movzbl 0x17d234,%eax
  101f0d:	83 e0 1f             	and    $0x1f,%eax
  101f10:	a2 34 d2 17 00       	mov    %al,0x17d234
  101f15:	0f b6 05 35 d2 17 00 	movzbl 0x17d235,%eax
  101f1c:	83 e0 f0             	and    $0xfffffff0,%eax
  101f1f:	83 c8 0e             	or     $0xe,%eax
  101f22:	a2 35 d2 17 00       	mov    %al,0x17d235
  101f27:	0f b6 05 35 d2 17 00 	movzbl 0x17d235,%eax
  101f2e:	83 e0 ef             	and    $0xffffffef,%eax
  101f31:	a2 35 d2 17 00       	mov    %al,0x17d235
  101f36:	0f b6 05 35 d2 17 00 	movzbl 0x17d235,%eax
  101f3d:	83 e0 9f             	and    $0xffffff9f,%eax
  101f40:	a2 35 d2 17 00       	mov    %al,0x17d235
  101f45:	0f b6 05 35 d2 17 00 	movzbl 0x17d235,%eax
  101f4c:	83 c8 80             	or     $0xffffff80,%eax
  101f4f:	a2 35 d2 17 00       	mov    %al,0x17d235
  101f54:	b8 e4 38 10 00       	mov    $0x1038e4,%eax
  101f59:	c1 e8 10             	shr    $0x10,%eax
  101f5c:	66 a3 36 d2 17 00    	mov    %ax,0x17d236
  101f62:	b8 ee 38 10 00       	mov    $0x1038ee,%eax
  101f67:	66 a3 38 d2 17 00    	mov    %ax,0x17d238
  101f6d:	66 c7 05 3a d2 17 00 	movw   $0x8,0x17d23a
  101f74:	08 00 
  101f76:	0f b6 05 3c d2 17 00 	movzbl 0x17d23c,%eax
  101f7d:	83 e0 e0             	and    $0xffffffe0,%eax
  101f80:	a2 3c d2 17 00       	mov    %al,0x17d23c
  101f85:	0f b6 05 3c d2 17 00 	movzbl 0x17d23c,%eax
  101f8c:	83 e0 1f             	and    $0x1f,%eax
  101f8f:	a2 3c d2 17 00       	mov    %al,0x17d23c
  101f94:	0f b6 05 3d d2 17 00 	movzbl 0x17d23d,%eax
  101f9b:	83 e0 f0             	and    $0xfffffff0,%eax
  101f9e:	83 c8 0e             	or     $0xe,%eax
  101fa1:	a2 3d d2 17 00       	mov    %al,0x17d23d
  101fa6:	0f b6 05 3d d2 17 00 	movzbl 0x17d23d,%eax
  101fad:	83 e0 ef             	and    $0xffffffef,%eax
  101fb0:	a2 3d d2 17 00       	mov    %al,0x17d23d
  101fb5:	0f b6 05 3d d2 17 00 	movzbl 0x17d23d,%eax
  101fbc:	83 c8 60             	or     $0x60,%eax
  101fbf:	a2 3d d2 17 00       	mov    %al,0x17d23d
  101fc4:	0f b6 05 3d d2 17 00 	movzbl 0x17d23d,%eax
  101fcb:	83 c8 80             	or     $0xffffff80,%eax
  101fce:	a2 3d d2 17 00       	mov    %al,0x17d23d
  101fd3:	b8 ee 38 10 00       	mov    $0x1038ee,%eax
  101fd8:	c1 e8 10             	shr    $0x10,%eax
  101fdb:	66 a3 3e d2 17 00    	mov    %ax,0x17d23e
  101fe1:	b8 f8 38 10 00       	mov    $0x1038f8,%eax
  101fe6:	66 a3 40 d2 17 00    	mov    %ax,0x17d240
  101fec:	66 c7 05 42 d2 17 00 	movw   $0x8,0x17d242
  101ff3:	08 00 
  101ff5:	0f b6 05 44 d2 17 00 	movzbl 0x17d244,%eax
  101ffc:	83 e0 e0             	and    $0xffffffe0,%eax
  101fff:	a2 44 d2 17 00       	mov    %al,0x17d244
  102004:	0f b6 05 44 d2 17 00 	movzbl 0x17d244,%eax
  10200b:	83 e0 1f             	and    $0x1f,%eax
  10200e:	a2 44 d2 17 00       	mov    %al,0x17d244
  102013:	0f b6 05 45 d2 17 00 	movzbl 0x17d245,%eax
  10201a:	83 e0 f0             	and    $0xfffffff0,%eax
  10201d:	83 c8 0e             	or     $0xe,%eax
  102020:	a2 45 d2 17 00       	mov    %al,0x17d245
  102025:	0f b6 05 45 d2 17 00 	movzbl 0x17d245,%eax
  10202c:	83 e0 ef             	and    $0xffffffef,%eax
  10202f:	a2 45 d2 17 00       	mov    %al,0x17d245
  102034:	0f b6 05 45 d2 17 00 	movzbl 0x17d245,%eax
  10203b:	83 c8 60             	or     $0x60,%eax
  10203e:	a2 45 d2 17 00       	mov    %al,0x17d245
  102043:	0f b6 05 45 d2 17 00 	movzbl 0x17d245,%eax
  10204a:	83 c8 80             	or     $0xffffff80,%eax
  10204d:	a2 45 d2 17 00       	mov    %al,0x17d245
  102052:	b8 f8 38 10 00       	mov    $0x1038f8,%eax
  102057:	c1 e8 10             	shr    $0x10,%eax
  10205a:	66 a3 46 d2 17 00    	mov    %ax,0x17d246
  102060:	b8 02 39 10 00       	mov    $0x103902,%eax
  102065:	66 a3 48 d2 17 00    	mov    %ax,0x17d248
  10206b:	66 c7 05 4a d2 17 00 	movw   $0x8,0x17d24a
  102072:	08 00 
  102074:	0f b6 05 4c d2 17 00 	movzbl 0x17d24c,%eax
  10207b:	83 e0 e0             	and    $0xffffffe0,%eax
  10207e:	a2 4c d2 17 00       	mov    %al,0x17d24c
  102083:	0f b6 05 4c d2 17 00 	movzbl 0x17d24c,%eax
  10208a:	83 e0 1f             	and    $0x1f,%eax
  10208d:	a2 4c d2 17 00       	mov    %al,0x17d24c
  102092:	0f b6 05 4d d2 17 00 	movzbl 0x17d24d,%eax
  102099:	83 e0 f0             	and    $0xfffffff0,%eax
  10209c:	83 c8 0e             	or     $0xe,%eax
  10209f:	a2 4d d2 17 00       	mov    %al,0x17d24d
  1020a4:	0f b6 05 4d d2 17 00 	movzbl 0x17d24d,%eax
  1020ab:	83 e0 ef             	and    $0xffffffef,%eax
  1020ae:	a2 4d d2 17 00       	mov    %al,0x17d24d
  1020b3:	0f b6 05 4d d2 17 00 	movzbl 0x17d24d,%eax
  1020ba:	83 e0 9f             	and    $0xffffff9f,%eax
  1020bd:	a2 4d d2 17 00       	mov    %al,0x17d24d
  1020c2:	0f b6 05 4d d2 17 00 	movzbl 0x17d24d,%eax
  1020c9:	83 c8 80             	or     $0xffffff80,%eax
  1020cc:	a2 4d d2 17 00       	mov    %al,0x17d24d
  1020d1:	b8 02 39 10 00       	mov    $0x103902,%eax
  1020d6:	c1 e8 10             	shr    $0x10,%eax
  1020d9:	66 a3 4e d2 17 00    	mov    %ax,0x17d24e
  1020df:	b8 0c 39 10 00       	mov    $0x10390c,%eax
  1020e4:	66 a3 50 d2 17 00    	mov    %ax,0x17d250
  1020ea:	66 c7 05 52 d2 17 00 	movw   $0x8,0x17d252
  1020f1:	08 00 
  1020f3:	0f b6 05 54 d2 17 00 	movzbl 0x17d254,%eax
  1020fa:	83 e0 e0             	and    $0xffffffe0,%eax
  1020fd:	a2 54 d2 17 00       	mov    %al,0x17d254
  102102:	0f b6 05 54 d2 17 00 	movzbl 0x17d254,%eax
  102109:	83 e0 1f             	and    $0x1f,%eax
  10210c:	a2 54 d2 17 00       	mov    %al,0x17d254
  102111:	0f b6 05 55 d2 17 00 	movzbl 0x17d255,%eax
  102118:	83 e0 f0             	and    $0xfffffff0,%eax
  10211b:	83 c8 0e             	or     $0xe,%eax
  10211e:	a2 55 d2 17 00       	mov    %al,0x17d255
  102123:	0f b6 05 55 d2 17 00 	movzbl 0x17d255,%eax
  10212a:	83 e0 ef             	and    $0xffffffef,%eax
  10212d:	a2 55 d2 17 00       	mov    %al,0x17d255
  102132:	0f b6 05 55 d2 17 00 	movzbl 0x17d255,%eax
  102139:	83 e0 9f             	and    $0xffffff9f,%eax
  10213c:	a2 55 d2 17 00       	mov    %al,0x17d255
  102141:	0f b6 05 55 d2 17 00 	movzbl 0x17d255,%eax
  102148:	83 c8 80             	or     $0xffffff80,%eax
  10214b:	a2 55 d2 17 00       	mov    %al,0x17d255
  102150:	b8 0c 39 10 00       	mov    $0x10390c,%eax
  102155:	c1 e8 10             	shr    $0x10,%eax
  102158:	66 a3 56 d2 17 00    	mov    %ax,0x17d256
  10215e:	b8 16 39 10 00       	mov    $0x103916,%eax
  102163:	66 a3 58 d2 17 00    	mov    %ax,0x17d258
  102169:	66 c7 05 5a d2 17 00 	movw   $0x8,0x17d25a
  102170:	08 00 
  102172:	0f b6 05 5c d2 17 00 	movzbl 0x17d25c,%eax
  102179:	83 e0 e0             	and    $0xffffffe0,%eax
  10217c:	a2 5c d2 17 00       	mov    %al,0x17d25c
  102181:	0f b6 05 5c d2 17 00 	movzbl 0x17d25c,%eax
  102188:	83 e0 1f             	and    $0x1f,%eax
  10218b:	a2 5c d2 17 00       	mov    %al,0x17d25c
  102190:	0f b6 05 5d d2 17 00 	movzbl 0x17d25d,%eax
  102197:	83 e0 f0             	and    $0xfffffff0,%eax
  10219a:	83 c8 0e             	or     $0xe,%eax
  10219d:	a2 5d d2 17 00       	mov    %al,0x17d25d
  1021a2:	0f b6 05 5d d2 17 00 	movzbl 0x17d25d,%eax
  1021a9:	83 e0 ef             	and    $0xffffffef,%eax
  1021ac:	a2 5d d2 17 00       	mov    %al,0x17d25d
  1021b1:	0f b6 05 5d d2 17 00 	movzbl 0x17d25d,%eax
  1021b8:	83 e0 9f             	and    $0xffffff9f,%eax
  1021bb:	a2 5d d2 17 00       	mov    %al,0x17d25d
  1021c0:	0f b6 05 5d d2 17 00 	movzbl 0x17d25d,%eax
  1021c7:	83 c8 80             	or     $0xffffff80,%eax
  1021ca:	a2 5d d2 17 00       	mov    %al,0x17d25d
  1021cf:	b8 16 39 10 00       	mov    $0x103916,%eax
  1021d4:	c1 e8 10             	shr    $0x10,%eax
  1021d7:	66 a3 5e d2 17 00    	mov    %ax,0x17d25e
  1021dd:	b8 20 39 10 00       	mov    $0x103920,%eax
  1021e2:	66 a3 60 d2 17 00    	mov    %ax,0x17d260
  1021e8:	66 c7 05 62 d2 17 00 	movw   $0x8,0x17d262
  1021ef:	08 00 
  1021f1:	0f b6 05 64 d2 17 00 	movzbl 0x17d264,%eax
  1021f8:	83 e0 e0             	and    $0xffffffe0,%eax
  1021fb:	a2 64 d2 17 00       	mov    %al,0x17d264
  102200:	0f b6 05 64 d2 17 00 	movzbl 0x17d264,%eax
  102207:	83 e0 1f             	and    $0x1f,%eax
  10220a:	a2 64 d2 17 00       	mov    %al,0x17d264
  10220f:	0f b6 05 65 d2 17 00 	movzbl 0x17d265,%eax
  102216:	83 e0 f0             	and    $0xfffffff0,%eax
  102219:	83 c8 0e             	or     $0xe,%eax
  10221c:	a2 65 d2 17 00       	mov    %al,0x17d265
  102221:	0f b6 05 65 d2 17 00 	movzbl 0x17d265,%eax
  102228:	83 e0 ef             	and    $0xffffffef,%eax
  10222b:	a2 65 d2 17 00       	mov    %al,0x17d265
  102230:	0f b6 05 65 d2 17 00 	movzbl 0x17d265,%eax
  102237:	83 e0 9f             	and    $0xffffff9f,%eax
  10223a:	a2 65 d2 17 00       	mov    %al,0x17d265
  10223f:	0f b6 05 65 d2 17 00 	movzbl 0x17d265,%eax
  102246:	83 c8 80             	or     $0xffffff80,%eax
  102249:	a2 65 d2 17 00       	mov    %al,0x17d265
  10224e:	b8 20 39 10 00       	mov    $0x103920,%eax
  102253:	c1 e8 10             	shr    $0x10,%eax
  102256:	66 a3 66 d2 17 00    	mov    %ax,0x17d266
  10225c:	b8 28 39 10 00       	mov    $0x103928,%eax
  102261:	66 a3 70 d2 17 00    	mov    %ax,0x17d270
  102267:	66 c7 05 72 d2 17 00 	movw   $0x8,0x17d272
  10226e:	08 00 
  102270:	0f b6 05 74 d2 17 00 	movzbl 0x17d274,%eax
  102277:	83 e0 e0             	and    $0xffffffe0,%eax
  10227a:	a2 74 d2 17 00       	mov    %al,0x17d274
  10227f:	0f b6 05 74 d2 17 00 	movzbl 0x17d274,%eax
  102286:	83 e0 1f             	and    $0x1f,%eax
  102289:	a2 74 d2 17 00       	mov    %al,0x17d274
  10228e:	0f b6 05 75 d2 17 00 	movzbl 0x17d275,%eax
  102295:	83 e0 f0             	and    $0xfffffff0,%eax
  102298:	83 c8 0e             	or     $0xe,%eax
  10229b:	a2 75 d2 17 00       	mov    %al,0x17d275
  1022a0:	0f b6 05 75 d2 17 00 	movzbl 0x17d275,%eax
  1022a7:	83 e0 ef             	and    $0xffffffef,%eax
  1022aa:	a2 75 d2 17 00       	mov    %al,0x17d275
  1022af:	0f b6 05 75 d2 17 00 	movzbl 0x17d275,%eax
  1022b6:	83 e0 9f             	and    $0xffffff9f,%eax
  1022b9:	a2 75 d2 17 00       	mov    %al,0x17d275
  1022be:	0f b6 05 75 d2 17 00 	movzbl 0x17d275,%eax
  1022c5:	83 c8 80             	or     $0xffffff80,%eax
  1022c8:	a2 75 d2 17 00       	mov    %al,0x17d275
  1022cd:	b8 28 39 10 00       	mov    $0x103928,%eax
  1022d2:	c1 e8 10             	shr    $0x10,%eax
  1022d5:	66 a3 76 d2 17 00    	mov    %ax,0x17d276
  1022db:	b8 30 39 10 00       	mov    $0x103930,%eax
  1022e0:	66 a3 78 d2 17 00    	mov    %ax,0x17d278
  1022e6:	66 c7 05 7a d2 17 00 	movw   $0x8,0x17d27a
  1022ed:	08 00 
  1022ef:	0f b6 05 7c d2 17 00 	movzbl 0x17d27c,%eax
  1022f6:	83 e0 e0             	and    $0xffffffe0,%eax
  1022f9:	a2 7c d2 17 00       	mov    %al,0x17d27c
  1022fe:	0f b6 05 7c d2 17 00 	movzbl 0x17d27c,%eax
  102305:	83 e0 1f             	and    $0x1f,%eax
  102308:	a2 7c d2 17 00       	mov    %al,0x17d27c
  10230d:	0f b6 05 7d d2 17 00 	movzbl 0x17d27d,%eax
  102314:	83 e0 f0             	and    $0xfffffff0,%eax
  102317:	83 c8 0e             	or     $0xe,%eax
  10231a:	a2 7d d2 17 00       	mov    %al,0x17d27d
  10231f:	0f b6 05 7d d2 17 00 	movzbl 0x17d27d,%eax
  102326:	83 e0 ef             	and    $0xffffffef,%eax
  102329:	a2 7d d2 17 00       	mov    %al,0x17d27d
  10232e:	0f b6 05 7d d2 17 00 	movzbl 0x17d27d,%eax
  102335:	83 e0 9f             	and    $0xffffff9f,%eax
  102338:	a2 7d d2 17 00       	mov    %al,0x17d27d
  10233d:	0f b6 05 7d d2 17 00 	movzbl 0x17d27d,%eax
  102344:	83 c8 80             	or     $0xffffff80,%eax
  102347:	a2 7d d2 17 00       	mov    %al,0x17d27d
  10234c:	b8 30 39 10 00       	mov    $0x103930,%eax
  102351:	c1 e8 10             	shr    $0x10,%eax
  102354:	66 a3 7e d2 17 00    	mov    %ax,0x17d27e
  10235a:	b8 38 39 10 00       	mov    $0x103938,%eax
  10235f:	66 a3 80 d2 17 00    	mov    %ax,0x17d280
  102365:	66 c7 05 82 d2 17 00 	movw   $0x8,0x17d282
  10236c:	08 00 
  10236e:	0f b6 05 84 d2 17 00 	movzbl 0x17d284,%eax
  102375:	83 e0 e0             	and    $0xffffffe0,%eax
  102378:	a2 84 d2 17 00       	mov    %al,0x17d284
  10237d:	0f b6 05 84 d2 17 00 	movzbl 0x17d284,%eax
  102384:	83 e0 1f             	and    $0x1f,%eax
  102387:	a2 84 d2 17 00       	mov    %al,0x17d284
  10238c:	0f b6 05 85 d2 17 00 	movzbl 0x17d285,%eax
  102393:	83 e0 f0             	and    $0xfffffff0,%eax
  102396:	83 c8 0e             	or     $0xe,%eax
  102399:	a2 85 d2 17 00       	mov    %al,0x17d285
  10239e:	0f b6 05 85 d2 17 00 	movzbl 0x17d285,%eax
  1023a5:	83 e0 ef             	and    $0xffffffef,%eax
  1023a8:	a2 85 d2 17 00       	mov    %al,0x17d285
  1023ad:	0f b6 05 85 d2 17 00 	movzbl 0x17d285,%eax
  1023b4:	83 e0 9f             	and    $0xffffff9f,%eax
  1023b7:	a2 85 d2 17 00       	mov    %al,0x17d285
  1023bc:	0f b6 05 85 d2 17 00 	movzbl 0x17d285,%eax
  1023c3:	83 c8 80             	or     $0xffffff80,%eax
  1023c6:	a2 85 d2 17 00       	mov    %al,0x17d285
  1023cb:	b8 38 39 10 00       	mov    $0x103938,%eax
  1023d0:	c1 e8 10             	shr    $0x10,%eax
  1023d3:	66 a3 86 d2 17 00    	mov    %ax,0x17d286
  1023d9:	b8 40 39 10 00       	mov    $0x103940,%eax
  1023de:	66 a3 88 d2 17 00    	mov    %ax,0x17d288
  1023e4:	66 c7 05 8a d2 17 00 	movw   $0x8,0x17d28a
  1023eb:	08 00 
  1023ed:	0f b6 05 8c d2 17 00 	movzbl 0x17d28c,%eax
  1023f4:	83 e0 e0             	and    $0xffffffe0,%eax
  1023f7:	a2 8c d2 17 00       	mov    %al,0x17d28c
  1023fc:	0f b6 05 8c d2 17 00 	movzbl 0x17d28c,%eax
  102403:	83 e0 1f             	and    $0x1f,%eax
  102406:	a2 8c d2 17 00       	mov    %al,0x17d28c
  10240b:	0f b6 05 8d d2 17 00 	movzbl 0x17d28d,%eax
  102412:	83 e0 f0             	and    $0xfffffff0,%eax
  102415:	83 c8 0e             	or     $0xe,%eax
  102418:	a2 8d d2 17 00       	mov    %al,0x17d28d
  10241d:	0f b6 05 8d d2 17 00 	movzbl 0x17d28d,%eax
  102424:	83 e0 ef             	and    $0xffffffef,%eax
  102427:	a2 8d d2 17 00       	mov    %al,0x17d28d
  10242c:	0f b6 05 8d d2 17 00 	movzbl 0x17d28d,%eax
  102433:	83 e0 9f             	and    $0xffffff9f,%eax
  102436:	a2 8d d2 17 00       	mov    %al,0x17d28d
  10243b:	0f b6 05 8d d2 17 00 	movzbl 0x17d28d,%eax
  102442:	83 c8 80             	or     $0xffffff80,%eax
  102445:	a2 8d d2 17 00       	mov    %al,0x17d28d
  10244a:	b8 40 39 10 00       	mov    $0x103940,%eax
  10244f:	c1 e8 10             	shr    $0x10,%eax
  102452:	66 a3 8e d2 17 00    	mov    %ax,0x17d28e
  102458:	b8 48 39 10 00       	mov    $0x103948,%eax
  10245d:	66 a3 90 d2 17 00    	mov    %ax,0x17d290
  102463:	66 c7 05 92 d2 17 00 	movw   $0x8,0x17d292
  10246a:	08 00 
  10246c:	0f b6 05 94 d2 17 00 	movzbl 0x17d294,%eax
  102473:	83 e0 e0             	and    $0xffffffe0,%eax
  102476:	a2 94 d2 17 00       	mov    %al,0x17d294
  10247b:	0f b6 05 94 d2 17 00 	movzbl 0x17d294,%eax
  102482:	83 e0 1f             	and    $0x1f,%eax
  102485:	a2 94 d2 17 00       	mov    %al,0x17d294
  10248a:	0f b6 05 95 d2 17 00 	movzbl 0x17d295,%eax
  102491:	83 e0 f0             	and    $0xfffffff0,%eax
  102494:	83 c8 0e             	or     $0xe,%eax
  102497:	a2 95 d2 17 00       	mov    %al,0x17d295
  10249c:	0f b6 05 95 d2 17 00 	movzbl 0x17d295,%eax
  1024a3:	83 e0 ef             	and    $0xffffffef,%eax
  1024a6:	a2 95 d2 17 00       	mov    %al,0x17d295
  1024ab:	0f b6 05 95 d2 17 00 	movzbl 0x17d295,%eax
  1024b2:	83 e0 9f             	and    $0xffffff9f,%eax
  1024b5:	a2 95 d2 17 00       	mov    %al,0x17d295
  1024ba:	0f b6 05 95 d2 17 00 	movzbl 0x17d295,%eax
  1024c1:	83 c8 80             	or     $0xffffff80,%eax
  1024c4:	a2 95 d2 17 00       	mov    %al,0x17d295
  1024c9:	b8 48 39 10 00       	mov    $0x103948,%eax
  1024ce:	c1 e8 10             	shr    $0x10,%eax
  1024d1:	66 a3 96 d2 17 00    	mov    %ax,0x17d296
  1024d7:	b8 50 39 10 00       	mov    $0x103950,%eax
  1024dc:	66 a3 a0 d2 17 00    	mov    %ax,0x17d2a0
  1024e2:	66 c7 05 a2 d2 17 00 	movw   $0x8,0x17d2a2
  1024e9:	08 00 
  1024eb:	0f b6 05 a4 d2 17 00 	movzbl 0x17d2a4,%eax
  1024f2:	83 e0 e0             	and    $0xffffffe0,%eax
  1024f5:	a2 a4 d2 17 00       	mov    %al,0x17d2a4
  1024fa:	0f b6 05 a4 d2 17 00 	movzbl 0x17d2a4,%eax
  102501:	83 e0 1f             	and    $0x1f,%eax
  102504:	a2 a4 d2 17 00       	mov    %al,0x17d2a4
  102509:	0f b6 05 a5 d2 17 00 	movzbl 0x17d2a5,%eax
  102510:	83 e0 f0             	and    $0xfffffff0,%eax
  102513:	83 c8 0e             	or     $0xe,%eax
  102516:	a2 a5 d2 17 00       	mov    %al,0x17d2a5
  10251b:	0f b6 05 a5 d2 17 00 	movzbl 0x17d2a5,%eax
  102522:	83 e0 ef             	and    $0xffffffef,%eax
  102525:	a2 a5 d2 17 00       	mov    %al,0x17d2a5
  10252a:	0f b6 05 a5 d2 17 00 	movzbl 0x17d2a5,%eax
  102531:	83 e0 9f             	and    $0xffffff9f,%eax
  102534:	a2 a5 d2 17 00       	mov    %al,0x17d2a5
  102539:	0f b6 05 a5 d2 17 00 	movzbl 0x17d2a5,%eax
  102540:	83 c8 80             	or     $0xffffff80,%eax
  102543:	a2 a5 d2 17 00       	mov    %al,0x17d2a5
  102548:	b8 50 39 10 00       	mov    $0x103950,%eax
  10254d:	c1 e8 10             	shr    $0x10,%eax
  102550:	66 a3 a6 d2 17 00    	mov    %ax,0x17d2a6
  102556:	b8 5a 39 10 00       	mov    $0x10395a,%eax
  10255b:	66 a3 a8 d2 17 00    	mov    %ax,0x17d2a8
  102561:	66 c7 05 aa d2 17 00 	movw   $0x8,0x17d2aa
  102568:	08 00 
  10256a:	0f b6 05 ac d2 17 00 	movzbl 0x17d2ac,%eax
  102571:	83 e0 e0             	and    $0xffffffe0,%eax
  102574:	a2 ac d2 17 00       	mov    %al,0x17d2ac
  102579:	0f b6 05 ac d2 17 00 	movzbl 0x17d2ac,%eax
  102580:	83 e0 1f             	and    $0x1f,%eax
  102583:	a2 ac d2 17 00       	mov    %al,0x17d2ac
  102588:	0f b6 05 ad d2 17 00 	movzbl 0x17d2ad,%eax
  10258f:	83 e0 f0             	and    $0xfffffff0,%eax
  102592:	83 c8 0e             	or     $0xe,%eax
  102595:	a2 ad d2 17 00       	mov    %al,0x17d2ad
  10259a:	0f b6 05 ad d2 17 00 	movzbl 0x17d2ad,%eax
  1025a1:	83 e0 ef             	and    $0xffffffef,%eax
  1025a4:	a2 ad d2 17 00       	mov    %al,0x17d2ad
  1025a9:	0f b6 05 ad d2 17 00 	movzbl 0x17d2ad,%eax
  1025b0:	83 e0 9f             	and    $0xffffff9f,%eax
  1025b3:	a2 ad d2 17 00       	mov    %al,0x17d2ad
  1025b8:	0f b6 05 ad d2 17 00 	movzbl 0x17d2ad,%eax
  1025bf:	83 c8 80             	or     $0xffffff80,%eax
  1025c2:	a2 ad d2 17 00       	mov    %al,0x17d2ad
  1025c7:	b8 5a 39 10 00       	mov    $0x10395a,%eax
  1025cc:	c1 e8 10             	shr    $0x10,%eax
  1025cf:	66 a3 ae d2 17 00    	mov    %ax,0x17d2ae
  1025d5:	b8 62 39 10 00       	mov    $0x103962,%eax
  1025da:	66 a3 b0 d2 17 00    	mov    %ax,0x17d2b0
  1025e0:	66 c7 05 b2 d2 17 00 	movw   $0x8,0x17d2b2
  1025e7:	08 00 
  1025e9:	0f b6 05 b4 d2 17 00 	movzbl 0x17d2b4,%eax
  1025f0:	83 e0 e0             	and    $0xffffffe0,%eax
  1025f3:	a2 b4 d2 17 00       	mov    %al,0x17d2b4
  1025f8:	0f b6 05 b4 d2 17 00 	movzbl 0x17d2b4,%eax
  1025ff:	83 e0 1f             	and    $0x1f,%eax
  102602:	a2 b4 d2 17 00       	mov    %al,0x17d2b4
  102607:	0f b6 05 b5 d2 17 00 	movzbl 0x17d2b5,%eax
  10260e:	83 e0 f0             	and    $0xfffffff0,%eax
  102611:	83 c8 0e             	or     $0xe,%eax
  102614:	a2 b5 d2 17 00       	mov    %al,0x17d2b5
  102619:	0f b6 05 b5 d2 17 00 	movzbl 0x17d2b5,%eax
  102620:	83 e0 ef             	and    $0xffffffef,%eax
  102623:	a2 b5 d2 17 00       	mov    %al,0x17d2b5
  102628:	0f b6 05 b5 d2 17 00 	movzbl 0x17d2b5,%eax
  10262f:	83 e0 9f             	and    $0xffffff9f,%eax
  102632:	a2 b5 d2 17 00       	mov    %al,0x17d2b5
  102637:	0f b6 05 b5 d2 17 00 	movzbl 0x17d2b5,%eax
  10263e:	83 c8 80             	or     $0xffffff80,%eax
  102641:	a2 b5 d2 17 00       	mov    %al,0x17d2b5
  102646:	b8 62 39 10 00       	mov    $0x103962,%eax
  10264b:	c1 e8 10             	shr    $0x10,%eax
  10264e:	66 a3 b6 d2 17 00    	mov    %ax,0x17d2b6
  102654:	b8 6c 39 10 00       	mov    $0x10396c,%eax
  102659:	66 a3 b8 d2 17 00    	mov    %ax,0x17d2b8
  10265f:	66 c7 05 ba d2 17 00 	movw   $0x8,0x17d2ba
  102666:	08 00 
  102668:	0f b6 05 bc d2 17 00 	movzbl 0x17d2bc,%eax
  10266f:	83 e0 e0             	and    $0xffffffe0,%eax
  102672:	a2 bc d2 17 00       	mov    %al,0x17d2bc
  102677:	0f b6 05 bc d2 17 00 	movzbl 0x17d2bc,%eax
  10267e:	83 e0 1f             	and    $0x1f,%eax
  102681:	a2 bc d2 17 00       	mov    %al,0x17d2bc
  102686:	0f b6 05 bd d2 17 00 	movzbl 0x17d2bd,%eax
  10268d:	83 e0 f0             	and    $0xfffffff0,%eax
  102690:	83 c8 0e             	or     $0xe,%eax
  102693:	a2 bd d2 17 00       	mov    %al,0x17d2bd
  102698:	0f b6 05 bd d2 17 00 	movzbl 0x17d2bd,%eax
  10269f:	83 e0 ef             	and    $0xffffffef,%eax
  1026a2:	a2 bd d2 17 00       	mov    %al,0x17d2bd
  1026a7:	0f b6 05 bd d2 17 00 	movzbl 0x17d2bd,%eax
  1026ae:	83 e0 9f             	and    $0xffffff9f,%eax
  1026b1:	a2 bd d2 17 00       	mov    %al,0x17d2bd
  1026b6:	0f b6 05 bd d2 17 00 	movzbl 0x17d2bd,%eax
  1026bd:	83 c8 80             	or     $0xffffff80,%eax
  1026c0:	a2 bd d2 17 00       	mov    %al,0x17d2bd
  1026c5:	b8 6c 39 10 00       	mov    $0x10396c,%eax
  1026ca:	c1 e8 10             	shr    $0x10,%eax
  1026cd:	66 a3 be d2 17 00    	mov    %ax,0x17d2be
  1026d3:	b8 76 39 10 00       	mov    $0x103976,%eax
  1026d8:	66 a3 20 d3 17 00    	mov    %ax,0x17d320
  1026de:	66 c7 05 22 d3 17 00 	movw   $0x8,0x17d322
  1026e5:	08 00 
  1026e7:	0f b6 05 24 d3 17 00 	movzbl 0x17d324,%eax
  1026ee:	83 e0 e0             	and    $0xffffffe0,%eax
  1026f1:	a2 24 d3 17 00       	mov    %al,0x17d324
  1026f6:	0f b6 05 24 d3 17 00 	movzbl 0x17d324,%eax
  1026fd:	83 e0 1f             	and    $0x1f,%eax
  102700:	a2 24 d3 17 00       	mov    %al,0x17d324
  102705:	0f b6 05 25 d3 17 00 	movzbl 0x17d325,%eax
  10270c:	83 e0 f0             	and    $0xfffffff0,%eax
  10270f:	83 c8 0e             	or     $0xe,%eax
  102712:	a2 25 d3 17 00       	mov    %al,0x17d325
  102717:	0f b6 05 25 d3 17 00 	movzbl 0x17d325,%eax
  10271e:	83 e0 ef             	and    $0xffffffef,%eax
  102721:	a2 25 d3 17 00       	mov    %al,0x17d325
  102726:	0f b6 05 25 d3 17 00 	movzbl 0x17d325,%eax
  10272d:	83 e0 9f             	and    $0xffffff9f,%eax
  102730:	a2 25 d3 17 00       	mov    %al,0x17d325
  102735:	0f b6 05 25 d3 17 00 	movzbl 0x17d325,%eax
  10273c:	83 c8 80             	or     $0xffffff80,%eax
  10273f:	a2 25 d3 17 00       	mov    %al,0x17d325
  102744:	b8 76 39 10 00       	mov    $0x103976,%eax
  102749:	c1 e8 10             	shr    $0x10,%eax
  10274c:	66 a3 26 d3 17 00    	mov    %ax,0x17d326
  102752:	b8 80 39 10 00       	mov    $0x103980,%eax
  102757:	66 a3 28 d3 17 00    	mov    %ax,0x17d328
  10275d:	66 c7 05 2a d3 17 00 	movw   $0x8,0x17d32a
  102764:	08 00 
  102766:	0f b6 05 2c d3 17 00 	movzbl 0x17d32c,%eax
  10276d:	83 e0 e0             	and    $0xffffffe0,%eax
  102770:	a2 2c d3 17 00       	mov    %al,0x17d32c
  102775:	0f b6 05 2c d3 17 00 	movzbl 0x17d32c,%eax
  10277c:	83 e0 1f             	and    $0x1f,%eax
  10277f:	a2 2c d3 17 00       	mov    %al,0x17d32c
  102784:	0f b6 05 2d d3 17 00 	movzbl 0x17d32d,%eax
  10278b:	83 e0 f0             	and    $0xfffffff0,%eax
  10278e:	83 c8 0e             	or     $0xe,%eax
  102791:	a2 2d d3 17 00       	mov    %al,0x17d32d
  102796:	0f b6 05 2d d3 17 00 	movzbl 0x17d32d,%eax
  10279d:	83 e0 ef             	and    $0xffffffef,%eax
  1027a0:	a2 2d d3 17 00       	mov    %al,0x17d32d
  1027a5:	0f b6 05 2d d3 17 00 	movzbl 0x17d32d,%eax
  1027ac:	83 e0 9f             	and    $0xffffff9f,%eax
  1027af:	a2 2d d3 17 00       	mov    %al,0x17d32d
  1027b4:	0f b6 05 2d d3 17 00 	movzbl 0x17d32d,%eax
  1027bb:	83 c8 80             	or     $0xffffff80,%eax
  1027be:	a2 2d d3 17 00       	mov    %al,0x17d32d
  1027c3:	b8 80 39 10 00       	mov    $0x103980,%eax
  1027c8:	c1 e8 10             	shr    $0x10,%eax
  1027cb:	66 a3 2e d3 17 00    	mov    %ax,0x17d32e
  1027d1:	b8 8a 39 10 00       	mov    $0x10398a,%eax
  1027d6:	66 a3 30 d3 17 00    	mov    %ax,0x17d330
  1027dc:	66 c7 05 32 d3 17 00 	movw   $0x8,0x17d332
  1027e3:	08 00 
  1027e5:	0f b6 05 34 d3 17 00 	movzbl 0x17d334,%eax
  1027ec:	83 e0 e0             	and    $0xffffffe0,%eax
  1027ef:	a2 34 d3 17 00       	mov    %al,0x17d334
  1027f4:	0f b6 05 34 d3 17 00 	movzbl 0x17d334,%eax
  1027fb:	83 e0 1f             	and    $0x1f,%eax
  1027fe:	a2 34 d3 17 00       	mov    %al,0x17d334
  102803:	0f b6 05 35 d3 17 00 	movzbl 0x17d335,%eax
  10280a:	83 e0 f0             	and    $0xfffffff0,%eax
  10280d:	83 c8 0e             	or     $0xe,%eax
  102810:	a2 35 d3 17 00       	mov    %al,0x17d335
  102815:	0f b6 05 35 d3 17 00 	movzbl 0x17d335,%eax
  10281c:	83 e0 ef             	and    $0xffffffef,%eax
  10281f:	a2 35 d3 17 00       	mov    %al,0x17d335
  102824:	0f b6 05 35 d3 17 00 	movzbl 0x17d335,%eax
  10282b:	83 e0 9f             	and    $0xffffff9f,%eax
  10282e:	a2 35 d3 17 00       	mov    %al,0x17d335
  102833:	0f b6 05 35 d3 17 00 	movzbl 0x17d335,%eax
  10283a:	83 c8 80             	or     $0xffffff80,%eax
  10283d:	a2 35 d3 17 00       	mov    %al,0x17d335
  102842:	b8 8a 39 10 00       	mov    $0x10398a,%eax
  102847:	c1 e8 10             	shr    $0x10,%eax
  10284a:	66 a3 36 d3 17 00    	mov    %ax,0x17d336
  102850:	b8 94 39 10 00       	mov    $0x103994,%eax
  102855:	66 a3 38 d3 17 00    	mov    %ax,0x17d338
  10285b:	66 c7 05 3a d3 17 00 	movw   $0x8,0x17d33a
  102862:	08 00 
  102864:	0f b6 05 3c d3 17 00 	movzbl 0x17d33c,%eax
  10286b:	83 e0 e0             	and    $0xffffffe0,%eax
  10286e:	a2 3c d3 17 00       	mov    %al,0x17d33c
  102873:	0f b6 05 3c d3 17 00 	movzbl 0x17d33c,%eax
  10287a:	83 e0 1f             	and    $0x1f,%eax
  10287d:	a2 3c d3 17 00       	mov    %al,0x17d33c
  102882:	0f b6 05 3d d3 17 00 	movzbl 0x17d33d,%eax
  102889:	83 e0 f0             	and    $0xfffffff0,%eax
  10288c:	83 c8 0e             	or     $0xe,%eax
  10288f:	a2 3d d3 17 00       	mov    %al,0x17d33d
  102894:	0f b6 05 3d d3 17 00 	movzbl 0x17d33d,%eax
  10289b:	83 e0 ef             	and    $0xffffffef,%eax
  10289e:	a2 3d d3 17 00       	mov    %al,0x17d33d
  1028a3:	0f b6 05 3d d3 17 00 	movzbl 0x17d33d,%eax
  1028aa:	83 e0 9f             	and    $0xffffff9f,%eax
  1028ad:	a2 3d d3 17 00       	mov    %al,0x17d33d
  1028b2:	0f b6 05 3d d3 17 00 	movzbl 0x17d33d,%eax
  1028b9:	83 c8 80             	or     $0xffffff80,%eax
  1028bc:	a2 3d d3 17 00       	mov    %al,0x17d33d
  1028c1:	b8 94 39 10 00       	mov    $0x103994,%eax
  1028c6:	c1 e8 10             	shr    $0x10,%eax
  1028c9:	66 a3 3e d3 17 00    	mov    %ax,0x17d33e
  1028cf:	b8 9e 39 10 00       	mov    $0x10399e,%eax
  1028d4:	66 a3 40 d3 17 00    	mov    %ax,0x17d340
  1028da:	66 c7 05 42 d3 17 00 	movw   $0x8,0x17d342
  1028e1:	08 00 
  1028e3:	0f b6 05 44 d3 17 00 	movzbl 0x17d344,%eax
  1028ea:	83 e0 e0             	and    $0xffffffe0,%eax
  1028ed:	a2 44 d3 17 00       	mov    %al,0x17d344
  1028f2:	0f b6 05 44 d3 17 00 	movzbl 0x17d344,%eax
  1028f9:	83 e0 1f             	and    $0x1f,%eax
  1028fc:	a2 44 d3 17 00       	mov    %al,0x17d344
  102901:	0f b6 05 45 d3 17 00 	movzbl 0x17d345,%eax
  102908:	83 e0 f0             	and    $0xfffffff0,%eax
  10290b:	83 c8 0e             	or     $0xe,%eax
  10290e:	a2 45 d3 17 00       	mov    %al,0x17d345
  102913:	0f b6 05 45 d3 17 00 	movzbl 0x17d345,%eax
  10291a:	83 e0 ef             	and    $0xffffffef,%eax
  10291d:	a2 45 d3 17 00       	mov    %al,0x17d345
  102922:	0f b6 05 45 d3 17 00 	movzbl 0x17d345,%eax
  102929:	83 e0 9f             	and    $0xffffff9f,%eax
  10292c:	a2 45 d3 17 00       	mov    %al,0x17d345
  102931:	0f b6 05 45 d3 17 00 	movzbl 0x17d345,%eax
  102938:	83 c8 80             	or     $0xffffff80,%eax
  10293b:	a2 45 d3 17 00       	mov    %al,0x17d345
  102940:	b8 9e 39 10 00       	mov    $0x10399e,%eax
  102945:	c1 e8 10             	shr    $0x10,%eax
  102948:	66 a3 46 d3 17 00    	mov    %ax,0x17d346
  10294e:	b8 a8 39 10 00       	mov    $0x1039a8,%eax
  102953:	66 a3 48 d3 17 00    	mov    %ax,0x17d348
  102959:	66 c7 05 4a d3 17 00 	movw   $0x8,0x17d34a
  102960:	08 00 
  102962:	0f b6 05 4c d3 17 00 	movzbl 0x17d34c,%eax
  102969:	83 e0 e0             	and    $0xffffffe0,%eax
  10296c:	a2 4c d3 17 00       	mov    %al,0x17d34c
  102971:	0f b6 05 4c d3 17 00 	movzbl 0x17d34c,%eax
  102978:	83 e0 1f             	and    $0x1f,%eax
  10297b:	a2 4c d3 17 00       	mov    %al,0x17d34c
  102980:	0f b6 05 4d d3 17 00 	movzbl 0x17d34d,%eax
  102987:	83 e0 f0             	and    $0xfffffff0,%eax
  10298a:	83 c8 0e             	or     $0xe,%eax
  10298d:	a2 4d d3 17 00       	mov    %al,0x17d34d
  102992:	0f b6 05 4d d3 17 00 	movzbl 0x17d34d,%eax
  102999:	83 e0 ef             	and    $0xffffffef,%eax
  10299c:	a2 4d d3 17 00       	mov    %al,0x17d34d
  1029a1:	0f b6 05 4d d3 17 00 	movzbl 0x17d34d,%eax
  1029a8:	83 e0 9f             	and    $0xffffff9f,%eax
  1029ab:	a2 4d d3 17 00       	mov    %al,0x17d34d
  1029b0:	0f b6 05 4d d3 17 00 	movzbl 0x17d34d,%eax
  1029b7:	83 c8 80             	or     $0xffffff80,%eax
  1029ba:	a2 4d d3 17 00       	mov    %al,0x17d34d
  1029bf:	b8 a8 39 10 00       	mov    $0x1039a8,%eax
  1029c4:	c1 e8 10             	shr    $0x10,%eax
  1029c7:	66 a3 4e d3 17 00    	mov    %ax,0x17d34e
  1029cd:	b8 b2 39 10 00       	mov    $0x1039b2,%eax
  1029d2:	66 a3 50 d3 17 00    	mov    %ax,0x17d350
  1029d8:	66 c7 05 52 d3 17 00 	movw   $0x8,0x17d352
  1029df:	08 00 
  1029e1:	0f b6 05 54 d3 17 00 	movzbl 0x17d354,%eax
  1029e8:	83 e0 e0             	and    $0xffffffe0,%eax
  1029eb:	a2 54 d3 17 00       	mov    %al,0x17d354
  1029f0:	0f b6 05 54 d3 17 00 	movzbl 0x17d354,%eax
  1029f7:	83 e0 1f             	and    $0x1f,%eax
  1029fa:	a2 54 d3 17 00       	mov    %al,0x17d354
  1029ff:	0f b6 05 55 d3 17 00 	movzbl 0x17d355,%eax
  102a06:	83 e0 f0             	and    $0xfffffff0,%eax
  102a09:	83 c8 0e             	or     $0xe,%eax
  102a0c:	a2 55 d3 17 00       	mov    %al,0x17d355
  102a11:	0f b6 05 55 d3 17 00 	movzbl 0x17d355,%eax
  102a18:	83 e0 ef             	and    $0xffffffef,%eax
  102a1b:	a2 55 d3 17 00       	mov    %al,0x17d355
  102a20:	0f b6 05 55 d3 17 00 	movzbl 0x17d355,%eax
  102a27:	83 e0 9f             	and    $0xffffff9f,%eax
  102a2a:	a2 55 d3 17 00       	mov    %al,0x17d355
  102a2f:	0f b6 05 55 d3 17 00 	movzbl 0x17d355,%eax
  102a36:	83 c8 80             	or     $0xffffff80,%eax
  102a39:	a2 55 d3 17 00       	mov    %al,0x17d355
  102a3e:	b8 b2 39 10 00       	mov    $0x1039b2,%eax
  102a43:	c1 e8 10             	shr    $0x10,%eax
  102a46:	66 a3 56 d3 17 00    	mov    %ax,0x17d356
  102a4c:	b8 bc 39 10 00       	mov    $0x1039bc,%eax
  102a51:	66 a3 58 d3 17 00    	mov    %ax,0x17d358
  102a57:	66 c7 05 5a d3 17 00 	movw   $0x8,0x17d35a
  102a5e:	08 00 
  102a60:	0f b6 05 5c d3 17 00 	movzbl 0x17d35c,%eax
  102a67:	83 e0 e0             	and    $0xffffffe0,%eax
  102a6a:	a2 5c d3 17 00       	mov    %al,0x17d35c
  102a6f:	0f b6 05 5c d3 17 00 	movzbl 0x17d35c,%eax
  102a76:	83 e0 1f             	and    $0x1f,%eax
  102a79:	a2 5c d3 17 00       	mov    %al,0x17d35c
  102a7e:	0f b6 05 5d d3 17 00 	movzbl 0x17d35d,%eax
  102a85:	83 e0 f0             	and    $0xfffffff0,%eax
  102a88:	83 c8 0e             	or     $0xe,%eax
  102a8b:	a2 5d d3 17 00       	mov    %al,0x17d35d
  102a90:	0f b6 05 5d d3 17 00 	movzbl 0x17d35d,%eax
  102a97:	83 e0 ef             	and    $0xffffffef,%eax
  102a9a:	a2 5d d3 17 00       	mov    %al,0x17d35d
  102a9f:	0f b6 05 5d d3 17 00 	movzbl 0x17d35d,%eax
  102aa6:	83 e0 9f             	and    $0xffffff9f,%eax
  102aa9:	a2 5d d3 17 00       	mov    %al,0x17d35d
  102aae:	0f b6 05 5d d3 17 00 	movzbl 0x17d35d,%eax
  102ab5:	83 c8 80             	or     $0xffffff80,%eax
  102ab8:	a2 5d d3 17 00       	mov    %al,0x17d35d
  102abd:	b8 bc 39 10 00       	mov    $0x1039bc,%eax
  102ac2:	c1 e8 10             	shr    $0x10,%eax
  102ac5:	66 a3 5e d3 17 00    	mov    %ax,0x17d35e
  102acb:	b8 c6 39 10 00       	mov    $0x1039c6,%eax
  102ad0:	66 a3 60 d3 17 00    	mov    %ax,0x17d360
  102ad6:	66 c7 05 62 d3 17 00 	movw   $0x8,0x17d362
  102add:	08 00 
  102adf:	0f b6 05 64 d3 17 00 	movzbl 0x17d364,%eax
  102ae6:	83 e0 e0             	and    $0xffffffe0,%eax
  102ae9:	a2 64 d3 17 00       	mov    %al,0x17d364
  102aee:	0f b6 05 64 d3 17 00 	movzbl 0x17d364,%eax
  102af5:	83 e0 1f             	and    $0x1f,%eax
  102af8:	a2 64 d3 17 00       	mov    %al,0x17d364
  102afd:	0f b6 05 65 d3 17 00 	movzbl 0x17d365,%eax
  102b04:	83 e0 f0             	and    $0xfffffff0,%eax
  102b07:	83 c8 0e             	or     $0xe,%eax
  102b0a:	a2 65 d3 17 00       	mov    %al,0x17d365
  102b0f:	0f b6 05 65 d3 17 00 	movzbl 0x17d365,%eax
  102b16:	83 e0 ef             	and    $0xffffffef,%eax
  102b19:	a2 65 d3 17 00       	mov    %al,0x17d365
  102b1e:	0f b6 05 65 d3 17 00 	movzbl 0x17d365,%eax
  102b25:	83 e0 9f             	and    $0xffffff9f,%eax
  102b28:	a2 65 d3 17 00       	mov    %al,0x17d365
  102b2d:	0f b6 05 65 d3 17 00 	movzbl 0x17d365,%eax
  102b34:	83 c8 80             	or     $0xffffff80,%eax
  102b37:	a2 65 d3 17 00       	mov    %al,0x17d365
  102b3c:	b8 c6 39 10 00       	mov    $0x1039c6,%eax
  102b41:	c1 e8 10             	shr    $0x10,%eax
  102b44:	66 a3 66 d3 17 00    	mov    %ax,0x17d366
  102b4a:	b8 d0 39 10 00       	mov    $0x1039d0,%eax
  102b4f:	66 a3 68 d3 17 00    	mov    %ax,0x17d368
  102b55:	66 c7 05 6a d3 17 00 	movw   $0x8,0x17d36a
  102b5c:	08 00 
  102b5e:	0f b6 05 6c d3 17 00 	movzbl 0x17d36c,%eax
  102b65:	83 e0 e0             	and    $0xffffffe0,%eax
  102b68:	a2 6c d3 17 00       	mov    %al,0x17d36c
  102b6d:	0f b6 05 6c d3 17 00 	movzbl 0x17d36c,%eax
  102b74:	83 e0 1f             	and    $0x1f,%eax
  102b77:	a2 6c d3 17 00       	mov    %al,0x17d36c
  102b7c:	0f b6 05 6d d3 17 00 	movzbl 0x17d36d,%eax
  102b83:	83 e0 f0             	and    $0xfffffff0,%eax
  102b86:	83 c8 0e             	or     $0xe,%eax
  102b89:	a2 6d d3 17 00       	mov    %al,0x17d36d
  102b8e:	0f b6 05 6d d3 17 00 	movzbl 0x17d36d,%eax
  102b95:	83 e0 ef             	and    $0xffffffef,%eax
  102b98:	a2 6d d3 17 00       	mov    %al,0x17d36d
  102b9d:	0f b6 05 6d d3 17 00 	movzbl 0x17d36d,%eax
  102ba4:	83 e0 9f             	and    $0xffffff9f,%eax
  102ba7:	a2 6d d3 17 00       	mov    %al,0x17d36d
  102bac:	0f b6 05 6d d3 17 00 	movzbl 0x17d36d,%eax
  102bb3:	83 c8 80             	or     $0xffffff80,%eax
  102bb6:	a2 6d d3 17 00       	mov    %al,0x17d36d
  102bbb:	b8 d0 39 10 00       	mov    $0x1039d0,%eax
  102bc0:	c1 e8 10             	shr    $0x10,%eax
  102bc3:	66 a3 6e d3 17 00    	mov    %ax,0x17d36e
  102bc9:	b8 da 39 10 00       	mov    $0x1039da,%eax
  102bce:	66 a3 70 d3 17 00    	mov    %ax,0x17d370
  102bd4:	66 c7 05 72 d3 17 00 	movw   $0x8,0x17d372
  102bdb:	08 00 
  102bdd:	0f b6 05 74 d3 17 00 	movzbl 0x17d374,%eax
  102be4:	83 e0 e0             	and    $0xffffffe0,%eax
  102be7:	a2 74 d3 17 00       	mov    %al,0x17d374
  102bec:	0f b6 05 74 d3 17 00 	movzbl 0x17d374,%eax
  102bf3:	83 e0 1f             	and    $0x1f,%eax
  102bf6:	a2 74 d3 17 00       	mov    %al,0x17d374
  102bfb:	0f b6 05 75 d3 17 00 	movzbl 0x17d375,%eax
  102c02:	83 e0 f0             	and    $0xfffffff0,%eax
  102c05:	83 c8 0e             	or     $0xe,%eax
  102c08:	a2 75 d3 17 00       	mov    %al,0x17d375
  102c0d:	0f b6 05 75 d3 17 00 	movzbl 0x17d375,%eax
  102c14:	83 e0 ef             	and    $0xffffffef,%eax
  102c17:	a2 75 d3 17 00       	mov    %al,0x17d375
  102c1c:	0f b6 05 75 d3 17 00 	movzbl 0x17d375,%eax
  102c23:	83 e0 9f             	and    $0xffffff9f,%eax
  102c26:	a2 75 d3 17 00       	mov    %al,0x17d375
  102c2b:	0f b6 05 75 d3 17 00 	movzbl 0x17d375,%eax
  102c32:	83 c8 80             	or     $0xffffff80,%eax
  102c35:	a2 75 d3 17 00       	mov    %al,0x17d375
  102c3a:	b8 da 39 10 00       	mov    $0x1039da,%eax
  102c3f:	c1 e8 10             	shr    $0x10,%eax
  102c42:	66 a3 76 d3 17 00    	mov    %ax,0x17d376
  102c48:	b8 e4 39 10 00       	mov    $0x1039e4,%eax
  102c4d:	66 a3 78 d3 17 00    	mov    %ax,0x17d378
  102c53:	66 c7 05 7a d3 17 00 	movw   $0x8,0x17d37a
  102c5a:	08 00 
  102c5c:	0f b6 05 7c d3 17 00 	movzbl 0x17d37c,%eax
  102c63:	83 e0 e0             	and    $0xffffffe0,%eax
  102c66:	a2 7c d3 17 00       	mov    %al,0x17d37c
  102c6b:	0f b6 05 7c d3 17 00 	movzbl 0x17d37c,%eax
  102c72:	83 e0 1f             	and    $0x1f,%eax
  102c75:	a2 7c d3 17 00       	mov    %al,0x17d37c
  102c7a:	0f b6 05 7d d3 17 00 	movzbl 0x17d37d,%eax
  102c81:	83 e0 f0             	and    $0xfffffff0,%eax
  102c84:	83 c8 0e             	or     $0xe,%eax
  102c87:	a2 7d d3 17 00       	mov    %al,0x17d37d
  102c8c:	0f b6 05 7d d3 17 00 	movzbl 0x17d37d,%eax
  102c93:	83 e0 ef             	and    $0xffffffef,%eax
  102c96:	a2 7d d3 17 00       	mov    %al,0x17d37d
  102c9b:	0f b6 05 7d d3 17 00 	movzbl 0x17d37d,%eax
  102ca2:	83 e0 9f             	and    $0xffffff9f,%eax
  102ca5:	a2 7d d3 17 00       	mov    %al,0x17d37d
  102caa:	0f b6 05 7d d3 17 00 	movzbl 0x17d37d,%eax
  102cb1:	83 c8 80             	or     $0xffffff80,%eax
  102cb4:	a2 7d d3 17 00       	mov    %al,0x17d37d
  102cb9:	b8 e4 39 10 00       	mov    $0x1039e4,%eax
  102cbe:	c1 e8 10             	shr    $0x10,%eax
  102cc1:	66 a3 7e d3 17 00    	mov    %ax,0x17d37e
  102cc7:	b8 ee 39 10 00       	mov    $0x1039ee,%eax
  102ccc:	66 a3 80 d3 17 00    	mov    %ax,0x17d380
  102cd2:	66 c7 05 82 d3 17 00 	movw   $0x8,0x17d382
  102cd9:	08 00 
  102cdb:	0f b6 05 84 d3 17 00 	movzbl 0x17d384,%eax
  102ce2:	83 e0 e0             	and    $0xffffffe0,%eax
  102ce5:	a2 84 d3 17 00       	mov    %al,0x17d384
  102cea:	0f b6 05 84 d3 17 00 	movzbl 0x17d384,%eax
  102cf1:	83 e0 1f             	and    $0x1f,%eax
  102cf4:	a2 84 d3 17 00       	mov    %al,0x17d384
  102cf9:	0f b6 05 85 d3 17 00 	movzbl 0x17d385,%eax
  102d00:	83 e0 f0             	and    $0xfffffff0,%eax
  102d03:	83 c8 0e             	or     $0xe,%eax
  102d06:	a2 85 d3 17 00       	mov    %al,0x17d385
  102d0b:	0f b6 05 85 d3 17 00 	movzbl 0x17d385,%eax
  102d12:	83 e0 ef             	and    $0xffffffef,%eax
  102d15:	a2 85 d3 17 00       	mov    %al,0x17d385
  102d1a:	0f b6 05 85 d3 17 00 	movzbl 0x17d385,%eax
  102d21:	83 e0 9f             	and    $0xffffff9f,%eax
  102d24:	a2 85 d3 17 00       	mov    %al,0x17d385
  102d29:	0f b6 05 85 d3 17 00 	movzbl 0x17d385,%eax
  102d30:	83 c8 80             	or     $0xffffff80,%eax
  102d33:	a2 85 d3 17 00       	mov    %al,0x17d385
  102d38:	b8 ee 39 10 00       	mov    $0x1039ee,%eax
  102d3d:	c1 e8 10             	shr    $0x10,%eax
  102d40:	66 a3 86 d3 17 00    	mov    %ax,0x17d386
  102d46:	b8 f8 39 10 00       	mov    $0x1039f8,%eax
  102d4b:	66 a3 88 d3 17 00    	mov    %ax,0x17d388
  102d51:	66 c7 05 8a d3 17 00 	movw   $0x8,0x17d38a
  102d58:	08 00 
  102d5a:	0f b6 05 8c d3 17 00 	movzbl 0x17d38c,%eax
  102d61:	83 e0 e0             	and    $0xffffffe0,%eax
  102d64:	a2 8c d3 17 00       	mov    %al,0x17d38c
  102d69:	0f b6 05 8c d3 17 00 	movzbl 0x17d38c,%eax
  102d70:	83 e0 1f             	and    $0x1f,%eax
  102d73:	a2 8c d3 17 00       	mov    %al,0x17d38c
  102d78:	0f b6 05 8d d3 17 00 	movzbl 0x17d38d,%eax
  102d7f:	83 e0 f0             	and    $0xfffffff0,%eax
  102d82:	83 c8 0e             	or     $0xe,%eax
  102d85:	a2 8d d3 17 00       	mov    %al,0x17d38d
  102d8a:	0f b6 05 8d d3 17 00 	movzbl 0x17d38d,%eax
  102d91:	83 e0 ef             	and    $0xffffffef,%eax
  102d94:	a2 8d d3 17 00       	mov    %al,0x17d38d
  102d99:	0f b6 05 8d d3 17 00 	movzbl 0x17d38d,%eax
  102da0:	83 e0 9f             	and    $0xffffff9f,%eax
  102da3:	a2 8d d3 17 00       	mov    %al,0x17d38d
  102da8:	0f b6 05 8d d3 17 00 	movzbl 0x17d38d,%eax
  102daf:	83 c8 80             	or     $0xffffff80,%eax
  102db2:	a2 8d d3 17 00       	mov    %al,0x17d38d
  102db7:	b8 f8 39 10 00       	mov    $0x1039f8,%eax
  102dbc:	c1 e8 10             	shr    $0x10,%eax
  102dbf:	66 a3 8e d3 17 00    	mov    %ax,0x17d38e
  102dc5:	b8 02 3a 10 00       	mov    $0x103a02,%eax
  102dca:	66 a3 90 d3 17 00    	mov    %ax,0x17d390
  102dd0:	66 c7 05 92 d3 17 00 	movw   $0x8,0x17d392
  102dd7:	08 00 
  102dd9:	0f b6 05 94 d3 17 00 	movzbl 0x17d394,%eax
  102de0:	83 e0 e0             	and    $0xffffffe0,%eax
  102de3:	a2 94 d3 17 00       	mov    %al,0x17d394
  102de8:	0f b6 05 94 d3 17 00 	movzbl 0x17d394,%eax
  102def:	83 e0 1f             	and    $0x1f,%eax
  102df2:	a2 94 d3 17 00       	mov    %al,0x17d394
  102df7:	0f b6 05 95 d3 17 00 	movzbl 0x17d395,%eax
  102dfe:	83 e0 f0             	and    $0xfffffff0,%eax
  102e01:	83 c8 0e             	or     $0xe,%eax
  102e04:	a2 95 d3 17 00       	mov    %al,0x17d395
  102e09:	0f b6 05 95 d3 17 00 	movzbl 0x17d395,%eax
  102e10:	83 e0 ef             	and    $0xffffffef,%eax
  102e13:	a2 95 d3 17 00       	mov    %al,0x17d395
  102e18:	0f b6 05 95 d3 17 00 	movzbl 0x17d395,%eax
  102e1f:	83 e0 9f             	and    $0xffffff9f,%eax
  102e22:	a2 95 d3 17 00       	mov    %al,0x17d395
  102e27:	0f b6 05 95 d3 17 00 	movzbl 0x17d395,%eax
  102e2e:	83 c8 80             	or     $0xffffff80,%eax
  102e31:	a2 95 d3 17 00       	mov    %al,0x17d395
  102e36:	b8 02 3a 10 00       	mov    $0x103a02,%eax
  102e3b:	c1 e8 10             	shr    $0x10,%eax
  102e3e:	66 a3 96 d3 17 00    	mov    %ax,0x17d396
  102e44:	b8 0c 3a 10 00       	mov    $0x103a0c,%eax
  102e49:	66 a3 98 d3 17 00    	mov    %ax,0x17d398
  102e4f:	66 c7 05 9a d3 17 00 	movw   $0x8,0x17d39a
  102e56:	08 00 
  102e58:	0f b6 05 9c d3 17 00 	movzbl 0x17d39c,%eax
  102e5f:	83 e0 e0             	and    $0xffffffe0,%eax
  102e62:	a2 9c d3 17 00       	mov    %al,0x17d39c
  102e67:	0f b6 05 9c d3 17 00 	movzbl 0x17d39c,%eax
  102e6e:	83 e0 1f             	and    $0x1f,%eax
  102e71:	a2 9c d3 17 00       	mov    %al,0x17d39c
  102e76:	0f b6 05 9d d3 17 00 	movzbl 0x17d39d,%eax
  102e7d:	83 e0 f0             	and    $0xfffffff0,%eax
  102e80:	83 c8 0e             	or     $0xe,%eax
  102e83:	a2 9d d3 17 00       	mov    %al,0x17d39d
  102e88:	0f b6 05 9d d3 17 00 	movzbl 0x17d39d,%eax
  102e8f:	83 e0 ef             	and    $0xffffffef,%eax
  102e92:	a2 9d d3 17 00       	mov    %al,0x17d39d
  102e97:	0f b6 05 9d d3 17 00 	movzbl 0x17d39d,%eax
  102e9e:	83 e0 9f             	and    $0xffffff9f,%eax
  102ea1:	a2 9d d3 17 00       	mov    %al,0x17d39d
  102ea6:	0f b6 05 9d d3 17 00 	movzbl 0x17d39d,%eax
  102ead:	83 c8 80             	or     $0xffffff80,%eax
  102eb0:	a2 9d d3 17 00       	mov    %al,0x17d39d
  102eb5:	b8 0c 3a 10 00       	mov    $0x103a0c,%eax
  102eba:	c1 e8 10             	shr    $0x10,%eax
  102ebd:	66 a3 9e d3 17 00    	mov    %ax,0x17d39e
  102ec3:	b8 16 3a 10 00       	mov    $0x103a16,%eax
  102ec8:	66 a3 a0 d3 17 00    	mov    %ax,0x17d3a0
  102ece:	66 c7 05 a2 d3 17 00 	movw   $0x8,0x17d3a2
  102ed5:	08 00 
  102ed7:	0f b6 05 a4 d3 17 00 	movzbl 0x17d3a4,%eax
  102ede:	83 e0 e0             	and    $0xffffffe0,%eax
  102ee1:	a2 a4 d3 17 00       	mov    %al,0x17d3a4
  102ee6:	0f b6 05 a4 d3 17 00 	movzbl 0x17d3a4,%eax
  102eed:	83 e0 1f             	and    $0x1f,%eax
  102ef0:	a2 a4 d3 17 00       	mov    %al,0x17d3a4
  102ef5:	0f b6 05 a5 d3 17 00 	movzbl 0x17d3a5,%eax
  102efc:	83 e0 f0             	and    $0xfffffff0,%eax
  102eff:	83 c8 0e             	or     $0xe,%eax
  102f02:	a2 a5 d3 17 00       	mov    %al,0x17d3a5
  102f07:	0f b6 05 a5 d3 17 00 	movzbl 0x17d3a5,%eax
  102f0e:	83 e0 ef             	and    $0xffffffef,%eax
  102f11:	a2 a5 d3 17 00       	mov    %al,0x17d3a5
  102f16:	0f b6 05 a5 d3 17 00 	movzbl 0x17d3a5,%eax
  102f1d:	83 c8 60             	or     $0x60,%eax
  102f20:	a2 a5 d3 17 00       	mov    %al,0x17d3a5
  102f25:	0f b6 05 a5 d3 17 00 	movzbl 0x17d3a5,%eax
  102f2c:	83 c8 80             	or     $0xffffff80,%eax
  102f2f:	a2 a5 d3 17 00       	mov    %al,0x17d3a5
  102f34:	b8 16 3a 10 00       	mov    $0x103a16,%eax
  102f39:	c1 e8 10             	shr    $0x10,%eax
  102f3c:	66 a3 a6 d3 17 00    	mov    %ax,0x17d3a6
  102f42:	b8 20 3a 10 00       	mov    $0x103a20,%eax
  102f47:	66 a3 a8 d3 17 00    	mov    %ax,0x17d3a8
  102f4d:	66 c7 05 aa d3 17 00 	movw   $0x8,0x17d3aa
  102f54:	08 00 
  102f56:	0f b6 05 ac d3 17 00 	movzbl 0x17d3ac,%eax
  102f5d:	83 e0 e0             	and    $0xffffffe0,%eax
  102f60:	a2 ac d3 17 00       	mov    %al,0x17d3ac
  102f65:	0f b6 05 ac d3 17 00 	movzbl 0x17d3ac,%eax
  102f6c:	83 e0 1f             	and    $0x1f,%eax
  102f6f:	a2 ac d3 17 00       	mov    %al,0x17d3ac
  102f74:	0f b6 05 ad d3 17 00 	movzbl 0x17d3ad,%eax
  102f7b:	83 e0 f0             	and    $0xfffffff0,%eax
  102f7e:	83 c8 0e             	or     $0xe,%eax
  102f81:	a2 ad d3 17 00       	mov    %al,0x17d3ad
  102f86:	0f b6 05 ad d3 17 00 	movzbl 0x17d3ad,%eax
  102f8d:	83 e0 ef             	and    $0xffffffef,%eax
  102f90:	a2 ad d3 17 00       	mov    %al,0x17d3ad
  102f95:	0f b6 05 ad d3 17 00 	movzbl 0x17d3ad,%eax
  102f9c:	83 e0 9f             	and    $0xffffff9f,%eax
  102f9f:	a2 ad d3 17 00       	mov    %al,0x17d3ad
  102fa4:	0f b6 05 ad d3 17 00 	movzbl 0x17d3ad,%eax
  102fab:	83 c8 80             	or     $0xffffff80,%eax
  102fae:	a2 ad d3 17 00       	mov    %al,0x17d3ad
  102fb3:	b8 20 3a 10 00       	mov    $0x103a20,%eax
  102fb8:	c1 e8 10             	shr    $0x10,%eax
  102fbb:	66 a3 ae d3 17 00    	mov    %ax,0x17d3ae
  102fc1:	b8 2a 3a 10 00       	mov    $0x103a2a,%eax
  102fc6:	66 a3 b0 d3 17 00    	mov    %ax,0x17d3b0
  102fcc:	66 c7 05 b2 d3 17 00 	movw   $0x8,0x17d3b2
  102fd3:	08 00 
  102fd5:	0f b6 05 b4 d3 17 00 	movzbl 0x17d3b4,%eax
  102fdc:	83 e0 e0             	and    $0xffffffe0,%eax
  102fdf:	a2 b4 d3 17 00       	mov    %al,0x17d3b4
  102fe4:	0f b6 05 b4 d3 17 00 	movzbl 0x17d3b4,%eax
  102feb:	83 e0 1f             	and    $0x1f,%eax
  102fee:	a2 b4 d3 17 00       	mov    %al,0x17d3b4
  102ff3:	0f b6 05 b5 d3 17 00 	movzbl 0x17d3b5,%eax
  102ffa:	83 e0 f0             	and    $0xfffffff0,%eax
  102ffd:	83 c8 0e             	or     $0xe,%eax
  103000:	a2 b5 d3 17 00       	mov    %al,0x17d3b5
  103005:	0f b6 05 b5 d3 17 00 	movzbl 0x17d3b5,%eax
  10300c:	83 e0 ef             	and    $0xffffffef,%eax
  10300f:	a2 b5 d3 17 00       	mov    %al,0x17d3b5
  103014:	0f b6 05 b5 d3 17 00 	movzbl 0x17d3b5,%eax
  10301b:	83 e0 9f             	and    $0xffffff9f,%eax
  10301e:	a2 b5 d3 17 00       	mov    %al,0x17d3b5
  103023:	0f b6 05 b5 d3 17 00 	movzbl 0x17d3b5,%eax
  10302a:	83 c8 80             	or     $0xffffff80,%eax
  10302d:	a2 b5 d3 17 00       	mov    %al,0x17d3b5
  103032:	b8 2a 3a 10 00       	mov    $0x103a2a,%eax
  103037:	c1 e8 10             	shr    $0x10,%eax
  10303a:	66 a3 b6 d3 17 00    	mov    %ax,0x17d3b6
  103040:	c9                   	leave  
  103041:	c3                   	ret    

00103042 <trap_init>:
  103042:	55                   	push   %ebp
  103043:	89 e5                	mov    %esp,%ebp
  103045:	83 ec 08             	sub    $0x8,%esp
  103048:	e8 20 00 00 00       	call   10306d <cpu_onboot>
  10304d:	85 c0                	test   %eax,%eax
  10304f:	74 05                	je     103056 <trap_init+0x14>
  103051:	e8 ba ec ff ff       	call   101d10 <trap_init_idt>
  103056:	0f 01 1d 04 00 11 00 	lidtl  0x110004
  10305d:	e8 0b 00 00 00       	call   10306d <cpu_onboot>
  103062:	85 c0                	test   %eax,%eax
  103064:	74 05                	je     10306b <trap_init+0x29>
  103066:	e8 31 05 00 00       	call   10359c <trap_check_kernel>
  10306b:	c9                   	leave  
  10306c:	c3                   	ret    

0010306d <cpu_onboot>:
}

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  10306d:	55                   	push   %ebp
  10306e:	89 e5                	mov    %esp,%ebp
  103070:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  103073:	e8 0d 00 00 00       	call   103085 <cpu_cur>
  103078:	3d 00 f0 10 00       	cmp    $0x10f000,%eax
  10307d:	0f 94 c0             	sete   %al
  103080:	0f b6 c0             	movzbl %al,%eax
}
  103083:	c9                   	leave  
  103084:	c3                   	ret    

00103085 <cpu_cur>:
  103085:	55                   	push   %ebp
  103086:	89 e5                	mov    %esp,%ebp
  103088:	83 ec 28             	sub    $0x28,%esp
static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  10308b:	89 65 fc             	mov    %esp,0xfffffffc(%ebp)
        return esp;
  10308e:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  103091:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  103094:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  103097:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  10309c:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	assert(c->magic == CPU_MAGIC);
  10309f:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  1030a2:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  1030a8:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  1030ad:	74 24                	je     1030d3 <cpu_cur+0x4e>
  1030af:	c7 44 24 0c e0 c6 10 	movl   $0x10c6e0,0xc(%esp)
  1030b6:	00 
  1030b7:	c7 44 24 08 f6 c6 10 	movl   $0x10c6f6,0x8(%esp)
  1030be:	00 
  1030bf:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  1030c6:	00 
  1030c7:	c7 04 24 0b c7 10 00 	movl   $0x10c70b,(%esp)
  1030ce:	e8 65 d8 ff ff       	call   100938 <debug_panic>
	return c;
  1030d3:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
}
  1030d6:	c9                   	leave  
  1030d7:	c3                   	ret    

001030d8 <trap_name>:
  1030d8:	55                   	push   %ebp
  1030d9:	89 e5                	mov    %esp,%ebp
  1030db:	83 ec 04             	sub    $0x4,%esp
  1030de:	8b 45 08             	mov    0x8(%ebp),%eax
  1030e1:	83 f8 13             	cmp    $0x13,%eax
  1030e4:	77 0f                	ja     1030f5 <trap_name+0x1d>
  1030e6:	8b 45 08             	mov    0x8(%ebp),%eax
  1030e9:	8b 04 85 80 c8 10 00 	mov    0x10c880(,%eax,4),%eax
  1030f0:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  1030f3:	eb 2b                	jmp    103120 <trap_name+0x48>
  1030f5:	83 7d 08 30          	cmpl   $0x30,0x8(%ebp)
  1030f9:	75 09                	jne    103104 <trap_name+0x2c>
  1030fb:	c7 45 fc d0 c8 10 00 	movl   $0x10c8d0,0xfffffffc(%ebp)
  103102:	eb 1c                	jmp    103120 <trap_name+0x48>
  103104:	83 7d 08 1f          	cmpl   $0x1f,0x8(%ebp)
  103108:	7e 0f                	jle    103119 <trap_name+0x41>
  10310a:	83 7d 08 2f          	cmpl   $0x2f,0x8(%ebp)
  10310e:	7f 09                	jg     103119 <trap_name+0x41>
  103110:	c7 45 fc dc c8 10 00 	movl   $0x10c8dc,0xfffffffc(%ebp)
  103117:	eb 07                	jmp    103120 <trap_name+0x48>
  103119:	c7 45 fc 02 c8 10 00 	movl   $0x10c802,0xfffffffc(%ebp)
  103120:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  103123:	c9                   	leave  
  103124:	c3                   	ret    

00103125 <trap_print_regs>:
  103125:	55                   	push   %ebp
  103126:	89 e5                	mov    %esp,%ebp
  103128:	83 ec 08             	sub    $0x8,%esp
  10312b:	8b 45 08             	mov    0x8(%ebp),%eax
  10312e:	8b 00                	mov    (%eax),%eax
  103130:	89 44 24 04          	mov    %eax,0x4(%esp)
  103134:	c7 04 24 ef c8 10 00 	movl   $0x10c8ef,(%esp)
  10313b:	e8 2d 87 00 00       	call   10b86d <cprintf>
  103140:	8b 45 08             	mov    0x8(%ebp),%eax
  103143:	8b 40 04             	mov    0x4(%eax),%eax
  103146:	89 44 24 04          	mov    %eax,0x4(%esp)
  10314a:	c7 04 24 fe c8 10 00 	movl   $0x10c8fe,(%esp)
  103151:	e8 17 87 00 00       	call   10b86d <cprintf>
  103156:	8b 45 08             	mov    0x8(%ebp),%eax
  103159:	8b 40 08             	mov    0x8(%eax),%eax
  10315c:	89 44 24 04          	mov    %eax,0x4(%esp)
  103160:	c7 04 24 0d c9 10 00 	movl   $0x10c90d,(%esp)
  103167:	e8 01 87 00 00       	call   10b86d <cprintf>
  10316c:	8b 45 08             	mov    0x8(%ebp),%eax
  10316f:	8b 40 10             	mov    0x10(%eax),%eax
  103172:	89 44 24 04          	mov    %eax,0x4(%esp)
  103176:	c7 04 24 1c c9 10 00 	movl   $0x10c91c,(%esp)
  10317d:	e8 eb 86 00 00       	call   10b86d <cprintf>
  103182:	8b 45 08             	mov    0x8(%ebp),%eax
  103185:	8b 40 14             	mov    0x14(%eax),%eax
  103188:	89 44 24 04          	mov    %eax,0x4(%esp)
  10318c:	c7 04 24 2b c9 10 00 	movl   $0x10c92b,(%esp)
  103193:	e8 d5 86 00 00       	call   10b86d <cprintf>
  103198:	8b 45 08             	mov    0x8(%ebp),%eax
  10319b:	8b 40 18             	mov    0x18(%eax),%eax
  10319e:	89 44 24 04          	mov    %eax,0x4(%esp)
  1031a2:	c7 04 24 3a c9 10 00 	movl   $0x10c93a,(%esp)
  1031a9:	e8 bf 86 00 00       	call   10b86d <cprintf>
  1031ae:	8b 45 08             	mov    0x8(%ebp),%eax
  1031b1:	8b 40 1c             	mov    0x1c(%eax),%eax
  1031b4:	89 44 24 04          	mov    %eax,0x4(%esp)
  1031b8:	c7 04 24 49 c9 10 00 	movl   $0x10c949,(%esp)
  1031bf:	e8 a9 86 00 00       	call   10b86d <cprintf>
  1031c4:	c9                   	leave  
  1031c5:	c3                   	ret    

001031c6 <trap_print>:
  1031c6:	55                   	push   %ebp
  1031c7:	89 e5                	mov    %esp,%ebp
  1031c9:	83 ec 18             	sub    $0x18,%esp
  1031cc:	8b 45 08             	mov    0x8(%ebp),%eax
  1031cf:	89 44 24 04          	mov    %eax,0x4(%esp)
  1031d3:	c7 04 24 58 c9 10 00 	movl   $0x10c958,(%esp)
  1031da:	e8 8e 86 00 00       	call   10b86d <cprintf>
  1031df:	8b 45 08             	mov    0x8(%ebp),%eax
  1031e2:	89 04 24             	mov    %eax,(%esp)
  1031e5:	e8 3b ff ff ff       	call   103125 <trap_print_regs>
  1031ea:	8b 45 08             	mov    0x8(%ebp),%eax
  1031ed:	0f b7 40 28          	movzwl 0x28(%eax),%eax
  1031f1:	0f b7 c0             	movzwl %ax,%eax
  1031f4:	89 44 24 04          	mov    %eax,0x4(%esp)
  1031f8:	c7 04 24 6a c9 10 00 	movl   $0x10c96a,(%esp)
  1031ff:	e8 69 86 00 00       	call   10b86d <cprintf>
  103204:	8b 45 08             	mov    0x8(%ebp),%eax
  103207:	0f b7 40 2c          	movzwl 0x2c(%eax),%eax
  10320b:	0f b7 c0             	movzwl %ax,%eax
  10320e:	89 44 24 04          	mov    %eax,0x4(%esp)
  103212:	c7 04 24 7d c9 10 00 	movl   $0x10c97d,(%esp)
  103219:	e8 4f 86 00 00       	call   10b86d <cprintf>
  10321e:	8b 45 08             	mov    0x8(%ebp),%eax
  103221:	8b 40 30             	mov    0x30(%eax),%eax
  103224:	89 04 24             	mov    %eax,(%esp)
  103227:	e8 ac fe ff ff       	call   1030d8 <trap_name>
  10322c:	89 c2                	mov    %eax,%edx
  10322e:	8b 45 08             	mov    0x8(%ebp),%eax
  103231:	8b 40 30             	mov    0x30(%eax),%eax
  103234:	89 54 24 08          	mov    %edx,0x8(%esp)
  103238:	89 44 24 04          	mov    %eax,0x4(%esp)
  10323c:	c7 04 24 90 c9 10 00 	movl   $0x10c990,(%esp)
  103243:	e8 25 86 00 00       	call   10b86d <cprintf>
  103248:	8b 45 08             	mov    0x8(%ebp),%eax
  10324b:	8b 40 34             	mov    0x34(%eax),%eax
  10324e:	89 44 24 04          	mov    %eax,0x4(%esp)
  103252:	c7 04 24 a2 c9 10 00 	movl   $0x10c9a2,(%esp)
  103259:	e8 0f 86 00 00       	call   10b86d <cprintf>
  10325e:	8b 45 08             	mov    0x8(%ebp),%eax
  103261:	8b 40 38             	mov    0x38(%eax),%eax
  103264:	89 44 24 04          	mov    %eax,0x4(%esp)
  103268:	c7 04 24 b1 c9 10 00 	movl   $0x10c9b1,(%esp)
  10326f:	e8 f9 85 00 00       	call   10b86d <cprintf>
  103274:	8b 45 08             	mov    0x8(%ebp),%eax
  103277:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
  10327b:	0f b7 c0             	movzwl %ax,%eax
  10327e:	89 44 24 04          	mov    %eax,0x4(%esp)
  103282:	c7 04 24 c0 c9 10 00 	movl   $0x10c9c0,(%esp)
  103289:	e8 df 85 00 00       	call   10b86d <cprintf>
  10328e:	8b 45 08             	mov    0x8(%ebp),%eax
  103291:	8b 40 40             	mov    0x40(%eax),%eax
  103294:	89 44 24 04          	mov    %eax,0x4(%esp)
  103298:	c7 04 24 d3 c9 10 00 	movl   $0x10c9d3,(%esp)
  10329f:	e8 c9 85 00 00       	call   10b86d <cprintf>
  1032a4:	8b 45 08             	mov    0x8(%ebp),%eax
  1032a7:	8b 40 44             	mov    0x44(%eax),%eax
  1032aa:	89 44 24 04          	mov    %eax,0x4(%esp)
  1032ae:	c7 04 24 e2 c9 10 00 	movl   $0x10c9e2,(%esp)
  1032b5:	e8 b3 85 00 00       	call   10b86d <cprintf>
  1032ba:	8b 45 08             	mov    0x8(%ebp),%eax
  1032bd:	0f b7 40 48          	movzwl 0x48(%eax),%eax
  1032c1:	0f b7 c0             	movzwl %ax,%eax
  1032c4:	89 44 24 04          	mov    %eax,0x4(%esp)
  1032c8:	c7 04 24 f1 c9 10 00 	movl   $0x10c9f1,(%esp)
  1032cf:	e8 99 85 00 00       	call   10b86d <cprintf>
  1032d4:	c9                   	leave  
  1032d5:	c3                   	ret    

001032d6 <trap>:
  1032d6:	55                   	push   %ebp
  1032d7:	89 e5                	mov    %esp,%ebp
  1032d9:	53                   	push   %ebx
  1032da:	83 ec 24             	sub    $0x24,%esp
  1032dd:	fc                   	cld    
  1032de:	8b 45 08             	mov    0x8(%ebp),%eax
  1032e1:	8b 40 30             	mov    0x30(%eax),%eax
  1032e4:	83 f8 0e             	cmp    $0xe,%eax
  1032e7:	75 0b                	jne    1032f4 <trap+0x1e>
  1032e9:	8b 45 08             	mov    0x8(%ebp),%eax
  1032ec:	89 04 24             	mov    %eax,(%esp)
  1032ef:	e8 45 41 00 00       	call   107439 <pmap_pagefault>
  1032f4:	e8 8c fd ff ff       	call   103085 <cpu_cur>
  1032f9:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  1032fc:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  1032ff:	8b 80 a0 00 00 00    	mov    0xa0(%eax),%eax
  103305:	85 c0                	test   %eax,%eax
  103307:	74 1e                	je     103327 <trap+0x51>
  103309:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  10330c:	8b 90 a0 00 00 00    	mov    0xa0(%eax),%edx
  103312:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  103315:	8b 80 a4 00 00 00    	mov    0xa4(%eax),%eax
  10331b:	89 44 24 04          	mov    %eax,0x4(%esp)
  10331f:	8b 45 08             	mov    0x8(%ebp),%eax
  103322:	89 04 24             	mov    %eax,(%esp)
  103325:	ff d2                	call   *%edx
  103327:	e8 59 fd ff ff       	call   103085 <cpu_cur>
  10332c:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  103332:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
  103335:	8b 45 08             	mov    0x8(%ebp),%eax
  103338:	8b 40 30             	mov    0x30(%eax),%eax
  10333b:	83 e8 03             	sub    $0x3,%eax
  10333e:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  103341:	83 7d e8 2f          	cmpl   $0x2f,0xffffffe8(%ebp)
  103345:	0f 87 80 01 00 00    	ja     1034cb <trap+0x1f5>
  10334b:	8b 55 e8             	mov    0xffffffe8(%ebp),%edx
  10334e:	8b 04 95 7c ca 10 00 	mov    0x10ca7c(,%edx,4),%eax
  103355:	ff e0                	jmp    *%eax
  103357:	8b 45 08             	mov    0x8(%ebp),%eax
  10335a:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
  10335e:	0f b7 c0             	movzwl %ax,%eax
  103361:	83 e0 03             	and    $0x3,%eax
  103364:	85 c0                	test   %eax,%eax
  103366:	75 24                	jne    10338c <trap+0xb6>
  103368:	c7 44 24 0c 04 ca 10 	movl   $0x10ca04,0xc(%esp)
  10336f:	00 
  103370:	c7 44 24 08 f6 c6 10 	movl   $0x10c6f6,0x8(%esp)
  103377:	00 
  103378:	c7 44 24 04 fd 00 00 	movl   $0xfd,0x4(%esp)
  10337f:	00 
  103380:	c7 04 24 0f ca 10 00 	movl   $0x10ca0f,(%esp)
  103387:	e8 ac d5 ff ff       	call   100938 <debug_panic>
  10338c:	8b 45 08             	mov    0x8(%ebp),%eax
  10338f:	89 04 24             	mov    %eax,(%esp)
  103392:	e8 e4 2a 00 00       	call   105e7b <syscall>
  103397:	e9 2f 01 00 00       	jmp    1034cb <trap+0x1f5>
  10339c:	8b 45 08             	mov    0x8(%ebp),%eax
  10339f:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
  1033a3:	0f b7 c0             	movzwl %ax,%eax
  1033a6:	83 e0 03             	and    $0x3,%eax
  1033a9:	85 c0                	test   %eax,%eax
  1033ab:	75 24                	jne    1033d1 <trap+0xfb>
  1033ad:	c7 44 24 0c 04 ca 10 	movl   $0x10ca04,0xc(%esp)
  1033b4:	00 
  1033b5:	c7 44 24 08 f6 c6 10 	movl   $0x10c6f6,0x8(%esp)
  1033bc:	00 
  1033bd:	c7 44 24 04 03 01 00 	movl   $0x103,0x4(%esp)
  1033c4:	00 
  1033c5:	c7 04 24 0f ca 10 00 	movl   $0x10ca0f,(%esp)
  1033cc:	e8 67 d5 ff ff       	call   100938 <debug_panic>
  1033d1:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  1033d8:	00 
  1033d9:	8b 45 08             	mov    0x8(%ebp),%eax
  1033dc:	89 04 24             	mov    %eax,(%esp)
  1033df:	e8 0a 18 00 00       	call   104bee <proc_ret>
  1033e4:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  1033e7:	8b 80 9c 04 00 00    	mov    0x49c(%eax),%eax
  1033ed:	89 c2                	mov    %eax,%edx
  1033ef:	83 ca 01             	or     $0x1,%edx
  1033f2:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  1033f5:	89 90 9c 04 00 00    	mov    %edx,0x49c(%eax)
static gcc_inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
  1033fb:	0f 20 c0             	mov    %cr0,%eax
  1033fe:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	return val;
  103401:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  103404:	83 e0 f7             	and    $0xfffffff7,%eax
  103407:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  10340a:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10340d:	0f 22 c0             	mov    %eax,%cr0
  103410:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  103413:	0f ae 88 a0 04 00 00 	fxrstor 0x4a0(%eax)
  10341a:	8b 45 08             	mov    0x8(%ebp),%eax
  10341d:	89 04 24             	mov    %eax,(%esp)
  103420:	e8 3b 06 00 00       	call   103a60 <trap_return>
  103425:	e8 02 79 00 00       	call   10ad2c <lapic_eoi>
  10342a:	8b 45 08             	mov    0x8(%ebp),%eax
  10342d:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
  103431:	0f b7 c0             	movzwl %ax,%eax
  103434:	83 e0 03             	and    $0x3,%eax
  103437:	85 c0                	test   %eax,%eax
  103439:	74 0b                	je     103446 <trap+0x170>
  10343b:	8b 45 08             	mov    0x8(%ebp),%eax
  10343e:	89 04 24             	mov    %eax,(%esp)
  103441:	e8 26 17 00 00       	call   104b6c <proc_yield>
  103446:	8b 45 08             	mov    0x8(%ebp),%eax
  103449:	89 04 24             	mov    %eax,(%esp)
  10344c:	e8 0f 06 00 00       	call   103a60 <trap_return>
  103451:	e8 fb 78 00 00       	call   10ad51 <lapic_errintr>
  103456:	8b 45 08             	mov    0x8(%ebp),%eax
  103459:	89 04 24             	mov    %eax,(%esp)
  10345c:	e8 ff 05 00 00       	call   103a60 <trap_return>
  103461:	e8 76 72 00 00       	call   10a6dc <kbd_intr>
  103466:	e8 c1 78 00 00       	call   10ad2c <lapic_eoi>
  10346b:	8b 45 08             	mov    0x8(%ebp),%eax
  10346e:	89 04 24             	mov    %eax,(%esp)
  103471:	e8 ea 05 00 00       	call   103a60 <trap_return>
  103476:	e8 b1 78 00 00       	call   10ad2c <lapic_eoi>
  10347b:	e8 24 73 00 00       	call   10a7a4 <serial_intr>
  103480:	8b 45 08             	mov    0x8(%ebp),%eax
  103483:	89 04 24             	mov    %eax,(%esp)
  103486:	e8 d5 05 00 00       	call   103a60 <trap_return>
  10348b:	8b 45 08             	mov    0x8(%ebp),%eax
  10348e:	8b 48 38             	mov    0x38(%eax),%ecx
  103491:	8b 45 08             	mov    0x8(%ebp),%eax
  103494:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
  103498:	0f b7 d0             	movzwl %ax,%edx
  10349b:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  10349e:	0f b6 80 ac 00 00 00 	movzbl 0xac(%eax),%eax
  1034a5:	0f b6 c0             	movzbl %al,%eax
  1034a8:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  1034ac:	89 54 24 08          	mov    %edx,0x8(%esp)
  1034b0:	89 44 24 04          	mov    %eax,0x4(%esp)
  1034b4:	c7 04 24 20 ca 10 00 	movl   $0x10ca20,(%esp)
  1034bb:	e8 ad 83 00 00       	call   10b86d <cprintf>
  1034c0:	8b 45 08             	mov    0x8(%ebp),%eax
  1034c3:	89 04 24             	mov    %eax,(%esp)
  1034c6:	e8 95 05 00 00       	call   103a60 <trap_return>
  1034cb:	8b 45 08             	mov    0x8(%ebp),%eax
  1034ce:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
  1034d2:	0f b7 c0             	movzwl %ax,%eax
  1034d5:	83 e0 03             	and    $0x3,%eax
  1034d8:	85 c0                	test   %eax,%eax
  1034da:	74 4b                	je     103527 <trap+0x251>
  1034dc:	e8 a4 fb ff ff       	call   103085 <cpu_cur>
  1034e1:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  1034e7:	8b 58 38             	mov    0x38(%eax),%ebx
  1034ea:	e8 96 fb ff ff       	call   103085 <cpu_cur>
  1034ef:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  1034f5:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  1034f9:	89 44 24 04          	mov    %eax,0x4(%esp)
  1034fd:	c7 04 24 44 ca 10 00 	movl   $0x10ca44,(%esp)
  103504:	e8 64 83 00 00       	call   10b86d <cprintf>
  103509:	8b 45 08             	mov    0x8(%ebp),%eax
  10350c:	89 04 24             	mov    %eax,(%esp)
  10350f:	e8 b2 fc ff ff       	call   1031c6 <trap_print>
  103514:	c7 44 24 04 ff ff ff 	movl   $0xffffffff,0x4(%esp)
  10351b:	ff 
  10351c:	8b 45 08             	mov    0x8(%ebp),%eax
  10351f:	89 04 24             	mov    %eax,(%esp)
  103522:	e8 c7 16 00 00       	call   104bee <proc_ret>
  103527:	c7 04 24 40 1d 18 00 	movl   $0x181d40,(%esp)
  10352e:	e8 dc 0a 00 00       	call   10400f <spinlock_holding>
  103533:	85 c0                	test   %eax,%eax
  103535:	74 0c                	je     103543 <trap+0x26d>
  103537:	c7 04 24 40 1d 18 00 	movl   $0x181d40,(%esp)
  10353e:	e8 72 0a 00 00       	call   103fb5 <spinlock_release>
  103543:	8b 45 08             	mov    0x8(%ebp),%eax
  103546:	89 04 24             	mov    %eax,(%esp)
  103549:	e8 78 fc ff ff       	call   1031c6 <trap_print>
  10354e:	c7 44 24 08 6c ca 10 	movl   $0x10ca6c,0x8(%esp)
  103555:	00 
  103556:	c7 44 24 04 8e 01 00 	movl   $0x18e,0x4(%esp)
  10355d:	00 
  10355e:	c7 04 24 0f ca 10 00 	movl   $0x10ca0f,(%esp)
  103565:	e8 ce d3 ff ff       	call   100938 <debug_panic>

0010356a <trap_check_recover>:
  10356a:	55                   	push   %ebp
  10356b:	89 e5                	mov    %esp,%ebp
  10356d:	83 ec 18             	sub    $0x18,%esp
  103570:	8b 45 0c             	mov    0xc(%ebp),%eax
  103573:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  103576:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  103579:	8b 00                	mov    (%eax),%eax
  10357b:	89 c2                	mov    %eax,%edx
  10357d:	8b 45 08             	mov    0x8(%ebp),%eax
  103580:	89 50 38             	mov    %edx,0x38(%eax)
  103583:	8b 45 08             	mov    0x8(%ebp),%eax
  103586:	8b 40 30             	mov    0x30(%eax),%eax
  103589:	89 c2                	mov    %eax,%edx
  10358b:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  10358e:	89 50 04             	mov    %edx,0x4(%eax)
  103591:	8b 45 08             	mov    0x8(%ebp),%eax
  103594:	89 04 24             	mov    %eax,(%esp)
  103597:	e8 c4 04 00 00       	call   103a60 <trap_return>

0010359c <trap_check_kernel>:
  10359c:	55                   	push   %ebp
  10359d:	89 e5                	mov    %esp,%ebp
  10359f:	83 ec 28             	sub    $0x28,%esp
}

static gcc_inline uint32_t
rcr2(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr2,%0" : "=r" (val));
	return val;
}

static gcc_inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
}

static gcc_inline uint32_t
rcr3(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr3,%0" : "=r" (val));
	return val;
}

static gcc_inline void
lcr4(uint32_t val)
{
	__asm __volatile("movl %0,%%cr4" : : "r" (val));
}

static gcc_inline uint32_t
rcr4(void)
{
	uint32_t cr4;
	__asm __volatile("movl %%cr4,%0" : "=r" (cr4));
	return cr4;
}

static gcc_inline void
tlbflush(void)
{
	uint32_t cr3;
	__asm __volatile("movl %%cr3,%0" : "=r" (cr3));
	__asm __volatile("movl %0,%%cr3" : : "r" (cr3));
}

static gcc_inline uint32_t
read_eflags(void)
{
        uint32_t eflags;
        __asm __volatile("pushfl; popl %0" : "=rm" (eflags));
        return eflags;
}

static gcc_inline void
write_eflags(uint32_t eflags)
{
        __asm __volatile("pushl %0; popfl" : : "rm" (eflags));
}

static gcc_inline uint32_t
read_ebp(void)
{
        uint32_t ebp;
        __asm __volatile("movl %%ebp,%0" : "=rm" (ebp));
        return ebp;
}

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
        return esp;
}

static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  1035a2:	8c 4d fe             	movw   %cs,0xfffffffe(%ebp)
        return cs;
  1035a5:	0f b7 45 fe          	movzwl 0xfffffffe(%ebp),%eax
  1035a9:	0f b7 c0             	movzwl %ax,%eax
  1035ac:	83 e0 03             	and    $0x3,%eax
  1035af:	85 c0                	test   %eax,%eax
  1035b1:	74 24                	je     1035d7 <trap_check_kernel+0x3b>
  1035b3:	c7 44 24 0c 3c cb 10 	movl   $0x10cb3c,0xc(%esp)
  1035ba:	00 
  1035bb:	c7 44 24 08 f6 c6 10 	movl   $0x10c6f6,0x8(%esp)
  1035c2:	00 
  1035c3:	c7 44 24 04 a2 01 00 	movl   $0x1a2,0x4(%esp)
  1035ca:	00 
  1035cb:	c7 04 24 0f ca 10 00 	movl   $0x10ca0f,(%esp)
  1035d2:	e8 61 d3 ff ff       	call   100938 <debug_panic>
  1035d7:	e8 a9 fa ff ff       	call   103085 <cpu_cur>
  1035dc:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  1035df:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1035e2:	c7 80 a0 00 00 00 6a 	movl   $0x10356a,0xa0(%eax)
  1035e9:	35 10 00 
  1035ec:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1035ef:	05 a4 00 00 00       	add    $0xa4,%eax
  1035f4:	89 04 24             	mov    %eax,(%esp)
  1035f7:	e8 96 00 00 00       	call   103692 <trap_check>
  1035fc:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1035ff:	c7 80 a0 00 00 00 00 	movl   $0x0,0xa0(%eax)
  103606:	00 00 00 
  103609:	c7 04 24 54 cb 10 00 	movl   $0x10cb54,(%esp)
  103610:	e8 58 82 00 00       	call   10b86d <cprintf>
  103615:	c9                   	leave  
  103616:	c3                   	ret    

00103617 <trap_check_user>:
  103617:	55                   	push   %ebp
  103618:	89 e5                	mov    %esp,%ebp
  10361a:	83 ec 28             	sub    $0x28,%esp
  10361d:	8c 4d fe             	movw   %cs,0xfffffffe(%ebp)
  103620:	0f b7 45 fe          	movzwl 0xfffffffe(%ebp),%eax
  103624:	0f b7 c0             	movzwl %ax,%eax
  103627:	83 e0 03             	and    $0x3,%eax
  10362a:	83 f8 03             	cmp    $0x3,%eax
  10362d:	74 24                	je     103653 <trap_check_user+0x3c>
  10362f:	c7 44 24 0c 74 cb 10 	movl   $0x10cb74,0xc(%esp)
  103636:	00 
  103637:	c7 44 24 08 f6 c6 10 	movl   $0x10c6f6,0x8(%esp)
  10363e:	00 
  10363f:	c7 44 24 04 b6 01 00 	movl   $0x1b6,0x4(%esp)
  103646:	00 
  103647:	c7 04 24 0f ca 10 00 	movl   $0x10ca0f,(%esp)
  10364e:	e8 e5 d2 ff ff       	call   100938 <debug_panic>
  103653:	c7 45 f8 00 f0 10 00 	movl   $0x10f000,0xfffffff8(%ebp)
  10365a:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10365d:	c7 80 a0 00 00 00 6a 	movl   $0x10356a,0xa0(%eax)
  103664:	35 10 00 
  103667:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10366a:	05 a4 00 00 00       	add    $0xa4,%eax
  10366f:	89 04 24             	mov    %eax,(%esp)
  103672:	e8 1b 00 00 00       	call   103692 <trap_check>
  103677:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10367a:	c7 80 a0 00 00 00 00 	movl   $0x0,0xa0(%eax)
  103681:	00 00 00 
  103684:	c7 04 24 89 cb 10 00 	movl   $0x10cb89,(%esp)
  10368b:	e8 dd 81 00 00       	call   10b86d <cprintf>
  103690:	c9                   	leave  
  103691:	c3                   	ret    

00103692 <trap_check>:
  103692:	55                   	push   %ebp
  103693:	89 e5                	mov    %esp,%ebp
  103695:	57                   	push   %edi
  103696:	56                   	push   %esi
  103697:	53                   	push   %ebx
  103698:	83 ec 3c             	sub    $0x3c,%esp
  10369b:	c7 45 ec ce fa ed fe 	movl   $0xfeedface,0xffffffec(%ebp)
  1036a2:	8b 55 08             	mov    0x8(%ebp),%edx
  1036a5:	8d 45 e4             	lea    0xffffffe4(%ebp),%eax
  1036a8:	89 02                	mov    %eax,(%edx)
  1036aa:	c7 45 e4 b8 36 10 00 	movl   $0x1036b8,0xffffffe4(%ebp)
  1036b1:	b8 00 00 00 00       	mov    $0x0,%eax
  1036b6:	f7 f0                	div    %eax

001036b8 <after_div0>:
  1036b8:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  1036bb:	85 c0                	test   %eax,%eax
  1036bd:	74 24                	je     1036e3 <after_div0+0x2b>
  1036bf:	c7 44 24 0c a7 cb 10 	movl   $0x10cba7,0xc(%esp)
  1036c6:	00 
  1036c7:	c7 44 24 08 f6 c6 10 	movl   $0x10c6f6,0x8(%esp)
  1036ce:	00 
  1036cf:	c7 44 24 04 d9 01 00 	movl   $0x1d9,0x4(%esp)
  1036d6:	00 
  1036d7:	c7 04 24 0f ca 10 00 	movl   $0x10ca0f,(%esp)
  1036de:	e8 55 d2 ff ff       	call   100938 <debug_panic>
  1036e3:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  1036e6:	3d ce fa ed fe       	cmp    $0xfeedface,%eax
  1036eb:	74 24                	je     103711 <after_div0+0x59>
  1036ed:	c7 44 24 0c bf cb 10 	movl   $0x10cbbf,0xc(%esp)
  1036f4:	00 
  1036f5:	c7 44 24 08 f6 c6 10 	movl   $0x10c6f6,0x8(%esp)
  1036fc:	00 
  1036fd:	c7 44 24 04 de 01 00 	movl   $0x1de,0x4(%esp)
  103704:	00 
  103705:	c7 04 24 0f ca 10 00 	movl   $0x10ca0f,(%esp)
  10370c:	e8 27 d2 ff ff       	call   100938 <debug_panic>
  103711:	c7 45 e4 19 37 10 00 	movl   $0x103719,0xffffffe4(%ebp)
  103718:	cc                   	int3   

00103719 <after_breakpoint>:
  103719:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  10371c:	83 f8 03             	cmp    $0x3,%eax
  10371f:	74 24                	je     103745 <after_breakpoint+0x2c>
  103721:	c7 44 24 0c d4 cb 10 	movl   $0x10cbd4,0xc(%esp)
  103728:	00 
  103729:	c7 44 24 08 f6 c6 10 	movl   $0x10c6f6,0x8(%esp)
  103730:	00 
  103731:	c7 44 24 04 e3 01 00 	movl   $0x1e3,0x4(%esp)
  103738:	00 
  103739:	c7 04 24 0f ca 10 00 	movl   $0x10ca0f,(%esp)
  103740:	e8 f3 d1 ff ff       	call   100938 <debug_panic>
  103745:	c7 45 e4 54 37 10 00 	movl   $0x103754,0xffffffe4(%ebp)
  10374c:	b8 00 00 00 70       	mov    $0x70000000,%eax
  103751:	01 c0                	add    %eax,%eax
  103753:	ce                   	into   

00103754 <after_overflow>:
  103754:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  103757:	83 f8 04             	cmp    $0x4,%eax
  10375a:	74 24                	je     103780 <after_overflow+0x2c>
  10375c:	c7 44 24 0c eb cb 10 	movl   $0x10cbeb,0xc(%esp)
  103763:	00 
  103764:	c7 44 24 08 f6 c6 10 	movl   $0x10c6f6,0x8(%esp)
  10376b:	00 
  10376c:	c7 44 24 04 e8 01 00 	movl   $0x1e8,0x4(%esp)
  103773:	00 
  103774:	c7 04 24 0f ca 10 00 	movl   $0x10ca0f,(%esp)
  10377b:	e8 b8 d1 ff ff       	call   100938 <debug_panic>
  103780:	c7 45 e4 9d 37 10 00 	movl   $0x10379d,0xffffffe4(%ebp)
  103787:	c7 45 dc 01 00 00 00 	movl   $0x1,0xffffffdc(%ebp)
  10378e:	c7 45 e0 03 00 00 00 	movl   $0x3,0xffffffe0(%ebp)
  103795:	b8 00 00 00 00       	mov    $0x0,%eax
  10379a:	62 45 dc             	bound  %eax,0xffffffdc(%ebp)

0010379d <after_bound>:
  10379d:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  1037a0:	83 f8 05             	cmp    $0x5,%eax
  1037a3:	74 24                	je     1037c9 <after_bound+0x2c>
  1037a5:	c7 44 24 0c 02 cc 10 	movl   $0x10cc02,0xc(%esp)
  1037ac:	00 
  1037ad:	c7 44 24 08 f6 c6 10 	movl   $0x10c6f6,0x8(%esp)
  1037b4:	00 
  1037b5:	c7 44 24 04 ee 01 00 	movl   $0x1ee,0x4(%esp)
  1037bc:	00 
  1037bd:	c7 04 24 0f ca 10 00 	movl   $0x10ca0f,(%esp)
  1037c4:	e8 6f d1 ff ff       	call   100938 <debug_panic>
  1037c9:	c7 45 e4 d2 37 10 00 	movl   $0x1037d2,0xffffffe4(%ebp)
  1037d0:	0f 0b                	ud2a   

001037d2 <after_illegal>:
  1037d2:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  1037d5:	83 f8 06             	cmp    $0x6,%eax
  1037d8:	74 24                	je     1037fe <after_illegal+0x2c>
  1037da:	c7 44 24 0c 19 cc 10 	movl   $0x10cc19,0xc(%esp)
  1037e1:	00 
  1037e2:	c7 44 24 08 f6 c6 10 	movl   $0x10c6f6,0x8(%esp)
  1037e9:	00 
  1037ea:	c7 44 24 04 f3 01 00 	movl   $0x1f3,0x4(%esp)
  1037f1:	00 
  1037f2:	c7 04 24 0f ca 10 00 	movl   $0x10ca0f,(%esp)
  1037f9:	e8 3a d1 ff ff       	call   100938 <debug_panic>
  1037fe:	c7 45 e4 0c 38 10 00 	movl   $0x10380c,0xffffffe4(%ebp)
  103805:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  10380a:	8e e0                	movl   %eax,%fs

0010380c <after_gpfault>:
  10380c:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  10380f:	83 f8 0d             	cmp    $0xd,%eax
  103812:	74 24                	je     103838 <after_gpfault+0x2c>
  103814:	c7 44 24 0c 30 cc 10 	movl   $0x10cc30,0xc(%esp)
  10381b:	00 
  10381c:	c7 44 24 08 f6 c6 10 	movl   $0x10c6f6,0x8(%esp)
  103823:	00 
  103824:	c7 44 24 04 f8 01 00 	movl   $0x1f8,0x4(%esp)
  10382b:	00 
  10382c:	c7 04 24 0f ca 10 00 	movl   $0x10ca0f,(%esp)
  103833:	e8 00 d1 ff ff       	call   100938 <debug_panic>
  103838:	8c 4d f2             	movw   %cs,0xfffffff2(%ebp)
  10383b:	0f b7 45 f2          	movzwl 0xfffffff2(%ebp),%eax
  10383f:	0f b7 c0             	movzwl %ax,%eax
  103842:	83 e0 03             	and    $0x3,%eax
  103845:	85 c0                	test   %eax,%eax
  103847:	74 3a                	je     103883 <after_priv+0x2c>
  103849:	c7 45 e4 57 38 10 00 	movl   $0x103857,0xffffffe4(%ebp)
  103850:	0f 01 1d 04 00 11 00 	lidtl  0x110004

00103857 <after_priv>:
  103857:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  10385a:	83 f8 0d             	cmp    $0xd,%eax
  10385d:	74 24                	je     103883 <after_priv+0x2c>
  10385f:	c7 44 24 0c 30 cc 10 	movl   $0x10cc30,0xc(%esp)
  103866:	00 
  103867:	c7 44 24 08 f6 c6 10 	movl   $0x10c6f6,0x8(%esp)
  10386e:	00 
  10386f:	c7 44 24 04 fe 01 00 	movl   $0x1fe,0x4(%esp)
  103876:	00 
  103877:	c7 04 24 0f ca 10 00 	movl   $0x10ca0f,(%esp)
  10387e:	e8 b5 d0 ff ff       	call   100938 <debug_panic>
  103883:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  103886:	3d ce fa ed fe       	cmp    $0xfeedface,%eax
  10388b:	74 24                	je     1038b1 <after_priv+0x5a>
  10388d:	c7 44 24 0c bf cb 10 	movl   $0x10cbbf,0xc(%esp)
  103894:	00 
  103895:	c7 44 24 08 f6 c6 10 	movl   $0x10c6f6,0x8(%esp)
  10389c:	00 
  10389d:	c7 44 24 04 02 02 00 	movl   $0x202,0x4(%esp)
  1038a4:	00 
  1038a5:	c7 04 24 0f ca 10 00 	movl   $0x10ca0f,(%esp)
  1038ac:	e8 87 d0 ff ff       	call   100938 <debug_panic>
  1038b1:	8b 45 08             	mov    0x8(%ebp),%eax
  1038b4:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  1038ba:	83 c4 3c             	add    $0x3c,%esp
  1038bd:	5b                   	pop    %ebx
  1038be:	5e                   	pop    %esi
  1038bf:	5f                   	pop    %edi
  1038c0:	5d                   	pop    %ebp
  1038c1:	c3                   	ret    
  1038c2:	90                   	nop    
  1038c3:	90                   	nop    
  1038c4:	90                   	nop    
  1038c5:	90                   	nop    
  1038c6:	90                   	nop    
  1038c7:	90                   	nop    
  1038c8:	90                   	nop    
  1038c9:	90                   	nop    
  1038ca:	90                   	nop    
  1038cb:	90                   	nop    
  1038cc:	90                   	nop    
  1038cd:	90                   	nop    
  1038ce:	90                   	nop    
  1038cf:	90                   	nop    

001038d0 <Xdivide>:

.text

/* CPU traps */
TRAPHANDLER_NOEC(Xdivide, T_DIVIDE)
  1038d0:	6a 00                	push   $0x0
  1038d2:	6a 00                	push   $0x0
  1038d4:	e9 67 01 00 00       	jmp    103a40 <_alltraps>
  1038d9:	90                   	nop    

001038da <Xdebug>:
TRAPHANDLER_NOEC(Xdebug,  T_DEBUG)
  1038da:	6a 00                	push   $0x0
  1038dc:	6a 01                	push   $0x1
  1038de:	e9 5d 01 00 00       	jmp    103a40 <_alltraps>
  1038e3:	90                   	nop    

001038e4 <Xnmi>:
TRAPHANDLER_NOEC(Xnmi,    T_NMI)
  1038e4:	6a 00                	push   $0x0
  1038e6:	6a 02                	push   $0x2
  1038e8:	e9 53 01 00 00       	jmp    103a40 <_alltraps>
  1038ed:	90                   	nop    

001038ee <Xbrkpt>:
TRAPHANDLER_NOEC(Xbrkpt,  T_BRKPT)
  1038ee:	6a 00                	push   $0x0
  1038f0:	6a 03                	push   $0x3
  1038f2:	e9 49 01 00 00       	jmp    103a40 <_alltraps>
  1038f7:	90                   	nop    

001038f8 <Xoflow>:
TRAPHANDLER_NOEC(Xoflow,  T_OFLOW)
  1038f8:	6a 00                	push   $0x0
  1038fa:	6a 04                	push   $0x4
  1038fc:	e9 3f 01 00 00       	jmp    103a40 <_alltraps>
  103901:	90                   	nop    

00103902 <Xbound>:
TRAPHANDLER_NOEC(Xbound,  T_BOUND)
  103902:	6a 00                	push   $0x0
  103904:	6a 05                	push   $0x5
  103906:	e9 35 01 00 00       	jmp    103a40 <_alltraps>
  10390b:	90                   	nop    

0010390c <Xillop>:
TRAPHANDLER_NOEC(Xillop,  T_ILLOP)
  10390c:	6a 00                	push   $0x0
  10390e:	6a 06                	push   $0x6
  103910:	e9 2b 01 00 00       	jmp    103a40 <_alltraps>
  103915:	90                   	nop    

00103916 <Xdevice>:
TRAPHANDLER_NOEC(Xdevice, T_DEVICE)
  103916:	6a 00                	push   $0x0
  103918:	6a 07                	push   $0x7
  10391a:	e9 21 01 00 00       	jmp    103a40 <_alltraps>
  10391f:	90                   	nop    

00103920 <Xdblflt>:
TRAPHANDLER     (Xdblflt, T_DBLFLT)
  103920:	6a 08                	push   $0x8
  103922:	e9 19 01 00 00       	jmp    103a40 <_alltraps>
  103927:	90                   	nop    

00103928 <Xtss>:
TRAPHANDLER     (Xtss,    T_TSS)
  103928:	6a 0a                	push   $0xa
  10392a:	e9 11 01 00 00       	jmp    103a40 <_alltraps>
  10392f:	90                   	nop    

00103930 <Xsegnp>:
TRAPHANDLER     (Xsegnp,  T_SEGNP)
  103930:	6a 0b                	push   $0xb
  103932:	e9 09 01 00 00       	jmp    103a40 <_alltraps>
  103937:	90                   	nop    

00103938 <Xstack>:
TRAPHANDLER     (Xstack,  T_STACK)
  103938:	6a 0c                	push   $0xc
  10393a:	e9 01 01 00 00       	jmp    103a40 <_alltraps>
  10393f:	90                   	nop    

00103940 <Xgpflt>:
TRAPHANDLER     (Xgpflt,  T_GPFLT)
  103940:	6a 0d                	push   $0xd
  103942:	e9 f9 00 00 00       	jmp    103a40 <_alltraps>
  103947:	90                   	nop    

00103948 <Xpgflt>:
TRAPHANDLER     (Xpgflt,  T_PGFLT)
  103948:	6a 0e                	push   $0xe
  10394a:	e9 f1 00 00 00       	jmp    103a40 <_alltraps>
  10394f:	90                   	nop    

00103950 <Xfperr>:
TRAPHANDLER_NOEC(Xfperr,  T_FPERR)
  103950:	6a 00                	push   $0x0
  103952:	6a 10                	push   $0x10
  103954:	e9 e7 00 00 00       	jmp    103a40 <_alltraps>
  103959:	90                   	nop    

0010395a <Xalign>:
TRAPHANDLER     (Xalign,  T_ALIGN)
  10395a:	6a 11                	push   $0x11
  10395c:	e9 df 00 00 00       	jmp    103a40 <_alltraps>
  103961:	90                   	nop    

00103962 <Xmchk>:
TRAPHANDLER_NOEC(Xmchk,   T_MCHK)
  103962:	6a 00                	push   $0x0
  103964:	6a 12                	push   $0x12
  103966:	e9 d5 00 00 00       	jmp    103a40 <_alltraps>
  10396b:	90                   	nop    

0010396c <Xsimd>:
TRAPHANDLER_NOEC(Xsimd,   T_SIMD)
  10396c:	6a 00                	push   $0x0
  10396e:	6a 13                	push   $0x13
  103970:	e9 cb 00 00 00       	jmp    103a40 <_alltraps>
  103975:	90                   	nop    

00103976 <Xirq0>:


/* ISA device interrupts */
TRAPHANDLER_NOEC(Xirq0,   T_IRQ0+0)	// IRQ_PIT
  103976:	6a 00                	push   $0x0
  103978:	6a 20                	push   $0x20
  10397a:	e9 c1 00 00 00       	jmp    103a40 <_alltraps>
  10397f:	90                   	nop    

00103980 <Xirq1>:
TRAPHANDLER_NOEC(Xirq1,   T_IRQ0+1)	// IRQ_KBD
  103980:	6a 00                	push   $0x0
  103982:	6a 21                	push   $0x21
  103984:	e9 b7 00 00 00       	jmp    103a40 <_alltraps>
  103989:	90                   	nop    

0010398a <Xirq2>:
TRAPHANDLER_NOEC(Xirq2,   T_IRQ0+2)
  10398a:	6a 00                	push   $0x0
  10398c:	6a 22                	push   $0x22
  10398e:	e9 ad 00 00 00       	jmp    103a40 <_alltraps>
  103993:	90                   	nop    

00103994 <Xirq3>:
TRAPHANDLER_NOEC(Xirq3,   T_IRQ0+3)
  103994:	6a 00                	push   $0x0
  103996:	6a 23                	push   $0x23
  103998:	e9 a3 00 00 00       	jmp    103a40 <_alltraps>
  10399d:	90                   	nop    

0010399e <Xirq4>:
TRAPHANDLER_NOEC(Xirq4,   T_IRQ0+4)	// IRQ_SERIAL
  10399e:	6a 00                	push   $0x0
  1039a0:	6a 24                	push   $0x24
  1039a2:	e9 99 00 00 00       	jmp    103a40 <_alltraps>
  1039a7:	90                   	nop    

001039a8 <Xirq5>:
TRAPHANDLER_NOEC(Xirq5,   T_IRQ0+5)
  1039a8:	6a 00                	push   $0x0
  1039aa:	6a 25                	push   $0x25
  1039ac:	e9 8f 00 00 00       	jmp    103a40 <_alltraps>
  1039b1:	90                   	nop    

001039b2 <Xirq6>:
TRAPHANDLER_NOEC(Xirq6,   T_IRQ0+6)
  1039b2:	6a 00                	push   $0x0
  1039b4:	6a 26                	push   $0x26
  1039b6:	e9 85 00 00 00       	jmp    103a40 <_alltraps>
  1039bb:	90                   	nop    

001039bc <Xirq7>:
TRAPHANDLER_NOEC(Xirq7,   T_IRQ0+7)	// IRQ_SPURIOUS
  1039bc:	6a 00                	push   $0x0
  1039be:	6a 27                	push   $0x27
  1039c0:	e9 7b 00 00 00       	jmp    103a40 <_alltraps>
  1039c5:	90                   	nop    

001039c6 <Xirq8>:
TRAPHANDLER_NOEC(Xirq8,   T_IRQ0+8)
  1039c6:	6a 00                	push   $0x0
  1039c8:	6a 28                	push   $0x28
  1039ca:	e9 71 00 00 00       	jmp    103a40 <_alltraps>
  1039cf:	90                   	nop    

001039d0 <Xirq9>:
TRAPHANDLER_NOEC(Xirq9,   T_IRQ0+9)
  1039d0:	6a 00                	push   $0x0
  1039d2:	6a 29                	push   $0x29
  1039d4:	e9 67 00 00 00       	jmp    103a40 <_alltraps>
  1039d9:	90                   	nop    

001039da <Xirq10>:
TRAPHANDLER_NOEC(Xirq10,  T_IRQ0+10)
  1039da:	6a 00                	push   $0x0
  1039dc:	6a 2a                	push   $0x2a
  1039de:	e9 5d 00 00 00       	jmp    103a40 <_alltraps>
  1039e3:	90                   	nop    

001039e4 <Xirq11>:
TRAPHANDLER_NOEC(Xirq11,  T_IRQ0+11)
  1039e4:	6a 00                	push   $0x0
  1039e6:	6a 2b                	push   $0x2b
  1039e8:	e9 53 00 00 00       	jmp    103a40 <_alltraps>
  1039ed:	90                   	nop    

001039ee <Xirq12>:
TRAPHANDLER_NOEC(Xirq12,  T_IRQ0+12)
  1039ee:	6a 00                	push   $0x0
  1039f0:	6a 2c                	push   $0x2c
  1039f2:	e9 49 00 00 00       	jmp    103a40 <_alltraps>
  1039f7:	90                   	nop    

001039f8 <Xirq13>:
TRAPHANDLER_NOEC(Xirq13,  T_IRQ0+13)
  1039f8:	6a 00                	push   $0x0
  1039fa:	6a 2d                	push   $0x2d
  1039fc:	e9 3f 00 00 00       	jmp    103a40 <_alltraps>
  103a01:	90                   	nop    

00103a02 <Xirq14>:
TRAPHANDLER_NOEC(Xirq14,  T_IRQ0+14)	// IRQ_IDE
  103a02:	6a 00                	push   $0x0
  103a04:	6a 2e                	push   $0x2e
  103a06:	e9 35 00 00 00       	jmp    103a40 <_alltraps>
  103a0b:	90                   	nop    

00103a0c <Xirq15>:
TRAPHANDLER_NOEC(Xirq15,  T_IRQ0+15)
  103a0c:	6a 00                	push   $0x0
  103a0e:	6a 2f                	push   $0x2f
  103a10:	e9 2b 00 00 00       	jmp    103a40 <_alltraps>
  103a15:	90                   	nop    

00103a16 <Xsyscall>:

TRAPHANDLER_NOEC(Xsyscall, T_SYSCALL)	// System call
  103a16:	6a 00                	push   $0x0
  103a18:	6a 30                	push   $0x30
  103a1a:	e9 21 00 00 00       	jmp    103a40 <_alltraps>
  103a1f:	90                   	nop    

00103a20 <Xltimer>:
TRAPHANDLER_NOEC(Xltimer,  T_LTIMER)	// Local APIC timer
  103a20:	6a 00                	push   $0x0
  103a22:	6a 31                	push   $0x31
  103a24:	e9 17 00 00 00       	jmp    103a40 <_alltraps>
  103a29:	90                   	nop    

00103a2a <Xlerror>:
TRAPHANDLER_NOEC(Xlerror,  T_LERROR)	// Local APIC error
  103a2a:	6a 00                	push   $0x0
  103a2c:	6a 32                	push   $0x32
  103a2e:	e9 0d 00 00 00       	jmp    103a40 <_alltraps>
  103a33:	90                   	nop    

00103a34 <Xdefault>:

/* default handler -- not for any specific trap */
TRAPHANDLER_NOEC(Xdefault, T_DEFAULT)
  103a34:	6a 00                	push   $0x0
  103a36:	68 f4 01 00 00       	push   $0x1f4
  103a3b:	e9 00 00 00 00       	jmp    103a40 <_alltraps>

00103a40 <_alltraps>:



.globl	_alltraps
.type	_alltraps,@function
.p2align 4, 0x90		/* 16-byte alignment, nop filled */
_alltraps:
	pushl %ds		# build trap frame
  103a40:	1e                   	push   %ds
	pushl %es
  103a41:	06                   	push   %es
	pushl %fs
  103a42:	0f a0                	push   %fs
	pushl %gs
  103a44:	0f a8                	push   %gs
	pushal
  103a46:	60                   	pusha  

	movl $CPU_GDT_KDATA,%eax # load kernel's data segment
  103a47:	b8 10 00 00 00       	mov    $0x10,%eax
	movw %ax,%ds
  103a4c:	8e d8                	movl   %eax,%ds
	movw %ax,%es
  103a4e:	8e c0                	movl   %eax,%es

	xorl %ebp,%ebp		# don't let debug_trace() walk into user space
  103a50:	31 ed                	xor    %ebp,%ebp

	pushl %esp		# pass pointer to this trapframe 
  103a52:	54                   	push   %esp
	call trap		# and call trap (does not return)
  103a53:	e8 7e f8 ff ff       	call   1032d6 <trap>

1:	jmp 1b			# should never get here; just spin...
  103a58:	eb fe                	jmp    103a58 <_alltraps+0x18>
  103a5a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi

00103a60 <trap_return>:



//
// Trap return code.
// C code in the kernel will call this function to return from a trap,
// providing the 
// Restore the CPU state from a given trapframe struct
// and return from the trap using the processor's 'iret' instruction.
// This function does not return to the caller,
// since the new CPU state this function loads
// replaces the caller's stack pointer and other registers.
//
.globl	trap_return
.type	trap_return,@function
.p2align 4, 0x90		/* 16-byte alignment, nop filled */
trap_return:
	movl	4(%esp),%esp	// reset stack pointer to point to trap frame
  103a60:	8b 64 24 04          	mov    0x4(%esp),%esp
	popal			// restore general-purpose registers except esp
  103a64:	61                   	popa   
	popl	%gs		// restore data segment registers
  103a65:	0f a9                	pop    %gs
	popl	%fs
  103a67:	0f a1                	pop    %fs
	popl	%es
  103a69:	07                   	pop    %es
	popl	%ds
  103a6a:	1f                   	pop    %ds
	addl	$8,%esp		// skip trapno and errcode
  103a6b:	83 c4 08             	add    $0x8,%esp
	iret			// return from trap handler
  103a6e:	cf                   	iret   
  103a6f:	90                   	nop    

00103a70 <sum>:
  103a70:	55                   	push   %ebp
  103a71:	89 e5                	mov    %esp,%ebp
  103a73:	83 ec 10             	sub    $0x10,%esp
  103a76:	c7 45 fc 00 00 00 00 	movl   $0x0,0xfffffffc(%ebp)
  103a7d:	c7 45 f8 00 00 00 00 	movl   $0x0,0xfffffff8(%ebp)
  103a84:	eb 13                	jmp    103a99 <sum+0x29>
  103a86:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  103a89:	03 45 08             	add    0x8(%ebp),%eax
  103a8c:	0f b6 00             	movzbl (%eax),%eax
  103a8f:	0f b6 c0             	movzbl %al,%eax
  103a92:	01 45 fc             	add    %eax,0xfffffffc(%ebp)
  103a95:	83 45 f8 01          	addl   $0x1,0xfffffff8(%ebp)
  103a99:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  103a9c:	3b 45 0c             	cmp    0xc(%ebp),%eax
  103a9f:	7c e5                	jl     103a86 <sum+0x16>
  103aa1:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  103aa4:	0f b6 c0             	movzbl %al,%eax
  103aa7:	c9                   	leave  
  103aa8:	c3                   	ret    

00103aa9 <mpsearch1>:
  103aa9:	55                   	push   %ebp
  103aaa:	89 e5                	mov    %esp,%ebp
  103aac:	83 ec 28             	sub    $0x28,%esp
  103aaf:	8b 45 0c             	mov    0xc(%ebp),%eax
  103ab2:	03 45 08             	add    0x8(%ebp),%eax
  103ab5:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  103ab8:	8b 45 08             	mov    0x8(%ebp),%eax
  103abb:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  103abe:	eb 42                	jmp    103b02 <mpsearch1+0x59>
  103ac0:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
  103ac7:	00 
  103ac8:	c7 44 24 04 48 cc 10 	movl   $0x10cc48,0x4(%esp)
  103acf:	00 
  103ad0:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  103ad3:	89 04 24             	mov    %eax,(%esp)
  103ad6:	e8 76 82 00 00       	call   10bd51 <memcmp>
  103adb:	85 c0                	test   %eax,%eax
  103add:	75 1f                	jne    103afe <mpsearch1+0x55>
  103adf:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
  103ae6:	00 
  103ae7:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  103aea:	89 04 24             	mov    %eax,(%esp)
  103aed:	e8 7e ff ff ff       	call   103a70 <sum>
  103af2:	84 c0                	test   %al,%al
  103af4:	75 08                	jne    103afe <mpsearch1+0x55>
  103af6:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  103af9:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  103afc:	eb 13                	jmp    103b11 <mpsearch1+0x68>
  103afe:	83 45 fc 10          	addl   $0x10,0xfffffffc(%ebp)
  103b02:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  103b05:	3b 45 f8             	cmp    0xfffffff8(%ebp),%eax
  103b08:	72 b6                	jb     103ac0 <mpsearch1+0x17>
  103b0a:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  103b11:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  103b14:	c9                   	leave  
  103b15:	c3                   	ret    

00103b16 <mpsearch>:
  103b16:	55                   	push   %ebp
  103b17:	89 e5                	mov    %esp,%ebp
  103b19:	83 ec 28             	sub    $0x28,%esp
  103b1c:	c7 45 f4 00 04 00 00 	movl   $0x400,0xfffffff4(%ebp)
  103b23:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  103b26:	83 c0 0f             	add    $0xf,%eax
  103b29:	0f b6 00             	movzbl (%eax),%eax
  103b2c:	0f b6 c0             	movzbl %al,%eax
  103b2f:	89 c2                	mov    %eax,%edx
  103b31:	c1 e2 08             	shl    $0x8,%edx
  103b34:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  103b37:	83 c0 0e             	add    $0xe,%eax
  103b3a:	0f b6 00             	movzbl (%eax),%eax
  103b3d:	0f b6 c0             	movzbl %al,%eax
  103b40:	09 d0                	or     %edx,%eax
  103b42:	c1 e0 04             	shl    $0x4,%eax
  103b45:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  103b48:	83 7d f8 00          	cmpl   $0x0,0xfffffff8(%ebp)
  103b4c:	74 24                	je     103b72 <mpsearch+0x5c>
  103b4e:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  103b51:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
  103b58:	00 
  103b59:	89 04 24             	mov    %eax,(%esp)
  103b5c:	e8 48 ff ff ff       	call   103aa9 <mpsearch1>
  103b61:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  103b64:	83 7d fc 00          	cmpl   $0x0,0xfffffffc(%ebp)
  103b68:	74 56                	je     103bc0 <mpsearch+0xaa>
  103b6a:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  103b6d:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  103b70:	eb 65                	jmp    103bd7 <mpsearch+0xc1>
  103b72:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  103b75:	83 c0 14             	add    $0x14,%eax
  103b78:	0f b6 00             	movzbl (%eax),%eax
  103b7b:	0f b6 c0             	movzbl %al,%eax
  103b7e:	89 c2                	mov    %eax,%edx
  103b80:	c1 e2 08             	shl    $0x8,%edx
  103b83:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  103b86:	83 c0 13             	add    $0x13,%eax
  103b89:	0f b6 00             	movzbl (%eax),%eax
  103b8c:	0f b6 c0             	movzbl %al,%eax
  103b8f:	09 d0                	or     %edx,%eax
  103b91:	c1 e0 0a             	shl    $0xa,%eax
  103b94:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  103b97:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  103b9a:	2d 00 04 00 00       	sub    $0x400,%eax
  103b9f:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
  103ba6:	00 
  103ba7:	89 04 24             	mov    %eax,(%esp)
  103baa:	e8 fa fe ff ff       	call   103aa9 <mpsearch1>
  103baf:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  103bb2:	83 7d fc 00          	cmpl   $0x0,0xfffffffc(%ebp)
  103bb6:	74 08                	je     103bc0 <mpsearch+0xaa>
  103bb8:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  103bbb:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  103bbe:	eb 17                	jmp    103bd7 <mpsearch+0xc1>
  103bc0:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
  103bc7:	00 
  103bc8:	c7 04 24 00 00 0f 00 	movl   $0xf0000,(%esp)
  103bcf:	e8 d5 fe ff ff       	call   103aa9 <mpsearch1>
  103bd4:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  103bd7:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  103bda:	c9                   	leave  
  103bdb:	c3                   	ret    

00103bdc <mpconfig>:
  103bdc:	55                   	push   %ebp
  103bdd:	89 e5                	mov    %esp,%ebp
  103bdf:	83 ec 28             	sub    $0x28,%esp
  103be2:	e8 2f ff ff ff       	call   103b16 <mpsearch>
  103be7:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  103bea:	83 7d fc 00          	cmpl   $0x0,0xfffffffc(%ebp)
  103bee:	74 0a                	je     103bfa <mpconfig+0x1e>
  103bf0:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  103bf3:	8b 40 04             	mov    0x4(%eax),%eax
  103bf6:	85 c0                	test   %eax,%eax
  103bf8:	75 0c                	jne    103c06 <mpconfig+0x2a>
  103bfa:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  103c01:	e9 84 00 00 00       	jmp    103c8a <mpconfig+0xae>
  103c06:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  103c09:	8b 40 04             	mov    0x4(%eax),%eax
  103c0c:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  103c0f:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
  103c16:	00 
  103c17:	c7 44 24 04 4d cc 10 	movl   $0x10cc4d,0x4(%esp)
  103c1e:	00 
  103c1f:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  103c22:	89 04 24             	mov    %eax,(%esp)
  103c25:	e8 27 81 00 00       	call   10bd51 <memcmp>
  103c2a:	85 c0                	test   %eax,%eax
  103c2c:	74 09                	je     103c37 <mpconfig+0x5b>
  103c2e:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  103c35:	eb 53                	jmp    103c8a <mpconfig+0xae>
  103c37:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  103c3a:	0f b6 40 06          	movzbl 0x6(%eax),%eax
  103c3e:	3c 01                	cmp    $0x1,%al
  103c40:	74 14                	je     103c56 <mpconfig+0x7a>
  103c42:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  103c45:	0f b6 40 06          	movzbl 0x6(%eax),%eax
  103c49:	3c 04                	cmp    $0x4,%al
  103c4b:	74 09                	je     103c56 <mpconfig+0x7a>
  103c4d:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  103c54:	eb 34                	jmp    103c8a <mpconfig+0xae>
  103c56:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  103c59:	0f b7 40 04          	movzwl 0x4(%eax),%eax
  103c5d:	0f b7 c0             	movzwl %ax,%eax
  103c60:	8b 55 f8             	mov    0xfffffff8(%ebp),%edx
  103c63:	89 44 24 04          	mov    %eax,0x4(%esp)
  103c67:	89 14 24             	mov    %edx,(%esp)
  103c6a:	e8 01 fe ff ff       	call   103a70 <sum>
  103c6f:	84 c0                	test   %al,%al
  103c71:	74 09                	je     103c7c <mpconfig+0xa0>
  103c73:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  103c7a:	eb 0e                	jmp    103c8a <mpconfig+0xae>
  103c7c:	8b 55 08             	mov    0x8(%ebp),%edx
  103c7f:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  103c82:	89 02                	mov    %eax,(%edx)
  103c84:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  103c87:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  103c8a:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  103c8d:	c9                   	leave  
  103c8e:	c3                   	ret    

00103c8f <mp_init>:
  103c8f:	55                   	push   %ebp
  103c90:	89 e5                	mov    %esp,%ebp
  103c92:	83 ec 58             	sub    $0x58,%esp
  103c95:	e8 88 01 00 00       	call   103e22 <cpu_onboot>
  103c9a:	85 c0                	test   %eax,%eax
  103c9c:	0f 84 7e 01 00 00    	je     103e20 <mp_init+0x191>
  103ca2:	8d 45 cc             	lea    0xffffffcc(%ebp),%eax
  103ca5:	89 04 24             	mov    %eax,(%esp)
  103ca8:	e8 2f ff ff ff       	call   103bdc <mpconfig>
  103cad:	89 45 d8             	mov    %eax,0xffffffd8(%ebp)
  103cb0:	83 7d d8 00          	cmpl   $0x0,0xffffffd8(%ebp)
  103cb4:	0f 84 66 01 00 00    	je     103e20 <mp_init+0x191>
  103cba:	c7 05 ec 1d 18 00 01 	movl   $0x1,0x181dec
  103cc1:	00 00 00 
  103cc4:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  103cc7:	8b 40 24             	mov    0x24(%eax),%eax
  103cca:	a3 04 50 18 00       	mov    %eax,0x185004
  103ccf:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  103cd2:	83 c0 2c             	add    $0x2c,%eax
  103cd5:	89 45 d0             	mov    %eax,0xffffffd0(%ebp)
  103cd8:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  103cdb:	0f b7 40 04          	movzwl 0x4(%eax),%eax
  103cdf:	0f b7 c0             	movzwl %ax,%eax
  103ce2:	89 c2                	mov    %eax,%edx
  103ce4:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  103ce7:	8d 04 02             	lea    (%edx,%eax,1),%eax
  103cea:	89 45 d4             	mov    %eax,0xffffffd4(%ebp)
  103ced:	e9 da 00 00 00       	jmp    103dcc <mp_init+0x13d>
  103cf2:	8b 45 d0             	mov    0xffffffd0(%ebp),%eax
  103cf5:	0f b6 00             	movzbl (%eax),%eax
  103cf8:	0f b6 c0             	movzbl %al,%eax
  103cfb:	89 45 b8             	mov    %eax,0xffffffb8(%ebp)
  103cfe:	83 7d b8 04          	cmpl   $0x4,0xffffffb8(%ebp)
  103d02:	0f 87 9b 00 00 00    	ja     103da3 <mp_init+0x114>
  103d08:	8b 55 b8             	mov    0xffffffb8(%ebp),%edx
  103d0b:	8b 04 95 84 cc 10 00 	mov    0x10cc84(,%edx,4),%eax
  103d12:	ff e0                	jmp    *%eax
  103d14:	8b 45 d0             	mov    0xffffffd0(%ebp),%eax
  103d17:	89 45 dc             	mov    %eax,0xffffffdc(%ebp)
  103d1a:	83 45 d0 14          	addl   $0x14,0xffffffd0(%ebp)
  103d1e:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  103d21:	0f b6 40 03          	movzbl 0x3(%eax),%eax
  103d25:	0f b6 c0             	movzbl %al,%eax
  103d28:	83 e0 01             	and    $0x1,%eax
  103d2b:	85 c0                	test   %eax,%eax
  103d2d:	0f 84 99 00 00 00    	je     103dcc <mp_init+0x13d>
  103d33:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  103d36:	0f b6 40 03          	movzbl 0x3(%eax),%eax
  103d3a:	0f b6 c0             	movzbl %al,%eax
  103d3d:	83 e0 02             	and    $0x2,%eax
  103d40:	85 c0                	test   %eax,%eax
  103d42:	75 0a                	jne    103d4e <mp_init+0xbf>
  103d44:	e8 2d de ff ff       	call   101b76 <cpu_alloc>
  103d49:	89 45 bc             	mov    %eax,0xffffffbc(%ebp)
  103d4c:	eb 07                	jmp    103d55 <mp_init+0xc6>
  103d4e:	c7 45 bc 00 f0 10 00 	movl   $0x10f000,0xffffffbc(%ebp)
  103d55:	8b 45 bc             	mov    0xffffffbc(%ebp),%eax
  103d58:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
  103d5b:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  103d5e:	0f b6 50 01          	movzbl 0x1(%eax),%edx
  103d62:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  103d65:	88 90 ac 00 00 00    	mov    %dl,0xac(%eax)
  103d6b:	a1 f0 1d 18 00       	mov    0x181df0,%eax
  103d70:	83 c0 01             	add    $0x1,%eax
  103d73:	a3 f0 1d 18 00       	mov    %eax,0x181df0
  103d78:	eb 52                	jmp    103dcc <mp_init+0x13d>
  103d7a:	8b 45 d0             	mov    0xffffffd0(%ebp),%eax
  103d7d:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)
  103d80:	83 45 d0 08          	addl   $0x8,0xffffffd0(%ebp)
  103d84:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  103d87:	0f b6 40 01          	movzbl 0x1(%eax),%eax
  103d8b:	a2 e4 1d 18 00       	mov    %al,0x181de4
  103d90:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  103d93:	8b 40 04             	mov    0x4(%eax),%eax
  103d96:	a3 e8 1d 18 00       	mov    %eax,0x181de8
  103d9b:	eb 2f                	jmp    103dcc <mp_init+0x13d>
  103d9d:	83 45 d0 08          	addl   $0x8,0xffffffd0(%ebp)
  103da1:	eb 29                	jmp    103dcc <mp_init+0x13d>
  103da3:	8b 45 d0             	mov    0xffffffd0(%ebp),%eax
  103da6:	0f b6 00             	movzbl (%eax),%eax
  103da9:	0f b6 c0             	movzbl %al,%eax
  103dac:	89 44 24 0c          	mov    %eax,0xc(%esp)
  103db0:	c7 44 24 08 54 cc 10 	movl   $0x10cc54,0x8(%esp)
  103db7:	00 
  103db8:	c7 44 24 04 96 00 00 	movl   $0x96,0x4(%esp)
  103dbf:	00 
  103dc0:	c7 04 24 74 cc 10 00 	movl   $0x10cc74,(%esp)
  103dc7:	e8 6c cb ff ff       	call   100938 <debug_panic>
  103dcc:	8b 45 d0             	mov    0xffffffd0(%ebp),%eax
  103dcf:	3b 45 d4             	cmp    0xffffffd4(%ebp),%eax
  103dd2:	0f 82 1a ff ff ff    	jb     103cf2 <mp_init+0x63>
  103dd8:	8b 45 cc             	mov    0xffffffcc(%ebp),%eax
  103ddb:	0f b6 40 0c          	movzbl 0xc(%eax),%eax
  103ddf:	84 c0                	test   %al,%al
  103de1:	74 3d                	je     103e20 <mp_init+0x191>
  103de3:	c7 45 ec 22 00 00 00 	movl   $0x22,0xffffffec(%ebp)
  103dea:	c6 45 eb 70          	movb   $0x70,0xffffffeb(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  103dee:	0f b6 45 eb          	movzbl 0xffffffeb(%ebp),%eax
  103df2:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
  103df5:	ee                   	out    %al,(%dx)
  103df6:	c7 45 f4 23 00 00 00 	movl   $0x23,0xfffffff4(%ebp)
  103dfd:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  103e00:	ec                   	in     (%dx),%al
  103e01:	88 45 f3             	mov    %al,0xfffffff3(%ebp)
  103e04:	0f b6 45 f3          	movzbl 0xfffffff3(%ebp),%eax
  103e08:	83 c8 01             	or     $0x1,%eax
  103e0b:	0f b6 c0             	movzbl %al,%eax
  103e0e:	c7 45 fc 23 00 00 00 	movl   $0x23,0xfffffffc(%ebp)
  103e15:	88 45 fb             	mov    %al,0xfffffffb(%ebp)
  103e18:	0f b6 45 fb          	movzbl 0xfffffffb(%ebp),%eax
  103e1c:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  103e1f:	ee                   	out    %al,(%dx)
  103e20:	c9                   	leave  
  103e21:	c3                   	ret    

00103e22 <cpu_onboot>:
}

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  103e22:	55                   	push   %ebp
  103e23:	89 e5                	mov    %esp,%ebp
  103e25:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  103e28:	e8 0d 00 00 00       	call   103e3a <cpu_cur>
  103e2d:	3d 00 f0 10 00       	cmp    $0x10f000,%eax
  103e32:	0f 94 c0             	sete   %al
  103e35:	0f b6 c0             	movzbl %al,%eax
}
  103e38:	c9                   	leave  
  103e39:	c3                   	ret    

00103e3a <cpu_cur>:
  103e3a:	55                   	push   %ebp
  103e3b:	89 e5                	mov    %esp,%ebp
  103e3d:	83 ec 28             	sub    $0x28,%esp
static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  103e40:	89 65 fc             	mov    %esp,0xfffffffc(%ebp)
        return esp;
  103e43:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  103e46:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  103e49:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  103e4c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  103e51:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	assert(c->magic == CPU_MAGIC);
  103e54:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  103e57:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  103e5d:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  103e62:	74 24                	je     103e88 <cpu_cur+0x4e>
  103e64:	c7 44 24 0c 98 cc 10 	movl   $0x10cc98,0xc(%esp)
  103e6b:	00 
  103e6c:	c7 44 24 08 ae cc 10 	movl   $0x10ccae,0x8(%esp)
  103e73:	00 
  103e74:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  103e7b:	00 
  103e7c:	c7 04 24 c3 cc 10 00 	movl   $0x10ccc3,(%esp)
  103e83:	e8 b0 ca ff ff       	call   100938 <debug_panic>
	return c;
  103e88:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
}
  103e8b:	c9                   	leave  
  103e8c:	c3                   	ret    
  103e8d:	90                   	nop    
  103e8e:	90                   	nop    
  103e8f:	90                   	nop    

00103e90 <spinlock_init_>:
  103e90:	55                   	push   %ebp
  103e91:	89 e5                	mov    %esp,%ebp
  103e93:	8b 55 08             	mov    0x8(%ebp),%edx
  103e96:	8b 45 0c             	mov    0xc(%ebp),%eax
  103e99:	89 42 04             	mov    %eax,0x4(%edx)
  103e9c:	8b 55 08             	mov    0x8(%ebp),%edx
  103e9f:	8b 45 10             	mov    0x10(%ebp),%eax
  103ea2:	89 42 08             	mov    %eax,0x8(%edx)
  103ea5:	8b 45 08             	mov    0x8(%ebp),%eax
  103ea8:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  103eae:	8b 45 08             	mov    0x8(%ebp),%eax
  103eb1:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  103eb8:	5d                   	pop    %ebp
  103eb9:	c3                   	ret    

00103eba <spinlock_acquire>:
  103eba:	55                   	push   %ebp
  103ebb:	89 e5                	mov    %esp,%ebp
  103ebd:	83 ec 28             	sub    $0x28,%esp
  103ec0:	8b 45 08             	mov    0x8(%ebp),%eax
  103ec3:	89 04 24             	mov    %eax,(%esp)
  103ec6:	e8 44 01 00 00       	call   10400f <spinlock_holding>
  103ecb:	85 c0                	test   %eax,%eax
  103ecd:	74 21                	je     103ef0 <spinlock_acquire+0x36>
  103ecf:	c7 44 24 08 d0 cc 10 	movl   $0x10ccd0,0x8(%esp)
  103ed6:	00 
  103ed7:	c7 44 24 04 28 00 00 	movl   $0x28,0x4(%esp)
  103ede:	00 
  103edf:	c7 04 24 eb cc 10 00 	movl   $0x10cceb,(%esp)
  103ee6:	e8 4d ca ff ff       	call   100938 <debug_panic>
  103eeb:	e8 3e 00 00 00       	call   103f2e <pause>
  103ef0:	8b 45 08             	mov    0x8(%ebp),%eax
  103ef3:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  103efa:	00 
  103efb:	89 04 24             	mov    %eax,(%esp)
  103efe:	e8 32 00 00 00       	call   103f35 <xchg>
  103f03:	85 c0                	test   %eax,%eax
  103f05:	75 e4                	jne    103eeb <spinlock_acquire+0x31>
  103f07:	e8 56 00 00 00       	call   103f62 <cpu_cur>
  103f0c:	89 c2                	mov    %eax,%edx
  103f0e:	8b 45 08             	mov    0x8(%ebp),%eax
  103f11:	89 50 0c             	mov    %edx,0xc(%eax)
  103f14:	8b 55 08             	mov    0x8(%ebp),%edx
  103f17:	83 c2 10             	add    $0x10,%edx
static gcc_inline uint32_t
read_ebp(void)
{
        uint32_t ebp;
        __asm __volatile("movl %%ebp,%0" : "=rm" (ebp));
  103f1a:	89 6d fc             	mov    %ebp,0xfffffffc(%ebp)
        return ebp;
  103f1d:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  103f20:	89 54 24 04          	mov    %edx,0x4(%esp)
  103f24:	89 04 24             	mov    %eax,(%esp)
  103f27:	e8 13 cb ff ff       	call   100a3f <debug_trace>
  103f2c:	c9                   	leave  
  103f2d:	c3                   	ret    

00103f2e <pause>:
}

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
        return esp;
}

static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
        return cs;
}

// Atomically set *addr to newval and return the old value of *addr.
static inline uint32_t
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
	       "+m" (*addr), "=a" (result) :
	       "1" (newval) :
	       "cc");
	return result;
}

// Atomically add incr to *addr.
static inline void
lockadd(volatile int32_t *addr, int32_t incr)
{
	asm volatile("lock; addl %1,%0" : "+m" (*addr) : "r" (incr) : "cc");
}

// Atomically add incr to *addr and return true if the result is zero.
static inline uint8_t
lockaddz(volatile int32_t *addr, int32_t incr)
{
	uint8_t zero;
	asm volatile("lock; addl %2,%0; setzb %1"
		: "+m" (*addr), "=rm" (zero)
		: "r" (incr)
		: "cc");
	return zero;
}

// Atomically add incr to *addr and return the old value of *addr.
static inline int32_t
xadd(volatile uint32_t *addr, int32_t incr)
{
	int32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xaddl %0, %1" :
	       "+m" (*addr), "=a" (result) :
	       "1" (incr) :
	       "cc");
	return result;
}

static inline void
pause(void)
{
  103f2e:	55                   	push   %ebp
  103f2f:	89 e5                	mov    %esp,%ebp
	asm volatile("pause" : : : "memory");
  103f31:	f3 90                	pause  
}
  103f33:	5d                   	pop    %ebp
  103f34:	c3                   	ret    

00103f35 <xchg>:
  103f35:	55                   	push   %ebp
  103f36:	89 e5                	mov    %esp,%ebp
  103f38:	53                   	push   %ebx
  103f39:	83 ec 14             	sub    $0x14,%esp
  103f3c:	8b 4d 08             	mov    0x8(%ebp),%ecx
  103f3f:	8b 55 0c             	mov    0xc(%ebp),%edx
  103f42:	8b 45 08             	mov    0x8(%ebp),%eax
  103f45:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  103f48:	89 d0                	mov    %edx,%eax
  103f4a:	8b 5d e8             	mov    0xffffffe8(%ebp),%ebx
  103f4d:	f0 87 01             	lock xchg %eax,(%ecx)
  103f50:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  103f53:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  103f56:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  103f59:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  103f5c:	83 c4 14             	add    $0x14,%esp
  103f5f:	5b                   	pop    %ebx
  103f60:	5d                   	pop    %ebp
  103f61:	c3                   	ret    

00103f62 <cpu_cur>:

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  103f62:	55                   	push   %ebp
  103f63:	89 e5                	mov    %esp,%ebp
  103f65:	83 ec 28             	sub    $0x28,%esp
static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  103f68:	89 65 fc             	mov    %esp,0xfffffffc(%ebp)
        return esp;
  103f6b:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  103f6e:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  103f71:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  103f74:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  103f79:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	assert(c->magic == CPU_MAGIC);
  103f7c:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  103f7f:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  103f85:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  103f8a:	74 24                	je     103fb0 <cpu_cur+0x4e>
  103f8c:	c7 44 24 0c fe cc 10 	movl   $0x10ccfe,0xc(%esp)
  103f93:	00 
  103f94:	c7 44 24 08 14 cd 10 	movl   $0x10cd14,0x8(%esp)
  103f9b:	00 
  103f9c:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  103fa3:	00 
  103fa4:	c7 04 24 29 cd 10 00 	movl   $0x10cd29,(%esp)
  103fab:	e8 88 c9 ff ff       	call   100938 <debug_panic>
	return c;
  103fb0:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
}
  103fb3:	c9                   	leave  
  103fb4:	c3                   	ret    

00103fb5 <spinlock_release>:
  103fb5:	55                   	push   %ebp
  103fb6:	89 e5                	mov    %esp,%ebp
  103fb8:	83 ec 18             	sub    $0x18,%esp
  103fbb:	8b 45 08             	mov    0x8(%ebp),%eax
  103fbe:	89 04 24             	mov    %eax,(%esp)
  103fc1:	e8 49 00 00 00       	call   10400f <spinlock_holding>
  103fc6:	85 c0                	test   %eax,%eax
  103fc8:	75 1c                	jne    103fe6 <spinlock_release+0x31>
  103fca:	c7 44 24 08 36 cd 10 	movl   $0x10cd36,0x8(%esp)
  103fd1:	00 
  103fd2:	c7 44 24 04 3c 00 00 	movl   $0x3c,0x4(%esp)
  103fd9:	00 
  103fda:	c7 04 24 eb cc 10 00 	movl   $0x10cceb,(%esp)
  103fe1:	e8 52 c9 ff ff       	call   100938 <debug_panic>
  103fe6:	8b 45 08             	mov    0x8(%ebp),%eax
  103fe9:	c7 40 10 00 00 00 00 	movl   $0x0,0x10(%eax)
  103ff0:	8b 45 08             	mov    0x8(%ebp),%eax
  103ff3:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  103ffa:	8b 45 08             	mov    0x8(%ebp),%eax
  103ffd:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  104004:	00 
  104005:	89 04 24             	mov    %eax,(%esp)
  104008:	e8 28 ff ff ff       	call   103f35 <xchg>
  10400d:	c9                   	leave  
  10400e:	c3                   	ret    

0010400f <spinlock_holding>:
  10400f:	55                   	push   %ebp
  104010:	89 e5                	mov    %esp,%ebp
  104012:	53                   	push   %ebx
  104013:	83 ec 04             	sub    $0x4,%esp
  104016:	8b 45 08             	mov    0x8(%ebp),%eax
  104019:	8b 00                	mov    (%eax),%eax
  10401b:	85 c0                	test   %eax,%eax
  10401d:	74 18                	je     104037 <spinlock_holding+0x28>
  10401f:	8b 45 08             	mov    0x8(%ebp),%eax
  104022:	8b 58 0c             	mov    0xc(%eax),%ebx
  104025:	e8 38 ff ff ff       	call   103f62 <cpu_cur>
  10402a:	39 c3                	cmp    %eax,%ebx
  10402c:	75 09                	jne    104037 <spinlock_holding+0x28>
  10402e:	c7 45 f8 01 00 00 00 	movl   $0x1,0xfffffff8(%ebp)
  104035:	eb 07                	jmp    10403e <spinlock_holding+0x2f>
  104037:	c7 45 f8 00 00 00 00 	movl   $0x0,0xfffffff8(%ebp)
  10403e:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  104041:	83 c4 04             	add    $0x4,%esp
  104044:	5b                   	pop    %ebx
  104045:	5d                   	pop    %ebp
  104046:	c3                   	ret    

00104047 <spinlock_godeep>:
  104047:	55                   	push   %ebp
  104048:	89 e5                	mov    %esp,%ebp
  10404a:	83 ec 18             	sub    $0x18,%esp
  10404d:	8b 45 08             	mov    0x8(%ebp),%eax
  104050:	85 c0                	test   %eax,%eax
  104052:	75 14                	jne    104068 <spinlock_godeep+0x21>
  104054:	8b 45 0c             	mov    0xc(%ebp),%eax
  104057:	89 04 24             	mov    %eax,(%esp)
  10405a:	e8 5b fe ff ff       	call   103eba <spinlock_acquire>
  10405f:	c7 45 fc 01 00 00 00 	movl   $0x1,0xfffffffc(%ebp)
  104066:	eb 22                	jmp    10408a <spinlock_godeep+0x43>
  104068:	8b 45 08             	mov    0x8(%ebp),%eax
  10406b:	8d 50 ff             	lea    0xffffffff(%eax),%edx
  10406e:	8b 45 0c             	mov    0xc(%ebp),%eax
  104071:	89 44 24 04          	mov    %eax,0x4(%esp)
  104075:	89 14 24             	mov    %edx,(%esp)
  104078:	e8 ca ff ff ff       	call   104047 <spinlock_godeep>
  10407d:	89 c2                	mov    %eax,%edx
  10407f:	8b 45 08             	mov    0x8(%ebp),%eax
  104082:	89 d1                	mov    %edx,%ecx
  104084:	0f af c8             	imul   %eax,%ecx
  104087:	89 4d fc             	mov    %ecx,0xfffffffc(%ebp)
  10408a:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  10408d:	c9                   	leave  
  10408e:	c3                   	ret    

0010408f <spinlock_check>:
  10408f:	55                   	push   %ebp
  104090:	89 e5                	mov    %esp,%ebp
  104092:	53                   	push   %ebx
  104093:	83 ec 44             	sub    $0x44,%esp
  104096:	89 e0                	mov    %esp,%eax
  104098:	89 45 d8             	mov    %eax,0xffffffd8(%ebp)
  10409b:	c7 45 e4 0a 00 00 00 	movl   $0xa,0xffffffe4(%ebp)
  1040a2:	c7 45 e8 05 00 00 00 	movl   $0x5,0xffffffe8(%ebp)
  1040a9:	c7 45 f8 47 cd 10 00 	movl   $0x10cd47,0xfffffff8(%ebp)
  1040b0:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  1040b3:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  1040ba:	8d 04 d5 00 00 00 00 	lea    0x0(,%edx,8),%eax
  1040c1:	29 d0                	sub    %edx,%eax
  1040c3:	83 c0 0f             	add    $0xf,%eax
  1040c6:	83 c0 0f             	add    $0xf,%eax
  1040c9:	c1 e8 04             	shr    $0x4,%eax
  1040cc:	c1 e0 04             	shl    $0x4,%eax
  1040cf:	29 c4                	sub    %eax,%esp
  1040d1:	8d 44 24 10          	lea    0x10(%esp),%eax
  1040d5:	89 45 d4             	mov    %eax,0xffffffd4(%ebp)
  1040d8:	8b 45 d4             	mov    0xffffffd4(%ebp),%eax
  1040db:	83 c0 0f             	add    $0xf,%eax
  1040de:	c1 e8 04             	shr    $0x4,%eax
  1040e1:	c1 e0 04             	shl    $0x4,%eax
  1040e4:	89 45 d4             	mov    %eax,0xffffffd4(%ebp)
  1040e7:	8b 45 d4             	mov    0xffffffd4(%ebp),%eax
  1040ea:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)
  1040ed:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  1040f4:	eb 34                	jmp    10412a <spinlock_check+0x9b>
  1040f6:	8b 4d e0             	mov    0xffffffe0(%ebp),%ecx
  1040f9:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  1040fc:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  104103:	8d 04 d5 00 00 00 00 	lea    0x0(,%edx,8),%eax
  10410a:	29 d0                	sub    %edx,%eax
  10410c:	8d 14 01             	lea    (%ecx,%eax,1),%edx
  10410f:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  104116:	00 
  104117:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10411a:	89 44 24 04          	mov    %eax,0x4(%esp)
  10411e:	89 14 24             	mov    %edx,(%esp)
  104121:	e8 6a fd ff ff       	call   103e90 <spinlock_init_>
  104126:	83 45 ec 01          	addl   $0x1,0xffffffec(%ebp)
  10412a:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  10412d:	3b 45 e4             	cmp    0xffffffe4(%ebp),%eax
  104130:	7c c4                	jl     1040f6 <spinlock_check+0x67>
  104132:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  104139:	eb 49                	jmp    104184 <spinlock_check+0xf5>
  10413b:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  10413e:	8b 4d e0             	mov    0xffffffe0(%ebp),%ecx
  104141:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  104148:	8d 04 d5 00 00 00 00 	lea    0x0(,%edx,8),%eax
  10414f:	29 d0                	sub    %edx,%eax
  104151:	01 c8                	add    %ecx,%eax
  104153:	83 c0 0c             	add    $0xc,%eax
  104156:	8b 00                	mov    (%eax),%eax
  104158:	85 c0                	test   %eax,%eax
  10415a:	74 24                	je     104180 <spinlock_check+0xf1>
  10415c:	c7 44 24 0c 56 cd 10 	movl   $0x10cd56,0xc(%esp)
  104163:	00 
  104164:	c7 44 24 08 14 cd 10 	movl   $0x10cd14,0x8(%esp)
  10416b:	00 
  10416c:	c7 44 24 04 6e 00 00 	movl   $0x6e,0x4(%esp)
  104173:	00 
  104174:	c7 04 24 eb cc 10 00 	movl   $0x10cceb,(%esp)
  10417b:	e8 b8 c7 ff ff       	call   100938 <debug_panic>
  104180:	83 45 ec 01          	addl   $0x1,0xffffffec(%ebp)
  104184:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  104187:	3b 45 e4             	cmp    0xffffffe4(%ebp),%eax
  10418a:	7c af                	jl     10413b <spinlock_check+0xac>
  10418c:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  104193:	eb 4a                	jmp    1041df <spinlock_check+0x150>
  104195:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  104198:	8b 4d e0             	mov    0xffffffe0(%ebp),%ecx
  10419b:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  1041a2:	8d 04 d5 00 00 00 00 	lea    0x0(,%edx,8),%eax
  1041a9:	29 d0                	sub    %edx,%eax
  1041ab:	01 c8                	add    %ecx,%eax
  1041ad:	83 c0 04             	add    $0x4,%eax
  1041b0:	8b 00                	mov    (%eax),%eax
  1041b2:	3b 45 f8             	cmp    0xfffffff8(%ebp),%eax
  1041b5:	74 24                	je     1041db <spinlock_check+0x14c>
  1041b7:	c7 44 24 0c 69 cd 10 	movl   $0x10cd69,0xc(%esp)
  1041be:	00 
  1041bf:	c7 44 24 08 14 cd 10 	movl   $0x10cd14,0x8(%esp)
  1041c6:	00 
  1041c7:	c7 44 24 04 70 00 00 	movl   $0x70,0x4(%esp)
  1041ce:	00 
  1041cf:	c7 04 24 eb cc 10 00 	movl   $0x10cceb,(%esp)
  1041d6:	e8 5d c7 ff ff       	call   100938 <debug_panic>
  1041db:	83 45 ec 01          	addl   $0x1,0xffffffec(%ebp)
  1041df:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  1041e2:	3b 45 e4             	cmp    0xffffffe4(%ebp),%eax
  1041e5:	7c ae                	jl     104195 <spinlock_check+0x106>
  1041e7:	c7 45 f4 00 00 00 00 	movl   $0x0,0xfffffff4(%ebp)
  1041ee:	e9 17 03 00 00       	jmp    10450a <spinlock_check+0x47b>
  1041f3:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  1041fa:	eb 2c                	jmp    104228 <spinlock_check+0x199>
  1041fc:	8b 4d e0             	mov    0xffffffe0(%ebp),%ecx
  1041ff:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  104202:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  104209:	8d 04 d5 00 00 00 00 	lea    0x0(,%edx,8),%eax
  104210:	29 d0                	sub    %edx,%eax
  104212:	8d 04 01             	lea    (%ecx,%eax,1),%eax
  104215:	89 44 24 04          	mov    %eax,0x4(%esp)
  104219:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  10421c:	89 04 24             	mov    %eax,(%esp)
  10421f:	e8 23 fe ff ff       	call   104047 <spinlock_godeep>
  104224:	83 45 ec 01          	addl   $0x1,0xffffffec(%ebp)
  104228:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  10422b:	3b 45 e4             	cmp    0xffffffe4(%ebp),%eax
  10422e:	7c cc                	jl     1041fc <spinlock_check+0x16d>
  104230:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  104237:	eb 4e                	jmp    104287 <spinlock_check+0x1f8>
  104239:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  10423c:	8b 4d e0             	mov    0xffffffe0(%ebp),%ecx
  10423f:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  104246:	8d 04 d5 00 00 00 00 	lea    0x0(,%edx,8),%eax
  10424d:	29 d0                	sub    %edx,%eax
  10424f:	01 c8                	add    %ecx,%eax
  104251:	83 c0 0c             	add    $0xc,%eax
  104254:	8b 18                	mov    (%eax),%ebx
  104256:	e8 07 fd ff ff       	call   103f62 <cpu_cur>
  10425b:	39 c3                	cmp    %eax,%ebx
  10425d:	74 24                	je     104283 <spinlock_check+0x1f4>
  10425f:	c7 44 24 0c 7d cd 10 	movl   $0x10cd7d,0xc(%esp)
  104266:	00 
  104267:	c7 44 24 08 14 cd 10 	movl   $0x10cd14,0x8(%esp)
  10426e:	00 
  10426f:	c7 44 24 04 7a 00 00 	movl   $0x7a,0x4(%esp)
  104276:	00 
  104277:	c7 04 24 eb cc 10 00 	movl   $0x10cceb,(%esp)
  10427e:	e8 b5 c6 ff ff       	call   100938 <debug_panic>
  104283:	83 45 ec 01          	addl   $0x1,0xffffffec(%ebp)
  104287:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  10428a:	3b 45 e4             	cmp    0xffffffe4(%ebp),%eax
  10428d:	7c aa                	jl     104239 <spinlock_check+0x1aa>
  10428f:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  104296:	eb 4d                	jmp    1042e5 <spinlock_check+0x256>
  104298:	8b 4d e0             	mov    0xffffffe0(%ebp),%ecx
  10429b:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  10429e:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  1042a5:	8d 04 d5 00 00 00 00 	lea    0x0(,%edx,8),%eax
  1042ac:	29 d0                	sub    %edx,%eax
  1042ae:	8d 04 01             	lea    (%ecx,%eax,1),%eax
  1042b1:	89 04 24             	mov    %eax,(%esp)
  1042b4:	e8 56 fd ff ff       	call   10400f <spinlock_holding>
  1042b9:	85 c0                	test   %eax,%eax
  1042bb:	75 24                	jne    1042e1 <spinlock_check+0x252>
  1042bd:	c7 44 24 0c 98 cd 10 	movl   $0x10cd98,0xc(%esp)
  1042c4:	00 
  1042c5:	c7 44 24 08 14 cd 10 	movl   $0x10cd14,0x8(%esp)
  1042cc:	00 
  1042cd:	c7 44 24 04 7d 00 00 	movl   $0x7d,0x4(%esp)
  1042d4:	00 
  1042d5:	c7 04 24 eb cc 10 00 	movl   $0x10cceb,(%esp)
  1042dc:	e8 57 c6 ff ff       	call   100938 <debug_panic>
  1042e1:	83 45 ec 01          	addl   $0x1,0xffffffec(%ebp)
  1042e5:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  1042e8:	3b 45 e4             	cmp    0xffffffe4(%ebp),%eax
  1042eb:	7c ab                	jl     104298 <spinlock_check+0x209>
  1042ed:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  1042f4:	e9 b9 00 00 00       	jmp    1043b2 <spinlock_check+0x323>
  1042f9:	c7 45 f0 00 00 00 00 	movl   $0x0,0xfffffff0(%ebp)
  104300:	e9 97 00 00 00       	jmp    10439c <spinlock_check+0x30d>
  104305:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  104308:	8b 4d f0             	mov    0xfffffff0(%ebp),%ecx
  10430b:	8b 5d e0             	mov    0xffffffe0(%ebp),%ebx
  10430e:	8d 14 00             	lea    (%eax,%eax,1),%edx
  104311:	8d 04 d5 00 00 00 00 	lea    0x0(,%edx,8),%eax
  104318:	29 d0                	sub    %edx,%eax
  10431a:	01 c8                	add    %ecx,%eax
  10431c:	8b 54 83 10          	mov    0x10(%ebx,%eax,4),%edx
  104320:	b8 47 40 10 00       	mov    $0x104047,%eax
  104325:	39 c2                	cmp    %eax,%edx
  104327:	73 24                	jae    10434d <spinlock_check+0x2be>
  104329:	c7 44 24 0c bc cd 10 	movl   $0x10cdbc,0xc(%esp)
  104330:	00 
  104331:	c7 44 24 08 14 cd 10 	movl   $0x10cd14,0x8(%esp)
  104338:	00 
  104339:	c7 44 24 04 84 00 00 	movl   $0x84,0x4(%esp)
  104340:	00 
  104341:	c7 04 24 eb cc 10 00 	movl   $0x10cceb,(%esp)
  104348:	e8 eb c5 ff ff       	call   100938 <debug_panic>
  10434d:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  104350:	8b 4d f0             	mov    0xfffffff0(%ebp),%ecx
  104353:	8b 5d e0             	mov    0xffffffe0(%ebp),%ebx
  104356:	8d 14 00             	lea    (%eax,%eax,1),%edx
  104359:	8d 04 d5 00 00 00 00 	lea    0x0(,%edx,8),%eax
  104360:	29 d0                	sub    %edx,%eax
  104362:	01 c8                	add    %ecx,%eax
  104364:	8b 54 83 10          	mov    0x10(%ebx,%eax,4),%edx
  104368:	b8 47 40 10 00       	mov    $0x104047,%eax
  10436d:	83 c0 64             	add    $0x64,%eax
  104370:	39 c2                	cmp    %eax,%edx
  104372:	72 24                	jb     104398 <spinlock_check+0x309>
  104374:	c7 44 24 0c ec cd 10 	movl   $0x10cdec,0xc(%esp)
  10437b:	00 
  10437c:	c7 44 24 08 14 cd 10 	movl   $0x10cd14,0x8(%esp)
  104383:	00 
  104384:	c7 44 24 04 86 00 00 	movl   $0x86,0x4(%esp)
  10438b:	00 
  10438c:	c7 04 24 eb cc 10 00 	movl   $0x10cceb,(%esp)
  104393:	e8 a0 c5 ff ff       	call   100938 <debug_panic>
  104398:	83 45 f0 01          	addl   $0x1,0xfffffff0(%ebp)
  10439c:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  10439f:	3b 45 ec             	cmp    0xffffffec(%ebp),%eax
  1043a2:	7f 0a                	jg     1043ae <spinlock_check+0x31f>
  1043a4:	83 7d f0 09          	cmpl   $0x9,0xfffffff0(%ebp)
  1043a8:	0f 8e 57 ff ff ff    	jle    104305 <spinlock_check+0x276>
  1043ae:	83 45 ec 01          	addl   $0x1,0xffffffec(%ebp)
  1043b2:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  1043b5:	3b 45 e4             	cmp    0xffffffe4(%ebp),%eax
  1043b8:	0f 8c 3b ff ff ff    	jl     1042f9 <spinlock_check+0x26a>
  1043be:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  1043c5:	eb 25                	jmp    1043ec <spinlock_check+0x35d>
  1043c7:	8b 4d e0             	mov    0xffffffe0(%ebp),%ecx
  1043ca:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  1043cd:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  1043d4:	8d 04 d5 00 00 00 00 	lea    0x0(,%edx,8),%eax
  1043db:	29 d0                	sub    %edx,%eax
  1043dd:	8d 04 01             	lea    (%ecx,%eax,1),%eax
  1043e0:	89 04 24             	mov    %eax,(%esp)
  1043e3:	e8 cd fb ff ff       	call   103fb5 <spinlock_release>
  1043e8:	83 45 ec 01          	addl   $0x1,0xffffffec(%ebp)
  1043ec:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  1043ef:	3b 45 e4             	cmp    0xffffffe4(%ebp),%eax
  1043f2:	7c d3                	jl     1043c7 <spinlock_check+0x338>
  1043f4:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  1043fb:	eb 49                	jmp    104446 <spinlock_check+0x3b7>
  1043fd:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  104400:	8b 4d e0             	mov    0xffffffe0(%ebp),%ecx
  104403:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  10440a:	8d 04 d5 00 00 00 00 	lea    0x0(,%edx,8),%eax
  104411:	29 d0                	sub    %edx,%eax
  104413:	01 c8                	add    %ecx,%eax
  104415:	83 c0 0c             	add    $0xc,%eax
  104418:	8b 00                	mov    (%eax),%eax
  10441a:	85 c0                	test   %eax,%eax
  10441c:	74 24                	je     104442 <spinlock_check+0x3b3>
  10441e:	c7 44 24 0c 1d ce 10 	movl   $0x10ce1d,0xc(%esp)
  104425:	00 
  104426:	c7 44 24 08 14 cd 10 	movl   $0x10cd14,0x8(%esp)
  10442d:	00 
  10442e:	c7 44 24 04 8d 00 00 	movl   $0x8d,0x4(%esp)
  104435:	00 
  104436:	c7 04 24 eb cc 10 00 	movl   $0x10cceb,(%esp)
  10443d:	e8 f6 c4 ff ff       	call   100938 <debug_panic>
  104442:	83 45 ec 01          	addl   $0x1,0xffffffec(%ebp)
  104446:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  104449:	3b 45 e4             	cmp    0xffffffe4(%ebp),%eax
  10444c:	7c af                	jl     1043fd <spinlock_check+0x36e>
  10444e:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  104455:	eb 49                	jmp    1044a0 <spinlock_check+0x411>
  104457:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  10445a:	8b 4d e0             	mov    0xffffffe0(%ebp),%ecx
  10445d:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  104464:	8d 04 d5 00 00 00 00 	lea    0x0(,%edx,8),%eax
  10446b:	29 d0                	sub    %edx,%eax
  10446d:	01 c8                	add    %ecx,%eax
  10446f:	83 c0 10             	add    $0x10,%eax
  104472:	8b 00                	mov    (%eax),%eax
  104474:	85 c0                	test   %eax,%eax
  104476:	74 24                	je     10449c <spinlock_check+0x40d>
  104478:	c7 44 24 0c 32 ce 10 	movl   $0x10ce32,0xc(%esp)
  10447f:	00 
  104480:	c7 44 24 08 14 cd 10 	movl   $0x10cd14,0x8(%esp)
  104487:	00 
  104488:	c7 44 24 04 8e 00 00 	movl   $0x8e,0x4(%esp)
  10448f:	00 
  104490:	c7 04 24 eb cc 10 00 	movl   $0x10cceb,(%esp)
  104497:	e8 9c c4 ff ff       	call   100938 <debug_panic>
  10449c:	83 45 ec 01          	addl   $0x1,0xffffffec(%ebp)
  1044a0:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  1044a3:	3b 45 e4             	cmp    0xffffffe4(%ebp),%eax
  1044a6:	7c af                	jl     104457 <spinlock_check+0x3c8>
  1044a8:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  1044af:	eb 4d                	jmp    1044fe <spinlock_check+0x46f>
  1044b1:	8b 4d e0             	mov    0xffffffe0(%ebp),%ecx
  1044b4:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  1044b7:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  1044be:	8d 04 d5 00 00 00 00 	lea    0x0(,%edx,8),%eax
  1044c5:	29 d0                	sub    %edx,%eax
  1044c7:	8d 04 01             	lea    (%ecx,%eax,1),%eax
  1044ca:	89 04 24             	mov    %eax,(%esp)
  1044cd:	e8 3d fb ff ff       	call   10400f <spinlock_holding>
  1044d2:	85 c0                	test   %eax,%eax
  1044d4:	74 24                	je     1044fa <spinlock_check+0x46b>
  1044d6:	c7 44 24 0c 48 ce 10 	movl   $0x10ce48,0xc(%esp)
  1044dd:	00 
  1044de:	c7 44 24 08 14 cd 10 	movl   $0x10cd14,0x8(%esp)
  1044e5:	00 
  1044e6:	c7 44 24 04 90 00 00 	movl   $0x90,0x4(%esp)
  1044ed:	00 
  1044ee:	c7 04 24 eb cc 10 00 	movl   $0x10cceb,(%esp)
  1044f5:	e8 3e c4 ff ff       	call   100938 <debug_panic>
  1044fa:	83 45 ec 01          	addl   $0x1,0xffffffec(%ebp)
  1044fe:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  104501:	3b 45 e4             	cmp    0xffffffe4(%ebp),%eax
  104504:	7c ab                	jl     1044b1 <spinlock_check+0x422>
  104506:	83 45 f4 01          	addl   $0x1,0xfffffff4(%ebp)
  10450a:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  10450d:	3b 45 e8             	cmp    0xffffffe8(%ebp),%eax
  104510:	0f 8c dd fc ff ff    	jl     1041f3 <spinlock_check+0x164>
  104516:	c7 04 24 69 ce 10 00 	movl   $0x10ce69,(%esp)
  10451d:	e8 4b 73 00 00       	call   10b86d <cprintf>
  104522:	8b 65 d8             	mov    0xffffffd8(%ebp),%esp
  104525:	8b 5d fc             	mov    0xfffffffc(%ebp),%ebx
  104528:	c9                   	leave  
  104529:	c3                   	ret    
  10452a:	90                   	nop    
  10452b:	90                   	nop    

0010452c <proc_init>:
  10452c:	55                   	push   %ebp
  10452d:	89 e5                	mov    %esp,%ebp
  10452f:	83 ec 18             	sub    $0x18,%esp
  104532:	e8 2c 00 00 00       	call   104563 <cpu_onboot>
  104537:	85 c0                	test   %eax,%eax
  104539:	74 26                	je     104561 <proc_init+0x35>
  10453b:	c7 44 24 08 33 00 00 	movl   $0x33,0x8(%esp)
  104542:	00 
  104543:	c7 44 24 04 88 ce 10 	movl   $0x10ce88,0x4(%esp)
  10454a:	00 
  10454b:	c7 04 24 40 da 17 00 	movl   $0x17da40,(%esp)
  104552:	e8 39 f9 ff ff       	call   103e90 <spinlock_init_>
  104557:	c7 05 7c da 17 00 78 	movl   $0x17da78,0x17da7c
  10455e:	da 17 00 
  104561:	c9                   	leave  
  104562:	c3                   	ret    

00104563 <cpu_onboot>:

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  104563:	55                   	push   %ebp
  104564:	89 e5                	mov    %esp,%ebp
  104566:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  104569:	e8 0d 00 00 00       	call   10457b <cpu_cur>
  10456e:	3d 00 f0 10 00       	cmp    $0x10f000,%eax
  104573:	0f 94 c0             	sete   %al
  104576:	0f b6 c0             	movzbl %al,%eax
}
  104579:	c9                   	leave  
  10457a:	c3                   	ret    

0010457b <cpu_cur>:
  10457b:	55                   	push   %ebp
  10457c:	89 e5                	mov    %esp,%ebp
  10457e:	83 ec 28             	sub    $0x28,%esp
static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  104581:	89 65 fc             	mov    %esp,0xfffffffc(%ebp)
        return esp;
  104584:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  104587:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  10458a:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10458d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  104592:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	assert(c->magic == CPU_MAGIC);
  104595:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  104598:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  10459e:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  1045a3:	74 24                	je     1045c9 <cpu_cur+0x4e>
  1045a5:	c7 44 24 0c 97 ce 10 	movl   $0x10ce97,0xc(%esp)
  1045ac:	00 
  1045ad:	c7 44 24 08 ad ce 10 	movl   $0x10cead,0x8(%esp)
  1045b4:	00 
  1045b5:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  1045bc:	00 
  1045bd:	c7 04 24 c2 ce 10 00 	movl   $0x10cec2,(%esp)
  1045c4:	e8 6f c3 ff ff       	call   100938 <debug_panic>
	return c;
  1045c9:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
}
  1045cc:	c9                   	leave  
  1045cd:	c3                   	ret    

001045ce <proc_alloc>:
  1045ce:	55                   	push   %ebp
  1045cf:	89 e5                	mov    %esp,%ebp
  1045d1:	83 ec 28             	sub    $0x28,%esp
  1045d4:	e8 8c ce ff ff       	call   101465 <mem_alloc>
  1045d9:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
  1045dc:	83 7d f4 00          	cmpl   $0x0,0xfffffff4(%ebp)
  1045e0:	75 0c                	jne    1045ee <proc_alloc+0x20>
  1045e2:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  1045e9:	e9 2d 02 00 00       	jmp    10481b <proc_alloc+0x24d>
  1045ee:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  1045f1:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  1045f4:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  1045f9:	83 c0 08             	add    $0x8,%eax
  1045fc:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  1045ff:	73 17                	jae    104618 <proc_alloc+0x4a>
  104601:	a1 d8 1d 18 00       	mov    0x181dd8,%eax
  104606:	c1 e0 03             	shl    $0x3,%eax
  104609:	89 c2                	mov    %eax,%edx
  10460b:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  104610:	8d 04 02             	lea    (%edx,%eax,1),%eax
  104613:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  104616:	77 24                	ja     10463c <proc_alloc+0x6e>
  104618:	c7 44 24 0c d0 ce 10 	movl   $0x10ced0,0xc(%esp)
  10461f:	00 
  104620:	c7 44 24 08 ad ce 10 	movl   $0x10cead,0x8(%esp)
  104627:	00 
  104628:	c7 44 24 04 9c 00 00 	movl   $0x9c,0x4(%esp)
  10462f:	00 
  104630:	c7 04 24 07 cf 10 00 	movl   $0x10cf07,(%esp)
  104637:	e8 fc c2 ff ff       	call   100938 <debug_panic>
  10463c:	8b 15 e0 1d 18 00    	mov    0x181de0,%edx
  104642:	b8 00 40 18 00       	mov    $0x184000,%eax
  104647:	c1 e8 0c             	shr    $0xc,%eax
  10464a:	c1 e0 03             	shl    $0x3,%eax
  10464d:	8d 04 02             	lea    (%edx,%eax,1),%eax
  104650:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  104653:	75 24                	jne    104679 <proc_alloc+0xab>
  104655:	c7 44 24 0c 15 cf 10 	movl   $0x10cf15,0xc(%esp)
  10465c:	00 
  10465d:	c7 44 24 08 ad ce 10 	movl   $0x10cead,0x8(%esp)
  104664:	00 
  104665:	c7 44 24 04 9e 00 00 	movl   $0x9e,0x4(%esp)
  10466c:	00 
  10466d:	c7 04 24 07 cf 10 00 	movl   $0x10cf07,(%esp)
  104674:	e8 bf c2 ff ff       	call   100938 <debug_panic>
  104679:	8b 15 e0 1d 18 00    	mov    0x181de0,%edx
  10467f:	b8 0c 00 10 00       	mov    $0x10000c,%eax
  104684:	c1 e8 0c             	shr    $0xc,%eax
  104687:	c1 e0 03             	shl    $0x3,%eax
  10468a:	8d 04 02             	lea    (%edx,%eax,1),%eax
  10468d:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  104690:	77 40                	ja     1046d2 <proc_alloc+0x104>
  104692:	8b 15 e0 1d 18 00    	mov    0x181de0,%edx
  104698:	b8 08 50 18 00       	mov    $0x185008,%eax
  10469d:	83 e8 01             	sub    $0x1,%eax
  1046a0:	c1 e8 0c             	shr    $0xc,%eax
  1046a3:	c1 e0 03             	shl    $0x3,%eax
  1046a6:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1046a9:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  1046ac:	72 24                	jb     1046d2 <proc_alloc+0x104>
  1046ae:	c7 44 24 0c 34 cf 10 	movl   $0x10cf34,0xc(%esp)
  1046b5:	00 
  1046b6:	c7 44 24 08 ad ce 10 	movl   $0x10cead,0x8(%esp)
  1046bd:	00 
  1046be:	c7 44 24 04 a0 00 00 	movl   $0xa0,0x4(%esp)
  1046c5:	00 
  1046c6:	c7 04 24 07 cf 10 00 	movl   $0x10cf07,(%esp)
  1046cd:	e8 66 c2 ff ff       	call   100938 <debug_panic>
  1046d2:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  1046d5:	83 c0 04             	add    $0x4,%eax
  1046d8:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  1046df:	00 
  1046e0:	89 04 24             	mov    %eax,(%esp)
  1046e3:	e8 38 01 00 00       	call   104820 <lockadd>
  1046e8:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  1046eb:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  1046f0:	89 d1                	mov    %edx,%ecx
  1046f2:	29 c1                	sub    %eax,%ecx
  1046f4:	89 c8                	mov    %ecx,%eax
  1046f6:	c1 e0 09             	shl    $0x9,%eax
  1046f9:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  1046fc:	c7 44 24 08 b0 06 00 	movl   $0x6b0,0x8(%esp)
  104703:	00 
  104704:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  10470b:	00 
  10470c:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10470f:	89 04 24             	mov    %eax,(%esp)
  104712:	e8 da 74 00 00       	call   10bbf1 <memset>
  104717:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10471a:	c7 44 24 08 46 00 00 	movl   $0x46,0x8(%esp)
  104721:	00 
  104722:	c7 44 24 04 88 ce 10 	movl   $0x10ce88,0x4(%esp)
  104729:	00 
  10472a:	89 04 24             	mov    %eax,(%esp)
  10472d:	e8 5e f7 ff ff       	call   103e90 <spinlock_init_>
  104732:	8b 55 f8             	mov    0xfffffff8(%ebp),%edx
  104735:	8b 45 08             	mov    0x8(%ebp),%eax
  104738:	89 42 38             	mov    %eax,0x38(%edx)
  10473b:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10473e:	c7 80 3c 04 00 00 00 	movl   $0x0,0x43c(%eax)
  104745:	00 00 00 
  104748:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10474b:	66 c7 80 7c 04 00 00 	movw   $0x23,0x47c(%eax)
  104752:	23 00 
  104754:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  104757:	66 c7 80 78 04 00 00 	movw   $0x23,0x478(%eax)
  10475e:	23 00 
  104760:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  104763:	66 c7 80 8c 04 00 00 	movw   $0x1b,0x48c(%eax)
  10476a:	1b 00 
  10476c:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10476f:	66 c7 80 98 04 00 00 	movw   $0x23,0x498(%eax)
  104776:	23 00 
  104778:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10477b:	66 c7 80 a0 04 00 00 	movw   $0x37f,0x4a0(%eax)
  104782:	7f 03 
  104784:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  104787:	c7 80 b8 04 00 00 80 	movl   $0x1f80,0x4b8(%eax)
  10478e:	1f 00 00 
  104791:	e8 94 18 00 00       	call   10602a <pmap_newpdir>
  104796:	89 c2                	mov    %eax,%edx
  104798:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10479b:	89 90 a0 06 00 00    	mov    %edx,0x6a0(%eax)
  1047a1:	e8 84 18 00 00       	call   10602a <pmap_newpdir>
  1047a6:	89 c2                	mov    %eax,%edx
  1047a8:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1047ab:	89 90 a4 06 00 00    	mov    %edx,0x6a4(%eax)
  1047b1:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1047b4:	8b 80 a0 06 00 00    	mov    0x6a0(%eax),%eax
  1047ba:	85 c0                	test   %eax,%eax
  1047bc:	74 0d                	je     1047cb <proc_alloc+0x1fd>
  1047be:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1047c1:	8b 80 a4 06 00 00    	mov    0x6a4(%eax),%eax
  1047c7:	85 c0                	test   %eax,%eax
  1047c9:	75 37                	jne    104802 <proc_alloc+0x234>
  1047cb:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1047ce:	8b 80 a0 06 00 00    	mov    0x6a0(%eax),%eax
  1047d4:	85 c0                	test   %eax,%eax
  1047d6:	74 21                	je     1047f9 <proc_alloc+0x22b>
  1047d8:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1047db:	8b 80 a0 06 00 00    	mov    0x6a0(%eax),%eax
  1047e1:	c1 e8 0c             	shr    $0xc,%eax
  1047e4:	c1 e0 03             	shl    $0x3,%eax
  1047e7:	89 c2                	mov    %eax,%edx
  1047e9:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  1047ee:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1047f1:	89 04 24             	mov    %eax,(%esp)
  1047f4:	e8 96 19 00 00       	call   10618f <pmap_freepdir>
  1047f9:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  104800:	eb 19                	jmp    10481b <proc_alloc+0x24d>
  104802:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  104806:	74 0d                	je     104815 <proc_alloc+0x247>
  104808:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  10480b:	8b 55 08             	mov    0x8(%ebp),%edx
  10480e:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  104811:	89 44 8a 3c          	mov    %eax,0x3c(%edx,%ecx,4)
  104815:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  104818:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  10481b:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  10481e:	c9                   	leave  
  10481f:	c3                   	ret    

00104820 <lockadd>:

// Atomically add incr to *addr.
static inline void
lockadd(volatile int32_t *addr, int32_t incr)
{
  104820:	55                   	push   %ebp
  104821:	89 e5                	mov    %esp,%ebp
	asm volatile("lock; addl %1,%0" : "+m" (*addr) : "r" (incr) : "cc");
  104823:	8b 4d 08             	mov    0x8(%ebp),%ecx
  104826:	8b 55 0c             	mov    0xc(%ebp),%edx
  104829:	8b 45 08             	mov    0x8(%ebp),%eax
  10482c:	f0 01 11             	lock add %edx,(%ecx)
}
  10482f:	5d                   	pop    %ebp
  104830:	c3                   	ret    

00104831 <proc_ready>:
  104831:	55                   	push   %ebp
  104832:	89 e5                	mov    %esp,%ebp
  104834:	83 ec 08             	sub    $0x8,%esp
  104837:	c7 04 24 40 da 17 00 	movl   $0x17da40,(%esp)
  10483e:	e8 77 f6 ff ff       	call   103eba <spinlock_acquire>
  104843:	8b 45 08             	mov    0x8(%ebp),%eax
  104846:	c7 80 3c 04 00 00 01 	movl   $0x1,0x43c(%eax)
  10484d:	00 00 00 
  104850:	8b 45 08             	mov    0x8(%ebp),%eax
  104853:	c7 80 40 04 00 00 00 	movl   $0x0,0x440(%eax)
  10485a:	00 00 00 
  10485d:	8b 15 7c da 17 00    	mov    0x17da7c,%edx
  104863:	8b 45 08             	mov    0x8(%ebp),%eax
  104866:	89 02                	mov    %eax,(%edx)
  104868:	8b 45 08             	mov    0x8(%ebp),%eax
  10486b:	05 40 04 00 00       	add    $0x440,%eax
  104870:	a3 7c da 17 00       	mov    %eax,0x17da7c
  104875:	c7 04 24 40 da 17 00 	movl   $0x17da40,(%esp)
  10487c:	e8 34 f7 ff ff       	call   103fb5 <spinlock_release>
  104881:	c9                   	leave  
  104882:	c3                   	ret    

00104883 <proc_save>:
  104883:	55                   	push   %ebp
  104884:	89 e5                	mov    %esp,%ebp
  104886:	83 ec 18             	sub    $0x18,%esp
  104889:	e8 ed fc ff ff       	call   10457b <cpu_cur>
  10488e:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  104894:	3b 45 08             	cmp    0x8(%ebp),%eax
  104897:	74 24                	je     1048bd <proc_save+0x3a>
  104899:	c7 44 24 0c 65 cf 10 	movl   $0x10cf65,0xc(%esp)
  1048a0:	00 
  1048a1:	c7 44 24 08 ad ce 10 	movl   $0x10cead,0x8(%esp)
  1048a8:	00 
  1048a9:	c7 44 24 04 89 00 00 	movl   $0x89,0x4(%esp)
  1048b0:	00 
  1048b1:	c7 04 24 88 ce 10 00 	movl   $0x10ce88,(%esp)
  1048b8:	e8 7b c0 ff ff       	call   100938 <debug_panic>
  1048bd:	8b 45 08             	mov    0x8(%ebp),%eax
  1048c0:	05 50 04 00 00       	add    $0x450,%eax
  1048c5:	3b 45 0c             	cmp    0xc(%ebp),%eax
  1048c8:	74 21                	je     1048eb <proc_save+0x68>
  1048ca:	8b 45 08             	mov    0x8(%ebp),%eax
  1048cd:	8b 55 0c             	mov    0xc(%ebp),%edx
  1048d0:	8d 88 50 04 00 00    	lea    0x450(%eax),%ecx
  1048d6:	b8 4c 00 00 00       	mov    $0x4c,%eax
  1048db:	89 44 24 08          	mov    %eax,0x8(%esp)
  1048df:	89 54 24 04          	mov    %edx,0x4(%esp)
  1048e3:	89 0c 24             	mov    %ecx,(%esp)
  1048e6:	e8 45 74 00 00       	call   10bd30 <memcpy>
  1048eb:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  1048ef:	75 15                	jne    104906 <proc_save+0x83>
  1048f1:	8b 45 08             	mov    0x8(%ebp),%eax
  1048f4:	8b 80 88 04 00 00    	mov    0x488(%eax),%eax
  1048fa:	8d 50 fe             	lea    0xfffffffe(%eax),%edx
  1048fd:	8b 45 08             	mov    0x8(%ebp),%eax
  104900:	89 90 88 04 00 00    	mov    %edx,0x488(%eax)
  104906:	c9                   	leave  
  104907:	c3                   	ret    

00104908 <proc_wait>:
  104908:	55                   	push   %ebp
  104909:	89 e5                	mov    %esp,%ebp
  10490b:	83 ec 18             	sub    $0x18,%esp
  10490e:	8b 45 08             	mov    0x8(%ebp),%eax
  104911:	89 04 24             	mov    %eax,(%esp)
  104914:	e8 f6 f6 ff ff       	call   10400f <spinlock_holding>
  104919:	85 c0                	test   %eax,%eax
  10491b:	75 24                	jne    104941 <proc_wait+0x39>
  10491d:	c7 44 24 0c 75 cf 10 	movl   $0x10cf75,0xc(%esp)
  104924:	00 
  104925:	c7 44 24 08 ad ce 10 	movl   $0x10cead,0x8(%esp)
  10492c:	00 
  10492d:	c7 44 24 04 b7 00 00 	movl   $0xb7,0x4(%esp)
  104934:	00 
  104935:	c7 04 24 88 ce 10 00 	movl   $0x10ce88,(%esp)
  10493c:	e8 f7 bf ff ff       	call   100938 <debug_panic>
  104941:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  104945:	74 09                	je     104950 <proc_wait+0x48>
  104947:	81 7d 0c 00 1e 18 00 	cmpl   $0x181e00,0xc(%ebp)
  10494e:	75 24                	jne    104974 <proc_wait+0x6c>
  104950:	c7 44 24 0c 90 cf 10 	movl   $0x10cf90,0xc(%esp)
  104957:	00 
  104958:	c7 44 24 08 ad ce 10 	movl   $0x10cead,0x8(%esp)
  10495f:	00 
  104960:	c7 44 24 04 b8 00 00 	movl   $0xb8,0x4(%esp)
  104967:	00 
  104968:	c7 04 24 88 ce 10 00 	movl   $0x10ce88,(%esp)
  10496f:	e8 c4 bf ff ff       	call   100938 <debug_panic>
  104974:	8b 45 0c             	mov    0xc(%ebp),%eax
  104977:	8b 80 3c 04 00 00    	mov    0x43c(%eax),%eax
  10497d:	85 c0                	test   %eax,%eax
  10497f:	75 24                	jne    1049a5 <proc_wait+0x9d>
  104981:	c7 44 24 0c a7 cf 10 	movl   $0x10cfa7,0xc(%esp)
  104988:	00 
  104989:	c7 44 24 08 ad ce 10 	movl   $0x10cead,0x8(%esp)
  104990:	00 
  104991:	c7 44 24 04 b9 00 00 	movl   $0xb9,0x4(%esp)
  104998:	00 
  104999:	c7 04 24 88 ce 10 00 	movl   $0x10ce88,(%esp)
  1049a0:	e8 93 bf ff ff       	call   100938 <debug_panic>
  1049a5:	8b 45 08             	mov    0x8(%ebp),%eax
  1049a8:	c7 80 3c 04 00 00 03 	movl   $0x3,0x43c(%eax)
  1049af:	00 00 00 
  1049b2:	8b 45 08             	mov    0x8(%ebp),%eax
  1049b5:	c7 80 44 04 00 00 00 	movl   $0x0,0x444(%eax)
  1049bc:	00 00 00 
  1049bf:	8b 55 08             	mov    0x8(%ebp),%edx
  1049c2:	8b 45 0c             	mov    0xc(%ebp),%eax
  1049c5:	89 82 48 04 00 00    	mov    %eax,0x448(%edx)
  1049cb:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  1049d2:	00 
  1049d3:	8b 45 10             	mov    0x10(%ebp),%eax
  1049d6:	89 44 24 04          	mov    %eax,0x4(%esp)
  1049da:	8b 45 08             	mov    0x8(%ebp),%eax
  1049dd:	89 04 24             	mov    %eax,(%esp)
  1049e0:	e8 9e fe ff ff       	call   104883 <proc_save>
  1049e5:	8b 45 08             	mov    0x8(%ebp),%eax
  1049e8:	89 04 24             	mov    %eax,(%esp)
  1049eb:	e8 c5 f5 ff ff       	call   103fb5 <spinlock_release>
  1049f0:	e8 00 00 00 00       	call   1049f5 <proc_sched>

001049f5 <proc_sched>:
  1049f5:	55                   	push   %ebp
  1049f6:	89 e5                	mov    %esp,%ebp
  1049f8:	83 ec 28             	sub    $0x28,%esp
  1049fb:	e8 7b fb ff ff       	call   10457b <cpu_cur>
  104a00:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  104a03:	c7 04 24 40 da 17 00 	movl   $0x17da40,(%esp)
  104a0a:	e8 ab f4 ff ff       	call   103eba <spinlock_acquire>
  104a0f:	eb 2a                	jmp    104a3b <proc_sched+0x46>
  104a11:	c7 04 24 40 da 17 00 	movl   $0x17da40,(%esp)
  104a18:	e8 98 f5 ff ff       	call   103fb5 <spinlock_release>
  104a1d:	eb 07                	jmp    104a26 <proc_sched+0x31>

// Atomically add incr to *addr and return true if the result is zero.
static inline uint8_t
lockaddz(volatile int32_t *addr, int32_t incr)
{
	uint8_t zero;
	asm volatile("lock; addl %2,%0; setzb %1"
		: "+m" (*addr), "=rm" (zero)
		: "r" (incr)
		: "cc");
	return zero;
}

// Atomically add incr to *addr and return the old value of *addr.
static inline int32_t
xadd(volatile uint32_t *addr, int32_t incr)
{
	int32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xaddl %0, %1" :
	       "+m" (*addr), "=a" (result) :
	       "1" (incr) :
	       "cc");
	return result;
}

static inline void
pause(void)
{
	asm volatile("pause" : : : "memory");
}

static gcc_inline void
cpuid(uint32_t idx, cpuinfo *info)
{
	asm volatile("cpuid" 
		: "=a" (info->eax), "=b" (info->ebx),
		  "=c" (info->ecx), "=d" (info->edx)
		: "a" (idx));
}

static gcc_inline uint64_t
rdtsc(void)
{
        uint64_t tsc;
        asm volatile("rdtsc" : "=A" (tsc));
        return tsc;
}

// Enable external device interrupts.
static gcc_inline void
sti(void)
{
	asm volatile("sti");
  104a1f:	fb                   	sti    
  104a20:	e8 ad 00 00 00       	call   104ad2 <pause>
}

// Disable external device interrupts.
static gcc_inline void
cli(void)
{
	asm volatile("cli");
  104a25:	fa                   	cli    
  104a26:	a1 78 da 17 00       	mov    0x17da78,%eax
  104a2b:	85 c0                	test   %eax,%eax
  104a2d:	74 f0                	je     104a1f <proc_sched+0x2a>
  104a2f:	c7 04 24 40 da 17 00 	movl   $0x17da40,(%esp)
  104a36:	e8 7f f4 ff ff       	call   103eba <spinlock_acquire>
  104a3b:	a1 78 da 17 00       	mov    0x17da78,%eax
  104a40:	85 c0                	test   %eax,%eax
  104a42:	74 cd                	je     104a11 <proc_sched+0x1c>
  104a44:	a1 78 da 17 00       	mov    0x17da78,%eax
  104a49:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  104a4c:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  104a4f:	8b 80 40 04 00 00    	mov    0x440(%eax),%eax
  104a55:	a3 78 da 17 00       	mov    %eax,0x17da78
  104a5a:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  104a5d:	81 c2 40 04 00 00    	add    $0x440,%edx
  104a63:	a1 7c da 17 00       	mov    0x17da7c,%eax
  104a68:	39 c2                	cmp    %eax,%edx
  104a6a:	75 37                	jne    104aa3 <proc_sched+0xae>
  104a6c:	a1 78 da 17 00       	mov    0x17da78,%eax
  104a71:	85 c0                	test   %eax,%eax
  104a73:	74 24                	je     104a99 <proc_sched+0xa4>
  104a75:	c7 44 24 0c be cf 10 	movl   $0x10cfbe,0xc(%esp)
  104a7c:	00 
  104a7d:	c7 44 24 08 ad ce 10 	movl   $0x10cead,0x8(%esp)
  104a84:	00 
  104a85:	c7 44 24 04 e4 00 00 	movl   $0xe4,0x4(%esp)
  104a8c:	00 
  104a8d:	c7 04 24 88 ce 10 00 	movl   $0x10ce88,(%esp)
  104a94:	e8 9f be ff ff       	call   100938 <debug_panic>
  104a99:	c7 05 7c da 17 00 78 	movl   $0x17da78,0x17da7c
  104aa0:	da 17 00 
  104aa3:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  104aa6:	c7 80 40 04 00 00 00 	movl   $0x0,0x440(%eax)
  104aad:	00 00 00 
  104ab0:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  104ab3:	89 04 24             	mov    %eax,(%esp)
  104ab6:	e8 ff f3 ff ff       	call   103eba <spinlock_acquire>
  104abb:	c7 04 24 40 da 17 00 	movl   $0x17da40,(%esp)
  104ac2:	e8 ee f4 ff ff       	call   103fb5 <spinlock_release>
  104ac7:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  104aca:	89 04 24             	mov    %eax,(%esp)
  104acd:	e8 07 00 00 00       	call   104ad9 <proc_run>

00104ad2 <pause>:
  104ad2:	55                   	push   %ebp
  104ad3:	89 e5                	mov    %esp,%ebp
  104ad5:	f3 90                	pause  
  104ad7:	5d                   	pop    %ebp
  104ad8:	c3                   	ret    

00104ad9 <proc_run>:
  104ad9:	55                   	push   %ebp
  104ada:	89 e5                	mov    %esp,%ebp
  104adc:	83 ec 28             	sub    $0x28,%esp
  104adf:	8b 45 08             	mov    0x8(%ebp),%eax
  104ae2:	89 04 24             	mov    %eax,(%esp)
  104ae5:	e8 25 f5 ff ff       	call   10400f <spinlock_holding>
  104aea:	85 c0                	test   %eax,%eax
  104aec:	75 24                	jne    104b12 <proc_run+0x39>
  104aee:	c7 44 24 0c 75 cf 10 	movl   $0x10cf75,0xc(%esp)
  104af5:	00 
  104af6:	c7 44 24 08 ad ce 10 	movl   $0x10cead,0x8(%esp)
  104afd:	00 
  104afe:	c7 44 24 04 f8 00 00 	movl   $0xf8,0x4(%esp)
  104b05:	00 
  104b06:	c7 04 24 88 ce 10 00 	movl   $0x10ce88,(%esp)
  104b0d:	e8 26 be ff ff       	call   100938 <debug_panic>
  104b12:	e8 64 fa ff ff       	call   10457b <cpu_cur>
  104b17:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  104b1a:	8b 45 08             	mov    0x8(%ebp),%eax
  104b1d:	c7 80 3c 04 00 00 02 	movl   $0x2,0x43c(%eax)
  104b24:	00 00 00 
  104b27:	8b 55 08             	mov    0x8(%ebp),%edx
  104b2a:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  104b2d:	89 82 44 04 00 00    	mov    %eax,0x444(%edx)
  104b33:	8b 55 f8             	mov    0xfffffff8(%ebp),%edx
  104b36:	8b 45 08             	mov    0x8(%ebp),%eax
  104b39:	89 82 b4 00 00 00    	mov    %eax,0xb4(%edx)
  104b3f:	8b 45 08             	mov    0x8(%ebp),%eax
  104b42:	89 04 24             	mov    %eax,(%esp)
  104b45:	e8 6b f4 ff ff       	call   103fb5 <spinlock_release>
  104b4a:	8b 45 08             	mov    0x8(%ebp),%eax
  104b4d:	8b 80 a0 06 00 00    	mov    0x6a0(%eax),%eax
  104b53:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  104b56:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  104b59:	0f 22 d8             	mov    %eax,%cr3
  104b5c:	8b 45 08             	mov    0x8(%ebp),%eax
  104b5f:	05 50 04 00 00       	add    $0x450,%eax
  104b64:	89 04 24             	mov    %eax,(%esp)
  104b67:	e8 f4 ee ff ff       	call   103a60 <trap_return>

00104b6c <proc_yield>:
  104b6c:	55                   	push   %ebp
  104b6d:	89 e5                	mov    %esp,%ebp
  104b6f:	53                   	push   %ebx
  104b70:	83 ec 24             	sub    $0x24,%esp
  104b73:	e8 03 fa ff ff       	call   10457b <cpu_cur>
  104b78:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  104b7e:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  104b81:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  104b84:	8b 98 44 04 00 00    	mov    0x444(%eax),%ebx
  104b8a:	e8 ec f9 ff ff       	call   10457b <cpu_cur>
  104b8f:	39 c3                	cmp    %eax,%ebx
  104b91:	74 24                	je     104bb7 <proc_yield+0x4b>
  104b93:	c7 44 24 0c d0 cf 10 	movl   $0x10cfd0,0xc(%esp)
  104b9a:	00 
  104b9b:	c7 44 24 08 ad ce 10 	movl   $0x10cead,0x8(%esp)
  104ba2:	00 
  104ba3:	c7 44 24 04 38 01 00 	movl   $0x138,0x4(%esp)
  104baa:	00 
  104bab:	c7 04 24 88 ce 10 00 	movl   $0x10ce88,(%esp)
  104bb2:	e8 81 bd ff ff       	call   100938 <debug_panic>
  104bb7:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  104bba:	c7 80 44 04 00 00 00 	movl   $0x0,0x444(%eax)
  104bc1:	00 00 00 
  104bc4:	c7 44 24 08 ff ff ff 	movl   $0xffffffff,0x8(%esp)
  104bcb:	ff 
  104bcc:	8b 45 08             	mov    0x8(%ebp),%eax
  104bcf:	89 44 24 04          	mov    %eax,0x4(%esp)
  104bd3:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  104bd6:	89 04 24             	mov    %eax,(%esp)
  104bd9:	e8 a5 fc ff ff       	call   104883 <proc_save>
  104bde:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  104be1:	89 04 24             	mov    %eax,(%esp)
  104be4:	e8 48 fc ff ff       	call   104831 <proc_ready>
  104be9:	e8 07 fe ff ff       	call   1049f5 <proc_sched>

00104bee <proc_ret>:
  104bee:	55                   	push   %ebp
  104bef:	89 e5                	mov    %esp,%ebp
  104bf1:	53                   	push   %ebx
  104bf2:	83 ec 24             	sub    $0x24,%esp
  104bf5:	e8 81 f9 ff ff       	call   10457b <cpu_cur>
  104bfa:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  104c00:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
  104c03:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  104c06:	8b 80 3c 04 00 00    	mov    0x43c(%eax),%eax
  104c0c:	83 f8 02             	cmp    $0x2,%eax
  104c0f:	75 12                	jne    104c23 <proc_ret+0x35>
  104c11:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  104c14:	8b 98 44 04 00 00    	mov    0x444(%eax),%ebx
  104c1a:	e8 5c f9 ff ff       	call   10457b <cpu_cur>
  104c1f:	39 c3                	cmp    %eax,%ebx
  104c21:	74 24                	je     104c47 <proc_ret+0x59>
  104c23:	c7 44 24 0c e8 cf 10 	movl   $0x10cfe8,0xc(%esp)
  104c2a:	00 
  104c2b:	c7 44 24 08 ad ce 10 	movl   $0x10cead,0x8(%esp)
  104c32:	00 
  104c33:	c7 44 24 04 4c 01 00 	movl   $0x14c,0x4(%esp)
  104c3a:	00 
  104c3b:	c7 04 24 88 ce 10 00 	movl   $0x10ce88,(%esp)
  104c42:	e8 f1 bc ff ff       	call   100938 <debug_panic>
  104c47:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  104c4a:	8b 40 38             	mov    0x38(%eax),%eax
  104c4d:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  104c50:	83 7d f8 00          	cmpl   $0x0,0xfffffff8(%ebp)
  104c54:	75 67                	jne    104cbd <proc_ret+0xcf>
  104c56:	8b 45 08             	mov    0x8(%ebp),%eax
  104c59:	8b 40 30             	mov    0x30(%eax),%eax
  104c5c:	83 f8 30             	cmp    $0x30,%eax
  104c5f:	74 27                	je     104c88 <proc_ret+0x9a>
  104c61:	8b 45 08             	mov    0x8(%ebp),%eax
  104c64:	89 04 24             	mov    %eax,(%esp)
  104c67:	e8 5a e5 ff ff       	call   1031c6 <trap_print>
  104c6c:	c7 44 24 08 19 d0 10 	movl   $0x10d019,0x8(%esp)
  104c73:	00 
  104c74:	c7 44 24 04 5a 01 00 	movl   $0x15a,0x4(%esp)
  104c7b:	00 
  104c7c:	c7 04 24 88 ce 10 00 	movl   $0x10ce88,(%esp)
  104c83:	e8 b0 bc ff ff       	call   100938 <debug_panic>
  104c88:	83 7d 0c 01          	cmpl   $0x1,0xc(%ebp)
  104c8c:	74 24                	je     104cb2 <proc_ret+0xc4>
  104c8e:	c7 44 24 0c 2e d0 10 	movl   $0x10d02e,0xc(%esp)
  104c95:	00 
  104c96:	c7 44 24 08 ad ce 10 	movl   $0x10cead,0x8(%esp)
  104c9d:	00 
  104c9e:	c7 44 24 04 5f 01 00 	movl   $0x15f,0x4(%esp)
  104ca5:	00 
  104ca6:	c7 04 24 88 ce 10 00 	movl   $0x10ce88,(%esp)
  104cad:	e8 86 bc ff ff       	call   100938 <debug_panic>
  104cb2:	8b 45 08             	mov    0x8(%ebp),%eax
  104cb5:	89 04 24             	mov    %eax,(%esp)
  104cb8:	e8 70 54 00 00       	call   10a12d <file_io>
  104cbd:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  104cc0:	89 04 24             	mov    %eax,(%esp)
  104cc3:	e8 f2 f1 ff ff       	call   103eba <spinlock_acquire>
  104cc8:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  104ccb:	c7 80 3c 04 00 00 00 	movl   $0x0,0x43c(%eax)
  104cd2:	00 00 00 
  104cd5:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  104cd8:	c7 80 44 04 00 00 00 	movl   $0x0,0x444(%eax)
  104cdf:	00 00 00 
  104ce2:	8b 45 0c             	mov    0xc(%ebp),%eax
  104ce5:	89 44 24 08          	mov    %eax,0x8(%esp)
  104ce9:	8b 45 08             	mov    0x8(%ebp),%eax
  104cec:	89 44 24 04          	mov    %eax,0x4(%esp)
  104cf0:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  104cf3:	89 04 24             	mov    %eax,(%esp)
  104cf6:	e8 88 fb ff ff       	call   104883 <proc_save>
  104cfb:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  104cfe:	8b 80 3c 04 00 00    	mov    0x43c(%eax),%eax
  104d04:	83 f8 03             	cmp    $0x3,%eax
  104d07:	75 26                	jne    104d2f <proc_ret+0x141>
  104d09:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  104d0c:	8b 80 48 04 00 00    	mov    0x448(%eax),%eax
  104d12:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  104d15:	75 18                	jne    104d2f <proc_ret+0x141>
  104d17:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  104d1a:	c7 80 48 04 00 00 00 	movl   $0x0,0x448(%eax)
  104d21:	00 00 00 
  104d24:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  104d27:	89 04 24             	mov    %eax,(%esp)
  104d2a:	e8 aa fd ff ff       	call   104ad9 <proc_run>
  104d2f:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  104d32:	89 04 24             	mov    %eax,(%esp)
  104d35:	e8 7b f2 ff ff       	call   103fb5 <spinlock_release>
  104d3a:	e8 b6 fc ff ff       	call   1049f5 <proc_sched>

00104d3f <proc_check>:
  104d3f:	55                   	push   %ebp
  104d40:	89 e5                	mov    %esp,%ebp
  104d42:	57                   	push   %edi
  104d43:	56                   	push   %esi
  104d44:	53                   	push   %ebx
  104d45:	81 ec dc 00 00 00    	sub    $0xdc,%esp
  104d4b:	c7 85 40 ff ff ff 00 	movl   $0x0,0xffffff40(%ebp)
  104d52:	00 00 00 
  104d55:	e9 12 01 00 00       	jmp    104e6c <proc_check+0x12d>
  104d5a:	8b 85 40 ff ff ff    	mov    0xffffff40(%ebp),%eax
  104d60:	c1 e0 0c             	shl    $0xc,%eax
  104d63:	89 c2                	mov    %eax,%edx
  104d65:	b8 d0 dc 17 00       	mov    $0x17dcd0,%eax
  104d6a:	05 00 10 00 00       	add    $0x1000,%eax
  104d6f:	8d 04 02             	lea    (%edx,%eax,1),%eax
  104d72:	89 85 44 ff ff ff    	mov    %eax,0xffffff44(%ebp)
  104d78:	83 ad 44 ff ff ff 04 	subl   $0x4,0xffffff44(%ebp)
  104d7f:	8b 95 40 ff ff ff    	mov    0xffffff40(%ebp),%edx
  104d85:	8b 85 44 ff ff ff    	mov    0xffffff44(%ebp),%eax
  104d8b:	89 10                	mov    %edx,(%eax)
  104d8d:	83 ad 44 ff ff ff 04 	subl   $0x4,0xffffff44(%ebp)
  104d94:	8b 85 44 ff ff ff    	mov    0xffffff44(%ebp),%eax
  104d9a:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  104da0:	b8 2a 52 10 00       	mov    $0x10522a,%eax
  104da5:	a3 b8 da 17 00       	mov    %eax,0x17dab8
  104daa:	8b 85 44 ff ff ff    	mov    0xffffff44(%ebp),%eax
  104db0:	a3 c4 da 17 00       	mov    %eax,0x17dac4
  104db5:	8b 85 40 ff ff ff    	mov    0xffffff40(%ebp),%eax
  104dbb:	89 44 24 04          	mov    %eax,0x4(%esp)
  104dbf:	c7 04 24 39 d0 10 00 	movl   $0x10d039,(%esp)
  104dc6:	e8 a2 6a 00 00       	call   10b86d <cprintf>
  104dcb:	8b 85 40 ff ff ff    	mov    0xffffff40(%ebp),%eax
  104dd1:	0f b7 c0             	movzwl %ax,%eax
  104dd4:	89 85 2c ff ff ff    	mov    %eax,0xffffff2c(%ebp)
  104dda:	83 bd 40 ff ff ff 01 	cmpl   $0x1,0xffffff40(%ebp)
  104de1:	7f 0c                	jg     104def <proc_check+0xb0>
  104de3:	c7 85 30 ff ff ff 10 	movl   $0x1010,0xffffff30(%ebp)
  104dea:	10 00 00 
  104ded:	eb 0a                	jmp    104df9 <proc_check+0xba>
  104def:	c7 85 30 ff ff ff 00 	movl   $0x1000,0xffffff30(%ebp)
  104df6:	10 00 00 
  104df9:	8b 85 30 ff ff ff    	mov    0xffffff30(%ebp),%eax
  104dff:	89 85 60 ff ff ff    	mov    %eax,0xffffff60(%ebp)
  104e05:	0f b7 85 2c ff ff ff 	movzwl 0xffffff2c(%ebp),%eax
  104e0c:	66 89 85 5e ff ff ff 	mov    %ax,0xffffff5e(%ebp)
  104e13:	c7 85 58 ff ff ff 80 	movl   $0x17da80,0xffffff58(%ebp)
  104e1a:	da 17 00 
  104e1d:	c7 85 54 ff ff ff 00 	movl   $0x0,0xffffff54(%ebp)
  104e24:	00 00 00 
  104e27:	c7 85 50 ff ff ff 00 	movl   $0x0,0xffffff50(%ebp)
  104e2e:	00 00 00 
  104e31:	c7 85 4c ff ff ff 00 	movl   $0x0,0xffffff4c(%ebp)
  104e38:	00 00 00 
static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
  104e3b:	8b 85 60 ff ff ff    	mov    0xffffff60(%ebp),%eax
  104e41:	83 c8 01             	or     $0x1,%eax
  104e44:	8b 9d 58 ff ff ff    	mov    0xffffff58(%ebp),%ebx
  104e4a:	0f b7 95 5e ff ff ff 	movzwl 0xffffff5e(%ebp),%edx
  104e51:	8b b5 54 ff ff ff    	mov    0xffffff54(%ebp),%esi
  104e57:	8b bd 50 ff ff ff    	mov    0xffffff50(%ebp),%edi
  104e5d:	8b 8d 4c ff ff ff    	mov    0xffffff4c(%ebp),%ecx
  104e63:	cd 30                	int    $0x30
  104e65:	83 85 40 ff ff ff 01 	addl   $0x1,0xffffff40(%ebp)
  104e6c:	83 bd 40 ff ff ff 03 	cmpl   $0x3,0xffffff40(%ebp)
  104e73:	0f 8e e1 fe ff ff    	jle    104d5a <proc_check+0x1b>
  104e79:	c7 85 40 ff ff ff 00 	movl   $0x0,0xffffff40(%ebp)
  104e80:	00 00 00 
  104e83:	e9 89 00 00 00       	jmp    104f11 <proc_check+0x1d2>
  104e88:	8b 85 40 ff ff ff    	mov    0xffffff40(%ebp),%eax
  104e8e:	89 44 24 04          	mov    %eax,0x4(%esp)
  104e92:	c7 04 24 4c d0 10 00 	movl   $0x10d04c,(%esp)
  104e99:	e8 cf 69 00 00       	call   10b86d <cprintf>
  104e9e:	8b 85 40 ff ff ff    	mov    0xffffff40(%ebp),%eax
  104ea4:	0f b7 c0             	movzwl %ax,%eax
  104ea7:	c7 85 78 ff ff ff 00 	movl   $0x1000,0xffffff78(%ebp)
  104eae:	10 00 00 
  104eb1:	66 89 85 76 ff ff ff 	mov    %ax,0xffffff76(%ebp)
  104eb8:	c7 85 70 ff ff ff 80 	movl   $0x17da80,0xffffff70(%ebp)
  104ebf:	da 17 00 
  104ec2:	c7 85 6c ff ff ff 00 	movl   $0x0,0xffffff6c(%ebp)
  104ec9:	00 00 00 
  104ecc:	c7 85 68 ff ff ff 00 	movl   $0x0,0xffffff68(%ebp)
  104ed3:	00 00 00 
  104ed6:	c7 85 64 ff ff ff 00 	movl   $0x0,0xffffff64(%ebp)
  104edd:	00 00 00 
		: "i" (T_SYSCALL),
		  "a" (SYS_PUT | flags),
		  "b" (save),
		  "d" (child),
		  "S" (localsrc),
		  "D" (childdest),
		  "c" (size)
		: "cc", "memory");
}

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
  104ee0:	8b 85 78 ff ff ff    	mov    0xffffff78(%ebp),%eax
  104ee6:	83 c8 02             	or     $0x2,%eax
  104ee9:	8b 9d 70 ff ff ff    	mov    0xffffff70(%ebp),%ebx
  104eef:	0f b7 95 76 ff ff ff 	movzwl 0xffffff76(%ebp),%edx
  104ef6:	8b b5 6c ff ff ff    	mov    0xffffff6c(%ebp),%esi
  104efc:	8b bd 68 ff ff ff    	mov    0xffffff68(%ebp),%edi
  104f02:	8b 8d 64 ff ff ff    	mov    0xffffff64(%ebp),%ecx
  104f08:	cd 30                	int    $0x30
  104f0a:	83 85 40 ff ff ff 01 	addl   $0x1,0xffffff40(%ebp)
  104f11:	83 bd 40 ff ff ff 01 	cmpl   $0x1,0xffffff40(%ebp)
  104f18:	0f 8e 6a ff ff ff    	jle    104e88 <proc_check+0x149>
  104f1e:	c7 04 24 64 d0 10 00 	movl   $0x10d064,(%esp)
  104f25:	e8 43 69 00 00       	call   10b86d <cprintf>
  104f2a:	c7 04 24 8c d0 10 00 	movl   $0x10d08c,(%esp)
  104f31:	e8 37 69 00 00       	call   10b86d <cprintf>
  104f36:	c7 85 40 ff ff ff 00 	movl   $0x0,0xffffff40(%ebp)
  104f3d:	00 00 00 
  104f40:	eb 6b                	jmp    104fad <proc_check+0x26e>
  104f42:	8b 85 40 ff ff ff    	mov    0xffffff40(%ebp),%eax
  104f48:	89 44 24 04          	mov    %eax,0x4(%esp)
  104f4c:	c7 04 24 39 d0 10 00 	movl   $0x10d039,(%esp)
  104f53:	e8 15 69 00 00       	call   10b86d <cprintf>
  104f58:	8b 85 40 ff ff ff    	mov    0xffffff40(%ebp),%eax
  104f5e:	0f b7 c0             	movzwl %ax,%eax
  104f61:	c7 45 90 10 00 00 00 	movl   $0x10,0xffffff90(%ebp)
  104f68:	66 89 45 8e          	mov    %ax,0xffffff8e(%ebp)
  104f6c:	c7 45 88 00 00 00 00 	movl   $0x0,0xffffff88(%ebp)
  104f73:	c7 45 84 00 00 00 00 	movl   $0x0,0xffffff84(%ebp)
  104f7a:	c7 45 80 00 00 00 00 	movl   $0x0,0xffffff80(%ebp)
  104f81:	c7 85 7c ff ff ff 00 	movl   $0x0,0xffffff7c(%ebp)
  104f88:	00 00 00 
  104f8b:	8b 45 90             	mov    0xffffff90(%ebp),%eax
  104f8e:	83 c8 01             	or     $0x1,%eax
  104f91:	8b 5d 88             	mov    0xffffff88(%ebp),%ebx
  104f94:	0f b7 55 8e          	movzwl 0xffffff8e(%ebp),%edx
  104f98:	8b 75 84             	mov    0xffffff84(%ebp),%esi
  104f9b:	8b 7d 80             	mov    0xffffff80(%ebp),%edi
  104f9e:	8b 8d 7c ff ff ff    	mov    0xffffff7c(%ebp),%ecx
  104fa4:	cd 30                	int    $0x30
  104fa6:	83 85 40 ff ff ff 01 	addl   $0x1,0xffffff40(%ebp)
  104fad:	83 bd 40 ff ff ff 03 	cmpl   $0x3,0xffffff40(%ebp)
  104fb4:	7e 8c                	jle    104f42 <proc_check+0x203>
  104fb6:	c7 85 40 ff ff ff 00 	movl   $0x0,0xffffff40(%ebp)
  104fbd:	00 00 00 
  104fc0:	eb 4f                	jmp    105011 <proc_check+0x2d2>
  104fc2:	8b 85 40 ff ff ff    	mov    0xffffff40(%ebp),%eax
  104fc8:	0f b7 c0             	movzwl %ax,%eax
  104fcb:	c7 45 a8 00 00 00 00 	movl   $0x0,0xffffffa8(%ebp)
  104fd2:	66 89 45 a6          	mov    %ax,0xffffffa6(%ebp)
  104fd6:	c7 45 a0 00 00 00 00 	movl   $0x0,0xffffffa0(%ebp)
  104fdd:	c7 45 9c 00 00 00 00 	movl   $0x0,0xffffff9c(%ebp)
  104fe4:	c7 45 98 00 00 00 00 	movl   $0x0,0xffffff98(%ebp)
  104feb:	c7 45 94 00 00 00 00 	movl   $0x0,0xffffff94(%ebp)
  104ff2:	8b 45 a8             	mov    0xffffffa8(%ebp),%eax
  104ff5:	83 c8 02             	or     $0x2,%eax
  104ff8:	8b 5d a0             	mov    0xffffffa0(%ebp),%ebx
  104ffb:	0f b7 55 a6          	movzwl 0xffffffa6(%ebp),%edx
  104fff:	8b 75 9c             	mov    0xffffff9c(%ebp),%esi
  105002:	8b 7d 98             	mov    0xffffff98(%ebp),%edi
  105005:	8b 4d 94             	mov    0xffffff94(%ebp),%ecx
  105008:	cd 30                	int    $0x30
  10500a:	83 85 40 ff ff ff 01 	addl   $0x1,0xffffff40(%ebp)
  105011:	83 bd 40 ff ff ff 03 	cmpl   $0x3,0xffffff40(%ebp)
  105018:	7e a8                	jle    104fc2 <proc_check+0x283>
  10501a:	c7 04 24 b0 d0 10 00 	movl   $0x10d0b0,(%esp)
  105021:	e8 47 68 00 00       	call   10b86d <cprintf>
  105026:	c7 85 40 ff ff ff 00 	movl   $0x0,0xffffff40(%ebp)
  10502d:	00 00 00 
  105030:	8b 85 40 ff ff ff    	mov    0xffffff40(%ebp),%eax
  105036:	0f b7 c0             	movzwl %ax,%eax
  105039:	c7 45 c0 00 10 00 00 	movl   $0x1000,0xffffffc0(%ebp)
  105040:	66 89 45 be          	mov    %ax,0xffffffbe(%ebp)
  105044:	c7 45 b8 80 da 17 00 	movl   $0x17da80,0xffffffb8(%ebp)
  10504b:	c7 45 b4 00 00 00 00 	movl   $0x0,0xffffffb4(%ebp)
  105052:	c7 45 b0 00 00 00 00 	movl   $0x0,0xffffffb0(%ebp)
  105059:	c7 45 ac 00 00 00 00 	movl   $0x0,0xffffffac(%ebp)
  105060:	8b 45 c0             	mov    0xffffffc0(%ebp),%eax
  105063:	83 c8 02             	or     $0x2,%eax
  105066:	8b 5d b8             	mov    0xffffffb8(%ebp),%ebx
  105069:	0f b7 55 be          	movzwl 0xffffffbe(%ebp),%edx
  10506d:	8b 75 b4             	mov    0xffffffb4(%ebp),%esi
  105070:	8b 7d b0             	mov    0xffffffb0(%ebp),%edi
  105073:	8b 4d ac             	mov    0xffffffac(%ebp),%ecx
  105076:	cd 30                	int    $0x30
  105078:	a1 d0 1c 18 00       	mov    0x181cd0,%eax
  10507d:	85 c0                	test   %eax,%eax
  10507f:	74 24                	je     1050a5 <proc_check+0x366>
  105081:	c7 44 24 0c d5 d0 10 	movl   $0x10d0d5,0xc(%esp)
  105088:	00 
  105089:	c7 44 24 08 ad ce 10 	movl   $0x10cead,0x8(%esp)
  105090:	00 
  105091:	c7 44 24 04 b6 01 00 	movl   $0x1b6,0x4(%esp)
  105098:	00 
  105099:	c7 04 24 88 ce 10 00 	movl   $0x10ce88,(%esp)
  1050a0:	e8 93 b8 ff ff       	call   100938 <debug_panic>
  1050a5:	8b 85 40 ff ff ff    	mov    0xffffff40(%ebp),%eax
  1050ab:	0f b7 c0             	movzwl %ax,%eax
  1050ae:	c7 45 d8 10 10 00 00 	movl   $0x1010,0xffffffd8(%ebp)
  1050b5:	66 89 45 d6          	mov    %ax,0xffffffd6(%ebp)
  1050b9:	c7 45 d0 80 da 17 00 	movl   $0x17da80,0xffffffd0(%ebp)
  1050c0:	c7 45 cc 00 00 00 00 	movl   $0x0,0xffffffcc(%ebp)
  1050c7:	c7 45 c8 00 00 00 00 	movl   $0x0,0xffffffc8(%ebp)
  1050ce:	c7 45 c4 00 00 00 00 	movl   $0x0,0xffffffc4(%ebp)
  1050d5:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  1050d8:	83 c8 01             	or     $0x1,%eax
  1050db:	8b 5d d0             	mov    0xffffffd0(%ebp),%ebx
  1050de:	0f b7 55 d6          	movzwl 0xffffffd6(%ebp),%edx
  1050e2:	8b 75 cc             	mov    0xffffffcc(%ebp),%esi
  1050e5:	8b 7d c8             	mov    0xffffffc8(%ebp),%edi
  1050e8:	8b 4d c4             	mov    0xffffffc4(%ebp),%ecx
  1050eb:	cd 30                	int    $0x30
  1050ed:	8b 85 40 ff ff ff    	mov    0xffffff40(%ebp),%eax
  1050f3:	0f b7 c0             	movzwl %ax,%eax
  1050f6:	c7 45 f0 00 10 00 00 	movl   $0x1000,0xfffffff0(%ebp)
  1050fd:	66 89 45 ee          	mov    %ax,0xffffffee(%ebp)
  105101:	c7 45 e8 80 da 17 00 	movl   $0x17da80,0xffffffe8(%ebp)
  105108:	c7 45 e4 00 00 00 00 	movl   $0x0,0xffffffe4(%ebp)
  10510f:	c7 45 e0 00 00 00 00 	movl   $0x0,0xffffffe0(%ebp)
  105116:	c7 45 dc 00 00 00 00 	movl   $0x0,0xffffffdc(%ebp)
  10511d:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  105120:	83 c8 02             	or     $0x2,%eax
  105123:	8b 5d e8             	mov    0xffffffe8(%ebp),%ebx
  105126:	0f b7 55 ee          	movzwl 0xffffffee(%ebp),%edx
  10512a:	8b 75 e4             	mov    0xffffffe4(%ebp),%esi
  10512d:	8b 7d e0             	mov    0xffffffe0(%ebp),%edi
  105130:	8b 4d dc             	mov    0xffffffdc(%ebp),%ecx
  105133:	cd 30                	int    $0x30
  105135:	a1 d0 1c 18 00       	mov    0x181cd0,%eax
  10513a:	85 c0                	test   %eax,%eax
  10513c:	74 3f                	je     10517d <proc_check+0x43e>
  10513e:	a1 d0 1c 18 00       	mov    0x181cd0,%eax
  105143:	89 85 48 ff ff ff    	mov    %eax,0xffffff48(%ebp)
  105149:	a1 b0 da 17 00       	mov    0x17dab0,%eax
  10514e:	89 44 24 04          	mov    %eax,0x4(%esp)
  105152:	c7 04 24 e7 d0 10 00 	movl   $0x10d0e7,(%esp)
  105159:	e8 0f 67 00 00       	call   10b86d <cprintf>
  10515e:	8b 85 48 ff ff ff    	mov    0xffffff48(%ebp),%eax
  105164:	8b 00                	mov    (%eax),%eax
  105166:	a3 b8 da 17 00       	mov    %eax,0x17dab8
  10516b:	a1 b0 da 17 00       	mov    0x17dab0,%eax
  105170:	89 c2                	mov    %eax,%edx
  105172:	8b 85 48 ff ff ff    	mov    0xffffff48(%ebp),%eax
  105178:	89 50 04             	mov    %edx,0x4(%eax)
  10517b:	eb 2e                	jmp    1051ab <proc_check+0x46c>
  10517d:	a1 b0 da 17 00       	mov    0x17dab0,%eax
  105182:	83 f8 30             	cmp    $0x30,%eax
  105185:	74 24                	je     1051ab <proc_check+0x46c>
  105187:	c7 44 24 0c 00 d1 10 	movl   $0x10d100,0xc(%esp)
  10518e:	00 
  10518f:	c7 44 24 08 ad ce 10 	movl   $0x10cead,0x8(%esp)
  105196:	00 
  105197:	c7 44 24 04 c1 01 00 	movl   $0x1c1,0x4(%esp)
  10519e:	00 
  10519f:	c7 04 24 88 ce 10 00 	movl   $0x10ce88,(%esp)
  1051a6:	e8 8d b7 ff ff       	call   100938 <debug_panic>
  1051ab:	8b 95 40 ff ff ff    	mov    0xffffff40(%ebp),%edx
  1051b1:	83 c2 01             	add    $0x1,%edx
  1051b4:	89 d0                	mov    %edx,%eax
  1051b6:	c1 f8 1f             	sar    $0x1f,%eax
  1051b9:	89 c1                	mov    %eax,%ecx
  1051bb:	c1 e9 1e             	shr    $0x1e,%ecx
  1051be:	8d 04 0a             	lea    (%edx,%ecx,1),%eax
  1051c1:	83 e0 03             	and    $0x3,%eax
  1051c4:	29 c8                	sub    %ecx,%eax
  1051c6:	89 85 40 ff ff ff    	mov    %eax,0xffffff40(%ebp)
  1051cc:	a1 b0 da 17 00       	mov    0x17dab0,%eax
  1051d1:	83 f8 30             	cmp    $0x30,%eax
  1051d4:	0f 85 cb fe ff ff    	jne    1050a5 <proc_check+0x366>
  1051da:	a1 d0 1c 18 00       	mov    0x181cd0,%eax
  1051df:	85 c0                	test   %eax,%eax
  1051e1:	74 24                	je     105207 <proc_check+0x4c8>
  1051e3:	c7 44 24 0c d5 d0 10 	movl   $0x10d0d5,0xc(%esp)
  1051ea:	00 
  1051eb:	c7 44 24 08 ad ce 10 	movl   $0x10cead,0x8(%esp)
  1051f2:	00 
  1051f3:	c7 44 24 04 c4 01 00 	movl   $0x1c4,0x4(%esp)
  1051fa:	00 
  1051fb:	c7 04 24 88 ce 10 00 	movl   $0x10ce88,(%esp)
  105202:	e8 31 b7 ff ff       	call   100938 <debug_panic>
  105207:	c7 04 24 24 d1 10 00 	movl   $0x10d124,(%esp)
  10520e:	e8 5a 66 00 00       	call   10b86d <cprintf>
  105213:	c7 04 24 51 d1 10 00 	movl   $0x10d151,(%esp)
  10521a:	e8 4e 66 00 00       	call   10b86d <cprintf>
  10521f:	81 c4 dc 00 00 00    	add    $0xdc,%esp
  105225:	5b                   	pop    %ebx
  105226:	5e                   	pop    %esi
  105227:	5f                   	pop    %edi
  105228:	5d                   	pop    %ebp
  105229:	c3                   	ret    

0010522a <child>:
  10522a:	55                   	push   %ebp
  10522b:	89 e5                	mov    %esp,%ebp
  10522d:	83 ec 28             	sub    $0x28,%esp
  105230:	83 7d 08 01          	cmpl   $0x1,0x8(%ebp)
  105234:	7f 64                	jg     10529a <child+0x70>
  105236:	c7 45 fc 00 00 00 00 	movl   $0x0,0xfffffffc(%ebp)
  10523d:	eb 4e                	jmp    10528d <child+0x63>
  10523f:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  105242:	89 44 24 08          	mov    %eax,0x8(%esp)
  105246:	8b 45 08             	mov    0x8(%ebp),%eax
  105249:	89 44 24 04          	mov    %eax,0x4(%esp)
  10524d:	c7 04 24 6a d1 10 00 	movl   $0x10d16a,(%esp)
  105254:	e8 14 66 00 00       	call   10b86d <cprintf>
  105259:	eb 05                	jmp    105260 <child+0x36>
  10525b:	e8 72 f8 ff ff       	call   104ad2 <pause>
  105260:	8b 55 08             	mov    0x8(%ebp),%edx
  105263:	a1 20 da 17 00       	mov    0x17da20,%eax
  105268:	39 c2                	cmp    %eax,%edx
  10526a:	75 ef                	jne    10525b <child+0x31>
  10526c:	a1 20 da 17 00       	mov    0x17da20,%eax
  105271:	85 c0                	test   %eax,%eax
  105273:	0f 94 c0             	sete   %al
  105276:	0f b6 c0             	movzbl %al,%eax
  105279:	89 44 24 04          	mov    %eax,0x4(%esp)
  10527d:	c7 04 24 20 da 17 00 	movl   $0x17da20,(%esp)
  105284:	e8 02 01 00 00       	call   10538b <xchg>
  105289:	83 45 fc 01          	addl   $0x1,0xfffffffc(%ebp)
  10528d:	83 7d fc 09          	cmpl   $0x9,0xfffffffc(%ebp)
  105291:	7e ac                	jle    10523f <child+0x15>
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
		  "b" (save),
		  "d" (child),
		  "S" (childsrc),
		  "D" (localdest),
		  "c" (size)
		: "cc", "memory");
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
  105293:	b8 03 00 00 00       	mov    $0x3,%eax
  105298:	cd 30                	int    $0x30
  10529a:	c7 45 f8 00 00 00 00 	movl   $0x0,0xfffffff8(%ebp)
  1052a1:	eb 4c                	jmp    1052ef <child+0xc5>
  1052a3:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1052a6:	89 44 24 08          	mov    %eax,0x8(%esp)
  1052aa:	8b 45 08             	mov    0x8(%ebp),%eax
  1052ad:	89 44 24 04          	mov    %eax,0x4(%esp)
  1052b1:	c7 04 24 6a d1 10 00 	movl   $0x10d16a,(%esp)
  1052b8:	e8 b0 65 00 00       	call   10b86d <cprintf>
  1052bd:	eb 05                	jmp    1052c4 <child+0x9a>
  1052bf:	e8 0e f8 ff ff       	call   104ad2 <pause>
  1052c4:	8b 55 08             	mov    0x8(%ebp),%edx
  1052c7:	a1 20 da 17 00       	mov    0x17da20,%eax
  1052cc:	39 c2                	cmp    %eax,%edx
  1052ce:	75 ef                	jne    1052bf <child+0x95>
  1052d0:	a1 20 da 17 00       	mov    0x17da20,%eax
  1052d5:	83 c0 01             	add    $0x1,%eax
  1052d8:	83 e0 03             	and    $0x3,%eax
  1052db:	89 44 24 04          	mov    %eax,0x4(%esp)
  1052df:	c7 04 24 20 da 17 00 	movl   $0x17da20,(%esp)
  1052e6:	e8 a0 00 00 00       	call   10538b <xchg>
  1052eb:	83 45 f8 01          	addl   $0x1,0xfffffff8(%ebp)
  1052ef:	83 7d f8 09          	cmpl   $0x9,0xfffffff8(%ebp)
  1052f3:	7e ae                	jle    1052a3 <child+0x79>
  1052f5:	b8 03 00 00 00       	mov    $0x3,%eax
  1052fa:	cd 30                	int    $0x30
  1052fc:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  105300:	75 6d                	jne    10536f <child+0x145>
  105302:	a1 d0 1c 18 00       	mov    0x181cd0,%eax
  105307:	85 c0                	test   %eax,%eax
  105309:	74 24                	je     10532f <child+0x105>
  10530b:	c7 44 24 0c d5 d0 10 	movl   $0x10d0d5,0xc(%esp)
  105312:	00 
  105313:	c7 44 24 08 ad ce 10 	movl   $0x10cead,0x8(%esp)
  10531a:	00 
  10531b:	c7 44 24 04 e5 01 00 	movl   $0x1e5,0x4(%esp)
  105322:	00 
  105323:	c7 04 24 88 ce 10 00 	movl   $0x10ce88,(%esp)
  10532a:	e8 09 b6 ff ff       	call   100938 <debug_panic>
  10532f:	c7 04 24 d0 1c 18 00 	movl   $0x181cd0,(%esp)
  105336:	e8 57 e3 ff ff       	call   103692 <trap_check>
  10533b:	a1 d0 1c 18 00       	mov    0x181cd0,%eax
  105340:	85 c0                	test   %eax,%eax
  105342:	74 24                	je     105368 <child+0x13e>
  105344:	c7 44 24 0c d5 d0 10 	movl   $0x10d0d5,0xc(%esp)
  10534b:	00 
  10534c:	c7 44 24 08 ad ce 10 	movl   $0x10cead,0x8(%esp)
  105353:	00 
  105354:	c7 44 24 04 e7 01 00 	movl   $0x1e7,0x4(%esp)
  10535b:	00 
  10535c:	c7 04 24 88 ce 10 00 	movl   $0x10ce88,(%esp)
  105363:	e8 d0 b5 ff ff       	call   100938 <debug_panic>
  105368:	b8 03 00 00 00       	mov    $0x3,%eax
  10536d:	cd 30                	int    $0x30
  10536f:	c7 44 24 08 80 d1 10 	movl   $0x10d180,0x8(%esp)
  105376:	00 
  105377:	c7 44 24 04 eb 01 00 	movl   $0x1eb,0x4(%esp)
  10537e:	00 
  10537f:	c7 04 24 88 ce 10 00 	movl   $0x10ce88,(%esp)
  105386:	e8 ad b5 ff ff       	call   100938 <debug_panic>

0010538b <xchg>:

// Atomically set *addr to newval and return the old value of *addr.
static inline uint32_t
xchg(volatile uint32_t *addr, uint32_t newval)
{
  10538b:	55                   	push   %ebp
  10538c:	89 e5                	mov    %esp,%ebp
  10538e:	53                   	push   %ebx
  10538f:	83 ec 14             	sub    $0x14,%esp
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
  105392:	8b 4d 08             	mov    0x8(%ebp),%ecx
  105395:	8b 55 0c             	mov    0xc(%ebp),%edx
  105398:	8b 45 08             	mov    0x8(%ebp),%eax
  10539b:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  10539e:	89 d0                	mov    %edx,%eax
  1053a0:	8b 5d e8             	mov    0xffffffe8(%ebp),%ebx
  1053a3:	f0 87 01             	lock xchg %eax,(%ecx)
  1053a6:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  1053a9:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  1053ac:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
	       "+m" (*addr), "=a" (result) :
	       "1" (newval) :
	       "cc");
	return result;
  1053af:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
}
  1053b2:	83 c4 14             	add    $0x14,%esp
  1053b5:	5b                   	pop    %ebx
  1053b6:	5d                   	pop    %ebp
  1053b7:	c3                   	ret    

001053b8 <grandchild>:
  1053b8:	55                   	push   %ebp
  1053b9:	89 e5                	mov    %esp,%ebp
  1053bb:	83 ec 18             	sub    $0x18,%esp
  1053be:	c7 44 24 08 a4 d1 10 	movl   $0x10d1a4,0x8(%esp)
  1053c5:	00 
  1053c6:	c7 44 24 04 f0 01 00 	movl   $0x1f0,0x4(%esp)
  1053cd:	00 
  1053ce:	c7 04 24 88 ce 10 00 	movl   $0x10ce88,(%esp)
  1053d5:	e8 5e b5 ff ff       	call   100938 <debug_panic>
  1053da:	90                   	nop    
  1053db:	90                   	nop    

001053dc <systrap>:
  1053dc:	55                   	push   %ebp
  1053dd:	89 e5                	mov    %esp,%ebp
  1053df:	83 ec 08             	sub    $0x8,%esp
  1053e2:	8b 55 0c             	mov    0xc(%ebp),%edx
  1053e5:	8b 45 08             	mov    0x8(%ebp),%eax
  1053e8:	89 50 30             	mov    %edx,0x30(%eax)
  1053eb:	8b 55 10             	mov    0x10(%ebp),%edx
  1053ee:	8b 45 08             	mov    0x8(%ebp),%eax
  1053f1:	89 50 34             	mov    %edx,0x34(%eax)
  1053f4:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1053fb:	00 
  1053fc:	8b 45 08             	mov    0x8(%ebp),%eax
  1053ff:	89 04 24             	mov    %eax,(%esp)
  105402:	e8 e7 f7 ff ff       	call   104bee <proc_ret>

00105407 <sysrecover>:
  105407:	55                   	push   %ebp
  105408:	89 e5                	mov    %esp,%ebp
  10540a:	83 ec 28             	sub    $0x28,%esp
  10540d:	8b 45 0c             	mov    0xc(%ebp),%eax
  105410:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  105413:	e8 65 00 00 00       	call   10547d <cpu_cur>
  105418:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  10541b:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  10541e:	8b 80 a0 00 00 00    	mov    0xa0(%eax),%eax
  105424:	3d 07 54 10 00       	cmp    $0x105407,%eax
  105429:	74 24                	je     10544f <sysrecover+0x48>
  10542b:	c7 44 24 0c d0 d1 10 	movl   $0x10d1d0,0xc(%esp)
  105432:	00 
  105433:	c7 44 24 08 e9 d1 10 	movl   $0x10d1e9,0x8(%esp)
  10543a:	00 
  10543b:	c7 44 24 04 49 00 00 	movl   $0x49,0x4(%esp)
  105442:	00 
  105443:	c7 04 24 fe d1 10 00 	movl   $0x10d1fe,(%esp)
  10544a:	e8 e9 b4 ff ff       	call   100938 <debug_panic>
  10544f:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  105452:	c7 80 a0 00 00 00 00 	movl   $0x0,0xa0(%eax)
  105459:	00 00 00 
  10545c:	8b 45 08             	mov    0x8(%ebp),%eax
  10545f:	8b 40 34             	mov    0x34(%eax),%eax
  105462:	89 c2                	mov    %eax,%edx
  105464:	8b 45 08             	mov    0x8(%ebp),%eax
  105467:	8b 40 30             	mov    0x30(%eax),%eax
  10546a:	89 54 24 08          	mov    %edx,0x8(%esp)
  10546e:	89 44 24 04          	mov    %eax,0x4(%esp)
  105472:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  105475:	89 04 24             	mov    %eax,(%esp)
  105478:	e8 5f ff ff ff       	call   1053dc <systrap>

0010547d <cpu_cur>:

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  10547d:	55                   	push   %ebp
  10547e:	89 e5                	mov    %esp,%ebp
  105480:	83 ec 28             	sub    $0x28,%esp
static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  105483:	89 65 fc             	mov    %esp,0xfffffffc(%ebp)
        return esp;
  105486:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  105489:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  10548c:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10548f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  105494:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	assert(c->magic == CPU_MAGIC);
  105497:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  10549a:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  1054a0:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  1054a5:	74 24                	je     1054cb <cpu_cur+0x4e>
  1054a7:	c7 44 24 0c 10 d2 10 	movl   $0x10d210,0xc(%esp)
  1054ae:	00 
  1054af:	c7 44 24 08 e9 d1 10 	movl   $0x10d1e9,0x8(%esp)
  1054b6:	00 
  1054b7:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  1054be:	00 
  1054bf:	c7 04 24 26 d2 10 00 	movl   $0x10d226,(%esp)
  1054c6:	e8 6d b4 ff ff       	call   100938 <debug_panic>
	return c;
  1054cb:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
}
  1054ce:	c9                   	leave  
  1054cf:	c3                   	ret    

001054d0 <checkva>:
  1054d0:	55                   	push   %ebp
  1054d1:	89 e5                	mov    %esp,%ebp
  1054d3:	83 ec 18             	sub    $0x18,%esp
  1054d6:	81 7d 0c ff ff ff 3f 	cmpl   $0x3fffffff,0xc(%ebp)
  1054dd:	76 16                	jbe    1054f5 <checkva+0x25>
  1054df:	81 7d 0c ff ff ff ef 	cmpl   $0xefffffff,0xc(%ebp)
  1054e6:	77 0d                	ja     1054f5 <checkva+0x25>
  1054e8:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
  1054ed:	2b 45 0c             	sub    0xc(%ebp),%eax
  1054f0:	3b 45 10             	cmp    0x10(%ebp),%eax
  1054f3:	77 1b                	ja     105510 <checkva+0x40>
  1054f5:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  1054fc:	00 
  1054fd:	c7 44 24 04 0e 00 00 	movl   $0xe,0x4(%esp)
  105504:	00 
  105505:	8b 45 08             	mov    0x8(%ebp),%eax
  105508:	89 04 24             	mov    %eax,(%esp)
  10550b:	e8 cc fe ff ff       	call   1053dc <systrap>
  105510:	c9                   	leave  
  105511:	c3                   	ret    

00105512 <usercopy>:
  105512:	55                   	push   %ebp
  105513:	89 e5                	mov    %esp,%ebp
  105515:	83 ec 28             	sub    $0x28,%esp
  105518:	8b 45 18             	mov    0x18(%ebp),%eax
  10551b:	89 44 24 08          	mov    %eax,0x8(%esp)
  10551f:	8b 45 14             	mov    0x14(%ebp),%eax
  105522:	89 44 24 04          	mov    %eax,0x4(%esp)
  105526:	8b 45 08             	mov    0x8(%ebp),%eax
  105529:	89 04 24             	mov    %eax,(%esp)
  10552c:	e8 9f ff ff ff       	call   1054d0 <checkva>
  105531:	e8 47 ff ff ff       	call   10547d <cpu_cur>
  105536:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  105539:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  10553c:	8b 80 a0 00 00 00    	mov    0xa0(%eax),%eax
  105542:	85 c0                	test   %eax,%eax
  105544:	74 24                	je     10556a <usercopy+0x58>
  105546:	c7 44 24 0c 33 d2 10 	movl   $0x10d233,0xc(%esp)
  10554d:	00 
  10554e:	c7 44 24 08 e9 d1 10 	movl   $0x10d1e9,0x8(%esp)
  105555:	00 
  105556:	c7 44 24 04 75 00 00 	movl   $0x75,0x4(%esp)
  10555d:	00 
  10555e:	c7 04 24 fe d1 10 00 	movl   $0x10d1fe,(%esp)
  105565:	e8 ce b3 ff ff       	call   100938 <debug_panic>
  10556a:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  10556d:	c7 80 a0 00 00 00 07 	movl   $0x105407,0xa0(%eax)
  105574:	54 10 00 
  105577:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  10557b:	74 1b                	je     105598 <usercopy+0x86>
  10557d:	8b 45 14             	mov    0x14(%ebp),%eax
  105580:	8b 55 18             	mov    0x18(%ebp),%edx
  105583:	89 54 24 08          	mov    %edx,0x8(%esp)
  105587:	8b 55 10             	mov    0x10(%ebp),%edx
  10558a:	89 54 24 04          	mov    %edx,0x4(%esp)
  10558e:	89 04 24             	mov    %eax,(%esp)
  105591:	e8 d4 66 00 00       	call   10bc6a <memmove>
  105596:	eb 19                	jmp    1055b1 <usercopy+0x9f>
  105598:	8b 45 14             	mov    0x14(%ebp),%eax
  10559b:	8b 55 18             	mov    0x18(%ebp),%edx
  10559e:	89 54 24 08          	mov    %edx,0x8(%esp)
  1055a2:	89 44 24 04          	mov    %eax,0x4(%esp)
  1055a6:	8b 45 10             	mov    0x10(%ebp),%eax
  1055a9:	89 04 24             	mov    %eax,(%esp)
  1055ac:	e8 b9 66 00 00       	call   10bc6a <memmove>
  1055b1:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  1055b4:	8b 80 a0 00 00 00    	mov    0xa0(%eax),%eax
  1055ba:	3d 07 54 10 00       	cmp    $0x105407,%eax
  1055bf:	74 24                	je     1055e5 <usercopy+0xd3>
  1055c1:	c7 44 24 0c d0 d1 10 	movl   $0x10d1d0,0xc(%esp)
  1055c8:	00 
  1055c9:	c7 44 24 08 e9 d1 10 	movl   $0x10d1e9,0x8(%esp)
  1055d0:	00 
  1055d1:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
  1055d8:	00 
  1055d9:	c7 04 24 fe d1 10 00 	movl   $0x10d1fe,(%esp)
  1055e0:	e8 53 b3 ff ff       	call   100938 <debug_panic>
  1055e5:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  1055e8:	c7 80 a0 00 00 00 00 	movl   $0x0,0xa0(%eax)
  1055ef:	00 00 00 
  1055f2:	c9                   	leave  
  1055f3:	c3                   	ret    

001055f4 <do_cputs>:
  1055f4:	55                   	push   %ebp
  1055f5:	89 e5                	mov    %esp,%ebp
  1055f7:	81 ec 28 01 00 00    	sub    $0x128,%esp
  1055fd:	8b 45 08             	mov    0x8(%ebp),%eax
  105600:	8b 40 10             	mov    0x10(%eax),%eax
  105603:	c7 44 24 10 00 01 00 	movl   $0x100,0x10(%esp)
  10560a:	00 
  10560b:	89 44 24 0c          	mov    %eax,0xc(%esp)
  10560f:	8d 85 ff fe ff ff    	lea    0xfffffeff(%ebp),%eax
  105615:	89 44 24 08          	mov    %eax,0x8(%esp)
  105619:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  105620:	00 
  105621:	8b 45 08             	mov    0x8(%ebp),%eax
  105624:	89 04 24             	mov    %eax,(%esp)
  105627:	e8 e6 fe ff ff       	call   105512 <usercopy>
  10562c:	c6 45 ff 00          	movb   $0x0,0xffffffff(%ebp)
  105630:	8d 85 ff fe ff ff    	lea    0xfffffeff(%ebp),%eax
  105636:	89 44 24 04          	mov    %eax,0x4(%esp)
  10563a:	c7 04 24 46 d2 10 00 	movl   $0x10d246,(%esp)
  105641:	e8 27 62 00 00       	call   10b86d <cprintf>
  105646:	8b 45 08             	mov    0x8(%ebp),%eax
  105649:	89 04 24             	mov    %eax,(%esp)
  10564c:	e8 0f e4 ff ff       	call   103a60 <trap_return>

00105651 <do_put>:
  105651:	55                   	push   %ebp
  105652:	89 e5                	mov    %esp,%ebp
  105654:	53                   	push   %ebx
  105655:	83 ec 44             	sub    $0x44,%esp
  105658:	e8 20 fe ff ff       	call   10547d <cpu_cur>
  10565d:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  105663:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)
  105666:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  105669:	8b 80 3c 04 00 00    	mov    0x43c(%eax),%eax
  10566f:	83 f8 02             	cmp    $0x2,%eax
  105672:	75 12                	jne    105686 <do_put+0x35>
  105674:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  105677:	8b 98 44 04 00 00    	mov    0x444(%eax),%ebx
  10567d:	e8 fb fd ff ff       	call   10547d <cpu_cur>
  105682:	39 c3                	cmp    %eax,%ebx
  105684:	74 24                	je     1056aa <do_put+0x59>
  105686:	c7 44 24 0c 4c d2 10 	movl   $0x10d24c,0xc(%esp)
  10568d:	00 
  10568e:	c7 44 24 08 e9 d1 10 	movl   $0x10d1e9,0x8(%esp)
  105695:	00 
  105696:	c7 44 24 04 9b 00 00 	movl   $0x9b,0x4(%esp)
  10569d:	00 
  10569e:	c7 04 24 fe d1 10 00 	movl   $0x10d1fe,(%esp)
  1056a5:	e8 8e b2 ff ff       	call   100938 <debug_panic>
  1056aa:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  1056ad:	89 04 24             	mov    %eax,(%esp)
  1056b0:	e8 05 e8 ff ff       	call   103eba <spinlock_acquire>
  1056b5:	8b 45 08             	mov    0x8(%ebp),%eax
  1056b8:	8b 40 14             	mov    0x14(%eax),%eax
  1056bb:	25 ff 00 00 00       	and    $0xff,%eax
  1056c0:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
  1056c3:	8b 55 e4             	mov    0xffffffe4(%ebp),%edx
  1056c6:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  1056c9:	8b 44 90 3c          	mov    0x3c(%eax,%edx,4),%eax
  1056cd:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  1056d0:	83 7d e8 00          	cmpl   $0x0,0xffffffe8(%ebp)
  1056d4:	75 37                	jne    10570d <do_put+0xbc>
  1056d6:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  1056d9:	89 44 24 04          	mov    %eax,0x4(%esp)
  1056dd:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  1056e0:	89 04 24             	mov    %eax,(%esp)
  1056e3:	e8 e6 ee ff ff       	call   1045ce <proc_alloc>
  1056e8:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  1056eb:	83 7d e8 00          	cmpl   $0x0,0xffffffe8(%ebp)
  1056ef:	75 1c                	jne    10570d <do_put+0xbc>
  1056f1:	c7 44 24 08 7b d2 10 	movl   $0x10d27b,0x8(%esp)
  1056f8:	00 
  1056f9:	c7 44 24 04 ae 00 00 	movl   $0xae,0x4(%esp)
  105700:	00 
  105701:	c7 04 24 fe d1 10 00 	movl   $0x10d1fe,(%esp)
  105708:	e8 2b b2 ff ff       	call   100938 <debug_panic>
  10570d:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  105710:	8b 80 3c 04 00 00    	mov    0x43c(%eax),%eax
  105716:	85 c0                	test   %eax,%eax
  105718:	74 19                	je     105733 <do_put+0xe2>
  10571a:	8b 45 08             	mov    0x8(%ebp),%eax
  10571d:	89 44 24 08          	mov    %eax,0x8(%esp)
  105721:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  105724:	89 44 24 04          	mov    %eax,0x4(%esp)
  105728:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  10572b:	89 04 24             	mov    %eax,(%esp)
  10572e:	e8 d5 f1 ff ff       	call   104908 <proc_wait>
  105733:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  105736:	89 04 24             	mov    %eax,(%esp)
  105739:	e8 77 e8 ff ff       	call   103fb5 <spinlock_release>
  10573e:	8b 45 0c             	mov    0xc(%ebp),%eax
  105741:	25 00 10 00 00       	and    $0x1000,%eax
  105746:	85 c0                	test   %eax,%eax
  105748:	0f 84 ac 00 00 00    	je     1057fa <do_put+0x1a9>
  10574e:	c7 45 f8 50 00 00 00 	movl   $0x50,0xfffffff8(%ebp)
  105755:	8b 45 0c             	mov    0xc(%ebp),%eax
  105758:	25 00 20 00 00       	and    $0x2000,%eax
  10575d:	85 c0                	test   %eax,%eax
  10575f:	74 07                	je     105768 <do_put+0x117>
  105761:	c7 45 f8 50 02 00 00 	movl   $0x250,0xfffffff8(%ebp)
  105768:	8b 4d f8             	mov    0xfffffff8(%ebp),%ecx
  10576b:	8b 45 08             	mov    0x8(%ebp),%eax
  10576e:	8b 40 10             	mov    0x10(%eax),%eax
  105771:	8b 55 e8             	mov    0xffffffe8(%ebp),%edx
  105774:	81 c2 50 04 00 00    	add    $0x450,%edx
  10577a:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  10577e:	89 44 24 0c          	mov    %eax,0xc(%esp)
  105782:	89 54 24 08          	mov    %edx,0x8(%esp)
  105786:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  10578d:	00 
  10578e:	8b 45 08             	mov    0x8(%ebp),%eax
  105791:	89 04 24             	mov    %eax,(%esp)
  105794:	e8 79 fd ff ff       	call   105512 <usercopy>
  105799:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  10579c:	66 c7 80 7c 04 00 00 	movw   $0x23,0x47c(%eax)
  1057a3:	23 00 
  1057a5:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  1057a8:	66 c7 80 78 04 00 00 	movw   $0x23,0x478(%eax)
  1057af:	23 00 
  1057b1:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  1057b4:	66 c7 80 8c 04 00 00 	movw   $0x1b,0x48c(%eax)
  1057bb:	1b 00 
  1057bd:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  1057c0:	66 c7 80 98 04 00 00 	movw   $0x23,0x498(%eax)
  1057c7:	23 00 
  1057c9:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  1057cc:	8b 80 90 04 00 00    	mov    0x490(%eax),%eax
  1057d2:	89 c2                	mov    %eax,%edx
  1057d4:	81 e2 d5 0c 00 00    	and    $0xcd5,%edx
  1057da:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  1057dd:	89 90 90 04 00 00    	mov    %edx,0x490(%eax)
  1057e3:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  1057e6:	8b 80 90 04 00 00    	mov    0x490(%eax),%eax
  1057ec:	89 c2                	mov    %eax,%edx
  1057ee:	80 ce 02             	or     $0x2,%dh
  1057f1:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  1057f4:	89 90 90 04 00 00    	mov    %edx,0x490(%eax)
  1057fa:	8b 45 08             	mov    0x8(%ebp),%eax
  1057fd:	8b 40 04             	mov    0x4(%eax),%eax
  105800:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  105803:	8b 45 08             	mov    0x8(%ebp),%eax
  105806:	8b 00                	mov    (%eax),%eax
  105808:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
  10580b:	8b 45 08             	mov    0x8(%ebp),%eax
  10580e:	8b 40 18             	mov    0x18(%eax),%eax
  105811:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
  105814:	8b 45 0c             	mov    0xc(%ebp),%eax
  105817:	25 00 00 03 00       	and    $0x30000,%eax
  10581c:	89 45 d4             	mov    %eax,0xffffffd4(%ebp)
  10581f:	81 7d d4 00 00 01 00 	cmpl   $0x10000,0xffffffd4(%ebp)
  105826:	74 6a                	je     105892 <do_put+0x241>
  105828:	81 7d d4 00 00 02 00 	cmpl   $0x20000,0xffffffd4(%ebp)
  10582f:	74 0f                	je     105840 <do_put+0x1ef>
  105831:	83 7d d4 00          	cmpl   $0x0,0xffffffd4(%ebp)
  105835:	0f 84 39 01 00 00    	je     105974 <do_put+0x323>
  10583b:	e9 19 01 00 00       	jmp    105959 <do_put+0x308>
  105840:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  105843:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  105848:	85 c0                	test   %eax,%eax
  10584a:	75 2b                	jne    105877 <do_put+0x226>
  10584c:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  10584f:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  105854:	85 c0                	test   %eax,%eax
  105856:	75 1f                	jne    105877 <do_put+0x226>
  105858:	81 7d ec ff ff ff 3f 	cmpl   $0x3fffffff,0xffffffec(%ebp)
  10585f:	76 16                	jbe    105877 <do_put+0x226>
  105861:	81 7d ec 00 00 00 f0 	cmpl   $0xf0000000,0xffffffec(%ebp)
  105868:	77 0d                	ja     105877 <do_put+0x226>
  10586a:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
  10586f:	2b 45 ec             	sub    0xffffffec(%ebp),%eax
  105872:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  105875:	73 1b                	jae    105892 <do_put+0x241>
  105877:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  10587e:	00 
  10587f:	c7 44 24 04 0d 00 00 	movl   $0xd,0x4(%esp)
  105886:	00 
  105887:	8b 45 08             	mov    0x8(%ebp),%eax
  10588a:	89 04 24             	mov    %eax,(%esp)
  10588d:	e8 4a fb ff ff       	call   1053dc <systrap>
  105892:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  105895:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  10589a:	85 c0                	test   %eax,%eax
  10589c:	75 2b                	jne    1058c9 <do_put+0x278>
  10589e:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  1058a1:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  1058a6:	85 c0                	test   %eax,%eax
  1058a8:	75 1f                	jne    1058c9 <do_put+0x278>
  1058aa:	81 7d f0 ff ff ff 3f 	cmpl   $0x3fffffff,0xfffffff0(%ebp)
  1058b1:	76 16                	jbe    1058c9 <do_put+0x278>
  1058b3:	81 7d f0 00 00 00 f0 	cmpl   $0xf0000000,0xfffffff0(%ebp)
  1058ba:	77 0d                	ja     1058c9 <do_put+0x278>
  1058bc:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
  1058c1:	2b 45 f0             	sub    0xfffffff0(%ebp),%eax
  1058c4:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  1058c7:	73 1b                	jae    1058e4 <do_put+0x293>
  1058c9:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  1058d0:	00 
  1058d1:	c7 44 24 04 0d 00 00 	movl   $0xd,0x4(%esp)
  1058d8:	00 
  1058d9:	8b 45 08             	mov    0x8(%ebp),%eax
  1058dc:	89 04 24             	mov    %eax,(%esp)
  1058df:	e8 f8 fa ff ff       	call   1053dc <systrap>
  1058e4:	8b 45 0c             	mov    0xc(%ebp),%eax
  1058e7:	25 00 00 03 00       	and    $0x30000,%eax
  1058ec:	89 45 d8             	mov    %eax,0xffffffd8(%ebp)
  1058ef:	81 7d d8 00 00 01 00 	cmpl   $0x10000,0xffffffd8(%ebp)
  1058f6:	74 0b                	je     105903 <do_put+0x2b2>
  1058f8:	81 7d d8 00 00 02 00 	cmpl   $0x20000,0xffffffd8(%ebp)
  1058ff:	74 23                	je     105924 <do_put+0x2d3>
  105901:	eb 71                	jmp    105974 <do_put+0x323>
  105903:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  105906:	8b 90 a0 06 00 00    	mov    0x6a0(%eax),%edx
  10590c:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  10590f:	89 44 24 08          	mov    %eax,0x8(%esp)
  105913:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  105916:	89 44 24 04          	mov    %eax,0x4(%esp)
  10591a:	89 14 24             	mov    %edx,(%esp)
  10591d:	e8 ab 12 00 00       	call   106bcd <pmap_remove>
  105922:	eb 50                	jmp    105974 <do_put+0x323>
  105924:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  105927:	8b 90 a0 06 00 00    	mov    0x6a0(%eax),%edx
  10592d:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  105930:	8b 88 a0 06 00 00    	mov    0x6a0(%eax),%ecx
  105936:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  105939:	89 44 24 10          	mov    %eax,0x10(%esp)
  10593d:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  105940:	89 44 24 0c          	mov    %eax,0xc(%esp)
  105944:	89 54 24 08          	mov    %edx,0x8(%esp)
  105948:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  10594b:	89 44 24 04          	mov    %eax,0x4(%esp)
  10594f:	89 0c 24             	mov    %ecx,(%esp)
  105952:	e8 59 17 00 00       	call   1070b0 <pmap_copy>
  105957:	eb 1b                	jmp    105974 <do_put+0x323>
  105959:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  105960:	00 
  105961:	c7 44 24 04 0d 00 00 	movl   $0xd,0x4(%esp)
  105968:	00 
  105969:	8b 45 08             	mov    0x8(%ebp),%eax
  10596c:	89 04 24             	mov    %eax,(%esp)
  10596f:	e8 68 fa ff ff       	call   1053dc <systrap>
  105974:	8b 45 0c             	mov    0xc(%ebp),%eax
  105977:	25 00 01 00 00       	and    $0x100,%eax
  10597c:	85 c0                	test   %eax,%eax
  10597e:	0f 84 a0 00 00 00    	je     105a24 <do_put+0x3d3>
  105984:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  105987:	25 ff 0f 00 00       	and    $0xfff,%eax
  10598c:	85 c0                	test   %eax,%eax
  10598e:	75 2b                	jne    1059bb <do_put+0x36a>
  105990:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  105993:	25 ff 0f 00 00       	and    $0xfff,%eax
  105998:	85 c0                	test   %eax,%eax
  10599a:	75 1f                	jne    1059bb <do_put+0x36a>
  10599c:	81 7d f0 ff ff ff 3f 	cmpl   $0x3fffffff,0xfffffff0(%ebp)
  1059a3:	76 16                	jbe    1059bb <do_put+0x36a>
  1059a5:	81 7d f0 00 00 00 f0 	cmpl   $0xf0000000,0xfffffff0(%ebp)
  1059ac:	77 0d                	ja     1059bb <do_put+0x36a>
  1059ae:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
  1059b3:	2b 45 f0             	sub    0xfffffff0(%ebp),%eax
  1059b6:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  1059b9:	73 1b                	jae    1059d6 <do_put+0x385>
  1059bb:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  1059c2:	00 
  1059c3:	c7 44 24 04 0d 00 00 	movl   $0xd,0x4(%esp)
  1059ca:	00 
  1059cb:	8b 45 08             	mov    0x8(%ebp),%eax
  1059ce:	89 04 24             	mov    %eax,(%esp)
  1059d1:	e8 06 fa ff ff       	call   1053dc <systrap>
  1059d6:	8b 45 0c             	mov    0xc(%ebp),%eax
  1059d9:	89 c2                	mov    %eax,%edx
  1059db:	81 e2 00 06 00 00    	and    $0x600,%edx
  1059e1:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  1059e4:	8b 88 a0 06 00 00    	mov    0x6a0(%eax),%ecx
  1059ea:	89 54 24 0c          	mov    %edx,0xc(%esp)
  1059ee:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  1059f1:	89 44 24 08          	mov    %eax,0x8(%esp)
  1059f5:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  1059f8:	89 44 24 04          	mov    %eax,0x4(%esp)
  1059fc:	89 0c 24             	mov    %ecx,(%esp)
  1059ff:	e8 6e 29 00 00       	call   108372 <pmap_setperm>
  105a04:	85 c0                	test   %eax,%eax
  105a06:	75 1c                	jne    105a24 <do_put+0x3d3>
  105a08:	c7 44 24 08 98 d2 10 	movl   $0x10d298,0x8(%esp)
  105a0f:	00 
  105a10:	c7 44 24 04 03 01 00 	movl   $0x103,0x4(%esp)
  105a17:	00 
  105a18:	c7 04 24 fe d1 10 00 	movl   $0x10d1fe,(%esp)
  105a1f:	e8 14 af ff ff       	call   100938 <debug_panic>
  105a24:	8b 45 0c             	mov    0xc(%ebp),%eax
  105a27:	25 00 00 04 00       	and    $0x40000,%eax
  105a2c:	85 c0                	test   %eax,%eax
  105a2e:	74 36                	je     105a66 <do_put+0x415>
  105a30:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  105a33:	8b 90 a4 06 00 00    	mov    0x6a4(%eax),%edx
  105a39:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  105a3c:	8b 80 a0 06 00 00    	mov    0x6a0(%eax),%eax
  105a42:	c7 44 24 10 00 00 00 	movl   $0xb0000000,0x10(%esp)
  105a49:	b0 
  105a4a:	c7 44 24 0c 00 00 00 	movl   $0x40000000,0xc(%esp)
  105a51:	40 
  105a52:	89 54 24 08          	mov    %edx,0x8(%esp)
  105a56:	c7 44 24 04 00 00 00 	movl   $0x40000000,0x4(%esp)
  105a5d:	40 
  105a5e:	89 04 24             	mov    %eax,(%esp)
  105a61:	e8 4a 16 00 00       	call   1070b0 <pmap_copy>
  105a66:	8b 45 0c             	mov    0xc(%ebp),%eax
  105a69:	83 e0 10             	and    $0x10,%eax
  105a6c:	85 c0                	test   %eax,%eax
  105a6e:	74 0b                	je     105a7b <do_put+0x42a>
  105a70:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  105a73:	89 04 24             	mov    %eax,(%esp)
  105a76:	e8 b6 ed ff ff       	call   104831 <proc_ready>
  105a7b:	8b 45 08             	mov    0x8(%ebp),%eax
  105a7e:	89 04 24             	mov    %eax,(%esp)
  105a81:	e8 da df ff ff       	call   103a60 <trap_return>

00105a86 <do_get>:
  105a86:	55                   	push   %ebp
  105a87:	89 e5                	mov    %esp,%ebp
  105a89:	53                   	push   %ebx
  105a8a:	83 ec 44             	sub    $0x44,%esp
  105a8d:	e8 eb f9 ff ff       	call   10547d <cpu_cur>
  105a92:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  105a98:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)
  105a9b:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  105a9e:	8b 80 3c 04 00 00    	mov    0x43c(%eax),%eax
  105aa4:	83 f8 02             	cmp    $0x2,%eax
  105aa7:	75 12                	jne    105abb <do_get+0x35>
  105aa9:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  105aac:	8b 98 44 04 00 00    	mov    0x444(%eax),%ebx
  105ab2:	e8 c6 f9 ff ff       	call   10547d <cpu_cur>
  105ab7:	39 c3                	cmp    %eax,%ebx
  105ab9:	74 24                	je     105adf <do_get+0x59>
  105abb:	c7 44 24 0c 4c d2 10 	movl   $0x10d24c,0xc(%esp)
  105ac2:	00 
  105ac3:	c7 44 24 08 e9 d1 10 	movl   $0x10d1e9,0x8(%esp)
  105aca:	00 
  105acb:	c7 44 24 04 16 01 00 	movl   $0x116,0x4(%esp)
  105ad2:	00 
  105ad3:	c7 04 24 fe d1 10 00 	movl   $0x10d1fe,(%esp)
  105ada:	e8 59 ae ff ff       	call   100938 <debug_panic>
  105adf:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  105ae2:	89 04 24             	mov    %eax,(%esp)
  105ae5:	e8 d0 e3 ff ff       	call   103eba <spinlock_acquire>
  105aea:	8b 45 08             	mov    0x8(%ebp),%eax
  105aed:	8b 40 14             	mov    0x14(%eax),%eax
  105af0:	25 ff 00 00 00       	and    $0xff,%eax
  105af5:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
  105af8:	8b 55 e4             	mov    0xffffffe4(%ebp),%edx
  105afb:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  105afe:	8b 44 90 3c          	mov    0x3c(%eax,%edx,4),%eax
  105b02:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  105b05:	83 7d e8 00          	cmpl   $0x0,0xffffffe8(%ebp)
  105b09:	75 07                	jne    105b12 <do_get+0x8c>
  105b0b:	c7 45 e8 00 1e 18 00 	movl   $0x181e00,0xffffffe8(%ebp)
  105b12:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  105b15:	8b 80 3c 04 00 00    	mov    0x43c(%eax),%eax
  105b1b:	85 c0                	test   %eax,%eax
  105b1d:	74 19                	je     105b38 <do_get+0xb2>
  105b1f:	8b 45 08             	mov    0x8(%ebp),%eax
  105b22:	89 44 24 08          	mov    %eax,0x8(%esp)
  105b26:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  105b29:	89 44 24 04          	mov    %eax,0x4(%esp)
  105b2d:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  105b30:	89 04 24             	mov    %eax,(%esp)
  105b33:	e8 d0 ed ff ff       	call   104908 <proc_wait>
  105b38:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  105b3b:	89 04 24             	mov    %eax,(%esp)
  105b3e:	e8 72 e4 ff ff       	call   103fb5 <spinlock_release>
  105b43:	8b 45 0c             	mov    0xc(%ebp),%eax
  105b46:	25 00 10 00 00       	and    $0x1000,%eax
  105b4b:	85 c0                	test   %eax,%eax
  105b4d:	74 4b                	je     105b9a <do_get+0x114>
  105b4f:	c7 45 f8 50 00 00 00 	movl   $0x50,0xfffffff8(%ebp)
  105b56:	8b 45 0c             	mov    0xc(%ebp),%eax
  105b59:	25 00 20 00 00       	and    $0x2000,%eax
  105b5e:	85 c0                	test   %eax,%eax
  105b60:	74 07                	je     105b69 <do_get+0xe3>
  105b62:	c7 45 f8 50 02 00 00 	movl   $0x250,0xfffffff8(%ebp)
  105b69:	8b 4d f8             	mov    0xfffffff8(%ebp),%ecx
  105b6c:	8b 45 08             	mov    0x8(%ebp),%eax
  105b6f:	8b 40 10             	mov    0x10(%eax),%eax
  105b72:	8b 55 e8             	mov    0xffffffe8(%ebp),%edx
  105b75:	81 c2 50 04 00 00    	add    $0x450,%edx
  105b7b:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  105b7f:	89 44 24 0c          	mov    %eax,0xc(%esp)
  105b83:	89 54 24 08          	mov    %edx,0x8(%esp)
  105b87:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  105b8e:	00 
  105b8f:	8b 45 08             	mov    0x8(%ebp),%eax
  105b92:	89 04 24             	mov    %eax,(%esp)
  105b95:	e8 78 f9 ff ff       	call   105512 <usercopy>
  105b9a:	8b 45 08             	mov    0x8(%ebp),%eax
  105b9d:	8b 40 04             	mov    0x4(%eax),%eax
  105ba0:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  105ba3:	8b 45 08             	mov    0x8(%ebp),%eax
  105ba6:	8b 00                	mov    (%eax),%eax
  105ba8:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
  105bab:	8b 45 08             	mov    0x8(%ebp),%eax
  105bae:	8b 40 18             	mov    0x18(%eax),%eax
  105bb1:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
  105bb4:	8b 45 0c             	mov    0xc(%ebp),%eax
  105bb7:	25 00 00 03 00       	and    $0x30000,%eax
  105bbc:	89 45 d4             	mov    %eax,0xffffffd4(%ebp)
  105bbf:	81 7d d4 00 00 01 00 	cmpl   $0x10000,0xffffffd4(%ebp)
  105bc6:	0f 84 81 00 00 00    	je     105c4d <do_get+0x1c7>
  105bcc:	81 7d d4 00 00 01 00 	cmpl   $0x10000,0xffffffd4(%ebp)
  105bd3:	77 0f                	ja     105be4 <do_get+0x15e>
  105bd5:	83 7d d4 00          	cmpl   $0x0,0xffffffd4(%ebp)
  105bd9:	0f 84 a1 01 00 00    	je     105d80 <do_get+0x2fa>
  105bdf:	e9 81 01 00 00       	jmp    105d65 <do_get+0x2df>
  105be4:	81 7d d4 00 00 02 00 	cmpl   $0x20000,0xffffffd4(%ebp)
  105beb:	74 0e                	je     105bfb <do_get+0x175>
  105bed:	81 7d d4 00 00 03 00 	cmpl   $0x30000,0xffffffd4(%ebp)
  105bf4:	74 05                	je     105bfb <do_get+0x175>
  105bf6:	e9 6a 01 00 00       	jmp    105d65 <do_get+0x2df>
  105bfb:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  105bfe:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  105c03:	85 c0                	test   %eax,%eax
  105c05:	75 2b                	jne    105c32 <do_get+0x1ac>
  105c07:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  105c0a:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  105c0f:	85 c0                	test   %eax,%eax
  105c11:	75 1f                	jne    105c32 <do_get+0x1ac>
  105c13:	81 7d ec ff ff ff 3f 	cmpl   $0x3fffffff,0xffffffec(%ebp)
  105c1a:	76 16                	jbe    105c32 <do_get+0x1ac>
  105c1c:	81 7d ec 00 00 00 f0 	cmpl   $0xf0000000,0xffffffec(%ebp)
  105c23:	77 0d                	ja     105c32 <do_get+0x1ac>
  105c25:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
  105c2a:	2b 45 ec             	sub    0xffffffec(%ebp),%eax
  105c2d:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  105c30:	73 1b                	jae    105c4d <do_get+0x1c7>
  105c32:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  105c39:	00 
  105c3a:	c7 44 24 04 0d 00 00 	movl   $0xd,0x4(%esp)
  105c41:	00 
  105c42:	8b 45 08             	mov    0x8(%ebp),%eax
  105c45:	89 04 24             	mov    %eax,(%esp)
  105c48:	e8 8f f7 ff ff       	call   1053dc <systrap>
  105c4d:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  105c50:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  105c55:	85 c0                	test   %eax,%eax
  105c57:	75 2b                	jne    105c84 <do_get+0x1fe>
  105c59:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  105c5c:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  105c61:	85 c0                	test   %eax,%eax
  105c63:	75 1f                	jne    105c84 <do_get+0x1fe>
  105c65:	81 7d f0 ff ff ff 3f 	cmpl   $0x3fffffff,0xfffffff0(%ebp)
  105c6c:	76 16                	jbe    105c84 <do_get+0x1fe>
  105c6e:	81 7d f0 00 00 00 f0 	cmpl   $0xf0000000,0xfffffff0(%ebp)
  105c75:	77 0d                	ja     105c84 <do_get+0x1fe>
  105c77:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
  105c7c:	2b 45 f0             	sub    0xfffffff0(%ebp),%eax
  105c7f:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  105c82:	73 1b                	jae    105c9f <do_get+0x219>
  105c84:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  105c8b:	00 
  105c8c:	c7 44 24 04 0d 00 00 	movl   $0xd,0x4(%esp)
  105c93:	00 
  105c94:	8b 45 08             	mov    0x8(%ebp),%eax
  105c97:	89 04 24             	mov    %eax,(%esp)
  105c9a:	e8 3d f7 ff ff       	call   1053dc <systrap>
  105c9f:	8b 45 0c             	mov    0xc(%ebp),%eax
  105ca2:	25 00 00 03 00       	and    $0x30000,%eax
  105ca7:	89 45 d8             	mov    %eax,0xffffffd8(%ebp)
  105caa:	81 7d d8 00 00 02 00 	cmpl   $0x20000,0xffffffd8(%ebp)
  105cb1:	74 3b                	je     105cee <do_get+0x268>
  105cb3:	81 7d d8 00 00 03 00 	cmpl   $0x30000,0xffffffd8(%ebp)
  105cba:	74 67                	je     105d23 <do_get+0x29d>
  105cbc:	81 7d d8 00 00 01 00 	cmpl   $0x10000,0xffffffd8(%ebp)
  105cc3:	74 05                	je     105cca <do_get+0x244>
  105cc5:	e9 b6 00 00 00       	jmp    105d80 <do_get+0x2fa>
  105cca:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  105ccd:	8b 90 a0 06 00 00    	mov    0x6a0(%eax),%edx
  105cd3:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  105cd6:	89 44 24 08          	mov    %eax,0x8(%esp)
  105cda:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  105cdd:	89 44 24 04          	mov    %eax,0x4(%esp)
  105ce1:	89 14 24             	mov    %edx,(%esp)
  105ce4:	e8 e4 0e 00 00       	call   106bcd <pmap_remove>
  105ce9:	e9 92 00 00 00       	jmp    105d80 <do_get+0x2fa>
  105cee:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  105cf1:	8b 90 a0 06 00 00    	mov    0x6a0(%eax),%edx
  105cf7:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  105cfa:	8b 88 a0 06 00 00    	mov    0x6a0(%eax),%ecx
  105d00:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  105d03:	89 44 24 10          	mov    %eax,0x10(%esp)
  105d07:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  105d0a:	89 44 24 0c          	mov    %eax,0xc(%esp)
  105d0e:	89 54 24 08          	mov    %edx,0x8(%esp)
  105d12:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  105d15:	89 44 24 04          	mov    %eax,0x4(%esp)
  105d19:	89 0c 24             	mov    %ecx,(%esp)
  105d1c:	e8 8f 13 00 00       	call   1070b0 <pmap_copy>
  105d21:	eb 5d                	jmp    105d80 <do_get+0x2fa>
  105d23:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  105d26:	8b 90 a0 06 00 00    	mov    0x6a0(%eax),%edx
  105d2c:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  105d2f:	8b 88 a0 06 00 00    	mov    0x6a0(%eax),%ecx
  105d35:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  105d38:	8b 98 a4 06 00 00    	mov    0x6a4(%eax),%ebx
  105d3e:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  105d41:	89 44 24 14          	mov    %eax,0x14(%esp)
  105d45:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  105d48:	89 44 24 10          	mov    %eax,0x10(%esp)
  105d4c:	89 54 24 0c          	mov    %edx,0xc(%esp)
  105d50:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  105d53:	89 44 24 08          	mov    %eax,0x8(%esp)
  105d57:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  105d5b:	89 1c 24             	mov    %ebx,(%esp)
  105d5e:	e8 33 20 00 00       	call   107d96 <pmap_merge>
  105d63:	eb 1b                	jmp    105d80 <do_get+0x2fa>
  105d65:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  105d6c:	00 
  105d6d:	c7 44 24 04 0d 00 00 	movl   $0xd,0x4(%esp)
  105d74:	00 
  105d75:	8b 45 08             	mov    0x8(%ebp),%eax
  105d78:	89 04 24             	mov    %eax,(%esp)
  105d7b:	e8 5c f6 ff ff       	call   1053dc <systrap>
  105d80:	8b 45 0c             	mov    0xc(%ebp),%eax
  105d83:	25 00 01 00 00       	and    $0x100,%eax
  105d88:	85 c0                	test   %eax,%eax
  105d8a:	0f 84 a0 00 00 00    	je     105e30 <do_get+0x3aa>
  105d90:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  105d93:	25 ff 0f 00 00       	and    $0xfff,%eax
  105d98:	85 c0                	test   %eax,%eax
  105d9a:	75 2b                	jne    105dc7 <do_get+0x341>
  105d9c:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  105d9f:	25 ff 0f 00 00       	and    $0xfff,%eax
  105da4:	85 c0                	test   %eax,%eax
  105da6:	75 1f                	jne    105dc7 <do_get+0x341>
  105da8:	81 7d f0 ff ff ff 3f 	cmpl   $0x3fffffff,0xfffffff0(%ebp)
  105daf:	76 16                	jbe    105dc7 <do_get+0x341>
  105db1:	81 7d f0 00 00 00 f0 	cmpl   $0xf0000000,0xfffffff0(%ebp)
  105db8:	77 0d                	ja     105dc7 <do_get+0x341>
  105dba:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
  105dbf:	2b 45 f0             	sub    0xfffffff0(%ebp),%eax
  105dc2:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  105dc5:	73 1b                	jae    105de2 <do_get+0x35c>
  105dc7:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  105dce:	00 
  105dcf:	c7 44 24 04 0d 00 00 	movl   $0xd,0x4(%esp)
  105dd6:	00 
  105dd7:	8b 45 08             	mov    0x8(%ebp),%eax
  105dda:	89 04 24             	mov    %eax,(%esp)
  105ddd:	e8 fa f5 ff ff       	call   1053dc <systrap>
  105de2:	8b 45 0c             	mov    0xc(%ebp),%eax
  105de5:	89 c2                	mov    %eax,%edx
  105de7:	81 e2 00 06 00 00    	and    $0x600,%edx
  105ded:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  105df0:	8b 88 a0 06 00 00    	mov    0x6a0(%eax),%ecx
  105df6:	89 54 24 0c          	mov    %edx,0xc(%esp)
  105dfa:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  105dfd:	89 44 24 08          	mov    %eax,0x8(%esp)
  105e01:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  105e04:	89 44 24 04          	mov    %eax,0x4(%esp)
  105e08:	89 0c 24             	mov    %ecx,(%esp)
  105e0b:	e8 62 25 00 00       	call   108372 <pmap_setperm>
  105e10:	85 c0                	test   %eax,%eax
  105e12:	75 1c                	jne    105e30 <do_get+0x3aa>
  105e14:	c7 44 24 08 c0 d2 10 	movl   $0x10d2c0,0x8(%esp)
  105e1b:	00 
  105e1c:	c7 44 24 04 75 01 00 	movl   $0x175,0x4(%esp)
  105e23:	00 
  105e24:	c7 04 24 fe d1 10 00 	movl   $0x10d1fe,(%esp)
  105e2b:	e8 08 ab ff ff       	call   100938 <debug_panic>
  105e30:	8b 45 0c             	mov    0xc(%ebp),%eax
  105e33:	25 00 00 04 00       	and    $0x40000,%eax
  105e38:	85 c0                	test   %eax,%eax
  105e3a:	74 1b                	je     105e57 <do_get+0x3d1>
  105e3c:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  105e43:	00 
  105e44:	c7 44 24 04 0d 00 00 	movl   $0xd,0x4(%esp)
  105e4b:	00 
  105e4c:	8b 45 08             	mov    0x8(%ebp),%eax
  105e4f:	89 04 24             	mov    %eax,(%esp)
  105e52:	e8 85 f5 ff ff       	call   1053dc <systrap>
  105e57:	8b 45 08             	mov    0x8(%ebp),%eax
  105e5a:	89 04 24             	mov    %eax,(%esp)
  105e5d:	e8 fe db ff ff       	call   103a60 <trap_return>

00105e62 <do_ret>:
  105e62:	55                   	push   %ebp
  105e63:	89 e5                	mov    %esp,%ebp
  105e65:	83 ec 08             	sub    $0x8,%esp
  105e68:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  105e6f:	00 
  105e70:	8b 45 08             	mov    0x8(%ebp),%eax
  105e73:	89 04 24             	mov    %eax,(%esp)
  105e76:	e8 73 ed ff ff       	call   104bee <proc_ret>

00105e7b <syscall>:
  105e7b:	55                   	push   %ebp
  105e7c:	89 e5                	mov    %esp,%ebp
  105e7e:	83 ec 28             	sub    $0x28,%esp
  105e81:	8b 45 08             	mov    0x8(%ebp),%eax
  105e84:	8b 40 1c             	mov    0x1c(%eax),%eax
  105e87:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  105e8a:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  105e8d:	83 e0 0f             	and    $0xf,%eax
  105e90:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  105e93:	83 7d ec 01          	cmpl   $0x1,0xffffffec(%ebp)
  105e97:	74 28                	je     105ec1 <syscall+0x46>
  105e99:	83 7d ec 01          	cmpl   $0x1,0xffffffec(%ebp)
  105e9d:	72 0e                	jb     105ead <syscall+0x32>
  105e9f:	83 7d ec 02          	cmpl   $0x2,0xffffffec(%ebp)
  105ea3:	74 30                	je     105ed5 <syscall+0x5a>
  105ea5:	83 7d ec 03          	cmpl   $0x3,0xffffffec(%ebp)
  105ea9:	74 3e                	je     105ee9 <syscall+0x6e>
  105eab:	eb 47                	jmp    105ef4 <syscall+0x79>
  105ead:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  105eb0:	89 44 24 04          	mov    %eax,0x4(%esp)
  105eb4:	8b 45 08             	mov    0x8(%ebp),%eax
  105eb7:	89 04 24             	mov    %eax,(%esp)
  105eba:	e8 35 f7 ff ff       	call   1055f4 <do_cputs>
  105ebf:	eb 33                	jmp    105ef4 <syscall+0x79>
  105ec1:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  105ec4:	89 44 24 04          	mov    %eax,0x4(%esp)
  105ec8:	8b 45 08             	mov    0x8(%ebp),%eax
  105ecb:	89 04 24             	mov    %eax,(%esp)
  105ece:	e8 7e f7 ff ff       	call   105651 <do_put>
  105ed3:	eb 1f                	jmp    105ef4 <syscall+0x79>
  105ed5:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  105ed8:	89 44 24 04          	mov    %eax,0x4(%esp)
  105edc:	8b 45 08             	mov    0x8(%ebp),%eax
  105edf:	89 04 24             	mov    %eax,(%esp)
  105ee2:	e8 9f fb ff ff       	call   105a86 <do_get>
  105ee7:	eb 0b                	jmp    105ef4 <syscall+0x79>
  105ee9:	8b 45 08             	mov    0x8(%ebp),%eax
  105eec:	89 04 24             	mov    %eax,(%esp)
  105eef:	e8 6e ff ff ff       	call   105e62 <do_ret>
  105ef4:	c9                   	leave  
  105ef5:	c3                   	ret    
  105ef6:	90                   	nop    
  105ef7:	90                   	nop    

00105ef8 <pmap_init>:
  105ef8:	55                   	push   %ebp
  105ef9:	89 e5                	mov    %esp,%ebp
  105efb:	83 ec 28             	sub    $0x28,%esp
  105efe:	e8 bc 00 00 00       	call   105fbf <cpu_onboot>
  105f03:	85 c0                	test   %eax,%eax
  105f05:	74 51                	je     105f58 <pmap_init+0x60>
  105f07:	c7 45 e8 00 00 00 00 	movl   $0x0,0xffffffe8(%ebp)
  105f0e:	eb 19                	jmp    105f29 <pmap_init+0x31>
  105f10:	8b 55 e8             	mov    0xffffffe8(%ebp),%edx
  105f13:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  105f16:	c1 e0 16             	shl    $0x16,%eax
  105f19:	0d 83 01 00 00       	or     $0x183,%eax
  105f1e:	89 04 95 00 30 18 00 	mov    %eax,0x183000(,%edx,4)
  105f25:	83 45 e8 01          	addl   $0x1,0xffffffe8(%ebp)
  105f29:	81 7d e8 ff 03 00 00 	cmpl   $0x3ff,0xffffffe8(%ebp)
  105f30:	7e de                	jle    105f10 <pmap_init+0x18>
  105f32:	c7 45 e8 00 01 00 00 	movl   $0x100,0xffffffe8(%ebp)
  105f39:	eb 13                	jmp    105f4e <pmap_init+0x56>
  105f3b:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  105f3e:	ba 00 40 18 00       	mov    $0x184000,%edx
  105f43:	89 14 85 00 30 18 00 	mov    %edx,0x183000(,%eax,4)
  105f4a:	83 45 e8 01          	addl   $0x1,0xffffffe8(%ebp)
  105f4e:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  105f51:	3d bf 03 00 00       	cmp    $0x3bf,%eax
  105f56:	76 e3                	jbe    105f3b <pmap_init+0x43>
static gcc_inline uint32_t
rcr4(void)
{
	uint32_t cr4;
	__asm __volatile("movl %%cr4,%0" : "=r" (cr4));
  105f58:	0f 20 e0             	mov    %cr4,%eax
  105f5b:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
	return cr4;
  105f5e:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  105f61:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)
  105f64:	81 4d e0 90 00 00 00 	orl    $0x90,0xffffffe0(%ebp)
  105f6b:	81 4d e0 00 06 00 00 	orl    $0x600,0xffffffe0(%ebp)
  105f72:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  105f75:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
  105f78:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  105f7b:	0f 22 e0             	mov    %eax,%cr4
  105f7e:	b8 00 30 18 00       	mov    $0x183000,%eax
  105f83:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
  105f86:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  105f89:	0f 22 d8             	mov    %eax,%cr3
  105f8c:	0f 20 c0             	mov    %cr0,%eax
  105f8f:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  105f92:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  105f95:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
  105f98:	81 4d e4 2b 00 05 80 	orl    $0x8005002b,0xffffffe4(%ebp)
  105f9f:	83 65 e4 fb          	andl   $0xfffffffb,0xffffffe4(%ebp)
  105fa3:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  105fa6:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  105fa9:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  105fac:	0f 22 c0             	mov    %eax,%cr0
  105faf:	e8 0b 00 00 00       	call   105fbf <cpu_onboot>
  105fb4:	85 c0                	test   %eax,%eax
  105fb6:	74 05                	je     105fbd <pmap_init+0xc5>
  105fb8:	e8 4e 26 00 00       	call   10860b <pmap_check>
  105fbd:	c9                   	leave  
  105fbe:	c3                   	ret    

00105fbf <cpu_onboot>:
}

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  105fbf:	55                   	push   %ebp
  105fc0:	89 e5                	mov    %esp,%ebp
  105fc2:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  105fc5:	e8 0d 00 00 00       	call   105fd7 <cpu_cur>
  105fca:	3d 00 f0 10 00       	cmp    $0x10f000,%eax
  105fcf:	0f 94 c0             	sete   %al
  105fd2:	0f b6 c0             	movzbl %al,%eax
}
  105fd5:	c9                   	leave  
  105fd6:	c3                   	ret    

00105fd7 <cpu_cur>:
  105fd7:	55                   	push   %ebp
  105fd8:	89 e5                	mov    %esp,%ebp
  105fda:	83 ec 28             	sub    $0x28,%esp
static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  105fdd:	89 65 fc             	mov    %esp,0xfffffffc(%ebp)
        return esp;
  105fe0:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  105fe3:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  105fe6:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  105fe9:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  105fee:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	assert(c->magic == CPU_MAGIC);
  105ff1:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  105ff4:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  105ffa:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  105fff:	74 24                	je     106025 <cpu_cur+0x4e>
  106001:	c7 44 24 0c e8 d2 10 	movl   $0x10d2e8,0xc(%esp)
  106008:	00 
  106009:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  106010:	00 
  106011:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  106018:	00 
  106019:	c7 04 24 13 d3 10 00 	movl   $0x10d313,(%esp)
  106020:	e8 13 a9 ff ff       	call   100938 <debug_panic>
	return c;
  106025:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
}
  106028:	c9                   	leave  
  106029:	c3                   	ret    

0010602a <pmap_newpdir>:
  10602a:	55                   	push   %ebp
  10602b:	89 e5                	mov    %esp,%ebp
  10602d:	83 ec 28             	sub    $0x28,%esp
  106030:	e8 30 b4 ff ff       	call   101465 <mem_alloc>
  106035:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
  106038:	83 7d f4 00          	cmpl   $0x0,0xfffffff4(%ebp)
  10603c:	75 0c                	jne    10604a <pmap_newpdir+0x20>
  10603e:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  106045:	e9 2f 01 00 00       	jmp    106179 <pmap_newpdir+0x14f>
  10604a:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  10604d:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  106050:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  106055:	83 c0 08             	add    $0x8,%eax
  106058:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  10605b:	73 17                	jae    106074 <pmap_newpdir+0x4a>
  10605d:	a1 d8 1d 18 00       	mov    0x181dd8,%eax
  106062:	c1 e0 03             	shl    $0x3,%eax
  106065:	89 c2                	mov    %eax,%edx
  106067:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  10606c:	8d 04 02             	lea    (%edx,%eax,1),%eax
  10606f:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  106072:	77 24                	ja     106098 <pmap_newpdir+0x6e>
  106074:	c7 44 24 0c 20 d3 10 	movl   $0x10d320,0xc(%esp)
  10607b:	00 
  10607c:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  106083:	00 
  106084:	c7 44 24 04 9c 00 00 	movl   $0x9c,0x4(%esp)
  10608b:	00 
  10608c:	c7 04 24 57 d3 10 00 	movl   $0x10d357,(%esp)
  106093:	e8 a0 a8 ff ff       	call   100938 <debug_panic>
  106098:	8b 15 e0 1d 18 00    	mov    0x181de0,%edx
  10609e:	b8 00 40 18 00       	mov    $0x184000,%eax
  1060a3:	c1 e8 0c             	shr    $0xc,%eax
  1060a6:	c1 e0 03             	shl    $0x3,%eax
  1060a9:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1060ac:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  1060af:	75 24                	jne    1060d5 <pmap_newpdir+0xab>
  1060b1:	c7 44 24 0c 65 d3 10 	movl   $0x10d365,0xc(%esp)
  1060b8:	00 
  1060b9:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  1060c0:	00 
  1060c1:	c7 44 24 04 9e 00 00 	movl   $0x9e,0x4(%esp)
  1060c8:	00 
  1060c9:	c7 04 24 57 d3 10 00 	movl   $0x10d357,(%esp)
  1060d0:	e8 63 a8 ff ff       	call   100938 <debug_panic>
  1060d5:	8b 15 e0 1d 18 00    	mov    0x181de0,%edx
  1060db:	b8 0c 00 10 00       	mov    $0x10000c,%eax
  1060e0:	c1 e8 0c             	shr    $0xc,%eax
  1060e3:	c1 e0 03             	shl    $0x3,%eax
  1060e6:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1060e9:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  1060ec:	77 40                	ja     10612e <pmap_newpdir+0x104>
  1060ee:	8b 15 e0 1d 18 00    	mov    0x181de0,%edx
  1060f4:	b8 08 50 18 00       	mov    $0x185008,%eax
  1060f9:	83 e8 01             	sub    $0x1,%eax
  1060fc:	c1 e8 0c             	shr    $0xc,%eax
  1060ff:	c1 e0 03             	shl    $0x3,%eax
  106102:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106105:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  106108:	72 24                	jb     10612e <pmap_newpdir+0x104>
  10610a:	c7 44 24 0c 84 d3 10 	movl   $0x10d384,0xc(%esp)
  106111:	00 
  106112:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  106119:	00 
  10611a:	c7 44 24 04 a0 00 00 	movl   $0xa0,0x4(%esp)
  106121:	00 
  106122:	c7 04 24 57 d3 10 00 	movl   $0x10d357,(%esp)
  106129:	e8 0a a8 ff ff       	call   100938 <debug_panic>
  10612e:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  106131:	83 c0 04             	add    $0x4,%eax
  106134:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  10613b:	00 
  10613c:	89 04 24             	mov    %eax,(%esp)
  10613f:	e8 3a 00 00 00       	call   10617e <lockadd>
  106144:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  106147:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  10614c:	89 d1                	mov    %edx,%ecx
  10614e:	29 c1                	sub    %eax,%ecx
  106150:	89 c8                	mov    %ecx,%eax
  106152:	c1 e0 09             	shl    $0x9,%eax
  106155:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  106158:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  10615f:	00 
  106160:	c7 44 24 04 00 30 18 	movl   $0x183000,0x4(%esp)
  106167:	00 
  106168:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10616b:	89 04 24             	mov    %eax,(%esp)
  10616e:	e8 f7 5a 00 00       	call   10bc6a <memmove>
  106173:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  106176:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  106179:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  10617c:	c9                   	leave  
  10617d:	c3                   	ret    

0010617e <lockadd>:

// Atomically add incr to *addr.
static inline void
lockadd(volatile int32_t *addr, int32_t incr)
{
  10617e:	55                   	push   %ebp
  10617f:	89 e5                	mov    %esp,%ebp
	asm volatile("lock; addl %1,%0" : "+m" (*addr) : "r" (incr) : "cc");
  106181:	8b 4d 08             	mov    0x8(%ebp),%ecx
  106184:	8b 55 0c             	mov    0xc(%ebp),%edx
  106187:	8b 45 08             	mov    0x8(%ebp),%eax
  10618a:	f0 01 11             	lock add %edx,(%ecx)
}
  10618d:	5d                   	pop    %ebp
  10618e:	c3                   	ret    

0010618f <pmap_freepdir>:
  10618f:	55                   	push   %ebp
  106190:	89 e5                	mov    %esp,%ebp
  106192:	83 ec 18             	sub    $0x18,%esp
  106195:	8b 55 08             	mov    0x8(%ebp),%edx
  106198:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  10619d:	89 d1                	mov    %edx,%ecx
  10619f:	29 c1                	sub    %eax,%ecx
  1061a1:	89 c8                	mov    %ecx,%eax
  1061a3:	c1 e0 09             	shl    $0x9,%eax
  1061a6:	c7 44 24 08 00 00 00 	movl   $0xb0000000,0x8(%esp)
  1061ad:	b0 
  1061ae:	c7 44 24 04 00 00 00 	movl   $0x40000000,0x4(%esp)
  1061b5:	40 
  1061b6:	89 04 24             	mov    %eax,(%esp)
  1061b9:	e8 0f 0a 00 00       	call   106bcd <pmap_remove>
  1061be:	8b 45 08             	mov    0x8(%ebp),%eax
  1061c1:	89 04 24             	mov    %eax,(%esp)
  1061c4:	e8 e0 b2 ff ff       	call   1014a9 <mem_free>
  1061c9:	c9                   	leave  
  1061ca:	c3                   	ret    

001061cb <pmap_freeptab>:
  1061cb:	55                   	push   %ebp
  1061cc:	89 e5                	mov    %esp,%ebp
  1061ce:	83 ec 38             	sub    $0x38,%esp
  1061d1:	8b 55 08             	mov    0x8(%ebp),%edx
  1061d4:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  1061d9:	89 d1                	mov    %edx,%ecx
  1061db:	29 c1                	sub    %eax,%ecx
  1061dd:	89 c8                	mov    %ecx,%eax
  1061df:	c1 e0 09             	shl    $0x9,%eax
  1061e2:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  1061e5:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  1061e8:	05 00 10 00 00       	add    $0x1000,%eax
  1061ed:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
  1061f0:	e9 6d 01 00 00       	jmp    106362 <pmap_freeptab+0x197>
  1061f5:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  1061f8:	8b 00                	mov    (%eax),%eax
  1061fa:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1061ff:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
  106202:	b8 00 40 18 00       	mov    $0x184000,%eax
  106207:	39 45 f4             	cmp    %eax,0xfffffff4(%ebp)
  10620a:	0f 84 4e 01 00 00    	je     10635e <pmap_freeptab+0x193>
  106210:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  106213:	c1 e8 0c             	shr    $0xc,%eax
  106216:	c1 e0 03             	shl    $0x3,%eax
  106219:	89 c2                	mov    %eax,%edx
  10621b:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  106220:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106223:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  106226:	c7 45 f8 a9 14 10 00 	movl   $0x1014a9,0xfffffff8(%ebp)
  10622d:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  106232:	83 c0 08             	add    $0x8,%eax
  106235:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  106238:	73 17                	jae    106251 <pmap_freeptab+0x86>
  10623a:	a1 d8 1d 18 00       	mov    0x181dd8,%eax
  10623f:	c1 e0 03             	shl    $0x3,%eax
  106242:	89 c2                	mov    %eax,%edx
  106244:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  106249:	8d 04 02             	lea    (%edx,%eax,1),%eax
  10624c:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  10624f:	77 24                	ja     106275 <pmap_freeptab+0xaa>
  106251:	c7 44 24 0c 20 d3 10 	movl   $0x10d320,0xc(%esp)
  106258:	00 
  106259:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  106260:	00 
  106261:	c7 44 24 04 aa 00 00 	movl   $0xaa,0x4(%esp)
  106268:	00 
  106269:	c7 04 24 57 d3 10 00 	movl   $0x10d357,(%esp)
  106270:	e8 c3 a6 ff ff       	call   100938 <debug_panic>
  106275:	8b 15 e0 1d 18 00    	mov    0x181de0,%edx
  10627b:	b8 00 40 18 00       	mov    $0x184000,%eax
  106280:	c1 e8 0c             	shr    $0xc,%eax
  106283:	c1 e0 03             	shl    $0x3,%eax
  106286:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106289:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  10628c:	75 24                	jne    1062b2 <pmap_freeptab+0xe7>
  10628e:	c7 44 24 0c 65 d3 10 	movl   $0x10d365,0xc(%esp)
  106295:	00 
  106296:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  10629d:	00 
  10629e:	c7 44 24 04 ac 00 00 	movl   $0xac,0x4(%esp)
  1062a5:	00 
  1062a6:	c7 04 24 57 d3 10 00 	movl   $0x10d357,(%esp)
  1062ad:	e8 86 a6 ff ff       	call   100938 <debug_panic>
  1062b2:	8b 15 e0 1d 18 00    	mov    0x181de0,%edx
  1062b8:	b8 0c 00 10 00       	mov    $0x10000c,%eax
  1062bd:	c1 e8 0c             	shr    $0xc,%eax
  1062c0:	c1 e0 03             	shl    $0x3,%eax
  1062c3:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1062c6:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  1062c9:	77 40                	ja     10630b <pmap_freeptab+0x140>
  1062cb:	8b 15 e0 1d 18 00    	mov    0x181de0,%edx
  1062d1:	b8 08 50 18 00       	mov    $0x185008,%eax
  1062d6:	83 e8 01             	sub    $0x1,%eax
  1062d9:	c1 e8 0c             	shr    $0xc,%eax
  1062dc:	c1 e0 03             	shl    $0x3,%eax
  1062df:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1062e2:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  1062e5:	72 24                	jb     10630b <pmap_freeptab+0x140>
  1062e7:	c7 44 24 0c 84 d3 10 	movl   $0x10d384,0xc(%esp)
  1062ee:	00 
  1062ef:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  1062f6:	00 
  1062f7:	c7 44 24 04 ae 00 00 	movl   $0xae,0x4(%esp)
  1062fe:	00 
  1062ff:	c7 04 24 57 d3 10 00 	movl   $0x10d357,(%esp)
  106306:	e8 2d a6 ff ff       	call   100938 <debug_panic>
  10630b:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  10630e:	83 c0 04             	add    $0x4,%eax
  106311:	c7 44 24 04 ff ff ff 	movl   $0xffffffff,0x4(%esp)
  106318:	ff 
  106319:	89 04 24             	mov    %eax,(%esp)
  10631c:	e8 5a 00 00 00       	call   10637b <lockaddz>
  106321:	84 c0                	test   %al,%al
  106323:	74 0b                	je     106330 <pmap_freeptab+0x165>
  106325:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  106328:	89 04 24             	mov    %eax,(%esp)
  10632b:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10632e:	ff d0                	call   *%eax
  106330:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  106333:	8b 40 04             	mov    0x4(%eax),%eax
  106336:	85 c0                	test   %eax,%eax
  106338:	79 24                	jns    10635e <pmap_freeptab+0x193>
  10633a:	c7 44 24 0c b5 d3 10 	movl   $0x10d3b5,0xc(%esp)
  106341:	00 
  106342:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  106349:	00 
  10634a:	c7 44 24 04 b5 00 00 	movl   $0xb5,0x4(%esp)
  106351:	00 
  106352:	c7 04 24 57 d3 10 00 	movl   $0x10d357,(%esp)
  106359:	e8 da a5 ff ff       	call   100938 <debug_panic>
  10635e:	83 45 ec 04          	addl   $0x4,0xffffffec(%ebp)
  106362:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  106365:	3b 45 f0             	cmp    0xfffffff0(%ebp),%eax
  106368:	0f 82 87 fe ff ff    	jb     1061f5 <pmap_freeptab+0x2a>
  10636e:	8b 45 08             	mov    0x8(%ebp),%eax
  106371:	89 04 24             	mov    %eax,(%esp)
  106374:	e8 30 b1 ff ff       	call   1014a9 <mem_free>
  106379:	c9                   	leave  
  10637a:	c3                   	ret    

0010637b <lockaddz>:

// Atomically add incr to *addr and return true if the result is zero.
static inline uint8_t
lockaddz(volatile int32_t *addr, int32_t incr)
{
  10637b:	55                   	push   %ebp
  10637c:	89 e5                	mov    %esp,%ebp
  10637e:	83 ec 10             	sub    $0x10,%esp
	uint8_t zero;
	asm volatile("lock; addl %2,%0; setzb %1"
  106381:	8b 4d 08             	mov    0x8(%ebp),%ecx
  106384:	8b 55 0c             	mov    0xc(%ebp),%edx
  106387:	8b 45 08             	mov    0x8(%ebp),%eax
  10638a:	f0 01 11             	lock add %edx,(%ecx)
  10638d:	0f 94 45 ff          	sete   0xffffffff(%ebp)
		: "+m" (*addr), "=rm" (zero)
		: "r" (incr)
		: "cc");
	return zero;
  106391:	0f b6 45 ff          	movzbl 0xffffffff(%ebp),%eax
}
  106395:	c9                   	leave  
  106396:	c3                   	ret    

00106397 <pmap_walk>:
  106397:	55                   	push   %ebp
  106398:	89 e5                	mov    %esp,%ebp
  10639a:	83 ec 58             	sub    $0x58,%esp
  10639d:	81 7d 0c ff ff ff 3f 	cmpl   $0x3fffffff,0xc(%ebp)
  1063a4:	76 09                	jbe    1063af <pmap_walk+0x18>
  1063a6:	81 7d 0c ff ff ff ef 	cmpl   $0xefffffff,0xc(%ebp)
  1063ad:	76 24                	jbe    1063d3 <pmap_walk+0x3c>
  1063af:	c7 44 24 0c c8 d3 10 	movl   $0x10d3c8,0xc(%esp)
  1063b6:	00 
  1063b7:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  1063be:	00 
  1063bf:	c7 44 24 04 ae 00 00 	movl   $0xae,0x4(%esp)
  1063c6:	00 
  1063c7:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  1063ce:	e8 65 a5 ff ff       	call   100938 <debug_panic>
  1063d3:	8b 45 0c             	mov    0xc(%ebp),%eax
  1063d6:	89 45 c4             	mov    %eax,0xffffffc4(%ebp)
  1063d9:	8b 45 c4             	mov    0xffffffc4(%ebp),%eax
  1063dc:	c1 e8 16             	shr    $0x16,%eax
  1063df:	25 ff 03 00 00       	and    $0x3ff,%eax
  1063e4:	c1 e0 02             	shl    $0x2,%eax
  1063e7:	03 45 08             	add    0x8(%ebp),%eax
  1063ea:	89 45 c8             	mov    %eax,0xffffffc8(%ebp)
  1063ed:	8b 45 c8             	mov    0xffffffc8(%ebp),%eax
  1063f0:	8b 00                	mov    (%eax),%eax
  1063f2:	83 e0 01             	and    $0x1,%eax
  1063f5:	84 c0                	test   %al,%al
  1063f7:	74 12                	je     10640b <pmap_walk+0x74>
  1063f9:	8b 45 c8             	mov    0xffffffc8(%ebp),%eax
  1063fc:	8b 00                	mov    (%eax),%eax
  1063fe:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  106403:	89 45 cc             	mov    %eax,0xffffffcc(%ebp)
  106406:	e9 a3 01 00 00       	jmp    1065ae <pmap_walk+0x217>
  10640b:	8b 45 c8             	mov    0xffffffc8(%ebp),%eax
  10640e:	8b 10                	mov    (%eax),%edx
  106410:	b8 00 40 18 00       	mov    $0x184000,%eax
  106415:	39 c2                	cmp    %eax,%edx
  106417:	74 24                	je     10643d <pmap_walk+0xa6>
  106419:	c7 44 24 0c f9 d3 10 	movl   $0x10d3f9,0xc(%esp)
  106420:	00 
  106421:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  106428:	00 
  106429:	c7 44 24 04 b7 00 00 	movl   $0xb7,0x4(%esp)
  106430:	00 
  106431:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  106438:	e8 fb a4 ff ff       	call   100938 <debug_panic>
  10643d:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  106441:	74 0e                	je     106451 <pmap_walk+0xba>
  106443:	e8 1d b0 ff ff       	call   101465 <mem_alloc>
  106448:	89 45 d0             	mov    %eax,0xffffffd0(%ebp)
  10644b:	83 7d d0 00          	cmpl   $0x0,0xffffffd0(%ebp)
  10644f:	75 0c                	jne    10645d <pmap_walk+0xc6>
  106451:	c7 45 bc 00 00 00 00 	movl   $0x0,0xffffffbc(%ebp)
  106458:	e9 ed 05 00 00       	jmp    106a4a <pmap_walk+0x6b3>
  10645d:	8b 45 d0             	mov    0xffffffd0(%ebp),%eax
  106460:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  106463:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  106468:	83 c0 08             	add    $0x8,%eax
  10646b:	3b 45 ec             	cmp    0xffffffec(%ebp),%eax
  10646e:	73 17                	jae    106487 <pmap_walk+0xf0>
  106470:	a1 d8 1d 18 00       	mov    0x181dd8,%eax
  106475:	c1 e0 03             	shl    $0x3,%eax
  106478:	89 c2                	mov    %eax,%edx
  10647a:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  10647f:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106482:	3b 45 ec             	cmp    0xffffffec(%ebp),%eax
  106485:	77 24                	ja     1064ab <pmap_walk+0x114>
  106487:	c7 44 24 0c 20 d3 10 	movl   $0x10d320,0xc(%esp)
  10648e:	00 
  10648f:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  106496:	00 
  106497:	c7 44 24 04 9c 00 00 	movl   $0x9c,0x4(%esp)
  10649e:	00 
  10649f:	c7 04 24 57 d3 10 00 	movl   $0x10d357,(%esp)
  1064a6:	e8 8d a4 ff ff       	call   100938 <debug_panic>
  1064ab:	8b 15 e0 1d 18 00    	mov    0x181de0,%edx
  1064b1:	b8 00 40 18 00       	mov    $0x184000,%eax
  1064b6:	c1 e8 0c             	shr    $0xc,%eax
  1064b9:	c1 e0 03             	shl    $0x3,%eax
  1064bc:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1064bf:	3b 45 ec             	cmp    0xffffffec(%ebp),%eax
  1064c2:	75 24                	jne    1064e8 <pmap_walk+0x151>
  1064c4:	c7 44 24 0c 65 d3 10 	movl   $0x10d365,0xc(%esp)
  1064cb:	00 
  1064cc:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  1064d3:	00 
  1064d4:	c7 44 24 04 9e 00 00 	movl   $0x9e,0x4(%esp)
  1064db:	00 
  1064dc:	c7 04 24 57 d3 10 00 	movl   $0x10d357,(%esp)
  1064e3:	e8 50 a4 ff ff       	call   100938 <debug_panic>
  1064e8:	8b 15 e0 1d 18 00    	mov    0x181de0,%edx
  1064ee:	b8 0c 00 10 00       	mov    $0x10000c,%eax
  1064f3:	c1 e8 0c             	shr    $0xc,%eax
  1064f6:	c1 e0 03             	shl    $0x3,%eax
  1064f9:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1064fc:	3b 45 ec             	cmp    0xffffffec(%ebp),%eax
  1064ff:	77 40                	ja     106541 <pmap_walk+0x1aa>
  106501:	8b 15 e0 1d 18 00    	mov    0x181de0,%edx
  106507:	b8 08 50 18 00       	mov    $0x185008,%eax
  10650c:	83 e8 01             	sub    $0x1,%eax
  10650f:	c1 e8 0c             	shr    $0xc,%eax
  106512:	c1 e0 03             	shl    $0x3,%eax
  106515:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106518:	3b 45 ec             	cmp    0xffffffec(%ebp),%eax
  10651b:	72 24                	jb     106541 <pmap_walk+0x1aa>
  10651d:	c7 44 24 0c 84 d3 10 	movl   $0x10d384,0xc(%esp)
  106524:	00 
  106525:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  10652c:	00 
  10652d:	c7 44 24 04 a0 00 00 	movl   $0xa0,0x4(%esp)
  106534:	00 
  106535:	c7 04 24 57 d3 10 00 	movl   $0x10d357,(%esp)
  10653c:	e8 f7 a3 ff ff       	call   100938 <debug_panic>
  106541:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  106544:	83 c0 04             	add    $0x4,%eax
  106547:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  10654e:	00 
  10654f:	89 04 24             	mov    %eax,(%esp)
  106552:	e8 27 fc ff ff       	call   10617e <lockadd>
  106557:	8b 55 d0             	mov    0xffffffd0(%ebp),%edx
  10655a:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  10655f:	89 d1                	mov    %edx,%ecx
  106561:	29 c1                	sub    %eax,%ecx
  106563:	89 c8                	mov    %ecx,%eax
  106565:	c1 e0 09             	shl    $0x9,%eax
  106568:	89 45 cc             	mov    %eax,0xffffffcc(%ebp)
  10656b:	c7 45 d4 00 00 00 00 	movl   $0x0,0xffffffd4(%ebp)
  106572:	eb 16                	jmp    10658a <pmap_walk+0x1f3>
  106574:	8b 45 d4             	mov    0xffffffd4(%ebp),%eax
  106577:	c1 e0 02             	shl    $0x2,%eax
  10657a:	89 c2                	mov    %eax,%edx
  10657c:	03 55 cc             	add    0xffffffcc(%ebp),%edx
  10657f:	b8 00 40 18 00       	mov    $0x184000,%eax
  106584:	89 02                	mov    %eax,(%edx)
  106586:	83 45 d4 01          	addl   $0x1,0xffffffd4(%ebp)
  10658a:	81 7d d4 ff 03 00 00 	cmpl   $0x3ff,0xffffffd4(%ebp)
  106591:	7e e1                	jle    106574 <pmap_walk+0x1dd>
  106593:	8b 55 d0             	mov    0xffffffd0(%ebp),%edx
  106596:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  10659b:	89 d1                	mov    %edx,%ecx
  10659d:	29 c1                	sub    %eax,%ecx
  10659f:	89 c8                	mov    %ecx,%eax
  1065a1:	c1 e0 09             	shl    $0x9,%eax
  1065a4:	83 c8 27             	or     $0x27,%eax
  1065a7:	89 c2                	mov    %eax,%edx
  1065a9:	8b 45 c8             	mov    0xffffffc8(%ebp),%eax
  1065ac:	89 10                	mov    %edx,(%eax)
  1065ae:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  1065b2:	0f 84 7c 04 00 00    	je     106a34 <pmap_walk+0x69d>
  1065b8:	8b 45 c8             	mov    0xffffffc8(%ebp),%eax
  1065bb:	8b 00                	mov    (%eax),%eax
  1065bd:	83 e0 02             	and    $0x2,%eax
  1065c0:	85 c0                	test   %eax,%eax
  1065c2:	0f 85 6c 04 00 00    	jne    106a34 <pmap_walk+0x69d>
  1065c8:	8b 45 cc             	mov    0xffffffcc(%ebp),%eax
  1065cb:	c1 e8 0c             	shr    $0xc,%eax
  1065ce:	c1 e0 03             	shl    $0x3,%eax
  1065d1:	89 c2                	mov    %eax,%edx
  1065d3:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  1065d8:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1065db:	8b 40 04             	mov    0x4(%eax),%eax
  1065de:	83 f8 01             	cmp    $0x1,%eax
  1065e1:	75 36                	jne    106619 <pmap_walk+0x282>
  1065e3:	c7 45 d8 00 00 00 00 	movl   $0x0,0xffffffd8(%ebp)
  1065ea:	eb 1f                	jmp    10660b <pmap_walk+0x274>
  1065ec:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  1065ef:	c1 e0 02             	shl    $0x2,%eax
  1065f2:	89 c2                	mov    %eax,%edx
  1065f4:	03 55 cc             	add    0xffffffcc(%ebp),%edx
  1065f7:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  1065fa:	c1 e0 02             	shl    $0x2,%eax
  1065fd:	03 45 cc             	add    0xffffffcc(%ebp),%eax
  106600:	8b 00                	mov    (%eax),%eax
  106602:	83 e0 fd             	and    $0xfffffffd,%eax
  106605:	89 02                	mov    %eax,(%edx)
  106607:	83 45 d8 01          	addl   $0x1,0xffffffd8(%ebp)
  10660b:	81 7d d8 ff 03 00 00 	cmpl   $0x3ff,0xffffffd8(%ebp)
  106612:	7e d8                	jle    1065ec <pmap_walk+0x255>
  106614:	e9 0e 04 00 00       	jmp    106a27 <pmap_walk+0x690>
  106619:	e8 47 ae ff ff       	call   101465 <mem_alloc>
  10661e:	89 45 dc             	mov    %eax,0xffffffdc(%ebp)
  106621:	83 7d dc 00          	cmpl   $0x0,0xffffffdc(%ebp)
  106625:	75 0c                	jne    106633 <pmap_walk+0x29c>
  106627:	c7 45 bc 00 00 00 00 	movl   $0x0,0xffffffbc(%ebp)
  10662e:	e9 17 04 00 00       	jmp    106a4a <pmap_walk+0x6b3>
  106633:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  106636:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
  106639:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  10663e:	83 c0 08             	add    $0x8,%eax
  106641:	3b 45 f0             	cmp    0xfffffff0(%ebp),%eax
  106644:	73 17                	jae    10665d <pmap_walk+0x2c6>
  106646:	a1 d8 1d 18 00       	mov    0x181dd8,%eax
  10664b:	c1 e0 03             	shl    $0x3,%eax
  10664e:	89 c2                	mov    %eax,%edx
  106650:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  106655:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106658:	3b 45 f0             	cmp    0xfffffff0(%ebp),%eax
  10665b:	77 24                	ja     106681 <pmap_walk+0x2ea>
  10665d:	c7 44 24 0c 20 d3 10 	movl   $0x10d320,0xc(%esp)
  106664:	00 
  106665:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  10666c:	00 
  10666d:	c7 44 24 04 9c 00 00 	movl   $0x9c,0x4(%esp)
  106674:	00 
  106675:	c7 04 24 57 d3 10 00 	movl   $0x10d357,(%esp)
  10667c:	e8 b7 a2 ff ff       	call   100938 <debug_panic>
  106681:	8b 15 e0 1d 18 00    	mov    0x181de0,%edx
  106687:	b8 00 40 18 00       	mov    $0x184000,%eax
  10668c:	c1 e8 0c             	shr    $0xc,%eax
  10668f:	c1 e0 03             	shl    $0x3,%eax
  106692:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106695:	3b 45 f0             	cmp    0xfffffff0(%ebp),%eax
  106698:	75 24                	jne    1066be <pmap_walk+0x327>
  10669a:	c7 44 24 0c 65 d3 10 	movl   $0x10d365,0xc(%esp)
  1066a1:	00 
  1066a2:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  1066a9:	00 
  1066aa:	c7 44 24 04 9e 00 00 	movl   $0x9e,0x4(%esp)
  1066b1:	00 
  1066b2:	c7 04 24 57 d3 10 00 	movl   $0x10d357,(%esp)
  1066b9:	e8 7a a2 ff ff       	call   100938 <debug_panic>
  1066be:	8b 15 e0 1d 18 00    	mov    0x181de0,%edx
  1066c4:	b8 0c 00 10 00       	mov    $0x10000c,%eax
  1066c9:	c1 e8 0c             	shr    $0xc,%eax
  1066cc:	c1 e0 03             	shl    $0x3,%eax
  1066cf:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1066d2:	3b 45 f0             	cmp    0xfffffff0(%ebp),%eax
  1066d5:	77 40                	ja     106717 <pmap_walk+0x380>
  1066d7:	8b 15 e0 1d 18 00    	mov    0x181de0,%edx
  1066dd:	b8 08 50 18 00       	mov    $0x185008,%eax
  1066e2:	83 e8 01             	sub    $0x1,%eax
  1066e5:	c1 e8 0c             	shr    $0xc,%eax
  1066e8:	c1 e0 03             	shl    $0x3,%eax
  1066eb:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1066ee:	3b 45 f0             	cmp    0xfffffff0(%ebp),%eax
  1066f1:	72 24                	jb     106717 <pmap_walk+0x380>
  1066f3:	c7 44 24 0c 84 d3 10 	movl   $0x10d384,0xc(%esp)
  1066fa:	00 
  1066fb:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  106702:	00 
  106703:	c7 44 24 04 a0 00 00 	movl   $0xa0,0x4(%esp)
  10670a:	00 
  10670b:	c7 04 24 57 d3 10 00 	movl   $0x10d357,(%esp)
  106712:	e8 21 a2 ff ff       	call   100938 <debug_panic>
  106717:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  10671a:	83 c0 04             	add    $0x4,%eax
  10671d:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  106724:	00 
  106725:	89 04 24             	mov    %eax,(%esp)
  106728:	e8 51 fa ff ff       	call   10617e <lockadd>
  10672d:	8b 55 dc             	mov    0xffffffdc(%ebp),%edx
  106730:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  106735:	89 d1                	mov    %edx,%ecx
  106737:	29 c1                	sub    %eax,%ecx
  106739:	89 c8                	mov    %ecx,%eax
  10673b:	c1 e0 09             	shl    $0x9,%eax
  10673e:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)
  106741:	c7 45 e4 00 00 00 00 	movl   $0x0,0xffffffe4(%ebp)
  106748:	e9 79 01 00 00       	jmp    1068c6 <pmap_walk+0x52f>
  10674d:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  106750:	c1 e0 02             	shl    $0x2,%eax
  106753:	03 45 cc             	add    0xffffffcc(%ebp),%eax
  106756:	8b 00                	mov    (%eax),%eax
  106758:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  10675b:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  10675e:	c1 e0 02             	shl    $0x2,%eax
  106761:	89 c2                	mov    %eax,%edx
  106763:	03 55 e0             	add    0xffffffe0(%ebp),%edx
  106766:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  106769:	83 e0 fd             	and    $0xfffffffd,%eax
  10676c:	89 02                	mov    %eax,(%edx)
  10676e:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  106771:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  106776:	85 c0                	test   %eax,%eax
  106778:	75 24                	jne    10679e <pmap_walk+0x407>
  10677a:	c7 44 24 0c 0a d4 10 	movl   $0x10d40a,0xc(%esp)
  106781:	00 
  106782:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  106789:	00 
  10678a:	c7 44 24 04 e3 00 00 	movl   $0xe3,0x4(%esp)
  106791:	00 
  106792:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  106799:	e8 9a a1 ff ff       	call   100938 <debug_panic>
  10679e:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  1067a1:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1067a6:	ba 00 40 18 00       	mov    $0x184000,%edx
  1067ab:	39 d0                	cmp    %edx,%eax
  1067ad:	0f 84 0f 01 00 00    	je     1068c2 <pmap_walk+0x52b>
  1067b3:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  1067b6:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1067bb:	c1 e8 0c             	shr    $0xc,%eax
  1067be:	c1 e0 03             	shl    $0x3,%eax
  1067c1:	89 c2                	mov    %eax,%edx
  1067c3:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  1067c8:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1067cb:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
  1067ce:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  1067d3:	83 c0 08             	add    $0x8,%eax
  1067d6:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  1067d9:	73 17                	jae    1067f2 <pmap_walk+0x45b>
  1067db:	a1 d8 1d 18 00       	mov    0x181dd8,%eax
  1067e0:	c1 e0 03             	shl    $0x3,%eax
  1067e3:	89 c2                	mov    %eax,%edx
  1067e5:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  1067ea:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1067ed:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  1067f0:	77 24                	ja     106816 <pmap_walk+0x47f>
  1067f2:	c7 44 24 0c 20 d3 10 	movl   $0x10d320,0xc(%esp)
  1067f9:	00 
  1067fa:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  106801:	00 
  106802:	c7 44 24 04 9c 00 00 	movl   $0x9c,0x4(%esp)
  106809:	00 
  10680a:	c7 04 24 57 d3 10 00 	movl   $0x10d357,(%esp)
  106811:	e8 22 a1 ff ff       	call   100938 <debug_panic>
  106816:	8b 15 e0 1d 18 00    	mov    0x181de0,%edx
  10681c:	b8 00 40 18 00       	mov    $0x184000,%eax
  106821:	c1 e8 0c             	shr    $0xc,%eax
  106824:	c1 e0 03             	shl    $0x3,%eax
  106827:	8d 04 02             	lea    (%edx,%eax,1),%eax
  10682a:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  10682d:	75 24                	jne    106853 <pmap_walk+0x4bc>
  10682f:	c7 44 24 0c 65 d3 10 	movl   $0x10d365,0xc(%esp)
  106836:	00 
  106837:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  10683e:	00 
  10683f:	c7 44 24 04 9e 00 00 	movl   $0x9e,0x4(%esp)
  106846:	00 
  106847:	c7 04 24 57 d3 10 00 	movl   $0x10d357,(%esp)
  10684e:	e8 e5 a0 ff ff       	call   100938 <debug_panic>
  106853:	8b 15 e0 1d 18 00    	mov    0x181de0,%edx
  106859:	b8 0c 00 10 00       	mov    $0x10000c,%eax
  10685e:	c1 e8 0c             	shr    $0xc,%eax
  106861:	c1 e0 03             	shl    $0x3,%eax
  106864:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106867:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  10686a:	77 40                	ja     1068ac <pmap_walk+0x515>
  10686c:	8b 15 e0 1d 18 00    	mov    0x181de0,%edx
  106872:	b8 08 50 18 00       	mov    $0x185008,%eax
  106877:	83 e8 01             	sub    $0x1,%eax
  10687a:	c1 e8 0c             	shr    $0xc,%eax
  10687d:	c1 e0 03             	shl    $0x3,%eax
  106880:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106883:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  106886:	72 24                	jb     1068ac <pmap_walk+0x515>
  106888:	c7 44 24 0c 84 d3 10 	movl   $0x10d384,0xc(%esp)
  10688f:	00 
  106890:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  106897:	00 
  106898:	c7 44 24 04 a0 00 00 	movl   $0xa0,0x4(%esp)
  10689f:	00 
  1068a0:	c7 04 24 57 d3 10 00 	movl   $0x10d357,(%esp)
  1068a7:	e8 8c a0 ff ff       	call   100938 <debug_panic>
  1068ac:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  1068af:	83 c0 04             	add    $0x4,%eax
  1068b2:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  1068b9:	00 
  1068ba:	89 04 24             	mov    %eax,(%esp)
  1068bd:	e8 bc f8 ff ff       	call   10617e <lockadd>
  1068c2:	83 45 e4 01          	addl   $0x1,0xffffffe4(%ebp)
  1068c6:	81 7d e4 ff 03 00 00 	cmpl   $0x3ff,0xffffffe4(%ebp)
  1068cd:	0f 8e 7a fe ff ff    	jle    10674d <pmap_walk+0x3b6>
  1068d3:	8b 45 cc             	mov    0xffffffcc(%ebp),%eax
  1068d6:	c1 e8 0c             	shr    $0xc,%eax
  1068d9:	c1 e0 03             	shl    $0x3,%eax
  1068dc:	89 c2                	mov    %eax,%edx
  1068de:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  1068e3:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1068e6:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  1068e9:	c7 45 f8 cb 61 10 00 	movl   $0x1061cb,0xfffffff8(%ebp)
  1068f0:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  1068f5:	83 c0 08             	add    $0x8,%eax
  1068f8:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  1068fb:	73 17                	jae    106914 <pmap_walk+0x57d>
  1068fd:	a1 d8 1d 18 00       	mov    0x181dd8,%eax
  106902:	c1 e0 03             	shl    $0x3,%eax
  106905:	89 c2                	mov    %eax,%edx
  106907:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  10690c:	8d 04 02             	lea    (%edx,%eax,1),%eax
  10690f:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  106912:	77 24                	ja     106938 <pmap_walk+0x5a1>
  106914:	c7 44 24 0c 20 d3 10 	movl   $0x10d320,0xc(%esp)
  10691b:	00 
  10691c:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  106923:	00 
  106924:	c7 44 24 04 aa 00 00 	movl   $0xaa,0x4(%esp)
  10692b:	00 
  10692c:	c7 04 24 57 d3 10 00 	movl   $0x10d357,(%esp)
  106933:	e8 00 a0 ff ff       	call   100938 <debug_panic>
  106938:	8b 15 e0 1d 18 00    	mov    0x181de0,%edx
  10693e:	b8 00 40 18 00       	mov    $0x184000,%eax
  106943:	c1 e8 0c             	shr    $0xc,%eax
  106946:	c1 e0 03             	shl    $0x3,%eax
  106949:	8d 04 02             	lea    (%edx,%eax,1),%eax
  10694c:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  10694f:	75 24                	jne    106975 <pmap_walk+0x5de>
  106951:	c7 44 24 0c 65 d3 10 	movl   $0x10d365,0xc(%esp)
  106958:	00 
  106959:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  106960:	00 
  106961:	c7 44 24 04 ac 00 00 	movl   $0xac,0x4(%esp)
  106968:	00 
  106969:	c7 04 24 57 d3 10 00 	movl   $0x10d357,(%esp)
  106970:	e8 c3 9f ff ff       	call   100938 <debug_panic>
  106975:	8b 15 e0 1d 18 00    	mov    0x181de0,%edx
  10697b:	b8 0c 00 10 00       	mov    $0x10000c,%eax
  106980:	c1 e8 0c             	shr    $0xc,%eax
  106983:	c1 e0 03             	shl    $0x3,%eax
  106986:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106989:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  10698c:	77 40                	ja     1069ce <pmap_walk+0x637>
  10698e:	8b 15 e0 1d 18 00    	mov    0x181de0,%edx
  106994:	b8 08 50 18 00       	mov    $0x185008,%eax
  106999:	83 e8 01             	sub    $0x1,%eax
  10699c:	c1 e8 0c             	shr    $0xc,%eax
  10699f:	c1 e0 03             	shl    $0x3,%eax
  1069a2:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1069a5:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  1069a8:	72 24                	jb     1069ce <pmap_walk+0x637>
  1069aa:	c7 44 24 0c 84 d3 10 	movl   $0x10d384,0xc(%esp)
  1069b1:	00 
  1069b2:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  1069b9:	00 
  1069ba:	c7 44 24 04 ae 00 00 	movl   $0xae,0x4(%esp)
  1069c1:	00 
  1069c2:	c7 04 24 57 d3 10 00 	movl   $0x10d357,(%esp)
  1069c9:	e8 6a 9f ff ff       	call   100938 <debug_panic>
  1069ce:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  1069d1:	83 c0 04             	add    $0x4,%eax
  1069d4:	c7 44 24 04 ff ff ff 	movl   $0xffffffff,0x4(%esp)
  1069db:	ff 
  1069dc:	89 04 24             	mov    %eax,(%esp)
  1069df:	e8 97 f9 ff ff       	call   10637b <lockaddz>
  1069e4:	84 c0                	test   %al,%al
  1069e6:	74 0b                	je     1069f3 <pmap_walk+0x65c>
  1069e8:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  1069eb:	89 04 24             	mov    %eax,(%esp)
  1069ee:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1069f1:	ff d0                	call   *%eax
  1069f3:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  1069f6:	8b 40 04             	mov    0x4(%eax),%eax
  1069f9:	85 c0                	test   %eax,%eax
  1069fb:	79 24                	jns    106a21 <pmap_walk+0x68a>
  1069fd:	c7 44 24 0c b5 d3 10 	movl   $0x10d3b5,0xc(%esp)
  106a04:	00 
  106a05:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  106a0c:	00 
  106a0d:	c7 44 24 04 b5 00 00 	movl   $0xb5,0x4(%esp)
  106a14:	00 
  106a15:	c7 04 24 57 d3 10 00 	movl   $0x10d357,(%esp)
  106a1c:	e8 17 9f ff ff       	call   100938 <debug_panic>
  106a21:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  106a24:	89 45 cc             	mov    %eax,0xffffffcc(%ebp)
  106a27:	8b 45 cc             	mov    0xffffffcc(%ebp),%eax
  106a2a:	89 c2                	mov    %eax,%edx
  106a2c:	83 ca 27             	or     $0x27,%edx
  106a2f:	8b 45 c8             	mov    0xffffffc8(%ebp),%eax
  106a32:	89 10                	mov    %edx,(%eax)
  106a34:	8b 45 c4             	mov    0xffffffc4(%ebp),%eax
  106a37:	c1 e8 0c             	shr    $0xc,%eax
  106a3a:	25 ff 03 00 00       	and    $0x3ff,%eax
  106a3f:	c1 e0 02             	shl    $0x2,%eax
  106a42:	8b 55 cc             	mov    0xffffffcc(%ebp),%edx
  106a45:	01 c2                	add    %eax,%edx
  106a47:	89 55 bc             	mov    %edx,0xffffffbc(%ebp)
  106a4a:	8b 45 bc             	mov    0xffffffbc(%ebp),%eax
  106a4d:	c9                   	leave  
  106a4e:	c3                   	ret    

00106a4f <pmap_insert>:
  106a4f:	55                   	push   %ebp
  106a50:	89 e5                	mov    %esp,%ebp
  106a52:	83 ec 28             	sub    $0x28,%esp
  106a55:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
  106a5c:	00 
  106a5d:	8b 45 10             	mov    0x10(%ebp),%eax
  106a60:	89 44 24 04          	mov    %eax,0x4(%esp)
  106a64:	8b 45 08             	mov    0x8(%ebp),%eax
  106a67:	89 04 24             	mov    %eax,(%esp)
  106a6a:	e8 28 f9 ff ff       	call   106397 <pmap_walk>
  106a6f:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  106a72:	83 7d f8 00          	cmpl   $0x0,0xfffffff8(%ebp)
  106a76:	75 0c                	jne    106a84 <pmap_insert+0x35>
  106a78:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  106a7f:	e9 44 01 00 00       	jmp    106bc8 <pmap_insert+0x179>
  106a84:	8b 45 0c             	mov    0xc(%ebp),%eax
  106a87:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  106a8a:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  106a8f:	83 c0 08             	add    $0x8,%eax
  106a92:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  106a95:	73 17                	jae    106aae <pmap_insert+0x5f>
  106a97:	a1 d8 1d 18 00       	mov    0x181dd8,%eax
  106a9c:	c1 e0 03             	shl    $0x3,%eax
  106a9f:	89 c2                	mov    %eax,%edx
  106aa1:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  106aa6:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106aa9:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  106aac:	77 24                	ja     106ad2 <pmap_insert+0x83>
  106aae:	c7 44 24 0c 20 d3 10 	movl   $0x10d320,0xc(%esp)
  106ab5:	00 
  106ab6:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  106abd:	00 
  106abe:	c7 44 24 04 9c 00 00 	movl   $0x9c,0x4(%esp)
  106ac5:	00 
  106ac6:	c7 04 24 57 d3 10 00 	movl   $0x10d357,(%esp)
  106acd:	e8 66 9e ff ff       	call   100938 <debug_panic>
  106ad2:	8b 15 e0 1d 18 00    	mov    0x181de0,%edx
  106ad8:	b8 00 40 18 00       	mov    $0x184000,%eax
  106add:	c1 e8 0c             	shr    $0xc,%eax
  106ae0:	c1 e0 03             	shl    $0x3,%eax
  106ae3:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106ae6:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  106ae9:	75 24                	jne    106b0f <pmap_insert+0xc0>
  106aeb:	c7 44 24 0c 65 d3 10 	movl   $0x10d365,0xc(%esp)
  106af2:	00 
  106af3:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  106afa:	00 
  106afb:	c7 44 24 04 9e 00 00 	movl   $0x9e,0x4(%esp)
  106b02:	00 
  106b03:	c7 04 24 57 d3 10 00 	movl   $0x10d357,(%esp)
  106b0a:	e8 29 9e ff ff       	call   100938 <debug_panic>
  106b0f:	8b 15 e0 1d 18 00    	mov    0x181de0,%edx
  106b15:	b8 0c 00 10 00       	mov    $0x10000c,%eax
  106b1a:	c1 e8 0c             	shr    $0xc,%eax
  106b1d:	c1 e0 03             	shl    $0x3,%eax
  106b20:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106b23:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  106b26:	77 40                	ja     106b68 <pmap_insert+0x119>
  106b28:	8b 15 e0 1d 18 00    	mov    0x181de0,%edx
  106b2e:	b8 08 50 18 00       	mov    $0x185008,%eax
  106b33:	83 e8 01             	sub    $0x1,%eax
  106b36:	c1 e8 0c             	shr    $0xc,%eax
  106b39:	c1 e0 03             	shl    $0x3,%eax
  106b3c:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106b3f:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  106b42:	72 24                	jb     106b68 <pmap_insert+0x119>
  106b44:	c7 44 24 0c 84 d3 10 	movl   $0x10d384,0xc(%esp)
  106b4b:	00 
  106b4c:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  106b53:	00 
  106b54:	c7 44 24 04 a0 00 00 	movl   $0xa0,0x4(%esp)
  106b5b:	00 
  106b5c:	c7 04 24 57 d3 10 00 	movl   $0x10d357,(%esp)
  106b63:	e8 d0 9d ff ff       	call   100938 <debug_panic>
  106b68:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  106b6b:	83 c0 04             	add    $0x4,%eax
  106b6e:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  106b75:	00 
  106b76:	89 04 24             	mov    %eax,(%esp)
  106b79:	e8 00 f6 ff ff       	call   10617e <lockadd>
  106b7e:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  106b81:	8b 00                	mov    (%eax),%eax
  106b83:	83 e0 01             	and    $0x1,%eax
  106b86:	84 c0                	test   %al,%al
  106b88:	74 1a                	je     106ba4 <pmap_insert+0x155>
  106b8a:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  106b91:	00 
  106b92:	8b 45 10             	mov    0x10(%ebp),%eax
  106b95:	89 44 24 04          	mov    %eax,0x4(%esp)
  106b99:	8b 45 08             	mov    0x8(%ebp),%eax
  106b9c:	89 04 24             	mov    %eax,(%esp)
  106b9f:	e8 29 00 00 00       	call   106bcd <pmap_remove>
  106ba4:	8b 55 0c             	mov    0xc(%ebp),%edx
  106ba7:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  106bac:	89 d1                	mov    %edx,%ecx
  106bae:	29 c1                	sub    %eax,%ecx
  106bb0:	89 c8                	mov    %ecx,%eax
  106bb2:	c1 e0 09             	shl    $0x9,%eax
  106bb5:	0b 45 14             	or     0x14(%ebp),%eax
  106bb8:	83 c8 01             	or     $0x1,%eax
  106bbb:	89 c2                	mov    %eax,%edx
  106bbd:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  106bc0:	89 10                	mov    %edx,(%eax)
  106bc2:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  106bc5:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  106bc8:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  106bcb:	c9                   	leave  
  106bcc:	c3                   	ret    

00106bcd <pmap_remove>:
  106bcd:	55                   	push   %ebp
  106bce:	89 e5                	mov    %esp,%ebp
  106bd0:	83 ec 48             	sub    $0x48,%esp
  106bd3:	8b 45 10             	mov    0x10(%ebp),%eax
  106bd6:	25 ff 0f 00 00       	and    $0xfff,%eax
  106bdb:	85 c0                	test   %eax,%eax
  106bdd:	74 24                	je     106c03 <pmap_remove+0x36>
  106bdf:	c7 44 24 0c 1b d4 10 	movl   $0x10d41b,0xc(%esp)
  106be6:	00 
  106be7:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  106bee:	00 
  106bef:	c7 44 24 04 3a 01 00 	movl   $0x13a,0x4(%esp)
  106bf6:	00 
  106bf7:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  106bfe:	e8 35 9d ff ff       	call   100938 <debug_panic>
  106c03:	81 7d 0c ff ff ff 3f 	cmpl   $0x3fffffff,0xc(%ebp)
  106c0a:	76 09                	jbe    106c15 <pmap_remove+0x48>
  106c0c:	81 7d 0c ff ff ff ef 	cmpl   $0xefffffff,0xc(%ebp)
  106c13:	76 24                	jbe    106c39 <pmap_remove+0x6c>
  106c15:	c7 44 24 0c c8 d3 10 	movl   $0x10d3c8,0xc(%esp)
  106c1c:	00 
  106c1d:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  106c24:	00 
  106c25:	c7 44 24 04 3b 01 00 	movl   $0x13b,0x4(%esp)
  106c2c:	00 
  106c2d:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  106c34:	e8 ff 9c ff ff       	call   100938 <debug_panic>
  106c39:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
  106c3e:	2b 45 0c             	sub    0xc(%ebp),%eax
  106c41:	3b 45 10             	cmp    0x10(%ebp),%eax
  106c44:	73 24                	jae    106c6a <pmap_remove+0x9d>
  106c46:	c7 44 24 0c 2c d4 10 	movl   $0x10d42c,0xc(%esp)
  106c4d:	00 
  106c4e:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  106c55:	00 
  106c56:	c7 44 24 04 3c 01 00 	movl   $0x13c,0x4(%esp)
  106c5d:	00 
  106c5e:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  106c65:	e8 ce 9c ff ff       	call   100938 <debug_panic>
  106c6a:	8b 45 10             	mov    0x10(%ebp),%eax
  106c6d:	89 44 24 08          	mov    %eax,0x8(%esp)
  106c71:	8b 45 0c             	mov    0xc(%ebp),%eax
  106c74:	89 44 24 04          	mov    %eax,0x4(%esp)
  106c78:	8b 45 08             	mov    0x8(%ebp),%eax
  106c7b:	89 04 24             	mov    %eax,(%esp)
  106c7e:	e8 e0 03 00 00       	call   107063 <pmap_inval>
  106c83:	8b 45 10             	mov    0x10(%ebp),%eax
  106c86:	03 45 0c             	add    0xc(%ebp),%eax
  106c89:	89 45 dc             	mov    %eax,0xffffffdc(%ebp)
  106c8c:	e9 c4 03 00 00       	jmp    107055 <pmap_remove+0x488>
  106c91:	8b 45 0c             	mov    0xc(%ebp),%eax
  106c94:	c1 e8 16             	shr    $0x16,%eax
  106c97:	25 ff 03 00 00       	and    $0x3ff,%eax
  106c9c:	c1 e0 02             	shl    $0x2,%eax
  106c9f:	03 45 08             	add    0x8(%ebp),%eax
  106ca2:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)
  106ca5:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  106ca8:	8b 10                	mov    (%eax),%edx
  106caa:	b8 00 40 18 00       	mov    $0x184000,%eax
  106caf:	39 c2                	cmp    %eax,%edx
  106cb1:	75 15                	jne    106cc8 <pmap_remove+0xfb>
  106cb3:	8b 45 0c             	mov    0xc(%ebp),%eax
  106cb6:	05 00 00 40 00       	add    $0x400000,%eax
  106cbb:	25 00 00 c0 ff       	and    $0xffc00000,%eax
  106cc0:	89 45 0c             	mov    %eax,0xc(%ebp)
  106cc3:	e9 8d 03 00 00       	jmp    107055 <pmap_remove+0x488>
  106cc8:	8b 45 0c             	mov    0xc(%ebp),%eax
  106ccb:	c1 e8 0c             	shr    $0xc,%eax
  106cce:	25 ff 03 00 00       	and    $0x3ff,%eax
  106cd3:	85 c0                	test   %eax,%eax
  106cd5:	0f 85 98 01 00 00    	jne    106e73 <pmap_remove+0x2a6>
  106cdb:	8b 45 0c             	mov    0xc(%ebp),%eax
  106cde:	8b 55 dc             	mov    0xffffffdc(%ebp),%edx
  106ce1:	89 d1                	mov    %edx,%ecx
  106ce3:	29 c1                	sub    %eax,%ecx
  106ce5:	89 c8                	mov    %ecx,%eax
  106ce7:	3d ff ff 3f 00       	cmp    $0x3fffff,%eax
  106cec:	0f 86 81 01 00 00    	jbe    106e73 <pmap_remove+0x2a6>
  106cf2:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  106cf5:	8b 00                	mov    (%eax),%eax
  106cf7:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  106cfc:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  106cff:	b8 00 40 18 00       	mov    $0x184000,%eax
  106d04:	39 45 e8             	cmp    %eax,0xffffffe8(%ebp)
  106d07:	0f 84 4e 01 00 00    	je     106e5b <pmap_remove+0x28e>
  106d0d:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  106d10:	c1 e8 0c             	shr    $0xc,%eax
  106d13:	c1 e0 03             	shl    $0x3,%eax
  106d16:	89 c2                	mov    %eax,%edx
  106d18:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  106d1d:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106d20:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
  106d23:	c7 45 f0 cb 61 10 00 	movl   $0x1061cb,0xfffffff0(%ebp)
  106d2a:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  106d2f:	83 c0 08             	add    $0x8,%eax
  106d32:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  106d35:	73 17                	jae    106d4e <pmap_remove+0x181>
  106d37:	a1 d8 1d 18 00       	mov    0x181dd8,%eax
  106d3c:	c1 e0 03             	shl    $0x3,%eax
  106d3f:	89 c2                	mov    %eax,%edx
  106d41:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  106d46:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106d49:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  106d4c:	77 24                	ja     106d72 <pmap_remove+0x1a5>
  106d4e:	c7 44 24 0c 20 d3 10 	movl   $0x10d320,0xc(%esp)
  106d55:	00 
  106d56:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  106d5d:	00 
  106d5e:	c7 44 24 04 aa 00 00 	movl   $0xaa,0x4(%esp)
  106d65:	00 
  106d66:	c7 04 24 57 d3 10 00 	movl   $0x10d357,(%esp)
  106d6d:	e8 c6 9b ff ff       	call   100938 <debug_panic>
  106d72:	8b 15 e0 1d 18 00    	mov    0x181de0,%edx
  106d78:	b8 00 40 18 00       	mov    $0x184000,%eax
  106d7d:	c1 e8 0c             	shr    $0xc,%eax
  106d80:	c1 e0 03             	shl    $0x3,%eax
  106d83:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106d86:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  106d89:	75 24                	jne    106daf <pmap_remove+0x1e2>
  106d8b:	c7 44 24 0c 65 d3 10 	movl   $0x10d365,0xc(%esp)
  106d92:	00 
  106d93:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  106d9a:	00 
  106d9b:	c7 44 24 04 ac 00 00 	movl   $0xac,0x4(%esp)
  106da2:	00 
  106da3:	c7 04 24 57 d3 10 00 	movl   $0x10d357,(%esp)
  106daa:	e8 89 9b ff ff       	call   100938 <debug_panic>
  106daf:	8b 15 e0 1d 18 00    	mov    0x181de0,%edx
  106db5:	b8 0c 00 10 00       	mov    $0x10000c,%eax
  106dba:	c1 e8 0c             	shr    $0xc,%eax
  106dbd:	c1 e0 03             	shl    $0x3,%eax
  106dc0:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106dc3:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  106dc6:	77 40                	ja     106e08 <pmap_remove+0x23b>
  106dc8:	8b 15 e0 1d 18 00    	mov    0x181de0,%edx
  106dce:	b8 08 50 18 00       	mov    $0x185008,%eax
  106dd3:	83 e8 01             	sub    $0x1,%eax
  106dd6:	c1 e8 0c             	shr    $0xc,%eax
  106dd9:	c1 e0 03             	shl    $0x3,%eax
  106ddc:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106ddf:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  106de2:	72 24                	jb     106e08 <pmap_remove+0x23b>
  106de4:	c7 44 24 0c 84 d3 10 	movl   $0x10d384,0xc(%esp)
  106deb:	00 
  106dec:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  106df3:	00 
  106df4:	c7 44 24 04 ae 00 00 	movl   $0xae,0x4(%esp)
  106dfb:	00 
  106dfc:	c7 04 24 57 d3 10 00 	movl   $0x10d357,(%esp)
  106e03:	e8 30 9b ff ff       	call   100938 <debug_panic>
  106e08:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  106e0b:	83 c0 04             	add    $0x4,%eax
  106e0e:	c7 44 24 04 ff ff ff 	movl   $0xffffffff,0x4(%esp)
  106e15:	ff 
  106e16:	89 04 24             	mov    %eax,(%esp)
  106e19:	e8 5d f5 ff ff       	call   10637b <lockaddz>
  106e1e:	84 c0                	test   %al,%al
  106e20:	74 0b                	je     106e2d <pmap_remove+0x260>
  106e22:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  106e25:	89 04 24             	mov    %eax,(%esp)
  106e28:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  106e2b:	ff d0                	call   *%eax
  106e2d:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  106e30:	8b 40 04             	mov    0x4(%eax),%eax
  106e33:	85 c0                	test   %eax,%eax
  106e35:	79 24                	jns    106e5b <pmap_remove+0x28e>
  106e37:	c7 44 24 0c b5 d3 10 	movl   $0x10d3b5,0xc(%esp)
  106e3e:	00 
  106e3f:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  106e46:	00 
  106e47:	c7 44 24 04 b5 00 00 	movl   $0xb5,0x4(%esp)
  106e4e:	00 
  106e4f:	c7 04 24 57 d3 10 00 	movl   $0x10d357,(%esp)
  106e56:	e8 dd 9a ff ff       	call   100938 <debug_panic>
  106e5b:	b8 00 40 18 00       	mov    $0x184000,%eax
  106e60:	89 c2                	mov    %eax,%edx
  106e62:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  106e65:	89 10                	mov    %edx,(%eax)
  106e67:	81 45 0c 00 00 40 00 	addl   $0x400000,0xc(%ebp)
  106e6e:	e9 e2 01 00 00       	jmp    107055 <pmap_remove+0x488>
  106e73:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
  106e7a:	00 
  106e7b:	8b 45 0c             	mov    0xc(%ebp),%eax
  106e7e:	89 44 24 04          	mov    %eax,0x4(%esp)
  106e82:	8b 45 08             	mov    0x8(%ebp),%eax
  106e85:	89 04 24             	mov    %eax,(%esp)
  106e88:	e8 0a f5 ff ff       	call   106397 <pmap_walk>
  106e8d:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
  106e90:	83 7d e4 00          	cmpl   $0x0,0xffffffe4(%ebp)
  106e94:	75 24                	jne    106eba <pmap_remove+0x2ed>
  106e96:	c7 44 24 0c 43 d4 10 	movl   $0x10d443,0xc(%esp)
  106e9d:	00 
  106e9e:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  106ea5:	00 
  106ea6:	c7 44 24 04 55 01 00 	movl   $0x155,0x4(%esp)
  106ead:	00 
  106eae:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  106eb5:	e8 7e 9a ff ff       	call   100938 <debug_panic>
  106eba:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  106ebd:	8b 00                	mov    (%eax),%eax
  106ebf:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  106ec4:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  106ec7:	b8 00 40 18 00       	mov    $0x184000,%eax
  106ecc:	39 45 ec             	cmp    %eax,0xffffffec(%ebp)
  106ecf:	0f 84 4e 01 00 00    	je     107023 <pmap_remove+0x456>
  106ed5:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  106ed8:	c1 e8 0c             	shr    $0xc,%eax
  106edb:	c1 e0 03             	shl    $0x3,%eax
  106ede:	89 c2                	mov    %eax,%edx
  106ee0:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  106ee5:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106ee8:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  106eeb:	c7 45 f8 a9 14 10 00 	movl   $0x1014a9,0xfffffff8(%ebp)
  106ef2:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  106ef7:	83 c0 08             	add    $0x8,%eax
  106efa:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  106efd:	73 17                	jae    106f16 <pmap_remove+0x349>
  106eff:	a1 d8 1d 18 00       	mov    0x181dd8,%eax
  106f04:	c1 e0 03             	shl    $0x3,%eax
  106f07:	89 c2                	mov    %eax,%edx
  106f09:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  106f0e:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106f11:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  106f14:	77 24                	ja     106f3a <pmap_remove+0x36d>
  106f16:	c7 44 24 0c 20 d3 10 	movl   $0x10d320,0xc(%esp)
  106f1d:	00 
  106f1e:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  106f25:	00 
  106f26:	c7 44 24 04 aa 00 00 	movl   $0xaa,0x4(%esp)
  106f2d:	00 
  106f2e:	c7 04 24 57 d3 10 00 	movl   $0x10d357,(%esp)
  106f35:	e8 fe 99 ff ff       	call   100938 <debug_panic>
  106f3a:	8b 15 e0 1d 18 00    	mov    0x181de0,%edx
  106f40:	b8 00 40 18 00       	mov    $0x184000,%eax
  106f45:	c1 e8 0c             	shr    $0xc,%eax
  106f48:	c1 e0 03             	shl    $0x3,%eax
  106f4b:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106f4e:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  106f51:	75 24                	jne    106f77 <pmap_remove+0x3aa>
  106f53:	c7 44 24 0c 65 d3 10 	movl   $0x10d365,0xc(%esp)
  106f5a:	00 
  106f5b:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  106f62:	00 
  106f63:	c7 44 24 04 ac 00 00 	movl   $0xac,0x4(%esp)
  106f6a:	00 
  106f6b:	c7 04 24 57 d3 10 00 	movl   $0x10d357,(%esp)
  106f72:	e8 c1 99 ff ff       	call   100938 <debug_panic>
  106f77:	8b 15 e0 1d 18 00    	mov    0x181de0,%edx
  106f7d:	b8 0c 00 10 00       	mov    $0x10000c,%eax
  106f82:	c1 e8 0c             	shr    $0xc,%eax
  106f85:	c1 e0 03             	shl    $0x3,%eax
  106f88:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106f8b:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  106f8e:	77 40                	ja     106fd0 <pmap_remove+0x403>
  106f90:	8b 15 e0 1d 18 00    	mov    0x181de0,%edx
  106f96:	b8 08 50 18 00       	mov    $0x185008,%eax
  106f9b:	83 e8 01             	sub    $0x1,%eax
  106f9e:	c1 e8 0c             	shr    $0xc,%eax
  106fa1:	c1 e0 03             	shl    $0x3,%eax
  106fa4:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106fa7:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  106faa:	72 24                	jb     106fd0 <pmap_remove+0x403>
  106fac:	c7 44 24 0c 84 d3 10 	movl   $0x10d384,0xc(%esp)
  106fb3:	00 
  106fb4:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  106fbb:	00 
  106fbc:	c7 44 24 04 ae 00 00 	movl   $0xae,0x4(%esp)
  106fc3:	00 
  106fc4:	c7 04 24 57 d3 10 00 	movl   $0x10d357,(%esp)
  106fcb:	e8 68 99 ff ff       	call   100938 <debug_panic>
  106fd0:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  106fd3:	83 c0 04             	add    $0x4,%eax
  106fd6:	c7 44 24 04 ff ff ff 	movl   $0xffffffff,0x4(%esp)
  106fdd:	ff 
  106fde:	89 04 24             	mov    %eax,(%esp)
  106fe1:	e8 95 f3 ff ff       	call   10637b <lockaddz>
  106fe6:	84 c0                	test   %al,%al
  106fe8:	74 0b                	je     106ff5 <pmap_remove+0x428>
  106fea:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  106fed:	89 04 24             	mov    %eax,(%esp)
  106ff0:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  106ff3:	ff d0                	call   *%eax
  106ff5:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  106ff8:	8b 40 04             	mov    0x4(%eax),%eax
  106ffb:	85 c0                	test   %eax,%eax
  106ffd:	79 24                	jns    107023 <pmap_remove+0x456>
  106fff:	c7 44 24 0c b5 d3 10 	movl   $0x10d3b5,0xc(%esp)
  107006:	00 
  107007:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  10700e:	00 
  10700f:	c7 44 24 04 b5 00 00 	movl   $0xb5,0x4(%esp)
  107016:	00 
  107017:	c7 04 24 57 d3 10 00 	movl   $0x10d357,(%esp)
  10701e:	e8 15 99 ff ff       	call   100938 <debug_panic>
  107023:	b8 00 40 18 00       	mov    $0x184000,%eax
  107028:	89 c2                	mov    %eax,%edx
  10702a:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  10702d:	89 10                	mov    %edx,(%eax)
  10702f:	83 45 e4 04          	addl   $0x4,0xffffffe4(%ebp)
  107033:	81 45 0c 00 10 00 00 	addl   $0x1000,0xc(%ebp)
  10703a:	8b 45 0c             	mov    0xc(%ebp),%eax
  10703d:	3b 45 dc             	cmp    0xffffffdc(%ebp),%eax
  107040:	73 13                	jae    107055 <pmap_remove+0x488>
  107042:	8b 45 0c             	mov    0xc(%ebp),%eax
  107045:	c1 e8 0c             	shr    $0xc,%eax
  107048:	25 ff 03 00 00       	and    $0x3ff,%eax
  10704d:	85 c0                	test   %eax,%eax
  10704f:	0f 85 65 fe ff ff    	jne    106eba <pmap_remove+0x2ed>
  107055:	8b 45 0c             	mov    0xc(%ebp),%eax
  107058:	3b 45 dc             	cmp    0xffffffdc(%ebp),%eax
  10705b:	0f 82 30 fc ff ff    	jb     106c91 <pmap_remove+0xc4>
  107061:	c9                   	leave  
  107062:	c3                   	ret    

00107063 <pmap_inval>:
  107063:	55                   	push   %ebp
  107064:	89 e5                	mov    %esp,%ebp
  107066:	83 ec 18             	sub    $0x18,%esp
  107069:	e8 69 ef ff ff       	call   105fd7 <cpu_cur>
  10706e:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  107074:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
  107077:	83 7d f4 00          	cmpl   $0x0,0xfffffff4(%ebp)
  10707b:	74 0e                	je     10708b <pmap_inval+0x28>
  10707d:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  107080:	8b 80 a0 06 00 00    	mov    0x6a0(%eax),%eax
  107086:	3b 45 08             	cmp    0x8(%ebp),%eax
  107089:	75 23                	jne    1070ae <pmap_inval+0x4b>
  10708b:	81 7d 10 00 10 00 00 	cmpl   $0x1000,0x10(%ebp)
  107092:	75 0e                	jne    1070a2 <pmap_inval+0x3f>
  107094:	8b 45 0c             	mov    0xc(%ebp),%eax
  107097:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  10709a:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10709d:	0f 01 38             	invlpg (%eax)
  1070a0:	eb 0c                	jmp    1070ae <pmap_inval+0x4b>
  1070a2:	8b 45 08             	mov    0x8(%ebp),%eax
  1070a5:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  1070a8:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  1070ab:	0f 22 d8             	mov    %eax,%cr3
  1070ae:	c9                   	leave  
  1070af:	c3                   	ret    

001070b0 <pmap_copy>:
  1070b0:	55                   	push   %ebp
  1070b1:	89 e5                	mov    %esp,%ebp
  1070b3:	83 ec 28             	sub    $0x28,%esp
  1070b6:	8b 45 0c             	mov    0xc(%ebp),%eax
  1070b9:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  1070be:	85 c0                	test   %eax,%eax
  1070c0:	74 24                	je     1070e6 <pmap_copy+0x36>
  1070c2:	c7 44 24 0c 4f d4 10 	movl   $0x10d44f,0xc(%esp)
  1070c9:	00 
  1070ca:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  1070d1:	00 
  1070d2:	c7 44 24 04 81 01 00 	movl   $0x181,0x4(%esp)
  1070d9:	00 
  1070da:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  1070e1:	e8 52 98 ff ff       	call   100938 <debug_panic>
  1070e6:	8b 45 14             	mov    0x14(%ebp),%eax
  1070e9:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  1070ee:	85 c0                	test   %eax,%eax
  1070f0:	74 24                	je     107116 <pmap_copy+0x66>
  1070f2:	c7 44 24 0c 5f d4 10 	movl   $0x10d45f,0xc(%esp)
  1070f9:	00 
  1070fa:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  107101:	00 
  107102:	c7 44 24 04 82 01 00 	movl   $0x182,0x4(%esp)
  107109:	00 
  10710a:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  107111:	e8 22 98 ff ff       	call   100938 <debug_panic>
  107116:	8b 45 18             	mov    0x18(%ebp),%eax
  107119:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  10711e:	85 c0                	test   %eax,%eax
  107120:	74 24                	je     107146 <pmap_copy+0x96>
  107122:	c7 44 24 0c 6f d4 10 	movl   $0x10d46f,0xc(%esp)
  107129:	00 
  10712a:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  107131:	00 
  107132:	c7 44 24 04 83 01 00 	movl   $0x183,0x4(%esp)
  107139:	00 
  10713a:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  107141:	e8 f2 97 ff ff       	call   100938 <debug_panic>
  107146:	81 7d 0c ff ff ff 3f 	cmpl   $0x3fffffff,0xc(%ebp)
  10714d:	76 09                	jbe    107158 <pmap_copy+0xa8>
  10714f:	81 7d 0c ff ff ff ef 	cmpl   $0xefffffff,0xc(%ebp)
  107156:	76 24                	jbe    10717c <pmap_copy+0xcc>
  107158:	c7 44 24 0c 80 d4 10 	movl   $0x10d480,0xc(%esp)
  10715f:	00 
  107160:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  107167:	00 
  107168:	c7 44 24 04 84 01 00 	movl   $0x184,0x4(%esp)
  10716f:	00 
  107170:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  107177:	e8 bc 97 ff ff       	call   100938 <debug_panic>
  10717c:	81 7d 14 ff ff ff 3f 	cmpl   $0x3fffffff,0x14(%ebp)
  107183:	76 09                	jbe    10718e <pmap_copy+0xde>
  107185:	81 7d 14 ff ff ff ef 	cmpl   $0xefffffff,0x14(%ebp)
  10718c:	76 24                	jbe    1071b2 <pmap_copy+0x102>
  10718e:	c7 44 24 0c a4 d4 10 	movl   $0x10d4a4,0xc(%esp)
  107195:	00 
  107196:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  10719d:	00 
  10719e:	c7 44 24 04 85 01 00 	movl   $0x185,0x4(%esp)
  1071a5:	00 
  1071a6:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  1071ad:	e8 86 97 ff ff       	call   100938 <debug_panic>
  1071b2:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
  1071b7:	2b 45 0c             	sub    0xc(%ebp),%eax
  1071ba:	3b 45 18             	cmp    0x18(%ebp),%eax
  1071bd:	73 24                	jae    1071e3 <pmap_copy+0x133>
  1071bf:	c7 44 24 0c c8 d4 10 	movl   $0x10d4c8,0xc(%esp)
  1071c6:	00 
  1071c7:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  1071ce:	00 
  1071cf:	c7 44 24 04 86 01 00 	movl   $0x186,0x4(%esp)
  1071d6:	00 
  1071d7:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  1071de:	e8 55 97 ff ff       	call   100938 <debug_panic>
  1071e3:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
  1071e8:	2b 45 14             	sub    0x14(%ebp),%eax
  1071eb:	3b 45 18             	cmp    0x18(%ebp),%eax
  1071ee:	73 24                	jae    107214 <pmap_copy+0x164>
  1071f0:	c7 44 24 0c e0 d4 10 	movl   $0x10d4e0,0xc(%esp)
  1071f7:	00 
  1071f8:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  1071ff:	00 
  107200:	c7 44 24 04 87 01 00 	movl   $0x187,0x4(%esp)
  107207:	00 
  107208:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  10720f:	e8 24 97 ff ff       	call   100938 <debug_panic>
  107214:	8b 45 18             	mov    0x18(%ebp),%eax
  107217:	89 44 24 08          	mov    %eax,0x8(%esp)
  10721b:	8b 45 0c             	mov    0xc(%ebp),%eax
  10721e:	89 44 24 04          	mov    %eax,0x4(%esp)
  107222:	8b 45 08             	mov    0x8(%ebp),%eax
  107225:	89 04 24             	mov    %eax,(%esp)
  107228:	e8 36 fe ff ff       	call   107063 <pmap_inval>
  10722d:	8b 45 18             	mov    0x18(%ebp),%eax
  107230:	89 44 24 08          	mov    %eax,0x8(%esp)
  107234:	8b 45 14             	mov    0x14(%ebp),%eax
  107237:	89 44 24 04          	mov    %eax,0x4(%esp)
  10723b:	8b 45 10             	mov    0x10(%ebp),%eax
  10723e:	89 04 24             	mov    %eax,(%esp)
  107241:	e8 1d fe ff ff       	call   107063 <pmap_inval>
  107246:	8b 45 18             	mov    0x18(%ebp),%eax
  107249:	03 45 0c             	add    0xc(%ebp),%eax
  10724c:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
  10724f:	8b 45 0c             	mov    0xc(%ebp),%eax
  107252:	c1 e8 16             	shr    $0x16,%eax
  107255:	25 ff 03 00 00       	and    $0x3ff,%eax
  10725a:	c1 e0 02             	shl    $0x2,%eax
  10725d:	03 45 08             	add    0x8(%ebp),%eax
  107260:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
  107263:	8b 45 14             	mov    0x14(%ebp),%eax
  107266:	c1 e8 16             	shr    $0x16,%eax
  107269:	25 ff 03 00 00       	and    $0x3ff,%eax
  10726e:	c1 e0 02             	shl    $0x2,%eax
  107271:	03 45 10             	add    0x10(%ebp),%eax
  107274:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  107277:	e9 aa 01 00 00       	jmp    107426 <pmap_copy+0x376>
  10727c:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10727f:	8b 00                	mov    (%eax),%eax
  107281:	83 e0 01             	and    $0x1,%eax
  107284:	84 c0                	test   %al,%al
  107286:	74 1a                	je     1072a2 <pmap_copy+0x1f2>
  107288:	c7 44 24 08 00 00 40 	movl   $0x400000,0x8(%esp)
  10728f:	00 
  107290:	8b 45 14             	mov    0x14(%ebp),%eax
  107293:	89 44 24 04          	mov    %eax,0x4(%esp)
  107297:	8b 45 10             	mov    0x10(%ebp),%eax
  10729a:	89 04 24             	mov    %eax,(%esp)
  10729d:	e8 2b f9 ff ff       	call   106bcd <pmap_remove>
  1072a2:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1072a5:	8b 10                	mov    (%eax),%edx
  1072a7:	b8 00 40 18 00       	mov    $0x184000,%eax
  1072ac:	39 c2                	cmp    %eax,%edx
  1072ae:	74 24                	je     1072d4 <pmap_copy+0x224>
  1072b0:	c7 44 24 0c f8 d4 10 	movl   $0x10d4f8,0xc(%esp)
  1072b7:	00 
  1072b8:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  1072bf:	00 
  1072c0:	c7 44 24 04 95 01 00 	movl   $0x195,0x4(%esp)
  1072c7:	00 
  1072c8:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  1072cf:	e8 64 96 ff ff       	call   100938 <debug_panic>
  1072d4:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  1072d7:	8b 00                	mov    (%eax),%eax
  1072d9:	89 c2                	mov    %eax,%edx
  1072db:	83 e2 fd             	and    $0xfffffffd,%edx
  1072de:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  1072e1:	89 10                	mov    %edx,(%eax)
  1072e3:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  1072e6:	8b 10                	mov    (%eax),%edx
  1072e8:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1072eb:	89 10                	mov    %edx,(%eax)
  1072ed:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  1072f0:	8b 10                	mov    (%eax),%edx
  1072f2:	b8 00 40 18 00       	mov    $0x184000,%eax
  1072f7:	39 c2                	cmp    %eax,%edx
  1072f9:	0f 84 11 01 00 00    	je     107410 <pmap_copy+0x360>
  1072ff:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  107302:	8b 00                	mov    (%eax),%eax
  107304:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  107309:	c1 e8 0c             	shr    $0xc,%eax
  10730c:	c1 e0 03             	shl    $0x3,%eax
  10730f:	89 c2                	mov    %eax,%edx
  107311:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  107316:	8d 04 02             	lea    (%edx,%eax,1),%eax
  107319:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  10731c:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  107321:	83 c0 08             	add    $0x8,%eax
  107324:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  107327:	73 17                	jae    107340 <pmap_copy+0x290>
  107329:	a1 d8 1d 18 00       	mov    0x181dd8,%eax
  10732e:	c1 e0 03             	shl    $0x3,%eax
  107331:	89 c2                	mov    %eax,%edx
  107333:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  107338:	8d 04 02             	lea    (%edx,%eax,1),%eax
  10733b:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  10733e:	77 24                	ja     107364 <pmap_copy+0x2b4>
  107340:	c7 44 24 0c 20 d3 10 	movl   $0x10d320,0xc(%esp)
  107347:	00 
  107348:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  10734f:	00 
  107350:	c7 44 24 04 9c 00 00 	movl   $0x9c,0x4(%esp)
  107357:	00 
  107358:	c7 04 24 57 d3 10 00 	movl   $0x10d357,(%esp)
  10735f:	e8 d4 95 ff ff       	call   100938 <debug_panic>
  107364:	8b 15 e0 1d 18 00    	mov    0x181de0,%edx
  10736a:	b8 00 40 18 00       	mov    $0x184000,%eax
  10736f:	c1 e8 0c             	shr    $0xc,%eax
  107372:	c1 e0 03             	shl    $0x3,%eax
  107375:	8d 04 02             	lea    (%edx,%eax,1),%eax
  107378:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  10737b:	75 24                	jne    1073a1 <pmap_copy+0x2f1>
  10737d:	c7 44 24 0c 65 d3 10 	movl   $0x10d365,0xc(%esp)
  107384:	00 
  107385:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  10738c:	00 
  10738d:	c7 44 24 04 9e 00 00 	movl   $0x9e,0x4(%esp)
  107394:	00 
  107395:	c7 04 24 57 d3 10 00 	movl   $0x10d357,(%esp)
  10739c:	e8 97 95 ff ff       	call   100938 <debug_panic>
  1073a1:	8b 15 e0 1d 18 00    	mov    0x181de0,%edx
  1073a7:	b8 0c 00 10 00       	mov    $0x10000c,%eax
  1073ac:	c1 e8 0c             	shr    $0xc,%eax
  1073af:	c1 e0 03             	shl    $0x3,%eax
  1073b2:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1073b5:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  1073b8:	77 40                	ja     1073fa <pmap_copy+0x34a>
  1073ba:	8b 15 e0 1d 18 00    	mov    0x181de0,%edx
  1073c0:	b8 08 50 18 00       	mov    $0x185008,%eax
  1073c5:	83 e8 01             	sub    $0x1,%eax
  1073c8:	c1 e8 0c             	shr    $0xc,%eax
  1073cb:	c1 e0 03             	shl    $0x3,%eax
  1073ce:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1073d1:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  1073d4:	72 24                	jb     1073fa <pmap_copy+0x34a>
  1073d6:	c7 44 24 0c 84 d3 10 	movl   $0x10d384,0xc(%esp)
  1073dd:	00 
  1073de:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  1073e5:	00 
  1073e6:	c7 44 24 04 a0 00 00 	movl   $0xa0,0x4(%esp)
  1073ed:	00 
  1073ee:	c7 04 24 57 d3 10 00 	movl   $0x10d357,(%esp)
  1073f5:	e8 3e 95 ff ff       	call   100938 <debug_panic>
  1073fa:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  1073fd:	83 c0 04             	add    $0x4,%eax
  107400:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  107407:	00 
  107408:	89 04 24             	mov    %eax,(%esp)
  10740b:	e8 6e ed ff ff       	call   10617e <lockadd>
  107410:	83 45 f4 04          	addl   $0x4,0xfffffff4(%ebp)
  107414:	83 45 f8 04          	addl   $0x4,0xfffffff8(%ebp)
  107418:	81 45 0c 00 00 40 00 	addl   $0x400000,0xc(%ebp)
  10741f:	81 45 14 00 00 40 00 	addl   $0x400000,0x14(%ebp)
  107426:	8b 45 0c             	mov    0xc(%ebp),%eax
  107429:	3b 45 f0             	cmp    0xfffffff0(%ebp),%eax
  10742c:	0f 82 4a fe ff ff    	jb     10727c <pmap_copy+0x1cc>
  107432:	b8 01 00 00 00       	mov    $0x1,%eax
  107437:	c9                   	leave  
  107438:	c3                   	ret    

00107439 <pmap_pagefault>:
  107439:	55                   	push   %ebp
  10743a:	89 e5                	mov    %esp,%ebp
  10743c:	83 ec 48             	sub    $0x48,%esp
  10743f:	0f 20 d0             	mov    %cr2,%eax
  107442:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
  107445:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  107448:	89 45 d4             	mov    %eax,0xffffffd4(%ebp)
  10744b:	81 7d d4 ff ff ff 3f 	cmpl   $0x3fffffff,0xffffffd4(%ebp)
  107452:	76 16                	jbe    10746a <pmap_pagefault+0x31>
  107454:	81 7d d4 ff ff ff ef 	cmpl   $0xefffffff,0xffffffd4(%ebp)
  10745b:	77 0d                	ja     10746a <pmap_pagefault+0x31>
  10745d:	8b 45 08             	mov    0x8(%ebp),%eax
  107460:	8b 40 34             	mov    0x34(%eax),%eax
  107463:	83 e0 02             	and    $0x2,%eax
  107466:	85 c0                	test   %eax,%eax
  107468:	75 22                	jne    10748c <pmap_pagefault+0x53>
  10746a:	8b 45 08             	mov    0x8(%ebp),%eax
  10746d:	8b 40 34             	mov    0x34(%eax),%eax
  107470:	89 44 24 08          	mov    %eax,0x8(%esp)
  107474:	8b 45 d4             	mov    0xffffffd4(%ebp),%eax
  107477:	89 44 24 04          	mov    %eax,0x4(%esp)
  10747b:	c7 04 24 0c d5 10 00 	movl   $0x10d50c,(%esp)
  107482:	e8 e6 43 00 00       	call   10b86d <cprintf>
  107487:	e9 fc 03 00 00       	jmp    107888 <pmap_pagefault+0x44f>
  10748c:	e8 46 eb ff ff       	call   105fd7 <cpu_cur>
  107491:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  107497:	89 45 d8             	mov    %eax,0xffffffd8(%ebp)
  10749a:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  10749d:	8b 90 a0 06 00 00    	mov    0x6a0(%eax),%edx
  1074a3:	8b 45 d4             	mov    0xffffffd4(%ebp),%eax
  1074a6:	c1 e8 16             	shr    $0x16,%eax
  1074a9:	25 ff 03 00 00       	and    $0x3ff,%eax
  1074ae:	c1 e0 02             	shl    $0x2,%eax
  1074b1:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1074b4:	89 45 dc             	mov    %eax,0xffffffdc(%ebp)
  1074b7:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  1074ba:	8b 00                	mov    (%eax),%eax
  1074bc:	83 e0 01             	and    $0x1,%eax
  1074bf:	85 c0                	test   %eax,%eax
  1074c1:	75 18                	jne    1074db <pmap_pagefault+0xa2>
  1074c3:	8b 45 d4             	mov    0xffffffd4(%ebp),%eax
  1074c6:	89 44 24 04          	mov    %eax,0x4(%esp)
  1074ca:	c7 04 24 2c d5 10 00 	movl   $0x10d52c,(%esp)
  1074d1:	e8 97 43 00 00       	call   10b86d <cprintf>
  1074d6:	e9 ad 03 00 00       	jmp    107888 <pmap_pagefault+0x44f>
  1074db:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  1074de:	8b 90 a0 06 00 00    	mov    0x6a0(%eax),%edx
  1074e4:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
  1074eb:	00 
  1074ec:	8b 45 d4             	mov    0xffffffd4(%ebp),%eax
  1074ef:	89 44 24 04          	mov    %eax,0x4(%esp)
  1074f3:	89 14 24             	mov    %edx,(%esp)
  1074f6:	e8 9c ee ff ff       	call   106397 <pmap_walk>
  1074fb:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)
  1074fe:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  107501:	8b 00                	mov    (%eax),%eax
  107503:	25 01 06 00 00       	and    $0x601,%eax
  107508:	3d 01 06 00 00       	cmp    $0x601,%eax
  10750d:	74 18                	je     107527 <pmap_pagefault+0xee>
  10750f:	8b 45 d4             	mov    0xffffffd4(%ebp),%eax
  107512:	89 44 24 04          	mov    %eax,0x4(%esp)
  107516:	c7 04 24 5c d5 10 00 	movl   $0x10d55c,(%esp)
  10751d:	e8 4b 43 00 00       	call   10b86d <cprintf>
  107522:	e9 61 03 00 00       	jmp    107888 <pmap_pagefault+0x44f>
  107527:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  10752a:	8b 00                	mov    (%eax),%eax
  10752c:	83 e0 02             	and    $0x2,%eax
  10752f:	85 c0                	test   %eax,%eax
  107531:	74 24                	je     107557 <pmap_pagefault+0x11e>
  107533:	c7 44 24 0c 8b d5 10 	movl   $0x10d58b,0xc(%esp)
  10753a:	00 
  10753b:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  107542:	00 
  107543:	c7 44 24 04 ca 01 00 	movl   $0x1ca,0x4(%esp)
  10754a:	00 
  10754b:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  107552:	e8 e1 93 ff ff       	call   100938 <debug_panic>
  107557:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  10755a:	8b 00                	mov    (%eax),%eax
  10755c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  107561:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
  107564:	b8 00 40 18 00       	mov    $0x184000,%eax
  107569:	39 45 e4             	cmp    %eax,0xffffffe4(%ebp)
  10756c:	74 1f                	je     10758d <pmap_pagefault+0x154>
  10756e:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  107571:	c1 e8 0c             	shr    $0xc,%eax
  107574:	c1 e0 03             	shl    $0x3,%eax
  107577:	89 c2                	mov    %eax,%edx
  107579:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  10757e:	8d 04 02             	lea    (%edx,%eax,1),%eax
  107581:	8b 40 04             	mov    0x4(%eax),%eax
  107584:	83 f8 01             	cmp    $0x1,%eax
  107587:	0f 8e bc 02 00 00    	jle    107849 <pmap_pagefault+0x410>
  10758d:	e8 d3 9e ff ff       	call   101465 <mem_alloc>
  107592:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  107595:	83 7d e8 00          	cmpl   $0x0,0xffffffe8(%ebp)
  107599:	75 24                	jne    1075bf <pmap_pagefault+0x186>
  10759b:	c7 44 24 0c 9b d5 10 	movl   $0x10d59b,0xc(%esp)
  1075a2:	00 
  1075a3:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  1075aa:	00 
  1075ab:	c7 44 24 04 cf 01 00 	movl   $0x1cf,0x4(%esp)
  1075b2:	00 
  1075b3:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  1075ba:	e8 79 93 ff ff       	call   100938 <debug_panic>
  1075bf:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  1075c2:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
  1075c5:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  1075ca:	83 c0 08             	add    $0x8,%eax
  1075cd:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  1075d0:	73 17                	jae    1075e9 <pmap_pagefault+0x1b0>
  1075d2:	a1 d8 1d 18 00       	mov    0x181dd8,%eax
  1075d7:	c1 e0 03             	shl    $0x3,%eax
  1075da:	89 c2                	mov    %eax,%edx
  1075dc:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  1075e1:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1075e4:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  1075e7:	77 24                	ja     10760d <pmap_pagefault+0x1d4>
  1075e9:	c7 44 24 0c 20 d3 10 	movl   $0x10d320,0xc(%esp)
  1075f0:	00 
  1075f1:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  1075f8:	00 
  1075f9:	c7 44 24 04 9c 00 00 	movl   $0x9c,0x4(%esp)
  107600:	00 
  107601:	c7 04 24 57 d3 10 00 	movl   $0x10d357,(%esp)
  107608:	e8 2b 93 ff ff       	call   100938 <debug_panic>
  10760d:	8b 15 e0 1d 18 00    	mov    0x181de0,%edx
  107613:	b8 00 40 18 00       	mov    $0x184000,%eax
  107618:	c1 e8 0c             	shr    $0xc,%eax
  10761b:	c1 e0 03             	shl    $0x3,%eax
  10761e:	8d 04 02             	lea    (%edx,%eax,1),%eax
  107621:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  107624:	75 24                	jne    10764a <pmap_pagefault+0x211>
  107626:	c7 44 24 0c 65 d3 10 	movl   $0x10d365,0xc(%esp)
  10762d:	00 
  10762e:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  107635:	00 
  107636:	c7 44 24 04 9e 00 00 	movl   $0x9e,0x4(%esp)
  10763d:	00 
  10763e:	c7 04 24 57 d3 10 00 	movl   $0x10d357,(%esp)
  107645:	e8 ee 92 ff ff       	call   100938 <debug_panic>
  10764a:	8b 15 e0 1d 18 00    	mov    0x181de0,%edx
  107650:	b8 0c 00 10 00       	mov    $0x10000c,%eax
  107655:	c1 e8 0c             	shr    $0xc,%eax
  107658:	c1 e0 03             	shl    $0x3,%eax
  10765b:	8d 04 02             	lea    (%edx,%eax,1),%eax
  10765e:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  107661:	77 40                	ja     1076a3 <pmap_pagefault+0x26a>
  107663:	8b 15 e0 1d 18 00    	mov    0x181de0,%edx
  107669:	b8 08 50 18 00       	mov    $0x185008,%eax
  10766e:	83 e8 01             	sub    $0x1,%eax
  107671:	c1 e8 0c             	shr    $0xc,%eax
  107674:	c1 e0 03             	shl    $0x3,%eax
  107677:	8d 04 02             	lea    (%edx,%eax,1),%eax
  10767a:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  10767d:	72 24                	jb     1076a3 <pmap_pagefault+0x26a>
  10767f:	c7 44 24 0c 84 d3 10 	movl   $0x10d384,0xc(%esp)
  107686:	00 
  107687:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  10768e:	00 
  10768f:	c7 44 24 04 a0 00 00 	movl   $0xa0,0x4(%esp)
  107696:	00 
  107697:	c7 04 24 57 d3 10 00 	movl   $0x10d357,(%esp)
  10769e:	e8 95 92 ff ff       	call   100938 <debug_panic>
  1076a3:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  1076a6:	83 c0 04             	add    $0x4,%eax
  1076a9:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  1076b0:	00 
  1076b1:	89 04 24             	mov    %eax,(%esp)
  1076b4:	e8 c5 ea ff ff       	call   10617e <lockadd>
  1076b9:	8b 55 e8             	mov    0xffffffe8(%ebp),%edx
  1076bc:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  1076c1:	89 d1                	mov    %edx,%ecx
  1076c3:	29 c1                	sub    %eax,%ecx
  1076c5:	89 c8                	mov    %ecx,%eax
  1076c7:	c1 e0 09             	shl    $0x9,%eax
  1076ca:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  1076cd:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  1076d0:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
  1076d3:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  1076da:	00 
  1076db:	89 44 24 04          	mov    %eax,0x4(%esp)
  1076df:	89 14 24             	mov    %edx,(%esp)
  1076e2:	e8 83 45 00 00       	call   10bc6a <memmove>
  1076e7:	b8 00 40 18 00       	mov    $0x184000,%eax
  1076ec:	39 45 e4             	cmp    %eax,0xffffffe4(%ebp)
  1076ef:	0f 84 4e 01 00 00    	je     107843 <pmap_pagefault+0x40a>
  1076f5:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  1076f8:	c1 e8 0c             	shr    $0xc,%eax
  1076fb:	c1 e0 03             	shl    $0x3,%eax
  1076fe:	89 c2                	mov    %eax,%edx
  107700:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  107705:	8d 04 02             	lea    (%edx,%eax,1),%eax
  107708:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  10770b:	c7 45 f8 a9 14 10 00 	movl   $0x1014a9,0xfffffff8(%ebp)
  107712:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  107717:	83 c0 08             	add    $0x8,%eax
  10771a:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  10771d:	73 17                	jae    107736 <pmap_pagefault+0x2fd>
  10771f:	a1 d8 1d 18 00       	mov    0x181dd8,%eax
  107724:	c1 e0 03             	shl    $0x3,%eax
  107727:	89 c2                	mov    %eax,%edx
  107729:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  10772e:	8d 04 02             	lea    (%edx,%eax,1),%eax
  107731:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  107734:	77 24                	ja     10775a <pmap_pagefault+0x321>
  107736:	c7 44 24 0c 20 d3 10 	movl   $0x10d320,0xc(%esp)
  10773d:	00 
  10773e:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  107745:	00 
  107746:	c7 44 24 04 aa 00 00 	movl   $0xaa,0x4(%esp)
  10774d:	00 
  10774e:	c7 04 24 57 d3 10 00 	movl   $0x10d357,(%esp)
  107755:	e8 de 91 ff ff       	call   100938 <debug_panic>
  10775a:	8b 15 e0 1d 18 00    	mov    0x181de0,%edx
  107760:	b8 00 40 18 00       	mov    $0x184000,%eax
  107765:	c1 e8 0c             	shr    $0xc,%eax
  107768:	c1 e0 03             	shl    $0x3,%eax
  10776b:	8d 04 02             	lea    (%edx,%eax,1),%eax
  10776e:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  107771:	75 24                	jne    107797 <pmap_pagefault+0x35e>
  107773:	c7 44 24 0c 65 d3 10 	movl   $0x10d365,0xc(%esp)
  10777a:	00 
  10777b:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  107782:	00 
  107783:	c7 44 24 04 ac 00 00 	movl   $0xac,0x4(%esp)
  10778a:	00 
  10778b:	c7 04 24 57 d3 10 00 	movl   $0x10d357,(%esp)
  107792:	e8 a1 91 ff ff       	call   100938 <debug_panic>
  107797:	8b 15 e0 1d 18 00    	mov    0x181de0,%edx
  10779d:	b8 0c 00 10 00       	mov    $0x10000c,%eax
  1077a2:	c1 e8 0c             	shr    $0xc,%eax
  1077a5:	c1 e0 03             	shl    $0x3,%eax
  1077a8:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1077ab:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  1077ae:	77 40                	ja     1077f0 <pmap_pagefault+0x3b7>
  1077b0:	8b 15 e0 1d 18 00    	mov    0x181de0,%edx
  1077b6:	b8 08 50 18 00       	mov    $0x185008,%eax
  1077bb:	83 e8 01             	sub    $0x1,%eax
  1077be:	c1 e8 0c             	shr    $0xc,%eax
  1077c1:	c1 e0 03             	shl    $0x3,%eax
  1077c4:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1077c7:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  1077ca:	72 24                	jb     1077f0 <pmap_pagefault+0x3b7>
  1077cc:	c7 44 24 0c 84 d3 10 	movl   $0x10d384,0xc(%esp)
  1077d3:	00 
  1077d4:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  1077db:	00 
  1077dc:	c7 44 24 04 ae 00 00 	movl   $0xae,0x4(%esp)
  1077e3:	00 
  1077e4:	c7 04 24 57 d3 10 00 	movl   $0x10d357,(%esp)
  1077eb:	e8 48 91 ff ff       	call   100938 <debug_panic>
  1077f0:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  1077f3:	83 c0 04             	add    $0x4,%eax
  1077f6:	c7 44 24 04 ff ff ff 	movl   $0xffffffff,0x4(%esp)
  1077fd:	ff 
  1077fe:	89 04 24             	mov    %eax,(%esp)
  107801:	e8 75 eb ff ff       	call   10637b <lockaddz>
  107806:	84 c0                	test   %al,%al
  107808:	74 0b                	je     107815 <pmap_pagefault+0x3dc>
  10780a:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  10780d:	89 04 24             	mov    %eax,(%esp)
  107810:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  107813:	ff d0                	call   *%eax
  107815:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  107818:	8b 40 04             	mov    0x4(%eax),%eax
  10781b:	85 c0                	test   %eax,%eax
  10781d:	79 24                	jns    107843 <pmap_pagefault+0x40a>
  10781f:	c7 44 24 0c b5 d3 10 	movl   $0x10d3b5,0xc(%esp)
  107826:	00 
  107827:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  10782e:	00 
  10782f:	c7 44 24 04 b5 00 00 	movl   $0xb5,0x4(%esp)
  107836:	00 
  107837:	c7 04 24 57 d3 10 00 	movl   $0x10d357,(%esp)
  10783e:	e8 f5 90 ff ff       	call   100938 <debug_panic>
  107843:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  107846:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
  107849:	8b 55 e4             	mov    0xffffffe4(%ebp),%edx
  10784c:	81 ca 67 06 00 00    	or     $0x667,%edx
  107852:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  107855:	89 10                	mov    %edx,(%eax)
  107857:	8b 55 d4             	mov    0xffffffd4(%ebp),%edx
  10785a:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
  107860:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  107863:	8b 80 a0 06 00 00    	mov    0x6a0(%eax),%eax
  107869:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  107870:	00 
  107871:	89 54 24 04          	mov    %edx,0x4(%esp)
  107875:	89 04 24             	mov    %eax,(%esp)
  107878:	e8 e6 f7 ff ff       	call   107063 <pmap_inval>
  10787d:	8b 45 08             	mov    0x8(%ebp),%eax
  107880:	89 04 24             	mov    %eax,(%esp)
  107883:	e8 d8 c1 ff ff       	call   103a60 <trap_return>
  107888:	c9                   	leave  
  107889:	c3                   	ret    

0010788a <pmap_mergepage>:
  10788a:	55                   	push   %ebp
  10788b:	89 e5                	mov    %esp,%ebp
  10788d:	83 ec 48             	sub    $0x48,%esp
  107890:	8b 45 08             	mov    0x8(%ebp),%eax
  107893:	8b 00                	mov    (%eax),%eax
  107895:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  10789a:	89 45 d4             	mov    %eax,0xffffffd4(%ebp)
  10789d:	8b 45 0c             	mov    0xc(%ebp),%eax
  1078a0:	8b 00                	mov    (%eax),%eax
  1078a2:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1078a7:	89 45 d8             	mov    %eax,0xffffffd8(%ebp)
  1078aa:	8b 45 10             	mov    0x10(%ebp),%eax
  1078ad:	8b 00                	mov    (%eax),%eax
  1078af:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1078b4:	89 45 dc             	mov    %eax,0xffffffdc(%ebp)
  1078b7:	81 7d dc 00 40 18 00 	cmpl   $0x184000,0xffffffdc(%ebp)
  1078be:	0f 84 d0 04 00 00    	je     107d94 <pmap_mergepage+0x50a>
  1078c4:	b8 00 40 18 00       	mov    $0x184000,%eax
  1078c9:	39 45 dc             	cmp    %eax,0xffffffdc(%ebp)
  1078cc:	74 1f                	je     1078ed <pmap_mergepage+0x63>
  1078ce:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  1078d1:	c1 e8 0c             	shr    $0xc,%eax
  1078d4:	c1 e0 03             	shl    $0x3,%eax
  1078d7:	89 c2                	mov    %eax,%edx
  1078d9:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  1078de:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1078e1:	8b 40 04             	mov    0x4(%eax),%eax
  1078e4:	83 f8 01             	cmp    $0x1,%eax
  1078e7:	0f 8e cc 02 00 00    	jle    107bb9 <pmap_mergepage+0x32f>
  1078ed:	e8 73 9b ff ff       	call   101465 <mem_alloc>
  1078f2:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
  1078f5:	83 7d e4 00          	cmpl   $0x0,0xffffffe4(%ebp)
  1078f9:	75 24                	jne    10791f <pmap_mergepage+0x95>
  1078fb:	c7 44 24 0c 9b d5 10 	movl   $0x10d59b,0xc(%esp)
  107902:	00 
  107903:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  10790a:	00 
  10790b:	c7 44 24 04 f6 01 00 	movl   $0x1f6,0x4(%esp)
  107912:	00 
  107913:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  10791a:	e8 19 90 ff ff       	call   100938 <debug_panic>
  10791f:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  107922:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  107925:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  10792a:	83 c0 08             	add    $0x8,%eax
  10792d:	3b 45 ec             	cmp    0xffffffec(%ebp),%eax
  107930:	73 17                	jae    107949 <pmap_mergepage+0xbf>
  107932:	a1 d8 1d 18 00       	mov    0x181dd8,%eax
  107937:	c1 e0 03             	shl    $0x3,%eax
  10793a:	89 c2                	mov    %eax,%edx
  10793c:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  107941:	8d 04 02             	lea    (%edx,%eax,1),%eax
  107944:	3b 45 ec             	cmp    0xffffffec(%ebp),%eax
  107947:	77 24                	ja     10796d <pmap_mergepage+0xe3>
  107949:	c7 44 24 0c 20 d3 10 	movl   $0x10d320,0xc(%esp)
  107950:	00 
  107951:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  107958:	00 
  107959:	c7 44 24 04 9c 00 00 	movl   $0x9c,0x4(%esp)
  107960:	00 
  107961:	c7 04 24 57 d3 10 00 	movl   $0x10d357,(%esp)
  107968:	e8 cb 8f ff ff       	call   100938 <debug_panic>
  10796d:	8b 15 e0 1d 18 00    	mov    0x181de0,%edx
  107973:	b8 00 40 18 00       	mov    $0x184000,%eax
  107978:	c1 e8 0c             	shr    $0xc,%eax
  10797b:	c1 e0 03             	shl    $0x3,%eax
  10797e:	8d 04 02             	lea    (%edx,%eax,1),%eax
  107981:	3b 45 ec             	cmp    0xffffffec(%ebp),%eax
  107984:	75 24                	jne    1079aa <pmap_mergepage+0x120>
  107986:	c7 44 24 0c 65 d3 10 	movl   $0x10d365,0xc(%esp)
  10798d:	00 
  10798e:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  107995:	00 
  107996:	c7 44 24 04 9e 00 00 	movl   $0x9e,0x4(%esp)
  10799d:	00 
  10799e:	c7 04 24 57 d3 10 00 	movl   $0x10d357,(%esp)
  1079a5:	e8 8e 8f ff ff       	call   100938 <debug_panic>
  1079aa:	8b 15 e0 1d 18 00    	mov    0x181de0,%edx
  1079b0:	b8 0c 00 10 00       	mov    $0x10000c,%eax
  1079b5:	c1 e8 0c             	shr    $0xc,%eax
  1079b8:	c1 e0 03             	shl    $0x3,%eax
  1079bb:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1079be:	3b 45 ec             	cmp    0xffffffec(%ebp),%eax
  1079c1:	77 40                	ja     107a03 <pmap_mergepage+0x179>
  1079c3:	8b 15 e0 1d 18 00    	mov    0x181de0,%edx
  1079c9:	b8 08 50 18 00       	mov    $0x185008,%eax
  1079ce:	83 e8 01             	sub    $0x1,%eax
  1079d1:	c1 e8 0c             	shr    $0xc,%eax
  1079d4:	c1 e0 03             	shl    $0x3,%eax
  1079d7:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1079da:	3b 45 ec             	cmp    0xffffffec(%ebp),%eax
  1079dd:	72 24                	jb     107a03 <pmap_mergepage+0x179>
  1079df:	c7 44 24 0c 84 d3 10 	movl   $0x10d384,0xc(%esp)
  1079e6:	00 
  1079e7:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  1079ee:	00 
  1079ef:	c7 44 24 04 a0 00 00 	movl   $0xa0,0x4(%esp)
  1079f6:	00 
  1079f7:	c7 04 24 57 d3 10 00 	movl   $0x10d357,(%esp)
  1079fe:	e8 35 8f ff ff       	call   100938 <debug_panic>
  107a03:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  107a06:	83 c0 04             	add    $0x4,%eax
  107a09:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  107a10:	00 
  107a11:	89 04 24             	mov    %eax,(%esp)
  107a14:	e8 65 e7 ff ff       	call   10617e <lockadd>
  107a19:	8b 55 e4             	mov    0xffffffe4(%ebp),%edx
  107a1c:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  107a21:	89 d1                	mov    %edx,%ecx
  107a23:	29 c1                	sub    %eax,%ecx
  107a25:	89 c8                	mov    %ecx,%eax
  107a27:	c1 e0 09             	shl    $0x9,%eax
  107a2a:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  107a2d:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  107a34:	00 
  107a35:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  107a38:	89 44 24 04          	mov    %eax,0x4(%esp)
  107a3c:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  107a3f:	89 04 24             	mov    %eax,(%esp)
  107a42:	e8 23 42 00 00       	call   10bc6a <memmove>
  107a47:	b8 00 40 18 00       	mov    $0x184000,%eax
  107a4c:	39 45 dc             	cmp    %eax,0xffffffdc(%ebp)
  107a4f:	0f 84 4e 01 00 00    	je     107ba3 <pmap_mergepage+0x319>
  107a55:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  107a58:	c1 e8 0c             	shr    $0xc,%eax
  107a5b:	c1 e0 03             	shl    $0x3,%eax
  107a5e:	89 c2                	mov    %eax,%edx
  107a60:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  107a65:	8d 04 02             	lea    (%edx,%eax,1),%eax
  107a68:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
  107a6b:	c7 45 f0 a9 14 10 00 	movl   $0x1014a9,0xfffffff0(%ebp)
  107a72:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  107a77:	83 c0 08             	add    $0x8,%eax
  107a7a:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  107a7d:	73 17                	jae    107a96 <pmap_mergepage+0x20c>
  107a7f:	a1 d8 1d 18 00       	mov    0x181dd8,%eax
  107a84:	c1 e0 03             	shl    $0x3,%eax
  107a87:	89 c2                	mov    %eax,%edx
  107a89:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  107a8e:	8d 04 02             	lea    (%edx,%eax,1),%eax
  107a91:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  107a94:	77 24                	ja     107aba <pmap_mergepage+0x230>
  107a96:	c7 44 24 0c 20 d3 10 	movl   $0x10d320,0xc(%esp)
  107a9d:	00 
  107a9e:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  107aa5:	00 
  107aa6:	c7 44 24 04 aa 00 00 	movl   $0xaa,0x4(%esp)
  107aad:	00 
  107aae:	c7 04 24 57 d3 10 00 	movl   $0x10d357,(%esp)
  107ab5:	e8 7e 8e ff ff       	call   100938 <debug_panic>
  107aba:	8b 15 e0 1d 18 00    	mov    0x181de0,%edx
  107ac0:	b8 00 40 18 00       	mov    $0x184000,%eax
  107ac5:	c1 e8 0c             	shr    $0xc,%eax
  107ac8:	c1 e0 03             	shl    $0x3,%eax
  107acb:	8d 04 02             	lea    (%edx,%eax,1),%eax
  107ace:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  107ad1:	75 24                	jne    107af7 <pmap_mergepage+0x26d>
  107ad3:	c7 44 24 0c 65 d3 10 	movl   $0x10d365,0xc(%esp)
  107ada:	00 
  107adb:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  107ae2:	00 
  107ae3:	c7 44 24 04 ac 00 00 	movl   $0xac,0x4(%esp)
  107aea:	00 
  107aeb:	c7 04 24 57 d3 10 00 	movl   $0x10d357,(%esp)
  107af2:	e8 41 8e ff ff       	call   100938 <debug_panic>
  107af7:	8b 15 e0 1d 18 00    	mov    0x181de0,%edx
  107afd:	b8 0c 00 10 00       	mov    $0x10000c,%eax
  107b02:	c1 e8 0c             	shr    $0xc,%eax
  107b05:	c1 e0 03             	shl    $0x3,%eax
  107b08:	8d 04 02             	lea    (%edx,%eax,1),%eax
  107b0b:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  107b0e:	77 40                	ja     107b50 <pmap_mergepage+0x2c6>
  107b10:	8b 15 e0 1d 18 00    	mov    0x181de0,%edx
  107b16:	b8 08 50 18 00       	mov    $0x185008,%eax
  107b1b:	83 e8 01             	sub    $0x1,%eax
  107b1e:	c1 e8 0c             	shr    $0xc,%eax
  107b21:	c1 e0 03             	shl    $0x3,%eax
  107b24:	8d 04 02             	lea    (%edx,%eax,1),%eax
  107b27:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  107b2a:	72 24                	jb     107b50 <pmap_mergepage+0x2c6>
  107b2c:	c7 44 24 0c 84 d3 10 	movl   $0x10d384,0xc(%esp)
  107b33:	00 
  107b34:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  107b3b:	00 
  107b3c:	c7 44 24 04 ae 00 00 	movl   $0xae,0x4(%esp)
  107b43:	00 
  107b44:	c7 04 24 57 d3 10 00 	movl   $0x10d357,(%esp)
  107b4b:	e8 e8 8d ff ff       	call   100938 <debug_panic>
  107b50:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  107b53:	83 c0 04             	add    $0x4,%eax
  107b56:	c7 44 24 04 ff ff ff 	movl   $0xffffffff,0x4(%esp)
  107b5d:	ff 
  107b5e:	89 04 24             	mov    %eax,(%esp)
  107b61:	e8 15 e8 ff ff       	call   10637b <lockaddz>
  107b66:	84 c0                	test   %al,%al
  107b68:	74 0b                	je     107b75 <pmap_mergepage+0x2eb>
  107b6a:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  107b6d:	89 04 24             	mov    %eax,(%esp)
  107b70:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  107b73:	ff d0                	call   *%eax
  107b75:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  107b78:	8b 40 04             	mov    0x4(%eax),%eax
  107b7b:	85 c0                	test   %eax,%eax
  107b7d:	79 24                	jns    107ba3 <pmap_mergepage+0x319>
  107b7f:	c7 44 24 0c b5 d3 10 	movl   $0x10d3b5,0xc(%esp)
  107b86:	00 
  107b87:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  107b8e:	00 
  107b8f:	c7 44 24 04 b5 00 00 	movl   $0xb5,0x4(%esp)
  107b96:	00 
  107b97:	c7 04 24 57 d3 10 00 	movl   $0x10d357,(%esp)
  107b9e:	e8 95 8d ff ff       	call   100938 <debug_panic>
  107ba3:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  107ba6:	89 45 dc             	mov    %eax,0xffffffdc(%ebp)
  107ba9:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  107bac:	89 c2                	mov    %eax,%edx
  107bae:	81 ca 67 06 00 00    	or     $0x667,%edx
  107bb4:	8b 45 10             	mov    0x10(%ebp),%eax
  107bb7:	89 10                	mov    %edx,(%eax)
  107bb9:	c7 45 e0 00 00 00 00 	movl   $0x0,0xffffffe0(%ebp)
  107bc0:	e9 c2 01 00 00       	jmp    107d87 <pmap_mergepage+0x4fd>
  107bc5:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  107bc8:	03 45 d8             	add    0xffffffd8(%ebp),%eax
  107bcb:	0f b6 10             	movzbl (%eax),%edx
  107bce:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  107bd1:	03 45 d4             	add    0xffffffd4(%ebp),%eax
  107bd4:	0f b6 00             	movzbl (%eax),%eax
  107bd7:	38 c2                	cmp    %al,%dl
  107bd9:	0f 84 a4 01 00 00    	je     107d83 <pmap_mergepage+0x4f9>
  107bdf:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  107be2:	03 45 dc             	add    0xffffffdc(%ebp),%eax
  107be5:	0f b6 10             	movzbl (%eax),%edx
  107be8:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  107beb:	03 45 d4             	add    0xffffffd4(%ebp),%eax
  107bee:	0f b6 00             	movzbl (%eax),%eax
  107bf1:	38 c2                	cmp    %al,%dl
  107bf3:	75 18                	jne    107c0d <pmap_mergepage+0x383>
  107bf5:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  107bf8:	89 c2                	mov    %eax,%edx
  107bfa:	03 55 dc             	add    0xffffffdc(%ebp),%edx
  107bfd:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  107c00:	03 45 d8             	add    0xffffffd8(%ebp),%eax
  107c03:	0f b6 00             	movzbl (%eax),%eax
  107c06:	88 02                	mov    %al,(%edx)
  107c08:	e9 76 01 00 00       	jmp    107d83 <pmap_mergepage+0x4f9>
  107c0d:	8b 45 14             	mov    0x14(%ebp),%eax
  107c10:	89 44 24 04          	mov    %eax,0x4(%esp)
  107c14:	c7 04 24 a0 d5 10 00 	movl   $0x10d5a0,(%esp)
  107c1b:	e8 4d 3c 00 00       	call   10b86d <cprintf>
  107c20:	8b 45 10             	mov    0x10(%ebp),%eax
  107c23:	8b 00                	mov    (%eax),%eax
  107c25:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  107c2a:	c1 e8 0c             	shr    $0xc,%eax
  107c2d:	c1 e0 03             	shl    $0x3,%eax
  107c30:	89 c2                	mov    %eax,%edx
  107c32:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  107c37:	8d 04 02             	lea    (%edx,%eax,1),%eax
  107c3a:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  107c3d:	c7 45 f8 a9 14 10 00 	movl   $0x1014a9,0xfffffff8(%ebp)
  107c44:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  107c49:	83 c0 08             	add    $0x8,%eax
  107c4c:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  107c4f:	73 17                	jae    107c68 <pmap_mergepage+0x3de>
  107c51:	a1 d8 1d 18 00       	mov    0x181dd8,%eax
  107c56:	c1 e0 03             	shl    $0x3,%eax
  107c59:	89 c2                	mov    %eax,%edx
  107c5b:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  107c60:	8d 04 02             	lea    (%edx,%eax,1),%eax
  107c63:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  107c66:	77 24                	ja     107c8c <pmap_mergepage+0x402>
  107c68:	c7 44 24 0c 20 d3 10 	movl   $0x10d320,0xc(%esp)
  107c6f:	00 
  107c70:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  107c77:	00 
  107c78:	c7 44 24 04 aa 00 00 	movl   $0xaa,0x4(%esp)
  107c7f:	00 
  107c80:	c7 04 24 57 d3 10 00 	movl   $0x10d357,(%esp)
  107c87:	e8 ac 8c ff ff       	call   100938 <debug_panic>
  107c8c:	8b 15 e0 1d 18 00    	mov    0x181de0,%edx
  107c92:	b8 00 40 18 00       	mov    $0x184000,%eax
  107c97:	c1 e8 0c             	shr    $0xc,%eax
  107c9a:	c1 e0 03             	shl    $0x3,%eax
  107c9d:	8d 04 02             	lea    (%edx,%eax,1),%eax
  107ca0:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  107ca3:	75 24                	jne    107cc9 <pmap_mergepage+0x43f>
  107ca5:	c7 44 24 0c 65 d3 10 	movl   $0x10d365,0xc(%esp)
  107cac:	00 
  107cad:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  107cb4:	00 
  107cb5:	c7 44 24 04 ac 00 00 	movl   $0xac,0x4(%esp)
  107cbc:	00 
  107cbd:	c7 04 24 57 d3 10 00 	movl   $0x10d357,(%esp)
  107cc4:	e8 6f 8c ff ff       	call   100938 <debug_panic>
  107cc9:	8b 15 e0 1d 18 00    	mov    0x181de0,%edx
  107ccf:	b8 0c 00 10 00       	mov    $0x10000c,%eax
  107cd4:	c1 e8 0c             	shr    $0xc,%eax
  107cd7:	c1 e0 03             	shl    $0x3,%eax
  107cda:	8d 04 02             	lea    (%edx,%eax,1),%eax
  107cdd:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  107ce0:	77 40                	ja     107d22 <pmap_mergepage+0x498>
  107ce2:	8b 15 e0 1d 18 00    	mov    0x181de0,%edx
  107ce8:	b8 08 50 18 00       	mov    $0x185008,%eax
  107ced:	83 e8 01             	sub    $0x1,%eax
  107cf0:	c1 e8 0c             	shr    $0xc,%eax
  107cf3:	c1 e0 03             	shl    $0x3,%eax
  107cf6:	8d 04 02             	lea    (%edx,%eax,1),%eax
  107cf9:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  107cfc:	72 24                	jb     107d22 <pmap_mergepage+0x498>
  107cfe:	c7 44 24 0c 84 d3 10 	movl   $0x10d384,0xc(%esp)
  107d05:	00 
  107d06:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  107d0d:	00 
  107d0e:	c7 44 24 04 ae 00 00 	movl   $0xae,0x4(%esp)
  107d15:	00 
  107d16:	c7 04 24 57 d3 10 00 	movl   $0x10d357,(%esp)
  107d1d:	e8 16 8c ff ff       	call   100938 <debug_panic>
  107d22:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  107d25:	83 c0 04             	add    $0x4,%eax
  107d28:	c7 44 24 04 ff ff ff 	movl   $0xffffffff,0x4(%esp)
  107d2f:	ff 
  107d30:	89 04 24             	mov    %eax,(%esp)
  107d33:	e8 43 e6 ff ff       	call   10637b <lockaddz>
  107d38:	84 c0                	test   %al,%al
  107d3a:	74 0b                	je     107d47 <pmap_mergepage+0x4bd>
  107d3c:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  107d3f:	89 04 24             	mov    %eax,(%esp)
  107d42:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  107d45:	ff d0                	call   *%eax
  107d47:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  107d4a:	8b 40 04             	mov    0x4(%eax),%eax
  107d4d:	85 c0                	test   %eax,%eax
  107d4f:	79 24                	jns    107d75 <pmap_mergepage+0x4eb>
  107d51:	c7 44 24 0c b5 d3 10 	movl   $0x10d3b5,0xc(%esp)
  107d58:	00 
  107d59:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  107d60:	00 
  107d61:	c7 44 24 04 b5 00 00 	movl   $0xb5,0x4(%esp)
  107d68:	00 
  107d69:	c7 04 24 57 d3 10 00 	movl   $0x10d357,(%esp)
  107d70:	e8 c3 8b ff ff       	call   100938 <debug_panic>
  107d75:	b8 00 40 18 00       	mov    $0x184000,%eax
  107d7a:	89 c2                	mov    %eax,%edx
  107d7c:	8b 45 10             	mov    0x10(%ebp),%eax
  107d7f:	89 10                	mov    %edx,(%eax)
  107d81:	eb 11                	jmp    107d94 <pmap_mergepage+0x50a>
  107d83:	83 45 e0 01          	addl   $0x1,0xffffffe0(%ebp)
  107d87:	81 7d e0 ff 0f 00 00 	cmpl   $0xfff,0xffffffe0(%ebp)
  107d8e:	0f 8e 31 fe ff ff    	jle    107bc5 <pmap_mergepage+0x33b>
  107d94:	c9                   	leave  
  107d95:	c3                   	ret    

00107d96 <pmap_merge>:
  107d96:	55                   	push   %ebp
  107d97:	89 e5                	mov    %esp,%ebp
  107d99:	83 ec 48             	sub    $0x48,%esp
  107d9c:	8b 45 10             	mov    0x10(%ebp),%eax
  107d9f:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  107da4:	85 c0                	test   %eax,%eax
  107da6:	74 24                	je     107dcc <pmap_merge+0x36>
  107da8:	c7 44 24 0c 4f d4 10 	movl   $0x10d44f,0xc(%esp)
  107daf:	00 
  107db0:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  107db7:	00 
  107db8:	c7 44 24 04 1d 02 00 	movl   $0x21d,0x4(%esp)
  107dbf:	00 
  107dc0:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  107dc7:	e8 6c 8b ff ff       	call   100938 <debug_panic>
  107dcc:	8b 45 18             	mov    0x18(%ebp),%eax
  107dcf:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  107dd4:	85 c0                	test   %eax,%eax
  107dd6:	74 24                	je     107dfc <pmap_merge+0x66>
  107dd8:	c7 44 24 0c 5f d4 10 	movl   $0x10d45f,0xc(%esp)
  107ddf:	00 
  107de0:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  107de7:	00 
  107de8:	c7 44 24 04 1e 02 00 	movl   $0x21e,0x4(%esp)
  107def:	00 
  107df0:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  107df7:	e8 3c 8b ff ff       	call   100938 <debug_panic>
  107dfc:	8b 45 1c             	mov    0x1c(%ebp),%eax
  107dff:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  107e04:	85 c0                	test   %eax,%eax
  107e06:	74 24                	je     107e2c <pmap_merge+0x96>
  107e08:	c7 44 24 0c 6f d4 10 	movl   $0x10d46f,0xc(%esp)
  107e0f:	00 
  107e10:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  107e17:	00 
  107e18:	c7 44 24 04 1f 02 00 	movl   $0x21f,0x4(%esp)
  107e1f:	00 
  107e20:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  107e27:	e8 0c 8b ff ff       	call   100938 <debug_panic>
  107e2c:	81 7d 10 ff ff ff 3f 	cmpl   $0x3fffffff,0x10(%ebp)
  107e33:	76 09                	jbe    107e3e <pmap_merge+0xa8>
  107e35:	81 7d 10 ff ff ff ef 	cmpl   $0xefffffff,0x10(%ebp)
  107e3c:	76 24                	jbe    107e62 <pmap_merge+0xcc>
  107e3e:	c7 44 24 0c 80 d4 10 	movl   $0x10d480,0xc(%esp)
  107e45:	00 
  107e46:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  107e4d:	00 
  107e4e:	c7 44 24 04 20 02 00 	movl   $0x220,0x4(%esp)
  107e55:	00 
  107e56:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  107e5d:	e8 d6 8a ff ff       	call   100938 <debug_panic>
  107e62:	81 7d 18 ff ff ff 3f 	cmpl   $0x3fffffff,0x18(%ebp)
  107e69:	76 09                	jbe    107e74 <pmap_merge+0xde>
  107e6b:	81 7d 18 ff ff ff ef 	cmpl   $0xefffffff,0x18(%ebp)
  107e72:	76 24                	jbe    107e98 <pmap_merge+0x102>
  107e74:	c7 44 24 0c a4 d4 10 	movl   $0x10d4a4,0xc(%esp)
  107e7b:	00 
  107e7c:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  107e83:	00 
  107e84:	c7 44 24 04 21 02 00 	movl   $0x221,0x4(%esp)
  107e8b:	00 
  107e8c:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  107e93:	e8 a0 8a ff ff       	call   100938 <debug_panic>
  107e98:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
  107e9d:	2b 45 10             	sub    0x10(%ebp),%eax
  107ea0:	3b 45 1c             	cmp    0x1c(%ebp),%eax
  107ea3:	73 24                	jae    107ec9 <pmap_merge+0x133>
  107ea5:	c7 44 24 0c c8 d4 10 	movl   $0x10d4c8,0xc(%esp)
  107eac:	00 
  107ead:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  107eb4:	00 
  107eb5:	c7 44 24 04 22 02 00 	movl   $0x222,0x4(%esp)
  107ebc:	00 
  107ebd:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  107ec4:	e8 6f 8a ff ff       	call   100938 <debug_panic>
  107ec9:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
  107ece:	2b 45 18             	sub    0x18(%ebp),%eax
  107ed1:	3b 45 1c             	cmp    0x1c(%ebp),%eax
  107ed4:	73 24                	jae    107efa <pmap_merge+0x164>
  107ed6:	c7 44 24 0c e0 d4 10 	movl   $0x10d4e0,0xc(%esp)
  107edd:	00 
  107ede:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  107ee5:	00 
  107ee6:	c7 44 24 04 23 02 00 	movl   $0x223,0x4(%esp)
  107eed:	00 
  107eee:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  107ef5:	e8 3e 8a ff ff       	call   100938 <debug_panic>
  107efa:	8b 45 1c             	mov    0x1c(%ebp),%eax
  107efd:	89 44 24 08          	mov    %eax,0x8(%esp)
  107f01:	8b 45 10             	mov    0x10(%ebp),%eax
  107f04:	89 44 24 04          	mov    %eax,0x4(%esp)
  107f08:	8b 45 0c             	mov    0xc(%ebp),%eax
  107f0b:	89 04 24             	mov    %eax,(%esp)
  107f0e:	e8 50 f1 ff ff       	call   107063 <pmap_inval>
  107f13:	8b 45 1c             	mov    0x1c(%ebp),%eax
  107f16:	89 44 24 08          	mov    %eax,0x8(%esp)
  107f1a:	8b 45 18             	mov    0x18(%ebp),%eax
  107f1d:	89 44 24 04          	mov    %eax,0x4(%esp)
  107f21:	8b 45 14             	mov    0x14(%ebp),%eax
  107f24:	89 04 24             	mov    %eax,(%esp)
  107f27:	e8 37 f1 ff ff       	call   107063 <pmap_inval>
  107f2c:	8b 45 10             	mov    0x10(%ebp),%eax
  107f2f:	c1 e8 16             	shr    $0x16,%eax
  107f32:	25 ff 03 00 00       	and    $0x3ff,%eax
  107f37:	c1 e0 02             	shl    $0x2,%eax
  107f3a:	03 45 08             	add    0x8(%ebp),%eax
  107f3d:	89 45 d4             	mov    %eax,0xffffffd4(%ebp)
  107f40:	8b 45 10             	mov    0x10(%ebp),%eax
  107f43:	c1 e8 16             	shr    $0x16,%eax
  107f46:	25 ff 03 00 00       	and    $0x3ff,%eax
  107f4b:	c1 e0 02             	shl    $0x2,%eax
  107f4e:	03 45 0c             	add    0xc(%ebp),%eax
  107f51:	89 45 d8             	mov    %eax,0xffffffd8(%ebp)
  107f54:	8b 45 18             	mov    0x18(%ebp),%eax
  107f57:	c1 e8 16             	shr    $0x16,%eax
  107f5a:	25 ff 03 00 00       	and    $0x3ff,%eax
  107f5f:	c1 e0 02             	shl    $0x2,%eax
  107f62:	03 45 14             	add    0x14(%ebp),%eax
  107f65:	89 45 dc             	mov    %eax,0xffffffdc(%ebp)
  107f68:	8b 45 1c             	mov    0x1c(%ebp),%eax
  107f6b:	03 45 10             	add    0x10(%ebp),%eax
  107f6e:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)
  107f71:	e9 e4 03 00 00       	jmp    10835a <pmap_merge+0x5c4>
  107f76:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  107f79:	8b 10                	mov    (%eax),%edx
  107f7b:	8b 45 d4             	mov    0xffffffd4(%ebp),%eax
  107f7e:	8b 00                	mov    (%eax),%eax
  107f80:	39 c2                	cmp    %eax,%edx
  107f82:	75 13                	jne    107f97 <pmap_merge+0x201>
  107f84:	81 45 10 00 00 40 00 	addl   $0x400000,0x10(%ebp)
  107f8b:	81 45 18 00 00 40 00 	addl   $0x400000,0x18(%ebp)
  107f92:	e9 b7 03 00 00       	jmp    10834e <pmap_merge+0x5b8>
  107f97:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  107f9a:	8b 10                	mov    (%eax),%edx
  107f9c:	8b 45 d4             	mov    0xffffffd4(%ebp),%eax
  107f9f:	8b 00                	mov    (%eax),%eax
  107fa1:	39 c2                	cmp    %eax,%edx
  107fa3:	75 4b                	jne    107ff0 <pmap_merge+0x25a>
  107fa5:	c7 44 24 10 00 00 40 	movl   $0x400000,0x10(%esp)
  107fac:	00 
  107fad:	8b 45 18             	mov    0x18(%ebp),%eax
  107fb0:	89 44 24 0c          	mov    %eax,0xc(%esp)
  107fb4:	8b 45 14             	mov    0x14(%ebp),%eax
  107fb7:	89 44 24 08          	mov    %eax,0x8(%esp)
  107fbb:	8b 45 10             	mov    0x10(%ebp),%eax
  107fbe:	89 44 24 04          	mov    %eax,0x4(%esp)
  107fc2:	8b 45 0c             	mov    0xc(%ebp),%eax
  107fc5:	89 04 24             	mov    %eax,(%esp)
  107fc8:	e8 e3 f0 ff ff       	call   1070b0 <pmap_copy>
  107fcd:	85 c0                	test   %eax,%eax
  107fcf:	75 0c                	jne    107fdd <pmap_merge+0x247>
  107fd1:	c7 45 cc 00 00 00 00 	movl   $0x0,0xffffffcc(%ebp)
  107fd8:	e9 90 03 00 00       	jmp    10836d <pmap_merge+0x5d7>
  107fdd:	81 45 10 00 00 40 00 	addl   $0x400000,0x10(%ebp)
  107fe4:	81 45 18 00 00 40 00 	addl   $0x400000,0x18(%ebp)
  107feb:	e9 5e 03 00 00       	jmp    10834e <pmap_merge+0x5b8>
  107ff0:	8b 45 d4             	mov    0xffffffd4(%ebp),%eax
  107ff3:	8b 00                	mov    (%eax),%eax
  107ff5:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  107ffa:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
  107ffd:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  108000:	8b 00                	mov    (%eax),%eax
  108002:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  108007:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  10800a:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
  108011:	00 
  108012:	8b 45 18             	mov    0x18(%ebp),%eax
  108015:	89 44 24 04          	mov    %eax,0x4(%esp)
  108019:	8b 45 14             	mov    0x14(%ebp),%eax
  10801c:	89 04 24             	mov    %eax,(%esp)
  10801f:	e8 73 e3 ff ff       	call   106397 <pmap_walk>
  108024:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  108027:	83 7d ec 00          	cmpl   $0x0,0xffffffec(%ebp)
  10802b:	75 0c                	jne    108039 <pmap_merge+0x2a3>
  10802d:	c7 45 cc 00 00 00 00 	movl   $0x0,0xffffffcc(%ebp)
  108034:	e9 34 03 00 00       	jmp    10836d <pmap_merge+0x5d7>
  108039:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  10803c:	05 00 10 00 00       	add    $0x1000,%eax
  108041:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
  108044:	e9 f9 02 00 00       	jmp    108342 <pmap_merge+0x5ac>
  108049:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  10804c:	8b 10                	mov    (%eax),%edx
  10804e:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  108051:	8b 00                	mov    (%eax),%eax
  108053:	39 c2                	cmp    %eax,%edx
  108055:	0f 84 cd 02 00 00    	je     108328 <pmap_merge+0x592>
  10805b:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  10805e:	8b 10                	mov    (%eax),%edx
  108060:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  108063:	8b 00                	mov    (%eax),%eax
  108065:	39 c2                	cmp    %eax,%edx
  108067:	0f 85 9b 02 00 00    	jne    108308 <pmap_merge+0x572>
  10806d:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  108070:	8b 00                	mov    (%eax),%eax
  108072:	89 c2                	mov    %eax,%edx
  108074:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
  10807a:	b8 00 40 18 00       	mov    $0x184000,%eax
  10807f:	39 c2                	cmp    %eax,%edx
  108081:	0f 84 55 01 00 00    	je     1081dc <pmap_merge+0x446>
  108087:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  10808a:	8b 00                	mov    (%eax),%eax
  10808c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  108091:	c1 e8 0c             	shr    $0xc,%eax
  108094:	c1 e0 03             	shl    $0x3,%eax
  108097:	89 c2                	mov    %eax,%edx
  108099:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  10809e:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1080a1:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  1080a4:	c7 45 f4 a9 14 10 00 	movl   $0x1014a9,0xfffffff4(%ebp)
  1080ab:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  1080b0:	83 c0 08             	add    $0x8,%eax
  1080b3:	3b 45 f8             	cmp    0xfffffff8(%ebp),%eax
  1080b6:	73 17                	jae    1080cf <pmap_merge+0x339>
  1080b8:	a1 d8 1d 18 00       	mov    0x181dd8,%eax
  1080bd:	c1 e0 03             	shl    $0x3,%eax
  1080c0:	89 c2                	mov    %eax,%edx
  1080c2:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  1080c7:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1080ca:	3b 45 f8             	cmp    0xfffffff8(%ebp),%eax
  1080cd:	77 24                	ja     1080f3 <pmap_merge+0x35d>
  1080cf:	c7 44 24 0c 20 d3 10 	movl   $0x10d320,0xc(%esp)
  1080d6:	00 
  1080d7:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  1080de:	00 
  1080df:	c7 44 24 04 aa 00 00 	movl   $0xaa,0x4(%esp)
  1080e6:	00 
  1080e7:	c7 04 24 57 d3 10 00 	movl   $0x10d357,(%esp)
  1080ee:	e8 45 88 ff ff       	call   100938 <debug_panic>
  1080f3:	8b 15 e0 1d 18 00    	mov    0x181de0,%edx
  1080f9:	b8 00 40 18 00       	mov    $0x184000,%eax
  1080fe:	c1 e8 0c             	shr    $0xc,%eax
  108101:	c1 e0 03             	shl    $0x3,%eax
  108104:	8d 04 02             	lea    (%edx,%eax,1),%eax
  108107:	3b 45 f8             	cmp    0xfffffff8(%ebp),%eax
  10810a:	75 24                	jne    108130 <pmap_merge+0x39a>
  10810c:	c7 44 24 0c 65 d3 10 	movl   $0x10d365,0xc(%esp)
  108113:	00 
  108114:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  10811b:	00 
  10811c:	c7 44 24 04 ac 00 00 	movl   $0xac,0x4(%esp)
  108123:	00 
  108124:	c7 04 24 57 d3 10 00 	movl   $0x10d357,(%esp)
  10812b:	e8 08 88 ff ff       	call   100938 <debug_panic>
  108130:	8b 15 e0 1d 18 00    	mov    0x181de0,%edx
  108136:	b8 0c 00 10 00       	mov    $0x10000c,%eax
  10813b:	c1 e8 0c             	shr    $0xc,%eax
  10813e:	c1 e0 03             	shl    $0x3,%eax
  108141:	8d 04 02             	lea    (%edx,%eax,1),%eax
  108144:	3b 45 f8             	cmp    0xfffffff8(%ebp),%eax
  108147:	77 40                	ja     108189 <pmap_merge+0x3f3>
  108149:	8b 15 e0 1d 18 00    	mov    0x181de0,%edx
  10814f:	b8 08 50 18 00       	mov    $0x185008,%eax
  108154:	83 e8 01             	sub    $0x1,%eax
  108157:	c1 e8 0c             	shr    $0xc,%eax
  10815a:	c1 e0 03             	shl    $0x3,%eax
  10815d:	8d 04 02             	lea    (%edx,%eax,1),%eax
  108160:	3b 45 f8             	cmp    0xfffffff8(%ebp),%eax
  108163:	72 24                	jb     108189 <pmap_merge+0x3f3>
  108165:	c7 44 24 0c 84 d3 10 	movl   $0x10d384,0xc(%esp)
  10816c:	00 
  10816d:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  108174:	00 
  108175:	c7 44 24 04 ae 00 00 	movl   $0xae,0x4(%esp)
  10817c:	00 
  10817d:	c7 04 24 57 d3 10 00 	movl   $0x10d357,(%esp)
  108184:	e8 af 87 ff ff       	call   100938 <debug_panic>
  108189:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10818c:	83 c0 04             	add    $0x4,%eax
  10818f:	c7 44 24 04 ff ff ff 	movl   $0xffffffff,0x4(%esp)
  108196:	ff 
  108197:	89 04 24             	mov    %eax,(%esp)
  10819a:	e8 dc e1 ff ff       	call   10637b <lockaddz>
  10819f:	84 c0                	test   %al,%al
  1081a1:	74 0b                	je     1081ae <pmap_merge+0x418>
  1081a3:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1081a6:	89 04 24             	mov    %eax,(%esp)
  1081a9:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  1081ac:	ff d0                	call   *%eax
  1081ae:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1081b1:	8b 40 04             	mov    0x4(%eax),%eax
  1081b4:	85 c0                	test   %eax,%eax
  1081b6:	79 24                	jns    1081dc <pmap_merge+0x446>
  1081b8:	c7 44 24 0c b5 d3 10 	movl   $0x10d3b5,0xc(%esp)
  1081bf:	00 
  1081c0:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  1081c7:	00 
  1081c8:	c7 44 24 04 b5 00 00 	movl   $0xb5,0x4(%esp)
  1081cf:	00 
  1081d0:	c7 04 24 57 d3 10 00 	movl   $0x10d357,(%esp)
  1081d7:	e8 5c 87 ff ff       	call   100938 <debug_panic>
  1081dc:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  1081df:	8b 00                	mov    (%eax),%eax
  1081e1:	89 c2                	mov    %eax,%edx
  1081e3:	83 e2 fd             	and    $0xfffffffd,%edx
  1081e6:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  1081e9:	89 10                	mov    %edx,(%eax)
  1081eb:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  1081ee:	8b 10                	mov    (%eax),%edx
  1081f0:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  1081f3:	89 10                	mov    %edx,(%eax)
  1081f5:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  1081f8:	8b 00                	mov    (%eax),%eax
  1081fa:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1081ff:	c1 e8 0c             	shr    $0xc,%eax
  108202:	c1 e0 03             	shl    $0x3,%eax
  108205:	89 c2                	mov    %eax,%edx
  108207:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  10820c:	8d 04 02             	lea    (%edx,%eax,1),%eax
  10820f:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  108212:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  108217:	83 c0 08             	add    $0x8,%eax
  10821a:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  10821d:	73 17                	jae    108236 <pmap_merge+0x4a0>
  10821f:	a1 d8 1d 18 00       	mov    0x181dd8,%eax
  108224:	c1 e0 03             	shl    $0x3,%eax
  108227:	89 c2                	mov    %eax,%edx
  108229:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  10822e:	8d 04 02             	lea    (%edx,%eax,1),%eax
  108231:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  108234:	77 24                	ja     10825a <pmap_merge+0x4c4>
  108236:	c7 44 24 0c 20 d3 10 	movl   $0x10d320,0xc(%esp)
  10823d:	00 
  10823e:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  108245:	00 
  108246:	c7 44 24 04 9c 00 00 	movl   $0x9c,0x4(%esp)
  10824d:	00 
  10824e:	c7 04 24 57 d3 10 00 	movl   $0x10d357,(%esp)
  108255:	e8 de 86 ff ff       	call   100938 <debug_panic>
  10825a:	8b 15 e0 1d 18 00    	mov    0x181de0,%edx
  108260:	b8 00 40 18 00       	mov    $0x184000,%eax
  108265:	c1 e8 0c             	shr    $0xc,%eax
  108268:	c1 e0 03             	shl    $0x3,%eax
  10826b:	8d 04 02             	lea    (%edx,%eax,1),%eax
  10826e:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  108271:	75 24                	jne    108297 <pmap_merge+0x501>
  108273:	c7 44 24 0c 65 d3 10 	movl   $0x10d365,0xc(%esp)
  10827a:	00 
  10827b:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  108282:	00 
  108283:	c7 44 24 04 9e 00 00 	movl   $0x9e,0x4(%esp)
  10828a:	00 
  10828b:	c7 04 24 57 d3 10 00 	movl   $0x10d357,(%esp)
  108292:	e8 a1 86 ff ff       	call   100938 <debug_panic>
  108297:	8b 15 e0 1d 18 00    	mov    0x181de0,%edx
  10829d:	b8 0c 00 10 00       	mov    $0x10000c,%eax
  1082a2:	c1 e8 0c             	shr    $0xc,%eax
  1082a5:	c1 e0 03             	shl    $0x3,%eax
  1082a8:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1082ab:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  1082ae:	77 40                	ja     1082f0 <pmap_merge+0x55a>
  1082b0:	8b 15 e0 1d 18 00    	mov    0x181de0,%edx
  1082b6:	b8 08 50 18 00       	mov    $0x185008,%eax
  1082bb:	83 e8 01             	sub    $0x1,%eax
  1082be:	c1 e8 0c             	shr    $0xc,%eax
  1082c1:	c1 e0 03             	shl    $0x3,%eax
  1082c4:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1082c7:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  1082ca:	72 24                	jb     1082f0 <pmap_merge+0x55a>
  1082cc:	c7 44 24 0c 84 d3 10 	movl   $0x10d384,0xc(%esp)
  1082d3:	00 
  1082d4:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  1082db:	00 
  1082dc:	c7 44 24 04 a0 00 00 	movl   $0xa0,0x4(%esp)
  1082e3:	00 
  1082e4:	c7 04 24 57 d3 10 00 	movl   $0x10d357,(%esp)
  1082eb:	e8 48 86 ff ff       	call   100938 <debug_panic>
  1082f0:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  1082f3:	83 c0 04             	add    $0x4,%eax
  1082f6:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  1082fd:	00 
  1082fe:	89 04 24             	mov    %eax,(%esp)
  108301:	e8 78 de ff ff       	call   10617e <lockadd>
  108306:	eb 20                	jmp    108328 <pmap_merge+0x592>
  108308:	8b 45 18             	mov    0x18(%ebp),%eax
  10830b:	89 44 24 0c          	mov    %eax,0xc(%esp)
  10830f:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  108312:	89 44 24 08          	mov    %eax,0x8(%esp)
  108316:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  108319:	89 44 24 04          	mov    %eax,0x4(%esp)
  10831d:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  108320:	89 04 24             	mov    %eax,(%esp)
  108323:	e8 62 f5 ff ff       	call   10788a <pmap_mergepage>
  108328:	83 45 e4 04          	addl   $0x4,0xffffffe4(%ebp)
  10832c:	83 45 e8 04          	addl   $0x4,0xffffffe8(%ebp)
  108330:	83 45 ec 04          	addl   $0x4,0xffffffec(%ebp)
  108334:	81 45 10 00 10 00 00 	addl   $0x1000,0x10(%ebp)
  10833b:	81 45 18 00 10 00 00 	addl   $0x1000,0x18(%ebp)
  108342:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  108345:	3b 45 f0             	cmp    0xfffffff0(%ebp),%eax
  108348:	0f 82 fb fc ff ff    	jb     108049 <pmap_merge+0x2b3>
  10834e:	83 45 d4 04          	addl   $0x4,0xffffffd4(%ebp)
  108352:	83 45 d8 04          	addl   $0x4,0xffffffd8(%ebp)
  108356:	83 45 dc 04          	addl   $0x4,0xffffffdc(%ebp)
  10835a:	8b 45 10             	mov    0x10(%ebp),%eax
  10835d:	3b 45 e0             	cmp    0xffffffe0(%ebp),%eax
  108360:	0f 82 10 fc ff ff    	jb     107f76 <pmap_merge+0x1e0>
  108366:	c7 45 cc 01 00 00 00 	movl   $0x1,0xffffffcc(%ebp)
  10836d:	8b 45 cc             	mov    0xffffffcc(%ebp),%eax
  108370:	c9                   	leave  
  108371:	c3                   	ret    

00108372 <pmap_setperm>:
  108372:	55                   	push   %ebp
  108373:	89 e5                	mov    %esp,%ebp
  108375:	83 ec 38             	sub    $0x38,%esp
  108378:	8b 45 0c             	mov    0xc(%ebp),%eax
  10837b:	25 ff 0f 00 00       	and    $0xfff,%eax
  108380:	85 c0                	test   %eax,%eax
  108382:	74 24                	je     1083a8 <pmap_setperm+0x36>
  108384:	c7 44 24 0c c4 d5 10 	movl   $0x10d5c4,0xc(%esp)
  10838b:	00 
  10838c:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  108393:	00 
  108394:	c7 44 24 04 6f 02 00 	movl   $0x26f,0x4(%esp)
  10839b:	00 
  10839c:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  1083a3:	e8 90 85 ff ff       	call   100938 <debug_panic>
  1083a8:	8b 45 10             	mov    0x10(%ebp),%eax
  1083ab:	25 ff 0f 00 00       	and    $0xfff,%eax
  1083b0:	85 c0                	test   %eax,%eax
  1083b2:	74 24                	je     1083d8 <pmap_setperm+0x66>
  1083b4:	c7 44 24 0c 1b d4 10 	movl   $0x10d41b,0xc(%esp)
  1083bb:	00 
  1083bc:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  1083c3:	00 
  1083c4:	c7 44 24 04 70 02 00 	movl   $0x270,0x4(%esp)
  1083cb:	00 
  1083cc:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  1083d3:	e8 60 85 ff ff       	call   100938 <debug_panic>
  1083d8:	81 7d 0c ff ff ff 3f 	cmpl   $0x3fffffff,0xc(%ebp)
  1083df:	76 09                	jbe    1083ea <pmap_setperm+0x78>
  1083e1:	81 7d 0c ff ff ff ef 	cmpl   $0xefffffff,0xc(%ebp)
  1083e8:	76 24                	jbe    10840e <pmap_setperm+0x9c>
  1083ea:	c7 44 24 0c c8 d3 10 	movl   $0x10d3c8,0xc(%esp)
  1083f1:	00 
  1083f2:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  1083f9:	00 
  1083fa:	c7 44 24 04 71 02 00 	movl   $0x271,0x4(%esp)
  108401:	00 
  108402:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  108409:	e8 2a 85 ff ff       	call   100938 <debug_panic>
  10840e:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
  108413:	2b 45 0c             	sub    0xc(%ebp),%eax
  108416:	3b 45 10             	cmp    0x10(%ebp),%eax
  108419:	73 24                	jae    10843f <pmap_setperm+0xcd>
  10841b:	c7 44 24 0c 2c d4 10 	movl   $0x10d42c,0xc(%esp)
  108422:	00 
  108423:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  10842a:	00 
  10842b:	c7 44 24 04 72 02 00 	movl   $0x272,0x4(%esp)
  108432:	00 
  108433:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  10843a:	e8 f9 84 ff ff       	call   100938 <debug_panic>
  10843f:	8b 45 14             	mov    0x14(%ebp),%eax
  108442:	80 e4 f9             	and    $0xf9,%ah
  108445:	85 c0                	test   %eax,%eax
  108447:	74 24                	je     10846d <pmap_setperm+0xfb>
  108449:	c7 44 24 0c d3 d5 10 	movl   $0x10d5d3,0xc(%esp)
  108450:	00 
  108451:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  108458:	00 
  108459:	c7 44 24 04 73 02 00 	movl   $0x273,0x4(%esp)
  108460:	00 
  108461:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  108468:	e8 cb 84 ff ff       	call   100938 <debug_panic>
  10846d:	8b 45 10             	mov    0x10(%ebp),%eax
  108470:	89 44 24 08          	mov    %eax,0x8(%esp)
  108474:	8b 45 0c             	mov    0xc(%ebp),%eax
  108477:	89 44 24 04          	mov    %eax,0x4(%esp)
  10847b:	8b 45 08             	mov    0x8(%ebp),%eax
  10847e:	89 04 24             	mov    %eax,(%esp)
  108481:	e8 dd eb ff ff       	call   107063 <pmap_inval>
  108486:	8b 45 14             	mov    0x14(%ebp),%eax
  108489:	25 00 02 00 00       	and    $0x200,%eax
  10848e:	85 c0                	test   %eax,%eax
  108490:	75 10                	jne    1084a2 <pmap_setperm+0x130>
  108492:	c7 45 ec fc f9 ff ff 	movl   $0xfffff9fc,0xffffffec(%ebp)
  108499:	c7 45 f0 00 00 00 00 	movl   $0x0,0xfffffff0(%ebp)
  1084a0:	eb 2a                	jmp    1084cc <pmap_setperm+0x15a>
  1084a2:	8b 45 14             	mov    0x14(%ebp),%eax
  1084a5:	25 00 04 00 00       	and    $0x400,%eax
  1084aa:	85 c0                	test   %eax,%eax
  1084ac:	75 10                	jne    1084be <pmap_setperm+0x14c>
  1084ae:	c7 45 ec fd fb ff ff 	movl   $0xfffffbfd,0xffffffec(%ebp)
  1084b5:	c7 45 f0 25 02 00 00 	movl   $0x225,0xfffffff0(%ebp)
  1084bc:	eb 0e                	jmp    1084cc <pmap_setperm+0x15a>
  1084be:	c7 45 ec ff ff ff ff 	movl   $0xffffffff,0xffffffec(%ebp)
  1084c5:	c7 45 f0 65 06 00 00 	movl   $0x665,0xfffffff0(%ebp)
  1084cc:	8b 45 10             	mov    0x10(%ebp),%eax
  1084cf:	03 45 0c             	add    0xc(%ebp),%eax
  1084d2:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
  1084d5:	e9 9a 00 00 00       	jmp    108574 <pmap_setperm+0x202>
  1084da:	8b 45 0c             	mov    0xc(%ebp),%eax
  1084dd:	c1 e8 16             	shr    $0x16,%eax
  1084e0:	25 ff 03 00 00       	and    $0x3ff,%eax
  1084e5:	c1 e0 02             	shl    $0x2,%eax
  1084e8:	03 45 08             	add    0x8(%ebp),%eax
  1084eb:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  1084ee:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1084f1:	8b 10                	mov    (%eax),%edx
  1084f3:	b8 00 40 18 00       	mov    $0x184000,%eax
  1084f8:	39 c2                	cmp    %eax,%edx
  1084fa:	75 18                	jne    108514 <pmap_setperm+0x1a2>
  1084fc:	83 7d f0 00          	cmpl   $0x0,0xfffffff0(%ebp)
  108500:	75 12                	jne    108514 <pmap_setperm+0x1a2>
  108502:	8b 45 0c             	mov    0xc(%ebp),%eax
  108505:	05 00 00 40 00       	add    $0x400000,%eax
  10850a:	25 00 00 c0 ff       	and    $0xffc00000,%eax
  10850f:	89 45 0c             	mov    %eax,0xc(%ebp)
  108512:	eb 60                	jmp    108574 <pmap_setperm+0x202>
  108514:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
  10851b:	00 
  10851c:	8b 45 0c             	mov    0xc(%ebp),%eax
  10851f:	89 44 24 04          	mov    %eax,0x4(%esp)
  108523:	8b 45 08             	mov    0x8(%ebp),%eax
  108526:	89 04 24             	mov    %eax,(%esp)
  108529:	e8 69 de ff ff       	call   106397 <pmap_walk>
  10852e:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  108531:	83 7d fc 00          	cmpl   $0x0,0xfffffffc(%ebp)
  108535:	75 09                	jne    108540 <pmap_setperm+0x1ce>
  108537:	c7 45 dc 00 00 00 00 	movl   $0x0,0xffffffdc(%ebp)
  10853e:	eb 47                	jmp    108587 <pmap_setperm+0x215>
  108540:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  108543:	8b 00                	mov    (%eax),%eax
  108545:	23 45 ec             	and    0xffffffec(%ebp),%eax
  108548:	89 c2                	mov    %eax,%edx
  10854a:	0b 55 f0             	or     0xfffffff0(%ebp),%edx
  10854d:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  108550:	89 10                	mov    %edx,(%eax)
  108552:	83 45 fc 04          	addl   $0x4,0xfffffffc(%ebp)
  108556:	81 45 0c 00 10 00 00 	addl   $0x1000,0xc(%ebp)
  10855d:	8b 45 0c             	mov    0xc(%ebp),%eax
  108560:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  108563:	73 0f                	jae    108574 <pmap_setperm+0x202>
  108565:	8b 45 0c             	mov    0xc(%ebp),%eax
  108568:	c1 e8 0c             	shr    $0xc,%eax
  10856b:	25 ff 03 00 00       	and    $0x3ff,%eax
  108570:	85 c0                	test   %eax,%eax
  108572:	75 cc                	jne    108540 <pmap_setperm+0x1ce>
  108574:	8b 45 0c             	mov    0xc(%ebp),%eax
  108577:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  10857a:	0f 82 5a ff ff ff    	jb     1084da <pmap_setperm+0x168>
  108580:	c7 45 dc 01 00 00 00 	movl   $0x1,0xffffffdc(%ebp)
  108587:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  10858a:	c9                   	leave  
  10858b:	c3                   	ret    

0010858c <va2pa>:
  10858c:	55                   	push   %ebp
  10858d:	89 e5                	mov    %esp,%ebp
  10858f:	83 ec 14             	sub    $0x14,%esp
  108592:	8b 45 0c             	mov    0xc(%ebp),%eax
  108595:	c1 e8 16             	shr    $0x16,%eax
  108598:	25 ff 03 00 00       	and    $0x3ff,%eax
  10859d:	c1 e0 02             	shl    $0x2,%eax
  1085a0:	01 45 08             	add    %eax,0x8(%ebp)
  1085a3:	8b 45 08             	mov    0x8(%ebp),%eax
  1085a6:	8b 00                	mov    (%eax),%eax
  1085a8:	83 e0 01             	and    $0x1,%eax
  1085ab:	85 c0                	test   %eax,%eax
  1085ad:	75 09                	jne    1085b8 <va2pa+0x2c>
  1085af:	c7 45 ec ff ff ff ff 	movl   $0xffffffff,0xffffffec(%ebp)
  1085b6:	eb 4e                	jmp    108606 <va2pa+0x7a>
  1085b8:	8b 45 08             	mov    0x8(%ebp),%eax
  1085bb:	8b 00                	mov    (%eax),%eax
  1085bd:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1085c2:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  1085c5:	8b 45 0c             	mov    0xc(%ebp),%eax
  1085c8:	c1 e8 0c             	shr    $0xc,%eax
  1085cb:	25 ff 03 00 00       	and    $0x3ff,%eax
  1085d0:	c1 e0 02             	shl    $0x2,%eax
  1085d3:	03 45 fc             	add    0xfffffffc(%ebp),%eax
  1085d6:	8b 00                	mov    (%eax),%eax
  1085d8:	83 e0 01             	and    $0x1,%eax
  1085db:	85 c0                	test   %eax,%eax
  1085dd:	75 09                	jne    1085e8 <va2pa+0x5c>
  1085df:	c7 45 ec ff ff ff ff 	movl   $0xffffffff,0xffffffec(%ebp)
  1085e6:	eb 1e                	jmp    108606 <va2pa+0x7a>
  1085e8:	8b 45 0c             	mov    0xc(%ebp),%eax
  1085eb:	c1 e8 0c             	shr    $0xc,%eax
  1085ee:	25 ff 03 00 00       	and    $0x3ff,%eax
  1085f3:	c1 e0 02             	shl    $0x2,%eax
  1085f6:	03 45 fc             	add    0xfffffffc(%ebp),%eax
  1085f9:	8b 00                	mov    (%eax),%eax
  1085fb:	89 c2                	mov    %eax,%edx
  1085fd:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
  108603:	89 55 ec             	mov    %edx,0xffffffec(%ebp)
  108606:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  108609:	c9                   	leave  
  10860a:	c3                   	ret    

0010860b <pmap_check>:
  10860b:	55                   	push   %ebp
  10860c:	89 e5                	mov    %esp,%ebp
  10860e:	53                   	push   %ebx
  10860f:	83 ec 44             	sub    $0x44,%esp
  108612:	c7 45 e0 00 00 00 00 	movl   $0x0,0xffffffe0(%ebp)
  108619:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  10861c:	89 45 dc             	mov    %eax,0xffffffdc(%ebp)
  10861f:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  108622:	89 45 d8             	mov    %eax,0xffffffd8(%ebp)
  108625:	e8 3b 8e ff ff       	call   101465 <mem_alloc>
  10862a:	89 45 d8             	mov    %eax,0xffffffd8(%ebp)
  10862d:	e8 33 8e ff ff       	call   101465 <mem_alloc>
  108632:	89 45 dc             	mov    %eax,0xffffffdc(%ebp)
  108635:	e8 2b 8e ff ff       	call   101465 <mem_alloc>
  10863a:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)
  10863d:	e8 23 8e ff ff       	call   101465 <mem_alloc>
  108642:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
  108645:	83 7d d8 00          	cmpl   $0x0,0xffffffd8(%ebp)
  108649:	75 24                	jne    10866f <pmap_check+0x64>
  10864b:	c7 44 24 0c eb d5 10 	movl   $0x10d5eb,0xc(%esp)
  108652:	00 
  108653:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  10865a:	00 
  10865b:	c7 44 24 04 c0 02 00 	movl   $0x2c0,0x4(%esp)
  108662:	00 
  108663:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  10866a:	e8 c9 82 ff ff       	call   100938 <debug_panic>
  10866f:	83 7d dc 00          	cmpl   $0x0,0xffffffdc(%ebp)
  108673:	74 08                	je     10867d <pmap_check+0x72>
  108675:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  108678:	3b 45 d8             	cmp    0xffffffd8(%ebp),%eax
  10867b:	75 24                	jne    1086a1 <pmap_check+0x96>
  10867d:	c7 44 24 0c ef d5 10 	movl   $0x10d5ef,0xc(%esp)
  108684:	00 
  108685:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  10868c:	00 
  10868d:	c7 44 24 04 c1 02 00 	movl   $0x2c1,0x4(%esp)
  108694:	00 
  108695:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  10869c:	e8 97 82 ff ff       	call   100938 <debug_panic>
  1086a1:	83 7d e0 00          	cmpl   $0x0,0xffffffe0(%ebp)
  1086a5:	74 10                	je     1086b7 <pmap_check+0xac>
  1086a7:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  1086aa:	3b 45 dc             	cmp    0xffffffdc(%ebp),%eax
  1086ad:	74 08                	je     1086b7 <pmap_check+0xac>
  1086af:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  1086b2:	3b 45 d8             	cmp    0xffffffd8(%ebp),%eax
  1086b5:	75 24                	jne    1086db <pmap_check+0xd0>
  1086b7:	c7 44 24 0c 04 d6 10 	movl   $0x10d604,0xc(%esp)
  1086be:	00 
  1086bf:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  1086c6:	00 
  1086c7:	c7 44 24 04 c2 02 00 	movl   $0x2c2,0x4(%esp)
  1086ce:	00 
  1086cf:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  1086d6:	e8 5d 82 ff ff       	call   100938 <debug_panic>
  1086db:	a1 80 1d 18 00       	mov    0x181d80,%eax
  1086e0:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  1086e3:	c7 05 80 1d 18 00 00 	movl   $0x0,0x181d80
  1086ea:	00 00 00 
  1086ed:	e8 73 8d ff ff       	call   101465 <mem_alloc>
  1086f2:	85 c0                	test   %eax,%eax
  1086f4:	74 24                	je     10871a <pmap_check+0x10f>
  1086f6:	c7 44 24 0c 24 d6 10 	movl   $0x10d624,0xc(%esp)
  1086fd:	00 
  1086fe:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  108705:	00 
  108706:	c7 44 24 04 c9 02 00 	movl   $0x2c9,0x4(%esp)
  10870d:	00 
  10870e:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  108715:	e8 1e 82 ff ff       	call   100938 <debug_panic>
  10871a:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  108721:	00 
  108722:	c7 44 24 08 00 00 00 	movl   $0x40000000,0x8(%esp)
  108729:	40 
  10872a:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  10872d:	89 44 24 04          	mov    %eax,0x4(%esp)
  108731:	c7 04 24 00 30 18 00 	movl   $0x183000,(%esp)
  108738:	e8 12 e3 ff ff       	call   106a4f <pmap_insert>
  10873d:	85 c0                	test   %eax,%eax
  10873f:	74 24                	je     108765 <pmap_check+0x15a>
  108741:	c7 44 24 0c 38 d6 10 	movl   $0x10d638,0xc(%esp)
  108748:	00 
  108749:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  108750:	00 
  108751:	c7 44 24 04 cc 02 00 	movl   $0x2cc,0x4(%esp)
  108758:	00 
  108759:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  108760:	e8 d3 81 ff ff       	call   100938 <debug_panic>
  108765:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  108768:	89 04 24             	mov    %eax,(%esp)
  10876b:	e8 39 8d ff ff       	call   1014a9 <mem_free>
  108770:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  108777:	00 
  108778:	c7 44 24 08 00 00 00 	movl   $0x40000000,0x8(%esp)
  10877f:	40 
  108780:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  108783:	89 44 24 04          	mov    %eax,0x4(%esp)
  108787:	c7 04 24 00 30 18 00 	movl   $0x183000,(%esp)
  10878e:	e8 bc e2 ff ff       	call   106a4f <pmap_insert>
  108793:	85 c0                	test   %eax,%eax
  108795:	75 24                	jne    1087bb <pmap_check+0x1b0>
  108797:	c7 44 24 0c 70 d6 10 	movl   $0x10d670,0xc(%esp)
  10879e:	00 
  10879f:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  1087a6:	00 
  1087a7:	c7 44 24 04 d0 02 00 	movl   $0x2d0,0x4(%esp)
  1087ae:	00 
  1087af:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  1087b6:	e8 7d 81 ff ff       	call   100938 <debug_panic>
  1087bb:	a1 00 34 18 00       	mov    0x183400,%eax
  1087c0:	89 c1                	mov    %eax,%ecx
  1087c2:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
  1087c8:	8b 55 d8             	mov    0xffffffd8(%ebp),%edx
  1087cb:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  1087d0:	89 d3                	mov    %edx,%ebx
  1087d2:	29 c3                	sub    %eax,%ebx
  1087d4:	89 d8                	mov    %ebx,%eax
  1087d6:	c1 e0 09             	shl    $0x9,%eax
  1087d9:	39 c1                	cmp    %eax,%ecx
  1087db:	74 24                	je     108801 <pmap_check+0x1f6>
  1087dd:	c7 44 24 0c a8 d6 10 	movl   $0x10d6a8,0xc(%esp)
  1087e4:	00 
  1087e5:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  1087ec:	00 
  1087ed:	c7 44 24 04 d1 02 00 	movl   $0x2d1,0x4(%esp)
  1087f4:	00 
  1087f5:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  1087fc:	e8 37 81 ff ff       	call   100938 <debug_panic>
  108801:	c7 44 24 04 00 00 00 	movl   $0x40000000,0x4(%esp)
  108808:	40 
  108809:	c7 04 24 00 30 18 00 	movl   $0x183000,(%esp)
  108810:	e8 77 fd ff ff       	call   10858c <va2pa>
  108815:	89 c1                	mov    %eax,%ecx
  108817:	8b 55 dc             	mov    0xffffffdc(%ebp),%edx
  10881a:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  10881f:	89 d3                	mov    %edx,%ebx
  108821:	29 c3                	sub    %eax,%ebx
  108823:	89 d8                	mov    %ebx,%eax
  108825:	c1 e0 09             	shl    $0x9,%eax
  108828:	39 c1                	cmp    %eax,%ecx
  10882a:	74 24                	je     108850 <pmap_check+0x245>
  10882c:	c7 44 24 0c e4 d6 10 	movl   $0x10d6e4,0xc(%esp)
  108833:	00 
  108834:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  10883b:	00 
  10883c:	c7 44 24 04 d2 02 00 	movl   $0x2d2,0x4(%esp)
  108843:	00 
  108844:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  10884b:	e8 e8 80 ff ff       	call   100938 <debug_panic>
  108850:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  108853:	8b 40 04             	mov    0x4(%eax),%eax
  108856:	83 f8 01             	cmp    $0x1,%eax
  108859:	74 24                	je     10887f <pmap_check+0x274>
  10885b:	c7 44 24 0c 18 d7 10 	movl   $0x10d718,0xc(%esp)
  108862:	00 
  108863:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  10886a:	00 
  10886b:	c7 44 24 04 d3 02 00 	movl   $0x2d3,0x4(%esp)
  108872:	00 
  108873:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  10887a:	e8 b9 80 ff ff       	call   100938 <debug_panic>
  10887f:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  108882:	8b 40 04             	mov    0x4(%eax),%eax
  108885:	83 f8 01             	cmp    $0x1,%eax
  108888:	74 24                	je     1088ae <pmap_check+0x2a3>
  10888a:	c7 44 24 0c 2b d7 10 	movl   $0x10d72b,0xc(%esp)
  108891:	00 
  108892:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  108899:	00 
  10889a:	c7 44 24 04 d4 02 00 	movl   $0x2d4,0x4(%esp)
  1088a1:	00 
  1088a2:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  1088a9:	e8 8a 80 ff ff       	call   100938 <debug_panic>
  1088ae:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  1088b5:	00 
  1088b6:	c7 44 24 08 00 10 00 	movl   $0x40001000,0x8(%esp)
  1088bd:	40 
  1088be:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  1088c1:	89 44 24 04          	mov    %eax,0x4(%esp)
  1088c5:	c7 04 24 00 30 18 00 	movl   $0x183000,(%esp)
  1088cc:	e8 7e e1 ff ff       	call   106a4f <pmap_insert>
  1088d1:	85 c0                	test   %eax,%eax
  1088d3:	75 24                	jne    1088f9 <pmap_check+0x2ee>
  1088d5:	c7 44 24 0c 40 d7 10 	movl   $0x10d740,0xc(%esp)
  1088dc:	00 
  1088dd:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  1088e4:	00 
  1088e5:	c7 44 24 04 d8 02 00 	movl   $0x2d8,0x4(%esp)
  1088ec:	00 
  1088ed:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  1088f4:	e8 3f 80 ff ff       	call   100938 <debug_panic>
  1088f9:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  108900:	40 
  108901:	c7 04 24 00 30 18 00 	movl   $0x183000,(%esp)
  108908:	e8 7f fc ff ff       	call   10858c <va2pa>
  10890d:	89 c1                	mov    %eax,%ecx
  10890f:	8b 55 e0             	mov    0xffffffe0(%ebp),%edx
  108912:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  108917:	89 d3                	mov    %edx,%ebx
  108919:	29 c3                	sub    %eax,%ebx
  10891b:	89 d8                	mov    %ebx,%eax
  10891d:	c1 e0 09             	shl    $0x9,%eax
  108920:	39 c1                	cmp    %eax,%ecx
  108922:	74 24                	je     108948 <pmap_check+0x33d>
  108924:	c7 44 24 0c 78 d7 10 	movl   $0x10d778,0xc(%esp)
  10892b:	00 
  10892c:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  108933:	00 
  108934:	c7 44 24 04 d9 02 00 	movl   $0x2d9,0x4(%esp)
  10893b:	00 
  10893c:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  108943:	e8 f0 7f ff ff       	call   100938 <debug_panic>
  108948:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  10894b:	8b 40 04             	mov    0x4(%eax),%eax
  10894e:	83 f8 01             	cmp    $0x1,%eax
  108951:	74 24                	je     108977 <pmap_check+0x36c>
  108953:	c7 44 24 0c b5 d7 10 	movl   $0x10d7b5,0xc(%esp)
  10895a:	00 
  10895b:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  108962:	00 
  108963:	c7 44 24 04 da 02 00 	movl   $0x2da,0x4(%esp)
  10896a:	00 
  10896b:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  108972:	e8 c1 7f ff ff       	call   100938 <debug_panic>
  108977:	e8 e9 8a ff ff       	call   101465 <mem_alloc>
  10897c:	85 c0                	test   %eax,%eax
  10897e:	74 24                	je     1089a4 <pmap_check+0x399>
  108980:	c7 44 24 0c 24 d6 10 	movl   $0x10d624,0xc(%esp)
  108987:	00 
  108988:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  10898f:	00 
  108990:	c7 44 24 04 dd 02 00 	movl   $0x2dd,0x4(%esp)
  108997:	00 
  108998:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  10899f:	e8 94 7f ff ff       	call   100938 <debug_panic>
  1089a4:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  1089ab:	00 
  1089ac:	c7 44 24 08 00 10 00 	movl   $0x40001000,0x8(%esp)
  1089b3:	40 
  1089b4:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  1089b7:	89 44 24 04          	mov    %eax,0x4(%esp)
  1089bb:	c7 04 24 00 30 18 00 	movl   $0x183000,(%esp)
  1089c2:	e8 88 e0 ff ff       	call   106a4f <pmap_insert>
  1089c7:	85 c0                	test   %eax,%eax
  1089c9:	75 24                	jne    1089ef <pmap_check+0x3e4>
  1089cb:	c7 44 24 0c 40 d7 10 	movl   $0x10d740,0xc(%esp)
  1089d2:	00 
  1089d3:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  1089da:	00 
  1089db:	c7 44 24 04 e1 02 00 	movl   $0x2e1,0x4(%esp)
  1089e2:	00 
  1089e3:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  1089ea:	e8 49 7f ff ff       	call   100938 <debug_panic>
  1089ef:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  1089f6:	40 
  1089f7:	c7 04 24 00 30 18 00 	movl   $0x183000,(%esp)
  1089fe:	e8 89 fb ff ff       	call   10858c <va2pa>
  108a03:	89 c1                	mov    %eax,%ecx
  108a05:	8b 55 e0             	mov    0xffffffe0(%ebp),%edx
  108a08:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  108a0d:	89 d3                	mov    %edx,%ebx
  108a0f:	29 c3                	sub    %eax,%ebx
  108a11:	89 d8                	mov    %ebx,%eax
  108a13:	c1 e0 09             	shl    $0x9,%eax
  108a16:	39 c1                	cmp    %eax,%ecx
  108a18:	74 24                	je     108a3e <pmap_check+0x433>
  108a1a:	c7 44 24 0c 78 d7 10 	movl   $0x10d778,0xc(%esp)
  108a21:	00 
  108a22:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  108a29:	00 
  108a2a:	c7 44 24 04 e2 02 00 	movl   $0x2e2,0x4(%esp)
  108a31:	00 
  108a32:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  108a39:	e8 fa 7e ff ff       	call   100938 <debug_panic>
  108a3e:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  108a41:	8b 40 04             	mov    0x4(%eax),%eax
  108a44:	83 f8 01             	cmp    $0x1,%eax
  108a47:	74 24                	je     108a6d <pmap_check+0x462>
  108a49:	c7 44 24 0c b5 d7 10 	movl   $0x10d7b5,0xc(%esp)
  108a50:	00 
  108a51:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  108a58:	00 
  108a59:	c7 44 24 04 e3 02 00 	movl   $0x2e3,0x4(%esp)
  108a60:	00 
  108a61:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  108a68:	e8 cb 7e ff ff       	call   100938 <debug_panic>
  108a6d:	e8 f3 89 ff ff       	call   101465 <mem_alloc>
  108a72:	85 c0                	test   %eax,%eax
  108a74:	74 24                	je     108a9a <pmap_check+0x48f>
  108a76:	c7 44 24 0c 24 d6 10 	movl   $0x10d624,0xc(%esp)
  108a7d:	00 
  108a7e:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  108a85:	00 
  108a86:	c7 44 24 04 e7 02 00 	movl   $0x2e7,0x4(%esp)
  108a8d:	00 
  108a8e:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  108a95:	e8 9e 7e ff ff       	call   100938 <debug_panic>
  108a9a:	a1 00 34 18 00       	mov    0x183400,%eax
  108a9f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  108aa4:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  108aa7:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  108aae:	00 
  108aaf:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  108ab6:	40 
  108ab7:	c7 04 24 00 30 18 00 	movl   $0x183000,(%esp)
  108abe:	e8 d4 d8 ff ff       	call   106397 <pmap_walk>
  108ac3:	89 c2                	mov    %eax,%edx
  108ac5:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  108ac8:	83 c0 04             	add    $0x4,%eax
  108acb:	39 c2                	cmp    %eax,%edx
  108acd:	74 24                	je     108af3 <pmap_check+0x4e8>
  108acf:	c7 44 24 0c c8 d7 10 	movl   $0x10d7c8,0xc(%esp)
  108ad6:	00 
  108ad7:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  108ade:	00 
  108adf:	c7 44 24 04 ec 02 00 	movl   $0x2ec,0x4(%esp)
  108ae6:	00 
  108ae7:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  108aee:	e8 45 7e ff ff       	call   100938 <debug_panic>
  108af3:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
  108afa:	00 
  108afb:	c7 44 24 08 00 10 00 	movl   $0x40001000,0x8(%esp)
  108b02:	40 
  108b03:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  108b06:	89 44 24 04          	mov    %eax,0x4(%esp)
  108b0a:	c7 04 24 00 30 18 00 	movl   $0x183000,(%esp)
  108b11:	e8 39 df ff ff       	call   106a4f <pmap_insert>
  108b16:	85 c0                	test   %eax,%eax
  108b18:	75 24                	jne    108b3e <pmap_check+0x533>
  108b1a:	c7 44 24 0c 18 d8 10 	movl   $0x10d818,0xc(%esp)
  108b21:	00 
  108b22:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  108b29:	00 
  108b2a:	c7 44 24 04 ef 02 00 	movl   $0x2ef,0x4(%esp)
  108b31:	00 
  108b32:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  108b39:	e8 fa 7d ff ff       	call   100938 <debug_panic>
  108b3e:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  108b45:	40 
  108b46:	c7 04 24 00 30 18 00 	movl   $0x183000,(%esp)
  108b4d:	e8 3a fa ff ff       	call   10858c <va2pa>
  108b52:	89 c1                	mov    %eax,%ecx
  108b54:	8b 55 e0             	mov    0xffffffe0(%ebp),%edx
  108b57:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  108b5c:	89 d3                	mov    %edx,%ebx
  108b5e:	29 c3                	sub    %eax,%ebx
  108b60:	89 d8                	mov    %ebx,%eax
  108b62:	c1 e0 09             	shl    $0x9,%eax
  108b65:	39 c1                	cmp    %eax,%ecx
  108b67:	74 24                	je     108b8d <pmap_check+0x582>
  108b69:	c7 44 24 0c 78 d7 10 	movl   $0x10d778,0xc(%esp)
  108b70:	00 
  108b71:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  108b78:	00 
  108b79:	c7 44 24 04 f0 02 00 	movl   $0x2f0,0x4(%esp)
  108b80:	00 
  108b81:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  108b88:	e8 ab 7d ff ff       	call   100938 <debug_panic>
  108b8d:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  108b90:	8b 40 04             	mov    0x4(%eax),%eax
  108b93:	83 f8 01             	cmp    $0x1,%eax
  108b96:	74 24                	je     108bbc <pmap_check+0x5b1>
  108b98:	c7 44 24 0c b5 d7 10 	movl   $0x10d7b5,0xc(%esp)
  108b9f:	00 
  108ba0:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  108ba7:	00 
  108ba8:	c7 44 24 04 f1 02 00 	movl   $0x2f1,0x4(%esp)
  108baf:	00 
  108bb0:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  108bb7:	e8 7c 7d ff ff       	call   100938 <debug_panic>
  108bbc:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  108bc3:	00 
  108bc4:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  108bcb:	40 
  108bcc:	c7 04 24 00 30 18 00 	movl   $0x183000,(%esp)
  108bd3:	e8 bf d7 ff ff       	call   106397 <pmap_walk>
  108bd8:	8b 00                	mov    (%eax),%eax
  108bda:	83 e0 04             	and    $0x4,%eax
  108bdd:	85 c0                	test   %eax,%eax
  108bdf:	75 24                	jne    108c05 <pmap_check+0x5fa>
  108be1:	c7 44 24 0c 54 d8 10 	movl   $0x10d854,0xc(%esp)
  108be8:	00 
  108be9:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  108bf0:	00 
  108bf1:	c7 44 24 04 f2 02 00 	movl   $0x2f2,0x4(%esp)
  108bf8:	00 
  108bf9:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  108c00:	e8 33 7d ff ff       	call   100938 <debug_panic>
  108c05:	a1 00 34 18 00       	mov    0x183400,%eax
  108c0a:	83 e0 04             	and    $0x4,%eax
  108c0d:	85 c0                	test   %eax,%eax
  108c0f:	75 24                	jne    108c35 <pmap_check+0x62a>
  108c11:	c7 44 24 0c 90 d8 10 	movl   $0x10d890,0xc(%esp)
  108c18:	00 
  108c19:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  108c20:	00 
  108c21:	c7 44 24 04 f3 02 00 	movl   $0x2f3,0x4(%esp)
  108c28:	00 
  108c29:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  108c30:	e8 03 7d ff ff       	call   100938 <debug_panic>
  108c35:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  108c3c:	00 
  108c3d:	c7 44 24 08 00 00 40 	movl   $0x40400000,0x8(%esp)
  108c44:	40 
  108c45:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  108c48:	89 44 24 04          	mov    %eax,0x4(%esp)
  108c4c:	c7 04 24 00 30 18 00 	movl   $0x183000,(%esp)
  108c53:	e8 f7 dd ff ff       	call   106a4f <pmap_insert>
  108c58:	85 c0                	test   %eax,%eax
  108c5a:	74 24                	je     108c80 <pmap_check+0x675>
  108c5c:	c7 44 24 0c b8 d8 10 	movl   $0x10d8b8,0xc(%esp)
  108c63:	00 
  108c64:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  108c6b:	00 
  108c6c:	c7 44 24 04 f7 02 00 	movl   $0x2f7,0x4(%esp)
  108c73:	00 
  108c74:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  108c7b:	e8 b8 7c ff ff       	call   100938 <debug_panic>
  108c80:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  108c87:	00 
  108c88:	c7 44 24 08 00 10 00 	movl   $0x40001000,0x8(%esp)
  108c8f:	40 
  108c90:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  108c93:	89 44 24 04          	mov    %eax,0x4(%esp)
  108c97:	c7 04 24 00 30 18 00 	movl   $0x183000,(%esp)
  108c9e:	e8 ac dd ff ff       	call   106a4f <pmap_insert>
  108ca3:	85 c0                	test   %eax,%eax
  108ca5:	75 24                	jne    108ccb <pmap_check+0x6c0>
  108ca7:	c7 44 24 0c f8 d8 10 	movl   $0x10d8f8,0xc(%esp)
  108cae:	00 
  108caf:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  108cb6:	00 
  108cb7:	c7 44 24 04 fa 02 00 	movl   $0x2fa,0x4(%esp)
  108cbe:	00 
  108cbf:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  108cc6:	e8 6d 7c ff ff       	call   100938 <debug_panic>
  108ccb:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  108cd2:	00 
  108cd3:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  108cda:	40 
  108cdb:	c7 04 24 00 30 18 00 	movl   $0x183000,(%esp)
  108ce2:	e8 b0 d6 ff ff       	call   106397 <pmap_walk>
  108ce7:	8b 00                	mov    (%eax),%eax
  108ce9:	83 e0 04             	and    $0x4,%eax
  108cec:	85 c0                	test   %eax,%eax
  108cee:	74 24                	je     108d14 <pmap_check+0x709>
  108cf0:	c7 44 24 0c 30 d9 10 	movl   $0x10d930,0xc(%esp)
  108cf7:	00 
  108cf8:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  108cff:	00 
  108d00:	c7 44 24 04 fb 02 00 	movl   $0x2fb,0x4(%esp)
  108d07:	00 
  108d08:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  108d0f:	e8 24 7c ff ff       	call   100938 <debug_panic>
  108d14:	c7 44 24 04 00 00 00 	movl   $0x40000000,0x4(%esp)
  108d1b:	40 
  108d1c:	c7 04 24 00 30 18 00 	movl   $0x183000,(%esp)
  108d23:	e8 64 f8 ff ff       	call   10858c <va2pa>
  108d28:	89 c1                	mov    %eax,%ecx
  108d2a:	8b 55 dc             	mov    0xffffffdc(%ebp),%edx
  108d2d:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  108d32:	89 d3                	mov    %edx,%ebx
  108d34:	29 c3                	sub    %eax,%ebx
  108d36:	89 d8                	mov    %ebx,%eax
  108d38:	c1 e0 09             	shl    $0x9,%eax
  108d3b:	39 c1                	cmp    %eax,%ecx
  108d3d:	74 24                	je     108d63 <pmap_check+0x758>
  108d3f:	c7 44 24 0c 6c d9 10 	movl   $0x10d96c,0xc(%esp)
  108d46:	00 
  108d47:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  108d4e:	00 
  108d4f:	c7 44 24 04 fe 02 00 	movl   $0x2fe,0x4(%esp)
  108d56:	00 
  108d57:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  108d5e:	e8 d5 7b ff ff       	call   100938 <debug_panic>
  108d63:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  108d6a:	40 
  108d6b:	c7 04 24 00 30 18 00 	movl   $0x183000,(%esp)
  108d72:	e8 15 f8 ff ff       	call   10858c <va2pa>
  108d77:	89 c1                	mov    %eax,%ecx
  108d79:	8b 55 dc             	mov    0xffffffdc(%ebp),%edx
  108d7c:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  108d81:	89 d3                	mov    %edx,%ebx
  108d83:	29 c3                	sub    %eax,%ebx
  108d85:	89 d8                	mov    %ebx,%eax
  108d87:	c1 e0 09             	shl    $0x9,%eax
  108d8a:	39 c1                	cmp    %eax,%ecx
  108d8c:	74 24                	je     108db2 <pmap_check+0x7a7>
  108d8e:	c7 44 24 0c a4 d9 10 	movl   $0x10d9a4,0xc(%esp)
  108d95:	00 
  108d96:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  108d9d:	00 
  108d9e:	c7 44 24 04 ff 02 00 	movl   $0x2ff,0x4(%esp)
  108da5:	00 
  108da6:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  108dad:	e8 86 7b ff ff       	call   100938 <debug_panic>
  108db2:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  108db5:	8b 40 04             	mov    0x4(%eax),%eax
  108db8:	83 f8 02             	cmp    $0x2,%eax
  108dbb:	74 24                	je     108de1 <pmap_check+0x7d6>
  108dbd:	c7 44 24 0c e1 d9 10 	movl   $0x10d9e1,0xc(%esp)
  108dc4:	00 
  108dc5:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  108dcc:	00 
  108dcd:	c7 44 24 04 01 03 00 	movl   $0x301,0x4(%esp)
  108dd4:	00 
  108dd5:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  108ddc:	e8 57 7b ff ff       	call   100938 <debug_panic>
  108de1:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  108de4:	8b 40 04             	mov    0x4(%eax),%eax
  108de7:	85 c0                	test   %eax,%eax
  108de9:	74 24                	je     108e0f <pmap_check+0x804>
  108deb:	c7 44 24 0c f4 d9 10 	movl   $0x10d9f4,0xc(%esp)
  108df2:	00 
  108df3:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  108dfa:	00 
  108dfb:	c7 44 24 04 02 03 00 	movl   $0x302,0x4(%esp)
  108e02:	00 
  108e03:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  108e0a:	e8 29 7b ff ff       	call   100938 <debug_panic>
  108e0f:	e8 51 86 ff ff       	call   101465 <mem_alloc>
  108e14:	3b 45 e0             	cmp    0xffffffe0(%ebp),%eax
  108e17:	74 24                	je     108e3d <pmap_check+0x832>
  108e19:	c7 44 24 0c 07 da 10 	movl   $0x10da07,0xc(%esp)
  108e20:	00 
  108e21:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  108e28:	00 
  108e29:	c7 44 24 04 05 03 00 	movl   $0x305,0x4(%esp)
  108e30:	00 
  108e31:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  108e38:	e8 fb 7a ff ff       	call   100938 <debug_panic>
  108e3d:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  108e44:	00 
  108e45:	c7 44 24 04 00 00 00 	movl   $0x40000000,0x4(%esp)
  108e4c:	40 
  108e4d:	c7 04 24 00 30 18 00 	movl   $0x183000,(%esp)
  108e54:	e8 74 dd ff ff       	call   106bcd <pmap_remove>
  108e59:	c7 44 24 04 00 00 00 	movl   $0x40000000,0x4(%esp)
  108e60:	40 
  108e61:	c7 04 24 00 30 18 00 	movl   $0x183000,(%esp)
  108e68:	e8 1f f7 ff ff       	call   10858c <va2pa>
  108e6d:	83 f8 ff             	cmp    $0xffffffff,%eax
  108e70:	74 24                	je     108e96 <pmap_check+0x88b>
  108e72:	c7 44 24 0c 1c da 10 	movl   $0x10da1c,0xc(%esp)
  108e79:	00 
  108e7a:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  108e81:	00 
  108e82:	c7 44 24 04 09 03 00 	movl   $0x309,0x4(%esp)
  108e89:	00 
  108e8a:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  108e91:	e8 a2 7a ff ff       	call   100938 <debug_panic>
  108e96:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  108e9d:	40 
  108e9e:	c7 04 24 00 30 18 00 	movl   $0x183000,(%esp)
  108ea5:	e8 e2 f6 ff ff       	call   10858c <va2pa>
  108eaa:	89 c1                	mov    %eax,%ecx
  108eac:	8b 55 dc             	mov    0xffffffdc(%ebp),%edx
  108eaf:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  108eb4:	89 d3                	mov    %edx,%ebx
  108eb6:	29 c3                	sub    %eax,%ebx
  108eb8:	89 d8                	mov    %ebx,%eax
  108eba:	c1 e0 09             	shl    $0x9,%eax
  108ebd:	39 c1                	cmp    %eax,%ecx
  108ebf:	74 24                	je     108ee5 <pmap_check+0x8da>
  108ec1:	c7 44 24 0c a4 d9 10 	movl   $0x10d9a4,0xc(%esp)
  108ec8:	00 
  108ec9:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  108ed0:	00 
  108ed1:	c7 44 24 04 0a 03 00 	movl   $0x30a,0x4(%esp)
  108ed8:	00 
  108ed9:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  108ee0:	e8 53 7a ff ff       	call   100938 <debug_panic>
  108ee5:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  108ee8:	8b 40 04             	mov    0x4(%eax),%eax
  108eeb:	83 f8 01             	cmp    $0x1,%eax
  108eee:	74 24                	je     108f14 <pmap_check+0x909>
  108ef0:	c7 44 24 0c 18 d7 10 	movl   $0x10d718,0xc(%esp)
  108ef7:	00 
  108ef8:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  108eff:	00 
  108f00:	c7 44 24 04 0b 03 00 	movl   $0x30b,0x4(%esp)
  108f07:	00 
  108f08:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  108f0f:	e8 24 7a ff ff       	call   100938 <debug_panic>
  108f14:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  108f17:	8b 40 04             	mov    0x4(%eax),%eax
  108f1a:	85 c0                	test   %eax,%eax
  108f1c:	74 24                	je     108f42 <pmap_check+0x937>
  108f1e:	c7 44 24 0c f4 d9 10 	movl   $0x10d9f4,0xc(%esp)
  108f25:	00 
  108f26:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  108f2d:	00 
  108f2e:	c7 44 24 04 0c 03 00 	movl   $0x30c,0x4(%esp)
  108f35:	00 
  108f36:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  108f3d:	e8 f6 79 ff ff       	call   100938 <debug_panic>
  108f42:	e8 1e 85 ff ff       	call   101465 <mem_alloc>
  108f47:	85 c0                	test   %eax,%eax
  108f49:	74 24                	je     108f6f <pmap_check+0x964>
  108f4b:	c7 44 24 0c 24 d6 10 	movl   $0x10d624,0xc(%esp)
  108f52:	00 
  108f53:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  108f5a:	00 
  108f5b:	c7 44 24 04 0d 03 00 	movl   $0x30d,0x4(%esp)
  108f62:	00 
  108f63:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  108f6a:	e8 c9 79 ff ff       	call   100938 <debug_panic>
  108f6f:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  108f76:	00 
  108f77:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  108f7e:	40 
  108f7f:	c7 04 24 00 30 18 00 	movl   $0x183000,(%esp)
  108f86:	e8 42 dc ff ff       	call   106bcd <pmap_remove>
  108f8b:	c7 44 24 04 00 00 00 	movl   $0x40000000,0x4(%esp)
  108f92:	40 
  108f93:	c7 04 24 00 30 18 00 	movl   $0x183000,(%esp)
  108f9a:	e8 ed f5 ff ff       	call   10858c <va2pa>
  108f9f:	83 f8 ff             	cmp    $0xffffffff,%eax
  108fa2:	74 24                	je     108fc8 <pmap_check+0x9bd>
  108fa4:	c7 44 24 0c 1c da 10 	movl   $0x10da1c,0xc(%esp)
  108fab:	00 
  108fac:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  108fb3:	00 
  108fb4:	c7 44 24 04 11 03 00 	movl   $0x311,0x4(%esp)
  108fbb:	00 
  108fbc:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  108fc3:	e8 70 79 ff ff       	call   100938 <debug_panic>
  108fc8:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  108fcf:	40 
  108fd0:	c7 04 24 00 30 18 00 	movl   $0x183000,(%esp)
  108fd7:	e8 b0 f5 ff ff       	call   10858c <va2pa>
  108fdc:	83 f8 ff             	cmp    $0xffffffff,%eax
  108fdf:	74 24                	je     109005 <pmap_check+0x9fa>
  108fe1:	c7 44 24 0c 44 da 10 	movl   $0x10da44,0xc(%esp)
  108fe8:	00 
  108fe9:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  108ff0:	00 
  108ff1:	c7 44 24 04 12 03 00 	movl   $0x312,0x4(%esp)
  108ff8:	00 
  108ff9:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  109000:	e8 33 79 ff ff       	call   100938 <debug_panic>
  109005:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  109008:	8b 40 04             	mov    0x4(%eax),%eax
  10900b:	85 c0                	test   %eax,%eax
  10900d:	74 24                	je     109033 <pmap_check+0xa28>
  10900f:	c7 44 24 0c 73 da 10 	movl   $0x10da73,0xc(%esp)
  109016:	00 
  109017:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  10901e:	00 
  10901f:	c7 44 24 04 13 03 00 	movl   $0x313,0x4(%esp)
  109026:	00 
  109027:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  10902e:	e8 05 79 ff ff       	call   100938 <debug_panic>
  109033:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  109036:	8b 40 04             	mov    0x4(%eax),%eax
  109039:	85 c0                	test   %eax,%eax
  10903b:	74 24                	je     109061 <pmap_check+0xa56>
  10903d:	c7 44 24 0c f4 d9 10 	movl   $0x10d9f4,0xc(%esp)
  109044:	00 
  109045:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  10904c:	00 
  10904d:	c7 44 24 04 14 03 00 	movl   $0x314,0x4(%esp)
  109054:	00 
  109055:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  10905c:	e8 d7 78 ff ff       	call   100938 <debug_panic>
  109061:	e8 ff 83 ff ff       	call   101465 <mem_alloc>
  109066:	3b 45 dc             	cmp    0xffffffdc(%ebp),%eax
  109069:	74 24                	je     10908f <pmap_check+0xa84>
  10906b:	c7 44 24 0c 86 da 10 	movl   $0x10da86,0xc(%esp)
  109072:	00 
  109073:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  10907a:	00 
  10907b:	c7 44 24 04 17 03 00 	movl   $0x317,0x4(%esp)
  109082:	00 
  109083:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  10908a:	e8 a9 78 ff ff       	call   100938 <debug_panic>
  10908f:	e8 d1 83 ff ff       	call   101465 <mem_alloc>
  109094:	85 c0                	test   %eax,%eax
  109096:	74 24                	je     1090bc <pmap_check+0xab1>
  109098:	c7 44 24 0c 24 d6 10 	movl   $0x10d624,0xc(%esp)
  10909f:	00 
  1090a0:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  1090a7:	00 
  1090a8:	c7 44 24 04 1a 03 00 	movl   $0x31a,0x4(%esp)
  1090af:	00 
  1090b0:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  1090b7:	e8 7c 78 ff ff       	call   100938 <debug_panic>
  1090bc:	8b 55 dc             	mov    0xffffffdc(%ebp),%edx
  1090bf:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  1090c4:	89 d1                	mov    %edx,%ecx
  1090c6:	29 c1                	sub    %eax,%ecx
  1090c8:	89 c8                	mov    %ecx,%eax
  1090ca:	c1 e0 09             	shl    $0x9,%eax
  1090cd:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  1090d4:	00 
  1090d5:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  1090dc:	00 
  1090dd:	89 04 24             	mov    %eax,(%esp)
  1090e0:	e8 0c 2b 00 00       	call   10bbf1 <memset>
  1090e5:	8b 55 e0             	mov    0xffffffe0(%ebp),%edx
  1090e8:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  1090ed:	89 d3                	mov    %edx,%ebx
  1090ef:	29 c3                	sub    %eax,%ebx
  1090f1:	89 d8                	mov    %ebx,%eax
  1090f3:	c1 e0 09             	shl    $0x9,%eax
  1090f6:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  1090fd:	00 
  1090fe:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
  109105:	00 
  109106:	89 04 24             	mov    %eax,(%esp)
  109109:	e8 e3 2a 00 00       	call   10bbf1 <memset>
  10910e:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  109115:	00 
  109116:	c7 44 24 08 00 00 00 	movl   $0x40000000,0x8(%esp)
  10911d:	40 
  10911e:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  109121:	89 44 24 04          	mov    %eax,0x4(%esp)
  109125:	c7 04 24 00 30 18 00 	movl   $0x183000,(%esp)
  10912c:	e8 1e d9 ff ff       	call   106a4f <pmap_insert>
  109131:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  109134:	8b 40 04             	mov    0x4(%eax),%eax
  109137:	83 f8 01             	cmp    $0x1,%eax
  10913a:	74 24                	je     109160 <pmap_check+0xb55>
  10913c:	c7 44 24 0c 18 d7 10 	movl   $0x10d718,0xc(%esp)
  109143:	00 
  109144:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  10914b:	00 
  10914c:	c7 44 24 04 21 03 00 	movl   $0x321,0x4(%esp)
  109153:	00 
  109154:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  10915b:	e8 d8 77 ff ff       	call   100938 <debug_panic>
  109160:	b8 00 00 00 40       	mov    $0x40000000,%eax
  109165:	8b 00                	mov    (%eax),%eax
  109167:	3d 01 01 01 01       	cmp    $0x1010101,%eax
  10916c:	74 24                	je     109192 <pmap_check+0xb87>
  10916e:	c7 44 24 0c 9c da 10 	movl   $0x10da9c,0xc(%esp)
  109175:	00 
  109176:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  10917d:	00 
  10917e:	c7 44 24 04 22 03 00 	movl   $0x322,0x4(%esp)
  109185:	00 
  109186:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  10918d:	e8 a6 77 ff ff       	call   100938 <debug_panic>
  109192:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  109199:	00 
  10919a:	c7 44 24 08 00 00 00 	movl   $0x40000000,0x8(%esp)
  1091a1:	40 
  1091a2:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  1091a5:	89 44 24 04          	mov    %eax,0x4(%esp)
  1091a9:	c7 04 24 00 30 18 00 	movl   $0x183000,(%esp)
  1091b0:	e8 9a d8 ff ff       	call   106a4f <pmap_insert>
  1091b5:	b8 00 00 00 40       	mov    $0x40000000,%eax
  1091ba:	8b 00                	mov    (%eax),%eax
  1091bc:	3d 02 02 02 02       	cmp    $0x2020202,%eax
  1091c1:	74 24                	je     1091e7 <pmap_check+0xbdc>
  1091c3:	c7 44 24 0c bc da 10 	movl   $0x10dabc,0xc(%esp)
  1091ca:	00 
  1091cb:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  1091d2:	00 
  1091d3:	c7 44 24 04 24 03 00 	movl   $0x324,0x4(%esp)
  1091da:	00 
  1091db:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  1091e2:	e8 51 77 ff ff       	call   100938 <debug_panic>
  1091e7:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  1091ea:	8b 40 04             	mov    0x4(%eax),%eax
  1091ed:	83 f8 01             	cmp    $0x1,%eax
  1091f0:	74 24                	je     109216 <pmap_check+0xc0b>
  1091f2:	c7 44 24 0c b5 d7 10 	movl   $0x10d7b5,0xc(%esp)
  1091f9:	00 
  1091fa:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  109201:	00 
  109202:	c7 44 24 04 25 03 00 	movl   $0x325,0x4(%esp)
  109209:	00 
  10920a:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  109211:	e8 22 77 ff ff       	call   100938 <debug_panic>
  109216:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  109219:	8b 40 04             	mov    0x4(%eax),%eax
  10921c:	85 c0                	test   %eax,%eax
  10921e:	74 24                	je     109244 <pmap_check+0xc39>
  109220:	c7 44 24 0c 73 da 10 	movl   $0x10da73,0xc(%esp)
  109227:	00 
  109228:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  10922f:	00 
  109230:	c7 44 24 04 26 03 00 	movl   $0x326,0x4(%esp)
  109237:	00 
  109238:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  10923f:	e8 f4 76 ff ff       	call   100938 <debug_panic>
  109244:	e8 1c 82 ff ff       	call   101465 <mem_alloc>
  109249:	3b 45 dc             	cmp    0xffffffdc(%ebp),%eax
  10924c:	74 24                	je     109272 <pmap_check+0xc67>
  10924e:	c7 44 24 0c 86 da 10 	movl   $0x10da86,0xc(%esp)
  109255:	00 
  109256:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  10925d:	00 
  10925e:	c7 44 24 04 27 03 00 	movl   $0x327,0x4(%esp)
  109265:	00 
  109266:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  10926d:	e8 c6 76 ff ff       	call   100938 <debug_panic>
  109272:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  109279:	00 
  10927a:	c7 44 24 04 00 00 00 	movl   $0x40000000,0x4(%esp)
  109281:	40 
  109282:	c7 04 24 00 30 18 00 	movl   $0x183000,(%esp)
  109289:	e8 3f d9 ff ff       	call   106bcd <pmap_remove>
  10928e:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  109291:	8b 40 04             	mov    0x4(%eax),%eax
  109294:	85 c0                	test   %eax,%eax
  109296:	74 24                	je     1092bc <pmap_check+0xcb1>
  109298:	c7 44 24 0c f4 d9 10 	movl   $0x10d9f4,0xc(%esp)
  10929f:	00 
  1092a0:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  1092a7:	00 
  1092a8:	c7 44 24 04 29 03 00 	movl   $0x329,0x4(%esp)
  1092af:	00 
  1092b0:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  1092b7:	e8 7c 76 ff ff       	call   100938 <debug_panic>
  1092bc:	e8 a4 81 ff ff       	call   101465 <mem_alloc>
  1092c1:	3b 45 e0             	cmp    0xffffffe0(%ebp),%eax
  1092c4:	74 24                	je     1092ea <pmap_check+0xcdf>
  1092c6:	c7 44 24 0c 07 da 10 	movl   $0x10da07,0xc(%esp)
  1092cd:	00 
  1092ce:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  1092d5:	00 
  1092d6:	c7 44 24 04 2a 03 00 	movl   $0x32a,0x4(%esp)
  1092dd:	00 
  1092de:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  1092e5:	e8 4e 76 ff ff       	call   100938 <debug_panic>
  1092ea:	c7 44 24 08 00 00 00 	movl   $0xb0000000,0x8(%esp)
  1092f1:	b0 
  1092f2:	c7 44 24 04 00 00 00 	movl   $0x40000000,0x4(%esp)
  1092f9:	40 
  1092fa:	c7 04 24 00 30 18 00 	movl   $0x183000,(%esp)
  109301:	e8 c7 d8 ff ff       	call   106bcd <pmap_remove>
  109306:	a1 00 34 18 00       	mov    0x183400,%eax
  10930b:	ba 00 40 18 00       	mov    $0x184000,%edx
  109310:	39 d0                	cmp    %edx,%eax
  109312:	74 24                	je     109338 <pmap_check+0xd2d>
  109314:	c7 44 24 0c dc da 10 	movl   $0x10dadc,0xc(%esp)
  10931b:	00 
  10931c:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  109323:	00 
  109324:	c7 44 24 04 2e 03 00 	movl   $0x32e,0x4(%esp)
  10932b:	00 
  10932c:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  109333:	e8 00 76 ff ff       	call   100938 <debug_panic>
  109338:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  10933b:	8b 40 04             	mov    0x4(%eax),%eax
  10933e:	85 c0                	test   %eax,%eax
  109340:	74 24                	je     109366 <pmap_check+0xd5b>
  109342:	c7 44 24 0c 06 db 10 	movl   $0x10db06,0xc(%esp)
  109349:	00 
  10934a:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  109351:	00 
  109352:	c7 44 24 04 2f 03 00 	movl   $0x32f,0x4(%esp)
  109359:	00 
  10935a:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  109361:	e8 d2 75 ff ff       	call   100938 <debug_panic>
  109366:	e8 fa 80 ff ff       	call   101465 <mem_alloc>
  10936b:	3b 45 d8             	cmp    0xffffffd8(%ebp),%eax
  10936e:	74 24                	je     109394 <pmap_check+0xd89>
  109370:	c7 44 24 0c 19 db 10 	movl   $0x10db19,0xc(%esp)
  109377:	00 
  109378:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  10937f:	00 
  109380:	c7 44 24 04 30 03 00 	movl   $0x330,0x4(%esp)
  109387:	00 
  109388:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  10938f:	e8 a4 75 ff ff       	call   100938 <debug_panic>
  109394:	a1 80 1d 18 00       	mov    0x181d80,%eax
  109399:	85 c0                	test   %eax,%eax
  10939b:	74 24                	je     1093c1 <pmap_check+0xdb6>
  10939d:	c7 44 24 0c 2c db 10 	movl   $0x10db2c,0xc(%esp)
  1093a4:	00 
  1093a5:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  1093ac:	00 
  1093ad:	c7 44 24 04 31 03 00 	movl   $0x331,0x4(%esp)
  1093b4:	00 
  1093b5:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  1093bc:	e8 77 75 ff ff       	call   100938 <debug_panic>
  1093c1:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  1093c4:	89 04 24             	mov    %eax,(%esp)
  1093c7:	e8 dd 80 ff ff       	call   1014a9 <mem_free>
  1093cc:	c7 45 f8 00 00 00 40 	movl   $0x40000000,0xfffffff8(%ebp)
  1093d3:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  1093da:	00 
  1093db:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1093de:	89 44 24 08          	mov    %eax,0x8(%esp)
  1093e2:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  1093e5:	89 44 24 04          	mov    %eax,0x4(%esp)
  1093e9:	c7 04 24 00 30 18 00 	movl   $0x183000,(%esp)
  1093f0:	e8 5a d6 ff ff       	call   106a4f <pmap_insert>
  1093f5:	85 c0                	test   %eax,%eax
  1093f7:	75 24                	jne    10941d <pmap_check+0xe12>
  1093f9:	c7 44 24 0c 44 db 10 	movl   $0x10db44,0xc(%esp)
  109400:	00 
  109401:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  109408:	00 
  109409:	c7 44 24 04 36 03 00 	movl   $0x336,0x4(%esp)
  109410:	00 
  109411:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  109418:	e8 1b 75 ff ff       	call   100938 <debug_panic>
  10941d:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  109420:	05 00 10 00 00       	add    $0x1000,%eax
  109425:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  10942c:	00 
  10942d:	89 44 24 08          	mov    %eax,0x8(%esp)
  109431:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  109434:	89 44 24 04          	mov    %eax,0x4(%esp)
  109438:	c7 04 24 00 30 18 00 	movl   $0x183000,(%esp)
  10943f:	e8 0b d6 ff ff       	call   106a4f <pmap_insert>
  109444:	85 c0                	test   %eax,%eax
  109446:	75 24                	jne    10946c <pmap_check+0xe61>
  109448:	c7 44 24 0c 6c db 10 	movl   $0x10db6c,0xc(%esp)
  10944f:	00 
  109450:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  109457:	00 
  109458:	c7 44 24 04 37 03 00 	movl   $0x337,0x4(%esp)
  10945f:	00 
  109460:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  109467:	e8 cc 74 ff ff       	call   100938 <debug_panic>
  10946c:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10946f:	05 00 f0 3f 00       	add    $0x3ff000,%eax
  109474:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  10947b:	00 
  10947c:	89 44 24 08          	mov    %eax,0x8(%esp)
  109480:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  109483:	89 44 24 04          	mov    %eax,0x4(%esp)
  109487:	c7 04 24 00 30 18 00 	movl   $0x183000,(%esp)
  10948e:	e8 bc d5 ff ff       	call   106a4f <pmap_insert>
  109493:	85 c0                	test   %eax,%eax
  109495:	75 24                	jne    1094bb <pmap_check+0xeb0>
  109497:	c7 44 24 0c 9c db 10 	movl   $0x10db9c,0xc(%esp)
  10949e:	00 
  10949f:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  1094a6:	00 
  1094a7:	c7 44 24 04 38 03 00 	movl   $0x338,0x4(%esp)
  1094ae:	00 
  1094af:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  1094b6:	e8 7d 74 ff ff       	call   100938 <debug_panic>
  1094bb:	a1 00 34 18 00       	mov    0x183400,%eax
  1094c0:	89 c1                	mov    %eax,%ecx
  1094c2:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
  1094c8:	8b 55 dc             	mov    0xffffffdc(%ebp),%edx
  1094cb:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  1094d0:	89 d3                	mov    %edx,%ebx
  1094d2:	29 c3                	sub    %eax,%ebx
  1094d4:	89 d8                	mov    %ebx,%eax
  1094d6:	c1 e0 09             	shl    $0x9,%eax
  1094d9:	39 c1                	cmp    %eax,%ecx
  1094db:	74 24                	je     109501 <pmap_check+0xef6>
  1094dd:	c7 44 24 0c d4 db 10 	movl   $0x10dbd4,0xc(%esp)
  1094e4:	00 
  1094e5:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  1094ec:	00 
  1094ed:	c7 44 24 04 39 03 00 	movl   $0x339,0x4(%esp)
  1094f4:	00 
  1094f5:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  1094fc:	e8 37 74 ff ff       	call   100938 <debug_panic>
  109501:	a1 80 1d 18 00       	mov    0x181d80,%eax
  109506:	85 c0                	test   %eax,%eax
  109508:	74 24                	je     10952e <pmap_check+0xf23>
  10950a:	c7 44 24 0c 2c db 10 	movl   $0x10db2c,0xc(%esp)
  109511:	00 
  109512:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  109519:	00 
  10951a:	c7 44 24 04 3a 03 00 	movl   $0x33a,0x4(%esp)
  109521:	00 
  109522:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  109529:	e8 0a 74 ff ff       	call   100938 <debug_panic>
  10952e:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  109531:	89 04 24             	mov    %eax,(%esp)
  109534:	e8 70 7f ff ff       	call   1014a9 <mem_free>
  109539:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10953c:	05 00 00 40 00       	add    $0x400000,%eax
  109541:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  109548:	00 
  109549:	89 44 24 08          	mov    %eax,0x8(%esp)
  10954d:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  109550:	89 44 24 04          	mov    %eax,0x4(%esp)
  109554:	c7 04 24 00 30 18 00 	movl   $0x183000,(%esp)
  10955b:	e8 ef d4 ff ff       	call   106a4f <pmap_insert>
  109560:	85 c0                	test   %eax,%eax
  109562:	75 24                	jne    109588 <pmap_check+0xf7d>
  109564:	c7 44 24 0c 10 dc 10 	movl   $0x10dc10,0xc(%esp)
  10956b:	00 
  10956c:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  109573:	00 
  109574:	c7 44 24 04 3c 03 00 	movl   $0x33c,0x4(%esp)
  10957b:	00 
  10957c:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  109583:	e8 b0 73 ff ff       	call   100938 <debug_panic>
  109588:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10958b:	05 00 10 40 00       	add    $0x401000,%eax
  109590:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  109597:	00 
  109598:	89 44 24 08          	mov    %eax,0x8(%esp)
  10959c:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  10959f:	89 44 24 04          	mov    %eax,0x4(%esp)
  1095a3:	c7 04 24 00 30 18 00 	movl   $0x183000,(%esp)
  1095aa:	e8 a0 d4 ff ff       	call   106a4f <pmap_insert>
  1095af:	85 c0                	test   %eax,%eax
  1095b1:	75 24                	jne    1095d7 <pmap_check+0xfcc>
  1095b3:	c7 44 24 0c 40 dc 10 	movl   $0x10dc40,0xc(%esp)
  1095ba:	00 
  1095bb:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  1095c2:	00 
  1095c3:	c7 44 24 04 3d 03 00 	movl   $0x33d,0x4(%esp)
  1095ca:	00 
  1095cb:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  1095d2:	e8 61 73 ff ff       	call   100938 <debug_panic>
  1095d7:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1095da:	05 00 f0 7f 00       	add    $0x7ff000,%eax
  1095df:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  1095e6:	00 
  1095e7:	89 44 24 08          	mov    %eax,0x8(%esp)
  1095eb:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  1095ee:	89 44 24 04          	mov    %eax,0x4(%esp)
  1095f2:	c7 04 24 00 30 18 00 	movl   $0x183000,(%esp)
  1095f9:	e8 51 d4 ff ff       	call   106a4f <pmap_insert>
  1095fe:	85 c0                	test   %eax,%eax
  109600:	75 24                	jne    109626 <pmap_check+0x101b>
  109602:	c7 44 24 0c 78 dc 10 	movl   $0x10dc78,0xc(%esp)
  109609:	00 
  10960a:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  109611:	00 
  109612:	c7 44 24 04 3e 03 00 	movl   $0x33e,0x4(%esp)
  109619:	00 
  10961a:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  109621:	e8 12 73 ff ff       	call   100938 <debug_panic>
  109626:	a1 04 34 18 00       	mov    0x183404,%eax
  10962b:	89 c1                	mov    %eax,%ecx
  10962d:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
  109633:	8b 55 e0             	mov    0xffffffe0(%ebp),%edx
  109636:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  10963b:	89 d3                	mov    %edx,%ebx
  10963d:	29 c3                	sub    %eax,%ebx
  10963f:	89 d8                	mov    %ebx,%eax
  109641:	c1 e0 09             	shl    $0x9,%eax
  109644:	39 c1                	cmp    %eax,%ecx
  109646:	74 24                	je     10966c <pmap_check+0x1061>
  109648:	c7 44 24 0c b4 dc 10 	movl   $0x10dcb4,0xc(%esp)
  10964f:	00 
  109650:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  109657:	00 
  109658:	c7 44 24 04 40 03 00 	movl   $0x340,0x4(%esp)
  10965f:	00 
  109660:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  109667:	e8 cc 72 ff ff       	call   100938 <debug_panic>
  10966c:	a1 80 1d 18 00       	mov    0x181d80,%eax
  109671:	85 c0                	test   %eax,%eax
  109673:	74 24                	je     109699 <pmap_check+0x108e>
  109675:	c7 44 24 0c 2c db 10 	movl   $0x10db2c,0xc(%esp)
  10967c:	00 
  10967d:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  109684:	00 
  109685:	c7 44 24 04 41 03 00 	movl   $0x341,0x4(%esp)
  10968c:	00 
  10968d:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  109694:	e8 9f 72 ff ff       	call   100938 <debug_panic>
  109699:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  10969c:	89 04 24             	mov    %eax,(%esp)
  10969f:	e8 05 7e ff ff       	call   1014a9 <mem_free>
  1096a4:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1096a7:	05 00 00 80 00       	add    $0x800000,%eax
  1096ac:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  1096b3:	00 
  1096b4:	89 44 24 08          	mov    %eax,0x8(%esp)
  1096b8:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  1096bb:	89 44 24 04          	mov    %eax,0x4(%esp)
  1096bf:	c7 04 24 00 30 18 00 	movl   $0x183000,(%esp)
  1096c6:	e8 84 d3 ff ff       	call   106a4f <pmap_insert>
  1096cb:	85 c0                	test   %eax,%eax
  1096cd:	75 24                	jne    1096f3 <pmap_check+0x10e8>
  1096cf:	c7 44 24 0c f8 dc 10 	movl   $0x10dcf8,0xc(%esp)
  1096d6:	00 
  1096d7:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  1096de:	00 
  1096df:	c7 44 24 04 43 03 00 	movl   $0x343,0x4(%esp)
  1096e6:	00 
  1096e7:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  1096ee:	e8 45 72 ff ff       	call   100938 <debug_panic>
  1096f3:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1096f6:	05 00 10 80 00       	add    $0x801000,%eax
  1096fb:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  109702:	00 
  109703:	89 44 24 08          	mov    %eax,0x8(%esp)
  109707:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  10970a:	89 44 24 04          	mov    %eax,0x4(%esp)
  10970e:	c7 04 24 00 30 18 00 	movl   $0x183000,(%esp)
  109715:	e8 35 d3 ff ff       	call   106a4f <pmap_insert>
  10971a:	85 c0                	test   %eax,%eax
  10971c:	75 24                	jne    109742 <pmap_check+0x1137>
  10971e:	c7 44 24 0c 28 dd 10 	movl   $0x10dd28,0xc(%esp)
  109725:	00 
  109726:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  10972d:	00 
  10972e:	c7 44 24 04 44 03 00 	movl   $0x344,0x4(%esp)
  109735:	00 
  109736:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  10973d:	e8 f6 71 ff ff       	call   100938 <debug_panic>
  109742:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  109745:	05 00 e0 bf 00       	add    $0xbfe000,%eax
  10974a:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  109751:	00 
  109752:	89 44 24 08          	mov    %eax,0x8(%esp)
  109756:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  109759:	89 44 24 04          	mov    %eax,0x4(%esp)
  10975d:	c7 04 24 00 30 18 00 	movl   $0x183000,(%esp)
  109764:	e8 e6 d2 ff ff       	call   106a4f <pmap_insert>
  109769:	85 c0                	test   %eax,%eax
  10976b:	75 24                	jne    109791 <pmap_check+0x1186>
  10976d:	c7 44 24 0c 64 dd 10 	movl   $0x10dd64,0xc(%esp)
  109774:	00 
  109775:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  10977c:	00 
  10977d:	c7 44 24 04 45 03 00 	movl   $0x345,0x4(%esp)
  109784:	00 
  109785:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  10978c:	e8 a7 71 ff ff       	call   100938 <debug_panic>
  109791:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  109794:	05 00 f0 bf 00       	add    $0xbff000,%eax
  109799:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  1097a0:	00 
  1097a1:	89 44 24 08          	mov    %eax,0x8(%esp)
  1097a5:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  1097a8:	89 44 24 04          	mov    %eax,0x4(%esp)
  1097ac:	c7 04 24 00 30 18 00 	movl   $0x183000,(%esp)
  1097b3:	e8 97 d2 ff ff       	call   106a4f <pmap_insert>
  1097b8:	85 c0                	test   %eax,%eax
  1097ba:	75 24                	jne    1097e0 <pmap_check+0x11d5>
  1097bc:	c7 44 24 0c a0 dd 10 	movl   $0x10dda0,0xc(%esp)
  1097c3:	00 
  1097c4:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  1097cb:	00 
  1097cc:	c7 44 24 04 46 03 00 	movl   $0x346,0x4(%esp)
  1097d3:	00 
  1097d4:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  1097db:	e8 58 71 ff ff       	call   100938 <debug_panic>
  1097e0:	a1 08 34 18 00       	mov    0x183408,%eax
  1097e5:	89 c1                	mov    %eax,%ecx
  1097e7:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
  1097ed:	8b 55 e4             	mov    0xffffffe4(%ebp),%edx
  1097f0:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  1097f5:	89 d3                	mov    %edx,%ebx
  1097f7:	29 c3                	sub    %eax,%ebx
  1097f9:	89 d8                	mov    %ebx,%eax
  1097fb:	c1 e0 09             	shl    $0x9,%eax
  1097fe:	39 c1                	cmp    %eax,%ecx
  109800:	74 24                	je     109826 <pmap_check+0x121b>
  109802:	c7 44 24 0c dc dd 10 	movl   $0x10dddc,0xc(%esp)
  109809:	00 
  10980a:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  109811:	00 
  109812:	c7 44 24 04 48 03 00 	movl   $0x348,0x4(%esp)
  109819:	00 
  10981a:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  109821:	e8 12 71 ff ff       	call   100938 <debug_panic>
  109826:	a1 80 1d 18 00       	mov    0x181d80,%eax
  10982b:	85 c0                	test   %eax,%eax
  10982d:	74 24                	je     109853 <pmap_check+0x1248>
  10982f:	c7 44 24 0c 2c db 10 	movl   $0x10db2c,0xc(%esp)
  109836:	00 
  109837:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  10983e:	00 
  10983f:	c7 44 24 04 49 03 00 	movl   $0x349,0x4(%esp)
  109846:	00 
  109847:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  10984e:	e8 e5 70 ff ff       	call   100938 <debug_panic>
  109853:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  109856:	8b 40 04             	mov    0x4(%eax),%eax
  109859:	83 f8 0a             	cmp    $0xa,%eax
  10985c:	74 24                	je     109882 <pmap_check+0x1277>
  10985e:	c7 44 24 0c 1f de 10 	movl   $0x10de1f,0xc(%esp)
  109865:	00 
  109866:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  10986d:	00 
  10986e:	c7 44 24 04 4a 03 00 	movl   $0x34a,0x4(%esp)
  109875:	00 
  109876:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  10987d:	e8 b6 70 ff ff       	call   100938 <debug_panic>
  109882:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  109885:	8b 40 04             	mov    0x4(%eax),%eax
  109888:	83 f8 01             	cmp    $0x1,%eax
  10988b:	74 24                	je     1098b1 <pmap_check+0x12a6>
  10988d:	c7 44 24 0c 18 d7 10 	movl   $0x10d718,0xc(%esp)
  109894:	00 
  109895:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  10989c:	00 
  10989d:	c7 44 24 04 4b 03 00 	movl   $0x34b,0x4(%esp)
  1098a4:	00 
  1098a5:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  1098ac:	e8 87 70 ff ff       	call   100938 <debug_panic>
  1098b1:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  1098b4:	8b 40 04             	mov    0x4(%eax),%eax
  1098b7:	83 f8 01             	cmp    $0x1,%eax
  1098ba:	74 24                	je     1098e0 <pmap_check+0x12d5>
  1098bc:	c7 44 24 0c b5 d7 10 	movl   $0x10d7b5,0xc(%esp)
  1098c3:	00 
  1098c4:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  1098cb:	00 
  1098cc:	c7 44 24 04 4c 03 00 	movl   $0x34c,0x4(%esp)
  1098d3:	00 
  1098d4:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  1098db:	e8 58 70 ff ff       	call   100938 <debug_panic>
  1098e0:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  1098e3:	8b 40 04             	mov    0x4(%eax),%eax
  1098e6:	83 f8 01             	cmp    $0x1,%eax
  1098e9:	74 24                	je     10990f <pmap_check+0x1304>
  1098eb:	c7 44 24 0c 33 de 10 	movl   $0x10de33,0xc(%esp)
  1098f2:	00 
  1098f3:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  1098fa:	00 
  1098fb:	c7 44 24 04 4d 03 00 	movl   $0x34d,0x4(%esp)
  109902:	00 
  109903:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  10990a:	e8 29 70 ff ff       	call   100938 <debug_panic>
  10990f:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  109912:	05 00 10 00 00       	add    $0x1000,%eax
  109917:	c7 44 24 08 00 e0 bf 	movl   $0xbfe000,0x8(%esp)
  10991e:	00 
  10991f:	89 44 24 04          	mov    %eax,0x4(%esp)
  109923:	c7 04 24 00 30 18 00 	movl   $0x183000,(%esp)
  10992a:	e8 9e d2 ff ff       	call   106bcd <pmap_remove>
  10992f:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  109932:	8b 40 04             	mov    0x4(%eax),%eax
  109935:	83 f8 02             	cmp    $0x2,%eax
  109938:	74 24                	je     10995e <pmap_check+0x1353>
  10993a:	c7 44 24 0c 46 de 10 	movl   $0x10de46,0xc(%esp)
  109941:	00 
  109942:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  109949:	00 
  10994a:	c7 44 24 04 4f 03 00 	movl   $0x34f,0x4(%esp)
  109951:	00 
  109952:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  109959:	e8 da 6f ff ff       	call   100938 <debug_panic>
  10995e:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  109961:	8b 40 04             	mov    0x4(%eax),%eax
  109964:	85 c0                	test   %eax,%eax
  109966:	74 24                	je     10998c <pmap_check+0x1381>
  109968:	c7 44 24 0c f4 d9 10 	movl   $0x10d9f4,0xc(%esp)
  10996f:	00 
  109970:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  109977:	00 
  109978:	c7 44 24 04 50 03 00 	movl   $0x350,0x4(%esp)
  10997f:	00 
  109980:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  109987:	e8 ac 6f ff ff       	call   100938 <debug_panic>
  10998c:	e8 d4 7a ff ff       	call   101465 <mem_alloc>
  109991:	3b 45 e0             	cmp    0xffffffe0(%ebp),%eax
  109994:	74 24                	je     1099ba <pmap_check+0x13af>
  109996:	c7 44 24 0c 07 da 10 	movl   $0x10da07,0xc(%esp)
  10999d:	00 
  10999e:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  1099a5:	00 
  1099a6:	c7 44 24 04 50 03 00 	movl   $0x350,0x4(%esp)
  1099ad:	00 
  1099ae:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  1099b5:	e8 7e 6f ff ff       	call   100938 <debug_panic>
  1099ba:	a1 80 1d 18 00       	mov    0x181d80,%eax
  1099bf:	85 c0                	test   %eax,%eax
  1099c1:	74 24                	je     1099e7 <pmap_check+0x13dc>
  1099c3:	c7 44 24 0c 2c db 10 	movl   $0x10db2c,0xc(%esp)
  1099ca:	00 
  1099cb:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  1099d2:	00 
  1099d3:	c7 44 24 04 51 03 00 	movl   $0x351,0x4(%esp)
  1099da:	00 
  1099db:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  1099e2:	e8 51 6f ff ff       	call   100938 <debug_panic>
  1099e7:	c7 44 24 08 00 f0 bf 	movl   $0xbff000,0x8(%esp)
  1099ee:	00 
  1099ef:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1099f2:	89 44 24 04          	mov    %eax,0x4(%esp)
  1099f6:	c7 04 24 00 30 18 00 	movl   $0x183000,(%esp)
  1099fd:	e8 cb d1 ff ff       	call   106bcd <pmap_remove>
  109a02:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  109a05:	8b 40 04             	mov    0x4(%eax),%eax
  109a08:	83 f8 01             	cmp    $0x1,%eax
  109a0b:	74 24                	je     109a31 <pmap_check+0x1426>
  109a0d:	c7 44 24 0c 2b d7 10 	movl   $0x10d72b,0xc(%esp)
  109a14:	00 
  109a15:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  109a1c:	00 
  109a1d:	c7 44 24 04 53 03 00 	movl   $0x353,0x4(%esp)
  109a24:	00 
  109a25:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  109a2c:	e8 07 6f ff ff       	call   100938 <debug_panic>
  109a31:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  109a34:	8b 40 04             	mov    0x4(%eax),%eax
  109a37:	85 c0                	test   %eax,%eax
  109a39:	74 24                	je     109a5f <pmap_check+0x1454>
  109a3b:	c7 44 24 0c 73 da 10 	movl   $0x10da73,0xc(%esp)
  109a42:	00 
  109a43:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  109a4a:	00 
  109a4b:	c7 44 24 04 54 03 00 	movl   $0x354,0x4(%esp)
  109a52:	00 
  109a53:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  109a5a:	e8 d9 6e ff ff       	call   100938 <debug_panic>
  109a5f:	e8 01 7a ff ff       	call   101465 <mem_alloc>
  109a64:	3b 45 dc             	cmp    0xffffffdc(%ebp),%eax
  109a67:	74 24                	je     109a8d <pmap_check+0x1482>
  109a69:	c7 44 24 0c 86 da 10 	movl   $0x10da86,0xc(%esp)
  109a70:	00 
  109a71:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  109a78:	00 
  109a79:	c7 44 24 04 54 03 00 	movl   $0x354,0x4(%esp)
  109a80:	00 
  109a81:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  109a88:	e8 ab 6e ff ff       	call   100938 <debug_panic>
  109a8d:	a1 80 1d 18 00       	mov    0x181d80,%eax
  109a92:	85 c0                	test   %eax,%eax
  109a94:	74 24                	je     109aba <pmap_check+0x14af>
  109a96:	c7 44 24 0c 2c db 10 	movl   $0x10db2c,0xc(%esp)
  109a9d:	00 
  109a9e:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  109aa5:	00 
  109aa6:	c7 44 24 04 55 03 00 	movl   $0x355,0x4(%esp)
  109aad:	00 
  109aae:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  109ab5:	e8 7e 6e ff ff       	call   100938 <debug_panic>
  109aba:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  109abd:	05 00 f0 bf 00       	add    $0xbff000,%eax
  109ac2:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  109ac9:	00 
  109aca:	89 44 24 04          	mov    %eax,0x4(%esp)
  109ace:	c7 04 24 00 30 18 00 	movl   $0x183000,(%esp)
  109ad5:	e8 f3 d0 ff ff       	call   106bcd <pmap_remove>
  109ada:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  109add:	8b 40 04             	mov    0x4(%eax),%eax
  109ae0:	85 c0                	test   %eax,%eax
  109ae2:	74 24                	je     109b08 <pmap_check+0x14fd>
  109ae4:	c7 44 24 0c 06 db 10 	movl   $0x10db06,0xc(%esp)
  109aeb:	00 
  109aec:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  109af3:	00 
  109af4:	c7 44 24 04 57 03 00 	movl   $0x357,0x4(%esp)
  109afb:	00 
  109afc:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  109b03:	e8 30 6e ff ff       	call   100938 <debug_panic>
  109b08:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  109b0b:	05 00 10 00 00       	add    $0x1000,%eax
  109b10:	c7 44 24 08 00 00 c0 	movl   $0xc00000,0x8(%esp)
  109b17:	00 
  109b18:	89 44 24 04          	mov    %eax,0x4(%esp)
  109b1c:	c7 04 24 00 30 18 00 	movl   $0x183000,(%esp)
  109b23:	e8 a5 d0 ff ff       	call   106bcd <pmap_remove>
  109b28:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  109b2b:	8b 40 04             	mov    0x4(%eax),%eax
  109b2e:	85 c0                	test   %eax,%eax
  109b30:	74 24                	je     109b56 <pmap_check+0x154b>
  109b32:	c7 44 24 0c 59 de 10 	movl   $0x10de59,0xc(%esp)
  109b39:	00 
  109b3a:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  109b41:	00 
  109b42:	c7 44 24 04 59 03 00 	movl   $0x359,0x4(%esp)
  109b49:	00 
  109b4a:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  109b51:	e8 e2 6d ff ff       	call   100938 <debug_panic>
  109b56:	e8 0a 79 ff ff       	call   101465 <mem_alloc>
  109b5b:	e8 05 79 ff ff       	call   101465 <mem_alloc>
  109b60:	a1 80 1d 18 00       	mov    0x181d80,%eax
  109b65:	85 c0                	test   %eax,%eax
  109b67:	74 24                	je     109b8d <pmap_check+0x1582>
  109b69:	c7 44 24 0c 2c db 10 	movl   $0x10db2c,0xc(%esp)
  109b70:	00 
  109b71:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  109b78:	00 
  109b79:	c7 44 24 04 5b 03 00 	movl   $0x35b,0x4(%esp)
  109b80:	00 
  109b81:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  109b88:	e8 ab 6d ff ff       	call   100938 <debug_panic>
  109b8d:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  109b90:	89 04 24             	mov    %eax,(%esp)
  109b93:	e8 11 79 ff ff       	call   1014a9 <mem_free>
  109b98:	c7 45 f8 00 10 40 40 	movl   $0x40401000,0xfffffff8(%ebp)
  109b9f:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
  109ba6:	00 
  109ba7:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  109baa:	89 44 24 04          	mov    %eax,0x4(%esp)
  109bae:	c7 04 24 00 30 18 00 	movl   $0x183000,(%esp)
  109bb5:	e8 dd c7 ff ff       	call   106397 <pmap_walk>
  109bba:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  109bbd:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  109bc0:	c1 e8 16             	shr    $0x16,%eax
  109bc3:	25 ff 03 00 00       	and    $0x3ff,%eax
  109bc8:	8b 04 85 00 30 18 00 	mov    0x183000(,%eax,4),%eax
  109bcf:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  109bd4:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
  109bd7:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  109bda:	c1 e8 0c             	shr    $0xc,%eax
  109bdd:	25 ff 03 00 00       	and    $0x3ff,%eax
  109be2:	c1 e0 02             	shl    $0x2,%eax
  109be5:	03 45 f0             	add    0xfffffff0(%ebp),%eax
  109be8:	3b 45 ec             	cmp    0xffffffec(%ebp),%eax
  109beb:	74 24                	je     109c11 <pmap_check+0x1606>
  109bed:	c7 44 24 0c 6c de 10 	movl   $0x10de6c,0xc(%esp)
  109bf4:	00 
  109bf5:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  109bfc:	00 
  109bfd:	c7 44 24 04 62 03 00 	movl   $0x362,0x4(%esp)
  109c04:	00 
  109c05:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  109c0c:	e8 27 6d ff ff       	call   100938 <debug_panic>
  109c11:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  109c14:	c1 e8 16             	shr    $0x16,%eax
  109c17:	89 c2                	mov    %eax,%edx
  109c19:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
  109c1f:	b8 00 40 18 00       	mov    $0x184000,%eax
  109c24:	89 04 95 00 30 18 00 	mov    %eax,0x183000(,%edx,4)
  109c2b:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  109c2e:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
  109c35:	8b 55 d8             	mov    0xffffffd8(%ebp),%edx
  109c38:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  109c3d:	89 d1                	mov    %edx,%ecx
  109c3f:	29 c1                	sub    %eax,%ecx
  109c41:	89 c8                	mov    %ecx,%eax
  109c43:	c1 e0 09             	shl    $0x9,%eax
  109c46:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  109c4d:	00 
  109c4e:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
  109c55:	00 
  109c56:	89 04 24             	mov    %eax,(%esp)
  109c59:	e8 93 1f 00 00       	call   10bbf1 <memset>
  109c5e:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  109c61:	89 04 24             	mov    %eax,(%esp)
  109c64:	e8 40 78 ff ff       	call   1014a9 <mem_free>
  109c69:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
  109c70:	00 
  109c71:	c7 44 24 04 00 f0 ff 	movl   $0xeffff000,0x4(%esp)
  109c78:	ef 
  109c79:	c7 04 24 00 30 18 00 	movl   $0x183000,(%esp)
  109c80:	e8 12 c7 ff ff       	call   106397 <pmap_walk>
  109c85:	8b 55 d8             	mov    0xffffffd8(%ebp),%edx
  109c88:	a1 e0 1d 18 00       	mov    0x181de0,%eax
  109c8d:	89 d3                	mov    %edx,%ebx
  109c8f:	29 c3                	sub    %eax,%ebx
  109c91:	89 d8                	mov    %ebx,%eax
  109c93:	c1 e0 09             	shl    $0x9,%eax
  109c96:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  109c99:	c7 45 f4 00 00 00 00 	movl   $0x0,0xfffffff4(%ebp)
  109ca0:	eb 3c                	jmp    109cde <pmap_check+0x16d3>
  109ca2:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  109ca5:	c1 e0 02             	shl    $0x2,%eax
  109ca8:	03 45 ec             	add    0xffffffec(%ebp),%eax
  109cab:	8b 10                	mov    (%eax),%edx
  109cad:	b8 00 40 18 00       	mov    $0x184000,%eax
  109cb2:	39 c2                	cmp    %eax,%edx
  109cb4:	74 24                	je     109cda <pmap_check+0x16cf>
  109cb6:	c7 44 24 0c 84 de 10 	movl   $0x10de84,0xc(%esp)
  109cbd:	00 
  109cbe:	c7 44 24 08 fe d2 10 	movl   $0x10d2fe,0x8(%esp)
  109cc5:	00 
  109cc6:	c7 44 24 04 6c 03 00 	movl   $0x36c,0x4(%esp)
  109ccd:	00 
  109cce:	c7 04 24 ea d3 10 00 	movl   $0x10d3ea,(%esp)
  109cd5:	e8 5e 6c ff ff       	call   100938 <debug_panic>
  109cda:	83 45 f4 01          	addl   $0x1,0xfffffff4(%ebp)
  109cde:	81 7d f4 ff 03 00 00 	cmpl   $0x3ff,0xfffffff4(%ebp)
  109ce5:	7e bb                	jle    109ca2 <pmap_check+0x1697>
  109ce7:	b8 00 40 18 00       	mov    $0x184000,%eax
  109cec:	a3 fc 3e 18 00       	mov    %eax,0x183efc
  109cf1:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  109cf4:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
  109cfb:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  109cfe:	a3 80 1d 18 00       	mov    %eax,0x181d80
  109d03:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  109d06:	89 04 24             	mov    %eax,(%esp)
  109d09:	e8 9b 77 ff ff       	call   1014a9 <mem_free>
  109d0e:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  109d11:	89 04 24             	mov    %eax,(%esp)
  109d14:	e8 90 77 ff ff       	call   1014a9 <mem_free>
  109d19:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  109d1c:	89 04 24             	mov    %eax,(%esp)
  109d1f:	e8 85 77 ff ff       	call   1014a9 <mem_free>
  109d24:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  109d27:	89 04 24             	mov    %eax,(%esp)
  109d2a:	e8 7a 77 ff ff       	call   1014a9 <mem_free>
  109d2f:	c7 04 24 98 de 10 00 	movl   $0x10de98,(%esp)
  109d36:	e8 32 1b 00 00       	call   10b86d <cprintf>
  109d3b:	83 c4 44             	add    $0x44,%esp
  109d3e:	5b                   	pop    %ebx
  109d3f:	5d                   	pop    %ebp
  109d40:	c3                   	ret    
  109d41:	90                   	nop    
  109d42:	90                   	nop    
  109d43:	90                   	nop    

00109d44 <file_init>:


void
file_init(void)
{
  109d44:	55                   	push   %ebp
  109d45:	89 e5                	mov    %esp,%ebp
  109d47:	83 ec 18             	sub    $0x18,%esp
	if (!cpu_onboot())
  109d4a:	e8 22 00 00 00       	call   109d71 <cpu_onboot>
  109d4f:	85 c0                	test   %eax,%eax
  109d51:	74 1c                	je     109d6f <file_init+0x2b>
		return;

	spinlock_init(&file_lock);
  109d53:	c7 44 24 08 3b 00 00 	movl   $0x3b,0x8(%esp)
  109d5a:	00 
  109d5b:	c7 44 24 04 d8 de 10 	movl   $0x10ded8,0x4(%esp)
  109d62:	00 
  109d63:	c7 04 24 e0 1c 18 00 	movl   $0x181ce0,(%esp)
  109d6a:	e8 21 a1 ff ff       	call   103e90 <spinlock_init_>
}
  109d6f:	c9                   	leave  
  109d70:	c3                   	ret    

00109d71 <cpu_onboot>:
}

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  109d71:	55                   	push   %ebp
  109d72:	89 e5                	mov    %esp,%ebp
  109d74:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  109d77:	e8 0d 00 00 00       	call   109d89 <cpu_cur>
  109d7c:	3d 00 f0 10 00       	cmp    $0x10f000,%eax
  109d81:	0f 94 c0             	sete   %al
  109d84:	0f b6 c0             	movzbl %al,%eax
}
  109d87:	c9                   	leave  
  109d88:	c3                   	ret    

00109d89 <cpu_cur>:
  109d89:	55                   	push   %ebp
  109d8a:	89 e5                	mov    %esp,%ebp
  109d8c:	83 ec 28             	sub    $0x28,%esp
static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  109d8f:	89 65 fc             	mov    %esp,0xfffffffc(%ebp)
        return esp;
  109d92:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  109d95:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  109d98:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  109d9b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  109da0:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	assert(c->magic == CPU_MAGIC);
  109da3:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  109da6:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  109dac:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  109db1:	74 24                	je     109dd7 <cpu_cur+0x4e>
  109db3:	c7 44 24 0c e4 de 10 	movl   $0x10dee4,0xc(%esp)
  109dba:	00 
  109dbb:	c7 44 24 08 fa de 10 	movl   $0x10defa,0x8(%esp)
  109dc2:	00 
  109dc3:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  109dca:	00 
  109dcb:	c7 04 24 0f df 10 00 	movl   $0x10df0f,(%esp)
  109dd2:	e8 61 6b ff ff       	call   100938 <debug_panic>
	return c;
  109dd7:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
}
  109dda:	c9                   	leave  
  109ddb:	c3                   	ret    

00109ddc <file_initroot>:

void
file_initroot(proc *root)
{
  109ddc:	55                   	push   %ebp
  109ddd:	89 e5                	mov    %esp,%ebp
  109ddf:	83 ec 48             	sub    $0x48,%esp
	// Only one root process may perform external I/O directly -
	// all other processes do I/O indirectly via the process hierarchy.
	assert(root == proc_root);
  109de2:	a1 b0 24 18 00       	mov    0x1824b0,%eax
  109de7:	39 45 08             	cmp    %eax,0x8(%ebp)
  109dea:	74 24                	je     109e10 <file_initroot+0x34>
  109dec:	c7 44 24 0c 1c df 10 	movl   $0x10df1c,0xc(%esp)
  109df3:	00 
  109df4:	c7 44 24 08 fa de 10 	movl   $0x10defa,0x8(%esp)
  109dfb:	00 
  109dfc:	c7 44 24 04 43 00 00 	movl   $0x43,0x4(%esp)
  109e03:	00 
  109e04:	c7 04 24 d8 de 10 00 	movl   $0x10ded8,(%esp)
  109e0b:	e8 28 6b ff ff       	call   100938 <debug_panic>

	// Make sure the root process's page directory is loaded,
	// so that we can write into the root process's file area directly.
	cpu_cur()->proc = root;
  109e10:	e8 74 ff ff ff       	call   109d89 <cpu_cur>
  109e15:	89 c2                	mov    %eax,%edx
  109e17:	8b 45 08             	mov    0x8(%ebp),%eax
  109e1a:	89 82 b4 00 00 00    	mov    %eax,0xb4(%edx)
	lcr3(mem_phys(root->pdir));
  109e20:	8b 45 08             	mov    0x8(%ebp),%eax
  109e23:	8b 80 a0 06 00 00    	mov    0x6a0(%eax),%eax
  109e29:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)

static gcc_inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
  109e2c:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  109e2f:	0f 22 d8             	mov    %eax,%cr3

	// Enable read/write access on the file metadata area
	pmap_setperm(root->pdir, FILESVA, ROUNDUP(sizeof(filestate), PAGESIZE),
  109e32:	c7 45 e8 00 10 00 00 	movl   $0x1000,0xffffffe8(%ebp)
  109e39:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  109e3c:	05 0f 70 00 00       	add    $0x700f,%eax
  109e41:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  109e44:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  109e47:	ba 00 00 00 00       	mov    $0x0,%edx
  109e4c:	f7 75 e8             	divl   0xffffffe8(%ebp)
  109e4f:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  109e52:	29 d0                	sub    %edx,%eax
  109e54:	89 c2                	mov    %eax,%edx
  109e56:	8b 45 08             	mov    0x8(%ebp),%eax
  109e59:	8b 80 a0 06 00 00    	mov    0x6a0(%eax),%eax
  109e5f:	c7 44 24 0c 00 06 00 	movl   $0x600,0xc(%esp)
  109e66:	00 
  109e67:	89 54 24 08          	mov    %edx,0x8(%esp)
  109e6b:	c7 44 24 04 00 00 00 	movl   $0x80000000,0x4(%esp)
  109e72:	80 
  109e73:	89 04 24             	mov    %eax,(%esp)
  109e76:	e8 f7 e4 ff ff       	call   108372 <pmap_setperm>
				SYS_READ | SYS_WRITE);
	memset(files, 0, sizeof(*files));
  109e7b:	a1 d4 de 10 00       	mov    0x10ded4,%eax
  109e80:	c7 44 24 08 10 70 00 	movl   $0x7010,0x8(%esp)
  109e87:	00 
  109e88:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  109e8f:	00 
  109e90:	89 04 24             	mov    %eax,(%esp)
  109e93:	e8 59 1d 00 00       	call   10bbf1 <memset>

	// Set up the standard I/O descriptors for console I/O
	files->fd[0].ino = FILEINO_CONSIN;
  109e98:	a1 d4 de 10 00       	mov    0x10ded4,%eax
  109e9d:	c7 40 10 01 00 00 00 	movl   $0x1,0x10(%eax)
	files->fd[0].flags = O_RDONLY;
  109ea4:	a1 d4 de 10 00       	mov    0x10ded4,%eax
  109ea9:	c7 40 14 01 00 00 00 	movl   $0x1,0x14(%eax)
	files->fd[1].ino = FILEINO_CONSOUT;
  109eb0:	a1 d4 de 10 00       	mov    0x10ded4,%eax
  109eb5:	c7 40 20 02 00 00 00 	movl   $0x2,0x20(%eax)
	files->fd[1].flags = O_WRONLY | O_APPEND;
  109ebc:	a1 d4 de 10 00       	mov    0x10ded4,%eax
  109ec1:	c7 40 24 12 00 00 00 	movl   $0x12,0x24(%eax)
	files->fd[2].ino = FILEINO_CONSOUT;
  109ec8:	a1 d4 de 10 00       	mov    0x10ded4,%eax
  109ecd:	c7 40 30 02 00 00 00 	movl   $0x2,0x30(%eax)
	files->fd[2].flags = O_WRONLY | O_APPEND;
  109ed4:	a1 d4 de 10 00       	mov    0x10ded4,%eax
  109ed9:	c7 40 34 12 00 00 00 	movl   $0x12,0x34(%eax)

	// Setup the inodes for the console I/O files and root directory
	strcpy(files->fi[FILEINO_CONSIN].de.d_name, "consin");
  109ee0:	a1 d4 de 10 00       	mov    0x10ded4,%eax
  109ee5:	05 70 10 00 00       	add    $0x1070,%eax
  109eea:	c7 44 24 04 2e df 10 	movl   $0x10df2e,0x4(%esp)
  109ef1:	00 
  109ef2:	89 04 24             	mov    %eax,(%esp)
  109ef5:	e8 50 1b 00 00       	call   10ba4a <strcpy>
	strcpy(files->fi[FILEINO_CONSOUT].de.d_name, "consout");
  109efa:	a1 d4 de 10 00       	mov    0x10ded4,%eax
  109eff:	05 cc 10 00 00       	add    $0x10cc,%eax
  109f04:	c7 44 24 04 35 df 10 	movl   $0x10df35,0x4(%esp)
  109f0b:	00 
  109f0c:	89 04 24             	mov    %eax,(%esp)
  109f0f:	e8 36 1b 00 00       	call   10ba4a <strcpy>
	strcpy(files->fi[FILEINO_ROOTDIR].de.d_name, "/");
  109f14:	a1 d4 de 10 00       	mov    0x10ded4,%eax
  109f19:	05 28 11 00 00       	add    $0x1128,%eax
  109f1e:	c7 44 24 04 3d df 10 	movl   $0x10df3d,0x4(%esp)
  109f25:	00 
  109f26:	89 04 24             	mov    %eax,(%esp)
  109f29:	e8 1c 1b 00 00       	call   10ba4a <strcpy>
	files->fi[FILEINO_CONSIN].dino = FILEINO_ROOTDIR;
  109f2e:	a1 d4 de 10 00       	mov    0x10ded4,%eax
  109f33:	c7 80 6c 10 00 00 03 	movl   $0x3,0x106c(%eax)
  109f3a:	00 00 00 
	files->fi[FILEINO_CONSOUT].dino = FILEINO_ROOTDIR;
  109f3d:	a1 d4 de 10 00       	mov    0x10ded4,%eax
  109f42:	c7 80 c8 10 00 00 03 	movl   $0x3,0x10c8(%eax)
  109f49:	00 00 00 
	files->fi[FILEINO_ROOTDIR].dino = FILEINO_ROOTDIR;
  109f4c:	a1 d4 de 10 00       	mov    0x10ded4,%eax
  109f51:	c7 80 24 11 00 00 03 	movl   $0x3,0x1124(%eax)
  109f58:	00 00 00 
	files->fi[FILEINO_CONSIN].mode = S_IFREG | S_IFPART;
  109f5b:	a1 d4 de 10 00       	mov    0x10ded4,%eax
  109f60:	c7 80 b4 10 00 00 00 	movl   $0x9000,0x10b4(%eax)
  109f67:	90 00 00 
	files->fi[FILEINO_CONSOUT].mode = S_IFREG;
  109f6a:	a1 d4 de 10 00       	mov    0x10ded4,%eax
  109f6f:	c7 80 10 11 00 00 00 	movl   $0x1000,0x1110(%eax)
  109f76:	10 00 00 
	files->fi[FILEINO_ROOTDIR].mode = S_IFDIR;
  109f79:	a1 d4 de 10 00       	mov    0x10ded4,%eax
  109f7e:	c7 80 6c 11 00 00 00 	movl   $0x2000,0x116c(%eax)
  109f85:	20 00 00 

	// Set the whole console input area to be read/write,
	// so we won't have to worry about perms in cons_io().
	pmap_setperm(root->pdir, (uintptr_t)FILEDATA(FILEINO_CONSIN),
  109f88:	8b 45 08             	mov    0x8(%ebp),%eax
  109f8b:	8b 80 a0 06 00 00    	mov    0x6a0(%eax),%eax
  109f91:	c7 44 24 0c 00 06 00 	movl   $0x600,0xc(%esp)
  109f98:	00 
  109f99:	c7 44 24 08 00 00 40 	movl   $0x400000,0x8(%esp)
  109fa0:	00 
  109fa1:	c7 44 24 04 00 00 40 	movl   $0x80400000,0x4(%esp)
  109fa8:	80 
  109fa9:	89 04 24             	mov    %eax,(%esp)
  109fac:	e8 c1 e3 ff ff       	call   108372 <pmap_setperm>
				PTSIZE, SYS_READ | SYS_WRITE);

	// Set up the initial files in the root process's file system.
	// Some script magic in kern/Makefrag creates obj/kern/initfiles.h,
	// which gets included above (twice) to create the 'initfiles' array.
	// For each initial file numbered 0 <= i < ninitfiles,
	// initfiles[i][0] is a pointer to the filename string for that file,
	// initfiles[i][1] is a pointer to the start of the file's content, and
	// initfiles[i][2] is a pointer to the end of the file's content
	// (i.e., a pointer to the first byte after the file's last byte).
	int ninitfiles = sizeof(initfiles)/sizeof(initfiles[0]);
  109fb1:	c7 45 dc 07 00 00 00 	movl   $0x7,0xffffffdc(%ebp)
	int i;
	int ino = FILEINO_GENERAL;
  109fb8:	c7 45 e4 04 00 00 00 	movl   $0x4,0xffffffe4(%ebp)
	for (i = 0; i < ninitfiles; i++) {
  109fbf:	c7 45 e0 00 00 00 00 	movl   $0x0,0xffffffe0(%ebp)
  109fc6:	e9 39 01 00 00       	jmp    10a104 <file_initroot+0x328>
		int filesize = initfiles[i][2] - initfiles[i][1];
  109fcb:	8b 55 e0             	mov    0xffffffe0(%ebp),%edx
  109fce:	89 d0                	mov    %edx,%eax
  109fd0:	01 c0                	add    %eax,%eax
  109fd2:	01 d0                	add    %edx,%eax
  109fd4:	c1 e0 02             	shl    $0x2,%eax
  109fd7:	8b 80 28 00 11 00    	mov    0x110028(%eax),%eax
  109fdd:	89 c1                	mov    %eax,%ecx
  109fdf:	8b 55 e0             	mov    0xffffffe0(%ebp),%edx
  109fe2:	89 d0                	mov    %edx,%eax
  109fe4:	01 c0                	add    %eax,%eax
  109fe6:	01 d0                	add    %edx,%eax
  109fe8:	c1 e0 02             	shl    $0x2,%eax
  109feb:	8b 80 24 00 11 00    	mov    0x110024(%eax),%eax
  109ff1:	89 ca                	mov    %ecx,%edx
  109ff3:	29 c2                	sub    %eax,%edx
  109ff5:	89 d0                	mov    %edx,%eax
  109ff7:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
		strcpy(files->fi[ino].de.d_name, initfiles[i][0]);
  109ffa:	8b 55 e0             	mov    0xffffffe0(%ebp),%edx
  109ffd:	89 d0                	mov    %edx,%eax
  109fff:	01 c0                	add    %eax,%eax
  10a001:	01 d0                	add    %edx,%eax
  10a003:	c1 e0 02             	shl    $0x2,%eax
  10a006:	8b 88 20 00 11 00    	mov    0x110020(%eax),%ecx
  10a00c:	8b 15 d4 de 10 00    	mov    0x10ded4,%edx
  10a012:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  10a015:	6b c0 5c             	imul   $0x5c,%eax,%eax
  10a018:	05 10 10 00 00       	add    $0x1010,%eax
  10a01d:	8d 04 02             	lea    (%edx,%eax,1),%eax
  10a020:	83 c0 04             	add    $0x4,%eax
  10a023:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  10a027:	89 04 24             	mov    %eax,(%esp)
  10a02a:	e8 1b 1a 00 00       	call   10ba4a <strcpy>
		files->fi[ino].dino = FILEINO_ROOTDIR;
  10a02f:	8b 15 d4 de 10 00    	mov    0x10ded4,%edx
  10a035:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  10a038:	6b c0 5c             	imul   $0x5c,%eax,%eax
  10a03b:	01 d0                	add    %edx,%eax
  10a03d:	05 10 10 00 00       	add    $0x1010,%eax
  10a042:	c7 00 03 00 00 00    	movl   $0x3,(%eax)
		files->fi[ino].mode = S_IFREG;
  10a048:	8b 15 d4 de 10 00    	mov    0x10ded4,%edx
  10a04e:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  10a051:	6b c0 5c             	imul   $0x5c,%eax,%eax
  10a054:	01 d0                	add    %edx,%eax
  10a056:	05 58 10 00 00       	add    $0x1058,%eax
  10a05b:	c7 00 00 10 00 00    	movl   $0x1000,(%eax)
		files->fi[ino].size = filesize;
  10a061:	8b 15 d4 de 10 00    	mov    0x10ded4,%edx
  10a067:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  10a06a:	8b 4d f0             	mov    0xfffffff0(%ebp),%ecx
  10a06d:	6b c0 5c             	imul   $0x5c,%eax,%eax
  10a070:	01 d0                	add    %edx,%eax
  10a072:	05 5c 10 00 00       	add    $0x105c,%eax
  10a077:	89 08                	mov    %ecx,(%eax)
		pmap_setperm(root->pdir, (uintptr_t)FILEDATA(ino),
					ROUNDUP(filesize, PAGESIZE),
  10a079:	c7 45 f4 00 10 00 00 	movl   $0x1000,0xfffffff4(%ebp)
  10a080:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  10a083:	03 45 f4             	add    0xfffffff4(%ebp),%eax
  10a086:	83 e8 01             	sub    $0x1,%eax
  10a089:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  10a08c:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10a08f:	ba 00 00 00 00       	mov    $0x0,%edx
  10a094:	f7 75 f4             	divl   0xfffffff4(%ebp)
  10a097:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10a09a:	29 d0                	sub    %edx,%eax
  10a09c:	89 c1                	mov    %eax,%ecx
  10a09e:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  10a0a1:	c1 e0 16             	shl    $0x16,%eax
  10a0a4:	2d 00 00 00 80       	sub    $0x80000000,%eax
  10a0a9:	89 c2                	mov    %eax,%edx
  10a0ab:	8b 45 08             	mov    0x8(%ebp),%eax
  10a0ae:	8b 80 a0 06 00 00    	mov    0x6a0(%eax),%eax
  10a0b4:	c7 44 24 0c 00 06 00 	movl   $0x600,0xc(%esp)
  10a0bb:	00 
  10a0bc:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  10a0c0:	89 54 24 04          	mov    %edx,0x4(%esp)
  10a0c4:	89 04 24             	mov    %eax,(%esp)
  10a0c7:	e8 a6 e2 ff ff       	call   108372 <pmap_setperm>
					SYS_READ | SYS_WRITE);
		memcpy(FILEDATA(ino), initfiles[i][1], filesize);
  10a0cc:	8b 4d f0             	mov    0xfffffff0(%ebp),%ecx
  10a0cf:	8b 55 e0             	mov    0xffffffe0(%ebp),%edx
  10a0d2:	89 d0                	mov    %edx,%eax
  10a0d4:	01 c0                	add    %eax,%eax
  10a0d6:	01 d0                	add    %edx,%eax
  10a0d8:	c1 e0 02             	shl    $0x2,%eax
  10a0db:	8b 90 24 00 11 00    	mov    0x110024(%eax),%edx
  10a0e1:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  10a0e4:	c1 e0 16             	shl    $0x16,%eax
  10a0e7:	2d 00 00 00 80       	sub    $0x80000000,%eax
  10a0ec:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  10a0f0:	89 54 24 04          	mov    %edx,0x4(%esp)
  10a0f4:	89 04 24             	mov    %eax,(%esp)
  10a0f7:	e8 34 1c 00 00       	call   10bd30 <memcpy>
		ino++;
  10a0fc:	83 45 e4 01          	addl   $0x1,0xffffffe4(%ebp)
  10a100:	83 45 e0 01          	addl   $0x1,0xffffffe0(%ebp)
  10a104:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  10a107:	3b 45 dc             	cmp    0xffffffdc(%ebp),%eax
  10a10a:	0f 8c bb fe ff ff    	jl     109fcb <file_initroot+0x1ef>
	}

	// Set root process's current working directory
	files->cwd = FILEINO_ROOTDIR;
  10a110:	a1 d4 de 10 00       	mov    0x10ded4,%eax
  10a115:	c7 40 04 03 00 00 00 	movl   $0x3,0x4(%eax)

	// Child process state - reserve PID 0 as a "scratch" child process.
	files->child[0].state = PROC_RESERVED;
  10a11c:	a1 d4 de 10 00       	mov    0x10ded4,%eax
  10a121:	c7 80 10 6c 00 00 ff 	movl   $0xffffffff,0x6c10(%eax)
  10a128:	ff ff ff 
}
  10a12b:	c9                   	leave  
  10a12c:	c3                   	ret    

0010a12d <file_io>:

// Called from proc_ret() when the root process "returns" -
// this function performs any new output the root process requested,
// or if it didn't request output, puts the root process to sleep
// waiting for input to arrive from some I/O device.
void
file_io(trapframe *tf)
{
  10a12d:	55                   	push   %ebp
  10a12e:	89 e5                	mov    %esp,%ebp
  10a130:	83 ec 28             	sub    $0x28,%esp
	proc *cp = proc_cur();
  10a133:	e8 51 fc ff ff       	call   109d89 <cpu_cur>
  10a138:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  10a13e:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
	assert(cp == proc_root);	// only root process should do this!
  10a141:	a1 b0 24 18 00       	mov    0x1824b0,%eax
  10a146:	39 45 f8             	cmp    %eax,0xfffffff8(%ebp)
  10a149:	74 24                	je     10a16f <file_io+0x42>
  10a14b:	c7 44 24 0c 3f df 10 	movl   $0x10df3f,0xc(%esp)
  10a152:	00 
  10a153:	c7 44 24 08 fa de 10 	movl   $0x10defa,0x8(%esp)
  10a15a:	00 
  10a15b:	c7 44 24 04 8e 00 00 	movl   $0x8e,0x4(%esp)
  10a162:	00 
  10a163:	c7 04 24 d8 de 10 00 	movl   $0x10ded8,(%esp)
  10a16a:	e8 c9 67 ff ff       	call   100938 <debug_panic>

	// Note that we don't need to bother protecting ourselves
	// against memory access traps while accessing user memory here,
	// because we consider the root process a special, "trusted" process:
	// the whole system goes down anyway if the root process goes haywire.
	// This is very different from handling system calls
	// on behalf of arbitrary processes that might be buggy or evil.

	// Perform I/O with whatever devices we have access to.
	bool iodone = 0;
  10a16f:	c7 45 fc 00 00 00 00 	movl   $0x0,0xfffffffc(%ebp)
	iodone |= cons_io();
  10a176:	e8 26 66 ff ff       	call   1007a1 <cons_io>
  10a17b:	09 45 fc             	or     %eax,0xfffffffc(%ebp)

	// Has the root process exited?
	if (files->exited) {
  10a17e:	a1 d4 de 10 00       	mov    0x10ded4,%eax
  10a183:	8b 40 08             	mov    0x8(%eax),%eax
  10a186:	85 c0                	test   %eax,%eax
  10a188:	74 1d                	je     10a1a7 <file_io+0x7a>
		cprintf("root process exited with status %d\n", files->status);
  10a18a:	a1 d4 de 10 00       	mov    0x10ded4,%eax
  10a18f:	8b 40 0c             	mov    0xc(%eax),%eax
  10a192:	89 44 24 04          	mov    %eax,0x4(%esp)
  10a196:	c7 04 24 50 df 10 00 	movl   $0x10df50,(%esp)
  10a19d:	e8 cb 16 00 00       	call   10b86d <cprintf>
		done();
  10a1a2:	e8 9e 63 ff ff       	call   100545 <done>
	}

	// We successfully did some I/O, let the root process run again.
	if (iodone)
  10a1a7:	83 7d fc 00          	cmpl   $0x0,0xfffffffc(%ebp)
  10a1ab:	74 0b                	je     10a1b8 <file_io+0x8b>
		trap_return(tf);
  10a1ad:	8b 45 08             	mov    0x8(%ebp),%eax
  10a1b0:	89 04 24             	mov    %eax,(%esp)
  10a1b3:	e8 a8 98 ff ff       	call   103a60 <trap_return>

	// No I/O ready - put the root process to sleep waiting for I/O.
	spinlock_acquire(&file_lock);
  10a1b8:	c7 04 24 e0 1c 18 00 	movl   $0x181ce0,(%esp)
  10a1bf:	e8 f6 9c ff ff       	call   103eba <spinlock_acquire>
	cp->state = PROC_STOP;		// we're becoming stopped
  10a1c4:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10a1c7:	c7 80 3c 04 00 00 00 	movl   $0x0,0x43c(%eax)
  10a1ce:	00 00 00 
	cp->runcpu = NULL;		// no longer running
  10a1d1:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10a1d4:	c7 80 44 04 00 00 00 	movl   $0x0,0x444(%eax)
  10a1db:	00 00 00 
	proc_save(cp, tf, 1);		// save process's state
  10a1de:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
  10a1e5:	00 
  10a1e6:	8b 45 08             	mov    0x8(%ebp),%eax
  10a1e9:	89 44 24 04          	mov    %eax,0x4(%esp)
  10a1ed:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10a1f0:	89 04 24             	mov    %eax,(%esp)
  10a1f3:	e8 8b a6 ff ff       	call   104883 <proc_save>
	spinlock_release(&file_lock);
  10a1f8:	c7 04 24 e0 1c 18 00 	movl   $0x181ce0,(%esp)
  10a1ff:	e8 b1 9d ff ff       	call   103fb5 <spinlock_release>

	proc_sched();			// go do something else
  10a204:	e8 ec a7 ff ff       	call   1049f5 <proc_sched>

0010a209 <file_wakeroot>:
}

// Check to see if any input is available for the root process
// and if the root process is waiting for it, and if so, wake the process.
void
file_wakeroot(void)
{
  10a209:	55                   	push   %ebp
  10a20a:	89 e5                	mov    %esp,%ebp
  10a20c:	83 ec 08             	sub    $0x8,%esp
	spinlock_acquire(&file_lock);
  10a20f:	c7 04 24 e0 1c 18 00 	movl   $0x181ce0,(%esp)
  10a216:	e8 9f 9c ff ff       	call   103eba <spinlock_acquire>
	if (proc_root && proc_root->state == PROC_STOP)
  10a21b:	a1 b0 24 18 00       	mov    0x1824b0,%eax
  10a220:	85 c0                	test   %eax,%eax
  10a222:	74 1c                	je     10a240 <file_wakeroot+0x37>
  10a224:	a1 b0 24 18 00       	mov    0x1824b0,%eax
  10a229:	8b 80 3c 04 00 00    	mov    0x43c(%eax),%eax
  10a22f:	85 c0                	test   %eax,%eax
  10a231:	75 0d                	jne    10a240 <file_wakeroot+0x37>
		proc_ready(proc_root);
  10a233:	a1 b0 24 18 00       	mov    0x1824b0,%eax
  10a238:	89 04 24             	mov    %eax,(%esp)
  10a23b:	e8 f1 a5 ff ff       	call   104831 <proc_ready>
	spinlock_release(&file_lock);
  10a240:	c7 04 24 e0 1c 18 00 	movl   $0x181ce0,(%esp)
  10a247:	e8 69 9d ff ff       	call   103fb5 <spinlock_release>
}
  10a24c:	c9                   	leave  
  10a24d:	c3                   	ret    
  10a24e:	90                   	nop    
  10a24f:	90                   	nop    

0010a250 <video_init>:
static uint16_t crt_pos;

void
video_init(void)
{
  10a250:	55                   	push   %ebp
  10a251:	89 e5                	mov    %esp,%ebp
  10a253:	83 ec 30             	sub    $0x30,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	/* Get a pointer to the memory-mapped text display buffer. */
	cp = (uint16_t*) mem_ptr(CGA_BUF);
  10a256:	c7 45 d4 00 80 0b 00 	movl   $0xb8000,0xffffffd4(%ebp)
	was = *cp;
  10a25d:	8b 45 d4             	mov    0xffffffd4(%ebp),%eax
  10a260:	0f b7 00             	movzwl (%eax),%eax
  10a263:	66 89 45 da          	mov    %ax,0xffffffda(%ebp)
	*cp = (uint16_t) 0xA55A;
  10a267:	8b 45 d4             	mov    0xffffffd4(%ebp),%eax
  10a26a:	66 c7 00 5a a5       	movw   $0xa55a,(%eax)
	if (*cp != 0xA55A) {
  10a26f:	8b 45 d4             	mov    0xffffffd4(%ebp),%eax
  10a272:	0f b7 00             	movzwl (%eax),%eax
  10a275:	66 3d 5a a5          	cmp    $0xa55a,%ax
  10a279:	74 13                	je     10a28e <video_init+0x3e>
		cp = (uint16_t*) mem_ptr(MONO_BUF);
  10a27b:	c7 45 d4 00 00 0b 00 	movl   $0xb0000,0xffffffd4(%ebp)
		addr_6845 = MONO_BASE;
  10a282:	c7 05 1c 1d 18 00 b4 	movl   $0x3b4,0x181d1c
  10a289:	03 00 00 
  10a28c:	eb 14                	jmp    10a2a2 <video_init+0x52>
	} else {
		*cp = was;
  10a28e:	8b 55 d4             	mov    0xffffffd4(%ebp),%edx
  10a291:	0f b7 45 da          	movzwl 0xffffffda(%ebp),%eax
  10a295:	66 89 02             	mov    %ax,(%edx)
		addr_6845 = CGA_BASE;
  10a298:	c7 05 1c 1d 18 00 d4 	movl   $0x3d4,0x181d1c
  10a29f:	03 00 00 
	}
	
	/* Extract cursor location */
	outb(addr_6845, 14);
  10a2a2:	a1 1c 1d 18 00       	mov    0x181d1c,%eax
  10a2a7:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
  10a2aa:	c6 45 e3 0e          	movb   $0xe,0xffffffe3(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  10a2ae:	0f b6 45 e3          	movzbl 0xffffffe3(%ebp),%eax
  10a2b2:	8b 55 e4             	mov    0xffffffe4(%ebp),%edx
  10a2b5:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
  10a2b6:	a1 1c 1d 18 00       	mov    0x181d1c,%eax
  10a2bb:	83 c0 01             	add    $0x1,%eax
  10a2be:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  10a2c1:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
  10a2c4:	ec                   	in     (%dx),%al
  10a2c5:	88 45 eb             	mov    %al,0xffffffeb(%ebp)
	return data;
  10a2c8:	0f b6 45 eb          	movzbl 0xffffffeb(%ebp),%eax
  10a2cc:	0f b6 c0             	movzbl %al,%eax
  10a2cf:	c1 e0 08             	shl    $0x8,%eax
  10a2d2:	89 45 dc             	mov    %eax,0xffffffdc(%ebp)
	outb(addr_6845, 15);
  10a2d5:	a1 1c 1d 18 00       	mov    0x181d1c,%eax
  10a2da:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
  10a2dd:	c6 45 f3 0f          	movb   $0xf,0xfffffff3(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  10a2e1:	0f b6 45 f3          	movzbl 0xfffffff3(%ebp),%eax
  10a2e5:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  10a2e8:	ee                   	out    %al,(%dx)
	pos |= inb(addr_6845 + 1);
  10a2e9:	a1 1c 1d 18 00       	mov    0x181d1c,%eax
  10a2ee:	83 c0 01             	add    $0x1,%eax
  10a2f1:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  10a2f4:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  10a2f7:	ec                   	in     (%dx),%al
  10a2f8:	88 45 fb             	mov    %al,0xfffffffb(%ebp)
	return data;
  10a2fb:	0f b6 45 fb          	movzbl 0xfffffffb(%ebp),%eax
  10a2ff:	0f b6 c0             	movzbl %al,%eax
  10a302:	09 45 dc             	or     %eax,0xffffffdc(%ebp)

	crt_buf = (uint16_t*) cp;
  10a305:	8b 45 d4             	mov    0xffffffd4(%ebp),%eax
  10a308:	a3 20 1d 18 00       	mov    %eax,0x181d20
	crt_pos = pos;
  10a30d:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  10a310:	66 a3 24 1d 18 00    	mov    %ax,0x181d24
}
  10a316:	c9                   	leave  
  10a317:	c3                   	ret    

0010a318 <video_putc>:



void
video_putc(int c)
{
  10a318:	55                   	push   %ebp
  10a319:	89 e5                	mov    %esp,%ebp
  10a31b:	53                   	push   %ebx
  10a31c:	83 ec 44             	sub    $0x44,%esp
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
  10a31f:	8b 45 08             	mov    0x8(%ebp),%eax
  10a322:	b0 00                	mov    $0x0,%al
  10a324:	85 c0                	test   %eax,%eax
  10a326:	75 07                	jne    10a32f <video_putc+0x17>
		c |= 0x0700;
  10a328:	81 4d 08 00 07 00 00 	orl    $0x700,0x8(%ebp)

	switch (c & 0xff) {
  10a32f:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
  10a333:	89 45 c4             	mov    %eax,0xffffffc4(%ebp)
  10a336:	83 7d c4 09          	cmpl   $0x9,0xffffffc4(%ebp)
  10a33a:	0f 84 c0 00 00 00    	je     10a400 <video_putc+0xe8>
  10a340:	83 7d c4 09          	cmpl   $0x9,0xffffffc4(%ebp)
  10a344:	7f 0b                	jg     10a351 <video_putc+0x39>
  10a346:	83 7d c4 08          	cmpl   $0x8,0xffffffc4(%ebp)
  10a34a:	74 16                	je     10a362 <video_putc+0x4a>
  10a34c:	e9 ed 00 00 00       	jmp    10a43e <video_putc+0x126>
  10a351:	83 7d c4 0a          	cmpl   $0xa,0xffffffc4(%ebp)
  10a355:	74 50                	je     10a3a7 <video_putc+0x8f>
  10a357:	83 7d c4 0d          	cmpl   $0xd,0xffffffc4(%ebp)
  10a35b:	74 5a                	je     10a3b7 <video_putc+0x9f>
  10a35d:	e9 dc 00 00 00       	jmp    10a43e <video_putc+0x126>
	case '\b':
		if (crt_pos > 0) {
  10a362:	0f b7 05 24 1d 18 00 	movzwl 0x181d24,%eax
  10a369:	66 85 c0             	test   %ax,%ax
  10a36c:	0f 84 f0 00 00 00    	je     10a462 <video_putc+0x14a>
			crt_pos--;
  10a372:	0f b7 05 24 1d 18 00 	movzwl 0x181d24,%eax
  10a379:	83 e8 01             	sub    $0x1,%eax
  10a37c:	66 a3 24 1d 18 00    	mov    %ax,0x181d24
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
  10a382:	0f b7 05 24 1d 18 00 	movzwl 0x181d24,%eax
  10a389:	0f b7 c0             	movzwl %ax,%eax
  10a38c:	01 c0                	add    %eax,%eax
  10a38e:	89 c2                	mov    %eax,%edx
  10a390:	a1 20 1d 18 00       	mov    0x181d20,%eax
  10a395:	01 c2                	add    %eax,%edx
  10a397:	8b 45 08             	mov    0x8(%ebp),%eax
  10a39a:	b0 00                	mov    $0x0,%al
  10a39c:	83 c8 20             	or     $0x20,%eax
  10a39f:	66 89 02             	mov    %ax,(%edx)
		}
		break;
  10a3a2:	e9 bb 00 00 00       	jmp    10a462 <video_putc+0x14a>
	case '\n':
		crt_pos += CRT_COLS;
  10a3a7:	0f b7 05 24 1d 18 00 	movzwl 0x181d24,%eax
  10a3ae:	83 c0 50             	add    $0x50,%eax
  10a3b1:	66 a3 24 1d 18 00    	mov    %ax,0x181d24
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
  10a3b7:	0f b7 0d 24 1d 18 00 	movzwl 0x181d24,%ecx
  10a3be:	0f b7 15 24 1d 18 00 	movzwl 0x181d24,%edx
  10a3c5:	0f b7 c2             	movzwl %dx,%eax
  10a3c8:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
  10a3ce:	c1 e8 10             	shr    $0x10,%eax
  10a3d1:	89 c3                	mov    %eax,%ebx
  10a3d3:	66 c1 eb 06          	shr    $0x6,%bx
  10a3d7:	66 89 5d ca          	mov    %bx,0xffffffca(%ebp)
  10a3db:	0f b7 45 ca          	movzwl 0xffffffca(%ebp),%eax
  10a3df:	c1 e0 02             	shl    $0x2,%eax
  10a3e2:	66 03 45 ca          	add    0xffffffca(%ebp),%ax
  10a3e6:	c1 e0 04             	shl    $0x4,%eax
  10a3e9:	89 d3                	mov    %edx,%ebx
  10a3eb:	66 29 c3             	sub    %ax,%bx
  10a3ee:	66 89 5d ca          	mov    %bx,0xffffffca(%ebp)
  10a3f2:	89 c8                	mov    %ecx,%eax
  10a3f4:	66 2b 45 ca          	sub    0xffffffca(%ebp),%ax
  10a3f8:	66 a3 24 1d 18 00    	mov    %ax,0x181d24
		break;
  10a3fe:	eb 62                	jmp    10a462 <video_putc+0x14a>
	case '\t':
		video_putc(' ');
  10a400:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  10a407:	e8 0c ff ff ff       	call   10a318 <video_putc>
		video_putc(' ');
  10a40c:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  10a413:	e8 00 ff ff ff       	call   10a318 <video_putc>
		video_putc(' ');
  10a418:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  10a41f:	e8 f4 fe ff ff       	call   10a318 <video_putc>
		video_putc(' ');
  10a424:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  10a42b:	e8 e8 fe ff ff       	call   10a318 <video_putc>
		video_putc(' ');
  10a430:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  10a437:	e8 dc fe ff ff       	call   10a318 <video_putc>
		break;
  10a43c:	eb 24                	jmp    10a462 <video_putc+0x14a>
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
  10a43e:	0f b7 0d 24 1d 18 00 	movzwl 0x181d24,%ecx
  10a445:	0f b7 c1             	movzwl %cx,%eax
  10a448:	01 c0                	add    %eax,%eax
  10a44a:	89 c2                	mov    %eax,%edx
  10a44c:	a1 20 1d 18 00       	mov    0x181d20,%eax
  10a451:	01 c2                	add    %eax,%edx
  10a453:	8b 45 08             	mov    0x8(%ebp),%eax
  10a456:	66 89 02             	mov    %ax,(%edx)
  10a459:	8d 41 01             	lea    0x1(%ecx),%eax
  10a45c:	66 a3 24 1d 18 00    	mov    %ax,0x181d24
		break;
	}

	/* scroll if necessary */
	if (crt_pos >= CRT_SIZE) {
  10a462:	0f b7 05 24 1d 18 00 	movzwl 0x181d24,%eax
  10a469:	66 3d cf 07          	cmp    $0x7cf,%ax
  10a46d:	76 5e                	jbe    10a4cd <video_putc+0x1b5>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS,
  10a46f:	a1 20 1d 18 00       	mov    0x181d20,%eax
  10a474:	05 a0 00 00 00       	add    $0xa0,%eax
  10a479:	8b 15 20 1d 18 00    	mov    0x181d20,%edx
  10a47f:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
  10a486:	00 
  10a487:	89 44 24 04          	mov    %eax,0x4(%esp)
  10a48b:	89 14 24             	mov    %edx,(%esp)
  10a48e:	e8 d7 17 00 00       	call   10bc6a <memmove>
			(CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
  10a493:	c7 45 d8 80 07 00 00 	movl   $0x780,0xffffffd8(%ebp)
  10a49a:	eb 18                	jmp    10a4b4 <video_putc+0x19c>
			crt_buf[i] = 0x0700 | ' ';
  10a49c:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  10a49f:	01 c0                	add    %eax,%eax
  10a4a1:	89 c2                	mov    %eax,%edx
  10a4a3:	a1 20 1d 18 00       	mov    0x181d20,%eax
  10a4a8:	8d 04 02             	lea    (%edx,%eax,1),%eax
  10a4ab:	66 c7 00 20 07       	movw   $0x720,(%eax)
  10a4b0:	83 45 d8 01          	addl   $0x1,0xffffffd8(%ebp)
  10a4b4:	81 7d d8 cf 07 00 00 	cmpl   $0x7cf,0xffffffd8(%ebp)
  10a4bb:	7e df                	jle    10a49c <video_putc+0x184>
		crt_pos -= CRT_COLS;
  10a4bd:	0f b7 05 24 1d 18 00 	movzwl 0x181d24,%eax
  10a4c4:	83 e8 50             	sub    $0x50,%eax
  10a4c7:	66 a3 24 1d 18 00    	mov    %ax,0x181d24
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
  10a4cd:	a1 1c 1d 18 00       	mov    0x181d1c,%eax
  10a4d2:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)
  10a4d5:	c6 45 df 0e          	movb   $0xe,0xffffffdf(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  10a4d9:	0f b6 45 df          	movzbl 0xffffffdf(%ebp),%eax
  10a4dd:	8b 55 e0             	mov    0xffffffe0(%ebp),%edx
  10a4e0:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
  10a4e1:	0f b7 05 24 1d 18 00 	movzwl 0x181d24,%eax
  10a4e8:	66 c1 e8 08          	shr    $0x8,%ax
  10a4ec:	0f b6 d0             	movzbl %al,%edx
  10a4ef:	a1 1c 1d 18 00       	mov    0x181d1c,%eax
  10a4f4:	83 c0 01             	add    $0x1,%eax
  10a4f7:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  10a4fa:	88 55 e7             	mov    %dl,0xffffffe7(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  10a4fd:	0f b6 45 e7          	movzbl 0xffffffe7(%ebp),%eax
  10a501:	8b 55 e8             	mov    0xffffffe8(%ebp),%edx
  10a504:	ee                   	out    %al,(%dx)
	outb(addr_6845, 15);
  10a505:	a1 1c 1d 18 00       	mov    0x181d1c,%eax
  10a50a:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
  10a50d:	c6 45 ef 0f          	movb   $0xf,0xffffffef(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  10a511:	0f b6 45 ef          	movzbl 0xffffffef(%ebp),%eax
  10a515:	8b 55 f0             	mov    0xfffffff0(%ebp),%edx
  10a518:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos);
  10a519:	0f b7 05 24 1d 18 00 	movzwl 0x181d24,%eax
  10a520:	0f b6 d0             	movzbl %al,%edx
  10a523:	a1 1c 1d 18 00       	mov    0x181d1c,%eax
  10a528:	83 c0 01             	add    $0x1,%eax
  10a52b:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  10a52e:	88 55 f7             	mov    %dl,0xfffffff7(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  10a531:	0f b6 45 f7          	movzbl 0xfffffff7(%ebp),%eax
  10a535:	8b 55 f8             	mov    0xfffffff8(%ebp),%edx
  10a538:	ee                   	out    %al,(%dx)
}
  10a539:	83 c4 44             	add    $0x44,%esp
  10a53c:	5b                   	pop    %ebx
  10a53d:	5d                   	pop    %ebp
  10a53e:	c3                   	ret    
  10a53f:	90                   	nop    

0010a540 <kbd_proc_data>:
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
  10a540:	55                   	push   %ebp
  10a541:	89 e5                	mov    %esp,%ebp
  10a543:	83 ec 38             	sub    $0x38,%esp
  10a546:	c7 45 ec 64 00 00 00 	movl   $0x64,0xffffffec(%ebp)
static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  10a54d:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
  10a550:	ec                   	in     (%dx),%al
  10a551:	88 45 eb             	mov    %al,0xffffffeb(%ebp)
	return data;
  10a554:	0f b6 45 eb          	movzbl 0xffffffeb(%ebp),%eax
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
  10a558:	0f b6 c0             	movzbl %al,%eax
  10a55b:	83 e0 01             	and    $0x1,%eax
  10a55e:	85 c0                	test   %eax,%eax
  10a560:	75 0c                	jne    10a56e <kbd_proc_data+0x2e>
		return -1;
  10a562:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,0xffffffd8(%ebp)
  10a569:	e9 69 01 00 00       	jmp    10a6d7 <kbd_proc_data+0x197>
  10a56e:	c7 45 f4 60 00 00 00 	movl   $0x60,0xfffffff4(%ebp)
static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  10a575:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  10a578:	ec                   	in     (%dx),%al
  10a579:	88 45 f3             	mov    %al,0xfffffff3(%ebp)
	return data;
  10a57c:	0f b6 45 f3          	movzbl 0xfffffff3(%ebp),%eax

	data = inb(KBDATAP);
  10a580:	88 45 ea             	mov    %al,0xffffffea(%ebp)

	if (data == 0xE0) {
  10a583:	80 7d ea e0          	cmpb   $0xe0,0xffffffea(%ebp)
  10a587:	75 19                	jne    10a5a2 <kbd_proc_data+0x62>
		// E0 escape character
		shift |= E0ESC;
  10a589:	a1 28 1d 18 00       	mov    0x181d28,%eax
  10a58e:	83 c8 40             	or     $0x40,%eax
  10a591:	a3 28 1d 18 00       	mov    %eax,0x181d28
		return 0;
  10a596:	c7 45 d8 00 00 00 00 	movl   $0x0,0xffffffd8(%ebp)
  10a59d:	e9 35 01 00 00       	jmp    10a6d7 <kbd_proc_data+0x197>
	} else if (data & 0x80) {
  10a5a2:	0f b6 45 ea          	movzbl 0xffffffea(%ebp),%eax
  10a5a6:	84 c0                	test   %al,%al
  10a5a8:	79 53                	jns    10a5fd <kbd_proc_data+0xbd>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
  10a5aa:	a1 28 1d 18 00       	mov    0x181d28,%eax
  10a5af:	83 e0 40             	and    $0x40,%eax
  10a5b2:	85 c0                	test   %eax,%eax
  10a5b4:	75 0c                	jne    10a5c2 <kbd_proc_data+0x82>
  10a5b6:	0f b6 45 ea          	movzbl 0xffffffea(%ebp),%eax
  10a5ba:	83 e0 7f             	and    $0x7f,%eax
  10a5bd:	88 45 df             	mov    %al,0xffffffdf(%ebp)
  10a5c0:	eb 07                	jmp    10a5c9 <kbd_proc_data+0x89>
  10a5c2:	0f b6 45 ea          	movzbl 0xffffffea(%ebp),%eax
  10a5c6:	88 45 df             	mov    %al,0xffffffdf(%ebp)
  10a5c9:	0f b6 45 df          	movzbl 0xffffffdf(%ebp),%eax
  10a5cd:	88 45 ea             	mov    %al,0xffffffea(%ebp)
		shift &= ~(shiftcode[data] | E0ESC);
  10a5d0:	0f b6 45 ea          	movzbl 0xffffffea(%ebp),%eax
  10a5d4:	0f b6 80 80 00 11 00 	movzbl 0x110080(%eax),%eax
  10a5db:	83 c8 40             	or     $0x40,%eax
  10a5de:	0f b6 c0             	movzbl %al,%eax
  10a5e1:	f7 d0                	not    %eax
  10a5e3:	89 c2                	mov    %eax,%edx
  10a5e5:	a1 28 1d 18 00       	mov    0x181d28,%eax
  10a5ea:	21 d0                	and    %edx,%eax
  10a5ec:	a3 28 1d 18 00       	mov    %eax,0x181d28
		return 0;
  10a5f1:	c7 45 d8 00 00 00 00 	movl   $0x0,0xffffffd8(%ebp)
  10a5f8:	e9 da 00 00 00       	jmp    10a6d7 <kbd_proc_data+0x197>
	} else if (shift & E0ESC) {
  10a5fd:	a1 28 1d 18 00       	mov    0x181d28,%eax
  10a602:	83 e0 40             	and    $0x40,%eax
  10a605:	85 c0                	test   %eax,%eax
  10a607:	74 11                	je     10a61a <kbd_proc_data+0xda>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
  10a609:	80 4d ea 80          	orb    $0x80,0xffffffea(%ebp)
		shift &= ~E0ESC;
  10a60d:	a1 28 1d 18 00       	mov    0x181d28,%eax
  10a612:	83 e0 bf             	and    $0xffffffbf,%eax
  10a615:	a3 28 1d 18 00       	mov    %eax,0x181d28
	}

	shift |= shiftcode[data];
  10a61a:	0f b6 45 ea          	movzbl 0xffffffea(%ebp),%eax
  10a61e:	0f b6 80 80 00 11 00 	movzbl 0x110080(%eax),%eax
  10a625:	0f b6 d0             	movzbl %al,%edx
  10a628:	a1 28 1d 18 00       	mov    0x181d28,%eax
  10a62d:	09 d0                	or     %edx,%eax
  10a62f:	a3 28 1d 18 00       	mov    %eax,0x181d28
	shift ^= togglecode[data];
  10a634:	0f b6 45 ea          	movzbl 0xffffffea(%ebp),%eax
  10a638:	0f b6 80 80 01 11 00 	movzbl 0x110180(%eax),%eax
  10a63f:	0f b6 d0             	movzbl %al,%edx
  10a642:	a1 28 1d 18 00       	mov    0x181d28,%eax
  10a647:	31 d0                	xor    %edx,%eax
  10a649:	a3 28 1d 18 00       	mov    %eax,0x181d28

	c = charcode[shift & (CTL | SHIFT)][data];
  10a64e:	a1 28 1d 18 00       	mov    0x181d28,%eax
  10a653:	83 e0 03             	and    $0x3,%eax
  10a656:	8b 14 85 80 05 11 00 	mov    0x110580(,%eax,4),%edx
  10a65d:	0f b6 45 ea          	movzbl 0xffffffea(%ebp),%eax
  10a661:	8d 04 02             	lea    (%edx,%eax,1),%eax
  10a664:	0f b6 00             	movzbl (%eax),%eax
  10a667:	0f b6 c0             	movzbl %al,%eax
  10a66a:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
	if (shift & CAPSLOCK) {
  10a66d:	a1 28 1d 18 00       	mov    0x181d28,%eax
  10a672:	83 e0 08             	and    $0x8,%eax
  10a675:	85 c0                	test   %eax,%eax
  10a677:	74 22                	je     10a69b <kbd_proc_data+0x15b>
		if ('a' <= c && c <= 'z')
  10a679:	83 7d e4 60          	cmpl   $0x60,0xffffffe4(%ebp)
  10a67d:	7e 0c                	jle    10a68b <kbd_proc_data+0x14b>
  10a67f:	83 7d e4 7a          	cmpl   $0x7a,0xffffffe4(%ebp)
  10a683:	7f 06                	jg     10a68b <kbd_proc_data+0x14b>
			c += 'A' - 'a';
  10a685:	83 6d e4 20          	subl   $0x20,0xffffffe4(%ebp)
  10a689:	eb 10                	jmp    10a69b <kbd_proc_data+0x15b>
		else if ('A' <= c && c <= 'Z')
  10a68b:	83 7d e4 40          	cmpl   $0x40,0xffffffe4(%ebp)
  10a68f:	7e 0a                	jle    10a69b <kbd_proc_data+0x15b>
  10a691:	83 7d e4 5a          	cmpl   $0x5a,0xffffffe4(%ebp)
  10a695:	7f 04                	jg     10a69b <kbd_proc_data+0x15b>
			c += 'a' - 'A';
  10a697:	83 45 e4 20          	addl   $0x20,0xffffffe4(%ebp)
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
  10a69b:	a1 28 1d 18 00       	mov    0x181d28,%eax
  10a6a0:	f7 d0                	not    %eax
  10a6a2:	83 e0 06             	and    $0x6,%eax
  10a6a5:	85 c0                	test   %eax,%eax
  10a6a7:	75 28                	jne    10a6d1 <kbd_proc_data+0x191>
  10a6a9:	81 7d e4 e9 00 00 00 	cmpl   $0xe9,0xffffffe4(%ebp)
  10a6b0:	75 1f                	jne    10a6d1 <kbd_proc_data+0x191>
		cprintf("Rebooting!\n");
  10a6b2:	c7 04 24 74 df 10 00 	movl   $0x10df74,(%esp)
  10a6b9:	e8 af 11 00 00       	call   10b86d <cprintf>
  10a6be:	c7 45 fc 92 00 00 00 	movl   $0x92,0xfffffffc(%ebp)
  10a6c5:	c6 45 fb 03          	movb   $0x3,0xfffffffb(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  10a6c9:	0f b6 45 fb          	movzbl 0xfffffffb(%ebp),%eax
  10a6cd:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  10a6d0:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
  10a6d1:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  10a6d4:	89 45 d8             	mov    %eax,0xffffffd8(%ebp)
  10a6d7:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
}
  10a6da:	c9                   	leave  
  10a6db:	c3                   	ret    

0010a6dc <kbd_intr>:

void
kbd_intr(void)
{
  10a6dc:	55                   	push   %ebp
  10a6dd:	89 e5                	mov    %esp,%ebp
  10a6df:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
  10a6e2:	c7 04 24 40 a5 10 00 	movl   $0x10a540,(%esp)
  10a6e9:	e8 5e 5e ff ff       	call   10054c <cons_intr>
}
  10a6ee:	c9                   	leave  
  10a6ef:	c3                   	ret    

0010a6f0 <kbd_init>:

void
kbd_init(void)
{
  10a6f0:	55                   	push   %ebp
  10a6f1:	89 e5                	mov    %esp,%ebp
}
  10a6f3:	5d                   	pop    %ebp
  10a6f4:	c3                   	ret    

0010a6f5 <kbd_intenable>:

void
kbd_intenable(void)
{
  10a6f5:	55                   	push   %ebp
  10a6f6:	89 e5                	mov    %esp,%ebp
  10a6f8:	83 ec 08             	sub    $0x8,%esp
	// Enable interrupt delivery via the PIC/APIC
	pic_enable(IRQ_KBD);
  10a6fb:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  10a702:	e8 a4 03 00 00       	call   10aaab <pic_enable>
	ioapic_enable(IRQ_KBD);
  10a707:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  10a70e:	e8 38 09 00 00       	call   10b04b <ioapic_enable>

	// Drain the kbd buffer so that the hardware generates interrupts.
	kbd_intr();
  10a713:	e8 c4 ff ff ff       	call   10a6dc <kbd_intr>
}
  10a718:	c9                   	leave  
  10a719:	c3                   	ret    
  10a71a:	90                   	nop    
  10a71b:	90                   	nop    

0010a71c <delay>:

// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
  10a71c:	55                   	push   %ebp
  10a71d:	89 e5                	mov    %esp,%ebp
  10a71f:	83 ec 20             	sub    $0x20,%esp
  10a722:	c7 45 e4 84 00 00 00 	movl   $0x84,0xffffffe4(%ebp)
static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  10a729:	8b 55 e4             	mov    0xffffffe4(%ebp),%edx
  10a72c:	ec                   	in     (%dx),%al
  10a72d:	88 45 e3             	mov    %al,0xffffffe3(%ebp)
	return data;
  10a730:	c7 45 ec 84 00 00 00 	movl   $0x84,0xffffffec(%ebp)
  10a737:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
  10a73a:	ec                   	in     (%dx),%al
  10a73b:	88 45 eb             	mov    %al,0xffffffeb(%ebp)
  10a73e:	c7 45 f4 84 00 00 00 	movl   $0x84,0xfffffff4(%ebp)
  10a745:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  10a748:	ec                   	in     (%dx),%al
  10a749:	88 45 f3             	mov    %al,0xfffffff3(%ebp)
  10a74c:	c7 45 fc 84 00 00 00 	movl   $0x84,0xfffffffc(%ebp)
  10a753:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  10a756:	ec                   	in     (%dx),%al
  10a757:	88 45 fb             	mov    %al,0xfffffffb(%ebp)
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
  10a75a:	c9                   	leave  
  10a75b:	c3                   	ret    

0010a75c <serial_proc_data>:

static int
serial_proc_data(void)
{
  10a75c:	55                   	push   %ebp
  10a75d:	89 e5                	mov    %esp,%ebp
  10a75f:	83 ec 14             	sub    $0x14,%esp
  10a762:	c7 45 f4 fd 03 00 00 	movl   $0x3fd,0xfffffff4(%ebp)
static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  10a769:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  10a76c:	ec                   	in     (%dx),%al
  10a76d:	88 45 f3             	mov    %al,0xfffffff3(%ebp)
	return data;
  10a770:	0f b6 45 f3          	movzbl 0xfffffff3(%ebp),%eax
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
  10a774:	0f b6 c0             	movzbl %al,%eax
  10a777:	83 e0 01             	and    $0x1,%eax
  10a77a:	85 c0                	test   %eax,%eax
  10a77c:	75 09                	jne    10a787 <serial_proc_data+0x2b>
		return -1;
  10a77e:	c7 45 ec ff ff ff ff 	movl   $0xffffffff,0xffffffec(%ebp)
  10a785:	eb 18                	jmp    10a79f <serial_proc_data+0x43>
  10a787:	c7 45 fc f8 03 00 00 	movl   $0x3f8,0xfffffffc(%ebp)
static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  10a78e:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  10a791:	ec                   	in     (%dx),%al
  10a792:	88 45 fb             	mov    %al,0xfffffffb(%ebp)
	return data;
  10a795:	0f b6 45 fb          	movzbl 0xfffffffb(%ebp),%eax
	return inb(COM1+COM_RX);
  10a799:	0f b6 c0             	movzbl %al,%eax
  10a79c:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  10a79f:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
}
  10a7a2:	c9                   	leave  
  10a7a3:	c3                   	ret    

0010a7a4 <serial_intr>:

void
serial_intr(void)
{
  10a7a4:	55                   	push   %ebp
  10a7a5:	89 e5                	mov    %esp,%ebp
  10a7a7:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
  10a7aa:	a1 00 50 18 00       	mov    0x185000,%eax
  10a7af:	85 c0                	test   %eax,%eax
  10a7b1:	74 0c                	je     10a7bf <serial_intr+0x1b>
		cons_intr(serial_proc_data);
  10a7b3:	c7 04 24 5c a7 10 00 	movl   $0x10a75c,(%esp)
  10a7ba:	e8 8d 5d ff ff       	call   10054c <cons_intr>
}
  10a7bf:	c9                   	leave  
  10a7c0:	c3                   	ret    

0010a7c1 <serial_putc>:

void
serial_putc(int c)
{
  10a7c1:	55                   	push   %ebp
  10a7c2:	89 e5                	mov    %esp,%ebp
  10a7c4:	83 ec 20             	sub    $0x20,%esp
	if (!serial_exists)
  10a7c7:	a1 00 50 18 00       	mov    0x185000,%eax
  10a7cc:	85 c0                	test   %eax,%eax
  10a7ce:	74 4f                	je     10a81f <serial_putc+0x5e>
		return;

	int i;
	for (i = 0;
  10a7d0:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
  10a7d7:	eb 09                	jmp    10a7e2 <serial_putc+0x21>
	     i++)
		delay();
  10a7d9:	e8 3e ff ff ff       	call   10a71c <delay>
  10a7de:	83 45 ec 01          	addl   $0x1,0xffffffec(%ebp)
  10a7e2:	c7 45 f4 fd 03 00 00 	movl   $0x3fd,0xfffffff4(%ebp)
static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  10a7e9:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  10a7ec:	ec                   	in     (%dx),%al
  10a7ed:	88 45 f3             	mov    %al,0xfffffff3(%ebp)
	return data;
  10a7f0:	0f b6 45 f3          	movzbl 0xfffffff3(%ebp),%eax
  10a7f4:	0f b6 c0             	movzbl %al,%eax
  10a7f7:	83 e0 20             	and    $0x20,%eax
  10a7fa:	85 c0                	test   %eax,%eax
  10a7fc:	75 09                	jne    10a807 <serial_putc+0x46>
  10a7fe:	81 7d ec ff 31 00 00 	cmpl   $0x31ff,0xffffffec(%ebp)
  10a805:	7e d2                	jle    10a7d9 <serial_putc+0x18>
	
	outb(COM1 + COM_TX, c);
  10a807:	8b 45 08             	mov    0x8(%ebp),%eax
  10a80a:	0f b6 c0             	movzbl %al,%eax
  10a80d:	c7 45 fc f8 03 00 00 	movl   $0x3f8,0xfffffffc(%ebp)
  10a814:	88 45 fb             	mov    %al,0xfffffffb(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  10a817:	0f b6 45 fb          	movzbl 0xfffffffb(%ebp),%eax
  10a81b:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  10a81e:	ee                   	out    %al,(%dx)
}
  10a81f:	c9                   	leave  
  10a820:	c3                   	ret    

0010a821 <serial_init>:

void
serial_init(void)
{
  10a821:	55                   	push   %ebp
  10a822:	89 e5                	mov    %esp,%ebp
  10a824:	83 ec 50             	sub    $0x50,%esp
  10a827:	c7 45 b4 fa 03 00 00 	movl   $0x3fa,0xffffffb4(%ebp)
  10a82e:	c6 45 b3 00          	movb   $0x0,0xffffffb3(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  10a832:	0f b6 45 b3          	movzbl 0xffffffb3(%ebp),%eax
  10a836:	8b 55 b4             	mov    0xffffffb4(%ebp),%edx
  10a839:	ee                   	out    %al,(%dx)
  10a83a:	c7 45 bc fb 03 00 00 	movl   $0x3fb,0xffffffbc(%ebp)
  10a841:	c6 45 bb 80          	movb   $0x80,0xffffffbb(%ebp)
  10a845:	0f b6 45 bb          	movzbl 0xffffffbb(%ebp),%eax
  10a849:	8b 55 bc             	mov    0xffffffbc(%ebp),%edx
  10a84c:	ee                   	out    %al,(%dx)
  10a84d:	c7 45 c4 f8 03 00 00 	movl   $0x3f8,0xffffffc4(%ebp)
  10a854:	c6 45 c3 0c          	movb   $0xc,0xffffffc3(%ebp)
  10a858:	0f b6 45 c3          	movzbl 0xffffffc3(%ebp),%eax
  10a85c:	8b 55 c4             	mov    0xffffffc4(%ebp),%edx
  10a85f:	ee                   	out    %al,(%dx)
  10a860:	c7 45 cc f9 03 00 00 	movl   $0x3f9,0xffffffcc(%ebp)
  10a867:	c6 45 cb 00          	movb   $0x0,0xffffffcb(%ebp)
  10a86b:	0f b6 45 cb          	movzbl 0xffffffcb(%ebp),%eax
  10a86f:	8b 55 cc             	mov    0xffffffcc(%ebp),%edx
  10a872:	ee                   	out    %al,(%dx)
  10a873:	c7 45 d4 fb 03 00 00 	movl   $0x3fb,0xffffffd4(%ebp)
  10a87a:	c6 45 d3 03          	movb   $0x3,0xffffffd3(%ebp)
  10a87e:	0f b6 45 d3          	movzbl 0xffffffd3(%ebp),%eax
  10a882:	8b 55 d4             	mov    0xffffffd4(%ebp),%edx
  10a885:	ee                   	out    %al,(%dx)
  10a886:	c7 45 dc fc 03 00 00 	movl   $0x3fc,0xffffffdc(%ebp)
  10a88d:	c6 45 db 00          	movb   $0x0,0xffffffdb(%ebp)
  10a891:	0f b6 45 db          	movzbl 0xffffffdb(%ebp),%eax
  10a895:	8b 55 dc             	mov    0xffffffdc(%ebp),%edx
  10a898:	ee                   	out    %al,(%dx)
  10a899:	c7 45 e4 f9 03 00 00 	movl   $0x3f9,0xffffffe4(%ebp)
  10a8a0:	c6 45 e3 01          	movb   $0x1,0xffffffe3(%ebp)
  10a8a4:	0f b6 45 e3          	movzbl 0xffffffe3(%ebp),%eax
  10a8a8:	8b 55 e4             	mov    0xffffffe4(%ebp),%edx
  10a8ab:	ee                   	out    %al,(%dx)
  10a8ac:	c7 45 ec fd 03 00 00 	movl   $0x3fd,0xffffffec(%ebp)
  10a8b3:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
  10a8b6:	ec                   	in     (%dx),%al
  10a8b7:	88 45 eb             	mov    %al,0xffffffeb(%ebp)
  10a8ba:	0f b6 45 eb          	movzbl 0xffffffeb(%ebp),%eax
	// Turn off the FIFO
	outb(COM1+COM_FCR, 0);
	
	// Set speed; requires DLAB latch
	outb(COM1+COM_LCR, COM_LCR_DLAB);
	outb(COM1+COM_DLL, (uint8_t) (115200 / 9600));
	outb(COM1+COM_DLM, 0);

	// 8 data bits, 1 stop bit, parity off; turn off DLAB latch
	outb(COM1+COM_LCR, COM_LCR_WLEN8 & ~COM_LCR_DLAB);

	// No modem controls
	outb(COM1+COM_MCR, 0);
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
  10a8be:	3c ff                	cmp    $0xff,%al
  10a8c0:	0f 95 c0             	setne  %al
  10a8c3:	0f b6 c0             	movzbl %al,%eax
  10a8c6:	a3 00 50 18 00       	mov    %eax,0x185000
  10a8cb:	c7 45 f4 fa 03 00 00 	movl   $0x3fa,0xfffffff4(%ebp)
static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  10a8d2:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  10a8d5:	ec                   	in     (%dx),%al
  10a8d6:	88 45 f3             	mov    %al,0xfffffff3(%ebp)
	return data;
  10a8d9:	c7 45 fc f8 03 00 00 	movl   $0x3f8,0xfffffffc(%ebp)
  10a8e0:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  10a8e3:	ec                   	in     (%dx),%al
  10a8e4:	88 45 fb             	mov    %al,0xfffffffb(%ebp)
	(void) inb(COM1+COM_IIR);
	(void) inb(COM1+COM_RX);
}
  10a8e7:	c9                   	leave  
  10a8e8:	c3                   	ret    

0010a8e9 <serial_intenable>:

void
serial_intenable(void)
{
  10a8e9:	55                   	push   %ebp
  10a8ea:	89 e5                	mov    %esp,%ebp
  10a8ec:	83 ec 08             	sub    $0x8,%esp
	// Enable serial interrupts
	if (serial_exists) {
  10a8ef:	a1 00 50 18 00       	mov    0x185000,%eax
  10a8f4:	85 c0                	test   %eax,%eax
  10a8f6:	74 18                	je     10a910 <serial_intenable+0x27>
		pic_enable(IRQ_SERIAL);
  10a8f8:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
  10a8ff:	e8 a7 01 00 00       	call   10aaab <pic_enable>
		ioapic_enable(IRQ_SERIAL);
  10a904:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
  10a90b:	e8 3b 07 00 00       	call   10b04b <ioapic_enable>
	}
}
  10a910:	c9                   	leave  
  10a911:	c3                   	ret    
  10a912:	90                   	nop    
  10a913:	90                   	nop    

0010a914 <pic_init>:

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
  10a914:	55                   	push   %ebp
  10a915:	89 e5                	mov    %esp,%ebp
  10a917:	83 ec 78             	sub    $0x78,%esp
	if (didinit)		// only do once on bootstrap CPU
  10a91a:	a1 2c 1d 18 00       	mov    0x181d2c,%eax
  10a91f:	85 c0                	test   %eax,%eax
  10a921:	0f 85 33 01 00 00    	jne    10aa5a <pic_init+0x146>
		return;
	didinit = 1;
  10a927:	c7 05 2c 1d 18 00 01 	movl   $0x1,0x181d2c
  10a92e:	00 00 00 
  10a931:	c7 45 94 21 00 00 00 	movl   $0x21,0xffffff94(%ebp)
  10a938:	c6 45 93 ff          	movb   $0xff,0xffffff93(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  10a93c:	0f b6 45 93          	movzbl 0xffffff93(%ebp),%eax
  10a940:	8b 55 94             	mov    0xffffff94(%ebp),%edx
  10a943:	ee                   	out    %al,(%dx)
  10a944:	c7 45 9c a1 00 00 00 	movl   $0xa1,0xffffff9c(%ebp)
  10a94b:	c6 45 9b ff          	movb   $0xff,0xffffff9b(%ebp)
  10a94f:	0f b6 45 9b          	movzbl 0xffffff9b(%ebp),%eax
  10a953:	8b 55 9c             	mov    0xffffff9c(%ebp),%edx
  10a956:	ee                   	out    %al,(%dx)
  10a957:	c7 45 a4 20 00 00 00 	movl   $0x20,0xffffffa4(%ebp)
  10a95e:	c6 45 a3 11          	movb   $0x11,0xffffffa3(%ebp)
  10a962:	0f b6 45 a3          	movzbl 0xffffffa3(%ebp),%eax
  10a966:	8b 55 a4             	mov    0xffffffa4(%ebp),%edx
  10a969:	ee                   	out    %al,(%dx)
  10a96a:	c7 45 ac 21 00 00 00 	movl   $0x21,0xffffffac(%ebp)
  10a971:	c6 45 ab 20          	movb   $0x20,0xffffffab(%ebp)
  10a975:	0f b6 45 ab          	movzbl 0xffffffab(%ebp),%eax
  10a979:	8b 55 ac             	mov    0xffffffac(%ebp),%edx
  10a97c:	ee                   	out    %al,(%dx)
  10a97d:	c7 45 b4 21 00 00 00 	movl   $0x21,0xffffffb4(%ebp)
  10a984:	c6 45 b3 04          	movb   $0x4,0xffffffb3(%ebp)
  10a988:	0f b6 45 b3          	movzbl 0xffffffb3(%ebp),%eax
  10a98c:	8b 55 b4             	mov    0xffffffb4(%ebp),%edx
  10a98f:	ee                   	out    %al,(%dx)
  10a990:	c7 45 bc 21 00 00 00 	movl   $0x21,0xffffffbc(%ebp)
  10a997:	c6 45 bb 03          	movb   $0x3,0xffffffbb(%ebp)
  10a99b:	0f b6 45 bb          	movzbl 0xffffffbb(%ebp),%eax
  10a99f:	8b 55 bc             	mov    0xffffffbc(%ebp),%edx
  10a9a2:	ee                   	out    %al,(%dx)
  10a9a3:	c7 45 c4 a0 00 00 00 	movl   $0xa0,0xffffffc4(%ebp)
  10a9aa:	c6 45 c3 11          	movb   $0x11,0xffffffc3(%ebp)
  10a9ae:	0f b6 45 c3          	movzbl 0xffffffc3(%ebp),%eax
  10a9b2:	8b 55 c4             	mov    0xffffffc4(%ebp),%edx
  10a9b5:	ee                   	out    %al,(%dx)
  10a9b6:	c7 45 cc a1 00 00 00 	movl   $0xa1,0xffffffcc(%ebp)
  10a9bd:	c6 45 cb 28          	movb   $0x28,0xffffffcb(%ebp)
  10a9c1:	0f b6 45 cb          	movzbl 0xffffffcb(%ebp),%eax
  10a9c5:	8b 55 cc             	mov    0xffffffcc(%ebp),%edx
  10a9c8:	ee                   	out    %al,(%dx)
  10a9c9:	c7 45 d4 a1 00 00 00 	movl   $0xa1,0xffffffd4(%ebp)
  10a9d0:	c6 45 d3 02          	movb   $0x2,0xffffffd3(%ebp)
  10a9d4:	0f b6 45 d3          	movzbl 0xffffffd3(%ebp),%eax
  10a9d8:	8b 55 d4             	mov    0xffffffd4(%ebp),%edx
  10a9db:	ee                   	out    %al,(%dx)
  10a9dc:	c7 45 dc a1 00 00 00 	movl   $0xa1,0xffffffdc(%ebp)
  10a9e3:	c6 45 db 01          	movb   $0x1,0xffffffdb(%ebp)
  10a9e7:	0f b6 45 db          	movzbl 0xffffffdb(%ebp),%eax
  10a9eb:	8b 55 dc             	mov    0xffffffdc(%ebp),%edx
  10a9ee:	ee                   	out    %al,(%dx)
  10a9ef:	c7 45 e4 20 00 00 00 	movl   $0x20,0xffffffe4(%ebp)
  10a9f6:	c6 45 e3 68          	movb   $0x68,0xffffffe3(%ebp)
  10a9fa:	0f b6 45 e3          	movzbl 0xffffffe3(%ebp),%eax
  10a9fe:	8b 55 e4             	mov    0xffffffe4(%ebp),%edx
  10aa01:	ee                   	out    %al,(%dx)
  10aa02:	c7 45 ec 20 00 00 00 	movl   $0x20,0xffffffec(%ebp)
  10aa09:	c6 45 eb 0a          	movb   $0xa,0xffffffeb(%ebp)
  10aa0d:	0f b6 45 eb          	movzbl 0xffffffeb(%ebp),%eax
  10aa11:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
  10aa14:	ee                   	out    %al,(%dx)
  10aa15:	c7 45 f4 a0 00 00 00 	movl   $0xa0,0xfffffff4(%ebp)
  10aa1c:	c6 45 f3 68          	movb   $0x68,0xfffffff3(%ebp)
  10aa20:	0f b6 45 f3          	movzbl 0xfffffff3(%ebp),%eax
  10aa24:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  10aa27:	ee                   	out    %al,(%dx)
  10aa28:	c7 45 fc a0 00 00 00 	movl   $0xa0,0xfffffffc(%ebp)
  10aa2f:	c6 45 fb 0a          	movb   $0xa,0xfffffffb(%ebp)
  10aa33:	0f b6 45 fb          	movzbl 0xfffffffb(%ebp),%eax
  10aa37:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  10aa3a:	ee                   	out    %al,(%dx)

	// mask all interrupts
	outb(IO_PIC1+1, 0xFF);
	outb(IO_PIC2+1, 0xFF);

	// Set up master (8259A-1)

	// ICW1:  0001g0hi
	//    g:  0 = edge triggering, 1 = level triggering
	//    h:  0 = cascaded PICs, 1 = master only
	//    i:  0 = no ICW4, 1 = ICW4 required
	outb(IO_PIC1, 0x11);

	// ICW2:  Vector offset
	outb(IO_PIC1+1, T_IRQ0);

	// ICW3:  bit mask of IR lines connected to slave PICs (master PIC),
	//        3-bit No of IR line at which slave connects to master(slave PIC).
	outb(IO_PIC1+1, 1<<IRQ_SLAVE);

	// ICW4:  000nbmap
	//    n:  1 = special fully nested mode
	//    b:  1 = buffered mode
	//    m:  0 = slave PIC, 1 = master PIC
	//	  (ignored when b is 0, as the master/slave role
	//	  can be hardwired).
	//    a:  1 = Automatic EOI mode
	//    p:  0 = MCS-80/85 mode, 1 = intel x86 mode
	outb(IO_PIC1+1, 0x3);

	// Set up slave (8259A-2)
	outb(IO_PIC2, 0x11);			// ICW1
	outb(IO_PIC2+1, T_IRQ0 + 8);		// ICW2
	outb(IO_PIC2+1, IRQ_SLAVE);		// ICW3
	// NB Automatic EOI mode doesn't tend to work on the slave.
	// Linux source code says it's "to be investigated".
	outb(IO_PIC2+1, 0x01);			// ICW4

	// OCW3:  0ef01prs
	//   ef:  0x = NOP, 10 = clear specific mask, 11 = set specific mask
	//    p:  0 = no polling, 1 = polling mode
	//   rs:  0x = NOP, 10 = read IRR, 11 = read ISR
	outb(IO_PIC1, 0x68);             /* clear specific mask */
	outb(IO_PIC1, 0x0a);             /* read IRR by default */

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irqmask != 0xFFFF)
  10aa3b:	0f b7 05 90 05 11 00 	movzwl 0x110590,%eax
  10aa42:	66 83 f8 ff          	cmp    $0xffffffff,%ax
  10aa46:	74 12                	je     10aa5a <pic_init+0x146>
		pic_setmask(irqmask);
  10aa48:	0f b7 05 90 05 11 00 	movzwl 0x110590,%eax
  10aa4f:	0f b7 c0             	movzwl %ax,%eax
  10aa52:	89 04 24             	mov    %eax,(%esp)
  10aa55:	e8 02 00 00 00       	call   10aa5c <pic_setmask>
}
  10aa5a:	c9                   	leave  
  10aa5b:	c3                   	ret    

0010aa5c <pic_setmask>:

void
pic_setmask(uint16_t mask)
{
  10aa5c:	55                   	push   %ebp
  10aa5d:	89 e5                	mov    %esp,%ebp
  10aa5f:	83 ec 14             	sub    $0x14,%esp
  10aa62:	8b 45 08             	mov    0x8(%ebp),%eax
  10aa65:	66 89 45 ec          	mov    %ax,0xffffffec(%ebp)
	irqmask = mask;
  10aa69:	0f b7 45 ec          	movzwl 0xffffffec(%ebp),%eax
  10aa6d:	66 a3 90 05 11 00    	mov    %ax,0x110590
	outb(IO_PIC1+1, (char)mask);
  10aa73:	0f b7 45 ec          	movzwl 0xffffffec(%ebp),%eax
  10aa77:	0f b6 c0             	movzbl %al,%eax
  10aa7a:	c7 45 f4 21 00 00 00 	movl   $0x21,0xfffffff4(%ebp)
  10aa81:	88 45 f3             	mov    %al,0xfffffff3(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  10aa84:	0f b6 45 f3          	movzbl 0xfffffff3(%ebp),%eax
  10aa88:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  10aa8b:	ee                   	out    %al,(%dx)
	outb(IO_PIC2+1, (char)(mask >> 8));
  10aa8c:	0f b7 45 ec          	movzwl 0xffffffec(%ebp),%eax
  10aa90:	66 c1 e8 08          	shr    $0x8,%ax
  10aa94:	0f b6 c0             	movzbl %al,%eax
  10aa97:	c7 45 fc a1 00 00 00 	movl   $0xa1,0xfffffffc(%ebp)
  10aa9e:	88 45 fb             	mov    %al,0xfffffffb(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  10aaa1:	0f b6 45 fb          	movzbl 0xfffffffb(%ebp),%eax
  10aaa5:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  10aaa8:	ee                   	out    %al,(%dx)
}
  10aaa9:	c9                   	leave  
  10aaaa:	c3                   	ret    

0010aaab <pic_enable>:

void
pic_enable(int irq)
{
  10aaab:	55                   	push   %ebp
  10aaac:	89 e5                	mov    %esp,%ebp
  10aaae:	83 ec 04             	sub    $0x4,%esp
	pic_setmask(irqmask & ~(1 << irq));
  10aab1:	8b 4d 08             	mov    0x8(%ebp),%ecx
  10aab4:	b8 01 00 00 00       	mov    $0x1,%eax
  10aab9:	d3 e0                	shl    %cl,%eax
  10aabb:	89 c2                	mov    %eax,%edx
  10aabd:	f7 d2                	not    %edx
  10aabf:	0f b7 05 90 05 11 00 	movzwl 0x110590,%eax
  10aac6:	21 d0                	and    %edx,%eax
  10aac8:	0f b7 c0             	movzwl %ax,%eax
  10aacb:	89 04 24             	mov    %eax,(%esp)
  10aace:	e8 89 ff ff ff       	call   10aa5c <pic_setmask>
}
  10aad3:	c9                   	leave  
  10aad4:	c3                   	ret    
  10aad5:	90                   	nop    
  10aad6:	90                   	nop    
  10aad7:	90                   	nop    

0010aad8 <nvram_read>:


unsigned
nvram_read(unsigned reg)
{
  10aad8:	55                   	push   %ebp
  10aad9:	89 e5                	mov    %esp,%ebp
  10aadb:	83 ec 10             	sub    $0x10,%esp
	outb(IO_RTC, reg);
  10aade:	8b 45 08             	mov    0x8(%ebp),%eax
  10aae1:	0f b6 c0             	movzbl %al,%eax
  10aae4:	c7 45 f4 70 00 00 00 	movl   $0x70,0xfffffff4(%ebp)
  10aaeb:	88 45 f3             	mov    %al,0xfffffff3(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  10aaee:	0f b6 45 f3          	movzbl 0xfffffff3(%ebp),%eax
  10aaf2:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  10aaf5:	ee                   	out    %al,(%dx)
  10aaf6:	c7 45 fc 71 00 00 00 	movl   $0x71,0xfffffffc(%ebp)
  10aafd:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  10ab00:	ec                   	in     (%dx),%al
  10ab01:	88 45 fb             	mov    %al,0xfffffffb(%ebp)
  10ab04:	0f b6 45 fb          	movzbl 0xfffffffb(%ebp),%eax
	return inb(IO_RTC+1);
  10ab08:	0f b6 c0             	movzbl %al,%eax
}
  10ab0b:	c9                   	leave  
  10ab0c:	c3                   	ret    

0010ab0d <nvram_read16>:

unsigned
nvram_read16(unsigned r)
{
  10ab0d:	55                   	push   %ebp
  10ab0e:	89 e5                	mov    %esp,%ebp
  10ab10:	53                   	push   %ebx
  10ab11:	83 ec 04             	sub    $0x4,%esp
	return nvram_read(r) | (nvram_read(r + 1) << 8);
  10ab14:	8b 45 08             	mov    0x8(%ebp),%eax
  10ab17:	89 04 24             	mov    %eax,(%esp)
  10ab1a:	e8 b9 ff ff ff       	call   10aad8 <nvram_read>
  10ab1f:	89 c3                	mov    %eax,%ebx
  10ab21:	8b 45 08             	mov    0x8(%ebp),%eax
  10ab24:	83 c0 01             	add    $0x1,%eax
  10ab27:	89 04 24             	mov    %eax,(%esp)
  10ab2a:	e8 a9 ff ff ff       	call   10aad8 <nvram_read>
  10ab2f:	c1 e0 08             	shl    $0x8,%eax
  10ab32:	09 d8                	or     %ebx,%eax
}
  10ab34:	83 c4 04             	add    $0x4,%esp
  10ab37:	5b                   	pop    %ebx
  10ab38:	5d                   	pop    %ebp
  10ab39:	c3                   	ret    

0010ab3a <nvram_write>:

void
nvram_write(unsigned reg, unsigned datum)
{
  10ab3a:	55                   	push   %ebp
  10ab3b:	89 e5                	mov    %esp,%ebp
  10ab3d:	83 ec 10             	sub    $0x10,%esp
	outb(IO_RTC, reg);
  10ab40:	8b 45 08             	mov    0x8(%ebp),%eax
  10ab43:	0f b6 c0             	movzbl %al,%eax
  10ab46:	c7 45 f4 70 00 00 00 	movl   $0x70,0xfffffff4(%ebp)
  10ab4d:	88 45 f3             	mov    %al,0xfffffff3(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  10ab50:	0f b6 45 f3          	movzbl 0xfffffff3(%ebp),%eax
  10ab54:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  10ab57:	ee                   	out    %al,(%dx)
	outb(IO_RTC+1, datum);
  10ab58:	8b 45 0c             	mov    0xc(%ebp),%eax
  10ab5b:	0f b6 c0             	movzbl %al,%eax
  10ab5e:	c7 45 fc 71 00 00 00 	movl   $0x71,0xfffffffc(%ebp)
  10ab65:	88 45 fb             	mov    %al,0xfffffffb(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  10ab68:	0f b6 45 fb          	movzbl 0xfffffffb(%ebp),%eax
  10ab6c:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  10ab6f:	ee                   	out    %al,(%dx)
}
  10ab70:	c9                   	leave  
  10ab71:	c3                   	ret    
  10ab72:	90                   	nop    
  10ab73:	90                   	nop    

0010ab74 <lapicw>:


static void
lapicw(int index, int value)
{
  10ab74:	55                   	push   %ebp
  10ab75:	89 e5                	mov    %esp,%ebp
	lapic[index] = value;
  10ab77:	8b 45 08             	mov    0x8(%ebp),%eax
  10ab7a:	c1 e0 02             	shl    $0x2,%eax
  10ab7d:	89 c2                	mov    %eax,%edx
  10ab7f:	a1 04 50 18 00       	mov    0x185004,%eax
  10ab84:	01 c2                	add    %eax,%edx
  10ab86:	8b 45 0c             	mov    0xc(%ebp),%eax
  10ab89:	89 02                	mov    %eax,(%edx)
	lapic[ID];  // wait for write to finish, by reading
  10ab8b:	a1 04 50 18 00       	mov    0x185004,%eax
  10ab90:	83 c0 20             	add    $0x20,%eax
  10ab93:	8b 00                	mov    (%eax),%eax
}
  10ab95:	5d                   	pop    %ebp
  10ab96:	c3                   	ret    

0010ab97 <lapic_init>:

void
lapic_init()
{
  10ab97:	55                   	push   %ebp
  10ab98:	89 e5                	mov    %esp,%ebp
  10ab9a:	83 ec 08             	sub    $0x8,%esp
	if (!lapic) 
  10ab9d:	a1 04 50 18 00       	mov    0x185004,%eax
  10aba2:	85 c0                	test   %eax,%eax
  10aba4:	0f 84 80 01 00 00    	je     10ad2a <lapic_init+0x193>
		return;

	// Enable local APIC; set spurious interrupt vector.
	lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
  10abaa:	c7 44 24 04 27 01 00 	movl   $0x127,0x4(%esp)
  10abb1:	00 
  10abb2:	c7 04 24 3c 00 00 00 	movl   $0x3c,(%esp)
  10abb9:	e8 b6 ff ff ff       	call   10ab74 <lapicw>

	// The timer repeatedly counts down at bus frequency
	// from lapic[TICR] and then issues an interrupt.  
	lapicw(TDCR, X1);
  10abbe:	c7 44 24 04 0b 00 00 	movl   $0xb,0x4(%esp)
  10abc5:	00 
  10abc6:	c7 04 24 f8 00 00 00 	movl   $0xf8,(%esp)
  10abcd:	e8 a2 ff ff ff       	call   10ab74 <lapicw>
	lapicw(TIMER, PERIODIC | T_LTIMER);
  10abd2:	c7 44 24 04 31 00 02 	movl   $0x20031,0x4(%esp)
  10abd9:	00 
  10abda:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
  10abe1:	e8 8e ff ff ff       	call   10ab74 <lapicw>

	// If we cared more about precise timekeeping,
	// we would calibrate TICR with another time source such as the PIT.
	lapicw(TICR, 10000000);
  10abe6:	c7 44 24 04 80 96 98 	movl   $0x989680,0x4(%esp)
  10abed:	00 
  10abee:	c7 04 24 e0 00 00 00 	movl   $0xe0,(%esp)
  10abf5:	e8 7a ff ff ff       	call   10ab74 <lapicw>

	// Disable logical interrupt lines.
	lapicw(LINT0, MASKED);
  10abfa:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
  10ac01:	00 
  10ac02:	c7 04 24 d4 00 00 00 	movl   $0xd4,(%esp)
  10ac09:	e8 66 ff ff ff       	call   10ab74 <lapicw>
	lapicw(LINT1, MASKED);
  10ac0e:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
  10ac15:	00 
  10ac16:	c7 04 24 d8 00 00 00 	movl   $0xd8,(%esp)
  10ac1d:	e8 52 ff ff ff       	call   10ab74 <lapicw>

	// Disable performance counter overflow interrupts
	// on machines that provide that interrupt entry.
	if (((lapic[VER]>>16) & 0xFF) >= 4)
  10ac22:	a1 04 50 18 00       	mov    0x185004,%eax
  10ac27:	83 c0 30             	add    $0x30,%eax
  10ac2a:	8b 00                	mov    (%eax),%eax
  10ac2c:	c1 e8 10             	shr    $0x10,%eax
  10ac2f:	25 ff 00 00 00       	and    $0xff,%eax
  10ac34:	83 f8 03             	cmp    $0x3,%eax
  10ac37:	76 14                	jbe    10ac4d <lapic_init+0xb6>
		lapicw(PCINT, MASKED);
  10ac39:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
  10ac40:	00 
  10ac41:	c7 04 24 d0 00 00 00 	movl   $0xd0,(%esp)
  10ac48:	e8 27 ff ff ff       	call   10ab74 <lapicw>

	// Map other interrupts to appropriate vectors.
	lapicw(ERROR, T_LERROR);
  10ac4d:	c7 44 24 04 32 00 00 	movl   $0x32,0x4(%esp)
  10ac54:	00 
  10ac55:	c7 04 24 dc 00 00 00 	movl   $0xdc,(%esp)
  10ac5c:	e8 13 ff ff ff       	call   10ab74 <lapicw>

	// Set up to lowest-priority, "anycast" interrupts
	lapicw(LDR, 0xff << 24);	// Accept all interrupts
  10ac61:	c7 44 24 04 00 00 00 	movl   $0xff000000,0x4(%esp)
  10ac68:	ff 
  10ac69:	c7 04 24 34 00 00 00 	movl   $0x34,(%esp)
  10ac70:	e8 ff fe ff ff       	call   10ab74 <lapicw>
	lapicw(DFR, 0xf << 28);		// Flat model
  10ac75:	c7 44 24 04 00 00 00 	movl   $0xf0000000,0x4(%esp)
  10ac7c:	f0 
  10ac7d:	c7 04 24 38 00 00 00 	movl   $0x38,(%esp)
  10ac84:	e8 eb fe ff ff       	call   10ab74 <lapicw>
	lapicw(TPR, 0x00);		// Task priority 0, no intrs masked
  10ac89:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  10ac90:	00 
  10ac91:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  10ac98:	e8 d7 fe ff ff       	call   10ab74 <lapicw>

	// Clear error status register (requires back-to-back writes).
	lapicw(ESR, 0);
  10ac9d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  10aca4:	00 
  10aca5:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
  10acac:	e8 c3 fe ff ff       	call   10ab74 <lapicw>
	lapicw(ESR, 0);
  10acb1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  10acb8:	00 
  10acb9:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
  10acc0:	e8 af fe ff ff       	call   10ab74 <lapicw>

	// Ack any outstanding interrupts.
	lapicw(EOI, 0);
  10acc5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  10accc:	00 
  10accd:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
  10acd4:	e8 9b fe ff ff       	call   10ab74 <lapicw>

	// Send an Init Level De-Assert to synchronise arbitration ID's.
	lapicw(ICRHI, 0);
  10acd9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  10ace0:	00 
  10ace1:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
  10ace8:	e8 87 fe ff ff       	call   10ab74 <lapicw>
	lapicw(ICRLO, BCAST | INIT | LEVEL);
  10aced:	c7 44 24 04 00 85 08 	movl   $0x88500,0x4(%esp)
  10acf4:	00 
  10acf5:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
  10acfc:	e8 73 fe ff ff       	call   10ab74 <lapicw>
	while(lapic[ICRLO] & DELIVS)
  10ad01:	a1 04 50 18 00       	mov    0x185004,%eax
  10ad06:	05 00 03 00 00       	add    $0x300,%eax
  10ad0b:	8b 00                	mov    (%eax),%eax
  10ad0d:	25 00 10 00 00       	and    $0x1000,%eax
  10ad12:	85 c0                	test   %eax,%eax
  10ad14:	75 eb                	jne    10ad01 <lapic_init+0x16a>
		;

	// Enable interrupts on the APIC (but not on the processor).
	lapicw(TPR, 0);
  10ad16:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  10ad1d:	00 
  10ad1e:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  10ad25:	e8 4a fe ff ff       	call   10ab74 <lapicw>
}
  10ad2a:	c9                   	leave  
  10ad2b:	c3                   	ret    

0010ad2c <lapic_eoi>:

// Acknowledge interrupt.
void
lapic_eoi(void)
{
  10ad2c:	55                   	push   %ebp
  10ad2d:	89 e5                	mov    %esp,%ebp
  10ad2f:	83 ec 08             	sub    $0x8,%esp
	if (lapic)
  10ad32:	a1 04 50 18 00       	mov    0x185004,%eax
  10ad37:	85 c0                	test   %eax,%eax
  10ad39:	74 14                	je     10ad4f <lapic_eoi+0x23>
		lapicw(EOI, 0);
  10ad3b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  10ad42:	00 
  10ad43:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
  10ad4a:	e8 25 fe ff ff       	call   10ab74 <lapicw>
}
  10ad4f:	c9                   	leave  
  10ad50:	c3                   	ret    

0010ad51 <lapic_errintr>:

void lapic_errintr(void)
{
  10ad51:	55                   	push   %ebp
  10ad52:	89 e5                	mov    %esp,%ebp
  10ad54:	53                   	push   %ebx
  10ad55:	83 ec 14             	sub    $0x14,%esp
	lapic_eoi();	// Acknowledge interrupt
  10ad58:	e8 cf ff ff ff       	call   10ad2c <lapic_eoi>
	lapicw(ESR, 0);	// Trigger update of ESR by writing anything
  10ad5d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  10ad64:	00 
  10ad65:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
  10ad6c:	e8 03 fe ff ff       	call   10ab74 <lapicw>
	warn("CPU%d LAPIC error: ESR %x", cpu_cur()->id, lapic[ESR]);
  10ad71:	a1 04 50 18 00       	mov    0x185004,%eax
  10ad76:	05 80 02 00 00       	add    $0x280,%eax
  10ad7b:	8b 18                	mov    (%eax),%ebx
  10ad7d:	e8 34 00 00 00       	call   10adb6 <cpu_cur>
  10ad82:	0f b6 80 ac 00 00 00 	movzbl 0xac(%eax),%eax
  10ad89:	0f b6 c0             	movzbl %al,%eax
  10ad8c:	89 5c 24 10          	mov    %ebx,0x10(%esp)
  10ad90:	89 44 24 0c          	mov    %eax,0xc(%esp)
  10ad94:	c7 44 24 08 80 df 10 	movl   $0x10df80,0x8(%esp)
  10ad9b:	00 
  10ad9c:	c7 44 24 04 60 00 00 	movl   $0x60,0x4(%esp)
  10ada3:	00 
  10ada4:	c7 04 24 9a df 10 00 	movl   $0x10df9a,(%esp)
  10adab:	e8 46 5c ff ff       	call   1009f6 <debug_warn>
}
  10adb0:	83 c4 14             	add    $0x14,%esp
  10adb3:	5b                   	pop    %ebx
  10adb4:	5d                   	pop    %ebp
  10adb5:	c3                   	ret    

0010adb6 <cpu_cur>:

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  10adb6:	55                   	push   %ebp
  10adb7:	89 e5                	mov    %esp,%ebp
  10adb9:	83 ec 28             	sub    $0x28,%esp
static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  10adbc:	89 65 fc             	mov    %esp,0xfffffffc(%ebp)
        return esp;
  10adbf:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  10adc2:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  10adc5:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10adc8:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  10adcd:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	assert(c->magic == CPU_MAGIC);
  10add0:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  10add3:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  10add9:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  10adde:	74 24                	je     10ae04 <cpu_cur+0x4e>
  10ade0:	c7 44 24 0c a6 df 10 	movl   $0x10dfa6,0xc(%esp)
  10ade7:	00 
  10ade8:	c7 44 24 08 bc df 10 	movl   $0x10dfbc,0x8(%esp)
  10adef:	00 
  10adf0:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  10adf7:	00 
  10adf8:	c7 04 24 d1 df 10 00 	movl   $0x10dfd1,(%esp)
  10adff:	e8 34 5b ff ff       	call   100938 <debug_panic>
	return c;
  10ae04:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
}
  10ae07:	c9                   	leave  
  10ae08:	c3                   	ret    

0010ae09 <microdelay>:

// Spin for a given number of microseconds.
// On real hardware would want to tune this dynamically.
void
microdelay(int us)
{
  10ae09:	55                   	push   %ebp
  10ae0a:	89 e5                	mov    %esp,%ebp
}
  10ae0c:	5d                   	pop    %ebp
  10ae0d:	c3                   	ret    

0010ae0e <lapic_startcpu>:


#define IO_RTC  0x70

// Start additional processor running bootstrap code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapic_startcpu(uint8_t apicid, uint32_t addr)
{
  10ae0e:	55                   	push   %ebp
  10ae0f:	89 e5                	mov    %esp,%ebp
  10ae11:	83 ec 2c             	sub    $0x2c,%esp
  10ae14:	8b 45 08             	mov    0x8(%ebp),%eax
  10ae17:	88 45 dc             	mov    %al,0xffffffdc(%ebp)
  10ae1a:	c7 45 f4 70 00 00 00 	movl   $0x70,0xfffffff4(%ebp)
  10ae21:	c6 45 f3 0f          	movb   $0xf,0xfffffff3(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  10ae25:	0f b6 45 f3          	movzbl 0xfffffff3(%ebp),%eax
  10ae29:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  10ae2c:	ee                   	out    %al,(%dx)
  10ae2d:	c7 45 fc 71 00 00 00 	movl   $0x71,0xfffffffc(%ebp)
  10ae34:	c6 45 fb 0a          	movb   $0xa,0xfffffffb(%ebp)
  10ae38:	0f b6 45 fb          	movzbl 0xfffffffb(%ebp),%eax
  10ae3c:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  10ae3f:	ee                   	out    %al,(%dx)
	int i;
	uint16_t *wrv;

	// "The BSP must initialize CMOS shutdown code to 0AH
	// and the warm reset vector (DWORD based at 40:67) to point at
	// the AP startup code prior to the [universal startup algorithm]."
	outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
	outb(IO_RTC+1, 0x0A);
	wrv = (uint16_t*)(0x40<<4 | 0x67);  // Warm reset vector
  10ae40:	c7 45 ec 67 04 00 00 	movl   $0x467,0xffffffec(%ebp)
	wrv[0] = 0;
  10ae47:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  10ae4a:	66 c7 00 00 00       	movw   $0x0,(%eax)
	wrv[1] = addr >> 4;
  10ae4f:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
  10ae52:	83 c2 02             	add    $0x2,%edx
  10ae55:	8b 45 0c             	mov    0xc(%ebp),%eax
  10ae58:	c1 e8 04             	shr    $0x4,%eax
  10ae5b:	66 89 02             	mov    %ax,(%edx)

	// "Universal startup algorithm."
	// Send INIT (level-triggered) interrupt to reset other CPU.
	lapicw(ICRHI, apicid<<24);
  10ae5e:	0f b6 45 dc          	movzbl 0xffffffdc(%ebp),%eax
  10ae62:	c1 e0 18             	shl    $0x18,%eax
  10ae65:	89 44 24 04          	mov    %eax,0x4(%esp)
  10ae69:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
  10ae70:	e8 ff fc ff ff       	call   10ab74 <lapicw>
	lapicw(ICRLO, INIT | LEVEL | ASSERT);
  10ae75:	c7 44 24 04 00 c5 00 	movl   $0xc500,0x4(%esp)
  10ae7c:	00 
  10ae7d:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
  10ae84:	e8 eb fc ff ff       	call   10ab74 <lapicw>
	microdelay(200);
  10ae89:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
  10ae90:	e8 74 ff ff ff       	call   10ae09 <microdelay>
	lapicw(ICRLO, INIT | LEVEL);
  10ae95:	c7 44 24 04 00 85 00 	movl   $0x8500,0x4(%esp)
  10ae9c:	00 
  10ae9d:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
  10aea4:	e8 cb fc ff ff       	call   10ab74 <lapicw>
	microdelay(100);    // should be 10ms, but too slow in Bochs!
  10aea9:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
  10aeb0:	e8 54 ff ff ff       	call   10ae09 <microdelay>

	// Send startup IPI (twice!) to enter bootstrap code.
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for(i = 0; i < 2; i++){
  10aeb5:	c7 45 e8 00 00 00 00 	movl   $0x0,0xffffffe8(%ebp)
  10aebc:	eb 40                	jmp    10aefe <lapic_startcpu+0xf0>
		lapicw(ICRHI, apicid<<24);
  10aebe:	0f b6 45 dc          	movzbl 0xffffffdc(%ebp),%eax
  10aec2:	c1 e0 18             	shl    $0x18,%eax
  10aec5:	89 44 24 04          	mov    %eax,0x4(%esp)
  10aec9:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
  10aed0:	e8 9f fc ff ff       	call   10ab74 <lapicw>
		lapicw(ICRLO, STARTUP | (addr>>12));
  10aed5:	8b 45 0c             	mov    0xc(%ebp),%eax
  10aed8:	c1 e8 0c             	shr    $0xc,%eax
  10aedb:	80 cc 06             	or     $0x6,%ah
  10aede:	89 44 24 04          	mov    %eax,0x4(%esp)
  10aee2:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
  10aee9:	e8 86 fc ff ff       	call   10ab74 <lapicw>
		microdelay(200);
  10aeee:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
  10aef5:	e8 0f ff ff ff       	call   10ae09 <microdelay>
  10aefa:	83 45 e8 01          	addl   $0x1,0xffffffe8(%ebp)
  10aefe:	83 7d e8 01          	cmpl   $0x1,0xffffffe8(%ebp)
  10af02:	7e ba                	jle    10aebe <lapic_startcpu+0xb0>
	}
}
  10af04:	c9                   	leave  
  10af05:	c3                   	ret    
  10af06:	90                   	nop    
  10af07:	90                   	nop    

0010af08 <ioapic_read>:
};

static uint32_t
ioapic_read(int reg)
{
  10af08:	55                   	push   %ebp
  10af09:	89 e5                	mov    %esp,%ebp
	ioapic->reg = reg;
  10af0b:	8b 15 e8 1d 18 00    	mov    0x181de8,%edx
  10af11:	8b 45 08             	mov    0x8(%ebp),%eax
  10af14:	89 02                	mov    %eax,(%edx)
	return ioapic->data;
  10af16:	a1 e8 1d 18 00       	mov    0x181de8,%eax
  10af1b:	8b 40 10             	mov    0x10(%eax),%eax
}
  10af1e:	5d                   	pop    %ebp
  10af1f:	c3                   	ret    

0010af20 <ioapic_write>:

static void
ioapic_write(int reg, uint32_t data)
{
  10af20:	55                   	push   %ebp
  10af21:	89 e5                	mov    %esp,%ebp
	ioapic->reg = reg;
  10af23:	8b 15 e8 1d 18 00    	mov    0x181de8,%edx
  10af29:	8b 45 08             	mov    0x8(%ebp),%eax
  10af2c:	89 02                	mov    %eax,(%edx)
	ioapic->data = data;
  10af2e:	8b 15 e8 1d 18 00    	mov    0x181de8,%edx
  10af34:	8b 45 0c             	mov    0xc(%ebp),%eax
  10af37:	89 42 10             	mov    %eax,0x10(%edx)
}
  10af3a:	5d                   	pop    %ebp
  10af3b:	c3                   	ret    

0010af3c <ioapic_init>:

void
ioapic_init(void)
{
  10af3c:	55                   	push   %ebp
  10af3d:	89 e5                	mov    %esp,%ebp
  10af3f:	83 ec 28             	sub    $0x28,%esp
	int i, id, maxintr;

	if(!ismp)
  10af42:	a1 ec 1d 18 00       	mov    0x181dec,%eax
  10af47:	85 c0                	test   %eax,%eax
  10af49:	0f 84 fa 00 00 00    	je     10b049 <ioapic_init+0x10d>
		return;

	if (ioapic == NULL)
  10af4f:	a1 e8 1d 18 00       	mov    0x181de8,%eax
  10af54:	85 c0                	test   %eax,%eax
  10af56:	75 0a                	jne    10af62 <ioapic_init+0x26>
		ioapic = mem_ptr(IOAPIC);	// assume default address
  10af58:	c7 05 e8 1d 18 00 00 	movl   $0xfec00000,0x181de8
  10af5f:	00 c0 fe 

	maxintr = (ioapic_read(REG_VER) >> 16) & 0xFF;
  10af62:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  10af69:	e8 9a ff ff ff       	call   10af08 <ioapic_read>
  10af6e:	c1 e8 10             	shr    $0x10,%eax
  10af71:	25 ff 00 00 00       	and    $0xff,%eax
  10af76:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	id = ioapic_read(REG_ID) >> 24;
  10af79:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  10af80:	e8 83 ff ff ff       	call   10af08 <ioapic_read>
  10af85:	c1 e8 18             	shr    $0x18,%eax
  10af88:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
	if (id == 0) {
  10af8b:	83 7d f8 00          	cmpl   $0x0,0xfffffff8(%ebp)
  10af8f:	75 2a                	jne    10afbb <ioapic_init+0x7f>
		// I/O APIC ID not initialized yet - have to do it ourselves.
		ioapic_write(REG_ID, ioapicid << 24);
  10af91:	0f b6 05 e4 1d 18 00 	movzbl 0x181de4,%eax
  10af98:	0f b6 c0             	movzbl %al,%eax
  10af9b:	c1 e0 18             	shl    $0x18,%eax
  10af9e:	89 44 24 04          	mov    %eax,0x4(%esp)
  10afa2:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  10afa9:	e8 72 ff ff ff       	call   10af20 <ioapic_write>
		id = ioapicid;
  10afae:	0f b6 05 e4 1d 18 00 	movzbl 0x181de4,%eax
  10afb5:	0f b6 c0             	movzbl %al,%eax
  10afb8:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
	}
	if (id != ioapicid)
  10afbb:	0f b6 05 e4 1d 18 00 	movzbl 0x181de4,%eax
  10afc2:	0f b6 c0             	movzbl %al,%eax
  10afc5:	3b 45 f8             	cmp    0xfffffff8(%ebp),%eax
  10afc8:	74 31                	je     10affb <ioapic_init+0xbf>
		warn("ioapicinit: id %d != ioapicid %d", id, ioapicid);
  10afca:	0f b6 05 e4 1d 18 00 	movzbl 0x181de4,%eax
  10afd1:	0f b6 c0             	movzbl %al,%eax
  10afd4:	89 44 24 10          	mov    %eax,0x10(%esp)
  10afd8:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10afdb:	89 44 24 0c          	mov    %eax,0xc(%esp)
  10afdf:	c7 44 24 08 e0 df 10 	movl   $0x10dfe0,0x8(%esp)
  10afe6:	00 
  10afe7:	c7 44 24 04 53 00 00 	movl   $0x53,0x4(%esp)
  10afee:	00 
  10afef:	c7 04 24 01 e0 10 00 	movl   $0x10e001,(%esp)
  10aff6:	e8 fb 59 ff ff       	call   1009f6 <debug_warn>

	// Mark all interrupts edge-triggered, active high, disabled,
	// and not routed to any CPUs.
	for (i = 0; i <= maxintr; i++){
  10affb:	c7 45 f4 00 00 00 00 	movl   $0x0,0xfffffff4(%ebp)
  10b002:	eb 3d                	jmp    10b041 <ioapic_init+0x105>
		ioapic_write(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
  10b004:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  10b007:	83 c0 20             	add    $0x20,%eax
  10b00a:	0d 00 00 01 00       	or     $0x10000,%eax
  10b00f:	89 c2                	mov    %eax,%edx
  10b011:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  10b014:	01 c0                	add    %eax,%eax
  10b016:	83 c0 10             	add    $0x10,%eax
  10b019:	89 54 24 04          	mov    %edx,0x4(%esp)
  10b01d:	89 04 24             	mov    %eax,(%esp)
  10b020:	e8 fb fe ff ff       	call   10af20 <ioapic_write>
		ioapic_write(REG_TABLE+2*i+1, 0);
  10b025:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  10b028:	01 c0                	add    %eax,%eax
  10b02a:	83 c0 11             	add    $0x11,%eax
  10b02d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  10b034:	00 
  10b035:	89 04 24             	mov    %eax,(%esp)
  10b038:	e8 e3 fe ff ff       	call   10af20 <ioapic_write>
  10b03d:	83 45 f4 01          	addl   $0x1,0xfffffff4(%ebp)
  10b041:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  10b044:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  10b047:	7e bb                	jle    10b004 <ioapic_init+0xc8>
	}
}
  10b049:	c9                   	leave  
  10b04a:	c3                   	ret    

0010b04b <ioapic_enable>:

void
ioapic_enable(int irq)
{
  10b04b:	55                   	push   %ebp
  10b04c:	89 e5                	mov    %esp,%ebp
  10b04e:	83 ec 08             	sub    $0x8,%esp
	if (!ismp)
  10b051:	a1 ec 1d 18 00       	mov    0x181dec,%eax
  10b056:	85 c0                	test   %eax,%eax
  10b058:	74 37                	je     10b091 <ioapic_enable+0x46>
		return;

	// Mark interrupt edge-triggered, active high,
	// enabled, and routed to any CPU.
	ioapic_write(REG_TABLE+2*irq,
  10b05a:	8b 45 08             	mov    0x8(%ebp),%eax
  10b05d:	83 c0 20             	add    $0x20,%eax
  10b060:	80 cc 09             	or     $0x9,%ah
  10b063:	89 c2                	mov    %eax,%edx
  10b065:	8b 45 08             	mov    0x8(%ebp),%eax
  10b068:	01 c0                	add    %eax,%eax
  10b06a:	83 c0 10             	add    $0x10,%eax
  10b06d:	89 54 24 04          	mov    %edx,0x4(%esp)
  10b071:	89 04 24             	mov    %eax,(%esp)
  10b074:	e8 a7 fe ff ff       	call   10af20 <ioapic_write>
			INT_LOGICAL | INT_LOWEST | (T_IRQ0 + irq));
	ioapic_write(REG_TABLE+2*irq+1, 0xff << 24);
  10b079:	8b 45 08             	mov    0x8(%ebp),%eax
  10b07c:	01 c0                	add    %eax,%eax
  10b07e:	83 c0 11             	add    $0x11,%eax
  10b081:	c7 44 24 04 00 00 00 	movl   $0xff000000,0x4(%esp)
  10b088:	ff 
  10b089:	89 04 24             	mov    %eax,(%esp)
  10b08c:	e8 8f fe ff ff       	call   10af20 <ioapic_write>
}
  10b091:	c9                   	leave  
  10b092:	c3                   	ret    
  10b093:	90                   	nop    

0010b094 <getuint>:
  10b094:	55                   	push   %ebp
  10b095:	89 e5                	mov    %esp,%ebp
  10b097:	83 ec 08             	sub    $0x8,%esp
  10b09a:	8b 45 08             	mov    0x8(%ebp),%eax
  10b09d:	8b 40 18             	mov    0x18(%eax),%eax
  10b0a0:	83 e0 02             	and    $0x2,%eax
  10b0a3:	85 c0                	test   %eax,%eax
  10b0a5:	74 22                	je     10b0c9 <getuint+0x35>
  10b0a7:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b0aa:	8b 00                	mov    (%eax),%eax
  10b0ac:	8d 50 08             	lea    0x8(%eax),%edx
  10b0af:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b0b2:	89 10                	mov    %edx,(%eax)
  10b0b4:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b0b7:	8b 00                	mov    (%eax),%eax
  10b0b9:	83 e8 08             	sub    $0x8,%eax
  10b0bc:	8b 10                	mov    (%eax),%edx
  10b0be:	8b 48 04             	mov    0x4(%eax),%ecx
  10b0c1:	89 55 f8             	mov    %edx,0xfffffff8(%ebp)
  10b0c4:	89 4d fc             	mov    %ecx,0xfffffffc(%ebp)
  10b0c7:	eb 51                	jmp    10b11a <getuint+0x86>
  10b0c9:	8b 45 08             	mov    0x8(%ebp),%eax
  10b0cc:	8b 40 18             	mov    0x18(%eax),%eax
  10b0cf:	83 e0 01             	and    $0x1,%eax
  10b0d2:	84 c0                	test   %al,%al
  10b0d4:	74 23                	je     10b0f9 <getuint+0x65>
  10b0d6:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b0d9:	8b 00                	mov    (%eax),%eax
  10b0db:	8d 50 04             	lea    0x4(%eax),%edx
  10b0de:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b0e1:	89 10                	mov    %edx,(%eax)
  10b0e3:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b0e6:	8b 00                	mov    (%eax),%eax
  10b0e8:	83 e8 04             	sub    $0x4,%eax
  10b0eb:	8b 00                	mov    (%eax),%eax
  10b0ed:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  10b0f0:	c7 45 fc 00 00 00 00 	movl   $0x0,0xfffffffc(%ebp)
  10b0f7:	eb 21                	jmp    10b11a <getuint+0x86>
  10b0f9:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b0fc:	8b 00                	mov    (%eax),%eax
  10b0fe:	8d 50 04             	lea    0x4(%eax),%edx
  10b101:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b104:	89 10                	mov    %edx,(%eax)
  10b106:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b109:	8b 00                	mov    (%eax),%eax
  10b10b:	83 e8 04             	sub    $0x4,%eax
  10b10e:	8b 00                	mov    (%eax),%eax
  10b110:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  10b113:	c7 45 fc 00 00 00 00 	movl   $0x0,0xfffffffc(%ebp)
  10b11a:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10b11d:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  10b120:	c9                   	leave  
  10b121:	c3                   	ret    

0010b122 <getint>:
  10b122:	55                   	push   %ebp
  10b123:	89 e5                	mov    %esp,%ebp
  10b125:	83 ec 08             	sub    $0x8,%esp
  10b128:	8b 45 08             	mov    0x8(%ebp),%eax
  10b12b:	8b 40 18             	mov    0x18(%eax),%eax
  10b12e:	83 e0 02             	and    $0x2,%eax
  10b131:	85 c0                	test   %eax,%eax
  10b133:	74 22                	je     10b157 <getint+0x35>
  10b135:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b138:	8b 00                	mov    (%eax),%eax
  10b13a:	8d 50 08             	lea    0x8(%eax),%edx
  10b13d:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b140:	89 10                	mov    %edx,(%eax)
  10b142:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b145:	8b 00                	mov    (%eax),%eax
  10b147:	83 e8 08             	sub    $0x8,%eax
  10b14a:	8b 10                	mov    (%eax),%edx
  10b14c:	8b 48 04             	mov    0x4(%eax),%ecx
  10b14f:	89 55 f8             	mov    %edx,0xfffffff8(%ebp)
  10b152:	89 4d fc             	mov    %ecx,0xfffffffc(%ebp)
  10b155:	eb 53                	jmp    10b1aa <getint+0x88>
  10b157:	8b 45 08             	mov    0x8(%ebp),%eax
  10b15a:	8b 40 18             	mov    0x18(%eax),%eax
  10b15d:	83 e0 01             	and    $0x1,%eax
  10b160:	84 c0                	test   %al,%al
  10b162:	74 24                	je     10b188 <getint+0x66>
  10b164:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b167:	8b 00                	mov    (%eax),%eax
  10b169:	8d 50 04             	lea    0x4(%eax),%edx
  10b16c:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b16f:	89 10                	mov    %edx,(%eax)
  10b171:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b174:	8b 00                	mov    (%eax),%eax
  10b176:	83 e8 04             	sub    $0x4,%eax
  10b179:	8b 00                	mov    (%eax),%eax
  10b17b:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  10b17e:	89 c1                	mov    %eax,%ecx
  10b180:	c1 f9 1f             	sar    $0x1f,%ecx
  10b183:	89 4d fc             	mov    %ecx,0xfffffffc(%ebp)
  10b186:	eb 22                	jmp    10b1aa <getint+0x88>
  10b188:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b18b:	8b 00                	mov    (%eax),%eax
  10b18d:	8d 50 04             	lea    0x4(%eax),%edx
  10b190:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b193:	89 10                	mov    %edx,(%eax)
  10b195:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b198:	8b 00                	mov    (%eax),%eax
  10b19a:	83 e8 04             	sub    $0x4,%eax
  10b19d:	8b 00                	mov    (%eax),%eax
  10b19f:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  10b1a2:	89 c2                	mov    %eax,%edx
  10b1a4:	c1 fa 1f             	sar    $0x1f,%edx
  10b1a7:	89 55 fc             	mov    %edx,0xfffffffc(%ebp)
  10b1aa:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10b1ad:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  10b1b0:	c9                   	leave  
  10b1b1:	c3                   	ret    

0010b1b2 <putpad>:
  10b1b2:	55                   	push   %ebp
  10b1b3:	89 e5                	mov    %esp,%ebp
  10b1b5:	83 ec 08             	sub    $0x8,%esp
  10b1b8:	eb 1a                	jmp    10b1d4 <putpad+0x22>
  10b1ba:	8b 45 08             	mov    0x8(%ebp),%eax
  10b1bd:	8b 08                	mov    (%eax),%ecx
  10b1bf:	8b 45 08             	mov    0x8(%ebp),%eax
  10b1c2:	8b 50 04             	mov    0x4(%eax),%edx
  10b1c5:	8b 45 08             	mov    0x8(%ebp),%eax
  10b1c8:	8b 40 08             	mov    0x8(%eax),%eax
  10b1cb:	89 54 24 04          	mov    %edx,0x4(%esp)
  10b1cf:	89 04 24             	mov    %eax,(%esp)
  10b1d2:	ff d1                	call   *%ecx
  10b1d4:	8b 45 08             	mov    0x8(%ebp),%eax
  10b1d7:	8b 40 0c             	mov    0xc(%eax),%eax
  10b1da:	8d 50 ff             	lea    0xffffffff(%eax),%edx
  10b1dd:	8b 45 08             	mov    0x8(%ebp),%eax
  10b1e0:	89 50 0c             	mov    %edx,0xc(%eax)
  10b1e3:	8b 45 08             	mov    0x8(%ebp),%eax
  10b1e6:	8b 40 0c             	mov    0xc(%eax),%eax
  10b1e9:	85 c0                	test   %eax,%eax
  10b1eb:	79 cd                	jns    10b1ba <putpad+0x8>
  10b1ed:	c9                   	leave  
  10b1ee:	c3                   	ret    

0010b1ef <putstr>:
  10b1ef:	55                   	push   %ebp
  10b1f0:	89 e5                	mov    %esp,%ebp
  10b1f2:	53                   	push   %ebx
  10b1f3:	83 ec 24             	sub    $0x24,%esp
  10b1f6:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  10b1fa:	79 18                	jns    10b214 <putstr+0x25>
  10b1fc:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  10b203:	00 
  10b204:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b207:	89 04 24             	mov    %eax,(%esp)
  10b20a:	e8 a2 09 00 00       	call   10bbb1 <strchr>
  10b20f:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
  10b212:	eb 2c                	jmp    10b240 <putstr+0x51>
  10b214:	8b 45 10             	mov    0x10(%ebp),%eax
  10b217:	89 44 24 08          	mov    %eax,0x8(%esp)
  10b21b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  10b222:	00 
  10b223:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b226:	89 04 24             	mov    %eax,(%esp)
  10b229:	e8 80 0b 00 00       	call   10bdae <memchr>
  10b22e:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
  10b231:	83 7d f4 00          	cmpl   $0x0,0xfffffff4(%ebp)
  10b235:	75 09                	jne    10b240 <putstr+0x51>
  10b237:	8b 45 10             	mov    0x10(%ebp),%eax
  10b23a:	03 45 0c             	add    0xc(%ebp),%eax
  10b23d:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
  10b240:	8b 45 08             	mov    0x8(%ebp),%eax
  10b243:	8b 48 0c             	mov    0xc(%eax),%ecx
  10b246:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  10b249:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b24c:	89 d3                	mov    %edx,%ebx
  10b24e:	29 c3                	sub    %eax,%ebx
  10b250:	89 d8                	mov    %ebx,%eax
  10b252:	89 ca                	mov    %ecx,%edx
  10b254:	29 c2                	sub    %eax,%edx
  10b256:	8b 45 08             	mov    0x8(%ebp),%eax
  10b259:	89 50 0c             	mov    %edx,0xc(%eax)
  10b25c:	8b 45 08             	mov    0x8(%ebp),%eax
  10b25f:	8b 40 18             	mov    0x18(%eax),%eax
  10b262:	83 e0 10             	and    $0x10,%eax
  10b265:	85 c0                	test   %eax,%eax
  10b267:	75 32                	jne    10b29b <putstr+0xac>
  10b269:	8b 45 08             	mov    0x8(%ebp),%eax
  10b26c:	89 04 24             	mov    %eax,(%esp)
  10b26f:	e8 3e ff ff ff       	call   10b1b2 <putpad>
  10b274:	eb 25                	jmp    10b29b <putstr+0xac>
  10b276:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b279:	0f b6 00             	movzbl (%eax),%eax
  10b27c:	88 45 fb             	mov    %al,0xfffffffb(%ebp)
  10b27f:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
  10b283:	8b 45 08             	mov    0x8(%ebp),%eax
  10b286:	8b 08                	mov    (%eax),%ecx
  10b288:	8b 45 08             	mov    0x8(%ebp),%eax
  10b28b:	8b 40 04             	mov    0x4(%eax),%eax
  10b28e:	0f be 55 fb          	movsbl 0xfffffffb(%ebp),%edx
  10b292:	89 44 24 04          	mov    %eax,0x4(%esp)
  10b296:	89 14 24             	mov    %edx,(%esp)
  10b299:	ff d1                	call   *%ecx
  10b29b:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b29e:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  10b2a1:	72 d3                	jb     10b276 <putstr+0x87>
  10b2a3:	8b 45 08             	mov    0x8(%ebp),%eax
  10b2a6:	89 04 24             	mov    %eax,(%esp)
  10b2a9:	e8 04 ff ff ff       	call   10b1b2 <putpad>
  10b2ae:	83 c4 24             	add    $0x24,%esp
  10b2b1:	5b                   	pop    %ebx
  10b2b2:	5d                   	pop    %ebp
  10b2b3:	c3                   	ret    

0010b2b4 <genint>:
  10b2b4:	55                   	push   %ebp
  10b2b5:	89 e5                	mov    %esp,%ebp
  10b2b7:	53                   	push   %ebx
  10b2b8:	83 ec 24             	sub    $0x24,%esp
  10b2bb:	8b 45 10             	mov    0x10(%ebp),%eax
  10b2be:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
  10b2c1:	8b 45 14             	mov    0x14(%ebp),%eax
  10b2c4:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
  10b2c7:	8b 45 08             	mov    0x8(%ebp),%eax
  10b2ca:	8b 40 1c             	mov    0x1c(%eax),%eax
  10b2cd:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  10b2d0:	89 c2                	mov    %eax,%edx
  10b2d2:	c1 fa 1f             	sar    $0x1f,%edx
  10b2d5:	89 55 ec             	mov    %edx,0xffffffec(%ebp)
  10b2d8:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  10b2db:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  10b2de:	77 54                	ja     10b334 <genint+0x80>
  10b2e0:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
  10b2e3:	3b 55 f4             	cmp    0xfffffff4(%ebp),%edx
  10b2e6:	72 08                	jb     10b2f0 <genint+0x3c>
  10b2e8:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  10b2eb:	3b 45 f0             	cmp    0xfffffff0(%ebp),%eax
  10b2ee:	77 44                	ja     10b334 <genint+0x80>
  10b2f0:	8b 45 08             	mov    0x8(%ebp),%eax
  10b2f3:	8b 40 1c             	mov    0x1c(%eax),%eax
  10b2f6:	89 c2                	mov    %eax,%edx
  10b2f8:	c1 fa 1f             	sar    $0x1f,%edx
  10b2fb:	89 44 24 08          	mov    %eax,0x8(%esp)
  10b2ff:	89 54 24 0c          	mov    %edx,0xc(%esp)
  10b303:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  10b306:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  10b309:	89 04 24             	mov    %eax,(%esp)
  10b30c:	89 54 24 04          	mov    %edx,0x4(%esp)
  10b310:	e8 db 0a 00 00       	call   10bdf0 <__udivdi3>
  10b315:	89 44 24 08          	mov    %eax,0x8(%esp)
  10b319:	89 54 24 0c          	mov    %edx,0xc(%esp)
  10b31d:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b320:	89 44 24 04          	mov    %eax,0x4(%esp)
  10b324:	8b 45 08             	mov    0x8(%ebp),%eax
  10b327:	89 04 24             	mov    %eax,(%esp)
  10b32a:	e8 85 ff ff ff       	call   10b2b4 <genint>
  10b32f:	89 45 0c             	mov    %eax,0xc(%ebp)
  10b332:	eb 1b                	jmp    10b34f <genint+0x9b>
  10b334:	8b 45 08             	mov    0x8(%ebp),%eax
  10b337:	8b 40 14             	mov    0x14(%eax),%eax
  10b33a:	85 c0                	test   %eax,%eax
  10b33c:	78 11                	js     10b34f <genint+0x9b>
  10b33e:	8b 45 08             	mov    0x8(%ebp),%eax
  10b341:	8b 40 14             	mov    0x14(%eax),%eax
  10b344:	89 c2                	mov    %eax,%edx
  10b346:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b349:	88 10                	mov    %dl,(%eax)
  10b34b:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
  10b34f:	8b 45 08             	mov    0x8(%ebp),%eax
  10b352:	8b 40 1c             	mov    0x1c(%eax),%eax
  10b355:	89 c2                	mov    %eax,%edx
  10b357:	c1 fa 1f             	sar    $0x1f,%edx
  10b35a:	8b 4d f0             	mov    0xfffffff0(%ebp),%ecx
  10b35d:	8b 5d f4             	mov    0xfffffff4(%ebp),%ebx
  10b360:	89 44 24 08          	mov    %eax,0x8(%esp)
  10b364:	89 54 24 0c          	mov    %edx,0xc(%esp)
  10b368:	89 0c 24             	mov    %ecx,(%esp)
  10b36b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  10b36f:	e8 ac 0b 00 00       	call   10bf20 <__umoddi3>
  10b374:	05 10 e0 10 00       	add    $0x10e010,%eax
  10b379:	0f b6 10             	movzbl (%eax),%edx
  10b37c:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b37f:	88 10                	mov    %dl,(%eax)
  10b381:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
  10b385:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b388:	83 c4 24             	add    $0x24,%esp
  10b38b:	5b                   	pop    %ebx
  10b38c:	5d                   	pop    %ebp
  10b38d:	c3                   	ret    

0010b38e <putint>:
  10b38e:	55                   	push   %ebp
  10b38f:	89 e5                	mov    %esp,%ebp
  10b391:	83 ec 48             	sub    $0x48,%esp
  10b394:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b397:	89 45 c8             	mov    %eax,0xffffffc8(%ebp)
  10b39a:	8b 45 10             	mov    0x10(%ebp),%eax
  10b39d:	89 45 cc             	mov    %eax,0xffffffcc(%ebp)
  10b3a0:	8d 45 de             	lea    0xffffffde(%ebp),%eax
  10b3a3:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  10b3a6:	8b 55 08             	mov    0x8(%ebp),%edx
  10b3a9:	8b 45 14             	mov    0x14(%ebp),%eax
  10b3ac:	89 42 1c             	mov    %eax,0x1c(%edx)
  10b3af:	8b 45 c8             	mov    0xffffffc8(%ebp),%eax
  10b3b2:	8b 55 cc             	mov    0xffffffcc(%ebp),%edx
  10b3b5:	89 44 24 08          	mov    %eax,0x8(%esp)
  10b3b9:	89 54 24 0c          	mov    %edx,0xc(%esp)
  10b3bd:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  10b3c0:	89 44 24 04          	mov    %eax,0x4(%esp)
  10b3c4:	8b 45 08             	mov    0x8(%ebp),%eax
  10b3c7:	89 04 24             	mov    %eax,(%esp)
  10b3ca:	e8 e5 fe ff ff       	call   10b2b4 <genint>
  10b3cf:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  10b3d2:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  10b3d5:	8d 45 de             	lea    0xffffffde(%ebp),%eax
  10b3d8:	89 d1                	mov    %edx,%ecx
  10b3da:	29 c1                	sub    %eax,%ecx
  10b3dc:	89 c8                	mov    %ecx,%eax
  10b3de:	89 44 24 08          	mov    %eax,0x8(%esp)
  10b3e2:	8d 45 de             	lea    0xffffffde(%ebp),%eax
  10b3e5:	89 44 24 04          	mov    %eax,0x4(%esp)
  10b3e9:	8b 45 08             	mov    0x8(%ebp),%eax
  10b3ec:	89 04 24             	mov    %eax,(%esp)
  10b3ef:	e8 fb fd ff ff       	call   10b1ef <putstr>
  10b3f4:	c9                   	leave  
  10b3f5:	c3                   	ret    

0010b3f6 <vprintfmt>:
  10b3f6:	55                   	push   %ebp
  10b3f7:	89 e5                	mov    %esp,%ebp
  10b3f9:	57                   	push   %edi
  10b3fa:	83 ec 54             	sub    $0x54,%esp
  10b3fd:	8d 7d c8             	lea    0xffffffc8(%ebp),%edi
  10b400:	fc                   	cld    
  10b401:	ba 00 00 00 00       	mov    $0x0,%edx
  10b406:	b8 08 00 00 00       	mov    $0x8,%eax
  10b40b:	89 c1                	mov    %eax,%ecx
  10b40d:	89 d0                	mov    %edx,%eax
  10b40f:	f3 ab                	rep stos %eax,%es:(%edi)
  10b411:	8b 45 08             	mov    0x8(%ebp),%eax
  10b414:	89 45 c8             	mov    %eax,0xffffffc8(%ebp)
  10b417:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b41a:	89 45 cc             	mov    %eax,0xffffffcc(%ebp)
  10b41d:	eb 1c                	jmp    10b43b <vprintfmt+0x45>
  10b41f:	83 7d c4 00          	cmpl   $0x0,0xffffffc4(%ebp)
  10b423:	0f 84 73 03 00 00    	je     10b79c <vprintfmt+0x3a6>
  10b429:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b42c:	89 44 24 04          	mov    %eax,0x4(%esp)
  10b430:	8b 55 c4             	mov    0xffffffc4(%ebp),%edx
  10b433:	89 14 24             	mov    %edx,(%esp)
  10b436:	8b 45 08             	mov    0x8(%ebp),%eax
  10b439:	ff d0                	call   *%eax
  10b43b:	8b 45 10             	mov    0x10(%ebp),%eax
  10b43e:	0f b6 00             	movzbl (%eax),%eax
  10b441:	0f b6 c0             	movzbl %al,%eax
  10b444:	89 45 c4             	mov    %eax,0xffffffc4(%ebp)
  10b447:	83 7d c4 25          	cmpl   $0x25,0xffffffc4(%ebp)
  10b44b:	0f 95 c0             	setne  %al
  10b44e:	83 45 10 01          	addl   $0x1,0x10(%ebp)
  10b452:	84 c0                	test   %al,%al
  10b454:	75 c9                	jne    10b41f <vprintfmt+0x29>
  10b456:	c7 45 d0 20 00 00 00 	movl   $0x20,0xffffffd0(%ebp)
  10b45d:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,0xffffffd4(%ebp)
  10b464:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,0xffffffd8(%ebp)
  10b46b:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,0xffffffdc(%ebp)
  10b472:	c7 45 e0 00 00 00 00 	movl   $0x0,0xffffffe0(%ebp)
  10b479:	c7 45 e4 0a 00 00 00 	movl   $0xa,0xffffffe4(%ebp)
  10b480:	eb 00                	jmp    10b482 <vprintfmt+0x8c>
  10b482:	8b 45 10             	mov    0x10(%ebp),%eax
  10b485:	0f b6 00             	movzbl (%eax),%eax
  10b488:	0f b6 c0             	movzbl %al,%eax
  10b48b:	89 45 c4             	mov    %eax,0xffffffc4(%ebp)
  10b48e:	8b 45 c4             	mov    0xffffffc4(%ebp),%eax
  10b491:	83 45 10 01          	addl   $0x1,0x10(%ebp)
  10b495:	83 e8 20             	sub    $0x20,%eax
  10b498:	89 45 b8             	mov    %eax,0xffffffb8(%ebp)
  10b49b:	83 7d b8 58          	cmpl   $0x58,0xffffffb8(%ebp)
  10b49f:	0f 87 c8 02 00 00    	ja     10b76d <vprintfmt+0x377>
  10b4a5:	8b 55 b8             	mov    0xffffffb8(%ebp),%edx
  10b4a8:	8b 04 95 28 e0 10 00 	mov    0x10e028(,%edx,4),%eax
  10b4af:	ff e0                	jmp    *%eax
  10b4b1:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  10b4b4:	83 c8 10             	or     $0x10,%eax
  10b4b7:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)
  10b4ba:	eb c6                	jmp    10b482 <vprintfmt+0x8c>
  10b4bc:	c7 45 dc 2b 00 00 00 	movl   $0x2b,0xffffffdc(%ebp)
  10b4c3:	eb bd                	jmp    10b482 <vprintfmt+0x8c>
  10b4c5:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  10b4c8:	85 c0                	test   %eax,%eax
  10b4ca:	79 b6                	jns    10b482 <vprintfmt+0x8c>
  10b4cc:	c7 45 dc 20 00 00 00 	movl   $0x20,0xffffffdc(%ebp)
  10b4d3:	eb ad                	jmp    10b482 <vprintfmt+0x8c>
  10b4d5:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  10b4d8:	83 e0 08             	and    $0x8,%eax
  10b4db:	85 c0                	test   %eax,%eax
  10b4dd:	75 07                	jne    10b4e6 <vprintfmt+0xf0>
  10b4df:	c7 45 d0 30 00 00 00 	movl   $0x30,0xffffffd0(%ebp)
  10b4e6:	c7 45 d8 00 00 00 00 	movl   $0x0,0xffffffd8(%ebp)
  10b4ed:	8b 55 d8             	mov    0xffffffd8(%ebp),%edx
  10b4f0:	89 d0                	mov    %edx,%eax
  10b4f2:	c1 e0 02             	shl    $0x2,%eax
  10b4f5:	01 d0                	add    %edx,%eax
  10b4f7:	01 c0                	add    %eax,%eax
  10b4f9:	03 45 c4             	add    0xffffffc4(%ebp),%eax
  10b4fc:	83 e8 30             	sub    $0x30,%eax
  10b4ff:	89 45 d8             	mov    %eax,0xffffffd8(%ebp)
  10b502:	8b 45 10             	mov    0x10(%ebp),%eax
  10b505:	0f b6 00             	movzbl (%eax),%eax
  10b508:	0f be c0             	movsbl %al,%eax
  10b50b:	89 45 c4             	mov    %eax,0xffffffc4(%ebp)
  10b50e:	83 7d c4 2f          	cmpl   $0x2f,0xffffffc4(%ebp)
  10b512:	7e 20                	jle    10b534 <vprintfmt+0x13e>
  10b514:	83 7d c4 39          	cmpl   $0x39,0xffffffc4(%ebp)
  10b518:	7f 1a                	jg     10b534 <vprintfmt+0x13e>
  10b51a:	83 45 10 01          	addl   $0x1,0x10(%ebp)
  10b51e:	eb cd                	jmp    10b4ed <vprintfmt+0xf7>
  10b520:	8b 45 14             	mov    0x14(%ebp),%eax
  10b523:	83 c0 04             	add    $0x4,%eax
  10b526:	89 45 14             	mov    %eax,0x14(%ebp)
  10b529:	8b 45 14             	mov    0x14(%ebp),%eax
  10b52c:	83 e8 04             	sub    $0x4,%eax
  10b52f:	8b 00                	mov    (%eax),%eax
  10b531:	89 45 d8             	mov    %eax,0xffffffd8(%ebp)
  10b534:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  10b537:	83 e0 08             	and    $0x8,%eax
  10b53a:	85 c0                	test   %eax,%eax
  10b53c:	0f 85 40 ff ff ff    	jne    10b482 <vprintfmt+0x8c>
  10b542:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  10b545:	89 45 d4             	mov    %eax,0xffffffd4(%ebp)
  10b548:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,0xffffffd8(%ebp)
  10b54f:	e9 2e ff ff ff       	jmp    10b482 <vprintfmt+0x8c>
  10b554:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  10b557:	83 c8 08             	or     $0x8,%eax
  10b55a:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)
  10b55d:	e9 20 ff ff ff       	jmp    10b482 <vprintfmt+0x8c>
  10b562:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  10b565:	83 c8 04             	or     $0x4,%eax
  10b568:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)
  10b56b:	e9 12 ff ff ff       	jmp    10b482 <vprintfmt+0x8c>
  10b570:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  10b573:	89 45 bc             	mov    %eax,0xffffffbc(%ebp)
  10b576:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  10b579:	83 e0 01             	and    $0x1,%eax
  10b57c:	84 c0                	test   %al,%al
  10b57e:	74 09                	je     10b589 <vprintfmt+0x193>
  10b580:	c7 45 c0 02 00 00 00 	movl   $0x2,0xffffffc0(%ebp)
  10b587:	eb 07                	jmp    10b590 <vprintfmt+0x19a>
  10b589:	c7 45 c0 01 00 00 00 	movl   $0x1,0xffffffc0(%ebp)
  10b590:	8b 45 bc             	mov    0xffffffbc(%ebp),%eax
  10b593:	0b 45 c0             	or     0xffffffc0(%ebp),%eax
  10b596:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)
  10b599:	e9 e4 fe ff ff       	jmp    10b482 <vprintfmt+0x8c>
  10b59e:	8b 45 14             	mov    0x14(%ebp),%eax
  10b5a1:	83 c0 04             	add    $0x4,%eax
  10b5a4:	89 45 14             	mov    %eax,0x14(%ebp)
  10b5a7:	8b 45 14             	mov    0x14(%ebp),%eax
  10b5aa:	83 e8 04             	sub    $0x4,%eax
  10b5ad:	8b 10                	mov    (%eax),%edx
  10b5af:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b5b2:	89 44 24 04          	mov    %eax,0x4(%esp)
  10b5b6:	89 14 24             	mov    %edx,(%esp)
  10b5b9:	8b 45 08             	mov    0x8(%ebp),%eax
  10b5bc:	ff d0                	call   *%eax
  10b5be:	e9 78 fe ff ff       	jmp    10b43b <vprintfmt+0x45>
  10b5c3:	8b 45 14             	mov    0x14(%ebp),%eax
  10b5c6:	83 c0 04             	add    $0x4,%eax
  10b5c9:	89 45 14             	mov    %eax,0x14(%ebp)
  10b5cc:	8b 45 14             	mov    0x14(%ebp),%eax
  10b5cf:	83 e8 04             	sub    $0x4,%eax
  10b5d2:	8b 00                	mov    (%eax),%eax
  10b5d4:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
  10b5d7:	83 7d f4 00          	cmpl   $0x0,0xfffffff4(%ebp)
  10b5db:	75 07                	jne    10b5e4 <vprintfmt+0x1ee>
  10b5dd:	c7 45 f4 21 e0 10 00 	movl   $0x10e021,0xfffffff4(%ebp)
  10b5e4:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  10b5e7:	89 44 24 08          	mov    %eax,0x8(%esp)
  10b5eb:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  10b5ee:	89 44 24 04          	mov    %eax,0x4(%esp)
  10b5f2:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
  10b5f5:	89 04 24             	mov    %eax,(%esp)
  10b5f8:	e8 f2 fb ff ff       	call   10b1ef <putstr>
  10b5fd:	e9 39 fe ff ff       	jmp    10b43b <vprintfmt+0x45>
  10b602:	8d 45 14             	lea    0x14(%ebp),%eax
  10b605:	89 44 24 04          	mov    %eax,0x4(%esp)
  10b609:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
  10b60c:	89 04 24             	mov    %eax,(%esp)
  10b60f:	e8 0e fb ff ff       	call   10b122 <getint>
  10b614:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  10b617:	89 55 ec             	mov    %edx,0xffffffec(%ebp)
  10b61a:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  10b61d:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
  10b620:	85 d2                	test   %edx,%edx
  10b622:	79 1a                	jns    10b63e <vprintfmt+0x248>
  10b624:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  10b627:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
  10b62a:	f7 d8                	neg    %eax
  10b62c:	83 d2 00             	adc    $0x0,%edx
  10b62f:	f7 da                	neg    %edx
  10b631:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  10b634:	89 55 ec             	mov    %edx,0xffffffec(%ebp)
  10b637:	c7 45 dc 2d 00 00 00 	movl   $0x2d,0xffffffdc(%ebp)
  10b63e:	c7 44 24 0c 0a 00 00 	movl   $0xa,0xc(%esp)
  10b645:	00 
  10b646:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  10b649:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
  10b64c:	89 44 24 04          	mov    %eax,0x4(%esp)
  10b650:	89 54 24 08          	mov    %edx,0x8(%esp)
  10b654:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
  10b657:	89 04 24             	mov    %eax,(%esp)
  10b65a:	e8 2f fd ff ff       	call   10b38e <putint>
  10b65f:	e9 d7 fd ff ff       	jmp    10b43b <vprintfmt+0x45>
  10b664:	8d 45 14             	lea    0x14(%ebp),%eax
  10b667:	89 44 24 04          	mov    %eax,0x4(%esp)
  10b66b:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
  10b66e:	89 04 24             	mov    %eax,(%esp)
  10b671:	e8 1e fa ff ff       	call   10b094 <getuint>
  10b676:	c7 44 24 0c 0a 00 00 	movl   $0xa,0xc(%esp)
  10b67d:	00 
  10b67e:	89 44 24 04          	mov    %eax,0x4(%esp)
  10b682:	89 54 24 08          	mov    %edx,0x8(%esp)
  10b686:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
  10b689:	89 04 24             	mov    %eax,(%esp)
  10b68c:	e8 fd fc ff ff       	call   10b38e <putint>
  10b691:	e9 a5 fd ff ff       	jmp    10b43b <vprintfmt+0x45>
  10b696:	8d 45 14             	lea    0x14(%ebp),%eax
  10b699:	89 44 24 04          	mov    %eax,0x4(%esp)
  10b69d:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
  10b6a0:	89 04 24             	mov    %eax,(%esp)
  10b6a3:	e8 ec f9 ff ff       	call   10b094 <getuint>
  10b6a8:	c7 44 24 0c 08 00 00 	movl   $0x8,0xc(%esp)
  10b6af:	00 
  10b6b0:	89 44 24 04          	mov    %eax,0x4(%esp)
  10b6b4:	89 54 24 08          	mov    %edx,0x8(%esp)
  10b6b8:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
  10b6bb:	89 04 24             	mov    %eax,(%esp)
  10b6be:	e8 cb fc ff ff       	call   10b38e <putint>
  10b6c3:	e9 73 fd ff ff       	jmp    10b43b <vprintfmt+0x45>
  10b6c8:	8d 45 14             	lea    0x14(%ebp),%eax
  10b6cb:	89 44 24 04          	mov    %eax,0x4(%esp)
  10b6cf:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
  10b6d2:	89 04 24             	mov    %eax,(%esp)
  10b6d5:	e8 ba f9 ff ff       	call   10b094 <getuint>
  10b6da:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
  10b6e1:	00 
  10b6e2:	89 44 24 04          	mov    %eax,0x4(%esp)
  10b6e6:	89 54 24 08          	mov    %edx,0x8(%esp)
  10b6ea:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
  10b6ed:	89 04 24             	mov    %eax,(%esp)
  10b6f0:	e8 99 fc ff ff       	call   10b38e <putint>
  10b6f5:	e9 41 fd ff ff       	jmp    10b43b <vprintfmt+0x45>
  10b6fa:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b6fd:	89 44 24 04          	mov    %eax,0x4(%esp)
  10b701:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  10b708:	8b 45 08             	mov    0x8(%ebp),%eax
  10b70b:	ff d0                	call   *%eax
  10b70d:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b710:	89 44 24 04          	mov    %eax,0x4(%esp)
  10b714:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  10b71b:	8b 45 08             	mov    0x8(%ebp),%eax
  10b71e:	ff d0                	call   *%eax
  10b720:	8b 45 14             	mov    0x14(%ebp),%eax
  10b723:	83 c0 04             	add    $0x4,%eax
  10b726:	89 45 14             	mov    %eax,0x14(%ebp)
  10b729:	8b 45 14             	mov    0x14(%ebp),%eax
  10b72c:	83 e8 04             	sub    $0x4,%eax
  10b72f:	8b 00                	mov    (%eax),%eax
  10b731:	ba 00 00 00 00       	mov    $0x0,%edx
  10b736:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
  10b73d:	00 
  10b73e:	89 44 24 04          	mov    %eax,0x4(%esp)
  10b742:	89 54 24 08          	mov    %edx,0x8(%esp)
  10b746:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
  10b749:	89 04 24             	mov    %eax,(%esp)
  10b74c:	e8 3d fc ff ff       	call   10b38e <putint>
  10b751:	e9 e5 fc ff ff       	jmp    10b43b <vprintfmt+0x45>
  10b756:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b759:	89 44 24 04          	mov    %eax,0x4(%esp)
  10b75d:	8b 55 c4             	mov    0xffffffc4(%ebp),%edx
  10b760:	89 14 24             	mov    %edx,(%esp)
  10b763:	8b 45 08             	mov    0x8(%ebp),%eax
  10b766:	ff d0                	call   *%eax
  10b768:	e9 ce fc ff ff       	jmp    10b43b <vprintfmt+0x45>
  10b76d:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b770:	89 44 24 04          	mov    %eax,0x4(%esp)
  10b774:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  10b77b:	8b 45 08             	mov    0x8(%ebp),%eax
  10b77e:	ff d0                	call   *%eax
  10b780:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  10b784:	eb 04                	jmp    10b78a <vprintfmt+0x394>
  10b786:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  10b78a:	8b 45 10             	mov    0x10(%ebp),%eax
  10b78d:	83 e8 01             	sub    $0x1,%eax
  10b790:	0f b6 00             	movzbl (%eax),%eax
  10b793:	3c 25                	cmp    $0x25,%al
  10b795:	75 ef                	jne    10b786 <vprintfmt+0x390>
  10b797:	e9 9f fc ff ff       	jmp    10b43b <vprintfmt+0x45>
  10b79c:	83 c4 54             	add    $0x54,%esp
  10b79f:	5f                   	pop    %edi
  10b7a0:	5d                   	pop    %ebp
  10b7a1:	c3                   	ret    
  10b7a2:	90                   	nop    
  10b7a3:	90                   	nop    

0010b7a4 <putch>:


static void
putch(int ch, struct printbuf *b)
{
  10b7a4:	55                   	push   %ebp
  10b7a5:	89 e5                	mov    %esp,%ebp
  10b7a7:	83 ec 08             	sub    $0x8,%esp
	b->buf[b->idx++] = ch;
  10b7aa:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b7ad:	8b 08                	mov    (%eax),%ecx
  10b7af:	8b 45 08             	mov    0x8(%ebp),%eax
  10b7b2:	89 c2                	mov    %eax,%edx
  10b7b4:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b7b7:	88 54 08 08          	mov    %dl,0x8(%eax,%ecx,1)
  10b7bb:	8d 51 01             	lea    0x1(%ecx),%edx
  10b7be:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b7c1:	89 10                	mov    %edx,(%eax)
	if (b->idx == CPUTS_MAX-1) {
  10b7c3:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b7c6:	8b 00                	mov    (%eax),%eax
  10b7c8:	3d ff 00 00 00       	cmp    $0xff,%eax
  10b7cd:	75 24                	jne    10b7f3 <putch+0x4f>
		b->buf[b->idx] = 0;
  10b7cf:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b7d2:	8b 10                	mov    (%eax),%edx
  10b7d4:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b7d7:	c6 44 10 08 00       	movb   $0x0,0x8(%eax,%edx,1)
		cputs(b->buf);
  10b7dc:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b7df:	83 c0 08             	add    $0x8,%eax
  10b7e2:	89 04 24             	mov    %eax,(%esp)
  10b7e5:	e8 33 4f ff ff       	call   10071d <cputs>
		b->idx = 0;
  10b7ea:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b7ed:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	}
	b->cnt++;
  10b7f3:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b7f6:	8b 40 04             	mov    0x4(%eax),%eax
  10b7f9:	8d 50 01             	lea    0x1(%eax),%edx
  10b7fc:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b7ff:	89 50 04             	mov    %edx,0x4(%eax)
}
  10b802:	c9                   	leave  
  10b803:	c3                   	ret    

0010b804 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  10b804:	55                   	push   %ebp
  10b805:	89 e5                	mov    %esp,%ebp
  10b807:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  10b80d:	c7 85 f8 fe ff ff 00 	movl   $0x0,0xfffffef8(%ebp)
  10b814:	00 00 00 
	b.cnt = 0;
  10b817:	c7 85 fc fe ff ff 00 	movl   $0x0,0xfffffefc(%ebp)
  10b81e:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  10b821:	ba a4 b7 10 00       	mov    $0x10b7a4,%edx
  10b826:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b829:	89 44 24 0c          	mov    %eax,0xc(%esp)
  10b82d:	8b 45 08             	mov    0x8(%ebp),%eax
  10b830:	89 44 24 08          	mov    %eax,0x8(%esp)
  10b834:	8d 85 f8 fe ff ff    	lea    0xfffffef8(%ebp),%eax
  10b83a:	89 44 24 04          	mov    %eax,0x4(%esp)
  10b83e:	89 14 24             	mov    %edx,(%esp)
  10b841:	e8 b0 fb ff ff       	call   10b3f6 <vprintfmt>

	b.buf[b.idx] = 0;
  10b846:	8b 85 f8 fe ff ff    	mov    0xfffffef8(%ebp),%eax
  10b84c:	c6 84 05 00 ff ff ff 	movb   $0x0,0xffffff00(%ebp,%eax,1)
  10b853:	00 
	cputs(b.buf);
  10b854:	8d 85 f8 fe ff ff    	lea    0xfffffef8(%ebp),%eax
  10b85a:	83 c0 08             	add    $0x8,%eax
  10b85d:	89 04 24             	mov    %eax,(%esp)
  10b860:	e8 b8 4e ff ff       	call   10071d <cputs>

	return b.cnt;
  10b865:	8b 85 fc fe ff ff    	mov    0xfffffefc(%ebp),%eax
}
  10b86b:	c9                   	leave  
  10b86c:	c3                   	ret    

0010b86d <cprintf>:

int
cprintf(const char *fmt, ...)
{
  10b86d:	55                   	push   %ebp
  10b86e:	89 e5                	mov    %esp,%ebp
  10b870:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  10b873:	8d 45 08             	lea    0x8(%ebp),%eax
  10b876:	83 c0 04             	add    $0x4,%eax
  10b879:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
	cnt = vcprintf(fmt, ap);
  10b87c:	8b 55 08             	mov    0x8(%ebp),%edx
  10b87f:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10b882:	89 44 24 04          	mov    %eax,0x4(%esp)
  10b886:	89 14 24             	mov    %edx,(%esp)
  10b889:	e8 76 ff ff ff       	call   10b804 <vcprintf>
  10b88e:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	va_end(ap);

	return cnt;
  10b891:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
}
  10b894:	c9                   	leave  
  10b895:	c3                   	ret    
  10b896:	90                   	nop    
  10b897:	90                   	nop    

0010b898 <sprintputch>:
  10b898:	55                   	push   %ebp
  10b899:	89 e5                	mov    %esp,%ebp
  10b89b:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b89e:	8b 40 08             	mov    0x8(%eax),%eax
  10b8a1:	8d 50 01             	lea    0x1(%eax),%edx
  10b8a4:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b8a7:	89 50 08             	mov    %edx,0x8(%eax)
  10b8aa:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b8ad:	8b 10                	mov    (%eax),%edx
  10b8af:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b8b2:	8b 40 04             	mov    0x4(%eax),%eax
  10b8b5:	39 c2                	cmp    %eax,%edx
  10b8b7:	73 12                	jae    10b8cb <sprintputch+0x33>
  10b8b9:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b8bc:	8b 10                	mov    (%eax),%edx
  10b8be:	8b 45 08             	mov    0x8(%ebp),%eax
  10b8c1:	88 02                	mov    %al,(%edx)
  10b8c3:	83 c2 01             	add    $0x1,%edx
  10b8c6:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b8c9:	89 10                	mov    %edx,(%eax)
  10b8cb:	5d                   	pop    %ebp
  10b8cc:	c3                   	ret    

0010b8cd <vsprintf>:
  10b8cd:	55                   	push   %ebp
  10b8ce:	89 e5                	mov    %esp,%ebp
  10b8d0:	83 ec 28             	sub    $0x28,%esp
  10b8d3:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  10b8d7:	75 24                	jne    10b8fd <vsprintf+0x30>
  10b8d9:	c7 44 24 0c 8c e1 10 	movl   $0x10e18c,0xc(%esp)
  10b8e0:	00 
  10b8e1:	c7 44 24 08 98 e1 10 	movl   $0x10e198,0x8(%esp)
  10b8e8:	00 
  10b8e9:	c7 44 24 04 1a 00 00 	movl   $0x1a,0x4(%esp)
  10b8f0:	00 
  10b8f1:	c7 04 24 ad e1 10 00 	movl   $0x10e1ad,(%esp)
  10b8f8:	e8 3b 50 ff ff       	call   100938 <debug_panic>
  10b8fd:	8b 45 08             	mov    0x8(%ebp),%eax
  10b900:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
  10b903:	c7 45 f8 ff ff ff ff 	movl   $0xffffffff,0xfffffff8(%ebp)
  10b90a:	c7 45 fc 00 00 00 00 	movl   $0x0,0xfffffffc(%ebp)
  10b911:	ba 98 b8 10 00       	mov    $0x10b898,%edx
  10b916:	8b 45 10             	mov    0x10(%ebp),%eax
  10b919:	89 44 24 0c          	mov    %eax,0xc(%esp)
  10b91d:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b920:	89 44 24 08          	mov    %eax,0x8(%esp)
  10b924:	8d 45 f4             	lea    0xfffffff4(%ebp),%eax
  10b927:	89 44 24 04          	mov    %eax,0x4(%esp)
  10b92b:	89 14 24             	mov    %edx,(%esp)
  10b92e:	e8 c3 fa ff ff       	call   10b3f6 <vprintfmt>
  10b933:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  10b936:	c6 00 00             	movb   $0x0,(%eax)
  10b939:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  10b93c:	c9                   	leave  
  10b93d:	c3                   	ret    

0010b93e <sprintf>:
  10b93e:	55                   	push   %ebp
  10b93f:	89 e5                	mov    %esp,%ebp
  10b941:	83 ec 28             	sub    $0x28,%esp
  10b944:	8d 45 0c             	lea    0xc(%ebp),%eax
  10b947:	83 c0 04             	add    $0x4,%eax
  10b94a:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  10b94d:	8b 55 0c             	mov    0xc(%ebp),%edx
  10b950:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10b953:	89 44 24 08          	mov    %eax,0x8(%esp)
  10b957:	89 54 24 04          	mov    %edx,0x4(%esp)
  10b95b:	8b 45 08             	mov    0x8(%ebp),%eax
  10b95e:	89 04 24             	mov    %eax,(%esp)
  10b961:	e8 67 ff ff ff       	call   10b8cd <vsprintf>
  10b966:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  10b969:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  10b96c:	c9                   	leave  
  10b96d:	c3                   	ret    

0010b96e <vsnprintf>:
  10b96e:	55                   	push   %ebp
  10b96f:	89 e5                	mov    %esp,%ebp
  10b971:	83 ec 28             	sub    $0x28,%esp
  10b974:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  10b978:	74 06                	je     10b980 <vsnprintf+0x12>
  10b97a:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  10b97e:	7f 24                	jg     10b9a4 <vsnprintf+0x36>
  10b980:	c7 44 24 0c be e1 10 	movl   $0x10e1be,0xc(%esp)
  10b987:	00 
  10b988:	c7 44 24 08 98 e1 10 	movl   $0x10e198,0x8(%esp)
  10b98f:	00 
  10b990:	c7 44 24 04 36 00 00 	movl   $0x36,0x4(%esp)
  10b997:	00 
  10b998:	c7 04 24 ad e1 10 00 	movl   $0x10e1ad,(%esp)
  10b99f:	e8 94 4f ff ff       	call   100938 <debug_panic>
  10b9a4:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b9a7:	03 45 08             	add    0x8(%ebp),%eax
  10b9aa:	8d 50 ff             	lea    0xffffffff(%eax),%edx
  10b9ad:	8b 45 08             	mov    0x8(%ebp),%eax
  10b9b0:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
  10b9b3:	89 55 f8             	mov    %edx,0xfffffff8(%ebp)
  10b9b6:	c7 45 fc 00 00 00 00 	movl   $0x0,0xfffffffc(%ebp)
  10b9bd:	ba 98 b8 10 00       	mov    $0x10b898,%edx
  10b9c2:	8b 45 14             	mov    0x14(%ebp),%eax
  10b9c5:	89 44 24 0c          	mov    %eax,0xc(%esp)
  10b9c9:	8b 45 10             	mov    0x10(%ebp),%eax
  10b9cc:	89 44 24 08          	mov    %eax,0x8(%esp)
  10b9d0:	8d 45 f4             	lea    0xfffffff4(%ebp),%eax
  10b9d3:	89 44 24 04          	mov    %eax,0x4(%esp)
  10b9d7:	89 14 24             	mov    %edx,(%esp)
  10b9da:	e8 17 fa ff ff       	call   10b3f6 <vprintfmt>
  10b9df:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  10b9e2:	c6 00 00             	movb   $0x0,(%eax)
  10b9e5:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  10b9e8:	c9                   	leave  
  10b9e9:	c3                   	ret    

0010b9ea <snprintf>:
  10b9ea:	55                   	push   %ebp
  10b9eb:	89 e5                	mov    %esp,%ebp
  10b9ed:	83 ec 28             	sub    $0x28,%esp
  10b9f0:	8d 45 10             	lea    0x10(%ebp),%eax
  10b9f3:	83 c0 04             	add    $0x4,%eax
  10b9f6:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  10b9f9:	8b 55 10             	mov    0x10(%ebp),%edx
  10b9fc:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10b9ff:	89 44 24 0c          	mov    %eax,0xc(%esp)
  10ba03:	89 54 24 08          	mov    %edx,0x8(%esp)
  10ba07:	8b 45 0c             	mov    0xc(%ebp),%eax
  10ba0a:	89 44 24 04          	mov    %eax,0x4(%esp)
  10ba0e:	8b 45 08             	mov    0x8(%ebp),%eax
  10ba11:	89 04 24             	mov    %eax,(%esp)
  10ba14:	e8 55 ff ff ff       	call   10b96e <vsnprintf>
  10ba19:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  10ba1c:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  10ba1f:	c9                   	leave  
  10ba20:	c3                   	ret    
  10ba21:	90                   	nop    
  10ba22:	90                   	nop    
  10ba23:	90                   	nop    

0010ba24 <strlen>:
  10ba24:	55                   	push   %ebp
  10ba25:	89 e5                	mov    %esp,%ebp
  10ba27:	83 ec 10             	sub    $0x10,%esp
  10ba2a:	c7 45 fc 00 00 00 00 	movl   $0x0,0xfffffffc(%ebp)
  10ba31:	eb 08                	jmp    10ba3b <strlen+0x17>
  10ba33:	83 45 fc 01          	addl   $0x1,0xfffffffc(%ebp)
  10ba37:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  10ba3b:	8b 45 08             	mov    0x8(%ebp),%eax
  10ba3e:	0f b6 00             	movzbl (%eax),%eax
  10ba41:	84 c0                	test   %al,%al
  10ba43:	75 ee                	jne    10ba33 <strlen+0xf>
  10ba45:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  10ba48:	c9                   	leave  
  10ba49:	c3                   	ret    

0010ba4a <strcpy>:
  10ba4a:	55                   	push   %ebp
  10ba4b:	89 e5                	mov    %esp,%ebp
  10ba4d:	83 ec 10             	sub    $0x10,%esp
  10ba50:	8b 45 08             	mov    0x8(%ebp),%eax
  10ba53:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  10ba56:	8b 45 0c             	mov    0xc(%ebp),%eax
  10ba59:	0f b6 10             	movzbl (%eax),%edx
  10ba5c:	8b 45 08             	mov    0x8(%ebp),%eax
  10ba5f:	88 10                	mov    %dl,(%eax)
  10ba61:	8b 45 08             	mov    0x8(%ebp),%eax
  10ba64:	0f b6 00             	movzbl (%eax),%eax
  10ba67:	84 c0                	test   %al,%al
  10ba69:	0f 95 c0             	setne  %al
  10ba6c:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  10ba70:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
  10ba74:	84 c0                	test   %al,%al
  10ba76:	75 de                	jne    10ba56 <strcpy+0xc>
  10ba78:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  10ba7b:	c9                   	leave  
  10ba7c:	c3                   	ret    

0010ba7d <strncpy>:
  10ba7d:	55                   	push   %ebp
  10ba7e:	89 e5                	mov    %esp,%ebp
  10ba80:	83 ec 10             	sub    $0x10,%esp
  10ba83:	8b 45 08             	mov    0x8(%ebp),%eax
  10ba86:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  10ba89:	c7 45 f8 00 00 00 00 	movl   $0x0,0xfffffff8(%ebp)
  10ba90:	eb 21                	jmp    10bab3 <strncpy+0x36>
  10ba92:	8b 45 0c             	mov    0xc(%ebp),%eax
  10ba95:	0f b6 10             	movzbl (%eax),%edx
  10ba98:	8b 45 08             	mov    0x8(%ebp),%eax
  10ba9b:	88 10                	mov    %dl,(%eax)
  10ba9d:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  10baa1:	8b 45 0c             	mov    0xc(%ebp),%eax
  10baa4:	0f b6 00             	movzbl (%eax),%eax
  10baa7:	84 c0                	test   %al,%al
  10baa9:	74 04                	je     10baaf <strncpy+0x32>
  10baab:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
  10baaf:	83 45 f8 01          	addl   $0x1,0xfffffff8(%ebp)
  10bab3:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10bab6:	3b 45 10             	cmp    0x10(%ebp),%eax
  10bab9:	72 d7                	jb     10ba92 <strncpy+0x15>
  10babb:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  10babe:	c9                   	leave  
  10babf:	c3                   	ret    

0010bac0 <strlcpy>:
  10bac0:	55                   	push   %ebp
  10bac1:	89 e5                	mov    %esp,%ebp
  10bac3:	83 ec 10             	sub    $0x10,%esp
  10bac6:	8b 45 08             	mov    0x8(%ebp),%eax
  10bac9:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  10bacc:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  10bad0:	74 2f                	je     10bb01 <strlcpy+0x41>
  10bad2:	eb 13                	jmp    10bae7 <strlcpy+0x27>
  10bad4:	8b 45 0c             	mov    0xc(%ebp),%eax
  10bad7:	0f b6 10             	movzbl (%eax),%edx
  10bada:	8b 45 08             	mov    0x8(%ebp),%eax
  10badd:	88 10                	mov    %dl,(%eax)
  10badf:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  10bae3:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
  10bae7:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  10baeb:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  10baef:	74 0a                	je     10bafb <strlcpy+0x3b>
  10baf1:	8b 45 0c             	mov    0xc(%ebp),%eax
  10baf4:	0f b6 00             	movzbl (%eax),%eax
  10baf7:	84 c0                	test   %al,%al
  10baf9:	75 d9                	jne    10bad4 <strlcpy+0x14>
  10bafb:	8b 45 08             	mov    0x8(%ebp),%eax
  10bafe:	c6 00 00             	movb   $0x0,(%eax)
  10bb01:	8b 55 08             	mov    0x8(%ebp),%edx
  10bb04:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  10bb07:	89 d1                	mov    %edx,%ecx
  10bb09:	29 c1                	sub    %eax,%ecx
  10bb0b:	89 c8                	mov    %ecx,%eax
  10bb0d:	c9                   	leave  
  10bb0e:	c3                   	ret    

0010bb0f <strcmp>:
  10bb0f:	55                   	push   %ebp
  10bb10:	89 e5                	mov    %esp,%ebp
  10bb12:	eb 08                	jmp    10bb1c <strcmp+0xd>
  10bb14:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  10bb18:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
  10bb1c:	8b 45 08             	mov    0x8(%ebp),%eax
  10bb1f:	0f b6 00             	movzbl (%eax),%eax
  10bb22:	84 c0                	test   %al,%al
  10bb24:	74 10                	je     10bb36 <strcmp+0x27>
  10bb26:	8b 45 08             	mov    0x8(%ebp),%eax
  10bb29:	0f b6 10             	movzbl (%eax),%edx
  10bb2c:	8b 45 0c             	mov    0xc(%ebp),%eax
  10bb2f:	0f b6 00             	movzbl (%eax),%eax
  10bb32:	38 c2                	cmp    %al,%dl
  10bb34:	74 de                	je     10bb14 <strcmp+0x5>
  10bb36:	8b 45 08             	mov    0x8(%ebp),%eax
  10bb39:	0f b6 00             	movzbl (%eax),%eax
  10bb3c:	0f b6 d0             	movzbl %al,%edx
  10bb3f:	8b 45 0c             	mov    0xc(%ebp),%eax
  10bb42:	0f b6 00             	movzbl (%eax),%eax
  10bb45:	0f b6 c0             	movzbl %al,%eax
  10bb48:	89 d1                	mov    %edx,%ecx
  10bb4a:	29 c1                	sub    %eax,%ecx
  10bb4c:	89 c8                	mov    %ecx,%eax
  10bb4e:	5d                   	pop    %ebp
  10bb4f:	c3                   	ret    

0010bb50 <strncmp>:
  10bb50:	55                   	push   %ebp
  10bb51:	89 e5                	mov    %esp,%ebp
  10bb53:	83 ec 04             	sub    $0x4,%esp
  10bb56:	eb 0c                	jmp    10bb64 <strncmp+0x14>
  10bb58:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  10bb5c:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  10bb60:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
  10bb64:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  10bb68:	74 1a                	je     10bb84 <strncmp+0x34>
  10bb6a:	8b 45 08             	mov    0x8(%ebp),%eax
  10bb6d:	0f b6 00             	movzbl (%eax),%eax
  10bb70:	84 c0                	test   %al,%al
  10bb72:	74 10                	je     10bb84 <strncmp+0x34>
  10bb74:	8b 45 08             	mov    0x8(%ebp),%eax
  10bb77:	0f b6 10             	movzbl (%eax),%edx
  10bb7a:	8b 45 0c             	mov    0xc(%ebp),%eax
  10bb7d:	0f b6 00             	movzbl (%eax),%eax
  10bb80:	38 c2                	cmp    %al,%dl
  10bb82:	74 d4                	je     10bb58 <strncmp+0x8>
  10bb84:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  10bb88:	75 09                	jne    10bb93 <strncmp+0x43>
  10bb8a:	c7 45 fc 00 00 00 00 	movl   $0x0,0xfffffffc(%ebp)
  10bb91:	eb 19                	jmp    10bbac <strncmp+0x5c>
  10bb93:	8b 45 08             	mov    0x8(%ebp),%eax
  10bb96:	0f b6 00             	movzbl (%eax),%eax
  10bb99:	0f b6 d0             	movzbl %al,%edx
  10bb9c:	8b 45 0c             	mov    0xc(%ebp),%eax
  10bb9f:	0f b6 00             	movzbl (%eax),%eax
  10bba2:	0f b6 c0             	movzbl %al,%eax
  10bba5:	89 d1                	mov    %edx,%ecx
  10bba7:	29 c1                	sub    %eax,%ecx
  10bba9:	89 4d fc             	mov    %ecx,0xfffffffc(%ebp)
  10bbac:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  10bbaf:	c9                   	leave  
  10bbb0:	c3                   	ret    

0010bbb1 <strchr>:
  10bbb1:	55                   	push   %ebp
  10bbb2:	89 e5                	mov    %esp,%ebp
  10bbb4:	83 ec 08             	sub    $0x8,%esp
  10bbb7:	8b 45 0c             	mov    0xc(%ebp),%eax
  10bbba:	88 45 fc             	mov    %al,0xfffffffc(%ebp)
  10bbbd:	eb 1c                	jmp    10bbdb <strchr+0x2a>
  10bbbf:	8b 45 08             	mov    0x8(%ebp),%eax
  10bbc2:	0f b6 00             	movzbl (%eax),%eax
  10bbc5:	84 c0                	test   %al,%al
  10bbc7:	0f 94 c0             	sete   %al
  10bbca:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  10bbce:	84 c0                	test   %al,%al
  10bbd0:	74 09                	je     10bbdb <strchr+0x2a>
  10bbd2:	c7 45 f8 00 00 00 00 	movl   $0x0,0xfffffff8(%ebp)
  10bbd9:	eb 11                	jmp    10bbec <strchr+0x3b>
  10bbdb:	8b 45 08             	mov    0x8(%ebp),%eax
  10bbde:	0f b6 00             	movzbl (%eax),%eax
  10bbe1:	3a 45 fc             	cmp    0xfffffffc(%ebp),%al
  10bbe4:	75 d9                	jne    10bbbf <strchr+0xe>
  10bbe6:	8b 45 08             	mov    0x8(%ebp),%eax
  10bbe9:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  10bbec:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10bbef:	c9                   	leave  
  10bbf0:	c3                   	ret    

0010bbf1 <memset>:
  10bbf1:	55                   	push   %ebp
  10bbf2:	89 e5                	mov    %esp,%ebp
  10bbf4:	57                   	push   %edi
  10bbf5:	83 ec 14             	sub    $0x14,%esp
  10bbf8:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  10bbfc:	75 08                	jne    10bc06 <memset+0x15>
  10bbfe:	8b 45 08             	mov    0x8(%ebp),%eax
  10bc01:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  10bc04:	eb 5b                	jmp    10bc61 <memset+0x70>
  10bc06:	8b 45 08             	mov    0x8(%ebp),%eax
  10bc09:	83 e0 03             	and    $0x3,%eax
  10bc0c:	85 c0                	test   %eax,%eax
  10bc0e:	75 3f                	jne    10bc4f <memset+0x5e>
  10bc10:	8b 45 10             	mov    0x10(%ebp),%eax
  10bc13:	83 e0 03             	and    $0x3,%eax
  10bc16:	85 c0                	test   %eax,%eax
  10bc18:	75 35                	jne    10bc4f <memset+0x5e>
  10bc1a:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
  10bc21:	8b 45 0c             	mov    0xc(%ebp),%eax
  10bc24:	89 c2                	mov    %eax,%edx
  10bc26:	c1 e2 18             	shl    $0x18,%edx
  10bc29:	8b 45 0c             	mov    0xc(%ebp),%eax
  10bc2c:	c1 e0 10             	shl    $0x10,%eax
  10bc2f:	09 c2                	or     %eax,%edx
  10bc31:	8b 45 0c             	mov    0xc(%ebp),%eax
  10bc34:	c1 e0 08             	shl    $0x8,%eax
  10bc37:	09 d0                	or     %edx,%eax
  10bc39:	09 45 0c             	or     %eax,0xc(%ebp)
  10bc3c:	8b 45 10             	mov    0x10(%ebp),%eax
  10bc3f:	89 c1                	mov    %eax,%ecx
  10bc41:	c1 e9 02             	shr    $0x2,%ecx
  10bc44:	8b 7d 08             	mov    0x8(%ebp),%edi
  10bc47:	8b 45 0c             	mov    0xc(%ebp),%eax
  10bc4a:	fc                   	cld    
  10bc4b:	f3 ab                	rep stos %eax,%es:(%edi)
  10bc4d:	eb 0c                	jmp    10bc5b <memset+0x6a>
  10bc4f:	8b 7d 08             	mov    0x8(%ebp),%edi
  10bc52:	8b 45 0c             	mov    0xc(%ebp),%eax
  10bc55:	8b 4d 10             	mov    0x10(%ebp),%ecx
  10bc58:	fc                   	cld    
  10bc59:	f3 aa                	rep stos %al,%es:(%edi)
  10bc5b:	8b 45 08             	mov    0x8(%ebp),%eax
  10bc5e:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  10bc61:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  10bc64:	83 c4 14             	add    $0x14,%esp
  10bc67:	5f                   	pop    %edi
  10bc68:	5d                   	pop    %ebp
  10bc69:	c3                   	ret    

0010bc6a <memmove>:
  10bc6a:	55                   	push   %ebp
  10bc6b:	89 e5                	mov    %esp,%ebp
  10bc6d:	57                   	push   %edi
  10bc6e:	56                   	push   %esi
  10bc6f:	83 ec 10             	sub    $0x10,%esp
  10bc72:	8b 45 0c             	mov    0xc(%ebp),%eax
  10bc75:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
  10bc78:	8b 45 08             	mov    0x8(%ebp),%eax
  10bc7b:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
  10bc7e:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  10bc81:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  10bc84:	73 63                	jae    10bce9 <memmove+0x7f>
  10bc86:	8b 45 10             	mov    0x10(%ebp),%eax
  10bc89:	03 45 f0             	add    0xfffffff0(%ebp),%eax
  10bc8c:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  10bc8f:	76 58                	jbe    10bce9 <memmove+0x7f>
  10bc91:	8b 45 10             	mov    0x10(%ebp),%eax
  10bc94:	01 45 f0             	add    %eax,0xfffffff0(%ebp)
  10bc97:	8b 45 10             	mov    0x10(%ebp),%eax
  10bc9a:	01 45 f4             	add    %eax,0xfffffff4(%ebp)
  10bc9d:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  10bca0:	83 e0 03             	and    $0x3,%eax
  10bca3:	85 c0                	test   %eax,%eax
  10bca5:	75 2d                	jne    10bcd4 <memmove+0x6a>
  10bca7:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  10bcaa:	83 e0 03             	and    $0x3,%eax
  10bcad:	85 c0                	test   %eax,%eax
  10bcaf:	75 23                	jne    10bcd4 <memmove+0x6a>
  10bcb1:	8b 45 10             	mov    0x10(%ebp),%eax
  10bcb4:	83 e0 03             	and    $0x3,%eax
  10bcb7:	85 c0                	test   %eax,%eax
  10bcb9:	75 19                	jne    10bcd4 <memmove+0x6a>
  10bcbb:	8b 7d f4             	mov    0xfffffff4(%ebp),%edi
  10bcbe:	83 ef 04             	sub    $0x4,%edi
  10bcc1:	8b 75 f0             	mov    0xfffffff0(%ebp),%esi
  10bcc4:	83 ee 04             	sub    $0x4,%esi
  10bcc7:	8b 45 10             	mov    0x10(%ebp),%eax
  10bcca:	89 c1                	mov    %eax,%ecx
  10bccc:	c1 e9 02             	shr    $0x2,%ecx
  10bccf:	fd                   	std    
  10bcd0:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  10bcd2:	eb 12                	jmp    10bce6 <memmove+0x7c>
  10bcd4:	8b 7d f4             	mov    0xfffffff4(%ebp),%edi
  10bcd7:	83 ef 01             	sub    $0x1,%edi
  10bcda:	8b 75 f0             	mov    0xfffffff0(%ebp),%esi
  10bcdd:	83 ee 01             	sub    $0x1,%esi
  10bce0:	8b 4d 10             	mov    0x10(%ebp),%ecx
  10bce3:	fd                   	std    
  10bce4:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
  10bce6:	fc                   	cld    
  10bce7:	eb 3d                	jmp    10bd26 <memmove+0xbc>
  10bce9:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  10bcec:	83 e0 03             	and    $0x3,%eax
  10bcef:	85 c0                	test   %eax,%eax
  10bcf1:	75 27                	jne    10bd1a <memmove+0xb0>
  10bcf3:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  10bcf6:	83 e0 03             	and    $0x3,%eax
  10bcf9:	85 c0                	test   %eax,%eax
  10bcfb:	75 1d                	jne    10bd1a <memmove+0xb0>
  10bcfd:	8b 45 10             	mov    0x10(%ebp),%eax
  10bd00:	83 e0 03             	and    $0x3,%eax
  10bd03:	85 c0                	test   %eax,%eax
  10bd05:	75 13                	jne    10bd1a <memmove+0xb0>
  10bd07:	8b 45 10             	mov    0x10(%ebp),%eax
  10bd0a:	89 c1                	mov    %eax,%ecx
  10bd0c:	c1 e9 02             	shr    $0x2,%ecx
  10bd0f:	8b 7d f4             	mov    0xfffffff4(%ebp),%edi
  10bd12:	8b 75 f0             	mov    0xfffffff0(%ebp),%esi
  10bd15:	fc                   	cld    
  10bd16:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  10bd18:	eb 0c                	jmp    10bd26 <memmove+0xbc>
  10bd1a:	8b 7d f4             	mov    0xfffffff4(%ebp),%edi
  10bd1d:	8b 75 f0             	mov    0xfffffff0(%ebp),%esi
  10bd20:	8b 4d 10             	mov    0x10(%ebp),%ecx
  10bd23:	fc                   	cld    
  10bd24:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
  10bd26:	8b 45 08             	mov    0x8(%ebp),%eax
  10bd29:	83 c4 10             	add    $0x10,%esp
  10bd2c:	5e                   	pop    %esi
  10bd2d:	5f                   	pop    %edi
  10bd2e:	5d                   	pop    %ebp
  10bd2f:	c3                   	ret    

0010bd30 <memcpy>:
  10bd30:	55                   	push   %ebp
  10bd31:	89 e5                	mov    %esp,%ebp
  10bd33:	83 ec 0c             	sub    $0xc,%esp
  10bd36:	8b 45 10             	mov    0x10(%ebp),%eax
  10bd39:	89 44 24 08          	mov    %eax,0x8(%esp)
  10bd3d:	8b 45 0c             	mov    0xc(%ebp),%eax
  10bd40:	89 44 24 04          	mov    %eax,0x4(%esp)
  10bd44:	8b 45 08             	mov    0x8(%ebp),%eax
  10bd47:	89 04 24             	mov    %eax,(%esp)
  10bd4a:	e8 1b ff ff ff       	call   10bc6a <memmove>
  10bd4f:	c9                   	leave  
  10bd50:	c3                   	ret    

0010bd51 <memcmp>:
  10bd51:	55                   	push   %ebp
  10bd52:	89 e5                	mov    %esp,%ebp
  10bd54:	83 ec 14             	sub    $0x14,%esp
  10bd57:	8b 45 08             	mov    0x8(%ebp),%eax
  10bd5a:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  10bd5d:	8b 45 0c             	mov    0xc(%ebp),%eax
  10bd60:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  10bd63:	eb 33                	jmp    10bd98 <memcmp+0x47>
  10bd65:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10bd68:	0f b6 10             	movzbl (%eax),%edx
  10bd6b:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  10bd6e:	0f b6 00             	movzbl (%eax),%eax
  10bd71:	38 c2                	cmp    %al,%dl
  10bd73:	74 1b                	je     10bd90 <memcmp+0x3f>
  10bd75:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10bd78:	0f b6 00             	movzbl (%eax),%eax
  10bd7b:	0f b6 d0             	movzbl %al,%edx
  10bd7e:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  10bd81:	0f b6 00             	movzbl (%eax),%eax
  10bd84:	0f b6 c0             	movzbl %al,%eax
  10bd87:	89 d1                	mov    %edx,%ecx
  10bd89:	29 c1                	sub    %eax,%ecx
  10bd8b:	89 4d ec             	mov    %ecx,0xffffffec(%ebp)
  10bd8e:	eb 19                	jmp    10bda9 <memcmp+0x58>
  10bd90:	83 45 f8 01          	addl   $0x1,0xfffffff8(%ebp)
  10bd94:	83 45 fc 01          	addl   $0x1,0xfffffffc(%ebp)
  10bd98:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  10bd9c:	83 7d 10 ff          	cmpl   $0xffffffff,0x10(%ebp)
  10bda0:	75 c3                	jne    10bd65 <memcmp+0x14>
  10bda2:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  10bda9:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  10bdac:	c9                   	leave  
  10bdad:	c3                   	ret    

0010bdae <memchr>:
  10bdae:	55                   	push   %ebp
  10bdaf:	89 e5                	mov    %esp,%ebp
  10bdb1:	83 ec 14             	sub    $0x14,%esp
  10bdb4:	8b 45 08             	mov    0x8(%ebp),%eax
  10bdb7:	8b 55 10             	mov    0x10(%ebp),%edx
  10bdba:	01 d0                	add    %edx,%eax
  10bdbc:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  10bdbf:	eb 19                	jmp    10bdda <memchr+0x2c>
  10bdc1:	8b 45 08             	mov    0x8(%ebp),%eax
  10bdc4:	0f b6 10             	movzbl (%eax),%edx
  10bdc7:	8b 45 0c             	mov    0xc(%ebp),%eax
  10bdca:	38 c2                	cmp    %al,%dl
  10bdcc:	75 08                	jne    10bdd6 <memchr+0x28>
  10bdce:	8b 45 08             	mov    0x8(%ebp),%eax
  10bdd1:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  10bdd4:	eb 13                	jmp    10bde9 <memchr+0x3b>
  10bdd6:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  10bdda:	8b 45 08             	mov    0x8(%ebp),%eax
  10bddd:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  10bde0:	72 df                	jb     10bdc1 <memchr+0x13>
  10bde2:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  10bde9:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  10bdec:	c9                   	leave  
  10bded:	c3                   	ret    
  10bdee:	90                   	nop    
  10bdef:	90                   	nop    

0010bdf0 <__udivdi3>:
  10bdf0:	55                   	push   %ebp
  10bdf1:	89 e5                	mov    %esp,%ebp
  10bdf3:	57                   	push   %edi
  10bdf4:	56                   	push   %esi
  10bdf5:	83 ec 1c             	sub    $0x1c,%esp
  10bdf8:	8b 45 10             	mov    0x10(%ebp),%eax
  10bdfb:	8b 55 14             	mov    0x14(%ebp),%edx
  10bdfe:	8b 7d 0c             	mov    0xc(%ebp),%edi
  10be01:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
  10be04:	89 c1                	mov    %eax,%ecx
  10be06:	8b 45 08             	mov    0x8(%ebp),%eax
  10be09:	85 d2                	test   %edx,%edx
  10be0b:	89 d6                	mov    %edx,%esi
  10be0d:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  10be10:	75 1e                	jne    10be30 <__udivdi3+0x40>
  10be12:	39 f9                	cmp    %edi,%ecx
  10be14:	0f 86 8d 00 00 00    	jbe    10bea7 <__udivdi3+0xb7>
  10be1a:	89 fa                	mov    %edi,%edx
  10be1c:	f7 f1                	div    %ecx
  10be1e:	89 c1                	mov    %eax,%ecx
  10be20:	89 c8                	mov    %ecx,%eax
  10be22:	89 f2                	mov    %esi,%edx
  10be24:	83 c4 1c             	add    $0x1c,%esp
  10be27:	5e                   	pop    %esi
  10be28:	5f                   	pop    %edi
  10be29:	5d                   	pop    %ebp
  10be2a:	c3                   	ret    
  10be2b:	90                   	nop    
  10be2c:	8d 74 26 00          	lea    0x0(%esi),%esi
  10be30:	39 fa                	cmp    %edi,%edx
  10be32:	0f 87 98 00 00 00    	ja     10bed0 <__udivdi3+0xe0>
  10be38:	0f bd c2             	bsr    %edx,%eax
  10be3b:	83 f0 1f             	xor    $0x1f,%eax
  10be3e:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
  10be41:	74 7f                	je     10bec2 <__udivdi3+0xd2>
  10be43:	b8 20 00 00 00       	mov    $0x20,%eax
  10be48:	8b 55 f0             	mov    0xfffffff0(%ebp),%edx
  10be4b:	2b 45 e4             	sub    0xffffffe4(%ebp),%eax
  10be4e:	89 c1                	mov    %eax,%ecx
  10be50:	d3 ea                	shr    %cl,%edx
  10be52:	0f b6 4d e4          	movzbl 0xffffffe4(%ebp),%ecx
  10be56:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  10be59:	89 f0                	mov    %esi,%eax
  10be5b:	d3 e0                	shl    %cl,%eax
  10be5d:	09 c2                	or     %eax,%edx
  10be5f:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  10be62:	89 55 e0             	mov    %edx,0xffffffe0(%ebp)
  10be65:	89 fa                	mov    %edi,%edx
  10be67:	d3 e0                	shl    %cl,%eax
  10be69:	0f b6 4d ec          	movzbl 0xffffffec(%ebp),%ecx
  10be6d:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
  10be70:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  10be73:	d3 e8                	shr    %cl,%eax
  10be75:	0f b6 4d e4          	movzbl 0xffffffe4(%ebp),%ecx
  10be79:	d3 e2                	shl    %cl,%edx
  10be7b:	0f b6 4d ec          	movzbl 0xffffffec(%ebp),%ecx
  10be7f:	09 d0                	or     %edx,%eax
  10be81:	d3 ef                	shr    %cl,%edi
  10be83:	89 fa                	mov    %edi,%edx
  10be85:	f7 75 e0             	divl   0xffffffe0(%ebp)
  10be88:	89 d1                	mov    %edx,%ecx
  10be8a:	89 c7                	mov    %eax,%edi
  10be8c:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  10be8f:	f7 e7                	mul    %edi
  10be91:	39 d1                	cmp    %edx,%ecx
  10be93:	89 c6                	mov    %eax,%esi
  10be95:	89 55 dc             	mov    %edx,0xffffffdc(%ebp)
  10be98:	72 6f                	jb     10bf09 <__udivdi3+0x119>
  10be9a:	39 ca                	cmp    %ecx,%edx
  10be9c:	74 5e                	je     10befc <__udivdi3+0x10c>
  10be9e:	89 f9                	mov    %edi,%ecx
  10bea0:	31 f6                	xor    %esi,%esi
  10bea2:	e9 79 ff ff ff       	jmp    10be20 <__udivdi3+0x30>
  10bea7:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  10beaa:	85 c0                	test   %eax,%eax
  10beac:	74 32                	je     10bee0 <__udivdi3+0xf0>
  10beae:	89 f2                	mov    %esi,%edx
  10beb0:	89 f8                	mov    %edi,%eax
  10beb2:	f7 f1                	div    %ecx
  10beb4:	89 c6                	mov    %eax,%esi
  10beb6:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  10beb9:	f7 f1                	div    %ecx
  10bebb:	89 c1                	mov    %eax,%ecx
  10bebd:	e9 5e ff ff ff       	jmp    10be20 <__udivdi3+0x30>
  10bec2:	39 d7                	cmp    %edx,%edi
  10bec4:	77 2a                	ja     10bef0 <__udivdi3+0x100>
  10bec6:	8b 55 f0             	mov    0xfffffff0(%ebp),%edx
  10bec9:	39 55 e8             	cmp    %edx,0xffffffe8(%ebp)
  10becc:	73 22                	jae    10bef0 <__udivdi3+0x100>
  10bece:	66 90                	xchg   %ax,%ax
  10bed0:	31 c9                	xor    %ecx,%ecx
  10bed2:	31 f6                	xor    %esi,%esi
  10bed4:	e9 47 ff ff ff       	jmp    10be20 <__udivdi3+0x30>
  10bed9:	8d b4 26 00 00 00 00 	lea    0x0(%esi),%esi
  10bee0:	b8 01 00 00 00       	mov    $0x1,%eax
  10bee5:	31 d2                	xor    %edx,%edx
  10bee7:	f7 75 f0             	divl   0xfffffff0(%ebp)
  10beea:	89 c1                	mov    %eax,%ecx
  10beec:	eb c0                	jmp    10beae <__udivdi3+0xbe>
  10beee:	66 90                	xchg   %ax,%ax
  10bef0:	b9 01 00 00 00       	mov    $0x1,%ecx
  10bef5:	31 f6                	xor    %esi,%esi
  10bef7:	e9 24 ff ff ff       	jmp    10be20 <__udivdi3+0x30>
  10befc:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  10beff:	0f b6 4d e4          	movzbl 0xffffffe4(%ebp),%ecx
  10bf03:	d3 e0                	shl    %cl,%eax
  10bf05:	39 c6                	cmp    %eax,%esi
  10bf07:	76 95                	jbe    10be9e <__udivdi3+0xae>
  10bf09:	8d 4f ff             	lea    0xffffffff(%edi),%ecx
  10bf0c:	31 f6                	xor    %esi,%esi
  10bf0e:	e9 0d ff ff ff       	jmp    10be20 <__udivdi3+0x30>
  10bf13:	90                   	nop    
  10bf14:	90                   	nop    
  10bf15:	90                   	nop    
  10bf16:	90                   	nop    
  10bf17:	90                   	nop    
  10bf18:	90                   	nop    
  10bf19:	90                   	nop    
  10bf1a:	90                   	nop    
  10bf1b:	90                   	nop    
  10bf1c:	90                   	nop    
  10bf1d:	90                   	nop    
  10bf1e:	90                   	nop    
  10bf1f:	90                   	nop    

0010bf20 <__umoddi3>:
  10bf20:	55                   	push   %ebp
  10bf21:	89 e5                	mov    %esp,%ebp
  10bf23:	57                   	push   %edi
  10bf24:	56                   	push   %esi
  10bf25:	83 ec 30             	sub    $0x30,%esp
  10bf28:	8b 55 14             	mov    0x14(%ebp),%edx
  10bf2b:	8b 45 10             	mov    0x10(%ebp),%eax
  10bf2e:	8b 75 08             	mov    0x8(%ebp),%esi
  10bf31:	8b 7d 0c             	mov    0xc(%ebp),%edi
  10bf34:	85 d2                	test   %edx,%edx
  10bf36:	c7 45 d0 00 00 00 00 	movl   $0x0,0xffffffd0(%ebp)
  10bf3d:	89 c1                	mov    %eax,%ecx
  10bf3f:	c7 45 d4 00 00 00 00 	movl   $0x0,0xffffffd4(%ebp)
  10bf46:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  10bf49:	89 55 e8             	mov    %edx,0xffffffe8(%ebp)
  10bf4c:	89 75 f0             	mov    %esi,0xfffffff0(%ebp)
  10bf4f:	89 7d e0             	mov    %edi,0xffffffe0(%ebp)
  10bf52:	75 1c                	jne    10bf70 <__umoddi3+0x50>
  10bf54:	39 f8                	cmp    %edi,%eax
  10bf56:	89 fa                	mov    %edi,%edx
  10bf58:	0f 86 d4 00 00 00    	jbe    10c032 <__umoddi3+0x112>
  10bf5e:	89 f0                	mov    %esi,%eax
  10bf60:	f7 f1                	div    %ecx
  10bf62:	89 55 d0             	mov    %edx,0xffffffd0(%ebp)
  10bf65:	c7 45 d4 00 00 00 00 	movl   $0x0,0xffffffd4(%ebp)
  10bf6c:	eb 12                	jmp    10bf80 <__umoddi3+0x60>
  10bf6e:	66 90                	xchg   %ax,%ax
  10bf70:	8b 4d e0             	mov    0xffffffe0(%ebp),%ecx
  10bf73:	39 4d e8             	cmp    %ecx,0xffffffe8(%ebp)
  10bf76:	76 18                	jbe    10bf90 <__umoddi3+0x70>
  10bf78:	89 75 d0             	mov    %esi,0xffffffd0(%ebp)
  10bf7b:	89 7d d4             	mov    %edi,0xffffffd4(%ebp)
  10bf7e:	66 90                	xchg   %ax,%ax
  10bf80:	8b 45 d0             	mov    0xffffffd0(%ebp),%eax
  10bf83:	8b 55 d4             	mov    0xffffffd4(%ebp),%edx
  10bf86:	83 c4 30             	add    $0x30,%esp
  10bf89:	5e                   	pop    %esi
  10bf8a:	5f                   	pop    %edi
  10bf8b:	5d                   	pop    %ebp
  10bf8c:	c3                   	ret    
  10bf8d:	8d 76 00             	lea    0x0(%esi),%esi
  10bf90:	0f bd 45 e8          	bsr    0xffffffe8(%ebp),%eax
  10bf94:	83 f0 1f             	xor    $0x1f,%eax
  10bf97:	89 45 dc             	mov    %eax,0xffffffdc(%ebp)
  10bf9a:	0f 84 c0 00 00 00    	je     10c060 <__umoddi3+0x140>
  10bfa0:	b8 20 00 00 00       	mov    $0x20,%eax
  10bfa5:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
  10bfa8:	2b 45 dc             	sub    0xffffffdc(%ebp),%eax
  10bfab:	8b 7d ec             	mov    0xffffffec(%ebp),%edi
  10bfae:	8b 75 f0             	mov    0xfffffff0(%ebp),%esi
  10bfb1:	89 c1                	mov    %eax,%ecx
  10bfb3:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
  10bfb6:	d3 ea                	shr    %cl,%edx
  10bfb8:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  10bfbb:	0f b6 4d dc          	movzbl 0xffffffdc(%ebp),%ecx
  10bfbf:	d3 e0                	shl    %cl,%eax
  10bfc1:	09 c2                	or     %eax,%edx
  10bfc3:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  10bfc6:	d3 e7                	shl    %cl,%edi
  10bfc8:	0f b6 4d e4          	movzbl 0xffffffe4(%ebp),%ecx
  10bfcc:	89 55 f4             	mov    %edx,0xfffffff4(%ebp)
  10bfcf:	8b 55 e0             	mov    0xffffffe0(%ebp),%edx
  10bfd2:	d3 e8                	shr    %cl,%eax
  10bfd4:	0f b6 4d dc          	movzbl 0xffffffdc(%ebp),%ecx
  10bfd8:	d3 e2                	shl    %cl,%edx
  10bfda:	09 d0                	or     %edx,%eax
  10bfdc:	8b 55 e0             	mov    0xffffffe0(%ebp),%edx
  10bfdf:	d3 e6                	shl    %cl,%esi
  10bfe1:	0f b6 4d e4          	movzbl 0xffffffe4(%ebp),%ecx
  10bfe5:	d3 ea                	shr    %cl,%edx
  10bfe7:	f7 75 f4             	divl   0xfffffff4(%ebp)
  10bfea:	89 55 cc             	mov    %edx,0xffffffcc(%ebp)
  10bfed:	f7 e7                	mul    %edi
  10bfef:	39 55 cc             	cmp    %edx,0xffffffcc(%ebp)
  10bff2:	0f 82 a5 00 00 00    	jb     10c09d <__umoddi3+0x17d>
  10bff8:	3b 55 cc             	cmp    0xffffffcc(%ebp),%edx
  10bffb:	0f 84 94 00 00 00    	je     10c095 <__umoddi3+0x175>
  10c001:	8b 4d cc             	mov    0xffffffcc(%ebp),%ecx
  10c004:	29 c6                	sub    %eax,%esi
  10c006:	19 d1                	sbb    %edx,%ecx
  10c008:	89 4d cc             	mov    %ecx,0xffffffcc(%ebp)
  10c00b:	0f b6 4d dc          	movzbl 0xffffffdc(%ebp),%ecx
  10c00f:	89 f2                	mov    %esi,%edx
  10c011:	8b 45 cc             	mov    0xffffffcc(%ebp),%eax
  10c014:	d3 ea                	shr    %cl,%edx
  10c016:	0f b6 4d e4          	movzbl 0xffffffe4(%ebp),%ecx
  10c01a:	d3 e0                	shl    %cl,%eax
  10c01c:	0f b6 4d dc          	movzbl 0xffffffdc(%ebp),%ecx
  10c020:	09 c2                	or     %eax,%edx
  10c022:	8b 45 cc             	mov    0xffffffcc(%ebp),%eax
  10c025:	89 55 d0             	mov    %edx,0xffffffd0(%ebp)
  10c028:	d3 e8                	shr    %cl,%eax
  10c02a:	89 45 d4             	mov    %eax,0xffffffd4(%ebp)
  10c02d:	e9 4e ff ff ff       	jmp    10bf80 <__umoddi3+0x60>
  10c032:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  10c035:	85 c0                	test   %eax,%eax
  10c037:	74 17                	je     10c050 <__umoddi3+0x130>
  10c039:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  10c03c:	8b 55 e8             	mov    0xffffffe8(%ebp),%edx
  10c03f:	f7 f1                	div    %ecx
  10c041:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  10c044:	f7 f1                	div    %ecx
  10c046:	e9 17 ff ff ff       	jmp    10bf62 <__umoddi3+0x42>
  10c04b:	90                   	nop    
  10c04c:	8d 74 26 00          	lea    0x0(%esi),%esi
  10c050:	b8 01 00 00 00       	mov    $0x1,%eax
  10c055:	31 d2                	xor    %edx,%edx
  10c057:	f7 75 ec             	divl   0xffffffec(%ebp)
  10c05a:	89 c1                	mov    %eax,%ecx
  10c05c:	eb db                	jmp    10c039 <__umoddi3+0x119>
  10c05e:	66 90                	xchg   %ax,%ax
  10c060:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  10c063:	39 45 e0             	cmp    %eax,0xffffffe0(%ebp)
  10c066:	77 19                	ja     10c081 <__umoddi3+0x161>
  10c068:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
  10c06b:	39 55 f0             	cmp    %edx,0xfffffff0(%ebp)
  10c06e:	73 11                	jae    10c081 <__umoddi3+0x161>
  10c070:	8b 55 f0             	mov    0xfffffff0(%ebp),%edx
  10c073:	8b 4d e0             	mov    0xffffffe0(%ebp),%ecx
  10c076:	89 55 d0             	mov    %edx,0xffffffd0(%ebp)
  10c079:	89 4d d4             	mov    %ecx,0xffffffd4(%ebp)
  10c07c:	e9 ff fe ff ff       	jmp    10bf80 <__umoddi3+0x60>
  10c081:	8b 4d e0             	mov    0xffffffe0(%ebp),%ecx
  10c084:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  10c087:	2b 45 ec             	sub    0xffffffec(%ebp),%eax
  10c08a:	1b 4d e8             	sbb    0xffffffe8(%ebp),%ecx
  10c08d:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
  10c090:	89 4d e0             	mov    %ecx,0xffffffe0(%ebp)
  10c093:	eb db                	jmp    10c070 <__umoddi3+0x150>
  10c095:	39 f0                	cmp    %esi,%eax
  10c097:	0f 86 64 ff ff ff    	jbe    10c001 <__umoddi3+0xe1>
  10c09d:	29 f8                	sub    %edi,%eax
  10c09f:	1b 55 f4             	sbb    0xfffffff4(%ebp),%edx
  10c0a2:	e9 5a ff ff ff       	jmp    10c001 <__umoddi3+0xe1>
