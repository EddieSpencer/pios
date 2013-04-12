
obj/user/testvm:     file format elf32-i386

Disassembly of section .text:

40000100 <start>:
// starts us running when we are initially loaded into a new process.
	.globl start
start:

	call	main	// run the program
40000100:	e8 4d 2a 00 00       	call   40002b52 <main>
	pushl	%eax	// use with main's return value as exit status
40000105:	50                   	push   %eax
        movl	$SYS_RET, %eax
40000106:	b8 03 00 00 00       	mov    $0x3,%eax
        int	$T_SYSCALL
4000010b:	cd 30                	int    $0x30
1:	jmp 1b
4000010d:	eb fe                	jmp    4000010d <start+0xd>
4000010f:	90                   	nop    

40000110 <fork>:

// Fork a child process, returning 0 in the child and 1 in the parent.
int
fork(int cmd, uint8_t child)
{
40000110:	55                   	push   %ebp
40000111:	89 e5                	mov    %esp,%ebp
40000113:	57                   	push   %edi
40000114:	56                   	push   %esi
40000115:	53                   	push   %ebx
40000116:	81 ec 9c 02 00 00    	sub    $0x29c,%esp
4000011c:	8b 45 0c             	mov    0xc(%ebp),%eax
4000011f:	88 85 74 fd ff ff    	mov    %al,0xfffffd74(%ebp)
	// Set up the register state for the child
	struct procstate ps;
	memset(&ps, 0, sizeof(ps));
40000125:	c7 44 24 08 50 02 00 	movl   $0x250,0x8(%esp)
4000012c:	00 
4000012d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000134:	00 
40000135:	8d 85 78 fd ff ff    	lea    0xfffffd78(%ebp),%eax
4000013b:	89 04 24             	mov    %eax,(%esp)
4000013e:	e8 26 36 00 00       	call   40003769 <memset>

	// Use some assembly magic to propagate registers to child
	// and generate an appropriate starting eip
	int isparent;
	asm volatile(
40000143:	89 b5 7c fd ff ff    	mov    %esi,0xfffffd7c(%ebp)
40000149:	89 bd 78 fd ff ff    	mov    %edi,0xfffffd78(%ebp)
4000014f:	89 ad 80 fd ff ff    	mov    %ebp,0xfffffd80(%ebp)
40000155:	89 a5 bc fd ff ff    	mov    %esp,0xfffffdbc(%ebp)
4000015b:	c7 85 b0 fd ff ff 6a 	movl   $0x4000016a,0xfffffdb0(%ebp)
40000162:	01 00 40 
40000165:	b8 01 00 00 00       	mov    $0x1,%eax
4000016a:	89 45 cc             	mov    %eax,0xffffffcc(%ebp)
		"	movl	%%esi,%0;"
		"	movl	%%edi,%1;"
		"	movl	%%ebp,%2;"
		"	movl	%%esp,%3;"
		"	movl	$1f,%4;"
		"	movl	$1,%5;"
		"1:	"
		: "=m" (ps.tf.regs.esi),
		  "=m" (ps.tf.regs.edi),
		  "=m" (ps.tf.regs.ebp),
		  "=m" (ps.tf.esp),
		  "=m" (ps.tf.eip),
		  "=a" (isparent)
		:
		: "ebx", "ecx", "edx");
	if (!isparent)
4000016d:	83 7d cc 00          	cmpl   $0x0,0xffffffcc(%ebp)
40000171:	75 0c                	jne    4000017f <fork+0x6f>
		return 0;	// in the child
40000173:	c7 85 70 fd ff ff 00 	movl   $0x0,0xfffffd70(%ebp)
4000017a:	00 00 00 
4000017d:	eb 60                	jmp    400001df <fork+0xcf>

	// Fork the child, copying our entire user address space into it.
	ps.tf.regs.eax = 0;	// isparent == 0 in the child
4000017f:	c7 85 94 fd ff ff 00 	movl   $0x0,0xfffffd94(%ebp)
40000186:	00 00 00 
	sys_put(cmd | SYS_REGS | SYS_COPY, child, &ps, ALLVA, ALLVA, ALLSIZE);
40000189:	0f b6 95 74 fd ff ff 	movzbl 0xfffffd74(%ebp),%edx
40000190:	8b 45 08             	mov    0x8(%ebp),%eax
40000193:	0d 00 10 02 00       	or     $0x21000,%eax
40000198:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
4000019b:	66 89 55 e2          	mov    %dx,0xffffffe2(%ebp)
4000019f:	8d 85 78 fd ff ff    	lea    0xfffffd78(%ebp),%eax
400001a5:	89 45 dc             	mov    %eax,0xffffffdc(%ebp)
400001a8:	c7 45 d8 00 00 00 40 	movl   $0x40000000,0xffffffd8(%ebp)
400001af:	c7 45 d4 00 00 00 40 	movl   $0x40000000,0xffffffd4(%ebp)
400001b6:	c7 45 d0 00 00 00 b0 	movl   $0xb0000000,0xffffffd0(%ebp)
static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
400001bd:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
400001c0:	83 c8 01             	or     $0x1,%eax
400001c3:	8b 5d dc             	mov    0xffffffdc(%ebp),%ebx
400001c6:	0f b7 55 e2          	movzwl 0xffffffe2(%ebp),%edx
400001ca:	8b 75 d8             	mov    0xffffffd8(%ebp),%esi
400001cd:	8b 7d d4             	mov    0xffffffd4(%ebp),%edi
400001d0:	8b 4d d0             	mov    0xffffffd0(%ebp),%ecx
400001d3:	cd 30                	int    $0x30

	return 1;
400001d5:	c7 85 70 fd ff ff 01 	movl   $0x1,0xfffffd70(%ebp)
400001dc:	00 00 00 
400001df:	8b 85 70 fd ff ff    	mov    0xfffffd70(%ebp),%eax
}
400001e5:	81 c4 9c 02 00 00    	add    $0x29c,%esp
400001eb:	5b                   	pop    %ebx
400001ec:	5e                   	pop    %esi
400001ed:	5f                   	pop    %edi
400001ee:	5d                   	pop    %ebp
400001ef:	c3                   	ret    

400001f0 <join>:

void
join(int cmd, uint8_t child, int trapexpect)
{
400001f0:	55                   	push   %ebp
400001f1:	89 e5                	mov    %esp,%ebp
400001f3:	57                   	push   %edi
400001f4:	56                   	push   %esi
400001f5:	53                   	push   %ebx
400001f6:	81 ec ac 02 00 00    	sub    $0x2ac,%esp
400001fc:	8b 45 0c             	mov    0xc(%ebp),%eax
400001ff:	88 85 74 fd ff ff    	mov    %al,0xfffffd74(%ebp)
	// Wait for the child and retrieve its CPU state.
	// If merging, leave the highest 4MB containing the stack unmerged,
	// so that the stack acts as a "thread-private" memory area.
	struct procstate ps;
	sys_get(cmd | SYS_REGS, child, &ps, ALLVA, ALLVA, ALLSIZE-PTSIZE);
40000205:	0f b6 95 74 fd ff ff 	movzbl 0xfffffd74(%ebp),%edx
4000020c:	8b 45 08             	mov    0x8(%ebp),%eax
4000020f:	80 cc 10             	or     $0x10,%ah
40000212:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
40000215:	66 89 55 e2          	mov    %dx,0xffffffe2(%ebp)
40000219:	8d 85 78 fd ff ff    	lea    0xfffffd78(%ebp),%eax
4000021f:	89 45 dc             	mov    %eax,0xffffffdc(%ebp)
40000222:	c7 45 d8 00 00 00 40 	movl   $0x40000000,0xffffffd8(%ebp)
40000229:	c7 45 d4 00 00 00 40 	movl   $0x40000000,0xffffffd4(%ebp)
40000230:	c7 45 d0 00 00 c0 af 	movl   $0xafc00000,0xffffffd0(%ebp)
static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40000237:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
4000023a:	83 c8 02             	or     $0x2,%eax
4000023d:	8b 5d dc             	mov    0xffffffdc(%ebp),%ebx
40000240:	0f b7 55 e2          	movzwl 0xffffffe2(%ebp),%edx
40000244:	8b 75 d8             	mov    0xffffffd8(%ebp),%esi
40000247:	8b 7d d4             	mov    0xffffffd4(%ebp),%edi
4000024a:	8b 4d d0             	mov    0xffffffd0(%ebp),%ecx
4000024d:	cd 30                	int    $0x30

	// Make sure the child exited with the expected trap number
	if (ps.tf.trapno != trapexpect) {
4000024f:	8b 95 a8 fd ff ff    	mov    0xfffffda8(%ebp),%edx
40000255:	8b 45 10             	mov    0x10(%ebp),%eax
40000258:	39 c2                	cmp    %eax,%edx
4000025a:	74 59                	je     400002b5 <join+0xc5>
		cprintf("  eip  0x%08x\n", ps.tf.eip);
4000025c:	8b 85 b0 fd ff ff    	mov    0xfffffdb0(%ebp),%eax
40000262:	89 44 24 04          	mov    %eax,0x4(%esp)
40000266:	c7 04 24 60 3c 00 40 	movl   $0x40003c60,(%esp)
4000026d:	e8 ef 2b 00 00       	call   40002e61 <cprintf>
		cprintf("  esp  0x%08x\n", ps.tf.esp);
40000272:	8b 85 bc fd ff ff    	mov    0xfffffdbc(%ebp),%eax
40000278:	89 44 24 04          	mov    %eax,0x4(%esp)
4000027c:	c7 04 24 6f 3c 00 40 	movl   $0x40003c6f,(%esp)
40000283:	e8 d9 2b 00 00       	call   40002e61 <cprintf>
		panic("join: unexpected trap %d, expecting %d\n",
40000288:	8b 95 a8 fd ff ff    	mov    0xfffffda8(%ebp),%edx
4000028e:	8b 45 10             	mov    0x10(%ebp),%eax
40000291:	89 44 24 10          	mov    %eax,0x10(%esp)
40000295:	89 54 24 0c          	mov    %edx,0xc(%esp)
40000299:	c7 44 24 08 80 3c 00 	movl   $0x40003c80,0x8(%esp)
400002a0:	40 
400002a1:	c7 44 24 04 50 00 00 	movl   $0x50,0x4(%esp)
400002a8:	00 
400002a9:	c7 04 24 a8 3c 00 40 	movl   $0x40003ca8,(%esp)
400002b0:	e8 ef 28 00 00       	call   40002ba4 <debug_panic>
			ps.tf.trapno, trapexpect);
	}
}
400002b5:	81 c4 ac 02 00 00    	add    $0x2ac,%esp
400002bb:	5b                   	pop    %ebx
400002bc:	5e                   	pop    %esi
400002bd:	5f                   	pop    %edi
400002be:	5d                   	pop    %ebp
400002bf:	c3                   	ret    

400002c0 <gentrap>:

void
gentrap(int trap)
{
400002c0:	55                   	push   %ebp
400002c1:	89 e5                	mov    %esp,%ebp
400002c3:	83 ec 28             	sub    $0x28,%esp
	int bounds[2] = { 1, 3 };
400002c6:	c7 45 f8 01 00 00 00 	movl   $0x1,0xfffffff8(%ebp)
400002cd:	c7 45 fc 03 00 00 00 	movl   $0x3,0xfffffffc(%ebp)
	switch (trap) {
400002d4:	8b 45 08             	mov    0x8(%ebp),%eax
400002d7:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
400002da:	83 7d ec 30          	cmpl   $0x30,0xffffffec(%ebp)
400002de:	77 31                	ja     40000311 <gentrap+0x51>
400002e0:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
400002e3:	8b 04 95 c8 3c 00 40 	mov    0x40003cc8(,%edx,4),%eax
400002ea:	ff e0                	jmp    *%eax
	case T_DIVIDE:
		asm volatile("divl %0,%0" : : "r" (0));
400002ec:	b8 00 00 00 00       	mov    $0x0,%eax
400002f1:	f7 f0                	div    %eax
	case T_BRKPT:
		asm volatile("int3");
400002f3:	cc                   	int3   
	case T_OFLOW:
		asm volatile("addl %0,%0; into" : : "r" (0x70000000));
400002f4:	b8 00 00 00 70       	mov    $0x70000000,%eax
400002f9:	01 c0                	add    %eax,%eax
400002fb:	ce                   	into   
	case T_BOUND:
		asm volatile("boundl %0,%1" : : "r" (0), "m" (bounds[0]));
400002fc:	b8 00 00 00 00       	mov    $0x0,%eax
40000301:	62 45 f8             	bound  %eax,0xfffffff8(%ebp)
	case T_ILLOP:
		asm volatile("ud2");	// guaranteed to be undefined
40000304:	0f 0b                	ud2a   
	case T_GPFLT:
		asm volatile("lidt %0" : : "m" (trap));
40000306:	0f 01 5d 08          	lidtl  0x8(%ebp)

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
4000030a:	b8 03 00 00 00       	mov    $0x3,%eax
4000030f:	cd 30                	int    $0x30
	case T_SYSCALL:
		sys_ret();
	default:
		panic("unknown trap %d", trap);
40000311:	8b 45 08             	mov    0x8(%ebp),%eax
40000314:	89 44 24 0c          	mov    %eax,0xc(%esp)
40000318:	c7 44 24 08 b6 3c 00 	movl   $0x40003cb6,0x8(%esp)
4000031f:	40 
40000320:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
40000327:	00 
40000328:	c7 04 24 a8 3c 00 40 	movl   $0x40003ca8,(%esp)
4000032f:	e8 70 28 00 00       	call   40002ba4 <debug_panic>

40000334 <trapcheck>:
	}
}

static void
trapcheck(int trapno)
{
40000334:	55                   	push   %ebp
40000335:	89 e5                	mov    %esp,%ebp
40000337:	83 ec 18             	sub    $0x18,%esp
	// cprintf("trapcheck %d\n", trapno);
	if (!fork(SYS_START, 0)) { gentrap(trapno); }
4000033a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000341:	00 
40000342:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000349:	e8 c2 fd ff ff       	call   40000110 <fork>
4000034e:	85 c0                	test   %eax,%eax
40000350:	75 0b                	jne    4000035d <trapcheck+0x29>
40000352:	8b 45 08             	mov    0x8(%ebp),%eax
40000355:	89 04 24             	mov    %eax,(%esp)
40000358:	e8 63 ff ff ff       	call   400002c0 <gentrap>
	join(0, 0, trapno);
4000035d:	8b 45 08             	mov    0x8(%ebp),%eax
40000360:	89 44 24 08          	mov    %eax,0x8(%esp)
40000364:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000036b:	00 
4000036c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000373:	e8 78 fe ff ff       	call   400001f0 <join>
}
40000378:	c9                   	leave  
40000379:	c3                   	ret    

4000037a <cputsfaultchild>:

#define readfaulttest(va) \
	if (!fork(SYS_START, 0)) \
		{ (void)(*(volatile int*)(va)); sys_ret(); } \
	join(0, 0, T_PGFLT);

#define writefaulttest(va) \
	if (!fork(SYS_START, 0)) \
		{ volatile int *p = (volatile int*)(va); \
		  *p = 0xdeadbeef; sys_ret(); } \
	join(0, 0, T_PGFLT);

static void cputsfaultchild(int arg) {
4000037a:	55                   	push   %ebp
4000037b:	89 e5                	mov    %esp,%ebp
4000037d:	53                   	push   %ebx
4000037e:	83 ec 10             	sub    $0x10,%esp
	sys_cputs((char*)arg);
40000381:	8b 45 08             	mov    0x8(%ebp),%eax
40000384:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %0" :
40000387:	b8 00 00 00 00       	mov    $0x0,%eax
4000038c:	8b 5d f8             	mov    0xfffffff8(%ebp),%ebx
4000038f:	cd 30                	int    $0x30
}
40000391:	83 c4 10             	add    $0x10,%esp
40000394:	5b                   	pop    %ebx
40000395:	5d                   	pop    %ebp
40000396:	c3                   	ret    

40000397 <loadcheck>:
#define cputsfaulttest(va) \
	if (!fork(SYS_START, 0)) \
		{ sys_cputs((char*)(va)); sys_ret(); } \
	join(0, 0, T_PGFLT);

#define putfaulttest(va) \
	if (!fork(SYS_START, 0)) { \
		sys_put(SYS_REGS, 0, (procstate*)(va), NULL, NULL, 0); \
		sys_ret(); } \
	join(0, 0, T_PGFLT);

#define getfaulttest(va) \
	if (!fork(SYS_START, 0)) { \
		sys_get(SYS_REGS, 0, (procstate*)(va), NULL, NULL, 0); \
		sys_ret(); } \
	join(0, 0, T_PGFLT);

void
loadcheck()
{
40000397:	55                   	push   %ebp
40000398:	89 e5                	mov    %esp,%ebp
4000039a:	83 ec 28             	sub    $0x28,%esp
	// Simple ELF loading test: make sure bss is mapped but cleared
	uint8_t *p;
	for (p = edata; p < end; p++) {
4000039d:	c7 45 fc 80 5d 00 40 	movl   $0x40005d80,0xfffffffc(%ebp)
400003a4:	eb 5c                	jmp    40000402 <loadcheck+0x6b>
		if (*p != 0) cprintf("%x %d\n", p, *p);
400003a6:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
400003a9:	0f b6 00             	movzbl (%eax),%eax
400003ac:	84 c0                	test   %al,%al
400003ae:	74 20                	je     400003d0 <loadcheck+0x39>
400003b0:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
400003b3:	0f b6 00             	movzbl (%eax),%eax
400003b6:	0f b6 c0             	movzbl %al,%eax
400003b9:	89 44 24 08          	mov    %eax,0x8(%esp)
400003bd:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
400003c0:	89 44 24 04          	mov    %eax,0x4(%esp)
400003c4:	c7 04 24 8c 3d 00 40 	movl   $0x40003d8c,(%esp)
400003cb:	e8 91 2a 00 00       	call   40002e61 <cprintf>
		assert(*p == 0);
400003d0:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
400003d3:	0f b6 00             	movzbl (%eax),%eax
400003d6:	84 c0                	test   %al,%al
400003d8:	74 24                	je     400003fe <loadcheck+0x67>
400003da:	c7 44 24 0c 93 3d 00 	movl   $0x40003d93,0xc(%esp)
400003e1:	40 
400003e2:	c7 44 24 08 9b 3d 00 	movl   $0x40003d9b,0x8(%esp)
400003e9:	40 
400003ea:	c7 44 24 04 9a 00 00 	movl   $0x9a,0x4(%esp)
400003f1:	00 
400003f2:	c7 04 24 a8 3c 00 40 	movl   $0x40003ca8,(%esp)
400003f9:	e8 a6 27 00 00       	call   40002ba4 <debug_panic>
400003fe:	83 45 fc 01          	addl   $0x1,0xfffffffc(%ebp)
40000402:	81 7d fc a8 7e 00 40 	cmpl   $0x40007ea8,0xfffffffc(%ebp)
40000409:	72 9b                	jb     400003a6 <loadcheck+0xf>
	}

	cprintf("testvm: loadcheck passed\n");
4000040b:	c7 04 24 b0 3d 00 40 	movl   $0x40003db0,(%esp)
40000412:	e8 4a 2a 00 00       	call   40002e61 <cprintf>
}
40000417:	c9                   	leave  
40000418:	c3                   	ret    

40000419 <forkcheck>:

// Check forking of simple child processes and trap redirection (once more)
void
forkcheck()
{
40000419:	55                   	push   %ebp
4000041a:	89 e5                	mov    %esp,%ebp
4000041c:	83 ec 18             	sub    $0x18,%esp
	// Our first copy-on-write test: fork and execute a simple child.
	if (!fork(SYS_START, 0)) gentrap(T_SYSCALL);
4000041f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000426:	00 
40000427:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
4000042e:	e8 dd fc ff ff       	call   40000110 <fork>
40000433:	85 c0                	test   %eax,%eax
40000435:	75 0c                	jne    40000443 <forkcheck+0x2a>
40000437:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
4000043e:	e8 7d fe ff ff       	call   400002c0 <gentrap>
	join(0, 0, T_SYSCALL);
40000443:	c7 44 24 08 30 00 00 	movl   $0x30,0x8(%esp)
4000044a:	00 
4000044b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000452:	00 
40000453:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
4000045a:	e8 91 fd ff ff       	call   400001f0 <join>

	// Re-check trap handling and reflection from child processes
	trapcheck(T_DIVIDE);
4000045f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000466:	e8 c9 fe ff ff       	call   40000334 <trapcheck>
	trapcheck(T_BRKPT);
4000046b:	c7 04 24 03 00 00 00 	movl   $0x3,(%esp)
40000472:	e8 bd fe ff ff       	call   40000334 <trapcheck>
	trapcheck(T_OFLOW);
40000477:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
4000047e:	e8 b1 fe ff ff       	call   40000334 <trapcheck>
	trapcheck(T_BOUND);
40000483:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
4000048a:	e8 a5 fe ff ff       	call   40000334 <trapcheck>
	trapcheck(T_ILLOP);
4000048f:	c7 04 24 06 00 00 00 	movl   $0x6,(%esp)
40000496:	e8 99 fe ff ff       	call   40000334 <trapcheck>
	trapcheck(T_GPFLT);
4000049b:	c7 04 24 0d 00 00 00 	movl   $0xd,(%esp)
400004a2:	e8 8d fe ff ff       	call   40000334 <trapcheck>

	// Make sure we can run several children using the same stack area
	// (since each child should get a separate logical copy)
	if (!fork(SYS_START, 0)) gentrap(T_SYSCALL);
400004a7:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400004ae:	00 
400004af:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
400004b6:	e8 55 fc ff ff       	call   40000110 <fork>
400004bb:	85 c0                	test   %eax,%eax
400004bd:	75 0c                	jne    400004cb <forkcheck+0xb2>
400004bf:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
400004c6:	e8 f5 fd ff ff       	call   400002c0 <gentrap>
	if (!fork(SYS_START, 1)) gentrap(T_DIVIDE);
400004cb:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
400004d2:	00 
400004d3:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
400004da:	e8 31 fc ff ff       	call   40000110 <fork>
400004df:	85 c0                	test   %eax,%eax
400004e1:	75 0c                	jne    400004ef <forkcheck+0xd6>
400004e3:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
400004ea:	e8 d1 fd ff ff       	call   400002c0 <gentrap>
	if (!fork(SYS_START, 2)) gentrap(T_BRKPT);
400004ef:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
400004f6:	00 
400004f7:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
400004fe:	e8 0d fc ff ff       	call   40000110 <fork>
40000503:	85 c0                	test   %eax,%eax
40000505:	75 0c                	jne    40000513 <forkcheck+0xfa>
40000507:	c7 04 24 03 00 00 00 	movl   $0x3,(%esp)
4000050e:	e8 ad fd ff ff       	call   400002c0 <gentrap>
	if (!fork(SYS_START, 3)) gentrap(T_OFLOW);
40000513:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
4000051a:	00 
4000051b:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000522:	e8 e9 fb ff ff       	call   40000110 <fork>
40000527:	85 c0                	test   %eax,%eax
40000529:	75 0c                	jne    40000537 <forkcheck+0x11e>
4000052b:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
40000532:	e8 89 fd ff ff       	call   400002c0 <gentrap>
	if (!fork(SYS_START, 4)) gentrap(T_BOUND);
40000537:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
4000053e:	00 
4000053f:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000546:	e8 c5 fb ff ff       	call   40000110 <fork>
4000054b:	85 c0                	test   %eax,%eax
4000054d:	75 0c                	jne    4000055b <forkcheck+0x142>
4000054f:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
40000556:	e8 65 fd ff ff       	call   400002c0 <gentrap>
	if (!fork(SYS_START, 5)) gentrap(T_ILLOP);
4000055b:	c7 44 24 04 05 00 00 	movl   $0x5,0x4(%esp)
40000562:	00 
40000563:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
4000056a:	e8 a1 fb ff ff       	call   40000110 <fork>
4000056f:	85 c0                	test   %eax,%eax
40000571:	75 0c                	jne    4000057f <forkcheck+0x166>
40000573:	c7 04 24 06 00 00 00 	movl   $0x6,(%esp)
4000057a:	e8 41 fd ff ff       	call   400002c0 <gentrap>
	if (!fork(SYS_START, 6)) gentrap(T_GPFLT);
4000057f:	c7 44 24 04 06 00 00 	movl   $0x6,0x4(%esp)
40000586:	00 
40000587:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
4000058e:	e8 7d fb ff ff       	call   40000110 <fork>
40000593:	85 c0                	test   %eax,%eax
40000595:	75 0c                	jne    400005a3 <forkcheck+0x18a>
40000597:	c7 04 24 0d 00 00 00 	movl   $0xd,(%esp)
4000059e:	e8 1d fd ff ff       	call   400002c0 <gentrap>
	join(0, 0, T_SYSCALL);
400005a3:	c7 44 24 08 30 00 00 	movl   $0x30,0x8(%esp)
400005aa:	00 
400005ab:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400005b2:	00 
400005b3:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
400005ba:	e8 31 fc ff ff       	call   400001f0 <join>
	join(0, 1, T_DIVIDE);
400005bf:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
400005c6:	00 
400005c7:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
400005ce:	00 
400005cf:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
400005d6:	e8 15 fc ff ff       	call   400001f0 <join>
	join(0, 2, T_BRKPT);
400005db:	c7 44 24 08 03 00 00 	movl   $0x3,0x8(%esp)
400005e2:	00 
400005e3:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
400005ea:	00 
400005eb:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
400005f2:	e8 f9 fb ff ff       	call   400001f0 <join>
	join(0, 3, T_OFLOW);
400005f7:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
400005fe:	00 
400005ff:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
40000606:	00 
40000607:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
4000060e:	e8 dd fb ff ff       	call   400001f0 <join>
	join(0, 4, T_BOUND);
40000613:	c7 44 24 08 05 00 00 	movl   $0x5,0x8(%esp)
4000061a:	00 
4000061b:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
40000622:	00 
40000623:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
4000062a:	e8 c1 fb ff ff       	call   400001f0 <join>
	join(0, 5, T_ILLOP);
4000062f:	c7 44 24 08 06 00 00 	movl   $0x6,0x8(%esp)
40000636:	00 
40000637:	c7 44 24 04 05 00 00 	movl   $0x5,0x4(%esp)
4000063e:	00 
4000063f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000646:	e8 a5 fb ff ff       	call   400001f0 <join>
	join(0, 6, T_GPFLT);
4000064b:	c7 44 24 08 0d 00 00 	movl   $0xd,0x8(%esp)
40000652:	00 
40000653:	c7 44 24 04 06 00 00 	movl   $0x6,0x4(%esp)
4000065a:	00 
4000065b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000662:	e8 89 fb ff ff       	call   400001f0 <join>

	// Check that kernel address space is inaccessible to user code
	readfaulttest(0);
40000667:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000066e:	00 
4000066f:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000676:	e8 95 fa ff ff       	call   40000110 <fork>
4000067b:	85 c0                	test   %eax,%eax
4000067d:	75 0e                	jne    4000068d <forkcheck+0x274>
4000067f:	b8 00 00 00 00       	mov    $0x0,%eax
40000684:	8b 00                	mov    (%eax),%eax

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40000686:	b8 03 00 00 00       	mov    $0x3,%eax
4000068b:	cd 30                	int    $0x30
4000068d:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40000694:	00 
40000695:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000069c:	00 
4000069d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
400006a4:	e8 47 fb ff ff       	call   400001f0 <join>
	readfaulttest(VM_USERLO-4);
400006a9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400006b0:	00 
400006b1:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
400006b8:	e8 53 fa ff ff       	call   40000110 <fork>
400006bd:	85 c0                	test   %eax,%eax
400006bf:	75 0e                	jne    400006cf <forkcheck+0x2b6>
400006c1:	b8 fc ff ff 3f       	mov    $0x3ffffffc,%eax
400006c6:	8b 00                	mov    (%eax),%eax

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
400006c8:	b8 03 00 00 00       	mov    $0x3,%eax
400006cd:	cd 30                	int    $0x30
400006cf:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
400006d6:	00 
400006d7:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400006de:	00 
400006df:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
400006e6:	e8 05 fb ff ff       	call   400001f0 <join>
	readfaulttest(VM_USERHI);
400006eb:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400006f2:	00 
400006f3:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
400006fa:	e8 11 fa ff ff       	call   40000110 <fork>
400006ff:	85 c0                	test   %eax,%eax
40000701:	75 0e                	jne    40000711 <forkcheck+0x2f8>
40000703:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
40000708:	8b 00                	mov    (%eax),%eax

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
4000070a:	b8 03 00 00 00       	mov    $0x3,%eax
4000070f:	cd 30                	int    $0x30
40000711:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40000718:	00 
40000719:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000720:	00 
40000721:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000728:	e8 c3 fa ff ff       	call   400001f0 <join>
	readfaulttest(0-4);
4000072d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000734:	00 
40000735:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
4000073c:	e8 cf f9 ff ff       	call   40000110 <fork>
40000741:	85 c0                	test   %eax,%eax
40000743:	75 0e                	jne    40000753 <forkcheck+0x33a>
40000745:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
4000074a:	8b 00                	mov    (%eax),%eax

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
4000074c:	b8 03 00 00 00       	mov    $0x3,%eax
40000751:	cd 30                	int    $0x30
40000753:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
4000075a:	00 
4000075b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000762:	00 
40000763:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
4000076a:	e8 81 fa ff ff       	call   400001f0 <join>

	cprintf("testvm: forkcheck passed\n");
4000076f:	c7 04 24 ca 3d 00 40 	movl   $0x40003dca,(%esp)
40000776:	e8 e6 26 00 00       	call   40002e61 <cprintf>
}
4000077b:	c9                   	leave  
4000077c:	c3                   	ret    

4000077d <protcheck>:

// Check for proper virtual memory protection
void
protcheck()
{
4000077d:	55                   	push   %ebp
4000077e:	89 e5                	mov    %esp,%ebp
40000780:	57                   	push   %edi
40000781:	56                   	push   %esi
40000782:	53                   	push   %ebx
40000783:	81 ec bc 01 00 00    	sub    $0x1bc,%esp
	// Copyin/copyout protection:
	// make sure we can't use cputs/put/get data in kernel space
	cputsfaulttest(0);
40000789:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000790:	00 
40000791:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000798:	e8 73 f9 ff ff       	call   40000110 <fork>
4000079d:	85 c0                	test   %eax,%eax
4000079f:	75 1e                	jne    400007bf <protcheck+0x42>
400007a1:	c7 85 58 fe ff ff 00 	movl   $0x0,0xfffffe58(%ebp)
400007a8:	00 00 00 
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %0" :
400007ab:	b8 00 00 00 00       	mov    $0x0,%eax
400007b0:	8b 9d 58 fe ff ff    	mov    0xfffffe58(%ebp),%ebx
400007b6:	cd 30                	int    $0x30
		: "i" (T_SYSCALL),
		  "a" (SYS_CPUTS),
		  "b" (s)
		: "cc", "memory");
}

static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
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
400007b8:	b8 03 00 00 00       	mov    $0x3,%eax
400007bd:	cd 30                	int    $0x30
400007bf:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
400007c6:	00 
400007c7:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400007ce:	00 
400007cf:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
400007d6:	e8 15 fa ff ff       	call   400001f0 <join>
	cputsfaulttest(VM_USERLO-1);
400007db:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400007e2:	00 
400007e3:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
400007ea:	e8 21 f9 ff ff       	call   40000110 <fork>
400007ef:	85 c0                	test   %eax,%eax
400007f1:	75 1e                	jne    40000811 <protcheck+0x94>
400007f3:	c7 85 5c fe ff ff ff 	movl   $0x3fffffff,0xfffffe5c(%ebp)
400007fa:	ff ff 3f 
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %0" :
400007fd:	b8 00 00 00 00       	mov    $0x0,%eax
40000802:	8b 9d 5c fe ff ff    	mov    0xfffffe5c(%ebp),%ebx
40000808:	cd 30                	int    $0x30
		: "i" (T_SYSCALL),
		  "a" (SYS_CPUTS),
		  "b" (s)
		: "cc", "memory");
}

static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
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
4000080a:	b8 03 00 00 00       	mov    $0x3,%eax
4000080f:	cd 30                	int    $0x30
40000811:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40000818:	00 
40000819:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000820:	00 
40000821:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000828:	e8 c3 f9 ff ff       	call   400001f0 <join>
	cputsfaulttest(VM_USERHI);
4000082d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000834:	00 
40000835:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
4000083c:	e8 cf f8 ff ff       	call   40000110 <fork>
40000841:	85 c0                	test   %eax,%eax
40000843:	75 1e                	jne    40000863 <protcheck+0xe6>
40000845:	c7 85 60 fe ff ff 00 	movl   $0xf0000000,0xfffffe60(%ebp)
4000084c:	00 00 f0 
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %0" :
4000084f:	b8 00 00 00 00       	mov    $0x0,%eax
40000854:	8b 9d 60 fe ff ff    	mov    0xfffffe60(%ebp),%ebx
4000085a:	cd 30                	int    $0x30
		: "i" (T_SYSCALL),
		  "a" (SYS_CPUTS),
		  "b" (s)
		: "cc", "memory");
}

static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
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
4000085c:	b8 03 00 00 00       	mov    $0x3,%eax
40000861:	cd 30                	int    $0x30
40000863:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
4000086a:	00 
4000086b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000872:	00 
40000873:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
4000087a:	e8 71 f9 ff ff       	call   400001f0 <join>
	cputsfaulttest(~0);
4000087f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000886:	00 
40000887:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
4000088e:	e8 7d f8 ff ff       	call   40000110 <fork>
40000893:	85 c0                	test   %eax,%eax
40000895:	75 1e                	jne    400008b5 <protcheck+0x138>
40000897:	c7 85 64 fe ff ff ff 	movl   $0xffffffff,0xfffffe64(%ebp)
4000089e:	ff ff ff 
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %0" :
400008a1:	b8 00 00 00 00       	mov    $0x0,%eax
400008a6:	8b 9d 64 fe ff ff    	mov    0xfffffe64(%ebp),%ebx
400008ac:	cd 30                	int    $0x30
		: "i" (T_SYSCALL),
		  "a" (SYS_CPUTS),
		  "b" (s)
		: "cc", "memory");
}

static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
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
400008ae:	b8 03 00 00 00       	mov    $0x3,%eax
400008b3:	cd 30                	int    $0x30
400008b5:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
400008bc:	00 
400008bd:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400008c4:	00 
400008c5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
400008cc:	e8 1f f9 ff ff       	call   400001f0 <join>
	putfaulttest(0);
