
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
  10001a:	bc b4 ef 10 00       	mov    $0x10efb4,%esp

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
  10002f:	e8 3e 04 00 00       	call   100472 <cpu_onboot>
  100034:	85 c0                	test   %eax,%eax
  100036:	74 28                	je     100060 <init+0x38>
		memset(edata, 0, end - edata);
  100038:	ba 08 20 18 00       	mov    $0x182008,%edx
  10003d:	b8 21 8b 17 00       	mov    $0x178b21,%eax
  100042:	89 d1                	mov    %edx,%ecx
  100044:	29 c1                	sub    %eax,%ecx
  100046:	89 c8                	mov    %ecx,%eax
  100048:	89 44 24 08          	mov    %eax,0x8(%esp)
  10004c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  100053:	00 
  100054:	c7 04 24 21 8b 17 00 	movl   $0x178b21,(%esp)
  10005b:	e8 95 b7 00 00       	call   10b7f5 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
  100060:	e8 01 06 00 00       	call   100666 <cons_init>

  	extern uint8_t _binary_obj_boot_bootother_start[],
    	_binary_obj_boot_bootother_size[];

  	uint8_t *code = (uint8_t*)lowmem_bootother_vec;
  100065:	c7 45 b0 00 10 00 00 	movl   $0x1000,0xffffffb0(%ebp)
  	memmove(code, _binary_obj_boot_bootother_start, (uint32_t) _binary_obj_boot_bootother_size);
  10006c:	b8 c0 01 00 00       	mov    $0x1c0,%eax
  100071:	89 44 24 08          	mov    %eax,0x8(%esp)
  100075:	c7 44 24 04 61 89 17 	movl   $0x178961,0x4(%esp)
  10007c:	00 
  10007d:	8b 45 b0             	mov    0xffffffb0(%ebp),%eax
  100080:	89 04 24             	mov    %eax,(%esp)
  100083:	e8 e6 b7 00 00       	call   10b86e <memmove>

	// Lab 1: test cprintf and debug_trace
	cprintf("1234 decimal is %o octal!\n", 1234);
  100088:	c7 44 24 04 d2 04 00 	movl   $0x4d2,0x4(%esp)
  10008f:	00 
  100090:	c7 04 24 c0 bc 10 00 	movl   $0x10bcc0,(%esp)
  100097:	e8 d5 b3 00 00       	call   10b471 <cprintf>
	debug_check();
  10009c:	e8 bc 0a 00 00       	call   100b5d <debug_check>

	// Initialize and load the bootstrap CPU's GDT, TSS, and IDT.
	cpu_init();
  1000a1:	e8 36 15 00 00       	call   1015dc <cpu_init>
	trap_init();
  1000a6:	e8 97 2b 00 00       	call   102c42 <trap_init>

	// Physical memory detection/initialization.
	// Can't call mem_alloc until after we do this!
	mem_init();
  1000ab:	e8 ec 0c 00 00       	call   100d9c <mem_init>

	// Lab 2: check spinlock implementation
	if (cpu_onboot())
  1000b0:	e8 bd 03 00 00       	call   100472 <cpu_onboot>
  1000b5:	85 c0                	test   %eax,%eax
  1000b7:	74 05                	je     1000be <init+0x96>
		spinlock_check();
  1000b9:	e8 d1 3b 00 00       	call   103c8f <spinlock_check>

	// Initialize the paged virtual memory system.
	pmap_init();
  1000be:	e8 6d 5a 00 00       	call   105b30 <pmap_init>

	// Find and start other processors in a multiprocessor system
	mp_init();		// Find info about processors in system
  1000c3:	e8 c7 37 00 00       	call   10388f <mp_init>
	pic_init();		// setup the legacy PIC (mainly to disable it)
  1000c8:	e8 4b a4 00 00       	call   10a518 <pic_init>
	ioapic_init();		// prepare to handle external device interrupts
  1000cd:	e8 6e aa 00 00       	call   10ab40 <ioapic_init>
	lapic_init();		// setup this CPU's local APIC
  1000d2:	e8 c4 a6 00 00       	call   10a79b <lapic_init>
	cpu_bootothers();	// Get other processors started
  1000d7:	e8 2e 17 00 00       	call   10180a <cpu_bootothers>
//	cprintf("CPU %d (%s) has booted\n", cpu_cur()->id,
//		cpu_onboot() ? "BP" : "AP");

	file_init();		// Create root directory and console I/O files
  1000dc:	e8 67 98 00 00       	call   109948 <file_init>

	// Lab 4: uncomment this when you can handle IRQ_SERIAL and IRQ_KBD.
	cons_intenable();	// Let the console start producing interrupts
  1000e1:	e8 4c 06 00 00       	call   100732 <cons_intenable>

	// Initialize the process management code.
	proc_init();
  1000e6:	e8 41 40 00 00       	call   10412c <proc_init>
	if(!cpu_onboot())
  1000eb:	e8 82 03 00 00       	call   100472 <cpu_onboot>
  1000f0:	85 c0                	test   %eax,%eax
  1000f2:	75 05                	jne    1000f9 <init+0xd1>
		proc_sched();
  1000f4:	e8 e3 44 00 00       	call   1045dc <proc_sched>
 	proc *root = proc_root = proc_alloc(NULL,0);
  1000f9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  100100:	00 
  100101:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  100108:	e8 c1 40 00 00       	call   1041ce <proc_alloc>
  10010d:	a3 b0 f4 17 00       	mov    %eax,0x17f4b0
  100112:	a1 b0 f4 17 00       	mov    0x17f4b0,%eax
  100117:	89 45 b4             	mov    %eax,0xffffffb4(%ebp)
  
  	elfhdr *ehs = (elfhdr *)ROOTEXE_START;
  10011a:	c7 45 b8 39 39 15 00 	movl   $0x153939,0xffffffb8(%ebp)
  	assert(ehs->e_magic == ELF_MAGIC);
  100121:	8b 45 b8             	mov    0xffffffb8(%ebp),%eax
  100124:	8b 00                	mov    (%eax),%eax
  100126:	3d 7f 45 4c 46       	cmp    $0x464c457f,%eax
  10012b:	74 24                	je     100151 <init+0x129>
  10012d:	c7 44 24 0c db bc 10 	movl   $0x10bcdb,0xc(%esp)
  100134:	00 
  100135:	c7 44 24 08 f5 bc 10 	movl   $0x10bcf5,0x8(%esp)
  10013c:	00 
  10013d:	c7 44 24 04 6b 00 00 	movl   $0x6b,0x4(%esp)
  100144:	00 
  100145:	c7 04 24 0a bd 10 00 	movl   $0x10bd0a,(%esp)
  10014c:	e8 17 08 00 00       	call   100968 <debug_panic>

  	proghdr *phs = (proghdr *) ((void *) ehs + ehs->e_phoff);
  100151:	8b 45 b8             	mov    0xffffffb8(%ebp),%eax
  100154:	8b 40 1c             	mov    0x1c(%eax),%eax
  100157:	03 45 b8             	add    0xffffffb8(%ebp),%eax
  10015a:	89 45 bc             	mov    %eax,0xffffffbc(%ebp)
  	proghdr *ep = phs + ehs->e_phnum;
  10015d:	8b 45 b8             	mov    0xffffffb8(%ebp),%eax
  100160:	0f b7 40 2c          	movzwl 0x2c(%eax),%eax
  100164:	0f b7 c0             	movzwl %ax,%eax
  100167:	c1 e0 05             	shl    $0x5,%eax
  10016a:	03 45 bc             	add    0xffffffbc(%ebp),%eax
  10016d:	89 45 c0             	mov    %eax,0xffffffc0(%ebp)

  	for (; phs < ep; phs++)
  100170:	e9 1c 02 00 00       	jmp    100391 <init+0x369>
	{
    		if (phs->p_type != ELF_PROG_LOAD)
  100175:	8b 45 bc             	mov    0xffffffbc(%ebp),%eax
  100178:	8b 00                	mov    (%eax),%eax
  10017a:	83 f8 01             	cmp    $0x1,%eax
  10017d:	0f 85 0a 02 00 00    	jne    10038d <init+0x365>
      		continue;

    		void *fa = (void *) ehs + ROUNDDOWN(phs->p_offset, PAGESIZE);
  100183:	8b 45 bc             	mov    0xffffffbc(%ebp),%eax
  100186:	8b 40 04             	mov    0x4(%eax),%eax
  100189:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)
  10018c:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  10018f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  100194:	03 45 b8             	add    0xffffffb8(%ebp),%eax
  100197:	89 45 cc             	mov    %eax,0xffffffcc(%ebp)
    		uint32_t va = ROUNDDOWN(phs->p_va, PAGESIZE);
  10019a:	8b 45 bc             	mov    0xffffffbc(%ebp),%eax
  10019d:	8b 40 08             	mov    0x8(%eax),%eax
  1001a0:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
  1001a3:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  1001a6:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1001ab:	89 45 d0             	mov    %eax,0xffffffd0(%ebp)
    		uint32_t zva = phs->p_va + phs->p_filesz;
  1001ae:	8b 45 bc             	mov    0xffffffbc(%ebp),%eax
  1001b1:	8b 50 08             	mov    0x8(%eax),%edx
  1001b4:	8b 45 bc             	mov    0xffffffbc(%ebp),%eax
  1001b7:	8b 40 10             	mov    0x10(%eax),%eax
  1001ba:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1001bd:	89 45 d4             	mov    %eax,0xffffffd4(%ebp)
    		uint32_t eva = ROUNDUP(phs->p_va + phs->p_memsz, PAGESIZE);
  1001c0:	c7 45 e8 00 10 00 00 	movl   $0x1000,0xffffffe8(%ebp)
  1001c7:	8b 45 bc             	mov    0xffffffbc(%ebp),%eax
  1001ca:	8b 50 08             	mov    0x8(%eax),%edx
  1001cd:	8b 45 bc             	mov    0xffffffbc(%ebp),%eax
  1001d0:	8b 40 14             	mov    0x14(%eax),%eax
  1001d3:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1001d6:	03 45 e8             	add    0xffffffe8(%ebp),%eax
  1001d9:	83 e8 01             	sub    $0x1,%eax
  1001dc:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  1001df:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  1001e2:	ba 00 00 00 00       	mov    $0x0,%edx
  1001e7:	f7 75 e8             	divl   0xffffffe8(%ebp)
  1001ea:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  1001ed:	29 d0                	sub    %edx,%eax
  1001ef:	89 45 d8             	mov    %eax,0xffffffd8(%ebp)

    		uint32_t perm = SYS_READ | PTE_P | PTE_U;
  1001f2:	c7 45 dc 05 02 00 00 	movl   $0x205,0xffffffdc(%ebp)
    		if(phs->p_flags & ELF_PROG_FLAG_WRITE) perm |= SYS_WRITE | PTE_W;
  1001f9:	8b 45 bc             	mov    0xffffffbc(%ebp),%eax
  1001fc:	8b 40 18             	mov    0x18(%eax),%eax
  1001ff:	83 e0 02             	and    $0x2,%eax
  100202:	85 c0                	test   %eax,%eax
  100204:	0f 84 77 01 00 00    	je     100381 <init+0x359>
  10020a:	81 4d dc 02 04 00 00 	orl    $0x402,0xffffffdc(%ebp)

    		for (; va < eva; va += PAGESIZE, fa += PAGESIZE) 
  100211:	e9 6b 01 00 00       	jmp    100381 <init+0x359>
		{
    			pageinfo *pi = mem_alloc(); assert(pi != NULL);
  100216:	e8 30 0e 00 00       	call   10104b <mem_alloc>
  10021b:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
  10021e:	83 7d f0 00          	cmpl   $0x0,0xfffffff0(%ebp)
  100222:	75 24                	jne    100248 <init+0x220>
  100224:	c7 44 24 0c 16 bd 10 	movl   $0x10bd16,0xc(%esp)
  10022b:	00 
  10022c:	c7 44 24 08 f5 bc 10 	movl   $0x10bcf5,0x8(%esp)
  100233:	00 
  100234:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
  10023b:	00 
  10023c:	c7 04 24 0a bd 10 00 	movl   $0x10bd0a,(%esp)
  100243:	e8 20 07 00 00       	call   100968 <debug_panic>
      			if(va < ROUNDDOWN(zva, PAGESIZE))
  100248:	8b 45 d4             	mov    0xffffffd4(%ebp),%eax
  10024b:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  10024e:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  100251:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  100256:	3b 45 d0             	cmp    0xffffffd0(%ebp),%eax
  100259:	76 2f                	jbe    10028a <init+0x262>
        			memmove(mem_pi2ptr(pi), fa, PAGESIZE);
  10025b:	8b 55 f0             	mov    0xfffffff0(%ebp),%edx
  10025e:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  100263:	89 d3                	mov    %edx,%ebx
  100265:	29 c3                	sub    %eax,%ebx
  100267:	89 d8                	mov    %ebx,%eax
  100269:	c1 e0 09             	shl    $0x9,%eax
  10026c:	89 c2                	mov    %eax,%edx
  10026e:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  100275:	00 
  100276:	8b 45 cc             	mov    0xffffffcc(%ebp),%eax
  100279:	89 44 24 04          	mov    %eax,0x4(%esp)
  10027d:	89 14 24             	mov    %edx,(%esp)
  100280:	e8 e9 b5 00 00       	call   10b86e <memmove>
  100285:	e9 96 00 00 00       	jmp    100320 <init+0x2f8>
      			else if (va < zva && phs->p_filesz)
  10028a:	8b 45 d0             	mov    0xffffffd0(%ebp),%eax
  10028d:	3b 45 d4             	cmp    0xffffffd4(%ebp),%eax
  100290:	73 65                	jae    1002f7 <init+0x2cf>
  100292:	8b 45 bc             	mov    0xffffffbc(%ebp),%eax
  100295:	8b 40 10             	mov    0x10(%eax),%eax
  100298:	85 c0                	test   %eax,%eax
  10029a:	74 5b                	je     1002f7 <init+0x2cf>
			{
      				memset(mem_pi2ptr(pi),0, PAGESIZE);
  10029c:	8b 55 f0             	mov    0xfffffff0(%ebp),%edx
  10029f:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  1002a4:	89 d1                	mov    %edx,%ecx
  1002a6:	29 c1                	sub    %eax,%ecx
  1002a8:	89 c8                	mov    %ecx,%eax
  1002aa:	c1 e0 09             	shl    $0x9,%eax
  1002ad:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  1002b4:	00 
  1002b5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1002bc:	00 
  1002bd:	89 04 24             	mov    %eax,(%esp)
  1002c0:	e8 30 b5 00 00       	call   10b7f5 <memset>
      				memmove(mem_pi2ptr(pi), fa, zva-va);
  1002c5:	8b 55 d0             	mov    0xffffffd0(%ebp),%edx
  1002c8:	8b 45 d4             	mov    0xffffffd4(%ebp),%eax
  1002cb:	89 c1                	mov    %eax,%ecx
  1002cd:	29 d1                	sub    %edx,%ecx
  1002cf:	8b 55 f0             	mov    0xfffffff0(%ebp),%edx
  1002d2:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  1002d7:	89 d3                	mov    %edx,%ebx
  1002d9:	29 c3                	sub    %eax,%ebx
  1002db:	89 d8                	mov    %ebx,%eax
  1002dd:	c1 e0 09             	shl    $0x9,%eax
  1002e0:	89 c2                	mov    %eax,%edx
  1002e2:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  1002e6:	8b 45 cc             	mov    0xffffffcc(%ebp),%eax
  1002e9:	89 44 24 04          	mov    %eax,0x4(%esp)
  1002ed:	89 14 24             	mov    %edx,(%esp)
  1002f0:	e8 79 b5 00 00       	call   10b86e <memmove>
  1002f5:	eb 29                	jmp    100320 <init+0x2f8>
      			} 
			else
        			memset(mem_pi2ptr(pi), 0, PAGESIZE);
  1002f7:	8b 55 f0             	mov    0xfffffff0(%ebp),%edx
  1002fa:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  1002ff:	89 d1                	mov    %edx,%ecx
  100301:	29 c1                	sub    %eax,%ecx
  100303:	89 c8                	mov    %ecx,%eax
  100305:	c1 e0 09             	shl    $0x9,%eax
  100308:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  10030f:	00 
  100310:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  100317:	00 
  100318:	89 04 24             	mov    %eax,(%esp)
  10031b:	e8 d5 b4 00 00       	call   10b7f5 <memset>

      			pte_t *pte = pmap_insert(root->pdir, pi, va, perm);
  100320:	8b 55 dc             	mov    0xffffffdc(%ebp),%edx
  100323:	8b 45 b4             	mov    0xffffffb4(%ebp),%eax
  100326:	8b 88 a0 06 00 00    	mov    0x6a0(%eax),%ecx
  10032c:	89 54 24 0c          	mov    %edx,0xc(%esp)
  100330:	8b 45 d0             	mov    0xffffffd0(%ebp),%eax
  100333:	89 44 24 08          	mov    %eax,0x8(%esp)
  100337:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  10033a:	89 44 24 04          	mov    %eax,0x4(%esp)
  10033e:	89 0c 24             	mov    %ecx,(%esp)
  100341:	e8 41 63 00 00       	call   106687 <pmap_insert>
  100346:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
      			assert(pte != NULL);
  100349:	83 7d f4 00          	cmpl   $0x0,0xfffffff4(%ebp)
  10034d:	75 24                	jne    100373 <init+0x34b>
  10034f:	c7 44 24 0c 21 bd 10 	movl   $0x10bd21,0xc(%esp)
  100356:	00 
  100357:	c7 44 24 08 f5 bc 10 	movl   $0x10bcf5,0x8(%esp)
  10035e:	00 
  10035f:	c7 44 24 04 8b 00 00 	movl   $0x8b,0x4(%esp)
  100366:	00 
  100367:	c7 04 24 0a bd 10 00 	movl   $0x10bd0a,(%esp)
  10036e:	e8 f5 05 00 00       	call   100968 <debug_panic>
  100373:	81 45 d0 00 10 00 00 	addl   $0x1000,0xffffffd0(%ebp)
  10037a:	81 45 cc 00 10 00 00 	addl   $0x1000,0xffffffcc(%ebp)
  100381:	8b 45 d0             	mov    0xffffffd0(%ebp),%eax
  100384:	3b 45 d8             	cmp    0xffffffd8(%ebp),%eax
  100387:	0f 82 89 fe ff ff    	jb     100216 <init+0x1ee>
  10038d:	83 45 bc 20          	addl   $0x20,0xffffffbc(%ebp)
  100391:	8b 45 bc             	mov    0xffffffbc(%ebp),%eax
  100394:	3b 45 c0             	cmp    0xffffffc0(%ebp),%eax
  100397:	0f 82 d8 fd ff ff    	jb     100175 <init+0x14d>
      		}
      }

      root->sv.tf.eip = ehs->e_entry;
  10039d:	8b 45 b8             	mov    0xffffffb8(%ebp),%eax
  1003a0:	8b 50 18             	mov    0x18(%eax),%edx
  1003a3:	8b 45 b4             	mov    0xffffffb4(%ebp),%eax
  1003a6:	89 90 88 04 00 00    	mov    %edx,0x488(%eax)
      root->sv.tf.eflags |= FL_IF;
  1003ac:	8b 45 b4             	mov    0xffffffb4(%ebp),%eax
  1003af:	8b 80 90 04 00 00    	mov    0x490(%eax),%eax
  1003b5:	89 c2                	mov    %eax,%edx
  1003b7:	80 ce 02             	or     $0x2,%dh
  1003ba:	8b 45 b4             	mov    0xffffffb4(%ebp),%eax
  1003bd:	89 90 90 04 00 00    	mov    %edx,0x490(%eax)

      pageinfo *pi = mem_alloc(); assert(pi != NULL);
  1003c3:	e8 83 0c 00 00       	call   10104b <mem_alloc>
  1003c8:	89 45 c4             	mov    %eax,0xffffffc4(%ebp)
  1003cb:	83 7d c4 00          	cmpl   $0x0,0xffffffc4(%ebp)
  1003cf:	75 24                	jne    1003f5 <init+0x3cd>
  1003d1:	c7 44 24 0c 16 bd 10 	movl   $0x10bd16,0xc(%esp)
  1003d8:	00 
  1003d9:	c7 44 24 08 f5 bc 10 	movl   $0x10bcf5,0x8(%esp)
  1003e0:	00 
  1003e1:	c7 44 24 04 92 00 00 	movl   $0x92,0x4(%esp)
  1003e8:	00 
  1003e9:	c7 04 24 0a bd 10 00 	movl   $0x10bd0a,(%esp)
  1003f0:	e8 73 05 00 00       	call   100968 <debug_panic>
      pte_t *pte = pmap_insert(root->pdir, pi, VM_STACKHI-PAGESIZE,
      SYS_READ | SYS_WRITE | PTE_P | PTE_U | PTE_W);
  1003f5:	8b 45 b4             	mov    0xffffffb4(%ebp),%eax
  1003f8:	8b 90 a0 06 00 00    	mov    0x6a0(%eax),%edx
  1003fe:	c7 44 24 0c 07 06 00 	movl   $0x607,0xc(%esp)
  100405:	00 
  100406:	c7 44 24 08 00 f0 ff 	movl   $0xeffff000,0x8(%esp)
  10040d:	ef 
  10040e:	8b 45 c4             	mov    0xffffffc4(%ebp),%eax
  100411:	89 44 24 04          	mov    %eax,0x4(%esp)
  100415:	89 14 24             	mov    %edx,(%esp)
  100418:	e8 6a 62 00 00       	call   106687 <pmap_insert>
  10041d:	89 45 c8             	mov    %eax,0xffffffc8(%ebp)

      assert(pte != NULL);
  100420:	83 7d c8 00          	cmpl   $0x0,0xffffffc8(%ebp)
  100424:	75 24                	jne    10044a <init+0x422>
  100426:	c7 44 24 0c 21 bd 10 	movl   $0x10bd21,0xc(%esp)
  10042d:	00 
  10042e:	c7 44 24 08 f5 bc 10 	movl   $0x10bcf5,0x8(%esp)
  100435:	00 
  100436:	c7 44 24 04 96 00 00 	movl   $0x96,0x4(%esp)
  10043d:	00 
  10043e:	c7 04 24 0a bd 10 00 	movl   $0x10bd0a,(%esp)
  100445:	e8 1e 05 00 00       	call   100968 <debug_panic>
      root->sv.tf.esp = VM_STACKHI;
  10044a:	8b 45 b4             	mov    0xffffffb4(%ebp),%eax
  10044d:	c7 80 94 04 00 00 00 	movl   $0xf0000000,0x494(%eax)
  100454:	00 00 f0 
			// Give the root process an initial file system.
			file_initroot(root);
  100457:	8b 45 b4             	mov    0xffffffb4(%ebp),%eax
  10045a:	89 04 24             	mov    %eax,(%esp)
  10045d:	e8 7e 95 00 00       	call   1099e0 <file_initroot>

			proc_ready(root);
  100462:	8b 45 b4             	mov    0xffffffb4(%ebp),%eax
  100465:	89 04 24             	mov    %eax,(%esp)
  100468:	e8 ab 3f 00 00       	call   104418 <proc_ready>
			proc_sched();
  10046d:	e8 6a 41 00 00       	call   1045dc <proc_sched>

00100472 <cpu_onboot>:
}

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  100472:	55                   	push   %ebp
  100473:	89 e5                	mov    %esp,%ebp
  100475:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  100478:	e8 0d 00 00 00       	call   10048a <cpu_cur>
  10047d:	3d 00 e0 10 00       	cmp    $0x10e000,%eax
  100482:	0f 94 c0             	sete   %al
  100485:	0f b6 c0             	movzbl %al,%eax
}
  100488:	c9                   	leave  
  100489:	c3                   	ret    

0010048a <cpu_cur>:
  10048a:	55                   	push   %ebp
  10048b:	89 e5                	mov    %esp,%ebp
  10048d:	83 ec 28             	sub    $0x28,%esp
static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  100490:	89 65 fc             	mov    %esp,0xfffffffc(%ebp)
        return esp;
  100493:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  100496:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  100499:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10049c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1004a1:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	assert(c->magic == CPU_MAGIC);
  1004a4:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  1004a7:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  1004ad:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  1004b2:	74 24                	je     1004d8 <cpu_cur+0x4e>
  1004b4:	c7 44 24 0c 2d bd 10 	movl   $0x10bd2d,0xc(%esp)
  1004bb:	00 
  1004bc:	c7 44 24 08 f5 bc 10 	movl   $0x10bcf5,0x8(%esp)
  1004c3:	00 
  1004c4:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  1004cb:	00 
  1004cc:	c7 04 24 43 bd 10 00 	movl   $0x10bd43,(%esp)
  1004d3:	e8 90 04 00 00       	call   100968 <debug_panic>
	return c;
  1004d8:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
}
  1004db:	c9                   	leave  
  1004dc:	c3                   	ret    

001004dd <user>:
}

// This is the first function that gets run in user mode (ring 3).
// It acts as PIOS's "root process",
// of which all other processes are descendants.
void
user()
{
  1004dd:	55                   	push   %ebp
  1004de:	89 e5                	mov    %esp,%ebp
  1004e0:	83 ec 28             	sub    $0x28,%esp
	cprintf("in user()\n");
  1004e3:	c7 04 24 50 bd 10 00 	movl   $0x10bd50,(%esp)
  1004ea:	e8 82 af 00 00       	call   10b471 <cprintf>
static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  1004ef:	89 65 f8             	mov    %esp,0xfffffff8(%ebp)
        return esp;
  1004f2:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1004f5:	89 c2                	mov    %eax,%edx
	assert(read_esp() > (uint32_t) &user_stack[0]);
  1004f7:	b8 00 90 17 00       	mov    $0x179000,%eax
  1004fc:	39 c2                	cmp    %eax,%edx
  1004fe:	77 24                	ja     100524 <user+0x47>
  100500:	c7 44 24 0c 5c bd 10 	movl   $0x10bd5c,0xc(%esp)
  100507:	00 
  100508:	c7 44 24 08 f5 bc 10 	movl   $0x10bcf5,0x8(%esp)
  10050f:	00 
  100510:	c7 44 24 04 a6 00 00 	movl   $0xa6,0x4(%esp)
  100517:	00 
  100518:	c7 04 24 0a bd 10 00 	movl   $0x10bd0a,(%esp)
  10051f:	e8 44 04 00 00       	call   100968 <debug_panic>
static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  100524:	89 65 fc             	mov    %esp,0xfffffffc(%ebp)
        return esp;
  100527:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  10052a:	89 c2                	mov    %eax,%edx
	assert(read_esp() < (uint32_t) &user_stack[sizeof(user_stack)]);
  10052c:	b8 00 a0 17 00       	mov    $0x17a000,%eax
  100531:	39 c2                	cmp    %eax,%edx
  100533:	72 24                	jb     100559 <user+0x7c>
  100535:	c7 44 24 0c 84 bd 10 	movl   $0x10bd84,0xc(%esp)
  10053c:	00 
  10053d:	c7 44 24 08 f5 bc 10 	movl   $0x10bcf5,0x8(%esp)
  100544:	00 
  100545:	c7 44 24 04 a7 00 00 	movl   $0xa7,0x4(%esp)
  10054c:	00 
  10054d:	c7 04 24 0a bd 10 00 	movl   $0x10bd0a,(%esp)
  100554:	e8 0f 04 00 00       	call   100968 <debug_panic>

	// Check the system call and process scheduling code.
  	cprintf("proc_check");
  100559:	c7 04 24 bc bd 10 00 	movl   $0x10bdbc,(%esp)
  100560:	e8 0c af 00 00       	call   10b471 <cprintf>
	proc_check();
  100565:	e8 bc 43 00 00       	call   104926 <proc_check>

	// Check that we're in user mode and can handle traps from there.
	trap_check_user();
  10056a:	e8 a8 2c 00 00       	call   103217 <trap_check_user>

	done();
  10056f:	e8 00 00 00 00       	call   100574 <done>

00100574 <done>:
}

// This is a function that we call when the kernel is "done" -
// it just puts the processor into an infinite loop.
// We make this a function so that we can set a breakpoints on it.
// Our grade scripts use this breakpoint to know when to stop QEMU.
void gcc_noreturn
done()
{
  100574:	55                   	push   %ebp
  100575:	89 e5                	mov    %esp,%ebp
	while (1)
		;	// just spin
  100577:	eb fe                	jmp    100577 <done+0x3>
  100579:	90                   	nop    
  10057a:	90                   	nop    
  10057b:	90                   	nop    

0010057c <cons_intr>:
// called by device interrupt routines to feed input characters
// into the circular console input buffer.
void
cons_intr(int (*proc)(void))
{
  10057c:	55                   	push   %ebp
  10057d:	89 e5                	mov    %esp,%ebp
  10057f:	83 ec 18             	sub    $0x18,%esp
	int c;

	spinlock_acquire(&cons_lock);
  100582:	c7 04 24 40 ed 17 00 	movl   $0x17ed40,(%esp)
  100589:	e8 2c 35 00 00       	call   103aba <spinlock_acquire>
	while ((c = (*proc)()) != -1) {
  10058e:	eb 33                	jmp    1005c3 <cons_intr+0x47>
		if (c == 0)
  100590:	83 7d fc 00          	cmpl   $0x0,0xfffffffc(%ebp)
  100594:	74 2d                	je     1005c3 <cons_intr+0x47>
			continue;
		cons.buf[cons.wpos++] = c;
  100596:	8b 15 04 a2 17 00    	mov    0x17a204,%edx
  10059c:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  10059f:	88 82 00 a0 17 00    	mov    %al,0x17a000(%edx)
  1005a5:	8d 42 01             	lea    0x1(%edx),%eax
  1005a8:	a3 04 a2 17 00       	mov    %eax,0x17a204
		if (cons.wpos == CONSBUFSIZE)
  1005ad:	a1 04 a2 17 00       	mov    0x17a204,%eax
  1005b2:	3d 00 02 00 00       	cmp    $0x200,%eax
  1005b7:	75 0a                	jne    1005c3 <cons_intr+0x47>
			cons.wpos = 0;
  1005b9:	c7 05 04 a2 17 00 00 	movl   $0x0,0x17a204
  1005c0:	00 00 00 
  1005c3:	8b 45 08             	mov    0x8(%ebp),%eax
  1005c6:	ff d0                	call   *%eax
  1005c8:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  1005cb:	83 7d fc ff          	cmpl   $0xffffffff,0xfffffffc(%ebp)
  1005cf:	75 bf                	jne    100590 <cons_intr+0x14>
	}
	spinlock_release(&cons_lock);
  1005d1:	c7 04 24 40 ed 17 00 	movl   $0x17ed40,(%esp)
  1005d8:	e8 d8 35 00 00       	call   103bb5 <spinlock_release>

	// Wake the root process
	file_wakeroot();
  1005dd:	e8 2b 98 00 00       	call   109e0d <file_wakeroot>
}
  1005e2:	c9                   	leave  
  1005e3:	c3                   	ret    

001005e4 <cons_getc>:

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
  1005e4:	55                   	push   %ebp
  1005e5:	89 e5                	mov    %esp,%ebp
  1005e7:	83 ec 18             	sub    $0x18,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
  1005ea:	e8 b9 9d 00 00       	call   10a3a8 <serial_intr>
	kbd_intr();
  1005ef:	e8 ec 9c 00 00       	call   10a2e0 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
  1005f4:	8b 15 00 a2 17 00    	mov    0x17a200,%edx
  1005fa:	a1 04 a2 17 00       	mov    0x17a204,%eax
  1005ff:	39 c2                	cmp    %eax,%edx
  100601:	74 39                	je     10063c <cons_getc+0x58>
		c = cons.buf[cons.rpos++];
  100603:	8b 15 00 a2 17 00    	mov    0x17a200,%edx
  100609:	0f b6 82 00 a0 17 00 	movzbl 0x17a000(%edx),%eax
  100610:	0f b6 c0             	movzbl %al,%eax
  100613:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  100616:	8d 42 01             	lea    0x1(%edx),%eax
  100619:	a3 00 a2 17 00       	mov    %eax,0x17a200
		if (cons.rpos == CONSBUFSIZE)
  10061e:	a1 00 a2 17 00       	mov    0x17a200,%eax
  100623:	3d 00 02 00 00       	cmp    $0x200,%eax
  100628:	75 0a                	jne    100634 <cons_getc+0x50>
			cons.rpos = 0;
  10062a:	c7 05 00 a2 17 00 00 	movl   $0x0,0x17a200
  100631:	00 00 00 
		return c;
  100634:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  100637:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  10063a:	eb 07                	jmp    100643 <cons_getc+0x5f>
	}
	return 0;
  10063c:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  100643:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
}
  100646:	c9                   	leave  
  100647:	c3                   	ret    

00100648 <cons_putc>:

// output a character to the console
static void
cons_putc(int c)
{
  100648:	55                   	push   %ebp
  100649:	89 e5                	mov    %esp,%ebp
  10064b:	83 ec 08             	sub    $0x8,%esp
	serial_putc(c);
  10064e:	8b 45 08             	mov    0x8(%ebp),%eax
  100651:	89 04 24             	mov    %eax,(%esp)
  100654:	e8 6c 9d 00 00       	call   10a3c5 <serial_putc>
	video_putc(c);
  100659:	8b 45 08             	mov    0x8(%ebp),%eax
  10065c:	89 04 24             	mov    %eax,(%esp)
  10065f:	e8 b8 98 00 00       	call   109f1c <video_putc>
}
  100664:	c9                   	leave  
  100665:	c3                   	ret    

00100666 <cons_init>:

// initialize the console devices
void
cons_init(void)
{
  100666:	55                   	push   %ebp
  100667:	89 e5                	mov    %esp,%ebp
  100669:	83 ec 18             	sub    $0x18,%esp
	if (!cpu_onboot())	// only do once, on the boot CPU
  10066c:	e8 56 00 00 00       	call   1006c7 <cpu_onboot>
  100671:	85 c0                	test   %eax,%eax
  100673:	74 50                	je     1006c5 <cons_init+0x5f>
		return;

	spinlock_init(&cons_lock);
  100675:	c7 44 24 08 6e 00 00 	movl   $0x6e,0x8(%esp)
  10067c:	00 
  10067d:	c7 44 24 04 c8 bd 10 	movl   $0x10bdc8,0x4(%esp)
  100684:	00 
  100685:	c7 04 24 40 ed 17 00 	movl   $0x17ed40,(%esp)
  10068c:	e8 ff 33 00 00       	call   103a90 <spinlock_init_>
	video_init();
  100691:	e8 be 97 00 00       	call   109e54 <video_init>
	kbd_init();
  100696:	e8 59 9c 00 00       	call   10a2f4 <kbd_init>
	serial_init();
  10069b:	e8 85 9d 00 00       	call   10a425 <serial_init>

	if (!serial_exists)
  1006a0:	a1 00 20 18 00       	mov    0x182000,%eax
  1006a5:	85 c0                	test   %eax,%eax
  1006a7:	75 1c                	jne    1006c5 <cons_init+0x5f>
		warn("Serial port does not exist!\n");
  1006a9:	c7 44 24 08 d4 bd 10 	movl   $0x10bdd4,0x8(%esp)
  1006b0:	00 
  1006b1:	c7 44 24 04 74 00 00 	movl   $0x74,0x4(%esp)
  1006b8:	00 
  1006b9:	c7 04 24 c8 bd 10 00 	movl   $0x10bdc8,(%esp)
  1006c0:	e8 61 03 00 00       	call   100a26 <debug_warn>
}
  1006c5:	c9                   	leave  
  1006c6:	c3                   	ret    

001006c7 <cpu_onboot>:
}

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  1006c7:	55                   	push   %ebp
  1006c8:	89 e5                	mov    %esp,%ebp
  1006ca:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  1006cd:	e8 0d 00 00 00       	call   1006df <cpu_cur>
  1006d2:	3d 00 e0 10 00       	cmp    $0x10e000,%eax
  1006d7:	0f 94 c0             	sete   %al
  1006da:	0f b6 c0             	movzbl %al,%eax
}
  1006dd:	c9                   	leave  
  1006de:	c3                   	ret    

001006df <cpu_cur>:
  1006df:	55                   	push   %ebp
  1006e0:	89 e5                	mov    %esp,%ebp
  1006e2:	83 ec 28             	sub    $0x28,%esp
static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  1006e5:	89 65 fc             	mov    %esp,0xfffffffc(%ebp)
        return esp;
  1006e8:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  1006eb:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  1006ee:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1006f1:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1006f6:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	assert(c->magic == CPU_MAGIC);
  1006f9:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  1006fc:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  100702:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  100707:	74 24                	je     10072d <cpu_cur+0x4e>
  100709:	c7 44 24 0c f1 bd 10 	movl   $0x10bdf1,0xc(%esp)
  100710:	00 
  100711:	c7 44 24 08 07 be 10 	movl   $0x10be07,0x8(%esp)
  100718:	00 
  100719:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  100720:	00 
  100721:	c7 04 24 1c be 10 00 	movl   $0x10be1c,(%esp)
  100728:	e8 3b 02 00 00       	call   100968 <debug_panic>
	return c;
  10072d:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
}
  100730:	c9                   	leave  
  100731:	c3                   	ret    

00100732 <cons_intenable>:

// Enable console interrupts.
void
cons_intenable(void)
{
  100732:	55                   	push   %ebp
  100733:	89 e5                	mov    %esp,%ebp
  100735:	83 ec 08             	sub    $0x8,%esp
	if (!cpu_onboot())	// only do once, on the boot CPU
  100738:	e8 8a ff ff ff       	call   1006c7 <cpu_onboot>
  10073d:	85 c0                	test   %eax,%eax
  10073f:	74 0a                	je     10074b <cons_intenable+0x19>
		return;

	kbd_intenable();
  100741:	e8 b3 9b 00 00       	call   10a2f9 <kbd_intenable>
	serial_intenable();
  100746:	e8 a2 9d 00 00       	call   10a4ed <serial_intenable>
}
  10074b:	c9                   	leave  
  10074c:	c3                   	ret    

0010074d <cputs>:

// `High'-level console I/O.  Used by readline and cprintf.
void
cputs(const char *str)
{
  10074d:	55                   	push   %ebp
  10074e:	89 e5                	mov    %esp,%ebp
  100750:	53                   	push   %ebx
  100751:	83 ec 14             	sub    $0x14,%esp
static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  100754:	8c 4d f6             	movw   %cs,0xfffffff6(%ebp)
        return cs;
  100757:	0f b7 45 f6          	movzwl 0xfffffff6(%ebp),%eax
	if (read_cs() & 3)
  10075b:	0f b7 c0             	movzwl %ax,%eax
  10075e:	83 e0 03             	and    $0x3,%eax
  100761:	85 c0                	test   %eax,%eax
  100763:	74 12                	je     100777 <cputs+0x2a>
  100765:	8b 45 08             	mov    0x8(%ebp),%eax
  100768:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %0" :
  10076b:	b8 00 00 00 00       	mov    $0x0,%eax
  100770:	8b 5d f8             	mov    0xfffffff8(%ebp),%ebx
  100773:	cd 30                	int    $0x30
		return sys_cputs(str);	// use syscall from user mode
  100775:	eb 54                	jmp    1007cb <cputs+0x7e>

	// Hold the console spinlock while printing the entire string,
	// so that the output of different cputs calls won't get mixed.
	// Implement ad hoc recursive locking for debugging convenience.
	bool already = spinlock_holding(&cons_lock);
  100777:	c7 04 24 40 ed 17 00 	movl   $0x17ed40,(%esp)
  10077e:	e8 8c 34 00 00       	call   103c0f <spinlock_holding>
  100783:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
	if (!already)
  100786:	83 7d f0 00          	cmpl   $0x0,0xfffffff0(%ebp)
  10078a:	75 23                	jne    1007af <cputs+0x62>
		spinlock_acquire(&cons_lock);
  10078c:	c7 04 24 40 ed 17 00 	movl   $0x17ed40,(%esp)
  100793:	e8 22 33 00 00       	call   103aba <spinlock_acquire>

	char ch;
	while (*str)
  100798:	eb 15                	jmp    1007af <cputs+0x62>
		cons_putc(*str++);
  10079a:	8b 45 08             	mov    0x8(%ebp),%eax
  10079d:	0f b6 00             	movzbl (%eax),%eax
  1007a0:	0f be c0             	movsbl %al,%eax
  1007a3:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  1007a7:	89 04 24             	mov    %eax,(%esp)
  1007aa:	e8 99 fe ff ff       	call   100648 <cons_putc>
  1007af:	8b 45 08             	mov    0x8(%ebp),%eax
  1007b2:	0f b6 00             	movzbl (%eax),%eax
  1007b5:	84 c0                	test   %al,%al
  1007b7:	75 e1                	jne    10079a <cputs+0x4d>

	if (!already)
  1007b9:	83 7d f0 00          	cmpl   $0x0,0xfffffff0(%ebp)
  1007bd:	75 0c                	jne    1007cb <cputs+0x7e>
		spinlock_release(&cons_lock);
  1007bf:	c7 04 24 40 ed 17 00 	movl   $0x17ed40,(%esp)
  1007c6:	e8 ea 33 00 00       	call   103bb5 <spinlock_release>
}
  1007cb:	83 c4 14             	add    $0x14,%esp
  1007ce:	5b                   	pop    %ebx
  1007cf:	5d                   	pop    %ebp
  1007d0:	c3                   	ret    

001007d1 <cons_io>:

// Synchronize the root process's console special files
// with the actual console I/O device.
bool
cons_io(void)
{
  1007d1:	55                   	push   %ebp
  1007d2:	89 e5                	mov    %esp,%ebp
  1007d4:	83 ec 38             	sub    $0x38,%esp
	// Lab 4: your console I/O code here.
	spinlock_acquire(&cons_lock);
  1007d7:	c7 04 24 40 ed 17 00 	movl   $0x17ed40,(%esp)
  1007de:	e8 d7 32 00 00       	call   103aba <spinlock_acquire>
	bool dildio = 0;
  1007e3:	c7 45 e8 00 00 00 00 	movl   $0x0,0xffffffe8(%ebp)

	// Console output from the root process's console output file
	fileinode *outfile = &files->fi[FILEINO_CONSOUT];
  1007ea:	a1 70 da 10 00       	mov    0x10da70,%eax
  1007ef:	05 10 10 00 00       	add    $0x1010,%eax
  1007f4:	05 b8 00 00 00       	add    $0xb8,%eax
  1007f9:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
	const char *outbuf = FILEDATA(FILEINO_CONSOUT);
  1007fc:	c7 45 f0 00 00 80 80 	movl   $0x80800000,0xfffffff0(%ebp)
	assert(cons_outsize <= outfile->size);
  100803:	a1 08 a2 17 00       	mov    0x17a208,%eax
  100808:	89 c2                	mov    %eax,%edx
  10080a:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  10080d:	8b 40 4c             	mov    0x4c(%eax),%eax
  100810:	39 c2                	cmp    %eax,%edx
  100812:	76 4c                	jbe    100860 <cons_io+0x8f>
  100814:	c7 44 24 0c 29 be 10 	movl   $0x10be29,0xc(%esp)
  10081b:	00 
  10081c:	c7 44 24 08 07 be 10 	movl   $0x10be07,0x8(%esp)
  100823:	00 
  100824:	c7 44 24 04 a4 00 00 	movl   $0xa4,0x4(%esp)
  10082b:	00 
  10082c:	c7 04 24 c8 bd 10 00 	movl   $0x10bdc8,(%esp)
  100833:	e8 30 01 00 00       	call   100968 <debug_panic>
	while (cons_outsize < outfile->size) {
		cons_putc(outbuf[cons_outsize++]);
  100838:	8b 0d 08 a2 17 00    	mov    0x17a208,%ecx
  10083e:	89 c8                	mov    %ecx,%eax
  100840:	03 45 f0             	add    0xfffffff0(%ebp),%eax
  100843:	0f b6 00             	movzbl (%eax),%eax
  100846:	0f be d0             	movsbl %al,%edx
  100849:	8d 41 01             	lea    0x1(%ecx),%eax
  10084c:	a3 08 a2 17 00       	mov    %eax,0x17a208
  100851:	89 14 24             	mov    %edx,(%esp)
  100854:	e8 ef fd ff ff       	call   100648 <cons_putc>
		dildio = 1;
  100859:	c7 45 e8 01 00 00 00 	movl   $0x1,0xffffffe8(%ebp)
  100860:	a1 08 a2 17 00       	mov    0x17a208,%eax
  100865:	89 c2                	mov    %eax,%edx
  100867:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  10086a:	8b 40 4c             	mov    0x4c(%eax),%eax
  10086d:	39 c2                	cmp    %eax,%edx
  10086f:	72 c7                	jb     100838 <cons_io+0x67>
	}

	fileinode *infile = &files->fi[FILEINO_CONSIN];
  100871:	a1 70 da 10 00       	mov    0x10da70,%eax
  100876:	05 10 10 00 00       	add    $0x1010,%eax
  10087b:	83 c0 5c             	add    $0x5c,%eax
  10087e:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	char *inbuf = FILEDATA(FILEINO_CONSIN);
  100881:	c7 45 f8 00 00 40 80 	movl   $0x80400000,0xfffffff8(%ebp)
	int amount = cons.wpos - cons.rpos;
  100888:	8b 15 04 a2 17 00    	mov    0x17a204,%edx
  10088e:	a1 00 a2 17 00       	mov    0x17a200,%eax
  100893:	89 d1                	mov    %edx,%ecx
  100895:	29 c1                	sub    %eax,%ecx
  100897:	89 c8                	mov    %ecx,%eax
  100899:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	if (infile->size + amount > FILE_MAXSIZE)
  10089c:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  10089f:	8b 50 4c             	mov    0x4c(%eax),%edx
  1008a2:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  1008a5:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1008a8:	3d 00 00 40 00       	cmp    $0x400000,%eax
  1008ad:	76 1c                	jbe    1008cb <cons_io+0xfa>
		panic("cons_io: root process console input file full");
  1008af:	c7 44 24 08 48 be 10 	movl   $0x10be48,0x8(%esp)
  1008b6:	00 
  1008b7:	c7 44 24 04 ae 00 00 	movl   $0xae,0x4(%esp)
  1008be:	00 
  1008bf:	c7 04 24 c8 bd 10 00 	movl   $0x10bdc8,(%esp)
  1008c6:	e8 9d 00 00 00       	call   100968 <debug_panic>
	assert(amount >= 0 && amount <= CONSBUFSIZE);
  1008cb:	83 7d fc 00          	cmpl   $0x0,0xfffffffc(%ebp)
  1008cf:	78 09                	js     1008da <cons_io+0x109>
  1008d1:	81 7d fc 00 02 00 00 	cmpl   $0x200,0xfffffffc(%ebp)
  1008d8:	7e 24                	jle    1008fe <cons_io+0x12d>
  1008da:	c7 44 24 0c 78 be 10 	movl   $0x10be78,0xc(%esp)
  1008e1:	00 
  1008e2:	c7 44 24 08 07 be 10 	movl   $0x10be07,0x8(%esp)
  1008e9:	00 
  1008ea:	c7 44 24 04 af 00 00 	movl   $0xaf,0x4(%esp)
  1008f1:	00 
  1008f2:	c7 04 24 c8 bd 10 00 	movl   $0x10bdc8,(%esp)
  1008f9:	e8 6a 00 00 00       	call   100968 <debug_panic>
	if (amount > 0) {
  1008fe:	83 7d fc 00          	cmpl   $0x0,0xfffffffc(%ebp)
  100902:	7e 53                	jle    100957 <cons_io+0x186>
		memmove(&inbuf[infile->size], &cons.buf[cons.rpos], amount);
  100904:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  100907:	a1 00 a2 17 00       	mov    0x17a200,%eax
  10090c:	8d 88 00 a0 17 00    	lea    0x17a000(%eax),%ecx
  100912:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  100915:	8b 40 4c             	mov    0x4c(%eax),%eax
  100918:	03 45 f8             	add    0xfffffff8(%ebp),%eax
  10091b:	89 54 24 08          	mov    %edx,0x8(%esp)
  10091f:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  100923:	89 04 24             	mov    %eax,(%esp)
  100926:	e8 43 af 00 00       	call   10b86e <memmove>
		infile->size += amount;
  10092b:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  10092e:	8b 50 4c             	mov    0x4c(%eax),%edx
  100931:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  100934:	01 c2                	add    %eax,%edx
  100936:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  100939:	89 50 4c             	mov    %edx,0x4c(%eax)
		cons.rpos = cons.wpos = 0;
  10093c:	c7 05 04 a2 17 00 00 	movl   $0x0,0x17a204
  100943:	00 00 00 
  100946:	a1 04 a2 17 00       	mov    0x17a204,%eax
  10094b:	a3 00 a2 17 00       	mov    %eax,0x17a200
		dildio = 1;
  100950:	c7 45 e8 01 00 00 00 	movl   $0x1,0xffffffe8(%ebp)
	}

	spinlock_release(&cons_lock);
  100957:	c7 04 24 40 ed 17 00 	movl   $0x17ed40,(%esp)
  10095e:	e8 52 32 00 00       	call   103bb5 <spinlock_release>
	return dildio;
  100963:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
}
  100966:	c9                   	leave  
  100967:	c3                   	ret    

00100968 <debug_panic>:
// Panic is called on unresolvable fatal errors.
// It prints "panic: mesg", and then enters the kernel monitor.
void
debug_panic(const char *file, int line, const char *fmt,...)
{
  100968:	55                   	push   %ebp
  100969:	89 e5                	mov    %esp,%ebp
  10096b:	83 ec 58             	sub    $0x58,%esp
static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  10096e:	8c 4d fa             	movw   %cs,0xfffffffa(%ebp)
        return cs;
  100971:	0f b7 45 fa          	movzwl 0xfffffffa(%ebp),%eax
	va_list ap;
	int i;

	// Avoid infinite recursion if we're panicking from kernel mode.
	if ((read_cs() & 3) == 0) {
  100975:	0f b7 c0             	movzwl %ax,%eax
  100978:	83 e0 03             	and    $0x3,%eax
  10097b:	85 c0                	test   %eax,%eax
  10097d:	75 15                	jne    100994 <debug_panic+0x2c>
		if (panicstr)
  10097f:	a1 0c a2 17 00       	mov    0x17a20c,%eax
  100984:	85 c0                	test   %eax,%eax
  100986:	0f 85 95 00 00 00    	jne    100a21 <debug_panic+0xb9>
			goto dead;
		panicstr = fmt;
  10098c:	8b 45 10             	mov    0x10(%ebp),%eax
  10098f:	a3 0c a2 17 00       	mov    %eax,0x17a20c
	}

	// First print the requested message
	va_start(ap, fmt);
  100994:	8d 45 10             	lea    0x10(%ebp),%eax
  100997:	83 c0 04             	add    $0x4,%eax
  10099a:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
	cprintf("kernel panic at %s:%d: ", file, line);
  10099d:	8b 45 0c             	mov    0xc(%ebp),%eax
  1009a0:	89 44 24 08          	mov    %eax,0x8(%esp)
  1009a4:	8b 45 08             	mov    0x8(%ebp),%eax
  1009a7:	89 44 24 04          	mov    %eax,0x4(%esp)
  1009ab:	c7 04 24 9d be 10 00 	movl   $0x10be9d,(%esp)
  1009b2:	e8 ba aa 00 00       	call   10b471 <cprintf>
	vcprintf(fmt, ap);
  1009b7:	8b 55 10             	mov    0x10(%ebp),%edx
  1009ba:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  1009bd:	89 44 24 04          	mov    %eax,0x4(%esp)
  1009c1:	89 14 24             	mov    %edx,(%esp)
  1009c4:	e8 3f aa 00 00       	call   10b408 <vcprintf>
	cprintf("\n");
  1009c9:	c7 04 24 b5 be 10 00 	movl   $0x10beb5,(%esp)
  1009d0:	e8 9c aa 00 00       	call   10b471 <cprintf>
static gcc_inline uint32_t
read_ebp(void)
{
        uint32_t ebp;
        __asm __volatile("movl %%ebp,%0" : "=rm" (ebp));
  1009d5:	89 6d fc             	mov    %ebp,0xfffffffc(%ebp)
        return ebp;
  1009d8:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  1009db:	89 c2                	mov    %eax,%edx
	va_end(ap);

	// Then print a backtrace of the kernel call chain
	uint32_t eips[DEBUG_TRACEFRAMES];
	debug_trace(read_ebp(), eips);
  1009dd:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
  1009e0:	89 44 24 04          	mov    %eax,0x4(%esp)
  1009e4:	89 14 24             	mov    %edx,(%esp)
  1009e7:	e8 83 00 00 00       	call   100a6f <debug_trace>
	for (i = 0; i < DEBUG_TRACEFRAMES && eips[i] != 0; i++)
  1009ec:	c7 45 f4 00 00 00 00 	movl   $0x0,0xfffffff4(%ebp)
  1009f3:	eb 1b                	jmp    100a10 <debug_panic+0xa8>
		cprintf("  from %08x\n", eips[i]);
  1009f5:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  1009f8:	8b 44 85 c8          	mov    0xffffffc8(%ebp,%eax,4),%eax
  1009fc:	89 44 24 04          	mov    %eax,0x4(%esp)
  100a00:	c7 04 24 b7 be 10 00 	movl   $0x10beb7,(%esp)
  100a07:	e8 65 aa 00 00       	call   10b471 <cprintf>
  100a0c:	83 45 f4 01          	addl   $0x1,0xfffffff4(%ebp)
  100a10:	83 7d f4 09          	cmpl   $0x9,0xfffffff4(%ebp)
  100a14:	7f 0b                	jg     100a21 <debug_panic+0xb9>
  100a16:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  100a19:	8b 44 85 c8          	mov    0xffffffc8(%ebp,%eax,4),%eax
  100a1d:	85 c0                	test   %eax,%eax
  100a1f:	75 d4                	jne    1009f5 <debug_panic+0x8d>

dead:
	done();		// enter infinite loop (see kern/init.c)
  100a21:	e8 4e fb ff ff       	call   100574 <done>

00100a26 <debug_warn>:
}

/* like panic, but don't */
void
debug_warn(const char *file, int line, const char *fmt,...)
{
  100a26:	55                   	push   %ebp
  100a27:	89 e5                	mov    %esp,%ebp
  100a29:	83 ec 28             	sub    $0x28,%esp
	va_list ap;

	va_start(ap, fmt);
  100a2c:	8d 45 10             	lea    0x10(%ebp),%eax
  100a2f:	83 c0 04             	add    $0x4,%eax
  100a32:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	cprintf("kernel warning at %s:%d: ", file, line);
  100a35:	8b 45 0c             	mov    0xc(%ebp),%eax
  100a38:	89 44 24 08          	mov    %eax,0x8(%esp)
  100a3c:	8b 45 08             	mov    0x8(%ebp),%eax
  100a3f:	89 44 24 04          	mov    %eax,0x4(%esp)
  100a43:	c7 04 24 c4 be 10 00 	movl   $0x10bec4,(%esp)
  100a4a:	e8 22 aa 00 00       	call   10b471 <cprintf>
	vcprintf(fmt, ap);
  100a4f:	8b 55 10             	mov    0x10(%ebp),%edx
  100a52:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  100a55:	89 44 24 04          	mov    %eax,0x4(%esp)
  100a59:	89 14 24             	mov    %edx,(%esp)
  100a5c:	e8 a7 a9 00 00       	call   10b408 <vcprintf>
	cprintf("\n");
  100a61:	c7 04 24 b5 be 10 00 	movl   $0x10beb5,(%esp)
  100a68:	e8 04 aa 00 00       	call   10b471 <cprintf>
	va_end(ap);
}
  100a6d:	c9                   	leave  
  100a6e:	c3                   	ret    

00100a6f <debug_trace>:

// Record the current call stack in eips[] by following the %ebp chain.
void gcc_noinline
debug_trace(uint32_t ebp, uint32_t eips[DEBUG_TRACEFRAMES])
{
  100a6f:	55                   	push   %ebp
  100a70:	89 e5                	mov    %esp,%ebp
  100a72:	83 ec 10             	sub    $0x10,%esp
//	panic("debug_trace not implemented");
  uint32_t *frame = (uint32_t *) ebp;
  100a75:	8b 45 08             	mov    0x8(%ebp),%eax
  100a78:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)

  int i;

  // Print the eip of the last n frames,
  // where n is DEBUG_TRACEFRAMES
  for (i = 0; i < DEBUG_TRACEFRAMES && frame; i++) {
  100a7b:	c7 45 fc 00 00 00 00 	movl   $0x0,0xfffffffc(%ebp)
  100a82:	eb 21                	jmp    100aa5 <debug_trace+0x36>
    // print relevent information about the stack
    //cprintf("ebp: %08x ", frame[0]);
    //cprintf("eip: %08x ", frame[1]);
    //cprintf("args: %08x %08x %08x %08x %08x ", frame[2], frame[3], frame[4], frame[5], frame[6]);
    //cprintf("\n"); 

    // add information to eips array
    eips[i] = frame[1];             // eip saved at ebp + 1
  100a84:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  100a87:	c1 e0 02             	shl    $0x2,%eax
  100a8a:	89 c2                	mov    %eax,%edx
  100a8c:	03 55 0c             	add    0xc(%ebp),%edx
  100a8f:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  100a92:	83 c0 04             	add    $0x4,%eax
  100a95:	8b 00                	mov    (%eax),%eax
  100a97:	89 02                	mov    %eax,(%edx)

    // move to the next frame up the stack
    frame = (uint32_t*)frame[0];  // prev ebp saved at ebp 0
  100a99:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  100a9c:	8b 00                	mov    (%eax),%eax
  100a9e:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  100aa1:	83 45 fc 01          	addl   $0x1,0xfffffffc(%ebp)
  100aa5:	83 7d fc 09          	cmpl   $0x9,0xfffffffc(%ebp)
  100aa9:	7f 1b                	jg     100ac6 <debug_trace+0x57>
  100aab:	83 7d f8 00          	cmpl   $0x0,0xfffffff8(%ebp)
  100aaf:	75 d3                	jne    100a84 <debug_trace+0x15>
  }

  // if the there are less than DEBUG_TRACEFRAMES frames,
  // print the rest as null
  for (i; i < DEBUG_TRACEFRAMES; i++) {
  100ab1:	eb 13                	jmp    100ac6 <debug_trace+0x57>
    eips[i] = 0; 
  100ab3:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  100ab6:	c1 e0 02             	shl    $0x2,%eax
  100ab9:	03 45 0c             	add    0xc(%ebp),%eax
  100abc:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  100ac2:	83 45 fc 01          	addl   $0x1,0xfffffffc(%ebp)
  100ac6:	83 7d fc 09          	cmpl   $0x9,0xfffffffc(%ebp)
  100aca:	7e e7                	jle    100ab3 <debug_trace+0x44>
  }
}
  100acc:	c9                   	leave  
  100acd:	c3                   	ret    

00100ace <f3>:


static void gcc_noinline f3(int r, uint32_t *e) { debug_trace(read_ebp(), e); }
  100ace:	55                   	push   %ebp
  100acf:	89 e5                	mov    %esp,%ebp
  100ad1:	83 ec 18             	sub    $0x18,%esp
static gcc_inline uint32_t
read_ebp(void)
{
        uint32_t ebp;
        __asm __volatile("movl %%ebp,%0" : "=rm" (ebp));
  100ad4:	89 6d fc             	mov    %ebp,0xfffffffc(%ebp)
        return ebp;
  100ad7:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  100ada:	89 c2                	mov    %eax,%edx
  100adc:	8b 45 0c             	mov    0xc(%ebp),%eax
  100adf:	89 44 24 04          	mov    %eax,0x4(%esp)
  100ae3:	89 14 24             	mov    %edx,(%esp)
  100ae6:	e8 84 ff ff ff       	call   100a6f <debug_trace>
  100aeb:	c9                   	leave  
  100aec:	c3                   	ret    

00100aed <f2>:
static void gcc_noinline f2(int r, uint32_t *e) { r & 2 ? f3(r,e) : f3(r,e); }
  100aed:	55                   	push   %ebp
  100aee:	89 e5                	mov    %esp,%ebp
  100af0:	83 ec 08             	sub    $0x8,%esp
  100af3:	8b 45 08             	mov    0x8(%ebp),%eax
  100af6:	83 e0 02             	and    $0x2,%eax
  100af9:	85 c0                	test   %eax,%eax
  100afb:	74 14                	je     100b11 <f2+0x24>
  100afd:	8b 45 0c             	mov    0xc(%ebp),%eax
  100b00:	89 44 24 04          	mov    %eax,0x4(%esp)
  100b04:	8b 45 08             	mov    0x8(%ebp),%eax
  100b07:	89 04 24             	mov    %eax,(%esp)
  100b0a:	e8 bf ff ff ff       	call   100ace <f3>
  100b0f:	eb 12                	jmp    100b23 <f2+0x36>
  100b11:	8b 45 0c             	mov    0xc(%ebp),%eax
  100b14:	89 44 24 04          	mov    %eax,0x4(%esp)
  100b18:	8b 45 08             	mov    0x8(%ebp),%eax
  100b1b:	89 04 24             	mov    %eax,(%esp)
  100b1e:	e8 ab ff ff ff       	call   100ace <f3>
  100b23:	c9                   	leave  
  100b24:	c3                   	ret    

00100b25 <f1>:
static void gcc_noinline f1(int r, uint32_t *e) { r & 1 ? f2(r,e) : f2(r,e); }
  100b25:	55                   	push   %ebp
  100b26:	89 e5                	mov    %esp,%ebp
  100b28:	83 ec 08             	sub    $0x8,%esp
  100b2b:	8b 45 08             	mov    0x8(%ebp),%eax
  100b2e:	83 e0 01             	and    $0x1,%eax
  100b31:	84 c0                	test   %al,%al
  100b33:	74 14                	je     100b49 <f1+0x24>
  100b35:	8b 45 0c             	mov    0xc(%ebp),%eax
  100b38:	89 44 24 04          	mov    %eax,0x4(%esp)
  100b3c:	8b 45 08             	mov    0x8(%ebp),%eax
  100b3f:	89 04 24             	mov    %eax,(%esp)
  100b42:	e8 a6 ff ff ff       	call   100aed <f2>
  100b47:	eb 12                	jmp    100b5b <f1+0x36>
  100b49:	8b 45 0c             	mov    0xc(%ebp),%eax
  100b4c:	89 44 24 04          	mov    %eax,0x4(%esp)
  100b50:	8b 45 08             	mov    0x8(%ebp),%eax
  100b53:	89 04 24             	mov    %eax,(%esp)
  100b56:	e8 92 ff ff ff       	call   100aed <f2>
  100b5b:	c9                   	leave  
  100b5c:	c3                   	ret    

00100b5d <debug_check>:

// Test the backtrace implementation for correct operation
void
debug_check(void)
{
  100b5d:	55                   	push   %ebp
  100b5e:	89 e5                	mov    %esp,%ebp
  100b60:	81 ec c8 00 00 00    	sub    $0xc8,%esp
	uint32_t eips[4][DEBUG_TRACEFRAMES];
	int r, i;

	// produce several related backtraces...
	for (i = 0; i < 4; i++)
  100b66:	c7 45 fc 00 00 00 00 	movl   $0x0,0xfffffffc(%ebp)
  100b6d:	eb 2a                	jmp    100b99 <debug_check+0x3c>
		f1(i, eips[i]);
  100b6f:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  100b72:	89 d0                	mov    %edx,%eax
  100b74:	c1 e0 02             	shl    $0x2,%eax
  100b77:	01 d0                	add    %edx,%eax
  100b79:	c1 e0 03             	shl    $0x3,%eax
  100b7c:	89 c2                	mov    %eax,%edx
  100b7e:	8d 85 58 ff ff ff    	lea    0xffffff58(%ebp),%eax
  100b84:	01 d0                	add    %edx,%eax
  100b86:	89 44 24 04          	mov    %eax,0x4(%esp)
  100b8a:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  100b8d:	89 04 24             	mov    %eax,(%esp)
  100b90:	e8 90 ff ff ff       	call   100b25 <f1>
  100b95:	83 45 fc 01          	addl   $0x1,0xfffffffc(%ebp)
  100b99:	83 7d fc 03          	cmpl   $0x3,0xfffffffc(%ebp)
  100b9d:	7e d0                	jle    100b6f <debug_check+0x12>

	// ...and make sure they come out correctly.
	for (r = 0; r < 4; r++)
  100b9f:	c7 45 f8 00 00 00 00 	movl   $0x0,0xfffffff8(%ebp)
  100ba6:	e9 bc 00 00 00       	jmp    100c67 <debug_check+0x10a>
		for (i = 0; i < DEBUG_TRACEFRAMES; i++) {
  100bab:	c7 45 fc 00 00 00 00 	movl   $0x0,0xfffffffc(%ebp)
  100bb2:	e9 a2 00 00 00       	jmp    100c59 <debug_check+0xfc>
			assert((eips[r][i] != 0) == (i < 5));
  100bb7:	8b 55 f8             	mov    0xfffffff8(%ebp),%edx
  100bba:	8b 4d fc             	mov    0xfffffffc(%ebp),%ecx
  100bbd:	89 d0                	mov    %edx,%eax
  100bbf:	c1 e0 02             	shl    $0x2,%eax
  100bc2:	01 d0                	add    %edx,%eax
  100bc4:	01 c0                	add    %eax,%eax
  100bc6:	01 c8                	add    %ecx,%eax
  100bc8:	8b 84 85 58 ff ff ff 	mov    0xffffff58(%ebp,%eax,4),%eax
  100bcf:	85 c0                	test   %eax,%eax
  100bd1:	0f 95 c2             	setne  %dl
  100bd4:	83 7d fc 04          	cmpl   $0x4,0xfffffffc(%ebp)
  100bd8:	0f 9e c0             	setle  %al
  100bdb:	31 d0                	xor    %edx,%eax
  100bdd:	84 c0                	test   %al,%al
  100bdf:	74 24                	je     100c05 <debug_check+0xa8>
  100be1:	c7 44 24 0c de be 10 	movl   $0x10bede,0xc(%esp)
  100be8:	00 
  100be9:	c7 44 24 08 fb be 10 	movl   $0x10befb,0x8(%esp)
  100bf0:	00 
  100bf1:	c7 44 24 04 7a 00 00 	movl   $0x7a,0x4(%esp)
  100bf8:	00 
  100bf9:	c7 04 24 10 bf 10 00 	movl   $0x10bf10,(%esp)
  100c00:	e8 63 fd ff ff       	call   100968 <debug_panic>
			if (i >= 2)
  100c05:	83 7d fc 01          	cmpl   $0x1,0xfffffffc(%ebp)
  100c09:	7e 4a                	jle    100c55 <debug_check+0xf8>
				assert(eips[r][i] == eips[0][i]);
  100c0b:	8b 55 f8             	mov    0xfffffff8(%ebp),%edx
  100c0e:	8b 4d fc             	mov    0xfffffffc(%ebp),%ecx
  100c11:	89 d0                	mov    %edx,%eax
  100c13:	c1 e0 02             	shl    $0x2,%eax
  100c16:	01 d0                	add    %edx,%eax
  100c18:	01 c0                	add    %eax,%eax
  100c1a:	01 c8                	add    %ecx,%eax
  100c1c:	8b 94 85 58 ff ff ff 	mov    0xffffff58(%ebp,%eax,4),%edx
  100c23:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  100c26:	8b 84 85 58 ff ff ff 	mov    0xffffff58(%ebp,%eax,4),%eax
  100c2d:	39 c2                	cmp    %eax,%edx
  100c2f:	74 24                	je     100c55 <debug_check+0xf8>
  100c31:	c7 44 24 0c 1d bf 10 	movl   $0x10bf1d,0xc(%esp)
  100c38:	00 
  100c39:	c7 44 24 08 fb be 10 	movl   $0x10befb,0x8(%esp)
  100c40:	00 
  100c41:	c7 44 24 04 7c 00 00 	movl   $0x7c,0x4(%esp)
  100c48:	00 
  100c49:	c7 04 24 10 bf 10 00 	movl   $0x10bf10,(%esp)
  100c50:	e8 13 fd ff ff       	call   100968 <debug_panic>
  100c55:	83 45 fc 01          	addl   $0x1,0xfffffffc(%ebp)
  100c59:	83 7d fc 09          	cmpl   $0x9,0xfffffffc(%ebp)
  100c5d:	0f 8e 54 ff ff ff    	jle    100bb7 <debug_check+0x5a>
  100c63:	83 45 f8 01          	addl   $0x1,0xfffffff8(%ebp)
  100c67:	83 7d f8 03          	cmpl   $0x3,0xfffffff8(%ebp)
  100c6b:	0f 8e 3a ff ff ff    	jle    100bab <debug_check+0x4e>
		}
	assert(eips[0][0] == eips[1][0]);
  100c71:	8b 95 58 ff ff ff    	mov    0xffffff58(%ebp),%edx
  100c77:	8b 45 80             	mov    0xffffff80(%ebp),%eax
  100c7a:	39 c2                	cmp    %eax,%edx
  100c7c:	74 24                	je     100ca2 <debug_check+0x145>
  100c7e:	c7 44 24 0c 36 bf 10 	movl   $0x10bf36,0xc(%esp)
  100c85:	00 
  100c86:	c7 44 24 08 fb be 10 	movl   $0x10befb,0x8(%esp)
  100c8d:	00 
  100c8e:	c7 44 24 04 7e 00 00 	movl   $0x7e,0x4(%esp)
  100c95:	00 
  100c96:	c7 04 24 10 bf 10 00 	movl   $0x10bf10,(%esp)
  100c9d:	e8 c6 fc ff ff       	call   100968 <debug_panic>
	assert(eips[2][0] == eips[3][0]);
  100ca2:	8b 55 a8             	mov    0xffffffa8(%ebp),%edx
  100ca5:	8b 45 d0             	mov    0xffffffd0(%ebp),%eax
  100ca8:	39 c2                	cmp    %eax,%edx
  100caa:	74 24                	je     100cd0 <debug_check+0x173>
  100cac:	c7 44 24 0c 4f bf 10 	movl   $0x10bf4f,0xc(%esp)
  100cb3:	00 
  100cb4:	c7 44 24 08 fb be 10 	movl   $0x10befb,0x8(%esp)
  100cbb:	00 
  100cbc:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
  100cc3:	00 
  100cc4:	c7 04 24 10 bf 10 00 	movl   $0x10bf10,(%esp)
  100ccb:	e8 98 fc ff ff       	call   100968 <debug_panic>
	assert(eips[1][0] != eips[2][0]);
  100cd0:	8b 55 80             	mov    0xffffff80(%ebp),%edx
  100cd3:	8b 45 a8             	mov    0xffffffa8(%ebp),%eax
  100cd6:	39 c2                	cmp    %eax,%edx
  100cd8:	75 24                	jne    100cfe <debug_check+0x1a1>
  100cda:	c7 44 24 0c 68 bf 10 	movl   $0x10bf68,0xc(%esp)
  100ce1:	00 
  100ce2:	c7 44 24 08 fb be 10 	movl   $0x10befb,0x8(%esp)
  100ce9:	00 
  100cea:	c7 44 24 04 80 00 00 	movl   $0x80,0x4(%esp)
  100cf1:	00 
  100cf2:	c7 04 24 10 bf 10 00 	movl   $0x10bf10,(%esp)
  100cf9:	e8 6a fc ff ff       	call   100968 <debug_panic>
	assert(eips[0][1] == eips[2][1]);
  100cfe:	8b 95 5c ff ff ff    	mov    0xffffff5c(%ebp),%edx
  100d04:	8b 45 ac             	mov    0xffffffac(%ebp),%eax
  100d07:	39 c2                	cmp    %eax,%edx
  100d09:	74 24                	je     100d2f <debug_check+0x1d2>
  100d0b:	c7 44 24 0c 81 bf 10 	movl   $0x10bf81,0xc(%esp)
  100d12:	00 
  100d13:	c7 44 24 08 fb be 10 	movl   $0x10befb,0x8(%esp)
  100d1a:	00 
  100d1b:	c7 44 24 04 81 00 00 	movl   $0x81,0x4(%esp)
  100d22:	00 
  100d23:	c7 04 24 10 bf 10 00 	movl   $0x10bf10,(%esp)
  100d2a:	e8 39 fc ff ff       	call   100968 <debug_panic>
	assert(eips[1][1] == eips[3][1]);
  100d2f:	8b 55 84             	mov    0xffffff84(%ebp),%edx
  100d32:	8b 45 d4             	mov    0xffffffd4(%ebp),%eax
  100d35:	39 c2                	cmp    %eax,%edx
  100d37:	74 24                	je     100d5d <debug_check+0x200>
  100d39:	c7 44 24 0c 9a bf 10 	movl   $0x10bf9a,0xc(%esp)
  100d40:	00 
  100d41:	c7 44 24 08 fb be 10 	movl   $0x10befb,0x8(%esp)
  100d48:	00 
  100d49:	c7 44 24 04 82 00 00 	movl   $0x82,0x4(%esp)
  100d50:	00 
  100d51:	c7 04 24 10 bf 10 00 	movl   $0x10bf10,(%esp)
  100d58:	e8 0b fc ff ff       	call   100968 <debug_panic>
	assert(eips[0][1] != eips[1][1]);
  100d5d:	8b 95 5c ff ff ff    	mov    0xffffff5c(%ebp),%edx
  100d63:	8b 45 84             	mov    0xffffff84(%ebp),%eax
  100d66:	39 c2                	cmp    %eax,%edx
  100d68:	75 24                	jne    100d8e <debug_check+0x231>
  100d6a:	c7 44 24 0c b3 bf 10 	movl   $0x10bfb3,0xc(%esp)
  100d71:	00 
  100d72:	c7 44 24 08 fb be 10 	movl   $0x10befb,0x8(%esp)
  100d79:	00 
  100d7a:	c7 44 24 04 83 00 00 	movl   $0x83,0x4(%esp)
  100d81:	00 
  100d82:	c7 04 24 10 bf 10 00 	movl   $0x10bf10,(%esp)
  100d89:	e8 da fb ff ff       	call   100968 <debug_panic>

	cprintf("debug_check() succeeded!\n");
  100d8e:	c7 04 24 cc bf 10 00 	movl   $0x10bfcc,(%esp)
  100d95:	e8 d7 a6 00 00       	call   10b471 <cprintf>
}
  100d9a:	c9                   	leave  
  100d9b:	c3                   	ret    

00100d9c <mem_init>:
void mem_check(void);

void
mem_init(void)
{
  100d9c:	55                   	push   %ebp
  100d9d:	89 e5                	mov    %esp,%ebp
  100d9f:	83 ec 48             	sub    $0x48,%esp
	if (!cpu_onboot())	// only do once, on the boot CPU
  100da2:	e8 39 02 00 00       	call   100fe0 <cpu_onboot>
  100da7:	85 c0                	test   %eax,%eax
  100da9:	0f 84 2f 02 00 00    	je     100fde <mem_init+0x242>
		return;

	// Determine how much base (<640K) and extended (>1MB) memory
	// is available in the system (in bytes),
	// by reading the PC's BIOS-managed nonvolatile RAM (NVRAM).
	// The NVRAM tells us how many kilobytes there are.
	// Since the count is 16 bits, this gives us up to 64MB of RAM;
	// additional RAM beyond that would have to be detected another way.
	size_t basemem = ROUNDDOWN(nvram_read16(NVRAM_BASELO)*1024, PAGESIZE);
  100daf:	c7 04 24 15 00 00 00 	movl   $0x15,(%esp)
  100db6:	e8 56 99 00 00       	call   10a711 <nvram_read16>
  100dbb:	c1 e0 0a             	shl    $0xa,%eax
  100dbe:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  100dc1:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  100dc4:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  100dc9:	89 45 dc             	mov    %eax,0xffffffdc(%ebp)
	size_t extmem = ROUNDDOWN(nvram_read16(NVRAM_EXTLO)*1024, PAGESIZE);
  100dcc:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
  100dd3:	e8 39 99 00 00       	call   10a711 <nvram_read16>
  100dd8:	c1 e0 0a             	shl    $0xa,%eax
  100ddb:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
  100dde:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  100de1:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  100de6:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)

	warn("Assuming we have 1GB of memory!");
  100de9:	c7 44 24 08 e8 bf 10 	movl   $0x10bfe8,0x8(%esp)
  100df0:	00 
  100df1:	c7 44 24 04 33 00 00 	movl   $0x33,0x4(%esp)
  100df8:	00 
  100df9:	c7 04 24 08 c0 10 00 	movl   $0x10c008,(%esp)
  100e00:	e8 21 fc ff ff       	call   100a26 <debug_warn>
	extmem = 1024*1024*1024 - MEM_EXT;	// assume 1GB total memory
  100e05:	c7 45 e0 00 00 f0 3f 	movl   $0x3ff00000,0xffffffe0(%ebp)

	// The maximum physical address is the top of extended memory.
	mem_max = MEM_EXT + extmem;
  100e0c:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  100e0f:	05 00 00 10 00       	add    $0x100000,%eax
  100e14:	a3 d8 ed 17 00       	mov    %eax,0x17edd8

	// Compute the total number of physical pages (including I/O holes)
	mem_npage = mem_max / PAGESIZE;
  100e19:	a1 d8 ed 17 00       	mov    0x17edd8,%eax
  100e1e:	c1 e8 0c             	shr    $0xc,%eax
  100e21:	a3 84 ed 17 00       	mov    %eax,0x17ed84

	cprintf("Physical memory: %dK available, ", (int)(mem_max/1024));
  100e26:	a1 d8 ed 17 00       	mov    0x17edd8,%eax
  100e2b:	c1 e8 0a             	shr    $0xa,%eax
  100e2e:	89 44 24 04          	mov    %eax,0x4(%esp)
  100e32:	c7 04 24 14 c0 10 00 	movl   $0x10c014,(%esp)
  100e39:	e8 33 a6 00 00       	call   10b471 <cprintf>
	cprintf("base = %dK, extended = %dK\n",
  100e3e:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  100e41:	c1 e8 0a             	shr    $0xa,%eax
  100e44:	89 c2                	mov    %eax,%edx
  100e46:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  100e49:	c1 e8 0a             	shr    $0xa,%eax
  100e4c:	89 54 24 08          	mov    %edx,0x8(%esp)
  100e50:	89 44 24 04          	mov    %eax,0x4(%esp)
  100e54:	c7 04 24 35 c0 10 00 	movl   $0x10c035,(%esp)
  100e5b:	e8 11 a6 00 00       	call   10b471 <cprintf>
		(int)(basemem/1024), (int)(extmem/1024));


	// Insert code here to:
	// (1)	allocate physical memory for the mem_pageinfo array,
	//	making it big enough to hold mem_npage entries.
	// (2)	add all pageinfo structs in the array representing
	//	available memory that is not in use for other purposes.
	//
	// For step (2), here is some incomplete/incorrect example code
	// that simply marks all mem_npage pages as free.
	// Which memory is actually free?
	//  1) Reserve page 0 for the real-mode IDT and BIOS structures
	//     (do not allow this page to be used for anything else).
	//  2) Reserve page 1 for the AP bootstrap code (boot/bootother.S).
	//  3) Mark the rest of base memory as free.
	//  4) Then comes the IO hole [MEM_IO, MEM_EXT).
	//     Mark it as in-use so that it can never be allocated.      
	//  5) Then extended memory [MEM_EXT, ...).
	//     Some of it is in use, some is free.
	//     Which pages hold the kernel and the pageinfo array?
	//     Hint: the linker places the kernel (see start and end above),
	//     but YOU decide where to place the pageinfo array.
	// Change the code to reflect this.

	// ...and remove this when you're ready.
//panic("mem_init() not implemented");
  // start at the beginning of memeory
  mem_pageinfo = (pageinfo *) ROUNDUP(((int)end), sizeof(pageinfo));
  100e60:	c7 45 f4 08 00 00 00 	movl   $0x8,0xfffffff4(%ebp)
  100e67:	b8 08 20 18 00       	mov    $0x182008,%eax
  100e6c:	83 e8 01             	sub    $0x1,%eax
  100e6f:	03 45 f4             	add    0xfffffff4(%ebp),%eax
  100e72:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  100e75:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  100e78:	ba 00 00 00 00       	mov    $0x0,%edx
  100e7d:	f7 75 f4             	divl   0xfffffff4(%ebp)
  100e80:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  100e83:	29 d0                	sub    %edx,%eax
  100e85:	a3 dc ed 17 00       	mov    %eax,0x17eddc

  // set it all to zero
  memset(mem_pageinfo, 0, sizeof(pageinfo) * mem_npage);
  100e8a:	a1 84 ed 17 00       	mov    0x17ed84,%eax
  100e8f:	c1 e0 03             	shl    $0x3,%eax
  100e92:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  100e98:	89 44 24 08          	mov    %eax,0x8(%esp)
  100e9c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  100ea3:	00 
  100ea4:	89 14 24             	mov    %edx,(%esp)
  100ea7:	e8 49 a9 00 00       	call   10b7f5 <memset>

  spinlock_init(&page_spinlock);
  100eac:	c7 44 24 08 5f 00 00 	movl   $0x5f,0x8(%esp)
  100eb3:	00 
  100eb4:	c7 44 24 04 08 c0 10 	movl   $0x10c008,0x4(%esp)
  100ebb:	00 
  100ebc:	c7 04 24 a0 ed 17 00 	movl   $0x17eda0,(%esp)
  100ec3:	e8 c8 2b 00 00       	call   103a90 <spinlock_init_>

	pageinfo **freetail = &mem_freelist;
  100ec8:	c7 45 e4 80 ed 17 00 	movl   $0x17ed80,0xffffffe4(%ebp)

	int i;
	for (i = 0; i < mem_npage; i++) {
  100ecf:	c7 45 e8 00 00 00 00 	movl   $0x0,0xffffffe8(%ebp)
  100ed6:	e9 e5 00 00 00       	jmp    100fc0 <mem_init+0x224>

    // physical address of current pageinfo
    uint32_t paddr = mem_pi2phys(mem_pageinfo + i);
  100edb:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  100ede:	c1 e0 03             	shl    $0x3,%eax
  100ee1:	89 c2                	mov    %eax,%edx
  100ee3:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  100ee8:	8d 04 02             	lea    (%edx,%eax,1),%eax
  100eeb:	89 c2                	mov    %eax,%edx
  100eed:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  100ef2:	89 d1                	mov    %edx,%ecx
  100ef4:	29 c1                	sub    %eax,%ecx
  100ef6:	89 c8                	mov    %ecx,%eax
  100ef8:	c1 e0 09             	shl    $0x9,%eax
  100efb:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
    if ((i == 0 || i == 1 || // pages 0 and 1 are reserved for idt, bios, and bootstrap (see above)
  100efe:	83 7d e8 00          	cmpl   $0x0,0xffffffe8(%ebp)
  100f02:	74 61                	je     100f65 <mem_init+0x1c9>
  100f04:	83 7d e8 01          	cmpl   $0x1,0xffffffe8(%ebp)
  100f08:	74 5b                	je     100f65 <mem_init+0x1c9>
  100f0a:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  100f0d:	05 00 10 00 00       	add    $0x1000,%eax
  100f12:	3d ff ff 09 00       	cmp    $0x9ffff,%eax
  100f17:	76 09                	jbe    100f22 <mem_init+0x186>
  100f19:	81 7d fc ff ff 0f 00 	cmpl   $0xfffff,0xfffffffc(%ebp)
  100f20:	76 43                	jbe    100f65 <mem_init+0x1c9>
  100f22:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  100f25:	05 00 10 00 00       	add    $0x1000,%eax
  100f2a:	ba 0c 00 10 00       	mov    $0x10000c,%edx
  100f2f:	39 d0                	cmp    %edx,%eax
  100f31:	72 0a                	jb     100f3d <mem_init+0x1a1>
  100f33:	b8 08 20 18 00       	mov    $0x182008,%eax
  100f38:	39 45 fc             	cmp    %eax,0xfffffffc(%ebp)
  100f3b:	72 28                	jb     100f65 <mem_init+0x1c9>
  100f3d:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  100f40:	05 00 10 00 00       	add    $0x1000,%eax
  100f45:	ba dc ed 17 00       	mov    $0x17eddc,%edx
  100f4a:	39 d0                	cmp    %edx,%eax
  100f4c:	72 30                	jb     100f7e <mem_init+0x1e2>
  100f4e:	a1 84 ed 17 00       	mov    0x17ed84,%eax
  100f53:	c1 e0 03             	shl    $0x3,%eax
  100f56:	89 c2                	mov    %eax,%edx
  100f58:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  100f5d:	8d 04 02             	lea    (%edx,%eax,1),%eax
  100f60:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  100f63:	76 19                	jbe    100f7e <mem_init+0x1e2>
          (paddr + PAGESIZE >= MEM_IO && paddr < MEM_EXT) || // IO section is reserved
          (paddr + PAGESIZE >= (uint32_t) &start[0] && paddr < (uint32_t) &end[0]) || // kernel, 
          (paddr + PAGESIZE >= (uint32_t) &mem_pageinfo && // start of pageinfo array
           paddr < (uint32_t) &mem_pageinfo[mem_npage]) // end of pageinfo array
     )) {
      mem_pageinfo[i].refcount = 1; 
  100f65:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  100f68:	c1 e0 03             	shl    $0x3,%eax
  100f6b:	89 c2                	mov    %eax,%edx
  100f6d:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  100f72:	8d 04 02             	lea    (%edx,%eax,1),%eax
  100f75:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
  100f7c:	eb 3e                	jmp    100fbc <mem_init+0x220>
    } else {
      mem_pageinfo[i].refcount = 0; 
  100f7e:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  100f81:	c1 e0 03             	shl    $0x3,%eax
  100f84:	89 c2                	mov    %eax,%edx
  100f86:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  100f8b:	8d 04 02             	lea    (%edx,%eax,1),%eax
  100f8e:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
      // Add the page to the end of the free list.
      *freetail = &mem_pageinfo[i];
  100f95:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  100f98:	c1 e0 03             	shl    $0x3,%eax
  100f9b:	89 c2                	mov    %eax,%edx
  100f9d:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  100fa2:	01 c2                	add    %eax,%edx
  100fa4:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  100fa7:	89 10                	mov    %edx,(%eax)
      freetail = &mem_pageinfo[i].free_next;
  100fa9:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  100fac:	c1 e0 03             	shl    $0x3,%eax
  100faf:	89 c2                	mov    %eax,%edx
  100fb1:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  100fb6:	8d 04 02             	lea    (%edx,%eax,1),%eax
  100fb9:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
  100fbc:	83 45 e8 01          	addl   $0x1,0xffffffe8(%ebp)
  100fc0:	8b 55 e8             	mov    0xffffffe8(%ebp),%edx
  100fc3:	a1 84 ed 17 00       	mov    0x17ed84,%eax
  100fc8:	39 c2                	cmp    %eax,%edx
  100fca:	0f 82 0b ff ff ff    	jb     100edb <mem_init+0x13f>
    }
	}

	*freetail = NULL;	// null-terminate the freelist
  100fd0:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  100fd3:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

	// Check to make sure the page allocator seems to work correctly.
	mem_check();
  100fd9:	e8 2e 01 00 00       	call   10110c <mem_check>
}
  100fde:	c9                   	leave  
  100fdf:	c3                   	ret    

00100fe0 <cpu_onboot>:
}

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  100fe0:	55                   	push   %ebp
  100fe1:	89 e5                	mov    %esp,%ebp
  100fe3:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  100fe6:	e8 0d 00 00 00       	call   100ff8 <cpu_cur>
  100feb:	3d 00 e0 10 00       	cmp    $0x10e000,%eax
  100ff0:	0f 94 c0             	sete   %al
  100ff3:	0f b6 c0             	movzbl %al,%eax
}
  100ff6:	c9                   	leave  
  100ff7:	c3                   	ret    

00100ff8 <cpu_cur>:
  100ff8:	55                   	push   %ebp
  100ff9:	89 e5                	mov    %esp,%ebp
  100ffb:	83 ec 28             	sub    $0x28,%esp
static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  100ffe:	89 65 fc             	mov    %esp,0xfffffffc(%ebp)
        return esp;
  101001:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  101004:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  101007:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10100a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  10100f:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	assert(c->magic == CPU_MAGIC);
  101012:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  101015:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  10101b:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  101020:	74 24                	je     101046 <cpu_cur+0x4e>
  101022:	c7 44 24 0c 51 c0 10 	movl   $0x10c051,0xc(%esp)
  101029:	00 
  10102a:	c7 44 24 08 67 c0 10 	movl   $0x10c067,0x8(%esp)
  101031:	00 
  101032:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  101039:	00 
  10103a:	c7 04 24 7c c0 10 00 	movl   $0x10c07c,(%esp)
  101041:	e8 22 f9 ff ff       	call   100968 <debug_panic>
	return c;
  101046:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
}
  101049:	c9                   	leave  
  10104a:	c3                   	ret    

0010104b <mem_alloc>:

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
  10104b:	55                   	push   %ebp
  10104c:	89 e5                	mov    %esp,%ebp
  10104e:	83 ec 18             	sub    $0x18,%esp
	// Fill this function in
	// Fill this function in.
//	panic("mem_alloc not implemented.");
  spinlock_acquire(&page_spinlock);
  101051:	c7 04 24 a0 ed 17 00 	movl   $0x17eda0,(%esp)
  101058:	e8 5d 2a 00 00       	call   103aba <spinlock_acquire>
  pageinfo *pi = mem_freelist;
  10105d:	a1 80 ed 17 00       	mov    0x17ed80,%eax
  101062:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  if (pi != NULL) {
  101065:	83 7d fc 00          	cmpl   $0x0,0xfffffffc(%ebp)
  101069:	74 13                	je     10107e <mem_alloc+0x33>
    mem_freelist = pi->free_next; // move front of list to next pageinfo
  10106b:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  10106e:	8b 00                	mov    (%eax),%eax
  101070:	a3 80 ed 17 00       	mov    %eax,0x17ed80
    pi->free_next = NULL; // remove pointer to next item
  101075:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  101078:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  }
  spinlock_release(&page_spinlock);
  10107e:	c7 04 24 a0 ed 17 00 	movl   $0x17eda0,(%esp)
  101085:	e8 2b 2b 00 00       	call   103bb5 <spinlock_release>
  return pi;
  10108a:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
}
  10108d:	c9                   	leave  
  10108e:	c3                   	ret    

0010108f <mem_free>:

//
// Return a page to the free list, given its pageinfo pointer.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
mem_free(pageinfo *pi)
{
  10108f:	55                   	push   %ebp
  101090:	89 e5                	mov    %esp,%ebp
  101092:	83 ec 18             	sub    $0x18,%esp
	// Fill this function in.
	//panic("mem_free not implemented.");
  // do not free in use, or already free pages
  if (pi->refcount != 0)
  101095:	8b 45 08             	mov    0x8(%ebp),%eax
  101098:	8b 40 04             	mov    0x4(%eax),%eax
  10109b:	85 c0                	test   %eax,%eax
  10109d:	74 1c                	je     1010bb <mem_free+0x2c>
    panic("mem_free: refcound does not equal zero");
  10109f:	c7 44 24 08 8c c0 10 	movl   $0x10c08c,0x8(%esp)
  1010a6:	00 
  1010a7:	c7 44 24 04 a3 00 00 	movl   $0xa3,0x4(%esp)
  1010ae:	00 
  1010af:	c7 04 24 08 c0 10 00 	movl   $0x10c008,(%esp)
  1010b6:	e8 ad f8 ff ff       	call   100968 <debug_panic>
  if (pi->free_next != NULL)
  1010bb:	8b 45 08             	mov    0x8(%ebp),%eax
  1010be:	8b 00                	mov    (%eax),%eax
  1010c0:	85 c0                	test   %eax,%eax
  1010c2:	74 1c                	je     1010e0 <mem_free+0x51>
    panic("mem_free: attempt to free already free page");
  1010c4:	c7 44 24 08 b4 c0 10 	movl   $0x10c0b4,0x8(%esp)
  1010cb:	00 
  1010cc:	c7 44 24 04 a5 00 00 	movl   $0xa5,0x4(%esp)
  1010d3:	00 
  1010d4:	c7 04 24 08 c0 10 00 	movl   $0x10c008,(%esp)
  1010db:	e8 88 f8 ff ff       	call   100968 <debug_panic>

  spinlock_acquire(&page_spinlock);
  1010e0:	c7 04 24 a0 ed 17 00 	movl   $0x17eda0,(%esp)
  1010e7:	e8 ce 29 00 00       	call   103aba <spinlock_acquire>
  pi->free_next = mem_freelist; // point this to the list
  1010ec:	a1 80 ed 17 00       	mov    0x17ed80,%eax
  1010f1:	8b 55 08             	mov    0x8(%ebp),%edx
  1010f4:	89 02                	mov    %eax,(%edx)
  mem_freelist = pi; // point the front of the list to this
  1010f6:	8b 45 08             	mov    0x8(%ebp),%eax
  1010f9:	a3 80 ed 17 00       	mov    %eax,0x17ed80
  spinlock_release(&page_spinlock);
  1010fe:	c7 04 24 a0 ed 17 00 	movl   $0x17eda0,(%esp)
  101105:	e8 ab 2a 00 00       	call   103bb5 <spinlock_release>
}
  10110a:	c9                   	leave  
  10110b:	c3                   	ret    

0010110c <mem_check>:

//
// Check the physical page allocator (mem_alloc(), mem_free())
// for correct operation after initialization via mem_init().
//
void
mem_check()
{
  10110c:	55                   	push   %ebp
  10110d:	89 e5                	mov    %esp,%ebp
  10110f:	83 ec 38             	sub    $0x38,%esp
	pageinfo *pp, *pp0, *pp1, *pp2;
	pageinfo *fl;
	int i;

        // if there's a page that shouldn't be on
        // the free list, try to make sure it
        // eventually causes trouble.
	int freepages = 0;
  101112:	c7 45 fc 00 00 00 00 	movl   $0x0,0xfffffffc(%ebp)
	for (pp = mem_freelist; pp != 0; pp = pp->free_next) {
  101119:	a1 80 ed 17 00       	mov    0x17ed80,%eax
  10111e:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
  101121:	eb 35                	jmp    101158 <mem_check+0x4c>
		memset(mem_pi2ptr(pp), 0x97, 128);
  101123:	8b 55 e4             	mov    0xffffffe4(%ebp),%edx
  101126:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  10112b:	89 d1                	mov    %edx,%ecx
  10112d:	29 c1                	sub    %eax,%ecx
  10112f:	89 c8                	mov    %ecx,%eax
  101131:	c1 e0 09             	shl    $0x9,%eax
  101134:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
  10113b:	00 
  10113c:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
  101143:	00 
  101144:	89 04 24             	mov    %eax,(%esp)
  101147:	e8 a9 a6 00 00       	call   10b7f5 <memset>
		freepages++;
  10114c:	83 45 fc 01          	addl   $0x1,0xfffffffc(%ebp)
  101150:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  101153:	8b 00                	mov    (%eax),%eax
  101155:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
  101158:	83 7d e4 00          	cmpl   $0x0,0xffffffe4(%ebp)
  10115c:	75 c5                	jne    101123 <mem_check+0x17>
	}
	cprintf("mem_check: %d free pages\n", freepages);
  10115e:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  101161:	89 44 24 04          	mov    %eax,0x4(%esp)
  101165:	c7 04 24 e0 c0 10 00 	movl   $0x10c0e0,(%esp)
  10116c:	e8 00 a3 00 00       	call   10b471 <cprintf>
	assert(freepages < mem_npage);	// can't have more free than total!
  101171:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  101174:	a1 84 ed 17 00       	mov    0x17ed84,%eax
  101179:	39 c2                	cmp    %eax,%edx
  10117b:	72 24                	jb     1011a1 <mem_check+0x95>
  10117d:	c7 44 24 0c fa c0 10 	movl   $0x10c0fa,0xc(%esp)
  101184:	00 
  101185:	c7 44 24 08 67 c0 10 	movl   $0x10c067,0x8(%esp)
  10118c:	00 
  10118d:	c7 44 24 04 c1 00 00 	movl   $0xc1,0x4(%esp)
  101194:	00 
  101195:	c7 04 24 08 c0 10 00 	movl   $0x10c008,(%esp)
  10119c:	e8 c7 f7 ff ff       	call   100968 <debug_panic>
	assert(freepages > 16000);	// make sure it's in the right ballpark
  1011a1:	81 7d fc 80 3e 00 00 	cmpl   $0x3e80,0xfffffffc(%ebp)
  1011a8:	7f 24                	jg     1011ce <mem_check+0xc2>
  1011aa:	c7 44 24 0c 10 c1 10 	movl   $0x10c110,0xc(%esp)
  1011b1:	00 
  1011b2:	c7 44 24 08 67 c0 10 	movl   $0x10c067,0x8(%esp)
  1011b9:	00 
  1011ba:	c7 44 24 04 c2 00 00 	movl   $0xc2,0x4(%esp)
  1011c1:	00 
  1011c2:	c7 04 24 08 c0 10 00 	movl   $0x10c008,(%esp)
  1011c9:	e8 9a f7 ff ff       	call   100968 <debug_panic>

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
  1011ce:	c7 45 f0 00 00 00 00 	movl   $0x0,0xfffffff0(%ebp)
  1011d5:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  1011d8:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  1011db:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  1011de:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
	pp0 = mem_alloc(); assert(pp0 != 0);
  1011e1:	e8 65 fe ff ff       	call   10104b <mem_alloc>
  1011e6:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  1011e9:	83 7d e8 00          	cmpl   $0x0,0xffffffe8(%ebp)
  1011ed:	75 24                	jne    101213 <mem_check+0x107>
  1011ef:	c7 44 24 0c 22 c1 10 	movl   $0x10c122,0xc(%esp)
  1011f6:	00 
  1011f7:	c7 44 24 08 67 c0 10 	movl   $0x10c067,0x8(%esp)
  1011fe:	00 
  1011ff:	c7 44 24 04 c6 00 00 	movl   $0xc6,0x4(%esp)
  101206:	00 
  101207:	c7 04 24 08 c0 10 00 	movl   $0x10c008,(%esp)
  10120e:	e8 55 f7 ff ff       	call   100968 <debug_panic>
	pp1 = mem_alloc(); assert(pp1 != 0);
  101213:	e8 33 fe ff ff       	call   10104b <mem_alloc>
  101218:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  10121b:	83 7d ec 00          	cmpl   $0x0,0xffffffec(%ebp)
  10121f:	75 24                	jne    101245 <mem_check+0x139>
  101221:	c7 44 24 0c 2b c1 10 	movl   $0x10c12b,0xc(%esp)
  101228:	00 
  101229:	c7 44 24 08 67 c0 10 	movl   $0x10c067,0x8(%esp)
  101230:	00 
  101231:	c7 44 24 04 c7 00 00 	movl   $0xc7,0x4(%esp)
  101238:	00 
  101239:	c7 04 24 08 c0 10 00 	movl   $0x10c008,(%esp)
  101240:	e8 23 f7 ff ff       	call   100968 <debug_panic>
	pp2 = mem_alloc(); assert(pp2 != 0);
  101245:	e8 01 fe ff ff       	call   10104b <mem_alloc>
  10124a:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
  10124d:	83 7d f0 00          	cmpl   $0x0,0xfffffff0(%ebp)
  101251:	75 24                	jne    101277 <mem_check+0x16b>
  101253:	c7 44 24 0c 34 c1 10 	movl   $0x10c134,0xc(%esp)
  10125a:	00 
  10125b:	c7 44 24 08 67 c0 10 	movl   $0x10c067,0x8(%esp)
  101262:	00 
  101263:	c7 44 24 04 c8 00 00 	movl   $0xc8,0x4(%esp)
  10126a:	00 
  10126b:	c7 04 24 08 c0 10 00 	movl   $0x10c008,(%esp)
  101272:	e8 f1 f6 ff ff       	call   100968 <debug_panic>

	assert(pp0);
  101277:	83 7d e8 00          	cmpl   $0x0,0xffffffe8(%ebp)
  10127b:	75 24                	jne    1012a1 <mem_check+0x195>
  10127d:	c7 44 24 0c 3d c1 10 	movl   $0x10c13d,0xc(%esp)
  101284:	00 
  101285:	c7 44 24 08 67 c0 10 	movl   $0x10c067,0x8(%esp)
  10128c:	00 
  10128d:	c7 44 24 04 ca 00 00 	movl   $0xca,0x4(%esp)
  101294:	00 
  101295:	c7 04 24 08 c0 10 00 	movl   $0x10c008,(%esp)
  10129c:	e8 c7 f6 ff ff       	call   100968 <debug_panic>
	assert(pp1 && pp1 != pp0);
  1012a1:	83 7d ec 00          	cmpl   $0x0,0xffffffec(%ebp)
  1012a5:	74 08                	je     1012af <mem_check+0x1a3>
  1012a7:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  1012aa:	3b 45 e8             	cmp    0xffffffe8(%ebp),%eax
  1012ad:	75 24                	jne    1012d3 <mem_check+0x1c7>
  1012af:	c7 44 24 0c 41 c1 10 	movl   $0x10c141,0xc(%esp)
  1012b6:	00 
  1012b7:	c7 44 24 08 67 c0 10 	movl   $0x10c067,0x8(%esp)
  1012be:	00 
  1012bf:	c7 44 24 04 cb 00 00 	movl   $0xcb,0x4(%esp)
  1012c6:	00 
  1012c7:	c7 04 24 08 c0 10 00 	movl   $0x10c008,(%esp)
  1012ce:	e8 95 f6 ff ff       	call   100968 <debug_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
  1012d3:	83 7d f0 00          	cmpl   $0x0,0xfffffff0(%ebp)
  1012d7:	74 10                	je     1012e9 <mem_check+0x1dd>
  1012d9:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  1012dc:	3b 45 ec             	cmp    0xffffffec(%ebp),%eax
  1012df:	74 08                	je     1012e9 <mem_check+0x1dd>
  1012e1:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  1012e4:	3b 45 e8             	cmp    0xffffffe8(%ebp),%eax
  1012e7:	75 24                	jne    10130d <mem_check+0x201>
  1012e9:	c7 44 24 0c 54 c1 10 	movl   $0x10c154,0xc(%esp)
  1012f0:	00 
  1012f1:	c7 44 24 08 67 c0 10 	movl   $0x10c067,0x8(%esp)
  1012f8:	00 
  1012f9:	c7 44 24 04 cc 00 00 	movl   $0xcc,0x4(%esp)
  101300:	00 
  101301:	c7 04 24 08 c0 10 00 	movl   $0x10c008,(%esp)
  101308:	e8 5b f6 ff ff       	call   100968 <debug_panic>
        assert(mem_pi2phys(pp0) < mem_npage*PAGESIZE);
  10130d:	8b 55 e8             	mov    0xffffffe8(%ebp),%edx
  101310:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  101315:	89 d1                	mov    %edx,%ecx
  101317:	29 c1                	sub    %eax,%ecx
  101319:	89 c8                	mov    %ecx,%eax
  10131b:	c1 e0 09             	shl    $0x9,%eax
  10131e:	89 c2                	mov    %eax,%edx
  101320:	a1 84 ed 17 00       	mov    0x17ed84,%eax
  101325:	c1 e0 0c             	shl    $0xc,%eax
  101328:	39 c2                	cmp    %eax,%edx
  10132a:	72 24                	jb     101350 <mem_check+0x244>
  10132c:	c7 44 24 0c 74 c1 10 	movl   $0x10c174,0xc(%esp)
  101333:	00 
  101334:	c7 44 24 08 67 c0 10 	movl   $0x10c067,0x8(%esp)
  10133b:	00 
  10133c:	c7 44 24 04 cd 00 00 	movl   $0xcd,0x4(%esp)
  101343:	00 
  101344:	c7 04 24 08 c0 10 00 	movl   $0x10c008,(%esp)
  10134b:	e8 18 f6 ff ff       	call   100968 <debug_panic>
        assert(mem_pi2phys(pp1) < mem_npage*PAGESIZE);
  101350:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
  101353:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  101358:	89 d1                	mov    %edx,%ecx
  10135a:	29 c1                	sub    %eax,%ecx
  10135c:	89 c8                	mov    %ecx,%eax
  10135e:	c1 e0 09             	shl    $0x9,%eax
  101361:	89 c2                	mov    %eax,%edx
  101363:	a1 84 ed 17 00       	mov    0x17ed84,%eax
  101368:	c1 e0 0c             	shl    $0xc,%eax
  10136b:	39 c2                	cmp    %eax,%edx
  10136d:	72 24                	jb     101393 <mem_check+0x287>
  10136f:	c7 44 24 0c 9c c1 10 	movl   $0x10c19c,0xc(%esp)
  101376:	00 
  101377:	c7 44 24 08 67 c0 10 	movl   $0x10c067,0x8(%esp)
  10137e:	00 
  10137f:	c7 44 24 04 ce 00 00 	movl   $0xce,0x4(%esp)
  101386:	00 
  101387:	c7 04 24 08 c0 10 00 	movl   $0x10c008,(%esp)
  10138e:	e8 d5 f5 ff ff       	call   100968 <debug_panic>
        assert(mem_pi2phys(pp2) < mem_npage*PAGESIZE);
  101393:	8b 55 f0             	mov    0xfffffff0(%ebp),%edx
  101396:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  10139b:	89 d1                	mov    %edx,%ecx
  10139d:	29 c1                	sub    %eax,%ecx
  10139f:	89 c8                	mov    %ecx,%eax
  1013a1:	c1 e0 09             	shl    $0x9,%eax
  1013a4:	89 c2                	mov    %eax,%edx
  1013a6:	a1 84 ed 17 00       	mov    0x17ed84,%eax
  1013ab:	c1 e0 0c             	shl    $0xc,%eax
  1013ae:	39 c2                	cmp    %eax,%edx
  1013b0:	72 24                	jb     1013d6 <mem_check+0x2ca>
  1013b2:	c7 44 24 0c c4 c1 10 	movl   $0x10c1c4,0xc(%esp)
  1013b9:	00 
  1013ba:	c7 44 24 08 67 c0 10 	movl   $0x10c067,0x8(%esp)
  1013c1:	00 
  1013c2:	c7 44 24 04 cf 00 00 	movl   $0xcf,0x4(%esp)
  1013c9:	00 
  1013ca:	c7 04 24 08 c0 10 00 	movl   $0x10c008,(%esp)
  1013d1:	e8 92 f5 ff ff       	call   100968 <debug_panic>

	// temporarily steal the rest of the free pages
	fl = mem_freelist;
  1013d6:	a1 80 ed 17 00       	mov    0x17ed80,%eax
  1013db:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	mem_freelist = 0;
  1013de:	c7 05 80 ed 17 00 00 	movl   $0x0,0x17ed80
  1013e5:	00 00 00 

	// should be no free memory
	assert(mem_alloc() == 0);
  1013e8:	e8 5e fc ff ff       	call   10104b <mem_alloc>
  1013ed:	85 c0                	test   %eax,%eax
  1013ef:	74 24                	je     101415 <mem_check+0x309>
  1013f1:	c7 44 24 0c ea c1 10 	movl   $0x10c1ea,0xc(%esp)
  1013f8:	00 
  1013f9:	c7 44 24 08 67 c0 10 	movl   $0x10c067,0x8(%esp)
  101400:	00 
  101401:	c7 44 24 04 d6 00 00 	movl   $0xd6,0x4(%esp)
  101408:	00 
  101409:	c7 04 24 08 c0 10 00 	movl   $0x10c008,(%esp)
  101410:	e8 53 f5 ff ff       	call   100968 <debug_panic>

        // free and re-allocate?
        mem_free(pp0);
  101415:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  101418:	89 04 24             	mov    %eax,(%esp)
  10141b:	e8 6f fc ff ff       	call   10108f <mem_free>
        mem_free(pp1);
  101420:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  101423:	89 04 24             	mov    %eax,(%esp)
  101426:	e8 64 fc ff ff       	call   10108f <mem_free>
        mem_free(pp2);
  10142b:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  10142e:	89 04 24             	mov    %eax,(%esp)
  101431:	e8 59 fc ff ff       	call   10108f <mem_free>
	pp0 = pp1 = pp2 = 0;
  101436:	c7 45 f0 00 00 00 00 	movl   $0x0,0xfffffff0(%ebp)
  10143d:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  101440:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  101443:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  101446:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
	pp0 = mem_alloc(); assert(pp0 != 0);
  101449:	e8 fd fb ff ff       	call   10104b <mem_alloc>
  10144e:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  101451:	83 7d e8 00          	cmpl   $0x0,0xffffffe8(%ebp)
  101455:	75 24                	jne    10147b <mem_check+0x36f>
  101457:	c7 44 24 0c 22 c1 10 	movl   $0x10c122,0xc(%esp)
  10145e:	00 
  10145f:	c7 44 24 08 67 c0 10 	movl   $0x10c067,0x8(%esp)
  101466:	00 
  101467:	c7 44 24 04 dd 00 00 	movl   $0xdd,0x4(%esp)
  10146e:	00 
  10146f:	c7 04 24 08 c0 10 00 	movl   $0x10c008,(%esp)
  101476:	e8 ed f4 ff ff       	call   100968 <debug_panic>
	pp1 = mem_alloc(); assert(pp1 != 0);
  10147b:	e8 cb fb ff ff       	call   10104b <mem_alloc>
  101480:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  101483:	83 7d ec 00          	cmpl   $0x0,0xffffffec(%ebp)
  101487:	75 24                	jne    1014ad <mem_check+0x3a1>
  101489:	c7 44 24 0c 2b c1 10 	movl   $0x10c12b,0xc(%esp)
  101490:	00 
  101491:	c7 44 24 08 67 c0 10 	movl   $0x10c067,0x8(%esp)
  101498:	00 
  101499:	c7 44 24 04 de 00 00 	movl   $0xde,0x4(%esp)
  1014a0:	00 
  1014a1:	c7 04 24 08 c0 10 00 	movl   $0x10c008,(%esp)
  1014a8:	e8 bb f4 ff ff       	call   100968 <debug_panic>
	pp2 = mem_alloc(); assert(pp2 != 0);
  1014ad:	e8 99 fb ff ff       	call   10104b <mem_alloc>
  1014b2:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
  1014b5:	83 7d f0 00          	cmpl   $0x0,0xfffffff0(%ebp)
  1014b9:	75 24                	jne    1014df <mem_check+0x3d3>
  1014bb:	c7 44 24 0c 34 c1 10 	movl   $0x10c134,0xc(%esp)
  1014c2:	00 
  1014c3:	c7 44 24 08 67 c0 10 	movl   $0x10c067,0x8(%esp)
  1014ca:	00 
  1014cb:	c7 44 24 04 df 00 00 	movl   $0xdf,0x4(%esp)
  1014d2:	00 
  1014d3:	c7 04 24 08 c0 10 00 	movl   $0x10c008,(%esp)
  1014da:	e8 89 f4 ff ff       	call   100968 <debug_panic>
	assert(pp0);
  1014df:	83 7d e8 00          	cmpl   $0x0,0xffffffe8(%ebp)
  1014e3:	75 24                	jne    101509 <mem_check+0x3fd>
  1014e5:	c7 44 24 0c 3d c1 10 	movl   $0x10c13d,0xc(%esp)
  1014ec:	00 
  1014ed:	c7 44 24 08 67 c0 10 	movl   $0x10c067,0x8(%esp)
  1014f4:	00 
  1014f5:	c7 44 24 04 e0 00 00 	movl   $0xe0,0x4(%esp)
  1014fc:	00 
  1014fd:	c7 04 24 08 c0 10 00 	movl   $0x10c008,(%esp)
  101504:	e8 5f f4 ff ff       	call   100968 <debug_panic>
	assert(pp1 && pp1 != pp0);
  101509:	83 7d ec 00          	cmpl   $0x0,0xffffffec(%ebp)
  10150d:	74 08                	je     101517 <mem_check+0x40b>
  10150f:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  101512:	3b 45 e8             	cmp    0xffffffe8(%ebp),%eax
  101515:	75 24                	jne    10153b <mem_check+0x42f>
  101517:	c7 44 24 0c 41 c1 10 	movl   $0x10c141,0xc(%esp)
  10151e:	00 
  10151f:	c7 44 24 08 67 c0 10 	movl   $0x10c067,0x8(%esp)
  101526:	00 
  101527:	c7 44 24 04 e1 00 00 	movl   $0xe1,0x4(%esp)
  10152e:	00 
  10152f:	c7 04 24 08 c0 10 00 	movl   $0x10c008,(%esp)
  101536:	e8 2d f4 ff ff       	call   100968 <debug_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
  10153b:	83 7d f0 00          	cmpl   $0x0,0xfffffff0(%ebp)
  10153f:	74 10                	je     101551 <mem_check+0x445>
  101541:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  101544:	3b 45 ec             	cmp    0xffffffec(%ebp),%eax
  101547:	74 08                	je     101551 <mem_check+0x445>
  101549:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  10154c:	3b 45 e8             	cmp    0xffffffe8(%ebp),%eax
  10154f:	75 24                	jne    101575 <mem_check+0x469>
  101551:	c7 44 24 0c 54 c1 10 	movl   $0x10c154,0xc(%esp)
  101558:	00 
  101559:	c7 44 24 08 67 c0 10 	movl   $0x10c067,0x8(%esp)
  101560:	00 
  101561:	c7 44 24 04 e2 00 00 	movl   $0xe2,0x4(%esp)
  101568:	00 
  101569:	c7 04 24 08 c0 10 00 	movl   $0x10c008,(%esp)
  101570:	e8 f3 f3 ff ff       	call   100968 <debug_panic>
	assert(mem_alloc() == 0);
  101575:	e8 d1 fa ff ff       	call   10104b <mem_alloc>
  10157a:	85 c0                	test   %eax,%eax
  10157c:	74 24                	je     1015a2 <mem_check+0x496>
  10157e:	c7 44 24 0c ea c1 10 	movl   $0x10c1ea,0xc(%esp)
  101585:	00 
  101586:	c7 44 24 08 67 c0 10 	movl   $0x10c067,0x8(%esp)
  10158d:	00 
  10158e:	c7 44 24 04 e3 00 00 	movl   $0xe3,0x4(%esp)
  101595:	00 
  101596:	c7 04 24 08 c0 10 00 	movl   $0x10c008,(%esp)
  10159d:	e8 c6 f3 ff ff       	call   100968 <debug_panic>

	// give free list back
	mem_freelist = fl;
  1015a2:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  1015a5:	a3 80 ed 17 00       	mov    %eax,0x17ed80

	// free the pages we took
	mem_free(pp0);
  1015aa:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  1015ad:	89 04 24             	mov    %eax,(%esp)
  1015b0:	e8 da fa ff ff       	call   10108f <mem_free>
	mem_free(pp1);
  1015b5:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  1015b8:	89 04 24             	mov    %eax,(%esp)
  1015bb:	e8 cf fa ff ff       	call   10108f <mem_free>
	mem_free(pp2);
  1015c0:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  1015c3:	89 04 24             	mov    %eax,(%esp)
  1015c6:	e8 c4 fa ff ff       	call   10108f <mem_free>

	cprintf("mem_check() succeeded!\n");
  1015cb:	c7 04 24 fb c1 10 00 	movl   $0x10c1fb,(%esp)
  1015d2:	e8 9a 9e 00 00       	call   10b471 <cprintf>
}
  1015d7:	c9                   	leave  
  1015d8:	c3                   	ret    
  1015d9:	90                   	nop    
  1015da:	90                   	nop    
  1015db:	90                   	nop    

001015dc <cpu_init>:
};


void cpu_init()
{
  1015dc:	55                   	push   %ebp
  1015dd:	89 e5                	mov    %esp,%ebp
  1015df:	53                   	push   %ebx
  1015e0:	83 ec 14             	sub    $0x14,%esp
	cpu *c = cpu_cur();
  1015e3:	e8 23 01 00 00       	call   10170b <cpu_cur>
  1015e8:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)


	c->tss.ts_esp0 = (uint32_t) c->kstackhi;
  1015eb:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  1015ee:	05 00 10 00 00       	add    $0x1000,%eax
  1015f3:	89 c2                	mov    %eax,%edx
  1015f5:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  1015f8:	89 50 3c             	mov    %edx,0x3c(%eax)
	c->tss.ts_ss0 = CPU_GDT_KDATA;
  1015fb:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  1015fe:	66 c7 40 40 10 00    	movw   $0x10,0x40(%eax)

	c->gdt[CPU_GDT_TSS >> 3] = SEGDESC16(0, STS_T32A, (uint32_t) (&c->tss),
  101604:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  101607:	83 c0 38             	add    $0x38,%eax
  10160a:	89 c2                	mov    %eax,%edx
  10160c:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  10160f:	83 c0 38             	add    $0x38,%eax
  101612:	c1 e8 10             	shr    $0x10,%eax
  101615:	89 c1                	mov    %eax,%ecx
  101617:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  10161a:	83 c0 38             	add    $0x38,%eax
  10161d:	c1 e8 18             	shr    $0x18,%eax
  101620:	89 c3                	mov    %eax,%ebx
  101622:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  101625:	66 c7 40 30 67 00    	movw   $0x67,0x30(%eax)
  10162b:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  10162e:	66 89 50 32          	mov    %dx,0x32(%eax)
  101632:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  101635:	88 48 34             	mov    %cl,0x34(%eax)
  101638:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  10163b:	0f b6 42 35          	movzbl 0x35(%edx),%eax
  10163f:	83 e0 f0             	and    $0xfffffff0,%eax
  101642:	83 c8 09             	or     $0x9,%eax
  101645:	88 42 35             	mov    %al,0x35(%edx)
  101648:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  10164b:	0f b6 42 35          	movzbl 0x35(%edx),%eax
  10164f:	83 e0 ef             	and    $0xffffffef,%eax
  101652:	88 42 35             	mov    %al,0x35(%edx)
  101655:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  101658:	0f b6 42 35          	movzbl 0x35(%edx),%eax
  10165c:	83 e0 9f             	and    $0xffffff9f,%eax
  10165f:	88 42 35             	mov    %al,0x35(%edx)
  101662:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  101665:	0f b6 42 35          	movzbl 0x35(%edx),%eax
  101669:	83 c8 80             	or     $0xffffff80,%eax
  10166c:	88 42 35             	mov    %al,0x35(%edx)
  10166f:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  101672:	0f b6 42 36          	movzbl 0x36(%edx),%eax
  101676:	83 e0 f0             	and    $0xfffffff0,%eax
  101679:	88 42 36             	mov    %al,0x36(%edx)
  10167c:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  10167f:	0f b6 42 36          	movzbl 0x36(%edx),%eax
  101683:	83 e0 ef             	and    $0xffffffef,%eax
  101686:	88 42 36             	mov    %al,0x36(%edx)
  101689:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  10168c:	0f b6 42 36          	movzbl 0x36(%edx),%eax
  101690:	83 e0 df             	and    $0xffffffdf,%eax
  101693:	88 42 36             	mov    %al,0x36(%edx)
  101696:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  101699:	0f b6 42 36          	movzbl 0x36(%edx),%eax
  10169d:	83 c8 40             	or     $0x40,%eax
  1016a0:	88 42 36             	mov    %al,0x36(%edx)
  1016a3:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  1016a6:	0f b6 42 36          	movzbl 0x36(%edx),%eax
  1016aa:	83 e0 7f             	and    $0x7f,%eax
  1016ad:	88 42 36             	mov    %al,0x36(%edx)
  1016b0:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  1016b3:	88 58 37             	mov    %bl,0x37(%eax)
					sizeof(taskstate)-1, 0);

	// Load the GDT
	struct pseudodesc gdt_pd = {
		sizeof(c->gdt) - 1, (uint32_t) c->gdt };
  1016b6:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  1016b9:	66 c7 45 ee 37 00    	movw   $0x37,0xffffffee(%ebp)
  1016bf:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
	asm volatile("lgdt %0" : : "m" (gdt_pd));
  1016c2:	0f 01 55 ee          	lgdtl  0xffffffee(%ebp)

	// Reload all segment registers.
	asm volatile("movw %%ax,%%gs" :: "a" (CPU_GDT_UDATA|3));
  1016c6:	b8 23 00 00 00       	mov    $0x23,%eax
  1016cb:	8e e8                	movl   %eax,%gs
	asm volatile("movw %%ax,%%fs" :: "a" (CPU_GDT_UDATA|3));
  1016cd:	b8 23 00 00 00       	mov    $0x23,%eax
  1016d2:	8e e0                	movl   %eax,%fs
	asm volatile("movw %%ax,%%es" :: "a" (CPU_GDT_KDATA));
  1016d4:	b8 10 00 00 00       	mov    $0x10,%eax
  1016d9:	8e c0                	movl   %eax,%es
	asm volatile("movw %%ax,%%ds" :: "a" (CPU_GDT_KDATA));
  1016db:	b8 10 00 00 00       	mov    $0x10,%eax
  1016e0:	8e d8                	movl   %eax,%ds
	asm volatile("movw %%ax,%%ss" :: "a" (CPU_GDT_KDATA));
  1016e2:	b8 10 00 00 00       	mov    $0x10,%eax
  1016e7:	8e d0                	movl   %eax,%ss
	asm volatile("ljmp %0,$1f\n 1:\n" :: "i" (CPU_GDT_KCODE)); // reload CS
  1016e9:	ea f0 16 10 00 08 00 	ljmp   $0x8,$0x1016f0

	// We don't need an LDT.
	asm volatile("lldt %%ax" :: "a" (0));
  1016f0:	b8 00 00 00 00       	mov    $0x0,%eax
  1016f5:	0f 00 d0             	lldt   %ax
  1016f8:	66 c7 45 fa 30 00    	movw   $0x30,0xfffffffa(%ebp)

static gcc_inline void
ltr(uint16_t sel)
{
	__asm __volatile("ltr %0" : : "r" (sel));
  1016fe:	0f b7 45 fa          	movzwl 0xfffffffa(%ebp),%eax
  101702:	0f 00 d8             	ltr    %ax
  ltr(CPU_GDT_TSS);
}
  101705:	83 c4 14             	add    $0x14,%esp
  101708:	5b                   	pop    %ebx
  101709:	5d                   	pop    %ebp
  10170a:	c3                   	ret    

0010170b <cpu_cur>:

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  10170b:	55                   	push   %ebp
  10170c:	89 e5                	mov    %esp,%ebp
  10170e:	83 ec 28             	sub    $0x28,%esp
static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  101711:	89 65 fc             	mov    %esp,0xfffffffc(%ebp)
        return esp;
  101714:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  101717:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  10171a:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10171d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  101722:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	assert(c->magic == CPU_MAGIC);
  101725:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  101728:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  10172e:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  101733:	74 24                	je     101759 <cpu_cur+0x4e>
  101735:	c7 44 24 0c 13 c2 10 	movl   $0x10c213,0xc(%esp)
  10173c:	00 
  10173d:	c7 44 24 08 29 c2 10 	movl   $0x10c229,0x8(%esp)
  101744:	00 
  101745:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  10174c:	00 
  10174d:	c7 04 24 3e c2 10 00 	movl   $0x10c23e,(%esp)
  101754:	e8 0f f2 ff ff       	call   100968 <debug_panic>
	return c;
  101759:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
}
  10175c:	c9                   	leave  
  10175d:	c3                   	ret    

0010175e <cpu_alloc>:

// Allocate an additional cpu struct representing a non-bootstrap processor.
cpu *
cpu_alloc(void)
{
  10175e:	55                   	push   %ebp
  10175f:	89 e5                	mov    %esp,%ebp
  101761:	83 ec 28             	sub    $0x28,%esp
	// Pointer to the cpu.next pointer of the last CPU on the list,
	// for chaining on new CPUs in cpu_alloc().  Note: static.
	static cpu **cpu_tail = &cpu_boot.next;

	pageinfo *pi = mem_alloc();
  101764:	e8 e2 f8 ff ff       	call   10104b <mem_alloc>
  101769:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
	assert(pi != 0);	// shouldn't be out of memory just yet!
  10176c:	83 7d f8 00          	cmpl   $0x0,0xfffffff8(%ebp)
  101770:	75 24                	jne    101796 <cpu_alloc+0x38>
  101772:	c7 44 24 0c 4b c2 10 	movl   $0x10c24b,0xc(%esp)
  101779:	00 
  10177a:	c7 44 24 08 29 c2 10 	movl   $0x10c229,0x8(%esp)
  101781:	00 
  101782:	c7 44 24 04 5f 00 00 	movl   $0x5f,0x4(%esp)
  101789:	00 
  10178a:	c7 04 24 53 c2 10 00 	movl   $0x10c253,(%esp)
  101791:	e8 d2 f1 ff ff       	call   100968 <debug_panic>

	cpu *c = (cpu*) mem_pi2ptr(pi);
  101796:	8b 55 f8             	mov    0xfffffff8(%ebp),%edx
  101799:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  10179e:	89 d1                	mov    %edx,%ecx
  1017a0:	29 c1                	sub    %eax,%ecx
  1017a2:	89 c8                	mov    %ecx,%eax
  1017a4:	c1 e0 09             	shl    $0x9,%eax
  1017a7:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)

	// Clear the whole page for good measure: cpu struct and kernel stack
	memset(c, 0, PAGESIZE);
  1017aa:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  1017b1:	00 
  1017b2:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1017b9:	00 
  1017ba:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  1017bd:	89 04 24             	mov    %eax,(%esp)
  1017c0:	e8 30 a0 00 00       	call   10b7f5 <memset>

	// Now we need to initialize the new cpu struct
	// just to the same degree that cpu_boot was statically initialized.
	// The rest will be filled in by the CPU itself
	// when it starts up and calls cpu_init().

	// Initialize the new cpu's GDT by copying from the cpu_boot.
	// The TSS descriptor will be filled in later by cpu_init().
	assert(sizeof(c->gdt) == sizeof(segdesc) * CPU_GDT_NDESC);
	memmove(c->gdt, cpu_boot.gdt, sizeof(c->gdt));
  1017c5:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  1017c8:	c7 44 24 08 38 00 00 	movl   $0x38,0x8(%esp)
  1017cf:	00 
  1017d0:	c7 44 24 04 00 e0 10 	movl   $0x10e000,0x4(%esp)
  1017d7:	00 
  1017d8:	89 04 24             	mov    %eax,(%esp)
  1017db:	e8 8e a0 00 00       	call   10b86e <memmove>

	// Magic verification tag for stack overflow/cpu corruption checking
	c->magic = CPU_MAGIC;
  1017e0:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  1017e3:	c7 80 b8 00 00 00 32 	movl   $0x98765432,0xb8(%eax)
  1017ea:	54 76 98 

	// Chain the new CPU onto the tail of the list.
	*cpu_tail = c;
  1017ed:	8b 15 00 f0 10 00    	mov    0x10f000,%edx
  1017f3:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  1017f6:	89 02                	mov    %eax,(%edx)
	cpu_tail = &c->next;
  1017f8:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  1017fb:	05 a8 00 00 00       	add    $0xa8,%eax
  101800:	a3 00 f0 10 00       	mov    %eax,0x10f000

	return c;
  101805:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
}
  101808:	c9                   	leave  
  101809:	c3                   	ret    

0010180a <cpu_bootothers>:

void
cpu_bootothers(void)
{
  10180a:	55                   	push   %ebp
  10180b:	89 e5                	mov    %esp,%ebp
  10180d:	83 ec 28             	sub    $0x28,%esp
	extern uint8_t _binary_obj_boot_bootother_start[],
			_binary_obj_boot_bootother_size[];

	if (!cpu_onboot()) {
  101810:	e8 b6 00 00 00       	call   1018cb <cpu_onboot>
  101815:	85 c0                	test   %eax,%eax
  101817:	75 1f                	jne    101838 <cpu_bootothers+0x2e>
		// Just inform the boot cpu we've booted.
		xchg(&cpu_cur()->booted, 1);
  101819:	e8 ed fe ff ff       	call   10170b <cpu_cur>
  10181e:	05 b0 00 00 00       	add    $0xb0,%eax
  101823:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  10182a:	00 
  10182b:	89 04 24             	mov    %eax,(%esp)
  10182e:	e8 b0 00 00 00       	call   1018e3 <xchg>
		return;
  101833:	e9 91 00 00 00       	jmp    1018c9 <cpu_bootothers+0xbf>
	}

	// Write bootstrap code to unused memory at 0x1000.
	uint8_t *code = (uint8_t*)0x1000;
  101838:	c7 45 f8 00 10 00 00 	movl   $0x1000,0xfffffff8(%ebp)
	memmove(code, _binary_obj_boot_bootother_start,
  10183f:	b8 c0 01 00 00       	mov    $0x1c0,%eax
  101844:	89 44 24 08          	mov    %eax,0x8(%esp)
  101848:	c7 44 24 04 61 89 17 	movl   $0x178961,0x4(%esp)
  10184f:	00 
  101850:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  101853:	89 04 24             	mov    %eax,(%esp)
  101856:	e8 13 a0 00 00       	call   10b86e <memmove>
		(uint32_t)_binary_obj_boot_bootother_size);

	cpu *c;
	for(c = &cpu_boot; c; c = c->next){
  10185b:	c7 45 fc 00 e0 10 00 	movl   $0x10e000,0xfffffffc(%ebp)
  101862:	eb 5f                	jmp    1018c3 <cpu_bootothers+0xb9>
		if(c == cpu_cur())  // We''ve started already.
  101864:	e8 a2 fe ff ff       	call   10170b <cpu_cur>
  101869:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  10186c:	74 49                	je     1018b7 <cpu_bootothers+0xad>
			continue;

		// Fill in %esp, %eip and start code on cpu.
		*(void**)(code-4) = c->kstackhi;
  10186e:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  101871:	83 e8 04             	sub    $0x4,%eax
  101874:	89 c2                	mov    %eax,%edx
  101876:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  101879:	05 00 10 00 00       	add    $0x1000,%eax
  10187e:	89 02                	mov    %eax,(%edx)
		*(void**)(code-8) = init;
  101880:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  101883:	83 e8 08             	sub    $0x8,%eax
  101886:	c7 00 28 00 10 00    	movl   $0x100028,(%eax)
		lapic_startcpu(c->id, (uint32_t)code);
  10188c:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10188f:	89 c2                	mov    %eax,%edx
  101891:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  101894:	0f b6 80 ac 00 00 00 	movzbl 0xac(%eax),%eax
  10189b:	0f b6 c0             	movzbl %al,%eax
  10189e:	89 54 24 04          	mov    %edx,0x4(%esp)
  1018a2:	89 04 24             	mov    %eax,(%esp)
  1018a5:	e8 68 91 00 00       	call   10aa12 <lapic_startcpu>

		// Wait for cpu to get through bootstrap.
		while(c->booted == 0)
  1018aa:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  1018ad:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
  1018b3:	85 c0                	test   %eax,%eax
  1018b5:	74 f3                	je     1018aa <cpu_bootothers+0xa0>
  1018b7:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  1018ba:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
  1018c0:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  1018c3:	83 7d fc 00          	cmpl   $0x0,0xfffffffc(%ebp)
  1018c7:	75 9b                	jne    101864 <cpu_bootothers+0x5a>
			;
	}
}
  1018c9:	c9                   	leave  
  1018ca:	c3                   	ret    

001018cb <cpu_onboot>:
}

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  1018cb:	55                   	push   %ebp
  1018cc:	89 e5                	mov    %esp,%ebp
  1018ce:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  1018d1:	e8 35 fe ff ff       	call   10170b <cpu_cur>
  1018d6:	3d 00 e0 10 00       	cmp    $0x10e000,%eax
  1018db:	0f 94 c0             	sete   %al
  1018de:	0f b6 c0             	movzbl %al,%eax
}
  1018e1:	c9                   	leave  
  1018e2:	c3                   	ret    

001018e3 <xchg>:

// Atomically set *addr to newval and return the old value of *addr.
static inline uint32_t
xchg(volatile uint32_t *addr, uint32_t newval)
{
  1018e3:	55                   	push   %ebp
  1018e4:	89 e5                	mov    %esp,%ebp
  1018e6:	53                   	push   %ebx
  1018e7:	83 ec 14             	sub    $0x14,%esp
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
  1018ea:	8b 4d 08             	mov    0x8(%ebp),%ecx
  1018ed:	8b 55 0c             	mov    0xc(%ebp),%edx
  1018f0:	8b 45 08             	mov    0x8(%ebp),%eax
  1018f3:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  1018f6:	89 d0                	mov    %edx,%eax
  1018f8:	8b 5d e8             	mov    0xffffffe8(%ebp),%ebx
  1018fb:	f0 87 01             	lock xchg %eax,(%ecx)
  1018fe:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  101901:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  101904:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
	       "+m" (*addr), "=a" (result) :
	       "1" (newval) :
	       "cc");
	return result;
  101907:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
}
  10190a:	83 c4 14             	add    $0x14,%esp
  10190d:	5b                   	pop    %ebx
  10190e:	5d                   	pop    %ebp
  10190f:	c3                   	ret    

00101910 <trap_init_idt>:


static void
trap_init_idt(void)
{
  101910:	55                   	push   %ebp
  101911:	89 e5                	mov    %esp,%ebp
  101913:	83 ec 10             	sub    $0x10,%esp
	extern segdesc gdt[];
	extern char
		Xdivide,Xdebug,Xnmi,Xbrkpt,Xoflow,Xbound,
		Xillop,Xdevice,Xdblflt,Xtss,Xsegnp,Xstack,
		Xgpflt,Xpgflt,Xfperr,Xalign,Xmchk,Xsimd,Xdefault;
	extern char
		Xirq0,Xirq1,Xirq2,Xirq3,Xirq4,Xirq5,
		Xirq6,Xirq7,Xirq8,Xirq9,Xirq10,Xirq11,
		Xirq12,Xirq13,Xirq14,Xirq15,
		Xsyscall,Xltimer,Xlerror,Xperfctr;
	int i;

	// check that the SIZEOF_STRUCT_TRAPFRAME symbol is defined correctly
	static_assert(sizeof(trapframe) == SIZEOF_STRUCT_TRAPFRAME);
	// check that T_IRQ0 is a multiple of 8
	static_assert((T_IRQ0 & 7) == 0);

	// install a default handler
	for (i = 0; i < sizeof(idt)/sizeof(idt[0]); i++)
  101916:	c7 45 fc 00 00 00 00 	movl   $0x0,0xfffffffc(%ebp)
  10191d:	e9 b5 00 00 00       	jmp    1019d7 <trap_init_idt+0xc7>
		SETGATE(idt[i], 0, CPU_GDT_KCODE, &Xdefault, 0);
  101922:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  101925:	b8 34 36 10 00       	mov    $0x103634,%eax
  10192a:	66 89 04 d5 20 a2 17 	mov    %ax,0x17a220(,%edx,8)
  101931:	00 
  101932:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  101935:	66 c7 04 c5 22 a2 17 	movw   $0x8,0x17a222(,%eax,8)
  10193c:	00 08 00 
  10193f:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  101942:	0f b6 04 d5 24 a2 17 	movzbl 0x17a224(,%edx,8),%eax
  101949:	00 
  10194a:	83 e0 e0             	and    $0xffffffe0,%eax
  10194d:	88 04 d5 24 a2 17 00 	mov    %al,0x17a224(,%edx,8)
  101954:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  101957:	0f b6 04 d5 24 a2 17 	movzbl 0x17a224(,%edx,8),%eax
  10195e:	00 
  10195f:	83 e0 1f             	and    $0x1f,%eax
  101962:	88 04 d5 24 a2 17 00 	mov    %al,0x17a224(,%edx,8)
  101969:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  10196c:	0f b6 04 d5 25 a2 17 	movzbl 0x17a225(,%edx,8),%eax
  101973:	00 
  101974:	83 e0 f0             	and    $0xfffffff0,%eax
  101977:	83 c8 0e             	or     $0xe,%eax
  10197a:	88 04 d5 25 a2 17 00 	mov    %al,0x17a225(,%edx,8)
  101981:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  101984:	0f b6 04 d5 25 a2 17 	movzbl 0x17a225(,%edx,8),%eax
  10198b:	00 
  10198c:	83 e0 ef             	and    $0xffffffef,%eax
  10198f:	88 04 d5 25 a2 17 00 	mov    %al,0x17a225(,%edx,8)
  101996:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  101999:	0f b6 04 d5 25 a2 17 	movzbl 0x17a225(,%edx,8),%eax
  1019a0:	00 
  1019a1:	83 e0 9f             	and    $0xffffff9f,%eax
  1019a4:	88 04 d5 25 a2 17 00 	mov    %al,0x17a225(,%edx,8)
  1019ab:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  1019ae:	0f b6 04 d5 25 a2 17 	movzbl 0x17a225(,%edx,8),%eax
  1019b5:	00 
  1019b6:	83 c8 80             	or     $0xffffff80,%eax
  1019b9:	88 04 d5 25 a2 17 00 	mov    %al,0x17a225(,%edx,8)
  1019c0:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  1019c3:	b8 34 36 10 00       	mov    $0x103634,%eax
  1019c8:	c1 e8 10             	shr    $0x10,%eax
  1019cb:	66 89 04 d5 26 a2 17 	mov    %ax,0x17a226(,%edx,8)
  1019d2:	00 
  1019d3:	83 45 fc 01          	addl   $0x1,0xfffffffc(%ebp)
  1019d7:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  1019da:	3d ff 00 00 00       	cmp    $0xff,%eax
  1019df:	0f 86 3d ff ff ff    	jbe    101922 <trap_init_idt+0x12>

	SETGATE(idt[T_DIVIDE], 0, CPU_GDT_KCODE, &Xdivide, 0);
  1019e5:	b8 d0 34 10 00       	mov    $0x1034d0,%eax
  1019ea:	66 a3 20 a2 17 00    	mov    %ax,0x17a220
  1019f0:	66 c7 05 22 a2 17 00 	movw   $0x8,0x17a222
  1019f7:	08 00 
  1019f9:	0f b6 05 24 a2 17 00 	movzbl 0x17a224,%eax
  101a00:	83 e0 e0             	and    $0xffffffe0,%eax
  101a03:	a2 24 a2 17 00       	mov    %al,0x17a224
  101a08:	0f b6 05 24 a2 17 00 	movzbl 0x17a224,%eax
  101a0f:	83 e0 1f             	and    $0x1f,%eax
  101a12:	a2 24 a2 17 00       	mov    %al,0x17a224
  101a17:	0f b6 05 25 a2 17 00 	movzbl 0x17a225,%eax
  101a1e:	83 e0 f0             	and    $0xfffffff0,%eax
  101a21:	83 c8 0e             	or     $0xe,%eax
  101a24:	a2 25 a2 17 00       	mov    %al,0x17a225
  101a29:	0f b6 05 25 a2 17 00 	movzbl 0x17a225,%eax
  101a30:	83 e0 ef             	and    $0xffffffef,%eax
  101a33:	a2 25 a2 17 00       	mov    %al,0x17a225
  101a38:	0f b6 05 25 a2 17 00 	movzbl 0x17a225,%eax
  101a3f:	83 e0 9f             	and    $0xffffff9f,%eax
  101a42:	a2 25 a2 17 00       	mov    %al,0x17a225
  101a47:	0f b6 05 25 a2 17 00 	movzbl 0x17a225,%eax
  101a4e:	83 c8 80             	or     $0xffffff80,%eax
  101a51:	a2 25 a2 17 00       	mov    %al,0x17a225
  101a56:	b8 d0 34 10 00       	mov    $0x1034d0,%eax
  101a5b:	c1 e8 10             	shr    $0x10,%eax
  101a5e:	66 a3 26 a2 17 00    	mov    %ax,0x17a226
	SETGATE(idt[T_DEBUG],  0, CPU_GDT_KCODE, &Xdebug,  0);
  101a64:	b8 da 34 10 00       	mov    $0x1034da,%eax
  101a69:	66 a3 28 a2 17 00    	mov    %ax,0x17a228
  101a6f:	66 c7 05 2a a2 17 00 	movw   $0x8,0x17a22a
  101a76:	08 00 
  101a78:	0f b6 05 2c a2 17 00 	movzbl 0x17a22c,%eax
  101a7f:	83 e0 e0             	and    $0xffffffe0,%eax
  101a82:	a2 2c a2 17 00       	mov    %al,0x17a22c
  101a87:	0f b6 05 2c a2 17 00 	movzbl 0x17a22c,%eax
  101a8e:	83 e0 1f             	and    $0x1f,%eax
  101a91:	a2 2c a2 17 00       	mov    %al,0x17a22c
  101a96:	0f b6 05 2d a2 17 00 	movzbl 0x17a22d,%eax
  101a9d:	83 e0 f0             	and    $0xfffffff0,%eax
  101aa0:	83 c8 0e             	or     $0xe,%eax
  101aa3:	a2 2d a2 17 00       	mov    %al,0x17a22d
  101aa8:	0f b6 05 2d a2 17 00 	movzbl 0x17a22d,%eax
  101aaf:	83 e0 ef             	and    $0xffffffef,%eax
  101ab2:	a2 2d a2 17 00       	mov    %al,0x17a22d
  101ab7:	0f b6 05 2d a2 17 00 	movzbl 0x17a22d,%eax
  101abe:	83 e0 9f             	and    $0xffffff9f,%eax
  101ac1:	a2 2d a2 17 00       	mov    %al,0x17a22d
  101ac6:	0f b6 05 2d a2 17 00 	movzbl 0x17a22d,%eax
  101acd:	83 c8 80             	or     $0xffffff80,%eax
  101ad0:	a2 2d a2 17 00       	mov    %al,0x17a22d
  101ad5:	b8 da 34 10 00       	mov    $0x1034da,%eax
  101ada:	c1 e8 10             	shr    $0x10,%eax
  101add:	66 a3 2e a2 17 00    	mov    %ax,0x17a22e
	SETGATE(idt[T_NMI],    0, CPU_GDT_KCODE, &Xnmi,    0);
  101ae3:	b8 e4 34 10 00       	mov    $0x1034e4,%eax
  101ae8:	66 a3 30 a2 17 00    	mov    %ax,0x17a230
  101aee:	66 c7 05 32 a2 17 00 	movw   $0x8,0x17a232
  101af5:	08 00 
  101af7:	0f b6 05 34 a2 17 00 	movzbl 0x17a234,%eax
  101afe:	83 e0 e0             	and    $0xffffffe0,%eax
  101b01:	a2 34 a2 17 00       	mov    %al,0x17a234
  101b06:	0f b6 05 34 a2 17 00 	movzbl 0x17a234,%eax
  101b0d:	83 e0 1f             	and    $0x1f,%eax
  101b10:	a2 34 a2 17 00       	mov    %al,0x17a234
  101b15:	0f b6 05 35 a2 17 00 	movzbl 0x17a235,%eax
  101b1c:	83 e0 f0             	and    $0xfffffff0,%eax
  101b1f:	83 c8 0e             	or     $0xe,%eax
  101b22:	a2 35 a2 17 00       	mov    %al,0x17a235
  101b27:	0f b6 05 35 a2 17 00 	movzbl 0x17a235,%eax
  101b2e:	83 e0 ef             	and    $0xffffffef,%eax
  101b31:	a2 35 a2 17 00       	mov    %al,0x17a235
  101b36:	0f b6 05 35 a2 17 00 	movzbl 0x17a235,%eax
  101b3d:	83 e0 9f             	and    $0xffffff9f,%eax
  101b40:	a2 35 a2 17 00       	mov    %al,0x17a235
  101b45:	0f b6 05 35 a2 17 00 	movzbl 0x17a235,%eax
  101b4c:	83 c8 80             	or     $0xffffff80,%eax
  101b4f:	a2 35 a2 17 00       	mov    %al,0x17a235
  101b54:	b8 e4 34 10 00       	mov    $0x1034e4,%eax
  101b59:	c1 e8 10             	shr    $0x10,%eax
  101b5c:	66 a3 36 a2 17 00    	mov    %ax,0x17a236
	SETGATE(idt[T_BRKPT],  0, CPU_GDT_KCODE, &Xbrkpt,  3);
  101b62:	b8 ee 34 10 00       	mov    $0x1034ee,%eax
  101b67:	66 a3 38 a2 17 00    	mov    %ax,0x17a238
  101b6d:	66 c7 05 3a a2 17 00 	movw   $0x8,0x17a23a
  101b74:	08 00 
  101b76:	0f b6 05 3c a2 17 00 	movzbl 0x17a23c,%eax
  101b7d:	83 e0 e0             	and    $0xffffffe0,%eax
  101b80:	a2 3c a2 17 00       	mov    %al,0x17a23c
  101b85:	0f b6 05 3c a2 17 00 	movzbl 0x17a23c,%eax
  101b8c:	83 e0 1f             	and    $0x1f,%eax
  101b8f:	a2 3c a2 17 00       	mov    %al,0x17a23c
  101b94:	0f b6 05 3d a2 17 00 	movzbl 0x17a23d,%eax
  101b9b:	83 e0 f0             	and    $0xfffffff0,%eax
  101b9e:	83 c8 0e             	or     $0xe,%eax
  101ba1:	a2 3d a2 17 00       	mov    %al,0x17a23d
  101ba6:	0f b6 05 3d a2 17 00 	movzbl 0x17a23d,%eax
  101bad:	83 e0 ef             	and    $0xffffffef,%eax
  101bb0:	a2 3d a2 17 00       	mov    %al,0x17a23d
  101bb5:	0f b6 05 3d a2 17 00 	movzbl 0x17a23d,%eax
  101bbc:	83 c8 60             	or     $0x60,%eax
  101bbf:	a2 3d a2 17 00       	mov    %al,0x17a23d
  101bc4:	0f b6 05 3d a2 17 00 	movzbl 0x17a23d,%eax
  101bcb:	83 c8 80             	or     $0xffffff80,%eax
  101bce:	a2 3d a2 17 00       	mov    %al,0x17a23d
  101bd3:	b8 ee 34 10 00       	mov    $0x1034ee,%eax
  101bd8:	c1 e8 10             	shr    $0x10,%eax
  101bdb:	66 a3 3e a2 17 00    	mov    %ax,0x17a23e
	SETGATE(idt[T_OFLOW],  0, CPU_GDT_KCODE, &Xoflow,  3);
  101be1:	b8 f8 34 10 00       	mov    $0x1034f8,%eax
  101be6:	66 a3 40 a2 17 00    	mov    %ax,0x17a240
  101bec:	66 c7 05 42 a2 17 00 	movw   $0x8,0x17a242
  101bf3:	08 00 
  101bf5:	0f b6 05 44 a2 17 00 	movzbl 0x17a244,%eax
  101bfc:	83 e0 e0             	and    $0xffffffe0,%eax
  101bff:	a2 44 a2 17 00       	mov    %al,0x17a244
  101c04:	0f b6 05 44 a2 17 00 	movzbl 0x17a244,%eax
  101c0b:	83 e0 1f             	and    $0x1f,%eax
  101c0e:	a2 44 a2 17 00       	mov    %al,0x17a244
  101c13:	0f b6 05 45 a2 17 00 	movzbl 0x17a245,%eax
  101c1a:	83 e0 f0             	and    $0xfffffff0,%eax
  101c1d:	83 c8 0e             	or     $0xe,%eax
  101c20:	a2 45 a2 17 00       	mov    %al,0x17a245
  101c25:	0f b6 05 45 a2 17 00 	movzbl 0x17a245,%eax
  101c2c:	83 e0 ef             	and    $0xffffffef,%eax
  101c2f:	a2 45 a2 17 00       	mov    %al,0x17a245
  101c34:	0f b6 05 45 a2 17 00 	movzbl 0x17a245,%eax
  101c3b:	83 c8 60             	or     $0x60,%eax
  101c3e:	a2 45 a2 17 00       	mov    %al,0x17a245
  101c43:	0f b6 05 45 a2 17 00 	movzbl 0x17a245,%eax
  101c4a:	83 c8 80             	or     $0xffffff80,%eax
  101c4d:	a2 45 a2 17 00       	mov    %al,0x17a245
  101c52:	b8 f8 34 10 00       	mov    $0x1034f8,%eax
  101c57:	c1 e8 10             	shr    $0x10,%eax
  101c5a:	66 a3 46 a2 17 00    	mov    %ax,0x17a246
	SETGATE(idt[T_BOUND],  0, CPU_GDT_KCODE, &Xbound,  0);
  101c60:	b8 02 35 10 00       	mov    $0x103502,%eax
  101c65:	66 a3 48 a2 17 00    	mov    %ax,0x17a248
  101c6b:	66 c7 05 4a a2 17 00 	movw   $0x8,0x17a24a
  101c72:	08 00 
  101c74:	0f b6 05 4c a2 17 00 	movzbl 0x17a24c,%eax
  101c7b:	83 e0 e0             	and    $0xffffffe0,%eax
  101c7e:	a2 4c a2 17 00       	mov    %al,0x17a24c
  101c83:	0f b6 05 4c a2 17 00 	movzbl 0x17a24c,%eax
  101c8a:	83 e0 1f             	and    $0x1f,%eax
  101c8d:	a2 4c a2 17 00       	mov    %al,0x17a24c
  101c92:	0f b6 05 4d a2 17 00 	movzbl 0x17a24d,%eax
  101c99:	83 e0 f0             	and    $0xfffffff0,%eax
  101c9c:	83 c8 0e             	or     $0xe,%eax
  101c9f:	a2 4d a2 17 00       	mov    %al,0x17a24d
  101ca4:	0f b6 05 4d a2 17 00 	movzbl 0x17a24d,%eax
  101cab:	83 e0 ef             	and    $0xffffffef,%eax
  101cae:	a2 4d a2 17 00       	mov    %al,0x17a24d
  101cb3:	0f b6 05 4d a2 17 00 	movzbl 0x17a24d,%eax
  101cba:	83 e0 9f             	and    $0xffffff9f,%eax
  101cbd:	a2 4d a2 17 00       	mov    %al,0x17a24d
  101cc2:	0f b6 05 4d a2 17 00 	movzbl 0x17a24d,%eax
  101cc9:	83 c8 80             	or     $0xffffff80,%eax
  101ccc:	a2 4d a2 17 00       	mov    %al,0x17a24d
  101cd1:	b8 02 35 10 00       	mov    $0x103502,%eax
  101cd6:	c1 e8 10             	shr    $0x10,%eax
  101cd9:	66 a3 4e a2 17 00    	mov    %ax,0x17a24e
	SETGATE(idt[T_ILLOP],  0, CPU_GDT_KCODE, &Xillop,  0);
  101cdf:	b8 0c 35 10 00       	mov    $0x10350c,%eax
  101ce4:	66 a3 50 a2 17 00    	mov    %ax,0x17a250
  101cea:	66 c7 05 52 a2 17 00 	movw   $0x8,0x17a252
  101cf1:	08 00 
  101cf3:	0f b6 05 54 a2 17 00 	movzbl 0x17a254,%eax
  101cfa:	83 e0 e0             	and    $0xffffffe0,%eax
  101cfd:	a2 54 a2 17 00       	mov    %al,0x17a254
  101d02:	0f b6 05 54 a2 17 00 	movzbl 0x17a254,%eax
  101d09:	83 e0 1f             	and    $0x1f,%eax
  101d0c:	a2 54 a2 17 00       	mov    %al,0x17a254
  101d11:	0f b6 05 55 a2 17 00 	movzbl 0x17a255,%eax
  101d18:	83 e0 f0             	and    $0xfffffff0,%eax
  101d1b:	83 c8 0e             	or     $0xe,%eax
  101d1e:	a2 55 a2 17 00       	mov    %al,0x17a255
  101d23:	0f b6 05 55 a2 17 00 	movzbl 0x17a255,%eax
  101d2a:	83 e0 ef             	and    $0xffffffef,%eax
  101d2d:	a2 55 a2 17 00       	mov    %al,0x17a255
  101d32:	0f b6 05 55 a2 17 00 	movzbl 0x17a255,%eax
  101d39:	83 e0 9f             	and    $0xffffff9f,%eax
  101d3c:	a2 55 a2 17 00       	mov    %al,0x17a255
  101d41:	0f b6 05 55 a2 17 00 	movzbl 0x17a255,%eax
  101d48:	83 c8 80             	or     $0xffffff80,%eax
  101d4b:	a2 55 a2 17 00       	mov    %al,0x17a255
  101d50:	b8 0c 35 10 00       	mov    $0x10350c,%eax
  101d55:	c1 e8 10             	shr    $0x10,%eax
  101d58:	66 a3 56 a2 17 00    	mov    %ax,0x17a256
	SETGATE(idt[T_DEVICE], 0, CPU_GDT_KCODE, &Xdevice, 0);
  101d5e:	b8 16 35 10 00       	mov    $0x103516,%eax
  101d63:	66 a3 58 a2 17 00    	mov    %ax,0x17a258
  101d69:	66 c7 05 5a a2 17 00 	movw   $0x8,0x17a25a
  101d70:	08 00 
  101d72:	0f b6 05 5c a2 17 00 	movzbl 0x17a25c,%eax
  101d79:	83 e0 e0             	and    $0xffffffe0,%eax
  101d7c:	a2 5c a2 17 00       	mov    %al,0x17a25c
  101d81:	0f b6 05 5c a2 17 00 	movzbl 0x17a25c,%eax
  101d88:	83 e0 1f             	and    $0x1f,%eax
  101d8b:	a2 5c a2 17 00       	mov    %al,0x17a25c
  101d90:	0f b6 05 5d a2 17 00 	movzbl 0x17a25d,%eax
  101d97:	83 e0 f0             	and    $0xfffffff0,%eax
  101d9a:	83 c8 0e             	or     $0xe,%eax
  101d9d:	a2 5d a2 17 00       	mov    %al,0x17a25d
  101da2:	0f b6 05 5d a2 17 00 	movzbl 0x17a25d,%eax
  101da9:	83 e0 ef             	and    $0xffffffef,%eax
  101dac:	a2 5d a2 17 00       	mov    %al,0x17a25d
  101db1:	0f b6 05 5d a2 17 00 	movzbl 0x17a25d,%eax
  101db8:	83 e0 9f             	and    $0xffffff9f,%eax
  101dbb:	a2 5d a2 17 00       	mov    %al,0x17a25d
  101dc0:	0f b6 05 5d a2 17 00 	movzbl 0x17a25d,%eax
  101dc7:	83 c8 80             	or     $0xffffff80,%eax
  101dca:	a2 5d a2 17 00       	mov    %al,0x17a25d
  101dcf:	b8 16 35 10 00       	mov    $0x103516,%eax
  101dd4:	c1 e8 10             	shr    $0x10,%eax
  101dd7:	66 a3 5e a2 17 00    	mov    %ax,0x17a25e
	SETGATE(idt[T_DBLFLT], 0, CPU_GDT_KCODE, &Xdblflt, 0);
  101ddd:	b8 20 35 10 00       	mov    $0x103520,%eax
  101de2:	66 a3 60 a2 17 00    	mov    %ax,0x17a260
  101de8:	66 c7 05 62 a2 17 00 	movw   $0x8,0x17a262
  101def:	08 00 
  101df1:	0f b6 05 64 a2 17 00 	movzbl 0x17a264,%eax
  101df8:	83 e0 e0             	and    $0xffffffe0,%eax
  101dfb:	a2 64 a2 17 00       	mov    %al,0x17a264
  101e00:	0f b6 05 64 a2 17 00 	movzbl 0x17a264,%eax
  101e07:	83 e0 1f             	and    $0x1f,%eax
  101e0a:	a2 64 a2 17 00       	mov    %al,0x17a264
  101e0f:	0f b6 05 65 a2 17 00 	movzbl 0x17a265,%eax
  101e16:	83 e0 f0             	and    $0xfffffff0,%eax
  101e19:	83 c8 0e             	or     $0xe,%eax
  101e1c:	a2 65 a2 17 00       	mov    %al,0x17a265
  101e21:	0f b6 05 65 a2 17 00 	movzbl 0x17a265,%eax
  101e28:	83 e0 ef             	and    $0xffffffef,%eax
  101e2b:	a2 65 a2 17 00       	mov    %al,0x17a265
  101e30:	0f b6 05 65 a2 17 00 	movzbl 0x17a265,%eax
  101e37:	83 e0 9f             	and    $0xffffff9f,%eax
  101e3a:	a2 65 a2 17 00       	mov    %al,0x17a265
  101e3f:	0f b6 05 65 a2 17 00 	movzbl 0x17a265,%eax
  101e46:	83 c8 80             	or     $0xffffff80,%eax
  101e49:	a2 65 a2 17 00       	mov    %al,0x17a265
  101e4e:	b8 20 35 10 00       	mov    $0x103520,%eax
  101e53:	c1 e8 10             	shr    $0x10,%eax
  101e56:	66 a3 66 a2 17 00    	mov    %ax,0x17a266
	SETGATE(idt[T_TSS],    0, CPU_GDT_KCODE, &Xtss,    0);
  101e5c:	b8 28 35 10 00       	mov    $0x103528,%eax
  101e61:	66 a3 70 a2 17 00    	mov    %ax,0x17a270
  101e67:	66 c7 05 72 a2 17 00 	movw   $0x8,0x17a272
  101e6e:	08 00 
  101e70:	0f b6 05 74 a2 17 00 	movzbl 0x17a274,%eax
  101e77:	83 e0 e0             	and    $0xffffffe0,%eax
  101e7a:	a2 74 a2 17 00       	mov    %al,0x17a274
  101e7f:	0f b6 05 74 a2 17 00 	movzbl 0x17a274,%eax
  101e86:	83 e0 1f             	and    $0x1f,%eax
  101e89:	a2 74 a2 17 00       	mov    %al,0x17a274
  101e8e:	0f b6 05 75 a2 17 00 	movzbl 0x17a275,%eax
  101e95:	83 e0 f0             	and    $0xfffffff0,%eax
  101e98:	83 c8 0e             	or     $0xe,%eax
  101e9b:	a2 75 a2 17 00       	mov    %al,0x17a275
  101ea0:	0f b6 05 75 a2 17 00 	movzbl 0x17a275,%eax
  101ea7:	83 e0 ef             	and    $0xffffffef,%eax
  101eaa:	a2 75 a2 17 00       	mov    %al,0x17a275
  101eaf:	0f b6 05 75 a2 17 00 	movzbl 0x17a275,%eax
  101eb6:	83 e0 9f             	and    $0xffffff9f,%eax
  101eb9:	a2 75 a2 17 00       	mov    %al,0x17a275
  101ebe:	0f b6 05 75 a2 17 00 	movzbl 0x17a275,%eax
  101ec5:	83 c8 80             	or     $0xffffff80,%eax
  101ec8:	a2 75 a2 17 00       	mov    %al,0x17a275
  101ecd:	b8 28 35 10 00       	mov    $0x103528,%eax
  101ed2:	c1 e8 10             	shr    $0x10,%eax
  101ed5:	66 a3 76 a2 17 00    	mov    %ax,0x17a276
	SETGATE(idt[T_SEGNP],  0, CPU_GDT_KCODE, &Xsegnp,  0);
  101edb:	b8 30 35 10 00       	mov    $0x103530,%eax
  101ee0:	66 a3 78 a2 17 00    	mov    %ax,0x17a278
  101ee6:	66 c7 05 7a a2 17 00 	movw   $0x8,0x17a27a
  101eed:	08 00 
  101eef:	0f b6 05 7c a2 17 00 	movzbl 0x17a27c,%eax
  101ef6:	83 e0 e0             	and    $0xffffffe0,%eax
  101ef9:	a2 7c a2 17 00       	mov    %al,0x17a27c
  101efe:	0f b6 05 7c a2 17 00 	movzbl 0x17a27c,%eax
  101f05:	83 e0 1f             	and    $0x1f,%eax
  101f08:	a2 7c a2 17 00       	mov    %al,0x17a27c
  101f0d:	0f b6 05 7d a2 17 00 	movzbl 0x17a27d,%eax
  101f14:	83 e0 f0             	and    $0xfffffff0,%eax
  101f17:	83 c8 0e             	or     $0xe,%eax
  101f1a:	a2 7d a2 17 00       	mov    %al,0x17a27d
  101f1f:	0f b6 05 7d a2 17 00 	movzbl 0x17a27d,%eax
  101f26:	83 e0 ef             	and    $0xffffffef,%eax
  101f29:	a2 7d a2 17 00       	mov    %al,0x17a27d
  101f2e:	0f b6 05 7d a2 17 00 	movzbl 0x17a27d,%eax
  101f35:	83 e0 9f             	and    $0xffffff9f,%eax
  101f38:	a2 7d a2 17 00       	mov    %al,0x17a27d
  101f3d:	0f b6 05 7d a2 17 00 	movzbl 0x17a27d,%eax
  101f44:	83 c8 80             	or     $0xffffff80,%eax
  101f47:	a2 7d a2 17 00       	mov    %al,0x17a27d
  101f4c:	b8 30 35 10 00       	mov    $0x103530,%eax
  101f51:	c1 e8 10             	shr    $0x10,%eax
  101f54:	66 a3 7e a2 17 00    	mov    %ax,0x17a27e
	SETGATE(idt[T_STACK],  0, CPU_GDT_KCODE, &Xstack,  0);
  101f5a:	b8 38 35 10 00       	mov    $0x103538,%eax
  101f5f:	66 a3 80 a2 17 00    	mov    %ax,0x17a280
  101f65:	66 c7 05 82 a2 17 00 	movw   $0x8,0x17a282
  101f6c:	08 00 
  101f6e:	0f b6 05 84 a2 17 00 	movzbl 0x17a284,%eax
  101f75:	83 e0 e0             	and    $0xffffffe0,%eax
  101f78:	a2 84 a2 17 00       	mov    %al,0x17a284
  101f7d:	0f b6 05 84 a2 17 00 	movzbl 0x17a284,%eax
  101f84:	83 e0 1f             	and    $0x1f,%eax
  101f87:	a2 84 a2 17 00       	mov    %al,0x17a284
  101f8c:	0f b6 05 85 a2 17 00 	movzbl 0x17a285,%eax
  101f93:	83 e0 f0             	and    $0xfffffff0,%eax
  101f96:	83 c8 0e             	or     $0xe,%eax
  101f99:	a2 85 a2 17 00       	mov    %al,0x17a285
  101f9e:	0f b6 05 85 a2 17 00 	movzbl 0x17a285,%eax
  101fa5:	83 e0 ef             	and    $0xffffffef,%eax
  101fa8:	a2 85 a2 17 00       	mov    %al,0x17a285
  101fad:	0f b6 05 85 a2 17 00 	movzbl 0x17a285,%eax
  101fb4:	83 e0 9f             	and    $0xffffff9f,%eax
  101fb7:	a2 85 a2 17 00       	mov    %al,0x17a285
  101fbc:	0f b6 05 85 a2 17 00 	movzbl 0x17a285,%eax
  101fc3:	83 c8 80             	or     $0xffffff80,%eax
  101fc6:	a2 85 a2 17 00       	mov    %al,0x17a285
  101fcb:	b8 38 35 10 00       	mov    $0x103538,%eax
  101fd0:	c1 e8 10             	shr    $0x10,%eax
  101fd3:	66 a3 86 a2 17 00    	mov    %ax,0x17a286
	SETGATE(idt[T_GPFLT],  0, CPU_GDT_KCODE, &Xgpflt,  0);
  101fd9:	b8 40 35 10 00       	mov    $0x103540,%eax
  101fde:	66 a3 88 a2 17 00    	mov    %ax,0x17a288
  101fe4:	66 c7 05 8a a2 17 00 	movw   $0x8,0x17a28a
  101feb:	08 00 
  101fed:	0f b6 05 8c a2 17 00 	movzbl 0x17a28c,%eax
  101ff4:	83 e0 e0             	and    $0xffffffe0,%eax
  101ff7:	a2 8c a2 17 00       	mov    %al,0x17a28c
  101ffc:	0f b6 05 8c a2 17 00 	movzbl 0x17a28c,%eax
  102003:	83 e0 1f             	and    $0x1f,%eax
  102006:	a2 8c a2 17 00       	mov    %al,0x17a28c
  10200b:	0f b6 05 8d a2 17 00 	movzbl 0x17a28d,%eax
  102012:	83 e0 f0             	and    $0xfffffff0,%eax
  102015:	83 c8 0e             	or     $0xe,%eax
  102018:	a2 8d a2 17 00       	mov    %al,0x17a28d
  10201d:	0f b6 05 8d a2 17 00 	movzbl 0x17a28d,%eax
  102024:	83 e0 ef             	and    $0xffffffef,%eax
  102027:	a2 8d a2 17 00       	mov    %al,0x17a28d
  10202c:	0f b6 05 8d a2 17 00 	movzbl 0x17a28d,%eax
  102033:	83 e0 9f             	and    $0xffffff9f,%eax
  102036:	a2 8d a2 17 00       	mov    %al,0x17a28d
  10203b:	0f b6 05 8d a2 17 00 	movzbl 0x17a28d,%eax
  102042:	83 c8 80             	or     $0xffffff80,%eax
  102045:	a2 8d a2 17 00       	mov    %al,0x17a28d
  10204a:	b8 40 35 10 00       	mov    $0x103540,%eax
  10204f:	c1 e8 10             	shr    $0x10,%eax
  102052:	66 a3 8e a2 17 00    	mov    %ax,0x17a28e
	SETGATE(idt[T_PGFLT],  0, CPU_GDT_KCODE, &Xpgflt,  0);
  102058:	b8 48 35 10 00       	mov    $0x103548,%eax
  10205d:	66 a3 90 a2 17 00    	mov    %ax,0x17a290
  102063:	66 c7 05 92 a2 17 00 	movw   $0x8,0x17a292
  10206a:	08 00 
  10206c:	0f b6 05 94 a2 17 00 	movzbl 0x17a294,%eax
  102073:	83 e0 e0             	and    $0xffffffe0,%eax
  102076:	a2 94 a2 17 00       	mov    %al,0x17a294
  10207b:	0f b6 05 94 a2 17 00 	movzbl 0x17a294,%eax
  102082:	83 e0 1f             	and    $0x1f,%eax
  102085:	a2 94 a2 17 00       	mov    %al,0x17a294
  10208a:	0f b6 05 95 a2 17 00 	movzbl 0x17a295,%eax
  102091:	83 e0 f0             	and    $0xfffffff0,%eax
  102094:	83 c8 0e             	or     $0xe,%eax
  102097:	a2 95 a2 17 00       	mov    %al,0x17a295
  10209c:	0f b6 05 95 a2 17 00 	movzbl 0x17a295,%eax
  1020a3:	83 e0 ef             	and    $0xffffffef,%eax
  1020a6:	a2 95 a2 17 00       	mov    %al,0x17a295
  1020ab:	0f b6 05 95 a2 17 00 	movzbl 0x17a295,%eax
  1020b2:	83 e0 9f             	and    $0xffffff9f,%eax
  1020b5:	a2 95 a2 17 00       	mov    %al,0x17a295
  1020ba:	0f b6 05 95 a2 17 00 	movzbl 0x17a295,%eax
  1020c1:	83 c8 80             	or     $0xffffff80,%eax
  1020c4:	a2 95 a2 17 00       	mov    %al,0x17a295
  1020c9:	b8 48 35 10 00       	mov    $0x103548,%eax
  1020ce:	c1 e8 10             	shr    $0x10,%eax
  1020d1:	66 a3 96 a2 17 00    	mov    %ax,0x17a296
	SETGATE(idt[T_FPERR],  0, CPU_GDT_KCODE, &Xfperr,  0);
  1020d7:	b8 50 35 10 00       	mov    $0x103550,%eax
  1020dc:	66 a3 a0 a2 17 00    	mov    %ax,0x17a2a0
  1020e2:	66 c7 05 a2 a2 17 00 	movw   $0x8,0x17a2a2
  1020e9:	08 00 
  1020eb:	0f b6 05 a4 a2 17 00 	movzbl 0x17a2a4,%eax
  1020f2:	83 e0 e0             	and    $0xffffffe0,%eax
  1020f5:	a2 a4 a2 17 00       	mov    %al,0x17a2a4
  1020fa:	0f b6 05 a4 a2 17 00 	movzbl 0x17a2a4,%eax
  102101:	83 e0 1f             	and    $0x1f,%eax
  102104:	a2 a4 a2 17 00       	mov    %al,0x17a2a4
  102109:	0f b6 05 a5 a2 17 00 	movzbl 0x17a2a5,%eax
  102110:	83 e0 f0             	and    $0xfffffff0,%eax
  102113:	83 c8 0e             	or     $0xe,%eax
  102116:	a2 a5 a2 17 00       	mov    %al,0x17a2a5
  10211b:	0f b6 05 a5 a2 17 00 	movzbl 0x17a2a5,%eax
  102122:	83 e0 ef             	and    $0xffffffef,%eax
  102125:	a2 a5 a2 17 00       	mov    %al,0x17a2a5
  10212a:	0f b6 05 a5 a2 17 00 	movzbl 0x17a2a5,%eax
  102131:	83 e0 9f             	and    $0xffffff9f,%eax
  102134:	a2 a5 a2 17 00       	mov    %al,0x17a2a5
  102139:	0f b6 05 a5 a2 17 00 	movzbl 0x17a2a5,%eax
  102140:	83 c8 80             	or     $0xffffff80,%eax
  102143:	a2 a5 a2 17 00       	mov    %al,0x17a2a5
  102148:	b8 50 35 10 00       	mov    $0x103550,%eax
  10214d:	c1 e8 10             	shr    $0x10,%eax
  102150:	66 a3 a6 a2 17 00    	mov    %ax,0x17a2a6
	SETGATE(idt[T_ALIGN],  0, CPU_GDT_KCODE, &Xalign,  0);
  102156:	b8 5a 35 10 00       	mov    $0x10355a,%eax
  10215b:	66 a3 a8 a2 17 00    	mov    %ax,0x17a2a8
  102161:	66 c7 05 aa a2 17 00 	movw   $0x8,0x17a2aa
  102168:	08 00 
  10216a:	0f b6 05 ac a2 17 00 	movzbl 0x17a2ac,%eax
  102171:	83 e0 e0             	and    $0xffffffe0,%eax
  102174:	a2 ac a2 17 00       	mov    %al,0x17a2ac
  102179:	0f b6 05 ac a2 17 00 	movzbl 0x17a2ac,%eax
  102180:	83 e0 1f             	and    $0x1f,%eax
  102183:	a2 ac a2 17 00       	mov    %al,0x17a2ac
  102188:	0f b6 05 ad a2 17 00 	movzbl 0x17a2ad,%eax
  10218f:	83 e0 f0             	and    $0xfffffff0,%eax
  102192:	83 c8 0e             	or     $0xe,%eax
  102195:	a2 ad a2 17 00       	mov    %al,0x17a2ad
  10219a:	0f b6 05 ad a2 17 00 	movzbl 0x17a2ad,%eax
  1021a1:	83 e0 ef             	and    $0xffffffef,%eax
  1021a4:	a2 ad a2 17 00       	mov    %al,0x17a2ad
  1021a9:	0f b6 05 ad a2 17 00 	movzbl 0x17a2ad,%eax
  1021b0:	83 e0 9f             	and    $0xffffff9f,%eax
  1021b3:	a2 ad a2 17 00       	mov    %al,0x17a2ad
  1021b8:	0f b6 05 ad a2 17 00 	movzbl 0x17a2ad,%eax
  1021bf:	83 c8 80             	or     $0xffffff80,%eax
  1021c2:	a2 ad a2 17 00       	mov    %al,0x17a2ad
  1021c7:	b8 5a 35 10 00       	mov    $0x10355a,%eax
  1021cc:	c1 e8 10             	shr    $0x10,%eax
  1021cf:	66 a3 ae a2 17 00    	mov    %ax,0x17a2ae
	SETGATE(idt[T_MCHK],   0, CPU_GDT_KCODE, &Xmchk,   0);
  1021d5:	b8 62 35 10 00       	mov    $0x103562,%eax
  1021da:	66 a3 b0 a2 17 00    	mov    %ax,0x17a2b0
  1021e0:	66 c7 05 b2 a2 17 00 	movw   $0x8,0x17a2b2
  1021e7:	08 00 
  1021e9:	0f b6 05 b4 a2 17 00 	movzbl 0x17a2b4,%eax
  1021f0:	83 e0 e0             	and    $0xffffffe0,%eax
  1021f3:	a2 b4 a2 17 00       	mov    %al,0x17a2b4
  1021f8:	0f b6 05 b4 a2 17 00 	movzbl 0x17a2b4,%eax
  1021ff:	83 e0 1f             	and    $0x1f,%eax
  102202:	a2 b4 a2 17 00       	mov    %al,0x17a2b4
  102207:	0f b6 05 b5 a2 17 00 	movzbl 0x17a2b5,%eax
  10220e:	83 e0 f0             	and    $0xfffffff0,%eax
  102211:	83 c8 0e             	or     $0xe,%eax
  102214:	a2 b5 a2 17 00       	mov    %al,0x17a2b5
  102219:	0f b6 05 b5 a2 17 00 	movzbl 0x17a2b5,%eax
  102220:	83 e0 ef             	and    $0xffffffef,%eax
  102223:	a2 b5 a2 17 00       	mov    %al,0x17a2b5
  102228:	0f b6 05 b5 a2 17 00 	movzbl 0x17a2b5,%eax
  10222f:	83 e0 9f             	and    $0xffffff9f,%eax
  102232:	a2 b5 a2 17 00       	mov    %al,0x17a2b5
  102237:	0f b6 05 b5 a2 17 00 	movzbl 0x17a2b5,%eax
  10223e:	83 c8 80             	or     $0xffffff80,%eax
  102241:	a2 b5 a2 17 00       	mov    %al,0x17a2b5
  102246:	b8 62 35 10 00       	mov    $0x103562,%eax
  10224b:	c1 e8 10             	shr    $0x10,%eax
  10224e:	66 a3 b6 a2 17 00    	mov    %ax,0x17a2b6
	SETGATE(idt[T_SIMD],   0, CPU_GDT_KCODE, &Xsimd,   0);
  102254:	b8 6c 35 10 00       	mov    $0x10356c,%eax
  102259:	66 a3 b8 a2 17 00    	mov    %ax,0x17a2b8
  10225f:	66 c7 05 ba a2 17 00 	movw   $0x8,0x17a2ba
  102266:	08 00 
  102268:	0f b6 05 bc a2 17 00 	movzbl 0x17a2bc,%eax
  10226f:	83 e0 e0             	and    $0xffffffe0,%eax
  102272:	a2 bc a2 17 00       	mov    %al,0x17a2bc
  102277:	0f b6 05 bc a2 17 00 	movzbl 0x17a2bc,%eax
  10227e:	83 e0 1f             	and    $0x1f,%eax
  102281:	a2 bc a2 17 00       	mov    %al,0x17a2bc
  102286:	0f b6 05 bd a2 17 00 	movzbl 0x17a2bd,%eax
  10228d:	83 e0 f0             	and    $0xfffffff0,%eax
  102290:	83 c8 0e             	or     $0xe,%eax
  102293:	a2 bd a2 17 00       	mov    %al,0x17a2bd
  102298:	0f b6 05 bd a2 17 00 	movzbl 0x17a2bd,%eax
  10229f:	83 e0 ef             	and    $0xffffffef,%eax
  1022a2:	a2 bd a2 17 00       	mov    %al,0x17a2bd
  1022a7:	0f b6 05 bd a2 17 00 	movzbl 0x17a2bd,%eax
  1022ae:	83 e0 9f             	and    $0xffffff9f,%eax
  1022b1:	a2 bd a2 17 00       	mov    %al,0x17a2bd
  1022b6:	0f b6 05 bd a2 17 00 	movzbl 0x17a2bd,%eax
  1022bd:	83 c8 80             	or     $0xffffff80,%eax
  1022c0:	a2 bd a2 17 00       	mov    %al,0x17a2bd
  1022c5:	b8 6c 35 10 00       	mov    $0x10356c,%eax
  1022ca:	c1 e8 10             	shr    $0x10,%eax
  1022cd:	66 a3 be a2 17 00    	mov    %ax,0x17a2be

	SETGATE(idt[T_IRQ0 + 0], 0, CPU_GDT_KCODE, &Xirq0, 0);
  1022d3:	b8 76 35 10 00       	mov    $0x103576,%eax
  1022d8:	66 a3 20 a3 17 00    	mov    %ax,0x17a320
  1022de:	66 c7 05 22 a3 17 00 	movw   $0x8,0x17a322
  1022e5:	08 00 
  1022e7:	0f b6 05 24 a3 17 00 	movzbl 0x17a324,%eax
  1022ee:	83 e0 e0             	and    $0xffffffe0,%eax
  1022f1:	a2 24 a3 17 00       	mov    %al,0x17a324
  1022f6:	0f b6 05 24 a3 17 00 	movzbl 0x17a324,%eax
  1022fd:	83 e0 1f             	and    $0x1f,%eax
  102300:	a2 24 a3 17 00       	mov    %al,0x17a324
  102305:	0f b6 05 25 a3 17 00 	movzbl 0x17a325,%eax
  10230c:	83 e0 f0             	and    $0xfffffff0,%eax
  10230f:	83 c8 0e             	or     $0xe,%eax
  102312:	a2 25 a3 17 00       	mov    %al,0x17a325
  102317:	0f b6 05 25 a3 17 00 	movzbl 0x17a325,%eax
  10231e:	83 e0 ef             	and    $0xffffffef,%eax
  102321:	a2 25 a3 17 00       	mov    %al,0x17a325
  102326:	0f b6 05 25 a3 17 00 	movzbl 0x17a325,%eax
  10232d:	83 e0 9f             	and    $0xffffff9f,%eax
  102330:	a2 25 a3 17 00       	mov    %al,0x17a325
  102335:	0f b6 05 25 a3 17 00 	movzbl 0x17a325,%eax
  10233c:	83 c8 80             	or     $0xffffff80,%eax
  10233f:	a2 25 a3 17 00       	mov    %al,0x17a325
  102344:	b8 76 35 10 00       	mov    $0x103576,%eax
  102349:	c1 e8 10             	shr    $0x10,%eax
  10234c:	66 a3 26 a3 17 00    	mov    %ax,0x17a326
	SETGATE(idt[T_IRQ0 + 1], 0, CPU_GDT_KCODE, &Xirq1, 0);
  102352:	b8 80 35 10 00       	mov    $0x103580,%eax
  102357:	66 a3 28 a3 17 00    	mov    %ax,0x17a328
  10235d:	66 c7 05 2a a3 17 00 	movw   $0x8,0x17a32a
  102364:	08 00 
  102366:	0f b6 05 2c a3 17 00 	movzbl 0x17a32c,%eax
  10236d:	83 e0 e0             	and    $0xffffffe0,%eax
  102370:	a2 2c a3 17 00       	mov    %al,0x17a32c
  102375:	0f b6 05 2c a3 17 00 	movzbl 0x17a32c,%eax
  10237c:	83 e0 1f             	and    $0x1f,%eax
  10237f:	a2 2c a3 17 00       	mov    %al,0x17a32c
  102384:	0f b6 05 2d a3 17 00 	movzbl 0x17a32d,%eax
  10238b:	83 e0 f0             	and    $0xfffffff0,%eax
  10238e:	83 c8 0e             	or     $0xe,%eax
  102391:	a2 2d a3 17 00       	mov    %al,0x17a32d
  102396:	0f b6 05 2d a3 17 00 	movzbl 0x17a32d,%eax
  10239d:	83 e0 ef             	and    $0xffffffef,%eax
  1023a0:	a2 2d a3 17 00       	mov    %al,0x17a32d
  1023a5:	0f b6 05 2d a3 17 00 	movzbl 0x17a32d,%eax
  1023ac:	83 e0 9f             	and    $0xffffff9f,%eax
  1023af:	a2 2d a3 17 00       	mov    %al,0x17a32d
  1023b4:	0f b6 05 2d a3 17 00 	movzbl 0x17a32d,%eax
  1023bb:	83 c8 80             	or     $0xffffff80,%eax
  1023be:	a2 2d a3 17 00       	mov    %al,0x17a32d
  1023c3:	b8 80 35 10 00       	mov    $0x103580,%eax
  1023c8:	c1 e8 10             	shr    $0x10,%eax
  1023cb:	66 a3 2e a3 17 00    	mov    %ax,0x17a32e
	SETGATE(idt[T_IRQ0 + 2], 0, CPU_GDT_KCODE, &Xirq2, 0);
  1023d1:	b8 8a 35 10 00       	mov    $0x10358a,%eax
  1023d6:	66 a3 30 a3 17 00    	mov    %ax,0x17a330
  1023dc:	66 c7 05 32 a3 17 00 	movw   $0x8,0x17a332
  1023e3:	08 00 
  1023e5:	0f b6 05 34 a3 17 00 	movzbl 0x17a334,%eax
  1023ec:	83 e0 e0             	and    $0xffffffe0,%eax
  1023ef:	a2 34 a3 17 00       	mov    %al,0x17a334
  1023f4:	0f b6 05 34 a3 17 00 	movzbl 0x17a334,%eax
  1023fb:	83 e0 1f             	and    $0x1f,%eax
  1023fe:	a2 34 a3 17 00       	mov    %al,0x17a334
  102403:	0f b6 05 35 a3 17 00 	movzbl 0x17a335,%eax
  10240a:	83 e0 f0             	and    $0xfffffff0,%eax
  10240d:	83 c8 0e             	or     $0xe,%eax
  102410:	a2 35 a3 17 00       	mov    %al,0x17a335
  102415:	0f b6 05 35 a3 17 00 	movzbl 0x17a335,%eax
  10241c:	83 e0 ef             	and    $0xffffffef,%eax
  10241f:	a2 35 a3 17 00       	mov    %al,0x17a335
  102424:	0f b6 05 35 a3 17 00 	movzbl 0x17a335,%eax
  10242b:	83 e0 9f             	and    $0xffffff9f,%eax
  10242e:	a2 35 a3 17 00       	mov    %al,0x17a335
  102433:	0f b6 05 35 a3 17 00 	movzbl 0x17a335,%eax
  10243a:	83 c8 80             	or     $0xffffff80,%eax
  10243d:	a2 35 a3 17 00       	mov    %al,0x17a335
  102442:	b8 8a 35 10 00       	mov    $0x10358a,%eax
  102447:	c1 e8 10             	shr    $0x10,%eax
  10244a:	66 a3 36 a3 17 00    	mov    %ax,0x17a336
	SETGATE(idt[T_IRQ0 + 3], 0, CPU_GDT_KCODE, &Xirq3, 0);
  102450:	b8 94 35 10 00       	mov    $0x103594,%eax
  102455:	66 a3 38 a3 17 00    	mov    %ax,0x17a338
  10245b:	66 c7 05 3a a3 17 00 	movw   $0x8,0x17a33a
  102462:	08 00 
  102464:	0f b6 05 3c a3 17 00 	movzbl 0x17a33c,%eax
  10246b:	83 e0 e0             	and    $0xffffffe0,%eax
  10246e:	a2 3c a3 17 00       	mov    %al,0x17a33c
  102473:	0f b6 05 3c a3 17 00 	movzbl 0x17a33c,%eax
  10247a:	83 e0 1f             	and    $0x1f,%eax
  10247d:	a2 3c a3 17 00       	mov    %al,0x17a33c
  102482:	0f b6 05 3d a3 17 00 	movzbl 0x17a33d,%eax
  102489:	83 e0 f0             	and    $0xfffffff0,%eax
  10248c:	83 c8 0e             	or     $0xe,%eax
  10248f:	a2 3d a3 17 00       	mov    %al,0x17a33d
  102494:	0f b6 05 3d a3 17 00 	movzbl 0x17a33d,%eax
  10249b:	83 e0 ef             	and    $0xffffffef,%eax
  10249e:	a2 3d a3 17 00       	mov    %al,0x17a33d
  1024a3:	0f b6 05 3d a3 17 00 	movzbl 0x17a33d,%eax
  1024aa:	83 e0 9f             	and    $0xffffff9f,%eax
  1024ad:	a2 3d a3 17 00       	mov    %al,0x17a33d
  1024b2:	0f b6 05 3d a3 17 00 	movzbl 0x17a33d,%eax
  1024b9:	83 c8 80             	or     $0xffffff80,%eax
  1024bc:	a2 3d a3 17 00       	mov    %al,0x17a33d
  1024c1:	b8 94 35 10 00       	mov    $0x103594,%eax
  1024c6:	c1 e8 10             	shr    $0x10,%eax
  1024c9:	66 a3 3e a3 17 00    	mov    %ax,0x17a33e
	SETGATE(idt[T_IRQ0 + 4], 0, CPU_GDT_KCODE, &Xirq4, 0);
  1024cf:	b8 9e 35 10 00       	mov    $0x10359e,%eax
  1024d4:	66 a3 40 a3 17 00    	mov    %ax,0x17a340
  1024da:	66 c7 05 42 a3 17 00 	movw   $0x8,0x17a342
  1024e1:	08 00 
  1024e3:	0f b6 05 44 a3 17 00 	movzbl 0x17a344,%eax
  1024ea:	83 e0 e0             	and    $0xffffffe0,%eax
  1024ed:	a2 44 a3 17 00       	mov    %al,0x17a344
  1024f2:	0f b6 05 44 a3 17 00 	movzbl 0x17a344,%eax
  1024f9:	83 e0 1f             	and    $0x1f,%eax
  1024fc:	a2 44 a3 17 00       	mov    %al,0x17a344
  102501:	0f b6 05 45 a3 17 00 	movzbl 0x17a345,%eax
  102508:	83 e0 f0             	and    $0xfffffff0,%eax
  10250b:	83 c8 0e             	or     $0xe,%eax
  10250e:	a2 45 a3 17 00       	mov    %al,0x17a345
  102513:	0f b6 05 45 a3 17 00 	movzbl 0x17a345,%eax
  10251a:	83 e0 ef             	and    $0xffffffef,%eax
  10251d:	a2 45 a3 17 00       	mov    %al,0x17a345
  102522:	0f b6 05 45 a3 17 00 	movzbl 0x17a345,%eax
  102529:	83 e0 9f             	and    $0xffffff9f,%eax
  10252c:	a2 45 a3 17 00       	mov    %al,0x17a345
  102531:	0f b6 05 45 a3 17 00 	movzbl 0x17a345,%eax
  102538:	83 c8 80             	or     $0xffffff80,%eax
  10253b:	a2 45 a3 17 00       	mov    %al,0x17a345
  102540:	b8 9e 35 10 00       	mov    $0x10359e,%eax
  102545:	c1 e8 10             	shr    $0x10,%eax
  102548:	66 a3 46 a3 17 00    	mov    %ax,0x17a346
	SETGATE(idt[T_IRQ0 + 5], 0, CPU_GDT_KCODE, &Xirq5, 0);
  10254e:	b8 a8 35 10 00       	mov    $0x1035a8,%eax
  102553:	66 a3 48 a3 17 00    	mov    %ax,0x17a348
  102559:	66 c7 05 4a a3 17 00 	movw   $0x8,0x17a34a
  102560:	08 00 
  102562:	0f b6 05 4c a3 17 00 	movzbl 0x17a34c,%eax
  102569:	83 e0 e0             	and    $0xffffffe0,%eax
  10256c:	a2 4c a3 17 00       	mov    %al,0x17a34c
  102571:	0f b6 05 4c a3 17 00 	movzbl 0x17a34c,%eax
  102578:	83 e0 1f             	and    $0x1f,%eax
  10257b:	a2 4c a3 17 00       	mov    %al,0x17a34c
  102580:	0f b6 05 4d a3 17 00 	movzbl 0x17a34d,%eax
  102587:	83 e0 f0             	and    $0xfffffff0,%eax
  10258a:	83 c8 0e             	or     $0xe,%eax
  10258d:	a2 4d a3 17 00       	mov    %al,0x17a34d
  102592:	0f b6 05 4d a3 17 00 	movzbl 0x17a34d,%eax
  102599:	83 e0 ef             	and    $0xffffffef,%eax
  10259c:	a2 4d a3 17 00       	mov    %al,0x17a34d
  1025a1:	0f b6 05 4d a3 17 00 	movzbl 0x17a34d,%eax
  1025a8:	83 e0 9f             	and    $0xffffff9f,%eax
  1025ab:	a2 4d a3 17 00       	mov    %al,0x17a34d
  1025b0:	0f b6 05 4d a3 17 00 	movzbl 0x17a34d,%eax
  1025b7:	83 c8 80             	or     $0xffffff80,%eax
  1025ba:	a2 4d a3 17 00       	mov    %al,0x17a34d
  1025bf:	b8 a8 35 10 00       	mov    $0x1035a8,%eax
  1025c4:	c1 e8 10             	shr    $0x10,%eax
  1025c7:	66 a3 4e a3 17 00    	mov    %ax,0x17a34e
	SETGATE(idt[T_IRQ0 + 6], 0, CPU_GDT_KCODE, &Xirq6, 0);
  1025cd:	b8 b2 35 10 00       	mov    $0x1035b2,%eax
  1025d2:	66 a3 50 a3 17 00    	mov    %ax,0x17a350
  1025d8:	66 c7 05 52 a3 17 00 	movw   $0x8,0x17a352
  1025df:	08 00 
  1025e1:	0f b6 05 54 a3 17 00 	movzbl 0x17a354,%eax
  1025e8:	83 e0 e0             	and    $0xffffffe0,%eax
  1025eb:	a2 54 a3 17 00       	mov    %al,0x17a354
  1025f0:	0f b6 05 54 a3 17 00 	movzbl 0x17a354,%eax
  1025f7:	83 e0 1f             	and    $0x1f,%eax
  1025fa:	a2 54 a3 17 00       	mov    %al,0x17a354
  1025ff:	0f b6 05 55 a3 17 00 	movzbl 0x17a355,%eax
  102606:	83 e0 f0             	and    $0xfffffff0,%eax
  102609:	83 c8 0e             	or     $0xe,%eax
  10260c:	a2 55 a3 17 00       	mov    %al,0x17a355
  102611:	0f b6 05 55 a3 17 00 	movzbl 0x17a355,%eax
  102618:	83 e0 ef             	and    $0xffffffef,%eax
  10261b:	a2 55 a3 17 00       	mov    %al,0x17a355
  102620:	0f b6 05 55 a3 17 00 	movzbl 0x17a355,%eax
  102627:	83 e0 9f             	and    $0xffffff9f,%eax
  10262a:	a2 55 a3 17 00       	mov    %al,0x17a355
  10262f:	0f b6 05 55 a3 17 00 	movzbl 0x17a355,%eax
  102636:	83 c8 80             	or     $0xffffff80,%eax
  102639:	a2 55 a3 17 00       	mov    %al,0x17a355
  10263e:	b8 b2 35 10 00       	mov    $0x1035b2,%eax
  102643:	c1 e8 10             	shr    $0x10,%eax
  102646:	66 a3 56 a3 17 00    	mov    %ax,0x17a356
	SETGATE(idt[T_IRQ0 + 7], 0, CPU_GDT_KCODE, &Xirq7, 0);
  10264c:	b8 bc 35 10 00       	mov    $0x1035bc,%eax
  102651:	66 a3 58 a3 17 00    	mov    %ax,0x17a358
  102657:	66 c7 05 5a a3 17 00 	movw   $0x8,0x17a35a
  10265e:	08 00 
  102660:	0f b6 05 5c a3 17 00 	movzbl 0x17a35c,%eax
  102667:	83 e0 e0             	and    $0xffffffe0,%eax
  10266a:	a2 5c a3 17 00       	mov    %al,0x17a35c
  10266f:	0f b6 05 5c a3 17 00 	movzbl 0x17a35c,%eax
  102676:	83 e0 1f             	and    $0x1f,%eax
  102679:	a2 5c a3 17 00       	mov    %al,0x17a35c
  10267e:	0f b6 05 5d a3 17 00 	movzbl 0x17a35d,%eax
  102685:	83 e0 f0             	and    $0xfffffff0,%eax
  102688:	83 c8 0e             	or     $0xe,%eax
  10268b:	a2 5d a3 17 00       	mov    %al,0x17a35d
  102690:	0f b6 05 5d a3 17 00 	movzbl 0x17a35d,%eax
  102697:	83 e0 ef             	and    $0xffffffef,%eax
  10269a:	a2 5d a3 17 00       	mov    %al,0x17a35d
  10269f:	0f b6 05 5d a3 17 00 	movzbl 0x17a35d,%eax
  1026a6:	83 e0 9f             	and    $0xffffff9f,%eax
  1026a9:	a2 5d a3 17 00       	mov    %al,0x17a35d
  1026ae:	0f b6 05 5d a3 17 00 	movzbl 0x17a35d,%eax
  1026b5:	83 c8 80             	or     $0xffffff80,%eax
  1026b8:	a2 5d a3 17 00       	mov    %al,0x17a35d
  1026bd:	b8 bc 35 10 00       	mov    $0x1035bc,%eax
  1026c2:	c1 e8 10             	shr    $0x10,%eax
  1026c5:	66 a3 5e a3 17 00    	mov    %ax,0x17a35e
	SETGATE(idt[T_IRQ0 + 8], 0, CPU_GDT_KCODE, &Xirq8, 0);
  1026cb:	b8 c6 35 10 00       	mov    $0x1035c6,%eax
  1026d0:	66 a3 60 a3 17 00    	mov    %ax,0x17a360
  1026d6:	66 c7 05 62 a3 17 00 	movw   $0x8,0x17a362
  1026dd:	08 00 
  1026df:	0f b6 05 64 a3 17 00 	movzbl 0x17a364,%eax
  1026e6:	83 e0 e0             	and    $0xffffffe0,%eax
  1026e9:	a2 64 a3 17 00       	mov    %al,0x17a364
  1026ee:	0f b6 05 64 a3 17 00 	movzbl 0x17a364,%eax
  1026f5:	83 e0 1f             	and    $0x1f,%eax
  1026f8:	a2 64 a3 17 00       	mov    %al,0x17a364
  1026fd:	0f b6 05 65 a3 17 00 	movzbl 0x17a365,%eax
  102704:	83 e0 f0             	and    $0xfffffff0,%eax
  102707:	83 c8 0e             	or     $0xe,%eax
  10270a:	a2 65 a3 17 00       	mov    %al,0x17a365
  10270f:	0f b6 05 65 a3 17 00 	movzbl 0x17a365,%eax
  102716:	83 e0 ef             	and    $0xffffffef,%eax
  102719:	a2 65 a3 17 00       	mov    %al,0x17a365
  10271e:	0f b6 05 65 a3 17 00 	movzbl 0x17a365,%eax
  102725:	83 e0 9f             	and    $0xffffff9f,%eax
  102728:	a2 65 a3 17 00       	mov    %al,0x17a365
  10272d:	0f b6 05 65 a3 17 00 	movzbl 0x17a365,%eax
  102734:	83 c8 80             	or     $0xffffff80,%eax
  102737:	a2 65 a3 17 00       	mov    %al,0x17a365
  10273c:	b8 c6 35 10 00       	mov    $0x1035c6,%eax
  102741:	c1 e8 10             	shr    $0x10,%eax
  102744:	66 a3 66 a3 17 00    	mov    %ax,0x17a366
	SETGATE(idt[T_IRQ0 + 9], 0, CPU_GDT_KCODE, &Xirq9, 0);
  10274a:	b8 d0 35 10 00       	mov    $0x1035d0,%eax
  10274f:	66 a3 68 a3 17 00    	mov    %ax,0x17a368
  102755:	66 c7 05 6a a3 17 00 	movw   $0x8,0x17a36a
  10275c:	08 00 
  10275e:	0f b6 05 6c a3 17 00 	movzbl 0x17a36c,%eax
  102765:	83 e0 e0             	and    $0xffffffe0,%eax
  102768:	a2 6c a3 17 00       	mov    %al,0x17a36c
  10276d:	0f b6 05 6c a3 17 00 	movzbl 0x17a36c,%eax
  102774:	83 e0 1f             	and    $0x1f,%eax
  102777:	a2 6c a3 17 00       	mov    %al,0x17a36c
  10277c:	0f b6 05 6d a3 17 00 	movzbl 0x17a36d,%eax
  102783:	83 e0 f0             	and    $0xfffffff0,%eax
  102786:	83 c8 0e             	or     $0xe,%eax
  102789:	a2 6d a3 17 00       	mov    %al,0x17a36d
  10278e:	0f b6 05 6d a3 17 00 	movzbl 0x17a36d,%eax
  102795:	83 e0 ef             	and    $0xffffffef,%eax
  102798:	a2 6d a3 17 00       	mov    %al,0x17a36d
  10279d:	0f b6 05 6d a3 17 00 	movzbl 0x17a36d,%eax
  1027a4:	83 e0 9f             	and    $0xffffff9f,%eax
  1027a7:	a2 6d a3 17 00       	mov    %al,0x17a36d
  1027ac:	0f b6 05 6d a3 17 00 	movzbl 0x17a36d,%eax
  1027b3:	83 c8 80             	or     $0xffffff80,%eax
  1027b6:	a2 6d a3 17 00       	mov    %al,0x17a36d
  1027bb:	b8 d0 35 10 00       	mov    $0x1035d0,%eax
  1027c0:	c1 e8 10             	shr    $0x10,%eax
  1027c3:	66 a3 6e a3 17 00    	mov    %ax,0x17a36e
	SETGATE(idt[T_IRQ0 + 10], 0, CPU_GDT_KCODE, &Xirq10, 0);
  1027c9:	b8 da 35 10 00       	mov    $0x1035da,%eax
  1027ce:	66 a3 70 a3 17 00    	mov    %ax,0x17a370
  1027d4:	66 c7 05 72 a3 17 00 	movw   $0x8,0x17a372
  1027db:	08 00 
  1027dd:	0f b6 05 74 a3 17 00 	movzbl 0x17a374,%eax
  1027e4:	83 e0 e0             	and    $0xffffffe0,%eax
  1027e7:	a2 74 a3 17 00       	mov    %al,0x17a374
  1027ec:	0f b6 05 74 a3 17 00 	movzbl 0x17a374,%eax
  1027f3:	83 e0 1f             	and    $0x1f,%eax
  1027f6:	a2 74 a3 17 00       	mov    %al,0x17a374
  1027fb:	0f b6 05 75 a3 17 00 	movzbl 0x17a375,%eax
  102802:	83 e0 f0             	and    $0xfffffff0,%eax
  102805:	83 c8 0e             	or     $0xe,%eax
  102808:	a2 75 a3 17 00       	mov    %al,0x17a375
  10280d:	0f b6 05 75 a3 17 00 	movzbl 0x17a375,%eax
  102814:	83 e0 ef             	and    $0xffffffef,%eax
  102817:	a2 75 a3 17 00       	mov    %al,0x17a375
  10281c:	0f b6 05 75 a3 17 00 	movzbl 0x17a375,%eax
  102823:	83 e0 9f             	and    $0xffffff9f,%eax
  102826:	a2 75 a3 17 00       	mov    %al,0x17a375
  10282b:	0f b6 05 75 a3 17 00 	movzbl 0x17a375,%eax
  102832:	83 c8 80             	or     $0xffffff80,%eax
  102835:	a2 75 a3 17 00       	mov    %al,0x17a375
  10283a:	b8 da 35 10 00       	mov    $0x1035da,%eax
  10283f:	c1 e8 10             	shr    $0x10,%eax
  102842:	66 a3 76 a3 17 00    	mov    %ax,0x17a376
	SETGATE(idt[T_IRQ0 + 11], 0, CPU_GDT_KCODE, &Xirq11, 0);
  102848:	b8 e4 35 10 00       	mov    $0x1035e4,%eax
  10284d:	66 a3 78 a3 17 00    	mov    %ax,0x17a378
  102853:	66 c7 05 7a a3 17 00 	movw   $0x8,0x17a37a
  10285a:	08 00 
  10285c:	0f b6 05 7c a3 17 00 	movzbl 0x17a37c,%eax
  102863:	83 e0 e0             	and    $0xffffffe0,%eax
  102866:	a2 7c a3 17 00       	mov    %al,0x17a37c
  10286b:	0f b6 05 7c a3 17 00 	movzbl 0x17a37c,%eax
  102872:	83 e0 1f             	and    $0x1f,%eax
  102875:	a2 7c a3 17 00       	mov    %al,0x17a37c
  10287a:	0f b6 05 7d a3 17 00 	movzbl 0x17a37d,%eax
  102881:	83 e0 f0             	and    $0xfffffff0,%eax
  102884:	83 c8 0e             	or     $0xe,%eax
  102887:	a2 7d a3 17 00       	mov    %al,0x17a37d
  10288c:	0f b6 05 7d a3 17 00 	movzbl 0x17a37d,%eax
  102893:	83 e0 ef             	and    $0xffffffef,%eax
  102896:	a2 7d a3 17 00       	mov    %al,0x17a37d
  10289b:	0f b6 05 7d a3 17 00 	movzbl 0x17a37d,%eax
  1028a2:	83 e0 9f             	and    $0xffffff9f,%eax
  1028a5:	a2 7d a3 17 00       	mov    %al,0x17a37d
  1028aa:	0f b6 05 7d a3 17 00 	movzbl 0x17a37d,%eax
  1028b1:	83 c8 80             	or     $0xffffff80,%eax
  1028b4:	a2 7d a3 17 00       	mov    %al,0x17a37d
  1028b9:	b8 e4 35 10 00       	mov    $0x1035e4,%eax
  1028be:	c1 e8 10             	shr    $0x10,%eax
  1028c1:	66 a3 7e a3 17 00    	mov    %ax,0x17a37e
	SETGATE(idt[T_IRQ0 + 12], 0, CPU_GDT_KCODE, &Xirq12, 0);
  1028c7:	b8 ee 35 10 00       	mov    $0x1035ee,%eax
  1028cc:	66 a3 80 a3 17 00    	mov    %ax,0x17a380
  1028d2:	66 c7 05 82 a3 17 00 	movw   $0x8,0x17a382
  1028d9:	08 00 
  1028db:	0f b6 05 84 a3 17 00 	movzbl 0x17a384,%eax
  1028e2:	83 e0 e0             	and    $0xffffffe0,%eax
  1028e5:	a2 84 a3 17 00       	mov    %al,0x17a384
  1028ea:	0f b6 05 84 a3 17 00 	movzbl 0x17a384,%eax
  1028f1:	83 e0 1f             	and    $0x1f,%eax
  1028f4:	a2 84 a3 17 00       	mov    %al,0x17a384
  1028f9:	0f b6 05 85 a3 17 00 	movzbl 0x17a385,%eax
  102900:	83 e0 f0             	and    $0xfffffff0,%eax
  102903:	83 c8 0e             	or     $0xe,%eax
  102906:	a2 85 a3 17 00       	mov    %al,0x17a385
  10290b:	0f b6 05 85 a3 17 00 	movzbl 0x17a385,%eax
  102912:	83 e0 ef             	and    $0xffffffef,%eax
  102915:	a2 85 a3 17 00       	mov    %al,0x17a385
  10291a:	0f b6 05 85 a3 17 00 	movzbl 0x17a385,%eax
  102921:	83 e0 9f             	and    $0xffffff9f,%eax
  102924:	a2 85 a3 17 00       	mov    %al,0x17a385
  102929:	0f b6 05 85 a3 17 00 	movzbl 0x17a385,%eax
  102930:	83 c8 80             	or     $0xffffff80,%eax
  102933:	a2 85 a3 17 00       	mov    %al,0x17a385
  102938:	b8 ee 35 10 00       	mov    $0x1035ee,%eax
  10293d:	c1 e8 10             	shr    $0x10,%eax
  102940:	66 a3 86 a3 17 00    	mov    %ax,0x17a386
	SETGATE(idt[T_IRQ0 + 13], 0, CPU_GDT_KCODE, &Xirq13, 0);
  102946:	b8 f8 35 10 00       	mov    $0x1035f8,%eax
  10294b:	66 a3 88 a3 17 00    	mov    %ax,0x17a388
  102951:	66 c7 05 8a a3 17 00 	movw   $0x8,0x17a38a
  102958:	08 00 
  10295a:	0f b6 05 8c a3 17 00 	movzbl 0x17a38c,%eax
  102961:	83 e0 e0             	and    $0xffffffe0,%eax
  102964:	a2 8c a3 17 00       	mov    %al,0x17a38c
  102969:	0f b6 05 8c a3 17 00 	movzbl 0x17a38c,%eax
  102970:	83 e0 1f             	and    $0x1f,%eax
  102973:	a2 8c a3 17 00       	mov    %al,0x17a38c
  102978:	0f b6 05 8d a3 17 00 	movzbl 0x17a38d,%eax
  10297f:	83 e0 f0             	and    $0xfffffff0,%eax
  102982:	83 c8 0e             	or     $0xe,%eax
  102985:	a2 8d a3 17 00       	mov    %al,0x17a38d
  10298a:	0f b6 05 8d a3 17 00 	movzbl 0x17a38d,%eax
  102991:	83 e0 ef             	and    $0xffffffef,%eax
  102994:	a2 8d a3 17 00       	mov    %al,0x17a38d
  102999:	0f b6 05 8d a3 17 00 	movzbl 0x17a38d,%eax
  1029a0:	83 e0 9f             	and    $0xffffff9f,%eax
  1029a3:	a2 8d a3 17 00       	mov    %al,0x17a38d
  1029a8:	0f b6 05 8d a3 17 00 	movzbl 0x17a38d,%eax
  1029af:	83 c8 80             	or     $0xffffff80,%eax
  1029b2:	a2 8d a3 17 00       	mov    %al,0x17a38d
  1029b7:	b8 f8 35 10 00       	mov    $0x1035f8,%eax
  1029bc:	c1 e8 10             	shr    $0x10,%eax
  1029bf:	66 a3 8e a3 17 00    	mov    %ax,0x17a38e
	SETGATE(idt[T_IRQ0 + 14], 0, CPU_GDT_KCODE, &Xirq14, 0);
  1029c5:	b8 02 36 10 00       	mov    $0x103602,%eax
  1029ca:	66 a3 90 a3 17 00    	mov    %ax,0x17a390
  1029d0:	66 c7 05 92 a3 17 00 	movw   $0x8,0x17a392
  1029d7:	08 00 
  1029d9:	0f b6 05 94 a3 17 00 	movzbl 0x17a394,%eax
  1029e0:	83 e0 e0             	and    $0xffffffe0,%eax
  1029e3:	a2 94 a3 17 00       	mov    %al,0x17a394
  1029e8:	0f b6 05 94 a3 17 00 	movzbl 0x17a394,%eax
  1029ef:	83 e0 1f             	and    $0x1f,%eax
  1029f2:	a2 94 a3 17 00       	mov    %al,0x17a394
  1029f7:	0f b6 05 95 a3 17 00 	movzbl 0x17a395,%eax
  1029fe:	83 e0 f0             	and    $0xfffffff0,%eax
  102a01:	83 c8 0e             	or     $0xe,%eax
  102a04:	a2 95 a3 17 00       	mov    %al,0x17a395
  102a09:	0f b6 05 95 a3 17 00 	movzbl 0x17a395,%eax
  102a10:	83 e0 ef             	and    $0xffffffef,%eax
  102a13:	a2 95 a3 17 00       	mov    %al,0x17a395
  102a18:	0f b6 05 95 a3 17 00 	movzbl 0x17a395,%eax
  102a1f:	83 e0 9f             	and    $0xffffff9f,%eax
  102a22:	a2 95 a3 17 00       	mov    %al,0x17a395
  102a27:	0f b6 05 95 a3 17 00 	movzbl 0x17a395,%eax
  102a2e:	83 c8 80             	or     $0xffffff80,%eax
  102a31:	a2 95 a3 17 00       	mov    %al,0x17a395
  102a36:	b8 02 36 10 00       	mov    $0x103602,%eax
  102a3b:	c1 e8 10             	shr    $0x10,%eax
  102a3e:	66 a3 96 a3 17 00    	mov    %ax,0x17a396
	SETGATE(idt[T_IRQ0 + 15], 0, CPU_GDT_KCODE, &Xirq15, 0);
  102a44:	b8 0c 36 10 00       	mov    $0x10360c,%eax
  102a49:	66 a3 98 a3 17 00    	mov    %ax,0x17a398
  102a4f:	66 c7 05 9a a3 17 00 	movw   $0x8,0x17a39a
  102a56:	08 00 
  102a58:	0f b6 05 9c a3 17 00 	movzbl 0x17a39c,%eax
  102a5f:	83 e0 e0             	and    $0xffffffe0,%eax
  102a62:	a2 9c a3 17 00       	mov    %al,0x17a39c
  102a67:	0f b6 05 9c a3 17 00 	movzbl 0x17a39c,%eax
  102a6e:	83 e0 1f             	and    $0x1f,%eax
  102a71:	a2 9c a3 17 00       	mov    %al,0x17a39c
  102a76:	0f b6 05 9d a3 17 00 	movzbl 0x17a39d,%eax
  102a7d:	83 e0 f0             	and    $0xfffffff0,%eax
  102a80:	83 c8 0e             	or     $0xe,%eax
  102a83:	a2 9d a3 17 00       	mov    %al,0x17a39d
  102a88:	0f b6 05 9d a3 17 00 	movzbl 0x17a39d,%eax
  102a8f:	83 e0 ef             	and    $0xffffffef,%eax
  102a92:	a2 9d a3 17 00       	mov    %al,0x17a39d
  102a97:	0f b6 05 9d a3 17 00 	movzbl 0x17a39d,%eax
  102a9e:	83 e0 9f             	and    $0xffffff9f,%eax
  102aa1:	a2 9d a3 17 00       	mov    %al,0x17a39d
  102aa6:	0f b6 05 9d a3 17 00 	movzbl 0x17a39d,%eax
  102aad:	83 c8 80             	or     $0xffffff80,%eax
  102ab0:	a2 9d a3 17 00       	mov    %al,0x17a39d
  102ab5:	b8 0c 36 10 00       	mov    $0x10360c,%eax
  102aba:	c1 e8 10             	shr    $0x10,%eax
  102abd:	66 a3 9e a3 17 00    	mov    %ax,0x17a39e

	// Use DPL=3 here because system calls are explicitly invoked
	// by the user process (with "int $T_SYSCALL").
	SETGATE(idt[T_SYSCALL], 0, CPU_GDT_KCODE, &Xsyscall, 3);
  102ac3:	b8 16 36 10 00       	mov    $0x103616,%eax
  102ac8:	66 a3 a0 a3 17 00    	mov    %ax,0x17a3a0
  102ace:	66 c7 05 a2 a3 17 00 	movw   $0x8,0x17a3a2
  102ad5:	08 00 
  102ad7:	0f b6 05 a4 a3 17 00 	movzbl 0x17a3a4,%eax
  102ade:	83 e0 e0             	and    $0xffffffe0,%eax
  102ae1:	a2 a4 a3 17 00       	mov    %al,0x17a3a4
  102ae6:	0f b6 05 a4 a3 17 00 	movzbl 0x17a3a4,%eax
  102aed:	83 e0 1f             	and    $0x1f,%eax
  102af0:	a2 a4 a3 17 00       	mov    %al,0x17a3a4
  102af5:	0f b6 05 a5 a3 17 00 	movzbl 0x17a3a5,%eax
  102afc:	83 e0 f0             	and    $0xfffffff0,%eax
  102aff:	83 c8 0e             	or     $0xe,%eax
  102b02:	a2 a5 a3 17 00       	mov    %al,0x17a3a5
  102b07:	0f b6 05 a5 a3 17 00 	movzbl 0x17a3a5,%eax
  102b0e:	83 e0 ef             	and    $0xffffffef,%eax
  102b11:	a2 a5 a3 17 00       	mov    %al,0x17a3a5
  102b16:	0f b6 05 a5 a3 17 00 	movzbl 0x17a3a5,%eax
  102b1d:	83 c8 60             	or     $0x60,%eax
  102b20:	a2 a5 a3 17 00       	mov    %al,0x17a3a5
  102b25:	0f b6 05 a5 a3 17 00 	movzbl 0x17a3a5,%eax
  102b2c:	83 c8 80             	or     $0xffffff80,%eax
  102b2f:	a2 a5 a3 17 00       	mov    %al,0x17a3a5
  102b34:	b8 16 36 10 00       	mov    $0x103616,%eax
  102b39:	c1 e8 10             	shr    $0x10,%eax
  102b3c:	66 a3 a6 a3 17 00    	mov    %ax,0x17a3a6

	// Vectors we use for local APIC interrupts
	SETGATE(idt[T_LTIMER], 0, CPU_GDT_KCODE, &Xltimer, 0);
  102b42:	b8 20 36 10 00       	mov    $0x103620,%eax
  102b47:	66 a3 a8 a3 17 00    	mov    %ax,0x17a3a8
  102b4d:	66 c7 05 aa a3 17 00 	movw   $0x8,0x17a3aa
  102b54:	08 00 
  102b56:	0f b6 05 ac a3 17 00 	movzbl 0x17a3ac,%eax
  102b5d:	83 e0 e0             	and    $0xffffffe0,%eax
  102b60:	a2 ac a3 17 00       	mov    %al,0x17a3ac
  102b65:	0f b6 05 ac a3 17 00 	movzbl 0x17a3ac,%eax
  102b6c:	83 e0 1f             	and    $0x1f,%eax
  102b6f:	a2 ac a3 17 00       	mov    %al,0x17a3ac
  102b74:	0f b6 05 ad a3 17 00 	movzbl 0x17a3ad,%eax
  102b7b:	83 e0 f0             	and    $0xfffffff0,%eax
  102b7e:	83 c8 0e             	or     $0xe,%eax
  102b81:	a2 ad a3 17 00       	mov    %al,0x17a3ad
  102b86:	0f b6 05 ad a3 17 00 	movzbl 0x17a3ad,%eax
  102b8d:	83 e0 ef             	and    $0xffffffef,%eax
  102b90:	a2 ad a3 17 00       	mov    %al,0x17a3ad
  102b95:	0f b6 05 ad a3 17 00 	movzbl 0x17a3ad,%eax
  102b9c:	83 e0 9f             	and    $0xffffff9f,%eax
  102b9f:	a2 ad a3 17 00       	mov    %al,0x17a3ad
  102ba4:	0f b6 05 ad a3 17 00 	movzbl 0x17a3ad,%eax
  102bab:	83 c8 80             	or     $0xffffff80,%eax
  102bae:	a2 ad a3 17 00       	mov    %al,0x17a3ad
  102bb3:	b8 20 36 10 00       	mov    $0x103620,%eax
  102bb8:	c1 e8 10             	shr    $0x10,%eax
  102bbb:	66 a3 ae a3 17 00    	mov    %ax,0x17a3ae
	SETGATE(idt[T_LERROR], 0, CPU_GDT_KCODE, &Xlerror, 0);
  102bc1:	b8 2a 36 10 00       	mov    $0x10362a,%eax
  102bc6:	66 a3 b0 a3 17 00    	mov    %ax,0x17a3b0
  102bcc:	66 c7 05 b2 a3 17 00 	movw   $0x8,0x17a3b2
  102bd3:	08 00 
  102bd5:	0f b6 05 b4 a3 17 00 	movzbl 0x17a3b4,%eax
  102bdc:	83 e0 e0             	and    $0xffffffe0,%eax
  102bdf:	a2 b4 a3 17 00       	mov    %al,0x17a3b4
  102be4:	0f b6 05 b4 a3 17 00 	movzbl 0x17a3b4,%eax
  102beb:	83 e0 1f             	and    $0x1f,%eax
  102bee:	a2 b4 a3 17 00       	mov    %al,0x17a3b4
  102bf3:	0f b6 05 b5 a3 17 00 	movzbl 0x17a3b5,%eax
  102bfa:	83 e0 f0             	and    $0xfffffff0,%eax
  102bfd:	83 c8 0e             	or     $0xe,%eax
  102c00:	a2 b5 a3 17 00       	mov    %al,0x17a3b5
  102c05:	0f b6 05 b5 a3 17 00 	movzbl 0x17a3b5,%eax
  102c0c:	83 e0 ef             	and    $0xffffffef,%eax
  102c0f:	a2 b5 a3 17 00       	mov    %al,0x17a3b5
  102c14:	0f b6 05 b5 a3 17 00 	movzbl 0x17a3b5,%eax
  102c1b:	83 e0 9f             	and    $0xffffff9f,%eax
  102c1e:	a2 b5 a3 17 00       	mov    %al,0x17a3b5
  102c23:	0f b6 05 b5 a3 17 00 	movzbl 0x17a3b5,%eax
  102c2a:	83 c8 80             	or     $0xffffff80,%eax
  102c2d:	a2 b5 a3 17 00       	mov    %al,0x17a3b5
  102c32:	b8 2a 36 10 00       	mov    $0x10362a,%eax
  102c37:	c1 e8 10             	shr    $0x10,%eax
  102c3a:	66 a3 b6 a3 17 00    	mov    %ax,0x17a3b6

}
  102c40:	c9                   	leave  
  102c41:	c3                   	ret    

00102c42 <trap_init>:

void
trap_init(void)
{
  102c42:	55                   	push   %ebp
  102c43:	89 e5                	mov    %esp,%ebp
  102c45:	83 ec 08             	sub    $0x8,%esp
	// The first time we get called on the bootstrap processor,
	// initialize the IDT.  Other CPUs will share the same IDT.
	if (cpu_onboot())
  102c48:	e8 20 00 00 00       	call   102c6d <cpu_onboot>
  102c4d:	85 c0                	test   %eax,%eax
  102c4f:	74 05                	je     102c56 <trap_init+0x14>
		trap_init_idt();
  102c51:	e8 ba ec ff ff       	call   101910 <trap_init_idt>

	// Load the IDT into this processor's IDT register.
	asm volatile("lidt %0" : : "m" (idt_pd));
  102c56:	0f 01 1d 04 f0 10 00 	lidtl  0x10f004

	// Check for the correct IDT and trap handler operation.
	if (cpu_onboot())
  102c5d:	e8 0b 00 00 00       	call   102c6d <cpu_onboot>
  102c62:	85 c0                	test   %eax,%eax
  102c64:	74 05                	je     102c6b <trap_init+0x29>
		trap_check_kernel();
  102c66:	e8 31 05 00 00       	call   10319c <trap_check_kernel>
}
  102c6b:	c9                   	leave  
  102c6c:	c3                   	ret    

00102c6d <cpu_onboot>:
}

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  102c6d:	55                   	push   %ebp
  102c6e:	89 e5                	mov    %esp,%ebp
  102c70:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  102c73:	e8 0d 00 00 00       	call   102c85 <cpu_cur>
  102c78:	3d 00 e0 10 00       	cmp    $0x10e000,%eax
  102c7d:	0f 94 c0             	sete   %al
  102c80:	0f b6 c0             	movzbl %al,%eax
}
  102c83:	c9                   	leave  
  102c84:	c3                   	ret    

00102c85 <cpu_cur>:
  102c85:	55                   	push   %ebp
  102c86:	89 e5                	mov    %esp,%ebp
  102c88:	83 ec 28             	sub    $0x28,%esp
static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  102c8b:	89 65 fc             	mov    %esp,0xfffffffc(%ebp)
        return esp;
  102c8e:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  102c91:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  102c94:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  102c97:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  102c9c:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	assert(c->magic == CPU_MAGIC);
  102c9f:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  102ca2:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  102ca8:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  102cad:	74 24                	je     102cd3 <cpu_cur+0x4e>
  102caf:	c7 44 24 0c 60 c2 10 	movl   $0x10c260,0xc(%esp)
  102cb6:	00 
  102cb7:	c7 44 24 08 76 c2 10 	movl   $0x10c276,0x8(%esp)
  102cbe:	00 
  102cbf:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  102cc6:	00 
  102cc7:	c7 04 24 8b c2 10 00 	movl   $0x10c28b,(%esp)
  102cce:	e8 95 dc ff ff       	call   100968 <debug_panic>
	return c;
  102cd3:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
}
  102cd6:	c9                   	leave  
  102cd7:	c3                   	ret    

00102cd8 <trap_name>:

const char *trap_name(int trapno)
{
  102cd8:	55                   	push   %ebp
  102cd9:	89 e5                	mov    %esp,%ebp
  102cdb:	83 ec 04             	sub    $0x4,%esp
	static const char * const excnames[] = {
		"Divide error",
		"Debug",
		"Non-Maskable Interrupt",
		"Breakpoint",
		"Overflow",
		"BOUND Range Exceeded",
		"Invalid Opcode",
		"Device Not Available",
		"Double Fault",
		"Coprocessor Segment Overrun",
		"Invalid TSS",
		"Segment Not Present",
		"Stack Fault",
		"General Protection",
		"Page Fault",
		"(unknown trap)",
		"x87 FPU Floating-Point Error",
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
  102cde:	8b 45 08             	mov    0x8(%ebp),%eax
  102ce1:	83 f8 13             	cmp    $0x13,%eax
  102ce4:	77 0f                	ja     102cf5 <trap_name+0x1d>
		return excnames[trapno];
  102ce6:	8b 45 08             	mov    0x8(%ebp),%eax
  102ce9:	8b 04 85 00 c4 10 00 	mov    0x10c400(,%eax,4),%eax
  102cf0:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  102cf3:	eb 2b                	jmp    102d20 <trap_name+0x48>
	if (trapno == T_SYSCALL)
  102cf5:	83 7d 08 30          	cmpl   $0x30,0x8(%ebp)
  102cf9:	75 09                	jne    102d04 <trap_name+0x2c>
		return "System call";
  102cfb:	c7 45 fc 50 c4 10 00 	movl   $0x10c450,0xfffffffc(%ebp)
  102d02:	eb 1c                	jmp    102d20 <trap_name+0x48>
	if (trapno >= T_IRQ0 && trapno < T_IRQ0 + 16)
  102d04:	83 7d 08 1f          	cmpl   $0x1f,0x8(%ebp)
  102d08:	7e 0f                	jle    102d19 <trap_name+0x41>
  102d0a:	83 7d 08 2f          	cmpl   $0x2f,0x8(%ebp)
  102d0e:	7f 09                	jg     102d19 <trap_name+0x41>
		return "Hardware Interrupt";
  102d10:	c7 45 fc 5c c4 10 00 	movl   $0x10c45c,0xfffffffc(%ebp)
  102d17:	eb 07                	jmp    102d20 <trap_name+0x48>
	return "(unknown trap)";
  102d19:	c7 45 fc 82 c3 10 00 	movl   $0x10c382,0xfffffffc(%ebp)
  102d20:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
}
  102d23:	c9                   	leave  
  102d24:	c3                   	ret    

00102d25 <trap_print_regs>:

void
trap_print_regs(pushregs *regs)
{
  102d25:	55                   	push   %ebp
  102d26:	89 e5                	mov    %esp,%ebp
  102d28:	83 ec 08             	sub    $0x8,%esp
	cprintf("  edi  0x%08x\n", regs->edi);
  102d2b:	8b 45 08             	mov    0x8(%ebp),%eax
  102d2e:	8b 00                	mov    (%eax),%eax
  102d30:	89 44 24 04          	mov    %eax,0x4(%esp)
  102d34:	c7 04 24 6f c4 10 00 	movl   $0x10c46f,(%esp)
  102d3b:	e8 31 87 00 00       	call   10b471 <cprintf>
	cprintf("  esi  0x%08x\n", regs->esi);
  102d40:	8b 45 08             	mov    0x8(%ebp),%eax
  102d43:	8b 40 04             	mov    0x4(%eax),%eax
  102d46:	89 44 24 04          	mov    %eax,0x4(%esp)
  102d4a:	c7 04 24 7e c4 10 00 	movl   $0x10c47e,(%esp)
  102d51:	e8 1b 87 00 00       	call   10b471 <cprintf>
	cprintf("  ebp  0x%08x\n", regs->ebp);
  102d56:	8b 45 08             	mov    0x8(%ebp),%eax
  102d59:	8b 40 08             	mov    0x8(%eax),%eax
  102d5c:	89 44 24 04          	mov    %eax,0x4(%esp)
  102d60:	c7 04 24 8d c4 10 00 	movl   $0x10c48d,(%esp)
  102d67:	e8 05 87 00 00       	call   10b471 <cprintf>
//	cprintf("  oesp 0x%08x\n", regs->oesp);	don't print - useless
	cprintf("  ebx  0x%08x\n", regs->ebx);
  102d6c:	8b 45 08             	mov    0x8(%ebp),%eax
  102d6f:	8b 40 10             	mov    0x10(%eax),%eax
  102d72:	89 44 24 04          	mov    %eax,0x4(%esp)
  102d76:	c7 04 24 9c c4 10 00 	movl   $0x10c49c,(%esp)
  102d7d:	e8 ef 86 00 00       	call   10b471 <cprintf>
	cprintf("  edx  0x%08x\n", regs->edx);
  102d82:	8b 45 08             	mov    0x8(%ebp),%eax
  102d85:	8b 40 14             	mov    0x14(%eax),%eax
  102d88:	89 44 24 04          	mov    %eax,0x4(%esp)
  102d8c:	c7 04 24 ab c4 10 00 	movl   $0x10c4ab,(%esp)
  102d93:	e8 d9 86 00 00       	call   10b471 <cprintf>
	cprintf("  ecx  0x%08x\n", regs->ecx);
  102d98:	8b 45 08             	mov    0x8(%ebp),%eax
  102d9b:	8b 40 18             	mov    0x18(%eax),%eax
  102d9e:	89 44 24 04          	mov    %eax,0x4(%esp)
  102da2:	c7 04 24 ba c4 10 00 	movl   $0x10c4ba,(%esp)
  102da9:	e8 c3 86 00 00       	call   10b471 <cprintf>
	cprintf("  eax  0x%08x\n", regs->eax);
  102dae:	8b 45 08             	mov    0x8(%ebp),%eax
  102db1:	8b 40 1c             	mov    0x1c(%eax),%eax
  102db4:	89 44 24 04          	mov    %eax,0x4(%esp)
  102db8:	c7 04 24 c9 c4 10 00 	movl   $0x10c4c9,(%esp)
  102dbf:	e8 ad 86 00 00       	call   10b471 <cprintf>
}
  102dc4:	c9                   	leave  
  102dc5:	c3                   	ret    

00102dc6 <trap_print>:

void
trap_print(trapframe *tf)
{
  102dc6:	55                   	push   %ebp
  102dc7:	89 e5                	mov    %esp,%ebp
  102dc9:	83 ec 18             	sub    $0x18,%esp
	cprintf("TRAP frame at %p\n", tf);
  102dcc:	8b 45 08             	mov    0x8(%ebp),%eax
  102dcf:	89 44 24 04          	mov    %eax,0x4(%esp)
  102dd3:	c7 04 24 d8 c4 10 00 	movl   $0x10c4d8,(%esp)
  102dda:	e8 92 86 00 00       	call   10b471 <cprintf>
	trap_print_regs(&tf->regs);
  102ddf:	8b 45 08             	mov    0x8(%ebp),%eax
  102de2:	89 04 24             	mov    %eax,(%esp)
  102de5:	e8 3b ff ff ff       	call   102d25 <trap_print_regs>
	cprintf("  es   0x----%04x\n", tf->es);
  102dea:	8b 45 08             	mov    0x8(%ebp),%eax
  102ded:	0f b7 40 28          	movzwl 0x28(%eax),%eax
  102df1:	0f b7 c0             	movzwl %ax,%eax
  102df4:	89 44 24 04          	mov    %eax,0x4(%esp)
  102df8:	c7 04 24 ea c4 10 00 	movl   $0x10c4ea,(%esp)
  102dff:	e8 6d 86 00 00       	call   10b471 <cprintf>
	cprintf("  ds   0x----%04x\n", tf->ds);
  102e04:	8b 45 08             	mov    0x8(%ebp),%eax
  102e07:	0f b7 40 2c          	movzwl 0x2c(%eax),%eax
  102e0b:	0f b7 c0             	movzwl %ax,%eax
  102e0e:	89 44 24 04          	mov    %eax,0x4(%esp)
  102e12:	c7 04 24 fd c4 10 00 	movl   $0x10c4fd,(%esp)
  102e19:	e8 53 86 00 00       	call   10b471 <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->trapno, trap_name(tf->trapno));
  102e1e:	8b 45 08             	mov    0x8(%ebp),%eax
  102e21:	8b 40 30             	mov    0x30(%eax),%eax
  102e24:	89 04 24             	mov    %eax,(%esp)
  102e27:	e8 ac fe ff ff       	call   102cd8 <trap_name>
  102e2c:	89 c2                	mov    %eax,%edx
  102e2e:	8b 45 08             	mov    0x8(%ebp),%eax
  102e31:	8b 40 30             	mov    0x30(%eax),%eax
  102e34:	89 54 24 08          	mov    %edx,0x8(%esp)
  102e38:	89 44 24 04          	mov    %eax,0x4(%esp)
  102e3c:	c7 04 24 10 c5 10 00 	movl   $0x10c510,(%esp)
  102e43:	e8 29 86 00 00       	call   10b471 <cprintf>
	cprintf("  err  0x%08x\n", tf->err);
  102e48:	8b 45 08             	mov    0x8(%ebp),%eax
  102e4b:	8b 40 34             	mov    0x34(%eax),%eax
  102e4e:	89 44 24 04          	mov    %eax,0x4(%esp)
  102e52:	c7 04 24 22 c5 10 00 	movl   $0x10c522,(%esp)
  102e59:	e8 13 86 00 00       	call   10b471 <cprintf>
	cprintf("  eip  0x%08x\n", tf->eip);
  102e5e:	8b 45 08             	mov    0x8(%ebp),%eax
  102e61:	8b 40 38             	mov    0x38(%eax),%eax
  102e64:	89 44 24 04          	mov    %eax,0x4(%esp)
  102e68:	c7 04 24 31 c5 10 00 	movl   $0x10c531,(%esp)
  102e6f:	e8 fd 85 00 00       	call   10b471 <cprintf>
	cprintf("  cs   0x----%04x\n", tf->cs);
  102e74:	8b 45 08             	mov    0x8(%ebp),%eax
  102e77:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
  102e7b:	0f b7 c0             	movzwl %ax,%eax
  102e7e:	89 44 24 04          	mov    %eax,0x4(%esp)
  102e82:	c7 04 24 40 c5 10 00 	movl   $0x10c540,(%esp)
  102e89:	e8 e3 85 00 00       	call   10b471 <cprintf>
	cprintf("  flag 0x%08x\n", tf->eflags);
  102e8e:	8b 45 08             	mov    0x8(%ebp),%eax
  102e91:	8b 40 40             	mov    0x40(%eax),%eax
  102e94:	89 44 24 04          	mov    %eax,0x4(%esp)
  102e98:	c7 04 24 53 c5 10 00 	movl   $0x10c553,(%esp)
  102e9f:	e8 cd 85 00 00       	call   10b471 <cprintf>
	cprintf("  esp  0x%08x\n", tf->esp);
  102ea4:	8b 45 08             	mov    0x8(%ebp),%eax
  102ea7:	8b 40 44             	mov    0x44(%eax),%eax
  102eaa:	89 44 24 04          	mov    %eax,0x4(%esp)
  102eae:	c7 04 24 62 c5 10 00 	movl   $0x10c562,(%esp)
  102eb5:	e8 b7 85 00 00       	call   10b471 <cprintf>
	cprintf("  ss   0x----%04x\n", tf->ss);
  102eba:	8b 45 08             	mov    0x8(%ebp),%eax
  102ebd:	0f b7 40 48          	movzwl 0x48(%eax),%eax
  102ec1:	0f b7 c0             	movzwl %ax,%eax
  102ec4:	89 44 24 04          	mov    %eax,0x4(%esp)
  102ec8:	c7 04 24 71 c5 10 00 	movl   $0x10c571,(%esp)
  102ecf:	e8 9d 85 00 00       	call   10b471 <cprintf>
}
  102ed4:	c9                   	leave  
  102ed5:	c3                   	ret    

00102ed6 <trap>:

void gcc_noreturn
trap(trapframe *tf)
{
  102ed6:	55                   	push   %ebp
  102ed7:	89 e5                	mov    %esp,%ebp
  102ed9:	53                   	push   %ebx
  102eda:	83 ec 24             	sub    $0x24,%esp
	// The user-level environment may have set the DF flag,
	// and some versions of GCC rely on DF being clear.
	asm volatile("cld" ::: "cc");
  102edd:	fc                   	cld    

	// If this is a page fault, first handle lazy copying automatically.
	// If that works, this call just calls trap_return() itself -
	// otherwise, it returns normally to blame the fault on the user.
	if (tf->trapno == T_PGFLT)
  102ede:	8b 45 08             	mov    0x8(%ebp),%eax
  102ee1:	8b 40 30             	mov    0x30(%eax),%eax
  102ee4:	83 f8 0e             	cmp    $0xe,%eax
  102ee7:	75 0b                	jne    102ef4 <trap+0x1e>
		pmap_pagefault(tf);
  102ee9:	8b 45 08             	mov    0x8(%ebp),%eax
  102eec:	89 04 24             	mov    %eax,(%esp)
  102eef:	e8 7d 41 00 00       	call   107071 <pmap_pagefault>

	// If this trap was anticipated, just use the designated handler.
	cpu *c = cpu_cur();
  102ef4:	e8 8c fd ff ff       	call   102c85 <cpu_cur>
  102ef9:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
	if (c->recover)
  102efc:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  102eff:	8b 80 a0 00 00 00    	mov    0xa0(%eax),%eax
  102f05:	85 c0                	test   %eax,%eax
  102f07:	74 1e                	je     102f27 <trap+0x51>
		c->recover(tf, c->recoverdata);
  102f09:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  102f0c:	8b 90 a0 00 00 00    	mov    0xa0(%eax),%edx
  102f12:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  102f15:	8b 80 a4 00 00 00    	mov    0xa4(%eax),%eax
  102f1b:	89 44 24 04          	mov    %eax,0x4(%esp)
  102f1f:	8b 45 08             	mov    0x8(%ebp),%eax
  102f22:	89 04 24             	mov    %eax,(%esp)
  102f25:	ff d2                	call   *%edx

	proc *p = proc_cur();
  102f27:	e8 59 fd ff ff       	call   102c85 <cpu_cur>
  102f2c:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  102f32:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
	switch (tf->trapno) {
  102f35:	8b 45 08             	mov    0x8(%ebp),%eax
  102f38:	8b 40 30             	mov    0x30(%eax),%eax
  102f3b:	83 e8 03             	sub    $0x3,%eax
  102f3e:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  102f41:	83 7d e8 2f          	cmpl   $0x2f,0xffffffe8(%ebp)
  102f45:	0f 87 80 01 00 00    	ja     1030cb <trap+0x1f5>
  102f4b:	8b 55 e8             	mov    0xffffffe8(%ebp),%edx
  102f4e:	8b 04 95 f8 c5 10 00 	mov    0x10c5f8(,%edx,4),%eax
  102f55:	ff e0                	jmp    *%eax
	case T_SYSCALL:
		assert(tf->cs & 3);	// syscalls only come from user space
  102f57:	8b 45 08             	mov    0x8(%ebp),%eax
  102f5a:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
  102f5e:	0f b7 c0             	movzwl %ax,%eax
  102f61:	83 e0 03             	and    $0x3,%eax
  102f64:	85 c0                	test   %eax,%eax
  102f66:	75 24                	jne    102f8c <trap+0xb6>
  102f68:	c7 44 24 0c 84 c5 10 	movl   $0x10c584,0xc(%esp)
  102f6f:	00 
  102f70:	c7 44 24 08 76 c2 10 	movl   $0x10c276,0x8(%esp)
  102f77:	00 
  102f78:	c7 44 24 04 d1 00 00 	movl   $0xd1,0x4(%esp)
  102f7f:	00 
  102f80:	c7 04 24 8f c5 10 00 	movl   $0x10c58f,(%esp)
  102f87:	e8 dc d9 ff ff       	call   100968 <debug_panic>
		syscall(tf);
  102f8c:	8b 45 08             	mov    0x8(%ebp),%eax
  102f8f:	89 04 24             	mov    %eax,(%esp)
  102f92:	e8 1c 2b 00 00       	call   105ab3 <syscall>
		break;
  102f97:	e9 2f 01 00 00       	jmp    1030cb <trap+0x1f5>

	case T_BRKPT:	// other traps entered via explicit INT instructions
	case T_OFLOW:
		assert(tf->cs & 3);	// only allowed from user space
  102f9c:	8b 45 08             	mov    0x8(%ebp),%eax
  102f9f:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
  102fa3:	0f b7 c0             	movzwl %ax,%eax
  102fa6:	83 e0 03             	and    $0x3,%eax
  102fa9:	85 c0                	test   %eax,%eax
  102fab:	75 24                	jne    102fd1 <trap+0xfb>
  102fad:	c7 44 24 0c 84 c5 10 	movl   $0x10c584,0xc(%esp)
  102fb4:	00 
  102fb5:	c7 44 24 08 76 c2 10 	movl   $0x10c276,0x8(%esp)
  102fbc:	00 
  102fbd:	c7 44 24 04 d7 00 00 	movl   $0xd7,0x4(%esp)
  102fc4:	00 
  102fc5:	c7 04 24 8f c5 10 00 	movl   $0x10c58f,(%esp)
  102fcc:	e8 97 d9 ff ff       	call   100968 <debug_panic>
		proc_ret(tf, 1);	// reflect trap to parent process
  102fd1:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  102fd8:	00 
  102fd9:	8b 45 08             	mov    0x8(%ebp),%eax
  102fdc:	89 04 24             	mov    %eax,(%esp)
  102fdf:	e8 f1 17 00 00       	call   1047d5 <proc_ret>

	case T_DEVICE:	// attempted to access FPU while TS flag set
		//cprintf("trap: enabling FPU\n");
		p->sv.pff |= PFF_USEFPU;
  102fe4:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  102fe7:	8b 80 9c 04 00 00    	mov    0x49c(%eax),%eax
  102fed:	89 c2                	mov    %eax,%edx
  102fef:	83 ca 01             	or     $0x1,%edx
  102ff2:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  102ff5:	89 90 9c 04 00 00    	mov    %edx,0x49c(%eax)
static gcc_inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
  102ffb:	0f 20 c0             	mov    %cr0,%eax
  102ffe:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	return val;
  103001:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
		assert(sizeof(p->sv.fx) == 512);
		lcr0(rcr0() & ~CR0_TS);			// enable FPU
  103004:	83 e0 f7             	and    $0xfffffff7,%eax
  103007:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)

static gcc_inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
  10300a:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10300d:	0f 22 c0             	mov    %eax,%cr0
		asm volatile("fxrstor %0" : : "m" (p->sv.fx));
  103010:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  103013:	0f ae 88 a0 04 00 00 	fxrstor 0x4a0(%eax)
		trap_return(tf);
  10301a:	8b 45 08             	mov    0x8(%ebp),%eax
  10301d:	89 04 24             	mov    %eax,(%esp)
  103020:	e8 3b 06 00 00       	call   103660 <trap_return>

	case T_LTIMER: ;
		lapic_eoi();
  103025:	e8 06 79 00 00       	call   10a930 <lapic_eoi>
		if (tf->cs & 3)	// If in user mode, context switch
  10302a:	8b 45 08             	mov    0x8(%ebp),%eax
  10302d:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
  103031:	0f b7 c0             	movzwl %ax,%eax
  103034:	83 e0 03             	and    $0x3,%eax
  103037:	85 c0                	test   %eax,%eax
  103039:	74 0b                	je     103046 <trap+0x170>
			proc_yield(tf);
  10303b:	8b 45 08             	mov    0x8(%ebp),%eax
  10303e:	89 04 24             	mov    %eax,(%esp)
  103041:	e8 0d 17 00 00       	call   104753 <proc_yield>
		trap_return(tf);	// Otherwise, stay in idle loop
  103046:	8b 45 08             	mov    0x8(%ebp),%eax
  103049:	89 04 24             	mov    %eax,(%esp)
  10304c:	e8 0f 06 00 00       	call   103660 <trap_return>
	case T_LERROR:
		lapic_errintr();
  103051:	e8 ff 78 00 00       	call   10a955 <lapic_errintr>
		trap_return(tf);
  103056:	8b 45 08             	mov    0x8(%ebp),%eax
  103059:	89 04 24             	mov    %eax,(%esp)
  10305c:	e8 ff 05 00 00       	call   103660 <trap_return>
	case T_IRQ0 + IRQ_KBD:
		//cprintf("CPU%d: KBD\n", c->id);
		kbd_intr();
  103061:	e8 7a 72 00 00       	call   10a2e0 <kbd_intr>
		lapic_eoi();
  103066:	e8 c5 78 00 00       	call   10a930 <lapic_eoi>
		trap_return(tf);
  10306b:	8b 45 08             	mov    0x8(%ebp),%eax
  10306e:	89 04 24             	mov    %eax,(%esp)
  103071:	e8 ea 05 00 00       	call   103660 <trap_return>
	case T_IRQ0 + IRQ_SERIAL:
		//cprintf("CPU%d: SER\n", c->id);
		lapic_eoi();
  103076:	e8 b5 78 00 00       	call   10a930 <lapic_eoi>
		serial_intr();
  10307b:	e8 28 73 00 00       	call   10a3a8 <serial_intr>
		trap_return(tf);
  103080:	8b 45 08             	mov    0x8(%ebp),%eax
  103083:	89 04 24             	mov    %eax,(%esp)
  103086:	e8 d5 05 00 00       	call   103660 <trap_return>
	case T_IRQ0 + IRQ_SPURIOUS:
		cprintf("cpu%d: spurious interrupt at %x:%x\n",
  10308b:	8b 45 08             	mov    0x8(%ebp),%eax
  10308e:	8b 48 38             	mov    0x38(%eax),%ecx
  103091:	8b 45 08             	mov    0x8(%ebp),%eax
  103094:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
  103098:	0f b7 d0             	movzwl %ax,%edx
  10309b:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  10309e:	0f b6 80 ac 00 00 00 	movzbl 0xac(%eax),%eax
  1030a5:	0f b6 c0             	movzbl %al,%eax
  1030a8:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  1030ac:	89 54 24 08          	mov    %edx,0x8(%esp)
  1030b0:	89 44 24 04          	mov    %eax,0x4(%esp)
  1030b4:	c7 04 24 9c c5 10 00 	movl   $0x10c59c,(%esp)
  1030bb:	e8 b1 83 00 00       	call   10b471 <cprintf>
			c->id, tf->cs, tf->eip);
		trap_return(tf); // Note: no EOI (see Local APIC manual)
  1030c0:	8b 45 08             	mov    0x8(%ebp),%eax
  1030c3:	89 04 24             	mov    %eax,(%esp)
  1030c6:	e8 95 05 00 00       	call   103660 <trap_return>
		break;
	}
	if (tf->cs & 3) {		// Unhandled trap from user mode
  1030cb:	8b 45 08             	mov    0x8(%ebp),%eax
  1030ce:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
  1030d2:	0f b7 c0             	movzwl %ax,%eax
  1030d5:	83 e0 03             	and    $0x3,%eax
  1030d8:	85 c0                	test   %eax,%eax
  1030da:	74 4b                	je     103127 <trap+0x251>
		cprintf("trap in proc %x, reflecting to proc %x\n",
  1030dc:	e8 a4 fb ff ff       	call   102c85 <cpu_cur>
  1030e1:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  1030e7:	8b 58 38             	mov    0x38(%eax),%ebx
  1030ea:	e8 96 fb ff ff       	call   102c85 <cpu_cur>
  1030ef:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  1030f5:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  1030f9:	89 44 24 04          	mov    %eax,0x4(%esp)
  1030fd:	c7 04 24 c0 c5 10 00 	movl   $0x10c5c0,(%esp)
  103104:	e8 68 83 00 00       	call   10b471 <cprintf>
			proc_cur(), proc_cur()->parent);
		trap_print(tf);
  103109:	8b 45 08             	mov    0x8(%ebp),%eax
  10310c:	89 04 24             	mov    %eax,(%esp)
  10310f:	e8 b2 fc ff ff       	call   102dc6 <trap_print>
		proc_ret(tf, -1);	// Reflect trap to parent process
  103114:	c7 44 24 04 ff ff ff 	movl   $0xffffffff,0x4(%esp)
  10311b:	ff 
  10311c:	8b 45 08             	mov    0x8(%ebp),%eax
  10311f:	89 04 24             	mov    %eax,(%esp)
  103122:	e8 ae 16 00 00       	call   1047d5 <proc_ret>
	}

	// If we panic while holding the console lock,
	// release it so we don't get into a recursive panic that way.
	if (spinlock_holding(&cons_lock))
  103127:	c7 04 24 40 ed 17 00 	movl   $0x17ed40,(%esp)
  10312e:	e8 dc 0a 00 00       	call   103c0f <spinlock_holding>
  103133:	85 c0                	test   %eax,%eax
  103135:	74 0c                	je     103143 <trap+0x26d>
		spinlock_release(&cons_lock);
  103137:	c7 04 24 40 ed 17 00 	movl   $0x17ed40,(%esp)
  10313e:	e8 72 0a 00 00       	call   103bb5 <spinlock_release>
	trap_print(tf);
  103143:	8b 45 08             	mov    0x8(%ebp),%eax
  103146:	89 04 24             	mov    %eax,(%esp)
  103149:	e8 78 fc ff ff       	call   102dc6 <trap_print>
	panic("unhandled trap");
  10314e:	c7 44 24 08 e8 c5 10 	movl   $0x10c5e8,0x8(%esp)
  103155:	00 
  103156:	c7 44 24 04 06 01 00 	movl   $0x106,0x4(%esp)
  10315d:	00 
  10315e:	c7 04 24 8f c5 10 00 	movl   $0x10c58f,(%esp)
  103165:	e8 fe d7 ff ff       	call   100968 <debug_panic>

0010316a <trap_check_recover>:
}


// Helper function for trap_check_recover(), below:
// handles "anticipated" traps by simply resuming at a new EIP.
static void gcc_noreturn
trap_check_recover(trapframe *tf, void *recoverdata)
{
  10316a:	55                   	push   %ebp
  10316b:	89 e5                	mov    %esp,%ebp
  10316d:	83 ec 18             	sub    $0x18,%esp
	trap_check_args *args = recoverdata;
  103170:	8b 45 0c             	mov    0xc(%ebp),%eax
  103173:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	tf->eip = (uint32_t) args->reip;	// Use recovery EIP on return
  103176:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  103179:	8b 00                	mov    (%eax),%eax
  10317b:	89 c2                	mov    %eax,%edx
  10317d:	8b 45 08             	mov    0x8(%ebp),%eax
  103180:	89 50 38             	mov    %edx,0x38(%eax)
	args->trapno = tf->trapno;		// Return trap number
  103183:	8b 45 08             	mov    0x8(%ebp),%eax
  103186:	8b 40 30             	mov    0x30(%eax),%eax
  103189:	89 c2                	mov    %eax,%edx
  10318b:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  10318e:	89 50 04             	mov    %edx,0x4(%eax)
	trap_return(tf);
  103191:	8b 45 08             	mov    0x8(%ebp),%eax
  103194:	89 04 24             	mov    %eax,(%esp)
  103197:	e8 c4 04 00 00       	call   103660 <trap_return>

0010319c <trap_check_kernel>:
}

// Check for correct handling of traps from kernel mode.
// Called on the boot CPU after trap_init() and trap_setup().
void
trap_check_kernel(void)
{
  10319c:	55                   	push   %ebp
  10319d:	89 e5                	mov    %esp,%ebp
  10319f:	83 ec 28             	sub    $0x28,%esp
static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  1031a2:	8c 4d fe             	movw   %cs,0xfffffffe(%ebp)
        return cs;
  1031a5:	0f b7 45 fe          	movzwl 0xfffffffe(%ebp),%eax
	assert((read_cs() & 3) == 0);	// better be in kernel mode!
  1031a9:	0f b7 c0             	movzwl %ax,%eax
  1031ac:	83 e0 03             	and    $0x3,%eax
  1031af:	85 c0                	test   %eax,%eax
  1031b1:	74 24                	je     1031d7 <trap_check_kernel+0x3b>
  1031b3:	c7 44 24 0c b8 c6 10 	movl   $0x10c6b8,0xc(%esp)
  1031ba:	00 
  1031bb:	c7 44 24 08 76 c2 10 	movl   $0x10c276,0x8(%esp)
  1031c2:	00 
  1031c3:	c7 44 24 04 1a 01 00 	movl   $0x11a,0x4(%esp)
  1031ca:	00 
  1031cb:	c7 04 24 8f c5 10 00 	movl   $0x10c58f,(%esp)
  1031d2:	e8 91 d7 ff ff       	call   100968 <debug_panic>

	cpu *c = cpu_cur();
  1031d7:	e8 a9 fa ff ff       	call   102c85 <cpu_cur>
  1031dc:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
	c->recover = trap_check_recover;
  1031df:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1031e2:	c7 80 a0 00 00 00 6a 	movl   $0x10316a,0xa0(%eax)
  1031e9:	31 10 00 
	trap_check(&c->recoverdata);
  1031ec:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1031ef:	05 a4 00 00 00       	add    $0xa4,%eax
  1031f4:	89 04 24             	mov    %eax,(%esp)
  1031f7:	e8 96 00 00 00       	call   103292 <trap_check>
	c->recover = NULL;	// No more mr. nice-guy; traps are real again
  1031fc:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1031ff:	c7 80 a0 00 00 00 00 	movl   $0x0,0xa0(%eax)
  103206:	00 00 00 

	cprintf("trap_check_kernel() succeeded!\n");
  103209:	c7 04 24 d0 c6 10 00 	movl   $0x10c6d0,(%esp)
  103210:	e8 5c 82 00 00       	call   10b471 <cprintf>
}
  103215:	c9                   	leave  
  103216:	c3                   	ret    

00103217 <trap_check_user>:

// Check for correct handling of traps from user mode.
// Called from user() in kern/init.c, only in lab 1.
// We assume the "current cpu" is always the boot cpu;
// this true only because lab 1 doesn't start any other CPUs.
void
trap_check_user(void)
{
  103217:	55                   	push   %ebp
  103218:	89 e5                	mov    %esp,%ebp
  10321a:	83 ec 28             	sub    $0x28,%esp
static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  10321d:	8c 4d fe             	movw   %cs,0xfffffffe(%ebp)
        return cs;
  103220:	0f b7 45 fe          	movzwl 0xfffffffe(%ebp),%eax
	assert((read_cs() & 3) == 3);	// better be in user mode!
  103224:	0f b7 c0             	movzwl %ax,%eax
  103227:	83 e0 03             	and    $0x3,%eax
  10322a:	83 f8 03             	cmp    $0x3,%eax
  10322d:	74 24                	je     103253 <trap_check_user+0x3c>
  10322f:	c7 44 24 0c f0 c6 10 	movl   $0x10c6f0,0xc(%esp)
  103236:	00 
  103237:	c7 44 24 08 76 c2 10 	movl   $0x10c276,0x8(%esp)
  10323e:	00 
  10323f:	c7 44 24 04 2b 01 00 	movl   $0x12b,0x4(%esp)
  103246:	00 
  103247:	c7 04 24 8f c5 10 00 	movl   $0x10c58f,(%esp)
  10324e:	e8 15 d7 ff ff       	call   100968 <debug_panic>

	cpu *c = &cpu_boot;	// cpu_cur doesn't work from user mode!
  103253:	c7 45 f8 00 e0 10 00 	movl   $0x10e000,0xfffffff8(%ebp)
	c->recover = trap_check_recover;
  10325a:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10325d:	c7 80 a0 00 00 00 6a 	movl   $0x10316a,0xa0(%eax)
  103264:	31 10 00 
	trap_check(&c->recoverdata);
  103267:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10326a:	05 a4 00 00 00       	add    $0xa4,%eax
  10326f:	89 04 24             	mov    %eax,(%esp)
  103272:	e8 1b 00 00 00       	call   103292 <trap_check>
	c->recover = NULL;	// No more mr. nice-guy; traps are real again
  103277:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10327a:	c7 80 a0 00 00 00 00 	movl   $0x0,0xa0(%eax)
  103281:	00 00 00 

	cprintf("trap_check_user() succeeded!\n");
  103284:	c7 04 24 05 c7 10 00 	movl   $0x10c705,(%esp)
  10328b:	e8 e1 81 00 00       	call   10b471 <cprintf>
}
  103290:	c9                   	leave  
  103291:	c3                   	ret    

00103292 <trap_check>:

void after_div0();
void after_breakpoint();
void after_overflow();
void after_bound();
void after_illegal();
void after_gpfault();
void after_priv();

// Multi-purpose trap checking function.
void
trap_check(void **argsp)
{
  103292:	55                   	push   %ebp
  103293:	89 e5                	mov    %esp,%ebp
  103295:	57                   	push   %edi
  103296:	56                   	push   %esi
  103297:	53                   	push   %ebx
  103298:	83 ec 3c             	sub    $0x3c,%esp
	volatile int cookie = 0xfeedface;
  10329b:	c7 45 ec ce fa ed fe 	movl   $0xfeedface,0xffffffec(%ebp)
	volatile trap_check_args args;
	*argsp = (void*)&args;	// provide args needed for trap recovery
  1032a2:	8b 55 08             	mov    0x8(%ebp),%edx
  1032a5:	8d 45 e4             	lea    0xffffffe4(%ebp),%eax
  1032a8:	89 02                	mov    %eax,(%edx)

	// Try a divide by zero trap.
	// Be careful when using && to take the address of a label:
	// some versions of GCC (4.4.2 at least) will incorrectly try to
	// eliminate code it thinks is _only_ reachable via such a pointer.
	args.reip = after_div0;
  1032aa:	c7 45 e4 b8 32 10 00 	movl   $0x1032b8,0xffffffe4(%ebp)
	asm volatile("div %0,%0; after_div0:" : : "r" (0));
  1032b1:	b8 00 00 00 00       	mov    $0x0,%eax
  1032b6:	f7 f0                	div    %eax

001032b8 <after_div0>:
	assert(args.trapno == T_DIVIDE);
  1032b8:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  1032bb:	85 c0                	test   %eax,%eax
  1032bd:	74 24                	je     1032e3 <after_div0+0x2b>
  1032bf:	c7 44 24 0c 23 c7 10 	movl   $0x10c723,0xc(%esp)
  1032c6:	00 
  1032c7:	c7 44 24 08 76 c2 10 	movl   $0x10c276,0x8(%esp)
  1032ce:	00 
  1032cf:	c7 44 24 04 4b 01 00 	movl   $0x14b,0x4(%esp)
  1032d6:	00 
  1032d7:	c7 04 24 8f c5 10 00 	movl   $0x10c58f,(%esp)
  1032de:	e8 85 d6 ff ff       	call   100968 <debug_panic>

	// Make sure we got our correct stack back with us.
	// The asm ensures gcc uses ebp/esp to get the cookie.
	asm volatile("" : : : "eax","ebx","ecx","edx","esi","edi");
	assert(cookie == 0xfeedface);
  1032e3:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  1032e6:	3d ce fa ed fe       	cmp    $0xfeedface,%eax
  1032eb:	74 24                	je     103311 <after_div0+0x59>
  1032ed:	c7 44 24 0c 3b c7 10 	movl   $0x10c73b,0xc(%esp)
  1032f4:	00 
  1032f5:	c7 44 24 08 76 c2 10 	movl   $0x10c276,0x8(%esp)
  1032fc:	00 
  1032fd:	c7 44 24 04 50 01 00 	movl   $0x150,0x4(%esp)
  103304:	00 
  103305:	c7 04 24 8f c5 10 00 	movl   $0x10c58f,(%esp)
  10330c:	e8 57 d6 ff ff       	call   100968 <debug_panic>

	// Breakpoint trap
	args.reip = after_breakpoint;
  103311:	c7 45 e4 19 33 10 00 	movl   $0x103319,0xffffffe4(%ebp)
	asm volatile("int3; after_breakpoint:");
  103318:	cc                   	int3   

00103319 <after_breakpoint>:
	assert(args.trapno == T_BRKPT);
  103319:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  10331c:	83 f8 03             	cmp    $0x3,%eax
  10331f:	74 24                	je     103345 <after_breakpoint+0x2c>
  103321:	c7 44 24 0c 50 c7 10 	movl   $0x10c750,0xc(%esp)
  103328:	00 
  103329:	c7 44 24 08 76 c2 10 	movl   $0x10c276,0x8(%esp)
  103330:	00 
  103331:	c7 44 24 04 55 01 00 	movl   $0x155,0x4(%esp)
  103338:	00 
  103339:	c7 04 24 8f c5 10 00 	movl   $0x10c58f,(%esp)
  103340:	e8 23 d6 ff ff       	call   100968 <debug_panic>

	// Overflow trap
	args.reip = after_overflow;
  103345:	c7 45 e4 54 33 10 00 	movl   $0x103354,0xffffffe4(%ebp)
	asm volatile("addl %0,%0; into; after_overflow:" : : "r" (0x70000000));
  10334c:	b8 00 00 00 70       	mov    $0x70000000,%eax
  103351:	01 c0                	add    %eax,%eax
  103353:	ce                   	into   

00103354 <after_overflow>:
	assert(args.trapno == T_OFLOW);
  103354:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  103357:	83 f8 04             	cmp    $0x4,%eax
  10335a:	74 24                	je     103380 <after_overflow+0x2c>
  10335c:	c7 44 24 0c 67 c7 10 	movl   $0x10c767,0xc(%esp)
  103363:	00 
  103364:	c7 44 24 08 76 c2 10 	movl   $0x10c276,0x8(%esp)
  10336b:	00 
  10336c:	c7 44 24 04 5a 01 00 	movl   $0x15a,0x4(%esp)
  103373:	00 
  103374:	c7 04 24 8f c5 10 00 	movl   $0x10c58f,(%esp)
  10337b:	e8 e8 d5 ff ff       	call   100968 <debug_panic>

	// Bounds trap
	args.reip = after_bound;
  103380:	c7 45 e4 9d 33 10 00 	movl   $0x10339d,0xffffffe4(%ebp)
	int bounds[2] = { 1, 3 };
  103387:	c7 45 dc 01 00 00 00 	movl   $0x1,0xffffffdc(%ebp)
  10338e:	c7 45 e0 03 00 00 00 	movl   $0x3,0xffffffe0(%ebp)
	asm volatile("boundl %0,%1; after_bound:" : : "r" (0), "m" (bounds[0]));
  103395:	b8 00 00 00 00       	mov    $0x0,%eax
  10339a:	62 45 dc             	bound  %eax,0xffffffdc(%ebp)

0010339d <after_bound>:
	assert(args.trapno == T_BOUND);
  10339d:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  1033a0:	83 f8 05             	cmp    $0x5,%eax
  1033a3:	74 24                	je     1033c9 <after_bound+0x2c>
  1033a5:	c7 44 24 0c 7e c7 10 	movl   $0x10c77e,0xc(%esp)
  1033ac:	00 
  1033ad:	c7 44 24 08 76 c2 10 	movl   $0x10c276,0x8(%esp)
  1033b4:	00 
  1033b5:	c7 44 24 04 60 01 00 	movl   $0x160,0x4(%esp)
  1033bc:	00 
  1033bd:	c7 04 24 8f c5 10 00 	movl   $0x10c58f,(%esp)
  1033c4:	e8 9f d5 ff ff       	call   100968 <debug_panic>

	// Illegal instruction trap
	args.reip = after_illegal;
  1033c9:	c7 45 e4 d2 33 10 00 	movl   $0x1033d2,0xffffffe4(%ebp)
	asm volatile("ud2; after_illegal:");	// guaranteed to be undefined
  1033d0:	0f 0b                	ud2a   

001033d2 <after_illegal>:
	assert(args.trapno == T_ILLOP);
  1033d2:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  1033d5:	83 f8 06             	cmp    $0x6,%eax
  1033d8:	74 24                	je     1033fe <after_illegal+0x2c>
  1033da:	c7 44 24 0c 95 c7 10 	movl   $0x10c795,0xc(%esp)
  1033e1:	00 
  1033e2:	c7 44 24 08 76 c2 10 	movl   $0x10c276,0x8(%esp)
  1033e9:	00 
  1033ea:	c7 44 24 04 65 01 00 	movl   $0x165,0x4(%esp)
  1033f1:	00 
  1033f2:	c7 04 24 8f c5 10 00 	movl   $0x10c58f,(%esp)
  1033f9:	e8 6a d5 ff ff       	call   100968 <debug_panic>

	// General protection fault due to invalid segment load
	args.reip = after_gpfault;
  1033fe:	c7 45 e4 0c 34 10 00 	movl   $0x10340c,0xffffffe4(%ebp)
	asm volatile("movl %0,%%fs; after_gpfault:" : : "r" (-1));
  103405:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  10340a:	8e e0                	movl   %eax,%fs

0010340c <after_gpfault>:
	assert(args.trapno == T_GPFLT);
  10340c:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  10340f:	83 f8 0d             	cmp    $0xd,%eax
  103412:	74 24                	je     103438 <after_gpfault+0x2c>
  103414:	c7 44 24 0c ac c7 10 	movl   $0x10c7ac,0xc(%esp)
  10341b:	00 
  10341c:	c7 44 24 08 76 c2 10 	movl   $0x10c276,0x8(%esp)
  103423:	00 
  103424:	c7 44 24 04 6a 01 00 	movl   $0x16a,0x4(%esp)
  10342b:	00 
  10342c:	c7 04 24 8f c5 10 00 	movl   $0x10c58f,(%esp)
  103433:	e8 30 d5 ff ff       	call   100968 <debug_panic>
static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  103438:	8c 4d f2             	movw   %cs,0xfffffff2(%ebp)
        return cs;
  10343b:	0f b7 45 f2          	movzwl 0xfffffff2(%ebp),%eax

	// General protection fault due to privilege violation
	if (read_cs() & 3) {
  10343f:	0f b7 c0             	movzwl %ax,%eax
  103442:	83 e0 03             	and    $0x3,%eax
  103445:	85 c0                	test   %eax,%eax
  103447:	74 3a                	je     103483 <after_priv+0x2c>
		args.reip = after_priv;
  103449:	c7 45 e4 57 34 10 00 	movl   $0x103457,0xffffffe4(%ebp)
		asm volatile("lidt %0; after_priv:" : : "m" (idt_pd));
  103450:	0f 01 1d 04 f0 10 00 	lidtl  0x10f004

00103457 <after_priv>:
		assert(args.trapno == T_GPFLT);
  103457:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  10345a:	83 f8 0d             	cmp    $0xd,%eax
  10345d:	74 24                	je     103483 <after_priv+0x2c>
  10345f:	c7 44 24 0c ac c7 10 	movl   $0x10c7ac,0xc(%esp)
  103466:	00 
  103467:	c7 44 24 08 76 c2 10 	movl   $0x10c276,0x8(%esp)
  10346e:	00 
  10346f:	c7 44 24 04 70 01 00 	movl   $0x170,0x4(%esp)
  103476:	00 
  103477:	c7 04 24 8f c5 10 00 	movl   $0x10c58f,(%esp)
  10347e:	e8 e5 d4 ff ff       	call   100968 <debug_panic>
	}

	// Make sure our stack cookie is still with us
	assert(cookie == 0xfeedface);
  103483:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  103486:	3d ce fa ed fe       	cmp    $0xfeedface,%eax
  10348b:	74 24                	je     1034b1 <after_priv+0x5a>
  10348d:	c7 44 24 0c 3b c7 10 	movl   $0x10c73b,0xc(%esp)
  103494:	00 
  103495:	c7 44 24 08 76 c2 10 	movl   $0x10c276,0x8(%esp)
  10349c:	00 
  10349d:	c7 44 24 04 74 01 00 	movl   $0x174,0x4(%esp)
  1034a4:	00 
  1034a5:	c7 04 24 8f c5 10 00 	movl   $0x10c58f,(%esp)
  1034ac:	e8 b7 d4 ff ff       	call   100968 <debug_panic>

	*argsp = NULL;	// recovery mechanism not needed anymore
  1034b1:	8b 45 08             	mov    0x8(%ebp),%eax
  1034b4:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}
  1034ba:	83 c4 3c             	add    $0x3c,%esp
  1034bd:	5b                   	pop    %ebx
  1034be:	5e                   	pop    %esi
  1034bf:	5f                   	pop    %edi
  1034c0:	5d                   	pop    %ebp
  1034c1:	c3                   	ret    
  1034c2:	90                   	nop    
  1034c3:	90                   	nop    
  1034c4:	90                   	nop    
  1034c5:	90                   	nop    
  1034c6:	90                   	nop    
  1034c7:	90                   	nop    
  1034c8:	90                   	nop    
  1034c9:	90                   	nop    
  1034ca:	90                   	nop    
  1034cb:	90                   	nop    
  1034cc:	90                   	nop    
  1034cd:	90                   	nop    
  1034ce:	90                   	nop    
  1034cf:	90                   	nop    

001034d0 <Xdivide>:

.text

/* CPU traps */
TRAPHANDLER_NOEC(Xdivide, T_DIVIDE)
  1034d0:	6a 00                	push   $0x0
  1034d2:	6a 00                	push   $0x0
  1034d4:	e9 67 01 00 00       	jmp    103640 <_alltraps>
  1034d9:	90                   	nop    

001034da <Xdebug>:
TRAPHANDLER_NOEC(Xdebug,  T_DEBUG)
  1034da:	6a 00                	push   $0x0
  1034dc:	6a 01                	push   $0x1
  1034de:	e9 5d 01 00 00       	jmp    103640 <_alltraps>
  1034e3:	90                   	nop    

001034e4 <Xnmi>:
TRAPHANDLER_NOEC(Xnmi,    T_NMI)
  1034e4:	6a 00                	push   $0x0
  1034e6:	6a 02                	push   $0x2
  1034e8:	e9 53 01 00 00       	jmp    103640 <_alltraps>
  1034ed:	90                   	nop    

001034ee <Xbrkpt>:
TRAPHANDLER_NOEC(Xbrkpt,  T_BRKPT)
  1034ee:	6a 00                	push   $0x0
  1034f0:	6a 03                	push   $0x3
  1034f2:	e9 49 01 00 00       	jmp    103640 <_alltraps>
  1034f7:	90                   	nop    

001034f8 <Xoflow>:
TRAPHANDLER_NOEC(Xoflow,  T_OFLOW)
  1034f8:	6a 00                	push   $0x0
  1034fa:	6a 04                	push   $0x4
  1034fc:	e9 3f 01 00 00       	jmp    103640 <_alltraps>
  103501:	90                   	nop    

00103502 <Xbound>:
TRAPHANDLER_NOEC(Xbound,  T_BOUND)
  103502:	6a 00                	push   $0x0
  103504:	6a 05                	push   $0x5
  103506:	e9 35 01 00 00       	jmp    103640 <_alltraps>
  10350b:	90                   	nop    

0010350c <Xillop>:
TRAPHANDLER_NOEC(Xillop,  T_ILLOP)
  10350c:	6a 00                	push   $0x0
  10350e:	6a 06                	push   $0x6
  103510:	e9 2b 01 00 00       	jmp    103640 <_alltraps>
  103515:	90                   	nop    

00103516 <Xdevice>:
TRAPHANDLER_NOEC(Xdevice, T_DEVICE)
  103516:	6a 00                	push   $0x0
  103518:	6a 07                	push   $0x7
  10351a:	e9 21 01 00 00       	jmp    103640 <_alltraps>
  10351f:	90                   	nop    

00103520 <Xdblflt>:
TRAPHANDLER     (Xdblflt, T_DBLFLT)
  103520:	6a 08                	push   $0x8
  103522:	e9 19 01 00 00       	jmp    103640 <_alltraps>
  103527:	90                   	nop    

00103528 <Xtss>:
TRAPHANDLER     (Xtss,    T_TSS)
  103528:	6a 0a                	push   $0xa
  10352a:	e9 11 01 00 00       	jmp    103640 <_alltraps>
  10352f:	90                   	nop    

00103530 <Xsegnp>:
TRAPHANDLER     (Xsegnp,  T_SEGNP)
  103530:	6a 0b                	push   $0xb
  103532:	e9 09 01 00 00       	jmp    103640 <_alltraps>
  103537:	90                   	nop    

00103538 <Xstack>:
TRAPHANDLER     (Xstack,  T_STACK)
  103538:	6a 0c                	push   $0xc
  10353a:	e9 01 01 00 00       	jmp    103640 <_alltraps>
  10353f:	90                   	nop    

00103540 <Xgpflt>:
TRAPHANDLER     (Xgpflt,  T_GPFLT)
  103540:	6a 0d                	push   $0xd
  103542:	e9 f9 00 00 00       	jmp    103640 <_alltraps>
  103547:	90                   	nop    

00103548 <Xpgflt>:
TRAPHANDLER     (Xpgflt,  T_PGFLT)
  103548:	6a 0e                	push   $0xe
  10354a:	e9 f1 00 00 00       	jmp    103640 <_alltraps>
  10354f:	90                   	nop    

00103550 <Xfperr>:
TRAPHANDLER_NOEC(Xfperr,  T_FPERR)
  103550:	6a 00                	push   $0x0
  103552:	6a 10                	push   $0x10
  103554:	e9 e7 00 00 00       	jmp    103640 <_alltraps>
  103559:	90                   	nop    

0010355a <Xalign>:
TRAPHANDLER     (Xalign,  T_ALIGN)
  10355a:	6a 11                	push   $0x11
  10355c:	e9 df 00 00 00       	jmp    103640 <_alltraps>
  103561:	90                   	nop    

00103562 <Xmchk>:
TRAPHANDLER_NOEC(Xmchk,   T_MCHK)
  103562:	6a 00                	push   $0x0
  103564:	6a 12                	push   $0x12
  103566:	e9 d5 00 00 00       	jmp    103640 <_alltraps>
  10356b:	90                   	nop    

0010356c <Xsimd>:
TRAPHANDLER_NOEC(Xsimd,   T_SIMD)
  10356c:	6a 00                	push   $0x0
  10356e:	6a 13                	push   $0x13
  103570:	e9 cb 00 00 00       	jmp    103640 <_alltraps>
  103575:	90                   	nop    

00103576 <Xirq0>:


/* ISA device interrupts */
TRAPHANDLER_NOEC(Xirq0,   T_IRQ0+0)	// IRQ_PIT
  103576:	6a 00                	push   $0x0
  103578:	6a 20                	push   $0x20
  10357a:	e9 c1 00 00 00       	jmp    103640 <_alltraps>
  10357f:	90                   	nop    

00103580 <Xirq1>:
TRAPHANDLER_NOEC(Xirq1,   T_IRQ0+1)	// IRQ_KBD
  103580:	6a 00                	push   $0x0
  103582:	6a 21                	push   $0x21
  103584:	e9 b7 00 00 00       	jmp    103640 <_alltraps>
  103589:	90                   	nop    

0010358a <Xirq2>:
TRAPHANDLER_NOEC(Xirq2,   T_IRQ0+2)
  10358a:	6a 00                	push   $0x0
  10358c:	6a 22                	push   $0x22
  10358e:	e9 ad 00 00 00       	jmp    103640 <_alltraps>
  103593:	90                   	nop    

00103594 <Xirq3>:
TRAPHANDLER_NOEC(Xirq3,   T_IRQ0+3)
  103594:	6a 00                	push   $0x0
  103596:	6a 23                	push   $0x23
  103598:	e9 a3 00 00 00       	jmp    103640 <_alltraps>
  10359d:	90                   	nop    

0010359e <Xirq4>:
TRAPHANDLER_NOEC(Xirq4,   T_IRQ0+4)	// IRQ_SERIAL
  10359e:	6a 00                	push   $0x0
  1035a0:	6a 24                	push   $0x24
  1035a2:	e9 99 00 00 00       	jmp    103640 <_alltraps>
  1035a7:	90                   	nop    

001035a8 <Xirq5>:
TRAPHANDLER_NOEC(Xirq5,   T_IRQ0+5)
  1035a8:	6a 00                	push   $0x0
  1035aa:	6a 25                	push   $0x25
  1035ac:	e9 8f 00 00 00       	jmp    103640 <_alltraps>
  1035b1:	90                   	nop    

001035b2 <Xirq6>:
TRAPHANDLER_NOEC(Xirq6,   T_IRQ0+6)
  1035b2:	6a 00                	push   $0x0
  1035b4:	6a 26                	push   $0x26
  1035b6:	e9 85 00 00 00       	jmp    103640 <_alltraps>
  1035bb:	90                   	nop    

001035bc <Xirq7>:
TRAPHANDLER_NOEC(Xirq7,   T_IRQ0+7)	// IRQ_SPURIOUS
  1035bc:	6a 00                	push   $0x0
  1035be:	6a 27                	push   $0x27
  1035c0:	e9 7b 00 00 00       	jmp    103640 <_alltraps>
  1035c5:	90                   	nop    

001035c6 <Xirq8>:
TRAPHANDLER_NOEC(Xirq8,   T_IRQ0+8)
  1035c6:	6a 00                	push   $0x0
  1035c8:	6a 28                	push   $0x28
  1035ca:	e9 71 00 00 00       	jmp    103640 <_alltraps>
  1035cf:	90                   	nop    

001035d0 <Xirq9>:
TRAPHANDLER_NOEC(Xirq9,   T_IRQ0+9)
  1035d0:	6a 00                	push   $0x0
  1035d2:	6a 29                	push   $0x29
  1035d4:	e9 67 00 00 00       	jmp    103640 <_alltraps>
  1035d9:	90                   	nop    

001035da <Xirq10>:
TRAPHANDLER_NOEC(Xirq10,  T_IRQ0+10)
  1035da:	6a 00                	push   $0x0
  1035dc:	6a 2a                	push   $0x2a
  1035de:	e9 5d 00 00 00       	jmp    103640 <_alltraps>
  1035e3:	90                   	nop    

001035e4 <Xirq11>:
TRAPHANDLER_NOEC(Xirq11,  T_IRQ0+11)
  1035e4:	6a 00                	push   $0x0
  1035e6:	6a 2b                	push   $0x2b
  1035e8:	e9 53 00 00 00       	jmp    103640 <_alltraps>
  1035ed:	90                   	nop    

001035ee <Xirq12>:
TRAPHANDLER_NOEC(Xirq12,  T_IRQ0+12)
  1035ee:	6a 00                	push   $0x0
  1035f0:	6a 2c                	push   $0x2c
  1035f2:	e9 49 00 00 00       	jmp    103640 <_alltraps>
  1035f7:	90                   	nop    

001035f8 <Xirq13>:
TRAPHANDLER_NOEC(Xirq13,  T_IRQ0+13)
  1035f8:	6a 00                	push   $0x0
  1035fa:	6a 2d                	push   $0x2d
  1035fc:	e9 3f 00 00 00       	jmp    103640 <_alltraps>
  103601:	90                   	nop    

00103602 <Xirq14>:
TRAPHANDLER_NOEC(Xirq14,  T_IRQ0+14)	// IRQ_IDE
  103602:	6a 00                	push   $0x0
  103604:	6a 2e                	push   $0x2e
  103606:	e9 35 00 00 00       	jmp    103640 <_alltraps>
  10360b:	90                   	nop    

0010360c <Xirq15>:
TRAPHANDLER_NOEC(Xirq15,  T_IRQ0+15)
  10360c:	6a 00                	push   $0x0
  10360e:	6a 2f                	push   $0x2f
  103610:	e9 2b 00 00 00       	jmp    103640 <_alltraps>
  103615:	90                   	nop    

00103616 <Xsyscall>:

TRAPHANDLER_NOEC(Xsyscall, T_SYSCALL)	// System call
  103616:	6a 00                	push   $0x0
  103618:	6a 30                	push   $0x30
  10361a:	e9 21 00 00 00       	jmp    103640 <_alltraps>
  10361f:	90                   	nop    

00103620 <Xltimer>:
TRAPHANDLER_NOEC(Xltimer,  T_LTIMER)	// Local APIC timer
  103620:	6a 00                	push   $0x0
  103622:	6a 31                	push   $0x31
  103624:	e9 17 00 00 00       	jmp    103640 <_alltraps>
  103629:	90                   	nop    

0010362a <Xlerror>:
TRAPHANDLER_NOEC(Xlerror,  T_LERROR)	// Local APIC error
  10362a:	6a 00                	push   $0x0
  10362c:	6a 32                	push   $0x32
  10362e:	e9 0d 00 00 00       	jmp    103640 <_alltraps>
  103633:	90                   	nop    

00103634 <Xdefault>:

/* default handler -- not for any specific trap */
TRAPHANDLER_NOEC(Xdefault, T_DEFAULT)
  103634:	6a 00                	push   $0x0
  103636:	68 f4 01 00 00       	push   $0x1f4
  10363b:	e9 00 00 00 00       	jmp    103640 <_alltraps>

00103640 <_alltraps>:



.globl	_alltraps
.type	_alltraps,@function
.p2align 4, 0x90		/* 16-byte alignment, nop filled */
_alltraps:
	pushl %ds		# build trap frame
  103640:	1e                   	push   %ds
	pushl %es
  103641:	06                   	push   %es
	pushl %fs
  103642:	0f a0                	push   %fs
	pushl %gs
  103644:	0f a8                	push   %gs
	pushal
  103646:	60                   	pusha  

	movl $CPU_GDT_KDATA,%eax # load kernel's data segment
  103647:	b8 10 00 00 00       	mov    $0x10,%eax
	movw %ax,%ds
  10364c:	8e d8                	movl   %eax,%ds
	movw %ax,%es
  10364e:	8e c0                	movl   %eax,%es

	xorl %ebp,%ebp		# don't let debug_trace() walk into user space
  103650:	31 ed                	xor    %ebp,%ebp

	pushl %esp		# pass pointer to this trapframe 
  103652:	54                   	push   %esp
	call trap		# and call trap (does not return)
  103653:	e8 7e f8 ff ff       	call   102ed6 <trap>

1:	jmp 1b			# should never get here; just spin...
  103658:	eb fe                	jmp    103658 <_alltraps+0x18>
  10365a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi

00103660 <trap_return>:



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
  103660:	8b 64 24 04          	mov    0x4(%esp),%esp
	popal			// restore general-purpose registers except esp
  103664:	61                   	popa   
	popl	%gs		// restore data segment registers
  103665:	0f a9                	pop    %gs
	popl	%fs
  103667:	0f a1                	pop    %fs
	popl	%es
  103669:	07                   	pop    %es
	popl	%ds
  10366a:	1f                   	pop    %ds
	addl	$8,%esp		// skip trapno and errcode
  10366b:	83 c4 08             	add    $0x8,%esp
	iret			// return from trap handler
  10366e:	cf                   	iret   
  10366f:	90                   	nop    

00103670 <sum>:


static uint8_t
sum(uint8_t * addr, int len)
{
  103670:	55                   	push   %ebp
  103671:	89 e5                	mov    %esp,%ebp
  103673:	83 ec 10             	sub    $0x10,%esp
	int i, sum;

	sum = 0;
  103676:	c7 45 fc 00 00 00 00 	movl   $0x0,0xfffffffc(%ebp)
	for (i = 0; i < len; i++)
  10367d:	c7 45 f8 00 00 00 00 	movl   $0x0,0xfffffff8(%ebp)
  103684:	eb 13                	jmp    103699 <sum+0x29>
		sum += addr[i];
  103686:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  103689:	03 45 08             	add    0x8(%ebp),%eax
  10368c:	0f b6 00             	movzbl (%eax),%eax
  10368f:	0f b6 c0             	movzbl %al,%eax
  103692:	01 45 fc             	add    %eax,0xfffffffc(%ebp)
  103695:	83 45 f8 01          	addl   $0x1,0xfffffff8(%ebp)
  103699:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10369c:	3b 45 0c             	cmp    0xc(%ebp),%eax
  10369f:	7c e5                	jl     103686 <sum+0x16>
	return sum;
  1036a1:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  1036a4:	0f b6 c0             	movzbl %al,%eax
}
  1036a7:	c9                   	leave  
  1036a8:	c3                   	ret    

001036a9 <mpsearch1>:

//Look for an MP structure in the len bytes at addr.
static struct mp *
mpsearch1(uint8_t * addr, int len)
{
  1036a9:	55                   	push   %ebp
  1036aa:	89 e5                	mov    %esp,%ebp
  1036ac:	83 ec 28             	sub    $0x28,%esp
	uint8_t *e, *p;

	e = addr + len;
  1036af:	8b 45 0c             	mov    0xc(%ebp),%eax
  1036b2:	03 45 08             	add    0x8(%ebp),%eax
  1036b5:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
	for (p = addr; p < e; p += sizeof(struct mp))
  1036b8:	8b 45 08             	mov    0x8(%ebp),%eax
  1036bb:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  1036be:	eb 42                	jmp    103702 <mpsearch1+0x59>
		if (memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
  1036c0:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
  1036c7:	00 
  1036c8:	c7 44 24 04 c4 c7 10 	movl   $0x10c7c4,0x4(%esp)
  1036cf:	00 
  1036d0:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  1036d3:	89 04 24             	mov    %eax,(%esp)
  1036d6:	e8 7a 82 00 00       	call   10b955 <memcmp>
  1036db:	85 c0                	test   %eax,%eax
  1036dd:	75 1f                	jne    1036fe <mpsearch1+0x55>
  1036df:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
  1036e6:	00 
  1036e7:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  1036ea:	89 04 24             	mov    %eax,(%esp)
  1036ed:	e8 7e ff ff ff       	call   103670 <sum>
  1036f2:	84 c0                	test   %al,%al
  1036f4:	75 08                	jne    1036fe <mpsearch1+0x55>
			return (struct mp *) p;
  1036f6:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  1036f9:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  1036fc:	eb 13                	jmp    103711 <mpsearch1+0x68>
  1036fe:	83 45 fc 10          	addl   $0x10,0xfffffffc(%ebp)
  103702:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  103705:	3b 45 f8             	cmp    0xfffffff8(%ebp),%eax
  103708:	72 b6                	jb     1036c0 <mpsearch1+0x17>
	return 0;
  10370a:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  103711:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
}
  103714:	c9                   	leave  
  103715:	c3                   	ret    

00103716 <mpsearch>:

// Search for the MP Floating Pointer Structure, which according to the
// spec is in one of the following three locations:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp *
mpsearch(void)
{
  103716:	55                   	push   %ebp
  103717:	89 e5                	mov    %esp,%ebp
  103719:	83 ec 28             	sub    $0x28,%esp
	uint8_t          *bda;
	uint32_t            p;
	struct mp      *mp;

	bda = (uint8_t *) 0x400;
  10371c:	c7 45 f4 00 04 00 00 	movl   $0x400,0xfffffff4(%ebp)
	if ((p = ((bda[0x0F] << 8) | bda[0x0E]) << 4)) {
  103723:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  103726:	83 c0 0f             	add    $0xf,%eax
  103729:	0f b6 00             	movzbl (%eax),%eax
  10372c:	0f b6 c0             	movzbl %al,%eax
  10372f:	89 c2                	mov    %eax,%edx
  103731:	c1 e2 08             	shl    $0x8,%edx
  103734:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  103737:	83 c0 0e             	add    $0xe,%eax
  10373a:	0f b6 00             	movzbl (%eax),%eax
  10373d:	0f b6 c0             	movzbl %al,%eax
  103740:	09 d0                	or     %edx,%eax
  103742:	c1 e0 04             	shl    $0x4,%eax
  103745:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  103748:	83 7d f8 00          	cmpl   $0x0,0xfffffff8(%ebp)
  10374c:	74 24                	je     103772 <mpsearch+0x5c>
		if ((mp = mpsearch1((uint8_t *) p, 1024)))
  10374e:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  103751:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
  103758:	00 
  103759:	89 04 24             	mov    %eax,(%esp)
  10375c:	e8 48 ff ff ff       	call   1036a9 <mpsearch1>
  103761:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  103764:	83 7d fc 00          	cmpl   $0x0,0xfffffffc(%ebp)
  103768:	74 56                	je     1037c0 <mpsearch+0xaa>
			return mp;
  10376a:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  10376d:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  103770:	eb 65                	jmp    1037d7 <mpsearch+0xc1>
	} else {
		p = ((bda[0x14] << 8) | bda[0x13]) * 1024;
  103772:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  103775:	83 c0 14             	add    $0x14,%eax
  103778:	0f b6 00             	movzbl (%eax),%eax
  10377b:	0f b6 c0             	movzbl %al,%eax
  10377e:	89 c2                	mov    %eax,%edx
  103780:	c1 e2 08             	shl    $0x8,%edx
  103783:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  103786:	83 c0 13             	add    $0x13,%eax
  103789:	0f b6 00             	movzbl (%eax),%eax
  10378c:	0f b6 c0             	movzbl %al,%eax
  10378f:	09 d0                	or     %edx,%eax
  103791:	c1 e0 0a             	shl    $0xa,%eax
  103794:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
		if ((mp = mpsearch1((uint8_t *) p - 1024, 1024)))
  103797:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10379a:	2d 00 04 00 00       	sub    $0x400,%eax
  10379f:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
  1037a6:	00 
  1037a7:	89 04 24             	mov    %eax,(%esp)
  1037aa:	e8 fa fe ff ff       	call   1036a9 <mpsearch1>
  1037af:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  1037b2:	83 7d fc 00          	cmpl   $0x0,0xfffffffc(%ebp)
  1037b6:	74 08                	je     1037c0 <mpsearch+0xaa>
			return mp;
  1037b8:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  1037bb:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  1037be:	eb 17                	jmp    1037d7 <mpsearch+0xc1>
	}
	return mpsearch1((uint8_t *) 0xF0000, 0x10000);
  1037c0:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
  1037c7:	00 
  1037c8:	c7 04 24 00 00 0f 00 	movl   $0xf0000,(%esp)
  1037cf:	e8 d5 fe ff ff       	call   1036a9 <mpsearch1>
  1037d4:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  1037d7:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
}
  1037da:	c9                   	leave  
  1037db:	c3                   	ret    

001037dc <mpconfig>:

// Search for an MP configuration table.  For now,
// don 't accept the default configurations (physaddr == 0).
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf *
mpconfig(struct mp **pmp) {
  1037dc:	55                   	push   %ebp
  1037dd:	89 e5                	mov    %esp,%ebp
  1037df:	83 ec 28             	sub    $0x28,%esp
	struct mpconf  *conf;
	struct mp      *mp;

	if ((mp = mpsearch()) == 0 || mp->physaddr == 0)
  1037e2:	e8 2f ff ff ff       	call   103716 <mpsearch>
  1037e7:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  1037ea:	83 7d fc 00          	cmpl   $0x0,0xfffffffc(%ebp)
  1037ee:	74 0a                	je     1037fa <mpconfig+0x1e>
  1037f0:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  1037f3:	8b 40 04             	mov    0x4(%eax),%eax
  1037f6:	85 c0                	test   %eax,%eax
  1037f8:	75 0c                	jne    103806 <mpconfig+0x2a>
		return 0;
  1037fa:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  103801:	e9 84 00 00 00       	jmp    10388a <mpconfig+0xae>
	conf = (struct mpconf *) mp->physaddr;
  103806:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  103809:	8b 40 04             	mov    0x4(%eax),%eax
  10380c:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
	if (memcmp(conf, "PCMP", 4) != 0)
  10380f:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
  103816:	00 
  103817:	c7 44 24 04 c9 c7 10 	movl   $0x10c7c9,0x4(%esp)
  10381e:	00 
  10381f:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  103822:	89 04 24             	mov    %eax,(%esp)
  103825:	e8 2b 81 00 00       	call   10b955 <memcmp>
  10382a:	85 c0                	test   %eax,%eax
  10382c:	74 09                	je     103837 <mpconfig+0x5b>
		return 0;
  10382e:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  103835:	eb 53                	jmp    10388a <mpconfig+0xae>
	if (conf->version != 1 && conf->version != 4)
  103837:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10383a:	0f b6 40 06          	movzbl 0x6(%eax),%eax
  10383e:	3c 01                	cmp    $0x1,%al
  103840:	74 14                	je     103856 <mpconfig+0x7a>
  103842:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  103845:	0f b6 40 06          	movzbl 0x6(%eax),%eax
  103849:	3c 04                	cmp    $0x4,%al
  10384b:	74 09                	je     103856 <mpconfig+0x7a>
		return 0;
  10384d:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  103854:	eb 34                	jmp    10388a <mpconfig+0xae>
	if (sum((uint8_t *) conf, conf->length) != 0)
  103856:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  103859:	0f b7 40 04          	movzwl 0x4(%eax),%eax
  10385d:	0f b7 c0             	movzwl %ax,%eax
  103860:	8b 55 f8             	mov    0xfffffff8(%ebp),%edx
  103863:	89 44 24 04          	mov    %eax,0x4(%esp)
  103867:	89 14 24             	mov    %edx,(%esp)
  10386a:	e8 01 fe ff ff       	call   103670 <sum>
  10386f:	84 c0                	test   %al,%al
  103871:	74 09                	je     10387c <mpconfig+0xa0>
		return 0;
  103873:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  10387a:	eb 0e                	jmp    10388a <mpconfig+0xae>
       *pmp = mp;
  10387c:	8b 55 08             	mov    0x8(%ebp),%edx
  10387f:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  103882:	89 02                	mov    %eax,(%edx)
	return conf;
  103884:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  103887:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  10388a:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
}
  10388d:	c9                   	leave  
  10388e:	c3                   	ret    

0010388f <mp_init>:

void
mp_init(void)
{
  10388f:	55                   	push   %ebp
  103890:	89 e5                	mov    %esp,%ebp
  103892:	83 ec 58             	sub    $0x58,%esp
	uint8_t          *p, *e;
	struct mp      *mp;
	struct mpconf  *conf;
	struct mpproc  *proc;
	struct mpioapic *mpio;

	if (!cpu_onboot())	// only do once, on the boot CPU
  103895:	e8 88 01 00 00       	call   103a22 <cpu_onboot>
  10389a:	85 c0                	test   %eax,%eax
  10389c:	0f 84 7e 01 00 00    	je     103a20 <mp_init+0x191>
		return;

	if ((conf = mpconfig(&mp)) == 0)
  1038a2:	8d 45 cc             	lea    0xffffffcc(%ebp),%eax
  1038a5:	89 04 24             	mov    %eax,(%esp)
  1038a8:	e8 2f ff ff ff       	call   1037dc <mpconfig>
  1038ad:	89 45 d8             	mov    %eax,0xffffffd8(%ebp)
  1038b0:	83 7d d8 00          	cmpl   $0x0,0xffffffd8(%ebp)
  1038b4:	0f 84 66 01 00 00    	je     103a20 <mp_init+0x191>
		return; // Not a multiprocessor machine - just use boot CPU.

	ismp = 1;
  1038ba:	c7 05 e8 ed 17 00 01 	movl   $0x1,0x17ede8
  1038c1:	00 00 00 
	lapic = (uint32_t *) conf->lapicaddr;
  1038c4:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  1038c7:	8b 40 24             	mov    0x24(%eax),%eax
  1038ca:	a3 04 20 18 00       	mov    %eax,0x182004
	for (p = (uint8_t *) (conf + 1), e = (uint8_t *) conf + conf->length;
  1038cf:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  1038d2:	83 c0 2c             	add    $0x2c,%eax
  1038d5:	89 45 d0             	mov    %eax,0xffffffd0(%ebp)
  1038d8:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  1038db:	0f b7 40 04          	movzwl 0x4(%eax),%eax
  1038df:	0f b7 c0             	movzwl %ax,%eax
  1038e2:	89 c2                	mov    %eax,%edx
  1038e4:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  1038e7:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1038ea:	89 45 d4             	mov    %eax,0xffffffd4(%ebp)
			p < e;) {
  1038ed:	e9 da 00 00 00       	jmp    1039cc <mp_init+0x13d>
		switch (*p) {
  1038f2:	8b 45 d0             	mov    0xffffffd0(%ebp),%eax
  1038f5:	0f b6 00             	movzbl (%eax),%eax
  1038f8:	0f b6 c0             	movzbl %al,%eax
  1038fb:	89 45 b8             	mov    %eax,0xffffffb8(%ebp)
  1038fe:	83 7d b8 04          	cmpl   $0x4,0xffffffb8(%ebp)
  103902:	0f 87 9b 00 00 00    	ja     1039a3 <mp_init+0x114>
  103908:	8b 55 b8             	mov    0xffffffb8(%ebp),%edx
  10390b:	8b 04 95 fc c7 10 00 	mov    0x10c7fc(,%edx,4),%eax
  103912:	ff e0                	jmp    *%eax
		case MPPROC:
			proc = (struct mpproc *) p;
  103914:	8b 45 d0             	mov    0xffffffd0(%ebp),%eax
  103917:	89 45 dc             	mov    %eax,0xffffffdc(%ebp)
			p += sizeof(struct mpproc);
  10391a:	83 45 d0 14          	addl   $0x14,0xffffffd0(%ebp)
			if (!(proc->flags & MPENAB))
  10391e:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  103921:	0f b6 40 03          	movzbl 0x3(%eax),%eax
  103925:	0f b6 c0             	movzbl %al,%eax
  103928:	83 e0 01             	and    $0x1,%eax
  10392b:	85 c0                	test   %eax,%eax
  10392d:	0f 84 99 00 00 00    	je     1039cc <mp_init+0x13d>
				continue;	// processor disabled

			// Get a cpu struct and kernel stack for this CPU.
			cpu *c = (proc->flags & MPBOOT)
					? &cpu_boot : cpu_alloc();
  103933:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  103936:	0f b6 40 03          	movzbl 0x3(%eax),%eax
  10393a:	0f b6 c0             	movzbl %al,%eax
  10393d:	83 e0 02             	and    $0x2,%eax
  103940:	85 c0                	test   %eax,%eax
  103942:	75 0a                	jne    10394e <mp_init+0xbf>
  103944:	e8 15 de ff ff       	call   10175e <cpu_alloc>
  103949:	89 45 bc             	mov    %eax,0xffffffbc(%ebp)
  10394c:	eb 07                	jmp    103955 <mp_init+0xc6>
  10394e:	c7 45 bc 00 e0 10 00 	movl   $0x10e000,0xffffffbc(%ebp)
  103955:	8b 45 bc             	mov    0xffffffbc(%ebp),%eax
  103958:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
			c->id = proc->apicid;
  10395b:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  10395e:	0f b6 50 01          	movzbl 0x1(%eax),%edx
  103962:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  103965:	88 90 ac 00 00 00    	mov    %dl,0xac(%eax)
			ncpu++;
  10396b:	a1 ec ed 17 00       	mov    0x17edec,%eax
  103970:	83 c0 01             	add    $0x1,%eax
  103973:	a3 ec ed 17 00       	mov    %eax,0x17edec
			continue;
  103978:	eb 52                	jmp    1039cc <mp_init+0x13d>
		case MPIOAPIC:
			mpio = (struct mpioapic *) p;
  10397a:	8b 45 d0             	mov    0xffffffd0(%ebp),%eax
  10397d:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)
			p += sizeof(struct mpioapic);
  103980:	83 45 d0 08          	addl   $0x8,0xffffffd0(%ebp)
			ioapicid = mpio->apicno;
  103984:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  103987:	0f b6 40 01          	movzbl 0x1(%eax),%eax
  10398b:	a2 e0 ed 17 00       	mov    %al,0x17ede0
			ioapic = (struct ioapic *) mpio->addr;
  103990:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  103993:	8b 40 04             	mov    0x4(%eax),%eax
  103996:	a3 e4 ed 17 00       	mov    %eax,0x17ede4
			continue;
  10399b:	eb 2f                	jmp    1039cc <mp_init+0x13d>
		case MPBUS:
		case MPIOINTR:
		case MPLINTR:
			p += 8;
  10399d:	83 45 d0 08          	addl   $0x8,0xffffffd0(%ebp)
			continue;
  1039a1:	eb 29                	jmp    1039cc <mp_init+0x13d>
		default:
			panic("mpinit: unknown config type %x\n", *p);
  1039a3:	8b 45 d0             	mov    0xffffffd0(%ebp),%eax
  1039a6:	0f b6 00             	movzbl (%eax),%eax
  1039a9:	0f b6 c0             	movzbl %al,%eax
  1039ac:	89 44 24 0c          	mov    %eax,0xc(%esp)
  1039b0:	c7 44 24 08 d0 c7 10 	movl   $0x10c7d0,0x8(%esp)
  1039b7:	00 
  1039b8:	c7 44 24 04 92 00 00 	movl   $0x92,0x4(%esp)
  1039bf:	00 
  1039c0:	c7 04 24 f0 c7 10 00 	movl   $0x10c7f0,(%esp)
  1039c7:	e8 9c cf ff ff       	call   100968 <debug_panic>
  1039cc:	8b 45 d0             	mov    0xffffffd0(%ebp),%eax
  1039cf:	3b 45 d4             	cmp    0xffffffd4(%ebp),%eax
  1039d2:	0f 82 1a ff ff ff    	jb     1038f2 <mp_init+0x63>
		}
	}
	if (mp->imcrp) {
  1039d8:	8b 45 cc             	mov    0xffffffcc(%ebp),%eax
  1039db:	0f b6 40 0c          	movzbl 0xc(%eax),%eax
  1039df:	84 c0                	test   %al,%al
  1039e1:	74 3d                	je     103a20 <mp_init+0x191>
  1039e3:	c7 45 ec 22 00 00 00 	movl   $0x22,0xffffffec(%ebp)
  1039ea:	c6 45 eb 70          	movb   $0x70,0xffffffeb(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  1039ee:	0f b6 45 eb          	movzbl 0xffffffeb(%ebp),%eax
  1039f2:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
  1039f5:	ee                   	out    %al,(%dx)
  1039f6:	c7 45 f4 23 00 00 00 	movl   $0x23,0xfffffff4(%ebp)
  1039fd:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  103a00:	ec                   	in     (%dx),%al
  103a01:	88 45 f3             	mov    %al,0xfffffff3(%ebp)
  103a04:	0f b6 45 f3          	movzbl 0xfffffff3(%ebp),%eax
		// Bochs doesn 't support IMCR, so this doesn' t run on Bochs.
		// But it would on real hardware.
		outb(0x22, 0x70);		// Select IMCR
		outb(0x23, inb(0x23) | 1);	// Mask external interrupts.
  103a08:	83 c8 01             	or     $0x1,%eax
  103a0b:	0f b6 c0             	movzbl %al,%eax
  103a0e:	c7 45 fc 23 00 00 00 	movl   $0x23,0xfffffffc(%ebp)
  103a15:	88 45 fb             	mov    %al,0xfffffffb(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  103a18:	0f b6 45 fb          	movzbl 0xfffffffb(%ebp),%eax
  103a1c:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  103a1f:	ee                   	out    %al,(%dx)
	}
}
  103a20:	c9                   	leave  
  103a21:	c3                   	ret    

00103a22 <cpu_onboot>:
}

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  103a22:	55                   	push   %ebp
  103a23:	89 e5                	mov    %esp,%ebp
  103a25:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  103a28:	e8 0d 00 00 00       	call   103a3a <cpu_cur>
  103a2d:	3d 00 e0 10 00       	cmp    $0x10e000,%eax
  103a32:	0f 94 c0             	sete   %al
  103a35:	0f b6 c0             	movzbl %al,%eax
}
  103a38:	c9                   	leave  
  103a39:	c3                   	ret    

00103a3a <cpu_cur>:
  103a3a:	55                   	push   %ebp
  103a3b:	89 e5                	mov    %esp,%ebp
  103a3d:	83 ec 28             	sub    $0x28,%esp
static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  103a40:	89 65 fc             	mov    %esp,0xfffffffc(%ebp)
        return esp;
  103a43:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  103a46:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  103a49:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  103a4c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  103a51:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	assert(c->magic == CPU_MAGIC);
  103a54:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  103a57:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  103a5d:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  103a62:	74 24                	je     103a88 <cpu_cur+0x4e>
  103a64:	c7 44 24 0c 10 c8 10 	movl   $0x10c810,0xc(%esp)
  103a6b:	00 
  103a6c:	c7 44 24 08 26 c8 10 	movl   $0x10c826,0x8(%esp)
  103a73:	00 
  103a74:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  103a7b:	00 
  103a7c:	c7 04 24 3b c8 10 00 	movl   $0x10c83b,(%esp)
  103a83:	e8 e0 ce ff ff       	call   100968 <debug_panic>
	return c;
  103a88:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
}
  103a8b:	c9                   	leave  
  103a8c:	c3                   	ret    
  103a8d:	90                   	nop    
  103a8e:	90                   	nop    
  103a8f:	90                   	nop    

00103a90 <spinlock_init_>:


void
spinlock_init_(struct spinlock *lk, const char *file, int line)
{
  103a90:	55                   	push   %ebp
  103a91:	89 e5                	mov    %esp,%ebp
  lk->file = file;
  103a93:	8b 55 08             	mov    0x8(%ebp),%edx
  103a96:	8b 45 0c             	mov    0xc(%ebp),%eax
  103a99:	89 42 04             	mov    %eax,0x4(%edx)
  lk->line = line;
  103a9c:	8b 55 08             	mov    0x8(%ebp),%edx
  103a9f:	8b 45 10             	mov    0x10(%ebp),%eax
  103aa2:	89 42 08             	mov    %eax,0x8(%edx)
  lk->locked = 0;
  103aa5:	8b 45 08             	mov    0x8(%ebp),%eax
  103aa8:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->cpu = NULL;
  103aae:	8b 45 08             	mov    0x8(%ebp),%eax
  103ab1:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
}
  103ab8:	5d                   	pop    %ebp
  103ab9:	c3                   	ret    

00103aba <spinlock_acquire>:

// Acquire the lock.
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
spinlock_acquire(struct spinlock *lk)
{
  103aba:	55                   	push   %ebp
  103abb:	89 e5                	mov    %esp,%ebp
  103abd:	83 ec 28             	sub    $0x28,%esp
  if (spinlock_holding(lk))
  103ac0:	8b 45 08             	mov    0x8(%ebp),%eax
  103ac3:	89 04 24             	mov    %eax,(%esp)
  103ac6:	e8 44 01 00 00       	call   103c0f <spinlock_holding>
  103acb:	85 c0                	test   %eax,%eax
  103acd:	74 21                	je     103af0 <spinlock_acquire+0x36>
    panic("Attempt to acquire lock already held by this cpu");
  103acf:	c7 44 24 08 48 c8 10 	movl   $0x10c848,0x8(%esp)
  103ad6:	00 
  103ad7:	c7 44 24 04 24 00 00 	movl   $0x24,0x4(%esp)
  103ade:	00 
  103adf:	c7 04 24 79 c8 10 00 	movl   $0x10c879,(%esp)
  103ae6:	e8 7d ce ff ff       	call   100968 <debug_panic>
  while(xchg(&lk->locked, 1) != 0) {
    pause(); // buisy wait
  103aeb:	e8 3e 00 00 00       	call   103b2e <pause>
  103af0:	8b 45 08             	mov    0x8(%ebp),%eax
  103af3:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  103afa:	00 
  103afb:	89 04 24             	mov    %eax,(%esp)
  103afe:	e8 32 00 00 00       	call   103b35 <xchg>
  103b03:	85 c0                	test   %eax,%eax
  103b05:	75 e4                	jne    103aeb <spinlock_acquire+0x31>
  }
  lk->cpu = cpu_cur();
  103b07:	e8 56 00 00 00       	call   103b62 <cpu_cur>
  103b0c:	89 c2                	mov    %eax,%edx
  103b0e:	8b 45 08             	mov    0x8(%ebp),%eax
  103b11:	89 50 0c             	mov    %edx,0xc(%eax)
  debug_trace(read_ebp(), lk->eips);
  103b14:	8b 55 08             	mov    0x8(%ebp),%edx
  103b17:	83 c2 10             	add    $0x10,%edx
static gcc_inline uint32_t
read_ebp(void)
{
        uint32_t ebp;
        __asm __volatile("movl %%ebp,%0" : "=rm" (ebp));
  103b1a:	89 6d fc             	mov    %ebp,0xfffffffc(%ebp)
        return ebp;
  103b1d:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  103b20:	89 54 24 04          	mov    %edx,0x4(%esp)
  103b24:	89 04 24             	mov    %eax,(%esp)
  103b27:	e8 43 cf ff ff       	call   100a6f <debug_trace>
}
  103b2c:	c9                   	leave  
  103b2d:	c3                   	ret    

00103b2e <pause>:
}

static inline void
pause(void)
{
  103b2e:	55                   	push   %ebp
  103b2f:	89 e5                	mov    %esp,%ebp
	asm volatile("pause" : : : "memory");
  103b31:	f3 90                	pause  
}
  103b33:	5d                   	pop    %ebp
  103b34:	c3                   	ret    

00103b35 <xchg>:
  103b35:	55                   	push   %ebp
  103b36:	89 e5                	mov    %esp,%ebp
  103b38:	53                   	push   %ebx
  103b39:	83 ec 14             	sub    $0x14,%esp
  103b3c:	8b 4d 08             	mov    0x8(%ebp),%ecx
  103b3f:	8b 55 0c             	mov    0xc(%ebp),%edx
  103b42:	8b 45 08             	mov    0x8(%ebp),%eax
  103b45:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  103b48:	89 d0                	mov    %edx,%eax
  103b4a:	8b 5d e8             	mov    0xffffffe8(%ebp),%ebx
  103b4d:	f0 87 01             	lock xchg %eax,(%ecx)
  103b50:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  103b53:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  103b56:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  103b59:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  103b5c:	83 c4 14             	add    $0x14,%esp
  103b5f:	5b                   	pop    %ebx
  103b60:	5d                   	pop    %ebp
  103b61:	c3                   	ret    

00103b62 <cpu_cur>:

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  103b62:	55                   	push   %ebp
  103b63:	89 e5                	mov    %esp,%ebp
  103b65:	83 ec 28             	sub    $0x28,%esp
static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  103b68:	89 65 fc             	mov    %esp,0xfffffffc(%ebp)
        return esp;
  103b6b:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  103b6e:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  103b71:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  103b74:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  103b79:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	assert(c->magic == CPU_MAGIC);
  103b7c:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  103b7f:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  103b85:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  103b8a:	74 24                	je     103bb0 <cpu_cur+0x4e>
  103b8c:	c7 44 24 0c 89 c8 10 	movl   $0x10c889,0xc(%esp)
  103b93:	00 
  103b94:	c7 44 24 08 9f c8 10 	movl   $0x10c89f,0x8(%esp)
  103b9b:	00 
  103b9c:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  103ba3:	00 
  103ba4:	c7 04 24 b4 c8 10 00 	movl   $0x10c8b4,(%esp)
  103bab:	e8 b8 cd ff ff       	call   100968 <debug_panic>
	return c;
  103bb0:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
}
  103bb3:	c9                   	leave  
  103bb4:	c3                   	ret    

00103bb5 <spinlock_release>:

// Release the lock.
void
spinlock_release(struct spinlock *lk)
{
  103bb5:	55                   	push   %ebp
  103bb6:	89 e5                	mov    %esp,%ebp
  103bb8:	83 ec 18             	sub    $0x18,%esp
  if (!spinlock_holding(lk))
  103bbb:	8b 45 08             	mov    0x8(%ebp),%eax
  103bbe:	89 04 24             	mov    %eax,(%esp)
  103bc1:	e8 49 00 00 00       	call   103c0f <spinlock_holding>
  103bc6:	85 c0                	test   %eax,%eax
  103bc8:	75 1c                	jne    103be6 <spinlock_release+0x31>
    panic("Attempt to release lock not held by this cpu");
  103bca:	c7 44 24 08 c4 c8 10 	movl   $0x10c8c4,0x8(%esp)
  103bd1:	00 
  103bd2:	c7 44 24 04 31 00 00 	movl   $0x31,0x4(%esp)
  103bd9:	00 
  103bda:	c7 04 24 79 c8 10 00 	movl   $0x10c879,(%esp)
  103be1:	e8 82 cd ff ff       	call   100968 <debug_panic>
  lk->eips[0] = 0;
  103be6:	8b 45 08             	mov    0x8(%ebp),%eax
  103be9:	c7 40 10 00 00 00 00 	movl   $0x0,0x10(%eax)
  lk->cpu = 0;
  103bf0:	8b 45 08             	mov    0x8(%ebp),%eax
  103bf3:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  xchg(&lk->locked, 0);
  103bfa:	8b 45 08             	mov    0x8(%ebp),%eax
  103bfd:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  103c04:	00 
  103c05:	89 04 24             	mov    %eax,(%esp)
  103c08:	e8 28 ff ff ff       	call   103b35 <xchg>
}
  103c0d:	c9                   	leave  
  103c0e:	c3                   	ret    

00103c0f <spinlock_holding>:

// Check whether this cpu is holding the lock.
int
spinlock_holding(spinlock *lk)
{
  103c0f:	55                   	push   %ebp
  103c10:	89 e5                	mov    %esp,%ebp
  103c12:	53                   	push   %ebx
  103c13:	83 ec 04             	sub    $0x4,%esp
  return (lk->locked) && (lk->cpu == cpu_cur());
  103c16:	8b 45 08             	mov    0x8(%ebp),%eax
  103c19:	8b 00                	mov    (%eax),%eax
  103c1b:	85 c0                	test   %eax,%eax
  103c1d:	74 18                	je     103c37 <spinlock_holding+0x28>
  103c1f:	8b 45 08             	mov    0x8(%ebp),%eax
  103c22:	8b 58 0c             	mov    0xc(%eax),%ebx
  103c25:	e8 38 ff ff ff       	call   103b62 <cpu_cur>
  103c2a:	39 c3                	cmp    %eax,%ebx
  103c2c:	75 09                	jne    103c37 <spinlock_holding+0x28>
  103c2e:	c7 45 f8 01 00 00 00 	movl   $0x1,0xfffffff8(%ebp)
  103c35:	eb 07                	jmp    103c3e <spinlock_holding+0x2f>
  103c37:	c7 45 f8 00 00 00 00 	movl   $0x0,0xfffffff8(%ebp)
  103c3e:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
}
  103c41:	83 c4 04             	add    $0x4,%esp
  103c44:	5b                   	pop    %ebx
  103c45:	5d                   	pop    %ebp
  103c46:	c3                   	ret    

00103c47 <spinlock_godeep>:

// Function that simply recurses to a specified depth.
// The useless return value and volatile parameter are
// so GCC doesn't collapse it via tail-call elimination.
int gcc_noinline
spinlock_godeep(volatile int depth, spinlock* lk)
{
  103c47:	55                   	push   %ebp
  103c48:	89 e5                	mov    %esp,%ebp
  103c4a:	83 ec 18             	sub    $0x18,%esp
	if (depth==0) { spinlock_acquire(lk); return 1; }
  103c4d:	8b 45 08             	mov    0x8(%ebp),%eax
  103c50:	85 c0                	test   %eax,%eax
  103c52:	75 14                	jne    103c68 <spinlock_godeep+0x21>
  103c54:	8b 45 0c             	mov    0xc(%ebp),%eax
  103c57:	89 04 24             	mov    %eax,(%esp)
  103c5a:	e8 5b fe ff ff       	call   103aba <spinlock_acquire>
  103c5f:	c7 45 fc 01 00 00 00 	movl   $0x1,0xfffffffc(%ebp)
  103c66:	eb 22                	jmp    103c8a <spinlock_godeep+0x43>
	else return spinlock_godeep(depth-1, lk) * depth;
  103c68:	8b 45 08             	mov    0x8(%ebp),%eax
  103c6b:	8d 50 ff             	lea    0xffffffff(%eax),%edx
  103c6e:	8b 45 0c             	mov    0xc(%ebp),%eax
  103c71:	89 44 24 04          	mov    %eax,0x4(%esp)
  103c75:	89 14 24             	mov    %edx,(%esp)
  103c78:	e8 ca ff ff ff       	call   103c47 <spinlock_godeep>
  103c7d:	89 c2                	mov    %eax,%edx
  103c7f:	8b 45 08             	mov    0x8(%ebp),%eax
  103c82:	89 d1                	mov    %edx,%ecx
  103c84:	0f af c8             	imul   %eax,%ecx
  103c87:	89 4d fc             	mov    %ecx,0xfffffffc(%ebp)
  103c8a:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
}
  103c8d:	c9                   	leave  
  103c8e:	c3                   	ret    

00103c8f <spinlock_check>:

void spinlock_check()
{
  103c8f:	55                   	push   %ebp
  103c90:	89 e5                	mov    %esp,%ebp
  103c92:	53                   	push   %ebx
  103c93:	83 ec 44             	sub    $0x44,%esp
  103c96:	89 e0                	mov    %esp,%eax
  103c98:	89 45 d8             	mov    %eax,0xffffffd8(%ebp)
	const int NUMLOCKS=10;
  103c9b:	c7 45 e4 0a 00 00 00 	movl   $0xa,0xffffffe4(%ebp)
	const int NUMRUNS=5;
  103ca2:	c7 45 e8 05 00 00 00 	movl   $0x5,0xffffffe8(%ebp)
	int i,j,run;
	const char* file = "spinlock_check";
  103ca9:	c7 45 f8 f1 c8 10 00 	movl   $0x10c8f1,0xfffffff8(%ebp)
	spinlock locks[NUMLOCKS];
  103cb0:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  103cb3:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  103cba:	8d 04 d5 00 00 00 00 	lea    0x0(,%edx,8),%eax
  103cc1:	29 d0                	sub    %edx,%eax
  103cc3:	83 c0 0f             	add    $0xf,%eax
  103cc6:	83 c0 0f             	add    $0xf,%eax
  103cc9:	c1 e8 04             	shr    $0x4,%eax
  103ccc:	c1 e0 04             	shl    $0x4,%eax
  103ccf:	29 c4                	sub    %eax,%esp
  103cd1:	8d 44 24 10          	lea    0x10(%esp),%eax
  103cd5:	89 45 d4             	mov    %eax,0xffffffd4(%ebp)
  103cd8:	8b 45 d4             	mov    0xffffffd4(%ebp),%eax
  103cdb:	83 c0 0f             	add    $0xf,%eax
  103cde:	c1 e8 04             	shr    $0x4,%eax
  103ce1:	c1 e0 04             	shl    $0x4,%eax
  103ce4:	89 45 d4             	mov    %eax,0xffffffd4(%ebp)
  103ce7:	8b 45 d4             	mov    0xffffffd4(%ebp),%eax
  103cea:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)

	// Initialize the locks
	for(i=0;i<NUMLOCKS;i++) spinlock_init_(&locks[i], file, 0);
  103ced:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  103cf4:	eb 34                	jmp    103d2a <spinlock_check+0x9b>
  103cf6:	8b 4d e0             	mov    0xffffffe0(%ebp),%ecx
  103cf9:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  103cfc:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  103d03:	8d 04 d5 00 00 00 00 	lea    0x0(,%edx,8),%eax
  103d0a:	29 d0                	sub    %edx,%eax
  103d0c:	8d 14 01             	lea    (%ecx,%eax,1),%edx
  103d0f:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  103d16:	00 
  103d17:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  103d1a:	89 44 24 04          	mov    %eax,0x4(%esp)
  103d1e:	89 14 24             	mov    %edx,(%esp)
  103d21:	e8 6a fd ff ff       	call   103a90 <spinlock_init_>
  103d26:	83 45 ec 01          	addl   $0x1,0xffffffec(%ebp)
  103d2a:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  103d2d:	3b 45 e4             	cmp    0xffffffe4(%ebp),%eax
  103d30:	7c c4                	jl     103cf6 <spinlock_check+0x67>
	// Make sure that all locks have CPU set to NULL initially
	for(i=0;i<NUMLOCKS;i++) assert(locks[i].cpu==NULL);
  103d32:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  103d39:	eb 49                	jmp    103d84 <spinlock_check+0xf5>
  103d3b:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  103d3e:	8b 4d e0             	mov    0xffffffe0(%ebp),%ecx
  103d41:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  103d48:	8d 04 d5 00 00 00 00 	lea    0x0(,%edx,8),%eax
  103d4f:	29 d0                	sub    %edx,%eax
  103d51:	01 c8                	add    %ecx,%eax
  103d53:	83 c0 0c             	add    $0xc,%eax
  103d56:	8b 00                	mov    (%eax),%eax
  103d58:	85 c0                	test   %eax,%eax
  103d5a:	74 24                	je     103d80 <spinlock_check+0xf1>
  103d5c:	c7 44 24 0c 00 c9 10 	movl   $0x10c900,0xc(%esp)
  103d63:	00 
  103d64:	c7 44 24 08 9f c8 10 	movl   $0x10c89f,0x8(%esp)
  103d6b:	00 
  103d6c:	c7 44 24 04 53 00 00 	movl   $0x53,0x4(%esp)
  103d73:	00 
  103d74:	c7 04 24 79 c8 10 00 	movl   $0x10c879,(%esp)
  103d7b:	e8 e8 cb ff ff       	call   100968 <debug_panic>
  103d80:	83 45 ec 01          	addl   $0x1,0xffffffec(%ebp)
  103d84:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  103d87:	3b 45 e4             	cmp    0xffffffe4(%ebp),%eax
  103d8a:	7c af                	jl     103d3b <spinlock_check+0xac>
	// Make sure that all locks have the correct debug info.
	for(i=0;i<NUMLOCKS;i++) assert(locks[i].file==file);
  103d8c:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  103d93:	eb 4a                	jmp    103ddf <spinlock_check+0x150>
  103d95:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  103d98:	8b 4d e0             	mov    0xffffffe0(%ebp),%ecx
  103d9b:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  103da2:	8d 04 d5 00 00 00 00 	lea    0x0(,%edx,8),%eax
  103da9:	29 d0                	sub    %edx,%eax
  103dab:	01 c8                	add    %ecx,%eax
  103dad:	83 c0 04             	add    $0x4,%eax
  103db0:	8b 00                	mov    (%eax),%eax
  103db2:	3b 45 f8             	cmp    0xfffffff8(%ebp),%eax
  103db5:	74 24                	je     103ddb <spinlock_check+0x14c>
  103db7:	c7 44 24 0c 13 c9 10 	movl   $0x10c913,0xc(%esp)
  103dbe:	00 
  103dbf:	c7 44 24 08 9f c8 10 	movl   $0x10c89f,0x8(%esp)
  103dc6:	00 
  103dc7:	c7 44 24 04 55 00 00 	movl   $0x55,0x4(%esp)
  103dce:	00 
  103dcf:	c7 04 24 79 c8 10 00 	movl   $0x10c879,(%esp)
  103dd6:	e8 8d cb ff ff       	call   100968 <debug_panic>
  103ddb:	83 45 ec 01          	addl   $0x1,0xffffffec(%ebp)
  103ddf:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  103de2:	3b 45 e4             	cmp    0xffffffe4(%ebp),%eax
  103de5:	7c ae                	jl     103d95 <spinlock_check+0x106>

	for (run=0;run<NUMRUNS;run++) 
  103de7:	c7 45 f4 00 00 00 00 	movl   $0x0,0xfffffff4(%ebp)
  103dee:	e9 17 03 00 00       	jmp    10410a <spinlock_check+0x47b>
	{
		// Lock all locks
		for(i=0;i<NUMLOCKS;i++)
  103df3:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  103dfa:	eb 2c                	jmp    103e28 <spinlock_check+0x199>
			spinlock_godeep(i, &locks[i]);
  103dfc:	8b 4d e0             	mov    0xffffffe0(%ebp),%ecx
  103dff:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  103e02:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  103e09:	8d 04 d5 00 00 00 00 	lea    0x0(,%edx,8),%eax
  103e10:	29 d0                	sub    %edx,%eax
  103e12:	8d 04 01             	lea    (%ecx,%eax,1),%eax
  103e15:	89 44 24 04          	mov    %eax,0x4(%esp)
  103e19:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  103e1c:	89 04 24             	mov    %eax,(%esp)
  103e1f:	e8 23 fe ff ff       	call   103c47 <spinlock_godeep>
  103e24:	83 45 ec 01          	addl   $0x1,0xffffffec(%ebp)
  103e28:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  103e2b:	3b 45 e4             	cmp    0xffffffe4(%ebp),%eax
  103e2e:	7c cc                	jl     103dfc <spinlock_check+0x16d>

		// Make sure that all locks have the right CPU
		for(i=0;i<NUMLOCKS;i++)
  103e30:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  103e37:	eb 4e                	jmp    103e87 <spinlock_check+0x1f8>
			assert(locks[i].cpu == cpu_cur());
  103e39:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  103e3c:	8b 4d e0             	mov    0xffffffe0(%ebp),%ecx
  103e3f:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  103e46:	8d 04 d5 00 00 00 00 	lea    0x0(,%edx,8),%eax
  103e4d:	29 d0                	sub    %edx,%eax
  103e4f:	01 c8                	add    %ecx,%eax
  103e51:	83 c0 0c             	add    $0xc,%eax
  103e54:	8b 18                	mov    (%eax),%ebx
  103e56:	e8 07 fd ff ff       	call   103b62 <cpu_cur>
  103e5b:	39 c3                	cmp    %eax,%ebx
  103e5d:	74 24                	je     103e83 <spinlock_check+0x1f4>
  103e5f:	c7 44 24 0c 27 c9 10 	movl   $0x10c927,0xc(%esp)
  103e66:	00 
  103e67:	c7 44 24 08 9f c8 10 	movl   $0x10c89f,0x8(%esp)
  103e6e:	00 
  103e6f:	c7 44 24 04 5f 00 00 	movl   $0x5f,0x4(%esp)
  103e76:	00 
  103e77:	c7 04 24 79 c8 10 00 	movl   $0x10c879,(%esp)
  103e7e:	e8 e5 ca ff ff       	call   100968 <debug_panic>
  103e83:	83 45 ec 01          	addl   $0x1,0xffffffec(%ebp)
  103e87:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  103e8a:	3b 45 e4             	cmp    0xffffffe4(%ebp),%eax
  103e8d:	7c aa                	jl     103e39 <spinlock_check+0x1aa>
		// Make sure that all locks have holding correctly implemented.
		for(i=0;i<NUMLOCKS;i++)
  103e8f:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  103e96:	eb 4d                	jmp    103ee5 <spinlock_check+0x256>
			assert(spinlock_holding(&locks[i]) != 0);
  103e98:	8b 4d e0             	mov    0xffffffe0(%ebp),%ecx
  103e9b:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  103e9e:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  103ea5:	8d 04 d5 00 00 00 00 	lea    0x0(,%edx,8),%eax
  103eac:	29 d0                	sub    %edx,%eax
  103eae:	8d 04 01             	lea    (%ecx,%eax,1),%eax
  103eb1:	89 04 24             	mov    %eax,(%esp)
  103eb4:	e8 56 fd ff ff       	call   103c0f <spinlock_holding>
  103eb9:	85 c0                	test   %eax,%eax
  103ebb:	75 24                	jne    103ee1 <spinlock_check+0x252>
  103ebd:	c7 44 24 0c 44 c9 10 	movl   $0x10c944,0xc(%esp)
  103ec4:	00 
  103ec5:	c7 44 24 08 9f c8 10 	movl   $0x10c89f,0x8(%esp)
  103ecc:	00 
  103ecd:	c7 44 24 04 62 00 00 	movl   $0x62,0x4(%esp)
  103ed4:	00 
  103ed5:	c7 04 24 79 c8 10 00 	movl   $0x10c879,(%esp)
  103edc:	e8 87 ca ff ff       	call   100968 <debug_panic>
  103ee1:	83 45 ec 01          	addl   $0x1,0xffffffec(%ebp)
  103ee5:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  103ee8:	3b 45 e4             	cmp    0xffffffe4(%ebp),%eax
  103eeb:	7c ab                	jl     103e98 <spinlock_check+0x209>
		// Make sure that top i frames are somewhere in godeep.
		for(i=0;i<NUMLOCKS;i++) 
  103eed:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  103ef4:	e9 b9 00 00 00       	jmp    103fb2 <spinlock_check+0x323>
		{
			for(j=0; j<=i && j < DEBUG_TRACEFRAMES ; j++) 
  103ef9:	c7 45 f0 00 00 00 00 	movl   $0x0,0xfffffff0(%ebp)
  103f00:	e9 97 00 00 00       	jmp    103f9c <spinlock_check+0x30d>
			{
				assert(locks[i].eips[j] >=
  103f05:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  103f08:	8b 4d f0             	mov    0xfffffff0(%ebp),%ecx
  103f0b:	8b 5d e0             	mov    0xffffffe0(%ebp),%ebx
  103f0e:	8d 14 00             	lea    (%eax,%eax,1),%edx
  103f11:	8d 04 d5 00 00 00 00 	lea    0x0(,%edx,8),%eax
  103f18:	29 d0                	sub    %edx,%eax
  103f1a:	01 c8                	add    %ecx,%eax
  103f1c:	8b 54 83 10          	mov    0x10(%ebx,%eax,4),%edx
  103f20:	b8 47 3c 10 00       	mov    $0x103c47,%eax
  103f25:	39 c2                	cmp    %eax,%edx
  103f27:	73 24                	jae    103f4d <spinlock_check+0x2be>
  103f29:	c7 44 24 0c 68 c9 10 	movl   $0x10c968,0xc(%esp)
  103f30:	00 
  103f31:	c7 44 24 08 9f c8 10 	movl   $0x10c89f,0x8(%esp)
  103f38:	00 
  103f39:	c7 44 24 04 69 00 00 	movl   $0x69,0x4(%esp)
  103f40:	00 
  103f41:	c7 04 24 79 c8 10 00 	movl   $0x10c879,(%esp)
  103f48:	e8 1b ca ff ff       	call   100968 <debug_panic>
					(uint32_t)spinlock_godeep);
				assert(locks[i].eips[j] <
  103f4d:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  103f50:	8b 4d f0             	mov    0xfffffff0(%ebp),%ecx
  103f53:	8b 5d e0             	mov    0xffffffe0(%ebp),%ebx
  103f56:	8d 14 00             	lea    (%eax,%eax,1),%edx
  103f59:	8d 04 d5 00 00 00 00 	lea    0x0(,%edx,8),%eax
  103f60:	29 d0                	sub    %edx,%eax
  103f62:	01 c8                	add    %ecx,%eax
  103f64:	8b 54 83 10          	mov    0x10(%ebx,%eax,4),%edx
  103f68:	b8 47 3c 10 00       	mov    $0x103c47,%eax
  103f6d:	83 c0 64             	add    $0x64,%eax
  103f70:	39 c2                	cmp    %eax,%edx
  103f72:	72 24                	jb     103f98 <spinlock_check+0x309>
  103f74:	c7 44 24 0c 98 c9 10 	movl   $0x10c998,0xc(%esp)
  103f7b:	00 
  103f7c:	c7 44 24 08 9f c8 10 	movl   $0x10c89f,0x8(%esp)
  103f83:	00 
  103f84:	c7 44 24 04 6b 00 00 	movl   $0x6b,0x4(%esp)
  103f8b:	00 
  103f8c:	c7 04 24 79 c8 10 00 	movl   $0x10c879,(%esp)
  103f93:	e8 d0 c9 ff ff       	call   100968 <debug_panic>
  103f98:	83 45 f0 01          	addl   $0x1,0xfffffff0(%ebp)
  103f9c:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  103f9f:	3b 45 ec             	cmp    0xffffffec(%ebp),%eax
  103fa2:	7f 0a                	jg     103fae <spinlock_check+0x31f>
  103fa4:	83 7d f0 09          	cmpl   $0x9,0xfffffff0(%ebp)
  103fa8:	0f 8e 57 ff ff ff    	jle    103f05 <spinlock_check+0x276>
  103fae:	83 45 ec 01          	addl   $0x1,0xffffffec(%ebp)
  103fb2:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  103fb5:	3b 45 e4             	cmp    0xffffffe4(%ebp),%eax
  103fb8:	0f 8c 3b ff ff ff    	jl     103ef9 <spinlock_check+0x26a>
					(uint32_t)spinlock_godeep+100);
			}
		}

		// Release all locks
		for(i=0;i<NUMLOCKS;i++) spinlock_release(&locks[i]);
  103fbe:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  103fc5:	eb 25                	jmp    103fec <spinlock_check+0x35d>
  103fc7:	8b 4d e0             	mov    0xffffffe0(%ebp),%ecx
  103fca:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  103fcd:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  103fd4:	8d 04 d5 00 00 00 00 	lea    0x0(,%edx,8),%eax
  103fdb:	29 d0                	sub    %edx,%eax
  103fdd:	8d 04 01             	lea    (%ecx,%eax,1),%eax
  103fe0:	89 04 24             	mov    %eax,(%esp)
  103fe3:	e8 cd fb ff ff       	call   103bb5 <spinlock_release>
  103fe8:	83 45 ec 01          	addl   $0x1,0xffffffec(%ebp)
  103fec:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  103fef:	3b 45 e4             	cmp    0xffffffe4(%ebp),%eax
  103ff2:	7c d3                	jl     103fc7 <spinlock_check+0x338>
		// Make sure that the CPU has been cleared
		for(i=0;i<NUMLOCKS;i++) assert(locks[i].cpu == NULL);
  103ff4:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  103ffb:	eb 49                	jmp    104046 <spinlock_check+0x3b7>
  103ffd:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  104000:	8b 4d e0             	mov    0xffffffe0(%ebp),%ecx
  104003:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  10400a:	8d 04 d5 00 00 00 00 	lea    0x0(,%edx,8),%eax
  104011:	29 d0                	sub    %edx,%eax
  104013:	01 c8                	add    %ecx,%eax
  104015:	83 c0 0c             	add    $0xc,%eax
  104018:	8b 00                	mov    (%eax),%eax
  10401a:	85 c0                	test   %eax,%eax
  10401c:	74 24                	je     104042 <spinlock_check+0x3b3>
  10401e:	c7 44 24 0c c9 c9 10 	movl   $0x10c9c9,0xc(%esp)
  104025:	00 
  104026:	c7 44 24 08 9f c8 10 	movl   $0x10c89f,0x8(%esp)
  10402d:	00 
  10402e:	c7 44 24 04 72 00 00 	movl   $0x72,0x4(%esp)
  104035:	00 
  104036:	c7 04 24 79 c8 10 00 	movl   $0x10c879,(%esp)
  10403d:	e8 26 c9 ff ff       	call   100968 <debug_panic>
  104042:	83 45 ec 01          	addl   $0x1,0xffffffec(%ebp)
  104046:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  104049:	3b 45 e4             	cmp    0xffffffe4(%ebp),%eax
  10404c:	7c af                	jl     103ffd <spinlock_check+0x36e>
		for(i=0;i<NUMLOCKS;i++) assert(locks[i].eips[0]==0);
  10404e:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  104055:	eb 49                	jmp    1040a0 <spinlock_check+0x411>
  104057:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  10405a:	8b 4d e0             	mov    0xffffffe0(%ebp),%ecx
  10405d:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  104064:	8d 04 d5 00 00 00 00 	lea    0x0(,%edx,8),%eax
  10406b:	29 d0                	sub    %edx,%eax
  10406d:	01 c8                	add    %ecx,%eax
  10406f:	83 c0 10             	add    $0x10,%eax
  104072:	8b 00                	mov    (%eax),%eax
  104074:	85 c0                	test   %eax,%eax
  104076:	74 24                	je     10409c <spinlock_check+0x40d>
  104078:	c7 44 24 0c de c9 10 	movl   $0x10c9de,0xc(%esp)
  10407f:	00 
  104080:	c7 44 24 08 9f c8 10 	movl   $0x10c89f,0x8(%esp)
  104087:	00 
  104088:	c7 44 24 04 73 00 00 	movl   $0x73,0x4(%esp)
  10408f:	00 
  104090:	c7 04 24 79 c8 10 00 	movl   $0x10c879,(%esp)
  104097:	e8 cc c8 ff ff       	call   100968 <debug_panic>
  10409c:	83 45 ec 01          	addl   $0x1,0xffffffec(%ebp)
  1040a0:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  1040a3:	3b 45 e4             	cmp    0xffffffe4(%ebp),%eax
  1040a6:	7c af                	jl     104057 <spinlock_check+0x3c8>
		// Make sure that all locks have holding correctly implemented.
		for(i=0;i<NUMLOCKS;i++) assert(spinlock_holding(&locks[i]) == 0);
  1040a8:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  1040af:	eb 4d                	jmp    1040fe <spinlock_check+0x46f>
  1040b1:	8b 4d e0             	mov    0xffffffe0(%ebp),%ecx
  1040b4:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  1040b7:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  1040be:	8d 04 d5 00 00 00 00 	lea    0x0(,%edx,8),%eax
  1040c5:	29 d0                	sub    %edx,%eax
  1040c7:	8d 04 01             	lea    (%ecx,%eax,1),%eax
  1040ca:	89 04 24             	mov    %eax,(%esp)
  1040cd:	e8 3d fb ff ff       	call   103c0f <spinlock_holding>
  1040d2:	85 c0                	test   %eax,%eax
  1040d4:	74 24                	je     1040fa <spinlock_check+0x46b>
  1040d6:	c7 44 24 0c f4 c9 10 	movl   $0x10c9f4,0xc(%esp)
  1040dd:	00 
  1040de:	c7 44 24 08 9f c8 10 	movl   $0x10c89f,0x8(%esp)
  1040e5:	00 
  1040e6:	c7 44 24 04 75 00 00 	movl   $0x75,0x4(%esp)
  1040ed:	00 
  1040ee:	c7 04 24 79 c8 10 00 	movl   $0x10c879,(%esp)
  1040f5:	e8 6e c8 ff ff       	call   100968 <debug_panic>
  1040fa:	83 45 ec 01          	addl   $0x1,0xffffffec(%ebp)
  1040fe:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  104101:	3b 45 e4             	cmp    0xffffffe4(%ebp),%eax
  104104:	7c ab                	jl     1040b1 <spinlock_check+0x422>
  104106:	83 45 f4 01          	addl   $0x1,0xfffffff4(%ebp)
  10410a:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  10410d:	3b 45 e8             	cmp    0xffffffe8(%ebp),%eax
  104110:	0f 8c dd fc ff ff    	jl     103df3 <spinlock_check+0x164>
	}
	cprintf("spinlock_check() succeeded!\n");
  104116:	c7 04 24 15 ca 10 00 	movl   $0x10ca15,(%esp)
  10411d:	e8 4f 73 00 00       	call   10b471 <cprintf>
  104122:	8b 65 d8             	mov    0xffffffd8(%ebp),%esp
}
  104125:	8b 5d fc             	mov    0xfffffffc(%ebp),%ebx
  104128:	c9                   	leave  
  104129:	c3                   	ret    
  10412a:	90                   	nop    
  10412b:	90                   	nop    

0010412c <proc_init>:
static proc **readytail;

void
proc_init(void)
{
  10412c:	55                   	push   %ebp
  10412d:	89 e5                	mov    %esp,%ebp
  10412f:	83 ec 18             	sub    $0x18,%esp
  if (!cpu_onboot())
  104132:	e8 2c 00 00 00       	call   104163 <cpu_onboot>
  104137:	85 c0                	test   %eax,%eax
  104139:	74 26                	je     104161 <proc_init+0x35>
 	return;

  // your module initialization code here
  spinlock_init(&readylock);
  10413b:	c7 44 24 08 25 00 00 	movl   $0x25,0x8(%esp)
  104142:	00 
  104143:	c7 44 24 04 34 ca 10 	movl   $0x10ca34,0x4(%esp)
  10414a:	00 
  10414b:	c7 04 24 40 aa 17 00 	movl   $0x17aa40,(%esp)
  104152:	e8 39 f9 ff ff       	call   103a90 <spinlock_init_>
  readytail = &readyhead;
  104157:	c7 05 7c aa 17 00 78 	movl   $0x17aa78,0x17aa7c
  10415e:	aa 17 00 
}
  104161:	c9                   	leave  
  104162:	c3                   	ret    

00104163 <cpu_onboot>:
}

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  104163:	55                   	push   %ebp
  104164:	89 e5                	mov    %esp,%ebp
  104166:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  104169:	e8 0d 00 00 00       	call   10417b <cpu_cur>
  10416e:	3d 00 e0 10 00       	cmp    $0x10e000,%eax
  104173:	0f 94 c0             	sete   %al
  104176:	0f b6 c0             	movzbl %al,%eax
}
  104179:	c9                   	leave  
  10417a:	c3                   	ret    

0010417b <cpu_cur>:
  10417b:	55                   	push   %ebp
  10417c:	89 e5                	mov    %esp,%ebp
  10417e:	83 ec 28             	sub    $0x28,%esp
static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  104181:	89 65 fc             	mov    %esp,0xfffffffc(%ebp)
        return esp;
  104184:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  104187:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  10418a:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10418d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  104192:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	assert(c->magic == CPU_MAGIC);
  104195:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  104198:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  10419e:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  1041a3:	74 24                	je     1041c9 <cpu_cur+0x4e>
  1041a5:	c7 44 24 0c 40 ca 10 	movl   $0x10ca40,0xc(%esp)
  1041ac:	00 
  1041ad:	c7 44 24 08 56 ca 10 	movl   $0x10ca56,0x8(%esp)
  1041b4:	00 
  1041b5:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  1041bc:	00 
  1041bd:	c7 04 24 6b ca 10 00 	movl   $0x10ca6b,(%esp)
  1041c4:	e8 9f c7 ff ff       	call   100968 <debug_panic>
	return c;
  1041c9:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
}
  1041cc:	c9                   	leave  
  1041cd:	c3                   	ret    

001041ce <proc_alloc>:

// Allocate and initialize a new proc as child 'cn' of parent 'p'.
// Returns NULL if no physical memory available.
proc *
proc_alloc(proc *p, uint32_t cn)
{
  1041ce:	55                   	push   %ebp
  1041cf:	89 e5                	mov    %esp,%ebp
  1041d1:	83 ec 28             	sub    $0x28,%esp
	pageinfo *pi = mem_alloc();
  1041d4:	e8 72 ce ff ff       	call   10104b <mem_alloc>
  1041d9:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	if (!pi)
  1041dc:	83 7d f4 00          	cmpl   $0x0,0xfffffff4(%ebp)
  1041e0:	75 0c                	jne    1041ee <proc_alloc+0x20>
		return NULL;
  1041e2:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  1041e9:	e9 14 02 00 00       	jmp    104402 <proc_alloc+0x234>
  1041ee:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  1041f1:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
// Atomically increment the reference count on a page.
static gcc_inline void
mem_incref(pageinfo *pi)
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  1041f4:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  1041f9:	83 c0 08             	add    $0x8,%eax
  1041fc:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  1041ff:	73 17                	jae    104218 <proc_alloc+0x4a>
  104201:	a1 84 ed 17 00       	mov    0x17ed84,%eax
  104206:	c1 e0 03             	shl    $0x3,%eax
  104209:	89 c2                	mov    %eax,%edx
  10420b:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  104210:	8d 04 02             	lea    (%edx,%eax,1),%eax
  104213:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  104216:	77 24                	ja     10423c <proc_alloc+0x6e>
  104218:	c7 44 24 0c 78 ca 10 	movl   $0x10ca78,0xc(%esp)
  10421f:	00 
  104220:	c7 44 24 08 56 ca 10 	movl   $0x10ca56,0x8(%esp)
  104227:	00 
  104228:	c7 44 24 04 8e 00 00 	movl   $0x8e,0x4(%esp)
  10422f:	00 
  104230:	c7 04 24 af ca 10 00 	movl   $0x10caaf,(%esp)
  104237:	e8 2c c7 ff ff       	call   100968 <debug_panic>
	assert(pi != mem_ptr2pi(pmap_zero));	// Don't alloc/free zero page!
  10423c:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  104242:	b8 00 10 18 00       	mov    $0x181000,%eax
  104247:	c1 e8 0c             	shr    $0xc,%eax
  10424a:	c1 e0 03             	shl    $0x3,%eax
  10424d:	8d 04 02             	lea    (%edx,%eax,1),%eax
  104250:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  104253:	75 24                	jne    104279 <proc_alloc+0xab>
  104255:	c7 44 24 0c bc ca 10 	movl   $0x10cabc,0xc(%esp)
  10425c:	00 
  10425d:	c7 44 24 08 56 ca 10 	movl   $0x10ca56,0x8(%esp)
  104264:	00 
  104265:	c7 44 24 04 8f 00 00 	movl   $0x8f,0x4(%esp)
  10426c:	00 
  10426d:	c7 04 24 af ca 10 00 	movl   $0x10caaf,(%esp)
  104274:	e8 ef c6 ff ff       	call   100968 <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  104279:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  10427f:	b8 0c 00 10 00       	mov    $0x10000c,%eax
  104284:	c1 e8 0c             	shr    $0xc,%eax
  104287:	c1 e0 03             	shl    $0x3,%eax
  10428a:	8d 04 02             	lea    (%edx,%eax,1),%eax
  10428d:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  104290:	77 40                	ja     1042d2 <proc_alloc+0x104>
  104292:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  104298:	b8 08 20 18 00       	mov    $0x182008,%eax
  10429d:	83 e8 01             	sub    $0x1,%eax
  1042a0:	c1 e8 0c             	shr    $0xc,%eax
  1042a3:	c1 e0 03             	shl    $0x3,%eax
  1042a6:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1042a9:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  1042ac:	72 24                	jb     1042d2 <proc_alloc+0x104>
  1042ae:	c7 44 24 0c d8 ca 10 	movl   $0x10cad8,0xc(%esp)
  1042b5:	00 
  1042b6:	c7 44 24 08 56 ca 10 	movl   $0x10ca56,0x8(%esp)
  1042bd:	00 
  1042be:	c7 44 24 04 90 00 00 	movl   $0x90,0x4(%esp)
  1042c5:	00 
  1042c6:	c7 04 24 af ca 10 00 	movl   $0x10caaf,(%esp)
  1042cd:	e8 96 c6 ff ff       	call   100968 <debug_panic>

	lockadd(&pi->refcount, 1);
  1042d2:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  1042d5:	83 c0 04             	add    $0x4,%eax
  1042d8:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  1042df:	00 
  1042e0:	89 04 24             	mov    %eax,(%esp)
  1042e3:	e8 1f 01 00 00       	call   104407 <lockadd>
	mem_incref(pi);

	proc *cp = (proc*)mem_pi2ptr(pi);
  1042e8:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  1042eb:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  1042f0:	89 d1                	mov    %edx,%ecx
  1042f2:	29 c1                	sub    %eax,%ecx
  1042f4:	89 c8                	mov    %ecx,%eax
  1042f6:	c1 e0 09             	shl    $0x9,%eax
  1042f9:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
	memset(cp, 0, sizeof(proc));
  1042fc:	c7 44 24 08 b0 06 00 	movl   $0x6b0,0x8(%esp)
  104303:	00 
  104304:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  10430b:	00 
  10430c:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10430f:	89 04 24             	mov    %eax,(%esp)
  104312:	e8 de 74 00 00       	call   10b7f5 <memset>
	spinlock_init(&cp->lock);
  104317:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10431a:	c7 44 24 08 35 00 00 	movl   $0x35,0x8(%esp)
  104321:	00 
  104322:	c7 44 24 04 34 ca 10 	movl   $0x10ca34,0x4(%esp)
  104329:	00 
  10432a:	89 04 24             	mov    %eax,(%esp)
  10432d:	e8 5e f7 ff ff       	call   103a90 <spinlock_init_>
	cp->parent = p;
  104332:	8b 55 f8             	mov    0xfffffff8(%ebp),%edx
  104335:	8b 45 08             	mov    0x8(%ebp),%eax
  104338:	89 42 38             	mov    %eax,0x38(%edx)
	cp->state = PROC_STOP;
  10433b:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10433e:	c7 80 3c 04 00 00 00 	movl   $0x0,0x43c(%eax)
  104345:	00 00 00 

	// Integer register state
	cp->sv.tf.ds = CPU_GDT_UDATA | 3;
  104348:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10434b:	66 c7 80 7c 04 00 00 	movw   $0x23,0x47c(%eax)
  104352:	23 00 
	cp->sv.tf.es = CPU_GDT_UDATA | 3;
  104354:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  104357:	66 c7 80 78 04 00 00 	movw   $0x23,0x478(%eax)
  10435e:	23 00 
	cp->sv.tf.cs = CPU_GDT_UCODE | 3;
  104360:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  104363:	66 c7 80 8c 04 00 00 	movw   $0x1b,0x48c(%eax)
  10436a:	1b 00 
	cp->sv.tf.ss = CPU_GDT_UDATA | 3;
  10436c:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10436f:	66 c7 80 98 04 00 00 	movw   $0x23,0x498(%eax)
  104376:	23 00 

	cp->pdir = pmap_newpdir();
  104378:	e8 e5 18 00 00       	call   105c62 <pmap_newpdir>
  10437d:	89 c2                	mov    %eax,%edx
  10437f:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  104382:	89 90 a0 06 00 00    	mov    %edx,0x6a0(%eax)
	cp->rpdir = pmap_newpdir();
  104388:	e8 d5 18 00 00       	call   105c62 <pmap_newpdir>
  10438d:	89 c2                	mov    %eax,%edx
  10438f:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  104392:	89 90 a4 06 00 00    	mov    %edx,0x6a4(%eax)
	if (!cp->pdir || !cp->rpdir)
  104398:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10439b:	8b 80 a0 06 00 00    	mov    0x6a0(%eax),%eax
  1043a1:	85 c0                	test   %eax,%eax
  1043a3:	74 0d                	je     1043b2 <proc_alloc+0x1e4>
  1043a5:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1043a8:	8b 80 a4 06 00 00    	mov    0x6a4(%eax),%eax
  1043ae:	85 c0                	test   %eax,%eax
  1043b0:	75 37                	jne    1043e9 <proc_alloc+0x21b>
	{
		if(cp->pdir) 
  1043b2:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1043b5:	8b 80 a0 06 00 00    	mov    0x6a0(%eax),%eax
  1043bb:	85 c0                	test   %eax,%eax
  1043bd:	74 21                	je     1043e0 <proc_alloc+0x212>
			pmap_freepdir(mem_ptr2pi(cp->pdir));
  1043bf:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1043c2:	8b 80 a0 06 00 00    	mov    0x6a0(%eax),%eax
  1043c8:	c1 e8 0c             	shr    $0xc,%eax
  1043cb:	c1 e0 03             	shl    $0x3,%eax
  1043ce:	89 c2                	mov    %eax,%edx
  1043d0:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  1043d5:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1043d8:	89 04 24             	mov    %eax,(%esp)
  1043db:	e8 e7 19 00 00       	call   105dc7 <pmap_freepdir>
		return NULL;
  1043e0:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  1043e7:	eb 19                	jmp    104402 <proc_alloc+0x234>
	}
	
	if (p)
  1043e9:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  1043ed:	74 0d                	je     1043fc <proc_alloc+0x22e>
		p->child[cn] = cp;
  1043ef:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  1043f2:	8b 55 08             	mov    0x8(%ebp),%edx
  1043f5:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1043f8:	89 44 8a 3c          	mov    %eax,0x3c(%edx,%ecx,4)
	
	return cp;
  1043fc:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1043ff:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  104402:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
}
  104405:	c9                   	leave  
  104406:	c3                   	ret    

00104407 <lockadd>:

// Atomically add incr to *addr.
static inline void
lockadd(volatile int32_t *addr, int32_t incr)
{
  104407:	55                   	push   %ebp
  104408:	89 e5                	mov    %esp,%ebp
	asm volatile("lock; addl %1,%0" : "+m" (*addr) : "r" (incr) : "cc");
  10440a:	8b 4d 08             	mov    0x8(%ebp),%ecx
  10440d:	8b 55 0c             	mov    0xc(%ebp),%edx
  104410:	8b 45 08             	mov    0x8(%ebp),%eax
  104413:	f0 01 11             	lock add %edx,(%ecx)
}
  104416:	5d                   	pop    %ebp
  104417:	c3                   	ret    

00104418 <proc_ready>:

// Put process p in the ready state and add it to the ready queue.
void
proc_ready(proc *p)
{
  104418:	55                   	push   %ebp
  104419:	89 e5                	mov    %esp,%ebp
  10441b:	83 ec 08             	sub    $0x8,%esp
//	panic("proc_ready not implemented");
  spinlock_acquire(&readylock);
  10441e:	c7 04 24 40 aa 17 00 	movl   $0x17aa40,(%esp)
  104425:	e8 90 f6 ff ff       	call   103aba <spinlock_acquire>

  p->state = PROC_READY;
  10442a:	8b 45 08             	mov    0x8(%ebp),%eax
  10442d:	c7 80 3c 04 00 00 01 	movl   $0x1,0x43c(%eax)
  104434:	00 00 00 
  p->readynext = NULL;
  104437:	8b 45 08             	mov    0x8(%ebp),%eax
  10443a:	c7 80 40 04 00 00 00 	movl   $0x0,0x440(%eax)
  104441:	00 00 00 
  *readytail = p;
  104444:	8b 15 7c aa 17 00    	mov    0x17aa7c,%edx
  10444a:	8b 45 08             	mov    0x8(%ebp),%eax
  10444d:	89 02                	mov    %eax,(%edx)
  readytail = &p->readynext;
  10444f:	8b 45 08             	mov    0x8(%ebp),%eax
  104452:	05 40 04 00 00       	add    $0x440,%eax
  104457:	a3 7c aa 17 00       	mov    %eax,0x17aa7c

  spinlock_release(&readylock);
  10445c:	c7 04 24 40 aa 17 00 	movl   $0x17aa40,(%esp)
  104463:	e8 4d f7 ff ff       	call   103bb5 <spinlock_release>
}
  104468:	c9                   	leave  
  104469:	c3                   	ret    

0010446a <proc_save>:

// Save the current process's state before switching to another process.
// Copies trapframe 'tf' into the proc struct,
// and saves any other relevant state such as FPU state.
// The 'entry' parameter is one of:
//	-1	if we entered the kernel via a trap before executing an insn
//	0	if we entered via a syscall and must abort/rollback the syscall
//	1	if we entered via a syscall and are completing the syscall
void
proc_save(proc *p, trapframe *tf, int entry)
{
  10446a:	55                   	push   %ebp
  10446b:	89 e5                	mov    %esp,%ebp
  10446d:	83 ec 18             	sub    $0x18,%esp
    assert(p == proc_cur());
  104470:	e8 06 fd ff ff       	call   10417b <cpu_cur>
  104475:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  10447b:	3b 45 08             	cmp    0x8(%ebp),%eax
  10447e:	74 24                	je     1044a4 <proc_save+0x3a>
  104480:	c7 44 24 0c 09 cb 10 	movl   $0x10cb09,0xc(%esp)
  104487:	00 
  104488:	c7 44 24 08 56 ca 10 	movl   $0x10ca56,0x8(%esp)
  10448f:	00 
  104490:	c7 44 24 04 67 00 00 	movl   $0x67,0x4(%esp)
  104497:	00 
  104498:	c7 04 24 34 ca 10 00 	movl   $0x10ca34,(%esp)
  10449f:	e8 c4 c4 ff ff       	call   100968 <debug_panic>

    if (tf != &p->sv.tf)
  1044a4:	8b 45 08             	mov    0x8(%ebp),%eax
  1044a7:	05 50 04 00 00       	add    $0x450,%eax
  1044ac:	3b 45 0c             	cmp    0xc(%ebp),%eax
  1044af:	74 21                	je     1044d2 <proc_save+0x68>
      p->sv.tf = *tf; // integer register state
  1044b1:	8b 45 08             	mov    0x8(%ebp),%eax
  1044b4:	8b 55 0c             	mov    0xc(%ebp),%edx
  1044b7:	8d 88 50 04 00 00    	lea    0x450(%eax),%ecx
  1044bd:	b8 4c 00 00 00       	mov    $0x4c,%eax
  1044c2:	89 44 24 08          	mov    %eax,0x8(%esp)
  1044c6:	89 54 24 04          	mov    %edx,0x4(%esp)
  1044ca:	89 0c 24             	mov    %ecx,(%esp)
  1044cd:	e8 62 74 00 00       	call   10b934 <memcpy>
    if (entry == 0)
  1044d2:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  1044d6:	75 15                	jne    1044ed <proc_save+0x83>
      p->sv.tf.eip -= 2;  // back up to replay INT instruction
  1044d8:	8b 45 08             	mov    0x8(%ebp),%eax
  1044db:	8b 80 88 04 00 00    	mov    0x488(%eax),%eax
  1044e1:	8d 50 fe             	lea    0xfffffffe(%eax),%edx
  1044e4:	8b 45 08             	mov    0x8(%ebp),%eax
  1044e7:	89 90 88 04 00 00    	mov    %edx,0x488(%eax)
}
  1044ed:	c9                   	leave  
  1044ee:	c3                   	ret    

001044ef <proc_wait>:

// Go to sleep waiting for a given child process to finish running.
// Parent process 'p' must be running and locked on entry.
// The supplied trapframe represents p's register state on syscall entry.
void gcc_noreturn
proc_wait(proc *p, proc *cp, trapframe *tf)
{
  1044ef:	55                   	push   %ebp
  1044f0:	89 e5                	mov    %esp,%ebp
  1044f2:	83 ec 18             	sub    $0x18,%esp
	//panic("proc_wait not implemented");
  assert(spinlock_holding(&p->lock));
  1044f5:	8b 45 08             	mov    0x8(%ebp),%eax
  1044f8:	89 04 24             	mov    %eax,(%esp)
  1044fb:	e8 0f f7 ff ff       	call   103c0f <spinlock_holding>
  104500:	85 c0                	test   %eax,%eax
  104502:	75 24                	jne    104528 <proc_wait+0x39>
  104504:	c7 44 24 0c 19 cb 10 	movl   $0x10cb19,0xc(%esp)
  10450b:	00 
  10450c:	c7 44 24 08 56 ca 10 	movl   $0x10ca56,0x8(%esp)
  104513:	00 
  104514:	c7 44 24 04 76 00 00 	movl   $0x76,0x4(%esp)
  10451b:	00 
  10451c:	c7 04 24 34 ca 10 00 	movl   $0x10ca34,(%esp)
  104523:	e8 40 c4 ff ff       	call   100968 <debug_panic>
  assert(cp && cp != &proc_null); // null proc is always stopped
  104528:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  10452c:	74 09                	je     104537 <proc_wait+0x48>
  10452e:	81 7d 0c 00 ee 17 00 	cmpl   $0x17ee00,0xc(%ebp)
  104535:	75 24                	jne    10455b <proc_wait+0x6c>
  104537:	c7 44 24 0c 34 cb 10 	movl   $0x10cb34,0xc(%esp)
  10453e:	00 
  10453f:	c7 44 24 08 56 ca 10 	movl   $0x10ca56,0x8(%esp)
  104546:	00 
  104547:	c7 44 24 04 77 00 00 	movl   $0x77,0x4(%esp)
  10454e:	00 
  10454f:	c7 04 24 34 ca 10 00 	movl   $0x10ca34,(%esp)
  104556:	e8 0d c4 ff ff       	call   100968 <debug_panic>
  assert(cp->state != PROC_STOP);
  10455b:	8b 45 0c             	mov    0xc(%ebp),%eax
  10455e:	8b 80 3c 04 00 00    	mov    0x43c(%eax),%eax
  104564:	85 c0                	test   %eax,%eax
  104566:	75 24                	jne    10458c <proc_wait+0x9d>
  104568:	c7 44 24 0c 4b cb 10 	movl   $0x10cb4b,0xc(%esp)
  10456f:	00 
  104570:	c7 44 24 08 56 ca 10 	movl   $0x10ca56,0x8(%esp)
  104577:	00 
  104578:	c7 44 24 04 78 00 00 	movl   $0x78,0x4(%esp)
  10457f:	00 
  104580:	c7 04 24 34 ca 10 00 	movl   $0x10ca34,(%esp)
  104587:	e8 dc c3 ff ff       	call   100968 <debug_panic>

  p->state = PROC_WAIT;
  10458c:	8b 45 08             	mov    0x8(%ebp),%eax
  10458f:	c7 80 3c 04 00 00 03 	movl   $0x3,0x43c(%eax)
  104596:	00 00 00 
  p->runcpu = NULL;
  104599:	8b 45 08             	mov    0x8(%ebp),%eax
  10459c:	c7 80 44 04 00 00 00 	movl   $0x0,0x444(%eax)
  1045a3:	00 00 00 
  p->waitchild = cp;  // remember what child we're waiting on
  1045a6:	8b 55 08             	mov    0x8(%ebp),%edx
  1045a9:	8b 45 0c             	mov    0xc(%ebp),%eax
  1045ac:	89 82 48 04 00 00    	mov    %eax,0x448(%edx)
  proc_save(p, tf, 0);  // save process state before INT instruction
  1045b2:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  1045b9:	00 
  1045ba:	8b 45 10             	mov    0x10(%ebp),%eax
  1045bd:	89 44 24 04          	mov    %eax,0x4(%esp)
  1045c1:	8b 45 08             	mov    0x8(%ebp),%eax
  1045c4:	89 04 24             	mov    %eax,(%esp)
  1045c7:	e8 9e fe ff ff       	call   10446a <proc_save>

  spinlock_release(&p->lock);
  1045cc:	8b 45 08             	mov    0x8(%ebp),%eax
  1045cf:	89 04 24             	mov    %eax,(%esp)
  1045d2:	e8 de f5 ff ff       	call   103bb5 <spinlock_release>

  proc_sched();
  1045d7:	e8 00 00 00 00       	call   1045dc <proc_sched>

001045dc <proc_sched>:
}

void gcc_noreturn
proc_sched(void)
{
  1045dc:	55                   	push   %ebp
  1045dd:	89 e5                	mov    %esp,%ebp
  1045df:	83 ec 28             	sub    $0x28,%esp
//	panic("proc_sched not implemented");
  cpu *c = cpu_cur();
  1045e2:	e8 94 fb ff ff       	call   10417b <cpu_cur>
  1045e7:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  spinlock_acquire(&readylock);
  1045ea:	c7 04 24 40 aa 17 00 	movl   $0x17aa40,(%esp)
  1045f1:	e8 c4 f4 ff ff       	call   103aba <spinlock_acquire>
  while (!readyhead || cpu_disabled(c)) {
  1045f6:	eb 2a                	jmp    104622 <proc_sched+0x46>
    spinlock_release(&readylock);
  1045f8:	c7 04 24 40 aa 17 00 	movl   $0x17aa40,(%esp)
  1045ff:	e8 b1 f5 ff ff       	call   103bb5 <spinlock_release>

    //cprintf("cpu %d waiting for work\n", cpu_cur()->id);
    while (!readyhead || cpu_disabled(c)) {  // spin-wait for work
  104604:	eb 07                	jmp    10460d <proc_sched+0x31>
// Enable external device interrupts.
static gcc_inline void
sti(void)
{
	asm volatile("sti");
  104606:	fb                   	sti    
      sti(); // enable device interrupts briefly
      pause(); // let CPU know we're in a spin loop
  104607:	e8 ad 00 00 00       	call   1046b9 <pause>
// Disable external device interrupts.
static gcc_inline void
cli(void)
{
	asm volatile("cli");
  10460c:	fa                   	cli    
  10460d:	a1 78 aa 17 00       	mov    0x17aa78,%eax
  104612:	85 c0                	test   %eax,%eax
  104614:	74 f0                	je     104606 <proc_sched+0x2a>
      cli(); // disable interrupts again
    }
    //cprintf("cpu %d found work\n", cpu_cur()->id);

    spinlock_acquire(&readylock);
  104616:	c7 04 24 40 aa 17 00 	movl   $0x17aa40,(%esp)
  10461d:	e8 98 f4 ff ff       	call   103aba <spinlock_acquire>
  104622:	a1 78 aa 17 00       	mov    0x17aa78,%eax
  104627:	85 c0                	test   %eax,%eax
  104629:	74 cd                	je     1045f8 <proc_sched+0x1c>
    // now must recheck readyhead while holding readylock!
  }

  // Remove the next proc from the ready queue
  proc *p = readyhead;
  10462b:	a1 78 aa 17 00       	mov    0x17aa78,%eax
  104630:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  readyhead = p->readynext;
  104633:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  104636:	8b 80 40 04 00 00    	mov    0x440(%eax),%eax
  10463c:	a3 78 aa 17 00       	mov    %eax,0x17aa78
  if (readytail == &p->readynext) {
  104641:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  104644:	81 c2 40 04 00 00    	add    $0x440,%edx
  10464a:	a1 7c aa 17 00       	mov    0x17aa7c,%eax
  10464f:	39 c2                	cmp    %eax,%edx
  104651:	75 37                	jne    10468a <proc_sched+0xae>
    assert(readyhead == NULL); // ready queue going empty
  104653:	a1 78 aa 17 00       	mov    0x17aa78,%eax
  104658:	85 c0                	test   %eax,%eax
  10465a:	74 24                	je     104680 <proc_sched+0xa4>
  10465c:	c7 44 24 0c 62 cb 10 	movl   $0x10cb62,0xc(%esp)
  104663:	00 
  104664:	c7 44 24 08 56 ca 10 	movl   $0x10ca56,0x8(%esp)
  10466b:	00 
  10466c:	c7 44 24 04 9d 00 00 	movl   $0x9d,0x4(%esp)
  104673:	00 
  104674:	c7 04 24 34 ca 10 00 	movl   $0x10ca34,(%esp)
  10467b:	e8 e8 c2 ff ff       	call   100968 <debug_panic>
    readytail = &readyhead;
  104680:	c7 05 7c aa 17 00 78 	movl   $0x17aa78,0x17aa7c
  104687:	aa 17 00 
  }
  p->readynext = NULL;
  10468a:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  10468d:	c7 80 40 04 00 00 00 	movl   $0x0,0x440(%eax)
  104694:	00 00 00 

  spinlock_acquire(&p->lock);
  104697:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  10469a:	89 04 24             	mov    %eax,(%esp)
  10469d:	e8 18 f4 ff ff       	call   103aba <spinlock_acquire>
  spinlock_release(&readylock);
  1046a2:	c7 04 24 40 aa 17 00 	movl   $0x17aa40,(%esp)
  1046a9:	e8 07 f5 ff ff       	call   103bb5 <spinlock_release>

  proc_run(p);
  1046ae:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  1046b1:	89 04 24             	mov    %eax,(%esp)
  1046b4:	e8 07 00 00 00       	call   1046c0 <proc_run>

001046b9 <pause>:
}

static inline void
pause(void)
{
  1046b9:	55                   	push   %ebp
  1046ba:	89 e5                	mov    %esp,%ebp
	asm volatile("pause" : : : "memory");
  1046bc:	f3 90                	pause  
}
  1046be:	5d                   	pop    %ebp
  1046bf:	c3                   	ret    

001046c0 <proc_run>:
}	

void gcc_noreturn
proc_run(proc *p)
{
  1046c0:	55                   	push   %ebp
  1046c1:	89 e5                	mov    %esp,%ebp
  1046c3:	83 ec 28             	sub    $0x28,%esp
	//panic("proc_run not implemented");
  assert(spinlock_holding(&p->lock));
  1046c6:	8b 45 08             	mov    0x8(%ebp),%eax
  1046c9:	89 04 24             	mov    %eax,(%esp)
  1046cc:	e8 3e f5 ff ff       	call   103c0f <spinlock_holding>
  1046d1:	85 c0                	test   %eax,%eax
  1046d3:	75 24                	jne    1046f9 <proc_run+0x39>
  1046d5:	c7 44 24 0c 19 cb 10 	movl   $0x10cb19,0xc(%esp)
  1046dc:	00 
  1046dd:	c7 44 24 08 56 ca 10 	movl   $0x10ca56,0x8(%esp)
  1046e4:	00 
  1046e5:	c7 44 24 04 ac 00 00 	movl   $0xac,0x4(%esp)
  1046ec:	00 
  1046ed:	c7 04 24 34 ca 10 00 	movl   $0x10ca34,(%esp)
  1046f4:	e8 6f c2 ff ff       	call   100968 <debug_panic>

  cpu *c = cpu_cur();
  1046f9:	e8 7d fa ff ff       	call   10417b <cpu_cur>
  1046fe:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  p->state = PROC_RUN;
  104701:	8b 45 08             	mov    0x8(%ebp),%eax
  104704:	c7 80 3c 04 00 00 02 	movl   $0x2,0x43c(%eax)
  10470b:	00 00 00 
  p->runcpu = c;
  10470e:	8b 55 08             	mov    0x8(%ebp),%edx
  104711:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  104714:	89 82 44 04 00 00    	mov    %eax,0x444(%edx)
  c->proc = p;
  10471a:	8b 55 f8             	mov    0xfffffff8(%ebp),%edx
  10471d:	8b 45 08             	mov    0x8(%ebp),%eax
  104720:	89 82 b4 00 00 00    	mov    %eax,0xb4(%edx)

  spinlock_release(&p->lock);
  104726:	8b 45 08             	mov    0x8(%ebp),%eax
  104729:	89 04 24             	mov    %eax,(%esp)
  10472c:	e8 84 f4 ff ff       	call   103bb5 <spinlock_release>

  lcr3(mem_phys(p->pdir));
  104731:	8b 45 08             	mov    0x8(%ebp),%eax
  104734:	8b 80 a0 06 00 00    	mov    0x6a0(%eax),%eax
  10473a:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)

static gcc_inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
  10473d:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  104740:	0f 22 d8             	mov    %eax,%cr3
  trap_return(&p->sv.tf);
  104743:	8b 45 08             	mov    0x8(%ebp),%eax
  104746:	05 50 04 00 00       	add    $0x450,%eax
  10474b:	89 04 24             	mov    %eax,(%esp)
  10474e:	e8 0d ef ff ff       	call   103660 <trap_return>

00104753 <proc_yield>:
}

// Yield the current CPU to another ready process.
// Called while handling a timer interrupt.
void gcc_noreturn
proc_yield(trapframe *tf)
{
  104753:	55                   	push   %ebp
  104754:	89 e5                	mov    %esp,%ebp
  104756:	53                   	push   %ebx
  104757:	83 ec 24             	sub    $0x24,%esp
//	panic("proc_yield not implemented");
    proc *p = proc_cur();
  10475a:	e8 1c fa ff ff       	call   10417b <cpu_cur>
  10475f:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  104765:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
    assert(p->runcpu == cpu_cur());
  104768:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10476b:	8b 98 44 04 00 00    	mov    0x444(%eax),%ebx
  104771:	e8 05 fa ff ff       	call   10417b <cpu_cur>
  104776:	39 c3                	cmp    %eax,%ebx
  104778:	74 24                	je     10479e <proc_yield+0x4b>
  10477a:	c7 44 24 0c 74 cb 10 	movl   $0x10cb74,0xc(%esp)
  104781:	00 
  104782:	c7 44 24 08 56 ca 10 	movl   $0x10ca56,0x8(%esp)
  104789:	00 
  10478a:	c7 44 24 04 c0 00 00 	movl   $0xc0,0x4(%esp)
  104791:	00 
  104792:	c7 04 24 34 ca 10 00 	movl   $0x10ca34,(%esp)
  104799:	e8 ca c1 ff ff       	call   100968 <debug_panic>
    p->runcpu = NULL; // this process no longer running
  10479e:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1047a1:	c7 80 44 04 00 00 00 	movl   $0x0,0x444(%eax)
  1047a8:	00 00 00 
    proc_save(p, tf, -1); // save this process's state
  1047ab:	c7 44 24 08 ff ff ff 	movl   $0xffffffff,0x8(%esp)
  1047b2:	ff 
  1047b3:	8b 45 08             	mov    0x8(%ebp),%eax
  1047b6:	89 44 24 04          	mov    %eax,0x4(%esp)
  1047ba:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1047bd:	89 04 24             	mov    %eax,(%esp)
  1047c0:	e8 a5 fc ff ff       	call   10446a <proc_save>
    proc_ready(p);  // put it on tail of ready queue
  1047c5:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1047c8:	89 04 24             	mov    %eax,(%esp)
  1047cb:	e8 48 fc ff ff       	call   104418 <proc_ready>

    proc_sched(); // schedule a process from head of ready queue
  1047d0:	e8 07 fe ff ff       	call   1045dc <proc_sched>

001047d5 <proc_ret>:
}

// Put the current process to sleep by "returning" to its parent process.
// Used both when a process calls the SYS_RET system call explicitly,
// and when a process causes an unhandled trap in user mode.
// The 'entry' parameter is as in proc_save().
void gcc_noreturn
proc_ret(trapframe *tf, int entry)
{
  1047d5:	55                   	push   %ebp
  1047d6:	89 e5                	mov    %esp,%ebp
  1047d8:	53                   	push   %ebx
  1047d9:	83 ec 24             	sub    $0x24,%esp

  proc *cp = proc_cur();  // we're the child
  1047dc:	e8 9a f9 ff ff       	call   10417b <cpu_cur>
  1047e1:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  1047e7:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
  assert(cp->state == PROC_RUN && cp->runcpu == cpu_cur());
  1047ea:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  1047ed:	8b 80 3c 04 00 00    	mov    0x43c(%eax),%eax
  1047f3:	83 f8 02             	cmp    $0x2,%eax
  1047f6:	75 12                	jne    10480a <proc_ret+0x35>
  1047f8:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  1047fb:	8b 98 44 04 00 00    	mov    0x444(%eax),%ebx
  104801:	e8 75 f9 ff ff       	call   10417b <cpu_cur>
  104806:	39 c3                	cmp    %eax,%ebx
  104808:	74 24                	je     10482e <proc_ret+0x59>
  10480a:	c7 44 24 0c 8c cb 10 	movl   $0x10cb8c,0xc(%esp)
  104811:	00 
  104812:	c7 44 24 08 56 ca 10 	movl   $0x10ca56,0x8(%esp)
  104819:	00 
  10481a:	c7 44 24 04 d1 00 00 	movl   $0xd1,0x4(%esp)
  104821:	00 
  104822:	c7 04 24 34 ca 10 00 	movl   $0x10ca34,(%esp)
  104829:	e8 3a c1 ff ff       	call   100968 <debug_panic>

  proc *p = cp->parent;  // find our parent
  10482e:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  104831:	8b 40 38             	mov    0x38(%eax),%eax
  104834:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  if (p == NULL) { // "return" from root process!
  104837:	83 7d f8 00          	cmpl   $0x0,0xfffffff8(%ebp)
  10483b:	75 67                	jne    1048a4 <proc_ret+0xcf>
    if (tf->trapno != T_SYSCALL) {
  10483d:	8b 45 08             	mov    0x8(%ebp),%eax
  104840:	8b 40 30             	mov    0x30(%eax),%eax
  104843:	83 f8 30             	cmp    $0x30,%eax
  104846:	74 27                	je     10486f <proc_ret+0x9a>
      trap_print(tf);
  104848:	8b 45 08             	mov    0x8(%ebp),%eax
  10484b:	89 04 24             	mov    %eax,(%esp)
  10484e:	e8 73 e5 ff ff       	call   102dc6 <trap_print>
      panic("trap in root process");
  104853:	c7 44 24 08 bd cb 10 	movl   $0x10cbbd,0x8(%esp)
  10485a:	00 
  10485b:	c7 44 24 04 d7 00 00 	movl   $0xd7,0x4(%esp)
  104862:	00 
  104863:	c7 04 24 34 ca 10 00 	movl   $0x10ca34,(%esp)
  10486a:	e8 f9 c0 ff ff       	call   100968 <debug_panic>
    }
		assert(entry == 1);
  10486f:	83 7d 0c 01          	cmpl   $0x1,0xc(%ebp)
  104873:	74 24                	je     104899 <proc_ret+0xc4>
  104875:	c7 44 24 0c d2 cb 10 	movl   $0x10cbd2,0xc(%esp)
  10487c:	00 
  10487d:	c7 44 24 08 56 ca 10 	movl   $0x10ca56,0x8(%esp)
  104884:	00 
  104885:	c7 44 24 04 d9 00 00 	movl   $0xd9,0x4(%esp)
  10488c:	00 
  10488d:	c7 04 24 34 ca 10 00 	movl   $0x10ca34,(%esp)
  104894:	e8 cf c0 ff ff       	call   100968 <debug_panic>
		file_io(tf);
  104899:	8b 45 08             	mov    0x8(%ebp),%eax
  10489c:	89 04 24             	mov    %eax,(%esp)
  10489f:	e8 8d 54 00 00       	call   109d31 <file_io>
  }

  spinlock_acquire(&p->lock);  // lock both in proper order
  1048a4:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1048a7:	89 04 24             	mov    %eax,(%esp)
  1048aa:	e8 0b f2 ff ff       	call   103aba <spinlock_acquire>

  cp->state = PROC_STOP; // we're becoming stopped
  1048af:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  1048b2:	c7 80 3c 04 00 00 00 	movl   $0x0,0x43c(%eax)
  1048b9:	00 00 00 
  cp->runcpu = NULL; // no longer running
  1048bc:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  1048bf:	c7 80 44 04 00 00 00 	movl   $0x0,0x444(%eax)
  1048c6:	00 00 00 
  proc_save(cp, tf, entry);  // save process state after INT insn
  1048c9:	8b 45 0c             	mov    0xc(%ebp),%eax
  1048cc:	89 44 24 08          	mov    %eax,0x8(%esp)
  1048d0:	8b 45 08             	mov    0x8(%ebp),%eax
  1048d3:	89 44 24 04          	mov    %eax,0x4(%esp)
  1048d7:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  1048da:	89 04 24             	mov    %eax,(%esp)
  1048dd:	e8 88 fb ff ff       	call   10446a <proc_save>

  // If parent is waiting to sync with us, wake it up.
  if (p->state == PROC_WAIT && p->waitchild == cp) {
  1048e2:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1048e5:	8b 80 3c 04 00 00    	mov    0x43c(%eax),%eax
  1048eb:	83 f8 03             	cmp    $0x3,%eax
  1048ee:	75 26                	jne    104916 <proc_ret+0x141>
  1048f0:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1048f3:	8b 80 48 04 00 00    	mov    0x448(%eax),%eax
  1048f9:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  1048fc:	75 18                	jne    104916 <proc_ret+0x141>
    p->waitchild = NULL;
  1048fe:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  104901:	c7 80 48 04 00 00 00 	movl   $0x0,0x448(%eax)
  104908:	00 00 00 
    proc_run(p);
  10490b:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10490e:	89 04 24             	mov    %eax,(%esp)
  104911:	e8 aa fd ff ff       	call   1046c0 <proc_run>
  }

  spinlock_release(&p->lock);
  104916:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  104919:	89 04 24             	mov    %eax,(%esp)
  10491c:	e8 94 f2 ff ff       	call   103bb5 <spinlock_release>
  proc_sched();  // find and run someone else
  104921:	e8 b6 fc ff ff       	call   1045dc <proc_sched>

00104926 <proc_check>:
}
// Helper functions for proc_check()
static void child(int n);
static void grandchild(int n);

static struct procstate child_state;
static char gcc_aligned(16) child_stack[4][PAGESIZE];

static volatile uint32_t pingpong = 0;
static void *recovargs;
//we might have some merge conflicts here...
void
proc_check(void)
{
  104926:	55                   	push   %ebp
  104927:	89 e5                	mov    %esp,%ebp
  104929:	57                   	push   %edi
  10492a:	56                   	push   %esi
  10492b:	53                   	push   %ebx
  10492c:	81 ec dc 00 00 00    	sub    $0xdc,%esp
	// Spawn 2 child processes, executing on statically allocated stacks.

	int i;
	for (i = 0; i < 4; i++) {
  104932:	c7 85 40 ff ff ff 00 	movl   $0x0,0xffffff40(%ebp)
  104939:	00 00 00 
  10493c:	e9 12 01 00 00       	jmp    104a53 <proc_check+0x12d>
		// Setup register state for child
		uint32_t *esp = (uint32_t*) &child_stack[i][PAGESIZE];
  104941:	8b 85 40 ff ff ff    	mov    0xffffff40(%ebp),%eax
  104947:	c1 e0 0c             	shl    $0xc,%eax
  10494a:	89 c2                	mov    %eax,%edx
  10494c:	b8 d0 ac 17 00       	mov    $0x17acd0,%eax
  104951:	05 00 10 00 00       	add    $0x1000,%eax
  104956:	8d 04 02             	lea    (%edx,%eax,1),%eax
  104959:	89 85 44 ff ff ff    	mov    %eax,0xffffff44(%ebp)
		*--esp = i;	// push argument to child() function
  10495f:	83 ad 44 ff ff ff 04 	subl   $0x4,0xffffff44(%ebp)
  104966:	8b 95 40 ff ff ff    	mov    0xffffff40(%ebp),%edx
  10496c:	8b 85 44 ff ff ff    	mov    0xffffff44(%ebp),%eax
  104972:	89 10                	mov    %edx,(%eax)
		*--esp = 0;	// fake return address
  104974:	83 ad 44 ff ff ff 04 	subl   $0x4,0xffffff44(%ebp)
  10497b:	8b 85 44 ff ff ff    	mov    0xffffff44(%ebp),%eax
  104981:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		child_state.tf.eip = (uint32_t) child;
  104987:	b8 11 4e 10 00       	mov    $0x104e11,%eax
  10498c:	a3 b8 aa 17 00       	mov    %eax,0x17aab8
		child_state.tf.esp = (uint32_t) esp;
  104991:	8b 85 44 ff ff ff    	mov    0xffffff44(%ebp),%eax
  104997:	a3 c4 aa 17 00       	mov    %eax,0x17aac4

		// Use PUT syscall to create each child,
		// but only start the first 2 children for now.
		cprintf("spawning child %d\n", i);
  10499c:	8b 85 40 ff ff ff    	mov    0xffffff40(%ebp),%eax
  1049a2:	89 44 24 04          	mov    %eax,0x4(%esp)
  1049a6:	c7 04 24 dd cb 10 00 	movl   $0x10cbdd,(%esp)
  1049ad:	e8 bf 6a 00 00       	call   10b471 <cprintf>
		sys_put(SYS_REGS | (i < 2 ? SYS_START : 0), i, &child_state,
  1049b2:	8b 85 40 ff ff ff    	mov    0xffffff40(%ebp),%eax
  1049b8:	0f b7 c0             	movzwl %ax,%eax
  1049bb:	89 85 2c ff ff ff    	mov    %eax,0xffffff2c(%ebp)
  1049c1:	83 bd 40 ff ff ff 01 	cmpl   $0x1,0xffffff40(%ebp)
  1049c8:	7f 0c                	jg     1049d6 <proc_check+0xb0>
  1049ca:	c7 85 30 ff ff ff 10 	movl   $0x1010,0xffffff30(%ebp)
  1049d1:	10 00 00 
  1049d4:	eb 0a                	jmp    1049e0 <proc_check+0xba>
  1049d6:	c7 85 30 ff ff ff 00 	movl   $0x1000,0xffffff30(%ebp)
  1049dd:	10 00 00 
  1049e0:	8b 85 30 ff ff ff    	mov    0xffffff30(%ebp),%eax
  1049e6:	89 85 60 ff ff ff    	mov    %eax,0xffffff60(%ebp)
  1049ec:	0f b7 85 2c ff ff ff 	movzwl 0xffffff2c(%ebp),%eax
  1049f3:	66 89 85 5e ff ff ff 	mov    %ax,0xffffff5e(%ebp)
  1049fa:	c7 85 58 ff ff ff 80 	movl   $0x17aa80,0xffffff58(%ebp)
  104a01:	aa 17 00 
  104a04:	c7 85 54 ff ff ff 00 	movl   $0x0,0xffffff54(%ebp)
  104a0b:	00 00 00 
  104a0e:	c7 85 50 ff ff ff 00 	movl   $0x0,0xffffff50(%ebp)
  104a15:	00 00 00 
  104a18:	c7 85 4c ff ff ff 00 	movl   $0x0,0xffffff4c(%ebp)
  104a1f:	00 00 00 
static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
  104a22:	8b 85 60 ff ff ff    	mov    0xffffff60(%ebp),%eax
  104a28:	83 c8 01             	or     $0x1,%eax
  104a2b:	8b 9d 58 ff ff ff    	mov    0xffffff58(%ebp),%ebx
  104a31:	0f b7 95 5e ff ff ff 	movzwl 0xffffff5e(%ebp),%edx
  104a38:	8b b5 54 ff ff ff    	mov    0xffffff54(%ebp),%esi
  104a3e:	8b bd 50 ff ff ff    	mov    0xffffff50(%ebp),%edi
  104a44:	8b 8d 4c ff ff ff    	mov    0xffffff4c(%ebp),%ecx
  104a4a:	cd 30                	int    $0x30
  104a4c:	83 85 40 ff ff ff 01 	addl   $0x1,0xffffff40(%ebp)
  104a53:	83 bd 40 ff ff ff 03 	cmpl   $0x3,0xffffff40(%ebp)
  104a5a:	0f 8e e1 fe ff ff    	jle    104941 <proc_check+0x1b>
			NULL, NULL, 0);
	}

	// Wait for both children to complete.
	// This should complete without preemptive scheduling
	// when we're running on a 2-processor machine.
	for (i = 0; i < 2; i++) {
  104a60:	c7 85 40 ff ff ff 00 	movl   $0x0,0xffffff40(%ebp)
  104a67:	00 00 00 
  104a6a:	e9 89 00 00 00       	jmp    104af8 <proc_check+0x1d2>
		cprintf("waiting for child %d\n", i);
  104a6f:	8b 85 40 ff ff ff    	mov    0xffffff40(%ebp),%eax
  104a75:	89 44 24 04          	mov    %eax,0x4(%esp)
  104a79:	c7 04 24 f0 cb 10 00 	movl   $0x10cbf0,(%esp)
  104a80:	e8 ec 69 00 00       	call   10b471 <cprintf>
		sys_get(SYS_REGS, i, &child_state, NULL, NULL, 0);
  104a85:	8b 85 40 ff ff ff    	mov    0xffffff40(%ebp),%eax
  104a8b:	0f b7 c0             	movzwl %ax,%eax
  104a8e:	c7 85 78 ff ff ff 00 	movl   $0x1000,0xffffff78(%ebp)
  104a95:	10 00 00 
  104a98:	66 89 85 76 ff ff ff 	mov    %ax,0xffffff76(%ebp)
  104a9f:	c7 85 70 ff ff ff 80 	movl   $0x17aa80,0xffffff70(%ebp)
  104aa6:	aa 17 00 
  104aa9:	c7 85 6c ff ff ff 00 	movl   $0x0,0xffffff6c(%ebp)
  104ab0:	00 00 00 
  104ab3:	c7 85 68 ff ff ff 00 	movl   $0x0,0xffffff68(%ebp)
  104aba:	00 00 00 
  104abd:	c7 85 64 ff ff ff 00 	movl   $0x0,0xffffff64(%ebp)
  104ac4:	00 00 00 
static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
  104ac7:	8b 85 78 ff ff ff    	mov    0xffffff78(%ebp),%eax
  104acd:	83 c8 02             	or     $0x2,%eax
  104ad0:	8b 9d 70 ff ff ff    	mov    0xffffff70(%ebp),%ebx
  104ad6:	0f b7 95 76 ff ff ff 	movzwl 0xffffff76(%ebp),%edx
  104add:	8b b5 6c ff ff ff    	mov    0xffffff6c(%ebp),%esi
  104ae3:	8b bd 68 ff ff ff    	mov    0xffffff68(%ebp),%edi
  104ae9:	8b 8d 64 ff ff ff    	mov    0xffffff64(%ebp),%ecx
  104aef:	cd 30                	int    $0x30
  104af1:	83 85 40 ff ff ff 01 	addl   $0x1,0xffffff40(%ebp)
  104af8:	83 bd 40 ff ff ff 01 	cmpl   $0x1,0xffffff40(%ebp)
  104aff:	0f 8e 6a ff ff ff    	jle    104a6f <proc_check+0x149>
	}
	cprintf("proc_check() 2-child test succeeded\n");
  104b05:	c7 04 24 08 cc 10 00 	movl   $0x10cc08,(%esp)
  104b0c:	e8 60 69 00 00       	call   10b471 <cprintf>

	// (Re)start all four children, and wait for them.
	// This will require preemptive scheduling to complete
	// if we have less than 4 CPUs.
	cprintf("proc_check: spawning 4 children\n");
  104b11:	c7 04 24 30 cc 10 00 	movl   $0x10cc30,(%esp)
  104b18:	e8 54 69 00 00       	call   10b471 <cprintf>
	for (i = 0; i < 4; i++) {
  104b1d:	c7 85 40 ff ff ff 00 	movl   $0x0,0xffffff40(%ebp)
  104b24:	00 00 00 
  104b27:	eb 6b                	jmp    104b94 <proc_check+0x26e>
		cprintf("spawning child %d\n", i);
  104b29:	8b 85 40 ff ff ff    	mov    0xffffff40(%ebp),%eax
  104b2f:	89 44 24 04          	mov    %eax,0x4(%esp)
  104b33:	c7 04 24 dd cb 10 00 	movl   $0x10cbdd,(%esp)
  104b3a:	e8 32 69 00 00       	call   10b471 <cprintf>
		sys_put(SYS_START, i, NULL, NULL, NULL, 0);
  104b3f:	8b 85 40 ff ff ff    	mov    0xffffff40(%ebp),%eax
  104b45:	0f b7 c0             	movzwl %ax,%eax
  104b48:	c7 45 90 10 00 00 00 	movl   $0x10,0xffffff90(%ebp)
  104b4f:	66 89 45 8e          	mov    %ax,0xffffff8e(%ebp)
  104b53:	c7 45 88 00 00 00 00 	movl   $0x0,0xffffff88(%ebp)
  104b5a:	c7 45 84 00 00 00 00 	movl   $0x0,0xffffff84(%ebp)
  104b61:	c7 45 80 00 00 00 00 	movl   $0x0,0xffffff80(%ebp)
  104b68:	c7 85 7c ff ff ff 00 	movl   $0x0,0xffffff7c(%ebp)
  104b6f:	00 00 00 
static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
  104b72:	8b 45 90             	mov    0xffffff90(%ebp),%eax
  104b75:	83 c8 01             	or     $0x1,%eax
  104b78:	8b 5d 88             	mov    0xffffff88(%ebp),%ebx
  104b7b:	0f b7 55 8e          	movzwl 0xffffff8e(%ebp),%edx
  104b7f:	8b 75 84             	mov    0xffffff84(%ebp),%esi
  104b82:	8b 7d 80             	mov    0xffffff80(%ebp),%edi
  104b85:	8b 8d 7c ff ff ff    	mov    0xffffff7c(%ebp),%ecx
  104b8b:	cd 30                	int    $0x30
  104b8d:	83 85 40 ff ff ff 01 	addl   $0x1,0xffffff40(%ebp)
  104b94:	83 bd 40 ff ff ff 03 	cmpl   $0x3,0xffffff40(%ebp)
  104b9b:	7e 8c                	jle    104b29 <proc_check+0x203>
	}

	// Wait for all 4 children to complete.
	for (i = 0; i < 4; i++)
  104b9d:	c7 85 40 ff ff ff 00 	movl   $0x0,0xffffff40(%ebp)
  104ba4:	00 00 00 
  104ba7:	eb 4f                	jmp    104bf8 <proc_check+0x2d2>
		sys_get(0, i, NULL, NULL, NULL, 0);
  104ba9:	8b 85 40 ff ff ff    	mov    0xffffff40(%ebp),%eax
  104baf:	0f b7 c0             	movzwl %ax,%eax
  104bb2:	c7 45 a8 00 00 00 00 	movl   $0x0,0xffffffa8(%ebp)
  104bb9:	66 89 45 a6          	mov    %ax,0xffffffa6(%ebp)
  104bbd:	c7 45 a0 00 00 00 00 	movl   $0x0,0xffffffa0(%ebp)
  104bc4:	c7 45 9c 00 00 00 00 	movl   $0x0,0xffffff9c(%ebp)
  104bcb:	c7 45 98 00 00 00 00 	movl   $0x0,0xffffff98(%ebp)
  104bd2:	c7 45 94 00 00 00 00 	movl   $0x0,0xffffff94(%ebp)
static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
  104bd9:	8b 45 a8             	mov    0xffffffa8(%ebp),%eax
  104bdc:	83 c8 02             	or     $0x2,%eax
  104bdf:	8b 5d a0             	mov    0xffffffa0(%ebp),%ebx
  104be2:	0f b7 55 a6          	movzwl 0xffffffa6(%ebp),%edx
  104be6:	8b 75 9c             	mov    0xffffff9c(%ebp),%esi
  104be9:	8b 7d 98             	mov    0xffffff98(%ebp),%edi
  104bec:	8b 4d 94             	mov    0xffffff94(%ebp),%ecx
  104bef:	cd 30                	int    $0x30
  104bf1:	83 85 40 ff ff ff 01 	addl   $0x1,0xffffff40(%ebp)
  104bf8:	83 bd 40 ff ff ff 03 	cmpl   $0x3,0xffffff40(%ebp)
  104bff:	7e a8                	jle    104ba9 <proc_check+0x283>
	cprintf("proc_check() 4-child test succeeded\n");
  104c01:	c7 04 24 54 cc 10 00 	movl   $0x10cc54,(%esp)
  104c08:	e8 64 68 00 00       	call   10b471 <cprintf>

	// Now do a trap handling test using all 4 children -
	// but they'll _think_ they're all child 0!
	// (We'll lose the register state of the other children.)
	i = 0;
  104c0d:	c7 85 40 ff ff ff 00 	movl   $0x0,0xffffff40(%ebp)
  104c14:	00 00 00 
	sys_get(SYS_REGS, i, &child_state, NULL, NULL, 0);
  104c17:	8b 85 40 ff ff ff    	mov    0xffffff40(%ebp),%eax
  104c1d:	0f b7 c0             	movzwl %ax,%eax
  104c20:	c7 45 c0 00 10 00 00 	movl   $0x1000,0xffffffc0(%ebp)
  104c27:	66 89 45 be          	mov    %ax,0xffffffbe(%ebp)
  104c2b:	c7 45 b8 80 aa 17 00 	movl   $0x17aa80,0xffffffb8(%ebp)
  104c32:	c7 45 b4 00 00 00 00 	movl   $0x0,0xffffffb4(%ebp)
  104c39:	c7 45 b0 00 00 00 00 	movl   $0x0,0xffffffb0(%ebp)
  104c40:	c7 45 ac 00 00 00 00 	movl   $0x0,0xffffffac(%ebp)
static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
  104c47:	8b 45 c0             	mov    0xffffffc0(%ebp),%eax
  104c4a:	83 c8 02             	or     $0x2,%eax
  104c4d:	8b 5d b8             	mov    0xffffffb8(%ebp),%ebx
  104c50:	0f b7 55 be          	movzwl 0xffffffbe(%ebp),%edx
  104c54:	8b 75 b4             	mov    0xffffffb4(%ebp),%esi
  104c57:	8b 7d b0             	mov    0xffffffb0(%ebp),%edi
  104c5a:	8b 4d ac             	mov    0xffffffac(%ebp),%ecx
  104c5d:	cd 30                	int    $0x30
		// get child 0's state
	assert(recovargs == NULL);
  104c5f:	a1 d0 ec 17 00       	mov    0x17ecd0,%eax
  104c64:	85 c0                	test   %eax,%eax
  104c66:	74 24                	je     104c8c <proc_check+0x366>
  104c68:	c7 44 24 0c 79 cc 10 	movl   $0x10cc79,0xc(%esp)
  104c6f:	00 
  104c70:	c7 44 24 08 56 ca 10 	movl   $0x10ca56,0x8(%esp)
  104c77:	00 
  104c78:	c7 44 24 04 28 01 00 	movl   $0x128,0x4(%esp)
  104c7f:	00 
  104c80:	c7 04 24 34 ca 10 00 	movl   $0x10ca34,(%esp)
  104c87:	e8 dc bc ff ff       	call   100968 <debug_panic>
	do {
		sys_put(SYS_REGS | SYS_START, i, &child_state, NULL, NULL, 0);
  104c8c:	8b 85 40 ff ff ff    	mov    0xffffff40(%ebp),%eax
  104c92:	0f b7 c0             	movzwl %ax,%eax
  104c95:	c7 45 d8 10 10 00 00 	movl   $0x1010,0xffffffd8(%ebp)
  104c9c:	66 89 45 d6          	mov    %ax,0xffffffd6(%ebp)
  104ca0:	c7 45 d0 80 aa 17 00 	movl   $0x17aa80,0xffffffd0(%ebp)
  104ca7:	c7 45 cc 00 00 00 00 	movl   $0x0,0xffffffcc(%ebp)
  104cae:	c7 45 c8 00 00 00 00 	movl   $0x0,0xffffffc8(%ebp)
  104cb5:	c7 45 c4 00 00 00 00 	movl   $0x0,0xffffffc4(%ebp)
static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
  104cbc:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  104cbf:	83 c8 01             	or     $0x1,%eax
  104cc2:	8b 5d d0             	mov    0xffffffd0(%ebp),%ebx
  104cc5:	0f b7 55 d6          	movzwl 0xffffffd6(%ebp),%edx
  104cc9:	8b 75 cc             	mov    0xffffffcc(%ebp),%esi
  104ccc:	8b 7d c8             	mov    0xffffffc8(%ebp),%edi
  104ccf:	8b 4d c4             	mov    0xffffffc4(%ebp),%ecx
  104cd2:	cd 30                	int    $0x30
		sys_get(SYS_REGS, i, &child_state, NULL, NULL, 0);
  104cd4:	8b 85 40 ff ff ff    	mov    0xffffff40(%ebp),%eax
  104cda:	0f b7 c0             	movzwl %ax,%eax
  104cdd:	c7 45 f0 00 10 00 00 	movl   $0x1000,0xfffffff0(%ebp)
  104ce4:	66 89 45 ee          	mov    %ax,0xffffffee(%ebp)
  104ce8:	c7 45 e8 80 aa 17 00 	movl   $0x17aa80,0xffffffe8(%ebp)
  104cef:	c7 45 e4 00 00 00 00 	movl   $0x0,0xffffffe4(%ebp)
  104cf6:	c7 45 e0 00 00 00 00 	movl   $0x0,0xffffffe0(%ebp)
  104cfd:	c7 45 dc 00 00 00 00 	movl   $0x0,0xffffffdc(%ebp)
static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
  104d04:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  104d07:	83 c8 02             	or     $0x2,%eax
  104d0a:	8b 5d e8             	mov    0xffffffe8(%ebp),%ebx
  104d0d:	0f b7 55 ee          	movzwl 0xffffffee(%ebp),%edx
  104d11:	8b 75 e4             	mov    0xffffffe4(%ebp),%esi
  104d14:	8b 7d e0             	mov    0xffffffe0(%ebp),%edi
  104d17:	8b 4d dc             	mov    0xffffffdc(%ebp),%ecx
  104d1a:	cd 30                	int    $0x30
		if (recovargs) {	// trap recovery needed
  104d1c:	a1 d0 ec 17 00       	mov    0x17ecd0,%eax
  104d21:	85 c0                	test   %eax,%eax
  104d23:	74 3f                	je     104d64 <proc_check+0x43e>
			trap_check_args *args = recovargs;
  104d25:	a1 d0 ec 17 00       	mov    0x17ecd0,%eax
  104d2a:	89 85 48 ff ff ff    	mov    %eax,0xffffff48(%ebp)
			cprintf("recover from trap %d\n",
  104d30:	a1 b0 aa 17 00       	mov    0x17aab0,%eax
  104d35:	89 44 24 04          	mov    %eax,0x4(%esp)
  104d39:	c7 04 24 8b cc 10 00 	movl   $0x10cc8b,(%esp)
  104d40:	e8 2c 67 00 00       	call   10b471 <cprintf>
				child_state.tf.trapno);
			child_state.tf.eip = (uint32_t) args->reip;
  104d45:	8b 85 48 ff ff ff    	mov    0xffffff48(%ebp),%eax
  104d4b:	8b 00                	mov    (%eax),%eax
  104d4d:	a3 b8 aa 17 00       	mov    %eax,0x17aab8
			args->trapno = child_state.tf.trapno;
  104d52:	a1 b0 aa 17 00       	mov    0x17aab0,%eax
  104d57:	89 c2                	mov    %eax,%edx
  104d59:	8b 85 48 ff ff ff    	mov    0xffffff48(%ebp),%eax
  104d5f:	89 50 04             	mov    %edx,0x4(%eax)
  104d62:	eb 2e                	jmp    104d92 <proc_check+0x46c>
		} else
			assert(child_state.tf.trapno == T_SYSCALL);
  104d64:	a1 b0 aa 17 00       	mov    0x17aab0,%eax
  104d69:	83 f8 30             	cmp    $0x30,%eax
  104d6c:	74 24                	je     104d92 <proc_check+0x46c>
  104d6e:	c7 44 24 0c a4 cc 10 	movl   $0x10cca4,0xc(%esp)
  104d75:	00 
  104d76:	c7 44 24 08 56 ca 10 	movl   $0x10ca56,0x8(%esp)
  104d7d:	00 
  104d7e:	c7 44 24 04 33 01 00 	movl   $0x133,0x4(%esp)
  104d85:	00 
  104d86:	c7 04 24 34 ca 10 00 	movl   $0x10ca34,(%esp)
  104d8d:	e8 d6 bb ff ff       	call   100968 <debug_panic>
		i = (i+1) % 4;	// rotate to next child proc
  104d92:	8b 95 40 ff ff ff    	mov    0xffffff40(%ebp),%edx
  104d98:	83 c2 01             	add    $0x1,%edx
  104d9b:	89 d0                	mov    %edx,%eax
  104d9d:	c1 f8 1f             	sar    $0x1f,%eax
  104da0:	89 c1                	mov    %eax,%ecx
  104da2:	c1 e9 1e             	shr    $0x1e,%ecx
  104da5:	8d 04 0a             	lea    (%edx,%ecx,1),%eax
  104da8:	83 e0 03             	and    $0x3,%eax
  104dab:	29 c8                	sub    %ecx,%eax
  104dad:	89 85 40 ff ff ff    	mov    %eax,0xffffff40(%ebp)
	} while (child_state.tf.trapno != T_SYSCALL);
  104db3:	a1 b0 aa 17 00       	mov    0x17aab0,%eax
  104db8:	83 f8 30             	cmp    $0x30,%eax
  104dbb:	0f 85 cb fe ff ff    	jne    104c8c <proc_check+0x366>
	assert(recovargs == NULL);
  104dc1:	a1 d0 ec 17 00       	mov    0x17ecd0,%eax
  104dc6:	85 c0                	test   %eax,%eax
  104dc8:	74 24                	je     104dee <proc_check+0x4c8>
  104dca:	c7 44 24 0c 79 cc 10 	movl   $0x10cc79,0xc(%esp)
  104dd1:	00 
  104dd2:	c7 44 24 08 56 ca 10 	movl   $0x10ca56,0x8(%esp)
  104dd9:	00 
  104dda:	c7 44 24 04 36 01 00 	movl   $0x136,0x4(%esp)
  104de1:	00 
  104de2:	c7 04 24 34 ca 10 00 	movl   $0x10ca34,(%esp)
  104de9:	e8 7a bb ff ff       	call   100968 <debug_panic>

	cprintf("proc_check() trap reflection test succeeded\n");
  104dee:	c7 04 24 c8 cc 10 00 	movl   $0x10ccc8,(%esp)
  104df5:	e8 77 66 00 00       	call   10b471 <cprintf>

	cprintf("proc_check() succeeded!\n");
  104dfa:	c7 04 24 f5 cc 10 00 	movl   $0x10ccf5,(%esp)
  104e01:	e8 6b 66 00 00       	call   10b471 <cprintf>
}
  104e06:	81 c4 dc 00 00 00    	add    $0xdc,%esp
  104e0c:	5b                   	pop    %ebx
  104e0d:	5e                   	pop    %esi
  104e0e:	5f                   	pop    %edi
  104e0f:	5d                   	pop    %ebp
  104e10:	c3                   	ret    

00104e11 <child>:

static void child(int n)
{
  104e11:	55                   	push   %ebp
  104e12:	89 e5                	mov    %esp,%ebp
  104e14:	83 ec 28             	sub    $0x28,%esp
	// Only first 2 children participate in first pingpong test
	if (n < 2) {
  104e17:	83 7d 08 01          	cmpl   $0x1,0x8(%ebp)
  104e1b:	7f 64                	jg     104e81 <child+0x70>
		int i;
		for (i = 0; i < 10; i++) {
  104e1d:	c7 45 fc 00 00 00 00 	movl   $0x0,0xfffffffc(%ebp)
  104e24:	eb 4e                	jmp    104e74 <child+0x63>
			cprintf("in child %d count %d\n", n, i);
  104e26:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  104e29:	89 44 24 08          	mov    %eax,0x8(%esp)
  104e2d:	8b 45 08             	mov    0x8(%ebp),%eax
  104e30:	89 44 24 04          	mov    %eax,0x4(%esp)
  104e34:	c7 04 24 0e cd 10 00 	movl   $0x10cd0e,(%esp)
  104e3b:	e8 31 66 00 00       	call   10b471 <cprintf>
			while (pingpong != n)
  104e40:	eb 05                	jmp    104e47 <child+0x36>
				pause();
  104e42:	e8 72 f8 ff ff       	call   1046b9 <pause>
  104e47:	8b 55 08             	mov    0x8(%ebp),%edx
  104e4a:	a1 20 aa 17 00       	mov    0x17aa20,%eax
  104e4f:	39 c2                	cmp    %eax,%edx
  104e51:	75 ef                	jne    104e42 <child+0x31>
			xchg(&pingpong, !pingpong);
  104e53:	a1 20 aa 17 00       	mov    0x17aa20,%eax
  104e58:	85 c0                	test   %eax,%eax
  104e5a:	0f 94 c0             	sete   %al
  104e5d:	0f b6 c0             	movzbl %al,%eax
  104e60:	89 44 24 04          	mov    %eax,0x4(%esp)
  104e64:	c7 04 24 20 aa 17 00 	movl   $0x17aa20,(%esp)
  104e6b:	e8 02 01 00 00       	call   104f72 <xchg>
  104e70:	83 45 fc 01          	addl   $0x1,0xfffffffc(%ebp)
  104e74:	83 7d fc 09          	cmpl   $0x9,0xfffffffc(%ebp)
  104e78:	7e ac                	jle    104e26 <child+0x15>

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
  104e7a:	b8 03 00 00 00       	mov    $0x3,%eax
  104e7f:	cd 30                	int    $0x30
		}
		sys_ret();
	}

	// Second test, round-robin pingpong between all 4 children
	int i;
	for (i = 0; i < 10; i++) {
  104e81:	c7 45 f8 00 00 00 00 	movl   $0x0,0xfffffff8(%ebp)
  104e88:	eb 4c                	jmp    104ed6 <child+0xc5>
		cprintf("in child %d count %d\n", n, i);
  104e8a:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  104e8d:	89 44 24 08          	mov    %eax,0x8(%esp)
  104e91:	8b 45 08             	mov    0x8(%ebp),%eax
  104e94:	89 44 24 04          	mov    %eax,0x4(%esp)
  104e98:	c7 04 24 0e cd 10 00 	movl   $0x10cd0e,(%esp)
  104e9f:	e8 cd 65 00 00       	call   10b471 <cprintf>
		while (pingpong != n)
  104ea4:	eb 05                	jmp    104eab <child+0x9a>
			pause();
  104ea6:	e8 0e f8 ff ff       	call   1046b9 <pause>
  104eab:	8b 55 08             	mov    0x8(%ebp),%edx
  104eae:	a1 20 aa 17 00       	mov    0x17aa20,%eax
  104eb3:	39 c2                	cmp    %eax,%edx
  104eb5:	75 ef                	jne    104ea6 <child+0x95>
		xchg(&pingpong, (pingpong + 1) % 4);
  104eb7:	a1 20 aa 17 00       	mov    0x17aa20,%eax
  104ebc:	83 c0 01             	add    $0x1,%eax
  104ebf:	83 e0 03             	and    $0x3,%eax
  104ec2:	89 44 24 04          	mov    %eax,0x4(%esp)
  104ec6:	c7 04 24 20 aa 17 00 	movl   $0x17aa20,(%esp)
  104ecd:	e8 a0 00 00 00       	call   104f72 <xchg>
  104ed2:	83 45 f8 01          	addl   $0x1,0xfffffff8(%ebp)
  104ed6:	83 7d f8 09          	cmpl   $0x9,0xfffffff8(%ebp)
  104eda:	7e ae                	jle    104e8a <child+0x79>

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
  104edc:	b8 03 00 00 00       	mov    $0x3,%eax
  104ee1:	cd 30                	int    $0x30
	}
	sys_ret();

	// Only "child 0" (or the proc that thinks it's child 0), trap check...
	if (n == 0) {
  104ee3:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  104ee7:	75 6d                	jne    104f56 <child+0x145>
		assert(recovargs == NULL);
  104ee9:	a1 d0 ec 17 00       	mov    0x17ecd0,%eax
  104eee:	85 c0                	test   %eax,%eax
  104ef0:	74 24                	je     104f16 <child+0x105>
  104ef2:	c7 44 24 0c 79 cc 10 	movl   $0x10cc79,0xc(%esp)
  104ef9:	00 
  104efa:	c7 44 24 08 56 ca 10 	movl   $0x10ca56,0x8(%esp)
  104f01:	00 
  104f02:	c7 44 24 04 57 01 00 	movl   $0x157,0x4(%esp)
  104f09:	00 
  104f0a:	c7 04 24 34 ca 10 00 	movl   $0x10ca34,(%esp)
  104f11:	e8 52 ba ff ff       	call   100968 <debug_panic>
		trap_check(&recovargs);
  104f16:	c7 04 24 d0 ec 17 00 	movl   $0x17ecd0,(%esp)
  104f1d:	e8 70 e3 ff ff       	call   103292 <trap_check>
		assert(recovargs == NULL);
  104f22:	a1 d0 ec 17 00       	mov    0x17ecd0,%eax
  104f27:	85 c0                	test   %eax,%eax
  104f29:	74 24                	je     104f4f <child+0x13e>
  104f2b:	c7 44 24 0c 79 cc 10 	movl   $0x10cc79,0xc(%esp)
  104f32:	00 
  104f33:	c7 44 24 08 56 ca 10 	movl   $0x10ca56,0x8(%esp)
  104f3a:	00 
  104f3b:	c7 44 24 04 59 01 00 	movl   $0x159,0x4(%esp)
  104f42:	00 
  104f43:	c7 04 24 34 ca 10 00 	movl   $0x10ca34,(%esp)
  104f4a:	e8 19 ba ff ff       	call   100968 <debug_panic>

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
  104f4f:	b8 03 00 00 00       	mov    $0x3,%eax
  104f54:	cd 30                	int    $0x30
		sys_ret();
	}

	panic("child(): shouldn't have gotten here");
  104f56:	c7 44 24 08 24 cd 10 	movl   $0x10cd24,0x8(%esp)
  104f5d:	00 
  104f5e:	c7 44 24 04 5d 01 00 	movl   $0x15d,0x4(%esp)
  104f65:	00 
  104f66:	c7 04 24 34 ca 10 00 	movl   $0x10ca34,(%esp)
  104f6d:	e8 f6 b9 ff ff       	call   100968 <debug_panic>

00104f72 <xchg>:

// Atomically set *addr to newval and return the old value of *addr.
static inline uint32_t
xchg(volatile uint32_t *addr, uint32_t newval)
{
  104f72:	55                   	push   %ebp
  104f73:	89 e5                	mov    %esp,%ebp
  104f75:	53                   	push   %ebx
  104f76:	83 ec 14             	sub    $0x14,%esp
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
  104f79:	8b 4d 08             	mov    0x8(%ebp),%ecx
  104f7c:	8b 55 0c             	mov    0xc(%ebp),%edx
  104f7f:	8b 45 08             	mov    0x8(%ebp),%eax
  104f82:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  104f85:	89 d0                	mov    %edx,%eax
  104f87:	8b 5d e8             	mov    0xffffffe8(%ebp),%ebx
  104f8a:	f0 87 01             	lock xchg %eax,(%ecx)
  104f8d:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  104f90:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  104f93:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
	       "+m" (*addr), "=a" (result) :
	       "1" (newval) :
	       "cc");
	return result;
  104f96:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
}
  104f99:	83 c4 14             	add    $0x14,%esp
  104f9c:	5b                   	pop    %ebx
  104f9d:	5d                   	pop    %ebp
  104f9e:	c3                   	ret    

00104f9f <grandchild>:
}

static void grandchild(int n)
{
  104f9f:	55                   	push   %ebp
  104fa0:	89 e5                	mov    %esp,%ebp
  104fa2:	83 ec 18             	sub    $0x18,%esp
	panic("grandchild(): shouldn't have gotten here");
  104fa5:	c7 44 24 08 48 cd 10 	movl   $0x10cd48,0x8(%esp)
  104fac:	00 
  104fad:	c7 44 24 04 62 01 00 	movl   $0x162,0x4(%esp)
  104fb4:	00 
  104fb5:	c7 04 24 34 ca 10 00 	movl   $0x10ca34,(%esp)
  104fbc:	e8 a7 b9 ff ff       	call   100968 <debug_panic>
  104fc1:	90                   	nop    
  104fc2:	90                   	nop    
  104fc3:	90                   	nop    

00104fc4 <systrap>:
// as if the user code's INT 0x30 instruction had caused it -
// and reflect the trap to the parent process as with other traps.
static void gcc_noreturn
systrap(trapframe *utf, int trapno, int err)
{
  104fc4:	55                   	push   %ebp
  104fc5:	89 e5                	mov    %esp,%ebp
  104fc7:	83 ec 08             	sub    $0x8,%esp
	utf->trapno = trapno;
  104fca:	8b 55 0c             	mov    0xc(%ebp),%edx
  104fcd:	8b 45 08             	mov    0x8(%ebp),%eax
  104fd0:	89 50 30             	mov    %edx,0x30(%eax)
	utf->err = err;
  104fd3:	8b 55 10             	mov    0x10(%ebp),%edx
  104fd6:	8b 45 08             	mov    0x8(%ebp),%eax
  104fd9:	89 50 34             	mov    %edx,0x34(%eax)
	proc_ret(utf,0);
  104fdc:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  104fe3:	00 
  104fe4:	8b 45 08             	mov    0x8(%ebp),%eax
  104fe7:	89 04 24             	mov    %eax,(%esp)
  104fea:	e8 e6 f7 ff ff       	call   1047d5 <proc_ret>

00104fef <sysrecover>:
} 



// Recover from a trap that occurs during a copyin or copyout,
// by aborting the system call and reflecting the trap to the parent process,
// behaving as if the user program's INT instruction had caused the trap.
// This uses the 'recover' pointer in the current cpu struct,
// and invokes systrap() above to blame the trap on the user process.
//
// Notes:
// - Be sure the parent gets the correct trapno, err, and eip values.
// - Be sure to release any spinlocks you were holding during the copyin/out.
//
static void gcc_noreturn
sysrecover(trapframe *ktf, void *recoverdata)
{
  104fef:	55                   	push   %ebp
  104ff0:	89 e5                	mov    %esp,%ebp
  104ff2:	83 ec 28             	sub    $0x28,%esp
	trapframe *utf = (trapframe*)recoverdata;
  104ff5:	8b 45 0c             	mov    0xc(%ebp),%eax
  104ff8:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
	cpu *c = cpu_cur();
  104ffb:	e8 65 00 00 00       	call   105065 <cpu_cur>
  105000:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	assert(c->recover == sysrecover);
  105003:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  105006:	8b 80 a0 00 00 00    	mov    0xa0(%eax),%eax
  10500c:	3d ef 4f 10 00       	cmp    $0x104fef,%eax
  105011:	74 24                	je     105037 <sysrecover+0x48>
  105013:	c7 44 24 0c 74 cd 10 	movl   $0x10cd74,0xc(%esp)
  10501a:	00 
  10501b:	c7 44 24 08 8d cd 10 	movl   $0x10cd8d,0x8(%esp)
  105022:	00 
  105023:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
  10502a:	00 
  10502b:	c7 04 24 a2 cd 10 00 	movl   $0x10cda2,(%esp)
  105032:	e8 31 b9 ff ff       	call   100968 <debug_panic>
	c->recover = NULL;
  105037:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  10503a:	c7 80 a0 00 00 00 00 	movl   $0x0,0xa0(%eax)
  105041:	00 00 00 
	systrap(utf, ktf->trapno, ktf->err);
  105044:	8b 45 08             	mov    0x8(%ebp),%eax
  105047:	8b 40 34             	mov    0x34(%eax),%eax
  10504a:	89 c2                	mov    %eax,%edx
  10504c:	8b 45 08             	mov    0x8(%ebp),%eax
  10504f:	8b 40 30             	mov    0x30(%eax),%eax
  105052:	89 54 24 08          	mov    %edx,0x8(%esp)
  105056:	89 44 24 04          	mov    %eax,0x4(%esp)
  10505a:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10505d:	89 04 24             	mov    %eax,(%esp)
  105060:	e8 5f ff ff ff       	call   104fc4 <systrap>

00105065 <cpu_cur>:

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  105065:	55                   	push   %ebp
  105066:	89 e5                	mov    %esp,%ebp
  105068:	83 ec 28             	sub    $0x28,%esp
static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  10506b:	89 65 fc             	mov    %esp,0xfffffffc(%ebp)
        return esp;
  10506e:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  105071:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  105074:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  105077:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  10507c:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	assert(c->magic == CPU_MAGIC);
  10507f:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  105082:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  105088:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  10508d:	74 24                	je     1050b3 <cpu_cur+0x4e>
  10508f:	c7 44 24 0c b1 cd 10 	movl   $0x10cdb1,0xc(%esp)
  105096:	00 
  105097:	c7 44 24 08 8d cd 10 	movl   $0x10cd8d,0x8(%esp)
  10509e:	00 
  10509f:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  1050a6:	00 
  1050a7:	c7 04 24 c7 cd 10 00 	movl   $0x10cdc7,(%esp)
  1050ae:	e8 b5 b8 ff ff       	call   100968 <debug_panic>
	return c;
  1050b3:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
}
  1050b6:	c9                   	leave  
  1050b7:	c3                   	ret    

001050b8 <checkva>:
}

// Check a user virtual address block for validity:
// i.e., make sure the complete area specified lies in
// the user address space between VM_USERLO and VM_USERHI.
// If not, abort the syscall by sending a T_GPFLT to the parent,
// again as if the user program's INT instruction was to blame.
//
// Note: Be careful that your arithmetic works correctly
// even if size is very large, e.g., if uva+size wraps around!
//
static void checkva(trapframe *utf, uint32_t uva, size_t size)
{
  1050b8:	55                   	push   %ebp
  1050b9:	89 e5                	mov    %esp,%ebp
  1050bb:	83 ec 18             	sub    $0x18,%esp
	if(uva < VM_USERLO || uva >= VM_USERHI || size >= VM_USERHI -uva)
  1050be:	81 7d 0c ff ff ff 3f 	cmpl   $0x3fffffff,0xc(%ebp)
  1050c5:	76 16                	jbe    1050dd <checkva+0x25>
  1050c7:	81 7d 0c ff ff ff ef 	cmpl   $0xefffffff,0xc(%ebp)
  1050ce:	77 0d                	ja     1050dd <checkva+0x25>
  1050d0:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
  1050d5:	2b 45 0c             	sub    0xc(%ebp),%eax
  1050d8:	3b 45 10             	cmp    0x10(%ebp),%eax
  1050db:	77 1b                	ja     1050f8 <checkva+0x40>
		systrap(utf, T_PGFLT, 0);
  1050dd:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  1050e4:	00 
  1050e5:	c7 44 24 04 0e 00 00 	movl   $0xe,0x4(%esp)
  1050ec:	00 
  1050ed:	8b 45 08             	mov    0x8(%ebp),%eax
  1050f0:	89 04 24             	mov    %eax,(%esp)
  1050f3:	e8 cc fe ff ff       	call   104fc4 <systrap>
}
  1050f8:	c9                   	leave  
  1050f9:	c3                   	ret    

001050fa <usercopy>:

// Copy data to/from user space,
// using checkva() above to validate the address range
// and using sysrecover() to recover from any traps during the copy.
void usercopy(trapframe *utf, bool copyout, void *kva, uint32_t uva, size_t size)
{
  1050fa:	55                   	push   %ebp
  1050fb:	89 e5                	mov    %esp,%ebp
  1050fd:	83 ec 28             	sub    $0x28,%esp
	checkva(utf, uva, size);
  105100:	8b 45 18             	mov    0x18(%ebp),%eax
  105103:	89 44 24 08          	mov    %eax,0x8(%esp)
  105107:	8b 45 14             	mov    0x14(%ebp),%eax
  10510a:	89 44 24 04          	mov    %eax,0x4(%esp)
  10510e:	8b 45 08             	mov    0x8(%ebp),%eax
  105111:	89 04 24             	mov    %eax,(%esp)
  105114:	e8 9f ff ff ff       	call   1050b8 <checkva>
	cpu *c = cpu_cur();
  105119:	e8 47 ff ff ff       	call   105065 <cpu_cur>
  10511e:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	assert(c->recover == NULL);
  105121:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  105124:	8b 80 a0 00 00 00    	mov    0xa0(%eax),%eax
  10512a:	85 c0                	test   %eax,%eax
  10512c:	74 24                	je     105152 <usercopy+0x58>
  10512e:	c7 44 24 0c d4 cd 10 	movl   $0x10cdd4,0xc(%esp)
  105135:	00 
  105136:	c7 44 24 08 8d cd 10 	movl   $0x10cd8d,0x8(%esp)
  10513d:	00 
  10513e:	c7 44 24 04 55 00 00 	movl   $0x55,0x4(%esp)
  105145:	00 
  105146:	c7 04 24 a2 cd 10 00 	movl   $0x10cda2,(%esp)
  10514d:	e8 16 b8 ff ff       	call   100968 <debug_panic>
	c->recover = sysrecover;
  105152:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  105155:	c7 80 a0 00 00 00 ef 	movl   $0x104fef,0xa0(%eax)
  10515c:	4f 10 00 

	if(copyout)
  10515f:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  105163:	74 1b                	je     105180 <usercopy+0x86>
		memmove((void*)uva, kva, size);
  105165:	8b 45 14             	mov    0x14(%ebp),%eax
  105168:	8b 55 18             	mov    0x18(%ebp),%edx
  10516b:	89 54 24 08          	mov    %edx,0x8(%esp)
  10516f:	8b 55 10             	mov    0x10(%ebp),%edx
  105172:	89 54 24 04          	mov    %edx,0x4(%esp)
  105176:	89 04 24             	mov    %eax,(%esp)
  105179:	e8 f0 66 00 00       	call   10b86e <memmove>
  10517e:	eb 19                	jmp    105199 <usercopy+0x9f>
	else
		memmove(kva, (void*)uva, size);
  105180:	8b 45 14             	mov    0x14(%ebp),%eax
  105183:	8b 55 18             	mov    0x18(%ebp),%edx
  105186:	89 54 24 08          	mov    %edx,0x8(%esp)
  10518a:	89 44 24 04          	mov    %eax,0x4(%esp)
  10518e:	8b 45 10             	mov    0x10(%ebp),%eax
  105191:	89 04 24             	mov    %eax,(%esp)
  105194:	e8 d5 66 00 00       	call   10b86e <memmove>

	assert(c->recover == sysrecover);
  105199:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  10519c:	8b 80 a0 00 00 00    	mov    0xa0(%eax),%eax
  1051a2:	3d ef 4f 10 00       	cmp    $0x104fef,%eax
  1051a7:	74 24                	je     1051cd <usercopy+0xd3>
  1051a9:	c7 44 24 0c 74 cd 10 	movl   $0x10cd74,0xc(%esp)
  1051b0:	00 
  1051b1:	c7 44 24 08 8d cd 10 	movl   $0x10cd8d,0x8(%esp)
  1051b8:	00 
  1051b9:	c7 44 24 04 5d 00 00 	movl   $0x5d,0x4(%esp)
  1051c0:	00 
  1051c1:	c7 04 24 a2 cd 10 00 	movl   $0x10cda2,(%esp)
  1051c8:	e8 9b b7 ff ff       	call   100968 <debug_panic>
	c->recover = NULL;
  1051cd:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  1051d0:	c7 80 a0 00 00 00 00 	movl   $0x0,0xa0(%eax)
  1051d7:	00 00 00 
}
  1051da:	c9                   	leave  
  1051db:	c3                   	ret    

001051dc <do_cputs>:

static void
do_cputs(trapframe *tf, uint32_t cmd)
{
  1051dc:	55                   	push   %ebp
  1051dd:	89 e5                	mov    %esp,%ebp
  1051df:	81 ec 28 01 00 00    	sub    $0x128,%esp
	// Print the string supplied by the user: pointer in EBX
	char buf[CPUTS_MAX+1];
	usercopy(tf,0,buf,tf->regs.ebx,CPUTS_MAX);
  1051e5:	8b 45 08             	mov    0x8(%ebp),%eax
  1051e8:	8b 40 10             	mov    0x10(%eax),%eax
  1051eb:	c7 44 24 10 00 01 00 	movl   $0x100,0x10(%esp)
  1051f2:	00 
  1051f3:	89 44 24 0c          	mov    %eax,0xc(%esp)
  1051f7:	8d 85 ff fe ff ff    	lea    0xfffffeff(%ebp),%eax
  1051fd:	89 44 24 08          	mov    %eax,0x8(%esp)
  105201:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  105208:	00 
  105209:	8b 45 08             	mov    0x8(%ebp),%eax
  10520c:	89 04 24             	mov    %eax,(%esp)
  10520f:	e8 e6 fe ff ff       	call   1050fa <usercopy>
	buf[CPUTS_MAX] = 0;
  105214:	c6 45 ff 00          	movb   $0x0,0xffffffff(%ebp)
	cprintf("%s",buf);
  105218:	8d 85 ff fe ff ff    	lea    0xfffffeff(%ebp),%eax
  10521e:	89 44 24 04          	mov    %eax,0x4(%esp)
  105222:	c7 04 24 e7 cd 10 00 	movl   $0x10cde7,(%esp)
  105229:	e8 43 62 00 00       	call   10b471 <cprintf>
	trap_return(tf);	// syscall completed
  10522e:	8b 45 08             	mov    0x8(%ebp),%eax
  105231:	89 04 24             	mov    %eax,(%esp)
  105234:	e8 27 e4 ff ff       	call   103660 <trap_return>

00105239 <do_put>:
}

static void
do_put(trapframe *tf, uint32_t cmd)
{
  105239:	55                   	push   %ebp
  10523a:	89 e5                	mov    %esp,%ebp
  10523c:	53                   	push   %ebx
  10523d:	83 ec 44             	sub    $0x44,%esp
	proc *p = proc_cur();
  105240:	e8 20 fe ff ff       	call   105065 <cpu_cur>
  105245:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  10524b:	89 45 dc             	mov    %eax,0xffffffdc(%ebp)
	assert(p->state == PROC_RUN && p->runcpu == cpu_cur());
  10524e:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  105251:	8b 80 3c 04 00 00    	mov    0x43c(%eax),%eax
  105257:	83 f8 02             	cmp    $0x2,%eax
  10525a:	75 12                	jne    10526e <do_put+0x35>
  10525c:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  10525f:	8b 98 44 04 00 00    	mov    0x444(%eax),%ebx
  105265:	e8 fb fd ff ff       	call   105065 <cpu_cur>
  10526a:	39 c3                	cmp    %eax,%ebx
  10526c:	74 24                	je     105292 <do_put+0x59>
  10526e:	c7 44 24 0c ec cd 10 	movl   $0x10cdec,0xc(%esp)
  105275:	00 
  105276:	c7 44 24 08 8d cd 10 	movl   $0x10cd8d,0x8(%esp)
  10527d:	00 
  10527e:	c7 44 24 04 70 00 00 	movl   $0x70,0x4(%esp)
  105285:	00 
  105286:	c7 04 24 a2 cd 10 00 	movl   $0x10cda2,(%esp)
  10528d:	e8 d6 b6 ff ff       	call   100968 <debug_panic>
//cprintf("PUT proc %x eip %x esp %x cmd %x\n", p, tf->eip, tf->esp, cmd);

	spinlock_acquire(&p->lock);
  105292:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  105295:	89 04 24             	mov    %eax,(%esp)
  105298:	e8 1d e8 ff ff       	call   103aba <spinlock_acquire>

	// Find the named child process; create if it doesn't exist
	uint32_t cn = tf->regs.edx & 0xff;
  10529d:	8b 45 08             	mov    0x8(%ebp),%eax
  1052a0:	8b 40 14             	mov    0x14(%eax),%eax
  1052a3:	25 ff 00 00 00       	and    $0xff,%eax
  1052a8:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)
	proc *cp = p->child[cn];
  1052ab:	8b 55 e0             	mov    0xffffffe0(%ebp),%edx
  1052ae:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  1052b1:	8b 44 90 3c          	mov    0x3c(%eax,%edx,4),%eax
  1052b5:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
	if (!cp) {
  1052b8:	83 7d e4 00          	cmpl   $0x0,0xffffffe4(%ebp)
  1052bc:	75 37                	jne    1052f5 <do_put+0xbc>
		cp = proc_alloc(p, cn);
  1052be:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  1052c1:	89 44 24 04          	mov    %eax,0x4(%esp)
  1052c5:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  1052c8:	89 04 24             	mov    %eax,(%esp)
  1052cb:	e8 fe ee ff ff       	call   1041ce <proc_alloc>
  1052d0:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
		if (!cp)	// XX handle more gracefully
  1052d3:	83 7d e4 00          	cmpl   $0x0,0xffffffe4(%ebp)
  1052d7:	75 1c                	jne    1052f5 <do_put+0xbc>
			panic("sys_put: no memory for child");
  1052d9:	c7 44 24 08 1b ce 10 	movl   $0x10ce1b,0x8(%esp)
  1052e0:	00 
  1052e1:	c7 44 24 04 7b 00 00 	movl   $0x7b,0x4(%esp)
  1052e8:	00 
  1052e9:	c7 04 24 a2 cd 10 00 	movl   $0x10cda2,(%esp)
  1052f0:	e8 73 b6 ff ff       	call   100968 <debug_panic>
	}

	// Synchronize with child if necessary.
	if (cp->state != PROC_STOP)
  1052f5:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  1052f8:	8b 80 3c 04 00 00    	mov    0x43c(%eax),%eax
  1052fe:	85 c0                	test   %eax,%eax
  105300:	74 19                	je     10531b <do_put+0xe2>
		proc_wait(p, cp, tf);
  105302:	8b 45 08             	mov    0x8(%ebp),%eax
  105305:	89 44 24 08          	mov    %eax,0x8(%esp)
  105309:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  10530c:	89 44 24 04          	mov    %eax,0x4(%esp)
  105310:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  105313:	89 04 24             	mov    %eax,(%esp)
  105316:	e8 d4 f1 ff ff       	call   1044ef <proc_wait>

	// Since the child is now stopped, it's ours to control;
	// we no longer need our process lock -
	// and we don't want to be holding it if usercopy() below aborts.
	spinlock_release(&p->lock);
  10531b:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  10531e:	89 04 24             	mov    %eax,(%esp)
  105321:	e8 8f e8 ff ff       	call   103bb5 <spinlock_release>

	// Put child's general register state
	if (cmd & SYS_REGS) {
  105326:	8b 45 0c             	mov    0xc(%ebp),%eax
  105329:	25 00 10 00 00       	and    $0x1000,%eax
  10532e:	85 c0                	test   %eax,%eax
  105330:	0f 84 d4 00 00 00    	je     10540a <do_put+0x1d1>
		int len = offsetof(procstate, fx);  // just integer regs
  105336:	c7 45 f4 50 00 00 00 	movl   $0x50,0xfffffff4(%ebp)
		if (cmd & SYS_FPU) len = sizeof(procstate); // whole shebang
  10533d:	8b 45 0c             	mov    0xc(%ebp),%eax
  105340:	25 00 20 00 00       	and    $0x2000,%eax
  105345:	85 c0                	test   %eax,%eax
  105347:	74 07                	je     105350 <do_put+0x117>
  105349:	c7 45 f4 50 02 00 00 	movl   $0x250,0xfffffff4(%ebp)

		usercopy(tf,0,&cp->sv, tf->regs.ebx, len);
  105350:	8b 4d f4             	mov    0xfffffff4(%ebp),%ecx
  105353:	8b 45 08             	mov    0x8(%ebp),%eax
  105356:	8b 40 10             	mov    0x10(%eax),%eax
  105359:	8b 55 e4             	mov    0xffffffe4(%ebp),%edx
  10535c:	81 c2 50 04 00 00    	add    $0x450,%edx
  105362:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  105366:	89 44 24 0c          	mov    %eax,0xc(%esp)
  10536a:	89 54 24 08          	mov    %edx,0x8(%esp)
  10536e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  105375:	00 
  105376:	8b 45 08             	mov    0x8(%ebp),%eax
  105379:	89 04 24             	mov    %eax,(%esp)
  10537c:	e8 79 fd ff ff       	call   1050fa <usercopy>
		// Copy user's trapframe into child process
		procstate *cs = (procstate*) tf->regs.ebx;
  105381:	8b 45 08             	mov    0x8(%ebp),%eax
  105384:	8b 40 10             	mov    0x10(%eax),%eax
  105387:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
		memcpy(&cp->sv, cs, len);
  10538a:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  10538d:	8b 55 e4             	mov    0xffffffe4(%ebp),%edx
  105390:	81 c2 50 04 00 00    	add    $0x450,%edx
  105396:	89 44 24 08          	mov    %eax,0x8(%esp)
  10539a:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10539d:	89 44 24 04          	mov    %eax,0x4(%esp)
  1053a1:	89 14 24             	mov    %edx,(%esp)
  1053a4:	e8 8b 65 00 00       	call   10b934 <memcpy>

		// Make sure process uses user-mode segments and eflag settings
		cp->sv.tf.ds = CPU_GDT_UDATA | 3;
  1053a9:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  1053ac:	66 c7 80 7c 04 00 00 	movw   $0x23,0x47c(%eax)
  1053b3:	23 00 
		cp->sv.tf.es = CPU_GDT_UDATA | 3;
  1053b5:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  1053b8:	66 c7 80 78 04 00 00 	movw   $0x23,0x478(%eax)
  1053bf:	23 00 
		cp->sv.tf.cs = CPU_GDT_UCODE | 3;
  1053c1:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  1053c4:	66 c7 80 8c 04 00 00 	movw   $0x1b,0x48c(%eax)
  1053cb:	1b 00 
		cp->sv.tf.ss = CPU_GDT_UDATA | 3;
  1053cd:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  1053d0:	66 c7 80 98 04 00 00 	movw   $0x23,0x498(%eax)
  1053d7:	23 00 
		cp->sv.tf.eflags &= FL_USER;
  1053d9:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  1053dc:	8b 80 90 04 00 00    	mov    0x490(%eax),%eax
  1053e2:	89 c2                	mov    %eax,%edx
  1053e4:	81 e2 d5 0c 00 00    	and    $0xcd5,%edx
  1053ea:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  1053ed:	89 90 90 04 00 00    	mov    %edx,0x490(%eax)
		cp->sv.tf.eflags |= FL_IF;  // enable interrupts
  1053f3:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  1053f6:	8b 80 90 04 00 00    	mov    0x490(%eax),%eax
  1053fc:	89 c2                	mov    %eax,%edx
  1053fe:	80 ce 02             	or     $0x2,%dh
  105401:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  105404:	89 90 90 04 00 00    	mov    %edx,0x490(%eax)
	}
	uint32_t sva = tf->regs.esi;
  10540a:	8b 45 08             	mov    0x8(%ebp),%eax
  10540d:	8b 40 04             	mov    0x4(%eax),%eax
  105410:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
	uint32_t dva = tf->regs.edi;
  105413:	8b 45 08             	mov    0x8(%ebp),%eax
  105416:	8b 00                	mov    (%eax),%eax
  105418:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
	uint32_t size = tf->regs.ecx;
  10541b:	8b 45 08             	mov    0x8(%ebp),%eax
  10541e:	8b 40 18             	mov    0x18(%eax),%eax
  105421:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
	switch (cmd & SYS_MEMOP) {
  105424:	8b 45 0c             	mov    0xc(%ebp),%eax
  105427:	25 00 00 03 00       	and    $0x30000,%eax
  10542c:	89 45 d4             	mov    %eax,0xffffffd4(%ebp)
  10542f:	81 7d d4 00 00 01 00 	cmpl   $0x10000,0xffffffd4(%ebp)
  105436:	74 6a                	je     1054a2 <do_put+0x269>
  105438:	81 7d d4 00 00 02 00 	cmpl   $0x20000,0xffffffd4(%ebp)
  10543f:	74 0f                	je     105450 <do_put+0x217>
  105441:	83 7d d4 00          	cmpl   $0x0,0xffffffd4(%ebp)
  105445:	0f 84 39 01 00 00    	je     105584 <do_put+0x34b>
  10544b:	e9 19 01 00 00       	jmp    105569 <do_put+0x330>
		case 0:	// no memory operation
			break;
		case SYS_COPY:
			// validate source region
			if (PTOFF(sva) || PTOFF(size)
  105450:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  105453:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  105458:	85 c0                	test   %eax,%eax
  10545a:	75 2b                	jne    105487 <do_put+0x24e>
  10545c:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  10545f:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  105464:	85 c0                	test   %eax,%eax
  105466:	75 1f                	jne    105487 <do_put+0x24e>
  105468:	81 7d e8 ff ff ff 3f 	cmpl   $0x3fffffff,0xffffffe8(%ebp)
  10546f:	76 16                	jbe    105487 <do_put+0x24e>
  105471:	81 7d e8 00 00 00 f0 	cmpl   $0xf0000000,0xffffffe8(%ebp)
  105478:	77 0d                	ja     105487 <do_put+0x24e>
  10547a:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
  10547f:	2b 45 e8             	sub    0xffffffe8(%ebp),%eax
  105482:	3b 45 f0             	cmp    0xfffffff0(%ebp),%eax
  105485:	73 1b                	jae    1054a2 <do_put+0x269>
					|| sva < VM_USERLO || sva > VM_USERHI
					|| size > VM_USERHI-sva)
				systrap(tf, T_GPFLT, 0);
  105487:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  10548e:	00 
  10548f:	c7 44 24 04 0d 00 00 	movl   $0xd,0x4(%esp)
  105496:	00 
  105497:	8b 45 08             	mov    0x8(%ebp),%eax
  10549a:	89 04 24             	mov    %eax,(%esp)
  10549d:	e8 22 fb ff ff       	call   104fc4 <systrap>
			// fall thru...
		case SYS_ZERO:
			// validate destination region
			if (PTOFF(dva) || PTOFF(size)
  1054a2:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  1054a5:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  1054aa:	85 c0                	test   %eax,%eax
  1054ac:	75 2b                	jne    1054d9 <do_put+0x2a0>
  1054ae:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  1054b1:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  1054b6:	85 c0                	test   %eax,%eax
  1054b8:	75 1f                	jne    1054d9 <do_put+0x2a0>
  1054ba:	81 7d ec ff ff ff 3f 	cmpl   $0x3fffffff,0xffffffec(%ebp)
  1054c1:	76 16                	jbe    1054d9 <do_put+0x2a0>
  1054c3:	81 7d ec 00 00 00 f0 	cmpl   $0xf0000000,0xffffffec(%ebp)
  1054ca:	77 0d                	ja     1054d9 <do_put+0x2a0>
  1054cc:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
  1054d1:	2b 45 ec             	sub    0xffffffec(%ebp),%eax
  1054d4:	3b 45 f0             	cmp    0xfffffff0(%ebp),%eax
  1054d7:	73 1b                	jae    1054f4 <do_put+0x2bb>
					|| dva < VM_USERLO || dva > VM_USERHI
					|| size > VM_USERHI-dva)
				systrap(tf, T_GPFLT, 0);
  1054d9:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  1054e0:	00 
  1054e1:	c7 44 24 04 0d 00 00 	movl   $0xd,0x4(%esp)
  1054e8:	00 
  1054e9:	8b 45 08             	mov    0x8(%ebp),%eax
  1054ec:	89 04 24             	mov    %eax,(%esp)
  1054ef:	e8 d0 fa ff ff       	call   104fc4 <systrap>

			switch (cmd & SYS_MEMOP) {
  1054f4:	8b 45 0c             	mov    0xc(%ebp),%eax
  1054f7:	25 00 00 03 00       	and    $0x30000,%eax
  1054fc:	89 45 d8             	mov    %eax,0xffffffd8(%ebp)
  1054ff:	81 7d d8 00 00 01 00 	cmpl   $0x10000,0xffffffd8(%ebp)
  105506:	74 0b                	je     105513 <do_put+0x2da>
  105508:	81 7d d8 00 00 02 00 	cmpl   $0x20000,0xffffffd8(%ebp)
  10550f:	74 23                	je     105534 <do_put+0x2fb>
  105511:	eb 71                	jmp    105584 <do_put+0x34b>
				case SYS_ZERO:	// zero memory and clear permissions
					pmap_remove(cp->pdir, dva, size);
  105513:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  105516:	8b 90 a0 06 00 00    	mov    0x6a0(%eax),%edx
  10551c:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  10551f:	89 44 24 08          	mov    %eax,0x8(%esp)
  105523:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  105526:	89 44 24 04          	mov    %eax,0x4(%esp)
  10552a:	89 14 24             	mov    %edx,(%esp)
  10552d:	e8 d3 12 00 00       	call   106805 <pmap_remove>
					break;
  105532:	eb 50                	jmp    105584 <do_put+0x34b>
				case SYS_COPY:	// copy from local src to dest in child
					pmap_copy(p->pdir, sva, cp->pdir, dva, size);
  105534:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  105537:	8b 90 a0 06 00 00    	mov    0x6a0(%eax),%edx
  10553d:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  105540:	8b 88 a0 06 00 00    	mov    0x6a0(%eax),%ecx
  105546:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  105549:	89 44 24 10          	mov    %eax,0x10(%esp)
  10554d:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  105550:	89 44 24 0c          	mov    %eax,0xc(%esp)
  105554:	89 54 24 08          	mov    %edx,0x8(%esp)
  105558:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  10555b:	89 44 24 04          	mov    %eax,0x4(%esp)
  10555f:	89 0c 24             	mov    %ecx,(%esp)
  105562:	e8 81 17 00 00       	call   106ce8 <pmap_copy>
					break;
			}
			break;
  105567:	eb 1b                	jmp    105584 <do_put+0x34b>
		default:
			systrap(tf, T_GPFLT, 0);
  105569:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  105570:	00 
  105571:	c7 44 24 04 0d 00 00 	movl   $0xd,0x4(%esp)
  105578:	00 
  105579:	8b 45 08             	mov    0x8(%ebp),%eax
  10557c:	89 04 24             	mov    %eax,(%esp)
  10557f:	e8 40 fa ff ff       	call   104fc4 <systrap>
	}

	if (cmd & SYS_PERM) {
  105584:	8b 45 0c             	mov    0xc(%ebp),%eax
  105587:	25 00 01 00 00       	and    $0x100,%eax
  10558c:	85 c0                	test   %eax,%eax
  10558e:	0f 84 a0 00 00 00    	je     105634 <do_put+0x3fb>
		// validate destination region
		if (PGOFF(dva) || PGOFF(size)
  105594:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  105597:	25 ff 0f 00 00       	and    $0xfff,%eax
  10559c:	85 c0                	test   %eax,%eax
  10559e:	75 2b                	jne    1055cb <do_put+0x392>
  1055a0:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  1055a3:	25 ff 0f 00 00       	and    $0xfff,%eax
  1055a8:	85 c0                	test   %eax,%eax
  1055aa:	75 1f                	jne    1055cb <do_put+0x392>
  1055ac:	81 7d ec ff ff ff 3f 	cmpl   $0x3fffffff,0xffffffec(%ebp)
  1055b3:	76 16                	jbe    1055cb <do_put+0x392>
  1055b5:	81 7d ec 00 00 00 f0 	cmpl   $0xf0000000,0xffffffec(%ebp)
  1055bc:	77 0d                	ja     1055cb <do_put+0x392>
  1055be:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
  1055c3:	2b 45 ec             	sub    0xffffffec(%ebp),%eax
  1055c6:	3b 45 f0             	cmp    0xfffffff0(%ebp),%eax
  1055c9:	73 1b                	jae    1055e6 <do_put+0x3ad>
				|| dva < VM_USERLO || dva > VM_USERHI
				|| size > VM_USERHI-dva)
			systrap(tf, T_GPFLT, 0);
  1055cb:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  1055d2:	00 
  1055d3:	c7 44 24 04 0d 00 00 	movl   $0xd,0x4(%esp)
  1055da:	00 
  1055db:	8b 45 08             	mov    0x8(%ebp),%eax
  1055de:	89 04 24             	mov    %eax,(%esp)
  1055e1:	e8 de f9 ff ff       	call   104fc4 <systrap>
		if (!pmap_setperm(cp->pdir, dva, size, cmd & SYS_RW))
  1055e6:	8b 45 0c             	mov    0xc(%ebp),%eax
  1055e9:	89 c2                	mov    %eax,%edx
  1055eb:	81 e2 00 06 00 00    	and    $0x600,%edx
  1055f1:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  1055f4:	8b 88 a0 06 00 00    	mov    0x6a0(%eax),%ecx
  1055fa:	89 54 24 0c          	mov    %edx,0xc(%esp)
  1055fe:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  105601:	89 44 24 08          	mov    %eax,0x8(%esp)
  105605:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  105608:	89 44 24 04          	mov    %eax,0x4(%esp)
  10560c:	89 0c 24             	mov    %ecx,(%esp)
  10560f:	e8 64 29 00 00       	call   107f78 <pmap_setperm>
  105614:	85 c0                	test   %eax,%eax
  105616:	75 1c                	jne    105634 <do_put+0x3fb>
			panic("pmap_put: no memory to set permissions");
  105618:	c7 44 24 08 38 ce 10 	movl   $0x10ce38,0x8(%esp)
  10561f:	00 
  105620:	c7 44 24 04 c1 00 00 	movl   $0xc1,0x4(%esp)
  105627:	00 
  105628:	c7 04 24 a2 cd 10 00 	movl   $0x10cda2,(%esp)
  10562f:	e8 34 b3 ff ff       	call   100968 <debug_panic>
	}

	if (cmd & SYS_SNAP)	// Snapshot child's state
  105634:	8b 45 0c             	mov    0xc(%ebp),%eax
  105637:	25 00 00 04 00       	and    $0x40000,%eax
  10563c:	85 c0                	test   %eax,%eax
  10563e:	74 36                	je     105676 <do_put+0x43d>
		pmap_copy(cp->pdir, VM_USERLO, cp->rpdir, VM_USERLO,
  105640:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  105643:	8b 90 a4 06 00 00    	mov    0x6a4(%eax),%edx
  105649:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  10564c:	8b 80 a0 06 00 00    	mov    0x6a0(%eax),%eax
  105652:	c7 44 24 10 00 00 00 	movl   $0xb0000000,0x10(%esp)
  105659:	b0 
  10565a:	c7 44 24 0c 00 00 00 	movl   $0x40000000,0xc(%esp)
  105661:	40 
  105662:	89 54 24 08          	mov    %edx,0x8(%esp)
  105666:	c7 44 24 04 00 00 00 	movl   $0x40000000,0x4(%esp)
  10566d:	40 
  10566e:	89 04 24             	mov    %eax,(%esp)
  105671:	e8 72 16 00 00       	call   106ce8 <pmap_copy>
				VM_USERHI-VM_USERLO);

	// Start the child if requested
	if (cmd & SYS_START)
  105676:	8b 45 0c             	mov    0xc(%ebp),%eax
  105679:	83 e0 10             	and    $0x10,%eax
  10567c:	85 c0                	test   %eax,%eax
  10567e:	74 0b                	je     10568b <do_put+0x452>
		proc_ready(cp);
  105680:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  105683:	89 04 24             	mov    %eax,(%esp)
  105686:	e8 8d ed ff ff       	call   104418 <proc_ready>

	trap_return(tf);  // syscall completed
  10568b:	8b 45 08             	mov    0x8(%ebp),%eax
  10568e:	89 04 24             	mov    %eax,(%esp)
  105691:	e8 ca df ff ff       	call   103660 <trap_return>

00105696 <do_get>:
}

  static void
do_get(trapframe *tf, uint32_t cmd)
{
  105696:	55                   	push   %ebp
  105697:	89 e5                	mov    %esp,%ebp
  105699:	53                   	push   %ebx
  10569a:	83 ec 44             	sub    $0x44,%esp
  proc *p = proc_cur();
  10569d:	e8 c3 f9 ff ff       	call   105065 <cpu_cur>
  1056a2:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  1056a8:	89 45 dc             	mov    %eax,0xffffffdc(%ebp)
  assert(p->state == PROC_RUN && p->runcpu == cpu_cur());
  1056ab:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  1056ae:	8b 80 3c 04 00 00    	mov    0x43c(%eax),%eax
  1056b4:	83 f8 02             	cmp    $0x2,%eax
  1056b7:	75 12                	jne    1056cb <do_get+0x35>
  1056b9:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  1056bc:	8b 98 44 04 00 00    	mov    0x444(%eax),%ebx
  1056c2:	e8 9e f9 ff ff       	call   105065 <cpu_cur>
  1056c7:	39 c3                	cmp    %eax,%ebx
  1056c9:	74 24                	je     1056ef <do_get+0x59>
  1056cb:	c7 44 24 0c ec cd 10 	movl   $0x10cdec,0xc(%esp)
  1056d2:	00 
  1056d3:	c7 44 24 08 8d cd 10 	movl   $0x10cd8d,0x8(%esp)
  1056da:	00 
  1056db:	c7 44 24 04 d3 00 00 	movl   $0xd3,0x4(%esp)
  1056e2:	00 
  1056e3:	c7 04 24 a2 cd 10 00 	movl   $0x10cda2,(%esp)
  1056ea:	e8 79 b2 ff ff       	call   100968 <debug_panic>
  //cprintf("GET proc %x eip %x esp %x cmd %x\n", p, tf->eip, tf->esp, cmd);

  spinlock_acquire(&p->lock);
  1056ef:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  1056f2:	89 04 24             	mov    %eax,(%esp)
  1056f5:	e8 c0 e3 ff ff       	call   103aba <spinlock_acquire>

  // Find the named child process; DON'T create if it doesn't exist
  uint32_t cn = tf->regs.edx & 0xff;
  1056fa:	8b 45 08             	mov    0x8(%ebp),%eax
  1056fd:	8b 40 14             	mov    0x14(%eax),%eax
  105700:	25 ff 00 00 00       	and    $0xff,%eax
  105705:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)
  proc *cp = p->child[cn];
  105708:	8b 55 e0             	mov    0xffffffe0(%ebp),%edx
  10570b:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  10570e:	8b 44 90 3c          	mov    0x3c(%eax,%edx,4),%eax
  105712:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
  if (!cp)
  105715:	83 7d e4 00          	cmpl   $0x0,0xffffffe4(%ebp)
  105719:	75 07                	jne    105722 <do_get+0x8c>
    cp = &proc_null;
  10571b:	c7 45 e4 00 ee 17 00 	movl   $0x17ee00,0xffffffe4(%ebp)

  // Synchronize with child if necessary.
  if (cp->state != PROC_STOP)
  105722:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  105725:	8b 80 3c 04 00 00    	mov    0x43c(%eax),%eax
  10572b:	85 c0                	test   %eax,%eax
  10572d:	74 19                	je     105748 <do_get+0xb2>
    proc_wait(p, cp, tf);
  10572f:	8b 45 08             	mov    0x8(%ebp),%eax
  105732:	89 44 24 08          	mov    %eax,0x8(%esp)
  105736:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  105739:	89 44 24 04          	mov    %eax,0x4(%esp)
  10573d:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  105740:	89 04 24             	mov    %eax,(%esp)
  105743:	e8 a7 ed ff ff       	call   1044ef <proc_wait>

  // Since the child is now stopped, it's ours to control;
  // we no longer need our process lock -
  // and we don't want to be holding it if usercopy() below aborts.
  spinlock_release(&p->lock);
  105748:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  10574b:	89 04 24             	mov    %eax,(%esp)
  10574e:	e8 62 e4 ff ff       	call   103bb5 <spinlock_release>

  // Get child's general register state
  if (cmd & SYS_REGS) {
  105753:	8b 45 0c             	mov    0xc(%ebp),%eax
  105756:	25 00 10 00 00       	and    $0x1000,%eax
  10575b:	85 c0                	test   %eax,%eax
  10575d:	74 73                	je     1057d2 <do_get+0x13c>
    int len = offsetof(procstate, fx);  // just integer regs
  10575f:	c7 45 f4 50 00 00 00 	movl   $0x50,0xfffffff4(%ebp)
    if (cmd & SYS_FPU) len = sizeof(procstate); // whole shebang
  105766:	8b 45 0c             	mov    0xc(%ebp),%eax
  105769:	25 00 20 00 00       	and    $0x2000,%eax
  10576e:	85 c0                	test   %eax,%eax
  105770:	74 07                	je     105779 <do_get+0xe3>
  105772:	c7 45 f4 50 02 00 00 	movl   $0x250,0xfffffff4(%ebp)
usercopy(tf, 1, &cp->sv, tf->regs.ebx, len);
  105779:	8b 4d f4             	mov    0xfffffff4(%ebp),%ecx
  10577c:	8b 45 08             	mov    0x8(%ebp),%eax
  10577f:	8b 40 10             	mov    0x10(%eax),%eax
  105782:	8b 55 e4             	mov    0xffffffe4(%ebp),%edx
  105785:	81 c2 50 04 00 00    	add    $0x450,%edx
  10578b:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  10578f:	89 44 24 0c          	mov    %eax,0xc(%esp)
  105793:	89 54 24 08          	mov    %edx,0x8(%esp)
  105797:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  10579e:	00 
  10579f:	8b 45 08             	mov    0x8(%ebp),%eax
  1057a2:	89 04 24             	mov    %eax,(%esp)
  1057a5:	e8 50 f9 ff ff       	call   1050fa <usercopy>
    // Copy child process's trapframe into user space
    procstate *cs = (procstate*) tf->regs.ebx;
  1057aa:	8b 45 08             	mov    0x8(%ebp),%eax
  1057ad:	8b 40 10             	mov    0x10(%eax),%eax
  1057b0:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
    memcpy(cs, &cp->sv, len);
  1057b3:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  1057b6:	8b 55 e4             	mov    0xffffffe4(%ebp),%edx
  1057b9:	81 c2 50 04 00 00    	add    $0x450,%edx
  1057bf:	89 44 24 08          	mov    %eax,0x8(%esp)
  1057c3:	89 54 24 04          	mov    %edx,0x4(%esp)
  1057c7:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1057ca:	89 04 24             	mov    %eax,(%esp)
  1057cd:	e8 62 61 00 00       	call   10b934 <memcpy>
  }
uint32_t sva = tf->regs.esi;
  1057d2:	8b 45 08             	mov    0x8(%ebp),%eax
  1057d5:	8b 40 04             	mov    0x4(%eax),%eax
  1057d8:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
	uint32_t dva = tf->regs.edi;
  1057db:	8b 45 08             	mov    0x8(%ebp),%eax
  1057de:	8b 00                	mov    (%eax),%eax
  1057e0:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
	uint32_t size = tf->regs.ecx;
  1057e3:	8b 45 08             	mov    0x8(%ebp),%eax
  1057e6:	8b 40 18             	mov    0x18(%eax),%eax
  1057e9:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
	switch (cmd & SYS_MEMOP) {
  1057ec:	8b 45 0c             	mov    0xc(%ebp),%eax
  1057ef:	25 00 00 03 00       	and    $0x30000,%eax
  1057f4:	89 45 d4             	mov    %eax,0xffffffd4(%ebp)
  1057f7:	81 7d d4 00 00 01 00 	cmpl   $0x10000,0xffffffd4(%ebp)
  1057fe:	0f 84 81 00 00 00    	je     105885 <do_get+0x1ef>
  105804:	81 7d d4 00 00 01 00 	cmpl   $0x10000,0xffffffd4(%ebp)
  10580b:	77 0f                	ja     10581c <do_get+0x186>
  10580d:	83 7d d4 00          	cmpl   $0x0,0xffffffd4(%ebp)
  105811:	0f 84 a1 01 00 00    	je     1059b8 <do_get+0x322>
  105817:	e9 81 01 00 00       	jmp    10599d <do_get+0x307>
  10581c:	81 7d d4 00 00 02 00 	cmpl   $0x20000,0xffffffd4(%ebp)
  105823:	74 0e                	je     105833 <do_get+0x19d>
  105825:	81 7d d4 00 00 03 00 	cmpl   $0x30000,0xffffffd4(%ebp)
  10582c:	74 05                	je     105833 <do_get+0x19d>
  10582e:	e9 6a 01 00 00       	jmp    10599d <do_get+0x307>
	case 0:	// no memory operation
		break;
	case SYS_COPY:
	case SYS_MERGE:
		// validate source region
		if (PTOFF(sva) || PTOFF(size)
  105833:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  105836:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  10583b:	85 c0                	test   %eax,%eax
  10583d:	75 2b                	jne    10586a <do_get+0x1d4>
  10583f:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  105842:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  105847:	85 c0                	test   %eax,%eax
  105849:	75 1f                	jne    10586a <do_get+0x1d4>
  10584b:	81 7d e8 ff ff ff 3f 	cmpl   $0x3fffffff,0xffffffe8(%ebp)
  105852:	76 16                	jbe    10586a <do_get+0x1d4>
  105854:	81 7d e8 00 00 00 f0 	cmpl   $0xf0000000,0xffffffe8(%ebp)
  10585b:	77 0d                	ja     10586a <do_get+0x1d4>
  10585d:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
  105862:	2b 45 e8             	sub    0xffffffe8(%ebp),%eax
  105865:	3b 45 f0             	cmp    0xfffffff0(%ebp),%eax
  105868:	73 1b                	jae    105885 <do_get+0x1ef>
				|| sva < VM_USERLO || sva > VM_USERHI
				|| size > VM_USERHI-sva)
			systrap(tf, T_GPFLT, 0);
  10586a:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  105871:	00 
  105872:	c7 44 24 04 0d 00 00 	movl   $0xd,0x4(%esp)
  105879:	00 
  10587a:	8b 45 08             	mov    0x8(%ebp),%eax
  10587d:	89 04 24             	mov    %eax,(%esp)
  105880:	e8 3f f7 ff ff       	call   104fc4 <systrap>
		// fall thru...
	case SYS_ZERO:
		// validate destination region
		if (PTOFF(dva) || PTOFF(size)
  105885:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  105888:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  10588d:	85 c0                	test   %eax,%eax
  10588f:	75 2b                	jne    1058bc <do_get+0x226>
  105891:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  105894:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  105899:	85 c0                	test   %eax,%eax
  10589b:	75 1f                	jne    1058bc <do_get+0x226>
  10589d:	81 7d ec ff ff ff 3f 	cmpl   $0x3fffffff,0xffffffec(%ebp)
  1058a4:	76 16                	jbe    1058bc <do_get+0x226>
  1058a6:	81 7d ec 00 00 00 f0 	cmpl   $0xf0000000,0xffffffec(%ebp)
  1058ad:	77 0d                	ja     1058bc <do_get+0x226>
  1058af:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
  1058b4:	2b 45 ec             	sub    0xffffffec(%ebp),%eax
  1058b7:	3b 45 f0             	cmp    0xfffffff0(%ebp),%eax
  1058ba:	73 1b                	jae    1058d7 <do_get+0x241>
				|| dva < VM_USERLO || dva > VM_USERHI
				|| size > VM_USERHI-dva)
			systrap(tf, T_GPFLT, 0);
  1058bc:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  1058c3:	00 
  1058c4:	c7 44 24 04 0d 00 00 	movl   $0xd,0x4(%esp)
  1058cb:	00 
  1058cc:	8b 45 08             	mov    0x8(%ebp),%eax
  1058cf:	89 04 24             	mov    %eax,(%esp)
  1058d2:	e8 ed f6 ff ff       	call   104fc4 <systrap>

		switch (cmd & SYS_MEMOP) {
  1058d7:	8b 45 0c             	mov    0xc(%ebp),%eax
  1058da:	25 00 00 03 00       	and    $0x30000,%eax
  1058df:	89 45 d8             	mov    %eax,0xffffffd8(%ebp)
  1058e2:	81 7d d8 00 00 02 00 	cmpl   $0x20000,0xffffffd8(%ebp)
  1058e9:	74 3b                	je     105926 <do_get+0x290>
  1058eb:	81 7d d8 00 00 03 00 	cmpl   $0x30000,0xffffffd8(%ebp)
  1058f2:	74 67                	je     10595b <do_get+0x2c5>
  1058f4:	81 7d d8 00 00 01 00 	cmpl   $0x10000,0xffffffd8(%ebp)
  1058fb:	74 05                	je     105902 <do_get+0x26c>
  1058fd:	e9 b6 00 00 00       	jmp    1059b8 <do_get+0x322>
		case SYS_ZERO:	// zero memory and clear permissions
			pmap_remove(p->pdir, dva, size);
  105902:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  105905:	8b 90 a0 06 00 00    	mov    0x6a0(%eax),%edx
  10590b:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  10590e:	89 44 24 08          	mov    %eax,0x8(%esp)
  105912:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  105915:	89 44 24 04          	mov    %eax,0x4(%esp)
  105919:	89 14 24             	mov    %edx,(%esp)
  10591c:	e8 e4 0e 00 00       	call   106805 <pmap_remove>
			break;
  105921:	e9 92 00 00 00       	jmp    1059b8 <do_get+0x322>
		case SYS_COPY:	// copy from local src to dest in child
			pmap_copy(cp->pdir, sva, p->pdir, dva, size);
  105926:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  105929:	8b 90 a0 06 00 00    	mov    0x6a0(%eax),%edx
  10592f:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  105932:	8b 88 a0 06 00 00    	mov    0x6a0(%eax),%ecx
  105938:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  10593b:	89 44 24 10          	mov    %eax,0x10(%esp)
  10593f:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  105942:	89 44 24 0c          	mov    %eax,0xc(%esp)
  105946:	89 54 24 08          	mov    %edx,0x8(%esp)
  10594a:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  10594d:	89 44 24 04          	mov    %eax,0x4(%esp)
  105951:	89 0c 24             	mov    %ecx,(%esp)
  105954:	e8 8f 13 00 00       	call   106ce8 <pmap_copy>
			break;
  105959:	eb 5d                	jmp    1059b8 <do_get+0x322>
		case SYS_MERGE:	// merge from local src to dest in child
			pmap_merge(cp->rpdir, cp->pdir, sva,
  10595b:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  10595e:	8b 90 a0 06 00 00    	mov    0x6a0(%eax),%edx
  105964:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  105967:	8b 88 a0 06 00 00    	mov    0x6a0(%eax),%ecx
  10596d:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  105970:	8b 98 a4 06 00 00    	mov    0x6a4(%eax),%ebx
  105976:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  105979:	89 44 24 14          	mov    %eax,0x14(%esp)
  10597d:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  105980:	89 44 24 10          	mov    %eax,0x10(%esp)
  105984:	89 54 24 0c          	mov    %edx,0xc(%esp)
  105988:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  10598b:	89 44 24 08          	mov    %eax,0x8(%esp)
  10598f:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  105993:	89 1c 24             	mov    %ebx,(%esp)
  105996:	e8 33 20 00 00       	call   1079ce <pmap_merge>
					p->pdir, dva, size);
			break;
		}
		break;
  10599b:	eb 1b                	jmp    1059b8 <do_get+0x322>
	default:
		systrap(tf, T_GPFLT, 0);
  10599d:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  1059a4:	00 
  1059a5:	c7 44 24 04 0d 00 00 	movl   $0xd,0x4(%esp)
  1059ac:	00 
  1059ad:	8b 45 08             	mov    0x8(%ebp),%eax
  1059b0:	89 04 24             	mov    %eax,(%esp)
  1059b3:	e8 0c f6 ff ff       	call   104fc4 <systrap>
	}

	if (cmd & SYS_PERM) {
  1059b8:	8b 45 0c             	mov    0xc(%ebp),%eax
  1059bb:	25 00 01 00 00       	and    $0x100,%eax
  1059c0:	85 c0                	test   %eax,%eax
  1059c2:	0f 84 a0 00 00 00    	je     105a68 <do_get+0x3d2>
		// validate destination region
		if (PGOFF(dva) || PGOFF(size)
  1059c8:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  1059cb:	25 ff 0f 00 00       	and    $0xfff,%eax
  1059d0:	85 c0                	test   %eax,%eax
  1059d2:	75 2b                	jne    1059ff <do_get+0x369>
  1059d4:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  1059d7:	25 ff 0f 00 00       	and    $0xfff,%eax
  1059dc:	85 c0                	test   %eax,%eax
  1059de:	75 1f                	jne    1059ff <do_get+0x369>
  1059e0:	81 7d ec ff ff ff 3f 	cmpl   $0x3fffffff,0xffffffec(%ebp)
  1059e7:	76 16                	jbe    1059ff <do_get+0x369>
  1059e9:	81 7d ec 00 00 00 f0 	cmpl   $0xf0000000,0xffffffec(%ebp)
  1059f0:	77 0d                	ja     1059ff <do_get+0x369>
  1059f2:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
  1059f7:	2b 45 ec             	sub    0xffffffec(%ebp),%eax
  1059fa:	3b 45 f0             	cmp    0xfffffff0(%ebp),%eax
  1059fd:	73 1b                	jae    105a1a <do_get+0x384>
				|| dva < VM_USERLO || dva > VM_USERHI
				|| size > VM_USERHI-dva)
			systrap(tf, T_GPFLT, 0);
  1059ff:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  105a06:	00 
  105a07:	c7 44 24 04 0d 00 00 	movl   $0xd,0x4(%esp)
  105a0e:	00 
  105a0f:	8b 45 08             	mov    0x8(%ebp),%eax
  105a12:	89 04 24             	mov    %eax,(%esp)
  105a15:	e8 aa f5 ff ff       	call   104fc4 <systrap>
		if (!pmap_setperm(p->pdir, dva, size, cmd & SYS_RW))
  105a1a:	8b 45 0c             	mov    0xc(%ebp),%eax
  105a1d:	89 c2                	mov    %eax,%edx
  105a1f:	81 e2 00 06 00 00    	and    $0x600,%edx
  105a25:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  105a28:	8b 88 a0 06 00 00    	mov    0x6a0(%eax),%ecx
  105a2e:	89 54 24 0c          	mov    %edx,0xc(%esp)
  105a32:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  105a35:	89 44 24 08          	mov    %eax,0x8(%esp)
  105a39:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  105a3c:	89 44 24 04          	mov    %eax,0x4(%esp)
  105a40:	89 0c 24             	mov    %ecx,(%esp)
  105a43:	e8 30 25 00 00       	call   107f78 <pmap_setperm>
  105a48:	85 c0                	test   %eax,%eax
  105a4a:	75 1c                	jne    105a68 <do_get+0x3d2>
			panic("pmap_get: no memory to set permissions");
  105a4c:	c7 44 24 08 60 ce 10 	movl   $0x10ce60,0x8(%esp)
  105a53:	00 
  105a54:	c7 44 24 04 1d 01 00 	movl   $0x11d,0x4(%esp)
  105a5b:	00 
  105a5c:	c7 04 24 a2 cd 10 00 	movl   $0x10cda2,(%esp)
  105a63:	e8 00 af ff ff       	call   100968 <debug_panic>
	}

	if (cmd & SYS_SNAP)
  105a68:	8b 45 0c             	mov    0xc(%ebp),%eax
  105a6b:	25 00 00 04 00       	and    $0x40000,%eax
  105a70:	85 c0                	test   %eax,%eax
  105a72:	74 1b                	je     105a8f <do_get+0x3f9>
		systrap(tf, T_GPFLT, 0);	// only valid for PUT
  105a74:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  105a7b:	00 
  105a7c:	c7 44 24 04 0d 00 00 	movl   $0xd,0x4(%esp)
  105a83:	00 
  105a84:	8b 45 08             	mov    0x8(%ebp),%eax
  105a87:	89 04 24             	mov    %eax,(%esp)
  105a8a:	e8 35 f5 ff ff       	call   104fc4 <systrap>
  trap_return(tf);  // syscall completed
  105a8f:	8b 45 08             	mov    0x8(%ebp),%eax
  105a92:	89 04 24             	mov    %eax,(%esp)
  105a95:	e8 c6 db ff ff       	call   103660 <trap_return>

00105a9a <do_ret>:
}

static void gcc_noreturn
do_ret(trapframe *tf)
{
  105a9a:	55                   	push   %ebp
  105a9b:	89 e5                	mov    %esp,%ebp
  105a9d:	83 ec 08             	sub    $0x8,%esp
//cprintf("RET proc %x eip %x esp %x\n", proc_cur(), tf->eip, tf->esp);
	proc_ret(tf, 1);	// Complete syscall insn and return to parent
  105aa0:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  105aa7:	00 
  105aa8:	8b 45 08             	mov    0x8(%ebp),%eax
  105aab:	89 04 24             	mov    %eax,(%esp)
  105aae:	e8 22 ed ff ff       	call   1047d5 <proc_ret>

00105ab3 <syscall>:
}


// Common function to handle all system calls -
// decode the system call type and call an appropriate handler function.
// Be sure to handle undefined system calls appropriately.
void
syscall(trapframe *tf)
{
  105ab3:	55                   	push   %ebp
  105ab4:	89 e5                	mov    %esp,%ebp
  105ab6:	83 ec 28             	sub    $0x28,%esp
	// EAX register holds system call command/flags
	uint32_t cmd = tf->regs.eax;
  105ab9:	8b 45 08             	mov    0x8(%ebp),%eax
  105abc:	8b 40 1c             	mov    0x1c(%eax),%eax
  105abf:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	switch (cmd & SYS_TYPE) {
  105ac2:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  105ac5:	83 e0 0f             	and    $0xf,%eax
  105ac8:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  105acb:	83 7d ec 01          	cmpl   $0x1,0xffffffec(%ebp)
  105acf:	74 28                	je     105af9 <syscall+0x46>
  105ad1:	83 7d ec 01          	cmpl   $0x1,0xffffffec(%ebp)
  105ad5:	72 0e                	jb     105ae5 <syscall+0x32>
  105ad7:	83 7d ec 02          	cmpl   $0x2,0xffffffec(%ebp)
  105adb:	74 30                	je     105b0d <syscall+0x5a>
  105add:	83 7d ec 03          	cmpl   $0x3,0xffffffec(%ebp)
  105ae1:	74 3e                	je     105b21 <syscall+0x6e>
  105ae3:	eb 47                	jmp    105b2c <syscall+0x79>
	case SYS_CPUTS:	return do_cputs(tf, cmd);
  105ae5:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  105ae8:	89 44 24 04          	mov    %eax,0x4(%esp)
  105aec:	8b 45 08             	mov    0x8(%ebp),%eax
  105aef:	89 04 24             	mov    %eax,(%esp)
  105af2:	e8 e5 f6 ff ff       	call   1051dc <do_cputs>
  105af7:	eb 33                	jmp    105b2c <syscall+0x79>
	case SYS_PUT:	return do_put(tf, cmd);
  105af9:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  105afc:	89 44 24 04          	mov    %eax,0x4(%esp)
  105b00:	8b 45 08             	mov    0x8(%ebp),%eax
  105b03:	89 04 24             	mov    %eax,(%esp)
  105b06:	e8 2e f7 ff ff       	call   105239 <do_put>
  105b0b:	eb 1f                	jmp    105b2c <syscall+0x79>
	case SYS_GET:	return do_get(tf, cmd);
  105b0d:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  105b10:	89 44 24 04          	mov    %eax,0x4(%esp)
  105b14:	8b 45 08             	mov    0x8(%ebp),%eax
  105b17:	89 04 24             	mov    %eax,(%esp)
  105b1a:	e8 77 fb ff ff       	call   105696 <do_get>
  105b1f:	eb 0b                	jmp    105b2c <syscall+0x79>
	case SYS_RET:	return do_ret(tf);
  105b21:	8b 45 08             	mov    0x8(%ebp),%eax
  105b24:	89 04 24             	mov    %eax,(%esp)
  105b27:	e8 6e ff ff ff       	call   105a9a <do_ret>
	default:	return;		// handle as a regular trap
	}
}
  105b2c:	c9                   	leave  
  105b2d:	c3                   	ret    
  105b2e:	90                   	nop    
  105b2f:	90                   	nop    

00105b30 <pmap_init>:
// The user part of the address space remains all PTE_ZERO until later.
//
void
pmap_init(void)
{
  105b30:	55                   	push   %ebp
  105b31:	89 e5                	mov    %esp,%ebp
  105b33:	83 ec 28             	sub    $0x28,%esp
	if (cpu_onboot()) {
  105b36:	e8 bc 00 00 00       	call   105bf7 <cpu_onboot>
  105b3b:	85 c0                	test   %eax,%eax
  105b3d:	74 51                	je     105b90 <pmap_init+0x60>

    	int a;
    	for (a = 0; a < NPDENTRIES; a++)
  105b3f:	c7 45 e8 00 00 00 00 	movl   $0x0,0xffffffe8(%ebp)
  105b46:	eb 19                	jmp    105b61 <pmap_init+0x31>
    		pmap_bootpdir[a] = (a << PDXSHIFT) | PTE_P | PTE_W | PTE_PS | PTE_G;
  105b48:	8b 55 e8             	mov    0xffffffe8(%ebp),%edx
  105b4b:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  105b4e:	c1 e0 16             	shl    $0x16,%eax
  105b51:	0d 83 01 00 00       	or     $0x183,%eax
  105b56:	89 04 95 00 00 18 00 	mov    %eax,0x180000(,%edx,4)
  105b5d:	83 45 e8 01          	addl   $0x1,0xffffffe8(%ebp)
  105b61:	81 7d e8 ff 03 00 00 	cmpl   $0x3ff,0xffffffe8(%ebp)
  105b68:	7e de                	jle    105b48 <pmap_init+0x18>
    	for (a = PDX(VM_USERLO); a < PDX(VM_USERHI); a++)
  105b6a:	c7 45 e8 00 01 00 00 	movl   $0x100,0xffffffe8(%ebp)
  105b71:	eb 13                	jmp    105b86 <pmap_init+0x56>
    		pmap_bootpdir[a] = PTE_ZERO;
  105b73:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  105b76:	ba 00 10 18 00       	mov    $0x181000,%edx
  105b7b:	89 14 85 00 00 18 00 	mov    %edx,0x180000(,%eax,4)
  105b82:	83 45 e8 01          	addl   $0x1,0xffffffe8(%ebp)
  105b86:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  105b89:	3d bf 03 00 00       	cmp    $0x3bf,%eax
  105b8e:	76 e3                	jbe    105b73 <pmap_init+0x43>
static gcc_inline uint32_t
rcr4(void)
{
	uint32_t cr4;
	__asm __volatile("movl %%cr4,%0" : "=r" (cr4));
  105b90:	0f 20 e0             	mov    %cr4,%eax
  105b93:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
	return cr4;
  105b96:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
	}

	uint32_t cr4 = rcr4();
  105b99:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)
	cr4 |= CR4_PSE | CR4_PGE;
  105b9c:	81 4d e0 90 00 00 00 	orl    $0x90,0xffffffe0(%ebp)
  	cr4 |= CR4_OSFXSR | CR4_OSXMMEXCPT;
  105ba3:	81 4d e0 00 06 00 00 	orl    $0x600,0xffffffe0(%ebp)
  105baa:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  105bad:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)

static gcc_inline void
lcr4(uint32_t val)
{
	__asm __volatile("movl %0,%%cr4" : : "r" (val));
  105bb0:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  105bb3:	0f 22 e0             	mov    %eax,%cr4
	lcr4(cr4);
	lcr3(mem_phys(pmap_bootpdir));
  105bb6:	b8 00 00 18 00       	mov    $0x180000,%eax
  105bbb:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)

static gcc_inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
  105bbe:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  105bc1:	0f 22 d8             	mov    %eax,%cr3
  105bc4:	0f 20 c0             	mov    %cr0,%eax
  105bc7:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  105bca:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax

	uint32_t cr0 = rcr0();
  105bcd:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_TS|CR0_MP|CR0_TS;
  105bd0:	81 4d e4 2b 00 05 80 	orl    $0x8005002b,0xffffffe4(%ebp)
	cr0 &= ~(CR0_EM);
  105bd7:	83 65 e4 fb          	andl   $0xfffffffb,0xffffffe4(%ebp)
  105bdb:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  105bde:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)

static gcc_inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
  105be1:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  105be4:	0f 22 c0             	mov    %eax,%cr0
	lcr0(cr0);

	// If we survived the lcr0, we're running with paging enabled.
	// Now check the page table management functions below.
	if (cpu_onboot())
  105be7:	e8 0b 00 00 00       	call   105bf7 <cpu_onboot>
  105bec:	85 c0                	test   %eax,%eax
  105bee:	74 05                	je     105bf5 <pmap_init+0xc5>
		pmap_check();
  105bf0:	e8 1c 26 00 00       	call   108211 <pmap_check>
}
  105bf5:	c9                   	leave  
  105bf6:	c3                   	ret    

00105bf7 <cpu_onboot>:
}

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  105bf7:	55                   	push   %ebp
  105bf8:	89 e5                	mov    %esp,%ebp
  105bfa:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  105bfd:	e8 0d 00 00 00       	call   105c0f <cpu_cur>
  105c02:	3d 00 e0 10 00       	cmp    $0x10e000,%eax
  105c07:	0f 94 c0             	sete   %al
  105c0a:	0f b6 c0             	movzbl %al,%eax
}
  105c0d:	c9                   	leave  
  105c0e:	c3                   	ret    

00105c0f <cpu_cur>:
  105c0f:	55                   	push   %ebp
  105c10:	89 e5                	mov    %esp,%ebp
  105c12:	83 ec 28             	sub    $0x28,%esp
static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  105c15:	89 65 fc             	mov    %esp,0xfffffffc(%ebp)
        return esp;
  105c18:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  105c1b:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  105c1e:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  105c21:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  105c26:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	assert(c->magic == CPU_MAGIC);
  105c29:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  105c2c:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  105c32:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  105c37:	74 24                	je     105c5d <cpu_cur+0x4e>
  105c39:	c7 44 24 0c 88 ce 10 	movl   $0x10ce88,0xc(%esp)
  105c40:	00 
  105c41:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  105c48:	00 
  105c49:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  105c50:	00 
  105c51:	c7 04 24 b3 ce 10 00 	movl   $0x10ceb3,(%esp)
  105c58:	e8 0b ad ff ff       	call   100968 <debug_panic>
	return c;
  105c5d:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
}
  105c60:	c9                   	leave  
  105c61:	c3                   	ret    

00105c62 <pmap_newpdir>:

//
// Allocate a new page directory, initialized from the bootstrap pdir.
// Returns the new pdir with a reference count of 1.
//
pte_t *
pmap_newpdir(void)
{
  105c62:	55                   	push   %ebp
  105c63:	89 e5                	mov    %esp,%ebp
  105c65:	83 ec 28             	sub    $0x28,%esp
	pageinfo *pi = mem_alloc();
  105c68:	e8 de b3 ff ff       	call   10104b <mem_alloc>
  105c6d:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	if (pi == NULL)
  105c70:	83 7d f4 00          	cmpl   $0x0,0xfffffff4(%ebp)
  105c74:	75 0c                	jne    105c82 <pmap_newpdir+0x20>
		return NULL;
  105c76:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  105c7d:	e9 2f 01 00 00       	jmp    105db1 <pmap_newpdir+0x14f>
  105c82:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  105c85:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
// Atomically increment the reference count on a page.
static gcc_inline void
mem_incref(pageinfo *pi)
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  105c88:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  105c8d:	83 c0 08             	add    $0x8,%eax
  105c90:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  105c93:	73 17                	jae    105cac <pmap_newpdir+0x4a>
  105c95:	a1 84 ed 17 00       	mov    0x17ed84,%eax
  105c9a:	c1 e0 03             	shl    $0x3,%eax
  105c9d:	89 c2                	mov    %eax,%edx
  105c9f:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  105ca4:	8d 04 02             	lea    (%edx,%eax,1),%eax
  105ca7:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  105caa:	77 24                	ja     105cd0 <pmap_newpdir+0x6e>
  105cac:	c7 44 24 0c c0 ce 10 	movl   $0x10cec0,0xc(%esp)
  105cb3:	00 
  105cb4:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  105cbb:	00 
  105cbc:	c7 44 24 04 8e 00 00 	movl   $0x8e,0x4(%esp)
  105cc3:	00 
  105cc4:	c7 04 24 f7 ce 10 00 	movl   $0x10cef7,(%esp)
  105ccb:	e8 98 ac ff ff       	call   100968 <debug_panic>
	assert(pi != mem_ptr2pi(pmap_zero));	// Don't alloc/free zero page!
  105cd0:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  105cd6:	b8 00 10 18 00       	mov    $0x181000,%eax
  105cdb:	c1 e8 0c             	shr    $0xc,%eax
  105cde:	c1 e0 03             	shl    $0x3,%eax
  105ce1:	8d 04 02             	lea    (%edx,%eax,1),%eax
  105ce4:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  105ce7:	75 24                	jne    105d0d <pmap_newpdir+0xab>
  105ce9:	c7 44 24 0c 04 cf 10 	movl   $0x10cf04,0xc(%esp)
  105cf0:	00 
  105cf1:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  105cf8:	00 
  105cf9:	c7 44 24 04 8f 00 00 	movl   $0x8f,0x4(%esp)
  105d00:	00 
  105d01:	c7 04 24 f7 ce 10 00 	movl   $0x10cef7,(%esp)
  105d08:	e8 5b ac ff ff       	call   100968 <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  105d0d:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  105d13:	b8 0c 00 10 00       	mov    $0x10000c,%eax
  105d18:	c1 e8 0c             	shr    $0xc,%eax
  105d1b:	c1 e0 03             	shl    $0x3,%eax
  105d1e:	8d 04 02             	lea    (%edx,%eax,1),%eax
  105d21:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  105d24:	77 40                	ja     105d66 <pmap_newpdir+0x104>
  105d26:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  105d2c:	b8 08 20 18 00       	mov    $0x182008,%eax
  105d31:	83 e8 01             	sub    $0x1,%eax
  105d34:	c1 e8 0c             	shr    $0xc,%eax
  105d37:	c1 e0 03             	shl    $0x3,%eax
  105d3a:	8d 04 02             	lea    (%edx,%eax,1),%eax
  105d3d:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  105d40:	72 24                	jb     105d66 <pmap_newpdir+0x104>
  105d42:	c7 44 24 0c 20 cf 10 	movl   $0x10cf20,0xc(%esp)
  105d49:	00 
  105d4a:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  105d51:	00 
  105d52:	c7 44 24 04 90 00 00 	movl   $0x90,0x4(%esp)
  105d59:	00 
  105d5a:	c7 04 24 f7 ce 10 00 	movl   $0x10cef7,(%esp)
  105d61:	e8 02 ac ff ff       	call   100968 <debug_panic>

	lockadd(&pi->refcount, 1);
  105d66:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  105d69:	83 c0 04             	add    $0x4,%eax
  105d6c:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  105d73:	00 
  105d74:	89 04 24             	mov    %eax,(%esp)
  105d77:	e8 3a 00 00 00       	call   105db6 <lockadd>
	mem_incref(pi);
	pte_t *pdir = mem_pi2ptr(pi);
  105d7c:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  105d7f:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  105d84:	89 d1                	mov    %edx,%ecx
  105d86:	29 c1                	sub    %eax,%ecx
  105d88:	89 c8                	mov    %ecx,%eax
  105d8a:	c1 e0 09             	shl    $0x9,%eax
  105d8d:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)

	// Initialize it from the bootstrap page directory
	assert(sizeof(pmap_bootpdir) == PAGESIZE);
	memmove(pdir, pmap_bootpdir, PAGESIZE);
  105d90:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  105d97:	00 
  105d98:	c7 44 24 04 00 00 18 	movl   $0x180000,0x4(%esp)
  105d9f:	00 
  105da0:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  105da3:	89 04 24             	mov    %eax,(%esp)
  105da6:	e8 c3 5a 00 00       	call   10b86e <memmove>

	return pdir;
  105dab:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  105dae:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  105db1:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
}
  105db4:	c9                   	leave  
  105db5:	c3                   	ret    

00105db6 <lockadd>:

// Atomically add incr to *addr.
static inline void
lockadd(volatile int32_t *addr, int32_t incr)
{
  105db6:	55                   	push   %ebp
  105db7:	89 e5                	mov    %esp,%ebp
	asm volatile("lock; addl %1,%0" : "+m" (*addr) : "r" (incr) : "cc");
  105db9:	8b 4d 08             	mov    0x8(%ebp),%ecx
  105dbc:	8b 55 0c             	mov    0xc(%ebp),%edx
  105dbf:	8b 45 08             	mov    0x8(%ebp),%eax
  105dc2:	f0 01 11             	lock add %edx,(%ecx)
}
  105dc5:	5d                   	pop    %ebp
  105dc6:	c3                   	ret    

00105dc7 <pmap_freepdir>:

// Free a page directory, and all page tables and mappings it may contain.
void
pmap_freepdir(pageinfo *pdirpi)
{
  105dc7:	55                   	push   %ebp
  105dc8:	89 e5                	mov    %esp,%ebp
  105dca:	83 ec 18             	sub    $0x18,%esp
	pmap_remove(mem_pi2ptr(pdirpi), VM_USERLO, VM_USERHI-VM_USERLO);
  105dcd:	8b 55 08             	mov    0x8(%ebp),%edx
  105dd0:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  105dd5:	89 d1                	mov    %edx,%ecx
  105dd7:	29 c1                	sub    %eax,%ecx
  105dd9:	89 c8                	mov    %ecx,%eax
  105ddb:	c1 e0 09             	shl    $0x9,%eax
  105dde:	c7 44 24 08 00 00 00 	movl   $0xb0000000,0x8(%esp)
  105de5:	b0 
  105de6:	c7 44 24 04 00 00 00 	movl   $0x40000000,0x4(%esp)
  105ded:	40 
  105dee:	89 04 24             	mov    %eax,(%esp)
  105df1:	e8 0f 0a 00 00       	call   106805 <pmap_remove>
	mem_free(pdirpi);
  105df6:	8b 45 08             	mov    0x8(%ebp),%eax
  105df9:	89 04 24             	mov    %eax,(%esp)
  105dfc:	e8 8e b2 ff ff       	call   10108f <mem_free>
}
  105e01:	c9                   	leave  
  105e02:	c3                   	ret    

00105e03 <pmap_freeptab>:

// Free a page table and all page mappings it may contain.
void
pmap_freeptab(pageinfo *ptabpi)
{
  105e03:	55                   	push   %ebp
  105e04:	89 e5                	mov    %esp,%ebp
  105e06:	83 ec 38             	sub    $0x38,%esp
	pte_t *pte = mem_pi2ptr(ptabpi), *ptelim = pte + NPTENTRIES;
  105e09:	8b 55 08             	mov    0x8(%ebp),%edx
  105e0c:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  105e11:	89 d1                	mov    %edx,%ecx
  105e13:	29 c1                	sub    %eax,%ecx
  105e15:	89 c8                	mov    %ecx,%eax
  105e17:	c1 e0 09             	shl    $0x9,%eax
  105e1a:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  105e1d:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  105e20:	05 00 10 00 00       	add    $0x1000,%eax
  105e25:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
	for (; pte < ptelim; pte++) {
  105e28:	e9 6d 01 00 00       	jmp    105f9a <pmap_freeptab+0x197>
		uint32_t pgaddr = PGADDR(*pte);
  105e2d:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  105e30:	8b 00                	mov    (%eax),%eax
  105e32:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  105e37:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
		if (pgaddr != PTE_ZERO)
  105e3a:	b8 00 10 18 00       	mov    $0x181000,%eax
  105e3f:	39 45 f4             	cmp    %eax,0xfffffff4(%ebp)
  105e42:	0f 84 4e 01 00 00    	je     105f96 <pmap_freeptab+0x193>
			mem_decref(mem_phys2pi(pgaddr), mem_free);
  105e48:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  105e4b:	c1 e8 0c             	shr    $0xc,%eax
  105e4e:	c1 e0 03             	shl    $0x3,%eax
  105e51:	89 c2                	mov    %eax,%edx
  105e53:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  105e58:	8d 04 02             	lea    (%edx,%eax,1),%eax
  105e5b:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  105e5e:	c7 45 f8 8f 10 10 00 	movl   $0x10108f,0xfffffff8(%ebp)
// freeing the page with the provided function if there are no more refs.
static gcc_inline void
mem_decref(pageinfo* pi, void (*freefun)(pageinfo *pi))
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  105e65:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  105e6a:	83 c0 08             	add    $0x8,%eax
  105e6d:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  105e70:	73 17                	jae    105e89 <pmap_freeptab+0x86>
  105e72:	a1 84 ed 17 00       	mov    0x17ed84,%eax
  105e77:	c1 e0 03             	shl    $0x3,%eax
  105e7a:	89 c2                	mov    %eax,%edx
  105e7c:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  105e81:	8d 04 02             	lea    (%edx,%eax,1),%eax
  105e84:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  105e87:	77 24                	ja     105ead <pmap_freeptab+0xaa>
  105e89:	c7 44 24 0c c0 ce 10 	movl   $0x10cec0,0xc(%esp)
  105e90:	00 
  105e91:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  105e98:	00 
  105e99:	c7 44 24 04 9a 00 00 	movl   $0x9a,0x4(%esp)
  105ea0:	00 
  105ea1:	c7 04 24 f7 ce 10 00 	movl   $0x10cef7,(%esp)
  105ea8:	e8 bb aa ff ff       	call   100968 <debug_panic>
	assert(pi != mem_ptr2pi(pmap_zero));	// Don't alloc/free zero page!
  105ead:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  105eb3:	b8 00 10 18 00       	mov    $0x181000,%eax
  105eb8:	c1 e8 0c             	shr    $0xc,%eax
  105ebb:	c1 e0 03             	shl    $0x3,%eax
  105ebe:	8d 04 02             	lea    (%edx,%eax,1),%eax
  105ec1:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  105ec4:	75 24                	jne    105eea <pmap_freeptab+0xe7>
  105ec6:	c7 44 24 0c 04 cf 10 	movl   $0x10cf04,0xc(%esp)
  105ecd:	00 
  105ece:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  105ed5:	00 
  105ed6:	c7 44 24 04 9b 00 00 	movl   $0x9b,0x4(%esp)
  105edd:	00 
  105ede:	c7 04 24 f7 ce 10 00 	movl   $0x10cef7,(%esp)
  105ee5:	e8 7e aa ff ff       	call   100968 <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  105eea:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  105ef0:	b8 0c 00 10 00       	mov    $0x10000c,%eax
  105ef5:	c1 e8 0c             	shr    $0xc,%eax
  105ef8:	c1 e0 03             	shl    $0x3,%eax
  105efb:	8d 04 02             	lea    (%edx,%eax,1),%eax
  105efe:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  105f01:	77 40                	ja     105f43 <pmap_freeptab+0x140>
  105f03:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  105f09:	b8 08 20 18 00       	mov    $0x182008,%eax
  105f0e:	83 e8 01             	sub    $0x1,%eax
  105f11:	c1 e8 0c             	shr    $0xc,%eax
  105f14:	c1 e0 03             	shl    $0x3,%eax
  105f17:	8d 04 02             	lea    (%edx,%eax,1),%eax
  105f1a:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  105f1d:	72 24                	jb     105f43 <pmap_freeptab+0x140>
  105f1f:	c7 44 24 0c 20 cf 10 	movl   $0x10cf20,0xc(%esp)
  105f26:	00 
  105f27:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  105f2e:	00 
  105f2f:	c7 44 24 04 9c 00 00 	movl   $0x9c,0x4(%esp)
  105f36:	00 
  105f37:	c7 04 24 f7 ce 10 00 	movl   $0x10cef7,(%esp)
  105f3e:	e8 25 aa ff ff       	call   100968 <debug_panic>

	if (lockaddz(&pi->refcount, -1))
  105f43:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  105f46:	83 c0 04             	add    $0x4,%eax
  105f49:	c7 44 24 04 ff ff ff 	movl   $0xffffffff,0x4(%esp)
  105f50:	ff 
  105f51:	89 04 24             	mov    %eax,(%esp)
  105f54:	e8 5a 00 00 00       	call   105fb3 <lockaddz>
  105f59:	84 c0                	test   %al,%al
  105f5b:	74 0b                	je     105f68 <pmap_freeptab+0x165>
			freefun(pi);
  105f5d:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  105f60:	89 04 24             	mov    %eax,(%esp)
  105f63:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  105f66:	ff d0                	call   *%eax
	assert(pi->refcount >= 0);
  105f68:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  105f6b:	8b 40 04             	mov    0x4(%eax),%eax
  105f6e:	85 c0                	test   %eax,%eax
  105f70:	79 24                	jns    105f96 <pmap_freeptab+0x193>
  105f72:	c7 44 24 0c 51 cf 10 	movl   $0x10cf51,0xc(%esp)
  105f79:	00 
  105f7a:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  105f81:	00 
  105f82:	c7 44 24 04 a0 00 00 	movl   $0xa0,0x4(%esp)
  105f89:	00 
  105f8a:	c7 04 24 f7 ce 10 00 	movl   $0x10cef7,(%esp)
  105f91:	e8 d2 a9 ff ff       	call   100968 <debug_panic>
  105f96:	83 45 ec 04          	addl   $0x4,0xffffffec(%ebp)
  105f9a:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  105f9d:	3b 45 f0             	cmp    0xfffffff0(%ebp),%eax
  105fa0:	0f 82 87 fe ff ff    	jb     105e2d <pmap_freeptab+0x2a>
	}
	mem_free(ptabpi);
  105fa6:	8b 45 08             	mov    0x8(%ebp),%eax
  105fa9:	89 04 24             	mov    %eax,(%esp)
  105fac:	e8 de b0 ff ff       	call   10108f <mem_free>
}
  105fb1:	c9                   	leave  
  105fb2:	c3                   	ret    

00105fb3 <lockaddz>:

// Atomically add incr to *addr and return true if the result is zero.
static inline uint8_t
lockaddz(volatile int32_t *addr, int32_t incr)
{
  105fb3:	55                   	push   %ebp
  105fb4:	89 e5                	mov    %esp,%ebp
  105fb6:	83 ec 10             	sub    $0x10,%esp
	uint8_t zero;
	asm volatile("lock; addl %2,%0; setzb %1"
  105fb9:	8b 4d 08             	mov    0x8(%ebp),%ecx
  105fbc:	8b 55 0c             	mov    0xc(%ebp),%edx
  105fbf:	8b 45 08             	mov    0x8(%ebp),%eax
  105fc2:	f0 01 11             	lock add %edx,(%ecx)
  105fc5:	0f 94 45 ff          	sete   0xffffffff(%ebp)
		: "+m" (*addr), "=rm" (zero)
		: "r" (incr)
		: "cc");
	return zero;
  105fc9:	0f b6 45 ff          	movzbl 0xffffffff(%ebp),%eax
}
  105fcd:	c9                   	leave  
  105fce:	c3                   	ret    

00105fcf <pmap_walk>:

// Given 'pdir', a pointer to a page directory, pmap_walk returns
// a pointer to the page table entry (PTE) for user virtual address 'va'.
// This requires walking the two-level page table structure.
//
// If the relevant page table doesn't exist in the page directory, then:
//    - If writing == 0, pmap_walk returns NULL.
//    - Otherwise, pmap_walk tries to allocate a new page table
//	with mem_alloc.  If this fails, pmap_walk returns NULL.
//    - The new page table is cleared and its refcount set to 1.
//    - Finally, pmap_walk returns a pointer to the requested entry
//	within the new page table.
//
// If the relevant page table does already exist in the page directory,
// but it is read shared and writing != 0, then copy the page table
// to obtain an exclusive copy of it and write-enable the PDE.
//
// Hint: you can turn a pageinfo pointer into the physical address of the
// page it refers to with mem_pi2phys() from kern/mem.h.
//
// Hint 2: the x86 MMU checks permission bits in both the page directory
// and the page table, so it's safe to leave some page permissions
// more permissive than strictly necessary.
pte_t *
pmap_walk(pde_t *pdir, uint32_t va, bool writing)
{
  105fcf:	55                   	push   %ebp
  105fd0:	89 e5                	mov    %esp,%ebp
  105fd2:	83 ec 58             	sub    $0x58,%esp
  assert(va >= VM_USERLO && va < VM_USERHI);
  105fd5:	81 7d 0c ff ff ff 3f 	cmpl   $0x3fffffff,0xc(%ebp)
  105fdc:	76 09                	jbe    105fe7 <pmap_walk+0x18>
  105fde:	81 7d 0c ff ff ff ef 	cmpl   $0xefffffff,0xc(%ebp)
  105fe5:	76 24                	jbe    10600b <pmap_walk+0x3c>
  105fe7:	c7 44 24 0c 64 cf 10 	movl   $0x10cf64,0xc(%esp)
  105fee:	00 
  105fef:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  105ff6:	00 
  105ff7:	c7 44 24 04 8f 00 00 	movl   $0x8f,0x4(%esp)
  105ffe:	00 
  105fff:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  106006:	e8 5d a9 ff ff       	call   100968 <debug_panic>

  uint32_t la = va;
  10600b:	8b 45 0c             	mov    0xc(%ebp),%eax
  10600e:	89 45 c4             	mov    %eax,0xffffffc4(%ebp)
  pde_t *pde = &pdir[PDX(la)];
  106011:	8b 45 c4             	mov    0xffffffc4(%ebp),%eax
  106014:	c1 e8 16             	shr    $0x16,%eax
  106017:	25 ff 03 00 00       	and    $0x3ff,%eax
  10601c:	c1 e0 02             	shl    $0x2,%eax
  10601f:	03 45 08             	add    0x8(%ebp),%eax
  106022:	89 45 c8             	mov    %eax,0xffffffc8(%ebp)
  pte_t *ptab;
  if (*pde & PTE_P)
  106025:	8b 45 c8             	mov    0xffffffc8(%ebp),%eax
  106028:	8b 00                	mov    (%eax),%eax
  10602a:	83 e0 01             	and    $0x1,%eax
  10602d:	84 c0                	test   %al,%al
  10602f:	74 12                	je     106043 <pmap_walk+0x74>
  {
  	ptab = mem_ptr(PGADDR(*pde));
  106031:	8b 45 c8             	mov    0xffffffc8(%ebp),%eax
  106034:	8b 00                	mov    (%eax),%eax
  106036:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  10603b:	89 45 cc             	mov    %eax,0xffffffcc(%ebp)
  10603e:	e9 a3 01 00 00       	jmp    1061e6 <pmap_walk+0x217>
  } 
  else 
  {
  assert(*pde == PTE_ZERO);
  106043:	8b 45 c8             	mov    0xffffffc8(%ebp),%eax
  106046:	8b 10                	mov    (%eax),%edx
  106048:	b8 00 10 18 00       	mov    $0x181000,%eax
  10604d:	39 c2                	cmp    %eax,%edx
  10604f:	74 24                	je     106075 <pmap_walk+0xa6>
  106051:	c7 44 24 0c 92 cf 10 	movl   $0x10cf92,0xc(%esp)
  106058:	00 
  106059:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  106060:	00 
  106061:	c7 44 24 04 9a 00 00 	movl   $0x9a,0x4(%esp)
  106068:	00 
  106069:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  106070:	e8 f3 a8 ff ff       	call   100968 <debug_panic>
  pageinfo *pi;
  	if (!writing || (pi = mem_alloc()) == NULL)
  106075:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  106079:	74 0e                	je     106089 <pmap_walk+0xba>
  10607b:	e8 cb af ff ff       	call   10104b <mem_alloc>
  106080:	89 45 d0             	mov    %eax,0xffffffd0(%ebp)
  106083:	83 7d d0 00          	cmpl   $0x0,0xffffffd0(%ebp)
  106087:	75 0c                	jne    106095 <pmap_walk+0xc6>
  		return NULL;
  106089:	c7 45 bc 00 00 00 00 	movl   $0x0,0xffffffbc(%ebp)
  106090:	e9 ed 05 00 00       	jmp    106682 <pmap_walk+0x6b3>
  106095:	8b 45 d0             	mov    0xffffffd0(%ebp),%eax
  106098:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
// Atomically increment the reference count on a page.
static gcc_inline void
mem_incref(pageinfo *pi)
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  10609b:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  1060a0:	83 c0 08             	add    $0x8,%eax
  1060a3:	3b 45 ec             	cmp    0xffffffec(%ebp),%eax
  1060a6:	73 17                	jae    1060bf <pmap_walk+0xf0>
  1060a8:	a1 84 ed 17 00       	mov    0x17ed84,%eax
  1060ad:	c1 e0 03             	shl    $0x3,%eax
  1060b0:	89 c2                	mov    %eax,%edx
  1060b2:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  1060b7:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1060ba:	3b 45 ec             	cmp    0xffffffec(%ebp),%eax
  1060bd:	77 24                	ja     1060e3 <pmap_walk+0x114>
  1060bf:	c7 44 24 0c c0 ce 10 	movl   $0x10cec0,0xc(%esp)
  1060c6:	00 
  1060c7:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  1060ce:	00 
  1060cf:	c7 44 24 04 8e 00 00 	movl   $0x8e,0x4(%esp)
  1060d6:	00 
  1060d7:	c7 04 24 f7 ce 10 00 	movl   $0x10cef7,(%esp)
  1060de:	e8 85 a8 ff ff       	call   100968 <debug_panic>
	assert(pi != mem_ptr2pi(pmap_zero));	// Don't alloc/free zero page!
  1060e3:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  1060e9:	b8 00 10 18 00       	mov    $0x181000,%eax
  1060ee:	c1 e8 0c             	shr    $0xc,%eax
  1060f1:	c1 e0 03             	shl    $0x3,%eax
  1060f4:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1060f7:	3b 45 ec             	cmp    0xffffffec(%ebp),%eax
  1060fa:	75 24                	jne    106120 <pmap_walk+0x151>
  1060fc:	c7 44 24 0c 04 cf 10 	movl   $0x10cf04,0xc(%esp)
  106103:	00 
  106104:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  10610b:	00 
  10610c:	c7 44 24 04 8f 00 00 	movl   $0x8f,0x4(%esp)
  106113:	00 
  106114:	c7 04 24 f7 ce 10 00 	movl   $0x10cef7,(%esp)
  10611b:	e8 48 a8 ff ff       	call   100968 <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  106120:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  106126:	b8 0c 00 10 00       	mov    $0x10000c,%eax
  10612b:	c1 e8 0c             	shr    $0xc,%eax
  10612e:	c1 e0 03             	shl    $0x3,%eax
  106131:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106134:	3b 45 ec             	cmp    0xffffffec(%ebp),%eax
  106137:	77 40                	ja     106179 <pmap_walk+0x1aa>
  106139:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  10613f:	b8 08 20 18 00       	mov    $0x182008,%eax
  106144:	83 e8 01             	sub    $0x1,%eax
  106147:	c1 e8 0c             	shr    $0xc,%eax
  10614a:	c1 e0 03             	shl    $0x3,%eax
  10614d:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106150:	3b 45 ec             	cmp    0xffffffec(%ebp),%eax
  106153:	72 24                	jb     106179 <pmap_walk+0x1aa>
  106155:	c7 44 24 0c 20 cf 10 	movl   $0x10cf20,0xc(%esp)
  10615c:	00 
  10615d:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  106164:	00 
  106165:	c7 44 24 04 90 00 00 	movl   $0x90,0x4(%esp)
  10616c:	00 
  10616d:	c7 04 24 f7 ce 10 00 	movl   $0x10cef7,(%esp)
  106174:	e8 ef a7 ff ff       	call   100968 <debug_panic>

	lockadd(&pi->refcount, 1);
  106179:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  10617c:	83 c0 04             	add    $0x4,%eax
  10617f:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  106186:	00 
  106187:	89 04 24             	mov    %eax,(%esp)
  10618a:	e8 27 fc ff ff       	call   105db6 <lockadd>
  mem_incref(pi);
  ptab = mem_pi2ptr(pi);
  10618f:	8b 55 d0             	mov    0xffffffd0(%ebp),%edx
  106192:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  106197:	89 d1                	mov    %edx,%ecx
  106199:	29 c1                	sub    %eax,%ecx
  10619b:	89 c8                	mov    %ecx,%eax
  10619d:	c1 e0 09             	shl    $0x9,%eax
  1061a0:	89 45 cc             	mov    %eax,0xffffffcc(%ebp)

  int i;
  for (i = 0; i < NPTENTRIES; i++)
  1061a3:	c7 45 d4 00 00 00 00 	movl   $0x0,0xffffffd4(%ebp)
  1061aa:	eb 16                	jmp    1061c2 <pmap_walk+0x1f3>
  	ptab[i] = PTE_ZERO;
  1061ac:	8b 45 d4             	mov    0xffffffd4(%ebp),%eax
  1061af:	c1 e0 02             	shl    $0x2,%eax
  1061b2:	89 c2                	mov    %eax,%edx
  1061b4:	03 55 cc             	add    0xffffffcc(%ebp),%edx
  1061b7:	b8 00 10 18 00       	mov    $0x181000,%eax
  1061bc:	89 02                	mov    %eax,(%edx)
  1061be:	83 45 d4 01          	addl   $0x1,0xffffffd4(%ebp)
  1061c2:	81 7d d4 ff 03 00 00 	cmpl   $0x3ff,0xffffffd4(%ebp)
  1061c9:	7e e1                	jle    1061ac <pmap_walk+0x1dd>

  *pde = mem_pi2phys(pi) | PTE_A | PTE_P | PTE_W | PTE_U;
  1061cb:	8b 55 d0             	mov    0xffffffd0(%ebp),%edx
  1061ce:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  1061d3:	89 d1                	mov    %edx,%ecx
  1061d5:	29 c1                	sub    %eax,%ecx
  1061d7:	89 c8                	mov    %ecx,%eax
  1061d9:	c1 e0 09             	shl    $0x9,%eax
  1061dc:	83 c8 27             	or     $0x27,%eax
  1061df:	89 c2                	mov    %eax,%edx
  1061e1:	8b 45 c8             	mov    0xffffffc8(%ebp),%eax
  1061e4:	89 10                	mov    %edx,(%eax)
  }
  
  if(writing && !(*pde & PTE_W)) 
  1061e6:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  1061ea:	0f 84 7c 04 00 00    	je     10666c <pmap_walk+0x69d>
  1061f0:	8b 45 c8             	mov    0xffffffc8(%ebp),%eax
  1061f3:	8b 00                	mov    (%eax),%eax
  1061f5:	83 e0 02             	and    $0x2,%eax
  1061f8:	85 c0                	test   %eax,%eax
  1061fa:	0f 85 6c 04 00 00    	jne    10666c <pmap_walk+0x69d>
  {
  	if(mem_ptr2pi(ptab) -> refcount == 1)
  106200:	8b 45 cc             	mov    0xffffffcc(%ebp),%eax
  106203:	c1 e8 0c             	shr    $0xc,%eax
  106206:	c1 e0 03             	shl    $0x3,%eax
  106209:	89 c2                	mov    %eax,%edx
  10620b:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  106210:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106213:	8b 40 04             	mov    0x4(%eax),%eax
  106216:	83 f8 01             	cmp    $0x1,%eax
  106219:	75 36                	jne    106251 <pmap_walk+0x282>
	{
  		int i;
  		for (i = 0; i < NPTENTRIES; i++)
  10621b:	c7 45 d8 00 00 00 00 	movl   $0x0,0xffffffd8(%ebp)
  106222:	eb 1f                	jmp    106243 <pmap_walk+0x274>
    			ptab[i] &= ~PTE_W;
  106224:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  106227:	c1 e0 02             	shl    $0x2,%eax
  10622a:	89 c2                	mov    %eax,%edx
  10622c:	03 55 cc             	add    0xffffffcc(%ebp),%edx
  10622f:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  106232:	c1 e0 02             	shl    $0x2,%eax
  106235:	03 45 cc             	add    0xffffffcc(%ebp),%eax
  106238:	8b 00                	mov    (%eax),%eax
  10623a:	83 e0 fd             	and    $0xfffffffd,%eax
  10623d:	89 02                	mov    %eax,(%edx)
  10623f:	83 45 d8 01          	addl   $0x1,0xffffffd8(%ebp)
  106243:	81 7d d8 ff 03 00 00 	cmpl   $0x3ff,0xffffffd8(%ebp)
  10624a:	7e d8                	jle    106224 <pmap_walk+0x255>
  10624c:	e9 0e 04 00 00       	jmp    10665f <pmap_walk+0x690>
    	} 
	else 
	{
    		pageinfo *pi = mem_alloc();
  106251:	e8 f5 ad ff ff       	call   10104b <mem_alloc>
  106256:	89 45 dc             	mov    %eax,0xffffffdc(%ebp)
    		if (pi==NULL)
  106259:	83 7d dc 00          	cmpl   $0x0,0xffffffdc(%ebp)
  10625d:	75 0c                	jne    10626b <pmap_walk+0x29c>
    			return NULL;
  10625f:	c7 45 bc 00 00 00 00 	movl   $0x0,0xffffffbc(%ebp)
  106266:	e9 17 04 00 00       	jmp    106682 <pmap_walk+0x6b3>
  10626b:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  10626e:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
// Atomically increment the reference count on a page.
static gcc_inline void
mem_incref(pageinfo *pi)
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  106271:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  106276:	83 c0 08             	add    $0x8,%eax
  106279:	3b 45 f0             	cmp    0xfffffff0(%ebp),%eax
  10627c:	73 17                	jae    106295 <pmap_walk+0x2c6>
  10627e:	a1 84 ed 17 00       	mov    0x17ed84,%eax
  106283:	c1 e0 03             	shl    $0x3,%eax
  106286:	89 c2                	mov    %eax,%edx
  106288:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  10628d:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106290:	3b 45 f0             	cmp    0xfffffff0(%ebp),%eax
  106293:	77 24                	ja     1062b9 <pmap_walk+0x2ea>
  106295:	c7 44 24 0c c0 ce 10 	movl   $0x10cec0,0xc(%esp)
  10629c:	00 
  10629d:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  1062a4:	00 
  1062a5:	c7 44 24 04 8e 00 00 	movl   $0x8e,0x4(%esp)
  1062ac:	00 
  1062ad:	c7 04 24 f7 ce 10 00 	movl   $0x10cef7,(%esp)
  1062b4:	e8 af a6 ff ff       	call   100968 <debug_panic>
	assert(pi != mem_ptr2pi(pmap_zero));	// Don't alloc/free zero page!
  1062b9:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  1062bf:	b8 00 10 18 00       	mov    $0x181000,%eax
  1062c4:	c1 e8 0c             	shr    $0xc,%eax
  1062c7:	c1 e0 03             	shl    $0x3,%eax
  1062ca:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1062cd:	3b 45 f0             	cmp    0xfffffff0(%ebp),%eax
  1062d0:	75 24                	jne    1062f6 <pmap_walk+0x327>
  1062d2:	c7 44 24 0c 04 cf 10 	movl   $0x10cf04,0xc(%esp)
  1062d9:	00 
  1062da:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  1062e1:	00 
  1062e2:	c7 44 24 04 8f 00 00 	movl   $0x8f,0x4(%esp)
  1062e9:	00 
  1062ea:	c7 04 24 f7 ce 10 00 	movl   $0x10cef7,(%esp)
  1062f1:	e8 72 a6 ff ff       	call   100968 <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  1062f6:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  1062fc:	b8 0c 00 10 00       	mov    $0x10000c,%eax
  106301:	c1 e8 0c             	shr    $0xc,%eax
  106304:	c1 e0 03             	shl    $0x3,%eax
  106307:	8d 04 02             	lea    (%edx,%eax,1),%eax
  10630a:	3b 45 f0             	cmp    0xfffffff0(%ebp),%eax
  10630d:	77 40                	ja     10634f <pmap_walk+0x380>
  10630f:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  106315:	b8 08 20 18 00       	mov    $0x182008,%eax
  10631a:	83 e8 01             	sub    $0x1,%eax
  10631d:	c1 e8 0c             	shr    $0xc,%eax
  106320:	c1 e0 03             	shl    $0x3,%eax
  106323:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106326:	3b 45 f0             	cmp    0xfffffff0(%ebp),%eax
  106329:	72 24                	jb     10634f <pmap_walk+0x380>
  10632b:	c7 44 24 0c 20 cf 10 	movl   $0x10cf20,0xc(%esp)
  106332:	00 
  106333:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  10633a:	00 
  10633b:	c7 44 24 04 90 00 00 	movl   $0x90,0x4(%esp)
  106342:	00 
  106343:	c7 04 24 f7 ce 10 00 	movl   $0x10cef7,(%esp)
  10634a:	e8 19 a6 ff ff       	call   100968 <debug_panic>

	lockadd(&pi->refcount, 1);
  10634f:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  106352:	83 c0 04             	add    $0x4,%eax
  106355:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  10635c:	00 
  10635d:	89 04 24             	mov    %eax,(%esp)
  106360:	e8 51 fa ff ff       	call   105db6 <lockadd>
    		mem_incref(pi);
    		pte_t *nptab = mem_pi2ptr(pi);
  106365:	8b 55 dc             	mov    0xffffffdc(%ebp),%edx
  106368:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  10636d:	89 d1                	mov    %edx,%ecx
  10636f:	29 c1                	sub    %eax,%ecx
  106371:	89 c8                	mov    %ecx,%eax
  106373:	c1 e0 09             	shl    $0x9,%eax
  106376:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)

    		int i;
    		for (i = 0; i < NPTENTRIES; i++)
  106379:	c7 45 e4 00 00 00 00 	movl   $0x0,0xffffffe4(%ebp)
  106380:	e9 79 01 00 00       	jmp    1064fe <pmap_walk+0x52f>
    		{
    			uint32_t pte = ptab[i];
  106385:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  106388:	c1 e0 02             	shl    $0x2,%eax
  10638b:	03 45 cc             	add    0xffffffcc(%ebp),%eax
  10638e:	8b 00                	mov    (%eax),%eax
  106390:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
    			nptab[i] = pte & ~PTE_W;
  106393:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  106396:	c1 e0 02             	shl    $0x2,%eax
  106399:	89 c2                	mov    %eax,%edx
  10639b:	03 55 e0             	add    0xffffffe0(%ebp),%edx
  10639e:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  1063a1:	83 e0 fd             	and    $0xfffffffd,%eax
  1063a4:	89 02                	mov    %eax,(%edx)
    			assert(PGADDR(pte) != 0);
  1063a6:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  1063a9:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1063ae:	85 c0                	test   %eax,%eax
  1063b0:	75 24                	jne    1063d6 <pmap_walk+0x407>
  1063b2:	c7 44 24 0c a3 cf 10 	movl   $0x10cfa3,0xc(%esp)
  1063b9:	00 
  1063ba:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  1063c1:	00 
  1063c2:	c7 44 24 04 bd 00 00 	movl   $0xbd,0x4(%esp)
  1063c9:	00 
  1063ca:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  1063d1:	e8 92 a5 ff ff       	call   100968 <debug_panic>
    			if (PGADDR(pte) != PTE_ZERO)
  1063d6:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  1063d9:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1063de:	ba 00 10 18 00       	mov    $0x181000,%edx
  1063e3:	39 d0                	cmp    %edx,%eax
  1063e5:	0f 84 0f 01 00 00    	je     1064fa <pmap_walk+0x52b>
    				mem_incref(mem_phys2pi(PGADDR(pte)));
  1063eb:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  1063ee:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1063f3:	c1 e8 0c             	shr    $0xc,%eax
  1063f6:	c1 e0 03             	shl    $0x3,%eax
  1063f9:	89 c2                	mov    %eax,%edx
  1063fb:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  106400:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106403:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
// Atomically increment the reference count on a page.
static gcc_inline void
mem_incref(pageinfo *pi)
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  106406:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  10640b:	83 c0 08             	add    $0x8,%eax
  10640e:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  106411:	73 17                	jae    10642a <pmap_walk+0x45b>
  106413:	a1 84 ed 17 00       	mov    0x17ed84,%eax
  106418:	c1 e0 03             	shl    $0x3,%eax
  10641b:	89 c2                	mov    %eax,%edx
  10641d:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  106422:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106425:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  106428:	77 24                	ja     10644e <pmap_walk+0x47f>
  10642a:	c7 44 24 0c c0 ce 10 	movl   $0x10cec0,0xc(%esp)
  106431:	00 
  106432:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  106439:	00 
  10643a:	c7 44 24 04 8e 00 00 	movl   $0x8e,0x4(%esp)
  106441:	00 
  106442:	c7 04 24 f7 ce 10 00 	movl   $0x10cef7,(%esp)
  106449:	e8 1a a5 ff ff       	call   100968 <debug_panic>
	assert(pi != mem_ptr2pi(pmap_zero));	// Don't alloc/free zero page!
  10644e:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  106454:	b8 00 10 18 00       	mov    $0x181000,%eax
  106459:	c1 e8 0c             	shr    $0xc,%eax
  10645c:	c1 e0 03             	shl    $0x3,%eax
  10645f:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106462:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  106465:	75 24                	jne    10648b <pmap_walk+0x4bc>
  106467:	c7 44 24 0c 04 cf 10 	movl   $0x10cf04,0xc(%esp)
  10646e:	00 
  10646f:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  106476:	00 
  106477:	c7 44 24 04 8f 00 00 	movl   $0x8f,0x4(%esp)
  10647e:	00 
  10647f:	c7 04 24 f7 ce 10 00 	movl   $0x10cef7,(%esp)
  106486:	e8 dd a4 ff ff       	call   100968 <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  10648b:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  106491:	b8 0c 00 10 00       	mov    $0x10000c,%eax
  106496:	c1 e8 0c             	shr    $0xc,%eax
  106499:	c1 e0 03             	shl    $0x3,%eax
  10649c:	8d 04 02             	lea    (%edx,%eax,1),%eax
  10649f:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  1064a2:	77 40                	ja     1064e4 <pmap_walk+0x515>
  1064a4:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  1064aa:	b8 08 20 18 00       	mov    $0x182008,%eax
  1064af:	83 e8 01             	sub    $0x1,%eax
  1064b2:	c1 e8 0c             	shr    $0xc,%eax
  1064b5:	c1 e0 03             	shl    $0x3,%eax
  1064b8:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1064bb:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  1064be:	72 24                	jb     1064e4 <pmap_walk+0x515>
  1064c0:	c7 44 24 0c 20 cf 10 	movl   $0x10cf20,0xc(%esp)
  1064c7:	00 
  1064c8:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  1064cf:	00 
  1064d0:	c7 44 24 04 90 00 00 	movl   $0x90,0x4(%esp)
  1064d7:	00 
  1064d8:	c7 04 24 f7 ce 10 00 	movl   $0x10cef7,(%esp)
  1064df:	e8 84 a4 ff ff       	call   100968 <debug_panic>

	lockadd(&pi->refcount, 1);
  1064e4:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  1064e7:	83 c0 04             	add    $0x4,%eax
  1064ea:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  1064f1:	00 
  1064f2:	89 04 24             	mov    %eax,(%esp)
  1064f5:	e8 bc f8 ff ff       	call   105db6 <lockadd>
  1064fa:	83 45 e4 01          	addl   $0x1,0xffffffe4(%ebp)
  1064fe:	81 7d e4 ff 03 00 00 	cmpl   $0x3ff,0xffffffe4(%ebp)
  106505:	0f 8e 7a fe ff ff    	jle    106385 <pmap_walk+0x3b6>
    		}

    	mem_decref(mem_ptr2pi(ptab), pmap_freeptab);
  10650b:	8b 45 cc             	mov    0xffffffcc(%ebp),%eax
  10650e:	c1 e8 0c             	shr    $0xc,%eax
  106511:	c1 e0 03             	shl    $0x3,%eax
  106514:	89 c2                	mov    %eax,%edx
  106516:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  10651b:	8d 04 02             	lea    (%edx,%eax,1),%eax
  10651e:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  106521:	c7 45 f8 03 5e 10 00 	movl   $0x105e03,0xfffffff8(%ebp)
// freeing the page with the provided function if there are no more refs.
static gcc_inline void
mem_decref(pageinfo* pi, void (*freefun)(pageinfo *pi))
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  106528:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  10652d:	83 c0 08             	add    $0x8,%eax
  106530:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  106533:	73 17                	jae    10654c <pmap_walk+0x57d>
  106535:	a1 84 ed 17 00       	mov    0x17ed84,%eax
  10653a:	c1 e0 03             	shl    $0x3,%eax
  10653d:	89 c2                	mov    %eax,%edx
  10653f:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  106544:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106547:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  10654a:	77 24                	ja     106570 <pmap_walk+0x5a1>
  10654c:	c7 44 24 0c c0 ce 10 	movl   $0x10cec0,0xc(%esp)
  106553:	00 
  106554:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  10655b:	00 
  10655c:	c7 44 24 04 9a 00 00 	movl   $0x9a,0x4(%esp)
  106563:	00 
  106564:	c7 04 24 f7 ce 10 00 	movl   $0x10cef7,(%esp)
  10656b:	e8 f8 a3 ff ff       	call   100968 <debug_panic>
	assert(pi != mem_ptr2pi(pmap_zero));	// Don't alloc/free zero page!
  106570:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  106576:	b8 00 10 18 00       	mov    $0x181000,%eax
  10657b:	c1 e8 0c             	shr    $0xc,%eax
  10657e:	c1 e0 03             	shl    $0x3,%eax
  106581:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106584:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  106587:	75 24                	jne    1065ad <pmap_walk+0x5de>
  106589:	c7 44 24 0c 04 cf 10 	movl   $0x10cf04,0xc(%esp)
  106590:	00 
  106591:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  106598:	00 
  106599:	c7 44 24 04 9b 00 00 	movl   $0x9b,0x4(%esp)
  1065a0:	00 
  1065a1:	c7 04 24 f7 ce 10 00 	movl   $0x10cef7,(%esp)
  1065a8:	e8 bb a3 ff ff       	call   100968 <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  1065ad:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  1065b3:	b8 0c 00 10 00       	mov    $0x10000c,%eax
  1065b8:	c1 e8 0c             	shr    $0xc,%eax
  1065bb:	c1 e0 03             	shl    $0x3,%eax
  1065be:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1065c1:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  1065c4:	77 40                	ja     106606 <pmap_walk+0x637>
  1065c6:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  1065cc:	b8 08 20 18 00       	mov    $0x182008,%eax
  1065d1:	83 e8 01             	sub    $0x1,%eax
  1065d4:	c1 e8 0c             	shr    $0xc,%eax
  1065d7:	c1 e0 03             	shl    $0x3,%eax
  1065da:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1065dd:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  1065e0:	72 24                	jb     106606 <pmap_walk+0x637>
  1065e2:	c7 44 24 0c 20 cf 10 	movl   $0x10cf20,0xc(%esp)
  1065e9:	00 
  1065ea:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  1065f1:	00 
  1065f2:	c7 44 24 04 9c 00 00 	movl   $0x9c,0x4(%esp)
  1065f9:	00 
  1065fa:	c7 04 24 f7 ce 10 00 	movl   $0x10cef7,(%esp)
  106601:	e8 62 a3 ff ff       	call   100968 <debug_panic>

	if (lockaddz(&pi->refcount, -1))
  106606:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  106609:	83 c0 04             	add    $0x4,%eax
  10660c:	c7 44 24 04 ff ff ff 	movl   $0xffffffff,0x4(%esp)
  106613:	ff 
  106614:	89 04 24             	mov    %eax,(%esp)
  106617:	e8 97 f9 ff ff       	call   105fb3 <lockaddz>
  10661c:	84 c0                	test   %al,%al
  10661e:	74 0b                	je     10662b <pmap_walk+0x65c>
			freefun(pi);
  106620:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  106623:	89 04 24             	mov    %eax,(%esp)
  106626:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  106629:	ff d0                	call   *%eax
	assert(pi->refcount >= 0);
  10662b:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  10662e:	8b 40 04             	mov    0x4(%eax),%eax
  106631:	85 c0                	test   %eax,%eax
  106633:	79 24                	jns    106659 <pmap_walk+0x68a>
  106635:	c7 44 24 0c 51 cf 10 	movl   $0x10cf51,0xc(%esp)
  10663c:	00 
  10663d:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  106644:	00 
  106645:	c7 44 24 04 a0 00 00 	movl   $0xa0,0x4(%esp)
  10664c:	00 
  10664d:	c7 04 24 f7 ce 10 00 	movl   $0x10cef7,(%esp)
  106654:	e8 0f a3 ff ff       	call   100968 <debug_panic>
    	ptab = nptab;
  106659:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  10665c:	89 45 cc             	mov    %eax,0xffffffcc(%ebp)
    	}

    	*pde = (uint32_t)ptab | PTE_A | PTE_P | PTE_W | PTE_U;
  10665f:	8b 45 cc             	mov    0xffffffcc(%ebp),%eax
  106662:	89 c2                	mov    %eax,%edx
  106664:	83 ca 27             	or     $0x27,%edx
  106667:	8b 45 c8             	mov    0xffffffc8(%ebp),%eax
  10666a:	89 10                	mov    %edx,(%eax)
  }

  return &ptab[PTX(la)];
  10666c:	8b 45 c4             	mov    0xffffffc4(%ebp),%eax
  10666f:	c1 e8 0c             	shr    $0xc,%eax
  106672:	25 ff 03 00 00       	and    $0x3ff,%eax
  106677:	c1 e0 02             	shl    $0x2,%eax
  10667a:	8b 55 cc             	mov    0xffffffcc(%ebp),%edx
  10667d:	01 c2                	add    %eax,%edx
  10667f:	89 55 bc             	mov    %edx,0xffffffbc(%ebp)
  106682:	8b 45 bc             	mov    0xffffffbc(%ebp),%eax
}
  106685:	c9                   	leave  
  106686:	c3                   	ret    

00106687 <pmap_insert>:

//
// Map the physical page 'pi' at user virtual address 'va'.
// The permissions (the low 12 bits) of the page table
//  entry should be set to 'perm | PTE_P'.
//
// Requirements
//   - If there is already a page mapped at 'va', it should be pmap_remove()d.
//   - If necessary, allocate a page able on demand and insert into 'pdir'.
//   - pi->refcount should be incremented if the insertion succeeds.
//   - The TLB must be invalidated if a page was formerly present at 'va'.
//
// Corner-case hint: Make sure to consider what happens when the same 
// pi is re-inserted at the same virtual address in the same pdir.
// What if this is the only reference to that page?
//
// RETURNS: 
//   a pointer to the inserted PTE on success (same as pmap_walk)
//   NULL, if page table couldn't be allocated
//
// Hint: The reference solution uses pmap_walk, pmap_remove, and mem_pi2phys.
//
pte_t *
pmap_insert(pde_t *pdir, pageinfo *pi, uint32_t va, int perm)
{
  106687:	55                   	push   %ebp
  106688:	89 e5                	mov    %esp,%ebp
  10668a:	83 ec 28             	sub    $0x28,%esp
  pte_t* pte = pmap_walk(pdir, va, 1);
  10668d:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
  106694:	00 
  106695:	8b 45 10             	mov    0x10(%ebp),%eax
  106698:	89 44 24 04          	mov    %eax,0x4(%esp)
  10669c:	8b 45 08             	mov    0x8(%ebp),%eax
  10669f:	89 04 24             	mov    %eax,(%esp)
  1066a2:	e8 28 f9 ff ff       	call   105fcf <pmap_walk>
  1066a7:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  if (pte == NULL)
  1066aa:	83 7d f8 00          	cmpl   $0x0,0xfffffff8(%ebp)
  1066ae:	75 0c                	jne    1066bc <pmap_insert+0x35>
    return NULL;
  1066b0:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  1066b7:	e9 44 01 00 00       	jmp    106800 <pmap_insert+0x179>
  1066bc:	8b 45 0c             	mov    0xc(%ebp),%eax
  1066bf:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
// Atomically increment the reference count on a page.
static gcc_inline void
mem_incref(pageinfo *pi)
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  1066c2:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  1066c7:	83 c0 08             	add    $0x8,%eax
  1066ca:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  1066cd:	73 17                	jae    1066e6 <pmap_insert+0x5f>
  1066cf:	a1 84 ed 17 00       	mov    0x17ed84,%eax
  1066d4:	c1 e0 03             	shl    $0x3,%eax
  1066d7:	89 c2                	mov    %eax,%edx
  1066d9:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  1066de:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1066e1:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  1066e4:	77 24                	ja     10670a <pmap_insert+0x83>
  1066e6:	c7 44 24 0c c0 ce 10 	movl   $0x10cec0,0xc(%esp)
  1066ed:	00 
  1066ee:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  1066f5:	00 
  1066f6:	c7 44 24 04 8e 00 00 	movl   $0x8e,0x4(%esp)
  1066fd:	00 
  1066fe:	c7 04 24 f7 ce 10 00 	movl   $0x10cef7,(%esp)
  106705:	e8 5e a2 ff ff       	call   100968 <debug_panic>
	assert(pi != mem_ptr2pi(pmap_zero));	// Don't alloc/free zero page!
  10670a:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  106710:	b8 00 10 18 00       	mov    $0x181000,%eax
  106715:	c1 e8 0c             	shr    $0xc,%eax
  106718:	c1 e0 03             	shl    $0x3,%eax
  10671b:	8d 04 02             	lea    (%edx,%eax,1),%eax
  10671e:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  106721:	75 24                	jne    106747 <pmap_insert+0xc0>
  106723:	c7 44 24 0c 04 cf 10 	movl   $0x10cf04,0xc(%esp)
  10672a:	00 
  10672b:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  106732:	00 
  106733:	c7 44 24 04 8f 00 00 	movl   $0x8f,0x4(%esp)
  10673a:	00 
  10673b:	c7 04 24 f7 ce 10 00 	movl   $0x10cef7,(%esp)
  106742:	e8 21 a2 ff ff       	call   100968 <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  106747:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  10674d:	b8 0c 00 10 00       	mov    $0x10000c,%eax
  106752:	c1 e8 0c             	shr    $0xc,%eax
  106755:	c1 e0 03             	shl    $0x3,%eax
  106758:	8d 04 02             	lea    (%edx,%eax,1),%eax
  10675b:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  10675e:	77 40                	ja     1067a0 <pmap_insert+0x119>
  106760:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  106766:	b8 08 20 18 00       	mov    $0x182008,%eax
  10676b:	83 e8 01             	sub    $0x1,%eax
  10676e:	c1 e8 0c             	shr    $0xc,%eax
  106771:	c1 e0 03             	shl    $0x3,%eax
  106774:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106777:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  10677a:	72 24                	jb     1067a0 <pmap_insert+0x119>
  10677c:	c7 44 24 0c 20 cf 10 	movl   $0x10cf20,0xc(%esp)
  106783:	00 
  106784:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  10678b:	00 
  10678c:	c7 44 24 04 90 00 00 	movl   $0x90,0x4(%esp)
  106793:	00 
  106794:	c7 04 24 f7 ce 10 00 	movl   $0x10cef7,(%esp)
  10679b:	e8 c8 a1 ff ff       	call   100968 <debug_panic>

	lockadd(&pi->refcount, 1);
  1067a0:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  1067a3:	83 c0 04             	add    $0x4,%eax
  1067a6:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  1067ad:	00 
  1067ae:	89 04 24             	mov    %eax,(%esp)
  1067b1:	e8 00 f6 ff ff       	call   105db6 <lockadd>

  mem_incref(pi);

  if (*pte & PTE_P)
  1067b6:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1067b9:	8b 00                	mov    (%eax),%eax
  1067bb:	83 e0 01             	and    $0x1,%eax
  1067be:	84 c0                	test   %al,%al
  1067c0:	74 1a                	je     1067dc <pmap_insert+0x155>
    pmap_remove(pdir, va, PAGESIZE);
  1067c2:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  1067c9:	00 
  1067ca:	8b 45 10             	mov    0x10(%ebp),%eax
  1067cd:	89 44 24 04          	mov    %eax,0x4(%esp)
  1067d1:	8b 45 08             	mov    0x8(%ebp),%eax
  1067d4:	89 04 24             	mov    %eax,(%esp)
  1067d7:	e8 29 00 00 00       	call   106805 <pmap_remove>

  *pte = mem_pi2phys(pi) | perm | PTE_P;
  1067dc:	8b 55 0c             	mov    0xc(%ebp),%edx
  1067df:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  1067e4:	89 d1                	mov    %edx,%ecx
  1067e6:	29 c1                	sub    %eax,%ecx
  1067e8:	89 c8                	mov    %ecx,%eax
  1067ea:	c1 e0 09             	shl    $0x9,%eax
  1067ed:	0b 45 14             	or     0x14(%ebp),%eax
  1067f0:	83 c8 01             	or     $0x1,%eax
  1067f3:	89 c2                	mov    %eax,%edx
  1067f5:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1067f8:	89 10                	mov    %edx,(%eax)

  return pte;
  1067fa:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1067fd:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  106800:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
}
  106803:	c9                   	leave  
  106804:	c3                   	ret    

00106805 <pmap_remove>:

//
// Unmap the physical pages starting at user virtual address 'va'
// and covering a virtual address region of 'size' bytes.
// The caller must ensure that both 'va' and 'size' are page-aligned.
// If there is no mapping at that address, pmap_remove silently does nothing.
// Clears nominal permissions (SYS_RW flags) as well as mappings themselves.
//
// Details:
//   - The refcount on mapped pages should be decremented atomically.
//   - The physical page should be freed if the refcount reaches 0.
//   - The page table entry corresponding to 'va' should be set to 0.
//     (if such a PTE exists)
//   - The TLB must be invalidated if you remove an entry from
//     the pdir/ptab.
//   - If the region to remove covers a whole 4MB page table region,
//     then unmap and free the page table after unmapping all its contents.
//
// Hint: The TA solution is implemented using pmap_lookup,
// 	pmap_inval, and mem_decref.
//
void
pmap_remove(pde_t *pdir, uint32_t va, size_t size)
{
  106805:	55                   	push   %ebp
  106806:	89 e5                	mov    %esp,%ebp
  106808:	83 ec 48             	sub    $0x48,%esp
  assert(PGOFF(size) == 0);	// must be page-aligned
  10680b:	8b 45 10             	mov    0x10(%ebp),%eax
  10680e:	25 ff 0f 00 00       	and    $0xfff,%eax
  106813:	85 c0                	test   %eax,%eax
  106815:	74 24                	je     10683b <pmap_remove+0x36>
  106817:	c7 44 24 0c b4 cf 10 	movl   $0x10cfb4,0xc(%esp)
  10681e:	00 
  10681f:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  106826:	00 
  106827:	c7 44 24 04 09 01 00 	movl   $0x109,0x4(%esp)
  10682e:	00 
  10682f:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  106836:	e8 2d a1 ff ff       	call   100968 <debug_panic>
  assert(va >= VM_USERLO && va < VM_USERHI);
  10683b:	81 7d 0c ff ff ff 3f 	cmpl   $0x3fffffff,0xc(%ebp)
  106842:	76 09                	jbe    10684d <pmap_remove+0x48>
  106844:	81 7d 0c ff ff ff ef 	cmpl   $0xefffffff,0xc(%ebp)
  10684b:	76 24                	jbe    106871 <pmap_remove+0x6c>
  10684d:	c7 44 24 0c 64 cf 10 	movl   $0x10cf64,0xc(%esp)
  106854:	00 
  106855:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  10685c:	00 
  10685d:	c7 44 24 04 0a 01 00 	movl   $0x10a,0x4(%esp)
  106864:	00 
  106865:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  10686c:	e8 f7 a0 ff ff       	call   100968 <debug_panic>
  assert(size <= VM_USERHI - va);
  106871:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
  106876:	2b 45 0c             	sub    0xc(%ebp),%eax
  106879:	3b 45 10             	cmp    0x10(%ebp),%eax
  10687c:	73 24                	jae    1068a2 <pmap_remove+0x9d>
  10687e:	c7 44 24 0c c5 cf 10 	movl   $0x10cfc5,0xc(%esp)
  106885:	00 
  106886:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  10688d:	00 
  10688e:	c7 44 24 04 0b 01 00 	movl   $0x10b,0x4(%esp)
  106895:	00 
  106896:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  10689d:	e8 c6 a0 ff ff       	call   100968 <debug_panic>

  pmap_inval(pdir, va, size);
  1068a2:	8b 45 10             	mov    0x10(%ebp),%eax
  1068a5:	89 44 24 08          	mov    %eax,0x8(%esp)
  1068a9:	8b 45 0c             	mov    0xc(%ebp),%eax
  1068ac:	89 44 24 04          	mov    %eax,0x4(%esp)
  1068b0:	8b 45 08             	mov    0x8(%ebp),%eax
  1068b3:	89 04 24             	mov    %eax,(%esp)
  1068b6:	e8 e0 03 00 00       	call   106c9b <pmap_inval>

  uint32_t vahi = va + size;
  1068bb:	8b 45 10             	mov    0x10(%ebp),%eax
  1068be:	03 45 0c             	add    0xc(%ebp),%eax
  1068c1:	89 45 dc             	mov    %eax,0xffffffdc(%ebp)
  while (va < vahi)
  1068c4:	e9 c4 03 00 00       	jmp    106c8d <pmap_remove+0x488>
  {
  	pde_t *pde = &pdir[PDX(va)];
  1068c9:	8b 45 0c             	mov    0xc(%ebp),%eax
  1068cc:	c1 e8 16             	shr    $0x16,%eax
  1068cf:	25 ff 03 00 00       	and    $0x3ff,%eax
  1068d4:	c1 e0 02             	shl    $0x2,%eax
  1068d7:	03 45 08             	add    0x8(%ebp),%eax
  1068da:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)
  	if (*pde == PTE_ZERO)
  1068dd:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  1068e0:	8b 10                	mov    (%eax),%edx
  1068e2:	b8 00 10 18 00       	mov    $0x181000,%eax
  1068e7:	39 c2                	cmp    %eax,%edx
  1068e9:	75 15                	jne    106900 <pmap_remove+0xfb>
  	{
  	  va = PTADDR(va + PTSIZE);
  1068eb:	8b 45 0c             	mov    0xc(%ebp),%eax
  1068ee:	05 00 00 40 00       	add    $0x400000,%eax
  1068f3:	25 00 00 c0 ff       	and    $0xffc00000,%eax
  1068f8:	89 45 0c             	mov    %eax,0xc(%ebp)
  	  continue;
  1068fb:	e9 8d 03 00 00       	jmp    106c8d <pmap_remove+0x488>
  	}

  	if (PTX(va) == 0 && vahi-va >= PTSIZE)
  106900:	8b 45 0c             	mov    0xc(%ebp),%eax
  106903:	c1 e8 0c             	shr    $0xc,%eax
  106906:	25 ff 03 00 00       	and    $0x3ff,%eax
  10690b:	85 c0                	test   %eax,%eax
  10690d:	0f 85 98 01 00 00    	jne    106aab <pmap_remove+0x2a6>
  106913:	8b 45 0c             	mov    0xc(%ebp),%eax
  106916:	8b 55 dc             	mov    0xffffffdc(%ebp),%edx
  106919:	89 d1                	mov    %edx,%ecx
  10691b:	29 c1                	sub    %eax,%ecx
  10691d:	89 c8                	mov    %ecx,%eax
  10691f:	3d ff ff 3f 00       	cmp    $0x3fffff,%eax
  106924:	0f 86 81 01 00 00    	jbe    106aab <pmap_remove+0x2a6>
  	{
  		uint32_t ptabaddr = PGADDR(*pde);
  10692a:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  10692d:	8b 00                	mov    (%eax),%eax
  10692f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  106934:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
    		if(ptabaddr != PTE_ZERO)
  106937:	b8 00 10 18 00       	mov    $0x181000,%eax
  10693c:	39 45 e8             	cmp    %eax,0xffffffe8(%ebp)
  10693f:	0f 84 4e 01 00 00    	je     106a93 <pmap_remove+0x28e>
      			mem_decref(mem_phys2pi(ptabaddr), pmap_freeptab);
  106945:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  106948:	c1 e8 0c             	shr    $0xc,%eax
  10694b:	c1 e0 03             	shl    $0x3,%eax
  10694e:	89 c2                	mov    %eax,%edx
  106950:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  106955:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106958:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
  10695b:	c7 45 f0 03 5e 10 00 	movl   $0x105e03,0xfffffff0(%ebp)
// freeing the page with the provided function if there are no more refs.
static gcc_inline void
mem_decref(pageinfo* pi, void (*freefun)(pageinfo *pi))
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  106962:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  106967:	83 c0 08             	add    $0x8,%eax
  10696a:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  10696d:	73 17                	jae    106986 <pmap_remove+0x181>
  10696f:	a1 84 ed 17 00       	mov    0x17ed84,%eax
  106974:	c1 e0 03             	shl    $0x3,%eax
  106977:	89 c2                	mov    %eax,%edx
  106979:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  10697e:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106981:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  106984:	77 24                	ja     1069aa <pmap_remove+0x1a5>
  106986:	c7 44 24 0c c0 ce 10 	movl   $0x10cec0,0xc(%esp)
  10698d:	00 
  10698e:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  106995:	00 
  106996:	c7 44 24 04 9a 00 00 	movl   $0x9a,0x4(%esp)
  10699d:	00 
  10699e:	c7 04 24 f7 ce 10 00 	movl   $0x10cef7,(%esp)
  1069a5:	e8 be 9f ff ff       	call   100968 <debug_panic>
	assert(pi != mem_ptr2pi(pmap_zero));	// Don't alloc/free zero page!
  1069aa:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  1069b0:	b8 00 10 18 00       	mov    $0x181000,%eax
  1069b5:	c1 e8 0c             	shr    $0xc,%eax
  1069b8:	c1 e0 03             	shl    $0x3,%eax
  1069bb:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1069be:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  1069c1:	75 24                	jne    1069e7 <pmap_remove+0x1e2>
  1069c3:	c7 44 24 0c 04 cf 10 	movl   $0x10cf04,0xc(%esp)
  1069ca:	00 
  1069cb:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  1069d2:	00 
  1069d3:	c7 44 24 04 9b 00 00 	movl   $0x9b,0x4(%esp)
  1069da:	00 
  1069db:	c7 04 24 f7 ce 10 00 	movl   $0x10cef7,(%esp)
  1069e2:	e8 81 9f ff ff       	call   100968 <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  1069e7:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  1069ed:	b8 0c 00 10 00       	mov    $0x10000c,%eax
  1069f2:	c1 e8 0c             	shr    $0xc,%eax
  1069f5:	c1 e0 03             	shl    $0x3,%eax
  1069f8:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1069fb:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  1069fe:	77 40                	ja     106a40 <pmap_remove+0x23b>
  106a00:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  106a06:	b8 08 20 18 00       	mov    $0x182008,%eax
  106a0b:	83 e8 01             	sub    $0x1,%eax
  106a0e:	c1 e8 0c             	shr    $0xc,%eax
  106a11:	c1 e0 03             	shl    $0x3,%eax
  106a14:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106a17:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  106a1a:	72 24                	jb     106a40 <pmap_remove+0x23b>
  106a1c:	c7 44 24 0c 20 cf 10 	movl   $0x10cf20,0xc(%esp)
  106a23:	00 
  106a24:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  106a2b:	00 
  106a2c:	c7 44 24 04 9c 00 00 	movl   $0x9c,0x4(%esp)
  106a33:	00 
  106a34:	c7 04 24 f7 ce 10 00 	movl   $0x10cef7,(%esp)
  106a3b:	e8 28 9f ff ff       	call   100968 <debug_panic>

	if (lockaddz(&pi->refcount, -1))
  106a40:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  106a43:	83 c0 04             	add    $0x4,%eax
  106a46:	c7 44 24 04 ff ff ff 	movl   $0xffffffff,0x4(%esp)
  106a4d:	ff 
  106a4e:	89 04 24             	mov    %eax,(%esp)
  106a51:	e8 5d f5 ff ff       	call   105fb3 <lockaddz>
  106a56:	84 c0                	test   %al,%al
  106a58:	74 0b                	je     106a65 <pmap_remove+0x260>
			freefun(pi);
  106a5a:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  106a5d:	89 04 24             	mov    %eax,(%esp)
  106a60:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  106a63:	ff d0                	call   *%eax
	assert(pi->refcount >= 0);
  106a65:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  106a68:	8b 40 04             	mov    0x4(%eax),%eax
  106a6b:	85 c0                	test   %eax,%eax
  106a6d:	79 24                	jns    106a93 <pmap_remove+0x28e>
  106a6f:	c7 44 24 0c 51 cf 10 	movl   $0x10cf51,0xc(%esp)
  106a76:	00 
  106a77:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  106a7e:	00 
  106a7f:	c7 44 24 04 a0 00 00 	movl   $0xa0,0x4(%esp)
  106a86:	00 
  106a87:	c7 04 24 f7 ce 10 00 	movl   $0x10cef7,(%esp)
  106a8e:	e8 d5 9e ff ff       	call   100968 <debug_panic>
      		*pde = PTE_ZERO;
  106a93:	b8 00 10 18 00       	mov    $0x181000,%eax
  106a98:	89 c2                	mov    %eax,%edx
  106a9a:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  106a9d:	89 10                	mov    %edx,(%eax)
      		va += PTSIZE;
  106a9f:	81 45 0c 00 00 40 00 	addl   $0x400000,0xc(%ebp)
      		continue;
  106aa6:	e9 e2 01 00 00       	jmp    106c8d <pmap_remove+0x488>
  	}

  	pte_t *pte = pmap_walk(pdir, va, 1);
  106aab:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
  106ab2:	00 
  106ab3:	8b 45 0c             	mov    0xc(%ebp),%eax
  106ab6:	89 44 24 04          	mov    %eax,0x4(%esp)
  106aba:	8b 45 08             	mov    0x8(%ebp),%eax
  106abd:	89 04 24             	mov    %eax,(%esp)
  106ac0:	e8 0a f5 ff ff       	call   105fcf <pmap_walk>
  106ac5:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
  	assert(pte != NULL);
  106ac8:	83 7d e4 00          	cmpl   $0x0,0xffffffe4(%ebp)
  106acc:	75 24                	jne    106af2 <pmap_remove+0x2ed>
  106ace:	c7 44 24 0c dc cf 10 	movl   $0x10cfdc,0xc(%esp)
  106ad5:	00 
  106ad6:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  106add:	00 
  106ade:	c7 44 24 04 24 01 00 	movl   $0x124,0x4(%esp)
  106ae5:	00 
  106ae6:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  106aed:	e8 76 9e ff ff       	call   100968 <debug_panic>
	
  	do
  	{
  		uint32_t pgaddr = PGADDR(*pte);
  106af2:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  106af5:	8b 00                	mov    (%eax),%eax
  106af7:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  106afc:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  		if(pgaddr != PTE_ZERO)
  106aff:	b8 00 10 18 00       	mov    $0x181000,%eax
  106b04:	39 45 ec             	cmp    %eax,0xffffffec(%ebp)
  106b07:	0f 84 4e 01 00 00    	je     106c5b <pmap_remove+0x456>
  			mem_decref(mem_phys2pi(pgaddr), mem_free);
  106b0d:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  106b10:	c1 e8 0c             	shr    $0xc,%eax
  106b13:	c1 e0 03             	shl    $0x3,%eax
  106b16:	89 c2                	mov    %eax,%edx
  106b18:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  106b1d:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106b20:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  106b23:	c7 45 f8 8f 10 10 00 	movl   $0x10108f,0xfffffff8(%ebp)
// freeing the page with the provided function if there are no more refs.
static gcc_inline void
mem_decref(pageinfo* pi, void (*freefun)(pageinfo *pi))
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  106b2a:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  106b2f:	83 c0 08             	add    $0x8,%eax
  106b32:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  106b35:	73 17                	jae    106b4e <pmap_remove+0x349>
  106b37:	a1 84 ed 17 00       	mov    0x17ed84,%eax
  106b3c:	c1 e0 03             	shl    $0x3,%eax
  106b3f:	89 c2                	mov    %eax,%edx
  106b41:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  106b46:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106b49:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  106b4c:	77 24                	ja     106b72 <pmap_remove+0x36d>
  106b4e:	c7 44 24 0c c0 ce 10 	movl   $0x10cec0,0xc(%esp)
  106b55:	00 
  106b56:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  106b5d:	00 
  106b5e:	c7 44 24 04 9a 00 00 	movl   $0x9a,0x4(%esp)
  106b65:	00 
  106b66:	c7 04 24 f7 ce 10 00 	movl   $0x10cef7,(%esp)
  106b6d:	e8 f6 9d ff ff       	call   100968 <debug_panic>
	assert(pi != mem_ptr2pi(pmap_zero));	// Don't alloc/free zero page!
  106b72:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  106b78:	b8 00 10 18 00       	mov    $0x181000,%eax
  106b7d:	c1 e8 0c             	shr    $0xc,%eax
  106b80:	c1 e0 03             	shl    $0x3,%eax
  106b83:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106b86:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  106b89:	75 24                	jne    106baf <pmap_remove+0x3aa>
  106b8b:	c7 44 24 0c 04 cf 10 	movl   $0x10cf04,0xc(%esp)
  106b92:	00 
  106b93:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  106b9a:	00 
  106b9b:	c7 44 24 04 9b 00 00 	movl   $0x9b,0x4(%esp)
  106ba2:	00 
  106ba3:	c7 04 24 f7 ce 10 00 	movl   $0x10cef7,(%esp)
  106baa:	e8 b9 9d ff ff       	call   100968 <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  106baf:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  106bb5:	b8 0c 00 10 00       	mov    $0x10000c,%eax
  106bba:	c1 e8 0c             	shr    $0xc,%eax
  106bbd:	c1 e0 03             	shl    $0x3,%eax
  106bc0:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106bc3:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  106bc6:	77 40                	ja     106c08 <pmap_remove+0x403>
  106bc8:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  106bce:	b8 08 20 18 00       	mov    $0x182008,%eax
  106bd3:	83 e8 01             	sub    $0x1,%eax
  106bd6:	c1 e8 0c             	shr    $0xc,%eax
  106bd9:	c1 e0 03             	shl    $0x3,%eax
  106bdc:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106bdf:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  106be2:	72 24                	jb     106c08 <pmap_remove+0x403>
  106be4:	c7 44 24 0c 20 cf 10 	movl   $0x10cf20,0xc(%esp)
  106beb:	00 
  106bec:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  106bf3:	00 
  106bf4:	c7 44 24 04 9c 00 00 	movl   $0x9c,0x4(%esp)
  106bfb:	00 
  106bfc:	c7 04 24 f7 ce 10 00 	movl   $0x10cef7,(%esp)
  106c03:	e8 60 9d ff ff       	call   100968 <debug_panic>

	if (lockaddz(&pi->refcount, -1))
  106c08:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  106c0b:	83 c0 04             	add    $0x4,%eax
  106c0e:	c7 44 24 04 ff ff ff 	movl   $0xffffffff,0x4(%esp)
  106c15:	ff 
  106c16:	89 04 24             	mov    %eax,(%esp)
  106c19:	e8 95 f3 ff ff       	call   105fb3 <lockaddz>
  106c1e:	84 c0                	test   %al,%al
  106c20:	74 0b                	je     106c2d <pmap_remove+0x428>
			freefun(pi);
  106c22:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  106c25:	89 04 24             	mov    %eax,(%esp)
  106c28:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  106c2b:	ff d0                	call   *%eax
	assert(pi->refcount >= 0);
  106c2d:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  106c30:	8b 40 04             	mov    0x4(%eax),%eax
  106c33:	85 c0                	test   %eax,%eax
  106c35:	79 24                	jns    106c5b <pmap_remove+0x456>
  106c37:	c7 44 24 0c 51 cf 10 	movl   $0x10cf51,0xc(%esp)
  106c3e:	00 
  106c3f:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  106c46:	00 
  106c47:	c7 44 24 04 a0 00 00 	movl   $0xa0,0x4(%esp)
  106c4e:	00 
  106c4f:	c7 04 24 f7 ce 10 00 	movl   $0x10cef7,(%esp)
  106c56:	e8 0d 9d ff ff       	call   100968 <debug_panic>
      		*pte++ = PTE_ZERO;
  106c5b:	b8 00 10 18 00       	mov    $0x181000,%eax
  106c60:	89 c2                	mov    %eax,%edx
  106c62:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  106c65:	89 10                	mov    %edx,(%eax)
  106c67:	83 45 e4 04          	addl   $0x4,0xffffffe4(%ebp)
      		va += PAGESIZE;
  106c6b:	81 45 0c 00 10 00 00 	addl   $0x1000,0xc(%ebp)
  	} while (va < vahi && PTX(va) != 0);
  106c72:	8b 45 0c             	mov    0xc(%ebp),%eax
  106c75:	3b 45 dc             	cmp    0xffffffdc(%ebp),%eax
  106c78:	73 13                	jae    106c8d <pmap_remove+0x488>
  106c7a:	8b 45 0c             	mov    0xc(%ebp),%eax
  106c7d:	c1 e8 0c             	shr    $0xc,%eax
  106c80:	25 ff 03 00 00       	and    $0x3ff,%eax
  106c85:	85 c0                	test   %eax,%eax
  106c87:	0f 85 65 fe ff ff    	jne    106af2 <pmap_remove+0x2ed>
  106c8d:	8b 45 0c             	mov    0xc(%ebp),%eax
  106c90:	3b 45 dc             	cmp    0xffffffdc(%ebp),%eax
  106c93:	0f 82 30 fc ff ff    	jb     1068c9 <pmap_remove+0xc4>
  }
}
  106c99:	c9                   	leave  
  106c9a:	c3                   	ret    

00106c9b <pmap_inval>:

//
// Invalidate the TLB entry or entries for a given virtual address range,
// but only if the page tables being edited are the ones
// currently in use by the processor.
//
void
pmap_inval(pde_t *pdir, uint32_t va, size_t size)
{
  106c9b:	55                   	push   %ebp
  106c9c:	89 e5                	mov    %esp,%ebp
  106c9e:	83 ec 18             	sub    $0x18,%esp
	// Flush the entry only if we're modifying the current address space.
	proc *p = proc_cur();
  106ca1:	e8 69 ef ff ff       	call   105c0f <cpu_cur>
  106ca6:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  106cac:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	if (p == NULL || p->pdir == pdir) {
  106caf:	83 7d f4 00          	cmpl   $0x0,0xfffffff4(%ebp)
  106cb3:	74 0e                	je     106cc3 <pmap_inval+0x28>
  106cb5:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  106cb8:	8b 80 a0 06 00 00    	mov    0x6a0(%eax),%eax
  106cbe:	3b 45 08             	cmp    0x8(%ebp),%eax
  106cc1:	75 23                	jne    106ce6 <pmap_inval+0x4b>
		if (size == PAGESIZE)
  106cc3:	81 7d 10 00 10 00 00 	cmpl   $0x1000,0x10(%ebp)
  106cca:	75 0e                	jne    106cda <pmap_inval+0x3f>
			invlpg(mem_ptr(va));	// invalidate one page
  106ccc:	8b 45 0c             	mov    0xc(%ebp),%eax
  106ccf:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)

static gcc_inline void 
invlpg(void *addr)
{ 
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
  106cd2:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  106cd5:	0f 01 38             	invlpg (%eax)
  106cd8:	eb 0c                	jmp    106ce6 <pmap_inval+0x4b>
		else
			lcr3(mem_phys(pdir));	// invalidate everything
  106cda:	8b 45 08             	mov    0x8(%ebp),%eax
  106cdd:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)

static gcc_inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
  106ce0:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  106ce3:	0f 22 d8             	mov    %eax,%cr3
	}
}
  106ce6:	c9                   	leave  
  106ce7:	c3                   	ret    

00106ce8 <pmap_copy>:

//
// Virtually copy a range of pages from spdir to dpdir (could be the same).
// Uses copy-on-write to avoid the cost of immediate copying:
// instead just copies the mappings and makes both source and dest read-only.
// Returns true if successfull, false if not enough memory for copy.
//
int
pmap_copy(pde_t *spdir, uint32_t sva, pde_t *dpdir, uint32_t dva,
		size_t size)
{
  106ce8:	55                   	push   %ebp
  106ce9:	89 e5                	mov    %esp,%ebp
  106ceb:	83 ec 28             	sub    $0x28,%esp
	assert(PTOFF(sva) == 0);	// must be 4MB-aligned
  106cee:	8b 45 0c             	mov    0xc(%ebp),%eax
  106cf1:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  106cf6:	85 c0                	test   %eax,%eax
  106cf8:	74 24                	je     106d1e <pmap_copy+0x36>
  106cfa:	c7 44 24 0c e8 cf 10 	movl   $0x10cfe8,0xc(%esp)
  106d01:	00 
  106d02:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  106d09:	00 
  106d0a:	c7 44 24 04 4d 01 00 	movl   $0x14d,0x4(%esp)
  106d11:	00 
  106d12:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  106d19:	e8 4a 9c ff ff       	call   100968 <debug_panic>
	assert(PTOFF(dva) == 0);
  106d1e:	8b 45 14             	mov    0x14(%ebp),%eax
  106d21:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  106d26:	85 c0                	test   %eax,%eax
  106d28:	74 24                	je     106d4e <pmap_copy+0x66>
  106d2a:	c7 44 24 0c f8 cf 10 	movl   $0x10cff8,0xc(%esp)
  106d31:	00 
  106d32:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  106d39:	00 
  106d3a:	c7 44 24 04 4e 01 00 	movl   $0x14e,0x4(%esp)
  106d41:	00 
  106d42:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  106d49:	e8 1a 9c ff ff       	call   100968 <debug_panic>
	assert(PTOFF(size) == 0);
  106d4e:	8b 45 18             	mov    0x18(%ebp),%eax
  106d51:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  106d56:	85 c0                	test   %eax,%eax
  106d58:	74 24                	je     106d7e <pmap_copy+0x96>
  106d5a:	c7 44 24 0c 08 d0 10 	movl   $0x10d008,0xc(%esp)
  106d61:	00 
  106d62:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  106d69:	00 
  106d6a:	c7 44 24 04 4f 01 00 	movl   $0x14f,0x4(%esp)
  106d71:	00 
  106d72:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  106d79:	e8 ea 9b ff ff       	call   100968 <debug_panic>
	assert(sva >= VM_USERLO && sva < VM_USERHI);
  106d7e:	81 7d 0c ff ff ff 3f 	cmpl   $0x3fffffff,0xc(%ebp)
  106d85:	76 09                	jbe    106d90 <pmap_copy+0xa8>
  106d87:	81 7d 0c ff ff ff ef 	cmpl   $0xefffffff,0xc(%ebp)
  106d8e:	76 24                	jbe    106db4 <pmap_copy+0xcc>
  106d90:	c7 44 24 0c 1c d0 10 	movl   $0x10d01c,0xc(%esp)
  106d97:	00 
  106d98:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  106d9f:	00 
  106da0:	c7 44 24 04 50 01 00 	movl   $0x150,0x4(%esp)
  106da7:	00 
  106da8:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  106daf:	e8 b4 9b ff ff       	call   100968 <debug_panic>
	assert(dva >= VM_USERLO && dva < VM_USERHI);
  106db4:	81 7d 14 ff ff ff 3f 	cmpl   $0x3fffffff,0x14(%ebp)
  106dbb:	76 09                	jbe    106dc6 <pmap_copy+0xde>
  106dbd:	81 7d 14 ff ff ff ef 	cmpl   $0xefffffff,0x14(%ebp)
  106dc4:	76 24                	jbe    106dea <pmap_copy+0x102>
  106dc6:	c7 44 24 0c 40 d0 10 	movl   $0x10d040,0xc(%esp)
  106dcd:	00 
  106dce:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  106dd5:	00 
  106dd6:	c7 44 24 04 51 01 00 	movl   $0x151,0x4(%esp)
  106ddd:	00 
  106dde:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  106de5:	e8 7e 9b ff ff       	call   100968 <debug_panic>
	assert(size <= VM_USERHI - sva);
  106dea:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
  106def:	2b 45 0c             	sub    0xc(%ebp),%eax
  106df2:	3b 45 18             	cmp    0x18(%ebp),%eax
  106df5:	73 24                	jae    106e1b <pmap_copy+0x133>
  106df7:	c7 44 24 0c 64 d0 10 	movl   $0x10d064,0xc(%esp)
  106dfe:	00 
  106dff:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  106e06:	00 
  106e07:	c7 44 24 04 52 01 00 	movl   $0x152,0x4(%esp)
  106e0e:	00 
  106e0f:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  106e16:	e8 4d 9b ff ff       	call   100968 <debug_panic>
	assert(size <= VM_USERHI - dva);
  106e1b:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
  106e20:	2b 45 14             	sub    0x14(%ebp),%eax
  106e23:	3b 45 18             	cmp    0x18(%ebp),%eax
  106e26:	73 24                	jae    106e4c <pmap_copy+0x164>
  106e28:	c7 44 24 0c 7c d0 10 	movl   $0x10d07c,0xc(%esp)
  106e2f:	00 
  106e30:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  106e37:	00 
  106e38:	c7 44 24 04 53 01 00 	movl   $0x153,0x4(%esp)
  106e3f:	00 
  106e40:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  106e47:	e8 1c 9b ff ff       	call   100968 <debug_panic>

	pmap_inval(spdir, sva, size);
  106e4c:	8b 45 18             	mov    0x18(%ebp),%eax
  106e4f:	89 44 24 08          	mov    %eax,0x8(%esp)
  106e53:	8b 45 0c             	mov    0xc(%ebp),%eax
  106e56:	89 44 24 04          	mov    %eax,0x4(%esp)
  106e5a:	8b 45 08             	mov    0x8(%ebp),%eax
  106e5d:	89 04 24             	mov    %eax,(%esp)
  106e60:	e8 36 fe ff ff       	call   106c9b <pmap_inval>
	pmap_inval(dpdir, dva, size);
  106e65:	8b 45 18             	mov    0x18(%ebp),%eax
  106e68:	89 44 24 08          	mov    %eax,0x8(%esp)
  106e6c:	8b 45 14             	mov    0x14(%ebp),%eax
  106e6f:	89 44 24 04          	mov    %eax,0x4(%esp)
  106e73:	8b 45 10             	mov    0x10(%ebp),%eax
  106e76:	89 04 24             	mov    %eax,(%esp)
  106e79:	e8 1d fe ff ff       	call   106c9b <pmap_inval>

	uint32_t svahi = sva + size;
  106e7e:	8b 45 18             	mov    0x18(%ebp),%eax
  106e81:	03 45 0c             	add    0xc(%ebp),%eax
  106e84:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
	pde_t *spde = &spdir[PDX(sva)];
  106e87:	8b 45 0c             	mov    0xc(%ebp),%eax
  106e8a:	c1 e8 16             	shr    $0x16,%eax
  106e8d:	25 ff 03 00 00       	and    $0x3ff,%eax
  106e92:	c1 e0 02             	shl    $0x2,%eax
  106e95:	03 45 08             	add    0x8(%ebp),%eax
  106e98:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	pte_t *dpde = &dpdir[PDX(dva)];
  106e9b:	8b 45 14             	mov    0x14(%ebp),%eax
  106e9e:	c1 e8 16             	shr    $0x16,%eax
  106ea1:	25 ff 03 00 00       	and    $0x3ff,%eax
  106ea6:	c1 e0 02             	shl    $0x2,%eax
  106ea9:	03 45 10             	add    0x10(%ebp),%eax
  106eac:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)

	while (sva < svahi)
  106eaf:	e9 aa 01 00 00       	jmp    10705e <pmap_copy+0x376>
	{
		if (*dpde & PTE_P)
  106eb4:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  106eb7:	8b 00                	mov    (%eax),%eax
  106eb9:	83 e0 01             	and    $0x1,%eax
  106ebc:	84 c0                	test   %al,%al
  106ebe:	74 1a                	je     106eda <pmap_copy+0x1f2>
			pmap_remove(dpdir, dva, PTSIZE);
  106ec0:	c7 44 24 08 00 00 40 	movl   $0x400000,0x8(%esp)
  106ec7:	00 
  106ec8:	8b 45 14             	mov    0x14(%ebp),%eax
  106ecb:	89 44 24 04          	mov    %eax,0x4(%esp)
  106ecf:	8b 45 10             	mov    0x10(%ebp),%eax
  106ed2:	89 04 24             	mov    %eax,(%esp)
  106ed5:	e8 2b f9 ff ff       	call   106805 <pmap_remove>
		assert(*dpde == PTE_ZERO);
  106eda:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  106edd:	8b 10                	mov    (%eax),%edx
  106edf:	b8 00 10 18 00       	mov    $0x181000,%eax
  106ee4:	39 c2                	cmp    %eax,%edx
  106ee6:	74 24                	je     106f0c <pmap_copy+0x224>
  106ee8:	c7 44 24 0c 94 d0 10 	movl   $0x10d094,0xc(%esp)
  106eef:	00 
  106ef0:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  106ef7:	00 
  106ef8:	c7 44 24 04 60 01 00 	movl   $0x160,0x4(%esp)
  106eff:	00 
  106f00:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  106f07:	e8 5c 9a ff ff       	call   100968 <debug_panic>
		*spde &= ~PTE_W;
  106f0c:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  106f0f:	8b 00                	mov    (%eax),%eax
  106f11:	89 c2                	mov    %eax,%edx
  106f13:	83 e2 fd             	and    $0xfffffffd,%edx
  106f16:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  106f19:	89 10                	mov    %edx,(%eax)
		*dpde = *spde;
  106f1b:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  106f1e:	8b 10                	mov    (%eax),%edx
  106f20:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  106f23:	89 10                	mov    %edx,(%eax)

		if (*spde != PTE_ZERO)
  106f25:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  106f28:	8b 10                	mov    (%eax),%edx
  106f2a:	b8 00 10 18 00       	mov    $0x181000,%eax
  106f2f:	39 c2                	cmp    %eax,%edx
  106f31:	0f 84 11 01 00 00    	je     107048 <pmap_copy+0x360>
			mem_incref(mem_phys2pi(PGADDR(*spde)));
  106f37:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  106f3a:	8b 00                	mov    (%eax),%eax
  106f3c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  106f41:	c1 e8 0c             	shr    $0xc,%eax
  106f44:	c1 e0 03             	shl    $0x3,%eax
  106f47:	89 c2                	mov    %eax,%edx
  106f49:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  106f4e:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106f51:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
// Atomically increment the reference count on a page.
static gcc_inline void
mem_incref(pageinfo *pi)
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  106f54:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  106f59:	83 c0 08             	add    $0x8,%eax
  106f5c:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  106f5f:	73 17                	jae    106f78 <pmap_copy+0x290>
  106f61:	a1 84 ed 17 00       	mov    0x17ed84,%eax
  106f66:	c1 e0 03             	shl    $0x3,%eax
  106f69:	89 c2                	mov    %eax,%edx
  106f6b:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  106f70:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106f73:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  106f76:	77 24                	ja     106f9c <pmap_copy+0x2b4>
  106f78:	c7 44 24 0c c0 ce 10 	movl   $0x10cec0,0xc(%esp)
  106f7f:	00 
  106f80:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  106f87:	00 
  106f88:	c7 44 24 04 8e 00 00 	movl   $0x8e,0x4(%esp)
  106f8f:	00 
  106f90:	c7 04 24 f7 ce 10 00 	movl   $0x10cef7,(%esp)
  106f97:	e8 cc 99 ff ff       	call   100968 <debug_panic>
	assert(pi != mem_ptr2pi(pmap_zero));	// Don't alloc/free zero page!
  106f9c:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  106fa2:	b8 00 10 18 00       	mov    $0x181000,%eax
  106fa7:	c1 e8 0c             	shr    $0xc,%eax
  106faa:	c1 e0 03             	shl    $0x3,%eax
  106fad:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106fb0:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  106fb3:	75 24                	jne    106fd9 <pmap_copy+0x2f1>
  106fb5:	c7 44 24 0c 04 cf 10 	movl   $0x10cf04,0xc(%esp)
  106fbc:	00 
  106fbd:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  106fc4:	00 
  106fc5:	c7 44 24 04 8f 00 00 	movl   $0x8f,0x4(%esp)
  106fcc:	00 
  106fcd:	c7 04 24 f7 ce 10 00 	movl   $0x10cef7,(%esp)
  106fd4:	e8 8f 99 ff ff       	call   100968 <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  106fd9:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  106fdf:	b8 0c 00 10 00       	mov    $0x10000c,%eax
  106fe4:	c1 e8 0c             	shr    $0xc,%eax
  106fe7:	c1 e0 03             	shl    $0x3,%eax
  106fea:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106fed:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  106ff0:	77 40                	ja     107032 <pmap_copy+0x34a>
  106ff2:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  106ff8:	b8 08 20 18 00       	mov    $0x182008,%eax
  106ffd:	83 e8 01             	sub    $0x1,%eax
  107000:	c1 e8 0c             	shr    $0xc,%eax
  107003:	c1 e0 03             	shl    $0x3,%eax
  107006:	8d 04 02             	lea    (%edx,%eax,1),%eax
  107009:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  10700c:	72 24                	jb     107032 <pmap_copy+0x34a>
  10700e:	c7 44 24 0c 20 cf 10 	movl   $0x10cf20,0xc(%esp)
  107015:	00 
  107016:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  10701d:	00 
  10701e:	c7 44 24 04 90 00 00 	movl   $0x90,0x4(%esp)
  107025:	00 
  107026:	c7 04 24 f7 ce 10 00 	movl   $0x10cef7,(%esp)
  10702d:	e8 36 99 ff ff       	call   100968 <debug_panic>

	lockadd(&pi->refcount, 1);
  107032:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  107035:	83 c0 04             	add    $0x4,%eax
  107038:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  10703f:	00 
  107040:	89 04 24             	mov    %eax,(%esp)
  107043:	e8 6e ed ff ff       	call   105db6 <lockadd>

		spde++, dpde++;
  107048:	83 45 f4 04          	addl   $0x4,0xfffffff4(%ebp)
  10704c:	83 45 f8 04          	addl   $0x4,0xfffffff8(%ebp)
		sva += PTSIZE;
  107050:	81 45 0c 00 00 40 00 	addl   $0x400000,0xc(%ebp)
		dva += PTSIZE;
  107057:	81 45 14 00 00 40 00 	addl   $0x400000,0x14(%ebp)
  10705e:	8b 45 0c             	mov    0xc(%ebp),%eax
  107061:	3b 45 f0             	cmp    0xfffffff0(%ebp),%eax
  107064:	0f 82 4a fe ff ff    	jb     106eb4 <pmap_copy+0x1cc>
	}
	
	return 1;
  10706a:	b8 01 00 00 00       	mov    $0x1,%eax
}
  10706f:	c9                   	leave  
  107070:	c3                   	ret    

00107071 <pmap_pagefault>:

//
// Transparently handle a page fault entirely in the kernel, if possible.
// If the page fault was caused by a write to a copy-on-write page,
// then performs the actual page copy on demand and calls trap_return().
// If the fault wasn't due to the kernel's copy on write optimization,
// however, this function just returns so the trap gets blamed on the user.
//
void
pmap_pagefault(trapframe *tf)
{
  107071:	55                   	push   %ebp
  107072:	89 e5                	mov    %esp,%ebp
  107074:	83 ec 48             	sub    $0x48,%esp
static gcc_inline uint32_t
rcr2(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr2,%0" : "=r" (val));
  107077:	0f 20 d0             	mov    %cr2,%eax
  10707a:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
	return val;
  10707d:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax

	uint32_t fva = rcr2();
  107080:	89 45 d4             	mov    %eax,0xffffffd4(%ebp)

	if (fva < VM_USERLO || fva >= VM_USERHI || !(tf->err & PFE_WR))
  107083:	81 7d d4 ff ff ff 3f 	cmpl   $0x3fffffff,0xffffffd4(%ebp)
  10708a:	76 16                	jbe    1070a2 <pmap_pagefault+0x31>
  10708c:	81 7d d4 ff ff ff ef 	cmpl   $0xefffffff,0xffffffd4(%ebp)
  107093:	77 0d                	ja     1070a2 <pmap_pagefault+0x31>
  107095:	8b 45 08             	mov    0x8(%ebp),%eax
  107098:	8b 40 34             	mov    0x34(%eax),%eax
  10709b:	83 e0 02             	and    $0x2,%eax
  10709e:	85 c0                	test   %eax,%eax
  1070a0:	75 22                	jne    1070c4 <pmap_pagefault+0x53>
	{
		cprintf("pmap_pagefault: fva %x err %x\n", fva, tf->err);
  1070a2:	8b 45 08             	mov    0x8(%ebp),%eax
  1070a5:	8b 40 34             	mov    0x34(%eax),%eax
  1070a8:	89 44 24 08          	mov    %eax,0x8(%esp)
  1070ac:	8b 45 d4             	mov    0xffffffd4(%ebp),%eax
  1070af:	89 44 24 04          	mov    %eax,0x4(%esp)
  1070b3:	c7 04 24 a8 d0 10 00 	movl   $0x10d0a8,(%esp)
  1070ba:	e8 b2 43 00 00       	call   10b471 <cprintf>
		return;
  1070bf:	e9 fc 03 00 00       	jmp    1074c0 <pmap_pagefault+0x44f>
	}


	proc *p = proc_cur();
  1070c4:	e8 46 eb ff ff       	call   105c0f <cpu_cur>
  1070c9:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  1070cf:	89 45 d8             	mov    %eax,0xffffffd8(%ebp)
	pde_t *pde = &p->pdir[PDX(fva)];
  1070d2:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  1070d5:	8b 90 a0 06 00 00    	mov    0x6a0(%eax),%edx
  1070db:	8b 45 d4             	mov    0xffffffd4(%ebp),%eax
  1070de:	c1 e8 16             	shr    $0x16,%eax
  1070e1:	25 ff 03 00 00       	and    $0x3ff,%eax
  1070e6:	c1 e0 02             	shl    $0x2,%eax
  1070e9:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1070ec:	89 45 dc             	mov    %eax,0xffffffdc(%ebp)
	if(!(*pde & PTE_P))
  1070ef:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  1070f2:	8b 00                	mov    (%eax),%eax
  1070f4:	83 e0 01             	and    $0x1,%eax
  1070f7:	85 c0                	test   %eax,%eax
  1070f9:	75 18                	jne    107113 <pmap_pagefault+0xa2>
	{
		cprintf("pmap_pagefault: pde for fva %x does not exist\n", fva);
  1070fb:	8b 45 d4             	mov    0xffffffd4(%ebp),%eax
  1070fe:	89 44 24 04          	mov    %eax,0x4(%esp)
  107102:	c7 04 24 c8 d0 10 00 	movl   $0x10d0c8,(%esp)
  107109:	e8 63 43 00 00       	call   10b471 <cprintf>
		return;
  10710e:	e9 ad 03 00 00       	jmp    1074c0 <pmap_pagefault+0x44f>
	}

	pte_t *pte = pmap_walk(p->pdir, fva, 1);
  107113:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  107116:	8b 90 a0 06 00 00    	mov    0x6a0(%eax),%edx
  10711c:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
  107123:	00 
  107124:	8b 45 d4             	mov    0xffffffd4(%ebp),%eax
  107127:	89 44 24 04          	mov    %eax,0x4(%esp)
  10712b:	89 14 24             	mov    %edx,(%esp)
  10712e:	e8 9c ee ff ff       	call   105fcf <pmap_walk>
  107133:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)
	if((*pte & (SYS_READ | SYS_WRITE | PTE_P)) != (SYS_READ | SYS_WRITE | PTE_P))
  107136:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  107139:	8b 00                	mov    (%eax),%eax
  10713b:	25 01 06 00 00       	and    $0x601,%eax
  107140:	3d 01 06 00 00       	cmp    $0x601,%eax
  107145:	74 18                	je     10715f <pmap_pagefault+0xee>
	{
		cprintf("pmap_pagefault: page for fva %x does not exist\n", fva);
  107147:	8b 45 d4             	mov    0xffffffd4(%ebp),%eax
  10714a:	89 44 24 04          	mov    %eax,0x4(%esp)
  10714e:	c7 04 24 f8 d0 10 00 	movl   $0x10d0f8,(%esp)
  107155:	e8 17 43 00 00       	call   10b471 <cprintf>
		return;
  10715a:	e9 61 03 00 00       	jmp    1074c0 <pmap_pagefault+0x44f>
	}

	assert(!(*pte & PTE_W));
  10715f:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  107162:	8b 00                	mov    (%eax),%eax
  107164:	83 e0 02             	and    $0x2,%eax
  107167:	85 c0                	test   %eax,%eax
  107169:	74 24                	je     10718f <pmap_pagefault+0x11e>
  10716b:	c7 44 24 0c 28 d1 10 	movl   $0x10d128,0xc(%esp)
  107172:	00 
  107173:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  10717a:	00 
  10717b:	c7 44 24 04 92 01 00 	movl   $0x192,0x4(%esp)
  107182:	00 
  107183:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  10718a:	e8 d9 97 ff ff       	call   100968 <debug_panic>

	uint32_t pg = PGADDR(*pte);
  10718f:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  107192:	8b 00                	mov    (%eax),%eax
  107194:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  107199:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
	if(pg == PTE_ZERO || mem_phys2pi(pg)->refcount > 1)
  10719c:	b8 00 10 18 00       	mov    $0x181000,%eax
  1071a1:	39 45 e4             	cmp    %eax,0xffffffe4(%ebp)
  1071a4:	74 1f                	je     1071c5 <pmap_pagefault+0x154>
  1071a6:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  1071a9:	c1 e8 0c             	shr    $0xc,%eax
  1071ac:	c1 e0 03             	shl    $0x3,%eax
  1071af:	89 c2                	mov    %eax,%edx
  1071b1:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  1071b6:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1071b9:	8b 40 04             	mov    0x4(%eax),%eax
  1071bc:	83 f8 01             	cmp    $0x1,%eax
  1071bf:	0f 8e bc 02 00 00    	jle    107481 <pmap_pagefault+0x410>
	{
		pageinfo *npi = mem_alloc();
  1071c5:	e8 81 9e ff ff       	call   10104b <mem_alloc>
  1071ca:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
		assert(npi);
  1071cd:	83 7d e8 00          	cmpl   $0x0,0xffffffe8(%ebp)
  1071d1:	75 24                	jne    1071f7 <pmap_pagefault+0x186>
  1071d3:	c7 44 24 0c 38 d1 10 	movl   $0x10d138,0xc(%esp)
  1071da:	00 
  1071db:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  1071e2:	00 
  1071e3:	c7 44 24 04 98 01 00 	movl   $0x198,0x4(%esp)
  1071ea:	00 
  1071eb:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  1071f2:	e8 71 97 ff ff       	call   100968 <debug_panic>
  1071f7:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  1071fa:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
// Atomically increment the reference count on a page.
static gcc_inline void
mem_incref(pageinfo *pi)
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  1071fd:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  107202:	83 c0 08             	add    $0x8,%eax
  107205:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  107208:	73 17                	jae    107221 <pmap_pagefault+0x1b0>
  10720a:	a1 84 ed 17 00       	mov    0x17ed84,%eax
  10720f:	c1 e0 03             	shl    $0x3,%eax
  107212:	89 c2                	mov    %eax,%edx
  107214:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  107219:	8d 04 02             	lea    (%edx,%eax,1),%eax
  10721c:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  10721f:	77 24                	ja     107245 <pmap_pagefault+0x1d4>
  107221:	c7 44 24 0c c0 ce 10 	movl   $0x10cec0,0xc(%esp)
  107228:	00 
  107229:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  107230:	00 
  107231:	c7 44 24 04 8e 00 00 	movl   $0x8e,0x4(%esp)
  107238:	00 
  107239:	c7 04 24 f7 ce 10 00 	movl   $0x10cef7,(%esp)
  107240:	e8 23 97 ff ff       	call   100968 <debug_panic>
	assert(pi != mem_ptr2pi(pmap_zero));	// Don't alloc/free zero page!
  107245:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  10724b:	b8 00 10 18 00       	mov    $0x181000,%eax
  107250:	c1 e8 0c             	shr    $0xc,%eax
  107253:	c1 e0 03             	shl    $0x3,%eax
  107256:	8d 04 02             	lea    (%edx,%eax,1),%eax
  107259:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  10725c:	75 24                	jne    107282 <pmap_pagefault+0x211>
  10725e:	c7 44 24 0c 04 cf 10 	movl   $0x10cf04,0xc(%esp)
  107265:	00 
  107266:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  10726d:	00 
  10726e:	c7 44 24 04 8f 00 00 	movl   $0x8f,0x4(%esp)
  107275:	00 
  107276:	c7 04 24 f7 ce 10 00 	movl   $0x10cef7,(%esp)
  10727d:	e8 e6 96 ff ff       	call   100968 <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  107282:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  107288:	b8 0c 00 10 00       	mov    $0x10000c,%eax
  10728d:	c1 e8 0c             	shr    $0xc,%eax
  107290:	c1 e0 03             	shl    $0x3,%eax
  107293:	8d 04 02             	lea    (%edx,%eax,1),%eax
  107296:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  107299:	77 40                	ja     1072db <pmap_pagefault+0x26a>
  10729b:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  1072a1:	b8 08 20 18 00       	mov    $0x182008,%eax
  1072a6:	83 e8 01             	sub    $0x1,%eax
  1072a9:	c1 e8 0c             	shr    $0xc,%eax
  1072ac:	c1 e0 03             	shl    $0x3,%eax
  1072af:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1072b2:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  1072b5:	72 24                	jb     1072db <pmap_pagefault+0x26a>
  1072b7:	c7 44 24 0c 20 cf 10 	movl   $0x10cf20,0xc(%esp)
  1072be:	00 
  1072bf:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  1072c6:	00 
  1072c7:	c7 44 24 04 90 00 00 	movl   $0x90,0x4(%esp)
  1072ce:	00 
  1072cf:	c7 04 24 f7 ce 10 00 	movl   $0x10cef7,(%esp)
  1072d6:	e8 8d 96 ff ff       	call   100968 <debug_panic>

	lockadd(&pi->refcount, 1);
  1072db:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  1072de:	83 c0 04             	add    $0x4,%eax
  1072e1:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  1072e8:	00 
  1072e9:	89 04 24             	mov    %eax,(%esp)
  1072ec:	e8 c5 ea ff ff       	call   105db6 <lockadd>
		mem_incref(npi);
		uint32_t npg = mem_pi2phys(npi);
  1072f1:	8b 55 e8             	mov    0xffffffe8(%ebp),%edx
  1072f4:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  1072f9:	89 d1                	mov    %edx,%ecx
  1072fb:	29 c1                	sub    %eax,%ecx
  1072fd:	89 c8                	mov    %ecx,%eax
  1072ff:	c1 e0 09             	shl    $0x9,%eax
  107302:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
		memmove((void*)npg, (void*)pg, PAGESIZE);
  107305:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  107308:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
  10730b:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  107312:	00 
  107313:	89 44 24 04          	mov    %eax,0x4(%esp)
  107317:	89 14 24             	mov    %edx,(%esp)
  10731a:	e8 4f 45 00 00       	call   10b86e <memmove>
		if(pg != PTE_ZERO)
  10731f:	b8 00 10 18 00       	mov    $0x181000,%eax
  107324:	39 45 e4             	cmp    %eax,0xffffffe4(%ebp)
  107327:	0f 84 4e 01 00 00    	je     10747b <pmap_pagefault+0x40a>
			mem_decref(mem_phys2pi(pg), mem_free);
  10732d:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  107330:	c1 e8 0c             	shr    $0xc,%eax
  107333:	c1 e0 03             	shl    $0x3,%eax
  107336:	89 c2                	mov    %eax,%edx
  107338:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  10733d:	8d 04 02             	lea    (%edx,%eax,1),%eax
  107340:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  107343:	c7 45 f8 8f 10 10 00 	movl   $0x10108f,0xfffffff8(%ebp)
// freeing the page with the provided function if there are no more refs.
static gcc_inline void
mem_decref(pageinfo* pi, void (*freefun)(pageinfo *pi))
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  10734a:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  10734f:	83 c0 08             	add    $0x8,%eax
  107352:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  107355:	73 17                	jae    10736e <pmap_pagefault+0x2fd>
  107357:	a1 84 ed 17 00       	mov    0x17ed84,%eax
  10735c:	c1 e0 03             	shl    $0x3,%eax
  10735f:	89 c2                	mov    %eax,%edx
  107361:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  107366:	8d 04 02             	lea    (%edx,%eax,1),%eax
  107369:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  10736c:	77 24                	ja     107392 <pmap_pagefault+0x321>
  10736e:	c7 44 24 0c c0 ce 10 	movl   $0x10cec0,0xc(%esp)
  107375:	00 
  107376:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  10737d:	00 
  10737e:	c7 44 24 04 9a 00 00 	movl   $0x9a,0x4(%esp)
  107385:	00 
  107386:	c7 04 24 f7 ce 10 00 	movl   $0x10cef7,(%esp)
  10738d:	e8 d6 95 ff ff       	call   100968 <debug_panic>
	assert(pi != mem_ptr2pi(pmap_zero));	// Don't alloc/free zero page!
  107392:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  107398:	b8 00 10 18 00       	mov    $0x181000,%eax
  10739d:	c1 e8 0c             	shr    $0xc,%eax
  1073a0:	c1 e0 03             	shl    $0x3,%eax
  1073a3:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1073a6:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  1073a9:	75 24                	jne    1073cf <pmap_pagefault+0x35e>
  1073ab:	c7 44 24 0c 04 cf 10 	movl   $0x10cf04,0xc(%esp)
  1073b2:	00 
  1073b3:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  1073ba:	00 
  1073bb:	c7 44 24 04 9b 00 00 	movl   $0x9b,0x4(%esp)
  1073c2:	00 
  1073c3:	c7 04 24 f7 ce 10 00 	movl   $0x10cef7,(%esp)
  1073ca:	e8 99 95 ff ff       	call   100968 <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  1073cf:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  1073d5:	b8 0c 00 10 00       	mov    $0x10000c,%eax
  1073da:	c1 e8 0c             	shr    $0xc,%eax
  1073dd:	c1 e0 03             	shl    $0x3,%eax
  1073e0:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1073e3:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  1073e6:	77 40                	ja     107428 <pmap_pagefault+0x3b7>
  1073e8:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  1073ee:	b8 08 20 18 00       	mov    $0x182008,%eax
  1073f3:	83 e8 01             	sub    $0x1,%eax
  1073f6:	c1 e8 0c             	shr    $0xc,%eax
  1073f9:	c1 e0 03             	shl    $0x3,%eax
  1073fc:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1073ff:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  107402:	72 24                	jb     107428 <pmap_pagefault+0x3b7>
  107404:	c7 44 24 0c 20 cf 10 	movl   $0x10cf20,0xc(%esp)
  10740b:	00 
  10740c:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  107413:	00 
  107414:	c7 44 24 04 9c 00 00 	movl   $0x9c,0x4(%esp)
  10741b:	00 
  10741c:	c7 04 24 f7 ce 10 00 	movl   $0x10cef7,(%esp)
  107423:	e8 40 95 ff ff       	call   100968 <debug_panic>

	if (lockaddz(&pi->refcount, -1))
  107428:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  10742b:	83 c0 04             	add    $0x4,%eax
  10742e:	c7 44 24 04 ff ff ff 	movl   $0xffffffff,0x4(%esp)
  107435:	ff 
  107436:	89 04 24             	mov    %eax,(%esp)
  107439:	e8 75 eb ff ff       	call   105fb3 <lockaddz>
  10743e:	84 c0                	test   %al,%al
  107440:	74 0b                	je     10744d <pmap_pagefault+0x3dc>
			freefun(pi);
  107442:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  107445:	89 04 24             	mov    %eax,(%esp)
  107448:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10744b:	ff d0                	call   *%eax
	assert(pi->refcount >= 0);
  10744d:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  107450:	8b 40 04             	mov    0x4(%eax),%eax
  107453:	85 c0                	test   %eax,%eax
  107455:	79 24                	jns    10747b <pmap_pagefault+0x40a>
  107457:	c7 44 24 0c 51 cf 10 	movl   $0x10cf51,0xc(%esp)
  10745e:	00 
  10745f:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  107466:	00 
  107467:	c7 44 24 04 a0 00 00 	movl   $0xa0,0x4(%esp)
  10746e:	00 
  10746f:	c7 04 24 f7 ce 10 00 	movl   $0x10cef7,(%esp)
  107476:	e8 ed 94 ff ff       	call   100968 <debug_panic>
		pg = npg;
  10747b:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  10747e:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
	}

	*pte = pg | SYS_RW | PTE_A | PTE_D | PTE_W | PTE_U | PTE_P;
  107481:	8b 55 e4             	mov    0xffffffe4(%ebp),%edx
  107484:	81 ca 67 06 00 00    	or     $0x667,%edx
  10748a:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  10748d:	89 10                	mov    %edx,(%eax)

	pmap_inval(p->pdir, PGADDR(fva), PAGESIZE);
  10748f:	8b 55 d4             	mov    0xffffffd4(%ebp),%edx
  107492:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
  107498:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  10749b:	8b 80 a0 06 00 00    	mov    0x6a0(%eax),%eax
  1074a1:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  1074a8:	00 
  1074a9:	89 54 24 04          	mov    %edx,0x4(%esp)
  1074ad:	89 04 24             	mov    %eax,(%esp)
  1074b0:	e8 e6 f7 ff ff       	call   106c9b <pmap_inval>
	trap_return(tf);
  1074b5:	8b 45 08             	mov    0x8(%ebp),%eax
  1074b8:	89 04 24             	mov    %eax,(%esp)
  1074bb:	e8 a0 c1 ff ff       	call   103660 <trap_return>
}
  1074c0:	c9                   	leave  
  1074c1:	c3                   	ret    

001074c2 <pmap_mergepage>:

//
// Helper function for pmap_merge: merge a single memory page
// that has been modified in both the source and destination.
// If conflicting writes to a single byte are detected on the page,
// print a warning to the console and remove the page from the destination.
// If the destination page is read-shared, be sure to copy it before modifying!
//
void
pmap_mergepage(pte_t *rpte, pte_t *spte, pte_t *dpte, uint32_t dva)
{
  1074c2:	55                   	push   %ebp
  1074c3:	89 e5                	mov    %esp,%ebp
  1074c5:	83 ec 48             	sub    $0x48,%esp
  uint8_t *rpg = (uint8_t*)PGADDR(*rpte);
  1074c8:	8b 45 08             	mov    0x8(%ebp),%eax
  1074cb:	8b 00                	mov    (%eax),%eax
  1074cd:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1074d2:	89 45 d4             	mov    %eax,0xffffffd4(%ebp)

  uint8_t *spg = (uint8_t*)PGADDR(*spte);
  1074d5:	8b 45 0c             	mov    0xc(%ebp),%eax
  1074d8:	8b 00                	mov    (%eax),%eax
  1074da:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1074df:	89 45 d8             	mov    %eax,0xffffffd8(%ebp)

  uint8_t *dpg = (uint8_t*)PGADDR(*dpte);
  1074e2:	8b 45 10             	mov    0x10(%ebp),%eax
  1074e5:	8b 00                	mov    (%eax),%eax
  1074e7:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1074ec:	89 45 dc             	mov    %eax,0xffffffdc(%ebp)
  if(dpg == pmap_zero) return;
  1074ef:	81 7d dc 00 10 18 00 	cmpl   $0x181000,0xffffffdc(%ebp)
  1074f6:	0f 84 d0 04 00 00    	je     1079cc <pmap_mergepage+0x50a>

  if(dpg == (uint8_t*)PTE_ZERO || mem_ptr2pi(dpg)->refcount > 1){
  1074fc:	b8 00 10 18 00       	mov    $0x181000,%eax
  107501:	39 45 dc             	cmp    %eax,0xffffffdc(%ebp)
  107504:	74 1f                	je     107525 <pmap_mergepage+0x63>
  107506:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  107509:	c1 e8 0c             	shr    $0xc,%eax
  10750c:	c1 e0 03             	shl    $0x3,%eax
  10750f:	89 c2                	mov    %eax,%edx
  107511:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  107516:	8d 04 02             	lea    (%edx,%eax,1),%eax
  107519:	8b 40 04             	mov    0x4(%eax),%eax
  10751c:	83 f8 01             	cmp    $0x1,%eax
  10751f:	0f 8e cc 02 00 00    	jle    1077f1 <pmap_mergepage+0x32f>
    pageinfo *npi = mem_alloc(); assert(npi);
  107525:	e8 21 9b ff ff       	call   10104b <mem_alloc>
  10752a:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
  10752d:	83 7d e4 00          	cmpl   $0x0,0xffffffe4(%ebp)
  107531:	75 24                	jne    107557 <pmap_mergepage+0x95>
  107533:	c7 44 24 0c 38 d1 10 	movl   $0x10d138,0xc(%esp)
  10753a:	00 
  10753b:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  107542:	00 
  107543:	c7 44 24 04 b9 01 00 	movl   $0x1b9,0x4(%esp)
  10754a:	00 
  10754b:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  107552:	e8 11 94 ff ff       	call   100968 <debug_panic>
  107557:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  10755a:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
// Atomically increment the reference count on a page.
static gcc_inline void
mem_incref(pageinfo *pi)
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  10755d:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  107562:	83 c0 08             	add    $0x8,%eax
  107565:	3b 45 ec             	cmp    0xffffffec(%ebp),%eax
  107568:	73 17                	jae    107581 <pmap_mergepage+0xbf>
  10756a:	a1 84 ed 17 00       	mov    0x17ed84,%eax
  10756f:	c1 e0 03             	shl    $0x3,%eax
  107572:	89 c2                	mov    %eax,%edx
  107574:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  107579:	8d 04 02             	lea    (%edx,%eax,1),%eax
  10757c:	3b 45 ec             	cmp    0xffffffec(%ebp),%eax
  10757f:	77 24                	ja     1075a5 <pmap_mergepage+0xe3>
  107581:	c7 44 24 0c c0 ce 10 	movl   $0x10cec0,0xc(%esp)
  107588:	00 
  107589:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  107590:	00 
  107591:	c7 44 24 04 8e 00 00 	movl   $0x8e,0x4(%esp)
  107598:	00 
  107599:	c7 04 24 f7 ce 10 00 	movl   $0x10cef7,(%esp)
  1075a0:	e8 c3 93 ff ff       	call   100968 <debug_panic>
	assert(pi != mem_ptr2pi(pmap_zero));	// Don't alloc/free zero page!
  1075a5:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  1075ab:	b8 00 10 18 00       	mov    $0x181000,%eax
  1075b0:	c1 e8 0c             	shr    $0xc,%eax
  1075b3:	c1 e0 03             	shl    $0x3,%eax
  1075b6:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1075b9:	3b 45 ec             	cmp    0xffffffec(%ebp),%eax
  1075bc:	75 24                	jne    1075e2 <pmap_mergepage+0x120>
  1075be:	c7 44 24 0c 04 cf 10 	movl   $0x10cf04,0xc(%esp)
  1075c5:	00 
  1075c6:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  1075cd:	00 
  1075ce:	c7 44 24 04 8f 00 00 	movl   $0x8f,0x4(%esp)
  1075d5:	00 
  1075d6:	c7 04 24 f7 ce 10 00 	movl   $0x10cef7,(%esp)
  1075dd:	e8 86 93 ff ff       	call   100968 <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  1075e2:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  1075e8:	b8 0c 00 10 00       	mov    $0x10000c,%eax
  1075ed:	c1 e8 0c             	shr    $0xc,%eax
  1075f0:	c1 e0 03             	shl    $0x3,%eax
  1075f3:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1075f6:	3b 45 ec             	cmp    0xffffffec(%ebp),%eax
  1075f9:	77 40                	ja     10763b <pmap_mergepage+0x179>
  1075fb:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  107601:	b8 08 20 18 00       	mov    $0x182008,%eax
  107606:	83 e8 01             	sub    $0x1,%eax
  107609:	c1 e8 0c             	shr    $0xc,%eax
  10760c:	c1 e0 03             	shl    $0x3,%eax
  10760f:	8d 04 02             	lea    (%edx,%eax,1),%eax
  107612:	3b 45 ec             	cmp    0xffffffec(%ebp),%eax
  107615:	72 24                	jb     10763b <pmap_mergepage+0x179>
  107617:	c7 44 24 0c 20 cf 10 	movl   $0x10cf20,0xc(%esp)
  10761e:	00 
  10761f:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  107626:	00 
  107627:	c7 44 24 04 90 00 00 	movl   $0x90,0x4(%esp)
  10762e:	00 
  10762f:	c7 04 24 f7 ce 10 00 	movl   $0x10cef7,(%esp)
  107636:	e8 2d 93 ff ff       	call   100968 <debug_panic>

	lockadd(&pi->refcount, 1);
  10763b:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  10763e:	83 c0 04             	add    $0x4,%eax
  107641:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  107648:	00 
  107649:	89 04 24             	mov    %eax,(%esp)
  10764c:	e8 65 e7 ff ff       	call   105db6 <lockadd>
    mem_incref(npi);
    uint8_t *npg = mem_pi2ptr(npi);
  107651:	8b 55 e4             	mov    0xffffffe4(%ebp),%edx
  107654:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  107659:	89 d1                	mov    %edx,%ecx
  10765b:	29 c1                	sub    %eax,%ecx
  10765d:	89 c8                	mov    %ecx,%eax
  10765f:	c1 e0 09             	shl    $0x9,%eax
  107662:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
    memmove(npg, dpg, PAGESIZE);
  107665:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  10766c:	00 
  10766d:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  107670:	89 44 24 04          	mov    %eax,0x4(%esp)
  107674:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  107677:	89 04 24             	mov    %eax,(%esp)
  10767a:	e8 ef 41 00 00       	call   10b86e <memmove>
    if(dpg != (uint8_t*)PTE_ZERO)
  10767f:	b8 00 10 18 00       	mov    $0x181000,%eax
  107684:	39 45 dc             	cmp    %eax,0xffffffdc(%ebp)
  107687:	0f 84 4e 01 00 00    	je     1077db <pmap_mergepage+0x319>
      mem_decref(mem_ptr2pi(dpg), mem_free);
  10768d:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  107690:	c1 e8 0c             	shr    $0xc,%eax
  107693:	c1 e0 03             	shl    $0x3,%eax
  107696:	89 c2                	mov    %eax,%edx
  107698:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  10769d:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1076a0:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
  1076a3:	c7 45 f0 8f 10 10 00 	movl   $0x10108f,0xfffffff0(%ebp)
// freeing the page with the provided function if there are no more refs.
static gcc_inline void
mem_decref(pageinfo* pi, void (*freefun)(pageinfo *pi))
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  1076aa:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  1076af:	83 c0 08             	add    $0x8,%eax
  1076b2:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  1076b5:	73 17                	jae    1076ce <pmap_mergepage+0x20c>
  1076b7:	a1 84 ed 17 00       	mov    0x17ed84,%eax
  1076bc:	c1 e0 03             	shl    $0x3,%eax
  1076bf:	89 c2                	mov    %eax,%edx
  1076c1:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  1076c6:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1076c9:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  1076cc:	77 24                	ja     1076f2 <pmap_mergepage+0x230>
  1076ce:	c7 44 24 0c c0 ce 10 	movl   $0x10cec0,0xc(%esp)
  1076d5:	00 
  1076d6:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  1076dd:	00 
  1076de:	c7 44 24 04 9a 00 00 	movl   $0x9a,0x4(%esp)
  1076e5:	00 
  1076e6:	c7 04 24 f7 ce 10 00 	movl   $0x10cef7,(%esp)
  1076ed:	e8 76 92 ff ff       	call   100968 <debug_panic>
	assert(pi != mem_ptr2pi(pmap_zero));	// Don't alloc/free zero page!
  1076f2:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  1076f8:	b8 00 10 18 00       	mov    $0x181000,%eax
  1076fd:	c1 e8 0c             	shr    $0xc,%eax
  107700:	c1 e0 03             	shl    $0x3,%eax
  107703:	8d 04 02             	lea    (%edx,%eax,1),%eax
  107706:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  107709:	75 24                	jne    10772f <pmap_mergepage+0x26d>
  10770b:	c7 44 24 0c 04 cf 10 	movl   $0x10cf04,0xc(%esp)
  107712:	00 
  107713:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  10771a:	00 
  10771b:	c7 44 24 04 9b 00 00 	movl   $0x9b,0x4(%esp)
  107722:	00 
  107723:	c7 04 24 f7 ce 10 00 	movl   $0x10cef7,(%esp)
  10772a:	e8 39 92 ff ff       	call   100968 <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  10772f:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  107735:	b8 0c 00 10 00       	mov    $0x10000c,%eax
  10773a:	c1 e8 0c             	shr    $0xc,%eax
  10773d:	c1 e0 03             	shl    $0x3,%eax
  107740:	8d 04 02             	lea    (%edx,%eax,1),%eax
  107743:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  107746:	77 40                	ja     107788 <pmap_mergepage+0x2c6>
  107748:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  10774e:	b8 08 20 18 00       	mov    $0x182008,%eax
  107753:	83 e8 01             	sub    $0x1,%eax
  107756:	c1 e8 0c             	shr    $0xc,%eax
  107759:	c1 e0 03             	shl    $0x3,%eax
  10775c:	8d 04 02             	lea    (%edx,%eax,1),%eax
  10775f:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  107762:	72 24                	jb     107788 <pmap_mergepage+0x2c6>
  107764:	c7 44 24 0c 20 cf 10 	movl   $0x10cf20,0xc(%esp)
  10776b:	00 
  10776c:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  107773:	00 
  107774:	c7 44 24 04 9c 00 00 	movl   $0x9c,0x4(%esp)
  10777b:	00 
  10777c:	c7 04 24 f7 ce 10 00 	movl   $0x10cef7,(%esp)
  107783:	e8 e0 91 ff ff       	call   100968 <debug_panic>

	if (lockaddz(&pi->refcount, -1))
  107788:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  10778b:	83 c0 04             	add    $0x4,%eax
  10778e:	c7 44 24 04 ff ff ff 	movl   $0xffffffff,0x4(%esp)
  107795:	ff 
  107796:	89 04 24             	mov    %eax,(%esp)
  107799:	e8 15 e8 ff ff       	call   105fb3 <lockaddz>
  10779e:	84 c0                	test   %al,%al
  1077a0:	74 0b                	je     1077ad <pmap_mergepage+0x2eb>
			freefun(pi);
  1077a2:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  1077a5:	89 04 24             	mov    %eax,(%esp)
  1077a8:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  1077ab:	ff d0                	call   *%eax
	assert(pi->refcount >= 0);
  1077ad:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  1077b0:	8b 40 04             	mov    0x4(%eax),%eax
  1077b3:	85 c0                	test   %eax,%eax
  1077b5:	79 24                	jns    1077db <pmap_mergepage+0x319>
  1077b7:	c7 44 24 0c 51 cf 10 	movl   $0x10cf51,0xc(%esp)
  1077be:	00 
  1077bf:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  1077c6:	00 
  1077c7:	c7 44 24 04 a0 00 00 	movl   $0xa0,0x4(%esp)
  1077ce:	00 
  1077cf:	c7 04 24 f7 ce 10 00 	movl   $0x10cef7,(%esp)
  1077d6:	e8 8d 91 ff ff       	call   100968 <debug_panic>
      dpg = npg;
  1077db:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  1077de:	89 45 dc             	mov    %eax,0xffffffdc(%ebp)
      *dpte = (uint32_t)npg | SYS_RW | PTE_A | PTE_D | PTE_W | PTE_U | PTE_P;
  1077e1:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  1077e4:	89 c2                	mov    %eax,%edx
  1077e6:	81 ca 67 06 00 00    	or     $0x667,%edx
  1077ec:	8b 45 10             	mov    0x10(%ebp),%eax
  1077ef:	89 10                	mov    %edx,(%eax)
      }

      int i;
      for(i = 0; i < PAGESIZE; i++){
  1077f1:	c7 45 e0 00 00 00 00 	movl   $0x0,0xffffffe0(%ebp)
  1077f8:	e9 c2 01 00 00       	jmp    1079bf <pmap_mergepage+0x4fd>
      if(spg[i] == rpg[i])
  1077fd:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  107800:	03 45 d8             	add    0xffffffd8(%ebp),%eax
  107803:	0f b6 10             	movzbl (%eax),%edx
  107806:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  107809:	03 45 d4             	add    0xffffffd4(%ebp),%eax
  10780c:	0f b6 00             	movzbl (%eax),%eax
  10780f:	38 c2                	cmp    %al,%dl
  107811:	0f 84 a4 01 00 00    	je     1079bb <pmap_mergepage+0x4f9>
      continue;
      if(dpg[i] == rpg[i]){
  107817:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  10781a:	03 45 dc             	add    0xffffffdc(%ebp),%eax
  10781d:	0f b6 10             	movzbl (%eax),%edx
  107820:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  107823:	03 45 d4             	add    0xffffffd4(%ebp),%eax
  107826:	0f b6 00             	movzbl (%eax),%eax
  107829:	38 c2                	cmp    %al,%dl
  10782b:	75 18                	jne    107845 <pmap_mergepage+0x383>
      dpg[i] = spg[i];
  10782d:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  107830:	89 c2                	mov    %eax,%edx
  107832:	03 55 dc             	add    0xffffffdc(%ebp),%edx
  107835:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  107838:	03 45 d8             	add    0xffffffd8(%ebp),%eax
  10783b:	0f b6 00             	movzbl (%eax),%eax
  10783e:	88 02                	mov    %al,(%edx)
      continue;
  107840:	e9 76 01 00 00       	jmp    1079bb <pmap_mergepage+0x4f9>
      }

      cprintf("pmap_mergepage: conflict ad dva %x\n", dva);
  107845:	8b 45 14             	mov    0x14(%ebp),%eax
  107848:	89 44 24 04          	mov    %eax,0x4(%esp)
  10784c:	c7 04 24 3c d1 10 00 	movl   $0x10d13c,(%esp)
  107853:	e8 19 3c 00 00       	call   10b471 <cprintf>
      mem_decref(mem_phys2pi(PGADDR(*dpte)), mem_free);
  107858:	8b 45 10             	mov    0x10(%ebp),%eax
  10785b:	8b 00                	mov    (%eax),%eax
  10785d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  107862:	c1 e8 0c             	shr    $0xc,%eax
  107865:	c1 e0 03             	shl    $0x3,%eax
  107868:	89 c2                	mov    %eax,%edx
  10786a:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  10786f:	8d 04 02             	lea    (%edx,%eax,1),%eax
  107872:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  107875:	c7 45 f8 8f 10 10 00 	movl   $0x10108f,0xfffffff8(%ebp)
// freeing the page with the provided function if there are no more refs.
static gcc_inline void
mem_decref(pageinfo* pi, void (*freefun)(pageinfo *pi))
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  10787c:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  107881:	83 c0 08             	add    $0x8,%eax
  107884:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  107887:	73 17                	jae    1078a0 <pmap_mergepage+0x3de>
  107889:	a1 84 ed 17 00       	mov    0x17ed84,%eax
  10788e:	c1 e0 03             	shl    $0x3,%eax
  107891:	89 c2                	mov    %eax,%edx
  107893:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  107898:	8d 04 02             	lea    (%edx,%eax,1),%eax
  10789b:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  10789e:	77 24                	ja     1078c4 <pmap_mergepage+0x402>
  1078a0:	c7 44 24 0c c0 ce 10 	movl   $0x10cec0,0xc(%esp)
  1078a7:	00 
  1078a8:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  1078af:	00 
  1078b0:	c7 44 24 04 9a 00 00 	movl   $0x9a,0x4(%esp)
  1078b7:	00 
  1078b8:	c7 04 24 f7 ce 10 00 	movl   $0x10cef7,(%esp)
  1078bf:	e8 a4 90 ff ff       	call   100968 <debug_panic>
	assert(pi != mem_ptr2pi(pmap_zero));	// Don't alloc/free zero page!
  1078c4:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  1078ca:	b8 00 10 18 00       	mov    $0x181000,%eax
  1078cf:	c1 e8 0c             	shr    $0xc,%eax
  1078d2:	c1 e0 03             	shl    $0x3,%eax
  1078d5:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1078d8:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  1078db:	75 24                	jne    107901 <pmap_mergepage+0x43f>
  1078dd:	c7 44 24 0c 04 cf 10 	movl   $0x10cf04,0xc(%esp)
  1078e4:	00 
  1078e5:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  1078ec:	00 
  1078ed:	c7 44 24 04 9b 00 00 	movl   $0x9b,0x4(%esp)
  1078f4:	00 
  1078f5:	c7 04 24 f7 ce 10 00 	movl   $0x10cef7,(%esp)
  1078fc:	e8 67 90 ff ff       	call   100968 <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  107901:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  107907:	b8 0c 00 10 00       	mov    $0x10000c,%eax
  10790c:	c1 e8 0c             	shr    $0xc,%eax
  10790f:	c1 e0 03             	shl    $0x3,%eax
  107912:	8d 04 02             	lea    (%edx,%eax,1),%eax
  107915:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  107918:	77 40                	ja     10795a <pmap_mergepage+0x498>
  10791a:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  107920:	b8 08 20 18 00       	mov    $0x182008,%eax
  107925:	83 e8 01             	sub    $0x1,%eax
  107928:	c1 e8 0c             	shr    $0xc,%eax
  10792b:	c1 e0 03             	shl    $0x3,%eax
  10792e:	8d 04 02             	lea    (%edx,%eax,1),%eax
  107931:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  107934:	72 24                	jb     10795a <pmap_mergepage+0x498>
  107936:	c7 44 24 0c 20 cf 10 	movl   $0x10cf20,0xc(%esp)
  10793d:	00 
  10793e:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  107945:	00 
  107946:	c7 44 24 04 9c 00 00 	movl   $0x9c,0x4(%esp)
  10794d:	00 
  10794e:	c7 04 24 f7 ce 10 00 	movl   $0x10cef7,(%esp)
  107955:	e8 0e 90 ff ff       	call   100968 <debug_panic>

	if (lockaddz(&pi->refcount, -1))
  10795a:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  10795d:	83 c0 04             	add    $0x4,%eax
  107960:	c7 44 24 04 ff ff ff 	movl   $0xffffffff,0x4(%esp)
  107967:	ff 
  107968:	89 04 24             	mov    %eax,(%esp)
  10796b:	e8 43 e6 ff ff       	call   105fb3 <lockaddz>
  107970:	84 c0                	test   %al,%al
  107972:	74 0b                	je     10797f <pmap_mergepage+0x4bd>
			freefun(pi);
  107974:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  107977:	89 04 24             	mov    %eax,(%esp)
  10797a:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10797d:	ff d0                	call   *%eax
	assert(pi->refcount >= 0);
  10797f:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  107982:	8b 40 04             	mov    0x4(%eax),%eax
  107985:	85 c0                	test   %eax,%eax
  107987:	79 24                	jns    1079ad <pmap_mergepage+0x4eb>
  107989:	c7 44 24 0c 51 cf 10 	movl   $0x10cf51,0xc(%esp)
  107990:	00 
  107991:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  107998:	00 
  107999:	c7 44 24 04 a0 00 00 	movl   $0xa0,0x4(%esp)
  1079a0:	00 
  1079a1:	c7 04 24 f7 ce 10 00 	movl   $0x10cef7,(%esp)
  1079a8:	e8 bb 8f ff ff       	call   100968 <debug_panic>
      *dpte = PTE_ZERO;
  1079ad:	b8 00 10 18 00       	mov    $0x181000,%eax
  1079b2:	89 c2                	mov    %eax,%edx
  1079b4:	8b 45 10             	mov    0x10(%ebp),%eax
  1079b7:	89 10                	mov    %edx,(%eax)
      return;
  1079b9:	eb 11                	jmp    1079cc <pmap_mergepage+0x50a>
  1079bb:	83 45 e0 01          	addl   $0x1,0xffffffe0(%ebp)
  1079bf:	81 7d e0 ff 0f 00 00 	cmpl   $0xfff,0xffffffe0(%ebp)
  1079c6:	0f 8e 31 fe ff ff    	jle    1077fd <pmap_mergepage+0x33b>
      }
}
  1079cc:	c9                   	leave  
  1079cd:	c3                   	ret    

001079ce <pmap_merge>:

// 
// Merge differences between a reference snapshot represented by rpdir
// and a source address space spdir into a destination address space dpdir.
//
int
pmap_merge(pde_t *rpdir, pde_t *spdir, uint32_t sva,
		pde_t *dpdir, uint32_t dva, size_t size)
{
  1079ce:	55                   	push   %ebp
  1079cf:	89 e5                	mov    %esp,%ebp
  1079d1:	83 ec 48             	sub    $0x48,%esp
	assert(PTOFF(sva) == 0);	// must be 4MB-aligned
  1079d4:	8b 45 10             	mov    0x10(%ebp),%eax
  1079d7:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  1079dc:	85 c0                	test   %eax,%eax
  1079de:	74 24                	je     107a04 <pmap_merge+0x36>
  1079e0:	c7 44 24 0c e8 cf 10 	movl   $0x10cfe8,0xc(%esp)
  1079e7:	00 
  1079e8:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  1079ef:	00 
  1079f0:	c7 44 24 04 db 01 00 	movl   $0x1db,0x4(%esp)
  1079f7:	00 
  1079f8:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  1079ff:	e8 64 8f ff ff       	call   100968 <debug_panic>
	assert(PTOFF(dva) == 0);
  107a04:	8b 45 18             	mov    0x18(%ebp),%eax
  107a07:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  107a0c:	85 c0                	test   %eax,%eax
  107a0e:	74 24                	je     107a34 <pmap_merge+0x66>
  107a10:	c7 44 24 0c f8 cf 10 	movl   $0x10cff8,0xc(%esp)
  107a17:	00 
  107a18:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  107a1f:	00 
  107a20:	c7 44 24 04 dc 01 00 	movl   $0x1dc,0x4(%esp)
  107a27:	00 
  107a28:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  107a2f:	e8 34 8f ff ff       	call   100968 <debug_panic>
	assert(PTOFF(size) == 0);
  107a34:	8b 45 1c             	mov    0x1c(%ebp),%eax
  107a37:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  107a3c:	85 c0                	test   %eax,%eax
  107a3e:	74 24                	je     107a64 <pmap_merge+0x96>
  107a40:	c7 44 24 0c 08 d0 10 	movl   $0x10d008,0xc(%esp)
  107a47:	00 
  107a48:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  107a4f:	00 
  107a50:	c7 44 24 04 dd 01 00 	movl   $0x1dd,0x4(%esp)
  107a57:	00 
  107a58:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  107a5f:	e8 04 8f ff ff       	call   100968 <debug_panic>
	assert(sva >= VM_USERLO && sva < VM_USERHI);
  107a64:	81 7d 10 ff ff ff 3f 	cmpl   $0x3fffffff,0x10(%ebp)
  107a6b:	76 09                	jbe    107a76 <pmap_merge+0xa8>
  107a6d:	81 7d 10 ff ff ff ef 	cmpl   $0xefffffff,0x10(%ebp)
  107a74:	76 24                	jbe    107a9a <pmap_merge+0xcc>
  107a76:	c7 44 24 0c 1c d0 10 	movl   $0x10d01c,0xc(%esp)
  107a7d:	00 
  107a7e:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  107a85:	00 
  107a86:	c7 44 24 04 de 01 00 	movl   $0x1de,0x4(%esp)
  107a8d:	00 
  107a8e:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  107a95:	e8 ce 8e ff ff       	call   100968 <debug_panic>
	assert(dva >= VM_USERLO && dva < VM_USERHI);
  107a9a:	81 7d 18 ff ff ff 3f 	cmpl   $0x3fffffff,0x18(%ebp)
  107aa1:	76 09                	jbe    107aac <pmap_merge+0xde>
  107aa3:	81 7d 18 ff ff ff ef 	cmpl   $0xefffffff,0x18(%ebp)
  107aaa:	76 24                	jbe    107ad0 <pmap_merge+0x102>
  107aac:	c7 44 24 0c 40 d0 10 	movl   $0x10d040,0xc(%esp)
  107ab3:	00 
  107ab4:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  107abb:	00 
  107abc:	c7 44 24 04 df 01 00 	movl   $0x1df,0x4(%esp)
  107ac3:	00 
  107ac4:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  107acb:	e8 98 8e ff ff       	call   100968 <debug_panic>
	assert(size <= VM_USERHI - sva);
  107ad0:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
  107ad5:	2b 45 10             	sub    0x10(%ebp),%eax
  107ad8:	3b 45 1c             	cmp    0x1c(%ebp),%eax
  107adb:	73 24                	jae    107b01 <pmap_merge+0x133>
  107add:	c7 44 24 0c 64 d0 10 	movl   $0x10d064,0xc(%esp)
  107ae4:	00 
  107ae5:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  107aec:	00 
  107aed:	c7 44 24 04 e0 01 00 	movl   $0x1e0,0x4(%esp)
  107af4:	00 
  107af5:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  107afc:	e8 67 8e ff ff       	call   100968 <debug_panic>
	assert(size <= VM_USERHI - dva);
  107b01:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
  107b06:	2b 45 18             	sub    0x18(%ebp),%eax
  107b09:	3b 45 1c             	cmp    0x1c(%ebp),%eax
  107b0c:	73 24                	jae    107b32 <pmap_merge+0x164>
  107b0e:	c7 44 24 0c 7c d0 10 	movl   $0x10d07c,0xc(%esp)
  107b15:	00 
  107b16:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  107b1d:	00 
  107b1e:	c7 44 24 04 e1 01 00 	movl   $0x1e1,0x4(%esp)
  107b25:	00 
  107b26:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  107b2d:	e8 36 8e ff ff       	call   100968 <debug_panic>

  pde_t *rpde = &rpdir[PDX(sva)];
  107b32:	8b 45 10             	mov    0x10(%ebp),%eax
  107b35:	c1 e8 16             	shr    $0x16,%eax
  107b38:	25 ff 03 00 00       	and    $0x3ff,%eax
  107b3d:	c1 e0 02             	shl    $0x2,%eax
  107b40:	03 45 08             	add    0x8(%ebp),%eax
  107b43:	89 45 d4             	mov    %eax,0xffffffd4(%ebp)
  pde_t *spde = &spdir[PDX(sva)];
  107b46:	8b 45 10             	mov    0x10(%ebp),%eax
  107b49:	c1 e8 16             	shr    $0x16,%eax
  107b4c:	25 ff 03 00 00       	and    $0x3ff,%eax
  107b51:	c1 e0 02             	shl    $0x2,%eax
  107b54:	03 45 0c             	add    0xc(%ebp),%eax
  107b57:	89 45 d8             	mov    %eax,0xffffffd8(%ebp)
  pde_t *dpde = &dpdir[PDX(dva)];
  107b5a:	8b 45 18             	mov    0x18(%ebp),%eax
  107b5d:	c1 e8 16             	shr    $0x16,%eax
  107b60:	25 ff 03 00 00       	and    $0x3ff,%eax
  107b65:	c1 e0 02             	shl    $0x2,%eax
  107b68:	03 45 14             	add    0x14(%ebp),%eax
  107b6b:	89 45 dc             	mov    %eax,0xffffffdc(%ebp)
  uint32_t svahi = sva + size;
  107b6e:	8b 45 1c             	mov    0x1c(%ebp),%eax
  107b71:	03 45 10             	add    0x10(%ebp),%eax
  107b74:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)

  for (; sva < svahi; rpde++, spde++, dpde++){
  107b77:	e9 e4 03 00 00       	jmp    107f60 <pmap_merge+0x592>
  if(*spde == *rpde){
  107b7c:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  107b7f:	8b 10                	mov    (%eax),%edx
  107b81:	8b 45 d4             	mov    0xffffffd4(%ebp),%eax
  107b84:	8b 00                	mov    (%eax),%eax
  107b86:	39 c2                	cmp    %eax,%edx
  107b88:	75 13                	jne    107b9d <pmap_merge+0x1cf>
  sva += PTSIZE, dva += PTSIZE;
  107b8a:	81 45 10 00 00 40 00 	addl   $0x400000,0x10(%ebp)
  107b91:	81 45 18 00 00 40 00 	addl   $0x400000,0x18(%ebp)
  continue;
  107b98:	e9 b7 03 00 00       	jmp    107f54 <pmap_merge+0x586>
  }

  if(*dpde == *rpde){
  107b9d:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  107ba0:	8b 10                	mov    (%eax),%edx
  107ba2:	8b 45 d4             	mov    0xffffffd4(%ebp),%eax
  107ba5:	8b 00                	mov    (%eax),%eax
  107ba7:	39 c2                	cmp    %eax,%edx
  107ba9:	75 4b                	jne    107bf6 <pmap_merge+0x228>
    if(!pmap_copy(spdir, sva, dpdir, dva, PTSIZE))
  107bab:	c7 44 24 10 00 00 40 	movl   $0x400000,0x10(%esp)
  107bb2:	00 
  107bb3:	8b 45 18             	mov    0x18(%ebp),%eax
  107bb6:	89 44 24 0c          	mov    %eax,0xc(%esp)
  107bba:	8b 45 14             	mov    0x14(%ebp),%eax
  107bbd:	89 44 24 08          	mov    %eax,0x8(%esp)
  107bc1:	8b 45 10             	mov    0x10(%ebp),%eax
  107bc4:	89 44 24 04          	mov    %eax,0x4(%esp)
  107bc8:	8b 45 0c             	mov    0xc(%ebp),%eax
  107bcb:	89 04 24             	mov    %eax,(%esp)
  107bce:	e8 15 f1 ff ff       	call   106ce8 <pmap_copy>
  107bd3:	85 c0                	test   %eax,%eax
  107bd5:	75 0c                	jne    107be3 <pmap_merge+0x215>
      return 0;
  107bd7:	c7 45 cc 00 00 00 00 	movl   $0x0,0xffffffcc(%ebp)
  107bde:	e9 90 03 00 00       	jmp    107f73 <pmap_merge+0x5a5>
      sva += PTSIZE, dva += PTSIZE;
  107be3:	81 45 10 00 00 40 00 	addl   $0x400000,0x10(%ebp)
  107bea:	81 45 18 00 00 40 00 	addl   $0x400000,0x18(%ebp)
      continue;
  107bf1:	e9 5e 03 00 00       	jmp    107f54 <pmap_merge+0x586>
      }

      pte_t *rpte = mem_ptr(PGADDR(*rpde));
  107bf6:	8b 45 d4             	mov    0xffffffd4(%ebp),%eax
  107bf9:	8b 00                	mov    (%eax),%eax
  107bfb:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  107c00:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
      pte_t *spte = mem_ptr(PGADDR(*spde));
  107c03:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  107c06:	8b 00                	mov    (%eax),%eax
  107c08:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  107c0d:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
      pte_t *dpte = pmap_walk(dpdir, dva, 1);
  107c10:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
  107c17:	00 
  107c18:	8b 45 18             	mov    0x18(%ebp),%eax
  107c1b:	89 44 24 04          	mov    %eax,0x4(%esp)
  107c1f:	8b 45 14             	mov    0x14(%ebp),%eax
  107c22:	89 04 24             	mov    %eax,(%esp)
  107c25:	e8 a5 e3 ff ff       	call   105fcf <pmap_walk>
  107c2a:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
      if (dpte == NULL)
  107c2d:	83 7d ec 00          	cmpl   $0x0,0xffffffec(%ebp)
  107c31:	75 0c                	jne    107c3f <pmap_merge+0x271>
        return 0;
  107c33:	c7 45 cc 00 00 00 00 	movl   $0x0,0xffffffcc(%ebp)
  107c3a:	e9 34 03 00 00       	jmp    107f73 <pmap_merge+0x5a5>

        pte_t *erpte = &rpte[NPTENTRIES];
  107c3f:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  107c42:	05 00 10 00 00       	add    $0x1000,%eax
  107c47:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
        for(; rpte <erpte; rpte++, spte++, dpte++, sva += PAGESIZE, dva += PAGESIZE){
  107c4a:	e9 f9 02 00 00       	jmp    107f48 <pmap_merge+0x57a>
        
        if (*spte == *rpte)
  107c4f:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  107c52:	8b 10                	mov    (%eax),%edx
  107c54:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  107c57:	8b 00                	mov    (%eax),%eax
  107c59:	39 c2                	cmp    %eax,%edx
  107c5b:	0f 84 cd 02 00 00    	je     107f2e <pmap_merge+0x560>
        continue;
        if (*dpte == *rpte)
  107c61:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  107c64:	8b 10                	mov    (%eax),%edx
  107c66:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  107c69:	8b 00                	mov    (%eax),%eax
  107c6b:	39 c2                	cmp    %eax,%edx
  107c6d:	0f 85 9b 02 00 00    	jne    107f0e <pmap_merge+0x540>
        { if(PGADDR(*dpte) != PTE_ZERO)
  107c73:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  107c76:	8b 00                	mov    (%eax),%eax
  107c78:	89 c2                	mov    %eax,%edx
  107c7a:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
  107c80:	b8 00 10 18 00       	mov    $0x181000,%eax
  107c85:	39 c2                	cmp    %eax,%edx
  107c87:	0f 84 55 01 00 00    	je     107de2 <pmap_merge+0x414>
          mem_decref(mem_phys2pi(PGADDR(*dpte)),mem_free);
  107c8d:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  107c90:	8b 00                	mov    (%eax),%eax
  107c92:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  107c97:	c1 e8 0c             	shr    $0xc,%eax
  107c9a:	c1 e0 03             	shl    $0x3,%eax
  107c9d:	89 c2                	mov    %eax,%edx
  107c9f:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  107ca4:	8d 04 02             	lea    (%edx,%eax,1),%eax
  107ca7:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  107caa:	c7 45 f4 8f 10 10 00 	movl   $0x10108f,0xfffffff4(%ebp)
// freeing the page with the provided function if there are no more refs.
static gcc_inline void
mem_decref(pageinfo* pi, void (*freefun)(pageinfo *pi))
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  107cb1:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  107cb6:	83 c0 08             	add    $0x8,%eax
  107cb9:	3b 45 f8             	cmp    0xfffffff8(%ebp),%eax
  107cbc:	73 17                	jae    107cd5 <pmap_merge+0x307>
  107cbe:	a1 84 ed 17 00       	mov    0x17ed84,%eax
  107cc3:	c1 e0 03             	shl    $0x3,%eax
  107cc6:	89 c2                	mov    %eax,%edx
  107cc8:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  107ccd:	8d 04 02             	lea    (%edx,%eax,1),%eax
  107cd0:	3b 45 f8             	cmp    0xfffffff8(%ebp),%eax
  107cd3:	77 24                	ja     107cf9 <pmap_merge+0x32b>
  107cd5:	c7 44 24 0c c0 ce 10 	movl   $0x10cec0,0xc(%esp)
  107cdc:	00 
  107cdd:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  107ce4:	00 
  107ce5:	c7 44 24 04 9a 00 00 	movl   $0x9a,0x4(%esp)
  107cec:	00 
  107ced:	c7 04 24 f7 ce 10 00 	movl   $0x10cef7,(%esp)
  107cf4:	e8 6f 8c ff ff       	call   100968 <debug_panic>
	assert(pi != mem_ptr2pi(pmap_zero));	// Don't alloc/free zero page!
  107cf9:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  107cff:	b8 00 10 18 00       	mov    $0x181000,%eax
  107d04:	c1 e8 0c             	shr    $0xc,%eax
  107d07:	c1 e0 03             	shl    $0x3,%eax
  107d0a:	8d 04 02             	lea    (%edx,%eax,1),%eax
  107d0d:	3b 45 f8             	cmp    0xfffffff8(%ebp),%eax
  107d10:	75 24                	jne    107d36 <pmap_merge+0x368>
  107d12:	c7 44 24 0c 04 cf 10 	movl   $0x10cf04,0xc(%esp)
  107d19:	00 
  107d1a:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  107d21:	00 
  107d22:	c7 44 24 04 9b 00 00 	movl   $0x9b,0x4(%esp)
  107d29:	00 
  107d2a:	c7 04 24 f7 ce 10 00 	movl   $0x10cef7,(%esp)
  107d31:	e8 32 8c ff ff       	call   100968 <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  107d36:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  107d3c:	b8 0c 00 10 00       	mov    $0x10000c,%eax
  107d41:	c1 e8 0c             	shr    $0xc,%eax
  107d44:	c1 e0 03             	shl    $0x3,%eax
  107d47:	8d 04 02             	lea    (%edx,%eax,1),%eax
  107d4a:	3b 45 f8             	cmp    0xfffffff8(%ebp),%eax
  107d4d:	77 40                	ja     107d8f <pmap_merge+0x3c1>
  107d4f:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  107d55:	b8 08 20 18 00       	mov    $0x182008,%eax
  107d5a:	83 e8 01             	sub    $0x1,%eax
  107d5d:	c1 e8 0c             	shr    $0xc,%eax
  107d60:	c1 e0 03             	shl    $0x3,%eax
  107d63:	8d 04 02             	lea    (%edx,%eax,1),%eax
  107d66:	3b 45 f8             	cmp    0xfffffff8(%ebp),%eax
  107d69:	72 24                	jb     107d8f <pmap_merge+0x3c1>
  107d6b:	c7 44 24 0c 20 cf 10 	movl   $0x10cf20,0xc(%esp)
  107d72:	00 
  107d73:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  107d7a:	00 
  107d7b:	c7 44 24 04 9c 00 00 	movl   $0x9c,0x4(%esp)
  107d82:	00 
  107d83:	c7 04 24 f7 ce 10 00 	movl   $0x10cef7,(%esp)
  107d8a:	e8 d9 8b ff ff       	call   100968 <debug_panic>

	if (lockaddz(&pi->refcount, -1))
  107d8f:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  107d92:	83 c0 04             	add    $0x4,%eax
  107d95:	c7 44 24 04 ff ff ff 	movl   $0xffffffff,0x4(%esp)
  107d9c:	ff 
  107d9d:	89 04 24             	mov    %eax,(%esp)
  107da0:	e8 0e e2 ff ff       	call   105fb3 <lockaddz>
  107da5:	84 c0                	test   %al,%al
  107da7:	74 0b                	je     107db4 <pmap_merge+0x3e6>
			freefun(pi);
  107da9:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  107dac:	89 04 24             	mov    %eax,(%esp)
  107daf:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  107db2:	ff d0                	call   *%eax
	assert(pi->refcount >= 0);
  107db4:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  107db7:	8b 40 04             	mov    0x4(%eax),%eax
  107dba:	85 c0                	test   %eax,%eax
  107dbc:	79 24                	jns    107de2 <pmap_merge+0x414>
  107dbe:	c7 44 24 0c 51 cf 10 	movl   $0x10cf51,0xc(%esp)
  107dc5:	00 
  107dc6:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  107dcd:	00 
  107dce:	c7 44 24 04 a0 00 00 	movl   $0xa0,0x4(%esp)
  107dd5:	00 
  107dd6:	c7 04 24 f7 ce 10 00 	movl   $0x10cef7,(%esp)
  107ddd:	e8 86 8b ff ff       	call   100968 <debug_panic>
          *spte &= ~PTE_W;
  107de2:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  107de5:	8b 00                	mov    (%eax),%eax
  107de7:	89 c2                	mov    %eax,%edx
  107de9:	83 e2 fd             	and    $0xfffffffd,%edx
  107dec:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  107def:	89 10                	mov    %edx,(%eax)
          *dpte = *spte;
  107df1:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  107df4:	8b 10                	mov    (%eax),%edx
  107df6:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  107df9:	89 10                	mov    %edx,(%eax)
          mem_incref(mem_phys2pi(PGADDR(*spte)));
  107dfb:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  107dfe:	8b 00                	mov    (%eax),%eax
  107e00:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  107e05:	c1 e8 0c             	shr    $0xc,%eax
  107e08:	c1 e0 03             	shl    $0x3,%eax
  107e0b:	89 c2                	mov    %eax,%edx
  107e0d:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  107e12:	8d 04 02             	lea    (%edx,%eax,1),%eax
  107e15:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
// Atomically increment the reference count on a page.
static gcc_inline void
mem_incref(pageinfo *pi)
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  107e18:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  107e1d:	83 c0 08             	add    $0x8,%eax
  107e20:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  107e23:	73 17                	jae    107e3c <pmap_merge+0x46e>
  107e25:	a1 84 ed 17 00       	mov    0x17ed84,%eax
  107e2a:	c1 e0 03             	shl    $0x3,%eax
  107e2d:	89 c2                	mov    %eax,%edx
  107e2f:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  107e34:	8d 04 02             	lea    (%edx,%eax,1),%eax
  107e37:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  107e3a:	77 24                	ja     107e60 <pmap_merge+0x492>
  107e3c:	c7 44 24 0c c0 ce 10 	movl   $0x10cec0,0xc(%esp)
  107e43:	00 
  107e44:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  107e4b:	00 
  107e4c:	c7 44 24 04 8e 00 00 	movl   $0x8e,0x4(%esp)
  107e53:	00 
  107e54:	c7 04 24 f7 ce 10 00 	movl   $0x10cef7,(%esp)
  107e5b:	e8 08 8b ff ff       	call   100968 <debug_panic>
	assert(pi != mem_ptr2pi(pmap_zero));	// Don't alloc/free zero page!
  107e60:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  107e66:	b8 00 10 18 00       	mov    $0x181000,%eax
  107e6b:	c1 e8 0c             	shr    $0xc,%eax
  107e6e:	c1 e0 03             	shl    $0x3,%eax
  107e71:	8d 04 02             	lea    (%edx,%eax,1),%eax
  107e74:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  107e77:	75 24                	jne    107e9d <pmap_merge+0x4cf>
  107e79:	c7 44 24 0c 04 cf 10 	movl   $0x10cf04,0xc(%esp)
  107e80:	00 
  107e81:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  107e88:	00 
  107e89:	c7 44 24 04 8f 00 00 	movl   $0x8f,0x4(%esp)
  107e90:	00 
  107e91:	c7 04 24 f7 ce 10 00 	movl   $0x10cef7,(%esp)
  107e98:	e8 cb 8a ff ff       	call   100968 <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  107e9d:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  107ea3:	b8 0c 00 10 00       	mov    $0x10000c,%eax
  107ea8:	c1 e8 0c             	shr    $0xc,%eax
  107eab:	c1 e0 03             	shl    $0x3,%eax
  107eae:	8d 04 02             	lea    (%edx,%eax,1),%eax
  107eb1:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  107eb4:	77 40                	ja     107ef6 <pmap_merge+0x528>
  107eb6:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  107ebc:	b8 08 20 18 00       	mov    $0x182008,%eax
  107ec1:	83 e8 01             	sub    $0x1,%eax
  107ec4:	c1 e8 0c             	shr    $0xc,%eax
  107ec7:	c1 e0 03             	shl    $0x3,%eax
  107eca:	8d 04 02             	lea    (%edx,%eax,1),%eax
  107ecd:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  107ed0:	72 24                	jb     107ef6 <pmap_merge+0x528>
  107ed2:	c7 44 24 0c 20 cf 10 	movl   $0x10cf20,0xc(%esp)
  107ed9:	00 
  107eda:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  107ee1:	00 
  107ee2:	c7 44 24 04 90 00 00 	movl   $0x90,0x4(%esp)
  107ee9:	00 
  107eea:	c7 04 24 f7 ce 10 00 	movl   $0x10cef7,(%esp)
  107ef1:	e8 72 8a ff ff       	call   100968 <debug_panic>

	lockadd(&pi->refcount, 1);
  107ef6:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  107ef9:	83 c0 04             	add    $0x4,%eax
  107efc:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  107f03:	00 
  107f04:	89 04 24             	mov    %eax,(%esp)
  107f07:	e8 aa de ff ff       	call   105db6 <lockadd>
          continue;
  107f0c:	eb 20                	jmp    107f2e <pmap_merge+0x560>
          }
                    

          pmap_mergepage(rpte, spte, dpte, dva);
  107f0e:	8b 45 18             	mov    0x18(%ebp),%eax
  107f11:	89 44 24 0c          	mov    %eax,0xc(%esp)
  107f15:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  107f18:	89 44 24 08          	mov    %eax,0x8(%esp)
  107f1c:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  107f1f:	89 44 24 04          	mov    %eax,0x4(%esp)
  107f23:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  107f26:	89 04 24             	mov    %eax,(%esp)
  107f29:	e8 94 f5 ff ff       	call   1074c2 <pmap_mergepage>
  107f2e:	83 45 e4 04          	addl   $0x4,0xffffffe4(%ebp)
  107f32:	83 45 e8 04          	addl   $0x4,0xffffffe8(%ebp)
  107f36:	83 45 ec 04          	addl   $0x4,0xffffffec(%ebp)
  107f3a:	81 45 10 00 10 00 00 	addl   $0x1000,0x10(%ebp)
  107f41:	81 45 18 00 10 00 00 	addl   $0x1000,0x18(%ebp)
  107f48:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  107f4b:	3b 45 f0             	cmp    0xfffffff0(%ebp),%eax
  107f4e:	0f 82 fb fc ff ff    	jb     107c4f <pmap_merge+0x281>
  107f54:	83 45 d4 04          	addl   $0x4,0xffffffd4(%ebp)
  107f58:	83 45 d8 04          	addl   $0x4,0xffffffd8(%ebp)
  107f5c:	83 45 dc 04          	addl   $0x4,0xffffffdc(%ebp)
  107f60:	8b 45 10             	mov    0x10(%ebp),%eax
  107f63:	3b 45 e0             	cmp    0xffffffe0(%ebp),%eax
  107f66:	0f 82 10 fc ff ff    	jb     107b7c <pmap_merge+0x1ae>
         }
         }
          
return 1;
  107f6c:	c7 45 cc 01 00 00 00 	movl   $0x1,0xffffffcc(%ebp)
  107f73:	8b 45 cc             	mov    0xffffffcc(%ebp),%eax
}
  107f76:	c9                   	leave  
  107f77:	c3                   	ret    

00107f78 <pmap_setperm>:

//
// Set the nominal permission bits on a range of virtual pages to 'perm'.
// Adding permission to a nonexistent page maps zero-filled memory.
// It's OK to add SYS_READ and/or SYS_WRITE permission to a PTE_ZERO mapping;
// this causes the pmap_zero page to be mapped read-only (PTE_P but not PTE_W).
// If the user gives SYS_WRITE permission to a PTE_ZERO mapping,
// the page fault handler copies the zero page when the first write occurs.
//
int
pmap_setperm(pde_t *pdir, uint32_t va, uint32_t size, int perm)
{
  107f78:	55                   	push   %ebp
  107f79:	89 e5                	mov    %esp,%ebp
  107f7b:	83 ec 38             	sub    $0x38,%esp
	assert(PGOFF(va) == 0);
  107f7e:	8b 45 0c             	mov    0xc(%ebp),%eax
  107f81:	25 ff 0f 00 00       	and    $0xfff,%eax
  107f86:	85 c0                	test   %eax,%eax
  107f88:	74 24                	je     107fae <pmap_setperm+0x36>
  107f8a:	c7 44 24 0c 60 d1 10 	movl   $0x10d160,0xc(%esp)
  107f91:	00 
  107f92:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  107f99:	00 
  107f9a:	c7 44 24 04 1c 02 00 	movl   $0x21c,0x4(%esp)
  107fa1:	00 
  107fa2:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  107fa9:	e8 ba 89 ff ff       	call   100968 <debug_panic>
	assert(PGOFF(size) == 0);
  107fae:	8b 45 10             	mov    0x10(%ebp),%eax
  107fb1:	25 ff 0f 00 00       	and    $0xfff,%eax
  107fb6:	85 c0                	test   %eax,%eax
  107fb8:	74 24                	je     107fde <pmap_setperm+0x66>
  107fba:	c7 44 24 0c b4 cf 10 	movl   $0x10cfb4,0xc(%esp)
  107fc1:	00 
  107fc2:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  107fc9:	00 
  107fca:	c7 44 24 04 1d 02 00 	movl   $0x21d,0x4(%esp)
  107fd1:	00 
  107fd2:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  107fd9:	e8 8a 89 ff ff       	call   100968 <debug_panic>
	assert(va >= VM_USERLO && va < VM_USERHI);
  107fde:	81 7d 0c ff ff ff 3f 	cmpl   $0x3fffffff,0xc(%ebp)
  107fe5:	76 09                	jbe    107ff0 <pmap_setperm+0x78>
  107fe7:	81 7d 0c ff ff ff ef 	cmpl   $0xefffffff,0xc(%ebp)
  107fee:	76 24                	jbe    108014 <pmap_setperm+0x9c>
  107ff0:	c7 44 24 0c 64 cf 10 	movl   $0x10cf64,0xc(%esp)
  107ff7:	00 
  107ff8:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  107fff:	00 
  108000:	c7 44 24 04 1e 02 00 	movl   $0x21e,0x4(%esp)
  108007:	00 
  108008:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  10800f:	e8 54 89 ff ff       	call   100968 <debug_panic>
	assert(size <= VM_USERHI - va);
  108014:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
  108019:	2b 45 0c             	sub    0xc(%ebp),%eax
  10801c:	3b 45 10             	cmp    0x10(%ebp),%eax
  10801f:	73 24                	jae    108045 <pmap_setperm+0xcd>
  108021:	c7 44 24 0c c5 cf 10 	movl   $0x10cfc5,0xc(%esp)
  108028:	00 
  108029:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  108030:	00 
  108031:	c7 44 24 04 1f 02 00 	movl   $0x21f,0x4(%esp)
  108038:	00 
  108039:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  108040:	e8 23 89 ff ff       	call   100968 <debug_panic>
	assert((perm & ~(SYS_RW)) == 0);
  108045:	8b 45 14             	mov    0x14(%ebp),%eax
  108048:	80 e4 f9             	and    $0xf9,%ah
  10804b:	85 c0                	test   %eax,%eax
  10804d:	74 24                	je     108073 <pmap_setperm+0xfb>
  10804f:	c7 44 24 0c 6f d1 10 	movl   $0x10d16f,0xc(%esp)
  108056:	00 
  108057:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  10805e:	00 
  10805f:	c7 44 24 04 20 02 00 	movl   $0x220,0x4(%esp)
  108066:	00 
  108067:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  10806e:	e8 f5 88 ff ff       	call   100968 <debug_panic>


  pmap_inval(pdir, va, size);
  108073:	8b 45 10             	mov    0x10(%ebp),%eax
  108076:	89 44 24 08          	mov    %eax,0x8(%esp)
  10807a:	8b 45 0c             	mov    0xc(%ebp),%eax
  10807d:	89 44 24 04          	mov    %eax,0x4(%esp)
  108081:	8b 45 08             	mov    0x8(%ebp),%eax
  108084:	89 04 24             	mov    %eax,(%esp)
  108087:	e8 0f ec ff ff       	call   106c9b <pmap_inval>

  uint32_t pteand, pteor;
  if(!(perm & SYS_READ))
  10808c:	8b 45 14             	mov    0x14(%ebp),%eax
  10808f:	25 00 02 00 00       	and    $0x200,%eax
  108094:	85 c0                	test   %eax,%eax
  108096:	75 10                	jne    1080a8 <pmap_setperm+0x130>
    pteand = ~(SYS_RW | PTE_W | PTE_P), pteor = 0;
  108098:	c7 45 ec fc f9 ff ff 	movl   $0xfffff9fc,0xffffffec(%ebp)
  10809f:	c7 45 f0 00 00 00 00 	movl   $0x0,0xfffffff0(%ebp)
  1080a6:	eb 2a                	jmp    1080d2 <pmap_setperm+0x15a>
    else if (!(perm & SYS_WRITE))
  1080a8:	8b 45 14             	mov    0x14(%ebp),%eax
  1080ab:	25 00 04 00 00       	and    $0x400,%eax
  1080b0:	85 c0                	test   %eax,%eax
  1080b2:	75 10                	jne    1080c4 <pmap_setperm+0x14c>
    pteand = ~(SYS_WRITE | PTE_W),
  1080b4:	c7 45 ec fd fb ff ff 	movl   $0xfffffbfd,0xffffffec(%ebp)
  1080bb:	c7 45 f0 25 02 00 00 	movl   $0x225,0xfffffff0(%ebp)
  1080c2:	eb 0e                	jmp    1080d2 <pmap_setperm+0x15a>
    pteor = (SYS_READ | PTE_U | PTE_P | PTE_A);
    else
    pteand = ~0, pteor = (SYS_RW | PTE_U | PTE_P | PTE_A | PTE_D);
  1080c4:	c7 45 ec ff ff ff ff 	movl   $0xffffffff,0xffffffec(%ebp)
  1080cb:	c7 45 f0 65 06 00 00 	movl   $0x665,0xfffffff0(%ebp)

    uint32_t vahi = va + size;
  1080d2:	8b 45 10             	mov    0x10(%ebp),%eax
  1080d5:	03 45 0c             	add    0xc(%ebp),%eax
  1080d8:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
    while(va < vahi){
  1080db:	e9 9a 00 00 00       	jmp    10817a <pmap_setperm+0x202>
    pde_t *pde = &pdir[PDX(va)];
  1080e0:	8b 45 0c             	mov    0xc(%ebp),%eax
  1080e3:	c1 e8 16             	shr    $0x16,%eax
  1080e6:	25 ff 03 00 00       	and    $0x3ff,%eax
  1080eb:	c1 e0 02             	shl    $0x2,%eax
  1080ee:	03 45 08             	add    0x8(%ebp),%eax
  1080f1:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
    if (*pde == PTE_ZERO && pteor == 0){
  1080f4:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1080f7:	8b 10                	mov    (%eax),%edx
  1080f9:	b8 00 10 18 00       	mov    $0x181000,%eax
  1080fe:	39 c2                	cmp    %eax,%edx
  108100:	75 18                	jne    10811a <pmap_setperm+0x1a2>
  108102:	83 7d f0 00          	cmpl   $0x0,0xfffffff0(%ebp)
  108106:	75 12                	jne    10811a <pmap_setperm+0x1a2>
    va = PTADDR(va + PTSIZE);
  108108:	8b 45 0c             	mov    0xc(%ebp),%eax
  10810b:	05 00 00 40 00       	add    $0x400000,%eax
  108110:	25 00 00 c0 ff       	and    $0xffc00000,%eax
  108115:	89 45 0c             	mov    %eax,0xc(%ebp)
    continue;
  108118:	eb 60                	jmp    10817a <pmap_setperm+0x202>
    }

    pte_t *pte = pmap_walk(pdir, va, 1);
  10811a:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
  108121:	00 
  108122:	8b 45 0c             	mov    0xc(%ebp),%eax
  108125:	89 44 24 04          	mov    %eax,0x4(%esp)
  108129:	8b 45 08             	mov    0x8(%ebp),%eax
  10812c:	89 04 24             	mov    %eax,(%esp)
  10812f:	e8 9b de ff ff       	call   105fcf <pmap_walk>
  108134:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
    if (pte == NULL)
  108137:	83 7d fc 00          	cmpl   $0x0,0xfffffffc(%ebp)
  10813b:	75 09                	jne    108146 <pmap_setperm+0x1ce>
      return 0;
  10813d:	c7 45 dc 00 00 00 00 	movl   $0x0,0xffffffdc(%ebp)
  108144:	eb 47                	jmp    10818d <pmap_setperm+0x215>

    do {
    *pte = (*pte & pteand) | pteor;
  108146:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  108149:	8b 00                	mov    (%eax),%eax
  10814b:	23 45 ec             	and    0xffffffec(%ebp),%eax
  10814e:	89 c2                	mov    %eax,%edx
  108150:	0b 55 f0             	or     0xfffffff0(%ebp),%edx
  108153:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  108156:	89 10                	mov    %edx,(%eax)
    pte++;
  108158:	83 45 fc 04          	addl   $0x4,0xfffffffc(%ebp)
    va += PAGESIZE;
  10815c:	81 45 0c 00 10 00 00 	addl   $0x1000,0xc(%ebp)
    } while(va < vahi && PTX(va) !=0);
  108163:	8b 45 0c             	mov    0xc(%ebp),%eax
  108166:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  108169:	73 0f                	jae    10817a <pmap_setperm+0x202>
  10816b:	8b 45 0c             	mov    0xc(%ebp),%eax
  10816e:	c1 e8 0c             	shr    $0xc,%eax
  108171:	25 ff 03 00 00       	and    $0x3ff,%eax
  108176:	85 c0                	test   %eax,%eax
  108178:	75 cc                	jne    108146 <pmap_setperm+0x1ce>
  10817a:	8b 45 0c             	mov    0xc(%ebp),%eax
  10817d:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  108180:	0f 82 5a ff ff ff    	jb     1080e0 <pmap_setperm+0x168>
    }
    return 1;
  108186:	c7 45 dc 01 00 00 00 	movl   $0x1,0xffffffdc(%ebp)
  10818d:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax




}
  108190:	c9                   	leave  
  108191:	c3                   	ret    

00108192 <va2pa>:

//
// This function returns the physical address of the page containing 'va',
// defined by the page directory 'pdir'.  The hardware normally performs
// this functionality for us!  We define our own version to help check
// the pmap_check() function; it shouldn't be used elsewhere.
//
static uint32_t
va2pa(pde_t *pdir, uintptr_t va)
{
  108192:	55                   	push   %ebp
  108193:	89 e5                	mov    %esp,%ebp
  108195:	83 ec 14             	sub    $0x14,%esp
	pdir = &pdir[PDX(va)];
  108198:	8b 45 0c             	mov    0xc(%ebp),%eax
  10819b:	c1 e8 16             	shr    $0x16,%eax
  10819e:	25 ff 03 00 00       	and    $0x3ff,%eax
  1081a3:	c1 e0 02             	shl    $0x2,%eax
  1081a6:	01 45 08             	add    %eax,0x8(%ebp)
	if (!(*pdir & PTE_P))
  1081a9:	8b 45 08             	mov    0x8(%ebp),%eax
  1081ac:	8b 00                	mov    (%eax),%eax
  1081ae:	83 e0 01             	and    $0x1,%eax
  1081b1:	85 c0                	test   %eax,%eax
  1081b3:	75 09                	jne    1081be <va2pa+0x2c>
		return ~0;
  1081b5:	c7 45 ec ff ff ff ff 	movl   $0xffffffff,0xffffffec(%ebp)
  1081bc:	eb 4e                	jmp    10820c <va2pa+0x7a>
	pte_t *ptab = mem_ptr(PGADDR(*pdir));
  1081be:	8b 45 08             	mov    0x8(%ebp),%eax
  1081c1:	8b 00                	mov    (%eax),%eax
  1081c3:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1081c8:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	if (!(ptab[PTX(va)] & PTE_P))
  1081cb:	8b 45 0c             	mov    0xc(%ebp),%eax
  1081ce:	c1 e8 0c             	shr    $0xc,%eax
  1081d1:	25 ff 03 00 00       	and    $0x3ff,%eax
  1081d6:	c1 e0 02             	shl    $0x2,%eax
  1081d9:	03 45 fc             	add    0xfffffffc(%ebp),%eax
  1081dc:	8b 00                	mov    (%eax),%eax
  1081de:	83 e0 01             	and    $0x1,%eax
  1081e1:	85 c0                	test   %eax,%eax
  1081e3:	75 09                	jne    1081ee <va2pa+0x5c>
		return ~0;
  1081e5:	c7 45 ec ff ff ff ff 	movl   $0xffffffff,0xffffffec(%ebp)
  1081ec:	eb 1e                	jmp    10820c <va2pa+0x7a>
	return PGADDR(ptab[PTX(va)]);
  1081ee:	8b 45 0c             	mov    0xc(%ebp),%eax
  1081f1:	c1 e8 0c             	shr    $0xc,%eax
  1081f4:	25 ff 03 00 00       	and    $0x3ff,%eax
  1081f9:	c1 e0 02             	shl    $0x2,%eax
  1081fc:	03 45 fc             	add    0xfffffffc(%ebp),%eax
  1081ff:	8b 00                	mov    (%eax),%eax
  108201:	89 c2                	mov    %eax,%edx
  108203:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
  108209:	89 55 ec             	mov    %edx,0xffffffec(%ebp)
  10820c:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
}
  10820f:	c9                   	leave  
  108210:	c3                   	ret    

00108211 <pmap_check>:

// check pmap_insert, pmap_remove, &c
void
pmap_check(void)
{
  108211:	55                   	push   %ebp
  108212:	89 e5                	mov    %esp,%ebp
  108214:	53                   	push   %ebx
  108215:	83 ec 44             	sub    $0x44,%esp
	extern pageinfo *mem_freelist;

	pageinfo *pi, *pi0, *pi1, *pi2, *pi3;
	pageinfo *fl;
	pte_t *ptep, *ptep1;
	int i;

	// should be able to allocate three pages
	pi0 = pi1 = pi2 = 0;
  108218:	c7 45 e0 00 00 00 00 	movl   $0x0,0xffffffe0(%ebp)
  10821f:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  108222:	89 45 dc             	mov    %eax,0xffffffdc(%ebp)
  108225:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  108228:	89 45 d8             	mov    %eax,0xffffffd8(%ebp)
	pi0 = mem_alloc();
  10822b:	e8 1b 8e ff ff       	call   10104b <mem_alloc>
  108230:	89 45 d8             	mov    %eax,0xffffffd8(%ebp)
	pi1 = mem_alloc();
  108233:	e8 13 8e ff ff       	call   10104b <mem_alloc>
  108238:	89 45 dc             	mov    %eax,0xffffffdc(%ebp)
	pi2 = mem_alloc();
  10823b:	e8 0b 8e ff ff       	call   10104b <mem_alloc>
  108240:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)
	pi3 = mem_alloc();
  108243:	e8 03 8e ff ff       	call   10104b <mem_alloc>
  108248:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)

	assert(pi0);
  10824b:	83 7d d8 00          	cmpl   $0x0,0xffffffd8(%ebp)
  10824f:	75 24                	jne    108275 <pmap_check+0x64>
  108251:	c7 44 24 0c 87 d1 10 	movl   $0x10d187,0xc(%esp)
  108258:	00 
  108259:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  108260:	00 
  108261:	c7 44 24 04 6b 02 00 	movl   $0x26b,0x4(%esp)
  108268:	00 
  108269:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  108270:	e8 f3 86 ff ff       	call   100968 <debug_panic>
	assert(pi1 && pi1 != pi0);
  108275:	83 7d dc 00          	cmpl   $0x0,0xffffffdc(%ebp)
  108279:	74 08                	je     108283 <pmap_check+0x72>
  10827b:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  10827e:	3b 45 d8             	cmp    0xffffffd8(%ebp),%eax
  108281:	75 24                	jne    1082a7 <pmap_check+0x96>
  108283:	c7 44 24 0c 8b d1 10 	movl   $0x10d18b,0xc(%esp)
  10828a:	00 
  10828b:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  108292:	00 
  108293:	c7 44 24 04 6c 02 00 	movl   $0x26c,0x4(%esp)
  10829a:	00 
  10829b:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  1082a2:	e8 c1 86 ff ff       	call   100968 <debug_panic>
	assert(pi2 && pi2 != pi1 && pi2 != pi0);
  1082a7:	83 7d e0 00          	cmpl   $0x0,0xffffffe0(%ebp)
  1082ab:	74 10                	je     1082bd <pmap_check+0xac>
  1082ad:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  1082b0:	3b 45 dc             	cmp    0xffffffdc(%ebp),%eax
  1082b3:	74 08                	je     1082bd <pmap_check+0xac>
  1082b5:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  1082b8:	3b 45 d8             	cmp    0xffffffd8(%ebp),%eax
  1082bb:	75 24                	jne    1082e1 <pmap_check+0xd0>
  1082bd:	c7 44 24 0c a0 d1 10 	movl   $0x10d1a0,0xc(%esp)
  1082c4:	00 
  1082c5:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  1082cc:	00 
  1082cd:	c7 44 24 04 6d 02 00 	movl   $0x26d,0x4(%esp)
  1082d4:	00 
  1082d5:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  1082dc:	e8 87 86 ff ff       	call   100968 <debug_panic>

	// temporarily steal the rest of the free pages
	fl = mem_freelist;
  1082e1:	a1 80 ed 17 00       	mov    0x17ed80,%eax
  1082e6:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
	mem_freelist = NULL;
  1082e9:	c7 05 80 ed 17 00 00 	movl   $0x0,0x17ed80
  1082f0:	00 00 00 

	// should be no free memory
	assert(mem_alloc() == NULL);
  1082f3:	e8 53 8d ff ff       	call   10104b <mem_alloc>
  1082f8:	85 c0                	test   %eax,%eax
  1082fa:	74 24                	je     108320 <pmap_check+0x10f>
  1082fc:	c7 44 24 0c c0 d1 10 	movl   $0x10d1c0,0xc(%esp)
  108303:	00 
  108304:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  10830b:	00 
  10830c:	c7 44 24 04 74 02 00 	movl   $0x274,0x4(%esp)
  108313:	00 
  108314:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  10831b:	e8 48 86 ff ff       	call   100968 <debug_panic>

	// there is no free memory, so we can't allocate a page table 
	assert(pmap_insert(pmap_bootpdir, pi1, VM_USERLO, 0) == NULL);
  108320:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  108327:	00 
  108328:	c7 44 24 08 00 00 00 	movl   $0x40000000,0x8(%esp)
  10832f:	40 
  108330:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  108333:	89 44 24 04          	mov    %eax,0x4(%esp)
  108337:	c7 04 24 00 00 18 00 	movl   $0x180000,(%esp)
  10833e:	e8 44 e3 ff ff       	call   106687 <pmap_insert>
  108343:	85 c0                	test   %eax,%eax
  108345:	74 24                	je     10836b <pmap_check+0x15a>
  108347:	c7 44 24 0c d4 d1 10 	movl   $0x10d1d4,0xc(%esp)
  10834e:	00 
  10834f:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  108356:	00 
  108357:	c7 44 24 04 77 02 00 	movl   $0x277,0x4(%esp)
  10835e:	00 
  10835f:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  108366:	e8 fd 85 ff ff       	call   100968 <debug_panic>

	// free pi0 and try again: pi0 should be used for page table
	mem_free(pi0);
  10836b:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  10836e:	89 04 24             	mov    %eax,(%esp)
  108371:	e8 19 8d ff ff       	call   10108f <mem_free>
	assert(pmap_insert(pmap_bootpdir, pi1, VM_USERLO, 0) != NULL);
  108376:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  10837d:	00 
  10837e:	c7 44 24 08 00 00 00 	movl   $0x40000000,0x8(%esp)
  108385:	40 
  108386:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  108389:	89 44 24 04          	mov    %eax,0x4(%esp)
  10838d:	c7 04 24 00 00 18 00 	movl   $0x180000,(%esp)
  108394:	e8 ee e2 ff ff       	call   106687 <pmap_insert>
  108399:	85 c0                	test   %eax,%eax
  10839b:	75 24                	jne    1083c1 <pmap_check+0x1b0>
  10839d:	c7 44 24 0c 0c d2 10 	movl   $0x10d20c,0xc(%esp)
  1083a4:	00 
  1083a5:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  1083ac:	00 
  1083ad:	c7 44 24 04 7b 02 00 	movl   $0x27b,0x4(%esp)
  1083b4:	00 
  1083b5:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  1083bc:	e8 a7 85 ff ff       	call   100968 <debug_panic>
	assert(PGADDR(pmap_bootpdir[PDX(VM_USERLO)]) == mem_pi2phys(pi0));
  1083c1:	a1 00 04 18 00       	mov    0x180400,%eax
  1083c6:	89 c1                	mov    %eax,%ecx
  1083c8:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
  1083ce:	8b 55 d8             	mov    0xffffffd8(%ebp),%edx
  1083d1:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  1083d6:	89 d3                	mov    %edx,%ebx
  1083d8:	29 c3                	sub    %eax,%ebx
  1083da:	89 d8                	mov    %ebx,%eax
  1083dc:	c1 e0 09             	shl    $0x9,%eax
  1083df:	39 c1                	cmp    %eax,%ecx
  1083e1:	74 24                	je     108407 <pmap_check+0x1f6>
  1083e3:	c7 44 24 0c 44 d2 10 	movl   $0x10d244,0xc(%esp)
  1083ea:	00 
  1083eb:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  1083f2:	00 
  1083f3:	c7 44 24 04 7c 02 00 	movl   $0x27c,0x4(%esp)
  1083fa:	00 
  1083fb:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  108402:	e8 61 85 ff ff       	call   100968 <debug_panic>
	assert(va2pa(pmap_bootpdir, VM_USERLO) == mem_pi2phys(pi1));
  108407:	c7 44 24 04 00 00 00 	movl   $0x40000000,0x4(%esp)
  10840e:	40 
  10840f:	c7 04 24 00 00 18 00 	movl   $0x180000,(%esp)
  108416:	e8 77 fd ff ff       	call   108192 <va2pa>
  10841b:	89 c1                	mov    %eax,%ecx
  10841d:	8b 55 dc             	mov    0xffffffdc(%ebp),%edx
  108420:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  108425:	89 d3                	mov    %edx,%ebx
  108427:	29 c3                	sub    %eax,%ebx
  108429:	89 d8                	mov    %ebx,%eax
  10842b:	c1 e0 09             	shl    $0x9,%eax
  10842e:	39 c1                	cmp    %eax,%ecx
  108430:	74 24                	je     108456 <pmap_check+0x245>
  108432:	c7 44 24 0c 80 d2 10 	movl   $0x10d280,0xc(%esp)
  108439:	00 
  10843a:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  108441:	00 
  108442:	c7 44 24 04 7d 02 00 	movl   $0x27d,0x4(%esp)
  108449:	00 
  10844a:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  108451:	e8 12 85 ff ff       	call   100968 <debug_panic>
	assert(pi1->refcount == 1);
  108456:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  108459:	8b 40 04             	mov    0x4(%eax),%eax
  10845c:	83 f8 01             	cmp    $0x1,%eax
  10845f:	74 24                	je     108485 <pmap_check+0x274>
  108461:	c7 44 24 0c b4 d2 10 	movl   $0x10d2b4,0xc(%esp)
  108468:	00 
  108469:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  108470:	00 
  108471:	c7 44 24 04 7e 02 00 	movl   $0x27e,0x4(%esp)
  108478:	00 
  108479:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  108480:	e8 e3 84 ff ff       	call   100968 <debug_panic>
	assert(pi0->refcount == 1);
  108485:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  108488:	8b 40 04             	mov    0x4(%eax),%eax
  10848b:	83 f8 01             	cmp    $0x1,%eax
  10848e:	74 24                	je     1084b4 <pmap_check+0x2a3>
  108490:	c7 44 24 0c c7 d2 10 	movl   $0x10d2c7,0xc(%esp)
  108497:	00 
  108498:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  10849f:	00 
  1084a0:	c7 44 24 04 7f 02 00 	movl   $0x27f,0x4(%esp)
  1084a7:	00 
  1084a8:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  1084af:	e8 b4 84 ff ff       	call   100968 <debug_panic>

	// should be able to map pi2 at VM_USERLO+PAGESIZE
	// because pi0 is already allocated for page table
	assert(pmap_insert(pmap_bootpdir, pi2, VM_USERLO+PAGESIZE, 0));
  1084b4:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  1084bb:	00 
  1084bc:	c7 44 24 08 00 10 00 	movl   $0x40001000,0x8(%esp)
  1084c3:	40 
  1084c4:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  1084c7:	89 44 24 04          	mov    %eax,0x4(%esp)
  1084cb:	c7 04 24 00 00 18 00 	movl   $0x180000,(%esp)
  1084d2:	e8 b0 e1 ff ff       	call   106687 <pmap_insert>
  1084d7:	85 c0                	test   %eax,%eax
  1084d9:	75 24                	jne    1084ff <pmap_check+0x2ee>
  1084db:	c7 44 24 0c dc d2 10 	movl   $0x10d2dc,0xc(%esp)
  1084e2:	00 
  1084e3:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  1084ea:	00 
  1084eb:	c7 44 24 04 83 02 00 	movl   $0x283,0x4(%esp)
  1084f2:	00 
  1084f3:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  1084fa:	e8 69 84 ff ff       	call   100968 <debug_panic>
	assert(va2pa(pmap_bootpdir, VM_USERLO+PAGESIZE) == mem_pi2phys(pi2));
  1084ff:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  108506:	40 
  108507:	c7 04 24 00 00 18 00 	movl   $0x180000,(%esp)
  10850e:	e8 7f fc ff ff       	call   108192 <va2pa>
  108513:	89 c1                	mov    %eax,%ecx
  108515:	8b 55 e0             	mov    0xffffffe0(%ebp),%edx
  108518:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  10851d:	89 d3                	mov    %edx,%ebx
  10851f:	29 c3                	sub    %eax,%ebx
  108521:	89 d8                	mov    %ebx,%eax
  108523:	c1 e0 09             	shl    $0x9,%eax
  108526:	39 c1                	cmp    %eax,%ecx
  108528:	74 24                	je     10854e <pmap_check+0x33d>
  10852a:	c7 44 24 0c 14 d3 10 	movl   $0x10d314,0xc(%esp)
  108531:	00 
  108532:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  108539:	00 
  10853a:	c7 44 24 04 84 02 00 	movl   $0x284,0x4(%esp)
  108541:	00 
  108542:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  108549:	e8 1a 84 ff ff       	call   100968 <debug_panic>
	assert(pi2->refcount == 1);
  10854e:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  108551:	8b 40 04             	mov    0x4(%eax),%eax
  108554:	83 f8 01             	cmp    $0x1,%eax
  108557:	74 24                	je     10857d <pmap_check+0x36c>
  108559:	c7 44 24 0c 51 d3 10 	movl   $0x10d351,0xc(%esp)
  108560:	00 
  108561:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  108568:	00 
  108569:	c7 44 24 04 85 02 00 	movl   $0x285,0x4(%esp)
  108570:	00 
  108571:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  108578:	e8 eb 83 ff ff       	call   100968 <debug_panic>

	// should be no free memory
	assert(mem_alloc() == NULL);
  10857d:	e8 c9 8a ff ff       	call   10104b <mem_alloc>
  108582:	85 c0                	test   %eax,%eax
  108584:	74 24                	je     1085aa <pmap_check+0x399>
  108586:	c7 44 24 0c c0 d1 10 	movl   $0x10d1c0,0xc(%esp)
  10858d:	00 
  10858e:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  108595:	00 
  108596:	c7 44 24 04 88 02 00 	movl   $0x288,0x4(%esp)
  10859d:	00 
  10859e:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  1085a5:	e8 be 83 ff ff       	call   100968 <debug_panic>

	// should be able to map pi2 at VM_USERLO+PAGESIZE
	// because it's already there
	assert(pmap_insert(pmap_bootpdir, pi2, VM_USERLO+PAGESIZE, 0));
  1085aa:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  1085b1:	00 
  1085b2:	c7 44 24 08 00 10 00 	movl   $0x40001000,0x8(%esp)
  1085b9:	40 
  1085ba:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  1085bd:	89 44 24 04          	mov    %eax,0x4(%esp)
  1085c1:	c7 04 24 00 00 18 00 	movl   $0x180000,(%esp)
  1085c8:	e8 ba e0 ff ff       	call   106687 <pmap_insert>
  1085cd:	85 c0                	test   %eax,%eax
  1085cf:	75 24                	jne    1085f5 <pmap_check+0x3e4>
  1085d1:	c7 44 24 0c dc d2 10 	movl   $0x10d2dc,0xc(%esp)
  1085d8:	00 
  1085d9:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  1085e0:	00 
  1085e1:	c7 44 24 04 8c 02 00 	movl   $0x28c,0x4(%esp)
  1085e8:	00 
  1085e9:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  1085f0:	e8 73 83 ff ff       	call   100968 <debug_panic>
	assert(va2pa(pmap_bootpdir, VM_USERLO+PAGESIZE) == mem_pi2phys(pi2));
  1085f5:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  1085fc:	40 
  1085fd:	c7 04 24 00 00 18 00 	movl   $0x180000,(%esp)
  108604:	e8 89 fb ff ff       	call   108192 <va2pa>
  108609:	89 c1                	mov    %eax,%ecx
  10860b:	8b 55 e0             	mov    0xffffffe0(%ebp),%edx
  10860e:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  108613:	89 d3                	mov    %edx,%ebx
  108615:	29 c3                	sub    %eax,%ebx
  108617:	89 d8                	mov    %ebx,%eax
  108619:	c1 e0 09             	shl    $0x9,%eax
  10861c:	39 c1                	cmp    %eax,%ecx
  10861e:	74 24                	je     108644 <pmap_check+0x433>
  108620:	c7 44 24 0c 14 d3 10 	movl   $0x10d314,0xc(%esp)
  108627:	00 
  108628:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  10862f:	00 
  108630:	c7 44 24 04 8d 02 00 	movl   $0x28d,0x4(%esp)
  108637:	00 
  108638:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  10863f:	e8 24 83 ff ff       	call   100968 <debug_panic>
	assert(pi2->refcount == 1);
  108644:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  108647:	8b 40 04             	mov    0x4(%eax),%eax
  10864a:	83 f8 01             	cmp    $0x1,%eax
  10864d:	74 24                	je     108673 <pmap_check+0x462>
  10864f:	c7 44 24 0c 51 d3 10 	movl   $0x10d351,0xc(%esp)
  108656:	00 
  108657:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  10865e:	00 
  10865f:	c7 44 24 04 8e 02 00 	movl   $0x28e,0x4(%esp)
  108666:	00 
  108667:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  10866e:	e8 f5 82 ff ff       	call   100968 <debug_panic>

	// pi2 should NOT be on the free list
	// could hapien in ref counts are handled slopiily in pmap_insert
	assert(mem_alloc() == NULL);
  108673:	e8 d3 89 ff ff       	call   10104b <mem_alloc>
  108678:	85 c0                	test   %eax,%eax
  10867a:	74 24                	je     1086a0 <pmap_check+0x48f>
  10867c:	c7 44 24 0c c0 d1 10 	movl   $0x10d1c0,0xc(%esp)
  108683:	00 
  108684:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  10868b:	00 
  10868c:	c7 44 24 04 92 02 00 	movl   $0x292,0x4(%esp)
  108693:	00 
  108694:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  10869b:	e8 c8 82 ff ff       	call   100968 <debug_panic>

	// check that pmap_walk returns a pointer to the pte
	ptep = mem_ptr(PGADDR(pmap_bootpdir[PDX(VM_USERLO+PAGESIZE)]));
  1086a0:	a1 00 04 18 00       	mov    0x180400,%eax
  1086a5:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1086aa:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
	assert(pmap_walk(pmap_bootpdir, VM_USERLO+PAGESIZE, 0)
  1086ad:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  1086b4:	00 
  1086b5:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  1086bc:	40 
  1086bd:	c7 04 24 00 00 18 00 	movl   $0x180000,(%esp)
  1086c4:	e8 06 d9 ff ff       	call   105fcf <pmap_walk>
  1086c9:	89 c2                	mov    %eax,%edx
  1086cb:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  1086ce:	83 c0 04             	add    $0x4,%eax
  1086d1:	39 c2                	cmp    %eax,%edx
  1086d3:	74 24                	je     1086f9 <pmap_check+0x4e8>
  1086d5:	c7 44 24 0c 64 d3 10 	movl   $0x10d364,0xc(%esp)
  1086dc:	00 
  1086dd:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  1086e4:	00 
  1086e5:	c7 44 24 04 97 02 00 	movl   $0x297,0x4(%esp)
  1086ec:	00 
  1086ed:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  1086f4:	e8 6f 82 ff ff       	call   100968 <debug_panic>
		== ptep+PTX(VM_USERLO+PAGESIZE));

	// should be able to change permissions too.
	assert(pmap_insert(pmap_bootpdir, pi2, VM_USERLO+PAGESIZE, PTE_U));
  1086f9:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
  108700:	00 
  108701:	c7 44 24 08 00 10 00 	movl   $0x40001000,0x8(%esp)
  108708:	40 
  108709:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  10870c:	89 44 24 04          	mov    %eax,0x4(%esp)
  108710:	c7 04 24 00 00 18 00 	movl   $0x180000,(%esp)
  108717:	e8 6b df ff ff       	call   106687 <pmap_insert>
  10871c:	85 c0                	test   %eax,%eax
  10871e:	75 24                	jne    108744 <pmap_check+0x533>
  108720:	c7 44 24 0c b4 d3 10 	movl   $0x10d3b4,0xc(%esp)
  108727:	00 
  108728:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  10872f:	00 
  108730:	c7 44 24 04 9a 02 00 	movl   $0x29a,0x4(%esp)
  108737:	00 
  108738:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  10873f:	e8 24 82 ff ff       	call   100968 <debug_panic>
	assert(va2pa(pmap_bootpdir, VM_USERLO+PAGESIZE) == mem_pi2phys(pi2));
  108744:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  10874b:	40 
  10874c:	c7 04 24 00 00 18 00 	movl   $0x180000,(%esp)
  108753:	e8 3a fa ff ff       	call   108192 <va2pa>
  108758:	89 c1                	mov    %eax,%ecx
  10875a:	8b 55 e0             	mov    0xffffffe0(%ebp),%edx
  10875d:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  108762:	89 d3                	mov    %edx,%ebx
  108764:	29 c3                	sub    %eax,%ebx
  108766:	89 d8                	mov    %ebx,%eax
  108768:	c1 e0 09             	shl    $0x9,%eax
  10876b:	39 c1                	cmp    %eax,%ecx
  10876d:	74 24                	je     108793 <pmap_check+0x582>
  10876f:	c7 44 24 0c 14 d3 10 	movl   $0x10d314,0xc(%esp)
  108776:	00 
  108777:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  10877e:	00 
  10877f:	c7 44 24 04 9b 02 00 	movl   $0x29b,0x4(%esp)
  108786:	00 
  108787:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  10878e:	e8 d5 81 ff ff       	call   100968 <debug_panic>
	assert(pi2->refcount == 1);
  108793:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  108796:	8b 40 04             	mov    0x4(%eax),%eax
  108799:	83 f8 01             	cmp    $0x1,%eax
  10879c:	74 24                	je     1087c2 <pmap_check+0x5b1>
  10879e:	c7 44 24 0c 51 d3 10 	movl   $0x10d351,0xc(%esp)
  1087a5:	00 
  1087a6:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  1087ad:	00 
  1087ae:	c7 44 24 04 9c 02 00 	movl   $0x29c,0x4(%esp)
  1087b5:	00 
  1087b6:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  1087bd:	e8 a6 81 ff ff       	call   100968 <debug_panic>
	assert(*pmap_walk(pmap_bootpdir, VM_USERLO+PAGESIZE, 0) & PTE_U);
  1087c2:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  1087c9:	00 
  1087ca:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  1087d1:	40 
  1087d2:	c7 04 24 00 00 18 00 	movl   $0x180000,(%esp)
  1087d9:	e8 f1 d7 ff ff       	call   105fcf <pmap_walk>
  1087de:	8b 00                	mov    (%eax),%eax
  1087e0:	83 e0 04             	and    $0x4,%eax
  1087e3:	85 c0                	test   %eax,%eax
  1087e5:	75 24                	jne    10880b <pmap_check+0x5fa>
  1087e7:	c7 44 24 0c f0 d3 10 	movl   $0x10d3f0,0xc(%esp)
  1087ee:	00 
  1087ef:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  1087f6:	00 
  1087f7:	c7 44 24 04 9d 02 00 	movl   $0x29d,0x4(%esp)
  1087fe:	00 
  1087ff:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  108806:	e8 5d 81 ff ff       	call   100968 <debug_panic>
	assert(pmap_bootpdir[PDX(VM_USERLO)] & PTE_U);
  10880b:	a1 00 04 18 00       	mov    0x180400,%eax
  108810:	83 e0 04             	and    $0x4,%eax
  108813:	85 c0                	test   %eax,%eax
  108815:	75 24                	jne    10883b <pmap_check+0x62a>
  108817:	c7 44 24 0c 2c d4 10 	movl   $0x10d42c,0xc(%esp)
  10881e:	00 
  10881f:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  108826:	00 
  108827:	c7 44 24 04 9e 02 00 	movl   $0x29e,0x4(%esp)
  10882e:	00 
  10882f:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  108836:	e8 2d 81 ff ff       	call   100968 <debug_panic>
	
	// should not be able to map at VM_USERLO+PTSIZE
	// because we need a free page for a page table
	assert(pmap_insert(pmap_bootpdir, pi0, VM_USERLO+PTSIZE, 0) == NULL);
  10883b:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  108842:	00 
  108843:	c7 44 24 08 00 00 40 	movl   $0x40400000,0x8(%esp)
  10884a:	40 
  10884b:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  10884e:	89 44 24 04          	mov    %eax,0x4(%esp)
  108852:	c7 04 24 00 00 18 00 	movl   $0x180000,(%esp)
  108859:	e8 29 de ff ff       	call   106687 <pmap_insert>
  10885e:	85 c0                	test   %eax,%eax
  108860:	74 24                	je     108886 <pmap_check+0x675>
  108862:	c7 44 24 0c 54 d4 10 	movl   $0x10d454,0xc(%esp)
  108869:	00 
  10886a:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  108871:	00 
  108872:	c7 44 24 04 a2 02 00 	movl   $0x2a2,0x4(%esp)
  108879:	00 
  10887a:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  108881:	e8 e2 80 ff ff       	call   100968 <debug_panic>

	// insert pi1 at VM_USERLO+PAGESIZE (replacing pi2)
	assert(pmap_insert(pmap_bootpdir, pi1, VM_USERLO+PAGESIZE, 0));
  108886:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  10888d:	00 
  10888e:	c7 44 24 08 00 10 00 	movl   $0x40001000,0x8(%esp)
  108895:	40 
  108896:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  108899:	89 44 24 04          	mov    %eax,0x4(%esp)
  10889d:	c7 04 24 00 00 18 00 	movl   $0x180000,(%esp)
  1088a4:	e8 de dd ff ff       	call   106687 <pmap_insert>
  1088a9:	85 c0                	test   %eax,%eax
  1088ab:	75 24                	jne    1088d1 <pmap_check+0x6c0>
  1088ad:	c7 44 24 0c 94 d4 10 	movl   $0x10d494,0xc(%esp)
  1088b4:	00 
  1088b5:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  1088bc:	00 
  1088bd:	c7 44 24 04 a5 02 00 	movl   $0x2a5,0x4(%esp)
  1088c4:	00 
  1088c5:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  1088cc:	e8 97 80 ff ff       	call   100968 <debug_panic>
	assert(!(*pmap_walk(pmap_bootpdir, VM_USERLO+PAGESIZE, 0) & PTE_U));
  1088d1:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  1088d8:	00 
  1088d9:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  1088e0:	40 
  1088e1:	c7 04 24 00 00 18 00 	movl   $0x180000,(%esp)
  1088e8:	e8 e2 d6 ff ff       	call   105fcf <pmap_walk>
  1088ed:	8b 00                	mov    (%eax),%eax
  1088ef:	83 e0 04             	and    $0x4,%eax
  1088f2:	85 c0                	test   %eax,%eax
  1088f4:	74 24                	je     10891a <pmap_check+0x709>
  1088f6:	c7 44 24 0c cc d4 10 	movl   $0x10d4cc,0xc(%esp)
  1088fd:	00 
  1088fe:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  108905:	00 
  108906:	c7 44 24 04 a6 02 00 	movl   $0x2a6,0x4(%esp)
  10890d:	00 
  10890e:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  108915:	e8 4e 80 ff ff       	call   100968 <debug_panic>

	// should have pi1 at both +0 and +PAGESIZE, pi2 nowhere, ...
	assert(va2pa(pmap_bootpdir, VM_USERLO+0) == mem_pi2phys(pi1));
  10891a:	c7 44 24 04 00 00 00 	movl   $0x40000000,0x4(%esp)
  108921:	40 
  108922:	c7 04 24 00 00 18 00 	movl   $0x180000,(%esp)
  108929:	e8 64 f8 ff ff       	call   108192 <va2pa>
  10892e:	89 c1                	mov    %eax,%ecx
  108930:	8b 55 dc             	mov    0xffffffdc(%ebp),%edx
  108933:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  108938:	89 d3                	mov    %edx,%ebx
  10893a:	29 c3                	sub    %eax,%ebx
  10893c:	89 d8                	mov    %ebx,%eax
  10893e:	c1 e0 09             	shl    $0x9,%eax
  108941:	39 c1                	cmp    %eax,%ecx
  108943:	74 24                	je     108969 <pmap_check+0x758>
  108945:	c7 44 24 0c 08 d5 10 	movl   $0x10d508,0xc(%esp)
  10894c:	00 
  10894d:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  108954:	00 
  108955:	c7 44 24 04 a9 02 00 	movl   $0x2a9,0x4(%esp)
  10895c:	00 
  10895d:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  108964:	e8 ff 7f ff ff       	call   100968 <debug_panic>
	assert(va2pa(pmap_bootpdir, VM_USERLO+PAGESIZE) == mem_pi2phys(pi1));
  108969:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  108970:	40 
  108971:	c7 04 24 00 00 18 00 	movl   $0x180000,(%esp)
  108978:	e8 15 f8 ff ff       	call   108192 <va2pa>
  10897d:	89 c1                	mov    %eax,%ecx
  10897f:	8b 55 dc             	mov    0xffffffdc(%ebp),%edx
  108982:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  108987:	89 d3                	mov    %edx,%ebx
  108989:	29 c3                	sub    %eax,%ebx
  10898b:	89 d8                	mov    %ebx,%eax
  10898d:	c1 e0 09             	shl    $0x9,%eax
  108990:	39 c1                	cmp    %eax,%ecx
  108992:	74 24                	je     1089b8 <pmap_check+0x7a7>
  108994:	c7 44 24 0c 40 d5 10 	movl   $0x10d540,0xc(%esp)
  10899b:	00 
  10899c:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  1089a3:	00 
  1089a4:	c7 44 24 04 aa 02 00 	movl   $0x2aa,0x4(%esp)
  1089ab:	00 
  1089ac:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  1089b3:	e8 b0 7f ff ff       	call   100968 <debug_panic>
	// ... and ref counts should reflect this
	assert(pi1->refcount == 2);
  1089b8:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  1089bb:	8b 40 04             	mov    0x4(%eax),%eax
  1089be:	83 f8 02             	cmp    $0x2,%eax
  1089c1:	74 24                	je     1089e7 <pmap_check+0x7d6>
  1089c3:	c7 44 24 0c 7d d5 10 	movl   $0x10d57d,0xc(%esp)
  1089ca:	00 
  1089cb:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  1089d2:	00 
  1089d3:	c7 44 24 04 ac 02 00 	movl   $0x2ac,0x4(%esp)
  1089da:	00 
  1089db:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  1089e2:	e8 81 7f ff ff       	call   100968 <debug_panic>
	assert(pi2->refcount == 0);
  1089e7:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  1089ea:	8b 40 04             	mov    0x4(%eax),%eax
  1089ed:	85 c0                	test   %eax,%eax
  1089ef:	74 24                	je     108a15 <pmap_check+0x804>
  1089f1:	c7 44 24 0c 90 d5 10 	movl   $0x10d590,0xc(%esp)
  1089f8:	00 
  1089f9:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  108a00:	00 
  108a01:	c7 44 24 04 ad 02 00 	movl   $0x2ad,0x4(%esp)
  108a08:	00 
  108a09:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  108a10:	e8 53 7f ff ff       	call   100968 <debug_panic>

	// pi2 should be returned by mem_alloc
	assert(mem_alloc() == pi2);
  108a15:	e8 31 86 ff ff       	call   10104b <mem_alloc>
  108a1a:	3b 45 e0             	cmp    0xffffffe0(%ebp),%eax
  108a1d:	74 24                	je     108a43 <pmap_check+0x832>
  108a1f:	c7 44 24 0c a3 d5 10 	movl   $0x10d5a3,0xc(%esp)
  108a26:	00 
  108a27:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  108a2e:	00 
  108a2f:	c7 44 24 04 b0 02 00 	movl   $0x2b0,0x4(%esp)
  108a36:	00 
  108a37:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  108a3e:	e8 25 7f ff ff       	call   100968 <debug_panic>

	// unmapping pi1 at VM_USERLO+0 should keep pi1 at +PAGESIZE
	pmap_remove(pmap_bootpdir, VM_USERLO+0, PAGESIZE);
  108a43:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  108a4a:	00 
  108a4b:	c7 44 24 04 00 00 00 	movl   $0x40000000,0x4(%esp)
  108a52:	40 
  108a53:	c7 04 24 00 00 18 00 	movl   $0x180000,(%esp)
  108a5a:	e8 a6 dd ff ff       	call   106805 <pmap_remove>
	assert(va2pa(pmap_bootpdir, VM_USERLO+0) == ~0);
  108a5f:	c7 44 24 04 00 00 00 	movl   $0x40000000,0x4(%esp)
  108a66:	40 
  108a67:	c7 04 24 00 00 18 00 	movl   $0x180000,(%esp)
  108a6e:	e8 1f f7 ff ff       	call   108192 <va2pa>
  108a73:	83 f8 ff             	cmp    $0xffffffff,%eax
  108a76:	74 24                	je     108a9c <pmap_check+0x88b>
  108a78:	c7 44 24 0c b8 d5 10 	movl   $0x10d5b8,0xc(%esp)
  108a7f:	00 
  108a80:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  108a87:	00 
  108a88:	c7 44 24 04 b4 02 00 	movl   $0x2b4,0x4(%esp)
  108a8f:	00 
  108a90:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  108a97:	e8 cc 7e ff ff       	call   100968 <debug_panic>
	assert(va2pa(pmap_bootpdir, VM_USERLO+PAGESIZE) == mem_pi2phys(pi1));
  108a9c:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  108aa3:	40 
  108aa4:	c7 04 24 00 00 18 00 	movl   $0x180000,(%esp)
  108aab:	e8 e2 f6 ff ff       	call   108192 <va2pa>
  108ab0:	89 c1                	mov    %eax,%ecx
  108ab2:	8b 55 dc             	mov    0xffffffdc(%ebp),%edx
  108ab5:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  108aba:	89 d3                	mov    %edx,%ebx
  108abc:	29 c3                	sub    %eax,%ebx
  108abe:	89 d8                	mov    %ebx,%eax
  108ac0:	c1 e0 09             	shl    $0x9,%eax
  108ac3:	39 c1                	cmp    %eax,%ecx
  108ac5:	74 24                	je     108aeb <pmap_check+0x8da>
  108ac7:	c7 44 24 0c 40 d5 10 	movl   $0x10d540,0xc(%esp)
  108ace:	00 
  108acf:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  108ad6:	00 
  108ad7:	c7 44 24 04 b5 02 00 	movl   $0x2b5,0x4(%esp)
  108ade:	00 
  108adf:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  108ae6:	e8 7d 7e ff ff       	call   100968 <debug_panic>
	assert(pi1->refcount == 1);
  108aeb:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  108aee:	8b 40 04             	mov    0x4(%eax),%eax
  108af1:	83 f8 01             	cmp    $0x1,%eax
  108af4:	74 24                	je     108b1a <pmap_check+0x909>
  108af6:	c7 44 24 0c b4 d2 10 	movl   $0x10d2b4,0xc(%esp)
  108afd:	00 
  108afe:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  108b05:	00 
  108b06:	c7 44 24 04 b6 02 00 	movl   $0x2b6,0x4(%esp)
  108b0d:	00 
  108b0e:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  108b15:	e8 4e 7e ff ff       	call   100968 <debug_panic>
	assert(pi2->refcount == 0);
  108b1a:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  108b1d:	8b 40 04             	mov    0x4(%eax),%eax
  108b20:	85 c0                	test   %eax,%eax
  108b22:	74 24                	je     108b48 <pmap_check+0x937>
  108b24:	c7 44 24 0c 90 d5 10 	movl   $0x10d590,0xc(%esp)
  108b2b:	00 
  108b2c:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  108b33:	00 
  108b34:	c7 44 24 04 b7 02 00 	movl   $0x2b7,0x4(%esp)
  108b3b:	00 
  108b3c:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  108b43:	e8 20 7e ff ff       	call   100968 <debug_panic>
	assert(mem_alloc() == NULL);	// still should have no pages free
  108b48:	e8 fe 84 ff ff       	call   10104b <mem_alloc>
  108b4d:	85 c0                	test   %eax,%eax
  108b4f:	74 24                	je     108b75 <pmap_check+0x964>
  108b51:	c7 44 24 0c c0 d1 10 	movl   $0x10d1c0,0xc(%esp)
  108b58:	00 
  108b59:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  108b60:	00 
  108b61:	c7 44 24 04 b8 02 00 	movl   $0x2b8,0x4(%esp)
  108b68:	00 
  108b69:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  108b70:	e8 f3 7d ff ff       	call   100968 <debug_panic>

	// unmapping pi1 at VM_USERLO+PAGESIZE should free it
	pmap_remove(pmap_bootpdir, VM_USERLO+PAGESIZE, PAGESIZE);
  108b75:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  108b7c:	00 
  108b7d:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  108b84:	40 
  108b85:	c7 04 24 00 00 18 00 	movl   $0x180000,(%esp)
  108b8c:	e8 74 dc ff ff       	call   106805 <pmap_remove>
	assert(va2pa(pmap_bootpdir, VM_USERLO+0) == ~0);
  108b91:	c7 44 24 04 00 00 00 	movl   $0x40000000,0x4(%esp)
  108b98:	40 
  108b99:	c7 04 24 00 00 18 00 	movl   $0x180000,(%esp)
  108ba0:	e8 ed f5 ff ff       	call   108192 <va2pa>
  108ba5:	83 f8 ff             	cmp    $0xffffffff,%eax
  108ba8:	74 24                	je     108bce <pmap_check+0x9bd>
  108baa:	c7 44 24 0c b8 d5 10 	movl   $0x10d5b8,0xc(%esp)
  108bb1:	00 
  108bb2:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  108bb9:	00 
  108bba:	c7 44 24 04 bc 02 00 	movl   $0x2bc,0x4(%esp)
  108bc1:	00 
  108bc2:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  108bc9:	e8 9a 7d ff ff       	call   100968 <debug_panic>
	assert(va2pa(pmap_bootpdir, VM_USERLO+PAGESIZE) == ~0);
  108bce:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  108bd5:	40 
  108bd6:	c7 04 24 00 00 18 00 	movl   $0x180000,(%esp)
  108bdd:	e8 b0 f5 ff ff       	call   108192 <va2pa>
  108be2:	83 f8 ff             	cmp    $0xffffffff,%eax
  108be5:	74 24                	je     108c0b <pmap_check+0x9fa>
  108be7:	c7 44 24 0c e0 d5 10 	movl   $0x10d5e0,0xc(%esp)
  108bee:	00 
  108bef:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  108bf6:	00 
  108bf7:	c7 44 24 04 bd 02 00 	movl   $0x2bd,0x4(%esp)
  108bfe:	00 
  108bff:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  108c06:	e8 5d 7d ff ff       	call   100968 <debug_panic>
	assert(pi1->refcount == 0);
  108c0b:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  108c0e:	8b 40 04             	mov    0x4(%eax),%eax
  108c11:	85 c0                	test   %eax,%eax
  108c13:	74 24                	je     108c39 <pmap_check+0xa28>
  108c15:	c7 44 24 0c 0f d6 10 	movl   $0x10d60f,0xc(%esp)
  108c1c:	00 
  108c1d:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  108c24:	00 
  108c25:	c7 44 24 04 be 02 00 	movl   $0x2be,0x4(%esp)
  108c2c:	00 
  108c2d:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  108c34:	e8 2f 7d ff ff       	call   100968 <debug_panic>
	assert(pi2->refcount == 0);
  108c39:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  108c3c:	8b 40 04             	mov    0x4(%eax),%eax
  108c3f:	85 c0                	test   %eax,%eax
  108c41:	74 24                	je     108c67 <pmap_check+0xa56>
  108c43:	c7 44 24 0c 90 d5 10 	movl   $0x10d590,0xc(%esp)
  108c4a:	00 
  108c4b:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  108c52:	00 
  108c53:	c7 44 24 04 bf 02 00 	movl   $0x2bf,0x4(%esp)
  108c5a:	00 
  108c5b:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  108c62:	e8 01 7d ff ff       	call   100968 <debug_panic>

	// so it should be returned by page_alloc
	assert(mem_alloc() == pi1);
  108c67:	e8 df 83 ff ff       	call   10104b <mem_alloc>
  108c6c:	3b 45 dc             	cmp    0xffffffdc(%ebp),%eax
  108c6f:	74 24                	je     108c95 <pmap_check+0xa84>
  108c71:	c7 44 24 0c 22 d6 10 	movl   $0x10d622,0xc(%esp)
  108c78:	00 
  108c79:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  108c80:	00 
  108c81:	c7 44 24 04 c2 02 00 	movl   $0x2c2,0x4(%esp)
  108c88:	00 
  108c89:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  108c90:	e8 d3 7c ff ff       	call   100968 <debug_panic>

	// should once again have no free memory
	assert(mem_alloc() == NULL);
  108c95:	e8 b1 83 ff ff       	call   10104b <mem_alloc>
  108c9a:	85 c0                	test   %eax,%eax
  108c9c:	74 24                	je     108cc2 <pmap_check+0xab1>
  108c9e:	c7 44 24 0c c0 d1 10 	movl   $0x10d1c0,0xc(%esp)
  108ca5:	00 
  108ca6:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  108cad:	00 
  108cae:	c7 44 24 04 c5 02 00 	movl   $0x2c5,0x4(%esp)
  108cb5:	00 
  108cb6:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  108cbd:	e8 a6 7c ff ff       	call   100968 <debug_panic>

	// should be able to pmap_insert to change a page
	// and see the new data immediately.
	memset(mem_pi2ptr(pi1), 1, PAGESIZE);
  108cc2:	8b 55 dc             	mov    0xffffffdc(%ebp),%edx
  108cc5:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  108cca:	89 d1                	mov    %edx,%ecx
  108ccc:	29 c1                	sub    %eax,%ecx
  108cce:	89 c8                	mov    %ecx,%eax
  108cd0:	c1 e0 09             	shl    $0x9,%eax
  108cd3:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  108cda:	00 
  108cdb:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  108ce2:	00 
  108ce3:	89 04 24             	mov    %eax,(%esp)
  108ce6:	e8 0a 2b 00 00       	call   10b7f5 <memset>
	memset(mem_pi2ptr(pi2), 2, PAGESIZE);
  108ceb:	8b 55 e0             	mov    0xffffffe0(%ebp),%edx
  108cee:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  108cf3:	89 d3                	mov    %edx,%ebx
  108cf5:	29 c3                	sub    %eax,%ebx
  108cf7:	89 d8                	mov    %ebx,%eax
  108cf9:	c1 e0 09             	shl    $0x9,%eax
  108cfc:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  108d03:	00 
  108d04:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
  108d0b:	00 
  108d0c:	89 04 24             	mov    %eax,(%esp)
  108d0f:	e8 e1 2a 00 00       	call   10b7f5 <memset>
	pmap_insert(pmap_bootpdir, pi1, VM_USERLO, 0);
  108d14:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  108d1b:	00 
  108d1c:	c7 44 24 08 00 00 00 	movl   $0x40000000,0x8(%esp)
  108d23:	40 
  108d24:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  108d27:	89 44 24 04          	mov    %eax,0x4(%esp)
  108d2b:	c7 04 24 00 00 18 00 	movl   $0x180000,(%esp)
  108d32:	e8 50 d9 ff ff       	call   106687 <pmap_insert>
	assert(pi1->refcount == 1);
  108d37:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  108d3a:	8b 40 04             	mov    0x4(%eax),%eax
  108d3d:	83 f8 01             	cmp    $0x1,%eax
  108d40:	74 24                	je     108d66 <pmap_check+0xb55>
  108d42:	c7 44 24 0c b4 d2 10 	movl   $0x10d2b4,0xc(%esp)
  108d49:	00 
  108d4a:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  108d51:	00 
  108d52:	c7 44 24 04 cc 02 00 	movl   $0x2cc,0x4(%esp)
  108d59:	00 
  108d5a:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  108d61:	e8 02 7c ff ff       	call   100968 <debug_panic>
	assert(*(int*)VM_USERLO == 0x01010101);
  108d66:	b8 00 00 00 40       	mov    $0x40000000,%eax
  108d6b:	8b 00                	mov    (%eax),%eax
  108d6d:	3d 01 01 01 01       	cmp    $0x1010101,%eax
  108d72:	74 24                	je     108d98 <pmap_check+0xb87>
  108d74:	c7 44 24 0c 38 d6 10 	movl   $0x10d638,0xc(%esp)
  108d7b:	00 
  108d7c:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  108d83:	00 
  108d84:	c7 44 24 04 cd 02 00 	movl   $0x2cd,0x4(%esp)
  108d8b:	00 
  108d8c:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  108d93:	e8 d0 7b ff ff       	call   100968 <debug_panic>
	pmap_insert(pmap_bootpdir, pi2, VM_USERLO, 0);
  108d98:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  108d9f:	00 
  108da0:	c7 44 24 08 00 00 00 	movl   $0x40000000,0x8(%esp)
  108da7:	40 
  108da8:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  108dab:	89 44 24 04          	mov    %eax,0x4(%esp)
  108daf:	c7 04 24 00 00 18 00 	movl   $0x180000,(%esp)
  108db6:	e8 cc d8 ff ff       	call   106687 <pmap_insert>
	assert(*(int*)VM_USERLO == 0x02020202);
  108dbb:	b8 00 00 00 40       	mov    $0x40000000,%eax
  108dc0:	8b 00                	mov    (%eax),%eax
  108dc2:	3d 02 02 02 02       	cmp    $0x2020202,%eax
  108dc7:	74 24                	je     108ded <pmap_check+0xbdc>
  108dc9:	c7 44 24 0c 58 d6 10 	movl   $0x10d658,0xc(%esp)
  108dd0:	00 
  108dd1:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  108dd8:	00 
  108dd9:	c7 44 24 04 cf 02 00 	movl   $0x2cf,0x4(%esp)
  108de0:	00 
  108de1:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  108de8:	e8 7b 7b ff ff       	call   100968 <debug_panic>
	assert(pi2->refcount == 1);
  108ded:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  108df0:	8b 40 04             	mov    0x4(%eax),%eax
  108df3:	83 f8 01             	cmp    $0x1,%eax
  108df6:	74 24                	je     108e1c <pmap_check+0xc0b>
  108df8:	c7 44 24 0c 51 d3 10 	movl   $0x10d351,0xc(%esp)
  108dff:	00 
  108e00:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  108e07:	00 
  108e08:	c7 44 24 04 d0 02 00 	movl   $0x2d0,0x4(%esp)
  108e0f:	00 
  108e10:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  108e17:	e8 4c 7b ff ff       	call   100968 <debug_panic>
	assert(pi1->refcount == 0);
  108e1c:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  108e1f:	8b 40 04             	mov    0x4(%eax),%eax
  108e22:	85 c0                	test   %eax,%eax
  108e24:	74 24                	je     108e4a <pmap_check+0xc39>
  108e26:	c7 44 24 0c 0f d6 10 	movl   $0x10d60f,0xc(%esp)
  108e2d:	00 
  108e2e:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  108e35:	00 
  108e36:	c7 44 24 04 d1 02 00 	movl   $0x2d1,0x4(%esp)
  108e3d:	00 
  108e3e:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  108e45:	e8 1e 7b ff ff       	call   100968 <debug_panic>
	assert(mem_alloc() == pi1);
  108e4a:	e8 fc 81 ff ff       	call   10104b <mem_alloc>
  108e4f:	3b 45 dc             	cmp    0xffffffdc(%ebp),%eax
  108e52:	74 24                	je     108e78 <pmap_check+0xc67>
  108e54:	c7 44 24 0c 22 d6 10 	movl   $0x10d622,0xc(%esp)
  108e5b:	00 
  108e5c:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  108e63:	00 
  108e64:	c7 44 24 04 d2 02 00 	movl   $0x2d2,0x4(%esp)
  108e6b:	00 
  108e6c:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  108e73:	e8 f0 7a ff ff       	call   100968 <debug_panic>
	pmap_remove(pmap_bootpdir, VM_USERLO, PAGESIZE);
  108e78:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  108e7f:	00 
  108e80:	c7 44 24 04 00 00 00 	movl   $0x40000000,0x4(%esp)
  108e87:	40 
  108e88:	c7 04 24 00 00 18 00 	movl   $0x180000,(%esp)
  108e8f:	e8 71 d9 ff ff       	call   106805 <pmap_remove>
	assert(pi2->refcount == 0);
  108e94:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  108e97:	8b 40 04             	mov    0x4(%eax),%eax
  108e9a:	85 c0                	test   %eax,%eax
  108e9c:	74 24                	je     108ec2 <pmap_check+0xcb1>
  108e9e:	c7 44 24 0c 90 d5 10 	movl   $0x10d590,0xc(%esp)
  108ea5:	00 
  108ea6:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  108ead:	00 
  108eae:	c7 44 24 04 d4 02 00 	movl   $0x2d4,0x4(%esp)
  108eb5:	00 
  108eb6:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  108ebd:	e8 a6 7a ff ff       	call   100968 <debug_panic>
	assert(mem_alloc() == pi2);
  108ec2:	e8 84 81 ff ff       	call   10104b <mem_alloc>
  108ec7:	3b 45 e0             	cmp    0xffffffe0(%ebp),%eax
  108eca:	74 24                	je     108ef0 <pmap_check+0xcdf>
  108ecc:	c7 44 24 0c a3 d5 10 	movl   $0x10d5a3,0xc(%esp)
  108ed3:	00 
  108ed4:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  108edb:	00 
  108edc:	c7 44 24 04 d5 02 00 	movl   $0x2d5,0x4(%esp)
  108ee3:	00 
  108ee4:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  108eeb:	e8 78 7a ff ff       	call   100968 <debug_panic>

	// now use a pmap_remove on a large region to take pi0 back
	pmap_remove(pmap_bootpdir, VM_USERLO, VM_USERHI-VM_USERLO);
  108ef0:	c7 44 24 08 00 00 00 	movl   $0xb0000000,0x8(%esp)
  108ef7:	b0 
  108ef8:	c7 44 24 04 00 00 00 	movl   $0x40000000,0x4(%esp)
  108eff:	40 
  108f00:	c7 04 24 00 00 18 00 	movl   $0x180000,(%esp)
  108f07:	e8 f9 d8 ff ff       	call   106805 <pmap_remove>
	assert(pmap_bootpdir[PDX(VM_USERLO)] == PTE_ZERO);
  108f0c:	a1 00 04 18 00       	mov    0x180400,%eax
  108f11:	ba 00 10 18 00       	mov    $0x181000,%edx
  108f16:	39 d0                	cmp    %edx,%eax
  108f18:	74 24                	je     108f3e <pmap_check+0xd2d>
  108f1a:	c7 44 24 0c 78 d6 10 	movl   $0x10d678,0xc(%esp)
  108f21:	00 
  108f22:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  108f29:	00 
  108f2a:	c7 44 24 04 d9 02 00 	movl   $0x2d9,0x4(%esp)
  108f31:	00 
  108f32:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  108f39:	e8 2a 7a ff ff       	call   100968 <debug_panic>
	assert(pi0->refcount == 0);
  108f3e:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  108f41:	8b 40 04             	mov    0x4(%eax),%eax
  108f44:	85 c0                	test   %eax,%eax
  108f46:	74 24                	je     108f6c <pmap_check+0xd5b>
  108f48:	c7 44 24 0c a2 d6 10 	movl   $0x10d6a2,0xc(%esp)
  108f4f:	00 
  108f50:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  108f57:	00 
  108f58:	c7 44 24 04 da 02 00 	movl   $0x2da,0x4(%esp)
  108f5f:	00 
  108f60:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  108f67:	e8 fc 79 ff ff       	call   100968 <debug_panic>
	assert(mem_alloc() == pi0);
  108f6c:	e8 da 80 ff ff       	call   10104b <mem_alloc>
  108f71:	3b 45 d8             	cmp    0xffffffd8(%ebp),%eax
  108f74:	74 24                	je     108f9a <pmap_check+0xd89>
  108f76:	c7 44 24 0c b5 d6 10 	movl   $0x10d6b5,0xc(%esp)
  108f7d:	00 
  108f7e:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  108f85:	00 
  108f86:	c7 44 24 04 db 02 00 	movl   $0x2db,0x4(%esp)
  108f8d:	00 
  108f8e:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  108f95:	e8 ce 79 ff ff       	call   100968 <debug_panic>
	assert(mem_freelist == NULL);
  108f9a:	a1 80 ed 17 00       	mov    0x17ed80,%eax
  108f9f:	85 c0                	test   %eax,%eax
  108fa1:	74 24                	je     108fc7 <pmap_check+0xdb6>
  108fa3:	c7 44 24 0c c8 d6 10 	movl   $0x10d6c8,0xc(%esp)
  108faa:	00 
  108fab:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  108fb2:	00 
  108fb3:	c7 44 24 04 dc 02 00 	movl   $0x2dc,0x4(%esp)
  108fba:	00 
  108fbb:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  108fc2:	e8 a1 79 ff ff       	call   100968 <debug_panic>

	// test pmap_remove with large, non-ptable-aligned regions
	mem_free(pi1);
  108fc7:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  108fca:	89 04 24             	mov    %eax,(%esp)
  108fcd:	e8 bd 80 ff ff       	call   10108f <mem_free>
	uintptr_t va = VM_USERLO;
  108fd2:	c7 45 f8 00 00 00 40 	movl   $0x40000000,0xfffffff8(%ebp)
	assert(pmap_insert(pmap_bootpdir, pi0, va, 0));
  108fd9:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  108fe0:	00 
  108fe1:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  108fe4:	89 44 24 08          	mov    %eax,0x8(%esp)
  108fe8:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  108feb:	89 44 24 04          	mov    %eax,0x4(%esp)
  108fef:	c7 04 24 00 00 18 00 	movl   $0x180000,(%esp)
  108ff6:	e8 8c d6 ff ff       	call   106687 <pmap_insert>
  108ffb:	85 c0                	test   %eax,%eax
  108ffd:	75 24                	jne    109023 <pmap_check+0xe12>
  108fff:	c7 44 24 0c e0 d6 10 	movl   $0x10d6e0,0xc(%esp)
  109006:	00 
  109007:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  10900e:	00 
  10900f:	c7 44 24 04 e1 02 00 	movl   $0x2e1,0x4(%esp)
  109016:	00 
  109017:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  10901e:	e8 45 79 ff ff       	call   100968 <debug_panic>
	assert(pmap_insert(pmap_bootpdir, pi0, va+PAGESIZE, 0));
  109023:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  109026:	05 00 10 00 00       	add    $0x1000,%eax
  10902b:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  109032:	00 
  109033:	89 44 24 08          	mov    %eax,0x8(%esp)
  109037:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  10903a:	89 44 24 04          	mov    %eax,0x4(%esp)
  10903e:	c7 04 24 00 00 18 00 	movl   $0x180000,(%esp)
  109045:	e8 3d d6 ff ff       	call   106687 <pmap_insert>
  10904a:	85 c0                	test   %eax,%eax
  10904c:	75 24                	jne    109072 <pmap_check+0xe61>
  10904e:	c7 44 24 0c 08 d7 10 	movl   $0x10d708,0xc(%esp)
  109055:	00 
  109056:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  10905d:	00 
  10905e:	c7 44 24 04 e2 02 00 	movl   $0x2e2,0x4(%esp)
  109065:	00 
  109066:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  10906d:	e8 f6 78 ff ff       	call   100968 <debug_panic>
	assert(pmap_insert(pmap_bootpdir, pi0, va+PTSIZE-PAGESIZE, 0));
  109072:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  109075:	05 00 f0 3f 00       	add    $0x3ff000,%eax
  10907a:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  109081:	00 
  109082:	89 44 24 08          	mov    %eax,0x8(%esp)
  109086:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  109089:	89 44 24 04          	mov    %eax,0x4(%esp)
  10908d:	c7 04 24 00 00 18 00 	movl   $0x180000,(%esp)
  109094:	e8 ee d5 ff ff       	call   106687 <pmap_insert>
  109099:	85 c0                	test   %eax,%eax
  10909b:	75 24                	jne    1090c1 <pmap_check+0xeb0>
  10909d:	c7 44 24 0c 38 d7 10 	movl   $0x10d738,0xc(%esp)
  1090a4:	00 
  1090a5:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  1090ac:	00 
  1090ad:	c7 44 24 04 e3 02 00 	movl   $0x2e3,0x4(%esp)
  1090b4:	00 
  1090b5:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  1090bc:	e8 a7 78 ff ff       	call   100968 <debug_panic>
	assert(PGADDR(pmap_bootpdir[PDX(VM_USERLO)]) == mem_pi2phys(pi1));
  1090c1:	a1 00 04 18 00       	mov    0x180400,%eax
  1090c6:	89 c1                	mov    %eax,%ecx
  1090c8:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
  1090ce:	8b 55 dc             	mov    0xffffffdc(%ebp),%edx
  1090d1:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  1090d6:	89 d3                	mov    %edx,%ebx
  1090d8:	29 c3                	sub    %eax,%ebx
  1090da:	89 d8                	mov    %ebx,%eax
  1090dc:	c1 e0 09             	shl    $0x9,%eax
  1090df:	39 c1                	cmp    %eax,%ecx
  1090e1:	74 24                	je     109107 <pmap_check+0xef6>
  1090e3:	c7 44 24 0c 70 d7 10 	movl   $0x10d770,0xc(%esp)
  1090ea:	00 
  1090eb:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  1090f2:	00 
  1090f3:	c7 44 24 04 e4 02 00 	movl   $0x2e4,0x4(%esp)
  1090fa:	00 
  1090fb:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  109102:	e8 61 78 ff ff       	call   100968 <debug_panic>
	assert(mem_freelist == NULL);
  109107:	a1 80 ed 17 00       	mov    0x17ed80,%eax
  10910c:	85 c0                	test   %eax,%eax
  10910e:	74 24                	je     109134 <pmap_check+0xf23>
  109110:	c7 44 24 0c c8 d6 10 	movl   $0x10d6c8,0xc(%esp)
  109117:	00 
  109118:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  10911f:	00 
  109120:	c7 44 24 04 e5 02 00 	movl   $0x2e5,0x4(%esp)
  109127:	00 
  109128:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  10912f:	e8 34 78 ff ff       	call   100968 <debug_panic>
	mem_free(pi2);
  109134:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  109137:	89 04 24             	mov    %eax,(%esp)
  10913a:	e8 50 7f ff ff       	call   10108f <mem_free>
	assert(pmap_insert(pmap_bootpdir, pi0, va+PTSIZE, 0));
  10913f:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  109142:	05 00 00 40 00       	add    $0x400000,%eax
  109147:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  10914e:	00 
  10914f:	89 44 24 08          	mov    %eax,0x8(%esp)
  109153:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  109156:	89 44 24 04          	mov    %eax,0x4(%esp)
  10915a:	c7 04 24 00 00 18 00 	movl   $0x180000,(%esp)
  109161:	e8 21 d5 ff ff       	call   106687 <pmap_insert>
  109166:	85 c0                	test   %eax,%eax
  109168:	75 24                	jne    10918e <pmap_check+0xf7d>
  10916a:	c7 44 24 0c ac d7 10 	movl   $0x10d7ac,0xc(%esp)
  109171:	00 
  109172:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  109179:	00 
  10917a:	c7 44 24 04 e7 02 00 	movl   $0x2e7,0x4(%esp)
  109181:	00 
  109182:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  109189:	e8 da 77 ff ff       	call   100968 <debug_panic>
	assert(pmap_insert(pmap_bootpdir, pi0, va+PTSIZE+PAGESIZE, 0));
  10918e:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  109191:	05 00 10 40 00       	add    $0x401000,%eax
  109196:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  10919d:	00 
  10919e:	89 44 24 08          	mov    %eax,0x8(%esp)
  1091a2:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  1091a5:	89 44 24 04          	mov    %eax,0x4(%esp)
  1091a9:	c7 04 24 00 00 18 00 	movl   $0x180000,(%esp)
  1091b0:	e8 d2 d4 ff ff       	call   106687 <pmap_insert>
  1091b5:	85 c0                	test   %eax,%eax
  1091b7:	75 24                	jne    1091dd <pmap_check+0xfcc>
  1091b9:	c7 44 24 0c dc d7 10 	movl   $0x10d7dc,0xc(%esp)
  1091c0:	00 
  1091c1:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  1091c8:	00 
  1091c9:	c7 44 24 04 e8 02 00 	movl   $0x2e8,0x4(%esp)
  1091d0:	00 
  1091d1:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  1091d8:	e8 8b 77 ff ff       	call   100968 <debug_panic>
	assert(pmap_insert(pmap_bootpdir, pi0, va+PTSIZE*2-PAGESIZE, 0));
  1091dd:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1091e0:	05 00 f0 7f 00       	add    $0x7ff000,%eax
  1091e5:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  1091ec:	00 
  1091ed:	89 44 24 08          	mov    %eax,0x8(%esp)
  1091f1:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  1091f4:	89 44 24 04          	mov    %eax,0x4(%esp)
  1091f8:	c7 04 24 00 00 18 00 	movl   $0x180000,(%esp)
  1091ff:	e8 83 d4 ff ff       	call   106687 <pmap_insert>
  109204:	85 c0                	test   %eax,%eax
  109206:	75 24                	jne    10922c <pmap_check+0x101b>
  109208:	c7 44 24 0c 14 d8 10 	movl   $0x10d814,0xc(%esp)
  10920f:	00 
  109210:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  109217:	00 
  109218:	c7 44 24 04 e9 02 00 	movl   $0x2e9,0x4(%esp)
  10921f:	00 
  109220:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  109227:	e8 3c 77 ff ff       	call   100968 <debug_panic>
	assert(PGADDR(pmap_bootpdir[PDX(VM_USERLO+PTSIZE)])
  10922c:	a1 04 04 18 00       	mov    0x180404,%eax
  109231:	89 c1                	mov    %eax,%ecx
  109233:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
  109239:	8b 55 e0             	mov    0xffffffe0(%ebp),%edx
  10923c:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  109241:	89 d3                	mov    %edx,%ebx
  109243:	29 c3                	sub    %eax,%ebx
  109245:	89 d8                	mov    %ebx,%eax
  109247:	c1 e0 09             	shl    $0x9,%eax
  10924a:	39 c1                	cmp    %eax,%ecx
  10924c:	74 24                	je     109272 <pmap_check+0x1061>
  10924e:	c7 44 24 0c 50 d8 10 	movl   $0x10d850,0xc(%esp)
  109255:	00 
  109256:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  10925d:	00 
  10925e:	c7 44 24 04 eb 02 00 	movl   $0x2eb,0x4(%esp)
  109265:	00 
  109266:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  10926d:	e8 f6 76 ff ff       	call   100968 <debug_panic>
		== mem_pi2phys(pi2));
	assert(mem_freelist == NULL);
  109272:	a1 80 ed 17 00       	mov    0x17ed80,%eax
  109277:	85 c0                	test   %eax,%eax
  109279:	74 24                	je     10929f <pmap_check+0x108e>
  10927b:	c7 44 24 0c c8 d6 10 	movl   $0x10d6c8,0xc(%esp)
  109282:	00 
  109283:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  10928a:	00 
  10928b:	c7 44 24 04 ec 02 00 	movl   $0x2ec,0x4(%esp)
  109292:	00 
  109293:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  10929a:	e8 c9 76 ff ff       	call   100968 <debug_panic>
	mem_free(pi3);
  10929f:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  1092a2:	89 04 24             	mov    %eax,(%esp)
  1092a5:	e8 e5 7d ff ff       	call   10108f <mem_free>
	assert(pmap_insert(pmap_bootpdir, pi0, va+PTSIZE*2, 0));
  1092aa:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1092ad:	05 00 00 80 00       	add    $0x800000,%eax
  1092b2:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  1092b9:	00 
  1092ba:	89 44 24 08          	mov    %eax,0x8(%esp)
  1092be:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  1092c1:	89 44 24 04          	mov    %eax,0x4(%esp)
  1092c5:	c7 04 24 00 00 18 00 	movl   $0x180000,(%esp)
  1092cc:	e8 b6 d3 ff ff       	call   106687 <pmap_insert>
  1092d1:	85 c0                	test   %eax,%eax
  1092d3:	75 24                	jne    1092f9 <pmap_check+0x10e8>
  1092d5:	c7 44 24 0c 94 d8 10 	movl   $0x10d894,0xc(%esp)
  1092dc:	00 
  1092dd:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  1092e4:	00 
  1092e5:	c7 44 24 04 ee 02 00 	movl   $0x2ee,0x4(%esp)
  1092ec:	00 
  1092ed:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  1092f4:	e8 6f 76 ff ff       	call   100968 <debug_panic>
	assert(pmap_insert(pmap_bootpdir, pi0, va+PTSIZE*2+PAGESIZE, 0));
  1092f9:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1092fc:	05 00 10 80 00       	add    $0x801000,%eax
  109301:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  109308:	00 
  109309:	89 44 24 08          	mov    %eax,0x8(%esp)
  10930d:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  109310:	89 44 24 04          	mov    %eax,0x4(%esp)
  109314:	c7 04 24 00 00 18 00 	movl   $0x180000,(%esp)
  10931b:	e8 67 d3 ff ff       	call   106687 <pmap_insert>
  109320:	85 c0                	test   %eax,%eax
  109322:	75 24                	jne    109348 <pmap_check+0x1137>
  109324:	c7 44 24 0c c4 d8 10 	movl   $0x10d8c4,0xc(%esp)
  10932b:	00 
  10932c:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  109333:	00 
  109334:	c7 44 24 04 ef 02 00 	movl   $0x2ef,0x4(%esp)
  10933b:	00 
  10933c:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  109343:	e8 20 76 ff ff       	call   100968 <debug_panic>
	assert(pmap_insert(pmap_bootpdir, pi0, va+PTSIZE*3-PAGESIZE*2, 0));
  109348:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10934b:	05 00 e0 bf 00       	add    $0xbfe000,%eax
  109350:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  109357:	00 
  109358:	89 44 24 08          	mov    %eax,0x8(%esp)
  10935c:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  10935f:	89 44 24 04          	mov    %eax,0x4(%esp)
  109363:	c7 04 24 00 00 18 00 	movl   $0x180000,(%esp)
  10936a:	e8 18 d3 ff ff       	call   106687 <pmap_insert>
  10936f:	85 c0                	test   %eax,%eax
  109371:	75 24                	jne    109397 <pmap_check+0x1186>
  109373:	c7 44 24 0c 00 d9 10 	movl   $0x10d900,0xc(%esp)
  10937a:	00 
  10937b:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  109382:	00 
  109383:	c7 44 24 04 f0 02 00 	movl   $0x2f0,0x4(%esp)
  10938a:	00 
  10938b:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  109392:	e8 d1 75 ff ff       	call   100968 <debug_panic>
	assert(pmap_insert(pmap_bootpdir, pi0, va+PTSIZE*3-PAGESIZE, 0));
  109397:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10939a:	05 00 f0 bf 00       	add    $0xbff000,%eax
  10939f:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  1093a6:	00 
  1093a7:	89 44 24 08          	mov    %eax,0x8(%esp)
  1093ab:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  1093ae:	89 44 24 04          	mov    %eax,0x4(%esp)
  1093b2:	c7 04 24 00 00 18 00 	movl   $0x180000,(%esp)
  1093b9:	e8 c9 d2 ff ff       	call   106687 <pmap_insert>
  1093be:	85 c0                	test   %eax,%eax
  1093c0:	75 24                	jne    1093e6 <pmap_check+0x11d5>
  1093c2:	c7 44 24 0c 3c d9 10 	movl   $0x10d93c,0xc(%esp)
  1093c9:	00 
  1093ca:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  1093d1:	00 
  1093d2:	c7 44 24 04 f1 02 00 	movl   $0x2f1,0x4(%esp)
  1093d9:	00 
  1093da:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  1093e1:	e8 82 75 ff ff       	call   100968 <debug_panic>
	assert(PGADDR(pmap_bootpdir[PDX(VM_USERLO+PTSIZE*2)])
  1093e6:	a1 08 04 18 00       	mov    0x180408,%eax
  1093eb:	89 c1                	mov    %eax,%ecx
  1093ed:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
  1093f3:	8b 55 e4             	mov    0xffffffe4(%ebp),%edx
  1093f6:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  1093fb:	89 d3                	mov    %edx,%ebx
  1093fd:	29 c3                	sub    %eax,%ebx
  1093ff:	89 d8                	mov    %ebx,%eax
  109401:	c1 e0 09             	shl    $0x9,%eax
  109404:	39 c1                	cmp    %eax,%ecx
  109406:	74 24                	je     10942c <pmap_check+0x121b>
  109408:	c7 44 24 0c 78 d9 10 	movl   $0x10d978,0xc(%esp)
  10940f:	00 
  109410:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  109417:	00 
  109418:	c7 44 24 04 f3 02 00 	movl   $0x2f3,0x4(%esp)
  10941f:	00 
  109420:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  109427:	e8 3c 75 ff ff       	call   100968 <debug_panic>
		== mem_pi2phys(pi3));
	assert(mem_freelist == NULL);
  10942c:	a1 80 ed 17 00       	mov    0x17ed80,%eax
  109431:	85 c0                	test   %eax,%eax
  109433:	74 24                	je     109459 <pmap_check+0x1248>
  109435:	c7 44 24 0c c8 d6 10 	movl   $0x10d6c8,0xc(%esp)
  10943c:	00 
  10943d:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  109444:	00 
  109445:	c7 44 24 04 f4 02 00 	movl   $0x2f4,0x4(%esp)
  10944c:	00 
  10944d:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  109454:	e8 0f 75 ff ff       	call   100968 <debug_panic>
	assert(pi0->refcount == 10);
  109459:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  10945c:	8b 40 04             	mov    0x4(%eax),%eax
  10945f:	83 f8 0a             	cmp    $0xa,%eax
  109462:	74 24                	je     109488 <pmap_check+0x1277>
  109464:	c7 44 24 0c bb d9 10 	movl   $0x10d9bb,0xc(%esp)
  10946b:	00 
  10946c:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  109473:	00 
  109474:	c7 44 24 04 f5 02 00 	movl   $0x2f5,0x4(%esp)
  10947b:	00 
  10947c:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  109483:	e8 e0 74 ff ff       	call   100968 <debug_panic>
	assert(pi1->refcount == 1);
  109488:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  10948b:	8b 40 04             	mov    0x4(%eax),%eax
  10948e:	83 f8 01             	cmp    $0x1,%eax
  109491:	74 24                	je     1094b7 <pmap_check+0x12a6>
  109493:	c7 44 24 0c b4 d2 10 	movl   $0x10d2b4,0xc(%esp)
  10949a:	00 
  10949b:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  1094a2:	00 
  1094a3:	c7 44 24 04 f6 02 00 	movl   $0x2f6,0x4(%esp)
  1094aa:	00 
  1094ab:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  1094b2:	e8 b1 74 ff ff       	call   100968 <debug_panic>
	assert(pi2->refcount == 1);
  1094b7:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  1094ba:	8b 40 04             	mov    0x4(%eax),%eax
  1094bd:	83 f8 01             	cmp    $0x1,%eax
  1094c0:	74 24                	je     1094e6 <pmap_check+0x12d5>
  1094c2:	c7 44 24 0c 51 d3 10 	movl   $0x10d351,0xc(%esp)
  1094c9:	00 
  1094ca:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  1094d1:	00 
  1094d2:	c7 44 24 04 f7 02 00 	movl   $0x2f7,0x4(%esp)
  1094d9:	00 
  1094da:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  1094e1:	e8 82 74 ff ff       	call   100968 <debug_panic>
	assert(pi3->refcount == 1);
  1094e6:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  1094e9:	8b 40 04             	mov    0x4(%eax),%eax
  1094ec:	83 f8 01             	cmp    $0x1,%eax
  1094ef:	74 24                	je     109515 <pmap_check+0x1304>
  1094f1:	c7 44 24 0c cf d9 10 	movl   $0x10d9cf,0xc(%esp)
  1094f8:	00 
  1094f9:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  109500:	00 
  109501:	c7 44 24 04 f8 02 00 	movl   $0x2f8,0x4(%esp)
  109508:	00 
  109509:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  109510:	e8 53 74 ff ff       	call   100968 <debug_panic>
	pmap_remove(pmap_bootpdir, va+PAGESIZE, PTSIZE*3-PAGESIZE*2);
  109515:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  109518:	05 00 10 00 00       	add    $0x1000,%eax
  10951d:	c7 44 24 08 00 e0 bf 	movl   $0xbfe000,0x8(%esp)
  109524:	00 
  109525:	89 44 24 04          	mov    %eax,0x4(%esp)
  109529:	c7 04 24 00 00 18 00 	movl   $0x180000,(%esp)
  109530:	e8 d0 d2 ff ff       	call   106805 <pmap_remove>
	assert(pi0->refcount == 2);
  109535:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  109538:	8b 40 04             	mov    0x4(%eax),%eax
  10953b:	83 f8 02             	cmp    $0x2,%eax
  10953e:	74 24                	je     109564 <pmap_check+0x1353>
  109540:	c7 44 24 0c e2 d9 10 	movl   $0x10d9e2,0xc(%esp)
  109547:	00 
  109548:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  10954f:	00 
  109550:	c7 44 24 04 fa 02 00 	movl   $0x2fa,0x4(%esp)
  109557:	00 
  109558:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  10955f:	e8 04 74 ff ff       	call   100968 <debug_panic>
	assert(pi2->refcount == 0); assert(mem_alloc() == pi2);
  109564:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  109567:	8b 40 04             	mov    0x4(%eax),%eax
  10956a:	85 c0                	test   %eax,%eax
  10956c:	74 24                	je     109592 <pmap_check+0x1381>
  10956e:	c7 44 24 0c 90 d5 10 	movl   $0x10d590,0xc(%esp)
  109575:	00 
  109576:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  10957d:	00 
  10957e:	c7 44 24 04 fb 02 00 	movl   $0x2fb,0x4(%esp)
  109585:	00 
  109586:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  10958d:	e8 d6 73 ff ff       	call   100968 <debug_panic>
  109592:	e8 b4 7a ff ff       	call   10104b <mem_alloc>
  109597:	3b 45 e0             	cmp    0xffffffe0(%ebp),%eax
  10959a:	74 24                	je     1095c0 <pmap_check+0x13af>
  10959c:	c7 44 24 0c a3 d5 10 	movl   $0x10d5a3,0xc(%esp)
  1095a3:	00 
  1095a4:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  1095ab:	00 
  1095ac:	c7 44 24 04 fb 02 00 	movl   $0x2fb,0x4(%esp)
  1095b3:	00 
  1095b4:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  1095bb:	e8 a8 73 ff ff       	call   100968 <debug_panic>
	assert(mem_freelist == NULL);
  1095c0:	a1 80 ed 17 00       	mov    0x17ed80,%eax
  1095c5:	85 c0                	test   %eax,%eax
  1095c7:	74 24                	je     1095ed <pmap_check+0x13dc>
  1095c9:	c7 44 24 0c c8 d6 10 	movl   $0x10d6c8,0xc(%esp)
  1095d0:	00 
  1095d1:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  1095d8:	00 
  1095d9:	c7 44 24 04 fc 02 00 	movl   $0x2fc,0x4(%esp)
  1095e0:	00 
  1095e1:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  1095e8:	e8 7b 73 ff ff       	call   100968 <debug_panic>
	pmap_remove(pmap_bootpdir, va, PTSIZE*3-PAGESIZE);
  1095ed:	c7 44 24 08 00 f0 bf 	movl   $0xbff000,0x8(%esp)
  1095f4:	00 
  1095f5:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1095f8:	89 44 24 04          	mov    %eax,0x4(%esp)
  1095fc:	c7 04 24 00 00 18 00 	movl   $0x180000,(%esp)
  109603:	e8 fd d1 ff ff       	call   106805 <pmap_remove>
	assert(pi0->refcount == 1);
  109608:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  10960b:	8b 40 04             	mov    0x4(%eax),%eax
  10960e:	83 f8 01             	cmp    $0x1,%eax
  109611:	74 24                	je     109637 <pmap_check+0x1426>
  109613:	c7 44 24 0c c7 d2 10 	movl   $0x10d2c7,0xc(%esp)
  10961a:	00 
  10961b:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  109622:	00 
  109623:	c7 44 24 04 fe 02 00 	movl   $0x2fe,0x4(%esp)
  10962a:	00 
  10962b:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  109632:	e8 31 73 ff ff       	call   100968 <debug_panic>
	assert(pi1->refcount == 0); assert(mem_alloc() == pi1);
  109637:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  10963a:	8b 40 04             	mov    0x4(%eax),%eax
  10963d:	85 c0                	test   %eax,%eax
  10963f:	74 24                	je     109665 <pmap_check+0x1454>
  109641:	c7 44 24 0c 0f d6 10 	movl   $0x10d60f,0xc(%esp)
  109648:	00 
  109649:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  109650:	00 
  109651:	c7 44 24 04 ff 02 00 	movl   $0x2ff,0x4(%esp)
  109658:	00 
  109659:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  109660:	e8 03 73 ff ff       	call   100968 <debug_panic>
  109665:	e8 e1 79 ff ff       	call   10104b <mem_alloc>
  10966a:	3b 45 dc             	cmp    0xffffffdc(%ebp),%eax
  10966d:	74 24                	je     109693 <pmap_check+0x1482>
  10966f:	c7 44 24 0c 22 d6 10 	movl   $0x10d622,0xc(%esp)
  109676:	00 
  109677:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  10967e:	00 
  10967f:	c7 44 24 04 ff 02 00 	movl   $0x2ff,0x4(%esp)
  109686:	00 
  109687:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  10968e:	e8 d5 72 ff ff       	call   100968 <debug_panic>
	assert(mem_freelist == NULL);
  109693:	a1 80 ed 17 00       	mov    0x17ed80,%eax
  109698:	85 c0                	test   %eax,%eax
  10969a:	74 24                	je     1096c0 <pmap_check+0x14af>
  10969c:	c7 44 24 0c c8 d6 10 	movl   $0x10d6c8,0xc(%esp)
  1096a3:	00 
  1096a4:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  1096ab:	00 
  1096ac:	c7 44 24 04 00 03 00 	movl   $0x300,0x4(%esp)
  1096b3:	00 
  1096b4:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  1096bb:	e8 a8 72 ff ff       	call   100968 <debug_panic>
	pmap_remove(pmap_bootpdir, va+PTSIZE*3-PAGESIZE, PAGESIZE);
  1096c0:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1096c3:	05 00 f0 bf 00       	add    $0xbff000,%eax
  1096c8:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  1096cf:	00 
  1096d0:	89 44 24 04          	mov    %eax,0x4(%esp)
  1096d4:	c7 04 24 00 00 18 00 	movl   $0x180000,(%esp)
  1096db:	e8 25 d1 ff ff       	call   106805 <pmap_remove>
	assert(pi0->refcount == 0);	// pi3 might or might not also be freed
  1096e0:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  1096e3:	8b 40 04             	mov    0x4(%eax),%eax
  1096e6:	85 c0                	test   %eax,%eax
  1096e8:	74 24                	je     10970e <pmap_check+0x14fd>
  1096ea:	c7 44 24 0c a2 d6 10 	movl   $0x10d6a2,0xc(%esp)
  1096f1:	00 
  1096f2:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  1096f9:	00 
  1096fa:	c7 44 24 04 02 03 00 	movl   $0x302,0x4(%esp)
  109701:	00 
  109702:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  109709:	e8 5a 72 ff ff       	call   100968 <debug_panic>
	pmap_remove(pmap_bootpdir, va+PAGESIZE, PTSIZE*3);
  10970e:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  109711:	05 00 10 00 00       	add    $0x1000,%eax
  109716:	c7 44 24 08 00 00 c0 	movl   $0xc00000,0x8(%esp)
  10971d:	00 
  10971e:	89 44 24 04          	mov    %eax,0x4(%esp)
  109722:	c7 04 24 00 00 18 00 	movl   $0x180000,(%esp)
  109729:	e8 d7 d0 ff ff       	call   106805 <pmap_remove>
	assert(pi3->refcount == 0);
  10972e:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  109731:	8b 40 04             	mov    0x4(%eax),%eax
  109734:	85 c0                	test   %eax,%eax
  109736:	74 24                	je     10975c <pmap_check+0x154b>
  109738:	c7 44 24 0c f5 d9 10 	movl   $0x10d9f5,0xc(%esp)
  10973f:	00 
  109740:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  109747:	00 
  109748:	c7 44 24 04 04 03 00 	movl   $0x304,0x4(%esp)
  10974f:	00 
  109750:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  109757:	e8 0c 72 ff ff       	call   100968 <debug_panic>
	mem_alloc(); mem_alloc();	// collect pi0 and pi3
  10975c:	e8 ea 78 ff ff       	call   10104b <mem_alloc>
  109761:	e8 e5 78 ff ff       	call   10104b <mem_alloc>
	assert(mem_freelist == NULL);
  109766:	a1 80 ed 17 00       	mov    0x17ed80,%eax
  10976b:	85 c0                	test   %eax,%eax
  10976d:	74 24                	je     109793 <pmap_check+0x1582>
  10976f:	c7 44 24 0c c8 d6 10 	movl   $0x10d6c8,0xc(%esp)
  109776:	00 
  109777:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  10977e:	00 
  10977f:	c7 44 24 04 06 03 00 	movl   $0x306,0x4(%esp)
  109786:	00 
  109787:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  10978e:	e8 d5 71 ff ff       	call   100968 <debug_panic>

	// check pointer arithmetic in pmap_walk
	mem_free(pi0);
  109793:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  109796:	89 04 24             	mov    %eax,(%esp)
  109799:	e8 f1 78 ff ff       	call   10108f <mem_free>
	va = VM_USERLO + PAGESIZE*NPTENTRIES + PAGESIZE;
  10979e:	c7 45 f8 00 10 40 40 	movl   $0x40401000,0xfffffff8(%ebp)
	ptep = pmap_walk(pmap_bootpdir, va, 1);
  1097a5:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
  1097ac:	00 
  1097ad:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1097b0:	89 44 24 04          	mov    %eax,0x4(%esp)
  1097b4:	c7 04 24 00 00 18 00 	movl   $0x180000,(%esp)
  1097bb:	e8 0f c8 ff ff       	call   105fcf <pmap_walk>
  1097c0:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
	ptep1 = mem_ptr(PGADDR(pmap_bootpdir[PDX(va)]));
  1097c3:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1097c6:	c1 e8 16             	shr    $0x16,%eax
  1097c9:	25 ff 03 00 00       	and    $0x3ff,%eax
  1097ce:	8b 04 85 00 00 18 00 	mov    0x180000(,%eax,4),%eax
  1097d5:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1097da:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
	assert(ptep == ptep1 + PTX(va));
  1097dd:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1097e0:	c1 e8 0c             	shr    $0xc,%eax
  1097e3:	25 ff 03 00 00       	and    $0x3ff,%eax
  1097e8:	c1 e0 02             	shl    $0x2,%eax
  1097eb:	03 45 f0             	add    0xfffffff0(%ebp),%eax
  1097ee:	3b 45 ec             	cmp    0xffffffec(%ebp),%eax
  1097f1:	74 24                	je     109817 <pmap_check+0x1606>
  1097f3:	c7 44 24 0c 08 da 10 	movl   $0x10da08,0xc(%esp)
  1097fa:	00 
  1097fb:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  109802:	00 
  109803:	c7 44 24 04 0d 03 00 	movl   $0x30d,0x4(%esp)
  10980a:	00 
  10980b:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  109812:	e8 51 71 ff ff       	call   100968 <debug_panic>
	pmap_bootpdir[PDX(va)] = PTE_ZERO;
  109817:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10981a:	c1 e8 16             	shr    $0x16,%eax
  10981d:	89 c2                	mov    %eax,%edx
  10981f:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
  109825:	b8 00 10 18 00       	mov    $0x181000,%eax
  10982a:	89 04 95 00 00 18 00 	mov    %eax,0x180000(,%edx,4)
	pi0->refcount = 0;
  109831:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  109834:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)

	// check that new page tables get cleared
	memset(mem_pi2ptr(pi0), 0xFF, PAGESIZE);
  10983b:	8b 55 d8             	mov    0xffffffd8(%ebp),%edx
  10983e:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  109843:	89 d1                	mov    %edx,%ecx
  109845:	29 c1                	sub    %eax,%ecx
  109847:	89 c8                	mov    %ecx,%eax
  109849:	c1 e0 09             	shl    $0x9,%eax
  10984c:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  109853:	00 
  109854:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
  10985b:	00 
  10985c:	89 04 24             	mov    %eax,(%esp)
  10985f:	e8 91 1f 00 00       	call   10b7f5 <memset>
	mem_free(pi0);
  109864:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  109867:	89 04 24             	mov    %eax,(%esp)
  10986a:	e8 20 78 ff ff       	call   10108f <mem_free>
	pmap_walk(pmap_bootpdir, VM_USERHI-PAGESIZE, 1);
  10986f:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
  109876:	00 
  109877:	c7 44 24 04 00 f0 ff 	movl   $0xeffff000,0x4(%esp)
  10987e:	ef 
  10987f:	c7 04 24 00 00 18 00 	movl   $0x180000,(%esp)
  109886:	e8 44 c7 ff ff       	call   105fcf <pmap_walk>
	ptep = mem_pi2ptr(pi0);
  10988b:	8b 55 d8             	mov    0xffffffd8(%ebp),%edx
  10988e:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  109893:	89 d3                	mov    %edx,%ebx
  109895:	29 c3                	sub    %eax,%ebx
  109897:	89 d8                	mov    %ebx,%eax
  109899:	c1 e0 09             	shl    $0x9,%eax
  10989c:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
	for(i=0; i<NPTENTRIES; i++)
  10989f:	c7 45 f4 00 00 00 00 	movl   $0x0,0xfffffff4(%ebp)
  1098a6:	eb 3c                	jmp    1098e4 <pmap_check+0x16d3>
		assert(ptep[i] == PTE_ZERO);
  1098a8:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  1098ab:	c1 e0 02             	shl    $0x2,%eax
  1098ae:	03 45 ec             	add    0xffffffec(%ebp),%eax
  1098b1:	8b 10                	mov    (%eax),%edx
  1098b3:	b8 00 10 18 00       	mov    $0x181000,%eax
  1098b8:	39 c2                	cmp    %eax,%edx
  1098ba:	74 24                	je     1098e0 <pmap_check+0x16cf>
  1098bc:	c7 44 24 0c 20 da 10 	movl   $0x10da20,0xc(%esp)
  1098c3:	00 
  1098c4:	c7 44 24 08 9e ce 10 	movl   $0x10ce9e,0x8(%esp)
  1098cb:	00 
  1098cc:	c7 44 24 04 17 03 00 	movl   $0x317,0x4(%esp)
  1098d3:	00 
  1098d4:	c7 04 24 86 cf 10 00 	movl   $0x10cf86,(%esp)
  1098db:	e8 88 70 ff ff       	call   100968 <debug_panic>
  1098e0:	83 45 f4 01          	addl   $0x1,0xfffffff4(%ebp)
  1098e4:	81 7d f4 ff 03 00 00 	cmpl   $0x3ff,0xfffffff4(%ebp)
  1098eb:	7e bb                	jle    1098a8 <pmap_check+0x1697>
	pmap_bootpdir[PDX(VM_USERHI-PAGESIZE)] = PTE_ZERO;
  1098ed:	b8 00 10 18 00       	mov    $0x181000,%eax
  1098f2:	a3 fc 0e 18 00       	mov    %eax,0x180efc
	pi0->refcount = 0;
  1098f7:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  1098fa:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)

	// give free list back
	mem_freelist = fl;
  109901:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  109904:	a3 80 ed 17 00       	mov    %eax,0x17ed80

	// free the pages we filched
	mem_free(pi0);
  109909:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  10990c:	89 04 24             	mov    %eax,(%esp)
  10990f:	e8 7b 77 ff ff       	call   10108f <mem_free>
	mem_free(pi1);
  109914:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  109917:	89 04 24             	mov    %eax,(%esp)
  10991a:	e8 70 77 ff ff       	call   10108f <mem_free>
	mem_free(pi2);
  10991f:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  109922:	89 04 24             	mov    %eax,(%esp)
  109925:	e8 65 77 ff ff       	call   10108f <mem_free>
	mem_free(pi3);
  10992a:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  10992d:	89 04 24             	mov    %eax,(%esp)
  109930:	e8 5a 77 ff ff       	call   10108f <mem_free>

	cprintf("pmap_check() succeeded!\n");
  109935:	c7 04 24 34 da 10 00 	movl   $0x10da34,(%esp)
  10993c:	e8 30 1b 00 00       	call   10b471 <cprintf>
}
  109941:	83 c4 44             	add    $0x44,%esp
  109944:	5b                   	pop    %ebx
  109945:	5d                   	pop    %ebp
  109946:	c3                   	ret    
  109947:	90                   	nop    

00109948 <file_init>:


void
file_init(void)
{
  109948:	55                   	push   %ebp
  109949:	89 e5                	mov    %esp,%ebp
  10994b:	83 ec 18             	sub    $0x18,%esp
	if (!cpu_onboot())
  10994e:	e8 22 00 00 00       	call   109975 <cpu_onboot>
  109953:	85 c0                	test   %eax,%eax
  109955:	74 1c                	je     109973 <file_init+0x2b>
		return;

	spinlock_init(&file_lock);
  109957:	c7 44 24 08 3b 00 00 	movl   $0x3b,0x8(%esp)
  10995e:	00 
  10995f:	c7 44 24 04 74 da 10 	movl   $0x10da74,0x4(%esp)
  109966:	00 
  109967:	c7 04 24 e0 ec 17 00 	movl   $0x17ece0,(%esp)
  10996e:	e8 1d a1 ff ff       	call   103a90 <spinlock_init_>
}
  109973:	c9                   	leave  
  109974:	c3                   	ret    

00109975 <cpu_onboot>:
}

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  109975:	55                   	push   %ebp
  109976:	89 e5                	mov    %esp,%ebp
  109978:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  10997b:	e8 0d 00 00 00       	call   10998d <cpu_cur>
  109980:	3d 00 e0 10 00       	cmp    $0x10e000,%eax
  109985:	0f 94 c0             	sete   %al
  109988:	0f b6 c0             	movzbl %al,%eax
}
  10998b:	c9                   	leave  
  10998c:	c3                   	ret    

0010998d <cpu_cur>:
  10998d:	55                   	push   %ebp
  10998e:	89 e5                	mov    %esp,%ebp
  109990:	83 ec 28             	sub    $0x28,%esp
static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  109993:	89 65 fc             	mov    %esp,0xfffffffc(%ebp)
        return esp;
  109996:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  109999:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  10999c:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10999f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1099a4:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	assert(c->magic == CPU_MAGIC);
  1099a7:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  1099aa:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  1099b0:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  1099b5:	74 24                	je     1099db <cpu_cur+0x4e>
  1099b7:	c7 44 24 0c 80 da 10 	movl   $0x10da80,0xc(%esp)
  1099be:	00 
  1099bf:	c7 44 24 08 96 da 10 	movl   $0x10da96,0x8(%esp)
  1099c6:	00 
  1099c7:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  1099ce:	00 
  1099cf:	c7 04 24 ab da 10 00 	movl   $0x10daab,(%esp)
  1099d6:	e8 8d 6f ff ff       	call   100968 <debug_panic>
	return c;
  1099db:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
}
  1099de:	c9                   	leave  
  1099df:	c3                   	ret    

001099e0 <file_initroot>:

void
file_initroot(proc *root)
{
  1099e0:	55                   	push   %ebp
  1099e1:	89 e5                	mov    %esp,%ebp
  1099e3:	83 ec 48             	sub    $0x48,%esp
	// Only one root process may perform external I/O directly -
	// all other processes do I/O indirectly via the process hierarchy.
	assert(root == proc_root);
  1099e6:	a1 b0 f4 17 00       	mov    0x17f4b0,%eax
  1099eb:	39 45 08             	cmp    %eax,0x8(%ebp)
  1099ee:	74 24                	je     109a14 <file_initroot+0x34>
  1099f0:	c7 44 24 0c b8 da 10 	movl   $0x10dab8,0xc(%esp)
  1099f7:	00 
  1099f8:	c7 44 24 08 96 da 10 	movl   $0x10da96,0x8(%esp)
  1099ff:	00 
  109a00:	c7 44 24 04 43 00 00 	movl   $0x43,0x4(%esp)
  109a07:	00 
  109a08:	c7 04 24 74 da 10 00 	movl   $0x10da74,(%esp)
  109a0f:	e8 54 6f ff ff       	call   100968 <debug_panic>

	// Make sure the root process's page directory is loaded,
	// so that we can write into the root process's file area directly.
	cpu_cur()->proc = root;
  109a14:	e8 74 ff ff ff       	call   10998d <cpu_cur>
  109a19:	89 c2                	mov    %eax,%edx
  109a1b:	8b 45 08             	mov    0x8(%ebp),%eax
  109a1e:	89 82 b4 00 00 00    	mov    %eax,0xb4(%edx)
	lcr3(mem_phys(root->pdir));
  109a24:	8b 45 08             	mov    0x8(%ebp),%eax
  109a27:	8b 80 a0 06 00 00    	mov    0x6a0(%eax),%eax
  109a2d:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)

static gcc_inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
  109a30:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  109a33:	0f 22 d8             	mov    %eax,%cr3

	// Enable read/write access on the file metadata area
	pmap_setperm(root->pdir, FILESVA, ROUNDUP(sizeof(filestate), PAGESIZE),
  109a36:	c7 45 e8 00 10 00 00 	movl   $0x1000,0xffffffe8(%ebp)
  109a3d:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  109a40:	05 0f 70 00 00       	add    $0x700f,%eax
  109a45:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  109a48:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  109a4b:	ba 00 00 00 00       	mov    $0x0,%edx
  109a50:	f7 75 e8             	divl   0xffffffe8(%ebp)
  109a53:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  109a56:	29 d0                	sub    %edx,%eax
  109a58:	89 c2                	mov    %eax,%edx
  109a5a:	8b 45 08             	mov    0x8(%ebp),%eax
  109a5d:	8b 80 a0 06 00 00    	mov    0x6a0(%eax),%eax
  109a63:	c7 44 24 0c 00 06 00 	movl   $0x600,0xc(%esp)
  109a6a:	00 
  109a6b:	89 54 24 08          	mov    %edx,0x8(%esp)
  109a6f:	c7 44 24 04 00 00 00 	movl   $0x80000000,0x4(%esp)
  109a76:	80 
  109a77:	89 04 24             	mov    %eax,(%esp)
  109a7a:	e8 f9 e4 ff ff       	call   107f78 <pmap_setperm>
				SYS_READ | SYS_WRITE);
	memset(files, 0, sizeof(*files));
  109a7f:	a1 70 da 10 00       	mov    0x10da70,%eax
  109a84:	c7 44 24 08 10 70 00 	movl   $0x7010,0x8(%esp)
  109a8b:	00 
  109a8c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  109a93:	00 
  109a94:	89 04 24             	mov    %eax,(%esp)
  109a97:	e8 59 1d 00 00       	call   10b7f5 <memset>

	// Set up the standard I/O descriptors for console I/O
	files->fd[0].ino = FILEINO_CONSIN;
  109a9c:	a1 70 da 10 00       	mov    0x10da70,%eax
  109aa1:	c7 40 10 01 00 00 00 	movl   $0x1,0x10(%eax)
	files->fd[0].flags = O_RDONLY;
  109aa8:	a1 70 da 10 00       	mov    0x10da70,%eax
  109aad:	c7 40 14 01 00 00 00 	movl   $0x1,0x14(%eax)
	files->fd[1].ino = FILEINO_CONSOUT;
  109ab4:	a1 70 da 10 00       	mov    0x10da70,%eax
  109ab9:	c7 40 20 02 00 00 00 	movl   $0x2,0x20(%eax)
	files->fd[1].flags = O_WRONLY | O_APPEND;
  109ac0:	a1 70 da 10 00       	mov    0x10da70,%eax
  109ac5:	c7 40 24 12 00 00 00 	movl   $0x12,0x24(%eax)
	files->fd[2].ino = FILEINO_CONSOUT;
  109acc:	a1 70 da 10 00       	mov    0x10da70,%eax
  109ad1:	c7 40 30 02 00 00 00 	movl   $0x2,0x30(%eax)
	files->fd[2].flags = O_WRONLY | O_APPEND;
  109ad8:	a1 70 da 10 00       	mov    0x10da70,%eax
  109add:	c7 40 34 12 00 00 00 	movl   $0x12,0x34(%eax)

	// Setup the inodes for the console I/O files and root directory
	strcpy(files->fi[FILEINO_CONSIN].de.d_name, "consin");
  109ae4:	a1 70 da 10 00       	mov    0x10da70,%eax
  109ae9:	05 70 10 00 00       	add    $0x1070,%eax
  109aee:	c7 44 24 04 ca da 10 	movl   $0x10daca,0x4(%esp)
  109af5:	00 
  109af6:	89 04 24             	mov    %eax,(%esp)
  109af9:	e8 50 1b 00 00       	call   10b64e <strcpy>
	strcpy(files->fi[FILEINO_CONSOUT].de.d_name, "consout");
  109afe:	a1 70 da 10 00       	mov    0x10da70,%eax
  109b03:	05 cc 10 00 00       	add    $0x10cc,%eax
  109b08:	c7 44 24 04 d1 da 10 	movl   $0x10dad1,0x4(%esp)
  109b0f:	00 
  109b10:	89 04 24             	mov    %eax,(%esp)
  109b13:	e8 36 1b 00 00       	call   10b64e <strcpy>
	strcpy(files->fi[FILEINO_ROOTDIR].de.d_name, "/");
  109b18:	a1 70 da 10 00       	mov    0x10da70,%eax
  109b1d:	05 28 11 00 00       	add    $0x1128,%eax
  109b22:	c7 44 24 04 d9 da 10 	movl   $0x10dad9,0x4(%esp)
  109b29:	00 
  109b2a:	89 04 24             	mov    %eax,(%esp)
  109b2d:	e8 1c 1b 00 00       	call   10b64e <strcpy>
	files->fi[FILEINO_CONSIN].dino = FILEINO_ROOTDIR;
  109b32:	a1 70 da 10 00       	mov    0x10da70,%eax
  109b37:	c7 80 6c 10 00 00 03 	movl   $0x3,0x106c(%eax)
  109b3e:	00 00 00 
	files->fi[FILEINO_CONSOUT].dino = FILEINO_ROOTDIR;
  109b41:	a1 70 da 10 00       	mov    0x10da70,%eax
  109b46:	c7 80 c8 10 00 00 03 	movl   $0x3,0x10c8(%eax)
  109b4d:	00 00 00 
	files->fi[FILEINO_ROOTDIR].dino = FILEINO_ROOTDIR;
  109b50:	a1 70 da 10 00       	mov    0x10da70,%eax
  109b55:	c7 80 24 11 00 00 03 	movl   $0x3,0x1124(%eax)
  109b5c:	00 00 00 
	files->fi[FILEINO_CONSIN].mode = S_IFREG | S_IFPART;
  109b5f:	a1 70 da 10 00       	mov    0x10da70,%eax
  109b64:	c7 80 b4 10 00 00 00 	movl   $0x9000,0x10b4(%eax)
  109b6b:	90 00 00 
	files->fi[FILEINO_CONSOUT].mode = S_IFREG;
  109b6e:	a1 70 da 10 00       	mov    0x10da70,%eax
  109b73:	c7 80 10 11 00 00 00 	movl   $0x1000,0x1110(%eax)
  109b7a:	10 00 00 
	files->fi[FILEINO_ROOTDIR].mode = S_IFDIR;
  109b7d:	a1 70 da 10 00       	mov    0x10da70,%eax
  109b82:	c7 80 6c 11 00 00 00 	movl   $0x2000,0x116c(%eax)
  109b89:	20 00 00 

	// Set the whole console input area to be read/write,
	// so we won't have to worry about perms in cons_io().
	pmap_setperm(root->pdir, (uintptr_t)FILEDATA(FILEINO_CONSIN),
  109b8c:	8b 45 08             	mov    0x8(%ebp),%eax
  109b8f:	8b 80 a0 06 00 00    	mov    0x6a0(%eax),%eax
  109b95:	c7 44 24 0c 00 06 00 	movl   $0x600,0xc(%esp)
  109b9c:	00 
  109b9d:	c7 44 24 08 00 00 40 	movl   $0x400000,0x8(%esp)
  109ba4:	00 
  109ba5:	c7 44 24 04 00 00 40 	movl   $0x80400000,0x4(%esp)
  109bac:	80 
  109bad:	89 04 24             	mov    %eax,(%esp)
  109bb0:	e8 c3 e3 ff ff       	call   107f78 <pmap_setperm>
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
  109bb5:	c7 45 dc 07 00 00 00 	movl   $0x7,0xffffffdc(%ebp)
	// Lab 4: your file system initialization code here.
	int i;
	int ino = FILEINO_GENERAL;
  109bbc:	c7 45 e4 04 00 00 00 	movl   $0x4,0xffffffe4(%ebp)
	for (i = 0; i < ninitfiles; i++) {
  109bc3:	c7 45 e0 00 00 00 00 	movl   $0x0,0xffffffe0(%ebp)
  109bca:	e9 39 01 00 00       	jmp    109d08 <file_initroot+0x328>
		int filesize = initfiles[i][2] - initfiles[i][1];
  109bcf:	8b 55 e0             	mov    0xffffffe0(%ebp),%edx
  109bd2:	89 d0                	mov    %edx,%eax
  109bd4:	01 c0                	add    %eax,%eax
  109bd6:	01 d0                	add    %edx,%eax
  109bd8:	c1 e0 02             	shl    $0x2,%eax
  109bdb:	8b 80 28 f0 10 00    	mov    0x10f028(%eax),%eax
  109be1:	89 c1                	mov    %eax,%ecx
  109be3:	8b 55 e0             	mov    0xffffffe0(%ebp),%edx
  109be6:	89 d0                	mov    %edx,%eax
  109be8:	01 c0                	add    %eax,%eax
  109bea:	01 d0                	add    %edx,%eax
  109bec:	c1 e0 02             	shl    $0x2,%eax
  109bef:	8b 80 24 f0 10 00    	mov    0x10f024(%eax),%eax
  109bf5:	89 ca                	mov    %ecx,%edx
  109bf7:	29 c2                	sub    %eax,%edx
  109bf9:	89 d0                	mov    %edx,%eax
  109bfb:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
		strcpy(files->fi[ino].de.d_name, initfiles[i][0]);
  109bfe:	8b 55 e0             	mov    0xffffffe0(%ebp),%edx
  109c01:	89 d0                	mov    %edx,%eax
  109c03:	01 c0                	add    %eax,%eax
  109c05:	01 d0                	add    %edx,%eax
  109c07:	c1 e0 02             	shl    $0x2,%eax
  109c0a:	8b 88 20 f0 10 00    	mov    0x10f020(%eax),%ecx
  109c10:	8b 15 70 da 10 00    	mov    0x10da70,%edx
  109c16:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  109c19:	6b c0 5c             	imul   $0x5c,%eax,%eax
  109c1c:	05 10 10 00 00       	add    $0x1010,%eax
  109c21:	8d 04 02             	lea    (%edx,%eax,1),%eax
  109c24:	83 c0 04             	add    $0x4,%eax
  109c27:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  109c2b:	89 04 24             	mov    %eax,(%esp)
  109c2e:	e8 1b 1a 00 00       	call   10b64e <strcpy>
		files->fi[ino].size = filesize;
  109c33:	8b 15 70 da 10 00    	mov    0x10da70,%edx
  109c39:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  109c3c:	8b 4d f0             	mov    0xfffffff0(%ebp),%ecx
  109c3f:	6b c0 5c             	imul   $0x5c,%eax,%eax
  109c42:	01 d0                	add    %edx,%eax
  109c44:	05 5c 10 00 00       	add    $0x105c,%eax
  109c49:	89 08                	mov    %ecx,(%eax)
		files->fi[ino].mode = S_IFREG;
  109c4b:	8b 15 70 da 10 00    	mov    0x10da70,%edx
  109c51:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  109c54:	6b c0 5c             	imul   $0x5c,%eax,%eax
  109c57:	01 d0                	add    %edx,%eax
  109c59:	05 58 10 00 00       	add    $0x1058,%eax
  109c5e:	c7 00 00 10 00 00    	movl   $0x1000,(%eax)
		files->fi[ino].dino = FILEINO_ROOTDIR;
  109c64:	8b 15 70 da 10 00    	mov    0x10da70,%edx
  109c6a:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  109c6d:	6b c0 5c             	imul   $0x5c,%eax,%eax
  109c70:	01 d0                	add    %edx,%eax
  109c72:	05 10 10 00 00       	add    $0x1010,%eax
  109c77:	c7 00 03 00 00 00    	movl   $0x3,(%eax)
		pmap_setperm(root->pdir, (uintptr_t)FILEDATA(ino),
					ROUNDUP(filesize, PAGESIZE),
  109c7d:	c7 45 f4 00 10 00 00 	movl   $0x1000,0xfffffff4(%ebp)
  109c84:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  109c87:	03 45 f4             	add    0xfffffff4(%ebp),%eax
  109c8a:	83 e8 01             	sub    $0x1,%eax
  109c8d:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  109c90:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  109c93:	ba 00 00 00 00       	mov    $0x0,%edx
  109c98:	f7 75 f4             	divl   0xfffffff4(%ebp)
  109c9b:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  109c9e:	29 d0                	sub    %edx,%eax
  109ca0:	89 c1                	mov    %eax,%ecx
  109ca2:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  109ca5:	c1 e0 16             	shl    $0x16,%eax
  109ca8:	2d 00 00 00 80       	sub    $0x80000000,%eax
  109cad:	89 c2                	mov    %eax,%edx
  109caf:	8b 45 08             	mov    0x8(%ebp),%eax
  109cb2:	8b 80 a0 06 00 00    	mov    0x6a0(%eax),%eax
  109cb8:	c7 44 24 0c 00 06 00 	movl   $0x600,0xc(%esp)
  109cbf:	00 
  109cc0:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  109cc4:	89 54 24 04          	mov    %edx,0x4(%esp)
  109cc8:	89 04 24             	mov    %eax,(%esp)
  109ccb:	e8 a8 e2 ff ff       	call   107f78 <pmap_setperm>
					SYS_READ | SYS_WRITE);
		memcpy(FILEDATA(ino), initfiles[i][1], filesize);
  109cd0:	8b 4d f0             	mov    0xfffffff0(%ebp),%ecx
  109cd3:	8b 55 e0             	mov    0xffffffe0(%ebp),%edx
  109cd6:	89 d0                	mov    %edx,%eax
  109cd8:	01 c0                	add    %eax,%eax
  109cda:	01 d0                	add    %edx,%eax
  109cdc:	c1 e0 02             	shl    $0x2,%eax
  109cdf:	8b 90 24 f0 10 00    	mov    0x10f024(%eax),%edx
  109ce5:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  109ce8:	c1 e0 16             	shl    $0x16,%eax
  109ceb:	2d 00 00 00 80       	sub    $0x80000000,%eax
  109cf0:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  109cf4:	89 54 24 04          	mov    %edx,0x4(%esp)
  109cf8:	89 04 24             	mov    %eax,(%esp)
  109cfb:	e8 34 1c 00 00       	call   10b934 <memcpy>
		ino++;
  109d00:	83 45 e4 01          	addl   $0x1,0xffffffe4(%ebp)
  109d04:	83 45 e0 01          	addl   $0x1,0xffffffe0(%ebp)
  109d08:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  109d0b:	3b 45 dc             	cmp    0xffffffdc(%ebp),%eax
  109d0e:	0f 8c bb fe ff ff    	jl     109bcf <file_initroot+0x1ef>
	}

	// Set root process's current working directory
	files->cwd = FILEINO_ROOTDIR;
  109d14:	a1 70 da 10 00       	mov    0x10da70,%eax
  109d19:	c7 40 04 03 00 00 00 	movl   $0x3,0x4(%eax)

	// Child process state - reserve PID 0 as a "scratch" child process.
	files->child[0].state = PROC_RESERVED;
  109d20:	a1 70 da 10 00       	mov    0x10da70,%eax
  109d25:	c7 80 10 6c 00 00 ff 	movl   $0xffffffff,0x6c10(%eax)
  109d2c:	ff ff ff 
}
  109d2f:	c9                   	leave  
  109d30:	c3                   	ret    

00109d31 <file_io>:

// Called from proc_ret() when the root process "returns" -
// this function performs any new output the root process requested,
// or if it didn't request output, puts the root process to sleep
// waiting for input to arrive from some I/O device.
void
file_io(trapframe *tf)
{
  109d31:	55                   	push   %ebp
  109d32:	89 e5                	mov    %esp,%ebp
  109d34:	83 ec 28             	sub    $0x28,%esp
	proc *cp = proc_cur();
  109d37:	e8 51 fc ff ff       	call   10998d <cpu_cur>
  109d3c:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  109d42:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
	assert(cp == proc_root);	// only root process should do this!
  109d45:	a1 b0 f4 17 00       	mov    0x17f4b0,%eax
  109d4a:	39 45 f8             	cmp    %eax,0xfffffff8(%ebp)
  109d4d:	74 24                	je     109d73 <file_io+0x42>
  109d4f:	c7 44 24 0c db da 10 	movl   $0x10dadb,0xc(%esp)
  109d56:	00 
  109d57:	c7 44 24 08 96 da 10 	movl   $0x10da96,0x8(%esp)
  109d5e:	00 
  109d5f:	c7 44 24 04 8f 00 00 	movl   $0x8f,0x4(%esp)
  109d66:	00 
  109d67:	c7 04 24 74 da 10 00 	movl   $0x10da74,(%esp)
  109d6e:	e8 f5 6b ff ff       	call   100968 <debug_panic>

	// Note that we don't need to bother protecting ourselves
	// against memory access traps while accessing user memory here,
	// because we consider the root process a special, "trusted" process:
	// the whole system goes down anyway if the root process goes haywire.
	// This is very different from handling system calls
	// on behalf of arbitrary processes that might be buggy or evil.

	// Perform I/O with whatever devices we have access to.
	bool iodone = 0;
  109d73:	c7 45 fc 00 00 00 00 	movl   $0x0,0xfffffffc(%ebp)
	iodone |= cons_io();
  109d7a:	e8 52 6a ff ff       	call   1007d1 <cons_io>
  109d7f:	09 45 fc             	or     %eax,0xfffffffc(%ebp)

	// Has the root process exited?
	if (files->exited) {
  109d82:	a1 70 da 10 00       	mov    0x10da70,%eax
  109d87:	8b 40 08             	mov    0x8(%eax),%eax
  109d8a:	85 c0                	test   %eax,%eax
  109d8c:	74 1d                	je     109dab <file_io+0x7a>
		cprintf("root process exited with status %d\n", files->status);
  109d8e:	a1 70 da 10 00       	mov    0x10da70,%eax
  109d93:	8b 40 0c             	mov    0xc(%eax),%eax
  109d96:	89 44 24 04          	mov    %eax,0x4(%esp)
  109d9a:	c7 04 24 ec da 10 00 	movl   $0x10daec,(%esp)
  109da1:	e8 cb 16 00 00       	call   10b471 <cprintf>
		done();
  109da6:	e8 c9 67 ff ff       	call   100574 <done>
	}

	// We successfully did some I/O, let the root process run again.
	if (iodone)
  109dab:	83 7d fc 00          	cmpl   $0x0,0xfffffffc(%ebp)
  109daf:	74 0b                	je     109dbc <file_io+0x8b>
		trap_return(tf);
  109db1:	8b 45 08             	mov    0x8(%ebp),%eax
  109db4:	89 04 24             	mov    %eax,(%esp)
  109db7:	e8 a4 98 ff ff       	call   103660 <trap_return>

	// No I/O ready - put the root process to sleep waiting for I/O.
	spinlock_acquire(&file_lock);
  109dbc:	c7 04 24 e0 ec 17 00 	movl   $0x17ece0,(%esp)
  109dc3:	e8 f2 9c ff ff       	call   103aba <spinlock_acquire>
	cp->state = PROC_STOP;		// we're becoming stopped
  109dc8:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  109dcb:	c7 80 3c 04 00 00 00 	movl   $0x0,0x43c(%eax)
  109dd2:	00 00 00 
	cp->runcpu = NULL;		// no longer running
  109dd5:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  109dd8:	c7 80 44 04 00 00 00 	movl   $0x0,0x444(%eax)
  109ddf:	00 00 00 
	proc_save(cp, tf, 1);		// save process's state
  109de2:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
  109de9:	00 
  109dea:	8b 45 08             	mov    0x8(%ebp),%eax
  109ded:	89 44 24 04          	mov    %eax,0x4(%esp)
  109df1:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  109df4:	89 04 24             	mov    %eax,(%esp)
  109df7:	e8 6e a6 ff ff       	call   10446a <proc_save>
	spinlock_release(&file_lock);
  109dfc:	c7 04 24 e0 ec 17 00 	movl   $0x17ece0,(%esp)
  109e03:	e8 ad 9d ff ff       	call   103bb5 <spinlock_release>

	proc_sched();			// go do something else
  109e08:	e8 cf a7 ff ff       	call   1045dc <proc_sched>

00109e0d <file_wakeroot>:
}

// Check to see if any input is available for the root process
// and if the root process is waiting for it, and if so, wake the process.
void
file_wakeroot(void)
{
  109e0d:	55                   	push   %ebp
  109e0e:	89 e5                	mov    %esp,%ebp
  109e10:	83 ec 08             	sub    $0x8,%esp
	spinlock_acquire(&file_lock);
  109e13:	c7 04 24 e0 ec 17 00 	movl   $0x17ece0,(%esp)
  109e1a:	e8 9b 9c ff ff       	call   103aba <spinlock_acquire>
	if (proc_root && proc_root->state == PROC_STOP)
  109e1f:	a1 b0 f4 17 00       	mov    0x17f4b0,%eax
  109e24:	85 c0                	test   %eax,%eax
  109e26:	74 1c                	je     109e44 <file_wakeroot+0x37>
  109e28:	a1 b0 f4 17 00       	mov    0x17f4b0,%eax
  109e2d:	8b 80 3c 04 00 00    	mov    0x43c(%eax),%eax
  109e33:	85 c0                	test   %eax,%eax
  109e35:	75 0d                	jne    109e44 <file_wakeroot+0x37>
		proc_ready(proc_root);
  109e37:	a1 b0 f4 17 00       	mov    0x17f4b0,%eax
  109e3c:	89 04 24             	mov    %eax,(%esp)
  109e3f:	e8 d4 a5 ff ff       	call   104418 <proc_ready>
	spinlock_release(&file_lock);
  109e44:	c7 04 24 e0 ec 17 00 	movl   $0x17ece0,(%esp)
  109e4b:	e8 65 9d ff ff       	call   103bb5 <spinlock_release>
}
  109e50:	c9                   	leave  
  109e51:	c3                   	ret    
  109e52:	90                   	nop    
  109e53:	90                   	nop    

00109e54 <video_init>:
static uint16_t crt_pos;

void
video_init(void)
{
  109e54:	55                   	push   %ebp
  109e55:	89 e5                	mov    %esp,%ebp
  109e57:	83 ec 30             	sub    $0x30,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	/* Get a pointer to the memory-mapped text display buffer. */
	cp = (uint16_t*) mem_ptr(CGA_BUF);
  109e5a:	c7 45 d4 00 80 0b 00 	movl   $0xb8000,0xffffffd4(%ebp)
	was = *cp;
  109e61:	8b 45 d4             	mov    0xffffffd4(%ebp),%eax
  109e64:	0f b7 00             	movzwl (%eax),%eax
  109e67:	66 89 45 da          	mov    %ax,0xffffffda(%ebp)
	*cp = (uint16_t) 0xA55A;
  109e6b:	8b 45 d4             	mov    0xffffffd4(%ebp),%eax
  109e6e:	66 c7 00 5a a5       	movw   $0xa55a,(%eax)
	if (*cp != 0xA55A) {
  109e73:	8b 45 d4             	mov    0xffffffd4(%ebp),%eax
  109e76:	0f b7 00             	movzwl (%eax),%eax
  109e79:	66 3d 5a a5          	cmp    $0xa55a,%ax
  109e7d:	74 13                	je     109e92 <video_init+0x3e>
		cp = (uint16_t*) mem_ptr(MONO_BUF);
  109e7f:	c7 45 d4 00 00 0b 00 	movl   $0xb0000,0xffffffd4(%ebp)
		addr_6845 = MONO_BASE;
  109e86:	c7 05 1c ed 17 00 b4 	movl   $0x3b4,0x17ed1c
  109e8d:	03 00 00 
  109e90:	eb 14                	jmp    109ea6 <video_init+0x52>
	} else {
		*cp = was;
  109e92:	8b 55 d4             	mov    0xffffffd4(%ebp),%edx
  109e95:	0f b7 45 da          	movzwl 0xffffffda(%ebp),%eax
  109e99:	66 89 02             	mov    %ax,(%edx)
		addr_6845 = CGA_BASE;
  109e9c:	c7 05 1c ed 17 00 d4 	movl   $0x3d4,0x17ed1c
  109ea3:	03 00 00 
	}
	
	/* Extract cursor location */
	outb(addr_6845, 14);
  109ea6:	a1 1c ed 17 00       	mov    0x17ed1c,%eax
  109eab:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
  109eae:	c6 45 e3 0e          	movb   $0xe,0xffffffe3(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  109eb2:	0f b6 45 e3          	movzbl 0xffffffe3(%ebp),%eax
  109eb6:	8b 55 e4             	mov    0xffffffe4(%ebp),%edx
  109eb9:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
  109eba:	a1 1c ed 17 00       	mov    0x17ed1c,%eax
  109ebf:	83 c0 01             	add    $0x1,%eax
  109ec2:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  109ec5:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
  109ec8:	ec                   	in     (%dx),%al
  109ec9:	88 45 eb             	mov    %al,0xffffffeb(%ebp)
	return data;
  109ecc:	0f b6 45 eb          	movzbl 0xffffffeb(%ebp),%eax
  109ed0:	0f b6 c0             	movzbl %al,%eax
  109ed3:	c1 e0 08             	shl    $0x8,%eax
  109ed6:	89 45 dc             	mov    %eax,0xffffffdc(%ebp)
	outb(addr_6845, 15);
  109ed9:	a1 1c ed 17 00       	mov    0x17ed1c,%eax
  109ede:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
  109ee1:	c6 45 f3 0f          	movb   $0xf,0xfffffff3(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  109ee5:	0f b6 45 f3          	movzbl 0xfffffff3(%ebp),%eax
  109ee9:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  109eec:	ee                   	out    %al,(%dx)
	pos |= inb(addr_6845 + 1);
  109eed:	a1 1c ed 17 00       	mov    0x17ed1c,%eax
  109ef2:	83 c0 01             	add    $0x1,%eax
  109ef5:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  109ef8:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  109efb:	ec                   	in     (%dx),%al
  109efc:	88 45 fb             	mov    %al,0xfffffffb(%ebp)
	return data;
  109eff:	0f b6 45 fb          	movzbl 0xfffffffb(%ebp),%eax
  109f03:	0f b6 c0             	movzbl %al,%eax
  109f06:	09 45 dc             	or     %eax,0xffffffdc(%ebp)

	crt_buf = (uint16_t*) cp;
  109f09:	8b 45 d4             	mov    0xffffffd4(%ebp),%eax
  109f0c:	a3 20 ed 17 00       	mov    %eax,0x17ed20
	crt_pos = pos;
  109f11:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  109f14:	66 a3 24 ed 17 00    	mov    %ax,0x17ed24
}
  109f1a:	c9                   	leave  
  109f1b:	c3                   	ret    

00109f1c <video_putc>:



void
video_putc(int c)
{
  109f1c:	55                   	push   %ebp
  109f1d:	89 e5                	mov    %esp,%ebp
  109f1f:	53                   	push   %ebx
  109f20:	83 ec 44             	sub    $0x44,%esp
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
  109f23:	8b 45 08             	mov    0x8(%ebp),%eax
  109f26:	b0 00                	mov    $0x0,%al
  109f28:	85 c0                	test   %eax,%eax
  109f2a:	75 07                	jne    109f33 <video_putc+0x17>
		c |= 0x0700;
  109f2c:	81 4d 08 00 07 00 00 	orl    $0x700,0x8(%ebp)

	switch (c & 0xff) {
  109f33:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
  109f37:	89 45 c4             	mov    %eax,0xffffffc4(%ebp)
  109f3a:	83 7d c4 09          	cmpl   $0x9,0xffffffc4(%ebp)
  109f3e:	0f 84 c0 00 00 00    	je     10a004 <video_putc+0xe8>
  109f44:	83 7d c4 09          	cmpl   $0x9,0xffffffc4(%ebp)
  109f48:	7f 0b                	jg     109f55 <video_putc+0x39>
  109f4a:	83 7d c4 08          	cmpl   $0x8,0xffffffc4(%ebp)
  109f4e:	74 16                	je     109f66 <video_putc+0x4a>
  109f50:	e9 ed 00 00 00       	jmp    10a042 <video_putc+0x126>
  109f55:	83 7d c4 0a          	cmpl   $0xa,0xffffffc4(%ebp)
  109f59:	74 50                	je     109fab <video_putc+0x8f>
  109f5b:	83 7d c4 0d          	cmpl   $0xd,0xffffffc4(%ebp)
  109f5f:	74 5a                	je     109fbb <video_putc+0x9f>
  109f61:	e9 dc 00 00 00       	jmp    10a042 <video_putc+0x126>
	case '\b':
		if (crt_pos > 0) {
  109f66:	0f b7 05 24 ed 17 00 	movzwl 0x17ed24,%eax
  109f6d:	66 85 c0             	test   %ax,%ax
  109f70:	0f 84 f0 00 00 00    	je     10a066 <video_putc+0x14a>
			crt_pos--;
  109f76:	0f b7 05 24 ed 17 00 	movzwl 0x17ed24,%eax
  109f7d:	83 e8 01             	sub    $0x1,%eax
  109f80:	66 a3 24 ed 17 00    	mov    %ax,0x17ed24
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
  109f86:	0f b7 05 24 ed 17 00 	movzwl 0x17ed24,%eax
  109f8d:	0f b7 c0             	movzwl %ax,%eax
  109f90:	01 c0                	add    %eax,%eax
  109f92:	89 c2                	mov    %eax,%edx
  109f94:	a1 20 ed 17 00       	mov    0x17ed20,%eax
  109f99:	01 c2                	add    %eax,%edx
  109f9b:	8b 45 08             	mov    0x8(%ebp),%eax
  109f9e:	b0 00                	mov    $0x0,%al
  109fa0:	83 c8 20             	or     $0x20,%eax
  109fa3:	66 89 02             	mov    %ax,(%edx)
		}
		break;
  109fa6:	e9 bb 00 00 00       	jmp    10a066 <video_putc+0x14a>
	case '\n':
		crt_pos += CRT_COLS;
  109fab:	0f b7 05 24 ed 17 00 	movzwl 0x17ed24,%eax
  109fb2:	83 c0 50             	add    $0x50,%eax
  109fb5:	66 a3 24 ed 17 00    	mov    %ax,0x17ed24
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
  109fbb:	0f b7 0d 24 ed 17 00 	movzwl 0x17ed24,%ecx
  109fc2:	0f b7 15 24 ed 17 00 	movzwl 0x17ed24,%edx
  109fc9:	0f b7 c2             	movzwl %dx,%eax
  109fcc:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
  109fd2:	c1 e8 10             	shr    $0x10,%eax
  109fd5:	89 c3                	mov    %eax,%ebx
  109fd7:	66 c1 eb 06          	shr    $0x6,%bx
  109fdb:	66 89 5d ca          	mov    %bx,0xffffffca(%ebp)
  109fdf:	0f b7 45 ca          	movzwl 0xffffffca(%ebp),%eax
  109fe3:	c1 e0 02             	shl    $0x2,%eax
  109fe6:	66 03 45 ca          	add    0xffffffca(%ebp),%ax
  109fea:	c1 e0 04             	shl    $0x4,%eax
  109fed:	89 d3                	mov    %edx,%ebx
  109fef:	66 29 c3             	sub    %ax,%bx
  109ff2:	66 89 5d ca          	mov    %bx,0xffffffca(%ebp)
  109ff6:	89 c8                	mov    %ecx,%eax
  109ff8:	66 2b 45 ca          	sub    0xffffffca(%ebp),%ax
  109ffc:	66 a3 24 ed 17 00    	mov    %ax,0x17ed24
		break;
  10a002:	eb 62                	jmp    10a066 <video_putc+0x14a>
	case '\t':
		video_putc(' ');
  10a004:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  10a00b:	e8 0c ff ff ff       	call   109f1c <video_putc>
		video_putc(' ');
  10a010:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  10a017:	e8 00 ff ff ff       	call   109f1c <video_putc>
		video_putc(' ');
  10a01c:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  10a023:	e8 f4 fe ff ff       	call   109f1c <video_putc>
		video_putc(' ');
  10a028:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  10a02f:	e8 e8 fe ff ff       	call   109f1c <video_putc>
		video_putc(' ');
  10a034:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  10a03b:	e8 dc fe ff ff       	call   109f1c <video_putc>
		break;
  10a040:	eb 24                	jmp    10a066 <video_putc+0x14a>
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
  10a042:	0f b7 0d 24 ed 17 00 	movzwl 0x17ed24,%ecx
  10a049:	0f b7 c1             	movzwl %cx,%eax
  10a04c:	01 c0                	add    %eax,%eax
  10a04e:	89 c2                	mov    %eax,%edx
  10a050:	a1 20 ed 17 00       	mov    0x17ed20,%eax
  10a055:	01 c2                	add    %eax,%edx
  10a057:	8b 45 08             	mov    0x8(%ebp),%eax
  10a05a:	66 89 02             	mov    %ax,(%edx)
  10a05d:	8d 41 01             	lea    0x1(%ecx),%eax
  10a060:	66 a3 24 ed 17 00    	mov    %ax,0x17ed24
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
  10a066:	0f b7 05 24 ed 17 00 	movzwl 0x17ed24,%eax
  10a06d:	66 3d cf 07          	cmp    $0x7cf,%ax
  10a071:	76 5e                	jbe    10a0d1 <video_putc+0x1b5>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS,
  10a073:	a1 20 ed 17 00       	mov    0x17ed20,%eax
  10a078:	05 a0 00 00 00       	add    $0xa0,%eax
  10a07d:	8b 15 20 ed 17 00    	mov    0x17ed20,%edx
  10a083:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
  10a08a:	00 
  10a08b:	89 44 24 04          	mov    %eax,0x4(%esp)
  10a08f:	89 14 24             	mov    %edx,(%esp)
  10a092:	e8 d7 17 00 00       	call   10b86e <memmove>
			(CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
  10a097:	c7 45 d8 80 07 00 00 	movl   $0x780,0xffffffd8(%ebp)
  10a09e:	eb 18                	jmp    10a0b8 <video_putc+0x19c>
			crt_buf[i] = 0x0700 | ' ';
  10a0a0:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  10a0a3:	01 c0                	add    %eax,%eax
  10a0a5:	89 c2                	mov    %eax,%edx
  10a0a7:	a1 20 ed 17 00       	mov    0x17ed20,%eax
  10a0ac:	8d 04 02             	lea    (%edx,%eax,1),%eax
  10a0af:	66 c7 00 20 07       	movw   $0x720,(%eax)
  10a0b4:	83 45 d8 01          	addl   $0x1,0xffffffd8(%ebp)
  10a0b8:	81 7d d8 cf 07 00 00 	cmpl   $0x7cf,0xffffffd8(%ebp)
  10a0bf:	7e df                	jle    10a0a0 <video_putc+0x184>
		crt_pos -= CRT_COLS;
  10a0c1:	0f b7 05 24 ed 17 00 	movzwl 0x17ed24,%eax
  10a0c8:	83 e8 50             	sub    $0x50,%eax
  10a0cb:	66 a3 24 ed 17 00    	mov    %ax,0x17ed24
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
  10a0d1:	a1 1c ed 17 00       	mov    0x17ed1c,%eax
  10a0d6:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)
  10a0d9:	c6 45 df 0e          	movb   $0xe,0xffffffdf(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  10a0dd:	0f b6 45 df          	movzbl 0xffffffdf(%ebp),%eax
  10a0e1:	8b 55 e0             	mov    0xffffffe0(%ebp),%edx
  10a0e4:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
  10a0e5:	0f b7 05 24 ed 17 00 	movzwl 0x17ed24,%eax
  10a0ec:	66 c1 e8 08          	shr    $0x8,%ax
  10a0f0:	0f b6 d0             	movzbl %al,%edx
  10a0f3:	a1 1c ed 17 00       	mov    0x17ed1c,%eax
  10a0f8:	83 c0 01             	add    $0x1,%eax
  10a0fb:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  10a0fe:	88 55 e7             	mov    %dl,0xffffffe7(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  10a101:	0f b6 45 e7          	movzbl 0xffffffe7(%ebp),%eax
  10a105:	8b 55 e8             	mov    0xffffffe8(%ebp),%edx
  10a108:	ee                   	out    %al,(%dx)
	outb(addr_6845, 15);
  10a109:	a1 1c ed 17 00       	mov    0x17ed1c,%eax
  10a10e:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
  10a111:	c6 45 ef 0f          	movb   $0xf,0xffffffef(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  10a115:	0f b6 45 ef          	movzbl 0xffffffef(%ebp),%eax
  10a119:	8b 55 f0             	mov    0xfffffff0(%ebp),%edx
  10a11c:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos);
  10a11d:	0f b7 05 24 ed 17 00 	movzwl 0x17ed24,%eax
  10a124:	0f b6 d0             	movzbl %al,%edx
  10a127:	a1 1c ed 17 00       	mov    0x17ed1c,%eax
  10a12c:	83 c0 01             	add    $0x1,%eax
  10a12f:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  10a132:	88 55 f7             	mov    %dl,0xfffffff7(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  10a135:	0f b6 45 f7          	movzbl 0xfffffff7(%ebp),%eax
  10a139:	8b 55 f8             	mov    0xfffffff8(%ebp),%edx
  10a13c:	ee                   	out    %al,(%dx)
}
  10a13d:	83 c4 44             	add    $0x44,%esp
  10a140:	5b                   	pop    %ebx
  10a141:	5d                   	pop    %ebp
  10a142:	c3                   	ret    
  10a143:	90                   	nop    

0010a144 <kbd_proc_data>:
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
  10a144:	55                   	push   %ebp
  10a145:	89 e5                	mov    %esp,%ebp
  10a147:	83 ec 38             	sub    $0x38,%esp
  10a14a:	c7 45 ec 64 00 00 00 	movl   $0x64,0xffffffec(%ebp)
static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  10a151:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
  10a154:	ec                   	in     (%dx),%al
  10a155:	88 45 eb             	mov    %al,0xffffffeb(%ebp)
	return data;
  10a158:	0f b6 45 eb          	movzbl 0xffffffeb(%ebp),%eax
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
  10a15c:	0f b6 c0             	movzbl %al,%eax
  10a15f:	83 e0 01             	and    $0x1,%eax
  10a162:	85 c0                	test   %eax,%eax
  10a164:	75 0c                	jne    10a172 <kbd_proc_data+0x2e>
		return -1;
  10a166:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,0xffffffd8(%ebp)
  10a16d:	e9 69 01 00 00       	jmp    10a2db <kbd_proc_data+0x197>
  10a172:	c7 45 f4 60 00 00 00 	movl   $0x60,0xfffffff4(%ebp)
static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  10a179:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  10a17c:	ec                   	in     (%dx),%al
  10a17d:	88 45 f3             	mov    %al,0xfffffff3(%ebp)
	return data;
  10a180:	0f b6 45 f3          	movzbl 0xfffffff3(%ebp),%eax

	data = inb(KBDATAP);
  10a184:	88 45 ea             	mov    %al,0xffffffea(%ebp)

	if (data == 0xE0) {
  10a187:	80 7d ea e0          	cmpb   $0xe0,0xffffffea(%ebp)
  10a18b:	75 19                	jne    10a1a6 <kbd_proc_data+0x62>
		// E0 escape character
		shift |= E0ESC;
  10a18d:	a1 28 ed 17 00       	mov    0x17ed28,%eax
  10a192:	83 c8 40             	or     $0x40,%eax
  10a195:	a3 28 ed 17 00       	mov    %eax,0x17ed28
		return 0;
  10a19a:	c7 45 d8 00 00 00 00 	movl   $0x0,0xffffffd8(%ebp)
  10a1a1:	e9 35 01 00 00       	jmp    10a2db <kbd_proc_data+0x197>
	} else if (data & 0x80) {
  10a1a6:	0f b6 45 ea          	movzbl 0xffffffea(%ebp),%eax
  10a1aa:	84 c0                	test   %al,%al
  10a1ac:	79 53                	jns    10a201 <kbd_proc_data+0xbd>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
  10a1ae:	a1 28 ed 17 00       	mov    0x17ed28,%eax
  10a1b3:	83 e0 40             	and    $0x40,%eax
  10a1b6:	85 c0                	test   %eax,%eax
  10a1b8:	75 0c                	jne    10a1c6 <kbd_proc_data+0x82>
  10a1ba:	0f b6 45 ea          	movzbl 0xffffffea(%ebp),%eax
  10a1be:	83 e0 7f             	and    $0x7f,%eax
  10a1c1:	88 45 df             	mov    %al,0xffffffdf(%ebp)
  10a1c4:	eb 07                	jmp    10a1cd <kbd_proc_data+0x89>
  10a1c6:	0f b6 45 ea          	movzbl 0xffffffea(%ebp),%eax
  10a1ca:	88 45 df             	mov    %al,0xffffffdf(%ebp)
  10a1cd:	0f b6 45 df          	movzbl 0xffffffdf(%ebp),%eax
  10a1d1:	88 45 ea             	mov    %al,0xffffffea(%ebp)
		shift &= ~(shiftcode[data] | E0ESC);
  10a1d4:	0f b6 45 ea          	movzbl 0xffffffea(%ebp),%eax
  10a1d8:	0f b6 80 80 f0 10 00 	movzbl 0x10f080(%eax),%eax
  10a1df:	83 c8 40             	or     $0x40,%eax
  10a1e2:	0f b6 c0             	movzbl %al,%eax
  10a1e5:	f7 d0                	not    %eax
  10a1e7:	89 c2                	mov    %eax,%edx
  10a1e9:	a1 28 ed 17 00       	mov    0x17ed28,%eax
  10a1ee:	21 d0                	and    %edx,%eax
  10a1f0:	a3 28 ed 17 00       	mov    %eax,0x17ed28
		return 0;
  10a1f5:	c7 45 d8 00 00 00 00 	movl   $0x0,0xffffffd8(%ebp)
  10a1fc:	e9 da 00 00 00       	jmp    10a2db <kbd_proc_data+0x197>
	} else if (shift & E0ESC) {
  10a201:	a1 28 ed 17 00       	mov    0x17ed28,%eax
  10a206:	83 e0 40             	and    $0x40,%eax
  10a209:	85 c0                	test   %eax,%eax
  10a20b:	74 11                	je     10a21e <kbd_proc_data+0xda>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
  10a20d:	80 4d ea 80          	orb    $0x80,0xffffffea(%ebp)
		shift &= ~E0ESC;
  10a211:	a1 28 ed 17 00       	mov    0x17ed28,%eax
  10a216:	83 e0 bf             	and    $0xffffffbf,%eax
  10a219:	a3 28 ed 17 00       	mov    %eax,0x17ed28
	}

	shift |= shiftcode[data];
  10a21e:	0f b6 45 ea          	movzbl 0xffffffea(%ebp),%eax
  10a222:	0f b6 80 80 f0 10 00 	movzbl 0x10f080(%eax),%eax
  10a229:	0f b6 d0             	movzbl %al,%edx
  10a22c:	a1 28 ed 17 00       	mov    0x17ed28,%eax
  10a231:	09 d0                	or     %edx,%eax
  10a233:	a3 28 ed 17 00       	mov    %eax,0x17ed28
	shift ^= togglecode[data];
  10a238:	0f b6 45 ea          	movzbl 0xffffffea(%ebp),%eax
  10a23c:	0f b6 80 80 f1 10 00 	movzbl 0x10f180(%eax),%eax
  10a243:	0f b6 d0             	movzbl %al,%edx
  10a246:	a1 28 ed 17 00       	mov    0x17ed28,%eax
  10a24b:	31 d0                	xor    %edx,%eax
  10a24d:	a3 28 ed 17 00       	mov    %eax,0x17ed28

	c = charcode[shift & (CTL | SHIFT)][data];
  10a252:	a1 28 ed 17 00       	mov    0x17ed28,%eax
  10a257:	83 e0 03             	and    $0x3,%eax
  10a25a:	8b 14 85 80 f5 10 00 	mov    0x10f580(,%eax,4),%edx
  10a261:	0f b6 45 ea          	movzbl 0xffffffea(%ebp),%eax
  10a265:	8d 04 02             	lea    (%edx,%eax,1),%eax
  10a268:	0f b6 00             	movzbl (%eax),%eax
  10a26b:	0f b6 c0             	movzbl %al,%eax
  10a26e:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
	if (shift & CAPSLOCK) {
  10a271:	a1 28 ed 17 00       	mov    0x17ed28,%eax
  10a276:	83 e0 08             	and    $0x8,%eax
  10a279:	85 c0                	test   %eax,%eax
  10a27b:	74 22                	je     10a29f <kbd_proc_data+0x15b>
		if ('a' <= c && c <= 'z')
  10a27d:	83 7d e4 60          	cmpl   $0x60,0xffffffe4(%ebp)
  10a281:	7e 0c                	jle    10a28f <kbd_proc_data+0x14b>
  10a283:	83 7d e4 7a          	cmpl   $0x7a,0xffffffe4(%ebp)
  10a287:	7f 06                	jg     10a28f <kbd_proc_data+0x14b>
			c += 'A' - 'a';
  10a289:	83 6d e4 20          	subl   $0x20,0xffffffe4(%ebp)
  10a28d:	eb 10                	jmp    10a29f <kbd_proc_data+0x15b>
		else if ('A' <= c && c <= 'Z')
  10a28f:	83 7d e4 40          	cmpl   $0x40,0xffffffe4(%ebp)
  10a293:	7e 0a                	jle    10a29f <kbd_proc_data+0x15b>
  10a295:	83 7d e4 5a          	cmpl   $0x5a,0xffffffe4(%ebp)
  10a299:	7f 04                	jg     10a29f <kbd_proc_data+0x15b>
			c += 'a' - 'A';
  10a29b:	83 45 e4 20          	addl   $0x20,0xffffffe4(%ebp)
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
  10a29f:	a1 28 ed 17 00       	mov    0x17ed28,%eax
  10a2a4:	f7 d0                	not    %eax
  10a2a6:	83 e0 06             	and    $0x6,%eax
  10a2a9:	85 c0                	test   %eax,%eax
  10a2ab:	75 28                	jne    10a2d5 <kbd_proc_data+0x191>
  10a2ad:	81 7d e4 e9 00 00 00 	cmpl   $0xe9,0xffffffe4(%ebp)
  10a2b4:	75 1f                	jne    10a2d5 <kbd_proc_data+0x191>
		cprintf("Rebooting!\n");
  10a2b6:	c7 04 24 10 db 10 00 	movl   $0x10db10,(%esp)
  10a2bd:	e8 af 11 00 00       	call   10b471 <cprintf>
  10a2c2:	c7 45 fc 92 00 00 00 	movl   $0x92,0xfffffffc(%ebp)
  10a2c9:	c6 45 fb 03          	movb   $0x3,0xfffffffb(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  10a2cd:	0f b6 45 fb          	movzbl 0xfffffffb(%ebp),%eax
  10a2d1:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  10a2d4:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
  10a2d5:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  10a2d8:	89 45 d8             	mov    %eax,0xffffffd8(%ebp)
  10a2db:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
}
  10a2de:	c9                   	leave  
  10a2df:	c3                   	ret    

0010a2e0 <kbd_intr>:

void
kbd_intr(void)
{
  10a2e0:	55                   	push   %ebp
  10a2e1:	89 e5                	mov    %esp,%ebp
  10a2e3:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
  10a2e6:	c7 04 24 44 a1 10 00 	movl   $0x10a144,(%esp)
  10a2ed:	e8 8a 62 ff ff       	call   10057c <cons_intr>
}
  10a2f2:	c9                   	leave  
  10a2f3:	c3                   	ret    

0010a2f4 <kbd_init>:

void
kbd_init(void)
{
  10a2f4:	55                   	push   %ebp
  10a2f5:	89 e5                	mov    %esp,%ebp
}
  10a2f7:	5d                   	pop    %ebp
  10a2f8:	c3                   	ret    

0010a2f9 <kbd_intenable>:

void
kbd_intenable(void)
{
  10a2f9:	55                   	push   %ebp
  10a2fa:	89 e5                	mov    %esp,%ebp
  10a2fc:	83 ec 08             	sub    $0x8,%esp
	// Enable interrupt delivery via the PIC/APIC
	pic_enable(IRQ_KBD);
  10a2ff:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  10a306:	e8 a4 03 00 00       	call   10a6af <pic_enable>
	ioapic_enable(IRQ_KBD);
  10a30b:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  10a312:	e8 38 09 00 00       	call   10ac4f <ioapic_enable>

	// Drain the kbd buffer so that the hardware generates interrupts.
	kbd_intr();
  10a317:	e8 c4 ff ff ff       	call   10a2e0 <kbd_intr>
}
  10a31c:	c9                   	leave  
  10a31d:	c3                   	ret    
  10a31e:	90                   	nop    
  10a31f:	90                   	nop    

0010a320 <delay>:

// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
  10a320:	55                   	push   %ebp
  10a321:	89 e5                	mov    %esp,%ebp
  10a323:	83 ec 20             	sub    $0x20,%esp
  10a326:	c7 45 e4 84 00 00 00 	movl   $0x84,0xffffffe4(%ebp)
static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  10a32d:	8b 55 e4             	mov    0xffffffe4(%ebp),%edx
  10a330:	ec                   	in     (%dx),%al
  10a331:	88 45 e3             	mov    %al,0xffffffe3(%ebp)
	return data;
  10a334:	c7 45 ec 84 00 00 00 	movl   $0x84,0xffffffec(%ebp)
  10a33b:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
  10a33e:	ec                   	in     (%dx),%al
  10a33f:	88 45 eb             	mov    %al,0xffffffeb(%ebp)
  10a342:	c7 45 f4 84 00 00 00 	movl   $0x84,0xfffffff4(%ebp)
  10a349:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  10a34c:	ec                   	in     (%dx),%al
  10a34d:	88 45 f3             	mov    %al,0xfffffff3(%ebp)
  10a350:	c7 45 fc 84 00 00 00 	movl   $0x84,0xfffffffc(%ebp)
  10a357:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  10a35a:	ec                   	in     (%dx),%al
  10a35b:	88 45 fb             	mov    %al,0xfffffffb(%ebp)
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
  10a35e:	c9                   	leave  
  10a35f:	c3                   	ret    

0010a360 <serial_proc_data>:

static int
serial_proc_data(void)
{
  10a360:	55                   	push   %ebp
  10a361:	89 e5                	mov    %esp,%ebp
  10a363:	83 ec 14             	sub    $0x14,%esp
  10a366:	c7 45 f4 fd 03 00 00 	movl   $0x3fd,0xfffffff4(%ebp)
static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  10a36d:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  10a370:	ec                   	in     (%dx),%al
  10a371:	88 45 f3             	mov    %al,0xfffffff3(%ebp)
	return data;
  10a374:	0f b6 45 f3          	movzbl 0xfffffff3(%ebp),%eax
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
  10a378:	0f b6 c0             	movzbl %al,%eax
  10a37b:	83 e0 01             	and    $0x1,%eax
  10a37e:	85 c0                	test   %eax,%eax
  10a380:	75 09                	jne    10a38b <serial_proc_data+0x2b>
		return -1;
  10a382:	c7 45 ec ff ff ff ff 	movl   $0xffffffff,0xffffffec(%ebp)
  10a389:	eb 18                	jmp    10a3a3 <serial_proc_data+0x43>
  10a38b:	c7 45 fc f8 03 00 00 	movl   $0x3f8,0xfffffffc(%ebp)
static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  10a392:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  10a395:	ec                   	in     (%dx),%al
  10a396:	88 45 fb             	mov    %al,0xfffffffb(%ebp)
	return data;
  10a399:	0f b6 45 fb          	movzbl 0xfffffffb(%ebp),%eax
	return inb(COM1+COM_RX);
  10a39d:	0f b6 c0             	movzbl %al,%eax
  10a3a0:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  10a3a3:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
}
  10a3a6:	c9                   	leave  
  10a3a7:	c3                   	ret    

0010a3a8 <serial_intr>:

void
serial_intr(void)
{
  10a3a8:	55                   	push   %ebp
  10a3a9:	89 e5                	mov    %esp,%ebp
  10a3ab:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
  10a3ae:	a1 00 20 18 00       	mov    0x182000,%eax
  10a3b3:	85 c0                	test   %eax,%eax
  10a3b5:	74 0c                	je     10a3c3 <serial_intr+0x1b>
		cons_intr(serial_proc_data);
  10a3b7:	c7 04 24 60 a3 10 00 	movl   $0x10a360,(%esp)
  10a3be:	e8 b9 61 ff ff       	call   10057c <cons_intr>
}
  10a3c3:	c9                   	leave  
  10a3c4:	c3                   	ret    

0010a3c5 <serial_putc>:

void
serial_putc(int c)
{
  10a3c5:	55                   	push   %ebp
  10a3c6:	89 e5                	mov    %esp,%ebp
  10a3c8:	83 ec 20             	sub    $0x20,%esp
	if (!serial_exists)
  10a3cb:	a1 00 20 18 00       	mov    0x182000,%eax
  10a3d0:	85 c0                	test   %eax,%eax
  10a3d2:	74 4f                	je     10a423 <serial_putc+0x5e>
		return;

	int i;
	for (i = 0;
  10a3d4:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
  10a3db:	eb 09                	jmp    10a3e6 <serial_putc+0x21>
	     i++)
		delay();
  10a3dd:	e8 3e ff ff ff       	call   10a320 <delay>
  10a3e2:	83 45 ec 01          	addl   $0x1,0xffffffec(%ebp)
  10a3e6:	c7 45 f4 fd 03 00 00 	movl   $0x3fd,0xfffffff4(%ebp)
static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  10a3ed:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  10a3f0:	ec                   	in     (%dx),%al
  10a3f1:	88 45 f3             	mov    %al,0xfffffff3(%ebp)
	return data;
  10a3f4:	0f b6 45 f3          	movzbl 0xfffffff3(%ebp),%eax
  10a3f8:	0f b6 c0             	movzbl %al,%eax
  10a3fb:	83 e0 20             	and    $0x20,%eax
  10a3fe:	85 c0                	test   %eax,%eax
  10a400:	75 09                	jne    10a40b <serial_putc+0x46>
  10a402:	81 7d ec ff 31 00 00 	cmpl   $0x31ff,0xffffffec(%ebp)
  10a409:	7e d2                	jle    10a3dd <serial_putc+0x18>
	
	outb(COM1 + COM_TX, c);
  10a40b:	8b 45 08             	mov    0x8(%ebp),%eax
  10a40e:	0f b6 c0             	movzbl %al,%eax
  10a411:	c7 45 fc f8 03 00 00 	movl   $0x3f8,0xfffffffc(%ebp)
  10a418:	88 45 fb             	mov    %al,0xfffffffb(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  10a41b:	0f b6 45 fb          	movzbl 0xfffffffb(%ebp),%eax
  10a41f:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  10a422:	ee                   	out    %al,(%dx)
}
  10a423:	c9                   	leave  
  10a424:	c3                   	ret    

0010a425 <serial_init>:

void
serial_init(void)
{
  10a425:	55                   	push   %ebp
  10a426:	89 e5                	mov    %esp,%ebp
  10a428:	83 ec 50             	sub    $0x50,%esp
  10a42b:	c7 45 b4 fa 03 00 00 	movl   $0x3fa,0xffffffb4(%ebp)
  10a432:	c6 45 b3 00          	movb   $0x0,0xffffffb3(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  10a436:	0f b6 45 b3          	movzbl 0xffffffb3(%ebp),%eax
  10a43a:	8b 55 b4             	mov    0xffffffb4(%ebp),%edx
  10a43d:	ee                   	out    %al,(%dx)
  10a43e:	c7 45 bc fb 03 00 00 	movl   $0x3fb,0xffffffbc(%ebp)
  10a445:	c6 45 bb 80          	movb   $0x80,0xffffffbb(%ebp)
  10a449:	0f b6 45 bb          	movzbl 0xffffffbb(%ebp),%eax
  10a44d:	8b 55 bc             	mov    0xffffffbc(%ebp),%edx
  10a450:	ee                   	out    %al,(%dx)
  10a451:	c7 45 c4 f8 03 00 00 	movl   $0x3f8,0xffffffc4(%ebp)
  10a458:	c6 45 c3 0c          	movb   $0xc,0xffffffc3(%ebp)
  10a45c:	0f b6 45 c3          	movzbl 0xffffffc3(%ebp),%eax
  10a460:	8b 55 c4             	mov    0xffffffc4(%ebp),%edx
  10a463:	ee                   	out    %al,(%dx)
  10a464:	c7 45 cc f9 03 00 00 	movl   $0x3f9,0xffffffcc(%ebp)
  10a46b:	c6 45 cb 00          	movb   $0x0,0xffffffcb(%ebp)
  10a46f:	0f b6 45 cb          	movzbl 0xffffffcb(%ebp),%eax
  10a473:	8b 55 cc             	mov    0xffffffcc(%ebp),%edx
  10a476:	ee                   	out    %al,(%dx)
  10a477:	c7 45 d4 fb 03 00 00 	movl   $0x3fb,0xffffffd4(%ebp)
  10a47e:	c6 45 d3 03          	movb   $0x3,0xffffffd3(%ebp)
  10a482:	0f b6 45 d3          	movzbl 0xffffffd3(%ebp),%eax
  10a486:	8b 55 d4             	mov    0xffffffd4(%ebp),%edx
  10a489:	ee                   	out    %al,(%dx)
  10a48a:	c7 45 dc fc 03 00 00 	movl   $0x3fc,0xffffffdc(%ebp)
  10a491:	c6 45 db 00          	movb   $0x0,0xffffffdb(%ebp)
  10a495:	0f b6 45 db          	movzbl 0xffffffdb(%ebp),%eax
  10a499:	8b 55 dc             	mov    0xffffffdc(%ebp),%edx
  10a49c:	ee                   	out    %al,(%dx)
  10a49d:	c7 45 e4 f9 03 00 00 	movl   $0x3f9,0xffffffe4(%ebp)
  10a4a4:	c6 45 e3 01          	movb   $0x1,0xffffffe3(%ebp)
  10a4a8:	0f b6 45 e3          	movzbl 0xffffffe3(%ebp),%eax
  10a4ac:	8b 55 e4             	mov    0xffffffe4(%ebp),%edx
  10a4af:	ee                   	out    %al,(%dx)
  10a4b0:	c7 45 ec fd 03 00 00 	movl   $0x3fd,0xffffffec(%ebp)
  10a4b7:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
  10a4ba:	ec                   	in     (%dx),%al
  10a4bb:	88 45 eb             	mov    %al,0xffffffeb(%ebp)
  10a4be:	0f b6 45 eb          	movzbl 0xffffffeb(%ebp),%eax
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
  10a4c2:	3c ff                	cmp    $0xff,%al
  10a4c4:	0f 95 c0             	setne  %al
  10a4c7:	0f b6 c0             	movzbl %al,%eax
  10a4ca:	a3 00 20 18 00       	mov    %eax,0x182000
  10a4cf:	c7 45 f4 fa 03 00 00 	movl   $0x3fa,0xfffffff4(%ebp)
static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  10a4d6:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  10a4d9:	ec                   	in     (%dx),%al
  10a4da:	88 45 f3             	mov    %al,0xfffffff3(%ebp)
	return data;
  10a4dd:	c7 45 fc f8 03 00 00 	movl   $0x3f8,0xfffffffc(%ebp)
  10a4e4:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  10a4e7:	ec                   	in     (%dx),%al
  10a4e8:	88 45 fb             	mov    %al,0xfffffffb(%ebp)
	(void) inb(COM1+COM_IIR);
	(void) inb(COM1+COM_RX);
}
  10a4eb:	c9                   	leave  
  10a4ec:	c3                   	ret    

0010a4ed <serial_intenable>:

void
serial_intenable(void)
{
  10a4ed:	55                   	push   %ebp
  10a4ee:	89 e5                	mov    %esp,%ebp
  10a4f0:	83 ec 08             	sub    $0x8,%esp
	// Enable serial interrupts
	if (serial_exists) {
  10a4f3:	a1 00 20 18 00       	mov    0x182000,%eax
  10a4f8:	85 c0                	test   %eax,%eax
  10a4fa:	74 18                	je     10a514 <serial_intenable+0x27>
		pic_enable(IRQ_SERIAL);
  10a4fc:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
  10a503:	e8 a7 01 00 00       	call   10a6af <pic_enable>
		ioapic_enable(IRQ_SERIAL);
  10a508:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
  10a50f:	e8 3b 07 00 00       	call   10ac4f <ioapic_enable>
	}
}
  10a514:	c9                   	leave  
  10a515:	c3                   	ret    
  10a516:	90                   	nop    
  10a517:	90                   	nop    

0010a518 <pic_init>:

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
  10a518:	55                   	push   %ebp
  10a519:	89 e5                	mov    %esp,%ebp
  10a51b:	83 ec 78             	sub    $0x78,%esp
	if (didinit)		// only do once on bootstrap CPU
  10a51e:	a1 2c ed 17 00       	mov    0x17ed2c,%eax
  10a523:	85 c0                	test   %eax,%eax
  10a525:	0f 85 33 01 00 00    	jne    10a65e <pic_init+0x146>
		return;
	didinit = 1;
  10a52b:	c7 05 2c ed 17 00 01 	movl   $0x1,0x17ed2c
  10a532:	00 00 00 
  10a535:	c7 45 94 21 00 00 00 	movl   $0x21,0xffffff94(%ebp)
  10a53c:	c6 45 93 ff          	movb   $0xff,0xffffff93(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  10a540:	0f b6 45 93          	movzbl 0xffffff93(%ebp),%eax
  10a544:	8b 55 94             	mov    0xffffff94(%ebp),%edx
  10a547:	ee                   	out    %al,(%dx)
  10a548:	c7 45 9c a1 00 00 00 	movl   $0xa1,0xffffff9c(%ebp)
  10a54f:	c6 45 9b ff          	movb   $0xff,0xffffff9b(%ebp)
  10a553:	0f b6 45 9b          	movzbl 0xffffff9b(%ebp),%eax
  10a557:	8b 55 9c             	mov    0xffffff9c(%ebp),%edx
  10a55a:	ee                   	out    %al,(%dx)
  10a55b:	c7 45 a4 20 00 00 00 	movl   $0x20,0xffffffa4(%ebp)
  10a562:	c6 45 a3 11          	movb   $0x11,0xffffffa3(%ebp)
  10a566:	0f b6 45 a3          	movzbl 0xffffffa3(%ebp),%eax
  10a56a:	8b 55 a4             	mov    0xffffffa4(%ebp),%edx
  10a56d:	ee                   	out    %al,(%dx)
  10a56e:	c7 45 ac 21 00 00 00 	movl   $0x21,0xffffffac(%ebp)
  10a575:	c6 45 ab 20          	movb   $0x20,0xffffffab(%ebp)
  10a579:	0f b6 45 ab          	movzbl 0xffffffab(%ebp),%eax
  10a57d:	8b 55 ac             	mov    0xffffffac(%ebp),%edx
  10a580:	ee                   	out    %al,(%dx)
  10a581:	c7 45 b4 21 00 00 00 	movl   $0x21,0xffffffb4(%ebp)
  10a588:	c6 45 b3 04          	movb   $0x4,0xffffffb3(%ebp)
  10a58c:	0f b6 45 b3          	movzbl 0xffffffb3(%ebp),%eax
  10a590:	8b 55 b4             	mov    0xffffffb4(%ebp),%edx
  10a593:	ee                   	out    %al,(%dx)
  10a594:	c7 45 bc 21 00 00 00 	movl   $0x21,0xffffffbc(%ebp)
  10a59b:	c6 45 bb 03          	movb   $0x3,0xffffffbb(%ebp)
  10a59f:	0f b6 45 bb          	movzbl 0xffffffbb(%ebp),%eax
  10a5a3:	8b 55 bc             	mov    0xffffffbc(%ebp),%edx
  10a5a6:	ee                   	out    %al,(%dx)
  10a5a7:	c7 45 c4 a0 00 00 00 	movl   $0xa0,0xffffffc4(%ebp)
  10a5ae:	c6 45 c3 11          	movb   $0x11,0xffffffc3(%ebp)
  10a5b2:	0f b6 45 c3          	movzbl 0xffffffc3(%ebp),%eax
  10a5b6:	8b 55 c4             	mov    0xffffffc4(%ebp),%edx
  10a5b9:	ee                   	out    %al,(%dx)
  10a5ba:	c7 45 cc a1 00 00 00 	movl   $0xa1,0xffffffcc(%ebp)
  10a5c1:	c6 45 cb 28          	movb   $0x28,0xffffffcb(%ebp)
  10a5c5:	0f b6 45 cb          	movzbl 0xffffffcb(%ebp),%eax
  10a5c9:	8b 55 cc             	mov    0xffffffcc(%ebp),%edx
  10a5cc:	ee                   	out    %al,(%dx)
  10a5cd:	c7 45 d4 a1 00 00 00 	movl   $0xa1,0xffffffd4(%ebp)
  10a5d4:	c6 45 d3 02          	movb   $0x2,0xffffffd3(%ebp)
  10a5d8:	0f b6 45 d3          	movzbl 0xffffffd3(%ebp),%eax
  10a5dc:	8b 55 d4             	mov    0xffffffd4(%ebp),%edx
  10a5df:	ee                   	out    %al,(%dx)
  10a5e0:	c7 45 dc a1 00 00 00 	movl   $0xa1,0xffffffdc(%ebp)
  10a5e7:	c6 45 db 01          	movb   $0x1,0xffffffdb(%ebp)
  10a5eb:	0f b6 45 db          	movzbl 0xffffffdb(%ebp),%eax
  10a5ef:	8b 55 dc             	mov    0xffffffdc(%ebp),%edx
  10a5f2:	ee                   	out    %al,(%dx)
  10a5f3:	c7 45 e4 20 00 00 00 	movl   $0x20,0xffffffe4(%ebp)
  10a5fa:	c6 45 e3 68          	movb   $0x68,0xffffffe3(%ebp)
  10a5fe:	0f b6 45 e3          	movzbl 0xffffffe3(%ebp),%eax
  10a602:	8b 55 e4             	mov    0xffffffe4(%ebp),%edx
  10a605:	ee                   	out    %al,(%dx)
  10a606:	c7 45 ec 20 00 00 00 	movl   $0x20,0xffffffec(%ebp)
  10a60d:	c6 45 eb 0a          	movb   $0xa,0xffffffeb(%ebp)
  10a611:	0f b6 45 eb          	movzbl 0xffffffeb(%ebp),%eax
  10a615:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
  10a618:	ee                   	out    %al,(%dx)
  10a619:	c7 45 f4 a0 00 00 00 	movl   $0xa0,0xfffffff4(%ebp)
  10a620:	c6 45 f3 68          	movb   $0x68,0xfffffff3(%ebp)
  10a624:	0f b6 45 f3          	movzbl 0xfffffff3(%ebp),%eax
  10a628:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  10a62b:	ee                   	out    %al,(%dx)
  10a62c:	c7 45 fc a0 00 00 00 	movl   $0xa0,0xfffffffc(%ebp)
  10a633:	c6 45 fb 0a          	movb   $0xa,0xfffffffb(%ebp)
  10a637:	0f b6 45 fb          	movzbl 0xfffffffb(%ebp),%eax
  10a63b:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  10a63e:	ee                   	out    %al,(%dx)

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
  10a63f:	0f b7 05 90 f5 10 00 	movzwl 0x10f590,%eax
  10a646:	66 83 f8 ff          	cmp    $0xffffffff,%ax
  10a64a:	74 12                	je     10a65e <pic_init+0x146>
		pic_setmask(irqmask);
  10a64c:	0f b7 05 90 f5 10 00 	movzwl 0x10f590,%eax
  10a653:	0f b7 c0             	movzwl %ax,%eax
  10a656:	89 04 24             	mov    %eax,(%esp)
  10a659:	e8 02 00 00 00       	call   10a660 <pic_setmask>
}
  10a65e:	c9                   	leave  
  10a65f:	c3                   	ret    

0010a660 <pic_setmask>:

void
pic_setmask(uint16_t mask)
{
  10a660:	55                   	push   %ebp
  10a661:	89 e5                	mov    %esp,%ebp
  10a663:	83 ec 14             	sub    $0x14,%esp
  10a666:	8b 45 08             	mov    0x8(%ebp),%eax
  10a669:	66 89 45 ec          	mov    %ax,0xffffffec(%ebp)
	irqmask = mask;
  10a66d:	0f b7 45 ec          	movzwl 0xffffffec(%ebp),%eax
  10a671:	66 a3 90 f5 10 00    	mov    %ax,0x10f590
	outb(IO_PIC1+1, (char)mask);
  10a677:	0f b7 45 ec          	movzwl 0xffffffec(%ebp),%eax
  10a67b:	0f b6 c0             	movzbl %al,%eax
  10a67e:	c7 45 f4 21 00 00 00 	movl   $0x21,0xfffffff4(%ebp)
  10a685:	88 45 f3             	mov    %al,0xfffffff3(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  10a688:	0f b6 45 f3          	movzbl 0xfffffff3(%ebp),%eax
  10a68c:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  10a68f:	ee                   	out    %al,(%dx)
	outb(IO_PIC2+1, (char)(mask >> 8));
  10a690:	0f b7 45 ec          	movzwl 0xffffffec(%ebp),%eax
  10a694:	66 c1 e8 08          	shr    $0x8,%ax
  10a698:	0f b6 c0             	movzbl %al,%eax
  10a69b:	c7 45 fc a1 00 00 00 	movl   $0xa1,0xfffffffc(%ebp)
  10a6a2:	88 45 fb             	mov    %al,0xfffffffb(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  10a6a5:	0f b6 45 fb          	movzbl 0xfffffffb(%ebp),%eax
  10a6a9:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  10a6ac:	ee                   	out    %al,(%dx)
}
  10a6ad:	c9                   	leave  
  10a6ae:	c3                   	ret    

0010a6af <pic_enable>:

void
pic_enable(int irq)
{
  10a6af:	55                   	push   %ebp
  10a6b0:	89 e5                	mov    %esp,%ebp
  10a6b2:	83 ec 04             	sub    $0x4,%esp
	pic_setmask(irqmask & ~(1 << irq));
  10a6b5:	8b 4d 08             	mov    0x8(%ebp),%ecx
  10a6b8:	b8 01 00 00 00       	mov    $0x1,%eax
  10a6bd:	d3 e0                	shl    %cl,%eax
  10a6bf:	89 c2                	mov    %eax,%edx
  10a6c1:	f7 d2                	not    %edx
  10a6c3:	0f b7 05 90 f5 10 00 	movzwl 0x10f590,%eax
  10a6ca:	21 d0                	and    %edx,%eax
  10a6cc:	0f b7 c0             	movzwl %ax,%eax
  10a6cf:	89 04 24             	mov    %eax,(%esp)
  10a6d2:	e8 89 ff ff ff       	call   10a660 <pic_setmask>
}
  10a6d7:	c9                   	leave  
  10a6d8:	c3                   	ret    
  10a6d9:	90                   	nop    
  10a6da:	90                   	nop    
  10a6db:	90                   	nop    

0010a6dc <nvram_read>:


unsigned
nvram_read(unsigned reg)
{
  10a6dc:	55                   	push   %ebp
  10a6dd:	89 e5                	mov    %esp,%ebp
  10a6df:	83 ec 10             	sub    $0x10,%esp
	outb(IO_RTC, reg);
  10a6e2:	8b 45 08             	mov    0x8(%ebp),%eax
  10a6e5:	0f b6 c0             	movzbl %al,%eax
  10a6e8:	c7 45 f4 70 00 00 00 	movl   $0x70,0xfffffff4(%ebp)
  10a6ef:	88 45 f3             	mov    %al,0xfffffff3(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  10a6f2:	0f b6 45 f3          	movzbl 0xfffffff3(%ebp),%eax
  10a6f6:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  10a6f9:	ee                   	out    %al,(%dx)
  10a6fa:	c7 45 fc 71 00 00 00 	movl   $0x71,0xfffffffc(%ebp)
  10a701:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  10a704:	ec                   	in     (%dx),%al
  10a705:	88 45 fb             	mov    %al,0xfffffffb(%ebp)
  10a708:	0f b6 45 fb          	movzbl 0xfffffffb(%ebp),%eax
	return inb(IO_RTC+1);
  10a70c:	0f b6 c0             	movzbl %al,%eax
}
  10a70f:	c9                   	leave  
  10a710:	c3                   	ret    

0010a711 <nvram_read16>:

unsigned
nvram_read16(unsigned r)
{
  10a711:	55                   	push   %ebp
  10a712:	89 e5                	mov    %esp,%ebp
  10a714:	53                   	push   %ebx
  10a715:	83 ec 04             	sub    $0x4,%esp
	return nvram_read(r) | (nvram_read(r + 1) << 8);
  10a718:	8b 45 08             	mov    0x8(%ebp),%eax
  10a71b:	89 04 24             	mov    %eax,(%esp)
  10a71e:	e8 b9 ff ff ff       	call   10a6dc <nvram_read>
  10a723:	89 c3                	mov    %eax,%ebx
  10a725:	8b 45 08             	mov    0x8(%ebp),%eax
  10a728:	83 c0 01             	add    $0x1,%eax
  10a72b:	89 04 24             	mov    %eax,(%esp)
  10a72e:	e8 a9 ff ff ff       	call   10a6dc <nvram_read>
  10a733:	c1 e0 08             	shl    $0x8,%eax
  10a736:	09 d8                	or     %ebx,%eax
}
  10a738:	83 c4 04             	add    $0x4,%esp
  10a73b:	5b                   	pop    %ebx
  10a73c:	5d                   	pop    %ebp
  10a73d:	c3                   	ret    

0010a73e <nvram_write>:

void
nvram_write(unsigned reg, unsigned datum)
{
  10a73e:	55                   	push   %ebp
  10a73f:	89 e5                	mov    %esp,%ebp
  10a741:	83 ec 10             	sub    $0x10,%esp
	outb(IO_RTC, reg);
  10a744:	8b 45 08             	mov    0x8(%ebp),%eax
  10a747:	0f b6 c0             	movzbl %al,%eax
  10a74a:	c7 45 f4 70 00 00 00 	movl   $0x70,0xfffffff4(%ebp)
  10a751:	88 45 f3             	mov    %al,0xfffffff3(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  10a754:	0f b6 45 f3          	movzbl 0xfffffff3(%ebp),%eax
  10a758:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  10a75b:	ee                   	out    %al,(%dx)
	outb(IO_RTC+1, datum);
  10a75c:	8b 45 0c             	mov    0xc(%ebp),%eax
  10a75f:	0f b6 c0             	movzbl %al,%eax
  10a762:	c7 45 fc 71 00 00 00 	movl   $0x71,0xfffffffc(%ebp)
  10a769:	88 45 fb             	mov    %al,0xfffffffb(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  10a76c:	0f b6 45 fb          	movzbl 0xfffffffb(%ebp),%eax
  10a770:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  10a773:	ee                   	out    %al,(%dx)
}
  10a774:	c9                   	leave  
  10a775:	c3                   	ret    
  10a776:	90                   	nop    
  10a777:	90                   	nop    

0010a778 <lapicw>:


static void
lapicw(int index, int value)
{
  10a778:	55                   	push   %ebp
  10a779:	89 e5                	mov    %esp,%ebp
	lapic[index] = value;
  10a77b:	8b 45 08             	mov    0x8(%ebp),%eax
  10a77e:	c1 e0 02             	shl    $0x2,%eax
  10a781:	89 c2                	mov    %eax,%edx
  10a783:	a1 04 20 18 00       	mov    0x182004,%eax
  10a788:	01 c2                	add    %eax,%edx
  10a78a:	8b 45 0c             	mov    0xc(%ebp),%eax
  10a78d:	89 02                	mov    %eax,(%edx)
	lapic[ID];  // wait for write to finish, by reading
  10a78f:	a1 04 20 18 00       	mov    0x182004,%eax
  10a794:	83 c0 20             	add    $0x20,%eax
  10a797:	8b 00                	mov    (%eax),%eax
}
  10a799:	5d                   	pop    %ebp
  10a79a:	c3                   	ret    

0010a79b <lapic_init>:

void
lapic_init()
{
  10a79b:	55                   	push   %ebp
  10a79c:	89 e5                	mov    %esp,%ebp
  10a79e:	83 ec 08             	sub    $0x8,%esp
	if (!lapic) 
  10a7a1:	a1 04 20 18 00       	mov    0x182004,%eax
  10a7a6:	85 c0                	test   %eax,%eax
  10a7a8:	0f 84 80 01 00 00    	je     10a92e <lapic_init+0x193>
		return;

	// Enable local APIC; set spurious interrupt vector.
	lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
  10a7ae:	c7 44 24 04 27 01 00 	movl   $0x127,0x4(%esp)
  10a7b5:	00 
  10a7b6:	c7 04 24 3c 00 00 00 	movl   $0x3c,(%esp)
  10a7bd:	e8 b6 ff ff ff       	call   10a778 <lapicw>

	// The timer repeatedly counts down at bus frequency
	// from lapic[TICR] and then issues an interrupt.  
	lapicw(TDCR, X1);
  10a7c2:	c7 44 24 04 0b 00 00 	movl   $0xb,0x4(%esp)
  10a7c9:	00 
  10a7ca:	c7 04 24 f8 00 00 00 	movl   $0xf8,(%esp)
  10a7d1:	e8 a2 ff ff ff       	call   10a778 <lapicw>
	lapicw(TIMER, PERIODIC | T_LTIMER);
  10a7d6:	c7 44 24 04 31 00 02 	movl   $0x20031,0x4(%esp)
  10a7dd:	00 
  10a7de:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
  10a7e5:	e8 8e ff ff ff       	call   10a778 <lapicw>

	// If we cared more about precise timekeeping,
	// we would calibrate TICR with another time source such as the PIT.
	lapicw(TICR, 10000000);
  10a7ea:	c7 44 24 04 80 96 98 	movl   $0x989680,0x4(%esp)
  10a7f1:	00 
  10a7f2:	c7 04 24 e0 00 00 00 	movl   $0xe0,(%esp)
  10a7f9:	e8 7a ff ff ff       	call   10a778 <lapicw>

	// Disable logical interrupt lines.
	lapicw(LINT0, MASKED);
  10a7fe:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
  10a805:	00 
  10a806:	c7 04 24 d4 00 00 00 	movl   $0xd4,(%esp)
  10a80d:	e8 66 ff ff ff       	call   10a778 <lapicw>
	lapicw(LINT1, MASKED);
  10a812:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
  10a819:	00 
  10a81a:	c7 04 24 d8 00 00 00 	movl   $0xd8,(%esp)
  10a821:	e8 52 ff ff ff       	call   10a778 <lapicw>

	// Disable performance counter overflow interrupts
	// on machines that provide that interrupt entry.
	if (((lapic[VER]>>16) & 0xFF) >= 4)
  10a826:	a1 04 20 18 00       	mov    0x182004,%eax
  10a82b:	83 c0 30             	add    $0x30,%eax
  10a82e:	8b 00                	mov    (%eax),%eax
  10a830:	c1 e8 10             	shr    $0x10,%eax
  10a833:	25 ff 00 00 00       	and    $0xff,%eax
  10a838:	83 f8 03             	cmp    $0x3,%eax
  10a83b:	76 14                	jbe    10a851 <lapic_init+0xb6>
		lapicw(PCINT, MASKED);
  10a83d:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
  10a844:	00 
  10a845:	c7 04 24 d0 00 00 00 	movl   $0xd0,(%esp)
  10a84c:	e8 27 ff ff ff       	call   10a778 <lapicw>

	// Map other interrupts to appropriate vectors.
	lapicw(ERROR, T_LERROR);
  10a851:	c7 44 24 04 32 00 00 	movl   $0x32,0x4(%esp)
  10a858:	00 
  10a859:	c7 04 24 dc 00 00 00 	movl   $0xdc,(%esp)
  10a860:	e8 13 ff ff ff       	call   10a778 <lapicw>

	// Set up to lowest-priority, "anycast" interrupts
	lapicw(LDR, 0xff << 24);	// Accept all interrupts
  10a865:	c7 44 24 04 00 00 00 	movl   $0xff000000,0x4(%esp)
  10a86c:	ff 
  10a86d:	c7 04 24 34 00 00 00 	movl   $0x34,(%esp)
  10a874:	e8 ff fe ff ff       	call   10a778 <lapicw>
	lapicw(DFR, 0xf << 28);		// Flat model
  10a879:	c7 44 24 04 00 00 00 	movl   $0xf0000000,0x4(%esp)
  10a880:	f0 
  10a881:	c7 04 24 38 00 00 00 	movl   $0x38,(%esp)
  10a888:	e8 eb fe ff ff       	call   10a778 <lapicw>
	lapicw(TPR, 0x00);		// Task priority 0, no intrs masked
  10a88d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  10a894:	00 
  10a895:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  10a89c:	e8 d7 fe ff ff       	call   10a778 <lapicw>

	// Clear error status register (requires back-to-back writes).
	lapicw(ESR, 0);
  10a8a1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  10a8a8:	00 
  10a8a9:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
  10a8b0:	e8 c3 fe ff ff       	call   10a778 <lapicw>
	lapicw(ESR, 0);
  10a8b5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  10a8bc:	00 
  10a8bd:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
  10a8c4:	e8 af fe ff ff       	call   10a778 <lapicw>

	// Ack any outstanding interrupts.
	lapicw(EOI, 0);
  10a8c9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  10a8d0:	00 
  10a8d1:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
  10a8d8:	e8 9b fe ff ff       	call   10a778 <lapicw>

	// Send an Init Level De-Assert to synchronise arbitration ID's.
	lapicw(ICRHI, 0);
  10a8dd:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  10a8e4:	00 
  10a8e5:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
  10a8ec:	e8 87 fe ff ff       	call   10a778 <lapicw>
	lapicw(ICRLO, BCAST | INIT | LEVEL);
  10a8f1:	c7 44 24 04 00 85 08 	movl   $0x88500,0x4(%esp)
  10a8f8:	00 
  10a8f9:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
  10a900:	e8 73 fe ff ff       	call   10a778 <lapicw>
	while(lapic[ICRLO] & DELIVS)
  10a905:	a1 04 20 18 00       	mov    0x182004,%eax
  10a90a:	05 00 03 00 00       	add    $0x300,%eax
  10a90f:	8b 00                	mov    (%eax),%eax
  10a911:	25 00 10 00 00       	and    $0x1000,%eax
  10a916:	85 c0                	test   %eax,%eax
  10a918:	75 eb                	jne    10a905 <lapic_init+0x16a>
		;

	// Enable interrupts on the APIC (but not on the processor).
	lapicw(TPR, 0);
  10a91a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  10a921:	00 
  10a922:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  10a929:	e8 4a fe ff ff       	call   10a778 <lapicw>
}
  10a92e:	c9                   	leave  
  10a92f:	c3                   	ret    

0010a930 <lapic_eoi>:

// Acknowledge interrupt.
void
lapic_eoi(void)
{
  10a930:	55                   	push   %ebp
  10a931:	89 e5                	mov    %esp,%ebp
  10a933:	83 ec 08             	sub    $0x8,%esp
	if (lapic)
  10a936:	a1 04 20 18 00       	mov    0x182004,%eax
  10a93b:	85 c0                	test   %eax,%eax
  10a93d:	74 14                	je     10a953 <lapic_eoi+0x23>
		lapicw(EOI, 0);
  10a93f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  10a946:	00 
  10a947:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
  10a94e:	e8 25 fe ff ff       	call   10a778 <lapicw>
}
  10a953:	c9                   	leave  
  10a954:	c3                   	ret    

0010a955 <lapic_errintr>:

void lapic_errintr(void)
{
  10a955:	55                   	push   %ebp
  10a956:	89 e5                	mov    %esp,%ebp
  10a958:	53                   	push   %ebx
  10a959:	83 ec 14             	sub    $0x14,%esp
	lapic_eoi();	// Acknowledge interrupt
  10a95c:	e8 cf ff ff ff       	call   10a930 <lapic_eoi>
	lapicw(ESR, 0);	// Trigger update of ESR by writing anything
  10a961:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  10a968:	00 
  10a969:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
  10a970:	e8 03 fe ff ff       	call   10a778 <lapicw>
	warn("CPU%d LAPIC error: ESR %x", cpu_cur()->id, lapic[ESR]);
  10a975:	a1 04 20 18 00       	mov    0x182004,%eax
  10a97a:	05 80 02 00 00       	add    $0x280,%eax
  10a97f:	8b 18                	mov    (%eax),%ebx
  10a981:	e8 34 00 00 00       	call   10a9ba <cpu_cur>
  10a986:	0f b6 80 ac 00 00 00 	movzbl 0xac(%eax),%eax
  10a98d:	0f b6 c0             	movzbl %al,%eax
  10a990:	89 5c 24 10          	mov    %ebx,0x10(%esp)
  10a994:	89 44 24 0c          	mov    %eax,0xc(%esp)
  10a998:	c7 44 24 08 1c db 10 	movl   $0x10db1c,0x8(%esp)
  10a99f:	00 
  10a9a0:	c7 44 24 04 60 00 00 	movl   $0x60,0x4(%esp)
  10a9a7:	00 
  10a9a8:	c7 04 24 36 db 10 00 	movl   $0x10db36,(%esp)
  10a9af:	e8 72 60 ff ff       	call   100a26 <debug_warn>
}
  10a9b4:	83 c4 14             	add    $0x14,%esp
  10a9b7:	5b                   	pop    %ebx
  10a9b8:	5d                   	pop    %ebp
  10a9b9:	c3                   	ret    

0010a9ba <cpu_cur>:

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  10a9ba:	55                   	push   %ebp
  10a9bb:	89 e5                	mov    %esp,%ebp
  10a9bd:	83 ec 28             	sub    $0x28,%esp
static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  10a9c0:	89 65 fc             	mov    %esp,0xfffffffc(%ebp)
        return esp;
  10a9c3:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  10a9c6:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  10a9c9:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10a9cc:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  10a9d1:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	assert(c->magic == CPU_MAGIC);
  10a9d4:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  10a9d7:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  10a9dd:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  10a9e2:	74 24                	je     10aa08 <cpu_cur+0x4e>
  10a9e4:	c7 44 24 0c 42 db 10 	movl   $0x10db42,0xc(%esp)
  10a9eb:	00 
  10a9ec:	c7 44 24 08 58 db 10 	movl   $0x10db58,0x8(%esp)
  10a9f3:	00 
  10a9f4:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  10a9fb:	00 
  10a9fc:	c7 04 24 6d db 10 00 	movl   $0x10db6d,(%esp)
  10aa03:	e8 60 5f ff ff       	call   100968 <debug_panic>
	return c;
  10aa08:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
}
  10aa0b:	c9                   	leave  
  10aa0c:	c3                   	ret    

0010aa0d <microdelay>:

// Spin for a given number of microseconds.
// On real hardware would want to tune this dynamically.
void
microdelay(int us)
{
  10aa0d:	55                   	push   %ebp
  10aa0e:	89 e5                	mov    %esp,%ebp
}
  10aa10:	5d                   	pop    %ebp
  10aa11:	c3                   	ret    

0010aa12 <lapic_startcpu>:


#define IO_RTC  0x70

// Start additional processor running bootstrap code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapic_startcpu(uint8_t apicid, uint32_t addr)
{
  10aa12:	55                   	push   %ebp
  10aa13:	89 e5                	mov    %esp,%ebp
  10aa15:	83 ec 2c             	sub    $0x2c,%esp
  10aa18:	8b 45 08             	mov    0x8(%ebp),%eax
  10aa1b:	88 45 dc             	mov    %al,0xffffffdc(%ebp)
  10aa1e:	c7 45 f4 70 00 00 00 	movl   $0x70,0xfffffff4(%ebp)
  10aa25:	c6 45 f3 0f          	movb   $0xf,0xfffffff3(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  10aa29:	0f b6 45 f3          	movzbl 0xfffffff3(%ebp),%eax
  10aa2d:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  10aa30:	ee                   	out    %al,(%dx)
  10aa31:	c7 45 fc 71 00 00 00 	movl   $0x71,0xfffffffc(%ebp)
  10aa38:	c6 45 fb 0a          	movb   $0xa,0xfffffffb(%ebp)
  10aa3c:	0f b6 45 fb          	movzbl 0xfffffffb(%ebp),%eax
  10aa40:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  10aa43:	ee                   	out    %al,(%dx)
	int i;
	uint16_t *wrv;

	// "The BSP must initialize CMOS shutdown code to 0AH
	// and the warm reset vector (DWORD based at 40:67) to point at
	// the AP startup code prior to the [universal startup algorithm]."
	outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
	outb(IO_RTC+1, 0x0A);
	wrv = (uint16_t*)(0x40<<4 | 0x67);  // Warm reset vector
  10aa44:	c7 45 ec 67 04 00 00 	movl   $0x467,0xffffffec(%ebp)
	wrv[0] = 0;
  10aa4b:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  10aa4e:	66 c7 00 00 00       	movw   $0x0,(%eax)
	wrv[1] = addr >> 4;
  10aa53:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
  10aa56:	83 c2 02             	add    $0x2,%edx
  10aa59:	8b 45 0c             	mov    0xc(%ebp),%eax
  10aa5c:	c1 e8 04             	shr    $0x4,%eax
  10aa5f:	66 89 02             	mov    %ax,(%edx)

	// "Universal startup algorithm."
	// Send INIT (level-triggered) interrupt to reset other CPU.
	lapicw(ICRHI, apicid<<24);
  10aa62:	0f b6 45 dc          	movzbl 0xffffffdc(%ebp),%eax
  10aa66:	c1 e0 18             	shl    $0x18,%eax
  10aa69:	89 44 24 04          	mov    %eax,0x4(%esp)
  10aa6d:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
  10aa74:	e8 ff fc ff ff       	call   10a778 <lapicw>
	lapicw(ICRLO, INIT | LEVEL | ASSERT);
  10aa79:	c7 44 24 04 00 c5 00 	movl   $0xc500,0x4(%esp)
  10aa80:	00 
  10aa81:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
  10aa88:	e8 eb fc ff ff       	call   10a778 <lapicw>
	microdelay(200);
  10aa8d:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
  10aa94:	e8 74 ff ff ff       	call   10aa0d <microdelay>
	lapicw(ICRLO, INIT | LEVEL);
  10aa99:	c7 44 24 04 00 85 00 	movl   $0x8500,0x4(%esp)
  10aaa0:	00 
  10aaa1:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
  10aaa8:	e8 cb fc ff ff       	call   10a778 <lapicw>
	microdelay(100);    // should be 10ms, but too slow in Bochs!
  10aaad:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
  10aab4:	e8 54 ff ff ff       	call   10aa0d <microdelay>

	// Send startup IPI (twice!) to enter bootstrap code.
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for(i = 0; i < 2; i++){
  10aab9:	c7 45 e8 00 00 00 00 	movl   $0x0,0xffffffe8(%ebp)
  10aac0:	eb 40                	jmp    10ab02 <lapic_startcpu+0xf0>
		lapicw(ICRHI, apicid<<24);
  10aac2:	0f b6 45 dc          	movzbl 0xffffffdc(%ebp),%eax
  10aac6:	c1 e0 18             	shl    $0x18,%eax
  10aac9:	89 44 24 04          	mov    %eax,0x4(%esp)
  10aacd:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
  10aad4:	e8 9f fc ff ff       	call   10a778 <lapicw>
		lapicw(ICRLO, STARTUP | (addr>>12));
  10aad9:	8b 45 0c             	mov    0xc(%ebp),%eax
  10aadc:	c1 e8 0c             	shr    $0xc,%eax
  10aadf:	80 cc 06             	or     $0x6,%ah
  10aae2:	89 44 24 04          	mov    %eax,0x4(%esp)
  10aae6:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
  10aaed:	e8 86 fc ff ff       	call   10a778 <lapicw>
		microdelay(200);
  10aaf2:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
  10aaf9:	e8 0f ff ff ff       	call   10aa0d <microdelay>
  10aafe:	83 45 e8 01          	addl   $0x1,0xffffffe8(%ebp)
  10ab02:	83 7d e8 01          	cmpl   $0x1,0xffffffe8(%ebp)
  10ab06:	7e ba                	jle    10aac2 <lapic_startcpu+0xb0>
	}
}
  10ab08:	c9                   	leave  
  10ab09:	c3                   	ret    
  10ab0a:	90                   	nop    
  10ab0b:	90                   	nop    

0010ab0c <ioapic_read>:
};

static uint32_t
ioapic_read(int reg)
{
  10ab0c:	55                   	push   %ebp
  10ab0d:	89 e5                	mov    %esp,%ebp
	ioapic->reg = reg;
  10ab0f:	8b 15 e4 ed 17 00    	mov    0x17ede4,%edx
  10ab15:	8b 45 08             	mov    0x8(%ebp),%eax
  10ab18:	89 02                	mov    %eax,(%edx)
	return ioapic->data;
  10ab1a:	a1 e4 ed 17 00       	mov    0x17ede4,%eax
  10ab1f:	8b 40 10             	mov    0x10(%eax),%eax
}
  10ab22:	5d                   	pop    %ebp
  10ab23:	c3                   	ret    

0010ab24 <ioapic_write>:

static void
ioapic_write(int reg, uint32_t data)
{
  10ab24:	55                   	push   %ebp
  10ab25:	89 e5                	mov    %esp,%ebp
	ioapic->reg = reg;
  10ab27:	8b 15 e4 ed 17 00    	mov    0x17ede4,%edx
  10ab2d:	8b 45 08             	mov    0x8(%ebp),%eax
  10ab30:	89 02                	mov    %eax,(%edx)
	ioapic->data = data;
  10ab32:	8b 15 e4 ed 17 00    	mov    0x17ede4,%edx
  10ab38:	8b 45 0c             	mov    0xc(%ebp),%eax
  10ab3b:	89 42 10             	mov    %eax,0x10(%edx)
}
  10ab3e:	5d                   	pop    %ebp
  10ab3f:	c3                   	ret    

0010ab40 <ioapic_init>:

void
ioapic_init(void)
{
  10ab40:	55                   	push   %ebp
  10ab41:	89 e5                	mov    %esp,%ebp
  10ab43:	83 ec 28             	sub    $0x28,%esp
	int i, id, maxintr;

	if(!ismp)
  10ab46:	a1 e8 ed 17 00       	mov    0x17ede8,%eax
  10ab4b:	85 c0                	test   %eax,%eax
  10ab4d:	0f 84 fa 00 00 00    	je     10ac4d <ioapic_init+0x10d>
		return;

	if (ioapic == NULL)
  10ab53:	a1 e4 ed 17 00       	mov    0x17ede4,%eax
  10ab58:	85 c0                	test   %eax,%eax
  10ab5a:	75 0a                	jne    10ab66 <ioapic_init+0x26>
		ioapic = mem_ptr(IOAPIC);	// assume default address
  10ab5c:	c7 05 e4 ed 17 00 00 	movl   $0xfec00000,0x17ede4
  10ab63:	00 c0 fe 

	maxintr = (ioapic_read(REG_VER) >> 16) & 0xFF;
  10ab66:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  10ab6d:	e8 9a ff ff ff       	call   10ab0c <ioapic_read>
  10ab72:	c1 e8 10             	shr    $0x10,%eax
  10ab75:	25 ff 00 00 00       	and    $0xff,%eax
  10ab7a:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	id = ioapic_read(REG_ID) >> 24;
  10ab7d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  10ab84:	e8 83 ff ff ff       	call   10ab0c <ioapic_read>
  10ab89:	c1 e8 18             	shr    $0x18,%eax
  10ab8c:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
	if (id == 0) {
  10ab8f:	83 7d f8 00          	cmpl   $0x0,0xfffffff8(%ebp)
  10ab93:	75 2a                	jne    10abbf <ioapic_init+0x7f>
		// I/O APIC ID not initialized yet - have to do it ourselves.
		ioapic_write(REG_ID, ioapicid << 24);
  10ab95:	0f b6 05 e0 ed 17 00 	movzbl 0x17ede0,%eax
  10ab9c:	0f b6 c0             	movzbl %al,%eax
  10ab9f:	c1 e0 18             	shl    $0x18,%eax
  10aba2:	89 44 24 04          	mov    %eax,0x4(%esp)
  10aba6:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  10abad:	e8 72 ff ff ff       	call   10ab24 <ioapic_write>
		id = ioapicid;
  10abb2:	0f b6 05 e0 ed 17 00 	movzbl 0x17ede0,%eax
  10abb9:	0f b6 c0             	movzbl %al,%eax
  10abbc:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
	}
	if (id != ioapicid)
  10abbf:	0f b6 05 e0 ed 17 00 	movzbl 0x17ede0,%eax
  10abc6:	0f b6 c0             	movzbl %al,%eax
  10abc9:	3b 45 f8             	cmp    0xfffffff8(%ebp),%eax
  10abcc:	74 31                	je     10abff <ioapic_init+0xbf>
		warn("ioapicinit: id %d != ioapicid %d", id, ioapicid);
  10abce:	0f b6 05 e0 ed 17 00 	movzbl 0x17ede0,%eax
  10abd5:	0f b6 c0             	movzbl %al,%eax
  10abd8:	89 44 24 10          	mov    %eax,0x10(%esp)
  10abdc:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10abdf:	89 44 24 0c          	mov    %eax,0xc(%esp)
  10abe3:	c7 44 24 08 7c db 10 	movl   $0x10db7c,0x8(%esp)
  10abea:	00 
  10abeb:	c7 44 24 04 53 00 00 	movl   $0x53,0x4(%esp)
  10abf2:	00 
  10abf3:	c7 04 24 9d db 10 00 	movl   $0x10db9d,(%esp)
  10abfa:	e8 27 5e ff ff       	call   100a26 <debug_warn>

	// Mark all interrupts edge-triggered, active high, disabled,
	// and not routed to any CPUs.
	for (i = 0; i <= maxintr; i++){
  10abff:	c7 45 f4 00 00 00 00 	movl   $0x0,0xfffffff4(%ebp)
  10ac06:	eb 3d                	jmp    10ac45 <ioapic_init+0x105>
		ioapic_write(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
  10ac08:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  10ac0b:	83 c0 20             	add    $0x20,%eax
  10ac0e:	0d 00 00 01 00       	or     $0x10000,%eax
  10ac13:	89 c2                	mov    %eax,%edx
  10ac15:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  10ac18:	01 c0                	add    %eax,%eax
  10ac1a:	83 c0 10             	add    $0x10,%eax
  10ac1d:	89 54 24 04          	mov    %edx,0x4(%esp)
  10ac21:	89 04 24             	mov    %eax,(%esp)
  10ac24:	e8 fb fe ff ff       	call   10ab24 <ioapic_write>
		ioapic_write(REG_TABLE+2*i+1, 0);
  10ac29:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  10ac2c:	01 c0                	add    %eax,%eax
  10ac2e:	83 c0 11             	add    $0x11,%eax
  10ac31:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  10ac38:	00 
  10ac39:	89 04 24             	mov    %eax,(%esp)
  10ac3c:	e8 e3 fe ff ff       	call   10ab24 <ioapic_write>
  10ac41:	83 45 f4 01          	addl   $0x1,0xfffffff4(%ebp)
  10ac45:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  10ac48:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  10ac4b:	7e bb                	jle    10ac08 <ioapic_init+0xc8>
	}
}
  10ac4d:	c9                   	leave  
  10ac4e:	c3                   	ret    

0010ac4f <ioapic_enable>:

void
ioapic_enable(int irq)
{
  10ac4f:	55                   	push   %ebp
  10ac50:	89 e5                	mov    %esp,%ebp
  10ac52:	83 ec 08             	sub    $0x8,%esp
	if (!ismp)
  10ac55:	a1 e8 ed 17 00       	mov    0x17ede8,%eax
  10ac5a:	85 c0                	test   %eax,%eax
  10ac5c:	74 37                	je     10ac95 <ioapic_enable+0x46>
		return;

	// Mark interrupt edge-triggered, active high,
	// enabled, and routed to any CPU.
	ioapic_write(REG_TABLE+2*irq,
  10ac5e:	8b 45 08             	mov    0x8(%ebp),%eax
  10ac61:	83 c0 20             	add    $0x20,%eax
  10ac64:	80 cc 09             	or     $0x9,%ah
  10ac67:	89 c2                	mov    %eax,%edx
  10ac69:	8b 45 08             	mov    0x8(%ebp),%eax
  10ac6c:	01 c0                	add    %eax,%eax
  10ac6e:	83 c0 10             	add    $0x10,%eax
  10ac71:	89 54 24 04          	mov    %edx,0x4(%esp)
  10ac75:	89 04 24             	mov    %eax,(%esp)
  10ac78:	e8 a7 fe ff ff       	call   10ab24 <ioapic_write>
			INT_LOGICAL | INT_LOWEST | (T_IRQ0 + irq));
	ioapic_write(REG_TABLE+2*irq+1, 0xff << 24);
  10ac7d:	8b 45 08             	mov    0x8(%ebp),%eax
  10ac80:	01 c0                	add    %eax,%eax
  10ac82:	83 c0 11             	add    $0x11,%eax
  10ac85:	c7 44 24 04 00 00 00 	movl   $0xff000000,0x4(%esp)
  10ac8c:	ff 
  10ac8d:	89 04 24             	mov    %eax,(%esp)
  10ac90:	e8 8f fe ff ff       	call   10ab24 <ioapic_write>
}
  10ac95:	c9                   	leave  
  10ac96:	c3                   	ret    
  10ac97:	90                   	nop    

0010ac98 <getuint>:
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static uintmax_t
getuint(printstate *st, va_list *ap)
{
  10ac98:	55                   	push   %ebp
  10ac99:	89 e5                	mov    %esp,%ebp
  10ac9b:	83 ec 08             	sub    $0x8,%esp
	if (st->flags & F_LL)
  10ac9e:	8b 45 08             	mov    0x8(%ebp),%eax
  10aca1:	8b 40 18             	mov    0x18(%eax),%eax
  10aca4:	83 e0 02             	and    $0x2,%eax
  10aca7:	85 c0                	test   %eax,%eax
  10aca9:	74 22                	je     10accd <getuint+0x35>
		return va_arg(*ap, unsigned long long);
  10acab:	8b 45 0c             	mov    0xc(%ebp),%eax
  10acae:	8b 00                	mov    (%eax),%eax
  10acb0:	8d 50 08             	lea    0x8(%eax),%edx
  10acb3:	8b 45 0c             	mov    0xc(%ebp),%eax
  10acb6:	89 10                	mov    %edx,(%eax)
  10acb8:	8b 45 0c             	mov    0xc(%ebp),%eax
  10acbb:	8b 00                	mov    (%eax),%eax
  10acbd:	83 e8 08             	sub    $0x8,%eax
  10acc0:	8b 10                	mov    (%eax),%edx
  10acc2:	8b 48 04             	mov    0x4(%eax),%ecx
  10acc5:	89 55 f8             	mov    %edx,0xfffffff8(%ebp)
  10acc8:	89 4d fc             	mov    %ecx,0xfffffffc(%ebp)
  10accb:	eb 51                	jmp    10ad1e <getuint+0x86>
	else if (st->flags & F_L)
  10accd:	8b 45 08             	mov    0x8(%ebp),%eax
  10acd0:	8b 40 18             	mov    0x18(%eax),%eax
  10acd3:	83 e0 01             	and    $0x1,%eax
  10acd6:	84 c0                	test   %al,%al
  10acd8:	74 23                	je     10acfd <getuint+0x65>
		return va_arg(*ap, unsigned long);
  10acda:	8b 45 0c             	mov    0xc(%ebp),%eax
  10acdd:	8b 00                	mov    (%eax),%eax
  10acdf:	8d 50 04             	lea    0x4(%eax),%edx
  10ace2:	8b 45 0c             	mov    0xc(%ebp),%eax
  10ace5:	89 10                	mov    %edx,(%eax)
  10ace7:	8b 45 0c             	mov    0xc(%ebp),%eax
  10acea:	8b 00                	mov    (%eax),%eax
  10acec:	83 e8 04             	sub    $0x4,%eax
  10acef:	8b 00                	mov    (%eax),%eax
  10acf1:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  10acf4:	c7 45 fc 00 00 00 00 	movl   $0x0,0xfffffffc(%ebp)
  10acfb:	eb 21                	jmp    10ad1e <getuint+0x86>
	else
		return va_arg(*ap, unsigned int);
  10acfd:	8b 45 0c             	mov    0xc(%ebp),%eax
  10ad00:	8b 00                	mov    (%eax),%eax
  10ad02:	8d 50 04             	lea    0x4(%eax),%edx
  10ad05:	8b 45 0c             	mov    0xc(%ebp),%eax
  10ad08:	89 10                	mov    %edx,(%eax)
  10ad0a:	8b 45 0c             	mov    0xc(%ebp),%eax
  10ad0d:	8b 00                	mov    (%eax),%eax
  10ad0f:	83 e8 04             	sub    $0x4,%eax
  10ad12:	8b 00                	mov    (%eax),%eax
  10ad14:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  10ad17:	c7 45 fc 00 00 00 00 	movl   $0x0,0xfffffffc(%ebp)
  10ad1e:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10ad21:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
}
  10ad24:	c9                   	leave  
  10ad25:	c3                   	ret    

0010ad26 <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static intmax_t
getint(printstate *st, va_list *ap)
{
  10ad26:	55                   	push   %ebp
  10ad27:	89 e5                	mov    %esp,%ebp
  10ad29:	83 ec 08             	sub    $0x8,%esp
	if (st->flags & F_LL)
  10ad2c:	8b 45 08             	mov    0x8(%ebp),%eax
  10ad2f:	8b 40 18             	mov    0x18(%eax),%eax
  10ad32:	83 e0 02             	and    $0x2,%eax
  10ad35:	85 c0                	test   %eax,%eax
  10ad37:	74 22                	je     10ad5b <getint+0x35>
		return va_arg(*ap, long long);
  10ad39:	8b 45 0c             	mov    0xc(%ebp),%eax
  10ad3c:	8b 00                	mov    (%eax),%eax
  10ad3e:	8d 50 08             	lea    0x8(%eax),%edx
  10ad41:	8b 45 0c             	mov    0xc(%ebp),%eax
  10ad44:	89 10                	mov    %edx,(%eax)
  10ad46:	8b 45 0c             	mov    0xc(%ebp),%eax
  10ad49:	8b 00                	mov    (%eax),%eax
  10ad4b:	83 e8 08             	sub    $0x8,%eax
  10ad4e:	8b 10                	mov    (%eax),%edx
  10ad50:	8b 48 04             	mov    0x4(%eax),%ecx
  10ad53:	89 55 f8             	mov    %edx,0xfffffff8(%ebp)
  10ad56:	89 4d fc             	mov    %ecx,0xfffffffc(%ebp)
  10ad59:	eb 53                	jmp    10adae <getint+0x88>
	else if (st->flags & F_L)
  10ad5b:	8b 45 08             	mov    0x8(%ebp),%eax
  10ad5e:	8b 40 18             	mov    0x18(%eax),%eax
  10ad61:	83 e0 01             	and    $0x1,%eax
  10ad64:	84 c0                	test   %al,%al
  10ad66:	74 24                	je     10ad8c <getint+0x66>
		return va_arg(*ap, long);
  10ad68:	8b 45 0c             	mov    0xc(%ebp),%eax
  10ad6b:	8b 00                	mov    (%eax),%eax
  10ad6d:	8d 50 04             	lea    0x4(%eax),%edx
  10ad70:	8b 45 0c             	mov    0xc(%ebp),%eax
  10ad73:	89 10                	mov    %edx,(%eax)
  10ad75:	8b 45 0c             	mov    0xc(%ebp),%eax
  10ad78:	8b 00                	mov    (%eax),%eax
  10ad7a:	83 e8 04             	sub    $0x4,%eax
  10ad7d:	8b 00                	mov    (%eax),%eax
  10ad7f:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  10ad82:	89 c1                	mov    %eax,%ecx
  10ad84:	c1 f9 1f             	sar    $0x1f,%ecx
  10ad87:	89 4d fc             	mov    %ecx,0xfffffffc(%ebp)
  10ad8a:	eb 22                	jmp    10adae <getint+0x88>
	else
		return va_arg(*ap, int);
  10ad8c:	8b 45 0c             	mov    0xc(%ebp),%eax
  10ad8f:	8b 00                	mov    (%eax),%eax
  10ad91:	8d 50 04             	lea    0x4(%eax),%edx
  10ad94:	8b 45 0c             	mov    0xc(%ebp),%eax
  10ad97:	89 10                	mov    %edx,(%eax)
  10ad99:	8b 45 0c             	mov    0xc(%ebp),%eax
  10ad9c:	8b 00                	mov    (%eax),%eax
  10ad9e:	83 e8 04             	sub    $0x4,%eax
  10ada1:	8b 00                	mov    (%eax),%eax
  10ada3:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  10ada6:	89 c2                	mov    %eax,%edx
  10ada8:	c1 fa 1f             	sar    $0x1f,%edx
  10adab:	89 55 fc             	mov    %edx,0xfffffffc(%ebp)
  10adae:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10adb1:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
}
  10adb4:	c9                   	leave  
  10adb5:	c3                   	ret    

0010adb6 <putpad>:

// Print padding characters, and an optional sign before a number.
static void
putpad(printstate *st)
{
  10adb6:	55                   	push   %ebp
  10adb7:	89 e5                	mov    %esp,%ebp
  10adb9:	83 ec 08             	sub    $0x8,%esp
	while (--st->width >= 0)
  10adbc:	eb 1a                	jmp    10add8 <putpad+0x22>
		st->putch(st->padc, st->putdat);
  10adbe:	8b 45 08             	mov    0x8(%ebp),%eax
  10adc1:	8b 08                	mov    (%eax),%ecx
  10adc3:	8b 45 08             	mov    0x8(%ebp),%eax
  10adc6:	8b 50 04             	mov    0x4(%eax),%edx
  10adc9:	8b 45 08             	mov    0x8(%ebp),%eax
  10adcc:	8b 40 08             	mov    0x8(%eax),%eax
  10adcf:	89 54 24 04          	mov    %edx,0x4(%esp)
  10add3:	89 04 24             	mov    %eax,(%esp)
  10add6:	ff d1                	call   *%ecx
  10add8:	8b 45 08             	mov    0x8(%ebp),%eax
  10addb:	8b 40 0c             	mov    0xc(%eax),%eax
  10adde:	8d 50 ff             	lea    0xffffffff(%eax),%edx
  10ade1:	8b 45 08             	mov    0x8(%ebp),%eax
  10ade4:	89 50 0c             	mov    %edx,0xc(%eax)
  10ade7:	8b 45 08             	mov    0x8(%ebp),%eax
  10adea:	8b 40 0c             	mov    0xc(%eax),%eax
  10aded:	85 c0                	test   %eax,%eax
  10adef:	79 cd                	jns    10adbe <putpad+0x8>
}
  10adf1:	c9                   	leave  
  10adf2:	c3                   	ret    

0010adf3 <putstr>:

// Print a string with a specified maximum length (-1=unlimited),
// with any appropriate left or right field padding.
static void
putstr(printstate *st, const char *str, int maxlen)
{
  10adf3:	55                   	push   %ebp
  10adf4:	89 e5                	mov    %esp,%ebp
  10adf6:	53                   	push   %ebx
  10adf7:	83 ec 24             	sub    $0x24,%esp
	const char *lim;		// find where the string actually ends
	if (maxlen < 0)
  10adfa:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  10adfe:	79 18                	jns    10ae18 <putstr+0x25>
		lim = strchr(str, 0);	// find the terminating null
  10ae00:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  10ae07:	00 
  10ae08:	8b 45 0c             	mov    0xc(%ebp),%eax
  10ae0b:	89 04 24             	mov    %eax,(%esp)
  10ae0e:	e8 a2 09 00 00       	call   10b7b5 <strchr>
  10ae13:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
  10ae16:	eb 2c                	jmp    10ae44 <putstr+0x51>
	else if ((lim = memchr(str, 0, maxlen)) == NULL)
  10ae18:	8b 45 10             	mov    0x10(%ebp),%eax
  10ae1b:	89 44 24 08          	mov    %eax,0x8(%esp)
  10ae1f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  10ae26:	00 
  10ae27:	8b 45 0c             	mov    0xc(%ebp),%eax
  10ae2a:	89 04 24             	mov    %eax,(%esp)
  10ae2d:	e8 80 0b 00 00       	call   10b9b2 <memchr>
  10ae32:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
  10ae35:	83 7d f4 00          	cmpl   $0x0,0xfffffff4(%ebp)
  10ae39:	75 09                	jne    10ae44 <putstr+0x51>
		lim = str + maxlen;
  10ae3b:	8b 45 10             	mov    0x10(%ebp),%eax
  10ae3e:	03 45 0c             	add    0xc(%ebp),%eax
  10ae41:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	st->width -= (lim-str);		// deduct string length from field width
  10ae44:	8b 45 08             	mov    0x8(%ebp),%eax
  10ae47:	8b 48 0c             	mov    0xc(%eax),%ecx
  10ae4a:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  10ae4d:	8b 45 0c             	mov    0xc(%ebp),%eax
  10ae50:	89 d3                	mov    %edx,%ebx
  10ae52:	29 c3                	sub    %eax,%ebx
  10ae54:	89 d8                	mov    %ebx,%eax
  10ae56:	89 ca                	mov    %ecx,%edx
  10ae58:	29 c2                	sub    %eax,%edx
  10ae5a:	8b 45 08             	mov    0x8(%ebp),%eax
  10ae5d:	89 50 0c             	mov    %edx,0xc(%eax)

	if (!(st->flags & F_RPAD))	// print left-side padding
  10ae60:	8b 45 08             	mov    0x8(%ebp),%eax
  10ae63:	8b 40 18             	mov    0x18(%eax),%eax
  10ae66:	83 e0 10             	and    $0x10,%eax
  10ae69:	85 c0                	test   %eax,%eax
  10ae6b:	75 32                	jne    10ae9f <putstr+0xac>
		putpad(st);		// (also leaves st->width == 0)
  10ae6d:	8b 45 08             	mov    0x8(%ebp),%eax
  10ae70:	89 04 24             	mov    %eax,(%esp)
  10ae73:	e8 3e ff ff ff       	call   10adb6 <putpad>
	while (str < lim) {
  10ae78:	eb 25                	jmp    10ae9f <putstr+0xac>
		char ch = *str++;
  10ae7a:	8b 45 0c             	mov    0xc(%ebp),%eax
  10ae7d:	0f b6 00             	movzbl (%eax),%eax
  10ae80:	88 45 fb             	mov    %al,0xfffffffb(%ebp)
  10ae83:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
			st->putch(ch, st->putdat);
  10ae87:	8b 45 08             	mov    0x8(%ebp),%eax
  10ae8a:	8b 08                	mov    (%eax),%ecx
  10ae8c:	8b 45 08             	mov    0x8(%ebp),%eax
  10ae8f:	8b 40 04             	mov    0x4(%eax),%eax
  10ae92:	0f be 55 fb          	movsbl 0xfffffffb(%ebp),%edx
  10ae96:	89 44 24 04          	mov    %eax,0x4(%esp)
  10ae9a:	89 14 24             	mov    %edx,(%esp)
  10ae9d:	ff d1                	call   *%ecx
  10ae9f:	8b 45 0c             	mov    0xc(%ebp),%eax
  10aea2:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  10aea5:	72 d3                	jb     10ae7a <putstr+0x87>
	}
	putpad(st);			// print right-side padding
  10aea7:	8b 45 08             	mov    0x8(%ebp),%eax
  10aeaa:	89 04 24             	mov    %eax,(%esp)
  10aead:	e8 04 ff ff ff       	call   10adb6 <putpad>
}
  10aeb2:	83 c4 24             	add    $0x24,%esp
  10aeb5:	5b                   	pop    %ebx
  10aeb6:	5d                   	pop    %ebp
  10aeb7:	c3                   	ret    

0010aeb8 <genint>:

// Generate a number (base <= 16) in reverse order into a string buffer.
static char *
genint(printstate *st, char *p, uintmax_t num)
{
  10aeb8:	55                   	push   %ebp
  10aeb9:	89 e5                	mov    %esp,%ebp
  10aebb:	53                   	push   %ebx
  10aebc:	83 ec 24             	sub    $0x24,%esp
  10aebf:	8b 45 10             	mov    0x10(%ebp),%eax
  10aec2:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
  10aec5:	8b 45 14             	mov    0x14(%ebp),%eax
  10aec8:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= st->base)
  10aecb:	8b 45 08             	mov    0x8(%ebp),%eax
  10aece:	8b 40 1c             	mov    0x1c(%eax),%eax
  10aed1:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  10aed4:	89 c2                	mov    %eax,%edx
  10aed6:	c1 fa 1f             	sar    $0x1f,%edx
  10aed9:	89 55 ec             	mov    %edx,0xffffffec(%ebp)
  10aedc:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  10aedf:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  10aee2:	77 54                	ja     10af38 <genint+0x80>
  10aee4:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
  10aee7:	3b 55 f4             	cmp    0xfffffff4(%ebp),%edx
  10aeea:	72 08                	jb     10aef4 <genint+0x3c>
  10aeec:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  10aeef:	3b 45 f0             	cmp    0xfffffff0(%ebp),%eax
  10aef2:	77 44                	ja     10af38 <genint+0x80>
		p = genint(st, p, num / st->base);	// output higher digits
  10aef4:	8b 45 08             	mov    0x8(%ebp),%eax
  10aef7:	8b 40 1c             	mov    0x1c(%eax),%eax
  10aefa:	89 c2                	mov    %eax,%edx
  10aefc:	c1 fa 1f             	sar    $0x1f,%edx
  10aeff:	89 44 24 08          	mov    %eax,0x8(%esp)
  10af03:	89 54 24 0c          	mov    %edx,0xc(%esp)
  10af07:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  10af0a:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  10af0d:	89 04 24             	mov    %eax,(%esp)
  10af10:	89 54 24 04          	mov    %edx,0x4(%esp)
  10af14:	e8 e7 0a 00 00       	call   10ba00 <__udivdi3>
  10af19:	89 44 24 08          	mov    %eax,0x8(%esp)
  10af1d:	89 54 24 0c          	mov    %edx,0xc(%esp)
  10af21:	8b 45 0c             	mov    0xc(%ebp),%eax
  10af24:	89 44 24 04          	mov    %eax,0x4(%esp)
  10af28:	8b 45 08             	mov    0x8(%ebp),%eax
  10af2b:	89 04 24             	mov    %eax,(%esp)
  10af2e:	e8 85 ff ff ff       	call   10aeb8 <genint>
  10af33:	89 45 0c             	mov    %eax,0xc(%ebp)
  10af36:	eb 1b                	jmp    10af53 <genint+0x9b>
	else if (st->signc >= 0)
  10af38:	8b 45 08             	mov    0x8(%ebp),%eax
  10af3b:	8b 40 14             	mov    0x14(%eax),%eax
  10af3e:	85 c0                	test   %eax,%eax
  10af40:	78 11                	js     10af53 <genint+0x9b>
		*p++ = st->signc;			// output leading sign
  10af42:	8b 45 08             	mov    0x8(%ebp),%eax
  10af45:	8b 40 14             	mov    0x14(%eax),%eax
  10af48:	89 c2                	mov    %eax,%edx
  10af4a:	8b 45 0c             	mov    0xc(%ebp),%eax
  10af4d:	88 10                	mov    %dl,(%eax)
  10af4f:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
	*p++ = "0123456789abcdef"[num % st->base];	// output this digit
  10af53:	8b 45 08             	mov    0x8(%ebp),%eax
  10af56:	8b 40 1c             	mov    0x1c(%eax),%eax
  10af59:	89 c2                	mov    %eax,%edx
  10af5b:	c1 fa 1f             	sar    $0x1f,%edx
  10af5e:	8b 4d f0             	mov    0xfffffff0(%ebp),%ecx
  10af61:	8b 5d f4             	mov    0xfffffff4(%ebp),%ebx
  10af64:	89 44 24 08          	mov    %eax,0x8(%esp)
  10af68:	89 54 24 0c          	mov    %edx,0xc(%esp)
  10af6c:	89 0c 24             	mov    %ecx,(%esp)
  10af6f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  10af73:	e8 b8 0b 00 00       	call   10bb30 <__umoddi3>
  10af78:	05 ac db 10 00       	add    $0x10dbac,%eax
  10af7d:	0f b6 10             	movzbl (%eax),%edx
  10af80:	8b 45 0c             	mov    0xc(%ebp),%eax
  10af83:	88 10                	mov    %dl,(%eax)
  10af85:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
	return p;
  10af89:	8b 45 0c             	mov    0xc(%ebp),%eax
}
  10af8c:	83 c4 24             	add    $0x24,%esp
  10af8f:	5b                   	pop    %ebx
  10af90:	5d                   	pop    %ebp
  10af91:	c3                   	ret    

0010af92 <putint>:

// Print an integer with any appropriate field padding.
static void
putint(printstate *st, uintmax_t num, int base)
{
  10af92:	55                   	push   %ebp
  10af93:	89 e5                	mov    %esp,%ebp
  10af95:	83 ec 48             	sub    $0x48,%esp
  10af98:	8b 45 0c             	mov    0xc(%ebp),%eax
  10af9b:	89 45 c8             	mov    %eax,0xffffffc8(%ebp)
  10af9e:	8b 45 10             	mov    0x10(%ebp),%eax
  10afa1:	89 45 cc             	mov    %eax,0xffffffcc(%ebp)
	char buf[30], *p = buf;		// big enough for any 64-bit int in octal
  10afa4:	8d 45 de             	lea    0xffffffde(%ebp),%eax
  10afa7:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	st->base = base;		// select base for genint
  10afaa:	8b 55 08             	mov    0x8(%ebp),%edx
  10afad:	8b 45 14             	mov    0x14(%ebp),%eax
  10afb0:	89 42 1c             	mov    %eax,0x1c(%edx)
	p = genint(st, p, num);		// output to the string buffer
  10afb3:	8b 45 c8             	mov    0xffffffc8(%ebp),%eax
  10afb6:	8b 55 cc             	mov    0xffffffcc(%ebp),%edx
  10afb9:	89 44 24 08          	mov    %eax,0x8(%esp)
  10afbd:	89 54 24 0c          	mov    %edx,0xc(%esp)
  10afc1:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  10afc4:	89 44 24 04          	mov    %eax,0x4(%esp)
  10afc8:	8b 45 08             	mov    0x8(%ebp),%eax
  10afcb:	89 04 24             	mov    %eax,(%esp)
  10afce:	e8 e5 fe ff ff       	call   10aeb8 <genint>
  10afd3:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	putstr(st, buf, p-buf);		// print it with left/right padding
  10afd6:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  10afd9:	8d 45 de             	lea    0xffffffde(%ebp),%eax
  10afdc:	89 d1                	mov    %edx,%ecx
  10afde:	29 c1                	sub    %eax,%ecx
  10afe0:	89 c8                	mov    %ecx,%eax
  10afe2:	89 44 24 08          	mov    %eax,0x8(%esp)
  10afe6:	8d 45 de             	lea    0xffffffde(%ebp),%eax
  10afe9:	89 44 24 04          	mov    %eax,0x4(%esp)
  10afed:	8b 45 08             	mov    0x8(%ebp),%eax
  10aff0:	89 04 24             	mov    %eax,(%esp)
  10aff3:	e8 fb fd ff ff       	call   10adf3 <putstr>
}
  10aff8:	c9                   	leave  
  10aff9:	c3                   	ret    

0010affa <vprintfmt>:
/*
// Print the integer part of a floating-point number
static char *
genfint(printstate *st, char *p, double num)
{
	if (num >= 10.0)
		p = genfint(st, p, num / 10.0);	// recursively print higher digits
	else if (st->signc >= 0)
		*p++ = st->signc;		// optional sign before first digit
	*p++ = '0' + (int)fmod(num, 10.0);	// output this digit
	return p;
}
/
static char *
genfrac(printstate *st, char *p, double num, int fmtch)
{
	*p++ = '.';			// start with the '.'
	int rdig = st->prec < 0 ? 6 : st->prec;	 // digits to the right of the '.'
	num -= floor(num);		// get the fractional part only
	while (rdig-- > 0) {		// output 'rdig' fractional digits
		num *= 10.0;
		int dig = (int)num;
		*p++ = '0' + dig;
		num -= dig;
	}
	if (tolower(fmtch) == 'g')	// %g format removes trailing zeros
		while (p[-1] == '0')
			p--;
	if (p[-1] == '.' && !(st->flags & F_ALT))
		p--;			// no '.' if nothing after it, unless '#'
	return p;
}
//
// Print a floating-point number in simple '%f' floating-point notation.
static void
putfloat(printstate *st, double num, int l10, int fmtch)
{
	char buf[MAX(l10,0) + st->prec + 10], *p = buf;	// big enough output buffer
	p = genfint(st, p, num);			// sign and integer part
	p = genfrac(st, p, num, fmtch);			// '.' and fractional part
	putstr(st, buf, p-buf);				// print it with padding
}

// Print a floating-point number in exponential '%e' notation.
static void
putflexp(printstate *st, double num, int l10, int fmtch)
{
	num *= pow(10, -l10);			// shift num to correct position

	char buf[st->prec + 20], *p = buf;	// big enough output buffer
	p = genfint(st, p, num);		// generate sign and integer part
	p = genfrac(st, p, num, fmtch);		// generate '.' and fractional part

	*p++ = isupper(fmtch) ? 'E' : 'e';	// generate exponent
	st->signc = '+';
	if (l10 < 0)
		l10 = -l10, st->signc = '-';
	p = genint(st, p, l10 / 10);		// at least 2 digits
	*p++ = '0' + l10 % 10;

	putstr(st, buf, p-buf);			// print it all with field padding
}

// Print a floating-point number in general '%g' notation.
static void
putflgen(printstate *st, double num, int l10, int fmtch)
{
	// The precision in the format string counts significant figures.
	int sigfigs = (st->prec < 0) ? 6 : (st->prec == 0) ? 1 : st->prec;
	if (l10 < -4 || l10 >= st->prec) {	// Use exponential notation
		st->prec = sigfigs-1;
		putflexp(st, num, l10, fmtch);
	} else {				// Use simple decimal notation
		st->prec -= l10 + 1;
		putfloat(st, num, l10, fmtch);
	}
}

// Print a floating point infinity or NaN
static void
putfinf(printstate *st, const char *str)
{
	char buf[10], *p = buf;
	if (st->signc >= 0)
		*p++ = st->signc;		// leading sign
	strcpy(p, str);
	putstr(st, buf, -1);
}
#endif	// ! PIOS_KERNEL

*/
// Main function to format and print a string.
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  10affa:	55                   	push   %ebp
  10affb:	89 e5                	mov    %esp,%ebp
  10affd:	57                   	push   %edi
  10affe:	83 ec 54             	sub    $0x54,%esp
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
  10b001:	8d 7d c8             	lea    0xffffffc8(%ebp),%edi
  10b004:	fc                   	cld    
  10b005:	ba 00 00 00 00       	mov    $0x0,%edx
  10b00a:	b8 08 00 00 00       	mov    $0x8,%eax
  10b00f:	89 c1                	mov    %eax,%ecx
  10b011:	89 d0                	mov    %edx,%eax
  10b013:	f3 ab                	rep stos %eax,%es:(%edi)
  10b015:	8b 45 08             	mov    0x8(%ebp),%eax
  10b018:	89 45 c8             	mov    %eax,0xffffffc8(%ebp)
  10b01b:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b01e:	89 45 cc             	mov    %eax,0xffffffcc(%ebp)
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  10b021:	eb 1c                	jmp    10b03f <vprintfmt+0x45>
			if (ch == '\0')
  10b023:	83 7d c4 00          	cmpl   $0x0,0xffffffc4(%ebp)
  10b027:	0f 84 73 03 00 00    	je     10b3a0 <vprintfmt+0x3a6>
				return;
			putch(ch, putdat);
  10b02d:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b030:	89 44 24 04          	mov    %eax,0x4(%esp)
  10b034:	8b 55 c4             	mov    0xffffffc4(%ebp),%edx
  10b037:	89 14 24             	mov    %edx,(%esp)
  10b03a:	8b 45 08             	mov    0x8(%ebp),%eax
  10b03d:	ff d0                	call   *%eax
  10b03f:	8b 45 10             	mov    0x10(%ebp),%eax
  10b042:	0f b6 00             	movzbl (%eax),%eax
  10b045:	0f b6 c0             	movzbl %al,%eax
  10b048:	89 45 c4             	mov    %eax,0xffffffc4(%ebp)
  10b04b:	83 7d c4 25          	cmpl   $0x25,0xffffffc4(%ebp)
  10b04f:	0f 95 c0             	setne  %al
  10b052:	83 45 10 01          	addl   $0x1,0x10(%ebp)
  10b056:	84 c0                	test   %al,%al
  10b058:	75 c9                	jne    10b023 <vprintfmt+0x29>
		}

		// Process a %-escape sequence
		st.padc = ' ';
  10b05a:	c7 45 d0 20 00 00 00 	movl   $0x20,0xffffffd0(%ebp)
		st.width = -1;
  10b061:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,0xffffffd4(%ebp)
		st.prec = -1;
  10b068:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,0xffffffd8(%ebp)
		st.signc = -1;
  10b06f:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,0xffffffdc(%ebp)
		st.flags = 0;
  10b076:	c7 45 e0 00 00 00 00 	movl   $0x0,0xffffffe0(%ebp)
		st.base = 10;
  10b07d:	c7 45 e4 0a 00 00 00 	movl   $0xa,0xffffffe4(%ebp)
  10b084:	eb 00                	jmp    10b086 <vprintfmt+0x8c>
		uintmax_t num;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  10b086:	8b 45 10             	mov    0x10(%ebp),%eax
  10b089:	0f b6 00             	movzbl (%eax),%eax
  10b08c:	0f b6 c0             	movzbl %al,%eax
  10b08f:	89 45 c4             	mov    %eax,0xffffffc4(%ebp)
  10b092:	8b 45 c4             	mov    0xffffffc4(%ebp),%eax
  10b095:	83 45 10 01          	addl   $0x1,0x10(%ebp)
  10b099:	83 e8 20             	sub    $0x20,%eax
  10b09c:	89 45 b8             	mov    %eax,0xffffffb8(%ebp)
  10b09f:	83 7d b8 58          	cmpl   $0x58,0xffffffb8(%ebp)
  10b0a3:	0f 87 c8 02 00 00    	ja     10b371 <vprintfmt+0x377>
  10b0a9:	8b 55 b8             	mov    0xffffffb8(%ebp),%edx
  10b0ac:	8b 04 95 c4 db 10 00 	mov    0x10dbc4(,%edx,4),%eax
  10b0b3:	ff e0                	jmp    *%eax

		// modifier flags
		case '-': // pad on the right instead of the left
			st.flags |= F_RPAD;
  10b0b5:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  10b0b8:	83 c8 10             	or     $0x10,%eax
  10b0bb:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)
			goto reswitch;
  10b0be:	eb c6                	jmp    10b086 <vprintfmt+0x8c>

		case '+': // prefix positive numeric values with a '+' sign
			st.signc = '+';
  10b0c0:	c7 45 dc 2b 00 00 00 	movl   $0x2b,0xffffffdc(%ebp)
			goto reswitch;
  10b0c7:	eb bd                	jmp    10b086 <vprintfmt+0x8c>

		case ' ': // prefix signless numeric values with a space
			if (st.signc < 0)	// (but only if no '+' is specified)
  10b0c9:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  10b0cc:	85 c0                	test   %eax,%eax
  10b0ce:	79 b6                	jns    10b086 <vprintfmt+0x8c>
				st.signc = ' ';
  10b0d0:	c7 45 dc 20 00 00 00 	movl   $0x20,0xffffffdc(%ebp)
			goto reswitch;
  10b0d7:	eb ad                	jmp    10b086 <vprintfmt+0x8c>

		// width or precision field
		case '0':
			if (!(st.flags & F_DOT))
  10b0d9:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  10b0dc:	83 e0 08             	and    $0x8,%eax
  10b0df:	85 c0                	test   %eax,%eax
  10b0e1:	75 07                	jne    10b0ea <vprintfmt+0xf0>
				st.padc = '0'; // pad with 0's instead of spaces
  10b0e3:	c7 45 d0 30 00 00 00 	movl   $0x30,0xffffffd0(%ebp)
		case '1': case '2': case '3': case '4':
		case '5': case '6': case '7': case '8': case '9':
			for (st.prec = 0; ; ++fmt) {
  10b0ea:	c7 45 d8 00 00 00 00 	movl   $0x0,0xffffffd8(%ebp)
				st.prec = st.prec * 10 + ch - '0';
  10b0f1:	8b 55 d8             	mov    0xffffffd8(%ebp),%edx
  10b0f4:	89 d0                	mov    %edx,%eax
  10b0f6:	c1 e0 02             	shl    $0x2,%eax
  10b0f9:	01 d0                	add    %edx,%eax
  10b0fb:	01 c0                	add    %eax,%eax
  10b0fd:	03 45 c4             	add    0xffffffc4(%ebp),%eax
  10b100:	83 e8 30             	sub    $0x30,%eax
  10b103:	89 45 d8             	mov    %eax,0xffffffd8(%ebp)
				ch = *fmt;
  10b106:	8b 45 10             	mov    0x10(%ebp),%eax
  10b109:	0f b6 00             	movzbl (%eax),%eax
  10b10c:	0f be c0             	movsbl %al,%eax
  10b10f:	89 45 c4             	mov    %eax,0xffffffc4(%ebp)
				if (ch < '0' || ch > '9')
  10b112:	83 7d c4 2f          	cmpl   $0x2f,0xffffffc4(%ebp)
  10b116:	7e 20                	jle    10b138 <vprintfmt+0x13e>
  10b118:	83 7d c4 39          	cmpl   $0x39,0xffffffc4(%ebp)
  10b11c:	7f 1a                	jg     10b138 <vprintfmt+0x13e>
  10b11e:	83 45 10 01          	addl   $0x1,0x10(%ebp)
					break;
			}
  10b122:	eb cd                	jmp    10b0f1 <vprintfmt+0xf7>
			goto gotprec;

		case '*':
			st.prec = va_arg(ap, int);
  10b124:	8b 45 14             	mov    0x14(%ebp),%eax
  10b127:	83 c0 04             	add    $0x4,%eax
  10b12a:	89 45 14             	mov    %eax,0x14(%ebp)
  10b12d:	8b 45 14             	mov    0x14(%ebp),%eax
  10b130:	83 e8 04             	sub    $0x4,%eax
  10b133:	8b 00                	mov    (%eax),%eax
  10b135:	89 45 d8             	mov    %eax,0xffffffd8(%ebp)
		gotprec:
			if (!(st.flags & F_DOT)) {	// haven't seen a '.' yet?
  10b138:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  10b13b:	83 e0 08             	and    $0x8,%eax
  10b13e:	85 c0                	test   %eax,%eax
  10b140:	0f 85 40 ff ff ff    	jne    10b086 <vprintfmt+0x8c>
				st.width = st.prec;	// then it's a field width
  10b146:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  10b149:	89 45 d4             	mov    %eax,0xffffffd4(%ebp)
				st.prec = -1;
  10b14c:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,0xffffffd8(%ebp)
			}
			goto reswitch;
  10b153:	e9 2e ff ff ff       	jmp    10b086 <vprintfmt+0x8c>

		case '.':
			st.flags |= F_DOT;
  10b158:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  10b15b:	83 c8 08             	or     $0x8,%eax
  10b15e:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)
			goto reswitch;
  10b161:	e9 20 ff ff ff       	jmp    10b086 <vprintfmt+0x8c>

		case '#':
			st.flags |= F_ALT;
  10b166:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  10b169:	83 c8 04             	or     $0x4,%eax
  10b16c:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)
			goto reswitch;
  10b16f:	e9 12 ff ff ff       	jmp    10b086 <vprintfmt+0x8c>

		// long flag (doubled for long long)
		case 'l':
			st.flags |= (st.flags & F_L) ? F_LL : F_L;
  10b174:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  10b177:	89 45 bc             	mov    %eax,0xffffffbc(%ebp)
  10b17a:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  10b17d:	83 e0 01             	and    $0x1,%eax
  10b180:	84 c0                	test   %al,%al
  10b182:	74 09                	je     10b18d <vprintfmt+0x193>
  10b184:	c7 45 c0 02 00 00 00 	movl   $0x2,0xffffffc0(%ebp)
  10b18b:	eb 07                	jmp    10b194 <vprintfmt+0x19a>
  10b18d:	c7 45 c0 01 00 00 00 	movl   $0x1,0xffffffc0(%ebp)
  10b194:	8b 45 bc             	mov    0xffffffbc(%ebp),%eax
  10b197:	0b 45 c0             	or     0xffffffc0(%ebp),%eax
  10b19a:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)
			goto reswitch;
  10b19d:	e9 e4 fe ff ff       	jmp    10b086 <vprintfmt+0x8c>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  10b1a2:	8b 45 14             	mov    0x14(%ebp),%eax
  10b1a5:	83 c0 04             	add    $0x4,%eax
  10b1a8:	89 45 14             	mov    %eax,0x14(%ebp)
  10b1ab:	8b 45 14             	mov    0x14(%ebp),%eax
  10b1ae:	83 e8 04             	sub    $0x4,%eax
  10b1b1:	8b 10                	mov    (%eax),%edx
  10b1b3:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b1b6:	89 44 24 04          	mov    %eax,0x4(%esp)
  10b1ba:	89 14 24             	mov    %edx,(%esp)
  10b1bd:	8b 45 08             	mov    0x8(%ebp),%eax
  10b1c0:	ff d0                	call   *%eax
			break;
  10b1c2:	e9 78 fe ff ff       	jmp    10b03f <vprintfmt+0x45>

		// string
		case 's': {
			const char *s;
			if ((s = va_arg(ap, char *)) == NULL)
  10b1c7:	8b 45 14             	mov    0x14(%ebp),%eax
  10b1ca:	83 c0 04             	add    $0x4,%eax
  10b1cd:	89 45 14             	mov    %eax,0x14(%ebp)
  10b1d0:	8b 45 14             	mov    0x14(%ebp),%eax
  10b1d3:	83 e8 04             	sub    $0x4,%eax
  10b1d6:	8b 00                	mov    (%eax),%eax
  10b1d8:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
  10b1db:	83 7d f4 00          	cmpl   $0x0,0xfffffff4(%ebp)
  10b1df:	75 07                	jne    10b1e8 <vprintfmt+0x1ee>
				s = "(null)";
  10b1e1:	c7 45 f4 bd db 10 00 	movl   $0x10dbbd,0xfffffff4(%ebp)
			putstr(&st, s, st.prec);
  10b1e8:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  10b1eb:	89 44 24 08          	mov    %eax,0x8(%esp)
  10b1ef:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  10b1f2:	89 44 24 04          	mov    %eax,0x4(%esp)
  10b1f6:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
  10b1f9:	89 04 24             	mov    %eax,(%esp)
  10b1fc:	e8 f2 fb ff ff       	call   10adf3 <putstr>
			break;
  10b201:	e9 39 fe ff ff       	jmp    10b03f <vprintfmt+0x45>
		    }

		// (signed) decimal
		case 'd':
			num = getint(&st, &ap);
  10b206:	8d 45 14             	lea    0x14(%ebp),%eax
  10b209:	89 44 24 04          	mov    %eax,0x4(%esp)
  10b20d:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
  10b210:	89 04 24             	mov    %eax,(%esp)
  10b213:	e8 0e fb ff ff       	call   10ad26 <getint>
  10b218:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  10b21b:	89 55 ec             	mov    %edx,0xffffffec(%ebp)
			if ((intmax_t) num < 0) {
  10b21e:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  10b221:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
  10b224:	85 d2                	test   %edx,%edx
  10b226:	79 1a                	jns    10b242 <vprintfmt+0x248>
				num = -(intmax_t) num;
  10b228:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  10b22b:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
  10b22e:	f7 d8                	neg    %eax
  10b230:	83 d2 00             	adc    $0x0,%edx
  10b233:	f7 da                	neg    %edx
  10b235:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  10b238:	89 55 ec             	mov    %edx,0xffffffec(%ebp)
				st.signc = '-';
  10b23b:	c7 45 dc 2d 00 00 00 	movl   $0x2d,0xffffffdc(%ebp)
			}
			putint(&st, num, 10);
  10b242:	c7 44 24 0c 0a 00 00 	movl   $0xa,0xc(%esp)
  10b249:	00 
  10b24a:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  10b24d:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
  10b250:	89 44 24 04          	mov    %eax,0x4(%esp)
  10b254:	89 54 24 08          	mov    %edx,0x8(%esp)
  10b258:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
  10b25b:	89 04 24             	mov    %eax,(%esp)
  10b25e:	e8 2f fd ff ff       	call   10af92 <putint>
			break;
  10b263:	e9 d7 fd ff ff       	jmp    10b03f <vprintfmt+0x45>

		// unsigned decimal
		case 'u':
			putint(&st, getuint(&st, &ap), 10);
  10b268:	8d 45 14             	lea    0x14(%ebp),%eax
  10b26b:	89 44 24 04          	mov    %eax,0x4(%esp)
  10b26f:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
  10b272:	89 04 24             	mov    %eax,(%esp)
  10b275:	e8 1e fa ff ff       	call   10ac98 <getuint>
  10b27a:	c7 44 24 0c 0a 00 00 	movl   $0xa,0xc(%esp)
  10b281:	00 
  10b282:	89 44 24 04          	mov    %eax,0x4(%esp)
  10b286:	89 54 24 08          	mov    %edx,0x8(%esp)
  10b28a:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
  10b28d:	89 04 24             	mov    %eax,(%esp)
  10b290:	e8 fd fc ff ff       	call   10af92 <putint>
			break;
  10b295:	e9 a5 fd ff ff       	jmp    10b03f <vprintfmt+0x45>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putint(&st, getuint(&st, &ap), 8);
  10b29a:	8d 45 14             	lea    0x14(%ebp),%eax
  10b29d:	89 44 24 04          	mov    %eax,0x4(%esp)
  10b2a1:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
  10b2a4:	89 04 24             	mov    %eax,(%esp)
  10b2a7:	e8 ec f9 ff ff       	call   10ac98 <getuint>
  10b2ac:	c7 44 24 0c 08 00 00 	movl   $0x8,0xc(%esp)
  10b2b3:	00 
  10b2b4:	89 44 24 04          	mov    %eax,0x4(%esp)
  10b2b8:	89 54 24 08          	mov    %edx,0x8(%esp)
  10b2bc:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
  10b2bf:	89 04 24             	mov    %eax,(%esp)
  10b2c2:	e8 cb fc ff ff       	call   10af92 <putint>
			break;
  10b2c7:	e9 73 fd ff ff       	jmp    10b03f <vprintfmt+0x45>

		// (unsigned) hexadecimal
		case 'x':
			putint(&st, getuint(&st, &ap), 16);
  10b2cc:	8d 45 14             	lea    0x14(%ebp),%eax
  10b2cf:	89 44 24 04          	mov    %eax,0x4(%esp)
  10b2d3:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
  10b2d6:	89 04 24             	mov    %eax,(%esp)
  10b2d9:	e8 ba f9 ff ff       	call   10ac98 <getuint>
  10b2de:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
  10b2e5:	00 
  10b2e6:	89 44 24 04          	mov    %eax,0x4(%esp)
  10b2ea:	89 54 24 08          	mov    %edx,0x8(%esp)
  10b2ee:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
  10b2f1:	89 04 24             	mov    %eax,(%esp)
  10b2f4:	e8 99 fc ff ff       	call   10af92 <putint>
			break;
  10b2f9:	e9 41 fd ff ff       	jmp    10b03f <vprintfmt+0x45>

		// pointer
		case 'p':
			putch('0', putdat);
  10b2fe:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b301:	89 44 24 04          	mov    %eax,0x4(%esp)
  10b305:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  10b30c:	8b 45 08             	mov    0x8(%ebp),%eax
  10b30f:	ff d0                	call   *%eax
			putch('x', putdat);
  10b311:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b314:	89 44 24 04          	mov    %eax,0x4(%esp)
  10b318:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  10b31f:	8b 45 08             	mov    0x8(%ebp),%eax
  10b322:	ff d0                	call   *%eax
			putint(&st, (uintptr_t) va_arg(ap, void *), 16);
  10b324:	8b 45 14             	mov    0x14(%ebp),%eax
  10b327:	83 c0 04             	add    $0x4,%eax
  10b32a:	89 45 14             	mov    %eax,0x14(%ebp)
  10b32d:	8b 45 14             	mov    0x14(%ebp),%eax
  10b330:	83 e8 04             	sub    $0x4,%eax
  10b333:	8b 00                	mov    (%eax),%eax
  10b335:	ba 00 00 00 00       	mov    $0x0,%edx
  10b33a:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
  10b341:	00 
  10b342:	89 44 24 04          	mov    %eax,0x4(%esp)
  10b346:	89 54 24 08          	mov    %edx,0x8(%esp)
  10b34a:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
  10b34d:	89 04 24             	mov    %eax,(%esp)
  10b350:	e8 3d fc ff ff       	call   10af92 <putint>
			break;
  10b355:	e9 e5 fc ff ff       	jmp    10b03f <vprintfmt+0x45>
/*
		// floating-point
		case 'f': case 'F':
		case 'e': case 'E':	// XXX should be different from %f
		case 'g': case 'G': {	// XXX should be different from %f
			int variant = tolower(ch);	// which format variant?
			double val = va_arg(ap, double);	// number to print
			if (val < 0) {			// handle the sign
				val = -val;
				st.signc = '-';
			}
			if (isinf(val))			// handle infinities
				putfinf(&st, isupper(ch) ? "INF" : "inf");
			else if (isnan(val))		// handle NANs
				putfinf(&st, isupper(ch) ? "NAN" : "nan");
			else if (variant == 'f')	// simple decimal format
				putfloat(&st, val, floor(log10(val)), ch);
			else if (variant == 'e')	// exponential format
				putflexp(&st, val, floor(log10(val)), ch);
			else if (variant == 'g')	// general/mixed format
				putflgen(&st, val, floor(log10(val)), ch);
			break;
		    }
*/
		// escaped '%' character
		case '%':
			putch(ch, putdat);
  10b35a:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b35d:	89 44 24 04          	mov    %eax,0x4(%esp)
  10b361:	8b 55 c4             	mov    0xffffffc4(%ebp),%edx
  10b364:	89 14 24             	mov    %edx,(%esp)
  10b367:	8b 45 08             	mov    0x8(%ebp),%eax
  10b36a:	ff d0                	call   *%eax
			break;
  10b36c:	e9 ce fc ff ff       	jmp    10b03f <vprintfmt+0x45>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  10b371:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b374:	89 44 24 04          	mov    %eax,0x4(%esp)
  10b378:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  10b37f:	8b 45 08             	mov    0x8(%ebp),%eax
  10b382:	ff d0                	call   *%eax
			for (fmt--; fmt[-1] != '%'; fmt--)
  10b384:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  10b388:	eb 04                	jmp    10b38e <vprintfmt+0x394>
  10b38a:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  10b38e:	8b 45 10             	mov    0x10(%ebp),%eax
  10b391:	83 e8 01             	sub    $0x1,%eax
  10b394:	0f b6 00             	movzbl (%eax),%eax
  10b397:	3c 25                	cmp    $0x25,%al
  10b399:	75 ef                	jne    10b38a <vprintfmt+0x390>
				/* do nothing */;
			break;
		}
	}
  10b39b:	e9 9f fc ff ff       	jmp    10b03f <vprintfmt+0x45>
}
  10b3a0:	83 c4 54             	add    $0x54,%esp
  10b3a3:	5f                   	pop    %edi
  10b3a4:	5d                   	pop    %ebp
  10b3a5:	c3                   	ret    
  10b3a6:	90                   	nop    
  10b3a7:	90                   	nop    

0010b3a8 <putch>:


static void
putch(int ch, struct printbuf *b)
{
  10b3a8:	55                   	push   %ebp
  10b3a9:	89 e5                	mov    %esp,%ebp
  10b3ab:	83 ec 08             	sub    $0x8,%esp
	b->buf[b->idx++] = ch;
  10b3ae:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b3b1:	8b 08                	mov    (%eax),%ecx
  10b3b3:	8b 45 08             	mov    0x8(%ebp),%eax
  10b3b6:	89 c2                	mov    %eax,%edx
  10b3b8:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b3bb:	88 54 08 08          	mov    %dl,0x8(%eax,%ecx,1)
  10b3bf:	8d 51 01             	lea    0x1(%ecx),%edx
  10b3c2:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b3c5:	89 10                	mov    %edx,(%eax)
	if (b->idx == CPUTS_MAX-1) {
  10b3c7:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b3ca:	8b 00                	mov    (%eax),%eax
  10b3cc:	3d ff 00 00 00       	cmp    $0xff,%eax
  10b3d1:	75 24                	jne    10b3f7 <putch+0x4f>
		b->buf[b->idx] = 0;
  10b3d3:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b3d6:	8b 10                	mov    (%eax),%edx
  10b3d8:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b3db:	c6 44 10 08 00       	movb   $0x0,0x8(%eax,%edx,1)
		cputs(b->buf);
  10b3e0:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b3e3:	83 c0 08             	add    $0x8,%eax
  10b3e6:	89 04 24             	mov    %eax,(%esp)
  10b3e9:	e8 5f 53 ff ff       	call   10074d <cputs>
		b->idx = 0;
  10b3ee:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b3f1:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	}
	b->cnt++;
  10b3f7:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b3fa:	8b 40 04             	mov    0x4(%eax),%eax
  10b3fd:	8d 50 01             	lea    0x1(%eax),%edx
  10b400:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b403:	89 50 04             	mov    %edx,0x4(%eax)
}
  10b406:	c9                   	leave  
  10b407:	c3                   	ret    

0010b408 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  10b408:	55                   	push   %ebp
  10b409:	89 e5                	mov    %esp,%ebp
  10b40b:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  10b411:	c7 85 f8 fe ff ff 00 	movl   $0x0,0xfffffef8(%ebp)
  10b418:	00 00 00 
	b.cnt = 0;
  10b41b:	c7 85 fc fe ff ff 00 	movl   $0x0,0xfffffefc(%ebp)
  10b422:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  10b425:	ba a8 b3 10 00       	mov    $0x10b3a8,%edx
  10b42a:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b42d:	89 44 24 0c          	mov    %eax,0xc(%esp)
  10b431:	8b 45 08             	mov    0x8(%ebp),%eax
  10b434:	89 44 24 08          	mov    %eax,0x8(%esp)
  10b438:	8d 85 f8 fe ff ff    	lea    0xfffffef8(%ebp),%eax
  10b43e:	89 44 24 04          	mov    %eax,0x4(%esp)
  10b442:	89 14 24             	mov    %edx,(%esp)
  10b445:	e8 b0 fb ff ff       	call   10affa <vprintfmt>

	b.buf[b.idx] = 0;
  10b44a:	8b 85 f8 fe ff ff    	mov    0xfffffef8(%ebp),%eax
  10b450:	c6 84 05 00 ff ff ff 	movb   $0x0,0xffffff00(%ebp,%eax,1)
  10b457:	00 
	cputs(b.buf);
  10b458:	8d 85 f8 fe ff ff    	lea    0xfffffef8(%ebp),%eax
  10b45e:	83 c0 08             	add    $0x8,%eax
  10b461:	89 04 24             	mov    %eax,(%esp)
  10b464:	e8 e4 52 ff ff       	call   10074d <cputs>

	return b.cnt;
  10b469:	8b 85 fc fe ff ff    	mov    0xfffffefc(%ebp),%eax
}
  10b46f:	c9                   	leave  
  10b470:	c3                   	ret    

0010b471 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  10b471:	55                   	push   %ebp
  10b472:	89 e5                	mov    %esp,%ebp
  10b474:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  10b477:	8d 45 08             	lea    0x8(%ebp),%eax
  10b47a:	83 c0 04             	add    $0x4,%eax
  10b47d:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
	cnt = vcprintf(fmt, ap);
  10b480:	8b 55 08             	mov    0x8(%ebp),%edx
  10b483:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10b486:	89 44 24 04          	mov    %eax,0x4(%esp)
  10b48a:	89 14 24             	mov    %edx,(%esp)
  10b48d:	e8 76 ff ff ff       	call   10b408 <vcprintf>
  10b492:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	va_end(ap);

	return cnt;
  10b495:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
}
  10b498:	c9                   	leave  
  10b499:	c3                   	ret    
  10b49a:	90                   	nop    
  10b49b:	90                   	nop    

0010b49c <sprintputch>:
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  10b49c:	55                   	push   %ebp
  10b49d:	89 e5                	mov    %esp,%ebp
	b->cnt++;
  10b49f:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b4a2:	8b 40 08             	mov    0x8(%eax),%eax
  10b4a5:	8d 50 01             	lea    0x1(%eax),%edx
  10b4a8:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b4ab:	89 50 08             	mov    %edx,0x8(%eax)
	if (b->buf < b->ebuf)
  10b4ae:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b4b1:	8b 10                	mov    (%eax),%edx
  10b4b3:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b4b6:	8b 40 04             	mov    0x4(%eax),%eax
  10b4b9:	39 c2                	cmp    %eax,%edx
  10b4bb:	73 12                	jae    10b4cf <sprintputch+0x33>
		*b->buf++ = ch;
  10b4bd:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b4c0:	8b 10                	mov    (%eax),%edx
  10b4c2:	8b 45 08             	mov    0x8(%ebp),%eax
  10b4c5:	88 02                	mov    %al,(%edx)
  10b4c7:	83 c2 01             	add    $0x1,%edx
  10b4ca:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b4cd:	89 10                	mov    %edx,(%eax)
}
  10b4cf:	5d                   	pop    %ebp
  10b4d0:	c3                   	ret    

0010b4d1 <vsprintf>:

int
vsprintf(char *buf, const char *fmt, va_list ap)
{
  10b4d1:	55                   	push   %ebp
  10b4d2:	89 e5                	mov    %esp,%ebp
  10b4d4:	83 ec 28             	sub    $0x28,%esp
	assert(buf != NULL);
  10b4d7:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  10b4db:	75 24                	jne    10b501 <vsprintf+0x30>
  10b4dd:	c7 44 24 0c 28 dd 10 	movl   $0x10dd28,0xc(%esp)
  10b4e4:	00 
  10b4e5:	c7 44 24 08 34 dd 10 	movl   $0x10dd34,0x8(%esp)
  10b4ec:	00 
  10b4ed:	c7 44 24 04 19 00 00 	movl   $0x19,0x4(%esp)
  10b4f4:	00 
  10b4f5:	c7 04 24 49 dd 10 00 	movl   $0x10dd49,(%esp)
  10b4fc:	e8 67 54 ff ff       	call   100968 <debug_panic>
	struct sprintbuf b = {buf, (char*)(intptr_t)~0, 0};
  10b501:	8b 45 08             	mov    0x8(%ebp),%eax
  10b504:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
  10b507:	c7 45 f8 ff ff ff ff 	movl   $0xffffffff,0xfffffff8(%ebp)
  10b50e:	c7 45 fc 00 00 00 00 	movl   $0x0,0xfffffffc(%ebp)

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  10b515:	ba 9c b4 10 00       	mov    $0x10b49c,%edx
  10b51a:	8b 45 10             	mov    0x10(%ebp),%eax
  10b51d:	89 44 24 0c          	mov    %eax,0xc(%esp)
  10b521:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b524:	89 44 24 08          	mov    %eax,0x8(%esp)
  10b528:	8d 45 f4             	lea    0xfffffff4(%ebp),%eax
  10b52b:	89 44 24 04          	mov    %eax,0x4(%esp)
  10b52f:	89 14 24             	mov    %edx,(%esp)
  10b532:	e8 c3 fa ff ff       	call   10affa <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  10b537:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  10b53a:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  10b53d:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
}
  10b540:	c9                   	leave  
  10b541:	c3                   	ret    

0010b542 <sprintf>:

int
sprintf(char *buf, const char *fmt, ...)
{
  10b542:	55                   	push   %ebp
  10b543:	89 e5                	mov    %esp,%ebp
  10b545:	83 ec 28             	sub    $0x28,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  10b548:	8d 45 0c             	lea    0xc(%ebp),%eax
  10b54b:	83 c0 04             	add    $0x4,%eax
  10b54e:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
	rc = vsprintf(buf, fmt, ap);
  10b551:	8b 55 0c             	mov    0xc(%ebp),%edx
  10b554:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10b557:	89 44 24 08          	mov    %eax,0x8(%esp)
  10b55b:	89 54 24 04          	mov    %edx,0x4(%esp)
  10b55f:	8b 45 08             	mov    0x8(%ebp),%eax
  10b562:	89 04 24             	mov    %eax,(%esp)
  10b565:	e8 67 ff ff ff       	call   10b4d1 <vsprintf>
  10b56a:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	va_end(ap);

	return rc;
  10b56d:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
}
  10b570:	c9                   	leave  
  10b571:	c3                   	ret    

0010b572 <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  10b572:	55                   	push   %ebp
  10b573:	89 e5                	mov    %esp,%ebp
  10b575:	83 ec 28             	sub    $0x28,%esp
	assert(buf != NULL && n > 0);
  10b578:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  10b57c:	74 06                	je     10b584 <vsnprintf+0x12>
  10b57e:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  10b582:	7f 24                	jg     10b5a8 <vsnprintf+0x36>
  10b584:	c7 44 24 0c 57 dd 10 	movl   $0x10dd57,0xc(%esp)
  10b58b:	00 
  10b58c:	c7 44 24 08 34 dd 10 	movl   $0x10dd34,0x8(%esp)
  10b593:	00 
  10b594:	c7 44 24 04 35 00 00 	movl   $0x35,0x4(%esp)
  10b59b:	00 
  10b59c:	c7 04 24 49 dd 10 00 	movl   $0x10dd49,(%esp)
  10b5a3:	e8 c0 53 ff ff       	call   100968 <debug_panic>
	struct sprintbuf b = {buf, buf+n-1, 0};
  10b5a8:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b5ab:	03 45 08             	add    0x8(%ebp),%eax
  10b5ae:	8d 50 ff             	lea    0xffffffff(%eax),%edx
  10b5b1:	8b 45 08             	mov    0x8(%ebp),%eax
  10b5b4:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
  10b5b7:	89 55 f8             	mov    %edx,0xfffffff8(%ebp)
  10b5ba:	c7 45 fc 00 00 00 00 	movl   $0x0,0xfffffffc(%ebp)

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  10b5c1:	ba 9c b4 10 00       	mov    $0x10b49c,%edx
  10b5c6:	8b 45 14             	mov    0x14(%ebp),%eax
  10b5c9:	89 44 24 0c          	mov    %eax,0xc(%esp)
  10b5cd:	8b 45 10             	mov    0x10(%ebp),%eax
  10b5d0:	89 44 24 08          	mov    %eax,0x8(%esp)
  10b5d4:	8d 45 f4             	lea    0xfffffff4(%ebp),%eax
  10b5d7:	89 44 24 04          	mov    %eax,0x4(%esp)
  10b5db:	89 14 24             	mov    %edx,(%esp)
  10b5de:	e8 17 fa ff ff       	call   10affa <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  10b5e3:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  10b5e6:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  10b5e9:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
}
  10b5ec:	c9                   	leave  
  10b5ed:	c3                   	ret    

0010b5ee <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  10b5ee:	55                   	push   %ebp
  10b5ef:	89 e5                	mov    %esp,%ebp
  10b5f1:	83 ec 28             	sub    $0x28,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  10b5f4:	8d 45 10             	lea    0x10(%ebp),%eax
  10b5f7:	83 c0 04             	add    $0x4,%eax
  10b5fa:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
	rc = vsnprintf(buf, n, fmt, ap);
  10b5fd:	8b 55 10             	mov    0x10(%ebp),%edx
  10b600:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10b603:	89 44 24 0c          	mov    %eax,0xc(%esp)
  10b607:	89 54 24 08          	mov    %edx,0x8(%esp)
  10b60b:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b60e:	89 44 24 04          	mov    %eax,0x4(%esp)
  10b612:	8b 45 08             	mov    0x8(%ebp),%eax
  10b615:	89 04 24             	mov    %eax,(%esp)
  10b618:	e8 55 ff ff ff       	call   10b572 <vsnprintf>
  10b61d:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	va_end(ap);

	return rc;
  10b620:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
}
  10b623:	c9                   	leave  
  10b624:	c3                   	ret    
  10b625:	90                   	nop    
  10b626:	90                   	nop    
  10b627:	90                   	nop    

0010b628 <strlen>:
#define ASM 1

int
strlen(const char *s)
{
  10b628:	55                   	push   %ebp
  10b629:	89 e5                	mov    %esp,%ebp
  10b62b:	83 ec 10             	sub    $0x10,%esp
	int n;

	for (n = 0; *s != '\0'; s++)
  10b62e:	c7 45 fc 00 00 00 00 	movl   $0x0,0xfffffffc(%ebp)
  10b635:	eb 08                	jmp    10b63f <strlen+0x17>
		n++;
  10b637:	83 45 fc 01          	addl   $0x1,0xfffffffc(%ebp)
  10b63b:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  10b63f:	8b 45 08             	mov    0x8(%ebp),%eax
  10b642:	0f b6 00             	movzbl (%eax),%eax
  10b645:	84 c0                	test   %al,%al
  10b647:	75 ee                	jne    10b637 <strlen+0xf>
	return n;
  10b649:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
}
  10b64c:	c9                   	leave  
  10b64d:	c3                   	ret    

0010b64e <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  10b64e:	55                   	push   %ebp
  10b64f:	89 e5                	mov    %esp,%ebp
  10b651:	83 ec 10             	sub    $0x10,%esp
	char *ret;

	ret = dst;
  10b654:	8b 45 08             	mov    0x8(%ebp),%eax
  10b657:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	while ((*dst++ = *src++) != '\0')
  10b65a:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b65d:	0f b6 10             	movzbl (%eax),%edx
  10b660:	8b 45 08             	mov    0x8(%ebp),%eax
  10b663:	88 10                	mov    %dl,(%eax)
  10b665:	8b 45 08             	mov    0x8(%ebp),%eax
  10b668:	0f b6 00             	movzbl (%eax),%eax
  10b66b:	84 c0                	test   %al,%al
  10b66d:	0f 95 c0             	setne  %al
  10b670:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  10b674:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
  10b678:	84 c0                	test   %al,%al
  10b67a:	75 de                	jne    10b65a <strcpy+0xc>
		/* do nothing */;
	return ret;
  10b67c:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
}
  10b67f:	c9                   	leave  
  10b680:	c3                   	ret    

0010b681 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size)
{
  10b681:	55                   	push   %ebp
  10b682:	89 e5                	mov    %esp,%ebp
  10b684:	83 ec 10             	sub    $0x10,%esp
	size_t i;
	char *ret;

	ret = dst;
  10b687:	8b 45 08             	mov    0x8(%ebp),%eax
  10b68a:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	for (i = 0; i < size; i++) {
  10b68d:	c7 45 f8 00 00 00 00 	movl   $0x0,0xfffffff8(%ebp)
  10b694:	eb 21                	jmp    10b6b7 <strncpy+0x36>
		*dst++ = *src;
  10b696:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b699:	0f b6 10             	movzbl (%eax),%edx
  10b69c:	8b 45 08             	mov    0x8(%ebp),%eax
  10b69f:	88 10                	mov    %dl,(%eax)
  10b6a1:	83 45 08 01          	addl   $0x1,0x8(%ebp)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
  10b6a5:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b6a8:	0f b6 00             	movzbl (%eax),%eax
  10b6ab:	84 c0                	test   %al,%al
  10b6ad:	74 04                	je     10b6b3 <strncpy+0x32>
			src++;
  10b6af:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
  10b6b3:	83 45 f8 01          	addl   $0x1,0xfffffff8(%ebp)
  10b6b7:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10b6ba:	3b 45 10             	cmp    0x10(%ebp),%eax
  10b6bd:	72 d7                	jb     10b696 <strncpy+0x15>
	}
	return ret;
  10b6bf:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
}
  10b6c2:	c9                   	leave  
  10b6c3:	c3                   	ret    

0010b6c4 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  10b6c4:	55                   	push   %ebp
  10b6c5:	89 e5                	mov    %esp,%ebp
  10b6c7:	83 ec 10             	sub    $0x10,%esp
	char *dst_in;

	dst_in = dst;
  10b6ca:	8b 45 08             	mov    0x8(%ebp),%eax
  10b6cd:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	if (size > 0) {
  10b6d0:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  10b6d4:	74 2f                	je     10b705 <strlcpy+0x41>
		while (--size > 0 && *src != '\0')
  10b6d6:	eb 13                	jmp    10b6eb <strlcpy+0x27>
			*dst++ = *src++;
  10b6d8:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b6db:	0f b6 10             	movzbl (%eax),%edx
  10b6de:	8b 45 08             	mov    0x8(%ebp),%eax
  10b6e1:	88 10                	mov    %dl,(%eax)
  10b6e3:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  10b6e7:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
  10b6eb:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  10b6ef:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  10b6f3:	74 0a                	je     10b6ff <strlcpy+0x3b>
  10b6f5:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b6f8:	0f b6 00             	movzbl (%eax),%eax
  10b6fb:	84 c0                	test   %al,%al
  10b6fd:	75 d9                	jne    10b6d8 <strlcpy+0x14>
		*dst = '\0';
  10b6ff:	8b 45 08             	mov    0x8(%ebp),%eax
  10b702:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  10b705:	8b 55 08             	mov    0x8(%ebp),%edx
  10b708:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  10b70b:	89 d1                	mov    %edx,%ecx
  10b70d:	29 c1                	sub    %eax,%ecx
  10b70f:	89 c8                	mov    %ecx,%eax
}
  10b711:	c9                   	leave  
  10b712:	c3                   	ret    

0010b713 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  10b713:	55                   	push   %ebp
  10b714:	89 e5                	mov    %esp,%ebp
	while (*p && *p == *q)
  10b716:	eb 08                	jmp    10b720 <strcmp+0xd>
		p++, q++;
  10b718:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  10b71c:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
  10b720:	8b 45 08             	mov    0x8(%ebp),%eax
  10b723:	0f b6 00             	movzbl (%eax),%eax
  10b726:	84 c0                	test   %al,%al
  10b728:	74 10                	je     10b73a <strcmp+0x27>
  10b72a:	8b 45 08             	mov    0x8(%ebp),%eax
  10b72d:	0f b6 10             	movzbl (%eax),%edx
  10b730:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b733:	0f b6 00             	movzbl (%eax),%eax
  10b736:	38 c2                	cmp    %al,%dl
  10b738:	74 de                	je     10b718 <strcmp+0x5>
	return (int) ((unsigned char) *p - (unsigned char) *q);
  10b73a:	8b 45 08             	mov    0x8(%ebp),%eax
  10b73d:	0f b6 00             	movzbl (%eax),%eax
  10b740:	0f b6 d0             	movzbl %al,%edx
  10b743:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b746:	0f b6 00             	movzbl (%eax),%eax
  10b749:	0f b6 c0             	movzbl %al,%eax
  10b74c:	89 d1                	mov    %edx,%ecx
  10b74e:	29 c1                	sub    %eax,%ecx
  10b750:	89 c8                	mov    %ecx,%eax
}
  10b752:	5d                   	pop    %ebp
  10b753:	c3                   	ret    

0010b754 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  10b754:	55                   	push   %ebp
  10b755:	89 e5                	mov    %esp,%ebp
  10b757:	83 ec 04             	sub    $0x4,%esp
	while (n > 0 && *p && *p == *q)
  10b75a:	eb 0c                	jmp    10b768 <strncmp+0x14>
		n--, p++, q++;
  10b75c:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  10b760:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  10b764:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
  10b768:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  10b76c:	74 1a                	je     10b788 <strncmp+0x34>
  10b76e:	8b 45 08             	mov    0x8(%ebp),%eax
  10b771:	0f b6 00             	movzbl (%eax),%eax
  10b774:	84 c0                	test   %al,%al
  10b776:	74 10                	je     10b788 <strncmp+0x34>
  10b778:	8b 45 08             	mov    0x8(%ebp),%eax
  10b77b:	0f b6 10             	movzbl (%eax),%edx
  10b77e:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b781:	0f b6 00             	movzbl (%eax),%eax
  10b784:	38 c2                	cmp    %al,%dl
  10b786:	74 d4                	je     10b75c <strncmp+0x8>
	if (n == 0)
  10b788:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  10b78c:	75 09                	jne    10b797 <strncmp+0x43>
		return 0;
  10b78e:	c7 45 fc 00 00 00 00 	movl   $0x0,0xfffffffc(%ebp)
  10b795:	eb 19                	jmp    10b7b0 <strncmp+0x5c>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  10b797:	8b 45 08             	mov    0x8(%ebp),%eax
  10b79a:	0f b6 00             	movzbl (%eax),%eax
  10b79d:	0f b6 d0             	movzbl %al,%edx
  10b7a0:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b7a3:	0f b6 00             	movzbl (%eax),%eax
  10b7a6:	0f b6 c0             	movzbl %al,%eax
  10b7a9:	89 d1                	mov    %edx,%ecx
  10b7ab:	29 c1                	sub    %eax,%ecx
  10b7ad:	89 4d fc             	mov    %ecx,0xfffffffc(%ebp)
  10b7b0:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
}
  10b7b3:	c9                   	leave  
  10b7b4:	c3                   	ret    

0010b7b5 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  10b7b5:	55                   	push   %ebp
  10b7b6:	89 e5                	mov    %esp,%ebp
  10b7b8:	83 ec 08             	sub    $0x8,%esp
  10b7bb:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b7be:	88 45 fc             	mov    %al,0xfffffffc(%ebp)
	while (*s != c)
  10b7c1:	eb 1c                	jmp    10b7df <strchr+0x2a>
		if (*s++ == 0)
  10b7c3:	8b 45 08             	mov    0x8(%ebp),%eax
  10b7c6:	0f b6 00             	movzbl (%eax),%eax
  10b7c9:	84 c0                	test   %al,%al
  10b7cb:	0f 94 c0             	sete   %al
  10b7ce:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  10b7d2:	84 c0                	test   %al,%al
  10b7d4:	74 09                	je     10b7df <strchr+0x2a>
			return NULL;
  10b7d6:	c7 45 f8 00 00 00 00 	movl   $0x0,0xfffffff8(%ebp)
  10b7dd:	eb 11                	jmp    10b7f0 <strchr+0x3b>
  10b7df:	8b 45 08             	mov    0x8(%ebp),%eax
  10b7e2:	0f b6 00             	movzbl (%eax),%eax
  10b7e5:	3a 45 fc             	cmp    0xfffffffc(%ebp),%al
  10b7e8:	75 d9                	jne    10b7c3 <strchr+0xe>
	return (char *) s;
  10b7ea:	8b 45 08             	mov    0x8(%ebp),%eax
  10b7ed:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  10b7f0:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
}
  10b7f3:	c9                   	leave  
  10b7f4:	c3                   	ret    

0010b7f5 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  10b7f5:	55                   	push   %ebp
  10b7f6:	89 e5                	mov    %esp,%ebp
  10b7f8:	57                   	push   %edi
  10b7f9:	83 ec 14             	sub    $0x14,%esp
	char *p;

	if (n == 0)
  10b7fc:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  10b800:	75 08                	jne    10b80a <memset+0x15>
		return v;
  10b802:	8b 45 08             	mov    0x8(%ebp),%eax
  10b805:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  10b808:	eb 5b                	jmp    10b865 <memset+0x70>
	if ((int)v%4 == 0 && n%4 == 0) {
  10b80a:	8b 45 08             	mov    0x8(%ebp),%eax
  10b80d:	83 e0 03             	and    $0x3,%eax
  10b810:	85 c0                	test   %eax,%eax
  10b812:	75 3f                	jne    10b853 <memset+0x5e>
  10b814:	8b 45 10             	mov    0x10(%ebp),%eax
  10b817:	83 e0 03             	and    $0x3,%eax
  10b81a:	85 c0                	test   %eax,%eax
  10b81c:	75 35                	jne    10b853 <memset+0x5e>
		c &= 0xFF;
  10b81e:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
		c = (c<<24)|(c<<16)|(c<<8)|c;
  10b825:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b828:	89 c2                	mov    %eax,%edx
  10b82a:	c1 e2 18             	shl    $0x18,%edx
  10b82d:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b830:	c1 e0 10             	shl    $0x10,%eax
  10b833:	09 c2                	or     %eax,%edx
  10b835:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b838:	c1 e0 08             	shl    $0x8,%eax
  10b83b:	09 d0                	or     %edx,%eax
  10b83d:	09 45 0c             	or     %eax,0xc(%ebp)
		asm volatile("cld; rep stosl\n"
  10b840:	8b 45 10             	mov    0x10(%ebp),%eax
  10b843:	89 c1                	mov    %eax,%ecx
  10b845:	c1 e9 02             	shr    $0x2,%ecx
  10b848:	8b 7d 08             	mov    0x8(%ebp),%edi
  10b84b:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b84e:	fc                   	cld    
  10b84f:	f3 ab                	rep stos %eax,%es:(%edi)
  10b851:	eb 0c                	jmp    10b85f <memset+0x6a>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  10b853:	8b 7d 08             	mov    0x8(%ebp),%edi
  10b856:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b859:	8b 4d 10             	mov    0x10(%ebp),%ecx
  10b85c:	fc                   	cld    
  10b85d:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
  10b85f:	8b 45 08             	mov    0x8(%ebp),%eax
  10b862:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  10b865:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
}
  10b868:	83 c4 14             	add    $0x14,%esp
  10b86b:	5f                   	pop    %edi
  10b86c:	5d                   	pop    %ebp
  10b86d:	c3                   	ret    

0010b86e <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  10b86e:	55                   	push   %ebp
  10b86f:	89 e5                	mov    %esp,%ebp
  10b871:	57                   	push   %edi
  10b872:	56                   	push   %esi
  10b873:	83 ec 10             	sub    $0x10,%esp
	const char *s;
	char *d;
	
	s = src;
  10b876:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b879:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
	d = dst;
  10b87c:	8b 45 08             	mov    0x8(%ebp),%eax
  10b87f:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	if (s < d && s + n > d) {
  10b882:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  10b885:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  10b888:	73 63                	jae    10b8ed <memmove+0x7f>
  10b88a:	8b 45 10             	mov    0x10(%ebp),%eax
  10b88d:	03 45 f0             	add    0xfffffff0(%ebp),%eax
  10b890:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  10b893:	76 58                	jbe    10b8ed <memmove+0x7f>
		s += n;
  10b895:	8b 45 10             	mov    0x10(%ebp),%eax
  10b898:	01 45 f0             	add    %eax,0xfffffff0(%ebp)
		d += n;
  10b89b:	8b 45 10             	mov    0x10(%ebp),%eax
  10b89e:	01 45 f4             	add    %eax,0xfffffff4(%ebp)
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  10b8a1:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  10b8a4:	83 e0 03             	and    $0x3,%eax
  10b8a7:	85 c0                	test   %eax,%eax
  10b8a9:	75 2d                	jne    10b8d8 <memmove+0x6a>
  10b8ab:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  10b8ae:	83 e0 03             	and    $0x3,%eax
  10b8b1:	85 c0                	test   %eax,%eax
  10b8b3:	75 23                	jne    10b8d8 <memmove+0x6a>
  10b8b5:	8b 45 10             	mov    0x10(%ebp),%eax
  10b8b8:	83 e0 03             	and    $0x3,%eax
  10b8bb:	85 c0                	test   %eax,%eax
  10b8bd:	75 19                	jne    10b8d8 <memmove+0x6a>
			asm volatile("std; rep movsl\n"
  10b8bf:	8b 7d f4             	mov    0xfffffff4(%ebp),%edi
  10b8c2:	83 ef 04             	sub    $0x4,%edi
  10b8c5:	8b 75 f0             	mov    0xfffffff0(%ebp),%esi
  10b8c8:	83 ee 04             	sub    $0x4,%esi
  10b8cb:	8b 45 10             	mov    0x10(%ebp),%eax
  10b8ce:	89 c1                	mov    %eax,%ecx
  10b8d0:	c1 e9 02             	shr    $0x2,%ecx
  10b8d3:	fd                   	std    
  10b8d4:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  10b8d6:	eb 12                	jmp    10b8ea <memmove+0x7c>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  10b8d8:	8b 7d f4             	mov    0xfffffff4(%ebp),%edi
  10b8db:	83 ef 01             	sub    $0x1,%edi
  10b8de:	8b 75 f0             	mov    0xfffffff0(%ebp),%esi
  10b8e1:	83 ee 01             	sub    $0x1,%esi
  10b8e4:	8b 4d 10             	mov    0x10(%ebp),%ecx
  10b8e7:	fd                   	std    
  10b8e8:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  10b8ea:	fc                   	cld    
  10b8eb:	eb 3d                	jmp    10b92a <memmove+0xbc>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  10b8ed:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  10b8f0:	83 e0 03             	and    $0x3,%eax
  10b8f3:	85 c0                	test   %eax,%eax
  10b8f5:	75 27                	jne    10b91e <memmove+0xb0>
  10b8f7:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  10b8fa:	83 e0 03             	and    $0x3,%eax
  10b8fd:	85 c0                	test   %eax,%eax
  10b8ff:	75 1d                	jne    10b91e <memmove+0xb0>
  10b901:	8b 45 10             	mov    0x10(%ebp),%eax
  10b904:	83 e0 03             	and    $0x3,%eax
  10b907:	85 c0                	test   %eax,%eax
  10b909:	75 13                	jne    10b91e <memmove+0xb0>
			asm volatile("cld; rep movsl\n"
  10b90b:	8b 45 10             	mov    0x10(%ebp),%eax
  10b90e:	89 c1                	mov    %eax,%ecx
  10b910:	c1 e9 02             	shr    $0x2,%ecx
  10b913:	8b 7d f4             	mov    0xfffffff4(%ebp),%edi
  10b916:	8b 75 f0             	mov    0xfffffff0(%ebp),%esi
  10b919:	fc                   	cld    
  10b91a:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  10b91c:	eb 0c                	jmp    10b92a <memmove+0xbc>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  10b91e:	8b 7d f4             	mov    0xfffffff4(%ebp),%edi
  10b921:	8b 75 f0             	mov    0xfffffff0(%ebp),%esi
  10b924:	8b 4d 10             	mov    0x10(%ebp),%ecx
  10b927:	fc                   	cld    
  10b928:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
  10b92a:	8b 45 08             	mov    0x8(%ebp),%eax
}
  10b92d:	83 c4 10             	add    $0x10,%esp
  10b930:	5e                   	pop    %esi
  10b931:	5f                   	pop    %edi
  10b932:	5d                   	pop    %ebp
  10b933:	c3                   	ret    

0010b934 <memcpy>:

#else

void *
memset(void *v, int c, size_t n)
{
	char *p;
	int m;

	p = v;
	m = n;
	while (--m >= 0)
		*p++ = c;

	return v;
}

void *
memmove(void *dst, const void *src, size_t n)
{
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		while (n-- > 0)
			*--d = *--s;
	} else
		while (n-- > 0)
			*d++ = *s++;

	return dst;
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  10b934:	55                   	push   %ebp
  10b935:	89 e5                	mov    %esp,%ebp
  10b937:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
  10b93a:	8b 45 10             	mov    0x10(%ebp),%eax
  10b93d:	89 44 24 08          	mov    %eax,0x8(%esp)
  10b941:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b944:	89 44 24 04          	mov    %eax,0x4(%esp)
  10b948:	8b 45 08             	mov    0x8(%ebp),%eax
  10b94b:	89 04 24             	mov    %eax,(%esp)
  10b94e:	e8 1b ff ff ff       	call   10b86e <memmove>
}
  10b953:	c9                   	leave  
  10b954:	c3                   	ret    

0010b955 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  10b955:	55                   	push   %ebp
  10b956:	89 e5                	mov    %esp,%ebp
  10b958:	83 ec 14             	sub    $0x14,%esp
	const uint8_t *s1 = (const uint8_t *) v1;
  10b95b:	8b 45 08             	mov    0x8(%ebp),%eax
  10b95e:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
	const uint8_t *s2 = (const uint8_t *) v2;
  10b961:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b964:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)

	while (n-- > 0) {
  10b967:	eb 33                	jmp    10b99c <memcmp+0x47>
		if (*s1 != *s2)
  10b969:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10b96c:	0f b6 10             	movzbl (%eax),%edx
  10b96f:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  10b972:	0f b6 00             	movzbl (%eax),%eax
  10b975:	38 c2                	cmp    %al,%dl
  10b977:	74 1b                	je     10b994 <memcmp+0x3f>
			return (int) *s1 - (int) *s2;
  10b979:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10b97c:	0f b6 00             	movzbl (%eax),%eax
  10b97f:	0f b6 d0             	movzbl %al,%edx
  10b982:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  10b985:	0f b6 00             	movzbl (%eax),%eax
  10b988:	0f b6 c0             	movzbl %al,%eax
  10b98b:	89 d1                	mov    %edx,%ecx
  10b98d:	29 c1                	sub    %eax,%ecx
  10b98f:	89 4d ec             	mov    %ecx,0xffffffec(%ebp)
  10b992:	eb 19                	jmp    10b9ad <memcmp+0x58>
		s1++, s2++;
  10b994:	83 45 f8 01          	addl   $0x1,0xfffffff8(%ebp)
  10b998:	83 45 fc 01          	addl   $0x1,0xfffffffc(%ebp)
  10b99c:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  10b9a0:	83 7d 10 ff          	cmpl   $0xffffffff,0x10(%ebp)
  10b9a4:	75 c3                	jne    10b969 <memcmp+0x14>
	}

	return 0;
  10b9a6:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  10b9ad:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
}
  10b9b0:	c9                   	leave  
  10b9b1:	c3                   	ret    

0010b9b2 <memchr>:

void *
memchr(const void *s, int c, size_t n)
{
  10b9b2:	55                   	push   %ebp
  10b9b3:	89 e5                	mov    %esp,%ebp
  10b9b5:	83 ec 14             	sub    $0x14,%esp
	const void *ends = (const char *) s + n;
  10b9b8:	8b 45 08             	mov    0x8(%ebp),%eax
  10b9bb:	8b 55 10             	mov    0x10(%ebp),%edx
  10b9be:	01 d0                	add    %edx,%eax
  10b9c0:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	for (; s < ends; s++)
  10b9c3:	eb 19                	jmp    10b9de <memchr+0x2c>
		if (*(const unsigned char *) s == (unsigned char) c)
  10b9c5:	8b 45 08             	mov    0x8(%ebp),%eax
  10b9c8:	0f b6 10             	movzbl (%eax),%edx
  10b9cb:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b9ce:	38 c2                	cmp    %al,%dl
  10b9d0:	75 08                	jne    10b9da <memchr+0x28>
			return (void *) s;
  10b9d2:	8b 45 08             	mov    0x8(%ebp),%eax
  10b9d5:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  10b9d8:	eb 13                	jmp    10b9ed <memchr+0x3b>
  10b9da:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  10b9de:	8b 45 08             	mov    0x8(%ebp),%eax
  10b9e1:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  10b9e4:	72 df                	jb     10b9c5 <memchr+0x13>
	return NULL;
  10b9e6:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  10b9ed:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
}
  10b9f0:	c9                   	leave  
  10b9f1:	c3                   	ret    
  10b9f2:	90                   	nop    
  10b9f3:	90                   	nop    
  10b9f4:	90                   	nop    
  10b9f5:	90                   	nop    
  10b9f6:	90                   	nop    
  10b9f7:	90                   	nop    
  10b9f8:	90                   	nop    
  10b9f9:	90                   	nop    
  10b9fa:	90                   	nop    
  10b9fb:	90                   	nop    
  10b9fc:	90                   	nop    
  10b9fd:	90                   	nop    
  10b9fe:	90                   	nop    
  10b9ff:	90                   	nop    

0010ba00 <__udivdi3>:
  10ba00:	55                   	push   %ebp
  10ba01:	89 e5                	mov    %esp,%ebp
  10ba03:	57                   	push   %edi
  10ba04:	56                   	push   %esi
  10ba05:	83 ec 1c             	sub    $0x1c,%esp
  10ba08:	8b 45 10             	mov    0x10(%ebp),%eax
  10ba0b:	8b 55 14             	mov    0x14(%ebp),%edx
  10ba0e:	8b 7d 0c             	mov    0xc(%ebp),%edi
  10ba11:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
  10ba14:	89 c1                	mov    %eax,%ecx
  10ba16:	8b 45 08             	mov    0x8(%ebp),%eax
  10ba19:	85 d2                	test   %edx,%edx
  10ba1b:	89 d6                	mov    %edx,%esi
  10ba1d:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  10ba20:	75 1e                	jne    10ba40 <__udivdi3+0x40>
  10ba22:	39 f9                	cmp    %edi,%ecx
  10ba24:	0f 86 8d 00 00 00    	jbe    10bab7 <__udivdi3+0xb7>
  10ba2a:	89 fa                	mov    %edi,%edx
  10ba2c:	f7 f1                	div    %ecx
  10ba2e:	89 c1                	mov    %eax,%ecx
  10ba30:	89 c8                	mov    %ecx,%eax
  10ba32:	89 f2                	mov    %esi,%edx
  10ba34:	83 c4 1c             	add    $0x1c,%esp
  10ba37:	5e                   	pop    %esi
  10ba38:	5f                   	pop    %edi
  10ba39:	5d                   	pop    %ebp
  10ba3a:	c3                   	ret    
  10ba3b:	90                   	nop    
  10ba3c:	8d 74 26 00          	lea    0x0(%esi),%esi
  10ba40:	39 fa                	cmp    %edi,%edx
  10ba42:	0f 87 98 00 00 00    	ja     10bae0 <__udivdi3+0xe0>
  10ba48:	0f bd c2             	bsr    %edx,%eax
  10ba4b:	83 f0 1f             	xor    $0x1f,%eax
  10ba4e:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
  10ba51:	74 7f                	je     10bad2 <__udivdi3+0xd2>
  10ba53:	b8 20 00 00 00       	mov    $0x20,%eax
  10ba58:	8b 55 f0             	mov    0xfffffff0(%ebp),%edx
  10ba5b:	2b 45 e4             	sub    0xffffffe4(%ebp),%eax
  10ba5e:	89 c1                	mov    %eax,%ecx
  10ba60:	d3 ea                	shr    %cl,%edx
  10ba62:	0f b6 4d e4          	movzbl 0xffffffe4(%ebp),%ecx
  10ba66:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  10ba69:	89 f0                	mov    %esi,%eax
  10ba6b:	d3 e0                	shl    %cl,%eax
  10ba6d:	09 c2                	or     %eax,%edx
  10ba6f:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  10ba72:	89 55 e0             	mov    %edx,0xffffffe0(%ebp)
  10ba75:	89 fa                	mov    %edi,%edx
  10ba77:	d3 e0                	shl    %cl,%eax
  10ba79:	0f b6 4d ec          	movzbl 0xffffffec(%ebp),%ecx
  10ba7d:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
  10ba80:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  10ba83:	d3 e8                	shr    %cl,%eax
  10ba85:	0f b6 4d e4          	movzbl 0xffffffe4(%ebp),%ecx
  10ba89:	d3 e2                	shl    %cl,%edx
  10ba8b:	0f b6 4d ec          	movzbl 0xffffffec(%ebp),%ecx
  10ba8f:	09 d0                	or     %edx,%eax
  10ba91:	d3 ef                	shr    %cl,%edi
  10ba93:	89 fa                	mov    %edi,%edx
  10ba95:	f7 75 e0             	divl   0xffffffe0(%ebp)
  10ba98:	89 d1                	mov    %edx,%ecx
  10ba9a:	89 c7                	mov    %eax,%edi
  10ba9c:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  10ba9f:	f7 e7                	mul    %edi
  10baa1:	39 d1                	cmp    %edx,%ecx
  10baa3:	89 c6                	mov    %eax,%esi
  10baa5:	89 55 dc             	mov    %edx,0xffffffdc(%ebp)
  10baa8:	72 6f                	jb     10bb19 <__udivdi3+0x119>
  10baaa:	39 ca                	cmp    %ecx,%edx
  10baac:	74 5e                	je     10bb0c <__udivdi3+0x10c>
  10baae:	89 f9                	mov    %edi,%ecx
  10bab0:	31 f6                	xor    %esi,%esi
  10bab2:	e9 79 ff ff ff       	jmp    10ba30 <__udivdi3+0x30>
  10bab7:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  10baba:	85 c0                	test   %eax,%eax
  10babc:	74 32                	je     10baf0 <__udivdi3+0xf0>
  10babe:	89 f2                	mov    %esi,%edx
  10bac0:	89 f8                	mov    %edi,%eax
  10bac2:	f7 f1                	div    %ecx
  10bac4:	89 c6                	mov    %eax,%esi
  10bac6:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  10bac9:	f7 f1                	div    %ecx
  10bacb:	89 c1                	mov    %eax,%ecx
  10bacd:	e9 5e ff ff ff       	jmp    10ba30 <__udivdi3+0x30>
  10bad2:	39 d7                	cmp    %edx,%edi
  10bad4:	77 2a                	ja     10bb00 <__udivdi3+0x100>
  10bad6:	8b 55 f0             	mov    0xfffffff0(%ebp),%edx
  10bad9:	39 55 e8             	cmp    %edx,0xffffffe8(%ebp)
  10badc:	73 22                	jae    10bb00 <__udivdi3+0x100>
  10bade:	66 90                	xchg   %ax,%ax
  10bae0:	31 c9                	xor    %ecx,%ecx
  10bae2:	31 f6                	xor    %esi,%esi
  10bae4:	e9 47 ff ff ff       	jmp    10ba30 <__udivdi3+0x30>
  10bae9:	8d b4 26 00 00 00 00 	lea    0x0(%esi),%esi
  10baf0:	b8 01 00 00 00       	mov    $0x1,%eax
  10baf5:	31 d2                	xor    %edx,%edx
  10baf7:	f7 75 f0             	divl   0xfffffff0(%ebp)
  10bafa:	89 c1                	mov    %eax,%ecx
  10bafc:	eb c0                	jmp    10babe <__udivdi3+0xbe>
  10bafe:	66 90                	xchg   %ax,%ax
  10bb00:	b9 01 00 00 00       	mov    $0x1,%ecx
  10bb05:	31 f6                	xor    %esi,%esi
  10bb07:	e9 24 ff ff ff       	jmp    10ba30 <__udivdi3+0x30>
  10bb0c:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  10bb0f:	0f b6 4d e4          	movzbl 0xffffffe4(%ebp),%ecx
  10bb13:	d3 e0                	shl    %cl,%eax
  10bb15:	39 c6                	cmp    %eax,%esi
  10bb17:	76 95                	jbe    10baae <__udivdi3+0xae>
  10bb19:	8d 4f ff             	lea    0xffffffff(%edi),%ecx
  10bb1c:	31 f6                	xor    %esi,%esi
  10bb1e:	e9 0d ff ff ff       	jmp    10ba30 <__udivdi3+0x30>
  10bb23:	90                   	nop    
  10bb24:	90                   	nop    
  10bb25:	90                   	nop    
  10bb26:	90                   	nop    
  10bb27:	90                   	nop    
  10bb28:	90                   	nop    
  10bb29:	90                   	nop    
  10bb2a:	90                   	nop    
  10bb2b:	90                   	nop    
  10bb2c:	90                   	nop    
  10bb2d:	90                   	nop    
  10bb2e:	90                   	nop    
  10bb2f:	90                   	nop    

0010bb30 <__umoddi3>:
  10bb30:	55                   	push   %ebp
  10bb31:	89 e5                	mov    %esp,%ebp
  10bb33:	57                   	push   %edi
  10bb34:	56                   	push   %esi
  10bb35:	83 ec 30             	sub    $0x30,%esp
  10bb38:	8b 55 14             	mov    0x14(%ebp),%edx
  10bb3b:	8b 45 10             	mov    0x10(%ebp),%eax
  10bb3e:	8b 75 08             	mov    0x8(%ebp),%esi
  10bb41:	8b 7d 0c             	mov    0xc(%ebp),%edi
  10bb44:	85 d2                	test   %edx,%edx
  10bb46:	c7 45 d0 00 00 00 00 	movl   $0x0,0xffffffd0(%ebp)
  10bb4d:	89 c1                	mov    %eax,%ecx
  10bb4f:	c7 45 d4 00 00 00 00 	movl   $0x0,0xffffffd4(%ebp)
  10bb56:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  10bb59:	89 55 e8             	mov    %edx,0xffffffe8(%ebp)
  10bb5c:	89 75 f0             	mov    %esi,0xfffffff0(%ebp)
  10bb5f:	89 7d e0             	mov    %edi,0xffffffe0(%ebp)
  10bb62:	75 1c                	jne    10bb80 <__umoddi3+0x50>
  10bb64:	39 f8                	cmp    %edi,%eax
  10bb66:	89 fa                	mov    %edi,%edx
  10bb68:	0f 86 d4 00 00 00    	jbe    10bc42 <__umoddi3+0x112>
  10bb6e:	89 f0                	mov    %esi,%eax
  10bb70:	f7 f1                	div    %ecx
  10bb72:	89 55 d0             	mov    %edx,0xffffffd0(%ebp)
  10bb75:	c7 45 d4 00 00 00 00 	movl   $0x0,0xffffffd4(%ebp)
  10bb7c:	eb 12                	jmp    10bb90 <__umoddi3+0x60>
  10bb7e:	66 90                	xchg   %ax,%ax
  10bb80:	8b 4d e0             	mov    0xffffffe0(%ebp),%ecx
  10bb83:	39 4d e8             	cmp    %ecx,0xffffffe8(%ebp)
  10bb86:	76 18                	jbe    10bba0 <__umoddi3+0x70>
  10bb88:	89 75 d0             	mov    %esi,0xffffffd0(%ebp)
  10bb8b:	89 7d d4             	mov    %edi,0xffffffd4(%ebp)
  10bb8e:	66 90                	xchg   %ax,%ax
  10bb90:	8b 45 d0             	mov    0xffffffd0(%ebp),%eax
  10bb93:	8b 55 d4             	mov    0xffffffd4(%ebp),%edx
  10bb96:	83 c4 30             	add    $0x30,%esp
  10bb99:	5e                   	pop    %esi
  10bb9a:	5f                   	pop    %edi
  10bb9b:	5d                   	pop    %ebp
  10bb9c:	c3                   	ret    
  10bb9d:	8d 76 00             	lea    0x0(%esi),%esi
  10bba0:	0f bd 45 e8          	bsr    0xffffffe8(%ebp),%eax
  10bba4:	83 f0 1f             	xor    $0x1f,%eax
  10bba7:	89 45 dc             	mov    %eax,0xffffffdc(%ebp)
  10bbaa:	0f 84 c0 00 00 00    	je     10bc70 <__umoddi3+0x140>
  10bbb0:	b8 20 00 00 00       	mov    $0x20,%eax
  10bbb5:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
  10bbb8:	2b 45 dc             	sub    0xffffffdc(%ebp),%eax
  10bbbb:	8b 7d ec             	mov    0xffffffec(%ebp),%edi
  10bbbe:	8b 75 f0             	mov    0xfffffff0(%ebp),%esi
  10bbc1:	89 c1                	mov    %eax,%ecx
  10bbc3:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
  10bbc6:	d3 ea                	shr    %cl,%edx
  10bbc8:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  10bbcb:	0f b6 4d dc          	movzbl 0xffffffdc(%ebp),%ecx
  10bbcf:	d3 e0                	shl    %cl,%eax
  10bbd1:	09 c2                	or     %eax,%edx
  10bbd3:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  10bbd6:	d3 e7                	shl    %cl,%edi
  10bbd8:	0f b6 4d e4          	movzbl 0xffffffe4(%ebp),%ecx
  10bbdc:	89 55 f4             	mov    %edx,0xfffffff4(%ebp)
  10bbdf:	8b 55 e0             	mov    0xffffffe0(%ebp),%edx
  10bbe2:	d3 e8                	shr    %cl,%eax
  10bbe4:	0f b6 4d dc          	movzbl 0xffffffdc(%ebp),%ecx
  10bbe8:	d3 e2                	shl    %cl,%edx
  10bbea:	09 d0                	or     %edx,%eax
  10bbec:	8b 55 e0             	mov    0xffffffe0(%ebp),%edx
  10bbef:	d3 e6                	shl    %cl,%esi
  10bbf1:	0f b6 4d e4          	movzbl 0xffffffe4(%ebp),%ecx
  10bbf5:	d3 ea                	shr    %cl,%edx
  10bbf7:	f7 75 f4             	divl   0xfffffff4(%ebp)
  10bbfa:	89 55 cc             	mov    %edx,0xffffffcc(%ebp)
  10bbfd:	f7 e7                	mul    %edi
  10bbff:	39 55 cc             	cmp    %edx,0xffffffcc(%ebp)
  10bc02:	0f 82 a5 00 00 00    	jb     10bcad <__umoddi3+0x17d>
  10bc08:	3b 55 cc             	cmp    0xffffffcc(%ebp),%edx
  10bc0b:	0f 84 94 00 00 00    	je     10bca5 <__umoddi3+0x175>
  10bc11:	8b 4d cc             	mov    0xffffffcc(%ebp),%ecx
  10bc14:	29 c6                	sub    %eax,%esi
  10bc16:	19 d1                	sbb    %edx,%ecx
  10bc18:	89 4d cc             	mov    %ecx,0xffffffcc(%ebp)
  10bc1b:	0f b6 4d dc          	movzbl 0xffffffdc(%ebp),%ecx
  10bc1f:	89 f2                	mov    %esi,%edx
  10bc21:	8b 45 cc             	mov    0xffffffcc(%ebp),%eax
  10bc24:	d3 ea                	shr    %cl,%edx
  10bc26:	0f b6 4d e4          	movzbl 0xffffffe4(%ebp),%ecx
  10bc2a:	d3 e0                	shl    %cl,%eax
  10bc2c:	0f b6 4d dc          	movzbl 0xffffffdc(%ebp),%ecx
  10bc30:	09 c2                	or     %eax,%edx
  10bc32:	8b 45 cc             	mov    0xffffffcc(%ebp),%eax
  10bc35:	89 55 d0             	mov    %edx,0xffffffd0(%ebp)
  10bc38:	d3 e8                	shr    %cl,%eax
  10bc3a:	89 45 d4             	mov    %eax,0xffffffd4(%ebp)
  10bc3d:	e9 4e ff ff ff       	jmp    10bb90 <__umoddi3+0x60>
  10bc42:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  10bc45:	85 c0                	test   %eax,%eax
  10bc47:	74 17                	je     10bc60 <__umoddi3+0x130>
  10bc49:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  10bc4c:	8b 55 e8             	mov    0xffffffe8(%ebp),%edx
  10bc4f:	f7 f1                	div    %ecx
  10bc51:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  10bc54:	f7 f1                	div    %ecx
  10bc56:	e9 17 ff ff ff       	jmp    10bb72 <__umoddi3+0x42>
  10bc5b:	90                   	nop    
  10bc5c:	8d 74 26 00          	lea    0x0(%esi),%esi
  10bc60:	b8 01 00 00 00       	mov    $0x1,%eax
  10bc65:	31 d2                	xor    %edx,%edx
  10bc67:	f7 75 ec             	divl   0xffffffec(%ebp)
  10bc6a:	89 c1                	mov    %eax,%ecx
  10bc6c:	eb db                	jmp    10bc49 <__umoddi3+0x119>
  10bc6e:	66 90                	xchg   %ax,%ax
  10bc70:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  10bc73:	39 45 e0             	cmp    %eax,0xffffffe0(%ebp)
  10bc76:	77 19                	ja     10bc91 <__umoddi3+0x161>
  10bc78:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
  10bc7b:	39 55 f0             	cmp    %edx,0xfffffff0(%ebp)
  10bc7e:	73 11                	jae    10bc91 <__umoddi3+0x161>
  10bc80:	8b 55 f0             	mov    0xfffffff0(%ebp),%edx
  10bc83:	8b 4d e0             	mov    0xffffffe0(%ebp),%ecx
  10bc86:	89 55 d0             	mov    %edx,0xffffffd0(%ebp)
  10bc89:	89 4d d4             	mov    %ecx,0xffffffd4(%ebp)
  10bc8c:	e9 ff fe ff ff       	jmp    10bb90 <__umoddi3+0x60>
  10bc91:	8b 4d e0             	mov    0xffffffe0(%ebp),%ecx
  10bc94:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  10bc97:	2b 45 ec             	sub    0xffffffec(%ebp),%eax
  10bc9a:	1b 4d e8             	sbb    0xffffffe8(%ebp),%ecx
  10bc9d:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
  10bca0:	89 4d e0             	mov    %ecx,0xffffffe0(%ebp)
  10bca3:	eb db                	jmp    10bc80 <__umoddi3+0x150>
  10bca5:	39 f0                	cmp    %esi,%eax
  10bca7:	0f 86 64 ff ff ff    	jbe    10bc11 <__umoddi3+0xe1>
  10bcad:	29 f8                	sub    %edi,%eax
  10bcaf:	1b 55 f4             	sbb    0xfffffff4(%ebp),%edx
  10bcb2:	e9 5a ff ff ff       	jmp    10bc11 <__umoddi3+0xe1>
