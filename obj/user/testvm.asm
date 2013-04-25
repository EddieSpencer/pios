
obj/user/testvm:     file format elf32-i386

Disassembly of section .text:

40000100 <start>:
	.globl start
start:
	// See if we were started with arguments on the stack.
	// If not, our esp will start on a nice big power-of-two boundary.
	testl $0x0fffffff, %esp
40000100:	f7 c4 ff ff ff 0f    	test   $0xfffffff,%esp
	jnz args_exist
40000106:	75 04                	jne    4000010c <args_exist>

	// If not, push dummy argc/argv arguments.
	// This happens when we are loaded by the kernel,
	// because the kernel does not know about passing arguments.
	pushl $0
40000108:	6a 00                	push   $0x0
	pushl $0
4000010a:	6a 00                	push   $0x0

4000010c <args_exist>:

args_exist:

	call	main	// run the program
4000010c:	e8 85 2a 00 00       	call   40002b96 <main>
	pushl	%eax	// use with main's return value as exit status
40000111:	50                   	push   %eax
	call	exit
40000112:	e8 91 38 00 00       	call   400039a8 <exit>
1:	jmp 1b
40000117:	eb fe                	jmp    40000117 <args_exist+0xb>

40000119 <exec_start>:


// Start entrypoint for exec.  When our exec code replaces an existing process
// with a new one, it loads the new program image into child process 0,
// then calls this "function" with the new program's initial stack pointer
// as the only argument.
// Here we overwrite our entire user space memory state with that of child 0,
// clear child 0's address space, and start the new program.
// Since the old program's executable gets overwritten by the new one
// during the first system call below, this code will continue to work
// after that point ONLY if this particular code sequence is identical
// and at the same location in EVERY user program.
// We guarantee this by putting it in lib/entry.S, which is always the same
// and linked at the beginning of every user program.
	.globl exec_start
exec_start:
	movl	4(%esp),%esp	// Load new executable's initial stack pointer
40000119:	8b 64 24 04          	mov    0x4(%esp),%esp
	xorl	%ebp,%ebp	// New stack will be at its first stack frame
4000011d:	31 ed                	xor    %ebp,%ebp

	movl	$SYS_GET|SYS_COPY,%eax	// Copy child 0's memory onto our own.
4000011f:	b8 02 00 02 00       	mov    $0x20002,%eax
	xorl	%edx,%edx		// edx[0-7] = child 0
40000124:	31 d2                	xor    %edx,%edx
	movl	$VM_USERLO,%esi
40000126:	be 00 00 00 40       	mov    $0x40000000,%esi
	movl	$VM_USERLO,%edi
4000012b:	bf 00 00 00 40       	mov    $0x40000000,%edi
	movl	$VM_USERHI-VM_USERLO,%ecx
40000130:	b9 00 00 00 b0       	mov    $0xb0000000,%ecx
	int	$T_SYSCALL
40000135:	cd 30                	int    $0x30

	movl	$SYS_PUT|SYS_ZERO,%eax	// Zero out child 0's state
40000137:	b8 01 00 01 00       	mov    $0x10001,%eax
	int	$T_SYSCALL
4000013c:	cd 30                	int    $0x30

	jmp	start
4000013e:	e9 bd ff ff ff       	jmp    40000100 <start>


	call	main	// run the program
40000143:	e8 4e 2a 00 00       	call   40002b96 <main>
	pushl	%eax	// use with main's return value as exit status
40000148:	50                   	push   %eax
        movl	$SYS_RET, %eax
40000149:	b8 03 00 00 00       	mov    $0x3,%eax
        int	$T_SYSCALL
4000014e:	cd 30                	int    $0x30
1:	jmp 1b
40000150:	eb fe                	jmp    40000150 <exec_start+0x37>
40000152:	90                   	nop    
40000153:	90                   	nop    

40000154 <fork>:

// Fork a child process, returning 0 in the child and 1 in the parent.
int
fork(int cmd, uint8_t child)
{
40000154:	55                   	push   %ebp
40000155:	89 e5                	mov    %esp,%ebp
40000157:	57                   	push   %edi
40000158:	56                   	push   %esi
40000159:	53                   	push   %ebx
4000015a:	81 ec 9c 02 00 00    	sub    $0x29c,%esp
40000160:	8b 45 0c             	mov    0xc(%ebp),%eax
40000163:	88 85 74 fd ff ff    	mov    %al,0xfffffd74(%ebp)
	// Set up the register state for the child
	struct procstate ps;
	memset(&ps, 0, sizeof(ps));
40000169:	c7 44 24 08 50 02 00 	movl   $0x250,0x8(%esp)
40000170:	00 
40000171:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000178:	00 
40000179:	8d 85 78 fd ff ff    	lea    0xfffffd78(%ebp),%eax
4000017f:	89 04 24             	mov    %eax,(%esp)
40000182:	e8 22 36 00 00       	call   400037a9 <memset>

	// Use some assembly magic to propagate registers to child
	// and generate an appropriate starting eip
	int isparent;
	asm volatile(
40000187:	89 b5 7c fd ff ff    	mov    %esi,0xfffffd7c(%ebp)
4000018d:	89 bd 78 fd ff ff    	mov    %edi,0xfffffd78(%ebp)
40000193:	89 ad 80 fd ff ff    	mov    %ebp,0xfffffd80(%ebp)
40000199:	89 a5 bc fd ff ff    	mov    %esp,0xfffffdbc(%ebp)
4000019f:	c7 85 b0 fd ff ff ae 	movl   $0x400001ae,0xfffffdb0(%ebp)
400001a6:	01 00 40 
400001a9:	b8 01 00 00 00       	mov    $0x1,%eax
400001ae:	89 45 cc             	mov    %eax,0xffffffcc(%ebp)
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
400001b1:	83 7d cc 00          	cmpl   $0x0,0xffffffcc(%ebp)
400001b5:	75 0c                	jne    400001c3 <fork+0x6f>
		return 0;	// in the child
400001b7:	c7 85 70 fd ff ff 00 	movl   $0x0,0xfffffd70(%ebp)
400001be:	00 00 00 
400001c1:	eb 60                	jmp    40000223 <fork+0xcf>

	// Fork the child, copying our entire user address space into it.
	ps.tf.regs.eax = 0;	// isparent == 0 in the child
400001c3:	c7 85 94 fd ff ff 00 	movl   $0x0,0xfffffd94(%ebp)
400001ca:	00 00 00 
	sys_put(cmd | SYS_REGS | SYS_COPY, child, &ps, ALLVA, ALLVA, ALLSIZE);
400001cd:	0f b6 95 74 fd ff ff 	movzbl 0xfffffd74(%ebp),%edx
400001d4:	8b 45 08             	mov    0x8(%ebp),%eax
400001d7:	0d 00 10 02 00       	or     $0x21000,%eax
400001dc:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
400001df:	66 89 55 e2          	mov    %dx,0xffffffe2(%ebp)
400001e3:	8d 85 78 fd ff ff    	lea    0xfffffd78(%ebp),%eax
400001e9:	89 45 dc             	mov    %eax,0xffffffdc(%ebp)
400001ec:	c7 45 d8 00 00 00 40 	movl   $0x40000000,0xffffffd8(%ebp)
400001f3:	c7 45 d4 00 00 00 40 	movl   $0x40000000,0xffffffd4(%ebp)
400001fa:	c7 45 d0 00 00 00 b0 	movl   $0xb0000000,0xffffffd0(%ebp)
static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
40000201:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
40000204:	83 c8 01             	or     $0x1,%eax
40000207:	8b 5d dc             	mov    0xffffffdc(%ebp),%ebx
4000020a:	0f b7 55 e2          	movzwl 0xffffffe2(%ebp),%edx
4000020e:	8b 75 d8             	mov    0xffffffd8(%ebp),%esi
40000211:	8b 7d d4             	mov    0xffffffd4(%ebp),%edi
40000214:	8b 4d d0             	mov    0xffffffd0(%ebp),%ecx
40000217:	cd 30                	int    $0x30

	return 1;
40000219:	c7 85 70 fd ff ff 01 	movl   $0x1,0xfffffd70(%ebp)
40000220:	00 00 00 
40000223:	8b 85 70 fd ff ff    	mov    0xfffffd70(%ebp),%eax
}
40000229:	81 c4 9c 02 00 00    	add    $0x29c,%esp
4000022f:	5b                   	pop    %ebx
40000230:	5e                   	pop    %esi
40000231:	5f                   	pop    %edi
40000232:	5d                   	pop    %ebp
40000233:	c3                   	ret    

40000234 <join>:

void
join(int cmd, uint8_t child, int trapexpect)
{
40000234:	55                   	push   %ebp
40000235:	89 e5                	mov    %esp,%ebp
40000237:	57                   	push   %edi
40000238:	56                   	push   %esi
40000239:	53                   	push   %ebx
4000023a:	81 ec ac 02 00 00    	sub    $0x2ac,%esp
40000240:	8b 45 0c             	mov    0xc(%ebp),%eax
40000243:	88 85 74 fd ff ff    	mov    %al,0xfffffd74(%ebp)
	// Wait for the child and retrieve its CPU state.
	// If merging, leave the highest 4MB containing the stack unmerged,
	// so that the stack acts as a "thread-private" memory area.
	struct procstate ps;
	sys_get(cmd | SYS_REGS, child, &ps, ALLVA, ALLVA, ALLSIZE-PTSIZE);
40000249:	0f b6 95 74 fd ff ff 	movzbl 0xfffffd74(%ebp),%edx
40000250:	8b 45 08             	mov    0x8(%ebp),%eax
40000253:	80 cc 10             	or     $0x10,%ah
40000256:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
40000259:	66 89 55 e2          	mov    %dx,0xffffffe2(%ebp)
4000025d:	8d 85 78 fd ff ff    	lea    0xfffffd78(%ebp),%eax
40000263:	89 45 dc             	mov    %eax,0xffffffdc(%ebp)
40000266:	c7 45 d8 00 00 00 40 	movl   $0x40000000,0xffffffd8(%ebp)
4000026d:	c7 45 d4 00 00 00 40 	movl   $0x40000000,0xffffffd4(%ebp)
40000274:	c7 45 d0 00 00 c0 af 	movl   $0xafc00000,0xffffffd0(%ebp)
static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
4000027b:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
4000027e:	83 c8 02             	or     $0x2,%eax
40000281:	8b 5d dc             	mov    0xffffffdc(%ebp),%ebx
40000284:	0f b7 55 e2          	movzwl 0xffffffe2(%ebp),%edx
40000288:	8b 75 d8             	mov    0xffffffd8(%ebp),%esi
4000028b:	8b 7d d4             	mov    0xffffffd4(%ebp),%edi
4000028e:	8b 4d d0             	mov    0xffffffd0(%ebp),%ecx
40000291:	cd 30                	int    $0x30

	// Make sure the child exited with the expected trap number
	if (ps.tf.trapno != trapexpect) {
40000293:	8b 95 a8 fd ff ff    	mov    0xfffffda8(%ebp),%edx
40000299:	8b 45 10             	mov    0x10(%ebp),%eax
4000029c:	39 c2                	cmp    %eax,%edx
4000029e:	74 59                	je     400002f9 <join+0xc5>
		cprintf("  eip  0x%08x\n", ps.tf.eip);
400002a0:	8b 85 b0 fd ff ff    	mov    0xfffffdb0(%ebp),%eax
400002a6:	89 44 24 04          	mov    %eax,0x4(%esp)
400002aa:	c7 04 24 40 56 00 40 	movl   $0x40005640,(%esp)
400002b1:	e8 eb 2b 00 00       	call   40002ea1 <cprintf>
		cprintf("  esp  0x%08x\n", ps.tf.esp);
400002b6:	8b 85 bc fd ff ff    	mov    0xfffffdbc(%ebp),%eax
400002bc:	89 44 24 04          	mov    %eax,0x4(%esp)
400002c0:	c7 04 24 4f 56 00 40 	movl   $0x4000564f,(%esp)
400002c7:	e8 d5 2b 00 00       	call   40002ea1 <cprintf>
		panic("join: unexpected trap %d, expecting %d\n",
400002cc:	8b 95 a8 fd ff ff    	mov    0xfffffda8(%ebp),%edx
400002d2:	8b 45 10             	mov    0x10(%ebp),%eax
400002d5:	89 44 24 10          	mov    %eax,0x10(%esp)
400002d9:	89 54 24 0c          	mov    %edx,0xc(%esp)
400002dd:	c7 44 24 08 60 56 00 	movl   $0x40005660,0x8(%esp)
400002e4:	40 
400002e5:	c7 44 24 04 50 00 00 	movl   $0x50,0x4(%esp)
400002ec:	00 
400002ed:	c7 04 24 88 56 00 40 	movl   $0x40005688,(%esp)
400002f4:	e8 ef 28 00 00       	call   40002be8 <debug_panic>
			ps.tf.trapno, trapexpect);
	}
}
400002f9:	81 c4 ac 02 00 00    	add    $0x2ac,%esp
400002ff:	5b                   	pop    %ebx
40000300:	5e                   	pop    %esi
40000301:	5f                   	pop    %edi
40000302:	5d                   	pop    %ebp
40000303:	c3                   	ret    

40000304 <gentrap>:

void
gentrap(int trap)
{
40000304:	55                   	push   %ebp
40000305:	89 e5                	mov    %esp,%ebp
40000307:	83 ec 28             	sub    $0x28,%esp
	int bounds[2] = { 1, 3 };
4000030a:	c7 45 f8 01 00 00 00 	movl   $0x1,0xfffffff8(%ebp)
40000311:	c7 45 fc 03 00 00 00 	movl   $0x3,0xfffffffc(%ebp)
	switch (trap) {
40000318:	8b 45 08             	mov    0x8(%ebp),%eax
4000031b:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
4000031e:	83 7d ec 30          	cmpl   $0x30,0xffffffec(%ebp)
40000322:	77 31                	ja     40000355 <gentrap+0x51>
40000324:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
40000327:	8b 04 95 a8 56 00 40 	mov    0x400056a8(,%edx,4),%eax
4000032e:	ff e0                	jmp    *%eax
	case T_DIVIDE:
		asm volatile("divl %0,%0" : : "r" (0));
40000330:	b8 00 00 00 00       	mov    $0x0,%eax
40000335:	f7 f0                	div    %eax
	case T_BRKPT:
		asm volatile("int3");
40000337:	cc                   	int3   
	case T_OFLOW:
		asm volatile("addl %0,%0; into" : : "r" (0x70000000));
40000338:	b8 00 00 00 70       	mov    $0x70000000,%eax
4000033d:	01 c0                	add    %eax,%eax
4000033f:	ce                   	into   
	case T_BOUND:
		asm volatile("boundl %0,%1" : : "r" (0), "m" (bounds[0]));
40000340:	b8 00 00 00 00       	mov    $0x0,%eax
40000345:	62 45 f8             	bound  %eax,0xfffffff8(%ebp)
	case T_ILLOP:
		asm volatile("ud2");	// guaranteed to be undefined
40000348:	0f 0b                	ud2a   
	case T_GPFLT:
		asm volatile("lidt %0" : : "m" (trap));
4000034a:	0f 01 5d 08          	lidtl  0x8(%ebp)

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
4000034e:	b8 03 00 00 00       	mov    $0x3,%eax
40000353:	cd 30                	int    $0x30
	case T_SYSCALL:
		sys_ret();
	default:
		panic("unknown trap %d", trap);
40000355:	8b 45 08             	mov    0x8(%ebp),%eax
40000358:	89 44 24 0c          	mov    %eax,0xc(%esp)
4000035c:	c7 44 24 08 96 56 00 	movl   $0x40005696,0x8(%esp)
40000363:	40 
40000364:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
4000036b:	00 
4000036c:	c7 04 24 88 56 00 40 	movl   $0x40005688,(%esp)
40000373:	e8 70 28 00 00       	call   40002be8 <debug_panic>

40000378 <trapcheck>:
	}
}

static void
trapcheck(int trapno)
{
40000378:	55                   	push   %ebp
40000379:	89 e5                	mov    %esp,%ebp
4000037b:	83 ec 18             	sub    $0x18,%esp
	// cprintf("trapcheck %d\n", trapno);
	if (!fork(SYS_START, 0)) { gentrap(trapno); }
4000037e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000385:	00 
40000386:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
4000038d:	e8 c2 fd ff ff       	call   40000154 <fork>
40000392:	85 c0                	test   %eax,%eax
40000394:	75 0b                	jne    400003a1 <trapcheck+0x29>
40000396:	8b 45 08             	mov    0x8(%ebp),%eax
40000399:	89 04 24             	mov    %eax,(%esp)
4000039c:	e8 63 ff ff ff       	call   40000304 <gentrap>
	join(0, 0, trapno);
400003a1:	8b 45 08             	mov    0x8(%ebp),%eax
400003a4:	89 44 24 08          	mov    %eax,0x8(%esp)
400003a8:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400003af:	00 
400003b0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
400003b7:	e8 78 fe ff ff       	call   40000234 <join>
}
400003bc:	c9                   	leave  
400003bd:	c3                   	ret    

400003be <cputsfaultchild>:

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
400003be:	55                   	push   %ebp
400003bf:	89 e5                	mov    %esp,%ebp
400003c1:	53                   	push   %ebx
400003c2:	83 ec 10             	sub    $0x10,%esp
	sys_cputs((char*)arg);
400003c5:	8b 45 08             	mov    0x8(%ebp),%eax
400003c8:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %0" :
400003cb:	b8 00 00 00 00       	mov    $0x0,%eax
400003d0:	8b 5d f8             	mov    0xfffffff8(%ebp),%ebx
400003d3:	cd 30                	int    $0x30
}
400003d5:	83 c4 10             	add    $0x10,%esp
400003d8:	5b                   	pop    %ebx
400003d9:	5d                   	pop    %ebp
400003da:	c3                   	ret    

400003db <loadcheck>:
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
400003db:	55                   	push   %ebp
400003dc:	89 e5                	mov    %esp,%ebp
400003de:	83 ec 28             	sub    $0x28,%esp
	// Simple ELF loading test: make sure bss is mapped but cleared
	uint8_t *p;
	for (p = edata; p < end; p++) {
400003e1:	c7 45 fc e0 7a 00 40 	movl   $0x40007ae0,0xfffffffc(%ebp)
400003e8:	eb 5c                	jmp    40000446 <loadcheck+0x6b>
		if (*p != 0) cprintf("%x %d\n", p, *p);
400003ea:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
400003ed:	0f b6 00             	movzbl (%eax),%eax
400003f0:	84 c0                	test   %al,%al
400003f2:	74 20                	je     40000414 <loadcheck+0x39>
400003f4:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
400003f7:	0f b6 00             	movzbl (%eax),%eax
400003fa:	0f b6 c0             	movzbl %al,%eax
400003fd:	89 44 24 08          	mov    %eax,0x8(%esp)
40000401:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
40000404:	89 44 24 04          	mov    %eax,0x4(%esp)
40000408:	c7 04 24 6c 57 00 40 	movl   $0x4000576c,(%esp)
4000040f:	e8 8d 2a 00 00       	call   40002ea1 <cprintf>
		assert(*p == 0);
40000414:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
40000417:	0f b6 00             	movzbl (%eax),%eax
4000041a:	84 c0                	test   %al,%al
4000041c:	74 24                	je     40000442 <loadcheck+0x67>
4000041e:	c7 44 24 0c 73 57 00 	movl   $0x40005773,0xc(%esp)
40000425:	40 
40000426:	c7 44 24 08 7b 57 00 	movl   $0x4000577b,0x8(%esp)
4000042d:	40 
4000042e:	c7 44 24 04 9a 00 00 	movl   $0x9a,0x4(%esp)
40000435:	00 
40000436:	c7 04 24 88 56 00 40 	movl   $0x40005688,(%esp)
4000043d:	e8 a6 27 00 00       	call   40002be8 <debug_panic>
40000442:	83 45 fc 01          	addl   $0x1,0xfffffffc(%ebp)
40000446:	81 7d fc 08 9c 00 40 	cmpl   $0x40009c08,0xfffffffc(%ebp)
4000044d:	72 9b                	jb     400003ea <loadcheck+0xf>
	}

	cprintf("testvm: loadcheck passed\n");
4000044f:	c7 04 24 90 57 00 40 	movl   $0x40005790,(%esp)
40000456:	e8 46 2a 00 00       	call   40002ea1 <cprintf>
}
4000045b:	c9                   	leave  
4000045c:	c3                   	ret    

4000045d <forkcheck>:

// Check forking of simple child processes and trap redirection (once more)
void
forkcheck()
{
4000045d:	55                   	push   %ebp
4000045e:	89 e5                	mov    %esp,%ebp
40000460:	83 ec 18             	sub    $0x18,%esp
	// Our first copy-on-write test: fork and execute a simple child.
	if (!fork(SYS_START, 0)) gentrap(T_SYSCALL);
40000463:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000046a:	00 
4000046b:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000472:	e8 dd fc ff ff       	call   40000154 <fork>
40000477:	85 c0                	test   %eax,%eax
40000479:	75 0c                	jne    40000487 <forkcheck+0x2a>
4000047b:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
40000482:	e8 7d fe ff ff       	call   40000304 <gentrap>
	join(0, 0, T_SYSCALL);
40000487:	c7 44 24 08 30 00 00 	movl   $0x30,0x8(%esp)
4000048e:	00 
4000048f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000496:	00 
40000497:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
4000049e:	e8 91 fd ff ff       	call   40000234 <join>

	// Re-check trap handling and reflection from child processes
	trapcheck(T_DIVIDE);
400004a3:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
400004aa:	e8 c9 fe ff ff       	call   40000378 <trapcheck>
	trapcheck(T_BRKPT);
400004af:	c7 04 24 03 00 00 00 	movl   $0x3,(%esp)
400004b6:	e8 bd fe ff ff       	call   40000378 <trapcheck>
	trapcheck(T_OFLOW);
400004bb:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
400004c2:	e8 b1 fe ff ff       	call   40000378 <trapcheck>
	trapcheck(T_BOUND);
400004c7:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
400004ce:	e8 a5 fe ff ff       	call   40000378 <trapcheck>
	trapcheck(T_ILLOP);
400004d3:	c7 04 24 06 00 00 00 	movl   $0x6,(%esp)
400004da:	e8 99 fe ff ff       	call   40000378 <trapcheck>
	trapcheck(T_GPFLT);
400004df:	c7 04 24 0d 00 00 00 	movl   $0xd,(%esp)
400004e6:	e8 8d fe ff ff       	call   40000378 <trapcheck>

	// Make sure we can run several children using the same stack area
	// (since each child should get a separate logical copy)
	if (!fork(SYS_START, 0)) gentrap(T_SYSCALL);
400004eb:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400004f2:	00 
400004f3:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
400004fa:	e8 55 fc ff ff       	call   40000154 <fork>
400004ff:	85 c0                	test   %eax,%eax
40000501:	75 0c                	jne    4000050f <forkcheck+0xb2>
40000503:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
4000050a:	e8 f5 fd ff ff       	call   40000304 <gentrap>
	if (!fork(SYS_START, 1)) gentrap(T_DIVIDE);
4000050f:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
40000516:	00 
40000517:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
4000051e:	e8 31 fc ff ff       	call   40000154 <fork>
40000523:	85 c0                	test   %eax,%eax
40000525:	75 0c                	jne    40000533 <forkcheck+0xd6>
40000527:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
4000052e:	e8 d1 fd ff ff       	call   40000304 <gentrap>
	if (!fork(SYS_START, 2)) gentrap(T_BRKPT);
40000533:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
4000053a:	00 
4000053b:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000542:	e8 0d fc ff ff       	call   40000154 <fork>
40000547:	85 c0                	test   %eax,%eax
40000549:	75 0c                	jne    40000557 <forkcheck+0xfa>
4000054b:	c7 04 24 03 00 00 00 	movl   $0x3,(%esp)
40000552:	e8 ad fd ff ff       	call   40000304 <gentrap>
	if (!fork(SYS_START, 3)) gentrap(T_OFLOW);
40000557:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
4000055e:	00 
4000055f:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000566:	e8 e9 fb ff ff       	call   40000154 <fork>
4000056b:	85 c0                	test   %eax,%eax
4000056d:	75 0c                	jne    4000057b <forkcheck+0x11e>
4000056f:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
40000576:	e8 89 fd ff ff       	call   40000304 <gentrap>
	if (!fork(SYS_START, 4)) gentrap(T_BOUND);
4000057b:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
40000582:	00 
40000583:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
4000058a:	e8 c5 fb ff ff       	call   40000154 <fork>
4000058f:	85 c0                	test   %eax,%eax
40000591:	75 0c                	jne    4000059f <forkcheck+0x142>
40000593:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
4000059a:	e8 65 fd ff ff       	call   40000304 <gentrap>
	if (!fork(SYS_START, 5)) gentrap(T_ILLOP);
4000059f:	c7 44 24 04 05 00 00 	movl   $0x5,0x4(%esp)
400005a6:	00 
400005a7:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
400005ae:	e8 a1 fb ff ff       	call   40000154 <fork>
400005b3:	85 c0                	test   %eax,%eax
400005b5:	75 0c                	jne    400005c3 <forkcheck+0x166>
400005b7:	c7 04 24 06 00 00 00 	movl   $0x6,(%esp)
400005be:	e8 41 fd ff ff       	call   40000304 <gentrap>
	if (!fork(SYS_START, 6)) gentrap(T_GPFLT);
400005c3:	c7 44 24 04 06 00 00 	movl   $0x6,0x4(%esp)
400005ca:	00 
400005cb:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
400005d2:	e8 7d fb ff ff       	call   40000154 <fork>
400005d7:	85 c0                	test   %eax,%eax
400005d9:	75 0c                	jne    400005e7 <forkcheck+0x18a>
400005db:	c7 04 24 0d 00 00 00 	movl   $0xd,(%esp)
400005e2:	e8 1d fd ff ff       	call   40000304 <gentrap>
	join(0, 0, T_SYSCALL);
400005e7:	c7 44 24 08 30 00 00 	movl   $0x30,0x8(%esp)
400005ee:	00 
400005ef:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400005f6:	00 
400005f7:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
400005fe:	e8 31 fc ff ff       	call   40000234 <join>
	join(0, 1, T_DIVIDE);
40000603:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
4000060a:	00 
4000060b:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
40000612:	00 
40000613:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
4000061a:	e8 15 fc ff ff       	call   40000234 <join>
	join(0, 2, T_BRKPT);
4000061f:	c7 44 24 08 03 00 00 	movl   $0x3,0x8(%esp)
40000626:	00 
40000627:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
4000062e:	00 
4000062f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000636:	e8 f9 fb ff ff       	call   40000234 <join>
	join(0, 3, T_OFLOW);
4000063b:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
40000642:	00 
40000643:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
4000064a:	00 
4000064b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000652:	e8 dd fb ff ff       	call   40000234 <join>
	join(0, 4, T_BOUND);
40000657:	c7 44 24 08 05 00 00 	movl   $0x5,0x8(%esp)
4000065e:	00 
4000065f:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
40000666:	00 
40000667:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
4000066e:	e8 c1 fb ff ff       	call   40000234 <join>
	join(0, 5, T_ILLOP);
40000673:	c7 44 24 08 06 00 00 	movl   $0x6,0x8(%esp)
4000067a:	00 
4000067b:	c7 44 24 04 05 00 00 	movl   $0x5,0x4(%esp)
40000682:	00 
40000683:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
4000068a:	e8 a5 fb ff ff       	call   40000234 <join>
	join(0, 6, T_GPFLT);
4000068f:	c7 44 24 08 0d 00 00 	movl   $0xd,0x8(%esp)
40000696:	00 
40000697:	c7 44 24 04 06 00 00 	movl   $0x6,0x4(%esp)
4000069e:	00 
4000069f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
400006a6:	e8 89 fb ff ff       	call   40000234 <join>

	// Check that kernel address space is inaccessible to user code
	readfaulttest(0);
400006ab:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400006b2:	00 
400006b3:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
400006ba:	e8 95 fa ff ff       	call   40000154 <fork>
400006bf:	85 c0                	test   %eax,%eax
400006c1:	75 0e                	jne    400006d1 <forkcheck+0x274>
400006c3:	b8 00 00 00 00       	mov    $0x0,%eax
400006c8:	8b 00                	mov    (%eax),%eax

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
400006ca:	b8 03 00 00 00       	mov    $0x3,%eax
400006cf:	cd 30                	int    $0x30
400006d1:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
400006d8:	00 
400006d9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400006e0:	00 
400006e1:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
400006e8:	e8 47 fb ff ff       	call   40000234 <join>
	readfaulttest(VM_USERLO-4);
400006ed:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400006f4:	00 
400006f5:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
400006fc:	e8 53 fa ff ff       	call   40000154 <fork>
40000701:	85 c0                	test   %eax,%eax
40000703:	75 0e                	jne    40000713 <forkcheck+0x2b6>
40000705:	b8 fc ff ff 3f       	mov    $0x3ffffffc,%eax
4000070a:	8b 00                	mov    (%eax),%eax

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
4000070c:	b8 03 00 00 00       	mov    $0x3,%eax
40000711:	cd 30                	int    $0x30
40000713:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
4000071a:	00 
4000071b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000722:	00 
40000723:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
4000072a:	e8 05 fb ff ff       	call   40000234 <join>
	readfaulttest(VM_USERHI);
4000072f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000736:	00 
40000737:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
4000073e:	e8 11 fa ff ff       	call   40000154 <fork>
40000743:	85 c0                	test   %eax,%eax
40000745:	75 0e                	jne    40000755 <forkcheck+0x2f8>
40000747:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
4000074c:	8b 00                	mov    (%eax),%eax

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
4000074e:	b8 03 00 00 00       	mov    $0x3,%eax
40000753:	cd 30                	int    $0x30
40000755:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
4000075c:	00 
4000075d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000764:	00 
40000765:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
4000076c:	e8 c3 fa ff ff       	call   40000234 <join>
	readfaulttest(0-4);
40000771:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000778:	00 
40000779:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000780:	e8 cf f9 ff ff       	call   40000154 <fork>
40000785:	85 c0                	test   %eax,%eax
40000787:	75 0e                	jne    40000797 <forkcheck+0x33a>
40000789:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
4000078e:	8b 00                	mov    (%eax),%eax

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40000790:	b8 03 00 00 00       	mov    $0x3,%eax
40000795:	cd 30                	int    $0x30
40000797:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
4000079e:	00 
4000079f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400007a6:	00 
400007a7:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
400007ae:	e8 81 fa ff ff       	call   40000234 <join>

	cprintf("testvm: forkcheck passed\n");
400007b3:	c7 04 24 aa 57 00 40 	movl   $0x400057aa,(%esp)
400007ba:	e8 e2 26 00 00       	call   40002ea1 <cprintf>
}
400007bf:	c9                   	leave  
400007c0:	c3                   	ret    

400007c1 <protcheck>:

// Check for proper virtual memory protection
void
protcheck()
{
400007c1:	55                   	push   %ebp
400007c2:	89 e5                	mov    %esp,%ebp
400007c4:	57                   	push   %edi
400007c5:	56                   	push   %esi
400007c6:	53                   	push   %ebx
400007c7:	81 ec bc 01 00 00    	sub    $0x1bc,%esp
	// Copyin/copyout protection:
	// make sure we can't use cputs/put/get data in kernel space
	cputsfaulttest(0);
400007cd:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400007d4:	00 
400007d5:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
400007dc:	e8 73 f9 ff ff       	call   40000154 <fork>
400007e1:	85 c0                	test   %eax,%eax
400007e3:	75 1e                	jne    40000803 <protcheck+0x42>
400007e5:	c7 85 58 fe ff ff 00 	movl   $0x0,0xfffffe58(%ebp)
400007ec:	00 00 00 
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %0" :
400007ef:	b8 00 00 00 00       	mov    $0x0,%eax
400007f4:	8b 9d 58 fe ff ff    	mov    0xfffffe58(%ebp),%ebx
400007fa:	cd 30                	int    $0x30
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
400007fc:	b8 03 00 00 00       	mov    $0x3,%eax
40000801:	cd 30                	int    $0x30
40000803:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
4000080a:	00 
4000080b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000812:	00 
40000813:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
4000081a:	e8 15 fa ff ff       	call   40000234 <join>
	cputsfaulttest(VM_USERLO-1);
4000081f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000826:	00 
40000827:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
4000082e:	e8 21 f9 ff ff       	call   40000154 <fork>
40000833:	85 c0                	test   %eax,%eax
40000835:	75 1e                	jne    40000855 <protcheck+0x94>
40000837:	c7 85 5c fe ff ff ff 	movl   $0x3fffffff,0xfffffe5c(%ebp)
4000083e:	ff ff 3f 
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %0" :
40000841:	b8 00 00 00 00       	mov    $0x0,%eax
40000846:	8b 9d 5c fe ff ff    	mov    0xfffffe5c(%ebp),%ebx
4000084c:	cd 30                	int    $0x30
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
4000084e:	b8 03 00 00 00       	mov    $0x3,%eax
40000853:	cd 30                	int    $0x30
40000855:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
4000085c:	00 
4000085d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000864:	00 
40000865:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
4000086c:	e8 c3 f9 ff ff       	call   40000234 <join>
	cputsfaulttest(VM_USERHI);
40000871:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000878:	00 
40000879:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000880:	e8 cf f8 ff ff       	call   40000154 <fork>
40000885:	85 c0                	test   %eax,%eax
40000887:	75 1e                	jne    400008a7 <protcheck+0xe6>
40000889:	c7 85 60 fe ff ff 00 	movl   $0xf0000000,0xfffffe60(%ebp)
40000890:	00 00 f0 
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %0" :
40000893:	b8 00 00 00 00       	mov    $0x0,%eax
40000898:	8b 9d 60 fe ff ff    	mov    0xfffffe60(%ebp),%ebx
4000089e:	cd 30                	int    $0x30
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
400008a0:	b8 03 00 00 00       	mov    $0x3,%eax
400008a5:	cd 30                	int    $0x30
400008a7:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
400008ae:	00 
400008af:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400008b6:	00 
400008b7:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
400008be:	e8 71 f9 ff ff       	call   40000234 <join>
	cputsfaulttest(~0);
400008c3:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400008ca:	00 
400008cb:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
400008d2:	e8 7d f8 ff ff       	call   40000154 <fork>
400008d7:	85 c0                	test   %eax,%eax
400008d9:	75 1e                	jne    400008f9 <protcheck+0x138>
400008db:	c7 85 64 fe ff ff ff 	movl   $0xffffffff,0xfffffe64(%ebp)
400008e2:	ff ff ff 
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %0" :
400008e5:	b8 00 00 00 00       	mov    $0x0,%eax
400008ea:	8b 9d 64 fe ff ff    	mov    0xfffffe64(%ebp),%ebx
400008f0:	cd 30                	int    $0x30
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
400008f2:	b8 03 00 00 00       	mov    $0x3,%eax
400008f7:	cd 30                	int    $0x30
400008f9:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40000900:	00 
40000901:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000908:	00 
40000909:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000910:	e8 1f f9 ff ff       	call   40000234 <join>
	putfaulttest(0);
40000915:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000091c:	00 
4000091d:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000924:	e8 2b f8 ff ff       	call   40000154 <fork>
40000929:	85 c0                	test   %eax,%eax
4000092b:	75 6c                	jne    40000999 <protcheck+0x1d8>
4000092d:	c7 85 7c fe ff ff 00 	movl   $0x1000,0xfffffe7c(%ebp)
40000934:	10 00 00 
40000937:	66 c7 85 7a fe ff ff 	movw   $0x0,0xfffffe7a(%ebp)
4000093e:	00 00 
40000940:	c7 85 74 fe ff ff 00 	movl   $0x0,0xfffffe74(%ebp)
40000947:	00 00 00 
4000094a:	c7 85 70 fe ff ff 00 	movl   $0x0,0xfffffe70(%ebp)
40000951:	00 00 00 
40000954:	c7 85 6c fe ff ff 00 	movl   $0x0,0xfffffe6c(%ebp)
4000095b:	00 00 00 
4000095e:	c7 85 68 fe ff ff 00 	movl   $0x0,0xfffffe68(%ebp)
40000965:	00 00 00 
static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
40000968:	8b 85 7c fe ff ff    	mov    0xfffffe7c(%ebp),%eax
4000096e:	83 c8 01             	or     $0x1,%eax
40000971:	8b 9d 74 fe ff ff    	mov    0xfffffe74(%ebp),%ebx
40000977:	0f b7 95 7a fe ff ff 	movzwl 0xfffffe7a(%ebp),%edx
4000097e:	8b b5 70 fe ff ff    	mov    0xfffffe70(%ebp),%esi
40000984:	8b bd 6c fe ff ff    	mov    0xfffffe6c(%ebp),%edi
4000098a:	8b 8d 68 fe ff ff    	mov    0xfffffe68(%ebp),%ecx
40000990:	cd 30                	int    $0x30
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
40000992:	b8 03 00 00 00       	mov    $0x3,%eax
40000997:	cd 30                	int    $0x30
40000999:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
400009a0:	00 
400009a1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400009a8:	00 
400009a9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
400009b0:	e8 7f f8 ff ff       	call   40000234 <join>
	putfaulttest(VM_USERLO-1);
400009b5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400009bc:	00 
400009bd:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
400009c4:	e8 8b f7 ff ff       	call   40000154 <fork>
400009c9:	85 c0                	test   %eax,%eax
400009cb:	75 6c                	jne    40000a39 <protcheck+0x278>
400009cd:	c7 85 94 fe ff ff 00 	movl   $0x1000,0xfffffe94(%ebp)
400009d4:	10 00 00 
400009d7:	66 c7 85 92 fe ff ff 	movw   $0x0,0xfffffe92(%ebp)
400009de:	00 00 
400009e0:	c7 85 8c fe ff ff ff 	movl   $0x3fffffff,0xfffffe8c(%ebp)
400009e7:	ff ff 3f 
400009ea:	c7 85 88 fe ff ff 00 	movl   $0x0,0xfffffe88(%ebp)
400009f1:	00 00 00 
400009f4:	c7 85 84 fe ff ff 00 	movl   $0x0,0xfffffe84(%ebp)
400009fb:	00 00 00 
400009fe:	c7 85 80 fe ff ff 00 	movl   $0x0,0xfffffe80(%ebp)
40000a05:	00 00 00 
static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
40000a08:	8b 85 94 fe ff ff    	mov    0xfffffe94(%ebp),%eax
40000a0e:	83 c8 01             	or     $0x1,%eax
40000a11:	8b 9d 8c fe ff ff    	mov    0xfffffe8c(%ebp),%ebx
40000a17:	0f b7 95 92 fe ff ff 	movzwl 0xfffffe92(%ebp),%edx
40000a1e:	8b b5 88 fe ff ff    	mov    0xfffffe88(%ebp),%esi
40000a24:	8b bd 84 fe ff ff    	mov    0xfffffe84(%ebp),%edi
40000a2a:	8b 8d 80 fe ff ff    	mov    0xfffffe80(%ebp),%ecx
40000a30:	cd 30                	int    $0x30
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
40000a32:	b8 03 00 00 00       	mov    $0x3,%eax
40000a37:	cd 30                	int    $0x30
40000a39:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40000a40:	00 
40000a41:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000a48:	00 
40000a49:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000a50:	e8 df f7 ff ff       	call   40000234 <join>
	putfaulttest(VM_USERHI);
40000a55:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000a5c:	00 
40000a5d:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000a64:	e8 eb f6 ff ff       	call   40000154 <fork>
40000a69:	85 c0                	test   %eax,%eax
40000a6b:	75 6c                	jne    40000ad9 <protcheck+0x318>
40000a6d:	c7 85 ac fe ff ff 00 	movl   $0x1000,0xfffffeac(%ebp)
40000a74:	10 00 00 
40000a77:	66 c7 85 aa fe ff ff 	movw   $0x0,0xfffffeaa(%ebp)
40000a7e:	00 00 
40000a80:	c7 85 a4 fe ff ff 00 	movl   $0xf0000000,0xfffffea4(%ebp)
40000a87:	00 00 f0 
40000a8a:	c7 85 a0 fe ff ff 00 	movl   $0x0,0xfffffea0(%ebp)
40000a91:	00 00 00 
40000a94:	c7 85 9c fe ff ff 00 	movl   $0x0,0xfffffe9c(%ebp)
40000a9b:	00 00 00 
40000a9e:	c7 85 98 fe ff ff 00 	movl   $0x0,0xfffffe98(%ebp)
40000aa5:	00 00 00 
static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
40000aa8:	8b 85 ac fe ff ff    	mov    0xfffffeac(%ebp),%eax
40000aae:	83 c8 01             	or     $0x1,%eax
40000ab1:	8b 9d a4 fe ff ff    	mov    0xfffffea4(%ebp),%ebx
40000ab7:	0f b7 95 aa fe ff ff 	movzwl 0xfffffeaa(%ebp),%edx
40000abe:	8b b5 a0 fe ff ff    	mov    0xfffffea0(%ebp),%esi
40000ac4:	8b bd 9c fe ff ff    	mov    0xfffffe9c(%ebp),%edi
40000aca:	8b 8d 98 fe ff ff    	mov    0xfffffe98(%ebp),%ecx
40000ad0:	cd 30                	int    $0x30
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
40000ad2:	b8 03 00 00 00       	mov    $0x3,%eax
40000ad7:	cd 30                	int    $0x30
40000ad9:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40000ae0:	00 
40000ae1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000ae8:	00 
40000ae9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000af0:	e8 3f f7 ff ff       	call   40000234 <join>
	putfaulttest(~0);
40000af5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000afc:	00 
40000afd:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000b04:	e8 4b f6 ff ff       	call   40000154 <fork>
40000b09:	85 c0                	test   %eax,%eax
40000b0b:	75 6c                	jne    40000b79 <protcheck+0x3b8>
40000b0d:	c7 85 c4 fe ff ff 00 	movl   $0x1000,0xfffffec4(%ebp)
40000b14:	10 00 00 
40000b17:	66 c7 85 c2 fe ff ff 	movw   $0x0,0xfffffec2(%ebp)
40000b1e:	00 00 
40000b20:	c7 85 bc fe ff ff ff 	movl   $0xffffffff,0xfffffebc(%ebp)
40000b27:	ff ff ff 
40000b2a:	c7 85 b8 fe ff ff 00 	movl   $0x0,0xfffffeb8(%ebp)
40000b31:	00 00 00 
40000b34:	c7 85 b4 fe ff ff 00 	movl   $0x0,0xfffffeb4(%ebp)
40000b3b:	00 00 00 
40000b3e:	c7 85 b0 fe ff ff 00 	movl   $0x0,0xfffffeb0(%ebp)
40000b45:	00 00 00 
static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
40000b48:	8b 85 c4 fe ff ff    	mov    0xfffffec4(%ebp),%eax
40000b4e:	83 c8 01             	or     $0x1,%eax
40000b51:	8b 9d bc fe ff ff    	mov    0xfffffebc(%ebp),%ebx
40000b57:	0f b7 95 c2 fe ff ff 	movzwl 0xfffffec2(%ebp),%edx
40000b5e:	8b b5 b8 fe ff ff    	mov    0xfffffeb8(%ebp),%esi
40000b64:	8b bd b4 fe ff ff    	mov    0xfffffeb4(%ebp),%edi
40000b6a:	8b 8d b0 fe ff ff    	mov    0xfffffeb0(%ebp),%ecx
40000b70:	cd 30                	int    $0x30
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
40000b72:	b8 03 00 00 00       	mov    $0x3,%eax
40000b77:	cd 30                	int    $0x30
40000b79:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40000b80:	00 
40000b81:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000b88:	00 
40000b89:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000b90:	e8 9f f6 ff ff       	call   40000234 <join>
	getfaulttest(0);
40000b95:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000b9c:	00 
40000b9d:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000ba4:	e8 ab f5 ff ff       	call   40000154 <fork>
40000ba9:	85 c0                	test   %eax,%eax
40000bab:	75 6c                	jne    40000c19 <protcheck+0x458>
40000bad:	c7 85 dc fe ff ff 00 	movl   $0x1000,0xfffffedc(%ebp)
40000bb4:	10 00 00 
40000bb7:	66 c7 85 da fe ff ff 	movw   $0x0,0xfffffeda(%ebp)
40000bbe:	00 00 
40000bc0:	c7 85 d4 fe ff ff 00 	movl   $0x0,0xfffffed4(%ebp)
40000bc7:	00 00 00 
40000bca:	c7 85 d0 fe ff ff 00 	movl   $0x0,0xfffffed0(%ebp)
40000bd1:	00 00 00 
40000bd4:	c7 85 cc fe ff ff 00 	movl   $0x0,0xfffffecc(%ebp)
40000bdb:	00 00 00 
40000bde:	c7 85 c8 fe ff ff 00 	movl   $0x0,0xfffffec8(%ebp)
40000be5:	00 00 00 
static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40000be8:	8b 85 dc fe ff ff    	mov    0xfffffedc(%ebp),%eax
40000bee:	83 c8 02             	or     $0x2,%eax
40000bf1:	8b 9d d4 fe ff ff    	mov    0xfffffed4(%ebp),%ebx
40000bf7:	0f b7 95 da fe ff ff 	movzwl 0xfffffeda(%ebp),%edx
40000bfe:	8b b5 d0 fe ff ff    	mov    0xfffffed0(%ebp),%esi
40000c04:	8b bd cc fe ff ff    	mov    0xfffffecc(%ebp),%edi
40000c0a:	8b 8d c8 fe ff ff    	mov    0xfffffec8(%ebp),%ecx
40000c10:	cd 30                	int    $0x30
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
40000c12:	b8 03 00 00 00       	mov    $0x3,%eax
40000c17:	cd 30                	int    $0x30
40000c19:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40000c20:	00 
40000c21:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000c28:	00 
40000c29:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000c30:	e8 ff f5 ff ff       	call   40000234 <join>
	getfaulttest(VM_USERLO-1);
40000c35:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000c3c:	00 
40000c3d:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000c44:	e8 0b f5 ff ff       	call   40000154 <fork>
40000c49:	85 c0                	test   %eax,%eax
40000c4b:	75 6c                	jne    40000cb9 <protcheck+0x4f8>
40000c4d:	c7 85 f4 fe ff ff 00 	movl   $0x1000,0xfffffef4(%ebp)
40000c54:	10 00 00 
40000c57:	66 c7 85 f2 fe ff ff 	movw   $0x0,0xfffffef2(%ebp)
40000c5e:	00 00 
40000c60:	c7 85 ec fe ff ff ff 	movl   $0x3fffffff,0xfffffeec(%ebp)
40000c67:	ff ff 3f 
40000c6a:	c7 85 e8 fe ff ff 00 	movl   $0x0,0xfffffee8(%ebp)
40000c71:	00 00 00 
40000c74:	c7 85 e4 fe ff ff 00 	movl   $0x0,0xfffffee4(%ebp)
40000c7b:	00 00 00 
40000c7e:	c7 85 e0 fe ff ff 00 	movl   $0x0,0xfffffee0(%ebp)
40000c85:	00 00 00 
static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40000c88:	8b 85 f4 fe ff ff    	mov    0xfffffef4(%ebp),%eax
40000c8e:	83 c8 02             	or     $0x2,%eax
40000c91:	8b 9d ec fe ff ff    	mov    0xfffffeec(%ebp),%ebx
40000c97:	0f b7 95 f2 fe ff ff 	movzwl 0xfffffef2(%ebp),%edx
40000c9e:	8b b5 e8 fe ff ff    	mov    0xfffffee8(%ebp),%esi
40000ca4:	8b bd e4 fe ff ff    	mov    0xfffffee4(%ebp),%edi
40000caa:	8b 8d e0 fe ff ff    	mov    0xfffffee0(%ebp),%ecx
40000cb0:	cd 30                	int    $0x30
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
40000cb2:	b8 03 00 00 00       	mov    $0x3,%eax
40000cb7:	cd 30                	int    $0x30
40000cb9:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40000cc0:	00 
40000cc1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000cc8:	00 
40000cc9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000cd0:	e8 5f f5 ff ff       	call   40000234 <join>
	getfaulttest(VM_USERHI);
40000cd5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000cdc:	00 
40000cdd:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000ce4:	e8 6b f4 ff ff       	call   40000154 <fork>
40000ce9:	85 c0                	test   %eax,%eax
40000ceb:	75 6c                	jne    40000d59 <protcheck+0x598>
40000ced:	c7 85 0c ff ff ff 00 	movl   $0x1000,0xffffff0c(%ebp)
40000cf4:	10 00 00 
40000cf7:	66 c7 85 0a ff ff ff 	movw   $0x0,0xffffff0a(%ebp)
40000cfe:	00 00 
40000d00:	c7 85 04 ff ff ff 00 	movl   $0xf0000000,0xffffff04(%ebp)
40000d07:	00 00 f0 
40000d0a:	c7 85 00 ff ff ff 00 	movl   $0x0,0xffffff00(%ebp)
40000d11:	00 00 00 
40000d14:	c7 85 fc fe ff ff 00 	movl   $0x0,0xfffffefc(%ebp)
40000d1b:	00 00 00 
40000d1e:	c7 85 f8 fe ff ff 00 	movl   $0x0,0xfffffef8(%ebp)
40000d25:	00 00 00 
static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40000d28:	8b 85 0c ff ff ff    	mov    0xffffff0c(%ebp),%eax
40000d2e:	83 c8 02             	or     $0x2,%eax
40000d31:	8b 9d 04 ff ff ff    	mov    0xffffff04(%ebp),%ebx
40000d37:	0f b7 95 0a ff ff ff 	movzwl 0xffffff0a(%ebp),%edx
40000d3e:	8b b5 00 ff ff ff    	mov    0xffffff00(%ebp),%esi
40000d44:	8b bd fc fe ff ff    	mov    0xfffffefc(%ebp),%edi
40000d4a:	8b 8d f8 fe ff ff    	mov    0xfffffef8(%ebp),%ecx
40000d50:	cd 30                	int    $0x30
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
40000d52:	b8 03 00 00 00       	mov    $0x3,%eax
40000d57:	cd 30                	int    $0x30
40000d59:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40000d60:	00 
40000d61:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000d68:	00 
40000d69:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000d70:	e8 bf f4 ff ff       	call   40000234 <join>
	getfaulttest(~0);
40000d75:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000d7c:	00 
40000d7d:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000d84:	e8 cb f3 ff ff       	call   40000154 <fork>
40000d89:	85 c0                	test   %eax,%eax
40000d8b:	75 6c                	jne    40000df9 <protcheck+0x638>
40000d8d:	c7 85 24 ff ff ff 00 	movl   $0x1000,0xffffff24(%ebp)
40000d94:	10 00 00 
40000d97:	66 c7 85 22 ff ff ff 	movw   $0x0,0xffffff22(%ebp)
40000d9e:	00 00 
40000da0:	c7 85 1c ff ff ff ff 	movl   $0xffffffff,0xffffff1c(%ebp)
40000da7:	ff ff ff 
40000daa:	c7 85 18 ff ff ff 00 	movl   $0x0,0xffffff18(%ebp)
40000db1:	00 00 00 
40000db4:	c7 85 14 ff ff ff 00 	movl   $0x0,0xffffff14(%ebp)
40000dbb:	00 00 00 
40000dbe:	c7 85 10 ff ff ff 00 	movl   $0x0,0xffffff10(%ebp)
40000dc5:	00 00 00 
static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40000dc8:	8b 85 24 ff ff ff    	mov    0xffffff24(%ebp),%eax
40000dce:	83 c8 02             	or     $0x2,%eax
40000dd1:	8b 9d 1c ff ff ff    	mov    0xffffff1c(%ebp),%ebx
40000dd7:	0f b7 95 22 ff ff ff 	movzwl 0xffffff22(%ebp),%edx
40000dde:	8b b5 18 ff ff ff    	mov    0xffffff18(%ebp),%esi
40000de4:	8b bd 14 ff ff ff    	mov    0xffffff14(%ebp),%edi
40000dea:	8b 8d 10 ff ff ff    	mov    0xffffff10(%ebp),%ecx
40000df0:	cd 30                	int    $0x30
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
40000df2:	b8 03 00 00 00       	mov    $0x3,%eax
40000df7:	cd 30                	int    $0x30
40000df9:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40000e00:	00 
40000e01:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000e08:	00 
40000e09:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000e10:	e8 1f f4 ff ff       	call   40000234 <join>

warn("here");
40000e15:	c7 44 24 08 c4 57 00 	movl   $0x400057c4,0x8(%esp)
40000e1c:	40 
40000e1d:	c7 44 24 04 dd 00 00 	movl   $0xdd,0x4(%esp)
40000e24:	00 
40000e25:	c7 04 24 88 56 00 40 	movl   $0x40005688,(%esp)
40000e2c:	e8 21 1e 00 00       	call   40002c52 <debug_warn>
	// Check that unused parts of user space are also inaccessible
	readfaulttest(VM_USERLO+PTSIZE);
40000e31:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000e38:	00 
40000e39:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000e40:	e8 0f f3 ff ff       	call   40000154 <fork>
40000e45:	85 c0                	test   %eax,%eax
40000e47:	75 0e                	jne    40000e57 <protcheck+0x696>
40000e49:	b8 00 00 40 40       	mov    $0x40400000,%eax
40000e4e:	8b 00                	mov    (%eax),%eax

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40000e50:	b8 03 00 00 00       	mov    $0x3,%eax
40000e55:	cd 30                	int    $0x30
40000e57:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40000e5e:	00 
40000e5f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000e66:	00 
40000e67:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000e6e:	e8 c1 f3 ff ff       	call   40000234 <join>
warn("here");
40000e73:	c7 44 24 08 c4 57 00 	movl   $0x400057c4,0x8(%esp)
40000e7a:	40 
40000e7b:	c7 44 24 04 e0 00 00 	movl   $0xe0,0x4(%esp)
40000e82:	00 
40000e83:	c7 04 24 88 56 00 40 	movl   $0x40005688,(%esp)
40000e8a:	e8 c3 1d 00 00       	call   40002c52 <debug_warn>
	readfaulttest(VM_USERHI-PTSIZE);
40000e8f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000e96:	00 
40000e97:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000e9e:	e8 b1 f2 ff ff       	call   40000154 <fork>
40000ea3:	85 c0                	test   %eax,%eax
40000ea5:	75 0e                	jne    40000eb5 <protcheck+0x6f4>
40000ea7:	b8 00 00 c0 ef       	mov    $0xefc00000,%eax
40000eac:	8b 00                	mov    (%eax),%eax

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40000eae:	b8 03 00 00 00       	mov    $0x3,%eax
40000eb3:	cd 30                	int    $0x30
40000eb5:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40000ebc:	00 
40000ebd:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000ec4:	00 
40000ec5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000ecc:	e8 63 f3 ff ff       	call   40000234 <join>
warn("here");
40000ed1:	c7 44 24 08 c4 57 00 	movl   $0x400057c4,0x8(%esp)
40000ed8:	40 
40000ed9:	c7 44 24 04 e2 00 00 	movl   $0xe2,0x4(%esp)
40000ee0:	00 
40000ee1:	c7 04 24 88 56 00 40 	movl   $0x40005688,(%esp)
40000ee8:	e8 65 1d 00 00       	call   40002c52 <debug_warn>
	readfaulttest(VM_USERHI-PTSIZE*2);
40000eed:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000ef4:	00 
40000ef5:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000efc:	e8 53 f2 ff ff       	call   40000154 <fork>
40000f01:	85 c0                	test   %eax,%eax
40000f03:	75 0e                	jne    40000f13 <protcheck+0x752>
40000f05:	b8 00 00 80 ef       	mov    $0xef800000,%eax
40000f0a:	8b 00                	mov    (%eax),%eax

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40000f0c:	b8 03 00 00 00       	mov    $0x3,%eax
40000f11:	cd 30                	int    $0x30
40000f13:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40000f1a:	00 
40000f1b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000f22:	00 
40000f23:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000f2a:	e8 05 f3 ff ff       	call   40000234 <join>
warn("here");
40000f2f:	c7 44 24 08 c4 57 00 	movl   $0x400057c4,0x8(%esp)
40000f36:	40 
40000f37:	c7 44 24 04 e4 00 00 	movl   $0xe4,0x4(%esp)
40000f3e:	00 
40000f3f:	c7 04 24 88 56 00 40 	movl   $0x40005688,(%esp)
40000f46:	e8 07 1d 00 00       	call   40002c52 <debug_warn>
	cputsfaulttest(VM_USERLO+PTSIZE);
40000f4b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000f52:	00 
40000f53:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000f5a:	e8 f5 f1 ff ff       	call   40000154 <fork>
40000f5f:	85 c0                	test   %eax,%eax
40000f61:	75 1e                	jne    40000f81 <protcheck+0x7c0>
40000f63:	c7 85 28 ff ff ff 00 	movl   $0x40400000,0xffffff28(%ebp)
40000f6a:	00 40 40 
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %0" :
40000f6d:	b8 00 00 00 00       	mov    $0x0,%eax
40000f72:	8b 9d 28 ff ff ff    	mov    0xffffff28(%ebp),%ebx
40000f78:	cd 30                	int    $0x30
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
40000f7a:	b8 03 00 00 00       	mov    $0x3,%eax
40000f7f:	cd 30                	int    $0x30
40000f81:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40000f88:	00 
40000f89:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000f90:	00 
40000f91:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000f98:	e8 97 f2 ff ff       	call   40000234 <join>
warn("here");
40000f9d:	c7 44 24 08 c4 57 00 	movl   $0x400057c4,0x8(%esp)
40000fa4:	40 
40000fa5:	c7 44 24 04 e6 00 00 	movl   $0xe6,0x4(%esp)
40000fac:	00 
40000fad:	c7 04 24 88 56 00 40 	movl   $0x40005688,(%esp)
40000fb4:	e8 99 1c 00 00       	call   40002c52 <debug_warn>
	cputsfaulttest(VM_USERHI-PTSIZE);
40000fb9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000fc0:	00 
40000fc1:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000fc8:	e8 87 f1 ff ff       	call   40000154 <fork>
40000fcd:	85 c0                	test   %eax,%eax
40000fcf:	75 1e                	jne    40000fef <protcheck+0x82e>
40000fd1:	c7 85 2c ff ff ff 00 	movl   $0xefc00000,0xffffff2c(%ebp)
40000fd8:	00 c0 ef 
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %0" :
40000fdb:	b8 00 00 00 00       	mov    $0x0,%eax
40000fe0:	8b 9d 2c ff ff ff    	mov    0xffffff2c(%ebp),%ebx
40000fe6:	cd 30                	int    $0x30
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
40000fe8:	b8 03 00 00 00       	mov    $0x3,%eax
40000fed:	cd 30                	int    $0x30
40000fef:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40000ff6:	00 
40000ff7:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000ffe:	00 
40000fff:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40001006:	e8 29 f2 ff ff       	call   40000234 <join>
warn("here");
4000100b:	c7 44 24 08 c4 57 00 	movl   $0x400057c4,0x8(%esp)
40001012:	40 
40001013:	c7 44 24 04 e8 00 00 	movl   $0xe8,0x4(%esp)
4000101a:	00 
4000101b:	c7 04 24 88 56 00 40 	movl   $0x40005688,(%esp)
40001022:	e8 2b 1c 00 00       	call   40002c52 <debug_warn>
	cputsfaulttest(VM_USERHI-PTSIZE*2);
40001027:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000102e:	00 
4000102f:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40001036:	e8 19 f1 ff ff       	call   40000154 <fork>
4000103b:	85 c0                	test   %eax,%eax
4000103d:	75 1e                	jne    4000105d <protcheck+0x89c>
4000103f:	c7 85 30 ff ff ff 00 	movl   $0xef800000,0xffffff30(%ebp)
40001046:	00 80 ef 
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %0" :
40001049:	b8 00 00 00 00       	mov    $0x0,%eax
4000104e:	8b 9d 30 ff ff ff    	mov    0xffffff30(%ebp),%ebx
40001054:	cd 30                	int    $0x30
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
40001056:	b8 03 00 00 00       	mov    $0x3,%eax
4000105b:	cd 30                	int    $0x30
4000105d:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40001064:	00 
40001065:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000106c:	00 
4000106d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40001074:	e8 bb f1 ff ff       	call   40000234 <join>
warn("here");
40001079:	c7 44 24 08 c4 57 00 	movl   $0x400057c4,0x8(%esp)
40001080:	40 
40001081:	c7 44 24 04 ea 00 00 	movl   $0xea,0x4(%esp)
40001088:	00 
40001089:	c7 04 24 88 56 00 40 	movl   $0x40005688,(%esp)
40001090:	e8 bd 1b 00 00       	call   40002c52 <debug_warn>
	putfaulttest(VM_USERLO+PTSIZE);
40001095:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000109c:	00 
4000109d:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
400010a4:	e8 ab f0 ff ff       	call   40000154 <fork>
400010a9:	85 c0                	test   %eax,%eax
400010ab:	75 6c                	jne    40001119 <protcheck+0x958>
400010ad:	c7 85 48 ff ff ff 00 	movl   $0x1000,0xffffff48(%ebp)
400010b4:	10 00 00 
400010b7:	66 c7 85 46 ff ff ff 	movw   $0x0,0xffffff46(%ebp)
400010be:	00 00 
400010c0:	c7 85 40 ff ff ff 00 	movl   $0x40400000,0xffffff40(%ebp)
400010c7:	00 40 40 
400010ca:	c7 85 3c ff ff ff 00 	movl   $0x0,0xffffff3c(%ebp)
400010d1:	00 00 00 
400010d4:	c7 85 38 ff ff ff 00 	movl   $0x0,0xffffff38(%ebp)
400010db:	00 00 00 
400010de:	c7 85 34 ff ff ff 00 	movl   $0x0,0xffffff34(%ebp)
400010e5:	00 00 00 
static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
400010e8:	8b 85 48 ff ff ff    	mov    0xffffff48(%ebp),%eax
400010ee:	83 c8 01             	or     $0x1,%eax
400010f1:	8b 9d 40 ff ff ff    	mov    0xffffff40(%ebp),%ebx
400010f7:	0f b7 95 46 ff ff ff 	movzwl 0xffffff46(%ebp),%edx
400010fe:	8b b5 3c ff ff ff    	mov    0xffffff3c(%ebp),%esi
40001104:	8b bd 38 ff ff ff    	mov    0xffffff38(%ebp),%edi
4000110a:	8b 8d 34 ff ff ff    	mov    0xffffff34(%ebp),%ecx
40001110:	cd 30                	int    $0x30
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
40001112:	b8 03 00 00 00       	mov    $0x3,%eax
40001117:	cd 30                	int    $0x30
40001119:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40001120:	00 
40001121:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001128:	00 
40001129:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40001130:	e8 ff f0 ff ff       	call   40000234 <join>
warn("here");
40001135:	c7 44 24 08 c4 57 00 	movl   $0x400057c4,0x8(%esp)
4000113c:	40 
4000113d:	c7 44 24 04 ec 00 00 	movl   $0xec,0x4(%esp)
40001144:	00 
40001145:	c7 04 24 88 56 00 40 	movl   $0x40005688,(%esp)
4000114c:	e8 01 1b 00 00       	call   40002c52 <debug_warn>
	putfaulttest(VM_USERHI-PTSIZE);
40001151:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001158:	00 
40001159:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40001160:	e8 ef ef ff ff       	call   40000154 <fork>
40001165:	85 c0                	test   %eax,%eax
40001167:	75 6c                	jne    400011d5 <protcheck+0xa14>
40001169:	c7 85 60 ff ff ff 00 	movl   $0x1000,0xffffff60(%ebp)
40001170:	10 00 00 
40001173:	66 c7 85 5e ff ff ff 	movw   $0x0,0xffffff5e(%ebp)
4000117a:	00 00 
4000117c:	c7 85 58 ff ff ff 00 	movl   $0xefc00000,0xffffff58(%ebp)
40001183:	00 c0 ef 
40001186:	c7 85 54 ff ff ff 00 	movl   $0x0,0xffffff54(%ebp)
4000118d:	00 00 00 
40001190:	c7 85 50 ff ff ff 00 	movl   $0x0,0xffffff50(%ebp)
40001197:	00 00 00 
4000119a:	c7 85 4c ff ff ff 00 	movl   $0x0,0xffffff4c(%ebp)
400011a1:	00 00 00 
static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
400011a4:	8b 85 60 ff ff ff    	mov    0xffffff60(%ebp),%eax
400011aa:	83 c8 01             	or     $0x1,%eax
400011ad:	8b 9d 58 ff ff ff    	mov    0xffffff58(%ebp),%ebx
400011b3:	0f b7 95 5e ff ff ff 	movzwl 0xffffff5e(%ebp),%edx
400011ba:	8b b5 54 ff ff ff    	mov    0xffffff54(%ebp),%esi
400011c0:	8b bd 50 ff ff ff    	mov    0xffffff50(%ebp),%edi
400011c6:	8b 8d 4c ff ff ff    	mov    0xffffff4c(%ebp),%ecx
400011cc:	cd 30                	int    $0x30
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
400011ce:	b8 03 00 00 00       	mov    $0x3,%eax
400011d3:	cd 30                	int    $0x30
400011d5:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
400011dc:	00 
400011dd:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400011e4:	00 
400011e5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
400011ec:	e8 43 f0 ff ff       	call   40000234 <join>
warn("here");
400011f1:	c7 44 24 08 c4 57 00 	movl   $0x400057c4,0x8(%esp)
400011f8:	40 
400011f9:	c7 44 24 04 ee 00 00 	movl   $0xee,0x4(%esp)
40001200:	00 
40001201:	c7 04 24 88 56 00 40 	movl   $0x40005688,(%esp)
40001208:	e8 45 1a 00 00       	call   40002c52 <debug_warn>
	putfaulttest(VM_USERHI-PTSIZE*2);
4000120d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001214:	00 
40001215:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
4000121c:	e8 33 ef ff ff       	call   40000154 <fork>
40001221:	85 c0                	test   %eax,%eax
40001223:	75 6c                	jne    40001291 <protcheck+0xad0>
40001225:	c7 85 78 ff ff ff 00 	movl   $0x1000,0xffffff78(%ebp)
4000122c:	10 00 00 
4000122f:	66 c7 85 76 ff ff ff 	movw   $0x0,0xffffff76(%ebp)
40001236:	00 00 
40001238:	c7 85 70 ff ff ff 00 	movl   $0xef800000,0xffffff70(%ebp)
4000123f:	00 80 ef 
40001242:	c7 85 6c ff ff ff 00 	movl   $0x0,0xffffff6c(%ebp)
40001249:	00 00 00 
4000124c:	c7 85 68 ff ff ff 00 	movl   $0x0,0xffffff68(%ebp)
40001253:	00 00 00 
40001256:	c7 85 64 ff ff ff 00 	movl   $0x0,0xffffff64(%ebp)
4000125d:	00 00 00 
static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
40001260:	8b 85 78 ff ff ff    	mov    0xffffff78(%ebp),%eax
40001266:	83 c8 01             	or     $0x1,%eax
40001269:	8b 9d 70 ff ff ff    	mov    0xffffff70(%ebp),%ebx
4000126f:	0f b7 95 76 ff ff ff 	movzwl 0xffffff76(%ebp),%edx
40001276:	8b b5 6c ff ff ff    	mov    0xffffff6c(%ebp),%esi
4000127c:	8b bd 68 ff ff ff    	mov    0xffffff68(%ebp),%edi
40001282:	8b 8d 64 ff ff ff    	mov    0xffffff64(%ebp),%ecx
40001288:	cd 30                	int    $0x30
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
4000128a:	b8 03 00 00 00       	mov    $0x3,%eax
4000128f:	cd 30                	int    $0x30
40001291:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40001298:	00 
40001299:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400012a0:	00 
400012a1:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
400012a8:	e8 87 ef ff ff       	call   40000234 <join>
warn("here");
400012ad:	c7 44 24 08 c4 57 00 	movl   $0x400057c4,0x8(%esp)
400012b4:	40 
400012b5:	c7 44 24 04 f0 00 00 	movl   $0xf0,0x4(%esp)
400012bc:	00 
400012bd:	c7 04 24 88 56 00 40 	movl   $0x40005688,(%esp)
400012c4:	e8 89 19 00 00       	call   40002c52 <debug_warn>
	getfaulttest(VM_USERLO+PTSIZE);
400012c9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400012d0:	00 
400012d1:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
400012d8:	e8 77 ee ff ff       	call   40000154 <fork>
400012dd:	85 c0                	test   %eax,%eax
400012df:	75 4e                	jne    4000132f <protcheck+0xb6e>
400012e1:	c7 45 90 00 10 00 00 	movl   $0x1000,0xffffff90(%ebp)
400012e8:	66 c7 45 8e 00 00    	movw   $0x0,0xffffff8e(%ebp)
400012ee:	c7 45 88 00 00 40 40 	movl   $0x40400000,0xffffff88(%ebp)
400012f5:	c7 45 84 00 00 00 00 	movl   $0x0,0xffffff84(%ebp)
400012fc:	c7 45 80 00 00 00 00 	movl   $0x0,0xffffff80(%ebp)
40001303:	c7 85 7c ff ff ff 00 	movl   $0x0,0xffffff7c(%ebp)
4000130a:	00 00 00 
static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
4000130d:	8b 45 90             	mov    0xffffff90(%ebp),%eax
40001310:	83 c8 02             	or     $0x2,%eax
40001313:	8b 5d 88             	mov    0xffffff88(%ebp),%ebx
40001316:	0f b7 55 8e          	movzwl 0xffffff8e(%ebp),%edx
4000131a:	8b 75 84             	mov    0xffffff84(%ebp),%esi
4000131d:	8b 7d 80             	mov    0xffffff80(%ebp),%edi
40001320:	8b 8d 7c ff ff ff    	mov    0xffffff7c(%ebp),%ecx
40001326:	cd 30                	int    $0x30
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
40001328:	b8 03 00 00 00       	mov    $0x3,%eax
4000132d:	cd 30                	int    $0x30
4000132f:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40001336:	00 
40001337:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000133e:	00 
4000133f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40001346:	e8 e9 ee ff ff       	call   40000234 <join>
warn("here");
4000134b:	c7 44 24 08 c4 57 00 	movl   $0x400057c4,0x8(%esp)
40001352:	40 
40001353:	c7 44 24 04 f2 00 00 	movl   $0xf2,0x4(%esp)
4000135a:	00 
4000135b:	c7 04 24 88 56 00 40 	movl   $0x40005688,(%esp)
40001362:	e8 eb 18 00 00       	call   40002c52 <debug_warn>
	getfaulttest(VM_USERHI-PTSIZE);
40001367:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000136e:	00 
4000136f:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40001376:	e8 d9 ed ff ff       	call   40000154 <fork>
4000137b:	85 c0                	test   %eax,%eax
4000137d:	75 48                	jne    400013c7 <protcheck+0xc06>
4000137f:	c7 45 a8 00 10 00 00 	movl   $0x1000,0xffffffa8(%ebp)
40001386:	66 c7 45 a6 00 00    	movw   $0x0,0xffffffa6(%ebp)
4000138c:	c7 45 a0 00 00 c0 ef 	movl   $0xefc00000,0xffffffa0(%ebp)
40001393:	c7 45 9c 00 00 00 00 	movl   $0x0,0xffffff9c(%ebp)
4000139a:	c7 45 98 00 00 00 00 	movl   $0x0,0xffffff98(%ebp)
400013a1:	c7 45 94 00 00 00 00 	movl   $0x0,0xffffff94(%ebp)
static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
400013a8:	8b 45 a8             	mov    0xffffffa8(%ebp),%eax
400013ab:	83 c8 02             	or     $0x2,%eax
400013ae:	8b 5d a0             	mov    0xffffffa0(%ebp),%ebx
400013b1:	0f b7 55 a6          	movzwl 0xffffffa6(%ebp),%edx
400013b5:	8b 75 9c             	mov    0xffffff9c(%ebp),%esi
400013b8:	8b 7d 98             	mov    0xffffff98(%ebp),%edi
400013bb:	8b 4d 94             	mov    0xffffff94(%ebp),%ecx
400013be:	cd 30                	int    $0x30
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
400013c0:	b8 03 00 00 00       	mov    $0x3,%eax
400013c5:	cd 30                	int    $0x30
400013c7:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
400013ce:	00 
400013cf:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400013d6:	00 
400013d7:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
400013de:	e8 51 ee ff ff       	call   40000234 <join>
warn("here");
400013e3:	c7 44 24 08 c4 57 00 	movl   $0x400057c4,0x8(%esp)
400013ea:	40 
400013eb:	c7 44 24 04 f4 00 00 	movl   $0xf4,0x4(%esp)
400013f2:	00 
400013f3:	c7 04 24 88 56 00 40 	movl   $0x40005688,(%esp)
400013fa:	e8 53 18 00 00       	call   40002c52 <debug_warn>
	getfaulttest(VM_USERHI-PTSIZE*2);
400013ff:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001406:	00 
40001407:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
4000140e:	e8 41 ed ff ff       	call   40000154 <fork>
40001413:	85 c0                	test   %eax,%eax
40001415:	75 48                	jne    4000145f <protcheck+0xc9e>
40001417:	c7 45 c0 00 10 00 00 	movl   $0x1000,0xffffffc0(%ebp)
4000141e:	66 c7 45 be 00 00    	movw   $0x0,0xffffffbe(%ebp)
40001424:	c7 45 b8 00 00 80 ef 	movl   $0xef800000,0xffffffb8(%ebp)
4000142b:	c7 45 b4 00 00 00 00 	movl   $0x0,0xffffffb4(%ebp)
40001432:	c7 45 b0 00 00 00 00 	movl   $0x0,0xffffffb0(%ebp)
40001439:	c7 45 ac 00 00 00 00 	movl   $0x0,0xffffffac(%ebp)
static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40001440:	8b 45 c0             	mov    0xffffffc0(%ebp),%eax
40001443:	83 c8 02             	or     $0x2,%eax
40001446:	8b 5d b8             	mov    0xffffffb8(%ebp),%ebx
40001449:	0f b7 55 be          	movzwl 0xffffffbe(%ebp),%edx
4000144d:	8b 75 b4             	mov    0xffffffb4(%ebp),%esi
40001450:	8b 7d b0             	mov    0xffffffb0(%ebp),%edi
40001453:	8b 4d ac             	mov    0xffffffac(%ebp),%ecx
40001456:	cd 30                	int    $0x30
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
40001458:	b8 03 00 00 00       	mov    $0x3,%eax
4000145d:	cd 30                	int    $0x30
4000145f:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40001466:	00 
40001467:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000146e:	00 
4000146f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40001476:	e8 b9 ed ff ff       	call   40000234 <join>
warn("here");
4000147b:	c7 44 24 08 c4 57 00 	movl   $0x400057c4,0x8(%esp)
40001482:	40 
40001483:	c7 44 24 04 f6 00 00 	movl   $0xf6,0x4(%esp)
4000148a:	00 
4000148b:	c7 04 24 88 56 00 40 	movl   $0x40005688,(%esp)
40001492:	e8 bb 17 00 00       	call   40002c52 <debug_warn>

	// Check that our text segment is mapped read-only
	writefaulttest((int)start);
40001497:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000149e:	00 
4000149f:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
400014a6:	e8 a9 ec ff ff       	call   40000154 <fork>
400014ab:	85 c0                	test   %eax,%eax
400014ad:	75 1e                	jne    400014cd <protcheck+0xd0c>
400014af:	b8 00 01 00 40       	mov    $0x40000100,%eax
400014b4:	89 85 50 fe ff ff    	mov    %eax,0xfffffe50(%ebp)
400014ba:	8b 85 50 fe ff ff    	mov    0xfffffe50(%ebp),%eax
400014c0:	c7 00 ef be ad de    	movl   $0xdeadbeef,(%eax)

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
400014c6:	b8 03 00 00 00       	mov    $0x3,%eax
400014cb:	cd 30                	int    $0x30
400014cd:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
400014d4:	00 
400014d5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400014dc:	00 
400014dd:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
400014e4:	e8 4b ed ff ff       	call   40000234 <join>
	writefaulttest((int)etext-4);
400014e9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400014f0:	00 
400014f1:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
400014f8:	e8 57 ec ff ff       	call   40000154 <fork>
400014fd:	85 c0                	test   %eax,%eax
400014ff:	75 21                	jne    40001522 <protcheck+0xd61>
40001501:	b8 37 56 00 40       	mov    $0x40005637,%eax
40001506:	83 e8 04             	sub    $0x4,%eax
40001509:	89 85 54 fe ff ff    	mov    %eax,0xfffffe54(%ebp)
4000150f:	8b 85 54 fe ff ff    	mov    0xfffffe54(%ebp),%eax
40001515:	c7 00 ef be ad de    	movl   $0xdeadbeef,(%eax)

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
4000151b:	b8 03 00 00 00       	mov    $0x3,%eax
40001520:	cd 30                	int    $0x30
40001522:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40001529:	00 
4000152a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001531:	00 
40001532:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40001539:	e8 f6 ec ff ff       	call   40000234 <join>
	getfaulttest((int)start);
4000153e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001545:	00 
40001546:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
4000154d:	e8 02 ec ff ff       	call   40000154 <fork>
40001552:	85 c0                	test   %eax,%eax
40001554:	75 49                	jne    4000159f <protcheck+0xdde>
40001556:	b8 00 01 00 40       	mov    $0x40000100,%eax
4000155b:	c7 45 d8 00 10 00 00 	movl   $0x1000,0xffffffd8(%ebp)
40001562:	66 c7 45 d6 00 00    	movw   $0x0,0xffffffd6(%ebp)
40001568:	89 45 d0             	mov    %eax,0xffffffd0(%ebp)
4000156b:	c7 45 cc 00 00 00 00 	movl   $0x0,0xffffffcc(%ebp)
40001572:	c7 45 c8 00 00 00 00 	movl   $0x0,0xffffffc8(%ebp)
40001579:	c7 45 c4 00 00 00 00 	movl   $0x0,0xffffffc4(%ebp)
static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40001580:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
40001583:	83 c8 02             	or     $0x2,%eax
40001586:	8b 5d d0             	mov    0xffffffd0(%ebp),%ebx
40001589:	0f b7 55 d6          	movzwl 0xffffffd6(%ebp),%edx
4000158d:	8b 75 cc             	mov    0xffffffcc(%ebp),%esi
40001590:	8b 7d c8             	mov    0xffffffc8(%ebp),%edi
40001593:	8b 4d c4             	mov    0xffffffc4(%ebp),%ecx
40001596:	cd 30                	int    $0x30
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
40001598:	b8 03 00 00 00       	mov    $0x3,%eax
4000159d:	cd 30                	int    $0x30
4000159f:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
400015a6:	00 
400015a7:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400015ae:	00 
400015af:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
400015b6:	e8 79 ec ff ff       	call   40000234 <join>
	getfaulttest((int)etext-4);
400015bb:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400015c2:	00 
400015c3:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
400015ca:	e8 85 eb ff ff       	call   40000154 <fork>
400015cf:	85 c0                	test   %eax,%eax
400015d1:	75 4c                	jne    4000161f <protcheck+0xe5e>
400015d3:	b8 37 56 00 40       	mov    $0x40005637,%eax
400015d8:	83 e8 04             	sub    $0x4,%eax
400015db:	c7 45 f0 00 10 00 00 	movl   $0x1000,0xfffffff0(%ebp)
400015e2:	66 c7 45 ee 00 00    	movw   $0x0,0xffffffee(%ebp)
400015e8:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
400015eb:	c7 45 e4 00 00 00 00 	movl   $0x0,0xffffffe4(%ebp)
400015f2:	c7 45 e0 00 00 00 00 	movl   $0x0,0xffffffe0(%ebp)
400015f9:	c7 45 dc 00 00 00 00 	movl   $0x0,0xffffffdc(%ebp)
static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40001600:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
40001603:	83 c8 02             	or     $0x2,%eax
40001606:	8b 5d e8             	mov    0xffffffe8(%ebp),%ebx
40001609:	0f b7 55 ee          	movzwl 0xffffffee(%ebp),%edx
4000160d:	8b 75 e4             	mov    0xffffffe4(%ebp),%esi
40001610:	8b 7d e0             	mov    0xffffffe0(%ebp),%edi
40001613:	8b 4d dc             	mov    0xffffffdc(%ebp),%ecx
40001616:	cd 30                	int    $0x30
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
40001618:	b8 03 00 00 00       	mov    $0x3,%eax
4000161d:	cd 30                	int    $0x30
4000161f:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40001626:	00 
40001627:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000162e:	00 
4000162f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40001636:	e8 f9 eb ff ff       	call   40000234 <join>

	cprintf("testvm: protcheck passed\n");
4000163b:	c7 04 24 c9 57 00 40 	movl   $0x400057c9,(%esp)
40001642:	e8 5a 18 00 00       	call   40002ea1 <cprintf>
}
40001647:	81 c4 bc 01 00 00    	add    $0x1bc,%esp
4000164d:	5b                   	pop    %ebx
4000164e:	5e                   	pop    %esi
4000164f:	5f                   	pop    %edi
40001650:	5d                   	pop    %ebp
40001651:	c3                   	ret    

40001652 <memopcheck>:

// Test explicit memory management operations
void
memopcheck(void)
{
40001652:	55                   	push   %ebp
40001653:	89 e5                	mov    %esp,%ebp
40001655:	57                   	push   %edi
40001656:	56                   	push   %esi
40001657:	53                   	push   %ebx
40001658:	81 ec 5c 02 00 00    	sub    $0x25c,%esp
	// Test page permission changes
	void *va = (void*)VM_USERLO+PTSIZE+PAGESIZE;
4000165e:	c7 85 bc fd ff ff 00 	movl   $0x40401000,0xfffffdbc(%ebp)
40001665:	10 40 40 
	readfaulttest(va);
40001668:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000166f:	00 
40001670:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40001677:	e8 d8 ea ff ff       	call   40000154 <fork>
4000167c:	85 c0                	test   %eax,%eax
4000167e:	75 0f                	jne    4000168f <memopcheck+0x3d>
40001680:	8b 85 bc fd ff ff    	mov    0xfffffdbc(%ebp),%eax
40001686:	8b 00                	mov    (%eax),%eax

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40001688:	b8 03 00 00 00       	mov    $0x3,%eax
4000168d:	cd 30                	int    $0x30
4000168f:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40001696:	00 
40001697:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000169e:	00 
4000169f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
400016a6:	e8 89 eb ff ff       	call   40000234 <join>
400016ab:	c7 85 f8 fd ff ff 00 	movl   $0x300,0xfffffdf8(%ebp)
400016b2:	03 00 00 
400016b5:	66 c7 85 f6 fd ff ff 	movw   $0x0,0xfffffdf6(%ebp)
400016bc:	00 00 
400016be:	c7 85 f0 fd ff ff 00 	movl   $0x0,0xfffffdf0(%ebp)
400016c5:	00 00 00 
400016c8:	c7 85 ec fd ff ff 00 	movl   $0x0,0xfffffdec(%ebp)
400016cf:	00 00 00 
400016d2:	8b 85 bc fd ff ff    	mov    0xfffffdbc(%ebp),%eax
400016d8:	89 85 e8 fd ff ff    	mov    %eax,0xfffffde8(%ebp)
400016de:	c7 85 e4 fd ff ff 00 	movl   $0x1000,0xfffffde4(%ebp)
400016e5:	10 00 00 
static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
400016e8:	8b 85 f8 fd ff ff    	mov    0xfffffdf8(%ebp),%eax
400016ee:	83 c8 02             	or     $0x2,%eax
400016f1:	8b 9d f0 fd ff ff    	mov    0xfffffdf0(%ebp),%ebx
400016f7:	0f b7 95 f6 fd ff ff 	movzwl 0xfffffdf6(%ebp),%edx
400016fe:	8b b5 ec fd ff ff    	mov    0xfffffdec(%ebp),%esi
40001704:	8b bd e8 fd ff ff    	mov    0xfffffde8(%ebp),%edi
4000170a:	8b 8d e4 fd ff ff    	mov    0xfffffde4(%ebp),%ecx
40001710:	cd 30                	int    $0x30
	sys_get(SYS_PERM | SYS_READ, 0, NULL, NULL, va, PAGESIZE);
	assert(*(volatile int*)va == 0);	// should be readable now
40001712:	8b 85 bc fd ff ff    	mov    0xfffffdbc(%ebp),%eax
40001718:	8b 00                	mov    (%eax),%eax
4000171a:	85 c0                	test   %eax,%eax
4000171c:	74 24                	je     40001742 <memopcheck+0xf0>
4000171e:	c7 44 24 0c e3 57 00 	movl   $0x400057e3,0xc(%esp)
40001725:	40 
40001726:	c7 44 24 08 7b 57 00 	movl   $0x4000577b,0x8(%esp)
4000172d:	40 
4000172e:	c7 44 24 04 09 01 00 	movl   $0x109,0x4(%esp)
40001735:	00 
40001736:	c7 04 24 88 56 00 40 	movl   $0x40005688,(%esp)
4000173d:	e8 a6 14 00 00       	call   40002be8 <debug_panic>
	writefaulttest(va);			// but not writable
40001742:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001749:	00 
4000174a:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40001751:	e8 fe e9 ff ff       	call   40000154 <fork>
40001756:	85 c0                	test   %eax,%eax
40001758:	75 1f                	jne    40001779 <memopcheck+0x127>
4000175a:	8b 85 bc fd ff ff    	mov    0xfffffdbc(%ebp),%eax
40001760:	89 85 d0 fd ff ff    	mov    %eax,0xfffffdd0(%ebp)
40001766:	8b 85 d0 fd ff ff    	mov    0xfffffdd0(%ebp),%eax
4000176c:	c7 00 ef be ad de    	movl   $0xdeadbeef,(%eax)

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40001772:	b8 03 00 00 00       	mov    $0x3,%eax
40001777:	cd 30                	int    $0x30
40001779:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40001780:	00 
40001781:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001788:	00 
40001789:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40001790:	e8 9f ea ff ff       	call   40000234 <join>
40001795:	c7 85 10 fe ff ff 00 	movl   $0x700,0xfffffe10(%ebp)
4000179c:	07 00 00 
4000179f:	66 c7 85 0e fe ff ff 	movw   $0x0,0xfffffe0e(%ebp)
400017a6:	00 00 
400017a8:	c7 85 08 fe ff ff 00 	movl   $0x0,0xfffffe08(%ebp)
400017af:	00 00 00 
400017b2:	c7 85 04 fe ff ff 00 	movl   $0x0,0xfffffe04(%ebp)
400017b9:	00 00 00 
400017bc:	8b 85 bc fd ff ff    	mov    0xfffffdbc(%ebp),%eax
400017c2:	89 85 00 fe ff ff    	mov    %eax,0xfffffe00(%ebp)
400017c8:	c7 85 fc fd ff ff 00 	movl   $0x1000,0xfffffdfc(%ebp)
400017cf:	10 00 00 
static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
400017d2:	8b 85 10 fe ff ff    	mov    0xfffffe10(%ebp),%eax
400017d8:	83 c8 02             	or     $0x2,%eax
400017db:	8b 9d 08 fe ff ff    	mov    0xfffffe08(%ebp),%ebx
400017e1:	0f b7 95 0e fe ff ff 	movzwl 0xfffffe0e(%ebp),%edx
400017e8:	8b b5 04 fe ff ff    	mov    0xfffffe04(%ebp),%esi
400017ee:	8b bd 00 fe ff ff    	mov    0xfffffe00(%ebp),%edi
400017f4:	8b 8d fc fd ff ff    	mov    0xfffffdfc(%ebp),%ecx
400017fa:	cd 30                	int    $0x30
	sys_get(SYS_PERM | SYS_READ | SYS_WRITE, 0, NULL, NULL, va, PAGESIZE);
	*(volatile int*)va = 0xdeadbeef;	// should be writable now
400017fc:	8b 85 bc fd ff ff    	mov    0xfffffdbc(%ebp),%eax
40001802:	c7 00 ef be ad de    	movl   $0xdeadbeef,(%eax)
40001808:	c7 85 28 fe ff ff 00 	movl   $0x100,0xfffffe28(%ebp)
4000180f:	01 00 00 
40001812:	66 c7 85 26 fe ff ff 	movw   $0x0,0xfffffe26(%ebp)
40001819:	00 00 
4000181b:	c7 85 20 fe ff ff 00 	movl   $0x0,0xfffffe20(%ebp)
40001822:	00 00 00 
40001825:	c7 85 1c fe ff ff 00 	movl   $0x0,0xfffffe1c(%ebp)
4000182c:	00 00 00 
4000182f:	8b 85 bc fd ff ff    	mov    0xfffffdbc(%ebp),%eax
40001835:	89 85 18 fe ff ff    	mov    %eax,0xfffffe18(%ebp)
4000183b:	c7 85 14 fe ff ff 00 	movl   $0x1000,0xfffffe14(%ebp)
40001842:	10 00 00 
static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40001845:	8b 85 28 fe ff ff    	mov    0xfffffe28(%ebp),%eax
4000184b:	83 c8 02             	or     $0x2,%eax
4000184e:	8b 9d 20 fe ff ff    	mov    0xfffffe20(%ebp),%ebx
40001854:	0f b7 95 26 fe ff ff 	movzwl 0xfffffe26(%ebp),%edx
4000185b:	8b b5 1c fe ff ff    	mov    0xfffffe1c(%ebp),%esi
40001861:	8b bd 18 fe ff ff    	mov    0xfffffe18(%ebp),%edi
40001867:	8b 8d 14 fe ff ff    	mov    0xfffffe14(%ebp),%ecx
4000186d:	cd 30                	int    $0x30
	sys_get(SYS_PERM, 0, NULL, NULL, va, PAGESIZE);	// revoke all perms
	readfaulttest(va);
4000186f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001876:	00 
40001877:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
4000187e:	e8 d1 e8 ff ff       	call   40000154 <fork>
40001883:	85 c0                	test   %eax,%eax
40001885:	75 0f                	jne    40001896 <memopcheck+0x244>
40001887:	8b 85 bc fd ff ff    	mov    0xfffffdbc(%ebp),%eax
4000188d:	8b 00                	mov    (%eax),%eax

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
4000188f:	b8 03 00 00 00       	mov    $0x3,%eax
40001894:	cd 30                	int    $0x30
40001896:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
4000189d:	00 
4000189e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400018a5:	00 
400018a6:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
400018ad:	e8 82 e9 ff ff       	call   40000234 <join>
400018b2:	c7 85 40 fe ff ff 00 	movl   $0x300,0xfffffe40(%ebp)
400018b9:	03 00 00 
400018bc:	66 c7 85 3e fe ff ff 	movw   $0x0,0xfffffe3e(%ebp)
400018c3:	00 00 
400018c5:	c7 85 38 fe ff ff 00 	movl   $0x0,0xfffffe38(%ebp)
400018cc:	00 00 00 
400018cf:	c7 85 34 fe ff ff 00 	movl   $0x0,0xfffffe34(%ebp)
400018d6:	00 00 00 
400018d9:	8b 85 bc fd ff ff    	mov    0xfffffdbc(%ebp),%eax
400018df:	89 85 30 fe ff ff    	mov    %eax,0xfffffe30(%ebp)
400018e5:	c7 85 2c fe ff ff 00 	movl   $0x1000,0xfffffe2c(%ebp)
400018ec:	10 00 00 
static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
400018ef:	8b 85 40 fe ff ff    	mov    0xfffffe40(%ebp),%eax
400018f5:	83 c8 02             	or     $0x2,%eax
400018f8:	8b 9d 38 fe ff ff    	mov    0xfffffe38(%ebp),%ebx
400018fe:	0f b7 95 3e fe ff ff 	movzwl 0xfffffe3e(%ebp),%edx
40001905:	8b b5 34 fe ff ff    	mov    0xfffffe34(%ebp),%esi
4000190b:	8b bd 30 fe ff ff    	mov    0xfffffe30(%ebp),%edi
40001911:	8b 8d 2c fe ff ff    	mov    0xfffffe2c(%ebp),%ecx
40001917:	cd 30                	int    $0x30
	sys_get(SYS_PERM | SYS_READ, 0, NULL, NULL, va, PAGESIZE);
	assert(*(volatile int*)va == 0xdeadbeef);	// readable again
40001919:	8b 85 bc fd ff ff    	mov    0xfffffdbc(%ebp),%eax
4000191f:	8b 00                	mov    (%eax),%eax
40001921:	3d ef be ad de       	cmp    $0xdeadbeef,%eax
40001926:	74 24                	je     4000194c <memopcheck+0x2fa>
40001928:	c7 44 24 0c fc 57 00 	movl   $0x400057fc,0xc(%esp)
4000192f:	40 
40001930:	c7 44 24 08 7b 57 00 	movl   $0x4000577b,0x8(%esp)
40001937:	40 
40001938:	c7 44 24 04 10 01 00 	movl   $0x110,0x4(%esp)
4000193f:	00 
40001940:	c7 04 24 88 56 00 40 	movl   $0x40005688,(%esp)
40001947:	e8 9c 12 00 00       	call   40002be8 <debug_panic>
	writefaulttest(va);				// but not writable
4000194c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001953:	00 
40001954:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
4000195b:	e8 f4 e7 ff ff       	call   40000154 <fork>
40001960:	85 c0                	test   %eax,%eax
40001962:	75 1f                	jne    40001983 <memopcheck+0x331>
40001964:	8b 85 bc fd ff ff    	mov    0xfffffdbc(%ebp),%eax
4000196a:	89 85 d4 fd ff ff    	mov    %eax,0xfffffdd4(%ebp)
40001970:	8b 85 d4 fd ff ff    	mov    0xfffffdd4(%ebp),%eax
40001976:	c7 00 ef be ad de    	movl   $0xdeadbeef,(%eax)

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
4000197c:	b8 03 00 00 00       	mov    $0x3,%eax
40001981:	cd 30                	int    $0x30
40001983:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
4000198a:	00 
4000198b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001992:	00 
40001993:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
4000199a:	e8 95 e8 ff ff       	call   40000234 <join>
4000199f:	c7 85 58 fe ff ff 00 	movl   $0x700,0xfffffe58(%ebp)
400019a6:	07 00 00 
400019a9:	66 c7 85 56 fe ff ff 	movw   $0x0,0xfffffe56(%ebp)
400019b0:	00 00 
400019b2:	c7 85 50 fe ff ff 00 	movl   $0x0,0xfffffe50(%ebp)
400019b9:	00 00 00 
400019bc:	c7 85 4c fe ff ff 00 	movl   $0x0,0xfffffe4c(%ebp)
400019c3:	00 00 00 
400019c6:	8b 85 bc fd ff ff    	mov    0xfffffdbc(%ebp),%eax
400019cc:	89 85 48 fe ff ff    	mov    %eax,0xfffffe48(%ebp)
400019d2:	c7 85 44 fe ff ff 00 	movl   $0x1000,0xfffffe44(%ebp)
400019d9:	10 00 00 
static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
400019dc:	8b 85 58 fe ff ff    	mov    0xfffffe58(%ebp),%eax
400019e2:	83 c8 02             	or     $0x2,%eax
400019e5:	8b 9d 50 fe ff ff    	mov    0xfffffe50(%ebp),%ebx
400019eb:	0f b7 95 56 fe ff ff 	movzwl 0xfffffe56(%ebp),%edx
400019f2:	8b b5 4c fe ff ff    	mov    0xfffffe4c(%ebp),%esi
400019f8:	8b bd 48 fe ff ff    	mov    0xfffffe48(%ebp),%edi
400019fe:	8b 8d 44 fe ff ff    	mov    0xfffffe44(%ebp),%ecx
40001a04:	cd 30                	int    $0x30
	sys_get(SYS_PERM | SYS_READ | SYS_WRITE, 0, NULL, NULL, va, PAGESIZE);

	// Test SYS_ZERO with SYS_GET
	va = (void*)VM_USERLO+PTSIZE;	// 4MB-aligned
40001a06:	c7 85 bc fd ff ff 00 	movl   $0x40400000,0xfffffdbc(%ebp)
40001a0d:	00 40 40 
40001a10:	c7 85 70 fe ff ff 00 	movl   $0x10000,0xfffffe70(%ebp)
40001a17:	00 01 00 
40001a1a:	66 c7 85 6e fe ff ff 	movw   $0x0,0xfffffe6e(%ebp)
40001a21:	00 00 
40001a23:	c7 85 68 fe ff ff 00 	movl   $0x0,0xfffffe68(%ebp)
40001a2a:	00 00 00 
40001a2d:	c7 85 64 fe ff ff 00 	movl   $0x0,0xfffffe64(%ebp)
40001a34:	00 00 00 
40001a37:	8b 85 bc fd ff ff    	mov    0xfffffdbc(%ebp),%eax
40001a3d:	89 85 60 fe ff ff    	mov    %eax,0xfffffe60(%ebp)
40001a43:	c7 85 5c fe ff ff 00 	movl   $0x400000,0xfffffe5c(%ebp)
40001a4a:	00 40 00 
static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40001a4d:	8b 85 70 fe ff ff    	mov    0xfffffe70(%ebp),%eax
40001a53:	83 c8 02             	or     $0x2,%eax
40001a56:	8b 9d 68 fe ff ff    	mov    0xfffffe68(%ebp),%ebx
40001a5c:	0f b7 95 6e fe ff ff 	movzwl 0xfffffe6e(%ebp),%edx
40001a63:	8b b5 64 fe ff ff    	mov    0xfffffe64(%ebp),%esi
40001a69:	8b bd 60 fe ff ff    	mov    0xfffffe60(%ebp),%edi
40001a6f:	8b 8d 5c fe ff ff    	mov    0xfffffe5c(%ebp),%ecx
40001a75:	cd 30                	int    $0x30
	sys_get(SYS_ZERO, 0, NULL, NULL, va, PTSIZE);
	readfaulttest(va);		// should be inaccessible again
40001a77:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001a7e:	00 
40001a7f:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40001a86:	e8 c9 e6 ff ff       	call   40000154 <fork>
40001a8b:	85 c0                	test   %eax,%eax
40001a8d:	75 0f                	jne    40001a9e <memopcheck+0x44c>
40001a8f:	8b 85 bc fd ff ff    	mov    0xfffffdbc(%ebp),%eax
40001a95:	8b 00                	mov    (%eax),%eax

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40001a97:	b8 03 00 00 00       	mov    $0x3,%eax
40001a9c:	cd 30                	int    $0x30
40001a9e:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40001aa5:	00 
40001aa6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001aad:	00 
40001aae:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40001ab5:	e8 7a e7 ff ff       	call   40000234 <join>
40001aba:	c7 85 88 fe ff ff 00 	movl   $0x300,0xfffffe88(%ebp)
40001ac1:	03 00 00 
40001ac4:	66 c7 85 86 fe ff ff 	movw   $0x0,0xfffffe86(%ebp)
40001acb:	00 00 
40001acd:	c7 85 80 fe ff ff 00 	movl   $0x0,0xfffffe80(%ebp)
40001ad4:	00 00 00 
40001ad7:	c7 85 7c fe ff ff 00 	movl   $0x0,0xfffffe7c(%ebp)
40001ade:	00 00 00 
40001ae1:	8b 85 bc fd ff ff    	mov    0xfffffdbc(%ebp),%eax
40001ae7:	89 85 78 fe ff ff    	mov    %eax,0xfffffe78(%ebp)
40001aed:	c7 85 74 fe ff ff 00 	movl   $0x1000,0xfffffe74(%ebp)
40001af4:	10 00 00 
static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40001af7:	8b 85 88 fe ff ff    	mov    0xfffffe88(%ebp),%eax
40001afd:	83 c8 02             	or     $0x2,%eax
40001b00:	8b 9d 80 fe ff ff    	mov    0xfffffe80(%ebp),%ebx
40001b06:	0f b7 95 86 fe ff ff 	movzwl 0xfffffe86(%ebp),%edx
40001b0d:	8b b5 7c fe ff ff    	mov    0xfffffe7c(%ebp),%esi
40001b13:	8b bd 78 fe ff ff    	mov    0xfffffe78(%ebp),%edi
40001b19:	8b 8d 74 fe ff ff    	mov    0xfffffe74(%ebp),%ecx
40001b1f:	cd 30                	int    $0x30
	sys_get(SYS_PERM | SYS_READ, 0, NULL, NULL, va, PAGESIZE);
	assert(*(volatile int*)va == 0);	// and zeroed
40001b21:	8b 85 bc fd ff ff    	mov    0xfffffdbc(%ebp),%eax
40001b27:	8b 00                	mov    (%eax),%eax
40001b29:	85 c0                	test   %eax,%eax
40001b2b:	74 24                	je     40001b51 <memopcheck+0x4ff>
40001b2d:	c7 44 24 0c e3 57 00 	movl   $0x400057e3,0xc(%esp)
40001b34:	40 
40001b35:	c7 44 24 08 7b 57 00 	movl   $0x4000577b,0x8(%esp)
40001b3c:	40 
40001b3d:	c7 44 24 04 19 01 00 	movl   $0x119,0x4(%esp)
40001b44:	00 
40001b45:	c7 04 24 88 56 00 40 	movl   $0x40005688,(%esp)
40001b4c:	e8 97 10 00 00       	call   40002be8 <debug_panic>
	writefaulttest(va);			// but not writable
40001b51:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001b58:	00 
40001b59:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40001b60:	e8 ef e5 ff ff       	call   40000154 <fork>
40001b65:	85 c0                	test   %eax,%eax
40001b67:	75 1f                	jne    40001b88 <memopcheck+0x536>
40001b69:	8b 85 bc fd ff ff    	mov    0xfffffdbc(%ebp),%eax
40001b6f:	89 85 d8 fd ff ff    	mov    %eax,0xfffffdd8(%ebp)
40001b75:	8b 85 d8 fd ff ff    	mov    0xfffffdd8(%ebp),%eax
40001b7b:	c7 00 ef be ad de    	movl   $0xdeadbeef,(%eax)

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40001b81:	b8 03 00 00 00       	mov    $0x3,%eax
40001b86:	cd 30                	int    $0x30
40001b88:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40001b8f:	00 
40001b90:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001b97:	00 
40001b98:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40001b9f:	e8 90 e6 ff ff       	call   40000234 <join>
40001ba4:	c7 85 a0 fe ff ff 00 	movl   $0x10000,0xfffffea0(%ebp)
40001bab:	00 01 00 
40001bae:	66 c7 85 9e fe ff ff 	movw   $0x0,0xfffffe9e(%ebp)
40001bb5:	00 00 
40001bb7:	c7 85 98 fe ff ff 00 	movl   $0x0,0xfffffe98(%ebp)
40001bbe:	00 00 00 
40001bc1:	c7 85 94 fe ff ff 00 	movl   $0x0,0xfffffe94(%ebp)
40001bc8:	00 00 00 
40001bcb:	8b 85 bc fd ff ff    	mov    0xfffffdbc(%ebp),%eax
40001bd1:	89 85 90 fe ff ff    	mov    %eax,0xfffffe90(%ebp)
40001bd7:	c7 85 8c fe ff ff 00 	movl   $0x400000,0xfffffe8c(%ebp)
40001bde:	00 40 00 
static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40001be1:	8b 85 a0 fe ff ff    	mov    0xfffffea0(%ebp),%eax
40001be7:	83 c8 02             	or     $0x2,%eax
40001bea:	8b 9d 98 fe ff ff    	mov    0xfffffe98(%ebp),%ebx
40001bf0:	0f b7 95 9e fe ff ff 	movzwl 0xfffffe9e(%ebp),%edx
40001bf7:	8b b5 94 fe ff ff    	mov    0xfffffe94(%ebp),%esi
40001bfd:	8b bd 90 fe ff ff    	mov    0xfffffe90(%ebp),%edi
40001c03:	8b 8d 8c fe ff ff    	mov    0xfffffe8c(%ebp),%ecx
40001c09:	cd 30                	int    $0x30
	sys_get(SYS_ZERO, 0, NULL, NULL, va, PTSIZE);
	readfaulttest(va);			// gone again
40001c0b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001c12:	00 
40001c13:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40001c1a:	e8 35 e5 ff ff       	call   40000154 <fork>
40001c1f:	85 c0                	test   %eax,%eax
40001c21:	75 0f                	jne    40001c32 <memopcheck+0x5e0>
40001c23:	8b 85 bc fd ff ff    	mov    0xfffffdbc(%ebp),%eax
40001c29:	8b 00                	mov    (%eax),%eax

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40001c2b:	b8 03 00 00 00       	mov    $0x3,%eax
40001c30:	cd 30                	int    $0x30
40001c32:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40001c39:	00 
40001c3a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001c41:	00 
40001c42:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40001c49:	e8 e6 e5 ff ff       	call   40000234 <join>
40001c4e:	c7 85 b8 fe ff ff 00 	movl   $0x700,0xfffffeb8(%ebp)
40001c55:	07 00 00 
40001c58:	66 c7 85 b6 fe ff ff 	movw   $0x0,0xfffffeb6(%ebp)
40001c5f:	00 00 
40001c61:	c7 85 b0 fe ff ff 00 	movl   $0x0,0xfffffeb0(%ebp)
40001c68:	00 00 00 
40001c6b:	c7 85 ac fe ff ff 00 	movl   $0x0,0xfffffeac(%ebp)
40001c72:	00 00 00 
40001c75:	8b 85 bc fd ff ff    	mov    0xfffffdbc(%ebp),%eax
40001c7b:	89 85 a8 fe ff ff    	mov    %eax,0xfffffea8(%ebp)
40001c81:	c7 85 a4 fe ff ff 00 	movl   $0x1000,0xfffffea4(%ebp)
40001c88:	10 00 00 
static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40001c8b:	8b 85 b8 fe ff ff    	mov    0xfffffeb8(%ebp),%eax
40001c91:	83 c8 02             	or     $0x2,%eax
40001c94:	8b 9d b0 fe ff ff    	mov    0xfffffeb0(%ebp),%ebx
40001c9a:	0f b7 95 b6 fe ff ff 	movzwl 0xfffffeb6(%ebp),%edx
40001ca1:	8b b5 ac fe ff ff    	mov    0xfffffeac(%ebp),%esi
40001ca7:	8b bd a8 fe ff ff    	mov    0xfffffea8(%ebp),%edi
40001cad:	8b 8d a4 fe ff ff    	mov    0xfffffea4(%ebp),%ecx
40001cb3:	cd 30                	int    $0x30
	sys_get(SYS_PERM | SYS_READ | SYS_WRITE, 0, NULL, NULL, va, PAGESIZE);
	*(volatile int*)va = 0xdeadbeef;	// writable now
40001cb5:	8b 85 bc fd ff ff    	mov    0xfffffdbc(%ebp),%eax
40001cbb:	c7 00 ef be ad de    	movl   $0xdeadbeef,(%eax)
40001cc1:	c7 85 d0 fe ff ff 00 	movl   $0x10000,0xfffffed0(%ebp)
40001cc8:	00 01 00 
40001ccb:	66 c7 85 ce fe ff ff 	movw   $0x0,0xfffffece(%ebp)
40001cd2:	00 00 
40001cd4:	c7 85 c8 fe ff ff 00 	movl   $0x0,0xfffffec8(%ebp)
40001cdb:	00 00 00 
40001cde:	c7 85 c4 fe ff ff 00 	movl   $0x0,0xfffffec4(%ebp)
40001ce5:	00 00 00 
40001ce8:	8b 85 bc fd ff ff    	mov    0xfffffdbc(%ebp),%eax
40001cee:	89 85 c0 fe ff ff    	mov    %eax,0xfffffec0(%ebp)
40001cf4:	c7 85 bc fe ff ff 00 	movl   $0x400000,0xfffffebc(%ebp)
40001cfb:	00 40 00 
static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40001cfe:	8b 85 d0 fe ff ff    	mov    0xfffffed0(%ebp),%eax
40001d04:	83 c8 02             	or     $0x2,%eax
40001d07:	8b 9d c8 fe ff ff    	mov    0xfffffec8(%ebp),%ebx
40001d0d:	0f b7 95 ce fe ff ff 	movzwl 0xfffffece(%ebp),%edx
40001d14:	8b b5 c4 fe ff ff    	mov    0xfffffec4(%ebp),%esi
40001d1a:	8b bd c0 fe ff ff    	mov    0xfffffec0(%ebp),%edi
40001d20:	8b 8d bc fe ff ff    	mov    0xfffffebc(%ebp),%ecx
40001d26:	cd 30                	int    $0x30
	sys_get(SYS_ZERO, 0, NULL, NULL, va, PTSIZE);
	readfaulttest(va);			// gone again
40001d28:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001d2f:	00 
40001d30:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40001d37:	e8 18 e4 ff ff       	call   40000154 <fork>
40001d3c:	85 c0                	test   %eax,%eax
40001d3e:	75 0f                	jne    40001d4f <memopcheck+0x6fd>
40001d40:	8b 85 bc fd ff ff    	mov    0xfffffdbc(%ebp),%eax
40001d46:	8b 00                	mov    (%eax),%eax

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40001d48:	b8 03 00 00 00       	mov    $0x3,%eax
40001d4d:	cd 30                	int    $0x30
40001d4f:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40001d56:	00 
40001d57:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001d5e:	00 
40001d5f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40001d66:	e8 c9 e4 ff ff       	call   40000234 <join>
40001d6b:	c7 85 e8 fe ff ff 00 	movl   $0x300,0xfffffee8(%ebp)
40001d72:	03 00 00 
40001d75:	66 c7 85 e6 fe ff ff 	movw   $0x0,0xfffffee6(%ebp)
40001d7c:	00 00 
40001d7e:	c7 85 e0 fe ff ff 00 	movl   $0x0,0xfffffee0(%ebp)
40001d85:	00 00 00 
40001d88:	c7 85 dc fe ff ff 00 	movl   $0x0,0xfffffedc(%ebp)
40001d8f:	00 00 00 
40001d92:	8b 85 bc fd ff ff    	mov    0xfffffdbc(%ebp),%eax
40001d98:	89 85 d8 fe ff ff    	mov    %eax,0xfffffed8(%ebp)
40001d9e:	c7 85 d4 fe ff ff 00 	movl   $0x1000,0xfffffed4(%ebp)
40001da5:	10 00 00 
static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40001da8:	8b 85 e8 fe ff ff    	mov    0xfffffee8(%ebp),%eax
40001dae:	83 c8 02             	or     $0x2,%eax
40001db1:	8b 9d e0 fe ff ff    	mov    0xfffffee0(%ebp),%ebx
40001db7:	0f b7 95 e6 fe ff ff 	movzwl 0xfffffee6(%ebp),%edx
40001dbe:	8b b5 dc fe ff ff    	mov    0xfffffedc(%ebp),%esi
40001dc4:	8b bd d8 fe ff ff    	mov    0xfffffed8(%ebp),%edi
40001dca:	8b 8d d4 fe ff ff    	mov    0xfffffed4(%ebp),%ecx
40001dd0:	cd 30                	int    $0x30
	sys_get(SYS_PERM | SYS_READ, 0, NULL, NULL, va, PAGESIZE);
	assert(*(volatile int*)va == 0);	// and zeroed
40001dd2:	8b 85 bc fd ff ff    	mov    0xfffffdbc(%ebp),%eax
40001dd8:	8b 00                	mov    (%eax),%eax
40001dda:	85 c0                	test   %eax,%eax
40001ddc:	74 24                	je     40001e02 <memopcheck+0x7b0>
40001dde:	c7 44 24 0c e3 57 00 	movl   $0x400057e3,0xc(%esp)
40001de5:	40 
40001de6:	c7 44 24 08 7b 57 00 	movl   $0x4000577b,0x8(%esp)
40001ded:	40 
40001dee:	c7 44 24 04 22 01 00 	movl   $0x122,0x4(%esp)
40001df5:	00 
40001df6:	c7 04 24 88 56 00 40 	movl   $0x40005688,(%esp)
40001dfd:	e8 e6 0d 00 00       	call   40002be8 <debug_panic>

	// Test SYS_COPY with SYS_GET - pull residual stuff out of child 0
	void *sva = (void*)VM_USERLO;
40001e02:	c7 85 c0 fd ff ff 00 	movl   $0x40000000,0xfffffdc0(%ebp)
40001e09:	00 00 40 
	void *dva = (void*)VM_USERLO+PTSIZE;
40001e0c:	c7 85 c4 fd ff ff 00 	movl   $0x40400000,0xfffffdc4(%ebp)
40001e13:	00 40 40 
40001e16:	c7 85 00 ff ff ff 00 	movl   $0x20000,0xffffff00(%ebp)
40001e1d:	00 02 00 
40001e20:	66 c7 85 fe fe ff ff 	movw   $0x0,0xfffffefe(%ebp)
40001e27:	00 00 
40001e29:	c7 85 f8 fe ff ff 00 	movl   $0x0,0xfffffef8(%ebp)
40001e30:	00 00 00 
40001e33:	8b 85 c0 fd ff ff    	mov    0xfffffdc0(%ebp),%eax
40001e39:	89 85 f4 fe ff ff    	mov    %eax,0xfffffef4(%ebp)
40001e3f:	8b 85 c4 fd ff ff    	mov    0xfffffdc4(%ebp),%eax
40001e45:	89 85 f0 fe ff ff    	mov    %eax,0xfffffef0(%ebp)
40001e4b:	c7 85 ec fe ff ff 00 	movl   $0x400000,0xfffffeec(%ebp)
40001e52:	00 40 00 
static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40001e55:	8b 85 00 ff ff ff    	mov    0xffffff00(%ebp),%eax
40001e5b:	83 c8 02             	or     $0x2,%eax
40001e5e:	8b 9d f8 fe ff ff    	mov    0xfffffef8(%ebp),%ebx
40001e64:	0f b7 95 fe fe ff ff 	movzwl 0xfffffefe(%ebp),%edx
40001e6b:	8b b5 f4 fe ff ff    	mov    0xfffffef4(%ebp),%esi
40001e71:	8b bd f0 fe ff ff    	mov    0xfffffef0(%ebp),%edi
40001e77:	8b 8d ec fe ff ff    	mov    0xfffffeec(%ebp),%ecx
40001e7d:	cd 30                	int    $0x30
	sys_get(SYS_COPY, 0, NULL, sva, dva, PTSIZE);
	assert(memcmp(sva, dva, etext - start) == 0);
40001e7f:	ba 37 56 00 40       	mov    $0x40005637,%edx
40001e84:	b8 00 01 00 40       	mov    $0x40000100,%eax
40001e89:	89 d1                	mov    %edx,%ecx
40001e8b:	29 c1                	sub    %eax,%ecx
40001e8d:	89 c8                	mov    %ecx,%eax
40001e8f:	89 44 24 08          	mov    %eax,0x8(%esp)
40001e93:	8b 85 c4 fd ff ff    	mov    0xfffffdc4(%ebp),%eax
40001e99:	89 44 24 04          	mov    %eax,0x4(%esp)
40001e9d:	8b 85 c0 fd ff ff    	mov    0xfffffdc0(%ebp),%eax
40001ea3:	89 04 24             	mov    %eax,(%esp)
40001ea6:	e8 5e 1a 00 00       	call   40003909 <memcmp>
40001eab:	85 c0                	test   %eax,%eax
40001ead:	74 24                	je     40001ed3 <memopcheck+0x881>
40001eaf:	c7 44 24 0c 20 58 00 	movl   $0x40005820,0xc(%esp)
40001eb6:	40 
40001eb7:	c7 44 24 08 7b 57 00 	movl   $0x4000577b,0x8(%esp)
40001ebe:	40 
40001ebf:	c7 44 24 04 28 01 00 	movl   $0x128,0x4(%esp)
40001ec6:	00 
40001ec7:	c7 04 24 88 56 00 40 	movl   $0x40005688,(%esp)
40001ece:	e8 15 0d 00 00       	call   40002be8 <debug_panic>
	writefaulttest(dva);
40001ed3:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001eda:	00 
40001edb:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40001ee2:	e8 6d e2 ff ff       	call   40000154 <fork>
40001ee7:	85 c0                	test   %eax,%eax
40001ee9:	75 1f                	jne    40001f0a <memopcheck+0x8b8>
40001eeb:	8b 85 c4 fd ff ff    	mov    0xfffffdc4(%ebp),%eax
40001ef1:	89 85 dc fd ff ff    	mov    %eax,0xfffffddc(%ebp)
40001ef7:	8b 85 dc fd ff ff    	mov    0xfffffddc(%ebp),%eax
40001efd:	c7 00 ef be ad de    	movl   $0xdeadbeef,(%eax)

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40001f03:	b8 03 00 00 00       	mov    $0x3,%eax
40001f08:	cd 30                	int    $0x30
40001f0a:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40001f11:	00 
40001f12:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001f19:	00 
40001f1a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40001f21:	e8 0e e3 ff ff       	call   40000234 <join>
	readfaulttest(dva + PTSIZE-4);
40001f26:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001f2d:	00 
40001f2e:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40001f35:	e8 1a e2 ff ff       	call   40000154 <fork>
40001f3a:	85 c0                	test   %eax,%eax
40001f3c:	75 14                	jne    40001f52 <memopcheck+0x900>
40001f3e:	8b 85 c4 fd ff ff    	mov    0xfffffdc4(%ebp),%eax
40001f44:	05 fc ff 3f 00       	add    $0x3ffffc,%eax
40001f49:	8b 00                	mov    (%eax),%eax

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40001f4b:	b8 03 00 00 00       	mov    $0x3,%eax
40001f50:	cd 30                	int    $0x30
40001f52:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40001f59:	00 
40001f5a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001f61:	00 
40001f62:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40001f69:	e8 c6 e2 ff ff       	call   40000234 <join>

	// Test SYS_ZERO with SYS_PUT
	void *dva2 = (void*)VM_USERLO+PTSIZE*2;
40001f6e:	c7 85 c8 fd ff ff 00 	movl   $0x40800000,0xfffffdc8(%ebp)
40001f75:	00 80 40 
40001f78:	c7 85 18 ff ff ff 00 	movl   $0x10000,0xffffff18(%ebp)
40001f7f:	00 01 00 
40001f82:	66 c7 85 16 ff ff ff 	movw   $0x0,0xffffff16(%ebp)
40001f89:	00 00 
40001f8b:	c7 85 10 ff ff ff 00 	movl   $0x0,0xffffff10(%ebp)
40001f92:	00 00 00 
40001f95:	c7 85 0c ff ff ff 00 	movl   $0x0,0xffffff0c(%ebp)
40001f9c:	00 00 00 
40001f9f:	8b 85 c4 fd ff ff    	mov    0xfffffdc4(%ebp),%eax
40001fa5:	89 85 08 ff ff ff    	mov    %eax,0xffffff08(%ebp)
40001fab:	c7 85 04 ff ff ff 00 	movl   $0x400000,0xffffff04(%ebp)
40001fb2:	00 40 00 
static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
40001fb5:	8b 85 18 ff ff ff    	mov    0xffffff18(%ebp),%eax
40001fbb:	83 c8 01             	or     $0x1,%eax
40001fbe:	8b 9d 10 ff ff ff    	mov    0xffffff10(%ebp),%ebx
40001fc4:	0f b7 95 16 ff ff ff 	movzwl 0xffffff16(%ebp),%edx
40001fcb:	8b b5 0c ff ff ff    	mov    0xffffff0c(%ebp),%esi
40001fd1:	8b bd 08 ff ff ff    	mov    0xffffff08(%ebp),%edi
40001fd7:	8b 8d 04 ff ff ff    	mov    0xffffff04(%ebp),%ecx
40001fdd:	cd 30                	int    $0x30
40001fdf:	c7 85 30 ff ff ff 00 	movl   $0x20000,0xffffff30(%ebp)
40001fe6:	00 02 00 
40001fe9:	66 c7 85 2e ff ff ff 	movw   $0x0,0xffffff2e(%ebp)
40001ff0:	00 00 
40001ff2:	c7 85 28 ff ff ff 00 	movl   $0x0,0xffffff28(%ebp)
40001ff9:	00 00 00 
40001ffc:	8b 85 c4 fd ff ff    	mov    0xfffffdc4(%ebp),%eax
40002002:	89 85 24 ff ff ff    	mov    %eax,0xffffff24(%ebp)
40002008:	8b 85 c8 fd ff ff    	mov    0xfffffdc8(%ebp),%eax
4000200e:	89 85 20 ff ff ff    	mov    %eax,0xffffff20(%ebp)
40002014:	c7 85 1c ff ff ff 00 	movl   $0x400000,0xffffff1c(%ebp)
4000201b:	00 40 00 
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
4000201e:	8b 85 30 ff ff ff    	mov    0xffffff30(%ebp),%eax
40002024:	83 c8 02             	or     $0x2,%eax
40002027:	8b 9d 28 ff ff ff    	mov    0xffffff28(%ebp),%ebx
4000202d:	0f b7 95 2e ff ff ff 	movzwl 0xffffff2e(%ebp),%edx
40002034:	8b b5 24 ff ff ff    	mov    0xffffff24(%ebp),%esi
4000203a:	8b bd 20 ff ff ff    	mov    0xffffff20(%ebp),%edi
40002040:	8b 8d 1c ff ff ff    	mov    0xffffff1c(%ebp),%ecx
40002046:	cd 30                	int    $0x30
	sys_put(SYS_ZERO, 0, NULL, NULL, dva, PTSIZE);
	sys_get(SYS_COPY, 0, NULL, dva, dva2, PTSIZE);
	readfaulttest(dva2);
40002048:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000204f:	00 
40002050:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40002057:	e8 f8 e0 ff ff       	call   40000154 <fork>
4000205c:	85 c0                	test   %eax,%eax
4000205e:	75 0f                	jne    4000206f <memopcheck+0xa1d>
40002060:	8b 85 c8 fd ff ff    	mov    0xfffffdc8(%ebp),%eax
40002066:	8b 00                	mov    (%eax),%eax

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40002068:	b8 03 00 00 00       	mov    $0x3,%eax
4000206d:	cd 30                	int    $0x30
4000206f:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40002076:	00 
40002077:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000207e:	00 
4000207f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40002086:	e8 a9 e1 ff ff       	call   40000234 <join>
	readfaulttest(dva2 + PTSIZE-4);
4000208b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40002092:	00 
40002093:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
4000209a:	e8 b5 e0 ff ff       	call   40000154 <fork>
4000209f:	85 c0                	test   %eax,%eax
400020a1:	75 14                	jne    400020b7 <memopcheck+0xa65>
400020a3:	8b 85 c8 fd ff ff    	mov    0xfffffdc8(%ebp),%eax
400020a9:	05 fc ff 3f 00       	add    $0x3ffffc,%eax
400020ae:	8b 00                	mov    (%eax),%eax

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
400020b0:	b8 03 00 00 00       	mov    $0x3,%eax
400020b5:	cd 30                	int    $0x30
400020b7:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
400020be:	00 
400020bf:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400020c6:	00 
400020c7:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
400020ce:	e8 61 e1 ff ff       	call   40000234 <join>
400020d3:	c7 85 48 ff ff ff 00 	movl   $0x300,0xffffff48(%ebp)
400020da:	03 00 00 
400020dd:	66 c7 85 46 ff ff ff 	movw   $0x0,0xffffff46(%ebp)
400020e4:	00 00 
400020e6:	c7 85 40 ff ff ff 00 	movl   $0x0,0xffffff40(%ebp)
400020ed:	00 00 00 
400020f0:	c7 85 3c ff ff ff 00 	movl   $0x0,0xffffff3c(%ebp)
400020f7:	00 00 00 
400020fa:	8b 85 c8 fd ff ff    	mov    0xfffffdc8(%ebp),%eax
40002100:	89 85 38 ff ff ff    	mov    %eax,0xffffff38(%ebp)
40002106:	c7 85 34 ff ff ff 00 	movl   $0x400000,0xffffff34(%ebp)
4000210d:	00 40 00 
static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40002110:	8b 85 48 ff ff ff    	mov    0xffffff48(%ebp),%eax
40002116:	83 c8 02             	or     $0x2,%eax
40002119:	8b 9d 40 ff ff ff    	mov    0xffffff40(%ebp),%ebx
4000211f:	0f b7 95 46 ff ff ff 	movzwl 0xffffff46(%ebp),%edx
40002126:	8b b5 3c ff ff ff    	mov    0xffffff3c(%ebp),%esi
4000212c:	8b bd 38 ff ff ff    	mov    0xffffff38(%ebp),%edi
40002132:	8b 8d 34 ff ff ff    	mov    0xffffff34(%ebp),%ecx
40002138:	cd 30                	int    $0x30
	sys_get(SYS_PERM | SYS_READ, 0, NULL, NULL, dva2, PTSIZE);
	assert(*(volatile int*)dva2 == 0);
4000213a:	8b 85 c8 fd ff ff    	mov    0xfffffdc8(%ebp),%eax
40002140:	8b 00                	mov    (%eax),%eax
40002142:	85 c0                	test   %eax,%eax
40002144:	74 24                	je     4000216a <memopcheck+0xb18>
40002146:	c7 44 24 0c 45 58 00 	movl   $0x40005845,0xc(%esp)
4000214d:	40 
4000214e:	c7 44 24 08 7b 57 00 	movl   $0x4000577b,0x8(%esp)
40002155:	40 
40002156:	c7 44 24 04 33 01 00 	movl   $0x133,0x4(%esp)
4000215d:	00 
4000215e:	c7 04 24 88 56 00 40 	movl   $0x40005688,(%esp)
40002165:	e8 7e 0a 00 00       	call   40002be8 <debug_panic>
	assert(*(volatile int*)(dva2+PTSIZE-4) == 0);
4000216a:	8b 85 c8 fd ff ff    	mov    0xfffffdc8(%ebp),%eax
40002170:	05 fc ff 3f 00       	add    $0x3ffffc,%eax
40002175:	8b 00                	mov    (%eax),%eax
40002177:	85 c0                	test   %eax,%eax
40002179:	74 24                	je     4000219f <memopcheck+0xb4d>
4000217b:	c7 44 24 0c 60 58 00 	movl   $0x40005860,0xc(%esp)
40002182:	40 
40002183:	c7 44 24 08 7b 57 00 	movl   $0x4000577b,0x8(%esp)
4000218a:	40 
4000218b:	c7 44 24 04 34 01 00 	movl   $0x134,0x4(%esp)
40002192:	00 
40002193:	c7 04 24 88 56 00 40 	movl   $0x40005688,(%esp)
4000219a:	e8 49 0a 00 00       	call   40002be8 <debug_panic>
4000219f:	c7 85 60 ff ff ff 00 	movl   $0x20000,0xffffff60(%ebp)
400021a6:	00 02 00 
400021a9:	66 c7 85 5e ff ff ff 	movw   $0x0,0xffffff5e(%ebp)
400021b0:	00 00 
400021b2:	c7 85 58 ff ff ff 00 	movl   $0x0,0xffffff58(%ebp)
400021b9:	00 00 00 
400021bc:	8b 85 c0 fd ff ff    	mov    0xfffffdc0(%ebp),%eax
400021c2:	89 85 54 ff ff ff    	mov    %eax,0xffffff54(%ebp)
400021c8:	8b 85 c4 fd ff ff    	mov    0xfffffdc4(%ebp),%eax
400021ce:	89 85 50 ff ff ff    	mov    %eax,0xffffff50(%ebp)
400021d4:	c7 85 4c ff ff ff 00 	movl   $0x400000,0xffffff4c(%ebp)
400021db:	00 40 00 
static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
400021de:	8b 85 60 ff ff ff    	mov    0xffffff60(%ebp),%eax
400021e4:	83 c8 01             	or     $0x1,%eax
400021e7:	8b 9d 58 ff ff ff    	mov    0xffffff58(%ebp),%ebx
400021ed:	0f b7 95 5e ff ff ff 	movzwl 0xffffff5e(%ebp),%edx
400021f4:	8b b5 54 ff ff ff    	mov    0xffffff54(%ebp),%esi
400021fa:	8b bd 50 ff ff ff    	mov    0xffffff50(%ebp),%edi
40002200:	8b 8d 4c ff ff ff    	mov    0xffffff4c(%ebp),%ecx
40002206:	cd 30                	int    $0x30
40002208:	c7 85 78 ff ff ff 00 	movl   $0x20000,0xffffff78(%ebp)
4000220f:	00 02 00 
40002212:	66 c7 85 76 ff ff ff 	movw   $0x0,0xffffff76(%ebp)
40002219:	00 00 
4000221b:	c7 85 70 ff ff ff 00 	movl   $0x0,0xffffff70(%ebp)
40002222:	00 00 00 
40002225:	8b 85 c4 fd ff ff    	mov    0xfffffdc4(%ebp),%eax
4000222b:	89 85 6c ff ff ff    	mov    %eax,0xffffff6c(%ebp)
40002231:	8b 85 c8 fd ff ff    	mov    0xfffffdc8(%ebp),%eax
40002237:	89 85 68 ff ff ff    	mov    %eax,0xffffff68(%ebp)
4000223d:	c7 85 64 ff ff ff 00 	movl   $0x400000,0xffffff64(%ebp)
40002244:	00 40 00 
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
40002247:	8b 85 78 ff ff ff    	mov    0xffffff78(%ebp),%eax
4000224d:	83 c8 02             	or     $0x2,%eax
40002250:	8b 9d 70 ff ff ff    	mov    0xffffff70(%ebp),%ebx
40002256:	0f b7 95 76 ff ff ff 	movzwl 0xffffff76(%ebp),%edx
4000225d:	8b b5 6c ff ff ff    	mov    0xffffff6c(%ebp),%esi
40002263:	8b bd 68 ff ff ff    	mov    0xffffff68(%ebp),%edi
40002269:	8b 8d 64 ff ff ff    	mov    0xffffff64(%ebp),%ecx
4000226f:	cd 30                	int    $0x30

	// Test SYS_COPY with SYS_PUT
	sys_put(SYS_COPY, 0, NULL, sva, dva, PTSIZE);
	sys_get(SYS_COPY, 0, NULL, dva, dva2, PTSIZE);
	assert(memcmp(sva, dva2, etext - start) == 0);
40002271:	ba 37 56 00 40       	mov    $0x40005637,%edx
40002276:	b8 00 01 00 40       	mov    $0x40000100,%eax
4000227b:	89 d1                	mov    %edx,%ecx
4000227d:	29 c1                	sub    %eax,%ecx
4000227f:	89 c8                	mov    %ecx,%eax
40002281:	89 44 24 08          	mov    %eax,0x8(%esp)
40002285:	8b 85 c8 fd ff ff    	mov    0xfffffdc8(%ebp),%eax
4000228b:	89 44 24 04          	mov    %eax,0x4(%esp)
4000228f:	8b 85 c0 fd ff ff    	mov    0xfffffdc0(%ebp),%eax
40002295:	89 04 24             	mov    %eax,(%esp)
40002298:	e8 6c 16 00 00       	call   40003909 <memcmp>
4000229d:	85 c0                	test   %eax,%eax
4000229f:	74 24                	je     400022c5 <memopcheck+0xc73>
400022a1:	c7 44 24 0c 88 58 00 	movl   $0x40005888,0xc(%esp)
400022a8:	40 
400022a9:	c7 44 24 08 7b 57 00 	movl   $0x4000577b,0x8(%esp)
400022b0:	40 
400022b1:	c7 44 24 04 39 01 00 	movl   $0x139,0x4(%esp)
400022b8:	00 
400022b9:	c7 04 24 88 56 00 40 	movl   $0x40005688,(%esp)
400022c0:	e8 23 09 00 00       	call   40002be8 <debug_panic>
	writefaulttest(dva2);
400022c5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400022cc:	00 
400022cd:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
400022d4:	e8 7b de ff ff       	call   40000154 <fork>
400022d9:	85 c0                	test   %eax,%eax
400022db:	75 1f                	jne    400022fc <memopcheck+0xcaa>
400022dd:	8b 85 c8 fd ff ff    	mov    0xfffffdc8(%ebp),%eax
400022e3:	89 85 e0 fd ff ff    	mov    %eax,0xfffffde0(%ebp)
400022e9:	8b 85 e0 fd ff ff    	mov    0xfffffde0(%ebp),%eax
400022ef:	c7 00 ef be ad de    	movl   $0xdeadbeef,(%eax)

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
400022f5:	b8 03 00 00 00       	mov    $0x3,%eax
400022fa:	cd 30                	int    $0x30
400022fc:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40002303:	00 
40002304:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000230b:	00 
4000230c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40002313:	e8 1c df ff ff       	call   40000234 <join>
	readfaulttest(dva2 + PTSIZE-4);
40002318:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000231f:	00 
40002320:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40002327:	e8 28 de ff ff       	call   40000154 <fork>
4000232c:	85 c0                	test   %eax,%eax
4000232e:	75 14                	jne    40002344 <memopcheck+0xcf2>
40002330:	8b 85 c8 fd ff ff    	mov    0xfffffdc8(%ebp),%eax
40002336:	05 fc ff 3f 00       	add    $0x3ffffc,%eax
4000233b:	8b 00                	mov    (%eax),%eax

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
4000233d:	b8 03 00 00 00       	mov    $0x3,%eax
40002342:	cd 30                	int    $0x30
40002344:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
4000234b:	00 
4000234c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40002353:	00 
40002354:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
4000235b:	e8 d4 de ff ff       	call   40000234 <join>

	// Hide an easter egg and make sure it survives the two copies
	sva = (void*)VM_USERLO; dva = sva+PTSIZE; dva2 = dva+PTSIZE;
40002360:	c7 85 c0 fd ff ff 00 	movl   $0x40000000,0xfffffdc0(%ebp)
40002367:	00 00 40 
4000236a:	8b 85 c0 fd ff ff    	mov    0xfffffdc0(%ebp),%eax
40002370:	05 00 00 40 00       	add    $0x400000,%eax
40002375:	89 85 c4 fd ff ff    	mov    %eax,0xfffffdc4(%ebp)
4000237b:	8b 85 c4 fd ff ff    	mov    0xfffffdc4(%ebp),%eax
40002381:	05 00 00 40 00       	add    $0x400000,%eax
40002386:	89 85 c8 fd ff ff    	mov    %eax,0xfffffdc8(%ebp)
	uint32_t ofs = PTSIZE-PAGESIZE;
4000238c:	c7 85 cc fd ff ff 00 	movl   $0x3ff000,0xfffffdcc(%ebp)
40002393:	f0 3f 00 
	sys_get(SYS_PERM|SYS_READ|SYS_WRITE, 0, NULL, NULL, sva+ofs, PAGESIZE);
40002396:	8b 85 cc fd ff ff    	mov    0xfffffdcc(%ebp),%eax
4000239c:	03 85 c0 fd ff ff    	add    0xfffffdc0(%ebp),%eax
400023a2:	c7 45 90 00 07 00 00 	movl   $0x700,0xffffff90(%ebp)
400023a9:	66 c7 45 8e 00 00    	movw   $0x0,0xffffff8e(%ebp)
400023af:	c7 45 88 00 00 00 00 	movl   $0x0,0xffffff88(%ebp)
400023b6:	c7 45 84 00 00 00 00 	movl   $0x0,0xffffff84(%ebp)
400023bd:	89 45 80             	mov    %eax,0xffffff80(%ebp)
400023c0:	c7 85 7c ff ff ff 00 	movl   $0x1000,0xffffff7c(%ebp)
400023c7:	10 00 00 
static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
400023ca:	8b 45 90             	mov    0xffffff90(%ebp),%eax
400023cd:	83 c8 02             	or     $0x2,%eax
400023d0:	8b 5d 88             	mov    0xffffff88(%ebp),%ebx
400023d3:	0f b7 55 8e          	movzwl 0xffffff8e(%ebp),%edx
400023d7:	8b 75 84             	mov    0xffffff84(%ebp),%esi
400023da:	8b 7d 80             	mov    0xffffff80(%ebp),%edi
400023dd:	8b 8d 7c ff ff ff    	mov    0xffffff7c(%ebp),%ecx
400023e3:	cd 30                	int    $0x30
	*(volatile int*)(sva+ofs) = 0xdeadbeef;	// should be writable now
400023e5:	8b 85 cc fd ff ff    	mov    0xfffffdcc(%ebp),%eax
400023eb:	03 85 c0 fd ff ff    	add    0xfffffdc0(%ebp),%eax
400023f1:	c7 00 ef be ad de    	movl   $0xdeadbeef,(%eax)
	sys_get(SYS_PERM, 0, NULL, NULL, sva+ofs, PAGESIZE);
400023f7:	8b 85 cc fd ff ff    	mov    0xfffffdcc(%ebp),%eax
400023fd:	03 85 c0 fd ff ff    	add    0xfffffdc0(%ebp),%eax
40002403:	c7 45 a8 00 01 00 00 	movl   $0x100,0xffffffa8(%ebp)
4000240a:	66 c7 45 a6 00 00    	movw   $0x0,0xffffffa6(%ebp)
40002410:	c7 45 a0 00 00 00 00 	movl   $0x0,0xffffffa0(%ebp)
40002417:	c7 45 9c 00 00 00 00 	movl   $0x0,0xffffff9c(%ebp)
4000241e:	89 45 98             	mov    %eax,0xffffff98(%ebp)
40002421:	c7 45 94 00 10 00 00 	movl   $0x1000,0xffffff94(%ebp)
static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40002428:	8b 45 a8             	mov    0xffffffa8(%ebp),%eax
4000242b:	83 c8 02             	or     $0x2,%eax
4000242e:	8b 5d a0             	mov    0xffffffa0(%ebp),%ebx
40002431:	0f b7 55 a6          	movzwl 0xffffffa6(%ebp),%edx
40002435:	8b 75 9c             	mov    0xffffff9c(%ebp),%esi
40002438:	8b 7d 98             	mov    0xffffff98(%ebp),%edi
4000243b:	8b 4d 94             	mov    0xffffff94(%ebp),%ecx
4000243e:	cd 30                	int    $0x30
	readfaulttest(sva+ofs);			// hide it
40002440:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40002447:	00 
40002448:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
4000244f:	e8 00 dd ff ff       	call   40000154 <fork>
40002454:	85 c0                	test   %eax,%eax
40002456:	75 15                	jne    4000246d <memopcheck+0xe1b>
40002458:	8b 85 cc fd ff ff    	mov    0xfffffdcc(%ebp),%eax
4000245e:	03 85 c0 fd ff ff    	add    0xfffffdc0(%ebp),%eax
40002464:	8b 00                	mov    (%eax),%eax

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40002466:	b8 03 00 00 00       	mov    $0x3,%eax
4000246b:	cd 30                	int    $0x30
4000246d:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40002474:	00 
40002475:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000247c:	00 
4000247d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40002484:	e8 ab dd ff ff       	call   40000234 <join>
40002489:	c7 45 c0 00 00 02 00 	movl   $0x20000,0xffffffc0(%ebp)
40002490:	66 c7 45 be 00 00    	movw   $0x0,0xffffffbe(%ebp)
40002496:	c7 45 b8 00 00 00 00 	movl   $0x0,0xffffffb8(%ebp)
4000249d:	8b 85 c0 fd ff ff    	mov    0xfffffdc0(%ebp),%eax
400024a3:	89 45 b4             	mov    %eax,0xffffffb4(%ebp)
400024a6:	8b 85 c4 fd ff ff    	mov    0xfffffdc4(%ebp),%eax
400024ac:	89 45 b0             	mov    %eax,0xffffffb0(%ebp)
400024af:	c7 45 ac 00 00 40 00 	movl   $0x400000,0xffffffac(%ebp)
static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
400024b6:	8b 45 c0             	mov    0xffffffc0(%ebp),%eax
400024b9:	83 c8 01             	or     $0x1,%eax
400024bc:	8b 5d b8             	mov    0xffffffb8(%ebp),%ebx
400024bf:	0f b7 55 be          	movzwl 0xffffffbe(%ebp),%edx
400024c3:	8b 75 b4             	mov    0xffffffb4(%ebp),%esi
400024c6:	8b 7d b0             	mov    0xffffffb0(%ebp),%edi
400024c9:	8b 4d ac             	mov    0xffffffac(%ebp),%ecx
400024cc:	cd 30                	int    $0x30
400024ce:	c7 45 d8 00 00 02 00 	movl   $0x20000,0xffffffd8(%ebp)
400024d5:	66 c7 45 d6 00 00    	movw   $0x0,0xffffffd6(%ebp)
400024db:	c7 45 d0 00 00 00 00 	movl   $0x0,0xffffffd0(%ebp)
400024e2:	8b 85 c4 fd ff ff    	mov    0xfffffdc4(%ebp),%eax
400024e8:	89 45 cc             	mov    %eax,0xffffffcc(%ebp)
400024eb:	8b 85 c8 fd ff ff    	mov    0xfffffdc8(%ebp),%eax
400024f1:	89 45 c8             	mov    %eax,0xffffffc8(%ebp)
400024f4:	c7 45 c4 00 00 40 00 	movl   $0x400000,0xffffffc4(%ebp)
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
400024fb:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
400024fe:	83 c8 02             	or     $0x2,%eax
40002501:	8b 5d d0             	mov    0xffffffd0(%ebp),%ebx
40002504:	0f b7 55 d6          	movzwl 0xffffffd6(%ebp),%edx
40002508:	8b 75 cc             	mov    0xffffffcc(%ebp),%esi
4000250b:	8b 7d c8             	mov    0xffffffc8(%ebp),%edi
4000250e:	8b 4d c4             	mov    0xffffffc4(%ebp),%ecx
40002511:	cd 30                	int    $0x30
	sys_put(SYS_COPY, 0, NULL, sva, dva, PTSIZE);
	sys_get(SYS_COPY, 0, NULL, dva, dva2, PTSIZE);
	readfaulttest(dva2+ofs);		// stayed hidden?
40002513:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000251a:	00 
4000251b:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40002522:	e8 2d dc ff ff       	call   40000154 <fork>
40002527:	85 c0                	test   %eax,%eax
40002529:	75 15                	jne    40002540 <memopcheck+0xeee>
4000252b:	8b 85 cc fd ff ff    	mov    0xfffffdcc(%ebp),%eax
40002531:	03 85 c8 fd ff ff    	add    0xfffffdc8(%ebp),%eax
40002537:	8b 00                	mov    (%eax),%eax

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40002539:	b8 03 00 00 00       	mov    $0x3,%eax
4000253e:	cd 30                	int    $0x30
40002540:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40002547:	00 
40002548:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000254f:	00 
40002550:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40002557:	e8 d8 dc ff ff       	call   40000234 <join>
	sys_get(SYS_PERM|SYS_READ, 0, NULL, NULL, dva2+ofs, PAGESIZE);
4000255c:	8b 85 cc fd ff ff    	mov    0xfffffdcc(%ebp),%eax
40002562:	03 85 c8 fd ff ff    	add    0xfffffdc8(%ebp),%eax
40002568:	c7 45 f0 00 03 00 00 	movl   $0x300,0xfffffff0(%ebp)
4000256f:	66 c7 45 ee 00 00    	movw   $0x0,0xffffffee(%ebp)
40002575:	c7 45 e8 00 00 00 00 	movl   $0x0,0xffffffe8(%ebp)
4000257c:	c7 45 e4 00 00 00 00 	movl   $0x0,0xffffffe4(%ebp)
40002583:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)
40002586:	c7 45 dc 00 10 00 00 	movl   $0x1000,0xffffffdc(%ebp)
static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
4000258d:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
40002590:	83 c8 02             	or     $0x2,%eax
40002593:	8b 5d e8             	mov    0xffffffe8(%ebp),%ebx
40002596:	0f b7 55 ee          	movzwl 0xffffffee(%ebp),%edx
4000259a:	8b 75 e4             	mov    0xffffffe4(%ebp),%esi
4000259d:	8b 7d e0             	mov    0xffffffe0(%ebp),%edi
400025a0:	8b 4d dc             	mov    0xffffffdc(%ebp),%ecx
400025a3:	cd 30                	int    $0x30
	assert(*(volatile int*)(dva2+ofs) == 0xdeadbeef);	// survived?
400025a5:	8b 85 cc fd ff ff    	mov    0xfffffdcc(%ebp),%eax
400025ab:	03 85 c8 fd ff ff    	add    0xfffffdc8(%ebp),%eax
400025b1:	8b 00                	mov    (%eax),%eax
400025b3:	3d ef be ad de       	cmp    $0xdeadbeef,%eax
400025b8:	74 24                	je     400025de <memopcheck+0xf8c>
400025ba:	c7 44 24 0c b0 58 00 	movl   $0x400058b0,0xc(%esp)
400025c1:	40 
400025c2:	c7 44 24 08 7b 57 00 	movl   $0x4000577b,0x8(%esp)
400025c9:	40 
400025ca:	c7 44 24 04 48 01 00 	movl   $0x148,0x4(%esp)
400025d1:	00 
400025d2:	c7 04 24 88 56 00 40 	movl   $0x40005688,(%esp)
400025d9:	e8 0a 06 00 00       	call   40002be8 <debug_panic>

	cprintf("testvm: memopcheck passed\n");
400025de:	c7 04 24 d9 58 00 40 	movl   $0x400058d9,(%esp)
400025e5:	e8 b7 08 00 00       	call   40002ea1 <cprintf>
}
400025ea:	81 c4 5c 02 00 00    	add    $0x25c,%esp
400025f0:	5b                   	pop    %ebx
400025f1:	5e                   	pop    %esi
400025f2:	5f                   	pop    %edi
400025f3:	5d                   	pop    %ebp
400025f4:	c3                   	ret    

400025f5 <pqsort>:

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
400025f5:	55                   	push   %ebp
400025f6:	89 e5                	mov    %esp,%ebp
400025f8:	83 ec 38             	sub    $0x38,%esp
	if (lo >= hi)
400025fb:	8b 45 08             	mov    0x8(%ebp),%eax
400025fe:	3b 45 0c             	cmp    0xc(%ebp),%eax
40002601:	0f 83 23 01 00 00    	jae    4000272a <pqsort+0x135>
		return;

	int pivot = *lo;	// yeah, bad way to choose pivot...
40002607:	8b 45 08             	mov    0x8(%ebp),%eax
4000260a:	8b 00                	mov    (%eax),%eax
4000260c:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
	int *l = lo+1, *h = hi;
4000260f:	8b 45 08             	mov    0x8(%ebp),%eax
40002612:	83 c0 04             	add    $0x4,%eax
40002615:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
40002618:	8b 45 0c             	mov    0xc(%ebp),%eax
4000261b:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	while (l <= h) {
4000261e:	eb 42                	jmp    40002662 <pqsort+0x6d>
		if (*l < pivot)
40002620:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
40002623:	8b 00                	mov    (%eax),%eax
40002625:	3b 45 ec             	cmp    0xffffffec(%ebp),%eax
40002628:	7d 06                	jge    40002630 <pqsort+0x3b>
			l++;
4000262a:	83 45 f0 04          	addl   $0x4,0xfffffff0(%ebp)
4000262e:	eb 32                	jmp    40002662 <pqsort+0x6d>
		else if (*h > pivot)
40002630:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
40002633:	8b 00                	mov    (%eax),%eax
40002635:	3b 45 ec             	cmp    0xffffffec(%ebp),%eax
40002638:	7e 06                	jle    40002640 <pqsort+0x4b>
			h--;
4000263a:	83 6d f4 04          	subl   $0x4,0xfffffff4(%ebp)
4000263e:	eb 22                	jmp    40002662 <pqsort+0x6d>
		else
			swapints(*h, *l), l++, h--;
40002640:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
40002643:	8b 00                	mov    (%eax),%eax
40002645:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
40002648:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
4000264b:	8b 10                	mov    (%eax),%edx
4000264d:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
40002650:	89 10                	mov    %edx,(%eax)
40002652:	8b 55 f0             	mov    0xfffffff0(%ebp),%edx
40002655:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
40002658:	89 02                	mov    %eax,(%edx)
4000265a:	83 45 f0 04          	addl   $0x4,0xfffffff0(%ebp)
4000265e:	83 6d f4 04          	subl   $0x4,0xfffffff4(%ebp)
40002662:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
40002665:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
40002668:	76 b6                	jbe    40002620 <pqsort+0x2b>
	}
	swapints(*lo, l[-1]);
4000266a:	8b 45 08             	mov    0x8(%ebp),%eax
4000266d:	8b 00                	mov    (%eax),%eax
4000266f:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
40002672:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
40002675:	83 e8 04             	sub    $0x4,%eax
40002678:	8b 10                	mov    (%eax),%edx
4000267a:	8b 45 08             	mov    0x8(%ebp),%eax
4000267d:	89 10                	mov    %edx,(%eax)
4000267f:	8b 55 f0             	mov    0xfffffff0(%ebp),%edx
40002682:	83 ea 04             	sub    $0x4,%edx
40002685:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
40002688:	89 02                	mov    %eax,(%edx)

	// Now recursively sort the two halves in parallel subprocesses
	if (!fork(SYS_START | SYS_SNAP, 0)) {
4000268a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40002691:	00 
40002692:	c7 04 24 10 00 04 00 	movl   $0x40010,(%esp)
40002699:	e8 b6 da ff ff       	call   40000154 <fork>
4000269e:	85 c0                	test   %eax,%eax
400026a0:	75 1c                	jne    400026be <pqsort+0xc9>
		pqsort(lo, l-2);
400026a2:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
400026a5:	83 e8 08             	sub    $0x8,%eax
400026a8:	89 44 24 04          	mov    %eax,0x4(%esp)
400026ac:	8b 45 08             	mov    0x8(%ebp),%eax
400026af:	89 04 24             	mov    %eax,(%esp)
400026b2:	e8 3e ff ff ff       	call   400025f5 <pqsort>

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
400026b7:	b8 03 00 00 00       	mov    $0x3,%eax
400026bc:	cd 30                	int    $0x30
		sys_ret();
	}
	if (!fork(SYS_START | SYS_SNAP, 1)) {
400026be:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
400026c5:	00 
400026c6:	c7 04 24 10 00 04 00 	movl   $0x40010,(%esp)
400026cd:	e8 82 da ff ff       	call   40000154 <fork>
400026d2:	85 c0                	test   %eax,%eax
400026d4:	75 1c                	jne    400026f2 <pqsort+0xfd>
		pqsort(h+1, hi);
400026d6:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
400026d9:	83 c2 04             	add    $0x4,%edx
400026dc:	8b 45 0c             	mov    0xc(%ebp),%eax
400026df:	89 44 24 04          	mov    %eax,0x4(%esp)
400026e3:	89 14 24             	mov    %edx,(%esp)
400026e6:	e8 0a ff ff ff       	call   400025f5 <pqsort>

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
400026eb:	b8 03 00 00 00       	mov    $0x3,%eax
400026f0:	cd 30                	int    $0x30
		sys_ret();
	}
	join(SYS_MERGE, 0, T_SYSCALL);
400026f2:	c7 44 24 08 30 00 00 	movl   $0x30,0x8(%esp)
400026f9:	00 
400026fa:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40002701:	00 
40002702:	c7 04 24 00 00 03 00 	movl   $0x30000,(%esp)
40002709:	e8 26 db ff ff       	call   40000234 <join>
	join(SYS_MERGE, 1, T_SYSCALL);
4000270e:	c7 44 24 08 30 00 00 	movl   $0x30,0x8(%esp)
40002715:	00 
40002716:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
4000271d:	00 
4000271e:	c7 04 24 00 00 03 00 	movl   $0x30000,(%esp)
40002725:	e8 0a db ff ff       	call   40000234 <join>
}
4000272a:	c9                   	leave  
4000272b:	c3                   	ret    

4000272c <matmult>:

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
4000272c:	55                   	push   %ebp
4000272d:	89 e5                	mov    %esp,%ebp
4000272f:	83 ec 38             	sub    $0x38,%esp
	int i,j,k;

	// Fork off a thread to compute each cell in the result matrix
	for (i = 0; i < 8; i++)
40002732:	c7 45 e8 00 00 00 00 	movl   $0x0,0xffffffe8(%ebp)
40002739:	e9 a1 00 00 00       	jmp    400027df <matmult+0xb3>
		for (j = 0; j < 8; j++) {
4000273e:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
40002745:	e9 87 00 00 00       	jmp    400027d1 <matmult+0xa5>
			int child = i*8 + j;
4000274a:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
4000274d:	c1 e0 03             	shl    $0x3,%eax
40002750:	03 45 ec             	add    0xffffffec(%ebp),%eax
40002753:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
			if (!fork(SYS_START | SYS_SNAP, child)) {
40002756:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
40002759:	0f b6 c0             	movzbl %al,%eax
4000275c:	89 44 24 04          	mov    %eax,0x4(%esp)
40002760:	c7 04 24 10 00 04 00 	movl   $0x40010,(%esp)
40002767:	e8 e8 d9 ff ff       	call   40000154 <fork>
4000276c:	85 c0                	test   %eax,%eax
4000276e:	75 5d                	jne    400027cd <matmult+0xa1>
				int sum = 0;	// in child: compute cell i,j
40002770:	c7 45 f8 00 00 00 00 	movl   $0x0,0xfffffff8(%ebp)
				for (k = 0; k < 8; k++)
40002777:	c7 45 f0 00 00 00 00 	movl   $0x0,0xfffffff0(%ebp)
4000277e:	eb 2c                	jmp    400027ac <matmult+0x80>
					sum += a[i][k] * b[k][j];
40002780:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
40002783:	c1 e0 05             	shl    $0x5,%eax
40002786:	89 c2                	mov    %eax,%edx
40002788:	03 55 08             	add    0x8(%ebp),%edx
4000278b:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
4000278e:	8b 0c 82             	mov    (%edx,%eax,4),%ecx
40002791:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
40002794:	c1 e0 05             	shl    $0x5,%eax
40002797:	89 c2                	mov    %eax,%edx
40002799:	03 55 0c             	add    0xc(%ebp),%edx
4000279c:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
4000279f:	8b 04 82             	mov    (%edx,%eax,4),%eax
400027a2:	0f af c1             	imul   %ecx,%eax
400027a5:	01 45 f8             	add    %eax,0xfffffff8(%ebp)
400027a8:	83 45 f0 01          	addl   $0x1,0xfffffff0(%ebp)
400027ac:	83 7d f0 07          	cmpl   $0x7,0xfffffff0(%ebp)
400027b0:	7e ce                	jle    40002780 <matmult+0x54>
				r[i][j] = sum;
400027b2:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
400027b5:	c1 e0 05             	shl    $0x5,%eax
400027b8:	89 c1                	mov    %eax,%ecx
400027ba:	03 4d 10             	add    0x10(%ebp),%ecx
400027bd:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
400027c0:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
400027c3:	89 04 91             	mov    %eax,(%ecx,%edx,4)

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
400027c6:	b8 03 00 00 00       	mov    $0x3,%eax
400027cb:	cd 30                	int    $0x30
400027cd:	83 45 ec 01          	addl   $0x1,0xffffffec(%ebp)
400027d1:	83 7d ec 07          	cmpl   $0x7,0xffffffec(%ebp)
400027d5:	0f 8e 6f ff ff ff    	jle    4000274a <matmult+0x1e>
400027db:	83 45 e8 01          	addl   $0x1,0xffffffe8(%ebp)
400027df:	83 7d e8 07          	cmpl   $0x7,0xffffffe8(%ebp)
400027e3:	0f 8e 55 ff ff ff    	jle    4000273e <matmult+0x12>
				sys_ret();
			}
		}

	// Now go back and merge in the results of all our children
	for (i = 0; i < 8; i++)
400027e9:	c7 45 e8 00 00 00 00 	movl   $0x0,0xffffffe8(%ebp)
400027f0:	eb 41                	jmp    40002833 <matmult+0x107>
		for (j = 0; j < 8; j++) {
400027f2:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
400027f9:	eb 2e                	jmp    40002829 <matmult+0xfd>
			int child = i*8 + j;
400027fb:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
400027fe:	c1 e0 03             	shl    $0x3,%eax
40002801:	03 45 ec             	add    0xffffffec(%ebp),%eax
40002804:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
			join(SYS_MERGE, child, T_SYSCALL);
40002807:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
4000280a:	0f b6 c0             	movzbl %al,%eax
4000280d:	c7 44 24 08 30 00 00 	movl   $0x30,0x8(%esp)
40002814:	00 
40002815:	89 44 24 04          	mov    %eax,0x4(%esp)
40002819:	c7 04 24 00 00 03 00 	movl   $0x30000,(%esp)
40002820:	e8 0f da ff ff       	call   40000234 <join>
40002825:	83 45 ec 01          	addl   $0x1,0xffffffec(%ebp)
40002829:	83 7d ec 07          	cmpl   $0x7,0xffffffec(%ebp)
4000282d:	7e cc                	jle    400027fb <matmult+0xcf>
4000282f:	83 45 e8 01          	addl   $0x1,0xffffffe8(%ebp)
40002833:	83 7d e8 07          	cmpl   $0x7,0xffffffe8(%ebp)
40002837:	7e b9                	jle    400027f2 <matmult+0xc6>
		}
}
40002839:	c9                   	leave  
4000283a:	c3                   	ret    

4000283b <mergecheck>:

void
mergecheck()
{
4000283b:	55                   	push   %ebp
4000283c:	89 e5                	mov    %esp,%ebp
4000283e:	83 ec 18             	sub    $0x18,%esp
	// Simple merge test: two children write two adjacent variables
	if (!fork(SYS_START | SYS_SNAP, 0)) { x = 0xdeadbeef; sys_ret(); }
40002841:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40002848:	00 
40002849:	c7 04 24 10 00 04 00 	movl   $0x40010,(%esp)
40002850:	e8 ff d8 ff ff       	call   40000154 <fork>
40002855:	85 c0                	test   %eax,%eax
40002857:	75 11                	jne    4000286a <mergecheck+0x2f>
40002859:	c7 05 e0 7a 00 40 ef 	movl   $0xdeadbeef,0x40007ae0
40002860:	be ad de 

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40002863:	b8 03 00 00 00       	mov    $0x3,%eax
40002868:	cd 30                	int    $0x30
	if (!fork(SYS_START | SYS_SNAP, 1)) { y = 0xabadcafe; sys_ret(); }
4000286a:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
40002871:	00 
40002872:	c7 04 24 10 00 04 00 	movl   $0x40010,(%esp)
40002879:	e8 d6 d8 ff ff       	call   40000154 <fork>
4000287e:	85 c0                	test   %eax,%eax
40002880:	75 11                	jne    40002893 <mergecheck+0x58>
40002882:	c7 05 00 9c 00 40 fe 	movl   $0xabadcafe,0x40009c00
40002889:	ca ad ab 

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
4000288c:	b8 03 00 00 00       	mov    $0x3,%eax
40002891:	cd 30                	int    $0x30
	assert(x == 0); assert(y == 0);
40002893:	a1 e0 7a 00 40       	mov    0x40007ae0,%eax
40002898:	85 c0                	test   %eax,%eax
4000289a:	74 24                	je     400028c0 <mergecheck+0x85>
4000289c:	c7 44 24 0c 00 5e 00 	movl   $0x40005e00,0xc(%esp)
400028a3:	40 
400028a4:	c7 44 24 08 7b 57 00 	movl   $0x4000577b,0x8(%esp)
400028ab:	40 
400028ac:	c7 44 24 04 d0 01 00 	movl   $0x1d0,0x4(%esp)
400028b3:	00 
400028b4:	c7 04 24 88 56 00 40 	movl   $0x40005688,(%esp)
400028bb:	e8 28 03 00 00       	call   40002be8 <debug_panic>
400028c0:	a1 00 9c 00 40       	mov    0x40009c00,%eax
400028c5:	85 c0                	test   %eax,%eax
400028c7:	74 24                	je     400028ed <mergecheck+0xb2>
400028c9:	c7 44 24 0c 07 5e 00 	movl   $0x40005e07,0xc(%esp)
400028d0:	40 
400028d1:	c7 44 24 08 7b 57 00 	movl   $0x4000577b,0x8(%esp)
400028d8:	40 
400028d9:	c7 44 24 04 d0 01 00 	movl   $0x1d0,0x4(%esp)
400028e0:	00 
400028e1:	c7 04 24 88 56 00 40 	movl   $0x40005688,(%esp)
400028e8:	e8 fb 02 00 00       	call   40002be8 <debug_panic>
	join(SYS_MERGE, 0, T_SYSCALL);
400028ed:	c7 44 24 08 30 00 00 	movl   $0x30,0x8(%esp)
400028f4:	00 
400028f5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400028fc:	00 
400028fd:	c7 04 24 00 00 03 00 	movl   $0x30000,(%esp)
40002904:	e8 2b d9 ff ff       	call   40000234 <join>
	join(SYS_MERGE, 1, T_SYSCALL);
40002909:	c7 44 24 08 30 00 00 	movl   $0x30,0x8(%esp)
40002910:	00 
40002911:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
40002918:	00 
40002919:	c7 04 24 00 00 03 00 	movl   $0x30000,(%esp)
40002920:	e8 0f d9 ff ff       	call   40000234 <join>
	assert(x == 0xdeadbeef); assert(y == 0xabadcafe);
40002925:	a1 e0 7a 00 40       	mov    0x40007ae0,%eax
4000292a:	3d ef be ad de       	cmp    $0xdeadbeef,%eax
4000292f:	74 24                	je     40002955 <mergecheck+0x11a>
40002931:	c7 44 24 0c 0e 5e 00 	movl   $0x40005e0e,0xc(%esp)
40002938:	40 
40002939:	c7 44 24 08 7b 57 00 	movl   $0x4000577b,0x8(%esp)
40002940:	40 
40002941:	c7 44 24 04 d3 01 00 	movl   $0x1d3,0x4(%esp)
40002948:	00 
40002949:	c7 04 24 88 56 00 40 	movl   $0x40005688,(%esp)
40002950:	e8 93 02 00 00       	call   40002be8 <debug_panic>
40002955:	a1 00 9c 00 40       	mov    0x40009c00,%eax
4000295a:	3d fe ca ad ab       	cmp    $0xabadcafe,%eax
4000295f:	74 24                	je     40002985 <mergecheck+0x14a>
40002961:	c7 44 24 0c 1e 5e 00 	movl   $0x40005e1e,0xc(%esp)
40002968:	40 
40002969:	c7 44 24 08 7b 57 00 	movl   $0x4000577b,0x8(%esp)
40002970:	40 
40002971:	c7 44 24 04 d3 01 00 	movl   $0x1d3,0x4(%esp)
40002978:	00 
40002979:	c7 04 24 88 56 00 40 	movl   $0x40005688,(%esp)
40002980:	e8 63 02 00 00       	call   40002be8 <debug_panic>

	// A Rube Goldberg approach to swapping two variables
	if (!fork(SYS_START | SYS_SNAP, 0)) { x = y; sys_ret(); }
40002985:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000298c:	00 
4000298d:	c7 04 24 10 00 04 00 	movl   $0x40010,(%esp)
40002994:	e8 bb d7 ff ff       	call   40000154 <fork>
40002999:	85 c0                	test   %eax,%eax
4000299b:	75 11                	jne    400029ae <mergecheck+0x173>
4000299d:	a1 00 9c 00 40       	mov    0x40009c00,%eax
400029a2:	a3 e0 7a 00 40       	mov    %eax,0x40007ae0

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
400029a7:	b8 03 00 00 00       	mov    $0x3,%eax
400029ac:	cd 30                	int    $0x30
	if (!fork(SYS_START | SYS_SNAP, 1)) { y = x; sys_ret(); }
400029ae:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
400029b5:	00 
400029b6:	c7 04 24 10 00 04 00 	movl   $0x40010,(%esp)
400029bd:	e8 92 d7 ff ff       	call   40000154 <fork>
400029c2:	85 c0                	test   %eax,%eax
400029c4:	75 11                	jne    400029d7 <mergecheck+0x19c>
400029c6:	a1 e0 7a 00 40       	mov    0x40007ae0,%eax
400029cb:	a3 00 9c 00 40       	mov    %eax,0x40009c00

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
400029d0:	b8 03 00 00 00       	mov    $0x3,%eax
400029d5:	cd 30                	int    $0x30
	assert(x == 0xdeadbeef); assert(y == 0xabadcafe);
400029d7:	a1 e0 7a 00 40       	mov    0x40007ae0,%eax
400029dc:	3d ef be ad de       	cmp    $0xdeadbeef,%eax
400029e1:	74 24                	je     40002a07 <mergecheck+0x1cc>
400029e3:	c7 44 24 0c 0e 5e 00 	movl   $0x40005e0e,0xc(%esp)
400029ea:	40 
400029eb:	c7 44 24 08 7b 57 00 	movl   $0x4000577b,0x8(%esp)
400029f2:	40 
400029f3:	c7 44 24 04 d8 01 00 	movl   $0x1d8,0x4(%esp)
400029fa:	00 
400029fb:	c7 04 24 88 56 00 40 	movl   $0x40005688,(%esp)
40002a02:	e8 e1 01 00 00       	call   40002be8 <debug_panic>
40002a07:	a1 00 9c 00 40       	mov    0x40009c00,%eax
40002a0c:	3d fe ca ad ab       	cmp    $0xabadcafe,%eax
40002a11:	74 24                	je     40002a37 <mergecheck+0x1fc>
40002a13:	c7 44 24 0c 1e 5e 00 	movl   $0x40005e1e,0xc(%esp)
40002a1a:	40 
40002a1b:	c7 44 24 08 7b 57 00 	movl   $0x4000577b,0x8(%esp)
40002a22:	40 
40002a23:	c7 44 24 04 d8 01 00 	movl   $0x1d8,0x4(%esp)
40002a2a:	00 
40002a2b:	c7 04 24 88 56 00 40 	movl   $0x40005688,(%esp)
40002a32:	e8 b1 01 00 00       	call   40002be8 <debug_panic>
	join(SYS_MERGE, 0, T_SYSCALL);
40002a37:	c7 44 24 08 30 00 00 	movl   $0x30,0x8(%esp)
40002a3e:	00 
40002a3f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40002a46:	00 
40002a47:	c7 04 24 00 00 03 00 	movl   $0x30000,(%esp)
40002a4e:	e8 e1 d7 ff ff       	call   40000234 <join>
	join(SYS_MERGE, 1, T_SYSCALL);
40002a53:	c7 44 24 08 30 00 00 	movl   $0x30,0x8(%esp)
40002a5a:	00 
40002a5b:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
40002a62:	00 
40002a63:	c7 04 24 00 00 03 00 	movl   $0x30000,(%esp)
40002a6a:	e8 c5 d7 ff ff       	call   40000234 <join>
	assert(y == 0xdeadbeef); assert(x == 0xabadcafe);
40002a6f:	a1 00 9c 00 40       	mov    0x40009c00,%eax
40002a74:	3d ef be ad de       	cmp    $0xdeadbeef,%eax
40002a79:	74 24                	je     40002a9f <mergecheck+0x264>
40002a7b:	c7 44 24 0c 2e 5e 00 	movl   $0x40005e2e,0xc(%esp)
40002a82:	40 
40002a83:	c7 44 24 08 7b 57 00 	movl   $0x4000577b,0x8(%esp)
40002a8a:	40 
40002a8b:	c7 44 24 04 db 01 00 	movl   $0x1db,0x4(%esp)
40002a92:	00 
40002a93:	c7 04 24 88 56 00 40 	movl   $0x40005688,(%esp)
40002a9a:	e8 49 01 00 00       	call   40002be8 <debug_panic>
40002a9f:	a1 e0 7a 00 40       	mov    0x40007ae0,%eax
40002aa4:	3d fe ca ad ab       	cmp    $0xabadcafe,%eax
40002aa9:	74 24                	je     40002acf <mergecheck+0x294>
40002aab:	c7 44 24 0c 3e 5e 00 	movl   $0x40005e3e,0xc(%esp)
40002ab2:	40 
40002ab3:	c7 44 24 08 7b 57 00 	movl   $0x4000577b,0x8(%esp)
40002aba:	40 
40002abb:	c7 44 24 04 db 01 00 	movl   $0x1db,0x4(%esp)
40002ac2:	00 
40002ac3:	c7 04 24 88 56 00 40 	movl   $0x40005688,(%esp)
40002aca:	e8 19 01 00 00       	call   40002be8 <debug_panic>

	// Parallel quicksort with recursive processes!
	// (though probably not very efficient on arrays this small)
	pqsort(&randints[0], &randints[256-1]);
40002acf:	b8 dc 78 00 40       	mov    $0x400078dc,%eax
40002ad4:	89 44 24 04          	mov    %eax,0x4(%esp)
40002ad8:	c7 04 24 e0 74 00 40 	movl   $0x400074e0,(%esp)
40002adf:	e8 11 fb ff ff       	call   400025f5 <pqsort>
	assert(memcmp(randints, sortints, 256*sizeof(int)) == 0);
40002ae4:	c7 44 24 08 00 04 00 	movl   $0x400,0x8(%esp)
40002aeb:	00 
40002aec:	c7 44 24 04 00 59 00 	movl   $0x40005900,0x4(%esp)
40002af3:	40 
40002af4:	c7 04 24 e0 74 00 40 	movl   $0x400074e0,(%esp)
40002afb:	e8 09 0e 00 00       	call   40003909 <memcmp>
40002b00:	85 c0                	test   %eax,%eax
40002b02:	74 24                	je     40002b28 <mergecheck+0x2ed>
40002b04:	c7 44 24 0c 50 5e 00 	movl   $0x40005e50,0xc(%esp)
40002b0b:	40 
40002b0c:	c7 44 24 08 7b 57 00 	movl   $0x4000577b,0x8(%esp)
40002b13:	40 
40002b14:	c7 44 24 04 e0 01 00 	movl   $0x1e0,0x4(%esp)
40002b1b:	00 
40002b1c:	c7 04 24 88 56 00 40 	movl   $0x40005688,(%esp)
40002b23:	e8 c0 00 00 00       	call   40002be8 <debug_panic>

	// Parallel matrix multiply, one child process per result matrix cell
	matmult(ma, mb, mr);
40002b28:	c7 44 24 08 00 9b 00 	movl   $0x40009b00,0x8(%esp)
40002b2f:	40 
40002b30:	c7 44 24 04 e0 79 00 	movl   $0x400079e0,0x4(%esp)
40002b37:	40 
40002b38:	c7 04 24 e0 78 00 40 	movl   $0x400078e0,(%esp)
40002b3f:	e8 e8 fb ff ff       	call   4000272c <matmult>
	assert(sizeof(mr) == sizeof(int)*8*8);
	assert(sizeof(mc) == sizeof(int)*8*8);
	assert(memcmp(mr, mc, sizeof(mr)) == 0);
40002b44:	c7 44 24 08 00 01 00 	movl   $0x100,0x8(%esp)
40002b4b:	00 
40002b4c:	c7 44 24 04 00 5d 00 	movl   $0x40005d00,0x4(%esp)
40002b53:	40 
40002b54:	c7 04 24 00 9b 00 40 	movl   $0x40009b00,(%esp)
40002b5b:	e8 a9 0d 00 00       	call   40003909 <memcmp>
40002b60:	85 c0                	test   %eax,%eax
40002b62:	74 24                	je     40002b88 <mergecheck+0x34d>
40002b64:	c7 44 24 0c 84 5e 00 	movl   $0x40005e84,0xc(%esp)
40002b6b:	40 
40002b6c:	c7 44 24 08 7b 57 00 	movl   $0x4000577b,0x8(%esp)
40002b73:	40 
40002b74:	c7 44 24 04 e6 01 00 	movl   $0x1e6,0x4(%esp)
40002b7b:	00 
40002b7c:	c7 04 24 88 56 00 40 	movl   $0x40005688,(%esp)
40002b83:	e8 60 00 00 00       	call   40002be8 <debug_panic>

	cprintf("testvm: mergecheck passed\n");
40002b88:	c7 04 24 a4 5e 00 40 	movl   $0x40005ea4,(%esp)
40002b8f:	e8 0d 03 00 00       	call   40002ea1 <cprintf>
}
40002b94:	c9                   	leave  
40002b95:	c3                   	ret    

40002b96 <main>:

int
main()
{
40002b96:	8d 4c 24 04          	lea    0x4(%esp),%ecx
40002b9a:	83 e4 f0             	and    $0xfffffff0,%esp
40002b9d:	ff 71 fc             	pushl  0xfffffffc(%ecx)
40002ba0:	55                   	push   %ebp
40002ba1:	89 e5                	mov    %esp,%ebp
40002ba3:	51                   	push   %ecx
40002ba4:	83 ec 04             	sub    $0x4,%esp
	cprintf("testvm: in main()\n");
40002ba7:	c7 04 24 bf 5e 00 40 	movl   $0x40005ebf,(%esp)
40002bae:	e8 ee 02 00 00       	call   40002ea1 <cprintf>

	loadcheck();
40002bb3:	e8 23 d8 ff ff       	call   400003db <loadcheck>
	forkcheck();
40002bb8:	e8 a0 d8 ff ff       	call   4000045d <forkcheck>
	protcheck();
40002bbd:	e8 ff db ff ff       	call   400007c1 <protcheck>
	memopcheck();
40002bc2:	e8 8b ea ff ff       	call   40001652 <memopcheck>
	mergecheck();
40002bc7:	e8 6f fc ff ff       	call   4000283b <mergecheck>

	cprintf("testvm: all tests completed successfully!\n");
40002bcc:	c7 04 24 d4 5e 00 40 	movl   $0x40005ed4,(%esp)
40002bd3:	e8 c9 02 00 00       	call   40002ea1 <cprintf>
	return 0;
40002bd8:	b8 00 00 00 00       	mov    $0x0,%eax
}
40002bdd:	83 c4 04             	add    $0x4,%esp
40002be0:	59                   	pop    %ecx
40002be1:	5d                   	pop    %ebp
40002be2:	8d 61 fc             	lea    0xfffffffc(%ecx),%esp
40002be5:	c3                   	ret    
40002be6:	90                   	nop    
40002be7:	90                   	nop    

40002be8 <debug_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception.
 */
void
debug_panic(const char *file, int line, const char *fmt,...)
{
40002be8:	55                   	push   %ebp
40002be9:	89 e5                	mov    %esp,%ebp
40002beb:	83 ec 28             	sub    $0x28,%esp
	va_list ap;
	va_start(ap, fmt);
40002bee:	8d 45 10             	lea    0x10(%ebp),%eax
40002bf1:	83 c0 04             	add    $0x4,%eax
40002bf4:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)

	// Print the panic message
	if (argv0)
40002bf7:	a1 04 9c 00 40       	mov    0x40009c04,%eax
40002bfc:	85 c0                	test   %eax,%eax
40002bfe:	74 15                	je     40002c15 <debug_panic+0x2d>
		cprintf("%s: ", argv0);
40002c00:	a1 04 9c 00 40       	mov    0x40009c04,%eax
40002c05:	89 44 24 04          	mov    %eax,0x4(%esp)
40002c09:	c7 04 24 00 5f 00 40 	movl   $0x40005f00,(%esp)
40002c10:	e8 8c 02 00 00       	call   40002ea1 <cprintf>
	cprintf("user panic at %s:%d: ", file, line);
40002c15:	8b 45 0c             	mov    0xc(%ebp),%eax
40002c18:	89 44 24 08          	mov    %eax,0x8(%esp)
40002c1c:	8b 45 08             	mov    0x8(%ebp),%eax
40002c1f:	89 44 24 04          	mov    %eax,0x4(%esp)
40002c23:	c7 04 24 05 5f 00 40 	movl   $0x40005f05,(%esp)
40002c2a:	e8 72 02 00 00       	call   40002ea1 <cprintf>
	vcprintf(fmt, ap);
40002c2f:	8b 55 10             	mov    0x10(%ebp),%edx
40002c32:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
40002c35:	89 44 24 04          	mov    %eax,0x4(%esp)
40002c39:	89 14 24             	mov    %edx,(%esp)
40002c3c:	e8 f7 01 00 00       	call   40002e38 <vcprintf>
	cprintf("\n");
40002c41:	c7 04 24 1b 5f 00 40 	movl   $0x40005f1b,(%esp)
40002c48:	e8 54 02 00 00       	call   40002ea1 <cprintf>

	abort();
40002c4d:	e8 97 0d 00 00       	call   400039e9 <abort>

40002c52 <debug_warn>:
}

/* like panic, but don't */
void
debug_warn(const char *file, int line, const char *fmt,...)
{
40002c52:	55                   	push   %ebp
40002c53:	89 e5                	mov    %esp,%ebp
40002c55:	83 ec 28             	sub    $0x28,%esp
	va_list ap;

	va_start(ap, fmt);
40002c58:	8d 45 10             	lea    0x10(%ebp),%eax
40002c5b:	83 c0 04             	add    $0x4,%eax
40002c5e:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	cprintf("user warning at %s:%d: ", file, line);
40002c61:	8b 45 0c             	mov    0xc(%ebp),%eax
40002c64:	89 44 24 08          	mov    %eax,0x8(%esp)
40002c68:	8b 45 08             	mov    0x8(%ebp),%eax
40002c6b:	89 44 24 04          	mov    %eax,0x4(%esp)
40002c6f:	c7 04 24 1d 5f 00 40 	movl   $0x40005f1d,(%esp)
40002c76:	e8 26 02 00 00       	call   40002ea1 <cprintf>
	vcprintf(fmt, ap);
40002c7b:	8b 55 10             	mov    0x10(%ebp),%edx
40002c7e:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
40002c81:	89 44 24 04          	mov    %eax,0x4(%esp)
40002c85:	89 14 24             	mov    %edx,(%esp)
40002c88:	e8 ab 01 00 00       	call   40002e38 <vcprintf>
	cprintf("\n");
40002c8d:	c7 04 24 1b 5f 00 40 	movl   $0x40005f1b,(%esp)
40002c94:	e8 08 02 00 00       	call   40002ea1 <cprintf>
	va_end(ap);
}
40002c99:	c9                   	leave  
40002c9a:	c3                   	ret    

40002c9b <debug_dump>:

// Dump a block of memory as 32-bit words and ASCII bytes
void
debug_dump(const char *file, int line, const void *ptr, int size)
{
40002c9b:	55                   	push   %ebp
40002c9c:	89 e5                	mov    %esp,%ebp
40002c9e:	56                   	push   %esi
40002c9f:	53                   	push   %ebx
40002ca0:	81 ec b0 00 00 00    	sub    $0xb0,%esp
	cprintf("user dump at %s:%d of memory %08x-%08x:\n",
40002ca6:	8b 45 14             	mov    0x14(%ebp),%eax
40002ca9:	03 45 10             	add    0x10(%ebp),%eax
40002cac:	89 44 24 10          	mov    %eax,0x10(%esp)
40002cb0:	8b 45 10             	mov    0x10(%ebp),%eax
40002cb3:	89 44 24 0c          	mov    %eax,0xc(%esp)
40002cb7:	8b 45 0c             	mov    0xc(%ebp),%eax
40002cba:	89 44 24 08          	mov    %eax,0x8(%esp)
40002cbe:	8b 45 08             	mov    0x8(%ebp),%eax
40002cc1:	89 44 24 04          	mov    %eax,0x4(%esp)
40002cc5:	c7 04 24 38 5f 00 40 	movl   $0x40005f38,(%esp)
40002ccc:	e8 d0 01 00 00       	call   40002ea1 <cprintf>
		file, line, ptr, ptr + size);
	for (size = (size+15) & ~15; size > 0; size -= 16, ptr += 16) {
40002cd1:	8b 45 14             	mov    0x14(%ebp),%eax
40002cd4:	83 c0 0f             	add    $0xf,%eax
40002cd7:	83 e0 f0             	and    $0xfffffff0,%eax
40002cda:	89 45 14             	mov    %eax,0x14(%ebp)
40002cdd:	e9 df 00 00 00       	jmp    40002dc1 <debug_dump+0x126>
		char buf[100];

		// ASCII bytes
		int i; 
		const uint8_t *c = ptr;
40002ce2:	8b 45 10             	mov    0x10(%ebp),%eax
40002ce5:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
		for (i = 0; i < 16; i++)
40002ce8:	c7 45 e8 00 00 00 00 	movl   $0x0,0xffffffe8(%ebp)
40002cef:	eb 71                	jmp    40002d62 <debug_dump+0xc7>
			buf[i] = isprint(c[i]) ? c[i] : '.';
40002cf1:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
40002cf4:	89 85 6c ff ff ff    	mov    %eax,0xffffff6c(%ebp)
40002cfa:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
40002cfd:	03 45 ec             	add    0xffffffec(%ebp),%eax
40002d00:	0f b6 00             	movzbl (%eax),%eax
40002d03:	0f b6 c0             	movzbl %al,%eax
40002d06:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
static gcc_inline int iscntrl(int c)	{ return c < ' '; }
static gcc_inline int isblank(int c)	{ return c == ' ' || c == '\t'; }
static gcc_inline int isspace(int c)	{ return c == ' '
						|| (c >= '\t' && c <= '\r'); }
static gcc_inline int isprint(int c)	{ return c >= ' ' && c <= '~'; }
40002d09:	83 7d f4 1f          	cmpl   $0x1f,0xfffffff4(%ebp)
40002d0d:	7e 12                	jle    40002d21 <debug_dump+0x86>
40002d0f:	83 7d f4 7e          	cmpl   $0x7e,0xfffffff4(%ebp)
40002d13:	7f 0c                	jg     40002d21 <debug_dump+0x86>
40002d15:	c7 85 74 ff ff ff 01 	movl   $0x1,0xffffff74(%ebp)
40002d1c:	00 00 00 
40002d1f:	eb 0a                	jmp    40002d2b <debug_dump+0x90>
40002d21:	c7 85 74 ff ff ff 00 	movl   $0x0,0xffffff74(%ebp)
40002d28:	00 00 00 
40002d2b:	8b 85 74 ff ff ff    	mov    0xffffff74(%ebp),%eax
40002d31:	85 c0                	test   %eax,%eax
40002d33:	74 11                	je     40002d46 <debug_dump+0xab>
40002d35:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
40002d38:	03 45 ec             	add    0xffffffec(%ebp),%eax
40002d3b:	0f b6 00             	movzbl (%eax),%eax
40002d3e:	88 85 73 ff ff ff    	mov    %al,0xffffff73(%ebp)
40002d44:	eb 07                	jmp    40002d4d <debug_dump+0xb2>
40002d46:	c6 85 73 ff ff ff 2e 	movb   $0x2e,0xffffff73(%ebp)
40002d4d:	0f b6 95 73 ff ff ff 	movzbl 0xffffff73(%ebp),%edx
40002d54:	8b 85 6c ff ff ff    	mov    0xffffff6c(%ebp),%eax
40002d5a:	88 54 05 84          	mov    %dl,0xffffff84(%ebp,%eax,1)
40002d5e:	83 45 e8 01          	addl   $0x1,0xffffffe8(%ebp)
40002d62:	83 7d e8 0f          	cmpl   $0xf,0xffffffe8(%ebp)
40002d66:	7e 89                	jle    40002cf1 <debug_dump+0x56>
		buf[16] = 0;
40002d68:	c6 45 94 00          	movb   $0x0,0xffffff94(%ebp)

		// Hex words
		const uint32_t *v = ptr;
40002d6c:	8b 45 10             	mov    0x10(%ebp),%eax
40002d6f:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)

		// Print each line atomically to avoid async mixing
		cprintf("%08x: %08x %08x %08x %08x %s",
40002d72:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
40002d75:	83 c0 0c             	add    $0xc,%eax
40002d78:	8b 10                	mov    (%eax),%edx
40002d7a:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
40002d7d:	83 c0 08             	add    $0x8,%eax
40002d80:	8b 08                	mov    (%eax),%ecx
40002d82:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
40002d85:	83 c0 04             	add    $0x4,%eax
40002d88:	8b 18                	mov    (%eax),%ebx
40002d8a:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
40002d8d:	8b 30                	mov    (%eax),%esi
40002d8f:	8d 45 84             	lea    0xffffff84(%ebp),%eax
40002d92:	89 44 24 18          	mov    %eax,0x18(%esp)
40002d96:	89 54 24 14          	mov    %edx,0x14(%esp)
40002d9a:	89 4c 24 10          	mov    %ecx,0x10(%esp)
40002d9e:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
40002da2:	89 74 24 08          	mov    %esi,0x8(%esp)
40002da6:	8b 45 10             	mov    0x10(%ebp),%eax
40002da9:	89 44 24 04          	mov    %eax,0x4(%esp)
40002dad:	c7 04 24 61 5f 00 40 	movl   $0x40005f61,(%esp)
40002db4:	e8 e8 00 00 00       	call   40002ea1 <cprintf>
40002db9:	83 6d 14 10          	subl   $0x10,0x14(%ebp)
40002dbd:	83 45 10 10          	addl   $0x10,0x10(%ebp)
40002dc1:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
40002dc5:	0f 8f 17 ff ff ff    	jg     40002ce2 <debug_dump+0x47>
			ptr, v[0], v[1], v[2], v[3], buf);
	}
}
40002dcb:	81 c4 b0 00 00 00    	add    $0xb0,%esp
40002dd1:	5b                   	pop    %ebx
40002dd2:	5e                   	pop    %esi
40002dd3:	5d                   	pop    %ebp
40002dd4:	c3                   	ret    
40002dd5:	90                   	nop    
40002dd6:	90                   	nop    
40002dd7:	90                   	nop    

40002dd8 <putch>:


static void
putch(int ch, struct printbuf *b)
{
40002dd8:	55                   	push   %ebp
40002dd9:	89 e5                	mov    %esp,%ebp
40002ddb:	83 ec 08             	sub    $0x8,%esp
	b->buf[b->idx++] = ch;
40002dde:	8b 45 0c             	mov    0xc(%ebp),%eax
40002de1:	8b 08                	mov    (%eax),%ecx
40002de3:	8b 45 08             	mov    0x8(%ebp),%eax
40002de6:	89 c2                	mov    %eax,%edx
40002de8:	8b 45 0c             	mov    0xc(%ebp),%eax
40002deb:	88 54 08 08          	mov    %dl,0x8(%eax,%ecx,1)
40002def:	8d 51 01             	lea    0x1(%ecx),%edx
40002df2:	8b 45 0c             	mov    0xc(%ebp),%eax
40002df5:	89 10                	mov    %edx,(%eax)
	if (b->idx == CPUTS_MAX-1) {
40002df7:	8b 45 0c             	mov    0xc(%ebp),%eax
40002dfa:	8b 00                	mov    (%eax),%eax
40002dfc:	3d ff 00 00 00       	cmp    $0xff,%eax
40002e01:	75 24                	jne    40002e27 <putch+0x4f>
		b->buf[b->idx] = 0;
40002e03:	8b 45 0c             	mov    0xc(%ebp),%eax
40002e06:	8b 10                	mov    (%eax),%edx
40002e08:	8b 45 0c             	mov    0xc(%ebp),%eax
40002e0b:	c6 44 10 08 00       	movb   $0x0,0x8(%eax,%edx,1)
		cputs(b->buf);
40002e10:	8b 45 0c             	mov    0xc(%ebp),%eax
40002e13:	83 c0 08             	add    $0x8,%eax
40002e16:	89 04 24             	mov    %eax,(%esp)
40002e19:	e8 de 0b 00 00       	call   400039fc <cputs>
		b->idx = 0;
40002e1e:	8b 45 0c             	mov    0xc(%ebp),%eax
40002e21:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	}
	b->cnt++;
40002e27:	8b 45 0c             	mov    0xc(%ebp),%eax
40002e2a:	8b 40 04             	mov    0x4(%eax),%eax
40002e2d:	8d 50 01             	lea    0x1(%eax),%edx
40002e30:	8b 45 0c             	mov    0xc(%ebp),%eax
40002e33:	89 50 04             	mov    %edx,0x4(%eax)
}
40002e36:	c9                   	leave  
40002e37:	c3                   	ret    

40002e38 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
40002e38:	55                   	push   %ebp
40002e39:	89 e5                	mov    %esp,%ebp
40002e3b:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
40002e41:	c7 85 f8 fe ff ff 00 	movl   $0x0,0xfffffef8(%ebp)
40002e48:	00 00 00 
	b.cnt = 0;
40002e4b:	c7 85 fc fe ff ff 00 	movl   $0x0,0xfffffefc(%ebp)
40002e52:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
40002e55:	ba d8 2d 00 40       	mov    $0x40002dd8,%edx
40002e5a:	8b 45 0c             	mov    0xc(%ebp),%eax
40002e5d:	89 44 24 0c          	mov    %eax,0xc(%esp)
40002e61:	8b 45 08             	mov    0x8(%ebp),%eax
40002e64:	89 44 24 08          	mov    %eax,0x8(%esp)
40002e68:	8d 85 f8 fe ff ff    	lea    0xfffffef8(%ebp),%eax
40002e6e:	89 44 24 04          	mov    %eax,0x4(%esp)
40002e72:	89 14 24             	mov    %edx,(%esp)
40002e75:	e8 b4 03 00 00       	call   4000322e <vprintfmt>

	b.buf[b.idx] = 0;
40002e7a:	8b 85 f8 fe ff ff    	mov    0xfffffef8(%ebp),%eax
40002e80:	c6 84 05 00 ff ff ff 	movb   $0x0,0xffffff00(%ebp,%eax,1)
40002e87:	00 
	cputs(b.buf);
40002e88:	8d 85 f8 fe ff ff    	lea    0xfffffef8(%ebp),%eax
40002e8e:	83 c0 08             	add    $0x8,%eax
40002e91:	89 04 24             	mov    %eax,(%esp)
40002e94:	e8 63 0b 00 00       	call   400039fc <cputs>

	return b.cnt;
40002e99:	8b 85 fc fe ff ff    	mov    0xfffffefc(%ebp),%eax
}
40002e9f:	c9                   	leave  
40002ea0:	c3                   	ret    

40002ea1 <cprintf>:

int
cprintf(const char *fmt, ...)
{
40002ea1:	55                   	push   %ebp
40002ea2:	89 e5                	mov    %esp,%ebp
40002ea4:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
40002ea7:	8d 45 08             	lea    0x8(%ebp),%eax
40002eaa:	83 c0 04             	add    $0x4,%eax
40002ead:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
	cnt = vcprintf(fmt, ap);
40002eb0:	8b 55 08             	mov    0x8(%ebp),%edx
40002eb3:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
40002eb6:	89 44 24 04          	mov    %eax,0x4(%esp)
40002eba:	89 14 24             	mov    %edx,(%esp)
40002ebd:	e8 76 ff ff ff       	call   40002e38 <vcprintf>
40002ec2:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	va_end(ap);

	return cnt;
40002ec5:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
}
40002ec8:	c9                   	leave  
40002ec9:	c3                   	ret    
40002eca:	90                   	nop    
40002ecb:	90                   	nop    

40002ecc <getuint>:
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static uintmax_t
getuint(printstate *st, va_list *ap)
{
40002ecc:	55                   	push   %ebp
40002ecd:	89 e5                	mov    %esp,%ebp
40002ecf:	83 ec 08             	sub    $0x8,%esp
	if (st->flags & F_LL)
40002ed2:	8b 45 08             	mov    0x8(%ebp),%eax
40002ed5:	8b 40 18             	mov    0x18(%eax),%eax
40002ed8:	83 e0 02             	and    $0x2,%eax
40002edb:	85 c0                	test   %eax,%eax
40002edd:	74 22                	je     40002f01 <getuint+0x35>
		return va_arg(*ap, unsigned long long);
40002edf:	8b 45 0c             	mov    0xc(%ebp),%eax
40002ee2:	8b 00                	mov    (%eax),%eax
40002ee4:	8d 50 08             	lea    0x8(%eax),%edx
40002ee7:	8b 45 0c             	mov    0xc(%ebp),%eax
40002eea:	89 10                	mov    %edx,(%eax)
40002eec:	8b 45 0c             	mov    0xc(%ebp),%eax
40002eef:	8b 00                	mov    (%eax),%eax
40002ef1:	83 e8 08             	sub    $0x8,%eax
40002ef4:	8b 10                	mov    (%eax),%edx
40002ef6:	8b 48 04             	mov    0x4(%eax),%ecx
40002ef9:	89 55 f8             	mov    %edx,0xfffffff8(%ebp)
40002efc:	89 4d fc             	mov    %ecx,0xfffffffc(%ebp)
40002eff:	eb 51                	jmp    40002f52 <getuint+0x86>
	else if (st->flags & F_L)
40002f01:	8b 45 08             	mov    0x8(%ebp),%eax
40002f04:	8b 40 18             	mov    0x18(%eax),%eax
40002f07:	83 e0 01             	and    $0x1,%eax
40002f0a:	84 c0                	test   %al,%al
40002f0c:	74 23                	je     40002f31 <getuint+0x65>
		return va_arg(*ap, unsigned long);
40002f0e:	8b 45 0c             	mov    0xc(%ebp),%eax
40002f11:	8b 00                	mov    (%eax),%eax
40002f13:	8d 50 04             	lea    0x4(%eax),%edx
40002f16:	8b 45 0c             	mov    0xc(%ebp),%eax
40002f19:	89 10                	mov    %edx,(%eax)
40002f1b:	8b 45 0c             	mov    0xc(%ebp),%eax
40002f1e:	8b 00                	mov    (%eax),%eax
40002f20:	83 e8 04             	sub    $0x4,%eax
40002f23:	8b 00                	mov    (%eax),%eax
40002f25:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
40002f28:	c7 45 fc 00 00 00 00 	movl   $0x0,0xfffffffc(%ebp)
40002f2f:	eb 21                	jmp    40002f52 <getuint+0x86>
	else
		return va_arg(*ap, unsigned int);
40002f31:	8b 45 0c             	mov    0xc(%ebp),%eax
40002f34:	8b 00                	mov    (%eax),%eax
40002f36:	8d 50 04             	lea    0x4(%eax),%edx
40002f39:	8b 45 0c             	mov    0xc(%ebp),%eax
40002f3c:	89 10                	mov    %edx,(%eax)
40002f3e:	8b 45 0c             	mov    0xc(%ebp),%eax
40002f41:	8b 00                	mov    (%eax),%eax
40002f43:	83 e8 04             	sub    $0x4,%eax
40002f46:	8b 00                	mov    (%eax),%eax
40002f48:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
40002f4b:	c7 45 fc 00 00 00 00 	movl   $0x0,0xfffffffc(%ebp)
40002f52:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
40002f55:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
}
40002f58:	c9                   	leave  
40002f59:	c3                   	ret    

40002f5a <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static intmax_t
getint(printstate *st, va_list *ap)
{
40002f5a:	55                   	push   %ebp
40002f5b:	89 e5                	mov    %esp,%ebp
40002f5d:	83 ec 08             	sub    $0x8,%esp
	if (st->flags & F_LL)
40002f60:	8b 45 08             	mov    0x8(%ebp),%eax
40002f63:	8b 40 18             	mov    0x18(%eax),%eax
40002f66:	83 e0 02             	and    $0x2,%eax
40002f69:	85 c0                	test   %eax,%eax
40002f6b:	74 22                	je     40002f8f <getint+0x35>
		return va_arg(*ap, long long);
40002f6d:	8b 45 0c             	mov    0xc(%ebp),%eax
40002f70:	8b 00                	mov    (%eax),%eax
40002f72:	8d 50 08             	lea    0x8(%eax),%edx
40002f75:	8b 45 0c             	mov    0xc(%ebp),%eax
40002f78:	89 10                	mov    %edx,(%eax)
40002f7a:	8b 45 0c             	mov    0xc(%ebp),%eax
40002f7d:	8b 00                	mov    (%eax),%eax
40002f7f:	83 e8 08             	sub    $0x8,%eax
40002f82:	8b 10                	mov    (%eax),%edx
40002f84:	8b 48 04             	mov    0x4(%eax),%ecx
40002f87:	89 55 f8             	mov    %edx,0xfffffff8(%ebp)
40002f8a:	89 4d fc             	mov    %ecx,0xfffffffc(%ebp)
40002f8d:	eb 53                	jmp    40002fe2 <getint+0x88>
	else if (st->flags & F_L)
40002f8f:	8b 45 08             	mov    0x8(%ebp),%eax
40002f92:	8b 40 18             	mov    0x18(%eax),%eax
40002f95:	83 e0 01             	and    $0x1,%eax
40002f98:	84 c0                	test   %al,%al
40002f9a:	74 24                	je     40002fc0 <getint+0x66>
		return va_arg(*ap, long);
40002f9c:	8b 45 0c             	mov    0xc(%ebp),%eax
40002f9f:	8b 00                	mov    (%eax),%eax
40002fa1:	8d 50 04             	lea    0x4(%eax),%edx
40002fa4:	8b 45 0c             	mov    0xc(%ebp),%eax
40002fa7:	89 10                	mov    %edx,(%eax)
40002fa9:	8b 45 0c             	mov    0xc(%ebp),%eax
40002fac:	8b 00                	mov    (%eax),%eax
40002fae:	83 e8 04             	sub    $0x4,%eax
40002fb1:	8b 00                	mov    (%eax),%eax
40002fb3:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
40002fb6:	89 c1                	mov    %eax,%ecx
40002fb8:	c1 f9 1f             	sar    $0x1f,%ecx
40002fbb:	89 4d fc             	mov    %ecx,0xfffffffc(%ebp)
40002fbe:	eb 22                	jmp    40002fe2 <getint+0x88>
	else
		return va_arg(*ap, int);
40002fc0:	8b 45 0c             	mov    0xc(%ebp),%eax
40002fc3:	8b 00                	mov    (%eax),%eax
40002fc5:	8d 50 04             	lea    0x4(%eax),%edx
40002fc8:	8b 45 0c             	mov    0xc(%ebp),%eax
40002fcb:	89 10                	mov    %edx,(%eax)
40002fcd:	8b 45 0c             	mov    0xc(%ebp),%eax
40002fd0:	8b 00                	mov    (%eax),%eax
40002fd2:	83 e8 04             	sub    $0x4,%eax
40002fd5:	8b 00                	mov    (%eax),%eax
40002fd7:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
40002fda:	89 c2                	mov    %eax,%edx
40002fdc:	c1 fa 1f             	sar    $0x1f,%edx
40002fdf:	89 55 fc             	mov    %edx,0xfffffffc(%ebp)
40002fe2:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
40002fe5:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
}
40002fe8:	c9                   	leave  
40002fe9:	c3                   	ret    

40002fea <putpad>:

// Print padding characters, and an optional sign before a number.
static void
putpad(printstate *st)
{
40002fea:	55                   	push   %ebp
40002feb:	89 e5                	mov    %esp,%ebp
40002fed:	83 ec 08             	sub    $0x8,%esp
	while (--st->width >= 0)
40002ff0:	eb 1a                	jmp    4000300c <putpad+0x22>
		st->putch(st->padc, st->putdat);
40002ff2:	8b 45 08             	mov    0x8(%ebp),%eax
40002ff5:	8b 08                	mov    (%eax),%ecx
40002ff7:	8b 45 08             	mov    0x8(%ebp),%eax
40002ffa:	8b 50 04             	mov    0x4(%eax),%edx
40002ffd:	8b 45 08             	mov    0x8(%ebp),%eax
40003000:	8b 40 08             	mov    0x8(%eax),%eax
40003003:	89 54 24 04          	mov    %edx,0x4(%esp)
40003007:	89 04 24             	mov    %eax,(%esp)
4000300a:	ff d1                	call   *%ecx
4000300c:	8b 45 08             	mov    0x8(%ebp),%eax
4000300f:	8b 40 0c             	mov    0xc(%eax),%eax
40003012:	8d 50 ff             	lea    0xffffffff(%eax),%edx
40003015:	8b 45 08             	mov    0x8(%ebp),%eax
40003018:	89 50 0c             	mov    %edx,0xc(%eax)
4000301b:	8b 45 08             	mov    0x8(%ebp),%eax
4000301e:	8b 40 0c             	mov    0xc(%eax),%eax
40003021:	85 c0                	test   %eax,%eax
40003023:	79 cd                	jns    40002ff2 <putpad+0x8>
}
40003025:	c9                   	leave  
40003026:	c3                   	ret    

40003027 <putstr>:

// Print a string with a specified maximum length (-1=unlimited),
// with any appropriate left or right field padding.
static void
putstr(printstate *st, const char *str, int maxlen)
{
40003027:	55                   	push   %ebp
40003028:	89 e5                	mov    %esp,%ebp
4000302a:	53                   	push   %ebx
4000302b:	83 ec 24             	sub    $0x24,%esp
	const char *lim;		// find where the string actually ends
	if (maxlen < 0)
4000302e:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
40003032:	79 18                	jns    4000304c <putstr+0x25>
		lim = strchr(str, 0);	// find the terminating null
40003034:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000303b:	00 
4000303c:	8b 45 0c             	mov    0xc(%ebp),%eax
4000303f:	89 04 24             	mov    %eax,(%esp)
40003042:	e8 22 07 00 00       	call   40003769 <strchr>
40003047:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
4000304a:	eb 2c                	jmp    40003078 <putstr+0x51>
	else if ((lim = memchr(str, 0, maxlen)) == NULL)
4000304c:	8b 45 10             	mov    0x10(%ebp),%eax
4000304f:	89 44 24 08          	mov    %eax,0x8(%esp)
40003053:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000305a:	00 
4000305b:	8b 45 0c             	mov    0xc(%ebp),%eax
4000305e:	89 04 24             	mov    %eax,(%esp)
40003061:	e8 00 09 00 00       	call   40003966 <memchr>
40003066:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
40003069:	83 7d f4 00          	cmpl   $0x0,0xfffffff4(%ebp)
4000306d:	75 09                	jne    40003078 <putstr+0x51>
		lim = str + maxlen;
4000306f:	8b 45 10             	mov    0x10(%ebp),%eax
40003072:	03 45 0c             	add    0xc(%ebp),%eax
40003075:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	st->width -= (lim-str);		// deduct string length from field width
40003078:	8b 45 08             	mov    0x8(%ebp),%eax
4000307b:	8b 48 0c             	mov    0xc(%eax),%ecx
4000307e:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
40003081:	8b 45 0c             	mov    0xc(%ebp),%eax
40003084:	89 d3                	mov    %edx,%ebx
40003086:	29 c3                	sub    %eax,%ebx
40003088:	89 d8                	mov    %ebx,%eax
4000308a:	89 ca                	mov    %ecx,%edx
4000308c:	29 c2                	sub    %eax,%edx
4000308e:	8b 45 08             	mov    0x8(%ebp),%eax
40003091:	89 50 0c             	mov    %edx,0xc(%eax)

	if (!(st->flags & F_RPAD))	// print left-side padding
40003094:	8b 45 08             	mov    0x8(%ebp),%eax
40003097:	8b 40 18             	mov    0x18(%eax),%eax
4000309a:	83 e0 10             	and    $0x10,%eax
4000309d:	85 c0                	test   %eax,%eax
4000309f:	75 32                	jne    400030d3 <putstr+0xac>
		putpad(st);		// (also leaves st->width == 0)
400030a1:	8b 45 08             	mov    0x8(%ebp),%eax
400030a4:	89 04 24             	mov    %eax,(%esp)
400030a7:	e8 3e ff ff ff       	call   40002fea <putpad>
	while (str < lim) {
400030ac:	eb 25                	jmp    400030d3 <putstr+0xac>
		char ch = *str++;
400030ae:	8b 45 0c             	mov    0xc(%ebp),%eax
400030b1:	0f b6 00             	movzbl (%eax),%eax
400030b4:	88 45 fb             	mov    %al,0xfffffffb(%ebp)
400030b7:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
			st->putch(ch, st->putdat);
400030bb:	8b 45 08             	mov    0x8(%ebp),%eax
400030be:	8b 08                	mov    (%eax),%ecx
400030c0:	8b 45 08             	mov    0x8(%ebp),%eax
400030c3:	8b 40 04             	mov    0x4(%eax),%eax
400030c6:	0f be 55 fb          	movsbl 0xfffffffb(%ebp),%edx
400030ca:	89 44 24 04          	mov    %eax,0x4(%esp)
400030ce:	89 14 24             	mov    %edx,(%esp)
400030d1:	ff d1                	call   *%ecx
400030d3:	8b 45 0c             	mov    0xc(%ebp),%eax
400030d6:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
400030d9:	72 d3                	jb     400030ae <putstr+0x87>
	}
	putpad(st);			// print right-side padding
400030db:	8b 45 08             	mov    0x8(%ebp),%eax
400030de:	89 04 24             	mov    %eax,(%esp)
400030e1:	e8 04 ff ff ff       	call   40002fea <putpad>
}
400030e6:	83 c4 24             	add    $0x24,%esp
400030e9:	5b                   	pop    %ebx
400030ea:	5d                   	pop    %ebp
400030eb:	c3                   	ret    

400030ec <genint>:

// Generate a number (base <= 16) in reverse order into a string buffer.
static char *
genint(printstate *st, char *p, uintmax_t num)
{
400030ec:	55                   	push   %ebp
400030ed:	89 e5                	mov    %esp,%ebp
400030ef:	53                   	push   %ebx
400030f0:	83 ec 24             	sub    $0x24,%esp
400030f3:	8b 45 10             	mov    0x10(%ebp),%eax
400030f6:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
400030f9:	8b 45 14             	mov    0x14(%ebp),%eax
400030fc:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= st->base)
400030ff:	8b 45 08             	mov    0x8(%ebp),%eax
40003102:	8b 40 1c             	mov    0x1c(%eax),%eax
40003105:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
40003108:	89 c2                	mov    %eax,%edx
4000310a:	c1 fa 1f             	sar    $0x1f,%edx
4000310d:	89 55 ec             	mov    %edx,0xffffffec(%ebp)
40003110:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
40003113:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
40003116:	77 54                	ja     4000316c <genint+0x80>
40003118:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
4000311b:	3b 55 f4             	cmp    0xfffffff4(%ebp),%edx
4000311e:	72 08                	jb     40003128 <genint+0x3c>
40003120:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
40003123:	3b 45 f0             	cmp    0xfffffff0(%ebp),%eax
40003126:	77 44                	ja     4000316c <genint+0x80>
		p = genint(st, p, num / st->base);	// output higher digits
40003128:	8b 45 08             	mov    0x8(%ebp),%eax
4000312b:	8b 40 1c             	mov    0x1c(%eax),%eax
4000312e:	89 c2                	mov    %eax,%edx
40003130:	c1 fa 1f             	sar    $0x1f,%edx
40003133:	89 44 24 08          	mov    %eax,0x8(%esp)
40003137:	89 54 24 0c          	mov    %edx,0xc(%esp)
4000313b:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
4000313e:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
40003141:	89 04 24             	mov    %eax,(%esp)
40003144:	89 54 24 04          	mov    %edx,0x4(%esp)
40003148:	e8 33 22 00 00       	call   40005380 <__udivdi3>
4000314d:	89 44 24 08          	mov    %eax,0x8(%esp)
40003151:	89 54 24 0c          	mov    %edx,0xc(%esp)
40003155:	8b 45 0c             	mov    0xc(%ebp),%eax
40003158:	89 44 24 04          	mov    %eax,0x4(%esp)
4000315c:	8b 45 08             	mov    0x8(%ebp),%eax
4000315f:	89 04 24             	mov    %eax,(%esp)
40003162:	e8 85 ff ff ff       	call   400030ec <genint>
40003167:	89 45 0c             	mov    %eax,0xc(%ebp)
4000316a:	eb 1b                	jmp    40003187 <genint+0x9b>
	else if (st->signc >= 0)
4000316c:	8b 45 08             	mov    0x8(%ebp),%eax
4000316f:	8b 40 14             	mov    0x14(%eax),%eax
40003172:	85 c0                	test   %eax,%eax
40003174:	78 11                	js     40003187 <genint+0x9b>
		*p++ = st->signc;			// output leading sign
40003176:	8b 45 08             	mov    0x8(%ebp),%eax
40003179:	8b 40 14             	mov    0x14(%eax),%eax
4000317c:	89 c2                	mov    %eax,%edx
4000317e:	8b 45 0c             	mov    0xc(%ebp),%eax
40003181:	88 10                	mov    %dl,(%eax)
40003183:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
	*p++ = "0123456789abcdef"[num % st->base];	// output this digit
40003187:	8b 45 08             	mov    0x8(%ebp),%eax
4000318a:	8b 40 1c             	mov    0x1c(%eax),%eax
4000318d:	89 c2                	mov    %eax,%edx
4000318f:	c1 fa 1f             	sar    $0x1f,%edx
40003192:	8b 4d f0             	mov    0xfffffff0(%ebp),%ecx
40003195:	8b 5d f4             	mov    0xfffffff4(%ebp),%ebx
40003198:	89 44 24 08          	mov    %eax,0x8(%esp)
4000319c:	89 54 24 0c          	mov    %edx,0xc(%esp)
400031a0:	89 0c 24             	mov    %ecx,(%esp)
400031a3:	89 5c 24 04          	mov    %ebx,0x4(%esp)
400031a7:	e8 04 23 00 00       	call   400054b0 <__umoddi3>
400031ac:	05 80 5f 00 40       	add    $0x40005f80,%eax
400031b1:	0f b6 10             	movzbl (%eax),%edx
400031b4:	8b 45 0c             	mov    0xc(%ebp),%eax
400031b7:	88 10                	mov    %dl,(%eax)
400031b9:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
	return p;
400031bd:	8b 45 0c             	mov    0xc(%ebp),%eax
}
400031c0:	83 c4 24             	add    $0x24,%esp
400031c3:	5b                   	pop    %ebx
400031c4:	5d                   	pop    %ebp
400031c5:	c3                   	ret    

400031c6 <putint>:

// Print an integer with any appropriate field padding.
static void
putint(printstate *st, uintmax_t num, int base)
{
400031c6:	55                   	push   %ebp
400031c7:	89 e5                	mov    %esp,%ebp
400031c9:	83 ec 48             	sub    $0x48,%esp
400031cc:	8b 45 0c             	mov    0xc(%ebp),%eax
400031cf:	89 45 c8             	mov    %eax,0xffffffc8(%ebp)
400031d2:	8b 45 10             	mov    0x10(%ebp),%eax
400031d5:	89 45 cc             	mov    %eax,0xffffffcc(%ebp)
	char buf[30], *p = buf;		// big enough for any 64-bit int in octal
400031d8:	8d 45 de             	lea    0xffffffde(%ebp),%eax
400031db:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	st->base = base;		// select base for genint
400031de:	8b 55 08             	mov    0x8(%ebp),%edx
400031e1:	8b 45 14             	mov    0x14(%ebp),%eax
400031e4:	89 42 1c             	mov    %eax,0x1c(%edx)
	p = genint(st, p, num);		// output to the string buffer
400031e7:	8b 45 c8             	mov    0xffffffc8(%ebp),%eax
400031ea:	8b 55 cc             	mov    0xffffffcc(%ebp),%edx
400031ed:	89 44 24 08          	mov    %eax,0x8(%esp)
400031f1:	89 54 24 0c          	mov    %edx,0xc(%esp)
400031f5:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
400031f8:	89 44 24 04          	mov    %eax,0x4(%esp)
400031fc:	8b 45 08             	mov    0x8(%ebp),%eax
400031ff:	89 04 24             	mov    %eax,(%esp)
40003202:	e8 e5 fe ff ff       	call   400030ec <genint>
40003207:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	putstr(st, buf, p-buf);		// print it with left/right padding
4000320a:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
4000320d:	8d 45 de             	lea    0xffffffde(%ebp),%eax
40003210:	89 d1                	mov    %edx,%ecx
40003212:	29 c1                	sub    %eax,%ecx
40003214:	89 c8                	mov    %ecx,%eax
40003216:	89 44 24 08          	mov    %eax,0x8(%esp)
4000321a:	8d 45 de             	lea    0xffffffde(%ebp),%eax
4000321d:	89 44 24 04          	mov    %eax,0x4(%esp)
40003221:	8b 45 08             	mov    0x8(%ebp),%eax
40003224:	89 04 24             	mov    %eax,(%esp)
40003227:	e8 fb fd ff ff       	call   40003027 <putstr>
}
4000322c:	c9                   	leave  
4000322d:	c3                   	ret    

4000322e <vprintfmt>:
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
4000322e:	55                   	push   %ebp
4000322f:	89 e5                	mov    %esp,%ebp
40003231:	57                   	push   %edi
40003232:	83 ec 54             	sub    $0x54,%esp
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
40003235:	8d 7d c8             	lea    0xffffffc8(%ebp),%edi
40003238:	fc                   	cld    
40003239:	ba 00 00 00 00       	mov    $0x0,%edx
4000323e:	b8 08 00 00 00       	mov    $0x8,%eax
40003243:	89 c1                	mov    %eax,%ecx
40003245:	89 d0                	mov    %edx,%eax
40003247:	f3 ab                	rep stos %eax,%es:(%edi)
40003249:	8b 45 08             	mov    0x8(%ebp),%eax
4000324c:	89 45 c8             	mov    %eax,0xffffffc8(%ebp)
4000324f:	8b 45 0c             	mov    0xc(%ebp),%eax
40003252:	89 45 cc             	mov    %eax,0xffffffcc(%ebp)
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
40003255:	eb 1c                	jmp    40003273 <vprintfmt+0x45>
			if (ch == '\0')
40003257:	83 7d c4 00          	cmpl   $0x0,0xffffffc4(%ebp)
4000325b:	0f 84 73 03 00 00    	je     400035d4 <vprintfmt+0x3a6>
				return;
			putch(ch, putdat);
40003261:	8b 45 0c             	mov    0xc(%ebp),%eax
40003264:	89 44 24 04          	mov    %eax,0x4(%esp)
40003268:	8b 55 c4             	mov    0xffffffc4(%ebp),%edx
4000326b:	89 14 24             	mov    %edx,(%esp)
4000326e:	8b 45 08             	mov    0x8(%ebp),%eax
40003271:	ff d0                	call   *%eax
40003273:	8b 45 10             	mov    0x10(%ebp),%eax
40003276:	0f b6 00             	movzbl (%eax),%eax
40003279:	0f b6 c0             	movzbl %al,%eax
4000327c:	89 45 c4             	mov    %eax,0xffffffc4(%ebp)
4000327f:	83 7d c4 25          	cmpl   $0x25,0xffffffc4(%ebp)
40003283:	0f 95 c0             	setne  %al
40003286:	83 45 10 01          	addl   $0x1,0x10(%ebp)
4000328a:	84 c0                	test   %al,%al
4000328c:	75 c9                	jne    40003257 <vprintfmt+0x29>
		}

		// Process a %-escape sequence
		st.padc = ' ';
4000328e:	c7 45 d0 20 00 00 00 	movl   $0x20,0xffffffd0(%ebp)
		st.width = -1;
40003295:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,0xffffffd4(%ebp)
		st.prec = -1;
4000329c:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,0xffffffd8(%ebp)
		st.signc = -1;
400032a3:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,0xffffffdc(%ebp)
		st.flags = 0;
400032aa:	c7 45 e0 00 00 00 00 	movl   $0x0,0xffffffe0(%ebp)
		st.base = 10;
400032b1:	c7 45 e4 0a 00 00 00 	movl   $0xa,0xffffffe4(%ebp)
400032b8:	eb 00                	jmp    400032ba <vprintfmt+0x8c>
		uintmax_t num;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
400032ba:	8b 45 10             	mov    0x10(%ebp),%eax
400032bd:	0f b6 00             	movzbl (%eax),%eax
400032c0:	0f b6 c0             	movzbl %al,%eax
400032c3:	89 45 c4             	mov    %eax,0xffffffc4(%ebp)
400032c6:	8b 45 c4             	mov    0xffffffc4(%ebp),%eax
400032c9:	83 45 10 01          	addl   $0x1,0x10(%ebp)
400032cd:	83 e8 20             	sub    $0x20,%eax
400032d0:	89 45 b8             	mov    %eax,0xffffffb8(%ebp)
400032d3:	83 7d b8 58          	cmpl   $0x58,0xffffffb8(%ebp)
400032d7:	0f 87 c8 02 00 00    	ja     400035a5 <vprintfmt+0x377>
400032dd:	8b 55 b8             	mov    0xffffffb8(%ebp),%edx
400032e0:	8b 04 95 98 5f 00 40 	mov    0x40005f98(,%edx,4),%eax
400032e7:	ff e0                	jmp    *%eax

		// modifier flags
		case '-': // pad on the right instead of the left
			st.flags |= F_RPAD;
400032e9:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
400032ec:	83 c8 10             	or     $0x10,%eax
400032ef:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)
			goto reswitch;
400032f2:	eb c6                	jmp    400032ba <vprintfmt+0x8c>

		case '+': // prefix positive numeric values with a '+' sign
			st.signc = '+';
400032f4:	c7 45 dc 2b 00 00 00 	movl   $0x2b,0xffffffdc(%ebp)
			goto reswitch;
400032fb:	eb bd                	jmp    400032ba <vprintfmt+0x8c>

		case ' ': // prefix signless numeric values with a space
			if (st.signc < 0)	// (but only if no '+' is specified)
400032fd:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
40003300:	85 c0                	test   %eax,%eax
40003302:	79 b6                	jns    400032ba <vprintfmt+0x8c>
				st.signc = ' ';
40003304:	c7 45 dc 20 00 00 00 	movl   $0x20,0xffffffdc(%ebp)
			goto reswitch;
4000330b:	eb ad                	jmp    400032ba <vprintfmt+0x8c>

		// width or precision field
		case '0':
			if (!(st.flags & F_DOT))
4000330d:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
40003310:	83 e0 08             	and    $0x8,%eax
40003313:	85 c0                	test   %eax,%eax
40003315:	75 07                	jne    4000331e <vprintfmt+0xf0>
				st.padc = '0'; // pad with 0's instead of spaces
40003317:	c7 45 d0 30 00 00 00 	movl   $0x30,0xffffffd0(%ebp)
		case '1': case '2': case '3': case '4':
		case '5': case '6': case '7': case '8': case '9':
			for (st.prec = 0; ; ++fmt) {
4000331e:	c7 45 d8 00 00 00 00 	movl   $0x0,0xffffffd8(%ebp)
				st.prec = st.prec * 10 + ch - '0';
40003325:	8b 55 d8             	mov    0xffffffd8(%ebp),%edx
40003328:	89 d0                	mov    %edx,%eax
4000332a:	c1 e0 02             	shl    $0x2,%eax
4000332d:	01 d0                	add    %edx,%eax
4000332f:	01 c0                	add    %eax,%eax
40003331:	03 45 c4             	add    0xffffffc4(%ebp),%eax
40003334:	83 e8 30             	sub    $0x30,%eax
40003337:	89 45 d8             	mov    %eax,0xffffffd8(%ebp)
				ch = *fmt;
4000333a:	8b 45 10             	mov    0x10(%ebp),%eax
4000333d:	0f b6 00             	movzbl (%eax),%eax
40003340:	0f be c0             	movsbl %al,%eax
40003343:	89 45 c4             	mov    %eax,0xffffffc4(%ebp)
				if (ch < '0' || ch > '9')
40003346:	83 7d c4 2f          	cmpl   $0x2f,0xffffffc4(%ebp)
4000334a:	7e 20                	jle    4000336c <vprintfmt+0x13e>
4000334c:	83 7d c4 39          	cmpl   $0x39,0xffffffc4(%ebp)
40003350:	7f 1a                	jg     4000336c <vprintfmt+0x13e>
40003352:	83 45 10 01          	addl   $0x1,0x10(%ebp)
					break;
			}
40003356:	eb cd                	jmp    40003325 <vprintfmt+0xf7>
			goto gotprec;

		case '*':
			st.prec = va_arg(ap, int);
40003358:	8b 45 14             	mov    0x14(%ebp),%eax
4000335b:	83 c0 04             	add    $0x4,%eax
4000335e:	89 45 14             	mov    %eax,0x14(%ebp)
40003361:	8b 45 14             	mov    0x14(%ebp),%eax
40003364:	83 e8 04             	sub    $0x4,%eax
40003367:	8b 00                	mov    (%eax),%eax
40003369:	89 45 d8             	mov    %eax,0xffffffd8(%ebp)
		gotprec:
			if (!(st.flags & F_DOT)) {	// haven't seen a '.' yet?
4000336c:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
4000336f:	83 e0 08             	and    $0x8,%eax
40003372:	85 c0                	test   %eax,%eax
40003374:	0f 85 40 ff ff ff    	jne    400032ba <vprintfmt+0x8c>
				st.width = st.prec;	// then it's a field width
4000337a:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
4000337d:	89 45 d4             	mov    %eax,0xffffffd4(%ebp)
				st.prec = -1;
40003380:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,0xffffffd8(%ebp)
			}
			goto reswitch;
40003387:	e9 2e ff ff ff       	jmp    400032ba <vprintfmt+0x8c>

		case '.':
			st.flags |= F_DOT;
4000338c:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
4000338f:	83 c8 08             	or     $0x8,%eax
40003392:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)
			goto reswitch;
40003395:	e9 20 ff ff ff       	jmp    400032ba <vprintfmt+0x8c>

		case '#':
			st.flags |= F_ALT;
4000339a:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
4000339d:	83 c8 04             	or     $0x4,%eax
400033a0:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)
			goto reswitch;
400033a3:	e9 12 ff ff ff       	jmp    400032ba <vprintfmt+0x8c>

		// long flag (doubled for long long)
		case 'l':
			st.flags |= (st.flags & F_L) ? F_LL : F_L;
400033a8:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
400033ab:	89 45 bc             	mov    %eax,0xffffffbc(%ebp)
400033ae:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
400033b1:	83 e0 01             	and    $0x1,%eax
400033b4:	84 c0                	test   %al,%al
400033b6:	74 09                	je     400033c1 <vprintfmt+0x193>
400033b8:	c7 45 c0 02 00 00 00 	movl   $0x2,0xffffffc0(%ebp)
400033bf:	eb 07                	jmp    400033c8 <vprintfmt+0x19a>
400033c1:	c7 45 c0 01 00 00 00 	movl   $0x1,0xffffffc0(%ebp)
400033c8:	8b 45 bc             	mov    0xffffffbc(%ebp),%eax
400033cb:	0b 45 c0             	or     0xffffffc0(%ebp),%eax
400033ce:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)
			goto reswitch;
400033d1:	e9 e4 fe ff ff       	jmp    400032ba <vprintfmt+0x8c>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
400033d6:	8b 45 14             	mov    0x14(%ebp),%eax
400033d9:	83 c0 04             	add    $0x4,%eax
400033dc:	89 45 14             	mov    %eax,0x14(%ebp)
400033df:	8b 45 14             	mov    0x14(%ebp),%eax
400033e2:	83 e8 04             	sub    $0x4,%eax
400033e5:	8b 10                	mov    (%eax),%edx
400033e7:	8b 45 0c             	mov    0xc(%ebp),%eax
400033ea:	89 44 24 04          	mov    %eax,0x4(%esp)
400033ee:	89 14 24             	mov    %edx,(%esp)
400033f1:	8b 45 08             	mov    0x8(%ebp),%eax
400033f4:	ff d0                	call   *%eax
			break;
400033f6:	e9 78 fe ff ff       	jmp    40003273 <vprintfmt+0x45>

		// string
		case 's': {
			const char *s;
			if ((s = va_arg(ap, char *)) == NULL)
400033fb:	8b 45 14             	mov    0x14(%ebp),%eax
400033fe:	83 c0 04             	add    $0x4,%eax
40003401:	89 45 14             	mov    %eax,0x14(%ebp)
40003404:	8b 45 14             	mov    0x14(%ebp),%eax
40003407:	83 e8 04             	sub    $0x4,%eax
4000340a:	8b 00                	mov    (%eax),%eax
4000340c:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
4000340f:	83 7d f4 00          	cmpl   $0x0,0xfffffff4(%ebp)
40003413:	75 07                	jne    4000341c <vprintfmt+0x1ee>
				s = "(null)";
40003415:	c7 45 f4 91 5f 00 40 	movl   $0x40005f91,0xfffffff4(%ebp)
			putstr(&st, s, st.prec);
4000341c:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
4000341f:	89 44 24 08          	mov    %eax,0x8(%esp)
40003423:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
40003426:	89 44 24 04          	mov    %eax,0x4(%esp)
4000342a:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
4000342d:	89 04 24             	mov    %eax,(%esp)
40003430:	e8 f2 fb ff ff       	call   40003027 <putstr>
			break;
40003435:	e9 39 fe ff ff       	jmp    40003273 <vprintfmt+0x45>
		    }

		// (signed) decimal
		case 'd':
			num = getint(&st, &ap);
4000343a:	8d 45 14             	lea    0x14(%ebp),%eax
4000343d:	89 44 24 04          	mov    %eax,0x4(%esp)
40003441:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
40003444:	89 04 24             	mov    %eax,(%esp)
40003447:	e8 0e fb ff ff       	call   40002f5a <getint>
4000344c:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
4000344f:	89 55 ec             	mov    %edx,0xffffffec(%ebp)
			if ((intmax_t) num < 0) {
40003452:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
40003455:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
40003458:	85 d2                	test   %edx,%edx
4000345a:	79 1a                	jns    40003476 <vprintfmt+0x248>
				num = -(intmax_t) num;
4000345c:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
4000345f:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
40003462:	f7 d8                	neg    %eax
40003464:	83 d2 00             	adc    $0x0,%edx
40003467:	f7 da                	neg    %edx
40003469:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
4000346c:	89 55 ec             	mov    %edx,0xffffffec(%ebp)
				st.signc = '-';
4000346f:	c7 45 dc 2d 00 00 00 	movl   $0x2d,0xffffffdc(%ebp)
			}
			putint(&st, num, 10);
40003476:	c7 44 24 0c 0a 00 00 	movl   $0xa,0xc(%esp)
4000347d:	00 
4000347e:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
40003481:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
40003484:	89 44 24 04          	mov    %eax,0x4(%esp)
40003488:	89 54 24 08          	mov    %edx,0x8(%esp)
4000348c:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
4000348f:	89 04 24             	mov    %eax,(%esp)
40003492:	e8 2f fd ff ff       	call   400031c6 <putint>
			break;
40003497:	e9 d7 fd ff ff       	jmp    40003273 <vprintfmt+0x45>

		// unsigned decimal
		case 'u':
			putint(&st, getuint(&st, &ap), 10);
4000349c:	8d 45 14             	lea    0x14(%ebp),%eax
4000349f:	89 44 24 04          	mov    %eax,0x4(%esp)
400034a3:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
400034a6:	89 04 24             	mov    %eax,(%esp)
400034a9:	e8 1e fa ff ff       	call   40002ecc <getuint>
400034ae:	c7 44 24 0c 0a 00 00 	movl   $0xa,0xc(%esp)
400034b5:	00 
400034b6:	89 44 24 04          	mov    %eax,0x4(%esp)
400034ba:	89 54 24 08          	mov    %edx,0x8(%esp)
400034be:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
400034c1:	89 04 24             	mov    %eax,(%esp)
400034c4:	e8 fd fc ff ff       	call   400031c6 <putint>
			break;
400034c9:	e9 a5 fd ff ff       	jmp    40003273 <vprintfmt+0x45>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putint(&st, getuint(&st, &ap), 8);
400034ce:	8d 45 14             	lea    0x14(%ebp),%eax
400034d1:	89 44 24 04          	mov    %eax,0x4(%esp)
400034d5:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
400034d8:	89 04 24             	mov    %eax,(%esp)
400034db:	e8 ec f9 ff ff       	call   40002ecc <getuint>
400034e0:	c7 44 24 0c 08 00 00 	movl   $0x8,0xc(%esp)
400034e7:	00 
400034e8:	89 44 24 04          	mov    %eax,0x4(%esp)
400034ec:	89 54 24 08          	mov    %edx,0x8(%esp)
400034f0:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
400034f3:	89 04 24             	mov    %eax,(%esp)
400034f6:	e8 cb fc ff ff       	call   400031c6 <putint>
			break;
400034fb:	e9 73 fd ff ff       	jmp    40003273 <vprintfmt+0x45>

		// (unsigned) hexadecimal
		case 'x':
			putint(&st, getuint(&st, &ap), 16);
40003500:	8d 45 14             	lea    0x14(%ebp),%eax
40003503:	89 44 24 04          	mov    %eax,0x4(%esp)
40003507:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
4000350a:	89 04 24             	mov    %eax,(%esp)
4000350d:	e8 ba f9 ff ff       	call   40002ecc <getuint>
40003512:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
40003519:	00 
4000351a:	89 44 24 04          	mov    %eax,0x4(%esp)
4000351e:	89 54 24 08          	mov    %edx,0x8(%esp)
40003522:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
40003525:	89 04 24             	mov    %eax,(%esp)
40003528:	e8 99 fc ff ff       	call   400031c6 <putint>
			break;
4000352d:	e9 41 fd ff ff       	jmp    40003273 <vprintfmt+0x45>

		// pointer
		case 'p':
			putch('0', putdat);
40003532:	8b 45 0c             	mov    0xc(%ebp),%eax
40003535:	89 44 24 04          	mov    %eax,0x4(%esp)
40003539:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
40003540:	8b 45 08             	mov    0x8(%ebp),%eax
40003543:	ff d0                	call   *%eax
			putch('x', putdat);
40003545:	8b 45 0c             	mov    0xc(%ebp),%eax
40003548:	89 44 24 04          	mov    %eax,0x4(%esp)
4000354c:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
40003553:	8b 45 08             	mov    0x8(%ebp),%eax
40003556:	ff d0                	call   *%eax
			putint(&st, (uintptr_t) va_arg(ap, void *), 16);
40003558:	8b 45 14             	mov    0x14(%ebp),%eax
4000355b:	83 c0 04             	add    $0x4,%eax
4000355e:	89 45 14             	mov    %eax,0x14(%ebp)
40003561:	8b 45 14             	mov    0x14(%ebp),%eax
40003564:	83 e8 04             	sub    $0x4,%eax
40003567:	8b 00                	mov    (%eax),%eax
40003569:	ba 00 00 00 00       	mov    $0x0,%edx
4000356e:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
40003575:	00 
40003576:	89 44 24 04          	mov    %eax,0x4(%esp)
4000357a:	89 54 24 08          	mov    %edx,0x8(%esp)
4000357e:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
40003581:	89 04 24             	mov    %eax,(%esp)
40003584:	e8 3d fc ff ff       	call   400031c6 <putint>
			break;
40003589:	e9 e5 fc ff ff       	jmp    40003273 <vprintfmt+0x45>
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
4000358e:	8b 45 0c             	mov    0xc(%ebp),%eax
40003591:	89 44 24 04          	mov    %eax,0x4(%esp)
40003595:	8b 55 c4             	mov    0xffffffc4(%ebp),%edx
40003598:	89 14 24             	mov    %edx,(%esp)
4000359b:	8b 45 08             	mov    0x8(%ebp),%eax
4000359e:	ff d0                	call   *%eax
			break;
400035a0:	e9 ce fc ff ff       	jmp    40003273 <vprintfmt+0x45>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
400035a5:	8b 45 0c             	mov    0xc(%ebp),%eax
400035a8:	89 44 24 04          	mov    %eax,0x4(%esp)
400035ac:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
400035b3:	8b 45 08             	mov    0x8(%ebp),%eax
400035b6:	ff d0                	call   *%eax
			for (fmt--; fmt[-1] != '%'; fmt--)
400035b8:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
400035bc:	eb 04                	jmp    400035c2 <vprintfmt+0x394>
400035be:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
400035c2:	8b 45 10             	mov    0x10(%ebp),%eax
400035c5:	83 e8 01             	sub    $0x1,%eax
400035c8:	0f b6 00             	movzbl (%eax),%eax
400035cb:	3c 25                	cmp    $0x25,%al
400035cd:	75 ef                	jne    400035be <vprintfmt+0x390>
				/* do nothing */;
			break;
		}
	}
400035cf:	e9 9f fc ff ff       	jmp    40003273 <vprintfmt+0x45>
}
400035d4:	83 c4 54             	add    $0x54,%esp
400035d7:	5f                   	pop    %edi
400035d8:	5d                   	pop    %ebp
400035d9:	c3                   	ret    
400035da:	90                   	nop    
400035db:	90                   	nop    

400035dc <strlen>:
#define ASM 1

int
strlen(const char *s)
{
400035dc:	55                   	push   %ebp
400035dd:	89 e5                	mov    %esp,%ebp
400035df:	83 ec 10             	sub    $0x10,%esp
	int n;

	for (n = 0; *s != '\0'; s++)
400035e2:	c7 45 fc 00 00 00 00 	movl   $0x0,0xfffffffc(%ebp)
400035e9:	eb 08                	jmp    400035f3 <strlen+0x17>
		n++;
400035eb:	83 45 fc 01          	addl   $0x1,0xfffffffc(%ebp)
400035ef:	83 45 08 01          	addl   $0x1,0x8(%ebp)
400035f3:	8b 45 08             	mov    0x8(%ebp),%eax
400035f6:	0f b6 00             	movzbl (%eax),%eax
400035f9:	84 c0                	test   %al,%al
400035fb:	75 ee                	jne    400035eb <strlen+0xf>
	return n;
400035fd:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
}
40003600:	c9                   	leave  
40003601:	c3                   	ret    

40003602 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
40003602:	55                   	push   %ebp
40003603:	89 e5                	mov    %esp,%ebp
40003605:	83 ec 10             	sub    $0x10,%esp
	char *ret;

	ret = dst;
40003608:	8b 45 08             	mov    0x8(%ebp),%eax
4000360b:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	while ((*dst++ = *src++) != '\0')
4000360e:	8b 45 0c             	mov    0xc(%ebp),%eax
40003611:	0f b6 10             	movzbl (%eax),%edx
40003614:	8b 45 08             	mov    0x8(%ebp),%eax
40003617:	88 10                	mov    %dl,(%eax)
40003619:	8b 45 08             	mov    0x8(%ebp),%eax
4000361c:	0f b6 00             	movzbl (%eax),%eax
4000361f:	84 c0                	test   %al,%al
40003621:	0f 95 c0             	setne  %al
40003624:	83 45 08 01          	addl   $0x1,0x8(%ebp)
40003628:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
4000362c:	84 c0                	test   %al,%al
4000362e:	75 de                	jne    4000360e <strcpy+0xc>
		/* do nothing */;
	return ret;
40003630:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
}
40003633:	c9                   	leave  
40003634:	c3                   	ret    

40003635 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size)
{
40003635:	55                   	push   %ebp
40003636:	89 e5                	mov    %esp,%ebp
40003638:	83 ec 10             	sub    $0x10,%esp
	size_t i;
	char *ret;

	ret = dst;
4000363b:	8b 45 08             	mov    0x8(%ebp),%eax
4000363e:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	for (i = 0; i < size; i++) {
40003641:	c7 45 f8 00 00 00 00 	movl   $0x0,0xfffffff8(%ebp)
40003648:	eb 21                	jmp    4000366b <strncpy+0x36>
		*dst++ = *src;
4000364a:	8b 45 0c             	mov    0xc(%ebp),%eax
4000364d:	0f b6 10             	movzbl (%eax),%edx
40003650:	8b 45 08             	mov    0x8(%ebp),%eax
40003653:	88 10                	mov    %dl,(%eax)
40003655:	83 45 08 01          	addl   $0x1,0x8(%ebp)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
40003659:	8b 45 0c             	mov    0xc(%ebp),%eax
4000365c:	0f b6 00             	movzbl (%eax),%eax
4000365f:	84 c0                	test   %al,%al
40003661:	74 04                	je     40003667 <strncpy+0x32>
			src++;
40003663:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
40003667:	83 45 f8 01          	addl   $0x1,0xfffffff8(%ebp)
4000366b:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
4000366e:	3b 45 10             	cmp    0x10(%ebp),%eax
40003671:	72 d7                	jb     4000364a <strncpy+0x15>
	}
	return ret;
40003673:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
}
40003676:	c9                   	leave  
40003677:	c3                   	ret    

40003678 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
40003678:	55                   	push   %ebp
40003679:	89 e5                	mov    %esp,%ebp
4000367b:	83 ec 10             	sub    $0x10,%esp
	char *dst_in;

	dst_in = dst;
4000367e:	8b 45 08             	mov    0x8(%ebp),%eax
40003681:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	if (size > 0) {
40003684:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
40003688:	74 2f                	je     400036b9 <strlcpy+0x41>
		while (--size > 0 && *src != '\0')
4000368a:	eb 13                	jmp    4000369f <strlcpy+0x27>
			*dst++ = *src++;
4000368c:	8b 45 0c             	mov    0xc(%ebp),%eax
4000368f:	0f b6 10             	movzbl (%eax),%edx
40003692:	8b 45 08             	mov    0x8(%ebp),%eax
40003695:	88 10                	mov    %dl,(%eax)
40003697:	83 45 08 01          	addl   $0x1,0x8(%ebp)
4000369b:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
4000369f:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
400036a3:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
400036a7:	74 0a                	je     400036b3 <strlcpy+0x3b>
400036a9:	8b 45 0c             	mov    0xc(%ebp),%eax
400036ac:	0f b6 00             	movzbl (%eax),%eax
400036af:	84 c0                	test   %al,%al
400036b1:	75 d9                	jne    4000368c <strlcpy+0x14>
		*dst = '\0';
400036b3:	8b 45 08             	mov    0x8(%ebp),%eax
400036b6:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
400036b9:	8b 55 08             	mov    0x8(%ebp),%edx
400036bc:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
400036bf:	89 d1                	mov    %edx,%ecx
400036c1:	29 c1                	sub    %eax,%ecx
400036c3:	89 c8                	mov    %ecx,%eax
}
400036c5:	c9                   	leave  
400036c6:	c3                   	ret    

400036c7 <strcmp>:

int
strcmp(const char *p, const char *q)
{
400036c7:	55                   	push   %ebp
400036c8:	89 e5                	mov    %esp,%ebp
	while (*p && *p == *q)
400036ca:	eb 08                	jmp    400036d4 <strcmp+0xd>
		p++, q++;
400036cc:	83 45 08 01          	addl   $0x1,0x8(%ebp)
400036d0:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
400036d4:	8b 45 08             	mov    0x8(%ebp),%eax
400036d7:	0f b6 00             	movzbl (%eax),%eax
400036da:	84 c0                	test   %al,%al
400036dc:	74 10                	je     400036ee <strcmp+0x27>
400036de:	8b 45 08             	mov    0x8(%ebp),%eax
400036e1:	0f b6 10             	movzbl (%eax),%edx
400036e4:	8b 45 0c             	mov    0xc(%ebp),%eax
400036e7:	0f b6 00             	movzbl (%eax),%eax
400036ea:	38 c2                	cmp    %al,%dl
400036ec:	74 de                	je     400036cc <strcmp+0x5>
	return (int) ((unsigned char) *p - (unsigned char) *q);
400036ee:	8b 45 08             	mov    0x8(%ebp),%eax
400036f1:	0f b6 00             	movzbl (%eax),%eax
400036f4:	0f b6 d0             	movzbl %al,%edx
400036f7:	8b 45 0c             	mov    0xc(%ebp),%eax
400036fa:	0f b6 00             	movzbl (%eax),%eax
400036fd:	0f b6 c0             	movzbl %al,%eax
40003700:	89 d1                	mov    %edx,%ecx
40003702:	29 c1                	sub    %eax,%ecx
40003704:	89 c8                	mov    %ecx,%eax
}
40003706:	5d                   	pop    %ebp
40003707:	c3                   	ret    

40003708 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
40003708:	55                   	push   %ebp
40003709:	89 e5                	mov    %esp,%ebp
4000370b:	83 ec 04             	sub    $0x4,%esp
	while (n > 0 && *p && *p == *q)
4000370e:	eb 0c                	jmp    4000371c <strncmp+0x14>
		n--, p++, q++;
40003710:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
40003714:	83 45 08 01          	addl   $0x1,0x8(%ebp)
40003718:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
4000371c:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
40003720:	74 1a                	je     4000373c <strncmp+0x34>
40003722:	8b 45 08             	mov    0x8(%ebp),%eax
40003725:	0f b6 00             	movzbl (%eax),%eax
40003728:	84 c0                	test   %al,%al
4000372a:	74 10                	je     4000373c <strncmp+0x34>
4000372c:	8b 45 08             	mov    0x8(%ebp),%eax
4000372f:	0f b6 10             	movzbl (%eax),%edx
40003732:	8b 45 0c             	mov    0xc(%ebp),%eax
40003735:	0f b6 00             	movzbl (%eax),%eax
40003738:	38 c2                	cmp    %al,%dl
4000373a:	74 d4                	je     40003710 <strncmp+0x8>
	if (n == 0)
4000373c:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
40003740:	75 09                	jne    4000374b <strncmp+0x43>
		return 0;
40003742:	c7 45 fc 00 00 00 00 	movl   $0x0,0xfffffffc(%ebp)
40003749:	eb 19                	jmp    40003764 <strncmp+0x5c>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
4000374b:	8b 45 08             	mov    0x8(%ebp),%eax
4000374e:	0f b6 00             	movzbl (%eax),%eax
40003751:	0f b6 d0             	movzbl %al,%edx
40003754:	8b 45 0c             	mov    0xc(%ebp),%eax
40003757:	0f b6 00             	movzbl (%eax),%eax
4000375a:	0f b6 c0             	movzbl %al,%eax
4000375d:	89 d1                	mov    %edx,%ecx
4000375f:	29 c1                	sub    %eax,%ecx
40003761:	89 4d fc             	mov    %ecx,0xfffffffc(%ebp)
40003764:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
}
40003767:	c9                   	leave  
40003768:	c3                   	ret    

40003769 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
40003769:	55                   	push   %ebp
4000376a:	89 e5                	mov    %esp,%ebp
4000376c:	83 ec 08             	sub    $0x8,%esp
4000376f:	8b 45 0c             	mov    0xc(%ebp),%eax
40003772:	88 45 fc             	mov    %al,0xfffffffc(%ebp)
	while (*s != c)
40003775:	eb 1c                	jmp    40003793 <strchr+0x2a>
		if (*s++ == 0)
40003777:	8b 45 08             	mov    0x8(%ebp),%eax
4000377a:	0f b6 00             	movzbl (%eax),%eax
4000377d:	84 c0                	test   %al,%al
4000377f:	0f 94 c0             	sete   %al
40003782:	83 45 08 01          	addl   $0x1,0x8(%ebp)
40003786:	84 c0                	test   %al,%al
40003788:	74 09                	je     40003793 <strchr+0x2a>
			return NULL;
4000378a:	c7 45 f8 00 00 00 00 	movl   $0x0,0xfffffff8(%ebp)
40003791:	eb 11                	jmp    400037a4 <strchr+0x3b>
40003793:	8b 45 08             	mov    0x8(%ebp),%eax
40003796:	0f b6 00             	movzbl (%eax),%eax
40003799:	3a 45 fc             	cmp    0xfffffffc(%ebp),%al
4000379c:	75 d9                	jne    40003777 <strchr+0xe>
	return (char *) s;
4000379e:	8b 45 08             	mov    0x8(%ebp),%eax
400037a1:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
400037a4:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
}
400037a7:	c9                   	leave  
400037a8:	c3                   	ret    

400037a9 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
400037a9:	55                   	push   %ebp
400037aa:	89 e5                	mov    %esp,%ebp
400037ac:	57                   	push   %edi
400037ad:	83 ec 14             	sub    $0x14,%esp
	char *p;

	if (n == 0)
400037b0:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
400037b4:	75 08                	jne    400037be <memset+0x15>
		return v;
400037b6:	8b 45 08             	mov    0x8(%ebp),%eax
400037b9:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
400037bc:	eb 5b                	jmp    40003819 <memset+0x70>
	if ((int)v%4 == 0 && n%4 == 0) {
400037be:	8b 45 08             	mov    0x8(%ebp),%eax
400037c1:	83 e0 03             	and    $0x3,%eax
400037c4:	85 c0                	test   %eax,%eax
400037c6:	75 3f                	jne    40003807 <memset+0x5e>
400037c8:	8b 45 10             	mov    0x10(%ebp),%eax
400037cb:	83 e0 03             	and    $0x3,%eax
400037ce:	85 c0                	test   %eax,%eax
400037d0:	75 35                	jne    40003807 <memset+0x5e>
		c &= 0xFF;
400037d2:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
		c = (c<<24)|(c<<16)|(c<<8)|c;
400037d9:	8b 45 0c             	mov    0xc(%ebp),%eax
400037dc:	89 c2                	mov    %eax,%edx
400037de:	c1 e2 18             	shl    $0x18,%edx
400037e1:	8b 45 0c             	mov    0xc(%ebp),%eax
400037e4:	c1 e0 10             	shl    $0x10,%eax
400037e7:	09 c2                	or     %eax,%edx
400037e9:	8b 45 0c             	mov    0xc(%ebp),%eax
400037ec:	c1 e0 08             	shl    $0x8,%eax
400037ef:	09 d0                	or     %edx,%eax
400037f1:	09 45 0c             	or     %eax,0xc(%ebp)
		asm volatile("cld; rep stosl\n"
400037f4:	8b 45 10             	mov    0x10(%ebp),%eax
400037f7:	89 c1                	mov    %eax,%ecx
400037f9:	c1 e9 02             	shr    $0x2,%ecx
400037fc:	8b 7d 08             	mov    0x8(%ebp),%edi
400037ff:	8b 45 0c             	mov    0xc(%ebp),%eax
40003802:	fc                   	cld    
40003803:	f3 ab                	rep stos %eax,%es:(%edi)
40003805:	eb 0c                	jmp    40003813 <memset+0x6a>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
40003807:	8b 7d 08             	mov    0x8(%ebp),%edi
4000380a:	8b 45 0c             	mov    0xc(%ebp),%eax
4000380d:	8b 4d 10             	mov    0x10(%ebp),%ecx
40003810:	fc                   	cld    
40003811:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
40003813:	8b 45 08             	mov    0x8(%ebp),%eax
40003816:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
40003819:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
}
4000381c:	83 c4 14             	add    $0x14,%esp
4000381f:	5f                   	pop    %edi
40003820:	5d                   	pop    %ebp
40003821:	c3                   	ret    

40003822 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
40003822:	55                   	push   %ebp
40003823:	89 e5                	mov    %esp,%ebp
40003825:	57                   	push   %edi
40003826:	56                   	push   %esi
40003827:	83 ec 10             	sub    $0x10,%esp
	const char *s;
	char *d;
	
	s = src;
4000382a:	8b 45 0c             	mov    0xc(%ebp),%eax
4000382d:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
	d = dst;
40003830:	8b 45 08             	mov    0x8(%ebp),%eax
40003833:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	if (s < d && s + n > d) {
40003836:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
40003839:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
4000383c:	73 63                	jae    400038a1 <memmove+0x7f>
4000383e:	8b 45 10             	mov    0x10(%ebp),%eax
40003841:	03 45 f0             	add    0xfffffff0(%ebp),%eax
40003844:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
40003847:	76 58                	jbe    400038a1 <memmove+0x7f>
		s += n;
40003849:	8b 45 10             	mov    0x10(%ebp),%eax
4000384c:	01 45 f0             	add    %eax,0xfffffff0(%ebp)
		d += n;
4000384f:	8b 45 10             	mov    0x10(%ebp),%eax
40003852:	01 45 f4             	add    %eax,0xfffffff4(%ebp)
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
40003855:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
40003858:	83 e0 03             	and    $0x3,%eax
4000385b:	85 c0                	test   %eax,%eax
4000385d:	75 2d                	jne    4000388c <memmove+0x6a>
4000385f:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
40003862:	83 e0 03             	and    $0x3,%eax
40003865:	85 c0                	test   %eax,%eax
40003867:	75 23                	jne    4000388c <memmove+0x6a>
40003869:	8b 45 10             	mov    0x10(%ebp),%eax
4000386c:	83 e0 03             	and    $0x3,%eax
4000386f:	85 c0                	test   %eax,%eax
40003871:	75 19                	jne    4000388c <memmove+0x6a>
			asm volatile("std; rep movsl\n"
40003873:	8b 7d f4             	mov    0xfffffff4(%ebp),%edi
40003876:	83 ef 04             	sub    $0x4,%edi
40003879:	8b 75 f0             	mov    0xfffffff0(%ebp),%esi
4000387c:	83 ee 04             	sub    $0x4,%esi
4000387f:	8b 45 10             	mov    0x10(%ebp),%eax
40003882:	89 c1                	mov    %eax,%ecx
40003884:	c1 e9 02             	shr    $0x2,%ecx
40003887:	fd                   	std    
40003888:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
4000388a:	eb 12                	jmp    4000389e <memmove+0x7c>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
4000388c:	8b 7d f4             	mov    0xfffffff4(%ebp),%edi
4000388f:	83 ef 01             	sub    $0x1,%edi
40003892:	8b 75 f0             	mov    0xfffffff0(%ebp),%esi
40003895:	83 ee 01             	sub    $0x1,%esi
40003898:	8b 4d 10             	mov    0x10(%ebp),%ecx
4000389b:	fd                   	std    
4000389c:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
4000389e:	fc                   	cld    
4000389f:	eb 3d                	jmp    400038de <memmove+0xbc>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
400038a1:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
400038a4:	83 e0 03             	and    $0x3,%eax
400038a7:	85 c0                	test   %eax,%eax
400038a9:	75 27                	jne    400038d2 <memmove+0xb0>
400038ab:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
400038ae:	83 e0 03             	and    $0x3,%eax
400038b1:	85 c0                	test   %eax,%eax
400038b3:	75 1d                	jne    400038d2 <memmove+0xb0>
400038b5:	8b 45 10             	mov    0x10(%ebp),%eax
400038b8:	83 e0 03             	and    $0x3,%eax
400038bb:	85 c0                	test   %eax,%eax
400038bd:	75 13                	jne    400038d2 <memmove+0xb0>
			asm volatile("cld; rep movsl\n"
400038bf:	8b 45 10             	mov    0x10(%ebp),%eax
400038c2:	89 c1                	mov    %eax,%ecx
400038c4:	c1 e9 02             	shr    $0x2,%ecx
400038c7:	8b 7d f4             	mov    0xfffffff4(%ebp),%edi
400038ca:	8b 75 f0             	mov    0xfffffff0(%ebp),%esi
400038cd:	fc                   	cld    
400038ce:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
400038d0:	eb 0c                	jmp    400038de <memmove+0xbc>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
400038d2:	8b 7d f4             	mov    0xfffffff4(%ebp),%edi
400038d5:	8b 75 f0             	mov    0xfffffff0(%ebp),%esi
400038d8:	8b 4d 10             	mov    0x10(%ebp),%ecx
400038db:	fc                   	cld    
400038dc:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
400038de:	8b 45 08             	mov    0x8(%ebp),%eax
}
400038e1:	83 c4 10             	add    $0x10,%esp
400038e4:	5e                   	pop    %esi
400038e5:	5f                   	pop    %edi
400038e6:	5d                   	pop    %ebp
400038e7:	c3                   	ret    

400038e8 <memcpy>:

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
400038e8:	55                   	push   %ebp
400038e9:	89 e5                	mov    %esp,%ebp
400038eb:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
400038ee:	8b 45 10             	mov    0x10(%ebp),%eax
400038f1:	89 44 24 08          	mov    %eax,0x8(%esp)
400038f5:	8b 45 0c             	mov    0xc(%ebp),%eax
400038f8:	89 44 24 04          	mov    %eax,0x4(%esp)
400038fc:	8b 45 08             	mov    0x8(%ebp),%eax
400038ff:	89 04 24             	mov    %eax,(%esp)
40003902:	e8 1b ff ff ff       	call   40003822 <memmove>
}
40003907:	c9                   	leave  
40003908:	c3                   	ret    

40003909 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
40003909:	55                   	push   %ebp
4000390a:	89 e5                	mov    %esp,%ebp
4000390c:	83 ec 14             	sub    $0x14,%esp
	const uint8_t *s1 = (const uint8_t *) v1;
4000390f:	8b 45 08             	mov    0x8(%ebp),%eax
40003912:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
	const uint8_t *s2 = (const uint8_t *) v2;
40003915:	8b 45 0c             	mov    0xc(%ebp),%eax
40003918:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)

	while (n-- > 0) {
4000391b:	eb 33                	jmp    40003950 <memcmp+0x47>
		if (*s1 != *s2)
4000391d:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
40003920:	0f b6 10             	movzbl (%eax),%edx
40003923:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
40003926:	0f b6 00             	movzbl (%eax),%eax
40003929:	38 c2                	cmp    %al,%dl
4000392b:	74 1b                	je     40003948 <memcmp+0x3f>
			return (int) *s1 - (int) *s2;
4000392d:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
40003930:	0f b6 00             	movzbl (%eax),%eax
40003933:	0f b6 d0             	movzbl %al,%edx
40003936:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
40003939:	0f b6 00             	movzbl (%eax),%eax
4000393c:	0f b6 c0             	movzbl %al,%eax
4000393f:	89 d1                	mov    %edx,%ecx
40003941:	29 c1                	sub    %eax,%ecx
40003943:	89 4d ec             	mov    %ecx,0xffffffec(%ebp)
40003946:	eb 19                	jmp    40003961 <memcmp+0x58>
		s1++, s2++;
40003948:	83 45 f8 01          	addl   $0x1,0xfffffff8(%ebp)
4000394c:	83 45 fc 01          	addl   $0x1,0xfffffffc(%ebp)
40003950:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
40003954:	83 7d 10 ff          	cmpl   $0xffffffff,0x10(%ebp)
40003958:	75 c3                	jne    4000391d <memcmp+0x14>
	}

	return 0;
4000395a:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
40003961:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
}
40003964:	c9                   	leave  
40003965:	c3                   	ret    

40003966 <memchr>:

void *
memchr(const void *s, int c, size_t n)
{
40003966:	55                   	push   %ebp
40003967:	89 e5                	mov    %esp,%ebp
40003969:	83 ec 14             	sub    $0x14,%esp
	const void *ends = (const char *) s + n;
4000396c:	8b 45 08             	mov    0x8(%ebp),%eax
4000396f:	8b 55 10             	mov    0x10(%ebp),%edx
40003972:	01 d0                	add    %edx,%eax
40003974:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	for (; s < ends; s++)
40003977:	eb 19                	jmp    40003992 <memchr+0x2c>
		if (*(const unsigned char *) s == (unsigned char) c)
40003979:	8b 45 08             	mov    0x8(%ebp),%eax
4000397c:	0f b6 10             	movzbl (%eax),%edx
4000397f:	8b 45 0c             	mov    0xc(%ebp),%eax
40003982:	38 c2                	cmp    %al,%dl
40003984:	75 08                	jne    4000398e <memchr+0x28>
			return (void *) s;
40003986:	8b 45 08             	mov    0x8(%ebp),%eax
40003989:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
4000398c:	eb 13                	jmp    400039a1 <memchr+0x3b>
4000398e:	83 45 08 01          	addl   $0x1,0x8(%ebp)
40003992:	8b 45 08             	mov    0x8(%ebp),%eax
40003995:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
40003998:	72 df                	jb     40003979 <memchr+0x13>
	return NULL;
4000399a:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
400039a1:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
}
400039a4:	c9                   	leave  
400039a5:	c3                   	ret    
400039a6:	90                   	nop    
400039a7:	90                   	nop    

400039a8 <exit>:
#include <inc/string.h>

void gcc_noreturn
exit(int status)
{
400039a8:	55                   	push   %ebp
400039a9:	89 e5                	mov    %esp,%ebp
400039ab:	83 ec 18             	sub    $0x18,%esp
	// To exit a PIOS user process, by convention,
	// we just set our exit status in our filestate area
	// and return to our parent process.
	files->status = status;
400039ae:	8b 15 30 61 00 40    	mov    0x40006130,%edx
400039b4:	8b 45 08             	mov    0x8(%ebp),%eax
400039b7:	89 42 0c             	mov    %eax,0xc(%edx)
	files->exited = 1;
400039ba:	a1 30 61 00 40       	mov    0x40006130,%eax
400039bf:	c7 40 08 01 00 00 00 	movl   $0x1,0x8(%eax)

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
400039c6:	b8 03 00 00 00       	mov    $0x3,%eax
400039cb:	cd 30                	int    $0x30
	sys_ret();
	panic("exit: sys_ret shouldn't have returned");
400039cd:	c7 44 24 08 fc 60 00 	movl   $0x400060fc,0x8(%esp)
400039d4:	40 
400039d5:	c7 44 24 04 1a 00 00 	movl   $0x1a,0x4(%esp)
400039dc:	00 
400039dd:	c7 04 24 22 61 00 40 	movl   $0x40006122,(%esp)
400039e4:	e8 ff f1 ff ff       	call   40002be8 <debug_panic>

400039e9 <abort>:
}

void gcc_noreturn
abort(void)
{
400039e9:	55                   	push   %ebp
400039ea:	89 e5                	mov    %esp,%ebp
400039ec:	83 ec 08             	sub    $0x8,%esp
	exit(EXIT_FAILURE);
400039ef:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
400039f6:	e8 ad ff ff ff       	call   400039a8 <exit>
400039fb:	90                   	nop    

400039fc <cputs>:
#include <inc/stdio.h>
#include <inc/syscall.h>

void cputs(const char *str)
{
400039fc:	55                   	push   %ebp
400039fd:	89 e5                	mov    %esp,%ebp
400039ff:	53                   	push   %ebx
40003a00:	83 ec 10             	sub    $0x10,%esp
40003a03:	8b 45 08             	mov    0x8(%ebp),%eax
40003a06:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %0" :
40003a09:	b8 00 00 00 00       	mov    $0x0,%eax
40003a0e:	8b 5d f8             	mov    0xfffffff8(%ebp),%ebx
40003a11:	cd 30                	int    $0x30
	sys_cputs(str);
}
40003a13:	83 c4 10             	add    $0x10,%esp
40003a16:	5b                   	pop    %ebx
40003a17:	5d                   	pop    %ebp
40003a18:	c3                   	ret    
40003a19:	90                   	nop    
40003a1a:	90                   	nop    
40003a1b:	90                   	nop    

40003a1c <fileino_alloc>:
// Find and return the index of a currently unused file inode in this process.
// If no inodes are available, returns -1 and sets errno accordingly.
int
fileino_alloc(void)
{
40003a1c:	55                   	push   %ebp
40003a1d:	89 e5                	mov    %esp,%ebp
40003a1f:	83 ec 28             	sub    $0x28,%esp
	int i;
	for (i = FILEINO_GENERAL; i < FILE_INODES; i++)
40003a22:	c7 45 fc 04 00 00 00 	movl   $0x4,0xfffffffc(%ebp)
40003a29:	eb 27                	jmp    40003a52 <fileino_alloc+0x36>
		if (files->fi[i].de.d_name[0] == 0)
40003a2b:	8b 15 30 61 00 40    	mov    0x40006130,%edx
40003a31:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
40003a34:	6b c0 5c             	imul   $0x5c,%eax,%eax
40003a37:	01 d0                	add    %edx,%eax
40003a39:	05 10 10 00 00       	add    $0x1010,%eax
40003a3e:	0f b6 40 04          	movzbl 0x4(%eax),%eax
40003a42:	84 c0                	test   %al,%al
40003a44:	75 08                	jne    40003a4e <fileino_alloc+0x32>
			return i;
40003a46:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
40003a49:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
40003a4c:	eb 3b                	jmp    40003a89 <fileino_alloc+0x6d>
40003a4e:	83 45 fc 01          	addl   $0x1,0xfffffffc(%ebp)
40003a52:	81 7d fc ff 00 00 00 	cmpl   $0xff,0xfffffffc(%ebp)
40003a59:	7e d0                	jle    40003a2b <fileino_alloc+0xf>

	warn("fileino_alloc: no free inodes\n");
40003a5b:	c7 44 24 08 34 61 00 	movl   $0x40006134,0x8(%esp)
40003a62:	40 
40003a63:	c7 44 24 04 29 00 00 	movl   $0x29,0x4(%esp)
40003a6a:	00 
40003a6b:	c7 04 24 53 61 00 40 	movl   $0x40006153,(%esp)
40003a72:	e8 db f1 ff ff       	call   40002c52 <debug_warn>
	errno = ENOSPC;
40003a77:	a1 30 61 00 40       	mov    0x40006130,%eax
40003a7c:	c7 00 07 00 00 00    	movl   $0x7,(%eax)
	return -1;
40003a82:	c7 45 ec ff ff ff ff 	movl   $0xffffffff,0xffffffec(%ebp)
40003a89:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
}
40003a8c:	c9                   	leave  
40003a8d:	c3                   	ret    

40003a8e <fileino_create>:

// Find or create an inode with a given parent directory inode and filename.
// Returns the index of the inode found or created.
// A newly-created inode is left in the "deleted" state, with mode == 0.
// If no inodes are available, returns -1 and sets errno accordingly.
int
fileino_create(filestate *fs, int dino, const char *name)
{
40003a8e:	55                   	push   %ebp
40003a8f:	89 e5                	mov    %esp,%ebp
40003a91:	83 ec 28             	sub    $0x28,%esp
	assert(dino != 0);
40003a94:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
40003a98:	75 24                	jne    40003abe <fileino_create+0x30>
40003a9a:	c7 44 24 0c 5e 61 00 	movl   $0x4000615e,0xc(%esp)
40003aa1:	40 
40003aa2:	c7 44 24 08 68 61 00 	movl   $0x40006168,0x8(%esp)
40003aa9:	40 
40003aaa:	c7 44 24 04 35 00 00 	movl   $0x35,0x4(%esp)
40003ab1:	00 
40003ab2:	c7 04 24 53 61 00 40 	movl   $0x40006153,(%esp)
40003ab9:	e8 2a f1 ff ff       	call   40002be8 <debug_panic>
	assert(name != NULL && name[0] != 0);
40003abe:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
40003ac2:	74 0a                	je     40003ace <fileino_create+0x40>
40003ac4:	8b 45 10             	mov    0x10(%ebp),%eax
40003ac7:	0f b6 00             	movzbl (%eax),%eax
40003aca:	84 c0                	test   %al,%al
40003acc:	75 24                	jne    40003af2 <fileino_create+0x64>
40003ace:	c7 44 24 0c 7d 61 00 	movl   $0x4000617d,0xc(%esp)
40003ad5:	40 
40003ad6:	c7 44 24 08 68 61 00 	movl   $0x40006168,0x8(%esp)
40003add:	40 
40003ade:	c7 44 24 04 36 00 00 	movl   $0x36,0x4(%esp)
40003ae5:	00 
40003ae6:	c7 04 24 53 61 00 40 	movl   $0x40006153,(%esp)
40003aed:	e8 f6 f0 ff ff       	call   40002be8 <debug_panic>
	assert(strlen(name) <= NAME_MAX);
40003af2:	8b 45 10             	mov    0x10(%ebp),%eax
40003af5:	89 04 24             	mov    %eax,(%esp)
40003af8:	e8 df fa ff ff       	call   400035dc <strlen>
40003afd:	83 f8 3f             	cmp    $0x3f,%eax
40003b00:	7e 24                	jle    40003b26 <fileino_create+0x98>
40003b02:	c7 44 24 0c 9a 61 00 	movl   $0x4000619a,0xc(%esp)
40003b09:	40 
40003b0a:	c7 44 24 08 68 61 00 	movl   $0x40006168,0x8(%esp)
40003b11:	40 
40003b12:	c7 44 24 04 37 00 00 	movl   $0x37,0x4(%esp)
40003b19:	00 
40003b1a:	c7 04 24 53 61 00 40 	movl   $0x40006153,(%esp)
40003b21:	e8 c2 f0 ff ff       	call   40002be8 <debug_panic>

	// First see if an inode already exists for this directory and name.
	int i;
	for (i = FILEINO_GENERAL; i < FILE_INODES; i++)
40003b26:	c7 45 fc 04 00 00 00 	movl   $0x4,0xfffffffc(%ebp)
40003b2d:	eb 4a                	jmp    40003b79 <fileino_create+0xeb>
		if (fs->fi[i].dino == dino
40003b2f:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
40003b32:	8b 55 08             	mov    0x8(%ebp),%edx
40003b35:	6b c0 5c             	imul   $0x5c,%eax,%eax
40003b38:	01 d0                	add    %edx,%eax
40003b3a:	05 10 10 00 00       	add    $0x1010,%eax
40003b3f:	8b 00                	mov    (%eax),%eax
40003b41:	3b 45 0c             	cmp    0xc(%ebp),%eax
40003b44:	75 2f                	jne    40003b75 <fileino_create+0xe7>
40003b46:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
40003b49:	6b c0 5c             	imul   $0x5c,%eax,%eax
40003b4c:	05 10 10 00 00       	add    $0x1010,%eax
40003b51:	03 45 08             	add    0x8(%ebp),%eax
40003b54:	8d 50 04             	lea    0x4(%eax),%edx
40003b57:	8b 45 10             	mov    0x10(%ebp),%eax
40003b5a:	89 44 24 04          	mov    %eax,0x4(%esp)
40003b5e:	89 14 24             	mov    %edx,(%esp)
40003b61:	e8 61 fb ff ff       	call   400036c7 <strcmp>
40003b66:	85 c0                	test   %eax,%eax
40003b68:	75 0b                	jne    40003b75 <fileino_create+0xe7>
				&& strcmp(fs->fi[i].de.d_name, name) == 0)
			return i;
40003b6a:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
40003b6d:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
40003b70:	e9 a7 00 00 00       	jmp    40003c1c <fileino_create+0x18e>
40003b75:	83 45 fc 01          	addl   $0x1,0xfffffffc(%ebp)
40003b79:	81 7d fc ff 00 00 00 	cmpl   $0xff,0xfffffffc(%ebp)
40003b80:	7e ad                	jle    40003b2f <fileino_create+0xa1>

	// No inode allocated to this name - find a free one to allocate.
	for (i = FILEINO_GENERAL; i < FILE_INODES; i++)
40003b82:	c7 45 fc 04 00 00 00 	movl   $0x4,0xfffffffc(%ebp)
40003b89:	eb 5a                	jmp    40003be5 <fileino_create+0x157>
		if (fs->fi[i].de.d_name[0] == 0) {
40003b8b:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
40003b8e:	8b 55 08             	mov    0x8(%ebp),%edx
40003b91:	6b c0 5c             	imul   $0x5c,%eax,%eax
40003b94:	01 d0                	add    %edx,%eax
40003b96:	05 10 10 00 00       	add    $0x1010,%eax
40003b9b:	0f b6 40 04          	movzbl 0x4(%eax),%eax
40003b9f:	84 c0                	test   %al,%al
40003ba1:	75 3e                	jne    40003be1 <fileino_create+0x153>
			fs->fi[i].dino = dino;
40003ba3:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
40003ba6:	8b 55 08             	mov    0x8(%ebp),%edx
40003ba9:	6b c0 5c             	imul   $0x5c,%eax,%eax
40003bac:	01 d0                	add    %edx,%eax
40003bae:	8d 90 10 10 00 00    	lea    0x1010(%eax),%edx
40003bb4:	8b 45 0c             	mov    0xc(%ebp),%eax
40003bb7:	89 02                	mov    %eax,(%edx)
			strcpy(fs->fi[i].de.d_name, name);
40003bb9:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
40003bbc:	6b c0 5c             	imul   $0x5c,%eax,%eax
40003bbf:	05 10 10 00 00       	add    $0x1010,%eax
40003bc4:	03 45 08             	add    0x8(%ebp),%eax
40003bc7:	8d 50 04             	lea    0x4(%eax),%edx
40003bca:	8b 45 10             	mov    0x10(%ebp),%eax
40003bcd:	89 44 24 04          	mov    %eax,0x4(%esp)
40003bd1:	89 14 24             	mov    %edx,(%esp)
40003bd4:	e8 29 fa ff ff       	call   40003602 <strcpy>
			return i;
40003bd9:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
40003bdc:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
40003bdf:	eb 3b                	jmp    40003c1c <fileino_create+0x18e>
40003be1:	83 45 fc 01          	addl   $0x1,0xfffffffc(%ebp)
40003be5:	81 7d fc ff 00 00 00 	cmpl   $0xff,0xfffffffc(%ebp)
40003bec:	7e 9d                	jle    40003b8b <fileino_create+0xfd>
		}

	warn("fileino_create: no free inodes\n");
40003bee:	c7 44 24 08 b4 61 00 	movl   $0x400061b4,0x8(%esp)
40003bf5:	40 
40003bf6:	c7 44 24 04 48 00 00 	movl   $0x48,0x4(%esp)
40003bfd:	00 
40003bfe:	c7 04 24 53 61 00 40 	movl   $0x40006153,(%esp)
40003c05:	e8 48 f0 ff ff       	call   40002c52 <debug_warn>
	errno = ENOSPC;
40003c0a:	a1 30 61 00 40       	mov    0x40006130,%eax
40003c0f:	c7 00 07 00 00 00    	movl   $0x7,(%eax)
	return -1;
40003c15:	c7 45 ec ff ff ff ff 	movl   $0xffffffff,0xffffffec(%ebp)
40003c1c:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
}
40003c1f:	c9                   	leave  
40003c20:	c3                   	ret    

40003c21 <fileino_read>:

// Read up to 'count' data elements each of size 'eltsize',
// starting at absolute byte offset 'ofs' within the file in inode 'ino'.
// Returns the number of elements (NOT the number of bytes!) actually read,
// or if an error occurs, returns -1 and sets errno appropriately.
// The number of elements returned is normally equal to the 'count' parameter,
// but may be less (without resulting in an error)
// if the file is not large enough to read that many elements.
ssize_t
fileino_read(int ino, off_t ofs, void *buf, size_t eltsize, size_t count)
{
40003c21:	55                   	push   %ebp
40003c22:	89 e5                	mov    %esp,%ebp
40003c24:	83 ec 38             	sub    $0x38,%esp
	assert(fileino_isreg(ino));
40003c27:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
40003c2b:	7e 45                	jle    40003c72 <fileino_read+0x51>
40003c2d:	81 7d 08 ff 00 00 00 	cmpl   $0xff,0x8(%ebp)
40003c34:	7f 3c                	jg     40003c72 <fileino_read+0x51>
40003c36:	8b 15 30 61 00 40    	mov    0x40006130,%edx
40003c3c:	8b 45 08             	mov    0x8(%ebp),%eax
40003c3f:	6b c0 5c             	imul   $0x5c,%eax,%eax
40003c42:	01 d0                	add    %edx,%eax
40003c44:	05 10 10 00 00       	add    $0x1010,%eax
40003c49:	0f b6 40 04          	movzbl 0x4(%eax),%eax
40003c4d:	84 c0                	test   %al,%al
40003c4f:	74 21                	je     40003c72 <fileino_read+0x51>
40003c51:	8b 15 30 61 00 40    	mov    0x40006130,%edx
40003c57:	8b 45 08             	mov    0x8(%ebp),%eax
40003c5a:	6b c0 5c             	imul   $0x5c,%eax,%eax
40003c5d:	01 d0                	add    %edx,%eax
40003c5f:	05 58 10 00 00       	add    $0x1058,%eax
40003c64:	8b 00                	mov    (%eax),%eax
40003c66:	25 00 70 00 00       	and    $0x7000,%eax
40003c6b:	3d 00 10 00 00       	cmp    $0x1000,%eax
40003c70:	74 24                	je     40003c96 <fileino_read+0x75>
40003c72:	c7 44 24 0c d4 61 00 	movl   $0x400061d4,0xc(%esp)
40003c79:	40 
40003c7a:	c7 44 24 08 68 61 00 	movl   $0x40006168,0x8(%esp)
40003c81:	40 
40003c82:	c7 44 24 04 57 00 00 	movl   $0x57,0x4(%esp)
40003c89:	00 
40003c8a:	c7 04 24 53 61 00 40 	movl   $0x40006153,(%esp)
40003c91:	e8 52 ef ff ff       	call   40002be8 <debug_panic>
	assert(ofs >= 0);
40003c96:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
40003c9a:	79 24                	jns    40003cc0 <fileino_read+0x9f>
40003c9c:	c7 44 24 0c e7 61 00 	movl   $0x400061e7,0xc(%esp)
40003ca3:	40 
40003ca4:	c7 44 24 08 68 61 00 	movl   $0x40006168,0x8(%esp)
40003cab:	40 
40003cac:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
40003cb3:	00 
40003cb4:	c7 04 24 53 61 00 40 	movl   $0x40006153,(%esp)
40003cbb:	e8 28 ef ff ff       	call   40002be8 <debug_panic>
	assert(eltsize > 0);
40003cc0:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
40003cc4:	75 24                	jne    40003cea <fileino_read+0xc9>
40003cc6:	c7 44 24 0c f0 61 00 	movl   $0x400061f0,0xc(%esp)
40003ccd:	40 
40003cce:	c7 44 24 08 68 61 00 	movl   $0x40006168,0x8(%esp)
40003cd5:	40 
40003cd6:	c7 44 24 04 59 00 00 	movl   $0x59,0x4(%esp)
40003cdd:	00 
40003cde:	c7 04 24 53 61 00 40 	movl   $0x40006153,(%esp)
40003ce5:	e8 fe ee ff ff       	call   40002be8 <debug_panic>

	fileinode *fi = &files->fi[ino];
40003cea:	a1 30 61 00 40       	mov    0x40006130,%eax
40003cef:	8d 90 10 10 00 00    	lea    0x1010(%eax),%edx
40003cf5:	8b 45 08             	mov    0x8(%ebp),%eax
40003cf8:	6b c0 5c             	imul   $0x5c,%eax,%eax
40003cfb:	8d 04 02             	lea    (%edx,%eax,1),%eax
40003cfe:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
	assert(fi->size <= FILE_MAXSIZE);
40003d01:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
40003d04:	8b 40 4c             	mov    0x4c(%eax),%eax
40003d07:	3d 00 00 40 00       	cmp    $0x400000,%eax
40003d0c:	76 24                	jbe    40003d32 <fileino_read+0x111>
40003d0e:	c7 44 24 0c fc 61 00 	movl   $0x400061fc,0xc(%esp)
40003d15:	40 
40003d16:	c7 44 24 08 68 61 00 	movl   $0x40006168,0x8(%esp)
40003d1d:	40 
40003d1e:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
40003d25:	00 
40003d26:	c7 04 24 53 61 00 40 	movl   $0x40006153,(%esp)
40003d2d:	e8 b6 ee ff ff       	call   40002be8 <debug_panic>

	// Lab 4: insert your file reading code here.
  ssize_t actual = 0;
40003d32:	c7 45 f0 00 00 00 00 	movl   $0x0,0xfffffff0(%ebp)
  while (count > 0){
40003d39:	e9 ba 00 00 00       	jmp    40003df8 <fileino_read+0x1d7>

    ssize_t avail = MIN(count, (fi->size - ofs) / eltsize);
40003d3e:	8b 45 18             	mov    0x18(%ebp),%eax
40003d41:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
40003d44:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
40003d47:	8b 50 4c             	mov    0x4c(%eax),%edx
40003d4a:	8b 45 0c             	mov    0xc(%ebp),%eax
40003d4d:	89 d1                	mov    %edx,%ecx
40003d4f:	29 c1                	sub    %eax,%ecx
40003d51:	89 c8                	mov    %ecx,%eax
40003d53:	ba 00 00 00 00       	mov    $0x0,%edx
40003d58:	f7 75 14             	divl   0x14(%ebp)
40003d5b:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
40003d5e:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
40003d61:	89 45 d8             	mov    %eax,0xffffffd8(%ebp)
40003d64:	8b 4d f8             	mov    0xfffffff8(%ebp),%ecx
40003d67:	89 4d dc             	mov    %ecx,0xffffffdc(%ebp)
40003d6a:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
40003d6d:	39 45 dc             	cmp    %eax,0xffffffdc(%ebp)
40003d70:	76 06                	jbe    40003d78 <fileino_read+0x157>
40003d72:	8b 4d d8             	mov    0xffffffd8(%ebp),%ecx
40003d75:	89 4d dc             	mov    %ecx,0xffffffdc(%ebp)
40003d78:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
40003d7b:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
    if (ofs >= fi->size)
40003d7e:	8b 45 0c             	mov    0xc(%ebp),%eax
40003d81:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
40003d84:	8b 52 4c             	mov    0x4c(%edx),%edx
40003d87:	39 d0                	cmp    %edx,%eax
40003d89:	72 07                	jb     40003d92 <fileino_read+0x171>
      avail = 0;
40003d8b:	c7 45 f4 00 00 00 00 	movl   $0x0,0xfffffff4(%ebp)
    if (avail > 0){
40003d92:	83 7d f4 00          	cmpl   $0x0,0xfffffff4(%ebp)
40003d96:	7e 44                	jle    40003ddc <fileino_read+0x1bb>
    memmove(buf, FILEDATA(ino) + ofs, avail * eltsize);
40003d98:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
40003d9b:	89 c1                	mov    %eax,%ecx
40003d9d:	0f af 4d 14          	imul   0x14(%ebp),%ecx
40003da1:	8b 45 08             	mov    0x8(%ebp),%eax
40003da4:	c1 e0 16             	shl    $0x16,%eax
40003da7:	8d 90 00 00 00 80    	lea    0x80000000(%eax),%edx
40003dad:	8b 45 0c             	mov    0xc(%ebp),%eax
40003db0:	8d 04 02             	lea    (%edx,%eax,1),%eax
40003db3:	89 4c 24 08          	mov    %ecx,0x8(%esp)
40003db7:	89 44 24 04          	mov    %eax,0x4(%esp)
40003dbb:	8b 45 10             	mov    0x10(%ebp),%eax
40003dbe:	89 04 24             	mov    %eax,(%esp)
40003dc1:	e8 5c fa ff ff       	call   40003822 <memmove>
      buf += avail * eltsize;
40003dc6:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
40003dc9:	0f af 45 14          	imul   0x14(%ebp),%eax
40003dcd:	01 45 10             	add    %eax,0x10(%ebp)
      actual += avail;
40003dd0:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
40003dd3:	01 45 f0             	add    %eax,0xfffffff0(%ebp)
		count -= avail;
40003dd6:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
40003dd9:	29 45 18             	sub    %eax,0x18(%ebp)
	}
    if (count == 0 || !(fi->mode & S_IFPART))
40003ddc:	83 7d 18 00          	cmpl   $0x0,0x18(%ebp)
40003de0:	74 20                	je     40003e02 <fileino_read+0x1e1>
40003de2:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
40003de5:	8b 40 48             	mov    0x48(%eax),%eax
40003de8:	25 00 80 00 00       	and    $0x8000,%eax
40003ded:	85 c0                	test   %eax,%eax
40003def:	74 11                	je     40003e02 <fileino_read+0x1e1>

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40003df1:	b8 03 00 00 00       	mov    $0x3,%eax
40003df6:	cd 30                	int    $0x30
40003df8:	83 7d 18 00          	cmpl   $0x0,0x18(%ebp)
40003dfc:	0f 85 3c ff ff ff    	jne    40003d3e <fileino_read+0x11d>
      break;

    sys_ret();
    }
    
    return actual;
40003e02:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
}
40003e05:	c9                   	leave  
40003e06:	c3                   	ret    

40003e07 <fileino_write>:

// Write 'count' data elements each of size 'eltsize'
// starting at absolute byte offset 'ofs' within the file in inode 'ino'.
// Returns the number of elements actually written,
// which should always be equal to the 'count' input parameter
// unless an error occurs, in which case this function
// returns -1 and sets errno appropriately.
// Since PIOS files can be up to only FILE_MAXSIZE bytes in size (4MB),
// one particular reason an error might occur is if an application
// tries to grow a file beyond this maximum file size,
// in which case this function generates the EFBIG error.
ssize_t
fileino_write(int ino, off_t ofs, const void *buf, size_t eltsize, size_t count)
{
40003e07:	55                   	push   %ebp
40003e08:	89 e5                	mov    %esp,%ebp
40003e0a:	57                   	push   %edi
40003e0b:	56                   	push   %esi
40003e0c:	53                   	push   %ebx
40003e0d:	83 ec 5c             	sub    $0x5c,%esp
	assert(fileino_isreg(ino));
40003e10:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
40003e14:	7e 45                	jle    40003e5b <fileino_write+0x54>
40003e16:	81 7d 08 ff 00 00 00 	cmpl   $0xff,0x8(%ebp)
40003e1d:	7f 3c                	jg     40003e5b <fileino_write+0x54>
40003e1f:	8b 15 30 61 00 40    	mov    0x40006130,%edx
40003e25:	8b 45 08             	mov    0x8(%ebp),%eax
40003e28:	6b c0 5c             	imul   $0x5c,%eax,%eax
40003e2b:	01 d0                	add    %edx,%eax
40003e2d:	05 10 10 00 00       	add    $0x1010,%eax
40003e32:	0f b6 40 04          	movzbl 0x4(%eax),%eax
40003e36:	84 c0                	test   %al,%al
40003e38:	74 21                	je     40003e5b <fileino_write+0x54>
40003e3a:	8b 15 30 61 00 40    	mov    0x40006130,%edx
40003e40:	8b 45 08             	mov    0x8(%ebp),%eax
40003e43:	6b c0 5c             	imul   $0x5c,%eax,%eax
40003e46:	01 d0                	add    %edx,%eax
40003e48:	05 58 10 00 00       	add    $0x1058,%eax
40003e4d:	8b 00                	mov    (%eax),%eax
40003e4f:	25 00 70 00 00       	and    $0x7000,%eax
40003e54:	3d 00 10 00 00       	cmp    $0x1000,%eax
40003e59:	74 24                	je     40003e7f <fileino_write+0x78>
40003e5b:	c7 44 24 0c d4 61 00 	movl   $0x400061d4,0xc(%esp)
40003e62:	40 
40003e63:	c7 44 24 08 68 61 00 	movl   $0x40006168,0x8(%esp)
40003e6a:	40 
40003e6b:	c7 44 24 04 81 00 00 	movl   $0x81,0x4(%esp)
40003e72:	00 
40003e73:	c7 04 24 53 61 00 40 	movl   $0x40006153,(%esp)
40003e7a:	e8 69 ed ff ff       	call   40002be8 <debug_panic>
	assert(ofs >= 0);
40003e7f:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
40003e83:	79 24                	jns    40003ea9 <fileino_write+0xa2>
40003e85:	c7 44 24 0c e7 61 00 	movl   $0x400061e7,0xc(%esp)
40003e8c:	40 
40003e8d:	c7 44 24 08 68 61 00 	movl   $0x40006168,0x8(%esp)
40003e94:	40 
40003e95:	c7 44 24 04 82 00 00 	movl   $0x82,0x4(%esp)
40003e9c:	00 
40003e9d:	c7 04 24 53 61 00 40 	movl   $0x40006153,(%esp)
40003ea4:	e8 3f ed ff ff       	call   40002be8 <debug_panic>
	assert(eltsize > 0);
40003ea9:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
40003ead:	75 24                	jne    40003ed3 <fileino_write+0xcc>
40003eaf:	c7 44 24 0c f0 61 00 	movl   $0x400061f0,0xc(%esp)
40003eb6:	40 
40003eb7:	c7 44 24 08 68 61 00 	movl   $0x40006168,0x8(%esp)
40003ebe:	40 
40003ebf:	c7 44 24 04 83 00 00 	movl   $0x83,0x4(%esp)
40003ec6:	00 
40003ec7:	c7 04 24 53 61 00 40 	movl   $0x40006153,(%esp)
40003ece:	e8 15 ed ff ff       	call   40002be8 <debug_panic>

	fileinode *fi = &files->fi[ino];
40003ed3:	a1 30 61 00 40       	mov    0x40006130,%eax
40003ed8:	8d 90 10 10 00 00    	lea    0x1010(%eax),%edx
40003ede:	8b 45 08             	mov    0x8(%ebp),%eax
40003ee1:	6b c0 5c             	imul   $0x5c,%eax,%eax
40003ee4:	8d 04 02             	lea    (%edx,%eax,1),%eax
40003ee7:	89 45 b8             	mov    %eax,0xffffffb8(%ebp)
	assert(fi->size <= FILE_MAXSIZE);
40003eea:	8b 45 b8             	mov    0xffffffb8(%ebp),%eax
40003eed:	8b 40 4c             	mov    0x4c(%eax),%eax
40003ef0:	3d 00 00 40 00       	cmp    $0x400000,%eax
40003ef5:	76 24                	jbe    40003f1b <fileino_write+0x114>
40003ef7:	c7 44 24 0c fc 61 00 	movl   $0x400061fc,0xc(%esp)
40003efe:	40 
40003eff:	c7 44 24 08 68 61 00 	movl   $0x40006168,0x8(%esp)
40003f06:	40 
40003f07:	c7 44 24 04 86 00 00 	movl   $0x86,0x4(%esp)
40003f0e:	00 
40003f0f:	c7 04 24 53 61 00 40 	movl   $0x40006153,(%esp)
40003f16:	e8 cd ec ff ff       	call   40002be8 <debug_panic>

	// Lab 4: insert your file writing code here.
	size_t len = eltsize * count;
40003f1b:	8b 45 14             	mov    0x14(%ebp),%eax
40003f1e:	0f af 45 18          	imul   0x18(%ebp),%eax
40003f22:	89 45 bc             	mov    %eax,0xffffffbc(%ebp)
	size_t lim = ofs + len;
40003f25:	8b 45 0c             	mov    0xc(%ebp),%eax
40003f28:	03 45 bc             	add    0xffffffbc(%ebp),%eax
40003f2b:	89 45 c0             	mov    %eax,0xffffffc0(%ebp)
	if (lim < ofs || lim > FILE_MAXSIZE) {
40003f2e:	8b 45 0c             	mov    0xc(%ebp),%eax
40003f31:	3b 45 c0             	cmp    0xffffffc0(%ebp),%eax
40003f34:	77 09                	ja     40003f3f <fileino_write+0x138>
40003f36:	81 7d c0 00 00 40 00 	cmpl   $0x400000,0xffffffc0(%ebp)
40003f3d:	76 17                	jbe    40003f56 <fileino_write+0x14f>
		errno = EFBIG;
40003f3f:	a1 30 61 00 40       	mov    0x40006130,%eax
40003f44:	c7 00 03 00 00 00    	movl   $0x3,(%eax)
		return -1;
40003f4a:	c7 45 b0 ff ff ff ff 	movl   $0xffffffff,0xffffffb0(%ebp)
40003f51:	e9 f1 00 00 00       	jmp    40004047 <fileino_write+0x240>
	}

	// Grow the file as necessary.
	if (lim > fi->size) {
40003f56:	8b 45 b8             	mov    0xffffffb8(%ebp),%eax
40003f59:	8b 40 4c             	mov    0x4c(%eax),%eax
40003f5c:	3b 45 c0             	cmp    0xffffffc0(%ebp),%eax
40003f5f:	0f 83 b5 00 00 00    	jae    4000401a <fileino_write+0x213>
		size_t oldpagelim = ROUNDUP(fi->size, PAGESIZE);
40003f65:	c7 45 cc 00 10 00 00 	movl   $0x1000,0xffffffcc(%ebp)
40003f6c:	8b 45 b8             	mov    0xffffffb8(%ebp),%eax
40003f6f:	8b 40 4c             	mov    0x4c(%eax),%eax
40003f72:	03 45 cc             	add    0xffffffcc(%ebp),%eax
40003f75:	83 e8 01             	sub    $0x1,%eax
40003f78:	89 45 d0             	mov    %eax,0xffffffd0(%ebp)
40003f7b:	8b 45 d0             	mov    0xffffffd0(%ebp),%eax
40003f7e:	ba 00 00 00 00       	mov    $0x0,%edx
40003f83:	f7 75 cc             	divl   0xffffffcc(%ebp)
40003f86:	8b 45 d0             	mov    0xffffffd0(%ebp),%eax
40003f89:	29 d0                	sub    %edx,%eax
40003f8b:	89 45 c4             	mov    %eax,0xffffffc4(%ebp)
		size_t newpagelim = ROUNDUP(lim, PAGESIZE);
40003f8e:	c7 45 d4 00 10 00 00 	movl   $0x1000,0xffffffd4(%ebp)
40003f95:	8b 45 d4             	mov    0xffffffd4(%ebp),%eax
40003f98:	03 45 c0             	add    0xffffffc0(%ebp),%eax
40003f9b:	83 e8 01             	sub    $0x1,%eax
40003f9e:	89 45 d8             	mov    %eax,0xffffffd8(%ebp)
40003fa1:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
40003fa4:	ba 00 00 00 00       	mov    $0x0,%edx
40003fa9:	f7 75 d4             	divl   0xffffffd4(%ebp)
40003fac:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
40003faf:	29 d0                	sub    %edx,%eax
40003fb1:	89 45 c8             	mov    %eax,0xffffffc8(%ebp)
		if (newpagelim > oldpagelim)
40003fb4:	8b 45 c8             	mov    0xffffffc8(%ebp),%eax
40003fb7:	3b 45 c4             	cmp    0xffffffc4(%ebp),%eax
40003fba:	76 55                	jbe    40004011 <fileino_write+0x20a>
			sys_get(SYS_PERM | SYS_READ | SYS_WRITE, 0, NULL, NULL,
40003fbc:	8b 55 c4             	mov    0xffffffc4(%ebp),%edx
40003fbf:	8b 45 c8             	mov    0xffffffc8(%ebp),%eax
40003fc2:	89 c1                	mov    %eax,%ecx
40003fc4:	29 d1                	sub    %edx,%ecx
40003fc6:	8b 45 08             	mov    0x8(%ebp),%eax
40003fc9:	c1 e0 16             	shl    $0x16,%eax
40003fcc:	8d 90 00 00 00 80    	lea    0x80000000(%eax),%edx
40003fd2:	8b 45 c4             	mov    0xffffffc4(%ebp),%eax
40003fd5:	8d 04 02             	lea    (%edx,%eax,1),%eax
40003fd8:	c7 45 f0 00 07 00 00 	movl   $0x700,0xfffffff0(%ebp)
40003fdf:	66 c7 45 ee 00 00    	movw   $0x0,0xffffffee(%ebp)
40003fe5:	c7 45 e8 00 00 00 00 	movl   $0x0,0xffffffe8(%ebp)
40003fec:	c7 45 e4 00 00 00 00 	movl   $0x0,0xffffffe4(%ebp)
40003ff3:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)
40003ff6:	89 4d dc             	mov    %ecx,0xffffffdc(%ebp)
static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40003ff9:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
40003ffc:	83 c8 02             	or     $0x2,%eax
40003fff:	8b 5d e8             	mov    0xffffffe8(%ebp),%ebx
40004002:	0f b7 55 ee          	movzwl 0xffffffee(%ebp),%edx
40004006:	8b 75 e4             	mov    0xffffffe4(%ebp),%esi
40004009:	8b 7d e0             	mov    0xffffffe0(%ebp),%edi
4000400c:	8b 4d dc             	mov    0xffffffdc(%ebp),%ecx
4000400f:	cd 30                	int    $0x30
				FILEDATA(ino) + oldpagelim,
				newpagelim - oldpagelim);
		fi->size = lim;
40004011:	8b 55 b8             	mov    0xffffffb8(%ebp),%edx
40004014:	8b 45 c0             	mov    0xffffffc0(%ebp),%eax
40004017:	89 42 4c             	mov    %eax,0x4c(%edx)
	}

	// Write the data.
	memmove(FILEDATA(ino) + ofs, buf, len);
4000401a:	8b 45 08             	mov    0x8(%ebp),%eax
4000401d:	c1 e0 16             	shl    $0x16,%eax
40004020:	8d 90 00 00 00 80    	lea    0x80000000(%eax),%edx
40004026:	8b 45 0c             	mov    0xc(%ebp),%eax
40004029:	01 c2                	add    %eax,%edx
4000402b:	8b 45 bc             	mov    0xffffffbc(%ebp),%eax
4000402e:	89 44 24 08          	mov    %eax,0x8(%esp)
40004032:	8b 45 10             	mov    0x10(%ebp),%eax
40004035:	89 44 24 04          	mov    %eax,0x4(%esp)
40004039:	89 14 24             	mov    %edx,(%esp)
4000403c:	e8 e1 f7 ff ff       	call   40003822 <memmove>
	return count;
40004041:	8b 45 18             	mov    0x18(%ebp),%eax
40004044:	89 45 b0             	mov    %eax,0xffffffb0(%ebp)
40004047:	8b 45 b0             	mov    0xffffffb0(%ebp),%eax
}
4000404a:	83 c4 5c             	add    $0x5c,%esp
4000404d:	5b                   	pop    %ebx
4000404e:	5e                   	pop    %esi
4000404f:	5f                   	pop    %edi
40004050:	5d                   	pop    %ebp
40004051:	c3                   	ret    

40004052 <fileino_stat>:

// Return file statistics about a particular inode.
// The specified inode must indicate a file that exists,
// but it can be any type of object: e.g., file, directory, special file, etc.
int
fileino_stat(int ino, struct stat *st)
{
40004052:	55                   	push   %ebp
40004053:	89 e5                	mov    %esp,%ebp
40004055:	83 ec 28             	sub    $0x28,%esp
	assert(fileino_exists(ino));
40004058:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
4000405c:	7e 3d                	jle    4000409b <fileino_stat+0x49>
4000405e:	81 7d 08 ff 00 00 00 	cmpl   $0xff,0x8(%ebp)
40004065:	7f 34                	jg     4000409b <fileino_stat+0x49>
40004067:	8b 15 30 61 00 40    	mov    0x40006130,%edx
4000406d:	8b 45 08             	mov    0x8(%ebp),%eax
40004070:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004073:	01 d0                	add    %edx,%eax
40004075:	05 10 10 00 00       	add    $0x1010,%eax
4000407a:	0f b6 40 04          	movzbl 0x4(%eax),%eax
4000407e:	84 c0                	test   %al,%al
40004080:	74 19                	je     4000409b <fileino_stat+0x49>
40004082:	8b 15 30 61 00 40    	mov    0x40006130,%edx
40004088:	8b 45 08             	mov    0x8(%ebp),%eax
4000408b:	6b c0 5c             	imul   $0x5c,%eax,%eax
4000408e:	01 d0                	add    %edx,%eax
40004090:	05 58 10 00 00       	add    $0x1058,%eax
40004095:	8b 00                	mov    (%eax),%eax
40004097:	85 c0                	test   %eax,%eax
40004099:	75 24                	jne    400040bf <fileino_stat+0x6d>
4000409b:	c7 44 24 0c 15 62 00 	movl   $0x40006215,0xc(%esp)
400040a2:	40 
400040a3:	c7 44 24 08 68 61 00 	movl   $0x40006168,0x8(%esp)
400040aa:	40 
400040ab:	c7 44 24 04 a6 00 00 	movl   $0xa6,0x4(%esp)
400040b2:	00 
400040b3:	c7 04 24 53 61 00 40 	movl   $0x40006153,(%esp)
400040ba:	e8 29 eb ff ff       	call   40002be8 <debug_panic>

	fileinode *fi = &files->fi[ino];
400040bf:	a1 30 61 00 40       	mov    0x40006130,%eax
400040c4:	8d 90 10 10 00 00    	lea    0x1010(%eax),%edx
400040ca:	8b 45 08             	mov    0x8(%ebp),%eax
400040cd:	6b c0 5c             	imul   $0x5c,%eax,%eax
400040d0:	8d 04 02             	lea    (%edx,%eax,1),%eax
400040d3:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	assert(fileino_isdir(fi->dino));	// Should be in a directory!
400040d6:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
400040d9:	8b 00                	mov    (%eax),%eax
400040db:	85 c0                	test   %eax,%eax
400040dd:	7e 4c                	jle    4000412b <fileino_stat+0xd9>
400040df:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
400040e2:	8b 00                	mov    (%eax),%eax
400040e4:	3d ff 00 00 00       	cmp    $0xff,%eax
400040e9:	7f 40                	jg     4000412b <fileino_stat+0xd9>
400040eb:	8b 15 30 61 00 40    	mov    0x40006130,%edx
400040f1:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
400040f4:	8b 00                	mov    (%eax),%eax
400040f6:	6b c0 5c             	imul   $0x5c,%eax,%eax
400040f9:	01 d0                	add    %edx,%eax
400040fb:	05 10 10 00 00       	add    $0x1010,%eax
40004100:	0f b6 40 04          	movzbl 0x4(%eax),%eax
40004104:	84 c0                	test   %al,%al
40004106:	74 23                	je     4000412b <fileino_stat+0xd9>
40004108:	8b 15 30 61 00 40    	mov    0x40006130,%edx
4000410e:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
40004111:	8b 00                	mov    (%eax),%eax
40004113:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004116:	01 d0                	add    %edx,%eax
40004118:	05 58 10 00 00       	add    $0x1058,%eax
4000411d:	8b 00                	mov    (%eax),%eax
4000411f:	25 00 70 00 00       	and    $0x7000,%eax
40004124:	3d 00 20 00 00       	cmp    $0x2000,%eax
40004129:	74 24                	je     4000414f <fileino_stat+0xfd>
4000412b:	c7 44 24 0c 29 62 00 	movl   $0x40006229,0xc(%esp)
40004132:	40 
40004133:	c7 44 24 08 68 61 00 	movl   $0x40006168,0x8(%esp)
4000413a:	40 
4000413b:	c7 44 24 04 a9 00 00 	movl   $0xa9,0x4(%esp)
40004142:	00 
40004143:	c7 04 24 53 61 00 40 	movl   $0x40006153,(%esp)
4000414a:	e8 99 ea ff ff       	call   40002be8 <debug_panic>
	st->st_ino = ino;
4000414f:	8b 55 0c             	mov    0xc(%ebp),%edx
40004152:	8b 45 08             	mov    0x8(%ebp),%eax
40004155:	89 02                	mov    %eax,(%edx)
	st->st_mode = fi->mode;
40004157:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
4000415a:	8b 50 48             	mov    0x48(%eax),%edx
4000415d:	8b 45 0c             	mov    0xc(%ebp),%eax
40004160:	89 50 04             	mov    %edx,0x4(%eax)
	st->st_size = fi->size;
40004163:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
40004166:	8b 40 4c             	mov    0x4c(%eax),%eax
40004169:	89 c2                	mov    %eax,%edx
4000416b:	8b 45 0c             	mov    0xc(%ebp),%eax
4000416e:	89 50 08             	mov    %edx,0x8(%eax)

	return 0;
40004171:	b8 00 00 00 00       	mov    $0x0,%eax
}
40004176:	c9                   	leave  
40004177:	c3                   	ret    

40004178 <fileino_truncate>:

// Grow or shrink a file to exactly a specified size.
// If growing a file, then fills the new space with zeros.
// Returns 0 if successful, or returns -1 and sets errno on error.
int
fileino_truncate(int ino, off_t newsize)
{
40004178:	55                   	push   %ebp
40004179:	89 e5                	mov    %esp,%ebp
4000417b:	57                   	push   %edi
4000417c:	56                   	push   %esi
4000417d:	53                   	push   %ebx
4000417e:	81 ec 8c 00 00 00    	sub    $0x8c,%esp
	assert(fileino_isvalid(ino));
40004184:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
40004188:	7e 09                	jle    40004193 <fileino_truncate+0x1b>
4000418a:	81 7d 08 ff 00 00 00 	cmpl   $0xff,0x8(%ebp)
40004191:	7e 24                	jle    400041b7 <fileino_truncate+0x3f>
40004193:	c7 44 24 0c 41 62 00 	movl   $0x40006241,0xc(%esp)
4000419a:	40 
4000419b:	c7 44 24 08 68 61 00 	movl   $0x40006168,0x8(%esp)
400041a2:	40 
400041a3:	c7 44 24 04 b7 00 00 	movl   $0xb7,0x4(%esp)
400041aa:	00 
400041ab:	c7 04 24 53 61 00 40 	movl   $0x40006153,(%esp)
400041b2:	e8 31 ea ff ff       	call   40002be8 <debug_panic>
	assert(newsize >= 0 && newsize <= FILE_MAXSIZE);
400041b7:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
400041bb:	78 09                	js     400041c6 <fileino_truncate+0x4e>
400041bd:	81 7d 0c 00 00 40 00 	cmpl   $0x400000,0xc(%ebp)
400041c4:	7e 24                	jle    400041ea <fileino_truncate+0x72>
400041c6:	c7 44 24 0c 58 62 00 	movl   $0x40006258,0xc(%esp)
400041cd:	40 
400041ce:	c7 44 24 08 68 61 00 	movl   $0x40006168,0x8(%esp)
400041d5:	40 
400041d6:	c7 44 24 04 b8 00 00 	movl   $0xb8,0x4(%esp)
400041dd:	00 
400041de:	c7 04 24 53 61 00 40 	movl   $0x40006153,(%esp)
400041e5:	e8 fe e9 ff ff       	call   40002be8 <debug_panic>

	size_t oldsize = files->fi[ino].size;
400041ea:	8b 15 30 61 00 40    	mov    0x40006130,%edx
400041f0:	8b 45 08             	mov    0x8(%ebp),%eax
400041f3:	6b c0 5c             	imul   $0x5c,%eax,%eax
400041f6:	01 d0                	add    %edx,%eax
400041f8:	05 5c 10 00 00       	add    $0x105c,%eax
400041fd:	8b 00                	mov    (%eax),%eax
400041ff:	89 45 90             	mov    %eax,0xffffff90(%ebp)
	size_t oldpagelim = ROUNDUP(files->fi[ino].size, PAGESIZE);
40004202:	c7 45 9c 00 10 00 00 	movl   $0x1000,0xffffff9c(%ebp)
40004209:	8b 15 30 61 00 40    	mov    0x40006130,%edx
4000420f:	8b 45 08             	mov    0x8(%ebp),%eax
40004212:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004215:	01 d0                	add    %edx,%eax
40004217:	05 5c 10 00 00       	add    $0x105c,%eax
4000421c:	8b 00                	mov    (%eax),%eax
4000421e:	03 45 9c             	add    0xffffff9c(%ebp),%eax
40004221:	83 e8 01             	sub    $0x1,%eax
40004224:	89 45 a0             	mov    %eax,0xffffffa0(%ebp)
40004227:	8b 45 a0             	mov    0xffffffa0(%ebp),%eax
4000422a:	ba 00 00 00 00       	mov    $0x0,%edx
4000422f:	f7 75 9c             	divl   0xffffff9c(%ebp)
40004232:	8b 45 a0             	mov    0xffffffa0(%ebp),%eax
40004235:	29 d0                	sub    %edx,%eax
40004237:	89 45 94             	mov    %eax,0xffffff94(%ebp)
	size_t newpagelim = ROUNDUP(newsize, PAGESIZE);
4000423a:	c7 45 a4 00 10 00 00 	movl   $0x1000,0xffffffa4(%ebp)
40004241:	8b 45 0c             	mov    0xc(%ebp),%eax
40004244:	03 45 a4             	add    0xffffffa4(%ebp),%eax
40004247:	83 e8 01             	sub    $0x1,%eax
4000424a:	89 45 a8             	mov    %eax,0xffffffa8(%ebp)
4000424d:	8b 45 a8             	mov    0xffffffa8(%ebp),%eax
40004250:	ba 00 00 00 00       	mov    $0x0,%edx
40004255:	f7 75 a4             	divl   0xffffffa4(%ebp)
40004258:	8b 45 a8             	mov    0xffffffa8(%ebp),%eax
4000425b:	29 d0                	sub    %edx,%eax
4000425d:	89 45 98             	mov    %eax,0xffffff98(%ebp)
	if (newsize > oldsize) {
40004260:	8b 45 0c             	mov    0xc(%ebp),%eax
40004263:	3b 45 90             	cmp    0xffffff90(%ebp),%eax
40004266:	0f 86 88 00 00 00    	jbe    400042f4 <fileino_truncate+0x17c>
		// Grow the file and fill the new space with zeros.
		sys_get(SYS_PERM | SYS_READ | SYS_WRITE, 0, NULL, NULL,
4000426c:	8b 55 94             	mov    0xffffff94(%ebp),%edx
4000426f:	8b 45 98             	mov    0xffffff98(%ebp),%eax
40004272:	89 c1                	mov    %eax,%ecx
40004274:	29 d1                	sub    %edx,%ecx
40004276:	8b 45 08             	mov    0x8(%ebp),%eax
40004279:	c1 e0 16             	shl    $0x16,%eax
4000427c:	8d 90 00 00 00 80    	lea    0x80000000(%eax),%edx
40004282:	8b 45 94             	mov    0xffffff94(%ebp),%eax
40004285:	8d 04 02             	lea    (%edx,%eax,1),%eax
40004288:	c7 45 c0 00 07 00 00 	movl   $0x700,0xffffffc0(%ebp)
4000428f:	66 c7 45 be 00 00    	movw   $0x0,0xffffffbe(%ebp)
40004295:	c7 45 b8 00 00 00 00 	movl   $0x0,0xffffffb8(%ebp)
4000429c:	c7 45 b4 00 00 00 00 	movl   $0x0,0xffffffb4(%ebp)
400042a3:	89 45 b0             	mov    %eax,0xffffffb0(%ebp)
400042a6:	89 4d ac             	mov    %ecx,0xffffffac(%ebp)
static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
400042a9:	8b 45 c0             	mov    0xffffffc0(%ebp),%eax
400042ac:	83 c8 02             	or     $0x2,%eax
400042af:	8b 5d b8             	mov    0xffffffb8(%ebp),%ebx
400042b2:	0f b7 55 be          	movzwl 0xffffffbe(%ebp),%edx
400042b6:	8b 75 b4             	mov    0xffffffb4(%ebp),%esi
400042b9:	8b 7d b0             	mov    0xffffffb0(%ebp),%edi
400042bc:	8b 4d ac             	mov    0xffffffac(%ebp),%ecx
400042bf:	cd 30                	int    $0x30
			FILEDATA(ino) + oldpagelim,
			newpagelim - oldpagelim);
		memset(FILEDATA(ino) + oldsize, 0, newsize - oldsize);
400042c1:	8b 45 0c             	mov    0xc(%ebp),%eax
400042c4:	89 c1                	mov    %eax,%ecx
400042c6:	2b 4d 90             	sub    0xffffff90(%ebp),%ecx
400042c9:	8b 45 08             	mov    0x8(%ebp),%eax
400042cc:	c1 e0 16             	shl    $0x16,%eax
400042cf:	8d 90 00 00 00 80    	lea    0x80000000(%eax),%edx
400042d5:	8b 45 90             	mov    0xffffff90(%ebp),%eax
400042d8:	8d 04 02             	lea    (%edx,%eax,1),%eax
400042db:	89 4c 24 08          	mov    %ecx,0x8(%esp)
400042df:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400042e6:	00 
400042e7:	89 04 24             	mov    %eax,(%esp)
400042ea:	e8 ba f4 ff ff       	call   400037a9 <memset>
400042ef:	e9 a5 00 00 00       	jmp    40004399 <fileino_truncate+0x221>
	} else if (newsize > 0) {
400042f4:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
400042f8:	7e 57                	jle    40004351 <fileino_truncate+0x1d9>
		// Shrink the file, but not all the way to empty.
		// Would prefer to use SYS_ZERO to free the file content,
		// but SYS_ZERO isn't guaranteed to work at page granularity.
		sys_get(SYS_PERM, 0, NULL, NULL,
400042fa:	b8 00 00 40 00       	mov    $0x400000,%eax
400042ff:	89 c1                	mov    %eax,%ecx
40004301:	2b 4d 98             	sub    0xffffff98(%ebp),%ecx
40004304:	8b 45 08             	mov    0x8(%ebp),%eax
40004307:	c1 e0 16             	shl    $0x16,%eax
4000430a:	8d 90 00 00 00 80    	lea    0x80000000(%eax),%edx
40004310:	8b 45 98             	mov    0xffffff98(%ebp),%eax
40004313:	8d 04 02             	lea    (%edx,%eax,1),%eax
40004316:	c7 45 d8 00 01 00 00 	movl   $0x100,0xffffffd8(%ebp)
4000431d:	66 c7 45 d6 00 00    	movw   $0x0,0xffffffd6(%ebp)
40004323:	c7 45 d0 00 00 00 00 	movl   $0x0,0xffffffd0(%ebp)
4000432a:	c7 45 cc 00 00 00 00 	movl   $0x0,0xffffffcc(%ebp)
40004331:	89 45 c8             	mov    %eax,0xffffffc8(%ebp)
40004334:	89 4d c4             	mov    %ecx,0xffffffc4(%ebp)
static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40004337:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
4000433a:	83 c8 02             	or     $0x2,%eax
4000433d:	8b 5d d0             	mov    0xffffffd0(%ebp),%ebx
40004340:	0f b7 55 d6          	movzwl 0xffffffd6(%ebp),%edx
40004344:	8b 75 cc             	mov    0xffffffcc(%ebp),%esi
40004347:	8b 7d c8             	mov    0xffffffc8(%ebp),%edi
4000434a:	8b 4d c4             	mov    0xffffffc4(%ebp),%ecx
4000434d:	cd 30                	int    $0x30
4000434f:	eb 48                	jmp    40004399 <fileino_truncate+0x221>
			FILEDATA(ino) + newpagelim, FILE_MAXSIZE - newpagelim);
	} else {
		// Shrink the file to empty.  Use SYS_ZERO to free completely.
		sys_get(SYS_ZERO, 0, NULL, NULL, FILEDATA(ino), FILE_MAXSIZE);
40004351:	8b 45 08             	mov    0x8(%ebp),%eax
40004354:	c1 e0 16             	shl    $0x16,%eax
40004357:	2d 00 00 00 80       	sub    $0x80000000,%eax
4000435c:	c7 45 f0 00 00 01 00 	movl   $0x10000,0xfffffff0(%ebp)
40004363:	66 c7 45 ee 00 00    	movw   $0x0,0xffffffee(%ebp)
40004369:	c7 45 e8 00 00 00 00 	movl   $0x0,0xffffffe8(%ebp)
40004370:	c7 45 e4 00 00 00 00 	movl   $0x0,0xffffffe4(%ebp)
40004377:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)
4000437a:	c7 45 dc 00 00 40 00 	movl   $0x400000,0xffffffdc(%ebp)
static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40004381:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
40004384:	83 c8 02             	or     $0x2,%eax
40004387:	8b 5d e8             	mov    0xffffffe8(%ebp),%ebx
4000438a:	0f b7 55 ee          	movzwl 0xffffffee(%ebp),%edx
4000438e:	8b 75 e4             	mov    0xffffffe4(%ebp),%esi
40004391:	8b 7d e0             	mov    0xffffffe0(%ebp),%edi
40004394:	8b 4d dc             	mov    0xffffffdc(%ebp),%ecx
40004397:	cd 30                	int    $0x30
	}
	files->fi[ino].size = newsize;
40004399:	8b 15 30 61 00 40    	mov    0x40006130,%edx
4000439f:	8b 45 08             	mov    0x8(%ebp),%eax
400043a2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
400043a5:	6b c0 5c             	imul   $0x5c,%eax,%eax
400043a8:	01 d0                	add    %edx,%eax
400043aa:	05 5c 10 00 00       	add    $0x105c,%eax
400043af:	89 08                	mov    %ecx,(%eax)
	files->fi[ino].ver++;	// truncation is always an exclusive change
400043b1:	8b 1d 30 61 00 40    	mov    0x40006130,%ebx
400043b7:	8b 55 08             	mov    0x8(%ebp),%edx
400043ba:	6b c2 5c             	imul   $0x5c,%edx,%eax
400043bd:	01 d8                	add    %ebx,%eax
400043bf:	05 54 10 00 00       	add    $0x1054,%eax
400043c4:	8b 00                	mov    (%eax),%eax
400043c6:	8d 48 01             	lea    0x1(%eax),%ecx
400043c9:	6b c2 5c             	imul   $0x5c,%edx,%eax
400043cc:	01 d8                	add    %ebx,%eax
400043ce:	05 54 10 00 00       	add    $0x1054,%eax
400043d3:	89 08                	mov    %ecx,(%eax)
	return 0;
400043d5:	b8 00 00 00 00       	mov    $0x0,%eax
}
400043da:	81 c4 8c 00 00 00    	add    $0x8c,%esp
400043e0:	5b                   	pop    %ebx
400043e1:	5e                   	pop    %esi
400043e2:	5f                   	pop    %edi
400043e3:	5d                   	pop    %ebp
400043e4:	c3                   	ret    

400043e5 <fileino_flush>:

// Flush any outstanding writes on this file to our parent process.
// (XXX should flushes propagate across multiple levels?)
int
fileino_flush(int ino)
{
400043e5:	55                   	push   %ebp
400043e6:	89 e5                	mov    %esp,%ebp
400043e8:	83 ec 18             	sub    $0x18,%esp
	assert(fileino_isvalid(ino));
400043eb:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
400043ef:	7e 09                	jle    400043fa <fileino_flush+0x15>
400043f1:	81 7d 08 ff 00 00 00 	cmpl   $0xff,0x8(%ebp)
400043f8:	7e 24                	jle    4000441e <fileino_flush+0x39>
400043fa:	c7 44 24 0c 41 62 00 	movl   $0x40006241,0xc(%esp)
40004401:	40 
40004402:	c7 44 24 08 68 61 00 	movl   $0x40006168,0x8(%esp)
40004409:	40 
4000440a:	c7 44 24 04 d7 00 00 	movl   $0xd7,0x4(%esp)
40004411:	00 
40004412:	c7 04 24 53 61 00 40 	movl   $0x40006153,(%esp)
40004419:	e8 ca e7 ff ff       	call   40002be8 <debug_panic>

	if (files->fi[ino].size > files->fi[ino].rlen)
4000441e:	8b 15 30 61 00 40    	mov    0x40006130,%edx
40004424:	8b 45 08             	mov    0x8(%ebp),%eax
40004427:	6b c0 5c             	imul   $0x5c,%eax,%eax
4000442a:	01 d0                	add    %edx,%eax
4000442c:	05 5c 10 00 00       	add    $0x105c,%eax
40004431:	8b 08                	mov    (%eax),%ecx
40004433:	8b 15 30 61 00 40    	mov    0x40006130,%edx
40004439:	8b 45 08             	mov    0x8(%ebp),%eax
4000443c:	6b c0 5c             	imul   $0x5c,%eax,%eax
4000443f:	01 d0                	add    %edx,%eax
40004441:	05 68 10 00 00       	add    $0x1068,%eax
40004446:	8b 00                	mov    (%eax),%eax
40004448:	39 c1                	cmp    %eax,%ecx
4000444a:	76 07                	jbe    40004453 <fileino_flush+0x6e>

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
4000444c:	b8 03 00 00 00       	mov    $0x3,%eax
40004451:	cd 30                	int    $0x30
		sys_ret();	// synchronize and reconcile with parent
	return 0;
40004453:	b8 00 00 00 00       	mov    $0x0,%eax
}
40004458:	c9                   	leave  
40004459:	c3                   	ret    

4000445a <filedesc_alloc>:


////////// File descriptor functions //////////

// Search the file descriptor table for the first free file descriptor,
// and return a pointer to that file descriptor.
// If no file descriptors are available,
// returns NULL and set errno appropriately.
filedesc *filedesc_alloc(void)
{
4000445a:	55                   	push   %ebp
4000445b:	89 e5                	mov    %esp,%ebp
4000445d:	83 ec 14             	sub    $0x14,%esp
	int i;
	for (i = 0; i < OPEN_MAX; i++)
40004460:	c7 45 fc 00 00 00 00 	movl   $0x0,0xfffffffc(%ebp)
40004467:	eb 30                	jmp    40004499 <filedesc_alloc+0x3f>
		if (files->fd[i].ino == FILEINO_NULL)
40004469:	8b 15 30 61 00 40    	mov    0x40006130,%edx
4000446f:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
40004472:	c1 e0 04             	shl    $0x4,%eax
40004475:	01 d0                	add    %edx,%eax
40004477:	83 c0 10             	add    $0x10,%eax
4000447a:	8b 00                	mov    (%eax),%eax
4000447c:	85 c0                	test   %eax,%eax
4000447e:	75 15                	jne    40004495 <filedesc_alloc+0x3b>
			return &files->fd[i];
40004480:	a1 30 61 00 40       	mov    0x40006130,%eax
40004485:	8d 50 10             	lea    0x10(%eax),%edx
40004488:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
4000448b:	c1 e0 04             	shl    $0x4,%eax
4000448e:	01 c2                	add    %eax,%edx
40004490:	89 55 ec             	mov    %edx,0xffffffec(%ebp)
40004493:	eb 1f                	jmp    400044b4 <filedesc_alloc+0x5a>
40004495:	83 45 fc 01          	addl   $0x1,0xfffffffc(%ebp)
40004499:	81 7d fc ff 00 00 00 	cmpl   $0xff,0xfffffffc(%ebp)
400044a0:	7e c7                	jle    40004469 <filedesc_alloc+0xf>
	errno = EMFILE;
400044a2:	a1 30 61 00 40       	mov    0x40006130,%eax
400044a7:	c7 00 04 00 00 00    	movl   $0x4,(%eax)
	return NULL;
400044ad:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
400044b4:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
}
400044b7:	c9                   	leave  
400044b8:	c3                   	ret    

400044b9 <filedesc_open>:

// Find or create and open a file, optionally using a given file descriptor.
// The argument 'fd' must point to a currently unused file descriptor,
// or may be NULL, in which case this function finds an unused file descriptor.
// The 'openflags' determines whether the file is created, truncated, etc.
// Returns the opened file descriptor on success,
// or returns NULL and sets errno on failure.
filedesc *
filedesc_open(filedesc *fd, const char *path, int openflags, mode_t mode)
{
400044b9:	55                   	push   %ebp
400044ba:	89 e5                	mov    %esp,%ebp
400044bc:	83 ec 38             	sub    $0x38,%esp
	if (!fd && !(fd = filedesc_alloc()))
400044bf:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
400044c3:	75 1a                	jne    400044df <filedesc_open+0x26>
400044c5:	e8 90 ff ff ff       	call   4000445a <filedesc_alloc>
400044ca:	89 45 08             	mov    %eax,0x8(%ebp)
400044cd:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
400044d1:	75 0c                	jne    400044df <filedesc_open+0x26>
		return NULL;
400044d3:	c7 45 e4 00 00 00 00 	movl   $0x0,0xffffffe4(%ebp)
400044da:	e9 24 02 00 00       	jmp    40004703 <filedesc_open+0x24a>
	assert(fd->ino == FILEINO_NULL);
400044df:	8b 45 08             	mov    0x8(%ebp),%eax
400044e2:	8b 00                	mov    (%eax),%eax
400044e4:	85 c0                	test   %eax,%eax
400044e6:	74 24                	je     4000450c <filedesc_open+0x53>
400044e8:	c7 44 24 0c 80 62 00 	movl   $0x40006280,0xc(%esp)
400044ef:	40 
400044f0:	c7 44 24 08 68 61 00 	movl   $0x40006168,0x8(%esp)
400044f7:	40 
400044f8:	c7 44 24 04 fa 00 00 	movl   $0xfa,0x4(%esp)
400044ff:	00 
40004500:	c7 04 24 53 61 00 40 	movl   $0x40006153,(%esp)
40004507:	e8 dc e6 ff ff       	call   40002be8 <debug_panic>

	// Determine the complete file mode if it is to be created.
	mode_t createmode = (openflags & O_CREAT) ? S_IFREG | (mode & 0777) : 0;
4000450c:	8b 45 10             	mov    0x10(%ebp),%eax
4000450f:	83 e0 20             	and    $0x20,%eax
40004512:	85 c0                	test   %eax,%eax
40004514:	74 12                	je     40004528 <filedesc_open+0x6f>
40004516:	8b 45 14             	mov    0x14(%ebp),%eax
40004519:	25 ff 01 00 00       	and    $0x1ff,%eax
4000451e:	89 c2                	mov    %eax,%edx
40004520:	80 ce 10             	or     $0x10,%dh
40004523:	89 55 e8             	mov    %edx,0xffffffe8(%ebp)
40004526:	eb 07                	jmp    4000452f <filedesc_open+0x76>
40004528:	c7 45 e8 00 00 00 00 	movl   $0x0,0xffffffe8(%ebp)
4000452f:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
40004532:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)

	// Walk the directory tree to find the desired directory entry,
	// creating an entry if it doesn't exist and O_CREAT is set.
	int ino = dir_walk(path, createmode);
40004535:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
40004538:	89 44 24 04          	mov    %eax,0x4(%esp)
4000453c:	8b 45 0c             	mov    0xc(%ebp),%eax
4000453f:	89 04 24             	mov    %eax,(%esp)
40004542:	e8 01 06 00 00       	call   40004b48 <dir_walk>
40004547:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	if (ino < 0)
4000454a:	83 7d fc 00          	cmpl   $0x0,0xfffffffc(%ebp)
4000454e:	79 0c                	jns    4000455c <filedesc_open+0xa3>
		return NULL;
40004550:	c7 45 e4 00 00 00 00 	movl   $0x0,0xffffffe4(%ebp)
40004557:	e9 a7 01 00 00       	jmp    40004703 <filedesc_open+0x24a>
	assert(fileino_exists(ino));
4000455c:	83 7d fc 00          	cmpl   $0x0,0xfffffffc(%ebp)
40004560:	7e 3d                	jle    4000459f <filedesc_open+0xe6>
40004562:	81 7d fc ff 00 00 00 	cmpl   $0xff,0xfffffffc(%ebp)
40004569:	7f 34                	jg     4000459f <filedesc_open+0xe6>
4000456b:	8b 15 30 61 00 40    	mov    0x40006130,%edx
40004571:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
40004574:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004577:	01 d0                	add    %edx,%eax
40004579:	05 10 10 00 00       	add    $0x1010,%eax
4000457e:	0f b6 40 04          	movzbl 0x4(%eax),%eax
40004582:	84 c0                	test   %al,%al
40004584:	74 19                	je     4000459f <filedesc_open+0xe6>
40004586:	8b 15 30 61 00 40    	mov    0x40006130,%edx
4000458c:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
4000458f:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004592:	01 d0                	add    %edx,%eax
40004594:	05 58 10 00 00       	add    $0x1058,%eax
40004599:	8b 00                	mov    (%eax),%eax
4000459b:	85 c0                	test   %eax,%eax
4000459d:	75 24                	jne    400045c3 <filedesc_open+0x10a>
4000459f:	c7 44 24 0c 15 62 00 	movl   $0x40006215,0xc(%esp)
400045a6:	40 
400045a7:	c7 44 24 08 68 61 00 	movl   $0x40006168,0x8(%esp)
400045ae:	40 
400045af:	c7 44 24 04 04 01 00 	movl   $0x104,0x4(%esp)
400045b6:	00 
400045b7:	c7 04 24 53 61 00 40 	movl   $0x40006153,(%esp)
400045be:	e8 25 e6 ff ff       	call   40002be8 <debug_panic>

	// Refuse to open conflict-marked files;
	// the user needs to resolve the conflict and clear the conflict flag,
	// or just delete the conflicted file.
	if (files->fi[ino].mode & S_IFCONF) {
400045c3:	8b 15 30 61 00 40    	mov    0x40006130,%edx
400045c9:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
400045cc:	6b c0 5c             	imul   $0x5c,%eax,%eax
400045cf:	01 d0                	add    %edx,%eax
400045d1:	05 58 10 00 00       	add    $0x1058,%eax
400045d6:	8b 00                	mov    (%eax),%eax
400045d8:	25 00 00 01 00       	and    $0x10000,%eax
400045dd:	85 c0                	test   %eax,%eax
400045df:	74 17                	je     400045f8 <filedesc_open+0x13f>
		errno = ECONFLICT;
400045e1:	a1 30 61 00 40       	mov    0x40006130,%eax
400045e6:	c7 00 0a 00 00 00    	movl   $0xa,(%eax)
		return NULL;
400045ec:	c7 45 e4 00 00 00 00 	movl   $0x0,0xffffffe4(%ebp)
400045f3:	e9 0b 01 00 00       	jmp    40004703 <filedesc_open+0x24a>
	}

	// Truncate the file if we were asked to
	if (openflags & O_TRUNC) {
400045f8:	8b 45 10             	mov    0x10(%ebp),%eax
400045fb:	83 e0 40             	and    $0x40,%eax
400045fe:	85 c0                	test   %eax,%eax
40004600:	74 60                	je     40004662 <filedesc_open+0x1a9>
		if (!(openflags & O_WRONLY)) {
40004602:	8b 45 10             	mov    0x10(%ebp),%eax
40004605:	83 e0 02             	and    $0x2,%eax
40004608:	85 c0                	test   %eax,%eax
4000460a:	75 33                	jne    4000463f <filedesc_open+0x186>
			warn("filedesc_open: can't truncate non-writable file");
4000460c:	c7 44 24 08 98 62 00 	movl   $0x40006298,0x8(%esp)
40004613:	40 
40004614:	c7 44 24 04 11 01 00 	movl   $0x111,0x4(%esp)
4000461b:	00 
4000461c:	c7 04 24 53 61 00 40 	movl   $0x40006153,(%esp)
40004623:	e8 2a e6 ff ff       	call   40002c52 <debug_warn>
			errno = EINVAL;
40004628:	a1 30 61 00 40       	mov    0x40006130,%eax
4000462d:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
			return NULL;
40004633:	c7 45 e4 00 00 00 00 	movl   $0x0,0xffffffe4(%ebp)
4000463a:	e9 c4 00 00 00       	jmp    40004703 <filedesc_open+0x24a>
		}
		if (fileino_truncate(ino, 0) < 0)
4000463f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40004646:	00 
40004647:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
4000464a:	89 04 24             	mov    %eax,(%esp)
4000464d:	e8 26 fb ff ff       	call   40004178 <fileino_truncate>
40004652:	85 c0                	test   %eax,%eax
40004654:	79 0c                	jns    40004662 <filedesc_open+0x1a9>
			return NULL;
40004656:	c7 45 e4 00 00 00 00 	movl   $0x0,0xffffffe4(%ebp)
4000465d:	e9 a1 00 00 00       	jmp    40004703 <filedesc_open+0x24a>
	}

	// Initialize the file descriptor
	fd->ino = ino;
40004662:	8b 55 08             	mov    0x8(%ebp),%edx
40004665:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
40004668:	89 02                	mov    %eax,(%edx)
	fd->flags = openflags;
4000466a:	8b 55 08             	mov    0x8(%ebp),%edx
4000466d:	8b 45 10             	mov    0x10(%ebp),%eax
40004670:	89 42 04             	mov    %eax,0x4(%edx)
	fd->ofs = (openflags & O_APPEND) ? files->fi[ino].size : 0;
40004673:	8b 45 10             	mov    0x10(%ebp),%eax
40004676:	83 e0 10             	and    $0x10,%eax
40004679:	85 c0                	test   %eax,%eax
4000467b:	74 1a                	je     40004697 <filedesc_open+0x1de>
4000467d:	8b 15 30 61 00 40    	mov    0x40006130,%edx
40004683:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
40004686:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004689:	01 d0                	add    %edx,%eax
4000468b:	05 5c 10 00 00       	add    $0x105c,%eax
40004690:	8b 00                	mov    (%eax),%eax
40004692:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
40004695:	eb 07                	jmp    4000469e <filedesc_open+0x1e5>
40004697:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
4000469e:	8b 45 08             	mov    0x8(%ebp),%eax
400046a1:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
400046a4:	89 50 08             	mov    %edx,0x8(%eax)
	fd->err = 0;
400046a7:	8b 45 08             	mov    0x8(%ebp),%eax
400046aa:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)

	assert(filedesc_isopen(fd));
400046b1:	a1 30 61 00 40       	mov    0x40006130,%eax
400046b6:	83 c0 10             	add    $0x10,%eax
400046b9:	3b 45 08             	cmp    0x8(%ebp),%eax
400046bc:	77 1b                	ja     400046d9 <filedesc_open+0x220>
400046be:	a1 30 61 00 40       	mov    0x40006130,%eax
400046c3:	83 c0 10             	add    $0x10,%eax
400046c6:	05 00 10 00 00       	add    $0x1000,%eax
400046cb:	3b 45 08             	cmp    0x8(%ebp),%eax
400046ce:	76 09                	jbe    400046d9 <filedesc_open+0x220>
400046d0:	8b 45 08             	mov    0x8(%ebp),%eax
400046d3:	8b 00                	mov    (%eax),%eax
400046d5:	85 c0                	test   %eax,%eax
400046d7:	75 24                	jne    400046fd <filedesc_open+0x244>
400046d9:	c7 44 24 0c c8 62 00 	movl   $0x400062c8,0xc(%esp)
400046e0:	40 
400046e1:	c7 44 24 08 68 61 00 	movl   $0x40006168,0x8(%esp)
400046e8:	40 
400046e9:	c7 44 24 04 1f 01 00 	movl   $0x11f,0x4(%esp)
400046f0:	00 
400046f1:	c7 04 24 53 61 00 40 	movl   $0x40006153,(%esp)
400046f8:	e8 eb e4 ff ff       	call   40002be8 <debug_panic>
	return fd;
400046fd:	8b 45 08             	mov    0x8(%ebp),%eax
40004700:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
40004703:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
}
40004706:	c9                   	leave  
40004707:	c3                   	ret    

40004708 <filedesc_read>:

// Read up to 'count' objects each of size 'eltsize'
// from the open file described by 'fd' into memory buffer 'buf',
// whose size must be at least 'count * eltsize' bytes.
// May read fewer than the requested number of objects
// if the end of file is reached, but always an integral number of objects.
// On success, returns the number of objects read (NOT the number of bytes).
// If an error (other than end-of-file) occurs, returns -1 and sets errno.
//
// If the file is a special device input file such as the console,
// this function pretends the file has no end and instead
// uses sys_ret() to wait for the file to extend the special file.
ssize_t
filedesc_read(filedesc *fd, void *buf, size_t eltsize, size_t count)
{
40004708:	55                   	push   %ebp
40004709:	89 e5                	mov    %esp,%ebp
4000470b:	83 ec 28             	sub    $0x28,%esp
	assert(filedesc_isreadable(fd));
4000470e:	a1 30 61 00 40       	mov    0x40006130,%eax
40004713:	83 c0 10             	add    $0x10,%eax
40004716:	3b 45 08             	cmp    0x8(%ebp),%eax
40004719:	77 28                	ja     40004743 <filedesc_read+0x3b>
4000471b:	a1 30 61 00 40       	mov    0x40006130,%eax
40004720:	83 c0 10             	add    $0x10,%eax
40004723:	05 00 10 00 00       	add    $0x1000,%eax
40004728:	3b 45 08             	cmp    0x8(%ebp),%eax
4000472b:	76 16                	jbe    40004743 <filedesc_read+0x3b>
4000472d:	8b 45 08             	mov    0x8(%ebp),%eax
40004730:	8b 00                	mov    (%eax),%eax
40004732:	85 c0                	test   %eax,%eax
40004734:	74 0d                	je     40004743 <filedesc_read+0x3b>
40004736:	8b 45 08             	mov    0x8(%ebp),%eax
40004739:	8b 40 04             	mov    0x4(%eax),%eax
4000473c:	83 e0 01             	and    $0x1,%eax
4000473f:	85 c0                	test   %eax,%eax
40004741:	75 24                	jne    40004767 <filedesc_read+0x5f>
40004743:	c7 44 24 0c dc 62 00 	movl   $0x400062dc,0xc(%esp)
4000474a:	40 
4000474b:	c7 44 24 08 68 61 00 	movl   $0x40006168,0x8(%esp)
40004752:	40 
40004753:	c7 44 24 04 31 01 00 	movl   $0x131,0x4(%esp)
4000475a:	00 
4000475b:	c7 04 24 53 61 00 40 	movl   $0x40006153,(%esp)
40004762:	e8 81 e4 ff ff       	call   40002be8 <debug_panic>
	fileinode *fi = &files->fi[fd->ino];
40004767:	a1 30 61 00 40       	mov    0x40006130,%eax
4000476c:	8d 90 10 10 00 00    	lea    0x1010(%eax),%edx
40004772:	8b 45 08             	mov    0x8(%ebp),%eax
40004775:	8b 00                	mov    (%eax),%eax
40004777:	6b c0 5c             	imul   $0x5c,%eax,%eax
4000477a:	8d 04 02             	lea    (%edx,%eax,1),%eax
4000477d:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)

	ssize_t actual = fileino_read(fd->ino, fd->ofs, buf, eltsize, count);
40004780:	8b 45 08             	mov    0x8(%ebp),%eax
40004783:	8b 50 08             	mov    0x8(%eax),%edx
40004786:	8b 45 08             	mov    0x8(%ebp),%eax
40004789:	8b 08                	mov    (%eax),%ecx
4000478b:	8b 45 14             	mov    0x14(%ebp),%eax
4000478e:	89 44 24 10          	mov    %eax,0x10(%esp)
40004792:	8b 45 10             	mov    0x10(%ebp),%eax
40004795:	89 44 24 0c          	mov    %eax,0xc(%esp)
40004799:	8b 45 0c             	mov    0xc(%ebp),%eax
4000479c:	89 44 24 08          	mov    %eax,0x8(%esp)
400047a0:	89 54 24 04          	mov    %edx,0x4(%esp)
400047a4:	89 0c 24             	mov    %ecx,(%esp)
400047a7:	e8 75 f4 ff ff       	call   40003c21 <fileino_read>
400047ac:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	if (actual < 0) {
400047af:	83 7d fc 00          	cmpl   $0x0,0xfffffffc(%ebp)
400047b3:	79 16                	jns    400047cb <filedesc_read+0xc3>
		fd->err = errno;	// save error indication for ferror()
400047b5:	a1 30 61 00 40       	mov    0x40006130,%eax
400047ba:	8b 10                	mov    (%eax),%edx
400047bc:	8b 45 08             	mov    0x8(%ebp),%eax
400047bf:	89 50 0c             	mov    %edx,0xc(%eax)
		return -1;
400047c2:	c7 45 ec ff ff ff ff 	movl   $0xffffffff,0xffffffec(%ebp)
400047c9:	eb 5a                	jmp    40004825 <filedesc_read+0x11d>
	}

	// Advance the file position
	fd->ofs += eltsize * actual;
400047cb:	8b 45 08             	mov    0x8(%ebp),%eax
400047ce:	8b 40 08             	mov    0x8(%eax),%eax
400047d1:	89 c2                	mov    %eax,%edx
400047d3:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
400047d6:	0f af 45 10          	imul   0x10(%ebp),%eax
400047da:	8d 04 02             	lea    (%edx,%eax,1),%eax
400047dd:	89 c2                	mov    %eax,%edx
400047df:	8b 45 08             	mov    0x8(%ebp),%eax
400047e2:	89 50 08             	mov    %edx,0x8(%eax)
	assert(actual == 0 || fi->size >= fd->ofs);
400047e5:	83 7d fc 00          	cmpl   $0x0,0xfffffffc(%ebp)
400047e9:	74 34                	je     4000481f <filedesc_read+0x117>
400047eb:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
400047ee:	8b 50 4c             	mov    0x4c(%eax),%edx
400047f1:	8b 45 08             	mov    0x8(%ebp),%eax
400047f4:	8b 40 08             	mov    0x8(%eax),%eax
400047f7:	39 c2                	cmp    %eax,%edx
400047f9:	73 24                	jae    4000481f <filedesc_read+0x117>
400047fb:	c7 44 24 0c f4 62 00 	movl   $0x400062f4,0xc(%esp)
40004802:	40 
40004803:	c7 44 24 08 68 61 00 	movl   $0x40006168,0x8(%esp)
4000480a:	40 
4000480b:	c7 44 24 04 3c 01 00 	movl   $0x13c,0x4(%esp)
40004812:	00 
40004813:	c7 04 24 53 61 00 40 	movl   $0x40006153,(%esp)
4000481a:	e8 c9 e3 ff ff       	call   40002be8 <debug_panic>

	return actual;
4000481f:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
40004822:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
40004825:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
}
40004828:	c9                   	leave  
40004829:	c3                   	ret    

4000482a <filedesc_write>:

// Write up to 'count' objects each of size 'eltsize'
// from memory buffer 'buf' to the open file described by 'fd'.
// The size of 'buf' must be at least 'count * eltsize' bytes.
// On success, returns the number of objects written (NOT the number of bytes).
// If an error occurs, returns -1 and sets errno appropriately.
ssize_t
filedesc_write(filedesc *fd, const void *buf, size_t eltsize, size_t count)
{
4000482a:	55                   	push   %ebp
4000482b:	89 e5                	mov    %esp,%ebp
4000482d:	83 ec 28             	sub    $0x28,%esp
	assert(filedesc_iswritable(fd));
40004830:	a1 30 61 00 40       	mov    0x40006130,%eax
40004835:	83 c0 10             	add    $0x10,%eax
40004838:	3b 45 08             	cmp    0x8(%ebp),%eax
4000483b:	77 28                	ja     40004865 <filedesc_write+0x3b>
4000483d:	a1 30 61 00 40       	mov    0x40006130,%eax
40004842:	83 c0 10             	add    $0x10,%eax
40004845:	05 00 10 00 00       	add    $0x1000,%eax
4000484a:	3b 45 08             	cmp    0x8(%ebp),%eax
4000484d:	76 16                	jbe    40004865 <filedesc_write+0x3b>
4000484f:	8b 45 08             	mov    0x8(%ebp),%eax
40004852:	8b 00                	mov    (%eax),%eax
40004854:	85 c0                	test   %eax,%eax
40004856:	74 0d                	je     40004865 <filedesc_write+0x3b>
40004858:	8b 45 08             	mov    0x8(%ebp),%eax
4000485b:	8b 40 04             	mov    0x4(%eax),%eax
4000485e:	83 e0 02             	and    $0x2,%eax
40004861:	85 c0                	test   %eax,%eax
40004863:	75 24                	jne    40004889 <filedesc_write+0x5f>
40004865:	c7 44 24 0c 17 63 00 	movl   $0x40006317,0xc(%esp)
4000486c:	40 
4000486d:	c7 44 24 08 68 61 00 	movl   $0x40006168,0x8(%esp)
40004874:	40 
40004875:	c7 44 24 04 49 01 00 	movl   $0x149,0x4(%esp)
4000487c:	00 
4000487d:	c7 04 24 53 61 00 40 	movl   $0x40006153,(%esp)
40004884:	e8 5f e3 ff ff       	call   40002be8 <debug_panic>
	fileinode *fi = &files->fi[fd->ino];
40004889:	a1 30 61 00 40       	mov    0x40006130,%eax
4000488e:	8d 90 10 10 00 00    	lea    0x1010(%eax),%edx
40004894:	8b 45 08             	mov    0x8(%ebp),%eax
40004897:	8b 00                	mov    (%eax),%eax
40004899:	6b c0 5c             	imul   $0x5c,%eax,%eax
4000489c:	8d 04 02             	lea    (%edx,%eax,1),%eax
4000489f:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)

	// If we're appending to the file, seek to the end first.
	if (fd->flags & O_APPEND)
400048a2:	8b 45 08             	mov    0x8(%ebp),%eax
400048a5:	8b 40 04             	mov    0x4(%eax),%eax
400048a8:	83 e0 10             	and    $0x10,%eax
400048ab:	85 c0                	test   %eax,%eax
400048ad:	74 0e                	je     400048bd <filedesc_write+0x93>
		fd->ofs = fi->size;
400048af:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
400048b2:	8b 40 4c             	mov    0x4c(%eax),%eax
400048b5:	89 c2                	mov    %eax,%edx
400048b7:	8b 45 08             	mov    0x8(%ebp),%eax
400048ba:	89 50 08             	mov    %edx,0x8(%eax)

	// Write the data, growing the file as necessary.
	ssize_t actual = fileino_write(fd->ino, fd->ofs, buf, eltsize, count);
400048bd:	8b 45 08             	mov    0x8(%ebp),%eax
400048c0:	8b 50 08             	mov    0x8(%eax),%edx
400048c3:	8b 45 08             	mov    0x8(%ebp),%eax
400048c6:	8b 08                	mov    (%eax),%ecx
400048c8:	8b 45 14             	mov    0x14(%ebp),%eax
400048cb:	89 44 24 10          	mov    %eax,0x10(%esp)
400048cf:	8b 45 10             	mov    0x10(%ebp),%eax
400048d2:	89 44 24 0c          	mov    %eax,0xc(%esp)
400048d6:	8b 45 0c             	mov    0xc(%ebp),%eax
400048d9:	89 44 24 08          	mov    %eax,0x8(%esp)
400048dd:	89 54 24 04          	mov    %edx,0x4(%esp)
400048e1:	89 0c 24             	mov    %ecx,(%esp)
400048e4:	e8 1e f5 ff ff       	call   40003e07 <fileino_write>
400048e9:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	if (actual < 0) {
400048ec:	83 7d fc 00          	cmpl   $0x0,0xfffffffc(%ebp)
400048f0:	79 19                	jns    4000490b <filedesc_write+0xe1>
		fd->err = errno;	// save error indication for ferror()
400048f2:	a1 30 61 00 40       	mov    0x40006130,%eax
400048f7:	8b 10                	mov    (%eax),%edx
400048f9:	8b 45 08             	mov    0x8(%ebp),%eax
400048fc:	89 50 0c             	mov    %edx,0xc(%eax)
		return -1;
400048ff:	c7 45 ec ff ff ff ff 	movl   $0xffffffff,0xffffffec(%ebp)
40004906:	e9 9c 00 00 00       	jmp    400049a7 <filedesc_write+0x17d>
	}
	assert(actual == count);
4000490b:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
4000490e:	3b 45 14             	cmp    0x14(%ebp),%eax
40004911:	74 24                	je     40004937 <filedesc_write+0x10d>
40004913:	c7 44 24 0c 2f 63 00 	movl   $0x4000632f,0xc(%esp)
4000491a:	40 
4000491b:	c7 44 24 08 68 61 00 	movl   $0x40006168,0x8(%esp)
40004922:	40 
40004923:	c7 44 24 04 56 01 00 	movl   $0x156,0x4(%esp)
4000492a:	00 
4000492b:	c7 04 24 53 61 00 40 	movl   $0x40006153,(%esp)
40004932:	e8 b1 e2 ff ff       	call   40002be8 <debug_panic>

	// Non-append-only writes constitute exclusive modifications,
	// so must bump the file's version number.
	if (!(fd->flags & O_APPEND))
40004937:	8b 45 08             	mov    0x8(%ebp),%eax
4000493a:	8b 40 04             	mov    0x4(%eax),%eax
4000493d:	83 e0 10             	and    $0x10,%eax
40004940:	85 c0                	test   %eax,%eax
40004942:	75 0f                	jne    40004953 <filedesc_write+0x129>
		fi->ver++;
40004944:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
40004947:	8b 40 44             	mov    0x44(%eax),%eax
4000494a:	8d 50 01             	lea    0x1(%eax),%edx
4000494d:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
40004950:	89 50 44             	mov    %edx,0x44(%eax)

	// Advance the file position
	fd->ofs += eltsize * count;
40004953:	8b 45 08             	mov    0x8(%ebp),%eax
40004956:	8b 40 08             	mov    0x8(%eax),%eax
40004959:	89 c2                	mov    %eax,%edx
4000495b:	8b 45 10             	mov    0x10(%ebp),%eax
4000495e:	0f af 45 14          	imul   0x14(%ebp),%eax
40004962:	8d 04 02             	lea    (%edx,%eax,1),%eax
40004965:	89 c2                	mov    %eax,%edx
40004967:	8b 45 08             	mov    0x8(%ebp),%eax
4000496a:	89 50 08             	mov    %edx,0x8(%eax)
	assert(fi->size >= fd->ofs);
4000496d:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
40004970:	8b 50 4c             	mov    0x4c(%eax),%edx
40004973:	8b 45 08             	mov    0x8(%ebp),%eax
40004976:	8b 40 08             	mov    0x8(%eax),%eax
40004979:	39 c2                	cmp    %eax,%edx
4000497b:	73 24                	jae    400049a1 <filedesc_write+0x177>
4000497d:	c7 44 24 0c 3f 63 00 	movl   $0x4000633f,0xc(%esp)
40004984:	40 
40004985:	c7 44 24 08 68 61 00 	movl   $0x40006168,0x8(%esp)
4000498c:	40 
4000498d:	c7 44 24 04 5f 01 00 	movl   $0x15f,0x4(%esp)
40004994:	00 
40004995:	c7 04 24 53 61 00 40 	movl   $0x40006153,(%esp)
4000499c:	e8 47 e2 ff ff       	call   40002be8 <debug_panic>

	return count;
400049a1:	8b 45 14             	mov    0x14(%ebp),%eax
400049a4:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
400049a7:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
}
400049aa:	c9                   	leave  
400049ab:	c3                   	ret    

400049ac <filedesc_seek>:

// Seek the given file descriptor to a specificied position,
// which may be relative to the file start, end, or corrent position,
// depending on 'whence' (SEEK_SET, SEEK_CUR, or SEEK_END).
// Returns the resulting absolute file position,
// or returns -1 and sets errno appropriately on error.
off_t filedesc_seek(filedesc *fd, off_t offset, int whence)
{
400049ac:	55                   	push   %ebp
400049ad:	89 e5                	mov    %esp,%ebp
400049af:	83 ec 28             	sub    $0x28,%esp
	assert(filedesc_isopen(fd));
400049b2:	a1 30 61 00 40       	mov    0x40006130,%eax
400049b7:	83 c0 10             	add    $0x10,%eax
400049ba:	3b 45 08             	cmp    0x8(%ebp),%eax
400049bd:	77 1b                	ja     400049da <filedesc_seek+0x2e>
400049bf:	a1 30 61 00 40       	mov    0x40006130,%eax
400049c4:	83 c0 10             	add    $0x10,%eax
400049c7:	05 00 10 00 00       	add    $0x1000,%eax
400049cc:	3b 45 08             	cmp    0x8(%ebp),%eax
400049cf:	76 09                	jbe    400049da <filedesc_seek+0x2e>
400049d1:	8b 45 08             	mov    0x8(%ebp),%eax
400049d4:	8b 00                	mov    (%eax),%eax
400049d6:	85 c0                	test   %eax,%eax
400049d8:	75 24                	jne    400049fe <filedesc_seek+0x52>
400049da:	c7 44 24 0c c8 62 00 	movl   $0x400062c8,0xc(%esp)
400049e1:	40 
400049e2:	c7 44 24 08 68 61 00 	movl   $0x40006168,0x8(%esp)
400049e9:	40 
400049ea:	c7 44 24 04 6b 01 00 	movl   $0x16b,0x4(%esp)
400049f1:	00 
400049f2:	c7 04 24 53 61 00 40 	movl   $0x40006153,(%esp)
400049f9:	e8 ea e1 ff ff       	call   40002be8 <debug_panic>
	assert(whence == SEEK_SET || whence == SEEK_CUR || whence == SEEK_END);
400049fe:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
40004a02:	74 30                	je     40004a34 <filedesc_seek+0x88>
40004a04:	83 7d 10 01          	cmpl   $0x1,0x10(%ebp)
40004a08:	74 2a                	je     40004a34 <filedesc_seek+0x88>
40004a0a:	83 7d 10 02          	cmpl   $0x2,0x10(%ebp)
40004a0e:	74 24                	je     40004a34 <filedesc_seek+0x88>
40004a10:	c7 44 24 0c 54 63 00 	movl   $0x40006354,0xc(%esp)
40004a17:	40 
40004a18:	c7 44 24 08 68 61 00 	movl   $0x40006168,0x8(%esp)
40004a1f:	40 
40004a20:	c7 44 24 04 6c 01 00 	movl   $0x16c,0x4(%esp)
40004a27:	00 
40004a28:	c7 04 24 53 61 00 40 	movl   $0x40006153,(%esp)
40004a2f:	e8 b4 e1 ff ff       	call   40002be8 <debug_panic>
	fileinode *fi = &files->fi[fd->ino];
40004a34:	a1 30 61 00 40       	mov    0x40006130,%eax
40004a39:	8d 90 10 10 00 00    	lea    0x1010(%eax),%edx
40004a3f:	8b 45 08             	mov    0x8(%ebp),%eax
40004a42:	8b 00                	mov    (%eax),%eax
40004a44:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004a47:	8d 04 02             	lea    (%edx,%eax,1),%eax
40004a4a:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)

	// Lab 4: insert your file descriptor seek implementation here.
	off_t newofs = offset;
40004a4d:	8b 45 0c             	mov    0xc(%ebp),%eax
40004a50:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	if (whence == SEEK_CUR)
40004a53:	83 7d 10 01          	cmpl   $0x1,0x10(%ebp)
40004a57:	75 0b                	jne    40004a64 <filedesc_seek+0xb8>
		newofs += fd->ofs;
40004a59:	8b 45 08             	mov    0x8(%ebp),%eax
40004a5c:	8b 40 08             	mov    0x8(%eax),%eax
40004a5f:	01 45 fc             	add    %eax,0xfffffffc(%ebp)
40004a62:	eb 15                	jmp    40004a79 <filedesc_seek+0xcd>
	else if (whence == SEEK_END)
40004a64:	83 7d 10 02          	cmpl   $0x2,0x10(%ebp)
40004a68:	75 0f                	jne    40004a79 <filedesc_seek+0xcd>
		newofs += fi->size;
40004a6a:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
40004a6d:	8b 50 4c             	mov    0x4c(%eax),%edx
40004a70:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
40004a73:	8d 04 02             	lea    (%edx,%eax,1),%eax
40004a76:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	assert(newofs >= 0);
40004a79:	83 7d fc 00          	cmpl   $0x0,0xfffffffc(%ebp)
40004a7d:	79 24                	jns    40004aa3 <filedesc_seek+0xf7>
40004a7f:	c7 44 24 0c 93 63 00 	movl   $0x40006393,0xc(%esp)
40004a86:	40 
40004a87:	c7 44 24 08 68 61 00 	movl   $0x40006168,0x8(%esp)
40004a8e:	40 
40004a8f:	c7 44 24 04 75 01 00 	movl   $0x175,0x4(%esp)
40004a96:	00 
40004a97:	c7 04 24 53 61 00 40 	movl   $0x40006153,(%esp)
40004a9e:	e8 45 e1 ff ff       	call   40002be8 <debug_panic>

	fd->ofs = newofs;
40004aa3:	8b 55 08             	mov    0x8(%ebp),%edx
40004aa6:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
40004aa9:	89 42 08             	mov    %eax,0x8(%edx)
	return newofs;
40004aac:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
}
40004aaf:	c9                   	leave  
40004ab0:	c3                   	ret    

40004ab1 <filedesc_close>:

void
filedesc_close(filedesc *fd)
{
40004ab1:	55                   	push   %ebp
40004ab2:	89 e5                	mov    %esp,%ebp
40004ab4:	83 ec 18             	sub    $0x18,%esp
	assert(filedesc_isopen(fd));
40004ab7:	a1 30 61 00 40       	mov    0x40006130,%eax
40004abc:	83 c0 10             	add    $0x10,%eax
40004abf:	3b 45 08             	cmp    0x8(%ebp),%eax
40004ac2:	77 1b                	ja     40004adf <filedesc_close+0x2e>
40004ac4:	a1 30 61 00 40       	mov    0x40006130,%eax
40004ac9:	83 c0 10             	add    $0x10,%eax
40004acc:	05 00 10 00 00       	add    $0x1000,%eax
40004ad1:	3b 45 08             	cmp    0x8(%ebp),%eax
40004ad4:	76 09                	jbe    40004adf <filedesc_close+0x2e>
40004ad6:	8b 45 08             	mov    0x8(%ebp),%eax
40004ad9:	8b 00                	mov    (%eax),%eax
40004adb:	85 c0                	test   %eax,%eax
40004add:	75 24                	jne    40004b03 <filedesc_close+0x52>
40004adf:	c7 44 24 0c c8 62 00 	movl   $0x400062c8,0xc(%esp)
40004ae6:	40 
40004ae7:	c7 44 24 08 68 61 00 	movl   $0x40006168,0x8(%esp)
40004aee:	40 
40004aef:	c7 44 24 04 7e 01 00 	movl   $0x17e,0x4(%esp)
40004af6:	00 
40004af7:	c7 04 24 53 61 00 40 	movl   $0x40006153,(%esp)
40004afe:	e8 e5 e0 ff ff       	call   40002be8 <debug_panic>
	assert(fileino_isvalid(fd->ino));
40004b03:	8b 45 08             	mov    0x8(%ebp),%eax
40004b06:	8b 00                	mov    (%eax),%eax
40004b08:	85 c0                	test   %eax,%eax
40004b0a:	7e 0c                	jle    40004b18 <filedesc_close+0x67>
40004b0c:	8b 45 08             	mov    0x8(%ebp),%eax
40004b0f:	8b 00                	mov    (%eax),%eax
40004b11:	3d ff 00 00 00       	cmp    $0xff,%eax
40004b16:	7e 24                	jle    40004b3c <filedesc_close+0x8b>
40004b18:	c7 44 24 0c 9f 63 00 	movl   $0x4000639f,0xc(%esp)
40004b1f:	40 
40004b20:	c7 44 24 08 68 61 00 	movl   $0x40006168,0x8(%esp)
40004b27:	40 
40004b28:	c7 44 24 04 7f 01 00 	movl   $0x17f,0x4(%esp)
40004b2f:	00 
40004b30:	c7 04 24 53 61 00 40 	movl   $0x40006153,(%esp)
40004b37:	e8 ac e0 ff ff       	call   40002be8 <debug_panic>

	fd->ino = FILEINO_NULL;		// mark the fd free
40004b3c:	8b 45 08             	mov    0x8(%ebp),%eax
40004b3f:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}
40004b45:	c9                   	leave  
40004b46:	c3                   	ret    
40004b47:	90                   	nop    

40004b48 <dir_walk>:


int
dir_walk(const char *path, mode_t createmode)
{
40004b48:	55                   	push   %ebp
40004b49:	89 e5                	mov    %esp,%ebp
40004b4b:	53                   	push   %ebx
40004b4c:	83 ec 24             	sub    $0x24,%esp
	assert(path != 0 && *path != 0);
40004b4f:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
40004b53:	74 0a                	je     40004b5f <dir_walk+0x17>
40004b55:	8b 45 08             	mov    0x8(%ebp),%eax
40004b58:	0f b6 00             	movzbl (%eax),%eax
40004b5b:	84 c0                	test   %al,%al
40004b5d:	75 24                	jne    40004b83 <dir_walk+0x3b>
40004b5f:	c7 44 24 0c b8 63 00 	movl   $0x400063b8,0xc(%esp)
40004b66:	40 
40004b67:	c7 44 24 08 d0 63 00 	movl   $0x400063d0,0x8(%esp)
40004b6e:	40 
40004b6f:	c7 44 24 04 15 00 00 	movl   $0x15,0x4(%esp)
40004b76:	00 
40004b77:	c7 04 24 e5 63 00 40 	movl   $0x400063e5,(%esp)
40004b7e:	e8 65 e0 ff ff       	call   40002be8 <debug_panic>

	// Start at the current or root directory as appropriate
	int dino = files->cwd;
40004b83:	a1 30 61 00 40       	mov    0x40006130,%eax
40004b88:	8b 40 04             	mov    0x4(%eax),%eax
40004b8b:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
	if (*path == '/') {
40004b8e:	8b 45 08             	mov    0x8(%ebp),%eax
40004b91:	0f b6 00             	movzbl (%eax),%eax
40004b94:	3c 2f                	cmp    $0x2f,%al
40004b96:	75 2a                	jne    40004bc2 <dir_walk+0x7a>
		dino = FILEINO_ROOTDIR;
40004b98:	c7 45 f0 03 00 00 00 	movl   $0x3,0xfffffff0(%ebp)
		do { path++; } while (*path == '/');	// skip leading slashes
40004b9f:	83 45 08 01          	addl   $0x1,0x8(%ebp)
40004ba3:	8b 45 08             	mov    0x8(%ebp),%eax
40004ba6:	0f b6 00             	movzbl (%eax),%eax
40004ba9:	3c 2f                	cmp    $0x2f,%al
40004bab:	74 f2                	je     40004b9f <dir_walk+0x57>
		if (*path == 0)
40004bad:	8b 45 08             	mov    0x8(%ebp),%eax
40004bb0:	0f b6 00             	movzbl (%eax),%eax
40004bb3:	84 c0                	test   %al,%al
40004bb5:	75 0b                	jne    40004bc2 <dir_walk+0x7a>
			return dino;	// Just looking up root directory
40004bb7:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
40004bba:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
40004bbd:	e9 67 05 00 00       	jmp    40005129 <dir_walk+0x5e1>
	}

	// Search for the appropriate entry in this directory
	searchdir:
	assert(fileino_isdir(dino));
40004bc2:	83 7d f0 00          	cmpl   $0x0,0xfffffff0(%ebp)
40004bc6:	7e 45                	jle    40004c0d <dir_walk+0xc5>
40004bc8:	81 7d f0 ff 00 00 00 	cmpl   $0xff,0xfffffff0(%ebp)
40004bcf:	7f 3c                	jg     40004c0d <dir_walk+0xc5>
40004bd1:	8b 15 30 61 00 40    	mov    0x40006130,%edx
40004bd7:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
40004bda:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004bdd:	01 d0                	add    %edx,%eax
40004bdf:	05 10 10 00 00       	add    $0x1010,%eax
40004be4:	0f b6 40 04          	movzbl 0x4(%eax),%eax
40004be8:	84 c0                	test   %al,%al
40004bea:	74 21                	je     40004c0d <dir_walk+0xc5>
40004bec:	8b 15 30 61 00 40    	mov    0x40006130,%edx
40004bf2:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
40004bf5:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004bf8:	01 d0                	add    %edx,%eax
40004bfa:	05 58 10 00 00       	add    $0x1058,%eax
40004bff:	8b 00                	mov    (%eax),%eax
40004c01:	25 00 70 00 00       	and    $0x7000,%eax
40004c06:	3d 00 20 00 00       	cmp    $0x2000,%eax
40004c0b:	74 24                	je     40004c31 <dir_walk+0xe9>
40004c0d:	c7 44 24 0c ef 63 00 	movl   $0x400063ef,0xc(%esp)
40004c14:	40 
40004c15:	c7 44 24 08 d0 63 00 	movl   $0x400063d0,0x8(%esp)
40004c1c:	40 
40004c1d:	c7 44 24 04 22 00 00 	movl   $0x22,0x4(%esp)
40004c24:	00 
40004c25:	c7 04 24 e5 63 00 40 	movl   $0x400063e5,(%esp)
40004c2c:	e8 b7 df ff ff       	call   40002be8 <debug_panic>
	assert(fileino_isdir(files->fi[dino].dino));
40004c31:	8b 15 30 61 00 40    	mov    0x40006130,%edx
40004c37:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
40004c3a:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004c3d:	01 d0                	add    %edx,%eax
40004c3f:	05 10 10 00 00       	add    $0x1010,%eax
40004c44:	8b 00                	mov    (%eax),%eax
40004c46:	85 c0                	test   %eax,%eax
40004c48:	7e 7c                	jle    40004cc6 <dir_walk+0x17e>
40004c4a:	8b 15 30 61 00 40    	mov    0x40006130,%edx
40004c50:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
40004c53:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004c56:	01 d0                	add    %edx,%eax
40004c58:	05 10 10 00 00       	add    $0x1010,%eax
40004c5d:	8b 00                	mov    (%eax),%eax
40004c5f:	3d ff 00 00 00       	cmp    $0xff,%eax
40004c64:	7f 60                	jg     40004cc6 <dir_walk+0x17e>
40004c66:	8b 0d 30 61 00 40    	mov    0x40006130,%ecx
40004c6c:	8b 15 30 61 00 40    	mov    0x40006130,%edx
40004c72:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
40004c75:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004c78:	01 d0                	add    %edx,%eax
40004c7a:	05 10 10 00 00       	add    $0x1010,%eax
40004c7f:	8b 00                	mov    (%eax),%eax
40004c81:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004c84:	01 c8                	add    %ecx,%eax
40004c86:	05 10 10 00 00       	add    $0x1010,%eax
40004c8b:	0f b6 40 04          	movzbl 0x4(%eax),%eax
40004c8f:	84 c0                	test   %al,%al
40004c91:	74 33                	je     40004cc6 <dir_walk+0x17e>
40004c93:	8b 0d 30 61 00 40    	mov    0x40006130,%ecx
40004c99:	8b 15 30 61 00 40    	mov    0x40006130,%edx
40004c9f:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
40004ca2:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004ca5:	01 d0                	add    %edx,%eax
40004ca7:	05 10 10 00 00       	add    $0x1010,%eax
40004cac:	8b 00                	mov    (%eax),%eax
40004cae:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004cb1:	01 c8                	add    %ecx,%eax
40004cb3:	05 58 10 00 00       	add    $0x1058,%eax
40004cb8:	8b 00                	mov    (%eax),%eax
40004cba:	25 00 70 00 00       	and    $0x7000,%eax
40004cbf:	3d 00 20 00 00       	cmp    $0x2000,%eax
40004cc4:	74 24                	je     40004cea <dir_walk+0x1a2>
40004cc6:	c7 44 24 0c 04 64 00 	movl   $0x40006404,0xc(%esp)
40004ccd:	40 
40004cce:	c7 44 24 08 d0 63 00 	movl   $0x400063d0,0x8(%esp)
40004cd5:	40 
40004cd6:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
40004cdd:	00 
40004cde:	c7 04 24 e5 63 00 40 	movl   $0x400063e5,(%esp)
40004ce5:	e8 fe de ff ff       	call   40002be8 <debug_panic>

	// Look for a regular directory entry with a matching name.
	int ino, len;
	for (ino = 1; ino < FILE_INODES; ino++) {
40004cea:	c7 45 f4 01 00 00 00 	movl   $0x1,0xfffffff4(%ebp)
40004cf1:	e9 39 02 00 00       	jmp    40004f2f <dir_walk+0x3e7>
		if (!fileino_alloced(ino) || files->fi[ino].dino != dino)
40004cf6:	83 7d f4 00          	cmpl   $0x0,0xfffffff4(%ebp)
40004cfa:	0f 8e 2b 02 00 00    	jle    40004f2b <dir_walk+0x3e3>
40004d00:	81 7d f4 ff 00 00 00 	cmpl   $0xff,0xfffffff4(%ebp)
40004d07:	0f 8f 1e 02 00 00    	jg     40004f2b <dir_walk+0x3e3>
40004d0d:	8b 15 30 61 00 40    	mov    0x40006130,%edx
40004d13:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
40004d16:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004d19:	01 d0                	add    %edx,%eax
40004d1b:	05 10 10 00 00       	add    $0x1010,%eax
40004d20:	0f b6 40 04          	movzbl 0x4(%eax),%eax
40004d24:	84 c0                	test   %al,%al
40004d26:	0f 84 ff 01 00 00    	je     40004f2b <dir_walk+0x3e3>
40004d2c:	8b 15 30 61 00 40    	mov    0x40006130,%edx
40004d32:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
40004d35:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004d38:	01 d0                	add    %edx,%eax
40004d3a:	05 10 10 00 00       	add    $0x1010,%eax
40004d3f:	8b 00                	mov    (%eax),%eax
40004d41:	3b 45 f0             	cmp    0xfffffff0(%ebp),%eax
40004d44:	0f 85 e1 01 00 00    	jne    40004f2b <dir_walk+0x3e3>
			continue;	// not an entry in directory 'dino'

		// Does this inode's name match our next path component?
		len = strlen(files->fi[ino].de.d_name);
40004d4a:	8b 15 30 61 00 40    	mov    0x40006130,%edx
40004d50:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
40004d53:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004d56:	05 10 10 00 00       	add    $0x1010,%eax
40004d5b:	8d 04 02             	lea    (%edx,%eax,1),%eax
40004d5e:	83 c0 04             	add    $0x4,%eax
40004d61:	89 04 24             	mov    %eax,(%esp)
40004d64:	e8 73 e8 ff ff       	call   400035dc <strlen>
40004d69:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
		if (memcmp(path, files->fi[ino].de.d_name, len) != 0)
40004d6c:	8b 4d f8             	mov    0xfffffff8(%ebp),%ecx
40004d6f:	8b 15 30 61 00 40    	mov    0x40006130,%edx
40004d75:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
40004d78:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004d7b:	05 10 10 00 00       	add    $0x1010,%eax
40004d80:	8d 04 02             	lea    (%edx,%eax,1),%eax
40004d83:	83 c0 04             	add    $0x4,%eax
40004d86:	89 4c 24 08          	mov    %ecx,0x8(%esp)
40004d8a:	89 44 24 04          	mov    %eax,0x4(%esp)
40004d8e:	8b 45 08             	mov    0x8(%ebp),%eax
40004d91:	89 04 24             	mov    %eax,(%esp)
40004d94:	e8 70 eb ff ff       	call   40003909 <memcmp>
40004d99:	85 c0                	test   %eax,%eax
40004d9b:	0f 85 8a 01 00 00    	jne    40004f2b <dir_walk+0x3e3>
			continue;	// no match
		found:
		if (path[len] == 0) {
40004da1:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
40004da4:	03 45 08             	add    0x8(%ebp),%eax
40004da7:	0f b6 00             	movzbl (%eax),%eax
40004daa:	84 c0                	test   %al,%al
40004dac:	0f 85 cc 00 00 00    	jne    40004e7e <dir_walk+0x336>
			// Exact match at end of path - but does it exist?
			if (fileino_exists(ino))
40004db2:	83 7d f4 00          	cmpl   $0x0,0xfffffff4(%ebp)
40004db6:	7e 48                	jle    40004e00 <dir_walk+0x2b8>
40004db8:	81 7d f4 ff 00 00 00 	cmpl   $0xff,0xfffffff4(%ebp)
40004dbf:	7f 3f                	jg     40004e00 <dir_walk+0x2b8>
40004dc1:	8b 15 30 61 00 40    	mov    0x40006130,%edx
40004dc7:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
40004dca:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004dcd:	01 d0                	add    %edx,%eax
40004dcf:	05 10 10 00 00       	add    $0x1010,%eax
40004dd4:	0f b6 40 04          	movzbl 0x4(%eax),%eax
40004dd8:	84 c0                	test   %al,%al
40004dda:	74 24                	je     40004e00 <dir_walk+0x2b8>
40004ddc:	8b 15 30 61 00 40    	mov    0x40006130,%edx
40004de2:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
40004de5:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004de8:	01 d0                	add    %edx,%eax
40004dea:	05 58 10 00 00       	add    $0x1058,%eax
40004def:	8b 00                	mov    (%eax),%eax
40004df1:	85 c0                	test   %eax,%eax
40004df3:	74 0b                	je     40004e00 <dir_walk+0x2b8>
				return ino;	// yes - return it
40004df5:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
40004df8:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
40004dfb:	e9 29 03 00 00       	jmp    40005129 <dir_walk+0x5e1>

			// no - existed, but was deleted.  re-create?
			if (!createmode) {
40004e00:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
40004e04:	75 17                	jne    40004e1d <dir_walk+0x2d5>
				errno = ENOENT;
40004e06:	a1 30 61 00 40       	mov    0x40006130,%eax
40004e0b:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
				return -1;
40004e11:	c7 45 e8 ff ff ff ff 	movl   $0xffffffff,0xffffffe8(%ebp)
40004e18:	e9 0c 03 00 00       	jmp    40005129 <dir_walk+0x5e1>
			}
			files->fi[ino].ver++;	// an exclusive change
40004e1d:	8b 1d 30 61 00 40    	mov    0x40006130,%ebx
40004e23:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
40004e26:	6b c2 5c             	imul   $0x5c,%edx,%eax
40004e29:	01 d8                	add    %ebx,%eax
40004e2b:	05 54 10 00 00       	add    $0x1054,%eax
40004e30:	8b 00                	mov    (%eax),%eax
40004e32:	8d 48 01             	lea    0x1(%eax),%ecx
40004e35:	6b c2 5c             	imul   $0x5c,%edx,%eax
40004e38:	01 d8                	add    %ebx,%eax
40004e3a:	05 54 10 00 00       	add    $0x1054,%eax
40004e3f:	89 08                	mov    %ecx,(%eax)
			files->fi[ino].mode = createmode;
40004e41:	8b 15 30 61 00 40    	mov    0x40006130,%edx
40004e47:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
40004e4a:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004e4d:	01 d0                	add    %edx,%eax
40004e4f:	8d 90 58 10 00 00    	lea    0x1058(%eax),%edx
40004e55:	8b 45 0c             	mov    0xc(%ebp),%eax
40004e58:	89 02                	mov    %eax,(%edx)
			files->fi[ino].size = 0;
40004e5a:	8b 15 30 61 00 40    	mov    0x40006130,%edx
40004e60:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
40004e63:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004e66:	01 d0                	add    %edx,%eax
40004e68:	05 5c 10 00 00       	add    $0x105c,%eax
40004e6d:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
			return ino;
40004e73:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
40004e76:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
40004e79:	e9 ab 02 00 00       	jmp    40005129 <dir_walk+0x5e1>
		}
		if (path[len] != '/')
40004e7e:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
40004e81:	03 45 08             	add    0x8(%ebp),%eax
40004e84:	0f b6 00             	movzbl (%eax),%eax
40004e87:	3c 2f                	cmp    $0x2f,%al
40004e89:	0f 85 9c 00 00 00    	jne    40004f2b <dir_walk+0x3e3>
			continue;	// no match

		// Make sure this dirent refers to a directory
		if (!fileino_isdir(ino)) {
40004e8f:	83 7d f4 00          	cmpl   $0x0,0xfffffff4(%ebp)
40004e93:	7e 45                	jle    40004eda <dir_walk+0x392>
40004e95:	81 7d f4 ff 00 00 00 	cmpl   $0xff,0xfffffff4(%ebp)
40004e9c:	7f 3c                	jg     40004eda <dir_walk+0x392>
40004e9e:	8b 15 30 61 00 40    	mov    0x40006130,%edx
40004ea4:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
40004ea7:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004eaa:	01 d0                	add    %edx,%eax
40004eac:	05 10 10 00 00       	add    $0x1010,%eax
40004eb1:	0f b6 40 04          	movzbl 0x4(%eax),%eax
40004eb5:	84 c0                	test   %al,%al
40004eb7:	74 21                	je     40004eda <dir_walk+0x392>
40004eb9:	8b 15 30 61 00 40    	mov    0x40006130,%edx
40004ebf:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
40004ec2:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004ec5:	01 d0                	add    %edx,%eax
40004ec7:	05 58 10 00 00       	add    $0x1058,%eax
40004ecc:	8b 00                	mov    (%eax),%eax
40004ece:	25 00 70 00 00       	and    $0x7000,%eax
40004ed3:	3d 00 20 00 00       	cmp    $0x2000,%eax
40004ed8:	74 17                	je     40004ef1 <dir_walk+0x3a9>
			errno = ENOTDIR;
40004eda:	a1 30 61 00 40       	mov    0x40006130,%eax
40004edf:	c7 00 05 00 00 00    	movl   $0x5,(%eax)
			return -1;
40004ee5:	c7 45 e8 ff ff ff ff 	movl   $0xffffffff,0xffffffe8(%ebp)
40004eec:	e9 38 02 00 00       	jmp    40005129 <dir_walk+0x5e1>
		}

		// Skip slashes to find next component
		do { len++; } while (path[len] == '/');
40004ef1:	83 45 f8 01          	addl   $0x1,0xfffffff8(%ebp)
40004ef5:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
40004ef8:	03 45 08             	add    0x8(%ebp),%eax
40004efb:	0f b6 00             	movzbl (%eax),%eax
40004efe:	3c 2f                	cmp    $0x2f,%al
40004f00:	74 ef                	je     40004ef1 <dir_walk+0x3a9>
		if (path[len] == 0)
40004f02:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
40004f05:	03 45 08             	add    0x8(%ebp),%eax
40004f08:	0f b6 00             	movzbl (%eax),%eax
40004f0b:	84 c0                	test   %al,%al
40004f0d:	75 0b                	jne    40004f1a <dir_walk+0x3d2>
			return ino;	// matched directory at end of path
40004f0f:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
40004f12:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
40004f15:	e9 0f 02 00 00       	jmp    40005129 <dir_walk+0x5e1>

		// Walk the next directory in the path
		dino = ino;
40004f1a:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
40004f1d:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
		path += len;
40004f20:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
40004f23:	01 45 08             	add    %eax,0x8(%ebp)
		goto searchdir;
40004f26:	e9 97 fc ff ff       	jmp    40004bc2 <dir_walk+0x7a>
40004f2b:	83 45 f4 01          	addl   $0x1,0xfffffff4(%ebp)
40004f2f:	81 7d f4 ff 00 00 00 	cmpl   $0xff,0xfffffff4(%ebp)
40004f36:	0f 8e ba fd ff ff    	jle    40004cf6 <dir_walk+0x1ae>
	}

	// Looking for one of the special entries '.' or '..'?
	if (path[0] == '.' && (path[1] == 0 || path[1] == '/')) {
40004f3c:	8b 45 08             	mov    0x8(%ebp),%eax
40004f3f:	0f b6 00             	movzbl (%eax),%eax
40004f42:	3c 2e                	cmp    $0x2e,%al
40004f44:	75 2c                	jne    40004f72 <dir_walk+0x42a>
40004f46:	8b 45 08             	mov    0x8(%ebp),%eax
40004f49:	83 c0 01             	add    $0x1,%eax
40004f4c:	0f b6 00             	movzbl (%eax),%eax
40004f4f:	84 c0                	test   %al,%al
40004f51:	74 0d                	je     40004f60 <dir_walk+0x418>
40004f53:	8b 45 08             	mov    0x8(%ebp),%eax
40004f56:	83 c0 01             	add    $0x1,%eax
40004f59:	0f b6 00             	movzbl (%eax),%eax
40004f5c:	3c 2f                	cmp    $0x2f,%al
40004f5e:	75 12                	jne    40004f72 <dir_walk+0x42a>
		len = 1;
40004f60:	c7 45 f8 01 00 00 00 	movl   $0x1,0xfffffff8(%ebp)
		ino = dino;	// just leads to this same directory
40004f67:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
40004f6a:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
		goto found;
40004f6d:	e9 2f fe ff ff       	jmp    40004da1 <dir_walk+0x259>
	}
	if (path[0] == '.' && path[1] == '.'
40004f72:	8b 45 08             	mov    0x8(%ebp),%eax
40004f75:	0f b6 00             	movzbl (%eax),%eax
40004f78:	3c 2e                	cmp    $0x2e,%al
40004f7a:	75 4b                	jne    40004fc7 <dir_walk+0x47f>
40004f7c:	8b 45 08             	mov    0x8(%ebp),%eax
40004f7f:	83 c0 01             	add    $0x1,%eax
40004f82:	0f b6 00             	movzbl (%eax),%eax
40004f85:	3c 2e                	cmp    $0x2e,%al
40004f87:	75 3e                	jne    40004fc7 <dir_walk+0x47f>
40004f89:	8b 45 08             	mov    0x8(%ebp),%eax
40004f8c:	83 c0 02             	add    $0x2,%eax
40004f8f:	0f b6 00             	movzbl (%eax),%eax
40004f92:	84 c0                	test   %al,%al
40004f94:	74 0d                	je     40004fa3 <dir_walk+0x45b>
40004f96:	8b 45 08             	mov    0x8(%ebp),%eax
40004f99:	83 c0 02             	add    $0x2,%eax
40004f9c:	0f b6 00             	movzbl (%eax),%eax
40004f9f:	3c 2f                	cmp    $0x2f,%al
40004fa1:	75 24                	jne    40004fc7 <dir_walk+0x47f>
			&& (path[2] == 0 || path[2] == '/')) {
		len = 2;
40004fa3:	c7 45 f8 02 00 00 00 	movl   $0x2,0xfffffff8(%ebp)
		ino = files->fi[dino].dino;	// leads to root directory
40004faa:	8b 15 30 61 00 40    	mov    0x40006130,%edx
40004fb0:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
40004fb3:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004fb6:	01 d0                	add    %edx,%eax
40004fb8:	05 10 10 00 00       	add    $0x1010,%eax
40004fbd:	8b 00                	mov    (%eax),%eax
40004fbf:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
		goto found;
40004fc2:	e9 da fd ff ff       	jmp    40004da1 <dir_walk+0x259>
	}

	// Path component not found - see if we should create it
	if (!createmode || strchr(path, '/') != NULL) {
40004fc7:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
40004fcb:	74 17                	je     40004fe4 <dir_walk+0x49c>
40004fcd:	c7 44 24 04 2f 00 00 	movl   $0x2f,0x4(%esp)
40004fd4:	00 
40004fd5:	8b 45 08             	mov    0x8(%ebp),%eax
40004fd8:	89 04 24             	mov    %eax,(%esp)
40004fdb:	e8 89 e7 ff ff       	call   40003769 <strchr>
40004fe0:	85 c0                	test   %eax,%eax
40004fe2:	74 17                	je     40004ffb <dir_walk+0x4b3>
		errno = ENOENT;
40004fe4:	a1 30 61 00 40       	mov    0x40006130,%eax
40004fe9:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
		return -1;
40004fef:	c7 45 e8 ff ff ff ff 	movl   $0xffffffff,0xffffffe8(%ebp)
40004ff6:	e9 2e 01 00 00       	jmp    40005129 <dir_walk+0x5e1>
	}
	if (strlen(path) > NAME_MAX) {
40004ffb:	8b 45 08             	mov    0x8(%ebp),%eax
40004ffe:	89 04 24             	mov    %eax,(%esp)
40005001:	e8 d6 e5 ff ff       	call   400035dc <strlen>
40005006:	83 f8 3f             	cmp    $0x3f,%eax
40005009:	7e 17                	jle    40005022 <dir_walk+0x4da>
		errno = ENAMETOOLONG;
4000500b:	a1 30 61 00 40       	mov    0x40006130,%eax
40005010:	c7 00 06 00 00 00    	movl   $0x6,(%eax)
		return -1;
40005016:	c7 45 e8 ff ff ff ff 	movl   $0xffffffff,0xffffffe8(%ebp)
4000501d:	e9 07 01 00 00       	jmp    40005129 <dir_walk+0x5e1>
	}

	// Allocate a new inode and create this entry with the given mode.
	ino = fileino_alloc();
40005022:	e8 f5 e9 ff ff       	call   40003a1c <fileino_alloc>
40005027:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	if (ino < 0)
4000502a:	83 7d f4 00          	cmpl   $0x0,0xfffffff4(%ebp)
4000502e:	79 0c                	jns    4000503c <dir_walk+0x4f4>
		return -1;
40005030:	c7 45 e8 ff ff ff ff 	movl   $0xffffffff,0xffffffe8(%ebp)
40005037:	e9 ed 00 00 00       	jmp    40005129 <dir_walk+0x5e1>
	assert(fileino_isvalid(ino) && !fileino_alloced(ino));
4000503c:	83 7d f4 00          	cmpl   $0x0,0xfffffff4(%ebp)
40005040:	7e 33                	jle    40005075 <dir_walk+0x52d>
40005042:	81 7d f4 ff 00 00 00 	cmpl   $0xff,0xfffffff4(%ebp)
40005049:	7f 2a                	jg     40005075 <dir_walk+0x52d>
4000504b:	83 7d f4 00          	cmpl   $0x0,0xfffffff4(%ebp)
4000504f:	7e 48                	jle    40005099 <dir_walk+0x551>
40005051:	81 7d f4 ff 00 00 00 	cmpl   $0xff,0xfffffff4(%ebp)
40005058:	7f 3f                	jg     40005099 <dir_walk+0x551>
4000505a:	8b 15 30 61 00 40    	mov    0x40006130,%edx
40005060:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
40005063:	6b c0 5c             	imul   $0x5c,%eax,%eax
40005066:	01 d0                	add    %edx,%eax
40005068:	05 10 10 00 00       	add    $0x1010,%eax
4000506d:	0f b6 40 04          	movzbl 0x4(%eax),%eax
40005071:	84 c0                	test   %al,%al
40005073:	74 24                	je     40005099 <dir_walk+0x551>
40005075:	c7 44 24 0c 28 64 00 	movl   $0x40006428,0xc(%esp)
4000507c:	40 
4000507d:	c7 44 24 08 d0 63 00 	movl   $0x400063d0,0x8(%esp)
40005084:	40 
40005085:	c7 44 24 04 6e 00 00 	movl   $0x6e,0x4(%esp)
4000508c:	00 
4000508d:	c7 04 24 e5 63 00 40 	movl   $0x400063e5,(%esp)
40005094:	e8 4f db ff ff       	call   40002be8 <debug_panic>
	strcpy(files->fi[ino].de.d_name, path);
40005099:	8b 15 30 61 00 40    	mov    0x40006130,%edx
4000509f:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
400050a2:	6b c0 5c             	imul   $0x5c,%eax,%eax
400050a5:	05 10 10 00 00       	add    $0x1010,%eax
400050aa:	8d 04 02             	lea    (%edx,%eax,1),%eax
400050ad:	8d 50 04             	lea    0x4(%eax),%edx
400050b0:	8b 45 08             	mov    0x8(%ebp),%eax
400050b3:	89 44 24 04          	mov    %eax,0x4(%esp)
400050b7:	89 14 24             	mov    %edx,(%esp)
400050ba:	e8 43 e5 ff ff       	call   40003602 <strcpy>
	files->fi[ino].dino = dino;
400050bf:	8b 15 30 61 00 40    	mov    0x40006130,%edx
400050c5:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
400050c8:	6b c0 5c             	imul   $0x5c,%eax,%eax
400050cb:	01 d0                	add    %edx,%eax
400050cd:	8d 90 10 10 00 00    	lea    0x1010(%eax),%edx
400050d3:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
400050d6:	89 02                	mov    %eax,(%edx)
	files->fi[ino].ver = 0;
400050d8:	8b 15 30 61 00 40    	mov    0x40006130,%edx
400050de:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
400050e1:	6b c0 5c             	imul   $0x5c,%eax,%eax
400050e4:	01 d0                	add    %edx,%eax
400050e6:	05 54 10 00 00       	add    $0x1054,%eax
400050eb:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	files->fi[ino].mode = createmode;
400050f1:	8b 15 30 61 00 40    	mov    0x40006130,%edx
400050f7:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
400050fa:	6b c0 5c             	imul   $0x5c,%eax,%eax
400050fd:	01 d0                	add    %edx,%eax
400050ff:	8d 90 58 10 00 00    	lea    0x1058(%eax),%edx
40005105:	8b 45 0c             	mov    0xc(%ebp),%eax
40005108:	89 02                	mov    %eax,(%edx)
	files->fi[ino].size = 0;
4000510a:	8b 15 30 61 00 40    	mov    0x40006130,%edx
40005110:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
40005113:	6b c0 5c             	imul   $0x5c,%eax,%eax
40005116:	01 d0                	add    %edx,%eax
40005118:	05 5c 10 00 00       	add    $0x105c,%eax
4000511d:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	return ino;
40005123:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
40005126:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
40005129:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
}
4000512c:	83 c4 24             	add    $0x24,%esp
4000512f:	5b                   	pop    %ebx
40005130:	5d                   	pop    %ebp
40005131:	c3                   	ret    

40005132 <opendir>:

// Open a directory for scanning.
// For simplicity, DIR is simply a filedesc like other file descriptors,
// except we interpret fd->ofs as an inode number for scanning,
// instead of as a byte offset as in a regular file.
DIR *opendir(const char *path)
{
40005132:	55                   	push   %ebp
40005133:	89 e5                	mov    %esp,%ebp
40005135:	83 ec 28             	sub    $0x28,%esp
	filedesc *fd = filedesc_open(NULL, path, O_RDONLY, 0);
40005138:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
4000513f:	00 
40005140:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
40005147:	00 
40005148:	8b 45 08             	mov    0x8(%ebp),%eax
4000514b:	89 44 24 04          	mov    %eax,0x4(%esp)
4000514f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40005156:	e8 5e f3 ff ff       	call   400044b9 <filedesc_open>
4000515b:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
	if (fd == NULL)
4000515e:	83 7d f8 00          	cmpl   $0x0,0xfffffff8(%ebp)
40005162:	75 0c                	jne    40005170 <opendir+0x3e>
		return NULL;
40005164:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
4000516b:	e9 c1 00 00 00       	jmp    40005231 <opendir+0xff>

	// Make sure it's a directory
	assert(fileino_exists(fd->ino));
40005170:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
40005173:	8b 00                	mov    (%eax),%eax
40005175:	85 c0                	test   %eax,%eax
40005177:	7e 44                	jle    400051bd <opendir+0x8b>
40005179:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
4000517c:	8b 00                	mov    (%eax),%eax
4000517e:	3d ff 00 00 00       	cmp    $0xff,%eax
40005183:	7f 38                	jg     400051bd <opendir+0x8b>
40005185:	8b 15 30 61 00 40    	mov    0x40006130,%edx
4000518b:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
4000518e:	8b 00                	mov    (%eax),%eax
40005190:	6b c0 5c             	imul   $0x5c,%eax,%eax
40005193:	01 d0                	add    %edx,%eax
40005195:	05 10 10 00 00       	add    $0x1010,%eax
4000519a:	0f b6 40 04          	movzbl 0x4(%eax),%eax
4000519e:	84 c0                	test   %al,%al
400051a0:	74 1b                	je     400051bd <opendir+0x8b>
400051a2:	8b 15 30 61 00 40    	mov    0x40006130,%edx
400051a8:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
400051ab:	8b 00                	mov    (%eax),%eax
400051ad:	6b c0 5c             	imul   $0x5c,%eax,%eax
400051b0:	01 d0                	add    %edx,%eax
400051b2:	05 58 10 00 00       	add    $0x1058,%eax
400051b7:	8b 00                	mov    (%eax),%eax
400051b9:	85 c0                	test   %eax,%eax
400051bb:	75 24                	jne    400051e1 <opendir+0xaf>
400051bd:	c7 44 24 0c 56 64 00 	movl   $0x40006456,0xc(%esp)
400051c4:	40 
400051c5:	c7 44 24 08 d0 63 00 	movl   $0x400063d0,0x8(%esp)
400051cc:	40 
400051cd:	c7 44 24 04 82 00 00 	movl   $0x82,0x4(%esp)
400051d4:	00 
400051d5:	c7 04 24 e5 63 00 40 	movl   $0x400063e5,(%esp)
400051dc:	e8 07 da ff ff       	call   40002be8 <debug_panic>
	fileinode *fi = &files->fi[fd->ino];
400051e1:	a1 30 61 00 40       	mov    0x40006130,%eax
400051e6:	8d 90 10 10 00 00    	lea    0x1010(%eax),%edx
400051ec:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
400051ef:	8b 00                	mov    (%eax),%eax
400051f1:	6b c0 5c             	imul   $0x5c,%eax,%eax
400051f4:	8d 04 02             	lea    (%edx,%eax,1),%eax
400051f7:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	if (!S_ISDIR(fi->mode)) {
400051fa:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
400051fd:	8b 40 48             	mov    0x48(%eax),%eax
40005200:	25 00 70 00 00       	and    $0x7000,%eax
40005205:	3d 00 20 00 00       	cmp    $0x2000,%eax
4000520a:	74 1f                	je     4000522b <opendir+0xf9>
		filedesc_close(fd);
4000520c:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
4000520f:	89 04 24             	mov    %eax,(%esp)
40005212:	e8 9a f8 ff ff       	call   40004ab1 <filedesc_close>
		errno = ENOTDIR;
40005217:	a1 30 61 00 40       	mov    0x40006130,%eax
4000521c:	c7 00 05 00 00 00    	movl   $0x5,(%eax)
		return NULL;
40005222:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
40005229:	eb 06                	jmp    40005231 <opendir+0xff>
	}

	return fd;
4000522b:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
4000522e:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
40005231:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
}
40005234:	c9                   	leave  
40005235:	c3                   	ret    

40005236 <closedir>:

int closedir(DIR *dir)
{
40005236:	55                   	push   %ebp
40005237:	89 e5                	mov    %esp,%ebp
40005239:	83 ec 08             	sub    $0x8,%esp
	filedesc_close(dir);
4000523c:	8b 45 08             	mov    0x8(%ebp),%eax
4000523f:	89 04 24             	mov    %eax,(%esp)
40005242:	e8 6a f8 ff ff       	call   40004ab1 <filedesc_close>
	return 0;
40005247:	b8 00 00 00 00       	mov    $0x0,%eax
}
4000524c:	c9                   	leave  
4000524d:	c3                   	ret    

4000524e <readdir>:

// Scan an open directory filedesc and return the next entry.
// Returns a pointer to the next matching file inode's 'dirent' struct,
// or NULL if the directory being scanned contains no more entries.
struct dirent *readdir(DIR *dir)
{
4000524e:	55                   	push   %ebp
4000524f:	89 e5                	mov    %esp,%ebp
40005251:	83 ec 28             	sub    $0x28,%esp
	// Lab 4: insert your directory scanning code here.
	// Hint: a fileinode's 'dino' field indicates
	// what directory the file is in;
	// this function shouldn't return entries from other directories!
	assert(filedesc_isopen(dir));
40005254:	a1 30 61 00 40       	mov    0x40006130,%eax
40005259:	83 c0 10             	add    $0x10,%eax
4000525c:	3b 45 08             	cmp    0x8(%ebp),%eax
4000525f:	77 1f                	ja     40005280 <readdir+0x32>
40005261:	a1 30 61 00 40       	mov    0x40006130,%eax
40005266:	83 c0 10             	add    $0x10,%eax
40005269:	05 00 10 00 00       	add    $0x1000,%eax
4000526e:	3b 45 08             	cmp    0x8(%ebp),%eax
40005271:	76 0d                	jbe    40005280 <readdir+0x32>
40005273:	8b 45 08             	mov    0x8(%ebp),%eax
40005276:	8b 00                	mov    (%eax),%eax
40005278:	85 c0                	test   %eax,%eax
4000527a:	0f 85 a1 00 00 00    	jne    40005321 <readdir+0xd3>
40005280:	c7 44 24 0c 6e 64 00 	movl   $0x4000646e,0xc(%esp)
40005287:	40 
40005288:	c7 44 24 08 d0 63 00 	movl   $0x400063d0,0x8(%esp)
4000528f:	40 
40005290:	c7 44 24 04 9c 00 00 	movl   $0x9c,0x4(%esp)
40005297:	00 
40005298:	c7 04 24 e5 63 00 40 	movl   $0x400063e5,(%esp)
4000529f:	e8 44 d9 ff ff       	call   40002be8 <debug_panic>
	int ino;
	while ((ino = dir->ofs++) < FILE_INODES) {
		if (!fileino_exists(ino) || files->fi[ino].dino != dir->ino)
400052a4:	83 7d fc 00          	cmpl   $0x0,0xfffffffc(%ebp)
400052a8:	7e 77                	jle    40005321 <readdir+0xd3>
400052aa:	81 7d fc ff 00 00 00 	cmpl   $0xff,0xfffffffc(%ebp)
400052b1:	7f 6e                	jg     40005321 <readdir+0xd3>
400052b3:	8b 15 30 61 00 40    	mov    0x40006130,%edx
400052b9:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
400052bc:	6b c0 5c             	imul   $0x5c,%eax,%eax
400052bf:	01 d0                	add    %edx,%eax
400052c1:	05 10 10 00 00       	add    $0x1010,%eax
400052c6:	0f b6 40 04          	movzbl 0x4(%eax),%eax
400052ca:	84 c0                	test   %al,%al
400052cc:	74 53                	je     40005321 <readdir+0xd3>
400052ce:	8b 15 30 61 00 40    	mov    0x40006130,%edx
400052d4:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
400052d7:	6b c0 5c             	imul   $0x5c,%eax,%eax
400052da:	01 d0                	add    %edx,%eax
400052dc:	05 58 10 00 00       	add    $0x1058,%eax
400052e1:	8b 00                	mov    (%eax),%eax
400052e3:	85 c0                	test   %eax,%eax
400052e5:	74 3a                	je     40005321 <readdir+0xd3>
400052e7:	8b 15 30 61 00 40    	mov    0x40006130,%edx
400052ed:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
400052f0:	6b c0 5c             	imul   $0x5c,%eax,%eax
400052f3:	01 d0                	add    %edx,%eax
400052f5:	05 10 10 00 00       	add    $0x1010,%eax
400052fa:	8b 10                	mov    (%eax),%edx
400052fc:	8b 45 08             	mov    0x8(%ebp),%eax
400052ff:	8b 00                	mov    (%eax),%eax
40005301:	39 c2                	cmp    %eax,%edx
40005303:	75 1c                	jne    40005321 <readdir+0xd3>
			continue;
		return &files->fi[ino].de;	// Return inode's dirent
40005305:	8b 15 30 61 00 40    	mov    0x40006130,%edx
4000530b:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
4000530e:	6b c0 5c             	imul   $0x5c,%eax,%eax
40005311:	05 10 10 00 00       	add    $0x1010,%eax
40005316:	8d 04 02             	lea    (%edx,%eax,1),%eax
40005319:	83 c0 04             	add    $0x4,%eax
4000531c:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
4000531f:	eb 2b                	jmp    4000534c <readdir+0xfe>
40005321:	8b 45 08             	mov    0x8(%ebp),%eax
40005324:	8b 40 08             	mov    0x8(%eax),%eax
40005327:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
4000532a:	81 7d fc ff 00 00 00 	cmpl   $0xff,0xfffffffc(%ebp)
40005331:	0f 9e c1             	setle  %cl
40005334:	8d 50 01             	lea    0x1(%eax),%edx
40005337:	8b 45 08             	mov    0x8(%ebp),%eax
4000533a:	89 50 08             	mov    %edx,0x8(%eax)
4000533d:	84 c9                	test   %cl,%cl
4000533f:	0f 85 5f ff ff ff    	jne    400052a4 <readdir+0x56>
	}
	return NULL;	// End of directory
40005345:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
4000534c:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
}
4000534f:	c9                   	leave  
40005350:	c3                   	ret    

40005351 <rewinddir>:

void rewinddir(DIR *dir)
{
40005351:	55                   	push   %ebp
40005352:	89 e5                	mov    %esp,%ebp
	dir->ofs = 0;
40005354:	8b 45 08             	mov    0x8(%ebp),%eax
40005357:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
4000535e:	5d                   	pop    %ebp
4000535f:	c3                   	ret    

40005360 <seekdir>:

void seekdir(DIR *dir, long ofs)
{
40005360:	55                   	push   %ebp
40005361:	89 e5                	mov    %esp,%ebp
	dir->ofs = ofs;
40005363:	8b 55 08             	mov    0x8(%ebp),%edx
40005366:	8b 45 0c             	mov    0xc(%ebp),%eax
40005369:	89 42 08             	mov    %eax,0x8(%edx)
}
4000536c:	5d                   	pop    %ebp
4000536d:	c3                   	ret    

4000536e <telldir>:

long telldir(DIR *dir)
{
4000536e:	55                   	push   %ebp
4000536f:	89 e5                	mov    %esp,%ebp
	return dir->ofs;
40005371:	8b 45 08             	mov    0x8(%ebp),%eax
40005374:	8b 40 08             	mov    0x8(%eax),%eax
}
40005377:	5d                   	pop    %ebp
40005378:	c3                   	ret    
40005379:	90                   	nop    
4000537a:	90                   	nop    
4000537b:	90                   	nop    
4000537c:	90                   	nop    
4000537d:	90                   	nop    
4000537e:	90                   	nop    
4000537f:	90                   	nop    

40005380 <__udivdi3>:
40005380:	55                   	push   %ebp
40005381:	89 e5                	mov    %esp,%ebp
40005383:	57                   	push   %edi
40005384:	56                   	push   %esi
40005385:	83 ec 1c             	sub    $0x1c,%esp
40005388:	8b 45 10             	mov    0x10(%ebp),%eax
4000538b:	8b 55 14             	mov    0x14(%ebp),%edx
4000538e:	8b 7d 0c             	mov    0xc(%ebp),%edi
40005391:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
40005394:	89 c1                	mov    %eax,%ecx
40005396:	8b 45 08             	mov    0x8(%ebp),%eax
40005399:	85 d2                	test   %edx,%edx
4000539b:	89 d6                	mov    %edx,%esi
4000539d:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
400053a0:	75 1e                	jne    400053c0 <__udivdi3+0x40>
400053a2:	39 f9                	cmp    %edi,%ecx
400053a4:	0f 86 8d 00 00 00    	jbe    40005437 <__udivdi3+0xb7>
400053aa:	89 fa                	mov    %edi,%edx
400053ac:	f7 f1                	div    %ecx
400053ae:	89 c1                	mov    %eax,%ecx
400053b0:	89 c8                	mov    %ecx,%eax
400053b2:	89 f2                	mov    %esi,%edx
400053b4:	83 c4 1c             	add    $0x1c,%esp
400053b7:	5e                   	pop    %esi
400053b8:	5f                   	pop    %edi
400053b9:	5d                   	pop    %ebp
400053ba:	c3                   	ret    
400053bb:	90                   	nop    
400053bc:	8d 74 26 00          	lea    0x0(%esi),%esi
400053c0:	39 fa                	cmp    %edi,%edx
400053c2:	0f 87 98 00 00 00    	ja     40005460 <__udivdi3+0xe0>
400053c8:	0f bd c2             	bsr    %edx,%eax
400053cb:	83 f0 1f             	xor    $0x1f,%eax
400053ce:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
400053d1:	74 7f                	je     40005452 <__udivdi3+0xd2>
400053d3:	b8 20 00 00 00       	mov    $0x20,%eax
400053d8:	8b 55 f0             	mov    0xfffffff0(%ebp),%edx
400053db:	2b 45 e4             	sub    0xffffffe4(%ebp),%eax
400053de:	89 c1                	mov    %eax,%ecx
400053e0:	d3 ea                	shr    %cl,%edx
400053e2:	0f b6 4d e4          	movzbl 0xffffffe4(%ebp),%ecx
400053e6:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
400053e9:	89 f0                	mov    %esi,%eax
400053eb:	d3 e0                	shl    %cl,%eax
400053ed:	09 c2                	or     %eax,%edx
400053ef:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
400053f2:	89 55 e0             	mov    %edx,0xffffffe0(%ebp)
400053f5:	89 fa                	mov    %edi,%edx
400053f7:	d3 e0                	shl    %cl,%eax
400053f9:	0f b6 4d ec          	movzbl 0xffffffec(%ebp),%ecx
400053fd:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
40005400:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
40005403:	d3 e8                	shr    %cl,%eax
40005405:	0f b6 4d e4          	movzbl 0xffffffe4(%ebp),%ecx
40005409:	d3 e2                	shl    %cl,%edx
4000540b:	0f b6 4d ec          	movzbl 0xffffffec(%ebp),%ecx
4000540f:	09 d0                	or     %edx,%eax
40005411:	d3 ef                	shr    %cl,%edi
40005413:	89 fa                	mov    %edi,%edx
40005415:	f7 75 e0             	divl   0xffffffe0(%ebp)
40005418:	89 d1                	mov    %edx,%ecx
4000541a:	89 c7                	mov    %eax,%edi
4000541c:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
4000541f:	f7 e7                	mul    %edi
40005421:	39 d1                	cmp    %edx,%ecx
40005423:	89 c6                	mov    %eax,%esi
40005425:	89 55 dc             	mov    %edx,0xffffffdc(%ebp)
40005428:	72 6f                	jb     40005499 <__udivdi3+0x119>
4000542a:	39 ca                	cmp    %ecx,%edx
4000542c:	74 5e                	je     4000548c <__udivdi3+0x10c>
4000542e:	89 f9                	mov    %edi,%ecx
40005430:	31 f6                	xor    %esi,%esi
40005432:	e9 79 ff ff ff       	jmp    400053b0 <__udivdi3+0x30>
40005437:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
4000543a:	85 c0                	test   %eax,%eax
4000543c:	74 32                	je     40005470 <__udivdi3+0xf0>
4000543e:	89 f2                	mov    %esi,%edx
40005440:	89 f8                	mov    %edi,%eax
40005442:	f7 f1                	div    %ecx
40005444:	89 c6                	mov    %eax,%esi
40005446:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
40005449:	f7 f1                	div    %ecx
4000544b:	89 c1                	mov    %eax,%ecx
4000544d:	e9 5e ff ff ff       	jmp    400053b0 <__udivdi3+0x30>
40005452:	39 d7                	cmp    %edx,%edi
40005454:	77 2a                	ja     40005480 <__udivdi3+0x100>
40005456:	8b 55 f0             	mov    0xfffffff0(%ebp),%edx
40005459:	39 55 e8             	cmp    %edx,0xffffffe8(%ebp)
4000545c:	73 22                	jae    40005480 <__udivdi3+0x100>
4000545e:	66 90                	xchg   %ax,%ax
40005460:	31 c9                	xor    %ecx,%ecx
40005462:	31 f6                	xor    %esi,%esi
40005464:	e9 47 ff ff ff       	jmp    400053b0 <__udivdi3+0x30>
40005469:	8d b4 26 00 00 00 00 	lea    0x0(%esi),%esi
40005470:	b8 01 00 00 00       	mov    $0x1,%eax
40005475:	31 d2                	xor    %edx,%edx
40005477:	f7 75 f0             	divl   0xfffffff0(%ebp)
4000547a:	89 c1                	mov    %eax,%ecx
4000547c:	eb c0                	jmp    4000543e <__udivdi3+0xbe>
4000547e:	66 90                	xchg   %ax,%ax
40005480:	b9 01 00 00 00       	mov    $0x1,%ecx
40005485:	31 f6                	xor    %esi,%esi
40005487:	e9 24 ff ff ff       	jmp    400053b0 <__udivdi3+0x30>
4000548c:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
4000548f:	0f b6 4d e4          	movzbl 0xffffffe4(%ebp),%ecx
40005493:	d3 e0                	shl    %cl,%eax
40005495:	39 c6                	cmp    %eax,%esi
40005497:	76 95                	jbe    4000542e <__udivdi3+0xae>
40005499:	8d 4f ff             	lea    0xffffffff(%edi),%ecx
4000549c:	31 f6                	xor    %esi,%esi
4000549e:	e9 0d ff ff ff       	jmp    400053b0 <__udivdi3+0x30>
400054a3:	90                   	nop    
400054a4:	90                   	nop    
400054a5:	90                   	nop    
400054a6:	90                   	nop    
400054a7:	90                   	nop    
400054a8:	90                   	nop    
400054a9:	90                   	nop    
400054aa:	90                   	nop    
400054ab:	90                   	nop    
400054ac:	90                   	nop    
400054ad:	90                   	nop    
400054ae:	90                   	nop    
400054af:	90                   	nop    

400054b0 <__umoddi3>:
400054b0:	55                   	push   %ebp
400054b1:	89 e5                	mov    %esp,%ebp
400054b3:	57                   	push   %edi
400054b4:	56                   	push   %esi
400054b5:	83 ec 30             	sub    $0x30,%esp
400054b8:	8b 55 14             	mov    0x14(%ebp),%edx
400054bb:	8b 45 10             	mov    0x10(%ebp),%eax
400054be:	8b 75 08             	mov    0x8(%ebp),%esi
400054c1:	8b 7d 0c             	mov    0xc(%ebp),%edi
400054c4:	85 d2                	test   %edx,%edx
400054c6:	c7 45 d0 00 00 00 00 	movl   $0x0,0xffffffd0(%ebp)
400054cd:	89 c1                	mov    %eax,%ecx
400054cf:	c7 45 d4 00 00 00 00 	movl   $0x0,0xffffffd4(%ebp)
400054d6:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
400054d9:	89 55 e8             	mov    %edx,0xffffffe8(%ebp)
400054dc:	89 75 f0             	mov    %esi,0xfffffff0(%ebp)
400054df:	89 7d e0             	mov    %edi,0xffffffe0(%ebp)
400054e2:	75 1c                	jne    40005500 <__umoddi3+0x50>
400054e4:	39 f8                	cmp    %edi,%eax
400054e6:	89 fa                	mov    %edi,%edx
400054e8:	0f 86 d4 00 00 00    	jbe    400055c2 <__umoddi3+0x112>
400054ee:	89 f0                	mov    %esi,%eax
400054f0:	f7 f1                	div    %ecx
400054f2:	89 55 d0             	mov    %edx,0xffffffd0(%ebp)
400054f5:	c7 45 d4 00 00 00 00 	movl   $0x0,0xffffffd4(%ebp)
400054fc:	eb 12                	jmp    40005510 <__umoddi3+0x60>
400054fe:	66 90                	xchg   %ax,%ax
40005500:	8b 4d e0             	mov    0xffffffe0(%ebp),%ecx
40005503:	39 4d e8             	cmp    %ecx,0xffffffe8(%ebp)
40005506:	76 18                	jbe    40005520 <__umoddi3+0x70>
40005508:	89 75 d0             	mov    %esi,0xffffffd0(%ebp)
4000550b:	89 7d d4             	mov    %edi,0xffffffd4(%ebp)
4000550e:	66 90                	xchg   %ax,%ax
40005510:	8b 45 d0             	mov    0xffffffd0(%ebp),%eax
40005513:	8b 55 d4             	mov    0xffffffd4(%ebp),%edx
40005516:	83 c4 30             	add    $0x30,%esp
40005519:	5e                   	pop    %esi
4000551a:	5f                   	pop    %edi
4000551b:	5d                   	pop    %ebp
4000551c:	c3                   	ret    
4000551d:	8d 76 00             	lea    0x0(%esi),%esi
40005520:	0f bd 45 e8          	bsr    0xffffffe8(%ebp),%eax
40005524:	83 f0 1f             	xor    $0x1f,%eax
40005527:	89 45 dc             	mov    %eax,0xffffffdc(%ebp)
4000552a:	0f 84 c0 00 00 00    	je     400055f0 <__umoddi3+0x140>
40005530:	b8 20 00 00 00       	mov    $0x20,%eax
40005535:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
40005538:	2b 45 dc             	sub    0xffffffdc(%ebp),%eax
4000553b:	8b 7d ec             	mov    0xffffffec(%ebp),%edi
4000553e:	8b 75 f0             	mov    0xfffffff0(%ebp),%esi
40005541:	89 c1                	mov    %eax,%ecx
40005543:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
40005546:	d3 ea                	shr    %cl,%edx
40005548:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
4000554b:	0f b6 4d dc          	movzbl 0xffffffdc(%ebp),%ecx
4000554f:	d3 e0                	shl    %cl,%eax
40005551:	09 c2                	or     %eax,%edx
40005553:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
40005556:	d3 e7                	shl    %cl,%edi
40005558:	0f b6 4d e4          	movzbl 0xffffffe4(%ebp),%ecx
4000555c:	89 55 f4             	mov    %edx,0xfffffff4(%ebp)
4000555f:	8b 55 e0             	mov    0xffffffe0(%ebp),%edx
40005562:	d3 e8                	shr    %cl,%eax
40005564:	0f b6 4d dc          	movzbl 0xffffffdc(%ebp),%ecx
40005568:	d3 e2                	shl    %cl,%edx
4000556a:	09 d0                	or     %edx,%eax
4000556c:	8b 55 e0             	mov    0xffffffe0(%ebp),%edx
4000556f:	d3 e6                	shl    %cl,%esi
40005571:	0f b6 4d e4          	movzbl 0xffffffe4(%ebp),%ecx
40005575:	d3 ea                	shr    %cl,%edx
40005577:	f7 75 f4             	divl   0xfffffff4(%ebp)
4000557a:	89 55 cc             	mov    %edx,0xffffffcc(%ebp)
4000557d:	f7 e7                	mul    %edi
4000557f:	39 55 cc             	cmp    %edx,0xffffffcc(%ebp)
40005582:	0f 82 a5 00 00 00    	jb     4000562d <__umoddi3+0x17d>
40005588:	3b 55 cc             	cmp    0xffffffcc(%ebp),%edx
4000558b:	0f 84 94 00 00 00    	je     40005625 <__umoddi3+0x175>
40005591:	8b 4d cc             	mov    0xffffffcc(%ebp),%ecx
40005594:	29 c6                	sub    %eax,%esi
40005596:	19 d1                	sbb    %edx,%ecx
40005598:	89 4d cc             	mov    %ecx,0xffffffcc(%ebp)
4000559b:	0f b6 4d dc          	movzbl 0xffffffdc(%ebp),%ecx
4000559f:	89 f2                	mov    %esi,%edx
400055a1:	8b 45 cc             	mov    0xffffffcc(%ebp),%eax
400055a4:	d3 ea                	shr    %cl,%edx
400055a6:	0f b6 4d e4          	movzbl 0xffffffe4(%ebp),%ecx
400055aa:	d3 e0                	shl    %cl,%eax
400055ac:	0f b6 4d dc          	movzbl 0xffffffdc(%ebp),%ecx
400055b0:	09 c2                	or     %eax,%edx
400055b2:	8b 45 cc             	mov    0xffffffcc(%ebp),%eax
400055b5:	89 55 d0             	mov    %edx,0xffffffd0(%ebp)
400055b8:	d3 e8                	shr    %cl,%eax
400055ba:	89 45 d4             	mov    %eax,0xffffffd4(%ebp)
400055bd:	e9 4e ff ff ff       	jmp    40005510 <__umoddi3+0x60>
400055c2:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
400055c5:	85 c0                	test   %eax,%eax
400055c7:	74 17                	je     400055e0 <__umoddi3+0x130>
400055c9:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
400055cc:	8b 55 e8             	mov    0xffffffe8(%ebp),%edx
400055cf:	f7 f1                	div    %ecx
400055d1:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
400055d4:	f7 f1                	div    %ecx
400055d6:	e9 17 ff ff ff       	jmp    400054f2 <__umoddi3+0x42>
400055db:	90                   	nop    
400055dc:	8d 74 26 00          	lea    0x0(%esi),%esi
400055e0:	b8 01 00 00 00       	mov    $0x1,%eax
400055e5:	31 d2                	xor    %edx,%edx
400055e7:	f7 75 ec             	divl   0xffffffec(%ebp)
400055ea:	89 c1                	mov    %eax,%ecx
400055ec:	eb db                	jmp    400055c9 <__umoddi3+0x119>
400055ee:	66 90                	xchg   %ax,%ax
400055f0:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
400055f3:	39 45 e0             	cmp    %eax,0xffffffe0(%ebp)
400055f6:	77 19                	ja     40005611 <__umoddi3+0x161>
400055f8:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
400055fb:	39 55 f0             	cmp    %edx,0xfffffff0(%ebp)
400055fe:	73 11                	jae    40005611 <__umoddi3+0x161>
40005600:	8b 55 f0             	mov    0xfffffff0(%ebp),%edx
40005603:	8b 4d e0             	mov    0xffffffe0(%ebp),%ecx
40005606:	89 55 d0             	mov    %edx,0xffffffd0(%ebp)
40005609:	89 4d d4             	mov    %ecx,0xffffffd4(%ebp)
4000560c:	e9 ff fe ff ff       	jmp    40005510 <__umoddi3+0x60>
40005611:	8b 4d e0             	mov    0xffffffe0(%ebp),%ecx
40005614:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
40005617:	2b 45 ec             	sub    0xffffffec(%ebp),%eax
4000561a:	1b 4d e8             	sbb    0xffffffe8(%ebp),%ecx
4000561d:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
40005620:	89 4d e0             	mov    %ecx,0xffffffe0(%ebp)
40005623:	eb db                	jmp    40005600 <__umoddi3+0x150>
40005625:	39 f0                	cmp    %esi,%eax
40005627:	0f 86 64 ff ff ff    	jbe    40005591 <__umoddi3+0xe1>
4000562d:	29 f8                	sub    %edi,%eax
4000562f:	1b 55 f4             	sbb    0xfffffff4(%ebp),%edx
40005632:	e9 5a ff ff ff       	jmp    40005591 <__umoddi3+0xe1>