400008d1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400008d8:	00 
400008d9:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
400008e0:	e8 2b f8 ff ff       	call   40000110 <fork>
400008e5:	85 c0                	test   %eax,%eax
400008e7:	75 6c                	jne    40000955 <protcheck+0x1d8>
400008e9:	c7 85 7c fe ff ff 00 	movl   $0x1000,0xfffffe7c(%ebp)
400008f0:	10 00 00 
400008f3:	66 c7 85 7a fe ff ff 	movw   $0x0,0xfffffe7a(%ebp)
400008fa:	00 00 
400008fc:	c7 85 74 fe ff ff 00 	movl   $0x0,0xfffffe74(%ebp)
40000903:	00 00 00 
40000906:	c7 85 70 fe ff ff 00 	movl   $0x0,0xfffffe70(%ebp)
4000090d:	00 00 00 
40000910:	c7 85 6c fe ff ff 00 	movl   $0x0,0xfffffe6c(%ebp)
40000917:	00 00 00 
4000091a:	c7 85 68 fe ff ff 00 	movl   $0x0,0xfffffe68(%ebp)
40000921:	00 00 00 
static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
40000924:	8b 85 7c fe ff ff    	mov    0xfffffe7c(%ebp),%eax
4000092a:	83 c8 01             	or     $0x1,%eax
4000092d:	8b 9d 74 fe ff ff    	mov    0xfffffe74(%ebp),%ebx
40000933:	0f b7 95 7a fe ff ff 	movzwl 0xfffffe7a(%ebp),%edx
4000093a:	8b b5 70 fe ff ff    	mov    0xfffffe70(%ebp),%esi
40000940:	8b bd 6c fe ff ff    	mov    0xfffffe6c(%ebp),%edi
40000946:	8b 8d 68 fe ff ff    	mov    0xfffffe68(%ebp),%ecx
4000094c:	cd 30                	int    $0x30
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
4000094e:	b8 03 00 00 00       	mov    $0x3,%eax
40000953:	cd 30                	int    $0x30
40000955:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
4000095c:	00 
4000095d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000964:	00 
40000965:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
4000096c:	e8 7f f8 ff ff       	call   400001f0 <join>
	putfaulttest(VM_USERLO-1);
40000971:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000978:	00 
40000979:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000980:	e8 8b f7 ff ff       	call   40000110 <fork>
40000985:	85 c0                	test   %eax,%eax
40000987:	75 6c                	jne    400009f5 <protcheck+0x278>
40000989:	c7 85 94 fe ff ff 00 	movl   $0x1000,0xfffffe94(%ebp)
40000990:	10 00 00 
40000993:	66 c7 85 92 fe ff ff 	movw   $0x0,0xfffffe92(%ebp)
4000099a:	00 00 
4000099c:	c7 85 8c fe ff ff ff 	movl   $0x3fffffff,0xfffffe8c(%ebp)
400009a3:	ff ff 3f 
400009a6:	c7 85 88 fe ff ff 00 	movl   $0x0,0xfffffe88(%ebp)
400009ad:	00 00 00 
400009b0:	c7 85 84 fe ff ff 00 	movl   $0x0,0xfffffe84(%ebp)
400009b7:	00 00 00 
400009ba:	c7 85 80 fe ff ff 00 	movl   $0x0,0xfffffe80(%ebp)
400009c1:	00 00 00 
static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
400009c4:	8b 85 94 fe ff ff    	mov    0xfffffe94(%ebp),%eax
400009ca:	83 c8 01             	or     $0x1,%eax
400009cd:	8b 9d 8c fe ff ff    	mov    0xfffffe8c(%ebp),%ebx
400009d3:	0f b7 95 92 fe ff ff 	movzwl 0xfffffe92(%ebp),%edx
400009da:	8b b5 88 fe ff ff    	mov    0xfffffe88(%ebp),%esi
400009e0:	8b bd 84 fe ff ff    	mov    0xfffffe84(%ebp),%edi
400009e6:	8b 8d 80 fe ff ff    	mov    0xfffffe80(%ebp),%ecx
400009ec:	cd 30                	int    $0x30
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
400009ee:	b8 03 00 00 00       	mov    $0x3,%eax
400009f3:	cd 30                	int    $0x30
400009f5:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
400009fc:	00 
400009fd:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000a04:	00 
40000a05:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000a0c:	e8 df f7 ff ff       	call   400001f0 <join>
	putfaulttest(VM_USERHI);
40000a11:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000a18:	00 
40000a19:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000a20:	e8 eb f6 ff ff       	call   40000110 <fork>
40000a25:	85 c0                	test   %eax,%eax
40000a27:	75 6c                	jne    40000a95 <protcheck+0x318>
40000a29:	c7 85 ac fe ff ff 00 	movl   $0x1000,0xfffffeac(%ebp)
40000a30:	10 00 00 
40000a33:	66 c7 85 aa fe ff ff 	movw   $0x0,0xfffffeaa(%ebp)
40000a3a:	00 00 
40000a3c:	c7 85 a4 fe ff ff 00 	movl   $0xf0000000,0xfffffea4(%ebp)
40000a43:	00 00 f0 
40000a46:	c7 85 a0 fe ff ff 00 	movl   $0x0,0xfffffea0(%ebp)
40000a4d:	00 00 00 
40000a50:	c7 85 9c fe ff ff 00 	movl   $0x0,0xfffffe9c(%ebp)
40000a57:	00 00 00 
40000a5a:	c7 85 98 fe ff ff 00 	movl   $0x0,0xfffffe98(%ebp)
40000a61:	00 00 00 
static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
40000a64:	8b 85 ac fe ff ff    	mov    0xfffffeac(%ebp),%eax
40000a6a:	83 c8 01             	or     $0x1,%eax
40000a6d:	8b 9d a4 fe ff ff    	mov    0xfffffea4(%ebp),%ebx
40000a73:	0f b7 95 aa fe ff ff 	movzwl 0xfffffeaa(%ebp),%edx
40000a7a:	8b b5 a0 fe ff ff    	mov    0xfffffea0(%ebp),%esi
40000a80:	8b bd 9c fe ff ff    	mov    0xfffffe9c(%ebp),%edi
40000a86:	8b 8d 98 fe ff ff    	mov    0xfffffe98(%ebp),%ecx
40000a8c:	cd 30                	int    $0x30
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
40000a8e:	b8 03 00 00 00       	mov    $0x3,%eax
40000a93:	cd 30                	int    $0x30
40000a95:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40000a9c:	00 
40000a9d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000aa4:	00 
40000aa5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000aac:	e8 3f f7 ff ff       	call   400001f0 <join>
	putfaulttest(~0);
40000ab1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000ab8:	00 
40000ab9:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000ac0:	e8 4b f6 ff ff       	call   40000110 <fork>
40000ac5:	85 c0                	test   %eax,%eax
40000ac7:	75 6c                	jne    40000b35 <protcheck+0x3b8>
40000ac9:	c7 85 c4 fe ff ff 00 	movl   $0x1000,0xfffffec4(%ebp)
40000ad0:	10 00 00 
40000ad3:	66 c7 85 c2 fe ff ff 	movw   $0x0,0xfffffec2(%ebp)
40000ada:	00 00 
40000adc:	c7 85 bc fe ff ff ff 	movl   $0xffffffff,0xfffffebc(%ebp)
40000ae3:	ff ff ff 
40000ae6:	c7 85 b8 fe ff ff 00 	movl   $0x0,0xfffffeb8(%ebp)
40000aed:	00 00 00 
40000af0:	c7 85 b4 fe ff ff 00 	movl   $0x0,0xfffffeb4(%ebp)
40000af7:	00 00 00 
40000afa:	c7 85 b0 fe ff ff 00 	movl   $0x0,0xfffffeb0(%ebp)
40000b01:	00 00 00 
static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
40000b04:	8b 85 c4 fe ff ff    	mov    0xfffffec4(%ebp),%eax
40000b0a:	83 c8 01             	or     $0x1,%eax
40000b0d:	8b 9d bc fe ff ff    	mov    0xfffffebc(%ebp),%ebx
40000b13:	0f b7 95 c2 fe ff ff 	movzwl 0xfffffec2(%ebp),%edx
40000b1a:	8b b5 b8 fe ff ff    	mov    0xfffffeb8(%ebp),%esi
40000b20:	8b bd b4 fe ff ff    	mov    0xfffffeb4(%ebp),%edi
40000b26:	8b 8d b0 fe ff ff    	mov    0xfffffeb0(%ebp),%ecx
40000b2c:	cd 30                	int    $0x30
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
40000b2e:	b8 03 00 00 00       	mov    $0x3,%eax
40000b33:	cd 30                	int    $0x30
40000b35:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40000b3c:	00 
40000b3d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000b44:	00 
40000b45:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000b4c:	e8 9f f6 ff ff       	call   400001f0 <join>
	getfaulttest(0);
40000b51:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000b58:	00 
40000b59:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000b60:	e8 ab f5 ff ff       	call   40000110 <fork>
40000b65:	85 c0                	test   %eax,%eax
40000b67:	75 6c                	jne    40000bd5 <protcheck+0x458>
40000b69:	c7 85 dc fe ff ff 00 	movl   $0x1000,0xfffffedc(%ebp)
40000b70:	10 00 00 
40000b73:	66 c7 85 da fe ff ff 	movw   $0x0,0xfffffeda(%ebp)
40000b7a:	00 00 
40000b7c:	c7 85 d4 fe ff ff 00 	movl   $0x0,0xfffffed4(%ebp)
40000b83:	00 00 00 
40000b86:	c7 85 d0 fe ff ff 00 	movl   $0x0,0xfffffed0(%ebp)
40000b8d:	00 00 00 
40000b90:	c7 85 cc fe ff ff 00 	movl   $0x0,0xfffffecc(%ebp)
40000b97:	00 00 00 
40000b9a:	c7 85 c8 fe ff ff 00 	movl   $0x0,0xfffffec8(%ebp)
40000ba1:	00 00 00 
static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40000ba4:	8b 85 dc fe ff ff    	mov    0xfffffedc(%ebp),%eax
40000baa:	83 c8 02             	or     $0x2,%eax
40000bad:	8b 9d d4 fe ff ff    	mov    0xfffffed4(%ebp),%ebx
40000bb3:	0f b7 95 da fe ff ff 	movzwl 0xfffffeda(%ebp),%edx
40000bba:	8b b5 d0 fe ff ff    	mov    0xfffffed0(%ebp),%esi
40000bc0:	8b bd cc fe ff ff    	mov    0xfffffecc(%ebp),%edi
40000bc6:	8b 8d c8 fe ff ff    	mov    0xfffffec8(%ebp),%ecx
40000bcc:	cd 30                	int    $0x30
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
40000bce:	b8 03 00 00 00       	mov    $0x3,%eax
40000bd3:	cd 30                	int    $0x30
40000bd5:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40000bdc:	00 
40000bdd:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000be4:	00 
40000be5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000bec:	e8 ff f5 ff ff       	call   400001f0 <join>
	getfaulttest(VM_USERLO-1);
40000bf1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000bf8:	00 
40000bf9:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000c00:	e8 0b f5 ff ff       	call   40000110 <fork>
40000c05:	85 c0                	test   %eax,%eax
40000c07:	75 6c                	jne    40000c75 <protcheck+0x4f8>
40000c09:	c7 85 f4 fe ff ff 00 	movl   $0x1000,0xfffffef4(%ebp)
40000c10:	10 00 00 
40000c13:	66 c7 85 f2 fe ff ff 	movw   $0x0,0xfffffef2(%ebp)
40000c1a:	00 00 
40000c1c:	c7 85 ec fe ff ff ff 	movl   $0x3fffffff,0xfffffeec(%ebp)
40000c23:	ff ff 3f 
40000c26:	c7 85 e8 fe ff ff 00 	movl   $0x0,0xfffffee8(%ebp)
40000c2d:	00 00 00 
40000c30:	c7 85 e4 fe ff ff 00 	movl   $0x0,0xfffffee4(%ebp)
40000c37:	00 00 00 
40000c3a:	c7 85 e0 fe ff ff 00 	movl   $0x0,0xfffffee0(%ebp)
40000c41:	00 00 00 
static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40000c44:	8b 85 f4 fe ff ff    	mov    0xfffffef4(%ebp),%eax
40000c4a:	83 c8 02             	or     $0x2,%eax
40000c4d:	8b 9d ec fe ff ff    	mov    0xfffffeec(%ebp),%ebx
40000c53:	0f b7 95 f2 fe ff ff 	movzwl 0xfffffef2(%ebp),%edx
40000c5a:	8b b5 e8 fe ff ff    	mov    0xfffffee8(%ebp),%esi
40000c60:	8b bd e4 fe ff ff    	mov    0xfffffee4(%ebp),%edi
40000c66:	8b 8d e0 fe ff ff    	mov    0xfffffee0(%ebp),%ecx
40000c6c:	cd 30                	int    $0x30
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
40000c6e:	b8 03 00 00 00       	mov    $0x3,%eax
40000c73:	cd 30                	int    $0x30
40000c75:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40000c7c:	00 
40000c7d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000c84:	00 
40000c85:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000c8c:	e8 5f f5 ff ff       	call   400001f0 <join>
	getfaulttest(VM_USERHI);
40000c91:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000c98:	00 
40000c99:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000ca0:	e8 6b f4 ff ff       	call   40000110 <fork>
40000ca5:	85 c0                	test   %eax,%eax
40000ca7:	75 6c                	jne    40000d15 <protcheck+0x598>
40000ca9:	c7 85 0c ff ff ff 00 	movl   $0x1000,0xffffff0c(%ebp)
40000cb0:	10 00 00 
40000cb3:	66 c7 85 0a ff ff ff 	movw   $0x0,0xffffff0a(%ebp)
40000cba:	00 00 
40000cbc:	c7 85 04 ff ff ff 00 	movl   $0xf0000000,0xffffff04(%ebp)
40000cc3:	00 00 f0 
40000cc6:	c7 85 00 ff ff ff 00 	movl   $0x0,0xffffff00(%ebp)
40000ccd:	00 00 00 
40000cd0:	c7 85 fc fe ff ff 00 	movl   $0x0,0xfffffefc(%ebp)
40000cd7:	00 00 00 
40000cda:	c7 85 f8 fe ff ff 00 	movl   $0x0,0xfffffef8(%ebp)
40000ce1:	00 00 00 
static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40000ce4:	8b 85 0c ff ff ff    	mov    0xffffff0c(%ebp),%eax
40000cea:	83 c8 02             	or     $0x2,%eax
40000ced:	8b 9d 04 ff ff ff    	mov    0xffffff04(%ebp),%ebx
40000cf3:	0f b7 95 0a ff ff ff 	movzwl 0xffffff0a(%ebp),%edx
40000cfa:	8b b5 00 ff ff ff    	mov    0xffffff00(%ebp),%esi
40000d00:	8b bd fc fe ff ff    	mov    0xfffffefc(%ebp),%edi
40000d06:	8b 8d f8 fe ff ff    	mov    0xfffffef8(%ebp),%ecx
40000d0c:	cd 30                	int    $0x30
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
40000d0e:	b8 03 00 00 00       	mov    $0x3,%eax
40000d13:	cd 30                	int    $0x30
40000d15:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40000d1c:	00 
40000d1d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000d24:	00 
40000d25:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000d2c:	e8 bf f4 ff ff       	call   400001f0 <join>
	getfaulttest(~0);
40000d31:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000d38:	00 
40000d39:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000d40:	e8 cb f3 ff ff       	call   40000110 <fork>
40000d45:	85 c0                	test   %eax,%eax
40000d47:	75 6c                	jne    40000db5 <protcheck+0x638>
40000d49:	c7 85 24 ff ff ff 00 	movl   $0x1000,0xffffff24(%ebp)
40000d50:	10 00 00 
40000d53:	66 c7 85 22 ff ff ff 	movw   $0x0,0xffffff22(%ebp)
40000d5a:	00 00 
40000d5c:	c7 85 1c ff ff ff ff 	movl   $0xffffffff,0xffffff1c(%ebp)
40000d63:	ff ff ff 
40000d66:	c7 85 18 ff ff ff 00 	movl   $0x0,0xffffff18(%ebp)
40000d6d:	00 00 00 
40000d70:	c7 85 14 ff ff ff 00 	movl   $0x0,0xffffff14(%ebp)
40000d77:	00 00 00 
40000d7a:	c7 85 10 ff ff ff 00 	movl   $0x0,0xffffff10(%ebp)
40000d81:	00 00 00 
static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40000d84:	8b 85 24 ff ff ff    	mov    0xffffff24(%ebp),%eax
40000d8a:	83 c8 02             	or     $0x2,%eax
40000d8d:	8b 9d 1c ff ff ff    	mov    0xffffff1c(%ebp),%ebx
40000d93:	0f b7 95 22 ff ff ff 	movzwl 0xffffff22(%ebp),%edx
40000d9a:	8b b5 18 ff ff ff    	mov    0xffffff18(%ebp),%esi
40000da0:	8b bd 14 ff ff ff    	mov    0xffffff14(%ebp),%edi
40000da6:	8b 8d 10 ff ff ff    	mov    0xffffff10(%ebp),%ecx
40000dac:	cd 30                	int    $0x30
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
40000dae:	b8 03 00 00 00       	mov    $0x3,%eax
40000db3:	cd 30                	int    $0x30
40000db5:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40000dbc:	00 
40000dbd:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000dc4:	00 
40000dc5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000dcc:	e8 1f f4 ff ff       	call   400001f0 <join>

warn("here");
40000dd1:	c7 44 24 08 e4 3d 00 	movl   $0x40003de4,0x8(%esp)
40000dd8:	40 
40000dd9:	c7 44 24 04 dd 00 00 	movl   $0xdd,0x4(%esp)
40000de0:	00 
40000de1:	c7 04 24 a8 3c 00 40 	movl   $0x40003ca8,(%esp)
40000de8:	e8 25 1e 00 00       	call   40002c12 <debug_warn>
	// Check that unused parts of user space are also inaccessible
	readfaulttest(VM_USERLO+PTSIZE);
40000ded:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000df4:	00 
40000df5:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000dfc:	e8 0f f3 ff ff       	call   40000110 <fork>
40000e01:	85 c0                	test   %eax,%eax
40000e03:	75 0e                	jne    40000e13 <protcheck+0x696>
40000e05:	b8 00 00 40 40       	mov    $0x40400000,%eax
40000e0a:	8b 00                	mov    (%eax),%eax

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40000e0c:	b8 03 00 00 00       	mov    $0x3,%eax
40000e11:	cd 30                	int    $0x30
40000e13:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40000e1a:	00 
40000e1b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000e22:	00 
40000e23:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000e2a:	e8 c1 f3 ff ff       	call   400001f0 <join>
warn("here");
40000e2f:	c7 44 24 08 e4 3d 00 	movl   $0x40003de4,0x8(%esp)
40000e36:	40 
40000e37:	c7 44 24 04 e0 00 00 	movl   $0xe0,0x4(%esp)
40000e3e:	00 
40000e3f:	c7 04 24 a8 3c 00 40 	movl   $0x40003ca8,(%esp)
40000e46:	e8 c7 1d 00 00       	call   40002c12 <debug_warn>
	readfaulttest(VM_USERHI-PTSIZE);
40000e4b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000e52:	00 
40000e53:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000e5a:	e8 b1 f2 ff ff       	call   40000110 <fork>
40000e5f:	85 c0                	test   %eax,%eax
40000e61:	75 0e                	jne    40000e71 <protcheck+0x6f4>
40000e63:	b8 00 00 c0 ef       	mov    $0xefc00000,%eax
40000e68:	8b 00                	mov    (%eax),%eax

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40000e6a:	b8 03 00 00 00       	mov    $0x3,%eax
40000e6f:	cd 30                	int    $0x30
40000e71:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40000e78:	00 
40000e79:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000e80:	00 
40000e81:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000e88:	e8 63 f3 ff ff       	call   400001f0 <join>
warn("here");
40000e8d:	c7 44 24 08 e4 3d 00 	movl   $0x40003de4,0x8(%esp)
40000e94:	40 
40000e95:	c7 44 24 04 e2 00 00 	movl   $0xe2,0x4(%esp)
40000e9c:	00 
40000e9d:	c7 04 24 a8 3c 00 40 	movl   $0x40003ca8,(%esp)
40000ea4:	e8 69 1d 00 00       	call   40002c12 <debug_warn>
	readfaulttest(VM_USERHI-PTSIZE*2);
40000ea9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000eb0:	00 
40000eb1:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000eb8:	e8 53 f2 ff ff       	call   40000110 <fork>
40000ebd:	85 c0                	test   %eax,%eax
40000ebf:	75 0e                	jne    40000ecf <protcheck+0x752>
40000ec1:	b8 00 00 80 ef       	mov    $0xef800000,%eax
40000ec6:	8b 00                	mov    (%eax),%eax

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40000ec8:	b8 03 00 00 00       	mov    $0x3,%eax
40000ecd:	cd 30                	int    $0x30
40000ecf:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40000ed6:	00 
40000ed7:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000ede:	00 
40000edf:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000ee6:	e8 05 f3 ff ff       	call   400001f0 <join>
warn("here");
40000eeb:	c7 44 24 08 e4 3d 00 	movl   $0x40003de4,0x8(%esp)
40000ef2:	40 
40000ef3:	c7 44 24 04 e4 00 00 	movl   $0xe4,0x4(%esp)
40000efa:	00 
40000efb:	c7 04 24 a8 3c 00 40 	movl   $0x40003ca8,(%esp)
40000f02:	e8 0b 1d 00 00       	call   40002c12 <debug_warn>
	cputsfaulttest(VM_USERLO+PTSIZE);
40000f07:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000f0e:	00 
40000f0f:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000f16:	e8 f5 f1 ff ff       	call   40000110 <fork>
40000f1b:	85 c0                	test   %eax,%eax
40000f1d:	75 1e                	jne    40000f3d <protcheck+0x7c0>
40000f1f:	c7 85 28 ff ff ff 00 	movl   $0x40400000,0xffffff28(%ebp)
40000f26:	00 40 40 
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %0" :
40000f29:	b8 00 00 00 00       	mov    $0x0,%eax
40000f2e:	8b 9d 28 ff ff ff    	mov    0xffffff28(%ebp),%ebx
40000f34:	cd 30                	int    $0x30
		: "i" (T_SYSCALL),
		  "a" (SYS_CPUTS),
		  "b" (s)
		: "cc", "memory");
}

static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
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
40000f36:	b8 03 00 00 00       	mov    $0x3,%eax
40000f3b:	cd 30                	int    $0x30
40000f3d:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40000f44:	00 
40000f45:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000f4c:	00 
40000f4d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000f54:	e8 97 f2 ff ff       	call   400001f0 <join>
warn("here");
40000f59:	c7 44 24 08 e4 3d 00 	movl   $0x40003de4,0x8(%esp)
40000f60:	40 
40000f61:	c7 44 24 04 e6 00 00 	movl   $0xe6,0x4(%esp)
40000f68:	00 
40000f69:	c7 04 24 a8 3c 00 40 	movl   $0x40003ca8,(%esp)
40000f70:	e8 9d 1c 00 00       	call   40002c12 <debug_warn>
	cputsfaulttest(VM_USERHI-PTSIZE);
40000f75:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000f7c:	00 
40000f7d:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000f84:	e8 87 f1 ff ff       	call   40000110 <fork>
40000f89:	85 c0                	test   %eax,%eax
40000f8b:	75 1e                	jne    40000fab <protcheck+0x82e>
40000f8d:	c7 85 2c ff ff ff 00 	movl   $0xefc00000,0xffffff2c(%ebp)
40000f94:	00 c0 ef 
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %0" :
40000f97:	b8 00 00 00 00       	mov    $0x0,%eax
40000f9c:	8b 9d 2c ff ff ff    	mov    0xffffff2c(%ebp),%ebx
40000fa2:	cd 30                	int    $0x30
		: "i" (T_SYSCALL),
		  "a" (SYS_CPUTS),
		  "b" (s)
		: "cc", "memory");
}

static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
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
40000fa4:	b8 03 00 00 00       	mov    $0x3,%eax
40000fa9:	cd 30                	int    $0x30
40000fab:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40000fb2:	00 
40000fb3:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000fba:	00 
40000fbb:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000fc2:	e8 29 f2 ff ff       	call   400001f0 <join>
warn("here");
40000fc7:	c7 44 24 08 e4 3d 00 	movl   $0x40003de4,0x8(%esp)
40000fce:	40 
40000fcf:	c7 44 24 04 e8 00 00 	movl   $0xe8,0x4(%esp)
40000fd6:	00 
40000fd7:	c7 04 24 a8 3c 00 40 	movl   $0x40003ca8,(%esp)
40000fde:	e8 2f 1c 00 00       	call   40002c12 <debug_warn>
	cputsfaulttest(VM_USERHI-PTSIZE*2);
40000fe3:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000fea:	00 
40000feb:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000ff2:	e8 19 f1 ff ff       	call   40000110 <fork>
40000ff7:	85 c0                	test   %eax,%eax
40000ff9:	75 1e                	jne    40001019 <protcheck+0x89c>
40000ffb:	c7 85 30 ff ff ff 00 	movl   $0xef800000,0xffffff30(%ebp)
40001002:	00 80 ef 
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %0" :
40001005:	b8 00 00 00 00       	mov    $0x0,%eax
4000100a:	8b 9d 30 ff ff ff    	mov    0xffffff30(%ebp),%ebx
40001010:	cd 30                	int    $0x30
		: "i" (T_SYSCALL),
		  "a" (SYS_CPUTS),
		  "b" (s)
		: "cc", "memory");
}

static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
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
40001012:	b8 03 00 00 00       	mov    $0x3,%eax
40001017:	cd 30                	int    $0x30
40001019:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40001020:	00 
40001021:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001028:	00 
40001029:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40001030:	e8 bb f1 ff ff       	call   400001f0 <join>
warn("here");
40001035:	c7 44 24 08 e4 3d 00 	movl   $0x40003de4,0x8(%esp)
4000103c:	40 
4000103d:	c7 44 24 04 ea 00 00 	movl   $0xea,0x4(%esp)
40001044:	00 
40001045:	c7 04 24 a8 3c 00 40 	movl   $0x40003ca8,(%esp)
4000104c:	e8 c1 1b 00 00       	call   40002c12 <debug_warn>
	putfaulttest(VM_USERLO+PTSIZE);
40001051:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001058:	00 
40001059:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40001060:	e8 ab f0 ff ff       	call   40000110 <fork>
40001065:	85 c0                	test   %eax,%eax
40001067:	75 6c                	jne    400010d5 <protcheck+0x958>
40001069:	c7 85 48 ff ff ff 00 	movl   $0x1000,0xffffff48(%ebp)
40001070:	10 00 00 
40001073:	66 c7 85 46 ff ff ff 	movw   $0x0,0xffffff46(%ebp)
4000107a:	00 00 
4000107c:	c7 85 40 ff ff ff 00 	movl   $0x40400000,0xffffff40(%ebp)
40001083:	00 40 40 
40001086:	c7 85 3c ff ff ff 00 	movl   $0x0,0xffffff3c(%ebp)
4000108d:	00 00 00 
40001090:	c7 85 38 ff ff ff 00 	movl   $0x0,0xffffff38(%ebp)
40001097:	00 00 00 
4000109a:	c7 85 34 ff ff ff 00 	movl   $0x0,0xffffff34(%ebp)
400010a1:	00 00 00 
static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
400010a4:	8b 85 48 ff ff ff    	mov    0xffffff48(%ebp),%eax
400010aa:	83 c8 01             	or     $0x1,%eax
400010ad:	8b 9d 40 ff ff ff    	mov    0xffffff40(%ebp),%ebx
400010b3:	0f b7 95 46 ff ff ff 	movzwl 0xffffff46(%ebp),%edx
400010ba:	8b b5 3c ff ff ff    	mov    0xffffff3c(%ebp),%esi
400010c0:	8b bd 38 ff ff ff    	mov    0xffffff38(%ebp),%edi
400010c6:	8b 8d 34 ff ff ff    	mov    0xffffff34(%ebp),%ecx
400010cc:	cd 30                	int    $0x30
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
400010ce:	b8 03 00 00 00       	mov    $0x3,%eax
400010d3:	cd 30                	int    $0x30
400010d5:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
400010dc:	00 
400010dd:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400010e4:	00 
400010e5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
400010ec:	e8 ff f0 ff ff       	call   400001f0 <join>
warn("here");
400010f1:	c7 44 24 08 e4 3d 00 	movl   $0x40003de4,0x8(%esp)
400010f8:	40 
400010f9:	c7 44 24 04 ec 00 00 	movl   $0xec,0x4(%esp)
40001100:	00 
40001101:	c7 04 24 a8 3c 00 40 	movl   $0x40003ca8,(%esp)
40001108:	e8 05 1b 00 00       	call   40002c12 <debug_warn>
	putfaulttest(VM_USERHI-PTSIZE);
4000110d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001114:	00 
40001115:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
4000111c:	e8 ef ef ff ff       	call   40000110 <fork>
40001121:	85 c0                	test   %eax,%eax
40001123:	75 6c                	jne    40001191 <protcheck+0xa14>
40001125:	c7 85 60 ff ff ff 00 	movl   $0x1000,0xffffff60(%ebp)
4000112c:	10 00 00 
4000112f:	66 c7 85 5e ff ff ff 	movw   $0x0,0xffffff5e(%ebp)
40001136:	00 00 
40001138:	c7 85 58 ff ff ff 00 	movl   $0xefc00000,0xffffff58(%ebp)
4000113f:	00 c0 ef 
40001142:	c7 85 54 ff ff ff 00 	movl   $0x0,0xffffff54(%ebp)
40001149:	00 00 00 
4000114c:	c7 85 50 ff ff ff 00 	movl   $0x0,0xffffff50(%ebp)
40001153:	00 00 00 
40001156:	c7 85 4c ff ff ff 00 	movl   $0x0,0xffffff4c(%ebp)
4000115d:	00 00 00 
static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
40001160:	8b 85 60 ff ff ff    	mov    0xffffff60(%ebp),%eax
40001166:	83 c8 01             	or     $0x1,%eax
40001169:	8b 9d 58 ff ff ff    	mov    0xffffff58(%ebp),%ebx
4000116f:	0f b7 95 5e ff ff ff 	movzwl 0xffffff5e(%ebp),%edx
40001176:	8b b5 54 ff ff ff    	mov    0xffffff54(%ebp),%esi
4000117c:	8b bd 50 ff ff ff    	mov    0xffffff50(%ebp),%edi
40001182:	8b 8d 4c ff ff ff    	mov    0xffffff4c(%ebp),%ecx
40001188:	cd 30                	int    $0x30
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
4000118a:	b8 03 00 00 00       	mov    $0x3,%eax
4000118f:	cd 30                	int    $0x30
40001191:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40001198:	00 
40001199:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400011a0:	00 
400011a1:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
400011a8:	e8 43 f0 ff ff       	call   400001f0 <join>
warn("here");
400011ad:	c7 44 24 08 e4 3d 00 	movl   $0x40003de4,0x8(%esp)
400011b4:	40 
400011b5:	c7 44 24 04 ee 00 00 	movl   $0xee,0x4(%esp)
400011bc:	00 
400011bd:	c7 04 24 a8 3c 00 40 	movl   $0x40003ca8,(%esp)
400011c4:	e8 49 1a 00 00       	call   40002c12 <debug_warn>
	putfaulttest(VM_USERHI-PTSIZE*2);
400011c9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400011d0:	00 
400011d1:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
400011d8:	e8 33 ef ff ff       	call   40000110 <fork>
400011dd:	85 c0                	test   %eax,%eax
400011df:	75 6c                	jne    4000124d <protcheck+0xad0>
400011e1:	c7 85 78 ff ff ff 00 	movl   $0x1000,0xffffff78(%ebp)
400011e8:	10 00 00 
400011eb:	66 c7 85 76 ff ff ff 	movw   $0x0,0xffffff76(%ebp)
400011f2:	00 00 
400011f4:	c7 85 70 ff ff ff 00 	movl   $0xef800000,0xffffff70(%ebp)
400011fb:	00 80 ef 
400011fe:	c7 85 6c ff ff ff 00 	movl   $0x0,0xffffff6c(%ebp)
40001205:	00 00 00 
40001208:	c7 85 68 ff ff ff 00 	movl   $0x0,0xffffff68(%ebp)
4000120f:	00 00 00 
40001212:	c7 85 64 ff ff ff 00 	movl   $0x0,0xffffff64(%ebp)
40001219:	00 00 00 
static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
4000121c:	8b 85 78 ff ff ff    	mov    0xffffff78(%ebp),%eax
40001222:	83 c8 01             	or     $0x1,%eax
40001225:	8b 9d 70 ff ff ff    	mov    0xffffff70(%ebp),%ebx
4000122b:	0f b7 95 76 ff ff ff 	movzwl 0xffffff76(%ebp),%edx
40001232:	8b b5 6c ff ff ff    	mov    0xffffff6c(%ebp),%esi
40001238:	8b bd 68 ff ff ff    	mov    0xffffff68(%ebp),%edi
4000123e:	8b 8d 64 ff ff ff    	mov    0xffffff64(%ebp),%ecx
40001244:	cd 30                	int    $0x30
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
40001246:	b8 03 00 00 00       	mov    $0x3,%eax
4000124b:	cd 30                	int    $0x30
4000124d:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40001254:	00 
40001255:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000125c:	00 
4000125d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40001264:	e8 87 ef ff ff       	call   400001f0 <join>
warn("here");
40001269:	c7 44 24 08 e4 3d 00 	movl   $0x40003de4,0x8(%esp)
40001270:	40 
40001271:	c7 44 24 04 f0 00 00 	movl   $0xf0,0x4(%esp)
40001278:	00 
40001279:	c7 04 24 a8 3c 00 40 	movl   $0x40003ca8,(%esp)
40001280:	e8 8d 19 00 00       	call   40002c12 <debug_warn>
	getfaulttest(VM_USERLO+PTSIZE);
40001285:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000128c:	00 
4000128d:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40001294:	e8 77 ee ff ff       	call   40000110 <fork>
40001299:	85 c0                	test   %eax,%eax
4000129b:	75 4e                	jne    400012eb <protcheck+0xb6e>
4000129d:	c7 45 90 00 10 00 00 	movl   $0x1000,0xffffff90(%ebp)
400012a4:	66 c7 45 8e 00 00    	movw   $0x0,0xffffff8e(%ebp)
400012aa:	c7 45 88 00 00 40 40 	movl   $0x40400000,0xffffff88(%ebp)
400012b1:	c7 45 84 00 00 00 00 	movl   $0x0,0xffffff84(%ebp)
400012b8:	c7 45 80 00 00 00 00 	movl   $0x0,0xffffff80(%ebp)
400012bf:	c7 85 7c ff ff ff 00 	movl   $0x0,0xffffff7c(%ebp)
400012c6:	00 00 00 
static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
400012c9:	8b 45 90             	mov    0xffffff90(%ebp),%eax
400012cc:	83 c8 02             	or     $0x2,%eax
400012cf:	8b 5d 88             	mov    0xffffff88(%ebp),%ebx
400012d2:	0f b7 55 8e          	movzwl 0xffffff8e(%ebp),%edx
400012d6:	8b 75 84             	mov    0xffffff84(%ebp),%esi
400012d9:	8b 7d 80             	mov    0xffffff80(%ebp),%edi
400012dc:	8b 8d 7c ff ff ff    	mov    0xffffff7c(%ebp),%ecx
400012e2:	cd 30                	int    $0x30
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
400012e4:	b8 03 00 00 00       	mov    $0x3,%eax
400012e9:	cd 30                	int    $0x30
400012eb:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
400012f2:	00 
400012f3:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400012fa:	00 
400012fb:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40001302:	e8 e9 ee ff ff       	call   400001f0 <join>
warn("here");
40001307:	c7 44 24 08 e4 3d 00 	movl   $0x40003de4,0x8(%esp)
4000130e:	40 
4000130f:	c7 44 24 04 f2 00 00 	movl   $0xf2,0x4(%esp)
40001316:	00 
40001317:	c7 04 24 a8 3c 00 40 	movl   $0x40003ca8,(%esp)
4000131e:	e8 ef 18 00 00       	call   40002c12 <debug_warn>
	getfaulttest(VM_USERHI-PTSIZE);
