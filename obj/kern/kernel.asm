
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
  10002f:	e8 25 04 00 00       	call   100459 <cpu_onboot>
  100034:	85 c0                	test   %eax,%eax
  100036:	74 28                	je     100060 <init+0x38>
		memset(edata, 0, end - edata);
  100038:	ba 08 20 18 00       	mov    $0x182008,%edx
  10003d:	b8 3f 8e 17 00       	mov    $0x178e3f,%eax
  100042:	89 d1                	mov    %edx,%ecx
  100044:	29 c1                	sub    %eax,%ecx
  100046:	89 c8                	mov    %ecx,%eax
  100048:	89 44 24 08          	mov    %eax,0x8(%esp)
  10004c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  100053:	00 
  100054:	c7 04 24 3f 8e 17 00 	movl   $0x178e3f,(%esp)
  10005b:	e8 a9 b7 00 00       	call   10b809 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
  100060:	e8 d1 05 00 00       	call   100636 <cons_init>

  extern uint8_t _binary_obj_boot_bootother_start[],
    _binary_obj_boot_bootother_size[];

  uint8_t *code = (uint8_t*)lowmem_bootother_vec;
  100065:	c7 45 b0 00 10 00 00 	movl   $0x1000,0xffffffb0(%ebp)
  memmove(code, _binary_obj_boot_bootother_start, (uint32_t) _binary_obj_boot_bootother_size);
  10006c:	b8 6a 00 00 00       	mov    $0x6a,%eax
  100071:	89 44 24 08          	mov    %eax,0x8(%esp)
  100075:	c7 44 24 04 d5 8d 17 	movl   $0x178dd5,0x4(%esp)
  10007c:	00 
  10007d:	8b 45 b0             	mov    0xffffffb0(%ebp),%eax
  100080:	89 04 24             	mov    %eax,(%esp)
  100083:	e8 fa b7 00 00       	call   10b882 <memmove>

	// Lab 1: test cprintf and debug_trace
//	cprintf("1234 decimal is %o octal!\n", 1234);
//	debug_check();

	// Initialize and load the bootstrap CPU's GDT, TSS, and IDT.
	cpu_init();
  100088:	e8 1f 15 00 00       	call   1015ac <cpu_init>
	trap_init();
  10008d:	e8 80 2b 00 00       	call   102c12 <trap_init>

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
  1000a0:	e8 ba 3b 00 00       	call   103c5f <spinlock_check>

	// Initialize the paged virtual memory system.
	pmap_init();
  1000a5:	e8 9a 5a 00 00       	call   105b44 <pmap_init>

	// Find and start other processors in a multiprocessor system
	mp_init();		// Find info about processors in system
  1000aa:	e8 b0 37 00 00       	call   10385f <mp_init>
	pic_init();		// setup the legacy PIC (mainly to disable it)
  1000af:	e8 78 a4 00 00       	call   10a52c <pic_init>
	ioapic_init();		// prepare to handle external device interrupts
  1000b4:	e8 9b aa 00 00       	call   10ab54 <ioapic_init>
	lapic_init();		// setup this CPU's local APIC
  1000b9:	e8 f1 a6 00 00       	call   10a7af <lapic_init>
	cpu_bootothers();	// Get other processors started
  1000be:	e8 17 17 00 00       	call   1017da <cpu_bootothers>
//	cprintf("CPU %d (%s) has booted\n", cpu_cur()->id,
//		cpu_onboot() ? "BP" : "AP");

	// Initialize the I/O system.
	file_init();		// Create root directory and console I/O files
  1000c3:	e8 94 98 00 00       	call   10995c <file_init>

	// Lab 4: uncomment this when you can handle IRQ_SERIAL and IRQ_KBD.
	//cons_intenable();	// Let the console start producing interrupts
  cons_intenable();
  1000c8:	e8 35 06 00 00       	call   100702 <cons_intenable>
	// Initialize the process management code.
	proc_init();
  1000cd:	e8 2a 40 00 00       	call   1040fc <proc_init>

	// Lab 1: change this so it enters user() in user mode,
	// running on the user_stack declared above,
	// instead of just calling user() directly.
//	user();

  //For LAB 3
if(!cpu_onboot())
  1000d2:	e8 82 03 00 00       	call   100459 <cpu_onboot>
  1000d7:	85 c0                	test   %eax,%eax
  1000d9:	75 05                	jne    1000e0 <init+0xb8>
proc_sched();
  1000db:	e8 cc 44 00 00       	call   1045ac <proc_sched>
  proc *root = proc_root = proc_alloc(NULL,0);
  1000e0:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1000e7:	00 
  1000e8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  1000ef:	e8 aa 40 00 00       	call   10419e <proc_alloc>
  1000f4:	a3 b0 f4 17 00       	mov    %eax,0x17f4b0
  1000f9:	a1 b0 f4 17 00       	mov    0x17f4b0,%eax
  1000fe:	89 45 b4             	mov    %eax,0xffffffb4(%ebp)
  
  elfhdr *eh = (elfhdr *)ROOTEXE_START;
  100101:	c7 45 b8 29 3c 15 00 	movl   $0x153c29,0xffffffb8(%ebp)
  assert(eh->e_magic == ELF_MAGIC);
  100108:	8b 45 b8             	mov    0xffffffb8(%ebp),%eax
  10010b:	8b 00                	mov    (%eax),%eax
  10010d:	3d 7f 45 4c 46       	cmp    $0x464c457f,%eax
  100112:	74 24                	je     100138 <init+0x110>
  100114:	c7 44 24 0c e0 bc 10 	movl   $0x10bce0,0xc(%esp)
  10011b:	00 
  10011c:	c7 44 24 08 f9 bc 10 	movl   $0x10bcf9,0x8(%esp)
  100123:	00 
  100124:	c7 44 24 04 75 00 00 	movl   $0x75,0x4(%esp)
  10012b:	00 
  10012c:	c7 04 24 0e bd 10 00 	movl   $0x10bd0e,(%esp)
  100133:	e8 00 08 00 00       	call   100938 <debug_panic>

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

  for (; ph < eph; ph++){
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
    if(ph->p_flags & ELF_PROG_FLAG_WRITE)
  1001e0:	8b 45 bc             	mov    0xffffffbc(%ebp),%eax
  1001e3:	8b 40 18             	mov    0x18(%eax),%eax
  1001e6:	83 e0 02             	and    $0x2,%eax
  1001e9:	85 c0                	test   %eax,%eax
  1001eb:	0f 84 77 01 00 00    	je     100368 <init+0x340>
    perm |= SYS_WRITE | PTE_W;
  1001f1:	81 4d dc 02 04 00 00 	orl    $0x402,0xffffffdc(%ebp)

    for (; va < eva; va += PAGESIZE, fa += PAGESIZE) {
  1001f8:	e9 6b 01 00 00       	jmp    100368 <init+0x340>
    pageinfo *pi = mem_alloc(); assert(pi != NULL);
  1001fd:	e8 19 0e 00 00       	call   10101b <mem_alloc>
  100202:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
  100205:	83 7d f0 00          	cmpl   $0x0,0xfffffff0(%ebp)
  100209:	75 24                	jne    10022f <init+0x207>
  10020b:	c7 44 24 0c 1a bd 10 	movl   $0x10bd1a,0xc(%esp)
  100212:	00 
  100213:	c7 44 24 08 f9 bc 10 	movl   $0x10bcf9,0x8(%esp)
  10021a:	00 
  10021b:	c7 44 24 04 88 00 00 	movl   $0x88,0x4(%esp)
  100222:	00 
  100223:	c7 04 24 0e bd 10 00 	movl   $0x10bd0e,(%esp)
  10022a:	e8 09 07 00 00       	call   100938 <debug_panic>
      if(va < ROUNDDOWN(zva, PAGESIZE))
  10022f:	8b 45 d4             	mov    0xffffffd4(%ebp),%eax
  100232:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  100235:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  100238:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  10023d:	3b 45 d0             	cmp    0xffffffd0(%ebp),%eax
  100240:	76 2f                	jbe    100271 <init+0x249>
        memmove(mem_pi2ptr(pi), fa, PAGESIZE);
  100242:	8b 55 f0             	mov    0xfffffff0(%ebp),%edx
  100245:	a1 dc ed 17 00       	mov    0x17eddc,%eax
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
  100267:	e8 16 b6 00 00       	call   10b882 <memmove>
  10026c:	e9 96 00 00 00       	jmp    100307 <init+0x2df>
      else if (va < zva && ph->p_filesz){
  100271:	8b 45 d0             	mov    0xffffffd0(%ebp),%eax
  100274:	3b 45 d4             	cmp    0xffffffd4(%ebp),%eax
  100277:	73 65                	jae    1002de <init+0x2b6>
  100279:	8b 45 bc             	mov    0xffffffbc(%ebp),%eax
  10027c:	8b 40 10             	mov    0x10(%eax),%eax
  10027f:	85 c0                	test   %eax,%eax
  100281:	74 5b                	je     1002de <init+0x2b6>
      memset(mem_pi2ptr(pi),0, PAGESIZE);
  100283:	8b 55 f0             	mov    0xfffffff0(%ebp),%edx
  100286:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  10028b:	89 d1                	mov    %edx,%ecx
  10028d:	29 c1                	sub    %eax,%ecx
  10028f:	89 c8                	mov    %ecx,%eax
  100291:	c1 e0 09             	shl    $0x9,%eax
  100294:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  10029b:	00 
  10029c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1002a3:	00 
  1002a4:	89 04 24             	mov    %eax,(%esp)
  1002a7:	e8 5d b5 00 00       	call   10b809 <memset>
      memmove(mem_pi2ptr(pi), fa, zva-va);
  1002ac:	8b 55 d0             	mov    0xffffffd0(%ebp),%edx
  1002af:	8b 45 d4             	mov    0xffffffd4(%ebp),%eax
  1002b2:	89 c1                	mov    %eax,%ecx
  1002b4:	29 d1                	sub    %edx,%ecx
  1002b6:	8b 55 f0             	mov    0xfffffff0(%ebp),%edx
  1002b9:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  1002be:	89 d3                	mov    %edx,%ebx
  1002c0:	29 c3                	sub    %eax,%ebx
  1002c2:	89 d8                	mov    %ebx,%eax
  1002c4:	c1 e0 09             	shl    $0x9,%eax
  1002c7:	89 c2                	mov    %eax,%edx
  1002c9:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  1002cd:	8b 45 cc             	mov    0xffffffcc(%ebp),%eax
  1002d0:	89 44 24 04          	mov    %eax,0x4(%esp)
  1002d4:	89 14 24             	mov    %edx,(%esp)
  1002d7:	e8 a6 b5 00 00       	call   10b882 <memmove>
  1002dc:	eb 29                	jmp    100307 <init+0x2df>
      } else
        memset(mem_pi2ptr(pi), 0, PAGESIZE);
  1002de:	8b 55 f0             	mov    0xfffffff0(%ebp),%edx
  1002e1:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  1002e6:	89 d1                	mov    %edx,%ecx
  1002e8:	29 c1                	sub    %eax,%ecx
  1002ea:	89 c8                	mov    %ecx,%eax
  1002ec:	c1 e0 09             	shl    $0x9,%eax
  1002ef:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  1002f6:	00 
  1002f7:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1002fe:	00 
  1002ff:	89 04 24             	mov    %eax,(%esp)
  100302:	e8 02 b5 00 00       	call   10b809 <memset>

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
  100328:	e8 6e 63 00 00       	call   10669b <pmap_insert>
  10032d:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
      assert(pte != NULL);
  100330:	83 7d f4 00          	cmpl   $0x0,0xfffffff4(%ebp)
  100334:	75 24                	jne    10035a <init+0x332>
  100336:	c7 44 24 0c 25 bd 10 	movl   $0x10bd25,0xc(%esp)
  10033d:	00 
  10033e:	c7 44 24 08 f9 bc 10 	movl   $0x10bcf9,0x8(%esp)
  100345:	00 
  100346:	c7 44 24 04 92 00 00 	movl   $0x92,0x4(%esp)
  10034d:	00 
  10034e:	c7 04 24 0e bd 10 00 	movl   $0x10bd0e,(%esp)
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

      root->sv.tf.eip = eh->e_entry;
  100384:	8b 45 b8             	mov    0xffffffb8(%ebp),%eax
  100387:	8b 50 18             	mov    0x18(%eax),%edx
  10038a:	8b 45 b4             	mov    0xffffffb4(%ebp),%eax
  10038d:	89 90 88 04 00 00    	mov    %edx,0x488(%eax)
      root->sv.tf.eflags |= FL_IF;
  100393:	8b 45 b4             	mov    0xffffffb4(%ebp),%eax
  100396:	8b 80 90 04 00 00    	mov    0x490(%eax),%eax
  10039c:	89 c2                	mov    %eax,%edx
  10039e:	80 ce 02             	or     $0x2,%dh
  1003a1:	8b 45 b4             	mov    0xffffffb4(%ebp),%eax
  1003a4:	89 90 90 04 00 00    	mov    %edx,0x490(%eax)

      pageinfo *pi = mem_alloc(); assert(pi != NULL);
  1003aa:	e8 6c 0c 00 00       	call   10101b <mem_alloc>
  1003af:	89 45 c4             	mov    %eax,0xffffffc4(%ebp)
  1003b2:	83 7d c4 00          	cmpl   $0x0,0xffffffc4(%ebp)
  1003b6:	75 24                	jne    1003dc <init+0x3b4>
  1003b8:	c7 44 24 0c 1a bd 10 	movl   $0x10bd1a,0xc(%esp)
  1003bf:	00 
  1003c0:	c7 44 24 08 f9 bc 10 	movl   $0x10bcf9,0x8(%esp)
  1003c7:	00 
  1003c8:	c7 44 24 04 99 00 00 	movl   $0x99,0x4(%esp)
  1003cf:	00 
  1003d0:	c7 04 24 0e bd 10 00 	movl   $0x10bd0e,(%esp)
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
  1003ff:	e8 97 62 00 00       	call   10669b <pmap_insert>
  100404:	89 45 c8             	mov    %eax,0xffffffc8(%ebp)
      assert(pte != NULL);
  100407:	83 7d c8 00          	cmpl   $0x0,0xffffffc8(%ebp)
  10040b:	75 24                	jne    100431 <init+0x409>
  10040d:	c7 44 24 0c 25 bd 10 	movl   $0x10bd25,0xc(%esp)
  100414:	00 
  100415:	c7 44 24 08 f9 bc 10 	movl   $0x10bcf9,0x8(%esp)
  10041c:	00 
  10041d:	c7 44 24 04 9c 00 00 	movl   $0x9c,0x4(%esp)
  100424:	00 
  100425:	c7 04 24 0e bd 10 00 	movl   $0x10bd0e,(%esp)
  10042c:	e8 07 05 00 00       	call   100938 <debug_panic>
      root->sv.tf.esp = VM_STACKHI;
  100431:	8b 45 b4             	mov    0xffffffb4(%ebp),%eax
  100434:	c7 80 94 04 00 00 00 	movl   $0xf0000000,0x494(%eax)
  10043b:	00 00 f0 

      file_initroot(root);
  10043e:	8b 45 b4             	mov    0xffffffb4(%ebp),%eax
  100441:	89 04 24             	mov    %eax,(%esp)
  100444:	e8 ab 95 00 00       	call   1099f4 <file_initroot>
      proc_ready(root);
  100449:	8b 45 b4             	mov    0xffffffb4(%ebp),%eax
  10044c:	89 04 24             	mov    %eax,(%esp)
  10044f:	e8 94 3f 00 00       	call   1043e8 <proc_ready>
      proc_sched();
  100454:	e8 53 41 00 00       	call   1045ac <proc_sched>

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
  100464:	3d 00 e0 10 00       	cmp    $0x10e000,%eax
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
  10049b:	c7 44 24 0c 31 bd 10 	movl   $0x10bd31,0xc(%esp)
  1004a2:	00 
  1004a3:	c7 44 24 08 f9 bc 10 	movl   $0x10bcf9,0x8(%esp)
  1004aa:	00 
  1004ab:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  1004b2:	00 
  1004b3:	c7 04 24 47 bd 10 00 	movl   $0x10bd47,(%esp)
  1004ba:	e8 79 04 00 00       	call   100938 <debug_panic>
	return c;
  1004bf:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
}
  1004c2:	c9                   	leave  
  1004c3:	c3                   	ret    

001004c4 <user>:


     // user();
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
  1004ca:	c7 04 24 54 bd 10 00 	movl   $0x10bd54,(%esp)
  1004d1:	e8 af af 00 00       	call   10b485 <cprintf>
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
  1004de:	b8 00 90 17 00       	mov    $0x179000,%eax
  1004e3:	39 c2                	cmp    %eax,%edx
  1004e5:	77 24                	ja     10050b <user+0x47>
  1004e7:	c7 44 24 0c 60 bd 10 	movl   $0x10bd60,0xc(%esp)
  1004ee:	00 
  1004ef:	c7 44 24 08 f9 bc 10 	movl   $0x10bcf9,0x8(%esp)
  1004f6:	00 
  1004f7:	c7 44 24 04 ae 00 00 	movl   $0xae,0x4(%esp)
  1004fe:	00 
  1004ff:	c7 04 24 0e bd 10 00 	movl   $0x10bd0e,(%esp)
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
  100513:	b8 00 a0 17 00       	mov    $0x17a000,%eax
  100518:	39 c2                	cmp    %eax,%edx
  10051a:	72 24                	jb     100540 <user+0x7c>
  10051c:	c7 44 24 0c 88 bd 10 	movl   $0x10bd88,0xc(%esp)
  100523:	00 
  100524:	c7 44 24 08 f9 bc 10 	movl   $0x10bcf9,0x8(%esp)
  10052b:	00 
  10052c:	c7 44 24 04 af 00 00 	movl   $0xaf,0x4(%esp)
  100533:	00 
  100534:	c7 04 24 0e bd 10 00 	movl   $0x10bd0e,(%esp)
  10053b:	e8 f8 03 00 00       	call   100938 <debug_panic>

	// Check the system call and process scheduling code.
//  cprintf("proc_check");
//	proc_check();

	// Check that we're in user mode and can handle traps from there.
//	trap_check_user();

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
  100552:	c7 04 24 40 ed 17 00 	movl   $0x17ed40,(%esp)
  100559:	e8 2c 35 00 00       	call   103a8a <spinlock_acquire>
	while ((c = (*proc)()) != -1) {
  10055e:	eb 33                	jmp    100593 <cons_intr+0x47>
		if (c == 0)
  100560:	83 7d fc 00          	cmpl   $0x0,0xfffffffc(%ebp)
  100564:	74 2d                	je     100593 <cons_intr+0x47>
			continue;
		cons.buf[cons.wpos++] = c;
  100566:	8b 15 04 a2 17 00    	mov    0x17a204,%edx
  10056c:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  10056f:	88 82 00 a0 17 00    	mov    %al,0x17a000(%edx)
  100575:	8d 42 01             	lea    0x1(%edx),%eax
  100578:	a3 04 a2 17 00       	mov    %eax,0x17a204
		if (cons.wpos == CONSBUFSIZE)
  10057d:	a1 04 a2 17 00       	mov    0x17a204,%eax
  100582:	3d 00 02 00 00       	cmp    $0x200,%eax
  100587:	75 0a                	jne    100593 <cons_intr+0x47>
			cons.wpos = 0;
  100589:	c7 05 04 a2 17 00 00 	movl   $0x0,0x17a204
  100590:	00 00 00 
  100593:	8b 45 08             	mov    0x8(%ebp),%eax
  100596:	ff d0                	call   *%eax
  100598:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  10059b:	83 7d fc ff          	cmpl   $0xffffffff,0xfffffffc(%ebp)
  10059f:	75 bf                	jne    100560 <cons_intr+0x14>
	}
	spinlock_release(&cons_lock);
  1005a1:	c7 04 24 40 ed 17 00 	movl   $0x17ed40,(%esp)
  1005a8:	e8 d8 35 00 00       	call   103b85 <spinlock_release>

	// Wake the root process
	file_wakeroot();
  1005ad:	e8 6f 98 00 00       	call   109e21 <file_wakeroot>
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
  1005ba:	e8 fd 9d 00 00       	call   10a3bc <serial_intr>
	kbd_intr();
  1005bf:	e8 30 9d 00 00       	call   10a2f4 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
  1005c4:	8b 15 00 a2 17 00    	mov    0x17a200,%edx
  1005ca:	a1 04 a2 17 00       	mov    0x17a204,%eax
  1005cf:	39 c2                	cmp    %eax,%edx
  1005d1:	74 39                	je     10060c <cons_getc+0x58>
		c = cons.buf[cons.rpos++];
  1005d3:	8b 15 00 a2 17 00    	mov    0x17a200,%edx
  1005d9:	0f b6 82 00 a0 17 00 	movzbl 0x17a000(%edx),%eax
  1005e0:	0f b6 c0             	movzbl %al,%eax
  1005e3:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  1005e6:	8d 42 01             	lea    0x1(%edx),%eax
  1005e9:	a3 00 a2 17 00       	mov    %eax,0x17a200
		if (cons.rpos == CONSBUFSIZE)
  1005ee:	a1 00 a2 17 00       	mov    0x17a200,%eax
  1005f3:	3d 00 02 00 00       	cmp    $0x200,%eax
  1005f8:	75 0a                	jne    100604 <cons_getc+0x50>
			cons.rpos = 0;
  1005fa:	c7 05 00 a2 17 00 00 	movl   $0x0,0x17a200
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
  100624:	e8 b0 9d 00 00       	call   10a3d9 <serial_putc>
	video_putc(c);
  100629:	8b 45 08             	mov    0x8(%ebp),%eax
  10062c:	89 04 24             	mov    %eax,(%esp)
  10062f:	e8 fc 98 00 00       	call   109f30 <video_putc>
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
  100645:	c7 44 24 08 6d 00 00 	movl   $0x6d,0x8(%esp)
  10064c:	00 
  10064d:	c7 44 24 04 c0 bd 10 	movl   $0x10bdc0,0x4(%esp)
  100654:	00 
  100655:	c7 04 24 40 ed 17 00 	movl   $0x17ed40,(%esp)
  10065c:	e8 ff 33 00 00       	call   103a60 <spinlock_init_>
	video_init();
  100661:	e8 02 98 00 00       	call   109e68 <video_init>
	kbd_init();
  100666:	e8 9d 9c 00 00       	call   10a308 <kbd_init>
	serial_init();
  10066b:	e8 c9 9d 00 00       	call   10a439 <serial_init>

	if (!serial_exists)
  100670:	a1 00 20 18 00       	mov    0x182000,%eax
  100675:	85 c0                	test   %eax,%eax
  100677:	75 1c                	jne    100695 <cons_init+0x5f>
		warn("Serial port does not exist!\n");
  100679:	c7 44 24 08 cc bd 10 	movl   $0x10bdcc,0x8(%esp)
  100680:	00 
  100681:	c7 44 24 04 73 00 00 	movl   $0x73,0x4(%esp)
  100688:	00 
  100689:	c7 04 24 c0 bd 10 00 	movl   $0x10bdc0,(%esp)
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
  1006a2:	3d 00 e0 10 00       	cmp    $0x10e000,%eax
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
  1006d9:	c7 44 24 0c e9 bd 10 	movl   $0x10bde9,0xc(%esp)
  1006e0:	00 
  1006e1:	c7 44 24 08 ff bd 10 	movl   $0x10bdff,0x8(%esp)
  1006e8:	00 
  1006e9:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  1006f0:	00 
  1006f1:	c7 04 24 14 be 10 00 	movl   $0x10be14,(%esp)
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
  100711:	e8 f7 9b 00 00       	call   10a30d <kbd_intenable>
	serial_intenable();
  100716:	e8 e6 9d 00 00       	call   10a501 <serial_intenable>
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
  100747:	c7 04 24 40 ed 17 00 	movl   $0x17ed40,(%esp)
  10074e:	e8 8c 34 00 00       	call   103bdf <spinlock_holding>
  100753:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
	if (!already)
  100756:	83 7d f0 00          	cmpl   $0x0,0xfffffff0(%ebp)
  10075a:	75 23                	jne    10077f <cputs+0x62>
		spinlock_acquire(&cons_lock);
  10075c:	c7 04 24 40 ed 17 00 	movl   $0x17ed40,(%esp)
  100763:	e8 22 33 00 00       	call   103a8a <spinlock_acquire>

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
  10078f:	c7 04 24 40 ed 17 00 	movl   $0x17ed40,(%esp)
  100796:	e8 ea 33 00 00       	call   103b85 <spinlock_release>
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
	// Lab 4: your console I/O code here.
	spinlock_acquire(&cons_lock);
  1007a7:	c7 04 24 40 ed 17 00 	movl   $0x17ed40,(%esp)
  1007ae:	e8 d7 32 00 00       	call   103a8a <spinlock_acquire>
	bool didio = 0;
  1007b3:	c7 45 e8 00 00 00 00 	movl   $0x0,0xffffffe8(%ebp)

	// Console output from the root process's console output file
	fileinode *outfi = &files->fi[FILEINO_CONSOUT];
  1007ba:	a1 98 da 10 00       	mov    0x10da98,%eax
  1007bf:	05 10 10 00 00       	add    $0x1010,%eax
  1007c4:	05 b8 00 00 00       	add    $0xb8,%eax
  1007c9:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
	const char *outbuf = FILEDATA(FILEINO_CONSOUT);
  1007cc:	c7 45 f0 00 00 80 80 	movl   $0x80800000,0xfffffff0(%ebp)
	assert(cons_outsize <= outfi->size);
  1007d3:	a1 08 a2 17 00       	mov    0x17a208,%eax
  1007d8:	89 c2                	mov    %eax,%edx
  1007da:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  1007dd:	8b 40 4c             	mov    0x4c(%eax),%eax
  1007e0:	39 c2                	cmp    %eax,%edx
  1007e2:	76 4c                	jbe    100830 <cons_io+0x8f>
  1007e4:	c7 44 24 0c 21 be 10 	movl   $0x10be21,0xc(%esp)
  1007eb:	00 
  1007ec:	c7 44 24 08 ff bd 10 	movl   $0x10bdff,0x8(%esp)
  1007f3:	00 
  1007f4:	c7 44 24 04 a3 00 00 	movl   $0xa3,0x4(%esp)
  1007fb:	00 
  1007fc:	c7 04 24 c0 bd 10 00 	movl   $0x10bdc0,(%esp)
  100803:	e8 30 01 00 00       	call   100938 <debug_panic>
	while (cons_outsize < outfi->size) {
		cons_putc(outbuf[cons_outsize++]);
  100808:	8b 0d 08 a2 17 00    	mov    0x17a208,%ecx
  10080e:	89 c8                	mov    %ecx,%eax
  100810:	03 45 f0             	add    0xfffffff0(%ebp),%eax
  100813:	0f b6 00             	movzbl (%eax),%eax
  100816:	0f be d0             	movsbl %al,%edx
  100819:	8d 41 01             	lea    0x1(%ecx),%eax
  10081c:	a3 08 a2 17 00       	mov    %eax,0x17a208
  100821:	89 14 24             	mov    %edx,(%esp)
  100824:	e8 ef fd ff ff       	call   100618 <cons_putc>
		didio = 1;
  100829:	c7 45 e8 01 00 00 00 	movl   $0x1,0xffffffe8(%ebp)
  100830:	a1 08 a2 17 00       	mov    0x17a208,%eax
  100835:	89 c2                	mov    %eax,%edx
  100837:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  10083a:	8b 40 4c             	mov    0x4c(%eax),%eax
  10083d:	39 c2                	cmp    %eax,%edx
  10083f:	72 c7                	jb     100808 <cons_io+0x67>
	}

	// Console input to the root process's console input file
	fileinode *infi = &files->fi[FILEINO_CONSIN];
  100841:	a1 98 da 10 00       	mov    0x10da98,%eax
  100846:	05 10 10 00 00       	add    $0x1010,%eax
  10084b:	83 c0 5c             	add    $0x5c,%eax
  10084e:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	char *inbuf = FILEDATA(FILEINO_CONSIN);
  100851:	c7 45 f8 00 00 40 80 	movl   $0x80400000,0xfffffff8(%ebp)
	int amount = cons.wpos - cons.rpos;
  100858:	8b 15 04 a2 17 00    	mov    0x17a204,%edx
  10085e:	a1 00 a2 17 00       	mov    0x17a200,%eax
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
  10087f:	c7 44 24 08 40 be 10 	movl   $0x10be40,0x8(%esp)
  100886:	00 
  100887:	c7 44 24 04 ae 00 00 	movl   $0xae,0x4(%esp)
  10088e:	00 
  10088f:	c7 04 24 c0 bd 10 00 	movl   $0x10bdc0,(%esp)
  100896:	e8 9d 00 00 00       	call   100938 <debug_panic>
	assert(amount >= 0 && amount <= CONSBUFSIZE);
  10089b:	83 7d fc 00          	cmpl   $0x0,0xfffffffc(%ebp)
  10089f:	78 09                	js     1008aa <cons_io+0x109>
  1008a1:	81 7d fc 00 02 00 00 	cmpl   $0x200,0xfffffffc(%ebp)
  1008a8:	7e 24                	jle    1008ce <cons_io+0x12d>
  1008aa:	c7 44 24 0c 74 be 10 	movl   $0x10be74,0xc(%esp)
  1008b1:	00 
  1008b2:	c7 44 24 08 ff bd 10 	movl   $0x10bdff,0x8(%esp)
  1008b9:	00 
  1008ba:	c7 44 24 04 af 00 00 	movl   $0xaf,0x4(%esp)
  1008c1:	00 
  1008c2:	c7 04 24 c0 bd 10 00 	movl   $0x10bdc0,(%esp)
  1008c9:	e8 6a 00 00 00       	call   100938 <debug_panic>
	if (amount > 0) {
  1008ce:	83 7d fc 00          	cmpl   $0x0,0xfffffffc(%ebp)
  1008d2:	7e 53                	jle    100927 <cons_io+0x186>
		memmove(&inbuf[infi->size], &cons.buf[cons.rpos], amount);
  1008d4:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  1008d7:	a1 00 a2 17 00       	mov    0x17a200,%eax
  1008dc:	8d 88 00 a0 17 00    	lea    0x17a000(%eax),%ecx
  1008e2:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  1008e5:	8b 40 4c             	mov    0x4c(%eax),%eax
  1008e8:	03 45 f8             	add    0xfffffff8(%ebp),%eax
  1008eb:	89 54 24 08          	mov    %edx,0x8(%esp)
  1008ef:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  1008f3:	89 04 24             	mov    %eax,(%esp)
  1008f6:	e8 87 af 00 00       	call   10b882 <memmove>
		infi->size += amount;
  1008fb:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  1008fe:	8b 50 4c             	mov    0x4c(%eax),%edx
  100901:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  100904:	01 c2                	add    %eax,%edx
  100906:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  100909:	89 50 4c             	mov    %edx,0x4c(%eax)
		cons.rpos = cons.wpos = 0;
  10090c:	c7 05 04 a2 17 00 00 	movl   $0x0,0x17a204
  100913:	00 00 00 
  100916:	a1 04 a2 17 00       	mov    0x17a204,%eax
  10091b:	a3 00 a2 17 00       	mov    %eax,0x17a200
		didio = 1;
  100920:	c7 45 e8 01 00 00 00 	movl   $0x1,0xffffffe8(%ebp)
	}

	spinlock_release(&cons_lock);
  100927:	c7 04 24 40 ed 17 00 	movl   $0x17ed40,(%esp)
  10092e:	e8 52 32 00 00       	call   103b85 <spinlock_release>
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
  10094f:	a1 0c a2 17 00       	mov    0x17a20c,%eax
  100954:	85 c0                	test   %eax,%eax
  100956:	0f 85 95 00 00 00    	jne    1009f1 <debug_panic+0xb9>
			goto dead;
		panicstr = fmt;
  10095c:	8b 45 10             	mov    0x10(%ebp),%eax
  10095f:	a3 0c a2 17 00       	mov    %eax,0x17a20c
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
  10097b:	c7 04 24 99 be 10 00 	movl   $0x10be99,(%esp)
  100982:	e8 fe aa 00 00       	call   10b485 <cprintf>
	vcprintf(fmt, ap);
  100987:	8b 55 10             	mov    0x10(%ebp),%edx
  10098a:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  10098d:	89 44 24 04          	mov    %eax,0x4(%esp)
  100991:	89 14 24             	mov    %edx,(%esp)
  100994:	e8 83 aa 00 00       	call   10b41c <vcprintf>
	cprintf("\n");
  100999:	c7 04 24 b1 be 10 00 	movl   $0x10beb1,(%esp)
  1009a0:	e8 e0 aa 00 00       	call   10b485 <cprintf>
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
  1009d0:	c7 04 24 b3 be 10 00 	movl   $0x10beb3,(%esp)
  1009d7:	e8 a9 aa 00 00       	call   10b485 <cprintf>
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
  100a13:	c7 04 24 c0 be 10 00 	movl   $0x10bec0,(%esp)
  100a1a:	e8 66 aa 00 00       	call   10b485 <cprintf>
	vcprintf(fmt, ap);
  100a1f:	8b 55 10             	mov    0x10(%ebp),%edx
  100a22:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  100a25:	89 44 24 04          	mov    %eax,0x4(%esp)
  100a29:	89 14 24             	mov    %edx,(%esp)
  100a2c:	e8 eb a9 00 00       	call   10b41c <vcprintf>
	cprintf("\n");
  100a31:	c7 04 24 b1 be 10 00 	movl   $0x10beb1,(%esp)
  100a38:	e8 48 aa 00 00       	call   10b485 <cprintf>
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
//	panic("debug_trace not implemented");
  uint32_t *frame = (uint32_t *) ebp;
  100a45:	8b 45 08             	mov    0x8(%ebp),%eax
  100a48:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)

  int i;

  // Print the eip of the last n frames,
  // where n is DEBUG_TRACEFRAMES
  for (i = 0; i < DEBUG_TRACEFRAMES && frame; i++) {
  100a4b:	c7 45 fc 00 00 00 00 	movl   $0x0,0xfffffffc(%ebp)
  100a52:	eb 21                	jmp    100a75 <debug_trace+0x36>
    // print relevent information about the stack
    //cprintf("ebp: %08x ", frame[0]);
    //cprintf("eip: %08x ", frame[1]);
    //cprintf("args: %08x %08x %08x %08x %08x ", frame[2], frame[3], frame[4], frame[5], frame[6]);
    //cprintf("\n"); 

    // add information to eips array
    eips[i] = frame[1];             // eip saved at ebp + 1
  100a54:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  100a57:	c1 e0 02             	shl    $0x2,%eax
  100a5a:	89 c2                	mov    %eax,%edx
  100a5c:	03 55 0c             	add    0xc(%ebp),%edx
  100a5f:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  100a62:	83 c0 04             	add    $0x4,%eax
  100a65:	8b 00                	mov    (%eax),%eax
  100a67:	89 02                	mov    %eax,(%edx)

    // move to the next frame up the stack
    frame = (uint32_t*)frame[0];  // prev ebp saved at ebp 0
  100a69:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  100a6c:	8b 00                	mov    (%eax),%eax
  100a6e:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  100a71:	83 45 fc 01          	addl   $0x1,0xfffffffc(%ebp)
  100a75:	83 7d fc 09          	cmpl   $0x9,0xfffffffc(%ebp)
  100a79:	7f 1b                	jg     100a96 <debug_trace+0x57>
  100a7b:	83 7d f8 00          	cmpl   $0x0,0xfffffff8(%ebp)
  100a7f:	75 d3                	jne    100a54 <debug_trace+0x15>
  }

  // if the there are less than DEBUG_TRACEFRAMES frames,
  // print the rest as null
  for (i; i < DEBUG_TRACEFRAMES; i++) {
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
  100bb1:	c7 44 24 0c da be 10 	movl   $0x10beda,0xc(%esp)
  100bb8:	00 
  100bb9:	c7 44 24 08 f7 be 10 	movl   $0x10bef7,0x8(%esp)
  100bc0:	00 
  100bc1:	c7 44 24 04 7a 00 00 	movl   $0x7a,0x4(%esp)
  100bc8:	00 
  100bc9:	c7 04 24 0c bf 10 00 	movl   $0x10bf0c,(%esp)
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
  100c01:	c7 44 24 0c 19 bf 10 	movl   $0x10bf19,0xc(%esp)
  100c08:	00 
  100c09:	c7 44 24 08 f7 be 10 	movl   $0x10bef7,0x8(%esp)
  100c10:	00 
  100c11:	c7 44 24 04 7c 00 00 	movl   $0x7c,0x4(%esp)
  100c18:	00 
  100c19:	c7 04 24 0c bf 10 00 	movl   $0x10bf0c,(%esp)
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
  100c4e:	c7 44 24 0c 32 bf 10 	movl   $0x10bf32,0xc(%esp)
  100c55:	00 
  100c56:	c7 44 24 08 f7 be 10 	movl   $0x10bef7,0x8(%esp)
  100c5d:	00 
  100c5e:	c7 44 24 04 7e 00 00 	movl   $0x7e,0x4(%esp)
  100c65:	00 
  100c66:	c7 04 24 0c bf 10 00 	movl   $0x10bf0c,(%esp)
  100c6d:	e8 c6 fc ff ff       	call   100938 <debug_panic>
	assert(eips[2][0] == eips[3][0]);
  100c72:	8b 55 a8             	mov    0xffffffa8(%ebp),%edx
  100c75:	8b 45 d0             	mov    0xffffffd0(%ebp),%eax
  100c78:	39 c2                	cmp    %eax,%edx
  100c7a:	74 24                	je     100ca0 <debug_check+0x173>
  100c7c:	c7 44 24 0c 4b bf 10 	movl   $0x10bf4b,0xc(%esp)
  100c83:	00 
  100c84:	c7 44 24 08 f7 be 10 	movl   $0x10bef7,0x8(%esp)
  100c8b:	00 
  100c8c:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
  100c93:	00 
  100c94:	c7 04 24 0c bf 10 00 	movl   $0x10bf0c,(%esp)
  100c9b:	e8 98 fc ff ff       	call   100938 <debug_panic>
	assert(eips[1][0] != eips[2][0]);
  100ca0:	8b 55 80             	mov    0xffffff80(%ebp),%edx
  100ca3:	8b 45 a8             	mov    0xffffffa8(%ebp),%eax
  100ca6:	39 c2                	cmp    %eax,%edx
  100ca8:	75 24                	jne    100cce <debug_check+0x1a1>
  100caa:	c7 44 24 0c 64 bf 10 	movl   $0x10bf64,0xc(%esp)
  100cb1:	00 
  100cb2:	c7 44 24 08 f7 be 10 	movl   $0x10bef7,0x8(%esp)
  100cb9:	00 
  100cba:	c7 44 24 04 80 00 00 	movl   $0x80,0x4(%esp)
  100cc1:	00 
  100cc2:	c7 04 24 0c bf 10 00 	movl   $0x10bf0c,(%esp)
  100cc9:	e8 6a fc ff ff       	call   100938 <debug_panic>
	assert(eips[0][1] == eips[2][1]);
  100cce:	8b 95 5c ff ff ff    	mov    0xffffff5c(%ebp),%edx
  100cd4:	8b 45 ac             	mov    0xffffffac(%ebp),%eax
  100cd7:	39 c2                	cmp    %eax,%edx
  100cd9:	74 24                	je     100cff <debug_check+0x1d2>
  100cdb:	c7 44 24 0c 7d bf 10 	movl   $0x10bf7d,0xc(%esp)
  100ce2:	00 
  100ce3:	c7 44 24 08 f7 be 10 	movl   $0x10bef7,0x8(%esp)
  100cea:	00 
  100ceb:	c7 44 24 04 81 00 00 	movl   $0x81,0x4(%esp)
  100cf2:	00 
  100cf3:	c7 04 24 0c bf 10 00 	movl   $0x10bf0c,(%esp)
  100cfa:	e8 39 fc ff ff       	call   100938 <debug_panic>
	assert(eips[1][1] == eips[3][1]);
  100cff:	8b 55 84             	mov    0xffffff84(%ebp),%edx
  100d02:	8b 45 d4             	mov    0xffffffd4(%ebp),%eax
  100d05:	39 c2                	cmp    %eax,%edx
  100d07:	74 24                	je     100d2d <debug_check+0x200>
  100d09:	c7 44 24 0c 96 bf 10 	movl   $0x10bf96,0xc(%esp)
  100d10:	00 
  100d11:	c7 44 24 08 f7 be 10 	movl   $0x10bef7,0x8(%esp)
  100d18:	00 
  100d19:	c7 44 24 04 82 00 00 	movl   $0x82,0x4(%esp)
  100d20:	00 
  100d21:	c7 04 24 0c bf 10 00 	movl   $0x10bf0c,(%esp)
  100d28:	e8 0b fc ff ff       	call   100938 <debug_panic>
	assert(eips[0][1] != eips[1][1]);
  100d2d:	8b 95 5c ff ff ff    	mov    0xffffff5c(%ebp),%edx
  100d33:	8b 45 84             	mov    0xffffff84(%ebp),%eax
  100d36:	39 c2                	cmp    %eax,%edx
  100d38:	75 24                	jne    100d5e <debug_check+0x231>
  100d3a:	c7 44 24 0c af bf 10 	movl   $0x10bfaf,0xc(%esp)
  100d41:	00 
  100d42:	c7 44 24 08 f7 be 10 	movl   $0x10bef7,0x8(%esp)
  100d49:	00 
  100d4a:	c7 44 24 04 83 00 00 	movl   $0x83,0x4(%esp)
  100d51:	00 
  100d52:	c7 04 24 0c bf 10 00 	movl   $0x10bf0c,(%esp)
  100d59:	e8 da fb ff ff       	call   100938 <debug_panic>

	cprintf("debug_check() succeeded!\n");
  100d5e:	c7 04 24 c8 bf 10 00 	movl   $0x10bfc8,(%esp)
  100d65:	e8 1b a7 00 00       	call   10b485 <cprintf>
}
  100d6a:	c9                   	leave  
  100d6b:	c3                   	ret    

00100d6c <mem_init>:
void mem_check(void);

void
mem_init(void)
{
  100d6c:	55                   	push   %ebp
  100d6d:	89 e5                	mov    %esp,%ebp
  100d6f:	83 ec 48             	sub    $0x48,%esp
	if (!cpu_onboot())	// only do once, on the boot CPU
  100d72:	e8 39 02 00 00       	call   100fb0 <cpu_onboot>
  100d77:	85 c0                	test   %eax,%eax
  100d79:	0f 84 2f 02 00 00    	je     100fae <mem_init+0x242>
		return;

	// Determine how much base (<640K) and extended (>1MB) memory
	// is available in the system (in bytes),
	// by reading the PC's BIOS-managed nonvolatile RAM (NVRAM).
	// The NVRAM tells us how many kilobytes there are.
	// Since the count is 16 bits, this gives us up to 64MB of RAM;
	// additional RAM beyond that would have to be detected another way.
	size_t basemem = ROUNDDOWN(nvram_read16(NVRAM_BASELO)*1024, PAGESIZE);
  100d7f:	c7 04 24 15 00 00 00 	movl   $0x15,(%esp)
  100d86:	e8 9a 99 00 00       	call   10a725 <nvram_read16>
  100d8b:	c1 e0 0a             	shl    $0xa,%eax
  100d8e:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  100d91:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  100d94:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  100d99:	89 45 dc             	mov    %eax,0xffffffdc(%ebp)
	size_t extmem = ROUNDDOWN(nvram_read16(NVRAM_EXTLO)*1024, PAGESIZE);
  100d9c:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
  100da3:	e8 7d 99 00 00       	call   10a725 <nvram_read16>
  100da8:	c1 e0 0a             	shl    $0xa,%eax
  100dab:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
  100dae:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  100db1:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  100db6:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)

	warn("Assuming we have 1GB of memory!");
  100db9:	c7 44 24 08 e4 bf 10 	movl   $0x10bfe4,0x8(%esp)
  100dc0:	00 
  100dc1:	c7 44 24 04 33 00 00 	movl   $0x33,0x4(%esp)
  100dc8:	00 
  100dc9:	c7 04 24 04 c0 10 00 	movl   $0x10c004,(%esp)
  100dd0:	e8 21 fc ff ff       	call   1009f6 <debug_warn>
	extmem = 1024*1024*1024 - MEM_EXT;	// assume 1GB total memory
  100dd5:	c7 45 e0 00 00 f0 3f 	movl   $0x3ff00000,0xffffffe0(%ebp)

	// The maximum physical address is the top of extended memory.
	mem_max = MEM_EXT + extmem;
  100ddc:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  100ddf:	05 00 00 10 00       	add    $0x100000,%eax
  100de4:	a3 d8 ed 17 00       	mov    %eax,0x17edd8

	// Compute the total number of physical pages (including I/O holes)
	mem_npage = mem_max / PAGESIZE;
  100de9:	a1 d8 ed 17 00       	mov    0x17edd8,%eax
  100dee:	c1 e8 0c             	shr    $0xc,%eax
  100df1:	a3 84 ed 17 00       	mov    %eax,0x17ed84

	cprintf("Physical memory: %dK available, ", (int)(mem_max/1024));
  100df6:	a1 d8 ed 17 00       	mov    0x17edd8,%eax
  100dfb:	c1 e8 0a             	shr    $0xa,%eax
  100dfe:	89 44 24 04          	mov    %eax,0x4(%esp)
  100e02:	c7 04 24 10 c0 10 00 	movl   $0x10c010,(%esp)
  100e09:	e8 77 a6 00 00       	call   10b485 <cprintf>
	cprintf("base = %dK, extended = %dK\n",
  100e0e:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  100e11:	c1 e8 0a             	shr    $0xa,%eax
  100e14:	89 c2                	mov    %eax,%edx
  100e16:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  100e19:	c1 e8 0a             	shr    $0xa,%eax
  100e1c:	89 54 24 08          	mov    %edx,0x8(%esp)
  100e20:	89 44 24 04          	mov    %eax,0x4(%esp)
  100e24:	c7 04 24 31 c0 10 00 	movl   $0x10c031,(%esp)
  100e2b:	e8 55 a6 00 00       	call   10b485 <cprintf>
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
	pageinfo **freetail = &mem_freelist;
  100e30:	c7 45 e4 80 ed 17 00 	movl   $0x17ed80,0xffffffe4(%ebp)
  // start at the beginning of memeory
  mem_pageinfo = (pageinfo *) ROUNDUP(((int)end), sizeof(pageinfo));
  100e37:	c7 45 f4 08 00 00 00 	movl   $0x8,0xfffffff4(%ebp)
  100e3e:	b8 08 20 18 00       	mov    $0x182008,%eax
  100e43:	83 e8 01             	sub    $0x1,%eax
  100e46:	03 45 f4             	add    0xfffffff4(%ebp),%eax
  100e49:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  100e4c:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  100e4f:	ba 00 00 00 00       	mov    $0x0,%edx
  100e54:	f7 75 f4             	divl   0xfffffff4(%ebp)
  100e57:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  100e5a:	29 d0                	sub    %edx,%eax
  100e5c:	a3 dc ed 17 00       	mov    %eax,0x17eddc

  // set it all to zero
  memset(mem_pageinfo, 0, sizeof(pageinfo) * mem_npage);
  100e61:	a1 84 ed 17 00       	mov    0x17ed84,%eax
  100e66:	c1 e0 03             	shl    $0x3,%eax
  100e69:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  100e6f:	89 44 24 08          	mov    %eax,0x8(%esp)
  100e73:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  100e7a:	00 
  100e7b:	89 14 24             	mov    %edx,(%esp)
  100e7e:	e8 86 a9 00 00       	call   10b809 <memset>

  spinlock_init(&page_spinlock);
  100e83:	c7 44 24 08 5d 00 00 	movl   $0x5d,0x8(%esp)
  100e8a:	00 
  100e8b:	c7 44 24 04 04 c0 10 	movl   $0x10c004,0x4(%esp)
  100e92:	00 
  100e93:	c7 04 24 a0 ed 17 00 	movl   $0x17eda0,(%esp)
  100e9a:	e8 c1 2b 00 00       	call   103a60 <spinlock_init_>
  int i;

	for (i = 0; i < mem_npage; i++) {
  100e9f:	c7 45 e8 00 00 00 00 	movl   $0x0,0xffffffe8(%ebp)
  100ea6:	e9 e5 00 00 00       	jmp    100f90 <mem_init+0x224>

    // physical address of current pageinfo
    uint32_t paddr = mem_pi2phys(mem_pageinfo + i);
  100eab:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  100eae:	c1 e0 03             	shl    $0x3,%eax
  100eb1:	89 c2                	mov    %eax,%edx
  100eb3:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  100eb8:	8d 04 02             	lea    (%edx,%eax,1),%eax
  100ebb:	89 c2                	mov    %eax,%edx
  100ebd:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  100ec2:	89 d1                	mov    %edx,%ecx
  100ec4:	29 c1                	sub    %eax,%ecx
  100ec6:	89 c8                	mov    %ecx,%eax
  100ec8:	c1 e0 09             	shl    $0x9,%eax
  100ecb:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
    if ((i == 0 || i == 1 || // pages 0 and 1 are reserved for idt, bios, and bootstrap (see above)
  100ece:	83 7d e8 00          	cmpl   $0x0,0xffffffe8(%ebp)
  100ed2:	74 61                	je     100f35 <mem_init+0x1c9>
  100ed4:	83 7d e8 01          	cmpl   $0x1,0xffffffe8(%ebp)
  100ed8:	74 5b                	je     100f35 <mem_init+0x1c9>
  100eda:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  100edd:	05 00 10 00 00       	add    $0x1000,%eax
  100ee2:	3d ff ff 09 00       	cmp    $0x9ffff,%eax
  100ee7:	76 09                	jbe    100ef2 <mem_init+0x186>
  100ee9:	81 7d fc ff ff 0f 00 	cmpl   $0xfffff,0xfffffffc(%ebp)
  100ef0:	76 43                	jbe    100f35 <mem_init+0x1c9>
  100ef2:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  100ef5:	05 00 10 00 00       	add    $0x1000,%eax
  100efa:	ba 0c 00 10 00       	mov    $0x10000c,%edx
  100eff:	39 d0                	cmp    %edx,%eax
  100f01:	72 0a                	jb     100f0d <mem_init+0x1a1>
  100f03:	b8 08 20 18 00       	mov    $0x182008,%eax
  100f08:	39 45 fc             	cmp    %eax,0xfffffffc(%ebp)
  100f0b:	72 28                	jb     100f35 <mem_init+0x1c9>
  100f0d:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  100f10:	05 00 10 00 00       	add    $0x1000,%eax
  100f15:	ba dc ed 17 00       	mov    $0x17eddc,%edx
  100f1a:	39 d0                	cmp    %edx,%eax
  100f1c:	72 30                	jb     100f4e <mem_init+0x1e2>
  100f1e:	a1 84 ed 17 00       	mov    0x17ed84,%eax
  100f23:	c1 e0 03             	shl    $0x3,%eax
  100f26:	89 c2                	mov    %eax,%edx
  100f28:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  100f2d:	8d 04 02             	lea    (%edx,%eax,1),%eax
  100f30:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  100f33:	76 19                	jbe    100f4e <mem_init+0x1e2>
          (paddr + PAGESIZE >= MEM_IO && paddr < MEM_EXT) || // IO section is reserved
          (paddr + PAGESIZE >= (uint32_t) &start[0] && paddr < (uint32_t) &end[0]) || // kernel, 
          (paddr + PAGESIZE >= (uint32_t) &mem_pageinfo && // start of pageinfo array
           paddr < (uint32_t) &mem_pageinfo[mem_npage]) // end of pageinfo array
     )) {
      mem_pageinfo[i].refcount = 1; 
  100f35:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  100f38:	c1 e0 03             	shl    $0x3,%eax
  100f3b:	89 c2                	mov    %eax,%edx
  100f3d:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  100f42:	8d 04 02             	lea    (%edx,%eax,1),%eax
  100f45:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
  100f4c:	eb 3e                	jmp    100f8c <mem_init+0x220>
    } else {
      mem_pageinfo[i].refcount = 0; 
  100f4e:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  100f51:	c1 e0 03             	shl    $0x3,%eax
  100f54:	89 c2                	mov    %eax,%edx
  100f56:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  100f5b:	8d 04 02             	lea    (%edx,%eax,1),%eax
  100f5e:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
      // Add the page to the end of the free list.
      *freetail = &mem_pageinfo[i];
  100f65:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  100f68:	c1 e0 03             	shl    $0x3,%eax
  100f6b:	89 c2                	mov    %eax,%edx
  100f6d:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  100f72:	01 c2                	add    %eax,%edx
  100f74:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  100f77:	89 10                	mov    %edx,(%eax)
      freetail = &mem_pageinfo[i].free_next;
  100f79:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  100f7c:	c1 e0 03             	shl    $0x3,%eax
  100f7f:	89 c2                	mov    %eax,%edx
  100f81:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  100f86:	8d 04 02             	lea    (%edx,%eax,1),%eax
  100f89:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
  100f8c:	83 45 e8 01          	addl   $0x1,0xffffffe8(%ebp)
  100f90:	8b 55 e8             	mov    0xffffffe8(%ebp),%edx
  100f93:	a1 84 ed 17 00       	mov    0x17ed84,%eax
  100f98:	39 c2                	cmp    %eax,%edx
  100f9a:	0f 82 0b ff ff ff    	jb     100eab <mem_init+0x13f>
    }
	}

	*freetail = NULL;	// null-terminate the freelist
  100fa0:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  100fa3:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

	// Check to make sure the page allocator seems to work correctly.
	mem_check();
  100fa9:	e8 2e 01 00 00       	call   1010dc <mem_check>
}
  100fae:	c9                   	leave  
  100faf:	c3                   	ret    

00100fb0 <cpu_onboot>:
}

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  100fb0:	55                   	push   %ebp
  100fb1:	89 e5                	mov    %esp,%ebp
  100fb3:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  100fb6:	e8 0d 00 00 00       	call   100fc8 <cpu_cur>
  100fbb:	3d 00 e0 10 00       	cmp    $0x10e000,%eax
  100fc0:	0f 94 c0             	sete   %al
  100fc3:	0f b6 c0             	movzbl %al,%eax
}
  100fc6:	c9                   	leave  
  100fc7:	c3                   	ret    

00100fc8 <cpu_cur>:
  100fc8:	55                   	push   %ebp
  100fc9:	89 e5                	mov    %esp,%ebp
  100fcb:	83 ec 28             	sub    $0x28,%esp
static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  100fce:	89 65 fc             	mov    %esp,0xfffffffc(%ebp)
        return esp;
  100fd1:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  100fd4:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  100fd7:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  100fda:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  100fdf:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	assert(c->magic == CPU_MAGIC);
  100fe2:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  100fe5:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  100feb:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  100ff0:	74 24                	je     101016 <cpu_cur+0x4e>
  100ff2:	c7 44 24 0c 4d c0 10 	movl   $0x10c04d,0xc(%esp)
  100ff9:	00 
  100ffa:	c7 44 24 08 63 c0 10 	movl   $0x10c063,0x8(%esp)
  101001:	00 
  101002:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  101009:	00 
  10100a:	c7 04 24 78 c0 10 00 	movl   $0x10c078,(%esp)
  101011:	e8 22 f9 ff ff       	call   100938 <debug_panic>
	return c;
  101016:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
}
  101019:	c9                   	leave  
  10101a:	c3                   	ret    

0010101b <mem_alloc>:

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
  10101b:	55                   	push   %ebp
  10101c:	89 e5                	mov    %esp,%ebp
  10101e:	83 ec 18             	sub    $0x18,%esp
	// Fill this function in
	// Fill this function in.
//	panic("mem_alloc not implemented.");
  spinlock_acquire(&page_spinlock);
  101021:	c7 04 24 a0 ed 17 00 	movl   $0x17eda0,(%esp)
  101028:	e8 5d 2a 00 00       	call   103a8a <spinlock_acquire>
  pageinfo *pi = mem_freelist;
  10102d:	a1 80 ed 17 00       	mov    0x17ed80,%eax
  101032:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  if (pi != NULL) {
  101035:	83 7d fc 00          	cmpl   $0x0,0xfffffffc(%ebp)
  101039:	74 13                	je     10104e <mem_alloc+0x33>
    mem_freelist = pi->free_next; // move front of list to next pageinfo
  10103b:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  10103e:	8b 00                	mov    (%eax),%eax
  101040:	a3 80 ed 17 00       	mov    %eax,0x17ed80
    pi->free_next = NULL; // remove pointer to next item
  101045:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  101048:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  }
  spinlock_release(&page_spinlock);
  10104e:	c7 04 24 a0 ed 17 00 	movl   $0x17eda0,(%esp)
  101055:	e8 2b 2b 00 00       	call   103b85 <spinlock_release>
  return pi;
  10105a:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
}
  10105d:	c9                   	leave  
  10105e:	c3                   	ret    

0010105f <mem_free>:

//
// Return a page to the free list, given its pageinfo pointer.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
mem_free(pageinfo *pi)
{
  10105f:	55                   	push   %ebp
  101060:	89 e5                	mov    %esp,%ebp
  101062:	83 ec 18             	sub    $0x18,%esp
	// Fill this function in.
	//panic("mem_free not implemented.");
  // do not free in use, or already free pages
  if (pi->refcount != 0)
  101065:	8b 45 08             	mov    0x8(%ebp),%eax
  101068:	8b 40 04             	mov    0x4(%eax),%eax
  10106b:	85 c0                	test   %eax,%eax
  10106d:	74 1c                	je     10108b <mem_free+0x2c>
    panic("mem_free: refcound does not equal zero");
  10106f:	c7 44 24 08 88 c0 10 	movl   $0x10c088,0x8(%esp)
  101076:	00 
  101077:	c7 44 24 04 9f 00 00 	movl   $0x9f,0x4(%esp)
  10107e:	00 
  10107f:	c7 04 24 04 c0 10 00 	movl   $0x10c004,(%esp)
  101086:	e8 ad f8 ff ff       	call   100938 <debug_panic>
  if (pi->free_next != NULL)
  10108b:	8b 45 08             	mov    0x8(%ebp),%eax
  10108e:	8b 00                	mov    (%eax),%eax
  101090:	85 c0                	test   %eax,%eax
  101092:	74 1c                	je     1010b0 <mem_free+0x51>
    panic("mem_free: attempt to free already free page");
  101094:	c7 44 24 08 b0 c0 10 	movl   $0x10c0b0,0x8(%esp)
  10109b:	00 
  10109c:	c7 44 24 04 a1 00 00 	movl   $0xa1,0x4(%esp)
  1010a3:	00 
  1010a4:	c7 04 24 04 c0 10 00 	movl   $0x10c004,(%esp)
  1010ab:	e8 88 f8 ff ff       	call   100938 <debug_panic>

  spinlock_acquire(&page_spinlock);
  1010b0:	c7 04 24 a0 ed 17 00 	movl   $0x17eda0,(%esp)
  1010b7:	e8 ce 29 00 00       	call   103a8a <spinlock_acquire>
  pi->free_next = mem_freelist; // point this to the list
  1010bc:	a1 80 ed 17 00       	mov    0x17ed80,%eax
  1010c1:	8b 55 08             	mov    0x8(%ebp),%edx
  1010c4:	89 02                	mov    %eax,(%edx)
  mem_freelist = pi; // point the front of the list to this
  1010c6:	8b 45 08             	mov    0x8(%ebp),%eax
  1010c9:	a3 80 ed 17 00       	mov    %eax,0x17ed80
  spinlock_release(&page_spinlock);
  1010ce:	c7 04 24 a0 ed 17 00 	movl   $0x17eda0,(%esp)
  1010d5:	e8 ab 2a 00 00       	call   103b85 <spinlock_release>
}
  1010da:	c9                   	leave  
  1010db:	c3                   	ret    

001010dc <mem_check>:

//
// Check the physical page allocator (mem_alloc(), mem_free())
// for correct operation after initialization via mem_init().
//
void
mem_check()
{
  1010dc:	55                   	push   %ebp
  1010dd:	89 e5                	mov    %esp,%ebp
  1010df:	83 ec 38             	sub    $0x38,%esp
	pageinfo *pp, *pp0, *pp1, *pp2;
	pageinfo *fl;
	int i;

        // if there's a page that shouldn't be on
        // the free list, try to make sure it
        // eventually causes trouble.
	int freepages = 0;
  1010e2:	c7 45 fc 00 00 00 00 	movl   $0x0,0xfffffffc(%ebp)
	for (pp = mem_freelist; pp != 0; pp = pp->free_next) {
  1010e9:	a1 80 ed 17 00       	mov    0x17ed80,%eax
  1010ee:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
  1010f1:	eb 35                	jmp    101128 <mem_check+0x4c>
		memset(mem_pi2ptr(pp), 0x97, 128);
  1010f3:	8b 55 e4             	mov    0xffffffe4(%ebp),%edx
  1010f6:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  1010fb:	89 d1                	mov    %edx,%ecx
  1010fd:	29 c1                	sub    %eax,%ecx
  1010ff:	89 c8                	mov    %ecx,%eax
  101101:	c1 e0 09             	shl    $0x9,%eax
  101104:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
  10110b:	00 
  10110c:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
  101113:	00 
  101114:	89 04 24             	mov    %eax,(%esp)
  101117:	e8 ed a6 00 00       	call   10b809 <memset>
		freepages++;
  10111c:	83 45 fc 01          	addl   $0x1,0xfffffffc(%ebp)
  101120:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  101123:	8b 00                	mov    (%eax),%eax
  101125:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
  101128:	83 7d e4 00          	cmpl   $0x0,0xffffffe4(%ebp)
  10112c:	75 c5                	jne    1010f3 <mem_check+0x17>
	}
	cprintf("mem_check: %d free pages\n", freepages);
  10112e:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  101131:	89 44 24 04          	mov    %eax,0x4(%esp)
  101135:	c7 04 24 dc c0 10 00 	movl   $0x10c0dc,(%esp)
  10113c:	e8 44 a3 00 00       	call   10b485 <cprintf>
	assert(freepages < mem_npage);	// can't have more free than total!
  101141:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  101144:	a1 84 ed 17 00       	mov    0x17ed84,%eax
  101149:	39 c2                	cmp    %eax,%edx
  10114b:	72 24                	jb     101171 <mem_check+0x95>
  10114d:	c7 44 24 0c f6 c0 10 	movl   $0x10c0f6,0xc(%esp)
  101154:	00 
  101155:	c7 44 24 08 63 c0 10 	movl   $0x10c063,0x8(%esp)
  10115c:	00 
  10115d:	c7 44 24 04 bd 00 00 	movl   $0xbd,0x4(%esp)
  101164:	00 
  101165:	c7 04 24 04 c0 10 00 	movl   $0x10c004,(%esp)
  10116c:	e8 c7 f7 ff ff       	call   100938 <debug_panic>
	assert(freepages > 16000);	// make sure it's in the right ballpark
  101171:	81 7d fc 80 3e 00 00 	cmpl   $0x3e80,0xfffffffc(%ebp)
  101178:	7f 24                	jg     10119e <mem_check+0xc2>
  10117a:	c7 44 24 0c 0c c1 10 	movl   $0x10c10c,0xc(%esp)
  101181:	00 
  101182:	c7 44 24 08 63 c0 10 	movl   $0x10c063,0x8(%esp)
  101189:	00 
  10118a:	c7 44 24 04 be 00 00 	movl   $0xbe,0x4(%esp)
  101191:	00 
  101192:	c7 04 24 04 c0 10 00 	movl   $0x10c004,(%esp)
  101199:	e8 9a f7 ff ff       	call   100938 <debug_panic>

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
  10119e:	c7 45 f0 00 00 00 00 	movl   $0x0,0xfffffff0(%ebp)
  1011a5:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  1011a8:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  1011ab:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  1011ae:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
	pp0 = mem_alloc(); assert(pp0 != 0);
  1011b1:	e8 65 fe ff ff       	call   10101b <mem_alloc>
  1011b6:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  1011b9:	83 7d e8 00          	cmpl   $0x0,0xffffffe8(%ebp)
  1011bd:	75 24                	jne    1011e3 <mem_check+0x107>
  1011bf:	c7 44 24 0c 1e c1 10 	movl   $0x10c11e,0xc(%esp)
  1011c6:	00 
  1011c7:	c7 44 24 08 63 c0 10 	movl   $0x10c063,0x8(%esp)
  1011ce:	00 
  1011cf:	c7 44 24 04 c2 00 00 	movl   $0xc2,0x4(%esp)
  1011d6:	00 
  1011d7:	c7 04 24 04 c0 10 00 	movl   $0x10c004,(%esp)
  1011de:	e8 55 f7 ff ff       	call   100938 <debug_panic>
	pp1 = mem_alloc(); assert(pp1 != 0);
  1011e3:	e8 33 fe ff ff       	call   10101b <mem_alloc>
  1011e8:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  1011eb:	83 7d ec 00          	cmpl   $0x0,0xffffffec(%ebp)
  1011ef:	75 24                	jne    101215 <mem_check+0x139>
  1011f1:	c7 44 24 0c 27 c1 10 	movl   $0x10c127,0xc(%esp)
  1011f8:	00 
  1011f9:	c7 44 24 08 63 c0 10 	movl   $0x10c063,0x8(%esp)
  101200:	00 
  101201:	c7 44 24 04 c3 00 00 	movl   $0xc3,0x4(%esp)
  101208:	00 
  101209:	c7 04 24 04 c0 10 00 	movl   $0x10c004,(%esp)
  101210:	e8 23 f7 ff ff       	call   100938 <debug_panic>
	pp2 = mem_alloc(); assert(pp2 != 0);
  101215:	e8 01 fe ff ff       	call   10101b <mem_alloc>
  10121a:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
  10121d:	83 7d f0 00          	cmpl   $0x0,0xfffffff0(%ebp)
  101221:	75 24                	jne    101247 <mem_check+0x16b>
  101223:	c7 44 24 0c 30 c1 10 	movl   $0x10c130,0xc(%esp)
  10122a:	00 
  10122b:	c7 44 24 08 63 c0 10 	movl   $0x10c063,0x8(%esp)
  101232:	00 
  101233:	c7 44 24 04 c4 00 00 	movl   $0xc4,0x4(%esp)
  10123a:	00 
  10123b:	c7 04 24 04 c0 10 00 	movl   $0x10c004,(%esp)
  101242:	e8 f1 f6 ff ff       	call   100938 <debug_panic>

	assert(pp0);
  101247:	83 7d e8 00          	cmpl   $0x0,0xffffffe8(%ebp)
  10124b:	75 24                	jne    101271 <mem_check+0x195>
  10124d:	c7 44 24 0c 39 c1 10 	movl   $0x10c139,0xc(%esp)
  101254:	00 
  101255:	c7 44 24 08 63 c0 10 	movl   $0x10c063,0x8(%esp)
  10125c:	00 
  10125d:	c7 44 24 04 c6 00 00 	movl   $0xc6,0x4(%esp)
  101264:	00 
  101265:	c7 04 24 04 c0 10 00 	movl   $0x10c004,(%esp)
  10126c:	e8 c7 f6 ff ff       	call   100938 <debug_panic>
	assert(pp1 && pp1 != pp0);
  101271:	83 7d ec 00          	cmpl   $0x0,0xffffffec(%ebp)
  101275:	74 08                	je     10127f <mem_check+0x1a3>
  101277:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  10127a:	3b 45 e8             	cmp    0xffffffe8(%ebp),%eax
  10127d:	75 24                	jne    1012a3 <mem_check+0x1c7>
  10127f:	c7 44 24 0c 3d c1 10 	movl   $0x10c13d,0xc(%esp)
  101286:	00 
  101287:	c7 44 24 08 63 c0 10 	movl   $0x10c063,0x8(%esp)
  10128e:	00 
  10128f:	c7 44 24 04 c7 00 00 	movl   $0xc7,0x4(%esp)
  101296:	00 
  101297:	c7 04 24 04 c0 10 00 	movl   $0x10c004,(%esp)
  10129e:	e8 95 f6 ff ff       	call   100938 <debug_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
  1012a3:	83 7d f0 00          	cmpl   $0x0,0xfffffff0(%ebp)
  1012a7:	74 10                	je     1012b9 <mem_check+0x1dd>
  1012a9:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  1012ac:	3b 45 ec             	cmp    0xffffffec(%ebp),%eax
  1012af:	74 08                	je     1012b9 <mem_check+0x1dd>
  1012b1:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  1012b4:	3b 45 e8             	cmp    0xffffffe8(%ebp),%eax
  1012b7:	75 24                	jne    1012dd <mem_check+0x201>
  1012b9:	c7 44 24 0c 50 c1 10 	movl   $0x10c150,0xc(%esp)
  1012c0:	00 
  1012c1:	c7 44 24 08 63 c0 10 	movl   $0x10c063,0x8(%esp)
  1012c8:	00 
  1012c9:	c7 44 24 04 c8 00 00 	movl   $0xc8,0x4(%esp)
  1012d0:	00 
  1012d1:	c7 04 24 04 c0 10 00 	movl   $0x10c004,(%esp)
  1012d8:	e8 5b f6 ff ff       	call   100938 <debug_panic>
        assert(mem_pi2phys(pp0) < mem_npage*PAGESIZE);
  1012dd:	8b 55 e8             	mov    0xffffffe8(%ebp),%edx
  1012e0:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  1012e5:	89 d1                	mov    %edx,%ecx
  1012e7:	29 c1                	sub    %eax,%ecx
  1012e9:	89 c8                	mov    %ecx,%eax
  1012eb:	c1 e0 09             	shl    $0x9,%eax
  1012ee:	89 c2                	mov    %eax,%edx
  1012f0:	a1 84 ed 17 00       	mov    0x17ed84,%eax
  1012f5:	c1 e0 0c             	shl    $0xc,%eax
  1012f8:	39 c2                	cmp    %eax,%edx
  1012fa:	72 24                	jb     101320 <mem_check+0x244>
  1012fc:	c7 44 24 0c 70 c1 10 	movl   $0x10c170,0xc(%esp)
  101303:	00 
  101304:	c7 44 24 08 63 c0 10 	movl   $0x10c063,0x8(%esp)
  10130b:	00 
  10130c:	c7 44 24 04 c9 00 00 	movl   $0xc9,0x4(%esp)
  101313:	00 
  101314:	c7 04 24 04 c0 10 00 	movl   $0x10c004,(%esp)
  10131b:	e8 18 f6 ff ff       	call   100938 <debug_panic>
        assert(mem_pi2phys(pp1) < mem_npage*PAGESIZE);
  101320:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
  101323:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  101328:	89 d1                	mov    %edx,%ecx
  10132a:	29 c1                	sub    %eax,%ecx
  10132c:	89 c8                	mov    %ecx,%eax
  10132e:	c1 e0 09             	shl    $0x9,%eax
  101331:	89 c2                	mov    %eax,%edx
  101333:	a1 84 ed 17 00       	mov    0x17ed84,%eax
  101338:	c1 e0 0c             	shl    $0xc,%eax
  10133b:	39 c2                	cmp    %eax,%edx
  10133d:	72 24                	jb     101363 <mem_check+0x287>
  10133f:	c7 44 24 0c 98 c1 10 	movl   $0x10c198,0xc(%esp)
  101346:	00 
  101347:	c7 44 24 08 63 c0 10 	movl   $0x10c063,0x8(%esp)
  10134e:	00 
  10134f:	c7 44 24 04 ca 00 00 	movl   $0xca,0x4(%esp)
  101356:	00 
  101357:	c7 04 24 04 c0 10 00 	movl   $0x10c004,(%esp)
  10135e:	e8 d5 f5 ff ff       	call   100938 <debug_panic>
        assert(mem_pi2phys(pp2) < mem_npage*PAGESIZE);
  101363:	8b 55 f0             	mov    0xfffffff0(%ebp),%edx
  101366:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  10136b:	89 d1                	mov    %edx,%ecx
  10136d:	29 c1                	sub    %eax,%ecx
  10136f:	89 c8                	mov    %ecx,%eax
  101371:	c1 e0 09             	shl    $0x9,%eax
  101374:	89 c2                	mov    %eax,%edx
  101376:	a1 84 ed 17 00       	mov    0x17ed84,%eax
  10137b:	c1 e0 0c             	shl    $0xc,%eax
  10137e:	39 c2                	cmp    %eax,%edx
  101380:	72 24                	jb     1013a6 <mem_check+0x2ca>
  101382:	c7 44 24 0c c0 c1 10 	movl   $0x10c1c0,0xc(%esp)
  101389:	00 
  10138a:	c7 44 24 08 63 c0 10 	movl   $0x10c063,0x8(%esp)
  101391:	00 
  101392:	c7 44 24 04 cb 00 00 	movl   $0xcb,0x4(%esp)
  101399:	00 
  10139a:	c7 04 24 04 c0 10 00 	movl   $0x10c004,(%esp)
  1013a1:	e8 92 f5 ff ff       	call   100938 <debug_panic>

	// temporarily steal the rest of the free pages
	fl = mem_freelist;
  1013a6:	a1 80 ed 17 00       	mov    0x17ed80,%eax
  1013ab:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	mem_freelist = 0;
  1013ae:	c7 05 80 ed 17 00 00 	movl   $0x0,0x17ed80
  1013b5:	00 00 00 

	// should be no free memory
	assert(mem_alloc() == 0);
  1013b8:	e8 5e fc ff ff       	call   10101b <mem_alloc>
  1013bd:	85 c0                	test   %eax,%eax
  1013bf:	74 24                	je     1013e5 <mem_check+0x309>
  1013c1:	c7 44 24 0c e6 c1 10 	movl   $0x10c1e6,0xc(%esp)
  1013c8:	00 
  1013c9:	c7 44 24 08 63 c0 10 	movl   $0x10c063,0x8(%esp)
  1013d0:	00 
  1013d1:	c7 44 24 04 d2 00 00 	movl   $0xd2,0x4(%esp)
  1013d8:	00 
  1013d9:	c7 04 24 04 c0 10 00 	movl   $0x10c004,(%esp)
  1013e0:	e8 53 f5 ff ff       	call   100938 <debug_panic>

        // free and re-allocate?
        mem_free(pp0);
  1013e5:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  1013e8:	89 04 24             	mov    %eax,(%esp)
  1013eb:	e8 6f fc ff ff       	call   10105f <mem_free>
        mem_free(pp1);
  1013f0:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  1013f3:	89 04 24             	mov    %eax,(%esp)
  1013f6:	e8 64 fc ff ff       	call   10105f <mem_free>
        mem_free(pp2);
  1013fb:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  1013fe:	89 04 24             	mov    %eax,(%esp)
  101401:	e8 59 fc ff ff       	call   10105f <mem_free>
	pp0 = pp1 = pp2 = 0;
  101406:	c7 45 f0 00 00 00 00 	movl   $0x0,0xfffffff0(%ebp)
  10140d:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  101410:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  101413:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  101416:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
	pp0 = mem_alloc(); assert(pp0 != 0);
  101419:	e8 fd fb ff ff       	call   10101b <mem_alloc>
  10141e:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  101421:	83 7d e8 00          	cmpl   $0x0,0xffffffe8(%ebp)
  101425:	75 24                	jne    10144b <mem_check+0x36f>
  101427:	c7 44 24 0c 1e c1 10 	movl   $0x10c11e,0xc(%esp)
  10142e:	00 
  10142f:	c7 44 24 08 63 c0 10 	movl   $0x10c063,0x8(%esp)
  101436:	00 
  101437:	c7 44 24 04 d9 00 00 	movl   $0xd9,0x4(%esp)
  10143e:	00 
  10143f:	c7 04 24 04 c0 10 00 	movl   $0x10c004,(%esp)
  101446:	e8 ed f4 ff ff       	call   100938 <debug_panic>
	pp1 = mem_alloc(); assert(pp1 != 0);
  10144b:	e8 cb fb ff ff       	call   10101b <mem_alloc>
  101450:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  101453:	83 7d ec 00          	cmpl   $0x0,0xffffffec(%ebp)
  101457:	75 24                	jne    10147d <mem_check+0x3a1>
  101459:	c7 44 24 0c 27 c1 10 	movl   $0x10c127,0xc(%esp)
  101460:	00 
  101461:	c7 44 24 08 63 c0 10 	movl   $0x10c063,0x8(%esp)
  101468:	00 
  101469:	c7 44 24 04 da 00 00 	movl   $0xda,0x4(%esp)
  101470:	00 
  101471:	c7 04 24 04 c0 10 00 	movl   $0x10c004,(%esp)
  101478:	e8 bb f4 ff ff       	call   100938 <debug_panic>
	pp2 = mem_alloc(); assert(pp2 != 0);
  10147d:	e8 99 fb ff ff       	call   10101b <mem_alloc>
  101482:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
  101485:	83 7d f0 00          	cmpl   $0x0,0xfffffff0(%ebp)
  101489:	75 24                	jne    1014af <mem_check+0x3d3>
  10148b:	c7 44 24 0c 30 c1 10 	movl   $0x10c130,0xc(%esp)
  101492:	00 
  101493:	c7 44 24 08 63 c0 10 	movl   $0x10c063,0x8(%esp)
  10149a:	00 
  10149b:	c7 44 24 04 db 00 00 	movl   $0xdb,0x4(%esp)
  1014a2:	00 
  1014a3:	c7 04 24 04 c0 10 00 	movl   $0x10c004,(%esp)
  1014aa:	e8 89 f4 ff ff       	call   100938 <debug_panic>
	assert(pp0);
  1014af:	83 7d e8 00          	cmpl   $0x0,0xffffffe8(%ebp)
  1014b3:	75 24                	jne    1014d9 <mem_check+0x3fd>
  1014b5:	c7 44 24 0c 39 c1 10 	movl   $0x10c139,0xc(%esp)
  1014bc:	00 
  1014bd:	c7 44 24 08 63 c0 10 	movl   $0x10c063,0x8(%esp)
  1014c4:	00 
  1014c5:	c7 44 24 04 dc 00 00 	movl   $0xdc,0x4(%esp)
  1014cc:	00 
  1014cd:	c7 04 24 04 c0 10 00 	movl   $0x10c004,(%esp)
  1014d4:	e8 5f f4 ff ff       	call   100938 <debug_panic>
	assert(pp1 && pp1 != pp0);
  1014d9:	83 7d ec 00          	cmpl   $0x0,0xffffffec(%ebp)
  1014dd:	74 08                	je     1014e7 <mem_check+0x40b>
  1014df:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  1014e2:	3b 45 e8             	cmp    0xffffffe8(%ebp),%eax
  1014e5:	75 24                	jne    10150b <mem_check+0x42f>
  1014e7:	c7 44 24 0c 3d c1 10 	movl   $0x10c13d,0xc(%esp)
  1014ee:	00 
  1014ef:	c7 44 24 08 63 c0 10 	movl   $0x10c063,0x8(%esp)
  1014f6:	00 
  1014f7:	c7 44 24 04 dd 00 00 	movl   $0xdd,0x4(%esp)
  1014fe:	00 
  1014ff:	c7 04 24 04 c0 10 00 	movl   $0x10c004,(%esp)
  101506:	e8 2d f4 ff ff       	call   100938 <debug_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
  10150b:	83 7d f0 00          	cmpl   $0x0,0xfffffff0(%ebp)
  10150f:	74 10                	je     101521 <mem_check+0x445>
  101511:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  101514:	3b 45 ec             	cmp    0xffffffec(%ebp),%eax
  101517:	74 08                	je     101521 <mem_check+0x445>
  101519:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  10151c:	3b 45 e8             	cmp    0xffffffe8(%ebp),%eax
  10151f:	75 24                	jne    101545 <mem_check+0x469>
  101521:	c7 44 24 0c 50 c1 10 	movl   $0x10c150,0xc(%esp)
  101528:	00 
  101529:	c7 44 24 08 63 c0 10 	movl   $0x10c063,0x8(%esp)
  101530:	00 
  101531:	c7 44 24 04 de 00 00 	movl   $0xde,0x4(%esp)
  101538:	00 
  101539:	c7 04 24 04 c0 10 00 	movl   $0x10c004,(%esp)
  101540:	e8 f3 f3 ff ff       	call   100938 <debug_panic>
	assert(mem_alloc() == 0);
  101545:	e8 d1 fa ff ff       	call   10101b <mem_alloc>
  10154a:	85 c0                	test   %eax,%eax
  10154c:	74 24                	je     101572 <mem_check+0x496>
  10154e:	c7 44 24 0c e6 c1 10 	movl   $0x10c1e6,0xc(%esp)
  101555:	00 
  101556:	c7 44 24 08 63 c0 10 	movl   $0x10c063,0x8(%esp)
  10155d:	00 
  10155e:	c7 44 24 04 df 00 00 	movl   $0xdf,0x4(%esp)
  101565:	00 
  101566:	c7 04 24 04 c0 10 00 	movl   $0x10c004,(%esp)
  10156d:	e8 c6 f3 ff ff       	call   100938 <debug_panic>

	// give free list back
	mem_freelist = fl;
  101572:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  101575:	a3 80 ed 17 00       	mov    %eax,0x17ed80

	// free the pages we took
	mem_free(pp0);
  10157a:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  10157d:	89 04 24             	mov    %eax,(%esp)
  101580:	e8 da fa ff ff       	call   10105f <mem_free>
	mem_free(pp1);
  101585:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  101588:	89 04 24             	mov    %eax,(%esp)
  10158b:	e8 cf fa ff ff       	call   10105f <mem_free>
	mem_free(pp2);
  101590:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  101593:	89 04 24             	mov    %eax,(%esp)
  101596:	e8 c4 fa ff ff       	call   10105f <mem_free>

	cprintf("mem_check() succeeded!\n");
  10159b:	c7 04 24 f7 c1 10 00 	movl   $0x10c1f7,(%esp)
  1015a2:	e8 de 9e 00 00       	call   10b485 <cprintf>
}
  1015a7:	c9                   	leave  
  1015a8:	c3                   	ret    
  1015a9:	90                   	nop    
  1015aa:	90                   	nop    
  1015ab:	90                   	nop    

001015ac <cpu_init>:
};


void cpu_init()
{
  1015ac:	55                   	push   %ebp
  1015ad:	89 e5                	mov    %esp,%ebp
  1015af:	53                   	push   %ebx
  1015b0:	83 ec 14             	sub    $0x14,%esp
	cpu *c = cpu_cur();
  1015b3:	e8 23 01 00 00       	call   1016db <cpu_cur>
  1015b8:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)

  c->tss.ts_esp0 = (uint32_t) c->kstackhi;
  1015bb:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  1015be:	05 00 10 00 00       	add    $0x1000,%eax
  1015c3:	89 c2                	mov    %eax,%edx
  1015c5:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  1015c8:	89 50 3c             	mov    %edx,0x3c(%eax)
  c->tss.ts_ss0 = CPU_GDT_KDATA;
  1015cb:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  1015ce:	66 c7 40 40 10 00    	movw   $0x10,0x40(%eax)

  c->gdt[CPU_GDT_TSS >> 3] = SEGDESC16(0, STS_T32A, (uint32_t) (&c->tss),
  1015d4:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  1015d7:	83 c0 38             	add    $0x38,%eax
  1015da:	89 c2                	mov    %eax,%edx
  1015dc:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  1015df:	83 c0 38             	add    $0x38,%eax
  1015e2:	c1 e8 10             	shr    $0x10,%eax
  1015e5:	89 c1                	mov    %eax,%ecx
  1015e7:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  1015ea:	83 c0 38             	add    $0x38,%eax
  1015ed:	c1 e8 18             	shr    $0x18,%eax
  1015f0:	89 c3                	mov    %eax,%ebx
  1015f2:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  1015f5:	66 c7 40 30 67 00    	movw   $0x67,0x30(%eax)
  1015fb:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  1015fe:	66 89 50 32          	mov    %dx,0x32(%eax)
  101602:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  101605:	88 48 34             	mov    %cl,0x34(%eax)
  101608:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  10160b:	0f b6 42 35          	movzbl 0x35(%edx),%eax
  10160f:	83 e0 f0             	and    $0xfffffff0,%eax
  101612:	83 c8 09             	or     $0x9,%eax
  101615:	88 42 35             	mov    %al,0x35(%edx)
  101618:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  10161b:	0f b6 42 35          	movzbl 0x35(%edx),%eax
  10161f:	83 e0 ef             	and    $0xffffffef,%eax
  101622:	88 42 35             	mov    %al,0x35(%edx)
  101625:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  101628:	0f b6 42 35          	movzbl 0x35(%edx),%eax
  10162c:	83 e0 9f             	and    $0xffffff9f,%eax
  10162f:	88 42 35             	mov    %al,0x35(%edx)
  101632:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  101635:	0f b6 42 35          	movzbl 0x35(%edx),%eax
  101639:	83 c8 80             	or     $0xffffff80,%eax
  10163c:	88 42 35             	mov    %al,0x35(%edx)
  10163f:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  101642:	0f b6 42 36          	movzbl 0x36(%edx),%eax
  101646:	83 e0 f0             	and    $0xfffffff0,%eax
  101649:	88 42 36             	mov    %al,0x36(%edx)
  10164c:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  10164f:	0f b6 42 36          	movzbl 0x36(%edx),%eax
  101653:	83 e0 ef             	and    $0xffffffef,%eax
  101656:	88 42 36             	mov    %al,0x36(%edx)
  101659:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  10165c:	0f b6 42 36          	movzbl 0x36(%edx),%eax
  101660:	83 e0 df             	and    $0xffffffdf,%eax
  101663:	88 42 36             	mov    %al,0x36(%edx)
  101666:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  101669:	0f b6 42 36          	movzbl 0x36(%edx),%eax
  10166d:	83 c8 40             	or     $0x40,%eax
  101670:	88 42 36             	mov    %al,0x36(%edx)
  101673:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  101676:	0f b6 42 36          	movzbl 0x36(%edx),%eax
  10167a:	83 e0 7f             	and    $0x7f,%eax
  10167d:	88 42 36             	mov    %al,0x36(%edx)
  101680:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  101683:	88 58 37             	mov    %bl,0x37(%eax)
                              sizeof(taskstate)-1, 0);

	// Load the GDT
	struct pseudodesc gdt_pd = {
		sizeof(c->gdt) - 1, (uint32_t) c->gdt };
  101686:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  101689:	66 c7 45 ee 37 00    	movw   $0x37,0xffffffee(%ebp)
  10168f:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
	asm volatile("lgdt %0" : : "m" (gdt_pd));
  101692:	0f 01 55 ee          	lgdtl  0xffffffee(%ebp)

	// Reload all segment registers.
	asm volatile("movw %%ax,%%gs" :: "a" (CPU_GDT_UDATA|3));
  101696:	b8 23 00 00 00       	mov    $0x23,%eax
  10169b:	8e e8                	movl   %eax,%gs
	asm volatile("movw %%ax,%%fs" :: "a" (CPU_GDT_UDATA|3));
  10169d:	b8 23 00 00 00       	mov    $0x23,%eax
  1016a2:	8e e0                	movl   %eax,%fs
	asm volatile("movw %%ax,%%es" :: "a" (CPU_GDT_KDATA));
  1016a4:	b8 10 00 00 00       	mov    $0x10,%eax
  1016a9:	8e c0                	movl   %eax,%es
	asm volatile("movw %%ax,%%ds" :: "a" (CPU_GDT_KDATA));
  1016ab:	b8 10 00 00 00       	mov    $0x10,%eax
  1016b0:	8e d8                	movl   %eax,%ds
	asm volatile("movw %%ax,%%ss" :: "a" (CPU_GDT_KDATA));
  1016b2:	b8 10 00 00 00       	mov    $0x10,%eax
  1016b7:	8e d0                	movl   %eax,%ss
	asm volatile("ljmp %0,$1f\n 1:\n" :: "i" (CPU_GDT_KCODE)); // reload CS
  1016b9:	ea c0 16 10 00 08 00 	ljmp   $0x8,$0x1016c0

	// We don't need an LDT.
	asm volatile("lldt %%ax" :: "a" (0));
  1016c0:	b8 00 00 00 00       	mov    $0x0,%eax
  1016c5:	0f 00 d0             	lldt   %ax
  1016c8:	66 c7 45 fa 30 00    	movw   $0x30,0xfffffffa(%ebp)

static gcc_inline void
ltr(uint16_t sel)
{
	__asm __volatile("ltr %0" : : "r" (sel));
  1016ce:	0f b7 45 fa          	movzwl 0xfffffffa(%ebp),%eax
  1016d2:	0f 00 d8             	ltr    %ax
  ltr(CPU_GDT_TSS);
}
  1016d5:	83 c4 14             	add    $0x14,%esp
  1016d8:	5b                   	pop    %ebx
  1016d9:	5d                   	pop    %ebp
  1016da:	c3                   	ret    

001016db <cpu_cur>:

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  1016db:	55                   	push   %ebp
  1016dc:	89 e5                	mov    %esp,%ebp
  1016de:	83 ec 28             	sub    $0x28,%esp
static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  1016e1:	89 65 fc             	mov    %esp,0xfffffffc(%ebp)
        return esp;
  1016e4:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  1016e7:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  1016ea:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1016ed:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1016f2:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	assert(c->magic == CPU_MAGIC);
  1016f5:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  1016f8:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  1016fe:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  101703:	74 24                	je     101729 <cpu_cur+0x4e>
  101705:	c7 44 24 0c 0f c2 10 	movl   $0x10c20f,0xc(%esp)
  10170c:	00 
  10170d:	c7 44 24 08 25 c2 10 	movl   $0x10c225,0x8(%esp)
  101714:	00 
  101715:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  10171c:	00 
  10171d:	c7 04 24 3a c2 10 00 	movl   $0x10c23a,(%esp)
  101724:	e8 0f f2 ff ff       	call   100938 <debug_panic>
	return c;
  101729:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
}
  10172c:	c9                   	leave  
  10172d:	c3                   	ret    

0010172e <cpu_alloc>:

// Allocate an additional cpu struct representing a non-bootstrap processor.
cpu *
cpu_alloc(void)
{
  10172e:	55                   	push   %ebp
  10172f:	89 e5                	mov    %esp,%ebp
  101731:	83 ec 28             	sub    $0x28,%esp
	// Pointer to the cpu.next pointer of the last CPU on the list,
	// for chaining on new CPUs in cpu_alloc().  Note: static.
	static cpu **cpu_tail = &cpu_boot.next;

	pageinfo *pi = mem_alloc();
  101734:	e8 e2 f8 ff ff       	call   10101b <mem_alloc>
  101739:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
	assert(pi != 0);	// shouldn't be out of memory just yet!
  10173c:	83 7d f8 00          	cmpl   $0x0,0xfffffff8(%ebp)
  101740:	75 24                	jne    101766 <cpu_alloc+0x38>
  101742:	c7 44 24 0c 47 c2 10 	movl   $0x10c247,0xc(%esp)
  101749:	00 
  10174a:	c7 44 24 08 25 c2 10 	movl   $0x10c225,0x8(%esp)
  101751:	00 
  101752:	c7 44 24 04 5e 00 00 	movl   $0x5e,0x4(%esp)
  101759:	00 
  10175a:	c7 04 24 4f c2 10 00 	movl   $0x10c24f,(%esp)
  101761:	e8 d2 f1 ff ff       	call   100938 <debug_panic>

	cpu *c = (cpu*) mem_pi2ptr(pi);
  101766:	8b 55 f8             	mov    0xfffffff8(%ebp),%edx
  101769:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  10176e:	89 d1                	mov    %edx,%ecx
  101770:	29 c1                	sub    %eax,%ecx
  101772:	89 c8                	mov    %ecx,%eax
  101774:	c1 e0 09             	shl    $0x9,%eax
  101777:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)

	// Clear the whole page for good measure: cpu struct and kernel stack
	memset(c, 0, PAGESIZE);
  10177a:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  101781:	00 
  101782:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  101789:	00 
  10178a:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  10178d:	89 04 24             	mov    %eax,(%esp)
  101790:	e8 74 a0 00 00       	call   10b809 <memset>

	// Now we need to initialize the new cpu struct
	// just to the same degree that cpu_boot was statically initialized.
	// The rest will be filled in by the CPU itself
	// when it starts up and calls cpu_init().

	// Initialize the new cpu's GDT by copying from the cpu_boot.
	// The TSS descriptor will be filled in later by cpu_init().
	assert(sizeof(c->gdt) == sizeof(segdesc) * CPU_GDT_NDESC);
	memmove(c->gdt, cpu_boot.gdt, sizeof(c->gdt));
  101795:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  101798:	c7 44 24 08 38 00 00 	movl   $0x38,0x8(%esp)
  10179f:	00 
  1017a0:	c7 44 24 04 00 e0 10 	movl   $0x10e000,0x4(%esp)
  1017a7:	00 
  1017a8:	89 04 24             	mov    %eax,(%esp)
  1017ab:	e8 d2 a0 00 00       	call   10b882 <memmove>

	// Magic verification tag for stack overflow/cpu corruption checking
	c->magic = CPU_MAGIC;
  1017b0:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  1017b3:	c7 80 b8 00 00 00 32 	movl   $0x98765432,0xb8(%eax)
  1017ba:	54 76 98 

	// Chain the new CPU onto the tail of the list.
	*cpu_tail = c;
  1017bd:	8b 15 00 f0 10 00    	mov    0x10f000,%edx
  1017c3:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  1017c6:	89 02                	mov    %eax,(%edx)
	cpu_tail = &c->next;
  1017c8:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  1017cb:	05 a8 00 00 00       	add    $0xa8,%eax
  1017d0:	a3 00 f0 10 00       	mov    %eax,0x10f000

	return c;
  1017d5:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
}
  1017d8:	c9                   	leave  
  1017d9:	c3                   	ret    

001017da <cpu_bootothers>:

void
cpu_bootothers(void)
{
  1017da:	55                   	push   %ebp
  1017db:	89 e5                	mov    %esp,%ebp
  1017dd:	83 ec 28             	sub    $0x28,%esp
	extern uint8_t _binary_obj_boot_bootother_start[],
			_binary_obj_boot_bootother_size[];

	if (!cpu_onboot()) {
  1017e0:	e8 b6 00 00 00       	call   10189b <cpu_onboot>
  1017e5:	85 c0                	test   %eax,%eax
  1017e7:	75 1f                	jne    101808 <cpu_bootothers+0x2e>
		// Just inform the boot cpu we've booted.
		xchg(&cpu_cur()->booted, 1);
  1017e9:	e8 ed fe ff ff       	call   1016db <cpu_cur>
  1017ee:	05 b0 00 00 00       	add    $0xb0,%eax
  1017f3:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  1017fa:	00 
  1017fb:	89 04 24             	mov    %eax,(%esp)
  1017fe:	e8 b0 00 00 00       	call   1018b3 <xchg>
		return;
  101803:	e9 91 00 00 00       	jmp    101899 <cpu_bootothers+0xbf>
	}

	// Write bootstrap code to unused memory at 0x1000.
	uint8_t *code = (uint8_t*)0x1000;
  101808:	c7 45 f8 00 10 00 00 	movl   $0x1000,0xfffffff8(%ebp)
	memmove(code, _binary_obj_boot_bootother_start,
  10180f:	b8 6a 00 00 00       	mov    $0x6a,%eax
  101814:	89 44 24 08          	mov    %eax,0x8(%esp)
  101818:	c7 44 24 04 d5 8d 17 	movl   $0x178dd5,0x4(%esp)
  10181f:	00 
  101820:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  101823:	89 04 24             	mov    %eax,(%esp)
  101826:	e8 57 a0 00 00       	call   10b882 <memmove>
		(uint32_t)_binary_obj_boot_bootother_size);

	cpu *c;
	for(c = &cpu_boot; c; c = c->next){
  10182b:	c7 45 fc 00 e0 10 00 	movl   $0x10e000,0xfffffffc(%ebp)
  101832:	eb 5f                	jmp    101893 <cpu_bootothers+0xb9>
		if(c == cpu_cur())  // We''ve started already.
  101834:	e8 a2 fe ff ff       	call   1016db <cpu_cur>
  101839:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  10183c:	74 49                	je     101887 <cpu_bootothers+0xad>
			continue;

		// Fill in %esp, %eip and start code on cpu.
		*(void**)(code-4) = c->kstackhi;
  10183e:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  101841:	83 e8 04             	sub    $0x4,%eax
  101844:	89 c2                	mov    %eax,%edx
  101846:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  101849:	05 00 10 00 00       	add    $0x1000,%eax
  10184e:	89 02                	mov    %eax,(%edx)
		*(void**)(code-8) = init;
  101850:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  101853:	83 e8 08             	sub    $0x8,%eax
  101856:	c7 00 28 00 10 00    	movl   $0x100028,(%eax)
		lapic_startcpu(c->id, (uint32_t)code);
  10185c:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10185f:	89 c2                	mov    %eax,%edx
  101861:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  101864:	0f b6 80 ac 00 00 00 	movzbl 0xac(%eax),%eax
  10186b:	0f b6 c0             	movzbl %al,%eax
  10186e:	89 54 24 04          	mov    %edx,0x4(%esp)
  101872:	89 04 24             	mov    %eax,(%esp)
  101875:	e8 ac 91 00 00       	call   10aa26 <lapic_startcpu>

		// Wait for cpu to get through bootstrap.
		while(c->booted == 0)
  10187a:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  10187d:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
  101883:	85 c0                	test   %eax,%eax
  101885:	74 f3                	je     10187a <cpu_bootothers+0xa0>
  101887:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  10188a:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
  101890:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  101893:	83 7d fc 00          	cmpl   $0x0,0xfffffffc(%ebp)
  101897:	75 9b                	jne    101834 <cpu_bootothers+0x5a>
			;
	}
}
  101899:	c9                   	leave  
  10189a:	c3                   	ret    

0010189b <cpu_onboot>:
}

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  10189b:	55                   	push   %ebp
  10189c:	89 e5                	mov    %esp,%ebp
  10189e:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  1018a1:	e8 35 fe ff ff       	call   1016db <cpu_cur>
  1018a6:	3d 00 e0 10 00       	cmp    $0x10e000,%eax
  1018ab:	0f 94 c0             	sete   %al
  1018ae:	0f b6 c0             	movzbl %al,%eax
}
  1018b1:	c9                   	leave  
  1018b2:	c3                   	ret    

001018b3 <xchg>:

// Atomically set *addr to newval and return the old value of *addr.
static inline uint32_t
xchg(volatile uint32_t *addr, uint32_t newval)
{
  1018b3:	55                   	push   %ebp
  1018b4:	89 e5                	mov    %esp,%ebp
  1018b6:	53                   	push   %ebx
  1018b7:	83 ec 14             	sub    $0x14,%esp
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
  1018ba:	8b 4d 08             	mov    0x8(%ebp),%ecx
  1018bd:	8b 55 0c             	mov    0xc(%ebp),%edx
  1018c0:	8b 45 08             	mov    0x8(%ebp),%eax
  1018c3:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  1018c6:	89 d0                	mov    %edx,%eax
  1018c8:	8b 5d e8             	mov    0xffffffe8(%ebp),%ebx
  1018cb:	f0 87 01             	lock xchg %eax,(%ecx)
  1018ce:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  1018d1:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  1018d4:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
	       "+m" (*addr), "=a" (result) :
	       "1" (newval) :
	       "cc");
	return result;
  1018d7:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
}
  1018da:	83 c4 14             	add    $0x14,%esp
  1018dd:	5b                   	pop    %ebx
  1018de:	5d                   	pop    %ebp
  1018df:	c3                   	ret    

001018e0 <trap_init_idt>:
  1018e0:	55                   	push   %ebp
  1018e1:	89 e5                	mov    %esp,%ebp
  1018e3:	83 ec 10             	sub    $0x10,%esp
  1018e6:	c7 45 fc 00 00 00 00 	movl   $0x0,0xfffffffc(%ebp)
  1018ed:	e9 b5 00 00 00       	jmp    1019a7 <trap_init_idt+0xc7>
  1018f2:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  1018f5:	b8 04 36 10 00       	mov    $0x103604,%eax
  1018fa:	66 89 04 d5 20 a2 17 	mov    %ax,0x17a220(,%edx,8)
  101901:	00 
  101902:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  101905:	66 c7 04 c5 22 a2 17 	movw   $0x8,0x17a222(,%eax,8)
  10190c:	00 08 00 
  10190f:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  101912:	0f b6 04 d5 24 a2 17 	movzbl 0x17a224(,%edx,8),%eax
  101919:	00 
  10191a:	83 e0 e0             	and    $0xffffffe0,%eax
  10191d:	88 04 d5 24 a2 17 00 	mov    %al,0x17a224(,%edx,8)
  101924:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  101927:	0f b6 04 d5 24 a2 17 	movzbl 0x17a224(,%edx,8),%eax
  10192e:	00 
  10192f:	83 e0 1f             	and    $0x1f,%eax
  101932:	88 04 d5 24 a2 17 00 	mov    %al,0x17a224(,%edx,8)
  101939:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  10193c:	0f b6 04 d5 25 a2 17 	movzbl 0x17a225(,%edx,8),%eax
  101943:	00 
  101944:	83 e0 f0             	and    $0xfffffff0,%eax
  101947:	83 c8 0e             	or     $0xe,%eax
  10194a:	88 04 d5 25 a2 17 00 	mov    %al,0x17a225(,%edx,8)
  101951:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  101954:	0f b6 04 d5 25 a2 17 	movzbl 0x17a225(,%edx,8),%eax
  10195b:	00 
  10195c:	83 e0 ef             	and    $0xffffffef,%eax
  10195f:	88 04 d5 25 a2 17 00 	mov    %al,0x17a225(,%edx,8)
  101966:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  101969:	0f b6 04 d5 25 a2 17 	movzbl 0x17a225(,%edx,8),%eax
  101970:	00 
  101971:	83 e0 9f             	and    $0xffffff9f,%eax
  101974:	88 04 d5 25 a2 17 00 	mov    %al,0x17a225(,%edx,8)
  10197b:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  10197e:	0f b6 04 d5 25 a2 17 	movzbl 0x17a225(,%edx,8),%eax
  101985:	00 
  101986:	83 c8 80             	or     $0xffffff80,%eax
  101989:	88 04 d5 25 a2 17 00 	mov    %al,0x17a225(,%edx,8)
  101990:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  101993:	b8 04 36 10 00       	mov    $0x103604,%eax
  101998:	c1 e8 10             	shr    $0x10,%eax
  10199b:	66 89 04 d5 26 a2 17 	mov    %ax,0x17a226(,%edx,8)
  1019a2:	00 
  1019a3:	83 45 fc 01          	addl   $0x1,0xfffffffc(%ebp)
  1019a7:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  1019aa:	3d ff 00 00 00       	cmp    $0xff,%eax
  1019af:	0f 86 3d ff ff ff    	jbe    1018f2 <trap_init_idt+0x12>
  1019b5:	b8 a0 34 10 00       	mov    $0x1034a0,%eax
  1019ba:	66 a3 20 a2 17 00    	mov    %ax,0x17a220
  1019c0:	66 c7 05 22 a2 17 00 	movw   $0x8,0x17a222
  1019c7:	08 00 
  1019c9:	0f b6 05 24 a2 17 00 	movzbl 0x17a224,%eax
  1019d0:	83 e0 e0             	and    $0xffffffe0,%eax
  1019d3:	a2 24 a2 17 00       	mov    %al,0x17a224
  1019d8:	0f b6 05 24 a2 17 00 	movzbl 0x17a224,%eax
  1019df:	83 e0 1f             	and    $0x1f,%eax
  1019e2:	a2 24 a2 17 00       	mov    %al,0x17a224
  1019e7:	0f b6 05 25 a2 17 00 	movzbl 0x17a225,%eax
  1019ee:	83 e0 f0             	and    $0xfffffff0,%eax
  1019f1:	83 c8 0e             	or     $0xe,%eax
  1019f4:	a2 25 a2 17 00       	mov    %al,0x17a225
  1019f9:	0f b6 05 25 a2 17 00 	movzbl 0x17a225,%eax
  101a00:	83 e0 ef             	and    $0xffffffef,%eax
  101a03:	a2 25 a2 17 00       	mov    %al,0x17a225
  101a08:	0f b6 05 25 a2 17 00 	movzbl 0x17a225,%eax
  101a0f:	83 e0 9f             	and    $0xffffff9f,%eax
  101a12:	a2 25 a2 17 00       	mov    %al,0x17a225
  101a17:	0f b6 05 25 a2 17 00 	movzbl 0x17a225,%eax
  101a1e:	83 c8 80             	or     $0xffffff80,%eax
  101a21:	a2 25 a2 17 00       	mov    %al,0x17a225
  101a26:	b8 a0 34 10 00       	mov    $0x1034a0,%eax
  101a2b:	c1 e8 10             	shr    $0x10,%eax
  101a2e:	66 a3 26 a2 17 00    	mov    %ax,0x17a226
  101a34:	b8 aa 34 10 00       	mov    $0x1034aa,%eax
  101a39:	66 a3 28 a2 17 00    	mov    %ax,0x17a228
  101a3f:	66 c7 05 2a a2 17 00 	movw   $0x8,0x17a22a
  101a46:	08 00 
  101a48:	0f b6 05 2c a2 17 00 	movzbl 0x17a22c,%eax
  101a4f:	83 e0 e0             	and    $0xffffffe0,%eax
  101a52:	a2 2c a2 17 00       	mov    %al,0x17a22c
  101a57:	0f b6 05 2c a2 17 00 	movzbl 0x17a22c,%eax
  101a5e:	83 e0 1f             	and    $0x1f,%eax
  101a61:	a2 2c a2 17 00       	mov    %al,0x17a22c
  101a66:	0f b6 05 2d a2 17 00 	movzbl 0x17a22d,%eax
  101a6d:	83 e0 f0             	and    $0xfffffff0,%eax
  101a70:	83 c8 0e             	or     $0xe,%eax
  101a73:	a2 2d a2 17 00       	mov    %al,0x17a22d
  101a78:	0f b6 05 2d a2 17 00 	movzbl 0x17a22d,%eax
  101a7f:	83 e0 ef             	and    $0xffffffef,%eax
  101a82:	a2 2d a2 17 00       	mov    %al,0x17a22d
  101a87:	0f b6 05 2d a2 17 00 	movzbl 0x17a22d,%eax
  101a8e:	83 e0 9f             	and    $0xffffff9f,%eax
  101a91:	a2 2d a2 17 00       	mov    %al,0x17a22d
  101a96:	0f b6 05 2d a2 17 00 	movzbl 0x17a22d,%eax
  101a9d:	83 c8 80             	or     $0xffffff80,%eax
  101aa0:	a2 2d a2 17 00       	mov    %al,0x17a22d
  101aa5:	b8 aa 34 10 00       	mov    $0x1034aa,%eax
  101aaa:	c1 e8 10             	shr    $0x10,%eax
  101aad:	66 a3 2e a2 17 00    	mov    %ax,0x17a22e
  101ab3:	b8 b4 34 10 00       	mov    $0x1034b4,%eax
  101ab8:	66 a3 30 a2 17 00    	mov    %ax,0x17a230
  101abe:	66 c7 05 32 a2 17 00 	movw   $0x8,0x17a232
  101ac5:	08 00 
  101ac7:	0f b6 05 34 a2 17 00 	movzbl 0x17a234,%eax
  101ace:	83 e0 e0             	and    $0xffffffe0,%eax
  101ad1:	a2 34 a2 17 00       	mov    %al,0x17a234
  101ad6:	0f b6 05 34 a2 17 00 	movzbl 0x17a234,%eax
  101add:	83 e0 1f             	and    $0x1f,%eax
  101ae0:	a2 34 a2 17 00       	mov    %al,0x17a234
  101ae5:	0f b6 05 35 a2 17 00 	movzbl 0x17a235,%eax
  101aec:	83 e0 f0             	and    $0xfffffff0,%eax
  101aef:	83 c8 0e             	or     $0xe,%eax
  101af2:	a2 35 a2 17 00       	mov    %al,0x17a235
  101af7:	0f b6 05 35 a2 17 00 	movzbl 0x17a235,%eax
  101afe:	83 e0 ef             	and    $0xffffffef,%eax
  101b01:	a2 35 a2 17 00       	mov    %al,0x17a235
  101b06:	0f b6 05 35 a2 17 00 	movzbl 0x17a235,%eax
  101b0d:	83 e0 9f             	and    $0xffffff9f,%eax
  101b10:	a2 35 a2 17 00       	mov    %al,0x17a235
  101b15:	0f b6 05 35 a2 17 00 	movzbl 0x17a235,%eax
  101b1c:	83 c8 80             	or     $0xffffff80,%eax
  101b1f:	a2 35 a2 17 00       	mov    %al,0x17a235
  101b24:	b8 b4 34 10 00       	mov    $0x1034b4,%eax
  101b29:	c1 e8 10             	shr    $0x10,%eax
  101b2c:	66 a3 36 a2 17 00    	mov    %ax,0x17a236
  101b32:	b8 be 34 10 00       	mov    $0x1034be,%eax
  101b37:	66 a3 38 a2 17 00    	mov    %ax,0x17a238
  101b3d:	66 c7 05 3a a2 17 00 	movw   $0x8,0x17a23a
  101b44:	08 00 
  101b46:	0f b6 05 3c a2 17 00 	movzbl 0x17a23c,%eax
  101b4d:	83 e0 e0             	and    $0xffffffe0,%eax
  101b50:	a2 3c a2 17 00       	mov    %al,0x17a23c
  101b55:	0f b6 05 3c a2 17 00 	movzbl 0x17a23c,%eax
  101b5c:	83 e0 1f             	and    $0x1f,%eax
  101b5f:	a2 3c a2 17 00       	mov    %al,0x17a23c
  101b64:	0f b6 05 3d a2 17 00 	movzbl 0x17a23d,%eax
  101b6b:	83 e0 f0             	and    $0xfffffff0,%eax
  101b6e:	83 c8 0e             	or     $0xe,%eax
  101b71:	a2 3d a2 17 00       	mov    %al,0x17a23d
  101b76:	0f b6 05 3d a2 17 00 	movzbl 0x17a23d,%eax
  101b7d:	83 e0 ef             	and    $0xffffffef,%eax
  101b80:	a2 3d a2 17 00       	mov    %al,0x17a23d
  101b85:	0f b6 05 3d a2 17 00 	movzbl 0x17a23d,%eax
  101b8c:	83 c8 60             	or     $0x60,%eax
  101b8f:	a2 3d a2 17 00       	mov    %al,0x17a23d
  101b94:	0f b6 05 3d a2 17 00 	movzbl 0x17a23d,%eax
  101b9b:	83 c8 80             	or     $0xffffff80,%eax
  101b9e:	a2 3d a2 17 00       	mov    %al,0x17a23d
  101ba3:	b8 be 34 10 00       	mov    $0x1034be,%eax
  101ba8:	c1 e8 10             	shr    $0x10,%eax
  101bab:	66 a3 3e a2 17 00    	mov    %ax,0x17a23e
  101bb1:	b8 c8 34 10 00       	mov    $0x1034c8,%eax
  101bb6:	66 a3 40 a2 17 00    	mov    %ax,0x17a240
  101bbc:	66 c7 05 42 a2 17 00 	movw   $0x8,0x17a242
  101bc3:	08 00 
  101bc5:	0f b6 05 44 a2 17 00 	movzbl 0x17a244,%eax
  101bcc:	83 e0 e0             	and    $0xffffffe0,%eax
  101bcf:	a2 44 a2 17 00       	mov    %al,0x17a244
  101bd4:	0f b6 05 44 a2 17 00 	movzbl 0x17a244,%eax
  101bdb:	83 e0 1f             	and    $0x1f,%eax
  101bde:	a2 44 a2 17 00       	mov    %al,0x17a244
  101be3:	0f b6 05 45 a2 17 00 	movzbl 0x17a245,%eax
  101bea:	83 e0 f0             	and    $0xfffffff0,%eax
  101bed:	83 c8 0e             	or     $0xe,%eax
  101bf0:	a2 45 a2 17 00       	mov    %al,0x17a245
  101bf5:	0f b6 05 45 a2 17 00 	movzbl 0x17a245,%eax
  101bfc:	83 e0 ef             	and    $0xffffffef,%eax
  101bff:	a2 45 a2 17 00       	mov    %al,0x17a245
  101c04:	0f b6 05 45 a2 17 00 	movzbl 0x17a245,%eax
  101c0b:	83 c8 60             	or     $0x60,%eax
  101c0e:	a2 45 a2 17 00       	mov    %al,0x17a245
  101c13:	0f b6 05 45 a2 17 00 	movzbl 0x17a245,%eax
  101c1a:	83 c8 80             	or     $0xffffff80,%eax
  101c1d:	a2 45 a2 17 00       	mov    %al,0x17a245
  101c22:	b8 c8 34 10 00       	mov    $0x1034c8,%eax
  101c27:	c1 e8 10             	shr    $0x10,%eax
  101c2a:	66 a3 46 a2 17 00    	mov    %ax,0x17a246
  101c30:	b8 d2 34 10 00       	mov    $0x1034d2,%eax
  101c35:	66 a3 48 a2 17 00    	mov    %ax,0x17a248
  101c3b:	66 c7 05 4a a2 17 00 	movw   $0x8,0x17a24a
  101c42:	08 00 
  101c44:	0f b6 05 4c a2 17 00 	movzbl 0x17a24c,%eax
  101c4b:	83 e0 e0             	and    $0xffffffe0,%eax
  101c4e:	a2 4c a2 17 00       	mov    %al,0x17a24c
  101c53:	0f b6 05 4c a2 17 00 	movzbl 0x17a24c,%eax
  101c5a:	83 e0 1f             	and    $0x1f,%eax
  101c5d:	a2 4c a2 17 00       	mov    %al,0x17a24c
  101c62:	0f b6 05 4d a2 17 00 	movzbl 0x17a24d,%eax
  101c69:	83 e0 f0             	and    $0xfffffff0,%eax
  101c6c:	83 c8 0e             	or     $0xe,%eax
  101c6f:	a2 4d a2 17 00       	mov    %al,0x17a24d
  101c74:	0f b6 05 4d a2 17 00 	movzbl 0x17a24d,%eax
  101c7b:	83 e0 ef             	and    $0xffffffef,%eax
  101c7e:	a2 4d a2 17 00       	mov    %al,0x17a24d
  101c83:	0f b6 05 4d a2 17 00 	movzbl 0x17a24d,%eax
  101c8a:	83 e0 9f             	and    $0xffffff9f,%eax
  101c8d:	a2 4d a2 17 00       	mov    %al,0x17a24d
  101c92:	0f b6 05 4d a2 17 00 	movzbl 0x17a24d,%eax
  101c99:	83 c8 80             	or     $0xffffff80,%eax
  101c9c:	a2 4d a2 17 00       	mov    %al,0x17a24d
  101ca1:	b8 d2 34 10 00       	mov    $0x1034d2,%eax
  101ca6:	c1 e8 10             	shr    $0x10,%eax
  101ca9:	66 a3 4e a2 17 00    	mov    %ax,0x17a24e
  101caf:	b8 dc 34 10 00       	mov    $0x1034dc,%eax
  101cb4:	66 a3 50 a2 17 00    	mov    %ax,0x17a250
  101cba:	66 c7 05 52 a2 17 00 	movw   $0x8,0x17a252
  101cc1:	08 00 
  101cc3:	0f b6 05 54 a2 17 00 	movzbl 0x17a254,%eax
  101cca:	83 e0 e0             	and    $0xffffffe0,%eax
  101ccd:	a2 54 a2 17 00       	mov    %al,0x17a254
  101cd2:	0f b6 05 54 a2 17 00 	movzbl 0x17a254,%eax
  101cd9:	83 e0 1f             	and    $0x1f,%eax
  101cdc:	a2 54 a2 17 00       	mov    %al,0x17a254
  101ce1:	0f b6 05 55 a2 17 00 	movzbl 0x17a255,%eax
  101ce8:	83 e0 f0             	and    $0xfffffff0,%eax
  101ceb:	83 c8 0e             	or     $0xe,%eax
  101cee:	a2 55 a2 17 00       	mov    %al,0x17a255
  101cf3:	0f b6 05 55 a2 17 00 	movzbl 0x17a255,%eax
  101cfa:	83 e0 ef             	and    $0xffffffef,%eax
  101cfd:	a2 55 a2 17 00       	mov    %al,0x17a255
  101d02:	0f b6 05 55 a2 17 00 	movzbl 0x17a255,%eax
  101d09:	83 e0 9f             	and    $0xffffff9f,%eax
  101d0c:	a2 55 a2 17 00       	mov    %al,0x17a255
  101d11:	0f b6 05 55 a2 17 00 	movzbl 0x17a255,%eax
  101d18:	83 c8 80             	or     $0xffffff80,%eax
  101d1b:	a2 55 a2 17 00       	mov    %al,0x17a255
  101d20:	b8 dc 34 10 00       	mov    $0x1034dc,%eax
  101d25:	c1 e8 10             	shr    $0x10,%eax
  101d28:	66 a3 56 a2 17 00    	mov    %ax,0x17a256
  101d2e:	b8 e6 34 10 00       	mov    $0x1034e6,%eax
  101d33:	66 a3 58 a2 17 00    	mov    %ax,0x17a258
  101d39:	66 c7 05 5a a2 17 00 	movw   $0x8,0x17a25a
  101d40:	08 00 
  101d42:	0f b6 05 5c a2 17 00 	movzbl 0x17a25c,%eax
  101d49:	83 e0 e0             	and    $0xffffffe0,%eax
  101d4c:	a2 5c a2 17 00       	mov    %al,0x17a25c
  101d51:	0f b6 05 5c a2 17 00 	movzbl 0x17a25c,%eax
  101d58:	83 e0 1f             	and    $0x1f,%eax
  101d5b:	a2 5c a2 17 00       	mov    %al,0x17a25c
  101d60:	0f b6 05 5d a2 17 00 	movzbl 0x17a25d,%eax
  101d67:	83 e0 f0             	and    $0xfffffff0,%eax
  101d6a:	83 c8 0e             	or     $0xe,%eax
  101d6d:	a2 5d a2 17 00       	mov    %al,0x17a25d
  101d72:	0f b6 05 5d a2 17 00 	movzbl 0x17a25d,%eax
  101d79:	83 e0 ef             	and    $0xffffffef,%eax
  101d7c:	a2 5d a2 17 00       	mov    %al,0x17a25d
  101d81:	0f b6 05 5d a2 17 00 	movzbl 0x17a25d,%eax
  101d88:	83 e0 9f             	and    $0xffffff9f,%eax
  101d8b:	a2 5d a2 17 00       	mov    %al,0x17a25d
  101d90:	0f b6 05 5d a2 17 00 	movzbl 0x17a25d,%eax
  101d97:	83 c8 80             	or     $0xffffff80,%eax
  101d9a:	a2 5d a2 17 00       	mov    %al,0x17a25d
  101d9f:	b8 e6 34 10 00       	mov    $0x1034e6,%eax
  101da4:	c1 e8 10             	shr    $0x10,%eax
  101da7:	66 a3 5e a2 17 00    	mov    %ax,0x17a25e
  101dad:	b8 f0 34 10 00       	mov    $0x1034f0,%eax
  101db2:	66 a3 60 a2 17 00    	mov    %ax,0x17a260
  101db8:	66 c7 05 62 a2 17 00 	movw   $0x8,0x17a262
  101dbf:	08 00 
  101dc1:	0f b6 05 64 a2 17 00 	movzbl 0x17a264,%eax
  101dc8:	83 e0 e0             	and    $0xffffffe0,%eax
  101dcb:	a2 64 a2 17 00       	mov    %al,0x17a264
  101dd0:	0f b6 05 64 a2 17 00 	movzbl 0x17a264,%eax
  101dd7:	83 e0 1f             	and    $0x1f,%eax
  101dda:	a2 64 a2 17 00       	mov    %al,0x17a264
  101ddf:	0f b6 05 65 a2 17 00 	movzbl 0x17a265,%eax
  101de6:	83 e0 f0             	and    $0xfffffff0,%eax
  101de9:	83 c8 0e             	or     $0xe,%eax
  101dec:	a2 65 a2 17 00       	mov    %al,0x17a265
  101df1:	0f b6 05 65 a2 17 00 	movzbl 0x17a265,%eax
  101df8:	83 e0 ef             	and    $0xffffffef,%eax
  101dfb:	a2 65 a2 17 00       	mov    %al,0x17a265
  101e00:	0f b6 05 65 a2 17 00 	movzbl 0x17a265,%eax
  101e07:	83 e0 9f             	and    $0xffffff9f,%eax
  101e0a:	a2 65 a2 17 00       	mov    %al,0x17a265
  101e0f:	0f b6 05 65 a2 17 00 	movzbl 0x17a265,%eax
  101e16:	83 c8 80             	or     $0xffffff80,%eax
  101e19:	a2 65 a2 17 00       	mov    %al,0x17a265
  101e1e:	b8 f0 34 10 00       	mov    $0x1034f0,%eax
  101e23:	c1 e8 10             	shr    $0x10,%eax
  101e26:	66 a3 66 a2 17 00    	mov    %ax,0x17a266
  101e2c:	b8 f8 34 10 00       	mov    $0x1034f8,%eax
  101e31:	66 a3 70 a2 17 00    	mov    %ax,0x17a270
  101e37:	66 c7 05 72 a2 17 00 	movw   $0x8,0x17a272
  101e3e:	08 00 
  101e40:	0f b6 05 74 a2 17 00 	movzbl 0x17a274,%eax
  101e47:	83 e0 e0             	and    $0xffffffe0,%eax
  101e4a:	a2 74 a2 17 00       	mov    %al,0x17a274
  101e4f:	0f b6 05 74 a2 17 00 	movzbl 0x17a274,%eax
  101e56:	83 e0 1f             	and    $0x1f,%eax
  101e59:	a2 74 a2 17 00       	mov    %al,0x17a274
  101e5e:	0f b6 05 75 a2 17 00 	movzbl 0x17a275,%eax
  101e65:	83 e0 f0             	and    $0xfffffff0,%eax
  101e68:	83 c8 0e             	or     $0xe,%eax
  101e6b:	a2 75 a2 17 00       	mov    %al,0x17a275
  101e70:	0f b6 05 75 a2 17 00 	movzbl 0x17a275,%eax
  101e77:	83 e0 ef             	and    $0xffffffef,%eax
  101e7a:	a2 75 a2 17 00       	mov    %al,0x17a275
  101e7f:	0f b6 05 75 a2 17 00 	movzbl 0x17a275,%eax
  101e86:	83 e0 9f             	and    $0xffffff9f,%eax
  101e89:	a2 75 a2 17 00       	mov    %al,0x17a275
  101e8e:	0f b6 05 75 a2 17 00 	movzbl 0x17a275,%eax
  101e95:	83 c8 80             	or     $0xffffff80,%eax
  101e98:	a2 75 a2 17 00       	mov    %al,0x17a275
  101e9d:	b8 f8 34 10 00       	mov    $0x1034f8,%eax
  101ea2:	c1 e8 10             	shr    $0x10,%eax
  101ea5:	66 a3 76 a2 17 00    	mov    %ax,0x17a276
  101eab:	b8 00 35 10 00       	mov    $0x103500,%eax
  101eb0:	66 a3 78 a2 17 00    	mov    %ax,0x17a278
  101eb6:	66 c7 05 7a a2 17 00 	movw   $0x8,0x17a27a
  101ebd:	08 00 
  101ebf:	0f b6 05 7c a2 17 00 	movzbl 0x17a27c,%eax
  101ec6:	83 e0 e0             	and    $0xffffffe0,%eax
  101ec9:	a2 7c a2 17 00       	mov    %al,0x17a27c
  101ece:	0f b6 05 7c a2 17 00 	movzbl 0x17a27c,%eax
  101ed5:	83 e0 1f             	and    $0x1f,%eax
  101ed8:	a2 7c a2 17 00       	mov    %al,0x17a27c
  101edd:	0f b6 05 7d a2 17 00 	movzbl 0x17a27d,%eax
  101ee4:	83 e0 f0             	and    $0xfffffff0,%eax
  101ee7:	83 c8 0e             	or     $0xe,%eax
  101eea:	a2 7d a2 17 00       	mov    %al,0x17a27d
  101eef:	0f b6 05 7d a2 17 00 	movzbl 0x17a27d,%eax
  101ef6:	83 e0 ef             	and    $0xffffffef,%eax
  101ef9:	a2 7d a2 17 00       	mov    %al,0x17a27d
  101efe:	0f b6 05 7d a2 17 00 	movzbl 0x17a27d,%eax
  101f05:	83 e0 9f             	and    $0xffffff9f,%eax
  101f08:	a2 7d a2 17 00       	mov    %al,0x17a27d
  101f0d:	0f b6 05 7d a2 17 00 	movzbl 0x17a27d,%eax
  101f14:	83 c8 80             	or     $0xffffff80,%eax
  101f17:	a2 7d a2 17 00       	mov    %al,0x17a27d
  101f1c:	b8 00 35 10 00       	mov    $0x103500,%eax
  101f21:	c1 e8 10             	shr    $0x10,%eax
  101f24:	66 a3 7e a2 17 00    	mov    %ax,0x17a27e
  101f2a:	b8 08 35 10 00       	mov    $0x103508,%eax
  101f2f:	66 a3 80 a2 17 00    	mov    %ax,0x17a280
  101f35:	66 c7 05 82 a2 17 00 	movw   $0x8,0x17a282
  101f3c:	08 00 
  101f3e:	0f b6 05 84 a2 17 00 	movzbl 0x17a284,%eax
  101f45:	83 e0 e0             	and    $0xffffffe0,%eax
  101f48:	a2 84 a2 17 00       	mov    %al,0x17a284
  101f4d:	0f b6 05 84 a2 17 00 	movzbl 0x17a284,%eax
  101f54:	83 e0 1f             	and    $0x1f,%eax
  101f57:	a2 84 a2 17 00       	mov    %al,0x17a284
  101f5c:	0f b6 05 85 a2 17 00 	movzbl 0x17a285,%eax
  101f63:	83 e0 f0             	and    $0xfffffff0,%eax
  101f66:	83 c8 0e             	or     $0xe,%eax
  101f69:	a2 85 a2 17 00       	mov    %al,0x17a285
  101f6e:	0f b6 05 85 a2 17 00 	movzbl 0x17a285,%eax
  101f75:	83 e0 ef             	and    $0xffffffef,%eax
  101f78:	a2 85 a2 17 00       	mov    %al,0x17a285
  101f7d:	0f b6 05 85 a2 17 00 	movzbl 0x17a285,%eax
  101f84:	83 e0 9f             	and    $0xffffff9f,%eax
  101f87:	a2 85 a2 17 00       	mov    %al,0x17a285
  101f8c:	0f b6 05 85 a2 17 00 	movzbl 0x17a285,%eax
  101f93:	83 c8 80             	or     $0xffffff80,%eax
  101f96:	a2 85 a2 17 00       	mov    %al,0x17a285
  101f9b:	b8 08 35 10 00       	mov    $0x103508,%eax
  101fa0:	c1 e8 10             	shr    $0x10,%eax
  101fa3:	66 a3 86 a2 17 00    	mov    %ax,0x17a286
  101fa9:	b8 10 35 10 00       	mov    $0x103510,%eax
  101fae:	66 a3 88 a2 17 00    	mov    %ax,0x17a288
  101fb4:	66 c7 05 8a a2 17 00 	movw   $0x8,0x17a28a
  101fbb:	08 00 
  101fbd:	0f b6 05 8c a2 17 00 	movzbl 0x17a28c,%eax
  101fc4:	83 e0 e0             	and    $0xffffffe0,%eax
  101fc7:	a2 8c a2 17 00       	mov    %al,0x17a28c
  101fcc:	0f b6 05 8c a2 17 00 	movzbl 0x17a28c,%eax
  101fd3:	83 e0 1f             	and    $0x1f,%eax
  101fd6:	a2 8c a2 17 00       	mov    %al,0x17a28c
  101fdb:	0f b6 05 8d a2 17 00 	movzbl 0x17a28d,%eax
  101fe2:	83 e0 f0             	and    $0xfffffff0,%eax
  101fe5:	83 c8 0e             	or     $0xe,%eax
  101fe8:	a2 8d a2 17 00       	mov    %al,0x17a28d
  101fed:	0f b6 05 8d a2 17 00 	movzbl 0x17a28d,%eax
  101ff4:	83 e0 ef             	and    $0xffffffef,%eax
  101ff7:	a2 8d a2 17 00       	mov    %al,0x17a28d
  101ffc:	0f b6 05 8d a2 17 00 	movzbl 0x17a28d,%eax
  102003:	83 e0 9f             	and    $0xffffff9f,%eax
  102006:	a2 8d a2 17 00       	mov    %al,0x17a28d
  10200b:	0f b6 05 8d a2 17 00 	movzbl 0x17a28d,%eax
  102012:	83 c8 80             	or     $0xffffff80,%eax
  102015:	a2 8d a2 17 00       	mov    %al,0x17a28d
  10201a:	b8 10 35 10 00       	mov    $0x103510,%eax
  10201f:	c1 e8 10             	shr    $0x10,%eax
  102022:	66 a3 8e a2 17 00    	mov    %ax,0x17a28e
  102028:	b8 18 35 10 00       	mov    $0x103518,%eax
  10202d:	66 a3 90 a2 17 00    	mov    %ax,0x17a290
  102033:	66 c7 05 92 a2 17 00 	movw   $0x8,0x17a292
  10203a:	08 00 
  10203c:	0f b6 05 94 a2 17 00 	movzbl 0x17a294,%eax
  102043:	83 e0 e0             	and    $0xffffffe0,%eax
  102046:	a2 94 a2 17 00       	mov    %al,0x17a294
  10204b:	0f b6 05 94 a2 17 00 	movzbl 0x17a294,%eax
  102052:	83 e0 1f             	and    $0x1f,%eax
  102055:	a2 94 a2 17 00       	mov    %al,0x17a294
  10205a:	0f b6 05 95 a2 17 00 	movzbl 0x17a295,%eax
  102061:	83 e0 f0             	and    $0xfffffff0,%eax
  102064:	83 c8 0e             	or     $0xe,%eax
  102067:	a2 95 a2 17 00       	mov    %al,0x17a295
  10206c:	0f b6 05 95 a2 17 00 	movzbl 0x17a295,%eax
  102073:	83 e0 ef             	and    $0xffffffef,%eax
  102076:	a2 95 a2 17 00       	mov    %al,0x17a295
  10207b:	0f b6 05 95 a2 17 00 	movzbl 0x17a295,%eax
  102082:	83 e0 9f             	and    $0xffffff9f,%eax
  102085:	a2 95 a2 17 00       	mov    %al,0x17a295
  10208a:	0f b6 05 95 a2 17 00 	movzbl 0x17a295,%eax
  102091:	83 c8 80             	or     $0xffffff80,%eax
  102094:	a2 95 a2 17 00       	mov    %al,0x17a295
  102099:	b8 18 35 10 00       	mov    $0x103518,%eax
  10209e:	c1 e8 10             	shr    $0x10,%eax
  1020a1:	66 a3 96 a2 17 00    	mov    %ax,0x17a296
  1020a7:	b8 20 35 10 00       	mov    $0x103520,%eax
  1020ac:	66 a3 a0 a2 17 00    	mov    %ax,0x17a2a0
  1020b2:	66 c7 05 a2 a2 17 00 	movw   $0x8,0x17a2a2
  1020b9:	08 00 
  1020bb:	0f b6 05 a4 a2 17 00 	movzbl 0x17a2a4,%eax
  1020c2:	83 e0 e0             	and    $0xffffffe0,%eax
  1020c5:	a2 a4 a2 17 00       	mov    %al,0x17a2a4
  1020ca:	0f b6 05 a4 a2 17 00 	movzbl 0x17a2a4,%eax
  1020d1:	83 e0 1f             	and    $0x1f,%eax
  1020d4:	a2 a4 a2 17 00       	mov    %al,0x17a2a4
  1020d9:	0f b6 05 a5 a2 17 00 	movzbl 0x17a2a5,%eax
  1020e0:	83 e0 f0             	and    $0xfffffff0,%eax
  1020e3:	83 c8 0e             	or     $0xe,%eax
  1020e6:	a2 a5 a2 17 00       	mov    %al,0x17a2a5
  1020eb:	0f b6 05 a5 a2 17 00 	movzbl 0x17a2a5,%eax
  1020f2:	83 e0 ef             	and    $0xffffffef,%eax
  1020f5:	a2 a5 a2 17 00       	mov    %al,0x17a2a5
  1020fa:	0f b6 05 a5 a2 17 00 	movzbl 0x17a2a5,%eax
  102101:	83 e0 9f             	and    $0xffffff9f,%eax
  102104:	a2 a5 a2 17 00       	mov    %al,0x17a2a5
  102109:	0f b6 05 a5 a2 17 00 	movzbl 0x17a2a5,%eax
  102110:	83 c8 80             	or     $0xffffff80,%eax
  102113:	a2 a5 a2 17 00       	mov    %al,0x17a2a5
  102118:	b8 20 35 10 00       	mov    $0x103520,%eax
  10211d:	c1 e8 10             	shr    $0x10,%eax
  102120:	66 a3 a6 a2 17 00    	mov    %ax,0x17a2a6
  102126:	b8 2a 35 10 00       	mov    $0x10352a,%eax
  10212b:	66 a3 a8 a2 17 00    	mov    %ax,0x17a2a8
  102131:	66 c7 05 aa a2 17 00 	movw   $0x8,0x17a2aa
  102138:	08 00 
  10213a:	0f b6 05 ac a2 17 00 	movzbl 0x17a2ac,%eax
  102141:	83 e0 e0             	and    $0xffffffe0,%eax
  102144:	a2 ac a2 17 00       	mov    %al,0x17a2ac
  102149:	0f b6 05 ac a2 17 00 	movzbl 0x17a2ac,%eax
  102150:	83 e0 1f             	and    $0x1f,%eax
  102153:	a2 ac a2 17 00       	mov    %al,0x17a2ac
  102158:	0f b6 05 ad a2 17 00 	movzbl 0x17a2ad,%eax
  10215f:	83 e0 f0             	and    $0xfffffff0,%eax
  102162:	83 c8 0e             	or     $0xe,%eax
  102165:	a2 ad a2 17 00       	mov    %al,0x17a2ad
  10216a:	0f b6 05 ad a2 17 00 	movzbl 0x17a2ad,%eax
  102171:	83 e0 ef             	and    $0xffffffef,%eax
  102174:	a2 ad a2 17 00       	mov    %al,0x17a2ad
  102179:	0f b6 05 ad a2 17 00 	movzbl 0x17a2ad,%eax
  102180:	83 e0 9f             	and    $0xffffff9f,%eax
  102183:	a2 ad a2 17 00       	mov    %al,0x17a2ad
  102188:	0f b6 05 ad a2 17 00 	movzbl 0x17a2ad,%eax
  10218f:	83 c8 80             	or     $0xffffff80,%eax
  102192:	a2 ad a2 17 00       	mov    %al,0x17a2ad
  102197:	b8 2a 35 10 00       	mov    $0x10352a,%eax
  10219c:	c1 e8 10             	shr    $0x10,%eax
  10219f:	66 a3 ae a2 17 00    	mov    %ax,0x17a2ae
  1021a5:	b8 32 35 10 00       	mov    $0x103532,%eax
  1021aa:	66 a3 b0 a2 17 00    	mov    %ax,0x17a2b0
  1021b0:	66 c7 05 b2 a2 17 00 	movw   $0x8,0x17a2b2
  1021b7:	08 00 
  1021b9:	0f b6 05 b4 a2 17 00 	movzbl 0x17a2b4,%eax
  1021c0:	83 e0 e0             	and    $0xffffffe0,%eax
  1021c3:	a2 b4 a2 17 00       	mov    %al,0x17a2b4
  1021c8:	0f b6 05 b4 a2 17 00 	movzbl 0x17a2b4,%eax
  1021cf:	83 e0 1f             	and    $0x1f,%eax
  1021d2:	a2 b4 a2 17 00       	mov    %al,0x17a2b4
  1021d7:	0f b6 05 b5 a2 17 00 	movzbl 0x17a2b5,%eax
  1021de:	83 e0 f0             	and    $0xfffffff0,%eax
  1021e1:	83 c8 0e             	or     $0xe,%eax
  1021e4:	a2 b5 a2 17 00       	mov    %al,0x17a2b5
  1021e9:	0f b6 05 b5 a2 17 00 	movzbl 0x17a2b5,%eax
  1021f0:	83 e0 ef             	and    $0xffffffef,%eax
  1021f3:	a2 b5 a2 17 00       	mov    %al,0x17a2b5
  1021f8:	0f b6 05 b5 a2 17 00 	movzbl 0x17a2b5,%eax
  1021ff:	83 e0 9f             	and    $0xffffff9f,%eax
  102202:	a2 b5 a2 17 00       	mov    %al,0x17a2b5
  102207:	0f b6 05 b5 a2 17 00 	movzbl 0x17a2b5,%eax
  10220e:	83 c8 80             	or     $0xffffff80,%eax
  102211:	a2 b5 a2 17 00       	mov    %al,0x17a2b5
  102216:	b8 32 35 10 00       	mov    $0x103532,%eax
  10221b:	c1 e8 10             	shr    $0x10,%eax
  10221e:	66 a3 b6 a2 17 00    	mov    %ax,0x17a2b6
  102224:	b8 3c 35 10 00       	mov    $0x10353c,%eax
  102229:	66 a3 b8 a2 17 00    	mov    %ax,0x17a2b8
  10222f:	66 c7 05 ba a2 17 00 	movw   $0x8,0x17a2ba
  102236:	08 00 
  102238:	0f b6 05 bc a2 17 00 	movzbl 0x17a2bc,%eax
  10223f:	83 e0 e0             	and    $0xffffffe0,%eax
  102242:	a2 bc a2 17 00       	mov    %al,0x17a2bc
  102247:	0f b6 05 bc a2 17 00 	movzbl 0x17a2bc,%eax
  10224e:	83 e0 1f             	and    $0x1f,%eax
  102251:	a2 bc a2 17 00       	mov    %al,0x17a2bc
  102256:	0f b6 05 bd a2 17 00 	movzbl 0x17a2bd,%eax
  10225d:	83 e0 f0             	and    $0xfffffff0,%eax
  102260:	83 c8 0e             	or     $0xe,%eax
  102263:	a2 bd a2 17 00       	mov    %al,0x17a2bd
  102268:	0f b6 05 bd a2 17 00 	movzbl 0x17a2bd,%eax
  10226f:	83 e0 ef             	and    $0xffffffef,%eax
  102272:	a2 bd a2 17 00       	mov    %al,0x17a2bd
  102277:	0f b6 05 bd a2 17 00 	movzbl 0x17a2bd,%eax
  10227e:	83 e0 9f             	and    $0xffffff9f,%eax
  102281:	a2 bd a2 17 00       	mov    %al,0x17a2bd
  102286:	0f b6 05 bd a2 17 00 	movzbl 0x17a2bd,%eax
  10228d:	83 c8 80             	or     $0xffffff80,%eax
  102290:	a2 bd a2 17 00       	mov    %al,0x17a2bd
  102295:	b8 3c 35 10 00       	mov    $0x10353c,%eax
  10229a:	c1 e8 10             	shr    $0x10,%eax
  10229d:	66 a3 be a2 17 00    	mov    %ax,0x17a2be
  1022a3:	b8 46 35 10 00       	mov    $0x103546,%eax
  1022a8:	66 a3 20 a3 17 00    	mov    %ax,0x17a320
  1022ae:	66 c7 05 22 a3 17 00 	movw   $0x8,0x17a322
  1022b5:	08 00 
  1022b7:	0f b6 05 24 a3 17 00 	movzbl 0x17a324,%eax
  1022be:	83 e0 e0             	and    $0xffffffe0,%eax
  1022c1:	a2 24 a3 17 00       	mov    %al,0x17a324
  1022c6:	0f b6 05 24 a3 17 00 	movzbl 0x17a324,%eax
  1022cd:	83 e0 1f             	and    $0x1f,%eax
  1022d0:	a2 24 a3 17 00       	mov    %al,0x17a324
  1022d5:	0f b6 05 25 a3 17 00 	movzbl 0x17a325,%eax
  1022dc:	83 e0 f0             	and    $0xfffffff0,%eax
  1022df:	83 c8 0e             	or     $0xe,%eax
  1022e2:	a2 25 a3 17 00       	mov    %al,0x17a325
  1022e7:	0f b6 05 25 a3 17 00 	movzbl 0x17a325,%eax
  1022ee:	83 e0 ef             	and    $0xffffffef,%eax
  1022f1:	a2 25 a3 17 00       	mov    %al,0x17a325
  1022f6:	0f b6 05 25 a3 17 00 	movzbl 0x17a325,%eax
  1022fd:	83 e0 9f             	and    $0xffffff9f,%eax
  102300:	a2 25 a3 17 00       	mov    %al,0x17a325
  102305:	0f b6 05 25 a3 17 00 	movzbl 0x17a325,%eax
  10230c:	83 c8 80             	or     $0xffffff80,%eax
  10230f:	a2 25 a3 17 00       	mov    %al,0x17a325
  102314:	b8 46 35 10 00       	mov    $0x103546,%eax
  102319:	c1 e8 10             	shr    $0x10,%eax
  10231c:	66 a3 26 a3 17 00    	mov    %ax,0x17a326
  102322:	b8 50 35 10 00       	mov    $0x103550,%eax
  102327:	66 a3 28 a3 17 00    	mov    %ax,0x17a328
  10232d:	66 c7 05 2a a3 17 00 	movw   $0x8,0x17a32a
  102334:	08 00 
  102336:	0f b6 05 2c a3 17 00 	movzbl 0x17a32c,%eax
  10233d:	83 e0 e0             	and    $0xffffffe0,%eax
  102340:	a2 2c a3 17 00       	mov    %al,0x17a32c
  102345:	0f b6 05 2c a3 17 00 	movzbl 0x17a32c,%eax
  10234c:	83 e0 1f             	and    $0x1f,%eax
  10234f:	a2 2c a3 17 00       	mov    %al,0x17a32c
  102354:	0f b6 05 2d a3 17 00 	movzbl 0x17a32d,%eax
  10235b:	83 e0 f0             	and    $0xfffffff0,%eax
  10235e:	83 c8 0e             	or     $0xe,%eax
  102361:	a2 2d a3 17 00       	mov    %al,0x17a32d
  102366:	0f b6 05 2d a3 17 00 	movzbl 0x17a32d,%eax
  10236d:	83 e0 ef             	and    $0xffffffef,%eax
  102370:	a2 2d a3 17 00       	mov    %al,0x17a32d
  102375:	0f b6 05 2d a3 17 00 	movzbl 0x17a32d,%eax
  10237c:	83 e0 9f             	and    $0xffffff9f,%eax
  10237f:	a2 2d a3 17 00       	mov    %al,0x17a32d
  102384:	0f b6 05 2d a3 17 00 	movzbl 0x17a32d,%eax
  10238b:	83 c8 80             	or     $0xffffff80,%eax
  10238e:	a2 2d a3 17 00       	mov    %al,0x17a32d
  102393:	b8 50 35 10 00       	mov    $0x103550,%eax
  102398:	c1 e8 10             	shr    $0x10,%eax
  10239b:	66 a3 2e a3 17 00    	mov    %ax,0x17a32e
  1023a1:	b8 5a 35 10 00       	mov    $0x10355a,%eax
  1023a6:	66 a3 30 a3 17 00    	mov    %ax,0x17a330
  1023ac:	66 c7 05 32 a3 17 00 	movw   $0x8,0x17a332
  1023b3:	08 00 
  1023b5:	0f b6 05 34 a3 17 00 	movzbl 0x17a334,%eax
  1023bc:	83 e0 e0             	and    $0xffffffe0,%eax
  1023bf:	a2 34 a3 17 00       	mov    %al,0x17a334
  1023c4:	0f b6 05 34 a3 17 00 	movzbl 0x17a334,%eax
  1023cb:	83 e0 1f             	and    $0x1f,%eax
  1023ce:	a2 34 a3 17 00       	mov    %al,0x17a334
  1023d3:	0f b6 05 35 a3 17 00 	movzbl 0x17a335,%eax
  1023da:	83 e0 f0             	and    $0xfffffff0,%eax
  1023dd:	83 c8 0e             	or     $0xe,%eax
  1023e0:	a2 35 a3 17 00       	mov    %al,0x17a335
  1023e5:	0f b6 05 35 a3 17 00 	movzbl 0x17a335,%eax
  1023ec:	83 e0 ef             	and    $0xffffffef,%eax
  1023ef:	a2 35 a3 17 00       	mov    %al,0x17a335
  1023f4:	0f b6 05 35 a3 17 00 	movzbl 0x17a335,%eax
  1023fb:	83 e0 9f             	and    $0xffffff9f,%eax
  1023fe:	a2 35 a3 17 00       	mov    %al,0x17a335
  102403:	0f b6 05 35 a3 17 00 	movzbl 0x17a335,%eax
  10240a:	83 c8 80             	or     $0xffffff80,%eax
  10240d:	a2 35 a3 17 00       	mov    %al,0x17a335
  102412:	b8 5a 35 10 00       	mov    $0x10355a,%eax
  102417:	c1 e8 10             	shr    $0x10,%eax
  10241a:	66 a3 36 a3 17 00    	mov    %ax,0x17a336
  102420:	b8 64 35 10 00       	mov    $0x103564,%eax
  102425:	66 a3 38 a3 17 00    	mov    %ax,0x17a338
  10242b:	66 c7 05 3a a3 17 00 	movw   $0x8,0x17a33a
  102432:	08 00 
  102434:	0f b6 05 3c a3 17 00 	movzbl 0x17a33c,%eax
  10243b:	83 e0 e0             	and    $0xffffffe0,%eax
  10243e:	a2 3c a3 17 00       	mov    %al,0x17a33c
  102443:	0f b6 05 3c a3 17 00 	movzbl 0x17a33c,%eax
  10244a:	83 e0 1f             	and    $0x1f,%eax
  10244d:	a2 3c a3 17 00       	mov    %al,0x17a33c
  102452:	0f b6 05 3d a3 17 00 	movzbl 0x17a33d,%eax
  102459:	83 e0 f0             	and    $0xfffffff0,%eax
  10245c:	83 c8 0e             	or     $0xe,%eax
  10245f:	a2 3d a3 17 00       	mov    %al,0x17a33d
  102464:	0f b6 05 3d a3 17 00 	movzbl 0x17a33d,%eax
  10246b:	83 e0 ef             	and    $0xffffffef,%eax
  10246e:	a2 3d a3 17 00       	mov    %al,0x17a33d
  102473:	0f b6 05 3d a3 17 00 	movzbl 0x17a33d,%eax
  10247a:	83 e0 9f             	and    $0xffffff9f,%eax
  10247d:	a2 3d a3 17 00       	mov    %al,0x17a33d
  102482:	0f b6 05 3d a3 17 00 	movzbl 0x17a33d,%eax
  102489:	83 c8 80             	or     $0xffffff80,%eax
  10248c:	a2 3d a3 17 00       	mov    %al,0x17a33d
  102491:	b8 64 35 10 00       	mov    $0x103564,%eax
  102496:	c1 e8 10             	shr    $0x10,%eax
  102499:	66 a3 3e a3 17 00    	mov    %ax,0x17a33e
  10249f:	b8 6e 35 10 00       	mov    $0x10356e,%eax
  1024a4:	66 a3 40 a3 17 00    	mov    %ax,0x17a340
  1024aa:	66 c7 05 42 a3 17 00 	movw   $0x8,0x17a342
  1024b1:	08 00 
  1024b3:	0f b6 05 44 a3 17 00 	movzbl 0x17a344,%eax
  1024ba:	83 e0 e0             	and    $0xffffffe0,%eax
  1024bd:	a2 44 a3 17 00       	mov    %al,0x17a344
  1024c2:	0f b6 05 44 a3 17 00 	movzbl 0x17a344,%eax
  1024c9:	83 e0 1f             	and    $0x1f,%eax
  1024cc:	a2 44 a3 17 00       	mov    %al,0x17a344
  1024d1:	0f b6 05 45 a3 17 00 	movzbl 0x17a345,%eax
  1024d8:	83 e0 f0             	and    $0xfffffff0,%eax
  1024db:	83 c8 0e             	or     $0xe,%eax
  1024de:	a2 45 a3 17 00       	mov    %al,0x17a345
  1024e3:	0f b6 05 45 a3 17 00 	movzbl 0x17a345,%eax
  1024ea:	83 e0 ef             	and    $0xffffffef,%eax
  1024ed:	a2 45 a3 17 00       	mov    %al,0x17a345
  1024f2:	0f b6 05 45 a3 17 00 	movzbl 0x17a345,%eax
  1024f9:	83 e0 9f             	and    $0xffffff9f,%eax
  1024fc:	a2 45 a3 17 00       	mov    %al,0x17a345
  102501:	0f b6 05 45 a3 17 00 	movzbl 0x17a345,%eax
  102508:	83 c8 80             	or     $0xffffff80,%eax
  10250b:	a2 45 a3 17 00       	mov    %al,0x17a345
  102510:	b8 6e 35 10 00       	mov    $0x10356e,%eax
  102515:	c1 e8 10             	shr    $0x10,%eax
  102518:	66 a3 46 a3 17 00    	mov    %ax,0x17a346
  10251e:	b8 78 35 10 00       	mov    $0x103578,%eax
  102523:	66 a3 48 a3 17 00    	mov    %ax,0x17a348
  102529:	66 c7 05 4a a3 17 00 	movw   $0x8,0x17a34a
  102530:	08 00 
  102532:	0f b6 05 4c a3 17 00 	movzbl 0x17a34c,%eax
  102539:	83 e0 e0             	and    $0xffffffe0,%eax
  10253c:	a2 4c a3 17 00       	mov    %al,0x17a34c
  102541:	0f b6 05 4c a3 17 00 	movzbl 0x17a34c,%eax
  102548:	83 e0 1f             	and    $0x1f,%eax
  10254b:	a2 4c a3 17 00       	mov    %al,0x17a34c
  102550:	0f b6 05 4d a3 17 00 	movzbl 0x17a34d,%eax
  102557:	83 e0 f0             	and    $0xfffffff0,%eax
  10255a:	83 c8 0e             	or     $0xe,%eax
  10255d:	a2 4d a3 17 00       	mov    %al,0x17a34d
  102562:	0f b6 05 4d a3 17 00 	movzbl 0x17a34d,%eax
  102569:	83 e0 ef             	and    $0xffffffef,%eax
  10256c:	a2 4d a3 17 00       	mov    %al,0x17a34d
  102571:	0f b6 05 4d a3 17 00 	movzbl 0x17a34d,%eax
  102578:	83 e0 9f             	and    $0xffffff9f,%eax
  10257b:	a2 4d a3 17 00       	mov    %al,0x17a34d
  102580:	0f b6 05 4d a3 17 00 	movzbl 0x17a34d,%eax
  102587:	83 c8 80             	or     $0xffffff80,%eax
  10258a:	a2 4d a3 17 00       	mov    %al,0x17a34d
  10258f:	b8 78 35 10 00       	mov    $0x103578,%eax
  102594:	c1 e8 10             	shr    $0x10,%eax
  102597:	66 a3 4e a3 17 00    	mov    %ax,0x17a34e
  10259d:	b8 82 35 10 00       	mov    $0x103582,%eax
  1025a2:	66 a3 50 a3 17 00    	mov    %ax,0x17a350
  1025a8:	66 c7 05 52 a3 17 00 	movw   $0x8,0x17a352
  1025af:	08 00 
  1025b1:	0f b6 05 54 a3 17 00 	movzbl 0x17a354,%eax
  1025b8:	83 e0 e0             	and    $0xffffffe0,%eax
  1025bb:	a2 54 a3 17 00       	mov    %al,0x17a354
  1025c0:	0f b6 05 54 a3 17 00 	movzbl 0x17a354,%eax
  1025c7:	83 e0 1f             	and    $0x1f,%eax
  1025ca:	a2 54 a3 17 00       	mov    %al,0x17a354
  1025cf:	0f b6 05 55 a3 17 00 	movzbl 0x17a355,%eax
  1025d6:	83 e0 f0             	and    $0xfffffff0,%eax
  1025d9:	83 c8 0e             	or     $0xe,%eax
  1025dc:	a2 55 a3 17 00       	mov    %al,0x17a355
  1025e1:	0f b6 05 55 a3 17 00 	movzbl 0x17a355,%eax
  1025e8:	83 e0 ef             	and    $0xffffffef,%eax
  1025eb:	a2 55 a3 17 00       	mov    %al,0x17a355
  1025f0:	0f b6 05 55 a3 17 00 	movzbl 0x17a355,%eax
  1025f7:	83 e0 9f             	and    $0xffffff9f,%eax
  1025fa:	a2 55 a3 17 00       	mov    %al,0x17a355
  1025ff:	0f b6 05 55 a3 17 00 	movzbl 0x17a355,%eax
  102606:	83 c8 80             	or     $0xffffff80,%eax
  102609:	a2 55 a3 17 00       	mov    %al,0x17a355
  10260e:	b8 82 35 10 00       	mov    $0x103582,%eax
  102613:	c1 e8 10             	shr    $0x10,%eax
  102616:	66 a3 56 a3 17 00    	mov    %ax,0x17a356
  10261c:	b8 8c 35 10 00       	mov    $0x10358c,%eax
  102621:	66 a3 58 a3 17 00    	mov    %ax,0x17a358
  102627:	66 c7 05 5a a3 17 00 	movw   $0x8,0x17a35a
  10262e:	08 00 
  102630:	0f b6 05 5c a3 17 00 	movzbl 0x17a35c,%eax
  102637:	83 e0 e0             	and    $0xffffffe0,%eax
  10263a:	a2 5c a3 17 00       	mov    %al,0x17a35c
  10263f:	0f b6 05 5c a3 17 00 	movzbl 0x17a35c,%eax
  102646:	83 e0 1f             	and    $0x1f,%eax
  102649:	a2 5c a3 17 00       	mov    %al,0x17a35c
  10264e:	0f b6 05 5d a3 17 00 	movzbl 0x17a35d,%eax
  102655:	83 e0 f0             	and    $0xfffffff0,%eax
  102658:	83 c8 0e             	or     $0xe,%eax
  10265b:	a2 5d a3 17 00       	mov    %al,0x17a35d
  102660:	0f b6 05 5d a3 17 00 	movzbl 0x17a35d,%eax
  102667:	83 e0 ef             	and    $0xffffffef,%eax
  10266a:	a2 5d a3 17 00       	mov    %al,0x17a35d
  10266f:	0f b6 05 5d a3 17 00 	movzbl 0x17a35d,%eax
  102676:	83 e0 9f             	and    $0xffffff9f,%eax
  102679:	a2 5d a3 17 00       	mov    %al,0x17a35d
  10267e:	0f b6 05 5d a3 17 00 	movzbl 0x17a35d,%eax
  102685:	83 c8 80             	or     $0xffffff80,%eax
  102688:	a2 5d a3 17 00       	mov    %al,0x17a35d
  10268d:	b8 8c 35 10 00       	mov    $0x10358c,%eax
  102692:	c1 e8 10             	shr    $0x10,%eax
  102695:	66 a3 5e a3 17 00    	mov    %ax,0x17a35e
  10269b:	b8 96 35 10 00       	mov    $0x103596,%eax
  1026a0:	66 a3 60 a3 17 00    	mov    %ax,0x17a360
  1026a6:	66 c7 05 62 a3 17 00 	movw   $0x8,0x17a362
  1026ad:	08 00 
  1026af:	0f b6 05 64 a3 17 00 	movzbl 0x17a364,%eax
  1026b6:	83 e0 e0             	and    $0xffffffe0,%eax
  1026b9:	a2 64 a3 17 00       	mov    %al,0x17a364
  1026be:	0f b6 05 64 a3 17 00 	movzbl 0x17a364,%eax
  1026c5:	83 e0 1f             	and    $0x1f,%eax
  1026c8:	a2 64 a3 17 00       	mov    %al,0x17a364
  1026cd:	0f b6 05 65 a3 17 00 	movzbl 0x17a365,%eax
  1026d4:	83 e0 f0             	and    $0xfffffff0,%eax
  1026d7:	83 c8 0e             	or     $0xe,%eax
  1026da:	a2 65 a3 17 00       	mov    %al,0x17a365
  1026df:	0f b6 05 65 a3 17 00 	movzbl 0x17a365,%eax
  1026e6:	83 e0 ef             	and    $0xffffffef,%eax
  1026e9:	a2 65 a3 17 00       	mov    %al,0x17a365
  1026ee:	0f b6 05 65 a3 17 00 	movzbl 0x17a365,%eax
  1026f5:	83 e0 9f             	and    $0xffffff9f,%eax
  1026f8:	a2 65 a3 17 00       	mov    %al,0x17a365
  1026fd:	0f b6 05 65 a3 17 00 	movzbl 0x17a365,%eax
  102704:	83 c8 80             	or     $0xffffff80,%eax
  102707:	a2 65 a3 17 00       	mov    %al,0x17a365
  10270c:	b8 96 35 10 00       	mov    $0x103596,%eax
  102711:	c1 e8 10             	shr    $0x10,%eax
  102714:	66 a3 66 a3 17 00    	mov    %ax,0x17a366
  10271a:	b8 a0 35 10 00       	mov    $0x1035a0,%eax
  10271f:	66 a3 68 a3 17 00    	mov    %ax,0x17a368
  102725:	66 c7 05 6a a3 17 00 	movw   $0x8,0x17a36a
  10272c:	08 00 
  10272e:	0f b6 05 6c a3 17 00 	movzbl 0x17a36c,%eax
  102735:	83 e0 e0             	and    $0xffffffe0,%eax
  102738:	a2 6c a3 17 00       	mov    %al,0x17a36c
  10273d:	0f b6 05 6c a3 17 00 	movzbl 0x17a36c,%eax
  102744:	83 e0 1f             	and    $0x1f,%eax
  102747:	a2 6c a3 17 00       	mov    %al,0x17a36c
  10274c:	0f b6 05 6d a3 17 00 	movzbl 0x17a36d,%eax
  102753:	83 e0 f0             	and    $0xfffffff0,%eax
  102756:	83 c8 0e             	or     $0xe,%eax
  102759:	a2 6d a3 17 00       	mov    %al,0x17a36d
  10275e:	0f b6 05 6d a3 17 00 	movzbl 0x17a36d,%eax
  102765:	83 e0 ef             	and    $0xffffffef,%eax
  102768:	a2 6d a3 17 00       	mov    %al,0x17a36d
  10276d:	0f b6 05 6d a3 17 00 	movzbl 0x17a36d,%eax
  102774:	83 e0 9f             	and    $0xffffff9f,%eax
  102777:	a2 6d a3 17 00       	mov    %al,0x17a36d
  10277c:	0f b6 05 6d a3 17 00 	movzbl 0x17a36d,%eax
  102783:	83 c8 80             	or     $0xffffff80,%eax
  102786:	a2 6d a3 17 00       	mov    %al,0x17a36d
  10278b:	b8 a0 35 10 00       	mov    $0x1035a0,%eax
  102790:	c1 e8 10             	shr    $0x10,%eax
  102793:	66 a3 6e a3 17 00    	mov    %ax,0x17a36e
  102799:	b8 aa 35 10 00       	mov    $0x1035aa,%eax
  10279e:	66 a3 70 a3 17 00    	mov    %ax,0x17a370
  1027a4:	66 c7 05 72 a3 17 00 	movw   $0x8,0x17a372
  1027ab:	08 00 
  1027ad:	0f b6 05 74 a3 17 00 	movzbl 0x17a374,%eax
  1027b4:	83 e0 e0             	and    $0xffffffe0,%eax
  1027b7:	a2 74 a3 17 00       	mov    %al,0x17a374
  1027bc:	0f b6 05 74 a3 17 00 	movzbl 0x17a374,%eax
  1027c3:	83 e0 1f             	and    $0x1f,%eax
  1027c6:	a2 74 a3 17 00       	mov    %al,0x17a374
  1027cb:	0f b6 05 75 a3 17 00 	movzbl 0x17a375,%eax
  1027d2:	83 e0 f0             	and    $0xfffffff0,%eax
  1027d5:	83 c8 0e             	or     $0xe,%eax
  1027d8:	a2 75 a3 17 00       	mov    %al,0x17a375
  1027dd:	0f b6 05 75 a3 17 00 	movzbl 0x17a375,%eax
  1027e4:	83 e0 ef             	and    $0xffffffef,%eax
  1027e7:	a2 75 a3 17 00       	mov    %al,0x17a375
  1027ec:	0f b6 05 75 a3 17 00 	movzbl 0x17a375,%eax
  1027f3:	83 e0 9f             	and    $0xffffff9f,%eax
  1027f6:	a2 75 a3 17 00       	mov    %al,0x17a375
  1027fb:	0f b6 05 75 a3 17 00 	movzbl 0x17a375,%eax
  102802:	83 c8 80             	or     $0xffffff80,%eax
  102805:	a2 75 a3 17 00       	mov    %al,0x17a375
  10280a:	b8 aa 35 10 00       	mov    $0x1035aa,%eax
  10280f:	c1 e8 10             	shr    $0x10,%eax
  102812:	66 a3 76 a3 17 00    	mov    %ax,0x17a376
  102818:	b8 b4 35 10 00       	mov    $0x1035b4,%eax
  10281d:	66 a3 78 a3 17 00    	mov    %ax,0x17a378
  102823:	66 c7 05 7a a3 17 00 	movw   $0x8,0x17a37a
  10282a:	08 00 
  10282c:	0f b6 05 7c a3 17 00 	movzbl 0x17a37c,%eax
  102833:	83 e0 e0             	and    $0xffffffe0,%eax
  102836:	a2 7c a3 17 00       	mov    %al,0x17a37c
  10283b:	0f b6 05 7c a3 17 00 	movzbl 0x17a37c,%eax
  102842:	83 e0 1f             	and    $0x1f,%eax
  102845:	a2 7c a3 17 00       	mov    %al,0x17a37c
  10284a:	0f b6 05 7d a3 17 00 	movzbl 0x17a37d,%eax
  102851:	83 e0 f0             	and    $0xfffffff0,%eax
  102854:	83 c8 0e             	or     $0xe,%eax
  102857:	a2 7d a3 17 00       	mov    %al,0x17a37d
  10285c:	0f b6 05 7d a3 17 00 	movzbl 0x17a37d,%eax
  102863:	83 e0 ef             	and    $0xffffffef,%eax
  102866:	a2 7d a3 17 00       	mov    %al,0x17a37d
  10286b:	0f b6 05 7d a3 17 00 	movzbl 0x17a37d,%eax
  102872:	83 e0 9f             	and    $0xffffff9f,%eax
  102875:	a2 7d a3 17 00       	mov    %al,0x17a37d
  10287a:	0f b6 05 7d a3 17 00 	movzbl 0x17a37d,%eax
  102881:	83 c8 80             	or     $0xffffff80,%eax
  102884:	a2 7d a3 17 00       	mov    %al,0x17a37d
  102889:	b8 b4 35 10 00       	mov    $0x1035b4,%eax
  10288e:	c1 e8 10             	shr    $0x10,%eax
  102891:	66 a3 7e a3 17 00    	mov    %ax,0x17a37e
  102897:	b8 be 35 10 00       	mov    $0x1035be,%eax
  10289c:	66 a3 80 a3 17 00    	mov    %ax,0x17a380
  1028a2:	66 c7 05 82 a3 17 00 	movw   $0x8,0x17a382
  1028a9:	08 00 
  1028ab:	0f b6 05 84 a3 17 00 	movzbl 0x17a384,%eax
  1028b2:	83 e0 e0             	and    $0xffffffe0,%eax
  1028b5:	a2 84 a3 17 00       	mov    %al,0x17a384
  1028ba:	0f b6 05 84 a3 17 00 	movzbl 0x17a384,%eax
  1028c1:	83 e0 1f             	and    $0x1f,%eax
  1028c4:	a2 84 a3 17 00       	mov    %al,0x17a384
  1028c9:	0f b6 05 85 a3 17 00 	movzbl 0x17a385,%eax
  1028d0:	83 e0 f0             	and    $0xfffffff0,%eax
  1028d3:	83 c8 0e             	or     $0xe,%eax
  1028d6:	a2 85 a3 17 00       	mov    %al,0x17a385
  1028db:	0f b6 05 85 a3 17 00 	movzbl 0x17a385,%eax
  1028e2:	83 e0 ef             	and    $0xffffffef,%eax
  1028e5:	a2 85 a3 17 00       	mov    %al,0x17a385
  1028ea:	0f b6 05 85 a3 17 00 	movzbl 0x17a385,%eax
  1028f1:	83 e0 9f             	and    $0xffffff9f,%eax
  1028f4:	a2 85 a3 17 00       	mov    %al,0x17a385
  1028f9:	0f b6 05 85 a3 17 00 	movzbl 0x17a385,%eax
  102900:	83 c8 80             	or     $0xffffff80,%eax
  102903:	a2 85 a3 17 00       	mov    %al,0x17a385
  102908:	b8 be 35 10 00       	mov    $0x1035be,%eax
  10290d:	c1 e8 10             	shr    $0x10,%eax
  102910:	66 a3 86 a3 17 00    	mov    %ax,0x17a386
  102916:	b8 c8 35 10 00       	mov    $0x1035c8,%eax
  10291b:	66 a3 88 a3 17 00    	mov    %ax,0x17a388
  102921:	66 c7 05 8a a3 17 00 	movw   $0x8,0x17a38a
  102928:	08 00 
  10292a:	0f b6 05 8c a3 17 00 	movzbl 0x17a38c,%eax
  102931:	83 e0 e0             	and    $0xffffffe0,%eax
  102934:	a2 8c a3 17 00       	mov    %al,0x17a38c
  102939:	0f b6 05 8c a3 17 00 	movzbl 0x17a38c,%eax
  102940:	83 e0 1f             	and    $0x1f,%eax
  102943:	a2 8c a3 17 00       	mov    %al,0x17a38c
  102948:	0f b6 05 8d a3 17 00 	movzbl 0x17a38d,%eax
  10294f:	83 e0 f0             	and    $0xfffffff0,%eax
  102952:	83 c8 0e             	or     $0xe,%eax
  102955:	a2 8d a3 17 00       	mov    %al,0x17a38d
  10295a:	0f b6 05 8d a3 17 00 	movzbl 0x17a38d,%eax
  102961:	83 e0 ef             	and    $0xffffffef,%eax
  102964:	a2 8d a3 17 00       	mov    %al,0x17a38d
  102969:	0f b6 05 8d a3 17 00 	movzbl 0x17a38d,%eax
  102970:	83 e0 9f             	and    $0xffffff9f,%eax
  102973:	a2 8d a3 17 00       	mov    %al,0x17a38d
  102978:	0f b6 05 8d a3 17 00 	movzbl 0x17a38d,%eax
  10297f:	83 c8 80             	or     $0xffffff80,%eax
  102982:	a2 8d a3 17 00       	mov    %al,0x17a38d
  102987:	b8 c8 35 10 00       	mov    $0x1035c8,%eax
  10298c:	c1 e8 10             	shr    $0x10,%eax
  10298f:	66 a3 8e a3 17 00    	mov    %ax,0x17a38e
  102995:	b8 d2 35 10 00       	mov    $0x1035d2,%eax
  10299a:	66 a3 90 a3 17 00    	mov    %ax,0x17a390
  1029a0:	66 c7 05 92 a3 17 00 	movw   $0x8,0x17a392
  1029a7:	08 00 
  1029a9:	0f b6 05 94 a3 17 00 	movzbl 0x17a394,%eax
  1029b0:	83 e0 e0             	and    $0xffffffe0,%eax
  1029b3:	a2 94 a3 17 00       	mov    %al,0x17a394
  1029b8:	0f b6 05 94 a3 17 00 	movzbl 0x17a394,%eax
  1029bf:	83 e0 1f             	and    $0x1f,%eax
  1029c2:	a2 94 a3 17 00       	mov    %al,0x17a394
  1029c7:	0f b6 05 95 a3 17 00 	movzbl 0x17a395,%eax
  1029ce:	83 e0 f0             	and    $0xfffffff0,%eax
  1029d1:	83 c8 0e             	or     $0xe,%eax
  1029d4:	a2 95 a3 17 00       	mov    %al,0x17a395
  1029d9:	0f b6 05 95 a3 17 00 	movzbl 0x17a395,%eax
  1029e0:	83 e0 ef             	and    $0xffffffef,%eax
  1029e3:	a2 95 a3 17 00       	mov    %al,0x17a395
  1029e8:	0f b6 05 95 a3 17 00 	movzbl 0x17a395,%eax
  1029ef:	83 e0 9f             	and    $0xffffff9f,%eax
  1029f2:	a2 95 a3 17 00       	mov    %al,0x17a395
  1029f7:	0f b6 05 95 a3 17 00 	movzbl 0x17a395,%eax
  1029fe:	83 c8 80             	or     $0xffffff80,%eax
  102a01:	a2 95 a3 17 00       	mov    %al,0x17a395
  102a06:	b8 d2 35 10 00       	mov    $0x1035d2,%eax
  102a0b:	c1 e8 10             	shr    $0x10,%eax
  102a0e:	66 a3 96 a3 17 00    	mov    %ax,0x17a396
  102a14:	b8 dc 35 10 00       	mov    $0x1035dc,%eax
  102a19:	66 a3 98 a3 17 00    	mov    %ax,0x17a398
  102a1f:	66 c7 05 9a a3 17 00 	movw   $0x8,0x17a39a
  102a26:	08 00 
  102a28:	0f b6 05 9c a3 17 00 	movzbl 0x17a39c,%eax
  102a2f:	83 e0 e0             	and    $0xffffffe0,%eax
  102a32:	a2 9c a3 17 00       	mov    %al,0x17a39c
  102a37:	0f b6 05 9c a3 17 00 	movzbl 0x17a39c,%eax
  102a3e:	83 e0 1f             	and    $0x1f,%eax
  102a41:	a2 9c a3 17 00       	mov    %al,0x17a39c
  102a46:	0f b6 05 9d a3 17 00 	movzbl 0x17a39d,%eax
  102a4d:	83 e0 f0             	and    $0xfffffff0,%eax
  102a50:	83 c8 0e             	or     $0xe,%eax
  102a53:	a2 9d a3 17 00       	mov    %al,0x17a39d
  102a58:	0f b6 05 9d a3 17 00 	movzbl 0x17a39d,%eax
  102a5f:	83 e0 ef             	and    $0xffffffef,%eax
  102a62:	a2 9d a3 17 00       	mov    %al,0x17a39d
  102a67:	0f b6 05 9d a3 17 00 	movzbl 0x17a39d,%eax
  102a6e:	83 e0 9f             	and    $0xffffff9f,%eax
  102a71:	a2 9d a3 17 00       	mov    %al,0x17a39d
  102a76:	0f b6 05 9d a3 17 00 	movzbl 0x17a39d,%eax
  102a7d:	83 c8 80             	or     $0xffffff80,%eax
  102a80:	a2 9d a3 17 00       	mov    %al,0x17a39d
  102a85:	b8 dc 35 10 00       	mov    $0x1035dc,%eax
  102a8a:	c1 e8 10             	shr    $0x10,%eax
  102a8d:	66 a3 9e a3 17 00    	mov    %ax,0x17a39e
  102a93:	b8 e6 35 10 00       	mov    $0x1035e6,%eax
  102a98:	66 a3 a0 a3 17 00    	mov    %ax,0x17a3a0
  102a9e:	66 c7 05 a2 a3 17 00 	movw   $0x8,0x17a3a2
  102aa5:	08 00 
  102aa7:	0f b6 05 a4 a3 17 00 	movzbl 0x17a3a4,%eax
  102aae:	83 e0 e0             	and    $0xffffffe0,%eax
  102ab1:	a2 a4 a3 17 00       	mov    %al,0x17a3a4
  102ab6:	0f b6 05 a4 a3 17 00 	movzbl 0x17a3a4,%eax
  102abd:	83 e0 1f             	and    $0x1f,%eax
  102ac0:	a2 a4 a3 17 00       	mov    %al,0x17a3a4
  102ac5:	0f b6 05 a5 a3 17 00 	movzbl 0x17a3a5,%eax
  102acc:	83 e0 f0             	and    $0xfffffff0,%eax
  102acf:	83 c8 0e             	or     $0xe,%eax
  102ad2:	a2 a5 a3 17 00       	mov    %al,0x17a3a5
  102ad7:	0f b6 05 a5 a3 17 00 	movzbl 0x17a3a5,%eax
  102ade:	83 e0 ef             	and    $0xffffffef,%eax
  102ae1:	a2 a5 a3 17 00       	mov    %al,0x17a3a5
  102ae6:	0f b6 05 a5 a3 17 00 	movzbl 0x17a3a5,%eax
  102aed:	83 c8 60             	or     $0x60,%eax
  102af0:	a2 a5 a3 17 00       	mov    %al,0x17a3a5
  102af5:	0f b6 05 a5 a3 17 00 	movzbl 0x17a3a5,%eax
  102afc:	83 c8 80             	or     $0xffffff80,%eax
  102aff:	a2 a5 a3 17 00       	mov    %al,0x17a3a5
  102b04:	b8 e6 35 10 00       	mov    $0x1035e6,%eax
  102b09:	c1 e8 10             	shr    $0x10,%eax
  102b0c:	66 a3 a6 a3 17 00    	mov    %ax,0x17a3a6
  102b12:	b8 f0 35 10 00       	mov    $0x1035f0,%eax
  102b17:	66 a3 a8 a3 17 00    	mov    %ax,0x17a3a8
  102b1d:	66 c7 05 aa a3 17 00 	movw   $0x8,0x17a3aa
  102b24:	08 00 
  102b26:	0f b6 05 ac a3 17 00 	movzbl 0x17a3ac,%eax
  102b2d:	83 e0 e0             	and    $0xffffffe0,%eax
  102b30:	a2 ac a3 17 00       	mov    %al,0x17a3ac
  102b35:	0f b6 05 ac a3 17 00 	movzbl 0x17a3ac,%eax
  102b3c:	83 e0 1f             	and    $0x1f,%eax
  102b3f:	a2 ac a3 17 00       	mov    %al,0x17a3ac
  102b44:	0f b6 05 ad a3 17 00 	movzbl 0x17a3ad,%eax
  102b4b:	83 e0 f0             	and    $0xfffffff0,%eax
  102b4e:	83 c8 0e             	or     $0xe,%eax
  102b51:	a2 ad a3 17 00       	mov    %al,0x17a3ad
  102b56:	0f b6 05 ad a3 17 00 	movzbl 0x17a3ad,%eax
  102b5d:	83 e0 ef             	and    $0xffffffef,%eax
  102b60:	a2 ad a3 17 00       	mov    %al,0x17a3ad
  102b65:	0f b6 05 ad a3 17 00 	movzbl 0x17a3ad,%eax
  102b6c:	83 e0 9f             	and    $0xffffff9f,%eax
  102b6f:	a2 ad a3 17 00       	mov    %al,0x17a3ad
  102b74:	0f b6 05 ad a3 17 00 	movzbl 0x17a3ad,%eax
  102b7b:	83 c8 80             	or     $0xffffff80,%eax
  102b7e:	a2 ad a3 17 00       	mov    %al,0x17a3ad
  102b83:	b8 f0 35 10 00       	mov    $0x1035f0,%eax
  102b88:	c1 e8 10             	shr    $0x10,%eax
  102b8b:	66 a3 ae a3 17 00    	mov    %ax,0x17a3ae
  102b91:	b8 fa 35 10 00       	mov    $0x1035fa,%eax
  102b96:	66 a3 b0 a3 17 00    	mov    %ax,0x17a3b0
  102b9c:	66 c7 05 b2 a3 17 00 	movw   $0x8,0x17a3b2
  102ba3:	08 00 
  102ba5:	0f b6 05 b4 a3 17 00 	movzbl 0x17a3b4,%eax
  102bac:	83 e0 e0             	and    $0xffffffe0,%eax
  102baf:	a2 b4 a3 17 00       	mov    %al,0x17a3b4
  102bb4:	0f b6 05 b4 a3 17 00 	movzbl 0x17a3b4,%eax
  102bbb:	83 e0 1f             	and    $0x1f,%eax
  102bbe:	a2 b4 a3 17 00       	mov    %al,0x17a3b4
  102bc3:	0f b6 05 b5 a3 17 00 	movzbl 0x17a3b5,%eax
  102bca:	83 e0 f0             	and    $0xfffffff0,%eax
  102bcd:	83 c8 0e             	or     $0xe,%eax
  102bd0:	a2 b5 a3 17 00       	mov    %al,0x17a3b5
  102bd5:	0f b6 05 b5 a3 17 00 	movzbl 0x17a3b5,%eax
  102bdc:	83 e0 ef             	and    $0xffffffef,%eax
  102bdf:	a2 b5 a3 17 00       	mov    %al,0x17a3b5
  102be4:	0f b6 05 b5 a3 17 00 	movzbl 0x17a3b5,%eax
  102beb:	83 e0 9f             	and    $0xffffff9f,%eax
  102bee:	a2 b5 a3 17 00       	mov    %al,0x17a3b5
  102bf3:	0f b6 05 b5 a3 17 00 	movzbl 0x17a3b5,%eax
  102bfa:	83 c8 80             	or     $0xffffff80,%eax
  102bfd:	a2 b5 a3 17 00       	mov    %al,0x17a3b5
  102c02:	b8 fa 35 10 00       	mov    $0x1035fa,%eax
  102c07:	c1 e8 10             	shr    $0x10,%eax
  102c0a:	66 a3 b6 a3 17 00    	mov    %ax,0x17a3b6
  102c10:	c9                   	leave  
  102c11:	c3                   	ret    

00102c12 <trap_init>:
  102c12:	55                   	push   %ebp
  102c13:	89 e5                	mov    %esp,%ebp
  102c15:	83 ec 08             	sub    $0x8,%esp
  102c18:	e8 20 00 00 00       	call   102c3d <cpu_onboot>
  102c1d:	85 c0                	test   %eax,%eax
  102c1f:	74 05                	je     102c26 <trap_init+0x14>
  102c21:	e8 ba ec ff ff       	call   1018e0 <trap_init_idt>
  102c26:	0f 01 1d 04 f0 10 00 	lidtl  0x10f004
  102c2d:	e8 0b 00 00 00       	call   102c3d <cpu_onboot>
  102c32:	85 c0                	test   %eax,%eax
  102c34:	74 05                	je     102c3b <trap_init+0x29>
  102c36:	e8 31 05 00 00       	call   10316c <trap_check_kernel>
  102c3b:	c9                   	leave  
  102c3c:	c3                   	ret    

00102c3d <cpu_onboot>:
}

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  102c3d:	55                   	push   %ebp
  102c3e:	89 e5                	mov    %esp,%ebp
  102c40:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  102c43:	e8 0d 00 00 00       	call   102c55 <cpu_cur>
  102c48:	3d 00 e0 10 00       	cmp    $0x10e000,%eax
  102c4d:	0f 94 c0             	sete   %al
  102c50:	0f b6 c0             	movzbl %al,%eax
}
  102c53:	c9                   	leave  
  102c54:	c3                   	ret    

00102c55 <cpu_cur>:
  102c55:	55                   	push   %ebp
  102c56:	89 e5                	mov    %esp,%ebp
  102c58:	83 ec 28             	sub    $0x28,%esp
static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  102c5b:	89 65 fc             	mov    %esp,0xfffffffc(%ebp)
        return esp;
  102c5e:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  102c61:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  102c64:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  102c67:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  102c6c:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	assert(c->magic == CPU_MAGIC);
  102c6f:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  102c72:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  102c78:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  102c7d:	74 24                	je     102ca3 <cpu_cur+0x4e>
  102c7f:	c7 44 24 0c 60 c2 10 	movl   $0x10c260,0xc(%esp)
  102c86:	00 
  102c87:	c7 44 24 08 76 c2 10 	movl   $0x10c276,0x8(%esp)
  102c8e:	00 
  102c8f:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  102c96:	00 
  102c97:	c7 04 24 8b c2 10 00 	movl   $0x10c28b,(%esp)
  102c9e:	e8 95 dc ff ff       	call   100938 <debug_panic>
	return c;
  102ca3:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
}
  102ca6:	c9                   	leave  
  102ca7:	c3                   	ret    

00102ca8 <trap_name>:
  102ca8:	55                   	push   %ebp
  102ca9:	89 e5                	mov    %esp,%ebp
  102cab:	83 ec 04             	sub    $0x4,%esp
  102cae:	8b 45 08             	mov    0x8(%ebp),%eax
  102cb1:	83 f8 13             	cmp    $0x13,%eax
  102cb4:	77 0f                	ja     102cc5 <trap_name+0x1d>
  102cb6:	8b 45 08             	mov    0x8(%ebp),%eax
  102cb9:	8b 04 85 00 c4 10 00 	mov    0x10c400(,%eax,4),%eax
  102cc0:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  102cc3:	eb 2b                	jmp    102cf0 <trap_name+0x48>
  102cc5:	83 7d 08 30          	cmpl   $0x30,0x8(%ebp)
  102cc9:	75 09                	jne    102cd4 <trap_name+0x2c>
  102ccb:	c7 45 fc 50 c4 10 00 	movl   $0x10c450,0xfffffffc(%ebp)
  102cd2:	eb 1c                	jmp    102cf0 <trap_name+0x48>
  102cd4:	83 7d 08 1f          	cmpl   $0x1f,0x8(%ebp)
  102cd8:	7e 0f                	jle    102ce9 <trap_name+0x41>
  102cda:	83 7d 08 2f          	cmpl   $0x2f,0x8(%ebp)
  102cde:	7f 09                	jg     102ce9 <trap_name+0x41>
  102ce0:	c7 45 fc 5c c4 10 00 	movl   $0x10c45c,0xfffffffc(%ebp)
  102ce7:	eb 07                	jmp    102cf0 <trap_name+0x48>
  102ce9:	c7 45 fc 82 c3 10 00 	movl   $0x10c382,0xfffffffc(%ebp)
  102cf0:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  102cf3:	c9                   	leave  
  102cf4:	c3                   	ret    

00102cf5 <trap_print_regs>:
  102cf5:	55                   	push   %ebp
  102cf6:	89 e5                	mov    %esp,%ebp
  102cf8:	83 ec 08             	sub    $0x8,%esp
  102cfb:	8b 45 08             	mov    0x8(%ebp),%eax
  102cfe:	8b 00                	mov    (%eax),%eax
  102d00:	89 44 24 04          	mov    %eax,0x4(%esp)
  102d04:	c7 04 24 6f c4 10 00 	movl   $0x10c46f,(%esp)
  102d0b:	e8 75 87 00 00       	call   10b485 <cprintf>
  102d10:	8b 45 08             	mov    0x8(%ebp),%eax
  102d13:	8b 40 04             	mov    0x4(%eax),%eax
  102d16:	89 44 24 04          	mov    %eax,0x4(%esp)
  102d1a:	c7 04 24 7e c4 10 00 	movl   $0x10c47e,(%esp)
  102d21:	e8 5f 87 00 00       	call   10b485 <cprintf>
  102d26:	8b 45 08             	mov    0x8(%ebp),%eax
  102d29:	8b 40 08             	mov    0x8(%eax),%eax
  102d2c:	89 44 24 04          	mov    %eax,0x4(%esp)
  102d30:	c7 04 24 8d c4 10 00 	movl   $0x10c48d,(%esp)
  102d37:	e8 49 87 00 00       	call   10b485 <cprintf>
  102d3c:	8b 45 08             	mov    0x8(%ebp),%eax
  102d3f:	8b 40 10             	mov    0x10(%eax),%eax
  102d42:	89 44 24 04          	mov    %eax,0x4(%esp)
  102d46:	c7 04 24 9c c4 10 00 	movl   $0x10c49c,(%esp)
  102d4d:	e8 33 87 00 00       	call   10b485 <cprintf>
  102d52:	8b 45 08             	mov    0x8(%ebp),%eax
  102d55:	8b 40 14             	mov    0x14(%eax),%eax
  102d58:	89 44 24 04          	mov    %eax,0x4(%esp)
  102d5c:	c7 04 24 ab c4 10 00 	movl   $0x10c4ab,(%esp)
  102d63:	e8 1d 87 00 00       	call   10b485 <cprintf>
  102d68:	8b 45 08             	mov    0x8(%ebp),%eax
  102d6b:	8b 40 18             	mov    0x18(%eax),%eax
  102d6e:	89 44 24 04          	mov    %eax,0x4(%esp)
  102d72:	c7 04 24 ba c4 10 00 	movl   $0x10c4ba,(%esp)
  102d79:	e8 07 87 00 00       	call   10b485 <cprintf>
  102d7e:	8b 45 08             	mov    0x8(%ebp),%eax
  102d81:	8b 40 1c             	mov    0x1c(%eax),%eax
  102d84:	89 44 24 04          	mov    %eax,0x4(%esp)
  102d88:	c7 04 24 c9 c4 10 00 	movl   $0x10c4c9,(%esp)
  102d8f:	e8 f1 86 00 00       	call   10b485 <cprintf>
  102d94:	c9                   	leave  
  102d95:	c3                   	ret    

00102d96 <trap_print>:
  102d96:	55                   	push   %ebp
  102d97:	89 e5                	mov    %esp,%ebp
  102d99:	83 ec 18             	sub    $0x18,%esp
  102d9c:	8b 45 08             	mov    0x8(%ebp),%eax
  102d9f:	89 44 24 04          	mov    %eax,0x4(%esp)
  102da3:	c7 04 24 d8 c4 10 00 	movl   $0x10c4d8,(%esp)
  102daa:	e8 d6 86 00 00       	call   10b485 <cprintf>
  102daf:	8b 45 08             	mov    0x8(%ebp),%eax
  102db2:	89 04 24             	mov    %eax,(%esp)
  102db5:	e8 3b ff ff ff       	call   102cf5 <trap_print_regs>
  102dba:	8b 45 08             	mov    0x8(%ebp),%eax
  102dbd:	0f b7 40 28          	movzwl 0x28(%eax),%eax
  102dc1:	0f b7 c0             	movzwl %ax,%eax
  102dc4:	89 44 24 04          	mov    %eax,0x4(%esp)
  102dc8:	c7 04 24 ea c4 10 00 	movl   $0x10c4ea,(%esp)
  102dcf:	e8 b1 86 00 00       	call   10b485 <cprintf>
  102dd4:	8b 45 08             	mov    0x8(%ebp),%eax
  102dd7:	0f b7 40 2c          	movzwl 0x2c(%eax),%eax
  102ddb:	0f b7 c0             	movzwl %ax,%eax
  102dde:	89 44 24 04          	mov    %eax,0x4(%esp)
  102de2:	c7 04 24 fd c4 10 00 	movl   $0x10c4fd,(%esp)
  102de9:	e8 97 86 00 00       	call   10b485 <cprintf>
  102dee:	8b 45 08             	mov    0x8(%ebp),%eax
  102df1:	8b 40 30             	mov    0x30(%eax),%eax
  102df4:	89 04 24             	mov    %eax,(%esp)
  102df7:	e8 ac fe ff ff       	call   102ca8 <trap_name>
  102dfc:	89 c2                	mov    %eax,%edx
  102dfe:	8b 45 08             	mov    0x8(%ebp),%eax
  102e01:	8b 40 30             	mov    0x30(%eax),%eax
  102e04:	89 54 24 08          	mov    %edx,0x8(%esp)
  102e08:	89 44 24 04          	mov    %eax,0x4(%esp)
  102e0c:	c7 04 24 10 c5 10 00 	movl   $0x10c510,(%esp)
  102e13:	e8 6d 86 00 00       	call   10b485 <cprintf>
  102e18:	8b 45 08             	mov    0x8(%ebp),%eax
  102e1b:	8b 40 34             	mov    0x34(%eax),%eax
  102e1e:	89 44 24 04          	mov    %eax,0x4(%esp)
  102e22:	c7 04 24 22 c5 10 00 	movl   $0x10c522,(%esp)
  102e29:	e8 57 86 00 00       	call   10b485 <cprintf>
  102e2e:	8b 45 08             	mov    0x8(%ebp),%eax
  102e31:	8b 40 38             	mov    0x38(%eax),%eax
  102e34:	89 44 24 04          	mov    %eax,0x4(%esp)
  102e38:	c7 04 24 31 c5 10 00 	movl   $0x10c531,(%esp)
  102e3f:	e8 41 86 00 00       	call   10b485 <cprintf>
  102e44:	8b 45 08             	mov    0x8(%ebp),%eax
  102e47:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
  102e4b:	0f b7 c0             	movzwl %ax,%eax
  102e4e:	89 44 24 04          	mov    %eax,0x4(%esp)
  102e52:	c7 04 24 40 c5 10 00 	movl   $0x10c540,(%esp)
  102e59:	e8 27 86 00 00       	call   10b485 <cprintf>
  102e5e:	8b 45 08             	mov    0x8(%ebp),%eax
  102e61:	8b 40 40             	mov    0x40(%eax),%eax
  102e64:	89 44 24 04          	mov    %eax,0x4(%esp)
  102e68:	c7 04 24 53 c5 10 00 	movl   $0x10c553,(%esp)
  102e6f:	e8 11 86 00 00       	call   10b485 <cprintf>
  102e74:	8b 45 08             	mov    0x8(%ebp),%eax
  102e77:	8b 40 44             	mov    0x44(%eax),%eax
  102e7a:	89 44 24 04          	mov    %eax,0x4(%esp)
  102e7e:	c7 04 24 62 c5 10 00 	movl   $0x10c562,(%esp)
  102e85:	e8 fb 85 00 00       	call   10b485 <cprintf>
  102e8a:	8b 45 08             	mov    0x8(%ebp),%eax
  102e8d:	0f b7 40 48          	movzwl 0x48(%eax),%eax
  102e91:	0f b7 c0             	movzwl %ax,%eax
  102e94:	89 44 24 04          	mov    %eax,0x4(%esp)
  102e98:	c7 04 24 71 c5 10 00 	movl   $0x10c571,(%esp)
  102e9f:	e8 e1 85 00 00       	call   10b485 <cprintf>
  102ea4:	c9                   	leave  
  102ea5:	c3                   	ret    

00102ea6 <trap>:
  102ea6:	55                   	push   %ebp
  102ea7:	89 e5                	mov    %esp,%ebp
  102ea9:	53                   	push   %ebx
  102eaa:	83 ec 24             	sub    $0x24,%esp
  102ead:	fc                   	cld    
  102eae:	8b 45 08             	mov    0x8(%ebp),%eax
  102eb1:	8b 40 30             	mov    0x30(%eax),%eax
  102eb4:	83 f8 0e             	cmp    $0xe,%eax
  102eb7:	75 0b                	jne    102ec4 <trap+0x1e>
  102eb9:	8b 45 08             	mov    0x8(%ebp),%eax
  102ebc:	89 04 24             	mov    %eax,(%esp)
  102ebf:	e8 c1 41 00 00       	call   107085 <pmap_pagefault>
  102ec4:	e8 8c fd ff ff       	call   102c55 <cpu_cur>
  102ec9:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  102ecc:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  102ecf:	8b 80 a0 00 00 00    	mov    0xa0(%eax),%eax
  102ed5:	85 c0                	test   %eax,%eax
  102ed7:	74 1e                	je     102ef7 <trap+0x51>
  102ed9:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  102edc:	8b 90 a0 00 00 00    	mov    0xa0(%eax),%edx
  102ee2:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  102ee5:	8b 80 a4 00 00 00    	mov    0xa4(%eax),%eax
  102eeb:	89 44 24 04          	mov    %eax,0x4(%esp)
  102eef:	8b 45 08             	mov    0x8(%ebp),%eax
  102ef2:	89 04 24             	mov    %eax,(%esp)
  102ef5:	ff d2                	call   *%edx
  102ef7:	e8 59 fd ff ff       	call   102c55 <cpu_cur>
  102efc:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  102f02:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
  102f05:	8b 45 08             	mov    0x8(%ebp),%eax
  102f08:	8b 40 30             	mov    0x30(%eax),%eax
  102f0b:	83 e8 03             	sub    $0x3,%eax
  102f0e:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  102f11:	83 7d e8 2f          	cmpl   $0x2f,0xffffffe8(%ebp)
  102f15:	0f 87 80 01 00 00    	ja     10309b <trap+0x1f5>
  102f1b:	8b 55 e8             	mov    0xffffffe8(%ebp),%edx
  102f1e:	8b 04 95 fc c5 10 00 	mov    0x10c5fc(,%edx,4),%eax
  102f25:	ff e0                	jmp    *%eax
  102f27:	8b 45 08             	mov    0x8(%ebp),%eax
  102f2a:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
  102f2e:	0f b7 c0             	movzwl %ax,%eax
  102f31:	83 e0 03             	and    $0x3,%eax
  102f34:	85 c0                	test   %eax,%eax
  102f36:	75 24                	jne    102f5c <trap+0xb6>
  102f38:	c7 44 24 0c 84 c5 10 	movl   $0x10c584,0xc(%esp)
  102f3f:	00 
  102f40:	c7 44 24 08 76 c2 10 	movl   $0x10c276,0x8(%esp)
  102f47:	00 
  102f48:	c7 44 24 04 fd 00 00 	movl   $0xfd,0x4(%esp)
  102f4f:	00 
  102f50:	c7 04 24 8f c5 10 00 	movl   $0x10c58f,(%esp)
  102f57:	e8 dc d9 ff ff       	call   100938 <debug_panic>
  102f5c:	8b 45 08             	mov    0x8(%ebp),%eax
  102f5f:	89 04 24             	mov    %eax,(%esp)
  102f62:	e8 60 2b 00 00       	call   105ac7 <syscall>
  102f67:	e9 2f 01 00 00       	jmp    10309b <trap+0x1f5>
  102f6c:	8b 45 08             	mov    0x8(%ebp),%eax
  102f6f:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
  102f73:	0f b7 c0             	movzwl %ax,%eax
  102f76:	83 e0 03             	and    $0x3,%eax
  102f79:	85 c0                	test   %eax,%eax
  102f7b:	75 24                	jne    102fa1 <trap+0xfb>
  102f7d:	c7 44 24 0c 84 c5 10 	movl   $0x10c584,0xc(%esp)
  102f84:	00 
  102f85:	c7 44 24 08 76 c2 10 	movl   $0x10c276,0x8(%esp)
  102f8c:	00 
  102f8d:	c7 44 24 04 03 01 00 	movl   $0x103,0x4(%esp)
  102f94:	00 
  102f95:	c7 04 24 8f c5 10 00 	movl   $0x10c58f,(%esp)
  102f9c:	e8 97 d9 ff ff       	call   100938 <debug_panic>
  102fa1:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  102fa8:	00 
  102fa9:	8b 45 08             	mov    0x8(%ebp),%eax
  102fac:	89 04 24             	mov    %eax,(%esp)
  102faf:	e8 f1 17 00 00       	call   1047a5 <proc_ret>
  102fb4:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  102fb7:	8b 80 9c 04 00 00    	mov    0x49c(%eax),%eax
  102fbd:	89 c2                	mov    %eax,%edx
  102fbf:	83 ca 01             	or     $0x1,%edx
  102fc2:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  102fc5:	89 90 9c 04 00 00    	mov    %edx,0x49c(%eax)
static gcc_inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
  102fcb:	0f 20 c0             	mov    %cr0,%eax
  102fce:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	return val;
  102fd1:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  102fd4:	83 e0 f7             	and    $0xfffffff7,%eax
  102fd7:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  102fda:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  102fdd:	0f 22 c0             	mov    %eax,%cr0
  102fe0:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  102fe3:	0f ae 88 a0 04 00 00 	fxrstor 0x4a0(%eax)
  102fea:	8b 45 08             	mov    0x8(%ebp),%eax
  102fed:	89 04 24             	mov    %eax,(%esp)
  102ff0:	e8 3b 06 00 00       	call   103630 <trap_return>
  102ff5:	e8 4a 79 00 00       	call   10a944 <lapic_eoi>
  102ffa:	8b 45 08             	mov    0x8(%ebp),%eax
  102ffd:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
  103001:	0f b7 c0             	movzwl %ax,%eax
  103004:	83 e0 03             	and    $0x3,%eax
  103007:	85 c0                	test   %eax,%eax
  103009:	74 0b                	je     103016 <trap+0x170>
  10300b:	8b 45 08             	mov    0x8(%ebp),%eax
  10300e:	89 04 24             	mov    %eax,(%esp)
  103011:	e8 0d 17 00 00       	call   104723 <proc_yield>
  103016:	8b 45 08             	mov    0x8(%ebp),%eax
  103019:	89 04 24             	mov    %eax,(%esp)
  10301c:	e8 0f 06 00 00       	call   103630 <trap_return>
  103021:	e8 43 79 00 00       	call   10a969 <lapic_errintr>
  103026:	8b 45 08             	mov    0x8(%ebp),%eax
  103029:	89 04 24             	mov    %eax,(%esp)
  10302c:	e8 ff 05 00 00       	call   103630 <trap_return>
  103031:	e8 be 72 00 00       	call   10a2f4 <kbd_intr>
  103036:	e8 09 79 00 00       	call   10a944 <lapic_eoi>
  10303b:	8b 45 08             	mov    0x8(%ebp),%eax
  10303e:	89 04 24             	mov    %eax,(%esp)
  103041:	e8 ea 05 00 00       	call   103630 <trap_return>
  103046:	e8 f9 78 00 00       	call   10a944 <lapic_eoi>
  10304b:	e8 6c 73 00 00       	call   10a3bc <serial_intr>
  103050:	8b 45 08             	mov    0x8(%ebp),%eax
  103053:	89 04 24             	mov    %eax,(%esp)
  103056:	e8 d5 05 00 00       	call   103630 <trap_return>
  10305b:	8b 45 08             	mov    0x8(%ebp),%eax
  10305e:	8b 48 38             	mov    0x38(%eax),%ecx
  103061:	8b 45 08             	mov    0x8(%ebp),%eax
  103064:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
  103068:	0f b7 d0             	movzwl %ax,%edx
  10306b:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  10306e:	0f b6 80 ac 00 00 00 	movzbl 0xac(%eax),%eax
  103075:	0f b6 c0             	movzbl %al,%eax
  103078:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  10307c:	89 54 24 08          	mov    %edx,0x8(%esp)
  103080:	89 44 24 04          	mov    %eax,0x4(%esp)
  103084:	c7 04 24 a0 c5 10 00 	movl   $0x10c5a0,(%esp)
  10308b:	e8 f5 83 00 00       	call   10b485 <cprintf>
  103090:	8b 45 08             	mov    0x8(%ebp),%eax
  103093:	89 04 24             	mov    %eax,(%esp)
  103096:	e8 95 05 00 00       	call   103630 <trap_return>
  10309b:	8b 45 08             	mov    0x8(%ebp),%eax
  10309e:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
  1030a2:	0f b7 c0             	movzwl %ax,%eax
  1030a5:	83 e0 03             	and    $0x3,%eax
  1030a8:	85 c0                	test   %eax,%eax
  1030aa:	74 4b                	je     1030f7 <trap+0x251>
  1030ac:	e8 a4 fb ff ff       	call   102c55 <cpu_cur>
  1030b1:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  1030b7:	8b 58 38             	mov    0x38(%eax),%ebx
  1030ba:	e8 96 fb ff ff       	call   102c55 <cpu_cur>
  1030bf:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  1030c5:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  1030c9:	89 44 24 04          	mov    %eax,0x4(%esp)
  1030cd:	c7 04 24 c4 c5 10 00 	movl   $0x10c5c4,(%esp)
  1030d4:	e8 ac 83 00 00       	call   10b485 <cprintf>
  1030d9:	8b 45 08             	mov    0x8(%ebp),%eax
  1030dc:	89 04 24             	mov    %eax,(%esp)
  1030df:	e8 b2 fc ff ff       	call   102d96 <trap_print>
  1030e4:	c7 44 24 04 ff ff ff 	movl   $0xffffffff,0x4(%esp)
  1030eb:	ff 
  1030ec:	8b 45 08             	mov    0x8(%ebp),%eax
  1030ef:	89 04 24             	mov    %eax,(%esp)
  1030f2:	e8 ae 16 00 00       	call   1047a5 <proc_ret>
  1030f7:	c7 04 24 40 ed 17 00 	movl   $0x17ed40,(%esp)
  1030fe:	e8 dc 0a 00 00       	call   103bdf <spinlock_holding>
  103103:	85 c0                	test   %eax,%eax
  103105:	74 0c                	je     103113 <trap+0x26d>
  103107:	c7 04 24 40 ed 17 00 	movl   $0x17ed40,(%esp)
  10310e:	e8 72 0a 00 00       	call   103b85 <spinlock_release>
  103113:	8b 45 08             	mov    0x8(%ebp),%eax
  103116:	89 04 24             	mov    %eax,(%esp)
  103119:	e8 78 fc ff ff       	call   102d96 <trap_print>
  10311e:	c7 44 24 08 ec c5 10 	movl   $0x10c5ec,0x8(%esp)
  103125:	00 
  103126:	c7 44 24 04 8e 01 00 	movl   $0x18e,0x4(%esp)
  10312d:	00 
  10312e:	c7 04 24 8f c5 10 00 	movl   $0x10c58f,(%esp)
  103135:	e8 fe d7 ff ff       	call   100938 <debug_panic>

0010313a <trap_check_recover>:
  10313a:	55                   	push   %ebp
  10313b:	89 e5                	mov    %esp,%ebp
  10313d:	83 ec 18             	sub    $0x18,%esp
  103140:	8b 45 0c             	mov    0xc(%ebp),%eax
  103143:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  103146:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  103149:	8b 00                	mov    (%eax),%eax
  10314b:	89 c2                	mov    %eax,%edx
  10314d:	8b 45 08             	mov    0x8(%ebp),%eax
  103150:	89 50 38             	mov    %edx,0x38(%eax)
  103153:	8b 45 08             	mov    0x8(%ebp),%eax
  103156:	8b 40 30             	mov    0x30(%eax),%eax
  103159:	89 c2                	mov    %eax,%edx
  10315b:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  10315e:	89 50 04             	mov    %edx,0x4(%eax)
  103161:	8b 45 08             	mov    0x8(%ebp),%eax
  103164:	89 04 24             	mov    %eax,(%esp)
  103167:	e8 c4 04 00 00       	call   103630 <trap_return>

0010316c <trap_check_kernel>:
  10316c:	55                   	push   %ebp
  10316d:	89 e5                	mov    %esp,%ebp
  10316f:	83 ec 28             	sub    $0x28,%esp
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
  103172:	8c 4d fe             	movw   %cs,0xfffffffe(%ebp)
        return cs;
  103175:	0f b7 45 fe          	movzwl 0xfffffffe(%ebp),%eax
  103179:	0f b7 c0             	movzwl %ax,%eax
  10317c:	83 e0 03             	and    $0x3,%eax
  10317f:	85 c0                	test   %eax,%eax
  103181:	74 24                	je     1031a7 <trap_check_kernel+0x3b>
  103183:	c7 44 24 0c bc c6 10 	movl   $0x10c6bc,0xc(%esp)
  10318a:	00 
  10318b:	c7 44 24 08 76 c2 10 	movl   $0x10c276,0x8(%esp)
  103192:	00 
  103193:	c7 44 24 04 a2 01 00 	movl   $0x1a2,0x4(%esp)
  10319a:	00 
  10319b:	c7 04 24 8f c5 10 00 	movl   $0x10c58f,(%esp)
  1031a2:	e8 91 d7 ff ff       	call   100938 <debug_panic>
  1031a7:	e8 a9 fa ff ff       	call   102c55 <cpu_cur>
  1031ac:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  1031af:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1031b2:	c7 80 a0 00 00 00 3a 	movl   $0x10313a,0xa0(%eax)
  1031b9:	31 10 00 
  1031bc:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1031bf:	05 a4 00 00 00       	add    $0xa4,%eax
  1031c4:	89 04 24             	mov    %eax,(%esp)
  1031c7:	e8 96 00 00 00       	call   103262 <trap_check>
  1031cc:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1031cf:	c7 80 a0 00 00 00 00 	movl   $0x0,0xa0(%eax)
  1031d6:	00 00 00 
  1031d9:	c7 04 24 d4 c6 10 00 	movl   $0x10c6d4,(%esp)
  1031e0:	e8 a0 82 00 00       	call   10b485 <cprintf>
  1031e5:	c9                   	leave  
  1031e6:	c3                   	ret    

001031e7 <trap_check_user>:
  1031e7:	55                   	push   %ebp
  1031e8:	89 e5                	mov    %esp,%ebp
  1031ea:	83 ec 28             	sub    $0x28,%esp
  1031ed:	8c 4d fe             	movw   %cs,0xfffffffe(%ebp)
  1031f0:	0f b7 45 fe          	movzwl 0xfffffffe(%ebp),%eax
  1031f4:	0f b7 c0             	movzwl %ax,%eax
  1031f7:	83 e0 03             	and    $0x3,%eax
  1031fa:	83 f8 03             	cmp    $0x3,%eax
  1031fd:	74 24                	je     103223 <trap_check_user+0x3c>
  1031ff:	c7 44 24 0c f4 c6 10 	movl   $0x10c6f4,0xc(%esp)
  103206:	00 
  103207:	c7 44 24 08 76 c2 10 	movl   $0x10c276,0x8(%esp)
  10320e:	00 
  10320f:	c7 44 24 04 b6 01 00 	movl   $0x1b6,0x4(%esp)
  103216:	00 
  103217:	c7 04 24 8f c5 10 00 	movl   $0x10c58f,(%esp)
  10321e:	e8 15 d7 ff ff       	call   100938 <debug_panic>
  103223:	c7 45 f8 00 e0 10 00 	movl   $0x10e000,0xfffffff8(%ebp)
  10322a:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10322d:	c7 80 a0 00 00 00 3a 	movl   $0x10313a,0xa0(%eax)
  103234:	31 10 00 
  103237:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10323a:	05 a4 00 00 00       	add    $0xa4,%eax
  10323f:	89 04 24             	mov    %eax,(%esp)
  103242:	e8 1b 00 00 00       	call   103262 <trap_check>
  103247:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10324a:	c7 80 a0 00 00 00 00 	movl   $0x0,0xa0(%eax)
  103251:	00 00 00 
  103254:	c7 04 24 09 c7 10 00 	movl   $0x10c709,(%esp)
  10325b:	e8 25 82 00 00       	call   10b485 <cprintf>
  103260:	c9                   	leave  
  103261:	c3                   	ret    

00103262 <trap_check>:
  103262:	55                   	push   %ebp
  103263:	89 e5                	mov    %esp,%ebp
  103265:	57                   	push   %edi
  103266:	56                   	push   %esi
  103267:	53                   	push   %ebx
  103268:	83 ec 3c             	sub    $0x3c,%esp
  10326b:	c7 45 ec ce fa ed fe 	movl   $0xfeedface,0xffffffec(%ebp)
  103272:	8b 55 08             	mov    0x8(%ebp),%edx
  103275:	8d 45 e4             	lea    0xffffffe4(%ebp),%eax
  103278:	89 02                	mov    %eax,(%edx)
  10327a:	c7 45 e4 88 32 10 00 	movl   $0x103288,0xffffffe4(%ebp)
  103281:	b8 00 00 00 00       	mov    $0x0,%eax
  103286:	f7 f0                	div    %eax

00103288 <after_div0>:
  103288:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  10328b:	85 c0                	test   %eax,%eax
  10328d:	74 24                	je     1032b3 <after_div0+0x2b>
  10328f:	c7 44 24 0c 27 c7 10 	movl   $0x10c727,0xc(%esp)
  103296:	00 
  103297:	c7 44 24 08 76 c2 10 	movl   $0x10c276,0x8(%esp)
  10329e:	00 
  10329f:	c7 44 24 04 d9 01 00 	movl   $0x1d9,0x4(%esp)
  1032a6:	00 
  1032a7:	c7 04 24 8f c5 10 00 	movl   $0x10c58f,(%esp)
  1032ae:	e8 85 d6 ff ff       	call   100938 <debug_panic>
  1032b3:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  1032b6:	3d ce fa ed fe       	cmp    $0xfeedface,%eax
  1032bb:	74 24                	je     1032e1 <after_div0+0x59>
  1032bd:	c7 44 24 0c 3f c7 10 	movl   $0x10c73f,0xc(%esp)
  1032c4:	00 
  1032c5:	c7 44 24 08 76 c2 10 	movl   $0x10c276,0x8(%esp)
  1032cc:	00 
  1032cd:	c7 44 24 04 de 01 00 	movl   $0x1de,0x4(%esp)
  1032d4:	00 
  1032d5:	c7 04 24 8f c5 10 00 	movl   $0x10c58f,(%esp)
  1032dc:	e8 57 d6 ff ff       	call   100938 <debug_panic>
  1032e1:	c7 45 e4 e9 32 10 00 	movl   $0x1032e9,0xffffffe4(%ebp)
  1032e8:	cc                   	int3   

001032e9 <after_breakpoint>:
  1032e9:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  1032ec:	83 f8 03             	cmp    $0x3,%eax
  1032ef:	74 24                	je     103315 <after_breakpoint+0x2c>
  1032f1:	c7 44 24 0c 54 c7 10 	movl   $0x10c754,0xc(%esp)
  1032f8:	00 
  1032f9:	c7 44 24 08 76 c2 10 	movl   $0x10c276,0x8(%esp)
  103300:	00 
  103301:	c7 44 24 04 e3 01 00 	movl   $0x1e3,0x4(%esp)
  103308:	00 
  103309:	c7 04 24 8f c5 10 00 	movl   $0x10c58f,(%esp)
  103310:	e8 23 d6 ff ff       	call   100938 <debug_panic>
  103315:	c7 45 e4 24 33 10 00 	movl   $0x103324,0xffffffe4(%ebp)
  10331c:	b8 00 00 00 70       	mov    $0x70000000,%eax
  103321:	01 c0                	add    %eax,%eax
  103323:	ce                   	into   

00103324 <after_overflow>:
  103324:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  103327:	83 f8 04             	cmp    $0x4,%eax
  10332a:	74 24                	je     103350 <after_overflow+0x2c>
  10332c:	c7 44 24 0c 6b c7 10 	movl   $0x10c76b,0xc(%esp)
  103333:	00 
  103334:	c7 44 24 08 76 c2 10 	movl   $0x10c276,0x8(%esp)
  10333b:	00 
  10333c:	c7 44 24 04 e8 01 00 	movl   $0x1e8,0x4(%esp)
  103343:	00 
  103344:	c7 04 24 8f c5 10 00 	movl   $0x10c58f,(%esp)
  10334b:	e8 e8 d5 ff ff       	call   100938 <debug_panic>
  103350:	c7 45 e4 6d 33 10 00 	movl   $0x10336d,0xffffffe4(%ebp)
  103357:	c7 45 dc 01 00 00 00 	movl   $0x1,0xffffffdc(%ebp)
  10335e:	c7 45 e0 03 00 00 00 	movl   $0x3,0xffffffe0(%ebp)
  103365:	b8 00 00 00 00       	mov    $0x0,%eax
  10336a:	62 45 dc             	bound  %eax,0xffffffdc(%ebp)

0010336d <after_bound>:
  10336d:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  103370:	83 f8 05             	cmp    $0x5,%eax
  103373:	74 24                	je     103399 <after_bound+0x2c>
  103375:	c7 44 24 0c 82 c7 10 	movl   $0x10c782,0xc(%esp)
  10337c:	00 
  10337d:	c7 44 24 08 76 c2 10 	movl   $0x10c276,0x8(%esp)
  103384:	00 
  103385:	c7 44 24 04 ee 01 00 	movl   $0x1ee,0x4(%esp)
  10338c:	00 
  10338d:	c7 04 24 8f c5 10 00 	movl   $0x10c58f,(%esp)
  103394:	e8 9f d5 ff ff       	call   100938 <debug_panic>
  103399:	c7 45 e4 a2 33 10 00 	movl   $0x1033a2,0xffffffe4(%ebp)
  1033a0:	0f 0b                	ud2a   

001033a2 <after_illegal>:
  1033a2:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  1033a5:	83 f8 06             	cmp    $0x6,%eax
  1033a8:	74 24                	je     1033ce <after_illegal+0x2c>
  1033aa:	c7 44 24 0c 99 c7 10 	movl   $0x10c799,0xc(%esp)
  1033b1:	00 
  1033b2:	c7 44 24 08 76 c2 10 	movl   $0x10c276,0x8(%esp)
  1033b9:	00 
  1033ba:	c7 44 24 04 f3 01 00 	movl   $0x1f3,0x4(%esp)
  1033c1:	00 
  1033c2:	c7 04 24 8f c5 10 00 	movl   $0x10c58f,(%esp)
  1033c9:	e8 6a d5 ff ff       	call   100938 <debug_panic>
  1033ce:	c7 45 e4 dc 33 10 00 	movl   $0x1033dc,0xffffffe4(%ebp)
  1033d5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  1033da:	8e e0                	movl   %eax,%fs

001033dc <after_gpfault>:
  1033dc:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  1033df:	83 f8 0d             	cmp    $0xd,%eax
  1033e2:	74 24                	je     103408 <after_gpfault+0x2c>
  1033e4:	c7 44 24 0c b0 c7 10 	movl   $0x10c7b0,0xc(%esp)
  1033eb:	00 
  1033ec:	c7 44 24 08 76 c2 10 	movl   $0x10c276,0x8(%esp)
  1033f3:	00 
  1033f4:	c7 44 24 04 f8 01 00 	movl   $0x1f8,0x4(%esp)
  1033fb:	00 
  1033fc:	c7 04 24 8f c5 10 00 	movl   $0x10c58f,(%esp)
  103403:	e8 30 d5 ff ff       	call   100938 <debug_panic>
  103408:	8c 4d f2             	movw   %cs,0xfffffff2(%ebp)
  10340b:	0f b7 45 f2          	movzwl 0xfffffff2(%ebp),%eax
  10340f:	0f b7 c0             	movzwl %ax,%eax
  103412:	83 e0 03             	and    $0x3,%eax
  103415:	85 c0                	test   %eax,%eax
  103417:	74 3a                	je     103453 <after_priv+0x2c>
  103419:	c7 45 e4 27 34 10 00 	movl   $0x103427,0xffffffe4(%ebp)
  103420:	0f 01 1d 04 f0 10 00 	lidtl  0x10f004

00103427 <after_priv>:
  103427:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  10342a:	83 f8 0d             	cmp    $0xd,%eax
  10342d:	74 24                	je     103453 <after_priv+0x2c>
  10342f:	c7 44 24 0c b0 c7 10 	movl   $0x10c7b0,0xc(%esp)
  103436:	00 
  103437:	c7 44 24 08 76 c2 10 	movl   $0x10c276,0x8(%esp)
  10343e:	00 
  10343f:	c7 44 24 04 fe 01 00 	movl   $0x1fe,0x4(%esp)
  103446:	00 
  103447:	c7 04 24 8f c5 10 00 	movl   $0x10c58f,(%esp)
  10344e:	e8 e5 d4 ff ff       	call   100938 <debug_panic>
  103453:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  103456:	3d ce fa ed fe       	cmp    $0xfeedface,%eax
  10345b:	74 24                	je     103481 <after_priv+0x5a>
  10345d:	c7 44 24 0c 3f c7 10 	movl   $0x10c73f,0xc(%esp)
  103464:	00 
  103465:	c7 44 24 08 76 c2 10 	movl   $0x10c276,0x8(%esp)
  10346c:	00 
  10346d:	c7 44 24 04 02 02 00 	movl   $0x202,0x4(%esp)
  103474:	00 
  103475:	c7 04 24 8f c5 10 00 	movl   $0x10c58f,(%esp)
  10347c:	e8 b7 d4 ff ff       	call   100938 <debug_panic>
  103481:	8b 45 08             	mov    0x8(%ebp),%eax
  103484:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  10348a:	83 c4 3c             	add    $0x3c,%esp
  10348d:	5b                   	pop    %ebx
  10348e:	5e                   	pop    %esi
  10348f:	5f                   	pop    %edi
  103490:	5d                   	pop    %ebp
  103491:	c3                   	ret    
  103492:	90                   	nop    
  103493:	90                   	nop    
  103494:	90                   	nop    
  103495:	90                   	nop    
  103496:	90                   	nop    
  103497:	90                   	nop    
  103498:	90                   	nop    
  103499:	90                   	nop    
  10349a:	90                   	nop    
  10349b:	90                   	nop    
  10349c:	90                   	nop    
  10349d:	90                   	nop    
  10349e:	90                   	nop    
  10349f:	90                   	nop    

001034a0 <Xdivide>:

.text

/* CPU traps */
TRAPHANDLER_NOEC(Xdivide, T_DIVIDE)
  1034a0:	6a 00                	push   $0x0
  1034a2:	6a 00                	push   $0x0
  1034a4:	e9 67 01 00 00       	jmp    103610 <_alltraps>
  1034a9:	90                   	nop    

001034aa <Xdebug>:
TRAPHANDLER_NOEC(Xdebug,  T_DEBUG)
  1034aa:	6a 00                	push   $0x0
  1034ac:	6a 01                	push   $0x1
  1034ae:	e9 5d 01 00 00       	jmp    103610 <_alltraps>
  1034b3:	90                   	nop    

001034b4 <Xnmi>:
TRAPHANDLER_NOEC(Xnmi,    T_NMI)
  1034b4:	6a 00                	push   $0x0
  1034b6:	6a 02                	push   $0x2
  1034b8:	e9 53 01 00 00       	jmp    103610 <_alltraps>
  1034bd:	90                   	nop    

001034be <Xbrkpt>:
TRAPHANDLER_NOEC(Xbrkpt,  T_BRKPT)
  1034be:	6a 00                	push   $0x0
  1034c0:	6a 03                	push   $0x3
  1034c2:	e9 49 01 00 00       	jmp    103610 <_alltraps>
  1034c7:	90                   	nop    

001034c8 <Xoflow>:
TRAPHANDLER_NOEC(Xoflow,  T_OFLOW)
  1034c8:	6a 00                	push   $0x0
  1034ca:	6a 04                	push   $0x4
  1034cc:	e9 3f 01 00 00       	jmp    103610 <_alltraps>
  1034d1:	90                   	nop    

001034d2 <Xbound>:
TRAPHANDLER_NOEC(Xbound,  T_BOUND)
  1034d2:	6a 00                	push   $0x0
  1034d4:	6a 05                	push   $0x5
  1034d6:	e9 35 01 00 00       	jmp    103610 <_alltraps>
  1034db:	90                   	nop    

001034dc <Xillop>:
TRAPHANDLER_NOEC(Xillop,  T_ILLOP)
  1034dc:	6a 00                	push   $0x0
  1034de:	6a 06                	push   $0x6
  1034e0:	e9 2b 01 00 00       	jmp    103610 <_alltraps>
  1034e5:	90                   	nop    

001034e6 <Xdevice>:
TRAPHANDLER_NOEC(Xdevice, T_DEVICE)
  1034e6:	6a 00                	push   $0x0
  1034e8:	6a 07                	push   $0x7
  1034ea:	e9 21 01 00 00       	jmp    103610 <_alltraps>
  1034ef:	90                   	nop    

001034f0 <Xdblflt>:
TRAPHANDLER     (Xdblflt, T_DBLFLT)
  1034f0:	6a 08                	push   $0x8
  1034f2:	e9 19 01 00 00       	jmp    103610 <_alltraps>
  1034f7:	90                   	nop    

001034f8 <Xtss>:
TRAPHANDLER     (Xtss,    T_TSS)
  1034f8:	6a 0a                	push   $0xa
  1034fa:	e9 11 01 00 00       	jmp    103610 <_alltraps>
  1034ff:	90                   	nop    

00103500 <Xsegnp>:
TRAPHANDLER     (Xsegnp,  T_SEGNP)
  103500:	6a 0b                	push   $0xb
  103502:	e9 09 01 00 00       	jmp    103610 <_alltraps>
  103507:	90                   	nop    

00103508 <Xstack>:
TRAPHANDLER     (Xstack,  T_STACK)
  103508:	6a 0c                	push   $0xc
  10350a:	e9 01 01 00 00       	jmp    103610 <_alltraps>
  10350f:	90                   	nop    

00103510 <Xgpflt>:
TRAPHANDLER     (Xgpflt,  T_GPFLT)
  103510:	6a 0d                	push   $0xd
  103512:	e9 f9 00 00 00       	jmp    103610 <_alltraps>
  103517:	90                   	nop    

00103518 <Xpgflt>:
TRAPHANDLER     (Xpgflt,  T_PGFLT)
  103518:	6a 0e                	push   $0xe
  10351a:	e9 f1 00 00 00       	jmp    103610 <_alltraps>
  10351f:	90                   	nop    

00103520 <Xfperr>:
TRAPHANDLER_NOEC(Xfperr,  T_FPERR)
  103520:	6a 00                	push   $0x0
  103522:	6a 10                	push   $0x10
  103524:	e9 e7 00 00 00       	jmp    103610 <_alltraps>
  103529:	90                   	nop    

0010352a <Xalign>:
TRAPHANDLER     (Xalign,  T_ALIGN)
  10352a:	6a 11                	push   $0x11
  10352c:	e9 df 00 00 00       	jmp    103610 <_alltraps>
  103531:	90                   	nop    

00103532 <Xmchk>:
TRAPHANDLER_NOEC(Xmchk,   T_MCHK)
  103532:	6a 00                	push   $0x0
  103534:	6a 12                	push   $0x12
  103536:	e9 d5 00 00 00       	jmp    103610 <_alltraps>
  10353b:	90                   	nop    

0010353c <Xsimd>:
TRAPHANDLER_NOEC(Xsimd,   T_SIMD)
  10353c:	6a 00                	push   $0x0
  10353e:	6a 13                	push   $0x13
  103540:	e9 cb 00 00 00       	jmp    103610 <_alltraps>
  103545:	90                   	nop    

00103546 <Xirq0>:


/* ISA device interrupts */
TRAPHANDLER_NOEC(Xirq0,   T_IRQ0+0)	// IRQ_PIT
  103546:	6a 00                	push   $0x0
  103548:	6a 20                	push   $0x20
  10354a:	e9 c1 00 00 00       	jmp    103610 <_alltraps>
  10354f:	90                   	nop    

00103550 <Xirq1>:
TRAPHANDLER_NOEC(Xirq1,   T_IRQ0+1)	// IRQ_KBD
  103550:	6a 00                	push   $0x0
  103552:	6a 21                	push   $0x21
  103554:	e9 b7 00 00 00       	jmp    103610 <_alltraps>
  103559:	90                   	nop    

0010355a <Xirq2>:
TRAPHANDLER_NOEC(Xirq2,   T_IRQ0+2)
  10355a:	6a 00                	push   $0x0
  10355c:	6a 22                	push   $0x22
  10355e:	e9 ad 00 00 00       	jmp    103610 <_alltraps>
  103563:	90                   	nop    

00103564 <Xirq3>:
TRAPHANDLER_NOEC(Xirq3,   T_IRQ0+3)
  103564:	6a 00                	push   $0x0
  103566:	6a 23                	push   $0x23
  103568:	e9 a3 00 00 00       	jmp    103610 <_alltraps>
  10356d:	90                   	nop    

0010356e <Xirq4>:
TRAPHANDLER_NOEC(Xirq4,   T_IRQ0+4)	// IRQ_SERIAL
  10356e:	6a 00                	push   $0x0
  103570:	6a 24                	push   $0x24
  103572:	e9 99 00 00 00       	jmp    103610 <_alltraps>
  103577:	90                   	nop    

00103578 <Xirq5>:
TRAPHANDLER_NOEC(Xirq5,   T_IRQ0+5)
  103578:	6a 00                	push   $0x0
  10357a:	6a 25                	push   $0x25
  10357c:	e9 8f 00 00 00       	jmp    103610 <_alltraps>
  103581:	90                   	nop    

00103582 <Xirq6>:
TRAPHANDLER_NOEC(Xirq6,   T_IRQ0+6)
  103582:	6a 00                	push   $0x0
  103584:	6a 26                	push   $0x26
  103586:	e9 85 00 00 00       	jmp    103610 <_alltraps>
  10358b:	90                   	nop    

0010358c <Xirq7>:
TRAPHANDLER_NOEC(Xirq7,   T_IRQ0+7)	// IRQ_SPURIOUS
  10358c:	6a 00                	push   $0x0
  10358e:	6a 27                	push   $0x27
  103590:	e9 7b 00 00 00       	jmp    103610 <_alltraps>
  103595:	90                   	nop    

00103596 <Xirq8>:
TRAPHANDLER_NOEC(Xirq8,   T_IRQ0+8)
  103596:	6a 00                	push   $0x0
  103598:	6a 28                	push   $0x28
  10359a:	e9 71 00 00 00       	jmp    103610 <_alltraps>
  10359f:	90                   	nop    

001035a0 <Xirq9>:
TRAPHANDLER_NOEC(Xirq9,   T_IRQ0+9)
  1035a0:	6a 00                	push   $0x0
  1035a2:	6a 29                	push   $0x29
  1035a4:	e9 67 00 00 00       	jmp    103610 <_alltraps>
  1035a9:	90                   	nop    

001035aa <Xirq10>:
TRAPHANDLER_NOEC(Xirq10,  T_IRQ0+10)
  1035aa:	6a 00                	push   $0x0
  1035ac:	6a 2a                	push   $0x2a
  1035ae:	e9 5d 00 00 00       	jmp    103610 <_alltraps>
  1035b3:	90                   	nop    

001035b4 <Xirq11>:
TRAPHANDLER_NOEC(Xirq11,  T_IRQ0+11)
  1035b4:	6a 00                	push   $0x0
  1035b6:	6a 2b                	push   $0x2b
  1035b8:	e9 53 00 00 00       	jmp    103610 <_alltraps>
  1035bd:	90                   	nop    

001035be <Xirq12>:
TRAPHANDLER_NOEC(Xirq12,  T_IRQ0+12)
  1035be:	6a 00                	push   $0x0
  1035c0:	6a 2c                	push   $0x2c
  1035c2:	e9 49 00 00 00       	jmp    103610 <_alltraps>
  1035c7:	90                   	nop    

001035c8 <Xirq13>:
TRAPHANDLER_NOEC(Xirq13,  T_IRQ0+13)
  1035c8:	6a 00                	push   $0x0
  1035ca:	6a 2d                	push   $0x2d
  1035cc:	e9 3f 00 00 00       	jmp    103610 <_alltraps>
  1035d1:	90                   	nop    

001035d2 <Xirq14>:
TRAPHANDLER_NOEC(Xirq14,  T_IRQ0+14)	// IRQ_IDE
  1035d2:	6a 00                	push   $0x0
  1035d4:	6a 2e                	push   $0x2e
  1035d6:	e9 35 00 00 00       	jmp    103610 <_alltraps>
  1035db:	90                   	nop    

001035dc <Xirq15>:
TRAPHANDLER_NOEC(Xirq15,  T_IRQ0+15)
  1035dc:	6a 00                	push   $0x0
  1035de:	6a 2f                	push   $0x2f
  1035e0:	e9 2b 00 00 00       	jmp    103610 <_alltraps>
  1035e5:	90                   	nop    

001035e6 <Xsyscall>:

TRAPHANDLER_NOEC(Xsyscall, T_SYSCALL)	// System call
  1035e6:	6a 00                	push   $0x0
  1035e8:	6a 30                	push   $0x30
  1035ea:	e9 21 00 00 00       	jmp    103610 <_alltraps>
  1035ef:	90                   	nop    

001035f0 <Xltimer>:
TRAPHANDLER_NOEC(Xltimer,  T_LTIMER)	// Local APIC timer
  1035f0:	6a 00                	push   $0x0
  1035f2:	6a 31                	push   $0x31
  1035f4:	e9 17 00 00 00       	jmp    103610 <_alltraps>
  1035f9:	90                   	nop    

001035fa <Xlerror>:
TRAPHANDLER_NOEC(Xlerror,  T_LERROR)	// Local APIC error
  1035fa:	6a 00                	push   $0x0
  1035fc:	6a 32                	push   $0x32
  1035fe:	e9 0d 00 00 00       	jmp    103610 <_alltraps>
  103603:	90                   	nop    

00103604 <Xdefault>:

/* default handler -- not for any specific trap */
TRAPHANDLER_NOEC(Xdefault, T_DEFAULT)
  103604:	6a 00                	push   $0x0
  103606:	68 f4 01 00 00       	push   $0x1f4
  10360b:	e9 00 00 00 00       	jmp    103610 <_alltraps>

00103610 <_alltraps>:



.globl	_alltraps
.type	_alltraps,@function
.p2align 4, 0x90		/* 16-byte alignment, nop filled */
_alltraps:
	pushl %ds		# build trap frame
  103610:	1e                   	push   %ds
	pushl %es
  103611:	06                   	push   %es
	pushl %fs
  103612:	0f a0                	push   %fs
	pushl %gs
  103614:	0f a8                	push   %gs
	pushal
  103616:	60                   	pusha  

	movl $CPU_GDT_KDATA,%eax # load kernel's data segment
  103617:	b8 10 00 00 00       	mov    $0x10,%eax
	movw %ax,%ds
  10361c:	8e d8                	movl   %eax,%ds
	movw %ax,%es
  10361e:	8e c0                	movl   %eax,%es

	xorl %ebp,%ebp		# don't let debug_trace() walk into user space
  103620:	31 ed                	xor    %ebp,%ebp

	pushl %esp		# pass pointer to this trapframe 
  103622:	54                   	push   %esp
	call trap		# and call trap (does not return)
  103623:	e8 7e f8 ff ff       	call   102ea6 <trap>

1:	jmp 1b			# should never get here; just spin...
  103628:	eb fe                	jmp    103628 <_alltraps+0x18>
  10362a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi

00103630 <trap_return>:



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
  103630:	8b 64 24 04          	mov    0x4(%esp),%esp
	popal			// restore general-purpose registers except esp
  103634:	61                   	popa   
	popl	%gs		// restore data segment registers
  103635:	0f a9                	pop    %gs
	popl	%fs
  103637:	0f a1                	pop    %fs
	popl	%es
  103639:	07                   	pop    %es
	popl	%ds
  10363a:	1f                   	pop    %ds
	addl	$8,%esp		// skip trapno and errcode
  10363b:	83 c4 08             	add    $0x8,%esp
	iret			// return from trap handler
  10363e:	cf                   	iret   
  10363f:	90                   	nop    

00103640 <sum>:


static uint8_t
sum(uint8_t * addr, int len)
{
  103640:	55                   	push   %ebp
  103641:	89 e5                	mov    %esp,%ebp
  103643:	83 ec 10             	sub    $0x10,%esp
	int i, sum;

	sum = 0;
  103646:	c7 45 fc 00 00 00 00 	movl   $0x0,0xfffffffc(%ebp)
	for (i = 0; i < len; i++)
  10364d:	c7 45 f8 00 00 00 00 	movl   $0x0,0xfffffff8(%ebp)
  103654:	eb 13                	jmp    103669 <sum+0x29>
		sum += addr[i];
  103656:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  103659:	03 45 08             	add    0x8(%ebp),%eax
  10365c:	0f b6 00             	movzbl (%eax),%eax
  10365f:	0f b6 c0             	movzbl %al,%eax
  103662:	01 45 fc             	add    %eax,0xfffffffc(%ebp)
  103665:	83 45 f8 01          	addl   $0x1,0xfffffff8(%ebp)
  103669:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10366c:	3b 45 0c             	cmp    0xc(%ebp),%eax
  10366f:	7c e5                	jl     103656 <sum+0x16>
	return sum;
  103671:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  103674:	0f b6 c0             	movzbl %al,%eax
}
  103677:	c9                   	leave  
  103678:	c3                   	ret    

00103679 <mpsearch1>:

//Look for an MP structure in the len bytes at addr.
static struct mp *
mpsearch1(uint8_t * addr, int len)
{
  103679:	55                   	push   %ebp
  10367a:	89 e5                	mov    %esp,%ebp
  10367c:	83 ec 28             	sub    $0x28,%esp
	uint8_t *e, *p;

	e = addr + len;
  10367f:	8b 45 0c             	mov    0xc(%ebp),%eax
  103682:	03 45 08             	add    0x8(%ebp),%eax
  103685:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
	for (p = addr; p < e; p += sizeof(struct mp))
  103688:	8b 45 08             	mov    0x8(%ebp),%eax
  10368b:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  10368e:	eb 42                	jmp    1036d2 <mpsearch1+0x59>
		if (memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
  103690:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
  103697:	00 
  103698:	c7 44 24 04 c8 c7 10 	movl   $0x10c7c8,0x4(%esp)
  10369f:	00 
  1036a0:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  1036a3:	89 04 24             	mov    %eax,(%esp)
  1036a6:	e8 be 82 00 00       	call   10b969 <memcmp>
  1036ab:	85 c0                	test   %eax,%eax
  1036ad:	75 1f                	jne    1036ce <mpsearch1+0x55>
  1036af:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
  1036b6:	00 
  1036b7:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  1036ba:	89 04 24             	mov    %eax,(%esp)
  1036bd:	e8 7e ff ff ff       	call   103640 <sum>
  1036c2:	84 c0                	test   %al,%al
  1036c4:	75 08                	jne    1036ce <mpsearch1+0x55>
			return (struct mp *) p;
  1036c6:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  1036c9:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  1036cc:	eb 13                	jmp    1036e1 <mpsearch1+0x68>
  1036ce:	83 45 fc 10          	addl   $0x10,0xfffffffc(%ebp)
  1036d2:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  1036d5:	3b 45 f8             	cmp    0xfffffff8(%ebp),%eax
  1036d8:	72 b6                	jb     103690 <mpsearch1+0x17>
	return 0;
  1036da:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  1036e1:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
}
  1036e4:	c9                   	leave  
  1036e5:	c3                   	ret    

001036e6 <mpsearch>:

// Search for the MP Floating Pointer Structure, which according to the
// spec is in one of the following three locations:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp *
mpsearch(void)
{
  1036e6:	55                   	push   %ebp
  1036e7:	89 e5                	mov    %esp,%ebp
  1036e9:	83 ec 28             	sub    $0x28,%esp
	uint8_t          *bda;
	uint32_t            p;
	struct mp      *mp;

	bda = (uint8_t *) 0x400;
  1036ec:	c7 45 f4 00 04 00 00 	movl   $0x400,0xfffffff4(%ebp)
	if ((p = ((bda[0x0F] << 8) | bda[0x0E]) << 4)) {
  1036f3:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  1036f6:	83 c0 0f             	add    $0xf,%eax
  1036f9:	0f b6 00             	movzbl (%eax),%eax
  1036fc:	0f b6 c0             	movzbl %al,%eax
  1036ff:	89 c2                	mov    %eax,%edx
  103701:	c1 e2 08             	shl    $0x8,%edx
  103704:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  103707:	83 c0 0e             	add    $0xe,%eax
  10370a:	0f b6 00             	movzbl (%eax),%eax
  10370d:	0f b6 c0             	movzbl %al,%eax
  103710:	09 d0                	or     %edx,%eax
  103712:	c1 e0 04             	shl    $0x4,%eax
  103715:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  103718:	83 7d f8 00          	cmpl   $0x0,0xfffffff8(%ebp)
  10371c:	74 24                	je     103742 <mpsearch+0x5c>
		if ((mp = mpsearch1((uint8_t *) p, 1024)))
  10371e:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  103721:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
  103728:	00 
  103729:	89 04 24             	mov    %eax,(%esp)
  10372c:	e8 48 ff ff ff       	call   103679 <mpsearch1>
  103731:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  103734:	83 7d fc 00          	cmpl   $0x0,0xfffffffc(%ebp)
  103738:	74 56                	je     103790 <mpsearch+0xaa>
			return mp;
  10373a:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  10373d:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  103740:	eb 65                	jmp    1037a7 <mpsearch+0xc1>
	} else {
		p = ((bda[0x14] << 8) | bda[0x13]) * 1024;
  103742:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  103745:	83 c0 14             	add    $0x14,%eax
  103748:	0f b6 00             	movzbl (%eax),%eax
  10374b:	0f b6 c0             	movzbl %al,%eax
  10374e:	89 c2                	mov    %eax,%edx
  103750:	c1 e2 08             	shl    $0x8,%edx
  103753:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  103756:	83 c0 13             	add    $0x13,%eax
  103759:	0f b6 00             	movzbl (%eax),%eax
  10375c:	0f b6 c0             	movzbl %al,%eax
  10375f:	09 d0                	or     %edx,%eax
  103761:	c1 e0 0a             	shl    $0xa,%eax
  103764:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
		if ((mp = mpsearch1((uint8_t *) p - 1024, 1024)))
  103767:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10376a:	2d 00 04 00 00       	sub    $0x400,%eax
  10376f:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
  103776:	00 
  103777:	89 04 24             	mov    %eax,(%esp)
  10377a:	e8 fa fe ff ff       	call   103679 <mpsearch1>
  10377f:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  103782:	83 7d fc 00          	cmpl   $0x0,0xfffffffc(%ebp)
  103786:	74 08                	je     103790 <mpsearch+0xaa>
			return mp;
  103788:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  10378b:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  10378e:	eb 17                	jmp    1037a7 <mpsearch+0xc1>
	}
	return mpsearch1((uint8_t *) 0xF0000, 0x10000);
  103790:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
  103797:	00 
  103798:	c7 04 24 00 00 0f 00 	movl   $0xf0000,(%esp)
  10379f:	e8 d5 fe ff ff       	call   103679 <mpsearch1>
  1037a4:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  1037a7:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
}
  1037aa:	c9                   	leave  
  1037ab:	c3                   	ret    

001037ac <mpconfig>:

// Search for an MP configuration table.  For now,
// don 't accept the default configurations (physaddr == 0).
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf *
mpconfig(struct mp **pmp) {
  1037ac:	55                   	push   %ebp
  1037ad:	89 e5                	mov    %esp,%ebp
  1037af:	83 ec 28             	sub    $0x28,%esp
	struct mpconf  *conf;
	struct mp      *mp;

	if ((mp = mpsearch()) == 0 || mp->physaddr == 0)
  1037b2:	e8 2f ff ff ff       	call   1036e6 <mpsearch>
  1037b7:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  1037ba:	83 7d fc 00          	cmpl   $0x0,0xfffffffc(%ebp)
  1037be:	74 0a                	je     1037ca <mpconfig+0x1e>
  1037c0:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  1037c3:	8b 40 04             	mov    0x4(%eax),%eax
  1037c6:	85 c0                	test   %eax,%eax
  1037c8:	75 0c                	jne    1037d6 <mpconfig+0x2a>
		return 0;
  1037ca:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  1037d1:	e9 84 00 00 00       	jmp    10385a <mpconfig+0xae>
	conf = (struct mpconf *) mp->physaddr;
  1037d6:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  1037d9:	8b 40 04             	mov    0x4(%eax),%eax
  1037dc:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
	if (memcmp(conf, "PCMP", 4) != 0)
  1037df:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
  1037e6:	00 
  1037e7:	c7 44 24 04 cd c7 10 	movl   $0x10c7cd,0x4(%esp)
  1037ee:	00 
  1037ef:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1037f2:	89 04 24             	mov    %eax,(%esp)
  1037f5:	e8 6f 81 00 00       	call   10b969 <memcmp>
  1037fa:	85 c0                	test   %eax,%eax
  1037fc:	74 09                	je     103807 <mpconfig+0x5b>
		return 0;
  1037fe:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  103805:	eb 53                	jmp    10385a <mpconfig+0xae>
	if (conf->version != 1 && conf->version != 4)
  103807:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10380a:	0f b6 40 06          	movzbl 0x6(%eax),%eax
  10380e:	3c 01                	cmp    $0x1,%al
  103810:	74 14                	je     103826 <mpconfig+0x7a>
  103812:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  103815:	0f b6 40 06          	movzbl 0x6(%eax),%eax
  103819:	3c 04                	cmp    $0x4,%al
  10381b:	74 09                	je     103826 <mpconfig+0x7a>
		return 0;
  10381d:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  103824:	eb 34                	jmp    10385a <mpconfig+0xae>
	if (sum((uint8_t *) conf, conf->length) != 0)
  103826:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  103829:	0f b7 40 04          	movzwl 0x4(%eax),%eax
  10382d:	0f b7 c0             	movzwl %ax,%eax
  103830:	8b 55 f8             	mov    0xfffffff8(%ebp),%edx
  103833:	89 44 24 04          	mov    %eax,0x4(%esp)
  103837:	89 14 24             	mov    %edx,(%esp)
  10383a:	e8 01 fe ff ff       	call   103640 <sum>
  10383f:	84 c0                	test   %al,%al
  103841:	74 09                	je     10384c <mpconfig+0xa0>
		return 0;
  103843:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  10384a:	eb 0e                	jmp    10385a <mpconfig+0xae>
       *pmp = mp;
  10384c:	8b 55 08             	mov    0x8(%ebp),%edx
  10384f:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  103852:	89 02                	mov    %eax,(%edx)
	return conf;
  103854:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  103857:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  10385a:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
}
  10385d:	c9                   	leave  
  10385e:	c3                   	ret    

0010385f <mp_init>:

void
mp_init(void)
{
  10385f:	55                   	push   %ebp
  103860:	89 e5                	mov    %esp,%ebp
  103862:	83 ec 58             	sub    $0x58,%esp
	uint8_t          *p, *e;
	struct mp      *mp;
	struct mpconf  *conf;
	struct mpproc  *proc;
	struct mpioapic *mpio;

	if (!cpu_onboot())	// only do once, on the boot CPU
  103865:	e8 88 01 00 00       	call   1039f2 <cpu_onboot>
  10386a:	85 c0                	test   %eax,%eax
  10386c:	0f 84 7e 01 00 00    	je     1039f0 <mp_init+0x191>
		return;

	if ((conf = mpconfig(&mp)) == 0)
  103872:	8d 45 cc             	lea    0xffffffcc(%ebp),%eax
  103875:	89 04 24             	mov    %eax,(%esp)
  103878:	e8 2f ff ff ff       	call   1037ac <mpconfig>
  10387d:	89 45 d8             	mov    %eax,0xffffffd8(%ebp)
  103880:	83 7d d8 00          	cmpl   $0x0,0xffffffd8(%ebp)
  103884:	0f 84 66 01 00 00    	je     1039f0 <mp_init+0x191>
		return; // Not a multiprocessor machine - just use boot CPU.

	ismp = 1;
  10388a:	c7 05 e8 ed 17 00 01 	movl   $0x1,0x17ede8
  103891:	00 00 00 
	lapic = (uint32_t *) conf->lapicaddr;
  103894:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  103897:	8b 40 24             	mov    0x24(%eax),%eax
  10389a:	a3 04 20 18 00       	mov    %eax,0x182004
	for (p = (uint8_t *) (conf + 1), e = (uint8_t *) conf + conf->length;
  10389f:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  1038a2:	83 c0 2c             	add    $0x2c,%eax
  1038a5:	89 45 d0             	mov    %eax,0xffffffd0(%ebp)
  1038a8:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  1038ab:	0f b7 40 04          	movzwl 0x4(%eax),%eax
  1038af:	0f b7 c0             	movzwl %ax,%eax
  1038b2:	89 c2                	mov    %eax,%edx
  1038b4:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  1038b7:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1038ba:	89 45 d4             	mov    %eax,0xffffffd4(%ebp)
			p < e;) {
  1038bd:	e9 da 00 00 00       	jmp    10399c <mp_init+0x13d>
		switch (*p) {
  1038c2:	8b 45 d0             	mov    0xffffffd0(%ebp),%eax
  1038c5:	0f b6 00             	movzbl (%eax),%eax
  1038c8:	0f b6 c0             	movzbl %al,%eax
  1038cb:	89 45 b8             	mov    %eax,0xffffffb8(%ebp)
  1038ce:	83 7d b8 04          	cmpl   $0x4,0xffffffb8(%ebp)
  1038d2:	0f 87 9b 00 00 00    	ja     103973 <mp_init+0x114>
  1038d8:	8b 55 b8             	mov    0xffffffb8(%ebp),%edx
  1038db:	8b 04 95 00 c8 10 00 	mov    0x10c800(,%edx,4),%eax
  1038e2:	ff e0                	jmp    *%eax
		case MPPROC:
			proc = (struct mpproc *) p;
  1038e4:	8b 45 d0             	mov    0xffffffd0(%ebp),%eax
  1038e7:	89 45 dc             	mov    %eax,0xffffffdc(%ebp)
			p += sizeof(struct mpproc);
  1038ea:	83 45 d0 14          	addl   $0x14,0xffffffd0(%ebp)
			if (!(proc->flags & MPENAB))
  1038ee:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  1038f1:	0f b6 40 03          	movzbl 0x3(%eax),%eax
  1038f5:	0f b6 c0             	movzbl %al,%eax
  1038f8:	83 e0 01             	and    $0x1,%eax
  1038fb:	85 c0                	test   %eax,%eax
  1038fd:	0f 84 99 00 00 00    	je     10399c <mp_init+0x13d>
				continue;	// processor disabled

			// Get a cpu struct and kernel stack for this CPU.
			cpu *c = (proc->flags & MPBOOT)
					? &cpu_boot : cpu_alloc();
  103903:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  103906:	0f b6 40 03          	movzbl 0x3(%eax),%eax
  10390a:	0f b6 c0             	movzbl %al,%eax
  10390d:	83 e0 02             	and    $0x2,%eax
  103910:	85 c0                	test   %eax,%eax
  103912:	75 0a                	jne    10391e <mp_init+0xbf>
  103914:	e8 15 de ff ff       	call   10172e <cpu_alloc>
  103919:	89 45 bc             	mov    %eax,0xffffffbc(%ebp)
  10391c:	eb 07                	jmp    103925 <mp_init+0xc6>
  10391e:	c7 45 bc 00 e0 10 00 	movl   $0x10e000,0xffffffbc(%ebp)
  103925:	8b 45 bc             	mov    0xffffffbc(%ebp),%eax
  103928:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
			c->id = proc->apicid;
  10392b:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  10392e:	0f b6 50 01          	movzbl 0x1(%eax),%edx
  103932:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  103935:	88 90 ac 00 00 00    	mov    %dl,0xac(%eax)
			ncpu++;
  10393b:	a1 ec ed 17 00       	mov    0x17edec,%eax
  103940:	83 c0 01             	add    $0x1,%eax
  103943:	a3 ec ed 17 00       	mov    %eax,0x17edec
			continue;
  103948:	eb 52                	jmp    10399c <mp_init+0x13d>
		case MPIOAPIC:
			mpio = (struct mpioapic *) p;
  10394a:	8b 45 d0             	mov    0xffffffd0(%ebp),%eax
  10394d:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)
			p += sizeof(struct mpioapic);
  103950:	83 45 d0 08          	addl   $0x8,0xffffffd0(%ebp)
			ioapicid = mpio->apicno;
  103954:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  103957:	0f b6 40 01          	movzbl 0x1(%eax),%eax
  10395b:	a2 e0 ed 17 00       	mov    %al,0x17ede0
			ioapic = (struct ioapic *) mpio->addr;
  103960:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  103963:	8b 40 04             	mov    0x4(%eax),%eax
  103966:	a3 e4 ed 17 00       	mov    %eax,0x17ede4
			continue;
  10396b:	eb 2f                	jmp    10399c <mp_init+0x13d>
		case MPBUS:
		case MPIOINTR:
		case MPLINTR:
			p += 8;
  10396d:	83 45 d0 08          	addl   $0x8,0xffffffd0(%ebp)
			continue;
  103971:	eb 29                	jmp    10399c <mp_init+0x13d>
		default:
			panic("mpinit: unknown config type %x\n", *p);
  103973:	8b 45 d0             	mov    0xffffffd0(%ebp),%eax
  103976:	0f b6 00             	movzbl (%eax),%eax
  103979:	0f b6 c0             	movzbl %al,%eax
  10397c:	89 44 24 0c          	mov    %eax,0xc(%esp)
  103980:	c7 44 24 08 d4 c7 10 	movl   $0x10c7d4,0x8(%esp)
  103987:	00 
  103988:	c7 44 24 04 92 00 00 	movl   $0x92,0x4(%esp)
  10398f:	00 
  103990:	c7 04 24 f4 c7 10 00 	movl   $0x10c7f4,(%esp)
  103997:	e8 9c cf ff ff       	call   100938 <debug_panic>
  10399c:	8b 45 d0             	mov    0xffffffd0(%ebp),%eax
  10399f:	3b 45 d4             	cmp    0xffffffd4(%ebp),%eax
  1039a2:	0f 82 1a ff ff ff    	jb     1038c2 <mp_init+0x63>
		}
	}
	if (mp->imcrp) {
  1039a8:	8b 45 cc             	mov    0xffffffcc(%ebp),%eax
  1039ab:	0f b6 40 0c          	movzbl 0xc(%eax),%eax
  1039af:	84 c0                	test   %al,%al
  1039b1:	74 3d                	je     1039f0 <mp_init+0x191>
  1039b3:	c7 45 ec 22 00 00 00 	movl   $0x22,0xffffffec(%ebp)
  1039ba:	c6 45 eb 70          	movb   $0x70,0xffffffeb(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  1039be:	0f b6 45 eb          	movzbl 0xffffffeb(%ebp),%eax
  1039c2:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
  1039c5:	ee                   	out    %al,(%dx)
  1039c6:	c7 45 f4 23 00 00 00 	movl   $0x23,0xfffffff4(%ebp)
  1039cd:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  1039d0:	ec                   	in     (%dx),%al
  1039d1:	88 45 f3             	mov    %al,0xfffffff3(%ebp)
  1039d4:	0f b6 45 f3          	movzbl 0xfffffff3(%ebp),%eax
		// Bochs doesn 't support IMCR, so this doesn' t run on Bochs.
		// But it would on real hardware.
		outb(0x22, 0x70);		// Select IMCR
		outb(0x23, inb(0x23) | 1);	// Mask external interrupts.
  1039d8:	83 c8 01             	or     $0x1,%eax
  1039db:	0f b6 c0             	movzbl %al,%eax
  1039de:	c7 45 fc 23 00 00 00 	movl   $0x23,0xfffffffc(%ebp)
  1039e5:	88 45 fb             	mov    %al,0xfffffffb(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  1039e8:	0f b6 45 fb          	movzbl 0xfffffffb(%ebp),%eax
  1039ec:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  1039ef:	ee                   	out    %al,(%dx)
	}
}
  1039f0:	c9                   	leave  
  1039f1:	c3                   	ret    

001039f2 <cpu_onboot>:
}

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  1039f2:	55                   	push   %ebp
  1039f3:	89 e5                	mov    %esp,%ebp
  1039f5:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  1039f8:	e8 0d 00 00 00       	call   103a0a <cpu_cur>
  1039fd:	3d 00 e0 10 00       	cmp    $0x10e000,%eax
  103a02:	0f 94 c0             	sete   %al
  103a05:	0f b6 c0             	movzbl %al,%eax
}
  103a08:	c9                   	leave  
  103a09:	c3                   	ret    

00103a0a <cpu_cur>:
  103a0a:	55                   	push   %ebp
  103a0b:	89 e5                	mov    %esp,%ebp
  103a0d:	83 ec 28             	sub    $0x28,%esp
static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  103a10:	89 65 fc             	mov    %esp,0xfffffffc(%ebp)
        return esp;
  103a13:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  103a16:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  103a19:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  103a1c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  103a21:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	assert(c->magic == CPU_MAGIC);
  103a24:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  103a27:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  103a2d:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  103a32:	74 24                	je     103a58 <cpu_cur+0x4e>
  103a34:	c7 44 24 0c 14 c8 10 	movl   $0x10c814,0xc(%esp)
  103a3b:	00 
  103a3c:	c7 44 24 08 2a c8 10 	movl   $0x10c82a,0x8(%esp)
  103a43:	00 
  103a44:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  103a4b:	00 
  103a4c:	c7 04 24 3f c8 10 00 	movl   $0x10c83f,(%esp)
  103a53:	e8 e0 ce ff ff       	call   100938 <debug_panic>
	return c;
  103a58:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
}
  103a5b:	c9                   	leave  
  103a5c:	c3                   	ret    
  103a5d:	90                   	nop    
  103a5e:	90                   	nop    
  103a5f:	90                   	nop    

00103a60 <spinlock_init_>:


void
spinlock_init_(struct spinlock *lk, const char *file, int line)
{
  103a60:	55                   	push   %ebp
  103a61:	89 e5                	mov    %esp,%ebp
  lk->file = file;
  103a63:	8b 55 08             	mov    0x8(%ebp),%edx
  103a66:	8b 45 0c             	mov    0xc(%ebp),%eax
  103a69:	89 42 04             	mov    %eax,0x4(%edx)
  lk->line = line;
  103a6c:	8b 55 08             	mov    0x8(%ebp),%edx
  103a6f:	8b 45 10             	mov    0x10(%ebp),%eax
  103a72:	89 42 08             	mov    %eax,0x8(%edx)
  lk->locked = 0;
  103a75:	8b 45 08             	mov    0x8(%ebp),%eax
  103a78:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->cpu = NULL;
  103a7e:	8b 45 08             	mov    0x8(%ebp),%eax
  103a81:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
}
  103a88:	5d                   	pop    %ebp
  103a89:	c3                   	ret    

00103a8a <spinlock_acquire>:

// Acquire the lock.
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
spinlock_acquire(struct spinlock *lk)
{
  103a8a:	55                   	push   %ebp
  103a8b:	89 e5                	mov    %esp,%ebp
  103a8d:	83 ec 28             	sub    $0x28,%esp
  if (spinlock_holding(lk))
  103a90:	8b 45 08             	mov    0x8(%ebp),%eax
  103a93:	89 04 24             	mov    %eax,(%esp)
  103a96:	e8 44 01 00 00       	call   103bdf <spinlock_holding>
  103a9b:	85 c0                	test   %eax,%eax
  103a9d:	74 21                	je     103ac0 <spinlock_acquire+0x36>
    panic("Attempt to acquire lock already held by this cpu");
  103a9f:	c7 44 24 08 4c c8 10 	movl   $0x10c84c,0x8(%esp)
  103aa6:	00 
  103aa7:	c7 44 24 04 24 00 00 	movl   $0x24,0x4(%esp)
  103aae:	00 
  103aaf:	c7 04 24 7d c8 10 00 	movl   $0x10c87d,(%esp)
  103ab6:	e8 7d ce ff ff       	call   100938 <debug_panic>
  while(xchg(&lk->locked, 1) != 0) {
    pause(); // buisy wait
  103abb:	e8 3e 00 00 00       	call   103afe <pause>
  103ac0:	8b 45 08             	mov    0x8(%ebp),%eax
  103ac3:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  103aca:	00 
  103acb:	89 04 24             	mov    %eax,(%esp)
  103ace:	e8 32 00 00 00       	call   103b05 <xchg>
  103ad3:	85 c0                	test   %eax,%eax
  103ad5:	75 e4                	jne    103abb <spinlock_acquire+0x31>
  }
  lk->cpu = cpu_cur();
  103ad7:	e8 56 00 00 00       	call   103b32 <cpu_cur>
  103adc:	89 c2                	mov    %eax,%edx
  103ade:	8b 45 08             	mov    0x8(%ebp),%eax
  103ae1:	89 50 0c             	mov    %edx,0xc(%eax)
  debug_trace(read_ebp(), lk->eips);
  103ae4:	8b 55 08             	mov    0x8(%ebp),%edx
  103ae7:	83 c2 10             	add    $0x10,%edx
static gcc_inline uint32_t
read_ebp(void)
{
        uint32_t ebp;
        __asm __volatile("movl %%ebp,%0" : "=rm" (ebp));
  103aea:	89 6d fc             	mov    %ebp,0xfffffffc(%ebp)
        return ebp;
  103aed:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  103af0:	89 54 24 04          	mov    %edx,0x4(%esp)
  103af4:	89 04 24             	mov    %eax,(%esp)
  103af7:	e8 43 cf ff ff       	call   100a3f <debug_trace>
}
  103afc:	c9                   	leave  
  103afd:	c3                   	ret    

00103afe <pause>:
}

static inline void
pause(void)
{
  103afe:	55                   	push   %ebp
  103aff:	89 e5                	mov    %esp,%ebp
	asm volatile("pause" : : : "memory");
  103b01:	f3 90                	pause  
}
  103b03:	5d                   	pop    %ebp
  103b04:	c3                   	ret    

00103b05 <xchg>:
  103b05:	55                   	push   %ebp
  103b06:	89 e5                	mov    %esp,%ebp
  103b08:	53                   	push   %ebx
  103b09:	83 ec 14             	sub    $0x14,%esp
  103b0c:	8b 4d 08             	mov    0x8(%ebp),%ecx
  103b0f:	8b 55 0c             	mov    0xc(%ebp),%edx
  103b12:	8b 45 08             	mov    0x8(%ebp),%eax
  103b15:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  103b18:	89 d0                	mov    %edx,%eax
  103b1a:	8b 5d e8             	mov    0xffffffe8(%ebp),%ebx
  103b1d:	f0 87 01             	lock xchg %eax,(%ecx)
  103b20:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  103b23:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  103b26:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  103b29:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  103b2c:	83 c4 14             	add    $0x14,%esp
  103b2f:	5b                   	pop    %ebx
  103b30:	5d                   	pop    %ebp
  103b31:	c3                   	ret    

00103b32 <cpu_cur>:

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  103b32:	55                   	push   %ebp
  103b33:	89 e5                	mov    %esp,%ebp
  103b35:	83 ec 28             	sub    $0x28,%esp
static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  103b38:	89 65 fc             	mov    %esp,0xfffffffc(%ebp)
        return esp;
  103b3b:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  103b3e:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  103b41:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  103b44:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  103b49:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	assert(c->magic == CPU_MAGIC);
  103b4c:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  103b4f:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  103b55:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  103b5a:	74 24                	je     103b80 <cpu_cur+0x4e>
  103b5c:	c7 44 24 0c 8d c8 10 	movl   $0x10c88d,0xc(%esp)
  103b63:	00 
  103b64:	c7 44 24 08 a3 c8 10 	movl   $0x10c8a3,0x8(%esp)
  103b6b:	00 
  103b6c:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  103b73:	00 
  103b74:	c7 04 24 b8 c8 10 00 	movl   $0x10c8b8,(%esp)
  103b7b:	e8 b8 cd ff ff       	call   100938 <debug_panic>
	return c;
  103b80:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
}
  103b83:	c9                   	leave  
  103b84:	c3                   	ret    

00103b85 <spinlock_release>:

// Release the lock.
void
spinlock_release(struct spinlock *lk)
{
  103b85:	55                   	push   %ebp
  103b86:	89 e5                	mov    %esp,%ebp
  103b88:	83 ec 18             	sub    $0x18,%esp
  if (!spinlock_holding(lk))
  103b8b:	8b 45 08             	mov    0x8(%ebp),%eax
  103b8e:	89 04 24             	mov    %eax,(%esp)
  103b91:	e8 49 00 00 00       	call   103bdf <spinlock_holding>
  103b96:	85 c0                	test   %eax,%eax
  103b98:	75 1c                	jne    103bb6 <spinlock_release+0x31>
    panic("Attempt to release lock not held by this cpu");
  103b9a:	c7 44 24 08 c8 c8 10 	movl   $0x10c8c8,0x8(%esp)
  103ba1:	00 
  103ba2:	c7 44 24 04 31 00 00 	movl   $0x31,0x4(%esp)
  103ba9:	00 
  103baa:	c7 04 24 7d c8 10 00 	movl   $0x10c87d,(%esp)
  103bb1:	e8 82 cd ff ff       	call   100938 <debug_panic>
  lk->eips[0] = 0;
  103bb6:	8b 45 08             	mov    0x8(%ebp),%eax
  103bb9:	c7 40 10 00 00 00 00 	movl   $0x0,0x10(%eax)
  lk->cpu = 0;
  103bc0:	8b 45 08             	mov    0x8(%ebp),%eax
  103bc3:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  xchg(&lk->locked, 0);
  103bca:	8b 45 08             	mov    0x8(%ebp),%eax
  103bcd:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  103bd4:	00 
  103bd5:	89 04 24             	mov    %eax,(%esp)
  103bd8:	e8 28 ff ff ff       	call   103b05 <xchg>
}
  103bdd:	c9                   	leave  
  103bde:	c3                   	ret    

00103bdf <spinlock_holding>:

// Check whether this cpu is holding the lock.
int
spinlock_holding(spinlock *lk)
{
  103bdf:	55                   	push   %ebp
  103be0:	89 e5                	mov    %esp,%ebp
  103be2:	53                   	push   %ebx
  103be3:	83 ec 04             	sub    $0x4,%esp
  return (lk->locked) && (lk->cpu == cpu_cur());
  103be6:	8b 45 08             	mov    0x8(%ebp),%eax
  103be9:	8b 00                	mov    (%eax),%eax
  103beb:	85 c0                	test   %eax,%eax
  103bed:	74 18                	je     103c07 <spinlock_holding+0x28>
  103bef:	8b 45 08             	mov    0x8(%ebp),%eax
  103bf2:	8b 58 0c             	mov    0xc(%eax),%ebx
  103bf5:	e8 38 ff ff ff       	call   103b32 <cpu_cur>
  103bfa:	39 c3                	cmp    %eax,%ebx
  103bfc:	75 09                	jne    103c07 <spinlock_holding+0x28>
  103bfe:	c7 45 f8 01 00 00 00 	movl   $0x1,0xfffffff8(%ebp)
  103c05:	eb 07                	jmp    103c0e <spinlock_holding+0x2f>
  103c07:	c7 45 f8 00 00 00 00 	movl   $0x0,0xfffffff8(%ebp)
  103c0e:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
}
  103c11:	83 c4 04             	add    $0x4,%esp
  103c14:	5b                   	pop    %ebx
  103c15:	5d                   	pop    %ebp
  103c16:	c3                   	ret    

00103c17 <spinlock_godeep>:

// Function that simply recurses to a specified depth.
// The useless return value and volatile parameter are
// so GCC doesn't collapse it via tail-call elimination.
int gcc_noinline
spinlock_godeep(volatile int depth, spinlock* lk)
{
  103c17:	55                   	push   %ebp
  103c18:	89 e5                	mov    %esp,%ebp
  103c1a:	83 ec 18             	sub    $0x18,%esp
	if (depth==0) { spinlock_acquire(lk); return 1; }
  103c1d:	8b 45 08             	mov    0x8(%ebp),%eax
  103c20:	85 c0                	test   %eax,%eax
  103c22:	75 14                	jne    103c38 <spinlock_godeep+0x21>
  103c24:	8b 45 0c             	mov    0xc(%ebp),%eax
  103c27:	89 04 24             	mov    %eax,(%esp)
  103c2a:	e8 5b fe ff ff       	call   103a8a <spinlock_acquire>
  103c2f:	c7 45 fc 01 00 00 00 	movl   $0x1,0xfffffffc(%ebp)
  103c36:	eb 22                	jmp    103c5a <spinlock_godeep+0x43>
	else return spinlock_godeep(depth-1, lk) * depth;
  103c38:	8b 45 08             	mov    0x8(%ebp),%eax
  103c3b:	8d 50 ff             	lea    0xffffffff(%eax),%edx
  103c3e:	8b 45 0c             	mov    0xc(%ebp),%eax
  103c41:	89 44 24 04          	mov    %eax,0x4(%esp)
  103c45:	89 14 24             	mov    %edx,(%esp)
  103c48:	e8 ca ff ff ff       	call   103c17 <spinlock_godeep>
  103c4d:	89 c2                	mov    %eax,%edx
  103c4f:	8b 45 08             	mov    0x8(%ebp),%eax
  103c52:	89 d1                	mov    %edx,%ecx
  103c54:	0f af c8             	imul   %eax,%ecx
  103c57:	89 4d fc             	mov    %ecx,0xfffffffc(%ebp)
  103c5a:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
}
  103c5d:	c9                   	leave  
  103c5e:	c3                   	ret    

00103c5f <spinlock_check>:

void spinlock_check()
{
  103c5f:	55                   	push   %ebp
  103c60:	89 e5                	mov    %esp,%ebp
  103c62:	53                   	push   %ebx
  103c63:	83 ec 44             	sub    $0x44,%esp
  103c66:	89 e0                	mov    %esp,%eax
  103c68:	89 45 d8             	mov    %eax,0xffffffd8(%ebp)
	const int NUMLOCKS=10;
  103c6b:	c7 45 e4 0a 00 00 00 	movl   $0xa,0xffffffe4(%ebp)
	const int NUMRUNS=5;
  103c72:	c7 45 e8 05 00 00 00 	movl   $0x5,0xffffffe8(%ebp)
	int i,j,run;
	const char* file = "spinlock_check";
  103c79:	c7 45 f8 f5 c8 10 00 	movl   $0x10c8f5,0xfffffff8(%ebp)
	spinlock locks[NUMLOCKS];
  103c80:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  103c83:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  103c8a:	8d 04 d5 00 00 00 00 	lea    0x0(,%edx,8),%eax
  103c91:	29 d0                	sub    %edx,%eax
  103c93:	83 c0 0f             	add    $0xf,%eax
  103c96:	83 c0 0f             	add    $0xf,%eax
  103c99:	c1 e8 04             	shr    $0x4,%eax
  103c9c:	c1 e0 04             	shl    $0x4,%eax
  103c9f:	29 c4                	sub    %eax,%esp
  103ca1:	8d 44 24 10          	lea    0x10(%esp),%eax
  103ca5:	89 45 d4             	mov    %eax,0xffffffd4(%ebp)
  103ca8:	8b 45 d4             	mov    0xffffffd4(%ebp),%eax
  103cab:	83 c0 0f             	add    $0xf,%eax
  103cae:	c1 e8 04             	shr    $0x4,%eax
  103cb1:	c1 e0 04             	shl    $0x4,%eax
  103cb4:	89 45 d4             	mov    %eax,0xffffffd4(%ebp)
  103cb7:	8b 45 d4             	mov    0xffffffd4(%ebp),%eax
  103cba:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)

	// Initialize the locks
	for(i=0;i<NUMLOCKS;i++) spinlock_init_(&locks[i], file, 0);
  103cbd:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  103cc4:	eb 34                	jmp    103cfa <spinlock_check+0x9b>
  103cc6:	8b 4d e0             	mov    0xffffffe0(%ebp),%ecx
  103cc9:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  103ccc:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  103cd3:	8d 04 d5 00 00 00 00 	lea    0x0(,%edx,8),%eax
  103cda:	29 d0                	sub    %edx,%eax
  103cdc:	8d 14 01             	lea    (%ecx,%eax,1),%edx
  103cdf:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  103ce6:	00 
  103ce7:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  103cea:	89 44 24 04          	mov    %eax,0x4(%esp)
  103cee:	89 14 24             	mov    %edx,(%esp)
  103cf1:	e8 6a fd ff ff       	call   103a60 <spinlock_init_>
  103cf6:	83 45 ec 01          	addl   $0x1,0xffffffec(%ebp)
  103cfa:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  103cfd:	3b 45 e4             	cmp    0xffffffe4(%ebp),%eax
  103d00:	7c c4                	jl     103cc6 <spinlock_check+0x67>
	// Make sure that all locks have CPU set to NULL initially
	for(i=0;i<NUMLOCKS;i++) assert(locks[i].cpu==NULL);
  103d02:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  103d09:	eb 49                	jmp    103d54 <spinlock_check+0xf5>
  103d0b:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  103d0e:	8b 4d e0             	mov    0xffffffe0(%ebp),%ecx
  103d11:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  103d18:	8d 04 d5 00 00 00 00 	lea    0x0(,%edx,8),%eax
  103d1f:	29 d0                	sub    %edx,%eax
  103d21:	01 c8                	add    %ecx,%eax
  103d23:	83 c0 0c             	add    $0xc,%eax
  103d26:	8b 00                	mov    (%eax),%eax
  103d28:	85 c0                	test   %eax,%eax
  103d2a:	74 24                	je     103d50 <spinlock_check+0xf1>
  103d2c:	c7 44 24 0c 04 c9 10 	movl   $0x10c904,0xc(%esp)
  103d33:	00 
  103d34:	c7 44 24 08 a3 c8 10 	movl   $0x10c8a3,0x8(%esp)
  103d3b:	00 
  103d3c:	c7 44 24 04 53 00 00 	movl   $0x53,0x4(%esp)
  103d43:	00 
  103d44:	c7 04 24 7d c8 10 00 	movl   $0x10c87d,(%esp)
  103d4b:	e8 e8 cb ff ff       	call   100938 <debug_panic>
  103d50:	83 45 ec 01          	addl   $0x1,0xffffffec(%ebp)
  103d54:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  103d57:	3b 45 e4             	cmp    0xffffffe4(%ebp),%eax
  103d5a:	7c af                	jl     103d0b <spinlock_check+0xac>
	// Make sure that all locks have the correct debug info.
	for(i=0;i<NUMLOCKS;i++) assert(locks[i].file==file);
  103d5c:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  103d63:	eb 4a                	jmp    103daf <spinlock_check+0x150>
  103d65:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  103d68:	8b 4d e0             	mov    0xffffffe0(%ebp),%ecx
  103d6b:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  103d72:	8d 04 d5 00 00 00 00 	lea    0x0(,%edx,8),%eax
  103d79:	29 d0                	sub    %edx,%eax
  103d7b:	01 c8                	add    %ecx,%eax
  103d7d:	83 c0 04             	add    $0x4,%eax
  103d80:	8b 00                	mov    (%eax),%eax
  103d82:	3b 45 f8             	cmp    0xfffffff8(%ebp),%eax
  103d85:	74 24                	je     103dab <spinlock_check+0x14c>
  103d87:	c7 44 24 0c 17 c9 10 	movl   $0x10c917,0xc(%esp)
  103d8e:	00 
  103d8f:	c7 44 24 08 a3 c8 10 	movl   $0x10c8a3,0x8(%esp)
  103d96:	00 
  103d97:	c7 44 24 04 55 00 00 	movl   $0x55,0x4(%esp)
  103d9e:	00 
  103d9f:	c7 04 24 7d c8 10 00 	movl   $0x10c87d,(%esp)
  103da6:	e8 8d cb ff ff       	call   100938 <debug_panic>
  103dab:	83 45 ec 01          	addl   $0x1,0xffffffec(%ebp)
  103daf:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  103db2:	3b 45 e4             	cmp    0xffffffe4(%ebp),%eax
  103db5:	7c ae                	jl     103d65 <spinlock_check+0x106>

	for (run=0;run<NUMRUNS;run++) 
  103db7:	c7 45 f4 00 00 00 00 	movl   $0x0,0xfffffff4(%ebp)
  103dbe:	e9 17 03 00 00       	jmp    1040da <spinlock_check+0x47b>
	{
		// Lock all locks
		for(i=0;i<NUMLOCKS;i++)
  103dc3:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  103dca:	eb 2c                	jmp    103df8 <spinlock_check+0x199>
			spinlock_godeep(i, &locks[i]);
  103dcc:	8b 4d e0             	mov    0xffffffe0(%ebp),%ecx
  103dcf:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  103dd2:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  103dd9:	8d 04 d5 00 00 00 00 	lea    0x0(,%edx,8),%eax
  103de0:	29 d0                	sub    %edx,%eax
  103de2:	8d 04 01             	lea    (%ecx,%eax,1),%eax
  103de5:	89 44 24 04          	mov    %eax,0x4(%esp)
  103de9:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  103dec:	89 04 24             	mov    %eax,(%esp)
  103def:	e8 23 fe ff ff       	call   103c17 <spinlock_godeep>
  103df4:	83 45 ec 01          	addl   $0x1,0xffffffec(%ebp)
  103df8:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  103dfb:	3b 45 e4             	cmp    0xffffffe4(%ebp),%eax
  103dfe:	7c cc                	jl     103dcc <spinlock_check+0x16d>

		// Make sure that all locks have the right CPU
		for(i=0;i<NUMLOCKS;i++)
  103e00:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  103e07:	eb 4e                	jmp    103e57 <spinlock_check+0x1f8>
			assert(locks[i].cpu == cpu_cur());
  103e09:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  103e0c:	8b 4d e0             	mov    0xffffffe0(%ebp),%ecx
  103e0f:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  103e16:	8d 04 d5 00 00 00 00 	lea    0x0(,%edx,8),%eax
  103e1d:	29 d0                	sub    %edx,%eax
  103e1f:	01 c8                	add    %ecx,%eax
  103e21:	83 c0 0c             	add    $0xc,%eax
  103e24:	8b 18                	mov    (%eax),%ebx
  103e26:	e8 07 fd ff ff       	call   103b32 <cpu_cur>
  103e2b:	39 c3                	cmp    %eax,%ebx
  103e2d:	74 24                	je     103e53 <spinlock_check+0x1f4>
  103e2f:	c7 44 24 0c 2b c9 10 	movl   $0x10c92b,0xc(%esp)
  103e36:	00 
  103e37:	c7 44 24 08 a3 c8 10 	movl   $0x10c8a3,0x8(%esp)
  103e3e:	00 
  103e3f:	c7 44 24 04 5f 00 00 	movl   $0x5f,0x4(%esp)
  103e46:	00 
  103e47:	c7 04 24 7d c8 10 00 	movl   $0x10c87d,(%esp)
  103e4e:	e8 e5 ca ff ff       	call   100938 <debug_panic>
  103e53:	83 45 ec 01          	addl   $0x1,0xffffffec(%ebp)
  103e57:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  103e5a:	3b 45 e4             	cmp    0xffffffe4(%ebp),%eax
  103e5d:	7c aa                	jl     103e09 <spinlock_check+0x1aa>
		// Make sure that all locks have holding correctly implemented.
		for(i=0;i<NUMLOCKS;i++)
  103e5f:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  103e66:	eb 4d                	jmp    103eb5 <spinlock_check+0x256>
			assert(spinlock_holding(&locks[i]) != 0);
  103e68:	8b 4d e0             	mov    0xffffffe0(%ebp),%ecx
  103e6b:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  103e6e:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  103e75:	8d 04 d5 00 00 00 00 	lea    0x0(,%edx,8),%eax
  103e7c:	29 d0                	sub    %edx,%eax
  103e7e:	8d 04 01             	lea    (%ecx,%eax,1),%eax
  103e81:	89 04 24             	mov    %eax,(%esp)
  103e84:	e8 56 fd ff ff       	call   103bdf <spinlock_holding>
  103e89:	85 c0                	test   %eax,%eax
  103e8b:	75 24                	jne    103eb1 <spinlock_check+0x252>
  103e8d:	c7 44 24 0c 48 c9 10 	movl   $0x10c948,0xc(%esp)
  103e94:	00 
  103e95:	c7 44 24 08 a3 c8 10 	movl   $0x10c8a3,0x8(%esp)
  103e9c:	00 
  103e9d:	c7 44 24 04 62 00 00 	movl   $0x62,0x4(%esp)
  103ea4:	00 
  103ea5:	c7 04 24 7d c8 10 00 	movl   $0x10c87d,(%esp)
  103eac:	e8 87 ca ff ff       	call   100938 <debug_panic>
  103eb1:	83 45 ec 01          	addl   $0x1,0xffffffec(%ebp)
  103eb5:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  103eb8:	3b 45 e4             	cmp    0xffffffe4(%ebp),%eax
  103ebb:	7c ab                	jl     103e68 <spinlock_check+0x209>
		// Make sure that top i frames are somewhere in godeep.
		for(i=0;i<NUMLOCKS;i++) 
  103ebd:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  103ec4:	e9 b9 00 00 00       	jmp    103f82 <spinlock_check+0x323>
		{
			for(j=0; j<=i && j < DEBUG_TRACEFRAMES ; j++) 
  103ec9:	c7 45 f0 00 00 00 00 	movl   $0x0,0xfffffff0(%ebp)
  103ed0:	e9 97 00 00 00       	jmp    103f6c <spinlock_check+0x30d>
			{
				assert(locks[i].eips[j] >=
  103ed5:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  103ed8:	8b 4d f0             	mov    0xfffffff0(%ebp),%ecx
  103edb:	8b 5d e0             	mov    0xffffffe0(%ebp),%ebx
  103ede:	8d 14 00             	lea    (%eax,%eax,1),%edx
  103ee1:	8d 04 d5 00 00 00 00 	lea    0x0(,%edx,8),%eax
  103ee8:	29 d0                	sub    %edx,%eax
  103eea:	01 c8                	add    %ecx,%eax
  103eec:	8b 54 83 10          	mov    0x10(%ebx,%eax,4),%edx
  103ef0:	b8 17 3c 10 00       	mov    $0x103c17,%eax
  103ef5:	39 c2                	cmp    %eax,%edx
  103ef7:	73 24                	jae    103f1d <spinlock_check+0x2be>
  103ef9:	c7 44 24 0c 6c c9 10 	movl   $0x10c96c,0xc(%esp)
  103f00:	00 
  103f01:	c7 44 24 08 a3 c8 10 	movl   $0x10c8a3,0x8(%esp)
  103f08:	00 
  103f09:	c7 44 24 04 69 00 00 	movl   $0x69,0x4(%esp)
  103f10:	00 
  103f11:	c7 04 24 7d c8 10 00 	movl   $0x10c87d,(%esp)
  103f18:	e8 1b ca ff ff       	call   100938 <debug_panic>
					(uint32_t)spinlock_godeep);
				assert(locks[i].eips[j] <
  103f1d:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  103f20:	8b 4d f0             	mov    0xfffffff0(%ebp),%ecx
  103f23:	8b 5d e0             	mov    0xffffffe0(%ebp),%ebx
  103f26:	8d 14 00             	lea    (%eax,%eax,1),%edx
  103f29:	8d 04 d5 00 00 00 00 	lea    0x0(,%edx,8),%eax
  103f30:	29 d0                	sub    %edx,%eax
  103f32:	01 c8                	add    %ecx,%eax
  103f34:	8b 54 83 10          	mov    0x10(%ebx,%eax,4),%edx
  103f38:	b8 17 3c 10 00       	mov    $0x103c17,%eax
  103f3d:	83 c0 64             	add    $0x64,%eax
  103f40:	39 c2                	cmp    %eax,%edx
  103f42:	72 24                	jb     103f68 <spinlock_check+0x309>
  103f44:	c7 44 24 0c 9c c9 10 	movl   $0x10c99c,0xc(%esp)
  103f4b:	00 
  103f4c:	c7 44 24 08 a3 c8 10 	movl   $0x10c8a3,0x8(%esp)
  103f53:	00 
  103f54:	c7 44 24 04 6b 00 00 	movl   $0x6b,0x4(%esp)
  103f5b:	00 
  103f5c:	c7 04 24 7d c8 10 00 	movl   $0x10c87d,(%esp)
  103f63:	e8 d0 c9 ff ff       	call   100938 <debug_panic>
  103f68:	83 45 f0 01          	addl   $0x1,0xfffffff0(%ebp)
  103f6c:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  103f6f:	3b 45 ec             	cmp    0xffffffec(%ebp),%eax
  103f72:	7f 0a                	jg     103f7e <spinlock_check+0x31f>
  103f74:	83 7d f0 09          	cmpl   $0x9,0xfffffff0(%ebp)
  103f78:	0f 8e 57 ff ff ff    	jle    103ed5 <spinlock_check+0x276>
  103f7e:	83 45 ec 01          	addl   $0x1,0xffffffec(%ebp)
  103f82:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  103f85:	3b 45 e4             	cmp    0xffffffe4(%ebp),%eax
  103f88:	0f 8c 3b ff ff ff    	jl     103ec9 <spinlock_check+0x26a>
					(uint32_t)spinlock_godeep+100);
			}
		}

		// Release all locks
		for(i=0;i<NUMLOCKS;i++) spinlock_release(&locks[i]);
  103f8e:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  103f95:	eb 25                	jmp    103fbc <spinlock_check+0x35d>
  103f97:	8b 4d e0             	mov    0xffffffe0(%ebp),%ecx
  103f9a:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  103f9d:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  103fa4:	8d 04 d5 00 00 00 00 	lea    0x0(,%edx,8),%eax
  103fab:	29 d0                	sub    %edx,%eax
  103fad:	8d 04 01             	lea    (%ecx,%eax,1),%eax
  103fb0:	89 04 24             	mov    %eax,(%esp)
  103fb3:	e8 cd fb ff ff       	call   103b85 <spinlock_release>
  103fb8:	83 45 ec 01          	addl   $0x1,0xffffffec(%ebp)
  103fbc:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  103fbf:	3b 45 e4             	cmp    0xffffffe4(%ebp),%eax
  103fc2:	7c d3                	jl     103f97 <spinlock_check+0x338>
		// Make sure that the CPU has been cleared
		for(i=0;i<NUMLOCKS;i++) assert(locks[i].cpu == NULL);
  103fc4:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  103fcb:	eb 49                	jmp    104016 <spinlock_check+0x3b7>
  103fcd:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  103fd0:	8b 4d e0             	mov    0xffffffe0(%ebp),%ecx
  103fd3:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  103fda:	8d 04 d5 00 00 00 00 	lea    0x0(,%edx,8),%eax
  103fe1:	29 d0                	sub    %edx,%eax
  103fe3:	01 c8                	add    %ecx,%eax
  103fe5:	83 c0 0c             	add    $0xc,%eax
  103fe8:	8b 00                	mov    (%eax),%eax
  103fea:	85 c0                	test   %eax,%eax
  103fec:	74 24                	je     104012 <spinlock_check+0x3b3>
  103fee:	c7 44 24 0c cd c9 10 	movl   $0x10c9cd,0xc(%esp)
  103ff5:	00 
  103ff6:	c7 44 24 08 a3 c8 10 	movl   $0x10c8a3,0x8(%esp)
  103ffd:	00 
  103ffe:	c7 44 24 04 72 00 00 	movl   $0x72,0x4(%esp)
  104005:	00 
  104006:	c7 04 24 7d c8 10 00 	movl   $0x10c87d,(%esp)
  10400d:	e8 26 c9 ff ff       	call   100938 <debug_panic>
  104012:	83 45 ec 01          	addl   $0x1,0xffffffec(%ebp)
  104016:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  104019:	3b 45 e4             	cmp    0xffffffe4(%ebp),%eax
  10401c:	7c af                	jl     103fcd <spinlock_check+0x36e>
		for(i=0;i<NUMLOCKS;i++) assert(locks[i].eips[0]==0);
  10401e:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  104025:	eb 49                	jmp    104070 <spinlock_check+0x411>
  104027:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  10402a:	8b 4d e0             	mov    0xffffffe0(%ebp),%ecx
  10402d:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  104034:	8d 04 d5 00 00 00 00 	lea    0x0(,%edx,8),%eax
  10403b:	29 d0                	sub    %edx,%eax
  10403d:	01 c8                	add    %ecx,%eax
  10403f:	83 c0 10             	add    $0x10,%eax
  104042:	8b 00                	mov    (%eax),%eax
  104044:	85 c0                	test   %eax,%eax
  104046:	74 24                	je     10406c <spinlock_check+0x40d>
  104048:	c7 44 24 0c e2 c9 10 	movl   $0x10c9e2,0xc(%esp)
  10404f:	00 
  104050:	c7 44 24 08 a3 c8 10 	movl   $0x10c8a3,0x8(%esp)
  104057:	00 
  104058:	c7 44 24 04 73 00 00 	movl   $0x73,0x4(%esp)
  10405f:	00 
  104060:	c7 04 24 7d c8 10 00 	movl   $0x10c87d,(%esp)
  104067:	e8 cc c8 ff ff       	call   100938 <debug_panic>
  10406c:	83 45 ec 01          	addl   $0x1,0xffffffec(%ebp)
  104070:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  104073:	3b 45 e4             	cmp    0xffffffe4(%ebp),%eax
  104076:	7c af                	jl     104027 <spinlock_check+0x3c8>
		// Make sure that all locks have holding correctly implemented.
		for(i=0;i<NUMLOCKS;i++) assert(spinlock_holding(&locks[i]) == 0);
  104078:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  10407f:	eb 4d                	jmp    1040ce <spinlock_check+0x46f>
  104081:	8b 4d e0             	mov    0xffffffe0(%ebp),%ecx
  104084:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  104087:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  10408e:	8d 04 d5 00 00 00 00 	lea    0x0(,%edx,8),%eax
  104095:	29 d0                	sub    %edx,%eax
  104097:	8d 04 01             	lea    (%ecx,%eax,1),%eax
  10409a:	89 04 24             	mov    %eax,(%esp)
  10409d:	e8 3d fb ff ff       	call   103bdf <spinlock_holding>
  1040a2:	85 c0                	test   %eax,%eax
  1040a4:	74 24                	je     1040ca <spinlock_check+0x46b>
  1040a6:	c7 44 24 0c f8 c9 10 	movl   $0x10c9f8,0xc(%esp)
  1040ad:	00 
  1040ae:	c7 44 24 08 a3 c8 10 	movl   $0x10c8a3,0x8(%esp)
  1040b5:	00 
  1040b6:	c7 44 24 04 75 00 00 	movl   $0x75,0x4(%esp)
  1040bd:	00 
  1040be:	c7 04 24 7d c8 10 00 	movl   $0x10c87d,(%esp)
  1040c5:	e8 6e c8 ff ff       	call   100938 <debug_panic>
  1040ca:	83 45 ec 01          	addl   $0x1,0xffffffec(%ebp)
  1040ce:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  1040d1:	3b 45 e4             	cmp    0xffffffe4(%ebp),%eax
  1040d4:	7c ab                	jl     104081 <spinlock_check+0x422>
  1040d6:	83 45 f4 01          	addl   $0x1,0xfffffff4(%ebp)
  1040da:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  1040dd:	3b 45 e8             	cmp    0xffffffe8(%ebp),%eax
  1040e0:	0f 8c dd fc ff ff    	jl     103dc3 <spinlock_check+0x164>
	}
	cprintf("spinlock_check() succeeded!\n");
  1040e6:	c7 04 24 19 ca 10 00 	movl   $0x10ca19,(%esp)
  1040ed:	e8 93 73 00 00       	call   10b485 <cprintf>
  1040f2:	8b 65 d8             	mov    0xffffffd8(%ebp),%esp
}
  1040f5:	8b 5d fc             	mov    0xfffffffc(%ebp),%ebx
  1040f8:	c9                   	leave  
  1040f9:	c3                   	ret    
  1040fa:	90                   	nop    
  1040fb:	90                   	nop    

001040fc <proc_init>:
static proc **readytail;

void
proc_init(void)
{
  1040fc:	55                   	push   %ebp
  1040fd:	89 e5                	mov    %esp,%ebp
  1040ff:	83 ec 18             	sub    $0x18,%esp
	if (!cpu_onboot())
  104102:	e8 2c 00 00 00       	call   104133 <cpu_onboot>
  104107:	85 c0                	test   %eax,%eax
  104109:	74 26                	je     104131 <proc_init+0x35>
		return;

	// your module initialization code here
  spinlock_init(&readylock);
  10410b:	c7 44 24 08 26 00 00 	movl   $0x26,0x8(%esp)
  104112:	00 
  104113:	c7 44 24 04 38 ca 10 	movl   $0x10ca38,0x4(%esp)
  10411a:	00 
  10411b:	c7 04 24 40 aa 17 00 	movl   $0x17aa40,(%esp)
  104122:	e8 39 f9 ff ff       	call   103a60 <spinlock_init_>
  readytail = &readyhead;
  104127:	c7 05 7c aa 17 00 78 	movl   $0x17aa78,0x17aa7c
  10412e:	aa 17 00 
}
  104131:	c9                   	leave  
  104132:	c3                   	ret    

00104133 <cpu_onboot>:
}

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  104133:	55                   	push   %ebp
  104134:	89 e5                	mov    %esp,%ebp
  104136:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  104139:	e8 0d 00 00 00       	call   10414b <cpu_cur>
  10413e:	3d 00 e0 10 00       	cmp    $0x10e000,%eax
  104143:	0f 94 c0             	sete   %al
  104146:	0f b6 c0             	movzbl %al,%eax
}
  104149:	c9                   	leave  
  10414a:	c3                   	ret    

0010414b <cpu_cur>:
  10414b:	55                   	push   %ebp
  10414c:	89 e5                	mov    %esp,%ebp
  10414e:	83 ec 28             	sub    $0x28,%esp
static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  104151:	89 65 fc             	mov    %esp,0xfffffffc(%ebp)
        return esp;
  104154:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  104157:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  10415a:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10415d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  104162:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	assert(c->magic == CPU_MAGIC);
  104165:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  104168:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  10416e:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  104173:	74 24                	je     104199 <cpu_cur+0x4e>
  104175:	c7 44 24 0c 44 ca 10 	movl   $0x10ca44,0xc(%esp)
  10417c:	00 
  10417d:	c7 44 24 08 5a ca 10 	movl   $0x10ca5a,0x8(%esp)
  104184:	00 
  104185:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  10418c:	00 
  10418d:	c7 04 24 6f ca 10 00 	movl   $0x10ca6f,(%esp)
  104194:	e8 9f c7 ff ff       	call   100938 <debug_panic>
	return c;
  104199:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
}
  10419c:	c9                   	leave  
  10419d:	c3                   	ret    

0010419e <proc_alloc>:

// Allocate and initialize a new proc as child 'cn' of parent 'p'.
// Returns NULL if no physical memory available.
proc *
proc_alloc(proc *p, uint32_t cn)
{
  10419e:	55                   	push   %ebp
  10419f:	89 e5                	mov    %esp,%ebp
  1041a1:	83 ec 28             	sub    $0x28,%esp
	pageinfo *pi = mem_alloc();
  1041a4:	e8 72 ce ff ff       	call   10101b <mem_alloc>
  1041a9:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	if (!pi)
  1041ac:	83 7d f4 00          	cmpl   $0x0,0xfffffff4(%ebp)
  1041b0:	75 0c                	jne    1041be <proc_alloc+0x20>
		return NULL;
  1041b2:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  1041b9:	e9 14 02 00 00       	jmp    1043d2 <proc_alloc+0x234>
  1041be:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  1041c1:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
// Atomically increment the reference count on a page.
static gcc_inline void
mem_incref(pageinfo *pi)
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  1041c4:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  1041c9:	83 c0 08             	add    $0x8,%eax
  1041cc:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  1041cf:	73 17                	jae    1041e8 <proc_alloc+0x4a>
  1041d1:	a1 84 ed 17 00       	mov    0x17ed84,%eax
  1041d6:	c1 e0 03             	shl    $0x3,%eax
  1041d9:	89 c2                	mov    %eax,%edx
  1041db:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  1041e0:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1041e3:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  1041e6:	77 24                	ja     10420c <proc_alloc+0x6e>
  1041e8:	c7 44 24 0c 7c ca 10 	movl   $0x10ca7c,0xc(%esp)
  1041ef:	00 
  1041f0:	c7 44 24 08 5a ca 10 	movl   $0x10ca5a,0x8(%esp)
  1041f7:	00 
  1041f8:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
  1041ff:	00 
  104200:	c7 04 24 b3 ca 10 00 	movl   $0x10cab3,(%esp)
  104207:	e8 2c c7 ff ff       	call   100938 <debug_panic>
	assert(pi != mem_ptr2pi(pmap_zero));	// Don't alloc/free zero page!
  10420c:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  104212:	b8 00 10 18 00       	mov    $0x181000,%eax
  104217:	c1 e8 0c             	shr    $0xc,%eax
  10421a:	c1 e0 03             	shl    $0x3,%eax
  10421d:	8d 04 02             	lea    (%edx,%eax,1),%eax
  104220:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  104223:	75 24                	jne    104249 <proc_alloc+0xab>
  104225:	c7 44 24 0c c0 ca 10 	movl   $0x10cac0,0xc(%esp)
  10422c:	00 
  10422d:	c7 44 24 08 5a ca 10 	movl   $0x10ca5a,0x8(%esp)
  104234:	00 
  104235:	c7 44 24 04 59 00 00 	movl   $0x59,0x4(%esp)
  10423c:	00 
  10423d:	c7 04 24 b3 ca 10 00 	movl   $0x10cab3,(%esp)
  104244:	e8 ef c6 ff ff       	call   100938 <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  104249:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  10424f:	b8 0c 00 10 00       	mov    $0x10000c,%eax
  104254:	c1 e8 0c             	shr    $0xc,%eax
  104257:	c1 e0 03             	shl    $0x3,%eax
  10425a:	8d 04 02             	lea    (%edx,%eax,1),%eax
  10425d:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  104260:	77 40                	ja     1042a2 <proc_alloc+0x104>
  104262:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  104268:	b8 08 20 18 00       	mov    $0x182008,%eax
  10426d:	83 e8 01             	sub    $0x1,%eax
  104270:	c1 e8 0c             	shr    $0xc,%eax
  104273:	c1 e0 03             	shl    $0x3,%eax
  104276:	8d 04 02             	lea    (%edx,%eax,1),%eax
  104279:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  10427c:	72 24                	jb     1042a2 <proc_alloc+0x104>
  10427e:	c7 44 24 0c dc ca 10 	movl   $0x10cadc,0xc(%esp)
  104285:	00 
  104286:	c7 44 24 08 5a ca 10 	movl   $0x10ca5a,0x8(%esp)
  10428d:	00 
  10428e:	c7 44 24 04 5a 00 00 	movl   $0x5a,0x4(%esp)
  104295:	00 
  104296:	c7 04 24 b3 ca 10 00 	movl   $0x10cab3,(%esp)
  10429d:	e8 96 c6 ff ff       	call   100938 <debug_panic>

	lockadd(&pi->refcount, 1);
  1042a2:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  1042a5:	83 c0 04             	add    $0x4,%eax
  1042a8:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  1042af:	00 
  1042b0:	89 04 24             	mov    %eax,(%esp)
  1042b3:	e8 1f 01 00 00       	call   1043d7 <lockadd>
	mem_incref(pi);

	proc *cp = (proc*)mem_pi2ptr(pi);
  1042b8:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  1042bb:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  1042c0:	89 d1                	mov    %edx,%ecx
  1042c2:	29 c1                	sub    %eax,%ecx
  1042c4:	89 c8                	mov    %ecx,%eax
  1042c6:	c1 e0 09             	shl    $0x9,%eax
  1042c9:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
	memset(cp, 0, sizeof(proc));
  1042cc:	c7 44 24 08 b0 06 00 	movl   $0x6b0,0x8(%esp)
  1042d3:	00 
  1042d4:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1042db:	00 
  1042dc:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1042df:	89 04 24             	mov    %eax,(%esp)
  1042e2:	e8 22 75 00 00       	call   10b809 <memset>
	spinlock_init(&cp->lock);
  1042e7:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1042ea:	c7 44 24 08 36 00 00 	movl   $0x36,0x8(%esp)
  1042f1:	00 
  1042f2:	c7 44 24 04 38 ca 10 	movl   $0x10ca38,0x4(%esp)
  1042f9:	00 
  1042fa:	89 04 24             	mov    %eax,(%esp)
  1042fd:	e8 5e f7 ff ff       	call   103a60 <spinlock_init_>
	cp->parent = p;
  104302:	8b 55 f8             	mov    0xfffffff8(%ebp),%edx
  104305:	8b 45 08             	mov    0x8(%ebp),%eax
  104308:	89 42 38             	mov    %eax,0x38(%edx)
	cp->state = PROC_STOP;
  10430b:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10430e:	c7 80 3c 04 00 00 00 	movl   $0x0,0x43c(%eax)
  104315:	00 00 00 

	// Integer register state
	cp->sv.tf.ds = CPU_GDT_UDATA | 3;
  104318:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10431b:	66 c7 80 7c 04 00 00 	movw   $0x23,0x47c(%eax)
  104322:	23 00 
	cp->sv.tf.es = CPU_GDT_UDATA | 3;
  104324:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  104327:	66 c7 80 78 04 00 00 	movw   $0x23,0x478(%eax)
  10432e:	23 00 
	cp->sv.tf.cs = CPU_GDT_UCODE | 3;
  104330:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  104333:	66 c7 80 8c 04 00 00 	movw   $0x1b,0x48c(%eax)
  10433a:	1b 00 
	cp->sv.tf.ss = CPU_GDT_UDATA | 3;
  10433c:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10433f:	66 c7 80 98 04 00 00 	movw   $0x23,0x498(%eax)
  104346:	23 00 

cp->pdir = pmap_newpdir();
  104348:	e8 29 19 00 00       	call   105c76 <pmap_newpdir>
  10434d:	89 c2                	mov    %eax,%edx
  10434f:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  104352:	89 90 a0 06 00 00    	mov    %edx,0x6a0(%eax)
cp->rpdir = pmap_newpdir();
  104358:	e8 19 19 00 00       	call   105c76 <pmap_newpdir>
  10435d:	89 c2                	mov    %eax,%edx
  10435f:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  104362:	89 90 a4 06 00 00    	mov    %edx,0x6a4(%eax)
if (!cp->pdir || !cp->rpdir){
  104368:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10436b:	8b 80 a0 06 00 00    	mov    0x6a0(%eax),%eax
  104371:	85 c0                	test   %eax,%eax
  104373:	74 0d                	je     104382 <proc_alloc+0x1e4>
  104375:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  104378:	8b 80 a4 06 00 00    	mov    0x6a4(%eax),%eax
  10437e:	85 c0                	test   %eax,%eax
  104380:	75 37                	jne    1043b9 <proc_alloc+0x21b>
if(cp->pdir) pmap_freepdir(mem_ptr2pi(cp->pdir));
  104382:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  104385:	8b 80 a0 06 00 00    	mov    0x6a0(%eax),%eax
  10438b:	85 c0                	test   %eax,%eax
  10438d:	74 21                	je     1043b0 <proc_alloc+0x212>
  10438f:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  104392:	8b 80 a0 06 00 00    	mov    0x6a0(%eax),%eax
  104398:	c1 e8 0c             	shr    $0xc,%eax
  10439b:	c1 e0 03             	shl    $0x3,%eax
  10439e:	89 c2                	mov    %eax,%edx
  1043a0:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  1043a5:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1043a8:	89 04 24             	mov    %eax,(%esp)
  1043ab:	e8 2b 1a 00 00       	call   105ddb <pmap_freepdir>
return NULL;
  1043b0:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  1043b7:	eb 19                	jmp    1043d2 <proc_alloc+0x234>
}
	if (p)
  1043b9:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  1043bd:	74 0d                	je     1043cc <proc_alloc+0x22e>
		p->child[cn] = cp;
  1043bf:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  1043c2:	8b 55 08             	mov    0x8(%ebp),%edx
  1043c5:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1043c8:	89 44 8a 3c          	mov    %eax,0x3c(%edx,%ecx,4)
	return cp;
  1043cc:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1043cf:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  1043d2:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
}
  1043d5:	c9                   	leave  
  1043d6:	c3                   	ret    

001043d7 <lockadd>:

// Atomically add incr to *addr.
static inline void
lockadd(volatile int32_t *addr, int32_t incr)
{
  1043d7:	55                   	push   %ebp
  1043d8:	89 e5                	mov    %esp,%ebp
	asm volatile("lock; addl %1,%0" : "+m" (*addr) : "r" (incr) : "cc");
  1043da:	8b 4d 08             	mov    0x8(%ebp),%ecx
  1043dd:	8b 55 0c             	mov    0xc(%ebp),%edx
  1043e0:	8b 45 08             	mov    0x8(%ebp),%eax
  1043e3:	f0 01 11             	lock add %edx,(%ecx)
}
  1043e6:	5d                   	pop    %ebp
  1043e7:	c3                   	ret    

001043e8 <proc_ready>:

// Put process p in the ready state and add it to the ready queue.
void
proc_ready(proc *p)
{
  1043e8:	55                   	push   %ebp
  1043e9:	89 e5                	mov    %esp,%ebp
  1043eb:	83 ec 08             	sub    $0x8,%esp
//	panic("proc_ready not implemented");
  spinlock_acquire(&readylock);
  1043ee:	c7 04 24 40 aa 17 00 	movl   $0x17aa40,(%esp)
  1043f5:	e8 90 f6 ff ff       	call   103a8a <spinlock_acquire>

  p->state = PROC_READY;
  1043fa:	8b 45 08             	mov    0x8(%ebp),%eax
  1043fd:	c7 80 3c 04 00 00 01 	movl   $0x1,0x43c(%eax)
  104404:	00 00 00 
  p->readynext = NULL;
  104407:	8b 45 08             	mov    0x8(%ebp),%eax
  10440a:	c7 80 40 04 00 00 00 	movl   $0x0,0x440(%eax)
  104411:	00 00 00 
  *readytail = p;
  104414:	8b 15 7c aa 17 00    	mov    0x17aa7c,%edx
  10441a:	8b 45 08             	mov    0x8(%ebp),%eax
  10441d:	89 02                	mov    %eax,(%edx)
  readytail = &p->readynext;
  10441f:	8b 45 08             	mov    0x8(%ebp),%eax
  104422:	05 40 04 00 00       	add    $0x440,%eax
  104427:	a3 7c aa 17 00       	mov    %eax,0x17aa7c

  spinlock_release(&readylock);
  10442c:	c7 04 24 40 aa 17 00 	movl   $0x17aa40,(%esp)
  104433:	e8 4d f7 ff ff       	call   103b85 <spinlock_release>
}
  104438:	c9                   	leave  
  104439:	c3                   	ret    

0010443a <proc_save>:

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
  10443a:	55                   	push   %ebp
  10443b:	89 e5                	mov    %esp,%ebp
  10443d:	83 ec 18             	sub    $0x18,%esp
    assert(p == proc_cur());
  104440:	e8 06 fd ff ff       	call   10414b <cpu_cur>
  104445:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  10444b:	3b 45 08             	cmp    0x8(%ebp),%eax
  10444e:	74 24                	je     104474 <proc_save+0x3a>
  104450:	c7 44 24 0c 0d cb 10 	movl   $0x10cb0d,0xc(%esp)
  104457:	00 
  104458:	c7 44 24 08 5a ca 10 	movl   $0x10ca5a,0x8(%esp)
  10445f:	00 
  104460:	c7 44 24 04 64 00 00 	movl   $0x64,0x4(%esp)
  104467:	00 
  104468:	c7 04 24 38 ca 10 00 	movl   $0x10ca38,(%esp)
  10446f:	e8 c4 c4 ff ff       	call   100938 <debug_panic>

    if (tf != &p->sv.tf)
  104474:	8b 45 08             	mov    0x8(%ebp),%eax
  104477:	05 50 04 00 00       	add    $0x450,%eax
  10447c:	3b 45 0c             	cmp    0xc(%ebp),%eax
  10447f:	74 21                	je     1044a2 <proc_save+0x68>
      p->sv.tf = *tf; // integer register state
  104481:	8b 45 08             	mov    0x8(%ebp),%eax
  104484:	8b 55 0c             	mov    0xc(%ebp),%edx
  104487:	8d 88 50 04 00 00    	lea    0x450(%eax),%ecx
  10448d:	b8 4c 00 00 00       	mov    $0x4c,%eax
  104492:	89 44 24 08          	mov    %eax,0x8(%esp)
  104496:	89 54 24 04          	mov    %edx,0x4(%esp)
  10449a:	89 0c 24             	mov    %ecx,(%esp)
  10449d:	e8 a6 74 00 00       	call   10b948 <memcpy>
    if (entry == 0)
  1044a2:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  1044a6:	75 15                	jne    1044bd <proc_save+0x83>
      p->sv.tf.eip -= 2;  // back up to replay INT instruction
  1044a8:	8b 45 08             	mov    0x8(%ebp),%eax
  1044ab:	8b 80 88 04 00 00    	mov    0x488(%eax),%eax
  1044b1:	8d 50 fe             	lea    0xfffffffe(%eax),%edx
  1044b4:	8b 45 08             	mov    0x8(%ebp),%eax
  1044b7:	89 90 88 04 00 00    	mov    %edx,0x488(%eax)
}
  1044bd:	c9                   	leave  
  1044be:	c3                   	ret    

001044bf <proc_wait>:

// Go to sleep waiting for a given child process to finish running.
// Parent process 'p' must be running and locked on entry.
// The supplied trapframe represents p's register state on syscall entry.
void gcc_noreturn
proc_wait(proc *p, proc *cp, trapframe *tf)
{
  1044bf:	55                   	push   %ebp
  1044c0:	89 e5                	mov    %esp,%ebp
  1044c2:	83 ec 18             	sub    $0x18,%esp
	//panic("proc_wait not implemented");
  assert(spinlock_holding(&p->lock));
  1044c5:	8b 45 08             	mov    0x8(%ebp),%eax
  1044c8:	89 04 24             	mov    %eax,(%esp)
  1044cb:	e8 0f f7 ff ff       	call   103bdf <spinlock_holding>
  1044d0:	85 c0                	test   %eax,%eax
  1044d2:	75 24                	jne    1044f8 <proc_wait+0x39>
  1044d4:	c7 44 24 0c 1d cb 10 	movl   $0x10cb1d,0xc(%esp)
  1044db:	00 
  1044dc:	c7 44 24 08 5a ca 10 	movl   $0x10ca5a,0x8(%esp)
  1044e3:	00 
  1044e4:	c7 44 24 04 73 00 00 	movl   $0x73,0x4(%esp)
  1044eb:	00 
  1044ec:	c7 04 24 38 ca 10 00 	movl   $0x10ca38,(%esp)
  1044f3:	e8 40 c4 ff ff       	call   100938 <debug_panic>
  assert(cp && cp != &proc_null); // null proc is always stopped
  1044f8:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  1044fc:	74 09                	je     104507 <proc_wait+0x48>
  1044fe:	81 7d 0c 00 ee 17 00 	cmpl   $0x17ee00,0xc(%ebp)
  104505:	75 24                	jne    10452b <proc_wait+0x6c>
  104507:	c7 44 24 0c 38 cb 10 	movl   $0x10cb38,0xc(%esp)
  10450e:	00 
  10450f:	c7 44 24 08 5a ca 10 	movl   $0x10ca5a,0x8(%esp)
  104516:	00 
  104517:	c7 44 24 04 74 00 00 	movl   $0x74,0x4(%esp)
  10451e:	00 
  10451f:	c7 04 24 38 ca 10 00 	movl   $0x10ca38,(%esp)
  104526:	e8 0d c4 ff ff       	call   100938 <debug_panic>
  assert(cp->state != PROC_STOP);
  10452b:	8b 45 0c             	mov    0xc(%ebp),%eax
  10452e:	8b 80 3c 04 00 00    	mov    0x43c(%eax),%eax
  104534:	85 c0                	test   %eax,%eax
  104536:	75 24                	jne    10455c <proc_wait+0x9d>
  104538:	c7 44 24 0c 4f cb 10 	movl   $0x10cb4f,0xc(%esp)
  10453f:	00 
  104540:	c7 44 24 08 5a ca 10 	movl   $0x10ca5a,0x8(%esp)
  104547:	00 
  104548:	c7 44 24 04 75 00 00 	movl   $0x75,0x4(%esp)
  10454f:	00 
  104550:	c7 04 24 38 ca 10 00 	movl   $0x10ca38,(%esp)
  104557:	e8 dc c3 ff ff       	call   100938 <debug_panic>

  p->state = PROC_WAIT;
  10455c:	8b 45 08             	mov    0x8(%ebp),%eax
  10455f:	c7 80 3c 04 00 00 03 	movl   $0x3,0x43c(%eax)
  104566:	00 00 00 
  p->runcpu = NULL;
  104569:	8b 45 08             	mov    0x8(%ebp),%eax
  10456c:	c7 80 44 04 00 00 00 	movl   $0x0,0x444(%eax)
  104573:	00 00 00 
  p->waitchild = cp;  // remember what child we're waiting on
  104576:	8b 55 08             	mov    0x8(%ebp),%edx
  104579:	8b 45 0c             	mov    0xc(%ebp),%eax
  10457c:	89 82 48 04 00 00    	mov    %eax,0x448(%edx)
  proc_save(p, tf, 0);  // save process state before INT instruction
  104582:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  104589:	00 
  10458a:	8b 45 10             	mov    0x10(%ebp),%eax
  10458d:	89 44 24 04          	mov    %eax,0x4(%esp)
  104591:	8b 45 08             	mov    0x8(%ebp),%eax
  104594:	89 04 24             	mov    %eax,(%esp)
  104597:	e8 9e fe ff ff       	call   10443a <proc_save>

  spinlock_release(&p->lock);
  10459c:	8b 45 08             	mov    0x8(%ebp),%eax
  10459f:	89 04 24             	mov    %eax,(%esp)
  1045a2:	e8 de f5 ff ff       	call   103b85 <spinlock_release>

  proc_sched();
  1045a7:	e8 00 00 00 00       	call   1045ac <proc_sched>

001045ac <proc_sched>:
}

void gcc_noreturn
proc_sched(void)
{
  1045ac:	55                   	push   %ebp
  1045ad:	89 e5                	mov    %esp,%ebp
  1045af:	83 ec 28             	sub    $0x28,%esp
//	panic("proc_sched not implemented");
  cpu *c = cpu_cur();
  1045b2:	e8 94 fb ff ff       	call   10414b <cpu_cur>
  1045b7:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  spinlock_acquire(&readylock);
  1045ba:	c7 04 24 40 aa 17 00 	movl   $0x17aa40,(%esp)
  1045c1:	e8 c4 f4 ff ff       	call   103a8a <spinlock_acquire>
  while (!readyhead || cpu_disabled(c)) {
  1045c6:	eb 2a                	jmp    1045f2 <proc_sched+0x46>
    spinlock_release(&readylock);
  1045c8:	c7 04 24 40 aa 17 00 	movl   $0x17aa40,(%esp)
  1045cf:	e8 b1 f5 ff ff       	call   103b85 <spinlock_release>

    //cprintf("cpu %d waiting for work\n", cpu_cur()->id);
    while (!readyhead || cpu_disabled(c)) {  // spin-wait for work
  1045d4:	eb 07                	jmp    1045dd <proc_sched+0x31>
// Enable external device interrupts.
static gcc_inline void
sti(void)
{
	asm volatile("sti");
  1045d6:	fb                   	sti    
      sti(); // enable device interrupts briefly
      pause(); // let CPU know we're in a spin loop
  1045d7:	e8 ad 00 00 00       	call   104689 <pause>
// Disable external device interrupts.
static gcc_inline void
cli(void)
{
	asm volatile("cli");
  1045dc:	fa                   	cli    
  1045dd:	a1 78 aa 17 00       	mov    0x17aa78,%eax
  1045e2:	85 c0                	test   %eax,%eax
  1045e4:	74 f0                	je     1045d6 <proc_sched+0x2a>
      cli(); // disable interrupts again
    }
    //cprintf("cpu %d found work\n", cpu_cur()->id);

    spinlock_acquire(&readylock);
  1045e6:	c7 04 24 40 aa 17 00 	movl   $0x17aa40,(%esp)
  1045ed:	e8 98 f4 ff ff       	call   103a8a <spinlock_acquire>
  1045f2:	a1 78 aa 17 00       	mov    0x17aa78,%eax
  1045f7:	85 c0                	test   %eax,%eax
  1045f9:	74 cd                	je     1045c8 <proc_sched+0x1c>
    // now must recheck readyhead while holding readylock!
  }

  // Remove the next proc from the ready queue
  proc *p = readyhead;
  1045fb:	a1 78 aa 17 00       	mov    0x17aa78,%eax
  104600:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  readyhead = p->readynext;
  104603:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  104606:	8b 80 40 04 00 00    	mov    0x440(%eax),%eax
  10460c:	a3 78 aa 17 00       	mov    %eax,0x17aa78
  if (readytail == &p->readynext) {
  104611:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  104614:	81 c2 40 04 00 00    	add    $0x440,%edx
  10461a:	a1 7c aa 17 00       	mov    0x17aa7c,%eax
  10461f:	39 c2                	cmp    %eax,%edx
  104621:	75 37                	jne    10465a <proc_sched+0xae>
    assert(readyhead == NULL); // ready queue going empty
  104623:	a1 78 aa 17 00       	mov    0x17aa78,%eax
  104628:	85 c0                	test   %eax,%eax
  10462a:	74 24                	je     104650 <proc_sched+0xa4>
  10462c:	c7 44 24 0c 66 cb 10 	movl   $0x10cb66,0xc(%esp)
  104633:	00 
  104634:	c7 44 24 08 5a ca 10 	movl   $0x10ca5a,0x8(%esp)
  10463b:	00 
  10463c:	c7 44 24 04 9a 00 00 	movl   $0x9a,0x4(%esp)
  104643:	00 
  104644:	c7 04 24 38 ca 10 00 	movl   $0x10ca38,(%esp)
  10464b:	e8 e8 c2 ff ff       	call   100938 <debug_panic>
    readytail = &readyhead;
  104650:	c7 05 7c aa 17 00 78 	movl   $0x17aa78,0x17aa7c
  104657:	aa 17 00 
  }
  p->readynext = NULL;
  10465a:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  10465d:	c7 80 40 04 00 00 00 	movl   $0x0,0x440(%eax)
  104664:	00 00 00 

  spinlock_acquire(&p->lock);
  104667:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  10466a:	89 04 24             	mov    %eax,(%esp)
  10466d:	e8 18 f4 ff ff       	call   103a8a <spinlock_acquire>
  spinlock_release(&readylock);
  104672:	c7 04 24 40 aa 17 00 	movl   $0x17aa40,(%esp)
  104679:	e8 07 f5 ff ff       	call   103b85 <spinlock_release>

  proc_run(p);
  10467e:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  104681:	89 04 24             	mov    %eax,(%esp)
  104684:	e8 07 00 00 00       	call   104690 <proc_run>

00104689 <pause>:
}

static inline void
pause(void)
{
  104689:	55                   	push   %ebp
  10468a:	89 e5                	mov    %esp,%ebp
	asm volatile("pause" : : : "memory");
  10468c:	f3 90                	pause  
}
  10468e:	5d                   	pop    %ebp
  10468f:	c3                   	ret    

00104690 <proc_run>:
}	
// Switch to and run a specified process, which must already be locked.
void gcc_noreturn
proc_run(proc *p)
{
  104690:	55                   	push   %ebp
  104691:	89 e5                	mov    %esp,%ebp
  104693:	83 ec 28             	sub    $0x28,%esp
	//panic("proc_run not implemented");
  assert(spinlock_holding(&p->lock));
  104696:	8b 45 08             	mov    0x8(%ebp),%eax
  104699:	89 04 24             	mov    %eax,(%esp)
  10469c:	e8 3e f5 ff ff       	call   103bdf <spinlock_holding>
  1046a1:	85 c0                	test   %eax,%eax
  1046a3:	75 24                	jne    1046c9 <proc_run+0x39>
  1046a5:	c7 44 24 0c 1d cb 10 	movl   $0x10cb1d,0xc(%esp)
  1046ac:	00 
  1046ad:	c7 44 24 08 5a ca 10 	movl   $0x10ca5a,0x8(%esp)
  1046b4:	00 
  1046b5:	c7 44 24 04 a9 00 00 	movl   $0xa9,0x4(%esp)
  1046bc:	00 
  1046bd:	c7 04 24 38 ca 10 00 	movl   $0x10ca38,(%esp)
  1046c4:	e8 6f c2 ff ff       	call   100938 <debug_panic>

  cpu *c = cpu_cur();
  1046c9:	e8 7d fa ff ff       	call   10414b <cpu_cur>
  1046ce:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  p->state = PROC_RUN;
  1046d1:	8b 45 08             	mov    0x8(%ebp),%eax
  1046d4:	c7 80 3c 04 00 00 02 	movl   $0x2,0x43c(%eax)
  1046db:	00 00 00 
  p->runcpu = c;
  1046de:	8b 55 08             	mov    0x8(%ebp),%edx
  1046e1:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1046e4:	89 82 44 04 00 00    	mov    %eax,0x444(%edx)
  c->proc = p;
  1046ea:	8b 55 f8             	mov    0xfffffff8(%ebp),%edx
  1046ed:	8b 45 08             	mov    0x8(%ebp),%eax
  1046f0:	89 82 b4 00 00 00    	mov    %eax,0xb4(%edx)

  spinlock_release(&p->lock);
  1046f6:	8b 45 08             	mov    0x8(%ebp),%eax
  1046f9:	89 04 24             	mov    %eax,(%esp)
  1046fc:	e8 84 f4 ff ff       	call   103b85 <spinlock_release>

  lcr3(mem_phys(p->pdir));
  104701:	8b 45 08             	mov    0x8(%ebp),%eax
  104704:	8b 80 a0 06 00 00    	mov    0x6a0(%eax),%eax
  10470a:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)

static gcc_inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
  10470d:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  104710:	0f 22 d8             	mov    %eax,%cr3
  trap_return(&p->sv.tf);
  104713:	8b 45 08             	mov    0x8(%ebp),%eax
  104716:	05 50 04 00 00       	add    $0x450,%eax
  10471b:	89 04 24             	mov    %eax,(%esp)
  10471e:	e8 0d ef ff ff       	call   103630 <trap_return>

00104723 <proc_yield>:
}

// Yield the current CPU to another ready process.
// Called while handling a timer interrupt.
void gcc_noreturn
proc_yield(trapframe *tf)
{
  104723:	55                   	push   %ebp
  104724:	89 e5                	mov    %esp,%ebp
  104726:	53                   	push   %ebx
  104727:	83 ec 24             	sub    $0x24,%esp
//	panic("proc_yield not implemented");
    proc *p = proc_cur();
  10472a:	e8 1c fa ff ff       	call   10414b <cpu_cur>
  10472f:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  104735:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
    assert(p->runcpu == cpu_cur());
  104738:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10473b:	8b 98 44 04 00 00    	mov    0x444(%eax),%ebx
  104741:	e8 05 fa ff ff       	call   10414b <cpu_cur>
  104746:	39 c3                	cmp    %eax,%ebx
  104748:	74 24                	je     10476e <proc_yield+0x4b>
  10474a:	c7 44 24 0c 78 cb 10 	movl   $0x10cb78,0xc(%esp)
  104751:	00 
  104752:	c7 44 24 08 5a ca 10 	movl   $0x10ca5a,0x8(%esp)
  104759:	00 
  10475a:	c7 44 24 04 bd 00 00 	movl   $0xbd,0x4(%esp)
  104761:	00 
  104762:	c7 04 24 38 ca 10 00 	movl   $0x10ca38,(%esp)
  104769:	e8 ca c1 ff ff       	call   100938 <debug_panic>
    p->runcpu = NULL; // this process no longer running
  10476e:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  104771:	c7 80 44 04 00 00 00 	movl   $0x0,0x444(%eax)
  104778:	00 00 00 
    proc_save(p, tf, -1); // save this process's state
  10477b:	c7 44 24 08 ff ff ff 	movl   $0xffffffff,0x8(%esp)
  104782:	ff 
  104783:	8b 45 08             	mov    0x8(%ebp),%eax
  104786:	89 44 24 04          	mov    %eax,0x4(%esp)
  10478a:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10478d:	89 04 24             	mov    %eax,(%esp)
  104790:	e8 a5 fc ff ff       	call   10443a <proc_save>
    proc_ready(p);  // put it on tail of ready queue
  104795:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  104798:	89 04 24             	mov    %eax,(%esp)
  10479b:	e8 48 fc ff ff       	call   1043e8 <proc_ready>

    proc_sched(); // schedule a process from head of ready queue
  1047a0:	e8 07 fe ff ff       	call   1045ac <proc_sched>

001047a5 <proc_ret>:
}

// Put the current process to sleep by "returning" to its parent process.
// Used both when a process calls the SYS_RET system call explicitly,
// and when a process causes an unhandled trap in user mode.
// The 'entry' parameter is as in proc_save().
void gcc_noreturn
proc_ret(trapframe *tf, int entry)
{
  1047a5:	55                   	push   %ebp
  1047a6:	89 e5                	mov    %esp,%ebp
  1047a8:	53                   	push   %ebx
  1047a9:	83 ec 24             	sub    $0x24,%esp
	//panic("proc_ret not implemented");

  proc *cp = proc_cur();  // we're the child
  1047ac:	e8 9a f9 ff ff       	call   10414b <cpu_cur>
  1047b1:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  1047b7:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
  assert(cp->state == PROC_RUN && cp->runcpu == cpu_cur());
  1047ba:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  1047bd:	8b 80 3c 04 00 00    	mov    0x43c(%eax),%eax
  1047c3:	83 f8 02             	cmp    $0x2,%eax
  1047c6:	75 12                	jne    1047da <proc_ret+0x35>
  1047c8:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  1047cb:	8b 98 44 04 00 00    	mov    0x444(%eax),%ebx
  1047d1:	e8 75 f9 ff ff       	call   10414b <cpu_cur>
  1047d6:	39 c3                	cmp    %eax,%ebx
  1047d8:	74 24                	je     1047fe <proc_ret+0x59>
  1047da:	c7 44 24 0c 90 cb 10 	movl   $0x10cb90,0xc(%esp)
  1047e1:	00 
  1047e2:	c7 44 24 08 5a ca 10 	movl   $0x10ca5a,0x8(%esp)
  1047e9:	00 
  1047ea:	c7 44 24 04 cf 00 00 	movl   $0xcf,0x4(%esp)
  1047f1:	00 
  1047f2:	c7 04 24 38 ca 10 00 	movl   $0x10ca38,(%esp)
  1047f9:	e8 3a c1 ff ff       	call   100938 <debug_panic>

  proc *p = cp->parent;  // find our parent
  1047fe:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  104801:	8b 40 38             	mov    0x38(%eax),%eax
  104804:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  if (p == NULL) { // "return" from root process!
  104807:	83 7d f8 00          	cmpl   $0x0,0xfffffff8(%ebp)
  10480b:	75 67                	jne    104874 <proc_ret+0xcf>
    if (tf->trapno != T_SYSCALL) {
  10480d:	8b 45 08             	mov    0x8(%ebp),%eax
  104810:	8b 40 30             	mov    0x30(%eax),%eax
  104813:	83 f8 30             	cmp    $0x30,%eax
  104816:	74 27                	je     10483f <proc_ret+0x9a>
      trap_print(tf);
  104818:	8b 45 08             	mov    0x8(%ebp),%eax
  10481b:	89 04 24             	mov    %eax,(%esp)
  10481e:	e8 73 e5 ff ff       	call   102d96 <trap_print>
      panic("trap in root process");
  104823:	c7 44 24 08 c1 cb 10 	movl   $0x10cbc1,0x8(%esp)
  10482a:	00 
  10482b:	c7 44 24 04 d5 00 00 	movl   $0xd5,0x4(%esp)
  104832:	00 
  104833:	c7 04 24 38 ca 10 00 	movl   $0x10ca38,(%esp)
  10483a:	e8 f9 c0 ff ff       	call   100938 <debug_panic>
    }
 	assert(entry == 1);
  10483f:	83 7d 0c 01          	cmpl   $0x1,0xc(%ebp)
  104843:	74 24                	je     104869 <proc_ret+0xc4>
  104845:	c7 44 24 0c d6 cb 10 	movl   $0x10cbd6,0xc(%esp)
  10484c:	00 
  10484d:	c7 44 24 08 5a ca 10 	movl   $0x10ca5a,0x8(%esp)
  104854:	00 
  104855:	c7 44 24 04 d7 00 00 	movl   $0xd7,0x4(%esp)
  10485c:	00 
  10485d:	c7 04 24 38 ca 10 00 	movl   $0x10ca38,(%esp)
  104864:	e8 cf c0 ff ff       	call   100938 <debug_panic>
		file_io(tf);
  104869:	8b 45 08             	mov    0x8(%ebp),%eax
  10486c:	89 04 24             	mov    %eax,(%esp)
  10486f:	e8 d1 54 00 00       	call   109d45 <file_io>
  }

  spinlock_acquire(&p->lock);  // lock both in proper order
  104874:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  104877:	89 04 24             	mov    %eax,(%esp)
  10487a:	e8 0b f2 ff ff       	call   103a8a <spinlock_acquire>

  cp->state = PROC_STOP; // we're becoming stopped
  10487f:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  104882:	c7 80 3c 04 00 00 00 	movl   $0x0,0x43c(%eax)
  104889:	00 00 00 
  cp->runcpu = NULL; // no longer running
  10488c:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  10488f:	c7 80 44 04 00 00 00 	movl   $0x0,0x444(%eax)
  104896:	00 00 00 
  proc_save(cp, tf, entry);  // save process state after INT insn
  104899:	8b 45 0c             	mov    0xc(%ebp),%eax
  10489c:	89 44 24 08          	mov    %eax,0x8(%esp)
  1048a0:	8b 45 08             	mov    0x8(%ebp),%eax
  1048a3:	89 44 24 04          	mov    %eax,0x4(%esp)
  1048a7:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  1048aa:	89 04 24             	mov    %eax,(%esp)
  1048ad:	e8 88 fb ff ff       	call   10443a <proc_save>

  // If parent is waiting to sync with us, wake it up.
  if (p->state == PROC_WAIT && p->waitchild == cp) {
  1048b2:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1048b5:	8b 80 3c 04 00 00    	mov    0x43c(%eax),%eax
  1048bb:	83 f8 03             	cmp    $0x3,%eax
  1048be:	75 26                	jne    1048e6 <proc_ret+0x141>
  1048c0:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1048c3:	8b 80 48 04 00 00    	mov    0x448(%eax),%eax
  1048c9:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  1048cc:	75 18                	jne    1048e6 <proc_ret+0x141>
    p->waitchild = NULL;
  1048ce:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1048d1:	c7 80 48 04 00 00 00 	movl   $0x0,0x448(%eax)
  1048d8:	00 00 00 
    proc_run(p);
  1048db:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1048de:	89 04 24             	mov    %eax,(%esp)
  1048e1:	e8 aa fd ff ff       	call   104690 <proc_run>
  }

  spinlock_release(&p->lock);
  1048e6:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1048e9:	89 04 24             	mov    %eax,(%esp)
  1048ec:	e8 94 f2 ff ff       	call   103b85 <spinlock_release>
  proc_sched();  // find and run someone else
  1048f1:	e8 b6 fc ff ff       	call   1045ac <proc_sched>

001048f6 <proc_check>:
}
// Helper functions for proc_check()
static void child(int n);
static void grandchild(int n);

static struct procstate child_state;
static char gcc_aligned(16) child_stack[4][PAGESIZE];

static volatile uint32_t pingpong = 0;
static void *recovargs;
void
proc_check(void)
{
  1048f6:	55                   	push   %ebp
  1048f7:	89 e5                	mov    %esp,%ebp
  1048f9:	57                   	push   %edi
  1048fa:	56                   	push   %esi
  1048fb:	53                   	push   %ebx
  1048fc:	81 ec dc 00 00 00    	sub    $0xdc,%esp
	// Spawn 2 child processes, executing on statically allocated stacks.

	int i;
	for (i = 0; i < 4; i++) {
  104902:	c7 85 40 ff ff ff 00 	movl   $0x0,0xffffff40(%ebp)
  104909:	00 00 00 
  10490c:	e9 12 01 00 00       	jmp    104a23 <proc_check+0x12d>
		// Setup register state for child
		uint32_t *esp = (uint32_t*) &child_stack[i][PAGESIZE];
  104911:	8b 85 40 ff ff ff    	mov    0xffffff40(%ebp),%eax
  104917:	c1 e0 0c             	shl    $0xc,%eax
  10491a:	89 c2                	mov    %eax,%edx
  10491c:	b8 d0 ac 17 00       	mov    $0x17acd0,%eax
  104921:	05 00 10 00 00       	add    $0x1000,%eax
  104926:	8d 04 02             	lea    (%edx,%eax,1),%eax
  104929:	89 85 44 ff ff ff    	mov    %eax,0xffffff44(%ebp)
		*--esp = i;	// push argument to child() function
  10492f:	83 ad 44 ff ff ff 04 	subl   $0x4,0xffffff44(%ebp)
  104936:	8b 95 40 ff ff ff    	mov    0xffffff40(%ebp),%edx
  10493c:	8b 85 44 ff ff ff    	mov    0xffffff44(%ebp),%eax
  104942:	89 10                	mov    %edx,(%eax)
		*--esp = 0;	// fake return address
  104944:	83 ad 44 ff ff ff 04 	subl   $0x4,0xffffff44(%ebp)
  10494b:	8b 85 44 ff ff ff    	mov    0xffffff44(%ebp),%eax
  104951:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		child_state.tf.eip = (uint32_t) child;
  104957:	b8 e1 4d 10 00       	mov    $0x104de1,%eax
  10495c:	a3 b8 aa 17 00       	mov    %eax,0x17aab8
		child_state.tf.esp = (uint32_t) esp;
  104961:	8b 85 44 ff ff ff    	mov    0xffffff44(%ebp),%eax
  104967:	a3 c4 aa 17 00       	mov    %eax,0x17aac4

		// Use PUT syscall to create each child,
		// but only start the first 2 children for now.
		cprintf("spawning child %d\n", i);
  10496c:	8b 85 40 ff ff ff    	mov    0xffffff40(%ebp),%eax
  104972:	89 44 24 04          	mov    %eax,0x4(%esp)
  104976:	c7 04 24 e1 cb 10 00 	movl   $0x10cbe1,(%esp)
  10497d:	e8 03 6b 00 00       	call   10b485 <cprintf>
		sys_put(SYS_REGS | (i < 2 ? SYS_START : 0), i, &child_state,
  104982:	8b 85 40 ff ff ff    	mov    0xffffff40(%ebp),%eax
  104988:	0f b7 c0             	movzwl %ax,%eax
  10498b:	89 85 2c ff ff ff    	mov    %eax,0xffffff2c(%ebp)
  104991:	83 bd 40 ff ff ff 01 	cmpl   $0x1,0xffffff40(%ebp)
  104998:	7f 0c                	jg     1049a6 <proc_check+0xb0>
  10499a:	c7 85 30 ff ff ff 10 	movl   $0x1010,0xffffff30(%ebp)
  1049a1:	10 00 00 
  1049a4:	eb 0a                	jmp    1049b0 <proc_check+0xba>
  1049a6:	c7 85 30 ff ff ff 00 	movl   $0x1000,0xffffff30(%ebp)
  1049ad:	10 00 00 
  1049b0:	8b 85 30 ff ff ff    	mov    0xffffff30(%ebp),%eax
  1049b6:	89 85 60 ff ff ff    	mov    %eax,0xffffff60(%ebp)
  1049bc:	0f b7 85 2c ff ff ff 	movzwl 0xffffff2c(%ebp),%eax
  1049c3:	66 89 85 5e ff ff ff 	mov    %ax,0xffffff5e(%ebp)
  1049ca:	c7 85 58 ff ff ff 80 	movl   $0x17aa80,0xffffff58(%ebp)
  1049d1:	aa 17 00 
  1049d4:	c7 85 54 ff ff ff 00 	movl   $0x0,0xffffff54(%ebp)
  1049db:	00 00 00 
  1049de:	c7 85 50 ff ff ff 00 	movl   $0x0,0xffffff50(%ebp)
  1049e5:	00 00 00 
  1049e8:	c7 85 4c ff ff ff 00 	movl   $0x0,0xffffff4c(%ebp)
  1049ef:	00 00 00 
static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
  1049f2:	8b 85 60 ff ff ff    	mov    0xffffff60(%ebp),%eax
  1049f8:	83 c8 01             	or     $0x1,%eax
  1049fb:	8b 9d 58 ff ff ff    	mov    0xffffff58(%ebp),%ebx
  104a01:	0f b7 95 5e ff ff ff 	movzwl 0xffffff5e(%ebp),%edx
  104a08:	8b b5 54 ff ff ff    	mov    0xffffff54(%ebp),%esi
  104a0e:	8b bd 50 ff ff ff    	mov    0xffffff50(%ebp),%edi
  104a14:	8b 8d 4c ff ff ff    	mov    0xffffff4c(%ebp),%ecx
  104a1a:	cd 30                	int    $0x30
  104a1c:	83 85 40 ff ff ff 01 	addl   $0x1,0xffffff40(%ebp)
  104a23:	83 bd 40 ff ff ff 03 	cmpl   $0x3,0xffffff40(%ebp)
  104a2a:	0f 8e e1 fe ff ff    	jle    104911 <proc_check+0x1b>
			NULL, NULL, 0);
	}

	// Wait for both children to complete.
	// This should complete without preemptive scheduling
	// when we're running on a 2-processor machine.
	for (i = 0; i < 2; i++) {
  104a30:	c7 85 40 ff ff ff 00 	movl   $0x0,0xffffff40(%ebp)
  104a37:	00 00 00 
  104a3a:	e9 89 00 00 00       	jmp    104ac8 <proc_check+0x1d2>
		cprintf("waiting for child %d\n", i);
  104a3f:	8b 85 40 ff ff ff    	mov    0xffffff40(%ebp),%eax
  104a45:	89 44 24 04          	mov    %eax,0x4(%esp)
  104a49:	c7 04 24 f4 cb 10 00 	movl   $0x10cbf4,(%esp)
  104a50:	e8 30 6a 00 00       	call   10b485 <cprintf>
		sys_get(SYS_REGS, i, &child_state, NULL, NULL, 0);
  104a55:	8b 85 40 ff ff ff    	mov    0xffffff40(%ebp),%eax
  104a5b:	0f b7 c0             	movzwl %ax,%eax
  104a5e:	c7 85 78 ff ff ff 00 	movl   $0x1000,0xffffff78(%ebp)
  104a65:	10 00 00 
  104a68:	66 89 85 76 ff ff ff 	mov    %ax,0xffffff76(%ebp)
  104a6f:	c7 85 70 ff ff ff 80 	movl   $0x17aa80,0xffffff70(%ebp)
  104a76:	aa 17 00 
  104a79:	c7 85 6c ff ff ff 00 	movl   $0x0,0xffffff6c(%ebp)
  104a80:	00 00 00 
  104a83:	c7 85 68 ff ff ff 00 	movl   $0x0,0xffffff68(%ebp)
  104a8a:	00 00 00 
  104a8d:	c7 85 64 ff ff ff 00 	movl   $0x0,0xffffff64(%ebp)
  104a94:	00 00 00 
static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
  104a97:	8b 85 78 ff ff ff    	mov    0xffffff78(%ebp),%eax
  104a9d:	83 c8 02             	or     $0x2,%eax
  104aa0:	8b 9d 70 ff ff ff    	mov    0xffffff70(%ebp),%ebx
  104aa6:	0f b7 95 76 ff ff ff 	movzwl 0xffffff76(%ebp),%edx
  104aad:	8b b5 6c ff ff ff    	mov    0xffffff6c(%ebp),%esi
  104ab3:	8b bd 68 ff ff ff    	mov    0xffffff68(%ebp),%edi
  104ab9:	8b 8d 64 ff ff ff    	mov    0xffffff64(%ebp),%ecx
  104abf:	cd 30                	int    $0x30
  104ac1:	83 85 40 ff ff ff 01 	addl   $0x1,0xffffff40(%ebp)
  104ac8:	83 bd 40 ff ff ff 01 	cmpl   $0x1,0xffffff40(%ebp)
  104acf:	0f 8e 6a ff ff ff    	jle    104a3f <proc_check+0x149>
	}
	cprintf("proc_check() 2-child test succeeded\n");
  104ad5:	c7 04 24 0c cc 10 00 	movl   $0x10cc0c,(%esp)
  104adc:	e8 a4 69 00 00       	call   10b485 <cprintf>

	// (Re)start all four children, and wait for them.
	// This will require preemptive scheduling to complete
	// if we have less than 4 CPUs.
	cprintf("proc_check: spawning 4 children\n");
  104ae1:	c7 04 24 34 cc 10 00 	movl   $0x10cc34,(%esp)
  104ae8:	e8 98 69 00 00       	call   10b485 <cprintf>
	for (i = 0; i < 4; i++) {
  104aed:	c7 85 40 ff ff ff 00 	movl   $0x0,0xffffff40(%ebp)
  104af4:	00 00 00 
  104af7:	eb 6b                	jmp    104b64 <proc_check+0x26e>
		cprintf("spawning child %d\n", i);
  104af9:	8b 85 40 ff ff ff    	mov    0xffffff40(%ebp),%eax
  104aff:	89 44 24 04          	mov    %eax,0x4(%esp)
  104b03:	c7 04 24 e1 cb 10 00 	movl   $0x10cbe1,(%esp)
  104b0a:	e8 76 69 00 00       	call   10b485 <cprintf>
		sys_put(SYS_START, i, NULL, NULL, NULL, 0);
  104b0f:	8b 85 40 ff ff ff    	mov    0xffffff40(%ebp),%eax
  104b15:	0f b7 c0             	movzwl %ax,%eax
  104b18:	c7 45 90 10 00 00 00 	movl   $0x10,0xffffff90(%ebp)
  104b1f:	66 89 45 8e          	mov    %ax,0xffffff8e(%ebp)
  104b23:	c7 45 88 00 00 00 00 	movl   $0x0,0xffffff88(%ebp)
  104b2a:	c7 45 84 00 00 00 00 	movl   $0x0,0xffffff84(%ebp)
  104b31:	c7 45 80 00 00 00 00 	movl   $0x0,0xffffff80(%ebp)
  104b38:	c7 85 7c ff ff ff 00 	movl   $0x0,0xffffff7c(%ebp)
  104b3f:	00 00 00 
static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
  104b42:	8b 45 90             	mov    0xffffff90(%ebp),%eax
  104b45:	83 c8 01             	or     $0x1,%eax
  104b48:	8b 5d 88             	mov    0xffffff88(%ebp),%ebx
  104b4b:	0f b7 55 8e          	movzwl 0xffffff8e(%ebp),%edx
  104b4f:	8b 75 84             	mov    0xffffff84(%ebp),%esi
  104b52:	8b 7d 80             	mov    0xffffff80(%ebp),%edi
  104b55:	8b 8d 7c ff ff ff    	mov    0xffffff7c(%ebp),%ecx
  104b5b:	cd 30                	int    $0x30
  104b5d:	83 85 40 ff ff ff 01 	addl   $0x1,0xffffff40(%ebp)
  104b64:	83 bd 40 ff ff ff 03 	cmpl   $0x3,0xffffff40(%ebp)
  104b6b:	7e 8c                	jle    104af9 <proc_check+0x203>
	}

	// Wait for all 4 children to complete.
	for (i = 0; i < 4; i++)
  104b6d:	c7 85 40 ff ff ff 00 	movl   $0x0,0xffffff40(%ebp)
  104b74:	00 00 00 
  104b77:	eb 4f                	jmp    104bc8 <proc_check+0x2d2>
		sys_get(0, i, NULL, NULL, NULL, 0);
  104b79:	8b 85 40 ff ff ff    	mov    0xffffff40(%ebp),%eax
  104b7f:	0f b7 c0             	movzwl %ax,%eax
  104b82:	c7 45 a8 00 00 00 00 	movl   $0x0,0xffffffa8(%ebp)
  104b89:	66 89 45 a6          	mov    %ax,0xffffffa6(%ebp)
  104b8d:	c7 45 a0 00 00 00 00 	movl   $0x0,0xffffffa0(%ebp)
  104b94:	c7 45 9c 00 00 00 00 	movl   $0x0,0xffffff9c(%ebp)
  104b9b:	c7 45 98 00 00 00 00 	movl   $0x0,0xffffff98(%ebp)
  104ba2:	c7 45 94 00 00 00 00 	movl   $0x0,0xffffff94(%ebp)
static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
  104ba9:	8b 45 a8             	mov    0xffffffa8(%ebp),%eax
  104bac:	83 c8 02             	or     $0x2,%eax
  104baf:	8b 5d a0             	mov    0xffffffa0(%ebp),%ebx
  104bb2:	0f b7 55 a6          	movzwl 0xffffffa6(%ebp),%edx
  104bb6:	8b 75 9c             	mov    0xffffff9c(%ebp),%esi
  104bb9:	8b 7d 98             	mov    0xffffff98(%ebp),%edi
  104bbc:	8b 4d 94             	mov    0xffffff94(%ebp),%ecx
  104bbf:	cd 30                	int    $0x30
  104bc1:	83 85 40 ff ff ff 01 	addl   $0x1,0xffffff40(%ebp)
  104bc8:	83 bd 40 ff ff ff 03 	cmpl   $0x3,0xffffff40(%ebp)
  104bcf:	7e a8                	jle    104b79 <proc_check+0x283>
	cprintf("proc_check() 4-child test succeeded\n");
  104bd1:	c7 04 24 58 cc 10 00 	movl   $0x10cc58,(%esp)
  104bd8:	e8 a8 68 00 00       	call   10b485 <cprintf>

	// Now do a trap handling test using all 4 children -
	// but they'll _think_ they're all child 0!
	// (We'll lose the register state of the other children.)
	i = 0;
  104bdd:	c7 85 40 ff ff ff 00 	movl   $0x0,0xffffff40(%ebp)
  104be4:	00 00 00 
	sys_get(SYS_REGS, i, &child_state, NULL, NULL, 0);
  104be7:	8b 85 40 ff ff ff    	mov    0xffffff40(%ebp),%eax
  104bed:	0f b7 c0             	movzwl %ax,%eax
  104bf0:	c7 45 c0 00 10 00 00 	movl   $0x1000,0xffffffc0(%ebp)
  104bf7:	66 89 45 be          	mov    %ax,0xffffffbe(%ebp)
  104bfb:	c7 45 b8 80 aa 17 00 	movl   $0x17aa80,0xffffffb8(%ebp)
  104c02:	c7 45 b4 00 00 00 00 	movl   $0x0,0xffffffb4(%ebp)
  104c09:	c7 45 b0 00 00 00 00 	movl   $0x0,0xffffffb0(%ebp)
  104c10:	c7 45 ac 00 00 00 00 	movl   $0x0,0xffffffac(%ebp)
static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
  104c17:	8b 45 c0             	mov    0xffffffc0(%ebp),%eax
  104c1a:	83 c8 02             	or     $0x2,%eax
  104c1d:	8b 5d b8             	mov    0xffffffb8(%ebp),%ebx
  104c20:	0f b7 55 be          	movzwl 0xffffffbe(%ebp),%edx
  104c24:	8b 75 b4             	mov    0xffffffb4(%ebp),%esi
  104c27:	8b 7d b0             	mov    0xffffffb0(%ebp),%edi
  104c2a:	8b 4d ac             	mov    0xffffffac(%ebp),%ecx
  104c2d:	cd 30                	int    $0x30
		// get child 0's state
	assert(recovargs == NULL);
  104c2f:	a1 d0 ec 17 00       	mov    0x17ecd0,%eax
  104c34:	85 c0                	test   %eax,%eax
  104c36:	74 24                	je     104c5c <proc_check+0x366>
  104c38:	c7 44 24 0c 7d cc 10 	movl   $0x10cc7d,0xc(%esp)
  104c3f:	00 
  104c40:	c7 44 24 08 5a ca 10 	movl   $0x10ca5a,0x8(%esp)
  104c47:	00 
  104c48:	c7 44 24 04 25 01 00 	movl   $0x125,0x4(%esp)
  104c4f:	00 
  104c50:	c7 04 24 38 ca 10 00 	movl   $0x10ca38,(%esp)
  104c57:	e8 dc bc ff ff       	call   100938 <debug_panic>
	do {
		sys_put(SYS_REGS | SYS_START, i, &child_state, NULL, NULL, 0);
  104c5c:	8b 85 40 ff ff ff    	mov    0xffffff40(%ebp),%eax
  104c62:	0f b7 c0             	movzwl %ax,%eax
  104c65:	c7 45 d8 10 10 00 00 	movl   $0x1010,0xffffffd8(%ebp)
  104c6c:	66 89 45 d6          	mov    %ax,0xffffffd6(%ebp)
  104c70:	c7 45 d0 80 aa 17 00 	movl   $0x17aa80,0xffffffd0(%ebp)
  104c77:	c7 45 cc 00 00 00 00 	movl   $0x0,0xffffffcc(%ebp)
  104c7e:	c7 45 c8 00 00 00 00 	movl   $0x0,0xffffffc8(%ebp)
  104c85:	c7 45 c4 00 00 00 00 	movl   $0x0,0xffffffc4(%ebp)
static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
  104c8c:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  104c8f:	83 c8 01             	or     $0x1,%eax
  104c92:	8b 5d d0             	mov    0xffffffd0(%ebp),%ebx
  104c95:	0f b7 55 d6          	movzwl 0xffffffd6(%ebp),%edx
  104c99:	8b 75 cc             	mov    0xffffffcc(%ebp),%esi
  104c9c:	8b 7d c8             	mov    0xffffffc8(%ebp),%edi
  104c9f:	8b 4d c4             	mov    0xffffffc4(%ebp),%ecx
  104ca2:	cd 30                	int    $0x30
		sys_get(SYS_REGS, i, &child_state, NULL, NULL, 0);
  104ca4:	8b 85 40 ff ff ff    	mov    0xffffff40(%ebp),%eax
  104caa:	0f b7 c0             	movzwl %ax,%eax
  104cad:	c7 45 f0 00 10 00 00 	movl   $0x1000,0xfffffff0(%ebp)
  104cb4:	66 89 45 ee          	mov    %ax,0xffffffee(%ebp)
  104cb8:	c7 45 e8 80 aa 17 00 	movl   $0x17aa80,0xffffffe8(%ebp)
  104cbf:	c7 45 e4 00 00 00 00 	movl   $0x0,0xffffffe4(%ebp)
  104cc6:	c7 45 e0 00 00 00 00 	movl   $0x0,0xffffffe0(%ebp)
  104ccd:	c7 45 dc 00 00 00 00 	movl   $0x0,0xffffffdc(%ebp)
static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
  104cd4:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  104cd7:	83 c8 02             	or     $0x2,%eax
  104cda:	8b 5d e8             	mov    0xffffffe8(%ebp),%ebx
  104cdd:	0f b7 55 ee          	movzwl 0xffffffee(%ebp),%edx
  104ce1:	8b 75 e4             	mov    0xffffffe4(%ebp),%esi
  104ce4:	8b 7d e0             	mov    0xffffffe0(%ebp),%edi
  104ce7:	8b 4d dc             	mov    0xffffffdc(%ebp),%ecx
  104cea:	cd 30                	int    $0x30
		if (recovargs) {	// trap recovery needed
  104cec:	a1 d0 ec 17 00       	mov    0x17ecd0,%eax
  104cf1:	85 c0                	test   %eax,%eax
  104cf3:	74 3f                	je     104d34 <proc_check+0x43e>
			trap_check_args *args = recovargs;
  104cf5:	a1 d0 ec 17 00       	mov    0x17ecd0,%eax
  104cfa:	89 85 48 ff ff ff    	mov    %eax,0xffffff48(%ebp)
			cprintf("recover from trap %d\n",
  104d00:	a1 b0 aa 17 00       	mov    0x17aab0,%eax
  104d05:	89 44 24 04          	mov    %eax,0x4(%esp)
  104d09:	c7 04 24 8f cc 10 00 	movl   $0x10cc8f,(%esp)
  104d10:	e8 70 67 00 00       	call   10b485 <cprintf>
				child_state.tf.trapno);
			child_state.tf.eip = (uint32_t) args->reip;
  104d15:	8b 85 48 ff ff ff    	mov    0xffffff48(%ebp),%eax
  104d1b:	8b 00                	mov    (%eax),%eax
  104d1d:	a3 b8 aa 17 00       	mov    %eax,0x17aab8
			args->trapno = child_state.tf.trapno;
  104d22:	a1 b0 aa 17 00       	mov    0x17aab0,%eax
  104d27:	89 c2                	mov    %eax,%edx
  104d29:	8b 85 48 ff ff ff    	mov    0xffffff48(%ebp),%eax
  104d2f:	89 50 04             	mov    %edx,0x4(%eax)
  104d32:	eb 2e                	jmp    104d62 <proc_check+0x46c>
		} else
			assert(child_state.tf.trapno == T_SYSCALL);
  104d34:	a1 b0 aa 17 00       	mov    0x17aab0,%eax
  104d39:	83 f8 30             	cmp    $0x30,%eax
  104d3c:	74 24                	je     104d62 <proc_check+0x46c>
  104d3e:	c7 44 24 0c a8 cc 10 	movl   $0x10cca8,0xc(%esp)
  104d45:	00 
  104d46:	c7 44 24 08 5a ca 10 	movl   $0x10ca5a,0x8(%esp)
  104d4d:	00 
  104d4e:	c7 44 24 04 30 01 00 	movl   $0x130,0x4(%esp)
  104d55:	00 
  104d56:	c7 04 24 38 ca 10 00 	movl   $0x10ca38,(%esp)
  104d5d:	e8 d6 bb ff ff       	call   100938 <debug_panic>
		i = (i+1) % 4;	// rotate to next child proc
  104d62:	8b 95 40 ff ff ff    	mov    0xffffff40(%ebp),%edx
  104d68:	83 c2 01             	add    $0x1,%edx
  104d6b:	89 d0                	mov    %edx,%eax
  104d6d:	c1 f8 1f             	sar    $0x1f,%eax
  104d70:	89 c1                	mov    %eax,%ecx
  104d72:	c1 e9 1e             	shr    $0x1e,%ecx
  104d75:	8d 04 0a             	lea    (%edx,%ecx,1),%eax
  104d78:	83 e0 03             	and    $0x3,%eax
  104d7b:	29 c8                	sub    %ecx,%eax
  104d7d:	89 85 40 ff ff ff    	mov    %eax,0xffffff40(%ebp)
	} while (child_state.tf.trapno != T_SYSCALL);
  104d83:	a1 b0 aa 17 00       	mov    0x17aab0,%eax
  104d88:	83 f8 30             	cmp    $0x30,%eax
  104d8b:	0f 85 cb fe ff ff    	jne    104c5c <proc_check+0x366>
	assert(recovargs == NULL);
  104d91:	a1 d0 ec 17 00       	mov    0x17ecd0,%eax
  104d96:	85 c0                	test   %eax,%eax
  104d98:	74 24                	je     104dbe <proc_check+0x4c8>
  104d9a:	c7 44 24 0c 7d cc 10 	movl   $0x10cc7d,0xc(%esp)
  104da1:	00 
  104da2:	c7 44 24 08 5a ca 10 	movl   $0x10ca5a,0x8(%esp)
  104da9:	00 
  104daa:	c7 44 24 04 33 01 00 	movl   $0x133,0x4(%esp)
  104db1:	00 
  104db2:	c7 04 24 38 ca 10 00 	movl   $0x10ca38,(%esp)
  104db9:	e8 7a bb ff ff       	call   100938 <debug_panic>

	cprintf("proc_check() trap reflection test succeeded\n");
  104dbe:	c7 04 24 cc cc 10 00 	movl   $0x10cccc,(%esp)
  104dc5:	e8 bb 66 00 00       	call   10b485 <cprintf>

	cprintf("proc_check() succeeded!\n");
  104dca:	c7 04 24 f9 cc 10 00 	movl   $0x10ccf9,(%esp)
  104dd1:	e8 af 66 00 00       	call   10b485 <cprintf>
 }
  104dd6:	81 c4 dc 00 00 00    	add    $0xdc,%esp
  104ddc:	5b                   	pop    %ebx
  104ddd:	5e                   	pop    %esi
  104dde:	5f                   	pop    %edi
  104ddf:	5d                   	pop    %ebp
  104de0:	c3                   	ret    

00104de1 <child>:

static void child(int n)
{
  104de1:	55                   	push   %ebp
  104de2:	89 e5                	mov    %esp,%ebp
  104de4:	83 ec 28             	sub    $0x28,%esp
	// Only first 2 children participate in first pingpong test
	if (n < 2) {
  104de7:	83 7d 08 01          	cmpl   $0x1,0x8(%ebp)
  104deb:	7f 64                	jg     104e51 <child+0x70>
		int i;
		for (i = 0; i < 10; i++) {
  104ded:	c7 45 fc 00 00 00 00 	movl   $0x0,0xfffffffc(%ebp)
  104df4:	eb 4e                	jmp    104e44 <child+0x63>
			cprintf("in child %d count %d\n", n, i);
  104df6:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  104df9:	89 44 24 08          	mov    %eax,0x8(%esp)
  104dfd:	8b 45 08             	mov    0x8(%ebp),%eax
  104e00:	89 44 24 04          	mov    %eax,0x4(%esp)
  104e04:	c7 04 24 12 cd 10 00 	movl   $0x10cd12,(%esp)
  104e0b:	e8 75 66 00 00       	call   10b485 <cprintf>
			while (pingpong != n)
  104e10:	eb 05                	jmp    104e17 <child+0x36>
				pause();
  104e12:	e8 72 f8 ff ff       	call   104689 <pause>
  104e17:	8b 55 08             	mov    0x8(%ebp),%edx
  104e1a:	a1 20 aa 17 00       	mov    0x17aa20,%eax
  104e1f:	39 c2                	cmp    %eax,%edx
  104e21:	75 ef                	jne    104e12 <child+0x31>
			xchg(&pingpong, !pingpong);
  104e23:	a1 20 aa 17 00       	mov    0x17aa20,%eax
  104e28:	85 c0                	test   %eax,%eax
  104e2a:	0f 94 c0             	sete   %al
  104e2d:	0f b6 c0             	movzbl %al,%eax
  104e30:	89 44 24 04          	mov    %eax,0x4(%esp)
  104e34:	c7 04 24 20 aa 17 00 	movl   $0x17aa20,(%esp)
  104e3b:	e8 02 01 00 00       	call   104f42 <xchg>
  104e40:	83 45 fc 01          	addl   $0x1,0xfffffffc(%ebp)
  104e44:	83 7d fc 09          	cmpl   $0x9,0xfffffffc(%ebp)
  104e48:	7e ac                	jle    104df6 <child+0x15>

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
  104e4a:	b8 03 00 00 00       	mov    $0x3,%eax
  104e4f:	cd 30                	int    $0x30
		}
		sys_ret();
	}

	// Second test, round-robin pingpong between all 4 children
	int i;
	for (i = 0; i < 10; i++) {
  104e51:	c7 45 f8 00 00 00 00 	movl   $0x0,0xfffffff8(%ebp)
  104e58:	eb 4c                	jmp    104ea6 <child+0xc5>
		cprintf("in child %d count %d\n", n, i);
  104e5a:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  104e5d:	89 44 24 08          	mov    %eax,0x8(%esp)
  104e61:	8b 45 08             	mov    0x8(%ebp),%eax
  104e64:	89 44 24 04          	mov    %eax,0x4(%esp)
  104e68:	c7 04 24 12 cd 10 00 	movl   $0x10cd12,(%esp)
  104e6f:	e8 11 66 00 00       	call   10b485 <cprintf>
		while (pingpong != n)
  104e74:	eb 05                	jmp    104e7b <child+0x9a>
			pause();
  104e76:	e8 0e f8 ff ff       	call   104689 <pause>
  104e7b:	8b 55 08             	mov    0x8(%ebp),%edx
  104e7e:	a1 20 aa 17 00       	mov    0x17aa20,%eax
  104e83:	39 c2                	cmp    %eax,%edx
  104e85:	75 ef                	jne    104e76 <child+0x95>
		xchg(&pingpong, (pingpong + 1) % 4);
  104e87:	a1 20 aa 17 00       	mov    0x17aa20,%eax
  104e8c:	83 c0 01             	add    $0x1,%eax
  104e8f:	83 e0 03             	and    $0x3,%eax
  104e92:	89 44 24 04          	mov    %eax,0x4(%esp)
  104e96:	c7 04 24 20 aa 17 00 	movl   $0x17aa20,(%esp)
  104e9d:	e8 a0 00 00 00       	call   104f42 <xchg>
  104ea2:	83 45 f8 01          	addl   $0x1,0xfffffff8(%ebp)
  104ea6:	83 7d f8 09          	cmpl   $0x9,0xfffffff8(%ebp)
  104eaa:	7e ae                	jle    104e5a <child+0x79>

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
  104eac:	b8 03 00 00 00       	mov    $0x3,%eax
  104eb1:	cd 30                	int    $0x30
	}
	sys_ret();

	// Only "child 0" (or the proc that thinks it's child 0), trap check...
	if (n == 0) {
  104eb3:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  104eb7:	75 6d                	jne    104f26 <child+0x145>
		assert(recovargs == NULL);
  104eb9:	a1 d0 ec 17 00       	mov    0x17ecd0,%eax
  104ebe:	85 c0                	test   %eax,%eax
  104ec0:	74 24                	je     104ee6 <child+0x105>
  104ec2:	c7 44 24 0c 7d cc 10 	movl   $0x10cc7d,0xc(%esp)
  104ec9:	00 
  104eca:	c7 44 24 08 5a ca 10 	movl   $0x10ca5a,0x8(%esp)
  104ed1:	00 
  104ed2:	c7 44 24 04 54 01 00 	movl   $0x154,0x4(%esp)
  104ed9:	00 
  104eda:	c7 04 24 38 ca 10 00 	movl   $0x10ca38,(%esp)
  104ee1:	e8 52 ba ff ff       	call   100938 <debug_panic>
		trap_check(&recovargs);
  104ee6:	c7 04 24 d0 ec 17 00 	movl   $0x17ecd0,(%esp)
  104eed:	e8 70 e3 ff ff       	call   103262 <trap_check>
		assert(recovargs == NULL);
  104ef2:	a1 d0 ec 17 00       	mov    0x17ecd0,%eax
  104ef7:	85 c0                	test   %eax,%eax
  104ef9:	74 24                	je     104f1f <child+0x13e>
  104efb:	c7 44 24 0c 7d cc 10 	movl   $0x10cc7d,0xc(%esp)
  104f02:	00 
  104f03:	c7 44 24 08 5a ca 10 	movl   $0x10ca5a,0x8(%esp)
  104f0a:	00 
  104f0b:	c7 44 24 04 56 01 00 	movl   $0x156,0x4(%esp)
  104f12:	00 
  104f13:	c7 04 24 38 ca 10 00 	movl   $0x10ca38,(%esp)
  104f1a:	e8 19 ba ff ff       	call   100938 <debug_panic>

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
  104f1f:	b8 03 00 00 00       	mov    $0x3,%eax
  104f24:	cd 30                	int    $0x30
		sys_ret();
	}

	panic("child(): shouldn't have gotten here");
  104f26:	c7 44 24 08 28 cd 10 	movl   $0x10cd28,0x8(%esp)
  104f2d:	00 
  104f2e:	c7 44 24 04 5a 01 00 	movl   $0x15a,0x4(%esp)
  104f35:	00 
  104f36:	c7 04 24 38 ca 10 00 	movl   $0x10ca38,(%esp)
  104f3d:	e8 f6 b9 ff ff       	call   100938 <debug_panic>

00104f42 <xchg>:

// Atomically set *addr to newval and return the old value of *addr.
static inline uint32_t
xchg(volatile uint32_t *addr, uint32_t newval)
{
  104f42:	55                   	push   %ebp
  104f43:	89 e5                	mov    %esp,%ebp
  104f45:	53                   	push   %ebx
  104f46:	83 ec 14             	sub    $0x14,%esp
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
  104f49:	8b 4d 08             	mov    0x8(%ebp),%ecx
  104f4c:	8b 55 0c             	mov    0xc(%ebp),%edx
  104f4f:	8b 45 08             	mov    0x8(%ebp),%eax
  104f52:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  104f55:	89 d0                	mov    %edx,%eax
  104f57:	8b 5d e8             	mov    0xffffffe8(%ebp),%ebx
  104f5a:	f0 87 01             	lock xchg %eax,(%ecx)
  104f5d:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  104f60:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  104f63:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
	       "+m" (*addr), "=a" (result) :
	       "1" (newval) :
	       "cc");
	return result;
  104f66:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
}
  104f69:	83 c4 14             	add    $0x14,%esp
  104f6c:	5b                   	pop    %ebx
  104f6d:	5d                   	pop    %ebp
  104f6e:	c3                   	ret    

00104f6f <grandchild>:
 }

static void grandchild(int n)
{
  104f6f:	55                   	push   %ebp
  104f70:	89 e5                	mov    %esp,%ebp
  104f72:	83 ec 18             	sub    $0x18,%esp
	panic("grandchild(): shouldn't have gotten here");
  104f75:	c7 44 24 08 4c cd 10 	movl   $0x10cd4c,0x8(%esp)
  104f7c:	00 
  104f7d:	c7 44 24 04 5f 01 00 	movl   $0x15f,0x4(%esp)
  104f84:	00 
  104f85:	c7 04 24 38 ca 10 00 	movl   $0x10ca38,(%esp)
  104f8c:	e8 a7 b9 ff ff       	call   100938 <debug_panic>
  104f91:	90                   	nop    
  104f92:	90                   	nop    
  104f93:	90                   	nop    

00104f94 <systrap>:
// as if the user code's INT 0x30 instruction had caused it -
// and reflect the trap to the parent process as with other traps.
static void gcc_noreturn
systrap(trapframe *utf, int trapno, int err)
{
  104f94:	55                   	push   %ebp
  104f95:	89 e5                	mov    %esp,%ebp
  104f97:	83 ec 08             	sub    $0x8,%esp
  utf->trapno = trapno;
  104f9a:	8b 55 0c             	mov    0xc(%ebp),%edx
  104f9d:	8b 45 08             	mov    0x8(%ebp),%eax
  104fa0:	89 50 30             	mov    %edx,0x30(%eax)
  utf->err = err;
  104fa3:	8b 55 10             	mov    0x10(%ebp),%edx
  104fa6:	8b 45 08             	mov    0x8(%ebp),%eax
  104fa9:	89 50 34             	mov    %edx,0x34(%eax)
  proc_ret(utf,0);
  104fac:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  104fb3:	00 
  104fb4:	8b 45 08             	mov    0x8(%ebp),%eax
  104fb7:	89 04 24             	mov    %eax,(%esp)
  104fba:	e8 e6 f7 ff ff       	call   1047a5 <proc_ret>

00104fbf <sysrecover>:
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
  104fbf:	55                   	push   %ebp
  104fc0:	89 e5                	mov    %esp,%ebp
  104fc2:	83 ec 28             	sub    $0x28,%esp
  trapframe *utf = (trapframe*)recoverdata;
  104fc5:	8b 45 0c             	mov    0xc(%ebp),%eax
  104fc8:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)

  cpu *c = cpu_cur();
  104fcb:	e8 65 00 00 00       	call   105035 <cpu_cur>
  104fd0:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  assert(c->recover == sysrecover);
  104fd3:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  104fd6:	8b 80 a0 00 00 00    	mov    0xa0(%eax),%eax
  104fdc:	3d bf 4f 10 00       	cmp    $0x104fbf,%eax
  104fe1:	74 24                	je     105007 <sysrecover+0x48>
  104fe3:	c7 44 24 0c 78 cd 10 	movl   $0x10cd78,0xc(%esp)
  104fea:	00 
  104feb:	c7 44 24 08 91 cd 10 	movl   $0x10cd91,0x8(%esp)
  104ff2:	00 
  104ff3:	c7 44 24 04 3c 00 00 	movl   $0x3c,0x4(%esp)
  104ffa:	00 
  104ffb:	c7 04 24 a6 cd 10 00 	movl   $0x10cda6,(%esp)
  105002:	e8 31 b9 ff ff       	call   100938 <debug_panic>
  c->recover = NULL;
  105007:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  10500a:	c7 80 a0 00 00 00 00 	movl   $0x0,0xa0(%eax)
  105011:	00 00 00 

  systrap(utf, ktf->trapno, ktf->err);
  105014:	8b 45 08             	mov    0x8(%ebp),%eax
  105017:	8b 40 34             	mov    0x34(%eax),%eax
  10501a:	89 c2                	mov    %eax,%edx
  10501c:	8b 45 08             	mov    0x8(%ebp),%eax
  10501f:	8b 40 30             	mov    0x30(%eax),%eax
  105022:	89 54 24 08          	mov    %edx,0x8(%esp)
  105026:	89 44 24 04          	mov    %eax,0x4(%esp)
  10502a:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10502d:	89 04 24             	mov    %eax,(%esp)
  105030:	e8 5f ff ff ff       	call   104f94 <systrap>

00105035 <cpu_cur>:

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  105035:	55                   	push   %ebp
  105036:	89 e5                	mov    %esp,%ebp
  105038:	83 ec 28             	sub    $0x28,%esp
static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  10503b:	89 65 fc             	mov    %esp,0xfffffffc(%ebp)
        return esp;
  10503e:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  105041:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  105044:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  105047:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  10504c:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	assert(c->magic == CPU_MAGIC);
  10504f:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  105052:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  105058:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  10505d:	74 24                	je     105083 <cpu_cur+0x4e>
  10505f:	c7 44 24 0c b5 cd 10 	movl   $0x10cdb5,0xc(%esp)
  105066:	00 
  105067:	c7 44 24 08 91 cd 10 	movl   $0x10cd91,0x8(%esp)
  10506e:	00 
  10506f:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  105076:	00 
  105077:	c7 04 24 cb cd 10 00 	movl   $0x10cdcb,(%esp)
  10507e:	e8 b5 b8 ff ff       	call   100938 <debug_panic>
	return c;
  105083:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
}
  105086:	c9                   	leave  
  105087:	c3                   	ret    

00105088 <checkva>:
}

// Check a user virtual address block for validity:
// i.e., make sure the complete area specified lies in
// the user address space between VM_USERLO and VM_USERHI.
// If not, abort the syscall by sending a T_PGFLT to the parent,
// again as if the user program's INT instruction was to blame.
//
// Note: Be careful that your arithmetic works correctly
// even if size is very large, e.g., if uva+size wraps around!
//
static void checkva(trapframe *utf, uint32_t uva, size_t size)
{
  105088:	55                   	push   %ebp
  105089:	89 e5                	mov    %esp,%ebp
  10508b:	83 ec 18             	sub    $0x18,%esp
  if(uva < VM_USERLO || uva >= VM_USERHI || size >= VM_USERHI -uva){
  10508e:	81 7d 0c ff ff ff 3f 	cmpl   $0x3fffffff,0xc(%ebp)
  105095:	76 16                	jbe    1050ad <checkva+0x25>
  105097:	81 7d 0c ff ff ff ef 	cmpl   $0xefffffff,0xc(%ebp)
  10509e:	77 0d                	ja     1050ad <checkva+0x25>
  1050a0:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
  1050a5:	2b 45 0c             	sub    0xc(%ebp),%eax
  1050a8:	3b 45 10             	cmp    0x10(%ebp),%eax
  1050ab:	77 1b                	ja     1050c8 <checkva+0x40>

  systrap(utf, T_PGFLT, 0);
  1050ad:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  1050b4:	00 
  1050b5:	c7 44 24 04 0e 00 00 	movl   $0xe,0x4(%esp)
  1050bc:	00 
  1050bd:	8b 45 08             	mov    0x8(%ebp),%eax
  1050c0:	89 04 24             	mov    %eax,(%esp)
  1050c3:	e8 cc fe ff ff       	call   104f94 <systrap>
  }
}
  1050c8:	c9                   	leave  
  1050c9:	c3                   	ret    

001050ca <usercopy>:

// Copy data to/from user space,
// using checkva() above to validate the address range
// and using sysrecover() to recover from any traps during the copy.
void usercopy(trapframe *utf, bool copyout,
			void *kva, uint32_t uva, size_t size)
{
  1050ca:	55                   	push   %ebp
  1050cb:	89 e5                	mov    %esp,%ebp
  1050cd:	83 ec 28             	sub    $0x28,%esp
	checkva(utf, uva, size);
  1050d0:	8b 45 18             	mov    0x18(%ebp),%eax
  1050d3:	89 44 24 08          	mov    %eax,0x8(%esp)
  1050d7:	8b 45 14             	mov    0x14(%ebp),%eax
  1050da:	89 44 24 04          	mov    %eax,0x4(%esp)
  1050de:	8b 45 08             	mov    0x8(%ebp),%eax
  1050e1:	89 04 24             	mov    %eax,(%esp)
  1050e4:	e8 9f ff ff ff       	call   105088 <checkva>

  cpu *c = cpu_cur();
  1050e9:	e8 47 ff ff ff       	call   105035 <cpu_cur>
  1050ee:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  assert(c->recover == NULL);
  1050f1:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  1050f4:	8b 80 a0 00 00 00    	mov    0xa0(%eax),%eax
  1050fa:	85 c0                	test   %eax,%eax
  1050fc:	74 24                	je     105122 <usercopy+0x58>
  1050fe:	c7 44 24 0c d8 cd 10 	movl   $0x10cdd8,0xc(%esp)
  105105:	00 
  105106:	c7 44 24 08 91 cd 10 	movl   $0x10cd91,0x8(%esp)
  10510d:	00 
  10510e:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  105115:	00 
  105116:	c7 04 24 a6 cd 10 00 	movl   $0x10cda6,(%esp)
  10511d:	e8 16 b8 ff ff       	call   100938 <debug_panic>
  c->recover = sysrecover;
  105122:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  105125:	c7 80 a0 00 00 00 bf 	movl   $0x104fbf,0xa0(%eax)
  10512c:	4f 10 00 

  if(copyout)
  10512f:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  105133:	74 1b                	je     105150 <usercopy+0x86>
  memmove((void*)uva, kva, size);
  105135:	8b 45 14             	mov    0x14(%ebp),%eax
  105138:	8b 55 18             	mov    0x18(%ebp),%edx
  10513b:	89 54 24 08          	mov    %edx,0x8(%esp)
  10513f:	8b 55 10             	mov    0x10(%ebp),%edx
  105142:	89 54 24 04          	mov    %edx,0x4(%esp)
  105146:	89 04 24             	mov    %eax,(%esp)
  105149:	e8 34 67 00 00       	call   10b882 <memmove>
  10514e:	eb 19                	jmp    105169 <usercopy+0x9f>
  else
  memmove(kva, (void*)uva, size);
  105150:	8b 45 14             	mov    0x14(%ebp),%eax
  105153:	8b 55 18             	mov    0x18(%ebp),%edx
  105156:	89 54 24 08          	mov    %edx,0x8(%esp)
  10515a:	89 44 24 04          	mov    %eax,0x4(%esp)
  10515e:	8b 45 10             	mov    0x10(%ebp),%eax
  105161:	89 04 24             	mov    %eax,(%esp)
  105164:	e8 19 67 00 00       	call   10b882 <memmove>

  assert(c->recover == sysrecover);
  105169:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  10516c:	8b 80 a0 00 00 00    	mov    0xa0(%eax),%eax
  105172:	3d bf 4f 10 00       	cmp    $0x104fbf,%eax
  105177:	74 24                	je     10519d <usercopy+0xd3>
  105179:	c7 44 24 0c 78 cd 10 	movl   $0x10cd78,0xc(%esp)
  105180:	00 
  105181:	c7 44 24 08 91 cd 10 	movl   $0x10cd91,0x8(%esp)
  105188:	00 
  105189:	c7 44 24 04 64 00 00 	movl   $0x64,0x4(%esp)
  105190:	00 
  105191:	c7 04 24 a6 cd 10 00 	movl   $0x10cda6,(%esp)
  105198:	e8 9b b7 ff ff       	call   100938 <debug_panic>
  c->recover = NULL;
  10519d:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  1051a0:	c7 80 a0 00 00 00 00 	movl   $0x0,0xa0(%eax)
  1051a7:	00 00 00 
	// Now do the copy, but recover from page faults.
}
  1051aa:	c9                   	leave  
  1051ab:	c3                   	ret    

001051ac <do_cputs>:

static void
do_cputs(trapframe *tf, uint32_t cmd)
{
  1051ac:	55                   	push   %ebp
  1051ad:	89 e5                	mov    %esp,%ebp
  1051af:	81 ec 28 01 00 00    	sub    $0x128,%esp
	// Print the string supplied by the user: pointer in EBX
char buf[CPUTS_MAX+1];
usercopy(tf,0,buf,tf->regs.ebx,CPUTS_MAX);
  1051b5:	8b 45 08             	mov    0x8(%ebp),%eax
  1051b8:	8b 40 10             	mov    0x10(%eax),%eax
  1051bb:	c7 44 24 10 00 01 00 	movl   $0x100,0x10(%esp)
  1051c2:	00 
  1051c3:	89 44 24 0c          	mov    %eax,0xc(%esp)
  1051c7:	8d 85 ff fe ff ff    	lea    0xfffffeff(%ebp),%eax
  1051cd:	89 44 24 08          	mov    %eax,0x8(%esp)
  1051d1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1051d8:	00 
  1051d9:	8b 45 08             	mov    0x8(%ebp),%eax
  1051dc:	89 04 24             	mov    %eax,(%esp)
  1051df:	e8 e6 fe ff ff       	call   1050ca <usercopy>
buf[CPUTS_MAX] = 0;
  1051e4:	c6 45 ff 00          	movb   $0x0,0xffffffff(%ebp)
cprintf("%s",buf);
  1051e8:	8d 85 ff fe ff ff    	lea    0xfffffeff(%ebp),%eax
  1051ee:	89 44 24 04          	mov    %eax,0x4(%esp)
  1051f2:	c7 04 24 eb cd 10 00 	movl   $0x10cdeb,(%esp)
  1051f9:	e8 87 62 00 00       	call   10b485 <cprintf>
	cprintf("%s", (char*)tf->regs.ebx);
  1051fe:	8b 45 08             	mov    0x8(%ebp),%eax
  105201:	8b 40 10             	mov    0x10(%eax),%eax
  105204:	89 44 24 04          	mov    %eax,0x4(%esp)
  105208:	c7 04 24 eb cd 10 00 	movl   $0x10cdeb,(%esp)
  10520f:	e8 71 62 00 00       	call   10b485 <cprintf>
	trap_return(tf);	// syscall completed
  105214:	8b 45 08             	mov    0x8(%ebp),%eax
  105217:	89 04 24             	mov    %eax,(%esp)
  10521a:	e8 11 e4 ff ff       	call   103630 <trap_return>

0010521f <do_put>:
}
static void
do_put(trapframe *tf, uint32_t cmd)
{
  10521f:	55                   	push   %ebp
  105220:	89 e5                	mov    %esp,%ebp
  105222:	53                   	push   %ebx
  105223:	83 ec 44             	sub    $0x44,%esp
  proc *p = proc_cur();
  105226:	e8 0a fe ff ff       	call   105035 <cpu_cur>
  10522b:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  105231:	89 45 dc             	mov    %eax,0xffffffdc(%ebp)
  assert(p->state == PROC_RUN && p->runcpu == cpu_cur());
  105234:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  105237:	8b 80 3c 04 00 00    	mov    0x43c(%eax),%eax
  10523d:	83 f8 02             	cmp    $0x2,%eax
  105240:	75 12                	jne    105254 <do_put+0x35>
  105242:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  105245:	8b 98 44 04 00 00    	mov    0x444(%eax),%ebx
  10524b:	e8 e5 fd ff ff       	call   105035 <cpu_cur>
  105250:	39 c3                	cmp    %eax,%ebx
  105252:	74 24                	je     105278 <do_put+0x59>
  105254:	c7 44 24 0c f0 cd 10 	movl   $0x10cdf0,0xc(%esp)
  10525b:	00 
  10525c:	c7 44 24 08 91 cd 10 	movl   $0x10cd91,0x8(%esp)
  105263:	00 
  105264:	c7 44 24 04 78 00 00 	movl   $0x78,0x4(%esp)
  10526b:	00 
  10526c:	c7 04 24 a6 cd 10 00 	movl   $0x10cda6,(%esp)
  105273:	e8 c0 b6 ff ff       	call   100938 <debug_panic>
  cprintf("PUT proc %x eip %x esp %x cmd %x\n", p, tf->eip, tf->esp, cmd);
  105278:	8b 45 08             	mov    0x8(%ebp),%eax
  10527b:	8b 50 44             	mov    0x44(%eax),%edx
  10527e:	8b 45 08             	mov    0x8(%ebp),%eax
  105281:	8b 48 38             	mov    0x38(%eax),%ecx
  105284:	8b 45 0c             	mov    0xc(%ebp),%eax
  105287:	89 44 24 10          	mov    %eax,0x10(%esp)
  10528b:	89 54 24 0c          	mov    %edx,0xc(%esp)
  10528f:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  105293:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  105296:	89 44 24 04          	mov    %eax,0x4(%esp)
  10529a:	c7 04 24 20 ce 10 00 	movl   $0x10ce20,(%esp)
  1052a1:	e8 df 61 00 00       	call   10b485 <cprintf>

  spinlock_acquire(&p->lock);
  1052a6:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  1052a9:	89 04 24             	mov    %eax,(%esp)
  1052ac:	e8 d9 e7 ff ff       	call   103a8a <spinlock_acquire>

  // Find the named child process; create if it doesn't exist
  uint32_t cn = tf->regs.edx & 0xff;
  1052b1:	8b 45 08             	mov    0x8(%ebp),%eax
  1052b4:	8b 40 14             	mov    0x14(%eax),%eax
  1052b7:	25 ff 00 00 00       	and    $0xff,%eax
  1052bc:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)
  proc *cp = p->child[cn];
  1052bf:	8b 55 e0             	mov    0xffffffe0(%ebp),%edx
  1052c2:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  1052c5:	8b 44 90 3c          	mov    0x3c(%eax,%edx,4),%eax
  1052c9:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
  if (!cp) {
  1052cc:	83 7d e4 00          	cmpl   $0x0,0xffffffe4(%ebp)
  1052d0:	75 37                	jne    105309 <do_put+0xea>
    cp = proc_alloc(p, cn);
  1052d2:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  1052d5:	89 44 24 04          	mov    %eax,0x4(%esp)
  1052d9:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  1052dc:	89 04 24             	mov    %eax,(%esp)
  1052df:	e8 ba ee ff ff       	call   10419e <proc_alloc>
  1052e4:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
    if (!cp)  // XX handle more gracefully
  1052e7:	83 7d e4 00          	cmpl   $0x0,0xffffffe4(%ebp)
  1052eb:	75 1c                	jne    105309 <do_put+0xea>
      panic("sys_put: no memory for child");
  1052ed:	c7 44 24 08 42 ce 10 	movl   $0x10ce42,0x8(%esp)
  1052f4:	00 
  1052f5:	c7 44 24 04 83 00 00 	movl   $0x83,0x4(%esp)
  1052fc:	00 
  1052fd:	c7 04 24 a6 cd 10 00 	movl   $0x10cda6,(%esp)
  105304:	e8 2f b6 ff ff       	call   100938 <debug_panic>
  }

  // Synchronize with child if necessary.
  if (cp->state != PROC_STOP)
  105309:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  10530c:	8b 80 3c 04 00 00    	mov    0x43c(%eax),%eax
  105312:	85 c0                	test   %eax,%eax
  105314:	74 19                	je     10532f <do_put+0x110>
    proc_wait(p, cp, tf);
  105316:	8b 45 08             	mov    0x8(%ebp),%eax
  105319:	89 44 24 08          	mov    %eax,0x8(%esp)
  10531d:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  105320:	89 44 24 04          	mov    %eax,0x4(%esp)
  105324:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  105327:	89 04 24             	mov    %eax,(%esp)
  10532a:	e8 90 f1 ff ff       	call   1044bf <proc_wait>

  // Since the child is now stopped, it's ours to control;
  // we no longer need our process lock -
  // and we don't want to be holding it if usercopy() below aborts.
  spinlock_release(&p->lock);
  10532f:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  105332:	89 04 24             	mov    %eax,(%esp)
  105335:	e8 4b e8 ff ff       	call   103b85 <spinlock_release>

  // Put child's general register state
  if (cmd & SYS_REGS) {
  10533a:	8b 45 0c             	mov    0xc(%ebp),%eax
  10533d:	25 00 10 00 00       	and    $0x1000,%eax
  105342:	85 c0                	test   %eax,%eax
  105344:	0f 84 d4 00 00 00    	je     10541e <do_put+0x1ff>
    int len = offsetof(procstate, fx);  // just integer regs
  10534a:	c7 45 f4 50 00 00 00 	movl   $0x50,0xfffffff4(%ebp)
    if (cmd & SYS_FPU) len = sizeof(procstate); // whole shebang
  105351:	8b 45 0c             	mov    0xc(%ebp),%eax
  105354:	25 00 20 00 00       	and    $0x2000,%eax
  105359:	85 c0                	test   %eax,%eax
  10535b:	74 07                	je     105364 <do_put+0x145>
  10535d:	c7 45 f4 50 02 00 00 	movl   $0x250,0xfffffff4(%ebp)

  usercopy(tf,0,&cp->sv, tf->regs.ebx, len);
  105364:	8b 4d f4             	mov    0xfffffff4(%ebp),%ecx
  105367:	8b 45 08             	mov    0x8(%ebp),%eax
  10536a:	8b 40 10             	mov    0x10(%eax),%eax
  10536d:	8b 55 e4             	mov    0xffffffe4(%ebp),%edx
  105370:	81 c2 50 04 00 00    	add    $0x450,%edx
  105376:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  10537a:	89 44 24 0c          	mov    %eax,0xc(%esp)
  10537e:	89 54 24 08          	mov    %edx,0x8(%esp)
  105382:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  105389:	00 
  10538a:	8b 45 08             	mov    0x8(%ebp),%eax
  10538d:	89 04 24             	mov    %eax,(%esp)
  105390:	e8 35 fd ff ff       	call   1050ca <usercopy>
    // Copy user's trapframe into child process
    procstate *cs = (procstate*) tf->regs.ebx;
  105395:	8b 45 08             	mov    0x8(%ebp),%eax
  105398:	8b 40 10             	mov    0x10(%eax),%eax
  10539b:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
    memcpy(&cp->sv, cs, len);
  10539e:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  1053a1:	8b 55 e4             	mov    0xffffffe4(%ebp),%edx
  1053a4:	81 c2 50 04 00 00    	add    $0x450,%edx
  1053aa:	89 44 24 08          	mov    %eax,0x8(%esp)
  1053ae:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1053b1:	89 44 24 04          	mov    %eax,0x4(%esp)
  1053b5:	89 14 24             	mov    %edx,(%esp)
  1053b8:	e8 8b 65 00 00       	call   10b948 <memcpy>

    // Make sure process uses user-mode segments and eflag settings
    cp->sv.tf.ds = CPU_GDT_UDATA | 3;
  1053bd:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  1053c0:	66 c7 80 7c 04 00 00 	movw   $0x23,0x47c(%eax)
  1053c7:	23 00 
    cp->sv.tf.es = CPU_GDT_UDATA | 3;
  1053c9:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  1053cc:	66 c7 80 78 04 00 00 	movw   $0x23,0x478(%eax)
  1053d3:	23 00 
    cp->sv.tf.cs = CPU_GDT_UCODE | 3;
  1053d5:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  1053d8:	66 c7 80 8c 04 00 00 	movw   $0x1b,0x48c(%eax)
  1053df:	1b 00 
    cp->sv.tf.ss = CPU_GDT_UDATA | 3;
  1053e1:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  1053e4:	66 c7 80 98 04 00 00 	movw   $0x23,0x498(%eax)
  1053eb:	23 00 
    cp->sv.tf.eflags &= FL_USER;
  1053ed:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  1053f0:	8b 80 90 04 00 00    	mov    0x490(%eax),%eax
  1053f6:	89 c2                	mov    %eax,%edx
  1053f8:	81 e2 d5 0c 00 00    	and    $0xcd5,%edx
  1053fe:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  105401:	89 90 90 04 00 00    	mov    %edx,0x490(%eax)
    cp->sv.tf.eflags |= FL_IF;  // enable interrupts
  105407:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  10540a:	8b 80 90 04 00 00    	mov    0x490(%eax),%eax
  105410:	89 c2                	mov    %eax,%edx
  105412:	80 ce 02             	or     $0x2,%dh
  105415:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  105418:	89 90 90 04 00 00    	mov    %edx,0x490(%eax)
  }
	uint32_t sva = tf->regs.esi;
  10541e:	8b 45 08             	mov    0x8(%ebp),%eax
  105421:	8b 40 04             	mov    0x4(%eax),%eax
  105424:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
	uint32_t dva = tf->regs.edi;
  105427:	8b 45 08             	mov    0x8(%ebp),%eax
  10542a:	8b 00                	mov    (%eax),%eax
  10542c:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
	uint32_t size = tf->regs.ecx;
  10542f:	8b 45 08             	mov    0x8(%ebp),%eax
  105432:	8b 40 18             	mov    0x18(%eax),%eax
  105435:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
	switch (cmd & SYS_MEMOP) {
  105438:	8b 45 0c             	mov    0xc(%ebp),%eax
  10543b:	25 00 00 03 00       	and    $0x30000,%eax
  105440:	89 45 d4             	mov    %eax,0xffffffd4(%ebp)
  105443:	81 7d d4 00 00 01 00 	cmpl   $0x10000,0xffffffd4(%ebp)
  10544a:	74 6a                	je     1054b6 <do_put+0x297>
  10544c:	81 7d d4 00 00 02 00 	cmpl   $0x20000,0xffffffd4(%ebp)
  105453:	74 0f                	je     105464 <do_put+0x245>
  105455:	83 7d d4 00          	cmpl   $0x0,0xffffffd4(%ebp)
  105459:	0f 84 39 01 00 00    	je     105598 <do_put+0x379>
  10545f:	e9 19 01 00 00       	jmp    10557d <do_put+0x35e>
	case 0:	// no memory operation
		break;
	case SYS_COPY:
		// validate source region
		if (PTOFF(sva) || PTOFF(size)
  105464:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  105467:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  10546c:	85 c0                	test   %eax,%eax
  10546e:	75 2b                	jne    10549b <do_put+0x27c>
  105470:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  105473:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  105478:	85 c0                	test   %eax,%eax
  10547a:	75 1f                	jne    10549b <do_put+0x27c>
  10547c:	81 7d e8 ff ff ff 3f 	cmpl   $0x3fffffff,0xffffffe8(%ebp)
  105483:	76 16                	jbe    10549b <do_put+0x27c>
  105485:	81 7d e8 00 00 00 f0 	cmpl   $0xf0000000,0xffffffe8(%ebp)
  10548c:	77 0d                	ja     10549b <do_put+0x27c>
  10548e:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
  105493:	2b 45 e8             	sub    0xffffffe8(%ebp),%eax
  105496:	3b 45 f0             	cmp    0xfffffff0(%ebp),%eax
  105499:	73 1b                	jae    1054b6 <do_put+0x297>
				|| sva < VM_USERLO || sva > VM_USERHI
				|| size > VM_USERHI-sva)
			systrap(tf, T_GPFLT, 0);
  10549b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  1054a2:	00 
  1054a3:	c7 44 24 04 0d 00 00 	movl   $0xd,0x4(%esp)
  1054aa:	00 
  1054ab:	8b 45 08             	mov    0x8(%ebp),%eax
  1054ae:	89 04 24             	mov    %eax,(%esp)
  1054b1:	e8 de fa ff ff       	call   104f94 <systrap>
		// fall thru...
	case SYS_ZERO:
		// validate destination region
		if (PTOFF(dva) || PTOFF(size)
  1054b6:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  1054b9:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  1054be:	85 c0                	test   %eax,%eax
  1054c0:	75 2b                	jne    1054ed <do_put+0x2ce>
  1054c2:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  1054c5:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  1054ca:	85 c0                	test   %eax,%eax
  1054cc:	75 1f                	jne    1054ed <do_put+0x2ce>
  1054ce:	81 7d ec ff ff ff 3f 	cmpl   $0x3fffffff,0xffffffec(%ebp)
  1054d5:	76 16                	jbe    1054ed <do_put+0x2ce>
  1054d7:	81 7d ec 00 00 00 f0 	cmpl   $0xf0000000,0xffffffec(%ebp)
  1054de:	77 0d                	ja     1054ed <do_put+0x2ce>
  1054e0:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
  1054e5:	2b 45 ec             	sub    0xffffffec(%ebp),%eax
  1054e8:	3b 45 f0             	cmp    0xfffffff0(%ebp),%eax
  1054eb:	73 1b                	jae    105508 <do_put+0x2e9>
				|| dva < VM_USERLO || dva > VM_USERHI
				|| size > VM_USERHI-dva)
			systrap(tf, T_GPFLT, 0);
  1054ed:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  1054f4:	00 
  1054f5:	c7 44 24 04 0d 00 00 	movl   $0xd,0x4(%esp)
  1054fc:	00 
  1054fd:	8b 45 08             	mov    0x8(%ebp),%eax
  105500:	89 04 24             	mov    %eax,(%esp)
  105503:	e8 8c fa ff ff       	call   104f94 <systrap>

		switch (cmd & SYS_MEMOP) {
  105508:	8b 45 0c             	mov    0xc(%ebp),%eax
  10550b:	25 00 00 03 00       	and    $0x30000,%eax
  105510:	89 45 d8             	mov    %eax,0xffffffd8(%ebp)
  105513:	81 7d d8 00 00 01 00 	cmpl   $0x10000,0xffffffd8(%ebp)
  10551a:	74 0b                	je     105527 <do_put+0x308>
  10551c:	81 7d d8 00 00 02 00 	cmpl   $0x20000,0xffffffd8(%ebp)
  105523:	74 23                	je     105548 <do_put+0x329>
  105525:	eb 71                	jmp    105598 <do_put+0x379>
		case SYS_ZERO:	// zero memory and clear permissions
			pmap_remove(cp->pdir, dva, size);
  105527:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  10552a:	8b 90 a0 06 00 00    	mov    0x6a0(%eax),%edx
  105530:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  105533:	89 44 24 08          	mov    %eax,0x8(%esp)
  105537:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  10553a:	89 44 24 04          	mov    %eax,0x4(%esp)
  10553e:	89 14 24             	mov    %edx,(%esp)
  105541:	e8 d3 12 00 00       	call   106819 <pmap_remove>
			break;
  105546:	eb 50                	jmp    105598 <do_put+0x379>
		case SYS_COPY:	// copy from local src to dest in child
			pmap_copy(p->pdir, sva, cp->pdir, dva, size);
  105548:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  10554b:	8b 90 a0 06 00 00    	mov    0x6a0(%eax),%edx
  105551:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  105554:	8b 88 a0 06 00 00    	mov    0x6a0(%eax),%ecx
  10555a:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  10555d:	89 44 24 10          	mov    %eax,0x10(%esp)
  105561:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  105564:	89 44 24 0c          	mov    %eax,0xc(%esp)
  105568:	89 54 24 08          	mov    %edx,0x8(%esp)
  10556c:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  10556f:	89 44 24 04          	mov    %eax,0x4(%esp)
  105573:	89 0c 24             	mov    %ecx,(%esp)
  105576:	e8 81 17 00 00       	call   106cfc <pmap_copy>
			break;
		}
		break;
  10557b:	eb 1b                	jmp    105598 <do_put+0x379>
	default:
		systrap(tf, T_GPFLT, 0);
  10557d:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  105584:	00 
  105585:	c7 44 24 04 0d 00 00 	movl   $0xd,0x4(%esp)
  10558c:	00 
  10558d:	8b 45 08             	mov    0x8(%ebp),%eax
  105590:	89 04 24             	mov    %eax,(%esp)
  105593:	e8 fc f9 ff ff       	call   104f94 <systrap>
	}

	if (cmd & SYS_PERM) {
  105598:	8b 45 0c             	mov    0xc(%ebp),%eax
  10559b:	25 00 01 00 00       	and    $0x100,%eax
  1055a0:	85 c0                	test   %eax,%eax
  1055a2:	0f 84 a0 00 00 00    	je     105648 <do_put+0x429>
		// validate destination region
		if (PGOFF(dva) || PGOFF(size)
  1055a8:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  1055ab:	25 ff 0f 00 00       	and    $0xfff,%eax
  1055b0:	85 c0                	test   %eax,%eax
  1055b2:	75 2b                	jne    1055df <do_put+0x3c0>
  1055b4:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  1055b7:	25 ff 0f 00 00       	and    $0xfff,%eax
  1055bc:	85 c0                	test   %eax,%eax
  1055be:	75 1f                	jne    1055df <do_put+0x3c0>
  1055c0:	81 7d ec ff ff ff 3f 	cmpl   $0x3fffffff,0xffffffec(%ebp)
  1055c7:	76 16                	jbe    1055df <do_put+0x3c0>
  1055c9:	81 7d ec 00 00 00 f0 	cmpl   $0xf0000000,0xffffffec(%ebp)
  1055d0:	77 0d                	ja     1055df <do_put+0x3c0>
  1055d2:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
  1055d7:	2b 45 ec             	sub    0xffffffec(%ebp),%eax
  1055da:	3b 45 f0             	cmp    0xfffffff0(%ebp),%eax
  1055dd:	73 1b                	jae    1055fa <do_put+0x3db>
				|| dva < VM_USERLO || dva > VM_USERHI
				|| size > VM_USERHI-dva)
			systrap(tf, T_GPFLT, 0);
  1055df:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  1055e6:	00 
  1055e7:	c7 44 24 04 0d 00 00 	movl   $0xd,0x4(%esp)
  1055ee:	00 
  1055ef:	8b 45 08             	mov    0x8(%ebp),%eax
  1055f2:	89 04 24             	mov    %eax,(%esp)
  1055f5:	e8 9a f9 ff ff       	call   104f94 <systrap>
		if (!pmap_setperm(cp->pdir, dva, size, cmd & SYS_RW))
  1055fa:	8b 45 0c             	mov    0xc(%ebp),%eax
  1055fd:	89 c2                	mov    %eax,%edx
  1055ff:	81 e2 00 06 00 00    	and    $0x600,%edx
  105605:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  105608:	8b 88 a0 06 00 00    	mov    0x6a0(%eax),%ecx
  10560e:	89 54 24 0c          	mov    %edx,0xc(%esp)
  105612:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  105615:	89 44 24 08          	mov    %eax,0x8(%esp)
  105619:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  10561c:	89 44 24 04          	mov    %eax,0x4(%esp)
  105620:	89 0c 24             	mov    %ecx,(%esp)
  105623:	e8 64 29 00 00       	call   107f8c <pmap_setperm>
  105628:	85 c0                	test   %eax,%eax
  10562a:	75 1c                	jne    105648 <do_put+0x429>
			panic("pmap_put: no memory to set permissions");
  10562c:	c7 44 24 08 60 ce 10 	movl   $0x10ce60,0x8(%esp)
  105633:	00 
  105634:	c7 44 24 04 c9 00 00 	movl   $0xc9,0x4(%esp)
  10563b:	00 
  10563c:	c7 04 24 a6 cd 10 00 	movl   $0x10cda6,(%esp)
  105643:	e8 f0 b2 ff ff       	call   100938 <debug_panic>
	}

	if (cmd & SYS_SNAP)	// Snapshot child's state
  105648:	8b 45 0c             	mov    0xc(%ebp),%eax
  10564b:	25 00 00 04 00       	and    $0x40000,%eax
  105650:	85 c0                	test   %eax,%eax
  105652:	74 36                	je     10568a <do_put+0x46b>
		pmap_copy(cp->pdir, VM_USERLO, cp->rpdir, VM_USERLO,
  105654:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  105657:	8b 90 a4 06 00 00    	mov    0x6a4(%eax),%edx
  10565d:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  105660:	8b 80 a0 06 00 00    	mov    0x6a0(%eax),%eax
  105666:	c7 44 24 10 00 00 00 	movl   $0xb0000000,0x10(%esp)
  10566d:	b0 
  10566e:	c7 44 24 0c 00 00 00 	movl   $0x40000000,0xc(%esp)
  105675:	40 
  105676:	89 54 24 08          	mov    %edx,0x8(%esp)
  10567a:	c7 44 24 04 00 00 00 	movl   $0x40000000,0x4(%esp)
  105681:	40 
  105682:	89 04 24             	mov    %eax,(%esp)
  105685:	e8 72 16 00 00       	call   106cfc <pmap_copy>
				VM_USERHI-VM_USERLO);

  // Start the child if requested
  if (cmd & SYS_START)
  10568a:	8b 45 0c             	mov    0xc(%ebp),%eax
  10568d:	83 e0 10             	and    $0x10,%eax
  105690:	85 c0                	test   %eax,%eax
  105692:	74 0b                	je     10569f <do_put+0x480>
    proc_ready(cp);
  105694:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  105697:	89 04 24             	mov    %eax,(%esp)
  10569a:	e8 49 ed ff ff       	call   1043e8 <proc_ready>

  trap_return(tf);  // syscall completed
  10569f:	8b 45 08             	mov    0x8(%ebp),%eax
  1056a2:	89 04 24             	mov    %eax,(%esp)
  1056a5:	e8 86 df ff ff       	call   103630 <trap_return>

001056aa <do_get>:
}

  static void
do_get(trapframe *tf, uint32_t cmd)
{
  1056aa:	55                   	push   %ebp
  1056ab:	89 e5                	mov    %esp,%ebp
  1056ad:	53                   	push   %ebx
  1056ae:	83 ec 44             	sub    $0x44,%esp
  proc *p = proc_cur();
  1056b1:	e8 7f f9 ff ff       	call   105035 <cpu_cur>
  1056b6:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  1056bc:	89 45 dc             	mov    %eax,0xffffffdc(%ebp)
  assert(p->state == PROC_RUN && p->runcpu == cpu_cur());
  1056bf:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  1056c2:	8b 80 3c 04 00 00    	mov    0x43c(%eax),%eax
  1056c8:	83 f8 02             	cmp    $0x2,%eax
  1056cb:	75 12                	jne    1056df <do_get+0x35>
  1056cd:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  1056d0:	8b 98 44 04 00 00    	mov    0x444(%eax),%ebx
  1056d6:	e8 5a f9 ff ff       	call   105035 <cpu_cur>
  1056db:	39 c3                	cmp    %eax,%ebx
  1056dd:	74 24                	je     105703 <do_get+0x59>
  1056df:	c7 44 24 0c f0 cd 10 	movl   $0x10cdf0,0xc(%esp)
  1056e6:	00 
  1056e7:	c7 44 24 08 91 cd 10 	movl   $0x10cd91,0x8(%esp)
  1056ee:	00 
  1056ef:	c7 44 24 04 db 00 00 	movl   $0xdb,0x4(%esp)
  1056f6:	00 
  1056f7:	c7 04 24 a6 cd 10 00 	movl   $0x10cda6,(%esp)
  1056fe:	e8 35 b2 ff ff       	call   100938 <debug_panic>
  //cprintf("GET proc %x eip %x esp %x cmd %x\n", p, tf->eip, tf->esp, cmd);

  spinlock_acquire(&p->lock);
  105703:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  105706:	89 04 24             	mov    %eax,(%esp)
  105709:	e8 7c e3 ff ff       	call   103a8a <spinlock_acquire>

  // Find the named child process; DON'T create if it doesn't exist
  uint32_t cn = tf->regs.edx & 0xff;
  10570e:	8b 45 08             	mov    0x8(%ebp),%eax
  105711:	8b 40 14             	mov    0x14(%eax),%eax
  105714:	25 ff 00 00 00       	and    $0xff,%eax
  105719:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)
  proc *cp = p->child[cn];
  10571c:	8b 55 e0             	mov    0xffffffe0(%ebp),%edx
  10571f:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  105722:	8b 44 90 3c          	mov    0x3c(%eax,%edx,4),%eax
  105726:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
  if (!cp)
  105729:	83 7d e4 00          	cmpl   $0x0,0xffffffe4(%ebp)
  10572d:	75 07                	jne    105736 <do_get+0x8c>
    cp = &proc_null;
  10572f:	c7 45 e4 00 ee 17 00 	movl   $0x17ee00,0xffffffe4(%ebp)

  // Synchronize with child if necessary.
  if (cp->state != PROC_STOP)
  105736:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  105739:	8b 80 3c 04 00 00    	mov    0x43c(%eax),%eax
  10573f:	85 c0                	test   %eax,%eax
  105741:	74 19                	je     10575c <do_get+0xb2>
    proc_wait(p, cp, tf);
  105743:	8b 45 08             	mov    0x8(%ebp),%eax
  105746:	89 44 24 08          	mov    %eax,0x8(%esp)
  10574a:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  10574d:	89 44 24 04          	mov    %eax,0x4(%esp)
  105751:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  105754:	89 04 24             	mov    %eax,(%esp)
  105757:	e8 63 ed ff ff       	call   1044bf <proc_wait>

  // Since the child is now stopped, it's ours to control;
  // we no longer need our process lock -
  // and we don't want to be holding it if usercopy() below aborts.
  spinlock_release(&p->lock);
  10575c:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  10575f:	89 04 24             	mov    %eax,(%esp)
  105762:	e8 1e e4 ff ff       	call   103b85 <spinlock_release>

  // Get child's general register state
  if (cmd & SYS_REGS) {
  105767:	8b 45 0c             	mov    0xc(%ebp),%eax
  10576a:	25 00 10 00 00       	and    $0x1000,%eax
  10576f:	85 c0                	test   %eax,%eax
  105771:	74 73                	je     1057e6 <do_get+0x13c>
    int len = offsetof(procstate, fx);  // just integer regs
  105773:	c7 45 f4 50 00 00 00 	movl   $0x50,0xfffffff4(%ebp)
    if (cmd & SYS_FPU) len = sizeof(procstate); // whole shebang
  10577a:	8b 45 0c             	mov    0xc(%ebp),%eax
  10577d:	25 00 20 00 00       	and    $0x2000,%eax
  105782:	85 c0                	test   %eax,%eax
  105784:	74 07                	je     10578d <do_get+0xe3>
  105786:	c7 45 f4 50 02 00 00 	movl   $0x250,0xfffffff4(%ebp)
usercopy(tf, 1, &cp->sv, tf->regs.ebx, len);
  10578d:	8b 4d f4             	mov    0xfffffff4(%ebp),%ecx
  105790:	8b 45 08             	mov    0x8(%ebp),%eax
  105793:	8b 40 10             	mov    0x10(%eax),%eax
  105796:	8b 55 e4             	mov    0xffffffe4(%ebp),%edx
  105799:	81 c2 50 04 00 00    	add    $0x450,%edx
  10579f:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  1057a3:	89 44 24 0c          	mov    %eax,0xc(%esp)
  1057a7:	89 54 24 08          	mov    %edx,0x8(%esp)
  1057ab:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  1057b2:	00 
  1057b3:	8b 45 08             	mov    0x8(%ebp),%eax
  1057b6:	89 04 24             	mov    %eax,(%esp)
  1057b9:	e8 0c f9 ff ff       	call   1050ca <usercopy>
    // Copy child process's trapframe into user space
    procstate *cs = (procstate*) tf->regs.ebx;
  1057be:	8b 45 08             	mov    0x8(%ebp),%eax
  1057c1:	8b 40 10             	mov    0x10(%eax),%eax
  1057c4:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
    memcpy(cs, &cp->sv, len);
  1057c7:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  1057ca:	8b 55 e4             	mov    0xffffffe4(%ebp),%edx
  1057cd:	81 c2 50 04 00 00    	add    $0x450,%edx
  1057d3:	89 44 24 08          	mov    %eax,0x8(%esp)
  1057d7:	89 54 24 04          	mov    %edx,0x4(%esp)
  1057db:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1057de:	89 04 24             	mov    %eax,(%esp)
  1057e1:	e8 62 61 00 00       	call   10b948 <memcpy>
  }
uint32_t sva = tf->regs.esi;
  1057e6:	8b 45 08             	mov    0x8(%ebp),%eax
  1057e9:	8b 40 04             	mov    0x4(%eax),%eax
  1057ec:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
	uint32_t dva = tf->regs.edi;
  1057ef:	8b 45 08             	mov    0x8(%ebp),%eax
  1057f2:	8b 00                	mov    (%eax),%eax
  1057f4:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
	uint32_t size = tf->regs.ecx;
  1057f7:	8b 45 08             	mov    0x8(%ebp),%eax
  1057fa:	8b 40 18             	mov    0x18(%eax),%eax
  1057fd:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
	switch (cmd & SYS_MEMOP) {
  105800:	8b 45 0c             	mov    0xc(%ebp),%eax
  105803:	25 00 00 03 00       	and    $0x30000,%eax
  105808:	89 45 d4             	mov    %eax,0xffffffd4(%ebp)
  10580b:	81 7d d4 00 00 01 00 	cmpl   $0x10000,0xffffffd4(%ebp)
  105812:	0f 84 81 00 00 00    	je     105899 <do_get+0x1ef>
  105818:	81 7d d4 00 00 01 00 	cmpl   $0x10000,0xffffffd4(%ebp)
  10581f:	77 0f                	ja     105830 <do_get+0x186>
  105821:	83 7d d4 00          	cmpl   $0x0,0xffffffd4(%ebp)
  105825:	0f 84 a1 01 00 00    	je     1059cc <do_get+0x322>
  10582b:	e9 81 01 00 00       	jmp    1059b1 <do_get+0x307>
  105830:	81 7d d4 00 00 02 00 	cmpl   $0x20000,0xffffffd4(%ebp)
  105837:	74 0e                	je     105847 <do_get+0x19d>
  105839:	81 7d d4 00 00 03 00 	cmpl   $0x30000,0xffffffd4(%ebp)
  105840:	74 05                	je     105847 <do_get+0x19d>
  105842:	e9 6a 01 00 00       	jmp    1059b1 <do_get+0x307>
	case 0:	// no memory operation
		break;
	case SYS_COPY:
	case SYS_MERGE:
		// validate source region
		if (PTOFF(sva) || PTOFF(size)
  105847:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  10584a:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  10584f:	85 c0                	test   %eax,%eax
  105851:	75 2b                	jne    10587e <do_get+0x1d4>
  105853:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  105856:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  10585b:	85 c0                	test   %eax,%eax
  10585d:	75 1f                	jne    10587e <do_get+0x1d4>
  10585f:	81 7d e8 ff ff ff 3f 	cmpl   $0x3fffffff,0xffffffe8(%ebp)
  105866:	76 16                	jbe    10587e <do_get+0x1d4>
  105868:	81 7d e8 00 00 00 f0 	cmpl   $0xf0000000,0xffffffe8(%ebp)
  10586f:	77 0d                	ja     10587e <do_get+0x1d4>
  105871:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
  105876:	2b 45 e8             	sub    0xffffffe8(%ebp),%eax
  105879:	3b 45 f0             	cmp    0xfffffff0(%ebp),%eax
  10587c:	73 1b                	jae    105899 <do_get+0x1ef>
				|| sva < VM_USERLO || sva > VM_USERHI
				|| size > VM_USERHI-sva)
			systrap(tf, T_GPFLT, 0);
  10587e:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  105885:	00 
  105886:	c7 44 24 04 0d 00 00 	movl   $0xd,0x4(%esp)
  10588d:	00 
  10588e:	8b 45 08             	mov    0x8(%ebp),%eax
  105891:	89 04 24             	mov    %eax,(%esp)
  105894:	e8 fb f6 ff ff       	call   104f94 <systrap>
		// fall thru...
	case SYS_ZERO:
		// validate destination region
		if (PTOFF(dva) || PTOFF(size)
  105899:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  10589c:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  1058a1:	85 c0                	test   %eax,%eax
  1058a3:	75 2b                	jne    1058d0 <do_get+0x226>
  1058a5:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  1058a8:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  1058ad:	85 c0                	test   %eax,%eax
  1058af:	75 1f                	jne    1058d0 <do_get+0x226>
  1058b1:	81 7d ec ff ff ff 3f 	cmpl   $0x3fffffff,0xffffffec(%ebp)
  1058b8:	76 16                	jbe    1058d0 <do_get+0x226>
  1058ba:	81 7d ec 00 00 00 f0 	cmpl   $0xf0000000,0xffffffec(%ebp)
  1058c1:	77 0d                	ja     1058d0 <do_get+0x226>
  1058c3:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
  1058c8:	2b 45 ec             	sub    0xffffffec(%ebp),%eax
  1058cb:	3b 45 f0             	cmp    0xfffffff0(%ebp),%eax
  1058ce:	73 1b                	jae    1058eb <do_get+0x241>
				|| dva < VM_USERLO || dva > VM_USERHI
				|| size > VM_USERHI-dva)
			systrap(tf, T_GPFLT, 0);
  1058d0:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  1058d7:	00 
  1058d8:	c7 44 24 04 0d 00 00 	movl   $0xd,0x4(%esp)
  1058df:	00 
  1058e0:	8b 45 08             	mov    0x8(%ebp),%eax
  1058e3:	89 04 24             	mov    %eax,(%esp)
  1058e6:	e8 a9 f6 ff ff       	call   104f94 <systrap>

		switch (cmd & SYS_MEMOP) {
  1058eb:	8b 45 0c             	mov    0xc(%ebp),%eax
  1058ee:	25 00 00 03 00       	and    $0x30000,%eax
  1058f3:	89 45 d8             	mov    %eax,0xffffffd8(%ebp)
  1058f6:	81 7d d8 00 00 02 00 	cmpl   $0x20000,0xffffffd8(%ebp)
  1058fd:	74 3b                	je     10593a <do_get+0x290>
  1058ff:	81 7d d8 00 00 03 00 	cmpl   $0x30000,0xffffffd8(%ebp)
  105906:	74 67                	je     10596f <do_get+0x2c5>
  105908:	81 7d d8 00 00 01 00 	cmpl   $0x10000,0xffffffd8(%ebp)
  10590f:	74 05                	je     105916 <do_get+0x26c>
  105911:	e9 b6 00 00 00       	jmp    1059cc <do_get+0x322>
		case SYS_ZERO:	// zero memory and clear permissions
			pmap_remove(p->pdir, dva, size);
  105916:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  105919:	8b 90 a0 06 00 00    	mov    0x6a0(%eax),%edx
  10591f:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  105922:	89 44 24 08          	mov    %eax,0x8(%esp)
  105926:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  105929:	89 44 24 04          	mov    %eax,0x4(%esp)
  10592d:	89 14 24             	mov    %edx,(%esp)
  105930:	e8 e4 0e 00 00       	call   106819 <pmap_remove>
			break;
  105935:	e9 92 00 00 00       	jmp    1059cc <do_get+0x322>
		case SYS_COPY:	// copy from local src to dest in child
			pmap_copy(cp->pdir, sva, p->pdir, dva, size);
  10593a:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  10593d:	8b 90 a0 06 00 00    	mov    0x6a0(%eax),%edx
  105943:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  105946:	8b 88 a0 06 00 00    	mov    0x6a0(%eax),%ecx
  10594c:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  10594f:	89 44 24 10          	mov    %eax,0x10(%esp)
  105953:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  105956:	89 44 24 0c          	mov    %eax,0xc(%esp)
  10595a:	89 54 24 08          	mov    %edx,0x8(%esp)
  10595e:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  105961:	89 44 24 04          	mov    %eax,0x4(%esp)
  105965:	89 0c 24             	mov    %ecx,(%esp)
  105968:	e8 8f 13 00 00       	call   106cfc <pmap_copy>
			break;
  10596d:	eb 5d                	jmp    1059cc <do_get+0x322>
		case SYS_MERGE:	// merge from local src to dest in child
			pmap_merge(cp->rpdir, cp->pdir, sva,
  10596f:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  105972:	8b 90 a0 06 00 00    	mov    0x6a0(%eax),%edx
  105978:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  10597b:	8b 88 a0 06 00 00    	mov    0x6a0(%eax),%ecx
  105981:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  105984:	8b 98 a4 06 00 00    	mov    0x6a4(%eax),%ebx
  10598a:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  10598d:	89 44 24 14          	mov    %eax,0x14(%esp)
  105991:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  105994:	89 44 24 10          	mov    %eax,0x10(%esp)
  105998:	89 54 24 0c          	mov    %edx,0xc(%esp)
  10599c:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  10599f:	89 44 24 08          	mov    %eax,0x8(%esp)
  1059a3:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  1059a7:	89 1c 24             	mov    %ebx,(%esp)
  1059aa:	e8 33 20 00 00       	call   1079e2 <pmap_merge>
					p->pdir, dva, size);
			break;
		}
		break;
  1059af:	eb 1b                	jmp    1059cc <do_get+0x322>
	default:
		systrap(tf, T_GPFLT, 0);
  1059b1:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  1059b8:	00 
  1059b9:	c7 44 24 04 0d 00 00 	movl   $0xd,0x4(%esp)
  1059c0:	00 
  1059c1:	8b 45 08             	mov    0x8(%ebp),%eax
  1059c4:	89 04 24             	mov    %eax,(%esp)
  1059c7:	e8 c8 f5 ff ff       	call   104f94 <systrap>
	}

	if (cmd & SYS_PERM) {
  1059cc:	8b 45 0c             	mov    0xc(%ebp),%eax
  1059cf:	25 00 01 00 00       	and    $0x100,%eax
  1059d4:	85 c0                	test   %eax,%eax
  1059d6:	0f 84 a0 00 00 00    	je     105a7c <do_get+0x3d2>
		// validate destination region
		if (PGOFF(dva) || PGOFF(size)
  1059dc:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  1059df:	25 ff 0f 00 00       	and    $0xfff,%eax
  1059e4:	85 c0                	test   %eax,%eax
  1059e6:	75 2b                	jne    105a13 <do_get+0x369>
  1059e8:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  1059eb:	25 ff 0f 00 00       	and    $0xfff,%eax
  1059f0:	85 c0                	test   %eax,%eax
  1059f2:	75 1f                	jne    105a13 <do_get+0x369>
  1059f4:	81 7d ec ff ff ff 3f 	cmpl   $0x3fffffff,0xffffffec(%ebp)
  1059fb:	76 16                	jbe    105a13 <do_get+0x369>
  1059fd:	81 7d ec 00 00 00 f0 	cmpl   $0xf0000000,0xffffffec(%ebp)
  105a04:	77 0d                	ja     105a13 <do_get+0x369>
  105a06:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
  105a0b:	2b 45 ec             	sub    0xffffffec(%ebp),%eax
  105a0e:	3b 45 f0             	cmp    0xfffffff0(%ebp),%eax
  105a11:	73 1b                	jae    105a2e <do_get+0x384>
				|| dva < VM_USERLO || dva > VM_USERHI
				|| size > VM_USERHI-dva)
			systrap(tf, T_GPFLT, 0);
  105a13:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  105a1a:	00 
  105a1b:	c7 44 24 04 0d 00 00 	movl   $0xd,0x4(%esp)
  105a22:	00 
  105a23:	8b 45 08             	mov    0x8(%ebp),%eax
  105a26:	89 04 24             	mov    %eax,(%esp)
  105a29:	e8 66 f5 ff ff       	call   104f94 <systrap>
		if (!pmap_setperm(p->pdir, dva, size, cmd & SYS_RW))
  105a2e:	8b 45 0c             	mov    0xc(%ebp),%eax
  105a31:	89 c2                	mov    %eax,%edx
  105a33:	81 e2 00 06 00 00    	and    $0x600,%edx
  105a39:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  105a3c:	8b 88 a0 06 00 00    	mov    0x6a0(%eax),%ecx
  105a42:	89 54 24 0c          	mov    %edx,0xc(%esp)
  105a46:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  105a49:	89 44 24 08          	mov    %eax,0x8(%esp)
  105a4d:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  105a50:	89 44 24 04          	mov    %eax,0x4(%esp)
  105a54:	89 0c 24             	mov    %ecx,(%esp)
  105a57:	e8 30 25 00 00       	call   107f8c <pmap_setperm>
  105a5c:	85 c0                	test   %eax,%eax
  105a5e:	75 1c                	jne    105a7c <do_get+0x3d2>
			panic("pmap_get: no memory to set permissions");
  105a60:	c7 44 24 08 88 ce 10 	movl   $0x10ce88,0x8(%esp)
  105a67:	00 
  105a68:	c7 44 24 04 25 01 00 	movl   $0x125,0x4(%esp)
  105a6f:	00 
  105a70:	c7 04 24 a6 cd 10 00 	movl   $0x10cda6,(%esp)
  105a77:	e8 bc ae ff ff       	call   100938 <debug_panic>
	}

	if (cmd & SYS_SNAP)
  105a7c:	8b 45 0c             	mov    0xc(%ebp),%eax
  105a7f:	25 00 00 04 00       	and    $0x40000,%eax
  105a84:	85 c0                	test   %eax,%eax
  105a86:	74 1b                	je     105aa3 <do_get+0x3f9>
		systrap(tf, T_GPFLT, 0);	// only valid for PUT
  105a88:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  105a8f:	00 
  105a90:	c7 44 24 04 0d 00 00 	movl   $0xd,0x4(%esp)
  105a97:	00 
  105a98:	8b 45 08             	mov    0x8(%ebp),%eax
  105a9b:	89 04 24             	mov    %eax,(%esp)
  105a9e:	e8 f1 f4 ff ff       	call   104f94 <systrap>
  trap_return(tf);  // syscall completed
  105aa3:	8b 45 08             	mov    0x8(%ebp),%eax
  105aa6:	89 04 24             	mov    %eax,(%esp)
  105aa9:	e8 82 db ff ff       	call   103630 <trap_return>

00105aae <do_ret>:
}

  static void gcc_noreturn
do_ret(trapframe *tf)
{
  105aae:	55                   	push   %ebp
  105aaf:	89 e5                	mov    %esp,%ebp
  105ab1:	83 ec 08             	sub    $0x8,%esp
  //cprintf("RET proc %x eip %x esp %x\n", proc_cur(), tf->eip, tf->esp);
  proc_ret(tf, 1);
  105ab4:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  105abb:	00 
  105abc:	8b 45 08             	mov    0x8(%ebp),%eax
  105abf:	89 04 24             	mov    %eax,(%esp)
  105ac2:	e8 de ec ff ff       	call   1047a5 <proc_ret>

00105ac7 <syscall>:
}
// Common function to handle all system calls -
// decode the system call type and call an appropriate handler function.
// Be sure to handle undefined system calls appropriately.
void
syscall(trapframe *tf)
{
  105ac7:	55                   	push   %ebp
  105ac8:	89 e5                	mov    %esp,%ebp
  105aca:	83 ec 28             	sub    $0x28,%esp
	// EAX register holds system call command/flags
	uint32_t cmd = tf->regs.eax;
  105acd:	8b 45 08             	mov    0x8(%ebp),%eax
  105ad0:	8b 40 1c             	mov    0x1c(%eax),%eax
  105ad3:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	switch (cmd & SYS_TYPE) {
  105ad6:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  105ad9:	83 e0 0f             	and    $0xf,%eax
  105adc:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  105adf:	83 7d ec 01          	cmpl   $0x1,0xffffffec(%ebp)
  105ae3:	74 28                	je     105b0d <syscall+0x46>
  105ae5:	83 7d ec 01          	cmpl   $0x1,0xffffffec(%ebp)
  105ae9:	72 0e                	jb     105af9 <syscall+0x32>
  105aeb:	83 7d ec 02          	cmpl   $0x2,0xffffffec(%ebp)
  105aef:	74 30                	je     105b21 <syscall+0x5a>
  105af1:	83 7d ec 03          	cmpl   $0x3,0xffffffec(%ebp)
  105af5:	74 3e                	je     105b35 <syscall+0x6e>
  105af7:	eb 47                	jmp    105b40 <syscall+0x79>
	case SYS_CPUTS:	return do_cputs(tf, cmd);
  105af9:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  105afc:	89 44 24 04          	mov    %eax,0x4(%esp)
  105b00:	8b 45 08             	mov    0x8(%ebp),%eax
  105b03:	89 04 24             	mov    %eax,(%esp)
  105b06:	e8 a1 f6 ff ff       	call   1051ac <do_cputs>
  105b0b:	eb 33                	jmp    105b40 <syscall+0x79>
	case SYS_PUT:	return do_put(tf, cmd);
  105b0d:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  105b10:	89 44 24 04          	mov    %eax,0x4(%esp)
  105b14:	8b 45 08             	mov    0x8(%ebp),%eax
  105b17:	89 04 24             	mov    %eax,(%esp)
  105b1a:	e8 00 f7 ff ff       	call   10521f <do_put>
  105b1f:	eb 1f                	jmp    105b40 <syscall+0x79>
	case SYS_GET:	return do_get(tf, cmd);
  105b21:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  105b24:	89 44 24 04          	mov    %eax,0x4(%esp)
  105b28:	8b 45 08             	mov    0x8(%ebp),%eax
  105b2b:	89 04 24             	mov    %eax,(%esp)
  105b2e:	e8 77 fb ff ff       	call   1056aa <do_get>
  105b33:	eb 0b                	jmp    105b40 <syscall+0x79>
	case SYS_RET:	return do_ret(tf);
  105b35:	8b 45 08             	mov    0x8(%ebp),%eax
  105b38:	89 04 24             	mov    %eax,(%esp)
  105b3b:	e8 6e ff ff ff       	call   105aae <do_ret>
	// Your implementations of SYS_PUT, SYS_GET, SYS_RET here...
	default:	return;		// handle as a regular trap
	}
}
  105b40:	c9                   	leave  
  105b41:	c3                   	ret    
  105b42:	90                   	nop    
  105b43:	90                   	nop    

00105b44 <pmap_init>:
// The user part of the address space remains all PTE_ZERO until later.
//
void
pmap_init(void)
{
  105b44:	55                   	push   %ebp
  105b45:	89 e5                	mov    %esp,%ebp
  105b47:	83 ec 28             	sub    $0x28,%esp
	if (cpu_onboot()) {
  105b4a:	e8 bc 00 00 00       	call   105c0b <cpu_onboot>
  105b4f:	85 c0                	test   %eax,%eax
  105b51:	74 51                	je     105ba4 <pmap_init+0x60>
		// Initialize pmap_bootpdir, the bootstrap page directory.
		// Page directory entries (PDEs) corresponding to the 
		// user-mode address space between VM_USERLO and VM_USERHI
		// should all be initialized to PTE_ZERO (see kern/pmap.h).
		// All virtual addresses below and above this user area
		// should be identity-mapped to the same physical addresses,
		// but only accessible in kernel mode (not in user mode).
		// The easiest way to do this is to use 4MB page mappings.
		// Since these page mappings never change on context switches,
		// we can also mark them global (PTE_G) so the processor
		// doesn't flush these mappings when we reload the PDBR.
		//panic("pmap_init() not implemented");

    int i;
    for (i = 0; i < NPDENTRIES; i++)
  105b53:	c7 45 e8 00 00 00 00 	movl   $0x0,0xffffffe8(%ebp)
  105b5a:	eb 19                	jmp    105b75 <pmap_init+0x31>
    pmap_bootpdir[i] = (i << PDXSHIFT)
  105b5c:	8b 55 e8             	mov    0xffffffe8(%ebp),%edx
  105b5f:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  105b62:	c1 e0 16             	shl    $0x16,%eax
  105b65:	0d 83 01 00 00       	or     $0x183,%eax
  105b6a:	89 04 95 00 00 18 00 	mov    %eax,0x180000(,%edx,4)
  105b71:	83 45 e8 01          	addl   $0x1,0xffffffe8(%ebp)
  105b75:	81 7d e8 ff 03 00 00 	cmpl   $0x3ff,0xffffffe8(%ebp)
  105b7c:	7e de                	jle    105b5c <pmap_init+0x18>
      | PTE_P | PTE_W | PTE_PS | PTE_G;
    for (i = PDX(VM_USERLO); i < PDX(VM_USERHI); i++)
  105b7e:	c7 45 e8 00 01 00 00 	movl   $0x100,0xffffffe8(%ebp)
  105b85:	eb 13                	jmp    105b9a <pmap_init+0x56>
    pmap_bootpdir[i] = PTE_ZERO;
  105b87:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  105b8a:	ba 00 10 18 00       	mov    $0x181000,%edx
  105b8f:	89 14 85 00 00 18 00 	mov    %edx,0x180000(,%eax,4)
  105b96:	83 45 e8 01          	addl   $0x1,0xffffffe8(%ebp)
  105b9a:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  105b9d:	3d bf 03 00 00       	cmp    $0x3bf,%eax
  105ba2:	76 e3                	jbe    105b87 <pmap_init+0x43>
static gcc_inline uint32_t
rcr4(void)
{
	uint32_t cr4;
	__asm __volatile("movl %%cr4,%0" : "=r" (cr4));
  105ba4:	0f 20 e0             	mov    %cr4,%eax
  105ba7:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
	return cr4;
  105baa:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
	}

	// On x86, segmentation maps a VA to a LA (linear addr) and
	// paging maps the LA to a PA.  i.e., VA => LA => PA.  If paging is
	// turned off the LA is used as the PA.  There is no way to
	// turn off segmentation.  At the moment we turn on paging,
	// the code we're executing must be in an identity-mapped memory area
	// where LA == PA according to the page mapping structures.
	// In PIOS this is always the case for the kernel's address space,
	// so we don't have to play any special tricks as in other kernels.

	// Enable 4MB pages and global pages.
	uint32_t cr4 = rcr4();
  105bad:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)
	cr4 |= CR4_PSE | CR4_PGE;
  105bb0:	81 4d e0 90 00 00 00 	orl    $0x90,0xffffffe0(%ebp)
  cr4 |= CR4_OSFXSR | CR4_OSXMMEXCPT;
  105bb7:	81 4d e0 00 06 00 00 	orl    $0x600,0xffffffe0(%ebp)
  105bbe:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  105bc1:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)

static gcc_inline void
lcr4(uint32_t val)
{
	__asm __volatile("movl %0,%%cr4" : : "r" (val));
  105bc4:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  105bc7:	0f 22 e0             	mov    %eax,%cr4
	lcr4(cr4);

	// Install the bootstrap page directory into the PDBR.
	lcr3(mem_phys(pmap_bootpdir));
  105bca:	b8 00 00 18 00       	mov    $0x180000,%eax
  105bcf:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)

static gcc_inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
  105bd2:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  105bd5:	0f 22 d8             	mov    %eax,%cr3
  105bd8:	0f 20 c0             	mov    %cr0,%eax
  105bdb:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  105bde:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax

	// Turn on paging.
	uint32_t cr0 = rcr0();
  105be1:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_TS|CR0_MP|CR0_TS;
  105be4:	81 4d e4 2b 00 05 80 	orl    $0x8005002b,0xffffffe4(%ebp)
	cr0 &= ~(CR0_EM);
  105beb:	83 65 e4 fb          	andl   $0xfffffffb,0xffffffe4(%ebp)
  105bef:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  105bf2:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)

static gcc_inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
  105bf5:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  105bf8:	0f 22 c0             	mov    %eax,%cr0
	lcr0(cr0);

	// If we survived the lcr0, we're running with paging enabled.
	// Now check the page table management functions below.
	if (cpu_onboot())
  105bfb:	e8 0b 00 00 00       	call   105c0b <cpu_onboot>
  105c00:	85 c0                	test   %eax,%eax
  105c02:	74 05                	je     105c09 <pmap_init+0xc5>
		pmap_check();
  105c04:	e8 1c 26 00 00       	call   108225 <pmap_check>
}
  105c09:	c9                   	leave  
  105c0a:	c3                   	ret    

00105c0b <cpu_onboot>:
}

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  105c0b:	55                   	push   %ebp
  105c0c:	89 e5                	mov    %esp,%ebp
  105c0e:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  105c11:	e8 0d 00 00 00       	call   105c23 <cpu_cur>
  105c16:	3d 00 e0 10 00       	cmp    $0x10e000,%eax
  105c1b:	0f 94 c0             	sete   %al
  105c1e:	0f b6 c0             	movzbl %al,%eax
}
  105c21:	c9                   	leave  
  105c22:	c3                   	ret    

00105c23 <cpu_cur>:
  105c23:	55                   	push   %ebp
  105c24:	89 e5                	mov    %esp,%ebp
  105c26:	83 ec 28             	sub    $0x28,%esp
static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  105c29:	89 65 fc             	mov    %esp,0xfffffffc(%ebp)
        return esp;
  105c2c:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  105c2f:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  105c32:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  105c35:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  105c3a:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	assert(c->magic == CPU_MAGIC);
  105c3d:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  105c40:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  105c46:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  105c4b:	74 24                	je     105c71 <cpu_cur+0x4e>
  105c4d:	c7 44 24 0c b0 ce 10 	movl   $0x10ceb0,0xc(%esp)
  105c54:	00 
  105c55:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  105c5c:	00 
  105c5d:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  105c64:	00 
  105c65:	c7 04 24 db ce 10 00 	movl   $0x10cedb,(%esp)
  105c6c:	e8 c7 ac ff ff       	call   100938 <debug_panic>
	return c;
  105c71:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
}
  105c74:	c9                   	leave  
  105c75:	c3                   	ret    

00105c76 <pmap_newpdir>:

//
// Allocate a new page directory, initialized from the bootstrap pdir.
// Returns the new pdir with a reference count of 1.
//
pte_t *
pmap_newpdir(void)
{
  105c76:	55                   	push   %ebp
  105c77:	89 e5                	mov    %esp,%ebp
  105c79:	83 ec 28             	sub    $0x28,%esp
	pageinfo *pi = mem_alloc();
  105c7c:	e8 9a b3 ff ff       	call   10101b <mem_alloc>
  105c81:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	if (pi == NULL)
  105c84:	83 7d f4 00          	cmpl   $0x0,0xfffffff4(%ebp)
  105c88:	75 0c                	jne    105c96 <pmap_newpdir+0x20>
		return NULL;
  105c8a:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  105c91:	e9 2f 01 00 00       	jmp    105dc5 <pmap_newpdir+0x14f>
  105c96:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  105c99:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
// Atomically increment the reference count on a page.
static gcc_inline void
mem_incref(pageinfo *pi)
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  105c9c:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  105ca1:	83 c0 08             	add    $0x8,%eax
  105ca4:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  105ca7:	73 17                	jae    105cc0 <pmap_newpdir+0x4a>
  105ca9:	a1 84 ed 17 00       	mov    0x17ed84,%eax
  105cae:	c1 e0 03             	shl    $0x3,%eax
  105cb1:	89 c2                	mov    %eax,%edx
  105cb3:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  105cb8:	8d 04 02             	lea    (%edx,%eax,1),%eax
  105cbb:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  105cbe:	77 24                	ja     105ce4 <pmap_newpdir+0x6e>
  105cc0:	c7 44 24 0c e8 ce 10 	movl   $0x10cee8,0xc(%esp)
  105cc7:	00 
  105cc8:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  105ccf:	00 
  105cd0:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
  105cd7:	00 
  105cd8:	c7 04 24 1f cf 10 00 	movl   $0x10cf1f,(%esp)
  105cdf:	e8 54 ac ff ff       	call   100938 <debug_panic>
	assert(pi != mem_ptr2pi(pmap_zero));	// Don't alloc/free zero page!
  105ce4:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  105cea:	b8 00 10 18 00       	mov    $0x181000,%eax
  105cef:	c1 e8 0c             	shr    $0xc,%eax
  105cf2:	c1 e0 03             	shl    $0x3,%eax
  105cf5:	8d 04 02             	lea    (%edx,%eax,1),%eax
  105cf8:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  105cfb:	75 24                	jne    105d21 <pmap_newpdir+0xab>
  105cfd:	c7 44 24 0c 2c cf 10 	movl   $0x10cf2c,0xc(%esp)
  105d04:	00 
  105d05:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  105d0c:	00 
  105d0d:	c7 44 24 04 59 00 00 	movl   $0x59,0x4(%esp)
  105d14:	00 
  105d15:	c7 04 24 1f cf 10 00 	movl   $0x10cf1f,(%esp)
  105d1c:	e8 17 ac ff ff       	call   100938 <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  105d21:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  105d27:	b8 0c 00 10 00       	mov    $0x10000c,%eax
  105d2c:	c1 e8 0c             	shr    $0xc,%eax
  105d2f:	c1 e0 03             	shl    $0x3,%eax
  105d32:	8d 04 02             	lea    (%edx,%eax,1),%eax
  105d35:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  105d38:	77 40                	ja     105d7a <pmap_newpdir+0x104>
  105d3a:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  105d40:	b8 08 20 18 00       	mov    $0x182008,%eax
  105d45:	83 e8 01             	sub    $0x1,%eax
  105d48:	c1 e8 0c             	shr    $0xc,%eax
  105d4b:	c1 e0 03             	shl    $0x3,%eax
  105d4e:	8d 04 02             	lea    (%edx,%eax,1),%eax
  105d51:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  105d54:	72 24                	jb     105d7a <pmap_newpdir+0x104>
  105d56:	c7 44 24 0c 48 cf 10 	movl   $0x10cf48,0xc(%esp)
  105d5d:	00 
  105d5e:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  105d65:	00 
  105d66:	c7 44 24 04 5a 00 00 	movl   $0x5a,0x4(%esp)
  105d6d:	00 
  105d6e:	c7 04 24 1f cf 10 00 	movl   $0x10cf1f,(%esp)
  105d75:	e8 be ab ff ff       	call   100938 <debug_panic>

	lockadd(&pi->refcount, 1);
  105d7a:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  105d7d:	83 c0 04             	add    $0x4,%eax
  105d80:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  105d87:	00 
  105d88:	89 04 24             	mov    %eax,(%esp)
  105d8b:	e8 3a 00 00 00       	call   105dca <lockadd>
	mem_incref(pi);
	pte_t *pdir = mem_pi2ptr(pi);
  105d90:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  105d93:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  105d98:	89 d1                	mov    %edx,%ecx
  105d9a:	29 c1                	sub    %eax,%ecx
  105d9c:	89 c8                	mov    %ecx,%eax
  105d9e:	c1 e0 09             	shl    $0x9,%eax
  105da1:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)

	// Initialize it from the bootstrap page directory
	assert(sizeof(pmap_bootpdir) == PAGESIZE);
	memmove(pdir, pmap_bootpdir, PAGESIZE);
  105da4:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  105dab:	00 
  105dac:	c7 44 24 04 00 00 18 	movl   $0x180000,0x4(%esp)
  105db3:	00 
  105db4:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  105db7:	89 04 24             	mov    %eax,(%esp)
  105dba:	e8 c3 5a 00 00       	call   10b882 <memmove>

	return pdir;
  105dbf:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  105dc2:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  105dc5:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
}
  105dc8:	c9                   	leave  
  105dc9:	c3                   	ret    

00105dca <lockadd>:

// Atomically add incr to *addr.
static inline void
lockadd(volatile int32_t *addr, int32_t incr)
{
  105dca:	55                   	push   %ebp
  105dcb:	89 e5                	mov    %esp,%ebp
	asm volatile("lock; addl %1,%0" : "+m" (*addr) : "r" (incr) : "cc");
  105dcd:	8b 4d 08             	mov    0x8(%ebp),%ecx
  105dd0:	8b 55 0c             	mov    0xc(%ebp),%edx
  105dd3:	8b 45 08             	mov    0x8(%ebp),%eax
  105dd6:	f0 01 11             	lock add %edx,(%ecx)
}
  105dd9:	5d                   	pop    %ebp
  105dda:	c3                   	ret    

00105ddb <pmap_freepdir>:

// Free a page directory, and all page tables and mappings it may contain.
void
pmap_freepdir(pageinfo *pdirpi)
{
  105ddb:	55                   	push   %ebp
  105ddc:	89 e5                	mov    %esp,%ebp
  105dde:	83 ec 18             	sub    $0x18,%esp
	pmap_remove(mem_pi2ptr(pdirpi), VM_USERLO, VM_USERHI-VM_USERLO);
  105de1:	8b 55 08             	mov    0x8(%ebp),%edx
  105de4:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  105de9:	89 d1                	mov    %edx,%ecx
  105deb:	29 c1                	sub    %eax,%ecx
  105ded:	89 c8                	mov    %ecx,%eax
  105def:	c1 e0 09             	shl    $0x9,%eax
  105df2:	c7 44 24 08 00 00 00 	movl   $0xb0000000,0x8(%esp)
  105df9:	b0 
  105dfa:	c7 44 24 04 00 00 00 	movl   $0x40000000,0x4(%esp)
  105e01:	40 
  105e02:	89 04 24             	mov    %eax,(%esp)
  105e05:	e8 0f 0a 00 00       	call   106819 <pmap_remove>
	mem_free(pdirpi);
  105e0a:	8b 45 08             	mov    0x8(%ebp),%eax
  105e0d:	89 04 24             	mov    %eax,(%esp)
  105e10:	e8 4a b2 ff ff       	call   10105f <mem_free>
}
  105e15:	c9                   	leave  
  105e16:	c3                   	ret    

00105e17 <pmap_freeptab>:

// Free a page table and all page mappings it may contain.
void
pmap_freeptab(pageinfo *ptabpi)
{
  105e17:	55                   	push   %ebp
  105e18:	89 e5                	mov    %esp,%ebp
  105e1a:	83 ec 38             	sub    $0x38,%esp
	pte_t *pte = mem_pi2ptr(ptabpi), *ptelim = pte + NPTENTRIES;
  105e1d:	8b 55 08             	mov    0x8(%ebp),%edx
  105e20:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  105e25:	89 d1                	mov    %edx,%ecx
  105e27:	29 c1                	sub    %eax,%ecx
  105e29:	89 c8                	mov    %ecx,%eax
  105e2b:	c1 e0 09             	shl    $0x9,%eax
  105e2e:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  105e31:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  105e34:	05 00 10 00 00       	add    $0x1000,%eax
  105e39:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
	for (; pte < ptelim; pte++) {
  105e3c:	e9 6d 01 00 00       	jmp    105fae <pmap_freeptab+0x197>
		uint32_t pgaddr = PGADDR(*pte);
  105e41:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  105e44:	8b 00                	mov    (%eax),%eax
  105e46:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  105e4b:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
		if (pgaddr != PTE_ZERO)
  105e4e:	b8 00 10 18 00       	mov    $0x181000,%eax
  105e53:	39 45 f4             	cmp    %eax,0xfffffff4(%ebp)
  105e56:	0f 84 4e 01 00 00    	je     105faa <pmap_freeptab+0x193>
			mem_decref(mem_phys2pi(pgaddr), mem_free);
  105e5c:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  105e5f:	c1 e8 0c             	shr    $0xc,%eax
  105e62:	c1 e0 03             	shl    $0x3,%eax
  105e65:	89 c2                	mov    %eax,%edx
  105e67:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  105e6c:	8d 04 02             	lea    (%edx,%eax,1),%eax
  105e6f:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  105e72:	c7 45 f8 5f 10 10 00 	movl   $0x10105f,0xfffffff8(%ebp)
// freeing the page with the provided function if there are no more refs.
static gcc_inline void
mem_decref(pageinfo* pi, void (*freefun)(pageinfo *pi))
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  105e79:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  105e7e:	83 c0 08             	add    $0x8,%eax
  105e81:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  105e84:	73 17                	jae    105e9d <pmap_freeptab+0x86>
  105e86:	a1 84 ed 17 00       	mov    0x17ed84,%eax
  105e8b:	c1 e0 03             	shl    $0x3,%eax
  105e8e:	89 c2                	mov    %eax,%edx
  105e90:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  105e95:	8d 04 02             	lea    (%edx,%eax,1),%eax
  105e98:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  105e9b:	77 24                	ja     105ec1 <pmap_freeptab+0xaa>
  105e9d:	c7 44 24 0c e8 ce 10 	movl   $0x10cee8,0xc(%esp)
  105ea4:	00 
  105ea5:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  105eac:	00 
  105ead:	c7 44 24 04 64 00 00 	movl   $0x64,0x4(%esp)
  105eb4:	00 
  105eb5:	c7 04 24 1f cf 10 00 	movl   $0x10cf1f,(%esp)
  105ebc:	e8 77 aa ff ff       	call   100938 <debug_panic>
	assert(pi != mem_ptr2pi(pmap_zero));	// Don't alloc/free zero page!
  105ec1:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  105ec7:	b8 00 10 18 00       	mov    $0x181000,%eax
  105ecc:	c1 e8 0c             	shr    $0xc,%eax
  105ecf:	c1 e0 03             	shl    $0x3,%eax
  105ed2:	8d 04 02             	lea    (%edx,%eax,1),%eax
  105ed5:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  105ed8:	75 24                	jne    105efe <pmap_freeptab+0xe7>
  105eda:	c7 44 24 0c 2c cf 10 	movl   $0x10cf2c,0xc(%esp)
  105ee1:	00 
  105ee2:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  105ee9:	00 
  105eea:	c7 44 24 04 65 00 00 	movl   $0x65,0x4(%esp)
  105ef1:	00 
  105ef2:	c7 04 24 1f cf 10 00 	movl   $0x10cf1f,(%esp)
  105ef9:	e8 3a aa ff ff       	call   100938 <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  105efe:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  105f04:	b8 0c 00 10 00       	mov    $0x10000c,%eax
  105f09:	c1 e8 0c             	shr    $0xc,%eax
  105f0c:	c1 e0 03             	shl    $0x3,%eax
  105f0f:	8d 04 02             	lea    (%edx,%eax,1),%eax
  105f12:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  105f15:	77 40                	ja     105f57 <pmap_freeptab+0x140>
  105f17:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  105f1d:	b8 08 20 18 00       	mov    $0x182008,%eax
  105f22:	83 e8 01             	sub    $0x1,%eax
  105f25:	c1 e8 0c             	shr    $0xc,%eax
  105f28:	c1 e0 03             	shl    $0x3,%eax
  105f2b:	8d 04 02             	lea    (%edx,%eax,1),%eax
  105f2e:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  105f31:	72 24                	jb     105f57 <pmap_freeptab+0x140>
  105f33:	c7 44 24 0c 48 cf 10 	movl   $0x10cf48,0xc(%esp)
  105f3a:	00 
  105f3b:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  105f42:	00 
  105f43:	c7 44 24 04 66 00 00 	movl   $0x66,0x4(%esp)
  105f4a:	00 
  105f4b:	c7 04 24 1f cf 10 00 	movl   $0x10cf1f,(%esp)
  105f52:	e8 e1 a9 ff ff       	call   100938 <debug_panic>

	if (lockaddz(&pi->refcount, -1))
  105f57:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  105f5a:	83 c0 04             	add    $0x4,%eax
  105f5d:	c7 44 24 04 ff ff ff 	movl   $0xffffffff,0x4(%esp)
  105f64:	ff 
  105f65:	89 04 24             	mov    %eax,(%esp)
  105f68:	e8 5a 00 00 00       	call   105fc7 <lockaddz>
  105f6d:	84 c0                	test   %al,%al
  105f6f:	74 0b                	je     105f7c <pmap_freeptab+0x165>
			freefun(pi);
  105f71:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  105f74:	89 04 24             	mov    %eax,(%esp)
  105f77:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  105f7a:	ff d0                	call   *%eax
	assert(pi->refcount >= 0);
  105f7c:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  105f7f:	8b 40 04             	mov    0x4(%eax),%eax
  105f82:	85 c0                	test   %eax,%eax
  105f84:	79 24                	jns    105faa <pmap_freeptab+0x193>
  105f86:	c7 44 24 0c 79 cf 10 	movl   $0x10cf79,0xc(%esp)
  105f8d:	00 
  105f8e:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  105f95:	00 
  105f96:	c7 44 24 04 6a 00 00 	movl   $0x6a,0x4(%esp)
  105f9d:	00 
  105f9e:	c7 04 24 1f cf 10 00 	movl   $0x10cf1f,(%esp)
  105fa5:	e8 8e a9 ff ff       	call   100938 <debug_panic>
  105faa:	83 45 ec 04          	addl   $0x4,0xffffffec(%ebp)
  105fae:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  105fb1:	3b 45 f0             	cmp    0xfffffff0(%ebp),%eax
  105fb4:	0f 82 87 fe ff ff    	jb     105e41 <pmap_freeptab+0x2a>
	}
	mem_free(ptabpi);
  105fba:	8b 45 08             	mov    0x8(%ebp),%eax
  105fbd:	89 04 24             	mov    %eax,(%esp)
  105fc0:	e8 9a b0 ff ff       	call   10105f <mem_free>
}
  105fc5:	c9                   	leave  
  105fc6:	c3                   	ret    

00105fc7 <lockaddz>:

// Atomically add incr to *addr and return true if the result is zero.
static inline uint8_t
lockaddz(volatile int32_t *addr, int32_t incr)
{
  105fc7:	55                   	push   %ebp
  105fc8:	89 e5                	mov    %esp,%ebp
  105fca:	83 ec 10             	sub    $0x10,%esp
	uint8_t zero;
	asm volatile("lock; addl %2,%0; setzb %1"
  105fcd:	8b 4d 08             	mov    0x8(%ebp),%ecx
  105fd0:	8b 55 0c             	mov    0xc(%ebp),%edx
  105fd3:	8b 45 08             	mov    0x8(%ebp),%eax
  105fd6:	f0 01 11             	lock add %edx,(%ecx)
  105fd9:	0f 94 45 ff          	sete   0xffffffff(%ebp)
		: "+m" (*addr), "=rm" (zero)
		: "r" (incr)
		: "cc");
	return zero;
  105fdd:	0f b6 45 ff          	movzbl 0xffffffff(%ebp),%eax
}
  105fe1:	c9                   	leave  
  105fe2:	c3                   	ret    

00105fe3 <pmap_walk>:

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
  105fe3:	55                   	push   %ebp
  105fe4:	89 e5                	mov    %esp,%ebp
  105fe6:	83 ec 58             	sub    $0x58,%esp
	assert(va >= VM_USERLO && va < VM_USERHI);
  105fe9:	81 7d 0c ff ff ff 3f 	cmpl   $0x3fffffff,0xc(%ebp)
  105ff0:	76 09                	jbe    105ffb <pmap_walk+0x18>
  105ff2:	81 7d 0c ff ff ff ef 	cmpl   $0xefffffff,0xc(%ebp)
  105ff9:	76 24                	jbe    10601f <pmap_walk+0x3c>
  105ffb:	c7 44 24 0c 8c cf 10 	movl   $0x10cf8c,0xc(%esp)
  106002:	00 
  106003:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  10600a:	00 
  10600b:	c7 44 24 04 a9 00 00 	movl   $0xa9,0x4(%esp)
  106012:	00 
  106013:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  10601a:	e8 19 a9 ff ff       	call   100938 <debug_panic>

  uint32_t la = va;
  10601f:	8b 45 0c             	mov    0xc(%ebp),%eax
  106022:	89 45 c4             	mov    %eax,0xffffffc4(%ebp)
  pde_t *pde = &pdir[PDX(la)];
  106025:	8b 45 c4             	mov    0xffffffc4(%ebp),%eax
  106028:	c1 e8 16             	shr    $0x16,%eax
  10602b:	25 ff 03 00 00       	and    $0x3ff,%eax
  106030:	c1 e0 02             	shl    $0x2,%eax
  106033:	03 45 08             	add    0x8(%ebp),%eax
  106036:	89 45 c8             	mov    %eax,0xffffffc8(%ebp)
  pte_t *ptab;
  if (*pde & PTE_P){
  106039:	8b 45 c8             	mov    0xffffffc8(%ebp),%eax
  10603c:	8b 00                	mov    (%eax),%eax
  10603e:	83 e0 01             	and    $0x1,%eax
  106041:	84 c0                	test   %al,%al
  106043:	74 12                	je     106057 <pmap_walk+0x74>
  ptab = mem_ptr(PGADDR(*pde));
  106045:	8b 45 c8             	mov    0xffffffc8(%ebp),%eax
  106048:	8b 00                	mov    (%eax),%eax
  10604a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  10604f:	89 45 cc             	mov    %eax,0xffffffcc(%ebp)
  106052:	e9 a3 01 00 00       	jmp    1061fa <pmap_walk+0x217>
  } else {
  assert(*pde == PTE_ZERO);
  106057:	8b 45 c8             	mov    0xffffffc8(%ebp),%eax
  10605a:	8b 10                	mov    (%eax),%edx
  10605c:	b8 00 10 18 00       	mov    $0x181000,%eax
  106061:	39 c2                	cmp    %eax,%edx
  106063:	74 24                	je     106089 <pmap_walk+0xa6>
  106065:	c7 44 24 0c ba cf 10 	movl   $0x10cfba,0xc(%esp)
  10606c:	00 
  10606d:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  106074:	00 
  106075:	c7 44 24 04 b1 00 00 	movl   $0xb1,0x4(%esp)
  10607c:	00 
  10607d:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  106084:	e8 af a8 ff ff       	call   100938 <debug_panic>
  pageinfo *pi;
  if (!writing || (pi = mem_alloc()) == NULL)
  106089:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  10608d:	74 0e                	je     10609d <pmap_walk+0xba>
  10608f:	e8 87 af ff ff       	call   10101b <mem_alloc>
  106094:	89 45 d0             	mov    %eax,0xffffffd0(%ebp)
  106097:	83 7d d0 00          	cmpl   $0x0,0xffffffd0(%ebp)
  10609b:	75 0c                	jne    1060a9 <pmap_walk+0xc6>
  return NULL;
  10609d:	c7 45 bc 00 00 00 00 	movl   $0x0,0xffffffbc(%ebp)
  1060a4:	e9 ed 05 00 00       	jmp    106696 <pmap_walk+0x6b3>
  1060a9:	8b 45 d0             	mov    0xffffffd0(%ebp),%eax
  1060ac:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
// Atomically increment the reference count on a page.
static gcc_inline void
mem_incref(pageinfo *pi)
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  1060af:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  1060b4:	83 c0 08             	add    $0x8,%eax
  1060b7:	3b 45 ec             	cmp    0xffffffec(%ebp),%eax
  1060ba:	73 17                	jae    1060d3 <pmap_walk+0xf0>
  1060bc:	a1 84 ed 17 00       	mov    0x17ed84,%eax
  1060c1:	c1 e0 03             	shl    $0x3,%eax
  1060c4:	89 c2                	mov    %eax,%edx
  1060c6:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  1060cb:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1060ce:	3b 45 ec             	cmp    0xffffffec(%ebp),%eax
  1060d1:	77 24                	ja     1060f7 <pmap_walk+0x114>
  1060d3:	c7 44 24 0c e8 ce 10 	movl   $0x10cee8,0xc(%esp)
  1060da:	00 
  1060db:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  1060e2:	00 
  1060e3:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
  1060ea:	00 
  1060eb:	c7 04 24 1f cf 10 00 	movl   $0x10cf1f,(%esp)
  1060f2:	e8 41 a8 ff ff       	call   100938 <debug_panic>
	assert(pi != mem_ptr2pi(pmap_zero));	// Don't alloc/free zero page!
  1060f7:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  1060fd:	b8 00 10 18 00       	mov    $0x181000,%eax
  106102:	c1 e8 0c             	shr    $0xc,%eax
  106105:	c1 e0 03             	shl    $0x3,%eax
  106108:	8d 04 02             	lea    (%edx,%eax,1),%eax
  10610b:	3b 45 ec             	cmp    0xffffffec(%ebp),%eax
  10610e:	75 24                	jne    106134 <pmap_walk+0x151>
  106110:	c7 44 24 0c 2c cf 10 	movl   $0x10cf2c,0xc(%esp)
  106117:	00 
  106118:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  10611f:	00 
  106120:	c7 44 24 04 59 00 00 	movl   $0x59,0x4(%esp)
  106127:	00 
  106128:	c7 04 24 1f cf 10 00 	movl   $0x10cf1f,(%esp)
  10612f:	e8 04 a8 ff ff       	call   100938 <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  106134:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  10613a:	b8 0c 00 10 00       	mov    $0x10000c,%eax
  10613f:	c1 e8 0c             	shr    $0xc,%eax
  106142:	c1 e0 03             	shl    $0x3,%eax
  106145:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106148:	3b 45 ec             	cmp    0xffffffec(%ebp),%eax
  10614b:	77 40                	ja     10618d <pmap_walk+0x1aa>
  10614d:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  106153:	b8 08 20 18 00       	mov    $0x182008,%eax
  106158:	83 e8 01             	sub    $0x1,%eax
  10615b:	c1 e8 0c             	shr    $0xc,%eax
  10615e:	c1 e0 03             	shl    $0x3,%eax
  106161:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106164:	3b 45 ec             	cmp    0xffffffec(%ebp),%eax
  106167:	72 24                	jb     10618d <pmap_walk+0x1aa>
  106169:	c7 44 24 0c 48 cf 10 	movl   $0x10cf48,0xc(%esp)
  106170:	00 
  106171:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  106178:	00 
  106179:	c7 44 24 04 5a 00 00 	movl   $0x5a,0x4(%esp)
  106180:	00 
  106181:	c7 04 24 1f cf 10 00 	movl   $0x10cf1f,(%esp)
  106188:	e8 ab a7 ff ff       	call   100938 <debug_panic>

	lockadd(&pi->refcount, 1);
  10618d:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  106190:	83 c0 04             	add    $0x4,%eax
  106193:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  10619a:	00 
  10619b:	89 04 24             	mov    %eax,(%esp)
  10619e:	e8 27 fc ff ff       	call   105dca <lockadd>
  mem_incref(pi);
  ptab = mem_pi2ptr(pi);
  1061a3:	8b 55 d0             	mov    0xffffffd0(%ebp),%edx
  1061a6:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  1061ab:	89 d1                	mov    %edx,%ecx
  1061ad:	29 c1                	sub    %eax,%ecx
  1061af:	89 c8                	mov    %ecx,%eax
  1061b1:	c1 e0 09             	shl    $0x9,%eax
  1061b4:	89 45 cc             	mov    %eax,0xffffffcc(%ebp)

  int i;
  for (i = 0; i < NPTENTRIES; i++)
  1061b7:	c7 45 d4 00 00 00 00 	movl   $0x0,0xffffffd4(%ebp)
  1061be:	eb 16                	jmp    1061d6 <pmap_walk+0x1f3>
  ptab[i] = PTE_ZERO;
  1061c0:	8b 45 d4             	mov    0xffffffd4(%ebp),%eax
  1061c3:	c1 e0 02             	shl    $0x2,%eax
  1061c6:	89 c2                	mov    %eax,%edx
  1061c8:	03 55 cc             	add    0xffffffcc(%ebp),%edx
  1061cb:	b8 00 10 18 00       	mov    $0x181000,%eax
  1061d0:	89 02                	mov    %eax,(%edx)
  1061d2:	83 45 d4 01          	addl   $0x1,0xffffffd4(%ebp)
  1061d6:	81 7d d4 ff 03 00 00 	cmpl   $0x3ff,0xffffffd4(%ebp)
  1061dd:	7e e1                	jle    1061c0 <pmap_walk+0x1dd>

  *pde = mem_pi2phys(pi) | PTE_A | PTE_P | PTE_W | PTE_U;
  1061df:	8b 55 d0             	mov    0xffffffd0(%ebp),%edx
  1061e2:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  1061e7:	89 d1                	mov    %edx,%ecx
  1061e9:	29 c1                	sub    %eax,%ecx
  1061eb:	89 c8                	mov    %ecx,%eax
  1061ed:	c1 e0 09             	shl    $0x9,%eax
  1061f0:	83 c8 27             	or     $0x27,%eax
  1061f3:	89 c2                	mov    %eax,%edx
  1061f5:	8b 45 c8             	mov    0xffffffc8(%ebp),%eax
  1061f8:	89 10                	mov    %edx,(%eax)
  }
  
  if(writing && !(*pde & PTE_W)) {
  1061fa:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  1061fe:	0f 84 7c 04 00 00    	je     106680 <pmap_walk+0x69d>
  106204:	8b 45 c8             	mov    0xffffffc8(%ebp),%eax
  106207:	8b 00                	mov    (%eax),%eax
  106209:	83 e0 02             	and    $0x2,%eax
  10620c:	85 c0                	test   %eax,%eax
  10620e:	0f 85 6c 04 00 00    	jne    106680 <pmap_walk+0x69d>
  if(mem_ptr2pi(ptab) -> refcount == 1){
  106214:	8b 45 cc             	mov    0xffffffcc(%ebp),%eax
  106217:	c1 e8 0c             	shr    $0xc,%eax
  10621a:	c1 e0 03             	shl    $0x3,%eax
  10621d:	89 c2                	mov    %eax,%edx
  10621f:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  106224:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106227:	8b 40 04             	mov    0x4(%eax),%eax
  10622a:	83 f8 01             	cmp    $0x1,%eax
  10622d:	75 36                	jne    106265 <pmap_walk+0x282>
  int i;
  for (i = 0; i < NPTENTRIES; i++)
  10622f:	c7 45 d8 00 00 00 00 	movl   $0x0,0xffffffd8(%ebp)
  106236:	eb 1f                	jmp    106257 <pmap_walk+0x274>
    ptab[i] &= ~PTE_W;
  106238:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  10623b:	c1 e0 02             	shl    $0x2,%eax
  10623e:	89 c2                	mov    %eax,%edx
  106240:	03 55 cc             	add    0xffffffcc(%ebp),%edx
  106243:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  106246:	c1 e0 02             	shl    $0x2,%eax
  106249:	03 45 cc             	add    0xffffffcc(%ebp),%eax
  10624c:	8b 00                	mov    (%eax),%eax
  10624e:	83 e0 fd             	and    $0xfffffffd,%eax
  106251:	89 02                	mov    %eax,(%edx)
  106253:	83 45 d8 01          	addl   $0x1,0xffffffd8(%ebp)
  106257:	81 7d d8 ff 03 00 00 	cmpl   $0x3ff,0xffffffd8(%ebp)
  10625e:	7e d8                	jle    106238 <pmap_walk+0x255>
  106260:	e9 0e 04 00 00       	jmp    106673 <pmap_walk+0x690>
    } else {
    pageinfo *pi = mem_alloc();
  106265:	e8 b1 ad ff ff       	call   10101b <mem_alloc>
  10626a:	89 45 dc             	mov    %eax,0xffffffdc(%ebp)
    if (pi==NULL)
  10626d:	83 7d dc 00          	cmpl   $0x0,0xffffffdc(%ebp)
  106271:	75 0c                	jne    10627f <pmap_walk+0x29c>
    return NULL;
  106273:	c7 45 bc 00 00 00 00 	movl   $0x0,0xffffffbc(%ebp)
  10627a:	e9 17 04 00 00       	jmp    106696 <pmap_walk+0x6b3>
  10627f:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  106282:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
// Atomically increment the reference count on a page.
static gcc_inline void
mem_incref(pageinfo *pi)
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  106285:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  10628a:	83 c0 08             	add    $0x8,%eax
  10628d:	3b 45 f0             	cmp    0xfffffff0(%ebp),%eax
  106290:	73 17                	jae    1062a9 <pmap_walk+0x2c6>
  106292:	a1 84 ed 17 00       	mov    0x17ed84,%eax
  106297:	c1 e0 03             	shl    $0x3,%eax
  10629a:	89 c2                	mov    %eax,%edx
  10629c:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  1062a1:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1062a4:	3b 45 f0             	cmp    0xfffffff0(%ebp),%eax
  1062a7:	77 24                	ja     1062cd <pmap_walk+0x2ea>
  1062a9:	c7 44 24 0c e8 ce 10 	movl   $0x10cee8,0xc(%esp)
  1062b0:	00 
  1062b1:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  1062b8:	00 
  1062b9:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
  1062c0:	00 
  1062c1:	c7 04 24 1f cf 10 00 	movl   $0x10cf1f,(%esp)
  1062c8:	e8 6b a6 ff ff       	call   100938 <debug_panic>
	assert(pi != mem_ptr2pi(pmap_zero));	// Don't alloc/free zero page!
  1062cd:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  1062d3:	b8 00 10 18 00       	mov    $0x181000,%eax
  1062d8:	c1 e8 0c             	shr    $0xc,%eax
  1062db:	c1 e0 03             	shl    $0x3,%eax
  1062de:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1062e1:	3b 45 f0             	cmp    0xfffffff0(%ebp),%eax
  1062e4:	75 24                	jne    10630a <pmap_walk+0x327>
  1062e6:	c7 44 24 0c 2c cf 10 	movl   $0x10cf2c,0xc(%esp)
  1062ed:	00 
  1062ee:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  1062f5:	00 
  1062f6:	c7 44 24 04 59 00 00 	movl   $0x59,0x4(%esp)
  1062fd:	00 
  1062fe:	c7 04 24 1f cf 10 00 	movl   $0x10cf1f,(%esp)
  106305:	e8 2e a6 ff ff       	call   100938 <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  10630a:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  106310:	b8 0c 00 10 00       	mov    $0x10000c,%eax
  106315:	c1 e8 0c             	shr    $0xc,%eax
  106318:	c1 e0 03             	shl    $0x3,%eax
  10631b:	8d 04 02             	lea    (%edx,%eax,1),%eax
  10631e:	3b 45 f0             	cmp    0xfffffff0(%ebp),%eax
  106321:	77 40                	ja     106363 <pmap_walk+0x380>
  106323:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  106329:	b8 08 20 18 00       	mov    $0x182008,%eax
  10632e:	83 e8 01             	sub    $0x1,%eax
  106331:	c1 e8 0c             	shr    $0xc,%eax
  106334:	c1 e0 03             	shl    $0x3,%eax
  106337:	8d 04 02             	lea    (%edx,%eax,1),%eax
  10633a:	3b 45 f0             	cmp    0xfffffff0(%ebp),%eax
  10633d:	72 24                	jb     106363 <pmap_walk+0x380>
  10633f:	c7 44 24 0c 48 cf 10 	movl   $0x10cf48,0xc(%esp)
  106346:	00 
  106347:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  10634e:	00 
  10634f:	c7 44 24 04 5a 00 00 	movl   $0x5a,0x4(%esp)
  106356:	00 
  106357:	c7 04 24 1f cf 10 00 	movl   $0x10cf1f,(%esp)
  10635e:	e8 d5 a5 ff ff       	call   100938 <debug_panic>

	lockadd(&pi->refcount, 1);
  106363:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  106366:	83 c0 04             	add    $0x4,%eax
  106369:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  106370:	00 
  106371:	89 04 24             	mov    %eax,(%esp)
  106374:	e8 51 fa ff ff       	call   105dca <lockadd>
    mem_incref(pi);
    pte_t *nptab = mem_pi2ptr(pi);
  106379:	8b 55 dc             	mov    0xffffffdc(%ebp),%edx
  10637c:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  106381:	89 d1                	mov    %edx,%ecx
  106383:	29 c1                	sub    %eax,%ecx
  106385:	89 c8                	mov    %ecx,%eax
  106387:	c1 e0 09             	shl    $0x9,%eax
  10638a:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)

    int i;
    for (i = 0; i < NPTENTRIES; i++){
  10638d:	c7 45 e4 00 00 00 00 	movl   $0x0,0xffffffe4(%ebp)
  106394:	e9 79 01 00 00       	jmp    106512 <pmap_walk+0x52f>
    uint32_t pte = ptab[i];
  106399:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  10639c:	c1 e0 02             	shl    $0x2,%eax
  10639f:	03 45 cc             	add    0xffffffcc(%ebp),%eax
  1063a2:	8b 00                	mov    (%eax),%eax
  1063a4:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
    nptab[i] = pte & ~PTE_W;
  1063a7:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  1063aa:	c1 e0 02             	shl    $0x2,%eax
  1063ad:	89 c2                	mov    %eax,%edx
  1063af:	03 55 e0             	add    0xffffffe0(%ebp),%edx
  1063b2:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  1063b5:	83 e0 fd             	and    $0xfffffffd,%eax
  1063b8:	89 02                	mov    %eax,(%edx)
    assert(PGADDR(pte) != 0);
  1063ba:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  1063bd:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1063c2:	85 c0                	test   %eax,%eax
  1063c4:	75 24                	jne    1063ea <pmap_walk+0x407>
  1063c6:	c7 44 24 0c cb cf 10 	movl   $0x10cfcb,0xc(%esp)
  1063cd:	00 
  1063ce:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  1063d5:	00 
  1063d6:	c7 44 24 04 cf 00 00 	movl   $0xcf,0x4(%esp)
  1063dd:	00 
  1063de:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  1063e5:	e8 4e a5 ff ff       	call   100938 <debug_panic>
    if (PGADDR(pte) != PTE_ZERO)
  1063ea:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  1063ed:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1063f2:	ba 00 10 18 00       	mov    $0x181000,%edx
  1063f7:	39 d0                	cmp    %edx,%eax
  1063f9:	0f 84 0f 01 00 00    	je     10650e <pmap_walk+0x52b>
    mem_incref(mem_phys2pi(PGADDR(pte)));
  1063ff:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  106402:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  106407:	c1 e8 0c             	shr    $0xc,%eax
  10640a:	c1 e0 03             	shl    $0x3,%eax
  10640d:	89 c2                	mov    %eax,%edx
  10640f:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  106414:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106417:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
// Atomically increment the reference count on a page.
static gcc_inline void
mem_incref(pageinfo *pi)
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  10641a:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  10641f:	83 c0 08             	add    $0x8,%eax
  106422:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  106425:	73 17                	jae    10643e <pmap_walk+0x45b>
  106427:	a1 84 ed 17 00       	mov    0x17ed84,%eax
  10642c:	c1 e0 03             	shl    $0x3,%eax
  10642f:	89 c2                	mov    %eax,%edx
  106431:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  106436:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106439:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  10643c:	77 24                	ja     106462 <pmap_walk+0x47f>
  10643e:	c7 44 24 0c e8 ce 10 	movl   $0x10cee8,0xc(%esp)
  106445:	00 
  106446:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  10644d:	00 
  10644e:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
  106455:	00 
  106456:	c7 04 24 1f cf 10 00 	movl   $0x10cf1f,(%esp)
  10645d:	e8 d6 a4 ff ff       	call   100938 <debug_panic>
	assert(pi != mem_ptr2pi(pmap_zero));	// Don't alloc/free zero page!
  106462:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  106468:	b8 00 10 18 00       	mov    $0x181000,%eax
  10646d:	c1 e8 0c             	shr    $0xc,%eax
  106470:	c1 e0 03             	shl    $0x3,%eax
  106473:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106476:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  106479:	75 24                	jne    10649f <pmap_walk+0x4bc>
  10647b:	c7 44 24 0c 2c cf 10 	movl   $0x10cf2c,0xc(%esp)
  106482:	00 
  106483:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  10648a:	00 
  10648b:	c7 44 24 04 59 00 00 	movl   $0x59,0x4(%esp)
  106492:	00 
  106493:	c7 04 24 1f cf 10 00 	movl   $0x10cf1f,(%esp)
  10649a:	e8 99 a4 ff ff       	call   100938 <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  10649f:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  1064a5:	b8 0c 00 10 00       	mov    $0x10000c,%eax
  1064aa:	c1 e8 0c             	shr    $0xc,%eax
  1064ad:	c1 e0 03             	shl    $0x3,%eax
  1064b0:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1064b3:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  1064b6:	77 40                	ja     1064f8 <pmap_walk+0x515>
  1064b8:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  1064be:	b8 08 20 18 00       	mov    $0x182008,%eax
  1064c3:	83 e8 01             	sub    $0x1,%eax
  1064c6:	c1 e8 0c             	shr    $0xc,%eax
  1064c9:	c1 e0 03             	shl    $0x3,%eax
  1064cc:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1064cf:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  1064d2:	72 24                	jb     1064f8 <pmap_walk+0x515>
  1064d4:	c7 44 24 0c 48 cf 10 	movl   $0x10cf48,0xc(%esp)
  1064db:	00 
  1064dc:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  1064e3:	00 
  1064e4:	c7 44 24 04 5a 00 00 	movl   $0x5a,0x4(%esp)
  1064eb:	00 
  1064ec:	c7 04 24 1f cf 10 00 	movl   $0x10cf1f,(%esp)
  1064f3:	e8 40 a4 ff ff       	call   100938 <debug_panic>

	lockadd(&pi->refcount, 1);
  1064f8:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  1064fb:	83 c0 04             	add    $0x4,%eax
  1064fe:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  106505:	00 
  106506:	89 04 24             	mov    %eax,(%esp)
  106509:	e8 bc f8 ff ff       	call   105dca <lockadd>
  10650e:	83 45 e4 01          	addl   $0x1,0xffffffe4(%ebp)
  106512:	81 7d e4 ff 03 00 00 	cmpl   $0x3ff,0xffffffe4(%ebp)
  106519:	0f 8e 7a fe ff ff    	jle    106399 <pmap_walk+0x3b6>
    }

    mem_decref(mem_ptr2pi(ptab), pmap_freeptab);
  10651f:	8b 45 cc             	mov    0xffffffcc(%ebp),%eax
  106522:	c1 e8 0c             	shr    $0xc,%eax
  106525:	c1 e0 03             	shl    $0x3,%eax
  106528:	89 c2                	mov    %eax,%edx
  10652a:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  10652f:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106532:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  106535:	c7 45 f8 17 5e 10 00 	movl   $0x105e17,0xfffffff8(%ebp)
// freeing the page with the provided function if there are no more refs.
static gcc_inline void
mem_decref(pageinfo* pi, void (*freefun)(pageinfo *pi))
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  10653c:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  106541:	83 c0 08             	add    $0x8,%eax
  106544:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  106547:	73 17                	jae    106560 <pmap_walk+0x57d>
  106549:	a1 84 ed 17 00       	mov    0x17ed84,%eax
  10654e:	c1 e0 03             	shl    $0x3,%eax
  106551:	89 c2                	mov    %eax,%edx
  106553:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  106558:	8d 04 02             	lea    (%edx,%eax,1),%eax
  10655b:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  10655e:	77 24                	ja     106584 <pmap_walk+0x5a1>
  106560:	c7 44 24 0c e8 ce 10 	movl   $0x10cee8,0xc(%esp)
  106567:	00 
  106568:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  10656f:	00 
  106570:	c7 44 24 04 64 00 00 	movl   $0x64,0x4(%esp)
  106577:	00 
  106578:	c7 04 24 1f cf 10 00 	movl   $0x10cf1f,(%esp)
  10657f:	e8 b4 a3 ff ff       	call   100938 <debug_panic>
	assert(pi != mem_ptr2pi(pmap_zero));	// Don't alloc/free zero page!
  106584:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  10658a:	b8 00 10 18 00       	mov    $0x181000,%eax
  10658f:	c1 e8 0c             	shr    $0xc,%eax
  106592:	c1 e0 03             	shl    $0x3,%eax
  106595:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106598:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  10659b:	75 24                	jne    1065c1 <pmap_walk+0x5de>
  10659d:	c7 44 24 0c 2c cf 10 	movl   $0x10cf2c,0xc(%esp)
  1065a4:	00 
  1065a5:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  1065ac:	00 
  1065ad:	c7 44 24 04 65 00 00 	movl   $0x65,0x4(%esp)
  1065b4:	00 
  1065b5:	c7 04 24 1f cf 10 00 	movl   $0x10cf1f,(%esp)
  1065bc:	e8 77 a3 ff ff       	call   100938 <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  1065c1:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  1065c7:	b8 0c 00 10 00       	mov    $0x10000c,%eax
  1065cc:	c1 e8 0c             	shr    $0xc,%eax
  1065cf:	c1 e0 03             	shl    $0x3,%eax
  1065d2:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1065d5:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  1065d8:	77 40                	ja     10661a <pmap_walk+0x637>
  1065da:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  1065e0:	b8 08 20 18 00       	mov    $0x182008,%eax
  1065e5:	83 e8 01             	sub    $0x1,%eax
  1065e8:	c1 e8 0c             	shr    $0xc,%eax
  1065eb:	c1 e0 03             	shl    $0x3,%eax
  1065ee:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1065f1:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  1065f4:	72 24                	jb     10661a <pmap_walk+0x637>
  1065f6:	c7 44 24 0c 48 cf 10 	movl   $0x10cf48,0xc(%esp)
  1065fd:	00 
  1065fe:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  106605:	00 
  106606:	c7 44 24 04 66 00 00 	movl   $0x66,0x4(%esp)
  10660d:	00 
  10660e:	c7 04 24 1f cf 10 00 	movl   $0x10cf1f,(%esp)
  106615:	e8 1e a3 ff ff       	call   100938 <debug_panic>

	if (lockaddz(&pi->refcount, -1))
  10661a:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  10661d:	83 c0 04             	add    $0x4,%eax
  106620:	c7 44 24 04 ff ff ff 	movl   $0xffffffff,0x4(%esp)
  106627:	ff 
  106628:	89 04 24             	mov    %eax,(%esp)
  10662b:	e8 97 f9 ff ff       	call   105fc7 <lockaddz>
  106630:	84 c0                	test   %al,%al
  106632:	74 0b                	je     10663f <pmap_walk+0x65c>
			freefun(pi);
  106634:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  106637:	89 04 24             	mov    %eax,(%esp)
  10663a:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10663d:	ff d0                	call   *%eax
	assert(pi->refcount >= 0);
  10663f:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  106642:	8b 40 04             	mov    0x4(%eax),%eax
  106645:	85 c0                	test   %eax,%eax
  106647:	79 24                	jns    10666d <pmap_walk+0x68a>
  106649:	c7 44 24 0c 79 cf 10 	movl   $0x10cf79,0xc(%esp)
  106650:	00 
  106651:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  106658:	00 
  106659:	c7 44 24 04 6a 00 00 	movl   $0x6a,0x4(%esp)
  106660:	00 
  106661:	c7 04 24 1f cf 10 00 	movl   $0x10cf1f,(%esp)
  106668:	e8 cb a2 ff ff       	call   100938 <debug_panic>
    ptab = nptab;
  10666d:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  106670:	89 45 cc             	mov    %eax,0xffffffcc(%ebp)
    }

    *pde = (uint32_t)ptab | PTE_A | PTE_P | PTE_W | PTE_U;
  106673:	8b 45 cc             	mov    0xffffffcc(%ebp),%eax
  106676:	89 c2                	mov    %eax,%edx
  106678:	83 ca 27             	or     $0x27,%edx
  10667b:	8b 45 c8             	mov    0xffffffc8(%ebp),%eax
  10667e:	89 10                	mov    %edx,(%eax)
    }

    return &ptab[PTX(la)];
  106680:	8b 45 c4             	mov    0xffffffc4(%ebp),%eax
  106683:	c1 e8 0c             	shr    $0xc,%eax
  106686:	25 ff 03 00 00       	and    $0x3ff,%eax
  10668b:	c1 e0 02             	shl    $0x2,%eax
  10668e:	8b 55 cc             	mov    0xffffffcc(%ebp),%edx
  106691:	01 c2                	add    %eax,%edx
  106693:	89 55 bc             	mov    %edx,0xffffffbc(%ebp)
  106696:	8b 45 bc             	mov    0xffffffbc(%ebp),%eax
}
  106699:	c9                   	leave  
  10669a:	c3                   	ret    

0010669b <pmap_insert>:

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
  10669b:	55                   	push   %ebp
  10669c:	89 e5                	mov    %esp,%ebp
  10669e:	83 ec 28             	sub    $0x28,%esp
  pte_t* pte = pmap_walk(pdir, va, 1);
  1066a1:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
  1066a8:	00 
  1066a9:	8b 45 10             	mov    0x10(%ebp),%eax
  1066ac:	89 44 24 04          	mov    %eax,0x4(%esp)
  1066b0:	8b 45 08             	mov    0x8(%ebp),%eax
  1066b3:	89 04 24             	mov    %eax,(%esp)
  1066b6:	e8 28 f9 ff ff       	call   105fe3 <pmap_walk>
  1066bb:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  if (pte == NULL)
  1066be:	83 7d f8 00          	cmpl   $0x0,0xfffffff8(%ebp)
  1066c2:	75 0c                	jne    1066d0 <pmap_insert+0x35>
    return NULL;
  1066c4:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  1066cb:	e9 44 01 00 00       	jmp    106814 <pmap_insert+0x179>
  1066d0:	8b 45 0c             	mov    0xc(%ebp),%eax
  1066d3:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
// Atomically increment the reference count on a page.
static gcc_inline void
mem_incref(pageinfo *pi)
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  1066d6:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  1066db:	83 c0 08             	add    $0x8,%eax
  1066de:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  1066e1:	73 17                	jae    1066fa <pmap_insert+0x5f>
  1066e3:	a1 84 ed 17 00       	mov    0x17ed84,%eax
  1066e8:	c1 e0 03             	shl    $0x3,%eax
  1066eb:	89 c2                	mov    %eax,%edx
  1066ed:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  1066f2:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1066f5:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  1066f8:	77 24                	ja     10671e <pmap_insert+0x83>
  1066fa:	c7 44 24 0c e8 ce 10 	movl   $0x10cee8,0xc(%esp)
  106701:	00 
  106702:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  106709:	00 
  10670a:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
  106711:	00 
  106712:	c7 04 24 1f cf 10 00 	movl   $0x10cf1f,(%esp)
  106719:	e8 1a a2 ff ff       	call   100938 <debug_panic>
	assert(pi != mem_ptr2pi(pmap_zero));	// Don't alloc/free zero page!
  10671e:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  106724:	b8 00 10 18 00       	mov    $0x181000,%eax
  106729:	c1 e8 0c             	shr    $0xc,%eax
  10672c:	c1 e0 03             	shl    $0x3,%eax
  10672f:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106732:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  106735:	75 24                	jne    10675b <pmap_insert+0xc0>
  106737:	c7 44 24 0c 2c cf 10 	movl   $0x10cf2c,0xc(%esp)
  10673e:	00 
  10673f:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  106746:	00 
  106747:	c7 44 24 04 59 00 00 	movl   $0x59,0x4(%esp)
  10674e:	00 
  10674f:	c7 04 24 1f cf 10 00 	movl   $0x10cf1f,(%esp)
  106756:	e8 dd a1 ff ff       	call   100938 <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  10675b:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  106761:	b8 0c 00 10 00       	mov    $0x10000c,%eax
  106766:	c1 e8 0c             	shr    $0xc,%eax
  106769:	c1 e0 03             	shl    $0x3,%eax
  10676c:	8d 04 02             	lea    (%edx,%eax,1),%eax
  10676f:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  106772:	77 40                	ja     1067b4 <pmap_insert+0x119>
  106774:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  10677a:	b8 08 20 18 00       	mov    $0x182008,%eax
  10677f:	83 e8 01             	sub    $0x1,%eax
  106782:	c1 e8 0c             	shr    $0xc,%eax
  106785:	c1 e0 03             	shl    $0x3,%eax
  106788:	8d 04 02             	lea    (%edx,%eax,1),%eax
  10678b:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  10678e:	72 24                	jb     1067b4 <pmap_insert+0x119>
  106790:	c7 44 24 0c 48 cf 10 	movl   $0x10cf48,0xc(%esp)
  106797:	00 
  106798:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  10679f:	00 
  1067a0:	c7 44 24 04 5a 00 00 	movl   $0x5a,0x4(%esp)
  1067a7:	00 
  1067a8:	c7 04 24 1f cf 10 00 	movl   $0x10cf1f,(%esp)
  1067af:	e8 84 a1 ff ff       	call   100938 <debug_panic>

	lockadd(&pi->refcount, 1);
  1067b4:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  1067b7:	83 c0 04             	add    $0x4,%eax
  1067ba:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  1067c1:	00 
  1067c2:	89 04 24             	mov    %eax,(%esp)
  1067c5:	e8 00 f6 ff ff       	call   105dca <lockadd>


  mem_incref(pi);

  if (*pte & PTE_P)
  1067ca:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1067cd:	8b 00                	mov    (%eax),%eax
  1067cf:	83 e0 01             	and    $0x1,%eax
  1067d2:	84 c0                	test   %al,%al
  1067d4:	74 1a                	je     1067f0 <pmap_insert+0x155>
    pmap_remove(pdir, va, PAGESIZE);
  1067d6:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  1067dd:	00 
  1067de:	8b 45 10             	mov    0x10(%ebp),%eax
  1067e1:	89 44 24 04          	mov    %eax,0x4(%esp)
  1067e5:	8b 45 08             	mov    0x8(%ebp),%eax
  1067e8:	89 04 24             	mov    %eax,(%esp)
  1067eb:	e8 29 00 00 00       	call   106819 <pmap_remove>

  *pte = mem_pi2phys(pi) | perm | PTE_P;
  1067f0:	8b 55 0c             	mov    0xc(%ebp),%edx
  1067f3:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  1067f8:	89 d1                	mov    %edx,%ecx
  1067fa:	29 c1                	sub    %eax,%ecx
  1067fc:	89 c8                	mov    %ecx,%eax
  1067fe:	c1 e0 09             	shl    $0x9,%eax
  106801:	0b 45 14             	or     0x14(%ebp),%eax
  106804:	83 c8 01             	or     $0x1,%eax
  106807:	89 c2                	mov    %eax,%edx
  106809:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10680c:	89 10                	mov    %edx,(%eax)
  return pte;
  10680e:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  106811:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  106814:	8b 45 ec             	mov    0xffffffec(%ebp),%eax



}
  106817:	c9                   	leave  
  106818:	c3                   	ret    

00106819 <pmap_remove>:


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
  106819:	55                   	push   %ebp
  10681a:	89 e5                	mov    %esp,%ebp
  10681c:	83 ec 48             	sub    $0x48,%esp
	assert(PGOFF(size) == 0);	// must be page-aligned
  10681f:	8b 45 10             	mov    0x10(%ebp),%eax
  106822:	25 ff 0f 00 00       	and    $0xfff,%eax
  106827:	85 c0                	test   %eax,%eax
  106829:	74 24                	je     10684f <pmap_remove+0x36>
  10682b:	c7 44 24 0c dc cf 10 	movl   $0x10cfdc,0xc(%esp)
  106832:	00 
  106833:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  10683a:	00 
  10683b:	c7 44 24 04 1f 01 00 	movl   $0x11f,0x4(%esp)
  106842:	00 
  106843:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  10684a:	e8 e9 a0 ff ff       	call   100938 <debug_panic>
	assert(va >= VM_USERLO && va < VM_USERHI);
  10684f:	81 7d 0c ff ff ff 3f 	cmpl   $0x3fffffff,0xc(%ebp)
  106856:	76 09                	jbe    106861 <pmap_remove+0x48>
  106858:	81 7d 0c ff ff ff ef 	cmpl   $0xefffffff,0xc(%ebp)
  10685f:	76 24                	jbe    106885 <pmap_remove+0x6c>
  106861:	c7 44 24 0c 8c cf 10 	movl   $0x10cf8c,0xc(%esp)
  106868:	00 
  106869:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  106870:	00 
  106871:	c7 44 24 04 20 01 00 	movl   $0x120,0x4(%esp)
  106878:	00 
  106879:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  106880:	e8 b3 a0 ff ff       	call   100938 <debug_panic>
	assert(size <= VM_USERHI - va);
  106885:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
  10688a:	2b 45 0c             	sub    0xc(%ebp),%eax
  10688d:	3b 45 10             	cmp    0x10(%ebp),%eax
  106890:	73 24                	jae    1068b6 <pmap_remove+0x9d>
  106892:	c7 44 24 0c ed cf 10 	movl   $0x10cfed,0xc(%esp)
  106899:	00 
  10689a:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  1068a1:	00 
  1068a2:	c7 44 24 04 21 01 00 	movl   $0x121,0x4(%esp)
  1068a9:	00 
  1068aa:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  1068b1:	e8 82 a0 ff ff       	call   100938 <debug_panic>

	// Fill in this function
  pmap_inval(pdir, va, size);
  1068b6:	8b 45 10             	mov    0x10(%ebp),%eax
  1068b9:	89 44 24 08          	mov    %eax,0x8(%esp)
  1068bd:	8b 45 0c             	mov    0xc(%ebp),%eax
  1068c0:	89 44 24 04          	mov    %eax,0x4(%esp)
  1068c4:	8b 45 08             	mov    0x8(%ebp),%eax
  1068c7:	89 04 24             	mov    %eax,(%esp)
  1068ca:	e8 e0 03 00 00       	call   106caf <pmap_inval>

  uint32_t vahi = va + size;
  1068cf:	8b 45 10             	mov    0x10(%ebp),%eax
  1068d2:	03 45 0c             	add    0xc(%ebp),%eax
  1068d5:	89 45 dc             	mov    %eax,0xffffffdc(%ebp)
  while (va < vahi){
  1068d8:	e9 c4 03 00 00       	jmp    106ca1 <pmap_remove+0x488>
  pde_t *pde = &pdir[PDX(va)];
  1068dd:	8b 45 0c             	mov    0xc(%ebp),%eax
  1068e0:	c1 e8 16             	shr    $0x16,%eax
  1068e3:	25 ff 03 00 00       	and    $0x3ff,%eax
  1068e8:	c1 e0 02             	shl    $0x2,%eax
  1068eb:	03 45 08             	add    0x8(%ebp),%eax
  1068ee:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)
  if (*pde == PTE_ZERO){
  1068f1:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  1068f4:	8b 10                	mov    (%eax),%edx
  1068f6:	b8 00 10 18 00       	mov    $0x181000,%eax
  1068fb:	39 c2                	cmp    %eax,%edx
  1068fd:	75 15                	jne    106914 <pmap_remove+0xfb>
    va = PTADDR(va + PTSIZE);
  1068ff:	8b 45 0c             	mov    0xc(%ebp),%eax
  106902:	05 00 00 40 00       	add    $0x400000,%eax
  106907:	25 00 00 c0 ff       	and    $0xffc00000,%eax
  10690c:	89 45 0c             	mov    %eax,0xc(%ebp)
      continue;
  10690f:	e9 8d 03 00 00       	jmp    106ca1 <pmap_remove+0x488>
      }

    if (PTX(va) == 0 && vahi-va >= PTSIZE){
  106914:	8b 45 0c             	mov    0xc(%ebp),%eax
  106917:	c1 e8 0c             	shr    $0xc,%eax
  10691a:	25 ff 03 00 00       	and    $0x3ff,%eax
  10691f:	85 c0                	test   %eax,%eax
  106921:	0f 85 98 01 00 00    	jne    106abf <pmap_remove+0x2a6>
  106927:	8b 45 0c             	mov    0xc(%ebp),%eax
  10692a:	8b 55 dc             	mov    0xffffffdc(%ebp),%edx
  10692d:	89 d1                	mov    %edx,%ecx
  10692f:	29 c1                	sub    %eax,%ecx
  106931:	89 c8                	mov    %ecx,%eax
  106933:	3d ff ff 3f 00       	cmp    $0x3fffff,%eax
  106938:	0f 86 81 01 00 00    	jbe    106abf <pmap_remove+0x2a6>
    uint32_t ptabaddr = PGADDR(*pde);
  10693e:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  106941:	8b 00                	mov    (%eax),%eax
  106943:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  106948:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
    if(ptabaddr != PTE_ZERO)
  10694b:	b8 00 10 18 00       	mov    $0x181000,%eax
  106950:	39 45 e8             	cmp    %eax,0xffffffe8(%ebp)
  106953:	0f 84 4e 01 00 00    	je     106aa7 <pmap_remove+0x28e>
      mem_decref(mem_phys2pi(ptabaddr), pmap_freeptab);
  106959:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  10695c:	c1 e8 0c             	shr    $0xc,%eax
  10695f:	c1 e0 03             	shl    $0x3,%eax
  106962:	89 c2                	mov    %eax,%edx
  106964:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  106969:	8d 04 02             	lea    (%edx,%eax,1),%eax
  10696c:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
  10696f:	c7 45 f0 17 5e 10 00 	movl   $0x105e17,0xfffffff0(%ebp)
// freeing the page with the provided function if there are no more refs.
static gcc_inline void
mem_decref(pageinfo* pi, void (*freefun)(pageinfo *pi))
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  106976:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  10697b:	83 c0 08             	add    $0x8,%eax
  10697e:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  106981:	73 17                	jae    10699a <pmap_remove+0x181>
  106983:	a1 84 ed 17 00       	mov    0x17ed84,%eax
  106988:	c1 e0 03             	shl    $0x3,%eax
  10698b:	89 c2                	mov    %eax,%edx
  10698d:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  106992:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106995:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  106998:	77 24                	ja     1069be <pmap_remove+0x1a5>
  10699a:	c7 44 24 0c e8 ce 10 	movl   $0x10cee8,0xc(%esp)
  1069a1:	00 
  1069a2:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  1069a9:	00 
  1069aa:	c7 44 24 04 64 00 00 	movl   $0x64,0x4(%esp)
  1069b1:	00 
  1069b2:	c7 04 24 1f cf 10 00 	movl   $0x10cf1f,(%esp)
  1069b9:	e8 7a 9f ff ff       	call   100938 <debug_panic>
	assert(pi != mem_ptr2pi(pmap_zero));	// Don't alloc/free zero page!
  1069be:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  1069c4:	b8 00 10 18 00       	mov    $0x181000,%eax
  1069c9:	c1 e8 0c             	shr    $0xc,%eax
  1069cc:	c1 e0 03             	shl    $0x3,%eax
  1069cf:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1069d2:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  1069d5:	75 24                	jne    1069fb <pmap_remove+0x1e2>
  1069d7:	c7 44 24 0c 2c cf 10 	movl   $0x10cf2c,0xc(%esp)
  1069de:	00 
  1069df:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  1069e6:	00 
  1069e7:	c7 44 24 04 65 00 00 	movl   $0x65,0x4(%esp)
  1069ee:	00 
  1069ef:	c7 04 24 1f cf 10 00 	movl   $0x10cf1f,(%esp)
  1069f6:	e8 3d 9f ff ff       	call   100938 <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  1069fb:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  106a01:	b8 0c 00 10 00       	mov    $0x10000c,%eax
  106a06:	c1 e8 0c             	shr    $0xc,%eax
  106a09:	c1 e0 03             	shl    $0x3,%eax
  106a0c:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106a0f:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  106a12:	77 40                	ja     106a54 <pmap_remove+0x23b>
  106a14:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  106a1a:	b8 08 20 18 00       	mov    $0x182008,%eax
  106a1f:	83 e8 01             	sub    $0x1,%eax
  106a22:	c1 e8 0c             	shr    $0xc,%eax
  106a25:	c1 e0 03             	shl    $0x3,%eax
  106a28:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106a2b:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  106a2e:	72 24                	jb     106a54 <pmap_remove+0x23b>
  106a30:	c7 44 24 0c 48 cf 10 	movl   $0x10cf48,0xc(%esp)
  106a37:	00 
  106a38:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  106a3f:	00 
  106a40:	c7 44 24 04 66 00 00 	movl   $0x66,0x4(%esp)
  106a47:	00 
  106a48:	c7 04 24 1f cf 10 00 	movl   $0x10cf1f,(%esp)
  106a4f:	e8 e4 9e ff ff       	call   100938 <debug_panic>

	if (lockaddz(&pi->refcount, -1))
  106a54:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  106a57:	83 c0 04             	add    $0x4,%eax
  106a5a:	c7 44 24 04 ff ff ff 	movl   $0xffffffff,0x4(%esp)
  106a61:	ff 
  106a62:	89 04 24             	mov    %eax,(%esp)
  106a65:	e8 5d f5 ff ff       	call   105fc7 <lockaddz>
  106a6a:	84 c0                	test   %al,%al
  106a6c:	74 0b                	je     106a79 <pmap_remove+0x260>
			freefun(pi);
  106a6e:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  106a71:	89 04 24             	mov    %eax,(%esp)
  106a74:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  106a77:	ff d0                	call   *%eax
	assert(pi->refcount >= 0);
  106a79:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  106a7c:	8b 40 04             	mov    0x4(%eax),%eax
  106a7f:	85 c0                	test   %eax,%eax
  106a81:	79 24                	jns    106aa7 <pmap_remove+0x28e>
  106a83:	c7 44 24 0c 79 cf 10 	movl   $0x10cf79,0xc(%esp)
  106a8a:	00 
  106a8b:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  106a92:	00 
  106a93:	c7 44 24 04 6a 00 00 	movl   $0x6a,0x4(%esp)
  106a9a:	00 
  106a9b:	c7 04 24 1f cf 10 00 	movl   $0x10cf1f,(%esp)
  106aa2:	e8 91 9e ff ff       	call   100938 <debug_panic>
      *pde = PTE_ZERO;
  106aa7:	b8 00 10 18 00       	mov    $0x181000,%eax
  106aac:	89 c2                	mov    %eax,%edx
  106aae:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  106ab1:	89 10                	mov    %edx,(%eax)
      va += PTSIZE;
  106ab3:	81 45 0c 00 00 40 00 	addl   $0x400000,0xc(%ebp)
      continue;
  106aba:	e9 e2 01 00 00       	jmp    106ca1 <pmap_remove+0x488>
      }
  pte_t *pte = pmap_walk(pdir, va, 1);
  106abf:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
  106ac6:	00 
  106ac7:	8b 45 0c             	mov    0xc(%ebp),%eax
  106aca:	89 44 24 04          	mov    %eax,0x4(%esp)
  106ace:	8b 45 08             	mov    0x8(%ebp),%eax
  106ad1:	89 04 24             	mov    %eax,(%esp)
  106ad4:	e8 0a f5 ff ff       	call   105fe3 <pmap_walk>
  106ad9:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
  assert(pte != NULL);
  106adc:	83 7d e4 00          	cmpl   $0x0,0xffffffe4(%ebp)
  106ae0:	75 24                	jne    106b06 <pmap_remove+0x2ed>
  106ae2:	c7 44 24 0c 04 d0 10 	movl   $0x10d004,0xc(%esp)
  106ae9:	00 
  106aea:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  106af1:	00 
  106af2:	c7 44 24 04 37 01 00 	movl   $0x137,0x4(%esp)
  106af9:	00 
  106afa:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  106b01:	e8 32 9e ff ff       	call   100938 <debug_panic>

  do{
    uint32_t pgaddr = PGADDR(*pte);
  106b06:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  106b09:	8b 00                	mov    (%eax),%eax
  106b0b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  106b10:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
    if(pgaddr != PTE_ZERO)
  106b13:	b8 00 10 18 00       	mov    $0x181000,%eax
  106b18:	39 45 ec             	cmp    %eax,0xffffffec(%ebp)
  106b1b:	0f 84 4e 01 00 00    	je     106c6f <pmap_remove+0x456>
      mem_decref(mem_phys2pi(pgaddr), mem_free);
  106b21:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  106b24:	c1 e8 0c             	shr    $0xc,%eax
  106b27:	c1 e0 03             	shl    $0x3,%eax
  106b2a:	89 c2                	mov    %eax,%edx
  106b2c:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  106b31:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106b34:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  106b37:	c7 45 f8 5f 10 10 00 	movl   $0x10105f,0xfffffff8(%ebp)
// freeing the page with the provided function if there are no more refs.
static gcc_inline void
mem_decref(pageinfo* pi, void (*freefun)(pageinfo *pi))
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  106b3e:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  106b43:	83 c0 08             	add    $0x8,%eax
  106b46:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  106b49:	73 17                	jae    106b62 <pmap_remove+0x349>
  106b4b:	a1 84 ed 17 00       	mov    0x17ed84,%eax
  106b50:	c1 e0 03             	shl    $0x3,%eax
  106b53:	89 c2                	mov    %eax,%edx
  106b55:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  106b5a:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106b5d:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  106b60:	77 24                	ja     106b86 <pmap_remove+0x36d>
  106b62:	c7 44 24 0c e8 ce 10 	movl   $0x10cee8,0xc(%esp)
  106b69:	00 
  106b6a:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  106b71:	00 
  106b72:	c7 44 24 04 64 00 00 	movl   $0x64,0x4(%esp)
  106b79:	00 
  106b7a:	c7 04 24 1f cf 10 00 	movl   $0x10cf1f,(%esp)
  106b81:	e8 b2 9d ff ff       	call   100938 <debug_panic>
	assert(pi != mem_ptr2pi(pmap_zero));	// Don't alloc/free zero page!
  106b86:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  106b8c:	b8 00 10 18 00       	mov    $0x181000,%eax
  106b91:	c1 e8 0c             	shr    $0xc,%eax
  106b94:	c1 e0 03             	shl    $0x3,%eax
  106b97:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106b9a:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  106b9d:	75 24                	jne    106bc3 <pmap_remove+0x3aa>
  106b9f:	c7 44 24 0c 2c cf 10 	movl   $0x10cf2c,0xc(%esp)
  106ba6:	00 
  106ba7:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  106bae:	00 
  106baf:	c7 44 24 04 65 00 00 	movl   $0x65,0x4(%esp)
  106bb6:	00 
  106bb7:	c7 04 24 1f cf 10 00 	movl   $0x10cf1f,(%esp)
  106bbe:	e8 75 9d ff ff       	call   100938 <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  106bc3:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  106bc9:	b8 0c 00 10 00       	mov    $0x10000c,%eax
  106bce:	c1 e8 0c             	shr    $0xc,%eax
  106bd1:	c1 e0 03             	shl    $0x3,%eax
  106bd4:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106bd7:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  106bda:	77 40                	ja     106c1c <pmap_remove+0x403>
  106bdc:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  106be2:	b8 08 20 18 00       	mov    $0x182008,%eax
  106be7:	83 e8 01             	sub    $0x1,%eax
  106bea:	c1 e8 0c             	shr    $0xc,%eax
  106bed:	c1 e0 03             	shl    $0x3,%eax
  106bf0:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106bf3:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  106bf6:	72 24                	jb     106c1c <pmap_remove+0x403>
  106bf8:	c7 44 24 0c 48 cf 10 	movl   $0x10cf48,0xc(%esp)
  106bff:	00 
  106c00:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  106c07:	00 
  106c08:	c7 44 24 04 66 00 00 	movl   $0x66,0x4(%esp)
  106c0f:	00 
  106c10:	c7 04 24 1f cf 10 00 	movl   $0x10cf1f,(%esp)
  106c17:	e8 1c 9d ff ff       	call   100938 <debug_panic>

	if (lockaddz(&pi->refcount, -1))
  106c1c:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  106c1f:	83 c0 04             	add    $0x4,%eax
  106c22:	c7 44 24 04 ff ff ff 	movl   $0xffffffff,0x4(%esp)
  106c29:	ff 
  106c2a:	89 04 24             	mov    %eax,(%esp)
  106c2d:	e8 95 f3 ff ff       	call   105fc7 <lockaddz>
  106c32:	84 c0                	test   %al,%al
  106c34:	74 0b                	je     106c41 <pmap_remove+0x428>
			freefun(pi);
  106c36:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  106c39:	89 04 24             	mov    %eax,(%esp)
  106c3c:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  106c3f:	ff d0                	call   *%eax
	assert(pi->refcount >= 0);
  106c41:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  106c44:	8b 40 04             	mov    0x4(%eax),%eax
  106c47:	85 c0                	test   %eax,%eax
  106c49:	79 24                	jns    106c6f <pmap_remove+0x456>
  106c4b:	c7 44 24 0c 79 cf 10 	movl   $0x10cf79,0xc(%esp)
  106c52:	00 
  106c53:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  106c5a:	00 
  106c5b:	c7 44 24 04 6a 00 00 	movl   $0x6a,0x4(%esp)
  106c62:	00 
  106c63:	c7 04 24 1f cf 10 00 	movl   $0x10cf1f,(%esp)
  106c6a:	e8 c9 9c ff ff       	call   100938 <debug_panic>
      *pte++ = PTE_ZERO;
  106c6f:	b8 00 10 18 00       	mov    $0x181000,%eax
  106c74:	89 c2                	mov    %eax,%edx
  106c76:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  106c79:	89 10                	mov    %edx,(%eax)
  106c7b:	83 45 e4 04          	addl   $0x4,0xffffffe4(%ebp)
      va += PAGESIZE;
  106c7f:	81 45 0c 00 10 00 00 	addl   $0x1000,0xc(%ebp)
      } while (va < vahi && PTX(va) != 0);
  106c86:	8b 45 0c             	mov    0xc(%ebp),%eax
  106c89:	3b 45 dc             	cmp    0xffffffdc(%ebp),%eax
  106c8c:	73 13                	jae    106ca1 <pmap_remove+0x488>
  106c8e:	8b 45 0c             	mov    0xc(%ebp),%eax
  106c91:	c1 e8 0c             	shr    $0xc,%eax
  106c94:	25 ff 03 00 00       	and    $0x3ff,%eax
  106c99:	85 c0                	test   %eax,%eax
  106c9b:	0f 85 65 fe ff ff    	jne    106b06 <pmap_remove+0x2ed>
  106ca1:	8b 45 0c             	mov    0xc(%ebp),%eax
  106ca4:	3b 45 dc             	cmp    0xffffffdc(%ebp),%eax
  106ca7:	0f 82 30 fc ff ff    	jb     1068dd <pmap_remove+0xc4>
      }

}
  106cad:	c9                   	leave  
  106cae:	c3                   	ret    

00106caf <pmap_inval>:


//
// Invalidate the TLB entry or entries for a given virtual address range,
// but only if the page tables being edited are the ones
// currently in use by the processor.
//
void
pmap_inval(pde_t *pdir, uint32_t va, size_t size)
{
  106caf:	55                   	push   %ebp
  106cb0:	89 e5                	mov    %esp,%ebp
  106cb2:	83 ec 18             	sub    $0x18,%esp
	// Flush the entry only if we're modifying the current address space.
	proc *p = proc_cur();
  106cb5:	e8 69 ef ff ff       	call   105c23 <cpu_cur>
  106cba:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  106cc0:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	if (p == NULL || p->pdir == pdir) {
  106cc3:	83 7d f4 00          	cmpl   $0x0,0xfffffff4(%ebp)
  106cc7:	74 0e                	je     106cd7 <pmap_inval+0x28>
  106cc9:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  106ccc:	8b 80 a0 06 00 00    	mov    0x6a0(%eax),%eax
  106cd2:	3b 45 08             	cmp    0x8(%ebp),%eax
  106cd5:	75 23                	jne    106cfa <pmap_inval+0x4b>
		if (size == PAGESIZE)
  106cd7:	81 7d 10 00 10 00 00 	cmpl   $0x1000,0x10(%ebp)
  106cde:	75 0e                	jne    106cee <pmap_inval+0x3f>
			invlpg(mem_ptr(va));	// invalidate one page
  106ce0:	8b 45 0c             	mov    0xc(%ebp),%eax
  106ce3:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)

static gcc_inline void 
invlpg(void *addr)
{ 
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
  106ce6:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  106ce9:	0f 01 38             	invlpg (%eax)
  106cec:	eb 0c                	jmp    106cfa <pmap_inval+0x4b>
		else
			lcr3(mem_phys(pdir));	// invalidate everything
  106cee:	8b 45 08             	mov    0x8(%ebp),%eax
  106cf1:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)

static gcc_inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
  106cf4:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  106cf7:	0f 22 d8             	mov    %eax,%cr3
	}
}
  106cfa:	c9                   	leave  
  106cfb:	c3                   	ret    

00106cfc <pmap_copy>:

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
  106cfc:	55                   	push   %ebp
  106cfd:	89 e5                	mov    %esp,%ebp
  106cff:	83 ec 28             	sub    $0x28,%esp
	assert(PTOFF(sva) == 0);	// must be 4MB-aligned
  106d02:	8b 45 0c             	mov    0xc(%ebp),%eax
  106d05:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  106d0a:	85 c0                	test   %eax,%eax
  106d0c:	74 24                	je     106d32 <pmap_copy+0x36>
  106d0e:	c7 44 24 0c 10 d0 10 	movl   $0x10d010,0xc(%esp)
  106d15:	00 
  106d16:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  106d1d:	00 
  106d1e:	c7 44 24 04 61 01 00 	movl   $0x161,0x4(%esp)
  106d25:	00 
  106d26:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  106d2d:	e8 06 9c ff ff       	call   100938 <debug_panic>
	assert(PTOFF(dva) == 0);
  106d32:	8b 45 14             	mov    0x14(%ebp),%eax
  106d35:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  106d3a:	85 c0                	test   %eax,%eax
  106d3c:	74 24                	je     106d62 <pmap_copy+0x66>
  106d3e:	c7 44 24 0c 20 d0 10 	movl   $0x10d020,0xc(%esp)
  106d45:	00 
  106d46:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  106d4d:	00 
  106d4e:	c7 44 24 04 62 01 00 	movl   $0x162,0x4(%esp)
  106d55:	00 
  106d56:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  106d5d:	e8 d6 9b ff ff       	call   100938 <debug_panic>
	assert(PTOFF(size) == 0);
  106d62:	8b 45 18             	mov    0x18(%ebp),%eax
  106d65:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  106d6a:	85 c0                	test   %eax,%eax
  106d6c:	74 24                	je     106d92 <pmap_copy+0x96>
  106d6e:	c7 44 24 0c 30 d0 10 	movl   $0x10d030,0xc(%esp)
  106d75:	00 
  106d76:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  106d7d:	00 
  106d7e:	c7 44 24 04 63 01 00 	movl   $0x163,0x4(%esp)
  106d85:	00 
  106d86:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  106d8d:	e8 a6 9b ff ff       	call   100938 <debug_panic>
	assert(sva >= VM_USERLO && sva < VM_USERHI);
  106d92:	81 7d 0c ff ff ff 3f 	cmpl   $0x3fffffff,0xc(%ebp)
  106d99:	76 09                	jbe    106da4 <pmap_copy+0xa8>
  106d9b:	81 7d 0c ff ff ff ef 	cmpl   $0xefffffff,0xc(%ebp)
  106da2:	76 24                	jbe    106dc8 <pmap_copy+0xcc>
  106da4:	c7 44 24 0c 44 d0 10 	movl   $0x10d044,0xc(%esp)
  106dab:	00 
  106dac:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  106db3:	00 
  106db4:	c7 44 24 04 64 01 00 	movl   $0x164,0x4(%esp)
  106dbb:	00 
  106dbc:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  106dc3:	e8 70 9b ff ff       	call   100938 <debug_panic>
	assert(dva >= VM_USERLO && dva < VM_USERHI);
  106dc8:	81 7d 14 ff ff ff 3f 	cmpl   $0x3fffffff,0x14(%ebp)
  106dcf:	76 09                	jbe    106dda <pmap_copy+0xde>
  106dd1:	81 7d 14 ff ff ff ef 	cmpl   $0xefffffff,0x14(%ebp)
  106dd8:	76 24                	jbe    106dfe <pmap_copy+0x102>
  106dda:	c7 44 24 0c 68 d0 10 	movl   $0x10d068,0xc(%esp)
  106de1:	00 
  106de2:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  106de9:	00 
  106dea:	c7 44 24 04 65 01 00 	movl   $0x165,0x4(%esp)
  106df1:	00 
  106df2:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  106df9:	e8 3a 9b ff ff       	call   100938 <debug_panic>
	assert(size <= VM_USERHI - sva);
  106dfe:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
  106e03:	2b 45 0c             	sub    0xc(%ebp),%eax
  106e06:	3b 45 18             	cmp    0x18(%ebp),%eax
  106e09:	73 24                	jae    106e2f <pmap_copy+0x133>
  106e0b:	c7 44 24 0c 8c d0 10 	movl   $0x10d08c,0xc(%esp)
  106e12:	00 
  106e13:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  106e1a:	00 
  106e1b:	c7 44 24 04 66 01 00 	movl   $0x166,0x4(%esp)
  106e22:	00 
  106e23:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  106e2a:	e8 09 9b ff ff       	call   100938 <debug_panic>
	assert(size <= VM_USERHI - dva);
  106e2f:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
  106e34:	2b 45 14             	sub    0x14(%ebp),%eax
  106e37:	3b 45 18             	cmp    0x18(%ebp),%eax
  106e3a:	73 24                	jae    106e60 <pmap_copy+0x164>
  106e3c:	c7 44 24 0c a4 d0 10 	movl   $0x10d0a4,0xc(%esp)
  106e43:	00 
  106e44:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  106e4b:	00 
  106e4c:	c7 44 24 04 67 01 00 	movl   $0x167,0x4(%esp)
  106e53:	00 
  106e54:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  106e5b:	e8 d8 9a ff ff       	call   100938 <debug_panic>

  pmap_inval(spdir, sva, size);
  106e60:	8b 45 18             	mov    0x18(%ebp),%eax
  106e63:	89 44 24 08          	mov    %eax,0x8(%esp)
  106e67:	8b 45 0c             	mov    0xc(%ebp),%eax
  106e6a:	89 44 24 04          	mov    %eax,0x4(%esp)
  106e6e:	8b 45 08             	mov    0x8(%ebp),%eax
  106e71:	89 04 24             	mov    %eax,(%esp)
  106e74:	e8 36 fe ff ff       	call   106caf <pmap_inval>
  pmap_inval(dpdir, dva, size);
  106e79:	8b 45 18             	mov    0x18(%ebp),%eax
  106e7c:	89 44 24 08          	mov    %eax,0x8(%esp)
  106e80:	8b 45 14             	mov    0x14(%ebp),%eax
  106e83:	89 44 24 04          	mov    %eax,0x4(%esp)
  106e87:	8b 45 10             	mov    0x10(%ebp),%eax
  106e8a:	89 04 24             	mov    %eax,(%esp)
  106e8d:	e8 1d fe ff ff       	call   106caf <pmap_inval>

  uint32_t svahi = sva + size;
  106e92:	8b 45 18             	mov    0x18(%ebp),%eax
  106e95:	03 45 0c             	add    0xc(%ebp),%eax
  106e98:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
  pde_t *spde = &spdir[PDX(sva)];
  106e9b:	8b 45 0c             	mov    0xc(%ebp),%eax
  106e9e:	c1 e8 16             	shr    $0x16,%eax
  106ea1:	25 ff 03 00 00       	and    $0x3ff,%eax
  106ea6:	c1 e0 02             	shl    $0x2,%eax
  106ea9:	03 45 08             	add    0x8(%ebp),%eax
  106eac:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
  pte_t *dpde = &dpdir[PDX(dva)];
  106eaf:	8b 45 14             	mov    0x14(%ebp),%eax
  106eb2:	c1 e8 16             	shr    $0x16,%eax
  106eb5:	25 ff 03 00 00       	and    $0x3ff,%eax
  106eba:	c1 e0 02             	shl    $0x2,%eax
  106ebd:	03 45 10             	add    0x10(%ebp),%eax
  106ec0:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)

  while (sva < svahi){
  106ec3:	e9 aa 01 00 00       	jmp    107072 <pmap_copy+0x376>

    if (*dpde & PTE_P)
  106ec8:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  106ecb:	8b 00                	mov    (%eax),%eax
  106ecd:	83 e0 01             	and    $0x1,%eax
  106ed0:	84 c0                	test   %al,%al
  106ed2:	74 1a                	je     106eee <pmap_copy+0x1f2>
      pmap_remove(dpdir, dva, PTSIZE);
  106ed4:	c7 44 24 08 00 00 40 	movl   $0x400000,0x8(%esp)
  106edb:	00 
  106edc:	8b 45 14             	mov    0x14(%ebp),%eax
  106edf:	89 44 24 04          	mov    %eax,0x4(%esp)
  106ee3:	8b 45 10             	mov    0x10(%ebp),%eax
  106ee6:	89 04 24             	mov    %eax,(%esp)
  106ee9:	e8 2b f9 ff ff       	call   106819 <pmap_remove>
    assert(*dpde == PTE_ZERO);
  106eee:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  106ef1:	8b 10                	mov    (%eax),%edx
  106ef3:	b8 00 10 18 00       	mov    $0x181000,%eax
  106ef8:	39 c2                	cmp    %eax,%edx
  106efa:	74 24                	je     106f20 <pmap_copy+0x224>
  106efc:	c7 44 24 0c bc d0 10 	movl   $0x10d0bc,0xc(%esp)
  106f03:	00 
  106f04:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  106f0b:	00 
  106f0c:	c7 44 24 04 74 01 00 	movl   $0x174,0x4(%esp)
  106f13:	00 
  106f14:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  106f1b:	e8 18 9a ff ff       	call   100938 <debug_panic>

    *spde &= ~PTE_W;
  106f20:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  106f23:	8b 00                	mov    (%eax),%eax
  106f25:	89 c2                	mov    %eax,%edx
  106f27:	83 e2 fd             	and    $0xfffffffd,%edx
  106f2a:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  106f2d:	89 10                	mov    %edx,(%eax)

    *dpde = *spde;
  106f2f:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  106f32:	8b 10                	mov    (%eax),%edx
  106f34:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  106f37:	89 10                	mov    %edx,(%eax)

    if (*spde != PTE_ZERO)
  106f39:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  106f3c:	8b 10                	mov    (%eax),%edx
  106f3e:	b8 00 10 18 00       	mov    $0x181000,%eax
  106f43:	39 c2                	cmp    %eax,%edx
  106f45:	0f 84 11 01 00 00    	je     10705c <pmap_copy+0x360>
      mem_incref(mem_phys2pi(PGADDR(*spde)));
  106f4b:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  106f4e:	8b 00                	mov    (%eax),%eax
  106f50:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  106f55:	c1 e8 0c             	shr    $0xc,%eax
  106f58:	c1 e0 03             	shl    $0x3,%eax
  106f5b:	89 c2                	mov    %eax,%edx
  106f5d:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  106f62:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106f65:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
// Atomically increment the reference count on a page.
static gcc_inline void
mem_incref(pageinfo *pi)
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  106f68:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  106f6d:	83 c0 08             	add    $0x8,%eax
  106f70:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  106f73:	73 17                	jae    106f8c <pmap_copy+0x290>
  106f75:	a1 84 ed 17 00       	mov    0x17ed84,%eax
  106f7a:	c1 e0 03             	shl    $0x3,%eax
  106f7d:	89 c2                	mov    %eax,%edx
  106f7f:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  106f84:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106f87:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  106f8a:	77 24                	ja     106fb0 <pmap_copy+0x2b4>
  106f8c:	c7 44 24 0c e8 ce 10 	movl   $0x10cee8,0xc(%esp)
  106f93:	00 
  106f94:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  106f9b:	00 
  106f9c:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
  106fa3:	00 
  106fa4:	c7 04 24 1f cf 10 00 	movl   $0x10cf1f,(%esp)
  106fab:	e8 88 99 ff ff       	call   100938 <debug_panic>
	assert(pi != mem_ptr2pi(pmap_zero));	// Don't alloc/free zero page!
  106fb0:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  106fb6:	b8 00 10 18 00       	mov    $0x181000,%eax
  106fbb:	c1 e8 0c             	shr    $0xc,%eax
  106fbe:	c1 e0 03             	shl    $0x3,%eax
  106fc1:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106fc4:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  106fc7:	75 24                	jne    106fed <pmap_copy+0x2f1>
  106fc9:	c7 44 24 0c 2c cf 10 	movl   $0x10cf2c,0xc(%esp)
  106fd0:	00 
  106fd1:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  106fd8:	00 
  106fd9:	c7 44 24 04 59 00 00 	movl   $0x59,0x4(%esp)
  106fe0:	00 
  106fe1:	c7 04 24 1f cf 10 00 	movl   $0x10cf1f,(%esp)
  106fe8:	e8 4b 99 ff ff       	call   100938 <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  106fed:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  106ff3:	b8 0c 00 10 00       	mov    $0x10000c,%eax
  106ff8:	c1 e8 0c             	shr    $0xc,%eax
  106ffb:	c1 e0 03             	shl    $0x3,%eax
  106ffe:	8d 04 02             	lea    (%edx,%eax,1),%eax
  107001:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  107004:	77 40                	ja     107046 <pmap_copy+0x34a>
  107006:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  10700c:	b8 08 20 18 00       	mov    $0x182008,%eax
  107011:	83 e8 01             	sub    $0x1,%eax
  107014:	c1 e8 0c             	shr    $0xc,%eax
  107017:	c1 e0 03             	shl    $0x3,%eax
  10701a:	8d 04 02             	lea    (%edx,%eax,1),%eax
  10701d:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  107020:	72 24                	jb     107046 <pmap_copy+0x34a>
  107022:	c7 44 24 0c 48 cf 10 	movl   $0x10cf48,0xc(%esp)
  107029:	00 
  10702a:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  107031:	00 
  107032:	c7 44 24 04 5a 00 00 	movl   $0x5a,0x4(%esp)
  107039:	00 
  10703a:	c7 04 24 1f cf 10 00 	movl   $0x10cf1f,(%esp)
  107041:	e8 f2 98 ff ff       	call   100938 <debug_panic>

	lockadd(&pi->refcount, 1);
  107046:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  107049:	83 c0 04             	add    $0x4,%eax
  10704c:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  107053:	00 
  107054:	89 04 24             	mov    %eax,(%esp)
  107057:	e8 6e ed ff ff       	call   105dca <lockadd>

      spde++, dpde++;
  10705c:	83 45 f4 04          	addl   $0x4,0xfffffff4(%ebp)
  107060:	83 45 f8 04          	addl   $0x4,0xfffffff8(%ebp)
      sva += PTSIZE;
  107064:	81 45 0c 00 00 40 00 	addl   $0x400000,0xc(%ebp)
      dva += PTSIZE;
  10706b:	81 45 14 00 00 40 00 	addl   $0x400000,0x14(%ebp)
  107072:	8b 45 0c             	mov    0xc(%ebp),%eax
  107075:	3b 45 f0             	cmp    0xfffffff0(%ebp),%eax
  107078:	0f 82 4a fe ff ff    	jb     106ec8 <pmap_copy+0x1cc>
      }

      return 1;
  10707e:	b8 01 00 00 00       	mov    $0x1,%eax


}
  107083:	c9                   	leave  
  107084:	c3                   	ret    

00107085 <pmap_pagefault>:

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
  107085:	55                   	push   %ebp
  107086:	89 e5                	mov    %esp,%ebp
  107088:	83 ec 48             	sub    $0x48,%esp
static gcc_inline uint32_t
rcr2(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr2,%0" : "=r" (val));
  10708b:	0f 20 d0             	mov    %cr2,%eax
  10708e:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
	return val;
  107091:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
	// Read processor's CR2 register to find the faulting linear address.
	uint32_t fva = rcr2();
  107094:	89 45 d4             	mov    %eax,0xffffffd4(%ebp)
	//cprintf("pmap_pagefault fva %x eip %x\n", fva, tf->eip);


  if (fva < VM_USERLO || fva >= VM_USERHI || !(tf->err & PFE_WR)){
  107097:	81 7d d4 ff ff ff 3f 	cmpl   $0x3fffffff,0xffffffd4(%ebp)
  10709e:	76 16                	jbe    1070b6 <pmap_pagefault+0x31>
  1070a0:	81 7d d4 ff ff ff ef 	cmpl   $0xefffffff,0xffffffd4(%ebp)
  1070a7:	77 0d                	ja     1070b6 <pmap_pagefault+0x31>
  1070a9:	8b 45 08             	mov    0x8(%ebp),%eax
  1070ac:	8b 40 34             	mov    0x34(%eax),%eax
  1070af:	83 e0 02             	and    $0x2,%eax
  1070b2:	85 c0                	test   %eax,%eax
  1070b4:	75 22                	jne    1070d8 <pmap_pagefault+0x53>
  cprintf("pmap_pagefault: fva %x err %x\n", fva, tf->err);
  1070b6:	8b 45 08             	mov    0x8(%ebp),%eax
  1070b9:	8b 40 34             	mov    0x34(%eax),%eax
  1070bc:	89 44 24 08          	mov    %eax,0x8(%esp)
  1070c0:	8b 45 d4             	mov    0xffffffd4(%ebp),%eax
  1070c3:	89 44 24 04          	mov    %eax,0x4(%esp)
  1070c7:	c7 04 24 d0 d0 10 00 	movl   $0x10d0d0,(%esp)
  1070ce:	e8 b2 43 00 00       	call   10b485 <cprintf>
    return;
  1070d3:	e9 fc 03 00 00       	jmp    1074d4 <pmap_pagefault+0x44f>
    }


    proc *p = proc_cur();
  1070d8:	e8 46 eb ff ff       	call   105c23 <cpu_cur>
  1070dd:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  1070e3:	89 45 d8             	mov    %eax,0xffffffd8(%ebp)
    pde_t *pde = &p->pdir[PDX(fva)];
  1070e6:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  1070e9:	8b 90 a0 06 00 00    	mov    0x6a0(%eax),%edx
  1070ef:	8b 45 d4             	mov    0xffffffd4(%ebp),%eax
  1070f2:	c1 e8 16             	shr    $0x16,%eax
  1070f5:	25 ff 03 00 00       	and    $0x3ff,%eax
  1070fa:	c1 e0 02             	shl    $0x2,%eax
  1070fd:	8d 04 02             	lea    (%edx,%eax,1),%eax
  107100:	89 45 dc             	mov    %eax,0xffffffdc(%ebp)
    if(!(*pde & PTE_P)){
  107103:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  107106:	8b 00                	mov    (%eax),%eax
  107108:	83 e0 01             	and    $0x1,%eax
  10710b:	85 c0                	test   %eax,%eax
  10710d:	75 18                	jne    107127 <pmap_pagefault+0xa2>
    cprintf("pmap_pagefault: pde for fva %x does not exist\n", fva);
  10710f:	8b 45 d4             	mov    0xffffffd4(%ebp),%eax
  107112:	89 44 24 04          	mov    %eax,0x4(%esp)
  107116:	c7 04 24 f0 d0 10 00 	movl   $0x10d0f0,(%esp)
  10711d:	e8 63 43 00 00       	call   10b485 <cprintf>
      return;
  107122:	e9 ad 03 00 00       	jmp    1074d4 <pmap_pagefault+0x44f>
      }

      pte_t *pte = pmap_walk(p->pdir, fva, 1);
  107127:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  10712a:	8b 90 a0 06 00 00    	mov    0x6a0(%eax),%edx
  107130:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
  107137:	00 
  107138:	8b 45 d4             	mov    0xffffffd4(%ebp),%eax
  10713b:	89 44 24 04          	mov    %eax,0x4(%esp)
  10713f:	89 14 24             	mov    %edx,(%esp)
  107142:	e8 9c ee ff ff       	call   105fe3 <pmap_walk>
  107147:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)
      if((*pte & (SYS_READ | SYS_WRITE | PTE_P)) !=
  10714a:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  10714d:	8b 00                	mov    (%eax),%eax
  10714f:	25 01 06 00 00       	and    $0x601,%eax
  107154:	3d 01 06 00 00       	cmp    $0x601,%eax
  107159:	74 18                	je     107173 <pmap_pagefault+0xee>
        (SYS_READ | SYS_WRITE | PTE_P)){
        cprintf("pmap_pagefault: page for fva %x does not exist\n", fva);
  10715b:	8b 45 d4             	mov    0xffffffd4(%ebp),%eax
  10715e:	89 44 24 04          	mov    %eax,0x4(%esp)
  107162:	c7 04 24 20 d1 10 00 	movl   $0x10d120,(%esp)
  107169:	e8 17 43 00 00       	call   10b485 <cprintf>
        return;
  10716e:	e9 61 03 00 00       	jmp    1074d4 <pmap_pagefault+0x44f>
        }

    assert(!(*pte & PTE_W));
  107173:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  107176:	8b 00                	mov    (%eax),%eax
  107178:	83 e0 02             	and    $0x2,%eax
  10717b:	85 c0                	test   %eax,%eax
  10717d:	74 24                	je     1071a3 <pmap_pagefault+0x11e>
  10717f:	c7 44 24 0c 50 d1 10 	movl   $0x10d150,0xc(%esp)
  107186:	00 
  107187:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  10718e:	00 
  10718f:	c7 44 24 04 aa 01 00 	movl   $0x1aa,0x4(%esp)
  107196:	00 
  107197:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  10719e:	e8 95 97 ff ff       	call   100938 <debug_panic>

    uint32_t pg = PGADDR(*pte);
  1071a3:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  1071a6:	8b 00                	mov    (%eax),%eax
  1071a8:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1071ad:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
    if(pg == PTE_ZERO || mem_phys2pi(pg)->refcount > 1){
  1071b0:	b8 00 10 18 00       	mov    $0x181000,%eax
  1071b5:	39 45 e4             	cmp    %eax,0xffffffe4(%ebp)
  1071b8:	74 1f                	je     1071d9 <pmap_pagefault+0x154>
  1071ba:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  1071bd:	c1 e8 0c             	shr    $0xc,%eax
  1071c0:	c1 e0 03             	shl    $0x3,%eax
  1071c3:	89 c2                	mov    %eax,%edx
  1071c5:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  1071ca:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1071cd:	8b 40 04             	mov    0x4(%eax),%eax
  1071d0:	83 f8 01             	cmp    $0x1,%eax
  1071d3:	0f 8e bc 02 00 00    	jle    107495 <pmap_pagefault+0x410>
    pageinfo *npi = mem_alloc();
  1071d9:	e8 3d 9e ff ff       	call   10101b <mem_alloc>
  1071de:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
    assert(npi);
  1071e1:	83 7d e8 00          	cmpl   $0x0,0xffffffe8(%ebp)
  1071e5:	75 24                	jne    10720b <pmap_pagefault+0x186>
  1071e7:	c7 44 24 0c 60 d1 10 	movl   $0x10d160,0xc(%esp)
  1071ee:	00 
  1071ef:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  1071f6:	00 
  1071f7:	c7 44 24 04 af 01 00 	movl   $0x1af,0x4(%esp)
  1071fe:	00 
  1071ff:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  107206:	e8 2d 97 ff ff       	call   100938 <debug_panic>
  10720b:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  10720e:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
// Atomically increment the reference count on a page.
static gcc_inline void
mem_incref(pageinfo *pi)
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  107211:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  107216:	83 c0 08             	add    $0x8,%eax
  107219:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  10721c:	73 17                	jae    107235 <pmap_pagefault+0x1b0>
  10721e:	a1 84 ed 17 00       	mov    0x17ed84,%eax
  107223:	c1 e0 03             	shl    $0x3,%eax
  107226:	89 c2                	mov    %eax,%edx
  107228:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  10722d:	8d 04 02             	lea    (%edx,%eax,1),%eax
  107230:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  107233:	77 24                	ja     107259 <pmap_pagefault+0x1d4>
  107235:	c7 44 24 0c e8 ce 10 	movl   $0x10cee8,0xc(%esp)
  10723c:	00 
  10723d:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  107244:	00 
  107245:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
  10724c:	00 
  10724d:	c7 04 24 1f cf 10 00 	movl   $0x10cf1f,(%esp)
  107254:	e8 df 96 ff ff       	call   100938 <debug_panic>
	assert(pi != mem_ptr2pi(pmap_zero));	// Don't alloc/free zero page!
  107259:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  10725f:	b8 00 10 18 00       	mov    $0x181000,%eax
  107264:	c1 e8 0c             	shr    $0xc,%eax
  107267:	c1 e0 03             	shl    $0x3,%eax
  10726a:	8d 04 02             	lea    (%edx,%eax,1),%eax
  10726d:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  107270:	75 24                	jne    107296 <pmap_pagefault+0x211>
  107272:	c7 44 24 0c 2c cf 10 	movl   $0x10cf2c,0xc(%esp)
  107279:	00 
  10727a:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  107281:	00 
  107282:	c7 44 24 04 59 00 00 	movl   $0x59,0x4(%esp)
  107289:	00 
  10728a:	c7 04 24 1f cf 10 00 	movl   $0x10cf1f,(%esp)
  107291:	e8 a2 96 ff ff       	call   100938 <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  107296:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  10729c:	b8 0c 00 10 00       	mov    $0x10000c,%eax
  1072a1:	c1 e8 0c             	shr    $0xc,%eax
  1072a4:	c1 e0 03             	shl    $0x3,%eax
  1072a7:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1072aa:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  1072ad:	77 40                	ja     1072ef <pmap_pagefault+0x26a>
  1072af:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  1072b5:	b8 08 20 18 00       	mov    $0x182008,%eax
  1072ba:	83 e8 01             	sub    $0x1,%eax
  1072bd:	c1 e8 0c             	shr    $0xc,%eax
  1072c0:	c1 e0 03             	shl    $0x3,%eax
  1072c3:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1072c6:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  1072c9:	72 24                	jb     1072ef <pmap_pagefault+0x26a>
  1072cb:	c7 44 24 0c 48 cf 10 	movl   $0x10cf48,0xc(%esp)
  1072d2:	00 
  1072d3:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  1072da:	00 
  1072db:	c7 44 24 04 5a 00 00 	movl   $0x5a,0x4(%esp)
  1072e2:	00 
  1072e3:	c7 04 24 1f cf 10 00 	movl   $0x10cf1f,(%esp)
  1072ea:	e8 49 96 ff ff       	call   100938 <debug_panic>

	lockadd(&pi->refcount, 1);
  1072ef:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  1072f2:	83 c0 04             	add    $0x4,%eax
  1072f5:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  1072fc:	00 
  1072fd:	89 04 24             	mov    %eax,(%esp)
  107300:	e8 c5 ea ff ff       	call   105dca <lockadd>
    mem_incref(npi);
    uint32_t npg = mem_pi2phys(npi);
  107305:	8b 55 e8             	mov    0xffffffe8(%ebp),%edx
  107308:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  10730d:	89 d1                	mov    %edx,%ecx
  10730f:	29 c1                	sub    %eax,%ecx
  107311:	89 c8                	mov    %ecx,%eax
  107313:	c1 e0 09             	shl    $0x9,%eax
  107316:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
    memmove((void*)npg, (void*)pg, PAGESIZE);
  107319:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  10731c:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
  10731f:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  107326:	00 
  107327:	89 44 24 04          	mov    %eax,0x4(%esp)
  10732b:	89 14 24             	mov    %edx,(%esp)
  10732e:	e8 4f 45 00 00       	call   10b882 <memmove>
    if(pg != PTE_ZERO)
  107333:	b8 00 10 18 00       	mov    $0x181000,%eax
  107338:	39 45 e4             	cmp    %eax,0xffffffe4(%ebp)
  10733b:	0f 84 4e 01 00 00    	je     10748f <pmap_pagefault+0x40a>
      mem_decref(mem_phys2pi(pg), mem_free);
  107341:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  107344:	c1 e8 0c             	shr    $0xc,%eax
  107347:	c1 e0 03             	shl    $0x3,%eax
  10734a:	89 c2                	mov    %eax,%edx
  10734c:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  107351:	8d 04 02             	lea    (%edx,%eax,1),%eax
  107354:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  107357:	c7 45 f8 5f 10 10 00 	movl   $0x10105f,0xfffffff8(%ebp)
// freeing the page with the provided function if there are no more refs.
static gcc_inline void
mem_decref(pageinfo* pi, void (*freefun)(pageinfo *pi))
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  10735e:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  107363:	83 c0 08             	add    $0x8,%eax
  107366:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  107369:	73 17                	jae    107382 <pmap_pagefault+0x2fd>
  10736b:	a1 84 ed 17 00       	mov    0x17ed84,%eax
  107370:	c1 e0 03             	shl    $0x3,%eax
  107373:	89 c2                	mov    %eax,%edx
  107375:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  10737a:	8d 04 02             	lea    (%edx,%eax,1),%eax
  10737d:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  107380:	77 24                	ja     1073a6 <pmap_pagefault+0x321>
  107382:	c7 44 24 0c e8 ce 10 	movl   $0x10cee8,0xc(%esp)
  107389:	00 
  10738a:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  107391:	00 
  107392:	c7 44 24 04 64 00 00 	movl   $0x64,0x4(%esp)
  107399:	00 
  10739a:	c7 04 24 1f cf 10 00 	movl   $0x10cf1f,(%esp)
  1073a1:	e8 92 95 ff ff       	call   100938 <debug_panic>
	assert(pi != mem_ptr2pi(pmap_zero));	// Don't alloc/free zero page!
  1073a6:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  1073ac:	b8 00 10 18 00       	mov    $0x181000,%eax
  1073b1:	c1 e8 0c             	shr    $0xc,%eax
  1073b4:	c1 e0 03             	shl    $0x3,%eax
  1073b7:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1073ba:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  1073bd:	75 24                	jne    1073e3 <pmap_pagefault+0x35e>
  1073bf:	c7 44 24 0c 2c cf 10 	movl   $0x10cf2c,0xc(%esp)
  1073c6:	00 
  1073c7:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  1073ce:	00 
  1073cf:	c7 44 24 04 65 00 00 	movl   $0x65,0x4(%esp)
  1073d6:	00 
  1073d7:	c7 04 24 1f cf 10 00 	movl   $0x10cf1f,(%esp)
  1073de:	e8 55 95 ff ff       	call   100938 <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  1073e3:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  1073e9:	b8 0c 00 10 00       	mov    $0x10000c,%eax
  1073ee:	c1 e8 0c             	shr    $0xc,%eax
  1073f1:	c1 e0 03             	shl    $0x3,%eax
  1073f4:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1073f7:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  1073fa:	77 40                	ja     10743c <pmap_pagefault+0x3b7>
  1073fc:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  107402:	b8 08 20 18 00       	mov    $0x182008,%eax
  107407:	83 e8 01             	sub    $0x1,%eax
  10740a:	c1 e8 0c             	shr    $0xc,%eax
  10740d:	c1 e0 03             	shl    $0x3,%eax
  107410:	8d 04 02             	lea    (%edx,%eax,1),%eax
  107413:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  107416:	72 24                	jb     10743c <pmap_pagefault+0x3b7>
  107418:	c7 44 24 0c 48 cf 10 	movl   $0x10cf48,0xc(%esp)
  10741f:	00 
  107420:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  107427:	00 
  107428:	c7 44 24 04 66 00 00 	movl   $0x66,0x4(%esp)
  10742f:	00 
  107430:	c7 04 24 1f cf 10 00 	movl   $0x10cf1f,(%esp)
  107437:	e8 fc 94 ff ff       	call   100938 <debug_panic>

	if (lockaddz(&pi->refcount, -1))
  10743c:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  10743f:	83 c0 04             	add    $0x4,%eax
  107442:	c7 44 24 04 ff ff ff 	movl   $0xffffffff,0x4(%esp)
  107449:	ff 
  10744a:	89 04 24             	mov    %eax,(%esp)
  10744d:	e8 75 eb ff ff       	call   105fc7 <lockaddz>
  107452:	84 c0                	test   %al,%al
  107454:	74 0b                	je     107461 <pmap_pagefault+0x3dc>
			freefun(pi);
  107456:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  107459:	89 04 24             	mov    %eax,(%esp)
  10745c:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10745f:	ff d0                	call   *%eax
	assert(pi->refcount >= 0);
  107461:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  107464:	8b 40 04             	mov    0x4(%eax),%eax
  107467:	85 c0                	test   %eax,%eax
  107469:	79 24                	jns    10748f <pmap_pagefault+0x40a>
  10746b:	c7 44 24 0c 79 cf 10 	movl   $0x10cf79,0xc(%esp)
  107472:	00 
  107473:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  10747a:	00 
  10747b:	c7 44 24 04 6a 00 00 	movl   $0x6a,0x4(%esp)
  107482:	00 
  107483:	c7 04 24 1f cf 10 00 	movl   $0x10cf1f,(%esp)
  10748a:	e8 a9 94 ff ff       	call   100938 <debug_panic>
      pg = npg;
  10748f:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  107492:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
      }

      *pte = pg | SYS_RW | PTE_A | PTE_D | PTE_W | PTE_U | PTE_P;
  107495:	8b 55 e4             	mov    0xffffffe4(%ebp),%edx
  107498:	81 ca 67 06 00 00    	or     $0x667,%edx
  10749e:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  1074a1:	89 10                	mov    %edx,(%eax)

      pmap_inval(p->pdir, PGADDR(fva), PAGESIZE);
  1074a3:	8b 55 d4             	mov    0xffffffd4(%ebp),%edx
  1074a6:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
  1074ac:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  1074af:	8b 80 a0 06 00 00    	mov    0x6a0(%eax),%eax
  1074b5:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  1074bc:	00 
  1074bd:	89 54 24 04          	mov    %edx,0x4(%esp)
  1074c1:	89 04 24             	mov    %eax,(%esp)
  1074c4:	e8 e6 f7 ff ff       	call   106caf <pmap_inval>
      trap_return(tf);
  1074c9:	8b 45 08             	mov    0x8(%ebp),%eax
  1074cc:	89 04 24             	mov    %eax,(%esp)
  1074cf:	e8 5c c1 ff ff       	call   103630 <trap_return>
}
  1074d4:	c9                   	leave  
  1074d5:	c3                   	ret    

001074d6 <pmap_mergepage>:

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
  1074d6:	55                   	push   %ebp
  1074d7:	89 e5                	mov    %esp,%ebp
  1074d9:	83 ec 48             	sub    $0x48,%esp
  uint8_t *rpg = (uint8_t*)PGADDR(*rpte);
  1074dc:	8b 45 08             	mov    0x8(%ebp),%eax
  1074df:	8b 00                	mov    (%eax),%eax
  1074e1:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1074e6:	89 45 d4             	mov    %eax,0xffffffd4(%ebp)

  uint8_t *spg = (uint8_t*)PGADDR(*spte);
  1074e9:	8b 45 0c             	mov    0xc(%ebp),%eax
  1074ec:	8b 00                	mov    (%eax),%eax
  1074ee:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1074f3:	89 45 d8             	mov    %eax,0xffffffd8(%ebp)

  uint8_t *dpg = (uint8_t*)PGADDR(*dpte);
  1074f6:	8b 45 10             	mov    0x10(%ebp),%eax
  1074f9:	8b 00                	mov    (%eax),%eax
  1074fb:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  107500:	89 45 dc             	mov    %eax,0xffffffdc(%ebp)
  if(dpg == pmap_zero) return;
  107503:	81 7d dc 00 10 18 00 	cmpl   $0x181000,0xffffffdc(%ebp)
  10750a:	0f 84 d0 04 00 00    	je     1079e0 <pmap_mergepage+0x50a>

  if(dpg == (uint8_t*)PTE_ZERO || mem_ptr2pi(dpg)->refcount > 1){
  107510:	b8 00 10 18 00       	mov    $0x181000,%eax
  107515:	39 45 dc             	cmp    %eax,0xffffffdc(%ebp)
  107518:	74 1f                	je     107539 <pmap_mergepage+0x63>
  10751a:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  10751d:	c1 e8 0c             	shr    $0xc,%eax
  107520:	c1 e0 03             	shl    $0x3,%eax
  107523:	89 c2                	mov    %eax,%edx
  107525:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  10752a:	8d 04 02             	lea    (%edx,%eax,1),%eax
  10752d:	8b 40 04             	mov    0x4(%eax),%eax
  107530:	83 f8 01             	cmp    $0x1,%eax
  107533:	0f 8e cc 02 00 00    	jle    107805 <pmap_mergepage+0x32f>
    pageinfo *npi = mem_alloc(); assert(npi);
  107539:	e8 dd 9a ff ff       	call   10101b <mem_alloc>
  10753e:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
  107541:	83 7d e4 00          	cmpl   $0x0,0xffffffe4(%ebp)
  107545:	75 24                	jne    10756b <pmap_mergepage+0x95>
  107547:	c7 44 24 0c 60 d1 10 	movl   $0x10d160,0xc(%esp)
  10754e:	00 
  10754f:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  107556:	00 
  107557:	c7 44 24 04 d0 01 00 	movl   $0x1d0,0x4(%esp)
  10755e:	00 
  10755f:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  107566:	e8 cd 93 ff ff       	call   100938 <debug_panic>
  10756b:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  10756e:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
// Atomically increment the reference count on a page.
static gcc_inline void
mem_incref(pageinfo *pi)
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  107571:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  107576:	83 c0 08             	add    $0x8,%eax
  107579:	3b 45 ec             	cmp    0xffffffec(%ebp),%eax
  10757c:	73 17                	jae    107595 <pmap_mergepage+0xbf>
  10757e:	a1 84 ed 17 00       	mov    0x17ed84,%eax
  107583:	c1 e0 03             	shl    $0x3,%eax
  107586:	89 c2                	mov    %eax,%edx
  107588:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  10758d:	8d 04 02             	lea    (%edx,%eax,1),%eax
  107590:	3b 45 ec             	cmp    0xffffffec(%ebp),%eax
  107593:	77 24                	ja     1075b9 <pmap_mergepage+0xe3>
  107595:	c7 44 24 0c e8 ce 10 	movl   $0x10cee8,0xc(%esp)
  10759c:	00 
  10759d:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  1075a4:	00 
  1075a5:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
  1075ac:	00 
  1075ad:	c7 04 24 1f cf 10 00 	movl   $0x10cf1f,(%esp)
  1075b4:	e8 7f 93 ff ff       	call   100938 <debug_panic>
	assert(pi != mem_ptr2pi(pmap_zero));	// Don't alloc/free zero page!
  1075b9:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  1075bf:	b8 00 10 18 00       	mov    $0x181000,%eax
  1075c4:	c1 e8 0c             	shr    $0xc,%eax
  1075c7:	c1 e0 03             	shl    $0x3,%eax
  1075ca:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1075cd:	3b 45 ec             	cmp    0xffffffec(%ebp),%eax
  1075d0:	75 24                	jne    1075f6 <pmap_mergepage+0x120>
  1075d2:	c7 44 24 0c 2c cf 10 	movl   $0x10cf2c,0xc(%esp)
  1075d9:	00 
  1075da:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  1075e1:	00 
  1075e2:	c7 44 24 04 59 00 00 	movl   $0x59,0x4(%esp)
  1075e9:	00 
  1075ea:	c7 04 24 1f cf 10 00 	movl   $0x10cf1f,(%esp)
  1075f1:	e8 42 93 ff ff       	call   100938 <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  1075f6:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  1075fc:	b8 0c 00 10 00       	mov    $0x10000c,%eax
  107601:	c1 e8 0c             	shr    $0xc,%eax
  107604:	c1 e0 03             	shl    $0x3,%eax
  107607:	8d 04 02             	lea    (%edx,%eax,1),%eax
  10760a:	3b 45 ec             	cmp    0xffffffec(%ebp),%eax
  10760d:	77 40                	ja     10764f <pmap_mergepage+0x179>
  10760f:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  107615:	b8 08 20 18 00       	mov    $0x182008,%eax
  10761a:	83 e8 01             	sub    $0x1,%eax
  10761d:	c1 e8 0c             	shr    $0xc,%eax
  107620:	c1 e0 03             	shl    $0x3,%eax
  107623:	8d 04 02             	lea    (%edx,%eax,1),%eax
  107626:	3b 45 ec             	cmp    0xffffffec(%ebp),%eax
  107629:	72 24                	jb     10764f <pmap_mergepage+0x179>
  10762b:	c7 44 24 0c 48 cf 10 	movl   $0x10cf48,0xc(%esp)
  107632:	00 
  107633:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  10763a:	00 
  10763b:	c7 44 24 04 5a 00 00 	movl   $0x5a,0x4(%esp)
  107642:	00 
  107643:	c7 04 24 1f cf 10 00 	movl   $0x10cf1f,(%esp)
  10764a:	e8 e9 92 ff ff       	call   100938 <debug_panic>

	lockadd(&pi->refcount, 1);
  10764f:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  107652:	83 c0 04             	add    $0x4,%eax
  107655:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  10765c:	00 
  10765d:	89 04 24             	mov    %eax,(%esp)
  107660:	e8 65 e7 ff ff       	call   105dca <lockadd>
    mem_incref(npi);
    uint8_t *npg = mem_pi2ptr(npi);
  107665:	8b 55 e4             	mov    0xffffffe4(%ebp),%edx
  107668:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  10766d:	89 d1                	mov    %edx,%ecx
  10766f:	29 c1                	sub    %eax,%ecx
  107671:	89 c8                	mov    %ecx,%eax
  107673:	c1 e0 09             	shl    $0x9,%eax
  107676:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
    memmove(npg, dpg, PAGESIZE);
  107679:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  107680:	00 
  107681:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  107684:	89 44 24 04          	mov    %eax,0x4(%esp)
  107688:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  10768b:	89 04 24             	mov    %eax,(%esp)
  10768e:	e8 ef 41 00 00       	call   10b882 <memmove>
    if(dpg != (uint8_t*)PTE_ZERO)
  107693:	b8 00 10 18 00       	mov    $0x181000,%eax
  107698:	39 45 dc             	cmp    %eax,0xffffffdc(%ebp)
  10769b:	0f 84 4e 01 00 00    	je     1077ef <pmap_mergepage+0x319>
      mem_decref(mem_ptr2pi(dpg), mem_free);
  1076a1:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  1076a4:	c1 e8 0c             	shr    $0xc,%eax
  1076a7:	c1 e0 03             	shl    $0x3,%eax
  1076aa:	89 c2                	mov    %eax,%edx
  1076ac:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  1076b1:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1076b4:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
  1076b7:	c7 45 f0 5f 10 10 00 	movl   $0x10105f,0xfffffff0(%ebp)
// freeing the page with the provided function if there are no more refs.
static gcc_inline void
mem_decref(pageinfo* pi, void (*freefun)(pageinfo *pi))
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  1076be:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  1076c3:	83 c0 08             	add    $0x8,%eax
  1076c6:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  1076c9:	73 17                	jae    1076e2 <pmap_mergepage+0x20c>
  1076cb:	a1 84 ed 17 00       	mov    0x17ed84,%eax
  1076d0:	c1 e0 03             	shl    $0x3,%eax
  1076d3:	89 c2                	mov    %eax,%edx
  1076d5:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  1076da:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1076dd:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  1076e0:	77 24                	ja     107706 <pmap_mergepage+0x230>
  1076e2:	c7 44 24 0c e8 ce 10 	movl   $0x10cee8,0xc(%esp)
  1076e9:	00 
  1076ea:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  1076f1:	00 
  1076f2:	c7 44 24 04 64 00 00 	movl   $0x64,0x4(%esp)
  1076f9:	00 
  1076fa:	c7 04 24 1f cf 10 00 	movl   $0x10cf1f,(%esp)
  107701:	e8 32 92 ff ff       	call   100938 <debug_panic>
	assert(pi != mem_ptr2pi(pmap_zero));	// Don't alloc/free zero page!
  107706:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  10770c:	b8 00 10 18 00       	mov    $0x181000,%eax
  107711:	c1 e8 0c             	shr    $0xc,%eax
  107714:	c1 e0 03             	shl    $0x3,%eax
  107717:	8d 04 02             	lea    (%edx,%eax,1),%eax
  10771a:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  10771d:	75 24                	jne    107743 <pmap_mergepage+0x26d>
  10771f:	c7 44 24 0c 2c cf 10 	movl   $0x10cf2c,0xc(%esp)
  107726:	00 
  107727:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  10772e:	00 
  10772f:	c7 44 24 04 65 00 00 	movl   $0x65,0x4(%esp)
  107736:	00 
  107737:	c7 04 24 1f cf 10 00 	movl   $0x10cf1f,(%esp)
  10773e:	e8 f5 91 ff ff       	call   100938 <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  107743:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  107749:	b8 0c 00 10 00       	mov    $0x10000c,%eax
  10774e:	c1 e8 0c             	shr    $0xc,%eax
  107751:	c1 e0 03             	shl    $0x3,%eax
  107754:	8d 04 02             	lea    (%edx,%eax,1),%eax
  107757:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  10775a:	77 40                	ja     10779c <pmap_mergepage+0x2c6>
  10775c:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  107762:	b8 08 20 18 00       	mov    $0x182008,%eax
  107767:	83 e8 01             	sub    $0x1,%eax
  10776a:	c1 e8 0c             	shr    $0xc,%eax
  10776d:	c1 e0 03             	shl    $0x3,%eax
  107770:	8d 04 02             	lea    (%edx,%eax,1),%eax
  107773:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  107776:	72 24                	jb     10779c <pmap_mergepage+0x2c6>
  107778:	c7 44 24 0c 48 cf 10 	movl   $0x10cf48,0xc(%esp)
  10777f:	00 
  107780:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  107787:	00 
  107788:	c7 44 24 04 66 00 00 	movl   $0x66,0x4(%esp)
  10778f:	00 
  107790:	c7 04 24 1f cf 10 00 	movl   $0x10cf1f,(%esp)
  107797:	e8 9c 91 ff ff       	call   100938 <debug_panic>

	if (lockaddz(&pi->refcount, -1))
  10779c:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  10779f:	83 c0 04             	add    $0x4,%eax
  1077a2:	c7 44 24 04 ff ff ff 	movl   $0xffffffff,0x4(%esp)
  1077a9:	ff 
  1077aa:	89 04 24             	mov    %eax,(%esp)
  1077ad:	e8 15 e8 ff ff       	call   105fc7 <lockaddz>
  1077b2:	84 c0                	test   %al,%al
  1077b4:	74 0b                	je     1077c1 <pmap_mergepage+0x2eb>
			freefun(pi);
  1077b6:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  1077b9:	89 04 24             	mov    %eax,(%esp)
  1077bc:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  1077bf:	ff d0                	call   *%eax
	assert(pi->refcount >= 0);
  1077c1:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  1077c4:	8b 40 04             	mov    0x4(%eax),%eax
  1077c7:	85 c0                	test   %eax,%eax
  1077c9:	79 24                	jns    1077ef <pmap_mergepage+0x319>
  1077cb:	c7 44 24 0c 79 cf 10 	movl   $0x10cf79,0xc(%esp)
  1077d2:	00 
  1077d3:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  1077da:	00 
  1077db:	c7 44 24 04 6a 00 00 	movl   $0x6a,0x4(%esp)
  1077e2:	00 
  1077e3:	c7 04 24 1f cf 10 00 	movl   $0x10cf1f,(%esp)
  1077ea:	e8 49 91 ff ff       	call   100938 <debug_panic>
      dpg = npg;
  1077ef:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  1077f2:	89 45 dc             	mov    %eax,0xffffffdc(%ebp)
      *dpte = (uint32_t)npg | SYS_RW | PTE_A | PTE_D | PTE_W | PTE_U | PTE_P;
  1077f5:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  1077f8:	89 c2                	mov    %eax,%edx
  1077fa:	81 ca 67 06 00 00    	or     $0x667,%edx
  107800:	8b 45 10             	mov    0x10(%ebp),%eax
  107803:	89 10                	mov    %edx,(%eax)
      }

      int i;
      for(i = 0; i < PAGESIZE; i++){
  107805:	c7 45 e0 00 00 00 00 	movl   $0x0,0xffffffe0(%ebp)
  10780c:	e9 c2 01 00 00       	jmp    1079d3 <pmap_mergepage+0x4fd>
      if(spg[i] == rpg[i])
  107811:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  107814:	03 45 d8             	add    0xffffffd8(%ebp),%eax
  107817:	0f b6 10             	movzbl (%eax),%edx
  10781a:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  10781d:	03 45 d4             	add    0xffffffd4(%ebp),%eax
  107820:	0f b6 00             	movzbl (%eax),%eax
  107823:	38 c2                	cmp    %al,%dl
  107825:	0f 84 a4 01 00 00    	je     1079cf <pmap_mergepage+0x4f9>
      continue;
      if(dpg[i] == rpg[i]){
  10782b:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  10782e:	03 45 dc             	add    0xffffffdc(%ebp),%eax
  107831:	0f b6 10             	movzbl (%eax),%edx
  107834:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  107837:	03 45 d4             	add    0xffffffd4(%ebp),%eax
  10783a:	0f b6 00             	movzbl (%eax),%eax
  10783d:	38 c2                	cmp    %al,%dl
  10783f:	75 18                	jne    107859 <pmap_mergepage+0x383>
      dpg[i] = spg[i];
  107841:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  107844:	89 c2                	mov    %eax,%edx
  107846:	03 55 dc             	add    0xffffffdc(%ebp),%edx
  107849:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  10784c:	03 45 d8             	add    0xffffffd8(%ebp),%eax
  10784f:	0f b6 00             	movzbl (%eax),%eax
  107852:	88 02                	mov    %al,(%edx)
      continue;
  107854:	e9 76 01 00 00       	jmp    1079cf <pmap_mergepage+0x4f9>
      }

      cprintf("pmap_mergepage: conflict ad dva %x\n", dva);
  107859:	8b 45 14             	mov    0x14(%ebp),%eax
  10785c:	89 44 24 04          	mov    %eax,0x4(%esp)
  107860:	c7 04 24 64 d1 10 00 	movl   $0x10d164,(%esp)
  107867:	e8 19 3c 00 00       	call   10b485 <cprintf>
      mem_decref(mem_phys2pi(PGADDR(*dpte)), mem_free);
  10786c:	8b 45 10             	mov    0x10(%ebp),%eax
  10786f:	8b 00                	mov    (%eax),%eax
  107871:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  107876:	c1 e8 0c             	shr    $0xc,%eax
  107879:	c1 e0 03             	shl    $0x3,%eax
  10787c:	89 c2                	mov    %eax,%edx
  10787e:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  107883:	8d 04 02             	lea    (%edx,%eax,1),%eax
  107886:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  107889:	c7 45 f8 5f 10 10 00 	movl   $0x10105f,0xfffffff8(%ebp)
// freeing the page with the provided function if there are no more refs.
static gcc_inline void
mem_decref(pageinfo* pi, void (*freefun)(pageinfo *pi))
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  107890:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  107895:	83 c0 08             	add    $0x8,%eax
  107898:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  10789b:	73 17                	jae    1078b4 <pmap_mergepage+0x3de>
  10789d:	a1 84 ed 17 00       	mov    0x17ed84,%eax
  1078a2:	c1 e0 03             	shl    $0x3,%eax
  1078a5:	89 c2                	mov    %eax,%edx
  1078a7:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  1078ac:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1078af:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  1078b2:	77 24                	ja     1078d8 <pmap_mergepage+0x402>
  1078b4:	c7 44 24 0c e8 ce 10 	movl   $0x10cee8,0xc(%esp)
  1078bb:	00 
  1078bc:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  1078c3:	00 
  1078c4:	c7 44 24 04 64 00 00 	movl   $0x64,0x4(%esp)
  1078cb:	00 
  1078cc:	c7 04 24 1f cf 10 00 	movl   $0x10cf1f,(%esp)
  1078d3:	e8 60 90 ff ff       	call   100938 <debug_panic>
	assert(pi != mem_ptr2pi(pmap_zero));	// Don't alloc/free zero page!
  1078d8:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  1078de:	b8 00 10 18 00       	mov    $0x181000,%eax
  1078e3:	c1 e8 0c             	shr    $0xc,%eax
  1078e6:	c1 e0 03             	shl    $0x3,%eax
  1078e9:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1078ec:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  1078ef:	75 24                	jne    107915 <pmap_mergepage+0x43f>
  1078f1:	c7 44 24 0c 2c cf 10 	movl   $0x10cf2c,0xc(%esp)
  1078f8:	00 
  1078f9:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  107900:	00 
  107901:	c7 44 24 04 65 00 00 	movl   $0x65,0x4(%esp)
  107908:	00 
  107909:	c7 04 24 1f cf 10 00 	movl   $0x10cf1f,(%esp)
  107910:	e8 23 90 ff ff       	call   100938 <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  107915:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  10791b:	b8 0c 00 10 00       	mov    $0x10000c,%eax
  107920:	c1 e8 0c             	shr    $0xc,%eax
  107923:	c1 e0 03             	shl    $0x3,%eax
  107926:	8d 04 02             	lea    (%edx,%eax,1),%eax
  107929:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  10792c:	77 40                	ja     10796e <pmap_mergepage+0x498>
  10792e:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  107934:	b8 08 20 18 00       	mov    $0x182008,%eax
  107939:	83 e8 01             	sub    $0x1,%eax
  10793c:	c1 e8 0c             	shr    $0xc,%eax
  10793f:	c1 e0 03             	shl    $0x3,%eax
  107942:	8d 04 02             	lea    (%edx,%eax,1),%eax
  107945:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  107948:	72 24                	jb     10796e <pmap_mergepage+0x498>
  10794a:	c7 44 24 0c 48 cf 10 	movl   $0x10cf48,0xc(%esp)
  107951:	00 
  107952:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  107959:	00 
  10795a:	c7 44 24 04 66 00 00 	movl   $0x66,0x4(%esp)
  107961:	00 
  107962:	c7 04 24 1f cf 10 00 	movl   $0x10cf1f,(%esp)
  107969:	e8 ca 8f ff ff       	call   100938 <debug_panic>

	if (lockaddz(&pi->refcount, -1))
  10796e:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  107971:	83 c0 04             	add    $0x4,%eax
  107974:	c7 44 24 04 ff ff ff 	movl   $0xffffffff,0x4(%esp)
  10797b:	ff 
  10797c:	89 04 24             	mov    %eax,(%esp)
  10797f:	e8 43 e6 ff ff       	call   105fc7 <lockaddz>
  107984:	84 c0                	test   %al,%al
  107986:	74 0b                	je     107993 <pmap_mergepage+0x4bd>
			freefun(pi);
  107988:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  10798b:	89 04 24             	mov    %eax,(%esp)
  10798e:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  107991:	ff d0                	call   *%eax
	assert(pi->refcount >= 0);
  107993:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  107996:	8b 40 04             	mov    0x4(%eax),%eax
  107999:	85 c0                	test   %eax,%eax
  10799b:	79 24                	jns    1079c1 <pmap_mergepage+0x4eb>
  10799d:	c7 44 24 0c 79 cf 10 	movl   $0x10cf79,0xc(%esp)
  1079a4:	00 
  1079a5:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  1079ac:	00 
  1079ad:	c7 44 24 04 6a 00 00 	movl   $0x6a,0x4(%esp)
  1079b4:	00 
  1079b5:	c7 04 24 1f cf 10 00 	movl   $0x10cf1f,(%esp)
  1079bc:	e8 77 8f ff ff       	call   100938 <debug_panic>
      *dpte = PTE_ZERO;
  1079c1:	b8 00 10 18 00       	mov    $0x181000,%eax
  1079c6:	89 c2                	mov    %eax,%edx
  1079c8:	8b 45 10             	mov    0x10(%ebp),%eax
  1079cb:	89 10                	mov    %edx,(%eax)
      return;
  1079cd:	eb 11                	jmp    1079e0 <pmap_mergepage+0x50a>
  1079cf:	83 45 e0 01          	addl   $0x1,0xffffffe0(%ebp)
  1079d3:	81 7d e0 ff 0f 00 00 	cmpl   $0xfff,0xffffffe0(%ebp)
  1079da:	0f 8e 31 fe ff ff    	jle    107811 <pmap_mergepage+0x33b>
      }
      
}
  1079e0:	c9                   	leave  
  1079e1:	c3                   	ret    

001079e2 <pmap_merge>:

// 
// Merge differences between a reference snapshot represented by rpdir
// and a source address space spdir into a destination address space dpdir.
//
int
pmap_merge(pde_t *rpdir, pde_t *spdir, uint32_t sva,
		pde_t *dpdir, uint32_t dva, size_t size)
{
  1079e2:	55                   	push   %ebp
  1079e3:	89 e5                	mov    %esp,%ebp
  1079e5:	83 ec 48             	sub    $0x48,%esp
	assert(PTOFF(sva) == 0);	// must be 4MB-aligned
  1079e8:	8b 45 10             	mov    0x10(%ebp),%eax
  1079eb:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  1079f0:	85 c0                	test   %eax,%eax
  1079f2:	74 24                	je     107a18 <pmap_merge+0x36>
  1079f4:	c7 44 24 0c 10 d0 10 	movl   $0x10d010,0xc(%esp)
  1079fb:	00 
  1079fc:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  107a03:	00 
  107a04:	c7 44 24 04 f3 01 00 	movl   $0x1f3,0x4(%esp)
  107a0b:	00 
  107a0c:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  107a13:	e8 20 8f ff ff       	call   100938 <debug_panic>
	assert(PTOFF(dva) == 0);
  107a18:	8b 45 18             	mov    0x18(%ebp),%eax
  107a1b:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  107a20:	85 c0                	test   %eax,%eax
  107a22:	74 24                	je     107a48 <pmap_merge+0x66>
  107a24:	c7 44 24 0c 20 d0 10 	movl   $0x10d020,0xc(%esp)
  107a2b:	00 
  107a2c:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  107a33:	00 
  107a34:	c7 44 24 04 f4 01 00 	movl   $0x1f4,0x4(%esp)
  107a3b:	00 
  107a3c:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  107a43:	e8 f0 8e ff ff       	call   100938 <debug_panic>
	assert(PTOFF(size) == 0);
  107a48:	8b 45 1c             	mov    0x1c(%ebp),%eax
  107a4b:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  107a50:	85 c0                	test   %eax,%eax
  107a52:	74 24                	je     107a78 <pmap_merge+0x96>
  107a54:	c7 44 24 0c 30 d0 10 	movl   $0x10d030,0xc(%esp)
  107a5b:	00 
  107a5c:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  107a63:	00 
  107a64:	c7 44 24 04 f5 01 00 	movl   $0x1f5,0x4(%esp)
  107a6b:	00 
  107a6c:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  107a73:	e8 c0 8e ff ff       	call   100938 <debug_panic>
	assert(sva >= VM_USERLO && sva < VM_USERHI);
  107a78:	81 7d 10 ff ff ff 3f 	cmpl   $0x3fffffff,0x10(%ebp)
  107a7f:	76 09                	jbe    107a8a <pmap_merge+0xa8>
  107a81:	81 7d 10 ff ff ff ef 	cmpl   $0xefffffff,0x10(%ebp)
  107a88:	76 24                	jbe    107aae <pmap_merge+0xcc>
  107a8a:	c7 44 24 0c 44 d0 10 	movl   $0x10d044,0xc(%esp)
  107a91:	00 
  107a92:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  107a99:	00 
  107a9a:	c7 44 24 04 f6 01 00 	movl   $0x1f6,0x4(%esp)
  107aa1:	00 
  107aa2:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  107aa9:	e8 8a 8e ff ff       	call   100938 <debug_panic>
	assert(dva >= VM_USERLO && dva < VM_USERHI);
  107aae:	81 7d 18 ff ff ff 3f 	cmpl   $0x3fffffff,0x18(%ebp)
  107ab5:	76 09                	jbe    107ac0 <pmap_merge+0xde>
  107ab7:	81 7d 18 ff ff ff ef 	cmpl   $0xefffffff,0x18(%ebp)
  107abe:	76 24                	jbe    107ae4 <pmap_merge+0x102>
  107ac0:	c7 44 24 0c 68 d0 10 	movl   $0x10d068,0xc(%esp)
  107ac7:	00 
  107ac8:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  107acf:	00 
  107ad0:	c7 44 24 04 f7 01 00 	movl   $0x1f7,0x4(%esp)
  107ad7:	00 
  107ad8:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  107adf:	e8 54 8e ff ff       	call   100938 <debug_panic>
	assert(size <= VM_USERHI - sva);
  107ae4:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
  107ae9:	2b 45 10             	sub    0x10(%ebp),%eax
  107aec:	3b 45 1c             	cmp    0x1c(%ebp),%eax
  107aef:	73 24                	jae    107b15 <pmap_merge+0x133>
  107af1:	c7 44 24 0c 8c d0 10 	movl   $0x10d08c,0xc(%esp)
  107af8:	00 
  107af9:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  107b00:	00 
  107b01:	c7 44 24 04 f8 01 00 	movl   $0x1f8,0x4(%esp)
  107b08:	00 
  107b09:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  107b10:	e8 23 8e ff ff       	call   100938 <debug_panic>
	assert(size <= VM_USERHI - dva);
  107b15:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
  107b1a:	2b 45 18             	sub    0x18(%ebp),%eax
  107b1d:	3b 45 1c             	cmp    0x1c(%ebp),%eax
  107b20:	73 24                	jae    107b46 <pmap_merge+0x164>
  107b22:	c7 44 24 0c a4 d0 10 	movl   $0x10d0a4,0xc(%esp)
  107b29:	00 
  107b2a:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  107b31:	00 
  107b32:	c7 44 24 04 f9 01 00 	movl   $0x1f9,0x4(%esp)
  107b39:	00 
  107b3a:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  107b41:	e8 f2 8d ff ff       	call   100938 <debug_panic>

  pde_t *rpde = &rpdir[PDX(sva)];
  107b46:	8b 45 10             	mov    0x10(%ebp),%eax
  107b49:	c1 e8 16             	shr    $0x16,%eax
  107b4c:	25 ff 03 00 00       	and    $0x3ff,%eax
  107b51:	c1 e0 02             	shl    $0x2,%eax
  107b54:	03 45 08             	add    0x8(%ebp),%eax
  107b57:	89 45 d4             	mov    %eax,0xffffffd4(%ebp)
  pde_t *spde = &spdir[PDX(sva)];
  107b5a:	8b 45 10             	mov    0x10(%ebp),%eax
  107b5d:	c1 e8 16             	shr    $0x16,%eax
  107b60:	25 ff 03 00 00       	and    $0x3ff,%eax
  107b65:	c1 e0 02             	shl    $0x2,%eax
  107b68:	03 45 0c             	add    0xc(%ebp),%eax
  107b6b:	89 45 d8             	mov    %eax,0xffffffd8(%ebp)
  pde_t *dpde = &dpdir[PDX(dva)];
  107b6e:	8b 45 18             	mov    0x18(%ebp),%eax
  107b71:	c1 e8 16             	shr    $0x16,%eax
  107b74:	25 ff 03 00 00       	and    $0x3ff,%eax
  107b79:	c1 e0 02             	shl    $0x2,%eax
  107b7c:	03 45 14             	add    0x14(%ebp),%eax
  107b7f:	89 45 dc             	mov    %eax,0xffffffdc(%ebp)
  uint32_t svahi = sva + size;
  107b82:	8b 45 1c             	mov    0x1c(%ebp),%eax
  107b85:	03 45 10             	add    0x10(%ebp),%eax
  107b88:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)

  for (; sva < svahi; rpde++, spde++, dpde++){
  107b8b:	e9 e4 03 00 00       	jmp    107f74 <pmap_merge+0x592>
  if(*spde == *rpde){
  107b90:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  107b93:	8b 10                	mov    (%eax),%edx
  107b95:	8b 45 d4             	mov    0xffffffd4(%ebp),%eax
  107b98:	8b 00                	mov    (%eax),%eax
  107b9a:	39 c2                	cmp    %eax,%edx
  107b9c:	75 13                	jne    107bb1 <pmap_merge+0x1cf>
  sva += PTSIZE, dva += PTSIZE;
  107b9e:	81 45 10 00 00 40 00 	addl   $0x400000,0x10(%ebp)
  107ba5:	81 45 18 00 00 40 00 	addl   $0x400000,0x18(%ebp)
  continue;
  107bac:	e9 b7 03 00 00       	jmp    107f68 <pmap_merge+0x586>
  }

  if(*dpde == *rpde){
  107bb1:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  107bb4:	8b 10                	mov    (%eax),%edx
  107bb6:	8b 45 d4             	mov    0xffffffd4(%ebp),%eax
  107bb9:	8b 00                	mov    (%eax),%eax
  107bbb:	39 c2                	cmp    %eax,%edx
  107bbd:	75 4b                	jne    107c0a <pmap_merge+0x228>
    if(!pmap_copy(spdir, sva, dpdir, dva, PTSIZE))
  107bbf:	c7 44 24 10 00 00 40 	movl   $0x400000,0x10(%esp)
  107bc6:	00 
  107bc7:	8b 45 18             	mov    0x18(%ebp),%eax
  107bca:	89 44 24 0c          	mov    %eax,0xc(%esp)
  107bce:	8b 45 14             	mov    0x14(%ebp),%eax
  107bd1:	89 44 24 08          	mov    %eax,0x8(%esp)
  107bd5:	8b 45 10             	mov    0x10(%ebp),%eax
  107bd8:	89 44 24 04          	mov    %eax,0x4(%esp)
  107bdc:	8b 45 0c             	mov    0xc(%ebp),%eax
  107bdf:	89 04 24             	mov    %eax,(%esp)
  107be2:	e8 15 f1 ff ff       	call   106cfc <pmap_copy>
  107be7:	85 c0                	test   %eax,%eax
  107be9:	75 0c                	jne    107bf7 <pmap_merge+0x215>
      return 0;
  107beb:	c7 45 cc 00 00 00 00 	movl   $0x0,0xffffffcc(%ebp)
  107bf2:	e9 90 03 00 00       	jmp    107f87 <pmap_merge+0x5a5>
      sva += PTSIZE, dva += PTSIZE;
  107bf7:	81 45 10 00 00 40 00 	addl   $0x400000,0x10(%ebp)
  107bfe:	81 45 18 00 00 40 00 	addl   $0x400000,0x18(%ebp)
      continue;
  107c05:	e9 5e 03 00 00       	jmp    107f68 <pmap_merge+0x586>
      }

      pte_t *rpte = mem_ptr(PGADDR(*rpde));
  107c0a:	8b 45 d4             	mov    0xffffffd4(%ebp),%eax
  107c0d:	8b 00                	mov    (%eax),%eax
  107c0f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  107c14:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
      pte_t *spte = mem_ptr(PGADDR(*spde));
  107c17:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  107c1a:	8b 00                	mov    (%eax),%eax
  107c1c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  107c21:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
      pte_t *dpte = pmap_walk(dpdir, dva, 1);
  107c24:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
  107c2b:	00 
  107c2c:	8b 45 18             	mov    0x18(%ebp),%eax
  107c2f:	89 44 24 04          	mov    %eax,0x4(%esp)
  107c33:	8b 45 14             	mov    0x14(%ebp),%eax
  107c36:	89 04 24             	mov    %eax,(%esp)
  107c39:	e8 a5 e3 ff ff       	call   105fe3 <pmap_walk>
  107c3e:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
      if (dpte == NULL)
  107c41:	83 7d ec 00          	cmpl   $0x0,0xffffffec(%ebp)
  107c45:	75 0c                	jne    107c53 <pmap_merge+0x271>
        return 0;
  107c47:	c7 45 cc 00 00 00 00 	movl   $0x0,0xffffffcc(%ebp)
  107c4e:	e9 34 03 00 00       	jmp    107f87 <pmap_merge+0x5a5>

        pte_t *erpte = &rpte[NPTENTRIES];
  107c53:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  107c56:	05 00 10 00 00       	add    $0x1000,%eax
  107c5b:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
        for(; rpte <erpte; rpte++, spte++, dpte++, sva += PAGESIZE, dva += PAGESIZE){
  107c5e:	e9 f9 02 00 00       	jmp    107f5c <pmap_merge+0x57a>
        
        if (*spte == *rpte)
  107c63:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  107c66:	8b 10                	mov    (%eax),%edx
  107c68:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  107c6b:	8b 00                	mov    (%eax),%eax
  107c6d:	39 c2                	cmp    %eax,%edx
  107c6f:	0f 84 cd 02 00 00    	je     107f42 <pmap_merge+0x560>
        continue;
        if (*dpte == *rpte)
  107c75:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  107c78:	8b 10                	mov    (%eax),%edx
  107c7a:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  107c7d:	8b 00                	mov    (%eax),%eax
  107c7f:	39 c2                	cmp    %eax,%edx
  107c81:	0f 85 9b 02 00 00    	jne    107f22 <pmap_merge+0x540>
        { if(PGADDR(*dpte) != PTE_ZERO)
  107c87:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  107c8a:	8b 00                	mov    (%eax),%eax
  107c8c:	89 c2                	mov    %eax,%edx
  107c8e:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
  107c94:	b8 00 10 18 00       	mov    $0x181000,%eax
  107c99:	39 c2                	cmp    %eax,%edx
  107c9b:	0f 84 55 01 00 00    	je     107df6 <pmap_merge+0x414>
          mem_decref(mem_phys2pi(PGADDR(*dpte)),mem_free);
  107ca1:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  107ca4:	8b 00                	mov    (%eax),%eax
  107ca6:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  107cab:	c1 e8 0c             	shr    $0xc,%eax
  107cae:	c1 e0 03             	shl    $0x3,%eax
  107cb1:	89 c2                	mov    %eax,%edx
  107cb3:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  107cb8:	8d 04 02             	lea    (%edx,%eax,1),%eax
  107cbb:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  107cbe:	c7 45 f4 5f 10 10 00 	movl   $0x10105f,0xfffffff4(%ebp)
// freeing the page with the provided function if there are no more refs.
static gcc_inline void
mem_decref(pageinfo* pi, void (*freefun)(pageinfo *pi))
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  107cc5:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  107cca:	83 c0 08             	add    $0x8,%eax
  107ccd:	3b 45 f8             	cmp    0xfffffff8(%ebp),%eax
  107cd0:	73 17                	jae    107ce9 <pmap_merge+0x307>
  107cd2:	a1 84 ed 17 00       	mov    0x17ed84,%eax
  107cd7:	c1 e0 03             	shl    $0x3,%eax
  107cda:	89 c2                	mov    %eax,%edx
  107cdc:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  107ce1:	8d 04 02             	lea    (%edx,%eax,1),%eax
  107ce4:	3b 45 f8             	cmp    0xfffffff8(%ebp),%eax
  107ce7:	77 24                	ja     107d0d <pmap_merge+0x32b>
  107ce9:	c7 44 24 0c e8 ce 10 	movl   $0x10cee8,0xc(%esp)
  107cf0:	00 
  107cf1:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  107cf8:	00 
  107cf9:	c7 44 24 04 64 00 00 	movl   $0x64,0x4(%esp)
  107d00:	00 
  107d01:	c7 04 24 1f cf 10 00 	movl   $0x10cf1f,(%esp)
  107d08:	e8 2b 8c ff ff       	call   100938 <debug_panic>
	assert(pi != mem_ptr2pi(pmap_zero));	// Don't alloc/free zero page!
  107d0d:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  107d13:	b8 00 10 18 00       	mov    $0x181000,%eax
  107d18:	c1 e8 0c             	shr    $0xc,%eax
  107d1b:	c1 e0 03             	shl    $0x3,%eax
  107d1e:	8d 04 02             	lea    (%edx,%eax,1),%eax
  107d21:	3b 45 f8             	cmp    0xfffffff8(%ebp),%eax
  107d24:	75 24                	jne    107d4a <pmap_merge+0x368>
  107d26:	c7 44 24 0c 2c cf 10 	movl   $0x10cf2c,0xc(%esp)
  107d2d:	00 
  107d2e:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  107d35:	00 
  107d36:	c7 44 24 04 65 00 00 	movl   $0x65,0x4(%esp)
  107d3d:	00 
  107d3e:	c7 04 24 1f cf 10 00 	movl   $0x10cf1f,(%esp)
  107d45:	e8 ee 8b ff ff       	call   100938 <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  107d4a:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  107d50:	b8 0c 00 10 00       	mov    $0x10000c,%eax
  107d55:	c1 e8 0c             	shr    $0xc,%eax
  107d58:	c1 e0 03             	shl    $0x3,%eax
  107d5b:	8d 04 02             	lea    (%edx,%eax,1),%eax
  107d5e:	3b 45 f8             	cmp    0xfffffff8(%ebp),%eax
  107d61:	77 40                	ja     107da3 <pmap_merge+0x3c1>
  107d63:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  107d69:	b8 08 20 18 00       	mov    $0x182008,%eax
  107d6e:	83 e8 01             	sub    $0x1,%eax
  107d71:	c1 e8 0c             	shr    $0xc,%eax
  107d74:	c1 e0 03             	shl    $0x3,%eax
  107d77:	8d 04 02             	lea    (%edx,%eax,1),%eax
  107d7a:	3b 45 f8             	cmp    0xfffffff8(%ebp),%eax
  107d7d:	72 24                	jb     107da3 <pmap_merge+0x3c1>
  107d7f:	c7 44 24 0c 48 cf 10 	movl   $0x10cf48,0xc(%esp)
  107d86:	00 
  107d87:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  107d8e:	00 
  107d8f:	c7 44 24 04 66 00 00 	movl   $0x66,0x4(%esp)
  107d96:	00 
  107d97:	c7 04 24 1f cf 10 00 	movl   $0x10cf1f,(%esp)
  107d9e:	e8 95 8b ff ff       	call   100938 <debug_panic>

	if (lockaddz(&pi->refcount, -1))
  107da3:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  107da6:	83 c0 04             	add    $0x4,%eax
  107da9:	c7 44 24 04 ff ff ff 	movl   $0xffffffff,0x4(%esp)
  107db0:	ff 
  107db1:	89 04 24             	mov    %eax,(%esp)
  107db4:	e8 0e e2 ff ff       	call   105fc7 <lockaddz>
  107db9:	84 c0                	test   %al,%al
  107dbb:	74 0b                	je     107dc8 <pmap_merge+0x3e6>
			freefun(pi);
  107dbd:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  107dc0:	89 04 24             	mov    %eax,(%esp)
  107dc3:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  107dc6:	ff d0                	call   *%eax
	assert(pi->refcount >= 0);
  107dc8:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  107dcb:	8b 40 04             	mov    0x4(%eax),%eax
  107dce:	85 c0                	test   %eax,%eax
  107dd0:	79 24                	jns    107df6 <pmap_merge+0x414>
  107dd2:	c7 44 24 0c 79 cf 10 	movl   $0x10cf79,0xc(%esp)
  107dd9:	00 
  107dda:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  107de1:	00 
  107de2:	c7 44 24 04 6a 00 00 	movl   $0x6a,0x4(%esp)
  107de9:	00 
  107dea:	c7 04 24 1f cf 10 00 	movl   $0x10cf1f,(%esp)
  107df1:	e8 42 8b ff ff       	call   100938 <debug_panic>
          *spte &= ~PTE_W;
  107df6:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  107df9:	8b 00                	mov    (%eax),%eax
  107dfb:	89 c2                	mov    %eax,%edx
  107dfd:	83 e2 fd             	and    $0xfffffffd,%edx
  107e00:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  107e03:	89 10                	mov    %edx,(%eax)
          *dpte = *spte;
  107e05:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  107e08:	8b 10                	mov    (%eax),%edx
  107e0a:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  107e0d:	89 10                	mov    %edx,(%eax)
          mem_incref(mem_phys2pi(PGADDR(*spte)));
  107e0f:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  107e12:	8b 00                	mov    (%eax),%eax
  107e14:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  107e19:	c1 e8 0c             	shr    $0xc,%eax
  107e1c:	c1 e0 03             	shl    $0x3,%eax
  107e1f:	89 c2                	mov    %eax,%edx
  107e21:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  107e26:	8d 04 02             	lea    (%edx,%eax,1),%eax
  107e29:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
// Atomically increment the reference count on a page.
static gcc_inline void
mem_incref(pageinfo *pi)
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  107e2c:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  107e31:	83 c0 08             	add    $0x8,%eax
  107e34:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  107e37:	73 17                	jae    107e50 <pmap_merge+0x46e>
  107e39:	a1 84 ed 17 00       	mov    0x17ed84,%eax
  107e3e:	c1 e0 03             	shl    $0x3,%eax
  107e41:	89 c2                	mov    %eax,%edx
  107e43:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  107e48:	8d 04 02             	lea    (%edx,%eax,1),%eax
  107e4b:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  107e4e:	77 24                	ja     107e74 <pmap_merge+0x492>
  107e50:	c7 44 24 0c e8 ce 10 	movl   $0x10cee8,0xc(%esp)
  107e57:	00 
  107e58:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  107e5f:	00 
  107e60:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
  107e67:	00 
  107e68:	c7 04 24 1f cf 10 00 	movl   $0x10cf1f,(%esp)
  107e6f:	e8 c4 8a ff ff       	call   100938 <debug_panic>
	assert(pi != mem_ptr2pi(pmap_zero));	// Don't alloc/free zero page!
  107e74:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  107e7a:	b8 00 10 18 00       	mov    $0x181000,%eax
  107e7f:	c1 e8 0c             	shr    $0xc,%eax
  107e82:	c1 e0 03             	shl    $0x3,%eax
  107e85:	8d 04 02             	lea    (%edx,%eax,1),%eax
  107e88:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  107e8b:	75 24                	jne    107eb1 <pmap_merge+0x4cf>
  107e8d:	c7 44 24 0c 2c cf 10 	movl   $0x10cf2c,0xc(%esp)
  107e94:	00 
  107e95:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  107e9c:	00 
  107e9d:	c7 44 24 04 59 00 00 	movl   $0x59,0x4(%esp)
  107ea4:	00 
  107ea5:	c7 04 24 1f cf 10 00 	movl   $0x10cf1f,(%esp)
  107eac:	e8 87 8a ff ff       	call   100938 <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  107eb1:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  107eb7:	b8 0c 00 10 00       	mov    $0x10000c,%eax
  107ebc:	c1 e8 0c             	shr    $0xc,%eax
  107ebf:	c1 e0 03             	shl    $0x3,%eax
  107ec2:	8d 04 02             	lea    (%edx,%eax,1),%eax
  107ec5:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  107ec8:	77 40                	ja     107f0a <pmap_merge+0x528>
  107eca:	8b 15 dc ed 17 00    	mov    0x17eddc,%edx
  107ed0:	b8 08 20 18 00       	mov    $0x182008,%eax
  107ed5:	83 e8 01             	sub    $0x1,%eax
  107ed8:	c1 e8 0c             	shr    $0xc,%eax
  107edb:	c1 e0 03             	shl    $0x3,%eax
  107ede:	8d 04 02             	lea    (%edx,%eax,1),%eax
  107ee1:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  107ee4:	72 24                	jb     107f0a <pmap_merge+0x528>
  107ee6:	c7 44 24 0c 48 cf 10 	movl   $0x10cf48,0xc(%esp)
  107eed:	00 
  107eee:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  107ef5:	00 
  107ef6:	c7 44 24 04 5a 00 00 	movl   $0x5a,0x4(%esp)
  107efd:	00 
  107efe:	c7 04 24 1f cf 10 00 	movl   $0x10cf1f,(%esp)
  107f05:	e8 2e 8a ff ff       	call   100938 <debug_panic>

	lockadd(&pi->refcount, 1);
  107f0a:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  107f0d:	83 c0 04             	add    $0x4,%eax
  107f10:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  107f17:	00 
  107f18:	89 04 24             	mov    %eax,(%esp)
  107f1b:	e8 aa de ff ff       	call   105dca <lockadd>
          continue;
  107f20:	eb 20                	jmp    107f42 <pmap_merge+0x560>
          }
                    

          pmap_mergepage(rpte, spte, dpte, dva);
  107f22:	8b 45 18             	mov    0x18(%ebp),%eax
  107f25:	89 44 24 0c          	mov    %eax,0xc(%esp)
  107f29:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  107f2c:	89 44 24 08          	mov    %eax,0x8(%esp)
  107f30:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  107f33:	89 44 24 04          	mov    %eax,0x4(%esp)
  107f37:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  107f3a:	89 04 24             	mov    %eax,(%esp)
  107f3d:	e8 94 f5 ff ff       	call   1074d6 <pmap_mergepage>
  107f42:	83 45 e4 04          	addl   $0x4,0xffffffe4(%ebp)
  107f46:	83 45 e8 04          	addl   $0x4,0xffffffe8(%ebp)
  107f4a:	83 45 ec 04          	addl   $0x4,0xffffffec(%ebp)
  107f4e:	81 45 10 00 10 00 00 	addl   $0x1000,0x10(%ebp)
  107f55:	81 45 18 00 10 00 00 	addl   $0x1000,0x18(%ebp)
  107f5c:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  107f5f:	3b 45 f0             	cmp    0xfffffff0(%ebp),%eax
  107f62:	0f 82 fb fc ff ff    	jb     107c63 <pmap_merge+0x281>
  107f68:	83 45 d4 04          	addl   $0x4,0xffffffd4(%ebp)
  107f6c:	83 45 d8 04          	addl   $0x4,0xffffffd8(%ebp)
  107f70:	83 45 dc 04          	addl   $0x4,0xffffffdc(%ebp)
  107f74:	8b 45 10             	mov    0x10(%ebp),%eax
  107f77:	3b 45 e0             	cmp    0xffffffe0(%ebp),%eax
  107f7a:	0f 82 10 fc ff ff    	jb     107b90 <pmap_merge+0x1ae>
         }
         }
          
return 1;
  107f80:	c7 45 cc 01 00 00 00 	movl   $0x1,0xffffffcc(%ebp)
  107f87:	8b 45 cc             	mov    0xffffffcc(%ebp),%eax
}
  107f8a:	c9                   	leave  
  107f8b:	c3                   	ret    

00107f8c <pmap_setperm>:

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
  107f8c:	55                   	push   %ebp
  107f8d:	89 e5                	mov    %esp,%ebp
  107f8f:	83 ec 38             	sub    $0x38,%esp
	assert(PGOFF(va) == 0);
  107f92:	8b 45 0c             	mov    0xc(%ebp),%eax
  107f95:	25 ff 0f 00 00       	and    $0xfff,%eax
  107f9a:	85 c0                	test   %eax,%eax
  107f9c:	74 24                	je     107fc2 <pmap_setperm+0x36>
  107f9e:	c7 44 24 0c 88 d1 10 	movl   $0x10d188,0xc(%esp)
  107fa5:	00 
  107fa6:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  107fad:	00 
  107fae:	c7 44 24 04 34 02 00 	movl   $0x234,0x4(%esp)
  107fb5:	00 
  107fb6:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  107fbd:	e8 76 89 ff ff       	call   100938 <debug_panic>
	assert(PGOFF(size) == 0);
  107fc2:	8b 45 10             	mov    0x10(%ebp),%eax
  107fc5:	25 ff 0f 00 00       	and    $0xfff,%eax
  107fca:	85 c0                	test   %eax,%eax
  107fcc:	74 24                	je     107ff2 <pmap_setperm+0x66>
  107fce:	c7 44 24 0c dc cf 10 	movl   $0x10cfdc,0xc(%esp)
  107fd5:	00 
  107fd6:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  107fdd:	00 
  107fde:	c7 44 24 04 35 02 00 	movl   $0x235,0x4(%esp)
  107fe5:	00 
  107fe6:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  107fed:	e8 46 89 ff ff       	call   100938 <debug_panic>
	assert(va >= VM_USERLO && va < VM_USERHI);
  107ff2:	81 7d 0c ff ff ff 3f 	cmpl   $0x3fffffff,0xc(%ebp)
  107ff9:	76 09                	jbe    108004 <pmap_setperm+0x78>
  107ffb:	81 7d 0c ff ff ff ef 	cmpl   $0xefffffff,0xc(%ebp)
  108002:	76 24                	jbe    108028 <pmap_setperm+0x9c>
  108004:	c7 44 24 0c 8c cf 10 	movl   $0x10cf8c,0xc(%esp)
  10800b:	00 
  10800c:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  108013:	00 
  108014:	c7 44 24 04 36 02 00 	movl   $0x236,0x4(%esp)
  10801b:	00 
  10801c:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  108023:	e8 10 89 ff ff       	call   100938 <debug_panic>
	assert(size <= VM_USERHI - va);
  108028:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
  10802d:	2b 45 0c             	sub    0xc(%ebp),%eax
  108030:	3b 45 10             	cmp    0x10(%ebp),%eax
  108033:	73 24                	jae    108059 <pmap_setperm+0xcd>
  108035:	c7 44 24 0c ed cf 10 	movl   $0x10cfed,0xc(%esp)
  10803c:	00 
  10803d:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  108044:	00 
  108045:	c7 44 24 04 37 02 00 	movl   $0x237,0x4(%esp)
  10804c:	00 
  10804d:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  108054:	e8 df 88 ff ff       	call   100938 <debug_panic>
	assert((perm & ~(SYS_RW)) == 0);
  108059:	8b 45 14             	mov    0x14(%ebp),%eax
  10805c:	80 e4 f9             	and    $0xf9,%ah
  10805f:	85 c0                	test   %eax,%eax
  108061:	74 24                	je     108087 <pmap_setperm+0xfb>
  108063:	c7 44 24 0c 97 d1 10 	movl   $0x10d197,0xc(%esp)
  10806a:	00 
  10806b:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  108072:	00 
  108073:	c7 44 24 04 38 02 00 	movl   $0x238,0x4(%esp)
  10807a:	00 
  10807b:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  108082:	e8 b1 88 ff ff       	call   100938 <debug_panic>


  pmap_inval(pdir, va, size);
  108087:	8b 45 10             	mov    0x10(%ebp),%eax
  10808a:	89 44 24 08          	mov    %eax,0x8(%esp)
  10808e:	8b 45 0c             	mov    0xc(%ebp),%eax
  108091:	89 44 24 04          	mov    %eax,0x4(%esp)
  108095:	8b 45 08             	mov    0x8(%ebp),%eax
  108098:	89 04 24             	mov    %eax,(%esp)
  10809b:	e8 0f ec ff ff       	call   106caf <pmap_inval>

  uint32_t pteand, pteor;
  if(!(perm & SYS_READ))
  1080a0:	8b 45 14             	mov    0x14(%ebp),%eax
  1080a3:	25 00 02 00 00       	and    $0x200,%eax
  1080a8:	85 c0                	test   %eax,%eax
  1080aa:	75 10                	jne    1080bc <pmap_setperm+0x130>
    pteand = ~(SYS_RW | PTE_W | PTE_P), pteor = 0;
  1080ac:	c7 45 ec fc f9 ff ff 	movl   $0xfffff9fc,0xffffffec(%ebp)
  1080b3:	c7 45 f0 00 00 00 00 	movl   $0x0,0xfffffff0(%ebp)
  1080ba:	eb 2a                	jmp    1080e6 <pmap_setperm+0x15a>
    else if (!(perm & SYS_WRITE))
  1080bc:	8b 45 14             	mov    0x14(%ebp),%eax
  1080bf:	25 00 04 00 00       	and    $0x400,%eax
  1080c4:	85 c0                	test   %eax,%eax
  1080c6:	75 10                	jne    1080d8 <pmap_setperm+0x14c>
    pteand = ~(SYS_WRITE | PTE_W),
  1080c8:	c7 45 ec fd fb ff ff 	movl   $0xfffffbfd,0xffffffec(%ebp)
  1080cf:	c7 45 f0 25 02 00 00 	movl   $0x225,0xfffffff0(%ebp)
  1080d6:	eb 0e                	jmp    1080e6 <pmap_setperm+0x15a>
    pteor = (SYS_READ | PTE_U | PTE_P | PTE_A);
    else
    pteand = ~0, pteor = (SYS_RW | PTE_U | PTE_P | PTE_A | PTE_D);
  1080d8:	c7 45 ec ff ff ff ff 	movl   $0xffffffff,0xffffffec(%ebp)
  1080df:	c7 45 f0 65 06 00 00 	movl   $0x665,0xfffffff0(%ebp)

    uint32_t vahi = va + size;
  1080e6:	8b 45 10             	mov    0x10(%ebp),%eax
  1080e9:	03 45 0c             	add    0xc(%ebp),%eax
  1080ec:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
    while(va < vahi){
  1080ef:	e9 9a 00 00 00       	jmp    10818e <pmap_setperm+0x202>
    pde_t *pde = &pdir[PDX(va)];
  1080f4:	8b 45 0c             	mov    0xc(%ebp),%eax
  1080f7:	c1 e8 16             	shr    $0x16,%eax
  1080fa:	25 ff 03 00 00       	and    $0x3ff,%eax
  1080ff:	c1 e0 02             	shl    $0x2,%eax
  108102:	03 45 08             	add    0x8(%ebp),%eax
  108105:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
    if (*pde == PTE_ZERO && pteor == 0){
  108108:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10810b:	8b 10                	mov    (%eax),%edx
  10810d:	b8 00 10 18 00       	mov    $0x181000,%eax
  108112:	39 c2                	cmp    %eax,%edx
  108114:	75 18                	jne    10812e <pmap_setperm+0x1a2>
  108116:	83 7d f0 00          	cmpl   $0x0,0xfffffff0(%ebp)
  10811a:	75 12                	jne    10812e <pmap_setperm+0x1a2>
    va = PTADDR(va + PTSIZE);
  10811c:	8b 45 0c             	mov    0xc(%ebp),%eax
  10811f:	05 00 00 40 00       	add    $0x400000,%eax
  108124:	25 00 00 c0 ff       	and    $0xffc00000,%eax
  108129:	89 45 0c             	mov    %eax,0xc(%ebp)
    continue;
  10812c:	eb 60                	jmp    10818e <pmap_setperm+0x202>
    }

    pte_t *pte = pmap_walk(pdir, va, 1);
  10812e:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
  108135:	00 
  108136:	8b 45 0c             	mov    0xc(%ebp),%eax
  108139:	89 44 24 04          	mov    %eax,0x4(%esp)
  10813d:	8b 45 08             	mov    0x8(%ebp),%eax
  108140:	89 04 24             	mov    %eax,(%esp)
  108143:	e8 9b de ff ff       	call   105fe3 <pmap_walk>
  108148:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
    if (pte == NULL)
  10814b:	83 7d fc 00          	cmpl   $0x0,0xfffffffc(%ebp)
  10814f:	75 09                	jne    10815a <pmap_setperm+0x1ce>
      return 0;
  108151:	c7 45 dc 00 00 00 00 	movl   $0x0,0xffffffdc(%ebp)
  108158:	eb 47                	jmp    1081a1 <pmap_setperm+0x215>

    do {
    *pte = (*pte & pteand) | pteor;
  10815a:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  10815d:	8b 00                	mov    (%eax),%eax
  10815f:	23 45 ec             	and    0xffffffec(%ebp),%eax
  108162:	89 c2                	mov    %eax,%edx
  108164:	0b 55 f0             	or     0xfffffff0(%ebp),%edx
  108167:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  10816a:	89 10                	mov    %edx,(%eax)
    pte++;
  10816c:	83 45 fc 04          	addl   $0x4,0xfffffffc(%ebp)
    va += PAGESIZE;
  108170:	81 45 0c 00 10 00 00 	addl   $0x1000,0xc(%ebp)
    } while(va < vahi && PTX(va) !=0);
  108177:	8b 45 0c             	mov    0xc(%ebp),%eax
  10817a:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  10817d:	73 0f                	jae    10818e <pmap_setperm+0x202>
  10817f:	8b 45 0c             	mov    0xc(%ebp),%eax
  108182:	c1 e8 0c             	shr    $0xc,%eax
  108185:	25 ff 03 00 00       	and    $0x3ff,%eax
  10818a:	85 c0                	test   %eax,%eax
  10818c:	75 cc                	jne    10815a <pmap_setperm+0x1ce>
  10818e:	8b 45 0c             	mov    0xc(%ebp),%eax
  108191:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  108194:	0f 82 5a ff ff ff    	jb     1080f4 <pmap_setperm+0x168>
    }
    return 1;
  10819a:	c7 45 dc 01 00 00 00 	movl   $0x1,0xffffffdc(%ebp)
  1081a1:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax




}
  1081a4:	c9                   	leave  
  1081a5:	c3                   	ret    

001081a6 <va2pa>:

//
// This function returns the physical address of the page containing 'va',
// defined by the page directory 'pdir'.  The hardware normally performs
// this functionality for us!  We define our own version to help check
// the pmap_check() function; it shouldn't be used elsewhere.
//
static uint32_t
va2pa(pde_t *pdir, uintptr_t va)
{
  1081a6:	55                   	push   %ebp
  1081a7:	89 e5                	mov    %esp,%ebp
  1081a9:	83 ec 14             	sub    $0x14,%esp
	pdir = &pdir[PDX(va)];
  1081ac:	8b 45 0c             	mov    0xc(%ebp),%eax
  1081af:	c1 e8 16             	shr    $0x16,%eax
  1081b2:	25 ff 03 00 00       	and    $0x3ff,%eax
  1081b7:	c1 e0 02             	shl    $0x2,%eax
  1081ba:	01 45 08             	add    %eax,0x8(%ebp)
	if (!(*pdir & PTE_P))
  1081bd:	8b 45 08             	mov    0x8(%ebp),%eax
  1081c0:	8b 00                	mov    (%eax),%eax
  1081c2:	83 e0 01             	and    $0x1,%eax
  1081c5:	85 c0                	test   %eax,%eax
  1081c7:	75 09                	jne    1081d2 <va2pa+0x2c>
		return ~0;
  1081c9:	c7 45 ec ff ff ff ff 	movl   $0xffffffff,0xffffffec(%ebp)
  1081d0:	eb 4e                	jmp    108220 <va2pa+0x7a>
	pte_t *ptab = mem_ptr(PGADDR(*pdir));
  1081d2:	8b 45 08             	mov    0x8(%ebp),%eax
  1081d5:	8b 00                	mov    (%eax),%eax
  1081d7:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1081dc:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	if (!(ptab[PTX(va)] & PTE_P))
  1081df:	8b 45 0c             	mov    0xc(%ebp),%eax
  1081e2:	c1 e8 0c             	shr    $0xc,%eax
  1081e5:	25 ff 03 00 00       	and    $0x3ff,%eax
  1081ea:	c1 e0 02             	shl    $0x2,%eax
  1081ed:	03 45 fc             	add    0xfffffffc(%ebp),%eax
  1081f0:	8b 00                	mov    (%eax),%eax
  1081f2:	83 e0 01             	and    $0x1,%eax
  1081f5:	85 c0                	test   %eax,%eax
  1081f7:	75 09                	jne    108202 <va2pa+0x5c>
		return ~0;
  1081f9:	c7 45 ec ff ff ff ff 	movl   $0xffffffff,0xffffffec(%ebp)
  108200:	eb 1e                	jmp    108220 <va2pa+0x7a>
	return PGADDR(ptab[PTX(va)]);
  108202:	8b 45 0c             	mov    0xc(%ebp),%eax
  108205:	c1 e8 0c             	shr    $0xc,%eax
  108208:	25 ff 03 00 00       	and    $0x3ff,%eax
  10820d:	c1 e0 02             	shl    $0x2,%eax
  108210:	03 45 fc             	add    0xfffffffc(%ebp),%eax
  108213:	8b 00                	mov    (%eax),%eax
  108215:	89 c2                	mov    %eax,%edx
  108217:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
  10821d:	89 55 ec             	mov    %edx,0xffffffec(%ebp)
  108220:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
}
  108223:	c9                   	leave  
  108224:	c3                   	ret    

00108225 <pmap_check>:

// check pmap_insert, pmap_remove, &c
void
pmap_check(void)
{
  108225:	55                   	push   %ebp
  108226:	89 e5                	mov    %esp,%ebp
  108228:	53                   	push   %ebx
  108229:	83 ec 44             	sub    $0x44,%esp
	extern pageinfo *mem_freelist;

	pageinfo *pi, *pi0, *pi1, *pi2, *pi3;
	pageinfo *fl;
	pte_t *ptep, *ptep1;
	int i;

	// should be able to allocate three pages
	pi0 = pi1 = pi2 = 0;
  10822c:	c7 45 e0 00 00 00 00 	movl   $0x0,0xffffffe0(%ebp)
  108233:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  108236:	89 45 dc             	mov    %eax,0xffffffdc(%ebp)
  108239:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  10823c:	89 45 d8             	mov    %eax,0xffffffd8(%ebp)
	pi0 = mem_alloc();
  10823f:	e8 d7 8d ff ff       	call   10101b <mem_alloc>
  108244:	89 45 d8             	mov    %eax,0xffffffd8(%ebp)
	pi1 = mem_alloc();
  108247:	e8 cf 8d ff ff       	call   10101b <mem_alloc>
  10824c:	89 45 dc             	mov    %eax,0xffffffdc(%ebp)
	pi2 = mem_alloc();
  10824f:	e8 c7 8d ff ff       	call   10101b <mem_alloc>
  108254:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)
	pi3 = mem_alloc();
  108257:	e8 bf 8d ff ff       	call   10101b <mem_alloc>
  10825c:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)

	assert(pi0);
  10825f:	83 7d d8 00          	cmpl   $0x0,0xffffffd8(%ebp)
  108263:	75 24                	jne    108289 <pmap_check+0x64>
  108265:	c7 44 24 0c af d1 10 	movl   $0x10d1af,0xc(%esp)
  10826c:	00 
  10826d:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  108274:	00 
  108275:	c7 44 24 04 83 02 00 	movl   $0x283,0x4(%esp)
  10827c:	00 
  10827d:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  108284:	e8 af 86 ff ff       	call   100938 <debug_panic>
	assert(pi1 && pi1 != pi0);
  108289:	83 7d dc 00          	cmpl   $0x0,0xffffffdc(%ebp)
  10828d:	74 08                	je     108297 <pmap_check+0x72>
  10828f:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  108292:	3b 45 d8             	cmp    0xffffffd8(%ebp),%eax
  108295:	75 24                	jne    1082bb <pmap_check+0x96>
  108297:	c7 44 24 0c b3 d1 10 	movl   $0x10d1b3,0xc(%esp)
  10829e:	00 
  10829f:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  1082a6:	00 
  1082a7:	c7 44 24 04 84 02 00 	movl   $0x284,0x4(%esp)
  1082ae:	00 
  1082af:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  1082b6:	e8 7d 86 ff ff       	call   100938 <debug_panic>
	assert(pi2 && pi2 != pi1 && pi2 != pi0);
  1082bb:	83 7d e0 00          	cmpl   $0x0,0xffffffe0(%ebp)
  1082bf:	74 10                	je     1082d1 <pmap_check+0xac>
  1082c1:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  1082c4:	3b 45 dc             	cmp    0xffffffdc(%ebp),%eax
  1082c7:	74 08                	je     1082d1 <pmap_check+0xac>
  1082c9:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  1082cc:	3b 45 d8             	cmp    0xffffffd8(%ebp),%eax
  1082cf:	75 24                	jne    1082f5 <pmap_check+0xd0>
  1082d1:	c7 44 24 0c c8 d1 10 	movl   $0x10d1c8,0xc(%esp)
  1082d8:	00 
  1082d9:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  1082e0:	00 
  1082e1:	c7 44 24 04 85 02 00 	movl   $0x285,0x4(%esp)
  1082e8:	00 
  1082e9:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  1082f0:	e8 43 86 ff ff       	call   100938 <debug_panic>

	// temporarily steal the rest of the free pages
	fl = mem_freelist;
  1082f5:	a1 80 ed 17 00       	mov    0x17ed80,%eax
  1082fa:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
	mem_freelist = NULL;
  1082fd:	c7 05 80 ed 17 00 00 	movl   $0x0,0x17ed80
  108304:	00 00 00 

	// should be no free memory
	assert(mem_alloc() == NULL);
  108307:	e8 0f 8d ff ff       	call   10101b <mem_alloc>
  10830c:	85 c0                	test   %eax,%eax
  10830e:	74 24                	je     108334 <pmap_check+0x10f>
  108310:	c7 44 24 0c e8 d1 10 	movl   $0x10d1e8,0xc(%esp)
  108317:	00 
  108318:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  10831f:	00 
  108320:	c7 44 24 04 8c 02 00 	movl   $0x28c,0x4(%esp)
  108327:	00 
  108328:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  10832f:	e8 04 86 ff ff       	call   100938 <debug_panic>

	// there is no free memory, so we can't allocate a page table 
	assert(pmap_insert(pmap_bootpdir, pi1, VM_USERLO, 0) == NULL);
  108334:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  10833b:	00 
  10833c:	c7 44 24 08 00 00 00 	movl   $0x40000000,0x8(%esp)
  108343:	40 
  108344:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  108347:	89 44 24 04          	mov    %eax,0x4(%esp)
  10834b:	c7 04 24 00 00 18 00 	movl   $0x180000,(%esp)
  108352:	e8 44 e3 ff ff       	call   10669b <pmap_insert>
  108357:	85 c0                	test   %eax,%eax
  108359:	74 24                	je     10837f <pmap_check+0x15a>
  10835b:	c7 44 24 0c fc d1 10 	movl   $0x10d1fc,0xc(%esp)
  108362:	00 
  108363:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  10836a:	00 
  10836b:	c7 44 24 04 8f 02 00 	movl   $0x28f,0x4(%esp)
  108372:	00 
  108373:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  10837a:	e8 b9 85 ff ff       	call   100938 <debug_panic>

	// free pi0 and try again: pi0 should be used for page table
	mem_free(pi0);
  10837f:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  108382:	89 04 24             	mov    %eax,(%esp)
  108385:	e8 d5 8c ff ff       	call   10105f <mem_free>
	assert(pmap_insert(pmap_bootpdir, pi1, VM_USERLO, 0) != NULL);
  10838a:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  108391:	00 
  108392:	c7 44 24 08 00 00 00 	movl   $0x40000000,0x8(%esp)
  108399:	40 
  10839a:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  10839d:	89 44 24 04          	mov    %eax,0x4(%esp)
  1083a1:	c7 04 24 00 00 18 00 	movl   $0x180000,(%esp)
  1083a8:	e8 ee e2 ff ff       	call   10669b <pmap_insert>
  1083ad:	85 c0                	test   %eax,%eax
  1083af:	75 24                	jne    1083d5 <pmap_check+0x1b0>
  1083b1:	c7 44 24 0c 34 d2 10 	movl   $0x10d234,0xc(%esp)
  1083b8:	00 
  1083b9:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  1083c0:	00 
  1083c1:	c7 44 24 04 93 02 00 	movl   $0x293,0x4(%esp)
  1083c8:	00 
  1083c9:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  1083d0:	e8 63 85 ff ff       	call   100938 <debug_panic>
	assert(PGADDR(pmap_bootpdir[PDX(VM_USERLO)]) == mem_pi2phys(pi0));
  1083d5:	a1 00 04 18 00       	mov    0x180400,%eax
  1083da:	89 c1                	mov    %eax,%ecx
  1083dc:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
  1083e2:	8b 55 d8             	mov    0xffffffd8(%ebp),%edx
  1083e5:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  1083ea:	89 d3                	mov    %edx,%ebx
  1083ec:	29 c3                	sub    %eax,%ebx
  1083ee:	89 d8                	mov    %ebx,%eax
  1083f0:	c1 e0 09             	shl    $0x9,%eax
  1083f3:	39 c1                	cmp    %eax,%ecx
  1083f5:	74 24                	je     10841b <pmap_check+0x1f6>
  1083f7:	c7 44 24 0c 6c d2 10 	movl   $0x10d26c,0xc(%esp)
  1083fe:	00 
  1083ff:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  108406:	00 
  108407:	c7 44 24 04 94 02 00 	movl   $0x294,0x4(%esp)
  10840e:	00 
  10840f:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  108416:	e8 1d 85 ff ff       	call   100938 <debug_panic>
	assert(va2pa(pmap_bootpdir, VM_USERLO) == mem_pi2phys(pi1));
  10841b:	c7 44 24 04 00 00 00 	movl   $0x40000000,0x4(%esp)
  108422:	40 
  108423:	c7 04 24 00 00 18 00 	movl   $0x180000,(%esp)
  10842a:	e8 77 fd ff ff       	call   1081a6 <va2pa>
  10842f:	89 c1                	mov    %eax,%ecx
  108431:	8b 55 dc             	mov    0xffffffdc(%ebp),%edx
  108434:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  108439:	89 d3                	mov    %edx,%ebx
  10843b:	29 c3                	sub    %eax,%ebx
  10843d:	89 d8                	mov    %ebx,%eax
  10843f:	c1 e0 09             	shl    $0x9,%eax
  108442:	39 c1                	cmp    %eax,%ecx
  108444:	74 24                	je     10846a <pmap_check+0x245>
  108446:	c7 44 24 0c a8 d2 10 	movl   $0x10d2a8,0xc(%esp)
  10844d:	00 
  10844e:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  108455:	00 
  108456:	c7 44 24 04 95 02 00 	movl   $0x295,0x4(%esp)
  10845d:	00 
  10845e:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  108465:	e8 ce 84 ff ff       	call   100938 <debug_panic>
	assert(pi1->refcount == 1);
  10846a:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  10846d:	8b 40 04             	mov    0x4(%eax),%eax
  108470:	83 f8 01             	cmp    $0x1,%eax
  108473:	74 24                	je     108499 <pmap_check+0x274>
  108475:	c7 44 24 0c dc d2 10 	movl   $0x10d2dc,0xc(%esp)
  10847c:	00 
  10847d:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  108484:	00 
  108485:	c7 44 24 04 96 02 00 	movl   $0x296,0x4(%esp)
  10848c:	00 
  10848d:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  108494:	e8 9f 84 ff ff       	call   100938 <debug_panic>
	assert(pi0->refcount == 1);
  108499:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  10849c:	8b 40 04             	mov    0x4(%eax),%eax
  10849f:	83 f8 01             	cmp    $0x1,%eax
  1084a2:	74 24                	je     1084c8 <pmap_check+0x2a3>
  1084a4:	c7 44 24 0c ef d2 10 	movl   $0x10d2ef,0xc(%esp)
  1084ab:	00 
  1084ac:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  1084b3:	00 
  1084b4:	c7 44 24 04 97 02 00 	movl   $0x297,0x4(%esp)
  1084bb:	00 
  1084bc:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  1084c3:	e8 70 84 ff ff       	call   100938 <debug_panic>

	// should be able to map pi2 at VM_USERLO+PAGESIZE
	// because pi0 is already allocated for page table
	assert(pmap_insert(pmap_bootpdir, pi2, VM_USERLO+PAGESIZE, 0));
  1084c8:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  1084cf:	00 
  1084d0:	c7 44 24 08 00 10 00 	movl   $0x40001000,0x8(%esp)
  1084d7:	40 
  1084d8:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  1084db:	89 44 24 04          	mov    %eax,0x4(%esp)
  1084df:	c7 04 24 00 00 18 00 	movl   $0x180000,(%esp)
  1084e6:	e8 b0 e1 ff ff       	call   10669b <pmap_insert>
  1084eb:	85 c0                	test   %eax,%eax
  1084ed:	75 24                	jne    108513 <pmap_check+0x2ee>
  1084ef:	c7 44 24 0c 04 d3 10 	movl   $0x10d304,0xc(%esp)
  1084f6:	00 
  1084f7:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  1084fe:	00 
  1084ff:	c7 44 24 04 9b 02 00 	movl   $0x29b,0x4(%esp)
  108506:	00 
  108507:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  10850e:	e8 25 84 ff ff       	call   100938 <debug_panic>
	assert(va2pa(pmap_bootpdir, VM_USERLO+PAGESIZE) == mem_pi2phys(pi2));
  108513:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  10851a:	40 
  10851b:	c7 04 24 00 00 18 00 	movl   $0x180000,(%esp)
  108522:	e8 7f fc ff ff       	call   1081a6 <va2pa>
  108527:	89 c1                	mov    %eax,%ecx
  108529:	8b 55 e0             	mov    0xffffffe0(%ebp),%edx
  10852c:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  108531:	89 d3                	mov    %edx,%ebx
  108533:	29 c3                	sub    %eax,%ebx
  108535:	89 d8                	mov    %ebx,%eax
  108537:	c1 e0 09             	shl    $0x9,%eax
  10853a:	39 c1                	cmp    %eax,%ecx
  10853c:	74 24                	je     108562 <pmap_check+0x33d>
  10853e:	c7 44 24 0c 3c d3 10 	movl   $0x10d33c,0xc(%esp)
  108545:	00 
  108546:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  10854d:	00 
  10854e:	c7 44 24 04 9c 02 00 	movl   $0x29c,0x4(%esp)
  108555:	00 
  108556:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  10855d:	e8 d6 83 ff ff       	call   100938 <debug_panic>
	assert(pi2->refcount == 1);
  108562:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  108565:	8b 40 04             	mov    0x4(%eax),%eax
  108568:	83 f8 01             	cmp    $0x1,%eax
  10856b:	74 24                	je     108591 <pmap_check+0x36c>
  10856d:	c7 44 24 0c 79 d3 10 	movl   $0x10d379,0xc(%esp)
  108574:	00 
  108575:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  10857c:	00 
  10857d:	c7 44 24 04 9d 02 00 	movl   $0x29d,0x4(%esp)
  108584:	00 
  108585:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  10858c:	e8 a7 83 ff ff       	call   100938 <debug_panic>

	// should be no free memory
	assert(mem_alloc() == NULL);
  108591:	e8 85 8a ff ff       	call   10101b <mem_alloc>
  108596:	85 c0                	test   %eax,%eax
  108598:	74 24                	je     1085be <pmap_check+0x399>
  10859a:	c7 44 24 0c e8 d1 10 	movl   $0x10d1e8,0xc(%esp)
  1085a1:	00 
  1085a2:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  1085a9:	00 
  1085aa:	c7 44 24 04 a0 02 00 	movl   $0x2a0,0x4(%esp)
  1085b1:	00 
  1085b2:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  1085b9:	e8 7a 83 ff ff       	call   100938 <debug_panic>

	// should be able to map pi2 at VM_USERLO+PAGESIZE
	// because it's already there
	assert(pmap_insert(pmap_bootpdir, pi2, VM_USERLO+PAGESIZE, 0));
  1085be:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  1085c5:	00 
  1085c6:	c7 44 24 08 00 10 00 	movl   $0x40001000,0x8(%esp)
  1085cd:	40 
  1085ce:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  1085d1:	89 44 24 04          	mov    %eax,0x4(%esp)
  1085d5:	c7 04 24 00 00 18 00 	movl   $0x180000,(%esp)
  1085dc:	e8 ba e0 ff ff       	call   10669b <pmap_insert>
  1085e1:	85 c0                	test   %eax,%eax
  1085e3:	75 24                	jne    108609 <pmap_check+0x3e4>
  1085e5:	c7 44 24 0c 04 d3 10 	movl   $0x10d304,0xc(%esp)
  1085ec:	00 
  1085ed:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  1085f4:	00 
  1085f5:	c7 44 24 04 a4 02 00 	movl   $0x2a4,0x4(%esp)
  1085fc:	00 
  1085fd:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  108604:	e8 2f 83 ff ff       	call   100938 <debug_panic>
	assert(va2pa(pmap_bootpdir, VM_USERLO+PAGESIZE) == mem_pi2phys(pi2));
  108609:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  108610:	40 
  108611:	c7 04 24 00 00 18 00 	movl   $0x180000,(%esp)
  108618:	e8 89 fb ff ff       	call   1081a6 <va2pa>
  10861d:	89 c1                	mov    %eax,%ecx
  10861f:	8b 55 e0             	mov    0xffffffe0(%ebp),%edx
  108622:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  108627:	89 d3                	mov    %edx,%ebx
  108629:	29 c3                	sub    %eax,%ebx
  10862b:	89 d8                	mov    %ebx,%eax
  10862d:	c1 e0 09             	shl    $0x9,%eax
  108630:	39 c1                	cmp    %eax,%ecx
  108632:	74 24                	je     108658 <pmap_check+0x433>
  108634:	c7 44 24 0c 3c d3 10 	movl   $0x10d33c,0xc(%esp)
  10863b:	00 
  10863c:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  108643:	00 
  108644:	c7 44 24 04 a5 02 00 	movl   $0x2a5,0x4(%esp)
  10864b:	00 
  10864c:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  108653:	e8 e0 82 ff ff       	call   100938 <debug_panic>
	assert(pi2->refcount == 1);
  108658:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  10865b:	8b 40 04             	mov    0x4(%eax),%eax
  10865e:	83 f8 01             	cmp    $0x1,%eax
  108661:	74 24                	je     108687 <pmap_check+0x462>
  108663:	c7 44 24 0c 79 d3 10 	movl   $0x10d379,0xc(%esp)
  10866a:	00 
  10866b:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  108672:	00 
  108673:	c7 44 24 04 a6 02 00 	movl   $0x2a6,0x4(%esp)
  10867a:	00 
  10867b:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  108682:	e8 b1 82 ff ff       	call   100938 <debug_panic>

	// pi2 should NOT be on the free list
	// could hapien in ref counts are handled slopiily in pmap_insert
	assert(mem_alloc() == NULL);
  108687:	e8 8f 89 ff ff       	call   10101b <mem_alloc>
  10868c:	85 c0                	test   %eax,%eax
  10868e:	74 24                	je     1086b4 <pmap_check+0x48f>
  108690:	c7 44 24 0c e8 d1 10 	movl   $0x10d1e8,0xc(%esp)
  108697:	00 
  108698:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  10869f:	00 
  1086a0:	c7 44 24 04 aa 02 00 	movl   $0x2aa,0x4(%esp)
  1086a7:	00 
  1086a8:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  1086af:	e8 84 82 ff ff       	call   100938 <debug_panic>

	// check that pmap_walk returns a pointer to the pte
	ptep = mem_ptr(PGADDR(pmap_bootpdir[PDX(VM_USERLO+PAGESIZE)]));
  1086b4:	a1 00 04 18 00       	mov    0x180400,%eax
  1086b9:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1086be:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
	assert(pmap_walk(pmap_bootpdir, VM_USERLO+PAGESIZE, 0)
  1086c1:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  1086c8:	00 
  1086c9:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  1086d0:	40 
  1086d1:	c7 04 24 00 00 18 00 	movl   $0x180000,(%esp)
  1086d8:	e8 06 d9 ff ff       	call   105fe3 <pmap_walk>
  1086dd:	89 c2                	mov    %eax,%edx
  1086df:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  1086e2:	83 c0 04             	add    $0x4,%eax
  1086e5:	39 c2                	cmp    %eax,%edx
  1086e7:	74 24                	je     10870d <pmap_check+0x4e8>
  1086e9:	c7 44 24 0c 8c d3 10 	movl   $0x10d38c,0xc(%esp)
  1086f0:	00 
  1086f1:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  1086f8:	00 
  1086f9:	c7 44 24 04 af 02 00 	movl   $0x2af,0x4(%esp)
  108700:	00 
  108701:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  108708:	e8 2b 82 ff ff       	call   100938 <debug_panic>
		== ptep+PTX(VM_USERLO+PAGESIZE));

	// should be able to change permissions too.
	assert(pmap_insert(pmap_bootpdir, pi2, VM_USERLO+PAGESIZE, PTE_U));
  10870d:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
  108714:	00 
  108715:	c7 44 24 08 00 10 00 	movl   $0x40001000,0x8(%esp)
  10871c:	40 
  10871d:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  108720:	89 44 24 04          	mov    %eax,0x4(%esp)
  108724:	c7 04 24 00 00 18 00 	movl   $0x180000,(%esp)
  10872b:	e8 6b df ff ff       	call   10669b <pmap_insert>
  108730:	85 c0                	test   %eax,%eax
  108732:	75 24                	jne    108758 <pmap_check+0x533>
  108734:	c7 44 24 0c dc d3 10 	movl   $0x10d3dc,0xc(%esp)
  10873b:	00 
  10873c:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  108743:	00 
  108744:	c7 44 24 04 b2 02 00 	movl   $0x2b2,0x4(%esp)
  10874b:	00 
  10874c:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  108753:	e8 e0 81 ff ff       	call   100938 <debug_panic>
	assert(va2pa(pmap_bootpdir, VM_USERLO+PAGESIZE) == mem_pi2phys(pi2));
  108758:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  10875f:	40 
  108760:	c7 04 24 00 00 18 00 	movl   $0x180000,(%esp)
  108767:	e8 3a fa ff ff       	call   1081a6 <va2pa>
  10876c:	89 c1                	mov    %eax,%ecx
  10876e:	8b 55 e0             	mov    0xffffffe0(%ebp),%edx
  108771:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  108776:	89 d3                	mov    %edx,%ebx
  108778:	29 c3                	sub    %eax,%ebx
  10877a:	89 d8                	mov    %ebx,%eax
  10877c:	c1 e0 09             	shl    $0x9,%eax
  10877f:	39 c1                	cmp    %eax,%ecx
  108781:	74 24                	je     1087a7 <pmap_check+0x582>
  108783:	c7 44 24 0c 3c d3 10 	movl   $0x10d33c,0xc(%esp)
  10878a:	00 
  10878b:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  108792:	00 
  108793:	c7 44 24 04 b3 02 00 	movl   $0x2b3,0x4(%esp)
  10879a:	00 
  10879b:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  1087a2:	e8 91 81 ff ff       	call   100938 <debug_panic>
	assert(pi2->refcount == 1);
  1087a7:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  1087aa:	8b 40 04             	mov    0x4(%eax),%eax
  1087ad:	83 f8 01             	cmp    $0x1,%eax
  1087b0:	74 24                	je     1087d6 <pmap_check+0x5b1>
  1087b2:	c7 44 24 0c 79 d3 10 	movl   $0x10d379,0xc(%esp)
  1087b9:	00 
  1087ba:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  1087c1:	00 
  1087c2:	c7 44 24 04 b4 02 00 	movl   $0x2b4,0x4(%esp)
  1087c9:	00 
  1087ca:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  1087d1:	e8 62 81 ff ff       	call   100938 <debug_panic>
	assert(*pmap_walk(pmap_bootpdir, VM_USERLO+PAGESIZE, 0) & PTE_U);
  1087d6:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  1087dd:	00 
  1087de:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  1087e5:	40 
  1087e6:	c7 04 24 00 00 18 00 	movl   $0x180000,(%esp)
  1087ed:	e8 f1 d7 ff ff       	call   105fe3 <pmap_walk>
  1087f2:	8b 00                	mov    (%eax),%eax
  1087f4:	83 e0 04             	and    $0x4,%eax
  1087f7:	85 c0                	test   %eax,%eax
  1087f9:	75 24                	jne    10881f <pmap_check+0x5fa>
  1087fb:	c7 44 24 0c 18 d4 10 	movl   $0x10d418,0xc(%esp)
  108802:	00 
  108803:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  10880a:	00 
  10880b:	c7 44 24 04 b5 02 00 	movl   $0x2b5,0x4(%esp)
  108812:	00 
  108813:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  10881a:	e8 19 81 ff ff       	call   100938 <debug_panic>
	assert(pmap_bootpdir[PDX(VM_USERLO)] & PTE_U);
  10881f:	a1 00 04 18 00       	mov    0x180400,%eax
  108824:	83 e0 04             	and    $0x4,%eax
  108827:	85 c0                	test   %eax,%eax
  108829:	75 24                	jne    10884f <pmap_check+0x62a>
  10882b:	c7 44 24 0c 54 d4 10 	movl   $0x10d454,0xc(%esp)
  108832:	00 
  108833:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  10883a:	00 
  10883b:	c7 44 24 04 b6 02 00 	movl   $0x2b6,0x4(%esp)
  108842:	00 
  108843:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  10884a:	e8 e9 80 ff ff       	call   100938 <debug_panic>
	
	// should not be able to map at VM_USERLO+PTSIZE
	// because we need a free page for a page table
	assert(pmap_insert(pmap_bootpdir, pi0, VM_USERLO+PTSIZE, 0) == NULL);
  10884f:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  108856:	00 
  108857:	c7 44 24 08 00 00 40 	movl   $0x40400000,0x8(%esp)
  10885e:	40 
  10885f:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  108862:	89 44 24 04          	mov    %eax,0x4(%esp)
  108866:	c7 04 24 00 00 18 00 	movl   $0x180000,(%esp)
  10886d:	e8 29 de ff ff       	call   10669b <pmap_insert>
  108872:	85 c0                	test   %eax,%eax
  108874:	74 24                	je     10889a <pmap_check+0x675>
  108876:	c7 44 24 0c 7c d4 10 	movl   $0x10d47c,0xc(%esp)
  10887d:	00 
  10887e:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  108885:	00 
  108886:	c7 44 24 04 ba 02 00 	movl   $0x2ba,0x4(%esp)
  10888d:	00 
  10888e:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  108895:	e8 9e 80 ff ff       	call   100938 <debug_panic>

	// insert pi1 at VM_USERLO+PAGESIZE (replacing pi2)
	assert(pmap_insert(pmap_bootpdir, pi1, VM_USERLO+PAGESIZE, 0));
  10889a:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  1088a1:	00 
  1088a2:	c7 44 24 08 00 10 00 	movl   $0x40001000,0x8(%esp)
  1088a9:	40 
  1088aa:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  1088ad:	89 44 24 04          	mov    %eax,0x4(%esp)
  1088b1:	c7 04 24 00 00 18 00 	movl   $0x180000,(%esp)
  1088b8:	e8 de dd ff ff       	call   10669b <pmap_insert>
  1088bd:	85 c0                	test   %eax,%eax
  1088bf:	75 24                	jne    1088e5 <pmap_check+0x6c0>
  1088c1:	c7 44 24 0c bc d4 10 	movl   $0x10d4bc,0xc(%esp)
  1088c8:	00 
  1088c9:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  1088d0:	00 
  1088d1:	c7 44 24 04 bd 02 00 	movl   $0x2bd,0x4(%esp)
  1088d8:	00 
  1088d9:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  1088e0:	e8 53 80 ff ff       	call   100938 <debug_panic>
	assert(!(*pmap_walk(pmap_bootpdir, VM_USERLO+PAGESIZE, 0) & PTE_U));
  1088e5:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  1088ec:	00 
  1088ed:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  1088f4:	40 
  1088f5:	c7 04 24 00 00 18 00 	movl   $0x180000,(%esp)
  1088fc:	e8 e2 d6 ff ff       	call   105fe3 <pmap_walk>
  108901:	8b 00                	mov    (%eax),%eax
  108903:	83 e0 04             	and    $0x4,%eax
  108906:	85 c0                	test   %eax,%eax
  108908:	74 24                	je     10892e <pmap_check+0x709>
  10890a:	c7 44 24 0c f4 d4 10 	movl   $0x10d4f4,0xc(%esp)
  108911:	00 
  108912:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  108919:	00 
  10891a:	c7 44 24 04 be 02 00 	movl   $0x2be,0x4(%esp)
  108921:	00 
  108922:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  108929:	e8 0a 80 ff ff       	call   100938 <debug_panic>

	// should have pi1 at both +0 and +PAGESIZE, pi2 nowhere, ...
	assert(va2pa(pmap_bootpdir, VM_USERLO+0) == mem_pi2phys(pi1));
  10892e:	c7 44 24 04 00 00 00 	movl   $0x40000000,0x4(%esp)
  108935:	40 
  108936:	c7 04 24 00 00 18 00 	movl   $0x180000,(%esp)
  10893d:	e8 64 f8 ff ff       	call   1081a6 <va2pa>
  108942:	89 c1                	mov    %eax,%ecx
  108944:	8b 55 dc             	mov    0xffffffdc(%ebp),%edx
  108947:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  10894c:	89 d3                	mov    %edx,%ebx
  10894e:	29 c3                	sub    %eax,%ebx
  108950:	89 d8                	mov    %ebx,%eax
  108952:	c1 e0 09             	shl    $0x9,%eax
  108955:	39 c1                	cmp    %eax,%ecx
  108957:	74 24                	je     10897d <pmap_check+0x758>
  108959:	c7 44 24 0c 30 d5 10 	movl   $0x10d530,0xc(%esp)
  108960:	00 
  108961:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  108968:	00 
  108969:	c7 44 24 04 c1 02 00 	movl   $0x2c1,0x4(%esp)
  108970:	00 
  108971:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  108978:	e8 bb 7f ff ff       	call   100938 <debug_panic>
	assert(va2pa(pmap_bootpdir, VM_USERLO+PAGESIZE) == mem_pi2phys(pi1));
  10897d:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  108984:	40 
  108985:	c7 04 24 00 00 18 00 	movl   $0x180000,(%esp)
  10898c:	e8 15 f8 ff ff       	call   1081a6 <va2pa>
  108991:	89 c1                	mov    %eax,%ecx
  108993:	8b 55 dc             	mov    0xffffffdc(%ebp),%edx
  108996:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  10899b:	89 d3                	mov    %edx,%ebx
  10899d:	29 c3                	sub    %eax,%ebx
  10899f:	89 d8                	mov    %ebx,%eax
  1089a1:	c1 e0 09             	shl    $0x9,%eax
  1089a4:	39 c1                	cmp    %eax,%ecx
  1089a6:	74 24                	je     1089cc <pmap_check+0x7a7>
  1089a8:	c7 44 24 0c 68 d5 10 	movl   $0x10d568,0xc(%esp)
  1089af:	00 
  1089b0:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  1089b7:	00 
  1089b8:	c7 44 24 04 c2 02 00 	movl   $0x2c2,0x4(%esp)
  1089bf:	00 
  1089c0:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  1089c7:	e8 6c 7f ff ff       	call   100938 <debug_panic>
	// ... and ref counts should reflect this
	assert(pi1->refcount == 2);
  1089cc:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  1089cf:	8b 40 04             	mov    0x4(%eax),%eax
  1089d2:	83 f8 02             	cmp    $0x2,%eax
  1089d5:	74 24                	je     1089fb <pmap_check+0x7d6>
  1089d7:	c7 44 24 0c a5 d5 10 	movl   $0x10d5a5,0xc(%esp)
  1089de:	00 
  1089df:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  1089e6:	00 
  1089e7:	c7 44 24 04 c4 02 00 	movl   $0x2c4,0x4(%esp)
  1089ee:	00 
  1089ef:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  1089f6:	e8 3d 7f ff ff       	call   100938 <debug_panic>
	assert(pi2->refcount == 0);
  1089fb:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  1089fe:	8b 40 04             	mov    0x4(%eax),%eax
  108a01:	85 c0                	test   %eax,%eax
  108a03:	74 24                	je     108a29 <pmap_check+0x804>
  108a05:	c7 44 24 0c b8 d5 10 	movl   $0x10d5b8,0xc(%esp)
  108a0c:	00 
  108a0d:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  108a14:	00 
  108a15:	c7 44 24 04 c5 02 00 	movl   $0x2c5,0x4(%esp)
  108a1c:	00 
  108a1d:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  108a24:	e8 0f 7f ff ff       	call   100938 <debug_panic>

	// pi2 should be returned by mem_alloc
	assert(mem_alloc() == pi2);
  108a29:	e8 ed 85 ff ff       	call   10101b <mem_alloc>
  108a2e:	3b 45 e0             	cmp    0xffffffe0(%ebp),%eax
  108a31:	74 24                	je     108a57 <pmap_check+0x832>
  108a33:	c7 44 24 0c cb d5 10 	movl   $0x10d5cb,0xc(%esp)
  108a3a:	00 
  108a3b:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  108a42:	00 
  108a43:	c7 44 24 04 c8 02 00 	movl   $0x2c8,0x4(%esp)
  108a4a:	00 
  108a4b:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  108a52:	e8 e1 7e ff ff       	call   100938 <debug_panic>

	// unmapping pi1 at VM_USERLO+0 should keep pi1 at +PAGESIZE
	pmap_remove(pmap_bootpdir, VM_USERLO+0, PAGESIZE);
  108a57:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  108a5e:	00 
  108a5f:	c7 44 24 04 00 00 00 	movl   $0x40000000,0x4(%esp)
  108a66:	40 
  108a67:	c7 04 24 00 00 18 00 	movl   $0x180000,(%esp)
  108a6e:	e8 a6 dd ff ff       	call   106819 <pmap_remove>
	assert(va2pa(pmap_bootpdir, VM_USERLO+0) == ~0);
  108a73:	c7 44 24 04 00 00 00 	movl   $0x40000000,0x4(%esp)
  108a7a:	40 
  108a7b:	c7 04 24 00 00 18 00 	movl   $0x180000,(%esp)
  108a82:	e8 1f f7 ff ff       	call   1081a6 <va2pa>
  108a87:	83 f8 ff             	cmp    $0xffffffff,%eax
  108a8a:	74 24                	je     108ab0 <pmap_check+0x88b>
  108a8c:	c7 44 24 0c e0 d5 10 	movl   $0x10d5e0,0xc(%esp)
  108a93:	00 
  108a94:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  108a9b:	00 
  108a9c:	c7 44 24 04 cc 02 00 	movl   $0x2cc,0x4(%esp)
  108aa3:	00 
  108aa4:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  108aab:	e8 88 7e ff ff       	call   100938 <debug_panic>
	assert(va2pa(pmap_bootpdir, VM_USERLO+PAGESIZE) == mem_pi2phys(pi1));
  108ab0:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  108ab7:	40 
  108ab8:	c7 04 24 00 00 18 00 	movl   $0x180000,(%esp)
  108abf:	e8 e2 f6 ff ff       	call   1081a6 <va2pa>
  108ac4:	89 c1                	mov    %eax,%ecx
  108ac6:	8b 55 dc             	mov    0xffffffdc(%ebp),%edx
  108ac9:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  108ace:	89 d3                	mov    %edx,%ebx
  108ad0:	29 c3                	sub    %eax,%ebx
  108ad2:	89 d8                	mov    %ebx,%eax
  108ad4:	c1 e0 09             	shl    $0x9,%eax
  108ad7:	39 c1                	cmp    %eax,%ecx
  108ad9:	74 24                	je     108aff <pmap_check+0x8da>
  108adb:	c7 44 24 0c 68 d5 10 	movl   $0x10d568,0xc(%esp)
  108ae2:	00 
  108ae3:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  108aea:	00 
  108aeb:	c7 44 24 04 cd 02 00 	movl   $0x2cd,0x4(%esp)
  108af2:	00 
  108af3:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  108afa:	e8 39 7e ff ff       	call   100938 <debug_panic>
	assert(pi1->refcount == 1);
  108aff:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  108b02:	8b 40 04             	mov    0x4(%eax),%eax
  108b05:	83 f8 01             	cmp    $0x1,%eax
  108b08:	74 24                	je     108b2e <pmap_check+0x909>
  108b0a:	c7 44 24 0c dc d2 10 	movl   $0x10d2dc,0xc(%esp)
  108b11:	00 
  108b12:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  108b19:	00 
  108b1a:	c7 44 24 04 ce 02 00 	movl   $0x2ce,0x4(%esp)
  108b21:	00 
  108b22:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  108b29:	e8 0a 7e ff ff       	call   100938 <debug_panic>
	assert(pi2->refcount == 0);
  108b2e:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  108b31:	8b 40 04             	mov    0x4(%eax),%eax
  108b34:	85 c0                	test   %eax,%eax
  108b36:	74 24                	je     108b5c <pmap_check+0x937>
  108b38:	c7 44 24 0c b8 d5 10 	movl   $0x10d5b8,0xc(%esp)
  108b3f:	00 
  108b40:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  108b47:	00 
  108b48:	c7 44 24 04 cf 02 00 	movl   $0x2cf,0x4(%esp)
  108b4f:	00 
  108b50:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  108b57:	e8 dc 7d ff ff       	call   100938 <debug_panic>
	assert(mem_alloc() == NULL);	// still should have no pages free
  108b5c:	e8 ba 84 ff ff       	call   10101b <mem_alloc>
  108b61:	85 c0                	test   %eax,%eax
  108b63:	74 24                	je     108b89 <pmap_check+0x964>
  108b65:	c7 44 24 0c e8 d1 10 	movl   $0x10d1e8,0xc(%esp)
  108b6c:	00 
  108b6d:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  108b74:	00 
  108b75:	c7 44 24 04 d0 02 00 	movl   $0x2d0,0x4(%esp)
  108b7c:	00 
  108b7d:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  108b84:	e8 af 7d ff ff       	call   100938 <debug_panic>

	// unmapping pi1 at VM_USERLO+PAGESIZE should free it
	pmap_remove(pmap_bootpdir, VM_USERLO+PAGESIZE, PAGESIZE);
  108b89:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  108b90:	00 
  108b91:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  108b98:	40 
  108b99:	c7 04 24 00 00 18 00 	movl   $0x180000,(%esp)
  108ba0:	e8 74 dc ff ff       	call   106819 <pmap_remove>
	assert(va2pa(pmap_bootpdir, VM_USERLO+0) == ~0);
  108ba5:	c7 44 24 04 00 00 00 	movl   $0x40000000,0x4(%esp)
  108bac:	40 
  108bad:	c7 04 24 00 00 18 00 	movl   $0x180000,(%esp)
  108bb4:	e8 ed f5 ff ff       	call   1081a6 <va2pa>
  108bb9:	83 f8 ff             	cmp    $0xffffffff,%eax
  108bbc:	74 24                	je     108be2 <pmap_check+0x9bd>
  108bbe:	c7 44 24 0c e0 d5 10 	movl   $0x10d5e0,0xc(%esp)
  108bc5:	00 
  108bc6:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  108bcd:	00 
  108bce:	c7 44 24 04 d4 02 00 	movl   $0x2d4,0x4(%esp)
  108bd5:	00 
  108bd6:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  108bdd:	e8 56 7d ff ff       	call   100938 <debug_panic>
	assert(va2pa(pmap_bootpdir, VM_USERLO+PAGESIZE) == ~0);
  108be2:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  108be9:	40 
  108bea:	c7 04 24 00 00 18 00 	movl   $0x180000,(%esp)
  108bf1:	e8 b0 f5 ff ff       	call   1081a6 <va2pa>
  108bf6:	83 f8 ff             	cmp    $0xffffffff,%eax
  108bf9:	74 24                	je     108c1f <pmap_check+0x9fa>
  108bfb:	c7 44 24 0c 08 d6 10 	movl   $0x10d608,0xc(%esp)
  108c02:	00 
  108c03:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  108c0a:	00 
  108c0b:	c7 44 24 04 d5 02 00 	movl   $0x2d5,0x4(%esp)
  108c12:	00 
  108c13:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  108c1a:	e8 19 7d ff ff       	call   100938 <debug_panic>
	assert(pi1->refcount == 0);
  108c1f:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  108c22:	8b 40 04             	mov    0x4(%eax),%eax
  108c25:	85 c0                	test   %eax,%eax
  108c27:	74 24                	je     108c4d <pmap_check+0xa28>
  108c29:	c7 44 24 0c 37 d6 10 	movl   $0x10d637,0xc(%esp)
  108c30:	00 
  108c31:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  108c38:	00 
  108c39:	c7 44 24 04 d6 02 00 	movl   $0x2d6,0x4(%esp)
  108c40:	00 
  108c41:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  108c48:	e8 eb 7c ff ff       	call   100938 <debug_panic>
	assert(pi2->refcount == 0);
  108c4d:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  108c50:	8b 40 04             	mov    0x4(%eax),%eax
  108c53:	85 c0                	test   %eax,%eax
  108c55:	74 24                	je     108c7b <pmap_check+0xa56>
  108c57:	c7 44 24 0c b8 d5 10 	movl   $0x10d5b8,0xc(%esp)
  108c5e:	00 
  108c5f:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  108c66:	00 
  108c67:	c7 44 24 04 d7 02 00 	movl   $0x2d7,0x4(%esp)
  108c6e:	00 
  108c6f:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  108c76:	e8 bd 7c ff ff       	call   100938 <debug_panic>

	// so it should be returned by page_alloc
	assert(mem_alloc() == pi1);
  108c7b:	e8 9b 83 ff ff       	call   10101b <mem_alloc>
  108c80:	3b 45 dc             	cmp    0xffffffdc(%ebp),%eax
  108c83:	74 24                	je     108ca9 <pmap_check+0xa84>
  108c85:	c7 44 24 0c 4a d6 10 	movl   $0x10d64a,0xc(%esp)
  108c8c:	00 
  108c8d:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  108c94:	00 
  108c95:	c7 44 24 04 da 02 00 	movl   $0x2da,0x4(%esp)
  108c9c:	00 
  108c9d:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  108ca4:	e8 8f 7c ff ff       	call   100938 <debug_panic>

	// should once again have no free memory
	assert(mem_alloc() == NULL);
  108ca9:	e8 6d 83 ff ff       	call   10101b <mem_alloc>
  108cae:	85 c0                	test   %eax,%eax
  108cb0:	74 24                	je     108cd6 <pmap_check+0xab1>
  108cb2:	c7 44 24 0c e8 d1 10 	movl   $0x10d1e8,0xc(%esp)
  108cb9:	00 
  108cba:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  108cc1:	00 
  108cc2:	c7 44 24 04 dd 02 00 	movl   $0x2dd,0x4(%esp)
  108cc9:	00 
  108cca:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  108cd1:	e8 62 7c ff ff       	call   100938 <debug_panic>

	// should be able to pmap_insert to change a page
	// and see the new data immediately.
	memset(mem_pi2ptr(pi1), 1, PAGESIZE);
  108cd6:	8b 55 dc             	mov    0xffffffdc(%ebp),%edx
  108cd9:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  108cde:	89 d1                	mov    %edx,%ecx
  108ce0:	29 c1                	sub    %eax,%ecx
  108ce2:	89 c8                	mov    %ecx,%eax
  108ce4:	c1 e0 09             	shl    $0x9,%eax
  108ce7:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  108cee:	00 
  108cef:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  108cf6:	00 
  108cf7:	89 04 24             	mov    %eax,(%esp)
  108cfa:	e8 0a 2b 00 00       	call   10b809 <memset>
	memset(mem_pi2ptr(pi2), 2, PAGESIZE);
  108cff:	8b 55 e0             	mov    0xffffffe0(%ebp),%edx
  108d02:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  108d07:	89 d3                	mov    %edx,%ebx
  108d09:	29 c3                	sub    %eax,%ebx
  108d0b:	89 d8                	mov    %ebx,%eax
  108d0d:	c1 e0 09             	shl    $0x9,%eax
  108d10:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  108d17:	00 
  108d18:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
  108d1f:	00 
  108d20:	89 04 24             	mov    %eax,(%esp)
  108d23:	e8 e1 2a 00 00       	call   10b809 <memset>
	pmap_insert(pmap_bootpdir, pi1, VM_USERLO, 0);
  108d28:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  108d2f:	00 
  108d30:	c7 44 24 08 00 00 00 	movl   $0x40000000,0x8(%esp)
  108d37:	40 
  108d38:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  108d3b:	89 44 24 04          	mov    %eax,0x4(%esp)
  108d3f:	c7 04 24 00 00 18 00 	movl   $0x180000,(%esp)
  108d46:	e8 50 d9 ff ff       	call   10669b <pmap_insert>
	assert(pi1->refcount == 1);
  108d4b:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  108d4e:	8b 40 04             	mov    0x4(%eax),%eax
  108d51:	83 f8 01             	cmp    $0x1,%eax
  108d54:	74 24                	je     108d7a <pmap_check+0xb55>
  108d56:	c7 44 24 0c dc d2 10 	movl   $0x10d2dc,0xc(%esp)
  108d5d:	00 
  108d5e:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  108d65:	00 
  108d66:	c7 44 24 04 e4 02 00 	movl   $0x2e4,0x4(%esp)
  108d6d:	00 
  108d6e:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  108d75:	e8 be 7b ff ff       	call   100938 <debug_panic>
	assert(*(int*)VM_USERLO == 0x01010101);
  108d7a:	b8 00 00 00 40       	mov    $0x40000000,%eax
  108d7f:	8b 00                	mov    (%eax),%eax
  108d81:	3d 01 01 01 01       	cmp    $0x1010101,%eax
  108d86:	74 24                	je     108dac <pmap_check+0xb87>
  108d88:	c7 44 24 0c 60 d6 10 	movl   $0x10d660,0xc(%esp)
  108d8f:	00 
  108d90:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  108d97:	00 
  108d98:	c7 44 24 04 e5 02 00 	movl   $0x2e5,0x4(%esp)
  108d9f:	00 
  108da0:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  108da7:	e8 8c 7b ff ff       	call   100938 <debug_panic>
	pmap_insert(pmap_bootpdir, pi2, VM_USERLO, 0);
  108dac:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  108db3:	00 
  108db4:	c7 44 24 08 00 00 00 	movl   $0x40000000,0x8(%esp)
  108dbb:	40 
  108dbc:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  108dbf:	89 44 24 04          	mov    %eax,0x4(%esp)
  108dc3:	c7 04 24 00 00 18 00 	movl   $0x180000,(%esp)
  108dca:	e8 cc d8 ff ff       	call   10669b <pmap_insert>
	assert(*(int*)VM_USERLO == 0x02020202);
  108dcf:	b8 00 00 00 40       	mov    $0x40000000,%eax
  108dd4:	8b 00                	mov    (%eax),%eax
  108dd6:	3d 02 02 02 02       	cmp    $0x2020202,%eax
  108ddb:	74 24                	je     108e01 <pmap_check+0xbdc>
  108ddd:	c7 44 24 0c 80 d6 10 	movl   $0x10d680,0xc(%esp)
  108de4:	00 
  108de5:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  108dec:	00 
  108ded:	c7 44 24 04 e7 02 00 	movl   $0x2e7,0x4(%esp)
  108df4:	00 
  108df5:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  108dfc:	e8 37 7b ff ff       	call   100938 <debug_panic>
	assert(pi2->refcount == 1);
  108e01:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  108e04:	8b 40 04             	mov    0x4(%eax),%eax
  108e07:	83 f8 01             	cmp    $0x1,%eax
  108e0a:	74 24                	je     108e30 <pmap_check+0xc0b>
  108e0c:	c7 44 24 0c 79 d3 10 	movl   $0x10d379,0xc(%esp)
  108e13:	00 
  108e14:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  108e1b:	00 
  108e1c:	c7 44 24 04 e8 02 00 	movl   $0x2e8,0x4(%esp)
  108e23:	00 
  108e24:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  108e2b:	e8 08 7b ff ff       	call   100938 <debug_panic>
	assert(pi1->refcount == 0);
  108e30:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  108e33:	8b 40 04             	mov    0x4(%eax),%eax
  108e36:	85 c0                	test   %eax,%eax
  108e38:	74 24                	je     108e5e <pmap_check+0xc39>
  108e3a:	c7 44 24 0c 37 d6 10 	movl   $0x10d637,0xc(%esp)
  108e41:	00 
  108e42:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  108e49:	00 
  108e4a:	c7 44 24 04 e9 02 00 	movl   $0x2e9,0x4(%esp)
  108e51:	00 
  108e52:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  108e59:	e8 da 7a ff ff       	call   100938 <debug_panic>
	assert(mem_alloc() == pi1);
  108e5e:	e8 b8 81 ff ff       	call   10101b <mem_alloc>
  108e63:	3b 45 dc             	cmp    0xffffffdc(%ebp),%eax
  108e66:	74 24                	je     108e8c <pmap_check+0xc67>
  108e68:	c7 44 24 0c 4a d6 10 	movl   $0x10d64a,0xc(%esp)
  108e6f:	00 
  108e70:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  108e77:	00 
  108e78:	c7 44 24 04 ea 02 00 	movl   $0x2ea,0x4(%esp)
  108e7f:	00 
  108e80:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  108e87:	e8 ac 7a ff ff       	call   100938 <debug_panic>
	pmap_remove(pmap_bootpdir, VM_USERLO, PAGESIZE);
  108e8c:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  108e93:	00 
  108e94:	c7 44 24 04 00 00 00 	movl   $0x40000000,0x4(%esp)
  108e9b:	40 
  108e9c:	c7 04 24 00 00 18 00 	movl   $0x180000,(%esp)
  108ea3:	e8 71 d9 ff ff       	call   106819 <pmap_remove>
	assert(pi2->refcount == 0);
  108ea8:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  108eab:	8b 40 04             	mov    0x4(%eax),%eax
  108eae:	85 c0                	test   %eax,%eax
  108eb0:	74 24                	je     108ed6 <pmap_check+0xcb1>
  108eb2:	c7 44 24 0c b8 d5 10 	movl   $0x10d5b8,0xc(%esp)
  108eb9:	00 
  108eba:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  108ec1:	00 
  108ec2:	c7 44 24 04 ec 02 00 	movl   $0x2ec,0x4(%esp)
  108ec9:	00 
  108eca:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  108ed1:	e8 62 7a ff ff       	call   100938 <debug_panic>
	assert(mem_alloc() == pi2);
  108ed6:	e8 40 81 ff ff       	call   10101b <mem_alloc>
  108edb:	3b 45 e0             	cmp    0xffffffe0(%ebp),%eax
  108ede:	74 24                	je     108f04 <pmap_check+0xcdf>
  108ee0:	c7 44 24 0c cb d5 10 	movl   $0x10d5cb,0xc(%esp)
  108ee7:	00 
  108ee8:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  108eef:	00 
  108ef0:	c7 44 24 04 ed 02 00 	movl   $0x2ed,0x4(%esp)
  108ef7:	00 
  108ef8:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  108eff:	e8 34 7a ff ff       	call   100938 <debug_panic>

	// now use a pmap_remove on a large region to take pi0 back
	pmap_remove(pmap_bootpdir, VM_USERLO, VM_USERHI-VM_USERLO);
  108f04:	c7 44 24 08 00 00 00 	movl   $0xb0000000,0x8(%esp)
  108f0b:	b0 
  108f0c:	c7 44 24 04 00 00 00 	movl   $0x40000000,0x4(%esp)
  108f13:	40 
  108f14:	c7 04 24 00 00 18 00 	movl   $0x180000,(%esp)
  108f1b:	e8 f9 d8 ff ff       	call   106819 <pmap_remove>
	assert(pmap_bootpdir[PDX(VM_USERLO)] == PTE_ZERO);
  108f20:	a1 00 04 18 00       	mov    0x180400,%eax
  108f25:	ba 00 10 18 00       	mov    $0x181000,%edx
  108f2a:	39 d0                	cmp    %edx,%eax
  108f2c:	74 24                	je     108f52 <pmap_check+0xd2d>
  108f2e:	c7 44 24 0c a0 d6 10 	movl   $0x10d6a0,0xc(%esp)
  108f35:	00 
  108f36:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  108f3d:	00 
  108f3e:	c7 44 24 04 f1 02 00 	movl   $0x2f1,0x4(%esp)
  108f45:	00 
  108f46:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  108f4d:	e8 e6 79 ff ff       	call   100938 <debug_panic>
	assert(pi0->refcount == 0);
  108f52:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  108f55:	8b 40 04             	mov    0x4(%eax),%eax
  108f58:	85 c0                	test   %eax,%eax
  108f5a:	74 24                	je     108f80 <pmap_check+0xd5b>
  108f5c:	c7 44 24 0c ca d6 10 	movl   $0x10d6ca,0xc(%esp)
  108f63:	00 
  108f64:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  108f6b:	00 
  108f6c:	c7 44 24 04 f2 02 00 	movl   $0x2f2,0x4(%esp)
  108f73:	00 
  108f74:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  108f7b:	e8 b8 79 ff ff       	call   100938 <debug_panic>
	assert(mem_alloc() == pi0);
  108f80:	e8 96 80 ff ff       	call   10101b <mem_alloc>
  108f85:	3b 45 d8             	cmp    0xffffffd8(%ebp),%eax
  108f88:	74 24                	je     108fae <pmap_check+0xd89>
  108f8a:	c7 44 24 0c dd d6 10 	movl   $0x10d6dd,0xc(%esp)
  108f91:	00 
  108f92:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  108f99:	00 
  108f9a:	c7 44 24 04 f3 02 00 	movl   $0x2f3,0x4(%esp)
  108fa1:	00 
  108fa2:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  108fa9:	e8 8a 79 ff ff       	call   100938 <debug_panic>
	assert(mem_freelist == NULL);
  108fae:	a1 80 ed 17 00       	mov    0x17ed80,%eax
  108fb3:	85 c0                	test   %eax,%eax
  108fb5:	74 24                	je     108fdb <pmap_check+0xdb6>
  108fb7:	c7 44 24 0c f0 d6 10 	movl   $0x10d6f0,0xc(%esp)
  108fbe:	00 
  108fbf:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  108fc6:	00 
  108fc7:	c7 44 24 04 f4 02 00 	movl   $0x2f4,0x4(%esp)
  108fce:	00 
  108fcf:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  108fd6:	e8 5d 79 ff ff       	call   100938 <debug_panic>

	// test pmap_remove with large, non-ptable-aligned regions
	mem_free(pi1);
  108fdb:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  108fde:	89 04 24             	mov    %eax,(%esp)
  108fe1:	e8 79 80 ff ff       	call   10105f <mem_free>
	uintptr_t va = VM_USERLO;
  108fe6:	c7 45 f8 00 00 00 40 	movl   $0x40000000,0xfffffff8(%ebp)
	assert(pmap_insert(pmap_bootpdir, pi0, va, 0));
  108fed:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  108ff4:	00 
  108ff5:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  108ff8:	89 44 24 08          	mov    %eax,0x8(%esp)
  108ffc:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  108fff:	89 44 24 04          	mov    %eax,0x4(%esp)
  109003:	c7 04 24 00 00 18 00 	movl   $0x180000,(%esp)
  10900a:	e8 8c d6 ff ff       	call   10669b <pmap_insert>
  10900f:	85 c0                	test   %eax,%eax
  109011:	75 24                	jne    109037 <pmap_check+0xe12>
  109013:	c7 44 24 0c 08 d7 10 	movl   $0x10d708,0xc(%esp)
  10901a:	00 
  10901b:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  109022:	00 
  109023:	c7 44 24 04 f9 02 00 	movl   $0x2f9,0x4(%esp)
  10902a:	00 
  10902b:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  109032:	e8 01 79 ff ff       	call   100938 <debug_panic>
	assert(pmap_insert(pmap_bootpdir, pi0, va+PAGESIZE, 0));
  109037:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10903a:	05 00 10 00 00       	add    $0x1000,%eax
  10903f:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  109046:	00 
  109047:	89 44 24 08          	mov    %eax,0x8(%esp)
  10904b:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  10904e:	89 44 24 04          	mov    %eax,0x4(%esp)
  109052:	c7 04 24 00 00 18 00 	movl   $0x180000,(%esp)
  109059:	e8 3d d6 ff ff       	call   10669b <pmap_insert>
  10905e:	85 c0                	test   %eax,%eax
  109060:	75 24                	jne    109086 <pmap_check+0xe61>
  109062:	c7 44 24 0c 30 d7 10 	movl   $0x10d730,0xc(%esp)
  109069:	00 
  10906a:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  109071:	00 
  109072:	c7 44 24 04 fa 02 00 	movl   $0x2fa,0x4(%esp)
  109079:	00 
  10907a:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  109081:	e8 b2 78 ff ff       	call   100938 <debug_panic>
	assert(pmap_insert(pmap_bootpdir, pi0, va+PTSIZE-PAGESIZE, 0));
  109086:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  109089:	05 00 f0 3f 00       	add    $0x3ff000,%eax
  10908e:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  109095:	00 
  109096:	89 44 24 08          	mov    %eax,0x8(%esp)
  10909a:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  10909d:	89 44 24 04          	mov    %eax,0x4(%esp)
  1090a1:	c7 04 24 00 00 18 00 	movl   $0x180000,(%esp)
  1090a8:	e8 ee d5 ff ff       	call   10669b <pmap_insert>
  1090ad:	85 c0                	test   %eax,%eax
  1090af:	75 24                	jne    1090d5 <pmap_check+0xeb0>
  1090b1:	c7 44 24 0c 60 d7 10 	movl   $0x10d760,0xc(%esp)
  1090b8:	00 
  1090b9:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  1090c0:	00 
  1090c1:	c7 44 24 04 fb 02 00 	movl   $0x2fb,0x4(%esp)
  1090c8:	00 
  1090c9:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  1090d0:	e8 63 78 ff ff       	call   100938 <debug_panic>
	assert(PGADDR(pmap_bootpdir[PDX(VM_USERLO)]) == mem_pi2phys(pi1));
  1090d5:	a1 00 04 18 00       	mov    0x180400,%eax
  1090da:	89 c1                	mov    %eax,%ecx
  1090dc:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
  1090e2:	8b 55 dc             	mov    0xffffffdc(%ebp),%edx
  1090e5:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  1090ea:	89 d3                	mov    %edx,%ebx
  1090ec:	29 c3                	sub    %eax,%ebx
  1090ee:	89 d8                	mov    %ebx,%eax
  1090f0:	c1 e0 09             	shl    $0x9,%eax
  1090f3:	39 c1                	cmp    %eax,%ecx
  1090f5:	74 24                	je     10911b <pmap_check+0xef6>
  1090f7:	c7 44 24 0c 98 d7 10 	movl   $0x10d798,0xc(%esp)
  1090fe:	00 
  1090ff:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  109106:	00 
  109107:	c7 44 24 04 fc 02 00 	movl   $0x2fc,0x4(%esp)
  10910e:	00 
  10910f:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  109116:	e8 1d 78 ff ff       	call   100938 <debug_panic>
	assert(mem_freelist == NULL);
  10911b:	a1 80 ed 17 00       	mov    0x17ed80,%eax
  109120:	85 c0                	test   %eax,%eax
  109122:	74 24                	je     109148 <pmap_check+0xf23>
  109124:	c7 44 24 0c f0 d6 10 	movl   $0x10d6f0,0xc(%esp)
  10912b:	00 
  10912c:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  109133:	00 
  109134:	c7 44 24 04 fd 02 00 	movl   $0x2fd,0x4(%esp)
  10913b:	00 
  10913c:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  109143:	e8 f0 77 ff ff       	call   100938 <debug_panic>
	mem_free(pi2);
  109148:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  10914b:	89 04 24             	mov    %eax,(%esp)
  10914e:	e8 0c 7f ff ff       	call   10105f <mem_free>
	assert(pmap_insert(pmap_bootpdir, pi0, va+PTSIZE, 0));
  109153:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  109156:	05 00 00 40 00       	add    $0x400000,%eax
  10915b:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  109162:	00 
  109163:	89 44 24 08          	mov    %eax,0x8(%esp)
  109167:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  10916a:	89 44 24 04          	mov    %eax,0x4(%esp)
  10916e:	c7 04 24 00 00 18 00 	movl   $0x180000,(%esp)
  109175:	e8 21 d5 ff ff       	call   10669b <pmap_insert>
  10917a:	85 c0                	test   %eax,%eax
  10917c:	75 24                	jne    1091a2 <pmap_check+0xf7d>
  10917e:	c7 44 24 0c d4 d7 10 	movl   $0x10d7d4,0xc(%esp)
  109185:	00 
  109186:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  10918d:	00 
  10918e:	c7 44 24 04 ff 02 00 	movl   $0x2ff,0x4(%esp)
  109195:	00 
  109196:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  10919d:	e8 96 77 ff ff       	call   100938 <debug_panic>
	assert(pmap_insert(pmap_bootpdir, pi0, va+PTSIZE+PAGESIZE, 0));
  1091a2:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1091a5:	05 00 10 40 00       	add    $0x401000,%eax
  1091aa:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  1091b1:	00 
  1091b2:	89 44 24 08          	mov    %eax,0x8(%esp)
  1091b6:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  1091b9:	89 44 24 04          	mov    %eax,0x4(%esp)
  1091bd:	c7 04 24 00 00 18 00 	movl   $0x180000,(%esp)
  1091c4:	e8 d2 d4 ff ff       	call   10669b <pmap_insert>
  1091c9:	85 c0                	test   %eax,%eax
  1091cb:	75 24                	jne    1091f1 <pmap_check+0xfcc>
  1091cd:	c7 44 24 0c 04 d8 10 	movl   $0x10d804,0xc(%esp)
  1091d4:	00 
  1091d5:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  1091dc:	00 
  1091dd:	c7 44 24 04 00 03 00 	movl   $0x300,0x4(%esp)
  1091e4:	00 
  1091e5:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  1091ec:	e8 47 77 ff ff       	call   100938 <debug_panic>
	assert(pmap_insert(pmap_bootpdir, pi0, va+PTSIZE*2-PAGESIZE, 0));
  1091f1:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1091f4:	05 00 f0 7f 00       	add    $0x7ff000,%eax
  1091f9:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  109200:	00 
  109201:	89 44 24 08          	mov    %eax,0x8(%esp)
  109205:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  109208:	89 44 24 04          	mov    %eax,0x4(%esp)
  10920c:	c7 04 24 00 00 18 00 	movl   $0x180000,(%esp)
  109213:	e8 83 d4 ff ff       	call   10669b <pmap_insert>
  109218:	85 c0                	test   %eax,%eax
  10921a:	75 24                	jne    109240 <pmap_check+0x101b>
  10921c:	c7 44 24 0c 3c d8 10 	movl   $0x10d83c,0xc(%esp)
  109223:	00 
  109224:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  10922b:	00 
  10922c:	c7 44 24 04 01 03 00 	movl   $0x301,0x4(%esp)
  109233:	00 
  109234:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  10923b:	e8 f8 76 ff ff       	call   100938 <debug_panic>
	assert(PGADDR(pmap_bootpdir[PDX(VM_USERLO+PTSIZE)])
  109240:	a1 04 04 18 00       	mov    0x180404,%eax
  109245:	89 c1                	mov    %eax,%ecx
  109247:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
  10924d:	8b 55 e0             	mov    0xffffffe0(%ebp),%edx
  109250:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  109255:	89 d3                	mov    %edx,%ebx
  109257:	29 c3                	sub    %eax,%ebx
  109259:	89 d8                	mov    %ebx,%eax
  10925b:	c1 e0 09             	shl    $0x9,%eax
  10925e:	39 c1                	cmp    %eax,%ecx
  109260:	74 24                	je     109286 <pmap_check+0x1061>
  109262:	c7 44 24 0c 78 d8 10 	movl   $0x10d878,0xc(%esp)
  109269:	00 
  10926a:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  109271:	00 
  109272:	c7 44 24 04 03 03 00 	movl   $0x303,0x4(%esp)
  109279:	00 
  10927a:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  109281:	e8 b2 76 ff ff       	call   100938 <debug_panic>
		== mem_pi2phys(pi2));
	assert(mem_freelist == NULL);
  109286:	a1 80 ed 17 00       	mov    0x17ed80,%eax
  10928b:	85 c0                	test   %eax,%eax
  10928d:	74 24                	je     1092b3 <pmap_check+0x108e>
  10928f:	c7 44 24 0c f0 d6 10 	movl   $0x10d6f0,0xc(%esp)
  109296:	00 
  109297:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  10929e:	00 
  10929f:	c7 44 24 04 04 03 00 	movl   $0x304,0x4(%esp)
  1092a6:	00 
  1092a7:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  1092ae:	e8 85 76 ff ff       	call   100938 <debug_panic>
	mem_free(pi3);
  1092b3:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  1092b6:	89 04 24             	mov    %eax,(%esp)
  1092b9:	e8 a1 7d ff ff       	call   10105f <mem_free>
	assert(pmap_insert(pmap_bootpdir, pi0, va+PTSIZE*2, 0));
  1092be:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1092c1:	05 00 00 80 00       	add    $0x800000,%eax
  1092c6:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  1092cd:	00 
  1092ce:	89 44 24 08          	mov    %eax,0x8(%esp)
  1092d2:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  1092d5:	89 44 24 04          	mov    %eax,0x4(%esp)
  1092d9:	c7 04 24 00 00 18 00 	movl   $0x180000,(%esp)
  1092e0:	e8 b6 d3 ff ff       	call   10669b <pmap_insert>
  1092e5:	85 c0                	test   %eax,%eax
  1092e7:	75 24                	jne    10930d <pmap_check+0x10e8>
  1092e9:	c7 44 24 0c bc d8 10 	movl   $0x10d8bc,0xc(%esp)
  1092f0:	00 
  1092f1:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  1092f8:	00 
  1092f9:	c7 44 24 04 06 03 00 	movl   $0x306,0x4(%esp)
  109300:	00 
  109301:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  109308:	e8 2b 76 ff ff       	call   100938 <debug_panic>
	assert(pmap_insert(pmap_bootpdir, pi0, va+PTSIZE*2+PAGESIZE, 0));
  10930d:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  109310:	05 00 10 80 00       	add    $0x801000,%eax
  109315:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  10931c:	00 
  10931d:	89 44 24 08          	mov    %eax,0x8(%esp)
  109321:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  109324:	89 44 24 04          	mov    %eax,0x4(%esp)
  109328:	c7 04 24 00 00 18 00 	movl   $0x180000,(%esp)
  10932f:	e8 67 d3 ff ff       	call   10669b <pmap_insert>
  109334:	85 c0                	test   %eax,%eax
  109336:	75 24                	jne    10935c <pmap_check+0x1137>
  109338:	c7 44 24 0c ec d8 10 	movl   $0x10d8ec,0xc(%esp)
  10933f:	00 
  109340:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  109347:	00 
  109348:	c7 44 24 04 07 03 00 	movl   $0x307,0x4(%esp)
  10934f:	00 
  109350:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  109357:	e8 dc 75 ff ff       	call   100938 <debug_panic>
	assert(pmap_insert(pmap_bootpdir, pi0, va+PTSIZE*3-PAGESIZE*2, 0));
  10935c:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10935f:	05 00 e0 bf 00       	add    $0xbfe000,%eax
  109364:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  10936b:	00 
  10936c:	89 44 24 08          	mov    %eax,0x8(%esp)
  109370:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  109373:	89 44 24 04          	mov    %eax,0x4(%esp)
  109377:	c7 04 24 00 00 18 00 	movl   $0x180000,(%esp)
  10937e:	e8 18 d3 ff ff       	call   10669b <pmap_insert>
  109383:	85 c0                	test   %eax,%eax
  109385:	75 24                	jne    1093ab <pmap_check+0x1186>
  109387:	c7 44 24 0c 28 d9 10 	movl   $0x10d928,0xc(%esp)
  10938e:	00 
  10938f:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  109396:	00 
  109397:	c7 44 24 04 08 03 00 	movl   $0x308,0x4(%esp)
  10939e:	00 
  10939f:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  1093a6:	e8 8d 75 ff ff       	call   100938 <debug_panic>
	assert(pmap_insert(pmap_bootpdir, pi0, va+PTSIZE*3-PAGESIZE, 0));
  1093ab:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1093ae:	05 00 f0 bf 00       	add    $0xbff000,%eax
  1093b3:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  1093ba:	00 
  1093bb:	89 44 24 08          	mov    %eax,0x8(%esp)
  1093bf:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  1093c2:	89 44 24 04          	mov    %eax,0x4(%esp)
  1093c6:	c7 04 24 00 00 18 00 	movl   $0x180000,(%esp)
  1093cd:	e8 c9 d2 ff ff       	call   10669b <pmap_insert>
  1093d2:	85 c0                	test   %eax,%eax
  1093d4:	75 24                	jne    1093fa <pmap_check+0x11d5>
  1093d6:	c7 44 24 0c 64 d9 10 	movl   $0x10d964,0xc(%esp)
  1093dd:	00 
  1093de:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  1093e5:	00 
  1093e6:	c7 44 24 04 09 03 00 	movl   $0x309,0x4(%esp)
  1093ed:	00 
  1093ee:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  1093f5:	e8 3e 75 ff ff       	call   100938 <debug_panic>
	assert(PGADDR(pmap_bootpdir[PDX(VM_USERLO+PTSIZE*2)])
  1093fa:	a1 08 04 18 00       	mov    0x180408,%eax
  1093ff:	89 c1                	mov    %eax,%ecx
  109401:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
  109407:	8b 55 e4             	mov    0xffffffe4(%ebp),%edx
  10940a:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  10940f:	89 d3                	mov    %edx,%ebx
  109411:	29 c3                	sub    %eax,%ebx
  109413:	89 d8                	mov    %ebx,%eax
  109415:	c1 e0 09             	shl    $0x9,%eax
  109418:	39 c1                	cmp    %eax,%ecx
  10941a:	74 24                	je     109440 <pmap_check+0x121b>
  10941c:	c7 44 24 0c a0 d9 10 	movl   $0x10d9a0,0xc(%esp)
  109423:	00 
  109424:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  10942b:	00 
  10942c:	c7 44 24 04 0b 03 00 	movl   $0x30b,0x4(%esp)
  109433:	00 
  109434:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  10943b:	e8 f8 74 ff ff       	call   100938 <debug_panic>
		== mem_pi2phys(pi3));
	assert(mem_freelist == NULL);
  109440:	a1 80 ed 17 00       	mov    0x17ed80,%eax
  109445:	85 c0                	test   %eax,%eax
  109447:	74 24                	je     10946d <pmap_check+0x1248>
  109449:	c7 44 24 0c f0 d6 10 	movl   $0x10d6f0,0xc(%esp)
  109450:	00 
  109451:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  109458:	00 
  109459:	c7 44 24 04 0c 03 00 	movl   $0x30c,0x4(%esp)
  109460:	00 
  109461:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  109468:	e8 cb 74 ff ff       	call   100938 <debug_panic>
	assert(pi0->refcount == 10);
  10946d:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  109470:	8b 40 04             	mov    0x4(%eax),%eax
  109473:	83 f8 0a             	cmp    $0xa,%eax
  109476:	74 24                	je     10949c <pmap_check+0x1277>
  109478:	c7 44 24 0c e3 d9 10 	movl   $0x10d9e3,0xc(%esp)
  10947f:	00 
  109480:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  109487:	00 
  109488:	c7 44 24 04 0d 03 00 	movl   $0x30d,0x4(%esp)
  10948f:	00 
  109490:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  109497:	e8 9c 74 ff ff       	call   100938 <debug_panic>
	assert(pi1->refcount == 1);
  10949c:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  10949f:	8b 40 04             	mov    0x4(%eax),%eax
  1094a2:	83 f8 01             	cmp    $0x1,%eax
  1094a5:	74 24                	je     1094cb <pmap_check+0x12a6>
  1094a7:	c7 44 24 0c dc d2 10 	movl   $0x10d2dc,0xc(%esp)
  1094ae:	00 
  1094af:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  1094b6:	00 
  1094b7:	c7 44 24 04 0e 03 00 	movl   $0x30e,0x4(%esp)
  1094be:	00 
  1094bf:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  1094c6:	e8 6d 74 ff ff       	call   100938 <debug_panic>
	assert(pi2->refcount == 1);
  1094cb:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  1094ce:	8b 40 04             	mov    0x4(%eax),%eax
  1094d1:	83 f8 01             	cmp    $0x1,%eax
  1094d4:	74 24                	je     1094fa <pmap_check+0x12d5>
  1094d6:	c7 44 24 0c 79 d3 10 	movl   $0x10d379,0xc(%esp)
  1094dd:	00 
  1094de:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  1094e5:	00 
  1094e6:	c7 44 24 04 0f 03 00 	movl   $0x30f,0x4(%esp)
  1094ed:	00 
  1094ee:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  1094f5:	e8 3e 74 ff ff       	call   100938 <debug_panic>
	assert(pi3->refcount == 1);
  1094fa:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  1094fd:	8b 40 04             	mov    0x4(%eax),%eax
  109500:	83 f8 01             	cmp    $0x1,%eax
  109503:	74 24                	je     109529 <pmap_check+0x1304>
  109505:	c7 44 24 0c f7 d9 10 	movl   $0x10d9f7,0xc(%esp)
  10950c:	00 
  10950d:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  109514:	00 
  109515:	c7 44 24 04 10 03 00 	movl   $0x310,0x4(%esp)
  10951c:	00 
  10951d:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  109524:	e8 0f 74 ff ff       	call   100938 <debug_panic>
	pmap_remove(pmap_bootpdir, va+PAGESIZE, PTSIZE*3-PAGESIZE*2);
  109529:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10952c:	05 00 10 00 00       	add    $0x1000,%eax
  109531:	c7 44 24 08 00 e0 bf 	movl   $0xbfe000,0x8(%esp)
  109538:	00 
  109539:	89 44 24 04          	mov    %eax,0x4(%esp)
  10953d:	c7 04 24 00 00 18 00 	movl   $0x180000,(%esp)
  109544:	e8 d0 d2 ff ff       	call   106819 <pmap_remove>
	assert(pi0->refcount == 2);
  109549:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  10954c:	8b 40 04             	mov    0x4(%eax),%eax
  10954f:	83 f8 02             	cmp    $0x2,%eax
  109552:	74 24                	je     109578 <pmap_check+0x1353>
  109554:	c7 44 24 0c 0a da 10 	movl   $0x10da0a,0xc(%esp)
  10955b:	00 
  10955c:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  109563:	00 
  109564:	c7 44 24 04 12 03 00 	movl   $0x312,0x4(%esp)
  10956b:	00 
  10956c:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  109573:	e8 c0 73 ff ff       	call   100938 <debug_panic>
	assert(pi2->refcount == 0); assert(mem_alloc() == pi2);
  109578:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  10957b:	8b 40 04             	mov    0x4(%eax),%eax
  10957e:	85 c0                	test   %eax,%eax
  109580:	74 24                	je     1095a6 <pmap_check+0x1381>
  109582:	c7 44 24 0c b8 d5 10 	movl   $0x10d5b8,0xc(%esp)
  109589:	00 
  10958a:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  109591:	00 
  109592:	c7 44 24 04 13 03 00 	movl   $0x313,0x4(%esp)
  109599:	00 
  10959a:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  1095a1:	e8 92 73 ff ff       	call   100938 <debug_panic>
  1095a6:	e8 70 7a ff ff       	call   10101b <mem_alloc>
  1095ab:	3b 45 e0             	cmp    0xffffffe0(%ebp),%eax
  1095ae:	74 24                	je     1095d4 <pmap_check+0x13af>
  1095b0:	c7 44 24 0c cb d5 10 	movl   $0x10d5cb,0xc(%esp)
  1095b7:	00 
  1095b8:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  1095bf:	00 
  1095c0:	c7 44 24 04 13 03 00 	movl   $0x313,0x4(%esp)
  1095c7:	00 
  1095c8:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  1095cf:	e8 64 73 ff ff       	call   100938 <debug_panic>
	assert(mem_freelist == NULL);
  1095d4:	a1 80 ed 17 00       	mov    0x17ed80,%eax
  1095d9:	85 c0                	test   %eax,%eax
  1095db:	74 24                	je     109601 <pmap_check+0x13dc>
  1095dd:	c7 44 24 0c f0 d6 10 	movl   $0x10d6f0,0xc(%esp)
  1095e4:	00 
  1095e5:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  1095ec:	00 
  1095ed:	c7 44 24 04 14 03 00 	movl   $0x314,0x4(%esp)
  1095f4:	00 
  1095f5:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  1095fc:	e8 37 73 ff ff       	call   100938 <debug_panic>
	pmap_remove(pmap_bootpdir, va, PTSIZE*3-PAGESIZE);
  109601:	c7 44 24 08 00 f0 bf 	movl   $0xbff000,0x8(%esp)
  109608:	00 
  109609:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10960c:	89 44 24 04          	mov    %eax,0x4(%esp)
  109610:	c7 04 24 00 00 18 00 	movl   $0x180000,(%esp)
  109617:	e8 fd d1 ff ff       	call   106819 <pmap_remove>
	assert(pi0->refcount == 1);
  10961c:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  10961f:	8b 40 04             	mov    0x4(%eax),%eax
  109622:	83 f8 01             	cmp    $0x1,%eax
  109625:	74 24                	je     10964b <pmap_check+0x1426>
  109627:	c7 44 24 0c ef d2 10 	movl   $0x10d2ef,0xc(%esp)
  10962e:	00 
  10962f:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  109636:	00 
  109637:	c7 44 24 04 16 03 00 	movl   $0x316,0x4(%esp)
  10963e:	00 
  10963f:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  109646:	e8 ed 72 ff ff       	call   100938 <debug_panic>
	assert(pi1->refcount == 0); assert(mem_alloc() == pi1);
  10964b:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  10964e:	8b 40 04             	mov    0x4(%eax),%eax
  109651:	85 c0                	test   %eax,%eax
  109653:	74 24                	je     109679 <pmap_check+0x1454>
  109655:	c7 44 24 0c 37 d6 10 	movl   $0x10d637,0xc(%esp)
  10965c:	00 
  10965d:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  109664:	00 
  109665:	c7 44 24 04 17 03 00 	movl   $0x317,0x4(%esp)
  10966c:	00 
  10966d:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  109674:	e8 bf 72 ff ff       	call   100938 <debug_panic>
  109679:	e8 9d 79 ff ff       	call   10101b <mem_alloc>
  10967e:	3b 45 dc             	cmp    0xffffffdc(%ebp),%eax
  109681:	74 24                	je     1096a7 <pmap_check+0x1482>
  109683:	c7 44 24 0c 4a d6 10 	movl   $0x10d64a,0xc(%esp)
  10968a:	00 
  10968b:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  109692:	00 
  109693:	c7 44 24 04 17 03 00 	movl   $0x317,0x4(%esp)
  10969a:	00 
  10969b:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  1096a2:	e8 91 72 ff ff       	call   100938 <debug_panic>
	assert(mem_freelist == NULL);
  1096a7:	a1 80 ed 17 00       	mov    0x17ed80,%eax
  1096ac:	85 c0                	test   %eax,%eax
  1096ae:	74 24                	je     1096d4 <pmap_check+0x14af>
  1096b0:	c7 44 24 0c f0 d6 10 	movl   $0x10d6f0,0xc(%esp)
  1096b7:	00 
  1096b8:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  1096bf:	00 
  1096c0:	c7 44 24 04 18 03 00 	movl   $0x318,0x4(%esp)
  1096c7:	00 
  1096c8:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  1096cf:	e8 64 72 ff ff       	call   100938 <debug_panic>
	pmap_remove(pmap_bootpdir, va+PTSIZE*3-PAGESIZE, PAGESIZE);
  1096d4:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1096d7:	05 00 f0 bf 00       	add    $0xbff000,%eax
  1096dc:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  1096e3:	00 
  1096e4:	89 44 24 04          	mov    %eax,0x4(%esp)
  1096e8:	c7 04 24 00 00 18 00 	movl   $0x180000,(%esp)
  1096ef:	e8 25 d1 ff ff       	call   106819 <pmap_remove>
	assert(pi0->refcount == 0);	// pi3 might or might not also be freed
  1096f4:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  1096f7:	8b 40 04             	mov    0x4(%eax),%eax
  1096fa:	85 c0                	test   %eax,%eax
  1096fc:	74 24                	je     109722 <pmap_check+0x14fd>
  1096fe:	c7 44 24 0c ca d6 10 	movl   $0x10d6ca,0xc(%esp)
  109705:	00 
  109706:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  10970d:	00 
  10970e:	c7 44 24 04 1a 03 00 	movl   $0x31a,0x4(%esp)
  109715:	00 
  109716:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  10971d:	e8 16 72 ff ff       	call   100938 <debug_panic>
	pmap_remove(pmap_bootpdir, va+PAGESIZE, PTSIZE*3);
  109722:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  109725:	05 00 10 00 00       	add    $0x1000,%eax
  10972a:	c7 44 24 08 00 00 c0 	movl   $0xc00000,0x8(%esp)
  109731:	00 
  109732:	89 44 24 04          	mov    %eax,0x4(%esp)
  109736:	c7 04 24 00 00 18 00 	movl   $0x180000,(%esp)
  10973d:	e8 d7 d0 ff ff       	call   106819 <pmap_remove>
	assert(pi3->refcount == 0);
  109742:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  109745:	8b 40 04             	mov    0x4(%eax),%eax
  109748:	85 c0                	test   %eax,%eax
  10974a:	74 24                	je     109770 <pmap_check+0x154b>
  10974c:	c7 44 24 0c 1d da 10 	movl   $0x10da1d,0xc(%esp)
  109753:	00 
  109754:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  10975b:	00 
  10975c:	c7 44 24 04 1c 03 00 	movl   $0x31c,0x4(%esp)
  109763:	00 
  109764:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  10976b:	e8 c8 71 ff ff       	call   100938 <debug_panic>
	mem_alloc(); mem_alloc();	// collect pi0 and pi3
  109770:	e8 a6 78 ff ff       	call   10101b <mem_alloc>
  109775:	e8 a1 78 ff ff       	call   10101b <mem_alloc>
	assert(mem_freelist == NULL);
  10977a:	a1 80 ed 17 00       	mov    0x17ed80,%eax
  10977f:	85 c0                	test   %eax,%eax
  109781:	74 24                	je     1097a7 <pmap_check+0x1582>
  109783:	c7 44 24 0c f0 d6 10 	movl   $0x10d6f0,0xc(%esp)
  10978a:	00 
  10978b:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  109792:	00 
  109793:	c7 44 24 04 1e 03 00 	movl   $0x31e,0x4(%esp)
  10979a:	00 
  10979b:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  1097a2:	e8 91 71 ff ff       	call   100938 <debug_panic>

	// check pointer arithmetic in pmap_walk
	mem_free(pi0);
  1097a7:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  1097aa:	89 04 24             	mov    %eax,(%esp)
  1097ad:	e8 ad 78 ff ff       	call   10105f <mem_free>
	va = VM_USERLO + PAGESIZE*NPTENTRIES + PAGESIZE;
  1097b2:	c7 45 f8 00 10 40 40 	movl   $0x40401000,0xfffffff8(%ebp)
	ptep = pmap_walk(pmap_bootpdir, va, 1);
  1097b9:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
  1097c0:	00 
  1097c1:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1097c4:	89 44 24 04          	mov    %eax,0x4(%esp)
  1097c8:	c7 04 24 00 00 18 00 	movl   $0x180000,(%esp)
  1097cf:	e8 0f c8 ff ff       	call   105fe3 <pmap_walk>
  1097d4:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
	ptep1 = mem_ptr(PGADDR(pmap_bootpdir[PDX(va)]));
  1097d7:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1097da:	c1 e8 16             	shr    $0x16,%eax
  1097dd:	25 ff 03 00 00       	and    $0x3ff,%eax
  1097e2:	8b 04 85 00 00 18 00 	mov    0x180000(,%eax,4),%eax
  1097e9:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1097ee:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
	assert(ptep == ptep1 + PTX(va));
  1097f1:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1097f4:	c1 e8 0c             	shr    $0xc,%eax
  1097f7:	25 ff 03 00 00       	and    $0x3ff,%eax
  1097fc:	c1 e0 02             	shl    $0x2,%eax
  1097ff:	03 45 f0             	add    0xfffffff0(%ebp),%eax
  109802:	3b 45 ec             	cmp    0xffffffec(%ebp),%eax
  109805:	74 24                	je     10982b <pmap_check+0x1606>
  109807:	c7 44 24 0c 30 da 10 	movl   $0x10da30,0xc(%esp)
  10980e:	00 
  10980f:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  109816:	00 
  109817:	c7 44 24 04 25 03 00 	movl   $0x325,0x4(%esp)
  10981e:	00 
  10981f:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  109826:	e8 0d 71 ff ff       	call   100938 <debug_panic>
	pmap_bootpdir[PDX(va)] = PTE_ZERO;
  10982b:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10982e:	c1 e8 16             	shr    $0x16,%eax
  109831:	89 c2                	mov    %eax,%edx
  109833:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
  109839:	b8 00 10 18 00       	mov    $0x181000,%eax
  10983e:	89 04 95 00 00 18 00 	mov    %eax,0x180000(,%edx,4)
	pi0->refcount = 0;
  109845:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  109848:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)

	// check that new page tables get cleared
	memset(mem_pi2ptr(pi0), 0xFF, PAGESIZE);
  10984f:	8b 55 d8             	mov    0xffffffd8(%ebp),%edx
  109852:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  109857:	89 d1                	mov    %edx,%ecx
  109859:	29 c1                	sub    %eax,%ecx
  10985b:	89 c8                	mov    %ecx,%eax
  10985d:	c1 e0 09             	shl    $0x9,%eax
  109860:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  109867:	00 
  109868:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
  10986f:	00 
  109870:	89 04 24             	mov    %eax,(%esp)
  109873:	e8 91 1f 00 00       	call   10b809 <memset>
	mem_free(pi0);
  109878:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  10987b:	89 04 24             	mov    %eax,(%esp)
  10987e:	e8 dc 77 ff ff       	call   10105f <mem_free>
	pmap_walk(pmap_bootpdir, VM_USERHI-PAGESIZE, 1);
  109883:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
  10988a:	00 
  10988b:	c7 44 24 04 00 f0 ff 	movl   $0xeffff000,0x4(%esp)
  109892:	ef 
  109893:	c7 04 24 00 00 18 00 	movl   $0x180000,(%esp)
  10989a:	e8 44 c7 ff ff       	call   105fe3 <pmap_walk>
	ptep = mem_pi2ptr(pi0);
  10989f:	8b 55 d8             	mov    0xffffffd8(%ebp),%edx
  1098a2:	a1 dc ed 17 00       	mov    0x17eddc,%eax
  1098a7:	89 d3                	mov    %edx,%ebx
  1098a9:	29 c3                	sub    %eax,%ebx
  1098ab:	89 d8                	mov    %ebx,%eax
  1098ad:	c1 e0 09             	shl    $0x9,%eax
  1098b0:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
	for(i=0; i<NPTENTRIES; i++)
  1098b3:	c7 45 f4 00 00 00 00 	movl   $0x0,0xfffffff4(%ebp)
  1098ba:	eb 3c                	jmp    1098f8 <pmap_check+0x16d3>
		assert(ptep[i] == PTE_ZERO);
  1098bc:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  1098bf:	c1 e0 02             	shl    $0x2,%eax
  1098c2:	03 45 ec             	add    0xffffffec(%ebp),%eax
  1098c5:	8b 10                	mov    (%eax),%edx
  1098c7:	b8 00 10 18 00       	mov    $0x181000,%eax
  1098cc:	39 c2                	cmp    %eax,%edx
  1098ce:	74 24                	je     1098f4 <pmap_check+0x16cf>
  1098d0:	c7 44 24 0c 48 da 10 	movl   $0x10da48,0xc(%esp)
  1098d7:	00 
  1098d8:	c7 44 24 08 c6 ce 10 	movl   $0x10cec6,0x8(%esp)
  1098df:	00 
  1098e0:	c7 44 24 04 2f 03 00 	movl   $0x32f,0x4(%esp)
  1098e7:	00 
  1098e8:	c7 04 24 ae cf 10 00 	movl   $0x10cfae,(%esp)
  1098ef:	e8 44 70 ff ff       	call   100938 <debug_panic>
  1098f4:	83 45 f4 01          	addl   $0x1,0xfffffff4(%ebp)
  1098f8:	81 7d f4 ff 03 00 00 	cmpl   $0x3ff,0xfffffff4(%ebp)
  1098ff:	7e bb                	jle    1098bc <pmap_check+0x1697>
	pmap_bootpdir[PDX(VM_USERHI-PAGESIZE)] = PTE_ZERO;
  109901:	b8 00 10 18 00       	mov    $0x181000,%eax
  109906:	a3 fc 0e 18 00       	mov    %eax,0x180efc
	pi0->refcount = 0;
  10990b:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  10990e:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)

	// give free list back
	mem_freelist = fl;
  109915:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  109918:	a3 80 ed 17 00       	mov    %eax,0x17ed80

	// free the pages we filched
	mem_free(pi0);
  10991d:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  109920:	89 04 24             	mov    %eax,(%esp)
  109923:	e8 37 77 ff ff       	call   10105f <mem_free>
	mem_free(pi1);
  109928:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  10992b:	89 04 24             	mov    %eax,(%esp)
  10992e:	e8 2c 77 ff ff       	call   10105f <mem_free>
	mem_free(pi2);
  109933:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  109936:	89 04 24             	mov    %eax,(%esp)
  109939:	e8 21 77 ff ff       	call   10105f <mem_free>
	mem_free(pi3);
  10993e:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  109941:	89 04 24             	mov    %eax,(%esp)
  109944:	e8 16 77 ff ff       	call   10105f <mem_free>

	cprintf("pmap_check() succeeded!\n");
  109949:	c7 04 24 5c da 10 00 	movl   $0x10da5c,(%esp)
  109950:	e8 30 1b 00 00       	call   10b485 <cprintf>
}
  109955:	83 c4 44             	add    $0x44,%esp
  109958:	5b                   	pop    %ebx
  109959:	5d                   	pop    %ebp
  10995a:	c3                   	ret    
  10995b:	90                   	nop    

0010995c <file_init>:


void
file_init(void)
{
  10995c:	55                   	push   %ebp
  10995d:	89 e5                	mov    %esp,%ebp
  10995f:	83 ec 18             	sub    $0x18,%esp
	if (!cpu_onboot())
  109962:	e8 22 00 00 00       	call   109989 <cpu_onboot>
  109967:	85 c0                	test   %eax,%eax
  109969:	74 1c                	je     109987 <file_init+0x2b>
		return;

	spinlock_init(&file_lock);
  10996b:	c7 44 24 08 3b 00 00 	movl   $0x3b,0x8(%esp)
  109972:	00 
  109973:	c7 44 24 04 9c da 10 	movl   $0x10da9c,0x4(%esp)
  10997a:	00 
  10997b:	c7 04 24 e0 ec 17 00 	movl   $0x17ece0,(%esp)
  109982:	e8 d9 a0 ff ff       	call   103a60 <spinlock_init_>
}
  109987:	c9                   	leave  
  109988:	c3                   	ret    

00109989 <cpu_onboot>:
}

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  109989:	55                   	push   %ebp
  10998a:	89 e5                	mov    %esp,%ebp
  10998c:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  10998f:	e8 0d 00 00 00       	call   1099a1 <cpu_cur>
  109994:	3d 00 e0 10 00       	cmp    $0x10e000,%eax
  109999:	0f 94 c0             	sete   %al
  10999c:	0f b6 c0             	movzbl %al,%eax
}
  10999f:	c9                   	leave  
  1099a0:	c3                   	ret    

001099a1 <cpu_cur>:
  1099a1:	55                   	push   %ebp
  1099a2:	89 e5                	mov    %esp,%ebp
  1099a4:	83 ec 28             	sub    $0x28,%esp
static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  1099a7:	89 65 fc             	mov    %esp,0xfffffffc(%ebp)
        return esp;
  1099aa:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  1099ad:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  1099b0:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1099b3:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1099b8:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	assert(c->magic == CPU_MAGIC);
  1099bb:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  1099be:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  1099c4:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  1099c9:	74 24                	je     1099ef <cpu_cur+0x4e>
  1099cb:	c7 44 24 0c a8 da 10 	movl   $0x10daa8,0xc(%esp)
  1099d2:	00 
  1099d3:	c7 44 24 08 be da 10 	movl   $0x10dabe,0x8(%esp)
  1099da:	00 
  1099db:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  1099e2:	00 
  1099e3:	c7 04 24 d3 da 10 00 	movl   $0x10dad3,(%esp)
  1099ea:	e8 49 6f ff ff       	call   100938 <debug_panic>
	return c;
  1099ef:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
}
  1099f2:	c9                   	leave  
  1099f3:	c3                   	ret    

001099f4 <file_initroot>:

void
file_initroot(proc *root)
{
  1099f4:	55                   	push   %ebp
  1099f5:	89 e5                	mov    %esp,%ebp
  1099f7:	83 ec 48             	sub    $0x48,%esp
	// Only one root process may perform external I/O directly -
	// all other processes do I/O indirectly via the process hierarchy.
	assert(root == proc_root);
  1099fa:	a1 b0 f4 17 00       	mov    0x17f4b0,%eax
  1099ff:	39 45 08             	cmp    %eax,0x8(%ebp)
  109a02:	74 24                	je     109a28 <file_initroot+0x34>
  109a04:	c7 44 24 0c e0 da 10 	movl   $0x10dae0,0xc(%esp)
  109a0b:	00 
  109a0c:	c7 44 24 08 be da 10 	movl   $0x10dabe,0x8(%esp)
  109a13:	00 
  109a14:	c7 44 24 04 43 00 00 	movl   $0x43,0x4(%esp)
  109a1b:	00 
  109a1c:	c7 04 24 9c da 10 00 	movl   $0x10da9c,(%esp)
  109a23:	e8 10 6f ff ff       	call   100938 <debug_panic>

	// Make sure the root process's page directory is loaded,
	// so that we can write into the root process's file area directly.
	cpu_cur()->proc = root;
  109a28:	e8 74 ff ff ff       	call   1099a1 <cpu_cur>
  109a2d:	89 c2                	mov    %eax,%edx
  109a2f:	8b 45 08             	mov    0x8(%ebp),%eax
  109a32:	89 82 b4 00 00 00    	mov    %eax,0xb4(%edx)
	lcr3(mem_phys(root->pdir));
  109a38:	8b 45 08             	mov    0x8(%ebp),%eax
  109a3b:	8b 80 a0 06 00 00    	mov    0x6a0(%eax),%eax
  109a41:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)

static gcc_inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
  109a44:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  109a47:	0f 22 d8             	mov    %eax,%cr3

	// Enable read/write access on the file metadata area
	pmap_setperm(root->pdir, FILESVA, ROUNDUP(sizeof(filestate), PAGESIZE),
  109a4a:	c7 45 e8 00 10 00 00 	movl   $0x1000,0xffffffe8(%ebp)
  109a51:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  109a54:	05 0f 70 00 00       	add    $0x700f,%eax
  109a59:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  109a5c:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  109a5f:	ba 00 00 00 00       	mov    $0x0,%edx
  109a64:	f7 75 e8             	divl   0xffffffe8(%ebp)
  109a67:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  109a6a:	29 d0                	sub    %edx,%eax
  109a6c:	89 c2                	mov    %eax,%edx
  109a6e:	8b 45 08             	mov    0x8(%ebp),%eax
  109a71:	8b 80 a0 06 00 00    	mov    0x6a0(%eax),%eax
  109a77:	c7 44 24 0c 00 06 00 	movl   $0x600,0xc(%esp)
  109a7e:	00 
  109a7f:	89 54 24 08          	mov    %edx,0x8(%esp)
  109a83:	c7 44 24 04 00 00 00 	movl   $0x80000000,0x4(%esp)
  109a8a:	80 
  109a8b:	89 04 24             	mov    %eax,(%esp)
  109a8e:	e8 f9 e4 ff ff       	call   107f8c <pmap_setperm>
				SYS_READ | SYS_WRITE);
	memset(files, 0, sizeof(*files));
  109a93:	a1 98 da 10 00       	mov    0x10da98,%eax
  109a98:	c7 44 24 08 10 70 00 	movl   $0x7010,0x8(%esp)
  109a9f:	00 
  109aa0:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  109aa7:	00 
  109aa8:	89 04 24             	mov    %eax,(%esp)
  109aab:	e8 59 1d 00 00       	call   10b809 <memset>

	// Set up the standard I/O descriptors for console I/O
	files->fd[0].ino = FILEINO_CONSIN;
  109ab0:	a1 98 da 10 00       	mov    0x10da98,%eax
  109ab5:	c7 40 10 01 00 00 00 	movl   $0x1,0x10(%eax)
	files->fd[0].flags = O_RDONLY;
  109abc:	a1 98 da 10 00       	mov    0x10da98,%eax
  109ac1:	c7 40 14 01 00 00 00 	movl   $0x1,0x14(%eax)
	files->fd[1].ino = FILEINO_CONSOUT;
  109ac8:	a1 98 da 10 00       	mov    0x10da98,%eax
  109acd:	c7 40 20 02 00 00 00 	movl   $0x2,0x20(%eax)
	files->fd[1].flags = O_WRONLY | O_APPEND;
  109ad4:	a1 98 da 10 00       	mov    0x10da98,%eax
  109ad9:	c7 40 24 12 00 00 00 	movl   $0x12,0x24(%eax)
	files->fd[2].ino = FILEINO_CONSOUT;
  109ae0:	a1 98 da 10 00       	mov    0x10da98,%eax
  109ae5:	c7 40 30 02 00 00 00 	movl   $0x2,0x30(%eax)
	files->fd[2].flags = O_WRONLY | O_APPEND;
  109aec:	a1 98 da 10 00       	mov    0x10da98,%eax
  109af1:	c7 40 34 12 00 00 00 	movl   $0x12,0x34(%eax)

	// Setup the inodes for the console I/O files and root directory
	strcpy(files->fi[FILEINO_CONSIN].de.d_name, "consin");
  109af8:	a1 98 da 10 00       	mov    0x10da98,%eax
  109afd:	05 70 10 00 00       	add    $0x1070,%eax
  109b02:	c7 44 24 04 f2 da 10 	movl   $0x10daf2,0x4(%esp)
  109b09:	00 
  109b0a:	89 04 24             	mov    %eax,(%esp)
  109b0d:	e8 50 1b 00 00       	call   10b662 <strcpy>
	strcpy(files->fi[FILEINO_CONSOUT].de.d_name, "consout");
  109b12:	a1 98 da 10 00       	mov    0x10da98,%eax
  109b17:	05 cc 10 00 00       	add    $0x10cc,%eax
  109b1c:	c7 44 24 04 f9 da 10 	movl   $0x10daf9,0x4(%esp)
  109b23:	00 
  109b24:	89 04 24             	mov    %eax,(%esp)
  109b27:	e8 36 1b 00 00       	call   10b662 <strcpy>
	strcpy(files->fi[FILEINO_ROOTDIR].de.d_name, "/");
  109b2c:	a1 98 da 10 00       	mov    0x10da98,%eax
  109b31:	05 28 11 00 00       	add    $0x1128,%eax
  109b36:	c7 44 24 04 01 db 10 	movl   $0x10db01,0x4(%esp)
  109b3d:	00 
  109b3e:	89 04 24             	mov    %eax,(%esp)
  109b41:	e8 1c 1b 00 00       	call   10b662 <strcpy>
	files->fi[FILEINO_CONSIN].dino = FILEINO_ROOTDIR;
  109b46:	a1 98 da 10 00       	mov    0x10da98,%eax
  109b4b:	c7 80 6c 10 00 00 03 	movl   $0x3,0x106c(%eax)
  109b52:	00 00 00 
	files->fi[FILEINO_CONSOUT].dino = FILEINO_ROOTDIR;
  109b55:	a1 98 da 10 00       	mov    0x10da98,%eax
  109b5a:	c7 80 c8 10 00 00 03 	movl   $0x3,0x10c8(%eax)
  109b61:	00 00 00 
	files->fi[FILEINO_ROOTDIR].dino = FILEINO_ROOTDIR;
  109b64:	a1 98 da 10 00       	mov    0x10da98,%eax
  109b69:	c7 80 24 11 00 00 03 	movl   $0x3,0x1124(%eax)
  109b70:	00 00 00 
	files->fi[FILEINO_CONSIN].mode = S_IFREG | S_IFPART;
  109b73:	a1 98 da 10 00       	mov    0x10da98,%eax
  109b78:	c7 80 b4 10 00 00 00 	movl   $0x9000,0x10b4(%eax)
  109b7f:	90 00 00 
	files->fi[FILEINO_CONSOUT].mode = S_IFREG;
  109b82:	a1 98 da 10 00       	mov    0x10da98,%eax
  109b87:	c7 80 10 11 00 00 00 	movl   $0x1000,0x1110(%eax)
  109b8e:	10 00 00 
	files->fi[FILEINO_ROOTDIR].mode = S_IFDIR;
  109b91:	a1 98 da 10 00       	mov    0x10da98,%eax
  109b96:	c7 80 6c 11 00 00 00 	movl   $0x2000,0x116c(%eax)
  109b9d:	20 00 00 

	// Set the whole console input area to be read/write,
	// so we won't have to worry about perms in cons_io().
	pmap_setperm(root->pdir, (uintptr_t)FILEDATA(FILEINO_CONSIN),
  109ba0:	8b 45 08             	mov    0x8(%ebp),%eax
  109ba3:	8b 80 a0 06 00 00    	mov    0x6a0(%eax),%eax
  109ba9:	c7 44 24 0c 00 06 00 	movl   $0x600,0xc(%esp)
  109bb0:	00 
  109bb1:	c7 44 24 08 00 00 40 	movl   $0x400000,0x8(%esp)
  109bb8:	00 
  109bb9:	c7 44 24 04 00 00 40 	movl   $0x80400000,0x4(%esp)
  109bc0:	80 
  109bc1:	89 04 24             	mov    %eax,(%esp)
  109bc4:	e8 c3 e3 ff ff       	call   107f8c <pmap_setperm>
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
  109bc9:	c7 45 dc 07 00 00 00 	movl   $0x7,0xffffffdc(%ebp)
	int i;
	int ino = FILEINO_GENERAL;
  109bd0:	c7 45 e4 04 00 00 00 	movl   $0x4,0xffffffe4(%ebp)
	for (i = 0; i < ninitfiles; i++) {
  109bd7:	c7 45 e0 00 00 00 00 	movl   $0x0,0xffffffe0(%ebp)
  109bde:	e9 39 01 00 00       	jmp    109d1c <file_initroot+0x328>
		int filesize = initfiles[i][2] - initfiles[i][1];
  109be3:	8b 55 e0             	mov    0xffffffe0(%ebp),%edx
  109be6:	89 d0                	mov    %edx,%eax
  109be8:	01 c0                	add    %eax,%eax
  109bea:	01 d0                	add    %edx,%eax
  109bec:	c1 e0 02             	shl    $0x2,%eax
  109bef:	8b 80 28 f0 10 00    	mov    0x10f028(%eax),%eax
  109bf5:	89 c1                	mov    %eax,%ecx
  109bf7:	8b 55 e0             	mov    0xffffffe0(%ebp),%edx
  109bfa:	89 d0                	mov    %edx,%eax
  109bfc:	01 c0                	add    %eax,%eax
  109bfe:	01 d0                	add    %edx,%eax
  109c00:	c1 e0 02             	shl    $0x2,%eax
  109c03:	8b 80 24 f0 10 00    	mov    0x10f024(%eax),%eax
  109c09:	89 ca                	mov    %ecx,%edx
  109c0b:	29 c2                	sub    %eax,%edx
  109c0d:	89 d0                	mov    %edx,%eax
  109c0f:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
		strcpy(files->fi[ino].de.d_name, initfiles[i][0]);
  109c12:	8b 55 e0             	mov    0xffffffe0(%ebp),%edx
  109c15:	89 d0                	mov    %edx,%eax
  109c17:	01 c0                	add    %eax,%eax
  109c19:	01 d0                	add    %edx,%eax
  109c1b:	c1 e0 02             	shl    $0x2,%eax
  109c1e:	8b 88 20 f0 10 00    	mov    0x10f020(%eax),%ecx
  109c24:	8b 15 98 da 10 00    	mov    0x10da98,%edx
  109c2a:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  109c2d:	6b c0 5c             	imul   $0x5c,%eax,%eax
  109c30:	05 10 10 00 00       	add    $0x1010,%eax
  109c35:	8d 04 02             	lea    (%edx,%eax,1),%eax
  109c38:	83 c0 04             	add    $0x4,%eax
  109c3b:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  109c3f:	89 04 24             	mov    %eax,(%esp)
  109c42:	e8 1b 1a 00 00       	call   10b662 <strcpy>
		files->fi[ino].dino = FILEINO_ROOTDIR;
  109c47:	8b 15 98 da 10 00    	mov    0x10da98,%edx
  109c4d:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  109c50:	6b c0 5c             	imul   $0x5c,%eax,%eax
  109c53:	01 d0                	add    %edx,%eax
  109c55:	05 10 10 00 00       	add    $0x1010,%eax
  109c5a:	c7 00 03 00 00 00    	movl   $0x3,(%eax)
		files->fi[ino].mode = S_IFREG;
  109c60:	8b 15 98 da 10 00    	mov    0x10da98,%edx
  109c66:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  109c69:	6b c0 5c             	imul   $0x5c,%eax,%eax
  109c6c:	01 d0                	add    %edx,%eax
  109c6e:	05 58 10 00 00       	add    $0x1058,%eax
  109c73:	c7 00 00 10 00 00    	movl   $0x1000,(%eax)
		files->fi[ino].size = filesize;
  109c79:	8b 15 98 da 10 00    	mov    0x10da98,%edx
  109c7f:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  109c82:	8b 4d f0             	mov    0xfffffff0(%ebp),%ecx
  109c85:	6b c0 5c             	imul   $0x5c,%eax,%eax
  109c88:	01 d0                	add    %edx,%eax
  109c8a:	05 5c 10 00 00       	add    $0x105c,%eax
  109c8f:	89 08                	mov    %ecx,(%eax)
		pmap_setperm(root->pdir, (uintptr_t)FILEDATA(ino),
					ROUNDUP(filesize, PAGESIZE),
  109c91:	c7 45 f4 00 10 00 00 	movl   $0x1000,0xfffffff4(%ebp)
  109c98:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  109c9b:	03 45 f4             	add    0xfffffff4(%ebp),%eax
  109c9e:	83 e8 01             	sub    $0x1,%eax
  109ca1:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  109ca4:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  109ca7:	ba 00 00 00 00       	mov    $0x0,%edx
  109cac:	f7 75 f4             	divl   0xfffffff4(%ebp)
  109caf:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  109cb2:	29 d0                	sub    %edx,%eax
  109cb4:	89 c1                	mov    %eax,%ecx
  109cb6:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  109cb9:	c1 e0 16             	shl    $0x16,%eax
  109cbc:	2d 00 00 00 80       	sub    $0x80000000,%eax
  109cc1:	89 c2                	mov    %eax,%edx
  109cc3:	8b 45 08             	mov    0x8(%ebp),%eax
  109cc6:	8b 80 a0 06 00 00    	mov    0x6a0(%eax),%eax
  109ccc:	c7 44 24 0c 00 06 00 	movl   $0x600,0xc(%esp)
  109cd3:	00 
  109cd4:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  109cd8:	89 54 24 04          	mov    %edx,0x4(%esp)
  109cdc:	89 04 24             	mov    %eax,(%esp)
  109cdf:	e8 a8 e2 ff ff       	call   107f8c <pmap_setperm>
					SYS_READ | SYS_WRITE);
		memcpy(FILEDATA(ino), initfiles[i][1], filesize);
  109ce4:	8b 4d f0             	mov    0xfffffff0(%ebp),%ecx
  109ce7:	8b 55 e0             	mov    0xffffffe0(%ebp),%edx
  109cea:	89 d0                	mov    %edx,%eax
  109cec:	01 c0                	add    %eax,%eax
  109cee:	01 d0                	add    %edx,%eax
  109cf0:	c1 e0 02             	shl    $0x2,%eax
  109cf3:	8b 90 24 f0 10 00    	mov    0x10f024(%eax),%edx
  109cf9:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  109cfc:	c1 e0 16             	shl    $0x16,%eax
  109cff:	2d 00 00 00 80       	sub    $0x80000000,%eax
  109d04:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  109d08:	89 54 24 04          	mov    %edx,0x4(%esp)
  109d0c:	89 04 24             	mov    %eax,(%esp)
  109d0f:	e8 34 1c 00 00       	call   10b948 <memcpy>
    ino++;
  109d14:	83 45 e4 01          	addl   $0x1,0xffffffe4(%ebp)
  109d18:	83 45 e0 01          	addl   $0x1,0xffffffe0(%ebp)
  109d1c:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  109d1f:	3b 45 dc             	cmp    0xffffffdc(%ebp),%eax
  109d22:	0f 8c bb fe ff ff    	jl     109be3 <file_initroot+0x1ef>
	}

	// Set root process's current working directory
	files->cwd = FILEINO_ROOTDIR;
  109d28:	a1 98 da 10 00       	mov    0x10da98,%eax
  109d2d:	c7 40 04 03 00 00 00 	movl   $0x3,0x4(%eax)

	// Child process state - reserve PID 0 as a "scratch" child process.
	files->child[0].state = PROC_RESERVED;
  109d34:	a1 98 da 10 00       	mov    0x10da98,%eax
  109d39:	c7 80 10 6c 00 00 ff 	movl   $0xffffffff,0x6c10(%eax)
  109d40:	ff ff ff 
}
  109d43:	c9                   	leave  
  109d44:	c3                   	ret    

00109d45 <file_io>:

// Called from proc_ret() when the root process "returns" -
// this function performs any new output the root process requested,
// or if it didn't request output, puts the root process to sleep
// waiting for input to arrive from some I/O device.
void
file_io(trapframe *tf)
{
  109d45:	55                   	push   %ebp
  109d46:	89 e5                	mov    %esp,%ebp
  109d48:	83 ec 28             	sub    $0x28,%esp
	proc *cp = proc_cur();
  109d4b:	e8 51 fc ff ff       	call   1099a1 <cpu_cur>
  109d50:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  109d56:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
	assert(cp == proc_root);	// only root process should do this!
  109d59:	a1 b0 f4 17 00       	mov    0x17f4b0,%eax
  109d5e:	39 45 f8             	cmp    %eax,0xfffffff8(%ebp)
  109d61:	74 24                	je     109d87 <file_io+0x42>
  109d63:	c7 44 24 0c 03 db 10 	movl   $0x10db03,0xc(%esp)
  109d6a:	00 
  109d6b:	c7 44 24 08 be da 10 	movl   $0x10dabe,0x8(%esp)
  109d72:	00 
  109d73:	c7 44 24 04 8e 00 00 	movl   $0x8e,0x4(%esp)
  109d7a:	00 
  109d7b:	c7 04 24 9c da 10 00 	movl   $0x10da9c,(%esp)
  109d82:	e8 b1 6b ff ff       	call   100938 <debug_panic>

	// Note that we don't need to bother protecting ourselves
	// against memory access traps while accessing user memory here,
	// because we consider the root process a special, "trusted" process:
	// the whole system goes down anyway if the root process goes haywire.
	// This is very different from handling system calls
	// on behalf of arbitrary processes that might be buggy or evil.

	// Perform I/O with whatever devices we have access to.
	bool iodone = 0;
  109d87:	c7 45 fc 00 00 00 00 	movl   $0x0,0xfffffffc(%ebp)
	iodone |= cons_io();
  109d8e:	e8 0e 6a ff ff       	call   1007a1 <cons_io>
  109d93:	09 45 fc             	or     %eax,0xfffffffc(%ebp)

	// Has the root process exited?
	if (files->exited) {
  109d96:	a1 98 da 10 00       	mov    0x10da98,%eax
  109d9b:	8b 40 08             	mov    0x8(%eax),%eax
  109d9e:	85 c0                	test   %eax,%eax
  109da0:	74 1d                	je     109dbf <file_io+0x7a>
		cprintf("root process exited with status %d\n", files->status);
  109da2:	a1 98 da 10 00       	mov    0x10da98,%eax
  109da7:	8b 40 0c             	mov    0xc(%eax),%eax
  109daa:	89 44 24 04          	mov    %eax,0x4(%esp)
  109dae:	c7 04 24 14 db 10 00 	movl   $0x10db14,(%esp)
  109db5:	e8 cb 16 00 00       	call   10b485 <cprintf>
		done();
  109dba:	e8 86 67 ff ff       	call   100545 <done>
	}

	// We successfully did some I/O, let the root process run again.
	if (iodone)
  109dbf:	83 7d fc 00          	cmpl   $0x0,0xfffffffc(%ebp)
  109dc3:	74 0b                	je     109dd0 <file_io+0x8b>
		trap_return(tf);
  109dc5:	8b 45 08             	mov    0x8(%ebp),%eax
  109dc8:	89 04 24             	mov    %eax,(%esp)
  109dcb:	e8 60 98 ff ff       	call   103630 <trap_return>

	// No I/O ready - put the root process to sleep waiting for I/O.
	spinlock_acquire(&file_lock);
  109dd0:	c7 04 24 e0 ec 17 00 	movl   $0x17ece0,(%esp)
  109dd7:	e8 ae 9c ff ff       	call   103a8a <spinlock_acquire>
	cp->state = PROC_STOP;		// we're becoming stopped
  109ddc:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  109ddf:	c7 80 3c 04 00 00 00 	movl   $0x0,0x43c(%eax)
  109de6:	00 00 00 
	cp->runcpu = NULL;		// no longer running
  109de9:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  109dec:	c7 80 44 04 00 00 00 	movl   $0x0,0x444(%eax)
  109df3:	00 00 00 
	proc_save(cp, tf, 1);		// save process's state
  109df6:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
  109dfd:	00 
  109dfe:	8b 45 08             	mov    0x8(%ebp),%eax
  109e01:	89 44 24 04          	mov    %eax,0x4(%esp)
  109e05:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  109e08:	89 04 24             	mov    %eax,(%esp)
  109e0b:	e8 2a a6 ff ff       	call   10443a <proc_save>
	spinlock_release(&file_lock);
  109e10:	c7 04 24 e0 ec 17 00 	movl   $0x17ece0,(%esp)
  109e17:	e8 69 9d ff ff       	call   103b85 <spinlock_release>

	proc_sched();			// go do something else
  109e1c:	e8 8b a7 ff ff       	call   1045ac <proc_sched>

00109e21 <file_wakeroot>:
}

// Check to see if any input is available for the root process
// and if the root process is waiting for it, and if so, wake the process.
void
file_wakeroot(void)
{
  109e21:	55                   	push   %ebp
  109e22:	89 e5                	mov    %esp,%ebp
  109e24:	83 ec 08             	sub    $0x8,%esp
	spinlock_acquire(&file_lock);
  109e27:	c7 04 24 e0 ec 17 00 	movl   $0x17ece0,(%esp)
  109e2e:	e8 57 9c ff ff       	call   103a8a <spinlock_acquire>
	if (proc_root && proc_root->state == PROC_STOP)
  109e33:	a1 b0 f4 17 00       	mov    0x17f4b0,%eax
  109e38:	85 c0                	test   %eax,%eax
  109e3a:	74 1c                	je     109e58 <file_wakeroot+0x37>
  109e3c:	a1 b0 f4 17 00       	mov    0x17f4b0,%eax
  109e41:	8b 80 3c 04 00 00    	mov    0x43c(%eax),%eax
  109e47:	85 c0                	test   %eax,%eax
  109e49:	75 0d                	jne    109e58 <file_wakeroot+0x37>
		proc_ready(proc_root);
  109e4b:	a1 b0 f4 17 00       	mov    0x17f4b0,%eax
  109e50:	89 04 24             	mov    %eax,(%esp)
  109e53:	e8 90 a5 ff ff       	call   1043e8 <proc_ready>
	spinlock_release(&file_lock);
  109e58:	c7 04 24 e0 ec 17 00 	movl   $0x17ece0,(%esp)
  109e5f:	e8 21 9d ff ff       	call   103b85 <spinlock_release>
}
  109e64:	c9                   	leave  
  109e65:	c3                   	ret    
  109e66:	90                   	nop    
  109e67:	90                   	nop    

00109e68 <video_init>:
static uint16_t crt_pos;

void
video_init(void)
{
  109e68:	55                   	push   %ebp
  109e69:	89 e5                	mov    %esp,%ebp
  109e6b:	83 ec 30             	sub    $0x30,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	/* Get a pointer to the memory-mapped text display buffer. */
	cp = (uint16_t*) mem_ptr(CGA_BUF);
  109e6e:	c7 45 d4 00 80 0b 00 	movl   $0xb8000,0xffffffd4(%ebp)
	was = *cp;
  109e75:	8b 45 d4             	mov    0xffffffd4(%ebp),%eax
  109e78:	0f b7 00             	movzwl (%eax),%eax
  109e7b:	66 89 45 da          	mov    %ax,0xffffffda(%ebp)
	*cp = (uint16_t) 0xA55A;
  109e7f:	8b 45 d4             	mov    0xffffffd4(%ebp),%eax
  109e82:	66 c7 00 5a a5       	movw   $0xa55a,(%eax)
	if (*cp != 0xA55A) {
  109e87:	8b 45 d4             	mov    0xffffffd4(%ebp),%eax
  109e8a:	0f b7 00             	movzwl (%eax),%eax
  109e8d:	66 3d 5a a5          	cmp    $0xa55a,%ax
  109e91:	74 13                	je     109ea6 <video_init+0x3e>
		cp = (uint16_t*) mem_ptr(MONO_BUF);
  109e93:	c7 45 d4 00 00 0b 00 	movl   $0xb0000,0xffffffd4(%ebp)
		addr_6845 = MONO_BASE;
  109e9a:	c7 05 1c ed 17 00 b4 	movl   $0x3b4,0x17ed1c
  109ea1:	03 00 00 
  109ea4:	eb 14                	jmp    109eba <video_init+0x52>
	} else {
		*cp = was;
  109ea6:	8b 55 d4             	mov    0xffffffd4(%ebp),%edx
  109ea9:	0f b7 45 da          	movzwl 0xffffffda(%ebp),%eax
  109ead:	66 89 02             	mov    %ax,(%edx)
		addr_6845 = CGA_BASE;
  109eb0:	c7 05 1c ed 17 00 d4 	movl   $0x3d4,0x17ed1c
  109eb7:	03 00 00 
	}
	
	/* Extract cursor location */
	outb(addr_6845, 14);
  109eba:	a1 1c ed 17 00       	mov    0x17ed1c,%eax
  109ebf:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
  109ec2:	c6 45 e3 0e          	movb   $0xe,0xffffffe3(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  109ec6:	0f b6 45 e3          	movzbl 0xffffffe3(%ebp),%eax
  109eca:	8b 55 e4             	mov    0xffffffe4(%ebp),%edx
  109ecd:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
  109ece:	a1 1c ed 17 00       	mov    0x17ed1c,%eax
  109ed3:	83 c0 01             	add    $0x1,%eax
  109ed6:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  109ed9:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
  109edc:	ec                   	in     (%dx),%al
  109edd:	88 45 eb             	mov    %al,0xffffffeb(%ebp)
	return data;
  109ee0:	0f b6 45 eb          	movzbl 0xffffffeb(%ebp),%eax
  109ee4:	0f b6 c0             	movzbl %al,%eax
  109ee7:	c1 e0 08             	shl    $0x8,%eax
  109eea:	89 45 dc             	mov    %eax,0xffffffdc(%ebp)
	outb(addr_6845, 15);
  109eed:	a1 1c ed 17 00       	mov    0x17ed1c,%eax
  109ef2:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
  109ef5:	c6 45 f3 0f          	movb   $0xf,0xfffffff3(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  109ef9:	0f b6 45 f3          	movzbl 0xfffffff3(%ebp),%eax
  109efd:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  109f00:	ee                   	out    %al,(%dx)
	pos |= inb(addr_6845 + 1);
  109f01:	a1 1c ed 17 00       	mov    0x17ed1c,%eax
  109f06:	83 c0 01             	add    $0x1,%eax
  109f09:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  109f0c:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  109f0f:	ec                   	in     (%dx),%al
  109f10:	88 45 fb             	mov    %al,0xfffffffb(%ebp)
	return data;
  109f13:	0f b6 45 fb          	movzbl 0xfffffffb(%ebp),%eax
  109f17:	0f b6 c0             	movzbl %al,%eax
  109f1a:	09 45 dc             	or     %eax,0xffffffdc(%ebp)

	crt_buf = (uint16_t*) cp;
  109f1d:	8b 45 d4             	mov    0xffffffd4(%ebp),%eax
  109f20:	a3 20 ed 17 00       	mov    %eax,0x17ed20
	crt_pos = pos;
  109f25:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  109f28:	66 a3 24 ed 17 00    	mov    %ax,0x17ed24
}
  109f2e:	c9                   	leave  
  109f2f:	c3                   	ret    

00109f30 <video_putc>:



void
video_putc(int c)
{
  109f30:	55                   	push   %ebp
  109f31:	89 e5                	mov    %esp,%ebp
  109f33:	53                   	push   %ebx
  109f34:	83 ec 44             	sub    $0x44,%esp
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
  109f37:	8b 45 08             	mov    0x8(%ebp),%eax
  109f3a:	b0 00                	mov    $0x0,%al
  109f3c:	85 c0                	test   %eax,%eax
  109f3e:	75 07                	jne    109f47 <video_putc+0x17>
		c |= 0x0700;
  109f40:	81 4d 08 00 07 00 00 	orl    $0x700,0x8(%ebp)

	switch (c & 0xff) {
  109f47:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
  109f4b:	89 45 c4             	mov    %eax,0xffffffc4(%ebp)
  109f4e:	83 7d c4 09          	cmpl   $0x9,0xffffffc4(%ebp)
  109f52:	0f 84 c0 00 00 00    	je     10a018 <video_putc+0xe8>
  109f58:	83 7d c4 09          	cmpl   $0x9,0xffffffc4(%ebp)
  109f5c:	7f 0b                	jg     109f69 <video_putc+0x39>
  109f5e:	83 7d c4 08          	cmpl   $0x8,0xffffffc4(%ebp)
  109f62:	74 16                	je     109f7a <video_putc+0x4a>
  109f64:	e9 ed 00 00 00       	jmp    10a056 <video_putc+0x126>
  109f69:	83 7d c4 0a          	cmpl   $0xa,0xffffffc4(%ebp)
  109f6d:	74 50                	je     109fbf <video_putc+0x8f>
  109f6f:	83 7d c4 0d          	cmpl   $0xd,0xffffffc4(%ebp)
  109f73:	74 5a                	je     109fcf <video_putc+0x9f>
  109f75:	e9 dc 00 00 00       	jmp    10a056 <video_putc+0x126>
	case '\b':
		if (crt_pos > 0) {
  109f7a:	0f b7 05 24 ed 17 00 	movzwl 0x17ed24,%eax
  109f81:	66 85 c0             	test   %ax,%ax
  109f84:	0f 84 f0 00 00 00    	je     10a07a <video_putc+0x14a>
			crt_pos--;
  109f8a:	0f b7 05 24 ed 17 00 	movzwl 0x17ed24,%eax
  109f91:	83 e8 01             	sub    $0x1,%eax
  109f94:	66 a3 24 ed 17 00    	mov    %ax,0x17ed24
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
  109f9a:	0f b7 05 24 ed 17 00 	movzwl 0x17ed24,%eax
  109fa1:	0f b7 c0             	movzwl %ax,%eax
  109fa4:	01 c0                	add    %eax,%eax
  109fa6:	89 c2                	mov    %eax,%edx
  109fa8:	a1 20 ed 17 00       	mov    0x17ed20,%eax
  109fad:	01 c2                	add    %eax,%edx
  109faf:	8b 45 08             	mov    0x8(%ebp),%eax
  109fb2:	b0 00                	mov    $0x0,%al
  109fb4:	83 c8 20             	or     $0x20,%eax
  109fb7:	66 89 02             	mov    %ax,(%edx)
		}
		break;
  109fba:	e9 bb 00 00 00       	jmp    10a07a <video_putc+0x14a>
	case '\n':
		crt_pos += CRT_COLS;
  109fbf:	0f b7 05 24 ed 17 00 	movzwl 0x17ed24,%eax
  109fc6:	83 c0 50             	add    $0x50,%eax
  109fc9:	66 a3 24 ed 17 00    	mov    %ax,0x17ed24
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
  109fcf:	0f b7 0d 24 ed 17 00 	movzwl 0x17ed24,%ecx
  109fd6:	0f b7 15 24 ed 17 00 	movzwl 0x17ed24,%edx
  109fdd:	0f b7 c2             	movzwl %dx,%eax
  109fe0:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
  109fe6:	c1 e8 10             	shr    $0x10,%eax
  109fe9:	89 c3                	mov    %eax,%ebx
  109feb:	66 c1 eb 06          	shr    $0x6,%bx
  109fef:	66 89 5d ca          	mov    %bx,0xffffffca(%ebp)
  109ff3:	0f b7 45 ca          	movzwl 0xffffffca(%ebp),%eax
  109ff7:	c1 e0 02             	shl    $0x2,%eax
  109ffa:	66 03 45 ca          	add    0xffffffca(%ebp),%ax
  109ffe:	c1 e0 04             	shl    $0x4,%eax
  10a001:	89 d3                	mov    %edx,%ebx
  10a003:	66 29 c3             	sub    %ax,%bx
  10a006:	66 89 5d ca          	mov    %bx,0xffffffca(%ebp)
  10a00a:	89 c8                	mov    %ecx,%eax
  10a00c:	66 2b 45 ca          	sub    0xffffffca(%ebp),%ax
  10a010:	66 a3 24 ed 17 00    	mov    %ax,0x17ed24
		break;
  10a016:	eb 62                	jmp    10a07a <video_putc+0x14a>
	case '\t':
		video_putc(' ');
  10a018:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  10a01f:	e8 0c ff ff ff       	call   109f30 <video_putc>
		video_putc(' ');
  10a024:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  10a02b:	e8 00 ff ff ff       	call   109f30 <video_putc>
		video_putc(' ');
  10a030:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  10a037:	e8 f4 fe ff ff       	call   109f30 <video_putc>
		video_putc(' ');
  10a03c:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  10a043:	e8 e8 fe ff ff       	call   109f30 <video_putc>
		video_putc(' ');
  10a048:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  10a04f:	e8 dc fe ff ff       	call   109f30 <video_putc>
		break;
  10a054:	eb 24                	jmp    10a07a <video_putc+0x14a>
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
  10a056:	0f b7 0d 24 ed 17 00 	movzwl 0x17ed24,%ecx
  10a05d:	0f b7 c1             	movzwl %cx,%eax
  10a060:	01 c0                	add    %eax,%eax
  10a062:	89 c2                	mov    %eax,%edx
  10a064:	a1 20 ed 17 00       	mov    0x17ed20,%eax
  10a069:	01 c2                	add    %eax,%edx
  10a06b:	8b 45 08             	mov    0x8(%ebp),%eax
  10a06e:	66 89 02             	mov    %ax,(%edx)
  10a071:	8d 41 01             	lea    0x1(%ecx),%eax
  10a074:	66 a3 24 ed 17 00    	mov    %ax,0x17ed24
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
  10a07a:	0f b7 05 24 ed 17 00 	movzwl 0x17ed24,%eax
  10a081:	66 3d cf 07          	cmp    $0x7cf,%ax
  10a085:	76 5e                	jbe    10a0e5 <video_putc+0x1b5>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS,
  10a087:	a1 20 ed 17 00       	mov    0x17ed20,%eax
  10a08c:	05 a0 00 00 00       	add    $0xa0,%eax
  10a091:	8b 15 20 ed 17 00    	mov    0x17ed20,%edx
  10a097:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
  10a09e:	00 
  10a09f:	89 44 24 04          	mov    %eax,0x4(%esp)
  10a0a3:	89 14 24             	mov    %edx,(%esp)
  10a0a6:	e8 d7 17 00 00       	call   10b882 <memmove>
			(CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
  10a0ab:	c7 45 d8 80 07 00 00 	movl   $0x780,0xffffffd8(%ebp)
  10a0b2:	eb 18                	jmp    10a0cc <video_putc+0x19c>
			crt_buf[i] = 0x0700 | ' ';
  10a0b4:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  10a0b7:	01 c0                	add    %eax,%eax
  10a0b9:	89 c2                	mov    %eax,%edx
  10a0bb:	a1 20 ed 17 00       	mov    0x17ed20,%eax
  10a0c0:	8d 04 02             	lea    (%edx,%eax,1),%eax
  10a0c3:	66 c7 00 20 07       	movw   $0x720,(%eax)
  10a0c8:	83 45 d8 01          	addl   $0x1,0xffffffd8(%ebp)
  10a0cc:	81 7d d8 cf 07 00 00 	cmpl   $0x7cf,0xffffffd8(%ebp)
  10a0d3:	7e df                	jle    10a0b4 <video_putc+0x184>
		crt_pos -= CRT_COLS;
  10a0d5:	0f b7 05 24 ed 17 00 	movzwl 0x17ed24,%eax
  10a0dc:	83 e8 50             	sub    $0x50,%eax
  10a0df:	66 a3 24 ed 17 00    	mov    %ax,0x17ed24
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
  10a0e5:	a1 1c ed 17 00       	mov    0x17ed1c,%eax
  10a0ea:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)
  10a0ed:	c6 45 df 0e          	movb   $0xe,0xffffffdf(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  10a0f1:	0f b6 45 df          	movzbl 0xffffffdf(%ebp),%eax
  10a0f5:	8b 55 e0             	mov    0xffffffe0(%ebp),%edx
  10a0f8:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
  10a0f9:	0f b7 05 24 ed 17 00 	movzwl 0x17ed24,%eax
  10a100:	66 c1 e8 08          	shr    $0x8,%ax
  10a104:	0f b6 d0             	movzbl %al,%edx
  10a107:	a1 1c ed 17 00       	mov    0x17ed1c,%eax
  10a10c:	83 c0 01             	add    $0x1,%eax
  10a10f:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  10a112:	88 55 e7             	mov    %dl,0xffffffe7(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  10a115:	0f b6 45 e7          	movzbl 0xffffffe7(%ebp),%eax
  10a119:	8b 55 e8             	mov    0xffffffe8(%ebp),%edx
  10a11c:	ee                   	out    %al,(%dx)
	outb(addr_6845, 15);
  10a11d:	a1 1c ed 17 00       	mov    0x17ed1c,%eax
  10a122:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
  10a125:	c6 45 ef 0f          	movb   $0xf,0xffffffef(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  10a129:	0f b6 45 ef          	movzbl 0xffffffef(%ebp),%eax
  10a12d:	8b 55 f0             	mov    0xfffffff0(%ebp),%edx
  10a130:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos);
  10a131:	0f b7 05 24 ed 17 00 	movzwl 0x17ed24,%eax
  10a138:	0f b6 d0             	movzbl %al,%edx
  10a13b:	a1 1c ed 17 00       	mov    0x17ed1c,%eax
  10a140:	83 c0 01             	add    $0x1,%eax
  10a143:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  10a146:	88 55 f7             	mov    %dl,0xfffffff7(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  10a149:	0f b6 45 f7          	movzbl 0xfffffff7(%ebp),%eax
  10a14d:	8b 55 f8             	mov    0xfffffff8(%ebp),%edx
  10a150:	ee                   	out    %al,(%dx)
}
  10a151:	83 c4 44             	add    $0x44,%esp
  10a154:	5b                   	pop    %ebx
  10a155:	5d                   	pop    %ebp
  10a156:	c3                   	ret    
  10a157:	90                   	nop    

0010a158 <kbd_proc_data>:
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
  10a158:	55                   	push   %ebp
  10a159:	89 e5                	mov    %esp,%ebp
  10a15b:	83 ec 38             	sub    $0x38,%esp
  10a15e:	c7 45 ec 64 00 00 00 	movl   $0x64,0xffffffec(%ebp)
static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  10a165:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
  10a168:	ec                   	in     (%dx),%al
  10a169:	88 45 eb             	mov    %al,0xffffffeb(%ebp)
	return data;
  10a16c:	0f b6 45 eb          	movzbl 0xffffffeb(%ebp),%eax
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
  10a170:	0f b6 c0             	movzbl %al,%eax
  10a173:	83 e0 01             	and    $0x1,%eax
  10a176:	85 c0                	test   %eax,%eax
  10a178:	75 0c                	jne    10a186 <kbd_proc_data+0x2e>
		return -1;
  10a17a:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,0xffffffd8(%ebp)
  10a181:	e9 69 01 00 00       	jmp    10a2ef <kbd_proc_data+0x197>
  10a186:	c7 45 f4 60 00 00 00 	movl   $0x60,0xfffffff4(%ebp)
static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  10a18d:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  10a190:	ec                   	in     (%dx),%al
  10a191:	88 45 f3             	mov    %al,0xfffffff3(%ebp)
	return data;
  10a194:	0f b6 45 f3          	movzbl 0xfffffff3(%ebp),%eax

	data = inb(KBDATAP);
  10a198:	88 45 ea             	mov    %al,0xffffffea(%ebp)

	if (data == 0xE0) {
  10a19b:	80 7d ea e0          	cmpb   $0xe0,0xffffffea(%ebp)
  10a19f:	75 19                	jne    10a1ba <kbd_proc_data+0x62>
		// E0 escape character
		shift |= E0ESC;
  10a1a1:	a1 28 ed 17 00       	mov    0x17ed28,%eax
  10a1a6:	83 c8 40             	or     $0x40,%eax
  10a1a9:	a3 28 ed 17 00       	mov    %eax,0x17ed28
		return 0;
  10a1ae:	c7 45 d8 00 00 00 00 	movl   $0x0,0xffffffd8(%ebp)
  10a1b5:	e9 35 01 00 00       	jmp    10a2ef <kbd_proc_data+0x197>
	} else if (data & 0x80) {
  10a1ba:	0f b6 45 ea          	movzbl 0xffffffea(%ebp),%eax
  10a1be:	84 c0                	test   %al,%al
  10a1c0:	79 53                	jns    10a215 <kbd_proc_data+0xbd>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
  10a1c2:	a1 28 ed 17 00       	mov    0x17ed28,%eax
  10a1c7:	83 e0 40             	and    $0x40,%eax
  10a1ca:	85 c0                	test   %eax,%eax
  10a1cc:	75 0c                	jne    10a1da <kbd_proc_data+0x82>
  10a1ce:	0f b6 45 ea          	movzbl 0xffffffea(%ebp),%eax
  10a1d2:	83 e0 7f             	and    $0x7f,%eax
  10a1d5:	88 45 df             	mov    %al,0xffffffdf(%ebp)
  10a1d8:	eb 07                	jmp    10a1e1 <kbd_proc_data+0x89>
  10a1da:	0f b6 45 ea          	movzbl 0xffffffea(%ebp),%eax
  10a1de:	88 45 df             	mov    %al,0xffffffdf(%ebp)
  10a1e1:	0f b6 45 df          	movzbl 0xffffffdf(%ebp),%eax
  10a1e5:	88 45 ea             	mov    %al,0xffffffea(%ebp)
		shift &= ~(shiftcode[data] | E0ESC);
  10a1e8:	0f b6 45 ea          	movzbl 0xffffffea(%ebp),%eax
  10a1ec:	0f b6 80 80 f0 10 00 	movzbl 0x10f080(%eax),%eax
  10a1f3:	83 c8 40             	or     $0x40,%eax
  10a1f6:	0f b6 c0             	movzbl %al,%eax
  10a1f9:	f7 d0                	not    %eax
  10a1fb:	89 c2                	mov    %eax,%edx
  10a1fd:	a1 28 ed 17 00       	mov    0x17ed28,%eax
  10a202:	21 d0                	and    %edx,%eax
  10a204:	a3 28 ed 17 00       	mov    %eax,0x17ed28
		return 0;
  10a209:	c7 45 d8 00 00 00 00 	movl   $0x0,0xffffffd8(%ebp)
  10a210:	e9 da 00 00 00       	jmp    10a2ef <kbd_proc_data+0x197>
	} else if (shift & E0ESC) {
  10a215:	a1 28 ed 17 00       	mov    0x17ed28,%eax
  10a21a:	83 e0 40             	and    $0x40,%eax
  10a21d:	85 c0                	test   %eax,%eax
  10a21f:	74 11                	je     10a232 <kbd_proc_data+0xda>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
  10a221:	80 4d ea 80          	orb    $0x80,0xffffffea(%ebp)
		shift &= ~E0ESC;
  10a225:	a1 28 ed 17 00       	mov    0x17ed28,%eax
  10a22a:	83 e0 bf             	and    $0xffffffbf,%eax
  10a22d:	a3 28 ed 17 00       	mov    %eax,0x17ed28
	}

	shift |= shiftcode[data];
  10a232:	0f b6 45 ea          	movzbl 0xffffffea(%ebp),%eax
  10a236:	0f b6 80 80 f0 10 00 	movzbl 0x10f080(%eax),%eax
  10a23d:	0f b6 d0             	movzbl %al,%edx
  10a240:	a1 28 ed 17 00       	mov    0x17ed28,%eax
  10a245:	09 d0                	or     %edx,%eax
  10a247:	a3 28 ed 17 00       	mov    %eax,0x17ed28
	shift ^= togglecode[data];
  10a24c:	0f b6 45 ea          	movzbl 0xffffffea(%ebp),%eax
  10a250:	0f b6 80 80 f1 10 00 	movzbl 0x10f180(%eax),%eax
  10a257:	0f b6 d0             	movzbl %al,%edx
  10a25a:	a1 28 ed 17 00       	mov    0x17ed28,%eax
  10a25f:	31 d0                	xor    %edx,%eax
  10a261:	a3 28 ed 17 00       	mov    %eax,0x17ed28

	c = charcode[shift & (CTL | SHIFT)][data];
  10a266:	a1 28 ed 17 00       	mov    0x17ed28,%eax
  10a26b:	83 e0 03             	and    $0x3,%eax
  10a26e:	8b 14 85 80 f5 10 00 	mov    0x10f580(,%eax,4),%edx
  10a275:	0f b6 45 ea          	movzbl 0xffffffea(%ebp),%eax
  10a279:	8d 04 02             	lea    (%edx,%eax,1),%eax
  10a27c:	0f b6 00             	movzbl (%eax),%eax
  10a27f:	0f b6 c0             	movzbl %al,%eax
  10a282:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
	if (shift & CAPSLOCK) {
  10a285:	a1 28 ed 17 00       	mov    0x17ed28,%eax
  10a28a:	83 e0 08             	and    $0x8,%eax
  10a28d:	85 c0                	test   %eax,%eax
  10a28f:	74 22                	je     10a2b3 <kbd_proc_data+0x15b>
		if ('a' <= c && c <= 'z')
  10a291:	83 7d e4 60          	cmpl   $0x60,0xffffffe4(%ebp)
  10a295:	7e 0c                	jle    10a2a3 <kbd_proc_data+0x14b>
  10a297:	83 7d e4 7a          	cmpl   $0x7a,0xffffffe4(%ebp)
  10a29b:	7f 06                	jg     10a2a3 <kbd_proc_data+0x14b>
			c += 'A' - 'a';
  10a29d:	83 6d e4 20          	subl   $0x20,0xffffffe4(%ebp)
  10a2a1:	eb 10                	jmp    10a2b3 <kbd_proc_data+0x15b>
		else if ('A' <= c && c <= 'Z')
  10a2a3:	83 7d e4 40          	cmpl   $0x40,0xffffffe4(%ebp)
  10a2a7:	7e 0a                	jle    10a2b3 <kbd_proc_data+0x15b>
  10a2a9:	83 7d e4 5a          	cmpl   $0x5a,0xffffffe4(%ebp)
  10a2ad:	7f 04                	jg     10a2b3 <kbd_proc_data+0x15b>
			c += 'a' - 'A';
  10a2af:	83 45 e4 20          	addl   $0x20,0xffffffe4(%ebp)
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
  10a2b3:	a1 28 ed 17 00       	mov    0x17ed28,%eax
  10a2b8:	f7 d0                	not    %eax
  10a2ba:	83 e0 06             	and    $0x6,%eax
  10a2bd:	85 c0                	test   %eax,%eax
  10a2bf:	75 28                	jne    10a2e9 <kbd_proc_data+0x191>
  10a2c1:	81 7d e4 e9 00 00 00 	cmpl   $0xe9,0xffffffe4(%ebp)
  10a2c8:	75 1f                	jne    10a2e9 <kbd_proc_data+0x191>
		cprintf("Rebooting!\n");
  10a2ca:	c7 04 24 38 db 10 00 	movl   $0x10db38,(%esp)
  10a2d1:	e8 af 11 00 00       	call   10b485 <cprintf>
  10a2d6:	c7 45 fc 92 00 00 00 	movl   $0x92,0xfffffffc(%ebp)
  10a2dd:	c6 45 fb 03          	movb   $0x3,0xfffffffb(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  10a2e1:	0f b6 45 fb          	movzbl 0xfffffffb(%ebp),%eax
  10a2e5:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  10a2e8:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
  10a2e9:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  10a2ec:	89 45 d8             	mov    %eax,0xffffffd8(%ebp)
  10a2ef:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
}
  10a2f2:	c9                   	leave  
  10a2f3:	c3                   	ret    

0010a2f4 <kbd_intr>:

void
kbd_intr(void)
{
  10a2f4:	55                   	push   %ebp
  10a2f5:	89 e5                	mov    %esp,%ebp
  10a2f7:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
  10a2fa:	c7 04 24 58 a1 10 00 	movl   $0x10a158,(%esp)
  10a301:	e8 46 62 ff ff       	call   10054c <cons_intr>
}
  10a306:	c9                   	leave  
  10a307:	c3                   	ret    

0010a308 <kbd_init>:

void
kbd_init(void)
{
  10a308:	55                   	push   %ebp
  10a309:	89 e5                	mov    %esp,%ebp
}
  10a30b:	5d                   	pop    %ebp
  10a30c:	c3                   	ret    

0010a30d <kbd_intenable>:

void
kbd_intenable(void)
{
  10a30d:	55                   	push   %ebp
  10a30e:	89 e5                	mov    %esp,%ebp
  10a310:	83 ec 08             	sub    $0x8,%esp
	// Enable interrupt delivery via the PIC/APIC
	pic_enable(IRQ_KBD);
  10a313:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  10a31a:	e8 a4 03 00 00       	call   10a6c3 <pic_enable>
	ioapic_enable(IRQ_KBD);
  10a31f:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  10a326:	e8 38 09 00 00       	call   10ac63 <ioapic_enable>

	// Drain the kbd buffer so that the hardware generates interrupts.
	kbd_intr();
  10a32b:	e8 c4 ff ff ff       	call   10a2f4 <kbd_intr>
}
  10a330:	c9                   	leave  
  10a331:	c3                   	ret    
  10a332:	90                   	nop    
  10a333:	90                   	nop    

0010a334 <delay>:

// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
  10a334:	55                   	push   %ebp
  10a335:	89 e5                	mov    %esp,%ebp
  10a337:	83 ec 20             	sub    $0x20,%esp
  10a33a:	c7 45 e4 84 00 00 00 	movl   $0x84,0xffffffe4(%ebp)
static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  10a341:	8b 55 e4             	mov    0xffffffe4(%ebp),%edx
  10a344:	ec                   	in     (%dx),%al
  10a345:	88 45 e3             	mov    %al,0xffffffe3(%ebp)
	return data;
  10a348:	c7 45 ec 84 00 00 00 	movl   $0x84,0xffffffec(%ebp)
  10a34f:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
  10a352:	ec                   	in     (%dx),%al
  10a353:	88 45 eb             	mov    %al,0xffffffeb(%ebp)
  10a356:	c7 45 f4 84 00 00 00 	movl   $0x84,0xfffffff4(%ebp)
  10a35d:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  10a360:	ec                   	in     (%dx),%al
  10a361:	88 45 f3             	mov    %al,0xfffffff3(%ebp)
  10a364:	c7 45 fc 84 00 00 00 	movl   $0x84,0xfffffffc(%ebp)
  10a36b:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  10a36e:	ec                   	in     (%dx),%al
  10a36f:	88 45 fb             	mov    %al,0xfffffffb(%ebp)
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
  10a372:	c9                   	leave  
  10a373:	c3                   	ret    

0010a374 <serial_proc_data>:

static int
serial_proc_data(void)
{
  10a374:	55                   	push   %ebp
  10a375:	89 e5                	mov    %esp,%ebp
  10a377:	83 ec 14             	sub    $0x14,%esp
  10a37a:	c7 45 f4 fd 03 00 00 	movl   $0x3fd,0xfffffff4(%ebp)
static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  10a381:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  10a384:	ec                   	in     (%dx),%al
  10a385:	88 45 f3             	mov    %al,0xfffffff3(%ebp)
	return data;
  10a388:	0f b6 45 f3          	movzbl 0xfffffff3(%ebp),%eax
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
  10a38c:	0f b6 c0             	movzbl %al,%eax
  10a38f:	83 e0 01             	and    $0x1,%eax
  10a392:	85 c0                	test   %eax,%eax
  10a394:	75 09                	jne    10a39f <serial_proc_data+0x2b>
		return -1;
  10a396:	c7 45 ec ff ff ff ff 	movl   $0xffffffff,0xffffffec(%ebp)
  10a39d:	eb 18                	jmp    10a3b7 <serial_proc_data+0x43>
  10a39f:	c7 45 fc f8 03 00 00 	movl   $0x3f8,0xfffffffc(%ebp)
static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  10a3a6:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  10a3a9:	ec                   	in     (%dx),%al
  10a3aa:	88 45 fb             	mov    %al,0xfffffffb(%ebp)
	return data;
  10a3ad:	0f b6 45 fb          	movzbl 0xfffffffb(%ebp),%eax
	return inb(COM1+COM_RX);
  10a3b1:	0f b6 c0             	movzbl %al,%eax
  10a3b4:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  10a3b7:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
}
  10a3ba:	c9                   	leave  
  10a3bb:	c3                   	ret    

0010a3bc <serial_intr>:

void
serial_intr(void)
{
  10a3bc:	55                   	push   %ebp
  10a3bd:	89 e5                	mov    %esp,%ebp
  10a3bf:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
  10a3c2:	a1 00 20 18 00       	mov    0x182000,%eax
  10a3c7:	85 c0                	test   %eax,%eax
  10a3c9:	74 0c                	je     10a3d7 <serial_intr+0x1b>
		cons_intr(serial_proc_data);
  10a3cb:	c7 04 24 74 a3 10 00 	movl   $0x10a374,(%esp)
  10a3d2:	e8 75 61 ff ff       	call   10054c <cons_intr>
}
  10a3d7:	c9                   	leave  
  10a3d8:	c3                   	ret    

0010a3d9 <serial_putc>:

void
serial_putc(int c)
{
  10a3d9:	55                   	push   %ebp
  10a3da:	89 e5                	mov    %esp,%ebp
  10a3dc:	83 ec 20             	sub    $0x20,%esp
	if (!serial_exists)
  10a3df:	a1 00 20 18 00       	mov    0x182000,%eax
  10a3e4:	85 c0                	test   %eax,%eax
  10a3e6:	74 4f                	je     10a437 <serial_putc+0x5e>
		return;

	int i;
	for (i = 0;
  10a3e8:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
  10a3ef:	eb 09                	jmp    10a3fa <serial_putc+0x21>
	     i++)
		delay();
  10a3f1:	e8 3e ff ff ff       	call   10a334 <delay>
  10a3f6:	83 45 ec 01          	addl   $0x1,0xffffffec(%ebp)
  10a3fa:	c7 45 f4 fd 03 00 00 	movl   $0x3fd,0xfffffff4(%ebp)
static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  10a401:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  10a404:	ec                   	in     (%dx),%al
  10a405:	88 45 f3             	mov    %al,0xfffffff3(%ebp)
	return data;
  10a408:	0f b6 45 f3          	movzbl 0xfffffff3(%ebp),%eax
  10a40c:	0f b6 c0             	movzbl %al,%eax
  10a40f:	83 e0 20             	and    $0x20,%eax
  10a412:	85 c0                	test   %eax,%eax
  10a414:	75 09                	jne    10a41f <serial_putc+0x46>
  10a416:	81 7d ec ff 31 00 00 	cmpl   $0x31ff,0xffffffec(%ebp)
  10a41d:	7e d2                	jle    10a3f1 <serial_putc+0x18>
	
	outb(COM1 + COM_TX, c);
  10a41f:	8b 45 08             	mov    0x8(%ebp),%eax
  10a422:	0f b6 c0             	movzbl %al,%eax
  10a425:	c7 45 fc f8 03 00 00 	movl   $0x3f8,0xfffffffc(%ebp)
  10a42c:	88 45 fb             	mov    %al,0xfffffffb(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  10a42f:	0f b6 45 fb          	movzbl 0xfffffffb(%ebp),%eax
  10a433:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  10a436:	ee                   	out    %al,(%dx)
}
  10a437:	c9                   	leave  
  10a438:	c3                   	ret    

0010a439 <serial_init>:

void
serial_init(void)
{
  10a439:	55                   	push   %ebp
  10a43a:	89 e5                	mov    %esp,%ebp
  10a43c:	83 ec 50             	sub    $0x50,%esp
  10a43f:	c7 45 b4 fa 03 00 00 	movl   $0x3fa,0xffffffb4(%ebp)
  10a446:	c6 45 b3 00          	movb   $0x0,0xffffffb3(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  10a44a:	0f b6 45 b3          	movzbl 0xffffffb3(%ebp),%eax
  10a44e:	8b 55 b4             	mov    0xffffffb4(%ebp),%edx
  10a451:	ee                   	out    %al,(%dx)
  10a452:	c7 45 bc fb 03 00 00 	movl   $0x3fb,0xffffffbc(%ebp)
  10a459:	c6 45 bb 80          	movb   $0x80,0xffffffbb(%ebp)
  10a45d:	0f b6 45 bb          	movzbl 0xffffffbb(%ebp),%eax
  10a461:	8b 55 bc             	mov    0xffffffbc(%ebp),%edx
  10a464:	ee                   	out    %al,(%dx)
  10a465:	c7 45 c4 f8 03 00 00 	movl   $0x3f8,0xffffffc4(%ebp)
  10a46c:	c6 45 c3 0c          	movb   $0xc,0xffffffc3(%ebp)
  10a470:	0f b6 45 c3          	movzbl 0xffffffc3(%ebp),%eax
  10a474:	8b 55 c4             	mov    0xffffffc4(%ebp),%edx
  10a477:	ee                   	out    %al,(%dx)
  10a478:	c7 45 cc f9 03 00 00 	movl   $0x3f9,0xffffffcc(%ebp)
  10a47f:	c6 45 cb 00          	movb   $0x0,0xffffffcb(%ebp)
  10a483:	0f b6 45 cb          	movzbl 0xffffffcb(%ebp),%eax
  10a487:	8b 55 cc             	mov    0xffffffcc(%ebp),%edx
  10a48a:	ee                   	out    %al,(%dx)
  10a48b:	c7 45 d4 fb 03 00 00 	movl   $0x3fb,0xffffffd4(%ebp)
  10a492:	c6 45 d3 03          	movb   $0x3,0xffffffd3(%ebp)
  10a496:	0f b6 45 d3          	movzbl 0xffffffd3(%ebp),%eax
  10a49a:	8b 55 d4             	mov    0xffffffd4(%ebp),%edx
  10a49d:	ee                   	out    %al,(%dx)
  10a49e:	c7 45 dc fc 03 00 00 	movl   $0x3fc,0xffffffdc(%ebp)
  10a4a5:	c6 45 db 00          	movb   $0x0,0xffffffdb(%ebp)
  10a4a9:	0f b6 45 db          	movzbl 0xffffffdb(%ebp),%eax
  10a4ad:	8b 55 dc             	mov    0xffffffdc(%ebp),%edx
  10a4b0:	ee                   	out    %al,(%dx)
  10a4b1:	c7 45 e4 f9 03 00 00 	movl   $0x3f9,0xffffffe4(%ebp)
  10a4b8:	c6 45 e3 01          	movb   $0x1,0xffffffe3(%ebp)
  10a4bc:	0f b6 45 e3          	movzbl 0xffffffe3(%ebp),%eax
  10a4c0:	8b 55 e4             	mov    0xffffffe4(%ebp),%edx
  10a4c3:	ee                   	out    %al,(%dx)
  10a4c4:	c7 45 ec fd 03 00 00 	movl   $0x3fd,0xffffffec(%ebp)
  10a4cb:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
  10a4ce:	ec                   	in     (%dx),%al
  10a4cf:	88 45 eb             	mov    %al,0xffffffeb(%ebp)
  10a4d2:	0f b6 45 eb          	movzbl 0xffffffeb(%ebp),%eax
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
  10a4d6:	3c ff                	cmp    $0xff,%al
  10a4d8:	0f 95 c0             	setne  %al
  10a4db:	0f b6 c0             	movzbl %al,%eax
  10a4de:	a3 00 20 18 00       	mov    %eax,0x182000
  10a4e3:	c7 45 f4 fa 03 00 00 	movl   $0x3fa,0xfffffff4(%ebp)
static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  10a4ea:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  10a4ed:	ec                   	in     (%dx),%al
  10a4ee:	88 45 f3             	mov    %al,0xfffffff3(%ebp)
	return data;
  10a4f1:	c7 45 fc f8 03 00 00 	movl   $0x3f8,0xfffffffc(%ebp)
  10a4f8:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  10a4fb:	ec                   	in     (%dx),%al
  10a4fc:	88 45 fb             	mov    %al,0xfffffffb(%ebp)
	(void) inb(COM1+COM_IIR);
	(void) inb(COM1+COM_RX);
}
  10a4ff:	c9                   	leave  
  10a500:	c3                   	ret    

0010a501 <serial_intenable>:

void
serial_intenable(void)
{
  10a501:	55                   	push   %ebp
  10a502:	89 e5                	mov    %esp,%ebp
  10a504:	83 ec 08             	sub    $0x8,%esp
	// Enable serial interrupts
	if (serial_exists) {
  10a507:	a1 00 20 18 00       	mov    0x182000,%eax
  10a50c:	85 c0                	test   %eax,%eax
  10a50e:	74 18                	je     10a528 <serial_intenable+0x27>
		pic_enable(IRQ_SERIAL);
  10a510:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
  10a517:	e8 a7 01 00 00       	call   10a6c3 <pic_enable>
		ioapic_enable(IRQ_SERIAL);
  10a51c:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
  10a523:	e8 3b 07 00 00       	call   10ac63 <ioapic_enable>
	}
}
  10a528:	c9                   	leave  
  10a529:	c3                   	ret    
  10a52a:	90                   	nop    
  10a52b:	90                   	nop    

0010a52c <pic_init>:

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
  10a52c:	55                   	push   %ebp
  10a52d:	89 e5                	mov    %esp,%ebp
  10a52f:	83 ec 78             	sub    $0x78,%esp
	if (didinit)		// only do once on bootstrap CPU
  10a532:	a1 2c ed 17 00       	mov    0x17ed2c,%eax
  10a537:	85 c0                	test   %eax,%eax
  10a539:	0f 85 33 01 00 00    	jne    10a672 <pic_init+0x146>
		return;
	didinit = 1;
  10a53f:	c7 05 2c ed 17 00 01 	movl   $0x1,0x17ed2c
  10a546:	00 00 00 
  10a549:	c7 45 94 21 00 00 00 	movl   $0x21,0xffffff94(%ebp)
  10a550:	c6 45 93 ff          	movb   $0xff,0xffffff93(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  10a554:	0f b6 45 93          	movzbl 0xffffff93(%ebp),%eax
  10a558:	8b 55 94             	mov    0xffffff94(%ebp),%edx
  10a55b:	ee                   	out    %al,(%dx)
  10a55c:	c7 45 9c a1 00 00 00 	movl   $0xa1,0xffffff9c(%ebp)
  10a563:	c6 45 9b ff          	movb   $0xff,0xffffff9b(%ebp)
  10a567:	0f b6 45 9b          	movzbl 0xffffff9b(%ebp),%eax
  10a56b:	8b 55 9c             	mov    0xffffff9c(%ebp),%edx
  10a56e:	ee                   	out    %al,(%dx)
  10a56f:	c7 45 a4 20 00 00 00 	movl   $0x20,0xffffffa4(%ebp)
  10a576:	c6 45 a3 11          	movb   $0x11,0xffffffa3(%ebp)
  10a57a:	0f b6 45 a3          	movzbl 0xffffffa3(%ebp),%eax
  10a57e:	8b 55 a4             	mov    0xffffffa4(%ebp),%edx
  10a581:	ee                   	out    %al,(%dx)
  10a582:	c7 45 ac 21 00 00 00 	movl   $0x21,0xffffffac(%ebp)
  10a589:	c6 45 ab 20          	movb   $0x20,0xffffffab(%ebp)
  10a58d:	0f b6 45 ab          	movzbl 0xffffffab(%ebp),%eax
  10a591:	8b 55 ac             	mov    0xffffffac(%ebp),%edx
  10a594:	ee                   	out    %al,(%dx)
  10a595:	c7 45 b4 21 00 00 00 	movl   $0x21,0xffffffb4(%ebp)
  10a59c:	c6 45 b3 04          	movb   $0x4,0xffffffb3(%ebp)
  10a5a0:	0f b6 45 b3          	movzbl 0xffffffb3(%ebp),%eax
  10a5a4:	8b 55 b4             	mov    0xffffffb4(%ebp),%edx
  10a5a7:	ee                   	out    %al,(%dx)
  10a5a8:	c7 45 bc 21 00 00 00 	movl   $0x21,0xffffffbc(%ebp)
  10a5af:	c6 45 bb 03          	movb   $0x3,0xffffffbb(%ebp)
  10a5b3:	0f b6 45 bb          	movzbl 0xffffffbb(%ebp),%eax
  10a5b7:	8b 55 bc             	mov    0xffffffbc(%ebp),%edx
  10a5ba:	ee                   	out    %al,(%dx)
  10a5bb:	c7 45 c4 a0 00 00 00 	movl   $0xa0,0xffffffc4(%ebp)
  10a5c2:	c6 45 c3 11          	movb   $0x11,0xffffffc3(%ebp)
  10a5c6:	0f b6 45 c3          	movzbl 0xffffffc3(%ebp),%eax
  10a5ca:	8b 55 c4             	mov    0xffffffc4(%ebp),%edx
  10a5cd:	ee                   	out    %al,(%dx)
  10a5ce:	c7 45 cc a1 00 00 00 	movl   $0xa1,0xffffffcc(%ebp)
  10a5d5:	c6 45 cb 28          	movb   $0x28,0xffffffcb(%ebp)
  10a5d9:	0f b6 45 cb          	movzbl 0xffffffcb(%ebp),%eax
  10a5dd:	8b 55 cc             	mov    0xffffffcc(%ebp),%edx
  10a5e0:	ee                   	out    %al,(%dx)
  10a5e1:	c7 45 d4 a1 00 00 00 	movl   $0xa1,0xffffffd4(%ebp)
  10a5e8:	c6 45 d3 02          	movb   $0x2,0xffffffd3(%ebp)
  10a5ec:	0f b6 45 d3          	movzbl 0xffffffd3(%ebp),%eax
  10a5f0:	8b 55 d4             	mov    0xffffffd4(%ebp),%edx
  10a5f3:	ee                   	out    %al,(%dx)
  10a5f4:	c7 45 dc a1 00 00 00 	movl   $0xa1,0xffffffdc(%ebp)
  10a5fb:	c6 45 db 01          	movb   $0x1,0xffffffdb(%ebp)
  10a5ff:	0f b6 45 db          	movzbl 0xffffffdb(%ebp),%eax
  10a603:	8b 55 dc             	mov    0xffffffdc(%ebp),%edx
  10a606:	ee                   	out    %al,(%dx)
  10a607:	c7 45 e4 20 00 00 00 	movl   $0x20,0xffffffe4(%ebp)
  10a60e:	c6 45 e3 68          	movb   $0x68,0xffffffe3(%ebp)
  10a612:	0f b6 45 e3          	movzbl 0xffffffe3(%ebp),%eax
  10a616:	8b 55 e4             	mov    0xffffffe4(%ebp),%edx
  10a619:	ee                   	out    %al,(%dx)
  10a61a:	c7 45 ec 20 00 00 00 	movl   $0x20,0xffffffec(%ebp)
  10a621:	c6 45 eb 0a          	movb   $0xa,0xffffffeb(%ebp)
  10a625:	0f b6 45 eb          	movzbl 0xffffffeb(%ebp),%eax
  10a629:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
  10a62c:	ee                   	out    %al,(%dx)
  10a62d:	c7 45 f4 a0 00 00 00 	movl   $0xa0,0xfffffff4(%ebp)
  10a634:	c6 45 f3 68          	movb   $0x68,0xfffffff3(%ebp)
  10a638:	0f b6 45 f3          	movzbl 0xfffffff3(%ebp),%eax
  10a63c:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  10a63f:	ee                   	out    %al,(%dx)
  10a640:	c7 45 fc a0 00 00 00 	movl   $0xa0,0xfffffffc(%ebp)
  10a647:	c6 45 fb 0a          	movb   $0xa,0xfffffffb(%ebp)
  10a64b:	0f b6 45 fb          	movzbl 0xfffffffb(%ebp),%eax
  10a64f:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  10a652:	ee                   	out    %al,(%dx)

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
  10a653:	0f b7 05 90 f5 10 00 	movzwl 0x10f590,%eax
  10a65a:	66 83 f8 ff          	cmp    $0xffffffff,%ax
  10a65e:	74 12                	je     10a672 <pic_init+0x146>
		pic_setmask(irqmask);
  10a660:	0f b7 05 90 f5 10 00 	movzwl 0x10f590,%eax
  10a667:	0f b7 c0             	movzwl %ax,%eax
  10a66a:	89 04 24             	mov    %eax,(%esp)
  10a66d:	e8 02 00 00 00       	call   10a674 <pic_setmask>
}
  10a672:	c9                   	leave  
  10a673:	c3                   	ret    

0010a674 <pic_setmask>:

void
pic_setmask(uint16_t mask)
{
  10a674:	55                   	push   %ebp
  10a675:	89 e5                	mov    %esp,%ebp
  10a677:	83 ec 14             	sub    $0x14,%esp
  10a67a:	8b 45 08             	mov    0x8(%ebp),%eax
  10a67d:	66 89 45 ec          	mov    %ax,0xffffffec(%ebp)
	irqmask = mask;
  10a681:	0f b7 45 ec          	movzwl 0xffffffec(%ebp),%eax
  10a685:	66 a3 90 f5 10 00    	mov    %ax,0x10f590
	outb(IO_PIC1+1, (char)mask);
  10a68b:	0f b7 45 ec          	movzwl 0xffffffec(%ebp),%eax
  10a68f:	0f b6 c0             	movzbl %al,%eax
  10a692:	c7 45 f4 21 00 00 00 	movl   $0x21,0xfffffff4(%ebp)
  10a699:	88 45 f3             	mov    %al,0xfffffff3(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  10a69c:	0f b6 45 f3          	movzbl 0xfffffff3(%ebp),%eax
  10a6a0:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  10a6a3:	ee                   	out    %al,(%dx)
	outb(IO_PIC2+1, (char)(mask >> 8));
  10a6a4:	0f b7 45 ec          	movzwl 0xffffffec(%ebp),%eax
  10a6a8:	66 c1 e8 08          	shr    $0x8,%ax
  10a6ac:	0f b6 c0             	movzbl %al,%eax
  10a6af:	c7 45 fc a1 00 00 00 	movl   $0xa1,0xfffffffc(%ebp)
  10a6b6:	88 45 fb             	mov    %al,0xfffffffb(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  10a6b9:	0f b6 45 fb          	movzbl 0xfffffffb(%ebp),%eax
  10a6bd:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  10a6c0:	ee                   	out    %al,(%dx)
}
  10a6c1:	c9                   	leave  
  10a6c2:	c3                   	ret    

0010a6c3 <pic_enable>:

void
pic_enable(int irq)
{
  10a6c3:	55                   	push   %ebp
  10a6c4:	89 e5                	mov    %esp,%ebp
  10a6c6:	83 ec 04             	sub    $0x4,%esp
	pic_setmask(irqmask & ~(1 << irq));
  10a6c9:	8b 4d 08             	mov    0x8(%ebp),%ecx
  10a6cc:	b8 01 00 00 00       	mov    $0x1,%eax
  10a6d1:	d3 e0                	shl    %cl,%eax
  10a6d3:	89 c2                	mov    %eax,%edx
  10a6d5:	f7 d2                	not    %edx
  10a6d7:	0f b7 05 90 f5 10 00 	movzwl 0x10f590,%eax
  10a6de:	21 d0                	and    %edx,%eax
  10a6e0:	0f b7 c0             	movzwl %ax,%eax
  10a6e3:	89 04 24             	mov    %eax,(%esp)
  10a6e6:	e8 89 ff ff ff       	call   10a674 <pic_setmask>
}
  10a6eb:	c9                   	leave  
  10a6ec:	c3                   	ret    
  10a6ed:	90                   	nop    
  10a6ee:	90                   	nop    
  10a6ef:	90                   	nop    

0010a6f0 <nvram_read>:


unsigned
nvram_read(unsigned reg)
{
  10a6f0:	55                   	push   %ebp
  10a6f1:	89 e5                	mov    %esp,%ebp
  10a6f3:	83 ec 10             	sub    $0x10,%esp
	outb(IO_RTC, reg);
  10a6f6:	8b 45 08             	mov    0x8(%ebp),%eax
  10a6f9:	0f b6 c0             	movzbl %al,%eax
  10a6fc:	c7 45 f4 70 00 00 00 	movl   $0x70,0xfffffff4(%ebp)
  10a703:	88 45 f3             	mov    %al,0xfffffff3(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  10a706:	0f b6 45 f3          	movzbl 0xfffffff3(%ebp),%eax
  10a70a:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  10a70d:	ee                   	out    %al,(%dx)
  10a70e:	c7 45 fc 71 00 00 00 	movl   $0x71,0xfffffffc(%ebp)
  10a715:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  10a718:	ec                   	in     (%dx),%al
  10a719:	88 45 fb             	mov    %al,0xfffffffb(%ebp)
  10a71c:	0f b6 45 fb          	movzbl 0xfffffffb(%ebp),%eax
	return inb(IO_RTC+1);
  10a720:	0f b6 c0             	movzbl %al,%eax
}
  10a723:	c9                   	leave  
  10a724:	c3                   	ret    

0010a725 <nvram_read16>:

unsigned
nvram_read16(unsigned r)
{
  10a725:	55                   	push   %ebp
  10a726:	89 e5                	mov    %esp,%ebp
  10a728:	53                   	push   %ebx
  10a729:	83 ec 04             	sub    $0x4,%esp
	return nvram_read(r) | (nvram_read(r + 1) << 8);
  10a72c:	8b 45 08             	mov    0x8(%ebp),%eax
  10a72f:	89 04 24             	mov    %eax,(%esp)
  10a732:	e8 b9 ff ff ff       	call   10a6f0 <nvram_read>
  10a737:	89 c3                	mov    %eax,%ebx
  10a739:	8b 45 08             	mov    0x8(%ebp),%eax
  10a73c:	83 c0 01             	add    $0x1,%eax
  10a73f:	89 04 24             	mov    %eax,(%esp)
  10a742:	e8 a9 ff ff ff       	call   10a6f0 <nvram_read>
  10a747:	c1 e0 08             	shl    $0x8,%eax
  10a74a:	09 d8                	or     %ebx,%eax
}
  10a74c:	83 c4 04             	add    $0x4,%esp
  10a74f:	5b                   	pop    %ebx
  10a750:	5d                   	pop    %ebp
  10a751:	c3                   	ret    

0010a752 <nvram_write>:

void
nvram_write(unsigned reg, unsigned datum)
{
  10a752:	55                   	push   %ebp
  10a753:	89 e5                	mov    %esp,%ebp
  10a755:	83 ec 10             	sub    $0x10,%esp
	outb(IO_RTC, reg);
  10a758:	8b 45 08             	mov    0x8(%ebp),%eax
  10a75b:	0f b6 c0             	movzbl %al,%eax
  10a75e:	c7 45 f4 70 00 00 00 	movl   $0x70,0xfffffff4(%ebp)
  10a765:	88 45 f3             	mov    %al,0xfffffff3(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  10a768:	0f b6 45 f3          	movzbl 0xfffffff3(%ebp),%eax
  10a76c:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  10a76f:	ee                   	out    %al,(%dx)
	outb(IO_RTC+1, datum);
  10a770:	8b 45 0c             	mov    0xc(%ebp),%eax
  10a773:	0f b6 c0             	movzbl %al,%eax
  10a776:	c7 45 fc 71 00 00 00 	movl   $0x71,0xfffffffc(%ebp)
  10a77d:	88 45 fb             	mov    %al,0xfffffffb(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  10a780:	0f b6 45 fb          	movzbl 0xfffffffb(%ebp),%eax
  10a784:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  10a787:	ee                   	out    %al,(%dx)
}
  10a788:	c9                   	leave  
  10a789:	c3                   	ret    
  10a78a:	90                   	nop    
  10a78b:	90                   	nop    

0010a78c <lapicw>:


static void
lapicw(int index, int value)
{
  10a78c:	55                   	push   %ebp
  10a78d:	89 e5                	mov    %esp,%ebp
	lapic[index] = value;
  10a78f:	8b 45 08             	mov    0x8(%ebp),%eax
  10a792:	c1 e0 02             	shl    $0x2,%eax
  10a795:	89 c2                	mov    %eax,%edx
  10a797:	a1 04 20 18 00       	mov    0x182004,%eax
  10a79c:	01 c2                	add    %eax,%edx
  10a79e:	8b 45 0c             	mov    0xc(%ebp),%eax
  10a7a1:	89 02                	mov    %eax,(%edx)
	lapic[ID];  // wait for write to finish, by reading
  10a7a3:	a1 04 20 18 00       	mov    0x182004,%eax
  10a7a8:	83 c0 20             	add    $0x20,%eax
  10a7ab:	8b 00                	mov    (%eax),%eax
}
  10a7ad:	5d                   	pop    %ebp
  10a7ae:	c3                   	ret    

0010a7af <lapic_init>:

void
lapic_init()
{
  10a7af:	55                   	push   %ebp
  10a7b0:	89 e5                	mov    %esp,%ebp
  10a7b2:	83 ec 08             	sub    $0x8,%esp
	if (!lapic) 
  10a7b5:	a1 04 20 18 00       	mov    0x182004,%eax
  10a7ba:	85 c0                	test   %eax,%eax
  10a7bc:	0f 84 80 01 00 00    	je     10a942 <lapic_init+0x193>
		return;

	// Enable local APIC; set spurious interrupt vector.
	lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
  10a7c2:	c7 44 24 04 27 01 00 	movl   $0x127,0x4(%esp)
  10a7c9:	00 
  10a7ca:	c7 04 24 3c 00 00 00 	movl   $0x3c,(%esp)
  10a7d1:	e8 b6 ff ff ff       	call   10a78c <lapicw>

	// The timer repeatedly counts down at bus frequency
	// from lapic[TICR] and then issues an interrupt.  
	lapicw(TDCR, X1);
  10a7d6:	c7 44 24 04 0b 00 00 	movl   $0xb,0x4(%esp)
  10a7dd:	00 
  10a7de:	c7 04 24 f8 00 00 00 	movl   $0xf8,(%esp)
  10a7e5:	e8 a2 ff ff ff       	call   10a78c <lapicw>
	lapicw(TIMER, PERIODIC | T_LTIMER);
  10a7ea:	c7 44 24 04 31 00 02 	movl   $0x20031,0x4(%esp)
  10a7f1:	00 
  10a7f2:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
  10a7f9:	e8 8e ff ff ff       	call   10a78c <lapicw>

	// If we cared more about precise timekeeping,
	// we would calibrate TICR with another time source such as the PIT.
	lapicw(TICR, 10000000);
  10a7fe:	c7 44 24 04 80 96 98 	movl   $0x989680,0x4(%esp)
  10a805:	00 
  10a806:	c7 04 24 e0 00 00 00 	movl   $0xe0,(%esp)
  10a80d:	e8 7a ff ff ff       	call   10a78c <lapicw>

	// Disable logical interrupt lines.
	lapicw(LINT0, MASKED);
  10a812:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
  10a819:	00 
  10a81a:	c7 04 24 d4 00 00 00 	movl   $0xd4,(%esp)
  10a821:	e8 66 ff ff ff       	call   10a78c <lapicw>
	lapicw(LINT1, MASKED);
  10a826:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
  10a82d:	00 
  10a82e:	c7 04 24 d8 00 00 00 	movl   $0xd8,(%esp)
  10a835:	e8 52 ff ff ff       	call   10a78c <lapicw>

	// Disable performance counter overflow interrupts
	// on machines that provide that interrupt entry.
	if (((lapic[VER]>>16) & 0xFF) >= 4)
  10a83a:	a1 04 20 18 00       	mov    0x182004,%eax
  10a83f:	83 c0 30             	add    $0x30,%eax
  10a842:	8b 00                	mov    (%eax),%eax
  10a844:	c1 e8 10             	shr    $0x10,%eax
  10a847:	25 ff 00 00 00       	and    $0xff,%eax
  10a84c:	83 f8 03             	cmp    $0x3,%eax
  10a84f:	76 14                	jbe    10a865 <lapic_init+0xb6>
		lapicw(PCINT, MASKED);
  10a851:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
  10a858:	00 
  10a859:	c7 04 24 d0 00 00 00 	movl   $0xd0,(%esp)
  10a860:	e8 27 ff ff ff       	call   10a78c <lapicw>

	// Map other interrupts to appropriate vectors.
	lapicw(ERROR, T_LERROR);
  10a865:	c7 44 24 04 32 00 00 	movl   $0x32,0x4(%esp)
  10a86c:	00 
  10a86d:	c7 04 24 dc 00 00 00 	movl   $0xdc,(%esp)
  10a874:	e8 13 ff ff ff       	call   10a78c <lapicw>

	// Set up to lowest-priority, "anycast" interrupts
	lapicw(LDR, 0xff << 24);	// Accept all interrupts
  10a879:	c7 44 24 04 00 00 00 	movl   $0xff000000,0x4(%esp)
  10a880:	ff 
  10a881:	c7 04 24 34 00 00 00 	movl   $0x34,(%esp)
  10a888:	e8 ff fe ff ff       	call   10a78c <lapicw>
	lapicw(DFR, 0xf << 28);		// Flat model
  10a88d:	c7 44 24 04 00 00 00 	movl   $0xf0000000,0x4(%esp)
  10a894:	f0 
  10a895:	c7 04 24 38 00 00 00 	movl   $0x38,(%esp)
  10a89c:	e8 eb fe ff ff       	call   10a78c <lapicw>
	lapicw(TPR, 0x00);		// Task priority 0, no intrs masked
  10a8a1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  10a8a8:	00 
  10a8a9:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  10a8b0:	e8 d7 fe ff ff       	call   10a78c <lapicw>

	// Clear error status register (requires back-to-back writes).
	lapicw(ESR, 0);
  10a8b5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  10a8bc:	00 
  10a8bd:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
  10a8c4:	e8 c3 fe ff ff       	call   10a78c <lapicw>
	lapicw(ESR, 0);
  10a8c9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  10a8d0:	00 
  10a8d1:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
  10a8d8:	e8 af fe ff ff       	call   10a78c <lapicw>

	// Ack any outstanding interrupts.
	lapicw(EOI, 0);
  10a8dd:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  10a8e4:	00 
  10a8e5:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
  10a8ec:	e8 9b fe ff ff       	call   10a78c <lapicw>

	// Send an Init Level De-Assert to synchronise arbitration ID's.
	lapicw(ICRHI, 0);
  10a8f1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  10a8f8:	00 
  10a8f9:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
  10a900:	e8 87 fe ff ff       	call   10a78c <lapicw>
	lapicw(ICRLO, BCAST | INIT | LEVEL);
  10a905:	c7 44 24 04 00 85 08 	movl   $0x88500,0x4(%esp)
  10a90c:	00 
  10a90d:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
  10a914:	e8 73 fe ff ff       	call   10a78c <lapicw>
	while(lapic[ICRLO] & DELIVS)
  10a919:	a1 04 20 18 00       	mov    0x182004,%eax
  10a91e:	05 00 03 00 00       	add    $0x300,%eax
  10a923:	8b 00                	mov    (%eax),%eax
  10a925:	25 00 10 00 00       	and    $0x1000,%eax
  10a92a:	85 c0                	test   %eax,%eax
  10a92c:	75 eb                	jne    10a919 <lapic_init+0x16a>
		;

	// Enable interrupts on the APIC (but not on the processor).
	lapicw(TPR, 0);
  10a92e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  10a935:	00 
  10a936:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  10a93d:	e8 4a fe ff ff       	call   10a78c <lapicw>
}
  10a942:	c9                   	leave  
  10a943:	c3                   	ret    

0010a944 <lapic_eoi>:

// Acknowledge interrupt.
void
lapic_eoi(void)
{
  10a944:	55                   	push   %ebp
  10a945:	89 e5                	mov    %esp,%ebp
  10a947:	83 ec 08             	sub    $0x8,%esp
	if (lapic)
  10a94a:	a1 04 20 18 00       	mov    0x182004,%eax
  10a94f:	85 c0                	test   %eax,%eax
  10a951:	74 14                	je     10a967 <lapic_eoi+0x23>
		lapicw(EOI, 0);
  10a953:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  10a95a:	00 
  10a95b:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
  10a962:	e8 25 fe ff ff       	call   10a78c <lapicw>
}
  10a967:	c9                   	leave  
  10a968:	c3                   	ret    

0010a969 <lapic_errintr>:

void lapic_errintr(void)
{
  10a969:	55                   	push   %ebp
  10a96a:	89 e5                	mov    %esp,%ebp
  10a96c:	53                   	push   %ebx
  10a96d:	83 ec 14             	sub    $0x14,%esp
	lapic_eoi();	// Acknowledge interrupt
  10a970:	e8 cf ff ff ff       	call   10a944 <lapic_eoi>
	lapicw(ESR, 0);	// Trigger update of ESR by writing anything
  10a975:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  10a97c:	00 
  10a97d:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
  10a984:	e8 03 fe ff ff       	call   10a78c <lapicw>
	warn("CPU%d LAPIC error: ESR %x", cpu_cur()->id, lapic[ESR]);
  10a989:	a1 04 20 18 00       	mov    0x182004,%eax
  10a98e:	05 80 02 00 00       	add    $0x280,%eax
  10a993:	8b 18                	mov    (%eax),%ebx
  10a995:	e8 34 00 00 00       	call   10a9ce <cpu_cur>
  10a99a:	0f b6 80 ac 00 00 00 	movzbl 0xac(%eax),%eax
  10a9a1:	0f b6 c0             	movzbl %al,%eax
  10a9a4:	89 5c 24 10          	mov    %ebx,0x10(%esp)
  10a9a8:	89 44 24 0c          	mov    %eax,0xc(%esp)
  10a9ac:	c7 44 24 08 44 db 10 	movl   $0x10db44,0x8(%esp)
  10a9b3:	00 
  10a9b4:	c7 44 24 04 60 00 00 	movl   $0x60,0x4(%esp)
  10a9bb:	00 
  10a9bc:	c7 04 24 5e db 10 00 	movl   $0x10db5e,(%esp)
  10a9c3:	e8 2e 60 ff ff       	call   1009f6 <debug_warn>
}
  10a9c8:	83 c4 14             	add    $0x14,%esp
  10a9cb:	5b                   	pop    %ebx
  10a9cc:	5d                   	pop    %ebp
  10a9cd:	c3                   	ret    

0010a9ce <cpu_cur>:

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  10a9ce:	55                   	push   %ebp
  10a9cf:	89 e5                	mov    %esp,%ebp
  10a9d1:	83 ec 28             	sub    $0x28,%esp
static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  10a9d4:	89 65 fc             	mov    %esp,0xfffffffc(%ebp)
        return esp;
  10a9d7:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  10a9da:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  10a9dd:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10a9e0:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  10a9e5:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	assert(c->magic == CPU_MAGIC);
  10a9e8:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  10a9eb:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  10a9f1:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  10a9f6:	74 24                	je     10aa1c <cpu_cur+0x4e>
  10a9f8:	c7 44 24 0c 6a db 10 	movl   $0x10db6a,0xc(%esp)
  10a9ff:	00 
  10aa00:	c7 44 24 08 80 db 10 	movl   $0x10db80,0x8(%esp)
  10aa07:	00 
  10aa08:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  10aa0f:	00 
  10aa10:	c7 04 24 95 db 10 00 	movl   $0x10db95,(%esp)
  10aa17:	e8 1c 5f ff ff       	call   100938 <debug_panic>
	return c;
  10aa1c:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
}
  10aa1f:	c9                   	leave  
  10aa20:	c3                   	ret    

0010aa21 <microdelay>:

// Spin for a given number of microseconds.
// On real hardware would want to tune this dynamically.
void
microdelay(int us)
{
  10aa21:	55                   	push   %ebp
  10aa22:	89 e5                	mov    %esp,%ebp
}
  10aa24:	5d                   	pop    %ebp
  10aa25:	c3                   	ret    

0010aa26 <lapic_startcpu>:


#define IO_RTC  0x70

// Start additional processor running bootstrap code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapic_startcpu(uint8_t apicid, uint32_t addr)
{
  10aa26:	55                   	push   %ebp
  10aa27:	89 e5                	mov    %esp,%ebp
  10aa29:	83 ec 2c             	sub    $0x2c,%esp
  10aa2c:	8b 45 08             	mov    0x8(%ebp),%eax
  10aa2f:	88 45 dc             	mov    %al,0xffffffdc(%ebp)
  10aa32:	c7 45 f4 70 00 00 00 	movl   $0x70,0xfffffff4(%ebp)
  10aa39:	c6 45 f3 0f          	movb   $0xf,0xfffffff3(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  10aa3d:	0f b6 45 f3          	movzbl 0xfffffff3(%ebp),%eax
  10aa41:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  10aa44:	ee                   	out    %al,(%dx)
  10aa45:	c7 45 fc 71 00 00 00 	movl   $0x71,0xfffffffc(%ebp)
  10aa4c:	c6 45 fb 0a          	movb   $0xa,0xfffffffb(%ebp)
  10aa50:	0f b6 45 fb          	movzbl 0xfffffffb(%ebp),%eax
  10aa54:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  10aa57:	ee                   	out    %al,(%dx)
	int i;
	uint16_t *wrv;

	// "The BSP must initialize CMOS shutdown code to 0AH
	// and the warm reset vector (DWORD based at 40:67) to point at
	// the AP startup code prior to the [universal startup algorithm]."
	outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
	outb(IO_RTC+1, 0x0A);
	wrv = (uint16_t*)(0x40<<4 | 0x67);  // Warm reset vector
  10aa58:	c7 45 ec 67 04 00 00 	movl   $0x467,0xffffffec(%ebp)
	wrv[0] = 0;
  10aa5f:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  10aa62:	66 c7 00 00 00       	movw   $0x0,(%eax)
	wrv[1] = addr >> 4;
  10aa67:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
  10aa6a:	83 c2 02             	add    $0x2,%edx
  10aa6d:	8b 45 0c             	mov    0xc(%ebp),%eax
  10aa70:	c1 e8 04             	shr    $0x4,%eax
  10aa73:	66 89 02             	mov    %ax,(%edx)

	// "Universal startup algorithm."
	// Send INIT (level-triggered) interrupt to reset other CPU.
	lapicw(ICRHI, apicid<<24);
  10aa76:	0f b6 45 dc          	movzbl 0xffffffdc(%ebp),%eax
  10aa7a:	c1 e0 18             	shl    $0x18,%eax
  10aa7d:	89 44 24 04          	mov    %eax,0x4(%esp)
  10aa81:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
  10aa88:	e8 ff fc ff ff       	call   10a78c <lapicw>
	lapicw(ICRLO, INIT | LEVEL | ASSERT);
  10aa8d:	c7 44 24 04 00 c5 00 	movl   $0xc500,0x4(%esp)
  10aa94:	00 
  10aa95:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
  10aa9c:	e8 eb fc ff ff       	call   10a78c <lapicw>
	microdelay(200);
  10aaa1:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
  10aaa8:	e8 74 ff ff ff       	call   10aa21 <microdelay>
	lapicw(ICRLO, INIT | LEVEL);
  10aaad:	c7 44 24 04 00 85 00 	movl   $0x8500,0x4(%esp)
  10aab4:	00 
  10aab5:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
  10aabc:	e8 cb fc ff ff       	call   10a78c <lapicw>
	microdelay(100);    // should be 10ms, but too slow in Bochs!
  10aac1:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
  10aac8:	e8 54 ff ff ff       	call   10aa21 <microdelay>

	// Send startup IPI (twice!) to enter bootstrap code.
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for(i = 0; i < 2; i++){
  10aacd:	c7 45 e8 00 00 00 00 	movl   $0x0,0xffffffe8(%ebp)
  10aad4:	eb 40                	jmp    10ab16 <lapic_startcpu+0xf0>
		lapicw(ICRHI, apicid<<24);
  10aad6:	0f b6 45 dc          	movzbl 0xffffffdc(%ebp),%eax
  10aada:	c1 e0 18             	shl    $0x18,%eax
  10aadd:	89 44 24 04          	mov    %eax,0x4(%esp)
  10aae1:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
  10aae8:	e8 9f fc ff ff       	call   10a78c <lapicw>
		lapicw(ICRLO, STARTUP | (addr>>12));
  10aaed:	8b 45 0c             	mov    0xc(%ebp),%eax
  10aaf0:	c1 e8 0c             	shr    $0xc,%eax
  10aaf3:	80 cc 06             	or     $0x6,%ah
  10aaf6:	89 44 24 04          	mov    %eax,0x4(%esp)
  10aafa:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
  10ab01:	e8 86 fc ff ff       	call   10a78c <lapicw>
		microdelay(200);
  10ab06:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
  10ab0d:	e8 0f ff ff ff       	call   10aa21 <microdelay>
  10ab12:	83 45 e8 01          	addl   $0x1,0xffffffe8(%ebp)
  10ab16:	83 7d e8 01          	cmpl   $0x1,0xffffffe8(%ebp)
  10ab1a:	7e ba                	jle    10aad6 <lapic_startcpu+0xb0>
	}
}
  10ab1c:	c9                   	leave  
  10ab1d:	c3                   	ret    
  10ab1e:	90                   	nop    
  10ab1f:	90                   	nop    

0010ab20 <ioapic_read>:
};

static uint32_t
ioapic_read(int reg)
{
  10ab20:	55                   	push   %ebp
  10ab21:	89 e5                	mov    %esp,%ebp
	ioapic->reg = reg;
  10ab23:	8b 15 e4 ed 17 00    	mov    0x17ede4,%edx
  10ab29:	8b 45 08             	mov    0x8(%ebp),%eax
  10ab2c:	89 02                	mov    %eax,(%edx)
	return ioapic->data;
  10ab2e:	a1 e4 ed 17 00       	mov    0x17ede4,%eax
  10ab33:	8b 40 10             	mov    0x10(%eax),%eax
}
  10ab36:	5d                   	pop    %ebp
  10ab37:	c3                   	ret    

0010ab38 <ioapic_write>:

static void
ioapic_write(int reg, uint32_t data)
{
  10ab38:	55                   	push   %ebp
  10ab39:	89 e5                	mov    %esp,%ebp
	ioapic->reg = reg;
  10ab3b:	8b 15 e4 ed 17 00    	mov    0x17ede4,%edx
  10ab41:	8b 45 08             	mov    0x8(%ebp),%eax
  10ab44:	89 02                	mov    %eax,(%edx)
	ioapic->data = data;
  10ab46:	8b 15 e4 ed 17 00    	mov    0x17ede4,%edx
  10ab4c:	8b 45 0c             	mov    0xc(%ebp),%eax
  10ab4f:	89 42 10             	mov    %eax,0x10(%edx)
}
  10ab52:	5d                   	pop    %ebp
  10ab53:	c3                   	ret    

0010ab54 <ioapic_init>:

void
ioapic_init(void)
{
  10ab54:	55                   	push   %ebp
  10ab55:	89 e5                	mov    %esp,%ebp
  10ab57:	83 ec 28             	sub    $0x28,%esp
	int i, id, maxintr;

	if(!ismp)
  10ab5a:	a1 e8 ed 17 00       	mov    0x17ede8,%eax
  10ab5f:	85 c0                	test   %eax,%eax
  10ab61:	0f 84 fa 00 00 00    	je     10ac61 <ioapic_init+0x10d>
		return;

	if (ioapic == NULL)
  10ab67:	a1 e4 ed 17 00       	mov    0x17ede4,%eax
  10ab6c:	85 c0                	test   %eax,%eax
  10ab6e:	75 0a                	jne    10ab7a <ioapic_init+0x26>
		ioapic = mem_ptr(IOAPIC);	// assume default address
  10ab70:	c7 05 e4 ed 17 00 00 	movl   $0xfec00000,0x17ede4
  10ab77:	00 c0 fe 

	maxintr = (ioapic_read(REG_VER) >> 16) & 0xFF;
  10ab7a:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  10ab81:	e8 9a ff ff ff       	call   10ab20 <ioapic_read>
  10ab86:	c1 e8 10             	shr    $0x10,%eax
  10ab89:	25 ff 00 00 00       	and    $0xff,%eax
  10ab8e:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	id = ioapic_read(REG_ID) >> 24;
  10ab91:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  10ab98:	e8 83 ff ff ff       	call   10ab20 <ioapic_read>
  10ab9d:	c1 e8 18             	shr    $0x18,%eax
  10aba0:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
	if (id == 0) {
  10aba3:	83 7d f8 00          	cmpl   $0x0,0xfffffff8(%ebp)
  10aba7:	75 2a                	jne    10abd3 <ioapic_init+0x7f>
		// I/O APIC ID not initialized yet - have to do it ourselves.
		ioapic_write(REG_ID, ioapicid << 24);
  10aba9:	0f b6 05 e0 ed 17 00 	movzbl 0x17ede0,%eax
  10abb0:	0f b6 c0             	movzbl %al,%eax
  10abb3:	c1 e0 18             	shl    $0x18,%eax
  10abb6:	89 44 24 04          	mov    %eax,0x4(%esp)
  10abba:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  10abc1:	e8 72 ff ff ff       	call   10ab38 <ioapic_write>
		id = ioapicid;
  10abc6:	0f b6 05 e0 ed 17 00 	movzbl 0x17ede0,%eax
  10abcd:	0f b6 c0             	movzbl %al,%eax
  10abd0:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
	}
	if (id != ioapicid)
  10abd3:	0f b6 05 e0 ed 17 00 	movzbl 0x17ede0,%eax
  10abda:	0f b6 c0             	movzbl %al,%eax
  10abdd:	3b 45 f8             	cmp    0xfffffff8(%ebp),%eax
  10abe0:	74 31                	je     10ac13 <ioapic_init+0xbf>
		warn("ioapicinit: id %d != ioapicid %d", id, ioapicid);
  10abe2:	0f b6 05 e0 ed 17 00 	movzbl 0x17ede0,%eax
  10abe9:	0f b6 c0             	movzbl %al,%eax
  10abec:	89 44 24 10          	mov    %eax,0x10(%esp)
  10abf0:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10abf3:	89 44 24 0c          	mov    %eax,0xc(%esp)
  10abf7:	c7 44 24 08 a4 db 10 	movl   $0x10dba4,0x8(%esp)
  10abfe:	00 
  10abff:	c7 44 24 04 53 00 00 	movl   $0x53,0x4(%esp)
  10ac06:	00 
  10ac07:	c7 04 24 c5 db 10 00 	movl   $0x10dbc5,(%esp)
  10ac0e:	e8 e3 5d ff ff       	call   1009f6 <debug_warn>

	// Mark all interrupts edge-triggered, active high, disabled,
	// and not routed to any CPUs.
	for (i = 0; i <= maxintr; i++){
  10ac13:	c7 45 f4 00 00 00 00 	movl   $0x0,0xfffffff4(%ebp)
  10ac1a:	eb 3d                	jmp    10ac59 <ioapic_init+0x105>
		ioapic_write(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
  10ac1c:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  10ac1f:	83 c0 20             	add    $0x20,%eax
  10ac22:	0d 00 00 01 00       	or     $0x10000,%eax
  10ac27:	89 c2                	mov    %eax,%edx
  10ac29:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  10ac2c:	01 c0                	add    %eax,%eax
  10ac2e:	83 c0 10             	add    $0x10,%eax
  10ac31:	89 54 24 04          	mov    %edx,0x4(%esp)
  10ac35:	89 04 24             	mov    %eax,(%esp)
  10ac38:	e8 fb fe ff ff       	call   10ab38 <ioapic_write>
		ioapic_write(REG_TABLE+2*i+1, 0);
  10ac3d:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  10ac40:	01 c0                	add    %eax,%eax
  10ac42:	83 c0 11             	add    $0x11,%eax
  10ac45:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  10ac4c:	00 
  10ac4d:	89 04 24             	mov    %eax,(%esp)
  10ac50:	e8 e3 fe ff ff       	call   10ab38 <ioapic_write>
  10ac55:	83 45 f4 01          	addl   $0x1,0xfffffff4(%ebp)
  10ac59:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  10ac5c:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  10ac5f:	7e bb                	jle    10ac1c <ioapic_init+0xc8>
	}
}
  10ac61:	c9                   	leave  
  10ac62:	c3                   	ret    

0010ac63 <ioapic_enable>:

void
ioapic_enable(int irq)
{
  10ac63:	55                   	push   %ebp
  10ac64:	89 e5                	mov    %esp,%ebp
  10ac66:	83 ec 08             	sub    $0x8,%esp
	if (!ismp)
  10ac69:	a1 e8 ed 17 00       	mov    0x17ede8,%eax
  10ac6e:	85 c0                	test   %eax,%eax
  10ac70:	74 37                	je     10aca9 <ioapic_enable+0x46>
		return;

	// Mark interrupt edge-triggered, active high,
	// enabled, and routed to any CPU.
	ioapic_write(REG_TABLE+2*irq,
  10ac72:	8b 45 08             	mov    0x8(%ebp),%eax
  10ac75:	83 c0 20             	add    $0x20,%eax
  10ac78:	80 cc 09             	or     $0x9,%ah
  10ac7b:	89 c2                	mov    %eax,%edx
  10ac7d:	8b 45 08             	mov    0x8(%ebp),%eax
  10ac80:	01 c0                	add    %eax,%eax
  10ac82:	83 c0 10             	add    $0x10,%eax
  10ac85:	89 54 24 04          	mov    %edx,0x4(%esp)
  10ac89:	89 04 24             	mov    %eax,(%esp)
  10ac8c:	e8 a7 fe ff ff       	call   10ab38 <ioapic_write>
			INT_LOGICAL | INT_LOWEST | (T_IRQ0 + irq));
	ioapic_write(REG_TABLE+2*irq+1, 0xff << 24);
  10ac91:	8b 45 08             	mov    0x8(%ebp),%eax
  10ac94:	01 c0                	add    %eax,%eax
  10ac96:	83 c0 11             	add    $0x11,%eax
  10ac99:	c7 44 24 04 00 00 00 	movl   $0xff000000,0x4(%esp)
  10aca0:	ff 
  10aca1:	89 04 24             	mov    %eax,(%esp)
  10aca4:	e8 8f fe ff ff       	call   10ab38 <ioapic_write>
}
  10aca9:	c9                   	leave  
  10acaa:	c3                   	ret    
  10acab:	90                   	nop    

0010acac <getuint>:
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static uintmax_t
getuint(printstate *st, va_list *ap)
{
  10acac:	55                   	push   %ebp
  10acad:	89 e5                	mov    %esp,%ebp
  10acaf:	83 ec 08             	sub    $0x8,%esp
	if (st->flags & F_LL)
  10acb2:	8b 45 08             	mov    0x8(%ebp),%eax
  10acb5:	8b 40 18             	mov    0x18(%eax),%eax
  10acb8:	83 e0 02             	and    $0x2,%eax
  10acbb:	85 c0                	test   %eax,%eax
  10acbd:	74 22                	je     10ace1 <getuint+0x35>
		return va_arg(*ap, unsigned long long);
  10acbf:	8b 45 0c             	mov    0xc(%ebp),%eax
  10acc2:	8b 00                	mov    (%eax),%eax
  10acc4:	8d 50 08             	lea    0x8(%eax),%edx
  10acc7:	8b 45 0c             	mov    0xc(%ebp),%eax
  10acca:	89 10                	mov    %edx,(%eax)
  10accc:	8b 45 0c             	mov    0xc(%ebp),%eax
  10accf:	8b 00                	mov    (%eax),%eax
  10acd1:	83 e8 08             	sub    $0x8,%eax
  10acd4:	8b 10                	mov    (%eax),%edx
  10acd6:	8b 48 04             	mov    0x4(%eax),%ecx
  10acd9:	89 55 f8             	mov    %edx,0xfffffff8(%ebp)
  10acdc:	89 4d fc             	mov    %ecx,0xfffffffc(%ebp)
  10acdf:	eb 51                	jmp    10ad32 <getuint+0x86>
	else if (st->flags & F_L)
  10ace1:	8b 45 08             	mov    0x8(%ebp),%eax
  10ace4:	8b 40 18             	mov    0x18(%eax),%eax
  10ace7:	83 e0 01             	and    $0x1,%eax
  10acea:	84 c0                	test   %al,%al
  10acec:	74 23                	je     10ad11 <getuint+0x65>
		return va_arg(*ap, unsigned long);
  10acee:	8b 45 0c             	mov    0xc(%ebp),%eax
  10acf1:	8b 00                	mov    (%eax),%eax
  10acf3:	8d 50 04             	lea    0x4(%eax),%edx
  10acf6:	8b 45 0c             	mov    0xc(%ebp),%eax
  10acf9:	89 10                	mov    %edx,(%eax)
  10acfb:	8b 45 0c             	mov    0xc(%ebp),%eax
  10acfe:	8b 00                	mov    (%eax),%eax
  10ad00:	83 e8 04             	sub    $0x4,%eax
  10ad03:	8b 00                	mov    (%eax),%eax
  10ad05:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  10ad08:	c7 45 fc 00 00 00 00 	movl   $0x0,0xfffffffc(%ebp)
  10ad0f:	eb 21                	jmp    10ad32 <getuint+0x86>
	else
		return va_arg(*ap, unsigned int);
  10ad11:	8b 45 0c             	mov    0xc(%ebp),%eax
  10ad14:	8b 00                	mov    (%eax),%eax
  10ad16:	8d 50 04             	lea    0x4(%eax),%edx
  10ad19:	8b 45 0c             	mov    0xc(%ebp),%eax
  10ad1c:	89 10                	mov    %edx,(%eax)
  10ad1e:	8b 45 0c             	mov    0xc(%ebp),%eax
  10ad21:	8b 00                	mov    (%eax),%eax
  10ad23:	83 e8 04             	sub    $0x4,%eax
  10ad26:	8b 00                	mov    (%eax),%eax
  10ad28:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  10ad2b:	c7 45 fc 00 00 00 00 	movl   $0x0,0xfffffffc(%ebp)
  10ad32:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10ad35:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
}
  10ad38:	c9                   	leave  
  10ad39:	c3                   	ret    

0010ad3a <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static intmax_t
getint(printstate *st, va_list *ap)
{
  10ad3a:	55                   	push   %ebp
  10ad3b:	89 e5                	mov    %esp,%ebp
  10ad3d:	83 ec 08             	sub    $0x8,%esp
	if (st->flags & F_LL)
  10ad40:	8b 45 08             	mov    0x8(%ebp),%eax
  10ad43:	8b 40 18             	mov    0x18(%eax),%eax
  10ad46:	83 e0 02             	and    $0x2,%eax
  10ad49:	85 c0                	test   %eax,%eax
  10ad4b:	74 22                	je     10ad6f <getint+0x35>
		return va_arg(*ap, long long);
  10ad4d:	8b 45 0c             	mov    0xc(%ebp),%eax
  10ad50:	8b 00                	mov    (%eax),%eax
  10ad52:	8d 50 08             	lea    0x8(%eax),%edx
  10ad55:	8b 45 0c             	mov    0xc(%ebp),%eax
  10ad58:	89 10                	mov    %edx,(%eax)
  10ad5a:	8b 45 0c             	mov    0xc(%ebp),%eax
  10ad5d:	8b 00                	mov    (%eax),%eax
  10ad5f:	83 e8 08             	sub    $0x8,%eax
  10ad62:	8b 10                	mov    (%eax),%edx
  10ad64:	8b 48 04             	mov    0x4(%eax),%ecx
  10ad67:	89 55 f8             	mov    %edx,0xfffffff8(%ebp)
  10ad6a:	89 4d fc             	mov    %ecx,0xfffffffc(%ebp)
  10ad6d:	eb 53                	jmp    10adc2 <getint+0x88>
	else if (st->flags & F_L)
  10ad6f:	8b 45 08             	mov    0x8(%ebp),%eax
  10ad72:	8b 40 18             	mov    0x18(%eax),%eax
  10ad75:	83 e0 01             	and    $0x1,%eax
  10ad78:	84 c0                	test   %al,%al
  10ad7a:	74 24                	je     10ada0 <getint+0x66>
		return va_arg(*ap, long);
  10ad7c:	8b 45 0c             	mov    0xc(%ebp),%eax
  10ad7f:	8b 00                	mov    (%eax),%eax
  10ad81:	8d 50 04             	lea    0x4(%eax),%edx
  10ad84:	8b 45 0c             	mov    0xc(%ebp),%eax
  10ad87:	89 10                	mov    %edx,(%eax)
  10ad89:	8b 45 0c             	mov    0xc(%ebp),%eax
  10ad8c:	8b 00                	mov    (%eax),%eax
  10ad8e:	83 e8 04             	sub    $0x4,%eax
  10ad91:	8b 00                	mov    (%eax),%eax
  10ad93:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  10ad96:	89 c1                	mov    %eax,%ecx
  10ad98:	c1 f9 1f             	sar    $0x1f,%ecx
  10ad9b:	89 4d fc             	mov    %ecx,0xfffffffc(%ebp)
  10ad9e:	eb 22                	jmp    10adc2 <getint+0x88>
	else
		return va_arg(*ap, int);
  10ada0:	8b 45 0c             	mov    0xc(%ebp),%eax
  10ada3:	8b 00                	mov    (%eax),%eax
  10ada5:	8d 50 04             	lea    0x4(%eax),%edx
  10ada8:	8b 45 0c             	mov    0xc(%ebp),%eax
  10adab:	89 10                	mov    %edx,(%eax)
  10adad:	8b 45 0c             	mov    0xc(%ebp),%eax
  10adb0:	8b 00                	mov    (%eax),%eax
  10adb2:	83 e8 04             	sub    $0x4,%eax
  10adb5:	8b 00                	mov    (%eax),%eax
  10adb7:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  10adba:	89 c2                	mov    %eax,%edx
  10adbc:	c1 fa 1f             	sar    $0x1f,%edx
  10adbf:	89 55 fc             	mov    %edx,0xfffffffc(%ebp)
  10adc2:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10adc5:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
}
  10adc8:	c9                   	leave  
  10adc9:	c3                   	ret    

0010adca <putpad>:

// Print padding characters, and an optional sign before a number.
static void
putpad(printstate *st)
{
  10adca:	55                   	push   %ebp
  10adcb:	89 e5                	mov    %esp,%ebp
  10adcd:	83 ec 08             	sub    $0x8,%esp
	while (--st->width >= 0)
  10add0:	eb 1a                	jmp    10adec <putpad+0x22>
		st->putch(st->padc, st->putdat);
  10add2:	8b 45 08             	mov    0x8(%ebp),%eax
  10add5:	8b 08                	mov    (%eax),%ecx
  10add7:	8b 45 08             	mov    0x8(%ebp),%eax
  10adda:	8b 50 04             	mov    0x4(%eax),%edx
  10addd:	8b 45 08             	mov    0x8(%ebp),%eax
  10ade0:	8b 40 08             	mov    0x8(%eax),%eax
  10ade3:	89 54 24 04          	mov    %edx,0x4(%esp)
  10ade7:	89 04 24             	mov    %eax,(%esp)
  10adea:	ff d1                	call   *%ecx
  10adec:	8b 45 08             	mov    0x8(%ebp),%eax
  10adef:	8b 40 0c             	mov    0xc(%eax),%eax
  10adf2:	8d 50 ff             	lea    0xffffffff(%eax),%edx
  10adf5:	8b 45 08             	mov    0x8(%ebp),%eax
  10adf8:	89 50 0c             	mov    %edx,0xc(%eax)
  10adfb:	8b 45 08             	mov    0x8(%ebp),%eax
  10adfe:	8b 40 0c             	mov    0xc(%eax),%eax
  10ae01:	85 c0                	test   %eax,%eax
  10ae03:	79 cd                	jns    10add2 <putpad+0x8>
}
  10ae05:	c9                   	leave  
  10ae06:	c3                   	ret    

0010ae07 <putstr>:

// Print a string with a specified maximum length (-1=unlimited),
// with any appropriate left or right field padding.
static void
putstr(printstate *st, const char *str, int maxlen)
{
  10ae07:	55                   	push   %ebp
  10ae08:	89 e5                	mov    %esp,%ebp
  10ae0a:	53                   	push   %ebx
  10ae0b:	83 ec 24             	sub    $0x24,%esp
	const char *lim;		// find where the string actually ends
	if (maxlen < 0)
  10ae0e:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  10ae12:	79 18                	jns    10ae2c <putstr+0x25>
		lim = strchr(str, 0);	// find the terminating null
  10ae14:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  10ae1b:	00 
  10ae1c:	8b 45 0c             	mov    0xc(%ebp),%eax
  10ae1f:	89 04 24             	mov    %eax,(%esp)
  10ae22:	e8 a2 09 00 00       	call   10b7c9 <strchr>
  10ae27:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
  10ae2a:	eb 2c                	jmp    10ae58 <putstr+0x51>
	else if ((lim = memchr(str, 0, maxlen)) == NULL)
  10ae2c:	8b 45 10             	mov    0x10(%ebp),%eax
  10ae2f:	89 44 24 08          	mov    %eax,0x8(%esp)
  10ae33:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  10ae3a:	00 
  10ae3b:	8b 45 0c             	mov    0xc(%ebp),%eax
  10ae3e:	89 04 24             	mov    %eax,(%esp)
  10ae41:	e8 80 0b 00 00       	call   10b9c6 <memchr>
  10ae46:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
  10ae49:	83 7d f4 00          	cmpl   $0x0,0xfffffff4(%ebp)
  10ae4d:	75 09                	jne    10ae58 <putstr+0x51>
		lim = str + maxlen;
  10ae4f:	8b 45 10             	mov    0x10(%ebp),%eax
  10ae52:	03 45 0c             	add    0xc(%ebp),%eax
  10ae55:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	st->width -= (lim-str);		// deduct string length from field width
  10ae58:	8b 45 08             	mov    0x8(%ebp),%eax
  10ae5b:	8b 48 0c             	mov    0xc(%eax),%ecx
  10ae5e:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  10ae61:	8b 45 0c             	mov    0xc(%ebp),%eax
  10ae64:	89 d3                	mov    %edx,%ebx
  10ae66:	29 c3                	sub    %eax,%ebx
  10ae68:	89 d8                	mov    %ebx,%eax
  10ae6a:	89 ca                	mov    %ecx,%edx
  10ae6c:	29 c2                	sub    %eax,%edx
  10ae6e:	8b 45 08             	mov    0x8(%ebp),%eax
  10ae71:	89 50 0c             	mov    %edx,0xc(%eax)

	if (!(st->flags & F_RPAD))	// print left-side padding
  10ae74:	8b 45 08             	mov    0x8(%ebp),%eax
  10ae77:	8b 40 18             	mov    0x18(%eax),%eax
  10ae7a:	83 e0 10             	and    $0x10,%eax
  10ae7d:	85 c0                	test   %eax,%eax
  10ae7f:	75 32                	jne    10aeb3 <putstr+0xac>
		putpad(st);		// (also leaves st->width == 0)
  10ae81:	8b 45 08             	mov    0x8(%ebp),%eax
  10ae84:	89 04 24             	mov    %eax,(%esp)
  10ae87:	e8 3e ff ff ff       	call   10adca <putpad>
	while (str < lim) {
  10ae8c:	eb 25                	jmp    10aeb3 <putstr+0xac>
		char ch = *str++;
  10ae8e:	8b 45 0c             	mov    0xc(%ebp),%eax
  10ae91:	0f b6 00             	movzbl (%eax),%eax
  10ae94:	88 45 fb             	mov    %al,0xfffffffb(%ebp)
  10ae97:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
			st->putch(ch, st->putdat);
  10ae9b:	8b 45 08             	mov    0x8(%ebp),%eax
  10ae9e:	8b 08                	mov    (%eax),%ecx
  10aea0:	8b 45 08             	mov    0x8(%ebp),%eax
  10aea3:	8b 40 04             	mov    0x4(%eax),%eax
  10aea6:	0f be 55 fb          	movsbl 0xfffffffb(%ebp),%edx
  10aeaa:	89 44 24 04          	mov    %eax,0x4(%esp)
  10aeae:	89 14 24             	mov    %edx,(%esp)
  10aeb1:	ff d1                	call   *%ecx
  10aeb3:	8b 45 0c             	mov    0xc(%ebp),%eax
  10aeb6:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  10aeb9:	72 d3                	jb     10ae8e <putstr+0x87>
	}
	putpad(st);			// print right-side padding
  10aebb:	8b 45 08             	mov    0x8(%ebp),%eax
  10aebe:	89 04 24             	mov    %eax,(%esp)
  10aec1:	e8 04 ff ff ff       	call   10adca <putpad>
}
  10aec6:	83 c4 24             	add    $0x24,%esp
  10aec9:	5b                   	pop    %ebx
  10aeca:	5d                   	pop    %ebp
  10aecb:	c3                   	ret    

0010aecc <genint>:

// Generate a number (base <= 16) in reverse order into a string buffer.
static char *
genint(printstate *st, char *p, uintmax_t num)
{
  10aecc:	55                   	push   %ebp
  10aecd:	89 e5                	mov    %esp,%ebp
  10aecf:	53                   	push   %ebx
  10aed0:	83 ec 24             	sub    $0x24,%esp
  10aed3:	8b 45 10             	mov    0x10(%ebp),%eax
  10aed6:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
  10aed9:	8b 45 14             	mov    0x14(%ebp),%eax
  10aedc:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= st->base)
  10aedf:	8b 45 08             	mov    0x8(%ebp),%eax
  10aee2:	8b 40 1c             	mov    0x1c(%eax),%eax
  10aee5:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  10aee8:	89 c2                	mov    %eax,%edx
  10aeea:	c1 fa 1f             	sar    $0x1f,%edx
  10aeed:	89 55 ec             	mov    %edx,0xffffffec(%ebp)
  10aef0:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  10aef3:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  10aef6:	77 54                	ja     10af4c <genint+0x80>
  10aef8:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
  10aefb:	3b 55 f4             	cmp    0xfffffff4(%ebp),%edx
  10aefe:	72 08                	jb     10af08 <genint+0x3c>
  10af00:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  10af03:	3b 45 f0             	cmp    0xfffffff0(%ebp),%eax
  10af06:	77 44                	ja     10af4c <genint+0x80>
		p = genint(st, p, num / st->base);	// output higher digits
  10af08:	8b 45 08             	mov    0x8(%ebp),%eax
  10af0b:	8b 40 1c             	mov    0x1c(%eax),%eax
  10af0e:	89 c2                	mov    %eax,%edx
  10af10:	c1 fa 1f             	sar    $0x1f,%edx
  10af13:	89 44 24 08          	mov    %eax,0x8(%esp)
  10af17:	89 54 24 0c          	mov    %edx,0xc(%esp)
  10af1b:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  10af1e:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  10af21:	89 04 24             	mov    %eax,(%esp)
  10af24:	89 54 24 04          	mov    %edx,0x4(%esp)
  10af28:	e8 e3 0a 00 00       	call   10ba10 <__udivdi3>
  10af2d:	89 44 24 08          	mov    %eax,0x8(%esp)
  10af31:	89 54 24 0c          	mov    %edx,0xc(%esp)
  10af35:	8b 45 0c             	mov    0xc(%ebp),%eax
  10af38:	89 44 24 04          	mov    %eax,0x4(%esp)
  10af3c:	8b 45 08             	mov    0x8(%ebp),%eax
  10af3f:	89 04 24             	mov    %eax,(%esp)
  10af42:	e8 85 ff ff ff       	call   10aecc <genint>
  10af47:	89 45 0c             	mov    %eax,0xc(%ebp)
  10af4a:	eb 1b                	jmp    10af67 <genint+0x9b>
	else if (st->signc >= 0)
  10af4c:	8b 45 08             	mov    0x8(%ebp),%eax
  10af4f:	8b 40 14             	mov    0x14(%eax),%eax
  10af52:	85 c0                	test   %eax,%eax
  10af54:	78 11                	js     10af67 <genint+0x9b>
		*p++ = st->signc;			// output leading sign
  10af56:	8b 45 08             	mov    0x8(%ebp),%eax
  10af59:	8b 40 14             	mov    0x14(%eax),%eax
  10af5c:	89 c2                	mov    %eax,%edx
  10af5e:	8b 45 0c             	mov    0xc(%ebp),%eax
  10af61:	88 10                	mov    %dl,(%eax)
  10af63:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
	*p++ = "0123456789abcdef"[num % st->base];	// output this digit
  10af67:	8b 45 08             	mov    0x8(%ebp),%eax
  10af6a:	8b 40 1c             	mov    0x1c(%eax),%eax
  10af6d:	89 c2                	mov    %eax,%edx
  10af6f:	c1 fa 1f             	sar    $0x1f,%edx
  10af72:	8b 4d f0             	mov    0xfffffff0(%ebp),%ecx
  10af75:	8b 5d f4             	mov    0xfffffff4(%ebp),%ebx
  10af78:	89 44 24 08          	mov    %eax,0x8(%esp)
  10af7c:	89 54 24 0c          	mov    %edx,0xc(%esp)
  10af80:	89 0c 24             	mov    %ecx,(%esp)
  10af83:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  10af87:	e8 b4 0b 00 00       	call   10bb40 <__umoddi3>
  10af8c:	05 d4 db 10 00       	add    $0x10dbd4,%eax
  10af91:	0f b6 10             	movzbl (%eax),%edx
  10af94:	8b 45 0c             	mov    0xc(%ebp),%eax
  10af97:	88 10                	mov    %dl,(%eax)
  10af99:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
	return p;
  10af9d:	8b 45 0c             	mov    0xc(%ebp),%eax
}
  10afa0:	83 c4 24             	add    $0x24,%esp
  10afa3:	5b                   	pop    %ebx
  10afa4:	5d                   	pop    %ebp
  10afa5:	c3                   	ret    

0010afa6 <putint>:

// Print an integer with any appropriate field padding.
static void
putint(printstate *st, uintmax_t num, int base)
{
  10afa6:	55                   	push   %ebp
  10afa7:	89 e5                	mov    %esp,%ebp
  10afa9:	83 ec 48             	sub    $0x48,%esp
  10afac:	8b 45 0c             	mov    0xc(%ebp),%eax
  10afaf:	89 45 c8             	mov    %eax,0xffffffc8(%ebp)
  10afb2:	8b 45 10             	mov    0x10(%ebp),%eax
  10afb5:	89 45 cc             	mov    %eax,0xffffffcc(%ebp)
	char buf[30], *p = buf;		// big enough for any 64-bit int in octal
  10afb8:	8d 45 de             	lea    0xffffffde(%ebp),%eax
  10afbb:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	st->base = base;		// select base for genint
  10afbe:	8b 55 08             	mov    0x8(%ebp),%edx
  10afc1:	8b 45 14             	mov    0x14(%ebp),%eax
  10afc4:	89 42 1c             	mov    %eax,0x1c(%edx)
	p = genint(st, p, num);		// output to the string buffer
  10afc7:	8b 45 c8             	mov    0xffffffc8(%ebp),%eax
  10afca:	8b 55 cc             	mov    0xffffffcc(%ebp),%edx
  10afcd:	89 44 24 08          	mov    %eax,0x8(%esp)
  10afd1:	89 54 24 0c          	mov    %edx,0xc(%esp)
  10afd5:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  10afd8:	89 44 24 04          	mov    %eax,0x4(%esp)
  10afdc:	8b 45 08             	mov    0x8(%ebp),%eax
  10afdf:	89 04 24             	mov    %eax,(%esp)
  10afe2:	e8 e5 fe ff ff       	call   10aecc <genint>
  10afe7:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	putstr(st, buf, p-buf);		// print it with left/right padding
  10afea:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  10afed:	8d 45 de             	lea    0xffffffde(%ebp),%eax
  10aff0:	89 d1                	mov    %edx,%ecx
  10aff2:	29 c1                	sub    %eax,%ecx
  10aff4:	89 c8                	mov    %ecx,%eax
  10aff6:	89 44 24 08          	mov    %eax,0x8(%esp)
  10affa:	8d 45 de             	lea    0xffffffde(%ebp),%eax
  10affd:	89 44 24 04          	mov    %eax,0x4(%esp)
  10b001:	8b 45 08             	mov    0x8(%ebp),%eax
  10b004:	89 04 24             	mov    %eax,(%esp)
  10b007:	e8 fb fd ff ff       	call   10ae07 <putstr>
}
  10b00c:	c9                   	leave  
  10b00d:	c3                   	ret    

0010b00e <vprintfmt>:
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
  10b00e:	55                   	push   %ebp
  10b00f:	89 e5                	mov    %esp,%ebp
  10b011:	57                   	push   %edi
  10b012:	83 ec 54             	sub    $0x54,%esp
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
  10b015:	8d 7d c8             	lea    0xffffffc8(%ebp),%edi
  10b018:	fc                   	cld    
  10b019:	ba 00 00 00 00       	mov    $0x0,%edx
  10b01e:	b8 08 00 00 00       	mov    $0x8,%eax
  10b023:	89 c1                	mov    %eax,%ecx
  10b025:	89 d0                	mov    %edx,%eax
  10b027:	f3 ab                	rep stos %eax,%es:(%edi)
  10b029:	8b 45 08             	mov    0x8(%ebp),%eax
  10b02c:	89 45 c8             	mov    %eax,0xffffffc8(%ebp)
  10b02f:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b032:	89 45 cc             	mov    %eax,0xffffffcc(%ebp)
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  10b035:	eb 1c                	jmp    10b053 <vprintfmt+0x45>
			if (ch == '\0')
  10b037:	83 7d c4 00          	cmpl   $0x0,0xffffffc4(%ebp)
  10b03b:	0f 84 73 03 00 00    	je     10b3b4 <vprintfmt+0x3a6>
				return;
			putch(ch, putdat);
  10b041:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b044:	89 44 24 04          	mov    %eax,0x4(%esp)
  10b048:	8b 55 c4             	mov    0xffffffc4(%ebp),%edx
  10b04b:	89 14 24             	mov    %edx,(%esp)
  10b04e:	8b 45 08             	mov    0x8(%ebp),%eax
  10b051:	ff d0                	call   *%eax
  10b053:	8b 45 10             	mov    0x10(%ebp),%eax
  10b056:	0f b6 00             	movzbl (%eax),%eax
  10b059:	0f b6 c0             	movzbl %al,%eax
  10b05c:	89 45 c4             	mov    %eax,0xffffffc4(%ebp)
  10b05f:	83 7d c4 25          	cmpl   $0x25,0xffffffc4(%ebp)
  10b063:	0f 95 c0             	setne  %al
  10b066:	83 45 10 01          	addl   $0x1,0x10(%ebp)
  10b06a:	84 c0                	test   %al,%al
  10b06c:	75 c9                	jne    10b037 <vprintfmt+0x29>
		}

		// Process a %-escape sequence
		st.padc = ' ';
  10b06e:	c7 45 d0 20 00 00 00 	movl   $0x20,0xffffffd0(%ebp)
		st.width = -1;
  10b075:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,0xffffffd4(%ebp)
		st.prec = -1;
  10b07c:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,0xffffffd8(%ebp)
		st.signc = -1;
  10b083:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,0xffffffdc(%ebp)
		st.flags = 0;
  10b08a:	c7 45 e0 00 00 00 00 	movl   $0x0,0xffffffe0(%ebp)
		st.base = 10;
  10b091:	c7 45 e4 0a 00 00 00 	movl   $0xa,0xffffffe4(%ebp)
  10b098:	eb 00                	jmp    10b09a <vprintfmt+0x8c>
		uintmax_t num;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  10b09a:	8b 45 10             	mov    0x10(%ebp),%eax
  10b09d:	0f b6 00             	movzbl (%eax),%eax
  10b0a0:	0f b6 c0             	movzbl %al,%eax
  10b0a3:	89 45 c4             	mov    %eax,0xffffffc4(%ebp)
  10b0a6:	8b 45 c4             	mov    0xffffffc4(%ebp),%eax
  10b0a9:	83 45 10 01          	addl   $0x1,0x10(%ebp)
  10b0ad:	83 e8 20             	sub    $0x20,%eax
  10b0b0:	89 45 b8             	mov    %eax,0xffffffb8(%ebp)
  10b0b3:	83 7d b8 58          	cmpl   $0x58,0xffffffb8(%ebp)
  10b0b7:	0f 87 c8 02 00 00    	ja     10b385 <vprintfmt+0x377>
  10b0bd:	8b 55 b8             	mov    0xffffffb8(%ebp),%edx
  10b0c0:	8b 04 95 ec db 10 00 	mov    0x10dbec(,%edx,4),%eax
  10b0c7:	ff e0                	jmp    *%eax

		// modifier flags
		case '-': // pad on the right instead of the left
			st.flags |= F_RPAD;
  10b0c9:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  10b0cc:	83 c8 10             	or     $0x10,%eax
  10b0cf:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)
			goto reswitch;
  10b0d2:	eb c6                	jmp    10b09a <vprintfmt+0x8c>

		case '+': // prefix positive numeric values with a '+' sign
			st.signc = '+';
  10b0d4:	c7 45 dc 2b 00 00 00 	movl   $0x2b,0xffffffdc(%ebp)
			goto reswitch;
  10b0db:	eb bd                	jmp    10b09a <vprintfmt+0x8c>

		case ' ': // prefix signless numeric values with a space
			if (st.signc < 0)	// (but only if no '+' is specified)
  10b0dd:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  10b0e0:	85 c0                	test   %eax,%eax
  10b0e2:	79 b6                	jns    10b09a <vprintfmt+0x8c>
				st.signc = ' ';
  10b0e4:	c7 45 dc 20 00 00 00 	movl   $0x20,0xffffffdc(%ebp)
			goto reswitch;
  10b0eb:	eb ad                	jmp    10b09a <vprintfmt+0x8c>

		// width or precision field
		case '0':
			if (!(st.flags & F_DOT))
  10b0ed:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  10b0f0:	83 e0 08             	and    $0x8,%eax
  10b0f3:	85 c0                	test   %eax,%eax
  10b0f5:	75 07                	jne    10b0fe <vprintfmt+0xf0>
				st.padc = '0'; // pad with 0's instead of spaces
  10b0f7:	c7 45 d0 30 00 00 00 	movl   $0x30,0xffffffd0(%ebp)
		case '1': case '2': case '3': case '4':
		case '5': case '6': case '7': case '8': case '9':
			for (st.prec = 0; ; ++fmt) {
  10b0fe:	c7 45 d8 00 00 00 00 	movl   $0x0,0xffffffd8(%ebp)
				st.prec = st.prec * 10 + ch - '0';
  10b105:	8b 55 d8             	mov    0xffffffd8(%ebp),%edx
  10b108:	89 d0                	mov    %edx,%eax
  10b10a:	c1 e0 02             	shl    $0x2,%eax
  10b10d:	01 d0                	add    %edx,%eax
  10b10f:	01 c0                	add    %eax,%eax
  10b111:	03 45 c4             	add    0xffffffc4(%ebp),%eax
  10b114:	83 e8 30             	sub    $0x30,%eax
  10b117:	89 45 d8             	mov    %eax,0xffffffd8(%ebp)
				ch = *fmt;
  10b11a:	8b 45 10             	mov    0x10(%ebp),%eax
  10b11d:	0f b6 00             	movzbl (%eax),%eax
  10b120:	0f be c0             	movsbl %al,%eax
  10b123:	89 45 c4             	mov    %eax,0xffffffc4(%ebp)
				if (ch < '0' || ch > '9')
  10b126:	83 7d c4 2f          	cmpl   $0x2f,0xffffffc4(%ebp)
  10b12a:	7e 20                	jle    10b14c <vprintfmt+0x13e>
  10b12c:	83 7d c4 39          	cmpl   $0x39,0xffffffc4(%ebp)
  10b130:	7f 1a                	jg     10b14c <vprintfmt+0x13e>
  10b132:	83 45 10 01          	addl   $0x1,0x10(%ebp)
					break;
			}
  10b136:	eb cd                	jmp    10b105 <vprintfmt+0xf7>
			goto gotprec;

		case '*':
			st.prec = va_arg(ap, int);
  10b138:	8b 45 14             	mov    0x14(%ebp),%eax
  10b13b:	83 c0 04             	add    $0x4,%eax
  10b13e:	89 45 14             	mov    %eax,0x14(%ebp)
  10b141:	8b 45 14             	mov    0x14(%ebp),%eax
  10b144:	83 e8 04             	sub    $0x4,%eax
  10b147:	8b 00                	mov    (%eax),%eax
  10b149:	89 45 d8             	mov    %eax,0xffffffd8(%ebp)
		gotprec:
			if (!(st.flags & F_DOT)) {	// haven't seen a '.' yet?
  10b14c:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  10b14f:	83 e0 08             	and    $0x8,%eax
  10b152:	85 c0                	test   %eax,%eax
  10b154:	0f 85 40 ff ff ff    	jne    10b09a <vprintfmt+0x8c>
				st.width = st.prec;	// then it's a field width
  10b15a:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  10b15d:	89 45 d4             	mov    %eax,0xffffffd4(%ebp)
				st.prec = -1;
  10b160:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,0xffffffd8(%ebp)
			}
			goto reswitch;
  10b167:	e9 2e ff ff ff       	jmp    10b09a <vprintfmt+0x8c>

		case '.':
			st.flags |= F_DOT;
  10b16c:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  10b16f:	83 c8 08             	or     $0x8,%eax
  10b172:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)
			goto reswitch;
  10b175:	e9 20 ff ff ff       	jmp    10b09a <vprintfmt+0x8c>

		case '#':
			st.flags |= F_ALT;
  10b17a:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  10b17d:	83 c8 04             	or     $0x4,%eax
  10b180:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)
			goto reswitch;
  10b183:	e9 12 ff ff ff       	jmp    10b09a <vprintfmt+0x8c>

		// long flag (doubled for long long)
		case 'l':
			st.flags |= (st.flags & F_L) ? F_LL : F_L;
  10b188:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  10b18b:	89 45 bc             	mov    %eax,0xffffffbc(%ebp)
  10b18e:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  10b191:	83 e0 01             	and    $0x1,%eax
  10b194:	84 c0                	test   %al,%al
  10b196:	74 09                	je     10b1a1 <vprintfmt+0x193>
  10b198:	c7 45 c0 02 00 00 00 	movl   $0x2,0xffffffc0(%ebp)
  10b19f:	eb 07                	jmp    10b1a8 <vprintfmt+0x19a>
  10b1a1:	c7 45 c0 01 00 00 00 	movl   $0x1,0xffffffc0(%ebp)
  10b1a8:	8b 45 bc             	mov    0xffffffbc(%ebp),%eax
  10b1ab:	0b 45 c0             	or     0xffffffc0(%ebp),%eax
  10b1ae:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)
			goto reswitch;
  10b1b1:	e9 e4 fe ff ff       	jmp    10b09a <vprintfmt+0x8c>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  10b1b6:	8b 45 14             	mov    0x14(%ebp),%eax
  10b1b9:	83 c0 04             	add    $0x4,%eax
  10b1bc:	89 45 14             	mov    %eax,0x14(%ebp)
  10b1bf:	8b 45 14             	mov    0x14(%ebp),%eax
  10b1c2:	83 e8 04             	sub    $0x4,%eax
  10b1c5:	8b 10                	mov    (%eax),%edx
  10b1c7:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b1ca:	89 44 24 04          	mov    %eax,0x4(%esp)
  10b1ce:	89 14 24             	mov    %edx,(%esp)
  10b1d1:	8b 45 08             	mov    0x8(%ebp),%eax
  10b1d4:	ff d0                	call   *%eax
			break;
  10b1d6:	e9 78 fe ff ff       	jmp    10b053 <vprintfmt+0x45>

		// string
		case 's': {
			const char *s;
			if ((s = va_arg(ap, char *)) == NULL)
  10b1db:	8b 45 14             	mov    0x14(%ebp),%eax
  10b1de:	83 c0 04             	add    $0x4,%eax
  10b1e1:	89 45 14             	mov    %eax,0x14(%ebp)
  10b1e4:	8b 45 14             	mov    0x14(%ebp),%eax
  10b1e7:	83 e8 04             	sub    $0x4,%eax
  10b1ea:	8b 00                	mov    (%eax),%eax
  10b1ec:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
  10b1ef:	83 7d f4 00          	cmpl   $0x0,0xfffffff4(%ebp)
  10b1f3:	75 07                	jne    10b1fc <vprintfmt+0x1ee>
				s = "(null)";
  10b1f5:	c7 45 f4 e5 db 10 00 	movl   $0x10dbe5,0xfffffff4(%ebp)
			putstr(&st, s, st.prec);
  10b1fc:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  10b1ff:	89 44 24 08          	mov    %eax,0x8(%esp)
  10b203:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  10b206:	89 44 24 04          	mov    %eax,0x4(%esp)
  10b20a:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
  10b20d:	89 04 24             	mov    %eax,(%esp)
  10b210:	e8 f2 fb ff ff       	call   10ae07 <putstr>
			break;
  10b215:	e9 39 fe ff ff       	jmp    10b053 <vprintfmt+0x45>
		    }

		// (signed) decimal
		case 'd':
			num = getint(&st, &ap);
  10b21a:	8d 45 14             	lea    0x14(%ebp),%eax
  10b21d:	89 44 24 04          	mov    %eax,0x4(%esp)
  10b221:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
  10b224:	89 04 24             	mov    %eax,(%esp)
  10b227:	e8 0e fb ff ff       	call   10ad3a <getint>
  10b22c:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  10b22f:	89 55 ec             	mov    %edx,0xffffffec(%ebp)
			if ((intmax_t) num < 0) {
  10b232:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  10b235:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
  10b238:	85 d2                	test   %edx,%edx
  10b23a:	79 1a                	jns    10b256 <vprintfmt+0x248>
				num = -(intmax_t) num;
  10b23c:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  10b23f:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
  10b242:	f7 d8                	neg    %eax
  10b244:	83 d2 00             	adc    $0x0,%edx
  10b247:	f7 da                	neg    %edx
  10b249:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  10b24c:	89 55 ec             	mov    %edx,0xffffffec(%ebp)
				st.signc = '-';
  10b24f:	c7 45 dc 2d 00 00 00 	movl   $0x2d,0xffffffdc(%ebp)
			}
			putint(&st, num, 10);
  10b256:	c7 44 24 0c 0a 00 00 	movl   $0xa,0xc(%esp)
  10b25d:	00 
  10b25e:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  10b261:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
  10b264:	89 44 24 04          	mov    %eax,0x4(%esp)
  10b268:	89 54 24 08          	mov    %edx,0x8(%esp)
  10b26c:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
  10b26f:	89 04 24             	mov    %eax,(%esp)
  10b272:	e8 2f fd ff ff       	call   10afa6 <putint>
			break;
  10b277:	e9 d7 fd ff ff       	jmp    10b053 <vprintfmt+0x45>

		// unsigned decimal
		case 'u':
			putint(&st, getuint(&st, &ap), 10);
  10b27c:	8d 45 14             	lea    0x14(%ebp),%eax
  10b27f:	89 44 24 04          	mov    %eax,0x4(%esp)
  10b283:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
  10b286:	89 04 24             	mov    %eax,(%esp)
  10b289:	e8 1e fa ff ff       	call   10acac <getuint>
  10b28e:	c7 44 24 0c 0a 00 00 	movl   $0xa,0xc(%esp)
  10b295:	00 
  10b296:	89 44 24 04          	mov    %eax,0x4(%esp)
  10b29a:	89 54 24 08          	mov    %edx,0x8(%esp)
  10b29e:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
  10b2a1:	89 04 24             	mov    %eax,(%esp)
  10b2a4:	e8 fd fc ff ff       	call   10afa6 <putint>
			break;
  10b2a9:	e9 a5 fd ff ff       	jmp    10b053 <vprintfmt+0x45>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putint(&st, getuint(&st, &ap), 8);
  10b2ae:	8d 45 14             	lea    0x14(%ebp),%eax
  10b2b1:	89 44 24 04          	mov    %eax,0x4(%esp)
  10b2b5:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
  10b2b8:	89 04 24             	mov    %eax,(%esp)
  10b2bb:	e8 ec f9 ff ff       	call   10acac <getuint>
  10b2c0:	c7 44 24 0c 08 00 00 	movl   $0x8,0xc(%esp)
  10b2c7:	00 
  10b2c8:	89 44 24 04          	mov    %eax,0x4(%esp)
  10b2cc:	89 54 24 08          	mov    %edx,0x8(%esp)
  10b2d0:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
  10b2d3:	89 04 24             	mov    %eax,(%esp)
  10b2d6:	e8 cb fc ff ff       	call   10afa6 <putint>
			break;
  10b2db:	e9 73 fd ff ff       	jmp    10b053 <vprintfmt+0x45>

		// (unsigned) hexadecimal
		case 'x':
			putint(&st, getuint(&st, &ap), 16);
  10b2e0:	8d 45 14             	lea    0x14(%ebp),%eax
  10b2e3:	89 44 24 04          	mov    %eax,0x4(%esp)
  10b2e7:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
  10b2ea:	89 04 24             	mov    %eax,(%esp)
  10b2ed:	e8 ba f9 ff ff       	call   10acac <getuint>
  10b2f2:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
  10b2f9:	00 
  10b2fa:	89 44 24 04          	mov    %eax,0x4(%esp)
  10b2fe:	89 54 24 08          	mov    %edx,0x8(%esp)
  10b302:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
  10b305:	89 04 24             	mov    %eax,(%esp)
  10b308:	e8 99 fc ff ff       	call   10afa6 <putint>
			break;
  10b30d:	e9 41 fd ff ff       	jmp    10b053 <vprintfmt+0x45>

		// pointer
		case 'p':
			putch('0', putdat);
  10b312:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b315:	89 44 24 04          	mov    %eax,0x4(%esp)
  10b319:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  10b320:	8b 45 08             	mov    0x8(%ebp),%eax
  10b323:	ff d0                	call   *%eax
			putch('x', putdat);
  10b325:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b328:	89 44 24 04          	mov    %eax,0x4(%esp)
  10b32c:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  10b333:	8b 45 08             	mov    0x8(%ebp),%eax
  10b336:	ff d0                	call   *%eax
			putint(&st, (uintptr_t) va_arg(ap, void *), 16);
  10b338:	8b 45 14             	mov    0x14(%ebp),%eax
  10b33b:	83 c0 04             	add    $0x4,%eax
  10b33e:	89 45 14             	mov    %eax,0x14(%ebp)
  10b341:	8b 45 14             	mov    0x14(%ebp),%eax
  10b344:	83 e8 04             	sub    $0x4,%eax
  10b347:	8b 00                	mov    (%eax),%eax
  10b349:	ba 00 00 00 00       	mov    $0x0,%edx
  10b34e:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
  10b355:	00 
  10b356:	89 44 24 04          	mov    %eax,0x4(%esp)
  10b35a:	89 54 24 08          	mov    %edx,0x8(%esp)
  10b35e:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
  10b361:	89 04 24             	mov    %eax,(%esp)
  10b364:	e8 3d fc ff ff       	call   10afa6 <putint>
			break;
  10b369:	e9 e5 fc ff ff       	jmp    10b053 <vprintfmt+0x45>
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
  10b36e:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b371:	89 44 24 04          	mov    %eax,0x4(%esp)
  10b375:	8b 55 c4             	mov    0xffffffc4(%ebp),%edx
  10b378:	89 14 24             	mov    %edx,(%esp)
  10b37b:	8b 45 08             	mov    0x8(%ebp),%eax
  10b37e:	ff d0                	call   *%eax
			break;
  10b380:	e9 ce fc ff ff       	jmp    10b053 <vprintfmt+0x45>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  10b385:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b388:	89 44 24 04          	mov    %eax,0x4(%esp)
  10b38c:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  10b393:	8b 45 08             	mov    0x8(%ebp),%eax
  10b396:	ff d0                	call   *%eax
			for (fmt--; fmt[-1] != '%'; fmt--)
  10b398:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  10b39c:	eb 04                	jmp    10b3a2 <vprintfmt+0x394>
  10b39e:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  10b3a2:	8b 45 10             	mov    0x10(%ebp),%eax
  10b3a5:	83 e8 01             	sub    $0x1,%eax
  10b3a8:	0f b6 00             	movzbl (%eax),%eax
  10b3ab:	3c 25                	cmp    $0x25,%al
  10b3ad:	75 ef                	jne    10b39e <vprintfmt+0x390>
				/* do nothing */;
			break;
		}
	}
  10b3af:	e9 9f fc ff ff       	jmp    10b053 <vprintfmt+0x45>
}
  10b3b4:	83 c4 54             	add    $0x54,%esp
  10b3b7:	5f                   	pop    %edi
  10b3b8:	5d                   	pop    %ebp
  10b3b9:	c3                   	ret    
  10b3ba:	90                   	nop    
  10b3bb:	90                   	nop    

0010b3bc <putch>:


static void
putch(int ch, struct printbuf *b)
{
  10b3bc:	55                   	push   %ebp
  10b3bd:	89 e5                	mov    %esp,%ebp
  10b3bf:	83 ec 08             	sub    $0x8,%esp
	b->buf[b->idx++] = ch;
  10b3c2:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b3c5:	8b 08                	mov    (%eax),%ecx
  10b3c7:	8b 45 08             	mov    0x8(%ebp),%eax
  10b3ca:	89 c2                	mov    %eax,%edx
  10b3cc:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b3cf:	88 54 08 08          	mov    %dl,0x8(%eax,%ecx,1)
  10b3d3:	8d 51 01             	lea    0x1(%ecx),%edx
  10b3d6:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b3d9:	89 10                	mov    %edx,(%eax)
	if (b->idx == CPUTS_MAX-1) {
  10b3db:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b3de:	8b 00                	mov    (%eax),%eax
  10b3e0:	3d ff 00 00 00       	cmp    $0xff,%eax
  10b3e5:	75 24                	jne    10b40b <putch+0x4f>
		b->buf[b->idx] = 0;
  10b3e7:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b3ea:	8b 10                	mov    (%eax),%edx
  10b3ec:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b3ef:	c6 44 10 08 00       	movb   $0x0,0x8(%eax,%edx,1)
		cputs(b->buf);
  10b3f4:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b3f7:	83 c0 08             	add    $0x8,%eax
  10b3fa:	89 04 24             	mov    %eax,(%esp)
  10b3fd:	e8 1b 53 ff ff       	call   10071d <cputs>
		b->idx = 0;
  10b402:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b405:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	}
	b->cnt++;
  10b40b:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b40e:	8b 40 04             	mov    0x4(%eax),%eax
  10b411:	8d 50 01             	lea    0x1(%eax),%edx
  10b414:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b417:	89 50 04             	mov    %edx,0x4(%eax)
}
  10b41a:	c9                   	leave  
  10b41b:	c3                   	ret    

0010b41c <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  10b41c:	55                   	push   %ebp
  10b41d:	89 e5                	mov    %esp,%ebp
  10b41f:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  10b425:	c7 85 f8 fe ff ff 00 	movl   $0x0,0xfffffef8(%ebp)
  10b42c:	00 00 00 
	b.cnt = 0;
  10b42f:	c7 85 fc fe ff ff 00 	movl   $0x0,0xfffffefc(%ebp)
  10b436:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  10b439:	ba bc b3 10 00       	mov    $0x10b3bc,%edx
  10b43e:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b441:	89 44 24 0c          	mov    %eax,0xc(%esp)
  10b445:	8b 45 08             	mov    0x8(%ebp),%eax
  10b448:	89 44 24 08          	mov    %eax,0x8(%esp)
  10b44c:	8d 85 f8 fe ff ff    	lea    0xfffffef8(%ebp),%eax
  10b452:	89 44 24 04          	mov    %eax,0x4(%esp)
  10b456:	89 14 24             	mov    %edx,(%esp)
  10b459:	e8 b0 fb ff ff       	call   10b00e <vprintfmt>

	b.buf[b.idx] = 0;
  10b45e:	8b 85 f8 fe ff ff    	mov    0xfffffef8(%ebp),%eax
  10b464:	c6 84 05 00 ff ff ff 	movb   $0x0,0xffffff00(%ebp,%eax,1)
  10b46b:	00 
	cputs(b.buf);
  10b46c:	8d 85 f8 fe ff ff    	lea    0xfffffef8(%ebp),%eax
  10b472:	83 c0 08             	add    $0x8,%eax
  10b475:	89 04 24             	mov    %eax,(%esp)
  10b478:	e8 a0 52 ff ff       	call   10071d <cputs>

	return b.cnt;
  10b47d:	8b 85 fc fe ff ff    	mov    0xfffffefc(%ebp),%eax
}
  10b483:	c9                   	leave  
  10b484:	c3                   	ret    

0010b485 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  10b485:	55                   	push   %ebp
  10b486:	89 e5                	mov    %esp,%ebp
  10b488:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  10b48b:	8d 45 08             	lea    0x8(%ebp),%eax
  10b48e:	83 c0 04             	add    $0x4,%eax
  10b491:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
	cnt = vcprintf(fmt, ap);
  10b494:	8b 55 08             	mov    0x8(%ebp),%edx
  10b497:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10b49a:	89 44 24 04          	mov    %eax,0x4(%esp)
  10b49e:	89 14 24             	mov    %edx,(%esp)
  10b4a1:	e8 76 ff ff ff       	call   10b41c <vcprintf>
  10b4a6:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	va_end(ap);

	return cnt;
  10b4a9:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
}
  10b4ac:	c9                   	leave  
  10b4ad:	c3                   	ret    
  10b4ae:	90                   	nop    
  10b4af:	90                   	nop    

0010b4b0 <sprintputch>:
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  10b4b0:	55                   	push   %ebp
  10b4b1:	89 e5                	mov    %esp,%ebp
	b->cnt++;
  10b4b3:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b4b6:	8b 40 08             	mov    0x8(%eax),%eax
  10b4b9:	8d 50 01             	lea    0x1(%eax),%edx
  10b4bc:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b4bf:	89 50 08             	mov    %edx,0x8(%eax)
	if (b->buf < b->ebuf)
  10b4c2:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b4c5:	8b 10                	mov    (%eax),%edx
  10b4c7:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b4ca:	8b 40 04             	mov    0x4(%eax),%eax
  10b4cd:	39 c2                	cmp    %eax,%edx
  10b4cf:	73 12                	jae    10b4e3 <sprintputch+0x33>
		*b->buf++ = ch;
  10b4d1:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b4d4:	8b 10                	mov    (%eax),%edx
  10b4d6:	8b 45 08             	mov    0x8(%ebp),%eax
  10b4d9:	88 02                	mov    %al,(%edx)
  10b4db:	83 c2 01             	add    $0x1,%edx
  10b4de:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b4e1:	89 10                	mov    %edx,(%eax)
}
  10b4e3:	5d                   	pop    %ebp
  10b4e4:	c3                   	ret    

0010b4e5 <vsprintf>:

int
vsprintf(char *buf, const char *fmt, va_list ap)
{
  10b4e5:	55                   	push   %ebp
  10b4e6:	89 e5                	mov    %esp,%ebp
  10b4e8:	83 ec 28             	sub    $0x28,%esp
	assert(buf != NULL);
  10b4eb:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  10b4ef:	75 24                	jne    10b515 <vsprintf+0x30>
  10b4f1:	c7 44 24 0c 50 dd 10 	movl   $0x10dd50,0xc(%esp)
  10b4f8:	00 
  10b4f9:	c7 44 24 08 5c dd 10 	movl   $0x10dd5c,0x8(%esp)
  10b500:	00 
  10b501:	c7 44 24 04 19 00 00 	movl   $0x19,0x4(%esp)
  10b508:	00 
  10b509:	c7 04 24 71 dd 10 00 	movl   $0x10dd71,(%esp)
  10b510:	e8 23 54 ff ff       	call   100938 <debug_panic>
	struct sprintbuf b = {buf, (char*)(intptr_t)~0, 0};
  10b515:	8b 45 08             	mov    0x8(%ebp),%eax
  10b518:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
  10b51b:	c7 45 f8 ff ff ff ff 	movl   $0xffffffff,0xfffffff8(%ebp)
  10b522:	c7 45 fc 00 00 00 00 	movl   $0x0,0xfffffffc(%ebp)

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  10b529:	ba b0 b4 10 00       	mov    $0x10b4b0,%edx
  10b52e:	8b 45 10             	mov    0x10(%ebp),%eax
  10b531:	89 44 24 0c          	mov    %eax,0xc(%esp)
  10b535:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b538:	89 44 24 08          	mov    %eax,0x8(%esp)
  10b53c:	8d 45 f4             	lea    0xfffffff4(%ebp),%eax
  10b53f:	89 44 24 04          	mov    %eax,0x4(%esp)
  10b543:	89 14 24             	mov    %edx,(%esp)
  10b546:	e8 c3 fa ff ff       	call   10b00e <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  10b54b:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  10b54e:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  10b551:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
}
  10b554:	c9                   	leave  
  10b555:	c3                   	ret    

0010b556 <sprintf>:

int
sprintf(char *buf, const char *fmt, ...)
{
  10b556:	55                   	push   %ebp
  10b557:	89 e5                	mov    %esp,%ebp
  10b559:	83 ec 28             	sub    $0x28,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  10b55c:	8d 45 0c             	lea    0xc(%ebp),%eax
  10b55f:	83 c0 04             	add    $0x4,%eax
  10b562:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
	rc = vsprintf(buf, fmt, ap);
  10b565:	8b 55 0c             	mov    0xc(%ebp),%edx
  10b568:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10b56b:	89 44 24 08          	mov    %eax,0x8(%esp)
  10b56f:	89 54 24 04          	mov    %edx,0x4(%esp)
  10b573:	8b 45 08             	mov    0x8(%ebp),%eax
  10b576:	89 04 24             	mov    %eax,(%esp)
  10b579:	e8 67 ff ff ff       	call   10b4e5 <vsprintf>
  10b57e:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	va_end(ap);

	return rc;
  10b581:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
}
  10b584:	c9                   	leave  
  10b585:	c3                   	ret    

0010b586 <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  10b586:	55                   	push   %ebp
  10b587:	89 e5                	mov    %esp,%ebp
  10b589:	83 ec 28             	sub    $0x28,%esp
	assert(buf != NULL && n > 0);
  10b58c:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  10b590:	74 06                	je     10b598 <vsnprintf+0x12>
  10b592:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  10b596:	7f 24                	jg     10b5bc <vsnprintf+0x36>
  10b598:	c7 44 24 0c 7f dd 10 	movl   $0x10dd7f,0xc(%esp)
  10b59f:	00 
  10b5a0:	c7 44 24 08 5c dd 10 	movl   $0x10dd5c,0x8(%esp)
  10b5a7:	00 
  10b5a8:	c7 44 24 04 35 00 00 	movl   $0x35,0x4(%esp)
  10b5af:	00 
  10b5b0:	c7 04 24 71 dd 10 00 	movl   $0x10dd71,(%esp)
  10b5b7:	e8 7c 53 ff ff       	call   100938 <debug_panic>
	struct sprintbuf b = {buf, buf+n-1, 0};
  10b5bc:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b5bf:	03 45 08             	add    0x8(%ebp),%eax
  10b5c2:	8d 50 ff             	lea    0xffffffff(%eax),%edx
  10b5c5:	8b 45 08             	mov    0x8(%ebp),%eax
  10b5c8:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
  10b5cb:	89 55 f8             	mov    %edx,0xfffffff8(%ebp)
  10b5ce:	c7 45 fc 00 00 00 00 	movl   $0x0,0xfffffffc(%ebp)

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  10b5d5:	ba b0 b4 10 00       	mov    $0x10b4b0,%edx
  10b5da:	8b 45 14             	mov    0x14(%ebp),%eax
  10b5dd:	89 44 24 0c          	mov    %eax,0xc(%esp)
  10b5e1:	8b 45 10             	mov    0x10(%ebp),%eax
  10b5e4:	89 44 24 08          	mov    %eax,0x8(%esp)
  10b5e8:	8d 45 f4             	lea    0xfffffff4(%ebp),%eax
  10b5eb:	89 44 24 04          	mov    %eax,0x4(%esp)
  10b5ef:	89 14 24             	mov    %edx,(%esp)
  10b5f2:	e8 17 fa ff ff       	call   10b00e <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  10b5f7:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  10b5fa:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  10b5fd:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
}
  10b600:	c9                   	leave  
  10b601:	c3                   	ret    

0010b602 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  10b602:	55                   	push   %ebp
  10b603:	89 e5                	mov    %esp,%ebp
  10b605:	83 ec 28             	sub    $0x28,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  10b608:	8d 45 10             	lea    0x10(%ebp),%eax
  10b60b:	83 c0 04             	add    $0x4,%eax
  10b60e:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
	rc = vsnprintf(buf, n, fmt, ap);
  10b611:	8b 55 10             	mov    0x10(%ebp),%edx
  10b614:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10b617:	89 44 24 0c          	mov    %eax,0xc(%esp)
  10b61b:	89 54 24 08          	mov    %edx,0x8(%esp)
  10b61f:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b622:	89 44 24 04          	mov    %eax,0x4(%esp)
  10b626:	8b 45 08             	mov    0x8(%ebp),%eax
  10b629:	89 04 24             	mov    %eax,(%esp)
  10b62c:	e8 55 ff ff ff       	call   10b586 <vsnprintf>
  10b631:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	va_end(ap);

	return rc;
  10b634:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
}
  10b637:	c9                   	leave  
  10b638:	c3                   	ret    
  10b639:	90                   	nop    
  10b63a:	90                   	nop    
  10b63b:	90                   	nop    

0010b63c <strlen>:
#define ASM 1

int
strlen(const char *s)
{
  10b63c:	55                   	push   %ebp
  10b63d:	89 e5                	mov    %esp,%ebp
  10b63f:	83 ec 10             	sub    $0x10,%esp
	int n;

	for (n = 0; *s != '\0'; s++)
  10b642:	c7 45 fc 00 00 00 00 	movl   $0x0,0xfffffffc(%ebp)
  10b649:	eb 08                	jmp    10b653 <strlen+0x17>
		n++;
  10b64b:	83 45 fc 01          	addl   $0x1,0xfffffffc(%ebp)
  10b64f:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  10b653:	8b 45 08             	mov    0x8(%ebp),%eax
  10b656:	0f b6 00             	movzbl (%eax),%eax
  10b659:	84 c0                	test   %al,%al
  10b65b:	75 ee                	jne    10b64b <strlen+0xf>
	return n;
  10b65d:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
}
  10b660:	c9                   	leave  
  10b661:	c3                   	ret    

0010b662 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  10b662:	55                   	push   %ebp
  10b663:	89 e5                	mov    %esp,%ebp
  10b665:	83 ec 10             	sub    $0x10,%esp
	char *ret;

	ret = dst;
  10b668:	8b 45 08             	mov    0x8(%ebp),%eax
  10b66b:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	while ((*dst++ = *src++) != '\0')
  10b66e:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b671:	0f b6 10             	movzbl (%eax),%edx
  10b674:	8b 45 08             	mov    0x8(%ebp),%eax
  10b677:	88 10                	mov    %dl,(%eax)
  10b679:	8b 45 08             	mov    0x8(%ebp),%eax
  10b67c:	0f b6 00             	movzbl (%eax),%eax
  10b67f:	84 c0                	test   %al,%al
  10b681:	0f 95 c0             	setne  %al
  10b684:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  10b688:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
  10b68c:	84 c0                	test   %al,%al
  10b68e:	75 de                	jne    10b66e <strcpy+0xc>
		/* do nothing */;
	return ret;
  10b690:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
}
  10b693:	c9                   	leave  
  10b694:	c3                   	ret    

0010b695 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size)
{
  10b695:	55                   	push   %ebp
  10b696:	89 e5                	mov    %esp,%ebp
  10b698:	83 ec 10             	sub    $0x10,%esp
	size_t i;
	char *ret;

	ret = dst;
  10b69b:	8b 45 08             	mov    0x8(%ebp),%eax
  10b69e:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	for (i = 0; i < size; i++) {
  10b6a1:	c7 45 f8 00 00 00 00 	movl   $0x0,0xfffffff8(%ebp)
  10b6a8:	eb 21                	jmp    10b6cb <strncpy+0x36>
		*dst++ = *src;
  10b6aa:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b6ad:	0f b6 10             	movzbl (%eax),%edx
  10b6b0:	8b 45 08             	mov    0x8(%ebp),%eax
  10b6b3:	88 10                	mov    %dl,(%eax)
  10b6b5:	83 45 08 01          	addl   $0x1,0x8(%ebp)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
  10b6b9:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b6bc:	0f b6 00             	movzbl (%eax),%eax
  10b6bf:	84 c0                	test   %al,%al
  10b6c1:	74 04                	je     10b6c7 <strncpy+0x32>
			src++;
  10b6c3:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
  10b6c7:	83 45 f8 01          	addl   $0x1,0xfffffff8(%ebp)
  10b6cb:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10b6ce:	3b 45 10             	cmp    0x10(%ebp),%eax
  10b6d1:	72 d7                	jb     10b6aa <strncpy+0x15>
	}
	return ret;
  10b6d3:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
}
  10b6d6:	c9                   	leave  
  10b6d7:	c3                   	ret    

0010b6d8 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  10b6d8:	55                   	push   %ebp
  10b6d9:	89 e5                	mov    %esp,%ebp
  10b6db:	83 ec 10             	sub    $0x10,%esp
	char *dst_in;

	dst_in = dst;
  10b6de:	8b 45 08             	mov    0x8(%ebp),%eax
  10b6e1:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	if (size > 0) {
  10b6e4:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  10b6e8:	74 2f                	je     10b719 <strlcpy+0x41>
		while (--size > 0 && *src != '\0')
  10b6ea:	eb 13                	jmp    10b6ff <strlcpy+0x27>
			*dst++ = *src++;
  10b6ec:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b6ef:	0f b6 10             	movzbl (%eax),%edx
  10b6f2:	8b 45 08             	mov    0x8(%ebp),%eax
  10b6f5:	88 10                	mov    %dl,(%eax)
  10b6f7:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  10b6fb:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
  10b6ff:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  10b703:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  10b707:	74 0a                	je     10b713 <strlcpy+0x3b>
  10b709:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b70c:	0f b6 00             	movzbl (%eax),%eax
  10b70f:	84 c0                	test   %al,%al
  10b711:	75 d9                	jne    10b6ec <strlcpy+0x14>
		*dst = '\0';
  10b713:	8b 45 08             	mov    0x8(%ebp),%eax
  10b716:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  10b719:	8b 55 08             	mov    0x8(%ebp),%edx
  10b71c:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  10b71f:	89 d1                	mov    %edx,%ecx
  10b721:	29 c1                	sub    %eax,%ecx
  10b723:	89 c8                	mov    %ecx,%eax
}
  10b725:	c9                   	leave  
  10b726:	c3                   	ret    

0010b727 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  10b727:	55                   	push   %ebp
  10b728:	89 e5                	mov    %esp,%ebp
	while (*p && *p == *q)
  10b72a:	eb 08                	jmp    10b734 <strcmp+0xd>
		p++, q++;
  10b72c:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  10b730:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
  10b734:	8b 45 08             	mov    0x8(%ebp),%eax
  10b737:	0f b6 00             	movzbl (%eax),%eax
  10b73a:	84 c0                	test   %al,%al
  10b73c:	74 10                	je     10b74e <strcmp+0x27>
  10b73e:	8b 45 08             	mov    0x8(%ebp),%eax
  10b741:	0f b6 10             	movzbl (%eax),%edx
  10b744:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b747:	0f b6 00             	movzbl (%eax),%eax
  10b74a:	38 c2                	cmp    %al,%dl
  10b74c:	74 de                	je     10b72c <strcmp+0x5>
	return (int) ((unsigned char) *p - (unsigned char) *q);
  10b74e:	8b 45 08             	mov    0x8(%ebp),%eax
  10b751:	0f b6 00             	movzbl (%eax),%eax
  10b754:	0f b6 d0             	movzbl %al,%edx
  10b757:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b75a:	0f b6 00             	movzbl (%eax),%eax
  10b75d:	0f b6 c0             	movzbl %al,%eax
  10b760:	89 d1                	mov    %edx,%ecx
  10b762:	29 c1                	sub    %eax,%ecx
  10b764:	89 c8                	mov    %ecx,%eax
}
  10b766:	5d                   	pop    %ebp
  10b767:	c3                   	ret    

0010b768 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  10b768:	55                   	push   %ebp
  10b769:	89 e5                	mov    %esp,%ebp
  10b76b:	83 ec 04             	sub    $0x4,%esp
	while (n > 0 && *p && *p == *q)
  10b76e:	eb 0c                	jmp    10b77c <strncmp+0x14>
		n--, p++, q++;
  10b770:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  10b774:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  10b778:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
  10b77c:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  10b780:	74 1a                	je     10b79c <strncmp+0x34>
  10b782:	8b 45 08             	mov    0x8(%ebp),%eax
  10b785:	0f b6 00             	movzbl (%eax),%eax
  10b788:	84 c0                	test   %al,%al
  10b78a:	74 10                	je     10b79c <strncmp+0x34>
  10b78c:	8b 45 08             	mov    0x8(%ebp),%eax
  10b78f:	0f b6 10             	movzbl (%eax),%edx
  10b792:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b795:	0f b6 00             	movzbl (%eax),%eax
  10b798:	38 c2                	cmp    %al,%dl
  10b79a:	74 d4                	je     10b770 <strncmp+0x8>
	if (n == 0)
  10b79c:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  10b7a0:	75 09                	jne    10b7ab <strncmp+0x43>
		return 0;
  10b7a2:	c7 45 fc 00 00 00 00 	movl   $0x0,0xfffffffc(%ebp)
  10b7a9:	eb 19                	jmp    10b7c4 <strncmp+0x5c>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  10b7ab:	8b 45 08             	mov    0x8(%ebp),%eax
  10b7ae:	0f b6 00             	movzbl (%eax),%eax
  10b7b1:	0f b6 d0             	movzbl %al,%edx
  10b7b4:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b7b7:	0f b6 00             	movzbl (%eax),%eax
  10b7ba:	0f b6 c0             	movzbl %al,%eax
  10b7bd:	89 d1                	mov    %edx,%ecx
  10b7bf:	29 c1                	sub    %eax,%ecx
  10b7c1:	89 4d fc             	mov    %ecx,0xfffffffc(%ebp)
  10b7c4:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
}
  10b7c7:	c9                   	leave  
  10b7c8:	c3                   	ret    

0010b7c9 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  10b7c9:	55                   	push   %ebp
  10b7ca:	89 e5                	mov    %esp,%ebp
  10b7cc:	83 ec 08             	sub    $0x8,%esp
  10b7cf:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b7d2:	88 45 fc             	mov    %al,0xfffffffc(%ebp)
	while (*s != c)
  10b7d5:	eb 1c                	jmp    10b7f3 <strchr+0x2a>
		if (*s++ == 0)
  10b7d7:	8b 45 08             	mov    0x8(%ebp),%eax
  10b7da:	0f b6 00             	movzbl (%eax),%eax
  10b7dd:	84 c0                	test   %al,%al
  10b7df:	0f 94 c0             	sete   %al
  10b7e2:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  10b7e6:	84 c0                	test   %al,%al
  10b7e8:	74 09                	je     10b7f3 <strchr+0x2a>
			return NULL;
  10b7ea:	c7 45 f8 00 00 00 00 	movl   $0x0,0xfffffff8(%ebp)
  10b7f1:	eb 11                	jmp    10b804 <strchr+0x3b>
  10b7f3:	8b 45 08             	mov    0x8(%ebp),%eax
  10b7f6:	0f b6 00             	movzbl (%eax),%eax
  10b7f9:	3a 45 fc             	cmp    0xfffffffc(%ebp),%al
  10b7fc:	75 d9                	jne    10b7d7 <strchr+0xe>
	return (char *) s;
  10b7fe:	8b 45 08             	mov    0x8(%ebp),%eax
  10b801:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  10b804:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
}
  10b807:	c9                   	leave  
  10b808:	c3                   	ret    

0010b809 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  10b809:	55                   	push   %ebp
  10b80a:	89 e5                	mov    %esp,%ebp
  10b80c:	57                   	push   %edi
  10b80d:	83 ec 14             	sub    $0x14,%esp
	char *p;

	if (n == 0)
  10b810:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  10b814:	75 08                	jne    10b81e <memset+0x15>
		return v;
  10b816:	8b 45 08             	mov    0x8(%ebp),%eax
  10b819:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  10b81c:	eb 5b                	jmp    10b879 <memset+0x70>
	if ((int)v%4 == 0 && n%4 == 0) {
  10b81e:	8b 45 08             	mov    0x8(%ebp),%eax
  10b821:	83 e0 03             	and    $0x3,%eax
  10b824:	85 c0                	test   %eax,%eax
  10b826:	75 3f                	jne    10b867 <memset+0x5e>
  10b828:	8b 45 10             	mov    0x10(%ebp),%eax
  10b82b:	83 e0 03             	and    $0x3,%eax
  10b82e:	85 c0                	test   %eax,%eax
  10b830:	75 35                	jne    10b867 <memset+0x5e>
		c &= 0xFF;
  10b832:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
		c = (c<<24)|(c<<16)|(c<<8)|c;
  10b839:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b83c:	89 c2                	mov    %eax,%edx
  10b83e:	c1 e2 18             	shl    $0x18,%edx
  10b841:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b844:	c1 e0 10             	shl    $0x10,%eax
  10b847:	09 c2                	or     %eax,%edx
  10b849:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b84c:	c1 e0 08             	shl    $0x8,%eax
  10b84f:	09 d0                	or     %edx,%eax
  10b851:	09 45 0c             	or     %eax,0xc(%ebp)
		asm volatile("cld; rep stosl\n"
  10b854:	8b 45 10             	mov    0x10(%ebp),%eax
  10b857:	89 c1                	mov    %eax,%ecx
  10b859:	c1 e9 02             	shr    $0x2,%ecx
  10b85c:	8b 7d 08             	mov    0x8(%ebp),%edi
  10b85f:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b862:	fc                   	cld    
  10b863:	f3 ab                	rep stos %eax,%es:(%edi)
  10b865:	eb 0c                	jmp    10b873 <memset+0x6a>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  10b867:	8b 7d 08             	mov    0x8(%ebp),%edi
  10b86a:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b86d:	8b 4d 10             	mov    0x10(%ebp),%ecx
  10b870:	fc                   	cld    
  10b871:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
  10b873:	8b 45 08             	mov    0x8(%ebp),%eax
  10b876:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  10b879:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
}
  10b87c:	83 c4 14             	add    $0x14,%esp
  10b87f:	5f                   	pop    %edi
  10b880:	5d                   	pop    %ebp
  10b881:	c3                   	ret    

0010b882 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  10b882:	55                   	push   %ebp
  10b883:	89 e5                	mov    %esp,%ebp
  10b885:	57                   	push   %edi
  10b886:	56                   	push   %esi
  10b887:	83 ec 10             	sub    $0x10,%esp
	const char *s;
	char *d;
	
	s = src;
  10b88a:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b88d:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
	d = dst;
  10b890:	8b 45 08             	mov    0x8(%ebp),%eax
  10b893:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	if (s < d && s + n > d) {
  10b896:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  10b899:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  10b89c:	73 63                	jae    10b901 <memmove+0x7f>
  10b89e:	8b 45 10             	mov    0x10(%ebp),%eax
  10b8a1:	03 45 f0             	add    0xfffffff0(%ebp),%eax
  10b8a4:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  10b8a7:	76 58                	jbe    10b901 <memmove+0x7f>
		s += n;
  10b8a9:	8b 45 10             	mov    0x10(%ebp),%eax
  10b8ac:	01 45 f0             	add    %eax,0xfffffff0(%ebp)
		d += n;
  10b8af:	8b 45 10             	mov    0x10(%ebp),%eax
  10b8b2:	01 45 f4             	add    %eax,0xfffffff4(%ebp)
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  10b8b5:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  10b8b8:	83 e0 03             	and    $0x3,%eax
  10b8bb:	85 c0                	test   %eax,%eax
  10b8bd:	75 2d                	jne    10b8ec <memmove+0x6a>
  10b8bf:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  10b8c2:	83 e0 03             	and    $0x3,%eax
  10b8c5:	85 c0                	test   %eax,%eax
  10b8c7:	75 23                	jne    10b8ec <memmove+0x6a>
  10b8c9:	8b 45 10             	mov    0x10(%ebp),%eax
  10b8cc:	83 e0 03             	and    $0x3,%eax
  10b8cf:	85 c0                	test   %eax,%eax
  10b8d1:	75 19                	jne    10b8ec <memmove+0x6a>
			asm volatile("std; rep movsl\n"
  10b8d3:	8b 7d f4             	mov    0xfffffff4(%ebp),%edi
  10b8d6:	83 ef 04             	sub    $0x4,%edi
  10b8d9:	8b 75 f0             	mov    0xfffffff0(%ebp),%esi
  10b8dc:	83 ee 04             	sub    $0x4,%esi
  10b8df:	8b 45 10             	mov    0x10(%ebp),%eax
  10b8e2:	89 c1                	mov    %eax,%ecx
  10b8e4:	c1 e9 02             	shr    $0x2,%ecx
  10b8e7:	fd                   	std    
  10b8e8:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  10b8ea:	eb 12                	jmp    10b8fe <memmove+0x7c>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  10b8ec:	8b 7d f4             	mov    0xfffffff4(%ebp),%edi
  10b8ef:	83 ef 01             	sub    $0x1,%edi
  10b8f2:	8b 75 f0             	mov    0xfffffff0(%ebp),%esi
  10b8f5:	83 ee 01             	sub    $0x1,%esi
  10b8f8:	8b 4d 10             	mov    0x10(%ebp),%ecx
  10b8fb:	fd                   	std    
  10b8fc:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  10b8fe:	fc                   	cld    
  10b8ff:	eb 3d                	jmp    10b93e <memmove+0xbc>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  10b901:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  10b904:	83 e0 03             	and    $0x3,%eax
  10b907:	85 c0                	test   %eax,%eax
  10b909:	75 27                	jne    10b932 <memmove+0xb0>
  10b90b:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  10b90e:	83 e0 03             	and    $0x3,%eax
  10b911:	85 c0                	test   %eax,%eax
  10b913:	75 1d                	jne    10b932 <memmove+0xb0>
  10b915:	8b 45 10             	mov    0x10(%ebp),%eax
  10b918:	83 e0 03             	and    $0x3,%eax
  10b91b:	85 c0                	test   %eax,%eax
  10b91d:	75 13                	jne    10b932 <memmove+0xb0>
			asm volatile("cld; rep movsl\n"
  10b91f:	8b 45 10             	mov    0x10(%ebp),%eax
  10b922:	89 c1                	mov    %eax,%ecx
  10b924:	c1 e9 02             	shr    $0x2,%ecx
  10b927:	8b 7d f4             	mov    0xfffffff4(%ebp),%edi
  10b92a:	8b 75 f0             	mov    0xfffffff0(%ebp),%esi
  10b92d:	fc                   	cld    
  10b92e:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  10b930:	eb 0c                	jmp    10b93e <memmove+0xbc>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  10b932:	8b 7d f4             	mov    0xfffffff4(%ebp),%edi
  10b935:	8b 75 f0             	mov    0xfffffff0(%ebp),%esi
  10b938:	8b 4d 10             	mov    0x10(%ebp),%ecx
  10b93b:	fc                   	cld    
  10b93c:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
  10b93e:	8b 45 08             	mov    0x8(%ebp),%eax
}
  10b941:	83 c4 10             	add    $0x10,%esp
  10b944:	5e                   	pop    %esi
  10b945:	5f                   	pop    %edi
  10b946:	5d                   	pop    %ebp
  10b947:	c3                   	ret    

0010b948 <memcpy>:

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
  10b948:	55                   	push   %ebp
  10b949:	89 e5                	mov    %esp,%ebp
  10b94b:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
  10b94e:	8b 45 10             	mov    0x10(%ebp),%eax
  10b951:	89 44 24 08          	mov    %eax,0x8(%esp)
  10b955:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b958:	89 44 24 04          	mov    %eax,0x4(%esp)
  10b95c:	8b 45 08             	mov    0x8(%ebp),%eax
  10b95f:	89 04 24             	mov    %eax,(%esp)
  10b962:	e8 1b ff ff ff       	call   10b882 <memmove>
}
  10b967:	c9                   	leave  
  10b968:	c3                   	ret    

0010b969 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  10b969:	55                   	push   %ebp
  10b96a:	89 e5                	mov    %esp,%ebp
  10b96c:	83 ec 14             	sub    $0x14,%esp
	const uint8_t *s1 = (const uint8_t *) v1;
  10b96f:	8b 45 08             	mov    0x8(%ebp),%eax
  10b972:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
	const uint8_t *s2 = (const uint8_t *) v2;
  10b975:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b978:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)

	while (n-- > 0) {
  10b97b:	eb 33                	jmp    10b9b0 <memcmp+0x47>
		if (*s1 != *s2)
  10b97d:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10b980:	0f b6 10             	movzbl (%eax),%edx
  10b983:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  10b986:	0f b6 00             	movzbl (%eax),%eax
  10b989:	38 c2                	cmp    %al,%dl
  10b98b:	74 1b                	je     10b9a8 <memcmp+0x3f>
			return (int) *s1 - (int) *s2;
  10b98d:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10b990:	0f b6 00             	movzbl (%eax),%eax
  10b993:	0f b6 d0             	movzbl %al,%edx
  10b996:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  10b999:	0f b6 00             	movzbl (%eax),%eax
  10b99c:	0f b6 c0             	movzbl %al,%eax
  10b99f:	89 d1                	mov    %edx,%ecx
  10b9a1:	29 c1                	sub    %eax,%ecx
  10b9a3:	89 4d ec             	mov    %ecx,0xffffffec(%ebp)
  10b9a6:	eb 19                	jmp    10b9c1 <memcmp+0x58>
		s1++, s2++;
  10b9a8:	83 45 f8 01          	addl   $0x1,0xfffffff8(%ebp)
  10b9ac:	83 45 fc 01          	addl   $0x1,0xfffffffc(%ebp)
  10b9b0:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  10b9b4:	83 7d 10 ff          	cmpl   $0xffffffff,0x10(%ebp)
  10b9b8:	75 c3                	jne    10b97d <memcmp+0x14>
	}

	return 0;
  10b9ba:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  10b9c1:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
}
  10b9c4:	c9                   	leave  
  10b9c5:	c3                   	ret    

0010b9c6 <memchr>:

void *
memchr(const void *s, int c, size_t n)
{
  10b9c6:	55                   	push   %ebp
  10b9c7:	89 e5                	mov    %esp,%ebp
  10b9c9:	83 ec 14             	sub    $0x14,%esp
	const void *ends = (const char *) s + n;
  10b9cc:	8b 45 08             	mov    0x8(%ebp),%eax
  10b9cf:	8b 55 10             	mov    0x10(%ebp),%edx
  10b9d2:	01 d0                	add    %edx,%eax
  10b9d4:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	for (; s < ends; s++)
  10b9d7:	eb 19                	jmp    10b9f2 <memchr+0x2c>
		if (*(const unsigned char *) s == (unsigned char) c)
  10b9d9:	8b 45 08             	mov    0x8(%ebp),%eax
  10b9dc:	0f b6 10             	movzbl (%eax),%edx
  10b9df:	8b 45 0c             	mov    0xc(%ebp),%eax
  10b9e2:	38 c2                	cmp    %al,%dl
  10b9e4:	75 08                	jne    10b9ee <memchr+0x28>
			return (void *) s;
  10b9e6:	8b 45 08             	mov    0x8(%ebp),%eax
  10b9e9:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  10b9ec:	eb 13                	jmp    10ba01 <memchr+0x3b>
  10b9ee:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  10b9f2:	8b 45 08             	mov    0x8(%ebp),%eax
  10b9f5:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  10b9f8:	72 df                	jb     10b9d9 <memchr+0x13>
	return NULL;
  10b9fa:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  10ba01:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
}
  10ba04:	c9                   	leave  
  10ba05:	c3                   	ret    
  10ba06:	90                   	nop    
  10ba07:	90                   	nop    
  10ba08:	90                   	nop    
  10ba09:	90                   	nop    
  10ba0a:	90                   	nop    
  10ba0b:	90                   	nop    
  10ba0c:	90                   	nop    
  10ba0d:	90                   	nop    
  10ba0e:	90                   	nop    
  10ba0f:	90                   	nop    

0010ba10 <__udivdi3>:
  10ba10:	55                   	push   %ebp
  10ba11:	89 e5                	mov    %esp,%ebp
  10ba13:	57                   	push   %edi
  10ba14:	56                   	push   %esi
  10ba15:	83 ec 1c             	sub    $0x1c,%esp
  10ba18:	8b 45 10             	mov    0x10(%ebp),%eax
  10ba1b:	8b 55 14             	mov    0x14(%ebp),%edx
  10ba1e:	8b 7d 0c             	mov    0xc(%ebp),%edi
  10ba21:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
  10ba24:	89 c1                	mov    %eax,%ecx
  10ba26:	8b 45 08             	mov    0x8(%ebp),%eax
  10ba29:	85 d2                	test   %edx,%edx
  10ba2b:	89 d6                	mov    %edx,%esi
  10ba2d:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  10ba30:	75 1e                	jne    10ba50 <__udivdi3+0x40>
  10ba32:	39 f9                	cmp    %edi,%ecx
  10ba34:	0f 86 8d 00 00 00    	jbe    10bac7 <__udivdi3+0xb7>
  10ba3a:	89 fa                	mov    %edi,%edx
  10ba3c:	f7 f1                	div    %ecx
  10ba3e:	89 c1                	mov    %eax,%ecx
  10ba40:	89 c8                	mov    %ecx,%eax
  10ba42:	89 f2                	mov    %esi,%edx
  10ba44:	83 c4 1c             	add    $0x1c,%esp
  10ba47:	5e                   	pop    %esi
  10ba48:	5f                   	pop    %edi
  10ba49:	5d                   	pop    %ebp
  10ba4a:	c3                   	ret    
  10ba4b:	90                   	nop    
  10ba4c:	8d 74 26 00          	lea    0x0(%esi),%esi
  10ba50:	39 fa                	cmp    %edi,%edx
  10ba52:	0f 87 98 00 00 00    	ja     10baf0 <__udivdi3+0xe0>
  10ba58:	0f bd c2             	bsr    %edx,%eax
  10ba5b:	83 f0 1f             	xor    $0x1f,%eax
  10ba5e:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
  10ba61:	74 7f                	je     10bae2 <__udivdi3+0xd2>
  10ba63:	b8 20 00 00 00       	mov    $0x20,%eax
  10ba68:	8b 55 f0             	mov    0xfffffff0(%ebp),%edx
  10ba6b:	2b 45 e4             	sub    0xffffffe4(%ebp),%eax
  10ba6e:	89 c1                	mov    %eax,%ecx
  10ba70:	d3 ea                	shr    %cl,%edx
  10ba72:	0f b6 4d e4          	movzbl 0xffffffe4(%ebp),%ecx
  10ba76:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  10ba79:	89 f0                	mov    %esi,%eax
  10ba7b:	d3 e0                	shl    %cl,%eax
  10ba7d:	09 c2                	or     %eax,%edx
  10ba7f:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  10ba82:	89 55 e0             	mov    %edx,0xffffffe0(%ebp)
  10ba85:	89 fa                	mov    %edi,%edx
  10ba87:	d3 e0                	shl    %cl,%eax
  10ba89:	0f b6 4d ec          	movzbl 0xffffffec(%ebp),%ecx
  10ba8d:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
  10ba90:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  10ba93:	d3 e8                	shr    %cl,%eax
  10ba95:	0f b6 4d e4          	movzbl 0xffffffe4(%ebp),%ecx
  10ba99:	d3 e2                	shl    %cl,%edx
  10ba9b:	0f b6 4d ec          	movzbl 0xffffffec(%ebp),%ecx
  10ba9f:	09 d0                	or     %edx,%eax
  10baa1:	d3 ef                	shr    %cl,%edi
  10baa3:	89 fa                	mov    %edi,%edx
  10baa5:	f7 75 e0             	divl   0xffffffe0(%ebp)
  10baa8:	89 d1                	mov    %edx,%ecx
  10baaa:	89 c7                	mov    %eax,%edi
  10baac:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  10baaf:	f7 e7                	mul    %edi
  10bab1:	39 d1                	cmp    %edx,%ecx
  10bab3:	89 c6                	mov    %eax,%esi
  10bab5:	89 55 dc             	mov    %edx,0xffffffdc(%ebp)
  10bab8:	72 6f                	jb     10bb29 <__udivdi3+0x119>
  10baba:	39 ca                	cmp    %ecx,%edx
  10babc:	74 5e                	je     10bb1c <__udivdi3+0x10c>
  10babe:	89 f9                	mov    %edi,%ecx
  10bac0:	31 f6                	xor    %esi,%esi
  10bac2:	e9 79 ff ff ff       	jmp    10ba40 <__udivdi3+0x30>
  10bac7:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  10baca:	85 c0                	test   %eax,%eax
  10bacc:	74 32                	je     10bb00 <__udivdi3+0xf0>
  10bace:	89 f2                	mov    %esi,%edx
  10bad0:	89 f8                	mov    %edi,%eax
  10bad2:	f7 f1                	div    %ecx
  10bad4:	89 c6                	mov    %eax,%esi
  10bad6:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  10bad9:	f7 f1                	div    %ecx
  10badb:	89 c1                	mov    %eax,%ecx
  10badd:	e9 5e ff ff ff       	jmp    10ba40 <__udivdi3+0x30>
  10bae2:	39 d7                	cmp    %edx,%edi
  10bae4:	77 2a                	ja     10bb10 <__udivdi3+0x100>
  10bae6:	8b 55 f0             	mov    0xfffffff0(%ebp),%edx
  10bae9:	39 55 e8             	cmp    %edx,0xffffffe8(%ebp)
  10baec:	73 22                	jae    10bb10 <__udivdi3+0x100>
  10baee:	66 90                	xchg   %ax,%ax
  10baf0:	31 c9                	xor    %ecx,%ecx
  10baf2:	31 f6                	xor    %esi,%esi
  10baf4:	e9 47 ff ff ff       	jmp    10ba40 <__udivdi3+0x30>
  10baf9:	8d b4 26 00 00 00 00 	lea    0x0(%esi),%esi
  10bb00:	b8 01 00 00 00       	mov    $0x1,%eax
  10bb05:	31 d2                	xor    %edx,%edx
  10bb07:	f7 75 f0             	divl   0xfffffff0(%ebp)
  10bb0a:	89 c1                	mov    %eax,%ecx
  10bb0c:	eb c0                	jmp    10bace <__udivdi3+0xbe>
  10bb0e:	66 90                	xchg   %ax,%ax
  10bb10:	b9 01 00 00 00       	mov    $0x1,%ecx
  10bb15:	31 f6                	xor    %esi,%esi
  10bb17:	e9 24 ff ff ff       	jmp    10ba40 <__udivdi3+0x30>
  10bb1c:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  10bb1f:	0f b6 4d e4          	movzbl 0xffffffe4(%ebp),%ecx
  10bb23:	d3 e0                	shl    %cl,%eax
  10bb25:	39 c6                	cmp    %eax,%esi
  10bb27:	76 95                	jbe    10babe <__udivdi3+0xae>
  10bb29:	8d 4f ff             	lea    0xffffffff(%edi),%ecx
  10bb2c:	31 f6                	xor    %esi,%esi
  10bb2e:	e9 0d ff ff ff       	jmp    10ba40 <__udivdi3+0x30>
  10bb33:	90                   	nop    
  10bb34:	90                   	nop    
  10bb35:	90                   	nop    
  10bb36:	90                   	nop    
  10bb37:	90                   	nop    
  10bb38:	90                   	nop    
  10bb39:	90                   	nop    
  10bb3a:	90                   	nop    
  10bb3b:	90                   	nop    
  10bb3c:	90                   	nop    
  10bb3d:	90                   	nop    
  10bb3e:	90                   	nop    
  10bb3f:	90                   	nop    

0010bb40 <__umoddi3>:
  10bb40:	55                   	push   %ebp
  10bb41:	89 e5                	mov    %esp,%ebp
  10bb43:	57                   	push   %edi
  10bb44:	56                   	push   %esi
  10bb45:	83 ec 30             	sub    $0x30,%esp
  10bb48:	8b 55 14             	mov    0x14(%ebp),%edx
  10bb4b:	8b 45 10             	mov    0x10(%ebp),%eax
  10bb4e:	8b 75 08             	mov    0x8(%ebp),%esi
  10bb51:	8b 7d 0c             	mov    0xc(%ebp),%edi
  10bb54:	85 d2                	test   %edx,%edx
  10bb56:	c7 45 d0 00 00 00 00 	movl   $0x0,0xffffffd0(%ebp)
  10bb5d:	89 c1                	mov    %eax,%ecx
  10bb5f:	c7 45 d4 00 00 00 00 	movl   $0x0,0xffffffd4(%ebp)
  10bb66:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  10bb69:	89 55 e8             	mov    %edx,0xffffffe8(%ebp)
  10bb6c:	89 75 f0             	mov    %esi,0xfffffff0(%ebp)
  10bb6f:	89 7d e0             	mov    %edi,0xffffffe0(%ebp)
  10bb72:	75 1c                	jne    10bb90 <__umoddi3+0x50>
  10bb74:	39 f8                	cmp    %edi,%eax
  10bb76:	89 fa                	mov    %edi,%edx
  10bb78:	0f 86 d4 00 00 00    	jbe    10bc52 <__umoddi3+0x112>
  10bb7e:	89 f0                	mov    %esi,%eax
  10bb80:	f7 f1                	div    %ecx
  10bb82:	89 55 d0             	mov    %edx,0xffffffd0(%ebp)
  10bb85:	c7 45 d4 00 00 00 00 	movl   $0x0,0xffffffd4(%ebp)
  10bb8c:	eb 12                	jmp    10bba0 <__umoddi3+0x60>
  10bb8e:	66 90                	xchg   %ax,%ax
  10bb90:	8b 4d e0             	mov    0xffffffe0(%ebp),%ecx
  10bb93:	39 4d e8             	cmp    %ecx,0xffffffe8(%ebp)
  10bb96:	76 18                	jbe    10bbb0 <__umoddi3+0x70>
  10bb98:	89 75 d0             	mov    %esi,0xffffffd0(%ebp)
  10bb9b:	89 7d d4             	mov    %edi,0xffffffd4(%ebp)
  10bb9e:	66 90                	xchg   %ax,%ax
  10bba0:	8b 45 d0             	mov    0xffffffd0(%ebp),%eax
  10bba3:	8b 55 d4             	mov    0xffffffd4(%ebp),%edx
  10bba6:	83 c4 30             	add    $0x30,%esp
  10bba9:	5e                   	pop    %esi
  10bbaa:	5f                   	pop    %edi
  10bbab:	5d                   	pop    %ebp
  10bbac:	c3                   	ret    
  10bbad:	8d 76 00             	lea    0x0(%esi),%esi
  10bbb0:	0f bd 45 e8          	bsr    0xffffffe8(%ebp),%eax
  10bbb4:	83 f0 1f             	xor    $0x1f,%eax
  10bbb7:	89 45 dc             	mov    %eax,0xffffffdc(%ebp)
  10bbba:	0f 84 c0 00 00 00    	je     10bc80 <__umoddi3+0x140>
  10bbc0:	b8 20 00 00 00       	mov    $0x20,%eax
  10bbc5:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
  10bbc8:	2b 45 dc             	sub    0xffffffdc(%ebp),%eax
  10bbcb:	8b 7d ec             	mov    0xffffffec(%ebp),%edi
  10bbce:	8b 75 f0             	mov    0xfffffff0(%ebp),%esi
  10bbd1:	89 c1                	mov    %eax,%ecx
  10bbd3:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
  10bbd6:	d3 ea                	shr    %cl,%edx
  10bbd8:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  10bbdb:	0f b6 4d dc          	movzbl 0xffffffdc(%ebp),%ecx
  10bbdf:	d3 e0                	shl    %cl,%eax
  10bbe1:	09 c2                	or     %eax,%edx
  10bbe3:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  10bbe6:	d3 e7                	shl    %cl,%edi
  10bbe8:	0f b6 4d e4          	movzbl 0xffffffe4(%ebp),%ecx
  10bbec:	89 55 f4             	mov    %edx,0xfffffff4(%ebp)
  10bbef:	8b 55 e0             	mov    0xffffffe0(%ebp),%edx
  10bbf2:	d3 e8                	shr    %cl,%eax
  10bbf4:	0f b6 4d dc          	movzbl 0xffffffdc(%ebp),%ecx
  10bbf8:	d3 e2                	shl    %cl,%edx
  10bbfa:	09 d0                	or     %edx,%eax
  10bbfc:	8b 55 e0             	mov    0xffffffe0(%ebp),%edx
  10bbff:	d3 e6                	shl    %cl,%esi
  10bc01:	0f b6 4d e4          	movzbl 0xffffffe4(%ebp),%ecx
  10bc05:	d3 ea                	shr    %cl,%edx
  10bc07:	f7 75 f4             	divl   0xfffffff4(%ebp)
  10bc0a:	89 55 cc             	mov    %edx,0xffffffcc(%ebp)
  10bc0d:	f7 e7                	mul    %edi
  10bc0f:	39 55 cc             	cmp    %edx,0xffffffcc(%ebp)
  10bc12:	0f 82 a5 00 00 00    	jb     10bcbd <__umoddi3+0x17d>
  10bc18:	3b 55 cc             	cmp    0xffffffcc(%ebp),%edx
  10bc1b:	0f 84 94 00 00 00    	je     10bcb5 <__umoddi3+0x175>
  10bc21:	8b 4d cc             	mov    0xffffffcc(%ebp),%ecx
  10bc24:	29 c6                	sub    %eax,%esi
  10bc26:	19 d1                	sbb    %edx,%ecx
  10bc28:	89 4d cc             	mov    %ecx,0xffffffcc(%ebp)
  10bc2b:	0f b6 4d dc          	movzbl 0xffffffdc(%ebp),%ecx
  10bc2f:	89 f2                	mov    %esi,%edx
  10bc31:	8b 45 cc             	mov    0xffffffcc(%ebp),%eax
  10bc34:	d3 ea                	shr    %cl,%edx
  10bc36:	0f b6 4d e4          	movzbl 0xffffffe4(%ebp),%ecx
  10bc3a:	d3 e0                	shl    %cl,%eax
  10bc3c:	0f b6 4d dc          	movzbl 0xffffffdc(%ebp),%ecx
  10bc40:	09 c2                	or     %eax,%edx
  10bc42:	8b 45 cc             	mov    0xffffffcc(%ebp),%eax
  10bc45:	89 55 d0             	mov    %edx,0xffffffd0(%ebp)
  10bc48:	d3 e8                	shr    %cl,%eax
  10bc4a:	89 45 d4             	mov    %eax,0xffffffd4(%ebp)
  10bc4d:	e9 4e ff ff ff       	jmp    10bba0 <__umoddi3+0x60>
  10bc52:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  10bc55:	85 c0                	test   %eax,%eax
  10bc57:	74 17                	je     10bc70 <__umoddi3+0x130>
  10bc59:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  10bc5c:	8b 55 e8             	mov    0xffffffe8(%ebp),%edx
  10bc5f:	f7 f1                	div    %ecx
  10bc61:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  10bc64:	f7 f1                	div    %ecx
  10bc66:	e9 17 ff ff ff       	jmp    10bb82 <__umoddi3+0x42>
  10bc6b:	90                   	nop    
  10bc6c:	8d 74 26 00          	lea    0x0(%esi),%esi
  10bc70:	b8 01 00 00 00       	mov    $0x1,%eax
  10bc75:	31 d2                	xor    %edx,%edx
  10bc77:	f7 75 ec             	divl   0xffffffec(%ebp)
  10bc7a:	89 c1                	mov    %eax,%ecx
  10bc7c:	eb db                	jmp    10bc59 <__umoddi3+0x119>
  10bc7e:	66 90                	xchg   %ax,%ax
  10bc80:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  10bc83:	39 45 e0             	cmp    %eax,0xffffffe0(%ebp)
  10bc86:	77 19                	ja     10bca1 <__umoddi3+0x161>
  10bc88:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
  10bc8b:	39 55 f0             	cmp    %edx,0xfffffff0(%ebp)
  10bc8e:	73 11                	jae    10bca1 <__umoddi3+0x161>
  10bc90:	8b 55 f0             	mov    0xfffffff0(%ebp),%edx
  10bc93:	8b 4d e0             	mov    0xffffffe0(%ebp),%ecx
  10bc96:	89 55 d0             	mov    %edx,0xffffffd0(%ebp)
  10bc99:	89 4d d4             	mov    %ecx,0xffffffd4(%ebp)
  10bc9c:	e9 ff fe ff ff       	jmp    10bba0 <__umoddi3+0x60>
  10bca1:	8b 4d e0             	mov    0xffffffe0(%ebp),%ecx
  10bca4:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  10bca7:	2b 45 ec             	sub    0xffffffec(%ebp),%eax
  10bcaa:	1b 4d e8             	sbb    0xffffffe8(%ebp),%ecx
  10bcad:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
  10bcb0:	89 4d e0             	mov    %ecx,0xffffffe0(%ebp)
  10bcb3:	eb db                	jmp    10bc90 <__umoddi3+0x150>
  10bcb5:	39 f0                	cmp    %esi,%eax
  10bcb7:	0f 86 64 ff ff ff    	jbe    10bc21 <__umoddi3+0xe1>
  10bcbd:	29 f8                	sub    %edi,%eax
  10bcbf:	1b 55 f4             	sbb    0xfffffff4(%ebp),%edx
  10bcc2:	e9 5a ff ff ff       	jmp    10bc21 <__umoddi3+0xe1>
