
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
  10001a:	bc b4 df 10 00       	mov    $0x10dfb4,%esp

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
  10002f:	e8 29 04 00 00       	call   10045d <cpu_onboot>
  100034:	85 c0                	test   %eax,%eax
  100036:	74 28                	je     100060 <init+0x38>
		memset(edata, 0, end - edata);
  100038:	ba 08 30 12 00       	mov    $0x123008,%edx
  10003d:	b8 7d 91 11 00       	mov    $0x11917d,%eax
  100042:	89 d1                	mov    %edx,%ecx
  100044:	29 c1                	sub    %eax,%ecx
  100046:	89 c8                	mov    %ecx,%eax
  100048:	89 44 24 08          	mov    %eax,0x8(%esp)
  10004c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  100053:	00 
  100054:	c7 04 24 7d 91 11 00 	movl   $0x11917d,(%esp)
  10005b:	e8 41 a4 00 00       	call   10a4a1 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
  100060:	e8 e4 05 00 00       	call   100649 <cons_init>

  extern uint8_t _binary_obj_boot_bootother_start[],
    _binary_obj_boot_bootother_size[];

  uint8_t *code = (uint8_t*)lowmem_bootother_vec;
  100065:	c7 45 b0 00 10 00 00 	movl   $0x1000,0xffffffb0(%ebp)
  memmove(code, _binary_obj_boot_bootother_start, (uint32_t) _binary_obj_boot_bootother_size);
  10006c:	b8 6a 00 00 00       	mov    $0x6a,%eax
  100071:	89 44 24 08          	mov    %eax,0x8(%esp)
  100075:	c7 44 24 04 13 91 11 	movl   $0x119113,0x4(%esp)
  10007c:	00 
  10007d:	8b 45 b0             	mov    0xffffffb0(%ebp),%eax
  100080:	89 04 24             	mov    %eax,(%esp)
  100083:	e8 92 a4 00 00       	call   10a51a <memmove>

	// Lab 1: test cprintf and debug_trace
	cprintf("1234 decimal is %o octal!\n", 1234);
  100088:	c7 44 24 04 d2 04 00 	movl   $0x4d2,0x4(%esp)
  10008f:	00 
  100090:	c7 04 24 60 a9 10 00 	movl   $0x10a960,(%esp)
  100097:	e8 0d a2 00 00       	call   10a2a9 <cprintf>
	debug_check();
  10009c:	e8 f0 08 00 00       	call   100991 <debug_check>

	// Initialize and load the bootstrap CPU's GDT, TSS, and IDT.
	cpu_init();
  1000a1:	e8 6a 13 00 00       	call   101410 <cpu_init>
	trap_init();
  1000a6:	e8 8a 20 00 00       	call   102135 <trap_init>

	// Physical memory detection/initialization.
	// Can't call mem_alloc until after we do this!
	mem_init();
  1000ab:	e8 20 0b 00 00       	call   100bd0 <mem_init>

	// Lab 2: check spinlock implementation
	if (cpu_onboot())
  1000b0:	e8 a8 03 00 00       	call   10045d <cpu_onboot>
  1000b5:	85 c0                	test   %eax,%eax
  1000b7:	74 05                	je     1000be <init+0x96>
		spinlock_check();
  1000b9:	e8 41 2f 00 00       	call   102fff <spinlock_check>

	// Initialize the paged virtual memory system.
	pmap_init();
  1000be:	e8 fd 4d 00 00       	call   104ec0 <pmap_init>

	// Find and start other processors in a multiprocessor system
	mp_init();		// Find info about processors in system
  1000c3:	e8 37 2b 00 00       	call   102bff <mp_init>
	pic_init();		// setup the legacy PIC (mainly to disable it)
  1000c8:	e8 83 92 00 00       	call   109350 <pic_init>
	ioapic_init();		// prepare to handle external device interrupts
  1000cd:	e8 a6 98 00 00       	call   109978 <ioapic_init>
	lapic_init();		// setup this CPU's local APIC
  1000d2:	e8 fc 94 00 00       	call   1095d3 <lapic_init>
	cpu_bootothers();	// Get other processors started
  1000d7:	e8 62 15 00 00       	call   10163e <cpu_bootothers>
//	cprintf("CPU %d (%s) has booted\n", cpu_cur()->id,
//		cpu_onboot() ? "BP" : "AP");

	// Initialize the process management code.
proc_init();
  1000dc:	e8 bb 33 00 00       	call   10349c <proc_init>

	// Lab 1: change this so it enters user() in user mode,
	// running on the user_stack declared above,
	// instead of just calling user() directly.

  //For LAB 3
if(!cpu_onboot())
  1000e1:	e8 77 03 00 00       	call   10045d <cpu_onboot>
  1000e6:	85 c0                	test   %eax,%eax
  1000e8:	75 05                	jne    1000ef <init+0xc7>
proc_sched();
  1000ea:	e8 5d 38 00 00       	call   10394c <proc_sched>
  proc *root = proc_root = proc_alloc(NULL,0);
  1000ef:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1000f6:	00 
  1000f7:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  1000fe:	e8 3b 34 00 00       	call   10353e <proc_alloc>
  100103:	a3 70 04 12 00       	mov    %eax,0x120470
  100108:	a1 70 04 12 00       	mov    0x120470,%eax
  10010d:	89 45 b4             	mov    %eax,0xffffffb4(%ebp)
  
  elfhdr *eh = (elfhdr *)ROOTEXE_START;
  100110:	c7 45 b8 34 e5 10 00 	movl   $0x10e534,0xffffffb8(%ebp)
  assert(eh->e_magic == ELF_MAGIC);
  100117:	8b 45 b8             	mov    0xffffffb8(%ebp),%eax
  10011a:	8b 00                	mov    (%eax),%eax
  10011c:	3d 7f 45 4c 46       	cmp    $0x464c457f,%eax
  100121:	74 24                	je     100147 <init+0x11f>
  100123:	c7 44 24 0c 7b a9 10 	movl   $0x10a97b,0xc(%esp)
  10012a:	00 
  10012b:	c7 44 24 08 94 a9 10 	movl   $0x10a994,0x8(%esp)
  100132:	00 
  100133:	c7 44 24 04 6a 00 00 	movl   $0x6a,0x4(%esp)
  10013a:	00 
  10013b:	c7 04 24 a9 a9 10 00 	movl   $0x10a9a9,(%esp)
  100142:	e8 55 06 00 00       	call   10079c <debug_panic>

  proghdr *ph = (proghdr *) ((void *) eh + eh->e_phoff);
  100147:	8b 45 b8             	mov    0xffffffb8(%ebp),%eax
  10014a:	8b 40 1c             	mov    0x1c(%eax),%eax
  10014d:	03 45 b8             	add    0xffffffb8(%ebp),%eax
  100150:	89 45 bc             	mov    %eax,0xffffffbc(%ebp)
  proghdr *eph = ph + eh->e_phnum;
  100153:	8b 45 b8             	mov    0xffffffb8(%ebp),%eax
  100156:	0f b7 40 2c          	movzwl 0x2c(%eax),%eax
  10015a:	0f b7 c0             	movzwl %ax,%eax
  10015d:	c1 e0 05             	shl    $0x5,%eax
  100160:	03 45 bc             	add    0xffffffbc(%ebp),%eax
  100163:	89 45 c0             	mov    %eax,0xffffffc0(%ebp)

  for (; ph < eph; ph++){
  100166:	e9 1c 02 00 00       	jmp    100387 <init+0x35f>
    if (ph->p_type != ELF_PROG_LOAD)
  10016b:	8b 45 bc             	mov    0xffffffbc(%ebp),%eax
  10016e:	8b 00                	mov    (%eax),%eax
  100170:	83 f8 01             	cmp    $0x1,%eax
  100173:	0f 85 0a 02 00 00    	jne    100383 <init+0x35b>
      continue;

    void *fa = (void *) eh + ROUNDDOWN(ph->p_offset, PAGESIZE);
  100179:	8b 45 bc             	mov    0xffffffbc(%ebp),%eax
  10017c:	8b 40 04             	mov    0x4(%eax),%eax
  10017f:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)
  100182:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  100185:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  10018a:	03 45 b8             	add    0xffffffb8(%ebp),%eax
  10018d:	89 45 cc             	mov    %eax,0xffffffcc(%ebp)
    uint32_t va = ROUNDDOWN(ph->p_va, PAGESIZE);
  100190:	8b 45 bc             	mov    0xffffffbc(%ebp),%eax
  100193:	8b 40 08             	mov    0x8(%eax),%eax
  100196:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
  100199:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  10019c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1001a1:	89 45 d0             	mov    %eax,0xffffffd0(%ebp)
    uint32_t zva = ph->p_va + ph->p_filesz;
  1001a4:	8b 45 bc             	mov    0xffffffbc(%ebp),%eax
  1001a7:	8b 50 08             	mov    0x8(%eax),%edx
  1001aa:	8b 45 bc             	mov    0xffffffbc(%ebp),%eax
  1001ad:	8b 40 10             	mov    0x10(%eax),%eax
  1001b0:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1001b3:	89 45 d4             	mov    %eax,0xffffffd4(%ebp)
    uint32_t eva = ROUNDUP(ph->p_va + ph->p_memsz, PAGESIZE);
  1001b6:	c7 45 e8 00 10 00 00 	movl   $0x1000,0xffffffe8(%ebp)
  1001bd:	8b 45 bc             	mov    0xffffffbc(%ebp),%eax
  1001c0:	8b 50 08             	mov    0x8(%eax),%edx
  1001c3:	8b 45 bc             	mov    0xffffffbc(%ebp),%eax
  1001c6:	8b 40 14             	mov    0x14(%eax),%eax
  1001c9:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1001cc:	03 45 e8             	add    0xffffffe8(%ebp),%eax
  1001cf:	83 e8 01             	sub    $0x1,%eax
  1001d2:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  1001d5:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  1001d8:	ba 00 00 00 00       	mov    $0x0,%edx
  1001dd:	f7 75 e8             	divl   0xffffffe8(%ebp)
  1001e0:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  1001e3:	29 d0                	sub    %edx,%eax
  1001e5:	89 45 d8             	mov    %eax,0xffffffd8(%ebp)

    uint32_t perm = SYS_READ | PTE_P | PTE_U;
  1001e8:	c7 45 dc 05 02 00 00 	movl   $0x205,0xffffffdc(%ebp)
    if(ph->p_flags & ELF_PROG_FLAG_WRITE)
  1001ef:	8b 45 bc             	mov    0xffffffbc(%ebp),%eax
  1001f2:	8b 40 18             	mov    0x18(%eax),%eax
  1001f5:	83 e0 02             	and    $0x2,%eax
  1001f8:	85 c0                	test   %eax,%eax
  1001fa:	0f 84 77 01 00 00    	je     100377 <init+0x34f>
    perm |= SYS_WRITE | PTE_W;
  100200:	81 4d dc 02 04 00 00 	orl    $0x402,0xffffffdc(%ebp)

    for (; va < eva; va += PAGESIZE, fa += PAGESIZE) {
  100207:	e9 6b 01 00 00       	jmp    100377 <init+0x34f>
    pageinfo *pi = mem_alloc(); assert(pi != NULL);
  10020c:	e8 6e 0c 00 00       	call   100e7f <mem_alloc>
  100211:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
  100214:	83 7d f0 00          	cmpl   $0x0,0xfffffff0(%ebp)
  100218:	75 24                	jne    10023e <init+0x216>
  10021a:	c7 44 24 0c b5 a9 10 	movl   $0x10a9b5,0xc(%esp)
  100221:	00 
  100222:	c7 44 24 08 94 a9 10 	movl   $0x10a994,0x8(%esp)
  100229:	00 
  10022a:	c7 44 24 04 7d 00 00 	movl   $0x7d,0x4(%esp)
  100231:	00 
  100232:	c7 04 24 a9 a9 10 00 	movl   $0x10a9a9,(%esp)
  100239:	e8 5e 05 00 00       	call   10079c <debug_panic>
      if(va < ROUNDDOWN(zva, PAGESIZE))
  10023e:	8b 45 d4             	mov    0xffffffd4(%ebp),%eax
  100241:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  100244:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  100247:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  10024c:	3b 45 d0             	cmp    0xffffffd0(%ebp),%eax
  10024f:	76 2f                	jbe    100280 <init+0x258>
        memmove(mem_pi2ptr(pi), fa, PAGESIZE);
  100251:	8b 55 f0             	mov    0xfffffff0(%ebp),%edx
  100254:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  100259:	89 d3                	mov    %edx,%ebx
  10025b:	29 c3                	sub    %eax,%ebx
  10025d:	89 d8                	mov    %ebx,%eax
  10025f:	c1 e0 09             	shl    $0x9,%eax
  100262:	89 c2                	mov    %eax,%edx
  100264:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  10026b:	00 
  10026c:	8b 45 cc             	mov    0xffffffcc(%ebp),%eax
  10026f:	89 44 24 04          	mov    %eax,0x4(%esp)
  100273:	89 14 24             	mov    %edx,(%esp)
  100276:	e8 9f a2 00 00       	call   10a51a <memmove>
  10027b:	e9 96 00 00 00       	jmp    100316 <init+0x2ee>
      else if (va < zva && ph->p_filesz){
  100280:	8b 45 d0             	mov    0xffffffd0(%ebp),%eax
  100283:	3b 45 d4             	cmp    0xffffffd4(%ebp),%eax
  100286:	73 65                	jae    1002ed <init+0x2c5>
  100288:	8b 45 bc             	mov    0xffffffbc(%ebp),%eax
  10028b:	8b 40 10             	mov    0x10(%eax),%eax
  10028e:	85 c0                	test   %eax,%eax
  100290:	74 5b                	je     1002ed <init+0x2c5>
      memset(mem_pi2ptr(pi),0, PAGESIZE);
  100292:	8b 55 f0             	mov    0xfffffff0(%ebp),%edx
  100295:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  10029a:	89 d1                	mov    %edx,%ecx
  10029c:	29 c1                	sub    %eax,%ecx
  10029e:	89 c8                	mov    %ecx,%eax
  1002a0:	c1 e0 09             	shl    $0x9,%eax
  1002a3:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  1002aa:	00 
  1002ab:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1002b2:	00 
  1002b3:	89 04 24             	mov    %eax,(%esp)
  1002b6:	e8 e6 a1 00 00       	call   10a4a1 <memset>
      memmove(mem_pi2ptr(pi), fa, zva-va);
  1002bb:	8b 55 d0             	mov    0xffffffd0(%ebp),%edx
  1002be:	8b 45 d4             	mov    0xffffffd4(%ebp),%eax
  1002c1:	89 c1                	mov    %eax,%ecx
  1002c3:	29 d1                	sub    %edx,%ecx
  1002c5:	8b 55 f0             	mov    0xfffffff0(%ebp),%edx
  1002c8:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  1002cd:	89 d3                	mov    %edx,%ebx
  1002cf:	29 c3                	sub    %eax,%ebx
  1002d1:	89 d8                	mov    %ebx,%eax
  1002d3:	c1 e0 09             	shl    $0x9,%eax
  1002d6:	89 c2                	mov    %eax,%edx
  1002d8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  1002dc:	8b 45 cc             	mov    0xffffffcc(%ebp),%eax
  1002df:	89 44 24 04          	mov    %eax,0x4(%esp)
  1002e3:	89 14 24             	mov    %edx,(%esp)
  1002e6:	e8 2f a2 00 00       	call   10a51a <memmove>
  1002eb:	eb 29                	jmp    100316 <init+0x2ee>
      } else
        memset(mem_pi2ptr(pi), 0, PAGESIZE);
  1002ed:	8b 55 f0             	mov    0xfffffff0(%ebp),%edx
  1002f0:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  1002f5:	89 d1                	mov    %edx,%ecx
  1002f7:	29 c1                	sub    %eax,%ecx
  1002f9:	89 c8                	mov    %ecx,%eax
  1002fb:	c1 e0 09             	shl    $0x9,%eax
  1002fe:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  100305:	00 
  100306:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  10030d:	00 
  10030e:	89 04 24             	mov    %eax,(%esp)
  100311:	e8 8b a1 00 00       	call   10a4a1 <memset>

      pte_t *pte = pmap_insert(root->pdir, pi, va, perm);
  100316:	8b 55 dc             	mov    0xffffffdc(%ebp),%edx
  100319:	8b 45 b4             	mov    0xffffffb4(%ebp),%eax
  10031c:	8b 88 a0 06 00 00    	mov    0x6a0(%eax),%ecx
  100322:	89 54 24 0c          	mov    %edx,0xc(%esp)
  100326:	8b 45 d0             	mov    0xffffffd0(%ebp),%eax
  100329:	89 44 24 08          	mov    %eax,0x8(%esp)
  10032d:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  100330:	89 44 24 04          	mov    %eax,0x4(%esp)
  100334:	89 0c 24             	mov    %ecx,(%esp)
  100337:	e8 db 56 00 00       	call   105a17 <pmap_insert>
  10033c:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
      assert(pte != NULL);
  10033f:	83 7d f4 00          	cmpl   $0x0,0xfffffff4(%ebp)
  100343:	75 24                	jne    100369 <init+0x341>
  100345:	c7 44 24 0c c0 a9 10 	movl   $0x10a9c0,0xc(%esp)
  10034c:	00 
  10034d:	c7 44 24 08 94 a9 10 	movl   $0x10a994,0x8(%esp)
  100354:	00 
  100355:	c7 44 24 04 87 00 00 	movl   $0x87,0x4(%esp)
  10035c:	00 
  10035d:	c7 04 24 a9 a9 10 00 	movl   $0x10a9a9,(%esp)
  100364:	e8 33 04 00 00       	call   10079c <debug_panic>
  100369:	81 45 d0 00 10 00 00 	addl   $0x1000,0xffffffd0(%ebp)
  100370:	81 45 cc 00 10 00 00 	addl   $0x1000,0xffffffcc(%ebp)
  100377:	8b 45 d0             	mov    0xffffffd0(%ebp),%eax
  10037a:	3b 45 d8             	cmp    0xffffffd8(%ebp),%eax
  10037d:	0f 82 89 fe ff ff    	jb     10020c <init+0x1e4>
  100383:	83 45 bc 20          	addl   $0x20,0xffffffbc(%ebp)
  100387:	8b 45 bc             	mov    0xffffffbc(%ebp),%eax
  10038a:	3b 45 c0             	cmp    0xffffffc0(%ebp),%eax
  10038d:	0f 82 d8 fd ff ff    	jb     10016b <init+0x143>
      }
      }

      root->sv.tf.eip = eh->e_entry;
  100393:	8b 45 b8             	mov    0xffffffb8(%ebp),%eax
  100396:	8b 50 18             	mov    0x18(%eax),%edx
  100399:	8b 45 b4             	mov    0xffffffb4(%ebp),%eax
  10039c:	89 90 88 04 00 00    	mov    %edx,0x488(%eax)
      root->sv.tf.eflags |= FL_IF;
  1003a2:	8b 45 b4             	mov    0xffffffb4(%ebp),%eax
  1003a5:	8b 80 90 04 00 00    	mov    0x490(%eax),%eax
  1003ab:	89 c2                	mov    %eax,%edx
  1003ad:	80 ce 02             	or     $0x2,%dh
  1003b0:	8b 45 b4             	mov    0xffffffb4(%ebp),%eax
  1003b3:	89 90 90 04 00 00    	mov    %edx,0x490(%eax)

      pageinfo *pi = mem_alloc(); assert(pi != NULL);
  1003b9:	e8 c1 0a 00 00       	call   100e7f <mem_alloc>
  1003be:	89 45 c4             	mov    %eax,0xffffffc4(%ebp)
  1003c1:	83 7d c4 00          	cmpl   $0x0,0xffffffc4(%ebp)
  1003c5:	75 24                	jne    1003eb <init+0x3c3>
  1003c7:	c7 44 24 0c b5 a9 10 	movl   $0x10a9b5,0xc(%esp)
  1003ce:	00 
  1003cf:	c7 44 24 08 94 a9 10 	movl   $0x10a994,0x8(%esp)
  1003d6:	00 
  1003d7:	c7 44 24 04 8e 00 00 	movl   $0x8e,0x4(%esp)
  1003de:	00 
  1003df:	c7 04 24 a9 a9 10 00 	movl   $0x10a9a9,(%esp)
  1003e6:	e8 b1 03 00 00       	call   10079c <debug_panic>
      pte_t *pte = pmap_insert(root->pdir, pi, VM_STACKHI-PAGESIZE,
        SYS_READ | SYS_WRITE | PTE_P | PTE_U | PTE_W);
  1003eb:	8b 45 b4             	mov    0xffffffb4(%ebp),%eax
  1003ee:	8b 90 a0 06 00 00    	mov    0x6a0(%eax),%edx
  1003f4:	c7 44 24 0c 07 06 00 	movl   $0x607,0xc(%esp)
  1003fb:	00 
  1003fc:	c7 44 24 08 00 f0 ff 	movl   $0xeffff000,0x8(%esp)
  100403:	ef 
  100404:	8b 45 c4             	mov    0xffffffc4(%ebp),%eax
  100407:	89 44 24 04          	mov    %eax,0x4(%esp)
  10040b:	89 14 24             	mov    %edx,(%esp)
  10040e:	e8 04 56 00 00       	call   105a17 <pmap_insert>
  100413:	89 45 c8             	mov    %eax,0xffffffc8(%ebp)
      assert(pte != NULL);
  100416:	83 7d c8 00          	cmpl   $0x0,0xffffffc8(%ebp)
  10041a:	75 24                	jne    100440 <init+0x418>
  10041c:	c7 44 24 0c c0 a9 10 	movl   $0x10a9c0,0xc(%esp)
  100423:	00 
  100424:	c7 44 24 08 94 a9 10 	movl   $0x10a994,0x8(%esp)
  10042b:	00 
  10042c:	c7 44 24 04 91 00 00 	movl   $0x91,0x4(%esp)
  100433:	00 
  100434:	c7 04 24 a9 a9 10 00 	movl   $0x10a9a9,(%esp)
  10043b:	e8 5c 03 00 00       	call   10079c <debug_panic>
      root->sv.tf.esp = VM_STACKHI;
  100440:	8b 45 b4             	mov    0xffffffb4(%ebp),%eax
  100443:	c7 80 94 04 00 00 00 	movl   $0xf0000000,0x494(%eax)
  10044a:	00 00 f0 

      proc_ready(root);
  10044d:	8b 45 b4             	mov    0xffffffb4(%ebp),%eax
  100450:	89 04 24             	mov    %eax,(%esp)
  100453:	e8 30 33 00 00       	call   103788 <proc_ready>
      proc_sched();
  100458:	e8 ef 34 00 00       	call   10394c <proc_sched>

0010045d <cpu_onboot>:
}

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  10045d:	55                   	push   %ebp
  10045e:	89 e5                	mov    %esp,%ebp
  100460:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  100463:	e8 0d 00 00 00       	call   100475 <cpu_cur>
  100468:	3d 00 d0 10 00       	cmp    $0x10d000,%eax
  10046d:	0f 94 c0             	sete   %al
  100470:	0f b6 c0             	movzbl %al,%eax
}
  100473:	c9                   	leave  
  100474:	c3                   	ret    

00100475 <cpu_cur>:
  100475:	55                   	push   %ebp
  100476:	89 e5                	mov    %esp,%ebp
  100478:	83 ec 28             	sub    $0x28,%esp
static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  10047b:	89 65 fc             	mov    %esp,0xfffffffc(%ebp)
        return esp;
  10047e:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  100481:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  100484:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  100487:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  10048c:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	assert(c->magic == CPU_MAGIC);
  10048f:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  100492:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  100498:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  10049d:	74 24                	je     1004c3 <cpu_cur+0x4e>
  10049f:	c7 44 24 0c cc a9 10 	movl   $0x10a9cc,0xc(%esp)
  1004a6:	00 
  1004a7:	c7 44 24 08 94 a9 10 	movl   $0x10a994,0x8(%esp)
  1004ae:	00 
  1004af:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  1004b6:	00 
  1004b7:	c7 04 24 e2 a9 10 00 	movl   $0x10a9e2,(%esp)
  1004be:	e8 d9 02 00 00       	call   10079c <debug_panic>
	return c;
  1004c3:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
}
  1004c6:	c9                   	leave  
  1004c7:	c3                   	ret    

001004c8 <user>:
     // user();
}

// This is the first function that gets run in user mode (ring 3).
// It acts as PIOS's "root process",
// of which all other processes are descendants.
void
user()
{
  1004c8:	55                   	push   %ebp
  1004c9:	89 e5                	mov    %esp,%ebp
  1004cb:	83 ec 28             	sub    $0x28,%esp
	cprintf("in user()\n");
  1004ce:	c7 04 24 ef a9 10 00 	movl   $0x10a9ef,(%esp)
  1004d5:	e8 cf 9d 00 00       	call   10a2a9 <cprintf>
static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  1004da:	89 65 f8             	mov    %esp,0xfffffff8(%ebp)
        return esp;
  1004dd:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1004e0:	89 c2                	mov    %eax,%edx
	assert(read_esp() > (uint32_t) &user_stack[0]);
  1004e2:	b8 00 a0 11 00       	mov    $0x11a000,%eax
  1004e7:	39 c2                	cmp    %eax,%edx
  1004e9:	77 24                	ja     10050f <user+0x47>
  1004eb:	c7 44 24 0c fc a9 10 	movl   $0x10a9fc,0xc(%esp)
  1004f2:	00 
  1004f3:	c7 44 24 08 94 a9 10 	movl   $0x10a994,0x8(%esp)
  1004fa:	00 
  1004fb:	c7 44 24 04 a0 00 00 	movl   $0xa0,0x4(%esp)
  100502:	00 
  100503:	c7 04 24 a9 a9 10 00 	movl   $0x10a9a9,(%esp)
  10050a:	e8 8d 02 00 00       	call   10079c <debug_panic>
static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  10050f:	89 65 fc             	mov    %esp,0xfffffffc(%ebp)
        return esp;
  100512:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  100515:	89 c2                	mov    %eax,%edx
	assert(read_esp() < (uint32_t) &user_stack[sizeof(user_stack)]);
  100517:	b8 00 b0 11 00       	mov    $0x11b000,%eax
  10051c:	39 c2                	cmp    %eax,%edx
  10051e:	72 24                	jb     100544 <user+0x7c>
  100520:	c7 44 24 0c 24 aa 10 	movl   $0x10aa24,0xc(%esp)
  100527:	00 
  100528:	c7 44 24 08 94 a9 10 	movl   $0x10a994,0x8(%esp)
  10052f:	00 
  100530:	c7 44 24 04 a1 00 00 	movl   $0xa1,0x4(%esp)
  100537:	00 
  100538:	c7 04 24 a9 a9 10 00 	movl   $0x10a9a9,(%esp)
  10053f:	e8 58 02 00 00       	call   10079c <debug_panic>

	// Check the system call and process scheduling code.
  cprintf("proc_check");
  100544:	c7 04 24 5c aa 10 00 	movl   $0x10aa5c,(%esp)
  10054b:	e8 59 9d 00 00       	call   10a2a9 <cprintf>
	proc_check();
  100550:	e8 1d 37 00 00       	call   103c72 <proc_check>

	// Check that we're in user mode and can handle traps from there.
	trap_check_user();
  100555:	e8 d7 20 00 00       	call   102631 <trap_check_user>

	done();
  10055a:	e8 00 00 00 00       	call   10055f <done>

0010055f <done>:
}

// This is a function that we call when the kernel is "done" -
// it just puts the processor into an infinite loop.
// We make this a function so that we can set a breakpoints on it.
// Our grade scripts use this breakpoint to know when to stop QEMU.
void gcc_noreturn
done()
{
  10055f:	55                   	push   %ebp
  100560:	89 e5                	mov    %esp,%ebp
	while (1)
		;	// just spin
  100562:	eb fe                	jmp    100562 <done+0x3>

00100564 <cons_intr>:
// called by device interrupt routines to feed input characters
// into the circular console input buffer.
void
cons_intr(int (*proc)(void))
{
  100564:	55                   	push   %ebp
  100565:	89 e5                	mov    %esp,%ebp
  100567:	83 ec 18             	sub    $0x18,%esp
	int c;

	spinlock_acquire(&cons_lock);
  10056a:	c7 04 24 00 fd 11 00 	movl   $0x11fd00,(%esp)
  100571:	e8 b4 28 00 00       	call   102e2a <spinlock_acquire>
	while ((c = (*proc)()) != -1) {
  100576:	eb 33                	jmp    1005ab <cons_intr+0x47>
		if (c == 0)
  100578:	83 7d fc 00          	cmpl   $0x0,0xfffffffc(%ebp)
  10057c:	74 2d                	je     1005ab <cons_intr+0x47>
			continue;
		cons.buf[cons.wpos++] = c;
  10057e:	8b 15 04 b2 11 00    	mov    0x11b204,%edx
  100584:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  100587:	88 82 00 b0 11 00    	mov    %al,0x11b000(%edx)
  10058d:	8d 42 01             	lea    0x1(%edx),%eax
  100590:	a3 04 b2 11 00       	mov    %eax,0x11b204
		if (cons.wpos == CONSBUFSIZE)
  100595:	a1 04 b2 11 00       	mov    0x11b204,%eax
  10059a:	3d 00 02 00 00       	cmp    $0x200,%eax
  10059f:	75 0a                	jne    1005ab <cons_intr+0x47>
			cons.wpos = 0;
  1005a1:	c7 05 04 b2 11 00 00 	movl   $0x0,0x11b204
  1005a8:	00 00 00 
  1005ab:	8b 45 08             	mov    0x8(%ebp),%eax
  1005ae:	ff d0                	call   *%eax
  1005b0:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  1005b3:	83 7d fc ff          	cmpl   $0xffffffff,0xfffffffc(%ebp)
  1005b7:	75 bf                	jne    100578 <cons_intr+0x14>
	}
	spinlock_release(&cons_lock);
  1005b9:	c7 04 24 00 fd 11 00 	movl   $0x11fd00,(%esp)
  1005c0:	e8 60 29 00 00       	call   102f25 <spinlock_release>
}
  1005c5:	c9                   	leave  
  1005c6:	c3                   	ret    

001005c7 <cons_getc>:

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
  1005c7:	55                   	push   %ebp
  1005c8:	89 e5                	mov    %esp,%ebp
  1005ca:	83 ec 18             	sub    $0x18,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
  1005cd:	e8 36 8c 00 00       	call   109208 <serial_intr>
	kbd_intr();
  1005d2:	e8 8d 8b 00 00       	call   109164 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
  1005d7:	8b 15 00 b2 11 00    	mov    0x11b200,%edx
  1005dd:	a1 04 b2 11 00       	mov    0x11b204,%eax
  1005e2:	39 c2                	cmp    %eax,%edx
  1005e4:	74 39                	je     10061f <cons_getc+0x58>
		c = cons.buf[cons.rpos++];
  1005e6:	8b 15 00 b2 11 00    	mov    0x11b200,%edx
  1005ec:	0f b6 82 00 b0 11 00 	movzbl 0x11b000(%edx),%eax
  1005f3:	0f b6 c0             	movzbl %al,%eax
  1005f6:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  1005f9:	8d 42 01             	lea    0x1(%edx),%eax
  1005fc:	a3 00 b2 11 00       	mov    %eax,0x11b200
		if (cons.rpos == CONSBUFSIZE)
  100601:	a1 00 b2 11 00       	mov    0x11b200,%eax
  100606:	3d 00 02 00 00       	cmp    $0x200,%eax
  10060b:	75 0a                	jne    100617 <cons_getc+0x50>
			cons.rpos = 0;
  10060d:	c7 05 00 b2 11 00 00 	movl   $0x0,0x11b200
  100614:	00 00 00 
		return c;
  100617:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  10061a:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  10061d:	eb 07                	jmp    100626 <cons_getc+0x5f>
	}
	return 0;
  10061f:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  100626:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
}
  100629:	c9                   	leave  
  10062a:	c3                   	ret    

0010062b <cons_putc>:

// output a character to the console
static void
cons_putc(int c)
{
  10062b:	55                   	push   %ebp
  10062c:	89 e5                	mov    %esp,%ebp
  10062e:	83 ec 08             	sub    $0x8,%esp
	serial_putc(c);
  100631:	8b 45 08             	mov    0x8(%ebp),%eax
  100634:	89 04 24             	mov    %eax,(%esp)
  100637:	e8 e9 8b 00 00       	call   109225 <serial_putc>
	video_putc(c);
  10063c:	8b 45 08             	mov    0x8(%ebp),%eax
  10063f:	89 04 24             	mov    %eax,(%esp)
  100642:	e8 59 87 00 00       	call   108da0 <video_putc>
}
  100647:	c9                   	leave  
  100648:	c3                   	ret    

00100649 <cons_init>:

// initialize the console devices
void
cons_init(void)
{
  100649:	55                   	push   %ebp
  10064a:	89 e5                	mov    %esp,%ebp
  10064c:	83 ec 18             	sub    $0x18,%esp
	if (!cpu_onboot())	// only do once, on the boot CPU
  10064f:	e8 56 00 00 00       	call   1006aa <cpu_onboot>
  100654:	85 c0                	test   %eax,%eax
  100656:	74 50                	je     1006a8 <cons_init+0x5f>
		return;

	spinlock_init(&cons_lock);
  100658:	c7 44 24 08 69 00 00 	movl   $0x69,0x8(%esp)
  10065f:	00 
  100660:	c7 44 24 04 67 aa 10 	movl   $0x10aa67,0x4(%esp)
  100667:	00 
  100668:	c7 04 24 00 fd 11 00 	movl   $0x11fd00,(%esp)
  10066f:	e8 8c 27 00 00       	call   102e00 <spinlock_init_>
	video_init();
  100674:	e8 5f 86 00 00       	call   108cd8 <video_init>
	kbd_init();
  100679:	e8 fa 8a 00 00       	call   109178 <kbd_init>
	serial_init();
  10067e:	e8 02 8c 00 00       	call   109285 <serial_init>

	if (!serial_exists)
  100683:	a1 00 30 12 00       	mov    0x123000,%eax
  100688:	85 c0                	test   %eax,%eax
  10068a:	75 1c                	jne    1006a8 <cons_init+0x5f>
		warn("Serial port does not exist!\n");
  10068c:	c7 44 24 08 73 aa 10 	movl   $0x10aa73,0x8(%esp)
  100693:	00 
  100694:	c7 44 24 04 6f 00 00 	movl   $0x6f,0x4(%esp)
  10069b:	00 
  10069c:	c7 04 24 67 aa 10 00 	movl   $0x10aa67,(%esp)
  1006a3:	e8 b2 01 00 00       	call   10085a <debug_warn>
}
  1006a8:	c9                   	leave  
  1006a9:	c3                   	ret    

001006aa <cpu_onboot>:
}

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  1006aa:	55                   	push   %ebp
  1006ab:	89 e5                	mov    %esp,%ebp
  1006ad:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  1006b0:	e8 0d 00 00 00       	call   1006c2 <cpu_cur>
  1006b5:	3d 00 d0 10 00       	cmp    $0x10d000,%eax
  1006ba:	0f 94 c0             	sete   %al
  1006bd:	0f b6 c0             	movzbl %al,%eax
}
  1006c0:	c9                   	leave  
  1006c1:	c3                   	ret    

001006c2 <cpu_cur>:
  1006c2:	55                   	push   %ebp
  1006c3:	89 e5                	mov    %esp,%ebp
  1006c5:	83 ec 28             	sub    $0x28,%esp
static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  1006c8:	89 65 fc             	mov    %esp,0xfffffffc(%ebp)
        return esp;
  1006cb:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  1006ce:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  1006d1:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1006d4:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1006d9:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	assert(c->magic == CPU_MAGIC);
  1006dc:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  1006df:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  1006e5:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  1006ea:	74 24                	je     100710 <cpu_cur+0x4e>
  1006ec:	c7 44 24 0c 90 aa 10 	movl   $0x10aa90,0xc(%esp)
  1006f3:	00 
  1006f4:	c7 44 24 08 a6 aa 10 	movl   $0x10aaa6,0x8(%esp)
  1006fb:	00 
  1006fc:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  100703:	00 
  100704:	c7 04 24 bb aa 10 00 	movl   $0x10aabb,(%esp)
  10070b:	e8 8c 00 00 00       	call   10079c <debug_panic>
	return c;
  100710:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
}
  100713:	c9                   	leave  
  100714:	c3                   	ret    

00100715 <cputs>:


// `High'-level console I/O.  Used by readline and cprintf.
void
cputs(const char *str)
{
  100715:	55                   	push   %ebp
  100716:	89 e5                	mov    %esp,%ebp
  100718:	53                   	push   %ebx
  100719:	83 ec 14             	sub    $0x14,%esp
static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  10071c:	8c 4d f6             	movw   %cs,0xfffffff6(%ebp)
        return cs;
  10071f:	0f b7 45 f6          	movzwl 0xfffffff6(%ebp),%eax
	if (read_cs() & 3)
  100723:	0f b7 c0             	movzwl %ax,%eax
  100726:	83 e0 03             	and    $0x3,%eax
  100729:	85 c0                	test   %eax,%eax
  10072b:	74 12                	je     10073f <cputs+0x2a>
  10072d:	8b 45 08             	mov    0x8(%ebp),%eax
  100730:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %0" :
  100733:	b8 00 00 00 00       	mov    $0x0,%eax
  100738:	8b 5d f8             	mov    0xfffffff8(%ebp),%ebx
  10073b:	cd 30                	int    $0x30
		return sys_cputs(str);	// use syscall from user mode
  10073d:	eb 54                	jmp    100793 <cputs+0x7e>

	// Hold the console spinlock while printing the entire string,
	// so that the output of different cputs calls won't get mixed.
	// Implement ad hoc recursive locking for debugging convenience.
	bool already = spinlock_holding(&cons_lock);
  10073f:	c7 04 24 00 fd 11 00 	movl   $0x11fd00,(%esp)
  100746:	e8 34 28 00 00       	call   102f7f <spinlock_holding>
  10074b:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
	if (!already)
  10074e:	83 7d f0 00          	cmpl   $0x0,0xfffffff0(%ebp)
  100752:	75 23                	jne    100777 <cputs+0x62>
		spinlock_acquire(&cons_lock);
  100754:	c7 04 24 00 fd 11 00 	movl   $0x11fd00,(%esp)
  10075b:	e8 ca 26 00 00       	call   102e2a <spinlock_acquire>

	char ch;
	while (*str)
  100760:	eb 15                	jmp    100777 <cputs+0x62>
		cons_putc(*str++);
  100762:	8b 45 08             	mov    0x8(%ebp),%eax
  100765:	0f b6 00             	movzbl (%eax),%eax
  100768:	0f be c0             	movsbl %al,%eax
  10076b:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  10076f:	89 04 24             	mov    %eax,(%esp)
  100772:	e8 b4 fe ff ff       	call   10062b <cons_putc>
  100777:	8b 45 08             	mov    0x8(%ebp),%eax
  10077a:	0f b6 00             	movzbl (%eax),%eax
  10077d:	84 c0                	test   %al,%al
  10077f:	75 e1                	jne    100762 <cputs+0x4d>

	if (!already)
  100781:	83 7d f0 00          	cmpl   $0x0,0xfffffff0(%ebp)
  100785:	75 0c                	jne    100793 <cputs+0x7e>
		spinlock_release(&cons_lock);
  100787:	c7 04 24 00 fd 11 00 	movl   $0x11fd00,(%esp)
  10078e:	e8 92 27 00 00       	call   102f25 <spinlock_release>
}
  100793:	83 c4 14             	add    $0x14,%esp
  100796:	5b                   	pop    %ebx
  100797:	5d                   	pop    %ebp
  100798:	c3                   	ret    
  100799:	90                   	nop    
  10079a:	90                   	nop    
  10079b:	90                   	nop    

0010079c <debug_panic>:
// Panic is called on unresolvable fatal errors.
// It prints "panic: mesg", and then enters the kernel monitor.
void
debug_panic(const char *file, int line, const char *fmt,...)
{
  10079c:	55                   	push   %ebp
  10079d:	89 e5                	mov    %esp,%ebp
  10079f:	83 ec 58             	sub    $0x58,%esp
static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  1007a2:	8c 4d fa             	movw   %cs,0xfffffffa(%ebp)
        return cs;
  1007a5:	0f b7 45 fa          	movzwl 0xfffffffa(%ebp),%eax
	va_list ap;
	int i;

	// Avoid infinite recursion if we're panicking from kernel mode.
	if ((read_cs() & 3) == 0) {
  1007a9:	0f b7 c0             	movzwl %ax,%eax
  1007ac:	83 e0 03             	and    $0x3,%eax
  1007af:	85 c0                	test   %eax,%eax
  1007b1:	75 15                	jne    1007c8 <debug_panic+0x2c>
		if (panicstr)
  1007b3:	a1 08 b2 11 00       	mov    0x11b208,%eax
  1007b8:	85 c0                	test   %eax,%eax
  1007ba:	0f 85 95 00 00 00    	jne    100855 <debug_panic+0xb9>
			goto dead;
		panicstr = fmt;
  1007c0:	8b 45 10             	mov    0x10(%ebp),%eax
  1007c3:	a3 08 b2 11 00       	mov    %eax,0x11b208
	}

	// First print the requested message
	va_start(ap, fmt);
  1007c8:	8d 45 10             	lea    0x10(%ebp),%eax
  1007cb:	83 c0 04             	add    $0x4,%eax
  1007ce:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
	cprintf("kernel panic at %s:%d: ", file, line);
  1007d1:	8b 45 0c             	mov    0xc(%ebp),%eax
  1007d4:	89 44 24 08          	mov    %eax,0x8(%esp)
  1007d8:	8b 45 08             	mov    0x8(%ebp),%eax
  1007db:	89 44 24 04          	mov    %eax,0x4(%esp)
  1007df:	c7 04 24 c8 aa 10 00 	movl   $0x10aac8,(%esp)
  1007e6:	e8 be 9a 00 00       	call   10a2a9 <cprintf>
	vcprintf(fmt, ap);
  1007eb:	8b 55 10             	mov    0x10(%ebp),%edx
  1007ee:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  1007f1:	89 44 24 04          	mov    %eax,0x4(%esp)
  1007f5:	89 14 24             	mov    %edx,(%esp)
  1007f8:	e8 43 9a 00 00       	call   10a240 <vcprintf>
	cprintf("\n");
  1007fd:	c7 04 24 e0 aa 10 00 	movl   $0x10aae0,(%esp)
  100804:	e8 a0 9a 00 00       	call   10a2a9 <cprintf>
static gcc_inline uint32_t
read_ebp(void)
{
        uint32_t ebp;
        __asm __volatile("movl %%ebp,%0" : "=rm" (ebp));
  100809:	89 6d fc             	mov    %ebp,0xfffffffc(%ebp)
        return ebp;
  10080c:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  10080f:	89 c2                	mov    %eax,%edx
	va_end(ap);

	// Then print a backtrace of the kernel call chain
	uint32_t eips[DEBUG_TRACEFRAMES];
	debug_trace(read_ebp(), eips);
  100811:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
  100814:	89 44 24 04          	mov    %eax,0x4(%esp)
  100818:	89 14 24             	mov    %edx,(%esp)
  10081b:	e8 83 00 00 00       	call   1008a3 <debug_trace>
	for (i = 0; i < DEBUG_TRACEFRAMES && eips[i] != 0; i++)
  100820:	c7 45 f4 00 00 00 00 	movl   $0x0,0xfffffff4(%ebp)
  100827:	eb 1b                	jmp    100844 <debug_panic+0xa8>
		cprintf("  from %08x\n", eips[i]);
  100829:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  10082c:	8b 44 85 c8          	mov    0xffffffc8(%ebp,%eax,4),%eax
  100830:	89 44 24 04          	mov    %eax,0x4(%esp)
  100834:	c7 04 24 e2 aa 10 00 	movl   $0x10aae2,(%esp)
  10083b:	e8 69 9a 00 00       	call   10a2a9 <cprintf>
  100840:	83 45 f4 01          	addl   $0x1,0xfffffff4(%ebp)
  100844:	83 7d f4 09          	cmpl   $0x9,0xfffffff4(%ebp)
  100848:	7f 0b                	jg     100855 <debug_panic+0xb9>
  10084a:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  10084d:	8b 44 85 c8          	mov    0xffffffc8(%ebp,%eax,4),%eax
  100851:	85 c0                	test   %eax,%eax
  100853:	75 d4                	jne    100829 <debug_panic+0x8d>

dead:
	done();		// enter infinite loop (see kern/init.c)
  100855:	e8 05 fd ff ff       	call   10055f <done>

0010085a <debug_warn>:
}

/* like panic, but don't */
void
debug_warn(const char *file, int line, const char *fmt,...)
{
  10085a:	55                   	push   %ebp
  10085b:	89 e5                	mov    %esp,%ebp
  10085d:	83 ec 28             	sub    $0x28,%esp
	va_list ap;

	va_start(ap, fmt);
  100860:	8d 45 10             	lea    0x10(%ebp),%eax
  100863:	83 c0 04             	add    $0x4,%eax
  100866:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	cprintf("kernel warning at %s:%d: ", file, line);
  100869:	8b 45 0c             	mov    0xc(%ebp),%eax
  10086c:	89 44 24 08          	mov    %eax,0x8(%esp)
  100870:	8b 45 08             	mov    0x8(%ebp),%eax
  100873:	89 44 24 04          	mov    %eax,0x4(%esp)
  100877:	c7 04 24 ef aa 10 00 	movl   $0x10aaef,(%esp)
  10087e:	e8 26 9a 00 00       	call   10a2a9 <cprintf>
	vcprintf(fmt, ap);
  100883:	8b 55 10             	mov    0x10(%ebp),%edx
  100886:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  100889:	89 44 24 04          	mov    %eax,0x4(%esp)
  10088d:	89 14 24             	mov    %edx,(%esp)
  100890:	e8 ab 99 00 00       	call   10a240 <vcprintf>
	cprintf("\n");
  100895:	c7 04 24 e0 aa 10 00 	movl   $0x10aae0,(%esp)
  10089c:	e8 08 9a 00 00       	call   10a2a9 <cprintf>
	va_end(ap);
}
  1008a1:	c9                   	leave  
  1008a2:	c3                   	ret    

001008a3 <debug_trace>:

// Record the current call stack in eips[] by following the %ebp chain.
void gcc_noinline
debug_trace(uint32_t ebp, uint32_t eips[DEBUG_TRACEFRAMES])
{
  1008a3:	55                   	push   %ebp
  1008a4:	89 e5                	mov    %esp,%ebp
  1008a6:	83 ec 10             	sub    $0x10,%esp
//	panic("debug_trace not implemented");
  uint32_t *frame = (uint32_t *) ebp;
  1008a9:	8b 45 08             	mov    0x8(%ebp),%eax
  1008ac:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)

  int i;

  // Print the eip of the last n frames,
  // where n is DEBUG_TRACEFRAMES
  for (i = 0; i < DEBUG_TRACEFRAMES && frame; i++) {
  1008af:	c7 45 fc 00 00 00 00 	movl   $0x0,0xfffffffc(%ebp)
  1008b6:	eb 21                	jmp    1008d9 <debug_trace+0x36>
    // print relevent information about the stack
    //cprintf("ebp: %08x ", frame[0]);
    //cprintf("eip: %08x ", frame[1]);
    //cprintf("args: %08x %08x %08x %08x %08x ", frame[2], frame[3], frame[4], frame[5], frame[6]);
    //cprintf("\n"); 

    // add information to eips array
    eips[i] = frame[1];             // eip saved at ebp + 1
  1008b8:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  1008bb:	c1 e0 02             	shl    $0x2,%eax
  1008be:	89 c2                	mov    %eax,%edx
  1008c0:	03 55 0c             	add    0xc(%ebp),%edx
  1008c3:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1008c6:	83 c0 04             	add    $0x4,%eax
  1008c9:	8b 00                	mov    (%eax),%eax
  1008cb:	89 02                	mov    %eax,(%edx)

    // move to the next frame up the stack
    frame = (uint32_t*)frame[0];  // prev ebp saved at ebp 0
  1008cd:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1008d0:	8b 00                	mov    (%eax),%eax
  1008d2:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  1008d5:	83 45 fc 01          	addl   $0x1,0xfffffffc(%ebp)
  1008d9:	83 7d fc 09          	cmpl   $0x9,0xfffffffc(%ebp)
  1008dd:	7f 1b                	jg     1008fa <debug_trace+0x57>
  1008df:	83 7d f8 00          	cmpl   $0x0,0xfffffff8(%ebp)
  1008e3:	75 d3                	jne    1008b8 <debug_trace+0x15>
  }

  // if the there are less than DEBUG_TRACEFRAMES frames,
  // print the rest as null
  for (i; i < DEBUG_TRACEFRAMES; i++) {
  1008e5:	eb 13                	jmp    1008fa <debug_trace+0x57>
    eips[i] = 0; 
  1008e7:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  1008ea:	c1 e0 02             	shl    $0x2,%eax
  1008ed:	03 45 0c             	add    0xc(%ebp),%eax
  1008f0:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  1008f6:	83 45 fc 01          	addl   $0x1,0xfffffffc(%ebp)
  1008fa:	83 7d fc 09          	cmpl   $0x9,0xfffffffc(%ebp)
  1008fe:	7e e7                	jle    1008e7 <debug_trace+0x44>
  }
}
  100900:	c9                   	leave  
  100901:	c3                   	ret    

00100902 <f3>:


static void gcc_noinline f3(int r, uint32_t *e) { debug_trace(read_ebp(), e); }
  100902:	55                   	push   %ebp
  100903:	89 e5                	mov    %esp,%ebp
  100905:	83 ec 18             	sub    $0x18,%esp
static gcc_inline uint32_t
read_ebp(void)
{
        uint32_t ebp;
        __asm __volatile("movl %%ebp,%0" : "=rm" (ebp));
  100908:	89 6d fc             	mov    %ebp,0xfffffffc(%ebp)
        return ebp;
  10090b:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  10090e:	89 c2                	mov    %eax,%edx
  100910:	8b 45 0c             	mov    0xc(%ebp),%eax
  100913:	89 44 24 04          	mov    %eax,0x4(%esp)
  100917:	89 14 24             	mov    %edx,(%esp)
  10091a:	e8 84 ff ff ff       	call   1008a3 <debug_trace>
  10091f:	c9                   	leave  
  100920:	c3                   	ret    

00100921 <f2>:
static void gcc_noinline f2(int r, uint32_t *e) { r & 2 ? f3(r,e) : f3(r,e); }
  100921:	55                   	push   %ebp
  100922:	89 e5                	mov    %esp,%ebp
  100924:	83 ec 08             	sub    $0x8,%esp
  100927:	8b 45 08             	mov    0x8(%ebp),%eax
  10092a:	83 e0 02             	and    $0x2,%eax
  10092d:	85 c0                	test   %eax,%eax
  10092f:	74 14                	je     100945 <f2+0x24>
  100931:	8b 45 0c             	mov    0xc(%ebp),%eax
  100934:	89 44 24 04          	mov    %eax,0x4(%esp)
  100938:	8b 45 08             	mov    0x8(%ebp),%eax
  10093b:	89 04 24             	mov    %eax,(%esp)
  10093e:	e8 bf ff ff ff       	call   100902 <f3>
  100943:	eb 12                	jmp    100957 <f2+0x36>
  100945:	8b 45 0c             	mov    0xc(%ebp),%eax
  100948:	89 44 24 04          	mov    %eax,0x4(%esp)
  10094c:	8b 45 08             	mov    0x8(%ebp),%eax
  10094f:	89 04 24             	mov    %eax,(%esp)
  100952:	e8 ab ff ff ff       	call   100902 <f3>
  100957:	c9                   	leave  
  100958:	c3                   	ret    

00100959 <f1>:
static void gcc_noinline f1(int r, uint32_t *e) { r & 1 ? f2(r,e) : f2(r,e); }
  100959:	55                   	push   %ebp
  10095a:	89 e5                	mov    %esp,%ebp
  10095c:	83 ec 08             	sub    $0x8,%esp
  10095f:	8b 45 08             	mov    0x8(%ebp),%eax
  100962:	83 e0 01             	and    $0x1,%eax
  100965:	84 c0                	test   %al,%al
  100967:	74 14                	je     10097d <f1+0x24>
  100969:	8b 45 0c             	mov    0xc(%ebp),%eax
  10096c:	89 44 24 04          	mov    %eax,0x4(%esp)
  100970:	8b 45 08             	mov    0x8(%ebp),%eax
  100973:	89 04 24             	mov    %eax,(%esp)
  100976:	e8 a6 ff ff ff       	call   100921 <f2>
  10097b:	eb 12                	jmp    10098f <f1+0x36>
  10097d:	8b 45 0c             	mov    0xc(%ebp),%eax
  100980:	89 44 24 04          	mov    %eax,0x4(%esp)
  100984:	8b 45 08             	mov    0x8(%ebp),%eax
  100987:	89 04 24             	mov    %eax,(%esp)
  10098a:	e8 92 ff ff ff       	call   100921 <f2>
  10098f:	c9                   	leave  
  100990:	c3                   	ret    

00100991 <debug_check>:

// Test the backtrace implementation for correct operation
void
debug_check(void)
{
  100991:	55                   	push   %ebp
  100992:	89 e5                	mov    %esp,%ebp
  100994:	81 ec c8 00 00 00    	sub    $0xc8,%esp
	uint32_t eips[4][DEBUG_TRACEFRAMES];
	int r, i;

	// produce several related backtraces...
	for (i = 0; i < 4; i++)
  10099a:	c7 45 fc 00 00 00 00 	movl   $0x0,0xfffffffc(%ebp)
  1009a1:	eb 2a                	jmp    1009cd <debug_check+0x3c>
		f1(i, eips[i]);
  1009a3:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  1009a6:	89 d0                	mov    %edx,%eax
  1009a8:	c1 e0 02             	shl    $0x2,%eax
  1009ab:	01 d0                	add    %edx,%eax
  1009ad:	c1 e0 03             	shl    $0x3,%eax
  1009b0:	89 c2                	mov    %eax,%edx
  1009b2:	8d 85 58 ff ff ff    	lea    0xffffff58(%ebp),%eax
  1009b8:	01 d0                	add    %edx,%eax
  1009ba:	89 44 24 04          	mov    %eax,0x4(%esp)
  1009be:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  1009c1:	89 04 24             	mov    %eax,(%esp)
  1009c4:	e8 90 ff ff ff       	call   100959 <f1>
  1009c9:	83 45 fc 01          	addl   $0x1,0xfffffffc(%ebp)
  1009cd:	83 7d fc 03          	cmpl   $0x3,0xfffffffc(%ebp)
  1009d1:	7e d0                	jle    1009a3 <debug_check+0x12>

	// ...and make sure they come out correctly.
	for (r = 0; r < 4; r++)
  1009d3:	c7 45 f8 00 00 00 00 	movl   $0x0,0xfffffff8(%ebp)
  1009da:	e9 bc 00 00 00       	jmp    100a9b <debug_check+0x10a>
		for (i = 0; i < DEBUG_TRACEFRAMES; i++) {
  1009df:	c7 45 fc 00 00 00 00 	movl   $0x0,0xfffffffc(%ebp)
  1009e6:	e9 a2 00 00 00       	jmp    100a8d <debug_check+0xfc>
			assert((eips[r][i] != 0) == (i < 5));
  1009eb:	8b 55 f8             	mov    0xfffffff8(%ebp),%edx
  1009ee:	8b 4d fc             	mov    0xfffffffc(%ebp),%ecx
  1009f1:	89 d0                	mov    %edx,%eax
  1009f3:	c1 e0 02             	shl    $0x2,%eax
  1009f6:	01 d0                	add    %edx,%eax
  1009f8:	01 c0                	add    %eax,%eax
  1009fa:	01 c8                	add    %ecx,%eax
  1009fc:	8b 84 85 58 ff ff ff 	mov    0xffffff58(%ebp,%eax,4),%eax
  100a03:	85 c0                	test   %eax,%eax
  100a05:	0f 95 c2             	setne  %dl
  100a08:	83 7d fc 04          	cmpl   $0x4,0xfffffffc(%ebp)
  100a0c:	0f 9e c0             	setle  %al
  100a0f:	31 d0                	xor    %edx,%eax
  100a11:	84 c0                	test   %al,%al
  100a13:	74 24                	je     100a39 <debug_check+0xa8>
  100a15:	c7 44 24 0c 09 ab 10 	movl   $0x10ab09,0xc(%esp)
  100a1c:	00 
  100a1d:	c7 44 24 08 26 ab 10 	movl   $0x10ab26,0x8(%esp)
  100a24:	00 
  100a25:	c7 44 24 04 7a 00 00 	movl   $0x7a,0x4(%esp)
  100a2c:	00 
  100a2d:	c7 04 24 3b ab 10 00 	movl   $0x10ab3b,(%esp)
  100a34:	e8 63 fd ff ff       	call   10079c <debug_panic>
			if (i >= 2)
  100a39:	83 7d fc 01          	cmpl   $0x1,0xfffffffc(%ebp)
  100a3d:	7e 4a                	jle    100a89 <debug_check+0xf8>
				assert(eips[r][i] == eips[0][i]);
  100a3f:	8b 55 f8             	mov    0xfffffff8(%ebp),%edx
  100a42:	8b 4d fc             	mov    0xfffffffc(%ebp),%ecx
  100a45:	89 d0                	mov    %edx,%eax
  100a47:	c1 e0 02             	shl    $0x2,%eax
  100a4a:	01 d0                	add    %edx,%eax
  100a4c:	01 c0                	add    %eax,%eax
  100a4e:	01 c8                	add    %ecx,%eax
  100a50:	8b 94 85 58 ff ff ff 	mov    0xffffff58(%ebp,%eax,4),%edx
  100a57:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  100a5a:	8b 84 85 58 ff ff ff 	mov    0xffffff58(%ebp,%eax,4),%eax
  100a61:	39 c2                	cmp    %eax,%edx
  100a63:	74 24                	je     100a89 <debug_check+0xf8>
  100a65:	c7 44 24 0c 48 ab 10 	movl   $0x10ab48,0xc(%esp)
  100a6c:	00 
  100a6d:	c7 44 24 08 26 ab 10 	movl   $0x10ab26,0x8(%esp)
  100a74:	00 
  100a75:	c7 44 24 04 7c 00 00 	movl   $0x7c,0x4(%esp)
  100a7c:	00 
  100a7d:	c7 04 24 3b ab 10 00 	movl   $0x10ab3b,(%esp)
  100a84:	e8 13 fd ff ff       	call   10079c <debug_panic>
  100a89:	83 45 fc 01          	addl   $0x1,0xfffffffc(%ebp)
  100a8d:	83 7d fc 09          	cmpl   $0x9,0xfffffffc(%ebp)
  100a91:	0f 8e 54 ff ff ff    	jle    1009eb <debug_check+0x5a>
  100a97:	83 45 f8 01          	addl   $0x1,0xfffffff8(%ebp)
  100a9b:	83 7d f8 03          	cmpl   $0x3,0xfffffff8(%ebp)
  100a9f:	0f 8e 3a ff ff ff    	jle    1009df <debug_check+0x4e>
		}
	assert(eips[0][0] == eips[1][0]);
  100aa5:	8b 95 58 ff ff ff    	mov    0xffffff58(%ebp),%edx
  100aab:	8b 45 80             	mov    0xffffff80(%ebp),%eax
  100aae:	39 c2                	cmp    %eax,%edx
  100ab0:	74 24                	je     100ad6 <debug_check+0x145>
  100ab2:	c7 44 24 0c 61 ab 10 	movl   $0x10ab61,0xc(%esp)
  100ab9:	00 
  100aba:	c7 44 24 08 26 ab 10 	movl   $0x10ab26,0x8(%esp)
  100ac1:	00 
  100ac2:	c7 44 24 04 7e 00 00 	movl   $0x7e,0x4(%esp)
  100ac9:	00 
  100aca:	c7 04 24 3b ab 10 00 	movl   $0x10ab3b,(%esp)
  100ad1:	e8 c6 fc ff ff       	call   10079c <debug_panic>
	assert(eips[2][0] == eips[3][0]);
  100ad6:	8b 55 a8             	mov    0xffffffa8(%ebp),%edx
  100ad9:	8b 45 d0             	mov    0xffffffd0(%ebp),%eax
  100adc:	39 c2                	cmp    %eax,%edx
  100ade:	74 24                	je     100b04 <debug_check+0x173>
  100ae0:	c7 44 24 0c 7a ab 10 	movl   $0x10ab7a,0xc(%esp)
  100ae7:	00 
  100ae8:	c7 44 24 08 26 ab 10 	movl   $0x10ab26,0x8(%esp)
  100aef:	00 
  100af0:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
  100af7:	00 
  100af8:	c7 04 24 3b ab 10 00 	movl   $0x10ab3b,(%esp)
  100aff:	e8 98 fc ff ff       	call   10079c <debug_panic>
	assert(eips[1][0] != eips[2][0]);
  100b04:	8b 55 80             	mov    0xffffff80(%ebp),%edx
  100b07:	8b 45 a8             	mov    0xffffffa8(%ebp),%eax
  100b0a:	39 c2                	cmp    %eax,%edx
  100b0c:	75 24                	jne    100b32 <debug_check+0x1a1>
  100b0e:	c7 44 24 0c 93 ab 10 	movl   $0x10ab93,0xc(%esp)
  100b15:	00 
  100b16:	c7 44 24 08 26 ab 10 	movl   $0x10ab26,0x8(%esp)
  100b1d:	00 
  100b1e:	c7 44 24 04 80 00 00 	movl   $0x80,0x4(%esp)
  100b25:	00 
  100b26:	c7 04 24 3b ab 10 00 	movl   $0x10ab3b,(%esp)
  100b2d:	e8 6a fc ff ff       	call   10079c <debug_panic>
	assert(eips[0][1] == eips[2][1]);
  100b32:	8b 95 5c ff ff ff    	mov    0xffffff5c(%ebp),%edx
  100b38:	8b 45 ac             	mov    0xffffffac(%ebp),%eax
  100b3b:	39 c2                	cmp    %eax,%edx
  100b3d:	74 24                	je     100b63 <debug_check+0x1d2>
  100b3f:	c7 44 24 0c ac ab 10 	movl   $0x10abac,0xc(%esp)
  100b46:	00 
  100b47:	c7 44 24 08 26 ab 10 	movl   $0x10ab26,0x8(%esp)
  100b4e:	00 
  100b4f:	c7 44 24 04 81 00 00 	movl   $0x81,0x4(%esp)
  100b56:	00 
  100b57:	c7 04 24 3b ab 10 00 	movl   $0x10ab3b,(%esp)
  100b5e:	e8 39 fc ff ff       	call   10079c <debug_panic>
	assert(eips[1][1] == eips[3][1]);
  100b63:	8b 55 84             	mov    0xffffff84(%ebp),%edx
  100b66:	8b 45 d4             	mov    0xffffffd4(%ebp),%eax
  100b69:	39 c2                	cmp    %eax,%edx
  100b6b:	74 24                	je     100b91 <debug_check+0x200>
  100b6d:	c7 44 24 0c c5 ab 10 	movl   $0x10abc5,0xc(%esp)
  100b74:	00 
  100b75:	c7 44 24 08 26 ab 10 	movl   $0x10ab26,0x8(%esp)
  100b7c:	00 
  100b7d:	c7 44 24 04 82 00 00 	movl   $0x82,0x4(%esp)
  100b84:	00 
  100b85:	c7 04 24 3b ab 10 00 	movl   $0x10ab3b,(%esp)
  100b8c:	e8 0b fc ff ff       	call   10079c <debug_panic>
	assert(eips[0][1] != eips[1][1]);
  100b91:	8b 95 5c ff ff ff    	mov    0xffffff5c(%ebp),%edx
  100b97:	8b 45 84             	mov    0xffffff84(%ebp),%eax
  100b9a:	39 c2                	cmp    %eax,%edx
  100b9c:	75 24                	jne    100bc2 <debug_check+0x231>
  100b9e:	c7 44 24 0c de ab 10 	movl   $0x10abde,0xc(%esp)
  100ba5:	00 
  100ba6:	c7 44 24 08 26 ab 10 	movl   $0x10ab26,0x8(%esp)
  100bad:	00 
  100bae:	c7 44 24 04 83 00 00 	movl   $0x83,0x4(%esp)
  100bb5:	00 
  100bb6:	c7 04 24 3b ab 10 00 	movl   $0x10ab3b,(%esp)
  100bbd:	e8 da fb ff ff       	call   10079c <debug_panic>

	cprintf("debug_check() succeeded!\n");
  100bc2:	c7 04 24 f7 ab 10 00 	movl   $0x10abf7,(%esp)
  100bc9:	e8 db 96 00 00       	call   10a2a9 <cprintf>
}
  100bce:	c9                   	leave  
  100bcf:	c3                   	ret    

00100bd0 <mem_init>:
void mem_check(void);

void
mem_init(void)
{
  100bd0:	55                   	push   %ebp
  100bd1:	89 e5                	mov    %esp,%ebp
  100bd3:	83 ec 48             	sub    $0x48,%esp
	if (!cpu_onboot())	// only do once, on the boot CPU
  100bd6:	e8 39 02 00 00       	call   100e14 <cpu_onboot>
  100bdb:	85 c0                	test   %eax,%eax
  100bdd:	0f 84 2f 02 00 00    	je     100e12 <mem_init+0x242>
		return;

	// Determine how much base (<640K) and extended (>1MB) memory
	// is available in the system (in bytes),
	// by reading the PC's BIOS-managed nonvolatile RAM (NVRAM).
	// The NVRAM tells us how many kilobytes there are.
	// Since the count is 16 bits, this gives us up to 64MB of RAM;
	// additional RAM beyond that would have to be detected another way.
	size_t basemem = ROUNDDOWN(nvram_read16(NVRAM_BASELO)*1024, PAGESIZE);
  100be3:	c7 04 24 15 00 00 00 	movl   $0x15,(%esp)
  100bea:	e8 5a 89 00 00       	call   109549 <nvram_read16>
  100bef:	c1 e0 0a             	shl    $0xa,%eax
  100bf2:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  100bf5:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  100bf8:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  100bfd:	89 45 dc             	mov    %eax,0xffffffdc(%ebp)
	size_t extmem = ROUNDDOWN(nvram_read16(NVRAM_EXTLO)*1024, PAGESIZE);
  100c00:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
  100c07:	e8 3d 89 00 00       	call   109549 <nvram_read16>
  100c0c:	c1 e0 0a             	shl    $0xa,%eax
  100c0f:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
  100c12:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  100c15:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  100c1a:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)

	warn("Assuming we have 1GB of memory!");
  100c1d:	c7 44 24 08 14 ac 10 	movl   $0x10ac14,0x8(%esp)
  100c24:	00 
  100c25:	c7 44 24 04 33 00 00 	movl   $0x33,0x4(%esp)
  100c2c:	00 
  100c2d:	c7 04 24 34 ac 10 00 	movl   $0x10ac34,(%esp)
  100c34:	e8 21 fc ff ff       	call   10085a <debug_warn>
	extmem = 1024*1024*1024 - MEM_EXT;	// assume 1GB total memory
  100c39:	c7 45 e0 00 00 f0 3f 	movl   $0x3ff00000,0xffffffe0(%ebp)

	// The maximum physical address is the top of extended memory.
	mem_max = MEM_EXT + extmem;
  100c40:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  100c43:	05 00 00 10 00       	add    $0x100000,%eax
  100c48:	a3 98 fd 11 00       	mov    %eax,0x11fd98

	// Compute the total number of physical pages (including I/O holes)
	mem_npage = mem_max / PAGESIZE;
  100c4d:	a1 98 fd 11 00       	mov    0x11fd98,%eax
  100c52:	c1 e8 0c             	shr    $0xc,%eax
  100c55:	a3 44 fd 11 00       	mov    %eax,0x11fd44

	cprintf("Physical memory: %dK available, ", (int)(mem_max/1024));
  100c5a:	a1 98 fd 11 00       	mov    0x11fd98,%eax
  100c5f:	c1 e8 0a             	shr    $0xa,%eax
  100c62:	89 44 24 04          	mov    %eax,0x4(%esp)
  100c66:	c7 04 24 40 ac 10 00 	movl   $0x10ac40,(%esp)
  100c6d:	e8 37 96 00 00       	call   10a2a9 <cprintf>
	cprintf("base = %dK, extended = %dK\n",
  100c72:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  100c75:	c1 e8 0a             	shr    $0xa,%eax
  100c78:	89 c2                	mov    %eax,%edx
  100c7a:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  100c7d:	c1 e8 0a             	shr    $0xa,%eax
  100c80:	89 54 24 08          	mov    %edx,0x8(%esp)
  100c84:	89 44 24 04          	mov    %eax,0x4(%esp)
  100c88:	c7 04 24 61 ac 10 00 	movl   $0x10ac61,(%esp)
  100c8f:	e8 15 96 00 00       	call   10a2a9 <cprintf>
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
  100c94:	c7 45 f4 08 00 00 00 	movl   $0x8,0xfffffff4(%ebp)
  100c9b:	b8 08 30 12 00       	mov    $0x123008,%eax
  100ca0:	83 e8 01             	sub    $0x1,%eax
  100ca3:	03 45 f4             	add    0xfffffff4(%ebp),%eax
  100ca6:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  100ca9:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  100cac:	ba 00 00 00 00       	mov    $0x0,%edx
  100cb1:	f7 75 f4             	divl   0xfffffff4(%ebp)
  100cb4:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  100cb7:	29 d0                	sub    %edx,%eax
  100cb9:	a3 9c fd 11 00       	mov    %eax,0x11fd9c

  // set it all to zero
  memset(mem_pageinfo, 0, sizeof(pageinfo) * mem_npage);
  100cbe:	a1 44 fd 11 00       	mov    0x11fd44,%eax
  100cc3:	c1 e0 03             	shl    $0x3,%eax
  100cc6:	8b 15 9c fd 11 00    	mov    0x11fd9c,%edx
  100ccc:	89 44 24 08          	mov    %eax,0x8(%esp)
  100cd0:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  100cd7:	00 
  100cd8:	89 14 24             	mov    %edx,(%esp)
  100cdb:	e8 c1 97 00 00       	call   10a4a1 <memset>

  spinlock_init(&page_spinlock);
  100ce0:	c7 44 24 08 5f 00 00 	movl   $0x5f,0x8(%esp)
  100ce7:	00 
  100ce8:	c7 44 24 04 34 ac 10 	movl   $0x10ac34,0x4(%esp)
  100cef:	00 
  100cf0:	c7 04 24 60 fd 11 00 	movl   $0x11fd60,(%esp)
  100cf7:	e8 04 21 00 00       	call   102e00 <spinlock_init_>

	pageinfo **freetail = &mem_freelist;
  100cfc:	c7 45 e4 40 fd 11 00 	movl   $0x11fd40,0xffffffe4(%ebp)

	int i;
	for (i = 0; i < mem_npage; i++) {
  100d03:	c7 45 e8 00 00 00 00 	movl   $0x0,0xffffffe8(%ebp)
  100d0a:	e9 e5 00 00 00       	jmp    100df4 <mem_init+0x224>

    // physical address of current pageinfo
    uint32_t paddr = mem_pi2phys(mem_pageinfo + i);
  100d0f:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  100d12:	c1 e0 03             	shl    $0x3,%eax
  100d15:	89 c2                	mov    %eax,%edx
  100d17:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  100d1c:	8d 04 02             	lea    (%edx,%eax,1),%eax
  100d1f:	89 c2                	mov    %eax,%edx
  100d21:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  100d26:	89 d1                	mov    %edx,%ecx
  100d28:	29 c1                	sub    %eax,%ecx
  100d2a:	89 c8                	mov    %ecx,%eax
  100d2c:	c1 e0 09             	shl    $0x9,%eax
  100d2f:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
    if ((i == 0 || i == 1 || // pages 0 and 1 are reserved for idt, bios, and bootstrap (see above)
  100d32:	83 7d e8 00          	cmpl   $0x0,0xffffffe8(%ebp)
  100d36:	74 61                	je     100d99 <mem_init+0x1c9>
  100d38:	83 7d e8 01          	cmpl   $0x1,0xffffffe8(%ebp)
  100d3c:	74 5b                	je     100d99 <mem_init+0x1c9>
  100d3e:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  100d41:	05 00 10 00 00       	add    $0x1000,%eax
  100d46:	3d ff ff 09 00       	cmp    $0x9ffff,%eax
  100d4b:	76 09                	jbe    100d56 <mem_init+0x186>
  100d4d:	81 7d fc ff ff 0f 00 	cmpl   $0xfffff,0xfffffffc(%ebp)
  100d54:	76 43                	jbe    100d99 <mem_init+0x1c9>
  100d56:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  100d59:	05 00 10 00 00       	add    $0x1000,%eax
  100d5e:	ba 0c 00 10 00       	mov    $0x10000c,%edx
  100d63:	39 d0                	cmp    %edx,%eax
  100d65:	72 0a                	jb     100d71 <mem_init+0x1a1>
  100d67:	b8 08 30 12 00       	mov    $0x123008,%eax
  100d6c:	39 45 fc             	cmp    %eax,0xfffffffc(%ebp)
  100d6f:	72 28                	jb     100d99 <mem_init+0x1c9>
  100d71:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  100d74:	05 00 10 00 00       	add    $0x1000,%eax
  100d79:	ba 9c fd 11 00       	mov    $0x11fd9c,%edx
  100d7e:	39 d0                	cmp    %edx,%eax
  100d80:	72 30                	jb     100db2 <mem_init+0x1e2>
  100d82:	a1 44 fd 11 00       	mov    0x11fd44,%eax
  100d87:	c1 e0 03             	shl    $0x3,%eax
  100d8a:	89 c2                	mov    %eax,%edx
  100d8c:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  100d91:	8d 04 02             	lea    (%edx,%eax,1),%eax
  100d94:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  100d97:	76 19                	jbe    100db2 <mem_init+0x1e2>
          (paddr + PAGESIZE >= MEM_IO && paddr < MEM_EXT) || // IO section is reserved
          (paddr + PAGESIZE >= (uint32_t) &start[0] && paddr < (uint32_t) &end[0]) || // kernel, 
          (paddr + PAGESIZE >= (uint32_t) &mem_pageinfo && // start of pageinfo array
           paddr < (uint32_t) &mem_pageinfo[mem_npage]) // end of pageinfo array
     )) {
      mem_pageinfo[i].refcount = 1; 
  100d99:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  100d9c:	c1 e0 03             	shl    $0x3,%eax
  100d9f:	89 c2                	mov    %eax,%edx
  100da1:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  100da6:	8d 04 02             	lea    (%edx,%eax,1),%eax
  100da9:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
  100db0:	eb 3e                	jmp    100df0 <mem_init+0x220>
    } else {
      mem_pageinfo[i].refcount = 0; 
  100db2:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  100db5:	c1 e0 03             	shl    $0x3,%eax
  100db8:	89 c2                	mov    %eax,%edx
  100dba:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  100dbf:	8d 04 02             	lea    (%edx,%eax,1),%eax
  100dc2:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
      // Add the page to the end of the free list.
      *freetail = &mem_pageinfo[i];
  100dc9:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  100dcc:	c1 e0 03             	shl    $0x3,%eax
  100dcf:	89 c2                	mov    %eax,%edx
  100dd1:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  100dd6:	01 c2                	add    %eax,%edx
  100dd8:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  100ddb:	89 10                	mov    %edx,(%eax)
      freetail = &mem_pageinfo[i].free_next;
  100ddd:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  100de0:	c1 e0 03             	shl    $0x3,%eax
  100de3:	89 c2                	mov    %eax,%edx
  100de5:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  100dea:	8d 04 02             	lea    (%edx,%eax,1),%eax
  100ded:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
  100df0:	83 45 e8 01          	addl   $0x1,0xffffffe8(%ebp)
  100df4:	8b 55 e8             	mov    0xffffffe8(%ebp),%edx
  100df7:	a1 44 fd 11 00       	mov    0x11fd44,%eax
  100dfc:	39 c2                	cmp    %eax,%edx
  100dfe:	0f 82 0b ff ff ff    	jb     100d0f <mem_init+0x13f>
    }
	}

	*freetail = NULL;	// null-terminate the freelist
  100e04:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  100e07:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

	// Check to make sure the page allocator seems to work correctly.
	mem_check();
  100e0d:	e8 2e 01 00 00       	call   100f40 <mem_check>
}
  100e12:	c9                   	leave  
  100e13:	c3                   	ret    

00100e14 <cpu_onboot>:
}

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  100e14:	55                   	push   %ebp
  100e15:	89 e5                	mov    %esp,%ebp
  100e17:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  100e1a:	e8 0d 00 00 00       	call   100e2c <cpu_cur>
  100e1f:	3d 00 d0 10 00       	cmp    $0x10d000,%eax
  100e24:	0f 94 c0             	sete   %al
  100e27:	0f b6 c0             	movzbl %al,%eax
}
  100e2a:	c9                   	leave  
  100e2b:	c3                   	ret    

00100e2c <cpu_cur>:
  100e2c:	55                   	push   %ebp
  100e2d:	89 e5                	mov    %esp,%ebp
  100e2f:	83 ec 28             	sub    $0x28,%esp
static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  100e32:	89 65 fc             	mov    %esp,0xfffffffc(%ebp)
        return esp;
  100e35:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  100e38:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  100e3b:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  100e3e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  100e43:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	assert(c->magic == CPU_MAGIC);
  100e46:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  100e49:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  100e4f:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  100e54:	74 24                	je     100e7a <cpu_cur+0x4e>
  100e56:	c7 44 24 0c 7d ac 10 	movl   $0x10ac7d,0xc(%esp)
  100e5d:	00 
  100e5e:	c7 44 24 08 93 ac 10 	movl   $0x10ac93,0x8(%esp)
  100e65:	00 
  100e66:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  100e6d:	00 
  100e6e:	c7 04 24 a8 ac 10 00 	movl   $0x10aca8,(%esp)
  100e75:	e8 22 f9 ff ff       	call   10079c <debug_panic>
	return c;
  100e7a:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
}
  100e7d:	c9                   	leave  
  100e7e:	c3                   	ret    

00100e7f <mem_alloc>:

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
  100e7f:	55                   	push   %ebp
  100e80:	89 e5                	mov    %esp,%ebp
  100e82:	83 ec 18             	sub    $0x18,%esp
	// Fill this function in
	// Fill this function in.
//	panic("mem_alloc not implemented.");
  spinlock_acquire(&page_spinlock);
  100e85:	c7 04 24 60 fd 11 00 	movl   $0x11fd60,(%esp)
  100e8c:	e8 99 1f 00 00       	call   102e2a <spinlock_acquire>
  pageinfo *pi = mem_freelist;
  100e91:	a1 40 fd 11 00       	mov    0x11fd40,%eax
  100e96:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  if (pi != NULL) {
  100e99:	83 7d fc 00          	cmpl   $0x0,0xfffffffc(%ebp)
  100e9d:	74 13                	je     100eb2 <mem_alloc+0x33>
    mem_freelist = pi->free_next; // move front of list to next pageinfo
  100e9f:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  100ea2:	8b 00                	mov    (%eax),%eax
  100ea4:	a3 40 fd 11 00       	mov    %eax,0x11fd40
    pi->free_next = NULL; // remove pointer to next item
  100ea9:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  100eac:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  }
  spinlock_release(&page_spinlock);
  100eb2:	c7 04 24 60 fd 11 00 	movl   $0x11fd60,(%esp)
  100eb9:	e8 67 20 00 00       	call   102f25 <spinlock_release>
  return pi;
  100ebe:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
}
  100ec1:	c9                   	leave  
  100ec2:	c3                   	ret    

00100ec3 <mem_free>:

//
// Return a page to the free list, given its pageinfo pointer.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
mem_free(pageinfo *pi)
{
  100ec3:	55                   	push   %ebp
  100ec4:	89 e5                	mov    %esp,%ebp
  100ec6:	83 ec 18             	sub    $0x18,%esp
	// Fill this function in.
	//panic("mem_free not implemented.");
  // do not free in use, or already free pages
  if (pi->refcount != 0)
  100ec9:	8b 45 08             	mov    0x8(%ebp),%eax
  100ecc:	8b 40 04             	mov    0x4(%eax),%eax
  100ecf:	85 c0                	test   %eax,%eax
  100ed1:	74 1c                	je     100eef <mem_free+0x2c>
    panic("mem_free: refcound does not equal zero");
  100ed3:	c7 44 24 08 b8 ac 10 	movl   $0x10acb8,0x8(%esp)
  100eda:	00 
  100edb:	c7 44 24 04 a3 00 00 	movl   $0xa3,0x4(%esp)
  100ee2:	00 
  100ee3:	c7 04 24 34 ac 10 00 	movl   $0x10ac34,(%esp)
  100eea:	e8 ad f8 ff ff       	call   10079c <debug_panic>
  if (pi->free_next != NULL)
  100eef:	8b 45 08             	mov    0x8(%ebp),%eax
  100ef2:	8b 00                	mov    (%eax),%eax
  100ef4:	85 c0                	test   %eax,%eax
  100ef6:	74 1c                	je     100f14 <mem_free+0x51>
    panic("mem_free: attempt to free already free page");
  100ef8:	c7 44 24 08 e0 ac 10 	movl   $0x10ace0,0x8(%esp)
  100eff:	00 
  100f00:	c7 44 24 04 a5 00 00 	movl   $0xa5,0x4(%esp)
  100f07:	00 
  100f08:	c7 04 24 34 ac 10 00 	movl   $0x10ac34,(%esp)
  100f0f:	e8 88 f8 ff ff       	call   10079c <debug_panic>

  spinlock_acquire(&page_spinlock);
  100f14:	c7 04 24 60 fd 11 00 	movl   $0x11fd60,(%esp)
  100f1b:	e8 0a 1f 00 00       	call   102e2a <spinlock_acquire>
  pi->free_next = mem_freelist; // point this to the list
  100f20:	a1 40 fd 11 00       	mov    0x11fd40,%eax
  100f25:	8b 55 08             	mov    0x8(%ebp),%edx
  100f28:	89 02                	mov    %eax,(%edx)
  mem_freelist = pi; // point the front of the list to this
  100f2a:	8b 45 08             	mov    0x8(%ebp),%eax
  100f2d:	a3 40 fd 11 00       	mov    %eax,0x11fd40
  spinlock_release(&page_spinlock);
  100f32:	c7 04 24 60 fd 11 00 	movl   $0x11fd60,(%esp)
  100f39:	e8 e7 1f 00 00       	call   102f25 <spinlock_release>
}
  100f3e:	c9                   	leave  
  100f3f:	c3                   	ret    

00100f40 <mem_check>:

//
// Check the physical page allocator (mem_alloc(), mem_free())
// for correct operation after initialization via mem_init().
//
void
mem_check()
{
  100f40:	55                   	push   %ebp
  100f41:	89 e5                	mov    %esp,%ebp
  100f43:	83 ec 38             	sub    $0x38,%esp
	pageinfo *pp, *pp0, *pp1, *pp2;
	pageinfo *fl;
	int i;

        // if there's a page that shouldn't be on
        // the free list, try to make sure it
        // eventually causes trouble.
	int freepages = 0;
  100f46:	c7 45 fc 00 00 00 00 	movl   $0x0,0xfffffffc(%ebp)
	for (pp = mem_freelist; pp != 0; pp = pp->free_next) {
  100f4d:	a1 40 fd 11 00       	mov    0x11fd40,%eax
  100f52:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
  100f55:	eb 35                	jmp    100f8c <mem_check+0x4c>
		memset(mem_pi2ptr(pp), 0x97, 128);
  100f57:	8b 55 e4             	mov    0xffffffe4(%ebp),%edx
  100f5a:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  100f5f:	89 d1                	mov    %edx,%ecx
  100f61:	29 c1                	sub    %eax,%ecx
  100f63:	89 c8                	mov    %ecx,%eax
  100f65:	c1 e0 09             	shl    $0x9,%eax
  100f68:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
  100f6f:	00 
  100f70:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
  100f77:	00 
  100f78:	89 04 24             	mov    %eax,(%esp)
  100f7b:	e8 21 95 00 00       	call   10a4a1 <memset>
		freepages++;
  100f80:	83 45 fc 01          	addl   $0x1,0xfffffffc(%ebp)
  100f84:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  100f87:	8b 00                	mov    (%eax),%eax
  100f89:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
  100f8c:	83 7d e4 00          	cmpl   $0x0,0xffffffe4(%ebp)
  100f90:	75 c5                	jne    100f57 <mem_check+0x17>
	}
	cprintf("mem_check: %d free pages\n", freepages);
  100f92:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  100f95:	89 44 24 04          	mov    %eax,0x4(%esp)
  100f99:	c7 04 24 0c ad 10 00 	movl   $0x10ad0c,(%esp)
  100fa0:	e8 04 93 00 00       	call   10a2a9 <cprintf>
	assert(freepages < mem_npage);	// can't have more free than total!
  100fa5:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  100fa8:	a1 44 fd 11 00       	mov    0x11fd44,%eax
  100fad:	39 c2                	cmp    %eax,%edx
  100faf:	72 24                	jb     100fd5 <mem_check+0x95>
  100fb1:	c7 44 24 0c 26 ad 10 	movl   $0x10ad26,0xc(%esp)
  100fb8:	00 
  100fb9:	c7 44 24 08 93 ac 10 	movl   $0x10ac93,0x8(%esp)
  100fc0:	00 
  100fc1:	c7 44 24 04 c1 00 00 	movl   $0xc1,0x4(%esp)
  100fc8:	00 
  100fc9:	c7 04 24 34 ac 10 00 	movl   $0x10ac34,(%esp)
  100fd0:	e8 c7 f7 ff ff       	call   10079c <debug_panic>
	assert(freepages > 16000);	// make sure it's in the right ballpark
  100fd5:	81 7d fc 80 3e 00 00 	cmpl   $0x3e80,0xfffffffc(%ebp)
  100fdc:	7f 24                	jg     101002 <mem_check+0xc2>
  100fde:	c7 44 24 0c 3c ad 10 	movl   $0x10ad3c,0xc(%esp)
  100fe5:	00 
  100fe6:	c7 44 24 08 93 ac 10 	movl   $0x10ac93,0x8(%esp)
  100fed:	00 
  100fee:	c7 44 24 04 c2 00 00 	movl   $0xc2,0x4(%esp)
  100ff5:	00 
  100ff6:	c7 04 24 34 ac 10 00 	movl   $0x10ac34,(%esp)
  100ffd:	e8 9a f7 ff ff       	call   10079c <debug_panic>

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
  101002:	c7 45 f0 00 00 00 00 	movl   $0x0,0xfffffff0(%ebp)
  101009:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  10100c:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  10100f:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  101012:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
	pp0 = mem_alloc(); assert(pp0 != 0);
  101015:	e8 65 fe ff ff       	call   100e7f <mem_alloc>
  10101a:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  10101d:	83 7d e8 00          	cmpl   $0x0,0xffffffe8(%ebp)
  101021:	75 24                	jne    101047 <mem_check+0x107>
  101023:	c7 44 24 0c 4e ad 10 	movl   $0x10ad4e,0xc(%esp)
  10102a:	00 
  10102b:	c7 44 24 08 93 ac 10 	movl   $0x10ac93,0x8(%esp)
  101032:	00 
  101033:	c7 44 24 04 c6 00 00 	movl   $0xc6,0x4(%esp)
  10103a:	00 
  10103b:	c7 04 24 34 ac 10 00 	movl   $0x10ac34,(%esp)
  101042:	e8 55 f7 ff ff       	call   10079c <debug_panic>
	pp1 = mem_alloc(); assert(pp1 != 0);
  101047:	e8 33 fe ff ff       	call   100e7f <mem_alloc>
  10104c:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  10104f:	83 7d ec 00          	cmpl   $0x0,0xffffffec(%ebp)
  101053:	75 24                	jne    101079 <mem_check+0x139>
  101055:	c7 44 24 0c 57 ad 10 	movl   $0x10ad57,0xc(%esp)
  10105c:	00 
  10105d:	c7 44 24 08 93 ac 10 	movl   $0x10ac93,0x8(%esp)
  101064:	00 
  101065:	c7 44 24 04 c7 00 00 	movl   $0xc7,0x4(%esp)
  10106c:	00 
  10106d:	c7 04 24 34 ac 10 00 	movl   $0x10ac34,(%esp)
  101074:	e8 23 f7 ff ff       	call   10079c <debug_panic>
	pp2 = mem_alloc(); assert(pp2 != 0);
  101079:	e8 01 fe ff ff       	call   100e7f <mem_alloc>
  10107e:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
  101081:	83 7d f0 00          	cmpl   $0x0,0xfffffff0(%ebp)
  101085:	75 24                	jne    1010ab <mem_check+0x16b>
  101087:	c7 44 24 0c 60 ad 10 	movl   $0x10ad60,0xc(%esp)
  10108e:	00 
  10108f:	c7 44 24 08 93 ac 10 	movl   $0x10ac93,0x8(%esp)
  101096:	00 
  101097:	c7 44 24 04 c8 00 00 	movl   $0xc8,0x4(%esp)
  10109e:	00 
  10109f:	c7 04 24 34 ac 10 00 	movl   $0x10ac34,(%esp)
  1010a6:	e8 f1 f6 ff ff       	call   10079c <debug_panic>

	assert(pp0);
  1010ab:	83 7d e8 00          	cmpl   $0x0,0xffffffe8(%ebp)
  1010af:	75 24                	jne    1010d5 <mem_check+0x195>
  1010b1:	c7 44 24 0c 69 ad 10 	movl   $0x10ad69,0xc(%esp)
  1010b8:	00 
  1010b9:	c7 44 24 08 93 ac 10 	movl   $0x10ac93,0x8(%esp)
  1010c0:	00 
  1010c1:	c7 44 24 04 ca 00 00 	movl   $0xca,0x4(%esp)
  1010c8:	00 
  1010c9:	c7 04 24 34 ac 10 00 	movl   $0x10ac34,(%esp)
  1010d0:	e8 c7 f6 ff ff       	call   10079c <debug_panic>
	assert(pp1 && pp1 != pp0);
  1010d5:	83 7d ec 00          	cmpl   $0x0,0xffffffec(%ebp)
  1010d9:	74 08                	je     1010e3 <mem_check+0x1a3>
  1010db:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  1010de:	3b 45 e8             	cmp    0xffffffe8(%ebp),%eax
  1010e1:	75 24                	jne    101107 <mem_check+0x1c7>
  1010e3:	c7 44 24 0c 6d ad 10 	movl   $0x10ad6d,0xc(%esp)
  1010ea:	00 
  1010eb:	c7 44 24 08 93 ac 10 	movl   $0x10ac93,0x8(%esp)
  1010f2:	00 
  1010f3:	c7 44 24 04 cb 00 00 	movl   $0xcb,0x4(%esp)
  1010fa:	00 
  1010fb:	c7 04 24 34 ac 10 00 	movl   $0x10ac34,(%esp)
  101102:	e8 95 f6 ff ff       	call   10079c <debug_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
  101107:	83 7d f0 00          	cmpl   $0x0,0xfffffff0(%ebp)
  10110b:	74 10                	je     10111d <mem_check+0x1dd>
  10110d:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  101110:	3b 45 ec             	cmp    0xffffffec(%ebp),%eax
  101113:	74 08                	je     10111d <mem_check+0x1dd>
  101115:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  101118:	3b 45 e8             	cmp    0xffffffe8(%ebp),%eax
  10111b:	75 24                	jne    101141 <mem_check+0x201>
  10111d:	c7 44 24 0c 80 ad 10 	movl   $0x10ad80,0xc(%esp)
  101124:	00 
  101125:	c7 44 24 08 93 ac 10 	movl   $0x10ac93,0x8(%esp)
  10112c:	00 
  10112d:	c7 44 24 04 cc 00 00 	movl   $0xcc,0x4(%esp)
  101134:	00 
  101135:	c7 04 24 34 ac 10 00 	movl   $0x10ac34,(%esp)
  10113c:	e8 5b f6 ff ff       	call   10079c <debug_panic>
        assert(mem_pi2phys(pp0) < mem_npage*PAGESIZE);
  101141:	8b 55 e8             	mov    0xffffffe8(%ebp),%edx
  101144:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  101149:	89 d1                	mov    %edx,%ecx
  10114b:	29 c1                	sub    %eax,%ecx
  10114d:	89 c8                	mov    %ecx,%eax
  10114f:	c1 e0 09             	shl    $0x9,%eax
  101152:	89 c2                	mov    %eax,%edx
  101154:	a1 44 fd 11 00       	mov    0x11fd44,%eax
  101159:	c1 e0 0c             	shl    $0xc,%eax
  10115c:	39 c2                	cmp    %eax,%edx
  10115e:	72 24                	jb     101184 <mem_check+0x244>
  101160:	c7 44 24 0c a0 ad 10 	movl   $0x10ada0,0xc(%esp)
  101167:	00 
  101168:	c7 44 24 08 93 ac 10 	movl   $0x10ac93,0x8(%esp)
  10116f:	00 
  101170:	c7 44 24 04 cd 00 00 	movl   $0xcd,0x4(%esp)
  101177:	00 
  101178:	c7 04 24 34 ac 10 00 	movl   $0x10ac34,(%esp)
  10117f:	e8 18 f6 ff ff       	call   10079c <debug_panic>
        assert(mem_pi2phys(pp1) < mem_npage*PAGESIZE);
  101184:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
  101187:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  10118c:	89 d1                	mov    %edx,%ecx
  10118e:	29 c1                	sub    %eax,%ecx
  101190:	89 c8                	mov    %ecx,%eax
  101192:	c1 e0 09             	shl    $0x9,%eax
  101195:	89 c2                	mov    %eax,%edx
  101197:	a1 44 fd 11 00       	mov    0x11fd44,%eax
  10119c:	c1 e0 0c             	shl    $0xc,%eax
  10119f:	39 c2                	cmp    %eax,%edx
  1011a1:	72 24                	jb     1011c7 <mem_check+0x287>
  1011a3:	c7 44 24 0c c8 ad 10 	movl   $0x10adc8,0xc(%esp)
  1011aa:	00 
  1011ab:	c7 44 24 08 93 ac 10 	movl   $0x10ac93,0x8(%esp)
  1011b2:	00 
  1011b3:	c7 44 24 04 ce 00 00 	movl   $0xce,0x4(%esp)
  1011ba:	00 
  1011bb:	c7 04 24 34 ac 10 00 	movl   $0x10ac34,(%esp)
  1011c2:	e8 d5 f5 ff ff       	call   10079c <debug_panic>
        assert(mem_pi2phys(pp2) < mem_npage*PAGESIZE);
  1011c7:	8b 55 f0             	mov    0xfffffff0(%ebp),%edx
  1011ca:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  1011cf:	89 d1                	mov    %edx,%ecx
  1011d1:	29 c1                	sub    %eax,%ecx
  1011d3:	89 c8                	mov    %ecx,%eax
  1011d5:	c1 e0 09             	shl    $0x9,%eax
  1011d8:	89 c2                	mov    %eax,%edx
  1011da:	a1 44 fd 11 00       	mov    0x11fd44,%eax
  1011df:	c1 e0 0c             	shl    $0xc,%eax
  1011e2:	39 c2                	cmp    %eax,%edx
  1011e4:	72 24                	jb     10120a <mem_check+0x2ca>
  1011e6:	c7 44 24 0c f0 ad 10 	movl   $0x10adf0,0xc(%esp)
  1011ed:	00 
  1011ee:	c7 44 24 08 93 ac 10 	movl   $0x10ac93,0x8(%esp)
  1011f5:	00 
  1011f6:	c7 44 24 04 cf 00 00 	movl   $0xcf,0x4(%esp)
  1011fd:	00 
  1011fe:	c7 04 24 34 ac 10 00 	movl   $0x10ac34,(%esp)
  101205:	e8 92 f5 ff ff       	call   10079c <debug_panic>

	// temporarily steal the rest of the free pages
	fl = mem_freelist;
  10120a:	a1 40 fd 11 00       	mov    0x11fd40,%eax
  10120f:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	mem_freelist = 0;
  101212:	c7 05 40 fd 11 00 00 	movl   $0x0,0x11fd40
  101219:	00 00 00 

	// should be no free memory
	assert(mem_alloc() == 0);
  10121c:	e8 5e fc ff ff       	call   100e7f <mem_alloc>
  101221:	85 c0                	test   %eax,%eax
  101223:	74 24                	je     101249 <mem_check+0x309>
  101225:	c7 44 24 0c 16 ae 10 	movl   $0x10ae16,0xc(%esp)
  10122c:	00 
  10122d:	c7 44 24 08 93 ac 10 	movl   $0x10ac93,0x8(%esp)
  101234:	00 
  101235:	c7 44 24 04 d6 00 00 	movl   $0xd6,0x4(%esp)
  10123c:	00 
  10123d:	c7 04 24 34 ac 10 00 	movl   $0x10ac34,(%esp)
  101244:	e8 53 f5 ff ff       	call   10079c <debug_panic>

        // free and re-allocate?
        mem_free(pp0);
  101249:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  10124c:	89 04 24             	mov    %eax,(%esp)
  10124f:	e8 6f fc ff ff       	call   100ec3 <mem_free>
        mem_free(pp1);
  101254:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  101257:	89 04 24             	mov    %eax,(%esp)
  10125a:	e8 64 fc ff ff       	call   100ec3 <mem_free>
        mem_free(pp2);
  10125f:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  101262:	89 04 24             	mov    %eax,(%esp)
  101265:	e8 59 fc ff ff       	call   100ec3 <mem_free>
	pp0 = pp1 = pp2 = 0;
  10126a:	c7 45 f0 00 00 00 00 	movl   $0x0,0xfffffff0(%ebp)
  101271:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  101274:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  101277:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  10127a:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
	pp0 = mem_alloc(); assert(pp0 != 0);
  10127d:	e8 fd fb ff ff       	call   100e7f <mem_alloc>
  101282:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  101285:	83 7d e8 00          	cmpl   $0x0,0xffffffe8(%ebp)
  101289:	75 24                	jne    1012af <mem_check+0x36f>
  10128b:	c7 44 24 0c 4e ad 10 	movl   $0x10ad4e,0xc(%esp)
  101292:	00 
  101293:	c7 44 24 08 93 ac 10 	movl   $0x10ac93,0x8(%esp)
  10129a:	00 
  10129b:	c7 44 24 04 dd 00 00 	movl   $0xdd,0x4(%esp)
  1012a2:	00 
  1012a3:	c7 04 24 34 ac 10 00 	movl   $0x10ac34,(%esp)
  1012aa:	e8 ed f4 ff ff       	call   10079c <debug_panic>
	pp1 = mem_alloc(); assert(pp1 != 0);
  1012af:	e8 cb fb ff ff       	call   100e7f <mem_alloc>
  1012b4:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  1012b7:	83 7d ec 00          	cmpl   $0x0,0xffffffec(%ebp)
  1012bb:	75 24                	jne    1012e1 <mem_check+0x3a1>
  1012bd:	c7 44 24 0c 57 ad 10 	movl   $0x10ad57,0xc(%esp)
  1012c4:	00 
  1012c5:	c7 44 24 08 93 ac 10 	movl   $0x10ac93,0x8(%esp)
  1012cc:	00 
  1012cd:	c7 44 24 04 de 00 00 	movl   $0xde,0x4(%esp)
  1012d4:	00 
  1012d5:	c7 04 24 34 ac 10 00 	movl   $0x10ac34,(%esp)
  1012dc:	e8 bb f4 ff ff       	call   10079c <debug_panic>
	pp2 = mem_alloc(); assert(pp2 != 0);
  1012e1:	e8 99 fb ff ff       	call   100e7f <mem_alloc>
  1012e6:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
  1012e9:	83 7d f0 00          	cmpl   $0x0,0xfffffff0(%ebp)
  1012ed:	75 24                	jne    101313 <mem_check+0x3d3>
  1012ef:	c7 44 24 0c 60 ad 10 	movl   $0x10ad60,0xc(%esp)
  1012f6:	00 
  1012f7:	c7 44 24 08 93 ac 10 	movl   $0x10ac93,0x8(%esp)
  1012fe:	00 
  1012ff:	c7 44 24 04 df 00 00 	movl   $0xdf,0x4(%esp)
  101306:	00 
  101307:	c7 04 24 34 ac 10 00 	movl   $0x10ac34,(%esp)
  10130e:	e8 89 f4 ff ff       	call   10079c <debug_panic>
	assert(pp0);
  101313:	83 7d e8 00          	cmpl   $0x0,0xffffffe8(%ebp)
  101317:	75 24                	jne    10133d <mem_check+0x3fd>
  101319:	c7 44 24 0c 69 ad 10 	movl   $0x10ad69,0xc(%esp)
  101320:	00 
  101321:	c7 44 24 08 93 ac 10 	movl   $0x10ac93,0x8(%esp)
  101328:	00 
  101329:	c7 44 24 04 e0 00 00 	movl   $0xe0,0x4(%esp)
  101330:	00 
  101331:	c7 04 24 34 ac 10 00 	movl   $0x10ac34,(%esp)
  101338:	e8 5f f4 ff ff       	call   10079c <debug_panic>
	assert(pp1 && pp1 != pp0);
  10133d:	83 7d ec 00          	cmpl   $0x0,0xffffffec(%ebp)
  101341:	74 08                	je     10134b <mem_check+0x40b>
  101343:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  101346:	3b 45 e8             	cmp    0xffffffe8(%ebp),%eax
  101349:	75 24                	jne    10136f <mem_check+0x42f>
  10134b:	c7 44 24 0c 6d ad 10 	movl   $0x10ad6d,0xc(%esp)
  101352:	00 
  101353:	c7 44 24 08 93 ac 10 	movl   $0x10ac93,0x8(%esp)
  10135a:	00 
  10135b:	c7 44 24 04 e1 00 00 	movl   $0xe1,0x4(%esp)
  101362:	00 
  101363:	c7 04 24 34 ac 10 00 	movl   $0x10ac34,(%esp)
  10136a:	e8 2d f4 ff ff       	call   10079c <debug_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
  10136f:	83 7d f0 00          	cmpl   $0x0,0xfffffff0(%ebp)
  101373:	74 10                	je     101385 <mem_check+0x445>
  101375:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  101378:	3b 45 ec             	cmp    0xffffffec(%ebp),%eax
  10137b:	74 08                	je     101385 <mem_check+0x445>
  10137d:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  101380:	3b 45 e8             	cmp    0xffffffe8(%ebp),%eax
  101383:	75 24                	jne    1013a9 <mem_check+0x469>
  101385:	c7 44 24 0c 80 ad 10 	movl   $0x10ad80,0xc(%esp)
  10138c:	00 
  10138d:	c7 44 24 08 93 ac 10 	movl   $0x10ac93,0x8(%esp)
  101394:	00 
  101395:	c7 44 24 04 e2 00 00 	movl   $0xe2,0x4(%esp)
  10139c:	00 
  10139d:	c7 04 24 34 ac 10 00 	movl   $0x10ac34,(%esp)
  1013a4:	e8 f3 f3 ff ff       	call   10079c <debug_panic>
	assert(mem_alloc() == 0);
  1013a9:	e8 d1 fa ff ff       	call   100e7f <mem_alloc>
  1013ae:	85 c0                	test   %eax,%eax
  1013b0:	74 24                	je     1013d6 <mem_check+0x496>
  1013b2:	c7 44 24 0c 16 ae 10 	movl   $0x10ae16,0xc(%esp)
  1013b9:	00 
  1013ba:	c7 44 24 08 93 ac 10 	movl   $0x10ac93,0x8(%esp)
  1013c1:	00 
  1013c2:	c7 44 24 04 e3 00 00 	movl   $0xe3,0x4(%esp)
  1013c9:	00 
  1013ca:	c7 04 24 34 ac 10 00 	movl   $0x10ac34,(%esp)
  1013d1:	e8 c6 f3 ff ff       	call   10079c <debug_panic>

	// give free list back
	mem_freelist = fl;
  1013d6:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  1013d9:	a3 40 fd 11 00       	mov    %eax,0x11fd40

	// free the pages we took
	mem_free(pp0);
  1013de:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  1013e1:	89 04 24             	mov    %eax,(%esp)
  1013e4:	e8 da fa ff ff       	call   100ec3 <mem_free>
	mem_free(pp1);
  1013e9:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  1013ec:	89 04 24             	mov    %eax,(%esp)
  1013ef:	e8 cf fa ff ff       	call   100ec3 <mem_free>
	mem_free(pp2);
  1013f4:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  1013f7:	89 04 24             	mov    %eax,(%esp)
  1013fa:	e8 c4 fa ff ff       	call   100ec3 <mem_free>

	cprintf("mem_check() succeeded!\n");
  1013ff:	c7 04 24 27 ae 10 00 	movl   $0x10ae27,(%esp)
  101406:	e8 9e 8e 00 00       	call   10a2a9 <cprintf>
}
  10140b:	c9                   	leave  
  10140c:	c3                   	ret    
  10140d:	90                   	nop    
  10140e:	90                   	nop    
  10140f:	90                   	nop    

00101410 <cpu_init>:
};


void cpu_init()
{
  101410:	55                   	push   %ebp
  101411:	89 e5                	mov    %esp,%ebp
  101413:	53                   	push   %ebx
  101414:	83 ec 14             	sub    $0x14,%esp
	cpu *c = cpu_cur();
  101417:	e8 23 01 00 00       	call   10153f <cpu_cur>
  10141c:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)

  c->tss.ts_esp0 = (uint32_t) c->kstackhi;
  10141f:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  101422:	05 00 10 00 00       	add    $0x1000,%eax
  101427:	89 c2                	mov    %eax,%edx
  101429:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  10142c:	89 50 3c             	mov    %edx,0x3c(%eax)
  c->tss.ts_ss0 = CPU_GDT_KDATA;
  10142f:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  101432:	66 c7 40 40 10 00    	movw   $0x10,0x40(%eax)

  c->gdt[CPU_GDT_TSS >> 3] = SEGDESC16(0, STS_T32A, (uint32_t) (&c->tss),
  101438:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  10143b:	83 c0 38             	add    $0x38,%eax
  10143e:	89 c2                	mov    %eax,%edx
  101440:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  101443:	83 c0 38             	add    $0x38,%eax
  101446:	c1 e8 10             	shr    $0x10,%eax
  101449:	89 c1                	mov    %eax,%ecx
  10144b:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  10144e:	83 c0 38             	add    $0x38,%eax
  101451:	c1 e8 18             	shr    $0x18,%eax
  101454:	89 c3                	mov    %eax,%ebx
  101456:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  101459:	66 c7 40 30 67 00    	movw   $0x67,0x30(%eax)
  10145f:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  101462:	66 89 50 32          	mov    %dx,0x32(%eax)
  101466:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  101469:	88 48 34             	mov    %cl,0x34(%eax)
  10146c:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  10146f:	0f b6 42 35          	movzbl 0x35(%edx),%eax
  101473:	83 e0 f0             	and    $0xfffffff0,%eax
  101476:	83 c8 09             	or     $0x9,%eax
  101479:	88 42 35             	mov    %al,0x35(%edx)
  10147c:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  10147f:	0f b6 42 35          	movzbl 0x35(%edx),%eax
  101483:	83 e0 ef             	and    $0xffffffef,%eax
  101486:	88 42 35             	mov    %al,0x35(%edx)
  101489:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  10148c:	0f b6 42 35          	movzbl 0x35(%edx),%eax
  101490:	83 e0 9f             	and    $0xffffff9f,%eax
  101493:	88 42 35             	mov    %al,0x35(%edx)
  101496:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  101499:	0f b6 42 35          	movzbl 0x35(%edx),%eax
  10149d:	83 c8 80             	or     $0xffffff80,%eax
  1014a0:	88 42 35             	mov    %al,0x35(%edx)
  1014a3:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  1014a6:	0f b6 42 36          	movzbl 0x36(%edx),%eax
  1014aa:	83 e0 f0             	and    $0xfffffff0,%eax
  1014ad:	88 42 36             	mov    %al,0x36(%edx)
  1014b0:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  1014b3:	0f b6 42 36          	movzbl 0x36(%edx),%eax
  1014b7:	83 e0 ef             	and    $0xffffffef,%eax
  1014ba:	88 42 36             	mov    %al,0x36(%edx)
  1014bd:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  1014c0:	0f b6 42 36          	movzbl 0x36(%edx),%eax
  1014c4:	83 e0 df             	and    $0xffffffdf,%eax
  1014c7:	88 42 36             	mov    %al,0x36(%edx)
  1014ca:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  1014cd:	0f b6 42 36          	movzbl 0x36(%edx),%eax
  1014d1:	83 c8 40             	or     $0x40,%eax
  1014d4:	88 42 36             	mov    %al,0x36(%edx)
  1014d7:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  1014da:	0f b6 42 36          	movzbl 0x36(%edx),%eax
  1014de:	83 e0 7f             	and    $0x7f,%eax
  1014e1:	88 42 36             	mov    %al,0x36(%edx)
  1014e4:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  1014e7:	88 58 37             	mov    %bl,0x37(%eax)
                              sizeof(taskstate)-1, 0);

	// Load the GDT
	struct pseudodesc gdt_pd = {
		sizeof(c->gdt) - 1, (uint32_t) c->gdt };
  1014ea:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  1014ed:	66 c7 45 ee 37 00    	movw   $0x37,0xffffffee(%ebp)
  1014f3:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
	asm volatile("lgdt %0" : : "m" (gdt_pd));
  1014f6:	0f 01 55 ee          	lgdtl  0xffffffee(%ebp)

	// Reload all segment registers.
	asm volatile("movw %%ax,%%gs" :: "a" (CPU_GDT_UDATA|3));
  1014fa:	b8 23 00 00 00       	mov    $0x23,%eax
  1014ff:	8e e8                	movl   %eax,%gs
	asm volatile("movw %%ax,%%fs" :: "a" (CPU_GDT_UDATA|3));
  101501:	b8 23 00 00 00       	mov    $0x23,%eax
  101506:	8e e0                	movl   %eax,%fs
	asm volatile("movw %%ax,%%es" :: "a" (CPU_GDT_KDATA));
  101508:	b8 10 00 00 00       	mov    $0x10,%eax
  10150d:	8e c0                	movl   %eax,%es
	asm volatile("movw %%ax,%%ds" :: "a" (CPU_GDT_KDATA));
  10150f:	b8 10 00 00 00       	mov    $0x10,%eax
  101514:	8e d8                	movl   %eax,%ds
	asm volatile("movw %%ax,%%ss" :: "a" (CPU_GDT_KDATA));
  101516:	b8 10 00 00 00       	mov    $0x10,%eax
  10151b:	8e d0                	movl   %eax,%ss
	asm volatile("ljmp %0,$1f\n 1:\n" :: "i" (CPU_GDT_KCODE)); // reload CS
  10151d:	ea 24 15 10 00 08 00 	ljmp   $0x8,$0x101524

	// We don't need an LDT.
	asm volatile("lldt %%ax" :: "a" (0));
  101524:	b8 00 00 00 00       	mov    $0x0,%eax
  101529:	0f 00 d0             	lldt   %ax
  10152c:	66 c7 45 fa 30 00    	movw   $0x30,0xfffffffa(%ebp)

static gcc_inline void
ltr(uint16_t sel)
{
	__asm __volatile("ltr %0" : : "r" (sel));
  101532:	0f b7 45 fa          	movzwl 0xfffffffa(%ebp),%eax
  101536:	0f 00 d8             	ltr    %ax
  ltr(CPU_GDT_TSS);
}
  101539:	83 c4 14             	add    $0x14,%esp
  10153c:	5b                   	pop    %ebx
  10153d:	5d                   	pop    %ebp
  10153e:	c3                   	ret    

0010153f <cpu_cur>:

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  10153f:	55                   	push   %ebp
  101540:	89 e5                	mov    %esp,%ebp
  101542:	83 ec 28             	sub    $0x28,%esp
static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  101545:	89 65 fc             	mov    %esp,0xfffffffc(%ebp)
        return esp;
  101548:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  10154b:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  10154e:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  101551:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  101556:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	assert(c->magic == CPU_MAGIC);
  101559:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  10155c:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  101562:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  101567:	74 24                	je     10158d <cpu_cur+0x4e>
  101569:	c7 44 24 0c 3f ae 10 	movl   $0x10ae3f,0xc(%esp)
  101570:	00 
  101571:	c7 44 24 08 55 ae 10 	movl   $0x10ae55,0x8(%esp)
  101578:	00 
  101579:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  101580:	00 
  101581:	c7 04 24 6a ae 10 00 	movl   $0x10ae6a,(%esp)
  101588:	e8 0f f2 ff ff       	call   10079c <debug_panic>
	return c;
  10158d:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
}
  101590:	c9                   	leave  
  101591:	c3                   	ret    

00101592 <cpu_alloc>:

// Allocate an additional cpu struct representing a non-bootstrap processor.
cpu *
cpu_alloc(void)
{
  101592:	55                   	push   %ebp
  101593:	89 e5                	mov    %esp,%ebp
  101595:	83 ec 28             	sub    $0x28,%esp
	// Pointer to the cpu.next pointer of the last CPU on the list,
	// for chaining on new CPUs in cpu_alloc().  Note: static.
	static cpu **cpu_tail = &cpu_boot.next;

	pageinfo *pi = mem_alloc();
  101598:	e8 e2 f8 ff ff       	call   100e7f <mem_alloc>
  10159d:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
	assert(pi != 0);	// shouldn't be out of memory just yet!
  1015a0:	83 7d f8 00          	cmpl   $0x0,0xfffffff8(%ebp)
  1015a4:	75 24                	jne    1015ca <cpu_alloc+0x38>
  1015a6:	c7 44 24 0c 77 ae 10 	movl   $0x10ae77,0xc(%esp)
  1015ad:	00 
  1015ae:	c7 44 24 08 55 ae 10 	movl   $0x10ae55,0x8(%esp)
  1015b5:	00 
  1015b6:	c7 44 24 04 5e 00 00 	movl   $0x5e,0x4(%esp)
  1015bd:	00 
  1015be:	c7 04 24 7f ae 10 00 	movl   $0x10ae7f,(%esp)
  1015c5:	e8 d2 f1 ff ff       	call   10079c <debug_panic>

	cpu *c = (cpu*) mem_pi2ptr(pi);
  1015ca:	8b 55 f8             	mov    0xfffffff8(%ebp),%edx
  1015cd:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  1015d2:	89 d1                	mov    %edx,%ecx
  1015d4:	29 c1                	sub    %eax,%ecx
  1015d6:	89 c8                	mov    %ecx,%eax
  1015d8:	c1 e0 09             	shl    $0x9,%eax
  1015db:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)

	// Clear the whole page for good measure: cpu struct and kernel stack
	memset(c, 0, PAGESIZE);
  1015de:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  1015e5:	00 
  1015e6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1015ed:	00 
  1015ee:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  1015f1:	89 04 24             	mov    %eax,(%esp)
  1015f4:	e8 a8 8e 00 00       	call   10a4a1 <memset>

	// Now we need to initialize the new cpu struct
	// just to the same degree that cpu_boot was statically initialized.
	// The rest will be filled in by the CPU itself
	// when it starts up and calls cpu_init().

	// Initialize the new cpu's GDT by copying from the cpu_boot.
	// The TSS descriptor will be filled in later by cpu_init().
	assert(sizeof(c->gdt) == sizeof(segdesc) * CPU_GDT_NDESC);
	memmove(c->gdt, cpu_boot.gdt, sizeof(c->gdt));
  1015f9:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  1015fc:	c7 44 24 08 38 00 00 	movl   $0x38,0x8(%esp)
  101603:	00 
  101604:	c7 44 24 04 00 d0 10 	movl   $0x10d000,0x4(%esp)
  10160b:	00 
  10160c:	89 04 24             	mov    %eax,(%esp)
  10160f:	e8 06 8f 00 00       	call   10a51a <memmove>

	// Magic verification tag for stack overflow/cpu corruption checking
	c->magic = CPU_MAGIC;
  101614:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  101617:	c7 80 b8 00 00 00 32 	movl   $0x98765432,0xb8(%eax)
  10161e:	54 76 98 

	// Chain the new CPU onto the tail of the list.
	*cpu_tail = c;
  101621:	8b 15 00 e0 10 00    	mov    0x10e000,%edx
  101627:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  10162a:	89 02                	mov    %eax,(%edx)
	cpu_tail = &c->next;
  10162c:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  10162f:	05 a8 00 00 00       	add    $0xa8,%eax
  101634:	a3 00 e0 10 00       	mov    %eax,0x10e000

	return c;
  101639:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
}
  10163c:	c9                   	leave  
  10163d:	c3                   	ret    

0010163e <cpu_bootothers>:

void
cpu_bootothers(void)
{
  10163e:	55                   	push   %ebp
  10163f:	89 e5                	mov    %esp,%ebp
  101641:	83 ec 28             	sub    $0x28,%esp
	extern uint8_t _binary_obj_boot_bootother_start[],
			_binary_obj_boot_bootother_size[];

	if (!cpu_onboot()) {
  101644:	e8 b6 00 00 00       	call   1016ff <cpu_onboot>
  101649:	85 c0                	test   %eax,%eax
  10164b:	75 1f                	jne    10166c <cpu_bootothers+0x2e>
		// Just inform the boot cpu we've booted.
		xchg(&cpu_cur()->booted, 1);
  10164d:	e8 ed fe ff ff       	call   10153f <cpu_cur>
  101652:	05 b0 00 00 00       	add    $0xb0,%eax
  101657:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  10165e:	00 
  10165f:	89 04 24             	mov    %eax,(%esp)
  101662:	e8 b0 00 00 00       	call   101717 <xchg>
		return;
  101667:	e9 91 00 00 00       	jmp    1016fd <cpu_bootothers+0xbf>
	}

	// Write bootstrap code to unused memory at 0x1000.
	uint8_t *code = (uint8_t*)0x1000;
  10166c:	c7 45 f8 00 10 00 00 	movl   $0x1000,0xfffffff8(%ebp)
	memmove(code, _binary_obj_boot_bootother_start,
  101673:	b8 6a 00 00 00       	mov    $0x6a,%eax
  101678:	89 44 24 08          	mov    %eax,0x8(%esp)
  10167c:	c7 44 24 04 13 91 11 	movl   $0x119113,0x4(%esp)
  101683:	00 
  101684:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  101687:	89 04 24             	mov    %eax,(%esp)
  10168a:	e8 8b 8e 00 00       	call   10a51a <memmove>
		(uint32_t)_binary_obj_boot_bootother_size);

	cpu *c;
	for(c = &cpu_boot; c; c = c->next){
  10168f:	c7 45 fc 00 d0 10 00 	movl   $0x10d000,0xfffffffc(%ebp)
  101696:	eb 5f                	jmp    1016f7 <cpu_bootothers+0xb9>
		if(c == cpu_cur())  // We''ve started already.
  101698:	e8 a2 fe ff ff       	call   10153f <cpu_cur>
  10169d:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  1016a0:	74 49                	je     1016eb <cpu_bootothers+0xad>
			continue;

		// Fill in %esp, %eip and start code on cpu.
		*(void**)(code-4) = c->kstackhi;
  1016a2:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1016a5:	83 e8 04             	sub    $0x4,%eax
  1016a8:	89 c2                	mov    %eax,%edx
  1016aa:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  1016ad:	05 00 10 00 00       	add    $0x1000,%eax
  1016b2:	89 02                	mov    %eax,(%edx)
		*(void**)(code-8) = init;
  1016b4:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1016b7:	83 e8 08             	sub    $0x8,%eax
  1016ba:	c7 00 28 00 10 00    	movl   $0x100028,(%eax)
		lapic_startcpu(c->id, (uint32_t)code);
  1016c0:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1016c3:	89 c2                	mov    %eax,%edx
  1016c5:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  1016c8:	0f b6 80 ac 00 00 00 	movzbl 0xac(%eax),%eax
  1016cf:	0f b6 c0             	movzbl %al,%eax
  1016d2:	89 54 24 04          	mov    %edx,0x4(%esp)
  1016d6:	89 04 24             	mov    %eax,(%esp)
  1016d9:	e8 6c 81 00 00       	call   10984a <lapic_startcpu>

		// Wait for cpu to get through bootstrap.
		while(c->booted == 0)
  1016de:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  1016e1:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
  1016e7:	85 c0                	test   %eax,%eax
  1016e9:	74 f3                	je     1016de <cpu_bootothers+0xa0>
  1016eb:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  1016ee:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
  1016f4:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  1016f7:	83 7d fc 00          	cmpl   $0x0,0xfffffffc(%ebp)
  1016fb:	75 9b                	jne    101698 <cpu_bootothers+0x5a>
			;
	}
}
  1016fd:	c9                   	leave  
  1016fe:	c3                   	ret    

001016ff <cpu_onboot>:
}

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  1016ff:	55                   	push   %ebp
  101700:	89 e5                	mov    %esp,%ebp
  101702:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  101705:	e8 35 fe ff ff       	call   10153f <cpu_cur>
  10170a:	3d 00 d0 10 00       	cmp    $0x10d000,%eax
  10170f:	0f 94 c0             	sete   %al
  101712:	0f b6 c0             	movzbl %al,%eax
}
  101715:	c9                   	leave  
  101716:	c3                   	ret    

00101717 <xchg>:

// Atomically set *addr to newval and return the old value of *addr.
static inline uint32_t
xchg(volatile uint32_t *addr, uint32_t newval)
{
  101717:	55                   	push   %ebp
  101718:	89 e5                	mov    %esp,%ebp
  10171a:	53                   	push   %ebx
  10171b:	83 ec 14             	sub    $0x14,%esp
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
  10171e:	8b 4d 08             	mov    0x8(%ebp),%ecx
  101721:	8b 55 0c             	mov    0xc(%ebp),%edx
  101724:	8b 45 08             	mov    0x8(%ebp),%eax
  101727:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  10172a:	89 d0                	mov    %edx,%eax
  10172c:	8b 5d e8             	mov    0xffffffe8(%ebp),%ebx
  10172f:	f0 87 01             	lock xchg %eax,(%ecx)
  101732:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  101735:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  101738:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
	       "+m" (*addr), "=a" (result) :
	       "1" (newval) :
	       "cc");
	return result;
  10173b:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
}
  10173e:	83 c4 14             	add    $0x14,%esp
  101741:	5b                   	pop    %ebx
  101742:	5d                   	pop    %ebp
  101743:	c3                   	ret    

00101744 <trap_init_idt>:


static void
trap_init_idt(void)
{
  101744:	55                   	push   %ebp
  101745:	89 e5                	mov    %esp,%ebp
	extern segdesc gdt[];
  extern char trap_divide;
  extern char trap_nmi;
  extern char trap_brkpt;
  extern char trap_oflow;
  extern char trap_bound;
  extern char trap_illop;
  extern char trap_device;
  extern char trap_dblflt;
  extern char trap_tss;
  extern char trap_segnp;
  extern char trap_stack;
  extern char trap_gpflt;
  extern char trap_pgflt;
  extern char trap_fperr;
  extern char trap_align;
  extern char trap_mchk;
  extern char trap_simd;
  extern char trap_secev;
  extern char trap_irq0;
  extern char trap_syscall;
  extern char trap_ltimer;
  extern char trap_lerror;
  extern char trap_default;
  extern char trap_icnt;

// - istrap: 1 for a trap (= exception) gate, 0 for an interrupt gate.
// - sel: Code segment selector for interrupt/trap handler
// - off: Offset in code segment for interrupt/trap handler
// - dpl: Descriptor Privilege Level -
//	  the privilege level required for software to invoke
//	  this interrupt/trap gate explicitly using an int instruction.
//        gate           istrap sel            off           dpl
  SETGATE(idt[T_DIVIDE], 0,     CPU_GDT_KCODE, &trap_divide, 0);
  101747:	b8 e0 28 10 00       	mov    $0x1028e0,%eax
  10174c:	66 a3 20 b2 11 00    	mov    %ax,0x11b220
  101752:	66 c7 05 22 b2 11 00 	movw   $0x8,0x11b222
  101759:	08 00 
  10175b:	0f b6 05 24 b2 11 00 	movzbl 0x11b224,%eax
  101762:	83 e0 e0             	and    $0xffffffe0,%eax
  101765:	a2 24 b2 11 00       	mov    %al,0x11b224
  10176a:	0f b6 05 24 b2 11 00 	movzbl 0x11b224,%eax
  101771:	83 e0 1f             	and    $0x1f,%eax
  101774:	a2 24 b2 11 00       	mov    %al,0x11b224
  101779:	0f b6 05 25 b2 11 00 	movzbl 0x11b225,%eax
  101780:	83 e0 f0             	and    $0xfffffff0,%eax
  101783:	83 c8 0e             	or     $0xe,%eax
  101786:	a2 25 b2 11 00       	mov    %al,0x11b225
  10178b:	0f b6 05 25 b2 11 00 	movzbl 0x11b225,%eax
  101792:	83 e0 ef             	and    $0xffffffef,%eax
  101795:	a2 25 b2 11 00       	mov    %al,0x11b225
  10179a:	0f b6 05 25 b2 11 00 	movzbl 0x11b225,%eax
  1017a1:	83 e0 9f             	and    $0xffffff9f,%eax
  1017a4:	a2 25 b2 11 00       	mov    %al,0x11b225
  1017a9:	0f b6 05 25 b2 11 00 	movzbl 0x11b225,%eax
  1017b0:	83 c8 80             	or     $0xffffff80,%eax
  1017b3:	a2 25 b2 11 00       	mov    %al,0x11b225
  1017b8:	b8 e0 28 10 00       	mov    $0x1028e0,%eax
  1017bd:	c1 e8 10             	shr    $0x10,%eax
  1017c0:	66 a3 26 b2 11 00    	mov    %ax,0x11b226
  SETGATE(idt[T_NMI],    0,     CPU_GDT_KCODE, &trap_nmi,    0);
  1017c6:	b8 ea 28 10 00       	mov    $0x1028ea,%eax
  1017cb:	66 a3 30 b2 11 00    	mov    %ax,0x11b230
  1017d1:	66 c7 05 32 b2 11 00 	movw   $0x8,0x11b232
  1017d8:	08 00 
  1017da:	0f b6 05 34 b2 11 00 	movzbl 0x11b234,%eax
  1017e1:	83 e0 e0             	and    $0xffffffe0,%eax
  1017e4:	a2 34 b2 11 00       	mov    %al,0x11b234
  1017e9:	0f b6 05 34 b2 11 00 	movzbl 0x11b234,%eax
  1017f0:	83 e0 1f             	and    $0x1f,%eax
  1017f3:	a2 34 b2 11 00       	mov    %al,0x11b234
  1017f8:	0f b6 05 35 b2 11 00 	movzbl 0x11b235,%eax
  1017ff:	83 e0 f0             	and    $0xfffffff0,%eax
  101802:	83 c8 0e             	or     $0xe,%eax
  101805:	a2 35 b2 11 00       	mov    %al,0x11b235
  10180a:	0f b6 05 35 b2 11 00 	movzbl 0x11b235,%eax
  101811:	83 e0 ef             	and    $0xffffffef,%eax
  101814:	a2 35 b2 11 00       	mov    %al,0x11b235
  101819:	0f b6 05 35 b2 11 00 	movzbl 0x11b235,%eax
  101820:	83 e0 9f             	and    $0xffffff9f,%eax
  101823:	a2 35 b2 11 00       	mov    %al,0x11b235
  101828:	0f b6 05 35 b2 11 00 	movzbl 0x11b235,%eax
  10182f:	83 c8 80             	or     $0xffffff80,%eax
  101832:	a2 35 b2 11 00       	mov    %al,0x11b235
  101837:	b8 ea 28 10 00       	mov    $0x1028ea,%eax
  10183c:	c1 e8 10             	shr    $0x10,%eax
  10183f:	66 a3 36 b2 11 00    	mov    %ax,0x11b236
  SETGATE(idt[T_BRKPT],  0,     CPU_GDT_KCODE, &trap_brkpt,  3);
  101845:	b8 f4 28 10 00       	mov    $0x1028f4,%eax
  10184a:	66 a3 38 b2 11 00    	mov    %ax,0x11b238
  101850:	66 c7 05 3a b2 11 00 	movw   $0x8,0x11b23a
  101857:	08 00 
  101859:	0f b6 05 3c b2 11 00 	movzbl 0x11b23c,%eax
  101860:	83 e0 e0             	and    $0xffffffe0,%eax
  101863:	a2 3c b2 11 00       	mov    %al,0x11b23c
  101868:	0f b6 05 3c b2 11 00 	movzbl 0x11b23c,%eax
  10186f:	83 e0 1f             	and    $0x1f,%eax
  101872:	a2 3c b2 11 00       	mov    %al,0x11b23c
  101877:	0f b6 05 3d b2 11 00 	movzbl 0x11b23d,%eax
  10187e:	83 e0 f0             	and    $0xfffffff0,%eax
  101881:	83 c8 0e             	or     $0xe,%eax
  101884:	a2 3d b2 11 00       	mov    %al,0x11b23d
  101889:	0f b6 05 3d b2 11 00 	movzbl 0x11b23d,%eax
  101890:	83 e0 ef             	and    $0xffffffef,%eax
  101893:	a2 3d b2 11 00       	mov    %al,0x11b23d
  101898:	0f b6 05 3d b2 11 00 	movzbl 0x11b23d,%eax
  10189f:	83 c8 60             	or     $0x60,%eax
  1018a2:	a2 3d b2 11 00       	mov    %al,0x11b23d
  1018a7:	0f b6 05 3d b2 11 00 	movzbl 0x11b23d,%eax
  1018ae:	83 c8 80             	or     $0xffffff80,%eax
  1018b1:	a2 3d b2 11 00       	mov    %al,0x11b23d
  1018b6:	b8 f4 28 10 00       	mov    $0x1028f4,%eax
  1018bb:	c1 e8 10             	shr    $0x10,%eax
  1018be:	66 a3 3e b2 11 00    	mov    %ax,0x11b23e
  SETGATE(idt[T_OFLOW],  0,     CPU_GDT_KCODE, &trap_oflow,  3);
  1018c4:	b8 fe 28 10 00       	mov    $0x1028fe,%eax
  1018c9:	66 a3 40 b2 11 00    	mov    %ax,0x11b240
  1018cf:	66 c7 05 42 b2 11 00 	movw   $0x8,0x11b242
  1018d6:	08 00 
  1018d8:	0f b6 05 44 b2 11 00 	movzbl 0x11b244,%eax
  1018df:	83 e0 e0             	and    $0xffffffe0,%eax
  1018e2:	a2 44 b2 11 00       	mov    %al,0x11b244
  1018e7:	0f b6 05 44 b2 11 00 	movzbl 0x11b244,%eax
  1018ee:	83 e0 1f             	and    $0x1f,%eax
  1018f1:	a2 44 b2 11 00       	mov    %al,0x11b244
  1018f6:	0f b6 05 45 b2 11 00 	movzbl 0x11b245,%eax
  1018fd:	83 e0 f0             	and    $0xfffffff0,%eax
  101900:	83 c8 0e             	or     $0xe,%eax
  101903:	a2 45 b2 11 00       	mov    %al,0x11b245
  101908:	0f b6 05 45 b2 11 00 	movzbl 0x11b245,%eax
  10190f:	83 e0 ef             	and    $0xffffffef,%eax
  101912:	a2 45 b2 11 00       	mov    %al,0x11b245
  101917:	0f b6 05 45 b2 11 00 	movzbl 0x11b245,%eax
  10191e:	83 c8 60             	or     $0x60,%eax
  101921:	a2 45 b2 11 00       	mov    %al,0x11b245
  101926:	0f b6 05 45 b2 11 00 	movzbl 0x11b245,%eax
  10192d:	83 c8 80             	or     $0xffffff80,%eax
  101930:	a2 45 b2 11 00       	mov    %al,0x11b245
  101935:	b8 fe 28 10 00       	mov    $0x1028fe,%eax
  10193a:	c1 e8 10             	shr    $0x10,%eax
  10193d:	66 a3 46 b2 11 00    	mov    %ax,0x11b246
  SETGATE(idt[T_BOUND],  0,     CPU_GDT_KCODE, &trap_bound,  0);
  101943:	b8 08 29 10 00       	mov    $0x102908,%eax
  101948:	66 a3 48 b2 11 00    	mov    %ax,0x11b248
  10194e:	66 c7 05 4a b2 11 00 	movw   $0x8,0x11b24a
  101955:	08 00 
  101957:	0f b6 05 4c b2 11 00 	movzbl 0x11b24c,%eax
  10195e:	83 e0 e0             	and    $0xffffffe0,%eax
  101961:	a2 4c b2 11 00       	mov    %al,0x11b24c
  101966:	0f b6 05 4c b2 11 00 	movzbl 0x11b24c,%eax
  10196d:	83 e0 1f             	and    $0x1f,%eax
  101970:	a2 4c b2 11 00       	mov    %al,0x11b24c
  101975:	0f b6 05 4d b2 11 00 	movzbl 0x11b24d,%eax
  10197c:	83 e0 f0             	and    $0xfffffff0,%eax
  10197f:	83 c8 0e             	or     $0xe,%eax
  101982:	a2 4d b2 11 00       	mov    %al,0x11b24d
  101987:	0f b6 05 4d b2 11 00 	movzbl 0x11b24d,%eax
  10198e:	83 e0 ef             	and    $0xffffffef,%eax
  101991:	a2 4d b2 11 00       	mov    %al,0x11b24d
  101996:	0f b6 05 4d b2 11 00 	movzbl 0x11b24d,%eax
  10199d:	83 e0 9f             	and    $0xffffff9f,%eax
  1019a0:	a2 4d b2 11 00       	mov    %al,0x11b24d
  1019a5:	0f b6 05 4d b2 11 00 	movzbl 0x11b24d,%eax
  1019ac:	83 c8 80             	or     $0xffffff80,%eax
  1019af:	a2 4d b2 11 00       	mov    %al,0x11b24d
  1019b4:	b8 08 29 10 00       	mov    $0x102908,%eax
  1019b9:	c1 e8 10             	shr    $0x10,%eax
  1019bc:	66 a3 4e b2 11 00    	mov    %ax,0x11b24e
  SETGATE(idt[T_ILLOP],  0,     CPU_GDT_KCODE, &trap_illop,  0);
  1019c2:	b8 12 29 10 00       	mov    $0x102912,%eax
  1019c7:	66 a3 50 b2 11 00    	mov    %ax,0x11b250
  1019cd:	66 c7 05 52 b2 11 00 	movw   $0x8,0x11b252
  1019d4:	08 00 
  1019d6:	0f b6 05 54 b2 11 00 	movzbl 0x11b254,%eax
  1019dd:	83 e0 e0             	and    $0xffffffe0,%eax
  1019e0:	a2 54 b2 11 00       	mov    %al,0x11b254
  1019e5:	0f b6 05 54 b2 11 00 	movzbl 0x11b254,%eax
  1019ec:	83 e0 1f             	and    $0x1f,%eax
  1019ef:	a2 54 b2 11 00       	mov    %al,0x11b254
  1019f4:	0f b6 05 55 b2 11 00 	movzbl 0x11b255,%eax
  1019fb:	83 e0 f0             	and    $0xfffffff0,%eax
  1019fe:	83 c8 0e             	or     $0xe,%eax
  101a01:	a2 55 b2 11 00       	mov    %al,0x11b255
  101a06:	0f b6 05 55 b2 11 00 	movzbl 0x11b255,%eax
  101a0d:	83 e0 ef             	and    $0xffffffef,%eax
  101a10:	a2 55 b2 11 00       	mov    %al,0x11b255
  101a15:	0f b6 05 55 b2 11 00 	movzbl 0x11b255,%eax
  101a1c:	83 e0 9f             	and    $0xffffff9f,%eax
  101a1f:	a2 55 b2 11 00       	mov    %al,0x11b255
  101a24:	0f b6 05 55 b2 11 00 	movzbl 0x11b255,%eax
  101a2b:	83 c8 80             	or     $0xffffff80,%eax
  101a2e:	a2 55 b2 11 00       	mov    %al,0x11b255
  101a33:	b8 12 29 10 00       	mov    $0x102912,%eax
  101a38:	c1 e8 10             	shr    $0x10,%eax
  101a3b:	66 a3 56 b2 11 00    	mov    %ax,0x11b256
  SETGATE(idt[T_DEVICE], 0,     CPU_GDT_KCODE, &trap_device, 0);
  101a41:	b8 1c 29 10 00       	mov    $0x10291c,%eax
  101a46:	66 a3 58 b2 11 00    	mov    %ax,0x11b258
  101a4c:	66 c7 05 5a b2 11 00 	movw   $0x8,0x11b25a
  101a53:	08 00 
  101a55:	0f b6 05 5c b2 11 00 	movzbl 0x11b25c,%eax
  101a5c:	83 e0 e0             	and    $0xffffffe0,%eax
  101a5f:	a2 5c b2 11 00       	mov    %al,0x11b25c
  101a64:	0f b6 05 5c b2 11 00 	movzbl 0x11b25c,%eax
  101a6b:	83 e0 1f             	and    $0x1f,%eax
  101a6e:	a2 5c b2 11 00       	mov    %al,0x11b25c
  101a73:	0f b6 05 5d b2 11 00 	movzbl 0x11b25d,%eax
  101a7a:	83 e0 f0             	and    $0xfffffff0,%eax
  101a7d:	83 c8 0e             	or     $0xe,%eax
  101a80:	a2 5d b2 11 00       	mov    %al,0x11b25d
  101a85:	0f b6 05 5d b2 11 00 	movzbl 0x11b25d,%eax
  101a8c:	83 e0 ef             	and    $0xffffffef,%eax
  101a8f:	a2 5d b2 11 00       	mov    %al,0x11b25d
  101a94:	0f b6 05 5d b2 11 00 	movzbl 0x11b25d,%eax
  101a9b:	83 e0 9f             	and    $0xffffff9f,%eax
  101a9e:	a2 5d b2 11 00       	mov    %al,0x11b25d
  101aa3:	0f b6 05 5d b2 11 00 	movzbl 0x11b25d,%eax
  101aaa:	83 c8 80             	or     $0xffffff80,%eax
  101aad:	a2 5d b2 11 00       	mov    %al,0x11b25d
  101ab2:	b8 1c 29 10 00       	mov    $0x10291c,%eax
  101ab7:	c1 e8 10             	shr    $0x10,%eax
  101aba:	66 a3 5e b2 11 00    	mov    %ax,0x11b25e
  SETGATE(idt[T_DBLFLT], 0,     CPU_GDT_KCODE, &trap_dblflt, 0);
  101ac0:	b8 26 29 10 00       	mov    $0x102926,%eax
  101ac5:	66 a3 60 b2 11 00    	mov    %ax,0x11b260
  101acb:	66 c7 05 62 b2 11 00 	movw   $0x8,0x11b262
  101ad2:	08 00 
  101ad4:	0f b6 05 64 b2 11 00 	movzbl 0x11b264,%eax
  101adb:	83 e0 e0             	and    $0xffffffe0,%eax
  101ade:	a2 64 b2 11 00       	mov    %al,0x11b264
  101ae3:	0f b6 05 64 b2 11 00 	movzbl 0x11b264,%eax
  101aea:	83 e0 1f             	and    $0x1f,%eax
  101aed:	a2 64 b2 11 00       	mov    %al,0x11b264
  101af2:	0f b6 05 65 b2 11 00 	movzbl 0x11b265,%eax
  101af9:	83 e0 f0             	and    $0xfffffff0,%eax
  101afc:	83 c8 0e             	or     $0xe,%eax
  101aff:	a2 65 b2 11 00       	mov    %al,0x11b265
  101b04:	0f b6 05 65 b2 11 00 	movzbl 0x11b265,%eax
  101b0b:	83 e0 ef             	and    $0xffffffef,%eax
  101b0e:	a2 65 b2 11 00       	mov    %al,0x11b265
  101b13:	0f b6 05 65 b2 11 00 	movzbl 0x11b265,%eax
  101b1a:	83 e0 9f             	and    $0xffffff9f,%eax
  101b1d:	a2 65 b2 11 00       	mov    %al,0x11b265
  101b22:	0f b6 05 65 b2 11 00 	movzbl 0x11b265,%eax
  101b29:	83 c8 80             	or     $0xffffff80,%eax
  101b2c:	a2 65 b2 11 00       	mov    %al,0x11b265
  101b31:	b8 26 29 10 00       	mov    $0x102926,%eax
  101b36:	c1 e8 10             	shr    $0x10,%eax
  101b39:	66 a3 66 b2 11 00    	mov    %ax,0x11b266
  SETGATE(idt[T_TSS],    0,     CPU_GDT_KCODE, &trap_tss,    0);
  101b3f:	b8 30 29 10 00       	mov    $0x102930,%eax
  101b44:	66 a3 70 b2 11 00    	mov    %ax,0x11b270
  101b4a:	66 c7 05 72 b2 11 00 	movw   $0x8,0x11b272
  101b51:	08 00 
  101b53:	0f b6 05 74 b2 11 00 	movzbl 0x11b274,%eax
  101b5a:	83 e0 e0             	and    $0xffffffe0,%eax
  101b5d:	a2 74 b2 11 00       	mov    %al,0x11b274
  101b62:	0f b6 05 74 b2 11 00 	movzbl 0x11b274,%eax
  101b69:	83 e0 1f             	and    $0x1f,%eax
  101b6c:	a2 74 b2 11 00       	mov    %al,0x11b274
  101b71:	0f b6 05 75 b2 11 00 	movzbl 0x11b275,%eax
  101b78:	83 e0 f0             	and    $0xfffffff0,%eax
  101b7b:	83 c8 0e             	or     $0xe,%eax
  101b7e:	a2 75 b2 11 00       	mov    %al,0x11b275
  101b83:	0f b6 05 75 b2 11 00 	movzbl 0x11b275,%eax
  101b8a:	83 e0 ef             	and    $0xffffffef,%eax
  101b8d:	a2 75 b2 11 00       	mov    %al,0x11b275
  101b92:	0f b6 05 75 b2 11 00 	movzbl 0x11b275,%eax
  101b99:	83 e0 9f             	and    $0xffffff9f,%eax
  101b9c:	a2 75 b2 11 00       	mov    %al,0x11b275
  101ba1:	0f b6 05 75 b2 11 00 	movzbl 0x11b275,%eax
  101ba8:	83 c8 80             	or     $0xffffff80,%eax
  101bab:	a2 75 b2 11 00       	mov    %al,0x11b275
  101bb0:	b8 30 29 10 00       	mov    $0x102930,%eax
  101bb5:	c1 e8 10             	shr    $0x10,%eax
  101bb8:	66 a3 76 b2 11 00    	mov    %ax,0x11b276
  SETGATE(idt[T_GPFLT],  0,     CPU_GDT_KCODE, &trap_gpflt,  0);
  101bbe:	b8 48 29 10 00       	mov    $0x102948,%eax
  101bc3:	66 a3 88 b2 11 00    	mov    %ax,0x11b288
  101bc9:	66 c7 05 8a b2 11 00 	movw   $0x8,0x11b28a
  101bd0:	08 00 
  101bd2:	0f b6 05 8c b2 11 00 	movzbl 0x11b28c,%eax
  101bd9:	83 e0 e0             	and    $0xffffffe0,%eax
  101bdc:	a2 8c b2 11 00       	mov    %al,0x11b28c
  101be1:	0f b6 05 8c b2 11 00 	movzbl 0x11b28c,%eax
  101be8:	83 e0 1f             	and    $0x1f,%eax
  101beb:	a2 8c b2 11 00       	mov    %al,0x11b28c
  101bf0:	0f b6 05 8d b2 11 00 	movzbl 0x11b28d,%eax
  101bf7:	83 e0 f0             	and    $0xfffffff0,%eax
  101bfa:	83 c8 0e             	or     $0xe,%eax
  101bfd:	a2 8d b2 11 00       	mov    %al,0x11b28d
  101c02:	0f b6 05 8d b2 11 00 	movzbl 0x11b28d,%eax
  101c09:	83 e0 ef             	and    $0xffffffef,%eax
  101c0c:	a2 8d b2 11 00       	mov    %al,0x11b28d
  101c11:	0f b6 05 8d b2 11 00 	movzbl 0x11b28d,%eax
  101c18:	83 e0 9f             	and    $0xffffff9f,%eax
  101c1b:	a2 8d b2 11 00       	mov    %al,0x11b28d
  101c20:	0f b6 05 8d b2 11 00 	movzbl 0x11b28d,%eax
  101c27:	83 c8 80             	or     $0xffffff80,%eax
  101c2a:	a2 8d b2 11 00       	mov    %al,0x11b28d
  101c2f:	b8 48 29 10 00       	mov    $0x102948,%eax
  101c34:	c1 e8 10             	shr    $0x10,%eax
  101c37:	66 a3 8e b2 11 00    	mov    %ax,0x11b28e
  SETGATE(idt[T_PGFLT],  0,     CPU_GDT_KCODE, &trap_pgflt,  0);
  101c3d:	b8 50 29 10 00       	mov    $0x102950,%eax
  101c42:	66 a3 90 b2 11 00    	mov    %ax,0x11b290
  101c48:	66 c7 05 92 b2 11 00 	movw   $0x8,0x11b292
  101c4f:	08 00 
  101c51:	0f b6 05 94 b2 11 00 	movzbl 0x11b294,%eax
  101c58:	83 e0 e0             	and    $0xffffffe0,%eax
  101c5b:	a2 94 b2 11 00       	mov    %al,0x11b294
  101c60:	0f b6 05 94 b2 11 00 	movzbl 0x11b294,%eax
  101c67:	83 e0 1f             	and    $0x1f,%eax
  101c6a:	a2 94 b2 11 00       	mov    %al,0x11b294
  101c6f:	0f b6 05 95 b2 11 00 	movzbl 0x11b295,%eax
  101c76:	83 e0 f0             	and    $0xfffffff0,%eax
  101c79:	83 c8 0e             	or     $0xe,%eax
  101c7c:	a2 95 b2 11 00       	mov    %al,0x11b295
  101c81:	0f b6 05 95 b2 11 00 	movzbl 0x11b295,%eax
  101c88:	83 e0 ef             	and    $0xffffffef,%eax
  101c8b:	a2 95 b2 11 00       	mov    %al,0x11b295
  101c90:	0f b6 05 95 b2 11 00 	movzbl 0x11b295,%eax
  101c97:	83 e0 9f             	and    $0xffffff9f,%eax
  101c9a:	a2 95 b2 11 00       	mov    %al,0x11b295
  101c9f:	0f b6 05 95 b2 11 00 	movzbl 0x11b295,%eax
  101ca6:	83 c8 80             	or     $0xffffff80,%eax
  101ca9:	a2 95 b2 11 00       	mov    %al,0x11b295
  101cae:	b8 50 29 10 00       	mov    $0x102950,%eax
  101cb3:	c1 e8 10             	shr    $0x10,%eax
  101cb6:	66 a3 96 b2 11 00    	mov    %ax,0x11b296
  SETGATE(idt[T_FPERR],  0,     CPU_GDT_KCODE, &trap_fperr,  0);
  101cbc:	b8 58 29 10 00       	mov    $0x102958,%eax
  101cc1:	66 a3 a0 b2 11 00    	mov    %ax,0x11b2a0
  101cc7:	66 c7 05 a2 b2 11 00 	movw   $0x8,0x11b2a2
  101cce:	08 00 
  101cd0:	0f b6 05 a4 b2 11 00 	movzbl 0x11b2a4,%eax
  101cd7:	83 e0 e0             	and    $0xffffffe0,%eax
  101cda:	a2 a4 b2 11 00       	mov    %al,0x11b2a4
  101cdf:	0f b6 05 a4 b2 11 00 	movzbl 0x11b2a4,%eax
  101ce6:	83 e0 1f             	and    $0x1f,%eax
  101ce9:	a2 a4 b2 11 00       	mov    %al,0x11b2a4
  101cee:	0f b6 05 a5 b2 11 00 	movzbl 0x11b2a5,%eax
  101cf5:	83 e0 f0             	and    $0xfffffff0,%eax
  101cf8:	83 c8 0e             	or     $0xe,%eax
  101cfb:	a2 a5 b2 11 00       	mov    %al,0x11b2a5
  101d00:	0f b6 05 a5 b2 11 00 	movzbl 0x11b2a5,%eax
  101d07:	83 e0 ef             	and    $0xffffffef,%eax
  101d0a:	a2 a5 b2 11 00       	mov    %al,0x11b2a5
  101d0f:	0f b6 05 a5 b2 11 00 	movzbl 0x11b2a5,%eax
  101d16:	83 e0 9f             	and    $0xffffff9f,%eax
  101d19:	a2 a5 b2 11 00       	mov    %al,0x11b2a5
  101d1e:	0f b6 05 a5 b2 11 00 	movzbl 0x11b2a5,%eax
  101d25:	83 c8 80             	or     $0xffffff80,%eax
  101d28:	a2 a5 b2 11 00       	mov    %al,0x11b2a5
  101d2d:	b8 58 29 10 00       	mov    $0x102958,%eax
  101d32:	c1 e8 10             	shr    $0x10,%eax
  101d35:	66 a3 a6 b2 11 00    	mov    %ax,0x11b2a6
  SETGATE(idt[T_ALIGN],  0,     CPU_GDT_KCODE, &trap_align,  0);
  101d3b:	b8 62 29 10 00       	mov    $0x102962,%eax
  101d40:	66 a3 a8 b2 11 00    	mov    %ax,0x11b2a8
  101d46:	66 c7 05 aa b2 11 00 	movw   $0x8,0x11b2aa
  101d4d:	08 00 
  101d4f:	0f b6 05 ac b2 11 00 	movzbl 0x11b2ac,%eax
  101d56:	83 e0 e0             	and    $0xffffffe0,%eax
  101d59:	a2 ac b2 11 00       	mov    %al,0x11b2ac
  101d5e:	0f b6 05 ac b2 11 00 	movzbl 0x11b2ac,%eax
  101d65:	83 e0 1f             	and    $0x1f,%eax
  101d68:	a2 ac b2 11 00       	mov    %al,0x11b2ac
  101d6d:	0f b6 05 ad b2 11 00 	movzbl 0x11b2ad,%eax
  101d74:	83 e0 f0             	and    $0xfffffff0,%eax
  101d77:	83 c8 0e             	or     $0xe,%eax
  101d7a:	a2 ad b2 11 00       	mov    %al,0x11b2ad
  101d7f:	0f b6 05 ad b2 11 00 	movzbl 0x11b2ad,%eax
  101d86:	83 e0 ef             	and    $0xffffffef,%eax
  101d89:	a2 ad b2 11 00       	mov    %al,0x11b2ad
  101d8e:	0f b6 05 ad b2 11 00 	movzbl 0x11b2ad,%eax
  101d95:	83 e0 9f             	and    $0xffffff9f,%eax
  101d98:	a2 ad b2 11 00       	mov    %al,0x11b2ad
  101d9d:	0f b6 05 ad b2 11 00 	movzbl 0x11b2ad,%eax
  101da4:	83 c8 80             	or     $0xffffff80,%eax
  101da7:	a2 ad b2 11 00       	mov    %al,0x11b2ad
  101dac:	b8 62 29 10 00       	mov    $0x102962,%eax
  101db1:	c1 e8 10             	shr    $0x10,%eax
  101db4:	66 a3 ae b2 11 00    	mov    %ax,0x11b2ae
  SETGATE(idt[T_MCHK],   0,     CPU_GDT_KCODE, &trap_mchk,   0);
  101dba:	b8 6c 29 10 00       	mov    $0x10296c,%eax
  101dbf:	66 a3 b0 b2 11 00    	mov    %ax,0x11b2b0
  101dc5:	66 c7 05 b2 b2 11 00 	movw   $0x8,0x11b2b2
  101dcc:	08 00 
  101dce:	0f b6 05 b4 b2 11 00 	movzbl 0x11b2b4,%eax
  101dd5:	83 e0 e0             	and    $0xffffffe0,%eax
  101dd8:	a2 b4 b2 11 00       	mov    %al,0x11b2b4
  101ddd:	0f b6 05 b4 b2 11 00 	movzbl 0x11b2b4,%eax
  101de4:	83 e0 1f             	and    $0x1f,%eax
  101de7:	a2 b4 b2 11 00       	mov    %al,0x11b2b4
  101dec:	0f b6 05 b5 b2 11 00 	movzbl 0x11b2b5,%eax
  101df3:	83 e0 f0             	and    $0xfffffff0,%eax
  101df6:	83 c8 0e             	or     $0xe,%eax
  101df9:	a2 b5 b2 11 00       	mov    %al,0x11b2b5
  101dfe:	0f b6 05 b5 b2 11 00 	movzbl 0x11b2b5,%eax
  101e05:	83 e0 ef             	and    $0xffffffef,%eax
  101e08:	a2 b5 b2 11 00       	mov    %al,0x11b2b5
  101e0d:	0f b6 05 b5 b2 11 00 	movzbl 0x11b2b5,%eax
  101e14:	83 e0 9f             	and    $0xffffff9f,%eax
  101e17:	a2 b5 b2 11 00       	mov    %al,0x11b2b5
  101e1c:	0f b6 05 b5 b2 11 00 	movzbl 0x11b2b5,%eax
  101e23:	83 c8 80             	or     $0xffffff80,%eax
  101e26:	a2 b5 b2 11 00       	mov    %al,0x11b2b5
  101e2b:	b8 6c 29 10 00       	mov    $0x10296c,%eax
  101e30:	c1 e8 10             	shr    $0x10,%eax
  101e33:	66 a3 b6 b2 11 00    	mov    %ax,0x11b2b6
  SETGATE(idt[T_SIMD],   0,     CPU_GDT_KCODE, &trap_simd,   0);
  101e39:	b8 74 29 10 00       	mov    $0x102974,%eax
  101e3e:	66 a3 b8 b2 11 00    	mov    %ax,0x11b2b8
  101e44:	66 c7 05 ba b2 11 00 	movw   $0x8,0x11b2ba
  101e4b:	08 00 
  101e4d:	0f b6 05 bc b2 11 00 	movzbl 0x11b2bc,%eax
  101e54:	83 e0 e0             	and    $0xffffffe0,%eax
  101e57:	a2 bc b2 11 00       	mov    %al,0x11b2bc
  101e5c:	0f b6 05 bc b2 11 00 	movzbl 0x11b2bc,%eax
  101e63:	83 e0 1f             	and    $0x1f,%eax
  101e66:	a2 bc b2 11 00       	mov    %al,0x11b2bc
  101e6b:	0f b6 05 bd b2 11 00 	movzbl 0x11b2bd,%eax
  101e72:	83 e0 f0             	and    $0xfffffff0,%eax
  101e75:	83 c8 0e             	or     $0xe,%eax
  101e78:	a2 bd b2 11 00       	mov    %al,0x11b2bd
  101e7d:	0f b6 05 bd b2 11 00 	movzbl 0x11b2bd,%eax
  101e84:	83 e0 ef             	and    $0xffffffef,%eax
  101e87:	a2 bd b2 11 00       	mov    %al,0x11b2bd
  101e8c:	0f b6 05 bd b2 11 00 	movzbl 0x11b2bd,%eax
  101e93:	83 e0 9f             	and    $0xffffff9f,%eax
  101e96:	a2 bd b2 11 00       	mov    %al,0x11b2bd
  101e9b:	0f b6 05 bd b2 11 00 	movzbl 0x11b2bd,%eax
  101ea2:	83 c8 80             	or     $0xffffff80,%eax
  101ea5:	a2 bd b2 11 00       	mov    %al,0x11b2bd
  101eaa:	b8 74 29 10 00       	mov    $0x102974,%eax
  101eaf:	c1 e8 10             	shr    $0x10,%eax
  101eb2:	66 a3 be b2 11 00    	mov    %ax,0x11b2be
  SETGATE(idt[T_SECEV],  0,     CPU_GDT_KCODE, &trap_secev,  0);
  101eb8:	b8 7e 29 10 00       	mov    $0x10297e,%eax
  101ebd:	66 a3 10 b3 11 00    	mov    %ax,0x11b310
  101ec3:	66 c7 05 12 b3 11 00 	movw   $0x8,0x11b312
  101eca:	08 00 
  101ecc:	0f b6 05 14 b3 11 00 	movzbl 0x11b314,%eax
  101ed3:	83 e0 e0             	and    $0xffffffe0,%eax
  101ed6:	a2 14 b3 11 00       	mov    %al,0x11b314
  101edb:	0f b6 05 14 b3 11 00 	movzbl 0x11b314,%eax
  101ee2:	83 e0 1f             	and    $0x1f,%eax
  101ee5:	a2 14 b3 11 00       	mov    %al,0x11b314
  101eea:	0f b6 05 15 b3 11 00 	movzbl 0x11b315,%eax
  101ef1:	83 e0 f0             	and    $0xfffffff0,%eax
  101ef4:	83 c8 0e             	or     $0xe,%eax
  101ef7:	a2 15 b3 11 00       	mov    %al,0x11b315
  101efc:	0f b6 05 15 b3 11 00 	movzbl 0x11b315,%eax
  101f03:	83 e0 ef             	and    $0xffffffef,%eax
  101f06:	a2 15 b3 11 00       	mov    %al,0x11b315
  101f0b:	0f b6 05 15 b3 11 00 	movzbl 0x11b315,%eax
  101f12:	83 e0 9f             	and    $0xffffff9f,%eax
  101f15:	a2 15 b3 11 00       	mov    %al,0x11b315
  101f1a:	0f b6 05 15 b3 11 00 	movzbl 0x11b315,%eax
  101f21:	83 c8 80             	or     $0xffffff80,%eax
  101f24:	a2 15 b3 11 00       	mov    %al,0x11b315
  101f29:	b8 7e 29 10 00       	mov    $0x10297e,%eax
  101f2e:	c1 e8 10             	shr    $0x10,%eax
  101f31:	66 a3 16 b3 11 00    	mov    %ax,0x11b316
  SETGATE(idt[T_IRQ0],   0,     CPU_GDT_KCODE, &trap_irq0,   0);
  101f37:	b8 86 29 10 00       	mov    $0x102986,%eax
  101f3c:	66 a3 20 b3 11 00    	mov    %ax,0x11b320
  101f42:	66 c7 05 22 b3 11 00 	movw   $0x8,0x11b322
  101f49:	08 00 
  101f4b:	0f b6 05 24 b3 11 00 	movzbl 0x11b324,%eax
  101f52:	83 e0 e0             	and    $0xffffffe0,%eax
  101f55:	a2 24 b3 11 00       	mov    %al,0x11b324
  101f5a:	0f b6 05 24 b3 11 00 	movzbl 0x11b324,%eax
  101f61:	83 e0 1f             	and    $0x1f,%eax
  101f64:	a2 24 b3 11 00       	mov    %al,0x11b324
  101f69:	0f b6 05 25 b3 11 00 	movzbl 0x11b325,%eax
  101f70:	83 e0 f0             	and    $0xfffffff0,%eax
  101f73:	83 c8 0e             	or     $0xe,%eax
  101f76:	a2 25 b3 11 00       	mov    %al,0x11b325
  101f7b:	0f b6 05 25 b3 11 00 	movzbl 0x11b325,%eax
  101f82:	83 e0 ef             	and    $0xffffffef,%eax
  101f85:	a2 25 b3 11 00       	mov    %al,0x11b325
  101f8a:	0f b6 05 25 b3 11 00 	movzbl 0x11b325,%eax
  101f91:	83 e0 9f             	and    $0xffffff9f,%eax
  101f94:	a2 25 b3 11 00       	mov    %al,0x11b325
  101f99:	0f b6 05 25 b3 11 00 	movzbl 0x11b325,%eax
  101fa0:	83 c8 80             	or     $0xffffff80,%eax
  101fa3:	a2 25 b3 11 00       	mov    %al,0x11b325
  101fa8:	b8 86 29 10 00       	mov    $0x102986,%eax
  101fad:	c1 e8 10             	shr    $0x10,%eax
  101fb0:	66 a3 26 b3 11 00    	mov    %ax,0x11b326
  SETGATE(idt[T_SYSCALL],0,     CPU_GDT_KCODE, &trap_syscall,3);
  101fb6:	b8 90 29 10 00       	mov    $0x102990,%eax
  101fbb:	66 a3 a0 b3 11 00    	mov    %ax,0x11b3a0
  101fc1:	66 c7 05 a2 b3 11 00 	movw   $0x8,0x11b3a2
  101fc8:	08 00 
  101fca:	0f b6 05 a4 b3 11 00 	movzbl 0x11b3a4,%eax
  101fd1:	83 e0 e0             	and    $0xffffffe0,%eax
  101fd4:	a2 a4 b3 11 00       	mov    %al,0x11b3a4
  101fd9:	0f b6 05 a4 b3 11 00 	movzbl 0x11b3a4,%eax
  101fe0:	83 e0 1f             	and    $0x1f,%eax
  101fe3:	a2 a4 b3 11 00       	mov    %al,0x11b3a4
  101fe8:	0f b6 05 a5 b3 11 00 	movzbl 0x11b3a5,%eax
  101fef:	83 e0 f0             	and    $0xfffffff0,%eax
  101ff2:	83 c8 0e             	or     $0xe,%eax
  101ff5:	a2 a5 b3 11 00       	mov    %al,0x11b3a5
  101ffa:	0f b6 05 a5 b3 11 00 	movzbl 0x11b3a5,%eax
  102001:	83 e0 ef             	and    $0xffffffef,%eax
  102004:	a2 a5 b3 11 00       	mov    %al,0x11b3a5
  102009:	0f b6 05 a5 b3 11 00 	movzbl 0x11b3a5,%eax
  102010:	83 c8 60             	or     $0x60,%eax
  102013:	a2 a5 b3 11 00       	mov    %al,0x11b3a5
  102018:	0f b6 05 a5 b3 11 00 	movzbl 0x11b3a5,%eax
  10201f:	83 c8 80             	or     $0xffffff80,%eax
  102022:	a2 a5 b3 11 00       	mov    %al,0x11b3a5
  102027:	b8 90 29 10 00       	mov    $0x102990,%eax
  10202c:	c1 e8 10             	shr    $0x10,%eax
  10202f:	66 a3 a6 b3 11 00    	mov    %ax,0x11b3a6
  SETGATE(idt[T_LTIMER], 0,     CPU_GDT_KCODE, &trap_ltimer, 0);
  102035:	b8 9a 29 10 00       	mov    $0x10299a,%eax
  10203a:	66 a3 a8 b3 11 00    	mov    %ax,0x11b3a8
  102040:	66 c7 05 aa b3 11 00 	movw   $0x8,0x11b3aa
  102047:	08 00 
  102049:	0f b6 05 ac b3 11 00 	movzbl 0x11b3ac,%eax
  102050:	83 e0 e0             	and    $0xffffffe0,%eax
  102053:	a2 ac b3 11 00       	mov    %al,0x11b3ac
  102058:	0f b6 05 ac b3 11 00 	movzbl 0x11b3ac,%eax
  10205f:	83 e0 1f             	and    $0x1f,%eax
  102062:	a2 ac b3 11 00       	mov    %al,0x11b3ac
  102067:	0f b6 05 ad b3 11 00 	movzbl 0x11b3ad,%eax
  10206e:	83 e0 f0             	and    $0xfffffff0,%eax
  102071:	83 c8 0e             	or     $0xe,%eax
  102074:	a2 ad b3 11 00       	mov    %al,0x11b3ad
  102079:	0f b6 05 ad b3 11 00 	movzbl 0x11b3ad,%eax
  102080:	83 e0 ef             	and    $0xffffffef,%eax
  102083:	a2 ad b3 11 00       	mov    %al,0x11b3ad
  102088:	0f b6 05 ad b3 11 00 	movzbl 0x11b3ad,%eax
  10208f:	83 e0 9f             	and    $0xffffff9f,%eax
  102092:	a2 ad b3 11 00       	mov    %al,0x11b3ad
  102097:	0f b6 05 ad b3 11 00 	movzbl 0x11b3ad,%eax
  10209e:	83 c8 80             	or     $0xffffff80,%eax
  1020a1:	a2 ad b3 11 00       	mov    %al,0x11b3ad
  1020a6:	b8 9a 29 10 00       	mov    $0x10299a,%eax
  1020ab:	c1 e8 10             	shr    $0x10,%eax
  1020ae:	66 a3 ae b3 11 00    	mov    %ax,0x11b3ae
  SETGATE(idt[T_LERROR], 0,     CPU_GDT_KCODE, &trap_lerror, 0);
  1020b4:	b8 a4 29 10 00       	mov    $0x1029a4,%eax
  1020b9:	66 a3 b0 b3 11 00    	mov    %ax,0x11b3b0
  1020bf:	66 c7 05 b2 b3 11 00 	movw   $0x8,0x11b3b2
  1020c6:	08 00 
  1020c8:	0f b6 05 b4 b3 11 00 	movzbl 0x11b3b4,%eax
  1020cf:	83 e0 e0             	and    $0xffffffe0,%eax
  1020d2:	a2 b4 b3 11 00       	mov    %al,0x11b3b4
  1020d7:	0f b6 05 b4 b3 11 00 	movzbl 0x11b3b4,%eax
  1020de:	83 e0 1f             	and    $0x1f,%eax
  1020e1:	a2 b4 b3 11 00       	mov    %al,0x11b3b4
  1020e6:	0f b6 05 b5 b3 11 00 	movzbl 0x11b3b5,%eax
  1020ed:	83 e0 f0             	and    $0xfffffff0,%eax
  1020f0:	83 c8 0e             	or     $0xe,%eax
  1020f3:	a2 b5 b3 11 00       	mov    %al,0x11b3b5
  1020f8:	0f b6 05 b5 b3 11 00 	movzbl 0x11b3b5,%eax
  1020ff:	83 e0 ef             	and    $0xffffffef,%eax
  102102:	a2 b5 b3 11 00       	mov    %al,0x11b3b5
  102107:	0f b6 05 b5 b3 11 00 	movzbl 0x11b3b5,%eax
  10210e:	83 e0 9f             	and    $0xffffff9f,%eax
  102111:	a2 b5 b3 11 00       	mov    %al,0x11b3b5
  102116:	0f b6 05 b5 b3 11 00 	movzbl 0x11b3b5,%eax
  10211d:	83 c8 80             	or     $0xffffff80,%eax
  102120:	a2 b5 b3 11 00       	mov    %al,0x11b3b5
  102125:	b8 a4 29 10 00       	mov    $0x1029a4,%eax
  10212a:	c1 e8 10             	shr    $0x10,%eax
  10212d:	66 a3 b6 b3 11 00    	mov    %ax,0x11b3b6

}
  102133:	5d                   	pop    %ebp
  102134:	c3                   	ret    

00102135 <trap_init>:

void
trap_init(void)
{
  102135:	55                   	push   %ebp
  102136:	89 e5                	mov    %esp,%ebp
  102138:	83 ec 08             	sub    $0x8,%esp
	// The first time we get called on the bootstrap processor,
	// initialize the IDT.  Other CPUs will share the same IDT.
	if (cpu_onboot())
  10213b:	e8 20 00 00 00       	call   102160 <cpu_onboot>
  102140:	85 c0                	test   %eax,%eax
  102142:	74 05                	je     102149 <trap_init+0x14>
		trap_init_idt();
  102144:	e8 fb f5 ff ff       	call   101744 <trap_init_idt>

	// Load the IDT into this processor's IDT register.
	asm volatile("lidt %0" : : "m" (idt_pd));
  102149:	0f 01 1d 04 e0 10 00 	lidtl  0x10e004

	// Check for the correct IDT and trap handler operation.
	if (cpu_onboot())
  102150:	e8 0b 00 00 00       	call   102160 <cpu_onboot>
  102155:	85 c0                	test   %eax,%eax
  102157:	74 05                	je     10215e <trap_init+0x29>
		trap_check_kernel();
  102159:	e8 58 04 00 00       	call   1025b6 <trap_check_kernel>
}
  10215e:	c9                   	leave  
  10215f:	c3                   	ret    

00102160 <cpu_onboot>:
}

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  102160:	55                   	push   %ebp
  102161:	89 e5                	mov    %esp,%ebp
  102163:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  102166:	e8 0d 00 00 00       	call   102178 <cpu_cur>
  10216b:	3d 00 d0 10 00       	cmp    $0x10d000,%eax
  102170:	0f 94 c0             	sete   %al
  102173:	0f b6 c0             	movzbl %al,%eax
}
  102176:	c9                   	leave  
  102177:	c3                   	ret    

00102178 <cpu_cur>:
  102178:	55                   	push   %ebp
  102179:	89 e5                	mov    %esp,%ebp
  10217b:	83 ec 28             	sub    $0x28,%esp
static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  10217e:	89 65 fc             	mov    %esp,0xfffffffc(%ebp)
        return esp;
  102181:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  102184:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  102187:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10218a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  10218f:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	assert(c->magic == CPU_MAGIC);
  102192:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  102195:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  10219b:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  1021a0:	74 24                	je     1021c6 <cpu_cur+0x4e>
  1021a2:	c7 44 24 0c a0 ae 10 	movl   $0x10aea0,0xc(%esp)
  1021a9:	00 
  1021aa:	c7 44 24 08 b6 ae 10 	movl   $0x10aeb6,0x8(%esp)
  1021b1:	00 
  1021b2:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  1021b9:	00 
  1021ba:	c7 04 24 cb ae 10 00 	movl   $0x10aecb,(%esp)
  1021c1:	e8 d6 e5 ff ff       	call   10079c <debug_panic>
	return c;
  1021c6:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
}
  1021c9:	c9                   	leave  
  1021ca:	c3                   	ret    

001021cb <trap_name>:

const char *trap_name(int trapno)
{
  1021cb:	55                   	push   %ebp
  1021cc:	89 e5                	mov    %esp,%ebp
  1021ce:	83 ec 04             	sub    $0x4,%esp
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
  1021d1:	8b 45 08             	mov    0x8(%ebp),%eax
  1021d4:	83 f8 13             	cmp    $0x13,%eax
  1021d7:	77 0f                	ja     1021e8 <trap_name+0x1d>
		return excnames[trapno];
  1021d9:	8b 45 08             	mov    0x8(%ebp),%eax
  1021dc:	8b 04 85 40 b0 10 00 	mov    0x10b040(,%eax,4),%eax
  1021e3:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  1021e6:	eb 2b                	jmp    102213 <trap_name+0x48>
	if (trapno == T_SYSCALL)
  1021e8:	83 7d 08 30          	cmpl   $0x30,0x8(%ebp)
  1021ec:	75 09                	jne    1021f7 <trap_name+0x2c>
		return "System call";
  1021ee:	c7 45 fc 90 b0 10 00 	movl   $0x10b090,0xfffffffc(%ebp)
  1021f5:	eb 1c                	jmp    102213 <trap_name+0x48>
	if (trapno >= T_IRQ0 && trapno < T_IRQ0 + 16)
  1021f7:	83 7d 08 1f          	cmpl   $0x1f,0x8(%ebp)
  1021fb:	7e 0f                	jle    10220c <trap_name+0x41>
  1021fd:	83 7d 08 2f          	cmpl   $0x2f,0x8(%ebp)
  102201:	7f 09                	jg     10220c <trap_name+0x41>
		return "Hardware Interrupt";
  102203:	c7 45 fc 9c b0 10 00 	movl   $0x10b09c,0xfffffffc(%ebp)
  10220a:	eb 07                	jmp    102213 <trap_name+0x48>
	return "(unknown trap)";
  10220c:	c7 45 fc c2 af 10 00 	movl   $0x10afc2,0xfffffffc(%ebp)
  102213:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
}
  102216:	c9                   	leave  
  102217:	c3                   	ret    

00102218 <trap_print_regs>:

void
trap_print_regs(pushregs *regs)
{
  102218:	55                   	push   %ebp
  102219:	89 e5                	mov    %esp,%ebp
  10221b:	83 ec 08             	sub    $0x8,%esp
	cprintf("  edi  0x%08x\n", regs->edi);
  10221e:	8b 45 08             	mov    0x8(%ebp),%eax
  102221:	8b 00                	mov    (%eax),%eax
  102223:	89 44 24 04          	mov    %eax,0x4(%esp)
  102227:	c7 04 24 af b0 10 00 	movl   $0x10b0af,(%esp)
  10222e:	e8 76 80 00 00       	call   10a2a9 <cprintf>
	cprintf("  esi  0x%08x\n", regs->esi);
  102233:	8b 45 08             	mov    0x8(%ebp),%eax
  102236:	8b 40 04             	mov    0x4(%eax),%eax
  102239:	89 44 24 04          	mov    %eax,0x4(%esp)
  10223d:	c7 04 24 be b0 10 00 	movl   $0x10b0be,(%esp)
  102244:	e8 60 80 00 00       	call   10a2a9 <cprintf>
	cprintf("  ebp  0x%08x\n", regs->ebp);
  102249:	8b 45 08             	mov    0x8(%ebp),%eax
  10224c:	8b 40 08             	mov    0x8(%eax),%eax
  10224f:	89 44 24 04          	mov    %eax,0x4(%esp)
  102253:	c7 04 24 cd b0 10 00 	movl   $0x10b0cd,(%esp)
  10225a:	e8 4a 80 00 00       	call   10a2a9 <cprintf>
//	cprintf("  oesp 0x%08x\n", regs->oesp);	don't print - useless
	cprintf("  ebx  0x%08x\n", regs->ebx);
  10225f:	8b 45 08             	mov    0x8(%ebp),%eax
  102262:	8b 40 10             	mov    0x10(%eax),%eax
  102265:	89 44 24 04          	mov    %eax,0x4(%esp)
  102269:	c7 04 24 dc b0 10 00 	movl   $0x10b0dc,(%esp)
  102270:	e8 34 80 00 00       	call   10a2a9 <cprintf>
	cprintf("  edx  0x%08x\n", regs->edx);
  102275:	8b 45 08             	mov    0x8(%ebp),%eax
  102278:	8b 40 14             	mov    0x14(%eax),%eax
  10227b:	89 44 24 04          	mov    %eax,0x4(%esp)
  10227f:	c7 04 24 eb b0 10 00 	movl   $0x10b0eb,(%esp)
  102286:	e8 1e 80 00 00       	call   10a2a9 <cprintf>
	cprintf("  ecx  0x%08x\n", regs->ecx);
  10228b:	8b 45 08             	mov    0x8(%ebp),%eax
  10228e:	8b 40 18             	mov    0x18(%eax),%eax
  102291:	89 44 24 04          	mov    %eax,0x4(%esp)
  102295:	c7 04 24 fa b0 10 00 	movl   $0x10b0fa,(%esp)
  10229c:	e8 08 80 00 00       	call   10a2a9 <cprintf>
	cprintf("  eax  0x%08x\n", regs->eax);
  1022a1:	8b 45 08             	mov    0x8(%ebp),%eax
  1022a4:	8b 40 1c             	mov    0x1c(%eax),%eax
  1022a7:	89 44 24 04          	mov    %eax,0x4(%esp)
  1022ab:	c7 04 24 09 b1 10 00 	movl   $0x10b109,(%esp)
  1022b2:	e8 f2 7f 00 00       	call   10a2a9 <cprintf>
}
  1022b7:	c9                   	leave  
  1022b8:	c3                   	ret    

001022b9 <trap_print>:

void
trap_print(trapframe *tf)
{
  1022b9:	55                   	push   %ebp
  1022ba:	89 e5                	mov    %esp,%ebp
  1022bc:	83 ec 18             	sub    $0x18,%esp
	cprintf("TRAP frame at %p\n", tf);
  1022bf:	8b 45 08             	mov    0x8(%ebp),%eax
  1022c2:	89 44 24 04          	mov    %eax,0x4(%esp)
  1022c6:	c7 04 24 18 b1 10 00 	movl   $0x10b118,(%esp)
  1022cd:	e8 d7 7f 00 00       	call   10a2a9 <cprintf>
	trap_print_regs(&tf->regs);
  1022d2:	8b 45 08             	mov    0x8(%ebp),%eax
  1022d5:	89 04 24             	mov    %eax,(%esp)
  1022d8:	e8 3b ff ff ff       	call   102218 <trap_print_regs>
	cprintf("  es   0x----%04x\n", tf->es);
  1022dd:	8b 45 08             	mov    0x8(%ebp),%eax
  1022e0:	0f b7 40 28          	movzwl 0x28(%eax),%eax
  1022e4:	0f b7 c0             	movzwl %ax,%eax
  1022e7:	89 44 24 04          	mov    %eax,0x4(%esp)
  1022eb:	c7 04 24 2a b1 10 00 	movl   $0x10b12a,(%esp)
  1022f2:	e8 b2 7f 00 00       	call   10a2a9 <cprintf>
	cprintf("  ds   0x----%04x\n", tf->ds);
  1022f7:	8b 45 08             	mov    0x8(%ebp),%eax
  1022fa:	0f b7 40 2c          	movzwl 0x2c(%eax),%eax
  1022fe:	0f b7 c0             	movzwl %ax,%eax
  102301:	89 44 24 04          	mov    %eax,0x4(%esp)
  102305:	c7 04 24 3d b1 10 00 	movl   $0x10b13d,(%esp)
  10230c:	e8 98 7f 00 00       	call   10a2a9 <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->trapno, trap_name(tf->trapno));
  102311:	8b 45 08             	mov    0x8(%ebp),%eax
  102314:	8b 40 30             	mov    0x30(%eax),%eax
  102317:	89 04 24             	mov    %eax,(%esp)
  10231a:	e8 ac fe ff ff       	call   1021cb <trap_name>
  10231f:	89 c2                	mov    %eax,%edx
  102321:	8b 45 08             	mov    0x8(%ebp),%eax
  102324:	8b 40 30             	mov    0x30(%eax),%eax
  102327:	89 54 24 08          	mov    %edx,0x8(%esp)
  10232b:	89 44 24 04          	mov    %eax,0x4(%esp)
  10232f:	c7 04 24 50 b1 10 00 	movl   $0x10b150,(%esp)
  102336:	e8 6e 7f 00 00       	call   10a2a9 <cprintf>
	cprintf("  err  0x%08x\n", tf->err);
  10233b:	8b 45 08             	mov    0x8(%ebp),%eax
  10233e:	8b 40 34             	mov    0x34(%eax),%eax
  102341:	89 44 24 04          	mov    %eax,0x4(%esp)
  102345:	c7 04 24 62 b1 10 00 	movl   $0x10b162,(%esp)
  10234c:	e8 58 7f 00 00       	call   10a2a9 <cprintf>
	cprintf("  eip  0x%08x\n", tf->eip);
  102351:	8b 45 08             	mov    0x8(%ebp),%eax
  102354:	8b 40 38             	mov    0x38(%eax),%eax
  102357:	89 44 24 04          	mov    %eax,0x4(%esp)
  10235b:	c7 04 24 71 b1 10 00 	movl   $0x10b171,(%esp)
  102362:	e8 42 7f 00 00       	call   10a2a9 <cprintf>
	cprintf("  cs   0x----%04x\n", tf->cs);
  102367:	8b 45 08             	mov    0x8(%ebp),%eax
  10236a:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
  10236e:	0f b7 c0             	movzwl %ax,%eax
  102371:	89 44 24 04          	mov    %eax,0x4(%esp)
  102375:	c7 04 24 80 b1 10 00 	movl   $0x10b180,(%esp)
  10237c:	e8 28 7f 00 00       	call   10a2a9 <cprintf>
	cprintf("  flag 0x%08x\n", tf->eflags);
  102381:	8b 45 08             	mov    0x8(%ebp),%eax
  102384:	8b 40 40             	mov    0x40(%eax),%eax
  102387:	89 44 24 04          	mov    %eax,0x4(%esp)
  10238b:	c7 04 24 93 b1 10 00 	movl   $0x10b193,(%esp)
  102392:	e8 12 7f 00 00       	call   10a2a9 <cprintf>
	cprintf("  esp  0x%08x\n", tf->esp);
  102397:	8b 45 08             	mov    0x8(%ebp),%eax
  10239a:	8b 40 44             	mov    0x44(%eax),%eax
  10239d:	89 44 24 04          	mov    %eax,0x4(%esp)
  1023a1:	c7 04 24 a2 b1 10 00 	movl   $0x10b1a2,(%esp)
  1023a8:	e8 fc 7e 00 00       	call   10a2a9 <cprintf>
	cprintf("  ss   0x----%04x\n", tf->ss);
  1023ad:	8b 45 08             	mov    0x8(%ebp),%eax
  1023b0:	0f b7 40 48          	movzwl 0x48(%eax),%eax
  1023b4:	0f b7 c0             	movzwl %ax,%eax
  1023b7:	89 44 24 04          	mov    %eax,0x4(%esp)
  1023bb:	c7 04 24 b1 b1 10 00 	movl   $0x10b1b1,(%esp)
  1023c2:	e8 e2 7e 00 00       	call   10a2a9 <cprintf>
}
  1023c7:	c9                   	leave  
  1023c8:	c3                   	ret    

001023c9 <trap>:

void gcc_noreturn
trap(trapframe *tf)
{
  1023c9:	55                   	push   %ebp
  1023ca:	89 e5                	mov    %esp,%ebp
  1023cc:	83 ec 28             	sub    $0x28,%esp
	// The user-level environment may have set the DF flag,
	// and some versions of GCC rely on DF being clear.
	asm volatile("cld" ::: "cc");
  1023cf:	fc                   	cld    
  if(tf->trapno == T_PGFLT)
  1023d0:	8b 45 08             	mov    0x8(%ebp),%eax
  1023d3:	8b 40 30             	mov    0x30(%eax),%eax
  1023d6:	83 f8 0e             	cmp    $0xe,%eax
  1023d9:	75 0b                	jne    1023e6 <trap+0x1d>
    pmap_pagefault(tf);
  1023db:	8b 45 08             	mov    0x8(%ebp),%eax
  1023de:	89 04 24             	mov    %eax,(%esp)
  1023e1:	e8 1b 40 00 00       	call   106401 <pmap_pagefault>
	// If this trap was anticipated, just use the designated handler.
	cpu *c = cpu_cur();
  1023e6:	e8 8d fd ff ff       	call   102178 <cpu_cur>
  1023eb:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	if (c->recover)
  1023ee:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  1023f1:	8b 80 a0 00 00 00    	mov    0xa0(%eax),%eax
  1023f7:	85 c0                	test   %eax,%eax
  1023f9:	74 1e                	je     102419 <trap+0x50>
		c->recover(tf, c->recoverdata);
  1023fb:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  1023fe:	8b 90 a0 00 00 00    	mov    0xa0(%eax),%edx
  102404:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  102407:	8b 80 a4 00 00 00    	mov    0xa4(%eax),%eax
  10240d:	89 44 24 04          	mov    %eax,0x4(%esp)
  102411:	8b 45 08             	mov    0x8(%ebp),%eax
  102414:	89 04 24             	mov    %eax,(%esp)
  102417:	ff d2                	call   *%edx

	// Lab 2: your trap handling code here!
  switch (tf->trapno) {
  102419:	8b 45 08             	mov    0x8(%ebp),%eax
  10241c:	8b 40 30             	mov    0x30(%eax),%eax
  10241f:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  102422:	83 7d ec 32          	cmpl   $0x32,0xffffffec(%ebp)
  102426:	0f 87 15 01 00 00    	ja     102541 <trap+0x178>
  10242c:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
  10242f:	8b 04 95 10 b2 10 00 	mov    0x10b210(,%edx,4),%eax
  102436:	ff e0                	jmp    *%eax
  case T_SYSCALL:
    assert(tf->cs & 3);
  102438:	8b 45 08             	mov    0x8(%ebp),%eax
  10243b:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
  10243f:	0f b7 c0             	movzwl %ax,%eax
  102442:	83 e0 03             	and    $0x3,%eax
  102445:	85 c0                	test   %eax,%eax
  102447:	75 24                	jne    10246d <trap+0xa4>
  102449:	c7 44 24 0c c4 b1 10 	movl   $0x10b1c4,0xc(%esp)
  102450:	00 
  102451:	c7 44 24 08 b6 ae 10 	movl   $0x10aeb6,0x8(%esp)
  102458:	00 
  102459:	c7 44 24 04 bf 00 00 	movl   $0xbf,0x4(%esp)
  102460:	00 
  102461:	c7 04 24 cf b1 10 00 	movl   $0x10b1cf,(%esp)
  102468:	e8 2f e3 ff ff       	call   10079c <debug_panic>
    syscall(tf);
  10246d:	8b 45 08             	mov    0x8(%ebp),%eax
  102470:	89 04 24             	mov    %eax,(%esp)
  102473:	e8 cb 29 00 00       	call   104e43 <syscall>
    break;
  102478:	e9 c4 00 00 00       	jmp    102541 <trap+0x178>
  case T_DIVIDE:
  case T_DEBUG:
  case T_BRKPT:
  case T_OFLOW:
  case T_NMI:
  case T_BOUND:
  case T_ILLOP:
  case T_DEVICE:
  case T_DBLFLT:
  case T_TSS:
  case T_SEGNP:
  case T_STACK:
  case T_GPFLT:
  case T_PGFLT:
  case T_FPERR:
  case T_ALIGN:
  case T_MCHK:
  case T_SIMD:
  case T_SECEV:
    assert(tf->cs & 3);
  10247d:	8b 45 08             	mov    0x8(%ebp),%eax
  102480:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
  102484:	0f b7 c0             	movzwl %ax,%eax
  102487:	83 e0 03             	and    $0x3,%eax
  10248a:	85 c0                	test   %eax,%eax
  10248c:	75 24                	jne    1024b2 <trap+0xe9>
  10248e:	c7 44 24 0c c4 b1 10 	movl   $0x10b1c4,0xc(%esp)
  102495:	00 
  102496:	c7 44 24 08 b6 ae 10 	movl   $0x10aeb6,0x8(%esp)
  10249d:	00 
  10249e:	c7 44 24 04 d5 00 00 	movl   $0xd5,0x4(%esp)
  1024a5:	00 
  1024a6:	c7 04 24 cf b1 10 00 	movl   $0x10b1cf,(%esp)
  1024ad:	e8 ea e2 ff ff       	call   10079c <debug_panic>
    proc_ret(tf, 1);
  1024b2:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  1024b9:	00 
  1024ba:	8b 45 08             	mov    0x8(%ebp),%eax
  1024bd:	89 04 24             	mov    %eax,(%esp)
  1024c0:	e8 80 16 00 00       	call   103b45 <proc_ret>
    break;
  case T_LTIMER:
    lapic_eoi();
  1024c5:	e8 9e 72 00 00       	call   109768 <lapic_eoi>
    if (tf->cs & 3)
  1024ca:	8b 45 08             	mov    0x8(%ebp),%eax
  1024cd:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
  1024d1:	0f b7 c0             	movzwl %ax,%eax
  1024d4:	83 e0 03             	and    $0x3,%eax
  1024d7:	85 c0                	test   %eax,%eax
  1024d9:	74 0b                	je     1024e6 <trap+0x11d>
      proc_yield(tf);
  1024db:	8b 45 08             	mov    0x8(%ebp),%eax
  1024de:	89 04 24             	mov    %eax,(%esp)
  1024e1:	e8 dd 15 00 00       	call   103ac3 <proc_yield>

    trap_return(tf);
  1024e6:	8b 45 08             	mov    0x8(%ebp),%eax
  1024e9:	89 04 24             	mov    %eax,(%esp)
  1024ec:	e8 df 04 00 00       	call   1029d0 <trap_return>
    break;
  case T_LERROR:
    lapic_errintr();
  1024f1:	e8 97 72 00 00       	call   10978d <lapic_errintr>
    trap_return(tf);
  1024f6:	8b 45 08             	mov    0x8(%ebp),%eax
  1024f9:	89 04 24             	mov    %eax,(%esp)
  1024fc:	e8 cf 04 00 00       	call   1029d0 <trap_return>
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
  102501:	8b 45 08             	mov    0x8(%ebp),%eax
  102504:	8b 48 38             	mov    0x38(%eax),%ecx
  102507:	8b 45 08             	mov    0x8(%ebp),%eax
  10250a:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
  10250e:	0f b7 d0             	movzwl %ax,%edx
  102511:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  102514:	0f b6 80 ac 00 00 00 	movzbl 0xac(%eax),%eax
  10251b:	0f b6 c0             	movzbl %al,%eax
  10251e:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  102522:	89 54 24 08          	mov    %edx,0x8(%esp)
  102526:	89 44 24 04          	mov    %eax,0x4(%esp)
  10252a:	c7 04 24 dc b1 10 00 	movl   $0x10b1dc,(%esp)
  102531:	e8 73 7d 00 00       	call   10a2a9 <cprintf>
        c->id, tf->cs, tf->eip);
    trap_return(tf); // Note: no EOI (see Local APIC manual)
  102536:	8b 45 08             	mov    0x8(%ebp),%eax
  102539:	89 04 24             	mov    %eax,(%esp)
  10253c:	e8 8f 04 00 00       	call   1029d0 <trap_return>
    break;
  }
	// If we panic while holding the console lock,
	// release it so we don't get into a recursive panic that way.
	if (spinlock_holding(&cons_lock))
  102541:	c7 04 24 00 fd 11 00 	movl   $0x11fd00,(%esp)
  102548:	e8 32 0a 00 00       	call   102f7f <spinlock_holding>
  10254d:	85 c0                	test   %eax,%eax
  10254f:	74 0c                	je     10255d <trap+0x194>
		spinlock_release(&cons_lock);
  102551:	c7 04 24 00 fd 11 00 	movl   $0x11fd00,(%esp)
  102558:	e8 c8 09 00 00       	call   102f25 <spinlock_release>
	trap_print(tf);
  10255d:	8b 45 08             	mov    0x8(%ebp),%eax
  102560:	89 04 24             	mov    %eax,(%esp)
  102563:	e8 51 fd ff ff       	call   1022b9 <trap_print>
	panic("unhandled trap");
  102568:	c7 44 24 08 00 b2 10 	movl   $0x10b200,0x8(%esp)
  10256f:	00 
  102570:	c7 44 24 04 ed 00 00 	movl   $0xed,0x4(%esp)
  102577:	00 
  102578:	c7 04 24 cf b1 10 00 	movl   $0x10b1cf,(%esp)
  10257f:	e8 18 e2 ff ff       	call   10079c <debug_panic>

00102584 <trap_check_recover>:
}


// Helper function for trap_check_recover(), below:
// handles "anticipated" traps by simply resuming at a new EIP.
static void gcc_noreturn
trap_check_recover(trapframe *tf, void *recoverdata)
{
  102584:	55                   	push   %ebp
  102585:	89 e5                	mov    %esp,%ebp
  102587:	83 ec 18             	sub    $0x18,%esp
	trap_check_args *args = recoverdata;
  10258a:	8b 45 0c             	mov    0xc(%ebp),%eax
  10258d:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	tf->eip = (uint32_t) args->reip;	// Use recovery EIP on return
  102590:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  102593:	8b 00                	mov    (%eax),%eax
  102595:	89 c2                	mov    %eax,%edx
  102597:	8b 45 08             	mov    0x8(%ebp),%eax
  10259a:	89 50 38             	mov    %edx,0x38(%eax)
	args->trapno = tf->trapno;		// Return trap number
  10259d:	8b 45 08             	mov    0x8(%ebp),%eax
  1025a0:	8b 40 30             	mov    0x30(%eax),%eax
  1025a3:	89 c2                	mov    %eax,%edx
  1025a5:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  1025a8:	89 50 04             	mov    %edx,0x4(%eax)
	trap_return(tf);
  1025ab:	8b 45 08             	mov    0x8(%ebp),%eax
  1025ae:	89 04 24             	mov    %eax,(%esp)
  1025b1:	e8 1a 04 00 00       	call   1029d0 <trap_return>

001025b6 <trap_check_kernel>:
}

// Check for correct handling of traps from kernel mode.
// Called on the boot CPU after trap_init() and trap_setup().
void
trap_check_kernel(void)
{
  1025b6:	55                   	push   %ebp
  1025b7:	89 e5                	mov    %esp,%ebp
  1025b9:	83 ec 28             	sub    $0x28,%esp
static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  1025bc:	8c 4d fe             	movw   %cs,0xfffffffe(%ebp)
        return cs;
  1025bf:	0f b7 45 fe          	movzwl 0xfffffffe(%ebp),%eax
	assert((read_cs() & 3) == 0);	// better be in kernel mode!
  1025c3:	0f b7 c0             	movzwl %ax,%eax
  1025c6:	83 e0 03             	and    $0x3,%eax
  1025c9:	85 c0                	test   %eax,%eax
  1025cb:	74 24                	je     1025f1 <trap_check_kernel+0x3b>
  1025cd:	c7 44 24 0c dc b2 10 	movl   $0x10b2dc,0xc(%esp)
  1025d4:	00 
  1025d5:	c7 44 24 08 b6 ae 10 	movl   $0x10aeb6,0x8(%esp)
  1025dc:	00 
  1025dd:	c7 44 24 04 01 01 00 	movl   $0x101,0x4(%esp)
  1025e4:	00 
  1025e5:	c7 04 24 cf b1 10 00 	movl   $0x10b1cf,(%esp)
  1025ec:	e8 ab e1 ff ff       	call   10079c <debug_panic>

	cpu *c = cpu_cur();
  1025f1:	e8 82 fb ff ff       	call   102178 <cpu_cur>
  1025f6:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
	c->recover = trap_check_recover;
  1025f9:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1025fc:	c7 80 a0 00 00 00 84 	movl   $0x102584,0xa0(%eax)
  102603:	25 10 00 
	trap_check(&c->recoverdata);
  102606:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  102609:	05 a4 00 00 00       	add    $0xa4,%eax
  10260e:	89 04 24             	mov    %eax,(%esp)
  102611:	e8 96 00 00 00       	call   1026ac <trap_check>
	c->recover = NULL;	// No more mr. nice-guy; traps are real again
  102616:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  102619:	c7 80 a0 00 00 00 00 	movl   $0x0,0xa0(%eax)
  102620:	00 00 00 

	cprintf("trap_check_kernel() succeeded!\n");
  102623:	c7 04 24 f4 b2 10 00 	movl   $0x10b2f4,(%esp)
  10262a:	e8 7a 7c 00 00       	call   10a2a9 <cprintf>
}
  10262f:	c9                   	leave  
  102630:	c3                   	ret    

00102631 <trap_check_user>:

// Check for correct handling of traps from user mode.
// Called from user() in kern/init.c, only in lab 1.
// We assume the "current cpu" is always the boot cpu;
// this true only because lab 1 doesn't start any other CPUs.
void
trap_check_user(void)
{
  102631:	55                   	push   %ebp
  102632:	89 e5                	mov    %esp,%ebp
  102634:	83 ec 28             	sub    $0x28,%esp
static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  102637:	8c 4d fe             	movw   %cs,0xfffffffe(%ebp)
        return cs;
  10263a:	0f b7 45 fe          	movzwl 0xfffffffe(%ebp),%eax
	assert((read_cs() & 3) == 3);	// better be in user mode!
  10263e:	0f b7 c0             	movzwl %ax,%eax
  102641:	83 e0 03             	and    $0x3,%eax
  102644:	83 f8 03             	cmp    $0x3,%eax
  102647:	74 24                	je     10266d <trap_check_user+0x3c>
  102649:	c7 44 24 0c 14 b3 10 	movl   $0x10b314,0xc(%esp)
  102650:	00 
  102651:	c7 44 24 08 b6 ae 10 	movl   $0x10aeb6,0x8(%esp)
  102658:	00 
  102659:	c7 44 24 04 12 01 00 	movl   $0x112,0x4(%esp)
  102660:	00 
  102661:	c7 04 24 cf b1 10 00 	movl   $0x10b1cf,(%esp)
  102668:	e8 2f e1 ff ff       	call   10079c <debug_panic>

	cpu *c = &cpu_boot;	// cpu_cur doesn't work from user mode!
  10266d:	c7 45 f8 00 d0 10 00 	movl   $0x10d000,0xfffffff8(%ebp)
	c->recover = trap_check_recover;
  102674:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  102677:	c7 80 a0 00 00 00 84 	movl   $0x102584,0xa0(%eax)
  10267e:	25 10 00 
	trap_check(&c->recoverdata);
  102681:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  102684:	05 a4 00 00 00       	add    $0xa4,%eax
  102689:	89 04 24             	mov    %eax,(%esp)
  10268c:	e8 1b 00 00 00       	call   1026ac <trap_check>
	c->recover = NULL;	// No more mr. nice-guy; traps are real again
  102691:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  102694:	c7 80 a0 00 00 00 00 	movl   $0x0,0xa0(%eax)
  10269b:	00 00 00 

	cprintf("trap_check_user() succeeded!\n");
  10269e:	c7 04 24 29 b3 10 00 	movl   $0x10b329,(%esp)
  1026a5:	e8 ff 7b 00 00       	call   10a2a9 <cprintf>
}
  1026aa:	c9                   	leave  
  1026ab:	c3                   	ret    

001026ac <trap_check>:

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
  1026ac:	55                   	push   %ebp
  1026ad:	89 e5                	mov    %esp,%ebp
  1026af:	57                   	push   %edi
  1026b0:	56                   	push   %esi
  1026b1:	53                   	push   %ebx
  1026b2:	83 ec 3c             	sub    $0x3c,%esp
	volatile int cookie = 0xfeedface;
  1026b5:	c7 45 ec ce fa ed fe 	movl   $0xfeedface,0xffffffec(%ebp)
	volatile trap_check_args args;
	*argsp = (void*)&args;	// provide args needed for trap recovery
  1026bc:	8b 55 08             	mov    0x8(%ebp),%edx
  1026bf:	8d 45 e4             	lea    0xffffffe4(%ebp),%eax
  1026c2:	89 02                	mov    %eax,(%edx)

	// Try a divide by zero trap.
	// Be careful when using && to take the address of a label:
	// some versions of GCC (4.4.2 at least) will incorrectly try to
	// eliminate code it thinks is _only_ reachable via such a pointer.
	args.reip = after_div0;
  1026c4:	c7 45 e4 d2 26 10 00 	movl   $0x1026d2,0xffffffe4(%ebp)
	asm volatile("div %0,%0; after_div0:" : : "r" (0));
  1026cb:	b8 00 00 00 00       	mov    $0x0,%eax
  1026d0:	f7 f0                	div    %eax

001026d2 <after_div0>:
	assert(args.trapno == T_DIVIDE);
  1026d2:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  1026d5:	85 c0                	test   %eax,%eax
  1026d7:	74 24                	je     1026fd <after_div0+0x2b>
  1026d9:	c7 44 24 0c 47 b3 10 	movl   $0x10b347,0xc(%esp)
  1026e0:	00 
  1026e1:	c7 44 24 08 b6 ae 10 	movl   $0x10aeb6,0x8(%esp)
  1026e8:	00 
  1026e9:	c7 44 24 04 32 01 00 	movl   $0x132,0x4(%esp)
  1026f0:	00 
  1026f1:	c7 04 24 cf b1 10 00 	movl   $0x10b1cf,(%esp)
  1026f8:	e8 9f e0 ff ff       	call   10079c <debug_panic>

	// Make sure we got our correct stack back with us.
	// The asm ensures gcc uses ebp/esp to get the cookie.
	asm volatile("" : : : "eax","ebx","ecx","edx","esi","edi");
	assert(cookie == 0xfeedface);
  1026fd:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  102700:	3d ce fa ed fe       	cmp    $0xfeedface,%eax
  102705:	74 24                	je     10272b <after_div0+0x59>
  102707:	c7 44 24 0c 5f b3 10 	movl   $0x10b35f,0xc(%esp)
  10270e:	00 
  10270f:	c7 44 24 08 b6 ae 10 	movl   $0x10aeb6,0x8(%esp)
  102716:	00 
  102717:	c7 44 24 04 37 01 00 	movl   $0x137,0x4(%esp)
  10271e:	00 
  10271f:	c7 04 24 cf b1 10 00 	movl   $0x10b1cf,(%esp)
  102726:	e8 71 e0 ff ff       	call   10079c <debug_panic>

	// Breakpoint trap
	args.reip = after_breakpoint;
  10272b:	c7 45 e4 33 27 10 00 	movl   $0x102733,0xffffffe4(%ebp)
	asm volatile("int3; after_breakpoint:");
  102732:	cc                   	int3   

00102733 <after_breakpoint>:
	assert(args.trapno == T_BRKPT);
  102733:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  102736:	83 f8 03             	cmp    $0x3,%eax
  102739:	74 24                	je     10275f <after_breakpoint+0x2c>
  10273b:	c7 44 24 0c 74 b3 10 	movl   $0x10b374,0xc(%esp)
  102742:	00 
  102743:	c7 44 24 08 b6 ae 10 	movl   $0x10aeb6,0x8(%esp)
  10274a:	00 
  10274b:	c7 44 24 04 3c 01 00 	movl   $0x13c,0x4(%esp)
  102752:	00 
  102753:	c7 04 24 cf b1 10 00 	movl   $0x10b1cf,(%esp)
  10275a:	e8 3d e0 ff ff       	call   10079c <debug_panic>

	// Overflow trap
	args.reip = after_overflow;
  10275f:	c7 45 e4 6e 27 10 00 	movl   $0x10276e,0xffffffe4(%ebp)
	asm volatile("addl %0,%0; into; after_overflow:" : : "r" (0x70000000));
  102766:	b8 00 00 00 70       	mov    $0x70000000,%eax
  10276b:	01 c0                	add    %eax,%eax
  10276d:	ce                   	into   

0010276e <after_overflow>:
	assert(args.trapno == T_OFLOW);
  10276e:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  102771:	83 f8 04             	cmp    $0x4,%eax
  102774:	74 24                	je     10279a <after_overflow+0x2c>
  102776:	c7 44 24 0c 8b b3 10 	movl   $0x10b38b,0xc(%esp)
  10277d:	00 
  10277e:	c7 44 24 08 b6 ae 10 	movl   $0x10aeb6,0x8(%esp)
  102785:	00 
  102786:	c7 44 24 04 41 01 00 	movl   $0x141,0x4(%esp)
  10278d:	00 
  10278e:	c7 04 24 cf b1 10 00 	movl   $0x10b1cf,(%esp)
  102795:	e8 02 e0 ff ff       	call   10079c <debug_panic>

	// Bounds trap
	args.reip = after_bound;
  10279a:	c7 45 e4 b7 27 10 00 	movl   $0x1027b7,0xffffffe4(%ebp)
	int bounds[2] = { 1, 3 };
  1027a1:	c7 45 dc 01 00 00 00 	movl   $0x1,0xffffffdc(%ebp)
  1027a8:	c7 45 e0 03 00 00 00 	movl   $0x3,0xffffffe0(%ebp)
	asm volatile("boundl %0,%1; after_bound:" : : "r" (0), "m" (bounds[0]));
  1027af:	b8 00 00 00 00       	mov    $0x0,%eax
  1027b4:	62 45 dc             	bound  %eax,0xffffffdc(%ebp)

001027b7 <after_bound>:
	assert(args.trapno == T_BOUND);
  1027b7:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  1027ba:	83 f8 05             	cmp    $0x5,%eax
  1027bd:	74 24                	je     1027e3 <after_bound+0x2c>
  1027bf:	c7 44 24 0c a2 b3 10 	movl   $0x10b3a2,0xc(%esp)
  1027c6:	00 
  1027c7:	c7 44 24 08 b6 ae 10 	movl   $0x10aeb6,0x8(%esp)
  1027ce:	00 
  1027cf:	c7 44 24 04 47 01 00 	movl   $0x147,0x4(%esp)
  1027d6:	00 
  1027d7:	c7 04 24 cf b1 10 00 	movl   $0x10b1cf,(%esp)
  1027de:	e8 b9 df ff ff       	call   10079c <debug_panic>

	// Illegal instruction trap
	args.reip = after_illegal;
  1027e3:	c7 45 e4 ec 27 10 00 	movl   $0x1027ec,0xffffffe4(%ebp)
	asm volatile("ud2; after_illegal:");	// guaranteed to be undefined
  1027ea:	0f 0b                	ud2a   

001027ec <after_illegal>:
	assert(args.trapno == T_ILLOP);
  1027ec:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  1027ef:	83 f8 06             	cmp    $0x6,%eax
  1027f2:	74 24                	je     102818 <after_illegal+0x2c>
  1027f4:	c7 44 24 0c b9 b3 10 	movl   $0x10b3b9,0xc(%esp)
  1027fb:	00 
  1027fc:	c7 44 24 08 b6 ae 10 	movl   $0x10aeb6,0x8(%esp)
  102803:	00 
  102804:	c7 44 24 04 4c 01 00 	movl   $0x14c,0x4(%esp)
  10280b:	00 
  10280c:	c7 04 24 cf b1 10 00 	movl   $0x10b1cf,(%esp)
  102813:	e8 84 df ff ff       	call   10079c <debug_panic>

	// General protection fault due to invalid segment load
	args.reip = after_gpfault;
  102818:	c7 45 e4 26 28 10 00 	movl   $0x102826,0xffffffe4(%ebp)
	asm volatile("movl %0,%%fs; after_gpfault:" : : "r" (-1));
  10281f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  102824:	8e e0                	movl   %eax,%fs

00102826 <after_gpfault>:
	assert(args.trapno == T_GPFLT);
  102826:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  102829:	83 f8 0d             	cmp    $0xd,%eax
  10282c:	74 24                	je     102852 <after_gpfault+0x2c>
  10282e:	c7 44 24 0c d0 b3 10 	movl   $0x10b3d0,0xc(%esp)
  102835:	00 
  102836:	c7 44 24 08 b6 ae 10 	movl   $0x10aeb6,0x8(%esp)
  10283d:	00 
  10283e:	c7 44 24 04 51 01 00 	movl   $0x151,0x4(%esp)
  102845:	00 
  102846:	c7 04 24 cf b1 10 00 	movl   $0x10b1cf,(%esp)
  10284d:	e8 4a df ff ff       	call   10079c <debug_panic>
static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  102852:	8c 4d f2             	movw   %cs,0xfffffff2(%ebp)
        return cs;
  102855:	0f b7 45 f2          	movzwl 0xfffffff2(%ebp),%eax

	// General protection fault due to privilege violation
	if (read_cs() & 3) {
  102859:	0f b7 c0             	movzwl %ax,%eax
  10285c:	83 e0 03             	and    $0x3,%eax
  10285f:	85 c0                	test   %eax,%eax
  102861:	74 3a                	je     10289d <after_priv+0x2c>
		args.reip = after_priv;
  102863:	c7 45 e4 71 28 10 00 	movl   $0x102871,0xffffffe4(%ebp)
		asm volatile("lidt %0; after_priv:" : : "m" (idt_pd));
  10286a:	0f 01 1d 04 e0 10 00 	lidtl  0x10e004

00102871 <after_priv>:
		assert(args.trapno == T_GPFLT);
  102871:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  102874:	83 f8 0d             	cmp    $0xd,%eax
  102877:	74 24                	je     10289d <after_priv+0x2c>
  102879:	c7 44 24 0c d0 b3 10 	movl   $0x10b3d0,0xc(%esp)
  102880:	00 
  102881:	c7 44 24 08 b6 ae 10 	movl   $0x10aeb6,0x8(%esp)
  102888:	00 
  102889:	c7 44 24 04 57 01 00 	movl   $0x157,0x4(%esp)
  102890:	00 
  102891:	c7 04 24 cf b1 10 00 	movl   $0x10b1cf,(%esp)
  102898:	e8 ff de ff ff       	call   10079c <debug_panic>
	}

	// Make sure our stack cookie is still with us
	assert(cookie == 0xfeedface);
  10289d:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  1028a0:	3d ce fa ed fe       	cmp    $0xfeedface,%eax
  1028a5:	74 24                	je     1028cb <after_priv+0x5a>
  1028a7:	c7 44 24 0c 5f b3 10 	movl   $0x10b35f,0xc(%esp)
  1028ae:	00 
  1028af:	c7 44 24 08 b6 ae 10 	movl   $0x10aeb6,0x8(%esp)
  1028b6:	00 
  1028b7:	c7 44 24 04 5b 01 00 	movl   $0x15b,0x4(%esp)
  1028be:	00 
  1028bf:	c7 04 24 cf b1 10 00 	movl   $0x10b1cf,(%esp)
  1028c6:	e8 d1 de ff ff       	call   10079c <debug_panic>

	*argsp = NULL;	// recovery mechanism not needed anymore
  1028cb:	8b 45 08             	mov    0x8(%ebp),%eax
  1028ce:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}
  1028d4:	83 c4 3c             	add    $0x3c,%esp
  1028d7:	5b                   	pop    %ebx
  1028d8:	5e                   	pop    %esi
  1028d9:	5f                   	pop    %edi
  1028da:	5d                   	pop    %ebp
  1028db:	c3                   	ret    
  1028dc:	90                   	nop    
  1028dd:	90                   	nop    
  1028de:	90                   	nop    
  1028df:	90                   	nop    

001028e0 <trap_divide>:

/*
 * Lab 1: Your code here for generating entry points for the different traps.
 */
TRAPHANDLER_NOEC(trap_divide,T_DIVIDE)
  1028e0:	6a 00                	push   $0x0
  1028e2:	6a 00                	push   $0x0
  1028e4:	e9 c4 00 00 00       	jmp    1029ad <_alltraps>
  1028e9:	90                   	nop    

001028ea <trap_nmi>:
//TRAPHANDLER(trap_debug,T_DEBUG)
TRAPHANDLER_NOEC(trap_nmi,T_NMI)
  1028ea:	6a 00                	push   $0x0
  1028ec:	6a 02                	push   $0x2
  1028ee:	e9 ba 00 00 00       	jmp    1029ad <_alltraps>
  1028f3:	90                   	nop    

001028f4 <trap_brkpt>:
TRAPHANDLER_NOEC(trap_brkpt,T_BRKPT)
  1028f4:	6a 00                	push   $0x0
  1028f6:	6a 03                	push   $0x3
  1028f8:	e9 b0 00 00 00       	jmp    1029ad <_alltraps>
  1028fd:	90                   	nop    

001028fe <trap_oflow>:
TRAPHANDLER_NOEC(trap_oflow,T_OFLOW)
  1028fe:	6a 00                	push   $0x0
  102900:	6a 04                	push   $0x4
  102902:	e9 a6 00 00 00       	jmp    1029ad <_alltraps>
  102907:	90                   	nop    

00102908 <trap_bound>:
TRAPHANDLER_NOEC(trap_bound,T_BOUND)
  102908:	6a 00                	push   $0x0
  10290a:	6a 05                	push   $0x5
  10290c:	e9 9c 00 00 00       	jmp    1029ad <_alltraps>
  102911:	90                   	nop    

00102912 <trap_illop>:
TRAPHANDLER_NOEC(trap_illop,T_ILLOP)
  102912:	6a 00                	push   $0x0
  102914:	6a 06                	push   $0x6
  102916:	e9 92 00 00 00       	jmp    1029ad <_alltraps>
  10291b:	90                   	nop    

0010291c <trap_device>:
TRAPHANDLER_NOEC(trap_device,T_DEVICE)
  10291c:	6a 00                	push   $0x0
  10291e:	6a 07                	push   $0x7
  102920:	e9 88 00 00 00       	jmp    1029ad <_alltraps>
  102925:	90                   	nop    

00102926 <trap_dblflt>:
TRAPHANDLER_NOEC(trap_dblflt,T_DBLFLT)
  102926:	6a 00                	push   $0x0
  102928:	6a 08                	push   $0x8
  10292a:	e9 7e 00 00 00       	jmp    1029ad <_alltraps>
  10292f:	90                   	nop    

00102930 <trap_tss>:
TRAPHANDLER     (trap_tss,T_TSS)
  102930:	6a 0a                	push   $0xa
  102932:	e9 76 00 00 00       	jmp    1029ad <_alltraps>
  102937:	90                   	nop    

00102938 <trap_segnp>:
TRAPHANDLER     (trap_segnp,T_SEGNP)
  102938:	6a 0b                	push   $0xb
  10293a:	e9 6e 00 00 00       	jmp    1029ad <_alltraps>
  10293f:	90                   	nop    

00102940 <trap_stack>:
TRAPHANDLER     (trap_stack,T_STACK)
  102940:	6a 0c                	push   $0xc
  102942:	e9 66 00 00 00       	jmp    1029ad <_alltraps>
  102947:	90                   	nop    

00102948 <trap_gpflt>:
TRAPHANDLER     (trap_gpflt,T_GPFLT)
  102948:	6a 0d                	push   $0xd
  10294a:	e9 5e 00 00 00       	jmp    1029ad <_alltraps>
  10294f:	90                   	nop    

00102950 <trap_pgflt>:
TRAPHANDLER     (trap_pgflt,T_PGFLT)
  102950:	6a 0e                	push   $0xe
  102952:	e9 56 00 00 00       	jmp    1029ad <_alltraps>
  102957:	90                   	nop    

00102958 <trap_fperr>:
TRAPHANDLER_NOEC(trap_fperr,T_FPERR)
  102958:	6a 00                	push   $0x0
  10295a:	6a 10                	push   $0x10
  10295c:	e9 4c 00 00 00       	jmp    1029ad <_alltraps>
  102961:	90                   	nop    

00102962 <trap_align>:
TRAPHANDLER_NOEC(trap_align,T_ALIGN)
  102962:	6a 00                	push   $0x0
  102964:	6a 11                	push   $0x11
  102966:	e9 42 00 00 00       	jmp    1029ad <_alltraps>
  10296b:	90                   	nop    

0010296c <trap_mchk>:
TRAPHANDLER     (trap_mchk,T_MCHK)
  10296c:	6a 12                	push   $0x12
  10296e:	e9 3a 00 00 00       	jmp    1029ad <_alltraps>
  102973:	90                   	nop    

00102974 <trap_simd>:
TRAPHANDLER_NOEC(trap_simd,T_SIMD)
  102974:	6a 00                	push   $0x0
  102976:	6a 13                	push   $0x13
  102978:	e9 30 00 00 00       	jmp    1029ad <_alltraps>
  10297d:	90                   	nop    

0010297e <trap_secev>:
TRAPHANDLER     (trap_secev,T_SECEV) //Not is intel doc
  10297e:	6a 1e                	push   $0x1e
  102980:	e9 28 00 00 00       	jmp    1029ad <_alltraps>
  102985:	90                   	nop    

00102986 <trap_irq0>:
TRAPHANDLER_NOEC(trap_irq0,T_IRQ0)
  102986:	6a 00                	push   $0x0
  102988:	6a 20                	push   $0x20
  10298a:	e9 1e 00 00 00       	jmp    1029ad <_alltraps>
  10298f:	90                   	nop    

00102990 <trap_syscall>:
TRAPHANDLER_NOEC(trap_syscall,T_SYSCALL)
  102990:	6a 00                	push   $0x0
  102992:	6a 30                	push   $0x30
  102994:	e9 14 00 00 00       	jmp    1029ad <_alltraps>
  102999:	90                   	nop    

0010299a <trap_ltimer>:
TRAPHANDLER_NOEC(trap_ltimer,T_LTIMER)
  10299a:	6a 00                	push   $0x0
  10299c:	6a 31                	push   $0x31
  10299e:	e9 0a 00 00 00       	jmp    1029ad <_alltraps>
  1029a3:	90                   	nop    

001029a4 <trap_lerror>:
TRAPHANDLER_NOEC(trap_lerror,T_LERROR)
  1029a4:	6a 00                	push   $0x0
  1029a6:	6a 32                	push   $0x32
  1029a8:	e9 00 00 00 00       	jmp    1029ad <_alltraps>

001029ad <_alltraps>:
//TRAPHANDLER   (trap_default,T_DEFAULT)
//TRAPHANDLER   (trap_icnt,T_ICNT)

/*
 * Lab 1: Your code here for _alltraps
 */
 .globl _alltraps
 _alltraps:
  // Build struct trapframe
  pushl %ds
  1029ad:	1e                   	push   %ds
  pushl %es
  1029ae:	06                   	push   %es
  pushl %fs
  1029af:	0f a0                	push   %fs
  pushl %gs
  1029b1:	0f a8                	push   %gs
  pushal;
  1029b3:	60                   	pusha  
  
  // load CPU_GDT_KDATA into %ds and %es
  movw $CPU_GDT_KDATA, %ax
  1029b4:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %es
  1029b8:	8e c0                	movl   %eax,%es
  movw %ax, %ds
  1029ba:	8e d8                	movl   %eax,%ds
  
  // push esp to pass a pointer to the trapframe as an argument to trap()
  pushl %esp;
  1029bc:	54                   	push   %esp

  // call trap
  call trap;
  1029bd:	e8 07 fa ff ff       	call   1023c9 <trap>
  1029c2:	8d b4 26 00 00 00 00 	lea    0x0(%esi),%esi
  1029c9:	8d bc 27 00 00 00 00 	lea    0x0(%edi),%edi

001029d0 <trap_return>:
  // never return



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
/*
 * Lab 1: Your code here for trap_return
 */
 movl 4(%esp), %esp
  1029d0:	8b 64 24 04          	mov    0x4(%esp),%esp
 popal
  1029d4:	61                   	popa   
 popl %gs
  1029d5:	0f a9                	pop    %gs
 popl %fs
  1029d7:	0f a1                	pop    %fs
 popl %es
  1029d9:	07                   	pop    %es
 popl %ds
  1029da:	1f                   	pop    %ds
 addl $8, %esp
  1029db:	83 c4 08             	add    $0x8,%esp
 iret
  1029de:	cf                   	iret   
  1029df:	90                   	nop    

001029e0 <sum>:


static uint8_t
sum(uint8_t * addr, int len)
{
  1029e0:	55                   	push   %ebp
  1029e1:	89 e5                	mov    %esp,%ebp
  1029e3:	83 ec 10             	sub    $0x10,%esp
	int i, sum;

	sum = 0;
  1029e6:	c7 45 fc 00 00 00 00 	movl   $0x0,0xfffffffc(%ebp)
	for (i = 0; i < len; i++)
  1029ed:	c7 45 f8 00 00 00 00 	movl   $0x0,0xfffffff8(%ebp)
  1029f4:	eb 13                	jmp    102a09 <sum+0x29>
		sum += addr[i];
  1029f6:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1029f9:	03 45 08             	add    0x8(%ebp),%eax
  1029fc:	0f b6 00             	movzbl (%eax),%eax
  1029ff:	0f b6 c0             	movzbl %al,%eax
  102a02:	01 45 fc             	add    %eax,0xfffffffc(%ebp)
  102a05:	83 45 f8 01          	addl   $0x1,0xfffffff8(%ebp)
  102a09:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  102a0c:	3b 45 0c             	cmp    0xc(%ebp),%eax
  102a0f:	7c e5                	jl     1029f6 <sum+0x16>
	return sum;
  102a11:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  102a14:	0f b6 c0             	movzbl %al,%eax
}
  102a17:	c9                   	leave  
  102a18:	c3                   	ret    

00102a19 <mpsearch1>:

//Look for an MP structure in the len bytes at addr.
static struct mp *
mpsearch1(uint8_t * addr, int len)
{
  102a19:	55                   	push   %ebp
  102a1a:	89 e5                	mov    %esp,%ebp
  102a1c:	83 ec 28             	sub    $0x28,%esp
	uint8_t *e, *p;

	e = addr + len;
  102a1f:	8b 45 0c             	mov    0xc(%ebp),%eax
  102a22:	03 45 08             	add    0x8(%ebp),%eax
  102a25:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
	for (p = addr; p < e; p += sizeof(struct mp))
  102a28:	8b 45 08             	mov    0x8(%ebp),%eax
  102a2b:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  102a2e:	eb 42                	jmp    102a72 <mpsearch1+0x59>
		if (memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
  102a30:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
  102a37:	00 
  102a38:	c7 44 24 04 e8 b3 10 	movl   $0x10b3e8,0x4(%esp)
  102a3f:	00 
  102a40:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  102a43:	89 04 24             	mov    %eax,(%esp)
  102a46:	e8 b6 7b 00 00       	call   10a601 <memcmp>
  102a4b:	85 c0                	test   %eax,%eax
  102a4d:	75 1f                	jne    102a6e <mpsearch1+0x55>
  102a4f:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
  102a56:	00 
  102a57:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  102a5a:	89 04 24             	mov    %eax,(%esp)
  102a5d:	e8 7e ff ff ff       	call   1029e0 <sum>
  102a62:	84 c0                	test   %al,%al
  102a64:	75 08                	jne    102a6e <mpsearch1+0x55>
			return (struct mp *) p;
  102a66:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  102a69:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  102a6c:	eb 13                	jmp    102a81 <mpsearch1+0x68>
  102a6e:	83 45 fc 10          	addl   $0x10,0xfffffffc(%ebp)
  102a72:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  102a75:	3b 45 f8             	cmp    0xfffffff8(%ebp),%eax
  102a78:	72 b6                	jb     102a30 <mpsearch1+0x17>
	return 0;
  102a7a:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  102a81:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
}
  102a84:	c9                   	leave  
  102a85:	c3                   	ret    

00102a86 <mpsearch>:

// Search for the MP Floating Pointer Structure, which according to the
// spec is in one of the following three locations:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp *
mpsearch(void)
{
  102a86:	55                   	push   %ebp
  102a87:	89 e5                	mov    %esp,%ebp
  102a89:	83 ec 28             	sub    $0x28,%esp
	uint8_t          *bda;
	uint32_t            p;
	struct mp      *mp;

	bda = (uint8_t *) 0x400;
  102a8c:	c7 45 f4 00 04 00 00 	movl   $0x400,0xfffffff4(%ebp)
	if ((p = ((bda[0x0F] << 8) | bda[0x0E]) << 4)) {
  102a93:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  102a96:	83 c0 0f             	add    $0xf,%eax
  102a99:	0f b6 00             	movzbl (%eax),%eax
  102a9c:	0f b6 c0             	movzbl %al,%eax
  102a9f:	89 c2                	mov    %eax,%edx
  102aa1:	c1 e2 08             	shl    $0x8,%edx
  102aa4:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  102aa7:	83 c0 0e             	add    $0xe,%eax
  102aaa:	0f b6 00             	movzbl (%eax),%eax
  102aad:	0f b6 c0             	movzbl %al,%eax
  102ab0:	09 d0                	or     %edx,%eax
  102ab2:	c1 e0 04             	shl    $0x4,%eax
  102ab5:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  102ab8:	83 7d f8 00          	cmpl   $0x0,0xfffffff8(%ebp)
  102abc:	74 24                	je     102ae2 <mpsearch+0x5c>
		if ((mp = mpsearch1((uint8_t *) p, 1024)))
  102abe:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  102ac1:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
  102ac8:	00 
  102ac9:	89 04 24             	mov    %eax,(%esp)
  102acc:	e8 48 ff ff ff       	call   102a19 <mpsearch1>
  102ad1:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  102ad4:	83 7d fc 00          	cmpl   $0x0,0xfffffffc(%ebp)
  102ad8:	74 56                	je     102b30 <mpsearch+0xaa>
			return mp;
  102ada:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  102add:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  102ae0:	eb 65                	jmp    102b47 <mpsearch+0xc1>
	} else {
		p = ((bda[0x14] << 8) | bda[0x13]) * 1024;
  102ae2:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  102ae5:	83 c0 14             	add    $0x14,%eax
  102ae8:	0f b6 00             	movzbl (%eax),%eax
  102aeb:	0f b6 c0             	movzbl %al,%eax
  102aee:	89 c2                	mov    %eax,%edx
  102af0:	c1 e2 08             	shl    $0x8,%edx
  102af3:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  102af6:	83 c0 13             	add    $0x13,%eax
  102af9:	0f b6 00             	movzbl (%eax),%eax
  102afc:	0f b6 c0             	movzbl %al,%eax
  102aff:	09 d0                	or     %edx,%eax
  102b01:	c1 e0 0a             	shl    $0xa,%eax
  102b04:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
		if ((mp = mpsearch1((uint8_t *) p - 1024, 1024)))
  102b07:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  102b0a:	2d 00 04 00 00       	sub    $0x400,%eax
  102b0f:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
  102b16:	00 
  102b17:	89 04 24             	mov    %eax,(%esp)
  102b1a:	e8 fa fe ff ff       	call   102a19 <mpsearch1>
  102b1f:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  102b22:	83 7d fc 00          	cmpl   $0x0,0xfffffffc(%ebp)
  102b26:	74 08                	je     102b30 <mpsearch+0xaa>
			return mp;
  102b28:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  102b2b:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  102b2e:	eb 17                	jmp    102b47 <mpsearch+0xc1>
	}
	return mpsearch1((uint8_t *) 0xF0000, 0x10000);
  102b30:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
  102b37:	00 
  102b38:	c7 04 24 00 00 0f 00 	movl   $0xf0000,(%esp)
  102b3f:	e8 d5 fe ff ff       	call   102a19 <mpsearch1>
  102b44:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  102b47:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
}
  102b4a:	c9                   	leave  
  102b4b:	c3                   	ret    

00102b4c <mpconfig>:

// Search for an MP configuration table.  For now,
// don 't accept the default configurations (physaddr == 0).
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf *
mpconfig(struct mp **pmp) {
  102b4c:	55                   	push   %ebp
  102b4d:	89 e5                	mov    %esp,%ebp
  102b4f:	83 ec 28             	sub    $0x28,%esp
	struct mpconf  *conf;
	struct mp      *mp;

	if ((mp = mpsearch()) == 0 || mp->physaddr == 0)
  102b52:	e8 2f ff ff ff       	call   102a86 <mpsearch>
  102b57:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  102b5a:	83 7d fc 00          	cmpl   $0x0,0xfffffffc(%ebp)
  102b5e:	74 0a                	je     102b6a <mpconfig+0x1e>
  102b60:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  102b63:	8b 40 04             	mov    0x4(%eax),%eax
  102b66:	85 c0                	test   %eax,%eax
  102b68:	75 0c                	jne    102b76 <mpconfig+0x2a>
		return 0;
  102b6a:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  102b71:	e9 84 00 00 00       	jmp    102bfa <mpconfig+0xae>
	conf = (struct mpconf *) mp->physaddr;
  102b76:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  102b79:	8b 40 04             	mov    0x4(%eax),%eax
  102b7c:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
	if (memcmp(conf, "PCMP", 4) != 0)
  102b7f:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
  102b86:	00 
  102b87:	c7 44 24 04 ed b3 10 	movl   $0x10b3ed,0x4(%esp)
  102b8e:	00 
  102b8f:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  102b92:	89 04 24             	mov    %eax,(%esp)
  102b95:	e8 67 7a 00 00       	call   10a601 <memcmp>
  102b9a:	85 c0                	test   %eax,%eax
  102b9c:	74 09                	je     102ba7 <mpconfig+0x5b>
		return 0;
  102b9e:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  102ba5:	eb 53                	jmp    102bfa <mpconfig+0xae>
	if (conf->version != 1 && conf->version != 4)
  102ba7:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  102baa:	0f b6 40 06          	movzbl 0x6(%eax),%eax
  102bae:	3c 01                	cmp    $0x1,%al
  102bb0:	74 14                	je     102bc6 <mpconfig+0x7a>
  102bb2:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  102bb5:	0f b6 40 06          	movzbl 0x6(%eax),%eax
  102bb9:	3c 04                	cmp    $0x4,%al
  102bbb:	74 09                	je     102bc6 <mpconfig+0x7a>
		return 0;
  102bbd:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  102bc4:	eb 34                	jmp    102bfa <mpconfig+0xae>
	if (sum((uint8_t *) conf, conf->length) != 0)
  102bc6:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  102bc9:	0f b7 40 04          	movzwl 0x4(%eax),%eax
  102bcd:	0f b7 c0             	movzwl %ax,%eax
  102bd0:	8b 55 f8             	mov    0xfffffff8(%ebp),%edx
  102bd3:	89 44 24 04          	mov    %eax,0x4(%esp)
  102bd7:	89 14 24             	mov    %edx,(%esp)
  102bda:	e8 01 fe ff ff       	call   1029e0 <sum>
  102bdf:	84 c0                	test   %al,%al
  102be1:	74 09                	je     102bec <mpconfig+0xa0>
		return 0;
  102be3:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  102bea:	eb 0e                	jmp    102bfa <mpconfig+0xae>
       *pmp = mp;
  102bec:	8b 55 08             	mov    0x8(%ebp),%edx
  102bef:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  102bf2:	89 02                	mov    %eax,(%edx)
	return conf;
  102bf4:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  102bf7:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  102bfa:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
}
  102bfd:	c9                   	leave  
  102bfe:	c3                   	ret    

00102bff <mp_init>:

void
mp_init(void)
{
  102bff:	55                   	push   %ebp
  102c00:	89 e5                	mov    %esp,%ebp
  102c02:	83 ec 58             	sub    $0x58,%esp
	uint8_t          *p, *e;
	struct mp      *mp;
	struct mpconf  *conf;
	struct mpproc  *proc;
	struct mpioapic *mpio;

	if (!cpu_onboot())	// only do once, on the boot CPU
  102c05:	e8 88 01 00 00       	call   102d92 <cpu_onboot>
  102c0a:	85 c0                	test   %eax,%eax
  102c0c:	0f 84 7e 01 00 00    	je     102d90 <mp_init+0x191>
		return;

	if ((conf = mpconfig(&mp)) == 0)
  102c12:	8d 45 cc             	lea    0xffffffcc(%ebp),%eax
  102c15:	89 04 24             	mov    %eax,(%esp)
  102c18:	e8 2f ff ff ff       	call   102b4c <mpconfig>
  102c1d:	89 45 d8             	mov    %eax,0xffffffd8(%ebp)
  102c20:	83 7d d8 00          	cmpl   $0x0,0xffffffd8(%ebp)
  102c24:	0f 84 66 01 00 00    	je     102d90 <mp_init+0x191>
		return; // Not a multiprocessor machine - just use boot CPU.

	ismp = 1;
  102c2a:	c7 05 a8 fd 11 00 01 	movl   $0x1,0x11fda8
  102c31:	00 00 00 
	lapic = (uint32_t *) conf->lapicaddr;
  102c34:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  102c37:	8b 40 24             	mov    0x24(%eax),%eax
  102c3a:	a3 04 30 12 00       	mov    %eax,0x123004
	for (p = (uint8_t *) (conf + 1), e = (uint8_t *) conf + conf->length;
  102c3f:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  102c42:	83 c0 2c             	add    $0x2c,%eax
  102c45:	89 45 d0             	mov    %eax,0xffffffd0(%ebp)
  102c48:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  102c4b:	0f b7 40 04          	movzwl 0x4(%eax),%eax
  102c4f:	0f b7 c0             	movzwl %ax,%eax
  102c52:	89 c2                	mov    %eax,%edx
  102c54:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  102c57:	8d 04 02             	lea    (%edx,%eax,1),%eax
  102c5a:	89 45 d4             	mov    %eax,0xffffffd4(%ebp)
			p < e;) {
  102c5d:	e9 da 00 00 00       	jmp    102d3c <mp_init+0x13d>
		switch (*p) {
  102c62:	8b 45 d0             	mov    0xffffffd0(%ebp),%eax
  102c65:	0f b6 00             	movzbl (%eax),%eax
  102c68:	0f b6 c0             	movzbl %al,%eax
  102c6b:	89 45 b8             	mov    %eax,0xffffffb8(%ebp)
  102c6e:	83 7d b8 04          	cmpl   $0x4,0xffffffb8(%ebp)
  102c72:	0f 87 9b 00 00 00    	ja     102d13 <mp_init+0x114>
  102c78:	8b 55 b8             	mov    0xffffffb8(%ebp),%edx
  102c7b:	8b 04 95 20 b4 10 00 	mov    0x10b420(,%edx,4),%eax
  102c82:	ff e0                	jmp    *%eax
		case MPPROC:
			proc = (struct mpproc *) p;
  102c84:	8b 45 d0             	mov    0xffffffd0(%ebp),%eax
  102c87:	89 45 dc             	mov    %eax,0xffffffdc(%ebp)
			p += sizeof(struct mpproc);
  102c8a:	83 45 d0 14          	addl   $0x14,0xffffffd0(%ebp)
			if (!(proc->flags & MPENAB))
  102c8e:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  102c91:	0f b6 40 03          	movzbl 0x3(%eax),%eax
  102c95:	0f b6 c0             	movzbl %al,%eax
  102c98:	83 e0 01             	and    $0x1,%eax
  102c9b:	85 c0                	test   %eax,%eax
  102c9d:	0f 84 99 00 00 00    	je     102d3c <mp_init+0x13d>
				continue;	// processor disabled

			// Get a cpu struct and kernel stack for this CPU.
			cpu *c = (proc->flags & MPBOOT)
					? &cpu_boot : cpu_alloc();
  102ca3:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  102ca6:	0f b6 40 03          	movzbl 0x3(%eax),%eax
  102caa:	0f b6 c0             	movzbl %al,%eax
  102cad:	83 e0 02             	and    $0x2,%eax
  102cb0:	85 c0                	test   %eax,%eax
  102cb2:	75 0a                	jne    102cbe <mp_init+0xbf>
  102cb4:	e8 d9 e8 ff ff       	call   101592 <cpu_alloc>
  102cb9:	89 45 bc             	mov    %eax,0xffffffbc(%ebp)
  102cbc:	eb 07                	jmp    102cc5 <mp_init+0xc6>
  102cbe:	c7 45 bc 00 d0 10 00 	movl   $0x10d000,0xffffffbc(%ebp)
  102cc5:	8b 45 bc             	mov    0xffffffbc(%ebp),%eax
  102cc8:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
			c->id = proc->apicid;
  102ccb:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  102cce:	0f b6 50 01          	movzbl 0x1(%eax),%edx
  102cd2:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  102cd5:	88 90 ac 00 00 00    	mov    %dl,0xac(%eax)
			ncpu++;
  102cdb:	a1 ac fd 11 00       	mov    0x11fdac,%eax
  102ce0:	83 c0 01             	add    $0x1,%eax
  102ce3:	a3 ac fd 11 00       	mov    %eax,0x11fdac
			continue;
  102ce8:	eb 52                	jmp    102d3c <mp_init+0x13d>
		case MPIOAPIC:
			mpio = (struct mpioapic *) p;
  102cea:	8b 45 d0             	mov    0xffffffd0(%ebp),%eax
  102ced:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)
			p += sizeof(struct mpioapic);
  102cf0:	83 45 d0 08          	addl   $0x8,0xffffffd0(%ebp)
			ioapicid = mpio->apicno;
  102cf4:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  102cf7:	0f b6 40 01          	movzbl 0x1(%eax),%eax
  102cfb:	a2 a0 fd 11 00       	mov    %al,0x11fda0
			ioapic = (struct ioapic *) mpio->addr;
  102d00:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  102d03:	8b 40 04             	mov    0x4(%eax),%eax
  102d06:	a3 a4 fd 11 00       	mov    %eax,0x11fda4
			continue;
  102d0b:	eb 2f                	jmp    102d3c <mp_init+0x13d>
		case MPBUS:
		case MPIOINTR:
		case MPLINTR:
			p += 8;
  102d0d:	83 45 d0 08          	addl   $0x8,0xffffffd0(%ebp)
			continue;
  102d11:	eb 29                	jmp    102d3c <mp_init+0x13d>
		default:
			panic("mpinit: unknown config type %x\n", *p);
  102d13:	8b 45 d0             	mov    0xffffffd0(%ebp),%eax
  102d16:	0f b6 00             	movzbl (%eax),%eax
  102d19:	0f b6 c0             	movzbl %al,%eax
  102d1c:	89 44 24 0c          	mov    %eax,0xc(%esp)
  102d20:	c7 44 24 08 f4 b3 10 	movl   $0x10b3f4,0x8(%esp)
  102d27:	00 
  102d28:	c7 44 24 04 92 00 00 	movl   $0x92,0x4(%esp)
  102d2f:	00 
  102d30:	c7 04 24 14 b4 10 00 	movl   $0x10b414,(%esp)
  102d37:	e8 60 da ff ff       	call   10079c <debug_panic>
  102d3c:	8b 45 d0             	mov    0xffffffd0(%ebp),%eax
  102d3f:	3b 45 d4             	cmp    0xffffffd4(%ebp),%eax
  102d42:	0f 82 1a ff ff ff    	jb     102c62 <mp_init+0x63>
		}
	}
	if (mp->imcrp) {
  102d48:	8b 45 cc             	mov    0xffffffcc(%ebp),%eax
  102d4b:	0f b6 40 0c          	movzbl 0xc(%eax),%eax
  102d4f:	84 c0                	test   %al,%al
  102d51:	74 3d                	je     102d90 <mp_init+0x191>
  102d53:	c7 45 ec 22 00 00 00 	movl   $0x22,0xffffffec(%ebp)
  102d5a:	c6 45 eb 70          	movb   $0x70,0xffffffeb(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  102d5e:	0f b6 45 eb          	movzbl 0xffffffeb(%ebp),%eax
  102d62:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
  102d65:	ee                   	out    %al,(%dx)
  102d66:	c7 45 f4 23 00 00 00 	movl   $0x23,0xfffffff4(%ebp)
  102d6d:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  102d70:	ec                   	in     (%dx),%al
  102d71:	88 45 f3             	mov    %al,0xfffffff3(%ebp)
  102d74:	0f b6 45 f3          	movzbl 0xfffffff3(%ebp),%eax
		// Bochs doesn 't support IMCR, so this doesn' t run on Bochs.
		// But it would on real hardware.
		outb(0x22, 0x70);		// Select IMCR
		outb(0x23, inb(0x23) | 1);	// Mask external interrupts.
  102d78:	83 c8 01             	or     $0x1,%eax
  102d7b:	0f b6 c0             	movzbl %al,%eax
  102d7e:	c7 45 fc 23 00 00 00 	movl   $0x23,0xfffffffc(%ebp)
  102d85:	88 45 fb             	mov    %al,0xfffffffb(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  102d88:	0f b6 45 fb          	movzbl 0xfffffffb(%ebp),%eax
  102d8c:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  102d8f:	ee                   	out    %al,(%dx)
	}
}
  102d90:	c9                   	leave  
  102d91:	c3                   	ret    

00102d92 <cpu_onboot>:
}

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  102d92:	55                   	push   %ebp
  102d93:	89 e5                	mov    %esp,%ebp
  102d95:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  102d98:	e8 0d 00 00 00       	call   102daa <cpu_cur>
  102d9d:	3d 00 d0 10 00       	cmp    $0x10d000,%eax
  102da2:	0f 94 c0             	sete   %al
  102da5:	0f b6 c0             	movzbl %al,%eax
}
  102da8:	c9                   	leave  
  102da9:	c3                   	ret    

00102daa <cpu_cur>:
  102daa:	55                   	push   %ebp
  102dab:	89 e5                	mov    %esp,%ebp
  102dad:	83 ec 28             	sub    $0x28,%esp
static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  102db0:	89 65 fc             	mov    %esp,0xfffffffc(%ebp)
        return esp;
  102db3:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  102db6:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  102db9:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  102dbc:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  102dc1:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	assert(c->magic == CPU_MAGIC);
  102dc4:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  102dc7:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  102dcd:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  102dd2:	74 24                	je     102df8 <cpu_cur+0x4e>
  102dd4:	c7 44 24 0c 34 b4 10 	movl   $0x10b434,0xc(%esp)
  102ddb:	00 
  102ddc:	c7 44 24 08 4a b4 10 	movl   $0x10b44a,0x8(%esp)
  102de3:	00 
  102de4:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  102deb:	00 
  102dec:	c7 04 24 5f b4 10 00 	movl   $0x10b45f,(%esp)
  102df3:	e8 a4 d9 ff ff       	call   10079c <debug_panic>
	return c;
  102df8:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
}
  102dfb:	c9                   	leave  
  102dfc:	c3                   	ret    
  102dfd:	90                   	nop    
  102dfe:	90                   	nop    
  102dff:	90                   	nop    

00102e00 <spinlock_init_>:


void
spinlock_init_(struct spinlock *lk, const char *file, int line)
{
  102e00:	55                   	push   %ebp
  102e01:	89 e5                	mov    %esp,%ebp
  lk->file = file;
  102e03:	8b 55 08             	mov    0x8(%ebp),%edx
  102e06:	8b 45 0c             	mov    0xc(%ebp),%eax
  102e09:	89 42 04             	mov    %eax,0x4(%edx)
  lk->line = line;
  102e0c:	8b 55 08             	mov    0x8(%ebp),%edx
  102e0f:	8b 45 10             	mov    0x10(%ebp),%eax
  102e12:	89 42 08             	mov    %eax,0x8(%edx)
  lk->locked = 0;
  102e15:	8b 45 08             	mov    0x8(%ebp),%eax
  102e18:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->cpu = NULL;
  102e1e:	8b 45 08             	mov    0x8(%ebp),%eax
  102e21:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
}
  102e28:	5d                   	pop    %ebp
  102e29:	c3                   	ret    

00102e2a <spinlock_acquire>:

// Acquire the lock.
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
spinlock_acquire(struct spinlock *lk)
{
  102e2a:	55                   	push   %ebp
  102e2b:	89 e5                	mov    %esp,%ebp
  102e2d:	83 ec 28             	sub    $0x28,%esp
  if (spinlock_holding(lk))
  102e30:	8b 45 08             	mov    0x8(%ebp),%eax
  102e33:	89 04 24             	mov    %eax,(%esp)
  102e36:	e8 44 01 00 00       	call   102f7f <spinlock_holding>
  102e3b:	85 c0                	test   %eax,%eax
  102e3d:	74 21                	je     102e60 <spinlock_acquire+0x36>
    panic("Attempt to acquire lock already held by this cpu");
  102e3f:	c7 44 24 08 6c b4 10 	movl   $0x10b46c,0x8(%esp)
  102e46:	00 
  102e47:	c7 44 24 04 24 00 00 	movl   $0x24,0x4(%esp)
  102e4e:	00 
  102e4f:	c7 04 24 9d b4 10 00 	movl   $0x10b49d,(%esp)
  102e56:	e8 41 d9 ff ff       	call   10079c <debug_panic>
  while(xchg(&lk->locked, 1) != 0) {
    pause(); // buisy wait
  102e5b:	e8 3e 00 00 00       	call   102e9e <pause>
  102e60:	8b 45 08             	mov    0x8(%ebp),%eax
  102e63:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  102e6a:	00 
  102e6b:	89 04 24             	mov    %eax,(%esp)
  102e6e:	e8 32 00 00 00       	call   102ea5 <xchg>
  102e73:	85 c0                	test   %eax,%eax
  102e75:	75 e4                	jne    102e5b <spinlock_acquire+0x31>
  }
  lk->cpu = cpu_cur();
  102e77:	e8 56 00 00 00       	call   102ed2 <cpu_cur>
  102e7c:	89 c2                	mov    %eax,%edx
  102e7e:	8b 45 08             	mov    0x8(%ebp),%eax
  102e81:	89 50 0c             	mov    %edx,0xc(%eax)
  debug_trace(read_ebp(), lk->eips);
  102e84:	8b 55 08             	mov    0x8(%ebp),%edx
  102e87:	83 c2 10             	add    $0x10,%edx
static gcc_inline uint32_t
read_ebp(void)
{
        uint32_t ebp;
        __asm __volatile("movl %%ebp,%0" : "=rm" (ebp));
  102e8a:	89 6d fc             	mov    %ebp,0xfffffffc(%ebp)
        return ebp;
  102e8d:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  102e90:	89 54 24 04          	mov    %edx,0x4(%esp)
  102e94:	89 04 24             	mov    %eax,(%esp)
  102e97:	e8 07 da ff ff       	call   1008a3 <debug_trace>
}
  102e9c:	c9                   	leave  
  102e9d:	c3                   	ret    

00102e9e <pause>:
}

static inline void
pause(void)
{
  102e9e:	55                   	push   %ebp
  102e9f:	89 e5                	mov    %esp,%ebp
	asm volatile("pause" : : : "memory");
  102ea1:	f3 90                	pause  
}
  102ea3:	5d                   	pop    %ebp
  102ea4:	c3                   	ret    

00102ea5 <xchg>:
  102ea5:	55                   	push   %ebp
  102ea6:	89 e5                	mov    %esp,%ebp
  102ea8:	53                   	push   %ebx
  102ea9:	83 ec 14             	sub    $0x14,%esp
  102eac:	8b 4d 08             	mov    0x8(%ebp),%ecx
  102eaf:	8b 55 0c             	mov    0xc(%ebp),%edx
  102eb2:	8b 45 08             	mov    0x8(%ebp),%eax
  102eb5:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  102eb8:	89 d0                	mov    %edx,%eax
  102eba:	8b 5d e8             	mov    0xffffffe8(%ebp),%ebx
  102ebd:	f0 87 01             	lock xchg %eax,(%ecx)
  102ec0:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  102ec3:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  102ec6:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  102ec9:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  102ecc:	83 c4 14             	add    $0x14,%esp
  102ecf:	5b                   	pop    %ebx
  102ed0:	5d                   	pop    %ebp
  102ed1:	c3                   	ret    

00102ed2 <cpu_cur>:

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  102ed2:	55                   	push   %ebp
  102ed3:	89 e5                	mov    %esp,%ebp
  102ed5:	83 ec 28             	sub    $0x28,%esp
static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  102ed8:	89 65 fc             	mov    %esp,0xfffffffc(%ebp)
        return esp;
  102edb:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  102ede:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  102ee1:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  102ee4:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  102ee9:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	assert(c->magic == CPU_MAGIC);
  102eec:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  102eef:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  102ef5:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  102efa:	74 24                	je     102f20 <cpu_cur+0x4e>
  102efc:	c7 44 24 0c ad b4 10 	movl   $0x10b4ad,0xc(%esp)
  102f03:	00 
  102f04:	c7 44 24 08 c3 b4 10 	movl   $0x10b4c3,0x8(%esp)
  102f0b:	00 
  102f0c:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  102f13:	00 
  102f14:	c7 04 24 d8 b4 10 00 	movl   $0x10b4d8,(%esp)
  102f1b:	e8 7c d8 ff ff       	call   10079c <debug_panic>
	return c;
  102f20:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
}
  102f23:	c9                   	leave  
  102f24:	c3                   	ret    

00102f25 <spinlock_release>:

// Release the lock.
void
spinlock_release(struct spinlock *lk)
{
  102f25:	55                   	push   %ebp
  102f26:	89 e5                	mov    %esp,%ebp
  102f28:	83 ec 18             	sub    $0x18,%esp
  if (!spinlock_holding(lk))
  102f2b:	8b 45 08             	mov    0x8(%ebp),%eax
  102f2e:	89 04 24             	mov    %eax,(%esp)
  102f31:	e8 49 00 00 00       	call   102f7f <spinlock_holding>
  102f36:	85 c0                	test   %eax,%eax
  102f38:	75 1c                	jne    102f56 <spinlock_release+0x31>
    panic("Attempt to release lock not held by this cpu");
  102f3a:	c7 44 24 08 e8 b4 10 	movl   $0x10b4e8,0x8(%esp)
  102f41:	00 
  102f42:	c7 44 24 04 31 00 00 	movl   $0x31,0x4(%esp)
  102f49:	00 
  102f4a:	c7 04 24 9d b4 10 00 	movl   $0x10b49d,(%esp)
  102f51:	e8 46 d8 ff ff       	call   10079c <debug_panic>
  lk->eips[0] = 0;
  102f56:	8b 45 08             	mov    0x8(%ebp),%eax
  102f59:	c7 40 10 00 00 00 00 	movl   $0x0,0x10(%eax)
  lk->cpu = 0;
  102f60:	8b 45 08             	mov    0x8(%ebp),%eax
  102f63:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  xchg(&lk->locked, 0);
  102f6a:	8b 45 08             	mov    0x8(%ebp),%eax
  102f6d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  102f74:	00 
  102f75:	89 04 24             	mov    %eax,(%esp)
  102f78:	e8 28 ff ff ff       	call   102ea5 <xchg>
}
  102f7d:	c9                   	leave  
  102f7e:	c3                   	ret    

00102f7f <spinlock_holding>:

// Check whether this cpu is holding the lock.
int
spinlock_holding(spinlock *lk)
{
  102f7f:	55                   	push   %ebp
  102f80:	89 e5                	mov    %esp,%ebp
  102f82:	53                   	push   %ebx
  102f83:	83 ec 04             	sub    $0x4,%esp
  return (lk->locked) && (lk->cpu == cpu_cur());
  102f86:	8b 45 08             	mov    0x8(%ebp),%eax
  102f89:	8b 00                	mov    (%eax),%eax
  102f8b:	85 c0                	test   %eax,%eax
  102f8d:	74 18                	je     102fa7 <spinlock_holding+0x28>
  102f8f:	8b 45 08             	mov    0x8(%ebp),%eax
  102f92:	8b 58 0c             	mov    0xc(%eax),%ebx
  102f95:	e8 38 ff ff ff       	call   102ed2 <cpu_cur>
  102f9a:	39 c3                	cmp    %eax,%ebx
  102f9c:	75 09                	jne    102fa7 <spinlock_holding+0x28>
  102f9e:	c7 45 f8 01 00 00 00 	movl   $0x1,0xfffffff8(%ebp)
  102fa5:	eb 07                	jmp    102fae <spinlock_holding+0x2f>
  102fa7:	c7 45 f8 00 00 00 00 	movl   $0x0,0xfffffff8(%ebp)
  102fae:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
}
  102fb1:	83 c4 04             	add    $0x4,%esp
  102fb4:	5b                   	pop    %ebx
  102fb5:	5d                   	pop    %ebp
  102fb6:	c3                   	ret    

00102fb7 <spinlock_godeep>:

// Function that simply recurses to a specified depth.
// The useless return value and volatile parameter are
// so GCC doesn't collapse it via tail-call elimination.
int gcc_noinline
spinlock_godeep(volatile int depth, spinlock* lk)
{
  102fb7:	55                   	push   %ebp
  102fb8:	89 e5                	mov    %esp,%ebp
  102fba:	83 ec 18             	sub    $0x18,%esp
	if (depth==0) { spinlock_acquire(lk); return 1; }
  102fbd:	8b 45 08             	mov    0x8(%ebp),%eax
  102fc0:	85 c0                	test   %eax,%eax
  102fc2:	75 14                	jne    102fd8 <spinlock_godeep+0x21>
  102fc4:	8b 45 0c             	mov    0xc(%ebp),%eax
  102fc7:	89 04 24             	mov    %eax,(%esp)
  102fca:	e8 5b fe ff ff       	call   102e2a <spinlock_acquire>
  102fcf:	c7 45 fc 01 00 00 00 	movl   $0x1,0xfffffffc(%ebp)
  102fd6:	eb 22                	jmp    102ffa <spinlock_godeep+0x43>
	else return spinlock_godeep(depth-1, lk) * depth;
  102fd8:	8b 45 08             	mov    0x8(%ebp),%eax
  102fdb:	8d 50 ff             	lea    0xffffffff(%eax),%edx
  102fde:	8b 45 0c             	mov    0xc(%ebp),%eax
  102fe1:	89 44 24 04          	mov    %eax,0x4(%esp)
  102fe5:	89 14 24             	mov    %edx,(%esp)
  102fe8:	e8 ca ff ff ff       	call   102fb7 <spinlock_godeep>
  102fed:	89 c2                	mov    %eax,%edx
  102fef:	8b 45 08             	mov    0x8(%ebp),%eax
  102ff2:	89 d1                	mov    %edx,%ecx
  102ff4:	0f af c8             	imul   %eax,%ecx
  102ff7:	89 4d fc             	mov    %ecx,0xfffffffc(%ebp)
  102ffa:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
}
  102ffd:	c9                   	leave  
  102ffe:	c3                   	ret    

00102fff <spinlock_check>:

void spinlock_check()
{
  102fff:	55                   	push   %ebp
  103000:	89 e5                	mov    %esp,%ebp
  103002:	53                   	push   %ebx
  103003:	83 ec 44             	sub    $0x44,%esp
  103006:	89 e0                	mov    %esp,%eax
  103008:	89 45 d8             	mov    %eax,0xffffffd8(%ebp)
	const int NUMLOCKS=10;
  10300b:	c7 45 e4 0a 00 00 00 	movl   $0xa,0xffffffe4(%ebp)
	const int NUMRUNS=5;
  103012:	c7 45 e8 05 00 00 00 	movl   $0x5,0xffffffe8(%ebp)
	int i,j,run;
	const char* file = "spinlock_check";
  103019:	c7 45 f8 15 b5 10 00 	movl   $0x10b515,0xfffffff8(%ebp)
	spinlock locks[NUMLOCKS];
  103020:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  103023:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  10302a:	8d 04 d5 00 00 00 00 	lea    0x0(,%edx,8),%eax
  103031:	29 d0                	sub    %edx,%eax
  103033:	83 c0 0f             	add    $0xf,%eax
  103036:	83 c0 0f             	add    $0xf,%eax
  103039:	c1 e8 04             	shr    $0x4,%eax
  10303c:	c1 e0 04             	shl    $0x4,%eax
  10303f:	29 c4                	sub    %eax,%esp
  103041:	8d 44 24 10          	lea    0x10(%esp),%eax
  103045:	89 45 d4             	mov    %eax,0xffffffd4(%ebp)
  103048:	8b 45 d4             	mov    0xffffffd4(%ebp),%eax
  10304b:	83 c0 0f             	add    $0xf,%eax
  10304e:	c1 e8 04             	shr    $0x4,%eax
  103051:	c1 e0 04             	shl    $0x4,%eax
  103054:	89 45 d4             	mov    %eax,0xffffffd4(%ebp)
  103057:	8b 45 d4             	mov    0xffffffd4(%ebp),%eax
  10305a:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)

	// Initialize the locks
	for(i=0;i<NUMLOCKS;i++) spinlock_init_(&locks[i], file, 0);
  10305d:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  103064:	eb 34                	jmp    10309a <spinlock_check+0x9b>
  103066:	8b 4d e0             	mov    0xffffffe0(%ebp),%ecx
  103069:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  10306c:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  103073:	8d 04 d5 00 00 00 00 	lea    0x0(,%edx,8),%eax
  10307a:	29 d0                	sub    %edx,%eax
  10307c:	8d 14 01             	lea    (%ecx,%eax,1),%edx
  10307f:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  103086:	00 
  103087:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10308a:	89 44 24 04          	mov    %eax,0x4(%esp)
  10308e:	89 14 24             	mov    %edx,(%esp)
  103091:	e8 6a fd ff ff       	call   102e00 <spinlock_init_>
  103096:	83 45 ec 01          	addl   $0x1,0xffffffec(%ebp)
  10309a:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  10309d:	3b 45 e4             	cmp    0xffffffe4(%ebp),%eax
  1030a0:	7c c4                	jl     103066 <spinlock_check+0x67>
	// Make sure that all locks have CPU set to NULL initially
	for(i=0;i<NUMLOCKS;i++) assert(locks[i].cpu==NULL);
  1030a2:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  1030a9:	eb 49                	jmp    1030f4 <spinlock_check+0xf5>
  1030ab:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  1030ae:	8b 4d e0             	mov    0xffffffe0(%ebp),%ecx
  1030b1:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  1030b8:	8d 04 d5 00 00 00 00 	lea    0x0(,%edx,8),%eax
  1030bf:	29 d0                	sub    %edx,%eax
  1030c1:	01 c8                	add    %ecx,%eax
  1030c3:	83 c0 0c             	add    $0xc,%eax
  1030c6:	8b 00                	mov    (%eax),%eax
  1030c8:	85 c0                	test   %eax,%eax
  1030ca:	74 24                	je     1030f0 <spinlock_check+0xf1>
  1030cc:	c7 44 24 0c 24 b5 10 	movl   $0x10b524,0xc(%esp)
  1030d3:	00 
  1030d4:	c7 44 24 08 c3 b4 10 	movl   $0x10b4c3,0x8(%esp)
  1030db:	00 
  1030dc:	c7 44 24 04 53 00 00 	movl   $0x53,0x4(%esp)
  1030e3:	00 
  1030e4:	c7 04 24 9d b4 10 00 	movl   $0x10b49d,(%esp)
  1030eb:	e8 ac d6 ff ff       	call   10079c <debug_panic>
  1030f0:	83 45 ec 01          	addl   $0x1,0xffffffec(%ebp)
  1030f4:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  1030f7:	3b 45 e4             	cmp    0xffffffe4(%ebp),%eax
  1030fa:	7c af                	jl     1030ab <spinlock_check+0xac>
	// Make sure that all locks have the correct debug info.
	for(i=0;i<NUMLOCKS;i++) assert(locks[i].file==file);
  1030fc:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  103103:	eb 4a                	jmp    10314f <spinlock_check+0x150>
  103105:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  103108:	8b 4d e0             	mov    0xffffffe0(%ebp),%ecx
  10310b:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  103112:	8d 04 d5 00 00 00 00 	lea    0x0(,%edx,8),%eax
  103119:	29 d0                	sub    %edx,%eax
  10311b:	01 c8                	add    %ecx,%eax
  10311d:	83 c0 04             	add    $0x4,%eax
  103120:	8b 00                	mov    (%eax),%eax
  103122:	3b 45 f8             	cmp    0xfffffff8(%ebp),%eax
  103125:	74 24                	je     10314b <spinlock_check+0x14c>
  103127:	c7 44 24 0c 37 b5 10 	movl   $0x10b537,0xc(%esp)
  10312e:	00 
  10312f:	c7 44 24 08 c3 b4 10 	movl   $0x10b4c3,0x8(%esp)
  103136:	00 
  103137:	c7 44 24 04 55 00 00 	movl   $0x55,0x4(%esp)
  10313e:	00 
  10313f:	c7 04 24 9d b4 10 00 	movl   $0x10b49d,(%esp)
  103146:	e8 51 d6 ff ff       	call   10079c <debug_panic>
  10314b:	83 45 ec 01          	addl   $0x1,0xffffffec(%ebp)
  10314f:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  103152:	3b 45 e4             	cmp    0xffffffe4(%ebp),%eax
  103155:	7c ae                	jl     103105 <spinlock_check+0x106>

	for (run=0;run<NUMRUNS;run++) 
  103157:	c7 45 f4 00 00 00 00 	movl   $0x0,0xfffffff4(%ebp)
  10315e:	e9 17 03 00 00       	jmp    10347a <spinlock_check+0x47b>
	{
		// Lock all locks
		for(i=0;i<NUMLOCKS;i++)
  103163:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  10316a:	eb 2c                	jmp    103198 <spinlock_check+0x199>
			spinlock_godeep(i, &locks[i]);
  10316c:	8b 4d e0             	mov    0xffffffe0(%ebp),%ecx
  10316f:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  103172:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  103179:	8d 04 d5 00 00 00 00 	lea    0x0(,%edx,8),%eax
  103180:	29 d0                	sub    %edx,%eax
  103182:	8d 04 01             	lea    (%ecx,%eax,1),%eax
  103185:	89 44 24 04          	mov    %eax,0x4(%esp)
  103189:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  10318c:	89 04 24             	mov    %eax,(%esp)
  10318f:	e8 23 fe ff ff       	call   102fb7 <spinlock_godeep>
  103194:	83 45 ec 01          	addl   $0x1,0xffffffec(%ebp)
  103198:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  10319b:	3b 45 e4             	cmp    0xffffffe4(%ebp),%eax
  10319e:	7c cc                	jl     10316c <spinlock_check+0x16d>

		// Make sure that all locks have the right CPU
		for(i=0;i<NUMLOCKS;i++)
  1031a0:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  1031a7:	eb 4e                	jmp    1031f7 <spinlock_check+0x1f8>
			assert(locks[i].cpu == cpu_cur());
  1031a9:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  1031ac:	8b 4d e0             	mov    0xffffffe0(%ebp),%ecx
  1031af:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  1031b6:	8d 04 d5 00 00 00 00 	lea    0x0(,%edx,8),%eax
  1031bd:	29 d0                	sub    %edx,%eax
  1031bf:	01 c8                	add    %ecx,%eax
  1031c1:	83 c0 0c             	add    $0xc,%eax
  1031c4:	8b 18                	mov    (%eax),%ebx
  1031c6:	e8 07 fd ff ff       	call   102ed2 <cpu_cur>
  1031cb:	39 c3                	cmp    %eax,%ebx
  1031cd:	74 24                	je     1031f3 <spinlock_check+0x1f4>
  1031cf:	c7 44 24 0c 4b b5 10 	movl   $0x10b54b,0xc(%esp)
  1031d6:	00 
  1031d7:	c7 44 24 08 c3 b4 10 	movl   $0x10b4c3,0x8(%esp)
  1031de:	00 
  1031df:	c7 44 24 04 5f 00 00 	movl   $0x5f,0x4(%esp)
  1031e6:	00 
  1031e7:	c7 04 24 9d b4 10 00 	movl   $0x10b49d,(%esp)
  1031ee:	e8 a9 d5 ff ff       	call   10079c <debug_panic>
  1031f3:	83 45 ec 01          	addl   $0x1,0xffffffec(%ebp)
  1031f7:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  1031fa:	3b 45 e4             	cmp    0xffffffe4(%ebp),%eax
  1031fd:	7c aa                	jl     1031a9 <spinlock_check+0x1aa>
		// Make sure that all locks have holding correctly implemented.
		for(i=0;i<NUMLOCKS;i++)
  1031ff:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  103206:	eb 4d                	jmp    103255 <spinlock_check+0x256>
			assert(spinlock_holding(&locks[i]) != 0);
  103208:	8b 4d e0             	mov    0xffffffe0(%ebp),%ecx
  10320b:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  10320e:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  103215:	8d 04 d5 00 00 00 00 	lea    0x0(,%edx,8),%eax
  10321c:	29 d0                	sub    %edx,%eax
  10321e:	8d 04 01             	lea    (%ecx,%eax,1),%eax
  103221:	89 04 24             	mov    %eax,(%esp)
  103224:	e8 56 fd ff ff       	call   102f7f <spinlock_holding>
  103229:	85 c0                	test   %eax,%eax
  10322b:	75 24                	jne    103251 <spinlock_check+0x252>
  10322d:	c7 44 24 0c 68 b5 10 	movl   $0x10b568,0xc(%esp)
  103234:	00 
  103235:	c7 44 24 08 c3 b4 10 	movl   $0x10b4c3,0x8(%esp)
  10323c:	00 
  10323d:	c7 44 24 04 62 00 00 	movl   $0x62,0x4(%esp)
  103244:	00 
  103245:	c7 04 24 9d b4 10 00 	movl   $0x10b49d,(%esp)
  10324c:	e8 4b d5 ff ff       	call   10079c <debug_panic>
  103251:	83 45 ec 01          	addl   $0x1,0xffffffec(%ebp)
  103255:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  103258:	3b 45 e4             	cmp    0xffffffe4(%ebp),%eax
  10325b:	7c ab                	jl     103208 <spinlock_check+0x209>
		// Make sure that top i frames are somewhere in godeep.
		for(i=0;i<NUMLOCKS;i++) 
  10325d:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  103264:	e9 b9 00 00 00       	jmp    103322 <spinlock_check+0x323>
		{
			for(j=0; j<=i && j < DEBUG_TRACEFRAMES ; j++) 
  103269:	c7 45 f0 00 00 00 00 	movl   $0x0,0xfffffff0(%ebp)
  103270:	e9 97 00 00 00       	jmp    10330c <spinlock_check+0x30d>
			{
				assert(locks[i].eips[j] >=
  103275:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  103278:	8b 4d f0             	mov    0xfffffff0(%ebp),%ecx
  10327b:	8b 5d e0             	mov    0xffffffe0(%ebp),%ebx
  10327e:	8d 14 00             	lea    (%eax,%eax,1),%edx
  103281:	8d 04 d5 00 00 00 00 	lea    0x0(,%edx,8),%eax
  103288:	29 d0                	sub    %edx,%eax
  10328a:	01 c8                	add    %ecx,%eax
  10328c:	8b 54 83 10          	mov    0x10(%ebx,%eax,4),%edx
  103290:	b8 b7 2f 10 00       	mov    $0x102fb7,%eax
  103295:	39 c2                	cmp    %eax,%edx
  103297:	73 24                	jae    1032bd <spinlock_check+0x2be>
  103299:	c7 44 24 0c 8c b5 10 	movl   $0x10b58c,0xc(%esp)
  1032a0:	00 
  1032a1:	c7 44 24 08 c3 b4 10 	movl   $0x10b4c3,0x8(%esp)
  1032a8:	00 
  1032a9:	c7 44 24 04 69 00 00 	movl   $0x69,0x4(%esp)
  1032b0:	00 
  1032b1:	c7 04 24 9d b4 10 00 	movl   $0x10b49d,(%esp)
  1032b8:	e8 df d4 ff ff       	call   10079c <debug_panic>
					(uint32_t)spinlock_godeep);
				assert(locks[i].eips[j] <
  1032bd:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  1032c0:	8b 4d f0             	mov    0xfffffff0(%ebp),%ecx
  1032c3:	8b 5d e0             	mov    0xffffffe0(%ebp),%ebx
  1032c6:	8d 14 00             	lea    (%eax,%eax,1),%edx
  1032c9:	8d 04 d5 00 00 00 00 	lea    0x0(,%edx,8),%eax
  1032d0:	29 d0                	sub    %edx,%eax
  1032d2:	01 c8                	add    %ecx,%eax
  1032d4:	8b 54 83 10          	mov    0x10(%ebx,%eax,4),%edx
  1032d8:	b8 b7 2f 10 00       	mov    $0x102fb7,%eax
  1032dd:	83 c0 64             	add    $0x64,%eax
  1032e0:	39 c2                	cmp    %eax,%edx
  1032e2:	72 24                	jb     103308 <spinlock_check+0x309>
  1032e4:	c7 44 24 0c bc b5 10 	movl   $0x10b5bc,0xc(%esp)
  1032eb:	00 
  1032ec:	c7 44 24 08 c3 b4 10 	movl   $0x10b4c3,0x8(%esp)
  1032f3:	00 
  1032f4:	c7 44 24 04 6b 00 00 	movl   $0x6b,0x4(%esp)
  1032fb:	00 
  1032fc:	c7 04 24 9d b4 10 00 	movl   $0x10b49d,(%esp)
  103303:	e8 94 d4 ff ff       	call   10079c <debug_panic>
  103308:	83 45 f0 01          	addl   $0x1,0xfffffff0(%ebp)
  10330c:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  10330f:	3b 45 ec             	cmp    0xffffffec(%ebp),%eax
  103312:	7f 0a                	jg     10331e <spinlock_check+0x31f>
  103314:	83 7d f0 09          	cmpl   $0x9,0xfffffff0(%ebp)
  103318:	0f 8e 57 ff ff ff    	jle    103275 <spinlock_check+0x276>
  10331e:	83 45 ec 01          	addl   $0x1,0xffffffec(%ebp)
  103322:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  103325:	3b 45 e4             	cmp    0xffffffe4(%ebp),%eax
  103328:	0f 8c 3b ff ff ff    	jl     103269 <spinlock_check+0x26a>
					(uint32_t)spinlock_godeep+100);
			}
		}

		// Release all locks
		for(i=0;i<NUMLOCKS;i++) spinlock_release(&locks[i]);
  10332e:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  103335:	eb 25                	jmp    10335c <spinlock_check+0x35d>
  103337:	8b 4d e0             	mov    0xffffffe0(%ebp),%ecx
  10333a:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  10333d:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  103344:	8d 04 d5 00 00 00 00 	lea    0x0(,%edx,8),%eax
  10334b:	29 d0                	sub    %edx,%eax
  10334d:	8d 04 01             	lea    (%ecx,%eax,1),%eax
  103350:	89 04 24             	mov    %eax,(%esp)
  103353:	e8 cd fb ff ff       	call   102f25 <spinlock_release>
  103358:	83 45 ec 01          	addl   $0x1,0xffffffec(%ebp)
  10335c:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  10335f:	3b 45 e4             	cmp    0xffffffe4(%ebp),%eax
  103362:	7c d3                	jl     103337 <spinlock_check+0x338>
		// Make sure that the CPU has been cleared
		for(i=0;i<NUMLOCKS;i++) assert(locks[i].cpu == NULL);
  103364:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  10336b:	eb 49                	jmp    1033b6 <spinlock_check+0x3b7>
  10336d:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  103370:	8b 4d e0             	mov    0xffffffe0(%ebp),%ecx
  103373:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  10337a:	8d 04 d5 00 00 00 00 	lea    0x0(,%edx,8),%eax
  103381:	29 d0                	sub    %edx,%eax
  103383:	01 c8                	add    %ecx,%eax
  103385:	83 c0 0c             	add    $0xc,%eax
  103388:	8b 00                	mov    (%eax),%eax
  10338a:	85 c0                	test   %eax,%eax
  10338c:	74 24                	je     1033b2 <spinlock_check+0x3b3>
  10338e:	c7 44 24 0c ed b5 10 	movl   $0x10b5ed,0xc(%esp)
  103395:	00 
  103396:	c7 44 24 08 c3 b4 10 	movl   $0x10b4c3,0x8(%esp)
  10339d:	00 
  10339e:	c7 44 24 04 72 00 00 	movl   $0x72,0x4(%esp)
  1033a5:	00 
  1033a6:	c7 04 24 9d b4 10 00 	movl   $0x10b49d,(%esp)
  1033ad:	e8 ea d3 ff ff       	call   10079c <debug_panic>
  1033b2:	83 45 ec 01          	addl   $0x1,0xffffffec(%ebp)
  1033b6:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  1033b9:	3b 45 e4             	cmp    0xffffffe4(%ebp),%eax
  1033bc:	7c af                	jl     10336d <spinlock_check+0x36e>
		for(i=0;i<NUMLOCKS;i++) assert(locks[i].eips[0]==0);
  1033be:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  1033c5:	eb 49                	jmp    103410 <spinlock_check+0x411>
  1033c7:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  1033ca:	8b 4d e0             	mov    0xffffffe0(%ebp),%ecx
  1033cd:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  1033d4:	8d 04 d5 00 00 00 00 	lea    0x0(,%edx,8),%eax
  1033db:	29 d0                	sub    %edx,%eax
  1033dd:	01 c8                	add    %ecx,%eax
  1033df:	83 c0 10             	add    $0x10,%eax
  1033e2:	8b 00                	mov    (%eax),%eax
  1033e4:	85 c0                	test   %eax,%eax
  1033e6:	74 24                	je     10340c <spinlock_check+0x40d>
  1033e8:	c7 44 24 0c 02 b6 10 	movl   $0x10b602,0xc(%esp)
  1033ef:	00 
  1033f0:	c7 44 24 08 c3 b4 10 	movl   $0x10b4c3,0x8(%esp)
  1033f7:	00 
  1033f8:	c7 44 24 04 73 00 00 	movl   $0x73,0x4(%esp)
  1033ff:	00 
  103400:	c7 04 24 9d b4 10 00 	movl   $0x10b49d,(%esp)
  103407:	e8 90 d3 ff ff       	call   10079c <debug_panic>
  10340c:	83 45 ec 01          	addl   $0x1,0xffffffec(%ebp)
  103410:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  103413:	3b 45 e4             	cmp    0xffffffe4(%ebp),%eax
  103416:	7c af                	jl     1033c7 <spinlock_check+0x3c8>
		// Make sure that all locks have holding correctly implemented.
		for(i=0;i<NUMLOCKS;i++) assert(spinlock_holding(&locks[i]) == 0);
  103418:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  10341f:	eb 4d                	jmp    10346e <spinlock_check+0x46f>
  103421:	8b 4d e0             	mov    0xffffffe0(%ebp),%ecx
  103424:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  103427:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  10342e:	8d 04 d5 00 00 00 00 	lea    0x0(,%edx,8),%eax
  103435:	29 d0                	sub    %edx,%eax
  103437:	8d 04 01             	lea    (%ecx,%eax,1),%eax
  10343a:	89 04 24             	mov    %eax,(%esp)
  10343d:	e8 3d fb ff ff       	call   102f7f <spinlock_holding>
  103442:	85 c0                	test   %eax,%eax
  103444:	74 24                	je     10346a <spinlock_check+0x46b>
  103446:	c7 44 24 0c 18 b6 10 	movl   $0x10b618,0xc(%esp)
  10344d:	00 
  10344e:	c7 44 24 08 c3 b4 10 	movl   $0x10b4c3,0x8(%esp)
  103455:	00 
  103456:	c7 44 24 04 75 00 00 	movl   $0x75,0x4(%esp)
  10345d:	00 
  10345e:	c7 04 24 9d b4 10 00 	movl   $0x10b49d,(%esp)
  103465:	e8 32 d3 ff ff       	call   10079c <debug_panic>
  10346a:	83 45 ec 01          	addl   $0x1,0xffffffec(%ebp)
  10346e:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  103471:	3b 45 e4             	cmp    0xffffffe4(%ebp),%eax
  103474:	7c ab                	jl     103421 <spinlock_check+0x422>
  103476:	83 45 f4 01          	addl   $0x1,0xfffffff4(%ebp)
  10347a:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  10347d:	3b 45 e8             	cmp    0xffffffe8(%ebp),%eax
  103480:	0f 8c dd fc ff ff    	jl     103163 <spinlock_check+0x164>
	}
	cprintf("spinlock_check() succeeded!\n");
  103486:	c7 04 24 39 b6 10 00 	movl   $0x10b639,(%esp)
  10348d:	e8 17 6e 00 00       	call   10a2a9 <cprintf>
  103492:	8b 65 d8             	mov    0xffffffd8(%ebp),%esp
}
  103495:	8b 5d fc             	mov    0xfffffffc(%ebp),%ebx
  103498:	c9                   	leave  
  103499:	c3                   	ret    
  10349a:	90                   	nop    
  10349b:	90                   	nop    

0010349c <proc_init>:
static proc **readytail;

void
proc_init(void)
{
  10349c:	55                   	push   %ebp
  10349d:	89 e5                	mov    %esp,%ebp
  10349f:	83 ec 18             	sub    $0x18,%esp
	if (!cpu_onboot())
  1034a2:	e8 2c 00 00 00       	call   1034d3 <cpu_onboot>
  1034a7:	85 c0                	test   %eax,%eax
  1034a9:	74 26                	je     1034d1 <proc_init+0x35>
		return;

	// your module initialization code here
  spinlock_init(&readylock);
  1034ab:	c7 44 24 08 25 00 00 	movl   $0x25,0x8(%esp)
  1034b2:	00 
  1034b3:	c7 44 24 04 58 b6 10 	movl   $0x10b658,0x4(%esp)
  1034ba:	00 
  1034bb:	c7 04 24 40 ba 11 00 	movl   $0x11ba40,(%esp)
  1034c2:	e8 39 f9 ff ff       	call   102e00 <spinlock_init_>
  readytail = &readyhead;
  1034c7:	c7 05 7c ba 11 00 78 	movl   $0x11ba78,0x11ba7c
  1034ce:	ba 11 00 
}
  1034d1:	c9                   	leave  
  1034d2:	c3                   	ret    

001034d3 <cpu_onboot>:
}

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  1034d3:	55                   	push   %ebp
  1034d4:	89 e5                	mov    %esp,%ebp
  1034d6:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  1034d9:	e8 0d 00 00 00       	call   1034eb <cpu_cur>
  1034de:	3d 00 d0 10 00       	cmp    $0x10d000,%eax
  1034e3:	0f 94 c0             	sete   %al
  1034e6:	0f b6 c0             	movzbl %al,%eax
}
  1034e9:	c9                   	leave  
  1034ea:	c3                   	ret    

001034eb <cpu_cur>:
  1034eb:	55                   	push   %ebp
  1034ec:	89 e5                	mov    %esp,%ebp
  1034ee:	83 ec 28             	sub    $0x28,%esp
static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  1034f1:	89 65 fc             	mov    %esp,0xfffffffc(%ebp)
        return esp;
  1034f4:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  1034f7:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  1034fa:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1034fd:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  103502:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	assert(c->magic == CPU_MAGIC);
  103505:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  103508:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  10350e:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  103513:	74 24                	je     103539 <cpu_cur+0x4e>
  103515:	c7 44 24 0c 64 b6 10 	movl   $0x10b664,0xc(%esp)
  10351c:	00 
  10351d:	c7 44 24 08 7a b6 10 	movl   $0x10b67a,0x8(%esp)
  103524:	00 
  103525:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  10352c:	00 
  10352d:	c7 04 24 8f b6 10 00 	movl   $0x10b68f,(%esp)
  103534:	e8 63 d2 ff ff       	call   10079c <debug_panic>
	return c;
  103539:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
}
  10353c:	c9                   	leave  
  10353d:	c3                   	ret    

0010353e <proc_alloc>:

// Allocate and initialize a new proc as child 'cn' of parent 'p'.
// Returns NULL if no physical memory available.
proc *
proc_alloc(proc *p, uint32_t cn)
{
  10353e:	55                   	push   %ebp
  10353f:	89 e5                	mov    %esp,%ebp
  103541:	83 ec 28             	sub    $0x28,%esp
	pageinfo *pi = mem_alloc();
  103544:	e8 36 d9 ff ff       	call   100e7f <mem_alloc>
  103549:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	if (!pi)
  10354c:	83 7d f4 00          	cmpl   $0x0,0xfffffff4(%ebp)
  103550:	75 0c                	jne    10355e <proc_alloc+0x20>
		return NULL;
  103552:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  103559:	e9 14 02 00 00       	jmp    103772 <proc_alloc+0x234>
  10355e:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  103561:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
// Atomically increment the reference count on a page.
static gcc_inline void
mem_incref(pageinfo *pi)
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  103564:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  103569:	83 c0 08             	add    $0x8,%eax
  10356c:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  10356f:	73 17                	jae    103588 <proc_alloc+0x4a>
  103571:	a1 44 fd 11 00       	mov    0x11fd44,%eax
  103576:	c1 e0 03             	shl    $0x3,%eax
  103579:	89 c2                	mov    %eax,%edx
  10357b:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  103580:	8d 04 02             	lea    (%edx,%eax,1),%eax
  103583:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  103586:	77 24                	ja     1035ac <proc_alloc+0x6e>
  103588:	c7 44 24 0c 9c b6 10 	movl   $0x10b69c,0xc(%esp)
  10358f:	00 
  103590:	c7 44 24 08 7a b6 10 	movl   $0x10b67a,0x8(%esp)
  103597:	00 
  103598:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
  10359f:	00 
  1035a0:	c7 04 24 d3 b6 10 00 	movl   $0x10b6d3,(%esp)
  1035a7:	e8 f0 d1 ff ff       	call   10079c <debug_panic>
	assert(pi != mem_ptr2pi(pmap_zero));	// Don't alloc/free zero page!
  1035ac:	8b 15 9c fd 11 00    	mov    0x11fd9c,%edx
  1035b2:	b8 00 20 12 00       	mov    $0x122000,%eax
  1035b7:	c1 e8 0c             	shr    $0xc,%eax
  1035ba:	c1 e0 03             	shl    $0x3,%eax
  1035bd:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1035c0:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  1035c3:	75 24                	jne    1035e9 <proc_alloc+0xab>
  1035c5:	c7 44 24 0c e0 b6 10 	movl   $0x10b6e0,0xc(%esp)
  1035cc:	00 
  1035cd:	c7 44 24 08 7a b6 10 	movl   $0x10b67a,0x8(%esp)
  1035d4:	00 
  1035d5:	c7 44 24 04 59 00 00 	movl   $0x59,0x4(%esp)
  1035dc:	00 
  1035dd:	c7 04 24 d3 b6 10 00 	movl   $0x10b6d3,(%esp)
  1035e4:	e8 b3 d1 ff ff       	call   10079c <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  1035e9:	8b 15 9c fd 11 00    	mov    0x11fd9c,%edx
  1035ef:	b8 0c 00 10 00       	mov    $0x10000c,%eax
  1035f4:	c1 e8 0c             	shr    $0xc,%eax
  1035f7:	c1 e0 03             	shl    $0x3,%eax
  1035fa:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1035fd:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  103600:	77 40                	ja     103642 <proc_alloc+0x104>
  103602:	8b 15 9c fd 11 00    	mov    0x11fd9c,%edx
  103608:	b8 08 30 12 00       	mov    $0x123008,%eax
  10360d:	83 e8 01             	sub    $0x1,%eax
  103610:	c1 e8 0c             	shr    $0xc,%eax
  103613:	c1 e0 03             	shl    $0x3,%eax
  103616:	8d 04 02             	lea    (%edx,%eax,1),%eax
  103619:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  10361c:	72 24                	jb     103642 <proc_alloc+0x104>
  10361e:	c7 44 24 0c fc b6 10 	movl   $0x10b6fc,0xc(%esp)
  103625:	00 
  103626:	c7 44 24 08 7a b6 10 	movl   $0x10b67a,0x8(%esp)
  10362d:	00 
  10362e:	c7 44 24 04 5a 00 00 	movl   $0x5a,0x4(%esp)
  103635:	00 
  103636:	c7 04 24 d3 b6 10 00 	movl   $0x10b6d3,(%esp)
  10363d:	e8 5a d1 ff ff       	call   10079c <debug_panic>

	lockadd(&pi->refcount, 1);
  103642:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  103645:	83 c0 04             	add    $0x4,%eax
  103648:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  10364f:	00 
  103650:	89 04 24             	mov    %eax,(%esp)
  103653:	e8 1f 01 00 00       	call   103777 <lockadd>
	mem_incref(pi);

	proc *cp = (proc*)mem_pi2ptr(pi);
  103658:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  10365b:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  103660:	89 d1                	mov    %edx,%ecx
  103662:	29 c1                	sub    %eax,%ecx
  103664:	89 c8                	mov    %ecx,%eax
  103666:	c1 e0 09             	shl    $0x9,%eax
  103669:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
	memset(cp, 0, sizeof(proc));
  10366c:	c7 44 24 08 b0 06 00 	movl   $0x6b0,0x8(%esp)
  103673:	00 
  103674:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  10367b:	00 
  10367c:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10367f:	89 04 24             	mov    %eax,(%esp)
  103682:	e8 1a 6e 00 00       	call   10a4a1 <memset>
	spinlock_init(&cp->lock);
  103687:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10368a:	c7 44 24 08 35 00 00 	movl   $0x35,0x8(%esp)
  103691:	00 
  103692:	c7 44 24 04 58 b6 10 	movl   $0x10b658,0x4(%esp)
  103699:	00 
  10369a:	89 04 24             	mov    %eax,(%esp)
  10369d:	e8 5e f7 ff ff       	call   102e00 <spinlock_init_>
	cp->parent = p;
  1036a2:	8b 55 f8             	mov    0xfffffff8(%ebp),%edx
  1036a5:	8b 45 08             	mov    0x8(%ebp),%eax
  1036a8:	89 42 38             	mov    %eax,0x38(%edx)
	cp->state = PROC_STOP;
  1036ab:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1036ae:	c7 80 3c 04 00 00 00 	movl   $0x0,0x43c(%eax)
  1036b5:	00 00 00 

	// Integer register state
	cp->sv.tf.ds = CPU_GDT_UDATA | 3;
  1036b8:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1036bb:	66 c7 80 7c 04 00 00 	movw   $0x23,0x47c(%eax)
  1036c2:	23 00 
	cp->sv.tf.es = CPU_GDT_UDATA | 3;
  1036c4:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1036c7:	66 c7 80 78 04 00 00 	movw   $0x23,0x478(%eax)
  1036ce:	23 00 
	cp->sv.tf.cs = CPU_GDT_UCODE | 3;
  1036d0:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1036d3:	66 c7 80 8c 04 00 00 	movw   $0x1b,0x48c(%eax)
  1036da:	1b 00 
	cp->sv.tf.ss = CPU_GDT_UDATA | 3;
  1036dc:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1036df:	66 c7 80 98 04 00 00 	movw   $0x23,0x498(%eax)
  1036e6:	23 00 

cp->pdir = pmap_newpdir();
  1036e8:	e8 05 19 00 00       	call   104ff2 <pmap_newpdir>
  1036ed:	89 c2                	mov    %eax,%edx
  1036ef:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1036f2:	89 90 a0 06 00 00    	mov    %edx,0x6a0(%eax)
cp->rpdir = pmap_newpdir();
  1036f8:	e8 f5 18 00 00       	call   104ff2 <pmap_newpdir>
  1036fd:	89 c2                	mov    %eax,%edx
  1036ff:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  103702:	89 90 a4 06 00 00    	mov    %edx,0x6a4(%eax)
if (!cp->pdir || !cp->rpdir){
  103708:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10370b:	8b 80 a0 06 00 00    	mov    0x6a0(%eax),%eax
  103711:	85 c0                	test   %eax,%eax
  103713:	74 0d                	je     103722 <proc_alloc+0x1e4>
  103715:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  103718:	8b 80 a4 06 00 00    	mov    0x6a4(%eax),%eax
  10371e:	85 c0                	test   %eax,%eax
  103720:	75 37                	jne    103759 <proc_alloc+0x21b>
if(cp->pdir) pmap_freepdir(mem_ptr2pi(cp->pdir));
  103722:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  103725:	8b 80 a0 06 00 00    	mov    0x6a0(%eax),%eax
  10372b:	85 c0                	test   %eax,%eax
  10372d:	74 21                	je     103750 <proc_alloc+0x212>
  10372f:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  103732:	8b 80 a0 06 00 00    	mov    0x6a0(%eax),%eax
  103738:	c1 e8 0c             	shr    $0xc,%eax
  10373b:	c1 e0 03             	shl    $0x3,%eax
  10373e:	89 c2                	mov    %eax,%edx
  103740:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  103745:	8d 04 02             	lea    (%edx,%eax,1),%eax
  103748:	89 04 24             	mov    %eax,(%esp)
  10374b:	e8 07 1a 00 00       	call   105157 <pmap_freepdir>
return NULL;
  103750:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  103757:	eb 19                	jmp    103772 <proc_alloc+0x234>
}
	if (p)
  103759:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  10375d:	74 0d                	je     10376c <proc_alloc+0x22e>
		p->child[cn] = cp;
  10375f:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  103762:	8b 55 08             	mov    0x8(%ebp),%edx
  103765:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  103768:	89 44 8a 3c          	mov    %eax,0x3c(%edx,%ecx,4)
	return cp;
  10376c:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10376f:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  103772:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
}
  103775:	c9                   	leave  
  103776:	c3                   	ret    

00103777 <lockadd>:

// Atomically add incr to *addr.
static inline void
lockadd(volatile int32_t *addr, int32_t incr)
{
  103777:	55                   	push   %ebp
  103778:	89 e5                	mov    %esp,%ebp
	asm volatile("lock; addl %1,%0" : "+m" (*addr) : "r" (incr) : "cc");
  10377a:	8b 4d 08             	mov    0x8(%ebp),%ecx
  10377d:	8b 55 0c             	mov    0xc(%ebp),%edx
  103780:	8b 45 08             	mov    0x8(%ebp),%eax
  103783:	f0 01 11             	lock add %edx,(%ecx)
}
  103786:	5d                   	pop    %ebp
  103787:	c3                   	ret    

00103788 <proc_ready>:

// Put process p in the ready state and add it to the ready queue.
void
proc_ready(proc *p)
{
  103788:	55                   	push   %ebp
  103789:	89 e5                	mov    %esp,%ebp
  10378b:	83 ec 08             	sub    $0x8,%esp
//	panic("proc_ready not implemented");
  spinlock_acquire(&readylock);
  10378e:	c7 04 24 40 ba 11 00 	movl   $0x11ba40,(%esp)
  103795:	e8 90 f6 ff ff       	call   102e2a <spinlock_acquire>

  p->state = PROC_READY;
  10379a:	8b 45 08             	mov    0x8(%ebp),%eax
  10379d:	c7 80 3c 04 00 00 01 	movl   $0x1,0x43c(%eax)
  1037a4:	00 00 00 
  p->readynext = NULL;
  1037a7:	8b 45 08             	mov    0x8(%ebp),%eax
  1037aa:	c7 80 40 04 00 00 00 	movl   $0x0,0x440(%eax)
  1037b1:	00 00 00 
  *readytail = p;
  1037b4:	8b 15 7c ba 11 00    	mov    0x11ba7c,%edx
  1037ba:	8b 45 08             	mov    0x8(%ebp),%eax
  1037bd:	89 02                	mov    %eax,(%edx)
  readytail = &p->readynext;
  1037bf:	8b 45 08             	mov    0x8(%ebp),%eax
  1037c2:	05 40 04 00 00       	add    $0x440,%eax
  1037c7:	a3 7c ba 11 00       	mov    %eax,0x11ba7c

  spinlock_release(&readylock);
  1037cc:	c7 04 24 40 ba 11 00 	movl   $0x11ba40,(%esp)
  1037d3:	e8 4d f7 ff ff       	call   102f25 <spinlock_release>
}
  1037d8:	c9                   	leave  
  1037d9:	c3                   	ret    

001037da <proc_save>:

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
  1037da:	55                   	push   %ebp
  1037db:	89 e5                	mov    %esp,%ebp
  1037dd:	83 ec 18             	sub    $0x18,%esp
    assert(p == proc_cur());
  1037e0:	e8 06 fd ff ff       	call   1034eb <cpu_cur>
  1037e5:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  1037eb:	3b 45 08             	cmp    0x8(%ebp),%eax
  1037ee:	74 24                	je     103814 <proc_save+0x3a>
  1037f0:	c7 44 24 0c 2d b7 10 	movl   $0x10b72d,0xc(%esp)
  1037f7:	00 
  1037f8:	c7 44 24 08 7a b6 10 	movl   $0x10b67a,0x8(%esp)
  1037ff:	00 
  103800:	c7 44 24 04 63 00 00 	movl   $0x63,0x4(%esp)
  103807:	00 
  103808:	c7 04 24 58 b6 10 00 	movl   $0x10b658,(%esp)
  10380f:	e8 88 cf ff ff       	call   10079c <debug_panic>

    if (tf != &p->sv.tf)
  103814:	8b 45 08             	mov    0x8(%ebp),%eax
  103817:	05 50 04 00 00       	add    $0x450,%eax
  10381c:	3b 45 0c             	cmp    0xc(%ebp),%eax
  10381f:	74 21                	je     103842 <proc_save+0x68>
      p->sv.tf = *tf; // integer register state
  103821:	8b 45 08             	mov    0x8(%ebp),%eax
  103824:	8b 55 0c             	mov    0xc(%ebp),%edx
  103827:	8d 88 50 04 00 00    	lea    0x450(%eax),%ecx
  10382d:	b8 4c 00 00 00       	mov    $0x4c,%eax
  103832:	89 44 24 08          	mov    %eax,0x8(%esp)
  103836:	89 54 24 04          	mov    %edx,0x4(%esp)
  10383a:	89 0c 24             	mov    %ecx,(%esp)
  10383d:	e8 9e 6d 00 00       	call   10a5e0 <memcpy>
    if (entry == 0)
  103842:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  103846:	75 15                	jne    10385d <proc_save+0x83>
      p->sv.tf.eip -= 2;  // back up to replay INT instruction
  103848:	8b 45 08             	mov    0x8(%ebp),%eax
  10384b:	8b 80 88 04 00 00    	mov    0x488(%eax),%eax
  103851:	8d 50 fe             	lea    0xfffffffe(%eax),%edx
  103854:	8b 45 08             	mov    0x8(%ebp),%eax
  103857:	89 90 88 04 00 00    	mov    %edx,0x488(%eax)
}
  10385d:	c9                   	leave  
  10385e:	c3                   	ret    

0010385f <proc_wait>:

// Go to sleep waiting for a given child process to finish running.
// Parent process 'p' must be running and locked on entry.
// The supplied trapframe represents p's register state on syscall entry.
void gcc_noreturn
proc_wait(proc *p, proc *cp, trapframe *tf)
{
  10385f:	55                   	push   %ebp
  103860:	89 e5                	mov    %esp,%ebp
  103862:	83 ec 18             	sub    $0x18,%esp
	//panic("proc_wait not implemented");
  assert(spinlock_holding(&p->lock));
  103865:	8b 45 08             	mov    0x8(%ebp),%eax
  103868:	89 04 24             	mov    %eax,(%esp)
  10386b:	e8 0f f7 ff ff       	call   102f7f <spinlock_holding>
  103870:	85 c0                	test   %eax,%eax
  103872:	75 24                	jne    103898 <proc_wait+0x39>
  103874:	c7 44 24 0c 3d b7 10 	movl   $0x10b73d,0xc(%esp)
  10387b:	00 
  10387c:	c7 44 24 08 7a b6 10 	movl   $0x10b67a,0x8(%esp)
  103883:	00 
  103884:	c7 44 24 04 72 00 00 	movl   $0x72,0x4(%esp)
  10388b:	00 
  10388c:	c7 04 24 58 b6 10 00 	movl   $0x10b658,(%esp)
  103893:	e8 04 cf ff ff       	call   10079c <debug_panic>
  assert(cp && cp != &proc_null); // null proc is always stopped
  103898:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  10389c:	74 09                	je     1038a7 <proc_wait+0x48>
  10389e:	81 7d 0c c0 fd 11 00 	cmpl   $0x11fdc0,0xc(%ebp)
  1038a5:	75 24                	jne    1038cb <proc_wait+0x6c>
  1038a7:	c7 44 24 0c 58 b7 10 	movl   $0x10b758,0xc(%esp)
  1038ae:	00 
  1038af:	c7 44 24 08 7a b6 10 	movl   $0x10b67a,0x8(%esp)
  1038b6:	00 
  1038b7:	c7 44 24 04 73 00 00 	movl   $0x73,0x4(%esp)
  1038be:	00 
  1038bf:	c7 04 24 58 b6 10 00 	movl   $0x10b658,(%esp)
  1038c6:	e8 d1 ce ff ff       	call   10079c <debug_panic>
  assert(cp->state != PROC_STOP);
  1038cb:	8b 45 0c             	mov    0xc(%ebp),%eax
  1038ce:	8b 80 3c 04 00 00    	mov    0x43c(%eax),%eax
  1038d4:	85 c0                	test   %eax,%eax
  1038d6:	75 24                	jne    1038fc <proc_wait+0x9d>
  1038d8:	c7 44 24 0c 6f b7 10 	movl   $0x10b76f,0xc(%esp)
  1038df:	00 
  1038e0:	c7 44 24 08 7a b6 10 	movl   $0x10b67a,0x8(%esp)
  1038e7:	00 
  1038e8:	c7 44 24 04 74 00 00 	movl   $0x74,0x4(%esp)
  1038ef:	00 
  1038f0:	c7 04 24 58 b6 10 00 	movl   $0x10b658,(%esp)
  1038f7:	e8 a0 ce ff ff       	call   10079c <debug_panic>

  p->state = PROC_WAIT;
  1038fc:	8b 45 08             	mov    0x8(%ebp),%eax
  1038ff:	c7 80 3c 04 00 00 03 	movl   $0x3,0x43c(%eax)
  103906:	00 00 00 
  p->runcpu = NULL;
  103909:	8b 45 08             	mov    0x8(%ebp),%eax
  10390c:	c7 80 44 04 00 00 00 	movl   $0x0,0x444(%eax)
  103913:	00 00 00 
  p->waitchild = cp;  // remember what child we're waiting on
  103916:	8b 55 08             	mov    0x8(%ebp),%edx
  103919:	8b 45 0c             	mov    0xc(%ebp),%eax
  10391c:	89 82 48 04 00 00    	mov    %eax,0x448(%edx)
  proc_save(p, tf, 0);  // save process state before INT instruction
  103922:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  103929:	00 
  10392a:	8b 45 10             	mov    0x10(%ebp),%eax
  10392d:	89 44 24 04          	mov    %eax,0x4(%esp)
  103931:	8b 45 08             	mov    0x8(%ebp),%eax
  103934:	89 04 24             	mov    %eax,(%esp)
  103937:	e8 9e fe ff ff       	call   1037da <proc_save>

  spinlock_release(&p->lock);
  10393c:	8b 45 08             	mov    0x8(%ebp),%eax
  10393f:	89 04 24             	mov    %eax,(%esp)
  103942:	e8 de f5 ff ff       	call   102f25 <spinlock_release>

  proc_sched();
  103947:	e8 00 00 00 00       	call   10394c <proc_sched>

0010394c <proc_sched>:
}

void gcc_noreturn
proc_sched(void)
{
  10394c:	55                   	push   %ebp
  10394d:	89 e5                	mov    %esp,%ebp
  10394f:	83 ec 28             	sub    $0x28,%esp
//	panic("proc_sched not implemented");
  cpu *c = cpu_cur();
  103952:	e8 94 fb ff ff       	call   1034eb <cpu_cur>
  103957:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  spinlock_acquire(&readylock);
  10395a:	c7 04 24 40 ba 11 00 	movl   $0x11ba40,(%esp)
  103961:	e8 c4 f4 ff ff       	call   102e2a <spinlock_acquire>
  while (!readyhead || cpu_disabled(c)) {
  103966:	eb 2a                	jmp    103992 <proc_sched+0x46>
    spinlock_release(&readylock);
  103968:	c7 04 24 40 ba 11 00 	movl   $0x11ba40,(%esp)
  10396f:	e8 b1 f5 ff ff       	call   102f25 <spinlock_release>

    //cprintf("cpu %d waiting for work\n", cpu_cur()->id);
    while (!readyhead || cpu_disabled(c)) {  // spin-wait for work
  103974:	eb 07                	jmp    10397d <proc_sched+0x31>
// Enable external device interrupts.
static gcc_inline void
sti(void)
{
	asm volatile("sti");
  103976:	fb                   	sti    
      sti(); // enable device interrupts briefly
      pause(); // let CPU know we're in a spin loop
  103977:	e8 ad 00 00 00       	call   103a29 <pause>
// Disable external device interrupts.
static gcc_inline void
cli(void)
{
	asm volatile("cli");
  10397c:	fa                   	cli    
  10397d:	a1 78 ba 11 00       	mov    0x11ba78,%eax
  103982:	85 c0                	test   %eax,%eax
  103984:	74 f0                	je     103976 <proc_sched+0x2a>
      cli(); // disable interrupts again
    }
    //cprintf("cpu %d found work\n", cpu_cur()->id);

    spinlock_acquire(&readylock);
  103986:	c7 04 24 40 ba 11 00 	movl   $0x11ba40,(%esp)
  10398d:	e8 98 f4 ff ff       	call   102e2a <spinlock_acquire>
  103992:	a1 78 ba 11 00       	mov    0x11ba78,%eax
  103997:	85 c0                	test   %eax,%eax
  103999:	74 cd                	je     103968 <proc_sched+0x1c>
    // now must recheck readyhead while holding readylock!
  }

  // Remove the next proc from the ready queue
  proc *p = readyhead;
  10399b:	a1 78 ba 11 00       	mov    0x11ba78,%eax
  1039a0:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  readyhead = p->readynext;
  1039a3:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  1039a6:	8b 80 40 04 00 00    	mov    0x440(%eax),%eax
  1039ac:	a3 78 ba 11 00       	mov    %eax,0x11ba78
  if (readytail == &p->readynext) {
  1039b1:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  1039b4:	81 c2 40 04 00 00    	add    $0x440,%edx
  1039ba:	a1 7c ba 11 00       	mov    0x11ba7c,%eax
  1039bf:	39 c2                	cmp    %eax,%edx
  1039c1:	75 37                	jne    1039fa <proc_sched+0xae>
    assert(readyhead == NULL); // ready queue going empty
  1039c3:	a1 78 ba 11 00       	mov    0x11ba78,%eax
  1039c8:	85 c0                	test   %eax,%eax
  1039ca:	74 24                	je     1039f0 <proc_sched+0xa4>
  1039cc:	c7 44 24 0c 86 b7 10 	movl   $0x10b786,0xc(%esp)
  1039d3:	00 
  1039d4:	c7 44 24 08 7a b6 10 	movl   $0x10b67a,0x8(%esp)
  1039db:	00 
  1039dc:	c7 44 24 04 99 00 00 	movl   $0x99,0x4(%esp)
  1039e3:	00 
  1039e4:	c7 04 24 58 b6 10 00 	movl   $0x10b658,(%esp)
  1039eb:	e8 ac cd ff ff       	call   10079c <debug_panic>
    readytail = &readyhead;
  1039f0:	c7 05 7c ba 11 00 78 	movl   $0x11ba78,0x11ba7c
  1039f7:	ba 11 00 
  }
  p->readynext = NULL;
  1039fa:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  1039fd:	c7 80 40 04 00 00 00 	movl   $0x0,0x440(%eax)
  103a04:	00 00 00 

  spinlock_acquire(&p->lock);
  103a07:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  103a0a:	89 04 24             	mov    %eax,(%esp)
  103a0d:	e8 18 f4 ff ff       	call   102e2a <spinlock_acquire>
  spinlock_release(&readylock);
  103a12:	c7 04 24 40 ba 11 00 	movl   $0x11ba40,(%esp)
  103a19:	e8 07 f5 ff ff       	call   102f25 <spinlock_release>

  proc_run(p);
  103a1e:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  103a21:	89 04 24             	mov    %eax,(%esp)
  103a24:	e8 07 00 00 00       	call   103a30 <proc_run>

00103a29 <pause>:
}

static inline void
pause(void)
{
  103a29:	55                   	push   %ebp
  103a2a:	89 e5                	mov    %esp,%ebp
	asm volatile("pause" : : : "memory");
  103a2c:	f3 90                	pause  
}
  103a2e:	5d                   	pop    %ebp
  103a2f:	c3                   	ret    

00103a30 <proc_run>:
}	
// Switch to and run a specified process, which must already be locked.
void gcc_noreturn
proc_run(proc *p)
{
  103a30:	55                   	push   %ebp
  103a31:	89 e5                	mov    %esp,%ebp
  103a33:	83 ec 28             	sub    $0x28,%esp
	//panic("proc_run not implemented");
  assert(spinlock_holding(&p->lock));
  103a36:	8b 45 08             	mov    0x8(%ebp),%eax
  103a39:	89 04 24             	mov    %eax,(%esp)
  103a3c:	e8 3e f5 ff ff       	call   102f7f <spinlock_holding>
  103a41:	85 c0                	test   %eax,%eax
  103a43:	75 24                	jne    103a69 <proc_run+0x39>
  103a45:	c7 44 24 0c 3d b7 10 	movl   $0x10b73d,0xc(%esp)
  103a4c:	00 
  103a4d:	c7 44 24 08 7a b6 10 	movl   $0x10b67a,0x8(%esp)
  103a54:	00 
  103a55:	c7 44 24 04 a8 00 00 	movl   $0xa8,0x4(%esp)
  103a5c:	00 
  103a5d:	c7 04 24 58 b6 10 00 	movl   $0x10b658,(%esp)
  103a64:	e8 33 cd ff ff       	call   10079c <debug_panic>

  cpu *c = cpu_cur();
  103a69:	e8 7d fa ff ff       	call   1034eb <cpu_cur>
  103a6e:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  p->state = PROC_RUN;
  103a71:	8b 45 08             	mov    0x8(%ebp),%eax
  103a74:	c7 80 3c 04 00 00 02 	movl   $0x2,0x43c(%eax)
  103a7b:	00 00 00 
  p->runcpu = c;
  103a7e:	8b 55 08             	mov    0x8(%ebp),%edx
  103a81:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  103a84:	89 82 44 04 00 00    	mov    %eax,0x444(%edx)
  c->proc = p;
  103a8a:	8b 55 f8             	mov    0xfffffff8(%ebp),%edx
  103a8d:	8b 45 08             	mov    0x8(%ebp),%eax
  103a90:	89 82 b4 00 00 00    	mov    %eax,0xb4(%edx)

  spinlock_release(&p->lock);
  103a96:	8b 45 08             	mov    0x8(%ebp),%eax
  103a99:	89 04 24             	mov    %eax,(%esp)
  103a9c:	e8 84 f4 ff ff       	call   102f25 <spinlock_release>

  lcr3(mem_phys(p->pdir));
  103aa1:	8b 45 08             	mov    0x8(%ebp),%eax
  103aa4:	8b 80 a0 06 00 00    	mov    0x6a0(%eax),%eax
  103aaa:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)

static gcc_inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
  103aad:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  103ab0:	0f 22 d8             	mov    %eax,%cr3
  trap_return(&p->sv.tf);
  103ab3:	8b 45 08             	mov    0x8(%ebp),%eax
  103ab6:	05 50 04 00 00       	add    $0x450,%eax
  103abb:	89 04 24             	mov    %eax,(%esp)
  103abe:	e8 0d ef ff ff       	call   1029d0 <trap_return>

00103ac3 <proc_yield>:
}

// Yield the current CPU to another ready process.
// Called while handling a timer interrupt.
void gcc_noreturn
proc_yield(trapframe *tf)
{
  103ac3:	55                   	push   %ebp
  103ac4:	89 e5                	mov    %esp,%ebp
  103ac6:	53                   	push   %ebx
  103ac7:	83 ec 24             	sub    $0x24,%esp
//	panic("proc_yield not implemented");
    proc *p = proc_cur();
  103aca:	e8 1c fa ff ff       	call   1034eb <cpu_cur>
  103acf:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  103ad5:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
    assert(p->runcpu == cpu_cur());
  103ad8:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  103adb:	8b 98 44 04 00 00    	mov    0x444(%eax),%ebx
  103ae1:	e8 05 fa ff ff       	call   1034eb <cpu_cur>
  103ae6:	39 c3                	cmp    %eax,%ebx
  103ae8:	74 24                	je     103b0e <proc_yield+0x4b>
  103aea:	c7 44 24 0c 98 b7 10 	movl   $0x10b798,0xc(%esp)
  103af1:	00 
  103af2:	c7 44 24 08 7a b6 10 	movl   $0x10b67a,0x8(%esp)
  103af9:	00 
  103afa:	c7 44 24 04 bc 00 00 	movl   $0xbc,0x4(%esp)
  103b01:	00 
  103b02:	c7 04 24 58 b6 10 00 	movl   $0x10b658,(%esp)
  103b09:	e8 8e cc ff ff       	call   10079c <debug_panic>
    p->runcpu = NULL; // this process no longer running
  103b0e:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  103b11:	c7 80 44 04 00 00 00 	movl   $0x0,0x444(%eax)
  103b18:	00 00 00 
    proc_save(p, tf, -1); // save this process's state
  103b1b:	c7 44 24 08 ff ff ff 	movl   $0xffffffff,0x8(%esp)
  103b22:	ff 
  103b23:	8b 45 08             	mov    0x8(%ebp),%eax
  103b26:	89 44 24 04          	mov    %eax,0x4(%esp)
  103b2a:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  103b2d:	89 04 24             	mov    %eax,(%esp)
  103b30:	e8 a5 fc ff ff       	call   1037da <proc_save>
    proc_ready(p);  // put it on tail of ready queue
  103b35:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  103b38:	89 04 24             	mov    %eax,(%esp)
  103b3b:	e8 48 fc ff ff       	call   103788 <proc_ready>

    proc_sched(); // schedule a process from head of ready queue
  103b40:	e8 07 fe ff ff       	call   10394c <proc_sched>

00103b45 <proc_ret>:
}

// Put the current process to sleep by "returning" to its parent process.
// Used both when a process calls the SYS_RET system call explicitly,
// and when a process causes an unhandled trap in user mode.
// The 'entry' parameter is as in proc_save().
void gcc_noreturn
proc_ret(trapframe *tf, int entry)
{
  103b45:	55                   	push   %ebp
  103b46:	89 e5                	mov    %esp,%ebp
  103b48:	53                   	push   %ebx
  103b49:	83 ec 24             	sub    $0x24,%esp
	//panic("proc_ret not implemented");

  proc *cp = proc_cur();  // we're the child
  103b4c:	e8 9a f9 ff ff       	call   1034eb <cpu_cur>
  103b51:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  103b57:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
  assert(cp->state == PROC_RUN && cp->runcpu == cpu_cur());
  103b5a:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  103b5d:	8b 80 3c 04 00 00    	mov    0x43c(%eax),%eax
  103b63:	83 f8 02             	cmp    $0x2,%eax
  103b66:	75 12                	jne    103b7a <proc_ret+0x35>
  103b68:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  103b6b:	8b 98 44 04 00 00    	mov    0x444(%eax),%ebx
  103b71:	e8 75 f9 ff ff       	call   1034eb <cpu_cur>
  103b76:	39 c3                	cmp    %eax,%ebx
  103b78:	74 24                	je     103b9e <proc_ret+0x59>
  103b7a:	c7 44 24 0c b0 b7 10 	movl   $0x10b7b0,0xc(%esp)
  103b81:	00 
  103b82:	c7 44 24 08 7a b6 10 	movl   $0x10b67a,0x8(%esp)
  103b89:	00 
  103b8a:	c7 44 24 04 ce 00 00 	movl   $0xce,0x4(%esp)
  103b91:	00 
  103b92:	c7 04 24 58 b6 10 00 	movl   $0x10b658,(%esp)
  103b99:	e8 fe cb ff ff       	call   10079c <debug_panic>

  proc *p = cp->parent;  // find our parent
  103b9e:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  103ba1:	8b 40 38             	mov    0x38(%eax),%eax
  103ba4:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  if (p == NULL) { // "return" from root process!
  103ba7:	83 7d f8 00          	cmpl   $0x0,0xfffffff8(%ebp)
  103bab:	75 43                	jne    103bf0 <proc_ret+0xab>
    if (tf->trapno != T_SYSCALL) {
  103bad:	8b 45 08             	mov    0x8(%ebp),%eax
  103bb0:	8b 40 30             	mov    0x30(%eax),%eax
  103bb3:	83 f8 30             	cmp    $0x30,%eax
  103bb6:	74 27                	je     103bdf <proc_ret+0x9a>
      trap_print(tf);
  103bb8:	8b 45 08             	mov    0x8(%ebp),%eax
  103bbb:	89 04 24             	mov    %eax,(%esp)
  103bbe:	e8 f6 e6 ff ff       	call   1022b9 <trap_print>
      panic("trap in root process");
  103bc3:	c7 44 24 08 e1 b7 10 	movl   $0x10b7e1,0x8(%esp)
  103bca:	00 
  103bcb:	c7 44 24 04 d4 00 00 	movl   $0xd4,0x4(%esp)
  103bd2:	00 
  103bd3:	c7 04 24 58 b6 10 00 	movl   $0x10b658,(%esp)
  103bda:	e8 bd cb ff ff       	call   10079c <debug_panic>
    }
    cprintf("root process terminated\n");
  103bdf:	c7 04 24 f6 b7 10 00 	movl   $0x10b7f6,(%esp)
  103be6:	e8 be 66 00 00       	call   10a2a9 <cprintf>
    done();
  103beb:	e8 6f c9 ff ff       	call   10055f <done>
  }

  spinlock_acquire(&p->lock);  // lock both in proper order
  103bf0:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  103bf3:	89 04 24             	mov    %eax,(%esp)
  103bf6:	e8 2f f2 ff ff       	call   102e2a <spinlock_acquire>

  cp->state = PROC_STOP; // we're becoming stopped
  103bfb:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  103bfe:	c7 80 3c 04 00 00 00 	movl   $0x0,0x43c(%eax)
  103c05:	00 00 00 
  cp->runcpu = NULL; // no longer running
  103c08:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  103c0b:	c7 80 44 04 00 00 00 	movl   $0x0,0x444(%eax)
  103c12:	00 00 00 
  proc_save(cp, tf, entry);  // save process state after INT insn
  103c15:	8b 45 0c             	mov    0xc(%ebp),%eax
  103c18:	89 44 24 08          	mov    %eax,0x8(%esp)
  103c1c:	8b 45 08             	mov    0x8(%ebp),%eax
  103c1f:	89 44 24 04          	mov    %eax,0x4(%esp)
  103c23:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  103c26:	89 04 24             	mov    %eax,(%esp)
  103c29:	e8 ac fb ff ff       	call   1037da <proc_save>

  // If parent is waiting to sync with us, wake it up.
  if (p->state == PROC_WAIT && p->waitchild == cp) {
  103c2e:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  103c31:	8b 80 3c 04 00 00    	mov    0x43c(%eax),%eax
  103c37:	83 f8 03             	cmp    $0x3,%eax
  103c3a:	75 26                	jne    103c62 <proc_ret+0x11d>
  103c3c:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  103c3f:	8b 80 48 04 00 00    	mov    0x448(%eax),%eax
  103c45:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  103c48:	75 18                	jne    103c62 <proc_ret+0x11d>
    p->waitchild = NULL;
  103c4a:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  103c4d:	c7 80 48 04 00 00 00 	movl   $0x0,0x448(%eax)
  103c54:	00 00 00 
    proc_run(p);
  103c57:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  103c5a:	89 04 24             	mov    %eax,(%esp)
  103c5d:	e8 ce fd ff ff       	call   103a30 <proc_run>
  }

  spinlock_release(&p->lock);
  103c62:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  103c65:	89 04 24             	mov    %eax,(%esp)
  103c68:	e8 b8 f2 ff ff       	call   102f25 <spinlock_release>
  proc_sched();  // find and run someone else
  103c6d:	e8 da fc ff ff       	call   10394c <proc_sched>

00103c72 <proc_check>:
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
  103c72:	55                   	push   %ebp
  103c73:	89 e5                	mov    %esp,%ebp
  103c75:	57                   	push   %edi
  103c76:	56                   	push   %esi
  103c77:	53                   	push   %ebx
  103c78:	81 ec dc 00 00 00    	sub    $0xdc,%esp
	// Spawn 2 child processes, executing on statically allocated stacks.

	int i;
	for (i = 0; i < 4; i++) {
  103c7e:	c7 85 40 ff ff ff 00 	movl   $0x0,0xffffff40(%ebp)
  103c85:	00 00 00 
  103c88:	e9 12 01 00 00       	jmp    103d9f <proc_check+0x12d>
		// Setup register state for child
		uint32_t *esp = (uint32_t*) &child_stack[i][PAGESIZE];
  103c8d:	8b 85 40 ff ff ff    	mov    0xffffff40(%ebp),%eax
  103c93:	c1 e0 0c             	shl    $0xc,%eax
  103c96:	89 c2                	mov    %eax,%edx
  103c98:	b8 d0 bc 11 00       	mov    $0x11bcd0,%eax
  103c9d:	05 00 10 00 00       	add    $0x1000,%eax
  103ca2:	8d 04 02             	lea    (%edx,%eax,1),%eax
  103ca5:	89 85 44 ff ff ff    	mov    %eax,0xffffff44(%ebp)
		*--esp = i;	// push argument to child() function
  103cab:	83 ad 44 ff ff ff 04 	subl   $0x4,0xffffff44(%ebp)
  103cb2:	8b 95 40 ff ff ff    	mov    0xffffff40(%ebp),%edx
  103cb8:	8b 85 44 ff ff ff    	mov    0xffffff44(%ebp),%eax
  103cbe:	89 10                	mov    %edx,(%eax)
		*--esp = 0;	// fake return address
  103cc0:	83 ad 44 ff ff ff 04 	subl   $0x4,0xffffff44(%ebp)
  103cc7:	8b 85 44 ff ff ff    	mov    0xffffff44(%ebp),%eax
  103ccd:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		child_state.tf.eip = (uint32_t) child;
  103cd3:	b8 5d 41 10 00       	mov    $0x10415d,%eax
  103cd8:	a3 b8 ba 11 00       	mov    %eax,0x11bab8
		child_state.tf.esp = (uint32_t) esp;
  103cdd:	8b 85 44 ff ff ff    	mov    0xffffff44(%ebp),%eax
  103ce3:	a3 c4 ba 11 00       	mov    %eax,0x11bac4

		// Use PUT syscall to create each child,
		// but only start the first 2 children for now.
		cprintf("spawning child %d\n", i);
  103ce8:	8b 85 40 ff ff ff    	mov    0xffffff40(%ebp),%eax
  103cee:	89 44 24 04          	mov    %eax,0x4(%esp)
  103cf2:	c7 04 24 0f b8 10 00 	movl   $0x10b80f,(%esp)
  103cf9:	e8 ab 65 00 00       	call   10a2a9 <cprintf>
		sys_put(SYS_REGS | (i < 2 ? SYS_START : 0), i, &child_state,
  103cfe:	8b 85 40 ff ff ff    	mov    0xffffff40(%ebp),%eax
  103d04:	0f b7 c0             	movzwl %ax,%eax
  103d07:	89 85 2c ff ff ff    	mov    %eax,0xffffff2c(%ebp)
  103d0d:	83 bd 40 ff ff ff 01 	cmpl   $0x1,0xffffff40(%ebp)
  103d14:	7f 0c                	jg     103d22 <proc_check+0xb0>
  103d16:	c7 85 30 ff ff ff 10 	movl   $0x1010,0xffffff30(%ebp)
  103d1d:	10 00 00 
  103d20:	eb 0a                	jmp    103d2c <proc_check+0xba>
  103d22:	c7 85 30 ff ff ff 00 	movl   $0x1000,0xffffff30(%ebp)
  103d29:	10 00 00 
  103d2c:	8b 85 30 ff ff ff    	mov    0xffffff30(%ebp),%eax
  103d32:	89 85 60 ff ff ff    	mov    %eax,0xffffff60(%ebp)
  103d38:	0f b7 85 2c ff ff ff 	movzwl 0xffffff2c(%ebp),%eax
  103d3f:	66 89 85 5e ff ff ff 	mov    %ax,0xffffff5e(%ebp)
  103d46:	c7 85 58 ff ff ff 80 	movl   $0x11ba80,0xffffff58(%ebp)
  103d4d:	ba 11 00 
  103d50:	c7 85 54 ff ff ff 00 	movl   $0x0,0xffffff54(%ebp)
  103d57:	00 00 00 
  103d5a:	c7 85 50 ff ff ff 00 	movl   $0x0,0xffffff50(%ebp)
  103d61:	00 00 00 
  103d64:	c7 85 4c ff ff ff 00 	movl   $0x0,0xffffff4c(%ebp)
  103d6b:	00 00 00 
static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
  103d6e:	8b 85 60 ff ff ff    	mov    0xffffff60(%ebp),%eax
  103d74:	83 c8 01             	or     $0x1,%eax
  103d77:	8b 9d 58 ff ff ff    	mov    0xffffff58(%ebp),%ebx
  103d7d:	0f b7 95 5e ff ff ff 	movzwl 0xffffff5e(%ebp),%edx
  103d84:	8b b5 54 ff ff ff    	mov    0xffffff54(%ebp),%esi
  103d8a:	8b bd 50 ff ff ff    	mov    0xffffff50(%ebp),%edi
  103d90:	8b 8d 4c ff ff ff    	mov    0xffffff4c(%ebp),%ecx
  103d96:	cd 30                	int    $0x30
  103d98:	83 85 40 ff ff ff 01 	addl   $0x1,0xffffff40(%ebp)
  103d9f:	83 bd 40 ff ff ff 03 	cmpl   $0x3,0xffffff40(%ebp)
  103da6:	0f 8e e1 fe ff ff    	jle    103c8d <proc_check+0x1b>
			NULL, NULL, 0);
	}

	// Wait for both children to complete.
	// This should complete without preemptive scheduling
	// when we're running on a 2-processor machine.
	for (i = 0; i < 2; i++) {
  103dac:	c7 85 40 ff ff ff 00 	movl   $0x0,0xffffff40(%ebp)
  103db3:	00 00 00 
  103db6:	e9 89 00 00 00       	jmp    103e44 <proc_check+0x1d2>
		cprintf("waiting for child %d\n", i);
  103dbb:	8b 85 40 ff ff ff    	mov    0xffffff40(%ebp),%eax
  103dc1:	89 44 24 04          	mov    %eax,0x4(%esp)
  103dc5:	c7 04 24 22 b8 10 00 	movl   $0x10b822,(%esp)
  103dcc:	e8 d8 64 00 00       	call   10a2a9 <cprintf>
		sys_get(SYS_REGS, i, &child_state, NULL, NULL, 0);
  103dd1:	8b 85 40 ff ff ff    	mov    0xffffff40(%ebp),%eax
  103dd7:	0f b7 c0             	movzwl %ax,%eax
  103dda:	c7 85 78 ff ff ff 00 	movl   $0x1000,0xffffff78(%ebp)
  103de1:	10 00 00 
  103de4:	66 89 85 76 ff ff ff 	mov    %ax,0xffffff76(%ebp)
  103deb:	c7 85 70 ff ff ff 80 	movl   $0x11ba80,0xffffff70(%ebp)
  103df2:	ba 11 00 
  103df5:	c7 85 6c ff ff ff 00 	movl   $0x0,0xffffff6c(%ebp)
  103dfc:	00 00 00 
  103dff:	c7 85 68 ff ff ff 00 	movl   $0x0,0xffffff68(%ebp)
  103e06:	00 00 00 
  103e09:	c7 85 64 ff ff ff 00 	movl   $0x0,0xffffff64(%ebp)
  103e10:	00 00 00 
static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
  103e13:	8b 85 78 ff ff ff    	mov    0xffffff78(%ebp),%eax
  103e19:	83 c8 02             	or     $0x2,%eax
  103e1c:	8b 9d 70 ff ff ff    	mov    0xffffff70(%ebp),%ebx
  103e22:	0f b7 95 76 ff ff ff 	movzwl 0xffffff76(%ebp),%edx
  103e29:	8b b5 6c ff ff ff    	mov    0xffffff6c(%ebp),%esi
  103e2f:	8b bd 68 ff ff ff    	mov    0xffffff68(%ebp),%edi
  103e35:	8b 8d 64 ff ff ff    	mov    0xffffff64(%ebp),%ecx
  103e3b:	cd 30                	int    $0x30
  103e3d:	83 85 40 ff ff ff 01 	addl   $0x1,0xffffff40(%ebp)
  103e44:	83 bd 40 ff ff ff 01 	cmpl   $0x1,0xffffff40(%ebp)
  103e4b:	0f 8e 6a ff ff ff    	jle    103dbb <proc_check+0x149>
	}
	cprintf("proc_check() 2-child test succeeded\n");
  103e51:	c7 04 24 38 b8 10 00 	movl   $0x10b838,(%esp)
  103e58:	e8 4c 64 00 00       	call   10a2a9 <cprintf>

	// (Re)start all four children, and wait for them.
	// This will require preemptive scheduling to complete
	// if we have less than 4 CPUs.
	cprintf("proc_check: spawning 4 children\n");
  103e5d:	c7 04 24 60 b8 10 00 	movl   $0x10b860,(%esp)
  103e64:	e8 40 64 00 00       	call   10a2a9 <cprintf>
	for (i = 0; i < 4; i++) {
  103e69:	c7 85 40 ff ff ff 00 	movl   $0x0,0xffffff40(%ebp)
  103e70:	00 00 00 
  103e73:	eb 6b                	jmp    103ee0 <proc_check+0x26e>
		cprintf("spawning child %d\n", i);
  103e75:	8b 85 40 ff ff ff    	mov    0xffffff40(%ebp),%eax
  103e7b:	89 44 24 04          	mov    %eax,0x4(%esp)
  103e7f:	c7 04 24 0f b8 10 00 	movl   $0x10b80f,(%esp)
  103e86:	e8 1e 64 00 00       	call   10a2a9 <cprintf>
		sys_put(SYS_START, i, NULL, NULL, NULL, 0);
  103e8b:	8b 85 40 ff ff ff    	mov    0xffffff40(%ebp),%eax
  103e91:	0f b7 c0             	movzwl %ax,%eax
  103e94:	c7 45 90 10 00 00 00 	movl   $0x10,0xffffff90(%ebp)
  103e9b:	66 89 45 8e          	mov    %ax,0xffffff8e(%ebp)
  103e9f:	c7 45 88 00 00 00 00 	movl   $0x0,0xffffff88(%ebp)
  103ea6:	c7 45 84 00 00 00 00 	movl   $0x0,0xffffff84(%ebp)
  103ead:	c7 45 80 00 00 00 00 	movl   $0x0,0xffffff80(%ebp)
  103eb4:	c7 85 7c ff ff ff 00 	movl   $0x0,0xffffff7c(%ebp)
  103ebb:	00 00 00 
static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
  103ebe:	8b 45 90             	mov    0xffffff90(%ebp),%eax
  103ec1:	83 c8 01             	or     $0x1,%eax
  103ec4:	8b 5d 88             	mov    0xffffff88(%ebp),%ebx
  103ec7:	0f b7 55 8e          	movzwl 0xffffff8e(%ebp),%edx
  103ecb:	8b 75 84             	mov    0xffffff84(%ebp),%esi
  103ece:	8b 7d 80             	mov    0xffffff80(%ebp),%edi
  103ed1:	8b 8d 7c ff ff ff    	mov    0xffffff7c(%ebp),%ecx
  103ed7:	cd 30                	int    $0x30
  103ed9:	83 85 40 ff ff ff 01 	addl   $0x1,0xffffff40(%ebp)
  103ee0:	83 bd 40 ff ff ff 03 	cmpl   $0x3,0xffffff40(%ebp)
  103ee7:	7e 8c                	jle    103e75 <proc_check+0x203>
	}

	// Wait for all 4 children to complete.
	for (i = 0; i < 4; i++)
  103ee9:	c7 85 40 ff ff ff 00 	movl   $0x0,0xffffff40(%ebp)
  103ef0:	00 00 00 
  103ef3:	eb 4f                	jmp    103f44 <proc_check+0x2d2>
		sys_get(0, i, NULL, NULL, NULL, 0);
  103ef5:	8b 85 40 ff ff ff    	mov    0xffffff40(%ebp),%eax
  103efb:	0f b7 c0             	movzwl %ax,%eax
  103efe:	c7 45 a8 00 00 00 00 	movl   $0x0,0xffffffa8(%ebp)
  103f05:	66 89 45 a6          	mov    %ax,0xffffffa6(%ebp)
  103f09:	c7 45 a0 00 00 00 00 	movl   $0x0,0xffffffa0(%ebp)
  103f10:	c7 45 9c 00 00 00 00 	movl   $0x0,0xffffff9c(%ebp)
  103f17:	c7 45 98 00 00 00 00 	movl   $0x0,0xffffff98(%ebp)
  103f1e:	c7 45 94 00 00 00 00 	movl   $0x0,0xffffff94(%ebp)
static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
  103f25:	8b 45 a8             	mov    0xffffffa8(%ebp),%eax
  103f28:	83 c8 02             	or     $0x2,%eax
  103f2b:	8b 5d a0             	mov    0xffffffa0(%ebp),%ebx
  103f2e:	0f b7 55 a6          	movzwl 0xffffffa6(%ebp),%edx
  103f32:	8b 75 9c             	mov    0xffffff9c(%ebp),%esi
  103f35:	8b 7d 98             	mov    0xffffff98(%ebp),%edi
  103f38:	8b 4d 94             	mov    0xffffff94(%ebp),%ecx
  103f3b:	cd 30                	int    $0x30
  103f3d:	83 85 40 ff ff ff 01 	addl   $0x1,0xffffff40(%ebp)
  103f44:	83 bd 40 ff ff ff 03 	cmpl   $0x3,0xffffff40(%ebp)
  103f4b:	7e a8                	jle    103ef5 <proc_check+0x283>
	cprintf("proc_check() 4-child test succeeded\n");
  103f4d:	c7 04 24 84 b8 10 00 	movl   $0x10b884,(%esp)
  103f54:	e8 50 63 00 00       	call   10a2a9 <cprintf>

	// Now do a trap handling test using all 4 children -
	// but they'll _think_ they're all child 0!
	// (We'll lose the register state of the other children.)
	i = 0;
  103f59:	c7 85 40 ff ff ff 00 	movl   $0x0,0xffffff40(%ebp)
  103f60:	00 00 00 
	sys_get(SYS_REGS, i, &child_state, NULL, NULL, 0);
  103f63:	8b 85 40 ff ff ff    	mov    0xffffff40(%ebp),%eax
  103f69:	0f b7 c0             	movzwl %ax,%eax
  103f6c:	c7 45 c0 00 10 00 00 	movl   $0x1000,0xffffffc0(%ebp)
  103f73:	66 89 45 be          	mov    %ax,0xffffffbe(%ebp)
  103f77:	c7 45 b8 80 ba 11 00 	movl   $0x11ba80,0xffffffb8(%ebp)
  103f7e:	c7 45 b4 00 00 00 00 	movl   $0x0,0xffffffb4(%ebp)
  103f85:	c7 45 b0 00 00 00 00 	movl   $0x0,0xffffffb0(%ebp)
  103f8c:	c7 45 ac 00 00 00 00 	movl   $0x0,0xffffffac(%ebp)
static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
  103f93:	8b 45 c0             	mov    0xffffffc0(%ebp),%eax
  103f96:	83 c8 02             	or     $0x2,%eax
  103f99:	8b 5d b8             	mov    0xffffffb8(%ebp),%ebx
  103f9c:	0f b7 55 be          	movzwl 0xffffffbe(%ebp),%edx
  103fa0:	8b 75 b4             	mov    0xffffffb4(%ebp),%esi
  103fa3:	8b 7d b0             	mov    0xffffffb0(%ebp),%edi
  103fa6:	8b 4d ac             	mov    0xffffffac(%ebp),%ecx
  103fa9:	cd 30                	int    $0x30
		// get child 0's state
	assert(recovargs == NULL);
  103fab:	a1 d0 fc 11 00       	mov    0x11fcd0,%eax
  103fb0:	85 c0                	test   %eax,%eax
  103fb2:	74 24                	je     103fd8 <proc_check+0x366>
  103fb4:	c7 44 24 0c a9 b8 10 	movl   $0x10b8a9,0xc(%esp)
  103fbb:	00 
  103fbc:	c7 44 24 08 7a b6 10 	movl   $0x10b67a,0x8(%esp)
  103fc3:	00 
  103fc4:	c7 44 24 04 25 01 00 	movl   $0x125,0x4(%esp)
  103fcb:	00 
  103fcc:	c7 04 24 58 b6 10 00 	movl   $0x10b658,(%esp)
  103fd3:	e8 c4 c7 ff ff       	call   10079c <debug_panic>
	do {
		sys_put(SYS_REGS | SYS_START, i, &child_state, NULL, NULL, 0);
  103fd8:	8b 85 40 ff ff ff    	mov    0xffffff40(%ebp),%eax
  103fde:	0f b7 c0             	movzwl %ax,%eax
  103fe1:	c7 45 d8 10 10 00 00 	movl   $0x1010,0xffffffd8(%ebp)
  103fe8:	66 89 45 d6          	mov    %ax,0xffffffd6(%ebp)
  103fec:	c7 45 d0 80 ba 11 00 	movl   $0x11ba80,0xffffffd0(%ebp)
  103ff3:	c7 45 cc 00 00 00 00 	movl   $0x0,0xffffffcc(%ebp)
  103ffa:	c7 45 c8 00 00 00 00 	movl   $0x0,0xffffffc8(%ebp)
  104001:	c7 45 c4 00 00 00 00 	movl   $0x0,0xffffffc4(%ebp)
static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
  104008:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  10400b:	83 c8 01             	or     $0x1,%eax
  10400e:	8b 5d d0             	mov    0xffffffd0(%ebp),%ebx
  104011:	0f b7 55 d6          	movzwl 0xffffffd6(%ebp),%edx
  104015:	8b 75 cc             	mov    0xffffffcc(%ebp),%esi
  104018:	8b 7d c8             	mov    0xffffffc8(%ebp),%edi
  10401b:	8b 4d c4             	mov    0xffffffc4(%ebp),%ecx
  10401e:	cd 30                	int    $0x30
		sys_get(SYS_REGS, i, &child_state, NULL, NULL, 0);
  104020:	8b 85 40 ff ff ff    	mov    0xffffff40(%ebp),%eax
  104026:	0f b7 c0             	movzwl %ax,%eax
  104029:	c7 45 f0 00 10 00 00 	movl   $0x1000,0xfffffff0(%ebp)
  104030:	66 89 45 ee          	mov    %ax,0xffffffee(%ebp)
  104034:	c7 45 e8 80 ba 11 00 	movl   $0x11ba80,0xffffffe8(%ebp)
  10403b:	c7 45 e4 00 00 00 00 	movl   $0x0,0xffffffe4(%ebp)
  104042:	c7 45 e0 00 00 00 00 	movl   $0x0,0xffffffe0(%ebp)
  104049:	c7 45 dc 00 00 00 00 	movl   $0x0,0xffffffdc(%ebp)
static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
  104050:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  104053:	83 c8 02             	or     $0x2,%eax
  104056:	8b 5d e8             	mov    0xffffffe8(%ebp),%ebx
  104059:	0f b7 55 ee          	movzwl 0xffffffee(%ebp),%edx
  10405d:	8b 75 e4             	mov    0xffffffe4(%ebp),%esi
  104060:	8b 7d e0             	mov    0xffffffe0(%ebp),%edi
  104063:	8b 4d dc             	mov    0xffffffdc(%ebp),%ecx
  104066:	cd 30                	int    $0x30
		if (recovargs) {	// trap recovery needed
  104068:	a1 d0 fc 11 00       	mov    0x11fcd0,%eax
  10406d:	85 c0                	test   %eax,%eax
  10406f:	74 3f                	je     1040b0 <proc_check+0x43e>
			trap_check_args *args = recovargs;
  104071:	a1 d0 fc 11 00       	mov    0x11fcd0,%eax
  104076:	89 85 48 ff ff ff    	mov    %eax,0xffffff48(%ebp)
			cprintf("recover from trap %d\n",
  10407c:	a1 b0 ba 11 00       	mov    0x11bab0,%eax
  104081:	89 44 24 04          	mov    %eax,0x4(%esp)
  104085:	c7 04 24 bb b8 10 00 	movl   $0x10b8bb,(%esp)
  10408c:	e8 18 62 00 00       	call   10a2a9 <cprintf>
				child_state.tf.trapno);
			child_state.tf.eip = (uint32_t) args->reip;
  104091:	8b 85 48 ff ff ff    	mov    0xffffff48(%ebp),%eax
  104097:	8b 00                	mov    (%eax),%eax
  104099:	a3 b8 ba 11 00       	mov    %eax,0x11bab8
			args->trapno = child_state.tf.trapno;
  10409e:	a1 b0 ba 11 00       	mov    0x11bab0,%eax
  1040a3:	89 c2                	mov    %eax,%edx
  1040a5:	8b 85 48 ff ff ff    	mov    0xffffff48(%ebp),%eax
  1040ab:	89 50 04             	mov    %edx,0x4(%eax)
  1040ae:	eb 2e                	jmp    1040de <proc_check+0x46c>
		} else
			assert(child_state.tf.trapno == T_SYSCALL);
  1040b0:	a1 b0 ba 11 00       	mov    0x11bab0,%eax
  1040b5:	83 f8 30             	cmp    $0x30,%eax
  1040b8:	74 24                	je     1040de <proc_check+0x46c>
  1040ba:	c7 44 24 0c d4 b8 10 	movl   $0x10b8d4,0xc(%esp)
  1040c1:	00 
  1040c2:	c7 44 24 08 7a b6 10 	movl   $0x10b67a,0x8(%esp)
  1040c9:	00 
  1040ca:	c7 44 24 04 30 01 00 	movl   $0x130,0x4(%esp)
  1040d1:	00 
  1040d2:	c7 04 24 58 b6 10 00 	movl   $0x10b658,(%esp)
  1040d9:	e8 be c6 ff ff       	call   10079c <debug_panic>
		i = (i+1) % 4;	// rotate to next child proc
  1040de:	8b 95 40 ff ff ff    	mov    0xffffff40(%ebp),%edx
  1040e4:	83 c2 01             	add    $0x1,%edx
  1040e7:	89 d0                	mov    %edx,%eax
  1040e9:	c1 f8 1f             	sar    $0x1f,%eax
  1040ec:	89 c1                	mov    %eax,%ecx
  1040ee:	c1 e9 1e             	shr    $0x1e,%ecx
  1040f1:	8d 04 0a             	lea    (%edx,%ecx,1),%eax
  1040f4:	83 e0 03             	and    $0x3,%eax
  1040f7:	29 c8                	sub    %ecx,%eax
  1040f9:	89 85 40 ff ff ff    	mov    %eax,0xffffff40(%ebp)
	} while (child_state.tf.trapno != T_SYSCALL);
  1040ff:	a1 b0 ba 11 00       	mov    0x11bab0,%eax
  104104:	83 f8 30             	cmp    $0x30,%eax
  104107:	0f 85 cb fe ff ff    	jne    103fd8 <proc_check+0x366>
	assert(recovargs == NULL);
  10410d:	a1 d0 fc 11 00       	mov    0x11fcd0,%eax
  104112:	85 c0                	test   %eax,%eax
  104114:	74 24                	je     10413a <proc_check+0x4c8>
  104116:	c7 44 24 0c a9 b8 10 	movl   $0x10b8a9,0xc(%esp)
  10411d:	00 
  10411e:	c7 44 24 08 7a b6 10 	movl   $0x10b67a,0x8(%esp)
  104125:	00 
  104126:	c7 44 24 04 33 01 00 	movl   $0x133,0x4(%esp)
  10412d:	00 
  10412e:	c7 04 24 58 b6 10 00 	movl   $0x10b658,(%esp)
  104135:	e8 62 c6 ff ff       	call   10079c <debug_panic>

	cprintf("proc_check() trap reflection test succeeded\n");
  10413a:	c7 04 24 f8 b8 10 00 	movl   $0x10b8f8,(%esp)
  104141:	e8 63 61 00 00       	call   10a2a9 <cprintf>

	cprintf("proc_check() succeeded!\n");
  104146:	c7 04 24 25 b9 10 00 	movl   $0x10b925,(%esp)
  10414d:	e8 57 61 00 00       	call   10a2a9 <cprintf>
 }
  104152:	81 c4 dc 00 00 00    	add    $0xdc,%esp
  104158:	5b                   	pop    %ebx
  104159:	5e                   	pop    %esi
  10415a:	5f                   	pop    %edi
  10415b:	5d                   	pop    %ebp
  10415c:	c3                   	ret    

0010415d <child>:

static void child(int n)
{
  10415d:	55                   	push   %ebp
  10415e:	89 e5                	mov    %esp,%ebp
  104160:	83 ec 28             	sub    $0x28,%esp
	// Only first 2 children participate in first pingpong test
	if (n < 2) {
  104163:	83 7d 08 01          	cmpl   $0x1,0x8(%ebp)
  104167:	7f 64                	jg     1041cd <child+0x70>
		int i;
		for (i = 0; i < 10; i++) {
  104169:	c7 45 fc 00 00 00 00 	movl   $0x0,0xfffffffc(%ebp)
  104170:	eb 4e                	jmp    1041c0 <child+0x63>
			cprintf("in child %d count %d\n", n, i);
  104172:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  104175:	89 44 24 08          	mov    %eax,0x8(%esp)
  104179:	8b 45 08             	mov    0x8(%ebp),%eax
  10417c:	89 44 24 04          	mov    %eax,0x4(%esp)
  104180:	c7 04 24 3e b9 10 00 	movl   $0x10b93e,(%esp)
  104187:	e8 1d 61 00 00       	call   10a2a9 <cprintf>
			while (pingpong != n)
  10418c:	eb 05                	jmp    104193 <child+0x36>
				pause();
  10418e:	e8 96 f8 ff ff       	call   103a29 <pause>
  104193:	8b 55 08             	mov    0x8(%ebp),%edx
  104196:	a1 20 ba 11 00       	mov    0x11ba20,%eax
  10419b:	39 c2                	cmp    %eax,%edx
  10419d:	75 ef                	jne    10418e <child+0x31>
			xchg(&pingpong, !pingpong);
  10419f:	a1 20 ba 11 00       	mov    0x11ba20,%eax
  1041a4:	85 c0                	test   %eax,%eax
  1041a6:	0f 94 c0             	sete   %al
  1041a9:	0f b6 c0             	movzbl %al,%eax
  1041ac:	89 44 24 04          	mov    %eax,0x4(%esp)
  1041b0:	c7 04 24 20 ba 11 00 	movl   $0x11ba20,(%esp)
  1041b7:	e8 02 01 00 00       	call   1042be <xchg>
  1041bc:	83 45 fc 01          	addl   $0x1,0xfffffffc(%ebp)
  1041c0:	83 7d fc 09          	cmpl   $0x9,0xfffffffc(%ebp)
  1041c4:	7e ac                	jle    104172 <child+0x15>

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
  1041c6:	b8 03 00 00 00       	mov    $0x3,%eax
  1041cb:	cd 30                	int    $0x30
		}
		sys_ret();
	}

	// Second test, round-robin pingpong between all 4 children
	int i;
	for (i = 0; i < 10; i++) {
  1041cd:	c7 45 f8 00 00 00 00 	movl   $0x0,0xfffffff8(%ebp)
  1041d4:	eb 4c                	jmp    104222 <child+0xc5>
		cprintf("in child %d count %d\n", n, i);
  1041d6:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1041d9:	89 44 24 08          	mov    %eax,0x8(%esp)
  1041dd:	8b 45 08             	mov    0x8(%ebp),%eax
  1041e0:	89 44 24 04          	mov    %eax,0x4(%esp)
  1041e4:	c7 04 24 3e b9 10 00 	movl   $0x10b93e,(%esp)
  1041eb:	e8 b9 60 00 00       	call   10a2a9 <cprintf>
		while (pingpong != n)
  1041f0:	eb 05                	jmp    1041f7 <child+0x9a>
			pause();
  1041f2:	e8 32 f8 ff ff       	call   103a29 <pause>
  1041f7:	8b 55 08             	mov    0x8(%ebp),%edx
  1041fa:	a1 20 ba 11 00       	mov    0x11ba20,%eax
  1041ff:	39 c2                	cmp    %eax,%edx
  104201:	75 ef                	jne    1041f2 <child+0x95>
		xchg(&pingpong, (pingpong + 1) % 4);
  104203:	a1 20 ba 11 00       	mov    0x11ba20,%eax
  104208:	83 c0 01             	add    $0x1,%eax
  10420b:	83 e0 03             	and    $0x3,%eax
  10420e:	89 44 24 04          	mov    %eax,0x4(%esp)
  104212:	c7 04 24 20 ba 11 00 	movl   $0x11ba20,(%esp)
  104219:	e8 a0 00 00 00       	call   1042be <xchg>
  10421e:	83 45 f8 01          	addl   $0x1,0xfffffff8(%ebp)
  104222:	83 7d f8 09          	cmpl   $0x9,0xfffffff8(%ebp)
  104226:	7e ae                	jle    1041d6 <child+0x79>

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
  104228:	b8 03 00 00 00       	mov    $0x3,%eax
  10422d:	cd 30                	int    $0x30
	}
	sys_ret();

	// Only "child 0" (or the proc that thinks it's child 0), trap check...
	if (n == 0) {
  10422f:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  104233:	75 6d                	jne    1042a2 <child+0x145>
		assert(recovargs == NULL);
  104235:	a1 d0 fc 11 00       	mov    0x11fcd0,%eax
  10423a:	85 c0                	test   %eax,%eax
  10423c:	74 24                	je     104262 <child+0x105>
  10423e:	c7 44 24 0c a9 b8 10 	movl   $0x10b8a9,0xc(%esp)
  104245:	00 
  104246:	c7 44 24 08 7a b6 10 	movl   $0x10b67a,0x8(%esp)
  10424d:	00 
  10424e:	c7 44 24 04 54 01 00 	movl   $0x154,0x4(%esp)
  104255:	00 
  104256:	c7 04 24 58 b6 10 00 	movl   $0x10b658,(%esp)
  10425d:	e8 3a c5 ff ff       	call   10079c <debug_panic>
		trap_check(&recovargs);
  104262:	c7 04 24 d0 fc 11 00 	movl   $0x11fcd0,(%esp)
  104269:	e8 3e e4 ff ff       	call   1026ac <trap_check>
		assert(recovargs == NULL);
  10426e:	a1 d0 fc 11 00       	mov    0x11fcd0,%eax
  104273:	85 c0                	test   %eax,%eax
  104275:	74 24                	je     10429b <child+0x13e>
  104277:	c7 44 24 0c a9 b8 10 	movl   $0x10b8a9,0xc(%esp)
  10427e:	00 
  10427f:	c7 44 24 08 7a b6 10 	movl   $0x10b67a,0x8(%esp)
  104286:	00 
  104287:	c7 44 24 04 56 01 00 	movl   $0x156,0x4(%esp)
  10428e:	00 
  10428f:	c7 04 24 58 b6 10 00 	movl   $0x10b658,(%esp)
  104296:	e8 01 c5 ff ff       	call   10079c <debug_panic>

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
  10429b:	b8 03 00 00 00       	mov    $0x3,%eax
  1042a0:	cd 30                	int    $0x30
		sys_ret();
	}

	panic("child(): shouldn't have gotten here");
  1042a2:	c7 44 24 08 54 b9 10 	movl   $0x10b954,0x8(%esp)
  1042a9:	00 
  1042aa:	c7 44 24 04 5a 01 00 	movl   $0x15a,0x4(%esp)
  1042b1:	00 
  1042b2:	c7 04 24 58 b6 10 00 	movl   $0x10b658,(%esp)
  1042b9:	e8 de c4 ff ff       	call   10079c <debug_panic>

001042be <xchg>:

// Atomically set *addr to newval and return the old value of *addr.
static inline uint32_t
xchg(volatile uint32_t *addr, uint32_t newval)
{
  1042be:	55                   	push   %ebp
  1042bf:	89 e5                	mov    %esp,%ebp
  1042c1:	53                   	push   %ebx
  1042c2:	83 ec 14             	sub    $0x14,%esp
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
  1042c5:	8b 4d 08             	mov    0x8(%ebp),%ecx
  1042c8:	8b 55 0c             	mov    0xc(%ebp),%edx
  1042cb:	8b 45 08             	mov    0x8(%ebp),%eax
  1042ce:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  1042d1:	89 d0                	mov    %edx,%eax
  1042d3:	8b 5d e8             	mov    0xffffffe8(%ebp),%ebx
  1042d6:	f0 87 01             	lock xchg %eax,(%ecx)
  1042d9:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  1042dc:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  1042df:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
	       "+m" (*addr), "=a" (result) :
	       "1" (newval) :
	       "cc");
	return result;
  1042e2:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
}
  1042e5:	83 c4 14             	add    $0x14,%esp
  1042e8:	5b                   	pop    %ebx
  1042e9:	5d                   	pop    %ebp
  1042ea:	c3                   	ret    

001042eb <grandchild>:
 }

static void grandchild(int n)
{
  1042eb:	55                   	push   %ebp
  1042ec:	89 e5                	mov    %esp,%ebp
  1042ee:	83 ec 18             	sub    $0x18,%esp
	panic("grandchild(): shouldn't have gotten here");
  1042f1:	c7 44 24 08 78 b9 10 	movl   $0x10b978,0x8(%esp)
  1042f8:	00 
  1042f9:	c7 44 24 04 5f 01 00 	movl   $0x15f,0x4(%esp)
  104300:	00 
  104301:	c7 04 24 58 b6 10 00 	movl   $0x10b658,(%esp)
  104308:	e8 8f c4 ff ff       	call   10079c <debug_panic>
  10430d:	90                   	nop    
  10430e:	90                   	nop    
  10430f:	90                   	nop    

00104310 <systrap>:
// as if the user code's INT 0x30 instruction had caused it -
// and reflect the trap to the parent process as with other traps.
static void gcc_noreturn
systrap(trapframe *utf, int trapno, int err)
{
  104310:	55                   	push   %ebp
  104311:	89 e5                	mov    %esp,%ebp
  104313:	83 ec 08             	sub    $0x8,%esp
  utf->trapno = trapno;
  104316:	8b 55 0c             	mov    0xc(%ebp),%edx
  104319:	8b 45 08             	mov    0x8(%ebp),%eax
  10431c:	89 50 30             	mov    %edx,0x30(%eax)
  utf->err = err;
  10431f:	8b 55 10             	mov    0x10(%ebp),%edx
  104322:	8b 45 08             	mov    0x8(%ebp),%eax
  104325:	89 50 34             	mov    %edx,0x34(%eax)
  proc_ret(utf,0);
  104328:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  10432f:	00 
  104330:	8b 45 08             	mov    0x8(%ebp),%eax
  104333:	89 04 24             	mov    %eax,(%esp)
  104336:	e8 0a f8 ff ff       	call   103b45 <proc_ret>

0010433b <sysrecover>:
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
  10433b:	55                   	push   %ebp
  10433c:	89 e5                	mov    %esp,%ebp
  10433e:	83 ec 28             	sub    $0x28,%esp
  trapframe *utf = (trapframe*)recoverdata;
  104341:	8b 45 0c             	mov    0xc(%ebp),%eax
  104344:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)

  cpu *c = cpu_cur();
  104347:	e8 65 00 00 00       	call   1043b1 <cpu_cur>
  10434c:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  assert(c->recover == sysrecover);
  10434f:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  104352:	8b 80 a0 00 00 00    	mov    0xa0(%eax),%eax
  104358:	3d 3b 43 10 00       	cmp    $0x10433b,%eax
  10435d:	74 24                	je     104383 <sysrecover+0x48>
  10435f:	c7 44 24 0c a4 b9 10 	movl   $0x10b9a4,0xc(%esp)
  104366:	00 
  104367:	c7 44 24 08 bd b9 10 	movl   $0x10b9bd,0x8(%esp)
  10436e:	00 
  10436f:	c7 44 24 04 3b 00 00 	movl   $0x3b,0x4(%esp)
  104376:	00 
  104377:	c7 04 24 d2 b9 10 00 	movl   $0x10b9d2,(%esp)
  10437e:	e8 19 c4 ff ff       	call   10079c <debug_panic>
  c->recover = NULL;
  104383:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  104386:	c7 80 a0 00 00 00 00 	movl   $0x0,0xa0(%eax)
  10438d:	00 00 00 

  systrap(utf, ktf->trapno, ktf->err);
  104390:	8b 45 08             	mov    0x8(%ebp),%eax
  104393:	8b 40 34             	mov    0x34(%eax),%eax
  104396:	89 c2                	mov    %eax,%edx
  104398:	8b 45 08             	mov    0x8(%ebp),%eax
  10439b:	8b 40 30             	mov    0x30(%eax),%eax
  10439e:	89 54 24 08          	mov    %edx,0x8(%esp)
  1043a2:	89 44 24 04          	mov    %eax,0x4(%esp)
  1043a6:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1043a9:	89 04 24             	mov    %eax,(%esp)
  1043ac:	e8 5f ff ff ff       	call   104310 <systrap>

001043b1 <cpu_cur>:

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  1043b1:	55                   	push   %ebp
  1043b2:	89 e5                	mov    %esp,%ebp
  1043b4:	83 ec 28             	sub    $0x28,%esp
static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  1043b7:	89 65 fc             	mov    %esp,0xfffffffc(%ebp)
        return esp;
  1043ba:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  1043bd:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  1043c0:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1043c3:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1043c8:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	assert(c->magic == CPU_MAGIC);
  1043cb:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  1043ce:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  1043d4:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  1043d9:	74 24                	je     1043ff <cpu_cur+0x4e>
  1043db:	c7 44 24 0c e1 b9 10 	movl   $0x10b9e1,0xc(%esp)
  1043e2:	00 
  1043e3:	c7 44 24 08 bd b9 10 	movl   $0x10b9bd,0x8(%esp)
  1043ea:	00 
  1043eb:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  1043f2:	00 
  1043f3:	c7 04 24 f7 b9 10 00 	movl   $0x10b9f7,(%esp)
  1043fa:	e8 9d c3 ff ff       	call   10079c <debug_panic>
	return c;
  1043ff:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
}
  104402:	c9                   	leave  
  104403:	c3                   	ret    

00104404 <checkva>:
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
  104404:	55                   	push   %ebp
  104405:	89 e5                	mov    %esp,%ebp
  104407:	83 ec 18             	sub    $0x18,%esp
  if(uva < VM_USERLO || uva >= VM_USERHI || size >= VM_USERHI -uva){
  10440a:	81 7d 0c ff ff ff 3f 	cmpl   $0x3fffffff,0xc(%ebp)
  104411:	76 16                	jbe    104429 <checkva+0x25>
  104413:	81 7d 0c ff ff ff ef 	cmpl   $0xefffffff,0xc(%ebp)
  10441a:	77 0d                	ja     104429 <checkva+0x25>
  10441c:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
  104421:	2b 45 0c             	sub    0xc(%ebp),%eax
  104424:	3b 45 10             	cmp    0x10(%ebp),%eax
  104427:	77 1b                	ja     104444 <checkva+0x40>

  systrap(utf, T_PGFLT, 0);
  104429:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  104430:	00 
  104431:	c7 44 24 04 0e 00 00 	movl   $0xe,0x4(%esp)
  104438:	00 
  104439:	8b 45 08             	mov    0x8(%ebp),%eax
  10443c:	89 04 24             	mov    %eax,(%esp)
  10443f:	e8 cc fe ff ff       	call   104310 <systrap>
  }
}
  104444:	c9                   	leave  
  104445:	c3                   	ret    

00104446 <usercopy>:

// Copy data to/from user space,
// using checkva() above to validate the address range
// and using sysrecover() to recover from any traps during the copy.
void usercopy(trapframe *utf, bool copyout,
			void *kva, uint32_t uva, size_t size)
{
  104446:	55                   	push   %ebp
  104447:	89 e5                	mov    %esp,%ebp
  104449:	83 ec 28             	sub    $0x28,%esp
	checkva(utf, uva, size);
  10444c:	8b 45 18             	mov    0x18(%ebp),%eax
  10444f:	89 44 24 08          	mov    %eax,0x8(%esp)
  104453:	8b 45 14             	mov    0x14(%ebp),%eax
  104456:	89 44 24 04          	mov    %eax,0x4(%esp)
  10445a:	8b 45 08             	mov    0x8(%ebp),%eax
  10445d:	89 04 24             	mov    %eax,(%esp)
  104460:	e8 9f ff ff ff       	call   104404 <checkva>

  cpu *c = cpu_cur();
  104465:	e8 47 ff ff ff       	call   1043b1 <cpu_cur>
  10446a:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  assert(c->recover == NULL);
  10446d:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  104470:	8b 80 a0 00 00 00    	mov    0xa0(%eax),%eax
  104476:	85 c0                	test   %eax,%eax
  104478:	74 24                	je     10449e <usercopy+0x58>
  10447a:	c7 44 24 0c 04 ba 10 	movl   $0x10ba04,0xc(%esp)
  104481:	00 
  104482:	c7 44 24 08 bd b9 10 	movl   $0x10b9bd,0x8(%esp)
  104489:	00 
  10448a:	c7 44 24 04 5b 00 00 	movl   $0x5b,0x4(%esp)
  104491:	00 
  104492:	c7 04 24 d2 b9 10 00 	movl   $0x10b9d2,(%esp)
  104499:	e8 fe c2 ff ff       	call   10079c <debug_panic>
  c->recover = sysrecover;
  10449e:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  1044a1:	c7 80 a0 00 00 00 3b 	movl   $0x10433b,0xa0(%eax)
  1044a8:	43 10 00 

  if(copyout)
  1044ab:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  1044af:	74 1b                	je     1044cc <usercopy+0x86>
  memmove((void*)uva, kva, size);
  1044b1:	8b 45 14             	mov    0x14(%ebp),%eax
  1044b4:	8b 55 18             	mov    0x18(%ebp),%edx
  1044b7:	89 54 24 08          	mov    %edx,0x8(%esp)
  1044bb:	8b 55 10             	mov    0x10(%ebp),%edx
  1044be:	89 54 24 04          	mov    %edx,0x4(%esp)
  1044c2:	89 04 24             	mov    %eax,(%esp)
  1044c5:	e8 50 60 00 00       	call   10a51a <memmove>
  1044ca:	eb 19                	jmp    1044e5 <usercopy+0x9f>
  else
  memmove(kva, (void*)uva, size);
  1044cc:	8b 45 14             	mov    0x14(%ebp),%eax
  1044cf:	8b 55 18             	mov    0x18(%ebp),%edx
  1044d2:	89 54 24 08          	mov    %edx,0x8(%esp)
  1044d6:	89 44 24 04          	mov    %eax,0x4(%esp)
  1044da:	8b 45 10             	mov    0x10(%ebp),%eax
  1044dd:	89 04 24             	mov    %eax,(%esp)
  1044e0:	e8 35 60 00 00       	call   10a51a <memmove>

  assert(c->recover == sysrecover);
  1044e5:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  1044e8:	8b 80 a0 00 00 00    	mov    0xa0(%eax),%eax
  1044ee:	3d 3b 43 10 00       	cmp    $0x10433b,%eax
  1044f3:	74 24                	je     104519 <usercopy+0xd3>
  1044f5:	c7 44 24 0c a4 b9 10 	movl   $0x10b9a4,0xc(%esp)
  1044fc:	00 
  1044fd:	c7 44 24 08 bd b9 10 	movl   $0x10b9bd,0x8(%esp)
  104504:	00 
  104505:	c7 44 24 04 63 00 00 	movl   $0x63,0x4(%esp)
  10450c:	00 
  10450d:	c7 04 24 d2 b9 10 00 	movl   $0x10b9d2,(%esp)
  104514:	e8 83 c2 ff ff       	call   10079c <debug_panic>
  c->recover = NULL;
  104519:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  10451c:	c7 80 a0 00 00 00 00 	movl   $0x0,0xa0(%eax)
  104523:	00 00 00 
	// Now do the copy, but recover from page faults.
}
  104526:	c9                   	leave  
  104527:	c3                   	ret    

00104528 <do_cputs>:

static void
do_cputs(trapframe *tf, uint32_t cmd)
{
  104528:	55                   	push   %ebp
  104529:	89 e5                	mov    %esp,%ebp
  10452b:	81 ec 28 01 00 00    	sub    $0x128,%esp
	// Print the string supplied by the user: pointer in EBX
char buf[CPUTS_MAX+1];
usercopy(tf,0,buf,tf->regs.ebx,CPUTS_MAX);
  104531:	8b 45 08             	mov    0x8(%ebp),%eax
  104534:	8b 40 10             	mov    0x10(%eax),%eax
  104537:	c7 44 24 10 00 01 00 	movl   $0x100,0x10(%esp)
  10453e:	00 
  10453f:	89 44 24 0c          	mov    %eax,0xc(%esp)
  104543:	8d 85 ff fe ff ff    	lea    0xfffffeff(%ebp),%eax
  104549:	89 44 24 08          	mov    %eax,0x8(%esp)
  10454d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  104554:	00 
  104555:	8b 45 08             	mov    0x8(%ebp),%eax
  104558:	89 04 24             	mov    %eax,(%esp)
  10455b:	e8 e6 fe ff ff       	call   104446 <usercopy>
buf[CPUTS_MAX] = 0;
  104560:	c6 45 ff 00          	movb   $0x0,0xffffffff(%ebp)
cprintf("%s",buf);
  104564:	8d 85 ff fe ff ff    	lea    0xfffffeff(%ebp),%eax
  10456a:	89 44 24 04          	mov    %eax,0x4(%esp)
  10456e:	c7 04 24 17 ba 10 00 	movl   $0x10ba17,(%esp)
  104575:	e8 2f 5d 00 00       	call   10a2a9 <cprintf>
	cprintf("%s", (char*)tf->regs.ebx);
  10457a:	8b 45 08             	mov    0x8(%ebp),%eax
  10457d:	8b 40 10             	mov    0x10(%eax),%eax
  104580:	89 44 24 04          	mov    %eax,0x4(%esp)
  104584:	c7 04 24 17 ba 10 00 	movl   $0x10ba17,(%esp)
  10458b:	e8 19 5d 00 00       	call   10a2a9 <cprintf>
	trap_return(tf);	// syscall completed
  104590:	8b 45 08             	mov    0x8(%ebp),%eax
  104593:	89 04 24             	mov    %eax,(%esp)
  104596:	e8 35 e4 ff ff       	call   1029d0 <trap_return>

0010459b <do_put>:
}
static void
do_put(trapframe *tf, uint32_t cmd)
{
  10459b:	55                   	push   %ebp
  10459c:	89 e5                	mov    %esp,%ebp
  10459e:	53                   	push   %ebx
  10459f:	83 ec 44             	sub    $0x44,%esp
  proc *p = proc_cur();
  1045a2:	e8 0a fe ff ff       	call   1043b1 <cpu_cur>
  1045a7:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  1045ad:	89 45 dc             	mov    %eax,0xffffffdc(%ebp)
  assert(p->state == PROC_RUN && p->runcpu == cpu_cur());
  1045b0:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  1045b3:	8b 80 3c 04 00 00    	mov    0x43c(%eax),%eax
  1045b9:	83 f8 02             	cmp    $0x2,%eax
  1045bc:	75 12                	jne    1045d0 <do_put+0x35>
  1045be:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  1045c1:	8b 98 44 04 00 00    	mov    0x444(%eax),%ebx
  1045c7:	e8 e5 fd ff ff       	call   1043b1 <cpu_cur>
  1045cc:	39 c3                	cmp    %eax,%ebx
  1045ce:	74 24                	je     1045f4 <do_put+0x59>
  1045d0:	c7 44 24 0c 1c ba 10 	movl   $0x10ba1c,0xc(%esp)
  1045d7:	00 
  1045d8:	c7 44 24 08 bd b9 10 	movl   $0x10b9bd,0x8(%esp)
  1045df:	00 
  1045e0:	c7 44 24 04 77 00 00 	movl   $0x77,0x4(%esp)
  1045e7:	00 
  1045e8:	c7 04 24 d2 b9 10 00 	movl   $0x10b9d2,(%esp)
  1045ef:	e8 a8 c1 ff ff       	call   10079c <debug_panic>
  cprintf("PUT proc %x eip %x esp %x cmd %x\n", p, tf->eip, tf->esp, cmd);
  1045f4:	8b 45 08             	mov    0x8(%ebp),%eax
  1045f7:	8b 50 44             	mov    0x44(%eax),%edx
  1045fa:	8b 45 08             	mov    0x8(%ebp),%eax
  1045fd:	8b 48 38             	mov    0x38(%eax),%ecx
  104600:	8b 45 0c             	mov    0xc(%ebp),%eax
  104603:	89 44 24 10          	mov    %eax,0x10(%esp)
  104607:	89 54 24 0c          	mov    %edx,0xc(%esp)
  10460b:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  10460f:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  104612:	89 44 24 04          	mov    %eax,0x4(%esp)
  104616:	c7 04 24 4c ba 10 00 	movl   $0x10ba4c,(%esp)
  10461d:	e8 87 5c 00 00       	call   10a2a9 <cprintf>

  spinlock_acquire(&p->lock);
  104622:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  104625:	89 04 24             	mov    %eax,(%esp)
  104628:	e8 fd e7 ff ff       	call   102e2a <spinlock_acquire>

  // Find the named child process; create if it doesn't exist
  uint32_t cn = tf->regs.edx & 0xff;
  10462d:	8b 45 08             	mov    0x8(%ebp),%eax
  104630:	8b 40 14             	mov    0x14(%eax),%eax
  104633:	25 ff 00 00 00       	and    $0xff,%eax
  104638:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)
  proc *cp = p->child[cn];
  10463b:	8b 55 e0             	mov    0xffffffe0(%ebp),%edx
  10463e:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  104641:	8b 44 90 3c          	mov    0x3c(%eax,%edx,4),%eax
  104645:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
  if (!cp) {
  104648:	83 7d e4 00          	cmpl   $0x0,0xffffffe4(%ebp)
  10464c:	75 37                	jne    104685 <do_put+0xea>
    cp = proc_alloc(p, cn);
  10464e:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  104651:	89 44 24 04          	mov    %eax,0x4(%esp)
  104655:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  104658:	89 04 24             	mov    %eax,(%esp)
  10465b:	e8 de ee ff ff       	call   10353e <proc_alloc>
  104660:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
    if (!cp)  // XX handle more gracefully
  104663:	83 7d e4 00          	cmpl   $0x0,0xffffffe4(%ebp)
  104667:	75 1c                	jne    104685 <do_put+0xea>
      panic("sys_put: no memory for child");
  104669:	c7 44 24 08 6e ba 10 	movl   $0x10ba6e,0x8(%esp)
  104670:	00 
  104671:	c7 44 24 04 82 00 00 	movl   $0x82,0x4(%esp)
  104678:	00 
  104679:	c7 04 24 d2 b9 10 00 	movl   $0x10b9d2,(%esp)
  104680:	e8 17 c1 ff ff       	call   10079c <debug_panic>
  }

  // Synchronize with child if necessary.
  if (cp->state != PROC_STOP)
  104685:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  104688:	8b 80 3c 04 00 00    	mov    0x43c(%eax),%eax
  10468e:	85 c0                	test   %eax,%eax
  104690:	74 19                	je     1046ab <do_put+0x110>
    proc_wait(p, cp, tf);
  104692:	8b 45 08             	mov    0x8(%ebp),%eax
  104695:	89 44 24 08          	mov    %eax,0x8(%esp)
  104699:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  10469c:	89 44 24 04          	mov    %eax,0x4(%esp)
  1046a0:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  1046a3:	89 04 24             	mov    %eax,(%esp)
  1046a6:	e8 b4 f1 ff ff       	call   10385f <proc_wait>

  // Since the child is now stopped, it's ours to control;
  // we no longer need our process lock -
  // and we don't want to be holding it if usercopy() below aborts.
  spinlock_release(&p->lock);
  1046ab:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  1046ae:	89 04 24             	mov    %eax,(%esp)
  1046b1:	e8 6f e8 ff ff       	call   102f25 <spinlock_release>

  // Put child's general register state
  if (cmd & SYS_REGS) {
  1046b6:	8b 45 0c             	mov    0xc(%ebp),%eax
  1046b9:	25 00 10 00 00       	and    $0x1000,%eax
  1046be:	85 c0                	test   %eax,%eax
  1046c0:	0f 84 d4 00 00 00    	je     10479a <do_put+0x1ff>
    int len = offsetof(procstate, fx);  // just integer regs
  1046c6:	c7 45 f4 50 00 00 00 	movl   $0x50,0xfffffff4(%ebp)
    if (cmd & SYS_FPU) len = sizeof(procstate); // whole shebang
  1046cd:	8b 45 0c             	mov    0xc(%ebp),%eax
  1046d0:	25 00 20 00 00       	and    $0x2000,%eax
  1046d5:	85 c0                	test   %eax,%eax
  1046d7:	74 07                	je     1046e0 <do_put+0x145>
  1046d9:	c7 45 f4 50 02 00 00 	movl   $0x250,0xfffffff4(%ebp)

  usercopy(tf,0,&cp->sv, tf->regs.ebx, len);
  1046e0:	8b 4d f4             	mov    0xfffffff4(%ebp),%ecx
  1046e3:	8b 45 08             	mov    0x8(%ebp),%eax
  1046e6:	8b 40 10             	mov    0x10(%eax),%eax
  1046e9:	8b 55 e4             	mov    0xffffffe4(%ebp),%edx
  1046ec:	81 c2 50 04 00 00    	add    $0x450,%edx
  1046f2:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  1046f6:	89 44 24 0c          	mov    %eax,0xc(%esp)
  1046fa:	89 54 24 08          	mov    %edx,0x8(%esp)
  1046fe:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  104705:	00 
  104706:	8b 45 08             	mov    0x8(%ebp),%eax
  104709:	89 04 24             	mov    %eax,(%esp)
  10470c:	e8 35 fd ff ff       	call   104446 <usercopy>
    // Copy user's trapframe into child process
    procstate *cs = (procstate*) tf->regs.ebx;
  104711:	8b 45 08             	mov    0x8(%ebp),%eax
  104714:	8b 40 10             	mov    0x10(%eax),%eax
  104717:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
    memcpy(&cp->sv, cs, len);
  10471a:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  10471d:	8b 55 e4             	mov    0xffffffe4(%ebp),%edx
  104720:	81 c2 50 04 00 00    	add    $0x450,%edx
  104726:	89 44 24 08          	mov    %eax,0x8(%esp)
  10472a:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10472d:	89 44 24 04          	mov    %eax,0x4(%esp)
  104731:	89 14 24             	mov    %edx,(%esp)
  104734:	e8 a7 5e 00 00       	call   10a5e0 <memcpy>

    // Make sure process uses user-mode segments and eflag settings
    cp->sv.tf.ds = CPU_GDT_UDATA | 3;
  104739:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  10473c:	66 c7 80 7c 04 00 00 	movw   $0x23,0x47c(%eax)
  104743:	23 00 
    cp->sv.tf.es = CPU_GDT_UDATA | 3;
  104745:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  104748:	66 c7 80 78 04 00 00 	movw   $0x23,0x478(%eax)
  10474f:	23 00 
    cp->sv.tf.cs = CPU_GDT_UCODE | 3;
  104751:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  104754:	66 c7 80 8c 04 00 00 	movw   $0x1b,0x48c(%eax)
  10475b:	1b 00 
    cp->sv.tf.ss = CPU_GDT_UDATA | 3;
  10475d:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  104760:	66 c7 80 98 04 00 00 	movw   $0x23,0x498(%eax)
  104767:	23 00 
    cp->sv.tf.eflags &= FL_USER;
  104769:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  10476c:	8b 80 90 04 00 00    	mov    0x490(%eax),%eax
  104772:	89 c2                	mov    %eax,%edx
  104774:	81 e2 d5 0c 00 00    	and    $0xcd5,%edx
  10477a:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  10477d:	89 90 90 04 00 00    	mov    %edx,0x490(%eax)
    cp->sv.tf.eflags |= FL_IF;  // enable interrupts
  104783:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  104786:	8b 80 90 04 00 00    	mov    0x490(%eax),%eax
  10478c:	89 c2                	mov    %eax,%edx
  10478e:	80 ce 02             	or     $0x2,%dh
  104791:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  104794:	89 90 90 04 00 00    	mov    %edx,0x490(%eax)
  }
	uint32_t sva = tf->regs.esi;
  10479a:	8b 45 08             	mov    0x8(%ebp),%eax
  10479d:	8b 40 04             	mov    0x4(%eax),%eax
  1047a0:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
	uint32_t dva = tf->regs.edi;
  1047a3:	8b 45 08             	mov    0x8(%ebp),%eax
  1047a6:	8b 00                	mov    (%eax),%eax
  1047a8:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
	uint32_t size = tf->regs.ecx;
  1047ab:	8b 45 08             	mov    0x8(%ebp),%eax
  1047ae:	8b 40 18             	mov    0x18(%eax),%eax
  1047b1:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
	switch (cmd & SYS_MEMOP) {
  1047b4:	8b 45 0c             	mov    0xc(%ebp),%eax
  1047b7:	25 00 00 03 00       	and    $0x30000,%eax
  1047bc:	89 45 d4             	mov    %eax,0xffffffd4(%ebp)
  1047bf:	81 7d d4 00 00 01 00 	cmpl   $0x10000,0xffffffd4(%ebp)
  1047c6:	74 6a                	je     104832 <do_put+0x297>
  1047c8:	81 7d d4 00 00 02 00 	cmpl   $0x20000,0xffffffd4(%ebp)
  1047cf:	74 0f                	je     1047e0 <do_put+0x245>
  1047d1:	83 7d d4 00          	cmpl   $0x0,0xffffffd4(%ebp)
  1047d5:	0f 84 39 01 00 00    	je     104914 <do_put+0x379>
  1047db:	e9 19 01 00 00       	jmp    1048f9 <do_put+0x35e>
	case 0:	// no memory operation
		break;
	case SYS_COPY:
		// validate source region
		if (PTOFF(sva) || PTOFF(size)
  1047e0:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  1047e3:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  1047e8:	85 c0                	test   %eax,%eax
  1047ea:	75 2b                	jne    104817 <do_put+0x27c>
  1047ec:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  1047ef:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  1047f4:	85 c0                	test   %eax,%eax
  1047f6:	75 1f                	jne    104817 <do_put+0x27c>
  1047f8:	81 7d e8 ff ff ff 3f 	cmpl   $0x3fffffff,0xffffffe8(%ebp)
  1047ff:	76 16                	jbe    104817 <do_put+0x27c>
  104801:	81 7d e8 00 00 00 f0 	cmpl   $0xf0000000,0xffffffe8(%ebp)
  104808:	77 0d                	ja     104817 <do_put+0x27c>
  10480a:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
  10480f:	2b 45 e8             	sub    0xffffffe8(%ebp),%eax
  104812:	3b 45 f0             	cmp    0xfffffff0(%ebp),%eax
  104815:	73 1b                	jae    104832 <do_put+0x297>
				|| sva < VM_USERLO || sva > VM_USERHI
				|| size > VM_USERHI-sva)
			systrap(tf, T_GPFLT, 0);
  104817:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  10481e:	00 
  10481f:	c7 44 24 04 0d 00 00 	movl   $0xd,0x4(%esp)
  104826:	00 
  104827:	8b 45 08             	mov    0x8(%ebp),%eax
  10482a:	89 04 24             	mov    %eax,(%esp)
  10482d:	e8 de fa ff ff       	call   104310 <systrap>
		// fall thru...
	case SYS_ZERO:
		// validate destination region
		if (PTOFF(dva) || PTOFF(size)
  104832:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  104835:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  10483a:	85 c0                	test   %eax,%eax
  10483c:	75 2b                	jne    104869 <do_put+0x2ce>
  10483e:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  104841:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  104846:	85 c0                	test   %eax,%eax
  104848:	75 1f                	jne    104869 <do_put+0x2ce>
  10484a:	81 7d ec ff ff ff 3f 	cmpl   $0x3fffffff,0xffffffec(%ebp)
  104851:	76 16                	jbe    104869 <do_put+0x2ce>
  104853:	81 7d ec 00 00 00 f0 	cmpl   $0xf0000000,0xffffffec(%ebp)
  10485a:	77 0d                	ja     104869 <do_put+0x2ce>
  10485c:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
  104861:	2b 45 ec             	sub    0xffffffec(%ebp),%eax
  104864:	3b 45 f0             	cmp    0xfffffff0(%ebp),%eax
  104867:	73 1b                	jae    104884 <do_put+0x2e9>
				|| dva < VM_USERLO || dva > VM_USERHI
				|| size > VM_USERHI-dva)
			systrap(tf, T_GPFLT, 0);
  104869:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  104870:	00 
  104871:	c7 44 24 04 0d 00 00 	movl   $0xd,0x4(%esp)
  104878:	00 
  104879:	8b 45 08             	mov    0x8(%ebp),%eax
  10487c:	89 04 24             	mov    %eax,(%esp)
  10487f:	e8 8c fa ff ff       	call   104310 <systrap>

		switch (cmd & SYS_MEMOP) {
  104884:	8b 45 0c             	mov    0xc(%ebp),%eax
  104887:	25 00 00 03 00       	and    $0x30000,%eax
  10488c:	89 45 d8             	mov    %eax,0xffffffd8(%ebp)
  10488f:	81 7d d8 00 00 01 00 	cmpl   $0x10000,0xffffffd8(%ebp)
  104896:	74 0b                	je     1048a3 <do_put+0x308>
  104898:	81 7d d8 00 00 02 00 	cmpl   $0x20000,0xffffffd8(%ebp)
  10489f:	74 23                	je     1048c4 <do_put+0x329>
  1048a1:	eb 71                	jmp    104914 <do_put+0x379>
		case SYS_ZERO:	// zero memory and clear permissions
			pmap_remove(cp->pdir, dva, size);
  1048a3:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  1048a6:	8b 90 a0 06 00 00    	mov    0x6a0(%eax),%edx
  1048ac:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  1048af:	89 44 24 08          	mov    %eax,0x8(%esp)
  1048b3:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  1048b6:	89 44 24 04          	mov    %eax,0x4(%esp)
  1048ba:	89 14 24             	mov    %edx,(%esp)
  1048bd:	e8 d3 12 00 00       	call   105b95 <pmap_remove>
			break;
  1048c2:	eb 50                	jmp    104914 <do_put+0x379>
		case SYS_COPY:	// copy from local src to dest in child
			pmap_copy(p->pdir, sva, cp->pdir, dva, size);
  1048c4:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  1048c7:	8b 90 a0 06 00 00    	mov    0x6a0(%eax),%edx
  1048cd:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  1048d0:	8b 88 a0 06 00 00    	mov    0x6a0(%eax),%ecx
  1048d6:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  1048d9:	89 44 24 10          	mov    %eax,0x10(%esp)
  1048dd:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  1048e0:	89 44 24 0c          	mov    %eax,0xc(%esp)
  1048e4:	89 54 24 08          	mov    %edx,0x8(%esp)
  1048e8:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  1048eb:	89 44 24 04          	mov    %eax,0x4(%esp)
  1048ef:	89 0c 24             	mov    %ecx,(%esp)
  1048f2:	e8 81 17 00 00       	call   106078 <pmap_copy>
			break;
		}
		break;
  1048f7:	eb 1b                	jmp    104914 <do_put+0x379>
	default:
		systrap(tf, T_GPFLT, 0);
  1048f9:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  104900:	00 
  104901:	c7 44 24 04 0d 00 00 	movl   $0xd,0x4(%esp)
  104908:	00 
  104909:	8b 45 08             	mov    0x8(%ebp),%eax
  10490c:	89 04 24             	mov    %eax,(%esp)
  10490f:	e8 fc f9 ff ff       	call   104310 <systrap>
	}

	if (cmd & SYS_PERM) {
  104914:	8b 45 0c             	mov    0xc(%ebp),%eax
  104917:	25 00 01 00 00       	and    $0x100,%eax
  10491c:	85 c0                	test   %eax,%eax
  10491e:	0f 84 a0 00 00 00    	je     1049c4 <do_put+0x429>
		// validate destination region
		if (PGOFF(dva) || PGOFF(size)
  104924:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  104927:	25 ff 0f 00 00       	and    $0xfff,%eax
  10492c:	85 c0                	test   %eax,%eax
  10492e:	75 2b                	jne    10495b <do_put+0x3c0>
  104930:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  104933:	25 ff 0f 00 00       	and    $0xfff,%eax
  104938:	85 c0                	test   %eax,%eax
  10493a:	75 1f                	jne    10495b <do_put+0x3c0>
  10493c:	81 7d ec ff ff ff 3f 	cmpl   $0x3fffffff,0xffffffec(%ebp)
  104943:	76 16                	jbe    10495b <do_put+0x3c0>
  104945:	81 7d ec 00 00 00 f0 	cmpl   $0xf0000000,0xffffffec(%ebp)
  10494c:	77 0d                	ja     10495b <do_put+0x3c0>
  10494e:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
  104953:	2b 45 ec             	sub    0xffffffec(%ebp),%eax
  104956:	3b 45 f0             	cmp    0xfffffff0(%ebp),%eax
  104959:	73 1b                	jae    104976 <do_put+0x3db>
				|| dva < VM_USERLO || dva > VM_USERHI
				|| size > VM_USERHI-dva)
			systrap(tf, T_GPFLT, 0);
  10495b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  104962:	00 
  104963:	c7 44 24 04 0d 00 00 	movl   $0xd,0x4(%esp)
  10496a:	00 
  10496b:	8b 45 08             	mov    0x8(%ebp),%eax
  10496e:	89 04 24             	mov    %eax,(%esp)
  104971:	e8 9a f9 ff ff       	call   104310 <systrap>
		if (!pmap_setperm(cp->pdir, dva, size, cmd & SYS_RW))
  104976:	8b 45 0c             	mov    0xc(%ebp),%eax
  104979:	89 c2                	mov    %eax,%edx
  10497b:	81 e2 00 06 00 00    	and    $0x600,%edx
  104981:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  104984:	8b 88 a0 06 00 00    	mov    0x6a0(%eax),%ecx
  10498a:	89 54 24 0c          	mov    %edx,0xc(%esp)
  10498e:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  104991:	89 44 24 08          	mov    %eax,0x8(%esp)
  104995:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  104998:	89 44 24 04          	mov    %eax,0x4(%esp)
  10499c:	89 0c 24             	mov    %ecx,(%esp)
  10499f:	e8 64 29 00 00       	call   107308 <pmap_setperm>
  1049a4:	85 c0                	test   %eax,%eax
  1049a6:	75 1c                	jne    1049c4 <do_put+0x429>
			panic("pmap_put: no memory to set permissions");
  1049a8:	c7 44 24 08 8c ba 10 	movl   $0x10ba8c,0x8(%esp)
  1049af:	00 
  1049b0:	c7 44 24 04 c8 00 00 	movl   $0xc8,0x4(%esp)
  1049b7:	00 
  1049b8:	c7 04 24 d2 b9 10 00 	movl   $0x10b9d2,(%esp)
  1049bf:	e8 d8 bd ff ff       	call   10079c <debug_panic>
	}

	if (cmd & SYS_SNAP)	// Snapshot child's state
  1049c4:	8b 45 0c             	mov    0xc(%ebp),%eax
  1049c7:	25 00 00 04 00       	and    $0x40000,%eax
  1049cc:	85 c0                	test   %eax,%eax
  1049ce:	74 36                	je     104a06 <do_put+0x46b>
		pmap_copy(cp->pdir, VM_USERLO, cp->rpdir, VM_USERLO,
  1049d0:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  1049d3:	8b 90 a4 06 00 00    	mov    0x6a4(%eax),%edx
  1049d9:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  1049dc:	8b 80 a0 06 00 00    	mov    0x6a0(%eax),%eax
  1049e2:	c7 44 24 10 00 00 00 	movl   $0xb0000000,0x10(%esp)
  1049e9:	b0 
  1049ea:	c7 44 24 0c 00 00 00 	movl   $0x40000000,0xc(%esp)
  1049f1:	40 
  1049f2:	89 54 24 08          	mov    %edx,0x8(%esp)
  1049f6:	c7 44 24 04 00 00 00 	movl   $0x40000000,0x4(%esp)
  1049fd:	40 
  1049fe:	89 04 24             	mov    %eax,(%esp)
  104a01:	e8 72 16 00 00       	call   106078 <pmap_copy>
				VM_USERHI-VM_USERLO);

  // Start the child if requested
  if (cmd & SYS_START)
  104a06:	8b 45 0c             	mov    0xc(%ebp),%eax
  104a09:	83 e0 10             	and    $0x10,%eax
  104a0c:	85 c0                	test   %eax,%eax
  104a0e:	74 0b                	je     104a1b <do_put+0x480>
    proc_ready(cp);
  104a10:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  104a13:	89 04 24             	mov    %eax,(%esp)
  104a16:	e8 6d ed ff ff       	call   103788 <proc_ready>

  trap_return(tf);  // syscall completed
  104a1b:	8b 45 08             	mov    0x8(%ebp),%eax
  104a1e:	89 04 24             	mov    %eax,(%esp)
  104a21:	e8 aa df ff ff       	call   1029d0 <trap_return>

00104a26 <do_get>:
}

  static void
do_get(trapframe *tf, uint32_t cmd)
{
  104a26:	55                   	push   %ebp
  104a27:	89 e5                	mov    %esp,%ebp
  104a29:	53                   	push   %ebx
  104a2a:	83 ec 44             	sub    $0x44,%esp
  proc *p = proc_cur();
  104a2d:	e8 7f f9 ff ff       	call   1043b1 <cpu_cur>
  104a32:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  104a38:	89 45 dc             	mov    %eax,0xffffffdc(%ebp)
  assert(p->state == PROC_RUN && p->runcpu == cpu_cur());
  104a3b:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  104a3e:	8b 80 3c 04 00 00    	mov    0x43c(%eax),%eax
  104a44:	83 f8 02             	cmp    $0x2,%eax
  104a47:	75 12                	jne    104a5b <do_get+0x35>
  104a49:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  104a4c:	8b 98 44 04 00 00    	mov    0x444(%eax),%ebx
  104a52:	e8 5a f9 ff ff       	call   1043b1 <cpu_cur>
  104a57:	39 c3                	cmp    %eax,%ebx
  104a59:	74 24                	je     104a7f <do_get+0x59>
  104a5b:	c7 44 24 0c 1c ba 10 	movl   $0x10ba1c,0xc(%esp)
  104a62:	00 
  104a63:	c7 44 24 08 bd b9 10 	movl   $0x10b9bd,0x8(%esp)
  104a6a:	00 
  104a6b:	c7 44 24 04 da 00 00 	movl   $0xda,0x4(%esp)
  104a72:	00 
  104a73:	c7 04 24 d2 b9 10 00 	movl   $0x10b9d2,(%esp)
  104a7a:	e8 1d bd ff ff       	call   10079c <debug_panic>
  //cprintf("GET proc %x eip %x esp %x cmd %x\n", p, tf->eip, tf->esp, cmd);

  spinlock_acquire(&p->lock);
  104a7f:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  104a82:	89 04 24             	mov    %eax,(%esp)
  104a85:	e8 a0 e3 ff ff       	call   102e2a <spinlock_acquire>

  // Find the named child process; DON'T create if it doesn't exist
  uint32_t cn = tf->regs.edx & 0xff;
  104a8a:	8b 45 08             	mov    0x8(%ebp),%eax
  104a8d:	8b 40 14             	mov    0x14(%eax),%eax
  104a90:	25 ff 00 00 00       	and    $0xff,%eax
  104a95:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)
  proc *cp = p->child[cn];
  104a98:	8b 55 e0             	mov    0xffffffe0(%ebp),%edx
  104a9b:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  104a9e:	8b 44 90 3c          	mov    0x3c(%eax,%edx,4),%eax
  104aa2:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
  if (!cp)
  104aa5:	83 7d e4 00          	cmpl   $0x0,0xffffffe4(%ebp)
  104aa9:	75 07                	jne    104ab2 <do_get+0x8c>
    cp = &proc_null;
  104aab:	c7 45 e4 c0 fd 11 00 	movl   $0x11fdc0,0xffffffe4(%ebp)

  // Synchronize with child if necessary.
  if (cp->state != PROC_STOP)
  104ab2:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  104ab5:	8b 80 3c 04 00 00    	mov    0x43c(%eax),%eax
  104abb:	85 c0                	test   %eax,%eax
  104abd:	74 19                	je     104ad8 <do_get+0xb2>
    proc_wait(p, cp, tf);
  104abf:	8b 45 08             	mov    0x8(%ebp),%eax
  104ac2:	89 44 24 08          	mov    %eax,0x8(%esp)
  104ac6:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  104ac9:	89 44 24 04          	mov    %eax,0x4(%esp)
  104acd:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  104ad0:	89 04 24             	mov    %eax,(%esp)
  104ad3:	e8 87 ed ff ff       	call   10385f <proc_wait>

  // Since the child is now stopped, it's ours to control;
  // we no longer need our process lock -
  // and we don't want to be holding it if usercopy() below aborts.
  spinlock_release(&p->lock);
  104ad8:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  104adb:	89 04 24             	mov    %eax,(%esp)
  104ade:	e8 42 e4 ff ff       	call   102f25 <spinlock_release>

  // Get child's general register state
  if (cmd & SYS_REGS) {
  104ae3:	8b 45 0c             	mov    0xc(%ebp),%eax
  104ae6:	25 00 10 00 00       	and    $0x1000,%eax
  104aeb:	85 c0                	test   %eax,%eax
  104aed:	74 73                	je     104b62 <do_get+0x13c>
    int len = offsetof(procstate, fx);  // just integer regs
  104aef:	c7 45 f4 50 00 00 00 	movl   $0x50,0xfffffff4(%ebp)
    if (cmd & SYS_FPU) len = sizeof(procstate); // whole shebang
  104af6:	8b 45 0c             	mov    0xc(%ebp),%eax
  104af9:	25 00 20 00 00       	and    $0x2000,%eax
  104afe:	85 c0                	test   %eax,%eax
  104b00:	74 07                	je     104b09 <do_get+0xe3>
  104b02:	c7 45 f4 50 02 00 00 	movl   $0x250,0xfffffff4(%ebp)
usercopy(tf, 1, &cp->sv, tf->regs.ebx, len);
  104b09:	8b 4d f4             	mov    0xfffffff4(%ebp),%ecx
  104b0c:	8b 45 08             	mov    0x8(%ebp),%eax
  104b0f:	8b 40 10             	mov    0x10(%eax),%eax
  104b12:	8b 55 e4             	mov    0xffffffe4(%ebp),%edx
  104b15:	81 c2 50 04 00 00    	add    $0x450,%edx
  104b1b:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  104b1f:	89 44 24 0c          	mov    %eax,0xc(%esp)
  104b23:	89 54 24 08          	mov    %edx,0x8(%esp)
  104b27:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  104b2e:	00 
  104b2f:	8b 45 08             	mov    0x8(%ebp),%eax
  104b32:	89 04 24             	mov    %eax,(%esp)
  104b35:	e8 0c f9 ff ff       	call   104446 <usercopy>
    // Copy child process's trapframe into user space
    procstate *cs = (procstate*) tf->regs.ebx;
  104b3a:	8b 45 08             	mov    0x8(%ebp),%eax
  104b3d:	8b 40 10             	mov    0x10(%eax),%eax
  104b40:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
    memcpy(cs, &cp->sv, len);
  104b43:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  104b46:	8b 55 e4             	mov    0xffffffe4(%ebp),%edx
  104b49:	81 c2 50 04 00 00    	add    $0x450,%edx
  104b4f:	89 44 24 08          	mov    %eax,0x8(%esp)
  104b53:	89 54 24 04          	mov    %edx,0x4(%esp)
  104b57:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  104b5a:	89 04 24             	mov    %eax,(%esp)
  104b5d:	e8 7e 5a 00 00       	call   10a5e0 <memcpy>
  }
uint32_t sva = tf->regs.esi;
  104b62:	8b 45 08             	mov    0x8(%ebp),%eax
  104b65:	8b 40 04             	mov    0x4(%eax),%eax
  104b68:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
	uint32_t dva = tf->regs.edi;
  104b6b:	8b 45 08             	mov    0x8(%ebp),%eax
  104b6e:	8b 00                	mov    (%eax),%eax
  104b70:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
	uint32_t size = tf->regs.ecx;
  104b73:	8b 45 08             	mov    0x8(%ebp),%eax
  104b76:	8b 40 18             	mov    0x18(%eax),%eax
  104b79:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
	switch (cmd & SYS_MEMOP) {
  104b7c:	8b 45 0c             	mov    0xc(%ebp),%eax
  104b7f:	25 00 00 03 00       	and    $0x30000,%eax
  104b84:	89 45 d4             	mov    %eax,0xffffffd4(%ebp)
  104b87:	81 7d d4 00 00 01 00 	cmpl   $0x10000,0xffffffd4(%ebp)
  104b8e:	0f 84 81 00 00 00    	je     104c15 <do_get+0x1ef>
  104b94:	81 7d d4 00 00 01 00 	cmpl   $0x10000,0xffffffd4(%ebp)
  104b9b:	77 0f                	ja     104bac <do_get+0x186>
  104b9d:	83 7d d4 00          	cmpl   $0x0,0xffffffd4(%ebp)
  104ba1:	0f 84 a1 01 00 00    	je     104d48 <do_get+0x322>
  104ba7:	e9 81 01 00 00       	jmp    104d2d <do_get+0x307>
  104bac:	81 7d d4 00 00 02 00 	cmpl   $0x20000,0xffffffd4(%ebp)
  104bb3:	74 0e                	je     104bc3 <do_get+0x19d>
  104bb5:	81 7d d4 00 00 03 00 	cmpl   $0x30000,0xffffffd4(%ebp)
  104bbc:	74 05                	je     104bc3 <do_get+0x19d>
  104bbe:	e9 6a 01 00 00       	jmp    104d2d <do_get+0x307>
	case 0:	// no memory operation
		break;
	case SYS_COPY:
	case SYS_MERGE:
		// validate source region
		if (PTOFF(sva) || PTOFF(size)
  104bc3:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  104bc6:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  104bcb:	85 c0                	test   %eax,%eax
  104bcd:	75 2b                	jne    104bfa <do_get+0x1d4>
  104bcf:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  104bd2:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  104bd7:	85 c0                	test   %eax,%eax
  104bd9:	75 1f                	jne    104bfa <do_get+0x1d4>
  104bdb:	81 7d e8 ff ff ff 3f 	cmpl   $0x3fffffff,0xffffffe8(%ebp)
  104be2:	76 16                	jbe    104bfa <do_get+0x1d4>
  104be4:	81 7d e8 00 00 00 f0 	cmpl   $0xf0000000,0xffffffe8(%ebp)
  104beb:	77 0d                	ja     104bfa <do_get+0x1d4>
  104bed:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
  104bf2:	2b 45 e8             	sub    0xffffffe8(%ebp),%eax
  104bf5:	3b 45 f0             	cmp    0xfffffff0(%ebp),%eax
  104bf8:	73 1b                	jae    104c15 <do_get+0x1ef>
				|| sva < VM_USERLO || sva > VM_USERHI
				|| size > VM_USERHI-sva)
			systrap(tf, T_GPFLT, 0);
  104bfa:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  104c01:	00 
  104c02:	c7 44 24 04 0d 00 00 	movl   $0xd,0x4(%esp)
  104c09:	00 
  104c0a:	8b 45 08             	mov    0x8(%ebp),%eax
  104c0d:	89 04 24             	mov    %eax,(%esp)
  104c10:	e8 fb f6 ff ff       	call   104310 <systrap>
		// fall thru...
	case SYS_ZERO:
		// validate destination region
		if (PTOFF(dva) || PTOFF(size)
  104c15:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  104c18:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  104c1d:	85 c0                	test   %eax,%eax
  104c1f:	75 2b                	jne    104c4c <do_get+0x226>
  104c21:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  104c24:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  104c29:	85 c0                	test   %eax,%eax
  104c2b:	75 1f                	jne    104c4c <do_get+0x226>
  104c2d:	81 7d ec ff ff ff 3f 	cmpl   $0x3fffffff,0xffffffec(%ebp)
  104c34:	76 16                	jbe    104c4c <do_get+0x226>
  104c36:	81 7d ec 00 00 00 f0 	cmpl   $0xf0000000,0xffffffec(%ebp)
  104c3d:	77 0d                	ja     104c4c <do_get+0x226>
  104c3f:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
  104c44:	2b 45 ec             	sub    0xffffffec(%ebp),%eax
  104c47:	3b 45 f0             	cmp    0xfffffff0(%ebp),%eax
  104c4a:	73 1b                	jae    104c67 <do_get+0x241>
				|| dva < VM_USERLO || dva > VM_USERHI
				|| size > VM_USERHI-dva)
			systrap(tf, T_GPFLT, 0);
  104c4c:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  104c53:	00 
  104c54:	c7 44 24 04 0d 00 00 	movl   $0xd,0x4(%esp)
  104c5b:	00 
  104c5c:	8b 45 08             	mov    0x8(%ebp),%eax
  104c5f:	89 04 24             	mov    %eax,(%esp)
  104c62:	e8 a9 f6 ff ff       	call   104310 <systrap>

		switch (cmd & SYS_MEMOP) {
  104c67:	8b 45 0c             	mov    0xc(%ebp),%eax
  104c6a:	25 00 00 03 00       	and    $0x30000,%eax
  104c6f:	89 45 d8             	mov    %eax,0xffffffd8(%ebp)
  104c72:	81 7d d8 00 00 02 00 	cmpl   $0x20000,0xffffffd8(%ebp)
  104c79:	74 3b                	je     104cb6 <do_get+0x290>
  104c7b:	81 7d d8 00 00 03 00 	cmpl   $0x30000,0xffffffd8(%ebp)
  104c82:	74 67                	je     104ceb <do_get+0x2c5>
  104c84:	81 7d d8 00 00 01 00 	cmpl   $0x10000,0xffffffd8(%ebp)
  104c8b:	74 05                	je     104c92 <do_get+0x26c>
  104c8d:	e9 b6 00 00 00       	jmp    104d48 <do_get+0x322>
		case SYS_ZERO:	// zero memory and clear permissions
			pmap_remove(p->pdir, dva, size);
  104c92:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  104c95:	8b 90 a0 06 00 00    	mov    0x6a0(%eax),%edx
  104c9b:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  104c9e:	89 44 24 08          	mov    %eax,0x8(%esp)
  104ca2:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  104ca5:	89 44 24 04          	mov    %eax,0x4(%esp)
  104ca9:	89 14 24             	mov    %edx,(%esp)
  104cac:	e8 e4 0e 00 00       	call   105b95 <pmap_remove>
			break;
  104cb1:	e9 92 00 00 00       	jmp    104d48 <do_get+0x322>
		case SYS_COPY:	// copy from local src to dest in child
			pmap_copy(cp->pdir, sva, p->pdir, dva, size);
  104cb6:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  104cb9:	8b 90 a0 06 00 00    	mov    0x6a0(%eax),%edx
  104cbf:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  104cc2:	8b 88 a0 06 00 00    	mov    0x6a0(%eax),%ecx
  104cc8:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  104ccb:	89 44 24 10          	mov    %eax,0x10(%esp)
  104ccf:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  104cd2:	89 44 24 0c          	mov    %eax,0xc(%esp)
  104cd6:	89 54 24 08          	mov    %edx,0x8(%esp)
  104cda:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  104cdd:	89 44 24 04          	mov    %eax,0x4(%esp)
  104ce1:	89 0c 24             	mov    %ecx,(%esp)
  104ce4:	e8 8f 13 00 00       	call   106078 <pmap_copy>
			break;
  104ce9:	eb 5d                	jmp    104d48 <do_get+0x322>
		case SYS_MERGE:	// merge from local src to dest in child
			pmap_merge(cp->rpdir, cp->pdir, sva,
  104ceb:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  104cee:	8b 90 a0 06 00 00    	mov    0x6a0(%eax),%edx
  104cf4:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  104cf7:	8b 88 a0 06 00 00    	mov    0x6a0(%eax),%ecx
  104cfd:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  104d00:	8b 98 a4 06 00 00    	mov    0x6a4(%eax),%ebx
  104d06:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  104d09:	89 44 24 14          	mov    %eax,0x14(%esp)
  104d0d:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  104d10:	89 44 24 10          	mov    %eax,0x10(%esp)
  104d14:	89 54 24 0c          	mov    %edx,0xc(%esp)
  104d18:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  104d1b:	89 44 24 08          	mov    %eax,0x8(%esp)
  104d1f:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  104d23:	89 1c 24             	mov    %ebx,(%esp)
  104d26:	e8 33 20 00 00       	call   106d5e <pmap_merge>
					p->pdir, dva, size);
			break;
		}
		break;
  104d2b:	eb 1b                	jmp    104d48 <do_get+0x322>
	default:
		systrap(tf, T_GPFLT, 0);
  104d2d:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  104d34:	00 
  104d35:	c7 44 24 04 0d 00 00 	movl   $0xd,0x4(%esp)
  104d3c:	00 
  104d3d:	8b 45 08             	mov    0x8(%ebp),%eax
  104d40:	89 04 24             	mov    %eax,(%esp)
  104d43:	e8 c8 f5 ff ff       	call   104310 <systrap>
	}

	if (cmd & SYS_PERM) {
  104d48:	8b 45 0c             	mov    0xc(%ebp),%eax
  104d4b:	25 00 01 00 00       	and    $0x100,%eax
  104d50:	85 c0                	test   %eax,%eax
  104d52:	0f 84 a0 00 00 00    	je     104df8 <do_get+0x3d2>
		// validate destination region
		if (PGOFF(dva) || PGOFF(size)
  104d58:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  104d5b:	25 ff 0f 00 00       	and    $0xfff,%eax
  104d60:	85 c0                	test   %eax,%eax
  104d62:	75 2b                	jne    104d8f <do_get+0x369>
  104d64:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  104d67:	25 ff 0f 00 00       	and    $0xfff,%eax
  104d6c:	85 c0                	test   %eax,%eax
  104d6e:	75 1f                	jne    104d8f <do_get+0x369>
  104d70:	81 7d ec ff ff ff 3f 	cmpl   $0x3fffffff,0xffffffec(%ebp)
  104d77:	76 16                	jbe    104d8f <do_get+0x369>
  104d79:	81 7d ec 00 00 00 f0 	cmpl   $0xf0000000,0xffffffec(%ebp)
  104d80:	77 0d                	ja     104d8f <do_get+0x369>
  104d82:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
  104d87:	2b 45 ec             	sub    0xffffffec(%ebp),%eax
  104d8a:	3b 45 f0             	cmp    0xfffffff0(%ebp),%eax
  104d8d:	73 1b                	jae    104daa <do_get+0x384>
				|| dva < VM_USERLO || dva > VM_USERHI
				|| size > VM_USERHI-dva)
			systrap(tf, T_GPFLT, 0);
  104d8f:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  104d96:	00 
  104d97:	c7 44 24 04 0d 00 00 	movl   $0xd,0x4(%esp)
  104d9e:	00 
  104d9f:	8b 45 08             	mov    0x8(%ebp),%eax
  104da2:	89 04 24             	mov    %eax,(%esp)
  104da5:	e8 66 f5 ff ff       	call   104310 <systrap>
		if (!pmap_setperm(p->pdir, dva, size, cmd & SYS_RW))
  104daa:	8b 45 0c             	mov    0xc(%ebp),%eax
  104dad:	89 c2                	mov    %eax,%edx
  104daf:	81 e2 00 06 00 00    	and    $0x600,%edx
  104db5:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  104db8:	8b 88 a0 06 00 00    	mov    0x6a0(%eax),%ecx
  104dbe:	89 54 24 0c          	mov    %edx,0xc(%esp)
  104dc2:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  104dc5:	89 44 24 08          	mov    %eax,0x8(%esp)
  104dc9:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  104dcc:	89 44 24 04          	mov    %eax,0x4(%esp)
  104dd0:	89 0c 24             	mov    %ecx,(%esp)
  104dd3:	e8 30 25 00 00       	call   107308 <pmap_setperm>
  104dd8:	85 c0                	test   %eax,%eax
  104dda:	75 1c                	jne    104df8 <do_get+0x3d2>
			panic("pmap_get: no memory to set permissions");
  104ddc:	c7 44 24 08 b4 ba 10 	movl   $0x10bab4,0x8(%esp)
  104de3:	00 
  104de4:	c7 44 24 04 24 01 00 	movl   $0x124,0x4(%esp)
  104deb:	00 
  104dec:	c7 04 24 d2 b9 10 00 	movl   $0x10b9d2,(%esp)
  104df3:	e8 a4 b9 ff ff       	call   10079c <debug_panic>
	}

	if (cmd & SYS_SNAP)
  104df8:	8b 45 0c             	mov    0xc(%ebp),%eax
  104dfb:	25 00 00 04 00       	and    $0x40000,%eax
  104e00:	85 c0                	test   %eax,%eax
  104e02:	74 1b                	je     104e1f <do_get+0x3f9>
		systrap(tf, T_GPFLT, 0);	// only valid for PUT
  104e04:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  104e0b:	00 
  104e0c:	c7 44 24 04 0d 00 00 	movl   $0xd,0x4(%esp)
  104e13:	00 
  104e14:	8b 45 08             	mov    0x8(%ebp),%eax
  104e17:	89 04 24             	mov    %eax,(%esp)
  104e1a:	e8 f1 f4 ff ff       	call   104310 <systrap>
  trap_return(tf);  // syscall completed
  104e1f:	8b 45 08             	mov    0x8(%ebp),%eax
  104e22:	89 04 24             	mov    %eax,(%esp)
  104e25:	e8 a6 db ff ff       	call   1029d0 <trap_return>

00104e2a <do_ret>:
}

  static void gcc_noreturn
do_ret(trapframe *tf)
{
  104e2a:	55                   	push   %ebp
  104e2b:	89 e5                	mov    %esp,%ebp
  104e2d:	83 ec 08             	sub    $0x8,%esp
  //cprintf("RET proc %x eip %x esp %x\n", proc_cur(), tf->eip, tf->esp);
  proc_ret(tf, 1);
  104e30:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  104e37:	00 
  104e38:	8b 45 08             	mov    0x8(%ebp),%eax
  104e3b:	89 04 24             	mov    %eax,(%esp)
  104e3e:	e8 02 ed ff ff       	call   103b45 <proc_ret>

00104e43 <syscall>:
}
// Common function to handle all system calls -
// decode the system call type and call an appropriate handler function.
// Be sure to handle undefined system calls appropriately.
void
syscall(trapframe *tf)
{
  104e43:	55                   	push   %ebp
  104e44:	89 e5                	mov    %esp,%ebp
  104e46:	83 ec 28             	sub    $0x28,%esp
	// EAX register holds system call command/flags
	uint32_t cmd = tf->regs.eax;
  104e49:	8b 45 08             	mov    0x8(%ebp),%eax
  104e4c:	8b 40 1c             	mov    0x1c(%eax),%eax
  104e4f:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	switch (cmd & SYS_TYPE) {
  104e52:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  104e55:	83 e0 0f             	and    $0xf,%eax
  104e58:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  104e5b:	83 7d ec 01          	cmpl   $0x1,0xffffffec(%ebp)
  104e5f:	74 28                	je     104e89 <syscall+0x46>
  104e61:	83 7d ec 01          	cmpl   $0x1,0xffffffec(%ebp)
  104e65:	72 0e                	jb     104e75 <syscall+0x32>
  104e67:	83 7d ec 02          	cmpl   $0x2,0xffffffec(%ebp)
  104e6b:	74 30                	je     104e9d <syscall+0x5a>
  104e6d:	83 7d ec 03          	cmpl   $0x3,0xffffffec(%ebp)
  104e71:	74 3e                	je     104eb1 <syscall+0x6e>
  104e73:	eb 47                	jmp    104ebc <syscall+0x79>
	case SYS_CPUTS:	return do_cputs(tf, cmd);
  104e75:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  104e78:	89 44 24 04          	mov    %eax,0x4(%esp)
  104e7c:	8b 45 08             	mov    0x8(%ebp),%eax
  104e7f:	89 04 24             	mov    %eax,(%esp)
  104e82:	e8 a1 f6 ff ff       	call   104528 <do_cputs>
  104e87:	eb 33                	jmp    104ebc <syscall+0x79>
	case SYS_PUT:	return do_put(tf, cmd);
  104e89:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  104e8c:	89 44 24 04          	mov    %eax,0x4(%esp)
  104e90:	8b 45 08             	mov    0x8(%ebp),%eax
  104e93:	89 04 24             	mov    %eax,(%esp)
  104e96:	e8 00 f7 ff ff       	call   10459b <do_put>
  104e9b:	eb 1f                	jmp    104ebc <syscall+0x79>
	case SYS_GET:	return do_get(tf, cmd);
  104e9d:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  104ea0:	89 44 24 04          	mov    %eax,0x4(%esp)
  104ea4:	8b 45 08             	mov    0x8(%ebp),%eax
  104ea7:	89 04 24             	mov    %eax,(%esp)
  104eaa:	e8 77 fb ff ff       	call   104a26 <do_get>
  104eaf:	eb 0b                	jmp    104ebc <syscall+0x79>
	case SYS_RET:	return do_ret(tf);
  104eb1:	8b 45 08             	mov    0x8(%ebp),%eax
  104eb4:	89 04 24             	mov    %eax,(%esp)
  104eb7:	e8 6e ff ff ff       	call   104e2a <do_ret>
	// Your implementations of SYS_PUT, SYS_GET, SYS_RET here...
	default:	return;		// handle as a regular trap
	}
}
  104ebc:	c9                   	leave  
  104ebd:	c3                   	ret    
  104ebe:	90                   	nop    
  104ebf:	90                   	nop    

00104ec0 <pmap_init>:
// The user part of the address space remains all PTE_ZERO until later.
//
void
pmap_init(void)
{
  104ec0:	55                   	push   %ebp
  104ec1:	89 e5                	mov    %esp,%ebp
  104ec3:	83 ec 28             	sub    $0x28,%esp
	if (cpu_onboot()) {
  104ec6:	e8 bc 00 00 00       	call   104f87 <cpu_onboot>
  104ecb:	85 c0                	test   %eax,%eax
  104ecd:	74 51                	je     104f20 <pmap_init+0x60>
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
  104ecf:	c7 45 e8 00 00 00 00 	movl   $0x0,0xffffffe8(%ebp)
  104ed6:	eb 19                	jmp    104ef1 <pmap_init+0x31>
    pmap_bootpdir[i] = (i << PDXSHIFT)
  104ed8:	8b 55 e8             	mov    0xffffffe8(%ebp),%edx
  104edb:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  104ede:	c1 e0 16             	shl    $0x16,%eax
  104ee1:	0d 83 01 00 00       	or     $0x183,%eax
  104ee6:	89 04 95 00 10 12 00 	mov    %eax,0x121000(,%edx,4)
  104eed:	83 45 e8 01          	addl   $0x1,0xffffffe8(%ebp)
  104ef1:	81 7d e8 ff 03 00 00 	cmpl   $0x3ff,0xffffffe8(%ebp)
  104ef8:	7e de                	jle    104ed8 <pmap_init+0x18>
      | PTE_P | PTE_W | PTE_PS | PTE_G;
    for (i = PDX(VM_USERLO); i < PDX(VM_USERHI); i++)
  104efa:	c7 45 e8 00 01 00 00 	movl   $0x100,0xffffffe8(%ebp)
  104f01:	eb 13                	jmp    104f16 <pmap_init+0x56>
    pmap_bootpdir[i] = PTE_ZERO;
  104f03:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  104f06:	ba 00 20 12 00       	mov    $0x122000,%edx
  104f0b:	89 14 85 00 10 12 00 	mov    %edx,0x121000(,%eax,4)
  104f12:	83 45 e8 01          	addl   $0x1,0xffffffe8(%ebp)
  104f16:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  104f19:	3d bf 03 00 00       	cmp    $0x3bf,%eax
  104f1e:	76 e3                	jbe    104f03 <pmap_init+0x43>
static gcc_inline uint32_t
rcr4(void)
{
	uint32_t cr4;
	__asm __volatile("movl %%cr4,%0" : "=r" (cr4));
  104f20:	0f 20 e0             	mov    %cr4,%eax
  104f23:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
	return cr4;
  104f26:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
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
  104f29:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)
	cr4 |= CR4_PSE | CR4_PGE;
  104f2c:	81 4d e0 90 00 00 00 	orl    $0x90,0xffffffe0(%ebp)
  cr4 |= CR4_OSFXSR | CR4_OSXMMEXCPT;
  104f33:	81 4d e0 00 06 00 00 	orl    $0x600,0xffffffe0(%ebp)
  104f3a:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  104f3d:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)

static gcc_inline void
lcr4(uint32_t val)
{
	__asm __volatile("movl %0,%%cr4" : : "r" (val));
  104f40:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  104f43:	0f 22 e0             	mov    %eax,%cr4
	lcr4(cr4);

	// Install the bootstrap page directory into the PDBR.
	lcr3(mem_phys(pmap_bootpdir));
  104f46:	b8 00 10 12 00       	mov    $0x121000,%eax
  104f4b:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)

static gcc_inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
  104f4e:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  104f51:	0f 22 d8             	mov    %eax,%cr3
  104f54:	0f 20 c0             	mov    %cr0,%eax
  104f57:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  104f5a:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax

	// Turn on paging.
	uint32_t cr0 = rcr0();
  104f5d:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_TS|CR0_MP|CR0_TS;
  104f60:	81 4d e4 2b 00 05 80 	orl    $0x8005002b,0xffffffe4(%ebp)
	cr0 &= ~(CR0_EM);
  104f67:	83 65 e4 fb          	andl   $0xfffffffb,0xffffffe4(%ebp)
  104f6b:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  104f6e:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)

static gcc_inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
  104f71:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  104f74:	0f 22 c0             	mov    %eax,%cr0
	lcr0(cr0);

	// If we survived the lcr0, we're running with paging enabled.
	// Now check the page table management functions below.
	if (cpu_onboot())
  104f77:	e8 0b 00 00 00       	call   104f87 <cpu_onboot>
  104f7c:	85 c0                	test   %eax,%eax
  104f7e:	74 05                	je     104f85 <pmap_init+0xc5>
		pmap_check();
  104f80:	e8 1c 26 00 00       	call   1075a1 <pmap_check>
}
  104f85:	c9                   	leave  
  104f86:	c3                   	ret    

00104f87 <cpu_onboot>:
}

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  104f87:	55                   	push   %ebp
  104f88:	89 e5                	mov    %esp,%ebp
  104f8a:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  104f8d:	e8 0d 00 00 00       	call   104f9f <cpu_cur>
  104f92:	3d 00 d0 10 00       	cmp    $0x10d000,%eax
  104f97:	0f 94 c0             	sete   %al
  104f9a:	0f b6 c0             	movzbl %al,%eax
}
  104f9d:	c9                   	leave  
  104f9e:	c3                   	ret    

00104f9f <cpu_cur>:
  104f9f:	55                   	push   %ebp
  104fa0:	89 e5                	mov    %esp,%ebp
  104fa2:	83 ec 28             	sub    $0x28,%esp
static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  104fa5:	89 65 fc             	mov    %esp,0xfffffffc(%ebp)
        return esp;
  104fa8:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  104fab:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  104fae:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  104fb1:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  104fb6:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	assert(c->magic == CPU_MAGIC);
  104fb9:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  104fbc:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  104fc2:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  104fc7:	74 24                	je     104fed <cpu_cur+0x4e>
  104fc9:	c7 44 24 0c dc ba 10 	movl   $0x10badc,0xc(%esp)
  104fd0:	00 
  104fd1:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  104fd8:	00 
  104fd9:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  104fe0:	00 
  104fe1:	c7 04 24 07 bb 10 00 	movl   $0x10bb07,(%esp)
  104fe8:	e8 af b7 ff ff       	call   10079c <debug_panic>
	return c;
  104fed:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
}
  104ff0:	c9                   	leave  
  104ff1:	c3                   	ret    

00104ff2 <pmap_newpdir>:

//
// Allocate a new page directory, initialized from the bootstrap pdir.
// Returns the new pdir with a reference count of 1.
//
pte_t *
pmap_newpdir(void)
{
  104ff2:	55                   	push   %ebp
  104ff3:	89 e5                	mov    %esp,%ebp
  104ff5:	83 ec 28             	sub    $0x28,%esp
	pageinfo *pi = mem_alloc();
  104ff8:	e8 82 be ff ff       	call   100e7f <mem_alloc>
  104ffd:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	if (pi == NULL)
  105000:	83 7d f4 00          	cmpl   $0x0,0xfffffff4(%ebp)
  105004:	75 0c                	jne    105012 <pmap_newpdir+0x20>
		return NULL;
  105006:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  10500d:	e9 2f 01 00 00       	jmp    105141 <pmap_newpdir+0x14f>
  105012:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  105015:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
// Atomically increment the reference count on a page.
static gcc_inline void
mem_incref(pageinfo *pi)
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  105018:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  10501d:	83 c0 08             	add    $0x8,%eax
  105020:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  105023:	73 17                	jae    10503c <pmap_newpdir+0x4a>
  105025:	a1 44 fd 11 00       	mov    0x11fd44,%eax
  10502a:	c1 e0 03             	shl    $0x3,%eax
  10502d:	89 c2                	mov    %eax,%edx
  10502f:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  105034:	8d 04 02             	lea    (%edx,%eax,1),%eax
  105037:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  10503a:	77 24                	ja     105060 <pmap_newpdir+0x6e>
  10503c:	c7 44 24 0c 14 bb 10 	movl   $0x10bb14,0xc(%esp)
  105043:	00 
  105044:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  10504b:	00 
  10504c:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
  105053:	00 
  105054:	c7 04 24 4b bb 10 00 	movl   $0x10bb4b,(%esp)
  10505b:	e8 3c b7 ff ff       	call   10079c <debug_panic>
	assert(pi != mem_ptr2pi(pmap_zero));	// Don't alloc/free zero page!
  105060:	8b 15 9c fd 11 00    	mov    0x11fd9c,%edx
  105066:	b8 00 20 12 00       	mov    $0x122000,%eax
  10506b:	c1 e8 0c             	shr    $0xc,%eax
  10506e:	c1 e0 03             	shl    $0x3,%eax
  105071:	8d 04 02             	lea    (%edx,%eax,1),%eax
  105074:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  105077:	75 24                	jne    10509d <pmap_newpdir+0xab>
  105079:	c7 44 24 0c 58 bb 10 	movl   $0x10bb58,0xc(%esp)
  105080:	00 
  105081:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  105088:	00 
  105089:	c7 44 24 04 59 00 00 	movl   $0x59,0x4(%esp)
  105090:	00 
  105091:	c7 04 24 4b bb 10 00 	movl   $0x10bb4b,(%esp)
  105098:	e8 ff b6 ff ff       	call   10079c <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  10509d:	8b 15 9c fd 11 00    	mov    0x11fd9c,%edx
  1050a3:	b8 0c 00 10 00       	mov    $0x10000c,%eax
  1050a8:	c1 e8 0c             	shr    $0xc,%eax
  1050ab:	c1 e0 03             	shl    $0x3,%eax
  1050ae:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1050b1:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  1050b4:	77 40                	ja     1050f6 <pmap_newpdir+0x104>
  1050b6:	8b 15 9c fd 11 00    	mov    0x11fd9c,%edx
  1050bc:	b8 08 30 12 00       	mov    $0x123008,%eax
  1050c1:	83 e8 01             	sub    $0x1,%eax
  1050c4:	c1 e8 0c             	shr    $0xc,%eax
  1050c7:	c1 e0 03             	shl    $0x3,%eax
  1050ca:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1050cd:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  1050d0:	72 24                	jb     1050f6 <pmap_newpdir+0x104>
  1050d2:	c7 44 24 0c 74 bb 10 	movl   $0x10bb74,0xc(%esp)
  1050d9:	00 
  1050da:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  1050e1:	00 
  1050e2:	c7 44 24 04 5a 00 00 	movl   $0x5a,0x4(%esp)
  1050e9:	00 
  1050ea:	c7 04 24 4b bb 10 00 	movl   $0x10bb4b,(%esp)
  1050f1:	e8 a6 b6 ff ff       	call   10079c <debug_panic>

	lockadd(&pi->refcount, 1);
  1050f6:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  1050f9:	83 c0 04             	add    $0x4,%eax
  1050fc:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  105103:	00 
  105104:	89 04 24             	mov    %eax,(%esp)
  105107:	e8 3a 00 00 00       	call   105146 <lockadd>
	mem_incref(pi);
	pte_t *pdir = mem_pi2ptr(pi);
  10510c:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  10510f:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  105114:	89 d1                	mov    %edx,%ecx
  105116:	29 c1                	sub    %eax,%ecx
  105118:	89 c8                	mov    %ecx,%eax
  10511a:	c1 e0 09             	shl    $0x9,%eax
  10511d:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)

	// Initialize it from the bootstrap page directory
	assert(sizeof(pmap_bootpdir) == PAGESIZE);
	memmove(pdir, pmap_bootpdir, PAGESIZE);
  105120:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  105127:	00 
  105128:	c7 44 24 04 00 10 12 	movl   $0x121000,0x4(%esp)
  10512f:	00 
  105130:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  105133:	89 04 24             	mov    %eax,(%esp)
  105136:	e8 df 53 00 00       	call   10a51a <memmove>

	return pdir;
  10513b:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10513e:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  105141:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
}
  105144:	c9                   	leave  
  105145:	c3                   	ret    

00105146 <lockadd>:

// Atomically add incr to *addr.
static inline void
lockadd(volatile int32_t *addr, int32_t incr)
{
  105146:	55                   	push   %ebp
  105147:	89 e5                	mov    %esp,%ebp
	asm volatile("lock; addl %1,%0" : "+m" (*addr) : "r" (incr) : "cc");
  105149:	8b 4d 08             	mov    0x8(%ebp),%ecx
  10514c:	8b 55 0c             	mov    0xc(%ebp),%edx
  10514f:	8b 45 08             	mov    0x8(%ebp),%eax
  105152:	f0 01 11             	lock add %edx,(%ecx)
}
  105155:	5d                   	pop    %ebp
  105156:	c3                   	ret    

00105157 <pmap_freepdir>:

// Free a page directory, and all page tables and mappings it may contain.
void
pmap_freepdir(pageinfo *pdirpi)
{
  105157:	55                   	push   %ebp
  105158:	89 e5                	mov    %esp,%ebp
  10515a:	83 ec 18             	sub    $0x18,%esp
	pmap_remove(mem_pi2ptr(pdirpi), VM_USERLO, VM_USERHI-VM_USERLO);
  10515d:	8b 55 08             	mov    0x8(%ebp),%edx
  105160:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  105165:	89 d1                	mov    %edx,%ecx
  105167:	29 c1                	sub    %eax,%ecx
  105169:	89 c8                	mov    %ecx,%eax
  10516b:	c1 e0 09             	shl    $0x9,%eax
  10516e:	c7 44 24 08 00 00 00 	movl   $0xb0000000,0x8(%esp)
  105175:	b0 
  105176:	c7 44 24 04 00 00 00 	movl   $0x40000000,0x4(%esp)
  10517d:	40 
  10517e:	89 04 24             	mov    %eax,(%esp)
  105181:	e8 0f 0a 00 00       	call   105b95 <pmap_remove>
	mem_free(pdirpi);
  105186:	8b 45 08             	mov    0x8(%ebp),%eax
  105189:	89 04 24             	mov    %eax,(%esp)
  10518c:	e8 32 bd ff ff       	call   100ec3 <mem_free>
}
  105191:	c9                   	leave  
  105192:	c3                   	ret    

00105193 <pmap_freeptab>:

// Free a page table and all page mappings it may contain.
void
pmap_freeptab(pageinfo *ptabpi)
{
  105193:	55                   	push   %ebp
  105194:	89 e5                	mov    %esp,%ebp
  105196:	83 ec 38             	sub    $0x38,%esp
	pte_t *pte = mem_pi2ptr(ptabpi), *ptelim = pte + NPTENTRIES;
  105199:	8b 55 08             	mov    0x8(%ebp),%edx
  10519c:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  1051a1:	89 d1                	mov    %edx,%ecx
  1051a3:	29 c1                	sub    %eax,%ecx
  1051a5:	89 c8                	mov    %ecx,%eax
  1051a7:	c1 e0 09             	shl    $0x9,%eax
  1051aa:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  1051ad:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  1051b0:	05 00 10 00 00       	add    $0x1000,%eax
  1051b5:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
	for (; pte < ptelim; pte++) {
  1051b8:	e9 6d 01 00 00       	jmp    10532a <pmap_freeptab+0x197>
		uint32_t pgaddr = PGADDR(*pte);
  1051bd:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  1051c0:	8b 00                	mov    (%eax),%eax
  1051c2:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1051c7:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
		if (pgaddr != PTE_ZERO)
  1051ca:	b8 00 20 12 00       	mov    $0x122000,%eax
  1051cf:	39 45 f4             	cmp    %eax,0xfffffff4(%ebp)
  1051d2:	0f 84 4e 01 00 00    	je     105326 <pmap_freeptab+0x193>
			mem_decref(mem_phys2pi(pgaddr), mem_free);
  1051d8:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  1051db:	c1 e8 0c             	shr    $0xc,%eax
  1051de:	c1 e0 03             	shl    $0x3,%eax
  1051e1:	89 c2                	mov    %eax,%edx
  1051e3:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  1051e8:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1051eb:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  1051ee:	c7 45 f8 c3 0e 10 00 	movl   $0x100ec3,0xfffffff8(%ebp)
// freeing the page with the provided function if there are no more refs.
static gcc_inline void
mem_decref(pageinfo* pi, void (*freefun)(pageinfo *pi))
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  1051f5:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  1051fa:	83 c0 08             	add    $0x8,%eax
  1051fd:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  105200:	73 17                	jae    105219 <pmap_freeptab+0x86>
  105202:	a1 44 fd 11 00       	mov    0x11fd44,%eax
  105207:	c1 e0 03             	shl    $0x3,%eax
  10520a:	89 c2                	mov    %eax,%edx
  10520c:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  105211:	8d 04 02             	lea    (%edx,%eax,1),%eax
  105214:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  105217:	77 24                	ja     10523d <pmap_freeptab+0xaa>
  105219:	c7 44 24 0c 14 bb 10 	movl   $0x10bb14,0xc(%esp)
  105220:	00 
  105221:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  105228:	00 
  105229:	c7 44 24 04 64 00 00 	movl   $0x64,0x4(%esp)
  105230:	00 
  105231:	c7 04 24 4b bb 10 00 	movl   $0x10bb4b,(%esp)
  105238:	e8 5f b5 ff ff       	call   10079c <debug_panic>
	assert(pi != mem_ptr2pi(pmap_zero));	// Don't alloc/free zero page!
  10523d:	8b 15 9c fd 11 00    	mov    0x11fd9c,%edx
  105243:	b8 00 20 12 00       	mov    $0x122000,%eax
  105248:	c1 e8 0c             	shr    $0xc,%eax
  10524b:	c1 e0 03             	shl    $0x3,%eax
  10524e:	8d 04 02             	lea    (%edx,%eax,1),%eax
  105251:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  105254:	75 24                	jne    10527a <pmap_freeptab+0xe7>
  105256:	c7 44 24 0c 58 bb 10 	movl   $0x10bb58,0xc(%esp)
  10525d:	00 
  10525e:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  105265:	00 
  105266:	c7 44 24 04 65 00 00 	movl   $0x65,0x4(%esp)
  10526d:	00 
  10526e:	c7 04 24 4b bb 10 00 	movl   $0x10bb4b,(%esp)
  105275:	e8 22 b5 ff ff       	call   10079c <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  10527a:	8b 15 9c fd 11 00    	mov    0x11fd9c,%edx
  105280:	b8 0c 00 10 00       	mov    $0x10000c,%eax
  105285:	c1 e8 0c             	shr    $0xc,%eax
  105288:	c1 e0 03             	shl    $0x3,%eax
  10528b:	8d 04 02             	lea    (%edx,%eax,1),%eax
  10528e:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  105291:	77 40                	ja     1052d3 <pmap_freeptab+0x140>
  105293:	8b 15 9c fd 11 00    	mov    0x11fd9c,%edx
  105299:	b8 08 30 12 00       	mov    $0x123008,%eax
  10529e:	83 e8 01             	sub    $0x1,%eax
  1052a1:	c1 e8 0c             	shr    $0xc,%eax
  1052a4:	c1 e0 03             	shl    $0x3,%eax
  1052a7:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1052aa:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  1052ad:	72 24                	jb     1052d3 <pmap_freeptab+0x140>
  1052af:	c7 44 24 0c 74 bb 10 	movl   $0x10bb74,0xc(%esp)
  1052b6:	00 
  1052b7:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  1052be:	00 
  1052bf:	c7 44 24 04 66 00 00 	movl   $0x66,0x4(%esp)
  1052c6:	00 
  1052c7:	c7 04 24 4b bb 10 00 	movl   $0x10bb4b,(%esp)
  1052ce:	e8 c9 b4 ff ff       	call   10079c <debug_panic>

	if (lockaddz(&pi->refcount, -1))
  1052d3:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  1052d6:	83 c0 04             	add    $0x4,%eax
  1052d9:	c7 44 24 04 ff ff ff 	movl   $0xffffffff,0x4(%esp)
  1052e0:	ff 
  1052e1:	89 04 24             	mov    %eax,(%esp)
  1052e4:	e8 5a 00 00 00       	call   105343 <lockaddz>
  1052e9:	84 c0                	test   %al,%al
  1052eb:	74 0b                	je     1052f8 <pmap_freeptab+0x165>
			freefun(pi);
  1052ed:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  1052f0:	89 04 24             	mov    %eax,(%esp)
  1052f3:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1052f6:	ff d0                	call   *%eax
	assert(pi->refcount >= 0);
  1052f8:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  1052fb:	8b 40 04             	mov    0x4(%eax),%eax
  1052fe:	85 c0                	test   %eax,%eax
  105300:	79 24                	jns    105326 <pmap_freeptab+0x193>
  105302:	c7 44 24 0c a5 bb 10 	movl   $0x10bba5,0xc(%esp)
  105309:	00 
  10530a:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  105311:	00 
  105312:	c7 44 24 04 6a 00 00 	movl   $0x6a,0x4(%esp)
  105319:	00 
  10531a:	c7 04 24 4b bb 10 00 	movl   $0x10bb4b,(%esp)
  105321:	e8 76 b4 ff ff       	call   10079c <debug_panic>
  105326:	83 45 ec 04          	addl   $0x4,0xffffffec(%ebp)
  10532a:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  10532d:	3b 45 f0             	cmp    0xfffffff0(%ebp),%eax
  105330:	0f 82 87 fe ff ff    	jb     1051bd <pmap_freeptab+0x2a>
	}
	mem_free(ptabpi);
  105336:	8b 45 08             	mov    0x8(%ebp),%eax
  105339:	89 04 24             	mov    %eax,(%esp)
  10533c:	e8 82 bb ff ff       	call   100ec3 <mem_free>
}
  105341:	c9                   	leave  
  105342:	c3                   	ret    

00105343 <lockaddz>:

// Atomically add incr to *addr and return true if the result is zero.
static inline uint8_t
lockaddz(volatile int32_t *addr, int32_t incr)
{
  105343:	55                   	push   %ebp
  105344:	89 e5                	mov    %esp,%ebp
  105346:	83 ec 10             	sub    $0x10,%esp
	uint8_t zero;
	asm volatile("lock; addl %2,%0; setzb %1"
  105349:	8b 4d 08             	mov    0x8(%ebp),%ecx
  10534c:	8b 55 0c             	mov    0xc(%ebp),%edx
  10534f:	8b 45 08             	mov    0x8(%ebp),%eax
  105352:	f0 01 11             	lock add %edx,(%ecx)
  105355:	0f 94 45 ff          	sete   0xffffffff(%ebp)
		: "+m" (*addr), "=rm" (zero)
		: "r" (incr)
		: "cc");
	return zero;
  105359:	0f b6 45 ff          	movzbl 0xffffffff(%ebp),%eax
}
  10535d:	c9                   	leave  
  10535e:	c3                   	ret    

0010535f <pmap_walk>:

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
  10535f:	55                   	push   %ebp
  105360:	89 e5                	mov    %esp,%ebp
  105362:	83 ec 58             	sub    $0x58,%esp
	assert(va >= VM_USERLO && va < VM_USERHI);
  105365:	81 7d 0c ff ff ff 3f 	cmpl   $0x3fffffff,0xc(%ebp)
  10536c:	76 09                	jbe    105377 <pmap_walk+0x18>
  10536e:	81 7d 0c ff ff ff ef 	cmpl   $0xefffffff,0xc(%ebp)
  105375:	76 24                	jbe    10539b <pmap_walk+0x3c>
  105377:	c7 44 24 0c b8 bb 10 	movl   $0x10bbb8,0xc(%esp)
  10537e:	00 
  10537f:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  105386:	00 
  105387:	c7 44 24 04 a9 00 00 	movl   $0xa9,0x4(%esp)
  10538e:	00 
  10538f:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  105396:	e8 01 b4 ff ff       	call   10079c <debug_panic>

  uint32_t la = va;
  10539b:	8b 45 0c             	mov    0xc(%ebp),%eax
  10539e:	89 45 c4             	mov    %eax,0xffffffc4(%ebp)
  pde_t *pde = &pdir[PDX(la)];
  1053a1:	8b 45 c4             	mov    0xffffffc4(%ebp),%eax
  1053a4:	c1 e8 16             	shr    $0x16,%eax
  1053a7:	25 ff 03 00 00       	and    $0x3ff,%eax
  1053ac:	c1 e0 02             	shl    $0x2,%eax
  1053af:	03 45 08             	add    0x8(%ebp),%eax
  1053b2:	89 45 c8             	mov    %eax,0xffffffc8(%ebp)
  pte_t *ptab;
  if (*pde & PTE_P){
  1053b5:	8b 45 c8             	mov    0xffffffc8(%ebp),%eax
  1053b8:	8b 00                	mov    (%eax),%eax
  1053ba:	83 e0 01             	and    $0x1,%eax
  1053bd:	84 c0                	test   %al,%al
  1053bf:	74 12                	je     1053d3 <pmap_walk+0x74>
  ptab = mem_ptr(PGADDR(*pde));
  1053c1:	8b 45 c8             	mov    0xffffffc8(%ebp),%eax
  1053c4:	8b 00                	mov    (%eax),%eax
  1053c6:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1053cb:	89 45 cc             	mov    %eax,0xffffffcc(%ebp)
  1053ce:	e9 a3 01 00 00       	jmp    105576 <pmap_walk+0x217>
  } else {
  assert(*pde == PTE_ZERO);
  1053d3:	8b 45 c8             	mov    0xffffffc8(%ebp),%eax
  1053d6:	8b 10                	mov    (%eax),%edx
  1053d8:	b8 00 20 12 00       	mov    $0x122000,%eax
  1053dd:	39 c2                	cmp    %eax,%edx
  1053df:	74 24                	je     105405 <pmap_walk+0xa6>
  1053e1:	c7 44 24 0c e6 bb 10 	movl   $0x10bbe6,0xc(%esp)
  1053e8:	00 
  1053e9:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  1053f0:	00 
  1053f1:	c7 44 24 04 b1 00 00 	movl   $0xb1,0x4(%esp)
  1053f8:	00 
  1053f9:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  105400:	e8 97 b3 ff ff       	call   10079c <debug_panic>
  pageinfo *pi;
  if (!writing || (pi = mem_alloc()) == NULL)
  105405:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  105409:	74 0e                	je     105419 <pmap_walk+0xba>
  10540b:	e8 6f ba ff ff       	call   100e7f <mem_alloc>
  105410:	89 45 d0             	mov    %eax,0xffffffd0(%ebp)
  105413:	83 7d d0 00          	cmpl   $0x0,0xffffffd0(%ebp)
  105417:	75 0c                	jne    105425 <pmap_walk+0xc6>
  return NULL;
  105419:	c7 45 bc 00 00 00 00 	movl   $0x0,0xffffffbc(%ebp)
  105420:	e9 ed 05 00 00       	jmp    105a12 <pmap_walk+0x6b3>
  105425:	8b 45 d0             	mov    0xffffffd0(%ebp),%eax
  105428:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
// Atomically increment the reference count on a page.
static gcc_inline void
mem_incref(pageinfo *pi)
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  10542b:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  105430:	83 c0 08             	add    $0x8,%eax
  105433:	3b 45 ec             	cmp    0xffffffec(%ebp),%eax
  105436:	73 17                	jae    10544f <pmap_walk+0xf0>
  105438:	a1 44 fd 11 00       	mov    0x11fd44,%eax
  10543d:	c1 e0 03             	shl    $0x3,%eax
  105440:	89 c2                	mov    %eax,%edx
  105442:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  105447:	8d 04 02             	lea    (%edx,%eax,1),%eax
  10544a:	3b 45 ec             	cmp    0xffffffec(%ebp),%eax
  10544d:	77 24                	ja     105473 <pmap_walk+0x114>
  10544f:	c7 44 24 0c 14 bb 10 	movl   $0x10bb14,0xc(%esp)
  105456:	00 
  105457:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  10545e:	00 
  10545f:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
  105466:	00 
  105467:	c7 04 24 4b bb 10 00 	movl   $0x10bb4b,(%esp)
  10546e:	e8 29 b3 ff ff       	call   10079c <debug_panic>
	assert(pi != mem_ptr2pi(pmap_zero));	// Don't alloc/free zero page!
  105473:	8b 15 9c fd 11 00    	mov    0x11fd9c,%edx
  105479:	b8 00 20 12 00       	mov    $0x122000,%eax
  10547e:	c1 e8 0c             	shr    $0xc,%eax
  105481:	c1 e0 03             	shl    $0x3,%eax
  105484:	8d 04 02             	lea    (%edx,%eax,1),%eax
  105487:	3b 45 ec             	cmp    0xffffffec(%ebp),%eax
  10548a:	75 24                	jne    1054b0 <pmap_walk+0x151>
  10548c:	c7 44 24 0c 58 bb 10 	movl   $0x10bb58,0xc(%esp)
  105493:	00 
  105494:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  10549b:	00 
  10549c:	c7 44 24 04 59 00 00 	movl   $0x59,0x4(%esp)
  1054a3:	00 
  1054a4:	c7 04 24 4b bb 10 00 	movl   $0x10bb4b,(%esp)
  1054ab:	e8 ec b2 ff ff       	call   10079c <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  1054b0:	8b 15 9c fd 11 00    	mov    0x11fd9c,%edx
  1054b6:	b8 0c 00 10 00       	mov    $0x10000c,%eax
  1054bb:	c1 e8 0c             	shr    $0xc,%eax
  1054be:	c1 e0 03             	shl    $0x3,%eax
  1054c1:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1054c4:	3b 45 ec             	cmp    0xffffffec(%ebp),%eax
  1054c7:	77 40                	ja     105509 <pmap_walk+0x1aa>
  1054c9:	8b 15 9c fd 11 00    	mov    0x11fd9c,%edx
  1054cf:	b8 08 30 12 00       	mov    $0x123008,%eax
  1054d4:	83 e8 01             	sub    $0x1,%eax
  1054d7:	c1 e8 0c             	shr    $0xc,%eax
  1054da:	c1 e0 03             	shl    $0x3,%eax
  1054dd:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1054e0:	3b 45 ec             	cmp    0xffffffec(%ebp),%eax
  1054e3:	72 24                	jb     105509 <pmap_walk+0x1aa>
  1054e5:	c7 44 24 0c 74 bb 10 	movl   $0x10bb74,0xc(%esp)
  1054ec:	00 
  1054ed:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  1054f4:	00 
  1054f5:	c7 44 24 04 5a 00 00 	movl   $0x5a,0x4(%esp)
  1054fc:	00 
  1054fd:	c7 04 24 4b bb 10 00 	movl   $0x10bb4b,(%esp)
  105504:	e8 93 b2 ff ff       	call   10079c <debug_panic>

	lockadd(&pi->refcount, 1);
  105509:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  10550c:	83 c0 04             	add    $0x4,%eax
  10550f:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  105516:	00 
  105517:	89 04 24             	mov    %eax,(%esp)
  10551a:	e8 27 fc ff ff       	call   105146 <lockadd>
  mem_incref(pi);
  ptab = mem_pi2ptr(pi);
  10551f:	8b 55 d0             	mov    0xffffffd0(%ebp),%edx
  105522:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  105527:	89 d1                	mov    %edx,%ecx
  105529:	29 c1                	sub    %eax,%ecx
  10552b:	89 c8                	mov    %ecx,%eax
  10552d:	c1 e0 09             	shl    $0x9,%eax
  105530:	89 45 cc             	mov    %eax,0xffffffcc(%ebp)

  int i;
  for (i = 0; i < NPTENTRIES; i++)
  105533:	c7 45 d4 00 00 00 00 	movl   $0x0,0xffffffd4(%ebp)
  10553a:	eb 16                	jmp    105552 <pmap_walk+0x1f3>
  ptab[i] = PTE_ZERO;
  10553c:	8b 45 d4             	mov    0xffffffd4(%ebp),%eax
  10553f:	c1 e0 02             	shl    $0x2,%eax
  105542:	89 c2                	mov    %eax,%edx
  105544:	03 55 cc             	add    0xffffffcc(%ebp),%edx
  105547:	b8 00 20 12 00       	mov    $0x122000,%eax
  10554c:	89 02                	mov    %eax,(%edx)
  10554e:	83 45 d4 01          	addl   $0x1,0xffffffd4(%ebp)
  105552:	81 7d d4 ff 03 00 00 	cmpl   $0x3ff,0xffffffd4(%ebp)
  105559:	7e e1                	jle    10553c <pmap_walk+0x1dd>

  *pde = mem_pi2phys(pi) | PTE_A | PTE_P | PTE_W | PTE_U;
  10555b:	8b 55 d0             	mov    0xffffffd0(%ebp),%edx
  10555e:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  105563:	89 d1                	mov    %edx,%ecx
  105565:	29 c1                	sub    %eax,%ecx
  105567:	89 c8                	mov    %ecx,%eax
  105569:	c1 e0 09             	shl    $0x9,%eax
  10556c:	83 c8 27             	or     $0x27,%eax
  10556f:	89 c2                	mov    %eax,%edx
  105571:	8b 45 c8             	mov    0xffffffc8(%ebp),%eax
  105574:	89 10                	mov    %edx,(%eax)
  }
  
  if(writing && !(*pde & PTE_W)) {
  105576:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  10557a:	0f 84 7c 04 00 00    	je     1059fc <pmap_walk+0x69d>
  105580:	8b 45 c8             	mov    0xffffffc8(%ebp),%eax
  105583:	8b 00                	mov    (%eax),%eax
  105585:	83 e0 02             	and    $0x2,%eax
  105588:	85 c0                	test   %eax,%eax
  10558a:	0f 85 6c 04 00 00    	jne    1059fc <pmap_walk+0x69d>
  if(mem_ptr2pi(ptab) -> refcount == 1){
  105590:	8b 45 cc             	mov    0xffffffcc(%ebp),%eax
  105593:	c1 e8 0c             	shr    $0xc,%eax
  105596:	c1 e0 03             	shl    $0x3,%eax
  105599:	89 c2                	mov    %eax,%edx
  10559b:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  1055a0:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1055a3:	8b 40 04             	mov    0x4(%eax),%eax
  1055a6:	83 f8 01             	cmp    $0x1,%eax
  1055a9:	75 36                	jne    1055e1 <pmap_walk+0x282>
  int i;
  for (i = 0; i < NPTENTRIES; i++)
  1055ab:	c7 45 d8 00 00 00 00 	movl   $0x0,0xffffffd8(%ebp)
  1055b2:	eb 1f                	jmp    1055d3 <pmap_walk+0x274>
    ptab[i] &= ~PTE_W;
  1055b4:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  1055b7:	c1 e0 02             	shl    $0x2,%eax
  1055ba:	89 c2                	mov    %eax,%edx
  1055bc:	03 55 cc             	add    0xffffffcc(%ebp),%edx
  1055bf:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  1055c2:	c1 e0 02             	shl    $0x2,%eax
  1055c5:	03 45 cc             	add    0xffffffcc(%ebp),%eax
  1055c8:	8b 00                	mov    (%eax),%eax
  1055ca:	83 e0 fd             	and    $0xfffffffd,%eax
  1055cd:	89 02                	mov    %eax,(%edx)
  1055cf:	83 45 d8 01          	addl   $0x1,0xffffffd8(%ebp)
  1055d3:	81 7d d8 ff 03 00 00 	cmpl   $0x3ff,0xffffffd8(%ebp)
  1055da:	7e d8                	jle    1055b4 <pmap_walk+0x255>
  1055dc:	e9 0e 04 00 00       	jmp    1059ef <pmap_walk+0x690>
    } else {
    pageinfo *pi = mem_alloc();
  1055e1:	e8 99 b8 ff ff       	call   100e7f <mem_alloc>
  1055e6:	89 45 dc             	mov    %eax,0xffffffdc(%ebp)
    if (pi==NULL)
  1055e9:	83 7d dc 00          	cmpl   $0x0,0xffffffdc(%ebp)
  1055ed:	75 0c                	jne    1055fb <pmap_walk+0x29c>
    return NULL;
  1055ef:	c7 45 bc 00 00 00 00 	movl   $0x0,0xffffffbc(%ebp)
  1055f6:	e9 17 04 00 00       	jmp    105a12 <pmap_walk+0x6b3>
  1055fb:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  1055fe:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
// Atomically increment the reference count on a page.
static gcc_inline void
mem_incref(pageinfo *pi)
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  105601:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  105606:	83 c0 08             	add    $0x8,%eax
  105609:	3b 45 f0             	cmp    0xfffffff0(%ebp),%eax
  10560c:	73 17                	jae    105625 <pmap_walk+0x2c6>
  10560e:	a1 44 fd 11 00       	mov    0x11fd44,%eax
  105613:	c1 e0 03             	shl    $0x3,%eax
  105616:	89 c2                	mov    %eax,%edx
  105618:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  10561d:	8d 04 02             	lea    (%edx,%eax,1),%eax
  105620:	3b 45 f0             	cmp    0xfffffff0(%ebp),%eax
  105623:	77 24                	ja     105649 <pmap_walk+0x2ea>
  105625:	c7 44 24 0c 14 bb 10 	movl   $0x10bb14,0xc(%esp)
  10562c:	00 
  10562d:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  105634:	00 
  105635:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
  10563c:	00 
  10563d:	c7 04 24 4b bb 10 00 	movl   $0x10bb4b,(%esp)
  105644:	e8 53 b1 ff ff       	call   10079c <debug_panic>
	assert(pi != mem_ptr2pi(pmap_zero));	// Don't alloc/free zero page!
  105649:	8b 15 9c fd 11 00    	mov    0x11fd9c,%edx
  10564f:	b8 00 20 12 00       	mov    $0x122000,%eax
  105654:	c1 e8 0c             	shr    $0xc,%eax
  105657:	c1 e0 03             	shl    $0x3,%eax
  10565a:	8d 04 02             	lea    (%edx,%eax,1),%eax
  10565d:	3b 45 f0             	cmp    0xfffffff0(%ebp),%eax
  105660:	75 24                	jne    105686 <pmap_walk+0x327>
  105662:	c7 44 24 0c 58 bb 10 	movl   $0x10bb58,0xc(%esp)
  105669:	00 
  10566a:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  105671:	00 
  105672:	c7 44 24 04 59 00 00 	movl   $0x59,0x4(%esp)
  105679:	00 
  10567a:	c7 04 24 4b bb 10 00 	movl   $0x10bb4b,(%esp)
  105681:	e8 16 b1 ff ff       	call   10079c <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  105686:	8b 15 9c fd 11 00    	mov    0x11fd9c,%edx
  10568c:	b8 0c 00 10 00       	mov    $0x10000c,%eax
  105691:	c1 e8 0c             	shr    $0xc,%eax
  105694:	c1 e0 03             	shl    $0x3,%eax
  105697:	8d 04 02             	lea    (%edx,%eax,1),%eax
  10569a:	3b 45 f0             	cmp    0xfffffff0(%ebp),%eax
  10569d:	77 40                	ja     1056df <pmap_walk+0x380>
  10569f:	8b 15 9c fd 11 00    	mov    0x11fd9c,%edx
  1056a5:	b8 08 30 12 00       	mov    $0x123008,%eax
  1056aa:	83 e8 01             	sub    $0x1,%eax
  1056ad:	c1 e8 0c             	shr    $0xc,%eax
  1056b0:	c1 e0 03             	shl    $0x3,%eax
  1056b3:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1056b6:	3b 45 f0             	cmp    0xfffffff0(%ebp),%eax
  1056b9:	72 24                	jb     1056df <pmap_walk+0x380>
  1056bb:	c7 44 24 0c 74 bb 10 	movl   $0x10bb74,0xc(%esp)
  1056c2:	00 
  1056c3:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  1056ca:	00 
  1056cb:	c7 44 24 04 5a 00 00 	movl   $0x5a,0x4(%esp)
  1056d2:	00 
  1056d3:	c7 04 24 4b bb 10 00 	movl   $0x10bb4b,(%esp)
  1056da:	e8 bd b0 ff ff       	call   10079c <debug_panic>

	lockadd(&pi->refcount, 1);
  1056df:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  1056e2:	83 c0 04             	add    $0x4,%eax
  1056e5:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  1056ec:	00 
  1056ed:	89 04 24             	mov    %eax,(%esp)
  1056f0:	e8 51 fa ff ff       	call   105146 <lockadd>
    mem_incref(pi);
    pte_t *nptab = mem_pi2ptr(pi);
  1056f5:	8b 55 dc             	mov    0xffffffdc(%ebp),%edx
  1056f8:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  1056fd:	89 d1                	mov    %edx,%ecx
  1056ff:	29 c1                	sub    %eax,%ecx
  105701:	89 c8                	mov    %ecx,%eax
  105703:	c1 e0 09             	shl    $0x9,%eax
  105706:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)

    int i;
    for (i = 0; i < NPTENTRIES; i++){
  105709:	c7 45 e4 00 00 00 00 	movl   $0x0,0xffffffe4(%ebp)
  105710:	e9 79 01 00 00       	jmp    10588e <pmap_walk+0x52f>
    uint32_t pte = ptab[i];
  105715:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  105718:	c1 e0 02             	shl    $0x2,%eax
  10571b:	03 45 cc             	add    0xffffffcc(%ebp),%eax
  10571e:	8b 00                	mov    (%eax),%eax
  105720:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
    nptab[i] = pte & ~PTE_W;
  105723:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  105726:	c1 e0 02             	shl    $0x2,%eax
  105729:	89 c2                	mov    %eax,%edx
  10572b:	03 55 e0             	add    0xffffffe0(%ebp),%edx
  10572e:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  105731:	83 e0 fd             	and    $0xfffffffd,%eax
  105734:	89 02                	mov    %eax,(%edx)
    assert(PGADDR(pte) != 0);
  105736:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  105739:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  10573e:	85 c0                	test   %eax,%eax
  105740:	75 24                	jne    105766 <pmap_walk+0x407>
  105742:	c7 44 24 0c f7 bb 10 	movl   $0x10bbf7,0xc(%esp)
  105749:	00 
  10574a:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  105751:	00 
  105752:	c7 44 24 04 cf 00 00 	movl   $0xcf,0x4(%esp)
  105759:	00 
  10575a:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  105761:	e8 36 b0 ff ff       	call   10079c <debug_panic>
    if (PGADDR(pte) != PTE_ZERO)
  105766:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  105769:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  10576e:	ba 00 20 12 00       	mov    $0x122000,%edx
  105773:	39 d0                	cmp    %edx,%eax
  105775:	0f 84 0f 01 00 00    	je     10588a <pmap_walk+0x52b>
    mem_incref(mem_phys2pi(PGADDR(pte)));
  10577b:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  10577e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  105783:	c1 e8 0c             	shr    $0xc,%eax
  105786:	c1 e0 03             	shl    $0x3,%eax
  105789:	89 c2                	mov    %eax,%edx
  10578b:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  105790:	8d 04 02             	lea    (%edx,%eax,1),%eax
  105793:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
// Atomically increment the reference count on a page.
static gcc_inline void
mem_incref(pageinfo *pi)
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  105796:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  10579b:	83 c0 08             	add    $0x8,%eax
  10579e:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  1057a1:	73 17                	jae    1057ba <pmap_walk+0x45b>
  1057a3:	a1 44 fd 11 00       	mov    0x11fd44,%eax
  1057a8:	c1 e0 03             	shl    $0x3,%eax
  1057ab:	89 c2                	mov    %eax,%edx
  1057ad:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  1057b2:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1057b5:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  1057b8:	77 24                	ja     1057de <pmap_walk+0x47f>
  1057ba:	c7 44 24 0c 14 bb 10 	movl   $0x10bb14,0xc(%esp)
  1057c1:	00 
  1057c2:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  1057c9:	00 
  1057ca:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
  1057d1:	00 
  1057d2:	c7 04 24 4b bb 10 00 	movl   $0x10bb4b,(%esp)
  1057d9:	e8 be af ff ff       	call   10079c <debug_panic>
	assert(pi != mem_ptr2pi(pmap_zero));	// Don't alloc/free zero page!
  1057de:	8b 15 9c fd 11 00    	mov    0x11fd9c,%edx
  1057e4:	b8 00 20 12 00       	mov    $0x122000,%eax
  1057e9:	c1 e8 0c             	shr    $0xc,%eax
  1057ec:	c1 e0 03             	shl    $0x3,%eax
  1057ef:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1057f2:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  1057f5:	75 24                	jne    10581b <pmap_walk+0x4bc>
  1057f7:	c7 44 24 0c 58 bb 10 	movl   $0x10bb58,0xc(%esp)
  1057fe:	00 
  1057ff:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  105806:	00 
  105807:	c7 44 24 04 59 00 00 	movl   $0x59,0x4(%esp)
  10580e:	00 
  10580f:	c7 04 24 4b bb 10 00 	movl   $0x10bb4b,(%esp)
  105816:	e8 81 af ff ff       	call   10079c <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  10581b:	8b 15 9c fd 11 00    	mov    0x11fd9c,%edx
  105821:	b8 0c 00 10 00       	mov    $0x10000c,%eax
  105826:	c1 e8 0c             	shr    $0xc,%eax
  105829:	c1 e0 03             	shl    $0x3,%eax
  10582c:	8d 04 02             	lea    (%edx,%eax,1),%eax
  10582f:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  105832:	77 40                	ja     105874 <pmap_walk+0x515>
  105834:	8b 15 9c fd 11 00    	mov    0x11fd9c,%edx
  10583a:	b8 08 30 12 00       	mov    $0x123008,%eax
  10583f:	83 e8 01             	sub    $0x1,%eax
  105842:	c1 e8 0c             	shr    $0xc,%eax
  105845:	c1 e0 03             	shl    $0x3,%eax
  105848:	8d 04 02             	lea    (%edx,%eax,1),%eax
  10584b:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  10584e:	72 24                	jb     105874 <pmap_walk+0x515>
  105850:	c7 44 24 0c 74 bb 10 	movl   $0x10bb74,0xc(%esp)
  105857:	00 
  105858:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  10585f:	00 
  105860:	c7 44 24 04 5a 00 00 	movl   $0x5a,0x4(%esp)
  105867:	00 
  105868:	c7 04 24 4b bb 10 00 	movl   $0x10bb4b,(%esp)
  10586f:	e8 28 af ff ff       	call   10079c <debug_panic>

	lockadd(&pi->refcount, 1);
  105874:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  105877:	83 c0 04             	add    $0x4,%eax
  10587a:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  105881:	00 
  105882:	89 04 24             	mov    %eax,(%esp)
  105885:	e8 bc f8 ff ff       	call   105146 <lockadd>
  10588a:	83 45 e4 01          	addl   $0x1,0xffffffe4(%ebp)
  10588e:	81 7d e4 ff 03 00 00 	cmpl   $0x3ff,0xffffffe4(%ebp)
  105895:	0f 8e 7a fe ff ff    	jle    105715 <pmap_walk+0x3b6>
    }

    mem_decref(mem_ptr2pi(ptab), pmap_freeptab);
  10589b:	8b 45 cc             	mov    0xffffffcc(%ebp),%eax
  10589e:	c1 e8 0c             	shr    $0xc,%eax
  1058a1:	c1 e0 03             	shl    $0x3,%eax
  1058a4:	89 c2                	mov    %eax,%edx
  1058a6:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  1058ab:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1058ae:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  1058b1:	c7 45 f8 93 51 10 00 	movl   $0x105193,0xfffffff8(%ebp)
// freeing the page with the provided function if there are no more refs.
static gcc_inline void
mem_decref(pageinfo* pi, void (*freefun)(pageinfo *pi))
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  1058b8:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  1058bd:	83 c0 08             	add    $0x8,%eax
  1058c0:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  1058c3:	73 17                	jae    1058dc <pmap_walk+0x57d>
  1058c5:	a1 44 fd 11 00       	mov    0x11fd44,%eax
  1058ca:	c1 e0 03             	shl    $0x3,%eax
  1058cd:	89 c2                	mov    %eax,%edx
  1058cf:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  1058d4:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1058d7:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  1058da:	77 24                	ja     105900 <pmap_walk+0x5a1>
  1058dc:	c7 44 24 0c 14 bb 10 	movl   $0x10bb14,0xc(%esp)
  1058e3:	00 
  1058e4:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  1058eb:	00 
  1058ec:	c7 44 24 04 64 00 00 	movl   $0x64,0x4(%esp)
  1058f3:	00 
  1058f4:	c7 04 24 4b bb 10 00 	movl   $0x10bb4b,(%esp)
  1058fb:	e8 9c ae ff ff       	call   10079c <debug_panic>
	assert(pi != mem_ptr2pi(pmap_zero));	// Don't alloc/free zero page!
  105900:	8b 15 9c fd 11 00    	mov    0x11fd9c,%edx
  105906:	b8 00 20 12 00       	mov    $0x122000,%eax
  10590b:	c1 e8 0c             	shr    $0xc,%eax
  10590e:	c1 e0 03             	shl    $0x3,%eax
  105911:	8d 04 02             	lea    (%edx,%eax,1),%eax
  105914:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  105917:	75 24                	jne    10593d <pmap_walk+0x5de>
  105919:	c7 44 24 0c 58 bb 10 	movl   $0x10bb58,0xc(%esp)
  105920:	00 
  105921:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  105928:	00 
  105929:	c7 44 24 04 65 00 00 	movl   $0x65,0x4(%esp)
  105930:	00 
  105931:	c7 04 24 4b bb 10 00 	movl   $0x10bb4b,(%esp)
  105938:	e8 5f ae ff ff       	call   10079c <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  10593d:	8b 15 9c fd 11 00    	mov    0x11fd9c,%edx
  105943:	b8 0c 00 10 00       	mov    $0x10000c,%eax
  105948:	c1 e8 0c             	shr    $0xc,%eax
  10594b:	c1 e0 03             	shl    $0x3,%eax
  10594e:	8d 04 02             	lea    (%edx,%eax,1),%eax
  105951:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  105954:	77 40                	ja     105996 <pmap_walk+0x637>
  105956:	8b 15 9c fd 11 00    	mov    0x11fd9c,%edx
  10595c:	b8 08 30 12 00       	mov    $0x123008,%eax
  105961:	83 e8 01             	sub    $0x1,%eax
  105964:	c1 e8 0c             	shr    $0xc,%eax
  105967:	c1 e0 03             	shl    $0x3,%eax
  10596a:	8d 04 02             	lea    (%edx,%eax,1),%eax
  10596d:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  105970:	72 24                	jb     105996 <pmap_walk+0x637>
  105972:	c7 44 24 0c 74 bb 10 	movl   $0x10bb74,0xc(%esp)
  105979:	00 
  10597a:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  105981:	00 
  105982:	c7 44 24 04 66 00 00 	movl   $0x66,0x4(%esp)
  105989:	00 
  10598a:	c7 04 24 4b bb 10 00 	movl   $0x10bb4b,(%esp)
  105991:	e8 06 ae ff ff       	call   10079c <debug_panic>

	if (lockaddz(&pi->refcount, -1))
  105996:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  105999:	83 c0 04             	add    $0x4,%eax
  10599c:	c7 44 24 04 ff ff ff 	movl   $0xffffffff,0x4(%esp)
  1059a3:	ff 
  1059a4:	89 04 24             	mov    %eax,(%esp)
  1059a7:	e8 97 f9 ff ff       	call   105343 <lockaddz>
  1059ac:	84 c0                	test   %al,%al
  1059ae:	74 0b                	je     1059bb <pmap_walk+0x65c>
			freefun(pi);
  1059b0:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  1059b3:	89 04 24             	mov    %eax,(%esp)
  1059b6:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1059b9:	ff d0                	call   *%eax
	assert(pi->refcount >= 0);
  1059bb:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  1059be:	8b 40 04             	mov    0x4(%eax),%eax
  1059c1:	85 c0                	test   %eax,%eax
  1059c3:	79 24                	jns    1059e9 <pmap_walk+0x68a>
  1059c5:	c7 44 24 0c a5 bb 10 	movl   $0x10bba5,0xc(%esp)
  1059cc:	00 
  1059cd:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  1059d4:	00 
  1059d5:	c7 44 24 04 6a 00 00 	movl   $0x6a,0x4(%esp)
  1059dc:	00 
  1059dd:	c7 04 24 4b bb 10 00 	movl   $0x10bb4b,(%esp)
  1059e4:	e8 b3 ad ff ff       	call   10079c <debug_panic>
    ptab = nptab;
  1059e9:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  1059ec:	89 45 cc             	mov    %eax,0xffffffcc(%ebp)
    }

    *pde = (uint32_t)ptab | PTE_A | PTE_P | PTE_W | PTE_U;
  1059ef:	8b 45 cc             	mov    0xffffffcc(%ebp),%eax
  1059f2:	89 c2                	mov    %eax,%edx
  1059f4:	83 ca 27             	or     $0x27,%edx
  1059f7:	8b 45 c8             	mov    0xffffffc8(%ebp),%eax
  1059fa:	89 10                	mov    %edx,(%eax)
    }

    return &ptab[PTX(la)];
  1059fc:	8b 45 c4             	mov    0xffffffc4(%ebp),%eax
  1059ff:	c1 e8 0c             	shr    $0xc,%eax
  105a02:	25 ff 03 00 00       	and    $0x3ff,%eax
  105a07:	c1 e0 02             	shl    $0x2,%eax
  105a0a:	8b 55 cc             	mov    0xffffffcc(%ebp),%edx
  105a0d:	01 c2                	add    %eax,%edx
  105a0f:	89 55 bc             	mov    %edx,0xffffffbc(%ebp)
  105a12:	8b 45 bc             	mov    0xffffffbc(%ebp),%eax
}
  105a15:	c9                   	leave  
  105a16:	c3                   	ret    

00105a17 <pmap_insert>:

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
  105a17:	55                   	push   %ebp
  105a18:	89 e5                	mov    %esp,%ebp
  105a1a:	83 ec 28             	sub    $0x28,%esp
  pte_t* pte = pmap_walk(pdir, va, 1);
  105a1d:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
  105a24:	00 
  105a25:	8b 45 10             	mov    0x10(%ebp),%eax
  105a28:	89 44 24 04          	mov    %eax,0x4(%esp)
  105a2c:	8b 45 08             	mov    0x8(%ebp),%eax
  105a2f:	89 04 24             	mov    %eax,(%esp)
  105a32:	e8 28 f9 ff ff       	call   10535f <pmap_walk>
  105a37:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  if (pte == NULL)
  105a3a:	83 7d f8 00          	cmpl   $0x0,0xfffffff8(%ebp)
  105a3e:	75 0c                	jne    105a4c <pmap_insert+0x35>
    return NULL;
  105a40:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  105a47:	e9 44 01 00 00       	jmp    105b90 <pmap_insert+0x179>
  105a4c:	8b 45 0c             	mov    0xc(%ebp),%eax
  105a4f:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
// Atomically increment the reference count on a page.
static gcc_inline void
mem_incref(pageinfo *pi)
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  105a52:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  105a57:	83 c0 08             	add    $0x8,%eax
  105a5a:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  105a5d:	73 17                	jae    105a76 <pmap_insert+0x5f>
  105a5f:	a1 44 fd 11 00       	mov    0x11fd44,%eax
  105a64:	c1 e0 03             	shl    $0x3,%eax
  105a67:	89 c2                	mov    %eax,%edx
  105a69:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  105a6e:	8d 04 02             	lea    (%edx,%eax,1),%eax
  105a71:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  105a74:	77 24                	ja     105a9a <pmap_insert+0x83>
  105a76:	c7 44 24 0c 14 bb 10 	movl   $0x10bb14,0xc(%esp)
  105a7d:	00 
  105a7e:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  105a85:	00 
  105a86:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
  105a8d:	00 
  105a8e:	c7 04 24 4b bb 10 00 	movl   $0x10bb4b,(%esp)
  105a95:	e8 02 ad ff ff       	call   10079c <debug_panic>
	assert(pi != mem_ptr2pi(pmap_zero));	// Don't alloc/free zero page!
  105a9a:	8b 15 9c fd 11 00    	mov    0x11fd9c,%edx
  105aa0:	b8 00 20 12 00       	mov    $0x122000,%eax
  105aa5:	c1 e8 0c             	shr    $0xc,%eax
  105aa8:	c1 e0 03             	shl    $0x3,%eax
  105aab:	8d 04 02             	lea    (%edx,%eax,1),%eax
  105aae:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  105ab1:	75 24                	jne    105ad7 <pmap_insert+0xc0>
  105ab3:	c7 44 24 0c 58 bb 10 	movl   $0x10bb58,0xc(%esp)
  105aba:	00 
  105abb:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  105ac2:	00 
  105ac3:	c7 44 24 04 59 00 00 	movl   $0x59,0x4(%esp)
  105aca:	00 
  105acb:	c7 04 24 4b bb 10 00 	movl   $0x10bb4b,(%esp)
  105ad2:	e8 c5 ac ff ff       	call   10079c <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  105ad7:	8b 15 9c fd 11 00    	mov    0x11fd9c,%edx
  105add:	b8 0c 00 10 00       	mov    $0x10000c,%eax
  105ae2:	c1 e8 0c             	shr    $0xc,%eax
  105ae5:	c1 e0 03             	shl    $0x3,%eax
  105ae8:	8d 04 02             	lea    (%edx,%eax,1),%eax
  105aeb:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  105aee:	77 40                	ja     105b30 <pmap_insert+0x119>
  105af0:	8b 15 9c fd 11 00    	mov    0x11fd9c,%edx
  105af6:	b8 08 30 12 00       	mov    $0x123008,%eax
  105afb:	83 e8 01             	sub    $0x1,%eax
  105afe:	c1 e8 0c             	shr    $0xc,%eax
  105b01:	c1 e0 03             	shl    $0x3,%eax
  105b04:	8d 04 02             	lea    (%edx,%eax,1),%eax
  105b07:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  105b0a:	72 24                	jb     105b30 <pmap_insert+0x119>
  105b0c:	c7 44 24 0c 74 bb 10 	movl   $0x10bb74,0xc(%esp)
  105b13:	00 
  105b14:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  105b1b:	00 
  105b1c:	c7 44 24 04 5a 00 00 	movl   $0x5a,0x4(%esp)
  105b23:	00 
  105b24:	c7 04 24 4b bb 10 00 	movl   $0x10bb4b,(%esp)
  105b2b:	e8 6c ac ff ff       	call   10079c <debug_panic>

	lockadd(&pi->refcount, 1);
  105b30:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  105b33:	83 c0 04             	add    $0x4,%eax
  105b36:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  105b3d:	00 
  105b3e:	89 04 24             	mov    %eax,(%esp)
  105b41:	e8 00 f6 ff ff       	call   105146 <lockadd>


  mem_incref(pi);

  if (*pte & PTE_P)
  105b46:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  105b49:	8b 00                	mov    (%eax),%eax
  105b4b:	83 e0 01             	and    $0x1,%eax
  105b4e:	84 c0                	test   %al,%al
  105b50:	74 1a                	je     105b6c <pmap_insert+0x155>
    pmap_remove(pdir, va, PAGESIZE);
  105b52:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  105b59:	00 
  105b5a:	8b 45 10             	mov    0x10(%ebp),%eax
  105b5d:	89 44 24 04          	mov    %eax,0x4(%esp)
  105b61:	8b 45 08             	mov    0x8(%ebp),%eax
  105b64:	89 04 24             	mov    %eax,(%esp)
  105b67:	e8 29 00 00 00       	call   105b95 <pmap_remove>

  *pte = mem_pi2phys(pi) | perm | PTE_P;
  105b6c:	8b 55 0c             	mov    0xc(%ebp),%edx
  105b6f:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  105b74:	89 d1                	mov    %edx,%ecx
  105b76:	29 c1                	sub    %eax,%ecx
  105b78:	89 c8                	mov    %ecx,%eax
  105b7a:	c1 e0 09             	shl    $0x9,%eax
  105b7d:	0b 45 14             	or     0x14(%ebp),%eax
  105b80:	83 c8 01             	or     $0x1,%eax
  105b83:	89 c2                	mov    %eax,%edx
  105b85:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  105b88:	89 10                	mov    %edx,(%eax)
  return pte;
  105b8a:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  105b8d:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  105b90:	8b 45 ec             	mov    0xffffffec(%ebp),%eax



}
  105b93:	c9                   	leave  
  105b94:	c3                   	ret    

00105b95 <pmap_remove>:


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
  105b95:	55                   	push   %ebp
  105b96:	89 e5                	mov    %esp,%ebp
  105b98:	83 ec 48             	sub    $0x48,%esp
	assert(PGOFF(size) == 0);	// must be page-aligned
  105b9b:	8b 45 10             	mov    0x10(%ebp),%eax
  105b9e:	25 ff 0f 00 00       	and    $0xfff,%eax
  105ba3:	85 c0                	test   %eax,%eax
  105ba5:	74 24                	je     105bcb <pmap_remove+0x36>
  105ba7:	c7 44 24 0c 08 bc 10 	movl   $0x10bc08,0xc(%esp)
  105bae:	00 
  105baf:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  105bb6:	00 
  105bb7:	c7 44 24 04 1f 01 00 	movl   $0x11f,0x4(%esp)
  105bbe:	00 
  105bbf:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  105bc6:	e8 d1 ab ff ff       	call   10079c <debug_panic>
	assert(va >= VM_USERLO && va < VM_USERHI);
  105bcb:	81 7d 0c ff ff ff 3f 	cmpl   $0x3fffffff,0xc(%ebp)
  105bd2:	76 09                	jbe    105bdd <pmap_remove+0x48>
  105bd4:	81 7d 0c ff ff ff ef 	cmpl   $0xefffffff,0xc(%ebp)
  105bdb:	76 24                	jbe    105c01 <pmap_remove+0x6c>
  105bdd:	c7 44 24 0c b8 bb 10 	movl   $0x10bbb8,0xc(%esp)
  105be4:	00 
  105be5:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  105bec:	00 
  105bed:	c7 44 24 04 20 01 00 	movl   $0x120,0x4(%esp)
  105bf4:	00 
  105bf5:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  105bfc:	e8 9b ab ff ff       	call   10079c <debug_panic>
	assert(size <= VM_USERHI - va);
  105c01:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
  105c06:	2b 45 0c             	sub    0xc(%ebp),%eax
  105c09:	3b 45 10             	cmp    0x10(%ebp),%eax
  105c0c:	73 24                	jae    105c32 <pmap_remove+0x9d>
  105c0e:	c7 44 24 0c 19 bc 10 	movl   $0x10bc19,0xc(%esp)
  105c15:	00 
  105c16:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  105c1d:	00 
  105c1e:	c7 44 24 04 21 01 00 	movl   $0x121,0x4(%esp)
  105c25:	00 
  105c26:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  105c2d:	e8 6a ab ff ff       	call   10079c <debug_panic>

  pmap_inval(pdir, va, size);
  105c32:	8b 45 10             	mov    0x10(%ebp),%eax
  105c35:	89 44 24 08          	mov    %eax,0x8(%esp)
  105c39:	8b 45 0c             	mov    0xc(%ebp),%eax
  105c3c:	89 44 24 04          	mov    %eax,0x4(%esp)
  105c40:	8b 45 08             	mov    0x8(%ebp),%eax
  105c43:	89 04 24             	mov    %eax,(%esp)
  105c46:	e8 e0 03 00 00       	call   10602b <pmap_inval>

  uint32_t vahi = va + size;
  105c4b:	8b 45 10             	mov    0x10(%ebp),%eax
  105c4e:	03 45 0c             	add    0xc(%ebp),%eax
  105c51:	89 45 dc             	mov    %eax,0xffffffdc(%ebp)
  while (va < vahi){
  105c54:	e9 c4 03 00 00       	jmp    10601d <pmap_remove+0x488>
  pde_t *pde = &pdir[PDX(va)];
  105c59:	8b 45 0c             	mov    0xc(%ebp),%eax
  105c5c:	c1 e8 16             	shr    $0x16,%eax
  105c5f:	25 ff 03 00 00       	and    $0x3ff,%eax
  105c64:	c1 e0 02             	shl    $0x2,%eax
  105c67:	03 45 08             	add    0x8(%ebp),%eax
  105c6a:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)
  if (*pde == PTE_ZERO){
  105c6d:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  105c70:	8b 10                	mov    (%eax),%edx
  105c72:	b8 00 20 12 00       	mov    $0x122000,%eax
  105c77:	39 c2                	cmp    %eax,%edx
  105c79:	75 15                	jne    105c90 <pmap_remove+0xfb>
    va = PTADDR(va + PTSIZE);
  105c7b:	8b 45 0c             	mov    0xc(%ebp),%eax
  105c7e:	05 00 00 40 00       	add    $0x400000,%eax
  105c83:	25 00 00 c0 ff       	and    $0xffc00000,%eax
  105c88:	89 45 0c             	mov    %eax,0xc(%ebp)
      continue;
  105c8b:	e9 8d 03 00 00       	jmp    10601d <pmap_remove+0x488>
      }

    if (PTX(va) == 0 && vahi-va >= PTSIZE){
  105c90:	8b 45 0c             	mov    0xc(%ebp),%eax
  105c93:	c1 e8 0c             	shr    $0xc,%eax
  105c96:	25 ff 03 00 00       	and    $0x3ff,%eax
  105c9b:	85 c0                	test   %eax,%eax
  105c9d:	0f 85 98 01 00 00    	jne    105e3b <pmap_remove+0x2a6>
  105ca3:	8b 45 0c             	mov    0xc(%ebp),%eax
  105ca6:	8b 55 dc             	mov    0xffffffdc(%ebp),%edx
  105ca9:	89 d1                	mov    %edx,%ecx
  105cab:	29 c1                	sub    %eax,%ecx
  105cad:	89 c8                	mov    %ecx,%eax
  105caf:	3d ff ff 3f 00       	cmp    $0x3fffff,%eax
  105cb4:	0f 86 81 01 00 00    	jbe    105e3b <pmap_remove+0x2a6>
    uint32_t ptabaddr = PGADDR(*pde);
  105cba:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  105cbd:	8b 00                	mov    (%eax),%eax
  105cbf:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  105cc4:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
    if(ptabaddr != PTE_ZERO)
  105cc7:	b8 00 20 12 00       	mov    $0x122000,%eax
  105ccc:	39 45 e8             	cmp    %eax,0xffffffe8(%ebp)
  105ccf:	0f 84 4e 01 00 00    	je     105e23 <pmap_remove+0x28e>
      mem_decref(mem_phys2pi(ptabaddr), pmap_freeptab);
  105cd5:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  105cd8:	c1 e8 0c             	shr    $0xc,%eax
  105cdb:	c1 e0 03             	shl    $0x3,%eax
  105cde:	89 c2                	mov    %eax,%edx
  105ce0:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  105ce5:	8d 04 02             	lea    (%edx,%eax,1),%eax
  105ce8:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
  105ceb:	c7 45 f0 93 51 10 00 	movl   $0x105193,0xfffffff0(%ebp)
// freeing the page with the provided function if there are no more refs.
static gcc_inline void
mem_decref(pageinfo* pi, void (*freefun)(pageinfo *pi))
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  105cf2:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  105cf7:	83 c0 08             	add    $0x8,%eax
  105cfa:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  105cfd:	73 17                	jae    105d16 <pmap_remove+0x181>
  105cff:	a1 44 fd 11 00       	mov    0x11fd44,%eax
  105d04:	c1 e0 03             	shl    $0x3,%eax
  105d07:	89 c2                	mov    %eax,%edx
  105d09:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  105d0e:	8d 04 02             	lea    (%edx,%eax,1),%eax
  105d11:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  105d14:	77 24                	ja     105d3a <pmap_remove+0x1a5>
  105d16:	c7 44 24 0c 14 bb 10 	movl   $0x10bb14,0xc(%esp)
  105d1d:	00 
  105d1e:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  105d25:	00 
  105d26:	c7 44 24 04 64 00 00 	movl   $0x64,0x4(%esp)
  105d2d:	00 
  105d2e:	c7 04 24 4b bb 10 00 	movl   $0x10bb4b,(%esp)
  105d35:	e8 62 aa ff ff       	call   10079c <debug_panic>
	assert(pi != mem_ptr2pi(pmap_zero));	// Don't alloc/free zero page!
  105d3a:	8b 15 9c fd 11 00    	mov    0x11fd9c,%edx
  105d40:	b8 00 20 12 00       	mov    $0x122000,%eax
  105d45:	c1 e8 0c             	shr    $0xc,%eax
  105d48:	c1 e0 03             	shl    $0x3,%eax
  105d4b:	8d 04 02             	lea    (%edx,%eax,1),%eax
  105d4e:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  105d51:	75 24                	jne    105d77 <pmap_remove+0x1e2>
  105d53:	c7 44 24 0c 58 bb 10 	movl   $0x10bb58,0xc(%esp)
  105d5a:	00 
  105d5b:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  105d62:	00 
  105d63:	c7 44 24 04 65 00 00 	movl   $0x65,0x4(%esp)
  105d6a:	00 
  105d6b:	c7 04 24 4b bb 10 00 	movl   $0x10bb4b,(%esp)
  105d72:	e8 25 aa ff ff       	call   10079c <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  105d77:	8b 15 9c fd 11 00    	mov    0x11fd9c,%edx
  105d7d:	b8 0c 00 10 00       	mov    $0x10000c,%eax
  105d82:	c1 e8 0c             	shr    $0xc,%eax
  105d85:	c1 e0 03             	shl    $0x3,%eax
  105d88:	8d 04 02             	lea    (%edx,%eax,1),%eax
  105d8b:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  105d8e:	77 40                	ja     105dd0 <pmap_remove+0x23b>
  105d90:	8b 15 9c fd 11 00    	mov    0x11fd9c,%edx
  105d96:	b8 08 30 12 00       	mov    $0x123008,%eax
  105d9b:	83 e8 01             	sub    $0x1,%eax
  105d9e:	c1 e8 0c             	shr    $0xc,%eax
  105da1:	c1 e0 03             	shl    $0x3,%eax
  105da4:	8d 04 02             	lea    (%edx,%eax,1),%eax
  105da7:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  105daa:	72 24                	jb     105dd0 <pmap_remove+0x23b>
  105dac:	c7 44 24 0c 74 bb 10 	movl   $0x10bb74,0xc(%esp)
  105db3:	00 
  105db4:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  105dbb:	00 
  105dbc:	c7 44 24 04 66 00 00 	movl   $0x66,0x4(%esp)
  105dc3:	00 
  105dc4:	c7 04 24 4b bb 10 00 	movl   $0x10bb4b,(%esp)
  105dcb:	e8 cc a9 ff ff       	call   10079c <debug_panic>

	if (lockaddz(&pi->refcount, -1))
  105dd0:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  105dd3:	83 c0 04             	add    $0x4,%eax
  105dd6:	c7 44 24 04 ff ff ff 	movl   $0xffffffff,0x4(%esp)
  105ddd:	ff 
  105dde:	89 04 24             	mov    %eax,(%esp)
  105de1:	e8 5d f5 ff ff       	call   105343 <lockaddz>
  105de6:	84 c0                	test   %al,%al
  105de8:	74 0b                	je     105df5 <pmap_remove+0x260>
			freefun(pi);
  105dea:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  105ded:	89 04 24             	mov    %eax,(%esp)
  105df0:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  105df3:	ff d0                	call   *%eax
	assert(pi->refcount >= 0);
  105df5:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  105df8:	8b 40 04             	mov    0x4(%eax),%eax
  105dfb:	85 c0                	test   %eax,%eax
  105dfd:	79 24                	jns    105e23 <pmap_remove+0x28e>
  105dff:	c7 44 24 0c a5 bb 10 	movl   $0x10bba5,0xc(%esp)
  105e06:	00 
  105e07:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  105e0e:	00 
  105e0f:	c7 44 24 04 6a 00 00 	movl   $0x6a,0x4(%esp)
  105e16:	00 
  105e17:	c7 04 24 4b bb 10 00 	movl   $0x10bb4b,(%esp)
  105e1e:	e8 79 a9 ff ff       	call   10079c <debug_panic>
      *pde = PTE_ZERO;
  105e23:	b8 00 20 12 00       	mov    $0x122000,%eax
  105e28:	89 c2                	mov    %eax,%edx
  105e2a:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  105e2d:	89 10                	mov    %edx,(%eax)
      va += PTSIZE;
  105e2f:	81 45 0c 00 00 40 00 	addl   $0x400000,0xc(%ebp)
      continue;
  105e36:	e9 e2 01 00 00       	jmp    10601d <pmap_remove+0x488>
      }
  pte_t *pte = pmap_walk(pdir, va, 1);
  105e3b:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
  105e42:	00 
  105e43:	8b 45 0c             	mov    0xc(%ebp),%eax
  105e46:	89 44 24 04          	mov    %eax,0x4(%esp)
  105e4a:	8b 45 08             	mov    0x8(%ebp),%eax
  105e4d:	89 04 24             	mov    %eax,(%esp)
  105e50:	e8 0a f5 ff ff       	call   10535f <pmap_walk>
  105e55:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
  assert(pte != NULL);
  105e58:	83 7d e4 00          	cmpl   $0x0,0xffffffe4(%ebp)
  105e5c:	75 24                	jne    105e82 <pmap_remove+0x2ed>
  105e5e:	c7 44 24 0c 30 bc 10 	movl   $0x10bc30,0xc(%esp)
  105e65:	00 
  105e66:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  105e6d:	00 
  105e6e:	c7 44 24 04 36 01 00 	movl   $0x136,0x4(%esp)
  105e75:	00 
  105e76:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  105e7d:	e8 1a a9 ff ff       	call   10079c <debug_panic>

  do{
    uint32_t pgaddr = PGADDR(*pte);
  105e82:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  105e85:	8b 00                	mov    (%eax),%eax
  105e87:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  105e8c:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
    if(pgaddr != PTE_ZERO)
  105e8f:	b8 00 20 12 00       	mov    $0x122000,%eax
  105e94:	39 45 ec             	cmp    %eax,0xffffffec(%ebp)
  105e97:	0f 84 4e 01 00 00    	je     105feb <pmap_remove+0x456>
      mem_decref(mem_phys2pi(pgaddr), mem_free);
  105e9d:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  105ea0:	c1 e8 0c             	shr    $0xc,%eax
  105ea3:	c1 e0 03             	shl    $0x3,%eax
  105ea6:	89 c2                	mov    %eax,%edx
  105ea8:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  105ead:	8d 04 02             	lea    (%edx,%eax,1),%eax
  105eb0:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  105eb3:	c7 45 f8 c3 0e 10 00 	movl   $0x100ec3,0xfffffff8(%ebp)
// freeing the page with the provided function if there are no more refs.
static gcc_inline void
mem_decref(pageinfo* pi, void (*freefun)(pageinfo *pi))
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  105eba:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  105ebf:	83 c0 08             	add    $0x8,%eax
  105ec2:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  105ec5:	73 17                	jae    105ede <pmap_remove+0x349>
  105ec7:	a1 44 fd 11 00       	mov    0x11fd44,%eax
  105ecc:	c1 e0 03             	shl    $0x3,%eax
  105ecf:	89 c2                	mov    %eax,%edx
  105ed1:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  105ed6:	8d 04 02             	lea    (%edx,%eax,1),%eax
  105ed9:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  105edc:	77 24                	ja     105f02 <pmap_remove+0x36d>
  105ede:	c7 44 24 0c 14 bb 10 	movl   $0x10bb14,0xc(%esp)
  105ee5:	00 
  105ee6:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  105eed:	00 
  105eee:	c7 44 24 04 64 00 00 	movl   $0x64,0x4(%esp)
  105ef5:	00 
  105ef6:	c7 04 24 4b bb 10 00 	movl   $0x10bb4b,(%esp)
  105efd:	e8 9a a8 ff ff       	call   10079c <debug_panic>
	assert(pi != mem_ptr2pi(pmap_zero));	// Don't alloc/free zero page!
  105f02:	8b 15 9c fd 11 00    	mov    0x11fd9c,%edx
  105f08:	b8 00 20 12 00       	mov    $0x122000,%eax
  105f0d:	c1 e8 0c             	shr    $0xc,%eax
  105f10:	c1 e0 03             	shl    $0x3,%eax
  105f13:	8d 04 02             	lea    (%edx,%eax,1),%eax
  105f16:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  105f19:	75 24                	jne    105f3f <pmap_remove+0x3aa>
  105f1b:	c7 44 24 0c 58 bb 10 	movl   $0x10bb58,0xc(%esp)
  105f22:	00 
  105f23:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  105f2a:	00 
  105f2b:	c7 44 24 04 65 00 00 	movl   $0x65,0x4(%esp)
  105f32:	00 
  105f33:	c7 04 24 4b bb 10 00 	movl   $0x10bb4b,(%esp)
  105f3a:	e8 5d a8 ff ff       	call   10079c <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  105f3f:	8b 15 9c fd 11 00    	mov    0x11fd9c,%edx
  105f45:	b8 0c 00 10 00       	mov    $0x10000c,%eax
  105f4a:	c1 e8 0c             	shr    $0xc,%eax
  105f4d:	c1 e0 03             	shl    $0x3,%eax
  105f50:	8d 04 02             	lea    (%edx,%eax,1),%eax
  105f53:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  105f56:	77 40                	ja     105f98 <pmap_remove+0x403>
  105f58:	8b 15 9c fd 11 00    	mov    0x11fd9c,%edx
  105f5e:	b8 08 30 12 00       	mov    $0x123008,%eax
  105f63:	83 e8 01             	sub    $0x1,%eax
  105f66:	c1 e8 0c             	shr    $0xc,%eax
  105f69:	c1 e0 03             	shl    $0x3,%eax
  105f6c:	8d 04 02             	lea    (%edx,%eax,1),%eax
  105f6f:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  105f72:	72 24                	jb     105f98 <pmap_remove+0x403>
  105f74:	c7 44 24 0c 74 bb 10 	movl   $0x10bb74,0xc(%esp)
  105f7b:	00 
  105f7c:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  105f83:	00 
  105f84:	c7 44 24 04 66 00 00 	movl   $0x66,0x4(%esp)
  105f8b:	00 
  105f8c:	c7 04 24 4b bb 10 00 	movl   $0x10bb4b,(%esp)
  105f93:	e8 04 a8 ff ff       	call   10079c <debug_panic>

	if (lockaddz(&pi->refcount, -1))
  105f98:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  105f9b:	83 c0 04             	add    $0x4,%eax
  105f9e:	c7 44 24 04 ff ff ff 	movl   $0xffffffff,0x4(%esp)
  105fa5:	ff 
  105fa6:	89 04 24             	mov    %eax,(%esp)
  105fa9:	e8 95 f3 ff ff       	call   105343 <lockaddz>
  105fae:	84 c0                	test   %al,%al
  105fb0:	74 0b                	je     105fbd <pmap_remove+0x428>
			freefun(pi);
  105fb2:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  105fb5:	89 04 24             	mov    %eax,(%esp)
  105fb8:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  105fbb:	ff d0                	call   *%eax
	assert(pi->refcount >= 0);
  105fbd:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  105fc0:	8b 40 04             	mov    0x4(%eax),%eax
  105fc3:	85 c0                	test   %eax,%eax
  105fc5:	79 24                	jns    105feb <pmap_remove+0x456>
  105fc7:	c7 44 24 0c a5 bb 10 	movl   $0x10bba5,0xc(%esp)
  105fce:	00 
  105fcf:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  105fd6:	00 
  105fd7:	c7 44 24 04 6a 00 00 	movl   $0x6a,0x4(%esp)
  105fde:	00 
  105fdf:	c7 04 24 4b bb 10 00 	movl   $0x10bb4b,(%esp)
  105fe6:	e8 b1 a7 ff ff       	call   10079c <debug_panic>
      *pte++ = PTE_ZERO;
  105feb:	b8 00 20 12 00       	mov    $0x122000,%eax
  105ff0:	89 c2                	mov    %eax,%edx
  105ff2:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  105ff5:	89 10                	mov    %edx,(%eax)
  105ff7:	83 45 e4 04          	addl   $0x4,0xffffffe4(%ebp)
      va += PAGESIZE;
  105ffb:	81 45 0c 00 10 00 00 	addl   $0x1000,0xc(%ebp)
      } while (va < vahi && PTX(va) != 0);
  106002:	8b 45 0c             	mov    0xc(%ebp),%eax
  106005:	3b 45 dc             	cmp    0xffffffdc(%ebp),%eax
  106008:	73 13                	jae    10601d <pmap_remove+0x488>
  10600a:	8b 45 0c             	mov    0xc(%ebp),%eax
  10600d:	c1 e8 0c             	shr    $0xc,%eax
  106010:	25 ff 03 00 00       	and    $0x3ff,%eax
  106015:	85 c0                	test   %eax,%eax
  106017:	0f 85 65 fe ff ff    	jne    105e82 <pmap_remove+0x2ed>
  10601d:	8b 45 0c             	mov    0xc(%ebp),%eax
  106020:	3b 45 dc             	cmp    0xffffffdc(%ebp),%eax
  106023:	0f 82 30 fc ff ff    	jb     105c59 <pmap_remove+0xc4>
      }

}
  106029:	c9                   	leave  
  10602a:	c3                   	ret    

0010602b <pmap_inval>:


//
// Invalidate the TLB entry or entries for a given virtual address range,
// but only if the page tables being edited are the ones
// currently in use by the processor.
//
void
pmap_inval(pde_t *pdir, uint32_t va, size_t size)
{
  10602b:	55                   	push   %ebp
  10602c:	89 e5                	mov    %esp,%ebp
  10602e:	83 ec 18             	sub    $0x18,%esp
	// Flush the entry only if we're modifying the current address space.
	proc *p = proc_cur();
  106031:	e8 69 ef ff ff       	call   104f9f <cpu_cur>
  106036:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  10603c:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	if (p == NULL || p->pdir == pdir) {
  10603f:	83 7d f4 00          	cmpl   $0x0,0xfffffff4(%ebp)
  106043:	74 0e                	je     106053 <pmap_inval+0x28>
  106045:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  106048:	8b 80 a0 06 00 00    	mov    0x6a0(%eax),%eax
  10604e:	3b 45 08             	cmp    0x8(%ebp),%eax
  106051:	75 23                	jne    106076 <pmap_inval+0x4b>
		if (size == PAGESIZE)
  106053:	81 7d 10 00 10 00 00 	cmpl   $0x1000,0x10(%ebp)
  10605a:	75 0e                	jne    10606a <pmap_inval+0x3f>
			invlpg(mem_ptr(va));	// invalidate one page
  10605c:	8b 45 0c             	mov    0xc(%ebp),%eax
  10605f:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)

static gcc_inline void 
invlpg(void *addr)
{ 
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
  106062:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  106065:	0f 01 38             	invlpg (%eax)
  106068:	eb 0c                	jmp    106076 <pmap_inval+0x4b>
		else
			lcr3(mem_phys(pdir));	// invalidate everything
  10606a:	8b 45 08             	mov    0x8(%ebp),%eax
  10606d:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)

static gcc_inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
  106070:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  106073:	0f 22 d8             	mov    %eax,%cr3
	}
}
  106076:	c9                   	leave  
  106077:	c3                   	ret    

00106078 <pmap_copy>:

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
  106078:	55                   	push   %ebp
  106079:	89 e5                	mov    %esp,%ebp
  10607b:	83 ec 28             	sub    $0x28,%esp
	assert(PTOFF(sva) == 0);	// must be 4MB-aligned
  10607e:	8b 45 0c             	mov    0xc(%ebp),%eax
  106081:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  106086:	85 c0                	test   %eax,%eax
  106088:	74 24                	je     1060ae <pmap_copy+0x36>
  10608a:	c7 44 24 0c 3c bc 10 	movl   $0x10bc3c,0xc(%esp)
  106091:	00 
  106092:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  106099:	00 
  10609a:	c7 44 24 04 60 01 00 	movl   $0x160,0x4(%esp)
  1060a1:	00 
  1060a2:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  1060a9:	e8 ee a6 ff ff       	call   10079c <debug_panic>
	assert(PTOFF(dva) == 0);
  1060ae:	8b 45 14             	mov    0x14(%ebp),%eax
  1060b1:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  1060b6:	85 c0                	test   %eax,%eax
  1060b8:	74 24                	je     1060de <pmap_copy+0x66>
  1060ba:	c7 44 24 0c 4c bc 10 	movl   $0x10bc4c,0xc(%esp)
  1060c1:	00 
  1060c2:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  1060c9:	00 
  1060ca:	c7 44 24 04 61 01 00 	movl   $0x161,0x4(%esp)
  1060d1:	00 
  1060d2:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  1060d9:	e8 be a6 ff ff       	call   10079c <debug_panic>
	assert(PTOFF(size) == 0);
  1060de:	8b 45 18             	mov    0x18(%ebp),%eax
  1060e1:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  1060e6:	85 c0                	test   %eax,%eax
  1060e8:	74 24                	je     10610e <pmap_copy+0x96>
  1060ea:	c7 44 24 0c 5c bc 10 	movl   $0x10bc5c,0xc(%esp)
  1060f1:	00 
  1060f2:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  1060f9:	00 
  1060fa:	c7 44 24 04 62 01 00 	movl   $0x162,0x4(%esp)
  106101:	00 
  106102:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  106109:	e8 8e a6 ff ff       	call   10079c <debug_panic>
	assert(sva >= VM_USERLO && sva < VM_USERHI);
  10610e:	81 7d 0c ff ff ff 3f 	cmpl   $0x3fffffff,0xc(%ebp)
  106115:	76 09                	jbe    106120 <pmap_copy+0xa8>
  106117:	81 7d 0c ff ff ff ef 	cmpl   $0xefffffff,0xc(%ebp)
  10611e:	76 24                	jbe    106144 <pmap_copy+0xcc>
  106120:	c7 44 24 0c 70 bc 10 	movl   $0x10bc70,0xc(%esp)
  106127:	00 
  106128:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  10612f:	00 
  106130:	c7 44 24 04 63 01 00 	movl   $0x163,0x4(%esp)
  106137:	00 
  106138:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  10613f:	e8 58 a6 ff ff       	call   10079c <debug_panic>
	assert(dva >= VM_USERLO && dva < VM_USERHI);
  106144:	81 7d 14 ff ff ff 3f 	cmpl   $0x3fffffff,0x14(%ebp)
  10614b:	76 09                	jbe    106156 <pmap_copy+0xde>
  10614d:	81 7d 14 ff ff ff ef 	cmpl   $0xefffffff,0x14(%ebp)
  106154:	76 24                	jbe    10617a <pmap_copy+0x102>
  106156:	c7 44 24 0c 94 bc 10 	movl   $0x10bc94,0xc(%esp)
  10615d:	00 
  10615e:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  106165:	00 
  106166:	c7 44 24 04 64 01 00 	movl   $0x164,0x4(%esp)
  10616d:	00 
  10616e:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  106175:	e8 22 a6 ff ff       	call   10079c <debug_panic>
	assert(size <= VM_USERHI - sva);
  10617a:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
  10617f:	2b 45 0c             	sub    0xc(%ebp),%eax
  106182:	3b 45 18             	cmp    0x18(%ebp),%eax
  106185:	73 24                	jae    1061ab <pmap_copy+0x133>
  106187:	c7 44 24 0c b8 bc 10 	movl   $0x10bcb8,0xc(%esp)
  10618e:	00 
  10618f:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  106196:	00 
  106197:	c7 44 24 04 65 01 00 	movl   $0x165,0x4(%esp)
  10619e:	00 
  10619f:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  1061a6:	e8 f1 a5 ff ff       	call   10079c <debug_panic>
	assert(size <= VM_USERHI - dva);
  1061ab:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
  1061b0:	2b 45 14             	sub    0x14(%ebp),%eax
  1061b3:	3b 45 18             	cmp    0x18(%ebp),%eax
  1061b6:	73 24                	jae    1061dc <pmap_copy+0x164>
  1061b8:	c7 44 24 0c d0 bc 10 	movl   $0x10bcd0,0xc(%esp)
  1061bf:	00 
  1061c0:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  1061c7:	00 
  1061c8:	c7 44 24 04 66 01 00 	movl   $0x166,0x4(%esp)
  1061cf:	00 
  1061d0:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  1061d7:	e8 c0 a5 ff ff       	call   10079c <debug_panic>

  pmap_inval(spdir, sva, size);
  1061dc:	8b 45 18             	mov    0x18(%ebp),%eax
  1061df:	89 44 24 08          	mov    %eax,0x8(%esp)
  1061e3:	8b 45 0c             	mov    0xc(%ebp),%eax
  1061e6:	89 44 24 04          	mov    %eax,0x4(%esp)
  1061ea:	8b 45 08             	mov    0x8(%ebp),%eax
  1061ed:	89 04 24             	mov    %eax,(%esp)
  1061f0:	e8 36 fe ff ff       	call   10602b <pmap_inval>
  pmap_inval(dpdir, dva, size);
  1061f5:	8b 45 18             	mov    0x18(%ebp),%eax
  1061f8:	89 44 24 08          	mov    %eax,0x8(%esp)
  1061fc:	8b 45 14             	mov    0x14(%ebp),%eax
  1061ff:	89 44 24 04          	mov    %eax,0x4(%esp)
  106203:	8b 45 10             	mov    0x10(%ebp),%eax
  106206:	89 04 24             	mov    %eax,(%esp)
  106209:	e8 1d fe ff ff       	call   10602b <pmap_inval>

  uint32_t svahi = sva + size;
  10620e:	8b 45 18             	mov    0x18(%ebp),%eax
  106211:	03 45 0c             	add    0xc(%ebp),%eax
  106214:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
  pde_t *spde = &spdir[PDX(sva)];
  106217:	8b 45 0c             	mov    0xc(%ebp),%eax
  10621a:	c1 e8 16             	shr    $0x16,%eax
  10621d:	25 ff 03 00 00       	and    $0x3ff,%eax
  106222:	c1 e0 02             	shl    $0x2,%eax
  106225:	03 45 08             	add    0x8(%ebp),%eax
  106228:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
  pte_t *dpde = &dpdir[PDX(dva)];
  10622b:	8b 45 14             	mov    0x14(%ebp),%eax
  10622e:	c1 e8 16             	shr    $0x16,%eax
  106231:	25 ff 03 00 00       	and    $0x3ff,%eax
  106236:	c1 e0 02             	shl    $0x2,%eax
  106239:	03 45 10             	add    0x10(%ebp),%eax
  10623c:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)

  while (sva < svahi){
  10623f:	e9 aa 01 00 00       	jmp    1063ee <pmap_copy+0x376>

    if (*dpde & PTE_P)
  106244:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  106247:	8b 00                	mov    (%eax),%eax
  106249:	83 e0 01             	and    $0x1,%eax
  10624c:	84 c0                	test   %al,%al
  10624e:	74 1a                	je     10626a <pmap_copy+0x1f2>
      pmap_remove(dpdir, dva, PTSIZE);
  106250:	c7 44 24 08 00 00 40 	movl   $0x400000,0x8(%esp)
  106257:	00 
  106258:	8b 45 14             	mov    0x14(%ebp),%eax
  10625b:	89 44 24 04          	mov    %eax,0x4(%esp)
  10625f:	8b 45 10             	mov    0x10(%ebp),%eax
  106262:	89 04 24             	mov    %eax,(%esp)
  106265:	e8 2b f9 ff ff       	call   105b95 <pmap_remove>
    assert(*dpde == PTE_ZERO);
  10626a:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10626d:	8b 10                	mov    (%eax),%edx
  10626f:	b8 00 20 12 00       	mov    $0x122000,%eax
  106274:	39 c2                	cmp    %eax,%edx
  106276:	74 24                	je     10629c <pmap_copy+0x224>
  106278:	c7 44 24 0c e8 bc 10 	movl   $0x10bce8,0xc(%esp)
  10627f:	00 
  106280:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  106287:	00 
  106288:	c7 44 24 04 73 01 00 	movl   $0x173,0x4(%esp)
  10628f:	00 
  106290:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  106297:	e8 00 a5 ff ff       	call   10079c <debug_panic>

    *spde &= ~PTE_W;
  10629c:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  10629f:	8b 00                	mov    (%eax),%eax
  1062a1:	89 c2                	mov    %eax,%edx
  1062a3:	83 e2 fd             	and    $0xfffffffd,%edx
  1062a6:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  1062a9:	89 10                	mov    %edx,(%eax)

    *dpde = *spde;
  1062ab:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  1062ae:	8b 10                	mov    (%eax),%edx
  1062b0:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1062b3:	89 10                	mov    %edx,(%eax)

    if (*spde != PTE_ZERO)
  1062b5:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  1062b8:	8b 10                	mov    (%eax),%edx
  1062ba:	b8 00 20 12 00       	mov    $0x122000,%eax
  1062bf:	39 c2                	cmp    %eax,%edx
  1062c1:	0f 84 11 01 00 00    	je     1063d8 <pmap_copy+0x360>
      mem_incref(mem_phys2pi(PGADDR(*spde)));
  1062c7:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  1062ca:	8b 00                	mov    (%eax),%eax
  1062cc:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1062d1:	c1 e8 0c             	shr    $0xc,%eax
  1062d4:	c1 e0 03             	shl    $0x3,%eax
  1062d7:	89 c2                	mov    %eax,%edx
  1062d9:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  1062de:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1062e1:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
// Atomically increment the reference count on a page.
static gcc_inline void
mem_incref(pageinfo *pi)
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  1062e4:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  1062e9:	83 c0 08             	add    $0x8,%eax
  1062ec:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  1062ef:	73 17                	jae    106308 <pmap_copy+0x290>
  1062f1:	a1 44 fd 11 00       	mov    0x11fd44,%eax
  1062f6:	c1 e0 03             	shl    $0x3,%eax
  1062f9:	89 c2                	mov    %eax,%edx
  1062fb:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  106300:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106303:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  106306:	77 24                	ja     10632c <pmap_copy+0x2b4>
  106308:	c7 44 24 0c 14 bb 10 	movl   $0x10bb14,0xc(%esp)
  10630f:	00 
  106310:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  106317:	00 
  106318:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
  10631f:	00 
  106320:	c7 04 24 4b bb 10 00 	movl   $0x10bb4b,(%esp)
  106327:	e8 70 a4 ff ff       	call   10079c <debug_panic>
	assert(pi != mem_ptr2pi(pmap_zero));	// Don't alloc/free zero page!
  10632c:	8b 15 9c fd 11 00    	mov    0x11fd9c,%edx
  106332:	b8 00 20 12 00       	mov    $0x122000,%eax
  106337:	c1 e8 0c             	shr    $0xc,%eax
  10633a:	c1 e0 03             	shl    $0x3,%eax
  10633d:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106340:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  106343:	75 24                	jne    106369 <pmap_copy+0x2f1>
  106345:	c7 44 24 0c 58 bb 10 	movl   $0x10bb58,0xc(%esp)
  10634c:	00 
  10634d:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  106354:	00 
  106355:	c7 44 24 04 59 00 00 	movl   $0x59,0x4(%esp)
  10635c:	00 
  10635d:	c7 04 24 4b bb 10 00 	movl   $0x10bb4b,(%esp)
  106364:	e8 33 a4 ff ff       	call   10079c <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  106369:	8b 15 9c fd 11 00    	mov    0x11fd9c,%edx
  10636f:	b8 0c 00 10 00       	mov    $0x10000c,%eax
  106374:	c1 e8 0c             	shr    $0xc,%eax
  106377:	c1 e0 03             	shl    $0x3,%eax
  10637a:	8d 04 02             	lea    (%edx,%eax,1),%eax
  10637d:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  106380:	77 40                	ja     1063c2 <pmap_copy+0x34a>
  106382:	8b 15 9c fd 11 00    	mov    0x11fd9c,%edx
  106388:	b8 08 30 12 00       	mov    $0x123008,%eax
  10638d:	83 e8 01             	sub    $0x1,%eax
  106390:	c1 e8 0c             	shr    $0xc,%eax
  106393:	c1 e0 03             	shl    $0x3,%eax
  106396:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106399:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  10639c:	72 24                	jb     1063c2 <pmap_copy+0x34a>
  10639e:	c7 44 24 0c 74 bb 10 	movl   $0x10bb74,0xc(%esp)
  1063a5:	00 
  1063a6:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  1063ad:	00 
  1063ae:	c7 44 24 04 5a 00 00 	movl   $0x5a,0x4(%esp)
  1063b5:	00 
  1063b6:	c7 04 24 4b bb 10 00 	movl   $0x10bb4b,(%esp)
  1063bd:	e8 da a3 ff ff       	call   10079c <debug_panic>

	lockadd(&pi->refcount, 1);
  1063c2:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  1063c5:	83 c0 04             	add    $0x4,%eax
  1063c8:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  1063cf:	00 
  1063d0:	89 04 24             	mov    %eax,(%esp)
  1063d3:	e8 6e ed ff ff       	call   105146 <lockadd>

      spde++, dpde++;
  1063d8:	83 45 f4 04          	addl   $0x4,0xfffffff4(%ebp)
  1063dc:	83 45 f8 04          	addl   $0x4,0xfffffff8(%ebp)
      sva += PTSIZE;
  1063e0:	81 45 0c 00 00 40 00 	addl   $0x400000,0xc(%ebp)
      dva += PTSIZE;
  1063e7:	81 45 14 00 00 40 00 	addl   $0x400000,0x14(%ebp)
  1063ee:	8b 45 0c             	mov    0xc(%ebp),%eax
  1063f1:	3b 45 f0             	cmp    0xfffffff0(%ebp),%eax
  1063f4:	0f 82 4a fe ff ff    	jb     106244 <pmap_copy+0x1cc>
      }

      return 1;
  1063fa:	b8 01 00 00 00       	mov    $0x1,%eax


}
  1063ff:	c9                   	leave  
  106400:	c3                   	ret    

00106401 <pmap_pagefault>:

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
  106401:	55                   	push   %ebp
  106402:	89 e5                	mov    %esp,%ebp
  106404:	83 ec 48             	sub    $0x48,%esp
static gcc_inline uint32_t
rcr2(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr2,%0" : "=r" (val));
  106407:	0f 20 d0             	mov    %cr2,%eax
  10640a:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
	return val;
  10640d:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
	// Read processor's CR2 register to find the faulting linear address.
	uint32_t fva = rcr2();
  106410:	89 45 d4             	mov    %eax,0xffffffd4(%ebp)
	//cprintf("pmap_pagefault fva %x eip %x\n", fva, tf->eip);


  if (fva < VM_USERLO || fva >= VM_USERHI || !(tf->err & PFE_WR)){
  106413:	81 7d d4 ff ff ff 3f 	cmpl   $0x3fffffff,0xffffffd4(%ebp)
  10641a:	76 16                	jbe    106432 <pmap_pagefault+0x31>
  10641c:	81 7d d4 ff ff ff ef 	cmpl   $0xefffffff,0xffffffd4(%ebp)
  106423:	77 0d                	ja     106432 <pmap_pagefault+0x31>
  106425:	8b 45 08             	mov    0x8(%ebp),%eax
  106428:	8b 40 34             	mov    0x34(%eax),%eax
  10642b:	83 e0 02             	and    $0x2,%eax
  10642e:	85 c0                	test   %eax,%eax
  106430:	75 22                	jne    106454 <pmap_pagefault+0x53>
  cprintf("pmap_pagefault: fva %x err %x\n", fva, tf->err);
  106432:	8b 45 08             	mov    0x8(%ebp),%eax
  106435:	8b 40 34             	mov    0x34(%eax),%eax
  106438:	89 44 24 08          	mov    %eax,0x8(%esp)
  10643c:	8b 45 d4             	mov    0xffffffd4(%ebp),%eax
  10643f:	89 44 24 04          	mov    %eax,0x4(%esp)
  106443:	c7 04 24 fc bc 10 00 	movl   $0x10bcfc,(%esp)
  10644a:	e8 5a 3e 00 00       	call   10a2a9 <cprintf>
    return;
  10644f:	e9 fc 03 00 00       	jmp    106850 <pmap_pagefault+0x44f>
    }


    proc *p = proc_cur();
  106454:	e8 46 eb ff ff       	call   104f9f <cpu_cur>
  106459:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  10645f:	89 45 d8             	mov    %eax,0xffffffd8(%ebp)
    pde_t *pde = &p->pdir[PDX(fva)];
  106462:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  106465:	8b 90 a0 06 00 00    	mov    0x6a0(%eax),%edx
  10646b:	8b 45 d4             	mov    0xffffffd4(%ebp),%eax
  10646e:	c1 e8 16             	shr    $0x16,%eax
  106471:	25 ff 03 00 00       	and    $0x3ff,%eax
  106476:	c1 e0 02             	shl    $0x2,%eax
  106479:	8d 04 02             	lea    (%edx,%eax,1),%eax
  10647c:	89 45 dc             	mov    %eax,0xffffffdc(%ebp)
    if(!(*pde & PTE_P)){
  10647f:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  106482:	8b 00                	mov    (%eax),%eax
  106484:	83 e0 01             	and    $0x1,%eax
  106487:	85 c0                	test   %eax,%eax
  106489:	75 18                	jne    1064a3 <pmap_pagefault+0xa2>
    cprintf("pmap_pagefault: pde for fva %x does not exist\n", fva);
  10648b:	8b 45 d4             	mov    0xffffffd4(%ebp),%eax
  10648e:	89 44 24 04          	mov    %eax,0x4(%esp)
  106492:	c7 04 24 1c bd 10 00 	movl   $0x10bd1c,(%esp)
  106499:	e8 0b 3e 00 00       	call   10a2a9 <cprintf>
      return;
  10649e:	e9 ad 03 00 00       	jmp    106850 <pmap_pagefault+0x44f>
      }

      pte_t *pte = pmap_walk(p->pdir, fva, 1);
  1064a3:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  1064a6:	8b 90 a0 06 00 00    	mov    0x6a0(%eax),%edx
  1064ac:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
  1064b3:	00 
  1064b4:	8b 45 d4             	mov    0xffffffd4(%ebp),%eax
  1064b7:	89 44 24 04          	mov    %eax,0x4(%esp)
  1064bb:	89 14 24             	mov    %edx,(%esp)
  1064be:	e8 9c ee ff ff       	call   10535f <pmap_walk>
  1064c3:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)
      if((*pte & (SYS_READ | SYS_WRITE | PTE_P)) !=
  1064c6:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  1064c9:	8b 00                	mov    (%eax),%eax
  1064cb:	25 01 06 00 00       	and    $0x601,%eax
  1064d0:	3d 01 06 00 00       	cmp    $0x601,%eax
  1064d5:	74 18                	je     1064ef <pmap_pagefault+0xee>
        (SYS_READ | SYS_WRITE | PTE_P)){
        cprintf("pmap_pagefault: page for fva %x does not exist\n", fva);
  1064d7:	8b 45 d4             	mov    0xffffffd4(%ebp),%eax
  1064da:	89 44 24 04          	mov    %eax,0x4(%esp)
  1064de:	c7 04 24 4c bd 10 00 	movl   $0x10bd4c,(%esp)
  1064e5:	e8 bf 3d 00 00       	call   10a2a9 <cprintf>
        return;
  1064ea:	e9 61 03 00 00       	jmp    106850 <pmap_pagefault+0x44f>
        }

    assert(!(*pte & PTE_W));
  1064ef:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  1064f2:	8b 00                	mov    (%eax),%eax
  1064f4:	83 e0 02             	and    $0x2,%eax
  1064f7:	85 c0                	test   %eax,%eax
  1064f9:	74 24                	je     10651f <pmap_pagefault+0x11e>
  1064fb:	c7 44 24 0c 7c bd 10 	movl   $0x10bd7c,0xc(%esp)
  106502:	00 
  106503:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  10650a:	00 
  10650b:	c7 44 24 04 a9 01 00 	movl   $0x1a9,0x4(%esp)
  106512:	00 
  106513:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  10651a:	e8 7d a2 ff ff       	call   10079c <debug_panic>

    uint32_t pg = PGADDR(*pte);
  10651f:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  106522:	8b 00                	mov    (%eax),%eax
  106524:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  106529:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
    if(pg == PTE_ZERO || mem_phys2pi(pg)->refcount > 1){
  10652c:	b8 00 20 12 00       	mov    $0x122000,%eax
  106531:	39 45 e4             	cmp    %eax,0xffffffe4(%ebp)
  106534:	74 1f                	je     106555 <pmap_pagefault+0x154>
  106536:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  106539:	c1 e8 0c             	shr    $0xc,%eax
  10653c:	c1 e0 03             	shl    $0x3,%eax
  10653f:	89 c2                	mov    %eax,%edx
  106541:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  106546:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106549:	8b 40 04             	mov    0x4(%eax),%eax
  10654c:	83 f8 01             	cmp    $0x1,%eax
  10654f:	0f 8e bc 02 00 00    	jle    106811 <pmap_pagefault+0x410>
    pageinfo *npi = mem_alloc();
  106555:	e8 25 a9 ff ff       	call   100e7f <mem_alloc>
  10655a:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
    assert(npi);
  10655d:	83 7d e8 00          	cmpl   $0x0,0xffffffe8(%ebp)
  106561:	75 24                	jne    106587 <pmap_pagefault+0x186>
  106563:	c7 44 24 0c 8c bd 10 	movl   $0x10bd8c,0xc(%esp)
  10656a:	00 
  10656b:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  106572:	00 
  106573:	c7 44 24 04 ae 01 00 	movl   $0x1ae,0x4(%esp)
  10657a:	00 
  10657b:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  106582:	e8 15 a2 ff ff       	call   10079c <debug_panic>
  106587:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  10658a:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
// Atomically increment the reference count on a page.
static gcc_inline void
mem_incref(pageinfo *pi)
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  10658d:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  106592:	83 c0 08             	add    $0x8,%eax
  106595:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  106598:	73 17                	jae    1065b1 <pmap_pagefault+0x1b0>
  10659a:	a1 44 fd 11 00       	mov    0x11fd44,%eax
  10659f:	c1 e0 03             	shl    $0x3,%eax
  1065a2:	89 c2                	mov    %eax,%edx
  1065a4:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  1065a9:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1065ac:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  1065af:	77 24                	ja     1065d5 <pmap_pagefault+0x1d4>
  1065b1:	c7 44 24 0c 14 bb 10 	movl   $0x10bb14,0xc(%esp)
  1065b8:	00 
  1065b9:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  1065c0:	00 
  1065c1:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
  1065c8:	00 
  1065c9:	c7 04 24 4b bb 10 00 	movl   $0x10bb4b,(%esp)
  1065d0:	e8 c7 a1 ff ff       	call   10079c <debug_panic>
	assert(pi != mem_ptr2pi(pmap_zero));	// Don't alloc/free zero page!
  1065d5:	8b 15 9c fd 11 00    	mov    0x11fd9c,%edx
  1065db:	b8 00 20 12 00       	mov    $0x122000,%eax
  1065e0:	c1 e8 0c             	shr    $0xc,%eax
  1065e3:	c1 e0 03             	shl    $0x3,%eax
  1065e6:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1065e9:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  1065ec:	75 24                	jne    106612 <pmap_pagefault+0x211>
  1065ee:	c7 44 24 0c 58 bb 10 	movl   $0x10bb58,0xc(%esp)
  1065f5:	00 
  1065f6:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  1065fd:	00 
  1065fe:	c7 44 24 04 59 00 00 	movl   $0x59,0x4(%esp)
  106605:	00 
  106606:	c7 04 24 4b bb 10 00 	movl   $0x10bb4b,(%esp)
  10660d:	e8 8a a1 ff ff       	call   10079c <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  106612:	8b 15 9c fd 11 00    	mov    0x11fd9c,%edx
  106618:	b8 0c 00 10 00       	mov    $0x10000c,%eax
  10661d:	c1 e8 0c             	shr    $0xc,%eax
  106620:	c1 e0 03             	shl    $0x3,%eax
  106623:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106626:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  106629:	77 40                	ja     10666b <pmap_pagefault+0x26a>
  10662b:	8b 15 9c fd 11 00    	mov    0x11fd9c,%edx
  106631:	b8 08 30 12 00       	mov    $0x123008,%eax
  106636:	83 e8 01             	sub    $0x1,%eax
  106639:	c1 e8 0c             	shr    $0xc,%eax
  10663c:	c1 e0 03             	shl    $0x3,%eax
  10663f:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106642:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  106645:	72 24                	jb     10666b <pmap_pagefault+0x26a>
  106647:	c7 44 24 0c 74 bb 10 	movl   $0x10bb74,0xc(%esp)
  10664e:	00 
  10664f:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  106656:	00 
  106657:	c7 44 24 04 5a 00 00 	movl   $0x5a,0x4(%esp)
  10665e:	00 
  10665f:	c7 04 24 4b bb 10 00 	movl   $0x10bb4b,(%esp)
  106666:	e8 31 a1 ff ff       	call   10079c <debug_panic>

	lockadd(&pi->refcount, 1);
  10666b:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  10666e:	83 c0 04             	add    $0x4,%eax
  106671:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  106678:	00 
  106679:	89 04 24             	mov    %eax,(%esp)
  10667c:	e8 c5 ea ff ff       	call   105146 <lockadd>
    mem_incref(npi);
    uint32_t npg = mem_pi2phys(npi);
  106681:	8b 55 e8             	mov    0xffffffe8(%ebp),%edx
  106684:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  106689:	89 d1                	mov    %edx,%ecx
  10668b:	29 c1                	sub    %eax,%ecx
  10668d:	89 c8                	mov    %ecx,%eax
  10668f:	c1 e0 09             	shl    $0x9,%eax
  106692:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
    memmove((void*)npg, (void*)pg, PAGESIZE);
  106695:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  106698:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
  10669b:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  1066a2:	00 
  1066a3:	89 44 24 04          	mov    %eax,0x4(%esp)
  1066a7:	89 14 24             	mov    %edx,(%esp)
  1066aa:	e8 6b 3e 00 00       	call   10a51a <memmove>
    if(pg != PTE_ZERO)
  1066af:	b8 00 20 12 00       	mov    $0x122000,%eax
  1066b4:	39 45 e4             	cmp    %eax,0xffffffe4(%ebp)
  1066b7:	0f 84 4e 01 00 00    	je     10680b <pmap_pagefault+0x40a>
      mem_decref(mem_phys2pi(pg), mem_free);
  1066bd:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  1066c0:	c1 e8 0c             	shr    $0xc,%eax
  1066c3:	c1 e0 03             	shl    $0x3,%eax
  1066c6:	89 c2                	mov    %eax,%edx
  1066c8:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  1066cd:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1066d0:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  1066d3:	c7 45 f8 c3 0e 10 00 	movl   $0x100ec3,0xfffffff8(%ebp)
// freeing the page with the provided function if there are no more refs.
static gcc_inline void
mem_decref(pageinfo* pi, void (*freefun)(pageinfo *pi))
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  1066da:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  1066df:	83 c0 08             	add    $0x8,%eax
  1066e2:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  1066e5:	73 17                	jae    1066fe <pmap_pagefault+0x2fd>
  1066e7:	a1 44 fd 11 00       	mov    0x11fd44,%eax
  1066ec:	c1 e0 03             	shl    $0x3,%eax
  1066ef:	89 c2                	mov    %eax,%edx
  1066f1:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  1066f6:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1066f9:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  1066fc:	77 24                	ja     106722 <pmap_pagefault+0x321>
  1066fe:	c7 44 24 0c 14 bb 10 	movl   $0x10bb14,0xc(%esp)
  106705:	00 
  106706:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  10670d:	00 
  10670e:	c7 44 24 04 64 00 00 	movl   $0x64,0x4(%esp)
  106715:	00 
  106716:	c7 04 24 4b bb 10 00 	movl   $0x10bb4b,(%esp)
  10671d:	e8 7a a0 ff ff       	call   10079c <debug_panic>
	assert(pi != mem_ptr2pi(pmap_zero));	// Don't alloc/free zero page!
  106722:	8b 15 9c fd 11 00    	mov    0x11fd9c,%edx
  106728:	b8 00 20 12 00       	mov    $0x122000,%eax
  10672d:	c1 e8 0c             	shr    $0xc,%eax
  106730:	c1 e0 03             	shl    $0x3,%eax
  106733:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106736:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  106739:	75 24                	jne    10675f <pmap_pagefault+0x35e>
  10673b:	c7 44 24 0c 58 bb 10 	movl   $0x10bb58,0xc(%esp)
  106742:	00 
  106743:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  10674a:	00 
  10674b:	c7 44 24 04 65 00 00 	movl   $0x65,0x4(%esp)
  106752:	00 
  106753:	c7 04 24 4b bb 10 00 	movl   $0x10bb4b,(%esp)
  10675a:	e8 3d a0 ff ff       	call   10079c <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  10675f:	8b 15 9c fd 11 00    	mov    0x11fd9c,%edx
  106765:	b8 0c 00 10 00       	mov    $0x10000c,%eax
  10676a:	c1 e8 0c             	shr    $0xc,%eax
  10676d:	c1 e0 03             	shl    $0x3,%eax
  106770:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106773:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  106776:	77 40                	ja     1067b8 <pmap_pagefault+0x3b7>
  106778:	8b 15 9c fd 11 00    	mov    0x11fd9c,%edx
  10677e:	b8 08 30 12 00       	mov    $0x123008,%eax
  106783:	83 e8 01             	sub    $0x1,%eax
  106786:	c1 e8 0c             	shr    $0xc,%eax
  106789:	c1 e0 03             	shl    $0x3,%eax
  10678c:	8d 04 02             	lea    (%edx,%eax,1),%eax
  10678f:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  106792:	72 24                	jb     1067b8 <pmap_pagefault+0x3b7>
  106794:	c7 44 24 0c 74 bb 10 	movl   $0x10bb74,0xc(%esp)
  10679b:	00 
  10679c:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  1067a3:	00 
  1067a4:	c7 44 24 04 66 00 00 	movl   $0x66,0x4(%esp)
  1067ab:	00 
  1067ac:	c7 04 24 4b bb 10 00 	movl   $0x10bb4b,(%esp)
  1067b3:	e8 e4 9f ff ff       	call   10079c <debug_panic>

	if (lockaddz(&pi->refcount, -1))
  1067b8:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  1067bb:	83 c0 04             	add    $0x4,%eax
  1067be:	c7 44 24 04 ff ff ff 	movl   $0xffffffff,0x4(%esp)
  1067c5:	ff 
  1067c6:	89 04 24             	mov    %eax,(%esp)
  1067c9:	e8 75 eb ff ff       	call   105343 <lockaddz>
  1067ce:	84 c0                	test   %al,%al
  1067d0:	74 0b                	je     1067dd <pmap_pagefault+0x3dc>
			freefun(pi);
  1067d2:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  1067d5:	89 04 24             	mov    %eax,(%esp)
  1067d8:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1067db:	ff d0                	call   *%eax
	assert(pi->refcount >= 0);
  1067dd:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  1067e0:	8b 40 04             	mov    0x4(%eax),%eax
  1067e3:	85 c0                	test   %eax,%eax
  1067e5:	79 24                	jns    10680b <pmap_pagefault+0x40a>
  1067e7:	c7 44 24 0c a5 bb 10 	movl   $0x10bba5,0xc(%esp)
  1067ee:	00 
  1067ef:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  1067f6:	00 
  1067f7:	c7 44 24 04 6a 00 00 	movl   $0x6a,0x4(%esp)
  1067fe:	00 
  1067ff:	c7 04 24 4b bb 10 00 	movl   $0x10bb4b,(%esp)
  106806:	e8 91 9f ff ff       	call   10079c <debug_panic>
      pg = npg;
  10680b:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  10680e:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
      }

      *pte = pg | SYS_RW | PTE_A | PTE_D | PTE_W | PTE_U | PTE_P;
  106811:	8b 55 e4             	mov    0xffffffe4(%ebp),%edx
  106814:	81 ca 67 06 00 00    	or     $0x667,%edx
  10681a:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  10681d:	89 10                	mov    %edx,(%eax)

      pmap_inval(p->pdir, PGADDR(fva), PAGESIZE);
  10681f:	8b 55 d4             	mov    0xffffffd4(%ebp),%edx
  106822:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
  106828:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  10682b:	8b 80 a0 06 00 00    	mov    0x6a0(%eax),%eax
  106831:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  106838:	00 
  106839:	89 54 24 04          	mov    %edx,0x4(%esp)
  10683d:	89 04 24             	mov    %eax,(%esp)
  106840:	e8 e6 f7 ff ff       	call   10602b <pmap_inval>
      trap_return(tf);
  106845:	8b 45 08             	mov    0x8(%ebp),%eax
  106848:	89 04 24             	mov    %eax,(%esp)
  10684b:	e8 80 c1 ff ff       	call   1029d0 <trap_return>
}
  106850:	c9                   	leave  
  106851:	c3                   	ret    

00106852 <pmap_mergepage>:

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
  106852:	55                   	push   %ebp
  106853:	89 e5                	mov    %esp,%ebp
  106855:	83 ec 48             	sub    $0x48,%esp
  uint8_t *rpg = (uint8_t*)PGADDR(*rpte);
  106858:	8b 45 08             	mov    0x8(%ebp),%eax
  10685b:	8b 00                	mov    (%eax),%eax
  10685d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  106862:	89 45 d4             	mov    %eax,0xffffffd4(%ebp)

  uint8_t *spg = (uint8_t*)PGADDR(*spte);
  106865:	8b 45 0c             	mov    0xc(%ebp),%eax
  106868:	8b 00                	mov    (%eax),%eax
  10686a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  10686f:	89 45 d8             	mov    %eax,0xffffffd8(%ebp)

  uint8_t *dpg = (uint8_t*)PGADDR(*dpte);
  106872:	8b 45 10             	mov    0x10(%ebp),%eax
  106875:	8b 00                	mov    (%eax),%eax
  106877:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  10687c:	89 45 dc             	mov    %eax,0xffffffdc(%ebp)
  if(dpg == pmap_zero) return;
  10687f:	81 7d dc 00 20 12 00 	cmpl   $0x122000,0xffffffdc(%ebp)
  106886:	0f 84 d0 04 00 00    	je     106d5c <pmap_mergepage+0x50a>

  if(dpg == (uint8_t*)PTE_ZERO || mem_ptr2pi(dpg)->refcount > 1){
  10688c:	b8 00 20 12 00       	mov    $0x122000,%eax
  106891:	39 45 dc             	cmp    %eax,0xffffffdc(%ebp)
  106894:	74 1f                	je     1068b5 <pmap_mergepage+0x63>
  106896:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  106899:	c1 e8 0c             	shr    $0xc,%eax
  10689c:	c1 e0 03             	shl    $0x3,%eax
  10689f:	89 c2                	mov    %eax,%edx
  1068a1:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  1068a6:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1068a9:	8b 40 04             	mov    0x4(%eax),%eax
  1068ac:	83 f8 01             	cmp    $0x1,%eax
  1068af:	0f 8e cc 02 00 00    	jle    106b81 <pmap_mergepage+0x32f>
    pageinfo *npi = mem_alloc(); assert(npi);
  1068b5:	e8 c5 a5 ff ff       	call   100e7f <mem_alloc>
  1068ba:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
  1068bd:	83 7d e4 00          	cmpl   $0x0,0xffffffe4(%ebp)
  1068c1:	75 24                	jne    1068e7 <pmap_mergepage+0x95>
  1068c3:	c7 44 24 0c 8c bd 10 	movl   $0x10bd8c,0xc(%esp)
  1068ca:	00 
  1068cb:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  1068d2:	00 
  1068d3:	c7 44 24 04 cf 01 00 	movl   $0x1cf,0x4(%esp)
  1068da:	00 
  1068db:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  1068e2:	e8 b5 9e ff ff       	call   10079c <debug_panic>
  1068e7:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  1068ea:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
// Atomically increment the reference count on a page.
static gcc_inline void
mem_incref(pageinfo *pi)
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  1068ed:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  1068f2:	83 c0 08             	add    $0x8,%eax
  1068f5:	3b 45 ec             	cmp    0xffffffec(%ebp),%eax
  1068f8:	73 17                	jae    106911 <pmap_mergepage+0xbf>
  1068fa:	a1 44 fd 11 00       	mov    0x11fd44,%eax
  1068ff:	c1 e0 03             	shl    $0x3,%eax
  106902:	89 c2                	mov    %eax,%edx
  106904:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  106909:	8d 04 02             	lea    (%edx,%eax,1),%eax
  10690c:	3b 45 ec             	cmp    0xffffffec(%ebp),%eax
  10690f:	77 24                	ja     106935 <pmap_mergepage+0xe3>
  106911:	c7 44 24 0c 14 bb 10 	movl   $0x10bb14,0xc(%esp)
  106918:	00 
  106919:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  106920:	00 
  106921:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
  106928:	00 
  106929:	c7 04 24 4b bb 10 00 	movl   $0x10bb4b,(%esp)
  106930:	e8 67 9e ff ff       	call   10079c <debug_panic>
	assert(pi != mem_ptr2pi(pmap_zero));	// Don't alloc/free zero page!
  106935:	8b 15 9c fd 11 00    	mov    0x11fd9c,%edx
  10693b:	b8 00 20 12 00       	mov    $0x122000,%eax
  106940:	c1 e8 0c             	shr    $0xc,%eax
  106943:	c1 e0 03             	shl    $0x3,%eax
  106946:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106949:	3b 45 ec             	cmp    0xffffffec(%ebp),%eax
  10694c:	75 24                	jne    106972 <pmap_mergepage+0x120>
  10694e:	c7 44 24 0c 58 bb 10 	movl   $0x10bb58,0xc(%esp)
  106955:	00 
  106956:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  10695d:	00 
  10695e:	c7 44 24 04 59 00 00 	movl   $0x59,0x4(%esp)
  106965:	00 
  106966:	c7 04 24 4b bb 10 00 	movl   $0x10bb4b,(%esp)
  10696d:	e8 2a 9e ff ff       	call   10079c <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  106972:	8b 15 9c fd 11 00    	mov    0x11fd9c,%edx
  106978:	b8 0c 00 10 00       	mov    $0x10000c,%eax
  10697d:	c1 e8 0c             	shr    $0xc,%eax
  106980:	c1 e0 03             	shl    $0x3,%eax
  106983:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106986:	3b 45 ec             	cmp    0xffffffec(%ebp),%eax
  106989:	77 40                	ja     1069cb <pmap_mergepage+0x179>
  10698b:	8b 15 9c fd 11 00    	mov    0x11fd9c,%edx
  106991:	b8 08 30 12 00       	mov    $0x123008,%eax
  106996:	83 e8 01             	sub    $0x1,%eax
  106999:	c1 e8 0c             	shr    $0xc,%eax
  10699c:	c1 e0 03             	shl    $0x3,%eax
  10699f:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1069a2:	3b 45 ec             	cmp    0xffffffec(%ebp),%eax
  1069a5:	72 24                	jb     1069cb <pmap_mergepage+0x179>
  1069a7:	c7 44 24 0c 74 bb 10 	movl   $0x10bb74,0xc(%esp)
  1069ae:	00 
  1069af:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  1069b6:	00 
  1069b7:	c7 44 24 04 5a 00 00 	movl   $0x5a,0x4(%esp)
  1069be:	00 
  1069bf:	c7 04 24 4b bb 10 00 	movl   $0x10bb4b,(%esp)
  1069c6:	e8 d1 9d ff ff       	call   10079c <debug_panic>

	lockadd(&pi->refcount, 1);
  1069cb:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  1069ce:	83 c0 04             	add    $0x4,%eax
  1069d1:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  1069d8:	00 
  1069d9:	89 04 24             	mov    %eax,(%esp)
  1069dc:	e8 65 e7 ff ff       	call   105146 <lockadd>
    mem_incref(npi);
    uint8_t *npg = mem_pi2ptr(npi);
  1069e1:	8b 55 e4             	mov    0xffffffe4(%ebp),%edx
  1069e4:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  1069e9:	89 d1                	mov    %edx,%ecx
  1069eb:	29 c1                	sub    %eax,%ecx
  1069ed:	89 c8                	mov    %ecx,%eax
  1069ef:	c1 e0 09             	shl    $0x9,%eax
  1069f2:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
    memmove(npg, dpg, PAGESIZE);
  1069f5:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  1069fc:	00 
  1069fd:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  106a00:	89 44 24 04          	mov    %eax,0x4(%esp)
  106a04:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  106a07:	89 04 24             	mov    %eax,(%esp)
  106a0a:	e8 0b 3b 00 00       	call   10a51a <memmove>
    if(dpg != (uint8_t*)PTE_ZERO)
  106a0f:	b8 00 20 12 00       	mov    $0x122000,%eax
  106a14:	39 45 dc             	cmp    %eax,0xffffffdc(%ebp)
  106a17:	0f 84 4e 01 00 00    	je     106b6b <pmap_mergepage+0x319>
      mem_decref(mem_ptr2pi(dpg), mem_free);
  106a1d:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  106a20:	c1 e8 0c             	shr    $0xc,%eax
  106a23:	c1 e0 03             	shl    $0x3,%eax
  106a26:	89 c2                	mov    %eax,%edx
  106a28:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  106a2d:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106a30:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
  106a33:	c7 45 f0 c3 0e 10 00 	movl   $0x100ec3,0xfffffff0(%ebp)
// freeing the page with the provided function if there are no more refs.
static gcc_inline void
mem_decref(pageinfo* pi, void (*freefun)(pageinfo *pi))
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  106a3a:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  106a3f:	83 c0 08             	add    $0x8,%eax
  106a42:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  106a45:	73 17                	jae    106a5e <pmap_mergepage+0x20c>
  106a47:	a1 44 fd 11 00       	mov    0x11fd44,%eax
  106a4c:	c1 e0 03             	shl    $0x3,%eax
  106a4f:	89 c2                	mov    %eax,%edx
  106a51:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  106a56:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106a59:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  106a5c:	77 24                	ja     106a82 <pmap_mergepage+0x230>
  106a5e:	c7 44 24 0c 14 bb 10 	movl   $0x10bb14,0xc(%esp)
  106a65:	00 
  106a66:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  106a6d:	00 
  106a6e:	c7 44 24 04 64 00 00 	movl   $0x64,0x4(%esp)
  106a75:	00 
  106a76:	c7 04 24 4b bb 10 00 	movl   $0x10bb4b,(%esp)
  106a7d:	e8 1a 9d ff ff       	call   10079c <debug_panic>
	assert(pi != mem_ptr2pi(pmap_zero));	// Don't alloc/free zero page!
  106a82:	8b 15 9c fd 11 00    	mov    0x11fd9c,%edx
  106a88:	b8 00 20 12 00       	mov    $0x122000,%eax
  106a8d:	c1 e8 0c             	shr    $0xc,%eax
  106a90:	c1 e0 03             	shl    $0x3,%eax
  106a93:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106a96:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  106a99:	75 24                	jne    106abf <pmap_mergepage+0x26d>
  106a9b:	c7 44 24 0c 58 bb 10 	movl   $0x10bb58,0xc(%esp)
  106aa2:	00 
  106aa3:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  106aaa:	00 
  106aab:	c7 44 24 04 65 00 00 	movl   $0x65,0x4(%esp)
  106ab2:	00 
  106ab3:	c7 04 24 4b bb 10 00 	movl   $0x10bb4b,(%esp)
  106aba:	e8 dd 9c ff ff       	call   10079c <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  106abf:	8b 15 9c fd 11 00    	mov    0x11fd9c,%edx
  106ac5:	b8 0c 00 10 00       	mov    $0x10000c,%eax
  106aca:	c1 e8 0c             	shr    $0xc,%eax
  106acd:	c1 e0 03             	shl    $0x3,%eax
  106ad0:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106ad3:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  106ad6:	77 40                	ja     106b18 <pmap_mergepage+0x2c6>
  106ad8:	8b 15 9c fd 11 00    	mov    0x11fd9c,%edx
  106ade:	b8 08 30 12 00       	mov    $0x123008,%eax
  106ae3:	83 e8 01             	sub    $0x1,%eax
  106ae6:	c1 e8 0c             	shr    $0xc,%eax
  106ae9:	c1 e0 03             	shl    $0x3,%eax
  106aec:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106aef:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  106af2:	72 24                	jb     106b18 <pmap_mergepage+0x2c6>
  106af4:	c7 44 24 0c 74 bb 10 	movl   $0x10bb74,0xc(%esp)
  106afb:	00 
  106afc:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  106b03:	00 
  106b04:	c7 44 24 04 66 00 00 	movl   $0x66,0x4(%esp)
  106b0b:	00 
  106b0c:	c7 04 24 4b bb 10 00 	movl   $0x10bb4b,(%esp)
  106b13:	e8 84 9c ff ff       	call   10079c <debug_panic>

	if (lockaddz(&pi->refcount, -1))
  106b18:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  106b1b:	83 c0 04             	add    $0x4,%eax
  106b1e:	c7 44 24 04 ff ff ff 	movl   $0xffffffff,0x4(%esp)
  106b25:	ff 
  106b26:	89 04 24             	mov    %eax,(%esp)
  106b29:	e8 15 e8 ff ff       	call   105343 <lockaddz>
  106b2e:	84 c0                	test   %al,%al
  106b30:	74 0b                	je     106b3d <pmap_mergepage+0x2eb>
			freefun(pi);
  106b32:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  106b35:	89 04 24             	mov    %eax,(%esp)
  106b38:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  106b3b:	ff d0                	call   *%eax
	assert(pi->refcount >= 0);
  106b3d:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  106b40:	8b 40 04             	mov    0x4(%eax),%eax
  106b43:	85 c0                	test   %eax,%eax
  106b45:	79 24                	jns    106b6b <pmap_mergepage+0x319>
  106b47:	c7 44 24 0c a5 bb 10 	movl   $0x10bba5,0xc(%esp)
  106b4e:	00 
  106b4f:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  106b56:	00 
  106b57:	c7 44 24 04 6a 00 00 	movl   $0x6a,0x4(%esp)
  106b5e:	00 
  106b5f:	c7 04 24 4b bb 10 00 	movl   $0x10bb4b,(%esp)
  106b66:	e8 31 9c ff ff       	call   10079c <debug_panic>
      dpg = npg;
  106b6b:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  106b6e:	89 45 dc             	mov    %eax,0xffffffdc(%ebp)
      *dpte = (uint32_t)npg | SYS_RW | PTE_A | PTE_D | PTE_W | PTE_U | PTE_P;
  106b71:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  106b74:	89 c2                	mov    %eax,%edx
  106b76:	81 ca 67 06 00 00    	or     $0x667,%edx
  106b7c:	8b 45 10             	mov    0x10(%ebp),%eax
  106b7f:	89 10                	mov    %edx,(%eax)
      }

      int i;
      for(i = 0; i < PAGESIZE; i++){
  106b81:	c7 45 e0 00 00 00 00 	movl   $0x0,0xffffffe0(%ebp)
  106b88:	e9 c2 01 00 00       	jmp    106d4f <pmap_mergepage+0x4fd>
      if(spg[i] == rpg[i])
  106b8d:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  106b90:	03 45 d8             	add    0xffffffd8(%ebp),%eax
  106b93:	0f b6 10             	movzbl (%eax),%edx
  106b96:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  106b99:	03 45 d4             	add    0xffffffd4(%ebp),%eax
  106b9c:	0f b6 00             	movzbl (%eax),%eax
  106b9f:	38 c2                	cmp    %al,%dl
  106ba1:	0f 84 a4 01 00 00    	je     106d4b <pmap_mergepage+0x4f9>
      continue;
      if(dpg[i] == rpg[i]){
  106ba7:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  106baa:	03 45 dc             	add    0xffffffdc(%ebp),%eax
  106bad:	0f b6 10             	movzbl (%eax),%edx
  106bb0:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  106bb3:	03 45 d4             	add    0xffffffd4(%ebp),%eax
  106bb6:	0f b6 00             	movzbl (%eax),%eax
  106bb9:	38 c2                	cmp    %al,%dl
  106bbb:	75 18                	jne    106bd5 <pmap_mergepage+0x383>
      dpg[i] = spg[i];
  106bbd:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  106bc0:	89 c2                	mov    %eax,%edx
  106bc2:	03 55 dc             	add    0xffffffdc(%ebp),%edx
  106bc5:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  106bc8:	03 45 d8             	add    0xffffffd8(%ebp),%eax
  106bcb:	0f b6 00             	movzbl (%eax),%eax
  106bce:	88 02                	mov    %al,(%edx)
      continue;
  106bd0:	e9 76 01 00 00       	jmp    106d4b <pmap_mergepage+0x4f9>
      }

      cprintf("pmap_mergepage: conflict ad dva %x\n", dva);
  106bd5:	8b 45 14             	mov    0x14(%ebp),%eax
  106bd8:	89 44 24 04          	mov    %eax,0x4(%esp)
  106bdc:	c7 04 24 90 bd 10 00 	movl   $0x10bd90,(%esp)
  106be3:	e8 c1 36 00 00       	call   10a2a9 <cprintf>
      mem_decref(mem_phys2pi(PGADDR(*dpte)), mem_free);
  106be8:	8b 45 10             	mov    0x10(%ebp),%eax
  106beb:	8b 00                	mov    (%eax),%eax
  106bed:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  106bf2:	c1 e8 0c             	shr    $0xc,%eax
  106bf5:	c1 e0 03             	shl    $0x3,%eax
  106bf8:	89 c2                	mov    %eax,%edx
  106bfa:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  106bff:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106c02:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  106c05:	c7 45 f8 c3 0e 10 00 	movl   $0x100ec3,0xfffffff8(%ebp)
// freeing the page with the provided function if there are no more refs.
static gcc_inline void
mem_decref(pageinfo* pi, void (*freefun)(pageinfo *pi))
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  106c0c:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  106c11:	83 c0 08             	add    $0x8,%eax
  106c14:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  106c17:	73 17                	jae    106c30 <pmap_mergepage+0x3de>
  106c19:	a1 44 fd 11 00       	mov    0x11fd44,%eax
  106c1e:	c1 e0 03             	shl    $0x3,%eax
  106c21:	89 c2                	mov    %eax,%edx
  106c23:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  106c28:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106c2b:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  106c2e:	77 24                	ja     106c54 <pmap_mergepage+0x402>
  106c30:	c7 44 24 0c 14 bb 10 	movl   $0x10bb14,0xc(%esp)
  106c37:	00 
  106c38:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  106c3f:	00 
  106c40:	c7 44 24 04 64 00 00 	movl   $0x64,0x4(%esp)
  106c47:	00 
  106c48:	c7 04 24 4b bb 10 00 	movl   $0x10bb4b,(%esp)
  106c4f:	e8 48 9b ff ff       	call   10079c <debug_panic>
	assert(pi != mem_ptr2pi(pmap_zero));	// Don't alloc/free zero page!
  106c54:	8b 15 9c fd 11 00    	mov    0x11fd9c,%edx
  106c5a:	b8 00 20 12 00       	mov    $0x122000,%eax
  106c5f:	c1 e8 0c             	shr    $0xc,%eax
  106c62:	c1 e0 03             	shl    $0x3,%eax
  106c65:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106c68:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  106c6b:	75 24                	jne    106c91 <pmap_mergepage+0x43f>
  106c6d:	c7 44 24 0c 58 bb 10 	movl   $0x10bb58,0xc(%esp)
  106c74:	00 
  106c75:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  106c7c:	00 
  106c7d:	c7 44 24 04 65 00 00 	movl   $0x65,0x4(%esp)
  106c84:	00 
  106c85:	c7 04 24 4b bb 10 00 	movl   $0x10bb4b,(%esp)
  106c8c:	e8 0b 9b ff ff       	call   10079c <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  106c91:	8b 15 9c fd 11 00    	mov    0x11fd9c,%edx
  106c97:	b8 0c 00 10 00       	mov    $0x10000c,%eax
  106c9c:	c1 e8 0c             	shr    $0xc,%eax
  106c9f:	c1 e0 03             	shl    $0x3,%eax
  106ca2:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106ca5:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  106ca8:	77 40                	ja     106cea <pmap_mergepage+0x498>
  106caa:	8b 15 9c fd 11 00    	mov    0x11fd9c,%edx
  106cb0:	b8 08 30 12 00       	mov    $0x123008,%eax
  106cb5:	83 e8 01             	sub    $0x1,%eax
  106cb8:	c1 e8 0c             	shr    $0xc,%eax
  106cbb:	c1 e0 03             	shl    $0x3,%eax
  106cbe:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106cc1:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  106cc4:	72 24                	jb     106cea <pmap_mergepage+0x498>
  106cc6:	c7 44 24 0c 74 bb 10 	movl   $0x10bb74,0xc(%esp)
  106ccd:	00 
  106cce:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  106cd5:	00 
  106cd6:	c7 44 24 04 66 00 00 	movl   $0x66,0x4(%esp)
  106cdd:	00 
  106cde:	c7 04 24 4b bb 10 00 	movl   $0x10bb4b,(%esp)
  106ce5:	e8 b2 9a ff ff       	call   10079c <debug_panic>

	if (lockaddz(&pi->refcount, -1))
  106cea:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  106ced:	83 c0 04             	add    $0x4,%eax
  106cf0:	c7 44 24 04 ff ff ff 	movl   $0xffffffff,0x4(%esp)
  106cf7:	ff 
  106cf8:	89 04 24             	mov    %eax,(%esp)
  106cfb:	e8 43 e6 ff ff       	call   105343 <lockaddz>
  106d00:	84 c0                	test   %al,%al
  106d02:	74 0b                	je     106d0f <pmap_mergepage+0x4bd>
			freefun(pi);
  106d04:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  106d07:	89 04 24             	mov    %eax,(%esp)
  106d0a:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  106d0d:	ff d0                	call   *%eax
	assert(pi->refcount >= 0);
  106d0f:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  106d12:	8b 40 04             	mov    0x4(%eax),%eax
  106d15:	85 c0                	test   %eax,%eax
  106d17:	79 24                	jns    106d3d <pmap_mergepage+0x4eb>
  106d19:	c7 44 24 0c a5 bb 10 	movl   $0x10bba5,0xc(%esp)
  106d20:	00 
  106d21:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  106d28:	00 
  106d29:	c7 44 24 04 6a 00 00 	movl   $0x6a,0x4(%esp)
  106d30:	00 
  106d31:	c7 04 24 4b bb 10 00 	movl   $0x10bb4b,(%esp)
  106d38:	e8 5f 9a ff ff       	call   10079c <debug_panic>
      *dpte = PTE_ZERO;
  106d3d:	b8 00 20 12 00       	mov    $0x122000,%eax
  106d42:	89 c2                	mov    %eax,%edx
  106d44:	8b 45 10             	mov    0x10(%ebp),%eax
  106d47:	89 10                	mov    %edx,(%eax)
      return;
  106d49:	eb 11                	jmp    106d5c <pmap_mergepage+0x50a>
  106d4b:	83 45 e0 01          	addl   $0x1,0xffffffe0(%ebp)
  106d4f:	81 7d e0 ff 0f 00 00 	cmpl   $0xfff,0xffffffe0(%ebp)
  106d56:	0f 8e 31 fe ff ff    	jle    106b8d <pmap_mergepage+0x33b>
      }
      
}
  106d5c:	c9                   	leave  
  106d5d:	c3                   	ret    

00106d5e <pmap_merge>:

// 
// Merge differences between a reference snapshot represented by rpdir
// and a source address space spdir into a destination address space dpdir.
//
int
pmap_merge(pde_t *rpdir, pde_t *spdir, uint32_t sva,
		pde_t *dpdir, uint32_t dva, size_t size)
{
  106d5e:	55                   	push   %ebp
  106d5f:	89 e5                	mov    %esp,%ebp
  106d61:	83 ec 48             	sub    $0x48,%esp
	assert(PTOFF(sva) == 0);	// must be 4MB-aligned
  106d64:	8b 45 10             	mov    0x10(%ebp),%eax
  106d67:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  106d6c:	85 c0                	test   %eax,%eax
  106d6e:	74 24                	je     106d94 <pmap_merge+0x36>
  106d70:	c7 44 24 0c 3c bc 10 	movl   $0x10bc3c,0xc(%esp)
  106d77:	00 
  106d78:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  106d7f:	00 
  106d80:	c7 44 24 04 f2 01 00 	movl   $0x1f2,0x4(%esp)
  106d87:	00 
  106d88:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  106d8f:	e8 08 9a ff ff       	call   10079c <debug_panic>
	assert(PTOFF(dva) == 0);
  106d94:	8b 45 18             	mov    0x18(%ebp),%eax
  106d97:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  106d9c:	85 c0                	test   %eax,%eax
  106d9e:	74 24                	je     106dc4 <pmap_merge+0x66>
  106da0:	c7 44 24 0c 4c bc 10 	movl   $0x10bc4c,0xc(%esp)
  106da7:	00 
  106da8:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  106daf:	00 
  106db0:	c7 44 24 04 f3 01 00 	movl   $0x1f3,0x4(%esp)
  106db7:	00 
  106db8:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  106dbf:	e8 d8 99 ff ff       	call   10079c <debug_panic>
	assert(PTOFF(size) == 0);
  106dc4:	8b 45 1c             	mov    0x1c(%ebp),%eax
  106dc7:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  106dcc:	85 c0                	test   %eax,%eax
  106dce:	74 24                	je     106df4 <pmap_merge+0x96>
  106dd0:	c7 44 24 0c 5c bc 10 	movl   $0x10bc5c,0xc(%esp)
  106dd7:	00 
  106dd8:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  106ddf:	00 
  106de0:	c7 44 24 04 f4 01 00 	movl   $0x1f4,0x4(%esp)
  106de7:	00 
  106de8:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  106def:	e8 a8 99 ff ff       	call   10079c <debug_panic>
	assert(sva >= VM_USERLO && sva < VM_USERHI);
  106df4:	81 7d 10 ff ff ff 3f 	cmpl   $0x3fffffff,0x10(%ebp)
  106dfb:	76 09                	jbe    106e06 <pmap_merge+0xa8>
  106dfd:	81 7d 10 ff ff ff ef 	cmpl   $0xefffffff,0x10(%ebp)
  106e04:	76 24                	jbe    106e2a <pmap_merge+0xcc>
  106e06:	c7 44 24 0c 70 bc 10 	movl   $0x10bc70,0xc(%esp)
  106e0d:	00 
  106e0e:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  106e15:	00 
  106e16:	c7 44 24 04 f5 01 00 	movl   $0x1f5,0x4(%esp)
  106e1d:	00 
  106e1e:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  106e25:	e8 72 99 ff ff       	call   10079c <debug_panic>
	assert(dva >= VM_USERLO && dva < VM_USERHI);
  106e2a:	81 7d 18 ff ff ff 3f 	cmpl   $0x3fffffff,0x18(%ebp)
  106e31:	76 09                	jbe    106e3c <pmap_merge+0xde>
  106e33:	81 7d 18 ff ff ff ef 	cmpl   $0xefffffff,0x18(%ebp)
  106e3a:	76 24                	jbe    106e60 <pmap_merge+0x102>
  106e3c:	c7 44 24 0c 94 bc 10 	movl   $0x10bc94,0xc(%esp)
  106e43:	00 
  106e44:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  106e4b:	00 
  106e4c:	c7 44 24 04 f6 01 00 	movl   $0x1f6,0x4(%esp)
  106e53:	00 
  106e54:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  106e5b:	e8 3c 99 ff ff       	call   10079c <debug_panic>
	assert(size <= VM_USERHI - sva);
  106e60:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
  106e65:	2b 45 10             	sub    0x10(%ebp),%eax
  106e68:	3b 45 1c             	cmp    0x1c(%ebp),%eax
  106e6b:	73 24                	jae    106e91 <pmap_merge+0x133>
  106e6d:	c7 44 24 0c b8 bc 10 	movl   $0x10bcb8,0xc(%esp)
  106e74:	00 
  106e75:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  106e7c:	00 
  106e7d:	c7 44 24 04 f7 01 00 	movl   $0x1f7,0x4(%esp)
  106e84:	00 
  106e85:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  106e8c:	e8 0b 99 ff ff       	call   10079c <debug_panic>
	assert(size <= VM_USERHI - dva);
  106e91:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
  106e96:	2b 45 18             	sub    0x18(%ebp),%eax
  106e99:	3b 45 1c             	cmp    0x1c(%ebp),%eax
  106e9c:	73 24                	jae    106ec2 <pmap_merge+0x164>
  106e9e:	c7 44 24 0c d0 bc 10 	movl   $0x10bcd0,0xc(%esp)
  106ea5:	00 
  106ea6:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  106ead:	00 
  106eae:	c7 44 24 04 f8 01 00 	movl   $0x1f8,0x4(%esp)
  106eb5:	00 
  106eb6:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  106ebd:	e8 da 98 ff ff       	call   10079c <debug_panic>

  pde_t *rpde = &rpdir[PDX(sva)];
  106ec2:	8b 45 10             	mov    0x10(%ebp),%eax
  106ec5:	c1 e8 16             	shr    $0x16,%eax
  106ec8:	25 ff 03 00 00       	and    $0x3ff,%eax
  106ecd:	c1 e0 02             	shl    $0x2,%eax
  106ed0:	03 45 08             	add    0x8(%ebp),%eax
  106ed3:	89 45 d4             	mov    %eax,0xffffffd4(%ebp)
  pde_t *spde = &spdir[PDX(sva)];
  106ed6:	8b 45 10             	mov    0x10(%ebp),%eax
  106ed9:	c1 e8 16             	shr    $0x16,%eax
  106edc:	25 ff 03 00 00       	and    $0x3ff,%eax
  106ee1:	c1 e0 02             	shl    $0x2,%eax
  106ee4:	03 45 0c             	add    0xc(%ebp),%eax
  106ee7:	89 45 d8             	mov    %eax,0xffffffd8(%ebp)
  pde_t *dpde = &dpdir[PDX(dva)];
  106eea:	8b 45 18             	mov    0x18(%ebp),%eax
  106eed:	c1 e8 16             	shr    $0x16,%eax
  106ef0:	25 ff 03 00 00       	and    $0x3ff,%eax
  106ef5:	c1 e0 02             	shl    $0x2,%eax
  106ef8:	03 45 14             	add    0x14(%ebp),%eax
  106efb:	89 45 dc             	mov    %eax,0xffffffdc(%ebp)
  uint32_t svahi = sva + size;
  106efe:	8b 45 1c             	mov    0x1c(%ebp),%eax
  106f01:	03 45 10             	add    0x10(%ebp),%eax
  106f04:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)

  for (; sva < svahi; rpde++, spde++, dpde++){
  106f07:	e9 e4 03 00 00       	jmp    1072f0 <pmap_merge+0x592>
  if(*spde == *rpde){
  106f0c:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  106f0f:	8b 10                	mov    (%eax),%edx
  106f11:	8b 45 d4             	mov    0xffffffd4(%ebp),%eax
  106f14:	8b 00                	mov    (%eax),%eax
  106f16:	39 c2                	cmp    %eax,%edx
  106f18:	75 13                	jne    106f2d <pmap_merge+0x1cf>
  sva += PTSIZE, dva += PTSIZE;
  106f1a:	81 45 10 00 00 40 00 	addl   $0x400000,0x10(%ebp)
  106f21:	81 45 18 00 00 40 00 	addl   $0x400000,0x18(%ebp)
  continue;
  106f28:	e9 b7 03 00 00       	jmp    1072e4 <pmap_merge+0x586>
  }

  if(*dpde == *rpde){
  106f2d:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  106f30:	8b 10                	mov    (%eax),%edx
  106f32:	8b 45 d4             	mov    0xffffffd4(%ebp),%eax
  106f35:	8b 00                	mov    (%eax),%eax
  106f37:	39 c2                	cmp    %eax,%edx
  106f39:	75 4b                	jne    106f86 <pmap_merge+0x228>
    if(!pmap_copy(spdir, sva, dpdir, dva, PTSIZE))
  106f3b:	c7 44 24 10 00 00 40 	movl   $0x400000,0x10(%esp)
  106f42:	00 
  106f43:	8b 45 18             	mov    0x18(%ebp),%eax
  106f46:	89 44 24 0c          	mov    %eax,0xc(%esp)
  106f4a:	8b 45 14             	mov    0x14(%ebp),%eax
  106f4d:	89 44 24 08          	mov    %eax,0x8(%esp)
  106f51:	8b 45 10             	mov    0x10(%ebp),%eax
  106f54:	89 44 24 04          	mov    %eax,0x4(%esp)
  106f58:	8b 45 0c             	mov    0xc(%ebp),%eax
  106f5b:	89 04 24             	mov    %eax,(%esp)
  106f5e:	e8 15 f1 ff ff       	call   106078 <pmap_copy>
  106f63:	85 c0                	test   %eax,%eax
  106f65:	75 0c                	jne    106f73 <pmap_merge+0x215>
      return 0;
  106f67:	c7 45 cc 00 00 00 00 	movl   $0x0,0xffffffcc(%ebp)
  106f6e:	e9 90 03 00 00       	jmp    107303 <pmap_merge+0x5a5>
      sva += PTSIZE, dva += PTSIZE;
  106f73:	81 45 10 00 00 40 00 	addl   $0x400000,0x10(%ebp)
  106f7a:	81 45 18 00 00 40 00 	addl   $0x400000,0x18(%ebp)
      continue;
  106f81:	e9 5e 03 00 00       	jmp    1072e4 <pmap_merge+0x586>
      }

      pte_t *rpte = mem_ptr(PGADDR(*rpde));
  106f86:	8b 45 d4             	mov    0xffffffd4(%ebp),%eax
  106f89:	8b 00                	mov    (%eax),%eax
  106f8b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  106f90:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
      pte_t *spte = mem_ptr(PGADDR(*spde));
  106f93:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  106f96:	8b 00                	mov    (%eax),%eax
  106f98:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  106f9d:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
      pte_t *dpte = pmap_walk(dpdir, dva, 1);
  106fa0:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
  106fa7:	00 
  106fa8:	8b 45 18             	mov    0x18(%ebp),%eax
  106fab:	89 44 24 04          	mov    %eax,0x4(%esp)
  106faf:	8b 45 14             	mov    0x14(%ebp),%eax
  106fb2:	89 04 24             	mov    %eax,(%esp)
  106fb5:	e8 a5 e3 ff ff       	call   10535f <pmap_walk>
  106fba:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
      if (dpte == NULL)
  106fbd:	83 7d ec 00          	cmpl   $0x0,0xffffffec(%ebp)
  106fc1:	75 0c                	jne    106fcf <pmap_merge+0x271>
        return 0;
  106fc3:	c7 45 cc 00 00 00 00 	movl   $0x0,0xffffffcc(%ebp)
  106fca:	e9 34 03 00 00       	jmp    107303 <pmap_merge+0x5a5>

        pte_t *erpte = &rpte[NPTENTRIES];
  106fcf:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  106fd2:	05 00 10 00 00       	add    $0x1000,%eax
  106fd7:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
        for(; rpte <erpte; rpte++, spte++, dpte++, sva += PAGESIZE, dva += PAGESIZE){
  106fda:	e9 f9 02 00 00       	jmp    1072d8 <pmap_merge+0x57a>
        
        if (*spte == *rpte)
  106fdf:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  106fe2:	8b 10                	mov    (%eax),%edx
  106fe4:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  106fe7:	8b 00                	mov    (%eax),%eax
  106fe9:	39 c2                	cmp    %eax,%edx
  106feb:	0f 84 cd 02 00 00    	je     1072be <pmap_merge+0x560>
        continue;
        if (*dpte == *rpte)
  106ff1:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  106ff4:	8b 10                	mov    (%eax),%edx
  106ff6:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  106ff9:	8b 00                	mov    (%eax),%eax
  106ffb:	39 c2                	cmp    %eax,%edx
  106ffd:	0f 85 9b 02 00 00    	jne    10729e <pmap_merge+0x540>
        { if(PGADDR(*dpte) != PTE_ZERO)
  107003:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  107006:	8b 00                	mov    (%eax),%eax
  107008:	89 c2                	mov    %eax,%edx
  10700a:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
  107010:	b8 00 20 12 00       	mov    $0x122000,%eax
  107015:	39 c2                	cmp    %eax,%edx
  107017:	0f 84 55 01 00 00    	je     107172 <pmap_merge+0x414>
          mem_decref(mem_phys2pi(PGADDR(*dpte)),mem_free);
  10701d:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  107020:	8b 00                	mov    (%eax),%eax
  107022:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  107027:	c1 e8 0c             	shr    $0xc,%eax
  10702a:	c1 e0 03             	shl    $0x3,%eax
  10702d:	89 c2                	mov    %eax,%edx
  10702f:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  107034:	8d 04 02             	lea    (%edx,%eax,1),%eax
  107037:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  10703a:	c7 45 f4 c3 0e 10 00 	movl   $0x100ec3,0xfffffff4(%ebp)
// freeing the page with the provided function if there are no more refs.
static gcc_inline void
mem_decref(pageinfo* pi, void (*freefun)(pageinfo *pi))
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  107041:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  107046:	83 c0 08             	add    $0x8,%eax
  107049:	3b 45 f8             	cmp    0xfffffff8(%ebp),%eax
  10704c:	73 17                	jae    107065 <pmap_merge+0x307>
  10704e:	a1 44 fd 11 00       	mov    0x11fd44,%eax
  107053:	c1 e0 03             	shl    $0x3,%eax
  107056:	89 c2                	mov    %eax,%edx
  107058:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  10705d:	8d 04 02             	lea    (%edx,%eax,1),%eax
  107060:	3b 45 f8             	cmp    0xfffffff8(%ebp),%eax
  107063:	77 24                	ja     107089 <pmap_merge+0x32b>
  107065:	c7 44 24 0c 14 bb 10 	movl   $0x10bb14,0xc(%esp)
  10706c:	00 
  10706d:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  107074:	00 
  107075:	c7 44 24 04 64 00 00 	movl   $0x64,0x4(%esp)
  10707c:	00 
  10707d:	c7 04 24 4b bb 10 00 	movl   $0x10bb4b,(%esp)
  107084:	e8 13 97 ff ff       	call   10079c <debug_panic>
	assert(pi != mem_ptr2pi(pmap_zero));	// Don't alloc/free zero page!
  107089:	8b 15 9c fd 11 00    	mov    0x11fd9c,%edx
  10708f:	b8 00 20 12 00       	mov    $0x122000,%eax
  107094:	c1 e8 0c             	shr    $0xc,%eax
  107097:	c1 e0 03             	shl    $0x3,%eax
  10709a:	8d 04 02             	lea    (%edx,%eax,1),%eax
  10709d:	3b 45 f8             	cmp    0xfffffff8(%ebp),%eax
  1070a0:	75 24                	jne    1070c6 <pmap_merge+0x368>
  1070a2:	c7 44 24 0c 58 bb 10 	movl   $0x10bb58,0xc(%esp)
  1070a9:	00 
  1070aa:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  1070b1:	00 
  1070b2:	c7 44 24 04 65 00 00 	movl   $0x65,0x4(%esp)
  1070b9:	00 
  1070ba:	c7 04 24 4b bb 10 00 	movl   $0x10bb4b,(%esp)
  1070c1:	e8 d6 96 ff ff       	call   10079c <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  1070c6:	8b 15 9c fd 11 00    	mov    0x11fd9c,%edx
  1070cc:	b8 0c 00 10 00       	mov    $0x10000c,%eax
  1070d1:	c1 e8 0c             	shr    $0xc,%eax
  1070d4:	c1 e0 03             	shl    $0x3,%eax
  1070d7:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1070da:	3b 45 f8             	cmp    0xfffffff8(%ebp),%eax
  1070dd:	77 40                	ja     10711f <pmap_merge+0x3c1>
  1070df:	8b 15 9c fd 11 00    	mov    0x11fd9c,%edx
  1070e5:	b8 08 30 12 00       	mov    $0x123008,%eax
  1070ea:	83 e8 01             	sub    $0x1,%eax
  1070ed:	c1 e8 0c             	shr    $0xc,%eax
  1070f0:	c1 e0 03             	shl    $0x3,%eax
  1070f3:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1070f6:	3b 45 f8             	cmp    0xfffffff8(%ebp),%eax
  1070f9:	72 24                	jb     10711f <pmap_merge+0x3c1>
  1070fb:	c7 44 24 0c 74 bb 10 	movl   $0x10bb74,0xc(%esp)
  107102:	00 
  107103:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  10710a:	00 
  10710b:	c7 44 24 04 66 00 00 	movl   $0x66,0x4(%esp)
  107112:	00 
  107113:	c7 04 24 4b bb 10 00 	movl   $0x10bb4b,(%esp)
  10711a:	e8 7d 96 ff ff       	call   10079c <debug_panic>

	if (lockaddz(&pi->refcount, -1))
  10711f:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  107122:	83 c0 04             	add    $0x4,%eax
  107125:	c7 44 24 04 ff ff ff 	movl   $0xffffffff,0x4(%esp)
  10712c:	ff 
  10712d:	89 04 24             	mov    %eax,(%esp)
  107130:	e8 0e e2 ff ff       	call   105343 <lockaddz>
  107135:	84 c0                	test   %al,%al
  107137:	74 0b                	je     107144 <pmap_merge+0x3e6>
			freefun(pi);
  107139:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10713c:	89 04 24             	mov    %eax,(%esp)
  10713f:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  107142:	ff d0                	call   *%eax
	assert(pi->refcount >= 0);
  107144:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  107147:	8b 40 04             	mov    0x4(%eax),%eax
  10714a:	85 c0                	test   %eax,%eax
  10714c:	79 24                	jns    107172 <pmap_merge+0x414>
  10714e:	c7 44 24 0c a5 bb 10 	movl   $0x10bba5,0xc(%esp)
  107155:	00 
  107156:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  10715d:	00 
  10715e:	c7 44 24 04 6a 00 00 	movl   $0x6a,0x4(%esp)
  107165:	00 
  107166:	c7 04 24 4b bb 10 00 	movl   $0x10bb4b,(%esp)
  10716d:	e8 2a 96 ff ff       	call   10079c <debug_panic>
          *spte &= ~PTE_W;
  107172:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  107175:	8b 00                	mov    (%eax),%eax
  107177:	89 c2                	mov    %eax,%edx
  107179:	83 e2 fd             	and    $0xfffffffd,%edx
  10717c:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  10717f:	89 10                	mov    %edx,(%eax)
          *dpte = *spte;
  107181:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  107184:	8b 10                	mov    (%eax),%edx
  107186:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  107189:	89 10                	mov    %edx,(%eax)
          mem_incref(mem_phys2pi(PGADDR(*spte)));
  10718b:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  10718e:	8b 00                	mov    (%eax),%eax
  107190:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  107195:	c1 e8 0c             	shr    $0xc,%eax
  107198:	c1 e0 03             	shl    $0x3,%eax
  10719b:	89 c2                	mov    %eax,%edx
  10719d:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  1071a2:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1071a5:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
// Atomically increment the reference count on a page.
static gcc_inline void
mem_incref(pageinfo *pi)
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  1071a8:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  1071ad:	83 c0 08             	add    $0x8,%eax
  1071b0:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  1071b3:	73 17                	jae    1071cc <pmap_merge+0x46e>
  1071b5:	a1 44 fd 11 00       	mov    0x11fd44,%eax
  1071ba:	c1 e0 03             	shl    $0x3,%eax
  1071bd:	89 c2                	mov    %eax,%edx
  1071bf:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  1071c4:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1071c7:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  1071ca:	77 24                	ja     1071f0 <pmap_merge+0x492>
  1071cc:	c7 44 24 0c 14 bb 10 	movl   $0x10bb14,0xc(%esp)
  1071d3:	00 
  1071d4:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  1071db:	00 
  1071dc:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
  1071e3:	00 
  1071e4:	c7 04 24 4b bb 10 00 	movl   $0x10bb4b,(%esp)
  1071eb:	e8 ac 95 ff ff       	call   10079c <debug_panic>
	assert(pi != mem_ptr2pi(pmap_zero));	// Don't alloc/free zero page!
  1071f0:	8b 15 9c fd 11 00    	mov    0x11fd9c,%edx
  1071f6:	b8 00 20 12 00       	mov    $0x122000,%eax
  1071fb:	c1 e8 0c             	shr    $0xc,%eax
  1071fe:	c1 e0 03             	shl    $0x3,%eax
  107201:	8d 04 02             	lea    (%edx,%eax,1),%eax
  107204:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  107207:	75 24                	jne    10722d <pmap_merge+0x4cf>
  107209:	c7 44 24 0c 58 bb 10 	movl   $0x10bb58,0xc(%esp)
  107210:	00 
  107211:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  107218:	00 
  107219:	c7 44 24 04 59 00 00 	movl   $0x59,0x4(%esp)
  107220:	00 
  107221:	c7 04 24 4b bb 10 00 	movl   $0x10bb4b,(%esp)
  107228:	e8 6f 95 ff ff       	call   10079c <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  10722d:	8b 15 9c fd 11 00    	mov    0x11fd9c,%edx
  107233:	b8 0c 00 10 00       	mov    $0x10000c,%eax
  107238:	c1 e8 0c             	shr    $0xc,%eax
  10723b:	c1 e0 03             	shl    $0x3,%eax
  10723e:	8d 04 02             	lea    (%edx,%eax,1),%eax
  107241:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  107244:	77 40                	ja     107286 <pmap_merge+0x528>
  107246:	8b 15 9c fd 11 00    	mov    0x11fd9c,%edx
  10724c:	b8 08 30 12 00       	mov    $0x123008,%eax
  107251:	83 e8 01             	sub    $0x1,%eax
  107254:	c1 e8 0c             	shr    $0xc,%eax
  107257:	c1 e0 03             	shl    $0x3,%eax
  10725a:	8d 04 02             	lea    (%edx,%eax,1),%eax
  10725d:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  107260:	72 24                	jb     107286 <pmap_merge+0x528>
  107262:	c7 44 24 0c 74 bb 10 	movl   $0x10bb74,0xc(%esp)
  107269:	00 
  10726a:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  107271:	00 
  107272:	c7 44 24 04 5a 00 00 	movl   $0x5a,0x4(%esp)
  107279:	00 
  10727a:	c7 04 24 4b bb 10 00 	movl   $0x10bb4b,(%esp)
  107281:	e8 16 95 ff ff       	call   10079c <debug_panic>

	lockadd(&pi->refcount, 1);
  107286:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  107289:	83 c0 04             	add    $0x4,%eax
  10728c:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  107293:	00 
  107294:	89 04 24             	mov    %eax,(%esp)
  107297:	e8 aa de ff ff       	call   105146 <lockadd>
          continue;
  10729c:	eb 20                	jmp    1072be <pmap_merge+0x560>
          }
                    

          pmap_mergepage(rpte, spte, dpte, dva);
  10729e:	8b 45 18             	mov    0x18(%ebp),%eax
  1072a1:	89 44 24 0c          	mov    %eax,0xc(%esp)
  1072a5:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  1072a8:	89 44 24 08          	mov    %eax,0x8(%esp)
  1072ac:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  1072af:	89 44 24 04          	mov    %eax,0x4(%esp)
  1072b3:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  1072b6:	89 04 24             	mov    %eax,(%esp)
  1072b9:	e8 94 f5 ff ff       	call   106852 <pmap_mergepage>
  1072be:	83 45 e4 04          	addl   $0x4,0xffffffe4(%ebp)
  1072c2:	83 45 e8 04          	addl   $0x4,0xffffffe8(%ebp)
  1072c6:	83 45 ec 04          	addl   $0x4,0xffffffec(%ebp)
  1072ca:	81 45 10 00 10 00 00 	addl   $0x1000,0x10(%ebp)
  1072d1:	81 45 18 00 10 00 00 	addl   $0x1000,0x18(%ebp)
  1072d8:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  1072db:	3b 45 f0             	cmp    0xfffffff0(%ebp),%eax
  1072de:	0f 82 fb fc ff ff    	jb     106fdf <pmap_merge+0x281>
  1072e4:	83 45 d4 04          	addl   $0x4,0xffffffd4(%ebp)
  1072e8:	83 45 d8 04          	addl   $0x4,0xffffffd8(%ebp)
  1072ec:	83 45 dc 04          	addl   $0x4,0xffffffdc(%ebp)
  1072f0:	8b 45 10             	mov    0x10(%ebp),%eax
  1072f3:	3b 45 e0             	cmp    0xffffffe0(%ebp),%eax
  1072f6:	0f 82 10 fc ff ff    	jb     106f0c <pmap_merge+0x1ae>
         }
         }
          
return 1;
  1072fc:	c7 45 cc 01 00 00 00 	movl   $0x1,0xffffffcc(%ebp)
  107303:	8b 45 cc             	mov    0xffffffcc(%ebp),%eax
}
  107306:	c9                   	leave  
  107307:	c3                   	ret    

00107308 <pmap_setperm>:

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
  107308:	55                   	push   %ebp
  107309:	89 e5                	mov    %esp,%ebp
  10730b:	83 ec 38             	sub    $0x38,%esp
	assert(PGOFF(va) == 0);
  10730e:	8b 45 0c             	mov    0xc(%ebp),%eax
  107311:	25 ff 0f 00 00       	and    $0xfff,%eax
  107316:	85 c0                	test   %eax,%eax
  107318:	74 24                	je     10733e <pmap_setperm+0x36>
  10731a:	c7 44 24 0c b4 bd 10 	movl   $0x10bdb4,0xc(%esp)
  107321:	00 
  107322:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  107329:	00 
  10732a:	c7 44 24 04 33 02 00 	movl   $0x233,0x4(%esp)
  107331:	00 
  107332:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  107339:	e8 5e 94 ff ff       	call   10079c <debug_panic>
	assert(PGOFF(size) == 0);
  10733e:	8b 45 10             	mov    0x10(%ebp),%eax
  107341:	25 ff 0f 00 00       	and    $0xfff,%eax
  107346:	85 c0                	test   %eax,%eax
  107348:	74 24                	je     10736e <pmap_setperm+0x66>
  10734a:	c7 44 24 0c 08 bc 10 	movl   $0x10bc08,0xc(%esp)
  107351:	00 
  107352:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  107359:	00 
  10735a:	c7 44 24 04 34 02 00 	movl   $0x234,0x4(%esp)
  107361:	00 
  107362:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  107369:	e8 2e 94 ff ff       	call   10079c <debug_panic>
	assert(va >= VM_USERLO && va < VM_USERHI);
  10736e:	81 7d 0c ff ff ff 3f 	cmpl   $0x3fffffff,0xc(%ebp)
  107375:	76 09                	jbe    107380 <pmap_setperm+0x78>
  107377:	81 7d 0c ff ff ff ef 	cmpl   $0xefffffff,0xc(%ebp)
  10737e:	76 24                	jbe    1073a4 <pmap_setperm+0x9c>
  107380:	c7 44 24 0c b8 bb 10 	movl   $0x10bbb8,0xc(%esp)
  107387:	00 
  107388:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  10738f:	00 
  107390:	c7 44 24 04 35 02 00 	movl   $0x235,0x4(%esp)
  107397:	00 
  107398:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  10739f:	e8 f8 93 ff ff       	call   10079c <debug_panic>
	assert(size <= VM_USERHI - va);
  1073a4:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
  1073a9:	2b 45 0c             	sub    0xc(%ebp),%eax
  1073ac:	3b 45 10             	cmp    0x10(%ebp),%eax
  1073af:	73 24                	jae    1073d5 <pmap_setperm+0xcd>
  1073b1:	c7 44 24 0c 19 bc 10 	movl   $0x10bc19,0xc(%esp)
  1073b8:	00 
  1073b9:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  1073c0:	00 
  1073c1:	c7 44 24 04 36 02 00 	movl   $0x236,0x4(%esp)
  1073c8:	00 
  1073c9:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  1073d0:	e8 c7 93 ff ff       	call   10079c <debug_panic>
	assert((perm & ~(SYS_RW)) == 0);
  1073d5:	8b 45 14             	mov    0x14(%ebp),%eax
  1073d8:	80 e4 f9             	and    $0xf9,%ah
  1073db:	85 c0                	test   %eax,%eax
  1073dd:	74 24                	je     107403 <pmap_setperm+0xfb>
  1073df:	c7 44 24 0c c3 bd 10 	movl   $0x10bdc3,0xc(%esp)
  1073e6:	00 
  1073e7:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  1073ee:	00 
  1073ef:	c7 44 24 04 37 02 00 	movl   $0x237,0x4(%esp)
  1073f6:	00 
  1073f7:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  1073fe:	e8 99 93 ff ff       	call   10079c <debug_panic>


  pmap_inval(pdir, va, size);
  107403:	8b 45 10             	mov    0x10(%ebp),%eax
  107406:	89 44 24 08          	mov    %eax,0x8(%esp)
  10740a:	8b 45 0c             	mov    0xc(%ebp),%eax
  10740d:	89 44 24 04          	mov    %eax,0x4(%esp)
  107411:	8b 45 08             	mov    0x8(%ebp),%eax
  107414:	89 04 24             	mov    %eax,(%esp)
  107417:	e8 0f ec ff ff       	call   10602b <pmap_inval>

  uint32_t pteand, pteor;
  if(!(perm & SYS_READ))
  10741c:	8b 45 14             	mov    0x14(%ebp),%eax
  10741f:	25 00 02 00 00       	and    $0x200,%eax
  107424:	85 c0                	test   %eax,%eax
  107426:	75 10                	jne    107438 <pmap_setperm+0x130>
    pteand = ~(SYS_RW | PTE_W | PTE_P), pteor = 0;
  107428:	c7 45 ec fc f9 ff ff 	movl   $0xfffff9fc,0xffffffec(%ebp)
  10742f:	c7 45 f0 00 00 00 00 	movl   $0x0,0xfffffff0(%ebp)
  107436:	eb 2a                	jmp    107462 <pmap_setperm+0x15a>
    else if (!(perm & SYS_WRITE))
  107438:	8b 45 14             	mov    0x14(%ebp),%eax
  10743b:	25 00 04 00 00       	and    $0x400,%eax
  107440:	85 c0                	test   %eax,%eax
  107442:	75 10                	jne    107454 <pmap_setperm+0x14c>
    pteand = ~(SYS_WRITE | PTE_W),
  107444:	c7 45 ec fd fb ff ff 	movl   $0xfffffbfd,0xffffffec(%ebp)
  10744b:	c7 45 f0 25 02 00 00 	movl   $0x225,0xfffffff0(%ebp)
  107452:	eb 0e                	jmp    107462 <pmap_setperm+0x15a>
    pteor = (SYS_READ | PTE_U | PTE_P | PTE_A);
    else
    pteand = ~0, pteor = (SYS_RW | PTE_U | PTE_P | PTE_A | PTE_D);
  107454:	c7 45 ec ff ff ff ff 	movl   $0xffffffff,0xffffffec(%ebp)
  10745b:	c7 45 f0 65 06 00 00 	movl   $0x665,0xfffffff0(%ebp)

    uint32_t vahi = va + size;
  107462:	8b 45 10             	mov    0x10(%ebp),%eax
  107465:	03 45 0c             	add    0xc(%ebp),%eax
  107468:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
    while(va < vahi){
  10746b:	e9 9a 00 00 00       	jmp    10750a <pmap_setperm+0x202>
    pde_t *pde = &pdir[PDX(va)];
  107470:	8b 45 0c             	mov    0xc(%ebp),%eax
  107473:	c1 e8 16             	shr    $0x16,%eax
  107476:	25 ff 03 00 00       	and    $0x3ff,%eax
  10747b:	c1 e0 02             	shl    $0x2,%eax
  10747e:	03 45 08             	add    0x8(%ebp),%eax
  107481:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
    if (*pde == PTE_ZERO && pteor == 0){
  107484:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  107487:	8b 10                	mov    (%eax),%edx
  107489:	b8 00 20 12 00       	mov    $0x122000,%eax
  10748e:	39 c2                	cmp    %eax,%edx
  107490:	75 18                	jne    1074aa <pmap_setperm+0x1a2>
  107492:	83 7d f0 00          	cmpl   $0x0,0xfffffff0(%ebp)
  107496:	75 12                	jne    1074aa <pmap_setperm+0x1a2>
    va = PTADDR(va + PTSIZE);
  107498:	8b 45 0c             	mov    0xc(%ebp),%eax
  10749b:	05 00 00 40 00       	add    $0x400000,%eax
  1074a0:	25 00 00 c0 ff       	and    $0xffc00000,%eax
  1074a5:	89 45 0c             	mov    %eax,0xc(%ebp)
    continue;
  1074a8:	eb 60                	jmp    10750a <pmap_setperm+0x202>
    }

    pte_t *pte = pmap_walk(pdir, va, 1);
  1074aa:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
  1074b1:	00 
  1074b2:	8b 45 0c             	mov    0xc(%ebp),%eax
  1074b5:	89 44 24 04          	mov    %eax,0x4(%esp)
  1074b9:	8b 45 08             	mov    0x8(%ebp),%eax
  1074bc:	89 04 24             	mov    %eax,(%esp)
  1074bf:	e8 9b de ff ff       	call   10535f <pmap_walk>
  1074c4:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
    if (pte == NULL)
  1074c7:	83 7d fc 00          	cmpl   $0x0,0xfffffffc(%ebp)
  1074cb:	75 09                	jne    1074d6 <pmap_setperm+0x1ce>
      return 0;
  1074cd:	c7 45 dc 00 00 00 00 	movl   $0x0,0xffffffdc(%ebp)
  1074d4:	eb 47                	jmp    10751d <pmap_setperm+0x215>

    do {
    *pte = (*pte & pteand) | pteor;
  1074d6:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  1074d9:	8b 00                	mov    (%eax),%eax
  1074db:	23 45 ec             	and    0xffffffec(%ebp),%eax
  1074de:	89 c2                	mov    %eax,%edx
  1074e0:	0b 55 f0             	or     0xfffffff0(%ebp),%edx
  1074e3:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  1074e6:	89 10                	mov    %edx,(%eax)
    pte++;
  1074e8:	83 45 fc 04          	addl   $0x4,0xfffffffc(%ebp)
    va += PAGESIZE;
  1074ec:	81 45 0c 00 10 00 00 	addl   $0x1000,0xc(%ebp)
    } while(va < vahi && PTX(va) !=0);
  1074f3:	8b 45 0c             	mov    0xc(%ebp),%eax
  1074f6:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  1074f9:	73 0f                	jae    10750a <pmap_setperm+0x202>
  1074fb:	8b 45 0c             	mov    0xc(%ebp),%eax
  1074fe:	c1 e8 0c             	shr    $0xc,%eax
  107501:	25 ff 03 00 00       	and    $0x3ff,%eax
  107506:	85 c0                	test   %eax,%eax
  107508:	75 cc                	jne    1074d6 <pmap_setperm+0x1ce>
  10750a:	8b 45 0c             	mov    0xc(%ebp),%eax
  10750d:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  107510:	0f 82 5a ff ff ff    	jb     107470 <pmap_setperm+0x168>
    }
    return 1;
  107516:	c7 45 dc 01 00 00 00 	movl   $0x1,0xffffffdc(%ebp)
  10751d:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax




}
  107520:	c9                   	leave  
  107521:	c3                   	ret    

00107522 <va2pa>:

//
// This function returns the physical address of the page containing 'va',
// defined by the page directory 'pdir'.  The hardware normally performs
// this functionality for us!  We define our own version to help check
// the pmap_check() function; it shouldn't be used elsewhere.
//
static uint32_t
va2pa(pde_t *pdir, uintptr_t va)
{
  107522:	55                   	push   %ebp
  107523:	89 e5                	mov    %esp,%ebp
  107525:	83 ec 14             	sub    $0x14,%esp
	pdir = &pdir[PDX(va)];
  107528:	8b 45 0c             	mov    0xc(%ebp),%eax
  10752b:	c1 e8 16             	shr    $0x16,%eax
  10752e:	25 ff 03 00 00       	and    $0x3ff,%eax
  107533:	c1 e0 02             	shl    $0x2,%eax
  107536:	01 45 08             	add    %eax,0x8(%ebp)
	if (!(*pdir & PTE_P))
  107539:	8b 45 08             	mov    0x8(%ebp),%eax
  10753c:	8b 00                	mov    (%eax),%eax
  10753e:	83 e0 01             	and    $0x1,%eax
  107541:	85 c0                	test   %eax,%eax
  107543:	75 09                	jne    10754e <va2pa+0x2c>
		return ~0;
  107545:	c7 45 ec ff ff ff ff 	movl   $0xffffffff,0xffffffec(%ebp)
  10754c:	eb 4e                	jmp    10759c <va2pa+0x7a>
	pte_t *ptab = mem_ptr(PGADDR(*pdir));
  10754e:	8b 45 08             	mov    0x8(%ebp),%eax
  107551:	8b 00                	mov    (%eax),%eax
  107553:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  107558:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	if (!(ptab[PTX(va)] & PTE_P))
  10755b:	8b 45 0c             	mov    0xc(%ebp),%eax
  10755e:	c1 e8 0c             	shr    $0xc,%eax
  107561:	25 ff 03 00 00       	and    $0x3ff,%eax
  107566:	c1 e0 02             	shl    $0x2,%eax
  107569:	03 45 fc             	add    0xfffffffc(%ebp),%eax
  10756c:	8b 00                	mov    (%eax),%eax
  10756e:	83 e0 01             	and    $0x1,%eax
  107571:	85 c0                	test   %eax,%eax
  107573:	75 09                	jne    10757e <va2pa+0x5c>
		return ~0;
  107575:	c7 45 ec ff ff ff ff 	movl   $0xffffffff,0xffffffec(%ebp)
  10757c:	eb 1e                	jmp    10759c <va2pa+0x7a>
	return PGADDR(ptab[PTX(va)]);
  10757e:	8b 45 0c             	mov    0xc(%ebp),%eax
  107581:	c1 e8 0c             	shr    $0xc,%eax
  107584:	25 ff 03 00 00       	and    $0x3ff,%eax
  107589:	c1 e0 02             	shl    $0x2,%eax
  10758c:	03 45 fc             	add    0xfffffffc(%ebp),%eax
  10758f:	8b 00                	mov    (%eax),%eax
  107591:	89 c2                	mov    %eax,%edx
  107593:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
  107599:	89 55 ec             	mov    %edx,0xffffffec(%ebp)
  10759c:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
}
  10759f:	c9                   	leave  
  1075a0:	c3                   	ret    

001075a1 <pmap_check>:

// check pmap_insert, pmap_remove, &c
void
pmap_check(void)
{
  1075a1:	55                   	push   %ebp
  1075a2:	89 e5                	mov    %esp,%ebp
  1075a4:	53                   	push   %ebx
  1075a5:	83 ec 44             	sub    $0x44,%esp
	extern pageinfo *mem_freelist;

	pageinfo *pi, *pi0, *pi1, *pi2, *pi3;
	pageinfo *fl;
	pte_t *ptep, *ptep1;
	int i;

	// should be able to allocate three pages
	pi0 = pi1 = pi2 = 0;
  1075a8:	c7 45 e0 00 00 00 00 	movl   $0x0,0xffffffe0(%ebp)
  1075af:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  1075b2:	89 45 dc             	mov    %eax,0xffffffdc(%ebp)
  1075b5:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  1075b8:	89 45 d8             	mov    %eax,0xffffffd8(%ebp)
	pi0 = mem_alloc();
  1075bb:	e8 bf 98 ff ff       	call   100e7f <mem_alloc>
  1075c0:	89 45 d8             	mov    %eax,0xffffffd8(%ebp)
	pi1 = mem_alloc();
  1075c3:	e8 b7 98 ff ff       	call   100e7f <mem_alloc>
  1075c8:	89 45 dc             	mov    %eax,0xffffffdc(%ebp)
	pi2 = mem_alloc();
  1075cb:	e8 af 98 ff ff       	call   100e7f <mem_alloc>
  1075d0:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)
	pi3 = mem_alloc();
  1075d3:	e8 a7 98 ff ff       	call   100e7f <mem_alloc>
  1075d8:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)

	assert(pi0);
  1075db:	83 7d d8 00          	cmpl   $0x0,0xffffffd8(%ebp)
  1075df:	75 24                	jne    107605 <pmap_check+0x64>
  1075e1:	c7 44 24 0c db bd 10 	movl   $0x10bddb,0xc(%esp)
  1075e8:	00 
  1075e9:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  1075f0:	00 
  1075f1:	c7 44 24 04 82 02 00 	movl   $0x282,0x4(%esp)
  1075f8:	00 
  1075f9:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  107600:	e8 97 91 ff ff       	call   10079c <debug_panic>
	assert(pi1 && pi1 != pi0);
  107605:	83 7d dc 00          	cmpl   $0x0,0xffffffdc(%ebp)
  107609:	74 08                	je     107613 <pmap_check+0x72>
  10760b:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  10760e:	3b 45 d8             	cmp    0xffffffd8(%ebp),%eax
  107611:	75 24                	jne    107637 <pmap_check+0x96>
  107613:	c7 44 24 0c df bd 10 	movl   $0x10bddf,0xc(%esp)
  10761a:	00 
  10761b:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  107622:	00 
  107623:	c7 44 24 04 83 02 00 	movl   $0x283,0x4(%esp)
  10762a:	00 
  10762b:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  107632:	e8 65 91 ff ff       	call   10079c <debug_panic>
	assert(pi2 && pi2 != pi1 && pi2 != pi0);
  107637:	83 7d e0 00          	cmpl   $0x0,0xffffffe0(%ebp)
  10763b:	74 10                	je     10764d <pmap_check+0xac>
  10763d:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  107640:	3b 45 dc             	cmp    0xffffffdc(%ebp),%eax
  107643:	74 08                	je     10764d <pmap_check+0xac>
  107645:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  107648:	3b 45 d8             	cmp    0xffffffd8(%ebp),%eax
  10764b:	75 24                	jne    107671 <pmap_check+0xd0>
  10764d:	c7 44 24 0c f4 bd 10 	movl   $0x10bdf4,0xc(%esp)
  107654:	00 
  107655:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  10765c:	00 
  10765d:	c7 44 24 04 84 02 00 	movl   $0x284,0x4(%esp)
  107664:	00 
  107665:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  10766c:	e8 2b 91 ff ff       	call   10079c <debug_panic>

	// temporarily steal the rest of the free pages
	fl = mem_freelist;
  107671:	a1 40 fd 11 00       	mov    0x11fd40,%eax
  107676:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
	mem_freelist = NULL;
  107679:	c7 05 40 fd 11 00 00 	movl   $0x0,0x11fd40
  107680:	00 00 00 

	// should be no free memory
	assert(mem_alloc() == NULL);
  107683:	e8 f7 97 ff ff       	call   100e7f <mem_alloc>
  107688:	85 c0                	test   %eax,%eax
  10768a:	74 24                	je     1076b0 <pmap_check+0x10f>
  10768c:	c7 44 24 0c 14 be 10 	movl   $0x10be14,0xc(%esp)
  107693:	00 
  107694:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  10769b:	00 
  10769c:	c7 44 24 04 8b 02 00 	movl   $0x28b,0x4(%esp)
  1076a3:	00 
  1076a4:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  1076ab:	e8 ec 90 ff ff       	call   10079c <debug_panic>

	// there is no free memory, so we can't allocate a page table 
	assert(pmap_insert(pmap_bootpdir, pi1, VM_USERLO, 0) == NULL);
  1076b0:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  1076b7:	00 
  1076b8:	c7 44 24 08 00 00 00 	movl   $0x40000000,0x8(%esp)
  1076bf:	40 
  1076c0:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  1076c3:	89 44 24 04          	mov    %eax,0x4(%esp)
  1076c7:	c7 04 24 00 10 12 00 	movl   $0x121000,(%esp)
  1076ce:	e8 44 e3 ff ff       	call   105a17 <pmap_insert>
  1076d3:	85 c0                	test   %eax,%eax
  1076d5:	74 24                	je     1076fb <pmap_check+0x15a>
  1076d7:	c7 44 24 0c 28 be 10 	movl   $0x10be28,0xc(%esp)
  1076de:	00 
  1076df:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  1076e6:	00 
  1076e7:	c7 44 24 04 8e 02 00 	movl   $0x28e,0x4(%esp)
  1076ee:	00 
  1076ef:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  1076f6:	e8 a1 90 ff ff       	call   10079c <debug_panic>

	// free pi0 and try again: pi0 should be used for page table
	mem_free(pi0);
  1076fb:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  1076fe:	89 04 24             	mov    %eax,(%esp)
  107701:	e8 bd 97 ff ff       	call   100ec3 <mem_free>
	assert(pmap_insert(pmap_bootpdir, pi1, VM_USERLO, 0) != NULL);
  107706:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  10770d:	00 
  10770e:	c7 44 24 08 00 00 00 	movl   $0x40000000,0x8(%esp)
  107715:	40 
  107716:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  107719:	89 44 24 04          	mov    %eax,0x4(%esp)
  10771d:	c7 04 24 00 10 12 00 	movl   $0x121000,(%esp)
  107724:	e8 ee e2 ff ff       	call   105a17 <pmap_insert>
  107729:	85 c0                	test   %eax,%eax
  10772b:	75 24                	jne    107751 <pmap_check+0x1b0>
  10772d:	c7 44 24 0c 60 be 10 	movl   $0x10be60,0xc(%esp)
  107734:	00 
  107735:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  10773c:	00 
  10773d:	c7 44 24 04 92 02 00 	movl   $0x292,0x4(%esp)
  107744:	00 
  107745:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  10774c:	e8 4b 90 ff ff       	call   10079c <debug_panic>
	assert(PGADDR(pmap_bootpdir[PDX(VM_USERLO)]) == mem_pi2phys(pi0));
  107751:	a1 00 14 12 00       	mov    0x121400,%eax
  107756:	89 c1                	mov    %eax,%ecx
  107758:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
  10775e:	8b 55 d8             	mov    0xffffffd8(%ebp),%edx
  107761:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  107766:	89 d3                	mov    %edx,%ebx
  107768:	29 c3                	sub    %eax,%ebx
  10776a:	89 d8                	mov    %ebx,%eax
  10776c:	c1 e0 09             	shl    $0x9,%eax
  10776f:	39 c1                	cmp    %eax,%ecx
  107771:	74 24                	je     107797 <pmap_check+0x1f6>
  107773:	c7 44 24 0c 98 be 10 	movl   $0x10be98,0xc(%esp)
  10777a:	00 
  10777b:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  107782:	00 
  107783:	c7 44 24 04 93 02 00 	movl   $0x293,0x4(%esp)
  10778a:	00 
  10778b:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  107792:	e8 05 90 ff ff       	call   10079c <debug_panic>
	assert(va2pa(pmap_bootpdir, VM_USERLO) == mem_pi2phys(pi1));
  107797:	c7 44 24 04 00 00 00 	movl   $0x40000000,0x4(%esp)
  10779e:	40 
  10779f:	c7 04 24 00 10 12 00 	movl   $0x121000,(%esp)
  1077a6:	e8 77 fd ff ff       	call   107522 <va2pa>
  1077ab:	89 c1                	mov    %eax,%ecx
  1077ad:	8b 55 dc             	mov    0xffffffdc(%ebp),%edx
  1077b0:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  1077b5:	89 d3                	mov    %edx,%ebx
  1077b7:	29 c3                	sub    %eax,%ebx
  1077b9:	89 d8                	mov    %ebx,%eax
  1077bb:	c1 e0 09             	shl    $0x9,%eax
  1077be:	39 c1                	cmp    %eax,%ecx
  1077c0:	74 24                	je     1077e6 <pmap_check+0x245>
  1077c2:	c7 44 24 0c d4 be 10 	movl   $0x10bed4,0xc(%esp)
  1077c9:	00 
  1077ca:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  1077d1:	00 
  1077d2:	c7 44 24 04 94 02 00 	movl   $0x294,0x4(%esp)
  1077d9:	00 
  1077da:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  1077e1:	e8 b6 8f ff ff       	call   10079c <debug_panic>
	assert(pi1->refcount == 1);
  1077e6:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  1077e9:	8b 40 04             	mov    0x4(%eax),%eax
  1077ec:	83 f8 01             	cmp    $0x1,%eax
  1077ef:	74 24                	je     107815 <pmap_check+0x274>
  1077f1:	c7 44 24 0c 08 bf 10 	movl   $0x10bf08,0xc(%esp)
  1077f8:	00 
  1077f9:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  107800:	00 
  107801:	c7 44 24 04 95 02 00 	movl   $0x295,0x4(%esp)
  107808:	00 
  107809:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  107810:	e8 87 8f ff ff       	call   10079c <debug_panic>
	assert(pi0->refcount == 1);
  107815:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  107818:	8b 40 04             	mov    0x4(%eax),%eax
  10781b:	83 f8 01             	cmp    $0x1,%eax
  10781e:	74 24                	je     107844 <pmap_check+0x2a3>
  107820:	c7 44 24 0c 1b bf 10 	movl   $0x10bf1b,0xc(%esp)
  107827:	00 
  107828:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  10782f:	00 
  107830:	c7 44 24 04 96 02 00 	movl   $0x296,0x4(%esp)
  107837:	00 
  107838:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  10783f:	e8 58 8f ff ff       	call   10079c <debug_panic>

	// should be able to map pi2 at VM_USERLO+PAGESIZE
	// because pi0 is already allocated for page table
	assert(pmap_insert(pmap_bootpdir, pi2, VM_USERLO+PAGESIZE, 0));
  107844:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  10784b:	00 
  10784c:	c7 44 24 08 00 10 00 	movl   $0x40001000,0x8(%esp)
  107853:	40 
  107854:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  107857:	89 44 24 04          	mov    %eax,0x4(%esp)
  10785b:	c7 04 24 00 10 12 00 	movl   $0x121000,(%esp)
  107862:	e8 b0 e1 ff ff       	call   105a17 <pmap_insert>
  107867:	85 c0                	test   %eax,%eax
  107869:	75 24                	jne    10788f <pmap_check+0x2ee>
  10786b:	c7 44 24 0c 30 bf 10 	movl   $0x10bf30,0xc(%esp)
  107872:	00 
  107873:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  10787a:	00 
  10787b:	c7 44 24 04 9a 02 00 	movl   $0x29a,0x4(%esp)
  107882:	00 
  107883:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  10788a:	e8 0d 8f ff ff       	call   10079c <debug_panic>
	assert(va2pa(pmap_bootpdir, VM_USERLO+PAGESIZE) == mem_pi2phys(pi2));
  10788f:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  107896:	40 
  107897:	c7 04 24 00 10 12 00 	movl   $0x121000,(%esp)
  10789e:	e8 7f fc ff ff       	call   107522 <va2pa>
  1078a3:	89 c1                	mov    %eax,%ecx
  1078a5:	8b 55 e0             	mov    0xffffffe0(%ebp),%edx
  1078a8:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  1078ad:	89 d3                	mov    %edx,%ebx
  1078af:	29 c3                	sub    %eax,%ebx
  1078b1:	89 d8                	mov    %ebx,%eax
  1078b3:	c1 e0 09             	shl    $0x9,%eax
  1078b6:	39 c1                	cmp    %eax,%ecx
  1078b8:	74 24                	je     1078de <pmap_check+0x33d>
  1078ba:	c7 44 24 0c 68 bf 10 	movl   $0x10bf68,0xc(%esp)
  1078c1:	00 
  1078c2:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  1078c9:	00 
  1078ca:	c7 44 24 04 9b 02 00 	movl   $0x29b,0x4(%esp)
  1078d1:	00 
  1078d2:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  1078d9:	e8 be 8e ff ff       	call   10079c <debug_panic>
	assert(pi2->refcount == 1);
  1078de:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  1078e1:	8b 40 04             	mov    0x4(%eax),%eax
  1078e4:	83 f8 01             	cmp    $0x1,%eax
  1078e7:	74 24                	je     10790d <pmap_check+0x36c>
  1078e9:	c7 44 24 0c a5 bf 10 	movl   $0x10bfa5,0xc(%esp)
  1078f0:	00 
  1078f1:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  1078f8:	00 
  1078f9:	c7 44 24 04 9c 02 00 	movl   $0x29c,0x4(%esp)
  107900:	00 
  107901:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  107908:	e8 8f 8e ff ff       	call   10079c <debug_panic>

	// should be no free memory
	assert(mem_alloc() == NULL);
  10790d:	e8 6d 95 ff ff       	call   100e7f <mem_alloc>
  107912:	85 c0                	test   %eax,%eax
  107914:	74 24                	je     10793a <pmap_check+0x399>
  107916:	c7 44 24 0c 14 be 10 	movl   $0x10be14,0xc(%esp)
  10791d:	00 
  10791e:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  107925:	00 
  107926:	c7 44 24 04 9f 02 00 	movl   $0x29f,0x4(%esp)
  10792d:	00 
  10792e:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  107935:	e8 62 8e ff ff       	call   10079c <debug_panic>

	// should be able to map pi2 at VM_USERLO+PAGESIZE
	// because it's already there
	assert(pmap_insert(pmap_bootpdir, pi2, VM_USERLO+PAGESIZE, 0));
  10793a:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  107941:	00 
  107942:	c7 44 24 08 00 10 00 	movl   $0x40001000,0x8(%esp)
  107949:	40 
  10794a:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  10794d:	89 44 24 04          	mov    %eax,0x4(%esp)
  107951:	c7 04 24 00 10 12 00 	movl   $0x121000,(%esp)
  107958:	e8 ba e0 ff ff       	call   105a17 <pmap_insert>
  10795d:	85 c0                	test   %eax,%eax
  10795f:	75 24                	jne    107985 <pmap_check+0x3e4>
  107961:	c7 44 24 0c 30 bf 10 	movl   $0x10bf30,0xc(%esp)
  107968:	00 
  107969:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  107970:	00 
  107971:	c7 44 24 04 a3 02 00 	movl   $0x2a3,0x4(%esp)
  107978:	00 
  107979:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  107980:	e8 17 8e ff ff       	call   10079c <debug_panic>
	assert(va2pa(pmap_bootpdir, VM_USERLO+PAGESIZE) == mem_pi2phys(pi2));
  107985:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  10798c:	40 
  10798d:	c7 04 24 00 10 12 00 	movl   $0x121000,(%esp)
  107994:	e8 89 fb ff ff       	call   107522 <va2pa>
  107999:	89 c1                	mov    %eax,%ecx
  10799b:	8b 55 e0             	mov    0xffffffe0(%ebp),%edx
  10799e:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  1079a3:	89 d3                	mov    %edx,%ebx
  1079a5:	29 c3                	sub    %eax,%ebx
  1079a7:	89 d8                	mov    %ebx,%eax
  1079a9:	c1 e0 09             	shl    $0x9,%eax
  1079ac:	39 c1                	cmp    %eax,%ecx
  1079ae:	74 24                	je     1079d4 <pmap_check+0x433>
  1079b0:	c7 44 24 0c 68 bf 10 	movl   $0x10bf68,0xc(%esp)
  1079b7:	00 
  1079b8:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  1079bf:	00 
  1079c0:	c7 44 24 04 a4 02 00 	movl   $0x2a4,0x4(%esp)
  1079c7:	00 
  1079c8:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  1079cf:	e8 c8 8d ff ff       	call   10079c <debug_panic>
	assert(pi2->refcount == 1);
  1079d4:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  1079d7:	8b 40 04             	mov    0x4(%eax),%eax
  1079da:	83 f8 01             	cmp    $0x1,%eax
  1079dd:	74 24                	je     107a03 <pmap_check+0x462>
  1079df:	c7 44 24 0c a5 bf 10 	movl   $0x10bfa5,0xc(%esp)
  1079e6:	00 
  1079e7:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  1079ee:	00 
  1079ef:	c7 44 24 04 a5 02 00 	movl   $0x2a5,0x4(%esp)
  1079f6:	00 
  1079f7:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  1079fe:	e8 99 8d ff ff       	call   10079c <debug_panic>

	// pi2 should NOT be on the free list
	// could hapien in ref counts are handled slopiily in pmap_insert
	assert(mem_alloc() == NULL);
  107a03:	e8 77 94 ff ff       	call   100e7f <mem_alloc>
  107a08:	85 c0                	test   %eax,%eax
  107a0a:	74 24                	je     107a30 <pmap_check+0x48f>
  107a0c:	c7 44 24 0c 14 be 10 	movl   $0x10be14,0xc(%esp)
  107a13:	00 
  107a14:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  107a1b:	00 
  107a1c:	c7 44 24 04 a9 02 00 	movl   $0x2a9,0x4(%esp)
  107a23:	00 
  107a24:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  107a2b:	e8 6c 8d ff ff       	call   10079c <debug_panic>

	// check that pmap_walk returns a pointer to the pte
	ptep = mem_ptr(PGADDR(pmap_bootpdir[PDX(VM_USERLO+PAGESIZE)]));
  107a30:	a1 00 14 12 00       	mov    0x121400,%eax
  107a35:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  107a3a:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
	assert(pmap_walk(pmap_bootpdir, VM_USERLO+PAGESIZE, 0)
  107a3d:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  107a44:	00 
  107a45:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  107a4c:	40 
  107a4d:	c7 04 24 00 10 12 00 	movl   $0x121000,(%esp)
  107a54:	e8 06 d9 ff ff       	call   10535f <pmap_walk>
  107a59:	89 c2                	mov    %eax,%edx
  107a5b:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  107a5e:	83 c0 04             	add    $0x4,%eax
  107a61:	39 c2                	cmp    %eax,%edx
  107a63:	74 24                	je     107a89 <pmap_check+0x4e8>
  107a65:	c7 44 24 0c b8 bf 10 	movl   $0x10bfb8,0xc(%esp)
  107a6c:	00 
  107a6d:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  107a74:	00 
  107a75:	c7 44 24 04 ae 02 00 	movl   $0x2ae,0x4(%esp)
  107a7c:	00 
  107a7d:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  107a84:	e8 13 8d ff ff       	call   10079c <debug_panic>
		== ptep+PTX(VM_USERLO+PAGESIZE));

	// should be able to change permissions too.
	assert(pmap_insert(pmap_bootpdir, pi2, VM_USERLO+PAGESIZE, PTE_U));
  107a89:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
  107a90:	00 
  107a91:	c7 44 24 08 00 10 00 	movl   $0x40001000,0x8(%esp)
  107a98:	40 
  107a99:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  107a9c:	89 44 24 04          	mov    %eax,0x4(%esp)
  107aa0:	c7 04 24 00 10 12 00 	movl   $0x121000,(%esp)
  107aa7:	e8 6b df ff ff       	call   105a17 <pmap_insert>
  107aac:	85 c0                	test   %eax,%eax
  107aae:	75 24                	jne    107ad4 <pmap_check+0x533>
  107ab0:	c7 44 24 0c 08 c0 10 	movl   $0x10c008,0xc(%esp)
  107ab7:	00 
  107ab8:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  107abf:	00 
  107ac0:	c7 44 24 04 b1 02 00 	movl   $0x2b1,0x4(%esp)
  107ac7:	00 
  107ac8:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  107acf:	e8 c8 8c ff ff       	call   10079c <debug_panic>
	assert(va2pa(pmap_bootpdir, VM_USERLO+PAGESIZE) == mem_pi2phys(pi2));
  107ad4:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  107adb:	40 
  107adc:	c7 04 24 00 10 12 00 	movl   $0x121000,(%esp)
  107ae3:	e8 3a fa ff ff       	call   107522 <va2pa>
  107ae8:	89 c1                	mov    %eax,%ecx
  107aea:	8b 55 e0             	mov    0xffffffe0(%ebp),%edx
  107aed:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  107af2:	89 d3                	mov    %edx,%ebx
  107af4:	29 c3                	sub    %eax,%ebx
  107af6:	89 d8                	mov    %ebx,%eax
  107af8:	c1 e0 09             	shl    $0x9,%eax
  107afb:	39 c1                	cmp    %eax,%ecx
  107afd:	74 24                	je     107b23 <pmap_check+0x582>
  107aff:	c7 44 24 0c 68 bf 10 	movl   $0x10bf68,0xc(%esp)
  107b06:	00 
  107b07:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  107b0e:	00 
  107b0f:	c7 44 24 04 b2 02 00 	movl   $0x2b2,0x4(%esp)
  107b16:	00 
  107b17:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  107b1e:	e8 79 8c ff ff       	call   10079c <debug_panic>
	assert(pi2->refcount == 1);
  107b23:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  107b26:	8b 40 04             	mov    0x4(%eax),%eax
  107b29:	83 f8 01             	cmp    $0x1,%eax
  107b2c:	74 24                	je     107b52 <pmap_check+0x5b1>
  107b2e:	c7 44 24 0c a5 bf 10 	movl   $0x10bfa5,0xc(%esp)
  107b35:	00 
  107b36:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  107b3d:	00 
  107b3e:	c7 44 24 04 b3 02 00 	movl   $0x2b3,0x4(%esp)
  107b45:	00 
  107b46:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  107b4d:	e8 4a 8c ff ff       	call   10079c <debug_panic>
	assert(*pmap_walk(pmap_bootpdir, VM_USERLO+PAGESIZE, 0) & PTE_U);
  107b52:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  107b59:	00 
  107b5a:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  107b61:	40 
  107b62:	c7 04 24 00 10 12 00 	movl   $0x121000,(%esp)
  107b69:	e8 f1 d7 ff ff       	call   10535f <pmap_walk>
  107b6e:	8b 00                	mov    (%eax),%eax
  107b70:	83 e0 04             	and    $0x4,%eax
  107b73:	85 c0                	test   %eax,%eax
  107b75:	75 24                	jne    107b9b <pmap_check+0x5fa>
  107b77:	c7 44 24 0c 44 c0 10 	movl   $0x10c044,0xc(%esp)
  107b7e:	00 
  107b7f:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  107b86:	00 
  107b87:	c7 44 24 04 b4 02 00 	movl   $0x2b4,0x4(%esp)
  107b8e:	00 
  107b8f:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  107b96:	e8 01 8c ff ff       	call   10079c <debug_panic>
	assert(pmap_bootpdir[PDX(VM_USERLO)] & PTE_U);
  107b9b:	a1 00 14 12 00       	mov    0x121400,%eax
  107ba0:	83 e0 04             	and    $0x4,%eax
  107ba3:	85 c0                	test   %eax,%eax
  107ba5:	75 24                	jne    107bcb <pmap_check+0x62a>
  107ba7:	c7 44 24 0c 80 c0 10 	movl   $0x10c080,0xc(%esp)
  107bae:	00 
  107baf:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  107bb6:	00 
  107bb7:	c7 44 24 04 b5 02 00 	movl   $0x2b5,0x4(%esp)
  107bbe:	00 
  107bbf:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  107bc6:	e8 d1 8b ff ff       	call   10079c <debug_panic>
	
	// should not be able to map at VM_USERLO+PTSIZE
	// because we need a free page for a page table
	assert(pmap_insert(pmap_bootpdir, pi0, VM_USERLO+PTSIZE, 0) == NULL);
  107bcb:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  107bd2:	00 
  107bd3:	c7 44 24 08 00 00 40 	movl   $0x40400000,0x8(%esp)
  107bda:	40 
  107bdb:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  107bde:	89 44 24 04          	mov    %eax,0x4(%esp)
  107be2:	c7 04 24 00 10 12 00 	movl   $0x121000,(%esp)
  107be9:	e8 29 de ff ff       	call   105a17 <pmap_insert>
  107bee:	85 c0                	test   %eax,%eax
  107bf0:	74 24                	je     107c16 <pmap_check+0x675>
  107bf2:	c7 44 24 0c a8 c0 10 	movl   $0x10c0a8,0xc(%esp)
  107bf9:	00 
  107bfa:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  107c01:	00 
  107c02:	c7 44 24 04 b9 02 00 	movl   $0x2b9,0x4(%esp)
  107c09:	00 
  107c0a:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  107c11:	e8 86 8b ff ff       	call   10079c <debug_panic>

	// insert pi1 at VM_USERLO+PAGESIZE (replacing pi2)
	assert(pmap_insert(pmap_bootpdir, pi1, VM_USERLO+PAGESIZE, 0));
  107c16:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  107c1d:	00 
  107c1e:	c7 44 24 08 00 10 00 	movl   $0x40001000,0x8(%esp)
  107c25:	40 
  107c26:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  107c29:	89 44 24 04          	mov    %eax,0x4(%esp)
  107c2d:	c7 04 24 00 10 12 00 	movl   $0x121000,(%esp)
  107c34:	e8 de dd ff ff       	call   105a17 <pmap_insert>
  107c39:	85 c0                	test   %eax,%eax
  107c3b:	75 24                	jne    107c61 <pmap_check+0x6c0>
  107c3d:	c7 44 24 0c e8 c0 10 	movl   $0x10c0e8,0xc(%esp)
  107c44:	00 
  107c45:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  107c4c:	00 
  107c4d:	c7 44 24 04 bc 02 00 	movl   $0x2bc,0x4(%esp)
  107c54:	00 
  107c55:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  107c5c:	e8 3b 8b ff ff       	call   10079c <debug_panic>
	assert(!(*pmap_walk(pmap_bootpdir, VM_USERLO+PAGESIZE, 0) & PTE_U));
  107c61:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  107c68:	00 
  107c69:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  107c70:	40 
  107c71:	c7 04 24 00 10 12 00 	movl   $0x121000,(%esp)
  107c78:	e8 e2 d6 ff ff       	call   10535f <pmap_walk>
  107c7d:	8b 00                	mov    (%eax),%eax
  107c7f:	83 e0 04             	and    $0x4,%eax
  107c82:	85 c0                	test   %eax,%eax
  107c84:	74 24                	je     107caa <pmap_check+0x709>
  107c86:	c7 44 24 0c 20 c1 10 	movl   $0x10c120,0xc(%esp)
  107c8d:	00 
  107c8e:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  107c95:	00 
  107c96:	c7 44 24 04 bd 02 00 	movl   $0x2bd,0x4(%esp)
  107c9d:	00 
  107c9e:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  107ca5:	e8 f2 8a ff ff       	call   10079c <debug_panic>

	// should have pi1 at both +0 and +PAGESIZE, pi2 nowhere, ...
	assert(va2pa(pmap_bootpdir, VM_USERLO+0) == mem_pi2phys(pi1));
  107caa:	c7 44 24 04 00 00 00 	movl   $0x40000000,0x4(%esp)
  107cb1:	40 
  107cb2:	c7 04 24 00 10 12 00 	movl   $0x121000,(%esp)
  107cb9:	e8 64 f8 ff ff       	call   107522 <va2pa>
  107cbe:	89 c1                	mov    %eax,%ecx
  107cc0:	8b 55 dc             	mov    0xffffffdc(%ebp),%edx
  107cc3:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  107cc8:	89 d3                	mov    %edx,%ebx
  107cca:	29 c3                	sub    %eax,%ebx
  107ccc:	89 d8                	mov    %ebx,%eax
  107cce:	c1 e0 09             	shl    $0x9,%eax
  107cd1:	39 c1                	cmp    %eax,%ecx
  107cd3:	74 24                	je     107cf9 <pmap_check+0x758>
  107cd5:	c7 44 24 0c 5c c1 10 	movl   $0x10c15c,0xc(%esp)
  107cdc:	00 
  107cdd:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  107ce4:	00 
  107ce5:	c7 44 24 04 c0 02 00 	movl   $0x2c0,0x4(%esp)
  107cec:	00 
  107ced:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  107cf4:	e8 a3 8a ff ff       	call   10079c <debug_panic>
	assert(va2pa(pmap_bootpdir, VM_USERLO+PAGESIZE) == mem_pi2phys(pi1));
  107cf9:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  107d00:	40 
  107d01:	c7 04 24 00 10 12 00 	movl   $0x121000,(%esp)
  107d08:	e8 15 f8 ff ff       	call   107522 <va2pa>
  107d0d:	89 c1                	mov    %eax,%ecx
  107d0f:	8b 55 dc             	mov    0xffffffdc(%ebp),%edx
  107d12:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  107d17:	89 d3                	mov    %edx,%ebx
  107d19:	29 c3                	sub    %eax,%ebx
  107d1b:	89 d8                	mov    %ebx,%eax
  107d1d:	c1 e0 09             	shl    $0x9,%eax
  107d20:	39 c1                	cmp    %eax,%ecx
  107d22:	74 24                	je     107d48 <pmap_check+0x7a7>
  107d24:	c7 44 24 0c 94 c1 10 	movl   $0x10c194,0xc(%esp)
  107d2b:	00 
  107d2c:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  107d33:	00 
  107d34:	c7 44 24 04 c1 02 00 	movl   $0x2c1,0x4(%esp)
  107d3b:	00 
  107d3c:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  107d43:	e8 54 8a ff ff       	call   10079c <debug_panic>
	// ... and ref counts should reflect this
	assert(pi1->refcount == 2);
  107d48:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  107d4b:	8b 40 04             	mov    0x4(%eax),%eax
  107d4e:	83 f8 02             	cmp    $0x2,%eax
  107d51:	74 24                	je     107d77 <pmap_check+0x7d6>
  107d53:	c7 44 24 0c d1 c1 10 	movl   $0x10c1d1,0xc(%esp)
  107d5a:	00 
  107d5b:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  107d62:	00 
  107d63:	c7 44 24 04 c3 02 00 	movl   $0x2c3,0x4(%esp)
  107d6a:	00 
  107d6b:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  107d72:	e8 25 8a ff ff       	call   10079c <debug_panic>
	assert(pi2->refcount == 0);
  107d77:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  107d7a:	8b 40 04             	mov    0x4(%eax),%eax
  107d7d:	85 c0                	test   %eax,%eax
  107d7f:	74 24                	je     107da5 <pmap_check+0x804>
  107d81:	c7 44 24 0c e4 c1 10 	movl   $0x10c1e4,0xc(%esp)
  107d88:	00 
  107d89:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  107d90:	00 
  107d91:	c7 44 24 04 c4 02 00 	movl   $0x2c4,0x4(%esp)
  107d98:	00 
  107d99:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  107da0:	e8 f7 89 ff ff       	call   10079c <debug_panic>

	// pi2 should be returned by mem_alloc
	assert(mem_alloc() == pi2);
  107da5:	e8 d5 90 ff ff       	call   100e7f <mem_alloc>
  107daa:	3b 45 e0             	cmp    0xffffffe0(%ebp),%eax
  107dad:	74 24                	je     107dd3 <pmap_check+0x832>
  107daf:	c7 44 24 0c f7 c1 10 	movl   $0x10c1f7,0xc(%esp)
  107db6:	00 
  107db7:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  107dbe:	00 
  107dbf:	c7 44 24 04 c7 02 00 	movl   $0x2c7,0x4(%esp)
  107dc6:	00 
  107dc7:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  107dce:	e8 c9 89 ff ff       	call   10079c <debug_panic>

	// unmapping pi1 at VM_USERLO+0 should keep pi1 at +PAGESIZE
	pmap_remove(pmap_bootpdir, VM_USERLO+0, PAGESIZE);
  107dd3:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  107dda:	00 
  107ddb:	c7 44 24 04 00 00 00 	movl   $0x40000000,0x4(%esp)
  107de2:	40 
  107de3:	c7 04 24 00 10 12 00 	movl   $0x121000,(%esp)
  107dea:	e8 a6 dd ff ff       	call   105b95 <pmap_remove>
	assert(va2pa(pmap_bootpdir, VM_USERLO+0) == ~0);
  107def:	c7 44 24 04 00 00 00 	movl   $0x40000000,0x4(%esp)
  107df6:	40 
  107df7:	c7 04 24 00 10 12 00 	movl   $0x121000,(%esp)
  107dfe:	e8 1f f7 ff ff       	call   107522 <va2pa>
  107e03:	83 f8 ff             	cmp    $0xffffffff,%eax
  107e06:	74 24                	je     107e2c <pmap_check+0x88b>
  107e08:	c7 44 24 0c 0c c2 10 	movl   $0x10c20c,0xc(%esp)
  107e0f:	00 
  107e10:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  107e17:	00 
  107e18:	c7 44 24 04 cb 02 00 	movl   $0x2cb,0x4(%esp)
  107e1f:	00 
  107e20:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  107e27:	e8 70 89 ff ff       	call   10079c <debug_panic>
	assert(va2pa(pmap_bootpdir, VM_USERLO+PAGESIZE) == mem_pi2phys(pi1));
  107e2c:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  107e33:	40 
  107e34:	c7 04 24 00 10 12 00 	movl   $0x121000,(%esp)
  107e3b:	e8 e2 f6 ff ff       	call   107522 <va2pa>
  107e40:	89 c1                	mov    %eax,%ecx
  107e42:	8b 55 dc             	mov    0xffffffdc(%ebp),%edx
  107e45:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  107e4a:	89 d3                	mov    %edx,%ebx
  107e4c:	29 c3                	sub    %eax,%ebx
  107e4e:	89 d8                	mov    %ebx,%eax
  107e50:	c1 e0 09             	shl    $0x9,%eax
  107e53:	39 c1                	cmp    %eax,%ecx
  107e55:	74 24                	je     107e7b <pmap_check+0x8da>
  107e57:	c7 44 24 0c 94 c1 10 	movl   $0x10c194,0xc(%esp)
  107e5e:	00 
  107e5f:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  107e66:	00 
  107e67:	c7 44 24 04 cc 02 00 	movl   $0x2cc,0x4(%esp)
  107e6e:	00 
  107e6f:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  107e76:	e8 21 89 ff ff       	call   10079c <debug_panic>
	assert(pi1->refcount == 1);
  107e7b:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  107e7e:	8b 40 04             	mov    0x4(%eax),%eax
  107e81:	83 f8 01             	cmp    $0x1,%eax
  107e84:	74 24                	je     107eaa <pmap_check+0x909>
  107e86:	c7 44 24 0c 08 bf 10 	movl   $0x10bf08,0xc(%esp)
  107e8d:	00 
  107e8e:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  107e95:	00 
  107e96:	c7 44 24 04 cd 02 00 	movl   $0x2cd,0x4(%esp)
  107e9d:	00 
  107e9e:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  107ea5:	e8 f2 88 ff ff       	call   10079c <debug_panic>
	assert(pi2->refcount == 0);
  107eaa:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  107ead:	8b 40 04             	mov    0x4(%eax),%eax
  107eb0:	85 c0                	test   %eax,%eax
  107eb2:	74 24                	je     107ed8 <pmap_check+0x937>
  107eb4:	c7 44 24 0c e4 c1 10 	movl   $0x10c1e4,0xc(%esp)
  107ebb:	00 
  107ebc:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  107ec3:	00 
  107ec4:	c7 44 24 04 ce 02 00 	movl   $0x2ce,0x4(%esp)
  107ecb:	00 
  107ecc:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  107ed3:	e8 c4 88 ff ff       	call   10079c <debug_panic>
	assert(mem_alloc() == NULL);	// still should have no pages free
  107ed8:	e8 a2 8f ff ff       	call   100e7f <mem_alloc>
  107edd:	85 c0                	test   %eax,%eax
  107edf:	74 24                	je     107f05 <pmap_check+0x964>
  107ee1:	c7 44 24 0c 14 be 10 	movl   $0x10be14,0xc(%esp)
  107ee8:	00 
  107ee9:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  107ef0:	00 
  107ef1:	c7 44 24 04 cf 02 00 	movl   $0x2cf,0x4(%esp)
  107ef8:	00 
  107ef9:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  107f00:	e8 97 88 ff ff       	call   10079c <debug_panic>

	// unmapping pi1 at VM_USERLO+PAGESIZE should free it
	pmap_remove(pmap_bootpdir, VM_USERLO+PAGESIZE, PAGESIZE);
  107f05:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  107f0c:	00 
  107f0d:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  107f14:	40 
  107f15:	c7 04 24 00 10 12 00 	movl   $0x121000,(%esp)
  107f1c:	e8 74 dc ff ff       	call   105b95 <pmap_remove>
	assert(va2pa(pmap_bootpdir, VM_USERLO+0) == ~0);
  107f21:	c7 44 24 04 00 00 00 	movl   $0x40000000,0x4(%esp)
  107f28:	40 
  107f29:	c7 04 24 00 10 12 00 	movl   $0x121000,(%esp)
  107f30:	e8 ed f5 ff ff       	call   107522 <va2pa>
  107f35:	83 f8 ff             	cmp    $0xffffffff,%eax
  107f38:	74 24                	je     107f5e <pmap_check+0x9bd>
  107f3a:	c7 44 24 0c 0c c2 10 	movl   $0x10c20c,0xc(%esp)
  107f41:	00 
  107f42:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  107f49:	00 
  107f4a:	c7 44 24 04 d3 02 00 	movl   $0x2d3,0x4(%esp)
  107f51:	00 
  107f52:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  107f59:	e8 3e 88 ff ff       	call   10079c <debug_panic>
	assert(va2pa(pmap_bootpdir, VM_USERLO+PAGESIZE) == ~0);
  107f5e:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  107f65:	40 
  107f66:	c7 04 24 00 10 12 00 	movl   $0x121000,(%esp)
  107f6d:	e8 b0 f5 ff ff       	call   107522 <va2pa>
  107f72:	83 f8 ff             	cmp    $0xffffffff,%eax
  107f75:	74 24                	je     107f9b <pmap_check+0x9fa>
  107f77:	c7 44 24 0c 34 c2 10 	movl   $0x10c234,0xc(%esp)
  107f7e:	00 
  107f7f:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  107f86:	00 
  107f87:	c7 44 24 04 d4 02 00 	movl   $0x2d4,0x4(%esp)
  107f8e:	00 
  107f8f:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  107f96:	e8 01 88 ff ff       	call   10079c <debug_panic>
	assert(pi1->refcount == 0);
  107f9b:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  107f9e:	8b 40 04             	mov    0x4(%eax),%eax
  107fa1:	85 c0                	test   %eax,%eax
  107fa3:	74 24                	je     107fc9 <pmap_check+0xa28>
  107fa5:	c7 44 24 0c 63 c2 10 	movl   $0x10c263,0xc(%esp)
  107fac:	00 
  107fad:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  107fb4:	00 
  107fb5:	c7 44 24 04 d5 02 00 	movl   $0x2d5,0x4(%esp)
  107fbc:	00 
  107fbd:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  107fc4:	e8 d3 87 ff ff       	call   10079c <debug_panic>
	assert(pi2->refcount == 0);
  107fc9:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  107fcc:	8b 40 04             	mov    0x4(%eax),%eax
  107fcf:	85 c0                	test   %eax,%eax
  107fd1:	74 24                	je     107ff7 <pmap_check+0xa56>
  107fd3:	c7 44 24 0c e4 c1 10 	movl   $0x10c1e4,0xc(%esp)
  107fda:	00 
  107fdb:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  107fe2:	00 
  107fe3:	c7 44 24 04 d6 02 00 	movl   $0x2d6,0x4(%esp)
  107fea:	00 
  107feb:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  107ff2:	e8 a5 87 ff ff       	call   10079c <debug_panic>

	// so it should be returned by page_alloc
	assert(mem_alloc() == pi1);
  107ff7:	e8 83 8e ff ff       	call   100e7f <mem_alloc>
  107ffc:	3b 45 dc             	cmp    0xffffffdc(%ebp),%eax
  107fff:	74 24                	je     108025 <pmap_check+0xa84>
  108001:	c7 44 24 0c 76 c2 10 	movl   $0x10c276,0xc(%esp)
  108008:	00 
  108009:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  108010:	00 
  108011:	c7 44 24 04 d9 02 00 	movl   $0x2d9,0x4(%esp)
  108018:	00 
  108019:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  108020:	e8 77 87 ff ff       	call   10079c <debug_panic>

	// should once again have no free memory
	assert(mem_alloc() == NULL);
  108025:	e8 55 8e ff ff       	call   100e7f <mem_alloc>
  10802a:	85 c0                	test   %eax,%eax
  10802c:	74 24                	je     108052 <pmap_check+0xab1>
  10802e:	c7 44 24 0c 14 be 10 	movl   $0x10be14,0xc(%esp)
  108035:	00 
  108036:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  10803d:	00 
  10803e:	c7 44 24 04 dc 02 00 	movl   $0x2dc,0x4(%esp)
  108045:	00 
  108046:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  10804d:	e8 4a 87 ff ff       	call   10079c <debug_panic>

	// should be able to pmap_insert to change a page
	// and see the new data immediately.
	memset(mem_pi2ptr(pi1), 1, PAGESIZE);
  108052:	8b 55 dc             	mov    0xffffffdc(%ebp),%edx
  108055:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  10805a:	89 d1                	mov    %edx,%ecx
  10805c:	29 c1                	sub    %eax,%ecx
  10805e:	89 c8                	mov    %ecx,%eax
  108060:	c1 e0 09             	shl    $0x9,%eax
  108063:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  10806a:	00 
  10806b:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  108072:	00 
  108073:	89 04 24             	mov    %eax,(%esp)
  108076:	e8 26 24 00 00       	call   10a4a1 <memset>
	memset(mem_pi2ptr(pi2), 2, PAGESIZE);
  10807b:	8b 55 e0             	mov    0xffffffe0(%ebp),%edx
  10807e:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  108083:	89 d3                	mov    %edx,%ebx
  108085:	29 c3                	sub    %eax,%ebx
  108087:	89 d8                	mov    %ebx,%eax
  108089:	c1 e0 09             	shl    $0x9,%eax
  10808c:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  108093:	00 
  108094:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
  10809b:	00 
  10809c:	89 04 24             	mov    %eax,(%esp)
  10809f:	e8 fd 23 00 00       	call   10a4a1 <memset>
	pmap_insert(pmap_bootpdir, pi1, VM_USERLO, 0);
  1080a4:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  1080ab:	00 
  1080ac:	c7 44 24 08 00 00 00 	movl   $0x40000000,0x8(%esp)
  1080b3:	40 
  1080b4:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  1080b7:	89 44 24 04          	mov    %eax,0x4(%esp)
  1080bb:	c7 04 24 00 10 12 00 	movl   $0x121000,(%esp)
  1080c2:	e8 50 d9 ff ff       	call   105a17 <pmap_insert>
	assert(pi1->refcount == 1);
  1080c7:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  1080ca:	8b 40 04             	mov    0x4(%eax),%eax
  1080cd:	83 f8 01             	cmp    $0x1,%eax
  1080d0:	74 24                	je     1080f6 <pmap_check+0xb55>
  1080d2:	c7 44 24 0c 08 bf 10 	movl   $0x10bf08,0xc(%esp)
  1080d9:	00 
  1080da:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  1080e1:	00 
  1080e2:	c7 44 24 04 e3 02 00 	movl   $0x2e3,0x4(%esp)
  1080e9:	00 
  1080ea:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  1080f1:	e8 a6 86 ff ff       	call   10079c <debug_panic>
	assert(*(int*)VM_USERLO == 0x01010101);
  1080f6:	b8 00 00 00 40       	mov    $0x40000000,%eax
  1080fb:	8b 00                	mov    (%eax),%eax
  1080fd:	3d 01 01 01 01       	cmp    $0x1010101,%eax
  108102:	74 24                	je     108128 <pmap_check+0xb87>
  108104:	c7 44 24 0c 8c c2 10 	movl   $0x10c28c,0xc(%esp)
  10810b:	00 
  10810c:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  108113:	00 
  108114:	c7 44 24 04 e4 02 00 	movl   $0x2e4,0x4(%esp)
  10811b:	00 
  10811c:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  108123:	e8 74 86 ff ff       	call   10079c <debug_panic>
	pmap_insert(pmap_bootpdir, pi2, VM_USERLO, 0);
  108128:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  10812f:	00 
  108130:	c7 44 24 08 00 00 00 	movl   $0x40000000,0x8(%esp)
  108137:	40 
  108138:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  10813b:	89 44 24 04          	mov    %eax,0x4(%esp)
  10813f:	c7 04 24 00 10 12 00 	movl   $0x121000,(%esp)
  108146:	e8 cc d8 ff ff       	call   105a17 <pmap_insert>
	assert(*(int*)VM_USERLO == 0x02020202);
  10814b:	b8 00 00 00 40       	mov    $0x40000000,%eax
  108150:	8b 00                	mov    (%eax),%eax
  108152:	3d 02 02 02 02       	cmp    $0x2020202,%eax
  108157:	74 24                	je     10817d <pmap_check+0xbdc>
  108159:	c7 44 24 0c ac c2 10 	movl   $0x10c2ac,0xc(%esp)
  108160:	00 
  108161:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  108168:	00 
  108169:	c7 44 24 04 e6 02 00 	movl   $0x2e6,0x4(%esp)
  108170:	00 
  108171:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  108178:	e8 1f 86 ff ff       	call   10079c <debug_panic>
	assert(pi2->refcount == 1);
  10817d:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  108180:	8b 40 04             	mov    0x4(%eax),%eax
  108183:	83 f8 01             	cmp    $0x1,%eax
  108186:	74 24                	je     1081ac <pmap_check+0xc0b>
  108188:	c7 44 24 0c a5 bf 10 	movl   $0x10bfa5,0xc(%esp)
  10818f:	00 
  108190:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  108197:	00 
  108198:	c7 44 24 04 e7 02 00 	movl   $0x2e7,0x4(%esp)
  10819f:	00 
  1081a0:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  1081a7:	e8 f0 85 ff ff       	call   10079c <debug_panic>
	assert(pi1->refcount == 0);
  1081ac:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  1081af:	8b 40 04             	mov    0x4(%eax),%eax
  1081b2:	85 c0                	test   %eax,%eax
  1081b4:	74 24                	je     1081da <pmap_check+0xc39>
  1081b6:	c7 44 24 0c 63 c2 10 	movl   $0x10c263,0xc(%esp)
  1081bd:	00 
  1081be:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  1081c5:	00 
  1081c6:	c7 44 24 04 e8 02 00 	movl   $0x2e8,0x4(%esp)
  1081cd:	00 
  1081ce:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  1081d5:	e8 c2 85 ff ff       	call   10079c <debug_panic>
	assert(mem_alloc() == pi1);
  1081da:	e8 a0 8c ff ff       	call   100e7f <mem_alloc>
  1081df:	3b 45 dc             	cmp    0xffffffdc(%ebp),%eax
  1081e2:	74 24                	je     108208 <pmap_check+0xc67>
  1081e4:	c7 44 24 0c 76 c2 10 	movl   $0x10c276,0xc(%esp)
  1081eb:	00 
  1081ec:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  1081f3:	00 
  1081f4:	c7 44 24 04 e9 02 00 	movl   $0x2e9,0x4(%esp)
  1081fb:	00 
  1081fc:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  108203:	e8 94 85 ff ff       	call   10079c <debug_panic>
	pmap_remove(pmap_bootpdir, VM_USERLO, PAGESIZE);
  108208:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  10820f:	00 
  108210:	c7 44 24 04 00 00 00 	movl   $0x40000000,0x4(%esp)
  108217:	40 
  108218:	c7 04 24 00 10 12 00 	movl   $0x121000,(%esp)
  10821f:	e8 71 d9 ff ff       	call   105b95 <pmap_remove>
	assert(pi2->refcount == 0);
  108224:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  108227:	8b 40 04             	mov    0x4(%eax),%eax
  10822a:	85 c0                	test   %eax,%eax
  10822c:	74 24                	je     108252 <pmap_check+0xcb1>
  10822e:	c7 44 24 0c e4 c1 10 	movl   $0x10c1e4,0xc(%esp)
  108235:	00 
  108236:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  10823d:	00 
  10823e:	c7 44 24 04 eb 02 00 	movl   $0x2eb,0x4(%esp)
  108245:	00 
  108246:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  10824d:	e8 4a 85 ff ff       	call   10079c <debug_panic>
	assert(mem_alloc() == pi2);
  108252:	e8 28 8c ff ff       	call   100e7f <mem_alloc>
  108257:	3b 45 e0             	cmp    0xffffffe0(%ebp),%eax
  10825a:	74 24                	je     108280 <pmap_check+0xcdf>
  10825c:	c7 44 24 0c f7 c1 10 	movl   $0x10c1f7,0xc(%esp)
  108263:	00 
  108264:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  10826b:	00 
  10826c:	c7 44 24 04 ec 02 00 	movl   $0x2ec,0x4(%esp)
  108273:	00 
  108274:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  10827b:	e8 1c 85 ff ff       	call   10079c <debug_panic>

	// now use a pmap_remove on a large region to take pi0 back
	pmap_remove(pmap_bootpdir, VM_USERLO, VM_USERHI-VM_USERLO);
  108280:	c7 44 24 08 00 00 00 	movl   $0xb0000000,0x8(%esp)
  108287:	b0 
  108288:	c7 44 24 04 00 00 00 	movl   $0x40000000,0x4(%esp)
  10828f:	40 
  108290:	c7 04 24 00 10 12 00 	movl   $0x121000,(%esp)
  108297:	e8 f9 d8 ff ff       	call   105b95 <pmap_remove>
	assert(pmap_bootpdir[PDX(VM_USERLO)] == PTE_ZERO);
  10829c:	a1 00 14 12 00       	mov    0x121400,%eax
  1082a1:	ba 00 20 12 00       	mov    $0x122000,%edx
  1082a6:	39 d0                	cmp    %edx,%eax
  1082a8:	74 24                	je     1082ce <pmap_check+0xd2d>
  1082aa:	c7 44 24 0c cc c2 10 	movl   $0x10c2cc,0xc(%esp)
  1082b1:	00 
  1082b2:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  1082b9:	00 
  1082ba:	c7 44 24 04 f0 02 00 	movl   $0x2f0,0x4(%esp)
  1082c1:	00 
  1082c2:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  1082c9:	e8 ce 84 ff ff       	call   10079c <debug_panic>
	assert(pi0->refcount == 0);
  1082ce:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  1082d1:	8b 40 04             	mov    0x4(%eax),%eax
  1082d4:	85 c0                	test   %eax,%eax
  1082d6:	74 24                	je     1082fc <pmap_check+0xd5b>
  1082d8:	c7 44 24 0c f6 c2 10 	movl   $0x10c2f6,0xc(%esp)
  1082df:	00 
  1082e0:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  1082e7:	00 
  1082e8:	c7 44 24 04 f1 02 00 	movl   $0x2f1,0x4(%esp)
  1082ef:	00 
  1082f0:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  1082f7:	e8 a0 84 ff ff       	call   10079c <debug_panic>
	assert(mem_alloc() == pi0);
  1082fc:	e8 7e 8b ff ff       	call   100e7f <mem_alloc>
  108301:	3b 45 d8             	cmp    0xffffffd8(%ebp),%eax
  108304:	74 24                	je     10832a <pmap_check+0xd89>
  108306:	c7 44 24 0c 09 c3 10 	movl   $0x10c309,0xc(%esp)
  10830d:	00 
  10830e:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  108315:	00 
  108316:	c7 44 24 04 f2 02 00 	movl   $0x2f2,0x4(%esp)
  10831d:	00 
  10831e:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  108325:	e8 72 84 ff ff       	call   10079c <debug_panic>
	assert(mem_freelist == NULL);
  10832a:	a1 40 fd 11 00       	mov    0x11fd40,%eax
  10832f:	85 c0                	test   %eax,%eax
  108331:	74 24                	je     108357 <pmap_check+0xdb6>
  108333:	c7 44 24 0c 1c c3 10 	movl   $0x10c31c,0xc(%esp)
  10833a:	00 
  10833b:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  108342:	00 
  108343:	c7 44 24 04 f3 02 00 	movl   $0x2f3,0x4(%esp)
  10834a:	00 
  10834b:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  108352:	e8 45 84 ff ff       	call   10079c <debug_panic>

	// test pmap_remove with large, non-ptable-aligned regions
	mem_free(pi1);
  108357:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  10835a:	89 04 24             	mov    %eax,(%esp)
  10835d:	e8 61 8b ff ff       	call   100ec3 <mem_free>
	uintptr_t va = VM_USERLO;
  108362:	c7 45 f8 00 00 00 40 	movl   $0x40000000,0xfffffff8(%ebp)
	assert(pmap_insert(pmap_bootpdir, pi0, va, 0));
  108369:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  108370:	00 
  108371:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  108374:	89 44 24 08          	mov    %eax,0x8(%esp)
  108378:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  10837b:	89 44 24 04          	mov    %eax,0x4(%esp)
  10837f:	c7 04 24 00 10 12 00 	movl   $0x121000,(%esp)
  108386:	e8 8c d6 ff ff       	call   105a17 <pmap_insert>
  10838b:	85 c0                	test   %eax,%eax
  10838d:	75 24                	jne    1083b3 <pmap_check+0xe12>
  10838f:	c7 44 24 0c 34 c3 10 	movl   $0x10c334,0xc(%esp)
  108396:	00 
  108397:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  10839e:	00 
  10839f:	c7 44 24 04 f8 02 00 	movl   $0x2f8,0x4(%esp)
  1083a6:	00 
  1083a7:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  1083ae:	e8 e9 83 ff ff       	call   10079c <debug_panic>
	assert(pmap_insert(pmap_bootpdir, pi0, va+PAGESIZE, 0));
  1083b3:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1083b6:	05 00 10 00 00       	add    $0x1000,%eax
  1083bb:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  1083c2:	00 
  1083c3:	89 44 24 08          	mov    %eax,0x8(%esp)
  1083c7:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  1083ca:	89 44 24 04          	mov    %eax,0x4(%esp)
  1083ce:	c7 04 24 00 10 12 00 	movl   $0x121000,(%esp)
  1083d5:	e8 3d d6 ff ff       	call   105a17 <pmap_insert>
  1083da:	85 c0                	test   %eax,%eax
  1083dc:	75 24                	jne    108402 <pmap_check+0xe61>
  1083de:	c7 44 24 0c 5c c3 10 	movl   $0x10c35c,0xc(%esp)
  1083e5:	00 
  1083e6:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  1083ed:	00 
  1083ee:	c7 44 24 04 f9 02 00 	movl   $0x2f9,0x4(%esp)
  1083f5:	00 
  1083f6:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  1083fd:	e8 9a 83 ff ff       	call   10079c <debug_panic>
	assert(pmap_insert(pmap_bootpdir, pi0, va+PTSIZE-PAGESIZE, 0));
  108402:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  108405:	05 00 f0 3f 00       	add    $0x3ff000,%eax
  10840a:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  108411:	00 
  108412:	89 44 24 08          	mov    %eax,0x8(%esp)
  108416:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  108419:	89 44 24 04          	mov    %eax,0x4(%esp)
  10841d:	c7 04 24 00 10 12 00 	movl   $0x121000,(%esp)
  108424:	e8 ee d5 ff ff       	call   105a17 <pmap_insert>
  108429:	85 c0                	test   %eax,%eax
  10842b:	75 24                	jne    108451 <pmap_check+0xeb0>
  10842d:	c7 44 24 0c 8c c3 10 	movl   $0x10c38c,0xc(%esp)
  108434:	00 
  108435:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  10843c:	00 
  10843d:	c7 44 24 04 fa 02 00 	movl   $0x2fa,0x4(%esp)
  108444:	00 
  108445:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  10844c:	e8 4b 83 ff ff       	call   10079c <debug_panic>
	assert(PGADDR(pmap_bootpdir[PDX(VM_USERLO)]) == mem_pi2phys(pi1));
  108451:	a1 00 14 12 00       	mov    0x121400,%eax
  108456:	89 c1                	mov    %eax,%ecx
  108458:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
  10845e:	8b 55 dc             	mov    0xffffffdc(%ebp),%edx
  108461:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  108466:	89 d3                	mov    %edx,%ebx
  108468:	29 c3                	sub    %eax,%ebx
  10846a:	89 d8                	mov    %ebx,%eax
  10846c:	c1 e0 09             	shl    $0x9,%eax
  10846f:	39 c1                	cmp    %eax,%ecx
  108471:	74 24                	je     108497 <pmap_check+0xef6>
  108473:	c7 44 24 0c c4 c3 10 	movl   $0x10c3c4,0xc(%esp)
  10847a:	00 
  10847b:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  108482:	00 
  108483:	c7 44 24 04 fb 02 00 	movl   $0x2fb,0x4(%esp)
  10848a:	00 
  10848b:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  108492:	e8 05 83 ff ff       	call   10079c <debug_panic>
	assert(mem_freelist == NULL);
  108497:	a1 40 fd 11 00       	mov    0x11fd40,%eax
  10849c:	85 c0                	test   %eax,%eax
  10849e:	74 24                	je     1084c4 <pmap_check+0xf23>
  1084a0:	c7 44 24 0c 1c c3 10 	movl   $0x10c31c,0xc(%esp)
  1084a7:	00 
  1084a8:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  1084af:	00 
  1084b0:	c7 44 24 04 fc 02 00 	movl   $0x2fc,0x4(%esp)
  1084b7:	00 
  1084b8:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  1084bf:	e8 d8 82 ff ff       	call   10079c <debug_panic>
	mem_free(pi2);
  1084c4:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  1084c7:	89 04 24             	mov    %eax,(%esp)
  1084ca:	e8 f4 89 ff ff       	call   100ec3 <mem_free>
	assert(pmap_insert(pmap_bootpdir, pi0, va+PTSIZE, 0));
  1084cf:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1084d2:	05 00 00 40 00       	add    $0x400000,%eax
  1084d7:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  1084de:	00 
  1084df:	89 44 24 08          	mov    %eax,0x8(%esp)
  1084e3:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  1084e6:	89 44 24 04          	mov    %eax,0x4(%esp)
  1084ea:	c7 04 24 00 10 12 00 	movl   $0x121000,(%esp)
  1084f1:	e8 21 d5 ff ff       	call   105a17 <pmap_insert>
  1084f6:	85 c0                	test   %eax,%eax
  1084f8:	75 24                	jne    10851e <pmap_check+0xf7d>
  1084fa:	c7 44 24 0c 00 c4 10 	movl   $0x10c400,0xc(%esp)
  108501:	00 
  108502:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  108509:	00 
  10850a:	c7 44 24 04 fe 02 00 	movl   $0x2fe,0x4(%esp)
  108511:	00 
  108512:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  108519:	e8 7e 82 ff ff       	call   10079c <debug_panic>
	assert(pmap_insert(pmap_bootpdir, pi0, va+PTSIZE+PAGESIZE, 0));
  10851e:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  108521:	05 00 10 40 00       	add    $0x401000,%eax
  108526:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  10852d:	00 
  10852e:	89 44 24 08          	mov    %eax,0x8(%esp)
  108532:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  108535:	89 44 24 04          	mov    %eax,0x4(%esp)
  108539:	c7 04 24 00 10 12 00 	movl   $0x121000,(%esp)
  108540:	e8 d2 d4 ff ff       	call   105a17 <pmap_insert>
  108545:	85 c0                	test   %eax,%eax
  108547:	75 24                	jne    10856d <pmap_check+0xfcc>
  108549:	c7 44 24 0c 30 c4 10 	movl   $0x10c430,0xc(%esp)
  108550:	00 
  108551:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  108558:	00 
  108559:	c7 44 24 04 ff 02 00 	movl   $0x2ff,0x4(%esp)
  108560:	00 
  108561:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  108568:	e8 2f 82 ff ff       	call   10079c <debug_panic>
	assert(pmap_insert(pmap_bootpdir, pi0, va+PTSIZE*2-PAGESIZE, 0));
  10856d:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  108570:	05 00 f0 7f 00       	add    $0x7ff000,%eax
  108575:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  10857c:	00 
  10857d:	89 44 24 08          	mov    %eax,0x8(%esp)
  108581:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  108584:	89 44 24 04          	mov    %eax,0x4(%esp)
  108588:	c7 04 24 00 10 12 00 	movl   $0x121000,(%esp)
  10858f:	e8 83 d4 ff ff       	call   105a17 <pmap_insert>
  108594:	85 c0                	test   %eax,%eax
  108596:	75 24                	jne    1085bc <pmap_check+0x101b>
  108598:	c7 44 24 0c 68 c4 10 	movl   $0x10c468,0xc(%esp)
  10859f:	00 
  1085a0:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  1085a7:	00 
  1085a8:	c7 44 24 04 00 03 00 	movl   $0x300,0x4(%esp)
  1085af:	00 
  1085b0:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  1085b7:	e8 e0 81 ff ff       	call   10079c <debug_panic>
	assert(PGADDR(pmap_bootpdir[PDX(VM_USERLO+PTSIZE)])
  1085bc:	a1 04 14 12 00       	mov    0x121404,%eax
  1085c1:	89 c1                	mov    %eax,%ecx
  1085c3:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
  1085c9:	8b 55 e0             	mov    0xffffffe0(%ebp),%edx
  1085cc:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  1085d1:	89 d3                	mov    %edx,%ebx
  1085d3:	29 c3                	sub    %eax,%ebx
  1085d5:	89 d8                	mov    %ebx,%eax
  1085d7:	c1 e0 09             	shl    $0x9,%eax
  1085da:	39 c1                	cmp    %eax,%ecx
  1085dc:	74 24                	je     108602 <pmap_check+0x1061>
  1085de:	c7 44 24 0c a4 c4 10 	movl   $0x10c4a4,0xc(%esp)
  1085e5:	00 
  1085e6:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  1085ed:	00 
  1085ee:	c7 44 24 04 02 03 00 	movl   $0x302,0x4(%esp)
  1085f5:	00 
  1085f6:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  1085fd:	e8 9a 81 ff ff       	call   10079c <debug_panic>
		== mem_pi2phys(pi2));
	assert(mem_freelist == NULL);
  108602:	a1 40 fd 11 00       	mov    0x11fd40,%eax
  108607:	85 c0                	test   %eax,%eax
  108609:	74 24                	je     10862f <pmap_check+0x108e>
  10860b:	c7 44 24 0c 1c c3 10 	movl   $0x10c31c,0xc(%esp)
  108612:	00 
  108613:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  10861a:	00 
  10861b:	c7 44 24 04 03 03 00 	movl   $0x303,0x4(%esp)
  108622:	00 
  108623:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  10862a:	e8 6d 81 ff ff       	call   10079c <debug_panic>
	mem_free(pi3);
  10862f:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  108632:	89 04 24             	mov    %eax,(%esp)
  108635:	e8 89 88 ff ff       	call   100ec3 <mem_free>
	assert(pmap_insert(pmap_bootpdir, pi0, va+PTSIZE*2, 0));
  10863a:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10863d:	05 00 00 80 00       	add    $0x800000,%eax
  108642:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  108649:	00 
  10864a:	89 44 24 08          	mov    %eax,0x8(%esp)
  10864e:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  108651:	89 44 24 04          	mov    %eax,0x4(%esp)
  108655:	c7 04 24 00 10 12 00 	movl   $0x121000,(%esp)
  10865c:	e8 b6 d3 ff ff       	call   105a17 <pmap_insert>
  108661:	85 c0                	test   %eax,%eax
  108663:	75 24                	jne    108689 <pmap_check+0x10e8>
  108665:	c7 44 24 0c e8 c4 10 	movl   $0x10c4e8,0xc(%esp)
  10866c:	00 
  10866d:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  108674:	00 
  108675:	c7 44 24 04 05 03 00 	movl   $0x305,0x4(%esp)
  10867c:	00 
  10867d:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  108684:	e8 13 81 ff ff       	call   10079c <debug_panic>
	assert(pmap_insert(pmap_bootpdir, pi0, va+PTSIZE*2+PAGESIZE, 0));
  108689:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10868c:	05 00 10 80 00       	add    $0x801000,%eax
  108691:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  108698:	00 
  108699:	89 44 24 08          	mov    %eax,0x8(%esp)
  10869d:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  1086a0:	89 44 24 04          	mov    %eax,0x4(%esp)
  1086a4:	c7 04 24 00 10 12 00 	movl   $0x121000,(%esp)
  1086ab:	e8 67 d3 ff ff       	call   105a17 <pmap_insert>
  1086b0:	85 c0                	test   %eax,%eax
  1086b2:	75 24                	jne    1086d8 <pmap_check+0x1137>
  1086b4:	c7 44 24 0c 18 c5 10 	movl   $0x10c518,0xc(%esp)
  1086bb:	00 
  1086bc:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  1086c3:	00 
  1086c4:	c7 44 24 04 06 03 00 	movl   $0x306,0x4(%esp)
  1086cb:	00 
  1086cc:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  1086d3:	e8 c4 80 ff ff       	call   10079c <debug_panic>
	assert(pmap_insert(pmap_bootpdir, pi0, va+PTSIZE*3-PAGESIZE*2, 0));
  1086d8:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1086db:	05 00 e0 bf 00       	add    $0xbfe000,%eax
  1086e0:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  1086e7:	00 
  1086e8:	89 44 24 08          	mov    %eax,0x8(%esp)
  1086ec:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  1086ef:	89 44 24 04          	mov    %eax,0x4(%esp)
  1086f3:	c7 04 24 00 10 12 00 	movl   $0x121000,(%esp)
  1086fa:	e8 18 d3 ff ff       	call   105a17 <pmap_insert>
  1086ff:	85 c0                	test   %eax,%eax
  108701:	75 24                	jne    108727 <pmap_check+0x1186>
  108703:	c7 44 24 0c 54 c5 10 	movl   $0x10c554,0xc(%esp)
  10870a:	00 
  10870b:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  108712:	00 
  108713:	c7 44 24 04 07 03 00 	movl   $0x307,0x4(%esp)
  10871a:	00 
  10871b:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  108722:	e8 75 80 ff ff       	call   10079c <debug_panic>
	assert(pmap_insert(pmap_bootpdir, pi0, va+PTSIZE*3-PAGESIZE, 0));
  108727:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10872a:	05 00 f0 bf 00       	add    $0xbff000,%eax
  10872f:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  108736:	00 
  108737:	89 44 24 08          	mov    %eax,0x8(%esp)
  10873b:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  10873e:	89 44 24 04          	mov    %eax,0x4(%esp)
  108742:	c7 04 24 00 10 12 00 	movl   $0x121000,(%esp)
  108749:	e8 c9 d2 ff ff       	call   105a17 <pmap_insert>
  10874e:	85 c0                	test   %eax,%eax
  108750:	75 24                	jne    108776 <pmap_check+0x11d5>
  108752:	c7 44 24 0c 90 c5 10 	movl   $0x10c590,0xc(%esp)
  108759:	00 
  10875a:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  108761:	00 
  108762:	c7 44 24 04 08 03 00 	movl   $0x308,0x4(%esp)
  108769:	00 
  10876a:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  108771:	e8 26 80 ff ff       	call   10079c <debug_panic>
	assert(PGADDR(pmap_bootpdir[PDX(VM_USERLO+PTSIZE*2)])
  108776:	a1 08 14 12 00       	mov    0x121408,%eax
  10877b:	89 c1                	mov    %eax,%ecx
  10877d:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
  108783:	8b 55 e4             	mov    0xffffffe4(%ebp),%edx
  108786:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  10878b:	89 d3                	mov    %edx,%ebx
  10878d:	29 c3                	sub    %eax,%ebx
  10878f:	89 d8                	mov    %ebx,%eax
  108791:	c1 e0 09             	shl    $0x9,%eax
  108794:	39 c1                	cmp    %eax,%ecx
  108796:	74 24                	je     1087bc <pmap_check+0x121b>
  108798:	c7 44 24 0c cc c5 10 	movl   $0x10c5cc,0xc(%esp)
  10879f:	00 
  1087a0:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  1087a7:	00 
  1087a8:	c7 44 24 04 0a 03 00 	movl   $0x30a,0x4(%esp)
  1087af:	00 
  1087b0:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  1087b7:	e8 e0 7f ff ff       	call   10079c <debug_panic>
		== mem_pi2phys(pi3));
	assert(mem_freelist == NULL);
  1087bc:	a1 40 fd 11 00       	mov    0x11fd40,%eax
  1087c1:	85 c0                	test   %eax,%eax
  1087c3:	74 24                	je     1087e9 <pmap_check+0x1248>
  1087c5:	c7 44 24 0c 1c c3 10 	movl   $0x10c31c,0xc(%esp)
  1087cc:	00 
  1087cd:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  1087d4:	00 
  1087d5:	c7 44 24 04 0b 03 00 	movl   $0x30b,0x4(%esp)
  1087dc:	00 
  1087dd:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  1087e4:	e8 b3 7f ff ff       	call   10079c <debug_panic>
	assert(pi0->refcount == 10);
  1087e9:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  1087ec:	8b 40 04             	mov    0x4(%eax),%eax
  1087ef:	83 f8 0a             	cmp    $0xa,%eax
  1087f2:	74 24                	je     108818 <pmap_check+0x1277>
  1087f4:	c7 44 24 0c 0f c6 10 	movl   $0x10c60f,0xc(%esp)
  1087fb:	00 
  1087fc:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  108803:	00 
  108804:	c7 44 24 04 0c 03 00 	movl   $0x30c,0x4(%esp)
  10880b:	00 
  10880c:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  108813:	e8 84 7f ff ff       	call   10079c <debug_panic>
	assert(pi1->refcount == 1);
  108818:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  10881b:	8b 40 04             	mov    0x4(%eax),%eax
  10881e:	83 f8 01             	cmp    $0x1,%eax
  108821:	74 24                	je     108847 <pmap_check+0x12a6>
  108823:	c7 44 24 0c 08 bf 10 	movl   $0x10bf08,0xc(%esp)
  10882a:	00 
  10882b:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  108832:	00 
  108833:	c7 44 24 04 0d 03 00 	movl   $0x30d,0x4(%esp)
  10883a:	00 
  10883b:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  108842:	e8 55 7f ff ff       	call   10079c <debug_panic>
	assert(pi2->refcount == 1);
  108847:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  10884a:	8b 40 04             	mov    0x4(%eax),%eax
  10884d:	83 f8 01             	cmp    $0x1,%eax
  108850:	74 24                	je     108876 <pmap_check+0x12d5>
  108852:	c7 44 24 0c a5 bf 10 	movl   $0x10bfa5,0xc(%esp)
  108859:	00 
  10885a:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  108861:	00 
  108862:	c7 44 24 04 0e 03 00 	movl   $0x30e,0x4(%esp)
  108869:	00 
  10886a:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  108871:	e8 26 7f ff ff       	call   10079c <debug_panic>
	assert(pi3->refcount == 1);
  108876:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  108879:	8b 40 04             	mov    0x4(%eax),%eax
  10887c:	83 f8 01             	cmp    $0x1,%eax
  10887f:	74 24                	je     1088a5 <pmap_check+0x1304>
  108881:	c7 44 24 0c 23 c6 10 	movl   $0x10c623,0xc(%esp)
  108888:	00 
  108889:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  108890:	00 
  108891:	c7 44 24 04 0f 03 00 	movl   $0x30f,0x4(%esp)
  108898:	00 
  108899:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  1088a0:	e8 f7 7e ff ff       	call   10079c <debug_panic>
	pmap_remove(pmap_bootpdir, va+PAGESIZE, PTSIZE*3-PAGESIZE*2);
  1088a5:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1088a8:	05 00 10 00 00       	add    $0x1000,%eax
  1088ad:	c7 44 24 08 00 e0 bf 	movl   $0xbfe000,0x8(%esp)
  1088b4:	00 
  1088b5:	89 44 24 04          	mov    %eax,0x4(%esp)
  1088b9:	c7 04 24 00 10 12 00 	movl   $0x121000,(%esp)
  1088c0:	e8 d0 d2 ff ff       	call   105b95 <pmap_remove>
	assert(pi0->refcount == 2);
  1088c5:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  1088c8:	8b 40 04             	mov    0x4(%eax),%eax
  1088cb:	83 f8 02             	cmp    $0x2,%eax
  1088ce:	74 24                	je     1088f4 <pmap_check+0x1353>
  1088d0:	c7 44 24 0c 36 c6 10 	movl   $0x10c636,0xc(%esp)
  1088d7:	00 
  1088d8:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  1088df:	00 
  1088e0:	c7 44 24 04 11 03 00 	movl   $0x311,0x4(%esp)
  1088e7:	00 
  1088e8:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  1088ef:	e8 a8 7e ff ff       	call   10079c <debug_panic>
	assert(pi2->refcount == 0); assert(mem_alloc() == pi2);
  1088f4:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  1088f7:	8b 40 04             	mov    0x4(%eax),%eax
  1088fa:	85 c0                	test   %eax,%eax
  1088fc:	74 24                	je     108922 <pmap_check+0x1381>
  1088fe:	c7 44 24 0c e4 c1 10 	movl   $0x10c1e4,0xc(%esp)
  108905:	00 
  108906:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  10890d:	00 
  10890e:	c7 44 24 04 12 03 00 	movl   $0x312,0x4(%esp)
  108915:	00 
  108916:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  10891d:	e8 7a 7e ff ff       	call   10079c <debug_panic>
  108922:	e8 58 85 ff ff       	call   100e7f <mem_alloc>
  108927:	3b 45 e0             	cmp    0xffffffe0(%ebp),%eax
  10892a:	74 24                	je     108950 <pmap_check+0x13af>
  10892c:	c7 44 24 0c f7 c1 10 	movl   $0x10c1f7,0xc(%esp)
  108933:	00 
  108934:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  10893b:	00 
  10893c:	c7 44 24 04 12 03 00 	movl   $0x312,0x4(%esp)
  108943:	00 
  108944:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  10894b:	e8 4c 7e ff ff       	call   10079c <debug_panic>
	assert(mem_freelist == NULL);
  108950:	a1 40 fd 11 00       	mov    0x11fd40,%eax
  108955:	85 c0                	test   %eax,%eax
  108957:	74 24                	je     10897d <pmap_check+0x13dc>
  108959:	c7 44 24 0c 1c c3 10 	movl   $0x10c31c,0xc(%esp)
  108960:	00 
  108961:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  108968:	00 
  108969:	c7 44 24 04 13 03 00 	movl   $0x313,0x4(%esp)
  108970:	00 
  108971:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  108978:	e8 1f 7e ff ff       	call   10079c <debug_panic>
	pmap_remove(pmap_bootpdir, va, PTSIZE*3-PAGESIZE);
  10897d:	c7 44 24 08 00 f0 bf 	movl   $0xbff000,0x8(%esp)
  108984:	00 
  108985:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  108988:	89 44 24 04          	mov    %eax,0x4(%esp)
  10898c:	c7 04 24 00 10 12 00 	movl   $0x121000,(%esp)
  108993:	e8 fd d1 ff ff       	call   105b95 <pmap_remove>
	assert(pi0->refcount == 1);
  108998:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  10899b:	8b 40 04             	mov    0x4(%eax),%eax
  10899e:	83 f8 01             	cmp    $0x1,%eax
  1089a1:	74 24                	je     1089c7 <pmap_check+0x1426>
  1089a3:	c7 44 24 0c 1b bf 10 	movl   $0x10bf1b,0xc(%esp)
  1089aa:	00 
  1089ab:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  1089b2:	00 
  1089b3:	c7 44 24 04 15 03 00 	movl   $0x315,0x4(%esp)
  1089ba:	00 
  1089bb:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  1089c2:	e8 d5 7d ff ff       	call   10079c <debug_panic>
	assert(pi1->refcount == 0); assert(mem_alloc() == pi1);
  1089c7:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  1089ca:	8b 40 04             	mov    0x4(%eax),%eax
  1089cd:	85 c0                	test   %eax,%eax
  1089cf:	74 24                	je     1089f5 <pmap_check+0x1454>
  1089d1:	c7 44 24 0c 63 c2 10 	movl   $0x10c263,0xc(%esp)
  1089d8:	00 
  1089d9:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  1089e0:	00 
  1089e1:	c7 44 24 04 16 03 00 	movl   $0x316,0x4(%esp)
  1089e8:	00 
  1089e9:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  1089f0:	e8 a7 7d ff ff       	call   10079c <debug_panic>
  1089f5:	e8 85 84 ff ff       	call   100e7f <mem_alloc>
  1089fa:	3b 45 dc             	cmp    0xffffffdc(%ebp),%eax
  1089fd:	74 24                	je     108a23 <pmap_check+0x1482>
  1089ff:	c7 44 24 0c 76 c2 10 	movl   $0x10c276,0xc(%esp)
  108a06:	00 
  108a07:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  108a0e:	00 
  108a0f:	c7 44 24 04 16 03 00 	movl   $0x316,0x4(%esp)
  108a16:	00 
  108a17:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  108a1e:	e8 79 7d ff ff       	call   10079c <debug_panic>
	assert(mem_freelist == NULL);
  108a23:	a1 40 fd 11 00       	mov    0x11fd40,%eax
  108a28:	85 c0                	test   %eax,%eax
  108a2a:	74 24                	je     108a50 <pmap_check+0x14af>
  108a2c:	c7 44 24 0c 1c c3 10 	movl   $0x10c31c,0xc(%esp)
  108a33:	00 
  108a34:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  108a3b:	00 
  108a3c:	c7 44 24 04 17 03 00 	movl   $0x317,0x4(%esp)
  108a43:	00 
  108a44:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  108a4b:	e8 4c 7d ff ff       	call   10079c <debug_panic>
	pmap_remove(pmap_bootpdir, va+PTSIZE*3-PAGESIZE, PAGESIZE);
  108a50:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  108a53:	05 00 f0 bf 00       	add    $0xbff000,%eax
  108a58:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  108a5f:	00 
  108a60:	89 44 24 04          	mov    %eax,0x4(%esp)
  108a64:	c7 04 24 00 10 12 00 	movl   $0x121000,(%esp)
  108a6b:	e8 25 d1 ff ff       	call   105b95 <pmap_remove>
	assert(pi0->refcount == 0);	// pi3 might or might not also be freed
  108a70:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  108a73:	8b 40 04             	mov    0x4(%eax),%eax
  108a76:	85 c0                	test   %eax,%eax
  108a78:	74 24                	je     108a9e <pmap_check+0x14fd>
  108a7a:	c7 44 24 0c f6 c2 10 	movl   $0x10c2f6,0xc(%esp)
  108a81:	00 
  108a82:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  108a89:	00 
  108a8a:	c7 44 24 04 19 03 00 	movl   $0x319,0x4(%esp)
  108a91:	00 
  108a92:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  108a99:	e8 fe 7c ff ff       	call   10079c <debug_panic>
	pmap_remove(pmap_bootpdir, va+PAGESIZE, PTSIZE*3);
  108a9e:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  108aa1:	05 00 10 00 00       	add    $0x1000,%eax
  108aa6:	c7 44 24 08 00 00 c0 	movl   $0xc00000,0x8(%esp)
  108aad:	00 
  108aae:	89 44 24 04          	mov    %eax,0x4(%esp)
  108ab2:	c7 04 24 00 10 12 00 	movl   $0x121000,(%esp)
  108ab9:	e8 d7 d0 ff ff       	call   105b95 <pmap_remove>
	assert(pi3->refcount == 0);
  108abe:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  108ac1:	8b 40 04             	mov    0x4(%eax),%eax
  108ac4:	85 c0                	test   %eax,%eax
  108ac6:	74 24                	je     108aec <pmap_check+0x154b>
  108ac8:	c7 44 24 0c 49 c6 10 	movl   $0x10c649,0xc(%esp)
  108acf:	00 
  108ad0:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  108ad7:	00 
  108ad8:	c7 44 24 04 1b 03 00 	movl   $0x31b,0x4(%esp)
  108adf:	00 
  108ae0:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  108ae7:	e8 b0 7c ff ff       	call   10079c <debug_panic>
	mem_alloc(); mem_alloc();	// collect pi0 and pi3
  108aec:	e8 8e 83 ff ff       	call   100e7f <mem_alloc>
  108af1:	e8 89 83 ff ff       	call   100e7f <mem_alloc>
	assert(mem_freelist == NULL);
  108af6:	a1 40 fd 11 00       	mov    0x11fd40,%eax
  108afb:	85 c0                	test   %eax,%eax
  108afd:	74 24                	je     108b23 <pmap_check+0x1582>
  108aff:	c7 44 24 0c 1c c3 10 	movl   $0x10c31c,0xc(%esp)
  108b06:	00 
  108b07:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  108b0e:	00 
  108b0f:	c7 44 24 04 1d 03 00 	movl   $0x31d,0x4(%esp)
  108b16:	00 
  108b17:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  108b1e:	e8 79 7c ff ff       	call   10079c <debug_panic>

	// check pointer arithmetic in pmap_walk
	mem_free(pi0);
  108b23:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  108b26:	89 04 24             	mov    %eax,(%esp)
  108b29:	e8 95 83 ff ff       	call   100ec3 <mem_free>
	va = VM_USERLO + PAGESIZE*NPTENTRIES + PAGESIZE;
  108b2e:	c7 45 f8 00 10 40 40 	movl   $0x40401000,0xfffffff8(%ebp)
	ptep = pmap_walk(pmap_bootpdir, va, 1);
  108b35:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
  108b3c:	00 
  108b3d:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  108b40:	89 44 24 04          	mov    %eax,0x4(%esp)
  108b44:	c7 04 24 00 10 12 00 	movl   $0x121000,(%esp)
  108b4b:	e8 0f c8 ff ff       	call   10535f <pmap_walk>
  108b50:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
	ptep1 = mem_ptr(PGADDR(pmap_bootpdir[PDX(va)]));
  108b53:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  108b56:	c1 e8 16             	shr    $0x16,%eax
  108b59:	25 ff 03 00 00       	and    $0x3ff,%eax
  108b5e:	8b 04 85 00 10 12 00 	mov    0x121000(,%eax,4),%eax
  108b65:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  108b6a:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
	assert(ptep == ptep1 + PTX(va));
  108b6d:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  108b70:	c1 e8 0c             	shr    $0xc,%eax
  108b73:	25 ff 03 00 00       	and    $0x3ff,%eax
  108b78:	c1 e0 02             	shl    $0x2,%eax
  108b7b:	03 45 f0             	add    0xfffffff0(%ebp),%eax
  108b7e:	3b 45 ec             	cmp    0xffffffec(%ebp),%eax
  108b81:	74 24                	je     108ba7 <pmap_check+0x1606>
  108b83:	c7 44 24 0c 5c c6 10 	movl   $0x10c65c,0xc(%esp)
  108b8a:	00 
  108b8b:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  108b92:	00 
  108b93:	c7 44 24 04 24 03 00 	movl   $0x324,0x4(%esp)
  108b9a:	00 
  108b9b:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  108ba2:	e8 f5 7b ff ff       	call   10079c <debug_panic>
	pmap_bootpdir[PDX(va)] = PTE_ZERO;
  108ba7:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  108baa:	c1 e8 16             	shr    $0x16,%eax
  108bad:	89 c2                	mov    %eax,%edx
  108baf:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
  108bb5:	b8 00 20 12 00       	mov    $0x122000,%eax
  108bba:	89 04 95 00 10 12 00 	mov    %eax,0x121000(,%edx,4)
	pi0->refcount = 0;
  108bc1:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  108bc4:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)

	// check that new page tables get cleared
	memset(mem_pi2ptr(pi0), 0xFF, PAGESIZE);
  108bcb:	8b 55 d8             	mov    0xffffffd8(%ebp),%edx
  108bce:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  108bd3:	89 d1                	mov    %edx,%ecx
  108bd5:	29 c1                	sub    %eax,%ecx
  108bd7:	89 c8                	mov    %ecx,%eax
  108bd9:	c1 e0 09             	shl    $0x9,%eax
  108bdc:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  108be3:	00 
  108be4:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
  108beb:	00 
  108bec:	89 04 24             	mov    %eax,(%esp)
  108bef:	e8 ad 18 00 00       	call   10a4a1 <memset>
	mem_free(pi0);
  108bf4:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  108bf7:	89 04 24             	mov    %eax,(%esp)
  108bfa:	e8 c4 82 ff ff       	call   100ec3 <mem_free>
	pmap_walk(pmap_bootpdir, VM_USERHI-PAGESIZE, 1);
  108bff:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
  108c06:	00 
  108c07:	c7 44 24 04 00 f0 ff 	movl   $0xeffff000,0x4(%esp)
  108c0e:	ef 
  108c0f:	c7 04 24 00 10 12 00 	movl   $0x121000,(%esp)
  108c16:	e8 44 c7 ff ff       	call   10535f <pmap_walk>
	ptep = mem_pi2ptr(pi0);
  108c1b:	8b 55 d8             	mov    0xffffffd8(%ebp),%edx
  108c1e:	a1 9c fd 11 00       	mov    0x11fd9c,%eax
  108c23:	89 d3                	mov    %edx,%ebx
  108c25:	29 c3                	sub    %eax,%ebx
  108c27:	89 d8                	mov    %ebx,%eax
  108c29:	c1 e0 09             	shl    $0x9,%eax
  108c2c:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
	for(i=0; i<NPTENTRIES; i++)
  108c2f:	c7 45 f4 00 00 00 00 	movl   $0x0,0xfffffff4(%ebp)
  108c36:	eb 3c                	jmp    108c74 <pmap_check+0x16d3>
		assert(ptep[i] == PTE_ZERO);
  108c38:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  108c3b:	c1 e0 02             	shl    $0x2,%eax
  108c3e:	03 45 ec             	add    0xffffffec(%ebp),%eax
  108c41:	8b 10                	mov    (%eax),%edx
  108c43:	b8 00 20 12 00       	mov    $0x122000,%eax
  108c48:	39 c2                	cmp    %eax,%edx
  108c4a:	74 24                	je     108c70 <pmap_check+0x16cf>
  108c4c:	c7 44 24 0c 74 c6 10 	movl   $0x10c674,0xc(%esp)
  108c53:	00 
  108c54:	c7 44 24 08 f2 ba 10 	movl   $0x10baf2,0x8(%esp)
  108c5b:	00 
  108c5c:	c7 44 24 04 2e 03 00 	movl   $0x32e,0x4(%esp)
  108c63:	00 
  108c64:	c7 04 24 da bb 10 00 	movl   $0x10bbda,(%esp)
  108c6b:	e8 2c 7b ff ff       	call   10079c <debug_panic>
  108c70:	83 45 f4 01          	addl   $0x1,0xfffffff4(%ebp)
  108c74:	81 7d f4 ff 03 00 00 	cmpl   $0x3ff,0xfffffff4(%ebp)
  108c7b:	7e bb                	jle    108c38 <pmap_check+0x1697>
	pmap_bootpdir[PDX(VM_USERHI-PAGESIZE)] = PTE_ZERO;
  108c7d:	b8 00 20 12 00       	mov    $0x122000,%eax
  108c82:	a3 fc 1e 12 00       	mov    %eax,0x121efc
	pi0->refcount = 0;
  108c87:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  108c8a:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)

	// give free list back
	mem_freelist = fl;
  108c91:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  108c94:	a3 40 fd 11 00       	mov    %eax,0x11fd40

	// free the pages we filched
	mem_free(pi0);
  108c99:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  108c9c:	89 04 24             	mov    %eax,(%esp)
  108c9f:	e8 1f 82 ff ff       	call   100ec3 <mem_free>
	mem_free(pi1);
  108ca4:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  108ca7:	89 04 24             	mov    %eax,(%esp)
  108caa:	e8 14 82 ff ff       	call   100ec3 <mem_free>
	mem_free(pi2);
  108caf:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  108cb2:	89 04 24             	mov    %eax,(%esp)
  108cb5:	e8 09 82 ff ff       	call   100ec3 <mem_free>
	mem_free(pi3);
  108cba:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  108cbd:	89 04 24             	mov    %eax,(%esp)
  108cc0:	e8 fe 81 ff ff       	call   100ec3 <mem_free>

	cprintf("pmap_check() succeeded!\n");
  108cc5:	c7 04 24 88 c6 10 00 	movl   $0x10c688,(%esp)
  108ccc:	e8 d8 15 00 00       	call   10a2a9 <cprintf>
}
  108cd1:	83 c4 44             	add    $0x44,%esp
  108cd4:	5b                   	pop    %ebx
  108cd5:	5d                   	pop    %ebp
  108cd6:	c3                   	ret    
  108cd7:	90                   	nop    

00108cd8 <video_init>:
static uint16_t crt_pos;

void
video_init(void)
{
  108cd8:	55                   	push   %ebp
  108cd9:	89 e5                	mov    %esp,%ebp
  108cdb:	83 ec 30             	sub    $0x30,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	/* Get a pointer to the memory-mapped text display buffer. */
	cp = (uint16_t*) mem_ptr(CGA_BUF);
  108cde:	c7 45 d4 00 80 0b 00 	movl   $0xb8000,0xffffffd4(%ebp)
	was = *cp;
  108ce5:	8b 45 d4             	mov    0xffffffd4(%ebp),%eax
  108ce8:	0f b7 00             	movzwl (%eax),%eax
  108ceb:	66 89 45 da          	mov    %ax,0xffffffda(%ebp)
	*cp = (uint16_t) 0xA55A;
  108cef:	8b 45 d4             	mov    0xffffffd4(%ebp),%eax
  108cf2:	66 c7 00 5a a5       	movw   $0xa55a,(%eax)
	if (*cp != 0xA55A) {
  108cf7:	8b 45 d4             	mov    0xffffffd4(%ebp),%eax
  108cfa:	0f b7 00             	movzwl (%eax),%eax
  108cfd:	66 3d 5a a5          	cmp    $0xa55a,%ax
  108d01:	74 13                	je     108d16 <video_init+0x3e>
		cp = (uint16_t*) mem_ptr(MONO_BUF);
  108d03:	c7 45 d4 00 00 0b 00 	movl   $0xb0000,0xffffffd4(%ebp)
		addr_6845 = MONO_BASE;
  108d0a:	c7 05 d4 fc 11 00 b4 	movl   $0x3b4,0x11fcd4
  108d11:	03 00 00 
  108d14:	eb 14                	jmp    108d2a <video_init+0x52>
	} else {
		*cp = was;
  108d16:	8b 55 d4             	mov    0xffffffd4(%ebp),%edx
  108d19:	0f b7 45 da          	movzwl 0xffffffda(%ebp),%eax
  108d1d:	66 89 02             	mov    %ax,(%edx)
		addr_6845 = CGA_BASE;
  108d20:	c7 05 d4 fc 11 00 d4 	movl   $0x3d4,0x11fcd4
  108d27:	03 00 00 
	}
	
	/* Extract cursor location */
	outb(addr_6845, 14);
  108d2a:	a1 d4 fc 11 00       	mov    0x11fcd4,%eax
  108d2f:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
  108d32:	c6 45 e3 0e          	movb   $0xe,0xffffffe3(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  108d36:	0f b6 45 e3          	movzbl 0xffffffe3(%ebp),%eax
  108d3a:	8b 55 e4             	mov    0xffffffe4(%ebp),%edx
  108d3d:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
  108d3e:	a1 d4 fc 11 00       	mov    0x11fcd4,%eax
  108d43:	83 c0 01             	add    $0x1,%eax
  108d46:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  108d49:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
  108d4c:	ec                   	in     (%dx),%al
  108d4d:	88 45 eb             	mov    %al,0xffffffeb(%ebp)
	return data;
  108d50:	0f b6 45 eb          	movzbl 0xffffffeb(%ebp),%eax
  108d54:	0f b6 c0             	movzbl %al,%eax
  108d57:	c1 e0 08             	shl    $0x8,%eax
  108d5a:	89 45 dc             	mov    %eax,0xffffffdc(%ebp)
	outb(addr_6845, 15);
  108d5d:	a1 d4 fc 11 00       	mov    0x11fcd4,%eax
  108d62:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
  108d65:	c6 45 f3 0f          	movb   $0xf,0xfffffff3(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  108d69:	0f b6 45 f3          	movzbl 0xfffffff3(%ebp),%eax
  108d6d:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  108d70:	ee                   	out    %al,(%dx)
	pos |= inb(addr_6845 + 1);
  108d71:	a1 d4 fc 11 00       	mov    0x11fcd4,%eax
  108d76:	83 c0 01             	add    $0x1,%eax
  108d79:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  108d7c:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  108d7f:	ec                   	in     (%dx),%al
  108d80:	88 45 fb             	mov    %al,0xfffffffb(%ebp)
	return data;
  108d83:	0f b6 45 fb          	movzbl 0xfffffffb(%ebp),%eax
  108d87:	0f b6 c0             	movzbl %al,%eax
  108d8a:	09 45 dc             	or     %eax,0xffffffdc(%ebp)

	crt_buf = (uint16_t*) cp;
  108d8d:	8b 45 d4             	mov    0xffffffd4(%ebp),%eax
  108d90:	a3 d8 fc 11 00       	mov    %eax,0x11fcd8
	crt_pos = pos;
  108d95:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  108d98:	66 a3 dc fc 11 00    	mov    %ax,0x11fcdc
}
  108d9e:	c9                   	leave  
  108d9f:	c3                   	ret    

00108da0 <video_putc>:



void
video_putc(int c)
{
  108da0:	55                   	push   %ebp
  108da1:	89 e5                	mov    %esp,%ebp
  108da3:	53                   	push   %ebx
  108da4:	83 ec 44             	sub    $0x44,%esp
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
  108da7:	8b 45 08             	mov    0x8(%ebp),%eax
  108daa:	b0 00                	mov    $0x0,%al
  108dac:	85 c0                	test   %eax,%eax
  108dae:	75 07                	jne    108db7 <video_putc+0x17>
		c |= 0x0700;
  108db0:	81 4d 08 00 07 00 00 	orl    $0x700,0x8(%ebp)

	switch (c & 0xff) {
  108db7:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
  108dbb:	89 45 c4             	mov    %eax,0xffffffc4(%ebp)
  108dbe:	83 7d c4 09          	cmpl   $0x9,0xffffffc4(%ebp)
  108dc2:	0f 84 c0 00 00 00    	je     108e88 <video_putc+0xe8>
  108dc8:	83 7d c4 09          	cmpl   $0x9,0xffffffc4(%ebp)
  108dcc:	7f 0b                	jg     108dd9 <video_putc+0x39>
  108dce:	83 7d c4 08          	cmpl   $0x8,0xffffffc4(%ebp)
  108dd2:	74 16                	je     108dea <video_putc+0x4a>
  108dd4:	e9 ed 00 00 00       	jmp    108ec6 <video_putc+0x126>
  108dd9:	83 7d c4 0a          	cmpl   $0xa,0xffffffc4(%ebp)
  108ddd:	74 50                	je     108e2f <video_putc+0x8f>
  108ddf:	83 7d c4 0d          	cmpl   $0xd,0xffffffc4(%ebp)
  108de3:	74 5a                	je     108e3f <video_putc+0x9f>
  108de5:	e9 dc 00 00 00       	jmp    108ec6 <video_putc+0x126>
	case '\b':
		if (crt_pos > 0) {
  108dea:	0f b7 05 dc fc 11 00 	movzwl 0x11fcdc,%eax
  108df1:	66 85 c0             	test   %ax,%ax
  108df4:	0f 84 f0 00 00 00    	je     108eea <video_putc+0x14a>
			crt_pos--;
  108dfa:	0f b7 05 dc fc 11 00 	movzwl 0x11fcdc,%eax
  108e01:	83 e8 01             	sub    $0x1,%eax
  108e04:	66 a3 dc fc 11 00    	mov    %ax,0x11fcdc
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
  108e0a:	0f b7 05 dc fc 11 00 	movzwl 0x11fcdc,%eax
  108e11:	0f b7 c0             	movzwl %ax,%eax
  108e14:	01 c0                	add    %eax,%eax
  108e16:	89 c2                	mov    %eax,%edx
  108e18:	a1 d8 fc 11 00       	mov    0x11fcd8,%eax
  108e1d:	01 c2                	add    %eax,%edx
  108e1f:	8b 45 08             	mov    0x8(%ebp),%eax
  108e22:	b0 00                	mov    $0x0,%al
  108e24:	83 c8 20             	or     $0x20,%eax
  108e27:	66 89 02             	mov    %ax,(%edx)
		}
		break;
  108e2a:	e9 bb 00 00 00       	jmp    108eea <video_putc+0x14a>
	case '\n':
		crt_pos += CRT_COLS;
  108e2f:	0f b7 05 dc fc 11 00 	movzwl 0x11fcdc,%eax
  108e36:	83 c0 50             	add    $0x50,%eax
  108e39:	66 a3 dc fc 11 00    	mov    %ax,0x11fcdc
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
  108e3f:	0f b7 0d dc fc 11 00 	movzwl 0x11fcdc,%ecx
  108e46:	0f b7 15 dc fc 11 00 	movzwl 0x11fcdc,%edx
  108e4d:	0f b7 c2             	movzwl %dx,%eax
  108e50:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
  108e56:	c1 e8 10             	shr    $0x10,%eax
  108e59:	89 c3                	mov    %eax,%ebx
  108e5b:	66 c1 eb 06          	shr    $0x6,%bx
  108e5f:	66 89 5d ca          	mov    %bx,0xffffffca(%ebp)
  108e63:	0f b7 45 ca          	movzwl 0xffffffca(%ebp),%eax
  108e67:	c1 e0 02             	shl    $0x2,%eax
  108e6a:	66 03 45 ca          	add    0xffffffca(%ebp),%ax
  108e6e:	c1 e0 04             	shl    $0x4,%eax
  108e71:	89 d3                	mov    %edx,%ebx
  108e73:	66 29 c3             	sub    %ax,%bx
  108e76:	66 89 5d ca          	mov    %bx,0xffffffca(%ebp)
  108e7a:	89 c8                	mov    %ecx,%eax
  108e7c:	66 2b 45 ca          	sub    0xffffffca(%ebp),%ax
  108e80:	66 a3 dc fc 11 00    	mov    %ax,0x11fcdc
		break;
  108e86:	eb 62                	jmp    108eea <video_putc+0x14a>
	case '\t':
		video_putc(' ');
  108e88:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  108e8f:	e8 0c ff ff ff       	call   108da0 <video_putc>
		video_putc(' ');
  108e94:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  108e9b:	e8 00 ff ff ff       	call   108da0 <video_putc>
		video_putc(' ');
  108ea0:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  108ea7:	e8 f4 fe ff ff       	call   108da0 <video_putc>
		video_putc(' ');
  108eac:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  108eb3:	e8 e8 fe ff ff       	call   108da0 <video_putc>
		video_putc(' ');
  108eb8:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  108ebf:	e8 dc fe ff ff       	call   108da0 <video_putc>
		break;
  108ec4:	eb 24                	jmp    108eea <video_putc+0x14a>
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
  108ec6:	0f b7 0d dc fc 11 00 	movzwl 0x11fcdc,%ecx
  108ecd:	0f b7 c1             	movzwl %cx,%eax
  108ed0:	01 c0                	add    %eax,%eax
  108ed2:	89 c2                	mov    %eax,%edx
  108ed4:	a1 d8 fc 11 00       	mov    0x11fcd8,%eax
  108ed9:	01 c2                	add    %eax,%edx
  108edb:	8b 45 08             	mov    0x8(%ebp),%eax
  108ede:	66 89 02             	mov    %ax,(%edx)
  108ee1:	8d 41 01             	lea    0x1(%ecx),%eax
  108ee4:	66 a3 dc fc 11 00    	mov    %ax,0x11fcdc
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
  108eea:	0f b7 05 dc fc 11 00 	movzwl 0x11fcdc,%eax
  108ef1:	66 3d cf 07          	cmp    $0x7cf,%ax
  108ef5:	76 5e                	jbe    108f55 <video_putc+0x1b5>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS,
  108ef7:	a1 d8 fc 11 00       	mov    0x11fcd8,%eax
  108efc:	05 a0 00 00 00       	add    $0xa0,%eax
  108f01:	8b 15 d8 fc 11 00    	mov    0x11fcd8,%edx
  108f07:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
  108f0e:	00 
  108f0f:	89 44 24 04          	mov    %eax,0x4(%esp)
  108f13:	89 14 24             	mov    %edx,(%esp)
  108f16:	e8 ff 15 00 00       	call   10a51a <memmove>
			(CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
  108f1b:	c7 45 d8 80 07 00 00 	movl   $0x780,0xffffffd8(%ebp)
  108f22:	eb 18                	jmp    108f3c <video_putc+0x19c>
			crt_buf[i] = 0x0700 | ' ';
  108f24:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  108f27:	01 c0                	add    %eax,%eax
  108f29:	89 c2                	mov    %eax,%edx
  108f2b:	a1 d8 fc 11 00       	mov    0x11fcd8,%eax
  108f30:	8d 04 02             	lea    (%edx,%eax,1),%eax
  108f33:	66 c7 00 20 07       	movw   $0x720,(%eax)
  108f38:	83 45 d8 01          	addl   $0x1,0xffffffd8(%ebp)
  108f3c:	81 7d d8 cf 07 00 00 	cmpl   $0x7cf,0xffffffd8(%ebp)
  108f43:	7e df                	jle    108f24 <video_putc+0x184>
		crt_pos -= CRT_COLS;
  108f45:	0f b7 05 dc fc 11 00 	movzwl 0x11fcdc,%eax
  108f4c:	83 e8 50             	sub    $0x50,%eax
  108f4f:	66 a3 dc fc 11 00    	mov    %ax,0x11fcdc
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
  108f55:	a1 d4 fc 11 00       	mov    0x11fcd4,%eax
  108f5a:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)
  108f5d:	c6 45 df 0e          	movb   $0xe,0xffffffdf(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  108f61:	0f b6 45 df          	movzbl 0xffffffdf(%ebp),%eax
  108f65:	8b 55 e0             	mov    0xffffffe0(%ebp),%edx
  108f68:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
  108f69:	0f b7 05 dc fc 11 00 	movzwl 0x11fcdc,%eax
  108f70:	66 c1 e8 08          	shr    $0x8,%ax
  108f74:	0f b6 d0             	movzbl %al,%edx
  108f77:	a1 d4 fc 11 00       	mov    0x11fcd4,%eax
  108f7c:	83 c0 01             	add    $0x1,%eax
  108f7f:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  108f82:	88 55 e7             	mov    %dl,0xffffffe7(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  108f85:	0f b6 45 e7          	movzbl 0xffffffe7(%ebp),%eax
  108f89:	8b 55 e8             	mov    0xffffffe8(%ebp),%edx
  108f8c:	ee                   	out    %al,(%dx)
	outb(addr_6845, 15);
  108f8d:	a1 d4 fc 11 00       	mov    0x11fcd4,%eax
  108f92:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
  108f95:	c6 45 ef 0f          	movb   $0xf,0xffffffef(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  108f99:	0f b6 45 ef          	movzbl 0xffffffef(%ebp),%eax
  108f9d:	8b 55 f0             	mov    0xfffffff0(%ebp),%edx
  108fa0:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos);
  108fa1:	0f b7 05 dc fc 11 00 	movzwl 0x11fcdc,%eax
  108fa8:	0f b6 d0             	movzbl %al,%edx
  108fab:	a1 d4 fc 11 00       	mov    0x11fcd4,%eax
  108fb0:	83 c0 01             	add    $0x1,%eax
  108fb3:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  108fb6:	88 55 f7             	mov    %dl,0xfffffff7(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  108fb9:	0f b6 45 f7          	movzbl 0xfffffff7(%ebp),%eax
  108fbd:	8b 55 f8             	mov    0xfffffff8(%ebp),%edx
  108fc0:	ee                   	out    %al,(%dx)
}
  108fc1:	83 c4 44             	add    $0x44,%esp
  108fc4:	5b                   	pop    %ebx
  108fc5:	5d                   	pop    %ebp
  108fc6:	c3                   	ret    
  108fc7:	90                   	nop    

00108fc8 <kbd_proc_data>:
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
  108fc8:	55                   	push   %ebp
  108fc9:	89 e5                	mov    %esp,%ebp
  108fcb:	83 ec 38             	sub    $0x38,%esp
  108fce:	c7 45 ec 64 00 00 00 	movl   $0x64,0xffffffec(%ebp)
static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  108fd5:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
  108fd8:	ec                   	in     (%dx),%al
  108fd9:	88 45 eb             	mov    %al,0xffffffeb(%ebp)
	return data;
  108fdc:	0f b6 45 eb          	movzbl 0xffffffeb(%ebp),%eax
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
  108fe0:	0f b6 c0             	movzbl %al,%eax
  108fe3:	83 e0 01             	and    $0x1,%eax
  108fe6:	85 c0                	test   %eax,%eax
  108fe8:	75 0c                	jne    108ff6 <kbd_proc_data+0x2e>
		return -1;
  108fea:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,0xffffffd8(%ebp)
  108ff1:	e9 69 01 00 00       	jmp    10915f <kbd_proc_data+0x197>
  108ff6:	c7 45 f4 60 00 00 00 	movl   $0x60,0xfffffff4(%ebp)
static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  108ffd:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  109000:	ec                   	in     (%dx),%al
  109001:	88 45 f3             	mov    %al,0xfffffff3(%ebp)
	return data;
  109004:	0f b6 45 f3          	movzbl 0xfffffff3(%ebp),%eax

	data = inb(KBDATAP);
  109008:	88 45 ea             	mov    %al,0xffffffea(%ebp)

	if (data == 0xE0) {
  10900b:	80 7d ea e0          	cmpb   $0xe0,0xffffffea(%ebp)
  10900f:	75 19                	jne    10902a <kbd_proc_data+0x62>
		// E0 escape character
		shift |= E0ESC;
  109011:	a1 e0 fc 11 00       	mov    0x11fce0,%eax
  109016:	83 c8 40             	or     $0x40,%eax
  109019:	a3 e0 fc 11 00       	mov    %eax,0x11fce0
		return 0;
  10901e:	c7 45 d8 00 00 00 00 	movl   $0x0,0xffffffd8(%ebp)
  109025:	e9 35 01 00 00       	jmp    10915f <kbd_proc_data+0x197>
	} else if (data & 0x80) {
  10902a:	0f b6 45 ea          	movzbl 0xffffffea(%ebp),%eax
  10902e:	84 c0                	test   %al,%al
  109030:	79 53                	jns    109085 <kbd_proc_data+0xbd>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
  109032:	a1 e0 fc 11 00       	mov    0x11fce0,%eax
  109037:	83 e0 40             	and    $0x40,%eax
  10903a:	85 c0                	test   %eax,%eax
  10903c:	75 0c                	jne    10904a <kbd_proc_data+0x82>
  10903e:	0f b6 45 ea          	movzbl 0xffffffea(%ebp),%eax
  109042:	83 e0 7f             	and    $0x7f,%eax
  109045:	88 45 df             	mov    %al,0xffffffdf(%ebp)
  109048:	eb 07                	jmp    109051 <kbd_proc_data+0x89>
  10904a:	0f b6 45 ea          	movzbl 0xffffffea(%ebp),%eax
  10904e:	88 45 df             	mov    %al,0xffffffdf(%ebp)
  109051:	0f b6 45 df          	movzbl 0xffffffdf(%ebp),%eax
  109055:	88 45 ea             	mov    %al,0xffffffea(%ebp)
		shift &= ~(shiftcode[data] | E0ESC);
  109058:	0f b6 45 ea          	movzbl 0xffffffea(%ebp),%eax
  10905c:	0f b6 80 20 e0 10 00 	movzbl 0x10e020(%eax),%eax
  109063:	83 c8 40             	or     $0x40,%eax
  109066:	0f b6 c0             	movzbl %al,%eax
  109069:	f7 d0                	not    %eax
  10906b:	89 c2                	mov    %eax,%edx
  10906d:	a1 e0 fc 11 00       	mov    0x11fce0,%eax
  109072:	21 d0                	and    %edx,%eax
  109074:	a3 e0 fc 11 00       	mov    %eax,0x11fce0
		return 0;
  109079:	c7 45 d8 00 00 00 00 	movl   $0x0,0xffffffd8(%ebp)
  109080:	e9 da 00 00 00       	jmp    10915f <kbd_proc_data+0x197>
	} else if (shift & E0ESC) {
  109085:	a1 e0 fc 11 00       	mov    0x11fce0,%eax
  10908a:	83 e0 40             	and    $0x40,%eax
  10908d:	85 c0                	test   %eax,%eax
  10908f:	74 11                	je     1090a2 <kbd_proc_data+0xda>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
  109091:	80 4d ea 80          	orb    $0x80,0xffffffea(%ebp)
		shift &= ~E0ESC;
  109095:	a1 e0 fc 11 00       	mov    0x11fce0,%eax
  10909a:	83 e0 bf             	and    $0xffffffbf,%eax
  10909d:	a3 e0 fc 11 00       	mov    %eax,0x11fce0
	}

	shift |= shiftcode[data];
  1090a2:	0f b6 45 ea          	movzbl 0xffffffea(%ebp),%eax
  1090a6:	0f b6 80 20 e0 10 00 	movzbl 0x10e020(%eax),%eax
  1090ad:	0f b6 d0             	movzbl %al,%edx
  1090b0:	a1 e0 fc 11 00       	mov    0x11fce0,%eax
  1090b5:	09 d0                	or     %edx,%eax
  1090b7:	a3 e0 fc 11 00       	mov    %eax,0x11fce0
	shift ^= togglecode[data];
  1090bc:	0f b6 45 ea          	movzbl 0xffffffea(%ebp),%eax
  1090c0:	0f b6 80 20 e1 10 00 	movzbl 0x10e120(%eax),%eax
  1090c7:	0f b6 d0             	movzbl %al,%edx
  1090ca:	a1 e0 fc 11 00       	mov    0x11fce0,%eax
  1090cf:	31 d0                	xor    %edx,%eax
  1090d1:	a3 e0 fc 11 00       	mov    %eax,0x11fce0

	c = charcode[shift & (CTL | SHIFT)][data];
  1090d6:	a1 e0 fc 11 00       	mov    0x11fce0,%eax
  1090db:	83 e0 03             	and    $0x3,%eax
  1090de:	8b 14 85 20 e5 10 00 	mov    0x10e520(,%eax,4),%edx
  1090e5:	0f b6 45 ea          	movzbl 0xffffffea(%ebp),%eax
  1090e9:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1090ec:	0f b6 00             	movzbl (%eax),%eax
  1090ef:	0f b6 c0             	movzbl %al,%eax
  1090f2:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
	if (shift & CAPSLOCK) {
  1090f5:	a1 e0 fc 11 00       	mov    0x11fce0,%eax
  1090fa:	83 e0 08             	and    $0x8,%eax
  1090fd:	85 c0                	test   %eax,%eax
  1090ff:	74 22                	je     109123 <kbd_proc_data+0x15b>
		if ('a' <= c && c <= 'z')
  109101:	83 7d e4 60          	cmpl   $0x60,0xffffffe4(%ebp)
  109105:	7e 0c                	jle    109113 <kbd_proc_data+0x14b>
  109107:	83 7d e4 7a          	cmpl   $0x7a,0xffffffe4(%ebp)
  10910b:	7f 06                	jg     109113 <kbd_proc_data+0x14b>
			c += 'A' - 'a';
  10910d:	83 6d e4 20          	subl   $0x20,0xffffffe4(%ebp)
  109111:	eb 10                	jmp    109123 <kbd_proc_data+0x15b>
		else if ('A' <= c && c <= 'Z')
  109113:	83 7d e4 40          	cmpl   $0x40,0xffffffe4(%ebp)
  109117:	7e 0a                	jle    109123 <kbd_proc_data+0x15b>
  109119:	83 7d e4 5a          	cmpl   $0x5a,0xffffffe4(%ebp)
  10911d:	7f 04                	jg     109123 <kbd_proc_data+0x15b>
			c += 'a' - 'A';
  10911f:	83 45 e4 20          	addl   $0x20,0xffffffe4(%ebp)
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
  109123:	a1 e0 fc 11 00       	mov    0x11fce0,%eax
  109128:	f7 d0                	not    %eax
  10912a:	83 e0 06             	and    $0x6,%eax
  10912d:	85 c0                	test   %eax,%eax
  10912f:	75 28                	jne    109159 <kbd_proc_data+0x191>
  109131:	81 7d e4 e9 00 00 00 	cmpl   $0xe9,0xffffffe4(%ebp)
  109138:	75 1f                	jne    109159 <kbd_proc_data+0x191>
		cprintf("Rebooting!\n");
  10913a:	c7 04 24 a1 c6 10 00 	movl   $0x10c6a1,(%esp)
  109141:	e8 63 11 00 00       	call   10a2a9 <cprintf>
  109146:	c7 45 fc 92 00 00 00 	movl   $0x92,0xfffffffc(%ebp)
  10914d:	c6 45 fb 03          	movb   $0x3,0xfffffffb(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  109151:	0f b6 45 fb          	movzbl 0xfffffffb(%ebp),%eax
  109155:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  109158:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
  109159:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  10915c:	89 45 d8             	mov    %eax,0xffffffd8(%ebp)
  10915f:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
}
  109162:	c9                   	leave  
  109163:	c3                   	ret    

00109164 <kbd_intr>:

void
kbd_intr(void)
{
  109164:	55                   	push   %ebp
  109165:	89 e5                	mov    %esp,%ebp
  109167:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
  10916a:	c7 04 24 c8 8f 10 00 	movl   $0x108fc8,(%esp)
  109171:	e8 ee 73 ff ff       	call   100564 <cons_intr>
}
  109176:	c9                   	leave  
  109177:	c3                   	ret    

00109178 <kbd_init>:

void
kbd_init(void)
{
  109178:	55                   	push   %ebp
  109179:	89 e5                	mov    %esp,%ebp
}
  10917b:	5d                   	pop    %ebp
  10917c:	c3                   	ret    
  10917d:	90                   	nop    
  10917e:	90                   	nop    
  10917f:	90                   	nop    

00109180 <delay>:

// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
  109180:	55                   	push   %ebp
  109181:	89 e5                	mov    %esp,%ebp
  109183:	83 ec 20             	sub    $0x20,%esp
  109186:	c7 45 e4 84 00 00 00 	movl   $0x84,0xffffffe4(%ebp)
static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  10918d:	8b 55 e4             	mov    0xffffffe4(%ebp),%edx
  109190:	ec                   	in     (%dx),%al
  109191:	88 45 e3             	mov    %al,0xffffffe3(%ebp)
	return data;
  109194:	c7 45 ec 84 00 00 00 	movl   $0x84,0xffffffec(%ebp)
  10919b:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
  10919e:	ec                   	in     (%dx),%al
  10919f:	88 45 eb             	mov    %al,0xffffffeb(%ebp)
  1091a2:	c7 45 f4 84 00 00 00 	movl   $0x84,0xfffffff4(%ebp)
  1091a9:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  1091ac:	ec                   	in     (%dx),%al
  1091ad:	88 45 f3             	mov    %al,0xfffffff3(%ebp)
  1091b0:	c7 45 fc 84 00 00 00 	movl   $0x84,0xfffffffc(%ebp)
  1091b7:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  1091ba:	ec                   	in     (%dx),%al
  1091bb:	88 45 fb             	mov    %al,0xfffffffb(%ebp)
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
  1091be:	c9                   	leave  
  1091bf:	c3                   	ret    

001091c0 <serial_proc_data>:

static int
serial_proc_data(void)
{
  1091c0:	55                   	push   %ebp
  1091c1:	89 e5                	mov    %esp,%ebp
  1091c3:	83 ec 14             	sub    $0x14,%esp
  1091c6:	c7 45 f4 fd 03 00 00 	movl   $0x3fd,0xfffffff4(%ebp)
static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  1091cd:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  1091d0:	ec                   	in     (%dx),%al
  1091d1:	88 45 f3             	mov    %al,0xfffffff3(%ebp)
	return data;
  1091d4:	0f b6 45 f3          	movzbl 0xfffffff3(%ebp),%eax
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
  1091d8:	0f b6 c0             	movzbl %al,%eax
  1091db:	83 e0 01             	and    $0x1,%eax
  1091de:	85 c0                	test   %eax,%eax
  1091e0:	75 09                	jne    1091eb <serial_proc_data+0x2b>
		return -1;
  1091e2:	c7 45 ec ff ff ff ff 	movl   $0xffffffff,0xffffffec(%ebp)
  1091e9:	eb 18                	jmp    109203 <serial_proc_data+0x43>
  1091eb:	c7 45 fc f8 03 00 00 	movl   $0x3f8,0xfffffffc(%ebp)
static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  1091f2:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  1091f5:	ec                   	in     (%dx),%al
  1091f6:	88 45 fb             	mov    %al,0xfffffffb(%ebp)
	return data;
  1091f9:	0f b6 45 fb          	movzbl 0xfffffffb(%ebp),%eax
	return inb(COM1+COM_RX);
  1091fd:	0f b6 c0             	movzbl %al,%eax
  109200:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  109203:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
}
  109206:	c9                   	leave  
  109207:	c3                   	ret    

00109208 <serial_intr>:

void
serial_intr(void)
{
  109208:	55                   	push   %ebp
  109209:	89 e5                	mov    %esp,%ebp
  10920b:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
  10920e:	a1 00 30 12 00       	mov    0x123000,%eax
  109213:	85 c0                	test   %eax,%eax
  109215:	74 0c                	je     109223 <serial_intr+0x1b>
		cons_intr(serial_proc_data);
  109217:	c7 04 24 c0 91 10 00 	movl   $0x1091c0,(%esp)
  10921e:	e8 41 73 ff ff       	call   100564 <cons_intr>
}
  109223:	c9                   	leave  
  109224:	c3                   	ret    

00109225 <serial_putc>:

void
serial_putc(int c)
{
  109225:	55                   	push   %ebp
  109226:	89 e5                	mov    %esp,%ebp
  109228:	83 ec 20             	sub    $0x20,%esp
	if (!serial_exists)
  10922b:	a1 00 30 12 00       	mov    0x123000,%eax
  109230:	85 c0                	test   %eax,%eax
  109232:	74 4f                	je     109283 <serial_putc+0x5e>
		return;

	int i;
	for (i = 0;
  109234:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
  10923b:	eb 09                	jmp    109246 <serial_putc+0x21>
	     i++)
		delay();
  10923d:	e8 3e ff ff ff       	call   109180 <delay>
  109242:	83 45 ec 01          	addl   $0x1,0xffffffec(%ebp)
  109246:	c7 45 f4 fd 03 00 00 	movl   $0x3fd,0xfffffff4(%ebp)
static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  10924d:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  109250:	ec                   	in     (%dx),%al
  109251:	88 45 f3             	mov    %al,0xfffffff3(%ebp)
	return data;
  109254:	0f b6 45 f3          	movzbl 0xfffffff3(%ebp),%eax
  109258:	0f b6 c0             	movzbl %al,%eax
  10925b:	83 e0 20             	and    $0x20,%eax
  10925e:	85 c0                	test   %eax,%eax
  109260:	75 09                	jne    10926b <serial_putc+0x46>
  109262:	81 7d ec ff 31 00 00 	cmpl   $0x31ff,0xffffffec(%ebp)
  109269:	7e d2                	jle    10923d <serial_putc+0x18>
	
	outb(COM1 + COM_TX, c);
  10926b:	8b 45 08             	mov    0x8(%ebp),%eax
  10926e:	0f b6 c0             	movzbl %al,%eax
  109271:	c7 45 fc f8 03 00 00 	movl   $0x3f8,0xfffffffc(%ebp)
  109278:	88 45 fb             	mov    %al,0xfffffffb(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  10927b:	0f b6 45 fb          	movzbl 0xfffffffb(%ebp),%eax
  10927f:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  109282:	ee                   	out    %al,(%dx)
}
  109283:	c9                   	leave  
  109284:	c3                   	ret    

00109285 <serial_init>:

void
serial_init(void)
{
  109285:	55                   	push   %ebp
  109286:	89 e5                	mov    %esp,%ebp
  109288:	83 ec 50             	sub    $0x50,%esp
  10928b:	c7 45 b4 fa 03 00 00 	movl   $0x3fa,0xffffffb4(%ebp)
  109292:	c6 45 b3 00          	movb   $0x0,0xffffffb3(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  109296:	0f b6 45 b3          	movzbl 0xffffffb3(%ebp),%eax
  10929a:	8b 55 b4             	mov    0xffffffb4(%ebp),%edx
  10929d:	ee                   	out    %al,(%dx)
  10929e:	c7 45 bc fb 03 00 00 	movl   $0x3fb,0xffffffbc(%ebp)
  1092a5:	c6 45 bb 80          	movb   $0x80,0xffffffbb(%ebp)
  1092a9:	0f b6 45 bb          	movzbl 0xffffffbb(%ebp),%eax
  1092ad:	8b 55 bc             	mov    0xffffffbc(%ebp),%edx
  1092b0:	ee                   	out    %al,(%dx)
  1092b1:	c7 45 c4 f8 03 00 00 	movl   $0x3f8,0xffffffc4(%ebp)
  1092b8:	c6 45 c3 0c          	movb   $0xc,0xffffffc3(%ebp)
  1092bc:	0f b6 45 c3          	movzbl 0xffffffc3(%ebp),%eax
  1092c0:	8b 55 c4             	mov    0xffffffc4(%ebp),%edx
  1092c3:	ee                   	out    %al,(%dx)
  1092c4:	c7 45 cc f9 03 00 00 	movl   $0x3f9,0xffffffcc(%ebp)
  1092cb:	c6 45 cb 00          	movb   $0x0,0xffffffcb(%ebp)
  1092cf:	0f b6 45 cb          	movzbl 0xffffffcb(%ebp),%eax
  1092d3:	8b 55 cc             	mov    0xffffffcc(%ebp),%edx
  1092d6:	ee                   	out    %al,(%dx)
  1092d7:	c7 45 d4 fb 03 00 00 	movl   $0x3fb,0xffffffd4(%ebp)
  1092de:	c6 45 d3 03          	movb   $0x3,0xffffffd3(%ebp)
  1092e2:	0f b6 45 d3          	movzbl 0xffffffd3(%ebp),%eax
  1092e6:	8b 55 d4             	mov    0xffffffd4(%ebp),%edx
  1092e9:	ee                   	out    %al,(%dx)
  1092ea:	c7 45 dc fc 03 00 00 	movl   $0x3fc,0xffffffdc(%ebp)
  1092f1:	c6 45 db 00          	movb   $0x0,0xffffffdb(%ebp)
  1092f5:	0f b6 45 db          	movzbl 0xffffffdb(%ebp),%eax
  1092f9:	8b 55 dc             	mov    0xffffffdc(%ebp),%edx
  1092fc:	ee                   	out    %al,(%dx)
  1092fd:	c7 45 e4 f9 03 00 00 	movl   $0x3f9,0xffffffe4(%ebp)
  109304:	c6 45 e3 01          	movb   $0x1,0xffffffe3(%ebp)
  109308:	0f b6 45 e3          	movzbl 0xffffffe3(%ebp),%eax
  10930c:	8b 55 e4             	mov    0xffffffe4(%ebp),%edx
  10930f:	ee                   	out    %al,(%dx)
  109310:	c7 45 ec fd 03 00 00 	movl   $0x3fd,0xffffffec(%ebp)
  109317:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
  10931a:	ec                   	in     (%dx),%al
  10931b:	88 45 eb             	mov    %al,0xffffffeb(%ebp)
  10931e:	0f b6 45 eb          	movzbl 0xffffffeb(%ebp),%eax
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
  109322:	3c ff                	cmp    $0xff,%al
  109324:	0f 95 c0             	setne  %al
  109327:	0f b6 c0             	movzbl %al,%eax
  10932a:	a3 00 30 12 00       	mov    %eax,0x123000
  10932f:	c7 45 f4 fa 03 00 00 	movl   $0x3fa,0xfffffff4(%ebp)
static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  109336:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  109339:	ec                   	in     (%dx),%al
  10933a:	88 45 f3             	mov    %al,0xfffffff3(%ebp)
	return data;
  10933d:	c7 45 fc f8 03 00 00 	movl   $0x3f8,0xfffffffc(%ebp)
  109344:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  109347:	ec                   	in     (%dx),%al
  109348:	88 45 fb             	mov    %al,0xfffffffb(%ebp)
	(void) inb(COM1+COM_IIR);
	(void) inb(COM1+COM_RX);
}
  10934b:	c9                   	leave  
  10934c:	c3                   	ret    
  10934d:	90                   	nop    
  10934e:	90                   	nop    
  10934f:	90                   	nop    

00109350 <pic_init>:

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
  109350:	55                   	push   %ebp
  109351:	89 e5                	mov    %esp,%ebp
  109353:	83 ec 78             	sub    $0x78,%esp
	if (didinit)		// only do once on bootstrap CPU
  109356:	a1 e4 fc 11 00       	mov    0x11fce4,%eax
  10935b:	85 c0                	test   %eax,%eax
  10935d:	0f 85 33 01 00 00    	jne    109496 <pic_init+0x146>
		return;
	didinit = 1;
  109363:	c7 05 e4 fc 11 00 01 	movl   $0x1,0x11fce4
  10936a:	00 00 00 
  10936d:	c7 45 94 21 00 00 00 	movl   $0x21,0xffffff94(%ebp)
  109374:	c6 45 93 ff          	movb   $0xff,0xffffff93(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  109378:	0f b6 45 93          	movzbl 0xffffff93(%ebp),%eax
  10937c:	8b 55 94             	mov    0xffffff94(%ebp),%edx
  10937f:	ee                   	out    %al,(%dx)
  109380:	c7 45 9c a1 00 00 00 	movl   $0xa1,0xffffff9c(%ebp)
  109387:	c6 45 9b ff          	movb   $0xff,0xffffff9b(%ebp)
  10938b:	0f b6 45 9b          	movzbl 0xffffff9b(%ebp),%eax
  10938f:	8b 55 9c             	mov    0xffffff9c(%ebp),%edx
  109392:	ee                   	out    %al,(%dx)
  109393:	c7 45 a4 20 00 00 00 	movl   $0x20,0xffffffa4(%ebp)
  10939a:	c6 45 a3 11          	movb   $0x11,0xffffffa3(%ebp)
  10939e:	0f b6 45 a3          	movzbl 0xffffffa3(%ebp),%eax
  1093a2:	8b 55 a4             	mov    0xffffffa4(%ebp),%edx
  1093a5:	ee                   	out    %al,(%dx)
  1093a6:	c7 45 ac 21 00 00 00 	movl   $0x21,0xffffffac(%ebp)
  1093ad:	c6 45 ab 20          	movb   $0x20,0xffffffab(%ebp)
  1093b1:	0f b6 45 ab          	movzbl 0xffffffab(%ebp),%eax
  1093b5:	8b 55 ac             	mov    0xffffffac(%ebp),%edx
  1093b8:	ee                   	out    %al,(%dx)
  1093b9:	c7 45 b4 21 00 00 00 	movl   $0x21,0xffffffb4(%ebp)
  1093c0:	c6 45 b3 04          	movb   $0x4,0xffffffb3(%ebp)
  1093c4:	0f b6 45 b3          	movzbl 0xffffffb3(%ebp),%eax
  1093c8:	8b 55 b4             	mov    0xffffffb4(%ebp),%edx
  1093cb:	ee                   	out    %al,(%dx)
  1093cc:	c7 45 bc 21 00 00 00 	movl   $0x21,0xffffffbc(%ebp)
  1093d3:	c6 45 bb 03          	movb   $0x3,0xffffffbb(%ebp)
  1093d7:	0f b6 45 bb          	movzbl 0xffffffbb(%ebp),%eax
  1093db:	8b 55 bc             	mov    0xffffffbc(%ebp),%edx
  1093de:	ee                   	out    %al,(%dx)
  1093df:	c7 45 c4 a0 00 00 00 	movl   $0xa0,0xffffffc4(%ebp)
  1093e6:	c6 45 c3 11          	movb   $0x11,0xffffffc3(%ebp)
  1093ea:	0f b6 45 c3          	movzbl 0xffffffc3(%ebp),%eax
  1093ee:	8b 55 c4             	mov    0xffffffc4(%ebp),%edx
  1093f1:	ee                   	out    %al,(%dx)
  1093f2:	c7 45 cc a1 00 00 00 	movl   $0xa1,0xffffffcc(%ebp)
  1093f9:	c6 45 cb 28          	movb   $0x28,0xffffffcb(%ebp)
  1093fd:	0f b6 45 cb          	movzbl 0xffffffcb(%ebp),%eax
  109401:	8b 55 cc             	mov    0xffffffcc(%ebp),%edx
  109404:	ee                   	out    %al,(%dx)
  109405:	c7 45 d4 a1 00 00 00 	movl   $0xa1,0xffffffd4(%ebp)
  10940c:	c6 45 d3 02          	movb   $0x2,0xffffffd3(%ebp)
  109410:	0f b6 45 d3          	movzbl 0xffffffd3(%ebp),%eax
  109414:	8b 55 d4             	mov    0xffffffd4(%ebp),%edx
  109417:	ee                   	out    %al,(%dx)
  109418:	c7 45 dc a1 00 00 00 	movl   $0xa1,0xffffffdc(%ebp)
  10941f:	c6 45 db 01          	movb   $0x1,0xffffffdb(%ebp)
  109423:	0f b6 45 db          	movzbl 0xffffffdb(%ebp),%eax
  109427:	8b 55 dc             	mov    0xffffffdc(%ebp),%edx
  10942a:	ee                   	out    %al,(%dx)
  10942b:	c7 45 e4 20 00 00 00 	movl   $0x20,0xffffffe4(%ebp)
  109432:	c6 45 e3 68          	movb   $0x68,0xffffffe3(%ebp)
  109436:	0f b6 45 e3          	movzbl 0xffffffe3(%ebp),%eax
  10943a:	8b 55 e4             	mov    0xffffffe4(%ebp),%edx
  10943d:	ee                   	out    %al,(%dx)
  10943e:	c7 45 ec 20 00 00 00 	movl   $0x20,0xffffffec(%ebp)
  109445:	c6 45 eb 0a          	movb   $0xa,0xffffffeb(%ebp)
  109449:	0f b6 45 eb          	movzbl 0xffffffeb(%ebp),%eax
  10944d:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
  109450:	ee                   	out    %al,(%dx)
  109451:	c7 45 f4 a0 00 00 00 	movl   $0xa0,0xfffffff4(%ebp)
  109458:	c6 45 f3 68          	movb   $0x68,0xfffffff3(%ebp)
  10945c:	0f b6 45 f3          	movzbl 0xfffffff3(%ebp),%eax
  109460:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  109463:	ee                   	out    %al,(%dx)
  109464:	c7 45 fc a0 00 00 00 	movl   $0xa0,0xfffffffc(%ebp)
  10946b:	c6 45 fb 0a          	movb   $0xa,0xfffffffb(%ebp)
  10946f:	0f b6 45 fb          	movzbl 0xfffffffb(%ebp),%eax
  109473:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  109476:	ee                   	out    %al,(%dx)

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
  109477:	0f b7 05 30 e5 10 00 	movzwl 0x10e530,%eax
  10947e:	66 83 f8 ff          	cmp    $0xffffffff,%ax
  109482:	74 12                	je     109496 <pic_init+0x146>
		pic_setmask(irqmask);
  109484:	0f b7 05 30 e5 10 00 	movzwl 0x10e530,%eax
  10948b:	0f b7 c0             	movzwl %ax,%eax
  10948e:	89 04 24             	mov    %eax,(%esp)
  109491:	e8 02 00 00 00       	call   109498 <pic_setmask>
}
  109496:	c9                   	leave  
  109497:	c3                   	ret    

00109498 <pic_setmask>:

void
pic_setmask(uint16_t mask)
{
  109498:	55                   	push   %ebp
  109499:	89 e5                	mov    %esp,%ebp
  10949b:	83 ec 14             	sub    $0x14,%esp
  10949e:	8b 45 08             	mov    0x8(%ebp),%eax
  1094a1:	66 89 45 ec          	mov    %ax,0xffffffec(%ebp)
	irqmask = mask;
  1094a5:	0f b7 45 ec          	movzwl 0xffffffec(%ebp),%eax
  1094a9:	66 a3 30 e5 10 00    	mov    %ax,0x10e530
	outb(IO_PIC1+1, (char)mask);
  1094af:	0f b7 45 ec          	movzwl 0xffffffec(%ebp),%eax
  1094b3:	0f b6 c0             	movzbl %al,%eax
  1094b6:	c7 45 f4 21 00 00 00 	movl   $0x21,0xfffffff4(%ebp)
  1094bd:	88 45 f3             	mov    %al,0xfffffff3(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  1094c0:	0f b6 45 f3          	movzbl 0xfffffff3(%ebp),%eax
  1094c4:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  1094c7:	ee                   	out    %al,(%dx)
	outb(IO_PIC2+1, (char)(mask >> 8));
  1094c8:	0f b7 45 ec          	movzwl 0xffffffec(%ebp),%eax
  1094cc:	66 c1 e8 08          	shr    $0x8,%ax
  1094d0:	0f b6 c0             	movzbl %al,%eax
  1094d3:	c7 45 fc a1 00 00 00 	movl   $0xa1,0xfffffffc(%ebp)
  1094da:	88 45 fb             	mov    %al,0xfffffffb(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  1094dd:	0f b6 45 fb          	movzbl 0xfffffffb(%ebp),%eax
  1094e1:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  1094e4:	ee                   	out    %al,(%dx)
}
  1094e5:	c9                   	leave  
  1094e6:	c3                   	ret    

001094e7 <pic_enable>:

void
pic_enable(int irq)
{
  1094e7:	55                   	push   %ebp
  1094e8:	89 e5                	mov    %esp,%ebp
  1094ea:	83 ec 04             	sub    $0x4,%esp
	pic_setmask(irqmask & ~(1 << irq));
  1094ed:	8b 4d 08             	mov    0x8(%ebp),%ecx
  1094f0:	b8 01 00 00 00       	mov    $0x1,%eax
  1094f5:	d3 e0                	shl    %cl,%eax
  1094f7:	89 c2                	mov    %eax,%edx
  1094f9:	f7 d2                	not    %edx
  1094fb:	0f b7 05 30 e5 10 00 	movzwl 0x10e530,%eax
  109502:	21 d0                	and    %edx,%eax
  109504:	0f b7 c0             	movzwl %ax,%eax
  109507:	89 04 24             	mov    %eax,(%esp)
  10950a:	e8 89 ff ff ff       	call   109498 <pic_setmask>
}
  10950f:	c9                   	leave  
  109510:	c3                   	ret    
  109511:	90                   	nop    
  109512:	90                   	nop    
  109513:	90                   	nop    

00109514 <nvram_read>:


unsigned
nvram_read(unsigned reg)
{
  109514:	55                   	push   %ebp
  109515:	89 e5                	mov    %esp,%ebp
  109517:	83 ec 10             	sub    $0x10,%esp
	outb(IO_RTC, reg);
  10951a:	8b 45 08             	mov    0x8(%ebp),%eax
  10951d:	0f b6 c0             	movzbl %al,%eax
  109520:	c7 45 f4 70 00 00 00 	movl   $0x70,0xfffffff4(%ebp)
  109527:	88 45 f3             	mov    %al,0xfffffff3(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  10952a:	0f b6 45 f3          	movzbl 0xfffffff3(%ebp),%eax
  10952e:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  109531:	ee                   	out    %al,(%dx)
  109532:	c7 45 fc 71 00 00 00 	movl   $0x71,0xfffffffc(%ebp)
  109539:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  10953c:	ec                   	in     (%dx),%al
  10953d:	88 45 fb             	mov    %al,0xfffffffb(%ebp)
  109540:	0f b6 45 fb          	movzbl 0xfffffffb(%ebp),%eax
	return inb(IO_RTC+1);
  109544:	0f b6 c0             	movzbl %al,%eax
}
  109547:	c9                   	leave  
  109548:	c3                   	ret    

00109549 <nvram_read16>:

unsigned
nvram_read16(unsigned r)
{
  109549:	55                   	push   %ebp
  10954a:	89 e5                	mov    %esp,%ebp
  10954c:	53                   	push   %ebx
  10954d:	83 ec 04             	sub    $0x4,%esp
	return nvram_read(r) | (nvram_read(r + 1) << 8);
  109550:	8b 45 08             	mov    0x8(%ebp),%eax
  109553:	89 04 24             	mov    %eax,(%esp)
  109556:	e8 b9 ff ff ff       	call   109514 <nvram_read>
  10955b:	89 c3                	mov    %eax,%ebx
  10955d:	8b 45 08             	mov    0x8(%ebp),%eax
  109560:	83 c0 01             	add    $0x1,%eax
  109563:	89 04 24             	mov    %eax,(%esp)
  109566:	e8 a9 ff ff ff       	call   109514 <nvram_read>
  10956b:	c1 e0 08             	shl    $0x8,%eax
  10956e:	09 d8                	or     %ebx,%eax
}
  109570:	83 c4 04             	add    $0x4,%esp
  109573:	5b                   	pop    %ebx
  109574:	5d                   	pop    %ebp
  109575:	c3                   	ret    

00109576 <nvram_write>:

void
nvram_write(unsigned reg, unsigned datum)
{
  109576:	55                   	push   %ebp
  109577:	89 e5                	mov    %esp,%ebp
  109579:	83 ec 10             	sub    $0x10,%esp
	outb(IO_RTC, reg);
  10957c:	8b 45 08             	mov    0x8(%ebp),%eax
  10957f:	0f b6 c0             	movzbl %al,%eax
  109582:	c7 45 f4 70 00 00 00 	movl   $0x70,0xfffffff4(%ebp)
  109589:	88 45 f3             	mov    %al,0xfffffff3(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  10958c:	0f b6 45 f3          	movzbl 0xfffffff3(%ebp),%eax
  109590:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  109593:	ee                   	out    %al,(%dx)
	outb(IO_RTC+1, datum);
  109594:	8b 45 0c             	mov    0xc(%ebp),%eax
  109597:	0f b6 c0             	movzbl %al,%eax
  10959a:	c7 45 fc 71 00 00 00 	movl   $0x71,0xfffffffc(%ebp)
  1095a1:	88 45 fb             	mov    %al,0xfffffffb(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  1095a4:	0f b6 45 fb          	movzbl 0xfffffffb(%ebp),%eax
  1095a8:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  1095ab:	ee                   	out    %al,(%dx)
}
  1095ac:	c9                   	leave  
  1095ad:	c3                   	ret    
  1095ae:	90                   	nop    
  1095af:	90                   	nop    

001095b0 <lapicw>:


static void
lapicw(int index, int value)
{
  1095b0:	55                   	push   %ebp
  1095b1:	89 e5                	mov    %esp,%ebp
	lapic[index] = value;
  1095b3:	8b 45 08             	mov    0x8(%ebp),%eax
  1095b6:	c1 e0 02             	shl    $0x2,%eax
  1095b9:	89 c2                	mov    %eax,%edx
  1095bb:	a1 04 30 12 00       	mov    0x123004,%eax
  1095c0:	01 c2                	add    %eax,%edx
  1095c2:	8b 45 0c             	mov    0xc(%ebp),%eax
  1095c5:	89 02                	mov    %eax,(%edx)
	lapic[ID];  // wait for write to finish, by reading
  1095c7:	a1 04 30 12 00       	mov    0x123004,%eax
  1095cc:	83 c0 20             	add    $0x20,%eax
  1095cf:	8b 00                	mov    (%eax),%eax
}
  1095d1:	5d                   	pop    %ebp
  1095d2:	c3                   	ret    

001095d3 <lapic_init>:

void
lapic_init()
{
  1095d3:	55                   	push   %ebp
  1095d4:	89 e5                	mov    %esp,%ebp
  1095d6:	83 ec 08             	sub    $0x8,%esp
	if (!lapic) 
  1095d9:	a1 04 30 12 00       	mov    0x123004,%eax
  1095de:	85 c0                	test   %eax,%eax
  1095e0:	0f 84 80 01 00 00    	je     109766 <lapic_init+0x193>
		return;

	// Enable local APIC; set spurious interrupt vector.
	lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
  1095e6:	c7 44 24 04 27 01 00 	movl   $0x127,0x4(%esp)
  1095ed:	00 
  1095ee:	c7 04 24 3c 00 00 00 	movl   $0x3c,(%esp)
  1095f5:	e8 b6 ff ff ff       	call   1095b0 <lapicw>

	// The timer repeatedly counts down at bus frequency
	// from lapic[TICR] and then issues an interrupt.  
	lapicw(TDCR, X1);
  1095fa:	c7 44 24 04 0b 00 00 	movl   $0xb,0x4(%esp)
  109601:	00 
  109602:	c7 04 24 f8 00 00 00 	movl   $0xf8,(%esp)
  109609:	e8 a2 ff ff ff       	call   1095b0 <lapicw>
	lapicw(TIMER, PERIODIC | T_LTIMER);
  10960e:	c7 44 24 04 31 00 02 	movl   $0x20031,0x4(%esp)
  109615:	00 
  109616:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
  10961d:	e8 8e ff ff ff       	call   1095b0 <lapicw>

	// If we cared more about precise timekeeping,
	// we would calibrate TICR with another time source such as the PIT.
	lapicw(TICR, 10000000);
  109622:	c7 44 24 04 80 96 98 	movl   $0x989680,0x4(%esp)
  109629:	00 
  10962a:	c7 04 24 e0 00 00 00 	movl   $0xe0,(%esp)
  109631:	e8 7a ff ff ff       	call   1095b0 <lapicw>

	// Disable logical interrupt lines.
	lapicw(LINT0, MASKED);
  109636:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
  10963d:	00 
  10963e:	c7 04 24 d4 00 00 00 	movl   $0xd4,(%esp)
  109645:	e8 66 ff ff ff       	call   1095b0 <lapicw>
	lapicw(LINT1, MASKED);
  10964a:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
  109651:	00 
  109652:	c7 04 24 d8 00 00 00 	movl   $0xd8,(%esp)
  109659:	e8 52 ff ff ff       	call   1095b0 <lapicw>

	// Disable performance counter overflow interrupts
	// on machines that provide that interrupt entry.
	if (((lapic[VER]>>16) & 0xFF) >= 4)
  10965e:	a1 04 30 12 00       	mov    0x123004,%eax
  109663:	83 c0 30             	add    $0x30,%eax
  109666:	8b 00                	mov    (%eax),%eax
  109668:	c1 e8 10             	shr    $0x10,%eax
  10966b:	25 ff 00 00 00       	and    $0xff,%eax
  109670:	83 f8 03             	cmp    $0x3,%eax
  109673:	76 14                	jbe    109689 <lapic_init+0xb6>
		lapicw(PCINT, MASKED);
  109675:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
  10967c:	00 
  10967d:	c7 04 24 d0 00 00 00 	movl   $0xd0,(%esp)
  109684:	e8 27 ff ff ff       	call   1095b0 <lapicw>

	// Map other interrupts to appropriate vectors.
	lapicw(ERROR, T_LERROR);
  109689:	c7 44 24 04 32 00 00 	movl   $0x32,0x4(%esp)
  109690:	00 
  109691:	c7 04 24 dc 00 00 00 	movl   $0xdc,(%esp)
  109698:	e8 13 ff ff ff       	call   1095b0 <lapicw>

	// Set up to lowest-priority, "anycast" interrupts
	lapicw(LDR, 0xff << 24);	// Accept all interrupts
  10969d:	c7 44 24 04 00 00 00 	movl   $0xff000000,0x4(%esp)
  1096a4:	ff 
  1096a5:	c7 04 24 34 00 00 00 	movl   $0x34,(%esp)
  1096ac:	e8 ff fe ff ff       	call   1095b0 <lapicw>
	lapicw(DFR, 0xf << 28);		// Flat model
  1096b1:	c7 44 24 04 00 00 00 	movl   $0xf0000000,0x4(%esp)
  1096b8:	f0 
  1096b9:	c7 04 24 38 00 00 00 	movl   $0x38,(%esp)
  1096c0:	e8 eb fe ff ff       	call   1095b0 <lapicw>
	lapicw(TPR, 0x00);		// Task priority 0, no intrs masked
  1096c5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1096cc:	00 
  1096cd:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  1096d4:	e8 d7 fe ff ff       	call   1095b0 <lapicw>

	// Clear error status register (requires back-to-back writes).
	lapicw(ESR, 0);
  1096d9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1096e0:	00 
  1096e1:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
  1096e8:	e8 c3 fe ff ff       	call   1095b0 <lapicw>
	lapicw(ESR, 0);
  1096ed:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1096f4:	00 
  1096f5:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
  1096fc:	e8 af fe ff ff       	call   1095b0 <lapicw>

	// Ack any outstanding interrupts.
	lapicw(EOI, 0);
  109701:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  109708:	00 
  109709:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
  109710:	e8 9b fe ff ff       	call   1095b0 <lapicw>

	// Send an Init Level De-Assert to synchronise arbitration ID's.
	lapicw(ICRHI, 0);
  109715:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  10971c:	00 
  10971d:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
  109724:	e8 87 fe ff ff       	call   1095b0 <lapicw>
	lapicw(ICRLO, BCAST | INIT | LEVEL);
  109729:	c7 44 24 04 00 85 08 	movl   $0x88500,0x4(%esp)
  109730:	00 
  109731:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
  109738:	e8 73 fe ff ff       	call   1095b0 <lapicw>
	while(lapic[ICRLO] & DELIVS)
  10973d:	a1 04 30 12 00       	mov    0x123004,%eax
  109742:	05 00 03 00 00       	add    $0x300,%eax
  109747:	8b 00                	mov    (%eax),%eax
  109749:	25 00 10 00 00       	and    $0x1000,%eax
  10974e:	85 c0                	test   %eax,%eax
  109750:	75 eb                	jne    10973d <lapic_init+0x16a>
		;

	// Enable interrupts on the APIC (but not on the processor).
	lapicw(TPR, 0);
  109752:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  109759:	00 
  10975a:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  109761:	e8 4a fe ff ff       	call   1095b0 <lapicw>
}
  109766:	c9                   	leave  
  109767:	c3                   	ret    

00109768 <lapic_eoi>:

// Acknowledge interrupt.
void
lapic_eoi(void)
{
  109768:	55                   	push   %ebp
  109769:	89 e5                	mov    %esp,%ebp
  10976b:	83 ec 08             	sub    $0x8,%esp
	if (lapic)
  10976e:	a1 04 30 12 00       	mov    0x123004,%eax
  109773:	85 c0                	test   %eax,%eax
  109775:	74 14                	je     10978b <lapic_eoi+0x23>
		lapicw(EOI, 0);
  109777:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  10977e:	00 
  10977f:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
  109786:	e8 25 fe ff ff       	call   1095b0 <lapicw>
}
  10978b:	c9                   	leave  
  10978c:	c3                   	ret    

0010978d <lapic_errintr>:

void lapic_errintr(void)
{
  10978d:	55                   	push   %ebp
  10978e:	89 e5                	mov    %esp,%ebp
  109790:	53                   	push   %ebx
  109791:	83 ec 14             	sub    $0x14,%esp
	lapic_eoi();	// Acknowledge interrupt
  109794:	e8 cf ff ff ff       	call   109768 <lapic_eoi>
	lapicw(ESR, 0);	// Trigger update of ESR by writing anything
  109799:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1097a0:	00 
  1097a1:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
  1097a8:	e8 03 fe ff ff       	call   1095b0 <lapicw>
	warn("CPU%d LAPIC error: ESR %x", cpu_cur()->id, lapic[ESR]);
  1097ad:	a1 04 30 12 00       	mov    0x123004,%eax
  1097b2:	05 80 02 00 00       	add    $0x280,%eax
  1097b7:	8b 18                	mov    (%eax),%ebx
  1097b9:	e8 34 00 00 00       	call   1097f2 <cpu_cur>
  1097be:	0f b6 80 ac 00 00 00 	movzbl 0xac(%eax),%eax
  1097c5:	0f b6 c0             	movzbl %al,%eax
  1097c8:	89 5c 24 10          	mov    %ebx,0x10(%esp)
  1097cc:	89 44 24 0c          	mov    %eax,0xc(%esp)
  1097d0:	c7 44 24 08 ad c6 10 	movl   $0x10c6ad,0x8(%esp)
  1097d7:	00 
  1097d8:	c7 44 24 04 60 00 00 	movl   $0x60,0x4(%esp)
  1097df:	00 
  1097e0:	c7 04 24 c7 c6 10 00 	movl   $0x10c6c7,(%esp)
  1097e7:	e8 6e 70 ff ff       	call   10085a <debug_warn>
}
  1097ec:	83 c4 14             	add    $0x14,%esp
  1097ef:	5b                   	pop    %ebx
  1097f0:	5d                   	pop    %ebp
  1097f1:	c3                   	ret    

001097f2 <cpu_cur>:

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  1097f2:	55                   	push   %ebp
  1097f3:	89 e5                	mov    %esp,%ebp
  1097f5:	83 ec 28             	sub    $0x28,%esp
static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  1097f8:	89 65 fc             	mov    %esp,0xfffffffc(%ebp)
        return esp;
  1097fb:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  1097fe:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  109801:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  109804:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  109809:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	assert(c->magic == CPU_MAGIC);
  10980c:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  10980f:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  109815:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  10981a:	74 24                	je     109840 <cpu_cur+0x4e>
  10981c:	c7 44 24 0c d3 c6 10 	movl   $0x10c6d3,0xc(%esp)
  109823:	00 
  109824:	c7 44 24 08 e9 c6 10 	movl   $0x10c6e9,0x8(%esp)
  10982b:	00 
  10982c:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  109833:	00 
  109834:	c7 04 24 fe c6 10 00 	movl   $0x10c6fe,(%esp)
  10983b:	e8 5c 6f ff ff       	call   10079c <debug_panic>
	return c;
  109840:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
}
  109843:	c9                   	leave  
  109844:	c3                   	ret    

00109845 <microdelay>:

// Spin for a given number of microseconds.
// On real hardware would want to tune this dynamically.
void
microdelay(int us)
{
  109845:	55                   	push   %ebp
  109846:	89 e5                	mov    %esp,%ebp
}
  109848:	5d                   	pop    %ebp
  109849:	c3                   	ret    

0010984a <lapic_startcpu>:


#define IO_RTC  0x70

// Start additional processor running bootstrap code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapic_startcpu(uint8_t apicid, uint32_t addr)
{
  10984a:	55                   	push   %ebp
  10984b:	89 e5                	mov    %esp,%ebp
  10984d:	83 ec 2c             	sub    $0x2c,%esp
  109850:	8b 45 08             	mov    0x8(%ebp),%eax
  109853:	88 45 dc             	mov    %al,0xffffffdc(%ebp)
  109856:	c7 45 f4 70 00 00 00 	movl   $0x70,0xfffffff4(%ebp)
  10985d:	c6 45 f3 0f          	movb   $0xf,0xfffffff3(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  109861:	0f b6 45 f3          	movzbl 0xfffffff3(%ebp),%eax
  109865:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  109868:	ee                   	out    %al,(%dx)
  109869:	c7 45 fc 71 00 00 00 	movl   $0x71,0xfffffffc(%ebp)
  109870:	c6 45 fb 0a          	movb   $0xa,0xfffffffb(%ebp)
  109874:	0f b6 45 fb          	movzbl 0xfffffffb(%ebp),%eax
  109878:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  10987b:	ee                   	out    %al,(%dx)
	int i;
	uint16_t *wrv;

	// "The BSP must initialize CMOS shutdown code to 0AH
	// and the warm reset vector (DWORD based at 40:67) to point at
	// the AP startup code prior to the [universal startup algorithm]."
	outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
	outb(IO_RTC+1, 0x0A);
	wrv = (uint16_t*)(0x40<<4 | 0x67);  // Warm reset vector
  10987c:	c7 45 ec 67 04 00 00 	movl   $0x467,0xffffffec(%ebp)
	wrv[0] = 0;
  109883:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  109886:	66 c7 00 00 00       	movw   $0x0,(%eax)
	wrv[1] = addr >> 4;
  10988b:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
  10988e:	83 c2 02             	add    $0x2,%edx
  109891:	8b 45 0c             	mov    0xc(%ebp),%eax
  109894:	c1 e8 04             	shr    $0x4,%eax
  109897:	66 89 02             	mov    %ax,(%edx)

	// "Universal startup algorithm."
	// Send INIT (level-triggered) interrupt to reset other CPU.
	lapicw(ICRHI, apicid<<24);
  10989a:	0f b6 45 dc          	movzbl 0xffffffdc(%ebp),%eax
  10989e:	c1 e0 18             	shl    $0x18,%eax
  1098a1:	89 44 24 04          	mov    %eax,0x4(%esp)
  1098a5:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
  1098ac:	e8 ff fc ff ff       	call   1095b0 <lapicw>
	lapicw(ICRLO, INIT | LEVEL | ASSERT);
  1098b1:	c7 44 24 04 00 c5 00 	movl   $0xc500,0x4(%esp)
  1098b8:	00 
  1098b9:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
  1098c0:	e8 eb fc ff ff       	call   1095b0 <lapicw>
	microdelay(200);
  1098c5:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
  1098cc:	e8 74 ff ff ff       	call   109845 <microdelay>
	lapicw(ICRLO, INIT | LEVEL);
  1098d1:	c7 44 24 04 00 85 00 	movl   $0x8500,0x4(%esp)
  1098d8:	00 
  1098d9:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
  1098e0:	e8 cb fc ff ff       	call   1095b0 <lapicw>
	microdelay(100);    // should be 10ms, but too slow in Bochs!
  1098e5:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
  1098ec:	e8 54 ff ff ff       	call   109845 <microdelay>

	// Send startup IPI (twice!) to enter bootstrap code.
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for(i = 0; i < 2; i++){
  1098f1:	c7 45 e8 00 00 00 00 	movl   $0x0,0xffffffe8(%ebp)
  1098f8:	eb 40                	jmp    10993a <lapic_startcpu+0xf0>
		lapicw(ICRHI, apicid<<24);
  1098fa:	0f b6 45 dc          	movzbl 0xffffffdc(%ebp),%eax
  1098fe:	c1 e0 18             	shl    $0x18,%eax
  109901:	89 44 24 04          	mov    %eax,0x4(%esp)
  109905:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
  10990c:	e8 9f fc ff ff       	call   1095b0 <lapicw>
		lapicw(ICRLO, STARTUP | (addr>>12));
  109911:	8b 45 0c             	mov    0xc(%ebp),%eax
  109914:	c1 e8 0c             	shr    $0xc,%eax
  109917:	80 cc 06             	or     $0x6,%ah
  10991a:	89 44 24 04          	mov    %eax,0x4(%esp)
  10991e:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
  109925:	e8 86 fc ff ff       	call   1095b0 <lapicw>
		microdelay(200);
  10992a:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
  109931:	e8 0f ff ff ff       	call   109845 <microdelay>
  109936:	83 45 e8 01          	addl   $0x1,0xffffffe8(%ebp)
  10993a:	83 7d e8 01          	cmpl   $0x1,0xffffffe8(%ebp)
  10993e:	7e ba                	jle    1098fa <lapic_startcpu+0xb0>
	}
}
  109940:	c9                   	leave  
  109941:	c3                   	ret    
  109942:	90                   	nop    
  109943:	90                   	nop    

00109944 <ioapic_read>:
};

static uint32_t
ioapic_read(int reg)
{
  109944:	55                   	push   %ebp
  109945:	89 e5                	mov    %esp,%ebp
	ioapic->reg = reg;
  109947:	8b 15 a4 fd 11 00    	mov    0x11fda4,%edx
  10994d:	8b 45 08             	mov    0x8(%ebp),%eax
  109950:	89 02                	mov    %eax,(%edx)
	return ioapic->data;
  109952:	a1 a4 fd 11 00       	mov    0x11fda4,%eax
  109957:	8b 40 10             	mov    0x10(%eax),%eax
}
  10995a:	5d                   	pop    %ebp
  10995b:	c3                   	ret    

0010995c <ioapic_write>:

static void
ioapic_write(int reg, uint32_t data)
{
  10995c:	55                   	push   %ebp
  10995d:	89 e5                	mov    %esp,%ebp
	ioapic->reg = reg;
  10995f:	8b 15 a4 fd 11 00    	mov    0x11fda4,%edx
  109965:	8b 45 08             	mov    0x8(%ebp),%eax
  109968:	89 02                	mov    %eax,(%edx)
	ioapic->data = data;
  10996a:	8b 15 a4 fd 11 00    	mov    0x11fda4,%edx
  109970:	8b 45 0c             	mov    0xc(%ebp),%eax
  109973:	89 42 10             	mov    %eax,0x10(%edx)
}
  109976:	5d                   	pop    %ebp
  109977:	c3                   	ret    

00109978 <ioapic_init>:

void
ioapic_init(void)
{
  109978:	55                   	push   %ebp
  109979:	89 e5                	mov    %esp,%ebp
  10997b:	83 ec 28             	sub    $0x28,%esp
	int i, id, maxintr;

	if(!ismp)
  10997e:	a1 a8 fd 11 00       	mov    0x11fda8,%eax
  109983:	85 c0                	test   %eax,%eax
  109985:	0f 84 fa 00 00 00    	je     109a85 <ioapic_init+0x10d>
		return;

	if (ioapic == NULL)
  10998b:	a1 a4 fd 11 00       	mov    0x11fda4,%eax
  109990:	85 c0                	test   %eax,%eax
  109992:	75 0a                	jne    10999e <ioapic_init+0x26>
		ioapic = mem_ptr(IOAPIC);	// assume default address
  109994:	c7 05 a4 fd 11 00 00 	movl   $0xfec00000,0x11fda4
  10999b:	00 c0 fe 

	maxintr = (ioapic_read(REG_VER) >> 16) & 0xFF;
  10999e:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  1099a5:	e8 9a ff ff ff       	call   109944 <ioapic_read>
  1099aa:	c1 e8 10             	shr    $0x10,%eax
  1099ad:	25 ff 00 00 00       	and    $0xff,%eax
  1099b2:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	id = ioapic_read(REG_ID) >> 24;
  1099b5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  1099bc:	e8 83 ff ff ff       	call   109944 <ioapic_read>
  1099c1:	c1 e8 18             	shr    $0x18,%eax
  1099c4:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
	if (id == 0) {
  1099c7:	83 7d f8 00          	cmpl   $0x0,0xfffffff8(%ebp)
  1099cb:	75 2a                	jne    1099f7 <ioapic_init+0x7f>
		// I/O APIC ID not initialized yet - have to do it ourselves.
		ioapic_write(REG_ID, ioapicid << 24);
  1099cd:	0f b6 05 a0 fd 11 00 	movzbl 0x11fda0,%eax
  1099d4:	0f b6 c0             	movzbl %al,%eax
  1099d7:	c1 e0 18             	shl    $0x18,%eax
  1099da:	89 44 24 04          	mov    %eax,0x4(%esp)
  1099de:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  1099e5:	e8 72 ff ff ff       	call   10995c <ioapic_write>
		id = ioapicid;
  1099ea:	0f b6 05 a0 fd 11 00 	movzbl 0x11fda0,%eax
  1099f1:	0f b6 c0             	movzbl %al,%eax
  1099f4:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
	}
	if (id != ioapicid)
  1099f7:	0f b6 05 a0 fd 11 00 	movzbl 0x11fda0,%eax
  1099fe:	0f b6 c0             	movzbl %al,%eax
  109a01:	3b 45 f8             	cmp    0xfffffff8(%ebp),%eax
  109a04:	74 31                	je     109a37 <ioapic_init+0xbf>
		warn("ioapicinit: id %d != ioapicid %d", id, ioapicid);
  109a06:	0f b6 05 a0 fd 11 00 	movzbl 0x11fda0,%eax
  109a0d:	0f b6 c0             	movzbl %al,%eax
  109a10:	89 44 24 10          	mov    %eax,0x10(%esp)
  109a14:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  109a17:	89 44 24 0c          	mov    %eax,0xc(%esp)
  109a1b:	c7 44 24 08 0c c7 10 	movl   $0x10c70c,0x8(%esp)
  109a22:	00 
  109a23:	c7 44 24 04 53 00 00 	movl   $0x53,0x4(%esp)
  109a2a:	00 
  109a2b:	c7 04 24 2d c7 10 00 	movl   $0x10c72d,(%esp)
  109a32:	e8 23 6e ff ff       	call   10085a <debug_warn>

	// Mark all interrupts edge-triggered, active high, disabled,
	// and not routed to any CPUs.
	for (i = 0; i <= maxintr; i++){
  109a37:	c7 45 f4 00 00 00 00 	movl   $0x0,0xfffffff4(%ebp)
  109a3e:	eb 3d                	jmp    109a7d <ioapic_init+0x105>
		ioapic_write(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
  109a40:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  109a43:	83 c0 20             	add    $0x20,%eax
  109a46:	0d 00 00 01 00       	or     $0x10000,%eax
  109a4b:	89 c2                	mov    %eax,%edx
  109a4d:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  109a50:	01 c0                	add    %eax,%eax
  109a52:	83 c0 10             	add    $0x10,%eax
  109a55:	89 54 24 04          	mov    %edx,0x4(%esp)
  109a59:	89 04 24             	mov    %eax,(%esp)
  109a5c:	e8 fb fe ff ff       	call   10995c <ioapic_write>
		ioapic_write(REG_TABLE+2*i+1, 0);
  109a61:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  109a64:	01 c0                	add    %eax,%eax
  109a66:	83 c0 11             	add    $0x11,%eax
  109a69:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  109a70:	00 
  109a71:	89 04 24             	mov    %eax,(%esp)
  109a74:	e8 e3 fe ff ff       	call   10995c <ioapic_write>
  109a79:	83 45 f4 01          	addl   $0x1,0xfffffff4(%ebp)
  109a7d:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  109a80:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  109a83:	7e bb                	jle    109a40 <ioapic_init+0xc8>
	}
}
  109a85:	c9                   	leave  
  109a86:	c3                   	ret    

00109a87 <ioapic_enable>:

void
ioapic_enable(int irq)
{
  109a87:	55                   	push   %ebp
  109a88:	89 e5                	mov    %esp,%ebp
  109a8a:	83 ec 08             	sub    $0x8,%esp
	if (!ismp)
  109a8d:	a1 a8 fd 11 00       	mov    0x11fda8,%eax
  109a92:	85 c0                	test   %eax,%eax
  109a94:	74 37                	je     109acd <ioapic_enable+0x46>
		return;

	// Mark interrupt edge-triggered, active high,
	// enabled, and routed to any CPU.
	ioapic_write(REG_TABLE+2*irq,
  109a96:	8b 45 08             	mov    0x8(%ebp),%eax
  109a99:	83 c0 20             	add    $0x20,%eax
  109a9c:	80 cc 09             	or     $0x9,%ah
  109a9f:	89 c2                	mov    %eax,%edx
  109aa1:	8b 45 08             	mov    0x8(%ebp),%eax
  109aa4:	01 c0                	add    %eax,%eax
  109aa6:	83 c0 10             	add    $0x10,%eax
  109aa9:	89 54 24 04          	mov    %edx,0x4(%esp)
  109aad:	89 04 24             	mov    %eax,(%esp)
  109ab0:	e8 a7 fe ff ff       	call   10995c <ioapic_write>
			INT_LOGICAL | INT_LOWEST | (T_IRQ0 + irq));
	ioapic_write(REG_TABLE+2*irq+1, 0xff << 24);
  109ab5:	8b 45 08             	mov    0x8(%ebp),%eax
  109ab8:	01 c0                	add    %eax,%eax
  109aba:	83 c0 11             	add    $0x11,%eax
  109abd:	c7 44 24 04 00 00 00 	movl   $0xff000000,0x4(%esp)
  109ac4:	ff 
  109ac5:	89 04 24             	mov    %eax,(%esp)
  109ac8:	e8 8f fe ff ff       	call   10995c <ioapic_write>
}
  109acd:	c9                   	leave  
  109ace:	c3                   	ret    
  109acf:	90                   	nop    

00109ad0 <getuint>:
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static uintmax_t
getuint(printstate *st, va_list *ap)
{
  109ad0:	55                   	push   %ebp
  109ad1:	89 e5                	mov    %esp,%ebp
  109ad3:	83 ec 08             	sub    $0x8,%esp
	if (st->flags & F_LL)
  109ad6:	8b 45 08             	mov    0x8(%ebp),%eax
  109ad9:	8b 40 18             	mov    0x18(%eax),%eax
  109adc:	83 e0 02             	and    $0x2,%eax
  109adf:	85 c0                	test   %eax,%eax
  109ae1:	74 22                	je     109b05 <getuint+0x35>
		return va_arg(*ap, unsigned long long);
  109ae3:	8b 45 0c             	mov    0xc(%ebp),%eax
  109ae6:	8b 00                	mov    (%eax),%eax
  109ae8:	8d 50 08             	lea    0x8(%eax),%edx
  109aeb:	8b 45 0c             	mov    0xc(%ebp),%eax
  109aee:	89 10                	mov    %edx,(%eax)
  109af0:	8b 45 0c             	mov    0xc(%ebp),%eax
  109af3:	8b 00                	mov    (%eax),%eax
  109af5:	83 e8 08             	sub    $0x8,%eax
  109af8:	8b 10                	mov    (%eax),%edx
  109afa:	8b 48 04             	mov    0x4(%eax),%ecx
  109afd:	89 55 f8             	mov    %edx,0xfffffff8(%ebp)
  109b00:	89 4d fc             	mov    %ecx,0xfffffffc(%ebp)
  109b03:	eb 51                	jmp    109b56 <getuint+0x86>
	else if (st->flags & F_L)
  109b05:	8b 45 08             	mov    0x8(%ebp),%eax
  109b08:	8b 40 18             	mov    0x18(%eax),%eax
  109b0b:	83 e0 01             	and    $0x1,%eax
  109b0e:	84 c0                	test   %al,%al
  109b10:	74 23                	je     109b35 <getuint+0x65>
		return va_arg(*ap, unsigned long);
  109b12:	8b 45 0c             	mov    0xc(%ebp),%eax
  109b15:	8b 00                	mov    (%eax),%eax
  109b17:	8d 50 04             	lea    0x4(%eax),%edx
  109b1a:	8b 45 0c             	mov    0xc(%ebp),%eax
  109b1d:	89 10                	mov    %edx,(%eax)
  109b1f:	8b 45 0c             	mov    0xc(%ebp),%eax
  109b22:	8b 00                	mov    (%eax),%eax
  109b24:	83 e8 04             	sub    $0x4,%eax
  109b27:	8b 00                	mov    (%eax),%eax
  109b29:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  109b2c:	c7 45 fc 00 00 00 00 	movl   $0x0,0xfffffffc(%ebp)
  109b33:	eb 21                	jmp    109b56 <getuint+0x86>
	else
		return va_arg(*ap, unsigned int);
  109b35:	8b 45 0c             	mov    0xc(%ebp),%eax
  109b38:	8b 00                	mov    (%eax),%eax
  109b3a:	8d 50 04             	lea    0x4(%eax),%edx
  109b3d:	8b 45 0c             	mov    0xc(%ebp),%eax
  109b40:	89 10                	mov    %edx,(%eax)
  109b42:	8b 45 0c             	mov    0xc(%ebp),%eax
  109b45:	8b 00                	mov    (%eax),%eax
  109b47:	83 e8 04             	sub    $0x4,%eax
  109b4a:	8b 00                	mov    (%eax),%eax
  109b4c:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  109b4f:	c7 45 fc 00 00 00 00 	movl   $0x0,0xfffffffc(%ebp)
  109b56:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  109b59:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
}
  109b5c:	c9                   	leave  
  109b5d:	c3                   	ret    

00109b5e <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static intmax_t
getint(printstate *st, va_list *ap)
{
  109b5e:	55                   	push   %ebp
  109b5f:	89 e5                	mov    %esp,%ebp
  109b61:	83 ec 08             	sub    $0x8,%esp
	if (st->flags & F_LL)
  109b64:	8b 45 08             	mov    0x8(%ebp),%eax
  109b67:	8b 40 18             	mov    0x18(%eax),%eax
  109b6a:	83 e0 02             	and    $0x2,%eax
  109b6d:	85 c0                	test   %eax,%eax
  109b6f:	74 22                	je     109b93 <getint+0x35>
		return va_arg(*ap, long long);
  109b71:	8b 45 0c             	mov    0xc(%ebp),%eax
  109b74:	8b 00                	mov    (%eax),%eax
  109b76:	8d 50 08             	lea    0x8(%eax),%edx
  109b79:	8b 45 0c             	mov    0xc(%ebp),%eax
  109b7c:	89 10                	mov    %edx,(%eax)
  109b7e:	8b 45 0c             	mov    0xc(%ebp),%eax
  109b81:	8b 00                	mov    (%eax),%eax
  109b83:	83 e8 08             	sub    $0x8,%eax
  109b86:	8b 10                	mov    (%eax),%edx
  109b88:	8b 48 04             	mov    0x4(%eax),%ecx
  109b8b:	89 55 f8             	mov    %edx,0xfffffff8(%ebp)
  109b8e:	89 4d fc             	mov    %ecx,0xfffffffc(%ebp)
  109b91:	eb 53                	jmp    109be6 <getint+0x88>
	else if (st->flags & F_L)
  109b93:	8b 45 08             	mov    0x8(%ebp),%eax
  109b96:	8b 40 18             	mov    0x18(%eax),%eax
  109b99:	83 e0 01             	and    $0x1,%eax
  109b9c:	84 c0                	test   %al,%al
  109b9e:	74 24                	je     109bc4 <getint+0x66>
		return va_arg(*ap, long);
  109ba0:	8b 45 0c             	mov    0xc(%ebp),%eax
  109ba3:	8b 00                	mov    (%eax),%eax
  109ba5:	8d 50 04             	lea    0x4(%eax),%edx
  109ba8:	8b 45 0c             	mov    0xc(%ebp),%eax
  109bab:	89 10                	mov    %edx,(%eax)
  109bad:	8b 45 0c             	mov    0xc(%ebp),%eax
  109bb0:	8b 00                	mov    (%eax),%eax
  109bb2:	83 e8 04             	sub    $0x4,%eax
  109bb5:	8b 00                	mov    (%eax),%eax
  109bb7:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  109bba:	89 c1                	mov    %eax,%ecx
  109bbc:	c1 f9 1f             	sar    $0x1f,%ecx
  109bbf:	89 4d fc             	mov    %ecx,0xfffffffc(%ebp)
  109bc2:	eb 22                	jmp    109be6 <getint+0x88>
	else
		return va_arg(*ap, int);
  109bc4:	8b 45 0c             	mov    0xc(%ebp),%eax
  109bc7:	8b 00                	mov    (%eax),%eax
  109bc9:	8d 50 04             	lea    0x4(%eax),%edx
  109bcc:	8b 45 0c             	mov    0xc(%ebp),%eax
  109bcf:	89 10                	mov    %edx,(%eax)
  109bd1:	8b 45 0c             	mov    0xc(%ebp),%eax
  109bd4:	8b 00                	mov    (%eax),%eax
  109bd6:	83 e8 04             	sub    $0x4,%eax
  109bd9:	8b 00                	mov    (%eax),%eax
  109bdb:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  109bde:	89 c2                	mov    %eax,%edx
  109be0:	c1 fa 1f             	sar    $0x1f,%edx
  109be3:	89 55 fc             	mov    %edx,0xfffffffc(%ebp)
  109be6:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  109be9:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
}
  109bec:	c9                   	leave  
  109bed:	c3                   	ret    

00109bee <putpad>:

// Print padding characters, and an optional sign before a number.
static void
putpad(printstate *st)
{
  109bee:	55                   	push   %ebp
  109bef:	89 e5                	mov    %esp,%ebp
  109bf1:	83 ec 08             	sub    $0x8,%esp
	while (--st->width >= 0)
  109bf4:	eb 1a                	jmp    109c10 <putpad+0x22>
		st->putch(st->padc, st->putdat);
  109bf6:	8b 45 08             	mov    0x8(%ebp),%eax
  109bf9:	8b 08                	mov    (%eax),%ecx
  109bfb:	8b 45 08             	mov    0x8(%ebp),%eax
  109bfe:	8b 50 04             	mov    0x4(%eax),%edx
  109c01:	8b 45 08             	mov    0x8(%ebp),%eax
  109c04:	8b 40 08             	mov    0x8(%eax),%eax
  109c07:	89 54 24 04          	mov    %edx,0x4(%esp)
  109c0b:	89 04 24             	mov    %eax,(%esp)
  109c0e:	ff d1                	call   *%ecx
  109c10:	8b 45 08             	mov    0x8(%ebp),%eax
  109c13:	8b 40 0c             	mov    0xc(%eax),%eax
  109c16:	8d 50 ff             	lea    0xffffffff(%eax),%edx
  109c19:	8b 45 08             	mov    0x8(%ebp),%eax
  109c1c:	89 50 0c             	mov    %edx,0xc(%eax)
  109c1f:	8b 45 08             	mov    0x8(%ebp),%eax
  109c22:	8b 40 0c             	mov    0xc(%eax),%eax
  109c25:	85 c0                	test   %eax,%eax
  109c27:	79 cd                	jns    109bf6 <putpad+0x8>
}
  109c29:	c9                   	leave  
  109c2a:	c3                   	ret    

00109c2b <putstr>:

// Print a string with a specified maximum length (-1=unlimited),
// with any appropriate left or right field padding.
static void
putstr(printstate *st, const char *str, int maxlen)
{
  109c2b:	55                   	push   %ebp
  109c2c:	89 e5                	mov    %esp,%ebp
  109c2e:	53                   	push   %ebx
  109c2f:	83 ec 24             	sub    $0x24,%esp
	const char *lim;		// find where the string actually ends
	if (maxlen < 0)
  109c32:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  109c36:	79 18                	jns    109c50 <putstr+0x25>
		lim = strchr(str, 0);	// find the terminating null
  109c38:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  109c3f:	00 
  109c40:	8b 45 0c             	mov    0xc(%ebp),%eax
  109c43:	89 04 24             	mov    %eax,(%esp)
  109c46:	e8 16 08 00 00       	call   10a461 <strchr>
  109c4b:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
  109c4e:	eb 2c                	jmp    109c7c <putstr+0x51>
	else if ((lim = memchr(str, 0, maxlen)) == NULL)
  109c50:	8b 45 10             	mov    0x10(%ebp),%eax
  109c53:	89 44 24 08          	mov    %eax,0x8(%esp)
  109c57:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  109c5e:	00 
  109c5f:	8b 45 0c             	mov    0xc(%ebp),%eax
  109c62:	89 04 24             	mov    %eax,(%esp)
  109c65:	e8 f4 09 00 00       	call   10a65e <memchr>
  109c6a:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
  109c6d:	83 7d f4 00          	cmpl   $0x0,0xfffffff4(%ebp)
  109c71:	75 09                	jne    109c7c <putstr+0x51>
		lim = str + maxlen;
  109c73:	8b 45 10             	mov    0x10(%ebp),%eax
  109c76:	03 45 0c             	add    0xc(%ebp),%eax
  109c79:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	st->width -= (lim-str);		// deduct string length from field width
  109c7c:	8b 45 08             	mov    0x8(%ebp),%eax
  109c7f:	8b 48 0c             	mov    0xc(%eax),%ecx
  109c82:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  109c85:	8b 45 0c             	mov    0xc(%ebp),%eax
  109c88:	89 d3                	mov    %edx,%ebx
  109c8a:	29 c3                	sub    %eax,%ebx
  109c8c:	89 d8                	mov    %ebx,%eax
  109c8e:	89 ca                	mov    %ecx,%edx
  109c90:	29 c2                	sub    %eax,%edx
  109c92:	8b 45 08             	mov    0x8(%ebp),%eax
  109c95:	89 50 0c             	mov    %edx,0xc(%eax)

	if (!(st->flags & F_RPAD))	// print left-side padding
  109c98:	8b 45 08             	mov    0x8(%ebp),%eax
  109c9b:	8b 40 18             	mov    0x18(%eax),%eax
  109c9e:	83 e0 10             	and    $0x10,%eax
  109ca1:	85 c0                	test   %eax,%eax
  109ca3:	75 32                	jne    109cd7 <putstr+0xac>
		putpad(st);		// (also leaves st->width == 0)
  109ca5:	8b 45 08             	mov    0x8(%ebp),%eax
  109ca8:	89 04 24             	mov    %eax,(%esp)
  109cab:	e8 3e ff ff ff       	call   109bee <putpad>
	while (str < lim) {
  109cb0:	eb 25                	jmp    109cd7 <putstr+0xac>
		char ch = *str++;
  109cb2:	8b 45 0c             	mov    0xc(%ebp),%eax
  109cb5:	0f b6 00             	movzbl (%eax),%eax
  109cb8:	88 45 fb             	mov    %al,0xfffffffb(%ebp)
  109cbb:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
			st->putch(ch, st->putdat);
  109cbf:	8b 45 08             	mov    0x8(%ebp),%eax
  109cc2:	8b 08                	mov    (%eax),%ecx
  109cc4:	8b 45 08             	mov    0x8(%ebp),%eax
  109cc7:	8b 40 04             	mov    0x4(%eax),%eax
  109cca:	0f be 55 fb          	movsbl 0xfffffffb(%ebp),%edx
  109cce:	89 44 24 04          	mov    %eax,0x4(%esp)
  109cd2:	89 14 24             	mov    %edx,(%esp)
  109cd5:	ff d1                	call   *%ecx
  109cd7:	8b 45 0c             	mov    0xc(%ebp),%eax
  109cda:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  109cdd:	72 d3                	jb     109cb2 <putstr+0x87>
	}
	putpad(st);			// print right-side padding
  109cdf:	8b 45 08             	mov    0x8(%ebp),%eax
  109ce2:	89 04 24             	mov    %eax,(%esp)
  109ce5:	e8 04 ff ff ff       	call   109bee <putpad>
}
  109cea:	83 c4 24             	add    $0x24,%esp
  109ced:	5b                   	pop    %ebx
  109cee:	5d                   	pop    %ebp
  109cef:	c3                   	ret    

00109cf0 <genint>:

// Generate a number (base <= 16) in reverse order into a string buffer.
static char *
genint(printstate *st, char *p, uintmax_t num)
{
  109cf0:	55                   	push   %ebp
  109cf1:	89 e5                	mov    %esp,%ebp
  109cf3:	53                   	push   %ebx
  109cf4:	83 ec 24             	sub    $0x24,%esp
  109cf7:	8b 45 10             	mov    0x10(%ebp),%eax
  109cfa:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
  109cfd:	8b 45 14             	mov    0x14(%ebp),%eax
  109d00:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= st->base)
  109d03:	8b 45 08             	mov    0x8(%ebp),%eax
  109d06:	8b 40 1c             	mov    0x1c(%eax),%eax
  109d09:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  109d0c:	89 c2                	mov    %eax,%edx
  109d0e:	c1 fa 1f             	sar    $0x1f,%edx
  109d11:	89 55 ec             	mov    %edx,0xffffffec(%ebp)
  109d14:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  109d17:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  109d1a:	77 54                	ja     109d70 <genint+0x80>
  109d1c:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
  109d1f:	3b 55 f4             	cmp    0xfffffff4(%ebp),%edx
  109d22:	72 08                	jb     109d2c <genint+0x3c>
  109d24:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  109d27:	3b 45 f0             	cmp    0xfffffff0(%ebp),%eax
  109d2a:	77 44                	ja     109d70 <genint+0x80>
		p = genint(st, p, num / st->base);	// output higher digits
  109d2c:	8b 45 08             	mov    0x8(%ebp),%eax
  109d2f:	8b 40 1c             	mov    0x1c(%eax),%eax
  109d32:	89 c2                	mov    %eax,%edx
  109d34:	c1 fa 1f             	sar    $0x1f,%edx
  109d37:	89 44 24 08          	mov    %eax,0x8(%esp)
  109d3b:	89 54 24 0c          	mov    %edx,0xc(%esp)
  109d3f:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  109d42:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  109d45:	89 04 24             	mov    %eax,(%esp)
  109d48:	89 54 24 04          	mov    %edx,0x4(%esp)
  109d4c:	e8 4f 09 00 00       	call   10a6a0 <__udivdi3>
  109d51:	89 44 24 08          	mov    %eax,0x8(%esp)
  109d55:	89 54 24 0c          	mov    %edx,0xc(%esp)
  109d59:	8b 45 0c             	mov    0xc(%ebp),%eax
  109d5c:	89 44 24 04          	mov    %eax,0x4(%esp)
  109d60:	8b 45 08             	mov    0x8(%ebp),%eax
  109d63:	89 04 24             	mov    %eax,(%esp)
  109d66:	e8 85 ff ff ff       	call   109cf0 <genint>
  109d6b:	89 45 0c             	mov    %eax,0xc(%ebp)
  109d6e:	eb 1b                	jmp    109d8b <genint+0x9b>
	else if (st->signc >= 0)
  109d70:	8b 45 08             	mov    0x8(%ebp),%eax
  109d73:	8b 40 14             	mov    0x14(%eax),%eax
  109d76:	85 c0                	test   %eax,%eax
  109d78:	78 11                	js     109d8b <genint+0x9b>
		*p++ = st->signc;			// output leading sign
  109d7a:	8b 45 08             	mov    0x8(%ebp),%eax
  109d7d:	8b 40 14             	mov    0x14(%eax),%eax
  109d80:	89 c2                	mov    %eax,%edx
  109d82:	8b 45 0c             	mov    0xc(%ebp),%eax
  109d85:	88 10                	mov    %dl,(%eax)
  109d87:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
	*p++ = "0123456789abcdef"[num % st->base];	// output this digit
  109d8b:	8b 45 08             	mov    0x8(%ebp),%eax
  109d8e:	8b 40 1c             	mov    0x1c(%eax),%eax
  109d91:	89 c2                	mov    %eax,%edx
  109d93:	c1 fa 1f             	sar    $0x1f,%edx
  109d96:	8b 4d f0             	mov    0xfffffff0(%ebp),%ecx
  109d99:	8b 5d f4             	mov    0xfffffff4(%ebp),%ebx
  109d9c:	89 44 24 08          	mov    %eax,0x8(%esp)
  109da0:	89 54 24 0c          	mov    %edx,0xc(%esp)
  109da4:	89 0c 24             	mov    %ecx,(%esp)
  109da7:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  109dab:	e8 20 0a 00 00       	call   10a7d0 <__umoddi3>
  109db0:	05 3c c7 10 00       	add    $0x10c73c,%eax
  109db5:	0f b6 10             	movzbl (%eax),%edx
  109db8:	8b 45 0c             	mov    0xc(%ebp),%eax
  109dbb:	88 10                	mov    %dl,(%eax)
  109dbd:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
	return p;
  109dc1:	8b 45 0c             	mov    0xc(%ebp),%eax
}
  109dc4:	83 c4 24             	add    $0x24,%esp
  109dc7:	5b                   	pop    %ebx
  109dc8:	5d                   	pop    %ebp
  109dc9:	c3                   	ret    

00109dca <putint>:

// Print an integer with any appropriate field padding.
static void
putint(printstate *st, uintmax_t num, int base)
{
  109dca:	55                   	push   %ebp
  109dcb:	89 e5                	mov    %esp,%ebp
  109dcd:	83 ec 48             	sub    $0x48,%esp
  109dd0:	8b 45 0c             	mov    0xc(%ebp),%eax
  109dd3:	89 45 c8             	mov    %eax,0xffffffc8(%ebp)
  109dd6:	8b 45 10             	mov    0x10(%ebp),%eax
  109dd9:	89 45 cc             	mov    %eax,0xffffffcc(%ebp)
	char buf[30], *p = buf;		// big enough for any 64-bit int in octal
  109ddc:	8d 45 de             	lea    0xffffffde(%ebp),%eax
  109ddf:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	st->base = base;		// select base for genint
  109de2:	8b 55 08             	mov    0x8(%ebp),%edx
  109de5:	8b 45 14             	mov    0x14(%ebp),%eax
  109de8:	89 42 1c             	mov    %eax,0x1c(%edx)
	p = genint(st, p, num);		// output to the string buffer
  109deb:	8b 45 c8             	mov    0xffffffc8(%ebp),%eax
  109dee:	8b 55 cc             	mov    0xffffffcc(%ebp),%edx
  109df1:	89 44 24 08          	mov    %eax,0x8(%esp)
  109df5:	89 54 24 0c          	mov    %edx,0xc(%esp)
  109df9:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  109dfc:	89 44 24 04          	mov    %eax,0x4(%esp)
  109e00:	8b 45 08             	mov    0x8(%ebp),%eax
  109e03:	89 04 24             	mov    %eax,(%esp)
  109e06:	e8 e5 fe ff ff       	call   109cf0 <genint>
  109e0b:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	putstr(st, buf, p-buf);		// print it with left/right padding
  109e0e:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  109e11:	8d 45 de             	lea    0xffffffde(%ebp),%eax
  109e14:	89 d1                	mov    %edx,%ecx
  109e16:	29 c1                	sub    %eax,%ecx
  109e18:	89 c8                	mov    %ecx,%eax
  109e1a:	89 44 24 08          	mov    %eax,0x8(%esp)
  109e1e:	8d 45 de             	lea    0xffffffde(%ebp),%eax
  109e21:	89 44 24 04          	mov    %eax,0x4(%esp)
  109e25:	8b 45 08             	mov    0x8(%ebp),%eax
  109e28:	89 04 24             	mov    %eax,(%esp)
  109e2b:	e8 fb fd ff ff       	call   109c2b <putstr>
}
  109e30:	c9                   	leave  
  109e31:	c3                   	ret    

00109e32 <vprintfmt>:
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
  109e32:	55                   	push   %ebp
  109e33:	89 e5                	mov    %esp,%ebp
  109e35:	57                   	push   %edi
  109e36:	83 ec 54             	sub    $0x54,%esp
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
  109e39:	8d 7d c8             	lea    0xffffffc8(%ebp),%edi
  109e3c:	fc                   	cld    
  109e3d:	ba 00 00 00 00       	mov    $0x0,%edx
  109e42:	b8 08 00 00 00       	mov    $0x8,%eax
  109e47:	89 c1                	mov    %eax,%ecx
  109e49:	89 d0                	mov    %edx,%eax
  109e4b:	f3 ab                	rep stos %eax,%es:(%edi)
  109e4d:	8b 45 08             	mov    0x8(%ebp),%eax
  109e50:	89 45 c8             	mov    %eax,0xffffffc8(%ebp)
  109e53:	8b 45 0c             	mov    0xc(%ebp),%eax
  109e56:	89 45 cc             	mov    %eax,0xffffffcc(%ebp)
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  109e59:	eb 1c                	jmp    109e77 <vprintfmt+0x45>
			if (ch == '\0')
  109e5b:	83 7d c4 00          	cmpl   $0x0,0xffffffc4(%ebp)
  109e5f:	0f 84 73 03 00 00    	je     10a1d8 <vprintfmt+0x3a6>
				return;
			putch(ch, putdat);
  109e65:	8b 45 0c             	mov    0xc(%ebp),%eax
  109e68:	89 44 24 04          	mov    %eax,0x4(%esp)
  109e6c:	8b 55 c4             	mov    0xffffffc4(%ebp),%edx
  109e6f:	89 14 24             	mov    %edx,(%esp)
  109e72:	8b 45 08             	mov    0x8(%ebp),%eax
  109e75:	ff d0                	call   *%eax
  109e77:	8b 45 10             	mov    0x10(%ebp),%eax
  109e7a:	0f b6 00             	movzbl (%eax),%eax
  109e7d:	0f b6 c0             	movzbl %al,%eax
  109e80:	89 45 c4             	mov    %eax,0xffffffc4(%ebp)
  109e83:	83 7d c4 25          	cmpl   $0x25,0xffffffc4(%ebp)
  109e87:	0f 95 c0             	setne  %al
  109e8a:	83 45 10 01          	addl   $0x1,0x10(%ebp)
  109e8e:	84 c0                	test   %al,%al
  109e90:	75 c9                	jne    109e5b <vprintfmt+0x29>
		}

		// Process a %-escape sequence
		st.padc = ' ';
  109e92:	c7 45 d0 20 00 00 00 	movl   $0x20,0xffffffd0(%ebp)
		st.width = -1;
  109e99:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,0xffffffd4(%ebp)
		st.prec = -1;
  109ea0:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,0xffffffd8(%ebp)
		st.signc = -1;
  109ea7:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,0xffffffdc(%ebp)
		st.flags = 0;
  109eae:	c7 45 e0 00 00 00 00 	movl   $0x0,0xffffffe0(%ebp)
		st.base = 10;
  109eb5:	c7 45 e4 0a 00 00 00 	movl   $0xa,0xffffffe4(%ebp)
  109ebc:	eb 00                	jmp    109ebe <vprintfmt+0x8c>
		uintmax_t num;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  109ebe:	8b 45 10             	mov    0x10(%ebp),%eax
  109ec1:	0f b6 00             	movzbl (%eax),%eax
  109ec4:	0f b6 c0             	movzbl %al,%eax
  109ec7:	89 45 c4             	mov    %eax,0xffffffc4(%ebp)
  109eca:	8b 45 c4             	mov    0xffffffc4(%ebp),%eax
  109ecd:	83 45 10 01          	addl   $0x1,0x10(%ebp)
  109ed1:	83 e8 20             	sub    $0x20,%eax
  109ed4:	89 45 b8             	mov    %eax,0xffffffb8(%ebp)
  109ed7:	83 7d b8 58          	cmpl   $0x58,0xffffffb8(%ebp)
  109edb:	0f 87 c8 02 00 00    	ja     10a1a9 <vprintfmt+0x377>
  109ee1:	8b 55 b8             	mov    0xffffffb8(%ebp),%edx
  109ee4:	8b 04 95 54 c7 10 00 	mov    0x10c754(,%edx,4),%eax
  109eeb:	ff e0                	jmp    *%eax

		// modifier flags
		case '-': // pad on the right instead of the left
			st.flags |= F_RPAD;
  109eed:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  109ef0:	83 c8 10             	or     $0x10,%eax
  109ef3:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)
			goto reswitch;
  109ef6:	eb c6                	jmp    109ebe <vprintfmt+0x8c>

		case '+': // prefix positive numeric values with a '+' sign
			st.signc = '+';
  109ef8:	c7 45 dc 2b 00 00 00 	movl   $0x2b,0xffffffdc(%ebp)
			goto reswitch;
  109eff:	eb bd                	jmp    109ebe <vprintfmt+0x8c>

		case ' ': // prefix signless numeric values with a space
			if (st.signc < 0)	// (but only if no '+' is specified)
  109f01:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  109f04:	85 c0                	test   %eax,%eax
  109f06:	79 b6                	jns    109ebe <vprintfmt+0x8c>
				st.signc = ' ';
  109f08:	c7 45 dc 20 00 00 00 	movl   $0x20,0xffffffdc(%ebp)
			goto reswitch;
  109f0f:	eb ad                	jmp    109ebe <vprintfmt+0x8c>

		// width or precision field
		case '0':
			if (!(st.flags & F_DOT))
  109f11:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  109f14:	83 e0 08             	and    $0x8,%eax
  109f17:	85 c0                	test   %eax,%eax
  109f19:	75 07                	jne    109f22 <vprintfmt+0xf0>
				st.padc = '0'; // pad with 0's instead of spaces
  109f1b:	c7 45 d0 30 00 00 00 	movl   $0x30,0xffffffd0(%ebp)
		case '1': case '2': case '3': case '4':
		case '5': case '6': case '7': case '8': case '9':
			for (st.prec = 0; ; ++fmt) {
  109f22:	c7 45 d8 00 00 00 00 	movl   $0x0,0xffffffd8(%ebp)
				st.prec = st.prec * 10 + ch - '0';
  109f29:	8b 55 d8             	mov    0xffffffd8(%ebp),%edx
  109f2c:	89 d0                	mov    %edx,%eax
  109f2e:	c1 e0 02             	shl    $0x2,%eax
  109f31:	01 d0                	add    %edx,%eax
  109f33:	01 c0                	add    %eax,%eax
  109f35:	03 45 c4             	add    0xffffffc4(%ebp),%eax
  109f38:	83 e8 30             	sub    $0x30,%eax
  109f3b:	89 45 d8             	mov    %eax,0xffffffd8(%ebp)
				ch = *fmt;
  109f3e:	8b 45 10             	mov    0x10(%ebp),%eax
  109f41:	0f b6 00             	movzbl (%eax),%eax
  109f44:	0f be c0             	movsbl %al,%eax
  109f47:	89 45 c4             	mov    %eax,0xffffffc4(%ebp)
				if (ch < '0' || ch > '9')
  109f4a:	83 7d c4 2f          	cmpl   $0x2f,0xffffffc4(%ebp)
  109f4e:	7e 20                	jle    109f70 <vprintfmt+0x13e>
  109f50:	83 7d c4 39          	cmpl   $0x39,0xffffffc4(%ebp)
  109f54:	7f 1a                	jg     109f70 <vprintfmt+0x13e>
  109f56:	83 45 10 01          	addl   $0x1,0x10(%ebp)
					break;
			}
  109f5a:	eb cd                	jmp    109f29 <vprintfmt+0xf7>
			goto gotprec;

		case '*':
			st.prec = va_arg(ap, int);
  109f5c:	8b 45 14             	mov    0x14(%ebp),%eax
  109f5f:	83 c0 04             	add    $0x4,%eax
  109f62:	89 45 14             	mov    %eax,0x14(%ebp)
  109f65:	8b 45 14             	mov    0x14(%ebp),%eax
  109f68:	83 e8 04             	sub    $0x4,%eax
  109f6b:	8b 00                	mov    (%eax),%eax
  109f6d:	89 45 d8             	mov    %eax,0xffffffd8(%ebp)
		gotprec:
			if (!(st.flags & F_DOT)) {	// haven't seen a '.' yet?
  109f70:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  109f73:	83 e0 08             	and    $0x8,%eax
  109f76:	85 c0                	test   %eax,%eax
  109f78:	0f 85 40 ff ff ff    	jne    109ebe <vprintfmt+0x8c>
				st.width = st.prec;	// then it's a field width
  109f7e:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  109f81:	89 45 d4             	mov    %eax,0xffffffd4(%ebp)
				st.prec = -1;
  109f84:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,0xffffffd8(%ebp)
			}
			goto reswitch;
  109f8b:	e9 2e ff ff ff       	jmp    109ebe <vprintfmt+0x8c>

		case '.':
			st.flags |= F_DOT;
  109f90:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  109f93:	83 c8 08             	or     $0x8,%eax
  109f96:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)
			goto reswitch;
  109f99:	e9 20 ff ff ff       	jmp    109ebe <vprintfmt+0x8c>

		case '#':
			st.flags |= F_ALT;
  109f9e:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  109fa1:	83 c8 04             	or     $0x4,%eax
  109fa4:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)
			goto reswitch;
  109fa7:	e9 12 ff ff ff       	jmp    109ebe <vprintfmt+0x8c>

		// long flag (doubled for long long)
		case 'l':
			st.flags |= (st.flags & F_L) ? F_LL : F_L;
  109fac:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  109faf:	89 45 bc             	mov    %eax,0xffffffbc(%ebp)
  109fb2:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  109fb5:	83 e0 01             	and    $0x1,%eax
  109fb8:	84 c0                	test   %al,%al
  109fba:	74 09                	je     109fc5 <vprintfmt+0x193>
  109fbc:	c7 45 c0 02 00 00 00 	movl   $0x2,0xffffffc0(%ebp)
  109fc3:	eb 07                	jmp    109fcc <vprintfmt+0x19a>
  109fc5:	c7 45 c0 01 00 00 00 	movl   $0x1,0xffffffc0(%ebp)
  109fcc:	8b 45 bc             	mov    0xffffffbc(%ebp),%eax
  109fcf:	0b 45 c0             	or     0xffffffc0(%ebp),%eax
  109fd2:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)
			goto reswitch;
  109fd5:	e9 e4 fe ff ff       	jmp    109ebe <vprintfmt+0x8c>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  109fda:	8b 45 14             	mov    0x14(%ebp),%eax
  109fdd:	83 c0 04             	add    $0x4,%eax
  109fe0:	89 45 14             	mov    %eax,0x14(%ebp)
  109fe3:	8b 45 14             	mov    0x14(%ebp),%eax
  109fe6:	83 e8 04             	sub    $0x4,%eax
  109fe9:	8b 10                	mov    (%eax),%edx
  109feb:	8b 45 0c             	mov    0xc(%ebp),%eax
  109fee:	89 44 24 04          	mov    %eax,0x4(%esp)
  109ff2:	89 14 24             	mov    %edx,(%esp)
  109ff5:	8b 45 08             	mov    0x8(%ebp),%eax
  109ff8:	ff d0                	call   *%eax
			break;
  109ffa:	e9 78 fe ff ff       	jmp    109e77 <vprintfmt+0x45>

		// string
		case 's': {
			const char *s;
			if ((s = va_arg(ap, char *)) == NULL)
  109fff:	8b 45 14             	mov    0x14(%ebp),%eax
  10a002:	83 c0 04             	add    $0x4,%eax
  10a005:	89 45 14             	mov    %eax,0x14(%ebp)
  10a008:	8b 45 14             	mov    0x14(%ebp),%eax
  10a00b:	83 e8 04             	sub    $0x4,%eax
  10a00e:	8b 00                	mov    (%eax),%eax
  10a010:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
  10a013:	83 7d f4 00          	cmpl   $0x0,0xfffffff4(%ebp)
  10a017:	75 07                	jne    10a020 <vprintfmt+0x1ee>
				s = "(null)";
  10a019:	c7 45 f4 4d c7 10 00 	movl   $0x10c74d,0xfffffff4(%ebp)
			putstr(&st, s, st.prec);
  10a020:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  10a023:	89 44 24 08          	mov    %eax,0x8(%esp)
  10a027:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  10a02a:	89 44 24 04          	mov    %eax,0x4(%esp)
  10a02e:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
  10a031:	89 04 24             	mov    %eax,(%esp)
  10a034:	e8 f2 fb ff ff       	call   109c2b <putstr>
			break;
  10a039:	e9 39 fe ff ff       	jmp    109e77 <vprintfmt+0x45>
		    }

		// (signed) decimal
		case 'd':
			num = getint(&st, &ap);
  10a03e:	8d 45 14             	lea    0x14(%ebp),%eax
  10a041:	89 44 24 04          	mov    %eax,0x4(%esp)
  10a045:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
  10a048:	89 04 24             	mov    %eax,(%esp)
  10a04b:	e8 0e fb ff ff       	call   109b5e <getint>
  10a050:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  10a053:	89 55 ec             	mov    %edx,0xffffffec(%ebp)
			if ((intmax_t) num < 0) {
  10a056:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  10a059:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
  10a05c:	85 d2                	test   %edx,%edx
  10a05e:	79 1a                	jns    10a07a <vprintfmt+0x248>
				num = -(intmax_t) num;
  10a060:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  10a063:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
  10a066:	f7 d8                	neg    %eax
  10a068:	83 d2 00             	adc    $0x0,%edx
  10a06b:	f7 da                	neg    %edx
  10a06d:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  10a070:	89 55 ec             	mov    %edx,0xffffffec(%ebp)
				st.signc = '-';
  10a073:	c7 45 dc 2d 00 00 00 	movl   $0x2d,0xffffffdc(%ebp)
			}
			putint(&st, num, 10);
  10a07a:	c7 44 24 0c 0a 00 00 	movl   $0xa,0xc(%esp)
  10a081:	00 
  10a082:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  10a085:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
  10a088:	89 44 24 04          	mov    %eax,0x4(%esp)
  10a08c:	89 54 24 08          	mov    %edx,0x8(%esp)
  10a090:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
  10a093:	89 04 24             	mov    %eax,(%esp)
  10a096:	e8 2f fd ff ff       	call   109dca <putint>
			break;
  10a09b:	e9 d7 fd ff ff       	jmp    109e77 <vprintfmt+0x45>

		// unsigned decimal
		case 'u':
			putint(&st, getuint(&st, &ap), 10);
  10a0a0:	8d 45 14             	lea    0x14(%ebp),%eax
  10a0a3:	89 44 24 04          	mov    %eax,0x4(%esp)
  10a0a7:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
  10a0aa:	89 04 24             	mov    %eax,(%esp)
  10a0ad:	e8 1e fa ff ff       	call   109ad0 <getuint>
  10a0b2:	c7 44 24 0c 0a 00 00 	movl   $0xa,0xc(%esp)
  10a0b9:	00 
  10a0ba:	89 44 24 04          	mov    %eax,0x4(%esp)
  10a0be:	89 54 24 08          	mov    %edx,0x8(%esp)
  10a0c2:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
  10a0c5:	89 04 24             	mov    %eax,(%esp)
  10a0c8:	e8 fd fc ff ff       	call   109dca <putint>
			break;
  10a0cd:	e9 a5 fd ff ff       	jmp    109e77 <vprintfmt+0x45>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putint(&st, getuint(&st, &ap), 8);
  10a0d2:	8d 45 14             	lea    0x14(%ebp),%eax
  10a0d5:	89 44 24 04          	mov    %eax,0x4(%esp)
  10a0d9:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
  10a0dc:	89 04 24             	mov    %eax,(%esp)
  10a0df:	e8 ec f9 ff ff       	call   109ad0 <getuint>
  10a0e4:	c7 44 24 0c 08 00 00 	movl   $0x8,0xc(%esp)
  10a0eb:	00 
  10a0ec:	89 44 24 04          	mov    %eax,0x4(%esp)
  10a0f0:	89 54 24 08          	mov    %edx,0x8(%esp)
  10a0f4:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
  10a0f7:	89 04 24             	mov    %eax,(%esp)
  10a0fa:	e8 cb fc ff ff       	call   109dca <putint>
			break;
  10a0ff:	e9 73 fd ff ff       	jmp    109e77 <vprintfmt+0x45>

		// (unsigned) hexadecimal
		case 'x':
			putint(&st, getuint(&st, &ap), 16);
  10a104:	8d 45 14             	lea    0x14(%ebp),%eax
  10a107:	89 44 24 04          	mov    %eax,0x4(%esp)
  10a10b:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
  10a10e:	89 04 24             	mov    %eax,(%esp)
  10a111:	e8 ba f9 ff ff       	call   109ad0 <getuint>
  10a116:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
  10a11d:	00 
  10a11e:	89 44 24 04          	mov    %eax,0x4(%esp)
  10a122:	89 54 24 08          	mov    %edx,0x8(%esp)
  10a126:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
  10a129:	89 04 24             	mov    %eax,(%esp)
  10a12c:	e8 99 fc ff ff       	call   109dca <putint>
			break;
  10a131:	e9 41 fd ff ff       	jmp    109e77 <vprintfmt+0x45>

		// pointer
		case 'p':
			putch('0', putdat);
  10a136:	8b 45 0c             	mov    0xc(%ebp),%eax
  10a139:	89 44 24 04          	mov    %eax,0x4(%esp)
  10a13d:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  10a144:	8b 45 08             	mov    0x8(%ebp),%eax
  10a147:	ff d0                	call   *%eax
			putch('x', putdat);
  10a149:	8b 45 0c             	mov    0xc(%ebp),%eax
  10a14c:	89 44 24 04          	mov    %eax,0x4(%esp)
  10a150:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  10a157:	8b 45 08             	mov    0x8(%ebp),%eax
  10a15a:	ff d0                	call   *%eax
			putint(&st, (uintptr_t) va_arg(ap, void *), 16);
  10a15c:	8b 45 14             	mov    0x14(%ebp),%eax
  10a15f:	83 c0 04             	add    $0x4,%eax
  10a162:	89 45 14             	mov    %eax,0x14(%ebp)
  10a165:	8b 45 14             	mov    0x14(%ebp),%eax
  10a168:	83 e8 04             	sub    $0x4,%eax
  10a16b:	8b 00                	mov    (%eax),%eax
  10a16d:	ba 00 00 00 00       	mov    $0x0,%edx
  10a172:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
  10a179:	00 
  10a17a:	89 44 24 04          	mov    %eax,0x4(%esp)
  10a17e:	89 54 24 08          	mov    %edx,0x8(%esp)
  10a182:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
  10a185:	89 04 24             	mov    %eax,(%esp)
  10a188:	e8 3d fc ff ff       	call   109dca <putint>
			break;
  10a18d:	e9 e5 fc ff ff       	jmp    109e77 <vprintfmt+0x45>
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
  10a192:	8b 45 0c             	mov    0xc(%ebp),%eax
  10a195:	89 44 24 04          	mov    %eax,0x4(%esp)
  10a199:	8b 55 c4             	mov    0xffffffc4(%ebp),%edx
  10a19c:	89 14 24             	mov    %edx,(%esp)
  10a19f:	8b 45 08             	mov    0x8(%ebp),%eax
  10a1a2:	ff d0                	call   *%eax
			break;
  10a1a4:	e9 ce fc ff ff       	jmp    109e77 <vprintfmt+0x45>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  10a1a9:	8b 45 0c             	mov    0xc(%ebp),%eax
  10a1ac:	89 44 24 04          	mov    %eax,0x4(%esp)
  10a1b0:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  10a1b7:	8b 45 08             	mov    0x8(%ebp),%eax
  10a1ba:	ff d0                	call   *%eax
			for (fmt--; fmt[-1] != '%'; fmt--)
  10a1bc:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  10a1c0:	eb 04                	jmp    10a1c6 <vprintfmt+0x394>
  10a1c2:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  10a1c6:	8b 45 10             	mov    0x10(%ebp),%eax
  10a1c9:	83 e8 01             	sub    $0x1,%eax
  10a1cc:	0f b6 00             	movzbl (%eax),%eax
  10a1cf:	3c 25                	cmp    $0x25,%al
  10a1d1:	75 ef                	jne    10a1c2 <vprintfmt+0x390>
				/* do nothing */;
			break;
		}
	}
  10a1d3:	e9 9f fc ff ff       	jmp    109e77 <vprintfmt+0x45>
}
  10a1d8:	83 c4 54             	add    $0x54,%esp
  10a1db:	5f                   	pop    %edi
  10a1dc:	5d                   	pop    %ebp
  10a1dd:	c3                   	ret    
  10a1de:	90                   	nop    
  10a1df:	90                   	nop    

0010a1e0 <putch>:


static void
putch(int ch, struct printbuf *b)
{
  10a1e0:	55                   	push   %ebp
  10a1e1:	89 e5                	mov    %esp,%ebp
  10a1e3:	83 ec 08             	sub    $0x8,%esp
	b->buf[b->idx++] = ch;
  10a1e6:	8b 45 0c             	mov    0xc(%ebp),%eax
  10a1e9:	8b 08                	mov    (%eax),%ecx
  10a1eb:	8b 45 08             	mov    0x8(%ebp),%eax
  10a1ee:	89 c2                	mov    %eax,%edx
  10a1f0:	8b 45 0c             	mov    0xc(%ebp),%eax
  10a1f3:	88 54 08 08          	mov    %dl,0x8(%eax,%ecx,1)
  10a1f7:	8d 51 01             	lea    0x1(%ecx),%edx
  10a1fa:	8b 45 0c             	mov    0xc(%ebp),%eax
  10a1fd:	89 10                	mov    %edx,(%eax)
	if (b->idx == CPUTS_MAX-1) {
  10a1ff:	8b 45 0c             	mov    0xc(%ebp),%eax
  10a202:	8b 00                	mov    (%eax),%eax
  10a204:	3d ff 00 00 00       	cmp    $0xff,%eax
  10a209:	75 24                	jne    10a22f <putch+0x4f>
		b->buf[b->idx] = 0;
  10a20b:	8b 45 0c             	mov    0xc(%ebp),%eax
  10a20e:	8b 10                	mov    (%eax),%edx
  10a210:	8b 45 0c             	mov    0xc(%ebp),%eax
  10a213:	c6 44 10 08 00       	movb   $0x0,0x8(%eax,%edx,1)
		cputs(b->buf);
  10a218:	8b 45 0c             	mov    0xc(%ebp),%eax
  10a21b:	83 c0 08             	add    $0x8,%eax
  10a21e:	89 04 24             	mov    %eax,(%esp)
  10a221:	e8 ef 64 ff ff       	call   100715 <cputs>
		b->idx = 0;
  10a226:	8b 45 0c             	mov    0xc(%ebp),%eax
  10a229:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	}
	b->cnt++;
  10a22f:	8b 45 0c             	mov    0xc(%ebp),%eax
  10a232:	8b 40 04             	mov    0x4(%eax),%eax
  10a235:	8d 50 01             	lea    0x1(%eax),%edx
  10a238:	8b 45 0c             	mov    0xc(%ebp),%eax
  10a23b:	89 50 04             	mov    %edx,0x4(%eax)
}
  10a23e:	c9                   	leave  
  10a23f:	c3                   	ret    

0010a240 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  10a240:	55                   	push   %ebp
  10a241:	89 e5                	mov    %esp,%ebp
  10a243:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  10a249:	c7 85 f8 fe ff ff 00 	movl   $0x0,0xfffffef8(%ebp)
  10a250:	00 00 00 
	b.cnt = 0;
  10a253:	c7 85 fc fe ff ff 00 	movl   $0x0,0xfffffefc(%ebp)
  10a25a:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  10a25d:	ba e0 a1 10 00       	mov    $0x10a1e0,%edx
  10a262:	8b 45 0c             	mov    0xc(%ebp),%eax
  10a265:	89 44 24 0c          	mov    %eax,0xc(%esp)
  10a269:	8b 45 08             	mov    0x8(%ebp),%eax
  10a26c:	89 44 24 08          	mov    %eax,0x8(%esp)
  10a270:	8d 85 f8 fe ff ff    	lea    0xfffffef8(%ebp),%eax
  10a276:	89 44 24 04          	mov    %eax,0x4(%esp)
  10a27a:	89 14 24             	mov    %edx,(%esp)
  10a27d:	e8 b0 fb ff ff       	call   109e32 <vprintfmt>

	b.buf[b.idx] = 0;
  10a282:	8b 85 f8 fe ff ff    	mov    0xfffffef8(%ebp),%eax
  10a288:	c6 84 05 00 ff ff ff 	movb   $0x0,0xffffff00(%ebp,%eax,1)
  10a28f:	00 
	cputs(b.buf);
  10a290:	8d 85 f8 fe ff ff    	lea    0xfffffef8(%ebp),%eax
  10a296:	83 c0 08             	add    $0x8,%eax
  10a299:	89 04 24             	mov    %eax,(%esp)
  10a29c:	e8 74 64 ff ff       	call   100715 <cputs>

	return b.cnt;
  10a2a1:	8b 85 fc fe ff ff    	mov    0xfffffefc(%ebp),%eax
}
  10a2a7:	c9                   	leave  
  10a2a8:	c3                   	ret    

0010a2a9 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  10a2a9:	55                   	push   %ebp
  10a2aa:	89 e5                	mov    %esp,%ebp
  10a2ac:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  10a2af:	8d 45 08             	lea    0x8(%ebp),%eax
  10a2b2:	83 c0 04             	add    $0x4,%eax
  10a2b5:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
	cnt = vcprintf(fmt, ap);
  10a2b8:	8b 55 08             	mov    0x8(%ebp),%edx
  10a2bb:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10a2be:	89 44 24 04          	mov    %eax,0x4(%esp)
  10a2c2:	89 14 24             	mov    %edx,(%esp)
  10a2c5:	e8 76 ff ff ff       	call   10a240 <vcprintf>
  10a2ca:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	va_end(ap);

	return cnt;
  10a2cd:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
}
  10a2d0:	c9                   	leave  
  10a2d1:	c3                   	ret    
  10a2d2:	90                   	nop    
  10a2d3:	90                   	nop    

0010a2d4 <strlen>:
#define ASM 1

int
strlen(const char *s)
{
  10a2d4:	55                   	push   %ebp
  10a2d5:	89 e5                	mov    %esp,%ebp
  10a2d7:	83 ec 10             	sub    $0x10,%esp
	int n;

	for (n = 0; *s != '\0'; s++)
  10a2da:	c7 45 fc 00 00 00 00 	movl   $0x0,0xfffffffc(%ebp)
  10a2e1:	eb 08                	jmp    10a2eb <strlen+0x17>
		n++;
  10a2e3:	83 45 fc 01          	addl   $0x1,0xfffffffc(%ebp)
  10a2e7:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  10a2eb:	8b 45 08             	mov    0x8(%ebp),%eax
  10a2ee:	0f b6 00             	movzbl (%eax),%eax
  10a2f1:	84 c0                	test   %al,%al
  10a2f3:	75 ee                	jne    10a2e3 <strlen+0xf>
	return n;
  10a2f5:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
}
  10a2f8:	c9                   	leave  
  10a2f9:	c3                   	ret    

0010a2fa <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  10a2fa:	55                   	push   %ebp
  10a2fb:	89 e5                	mov    %esp,%ebp
  10a2fd:	83 ec 10             	sub    $0x10,%esp
	char *ret;

	ret = dst;
  10a300:	8b 45 08             	mov    0x8(%ebp),%eax
  10a303:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	while ((*dst++ = *src++) != '\0')
  10a306:	8b 45 0c             	mov    0xc(%ebp),%eax
  10a309:	0f b6 10             	movzbl (%eax),%edx
  10a30c:	8b 45 08             	mov    0x8(%ebp),%eax
  10a30f:	88 10                	mov    %dl,(%eax)
  10a311:	8b 45 08             	mov    0x8(%ebp),%eax
  10a314:	0f b6 00             	movzbl (%eax),%eax
  10a317:	84 c0                	test   %al,%al
  10a319:	0f 95 c0             	setne  %al
  10a31c:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  10a320:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
  10a324:	84 c0                	test   %al,%al
  10a326:	75 de                	jne    10a306 <strcpy+0xc>
		/* do nothing */;
	return ret;
  10a328:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
}
  10a32b:	c9                   	leave  
  10a32c:	c3                   	ret    

0010a32d <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size)
{
  10a32d:	55                   	push   %ebp
  10a32e:	89 e5                	mov    %esp,%ebp
  10a330:	83 ec 10             	sub    $0x10,%esp
	size_t i;
	char *ret;

	ret = dst;
  10a333:	8b 45 08             	mov    0x8(%ebp),%eax
  10a336:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	for (i = 0; i < size; i++) {
  10a339:	c7 45 f8 00 00 00 00 	movl   $0x0,0xfffffff8(%ebp)
  10a340:	eb 21                	jmp    10a363 <strncpy+0x36>
		*dst++ = *src;
  10a342:	8b 45 0c             	mov    0xc(%ebp),%eax
  10a345:	0f b6 10             	movzbl (%eax),%edx
  10a348:	8b 45 08             	mov    0x8(%ebp),%eax
  10a34b:	88 10                	mov    %dl,(%eax)
  10a34d:	83 45 08 01          	addl   $0x1,0x8(%ebp)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
  10a351:	8b 45 0c             	mov    0xc(%ebp),%eax
  10a354:	0f b6 00             	movzbl (%eax),%eax
  10a357:	84 c0                	test   %al,%al
  10a359:	74 04                	je     10a35f <strncpy+0x32>
			src++;
  10a35b:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
  10a35f:	83 45 f8 01          	addl   $0x1,0xfffffff8(%ebp)
  10a363:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10a366:	3b 45 10             	cmp    0x10(%ebp),%eax
  10a369:	72 d7                	jb     10a342 <strncpy+0x15>
	}
	return ret;
  10a36b:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
}
  10a36e:	c9                   	leave  
  10a36f:	c3                   	ret    

0010a370 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  10a370:	55                   	push   %ebp
  10a371:	89 e5                	mov    %esp,%ebp
  10a373:	83 ec 10             	sub    $0x10,%esp
	char *dst_in;

	dst_in = dst;
  10a376:	8b 45 08             	mov    0x8(%ebp),%eax
  10a379:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	if (size > 0) {
  10a37c:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  10a380:	74 2f                	je     10a3b1 <strlcpy+0x41>
		while (--size > 0 && *src != '\0')
  10a382:	eb 13                	jmp    10a397 <strlcpy+0x27>
			*dst++ = *src++;
  10a384:	8b 45 0c             	mov    0xc(%ebp),%eax
  10a387:	0f b6 10             	movzbl (%eax),%edx
  10a38a:	8b 45 08             	mov    0x8(%ebp),%eax
  10a38d:	88 10                	mov    %dl,(%eax)
  10a38f:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  10a393:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
  10a397:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  10a39b:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  10a39f:	74 0a                	je     10a3ab <strlcpy+0x3b>
  10a3a1:	8b 45 0c             	mov    0xc(%ebp),%eax
  10a3a4:	0f b6 00             	movzbl (%eax),%eax
  10a3a7:	84 c0                	test   %al,%al
  10a3a9:	75 d9                	jne    10a384 <strlcpy+0x14>
		*dst = '\0';
  10a3ab:	8b 45 08             	mov    0x8(%ebp),%eax
  10a3ae:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  10a3b1:	8b 55 08             	mov    0x8(%ebp),%edx
  10a3b4:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  10a3b7:	89 d1                	mov    %edx,%ecx
  10a3b9:	29 c1                	sub    %eax,%ecx
  10a3bb:	89 c8                	mov    %ecx,%eax
}
  10a3bd:	c9                   	leave  
  10a3be:	c3                   	ret    

0010a3bf <strcmp>:

int
strcmp(const char *p, const char *q)
{
  10a3bf:	55                   	push   %ebp
  10a3c0:	89 e5                	mov    %esp,%ebp
	while (*p && *p == *q)
  10a3c2:	eb 08                	jmp    10a3cc <strcmp+0xd>
		p++, q++;
  10a3c4:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  10a3c8:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
  10a3cc:	8b 45 08             	mov    0x8(%ebp),%eax
  10a3cf:	0f b6 00             	movzbl (%eax),%eax
  10a3d2:	84 c0                	test   %al,%al
  10a3d4:	74 10                	je     10a3e6 <strcmp+0x27>
  10a3d6:	8b 45 08             	mov    0x8(%ebp),%eax
  10a3d9:	0f b6 10             	movzbl (%eax),%edx
  10a3dc:	8b 45 0c             	mov    0xc(%ebp),%eax
  10a3df:	0f b6 00             	movzbl (%eax),%eax
  10a3e2:	38 c2                	cmp    %al,%dl
  10a3e4:	74 de                	je     10a3c4 <strcmp+0x5>
	return (int) ((unsigned char) *p - (unsigned char) *q);
  10a3e6:	8b 45 08             	mov    0x8(%ebp),%eax
  10a3e9:	0f b6 00             	movzbl (%eax),%eax
  10a3ec:	0f b6 d0             	movzbl %al,%edx
  10a3ef:	8b 45 0c             	mov    0xc(%ebp),%eax
  10a3f2:	0f b6 00             	movzbl (%eax),%eax
  10a3f5:	0f b6 c0             	movzbl %al,%eax
  10a3f8:	89 d1                	mov    %edx,%ecx
  10a3fa:	29 c1                	sub    %eax,%ecx
  10a3fc:	89 c8                	mov    %ecx,%eax
}
  10a3fe:	5d                   	pop    %ebp
  10a3ff:	c3                   	ret    

0010a400 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  10a400:	55                   	push   %ebp
  10a401:	89 e5                	mov    %esp,%ebp
  10a403:	83 ec 04             	sub    $0x4,%esp
	while (n > 0 && *p && *p == *q)
  10a406:	eb 0c                	jmp    10a414 <strncmp+0x14>
		n--, p++, q++;
  10a408:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  10a40c:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  10a410:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
  10a414:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  10a418:	74 1a                	je     10a434 <strncmp+0x34>
  10a41a:	8b 45 08             	mov    0x8(%ebp),%eax
  10a41d:	0f b6 00             	movzbl (%eax),%eax
  10a420:	84 c0                	test   %al,%al
  10a422:	74 10                	je     10a434 <strncmp+0x34>
  10a424:	8b 45 08             	mov    0x8(%ebp),%eax
  10a427:	0f b6 10             	movzbl (%eax),%edx
  10a42a:	8b 45 0c             	mov    0xc(%ebp),%eax
  10a42d:	0f b6 00             	movzbl (%eax),%eax
  10a430:	38 c2                	cmp    %al,%dl
  10a432:	74 d4                	je     10a408 <strncmp+0x8>
	if (n == 0)
  10a434:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  10a438:	75 09                	jne    10a443 <strncmp+0x43>
		return 0;
  10a43a:	c7 45 fc 00 00 00 00 	movl   $0x0,0xfffffffc(%ebp)
  10a441:	eb 19                	jmp    10a45c <strncmp+0x5c>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  10a443:	8b 45 08             	mov    0x8(%ebp),%eax
  10a446:	0f b6 00             	movzbl (%eax),%eax
  10a449:	0f b6 d0             	movzbl %al,%edx
  10a44c:	8b 45 0c             	mov    0xc(%ebp),%eax
  10a44f:	0f b6 00             	movzbl (%eax),%eax
  10a452:	0f b6 c0             	movzbl %al,%eax
  10a455:	89 d1                	mov    %edx,%ecx
  10a457:	29 c1                	sub    %eax,%ecx
  10a459:	89 4d fc             	mov    %ecx,0xfffffffc(%ebp)
  10a45c:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
}
  10a45f:	c9                   	leave  
  10a460:	c3                   	ret    

0010a461 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  10a461:	55                   	push   %ebp
  10a462:	89 e5                	mov    %esp,%ebp
  10a464:	83 ec 08             	sub    $0x8,%esp
  10a467:	8b 45 0c             	mov    0xc(%ebp),%eax
  10a46a:	88 45 fc             	mov    %al,0xfffffffc(%ebp)
	while (*s != c)
  10a46d:	eb 1c                	jmp    10a48b <strchr+0x2a>
		if (*s++ == 0)
  10a46f:	8b 45 08             	mov    0x8(%ebp),%eax
  10a472:	0f b6 00             	movzbl (%eax),%eax
  10a475:	84 c0                	test   %al,%al
  10a477:	0f 94 c0             	sete   %al
  10a47a:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  10a47e:	84 c0                	test   %al,%al
  10a480:	74 09                	je     10a48b <strchr+0x2a>
			return NULL;
  10a482:	c7 45 f8 00 00 00 00 	movl   $0x0,0xfffffff8(%ebp)
  10a489:	eb 11                	jmp    10a49c <strchr+0x3b>
  10a48b:	8b 45 08             	mov    0x8(%ebp),%eax
  10a48e:	0f b6 00             	movzbl (%eax),%eax
  10a491:	3a 45 fc             	cmp    0xfffffffc(%ebp),%al
  10a494:	75 d9                	jne    10a46f <strchr+0xe>
	return (char *) s;
  10a496:	8b 45 08             	mov    0x8(%ebp),%eax
  10a499:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  10a49c:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
}
  10a49f:	c9                   	leave  
  10a4a0:	c3                   	ret    

0010a4a1 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  10a4a1:	55                   	push   %ebp
  10a4a2:	89 e5                	mov    %esp,%ebp
  10a4a4:	57                   	push   %edi
  10a4a5:	83 ec 14             	sub    $0x14,%esp
	char *p;

	if (n == 0)
  10a4a8:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  10a4ac:	75 08                	jne    10a4b6 <memset+0x15>
		return v;
  10a4ae:	8b 45 08             	mov    0x8(%ebp),%eax
  10a4b1:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  10a4b4:	eb 5b                	jmp    10a511 <memset+0x70>
	if ((int)v%4 == 0 && n%4 == 0) {
  10a4b6:	8b 45 08             	mov    0x8(%ebp),%eax
  10a4b9:	83 e0 03             	and    $0x3,%eax
  10a4bc:	85 c0                	test   %eax,%eax
  10a4be:	75 3f                	jne    10a4ff <memset+0x5e>
  10a4c0:	8b 45 10             	mov    0x10(%ebp),%eax
  10a4c3:	83 e0 03             	and    $0x3,%eax
  10a4c6:	85 c0                	test   %eax,%eax
  10a4c8:	75 35                	jne    10a4ff <memset+0x5e>
		c &= 0xFF;
  10a4ca:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
		c = (c<<24)|(c<<16)|(c<<8)|c;
  10a4d1:	8b 45 0c             	mov    0xc(%ebp),%eax
  10a4d4:	89 c2                	mov    %eax,%edx
  10a4d6:	c1 e2 18             	shl    $0x18,%edx
  10a4d9:	8b 45 0c             	mov    0xc(%ebp),%eax
  10a4dc:	c1 e0 10             	shl    $0x10,%eax
  10a4df:	09 c2                	or     %eax,%edx
  10a4e1:	8b 45 0c             	mov    0xc(%ebp),%eax
  10a4e4:	c1 e0 08             	shl    $0x8,%eax
  10a4e7:	09 d0                	or     %edx,%eax
  10a4e9:	09 45 0c             	or     %eax,0xc(%ebp)
		asm volatile("cld; rep stosl\n"
  10a4ec:	8b 45 10             	mov    0x10(%ebp),%eax
  10a4ef:	89 c1                	mov    %eax,%ecx
  10a4f1:	c1 e9 02             	shr    $0x2,%ecx
  10a4f4:	8b 7d 08             	mov    0x8(%ebp),%edi
  10a4f7:	8b 45 0c             	mov    0xc(%ebp),%eax
  10a4fa:	fc                   	cld    
  10a4fb:	f3 ab                	rep stos %eax,%es:(%edi)
  10a4fd:	eb 0c                	jmp    10a50b <memset+0x6a>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  10a4ff:	8b 7d 08             	mov    0x8(%ebp),%edi
  10a502:	8b 45 0c             	mov    0xc(%ebp),%eax
  10a505:	8b 4d 10             	mov    0x10(%ebp),%ecx
  10a508:	fc                   	cld    
  10a509:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
  10a50b:	8b 45 08             	mov    0x8(%ebp),%eax
  10a50e:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  10a511:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
}
  10a514:	83 c4 14             	add    $0x14,%esp
  10a517:	5f                   	pop    %edi
  10a518:	5d                   	pop    %ebp
  10a519:	c3                   	ret    

0010a51a <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  10a51a:	55                   	push   %ebp
  10a51b:	89 e5                	mov    %esp,%ebp
  10a51d:	57                   	push   %edi
  10a51e:	56                   	push   %esi
  10a51f:	83 ec 10             	sub    $0x10,%esp
	const char *s;
	char *d;
	
	s = src;
  10a522:	8b 45 0c             	mov    0xc(%ebp),%eax
  10a525:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
	d = dst;
  10a528:	8b 45 08             	mov    0x8(%ebp),%eax
  10a52b:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	if (s < d && s + n > d) {
  10a52e:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  10a531:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  10a534:	73 63                	jae    10a599 <memmove+0x7f>
  10a536:	8b 45 10             	mov    0x10(%ebp),%eax
  10a539:	03 45 f0             	add    0xfffffff0(%ebp),%eax
  10a53c:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  10a53f:	76 58                	jbe    10a599 <memmove+0x7f>
		s += n;
  10a541:	8b 45 10             	mov    0x10(%ebp),%eax
  10a544:	01 45 f0             	add    %eax,0xfffffff0(%ebp)
		d += n;
  10a547:	8b 45 10             	mov    0x10(%ebp),%eax
  10a54a:	01 45 f4             	add    %eax,0xfffffff4(%ebp)
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  10a54d:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  10a550:	83 e0 03             	and    $0x3,%eax
  10a553:	85 c0                	test   %eax,%eax
  10a555:	75 2d                	jne    10a584 <memmove+0x6a>
  10a557:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  10a55a:	83 e0 03             	and    $0x3,%eax
  10a55d:	85 c0                	test   %eax,%eax
  10a55f:	75 23                	jne    10a584 <memmove+0x6a>
  10a561:	8b 45 10             	mov    0x10(%ebp),%eax
  10a564:	83 e0 03             	and    $0x3,%eax
  10a567:	85 c0                	test   %eax,%eax
  10a569:	75 19                	jne    10a584 <memmove+0x6a>
			asm volatile("std; rep movsl\n"
  10a56b:	8b 7d f4             	mov    0xfffffff4(%ebp),%edi
  10a56e:	83 ef 04             	sub    $0x4,%edi
  10a571:	8b 75 f0             	mov    0xfffffff0(%ebp),%esi
  10a574:	83 ee 04             	sub    $0x4,%esi
  10a577:	8b 45 10             	mov    0x10(%ebp),%eax
  10a57a:	89 c1                	mov    %eax,%ecx
  10a57c:	c1 e9 02             	shr    $0x2,%ecx
  10a57f:	fd                   	std    
  10a580:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  10a582:	eb 12                	jmp    10a596 <memmove+0x7c>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  10a584:	8b 7d f4             	mov    0xfffffff4(%ebp),%edi
  10a587:	83 ef 01             	sub    $0x1,%edi
  10a58a:	8b 75 f0             	mov    0xfffffff0(%ebp),%esi
  10a58d:	83 ee 01             	sub    $0x1,%esi
  10a590:	8b 4d 10             	mov    0x10(%ebp),%ecx
  10a593:	fd                   	std    
  10a594:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  10a596:	fc                   	cld    
  10a597:	eb 3d                	jmp    10a5d6 <memmove+0xbc>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  10a599:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  10a59c:	83 e0 03             	and    $0x3,%eax
  10a59f:	85 c0                	test   %eax,%eax
  10a5a1:	75 27                	jne    10a5ca <memmove+0xb0>
  10a5a3:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  10a5a6:	83 e0 03             	and    $0x3,%eax
  10a5a9:	85 c0                	test   %eax,%eax
  10a5ab:	75 1d                	jne    10a5ca <memmove+0xb0>
  10a5ad:	8b 45 10             	mov    0x10(%ebp),%eax
  10a5b0:	83 e0 03             	and    $0x3,%eax
  10a5b3:	85 c0                	test   %eax,%eax
  10a5b5:	75 13                	jne    10a5ca <memmove+0xb0>
			asm volatile("cld; rep movsl\n"
  10a5b7:	8b 45 10             	mov    0x10(%ebp),%eax
  10a5ba:	89 c1                	mov    %eax,%ecx
  10a5bc:	c1 e9 02             	shr    $0x2,%ecx
  10a5bf:	8b 7d f4             	mov    0xfffffff4(%ebp),%edi
  10a5c2:	8b 75 f0             	mov    0xfffffff0(%ebp),%esi
  10a5c5:	fc                   	cld    
  10a5c6:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  10a5c8:	eb 0c                	jmp    10a5d6 <memmove+0xbc>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  10a5ca:	8b 7d f4             	mov    0xfffffff4(%ebp),%edi
  10a5cd:	8b 75 f0             	mov    0xfffffff0(%ebp),%esi
  10a5d0:	8b 4d 10             	mov    0x10(%ebp),%ecx
  10a5d3:	fc                   	cld    
  10a5d4:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
  10a5d6:	8b 45 08             	mov    0x8(%ebp),%eax
}
  10a5d9:	83 c4 10             	add    $0x10,%esp
  10a5dc:	5e                   	pop    %esi
  10a5dd:	5f                   	pop    %edi
  10a5de:	5d                   	pop    %ebp
  10a5df:	c3                   	ret    

0010a5e0 <memcpy>:

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
  10a5e0:	55                   	push   %ebp
  10a5e1:	89 e5                	mov    %esp,%ebp
  10a5e3:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
  10a5e6:	8b 45 10             	mov    0x10(%ebp),%eax
  10a5e9:	89 44 24 08          	mov    %eax,0x8(%esp)
  10a5ed:	8b 45 0c             	mov    0xc(%ebp),%eax
  10a5f0:	89 44 24 04          	mov    %eax,0x4(%esp)
  10a5f4:	8b 45 08             	mov    0x8(%ebp),%eax
  10a5f7:	89 04 24             	mov    %eax,(%esp)
  10a5fa:	e8 1b ff ff ff       	call   10a51a <memmove>
}
  10a5ff:	c9                   	leave  
  10a600:	c3                   	ret    

0010a601 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  10a601:	55                   	push   %ebp
  10a602:	89 e5                	mov    %esp,%ebp
  10a604:	83 ec 14             	sub    $0x14,%esp
	const uint8_t *s1 = (const uint8_t *) v1;
  10a607:	8b 45 08             	mov    0x8(%ebp),%eax
  10a60a:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
	const uint8_t *s2 = (const uint8_t *) v2;
  10a60d:	8b 45 0c             	mov    0xc(%ebp),%eax
  10a610:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)

	while (n-- > 0) {
  10a613:	eb 33                	jmp    10a648 <memcmp+0x47>
		if (*s1 != *s2)
  10a615:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10a618:	0f b6 10             	movzbl (%eax),%edx
  10a61b:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  10a61e:	0f b6 00             	movzbl (%eax),%eax
  10a621:	38 c2                	cmp    %al,%dl
  10a623:	74 1b                	je     10a640 <memcmp+0x3f>
			return (int) *s1 - (int) *s2;
  10a625:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10a628:	0f b6 00             	movzbl (%eax),%eax
  10a62b:	0f b6 d0             	movzbl %al,%edx
  10a62e:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  10a631:	0f b6 00             	movzbl (%eax),%eax
  10a634:	0f b6 c0             	movzbl %al,%eax
  10a637:	89 d1                	mov    %edx,%ecx
  10a639:	29 c1                	sub    %eax,%ecx
  10a63b:	89 4d ec             	mov    %ecx,0xffffffec(%ebp)
  10a63e:	eb 19                	jmp    10a659 <memcmp+0x58>
		s1++, s2++;
  10a640:	83 45 f8 01          	addl   $0x1,0xfffffff8(%ebp)
  10a644:	83 45 fc 01          	addl   $0x1,0xfffffffc(%ebp)
  10a648:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  10a64c:	83 7d 10 ff          	cmpl   $0xffffffff,0x10(%ebp)
  10a650:	75 c3                	jne    10a615 <memcmp+0x14>
	}

	return 0;
  10a652:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  10a659:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
}
  10a65c:	c9                   	leave  
  10a65d:	c3                   	ret    

0010a65e <memchr>:

void *
memchr(const void *s, int c, size_t n)
{
  10a65e:	55                   	push   %ebp
  10a65f:	89 e5                	mov    %esp,%ebp
  10a661:	83 ec 14             	sub    $0x14,%esp
	const void *ends = (const char *) s + n;
  10a664:	8b 45 08             	mov    0x8(%ebp),%eax
  10a667:	8b 55 10             	mov    0x10(%ebp),%edx
  10a66a:	01 d0                	add    %edx,%eax
  10a66c:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	for (; s < ends; s++)
  10a66f:	eb 19                	jmp    10a68a <memchr+0x2c>
		if (*(const unsigned char *) s == (unsigned char) c)
  10a671:	8b 45 08             	mov    0x8(%ebp),%eax
  10a674:	0f b6 10             	movzbl (%eax),%edx
  10a677:	8b 45 0c             	mov    0xc(%ebp),%eax
  10a67a:	38 c2                	cmp    %al,%dl
  10a67c:	75 08                	jne    10a686 <memchr+0x28>
			return (void *) s;
  10a67e:	8b 45 08             	mov    0x8(%ebp),%eax
  10a681:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  10a684:	eb 13                	jmp    10a699 <memchr+0x3b>
  10a686:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  10a68a:	8b 45 08             	mov    0x8(%ebp),%eax
  10a68d:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  10a690:	72 df                	jb     10a671 <memchr+0x13>
	return NULL;
  10a692:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  10a699:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
}
  10a69c:	c9                   	leave  
  10a69d:	c3                   	ret    
  10a69e:	90                   	nop    
  10a69f:	90                   	nop    

0010a6a0 <__udivdi3>:
  10a6a0:	55                   	push   %ebp
  10a6a1:	89 e5                	mov    %esp,%ebp
  10a6a3:	57                   	push   %edi
  10a6a4:	56                   	push   %esi
  10a6a5:	83 ec 1c             	sub    $0x1c,%esp
  10a6a8:	8b 45 10             	mov    0x10(%ebp),%eax
  10a6ab:	8b 55 14             	mov    0x14(%ebp),%edx
  10a6ae:	8b 7d 0c             	mov    0xc(%ebp),%edi
  10a6b1:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
  10a6b4:	89 c1                	mov    %eax,%ecx
  10a6b6:	8b 45 08             	mov    0x8(%ebp),%eax
  10a6b9:	85 d2                	test   %edx,%edx
  10a6bb:	89 d6                	mov    %edx,%esi
  10a6bd:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  10a6c0:	75 1e                	jne    10a6e0 <__udivdi3+0x40>
  10a6c2:	39 f9                	cmp    %edi,%ecx
  10a6c4:	0f 86 8d 00 00 00    	jbe    10a757 <__udivdi3+0xb7>
  10a6ca:	89 fa                	mov    %edi,%edx
  10a6cc:	f7 f1                	div    %ecx
  10a6ce:	89 c1                	mov    %eax,%ecx
  10a6d0:	89 c8                	mov    %ecx,%eax
  10a6d2:	89 f2                	mov    %esi,%edx
  10a6d4:	83 c4 1c             	add    $0x1c,%esp
  10a6d7:	5e                   	pop    %esi
  10a6d8:	5f                   	pop    %edi
  10a6d9:	5d                   	pop    %ebp
  10a6da:	c3                   	ret    
  10a6db:	90                   	nop    
  10a6dc:	8d 74 26 00          	lea    0x0(%esi),%esi
  10a6e0:	39 fa                	cmp    %edi,%edx
  10a6e2:	0f 87 98 00 00 00    	ja     10a780 <__udivdi3+0xe0>
  10a6e8:	0f bd c2             	bsr    %edx,%eax
  10a6eb:	83 f0 1f             	xor    $0x1f,%eax
  10a6ee:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
  10a6f1:	74 7f                	je     10a772 <__udivdi3+0xd2>
  10a6f3:	b8 20 00 00 00       	mov    $0x20,%eax
  10a6f8:	8b 55 f0             	mov    0xfffffff0(%ebp),%edx
  10a6fb:	2b 45 e4             	sub    0xffffffe4(%ebp),%eax
  10a6fe:	89 c1                	mov    %eax,%ecx
  10a700:	d3 ea                	shr    %cl,%edx
  10a702:	0f b6 4d e4          	movzbl 0xffffffe4(%ebp),%ecx
  10a706:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  10a709:	89 f0                	mov    %esi,%eax
  10a70b:	d3 e0                	shl    %cl,%eax
  10a70d:	09 c2                	or     %eax,%edx
  10a70f:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  10a712:	89 55 e0             	mov    %edx,0xffffffe0(%ebp)
  10a715:	89 fa                	mov    %edi,%edx
  10a717:	d3 e0                	shl    %cl,%eax
  10a719:	0f b6 4d ec          	movzbl 0xffffffec(%ebp),%ecx
  10a71d:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
  10a720:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  10a723:	d3 e8                	shr    %cl,%eax
  10a725:	0f b6 4d e4          	movzbl 0xffffffe4(%ebp),%ecx
  10a729:	d3 e2                	shl    %cl,%edx
  10a72b:	0f b6 4d ec          	movzbl 0xffffffec(%ebp),%ecx
  10a72f:	09 d0                	or     %edx,%eax
  10a731:	d3 ef                	shr    %cl,%edi
  10a733:	89 fa                	mov    %edi,%edx
  10a735:	f7 75 e0             	divl   0xffffffe0(%ebp)
  10a738:	89 d1                	mov    %edx,%ecx
  10a73a:	89 c7                	mov    %eax,%edi
  10a73c:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  10a73f:	f7 e7                	mul    %edi
  10a741:	39 d1                	cmp    %edx,%ecx
  10a743:	89 c6                	mov    %eax,%esi
  10a745:	89 55 dc             	mov    %edx,0xffffffdc(%ebp)
  10a748:	72 6f                	jb     10a7b9 <__udivdi3+0x119>
  10a74a:	39 ca                	cmp    %ecx,%edx
  10a74c:	74 5e                	je     10a7ac <__udivdi3+0x10c>
  10a74e:	89 f9                	mov    %edi,%ecx
  10a750:	31 f6                	xor    %esi,%esi
  10a752:	e9 79 ff ff ff       	jmp    10a6d0 <__udivdi3+0x30>
  10a757:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  10a75a:	85 c0                	test   %eax,%eax
  10a75c:	74 32                	je     10a790 <__udivdi3+0xf0>
  10a75e:	89 f2                	mov    %esi,%edx
  10a760:	89 f8                	mov    %edi,%eax
  10a762:	f7 f1                	div    %ecx
  10a764:	89 c6                	mov    %eax,%esi
  10a766:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  10a769:	f7 f1                	div    %ecx
  10a76b:	89 c1                	mov    %eax,%ecx
  10a76d:	e9 5e ff ff ff       	jmp    10a6d0 <__udivdi3+0x30>
  10a772:	39 d7                	cmp    %edx,%edi
  10a774:	77 2a                	ja     10a7a0 <__udivdi3+0x100>
  10a776:	8b 55 f0             	mov    0xfffffff0(%ebp),%edx
  10a779:	39 55 e8             	cmp    %edx,0xffffffe8(%ebp)
  10a77c:	73 22                	jae    10a7a0 <__udivdi3+0x100>
  10a77e:	66 90                	xchg   %ax,%ax
  10a780:	31 c9                	xor    %ecx,%ecx
  10a782:	31 f6                	xor    %esi,%esi
  10a784:	e9 47 ff ff ff       	jmp    10a6d0 <__udivdi3+0x30>
  10a789:	8d b4 26 00 00 00 00 	lea    0x0(%esi),%esi
  10a790:	b8 01 00 00 00       	mov    $0x1,%eax
  10a795:	31 d2                	xor    %edx,%edx
  10a797:	f7 75 f0             	divl   0xfffffff0(%ebp)
  10a79a:	89 c1                	mov    %eax,%ecx
  10a79c:	eb c0                	jmp    10a75e <__udivdi3+0xbe>
  10a79e:	66 90                	xchg   %ax,%ax
  10a7a0:	b9 01 00 00 00       	mov    $0x1,%ecx
  10a7a5:	31 f6                	xor    %esi,%esi
  10a7a7:	e9 24 ff ff ff       	jmp    10a6d0 <__udivdi3+0x30>
  10a7ac:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  10a7af:	0f b6 4d e4          	movzbl 0xffffffe4(%ebp),%ecx
  10a7b3:	d3 e0                	shl    %cl,%eax
  10a7b5:	39 c6                	cmp    %eax,%esi
  10a7b7:	76 95                	jbe    10a74e <__udivdi3+0xae>
  10a7b9:	8d 4f ff             	lea    0xffffffff(%edi),%ecx
  10a7bc:	31 f6                	xor    %esi,%esi
  10a7be:	e9 0d ff ff ff       	jmp    10a6d0 <__udivdi3+0x30>
  10a7c3:	90                   	nop    
  10a7c4:	90                   	nop    
  10a7c5:	90                   	nop    
  10a7c6:	90                   	nop    
  10a7c7:	90                   	nop    
  10a7c8:	90                   	nop    
  10a7c9:	90                   	nop    
  10a7ca:	90                   	nop    
  10a7cb:	90                   	nop    
  10a7cc:	90                   	nop    
  10a7cd:	90                   	nop    
  10a7ce:	90                   	nop    
  10a7cf:	90                   	nop    

0010a7d0 <__umoddi3>:
  10a7d0:	55                   	push   %ebp
  10a7d1:	89 e5                	mov    %esp,%ebp
  10a7d3:	57                   	push   %edi
  10a7d4:	56                   	push   %esi
  10a7d5:	83 ec 30             	sub    $0x30,%esp
  10a7d8:	8b 55 14             	mov    0x14(%ebp),%edx
  10a7db:	8b 45 10             	mov    0x10(%ebp),%eax
  10a7de:	8b 75 08             	mov    0x8(%ebp),%esi
  10a7e1:	8b 7d 0c             	mov    0xc(%ebp),%edi
  10a7e4:	85 d2                	test   %edx,%edx
  10a7e6:	c7 45 d0 00 00 00 00 	movl   $0x0,0xffffffd0(%ebp)
  10a7ed:	89 c1                	mov    %eax,%ecx
  10a7ef:	c7 45 d4 00 00 00 00 	movl   $0x0,0xffffffd4(%ebp)
  10a7f6:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  10a7f9:	89 55 e8             	mov    %edx,0xffffffe8(%ebp)
  10a7fc:	89 75 f0             	mov    %esi,0xfffffff0(%ebp)
  10a7ff:	89 7d e0             	mov    %edi,0xffffffe0(%ebp)
  10a802:	75 1c                	jne    10a820 <__umoddi3+0x50>
  10a804:	39 f8                	cmp    %edi,%eax
  10a806:	89 fa                	mov    %edi,%edx
  10a808:	0f 86 d4 00 00 00    	jbe    10a8e2 <__umoddi3+0x112>
  10a80e:	89 f0                	mov    %esi,%eax
  10a810:	f7 f1                	div    %ecx
  10a812:	89 55 d0             	mov    %edx,0xffffffd0(%ebp)
  10a815:	c7 45 d4 00 00 00 00 	movl   $0x0,0xffffffd4(%ebp)
  10a81c:	eb 12                	jmp    10a830 <__umoddi3+0x60>
  10a81e:	66 90                	xchg   %ax,%ax
  10a820:	8b 4d e0             	mov    0xffffffe0(%ebp),%ecx
  10a823:	39 4d e8             	cmp    %ecx,0xffffffe8(%ebp)
  10a826:	76 18                	jbe    10a840 <__umoddi3+0x70>
  10a828:	89 75 d0             	mov    %esi,0xffffffd0(%ebp)
  10a82b:	89 7d d4             	mov    %edi,0xffffffd4(%ebp)
  10a82e:	66 90                	xchg   %ax,%ax
  10a830:	8b 45 d0             	mov    0xffffffd0(%ebp),%eax
  10a833:	8b 55 d4             	mov    0xffffffd4(%ebp),%edx
  10a836:	83 c4 30             	add    $0x30,%esp
  10a839:	5e                   	pop    %esi
  10a83a:	5f                   	pop    %edi
  10a83b:	5d                   	pop    %ebp
  10a83c:	c3                   	ret    
  10a83d:	8d 76 00             	lea    0x0(%esi),%esi
  10a840:	0f bd 45 e8          	bsr    0xffffffe8(%ebp),%eax
  10a844:	83 f0 1f             	xor    $0x1f,%eax
  10a847:	89 45 dc             	mov    %eax,0xffffffdc(%ebp)
  10a84a:	0f 84 c0 00 00 00    	je     10a910 <__umoddi3+0x140>
  10a850:	b8 20 00 00 00       	mov    $0x20,%eax
  10a855:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
  10a858:	2b 45 dc             	sub    0xffffffdc(%ebp),%eax
  10a85b:	8b 7d ec             	mov    0xffffffec(%ebp),%edi
  10a85e:	8b 75 f0             	mov    0xfffffff0(%ebp),%esi
  10a861:	89 c1                	mov    %eax,%ecx
  10a863:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
  10a866:	d3 ea                	shr    %cl,%edx
  10a868:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  10a86b:	0f b6 4d dc          	movzbl 0xffffffdc(%ebp),%ecx
  10a86f:	d3 e0                	shl    %cl,%eax
  10a871:	09 c2                	or     %eax,%edx
  10a873:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  10a876:	d3 e7                	shl    %cl,%edi
  10a878:	0f b6 4d e4          	movzbl 0xffffffe4(%ebp),%ecx
  10a87c:	89 55 f4             	mov    %edx,0xfffffff4(%ebp)
  10a87f:	8b 55 e0             	mov    0xffffffe0(%ebp),%edx
  10a882:	d3 e8                	shr    %cl,%eax
  10a884:	0f b6 4d dc          	movzbl 0xffffffdc(%ebp),%ecx
  10a888:	d3 e2                	shl    %cl,%edx
  10a88a:	09 d0                	or     %edx,%eax
  10a88c:	8b 55 e0             	mov    0xffffffe0(%ebp),%edx
  10a88f:	d3 e6                	shl    %cl,%esi
  10a891:	0f b6 4d e4          	movzbl 0xffffffe4(%ebp),%ecx
  10a895:	d3 ea                	shr    %cl,%edx
  10a897:	f7 75 f4             	divl   0xfffffff4(%ebp)
  10a89a:	89 55 cc             	mov    %edx,0xffffffcc(%ebp)
  10a89d:	f7 e7                	mul    %edi
  10a89f:	39 55 cc             	cmp    %edx,0xffffffcc(%ebp)
  10a8a2:	0f 82 a5 00 00 00    	jb     10a94d <__umoddi3+0x17d>
  10a8a8:	3b 55 cc             	cmp    0xffffffcc(%ebp),%edx
  10a8ab:	0f 84 94 00 00 00    	je     10a945 <__umoddi3+0x175>
  10a8b1:	8b 4d cc             	mov    0xffffffcc(%ebp),%ecx
  10a8b4:	29 c6                	sub    %eax,%esi
  10a8b6:	19 d1                	sbb    %edx,%ecx
  10a8b8:	89 4d cc             	mov    %ecx,0xffffffcc(%ebp)
  10a8bb:	0f b6 4d dc          	movzbl 0xffffffdc(%ebp),%ecx
  10a8bf:	89 f2                	mov    %esi,%edx
  10a8c1:	8b 45 cc             	mov    0xffffffcc(%ebp),%eax
  10a8c4:	d3 ea                	shr    %cl,%edx
  10a8c6:	0f b6 4d e4          	movzbl 0xffffffe4(%ebp),%ecx
  10a8ca:	d3 e0                	shl    %cl,%eax
  10a8cc:	0f b6 4d dc          	movzbl 0xffffffdc(%ebp),%ecx
  10a8d0:	09 c2                	or     %eax,%edx
  10a8d2:	8b 45 cc             	mov    0xffffffcc(%ebp),%eax
  10a8d5:	89 55 d0             	mov    %edx,0xffffffd0(%ebp)
  10a8d8:	d3 e8                	shr    %cl,%eax
  10a8da:	89 45 d4             	mov    %eax,0xffffffd4(%ebp)
  10a8dd:	e9 4e ff ff ff       	jmp    10a830 <__umoddi3+0x60>
  10a8e2:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  10a8e5:	85 c0                	test   %eax,%eax
  10a8e7:	74 17                	je     10a900 <__umoddi3+0x130>
  10a8e9:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  10a8ec:	8b 55 e8             	mov    0xffffffe8(%ebp),%edx
  10a8ef:	f7 f1                	div    %ecx
  10a8f1:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  10a8f4:	f7 f1                	div    %ecx
  10a8f6:	e9 17 ff ff ff       	jmp    10a812 <__umoddi3+0x42>
  10a8fb:	90                   	nop    
  10a8fc:	8d 74 26 00          	lea    0x0(%esi),%esi
  10a900:	b8 01 00 00 00       	mov    $0x1,%eax
  10a905:	31 d2                	xor    %edx,%edx
  10a907:	f7 75 ec             	divl   0xffffffec(%ebp)
  10a90a:	89 c1                	mov    %eax,%ecx
  10a90c:	eb db                	jmp    10a8e9 <__umoddi3+0x119>
  10a90e:	66 90                	xchg   %ax,%ax
  10a910:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  10a913:	39 45 e0             	cmp    %eax,0xffffffe0(%ebp)
  10a916:	77 19                	ja     10a931 <__umoddi3+0x161>
  10a918:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
  10a91b:	39 55 f0             	cmp    %edx,0xfffffff0(%ebp)
  10a91e:	73 11                	jae    10a931 <__umoddi3+0x161>
  10a920:	8b 55 f0             	mov    0xfffffff0(%ebp),%edx
  10a923:	8b 4d e0             	mov    0xffffffe0(%ebp),%ecx
  10a926:	89 55 d0             	mov    %edx,0xffffffd0(%ebp)
  10a929:	89 4d d4             	mov    %ecx,0xffffffd4(%ebp)
  10a92c:	e9 ff fe ff ff       	jmp    10a830 <__umoddi3+0x60>
  10a931:	8b 4d e0             	mov    0xffffffe0(%ebp),%ecx
  10a934:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  10a937:	2b 45 ec             	sub    0xffffffec(%ebp),%eax
  10a93a:	1b 4d e8             	sbb    0xffffffe8(%ebp),%ecx
  10a93d:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
  10a940:	89 4d e0             	mov    %ecx,0xffffffe0(%ebp)
  10a943:	eb db                	jmp    10a920 <__umoddi3+0x150>
  10a945:	39 f0                	cmp    %esi,%eax
  10a947:	0f 86 64 ff ff ff    	jbe    10a8b1 <__umoddi3+0xe1>
  10a94d:	29 f8                	sub    %edi,%eax
  10a94f:	1b 55 f4             	sbb    0xfffffff4(%ebp),%edx
  10a952:	e9 5a ff ff ff       	jmp    10a8b1 <__umoddi3+0xe1>