40001323:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000132a:	00 
4000132b:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40001332:	e8 d9 ed ff ff       	call   40000110 <fork>
40001337:	85 c0                	test   %eax,%eax
40001339:	75 48                	jne    40001383 <protcheck+0xc06>
4000133b:	c7 45 a8 00 10 00 00 	movl   $0x1000,0xffffffa8(%ebp)
40001342:	66 c7 45 a6 00 00    	movw   $0x0,0xffffffa6(%ebp)
40001348:	c7 45 a0 00 00 c0 ef 	movl   $0xefc00000,0xffffffa0(%ebp)
4000134f:	c7 45 9c 00 00 00 00 	movl   $0x0,0xffffff9c(%ebp)
40001356:	c7 45 98 00 00 00 00 	movl   $0x0,0xffffff98(%ebp)
4000135d:	c7 45 94 00 00 00 00 	movl   $0x0,0xffffff94(%ebp)
static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40001364:	8b 45 a8             	mov    0xffffffa8(%ebp),%eax
40001367:	83 c8 02             	or     $0x2,%eax
4000136a:	8b 5d a0             	mov    0xffffffa0(%ebp),%ebx
4000136d:	0f b7 55 a6          	movzwl 0xffffffa6(%ebp),%edx
40001371:	8b 75 9c             	mov    0xffffff9c(%ebp),%esi
40001374:	8b 7d 98             	mov    0xffffff98(%ebp),%edi
40001377:	8b 4d 94             	mov    0xffffff94(%ebp),%ecx
4000137a:	cd 30                	int    $0x30
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
4000137c:	b8 03 00 00 00       	mov    $0x3,%eax
40001381:	cd 30                	int    $0x30
40001383:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
4000138a:	00 
4000138b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001392:	00 
40001393:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
4000139a:	e8 51 ee ff ff       	call   400001f0 <join>
warn("here");
4000139f:	c7 44 24 08 e4 3d 00 	movl   $0x40003de4,0x8(%esp)
400013a6:	40 
400013a7:	c7 44 24 04 f4 00 00 	movl   $0xf4,0x4(%esp)
400013ae:	00 
400013af:	c7 04 24 a8 3c 00 40 	movl   $0x40003ca8,(%esp)
400013b6:	e8 57 18 00 00       	call   40002c12 <debug_warn>
	getfaulttest(VM_USERHI-PTSIZE*2);
400013bb:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400013c2:	00 
400013c3:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
400013ca:	e8 41 ed ff ff       	call   40000110 <fork>
400013cf:	85 c0                	test   %eax,%eax
400013d1:	75 48                	jne    4000141b <protcheck+0xc9e>
400013d3:	c7 45 c0 00 10 00 00 	movl   $0x1000,0xffffffc0(%ebp)
400013da:	66 c7 45 be 00 00    	movw   $0x0,0xffffffbe(%ebp)
400013e0:	c7 45 b8 00 00 80 ef 	movl   $0xef800000,0xffffffb8(%ebp)
400013e7:	c7 45 b4 00 00 00 00 	movl   $0x0,0xffffffb4(%ebp)
400013ee:	c7 45 b0 00 00 00 00 	movl   $0x0,0xffffffb0(%ebp)
400013f5:	c7 45 ac 00 00 00 00 	movl   $0x0,0xffffffac(%ebp)
static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
400013fc:	8b 45 c0             	mov    0xffffffc0(%ebp),%eax
400013ff:	83 c8 02             	or     $0x2,%eax
40001402:	8b 5d b8             	mov    0xffffffb8(%ebp),%ebx
40001405:	0f b7 55 be          	movzwl 0xffffffbe(%ebp),%edx
40001409:	8b 75 b4             	mov    0xffffffb4(%ebp),%esi
4000140c:	8b 7d b0             	mov    0xffffffb0(%ebp),%edi
4000140f:	8b 4d ac             	mov    0xffffffac(%ebp),%ecx
40001412:	cd 30                	int    $0x30
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
40001414:	b8 03 00 00 00       	mov    $0x3,%eax
40001419:	cd 30                	int    $0x30
4000141b:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40001422:	00 
40001423:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000142a:	00 
4000142b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40001432:	e8 b9 ed ff ff       	call   400001f0 <join>
warn("here");
40001437:	c7 44 24 08 e4 3d 00 	movl   $0x40003de4,0x8(%esp)
4000143e:	40 
4000143f:	c7 44 24 04 f6 00 00 	movl   $0xf6,0x4(%esp)
40001446:	00 
40001447:	c7 04 24 a8 3c 00 40 	movl   $0x40003ca8,(%esp)
4000144e:	e8 bf 17 00 00       	call   40002c12 <debug_warn>

	// Check that our text segment is mapped read-only
	writefaulttest((int)start);
40001453:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000145a:	00 
4000145b:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40001462:	e8 a9 ec ff ff       	call   40000110 <fork>
40001467:	85 c0                	test   %eax,%eax
40001469:	75 1e                	jne    40001489 <protcheck+0xd0c>
4000146b:	b8 00 01 00 40       	mov    $0x40000100,%eax
40001470:	89 85 50 fe ff ff    	mov    %eax,0xfffffe50(%ebp)
40001476:	8b 85 50 fe ff ff    	mov    0xfffffe50(%ebp),%eax
4000147c:	c7 00 ef be ad de    	movl   $0xdeadbeef,(%eax)

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40001482:	b8 03 00 00 00       	mov    $0x3,%eax
40001487:	cd 30                	int    $0x30
40001489:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40001490:	00 
40001491:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001498:	00 
40001499:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
400014a0:	e8 4b ed ff ff       	call   400001f0 <join>
	writefaulttest((int)etext-4);
400014a5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400014ac:	00 
400014ad:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
400014b4:	e8 57 ec ff ff       	call   40000110 <fork>
400014b9:	85 c0                	test   %eax,%eax
400014bb:	75 21                	jne    400014de <protcheck+0xd61>
400014bd:	b8 47 3c 00 40       	mov    $0x40003c47,%eax
400014c2:	83 e8 04             	sub    $0x4,%eax
400014c5:	89 85 54 fe ff ff    	mov    %eax,0xfffffe54(%ebp)
400014cb:	8b 85 54 fe ff ff    	mov    0xfffffe54(%ebp),%eax
400014d1:	c7 00 ef be ad de    	movl   $0xdeadbeef,(%eax)

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
400014d7:	b8 03 00 00 00       	mov    $0x3,%eax
400014dc:	cd 30                	int    $0x30
400014de:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
400014e5:	00 
400014e6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400014ed:	00 
400014ee:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
400014f5:	e8 f6 ec ff ff       	call   400001f0 <join>
	getfaulttest((int)start);
400014fa:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001501:	00 
40001502:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40001509:	e8 02 ec ff ff       	call   40000110 <fork>
4000150e:	85 c0                	test   %eax,%eax
40001510:	75 49                	jne    4000155b <protcheck+0xdde>
40001512:	b8 00 01 00 40       	mov    $0x40000100,%eax
40001517:	c7 45 d8 00 10 00 00 	movl   $0x1000,0xffffffd8(%ebp)
4000151e:	66 c7 45 d6 00 00    	movw   $0x0,0xffffffd6(%ebp)
40001524:	89 45 d0             	mov    %eax,0xffffffd0(%ebp)
40001527:	c7 45 cc 00 00 00 00 	movl   $0x0,0xffffffcc(%ebp)
4000152e:	c7 45 c8 00 00 00 00 	movl   $0x0,0xffffffc8(%ebp)
40001535:	c7 45 c4 00 00 00 00 	movl   $0x0,0xffffffc4(%ebp)
static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
4000153c:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
4000153f:	83 c8 02             	or     $0x2,%eax
40001542:	8b 5d d0             	mov    0xffffffd0(%ebp),%ebx
40001545:	0f b7 55 d6          	movzwl 0xffffffd6(%ebp),%edx
40001549:	8b 75 cc             	mov    0xffffffcc(%ebp),%esi
4000154c:	8b 7d c8             	mov    0xffffffc8(%ebp),%edi
4000154f:	8b 4d c4             	mov    0xffffffc4(%ebp),%ecx
40001552:	cd 30                	int    $0x30
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
40001554:	b8 03 00 00 00       	mov    $0x3,%eax
40001559:	cd 30                	int    $0x30
4000155b:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40001562:	00 
40001563:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000156a:	00 
4000156b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40001572:	e8 79 ec ff ff       	call   400001f0 <join>
	getfaulttest((int)etext-4);
40001577:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000157e:	00 
4000157f:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40001586:	e8 85 eb ff ff       	call   40000110 <fork>
4000158b:	85 c0                	test   %eax,%eax
4000158d:	75 4c                	jne    400015db <protcheck+0xe5e>
4000158f:	b8 47 3c 00 40       	mov    $0x40003c47,%eax
40001594:	83 e8 04             	sub    $0x4,%eax
40001597:	c7 45 f0 00 10 00 00 	movl   $0x1000,0xfffffff0(%ebp)
4000159e:	66 c7 45 ee 00 00    	movw   $0x0,0xffffffee(%ebp)
400015a4:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
400015a7:	c7 45 e4 00 00 00 00 	movl   $0x0,0xffffffe4(%ebp)
400015ae:	c7 45 e0 00 00 00 00 	movl   $0x0,0xffffffe0(%ebp)
400015b5:	c7 45 dc 00 00 00 00 	movl   $0x0,0xffffffdc(%ebp)
static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
400015bc:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
400015bf:	83 c8 02             	or     $0x2,%eax
400015c2:	8b 5d e8             	mov    0xffffffe8(%ebp),%ebx
400015c5:	0f b7 55 ee          	movzwl 0xffffffee(%ebp),%edx
400015c9:	8b 75 e4             	mov    0xffffffe4(%ebp),%esi
400015cc:	8b 7d e0             	mov    0xffffffe0(%ebp),%edi
400015cf:	8b 4d dc             	mov    0xffffffdc(%ebp),%ecx
400015d2:	cd 30                	int    $0x30
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
400015d4:	b8 03 00 00 00       	mov    $0x3,%eax
400015d9:	cd 30                	int    $0x30
400015db:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
400015e2:	00 
400015e3:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400015ea:	00 
400015eb:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
400015f2:	e8 f9 eb ff ff       	call   400001f0 <join>

	cprintf("testvm: protcheck passed\n");
400015f7:	c7 04 24 e9 3d 00 40 	movl   $0x40003de9,(%esp)
400015fe:	e8 5e 18 00 00       	call   40002e61 <cprintf>
}
40001603:	81 c4 bc 01 00 00    	add    $0x1bc,%esp
40001609:	5b                   	pop    %ebx
4000160a:	5e                   	pop    %esi
4000160b:	5f                   	pop    %edi
4000160c:	5d                   	pop    %ebp
4000160d:	c3                   	ret    

4000160e <memopcheck>:

// Test explicit memory management operations
void
memopcheck(void)
{
4000160e:	55                   	push   %ebp
4000160f:	89 e5                	mov    %esp,%ebp
40001611:	57                   	push   %edi
40001612:	56                   	push   %esi
40001613:	53                   	push   %ebx
40001614:	81 ec 5c 02 00 00    	sub    $0x25c,%esp
	// Test page permission changes
	void *va = (void*)VM_USERLO+PTSIZE+PAGESIZE;
4000161a:	c7 85 bc fd ff ff 00 	movl   $0x40401000,0xfffffdbc(%ebp)
40001621:	10 40 40 
	readfaulttest(va);
40001624:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000162b:	00 
4000162c:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40001633:	e8 d8 ea ff ff       	call   40000110 <fork>
40001638:	85 c0                	test   %eax,%eax
4000163a:	75 0f                	jne    4000164b <memopcheck+0x3d>
4000163c:	8b 85 bc fd ff ff    	mov    0xfffffdbc(%ebp),%eax
40001642:	8b 00                	mov    (%eax),%eax

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40001644:	b8 03 00 00 00       	mov    $0x3,%eax
40001649:	cd 30                	int    $0x30
4000164b:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40001652:	00 
40001653:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000165a:	00 
4000165b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40001662:	e8 89 eb ff ff       	call   400001f0 <join>
40001667:	c7 85 f8 fd ff ff 00 	movl   $0x300,0xfffffdf8(%ebp)
4000166e:	03 00 00 
40001671:	66 c7 85 f6 fd ff ff 	movw   $0x0,0xfffffdf6(%ebp)
40001678:	00 00 
4000167a:	c7 85 f0 fd ff ff 00 	movl   $0x0,0xfffffdf0(%ebp)
40001681:	00 00 00 
40001684:	c7 85 ec fd ff ff 00 	movl   $0x0,0xfffffdec(%ebp)
4000168b:	00 00 00 
4000168e:	8b 85 bc fd ff ff    	mov    0xfffffdbc(%ebp),%eax
40001694:	89 85 e8 fd ff ff    	mov    %eax,0xfffffde8(%ebp)
4000169a:	c7 85 e4 fd ff ff 00 	movl   $0x1000,0xfffffde4(%ebp)
400016a1:	10 00 00 
static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
400016a4:	8b 85 f8 fd ff ff    	mov    0xfffffdf8(%ebp),%eax
400016aa:	83 c8 02             	or     $0x2,%eax
400016ad:	8b 9d f0 fd ff ff    	mov    0xfffffdf0(%ebp),%ebx
400016b3:	0f b7 95 f6 fd ff ff 	movzwl 0xfffffdf6(%ebp),%edx
400016ba:	8b b5 ec fd ff ff    	mov    0xfffffdec(%ebp),%esi
400016c0:	8b bd e8 fd ff ff    	mov    0xfffffde8(%ebp),%edi
400016c6:	8b 8d e4 fd ff ff    	mov    0xfffffde4(%ebp),%ecx
400016cc:	cd 30                	int    $0x30
	sys_get(SYS_PERM | SYS_READ, 0, NULL, NULL, va, PAGESIZE);
	assert(*(volatile int*)va == 0);	// should be readable now
400016ce:	8b 85 bc fd ff ff    	mov    0xfffffdbc(%ebp),%eax
400016d4:	8b 00                	mov    (%eax),%eax
400016d6:	85 c0                	test   %eax,%eax
400016d8:	74 24                	je     400016fe <memopcheck+0xf0>
400016da:	c7 44 24 0c 03 3e 00 	movl   $0x40003e03,0xc(%esp)
400016e1:	40 
400016e2:	c7 44 24 08 9b 3d 00 	movl   $0x40003d9b,0x8(%esp)
400016e9:	40 
400016ea:	c7 44 24 04 09 01 00 	movl   $0x109,0x4(%esp)
400016f1:	00 
400016f2:	c7 04 24 a8 3c 00 40 	movl   $0x40003ca8,(%esp)
400016f9:	e8 a6 14 00 00       	call   40002ba4 <debug_panic>
	writefaulttest(va);			// but not writable
400016fe:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001705:	00 
40001706:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
4000170d:	e8 fe e9 ff ff       	call   40000110 <fork>
40001712:	85 c0                	test   %eax,%eax
40001714:	75 1f                	jne    40001735 <memopcheck+0x127>
40001716:	8b 85 bc fd ff ff    	mov    0xfffffdbc(%ebp),%eax
4000171c:	89 85 d0 fd ff ff    	mov    %eax,0xfffffdd0(%ebp)
40001722:	8b 85 d0 fd ff ff    	mov    0xfffffdd0(%ebp),%eax
40001728:	c7 00 ef be ad de    	movl   $0xdeadbeef,(%eax)

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
4000172e:	b8 03 00 00 00       	mov    $0x3,%eax
40001733:	cd 30                	int    $0x30
40001735:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
4000173c:	00 
4000173d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001744:	00 
40001745:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
4000174c:	e8 9f ea ff ff       	call   400001f0 <join>
40001751:	c7 85 10 fe ff ff 00 	movl   $0x700,0xfffffe10(%ebp)
40001758:	07 00 00 
4000175b:	66 c7 85 0e fe ff ff 	movw   $0x0,0xfffffe0e(%ebp)
40001762:	00 00 
40001764:	c7 85 08 fe ff ff 00 	movl   $0x0,0xfffffe08(%ebp)
4000176b:	00 00 00 
4000176e:	c7 85 04 fe ff ff 00 	movl   $0x0,0xfffffe04(%ebp)
40001775:	00 00 00 
40001778:	8b 85 bc fd ff ff    	mov    0xfffffdbc(%ebp),%eax
4000177e:	89 85 00 fe ff ff    	mov    %eax,0xfffffe00(%ebp)
40001784:	c7 85 fc fd ff ff 00 	movl   $0x1000,0xfffffdfc(%ebp)
4000178b:	10 00 00 
static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
4000178e:	8b 85 10 fe ff ff    	mov    0xfffffe10(%ebp),%eax
40001794:	83 c8 02             	or     $0x2,%eax
40001797:	8b 9d 08 fe ff ff    	mov    0xfffffe08(%ebp),%ebx
4000179d:	0f b7 95 0e fe ff ff 	movzwl 0xfffffe0e(%ebp),%edx
400017a4:	8b b5 04 fe ff ff    	mov    0xfffffe04(%ebp),%esi
400017aa:	8b bd 00 fe ff ff    	mov    0xfffffe00(%ebp),%edi
400017b0:	8b 8d fc fd ff ff    	mov    0xfffffdfc(%ebp),%ecx
400017b6:	cd 30                	int    $0x30
	sys_get(SYS_PERM | SYS_READ | SYS_WRITE, 0, NULL, NULL, va, PAGESIZE);
	*(volatile int*)va = 0xdeadbeef;	// should be writable now
400017b8:	8b 85 bc fd ff ff    	mov    0xfffffdbc(%ebp),%eax
400017be:	c7 00 ef be ad de    	movl   $0xdeadbeef,(%eax)
400017c4:	c7 85 28 fe ff ff 00 	movl   $0x100,0xfffffe28(%ebp)
400017cb:	01 00 00 
400017ce:	66 c7 85 26 fe ff ff 	movw   $0x0,0xfffffe26(%ebp)
400017d5:	00 00 
400017d7:	c7 85 20 fe ff ff 00 	movl   $0x0,0xfffffe20(%ebp)
400017de:	00 00 00 
400017e1:	c7 85 1c fe ff ff 00 	movl   $0x0,0xfffffe1c(%ebp)
400017e8:	00 00 00 
400017eb:	8b 85 bc fd ff ff    	mov    0xfffffdbc(%ebp),%eax
400017f1:	89 85 18 fe ff ff    	mov    %eax,0xfffffe18(%ebp)
400017f7:	c7 85 14 fe ff ff 00 	movl   $0x1000,0xfffffe14(%ebp)
400017fe:	10 00 00 
static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40001801:	8b 85 28 fe ff ff    	mov    0xfffffe28(%ebp),%eax
40001807:	83 c8 02             	or     $0x2,%eax
4000180a:	8b 9d 20 fe ff ff    	mov    0xfffffe20(%ebp),%ebx
40001810:	0f b7 95 26 fe ff ff 	movzwl 0xfffffe26(%ebp),%edx
40001817:	8b b5 1c fe ff ff    	mov    0xfffffe1c(%ebp),%esi
4000181d:	8b bd 18 fe ff ff    	mov    0xfffffe18(%ebp),%edi
40001823:	8b 8d 14 fe ff ff    	mov    0xfffffe14(%ebp),%ecx
40001829:	cd 30                	int    $0x30
	sys_get(SYS_PERM, 0, NULL, NULL, va, PAGESIZE);	// revoke all perms
	readfaulttest(va);
4000182b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001832:	00 
40001833:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
4000183a:	e8 d1 e8 ff ff       	call   40000110 <fork>
4000183f:	85 c0                	test   %eax,%eax
40001841:	75 0f                	jne    40001852 <memopcheck+0x244>
40001843:	8b 85 bc fd ff ff    	mov    0xfffffdbc(%ebp),%eax
40001849:	8b 00                	mov    (%eax),%eax

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
4000184b:	b8 03 00 00 00       	mov    $0x3,%eax
40001850:	cd 30                	int    $0x30
40001852:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40001859:	00 
4000185a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001861:	00 
40001862:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40001869:	e8 82 e9 ff ff       	call   400001f0 <join>
4000186e:	c7 85 40 fe ff ff 00 	movl   $0x300,0xfffffe40(%ebp)
40001875:	03 00 00 
40001878:	66 c7 85 3e fe ff ff 	movw   $0x0,0xfffffe3e(%ebp)
4000187f:	00 00 
40001881:	c7 85 38 fe ff ff 00 	movl   $0x0,0xfffffe38(%ebp)
40001888:	00 00 00 
4000188b:	c7 85 34 fe ff ff 00 	movl   $0x0,0xfffffe34(%ebp)
40001892:	00 00 00 
40001895:	8b 85 bc fd ff ff    	mov    0xfffffdbc(%ebp),%eax
4000189b:	89 85 30 fe ff ff    	mov    %eax,0xfffffe30(%ebp)
400018a1:	c7 85 2c fe ff ff 00 	movl   $0x1000,0xfffffe2c(%ebp)
400018a8:	10 00 00 
static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
400018ab:	8b 85 40 fe ff ff    	mov    0xfffffe40(%ebp),%eax
400018b1:	83 c8 02             	or     $0x2,%eax
400018b4:	8b 9d 38 fe ff ff    	mov    0xfffffe38(%ebp),%ebx
400018ba:	0f b7 95 3e fe ff ff 	movzwl 0xfffffe3e(%ebp),%edx
400018c1:	8b b5 34 fe ff ff    	mov    0xfffffe34(%ebp),%esi
400018c7:	8b bd 30 fe ff ff    	mov    0xfffffe30(%ebp),%edi
400018cd:	8b 8d 2c fe ff ff    	mov    0xfffffe2c(%ebp),%ecx
400018d3:	cd 30                	int    $0x30
	sys_get(SYS_PERM | SYS_READ, 0, NULL, NULL, va, PAGESIZE);
	assert(*(volatile int*)va == 0xdeadbeef);	// readable again
400018d5:	8b 85 bc fd ff ff    	mov    0xfffffdbc(%ebp),%eax
400018db:	8b 00                	mov    (%eax),%eax
400018dd:	3d ef be ad de       	cmp    $0xdeadbeef,%eax
400018e2:	74 24                	je     40001908 <memopcheck+0x2fa>
400018e4:	c7 44 24 0c 1c 3e 00 	movl   $0x40003e1c,0xc(%esp)
400018eb:	40 
400018ec:	c7 44 24 08 9b 3d 00 	movl   $0x40003d9b,0x8(%esp)
400018f3:	40 
400018f4:	c7 44 24 04 10 01 00 	movl   $0x110,0x4(%esp)
400018fb:	00 
400018fc:	c7 04 24 a8 3c 00 40 	movl   $0x40003ca8,(%esp)
40001903:	e8 9c 12 00 00       	call   40002ba4 <debug_panic>
	writefaulttest(va);				// but not writable
40001908:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000190f:	00 
40001910:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40001917:	e8 f4 e7 ff ff       	call   40000110 <fork>
4000191c:	85 c0                	test   %eax,%eax
4000191e:	75 1f                	jne    4000193f <memopcheck+0x331>
40001920:	8b 85 bc fd ff ff    	mov    0xfffffdbc(%ebp),%eax
40001926:	89 85 d4 fd ff ff    	mov    %eax,0xfffffdd4(%ebp)
4000192c:	8b 85 d4 fd ff ff    	mov    0xfffffdd4(%ebp),%eax
40001932:	c7 00 ef be ad de    	movl   $0xdeadbeef,(%eax)

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40001938:	b8 03 00 00 00       	mov    $0x3,%eax
4000193d:	cd 30                	int    $0x30
4000193f:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40001946:	00 
40001947:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000194e:	00 
4000194f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40001956:	e8 95 e8 ff ff       	call   400001f0 <join>
4000195b:	c7 85 58 fe ff ff 00 	movl   $0x700,0xfffffe58(%ebp)
40001962:	07 00 00 
40001965:	66 c7 85 56 fe ff ff 	movw   $0x0,0xfffffe56(%ebp)
4000196c:	00 00 
4000196e:	c7 85 50 fe ff ff 00 	movl   $0x0,0xfffffe50(%ebp)
40001975:	00 00 00 
40001978:	c7 85 4c fe ff ff 00 	movl   $0x0,0xfffffe4c(%ebp)
4000197f:	00 00 00 
40001982:	8b 85 bc fd ff ff    	mov    0xfffffdbc(%ebp),%eax
40001988:	89 85 48 fe ff ff    	mov    %eax,0xfffffe48(%ebp)
4000198e:	c7 85 44 fe ff ff 00 	movl   $0x1000,0xfffffe44(%ebp)
40001995:	10 00 00 
static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40001998:	8b 85 58 fe ff ff    	mov    0xfffffe58(%ebp),%eax
4000199e:	83 c8 02             	or     $0x2,%eax
400019a1:	8b 9d 50 fe ff ff    	mov    0xfffffe50(%ebp),%ebx
400019a7:	0f b7 95 56 fe ff ff 	movzwl 0xfffffe56(%ebp),%edx
400019ae:	8b b5 4c fe ff ff    	mov    0xfffffe4c(%ebp),%esi
400019b4:	8b bd 48 fe ff ff    	mov    0xfffffe48(%ebp),%edi
400019ba:	8b 8d 44 fe ff ff    	mov    0xfffffe44(%ebp),%ecx
400019c0:	cd 30                	int    $0x30
	sys_get(SYS_PERM | SYS_READ | SYS_WRITE, 0, NULL, NULL, va, PAGESIZE);

	// Test SYS_ZERO with SYS_GET
	va = (void*)VM_USERLO+PTSIZE;	// 4MB-aligned
400019c2:	c7 85 bc fd ff ff 00 	movl   $0x40400000,0xfffffdbc(%ebp)
400019c9:	00 40 40 
400019cc:	c7 85 70 fe ff ff 00 	movl   $0x10000,0xfffffe70(%ebp)
400019d3:	00 01 00 
400019d6:	66 c7 85 6e fe ff ff 	movw   $0x0,0xfffffe6e(%ebp)
400019dd:	00 00 
400019df:	c7 85 68 fe ff ff 00 	movl   $0x0,0xfffffe68(%ebp)
400019e6:	00 00 00 
400019e9:	c7 85 64 fe ff ff 00 	movl   $0x0,0xfffffe64(%ebp)
400019f0:	00 00 00 
400019f3:	8b 85 bc fd ff ff    	mov    0xfffffdbc(%ebp),%eax
400019f9:	89 85 60 fe ff ff    	mov    %eax,0xfffffe60(%ebp)
400019ff:	c7 85 5c fe ff ff 00 	movl   $0x400000,0xfffffe5c(%ebp)
40001a06:	00 40 00 
static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40001a09:	8b 85 70 fe ff ff    	mov    0xfffffe70(%ebp),%eax
40001a0f:	83 c8 02             	or     $0x2,%eax
40001a12:	8b 9d 68 fe ff ff    	mov    0xfffffe68(%ebp),%ebx
40001a18:	0f b7 95 6e fe ff ff 	movzwl 0xfffffe6e(%ebp),%edx
40001a1f:	8b b5 64 fe ff ff    	mov    0xfffffe64(%ebp),%esi
40001a25:	8b bd 60 fe ff ff    	mov    0xfffffe60(%ebp),%edi
40001a2b:	8b 8d 5c fe ff ff    	mov    0xfffffe5c(%ebp),%ecx
40001a31:	cd 30                	int    $0x30
	sys_get(SYS_ZERO, 0, NULL, NULL, va, PTSIZE);
	readfaulttest(va);		// should be inaccessible again
40001a33:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001a3a:	00 
40001a3b:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40001a42:	e8 c9 e6 ff ff       	call   40000110 <fork>
40001a47:	85 c0                	test   %eax,%eax
40001a49:	75 0f                	jne    40001a5a <memopcheck+0x44c>
40001a4b:	8b 85 bc fd ff ff    	mov    0xfffffdbc(%ebp),%eax
40001a51:	8b 00                	mov    (%eax),%eax

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40001a53:	b8 03 00 00 00       	mov    $0x3,%eax
40001a58:	cd 30                	int    $0x30
40001a5a:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40001a61:	00 
40001a62:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001a69:	00 
40001a6a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40001a71:	e8 7a e7 ff ff       	call   400001f0 <join>
40001a76:	c7 85 88 fe ff ff 00 	movl   $0x300,0xfffffe88(%ebp)
40001a7d:	03 00 00 
40001a80:	66 c7 85 86 fe ff ff 	movw   $0x0,0xfffffe86(%ebp)
40001a87:	00 00 
40001a89:	c7 85 80 fe ff ff 00 	movl   $0x0,0xfffffe80(%ebp)
40001a90:	00 00 00 
40001a93:	c7 85 7c fe ff ff 00 	movl   $0x0,0xfffffe7c(%ebp)
40001a9a:	00 00 00 
40001a9d:	8b 85 bc fd ff ff    	mov    0xfffffdbc(%ebp),%eax
40001aa3:	89 85 78 fe ff ff    	mov    %eax,0xfffffe78(%ebp)
40001aa9:	c7 85 74 fe ff ff 00 	movl   $0x1000,0xfffffe74(%ebp)
40001ab0:	10 00 00 
static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40001ab3:	8b 85 88 fe ff ff    	mov    0xfffffe88(%ebp),%eax
40001ab9:	83 c8 02             	or     $0x2,%eax
40001abc:	8b 9d 80 fe ff ff    	mov    0xfffffe80(%ebp),%ebx
40001ac2:	0f b7 95 86 fe ff ff 	movzwl 0xfffffe86(%ebp),%edx
40001ac9:	8b b5 7c fe ff ff    	mov    0xfffffe7c(%ebp),%esi
40001acf:	8b bd 78 fe ff ff    	mov    0xfffffe78(%ebp),%edi
40001ad5:	8b 8d 74 fe ff ff    	mov    0xfffffe74(%ebp),%ecx
40001adb:	cd 30                	int    $0x30
	sys_get(SYS_PERM | SYS_READ, 0, NULL, NULL, va, PAGESIZE);
	assert(*(volatile int*)va == 0);	// and zeroed
40001add:	8b 85 bc fd ff ff    	mov    0xfffffdbc(%ebp),%eax
40001ae3:	8b 00                	mov    (%eax),%eax
40001ae5:	85 c0                	test   %eax,%eax
40001ae7:	74 24                	je     40001b0d <memopcheck+0x4ff>
40001ae9:	c7 44 24 0c 03 3e 00 	movl   $0x40003e03,0xc(%esp)
40001af0:	40 
40001af1:	c7 44 24 08 9b 3d 00 	movl   $0x40003d9b,0x8(%esp)
40001af8:	40 
40001af9:	c7 44 24 04 19 01 00 	movl   $0x119,0x4(%esp)
40001b00:	00 
40001b01:	c7 04 24 a8 3c 00 40 	movl   $0x40003ca8,(%esp)
40001b08:	e8 97 10 00 00       	call   40002ba4 <debug_panic>
	writefaulttest(va);			// but not writable
40001b0d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001b14:	00 
40001b15:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40001b1c:	e8 ef e5 ff ff       	call   40000110 <fork>
40001b21:	85 c0                	test   %eax,%eax
40001b23:	75 1f                	jne    40001b44 <memopcheck+0x536>
40001b25:	8b 85 bc fd ff ff    	mov    0xfffffdbc(%ebp),%eax
40001b2b:	89 85 d8 fd ff ff    	mov    %eax,0xfffffdd8(%ebp)
40001b31:	8b 85 d8 fd ff ff    	mov    0xfffffdd8(%ebp),%eax
40001b37:	c7 00 ef be ad de    	movl   $0xdeadbeef,(%eax)

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40001b3d:	b8 03 00 00 00       	mov    $0x3,%eax
40001b42:	cd 30                	int    $0x30
40001b44:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40001b4b:	00 
40001b4c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001b53:	00 
40001b54:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40001b5b:	e8 90 e6 ff ff       	call   400001f0 <join>
40001b60:	c7 85 a0 fe ff ff 00 	movl   $0x10000,0xfffffea0(%ebp)
40001b67:	00 01 00 
40001b6a:	66 c7 85 9e fe ff ff 	movw   $0x0,0xfffffe9e(%ebp)
40001b71:	00 00 
40001b73:	c7 85 98 fe ff ff 00 	movl   $0x0,0xfffffe98(%ebp)
40001b7a:	00 00 00 
40001b7d:	c7 85 94 fe ff ff 00 	movl   $0x0,0xfffffe94(%ebp)
40001b84:	00 00 00 
40001b87:	8b 85 bc fd ff ff    	mov    0xfffffdbc(%ebp),%eax
40001b8d:	89 85 90 fe ff ff    	mov    %eax,0xfffffe90(%ebp)
40001b93:	c7 85 8c fe ff ff 00 	movl   $0x400000,0xfffffe8c(%ebp)
40001b9a:	00 40 00 
static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40001b9d:	8b 85 a0 fe ff ff    	mov    0xfffffea0(%ebp),%eax
40001ba3:	83 c8 02             	or     $0x2,%eax
40001ba6:	8b 9d 98 fe ff ff    	mov    0xfffffe98(%ebp),%ebx
40001bac:	0f b7 95 9e fe ff ff 	movzwl 0xfffffe9e(%ebp),%edx
40001bb3:	8b b5 94 fe ff ff    	mov    0xfffffe94(%ebp),%esi
40001bb9:	8b bd 90 fe ff ff    	mov    0xfffffe90(%ebp),%edi
40001bbf:	8b 8d 8c fe ff ff    	mov    0xfffffe8c(%ebp),%ecx
40001bc5:	cd 30                	int    $0x30
	sys_get(SYS_ZERO, 0, NULL, NULL, va, PTSIZE);
	readfaulttest(va);			// gone again
40001bc7:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001bce:	00 
40001bcf:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40001bd6:	e8 35 e5 ff ff       	call   40000110 <fork>
40001bdb:	85 c0                	test   %eax,%eax
40001bdd:	75 0f                	jne    40001bee <memopcheck+0x5e0>
40001bdf:	8b 85 bc fd ff ff    	mov    0xfffffdbc(%ebp),%eax
40001be5:	8b 00                	mov    (%eax),%eax

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40001be7:	b8 03 00 00 00       	mov    $0x3,%eax
40001bec:	cd 30                	int    $0x30
40001bee:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40001bf5:	00 
40001bf6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001bfd:	00 
40001bfe:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40001c05:	e8 e6 e5 ff ff       	call   400001f0 <join>
40001c0a:	c7 85 b8 fe ff ff 00 	movl   $0x700,0xfffffeb8(%ebp)
40001c11:	07 00 00 
40001c14:	66 c7 85 b6 fe ff ff 	movw   $0x0,0xfffffeb6(%ebp)
40001c1b:	00 00 
40001c1d:	c7 85 b0 fe ff ff 00 	movl   $0x0,0xfffffeb0(%ebp)
40001c24:	00 00 00 
40001c27:	c7 85 ac fe ff ff 00 	movl   $0x0,0xfffffeac(%ebp)
40001c2e:	00 00 00 
40001c31:	8b 85 bc fd ff ff    	mov    0xfffffdbc(%ebp),%eax
40001c37:	89 85 a8 fe ff ff    	mov    %eax,0xfffffea8(%ebp)
40001c3d:	c7 85 a4 fe ff ff 00 	movl   $0x1000,0xfffffea4(%ebp)
40001c44:	10 00 00 
static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40001c47:	8b 85 b8 fe ff ff    	mov    0xfffffeb8(%ebp),%eax
40001c4d:	83 c8 02             	or     $0x2,%eax
40001c50:	8b 9d b0 fe ff ff    	mov    0xfffffeb0(%ebp),%ebx
40001c56:	0f b7 95 b6 fe ff ff 	movzwl 0xfffffeb6(%ebp),%edx
40001c5d:	8b b5 ac fe ff ff    	mov    0xfffffeac(%ebp),%esi
40001c63:	8b bd a8 fe ff ff    	mov    0xfffffea8(%ebp),%edi
40001c69:	8b 8d a4 fe ff ff    	mov    0xfffffea4(%ebp),%ecx
40001c6f:	cd 30                	int    $0x30
	sys_get(SYS_PERM | SYS_READ | SYS_WRITE, 0, NULL, NULL, va, PAGESIZE);
	*(volatile int*)va = 0xdeadbeef;	// writable now
40001c71:	8b 85 bc fd ff ff    	mov    0xfffffdbc(%ebp),%eax
40001c77:	c7 00 ef be ad de    	movl   $0xdeadbeef,(%eax)
40001c7d:	c7 85 d0 fe ff ff 00 	movl   $0x10000,0xfffffed0(%ebp)
40001c84:	00 01 00 
40001c87:	66 c7 85 ce fe ff ff 	movw   $0x0,0xfffffece(%ebp)
40001c8e:	00 00 
40001c90:	c7 85 c8 fe ff ff 00 	movl   $0x0,0xfffffec8(%ebp)
40001c97:	00 00 00 
40001c9a:	c7 85 c4 fe ff ff 00 	movl   $0x0,0xfffffec4(%ebp)
40001ca1:	00 00 00 
40001ca4:	8b 85 bc fd ff ff    	mov    0xfffffdbc(%ebp),%eax
40001caa:	89 85 c0 fe ff ff    	mov    %eax,0xfffffec0(%ebp)
40001cb0:	c7 85 bc fe ff ff 00 	movl   $0x400000,0xfffffebc(%ebp)
40001cb7:	00 40 00 
static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40001cba:	8b 85 d0 fe ff ff    	mov    0xfffffed0(%ebp),%eax
40001cc0:	83 c8 02             	or     $0x2,%eax
40001cc3:	8b 9d c8 fe ff ff    	mov    0xfffffec8(%ebp),%ebx
40001cc9:	0f b7 95 ce fe ff ff 	movzwl 0xfffffece(%ebp),%edx
40001cd0:	8b b5 c4 fe ff ff    	mov    0xfffffec4(%ebp),%esi
40001cd6:	8b bd c0 fe ff ff    	mov    0xfffffec0(%ebp),%edi
40001cdc:	8b 8d bc fe ff ff    	mov    0xfffffebc(%ebp),%ecx
40001ce2:	cd 30                	int    $0x30
	sys_get(SYS_ZERO, 0, NULL, NULL, va, PTSIZE);
	readfaulttest(va);			// gone again
40001ce4:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001ceb:	00 
40001cec:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40001cf3:	e8 18 e4 ff ff       	call   40000110 <fork>
40001cf8:	85 c0                	test   %eax,%eax
40001cfa:	75 0f                	jne    40001d0b <memopcheck+0x6fd>
40001cfc:	8b 85 bc fd ff ff    	mov    0xfffffdbc(%ebp),%eax
40001d02:	8b 00                	mov    (%eax),%eax

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40001d04:	b8 03 00 00 00       	mov    $0x3,%eax
40001d09:	cd 30                	int    $0x30
40001d0b:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40001d12:	00 
40001d13:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001d1a:	00 
40001d1b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40001d22:	e8 c9 e4 ff ff       	call   400001f0 <join>
40001d27:	c7 85 e8 fe ff ff 00 	movl   $0x300,0xfffffee8(%ebp)
40001d2e:	03 00 00 
40001d31:	66 c7 85 e6 fe ff ff 	movw   $0x0,0xfffffee6(%ebp)
40001d38:	00 00 
40001d3a:	c7 85 e0 fe ff ff 00 	movl   $0x0,0xfffffee0(%ebp)
40001d41:	00 00 00 
40001d44:	c7 85 dc fe ff ff 00 	movl   $0x0,0xfffffedc(%ebp)
40001d4b:	00 00 00 
40001d4e:	8b 85 bc fd ff ff    	mov    0xfffffdbc(%ebp),%eax
40001d54:	89 85 d8 fe ff ff    	mov    %eax,0xfffffed8(%ebp)
40001d5a:	c7 85 d4 fe ff ff 00 	movl   $0x1000,0xfffffed4(%ebp)
40001d61:	10 00 00 
static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40001d64:	8b 85 e8 fe ff ff    	mov    0xfffffee8(%ebp),%eax
40001d6a:	83 c8 02             	or     $0x2,%eax
40001d6d:	8b 9d e0 fe ff ff    	mov    0xfffffee0(%ebp),%ebx
40001d73:	0f b7 95 e6 fe ff ff 	movzwl 0xfffffee6(%ebp),%edx
40001d7a:	8b b5 dc fe ff ff    	mov    0xfffffedc(%ebp),%esi
40001d80:	8b bd d8 fe ff ff    	mov    0xfffffed8(%ebp),%edi
40001d86:	8b 8d d4 fe ff ff    	mov    0xfffffed4(%ebp),%ecx
40001d8c:	cd 30                	int    $0x30
	sys_get(SYS_PERM | SYS_READ, 0, NULL, NULL, va, PAGESIZE);
	assert(*(volatile int*)va == 0);	// and zeroed
40001d8e:	8b 85 bc fd ff ff    	mov    0xfffffdbc(%ebp),%eax
40001d94:	8b 00                	mov    (%eax),%eax
40001d96:	85 c0                	test   %eax,%eax
40001d98:	74 24                	je     40001dbe <memopcheck+0x7b0>
40001d9a:	c7 44 24 0c 03 3e 00 	movl   $0x40003e03,0xc(%esp)
40001da1:	40 
40001da2:	c7 44 24 08 9b 3d 00 	movl   $0x40003d9b,0x8(%esp)
40001da9:	40 
40001daa:	c7 44 24 04 22 01 00 	movl   $0x122,0x4(%esp)
40001db1:	00 
40001db2:	c7 04 24 a8 3c 00 40 	movl   $0x40003ca8,(%esp)
40001db9:	e8 e6 0d 00 00       	call   40002ba4 <debug_panic>

	// Test SYS_COPY with SYS_GET - pull residual stuff out of child 0
	void *sva = (void*)VM_USERLO;
40001dbe:	c7 85 c0 fd ff ff 00 	movl   $0x40000000,0xfffffdc0(%ebp)
40001dc5:	00 00 40 
	void *dva = (void*)VM_USERLO+PTSIZE;
40001dc8:	c7 85 c4 fd ff ff 00 	movl   $0x40400000,0xfffffdc4(%ebp)
40001dcf:	00 40 40 
40001dd2:	c7 85 00 ff ff ff 00 	movl   $0x20000,0xffffff00(%ebp)
40001dd9:	00 02 00 
40001ddc:	66 c7 85 fe fe ff ff 	movw   $0x0,0xfffffefe(%ebp)
40001de3:	00 00 
40001de5:	c7 85 f8 fe ff ff 00 	movl   $0x0,0xfffffef8(%ebp)
40001dec:	00 00 00 
40001def:	8b 85 c0 fd ff ff    	mov    0xfffffdc0(%ebp),%eax
40001df5:	89 85 f4 fe ff ff    	mov    %eax,0xfffffef4(%ebp)
40001dfb:	8b 85 c4 fd ff ff    	mov    0xfffffdc4(%ebp),%eax
40001e01:	89 85 f0 fe ff ff    	mov    %eax,0xfffffef0(%ebp)
40001e07:	c7 85 ec fe ff ff 00 	movl   $0x400000,0xfffffeec(%ebp)
40001e0e:	00 40 00 
static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40001e11:	8b 85 00 ff ff ff    	mov    0xffffff00(%ebp),%eax
40001e17:	83 c8 02             	or     $0x2,%eax
40001e1a:	8b 9d f8 fe ff ff    	mov    0xfffffef8(%ebp),%ebx
40001e20:	0f b7 95 fe fe ff ff 	movzwl 0xfffffefe(%ebp),%edx
40001e27:	8b b5 f4 fe ff ff    	mov    0xfffffef4(%ebp),%esi
40001e2d:	8b bd f0 fe ff ff    	mov    0xfffffef0(%ebp),%edi
40001e33:	8b 8d ec fe ff ff    	mov    0xfffffeec(%ebp),%ecx
40001e39:	cd 30                	int    $0x30
	sys_get(SYS_COPY, 0, NULL, sva, dva, PTSIZE);
	assert(memcmp(sva, dva, etext - start) == 0);
40001e3b:	ba 47 3c 00 40       	mov    $0x40003c47,%edx
40001e40:	b8 00 01 00 40       	mov    $0x40000100,%eax
40001e45:	89 d1                	mov    %edx,%ecx
40001e47:	29 c1                	sub    %eax,%ecx
40001e49:	89 c8                	mov    %ecx,%eax
40001e4b:	89 44 24 08          	mov    %eax,0x8(%esp)
40001e4f:	8b 85 c4 fd ff ff    	mov    0xfffffdc4(%ebp),%eax
40001e55:	89 44 24 04          	mov    %eax,0x4(%esp)
40001e59:	8b 85 c0 fd ff ff    	mov    0xfffffdc0(%ebp),%eax
40001e5f:	89 04 24             	mov    %eax,(%esp)
40001e62:	e8 62 1a 00 00       	call   400038c9 <memcmp>
40001e67:	85 c0                	test   %eax,%eax
40001e69:	74 24                	je     40001e8f <memopcheck+0x881>
40001e6b:	c7 44 24 0c 40 3e 00 	movl   $0x40003e40,0xc(%esp)
40001e72:	40 
40001e73:	c7 44 24 08 9b 3d 00 	movl   $0x40003d9b,0x8(%esp)
40001e7a:	40 
40001e7b:	c7 44 24 04 28 01 00 	movl   $0x128,0x4(%esp)
40001e82:	00 
40001e83:	c7 04 24 a8 3c 00 40 	movl   $0x40003ca8,(%esp)
40001e8a:	e8 15 0d 00 00       	call   40002ba4 <debug_panic>
	writefaulttest(dva);
40001e8f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001e96:	00 
40001e97:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40001e9e:	e8 6d e2 ff ff       	call   40000110 <fork>
40001ea3:	85 c0                	test   %eax,%eax
40001ea5:	75 1f                	jne    40001ec6 <memopcheck+0x8b8>
40001ea7:	8b 85 c4 fd ff ff    	mov    0xfffffdc4(%ebp),%eax
40001ead:	89 85 dc fd ff ff    	mov    %eax,0xfffffddc(%ebp)
40001eb3:	8b 85 dc fd ff ff    	mov    0xfffffddc(%ebp),%eax
40001eb9:	c7 00 ef be ad de    	movl   $0xdeadbeef,(%eax)

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40001ebf:	b8 03 00 00 00       	mov    $0x3,%eax
40001ec4:	cd 30                	int    $0x30
40001ec6:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40001ecd:	00 
40001ece:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001ed5:	00 
40001ed6:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40001edd:	e8 0e e3 ff ff       	call   400001f0 <join>
	readfaulttest(dva + PTSIZE-4);
40001ee2:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001ee9:	00 
40001eea:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40001ef1:	e8 1a e2 ff ff       	call   40000110 <fork>
40001ef6:	85 c0                	test   %eax,%eax
40001ef8:	75 14                	jne    40001f0e <memopcheck+0x900>
40001efa:	8b 85 c4 fd ff ff    	mov    0xfffffdc4(%ebp),%eax
40001f00:	05 fc ff 3f 00       	add    $0x3ffffc,%eax
40001f05:	8b 00                	mov    (%eax),%eax

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40001f07:	b8 03 00 00 00       	mov    $0x3,%eax
40001f0c:	cd 30                	int    $0x30
40001f0e:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40001f15:	00 
40001f16:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001f1d:	00 
40001f1e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40001f25:	e8 c6 e2 ff ff       	call   400001f0 <join>

	// Test SYS_ZERO with SYS_PUT
	void *dva2 = (void*)VM_USERLO+PTSIZE*2;
40001f2a:	c7 85 c8 fd ff ff 00 	movl   $0x40800000,0xfffffdc8(%ebp)
40001f31:	00 80 40 
40001f34:	c7 85 18 ff ff ff 00 	movl   $0x10000,0xffffff18(%ebp)
40001f3b:	00 01 00 
40001f3e:	66 c7 85 16 ff ff ff 	movw   $0x0,0xffffff16(%ebp)
40001f45:	00 00 
40001f47:	c7 85 10 ff ff ff 00 	movl   $0x0,0xffffff10(%ebp)
40001f4e:	00 00 00 
40001f51:	c7 85 0c ff ff ff 00 	movl   $0x0,0xffffff0c(%ebp)
40001f58:	00 00 00 
40001f5b:	8b 85 c4 fd ff ff    	mov    0xfffffdc4(%ebp),%eax
40001f61:	89 85 08 ff ff ff    	mov    %eax,0xffffff08(%ebp)
40001f67:	c7 85 04 ff ff ff 00 	movl   $0x400000,0xffffff04(%ebp)
40001f6e:	00 40 00 
static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
40001f71:	8b 85 18 ff ff ff    	mov    0xffffff18(%ebp),%eax
40001f77:	83 c8 01             	or     $0x1,%eax
40001f7a:	8b 9d 10 ff ff ff    	mov    0xffffff10(%ebp),%ebx
40001f80:	0f b7 95 16 ff ff ff 	movzwl 0xffffff16(%ebp),%edx
40001f87:	8b b5 0c ff ff ff    	mov    0xffffff0c(%ebp),%esi
40001f8d:	8b bd 08 ff ff ff    	mov    0xffffff08(%ebp),%edi
40001f93:	8b 8d 04 ff ff ff    	mov    0xffffff04(%ebp),%ecx
40001f99:	cd 30                	int    $0x30
40001f9b:	c7 85 30 ff ff ff 00 	movl   $0x20000,0xffffff30(%ebp)
40001fa2:	00 02 00 
40001fa5:	66 c7 85 2e ff ff ff 	movw   $0x0,0xffffff2e(%ebp)
40001fac:	00 00 
40001fae:	c7 85 28 ff ff ff 00 	movl   $0x0,0xffffff28(%ebp)
40001fb5:	00 00 00 
40001fb8:	8b 85 c4 fd ff ff    	mov    0xfffffdc4(%ebp),%eax
40001fbe:	89 85 24 ff ff ff    	mov    %eax,0xffffff24(%ebp)
40001fc4:	8b 85 c8 fd ff ff    	mov    0xfffffdc8(%ebp),%eax
40001fca:	89 85 20 ff ff ff    	mov    %eax,0xffffff20(%ebp)
40001fd0:	c7 85 1c ff ff ff 00 	movl   $0x400000,0xffffff1c(%ebp)
40001fd7:	00 40 00 
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
40001fda:	8b 85 30 ff ff ff    	mov    0xffffff30(%ebp),%eax
40001fe0:	83 c8 02             	or     $0x2,%eax
40001fe3:	8b 9d 28 ff ff ff    	mov    0xffffff28(%ebp),%ebx
40001fe9:	0f b7 95 2e ff ff ff 	movzwl 0xffffff2e(%ebp),%edx
40001ff0:	8b b5 24 ff ff ff    	mov    0xffffff24(%ebp),%esi
40001ff6:	8b bd 20 ff ff ff    	mov    0xffffff20(%ebp),%edi
40001ffc:	8b 8d 1c ff ff ff    	mov    0xffffff1c(%ebp),%ecx
40002002:	cd 30                	int    $0x30
	sys_put(SYS_ZERO, 0, NULL, NULL, dva, PTSIZE);
	sys_get(SYS_COPY, 0, NULL, dva, dva2, PTSIZE);
	readfaulttest(dva2);
40002004:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000200b:	00 
4000200c:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40002013:	e8 f8 e0 ff ff       	call   40000110 <fork>
40002018:	85 c0                	test   %eax,%eax
4000201a:	75 0f                	jne    4000202b <memopcheck+0xa1d>
4000201c:	8b 85 c8 fd ff ff    	mov    0xfffffdc8(%ebp),%eax
40002022:	8b 00                	mov    (%eax),%eax

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40002024:	b8 03 00 00 00       	mov    $0x3,%eax
40002029:	cd 30                	int    $0x30
4000202b:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40002032:	00 
40002033:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000203a:	00 
4000203b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40002042:	e8 a9 e1 ff ff       	call   400001f0 <join>
	readfaulttest(dva2 + PTSIZE-4);
40002047:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000204e:	00 
4000204f:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40002056:	e8 b5 e0 ff ff       	call   40000110 <fork>
4000205b:	85 c0                	test   %eax,%eax
4000205d:	75 14                	jne    40002073 <memopcheck+0xa65>
4000205f:	8b 85 c8 fd ff ff    	mov    0xfffffdc8(%ebp),%eax
40002065:	05 fc ff 3f 00       	add    $0x3ffffc,%eax
4000206a:	8b 00                	mov    (%eax),%eax

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
4000206c:	b8 03 00 00 00       	mov    $0x3,%eax
40002071:	cd 30                	int    $0x30
40002073:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
4000207a:	00 
4000207b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40002082:	00 
40002083:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
4000208a:	e8 61 e1 ff ff       	call   400001f0 <join>
4000208f:	c7 85 48 ff ff ff 00 	movl   $0x300,0xffffff48(%ebp)
40002096:	03 00 00 
40002099:	66 c7 85 46 ff ff ff 	movw   $0x0,0xffffff46(%ebp)
400020a0:	00 00 
400020a2:	c7 85 40 ff ff ff 00 	movl   $0x0,0xffffff40(%ebp)
400020a9:	00 00 00 
400020ac:	c7 85 3c ff ff ff 00 	movl   $0x0,0xffffff3c(%ebp)
400020b3:	00 00 00 
400020b6:	8b 85 c8 fd ff ff    	mov    0xfffffdc8(%ebp),%eax
400020bc:	89 85 38 ff ff ff    	mov    %eax,0xffffff38(%ebp)
400020c2:	c7 85 34 ff ff ff 00 	movl   $0x400000,0xffffff34(%ebp)
400020c9:	00 40 00 
static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
400020cc:	8b 85 48 ff ff ff    	mov    0xffffff48(%ebp),%eax
400020d2:	83 c8 02             	or     $0x2,%eax
400020d5:	8b 9d 40 ff ff ff    	mov    0xffffff40(%ebp),%ebx
400020db:	0f b7 95 46 ff ff ff 	movzwl 0xffffff46(%ebp),%edx
400020e2:	8b b5 3c ff ff ff    	mov    0xffffff3c(%ebp),%esi
400020e8:	8b bd 38 ff ff ff    	mov    0xffffff38(%ebp),%edi
400020ee:	8b 8d 34 ff ff ff    	mov    0xffffff34(%ebp),%ecx
400020f4:	cd 30                	int    $0x30
	sys_get(SYS_PERM | SYS_READ, 0, NULL, NULL, dva2, PTSIZE);
	assert(*(volatile int*)dva2 == 0);
400020f6:	8b 85 c8 fd ff ff    	mov    0xfffffdc8(%ebp),%eax
400020fc:	8b 00                	mov    (%eax),%eax
400020fe:	85 c0                	test   %eax,%eax
40002100:	74 24                	je     40002126 <memopcheck+0xb18>
40002102:	c7 44 24 0c 65 3e 00 	movl   $0x40003e65,0xc(%esp)
40002109:	40 
4000210a:	c7 44 24 08 9b 3d 00 	movl   $0x40003d9b,0x8(%esp)
40002111:	40 
40002112:	c7 44 24 04 33 01 00 	movl   $0x133,0x4(%esp)
40002119:	00 
4000211a:	c7 04 24 a8 3c 00 40 	movl   $0x40003ca8,(%esp)
40002121:	e8 7e 0a 00 00       	call   40002ba4 <debug_panic>
	assert(*(volatile int*)(dva2+PTSIZE-4) == 0);
40002126:	8b 85 c8 fd ff ff    	mov    0xfffffdc8(%ebp),%eax
4000212c:	05 fc ff 3f 00       	add    $0x3ffffc,%eax
40002131:	8b 00                	mov    (%eax),%eax
40002133:	85 c0                	test   %eax,%eax
40002135:	74 24                	je     4000215b <memopcheck+0xb4d>
40002137:	c7 44 24 0c 80 3e 00 	movl   $0x40003e80,0xc(%esp)
4000213e:	40 
4000213f:	c7 44 24 08 9b 3d 00 	movl   $0x40003d9b,0x8(%esp)
40002146:	40 
40002147:	c7 44 24 04 34 01 00 	movl   $0x134,0x4(%esp)
4000214e:	00 
4000214f:	c7 04 24 a8 3c 00 40 	movl   $0x40003ca8,(%esp)
40002156:	e8 49 0a 00 00       	call   40002ba4 <debug_panic>
4000215b:	c7 85 60 ff ff ff 00 	movl   $0x20000,0xffffff60(%ebp)
40002162:	00 02 00 
40002165:	66 c7 85 5e ff ff ff 	movw   $0x0,0xffffff5e(%ebp)
4000216c:	00 00 
4000216e:	c7 85 58 ff ff ff 00 	movl   $0x0,0xffffff58(%ebp)
40002175:	00 00 00 
40002178:	8b 85 c0 fd ff ff    	mov    0xfffffdc0(%ebp),%eax
4000217e:	89 85 54 ff ff ff    	mov    %eax,0xffffff54(%ebp)
40002184:	8b 85 c4 fd ff ff    	mov    0xfffffdc4(%ebp),%eax
4000218a:	89 85 50 ff ff ff    	mov    %eax,0xffffff50(%ebp)
40002190:	c7 85 4c ff ff ff 00 	movl   $0x400000,0xffffff4c(%ebp)
40002197:	00 40 00 
static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
4000219a:	8b 85 60 ff ff ff    	mov    0xffffff60(%ebp),%eax
400021a0:	83 c8 01             	or     $0x1,%eax
400021a3:	8b 9d 58 ff ff ff    	mov    0xffffff58(%ebp),%ebx
400021a9:	0f b7 95 5e ff ff ff 	movzwl 0xffffff5e(%ebp),%edx
400021b0:	8b b5 54 ff ff ff    	mov    0xffffff54(%ebp),%esi
400021b6:	8b bd 50 ff ff ff    	mov    0xffffff50(%ebp),%edi
400021bc:	8b 8d 4c ff ff ff    	mov    0xffffff4c(%ebp),%ecx
400021c2:	cd 30                	int    $0x30
400021c4:	c7 85 78 ff ff ff 00 	movl   $0x20000,0xffffff78(%ebp)
400021cb:	00 02 00 
400021ce:	66 c7 85 76 ff ff ff 	movw   $0x0,0xffffff76(%ebp)
400021d5:	00 00 
400021d7:	c7 85 70 ff ff ff 00 	movl   $0x0,0xffffff70(%ebp)
400021de:	00 00 00 
400021e1:	8b 85 c4 fd ff ff    	mov    0xfffffdc4(%ebp),%eax
400021e7:	89 85 6c ff ff ff    	mov    %eax,0xffffff6c(%ebp)
400021ed:	8b 85 c8 fd ff ff    	mov    0xfffffdc8(%ebp),%eax
400021f3:	89 85 68 ff ff ff    	mov    %eax,0xffffff68(%ebp)
400021f9:	c7 85 64 ff ff ff 00 	movl   $0x400000,0xffffff64(%ebp)
40002200:	00 40 00 
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
40002203:	8b 85 78 ff ff ff    	mov    0xffffff78(%ebp),%eax
40002209:	83 c8 02             	or     $0x2,%eax
4000220c:	8b 9d 70 ff ff ff    	mov    0xffffff70(%ebp),%ebx
40002212:	0f b7 95 76 ff ff ff 	movzwl 0xffffff76(%ebp),%edx
40002219:	8b b5 6c ff ff ff    	mov    0xffffff6c(%ebp),%esi
4000221f:	8b bd 68 ff ff ff    	mov    0xffffff68(%ebp),%edi
40002225:	8b 8d 64 ff ff ff    	mov    0xffffff64(%ebp),%ecx
4000222b:	cd 30                	int    $0x30

	// Test SYS_COPY with SYS_PUT
	sys_put(SYS_COPY, 0, NULL, sva, dva, PTSIZE);
	sys_get(SYS_COPY, 0, NULL, dva, dva2, PTSIZE);
	assert(memcmp(sva, dva2, etext - start) == 0);
4000222d:	ba 47 3c 00 40       	mov    $0x40003c47,%edx
40002232:	b8 00 01 00 40       	mov    $0x40000100,%eax
40002237:	89 d1                	mov    %edx,%ecx
40002239:	29 c1                	sub    %eax,%ecx
4000223b:	89 c8                	mov    %ecx,%eax
4000223d:	89 44 24 08          	mov    %eax,0x8(%esp)
40002241:	8b 85 c8 fd ff ff    	mov    0xfffffdc8(%ebp),%eax
40002247:	89 44 24 04          	mov    %eax,0x4(%esp)
4000224b:	8b 85 c0 fd ff ff    	mov    0xfffffdc0(%ebp),%eax
40002251:	89 04 24             	mov    %eax,(%esp)
40002254:	e8 70 16 00 00       	call   400038c9 <memcmp>
40002259:	85 c0                	test   %eax,%eax
4000225b:	74 24                	je     40002281 <memopcheck+0xc73>
4000225d:	c7 44 24 0c a8 3e 00 	movl   $0x40003ea8,0xc(%esp)
40002264:	40 
40002265:	c7 44 24 08 9b 3d 00 	movl   $0x40003d9b,0x8(%esp)
4000226c:	40 
4000226d:	c7 44 24 04 39 01 00 	movl   $0x139,0x4(%esp)
40002274:	00 
40002275:	c7 04 24 a8 3c 00 40 	movl   $0x40003ca8,(%esp)
4000227c:	e8 23 09 00 00       	call   40002ba4 <debug_panic>
	writefaulttest(dva2);
40002281:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40002288:	00 
40002289:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40002290:	e8 7b de ff ff       	call   40000110 <fork>
40002295:	85 c0                	test   %eax,%eax
40002297:	75 1f                	jne    400022b8 <memopcheck+0xcaa>
40002299:	8b 85 c8 fd ff ff    	mov    0xfffffdc8(%ebp),%eax
4000229f:	89 85 e0 fd ff ff    	mov    %eax,0xfffffde0(%ebp)
400022a5:	8b 85 e0 fd ff ff    	mov    0xfffffde0(%ebp),%eax
400022ab:	c7 00 ef be ad de    	movl   $0xdeadbeef,(%eax)

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
400022b1:	b8 03 00 00 00       	mov    $0x3,%eax
400022b6:	cd 30                	int    $0x30
400022b8:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
400022bf:	00 
400022c0:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400022c7:	00 
400022c8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
400022cf:	e8 1c df ff ff       	call   400001f0 <join>
	readfaulttest(dva2 + PTSIZE-4);
400022d4:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400022db:	00 
400022dc:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
400022e3:	e8 28 de ff ff       	call   40000110 <fork>
400022e8:	85 c0                	test   %eax,%eax
400022ea:	75 14                	jne    40002300 <memopcheck+0xcf2>
400022ec:	8b 85 c8 fd ff ff    	mov    0xfffffdc8(%ebp),%eax
400022f2:	05 fc ff 3f 00       	add    $0x3ffffc,%eax
400022f7:	8b 00                	mov    (%eax),%eax

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
400022f9:	b8 03 00 00 00       	mov    $0x3,%eax
400022fe:	cd 30                	int    $0x30
40002300:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40002307:	00 
40002308:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000230f:	00 
40002310:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40002317:	e8 d4 de ff ff       	call   400001f0 <join>

	// Hide an easter egg and make sure it survives the two copies
	sva = (void*)VM_USERLO; dva = sva+PTSIZE; dva2 = dva+PTSIZE;
4000231c:	c7 85 c0 fd ff ff 00 	movl   $0x40000000,0xfffffdc0(%ebp)
40002323:	00 00 40 
40002326:	8b 85 c0 fd ff ff    	mov    0xfffffdc0(%ebp),%eax
4000232c:	05 00 00 40 00       	add    $0x400000,%eax
40002331:	89 85 c4 fd ff ff    	mov    %eax,0xfffffdc4(%ebp)
40002337:	8b 85 c4 fd ff ff    	mov    0xfffffdc4(%ebp),%eax
4000233d:	05 00 00 40 00       	add    $0x400000,%eax
40002342:	89 85 c8 fd ff ff    	mov    %eax,0xfffffdc8(%ebp)
	uint32_t ofs = PTSIZE-PAGESIZE;
40002348:	c7 85 cc fd ff ff 00 	movl   $0x3ff000,0xfffffdcc(%ebp)
4000234f:	f0 3f 00 
	sys_get(SYS_PERM|SYS_READ|SYS_WRITE, 0, NULL, NULL, sva+ofs, PAGESIZE);
40002352:	8b 85 cc fd ff ff    	mov    0xfffffdcc(%ebp),%eax
40002358:	03 85 c0 fd ff ff    	add    0xfffffdc0(%ebp),%eax
4000235e:	c7 45 90 00 07 00 00 	movl   $0x700,0xffffff90(%ebp)
40002365:	66 c7 45 8e 00 00    	movw   $0x0,0xffffff8e(%ebp)
4000236b:	c7 45 88 00 00 00 00 	movl   $0x0,0xffffff88(%ebp)
40002372:	c7 45 84 00 00 00 00 	movl   $0x0,0xffffff84(%ebp)
40002379:	89 45 80             	mov    %eax,0xffffff80(%ebp)
4000237c:	c7 85 7c ff ff ff 00 	movl   $0x1000,0xffffff7c(%ebp)
40002383:	10 00 00 
static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40002386:	8b 45 90             	mov    0xffffff90(%ebp),%eax
40002389:	83 c8 02             	or     $0x2,%eax
4000238c:	8b 5d 88             	mov    0xffffff88(%ebp),%ebx
4000238f:	0f b7 55 8e          	movzwl 0xffffff8e(%ebp),%edx
40002393:	8b 75 84             	mov    0xffffff84(%ebp),%esi
40002396:	8b 7d 80             	mov    0xffffff80(%ebp),%edi
40002399:	8b 8d 7c ff ff ff    	mov    0xffffff7c(%ebp),%ecx
4000239f:	cd 30                	int    $0x30
	*(volatile int*)(sva+ofs) = 0xdeadbeef;	// should be writable now
400023a1:	8b 85 cc fd ff ff    	mov    0xfffffdcc(%ebp),%eax
400023a7:	03 85 c0 fd ff ff    	add    0xfffffdc0(%ebp),%eax
400023ad:	c7 00 ef be ad de    	movl   $0xdeadbeef,(%eax)
	sys_get(SYS_PERM, 0, NULL, NULL, sva+ofs, PAGESIZE);
400023b3:	8b 85 cc fd ff ff    	mov    0xfffffdcc(%ebp),%eax
400023b9:	03 85 c0 fd ff ff    	add    0xfffffdc0(%ebp),%eax
400023bf:	c7 45 a8 00 01 00 00 	movl   $0x100,0xffffffa8(%ebp)
400023c6:	66 c7 45 a6 00 00    	movw   $0x0,0xffffffa6(%ebp)
400023cc:	c7 45 a0 00 00 00 00 	movl   $0x0,0xffffffa0(%ebp)
400023d3:	c7 45 9c 00 00 00 00 	movl   $0x0,0xffffff9c(%ebp)
400023da:	89 45 98             	mov    %eax,0xffffff98(%ebp)
400023dd:	c7 45 94 00 10 00 00 	movl   $0x1000,0xffffff94(%ebp)
static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
400023e4:	8b 45 a8             	mov    0xffffffa8(%ebp),%eax
400023e7:	83 c8 02             	or     $0x2,%eax
400023ea:	8b 5d a0             	mov    0xffffffa0(%ebp),%ebx
400023ed:	0f b7 55 a6          	movzwl 0xffffffa6(%ebp),%edx
400023f1:	8b 75 9c             	mov    0xffffff9c(%ebp),%esi
400023f4:	8b 7d 98             	mov    0xffffff98(%ebp),%edi
400023f7:	8b 4d 94             	mov    0xffffff94(%ebp),%ecx
400023fa:	cd 30                	int    $0x30
	readfaulttest(sva+ofs);			// hide it
400023fc:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40002403:	00 
40002404:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
4000240b:	e8 00 dd ff ff       	call   40000110 <fork>
40002410:	85 c0                	test   %eax,%eax
40002412:	75 15                	jne    40002429 <memopcheck+0xe1b>
40002414:	8b 85 cc fd ff ff    	mov    0xfffffdcc(%ebp),%eax
4000241a:	03 85 c0 fd ff ff    	add    0xfffffdc0(%ebp),%eax
40002420:	8b 00                	mov    (%eax),%eax

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40002422:	b8 03 00 00 00       	mov    $0x3,%eax
40002427:	cd 30                	int    $0x30
40002429:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40002430:	00 
40002431:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40002438:	00 
40002439:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40002440:	e8 ab dd ff ff       	call   400001f0 <join>
40002445:	c7 45 c0 00 00 02 00 	movl   $0x20000,0xffffffc0(%ebp)
4000244c:	66 c7 45 be 00 00    	movw   $0x0,0xffffffbe(%ebp)
40002452:	c7 45 b8 00 00 00 00 	movl   $0x0,0xffffffb8(%ebp)
40002459:	8b 85 c0 fd ff ff    	mov    0xfffffdc0(%ebp),%eax
4000245f:	89 45 b4             	mov    %eax,0xffffffb4(%ebp)
40002462:	8b 85 c4 fd ff ff    	mov    0xfffffdc4(%ebp),%eax
40002468:	89 45 b0             	mov    %eax,0xffffffb0(%ebp)
4000246b:	c7 45 ac 00 00 40 00 	movl   $0x400000,0xffffffac(%ebp)
static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
40002472:	8b 45 c0             	mov    0xffffffc0(%ebp),%eax
40002475:	83 c8 01             	or     $0x1,%eax
40002478:	8b 5d b8             	mov    0xffffffb8(%ebp),%ebx
4000247b:	0f b7 55 be          	movzwl 0xffffffbe(%ebp),%edx
4000247f:	8b 75 b4             	mov    0xffffffb4(%ebp),%esi
40002482:	8b 7d b0             	mov    0xffffffb0(%ebp),%edi
40002485:	8b 4d ac             	mov    0xffffffac(%ebp),%ecx
40002488:	cd 30                	int    $0x30
4000248a:	c7 45 d8 00 00 02 00 	movl   $0x20000,0xffffffd8(%ebp)
40002491:	66 c7 45 d6 00 00    	movw   $0x0,0xffffffd6(%ebp)
40002497:	c7 45 d0 00 00 00 00 	movl   $0x0,0xffffffd0(%ebp)
4000249e:	8b 85 c4 fd ff ff    	mov    0xfffffdc4(%ebp),%eax
400024a4:	89 45 cc             	mov    %eax,0xffffffcc(%ebp)
400024a7:	8b 85 c8 fd ff ff    	mov    0xfffffdc8(%ebp),%eax
400024ad:	89 45 c8             	mov    %eax,0xffffffc8(%ebp)
400024b0:	c7 45 c4 00 00 40 00 	movl   $0x400000,0xffffffc4(%ebp)
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
400024b7:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
400024ba:	83 c8 02             	or     $0x2,%eax
400024bd:	8b 5d d0             	mov    0xffffffd0(%ebp),%ebx
400024c0:	0f b7 55 d6          	movzwl 0xffffffd6(%ebp),%edx
400024c4:	8b 75 cc             	mov    0xffffffcc(%ebp),%esi
400024c7:	8b 7d c8             	mov    0xffffffc8(%ebp),%edi
400024ca:	8b 4d c4             	mov    0xffffffc4(%ebp),%ecx
400024cd:	cd 30                	int    $0x30
	sys_put(SYS_COPY, 0, NULL, sva, dva, PTSIZE);
	sys_get(SYS_COPY, 0, NULL, dva, dva2, PTSIZE);
	readfaulttest(dva2+ofs);		// stayed hidden?
400024cf:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400024d6:	00 
400024d7:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
400024de:	e8 2d dc ff ff       	call   40000110 <fork>
400024e3:	85 c0                	test   %eax,%eax
400024e5:	75 15                	jne    400024fc <memopcheck+0xeee>
400024e7:	8b 85 cc fd ff ff    	mov    0xfffffdcc(%ebp),%eax
400024ed:	03 85 c8 fd ff ff    	add    0xfffffdc8(%ebp),%eax
400024f3:	8b 00                	mov    (%eax),%eax

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
400024f5:	b8 03 00 00 00       	mov    $0x3,%eax
400024fa:	cd 30                	int    $0x30
400024fc:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40002503:	00 
40002504:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000250b:	00 
4000250c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40002513:	e8 d8 dc ff ff       	call   400001f0 <join>
	sys_get(SYS_PERM|SYS_READ, 0, NULL, NULL, dva2+ofs, PAGESIZE);
40002518:	8b 85 cc fd ff ff    	mov    0xfffffdcc(%ebp),%eax
4000251e:	03 85 c8 fd ff ff    	add    0xfffffdc8(%ebp),%eax
40002524:	c7 45 f0 00 03 00 00 	movl   $0x300,0xfffffff0(%ebp)
4000252b:	66 c7 45 ee 00 00    	movw   $0x0,0xffffffee(%ebp)
40002531:	c7 45 e8 00 00 00 00 	movl   $0x0,0xffffffe8(%ebp)
40002538:	c7 45 e4 00 00 00 00 	movl   $0x0,0xffffffe4(%ebp)
4000253f:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)
40002542:	c7 45 dc 00 10 00 00 	movl   $0x1000,0xffffffdc(%ebp)
static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40002549:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
4000254c:	83 c8 02             	or     $0x2,%eax
4000254f:	8b 5d e8             	mov    0xffffffe8(%ebp),%ebx
40002552:	0f b7 55 ee          	movzwl 0xffffffee(%ebp),%edx
40002556:	8b 75 e4             	mov    0xffffffe4(%ebp),%esi
40002559:	8b 7d e0             	mov    0xffffffe0(%ebp),%edi
4000255c:	8b 4d dc             	mov    0xffffffdc(%ebp),%ecx
4000255f:	cd 30                	int    $0x30
	assert(*(volatile int*)(dva2+ofs) == 0xdeadbeef);	// survived?
40002561:	8b 85 cc fd ff ff    	mov    0xfffffdcc(%ebp),%eax
40002567:	03 85 c8 fd ff ff    	add    0xfffffdc8(%ebp),%eax
4000256d:	8b 00                	mov    (%eax),%eax
4000256f:	3d ef be ad de       	cmp    $0xdeadbeef,%eax
40002574:	74 24                	je     4000259a <memopcheck+0xf8c>
40002576:	c7 44 24 0c d0 3e 00 	movl   $0x40003ed0,0xc(%esp)
4000257d:	40 
4000257e:	c7 44 24 08 9b 3d 00 	movl   $0x40003d9b,0x8(%esp)
40002585:	40 
40002586:	c7 44 24 04 48 01 00 	movl   $0x148,0x4(%esp)
4000258d:	00 
4000258e:	c7 04 24 a8 3c 00 40 	movl   $0x40003ca8,(%esp)
40002595:	e8 0a 06 00 00       	call   40002ba4 <debug_panic>

	cprintf("testvm: memopcheck passed\n");
4000259a:	c7 04 24 f9 3e 00 40 	movl   $0x40003ef9,(%esp)
400025a1:	e8 bb 08 00 00       	call   40002e61 <cprintf>
}
400025a6:	81 c4 5c 02 00 00    	add    $0x25c,%esp
400025ac:	5b                   	pop    %ebx
400025ad:	5e                   	pop    %esi
400025ae:	5f                   	pop    %edi
400025af:	5d                   	pop    %ebp
400025b0:	c3                   	ret    

400025b1 <pqsort>:

int x, y;

int randints[256] = {	// some random ints
	 20,726,926,682,210,585,829,491,612,744,753,405,346,189,669,416,
	 41,832,959,511,260,879,844,323,710,570,289,299,624,319,997,907,
	 56,545,122,497, 60,314,759,741,276,951,496,376,403,294,395, 96,
	372,402,468,866,782,524,739,273,462,920,965,225,164,687,628,127,
	998,957,973,212,801,790,254,855,215,979,229,234,194,755,174,793,
	367,865,458,479,117,471,113, 12,605,328,231,513,676,495,422,404,
	611,693, 32, 59,126,607,219,837,542,437,803,341,727,626,360,507,
	834,465,795,271,646,725,336,241, 42,353,438, 44,167,786, 51,873,
	874,994, 80,432,657,365,734,132,500,145,238,931,332,146,922,878,
	108,508,601, 38,749,606,565,642,261,767,312,410,239,476,498, 90,
	655,379,835,270,862,876,699,165,675,869,296,163,435,321, 88,575,
	233,745, 94,303,584,381,359, 50,766,534, 27,499,101,464,195,453,
	671, 87,139,123,544,560,679,616,705,494,733,678,927, 26, 14,114,
	140,777,250,564,596,802,723,383,808,817,  1,436,361,952,613,680,
	854,580, 76,891,888,721,204,989,882,141,448,286,964,130, 48,385,
	756,224,138,630,821,449,662,578,400, 74,477,275,272,392,747,394};
const int sortints[256] = {	// sorted array of the same ints
	  1, 12, 14, 20, 26, 27, 32, 38, 41, 42, 44, 48, 50, 51, 56, 59,
	 60, 74, 76, 80, 87, 88, 90, 94, 96,101,108,113,114,117,122,123,
	126,127,130,132,138,139,140,141,145,146,163,164,165,167,174,189,
	194,195,204,210,212,215,219,224,225,229,231,233,234,238,239,241,
	250,254,260,261,270,271,272,273,275,276,286,289,294,296,299,303,
	312,314,319,321,323,328,332,336,341,346,353,359,360,361,365,367,
	372,376,379,381,383,385,392,394,395,400,402,403,404,405,410,416,
	422,432,435,436,437,438,448,449,453,458,462,464,465,468,471,476,
	477,479,491,494,495,496,497,498,499,500,507,508,511,513,524,534,
	542,544,545,560,564,565,570,575,578,580,584,585,596,601,605,606,
	607,611,612,613,616,624,626,628,630,642,646,655,657,662,669,671,
	675,676,678,679,680,682,687,693,699,705,710,721,723,725,726,727,
	733,734,739,741,744,745,747,749,753,755,756,759,766,767,777,782,
	786,790,793,795,801,802,803,808,817,821,829,832,834,835,837,844,
	854,855,862,865,866,869,873,874,876,878,879,882,888,891,907,920,
	922,926,927,931,951,952,957,959,964,965,973,979,989,994,997,998};

#define swapints(a,b) ({ int t = (a); (a) = (b); (b) = t; })

void
pqsort(int *lo, int *hi)
{
400025b1:	55                   	push   %ebp
400025b2:	89 e5                	mov    %esp,%ebp
400025b4:	83 ec 38             	sub    $0x38,%esp
	if (lo >= hi)
400025b7:	8b 45 08             	mov    0x8(%ebp),%eax
400025ba:	3b 45 0c             	cmp    0xc(%ebp),%eax
400025bd:	0f 83 23 01 00 00    	jae    400026e6 <pqsort+0x135>
		return;

	int pivot = *lo;	// yeah, bad way to choose pivot...
400025c3:	8b 45 08             	mov    0x8(%ebp),%eax
400025c6:	8b 00                	mov    (%eax),%eax
400025c8:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
	int *l = lo+1, *h = hi;
400025cb:	8b 45 08             	mov    0x8(%ebp),%eax
400025ce:	83 c0 04             	add    $0x4,%eax
400025d1:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
400025d4:	8b 45 0c             	mov    0xc(%ebp),%eax
400025d7:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	while (l <= h) {
400025da:	eb 42                	jmp    4000261e <pqsort+0x6d>
		if (*l < pivot)
400025dc:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
400025df:	8b 00                	mov    (%eax),%eax
400025e1:	3b 45 ec             	cmp    0xffffffec(%ebp),%eax
400025e4:	7d 06                	jge    400025ec <pqsort+0x3b>
			l++;
400025e6:	83 45 f0 04          	addl   $0x4,0xfffffff0(%ebp)
400025ea:	eb 32                	jmp    4000261e <pqsort+0x6d>
		else if (*h > pivot)
400025ec:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
400025ef:	8b 00                	mov    (%eax),%eax
400025f1:	3b 45 ec             	cmp    0xffffffec(%ebp),%eax
400025f4:	7e 06                	jle    400025fc <pqsort+0x4b>
			h--;
400025f6:	83 6d f4 04          	subl   $0x4,0xfffffff4(%ebp)
400025fa:	eb 22                	jmp    4000261e <pqsort+0x6d>
		else
			swapints(*h, *l), l++, h--;
400025fc:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
400025ff:	8b 00                	mov    (%eax),%eax
40002601:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
40002604:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
40002607:	8b 10                	mov    (%eax),%edx
40002609:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
4000260c:	89 10                	mov    %edx,(%eax)
4000260e:	8b 55 f0             	mov    0xfffffff0(%ebp),%edx
40002611:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
40002614:	89 02                	mov    %eax,(%edx)
40002616:	83 45 f0 04          	addl   $0x4,0xfffffff0(%ebp)
4000261a:	83 6d f4 04          	subl   $0x4,0xfffffff4(%ebp)
4000261e:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
40002621:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
40002624:	76 b6                	jbe    400025dc <pqsort+0x2b>
	}
	swapints(*lo, l[-1]);
40002626:	8b 45 08             	mov    0x8(%ebp),%eax
40002629:	8b 00                	mov    (%eax),%eax
4000262b:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
4000262e:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
40002631:	83 e8 04             	sub    $0x4,%eax
40002634:	8b 10                	mov    (%eax),%edx
40002636:	8b 45 08             	mov    0x8(%ebp),%eax
40002639:	89 10                	mov    %edx,(%eax)
4000263b:	8b 55 f0             	mov    0xfffffff0(%ebp),%edx
4000263e:	83 ea 04             	sub    $0x4,%edx
40002641:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
40002644:	89 02                	mov    %eax,(%edx)

	// Now recursively sort the two halves in parallel subprocesses
	if (!fork(SYS_START | SYS_SNAP, 0)) {
40002646:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000264d:	00 
4000264e:	c7 04 24 10 00 04 00 	movl   $0x40010,(%esp)
40002655:	e8 b6 da ff ff       	call   40000110 <fork>
4000265a:	85 c0                	test   %eax,%eax
4000265c:	75 1c                	jne    4000267a <pqsort+0xc9>
		pqsort(lo, l-2);
4000265e:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
40002661:	83 e8 08             	sub    $0x8,%eax
40002664:	89 44 24 04          	mov    %eax,0x4(%esp)
40002668:	8b 45 08             	mov    0x8(%ebp),%eax
4000266b:	89 04 24             	mov    %eax,(%esp)
4000266e:	e8 3e ff ff ff       	call   400025b1 <pqsort>

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40002673:	b8 03 00 00 00       	mov    $0x3,%eax
40002678:	cd 30                	int    $0x30
		sys_ret();
	}
	if (!fork(SYS_START | SYS_SNAP, 1)) {
4000267a:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
40002681:	00 
40002682:	c7 04 24 10 00 04 00 	movl   $0x40010,(%esp)
40002689:	e8 82 da ff ff       	call   40000110 <fork>
4000268e:	85 c0                	test   %eax,%eax
40002690:	75 1c                	jne    400026ae <pqsort+0xfd>
		pqsort(h+1, hi);
40002692:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
40002695:	83 c2 04             	add    $0x4,%edx
40002698:	8b 45 0c             	mov    0xc(%ebp),%eax
4000269b:	89 44 24 04          	mov    %eax,0x4(%esp)
4000269f:	89 14 24             	mov    %edx,(%esp)
400026a2:	e8 0a ff ff ff       	call   400025b1 <pqsort>

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
400026a7:	b8 03 00 00 00       	mov    $0x3,%eax
400026ac:	cd 30                	int    $0x30
		sys_ret();
	}
	join(SYS_MERGE, 0, T_SYSCALL);
400026ae:	c7 44 24 08 30 00 00 	movl   $0x30,0x8(%esp)
400026b5:	00 
400026b6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400026bd:	00 
400026be:	c7 04 24 00 00 03 00 	movl   $0x30000,(%esp)
400026c5:	e8 26 db ff ff       	call   400001f0 <join>
	join(SYS_MERGE, 1, T_SYSCALL);
400026ca:	c7 44 24 08 30 00 00 	movl   $0x30,0x8(%esp)
400026d1:	00 
400026d2:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
400026d9:	00 
400026da:	c7 04 24 00 00 03 00 	movl   $0x30000,(%esp)
400026e1:	e8 0a db ff ff       	call   400001f0 <join>
}
400026e6:	c9                   	leave  
400026e7:	c3                   	ret    

400026e8 <matmult>:

int ma[8][8] = {	// First matrix to multiply
	{146, 3, 189, 106, 239, 208, 8, 122},
	{200, 225, 94, 74, 143, 3, 127, 59},
	{32, 127, 52, 205, 0, 86, 143, 213},
	{159, 135, 45, 198, 152, 70, 116, 234},
	{238, 68, 215, 168, 79, 235, 15, 189},
	{82, 160, 97, 132, 186, 1, 220, 48},
	{178, 39, 153, 15, 16, 227, 251, 198},
	{148, 1, 239, 153, 39, 137, 42, 161}};
int mb[8][8] = {	// Second matrix to multiply
	{75, 95, 165, 229, 14, 90, 222, 236},
	{171, 131, 12, 84, 120, 147, 76, 69},
	{235, 51, 255, 250, 222, 64, 9, 1},
	{206, 7, 13, 120, 23, 137, 178, 81},
	{57, 184, 224, 142, 22, 184, 3, 132},
	{49, 30, 70, 28, 239, 52, 217, 13},
	{217, 50, 44, 35, 216, 134, 49, 123},
	{119, 13, 157, 196, 37, 87, 38, 126}};
int mr[8][8];		// Result matrix
const int mc[8][8] = {	// Matrix of correct answers
	{117783, 76846, 161301, 157610, 108012, 106677, 104090, 94046},
	{133687, 87306, 107725, 133479, 85848, 115848, 85063, 110783},
	{139159, 36263, 68482, 104757, 91270, 95127, 87477, 78517},
	{151485, 75381, 122694, 156229, 86758, 131671, 111429, 127648},
	{156375, 68452, 161574, 189491, 131222, 113401, 148992, 113825},
	{147600, 80499, 100851, 115856, 98545, 123124, 68112, 98854},
	{149128, 54805, 130652, 140309, 157630, 99208, 115657, 106951},
	{136163, 42930, 132817, 154486, 107399, 83659, 100339, 80010}};

void
matmult(int a[8][8], int b[8][8], int r[8][8])
{
400026e8:	55                   	push   %ebp
400026e9:	89 e5                	mov    %esp,%ebp
400026eb:	83 ec 38             	sub    $0x38,%esp
	int i,j,k;

	// Fork off a thread to compute each cell in the result matrix
	for (i = 0; i < 8; i++)
400026ee:	c7 45 e8 00 00 00 00 	movl   $0x0,0xffffffe8(%ebp)
400026f5:	e9 a1 00 00 00       	jmp    4000279b <matmult+0xb3>
		for (j = 0; j < 8; j++) {
400026fa:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
40002701:	e9 87 00 00 00       	jmp    4000278d <matmult+0xa5>
			int child = i*8 + j;
40002706:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
40002709:	c1 e0 03             	shl    $0x3,%eax
4000270c:	03 45 ec             	add    0xffffffec(%ebp),%eax
4000270f:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
			if (!fork(SYS_START | SYS_SNAP, child)) {
40002712:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
40002715:	0f b6 c0             	movzbl %al,%eax
40002718:	89 44 24 04          	mov    %eax,0x4(%esp)
4000271c:	c7 04 24 10 00 04 00 	movl   $0x40010,(%esp)
40002723:	e8 e8 d9 ff ff       	call   40000110 <fork>
40002728:	85 c0                	test   %eax,%eax
4000272a:	75 5d                	jne    40002789 <matmult+0xa1>
				int sum = 0;	// in child: compute cell i,j
4000272c:	c7 45 f8 00 00 00 00 	movl   $0x0,0xfffffff8(%ebp)
				for (k = 0; k < 8; k++)
40002733:	c7 45 f0 00 00 00 00 	movl   $0x0,0xfffffff0(%ebp)
4000273a:	eb 2c                	jmp    40002768 <matmult+0x80>
					sum += a[i][k] * b[k][j];
4000273c:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
4000273f:	c1 e0 05             	shl    $0x5,%eax
40002742:	89 c2                	mov    %eax,%edx
40002744:	03 55 08             	add    0x8(%ebp),%edx
40002747:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
4000274a:	8b 0c 82             	mov    (%edx,%eax,4),%ecx
4000274d:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
40002750:	c1 e0 05             	shl    $0x5,%eax
40002753:	89 c2                	mov    %eax,%edx
40002755:	03 55 0c             	add    0xc(%ebp),%edx
40002758:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
4000275b:	8b 04 82             	mov    (%edx,%eax,4),%eax
4000275e:	0f af c1             	imul   %ecx,%eax
40002761:	01 45 f8             	add    %eax,0xfffffff8(%ebp)
40002764:	83 45 f0 01          	addl   $0x1,0xfffffff0(%ebp)
40002768:	83 7d f0 07          	cmpl   $0x7,0xfffffff0(%ebp)
4000276c:	7e ce                	jle    4000273c <matmult+0x54>
				r[i][j] = sum;
4000276e:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
40002771:	c1 e0 05             	shl    $0x5,%eax
40002774:	89 c1                	mov    %eax,%ecx
40002776:	03 4d 10             	add    0x10(%ebp),%ecx
40002779:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
4000277c:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
4000277f:	89 04 91             	mov    %eax,(%ecx,%edx,4)

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40002782:	b8 03 00 00 00       	mov    $0x3,%eax
40002787:	cd 30                	int    $0x30
40002789:	83 45 ec 01          	addl   $0x1,0xffffffec(%ebp)
4000278d:	83 7d ec 07          	cmpl   $0x7,0xffffffec(%ebp)
40002791:	0f 8e 6f ff ff ff    	jle    40002706 <matmult+0x1e>
40002797:	83 45 e8 01          	addl   $0x1,0xffffffe8(%ebp)
4000279b:	83 7d e8 07          	cmpl   $0x7,0xffffffe8(%ebp)
4000279f:	0f 8e 55 ff ff ff    	jle    400026fa <matmult+0x12>
				sys_ret();
			}
		}

	// Now go back and merge in the results of all our children
	for (i = 0; i < 8; i++)
400027a5:	c7 45 e8 00 00 00 00 	movl   $0x0,0xffffffe8(%ebp)
400027ac:	eb 41                	jmp    400027ef <matmult+0x107>
		for (j = 0; j < 8; j++) {
400027ae:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
400027b5:	eb 2e                	jmp    400027e5 <matmult+0xfd>
			int child = i*8 + j;
400027b7:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
400027ba:	c1 e0 03             	shl    $0x3,%eax
400027bd:	03 45 ec             	add    0xffffffec(%ebp),%eax
400027c0:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
			join(SYS_MERGE, child, T_SYSCALL);
400027c3:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
400027c6:	0f b6 c0             	movzbl %al,%eax
400027c9:	c7 44 24 08 30 00 00 	movl   $0x30,0x8(%esp)
400027d0:	00 
400027d1:	89 44 24 04          	mov    %eax,0x4(%esp)
400027d5:	c7 04 24 00 00 03 00 	movl   $0x30000,(%esp)
400027dc:	e8 0f da ff ff       	call   400001f0 <join>
400027e1:	83 45 ec 01          	addl   $0x1,0xffffffec(%ebp)
400027e5:	83 7d ec 07          	cmpl   $0x7,0xffffffec(%ebp)
400027e9:	7e cc                	jle    400027b7 <matmult+0xcf>
400027eb:	83 45 e8 01          	addl   $0x1,0xffffffe8(%ebp)
400027ef:	83 7d e8 07          	cmpl   $0x7,0xffffffe8(%ebp)
400027f3:	7e b9                	jle    400027ae <matmult+0xc6>
		}
}
400027f5:	c9                   	leave  
400027f6:	c3                   	ret    

400027f7 <mergecheck>:

void
mergecheck()
{
400027f7:	55                   	push   %ebp
400027f8:	89 e5                	mov    %esp,%ebp
400027fa:	83 ec 18             	sub    $0x18,%esp
	// Simple merge test: two children write two adjacent variables
	if (!fork(SYS_START | SYS_SNAP, 0)) { x = 0xdeadbeef; sys_ret(); }
400027fd:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40002804:	00 
40002805:	c7 04 24 10 00 04 00 	movl   $0x40010,(%esp)
4000280c:	e8 ff d8 ff ff       	call   40000110 <fork>
40002811:	85 c0                	test   %eax,%eax
40002813:	75 11                	jne    40002826 <mergecheck+0x2f>
40002815:	c7 05 80 5d 00 40 ef 	movl   $0xdeadbeef,0x40005d80
4000281c:	be ad de 

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
4000281f:	b8 03 00 00 00       	mov    $0x3,%eax
40002824:	cd 30                	int    $0x30
	if (!fork(SYS_START | SYS_SNAP, 1)) { y = 0xabadcafe; sys_ret(); }
40002826:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
4000282d:	00 
4000282e:	c7 04 24 10 00 04 00 	movl   $0x40010,(%esp)
40002835:	e8 d6 d8 ff ff       	call   40000110 <fork>
4000283a:	85 c0                	test   %eax,%eax
4000283c:	75 11                	jne    4000284f <mergecheck+0x58>
4000283e:	c7 05 a0 7e 00 40 fe 	movl   $0xabadcafe,0x40007ea0
40002845:	ca ad ab 

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40002848:	b8 03 00 00 00       	mov    $0x3,%eax
4000284d:	cd 30                	int    $0x30
	assert(x == 0); assert(y == 0);
4000284f:	a1 80 5d 00 40       	mov    0x40005d80,%eax
40002854:	85 c0                	test   %eax,%eax
40002856:	74 24                	je     4000287c <mergecheck+0x85>
40002858:	c7 44 24 0c 20 44 00 	movl   $0x40004420,0xc(%esp)
4000285f:	40 
40002860:	c7 44 24 08 9b 3d 00 	movl   $0x40003d9b,0x8(%esp)
40002867:	40 
40002868:	c7 44 24 04 d0 01 00 	movl   $0x1d0,0x4(%esp)
4000286f:	00 
40002870:	c7 04 24 a8 3c 00 40 	movl   $0x40003ca8,(%esp)
40002877:	e8 28 03 00 00       	call   40002ba4 <debug_panic>
4000287c:	a1 a0 7e 00 40       	mov    0x40007ea0,%eax
40002881:	85 c0                	test   %eax,%eax
40002883:	74 24                	je     400028a9 <mergecheck+0xb2>
40002885:	c7 44 24 0c 27 44 00 	movl   $0x40004427,0xc(%esp)
4000288c:	40 
4000288d:	c7 44 24 08 9b 3d 00 	movl   $0x40003d9b,0x8(%esp)
40002894:	40 
40002895:	c7 44 24 04 d0 01 00 	movl   $0x1d0,0x4(%esp)
4000289c:	00 
4000289d:	c7 04 24 a8 3c 00 40 	movl   $0x40003ca8,(%esp)
400028a4:	e8 fb 02 00 00       	call   40002ba4 <debug_panic>
	join(SYS_MERGE, 0, T_SYSCALL);
400028a9:	c7 44 24 08 30 00 00 	movl   $0x30,0x8(%esp)
400028b0:	00 
400028b1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400028b8:	00 
400028b9:	c7 04 24 00 00 03 00 	movl   $0x30000,(%esp)
400028c0:	e8 2b d9 ff ff       	call   400001f0 <join>
	join(SYS_MERGE, 1, T_SYSCALL);
400028c5:	c7 44 24 08 30 00 00 	movl   $0x30,0x8(%esp)
400028cc:	00 
400028cd:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
400028d4:	00 
400028d5:	c7 04 24 00 00 03 00 	movl   $0x30000,(%esp)
400028dc:	e8 0f d9 ff ff       	call   400001f0 <join>
	assert(x == 0xdeadbeef); assert(y == 0xabadcafe);
400028e1:	a1 80 5d 00 40       	mov    0x40005d80,%eax
400028e6:	3d ef be ad de       	cmp    $0xdeadbeef,%eax
400028eb:	74 24                	je     40002911 <mergecheck+0x11a>
400028ed:	c7 44 24 0c 2e 44 00 	movl   $0x4000442e,0xc(%esp)
400028f4:	40 
400028f5:	c7 44 24 08 9b 3d 00 	movl   $0x40003d9b,0x8(%esp)
400028fc:	40 
400028fd:	c7 44 24 04 d3 01 00 	movl   $0x1d3,0x4(%esp)
40002904:	00 
40002905:	c7 04 24 a8 3c 00 40 	movl   $0x40003ca8,(%esp)
4000290c:	e8 93 02 00 00       	call   40002ba4 <debug_panic>
40002911:	a1 a0 7e 00 40       	mov    0x40007ea0,%eax
40002916:	3d fe ca ad ab       	cmp    $0xabadcafe,%eax
4000291b:	74 24                	je     40002941 <mergecheck+0x14a>
4000291d:	c7 44 24 0c 3e 44 00 	movl   $0x4000443e,0xc(%esp)
40002924:	40 
40002925:	c7 44 24 08 9b 3d 00 	movl   $0x40003d9b,0x8(%esp)
4000292c:	40 
4000292d:	c7 44 24 04 d3 01 00 	movl   $0x1d3,0x4(%esp)
40002934:	00 
40002935:	c7 04 24 a8 3c 00 40 	movl   $0x40003ca8,(%esp)
4000293c:	e8 63 02 00 00       	call   40002ba4 <debug_panic>

	// A Rube Goldberg approach to swapping two variables
	if (!fork(SYS_START | SYS_SNAP, 0)) { x = y; sys_ret(); }
40002941:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40002948:	00 
40002949:	c7 04 24 10 00 04 00 	movl   $0x40010,(%esp)
40002950:	e8 bb d7 ff ff       	call   40000110 <fork>
40002955:	85 c0                	test   %eax,%eax
40002957:	75 11                	jne    4000296a <mergecheck+0x173>
40002959:	a1 a0 7e 00 40       	mov    0x40007ea0,%eax
4000295e:	a3 80 5d 00 40       	mov    %eax,0x40005d80

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40002963:	b8 03 00 00 00       	mov    $0x3,%eax
40002968:	cd 30                	int    $0x30
	if (!fork(SYS_START | SYS_SNAP, 1)) { y = x; sys_ret(); }
4000296a:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
40002971:	00 
40002972:	c7 04 24 10 00 04 00 	movl   $0x40010,(%esp)
40002979:	e8 92 d7 ff ff       	call   40000110 <fork>
4000297e:	85 c0                	test   %eax,%eax
40002980:	75 11                	jne    40002993 <mergecheck+0x19c>
40002982:	a1 80 5d 00 40       	mov    0x40005d80,%eax
40002987:	a3 a0 7e 00 40       	mov    %eax,0x40007ea0

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
4000298c:	b8 03 00 00 00       	mov    $0x3,%eax
40002991:	cd 30                	int    $0x30
	assert(x == 0xdeadbeef); assert(y == 0xabadcafe);
40002993:	a1 80 5d 00 40       	mov    0x40005d80,%eax
40002998:	3d ef be ad de       	cmp    $0xdeadbeef,%eax
4000299d:	74 24                	je     400029c3 <mergecheck+0x1cc>
4000299f:	c7 44 24 0c 2e 44 00 	movl   $0x4000442e,0xc(%esp)
400029a6:	40 
400029a7:	c7 44 24 08 9b 3d 00 	movl   $0x40003d9b,0x8(%esp)
400029ae:	40 
400029af:	c7 44 24 04 d8 01 00 	movl   $0x1d8,0x4(%esp)
400029b6:	00 
400029b7:	c7 04 24 a8 3c 00 40 	movl   $0x40003ca8,(%esp)
400029be:	e8 e1 01 00 00       	call   40002ba4 <debug_panic>
400029c3:	a1 a0 7e 00 40       	mov    0x40007ea0,%eax
400029c8:	3d fe ca ad ab       	cmp    $0xabadcafe,%eax
400029cd:	74 24                	je     400029f3 <mergecheck+0x1fc>
400029cf:	c7 44 24 0c 3e 44 00 	movl   $0x4000443e,0xc(%esp)
400029d6:	40 
400029d7:	c7 44 24 08 9b 3d 00 	movl   $0x40003d9b,0x8(%esp)
400029de:	40 
400029df:	c7 44 24 04 d8 01 00 	movl   $0x1d8,0x4(%esp)
400029e6:	00 
400029e7:	c7 04 24 a8 3c 00 40 	movl   $0x40003ca8,(%esp)
400029ee:	e8 b1 01 00 00       	call   40002ba4 <debug_panic>
	join(SYS_MERGE, 0, T_SYSCALL);
400029f3:	c7 44 24 08 30 00 00 	movl   $0x30,0x8(%esp)
400029fa:	00 
400029fb:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40002a02:	00 
40002a03:	c7 04 24 00 00 03 00 	movl   $0x30000,(%esp)
40002a0a:	e8 e1 d7 ff ff       	call   400001f0 <join>
	join(SYS_MERGE, 1, T_SYSCALL);
40002a0f:	c7 44 24 08 30 00 00 	movl   $0x30,0x8(%esp)
40002a16:	00 
40002a17:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
40002a1e:	00 
40002a1f:	c7 04 24 00 00 03 00 	movl   $0x30000,(%esp)
40002a26:	e8 c5 d7 ff ff       	call   400001f0 <join>
	assert(y == 0xdeadbeef); assert(x == 0xabadcafe);
40002a2b:	a1 a0 7e 00 40       	mov    0x40007ea0,%eax
40002a30:	3d ef be ad de       	cmp    $0xdeadbeef,%eax
40002a35:	74 24                	je     40002a5b <mergecheck+0x264>
40002a37:	c7 44 24 0c 4e 44 00 	movl   $0x4000444e,0xc(%esp)
40002a3e:	40 
40002a3f:	c7 44 24 08 9b 3d 00 	movl   $0x40003d9b,0x8(%esp)
40002a46:	40 
40002a47:	c7 44 24 04 db 01 00 	movl   $0x1db,0x4(%esp)
40002a4e:	00 
40002a4f:	c7 04 24 a8 3c 00 40 	movl   $0x40003ca8,(%esp)
40002a56:	e8 49 01 00 00       	call   40002ba4 <debug_panic>
40002a5b:	a1 80 5d 00 40       	mov    0x40005d80,%eax
40002a60:	3d fe ca ad ab       	cmp    $0xabadcafe,%eax
40002a65:	74 24                	je     40002a8b <mergecheck+0x294>
40002a67:	c7 44 24 0c 5e 44 00 	movl   $0x4000445e,0xc(%esp)
40002a6e:	40 
40002a6f:	c7 44 24 08 9b 3d 00 	movl   $0x40003d9b,0x8(%esp)
40002a76:	40 
40002a77:	c7 44 24 04 db 01 00 	movl   $0x1db,0x4(%esp)
40002a7e:	00 
40002a7f:	c7 04 24 a8 3c 00 40 	movl   $0x40003ca8,(%esp)
40002a86:	e8 19 01 00 00       	call   40002ba4 <debug_panic>

	// Parallel quicksort with recursive processes!
	// (though probably not very efficient on arrays this small)
	pqsort(&randints[0], &randints[256-1]);
40002a8b:	b8 7c 5b 00 40       	mov    $0x40005b7c,%eax
40002a90:	89 44 24 04          	mov    %eax,0x4(%esp)
40002a94:	c7 04 24 80 57 00 40 	movl   $0x40005780,(%esp)
40002a9b:	e8 11 fb ff ff       	call   400025b1 <pqsort>
	assert(memcmp(randints, sortints, 256*sizeof(int)) == 0);
40002aa0:	c7 44 24 08 00 04 00 	movl   $0x400,0x8(%esp)
40002aa7:	00 
40002aa8:	c7 44 24 04 20 3f 00 	movl   $0x40003f20,0x4(%esp)
40002aaf:	40 
40002ab0:	c7 04 24 80 57 00 40 	movl   $0x40005780,(%esp)
40002ab7:	e8 0d 0e 00 00       	call   400038c9 <memcmp>
40002abc:	85 c0                	test   %eax,%eax
40002abe:	74 24                	je     40002ae4 <mergecheck+0x2ed>
40002ac0:	c7 44 24 0c 70 44 00 	movl   $0x40004470,0xc(%esp)
40002ac7:	40 
40002ac8:	c7 44 24 08 9b 3d 00 	movl   $0x40003d9b,0x8(%esp)
40002acf:	40 
40002ad0:	c7 44 24 04 e0 01 00 	movl   $0x1e0,0x4(%esp)
40002ad7:	00 
40002ad8:	c7 04 24 a8 3c 00 40 	movl   $0x40003ca8,(%esp)
40002adf:	e8 c0 00 00 00       	call   40002ba4 <debug_panic>

	// Parallel matrix multiply, one child process per result matrix cell
	matmult(ma, mb, mr);
40002ae4:	c7 44 24 08 a0 7d 00 	movl   $0x40007da0,0x8(%esp)
40002aeb:	40 
40002aec:	c7 44 24 04 80 5c 00 	movl   $0x40005c80,0x4(%esp)
40002af3:	40 
40002af4:	c7 04 24 80 5b 00 40 	movl   $0x40005b80,(%esp)
40002afb:	e8 e8 fb ff ff       	call   400026e8 <matmult>
	assert(sizeof(mr) == sizeof(int)*8*8);
	assert(sizeof(mc) == sizeof(int)*8*8);
	assert(memcmp(mr, mc, sizeof(mr)) == 0);
40002b00:	c7 44 24 08 00 01 00 	movl   $0x100,0x8(%esp)
40002b07:	00 
40002b08:	c7 44 24 04 20 43 00 	movl   $0x40004320,0x4(%esp)
40002b0f:	40 
40002b10:	c7 04 24 a0 7d 00 40 	movl   $0x40007da0,(%esp)
40002b17:	e8 ad 0d 00 00       	call   400038c9 <memcmp>
40002b1c:	85 c0                	test   %eax,%eax
40002b1e:	74 24                	je     40002b44 <mergecheck+0x34d>
40002b20:	c7 44 24 0c a4 44 00 	movl   $0x400044a4,0xc(%esp)
40002b27:	40 
40002b28:	c7 44 24 08 9b 3d 00 	movl   $0x40003d9b,0x8(%esp)
40002b2f:	40 
40002b30:	c7 44 24 04 e6 01 00 	movl   $0x1e6,0x4(%esp)
40002b37:	00 
40002b38:	c7 04 24 a8 3c 00 40 	movl   $0x40003ca8,(%esp)
40002b3f:	e8 60 00 00 00       	call   40002ba4 <debug_panic>

	cprintf("testvm: mergecheck passed\n");
40002b44:	c7 04 24 c4 44 00 40 	movl   $0x400044c4,(%esp)
40002b4b:	e8 11 03 00 00       	call   40002e61 <cprintf>
}
40002b50:	c9                   	leave  
40002b51:	c3                   	ret    

40002b52 <main>:

int
main()
{
40002b52:	8d 4c 24 04          	lea    0x4(%esp),%ecx
40002b56:	83 e4 f0             	and    $0xfffffff0,%esp
40002b59:	ff 71 fc             	pushl  0xfffffffc(%ecx)
40002b5c:	55                   	push   %ebp
40002b5d:	89 e5                	mov    %esp,%ebp
40002b5f:	51                   	push   %ecx
40002b60:	83 ec 04             	sub    $0x4,%esp
	cprintf("testvm: in main()\n");
40002b63:	c7 04 24 df 44 00 40 	movl   $0x400044df,(%esp)
40002b6a:	e8 f2 02 00 00       	call   40002e61 <cprintf>

	loadcheck();
40002b6f:	e8 23 d8 ff ff       	call   40000397 <loadcheck>
	forkcheck();
40002b74:	e8 a0 d8 ff ff       	call   40000419 <forkcheck>
	protcheck();
40002b79:	e8 ff db ff ff       	call   4000077d <protcheck>
	memopcheck();
40002b7e:	e8 8b ea ff ff       	call   4000160e <memopcheck>
	mergecheck();
40002b83:	e8 6f fc ff ff       	call   400027f7 <mergecheck>

	cprintf("testvm: all tests completed successfully!\n");
40002b88:	c7 04 24 f4 44 00 40 	movl   $0x400044f4,(%esp)
40002b8f:	e8 cd 02 00 00       	call   40002e61 <cprintf>
	return 0;
40002b94:	b8 00 00 00 00       	mov    $0x0,%eax
}
40002b99:	83 c4 04             	add    $0x4,%esp
40002b9c:	59                   	pop    %ecx
40002b9d:	5d                   	pop    %ebp
40002b9e:	8d 61 fc             	lea    0xfffffffc(%ecx),%esp
40002ba1:	c3                   	ret    
40002ba2:	90                   	nop    
40002ba3:	90                   	nop    

40002ba4 <debug_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception.
 */
void
debug_panic(const char *file, int line, const char *fmt,...)
{
40002ba4:	55                   	push   %ebp
40002ba5:	89 e5                	mov    %esp,%ebp
40002ba7:	83 ec 28             	sub    $0x28,%esp
	va_list ap;
	va_start(ap, fmt);
40002baa:	8d 45 10             	lea    0x10(%ebp),%eax
40002bad:	83 c0 04             	add    $0x4,%eax
40002bb0:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)

	// Print the panic message
	if (argv0)
40002bb3:	a1 a4 7e 00 40       	mov    0x40007ea4,%eax
40002bb8:	85 c0                	test   %eax,%eax
40002bba:	74 15                	je     40002bd1 <debug_panic+0x2d>
		cprintf("%s: ", argv0);
40002bbc:	a1 a4 7e 00 40       	mov    0x40007ea4,%eax
40002bc1:	89 44 24 04          	mov    %eax,0x4(%esp)
40002bc5:	c7 04 24 20 45 00 40 	movl   $0x40004520,(%esp)
40002bcc:	e8 90 02 00 00       	call   40002e61 <cprintf>
	cprintf("user panic at %s:%d: ", file, line);
40002bd1:	8b 45 0c             	mov    0xc(%ebp),%eax
40002bd4:	89 44 24 08          	mov    %eax,0x8(%esp)
40002bd8:	8b 45 08             	mov    0x8(%ebp),%eax
40002bdb:	89 44 24 04          	mov    %eax,0x4(%esp)
40002bdf:	c7 04 24 25 45 00 40 	movl   $0x40004525,(%esp)
40002be6:	e8 76 02 00 00       	call   40002e61 <cprintf>
	vcprintf(fmt, ap);
40002beb:	8b 55 10             	mov    0x10(%ebp),%edx
40002bee:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
40002bf1:	89 44 24 04          	mov    %eax,0x4(%esp)
40002bf5:	89 14 24             	mov    %edx,(%esp)
40002bf8:	e8 fb 01 00 00       	call   40002df8 <vcprintf>
	cprintf("\n");
40002bfd:	c7 04 24 3b 45 00 40 	movl   $0x4000453b,(%esp)
40002c04:	e8 58 02 00 00       	call   40002e61 <cprintf>

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40002c09:	b8 03 00 00 00       	mov    $0x3,%eax
40002c0e:	cd 30                	int    $0x30

	sys_ret();
	while(1)
		;
40002c10:	eb fe                	jmp    40002c10 <debug_panic+0x6c>

40002c12 <debug_warn>:
}

/* like panic, but don't */
void
debug_warn(const char *file, int line, const char *fmt,...)
{
40002c12:	55                   	push   %ebp
40002c13:	89 e5                	mov    %esp,%ebp
40002c15:	83 ec 28             	sub    $0x28,%esp
	va_list ap;

	va_start(ap, fmt);
40002c18:	8d 45 10             	lea    0x10(%ebp),%eax
40002c1b:	83 c0 04             	add    $0x4,%eax
40002c1e:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	cprintf("user warning at %s:%d: ", file, line);
40002c21:	8b 45 0c             	mov    0xc(%ebp),%eax
40002c24:	89 44 24 08          	mov    %eax,0x8(%esp)
40002c28:	8b 45 08             	mov    0x8(%ebp),%eax
40002c2b:	89 44 24 04          	mov    %eax,0x4(%esp)
40002c2f:	c7 04 24 3d 45 00 40 	movl   $0x4000453d,(%esp)
40002c36:	e8 26 02 00 00       	call   40002e61 <cprintf>
	vcprintf(fmt, ap);
40002c3b:	8b 55 10             	mov    0x10(%ebp),%edx
40002c3e:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
40002c41:	89 44 24 04          	mov    %eax,0x4(%esp)
40002c45:	89 14 24             	mov    %edx,(%esp)
40002c48:	e8 ab 01 00 00       	call   40002df8 <vcprintf>
	cprintf("\n");
40002c4d:	c7 04 24 3b 45 00 40 	movl   $0x4000453b,(%esp)
40002c54:	e8 08 02 00 00       	call   40002e61 <cprintf>
	va_end(ap);
}
40002c59:	c9                   	leave  
40002c5a:	c3                   	ret    

40002c5b <debug_dump>:

// Dump a block of memory as 32-bit words and ASCII bytes
void
debug_dump(const char *file, int line, const void *ptr, int size)
{
40002c5b:	55                   	push   %ebp
40002c5c:	89 e5                	mov    %esp,%ebp
40002c5e:	56                   	push   %esi
40002c5f:	53                   	push   %ebx
40002c60:	81 ec b0 00 00 00    	sub    $0xb0,%esp
	cprintf("user dump at %s:%d of memory %08x-%08x:\n",
40002c66:	8b 45 14             	mov    0x14(%ebp),%eax
40002c69:	03 45 10             	add    0x10(%ebp),%eax
40002c6c:	89 44 24 10          	mov    %eax,0x10(%esp)
40002c70:	8b 45 10             	mov    0x10(%ebp),%eax
40002c73:	89 44 24 0c          	mov    %eax,0xc(%esp)
40002c77:	8b 45 0c             	mov    0xc(%ebp),%eax
40002c7a:	89 44 24 08          	mov    %eax,0x8(%esp)
40002c7e:	8b 45 08             	mov    0x8(%ebp),%eax
40002c81:	89 44 24 04          	mov    %eax,0x4(%esp)
40002c85:	c7 04 24 58 45 00 40 	movl   $0x40004558,(%esp)
40002c8c:	e8 d0 01 00 00       	call   40002e61 <cprintf>
		file, line, ptr, ptr + size);
	for (size = (size+15) & ~15; size > 0; size -= 16, ptr += 16) {
40002c91:	8b 45 14             	mov    0x14(%ebp),%eax
40002c94:	83 c0 0f             	add    $0xf,%eax
40002c97:	83 e0 f0             	and    $0xfffffff0,%eax
40002c9a:	89 45 14             	mov    %eax,0x14(%ebp)
40002c9d:	e9 df 00 00 00       	jmp    40002d81 <debug_dump+0x126>
		char buf[100];

		// ASCII bytes
		int i; 
		const uint8_t *c = ptr;
40002ca2:	8b 45 10             	mov    0x10(%ebp),%eax
40002ca5:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
		for (i = 0; i < 16; i++)
40002ca8:	c7 45 e8 00 00 00 00 	movl   $0x0,0xffffffe8(%ebp)
40002caf:	eb 71                	jmp    40002d22 <debug_dump+0xc7>
			buf[i] = isprint(c[i]) ? c[i] : '.';
40002cb1:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
40002cb4:	89 85 6c ff ff ff    	mov    %eax,0xffffff6c(%ebp)
40002cba:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
40002cbd:	03 45 ec             	add    0xffffffec(%ebp),%eax
40002cc0:	0f b6 00             	movzbl (%eax),%eax
40002cc3:	0f b6 c0             	movzbl %al,%eax
40002cc6:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
static gcc_inline int iscntrl(int c)	{ return c < ' '; }
static gcc_inline int isblank(int c)	{ return c == ' ' || c == '\t'; }
static gcc_inline int isspace(int c)	{ return c == ' '
						|| (c >= '\t' && c <= '\r'); }
static gcc_inline int isprint(int c)	{ return c >= ' ' && c <= '~'; }
40002cc9:	83 7d f4 1f          	cmpl   $0x1f,0xfffffff4(%ebp)
40002ccd:	7e 12                	jle    40002ce1 <debug_dump+0x86>
40002ccf:	83 7d f4 7e          	cmpl   $0x7e,0xfffffff4(%ebp)
40002cd3:	7f 0c                	jg     40002ce1 <debug_dump+0x86>
40002cd5:	c7 85 74 ff ff ff 01 	movl   $0x1,0xffffff74(%ebp)
40002cdc:	00 00 00 
40002cdf:	eb 0a                	jmp    40002ceb <debug_dump+0x90>
40002ce1:	c7 85 74 ff ff ff 00 	movl   $0x0,0xffffff74(%ebp)
40002ce8:	00 00 00 
40002ceb:	8b 85 74 ff ff ff    	mov    0xffffff74(%ebp),%eax
40002cf1:	85 c0                	test   %eax,%eax
40002cf3:	74 11                	je     40002d06 <debug_dump+0xab>
40002cf5:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
40002cf8:	03 45 ec             	add    0xffffffec(%ebp),%eax
40002cfb:	0f b6 00             	movzbl (%eax),%eax
40002cfe:	88 85 73 ff ff ff    	mov    %al,0xffffff73(%ebp)
40002d04:	eb 07                	jmp    40002d0d <debug_dump+0xb2>
40002d06:	c6 85 73 ff ff ff 2e 	movb   $0x2e,0xffffff73(%ebp)
40002d0d:	0f b6 95 73 ff ff ff 	movzbl 0xffffff73(%ebp),%edx
40002d14:	8b 85 6c ff ff ff    	mov    0xffffff6c(%ebp),%eax
40002d1a:	88 54 05 84          	mov    %dl,0xffffff84(%ebp,%eax,1)
40002d1e:	83 45 e8 01          	addl   $0x1,0xffffffe8(%ebp)
40002d22:	83 7d e8 0f          	cmpl   $0xf,0xffffffe8(%ebp)
40002d26:	7e 89                	jle    40002cb1 <debug_dump+0x56>
		buf[16] = 0;
40002d28:	c6 45 94 00          	movb   $0x0,0xffffff94(%ebp)

		// Hex words
		const uint32_t *v = ptr;
40002d2c:	8b 45 10             	mov    0x10(%ebp),%eax
40002d2f:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)

		// Print each line atomically to avoid async mixing
		cprintf("%08x: %08x %08x %08x %08x %s",
40002d32:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
40002d35:	83 c0 0c             	add    $0xc,%eax
40002d38:	8b 10                	mov    (%eax),%edx
40002d3a:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
40002d3d:	83 c0 08             	add    $0x8,%eax
40002d40:	8b 08                	mov    (%eax),%ecx
40002d42:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
40002d45:	83 c0 04             	add    $0x4,%eax
40002d48:	8b 18                	mov    (%eax),%ebx
40002d4a:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
40002d4d:	8b 30                	mov    (%eax),%esi
40002d4f:	8d 45 84             	lea    0xffffff84(%ebp),%eax
40002d52:	89 44 24 18          	mov    %eax,0x18(%esp)
40002d56:	89 54 24 14          	mov    %edx,0x14(%esp)
40002d5a:	89 4c 24 10          	mov    %ecx,0x10(%esp)
40002d5e:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
40002d62:	89 74 24 08          	mov    %esi,0x8(%esp)
40002d66:	8b 45 10             	mov    0x10(%ebp),%eax
40002d69:	89 44 24 04          	mov    %eax,0x4(%esp)
40002d6d:	c7 04 24 81 45 00 40 	movl   $0x40004581,(%esp)
40002d74:	e8 e8 00 00 00       	call   40002e61 <cprintf>
40002d79:	83 6d 14 10          	subl   $0x10,0x14(%ebp)
40002d7d:	83 45 10 10          	addl   $0x10,0x10(%ebp)
40002d81:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
40002d85:	0f 8f 17 ff ff ff    	jg     40002ca2 <debug_dump+0x47>
			ptr, v[0], v[1], v[2], v[3], buf);
	}
}
40002d8b:	81 c4 b0 00 00 00    	add    $0xb0,%esp
40002d91:	5b                   	pop    %ebx
40002d92:	5e                   	pop    %esi
40002d93:	5d                   	pop    %ebp
40002d94:	c3                   	ret    
40002d95:	90                   	nop    
40002d96:	90                   	nop    
40002d97:	90                   	nop    

40002d98 <putch>:


static void
putch(int ch, struct printbuf *b)
{
40002d98:	55                   	push   %ebp
40002d99:	89 e5                	mov    %esp,%ebp
40002d9b:	83 ec 08             	sub    $0x8,%esp
	b->buf[b->idx++] = ch;
40002d9e:	8b 45 0c             	mov    0xc(%ebp),%eax
40002da1:	8b 08                	mov    (%eax),%ecx
40002da3:	8b 45 08             	mov    0x8(%ebp),%eax
40002da6:	89 c2                	mov    %eax,%edx
40002da8:	8b 45 0c             	mov    0xc(%ebp),%eax
40002dab:	88 54 08 08          	mov    %dl,0x8(%eax,%ecx,1)
40002daf:	8d 51 01             	lea    0x1(%ecx),%edx
40002db2:	8b 45 0c             	mov    0xc(%ebp),%eax
40002db5:	89 10                	mov    %edx,(%eax)
	if (b->idx == CPUTS_MAX-1) {
40002db7:	8b 45 0c             	mov    0xc(%ebp),%eax
40002dba:	8b 00                	mov    (%eax),%eax
40002dbc:	3d ff 00 00 00       	cmp    $0xff,%eax
40002dc1:	75 24                	jne    40002de7 <putch+0x4f>
		b->buf[b->idx] = 0;
40002dc3:	8b 45 0c             	mov    0xc(%ebp),%eax
40002dc6:	8b 10                	mov    (%eax),%edx
40002dc8:	8b 45 0c             	mov    0xc(%ebp),%eax
40002dcb:	c6 44 10 08 00       	movb   $0x0,0x8(%eax,%edx,1)
		cputs(b->buf);
40002dd0:	8b 45 0c             	mov    0xc(%ebp),%eax
40002dd3:	83 c0 08             	add    $0x8,%eax
40002dd6:	89 04 24             	mov    %eax,(%esp)
40002dd9:	e8 8a 0b 00 00       	call   40003968 <cputs>
		b->idx = 0;
40002dde:	8b 45 0c             	mov    0xc(%ebp),%eax
40002de1:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	}
	b->cnt++;
40002de7:	8b 45 0c             	mov    0xc(%ebp),%eax
40002dea:	8b 40 04             	mov    0x4(%eax),%eax
40002ded:	8d 50 01             	lea    0x1(%eax),%edx
40002df0:	8b 45 0c             	mov    0xc(%ebp),%eax
40002df3:	89 50 04             	mov    %edx,0x4(%eax)
}
40002df6:	c9                   	leave  
40002df7:	c3                   	ret    

40002df8 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
40002df8:	55                   	push   %ebp
40002df9:	89 e5                	mov    %esp,%ebp
40002dfb:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
40002e01:	c7 85 f8 fe ff ff 00 	movl   $0x0,0xfffffef8(%ebp)
40002e08:	00 00 00 
	b.cnt = 0;
40002e0b:	c7 85 fc fe ff ff 00 	movl   $0x0,0xfffffefc(%ebp)
40002e12:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
40002e15:	ba 98 2d 00 40       	mov    $0x40002d98,%edx
40002e1a:	8b 45 0c             	mov    0xc(%ebp),%eax
40002e1d:	89 44 24 0c          	mov    %eax,0xc(%esp)
40002e21:	8b 45 08             	mov    0x8(%ebp),%eax
40002e24:	89 44 24 08          	mov    %eax,0x8(%esp)
40002e28:	8d 85 f8 fe ff ff    	lea    0xfffffef8(%ebp),%eax
40002e2e:	89 44 24 04          	mov    %eax,0x4(%esp)
40002e32:	89 14 24             	mov    %edx,(%esp)
40002e35:	e8 b4 03 00 00       	call   400031ee <vprintfmt>

	b.buf[b.idx] = 0;
40002e3a:	8b 85 f8 fe ff ff    	mov    0xfffffef8(%ebp),%eax
40002e40:	c6 84 05 00 ff ff ff 	movb   $0x0,0xffffff00(%ebp,%eax,1)
40002e47:	00 
	cputs(b.buf);
40002e48:	8d 85 f8 fe ff ff    	lea    0xfffffef8(%ebp),%eax
40002e4e:	83 c0 08             	add    $0x8,%eax
40002e51:	89 04 24             	mov    %eax,(%esp)
40002e54:	e8 0f 0b 00 00       	call   40003968 <cputs>

	return b.cnt;
40002e59:	8b 85 fc fe ff ff    	mov    0xfffffefc(%ebp),%eax
}
40002e5f:	c9                   	leave  
40002e60:	c3                   	ret    

40002e61 <cprintf>:

int
cprintf(const char *fmt, ...)
{
40002e61:	55                   	push   %ebp
40002e62:	89 e5                	mov    %esp,%ebp
40002e64:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
40002e67:	8d 45 08             	lea    0x8(%ebp),%eax
40002e6a:	83 c0 04             	add    $0x4,%eax
40002e6d:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
	cnt = vcprintf(fmt, ap);
40002e70:	8b 55 08             	mov    0x8(%ebp),%edx
40002e73:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
40002e76:	89 44 24 04          	mov    %eax,0x4(%esp)
40002e7a:	89 14 24             	mov    %edx,(%esp)
40002e7d:	e8 76 ff ff ff       	call   40002df8 <vcprintf>
40002e82:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	va_end(ap);

	return cnt;
40002e85:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
}
40002e88:	c9                   	leave  
40002e89:	c3                   	ret    
40002e8a:	90                   	nop    
40002e8b:	90                   	nop    

40002e8c <getuint>:
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static uintmax_t
getuint(printstate *st, va_list *ap)
{
40002e8c:	55                   	push   %ebp
40002e8d:	89 e5                	mov    %esp,%ebp
40002e8f:	83 ec 08             	sub    $0x8,%esp
	if (st->flags & F_LL)
40002e92:	8b 45 08             	mov    0x8(%ebp),%eax
40002e95:	8b 40 18             	mov    0x18(%eax),%eax
40002e98:	83 e0 02             	and    $0x2,%eax
40002e9b:	85 c0                	test   %eax,%eax
40002e9d:	74 22                	je     40002ec1 <getuint+0x35>
		return va_arg(*ap, unsigned long long);
40002e9f:	8b 45 0c             	mov    0xc(%ebp),%eax
40002ea2:	8b 00                	mov    (%eax),%eax
40002ea4:	8d 50 08             	lea    0x8(%eax),%edx
40002ea7:	8b 45 0c             	mov    0xc(%ebp),%eax
40002eaa:	89 10                	mov    %edx,(%eax)
40002eac:	8b 45 0c             	mov    0xc(%ebp),%eax
40002eaf:	8b 00                	mov    (%eax),%eax
40002eb1:	83 e8 08             	sub    $0x8,%eax
40002eb4:	8b 10                	mov    (%eax),%edx
40002eb6:	8b 48 04             	mov    0x4(%eax),%ecx
40002eb9:	89 55 f8             	mov    %edx,0xfffffff8(%ebp)
40002ebc:	89 4d fc             	mov    %ecx,0xfffffffc(%ebp)
40002ebf:	eb 51                	jmp    40002f12 <getuint+0x86>
	else if (st->flags & F_L)
40002ec1:	8b 45 08             	mov    0x8(%ebp),%eax
40002ec4:	8b 40 18             	mov    0x18(%eax),%eax
40002ec7:	83 e0 01             	and    $0x1,%eax
40002eca:	84 c0                	test   %al,%al
40002ecc:	74 23                	je     40002ef1 <getuint+0x65>
		return va_arg(*ap, unsigned long);
40002ece:	8b 45 0c             	mov    0xc(%ebp),%eax
40002ed1:	8b 00                	mov    (%eax),%eax
40002ed3:	8d 50 04             	lea    0x4(%eax),%edx
40002ed6:	8b 45 0c             	mov    0xc(%ebp),%eax
40002ed9:	89 10                	mov    %edx,(%eax)
40002edb:	8b 45 0c             	mov    0xc(%ebp),%eax
40002ede:	8b 00                	mov    (%eax),%eax
40002ee0:	83 e8 04             	sub    $0x4,%eax
40002ee3:	8b 00                	mov    (%eax),%eax
40002ee5:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
40002ee8:	c7 45 fc 00 00 00 00 	movl   $0x0,0xfffffffc(%ebp)
40002eef:	eb 21                	jmp    40002f12 <getuint+0x86>
	else
		return va_arg(*ap, unsigned int);
40002ef1:	8b 45 0c             	mov    0xc(%ebp),%eax
40002ef4:	8b 00                	mov    (%eax),%eax
40002ef6:	8d 50 04             	lea    0x4(%eax),%edx
40002ef9:	8b 45 0c             	mov    0xc(%ebp),%eax
40002efc:	89 10                	mov    %edx,(%eax)
40002efe:	8b 45 0c             	mov    0xc(%ebp),%eax
40002f01:	8b 00                	mov    (%eax),%eax
40002f03:	83 e8 04             	sub    $0x4,%eax
40002f06:	8b 00                	mov    (%eax),%eax
40002f08:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
40002f0b:	c7 45 fc 00 00 00 00 	movl   $0x0,0xfffffffc(%ebp)
40002f12:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
40002f15:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
}
40002f18:	c9                   	leave  
40002f19:	c3                   	ret    

40002f1a <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static intmax_t
getint(printstate *st, va_list *ap)
{
40002f1a:	55                   	push   %ebp
40002f1b:	89 e5                	mov    %esp,%ebp
40002f1d:	83 ec 08             	sub    $0x8,%esp
	if (st->flags & F_LL)
40002f20:	8b 45 08             	mov    0x8(%ebp),%eax
40002f23:	8b 40 18             	mov    0x18(%eax),%eax
40002f26:	83 e0 02             	and    $0x2,%eax
40002f29:	85 c0                	test   %eax,%eax
40002f2b:	74 22                	je     40002f4f <getint+0x35>
		return va_arg(*ap, long long);
40002f2d:	8b 45 0c             	mov    0xc(%ebp),%eax
40002f30:	8b 00                	mov    (%eax),%eax
40002f32:	8d 50 08             	lea    0x8(%eax),%edx
40002f35:	8b 45 0c             	mov    0xc(%ebp),%eax
40002f38:	89 10                	mov    %edx,(%eax)
40002f3a:	8b 45 0c             	mov    0xc(%ebp),%eax
40002f3d:	8b 00                	mov    (%eax),%eax
40002f3f:	83 e8 08             	sub    $0x8,%eax
40002f42:	8b 10                	mov    (%eax),%edx
40002f44:	8b 48 04             	mov    0x4(%eax),%ecx
40002f47:	89 55 f8             	mov    %edx,0xfffffff8(%ebp)
40002f4a:	89 4d fc             	mov    %ecx,0xfffffffc(%ebp)
40002f4d:	eb 53                	jmp    40002fa2 <getint+0x88>
	else if (st->flags & F_L)
40002f4f:	8b 45 08             	mov    0x8(%ebp),%eax
40002f52:	8b 40 18             	mov    0x18(%eax),%eax
40002f55:	83 e0 01             	and    $0x1,%eax
40002f58:	84 c0                	test   %al,%al
40002f5a:	74 24                	je     40002f80 <getint+0x66>
		return va_arg(*ap, long);
40002f5c:	8b 45 0c             	mov    0xc(%ebp),%eax
40002f5f:	8b 00                	mov    (%eax),%eax
40002f61:	8d 50 04             	lea    0x4(%eax),%edx
40002f64:	8b 45 0c             	mov    0xc(%ebp),%eax
40002f67:	89 10                	mov    %edx,(%eax)
40002f69:	8b 45 0c             	mov    0xc(%ebp),%eax
40002f6c:	8b 00                	mov    (%eax),%eax
40002f6e:	83 e8 04             	sub    $0x4,%eax
40002f71:	8b 00                	mov    (%eax),%eax
40002f73:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
40002f76:	89 c1                	mov    %eax,%ecx
40002f78:	c1 f9 1f             	sar    $0x1f,%ecx
40002f7b:	89 4d fc             	mov    %ecx,0xfffffffc(%ebp)
40002f7e:	eb 22                	jmp    40002fa2 <getint+0x88>
	else
		return va_arg(*ap, int);
40002f80:	8b 45 0c             	mov    0xc(%ebp),%eax
40002f83:	8b 00                	mov    (%eax),%eax
40002f85:	8d 50 04             	lea    0x4(%eax),%edx
40002f88:	8b 45 0c             	mov    0xc(%ebp),%eax
40002f8b:	89 10                	mov    %edx,(%eax)
40002f8d:	8b 45 0c             	mov    0xc(%ebp),%eax
40002f90:	8b 00                	mov    (%eax),%eax
40002f92:	83 e8 04             	sub    $0x4,%eax
40002f95:	8b 00                	mov    (%eax),%eax
40002f97:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
40002f9a:	89 c2                	mov    %eax,%edx
40002f9c:	c1 fa 1f             	sar    $0x1f,%edx
40002f9f:	89 55 fc             	mov    %edx,0xfffffffc(%ebp)
40002fa2:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
40002fa5:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
}
40002fa8:	c9                   	leave  
40002fa9:	c3                   	ret    

40002faa <putpad>:

// Print padding characters, and an optional sign before a number.
static void
putpad(printstate *st)
{
40002faa:	55                   	push   %ebp
40002fab:	89 e5                	mov    %esp,%ebp
40002fad:	83 ec 08             	sub    $0x8,%esp
	while (--st->width >= 0)
40002fb0:	eb 1a                	jmp    40002fcc <putpad+0x22>
		st->putch(st->padc, st->putdat);
40002fb2:	8b 45 08             	mov    0x8(%ebp),%eax
40002fb5:	8b 08                	mov    (%eax),%ecx
40002fb7:	8b 45 08             	mov    0x8(%ebp),%eax
40002fba:	8b 50 04             	mov    0x4(%eax),%edx
40002fbd:	8b 45 08             	mov    0x8(%ebp),%eax
40002fc0:	8b 40 08             	mov    0x8(%eax),%eax
40002fc3:	89 54 24 04          	mov    %edx,0x4(%esp)
40002fc7:	89 04 24             	mov    %eax,(%esp)
40002fca:	ff d1                	call   *%ecx
40002fcc:	8b 45 08             	mov    0x8(%ebp),%eax
40002fcf:	8b 40 0c             	mov    0xc(%eax),%eax
40002fd2:	8d 50 ff             	lea    0xffffffff(%eax),%edx
40002fd5:	8b 45 08             	mov    0x8(%ebp),%eax
40002fd8:	89 50 0c             	mov    %edx,0xc(%eax)
40002fdb:	8b 45 08             	mov    0x8(%ebp),%eax
40002fde:	8b 40 0c             	mov    0xc(%eax),%eax
40002fe1:	85 c0                	test   %eax,%eax
40002fe3:	79 cd                	jns    40002fb2 <putpad+0x8>
}
40002fe5:	c9                   	leave  
40002fe6:	c3                   	ret    

40002fe7 <putstr>:

// Print a string with a specified maximum length (-1=unlimited),
// with any appropriate left or right field padding.
static void
putstr(printstate *st, const char *str, int maxlen)
{
40002fe7:	55                   	push   %ebp
40002fe8:	89 e5                	mov    %esp,%ebp
40002fea:	53                   	push   %ebx
40002feb:	83 ec 24             	sub    $0x24,%esp
	const char *lim;		// find where the string actually ends
	if (maxlen < 0)
40002fee:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
40002ff2:	79 18                	jns    4000300c <putstr+0x25>
		lim = strchr(str, 0);	// find the terminating null
40002ff4:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40002ffb:	00 
40002ffc:	8b 45 0c             	mov    0xc(%ebp),%eax
40002fff:	89 04 24             	mov    %eax,(%esp)
40003002:	e8 22 07 00 00       	call   40003729 <strchr>
40003007:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
4000300a:	eb 2c                	jmp    40003038 <putstr+0x51>
	else if ((lim = memchr(str, 0, maxlen)) == NULL)
4000300c:	8b 45 10             	mov    0x10(%ebp),%eax
4000300f:	89 44 24 08          	mov    %eax,0x8(%esp)
40003013:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000301a:	00 
4000301b:	8b 45 0c             	mov    0xc(%ebp),%eax
4000301e:	89 04 24             	mov    %eax,(%esp)
40003021:	e8 00 09 00 00       	call   40003926 <memchr>
40003026:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
40003029:	83 7d f4 00          	cmpl   $0x0,0xfffffff4(%ebp)
4000302d:	75 09                	jne    40003038 <putstr+0x51>
		lim = str + maxlen;
4000302f:	8b 45 10             	mov    0x10(%ebp),%eax
40003032:	03 45 0c             	add    0xc(%ebp),%eax
40003035:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	st->width -= (lim-str);		// deduct string length from field width
40003038:	8b 45 08             	mov    0x8(%ebp),%eax
4000303b:	8b 48 0c             	mov    0xc(%eax),%ecx
4000303e:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
40003041:	8b 45 0c             	mov    0xc(%ebp),%eax
40003044:	89 d3                	mov    %edx,%ebx
40003046:	29 c3                	sub    %eax,%ebx
40003048:	89 d8                	mov    %ebx,%eax
4000304a:	89 ca                	mov    %ecx,%edx
4000304c:	29 c2                	sub    %eax,%edx
4000304e:	8b 45 08             	mov    0x8(%ebp),%eax
40003051:	89 50 0c             	mov    %edx,0xc(%eax)

	if (!(st->flags & F_RPAD))	// print left-side padding
40003054:	8b 45 08             	mov    0x8(%ebp),%eax
40003057:	8b 40 18             	mov    0x18(%eax),%eax
4000305a:	83 e0 10             	and    $0x10,%eax
4000305d:	85 c0                	test   %eax,%eax
4000305f:	75 32                	jne    40003093 <putstr+0xac>
		putpad(st);		// (also leaves st->width == 0)
40003061:	8b 45 08             	mov    0x8(%ebp),%eax
40003064:	89 04 24             	mov    %eax,(%esp)
40003067:	e8 3e ff ff ff       	call   40002faa <putpad>
	while (str < lim) {
4000306c:	eb 25                	jmp    40003093 <putstr+0xac>
		char ch = *str++;
4000306e:	8b 45 0c             	mov    0xc(%ebp),%eax
40003071:	0f b6 00             	movzbl (%eax),%eax
40003074:	88 45 fb             	mov    %al,0xfffffffb(%ebp)
40003077:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
			st->putch(ch, st->putdat);
4000307b:	8b 45 08             	mov    0x8(%ebp),%eax
4000307e:	8b 08                	mov    (%eax),%ecx
40003080:	8b 45 08             	mov    0x8(%ebp),%eax
40003083:	8b 40 04             	mov    0x4(%eax),%eax
40003086:	0f be 55 fb          	movsbl 0xfffffffb(%ebp),%edx
4000308a:	89 44 24 04          	mov    %eax,0x4(%esp)
4000308e:	89 14 24             	mov    %edx,(%esp)
40003091:	ff d1                	call   *%ecx
40003093:	8b 45 0c             	mov    0xc(%ebp),%eax
40003096:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
40003099:	72 d3                	jb     4000306e <putstr+0x87>
	}
	putpad(st);			// print right-side padding
4000309b:	8b 45 08             	mov    0x8(%ebp),%eax
4000309e:	89 04 24             	mov    %eax,(%esp)
400030a1:	e8 04 ff ff ff       	call   40002faa <putpad>
}
400030a6:	83 c4 24             	add    $0x24,%esp
400030a9:	5b                   	pop    %ebx
400030aa:	5d                   	pop    %ebp
400030ab:	c3                   	ret    

400030ac <genint>:

// Generate a number (base <= 16) in reverse order into a string buffer.
static char *
genint(printstate *st, char *p, uintmax_t num)
{
400030ac:	55                   	push   %ebp
400030ad:	89 e5                	mov    %esp,%ebp
400030af:	53                   	push   %ebx
400030b0:	83 ec 24             	sub    $0x24,%esp
400030b3:	8b 45 10             	mov    0x10(%ebp),%eax
400030b6:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
400030b9:	8b 45 14             	mov    0x14(%ebp),%eax
400030bc:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= st->base)
400030bf:	8b 45 08             	mov    0x8(%ebp),%eax
400030c2:	8b 40 1c             	mov    0x1c(%eax),%eax
400030c5:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
400030c8:	89 c2                	mov    %eax,%edx
400030ca:	c1 fa 1f             	sar    $0x1f,%edx
400030cd:	89 55 ec             	mov    %edx,0xffffffec(%ebp)
400030d0:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
400030d3:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
400030d6:	77 54                	ja     4000312c <genint+0x80>
400030d8:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
400030db:	3b 55 f4             	cmp    0xfffffff4(%ebp),%edx
400030de:	72 08                	jb     400030e8 <genint+0x3c>
400030e0:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
400030e3:	3b 45 f0             	cmp    0xfffffff0(%ebp),%eax
400030e6:	77 44                	ja     4000312c <genint+0x80>
		p = genint(st, p, num / st->base);	// output higher digits
400030e8:	8b 45 08             	mov    0x8(%ebp),%eax
400030eb:	8b 40 1c             	mov    0x1c(%eax),%eax
400030ee:	89 c2                	mov    %eax,%edx
400030f0:	c1 fa 1f             	sar    $0x1f,%edx
400030f3:	89 44 24 08          	mov    %eax,0x8(%esp)
400030f7:	89 54 24 0c          	mov    %edx,0xc(%esp)
400030fb:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
400030fe:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
40003101:	89 04 24             	mov    %eax,(%esp)
40003104:	89 54 24 04          	mov    %edx,0x4(%esp)
40003108:	e8 83 08 00 00       	call   40003990 <__udivdi3>
4000310d:	89 44 24 08          	mov    %eax,0x8(%esp)
40003111:	89 54 24 0c          	mov    %edx,0xc(%esp)
40003115:	8b 45 0c             	mov    0xc(%ebp),%eax
40003118:	89 44 24 04          	mov    %eax,0x4(%esp)
4000311c:	8b 45 08             	mov    0x8(%ebp),%eax
4000311f:	89 04 24             	mov    %eax,(%esp)
40003122:	e8 85 ff ff ff       	call   400030ac <genint>
40003127:	89 45 0c             	mov    %eax,0xc(%ebp)
4000312a:	eb 1b                	jmp    40003147 <genint+0x9b>
	else if (st->signc >= 0)
4000312c:	8b 45 08             	mov    0x8(%ebp),%eax
4000312f:	8b 40 14             	mov    0x14(%eax),%eax
40003132:	85 c0                	test   %eax,%eax
40003134:	78 11                	js     40003147 <genint+0x9b>
		*p++ = st->signc;			// output leading sign
40003136:	8b 45 08             	mov    0x8(%ebp),%eax
40003139:	8b 40 14             	mov    0x14(%eax),%eax
4000313c:	89 c2                	mov    %eax,%edx
4000313e:	8b 45 0c             	mov    0xc(%ebp),%eax
40003141:	88 10                	mov    %dl,(%eax)
40003143:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
	*p++ = "0123456789abcdef"[num % st->base];	// output this digit
40003147:	8b 45 08             	mov    0x8(%ebp),%eax
4000314a:	8b 40 1c             	mov    0x1c(%eax),%eax
4000314d:	89 c2                	mov    %eax,%edx
4000314f:	c1 fa 1f             	sar    $0x1f,%edx
40003152:	8b 4d f0             	mov    0xfffffff0(%ebp),%ecx
40003155:	8b 5d f4             	mov    0xfffffff4(%ebp),%ebx
40003158:	89 44 24 08          	mov    %eax,0x8(%esp)
4000315c:	89 54 24 0c          	mov    %edx,0xc(%esp)
40003160:	89 0c 24             	mov    %ecx,(%esp)
40003163:	89 5c 24 04          	mov    %ebx,0x4(%esp)
40003167:	e8 54 09 00 00       	call   40003ac0 <__umoddi3>
4000316c:	05 a0 45 00 40       	add    $0x400045a0,%eax
40003171:	0f b6 10             	movzbl (%eax),%edx
40003174:	8b 45 0c             	mov    0xc(%ebp),%eax
40003177:	88 10                	mov    %dl,(%eax)
40003179:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
	return p;
4000317d:	8b 45 0c             	mov    0xc(%ebp),%eax
}
40003180:	83 c4 24             	add    $0x24,%esp
40003183:	5b                   	pop    %ebx
40003184:	5d                   	pop    %ebp
40003185:	c3                   	ret    

40003186 <putint>:

// Print an integer with any appropriate field padding.
static void
putint(printstate *st, uintmax_t num, int base)
{
40003186:	55                   	push   %ebp
40003187:	89 e5                	mov    %esp,%ebp
40003189:	83 ec 48             	sub    $0x48,%esp
4000318c:	8b 45 0c             	mov    0xc(%ebp),%eax
4000318f:	89 45 c8             	mov    %eax,0xffffffc8(%ebp)
40003192:	8b 45 10             	mov    0x10(%ebp),%eax
40003195:	89 45 cc             	mov    %eax,0xffffffcc(%ebp)
	char buf[30], *p = buf;		// big enough for any 64-bit int in octal
40003198:	8d 45 de             	lea    0xffffffde(%ebp),%eax
4000319b:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	st->base = base;		// select base for genint
4000319e:	8b 55 08             	mov    0x8(%ebp),%edx
400031a1:	8b 45 14             	mov    0x14(%ebp),%eax
400031a4:	89 42 1c             	mov    %eax,0x1c(%edx)
	p = genint(st, p, num);		// output to the string buffer
400031a7:	8b 45 c8             	mov    0xffffffc8(%ebp),%eax
400031aa:	8b 55 cc             	mov    0xffffffcc(%ebp),%edx
400031ad:	89 44 24 08          	mov    %eax,0x8(%esp)
400031b1:	89 54 24 0c          	mov    %edx,0xc(%esp)
400031b5:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
400031b8:	89 44 24 04          	mov    %eax,0x4(%esp)
400031bc:	8b 45 08             	mov    0x8(%ebp),%eax
400031bf:	89 04 24             	mov    %eax,(%esp)
400031c2:	e8 e5 fe ff ff       	call   400030ac <genint>
400031c7:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	putstr(st, buf, p-buf);		// print it with left/right padding
400031ca:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
400031cd:	8d 45 de             	lea    0xffffffde(%ebp),%eax
400031d0:	89 d1                	mov    %edx,%ecx
400031d2:	29 c1                	sub    %eax,%ecx
400031d4:	89 c8                	mov    %ecx,%eax
400031d6:	89 44 24 08          	mov    %eax,0x8(%esp)
400031da:	8d 45 de             	lea    0xffffffde(%ebp),%eax
400031dd:	89 44 24 04          	mov    %eax,0x4(%esp)
400031e1:	8b 45 08             	mov    0x8(%ebp),%eax
400031e4:	89 04 24             	mov    %eax,(%esp)
400031e7:	e8 fb fd ff ff       	call   40002fe7 <putstr>
}
400031ec:	c9                   	leave  
400031ed:	c3                   	ret    

400031ee <vprintfmt>:
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
400031ee:	55                   	push   %ebp
400031ef:	89 e5                	mov    %esp,%ebp
400031f1:	57                   	push   %edi
400031f2:	83 ec 54             	sub    $0x54,%esp
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
400031f5:	8d 7d c8             	lea    0xffffffc8(%ebp),%edi
400031f8:	fc                   	cld    
400031f9:	ba 00 00 00 00       	mov    $0x0,%edx
400031fe:	b8 08 00 00 00       	mov    $0x8,%eax
40003203:	89 c1                	mov    %eax,%ecx
40003205:	89 d0                	mov    %edx,%eax
40003207:	f3 ab                	rep stos %eax,%es:(%edi)
40003209:	8b 45 08             	mov    0x8(%ebp),%eax
4000320c:	89 45 c8             	mov    %eax,0xffffffc8(%ebp)
4000320f:	8b 45 0c             	mov    0xc(%ebp),%eax
40003212:	89 45 cc             	mov    %eax,0xffffffcc(%ebp)
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
40003215:	eb 1c                	jmp    40003233 <vprintfmt+0x45>
			if (ch == '\0')
40003217:	83 7d c4 00          	cmpl   $0x0,0xffffffc4(%ebp)
4000321b:	0f 84 73 03 00 00    	je     40003594 <vprintfmt+0x3a6>
				return;
			putch(ch, putdat);
40003221:	8b 45 0c             	mov    0xc(%ebp),%eax
40003224:	89 44 24 04          	mov    %eax,0x4(%esp)
40003228:	8b 55 c4             	mov    0xffffffc4(%ebp),%edx
4000322b:	89 14 24             	mov    %edx,(%esp)
4000322e:	8b 45 08             	mov    0x8(%ebp),%eax
40003231:	ff d0                	call   *%eax
40003233:	8b 45 10             	mov    0x10(%ebp),%eax
40003236:	0f b6 00             	movzbl (%eax),%eax
40003239:	0f b6 c0             	movzbl %al,%eax
4000323c:	89 45 c4             	mov    %eax,0xffffffc4(%ebp)
4000323f:	83 7d c4 25          	cmpl   $0x25,0xffffffc4(%ebp)
40003243:	0f 95 c0             	setne  %al
40003246:	83 45 10 01          	addl   $0x1,0x10(%ebp)
4000324a:	84 c0                	test   %al,%al
4000324c:	75 c9                	jne    40003217 <vprintfmt+0x29>
		}

		// Process a %-escape sequence
		st.padc = ' ';
4000324e:	c7 45 d0 20 00 00 00 	movl   $0x20,0xffffffd0(%ebp)
		st.width = -1;
40003255:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,0xffffffd4(%ebp)
		st.prec = -1;
4000325c:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,0xffffffd8(%ebp)
		st.signc = -1;
40003263:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,0xffffffdc(%ebp)
		st.flags = 0;
4000326a:	c7 45 e0 00 00 00 00 	movl   $0x0,0xffffffe0(%ebp)
		st.base = 10;
40003271:	c7 45 e4 0a 00 00 00 	movl   $0xa,0xffffffe4(%ebp)
40003278:	eb 00                	jmp    4000327a <vprintfmt+0x8c>
		uintmax_t num;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
4000327a:	8b 45 10             	mov    0x10(%ebp),%eax
4000327d:	0f b6 00             	movzbl (%eax),%eax
40003280:	0f b6 c0             	movzbl %al,%eax
40003283:	89 45 c4             	mov    %eax,0xffffffc4(%ebp)
40003286:	8b 45 c4             	mov    0xffffffc4(%ebp),%eax
40003289:	83 45 10 01          	addl   $0x1,0x10(%ebp)
4000328d:	83 e8 20             	sub    $0x20,%eax
40003290:	89 45 b8             	mov    %eax,0xffffffb8(%ebp)
40003293:	83 7d b8 58          	cmpl   $0x58,0xffffffb8(%ebp)
40003297:	0f 87 c8 02 00 00    	ja     40003565 <vprintfmt+0x377>
4000329d:	8b 55 b8             	mov    0xffffffb8(%ebp),%edx
400032a0:	8b 04 95 b8 45 00 40 	mov    0x400045b8(,%edx,4),%eax
400032a7:	ff e0                	jmp    *%eax

		// modifier flags
		case '-': // pad on the right instead of the left
			st.flags |= F_RPAD;
400032a9:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
400032ac:	83 c8 10             	or     $0x10,%eax
400032af:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)
			goto reswitch;
400032b2:	eb c6                	jmp    4000327a <vprintfmt+0x8c>

		case '+': // prefix positive numeric values with a '+' sign
			st.signc = '+';
400032b4:	c7 45 dc 2b 00 00 00 	movl   $0x2b,0xffffffdc(%ebp)
			goto reswitch;
400032bb:	eb bd                	jmp    4000327a <vprintfmt+0x8c>

		case ' ': // prefix signless numeric values with a space
			if (st.signc < 0)	// (but only if no '+' is specified)
400032bd:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
400032c0:	85 c0                	test   %eax,%eax
400032c2:	79 b6                	jns    4000327a <vprintfmt+0x8c>
				st.signc = ' ';
400032c4:	c7 45 dc 20 00 00 00 	movl   $0x20,0xffffffdc(%ebp)
			goto reswitch;
400032cb:	eb ad                	jmp    4000327a <vprintfmt+0x8c>

		// width or precision field
		case '0':
			if (!(st.flags & F_DOT))
400032cd:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
400032d0:	83 e0 08             	and    $0x8,%eax
400032d3:	85 c0                	test   %eax,%eax
400032d5:	75 07                	jne    400032de <vprintfmt+0xf0>
				st.padc = '0'; // pad with 0's instead of spaces
400032d7:	c7 45 d0 30 00 00 00 	movl   $0x30,0xffffffd0(%ebp)
		case '1': case '2': case '3': case '4':
		case '5': case '6': case '7': case '8': case '9':
			for (st.prec = 0; ; ++fmt) {
400032de:	c7 45 d8 00 00 00 00 	movl   $0x0,0xffffffd8(%ebp)
				st.prec = st.prec * 10 + ch - '0';
400032e5:	8b 55 d8             	mov    0xffffffd8(%ebp),%edx
400032e8:	89 d0                	mov    %edx,%eax
400032ea:	c1 e0 02             	shl    $0x2,%eax
400032ed:	01 d0                	add    %edx,%eax
400032ef:	01 c0                	add    %eax,%eax
400032f1:	03 45 c4             	add    0xffffffc4(%ebp),%eax
400032f4:	83 e8 30             	sub    $0x30,%eax
400032f7:	89 45 d8             	mov    %eax,0xffffffd8(%ebp)
				ch = *fmt;
400032fa:	8b 45 10             	mov    0x10(%ebp),%eax
400032fd:	0f b6 00             	movzbl (%eax),%eax
40003300:	0f be c0             	movsbl %al,%eax
40003303:	89 45 c4             	mov    %eax,0xffffffc4(%ebp)
				if (ch < '0' || ch > '9')
40003306:	83 7d c4 2f          	cmpl   $0x2f,0xffffffc4(%ebp)
4000330a:	7e 20                	jle    4000332c <vprintfmt+0x13e>
4000330c:	83 7d c4 39          	cmpl   $0x39,0xffffffc4(%ebp)
40003310:	7f 1a                	jg     4000332c <vprintfmt+0x13e>
40003312:	83 45 10 01          	addl   $0x1,0x10(%ebp)
					break;
			}
40003316:	eb cd                	jmp    400032e5 <vprintfmt+0xf7>
			goto gotprec;

		case '*':
			st.prec = va_arg(ap, int);
40003318:	8b 45 14             	mov    0x14(%ebp),%eax
4000331b:	83 c0 04             	add    $0x4,%eax
4000331e:	89 45 14             	mov    %eax,0x14(%ebp)
40003321:	8b 45 14             	mov    0x14(%ebp),%eax
40003324:	83 e8 04             	sub    $0x4,%eax
40003327:	8b 00                	mov    (%eax),%eax
40003329:	89 45 d8             	mov    %eax,0xffffffd8(%ebp)
		gotprec:
			if (!(st.flags & F_DOT)) {	// haven't seen a '.' yet?
4000332c:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
4000332f:	83 e0 08             	and    $0x8,%eax
40003332:	85 c0                	test   %eax,%eax
40003334:	0f 85 40 ff ff ff    	jne    4000327a <vprintfmt+0x8c>
				st.width = st.prec;	// then it's a field width
4000333a:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
4000333d:	89 45 d4             	mov    %eax,0xffffffd4(%ebp)
				st.prec = -1;
40003340:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,0xffffffd8(%ebp)
			}
			goto reswitch;
40003347:	e9 2e ff ff ff       	jmp    4000327a <vprintfmt+0x8c>

		case '.':
			st.flags |= F_DOT;
4000334c:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
4000334f:	83 c8 08             	or     $0x8,%eax
40003352:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)
			goto reswitch;
40003355:	e9 20 ff ff ff       	jmp    4000327a <vprintfmt+0x8c>

		case '#':
			st.flags |= F_ALT;
4000335a:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
4000335d:	83 c8 04             	or     $0x4,%eax
40003360:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)
			goto reswitch;
40003363:	e9 12 ff ff ff       	jmp    4000327a <vprintfmt+0x8c>

		// long flag (doubled for long long)
		case 'l':
			st.flags |= (st.flags & F_L) ? F_LL : F_L;
40003368:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
4000336b:	89 45 bc             	mov    %eax,0xffffffbc(%ebp)
4000336e:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
40003371:	83 e0 01             	and    $0x1,%eax
40003374:	84 c0                	test   %al,%al
40003376:	74 09                	je     40003381 <vprintfmt+0x193>
40003378:	c7 45 c0 02 00 00 00 	movl   $0x2,0xffffffc0(%ebp)
4000337f:	eb 07                	jmp    40003388 <vprintfmt+0x19a>
40003381:	c7 45 c0 01 00 00 00 	movl   $0x1,0xffffffc0(%ebp)
40003388:	8b 45 bc             	mov    0xffffffbc(%ebp),%eax
4000338b:	0b 45 c0             	or     0xffffffc0(%ebp),%eax
4000338e:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)
			goto reswitch;
40003391:	e9 e4 fe ff ff       	jmp    4000327a <vprintfmt+0x8c>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
40003396:	8b 45 14             	mov    0x14(%ebp),%eax
40003399:	83 c0 04             	add    $0x4,%eax
4000339c:	89 45 14             	mov    %eax,0x14(%ebp)
4000339f:	8b 45 14             	mov    0x14(%ebp),%eax
400033a2:	83 e8 04             	sub    $0x4,%eax
400033a5:	8b 10                	mov    (%eax),%edx
400033a7:	8b 45 0c             	mov    0xc(%ebp),%eax
400033aa:	89 44 24 04          	mov    %eax,0x4(%esp)
400033ae:	89 14 24             	mov    %edx,(%esp)
400033b1:	8b 45 08             	mov    0x8(%ebp),%eax
400033b4:	ff d0                	call   *%eax
			break;
400033b6:	e9 78 fe ff ff       	jmp    40003233 <vprintfmt+0x45>

		// string
		case 's': {
			const char *s;
			if ((s = va_arg(ap, char *)) == NULL)
400033bb:	8b 45 14             	mov    0x14(%ebp),%eax
400033be:	83 c0 04             	add    $0x4,%eax
400033c1:	89 45 14             	mov    %eax,0x14(%ebp)
400033c4:	8b 45 14             	mov    0x14(%ebp),%eax
400033c7:	83 e8 04             	sub    $0x4,%eax
400033ca:	8b 00                	mov    (%eax),%eax
400033cc:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
400033cf:	83 7d f4 00          	cmpl   $0x0,0xfffffff4(%ebp)
400033d3:	75 07                	jne    400033dc <vprintfmt+0x1ee>
				s = "(null)";
400033d5:	c7 45 f4 b1 45 00 40 	movl   $0x400045b1,0xfffffff4(%ebp)
			putstr(&st, s, st.prec);
400033dc:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
400033df:	89 44 24 08          	mov    %eax,0x8(%esp)
400033e3:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
400033e6:	89 44 24 04          	mov    %eax,0x4(%esp)
400033ea:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
400033ed:	89 04 24             	mov    %eax,(%esp)
400033f0:	e8 f2 fb ff ff       	call   40002fe7 <putstr>
			break;
400033f5:	e9 39 fe ff ff       	jmp    40003233 <vprintfmt+0x45>
		    }

		// (signed) decimal
		case 'd':
			num = getint(&st, &ap);
400033fa:	8d 45 14             	lea    0x14(%ebp),%eax
400033fd:	89 44 24 04          	mov    %eax,0x4(%esp)
40003401:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
40003404:	89 04 24             	mov    %eax,(%esp)
40003407:	e8 0e fb ff ff       	call   40002f1a <getint>
4000340c:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
4000340f:	89 55 ec             	mov    %edx,0xffffffec(%ebp)
			if ((intmax_t) num < 0) {
40003412:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
40003415:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
40003418:	85 d2                	test   %edx,%edx
4000341a:	79 1a                	jns    40003436 <vprintfmt+0x248>
				num = -(intmax_t) num;
4000341c:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
4000341f:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
40003422:	f7 d8                	neg    %eax
40003424:	83 d2 00             	adc    $0x0,%edx
40003427:	f7 da                	neg    %edx
40003429:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
4000342c:	89 55 ec             	mov    %edx,0xffffffec(%ebp)
				st.signc = '-';
4000342f:	c7 45 dc 2d 00 00 00 	movl   $0x2d,0xffffffdc(%ebp)
			}
			putint(&st, num, 10);
40003436:	c7 44 24 0c 0a 00 00 	movl   $0xa,0xc(%esp)
4000343d:	00 
4000343e:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
40003441:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
40003444:	89 44 24 04          	mov    %eax,0x4(%esp)
40003448:	89 54 24 08          	mov    %edx,0x8(%esp)
4000344c:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
4000344f:	89 04 24             	mov    %eax,(%esp)
40003452:	e8 2f fd ff ff       	call   40003186 <putint>
			break;
40003457:	e9 d7 fd ff ff       	jmp    40003233 <vprintfmt+0x45>

		// unsigned decimal
		case 'u':
			putint(&st, getuint(&st, &ap), 10);
4000345c:	8d 45 14             	lea    0x14(%ebp),%eax
4000345f:	89 44 24 04          	mov    %eax,0x4(%esp)
40003463:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
40003466:	89 04 24             	mov    %eax,(%esp)
40003469:	e8 1e fa ff ff       	call   40002e8c <getuint>
4000346e:	c7 44 24 0c 0a 00 00 	movl   $0xa,0xc(%esp)
40003475:	00 
40003476:	89 44 24 04          	mov    %eax,0x4(%esp)
4000347a:	89 54 24 08          	mov    %edx,0x8(%esp)
4000347e:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
40003481:	89 04 24             	mov    %eax,(%esp)
40003484:	e8 fd fc ff ff       	call   40003186 <putint>
			break;
40003489:	e9 a5 fd ff ff       	jmp    40003233 <vprintfmt+0x45>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putint(&st, getuint(&st, &ap), 8);
4000348e:	8d 45 14             	lea    0x14(%ebp),%eax
40003491:	89 44 24 04          	mov    %eax,0x4(%esp)
40003495:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
40003498:	89 04 24             	mov    %eax,(%esp)
4000349b:	e8 ec f9 ff ff       	call   40002e8c <getuint>
400034a0:	c7 44 24 0c 08 00 00 	movl   $0x8,0xc(%esp)
400034a7:	00 
400034a8:	89 44 24 04          	mov    %eax,0x4(%esp)
400034ac:	89 54 24 08          	mov    %edx,0x8(%esp)
400034b0:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
400034b3:	89 04 24             	mov    %eax,(%esp)
400034b6:	e8 cb fc ff ff       	call   40003186 <putint>
			break;
400034bb:	e9 73 fd ff ff       	jmp    40003233 <vprintfmt+0x45>

		// (unsigned) hexadecimal
		case 'x':
			putint(&st, getuint(&st, &ap), 16);
400034c0:	8d 45 14             	lea    0x14(%ebp),%eax
400034c3:	89 44 24 04          	mov    %eax,0x4(%esp)
400034c7:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
400034ca:	89 04 24             	mov    %eax,(%esp)
400034cd:	e8 ba f9 ff ff       	call   40002e8c <getuint>
400034d2:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
400034d9:	00 
400034da:	89 44 24 04          	mov    %eax,0x4(%esp)
400034de:	89 54 24 08          	mov    %edx,0x8(%esp)
400034e2:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
400034e5:	89 04 24             	mov    %eax,(%esp)
400034e8:	e8 99 fc ff ff       	call   40003186 <putint>
			break;
400034ed:	e9 41 fd ff ff       	jmp    40003233 <vprintfmt+0x45>

		// pointer
		case 'p':
			putch('0', putdat);
400034f2:	8b 45 0c             	mov    0xc(%ebp),%eax
400034f5:	89 44 24 04          	mov    %eax,0x4(%esp)
400034f9:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
40003500:	8b 45 08             	mov    0x8(%ebp),%eax
40003503:	ff d0                	call   *%eax
			putch('x', putdat);
40003505:	8b 45 0c             	mov    0xc(%ebp),%eax
40003508:	89 44 24 04          	mov    %eax,0x4(%esp)
4000350c:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
40003513:	8b 45 08             	mov    0x8(%ebp),%eax
40003516:	ff d0                	call   *%eax
			putint(&st, (uintptr_t) va_arg(ap, void *), 16);
40003518:	8b 45 14             	mov    0x14(%ebp),%eax
4000351b:	83 c0 04             	add    $0x4,%eax
4000351e:	89 45 14             	mov    %eax,0x14(%ebp)
40003521:	8b 45 14             	mov    0x14(%ebp),%eax
40003524:	83 e8 04             	sub    $0x4,%eax
40003527:	8b 00                	mov    (%eax),%eax
40003529:	ba 00 00 00 00       	mov    $0x0,%edx
4000352e:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
40003535:	00 
40003536:	89 44 24 04          	mov    %eax,0x4(%esp)
4000353a:	89 54 24 08          	mov    %edx,0x8(%esp)
4000353e:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
40003541:	89 04 24             	mov    %eax,(%esp)
40003544:	e8 3d fc ff ff       	call   40003186 <putint>
			break;
40003549:	e9 e5 fc ff ff       	jmp    40003233 <vprintfmt+0x45>
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
4000354e:	8b 45 0c             	mov    0xc(%ebp),%eax
40003551:	89 44 24 04          	mov    %eax,0x4(%esp)
40003555:	8b 55 c4             	mov    0xffffffc4(%ebp),%edx
40003558:	89 14 24             	mov    %edx,(%esp)
4000355b:	8b 45 08             	mov    0x8(%ebp),%eax
4000355e:	ff d0                	call   *%eax
			break;
40003560:	e9 ce fc ff ff       	jmp    40003233 <vprintfmt+0x45>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
40003565:	8b 45 0c             	mov    0xc(%ebp),%eax
40003568:	89 44 24 04          	mov    %eax,0x4(%esp)
4000356c:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
40003573:	8b 45 08             	mov    0x8(%ebp),%eax
40003576:	ff d0                	call   *%eax
			for (fmt--; fmt[-1] != '%'; fmt--)
40003578:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
4000357c:	eb 04                	jmp    40003582 <vprintfmt+0x394>
4000357e:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
40003582:	8b 45 10             	mov    0x10(%ebp),%eax
40003585:	83 e8 01             	sub    $0x1,%eax
40003588:	0f b6 00             	movzbl (%eax),%eax
4000358b:	3c 25                	cmp    $0x25,%al
4000358d:	75 ef                	jne    4000357e <vprintfmt+0x390>
				/* do nothing */;
			break;
		}
	}
4000358f:	e9 9f fc ff ff       	jmp    40003233 <vprintfmt+0x45>
}
40003594:	83 c4 54             	add    $0x54,%esp
40003597:	5f                   	pop    %edi
40003598:	5d                   	pop    %ebp
40003599:	c3                   	ret    
4000359a:	90                   	nop    
4000359b:	90                   	nop    

4000359c <strlen>:
#define ASM 1

int
strlen(const char *s)
{
4000359c:	55                   	push   %ebp
4000359d:	89 e5                	mov    %esp,%ebp
4000359f:	83 ec 10             	sub    $0x10,%esp
	int n;

	for (n = 0; *s != '\0'; s++)
400035a2:	c7 45 fc 00 00 00 00 	movl   $0x0,0xfffffffc(%ebp)
400035a9:	eb 08                	jmp    400035b3 <strlen+0x17>
		n++;
400035ab:	83 45 fc 01          	addl   $0x1,0xfffffffc(%ebp)
400035af:	83 45 08 01          	addl   $0x1,0x8(%ebp)
400035b3:	8b 45 08             	mov    0x8(%ebp),%eax
400035b6:	0f b6 00             	movzbl (%eax),%eax
400035b9:	84 c0                	test   %al,%al
400035bb:	75 ee                	jne    400035ab <strlen+0xf>
	return n;
400035bd:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
}
400035c0:	c9                   	leave  
400035c1:	c3                   	ret    

400035c2 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
400035c2:	55                   	push   %ebp
400035c3:	89 e5                	mov    %esp,%ebp
400035c5:	83 ec 10             	sub    $0x10,%esp
	char *ret;

	ret = dst;
400035c8:	8b 45 08             	mov    0x8(%ebp),%eax
400035cb:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	while ((*dst++ = *src++) != '\0')
400035ce:	8b 45 0c             	mov    0xc(%ebp),%eax
400035d1:	0f b6 10             	movzbl (%eax),%edx
400035d4:	8b 45 08             	mov    0x8(%ebp),%eax
400035d7:	88 10                	mov    %dl,(%eax)
400035d9:	8b 45 08             	mov    0x8(%ebp),%eax
400035dc:	0f b6 00             	movzbl (%eax),%eax
400035df:	84 c0                	test   %al,%al
400035e1:	0f 95 c0             	setne  %al
400035e4:	83 45 08 01          	addl   $0x1,0x8(%ebp)
400035e8:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
400035ec:	84 c0                	test   %al,%al
400035ee:	75 de                	jne    400035ce <strcpy+0xc>
		/* do nothing */;
	return ret;
400035f0:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
}
400035f3:	c9                   	leave  
400035f4:	c3                   	ret    

400035f5 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size)
{
400035f5:	55                   	push   %ebp
400035f6:	89 e5                	mov    %esp,%ebp
400035f8:	83 ec 10             	sub    $0x10,%esp
	size_t i;
	char *ret;

	ret = dst;
400035fb:	8b 45 08             	mov    0x8(%ebp),%eax
400035fe:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	for (i = 0; i < size; i++) {
40003601:	c7 45 f8 00 00 00 00 	movl   $0x0,0xfffffff8(%ebp)
40003608:	eb 21                	jmp    4000362b <strncpy+0x36>
		*dst++ = *src;
4000360a:	8b 45 0c             	mov    0xc(%ebp),%eax
4000360d:	0f b6 10             	movzbl (%eax),%edx
40003610:	8b 45 08             	mov    0x8(%ebp),%eax
40003613:	88 10                	mov    %dl,(%eax)
40003615:	83 45 08 01          	addl   $0x1,0x8(%ebp)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
40003619:	8b 45 0c             	mov    0xc(%ebp),%eax
4000361c:	0f b6 00             	movzbl (%eax),%eax
4000361f:	84 c0                	test   %al,%al
40003621:	74 04                	je     40003627 <strncpy+0x32>
			src++;
40003623:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
40003627:	83 45 f8 01          	addl   $0x1,0xfffffff8(%ebp)
4000362b:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
4000362e:	3b 45 10             	cmp    0x10(%ebp),%eax
40003631:	72 d7                	jb     4000360a <strncpy+0x15>
	}
	return ret;
40003633:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
}
40003636:	c9                   	leave  
40003637:	c3                   	ret    

40003638 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
40003638:	55                   	push   %ebp
40003639:	89 e5                	mov    %esp,%ebp
4000363b:	83 ec 10             	sub    $0x10,%esp
	char *dst_in;

	dst_in = dst;
4000363e:	8b 45 08             	mov    0x8(%ebp),%eax
40003641:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	if (size > 0) {
40003644:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
40003648:	74 2f                	je     40003679 <strlcpy+0x41>
		while (--size > 0 && *src != '\0')
4000364a:	eb 13                	jmp    4000365f <strlcpy+0x27>
			*dst++ = *src++;
4000364c:	8b 45 0c             	mov    0xc(%ebp),%eax
4000364f:	0f b6 10             	movzbl (%eax),%edx
40003652:	8b 45 08             	mov    0x8(%ebp),%eax
40003655:	88 10                	mov    %dl,(%eax)
40003657:	83 45 08 01          	addl   $0x1,0x8(%ebp)
4000365b:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
4000365f:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
40003663:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
40003667:	74 0a                	je     40003673 <strlcpy+0x3b>
40003669:	8b 45 0c             	mov    0xc(%ebp),%eax
4000366c:	0f b6 00             	movzbl (%eax),%eax
4000366f:	84 c0                	test   %al,%al
40003671:	75 d9                	jne    4000364c <strlcpy+0x14>
		*dst = '\0';
40003673:	8b 45 08             	mov    0x8(%ebp),%eax
40003676:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
40003679:	8b 55 08             	mov    0x8(%ebp),%edx
4000367c:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
4000367f:	89 d1                	mov    %edx,%ecx
40003681:	29 c1                	sub    %eax,%ecx
40003683:	89 c8                	mov    %ecx,%eax
}
40003685:	c9                   	leave  
40003686:	c3                   	ret    

40003687 <strcmp>:

int
strcmp(const char *p, const char *q)
{
40003687:	55                   	push   %ebp
40003688:	89 e5                	mov    %esp,%ebp
	while (*p && *p == *q)
4000368a:	eb 08                	jmp    40003694 <strcmp+0xd>
		p++, q++;
4000368c:	83 45 08 01          	addl   $0x1,0x8(%ebp)
40003690:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
40003694:	8b 45 08             	mov    0x8(%ebp),%eax
40003697:	0f b6 00             	movzbl (%eax),%eax
4000369a:	84 c0                	test   %al,%al
4000369c:	74 10                	je     400036ae <strcmp+0x27>
4000369e:	8b 45 08             	mov    0x8(%ebp),%eax
400036a1:	0f b6 10             	movzbl (%eax),%edx
400036a4:	8b 45 0c             	mov    0xc(%ebp),%eax
400036a7:	0f b6 00             	movzbl (%eax),%eax
400036aa:	38 c2                	cmp    %al,%dl
400036ac:	74 de                	je     4000368c <strcmp+0x5>
	return (int) ((unsigned char) *p - (unsigned char) *q);
400036ae:	8b 45 08             	mov    0x8(%ebp),%eax
400036b1:	0f b6 00             	movzbl (%eax),%eax
400036b4:	0f b6 d0             	movzbl %al,%edx
400036b7:	8b 45 0c             	mov    0xc(%ebp),%eax
400036ba:	0f b6 00             	movzbl (%eax),%eax
400036bd:	0f b6 c0             	movzbl %al,%eax
400036c0:	89 d1                	mov    %edx,%ecx
400036c2:	29 c1                	sub    %eax,%ecx
400036c4:	89 c8                	mov    %ecx,%eax
}
400036c6:	5d                   	pop    %ebp
400036c7:	c3                   	ret    

400036c8 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
400036c8:	55                   	push   %ebp
400036c9:	89 e5                	mov    %esp,%ebp
400036cb:	83 ec 04             	sub    $0x4,%esp
	while (n > 0 && *p && *p == *q)
400036ce:	eb 0c                	jmp    400036dc <strncmp+0x14>
		n--, p++, q++;
400036d0:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
400036d4:	83 45 08 01          	addl   $0x1,0x8(%ebp)
400036d8:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
400036dc:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
400036e0:	74 1a                	je     400036fc <strncmp+0x34>
400036e2:	8b 45 08             	mov    0x8(%ebp),%eax
400036e5:	0f b6 00             	movzbl (%eax),%eax
400036e8:	84 c0                	test   %al,%al
400036ea:	74 10                	je     400036fc <strncmp+0x34>
400036ec:	8b 45 08             	mov    0x8(%ebp),%eax
400036ef:	0f b6 10             	movzbl (%eax),%edx
400036f2:	8b 45 0c             	mov    0xc(%ebp),%eax
400036f5:	0f b6 00             	movzbl (%eax),%eax
400036f8:	38 c2                	cmp    %al,%dl
400036fa:	74 d4                	je     400036d0 <strncmp+0x8>
	if (n == 0)
400036fc:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
40003700:	75 09                	jne    4000370b <strncmp+0x43>
		return 0;
40003702:	c7 45 fc 00 00 00 00 	movl   $0x0,0xfffffffc(%ebp)
40003709:	eb 19                	jmp    40003724 <strncmp+0x5c>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
4000370b:	8b 45 08             	mov    0x8(%ebp),%eax
4000370e:	0f b6 00             	movzbl (%eax),%eax
40003711:	0f b6 d0             	movzbl %al,%edx
40003714:	8b 45 0c             	mov    0xc(%ebp),%eax
40003717:	0f b6 00             	movzbl (%eax),%eax
4000371a:	0f b6 c0             	movzbl %al,%eax
4000371d:	89 d1                	mov    %edx,%ecx
4000371f:	29 c1                	sub    %eax,%ecx
40003721:	89 4d fc             	mov    %ecx,0xfffffffc(%ebp)
40003724:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
}
40003727:	c9                   	leave  
40003728:	c3                   	ret    

40003729 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
40003729:	55                   	push   %ebp
4000372a:	89 e5                	mov    %esp,%ebp
4000372c:	83 ec 08             	sub    $0x8,%esp
4000372f:	8b 45 0c             	mov    0xc(%ebp),%eax
40003732:	88 45 fc             	mov    %al,0xfffffffc(%ebp)
	while (*s != c)
40003735:	eb 1c                	jmp    40003753 <strchr+0x2a>
		if (*s++ == 0)
40003737:	8b 45 08             	mov    0x8(%ebp),%eax
4000373a:	0f b6 00             	movzbl (%eax),%eax
4000373d:	84 c0                	test   %al,%al
4000373f:	0f 94 c0             	sete   %al
40003742:	83 45 08 01          	addl   $0x1,0x8(%ebp)
40003746:	84 c0                	test   %al,%al
40003748:	74 09                	je     40003753 <strchr+0x2a>
			return NULL;
4000374a:	c7 45 f8 00 00 00 00 	movl   $0x0,0xfffffff8(%ebp)
40003751:	eb 11                	jmp    40003764 <strchr+0x3b>
40003753:	8b 45 08             	mov    0x8(%ebp),%eax
40003756:	0f b6 00             	movzbl (%eax),%eax
40003759:	3a 45 fc             	cmp    0xfffffffc(%ebp),%al
4000375c:	75 d9                	jne    40003737 <strchr+0xe>
	return (char *) s;
4000375e:	8b 45 08             	mov    0x8(%ebp),%eax
40003761:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
40003764:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
}
40003767:	c9                   	leave  
40003768:	c3                   	ret    

40003769 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
40003769:	55                   	push   %ebp
4000376a:	89 e5                	mov    %esp,%ebp
4000376c:	57                   	push   %edi
4000376d:	83 ec 14             	sub    $0x14,%esp
	char *p;

	if (n == 0)
40003770:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
40003774:	75 08                	jne    4000377e <memset+0x15>
		return v;
40003776:	8b 45 08             	mov    0x8(%ebp),%eax
40003779:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
4000377c:	eb 5b                	jmp    400037d9 <memset+0x70>
	if ((int)v%4 == 0 && n%4 == 0) {
4000377e:	8b 45 08             	mov    0x8(%ebp),%eax
40003781:	83 e0 03             	and    $0x3,%eax
40003784:	85 c0                	test   %eax,%eax
40003786:	75 3f                	jne    400037c7 <memset+0x5e>
40003788:	8b 45 10             	mov    0x10(%ebp),%eax
4000378b:	83 e0 03             	and    $0x3,%eax
4000378e:	85 c0                	test   %eax,%eax
40003790:	75 35                	jne    400037c7 <memset+0x5e>
		c &= 0xFF;
40003792:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
		c = (c<<24)|(c<<16)|(c<<8)|c;
40003799:	8b 45 0c             	mov    0xc(%ebp),%eax
4000379c:	89 c2                	mov    %eax,%edx
4000379e:	c1 e2 18             	shl    $0x18,%edx
400037a1:	8b 45 0c             	mov    0xc(%ebp),%eax
400037a4:	c1 e0 10             	shl    $0x10,%eax
400037a7:	09 c2                	or     %eax,%edx
400037a9:	8b 45 0c             	mov    0xc(%ebp),%eax
400037ac:	c1 e0 08             	shl    $0x8,%eax
400037af:	09 d0                	or     %edx,%eax
400037b1:	09 45 0c             	or     %eax,0xc(%ebp)
		asm volatile("cld; rep stosl\n"
400037b4:	8b 45 10             	mov    0x10(%ebp),%eax
400037b7:	89 c1                	mov    %eax,%ecx
400037b9:	c1 e9 02             	shr    $0x2,%ecx
400037bc:	8b 7d 08             	mov    0x8(%ebp),%edi
400037bf:	8b 45 0c             	mov    0xc(%ebp),%eax
400037c2:	fc                   	cld    
400037c3:	f3 ab                	rep stos %eax,%es:(%edi)
400037c5:	eb 0c                	jmp    400037d3 <memset+0x6a>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
400037c7:	8b 7d 08             	mov    0x8(%ebp),%edi
400037ca:	8b 45 0c             	mov    0xc(%ebp),%eax
400037cd:	8b 4d 10             	mov    0x10(%ebp),%ecx
400037d0:	fc                   	cld    
400037d1:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
400037d3:	8b 45 08             	mov    0x8(%ebp),%eax
400037d6:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
400037d9:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
}
400037dc:	83 c4 14             	add    $0x14,%esp
400037df:	5f                   	pop    %edi
400037e0:	5d                   	pop    %ebp
400037e1:	c3                   	ret    

400037e2 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
400037e2:	55                   	push   %ebp
400037e3:	89 e5                	mov    %esp,%ebp
400037e5:	57                   	push   %edi
400037e6:	56                   	push   %esi
400037e7:	83 ec 10             	sub    $0x10,%esp
	const char *s;
	char *d;
	
	s = src;
400037ea:	8b 45 0c             	mov    0xc(%ebp),%eax
400037ed:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
	d = dst;
400037f0:	8b 45 08             	mov    0x8(%ebp),%eax
400037f3:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	if (s < d && s + n > d) {
400037f6:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
400037f9:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
400037fc:	73 63                	jae    40003861 <memmove+0x7f>
400037fe:	8b 45 10             	mov    0x10(%ebp),%eax
40003801:	03 45 f0             	add    0xfffffff0(%ebp),%eax
40003804:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
40003807:	76 58                	jbe    40003861 <memmove+0x7f>
		s += n;
40003809:	8b 45 10             	mov    0x10(%ebp),%eax
4000380c:	01 45 f0             	add    %eax,0xfffffff0(%ebp)
		d += n;
4000380f:	8b 45 10             	mov    0x10(%ebp),%eax
40003812:	01 45 f4             	add    %eax,0xfffffff4(%ebp)
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
40003815:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
40003818:	83 e0 03             	and    $0x3,%eax
4000381b:	85 c0                	test   %eax,%eax
4000381d:	75 2d                	jne    4000384c <memmove+0x6a>
4000381f:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
40003822:	83 e0 03             	and    $0x3,%eax
40003825:	85 c0                	test   %eax,%eax
40003827:	75 23                	jne    4000384c <memmove+0x6a>
40003829:	8b 45 10             	mov    0x10(%ebp),%eax
4000382c:	83 e0 03             	and    $0x3,%eax
4000382f:	85 c0                	test   %eax,%eax
40003831:	75 19                	jne    4000384c <memmove+0x6a>
			asm volatile("std; rep movsl\n"
40003833:	8b 7d f4             	mov    0xfffffff4(%ebp),%edi
40003836:	83 ef 04             	sub    $0x4,%edi
40003839:	8b 75 f0             	mov    0xfffffff0(%ebp),%esi
4000383c:	83 ee 04             	sub    $0x4,%esi
4000383f:	8b 45 10             	mov    0x10(%ebp),%eax
40003842:	89 c1                	mov    %eax,%ecx
40003844:	c1 e9 02             	shr    $0x2,%ecx
40003847:	fd                   	std    
40003848:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
4000384a:	eb 12                	jmp    4000385e <memmove+0x7c>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
4000384c:	8b 7d f4             	mov    0xfffffff4(%ebp),%edi
4000384f:	83 ef 01             	sub    $0x1,%edi
40003852:	8b 75 f0             	mov    0xfffffff0(%ebp),%esi
40003855:	83 ee 01             	sub    $0x1,%esi
40003858:	8b 4d 10             	mov    0x10(%ebp),%ecx
4000385b:	fd                   	std    
4000385c:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
4000385e:	fc                   	cld    
4000385f:	eb 3d                	jmp    4000389e <memmove+0xbc>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
40003861:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
40003864:	83 e0 03             	and    $0x3,%eax
40003867:	85 c0                	test   %eax,%eax
40003869:	75 27                	jne    40003892 <memmove+0xb0>
4000386b:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
4000386e:	83 e0 03             	and    $0x3,%eax
40003871:	85 c0                	test   %eax,%eax
40003873:	75 1d                	jne    40003892 <memmove+0xb0>
40003875:	8b 45 10             	mov    0x10(%ebp),%eax
40003878:	83 e0 03             	and    $0x3,%eax
4000387b:	85 c0                	test   %eax,%eax
4000387d:	75 13                	jne    40003892 <memmove+0xb0>
			asm volatile("cld; rep movsl\n"
4000387f:	8b 45 10             	mov    0x10(%ebp),%eax
40003882:	89 c1                	mov    %eax,%ecx
40003884:	c1 e9 02             	shr    $0x2,%ecx
40003887:	8b 7d f4             	mov    0xfffffff4(%ebp),%edi
4000388a:	8b 75 f0             	mov    0xfffffff0(%ebp),%esi
4000388d:	fc                   	cld    
4000388e:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
40003890:	eb 0c                	jmp    4000389e <memmove+0xbc>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
40003892:	8b 7d f4             	mov    0xfffffff4(%ebp),%edi
40003895:	8b 75 f0             	mov    0xfffffff0(%ebp),%esi
40003898:	8b 4d 10             	mov    0x10(%ebp),%ecx
4000389b:	fc                   	cld    
4000389c:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
4000389e:	8b 45 08             	mov    0x8(%ebp),%eax
}
400038a1:	83 c4 10             	add    $0x10,%esp
400038a4:	5e                   	pop    %esi
400038a5:	5f                   	pop    %edi
400038a6:	5d                   	pop    %ebp
400038a7:	c3                   	ret    

400038a8 <memcpy>:

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
400038a8:	55                   	push   %ebp
400038a9:	89 e5                	mov    %esp,%ebp
400038ab:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
400038ae:	8b 45 10             	mov    0x10(%ebp),%eax
400038b1:	89 44 24 08          	mov    %eax,0x8(%esp)
400038b5:	8b 45 0c             	mov    0xc(%ebp),%eax
400038b8:	89 44 24 04          	mov    %eax,0x4(%esp)
400038bc:	8b 45 08             	mov    0x8(%ebp),%eax
400038bf:	89 04 24             	mov    %eax,(%esp)
400038c2:	e8 1b ff ff ff       	call   400037e2 <memmove>
}
400038c7:	c9                   	leave  
400038c8:	c3                   	ret    

400038c9 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
400038c9:	55                   	push   %ebp
400038ca:	89 e5                	mov    %esp,%ebp
400038cc:	83 ec 14             	sub    $0x14,%esp
	const uint8_t *s1 = (const uint8_t *) v1;
400038cf:	8b 45 08             	mov    0x8(%ebp),%eax
400038d2:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
	const uint8_t *s2 = (const uint8_t *) v2;
400038d5:	8b 45 0c             	mov    0xc(%ebp),%eax
400038d8:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)

	while (n-- > 0) {
400038db:	eb 33                	jmp    40003910 <memcmp+0x47>
		if (*s1 != *s2)
400038dd:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
400038e0:	0f b6 10             	movzbl (%eax),%edx
400038e3:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
400038e6:	0f b6 00             	movzbl (%eax),%eax
400038e9:	38 c2                	cmp    %al,%dl
400038eb:	74 1b                	je     40003908 <memcmp+0x3f>
			return (int) *s1 - (int) *s2;
400038ed:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
400038f0:	0f b6 00             	movzbl (%eax),%eax
400038f3:	0f b6 d0             	movzbl %al,%edx
400038f6:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
400038f9:	0f b6 00             	movzbl (%eax),%eax
400038fc:	0f b6 c0             	movzbl %al,%eax
400038ff:	89 d1                	mov    %edx,%ecx
40003901:	29 c1                	sub    %eax,%ecx
40003903:	89 4d ec             	mov    %ecx,0xffffffec(%ebp)
40003906:	eb 19                	jmp    40003921 <memcmp+0x58>
		s1++, s2++;
40003908:	83 45 f8 01          	addl   $0x1,0xfffffff8(%ebp)
4000390c:	83 45 fc 01          	addl   $0x1,0xfffffffc(%ebp)
40003910:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
40003914:	83 7d 10 ff          	cmpl   $0xffffffff,0x10(%ebp)
40003918:	75 c3                	jne    400038dd <memcmp+0x14>
	}

	return 0;
4000391a:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
40003921:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
}
40003924:	c9                   	leave  
40003925:	c3                   	ret    

40003926 <memchr>:

void *
memchr(const void *s, int c, size_t n)
{
40003926:	55                   	push   %ebp
40003927:	89 e5                	mov    %esp,%ebp
40003929:	83 ec 14             	sub    $0x14,%esp
	const void *ends = (const char *) s + n;
4000392c:	8b 45 08             	mov    0x8(%ebp),%eax
4000392f:	8b 55 10             	mov    0x10(%ebp),%edx
40003932:	01 d0                	add    %edx,%eax
40003934:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	for (; s < ends; s++)
40003937:	eb 19                	jmp    40003952 <memchr+0x2c>
		if (*(const unsigned char *) s == (unsigned char) c)
40003939:	8b 45 08             	mov    0x8(%ebp),%eax
4000393c:	0f b6 10             	movzbl (%eax),%edx
4000393f:	8b 45 0c             	mov    0xc(%ebp),%eax
40003942:	38 c2                	cmp    %al,%dl
40003944:	75 08                	jne    4000394e <memchr+0x28>
			return (void *) s;
40003946:	8b 45 08             	mov    0x8(%ebp),%eax
40003949:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
4000394c:	eb 13                	jmp    40003961 <memchr+0x3b>
4000394e:	83 45 08 01          	addl   $0x1,0x8(%ebp)
40003952:	8b 45 08             	mov    0x8(%ebp),%eax
40003955:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
40003958:	72 df                	jb     40003939 <memchr+0x13>
	return NULL;
4000395a:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
40003961:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
}
40003964:	c9                   	leave  
40003965:	c3                   	ret    
40003966:	90                   	nop    
40003967:	90                   	nop    

40003968 <cputs>:
#include <inc/stdio.h>
#include <inc/syscall.h>

void cputs(const char *str)
{
40003968:	55                   	push   %ebp
40003969:	89 e5                	mov    %esp,%ebp
4000396b:	53                   	push   %ebx
4000396c:	83 ec 10             	sub    $0x10,%esp
4000396f:	8b 45 08             	mov    0x8(%ebp),%eax
40003972:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %0" :
40003975:	b8 00 00 00 00       	mov    $0x0,%eax
4000397a:	8b 5d f8             	mov    0xfffffff8(%ebp),%ebx
4000397d:	cd 30                	int    $0x30
	sys_cputs(str);
}
4000397f:	83 c4 10             	add    $0x10,%esp
40003982:	5b                   	pop    %ebx
40003983:	5d                   	pop    %ebp
40003984:	c3                   	ret    
40003985:	90                   	nop    
40003986:	90                   	nop    
40003987:	90                   	nop    
40003988:	90                   	nop    
40003989:	90                   	nop    
4000398a:	90                   	nop    
4000398b:	90                   	nop    
4000398c:	90                   	nop    
4000398d:	90                   	nop    
4000398e:	90                   	nop    
4000398f:	90                   	nop    

40003990 <__udivdi3>:
40003990:	55                   	push   %ebp
40003991:	89 e5                	mov    %esp,%ebp
40003993:	57                   	push   %edi
40003994:	56                   	push   %esi
40003995:	83 ec 1c             	sub    $0x1c,%esp
40003998:	8b 45 10             	mov    0x10(%ebp),%eax
4000399b:	8b 55 14             	mov    0x14(%ebp),%edx
4000399e:	8b 7d 0c             	mov    0xc(%ebp),%edi
400039a1:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
400039a4:	89 c1                	mov    %eax,%ecx
400039a6:	8b 45 08             	mov    0x8(%ebp),%eax
400039a9:	85 d2                	test   %edx,%edx
400039ab:	89 d6                	mov    %edx,%esi
400039ad:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
400039b0:	75 1e                	jne    400039d0 <__udivdi3+0x40>
400039b2:	39 f9                	cmp    %edi,%ecx
400039b4:	0f 86 8d 00 00 00    	jbe    40003a47 <__udivdi3+0xb7>
400039ba:	89 fa                	mov    %edi,%edx
400039bc:	f7 f1                	div    %ecx
400039be:	89 c1                	mov    %eax,%ecx
400039c0:	89 c8                	mov    %ecx,%eax
400039c2:	89 f2                	mov    %esi,%edx
400039c4:	83 c4 1c             	add    $0x1c,%esp
400039c7:	5e                   	pop    %esi
400039c8:	5f                   	pop    %edi
400039c9:	5d                   	pop    %ebp
400039ca:	c3                   	ret    
400039cb:	90                   	nop    
400039cc:	8d 74 26 00          	lea    0x0(%esi),%esi
400039d0:	39 fa                	cmp    %edi,%edx
400039d2:	0f 87 98 00 00 00    	ja     40003a70 <__udivdi3+0xe0>
400039d8:	0f bd c2             	bsr    %edx,%eax
400039db:	83 f0 1f             	xor    $0x1f,%eax
400039de:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
400039e1:	74 7f                	je     40003a62 <__udivdi3+0xd2>
400039e3:	b8 20 00 00 00       	mov    $0x20,%eax
400039e8:	8b 55 f0             	mov    0xfffffff0(%ebp),%edx
400039eb:	2b 45 e4             	sub    0xffffffe4(%ebp),%eax
400039ee:	89 c1                	mov    %eax,%ecx
400039f0:	d3 ea                	shr    %cl,%edx
400039f2:	0f b6 4d e4          	movzbl 0xffffffe4(%ebp),%ecx
400039f6:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
400039f9:	89 f0                	mov    %esi,%eax
400039fb:	d3 e0                	shl    %cl,%eax
400039fd:	09 c2                	or     %eax,%edx
400039ff:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
40003a02:	89 55 e0             	mov    %edx,0xffffffe0(%ebp)
40003a05:	89 fa                	mov    %edi,%edx
40003a07:	d3 e0                	shl    %cl,%eax
40003a09:	0f b6 4d ec          	movzbl 0xffffffec(%ebp),%ecx
40003a0d:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
40003a10:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
40003a13:	d3 e8                	shr    %cl,%eax
40003a15:	0f b6 4d e4          	movzbl 0xffffffe4(%ebp),%ecx
40003a19:	d3 e2                	shl    %cl,%edx
40003a1b:	0f b6 4d ec          	movzbl 0xffffffec(%ebp),%ecx
40003a1f:	09 d0                	or     %edx,%eax
40003a21:	d3 ef                	shr    %cl,%edi
40003a23:	89 fa                	mov    %edi,%edx
40003a25:	f7 75 e0             	divl   0xffffffe0(%ebp)
40003a28:	89 d1                	mov    %edx,%ecx
40003a2a:	89 c7                	mov    %eax,%edi
40003a2c:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
40003a2f:	f7 e7                	mul    %edi
40003a31:	39 d1                	cmp    %edx,%ecx
40003a33:	89 c6                	mov    %eax,%esi
40003a35:	89 55 dc             	mov    %edx,0xffffffdc(%ebp)
40003a38:	72 6f                	jb     40003aa9 <__udivdi3+0x119>
40003a3a:	39 ca                	cmp    %ecx,%edx
40003a3c:	74 5e                	je     40003a9c <__udivdi3+0x10c>
40003a3e:	89 f9                	mov    %edi,%ecx
40003a40:	31 f6                	xor    %esi,%esi
40003a42:	e9 79 ff ff ff       	jmp    400039c0 <__udivdi3+0x30>
40003a47:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
40003a4a:	85 c0                	test   %eax,%eax
40003a4c:	74 32                	je     40003a80 <__udivdi3+0xf0>
40003a4e:	89 f2                	mov    %esi,%edx
40003a50:	89 f8                	mov    %edi,%eax
40003a52:	f7 f1                	div    %ecx
40003a54:	89 c6                	mov    %eax,%esi
40003a56:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
40003a59:	f7 f1                	div    %ecx
40003a5b:	89 c1                	mov    %eax,%ecx
40003a5d:	e9 5e ff ff ff       	jmp    400039c0 <__udivdi3+0x30>
40003a62:	39 d7                	cmp    %edx,%edi
40003a64:	77 2a                	ja     40003a90 <__udivdi3+0x100>
40003a66:	8b 55 f0             	mov    0xfffffff0(%ebp),%edx
40003a69:	39 55 e8             	cmp    %edx,0xffffffe8(%ebp)
40003a6c:	73 22                	jae    40003a90 <__udivdi3+0x100>
40003a6e:	66 90                	xchg   %ax,%ax
40003a70:	31 c9                	xor    %ecx,%ecx
40003a72:	31 f6                	xor    %esi,%esi
40003a74:	e9 47 ff ff ff       	jmp    400039c0 <__udivdi3+0x30>
40003a79:	8d b4 26 00 00 00 00 	lea    0x0(%esi),%esi
40003a80:	b8 01 00 00 00       	mov    $0x1,%eax
40003a85:	31 d2                	xor    %edx,%edx
40003a87:	f7 75 f0             	divl   0xfffffff0(%ebp)
40003a8a:	89 c1                	mov    %eax,%ecx
40003a8c:	eb c0                	jmp    40003a4e <__udivdi3+0xbe>
40003a8e:	66 90                	xchg   %ax,%ax
40003a90:	b9 01 00 00 00       	mov    $0x1,%ecx
40003a95:	31 f6                	xor    %esi,%esi
40003a97:	e9 24 ff ff ff       	jmp    400039c0 <__udivdi3+0x30>
40003a9c:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
40003a9f:	0f b6 4d e4          	movzbl 0xffffffe4(%ebp),%ecx
40003aa3:	d3 e0                	shl    %cl,%eax
40003aa5:	39 c6                	cmp    %eax,%esi
40003aa7:	76 95                	jbe    40003a3e <__udivdi3+0xae>
40003aa9:	8d 4f ff             	lea    0xffffffff(%edi),%ecx
40003aac:	31 f6                	xor    %esi,%esi
40003aae:	e9 0d ff ff ff       	jmp    400039c0 <__udivdi3+0x30>
40003ab3:	90                   	nop    
40003ab4:	90                   	nop    
40003ab5:	90                   	nop    
40003ab6:	90                   	nop    
40003ab7:	90                   	nop    
40003ab8:	90                   	nop    
40003ab9:	90                   	nop    
40003aba:	90                   	nop    
40003abb:	90                   	nop    
40003abc:	90                   	nop    
40003abd:	90                   	nop    
40003abe:	90                   	nop    
40003abf:	90                   	nop    

40003ac0 <__umoddi3>:
40003ac0:	55                   	push   %ebp
40003ac1:	89 e5                	mov    %esp,%ebp
40003ac3:	57                   	push   %edi
40003ac4:	56                   	push   %esi
40003ac5:	83 ec 30             	sub    $0x30,%esp
40003ac8:	8b 55 14             	mov    0x14(%ebp),%edx
40003acb:	8b 45 10             	mov    0x10(%ebp),%eax
40003ace:	8b 75 08             	mov    0x8(%ebp),%esi
40003ad1:	8b 7d 0c             	mov    0xc(%ebp),%edi
40003ad4:	85 d2                	test   %edx,%edx
40003ad6:	c7 45 d0 00 00 00 00 	movl   $0x0,0xffffffd0(%ebp)
40003add:	89 c1                	mov    %eax,%ecx
40003adf:	c7 45 d4 00 00 00 00 	movl   $0x0,0xffffffd4(%ebp)
40003ae6:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
40003ae9:	89 55 e8             	mov    %edx,0xffffffe8(%ebp)
40003aec:	89 75 f0             	mov    %esi,0xfffffff0(%ebp)
40003aef:	89 7d e0             	mov    %edi,0xffffffe0(%ebp)
40003af2:	75 1c                	jne    40003b10 <__umoddi3+0x50>
40003af4:	39 f8                	cmp    %edi,%eax
40003af6:	89 fa                	mov    %edi,%edx
40003af8:	0f 86 d4 00 00 00    	jbe    40003bd2 <__umoddi3+0x112>
40003afe:	89 f0                	mov    %esi,%eax
40003b00:	f7 f1                	div    %ecx
40003b02:	89 55 d0             	mov    %edx,0xffffffd0(%ebp)
40003b05:	c7 45 d4 00 00 00 00 	movl   $0x0,0xffffffd4(%ebp)
40003b0c:	eb 12                	jmp    40003b20 <__umoddi3+0x60>
40003b0e:	66 90                	xchg   %ax,%ax
40003b10:	8b 4d e0             	mov    0xffffffe0(%ebp),%ecx
40003b13:	39 4d e8             	cmp    %ecx,0xffffffe8(%ebp)
40003b16:	76 18                	jbe    40003b30 <__umoddi3+0x70>
40003b18:	89 75 d0             	mov    %esi,0xffffffd0(%ebp)
40003b1b:	89 7d d4             	mov    %edi,0xffffffd4(%ebp)
40003b1e:	66 90                	xchg   %ax,%ax
40003b20:	8b 45 d0             	mov    0xffffffd0(%ebp),%eax
40003b23:	8b 55 d4             	mov    0xffffffd4(%ebp),%edx
40003b26:	83 c4 30             	add    $0x30,%esp
40003b29:	5e                   	pop    %esi
40003b2a:	5f                   	pop    %edi
40003b2b:	5d                   	pop    %ebp
40003b2c:	c3                   	ret    
40003b2d:	8d 76 00             	lea    0x0(%esi),%esi
40003b30:	0f bd 45 e8          	bsr    0xffffffe8(%ebp),%eax
40003b34:	83 f0 1f             	xor    $0x1f,%eax
40003b37:	89 45 dc             	mov    %eax,0xffffffdc(%ebp)
40003b3a:	0f 84 c0 00 00 00    	je     40003c00 <__umoddi3+0x140>
40003b40:	b8 20 00 00 00       	mov    $0x20,%eax
40003b45:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
40003b48:	2b 45 dc             	sub    0xffffffdc(%ebp),%eax
40003b4b:	8b 7d ec             	mov    0xffffffec(%ebp),%edi
40003b4e:	8b 75 f0             	mov    0xfffffff0(%ebp),%esi
40003b51:	89 c1                	mov    %eax,%ecx
40003b53:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
40003b56:	d3 ea                	shr    %cl,%edx
40003b58:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
40003b5b:	0f b6 4d dc          	movzbl 0xffffffdc(%ebp),%ecx
40003b5f:	d3 e0                	shl    %cl,%eax
40003b61:	09 c2                	or     %eax,%edx
40003b63:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
40003b66:	d3 e7                	shl    %cl,%edi
40003b68:	0f b6 4d e4          	movzbl 0xffffffe4(%ebp),%ecx
40003b6c:	89 55 f4             	mov    %edx,0xfffffff4(%ebp)
40003b6f:	8b 55 e0             	mov    0xffffffe0(%ebp),%edx
40003b72:	d3 e8                	shr    %cl,%eax
40003b74:	0f b6 4d dc          	movzbl 0xffffffdc(%ebp),%ecx
40003b78:	d3 e2                	shl    %cl,%edx
40003b7a:	09 d0                	or     %edx,%eax
40003b7c:	8b 55 e0             	mov    0xffffffe0(%ebp),%edx
40003b7f:	d3 e6                	shl    %cl,%esi
40003b81:	0f b6 4d e4          	movzbl 0xffffffe4(%ebp),%ecx
40003b85:	d3 ea                	shr    %cl,%edx
40003b87:	f7 75 f4             	divl   0xfffffff4(%ebp)
40003b8a:	89 55 cc             	mov    %edx,0xffffffcc(%ebp)
40003b8d:	f7 e7                	mul    %edi
40003b8f:	39 55 cc             	cmp    %edx,0xffffffcc(%ebp)
40003b92:	0f 82 a5 00 00 00    	jb     40003c3d <__umoddi3+0x17d>
40003b98:	3b 55 cc             	cmp    0xffffffcc(%ebp),%edx
40003b9b:	0f 84 94 00 00 00    	je     40003c35 <__umoddi3+0x175>
40003ba1:	8b 4d cc             	mov    0xffffffcc(%ebp),%ecx
40003ba4:	29 c6                	sub    %eax,%esi
40003ba6:	19 d1                	sbb    %edx,%ecx
40003ba8:	89 4d cc             	mov    %ecx,0xffffffcc(%ebp)
40003bab:	0f b6 4d dc          	movzbl 0xffffffdc(%ebp),%ecx
40003baf:	89 f2                	mov    %esi,%edx
40003bb1:	8b 45 cc             	mov    0xffffffcc(%ebp),%eax
40003bb4:	d3 ea                	shr    %cl,%edx
40003bb6:	0f b6 4d e4          	movzbl 0xffffffe4(%ebp),%ecx
40003bba:	d3 e0                	shl    %cl,%eax
40003bbc:	0f b6 4d dc          	movzbl 0xffffffdc(%ebp),%ecx
40003bc0:	09 c2                	or     %eax,%edx
40003bc2:	8b 45 cc             	mov    0xffffffcc(%ebp),%eax
40003bc5:	89 55 d0             	mov    %edx,0xffffffd0(%ebp)
40003bc8:	d3 e8                	shr    %cl,%eax
40003bca:	89 45 d4             	mov    %eax,0xffffffd4(%ebp)
40003bcd:	e9 4e ff ff ff       	jmp    40003b20 <__umoddi3+0x60>
40003bd2:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
40003bd5:	85 c0                	test   %eax,%eax
40003bd7:	74 17                	je     40003bf0 <__umoddi3+0x130>
40003bd9:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
40003bdc:	8b 55 e8             	mov    0xffffffe8(%ebp),%edx
40003bdf:	f7 f1                	div    %ecx
40003be1:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
40003be4:	f7 f1                	div    %ecx
40003be6:	e9 17 ff ff ff       	jmp    40003b02 <__umoddi3+0x42>
40003beb:	90                   	nop    
40003bec:	8d 74 26 00          	lea    0x0(%esi),%esi
40003bf0:	b8 01 00 00 00       	mov    $0x1,%eax
40003bf5:	31 d2                	xor    %edx,%edx
40003bf7:	f7 75 ec             	divl   0xffffffec(%ebp)
40003bfa:	89 c1                	mov    %eax,%ecx
40003bfc:	eb db                	jmp    40003bd9 <__umoddi3+0x119>
40003bfe:	66 90                	xchg   %ax,%ax
40003c00:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
40003c03:	39 45 e0             	cmp    %eax,0xffffffe0(%ebp)
40003c06:	77 19                	ja     40003c21 <__umoddi3+0x161>
40003c08:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
40003c0b:	39 55 f0             	cmp    %edx,0xfffffff0(%ebp)
40003c0e:	73 11                	jae    40003c21 <__umoddi3+0x161>
40003c10:	8b 55 f0             	mov    0xfffffff0(%ebp),%edx
40003c13:	8b 4d e0             	mov    0xffffffe0(%ebp),%ecx
40003c16:	89 55 d0             	mov    %edx,0xffffffd0(%ebp)
40003c19:	89 4d d4             	mov    %ecx,0xffffffd4(%ebp)
40003c1c:	e9 ff fe ff ff       	jmp    40003b20 <__umoddi3+0x60>
40003c21:	8b 4d e0             	mov    0xffffffe0(%ebp),%ecx
40003c24:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
40003c27:	2b 45 ec             	sub    0xffffffec(%ebp),%eax
40003c2a:	1b 4d e8             	sbb    0xffffffe8(%ebp),%ecx
40003c2d:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
40003c30:	89 4d e0             	mov    %ecx,0xffffffe0(%ebp)
40003c33:	eb db                	jmp    40003c10 <__umoddi3+0x150>
40003c35:	39 f0                	cmp    %esi,%eax
40003c37:	0f 86 64 ff ff ff    	jbe    40003ba1 <__umoddi3+0xe1>
40003c3d:	29 f8                	sub    %edi,%eax
40003c3f:	1b 55 f4             	sbb    0xfffffff4(%ebp),%edx
40003c42:	e9 5a ff ff ff       	jmp    40003ba1 <__umoddi3+0xe1>
