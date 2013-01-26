
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

	# Set the stack pointer
	movl	$(cpu_boot+4096),%esp
  10001a:	bc 00 60 10 00       	mov    $0x106000,%esp

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
  10002b:	83 ec 18             	sub    $0x18,%esp
	extern char start[], edata[], end[];

	// Before anything else, complete the ELF loading process.
	// Clear all uninitialized global data (BSS) in our program,
	// ensuring that all static/global variables start out zero.
	if (cpu_onboot())
  10002e:	e8 60 00 00 00       	call   100093 <cpu_onboot>
  100033:	85 c0                	test   %eax,%eax
  100035:	74 28                	je     10005f <init+0x37>
		memset(edata, 0, end - edata);
  100037:	ba 84 7f 10 00       	mov    $0x107f84,%edx
  10003c:	b8 30 65 10 00       	mov    $0x106530,%eax
  100041:	89 d1                	mov    %edx,%ecx
  100043:	29 c1                	sub    %eax,%ecx
  100045:	89 c8                	mov    %ecx,%eax
  100047:	89 44 24 08          	mov    %eax,0x8(%esp)
  10004b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  100052:	00 
  100053:	c7 04 24 30 65 10 00 	movl   $0x106530,(%esp)
  10005a:	e8 8a 25 00 00       	call   1025e9 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
  10005f:	e8 f5 01 00 00       	call   100259 <cons_init>

	// Lab 1: test cprintf and debug_trace
	cprintf("1234 decimal is %o octal!\n", 1234);
  100064:	c7 44 24 04 d2 04 00 	movl   $0x4d2,0x4(%esp)
  10006b:	00 
  10006c:	c7 04 24 c0 2a 10 00 	movl   $0x102ac0,(%esp)
  100073:	e8 79 23 00 00       	call   1023f1 <cprintf>
	debug_check();
  100078:	e8 86 04 00 00       	call   100503 <debug_check>

	// Initialize and load the bootstrap CPU's GDT, TSS, and IDT.
	cpu_init();
  10007d:	e8 8a 0d 00 00       	call   100e0c <cpu_init>
	trap_init();
  100082:	e8 4f 0e 00 00       	call   100ed6 <trap_init>

	// Physical memory detection/initialization.
	// Can't call mem_alloc until after we do this!
	mem_init();
  100087:	e8 b8 06 00 00       	call   100744 <mem_init>


	// Lab 1: change this so it enters user() in user mode,
	// running on the user_stack declared above,
	// instead of just calling user() directly.
	user();
  10008c:	e8 6d 00 00 00       	call   1000fe <user>
}
  100091:	c9                   	leave  
  100092:	c3                   	ret    

00100093 <cpu_onboot>:
}

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  100093:	55                   	push   %ebp
  100094:	89 e5                	mov    %esp,%ebp
  100096:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  100099:	e8 0d 00 00 00       	call   1000ab <cpu_cur>
  10009e:	3d 00 50 10 00       	cmp    $0x105000,%eax
  1000a3:	0f 94 c0             	sete   %al
  1000a6:	0f b6 c0             	movzbl %al,%eax
}
  1000a9:	c9                   	leave  
  1000aa:	c3                   	ret    

001000ab <cpu_cur>:
  1000ab:	55                   	push   %ebp
  1000ac:	89 e5                	mov    %esp,%ebp
  1000ae:	83 ec 28             	sub    $0x28,%esp
static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  1000b1:	89 65 fc             	mov    %esp,0xfffffffc(%ebp)
        return esp;
  1000b4:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  1000b7:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  1000ba:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1000bd:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1000c2:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	assert(c->magic == CPU_MAGIC);
  1000c5:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  1000c8:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
  1000ce:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  1000d3:	74 24                	je     1000f9 <cpu_cur+0x4e>
  1000d5:	c7 44 24 0c db 2a 10 	movl   $0x102adb,0xc(%esp)
  1000dc:	00 
  1000dd:	c7 44 24 08 f1 2a 10 	movl   $0x102af1,0x8(%esp)
  1000e4:	00 
  1000e5:	c7 44 24 04 50 00 00 	movl   $0x50,0x4(%esp)
  1000ec:	00 
  1000ed:	c7 04 24 06 2b 10 00 	movl   $0x102b06,(%esp)
  1000f4:	e8 3b 02 00 00       	call   100334 <debug_panic>
	return c;
  1000f9:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
}
  1000fc:	c9                   	leave  
  1000fd:	c3                   	ret    

001000fe <user>:

// This is the first function that gets run in user mode (ring 3).
// It acts as PIOS's "root process",
// of which all other processes are descendants.
void
user()
{
  1000fe:	55                   	push   %ebp
  1000ff:	89 e5                	mov    %esp,%ebp
  100101:	83 ec 28             	sub    $0x28,%esp
	cprintf("in user()\n");
  100104:	c7 04 24 13 2b 10 00 	movl   $0x102b13,(%esp)
  10010b:	e8 e1 22 00 00       	call   1023f1 <cprintf>
static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  100110:	89 65 f8             	mov    %esp,0xfffffff8(%ebp)
        return esp;
  100113:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  100116:	89 c2                	mov    %eax,%edx
	assert(read_esp() > (uint32_t) &user_stack[0]);
  100118:	b8 40 65 10 00       	mov    $0x106540,%eax
  10011d:	39 c2                	cmp    %eax,%edx
  10011f:	77 24                	ja     100145 <user+0x47>
  100121:	c7 44 24 0c 20 2b 10 	movl   $0x102b20,0xc(%esp)
  100128:	00 
  100129:	c7 44 24 08 f1 2a 10 	movl   $0x102af1,0x8(%esp)
  100130:	00 
  100131:	c7 44 24 04 50 00 00 	movl   $0x50,0x4(%esp)
  100138:	00 
  100139:	c7 04 24 47 2b 10 00 	movl   $0x102b47,(%esp)
  100140:	e8 ef 01 00 00       	call   100334 <debug_panic>
static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  100145:	89 65 fc             	mov    %esp,0xfffffffc(%ebp)
        return esp;
  100148:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  10014b:	89 c2                	mov    %eax,%edx
	assert(read_esp() < (uint32_t) &user_stack[sizeof(user_stack)]);
  10014d:	b8 40 75 10 00       	mov    $0x107540,%eax
  100152:	39 c2                	cmp    %eax,%edx
  100154:	72 24                	jb     10017a <user+0x7c>
  100156:	c7 44 24 0c 54 2b 10 	movl   $0x102b54,0xc(%esp)
  10015d:	00 
  10015e:	c7 44 24 08 f1 2a 10 	movl   $0x102af1,0x8(%esp)
  100165:	00 
  100166:	c7 44 24 04 51 00 00 	movl   $0x51,0x4(%esp)
  10016d:	00 
  10016e:	c7 04 24 47 2b 10 00 	movl   $0x102b47,(%esp)
  100175:	e8 ba 01 00 00       	call   100334 <debug_panic>

	// Check that we're in user mode and can handle traps from there.
	trap_check_user();
  10017a:	e8 d5 10 00 00       	call   101254 <trap_check_user>

	done();
  10017f:	e8 00 00 00 00       	call   100184 <done>

00100184 <done>:
}

// This is a function that we call when the kernel is "done" -
// it just puts the processor into an infinite loop.
// We make this a function so that we can set a breakpoints on it.
// Our grade scripts use this breakpoint to know when to stop QEMU.
void gcc_noreturn
done()
{
  100184:	55                   	push   %ebp
  100185:	89 e5                	mov    %esp,%ebp
	while (1)
		;	// just spin
  100187:	eb fe                	jmp    100187 <done+0x3>
  100189:	90                   	nop    
  10018a:	90                   	nop    
  10018b:	90                   	nop    

0010018c <cons_intr>:
// called by device interrupt routines to feed input characters
// into the circular console input buffer.
void
cons_intr(int (*proc)(void))
{
  10018c:	55                   	push   %ebp
  10018d:	89 e5                	mov    %esp,%ebp
  10018f:	83 ec 18             	sub    $0x18,%esp
	int c;

	while ((c = (*proc)()) != -1) {
  100192:	eb 33                	jmp    1001c7 <cons_intr+0x3b>
		if (c == 0)
  100194:	83 7d fc 00          	cmpl   $0x0,0xfffffffc(%ebp)
  100198:	74 2d                	je     1001c7 <cons_intr+0x3b>
			continue;
		cons.buf[cons.wpos++] = c;
  10019a:	8b 15 44 77 10 00    	mov    0x107744,%edx
  1001a0:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  1001a3:	88 82 40 75 10 00    	mov    %al,0x107540(%edx)
  1001a9:	8d 42 01             	lea    0x1(%edx),%eax
  1001ac:	a3 44 77 10 00       	mov    %eax,0x107744
		if (cons.wpos == CONSBUFSIZE)
  1001b1:	a1 44 77 10 00       	mov    0x107744,%eax
  1001b6:	3d 00 02 00 00       	cmp    $0x200,%eax
  1001bb:	75 0a                	jne    1001c7 <cons_intr+0x3b>
			cons.wpos = 0;
  1001bd:	c7 05 44 77 10 00 00 	movl   $0x0,0x107744
  1001c4:	00 00 00 
  1001c7:	8b 45 08             	mov    0x8(%ebp),%eax
  1001ca:	ff d0                	call   *%eax
  1001cc:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  1001cf:	83 7d fc ff          	cmpl   $0xffffffff,0xfffffffc(%ebp)
  1001d3:	75 bf                	jne    100194 <cons_intr+0x8>
	}
}
  1001d5:	c9                   	leave  
  1001d6:	c3                   	ret    

001001d7 <cons_getc>:

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
  1001d7:	55                   	push   %ebp
  1001d8:	89 e5                	mov    %esp,%ebp
  1001da:	83 ec 18             	sub    $0x18,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
  1001dd:	e8 52 18 00 00       	call   101a34 <serial_intr>
	kbd_intr();
  1001e2:	e8 a9 17 00 00       	call   101990 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
  1001e7:	8b 15 40 77 10 00    	mov    0x107740,%edx
  1001ed:	a1 44 77 10 00       	mov    0x107744,%eax
  1001f2:	39 c2                	cmp    %eax,%edx
  1001f4:	74 39                	je     10022f <cons_getc+0x58>
		c = cons.buf[cons.rpos++];
  1001f6:	8b 15 40 77 10 00    	mov    0x107740,%edx
  1001fc:	0f b6 82 40 75 10 00 	movzbl 0x107540(%edx),%eax
  100203:	0f b6 c0             	movzbl %al,%eax
  100206:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  100209:	8d 42 01             	lea    0x1(%edx),%eax
  10020c:	a3 40 77 10 00       	mov    %eax,0x107740
		if (cons.rpos == CONSBUFSIZE)
  100211:	a1 40 77 10 00       	mov    0x107740,%eax
  100216:	3d 00 02 00 00       	cmp    $0x200,%eax
  10021b:	75 0a                	jne    100227 <cons_getc+0x50>
			cons.rpos = 0;
  10021d:	c7 05 40 77 10 00 00 	movl   $0x0,0x107740
  100224:	00 00 00 
		return c;
  100227:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  10022a:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  10022d:	eb 07                	jmp    100236 <cons_getc+0x5f>
	}
	return 0;
  10022f:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  100236:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
}
  100239:	c9                   	leave  
  10023a:	c3                   	ret    

0010023b <cons_putc>:

// output a character to the console
static void
cons_putc(int c)
{
  10023b:	55                   	push   %ebp
  10023c:	89 e5                	mov    %esp,%ebp
  10023e:	83 ec 08             	sub    $0x8,%esp
	serial_putc(c);
  100241:	8b 45 08             	mov    0x8(%ebp),%eax
  100244:	89 04 24             	mov    %eax,(%esp)
  100247:	e8 05 18 00 00       	call   101a51 <serial_putc>
	video_putc(c);
  10024c:	8b 45 08             	mov    0x8(%ebp),%eax
  10024f:	89 04 24             	mov    %eax,(%esp)
  100252:	e8 75 13 00 00       	call   1015cc <video_putc>
}
  100257:	c9                   	leave  
  100258:	c3                   	ret    

00100259 <cons_init>:

// initialize the console devices
void
cons_init(void)
{
  100259:	55                   	push   %ebp
  10025a:	89 e5                	mov    %esp,%ebp
  10025c:	83 ec 18             	sub    $0x18,%esp
	if (!cpu_onboot())	// only do once, on the boot CPU
  10025f:	e8 3a 00 00 00       	call   10029e <cpu_onboot>
  100264:	85 c0                	test   %eax,%eax
  100266:	74 34                	je     10029c <cons_init+0x43>
		return;

	video_init();
  100268:	e8 97 12 00 00       	call   101504 <video_init>
	kbd_init();
  10026d:	e8 32 17 00 00       	call   1019a4 <kbd_init>
	serial_init();
  100272:	e8 3a 18 00 00       	call   101ab1 <serial_init>

	if (!serial_exists)
  100277:	a1 80 7f 10 00       	mov    0x107f80,%eax
  10027c:	85 c0                	test   %eax,%eax
  10027e:	75 1c                	jne    10029c <cons_init+0x43>
		warn("Serial port does not exist!\n");
  100280:	c7 44 24 08 8c 2b 10 	movl   $0x102b8c,0x8(%esp)
  100287:	00 
  100288:	c7 44 24 04 69 00 00 	movl   $0x69,0x4(%esp)
  10028f:	00 
  100290:	c7 04 24 a9 2b 10 00 	movl   $0x102ba9,(%esp)
  100297:	e8 56 01 00 00       	call   1003f2 <debug_warn>
}
  10029c:	c9                   	leave  
  10029d:	c3                   	ret    

0010029e <cpu_onboot>:
}

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  10029e:	55                   	push   %ebp
  10029f:	89 e5                	mov    %esp,%ebp
  1002a1:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  1002a4:	e8 0d 00 00 00       	call   1002b6 <cpu_cur>
  1002a9:	3d 00 50 10 00       	cmp    $0x105000,%eax
  1002ae:	0f 94 c0             	sete   %al
  1002b1:	0f b6 c0             	movzbl %al,%eax
}
  1002b4:	c9                   	leave  
  1002b5:	c3                   	ret    

001002b6 <cpu_cur>:
  1002b6:	55                   	push   %ebp
  1002b7:	89 e5                	mov    %esp,%ebp
  1002b9:	83 ec 28             	sub    $0x28,%esp
static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  1002bc:	89 65 fc             	mov    %esp,0xfffffffc(%ebp)
        return esp;
  1002bf:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  1002c2:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  1002c5:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1002c8:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1002cd:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	assert(c->magic == CPU_MAGIC);
  1002d0:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  1002d3:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
  1002d9:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  1002de:	74 24                	je     100304 <cpu_cur+0x4e>
  1002e0:	c7 44 24 0c b5 2b 10 	movl   $0x102bb5,0xc(%esp)
  1002e7:	00 
  1002e8:	c7 44 24 08 cb 2b 10 	movl   $0x102bcb,0x8(%esp)
  1002ef:	00 
  1002f0:	c7 44 24 04 50 00 00 	movl   $0x50,0x4(%esp)
  1002f7:	00 
  1002f8:	c7 04 24 e0 2b 10 00 	movl   $0x102be0,(%esp)
  1002ff:	e8 30 00 00 00       	call   100334 <debug_panic>
	return c;
  100304:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
}
  100307:	c9                   	leave  
  100308:	c3                   	ret    

00100309 <cputs>:


// `High'-level console I/O.  Used by readline and cprintf.
void
cputs(const char *str)
{
  100309:	55                   	push   %ebp
  10030a:	89 e5                	mov    %esp,%ebp
  10030c:	83 ec 18             	sub    $0x18,%esp
	char ch;
	while (*str)
  10030f:	eb 15                	jmp    100326 <cputs+0x1d>
		cons_putc(*str++);
  100311:	8b 45 08             	mov    0x8(%ebp),%eax
  100314:	0f b6 00             	movzbl (%eax),%eax
  100317:	0f be c0             	movsbl %al,%eax
  10031a:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  10031e:	89 04 24             	mov    %eax,(%esp)
  100321:	e8 15 ff ff ff       	call   10023b <cons_putc>
  100326:	8b 45 08             	mov    0x8(%ebp),%eax
  100329:	0f b6 00             	movzbl (%eax),%eax
  10032c:	84 c0                	test   %al,%al
  10032e:	75 e1                	jne    100311 <cputs+0x8>
}
  100330:	c9                   	leave  
  100331:	c3                   	ret    
  100332:	90                   	nop    
  100333:	90                   	nop    

00100334 <debug_panic>:
// Panic is called on unresolvable fatal errors.
// It prints "panic: mesg", and then enters the kernel monitor.
void
debug_panic(const char *file, int line, const char *fmt,...)
{
  100334:	55                   	push   %ebp
  100335:	89 e5                	mov    %esp,%ebp
  100337:	83 ec 58             	sub    $0x58,%esp
static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  10033a:	8c 4d fa             	movw   %cs,0xfffffffa(%ebp)
        return cs;
  10033d:	0f b7 45 fa          	movzwl 0xfffffffa(%ebp),%eax
	va_list ap;
	int i;

	// Avoid infinite recursion if we're panicking from kernel mode.
	if ((read_cs() & 3) == 0) {
  100341:	0f b7 c0             	movzwl %ax,%eax
  100344:	83 e0 03             	and    $0x3,%eax
  100347:	85 c0                	test   %eax,%eax
  100349:	75 15                	jne    100360 <debug_panic+0x2c>
		if (panicstr)
  10034b:	a1 48 77 10 00       	mov    0x107748,%eax
  100350:	85 c0                	test   %eax,%eax
  100352:	0f 85 95 00 00 00    	jne    1003ed <debug_panic+0xb9>
			goto dead;
		panicstr = fmt;
  100358:	8b 45 10             	mov    0x10(%ebp),%eax
  10035b:	a3 48 77 10 00       	mov    %eax,0x107748
	}

	// First print the requested message
	va_start(ap, fmt);
  100360:	8d 45 10             	lea    0x10(%ebp),%eax
  100363:	83 c0 04             	add    $0x4,%eax
  100366:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
	cprintf("kernel panic at %s:%d: ", file, line);
  100369:	8b 45 0c             	mov    0xc(%ebp),%eax
  10036c:	89 44 24 08          	mov    %eax,0x8(%esp)
  100370:	8b 45 08             	mov    0x8(%ebp),%eax
  100373:	89 44 24 04          	mov    %eax,0x4(%esp)
  100377:	c7 04 24 ed 2b 10 00 	movl   $0x102bed,(%esp)
  10037e:	e8 6e 20 00 00       	call   1023f1 <cprintf>
	vcprintf(fmt, ap);
  100383:	8b 55 10             	mov    0x10(%ebp),%edx
  100386:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  100389:	89 44 24 04          	mov    %eax,0x4(%esp)
  10038d:	89 14 24             	mov    %edx,(%esp)
  100390:	e8 f3 1f 00 00       	call   102388 <vcprintf>
	cprintf("\n");
  100395:	c7 04 24 05 2c 10 00 	movl   $0x102c05,(%esp)
  10039c:	e8 50 20 00 00       	call   1023f1 <cprintf>
static gcc_inline uint32_t
read_ebp(void)
{
        uint32_t ebp;
        __asm __volatile("movl %%ebp,%0" : "=rm" (ebp));
  1003a1:	89 6d fc             	mov    %ebp,0xfffffffc(%ebp)
        return ebp;
  1003a4:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  1003a7:	89 c2                	mov    %eax,%edx
	va_end(ap);

	// Then print a backtrace of the kernel call chain
	uint32_t eips[DEBUG_TRACEFRAMES];
	debug_trace(read_ebp(), eips);
  1003a9:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
  1003ac:	89 44 24 04          	mov    %eax,0x4(%esp)
  1003b0:	89 14 24             	mov    %edx,(%esp)
  1003b3:	e8 83 00 00 00       	call   10043b <debug_trace>
	for (i = 0; i < DEBUG_TRACEFRAMES && eips[i] != 0; i++)
  1003b8:	c7 45 f4 00 00 00 00 	movl   $0x0,0xfffffff4(%ebp)
  1003bf:	eb 1b                	jmp    1003dc <debug_panic+0xa8>
		cprintf("  from %08x\n", eips[i]);
  1003c1:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  1003c4:	8b 44 85 c8          	mov    0xffffffc8(%ebp,%eax,4),%eax
  1003c8:	89 44 24 04          	mov    %eax,0x4(%esp)
  1003cc:	c7 04 24 07 2c 10 00 	movl   $0x102c07,(%esp)
  1003d3:	e8 19 20 00 00       	call   1023f1 <cprintf>
  1003d8:	83 45 f4 01          	addl   $0x1,0xfffffff4(%ebp)
  1003dc:	83 7d f4 09          	cmpl   $0x9,0xfffffff4(%ebp)
  1003e0:	7f 0b                	jg     1003ed <debug_panic+0xb9>
  1003e2:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  1003e5:	8b 44 85 c8          	mov    0xffffffc8(%ebp,%eax,4),%eax
  1003e9:	85 c0                	test   %eax,%eax
  1003eb:	75 d4                	jne    1003c1 <debug_panic+0x8d>

dead:
	done();		// enter infinite loop (see kern/init.c)
  1003ed:	e8 92 fd ff ff       	call   100184 <done>

001003f2 <debug_warn>:
}

/* like panic, but don't */
void
debug_warn(const char *file, int line, const char *fmt,...)
{
  1003f2:	55                   	push   %ebp
  1003f3:	89 e5                	mov    %esp,%ebp
  1003f5:	83 ec 28             	sub    $0x28,%esp
	va_list ap;

	va_start(ap, fmt);
  1003f8:	8d 45 10             	lea    0x10(%ebp),%eax
  1003fb:	83 c0 04             	add    $0x4,%eax
  1003fe:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	cprintf("kernel warning at %s:%d: ", file, line);
  100401:	8b 45 0c             	mov    0xc(%ebp),%eax
  100404:	89 44 24 08          	mov    %eax,0x8(%esp)
  100408:	8b 45 08             	mov    0x8(%ebp),%eax
  10040b:	89 44 24 04          	mov    %eax,0x4(%esp)
  10040f:	c7 04 24 14 2c 10 00 	movl   $0x102c14,(%esp)
  100416:	e8 d6 1f 00 00       	call   1023f1 <cprintf>
	vcprintf(fmt, ap);
  10041b:	8b 55 10             	mov    0x10(%ebp),%edx
  10041e:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  100421:	89 44 24 04          	mov    %eax,0x4(%esp)
  100425:	89 14 24             	mov    %edx,(%esp)
  100428:	e8 5b 1f 00 00       	call   102388 <vcprintf>
	cprintf("\n");
  10042d:	c7 04 24 05 2c 10 00 	movl   $0x102c05,(%esp)
  100434:	e8 b8 1f 00 00       	call   1023f1 <cprintf>
	va_end(ap);
}
  100439:	c9                   	leave  
  10043a:	c3                   	ret    

0010043b <debug_trace>:

// Record the current call stack in eips[] by following the %ebp chain.
void gcc_noinline
debug_trace(uint32_t ebp, uint32_t eips[DEBUG_TRACEFRAMES])
{
  10043b:	55                   	push   %ebp
  10043c:	89 e5                	mov    %esp,%ebp
  10043e:	83 ec 10             	sub    $0x10,%esp
  int i;
  uint32_t prev_ebp = ebp;
  100441:	8b 45 08             	mov    0x8(%ebp),%eax
  100444:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  for (i = 0; i < DEBUG_TRACEFRAMES; i++) {
  100447:	c7 45 f8 00 00 00 00 	movl   $0x0,0xfffffff8(%ebp)
  10044e:	eb 1c                	jmp    10046c <debug_trace+0x31>
    eips[i] = prev_ebp;
  100450:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  100453:	c1 e0 02             	shl    $0x2,%eax
  100456:	89 c2                	mov    %eax,%edx
  100458:	03 55 0c             	add    0xc(%ebp),%edx
  10045b:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  10045e:	89 02                	mov    %eax,(%edx)
    prev_ebp = *(uint32_t *)prev_ebp;
  100460:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  100463:	8b 00                	mov    (%eax),%eax
  100465:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  100468:	83 45 f8 01          	addl   $0x1,0xfffffff8(%ebp)
  10046c:	83 7d f8 09          	cmpl   $0x9,0xfffffff8(%ebp)
  100470:	7e de                	jle    100450 <debug_trace+0x15>
  }
}
  100472:	c9                   	leave  
  100473:	c3                   	ret    

00100474 <f3>:


static void gcc_noinline f3(int r, uint32_t *e) { debug_trace(read_ebp(), e); }
  100474:	55                   	push   %ebp
  100475:	89 e5                	mov    %esp,%ebp
  100477:	83 ec 18             	sub    $0x18,%esp
static gcc_inline uint32_t
read_ebp(void)
{
        uint32_t ebp;
        __asm __volatile("movl %%ebp,%0" : "=rm" (ebp));
  10047a:	89 6d fc             	mov    %ebp,0xfffffffc(%ebp)
        return ebp;
  10047d:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  100480:	89 c2                	mov    %eax,%edx
  100482:	8b 45 0c             	mov    0xc(%ebp),%eax
  100485:	89 44 24 04          	mov    %eax,0x4(%esp)
  100489:	89 14 24             	mov    %edx,(%esp)
  10048c:	e8 aa ff ff ff       	call   10043b <debug_trace>
  100491:	c9                   	leave  
  100492:	c3                   	ret    

00100493 <f2>:
static void gcc_noinline f2(int r, uint32_t *e) { r & 2 ? f3(r,e) : f3(r,e); }
  100493:	55                   	push   %ebp
  100494:	89 e5                	mov    %esp,%ebp
  100496:	83 ec 08             	sub    $0x8,%esp
  100499:	8b 45 08             	mov    0x8(%ebp),%eax
  10049c:	83 e0 02             	and    $0x2,%eax
  10049f:	85 c0                	test   %eax,%eax
  1004a1:	74 14                	je     1004b7 <f2+0x24>
  1004a3:	8b 45 0c             	mov    0xc(%ebp),%eax
  1004a6:	89 44 24 04          	mov    %eax,0x4(%esp)
  1004aa:	8b 45 08             	mov    0x8(%ebp),%eax
  1004ad:	89 04 24             	mov    %eax,(%esp)
  1004b0:	e8 bf ff ff ff       	call   100474 <f3>
  1004b5:	eb 12                	jmp    1004c9 <f2+0x36>
  1004b7:	8b 45 0c             	mov    0xc(%ebp),%eax
  1004ba:	89 44 24 04          	mov    %eax,0x4(%esp)
  1004be:	8b 45 08             	mov    0x8(%ebp),%eax
  1004c1:	89 04 24             	mov    %eax,(%esp)
  1004c4:	e8 ab ff ff ff       	call   100474 <f3>
  1004c9:	c9                   	leave  
  1004ca:	c3                   	ret    

001004cb <f1>:
static void gcc_noinline f1(int r, uint32_t *e) { r & 1 ? f2(r,e) : f2(r,e); }
  1004cb:	55                   	push   %ebp
  1004cc:	89 e5                	mov    %esp,%ebp
  1004ce:	83 ec 08             	sub    $0x8,%esp
  1004d1:	8b 45 08             	mov    0x8(%ebp),%eax
  1004d4:	83 e0 01             	and    $0x1,%eax
  1004d7:	84 c0                	test   %al,%al
  1004d9:	74 14                	je     1004ef <f1+0x24>
  1004db:	8b 45 0c             	mov    0xc(%ebp),%eax
  1004de:	89 44 24 04          	mov    %eax,0x4(%esp)
  1004e2:	8b 45 08             	mov    0x8(%ebp),%eax
  1004e5:	89 04 24             	mov    %eax,(%esp)
  1004e8:	e8 a6 ff ff ff       	call   100493 <f2>
  1004ed:	eb 12                	jmp    100501 <f1+0x36>
  1004ef:	8b 45 0c             	mov    0xc(%ebp),%eax
  1004f2:	89 44 24 04          	mov    %eax,0x4(%esp)
  1004f6:	8b 45 08             	mov    0x8(%ebp),%eax
  1004f9:	89 04 24             	mov    %eax,(%esp)
  1004fc:	e8 92 ff ff ff       	call   100493 <f2>
  100501:	c9                   	leave  
  100502:	c3                   	ret    

00100503 <debug_check>:

// Test the backtrace implementation for correct operation
void
debug_check(void)
{
  100503:	55                   	push   %ebp
  100504:	89 e5                	mov    %esp,%ebp
  100506:	81 ec c8 00 00 00    	sub    $0xc8,%esp
	uint32_t eips[4][DEBUG_TRACEFRAMES];
	int r, i;

	// produce several related backtraces...
	for (i = 0; i < 4; i++)
  10050c:	c7 45 fc 00 00 00 00 	movl   $0x0,0xfffffffc(%ebp)
  100513:	eb 2a                	jmp    10053f <debug_check+0x3c>
		f1(i, eips[i]);
  100515:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  100518:	89 d0                	mov    %edx,%eax
  10051a:	c1 e0 02             	shl    $0x2,%eax
  10051d:	01 d0                	add    %edx,%eax
  10051f:	c1 e0 03             	shl    $0x3,%eax
  100522:	89 c2                	mov    %eax,%edx
  100524:	8d 85 58 ff ff ff    	lea    0xffffff58(%ebp),%eax
  10052a:	01 d0                	add    %edx,%eax
  10052c:	89 44 24 04          	mov    %eax,0x4(%esp)
  100530:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  100533:	89 04 24             	mov    %eax,(%esp)
  100536:	e8 90 ff ff ff       	call   1004cb <f1>
  10053b:	83 45 fc 01          	addl   $0x1,0xfffffffc(%ebp)
  10053f:	83 7d fc 03          	cmpl   $0x3,0xfffffffc(%ebp)
  100543:	7e d0                	jle    100515 <debug_check+0x12>

	// ...and make sure they come out correctly.
	for (r = 0; r < 4; r++)
  100545:	c7 45 f8 00 00 00 00 	movl   $0x0,0xfffffff8(%ebp)
  10054c:	e9 bc 00 00 00       	jmp    10060d <debug_check+0x10a>
		for (i = 0; i < DEBUG_TRACEFRAMES; i++) {
  100551:	c7 45 fc 00 00 00 00 	movl   $0x0,0xfffffffc(%ebp)
  100558:	e9 a2 00 00 00       	jmp    1005ff <debug_check+0xfc>
			assert((eips[r][i] != 0) == (i < 5));
  10055d:	8b 55 f8             	mov    0xfffffff8(%ebp),%edx
  100560:	8b 4d fc             	mov    0xfffffffc(%ebp),%ecx
  100563:	89 d0                	mov    %edx,%eax
  100565:	c1 e0 02             	shl    $0x2,%eax
  100568:	01 d0                	add    %edx,%eax
  10056a:	01 c0                	add    %eax,%eax
  10056c:	01 c8                	add    %ecx,%eax
  10056e:	8b 84 85 58 ff ff ff 	mov    0xffffff58(%ebp,%eax,4),%eax
  100575:	85 c0                	test   %eax,%eax
  100577:	0f 95 c2             	setne  %dl
  10057a:	83 7d fc 04          	cmpl   $0x4,0xfffffffc(%ebp)
  10057e:	0f 9e c0             	setle  %al
  100581:	31 d0                	xor    %edx,%eax
  100583:	84 c0                	test   %al,%al
  100585:	74 24                	je     1005ab <debug_check+0xa8>
  100587:	c7 44 24 0c 2e 2c 10 	movl   $0x102c2e,0xc(%esp)
  10058e:	00 
  10058f:	c7 44 24 08 4b 2c 10 	movl   $0x102c4b,0x8(%esp)
  100596:	00 
  100597:	c7 44 24 04 65 00 00 	movl   $0x65,0x4(%esp)
  10059e:	00 
  10059f:	c7 04 24 60 2c 10 00 	movl   $0x102c60,(%esp)
  1005a6:	e8 89 fd ff ff       	call   100334 <debug_panic>
			if (i >= 2)
  1005ab:	83 7d fc 01          	cmpl   $0x1,0xfffffffc(%ebp)
  1005af:	7e 4a                	jle    1005fb <debug_check+0xf8>
				assert(eips[r][i] == eips[0][i]);
  1005b1:	8b 55 f8             	mov    0xfffffff8(%ebp),%edx
  1005b4:	8b 4d fc             	mov    0xfffffffc(%ebp),%ecx
  1005b7:	89 d0                	mov    %edx,%eax
  1005b9:	c1 e0 02             	shl    $0x2,%eax
  1005bc:	01 d0                	add    %edx,%eax
  1005be:	01 c0                	add    %eax,%eax
  1005c0:	01 c8                	add    %ecx,%eax
  1005c2:	8b 94 85 58 ff ff ff 	mov    0xffffff58(%ebp,%eax,4),%edx
  1005c9:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  1005cc:	8b 84 85 58 ff ff ff 	mov    0xffffff58(%ebp,%eax,4),%eax
  1005d3:	39 c2                	cmp    %eax,%edx
  1005d5:	74 24                	je     1005fb <debug_check+0xf8>
  1005d7:	c7 44 24 0c 6d 2c 10 	movl   $0x102c6d,0xc(%esp)
  1005de:	00 
  1005df:	c7 44 24 08 4b 2c 10 	movl   $0x102c4b,0x8(%esp)
  1005e6:	00 
  1005e7:	c7 44 24 04 67 00 00 	movl   $0x67,0x4(%esp)
  1005ee:	00 
  1005ef:	c7 04 24 60 2c 10 00 	movl   $0x102c60,(%esp)
  1005f6:	e8 39 fd ff ff       	call   100334 <debug_panic>
  1005fb:	83 45 fc 01          	addl   $0x1,0xfffffffc(%ebp)
  1005ff:	83 7d fc 09          	cmpl   $0x9,0xfffffffc(%ebp)
  100603:	0f 8e 54 ff ff ff    	jle    10055d <debug_check+0x5a>
  100609:	83 45 f8 01          	addl   $0x1,0xfffffff8(%ebp)
  10060d:	83 7d f8 03          	cmpl   $0x3,0xfffffff8(%ebp)
  100611:	0f 8e 3a ff ff ff    	jle    100551 <debug_check+0x4e>
		}
	assert(eips[0][0] == eips[1][0]);
  100617:	8b 95 58 ff ff ff    	mov    0xffffff58(%ebp),%edx
  10061d:	8b 45 80             	mov    0xffffff80(%ebp),%eax
  100620:	39 c2                	cmp    %eax,%edx
  100622:	74 24                	je     100648 <debug_check+0x145>
  100624:	c7 44 24 0c 86 2c 10 	movl   $0x102c86,0xc(%esp)
  10062b:	00 
  10062c:	c7 44 24 08 4b 2c 10 	movl   $0x102c4b,0x8(%esp)
  100633:	00 
  100634:	c7 44 24 04 69 00 00 	movl   $0x69,0x4(%esp)
  10063b:	00 
  10063c:	c7 04 24 60 2c 10 00 	movl   $0x102c60,(%esp)
  100643:	e8 ec fc ff ff       	call   100334 <debug_panic>
	assert(eips[2][0] == eips[3][0]);
  100648:	8b 55 a8             	mov    0xffffffa8(%ebp),%edx
  10064b:	8b 45 d0             	mov    0xffffffd0(%ebp),%eax
  10064e:	39 c2                	cmp    %eax,%edx
  100650:	74 24                	je     100676 <debug_check+0x173>
  100652:	c7 44 24 0c 9f 2c 10 	movl   $0x102c9f,0xc(%esp)
  100659:	00 
  10065a:	c7 44 24 08 4b 2c 10 	movl   $0x102c4b,0x8(%esp)
  100661:	00 
  100662:	c7 44 24 04 6a 00 00 	movl   $0x6a,0x4(%esp)
  100669:	00 
  10066a:	c7 04 24 60 2c 10 00 	movl   $0x102c60,(%esp)
  100671:	e8 be fc ff ff       	call   100334 <debug_panic>
	assert(eips[1][0] != eips[2][0]);
  100676:	8b 55 80             	mov    0xffffff80(%ebp),%edx
  100679:	8b 45 a8             	mov    0xffffffa8(%ebp),%eax
  10067c:	39 c2                	cmp    %eax,%edx
  10067e:	75 24                	jne    1006a4 <debug_check+0x1a1>
  100680:	c7 44 24 0c b8 2c 10 	movl   $0x102cb8,0xc(%esp)
  100687:	00 
  100688:	c7 44 24 08 4b 2c 10 	movl   $0x102c4b,0x8(%esp)
  10068f:	00 
  100690:	c7 44 24 04 6b 00 00 	movl   $0x6b,0x4(%esp)
  100697:	00 
  100698:	c7 04 24 60 2c 10 00 	movl   $0x102c60,(%esp)
  10069f:	e8 90 fc ff ff       	call   100334 <debug_panic>
	assert(eips[0][1] == eips[2][1]);
  1006a4:	8b 95 5c ff ff ff    	mov    0xffffff5c(%ebp),%edx
  1006aa:	8b 45 ac             	mov    0xffffffac(%ebp),%eax
  1006ad:	39 c2                	cmp    %eax,%edx
  1006af:	74 24                	je     1006d5 <debug_check+0x1d2>
  1006b1:	c7 44 24 0c d1 2c 10 	movl   $0x102cd1,0xc(%esp)
  1006b8:	00 
  1006b9:	c7 44 24 08 4b 2c 10 	movl   $0x102c4b,0x8(%esp)
  1006c0:	00 
  1006c1:	c7 44 24 04 6c 00 00 	movl   $0x6c,0x4(%esp)
  1006c8:	00 
  1006c9:	c7 04 24 60 2c 10 00 	movl   $0x102c60,(%esp)
  1006d0:	e8 5f fc ff ff       	call   100334 <debug_panic>
	assert(eips[1][1] == eips[3][1]);
  1006d5:	8b 55 84             	mov    0xffffff84(%ebp),%edx
  1006d8:	8b 45 d4             	mov    0xffffffd4(%ebp),%eax
  1006db:	39 c2                	cmp    %eax,%edx
  1006dd:	74 24                	je     100703 <debug_check+0x200>
  1006df:	c7 44 24 0c ea 2c 10 	movl   $0x102cea,0xc(%esp)
  1006e6:	00 
  1006e7:	c7 44 24 08 4b 2c 10 	movl   $0x102c4b,0x8(%esp)
  1006ee:	00 
  1006ef:	c7 44 24 04 6d 00 00 	movl   $0x6d,0x4(%esp)
  1006f6:	00 
  1006f7:	c7 04 24 60 2c 10 00 	movl   $0x102c60,(%esp)
  1006fe:	e8 31 fc ff ff       	call   100334 <debug_panic>
	assert(eips[0][1] != eips[1][1]);
  100703:	8b 95 5c ff ff ff    	mov    0xffffff5c(%ebp),%edx
  100709:	8b 45 84             	mov    0xffffff84(%ebp),%eax
  10070c:	39 c2                	cmp    %eax,%edx
  10070e:	75 24                	jne    100734 <debug_check+0x231>
  100710:	c7 44 24 0c 03 2d 10 	movl   $0x102d03,0xc(%esp)
  100717:	00 
  100718:	c7 44 24 08 4b 2c 10 	movl   $0x102c4b,0x8(%esp)
  10071f:	00 
  100720:	c7 44 24 04 6e 00 00 	movl   $0x6e,0x4(%esp)
  100727:	00 
  100728:	c7 04 24 60 2c 10 00 	movl   $0x102c60,(%esp)
  10072f:	e8 00 fc ff ff       	call   100334 <debug_panic>

	cprintf("debug_check() succeeded!\n");
  100734:	c7 04 24 1c 2d 10 00 	movl   $0x102d1c,(%esp)
  10073b:	e8 b1 1c 00 00       	call   1023f1 <cprintf>
}
  100740:	c9                   	leave  
  100741:	c3                   	ret    
  100742:	90                   	nop    
  100743:	90                   	nop    

00100744 <mem_init>:
void mem_check(void);

void
mem_init(void)
{
  100744:	55                   	push   %ebp
  100745:	89 e5                	mov    %esp,%ebp
  100747:	83 ec 38             	sub    $0x38,%esp
	if (!cpu_onboot())	// only do once, on the boot CPU
  10074a:	e8 3e 01 00 00       	call   10088d <cpu_onboot>
  10074f:	85 c0                	test   %eax,%eax
  100751:	0f 84 34 01 00 00    	je     10088b <mem_init+0x147>
		return;

	// Determine how much base (<640K) and extended (>1MB) memory
	// is available in the system (in bytes),
	// by reading the PC's BIOS-managed nonvolatile RAM (NVRAM).
	// The NVRAM tells us how many kilobytes there are.
	// Since the count is 16 bits, this gives us up to 64MB of RAM;
	// additional RAM beyond that would have to be detected another way.
	size_t basemem = ROUNDDOWN(nvram_read16(NVRAM_BASELO)*1024, PAGESIZE);
  100757:	c7 04 24 15 00 00 00 	movl   $0x15,(%esp)
  10075e:	e8 4e 14 00 00       	call   101bb1 <nvram_read16>
  100763:	c1 e0 0a             	shl    $0xa,%eax
  100766:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  100769:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10076c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  100771:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
	size_t extmem = ROUNDDOWN(nvram_read16(NVRAM_EXTLO)*1024, PAGESIZE);
  100774:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
  10077b:	e8 31 14 00 00       	call   101bb1 <nvram_read16>
  100780:	c1 e0 0a             	shl    $0xa,%eax
  100783:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  100786:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  100789:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  10078e:	89 45 ec             	mov    %eax,0xffffffec(%ebp)

	warn("Assuming we have 1GB of memory!");
  100791:	c7 44 24 08 38 2d 10 	movl   $0x102d38,0x8(%esp)
  100798:	00 
  100799:	c7 44 24 04 2f 00 00 	movl   $0x2f,0x4(%esp)
  1007a0:	00 
  1007a1:	c7 04 24 58 2d 10 00 	movl   $0x102d58,(%esp)
  1007a8:	e8 45 fc ff ff       	call   1003f2 <debug_warn>
	extmem = 1024*1024*1024 - MEM_EXT;	// assume 1GB total memory
  1007ad:	c7 45 ec 00 00 f0 3f 	movl   $0x3ff00000,0xffffffec(%ebp)

	// The maximum physical address is the top of extended memory.
	mem_max = MEM_EXT + extmem;
  1007b4:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  1007b7:	05 00 00 10 00       	add    $0x100000,%eax
  1007bc:	a3 78 7f 10 00       	mov    %eax,0x107f78

	// Compute the total number of physical pages (including I/O holes)
	mem_npage = mem_max / PAGESIZE;
  1007c1:	a1 78 7f 10 00       	mov    0x107f78,%eax
  1007c6:	c1 e8 0c             	shr    $0xc,%eax
  1007c9:	a3 74 7f 10 00       	mov    %eax,0x107f74

	cprintf("Physical memory: %dK available, ", (int)(mem_max/1024));
  1007ce:	a1 78 7f 10 00       	mov    0x107f78,%eax
  1007d3:	c1 e8 0a             	shr    $0xa,%eax
  1007d6:	89 44 24 04          	mov    %eax,0x4(%esp)
  1007da:	c7 04 24 64 2d 10 00 	movl   $0x102d64,(%esp)
  1007e1:	e8 0b 1c 00 00       	call   1023f1 <cprintf>
	cprintf("base = %dK, extended = %dK\n",
  1007e6:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  1007e9:	c1 e8 0a             	shr    $0xa,%eax
  1007ec:	89 c2                	mov    %eax,%edx
  1007ee:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  1007f1:	c1 e8 0a             	shr    $0xa,%eax
  1007f4:	89 54 24 08          	mov    %edx,0x8(%esp)
  1007f8:	89 44 24 04          	mov    %eax,0x4(%esp)
  1007fc:	c7 04 24 85 2d 10 00 	movl   $0x102d85,(%esp)
  100803:	e8 e9 1b 00 00       	call   1023f1 <cprintf>
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
  100808:	c7 45 f0 70 7f 10 00 	movl   $0x107f70,0xfffffff0(%ebp)
	int i;
	for (i = 0; i < mem_npage; i++) {
  10080f:	c7 45 f4 00 00 00 00 	movl   $0x0,0xfffffff4(%ebp)
  100816:	eb 42                	jmp    10085a <mem_init+0x116>
		// A free page has no references to it.
		mem_pageinfo[i].refcount = 0;
  100818:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  10081b:	c1 e0 03             	shl    $0x3,%eax
  10081e:	89 c2                	mov    %eax,%edx
  100820:	a1 7c 7f 10 00       	mov    0x107f7c,%eax
  100825:	8d 04 02             	lea    (%edx,%eax,1),%eax
  100828:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)

		// Add the page to the end of the free list.
		*freetail = &mem_pageinfo[i];
  10082f:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  100832:	c1 e0 03             	shl    $0x3,%eax
  100835:	89 c2                	mov    %eax,%edx
  100837:	a1 7c 7f 10 00       	mov    0x107f7c,%eax
  10083c:	01 c2                	add    %eax,%edx
  10083e:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  100841:	89 10                	mov    %edx,(%eax)
		freetail = &mem_pageinfo[i].free_next;
  100843:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  100846:	c1 e0 03             	shl    $0x3,%eax
  100849:	89 c2                	mov    %eax,%edx
  10084b:	a1 7c 7f 10 00       	mov    0x107f7c,%eax
  100850:	8d 04 02             	lea    (%edx,%eax,1),%eax
  100853:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
  100856:	83 45 f4 01          	addl   $0x1,0xfffffff4(%ebp)
  10085a:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  10085d:	a1 74 7f 10 00       	mov    0x107f74,%eax
  100862:	39 c2                	cmp    %eax,%edx
  100864:	72 b2                	jb     100818 <mem_init+0xd4>
	}
	*freetail = NULL;	// null-terminate the freelist
  100866:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  100869:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

	// ...and remove this when you're ready.
	panic("mem_init() not implemented");
  10086f:	c7 44 24 08 a1 2d 10 	movl   $0x102da1,0x8(%esp)
  100876:	00 
  100877:	c7 44 24 04 5f 00 00 	movl   $0x5f,0x4(%esp)
  10087e:	00 
  10087f:	c7 04 24 58 2d 10 00 	movl   $0x102d58,(%esp)
  100886:	e8 a9 fa ff ff       	call   100334 <debug_panic>

	// Check to make sure the page allocator seems to work correctly.
	mem_check();
}
  10088b:	c9                   	leave  
  10088c:	c3                   	ret    

0010088d <cpu_onboot>:
}

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  10088d:	55                   	push   %ebp
  10088e:	89 e5                	mov    %esp,%ebp
  100890:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  100893:	e8 0d 00 00 00       	call   1008a5 <cpu_cur>
  100898:	3d 00 50 10 00       	cmp    $0x105000,%eax
  10089d:	0f 94 c0             	sete   %al
  1008a0:	0f b6 c0             	movzbl %al,%eax
}
  1008a3:	c9                   	leave  
  1008a4:	c3                   	ret    

001008a5 <cpu_cur>:
  1008a5:	55                   	push   %ebp
  1008a6:	89 e5                	mov    %esp,%ebp
  1008a8:	83 ec 28             	sub    $0x28,%esp
static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  1008ab:	89 65 fc             	mov    %esp,0xfffffffc(%ebp)
        return esp;
  1008ae:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  1008b1:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  1008b4:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1008b7:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1008bc:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	assert(c->magic == CPU_MAGIC);
  1008bf:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  1008c2:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
  1008c8:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  1008cd:	74 24                	je     1008f3 <cpu_cur+0x4e>
  1008cf:	c7 44 24 0c bc 2d 10 	movl   $0x102dbc,0xc(%esp)
  1008d6:	00 
  1008d7:	c7 44 24 08 d2 2d 10 	movl   $0x102dd2,0x8(%esp)
  1008de:	00 
  1008df:	c7 44 24 04 50 00 00 	movl   $0x50,0x4(%esp)
  1008e6:	00 
  1008e7:	c7 04 24 e7 2d 10 00 	movl   $0x102de7,(%esp)
  1008ee:	e8 41 fa ff ff       	call   100334 <debug_panic>
	return c;
  1008f3:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
}
  1008f6:	c9                   	leave  
  1008f7:	c3                   	ret    

001008f8 <mem_alloc>:

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
  1008f8:	55                   	push   %ebp
  1008f9:	89 e5                	mov    %esp,%ebp
  1008fb:	83 ec 18             	sub    $0x18,%esp
	// Fill this function in
	// Fill this function in.
	panic("mem_alloc not implemented.");
  1008fe:	c7 44 24 08 f4 2d 10 	movl   $0x102df4,0x8(%esp)
  100905:	00 
  100906:	c7 44 24 04 75 00 00 	movl   $0x75,0x4(%esp)
  10090d:	00 
  10090e:	c7 04 24 58 2d 10 00 	movl   $0x102d58,(%esp)
  100915:	e8 1a fa ff ff       	call   100334 <debug_panic>

0010091a <mem_free>:
}

//
// Return a page to the free list, given its pageinfo pointer.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
mem_free(pageinfo *pi)
{
  10091a:	55                   	push   %ebp
  10091b:	89 e5                	mov    %esp,%ebp
  10091d:	83 ec 18             	sub    $0x18,%esp
	// Fill this function in.
	panic("mem_free not implemented.");
  100920:	c7 44 24 08 0f 2e 10 	movl   $0x102e0f,0x8(%esp)
  100927:	00 
  100928:	c7 44 24 04 80 00 00 	movl   $0x80,0x4(%esp)
  10092f:	00 
  100930:	c7 04 24 58 2d 10 00 	movl   $0x102d58,(%esp)
  100937:	e8 f8 f9 ff ff       	call   100334 <debug_panic>

0010093c <mem_check>:
}

//
// Check the physical page allocator (mem_alloc(), mem_free())
// for correct operation after initialization via mem_init().
//
void
mem_check()
{
  10093c:	55                   	push   %ebp
  10093d:	89 e5                	mov    %esp,%ebp
  10093f:	83 ec 38             	sub    $0x38,%esp
	pageinfo *pp, *pp0, *pp1, *pp2;
	pageinfo *fl;
	int i;

        // if there's a page that shouldn't be on
        // the free list, try to make sure it
        // eventually causes trouble.
	int freepages = 0;
  100942:	c7 45 fc 00 00 00 00 	movl   $0x0,0xfffffffc(%ebp)
	for (pp = mem_freelist; pp != 0; pp = pp->free_next) {
  100949:	a1 70 7f 10 00       	mov    0x107f70,%eax
  10094e:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
  100951:	eb 35                	jmp    100988 <mem_check+0x4c>
		memset(mem_pi2ptr(pp), 0x97, 128);
  100953:	8b 55 e4             	mov    0xffffffe4(%ebp),%edx
  100956:	a1 7c 7f 10 00       	mov    0x107f7c,%eax
  10095b:	89 d1                	mov    %edx,%ecx
  10095d:	29 c1                	sub    %eax,%ecx
  10095f:	89 c8                	mov    %ecx,%eax
  100961:	c1 e0 09             	shl    $0x9,%eax
  100964:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
  10096b:	00 
  10096c:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
  100973:	00 
  100974:	89 04 24             	mov    %eax,(%esp)
  100977:	e8 6d 1c 00 00       	call   1025e9 <memset>
		freepages++;
  10097c:	83 45 fc 01          	addl   $0x1,0xfffffffc(%ebp)
  100980:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  100983:	8b 00                	mov    (%eax),%eax
  100985:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
  100988:	83 7d e4 00          	cmpl   $0x0,0xffffffe4(%ebp)
  10098c:	75 c5                	jne    100953 <mem_check+0x17>
	}
	cprintf("mem_check: %d free pages\n", freepages);
  10098e:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  100991:	89 44 24 04          	mov    %eax,0x4(%esp)
  100995:	c7 04 24 29 2e 10 00 	movl   $0x102e29,(%esp)
  10099c:	e8 50 1a 00 00       	call   1023f1 <cprintf>
	assert(freepages < mem_npage);	// can't have more free than total!
  1009a1:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  1009a4:	a1 74 7f 10 00       	mov    0x107f74,%eax
  1009a9:	39 c2                	cmp    %eax,%edx
  1009ab:	72 24                	jb     1009d1 <mem_check+0x95>
  1009ad:	c7 44 24 0c 43 2e 10 	movl   $0x102e43,0xc(%esp)
  1009b4:	00 
  1009b5:	c7 44 24 08 d2 2d 10 	movl   $0x102dd2,0x8(%esp)
  1009bc:	00 
  1009bd:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
  1009c4:	00 
  1009c5:	c7 04 24 58 2d 10 00 	movl   $0x102d58,(%esp)
  1009cc:	e8 63 f9 ff ff       	call   100334 <debug_panic>
	assert(freepages > 16000);	// make sure it's in the right ballpark
  1009d1:	81 7d fc 80 3e 00 00 	cmpl   $0x3e80,0xfffffffc(%ebp)
  1009d8:	7f 24                	jg     1009fe <mem_check+0xc2>
  1009da:	c7 44 24 0c 59 2e 10 	movl   $0x102e59,0xc(%esp)
  1009e1:	00 
  1009e2:	c7 44 24 08 d2 2d 10 	movl   $0x102dd2,0x8(%esp)
  1009e9:	00 
  1009ea:	c7 44 24 04 98 00 00 	movl   $0x98,0x4(%esp)
  1009f1:	00 
  1009f2:	c7 04 24 58 2d 10 00 	movl   $0x102d58,(%esp)
  1009f9:	e8 36 f9 ff ff       	call   100334 <debug_panic>

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
  1009fe:	c7 45 f0 00 00 00 00 	movl   $0x0,0xfffffff0(%ebp)
  100a05:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  100a08:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  100a0b:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  100a0e:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
	pp0 = mem_alloc(); assert(pp0 != 0);
  100a11:	e8 e2 fe ff ff       	call   1008f8 <mem_alloc>
  100a16:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  100a19:	83 7d e8 00          	cmpl   $0x0,0xffffffe8(%ebp)
  100a1d:	75 24                	jne    100a43 <mem_check+0x107>
  100a1f:	c7 44 24 0c 6b 2e 10 	movl   $0x102e6b,0xc(%esp)
  100a26:	00 
  100a27:	c7 44 24 08 d2 2d 10 	movl   $0x102dd2,0x8(%esp)
  100a2e:	00 
  100a2f:	c7 44 24 04 9c 00 00 	movl   $0x9c,0x4(%esp)
  100a36:	00 
  100a37:	c7 04 24 58 2d 10 00 	movl   $0x102d58,(%esp)
  100a3e:	e8 f1 f8 ff ff       	call   100334 <debug_panic>
	pp1 = mem_alloc(); assert(pp1 != 0);
  100a43:	e8 b0 fe ff ff       	call   1008f8 <mem_alloc>
  100a48:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  100a4b:	83 7d ec 00          	cmpl   $0x0,0xffffffec(%ebp)
  100a4f:	75 24                	jne    100a75 <mem_check+0x139>
  100a51:	c7 44 24 0c 74 2e 10 	movl   $0x102e74,0xc(%esp)
  100a58:	00 
  100a59:	c7 44 24 08 d2 2d 10 	movl   $0x102dd2,0x8(%esp)
  100a60:	00 
  100a61:	c7 44 24 04 9d 00 00 	movl   $0x9d,0x4(%esp)
  100a68:	00 
  100a69:	c7 04 24 58 2d 10 00 	movl   $0x102d58,(%esp)
  100a70:	e8 bf f8 ff ff       	call   100334 <debug_panic>
	pp2 = mem_alloc(); assert(pp2 != 0);
  100a75:	e8 7e fe ff ff       	call   1008f8 <mem_alloc>
  100a7a:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
  100a7d:	83 7d f0 00          	cmpl   $0x0,0xfffffff0(%ebp)
  100a81:	75 24                	jne    100aa7 <mem_check+0x16b>
  100a83:	c7 44 24 0c 7d 2e 10 	movl   $0x102e7d,0xc(%esp)
  100a8a:	00 
  100a8b:	c7 44 24 08 d2 2d 10 	movl   $0x102dd2,0x8(%esp)
  100a92:	00 
  100a93:	c7 44 24 04 9e 00 00 	movl   $0x9e,0x4(%esp)
  100a9a:	00 
  100a9b:	c7 04 24 58 2d 10 00 	movl   $0x102d58,(%esp)
  100aa2:	e8 8d f8 ff ff       	call   100334 <debug_panic>

	assert(pp0);
  100aa7:	83 7d e8 00          	cmpl   $0x0,0xffffffe8(%ebp)
  100aab:	75 24                	jne    100ad1 <mem_check+0x195>
  100aad:	c7 44 24 0c 86 2e 10 	movl   $0x102e86,0xc(%esp)
  100ab4:	00 
  100ab5:	c7 44 24 08 d2 2d 10 	movl   $0x102dd2,0x8(%esp)
  100abc:	00 
  100abd:	c7 44 24 04 a0 00 00 	movl   $0xa0,0x4(%esp)
  100ac4:	00 
  100ac5:	c7 04 24 58 2d 10 00 	movl   $0x102d58,(%esp)
  100acc:	e8 63 f8 ff ff       	call   100334 <debug_panic>
	assert(pp1 && pp1 != pp0);
  100ad1:	83 7d ec 00          	cmpl   $0x0,0xffffffec(%ebp)
  100ad5:	74 08                	je     100adf <mem_check+0x1a3>
  100ad7:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  100ada:	3b 45 e8             	cmp    0xffffffe8(%ebp),%eax
  100add:	75 24                	jne    100b03 <mem_check+0x1c7>
  100adf:	c7 44 24 0c 8a 2e 10 	movl   $0x102e8a,0xc(%esp)
  100ae6:	00 
  100ae7:	c7 44 24 08 d2 2d 10 	movl   $0x102dd2,0x8(%esp)
  100aee:	00 
  100aef:	c7 44 24 04 a1 00 00 	movl   $0xa1,0x4(%esp)
  100af6:	00 
  100af7:	c7 04 24 58 2d 10 00 	movl   $0x102d58,(%esp)
  100afe:	e8 31 f8 ff ff       	call   100334 <debug_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
  100b03:	83 7d f0 00          	cmpl   $0x0,0xfffffff0(%ebp)
  100b07:	74 10                	je     100b19 <mem_check+0x1dd>
  100b09:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  100b0c:	3b 45 ec             	cmp    0xffffffec(%ebp),%eax
  100b0f:	74 08                	je     100b19 <mem_check+0x1dd>
  100b11:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  100b14:	3b 45 e8             	cmp    0xffffffe8(%ebp),%eax
  100b17:	75 24                	jne    100b3d <mem_check+0x201>
  100b19:	c7 44 24 0c 9c 2e 10 	movl   $0x102e9c,0xc(%esp)
  100b20:	00 
  100b21:	c7 44 24 08 d2 2d 10 	movl   $0x102dd2,0x8(%esp)
  100b28:	00 
  100b29:	c7 44 24 04 a2 00 00 	movl   $0xa2,0x4(%esp)
  100b30:	00 
  100b31:	c7 04 24 58 2d 10 00 	movl   $0x102d58,(%esp)
  100b38:	e8 f7 f7 ff ff       	call   100334 <debug_panic>
        assert(mem_pi2phys(pp0) < mem_npage*PAGESIZE);
  100b3d:	8b 55 e8             	mov    0xffffffe8(%ebp),%edx
  100b40:	a1 7c 7f 10 00       	mov    0x107f7c,%eax
  100b45:	89 d1                	mov    %edx,%ecx
  100b47:	29 c1                	sub    %eax,%ecx
  100b49:	89 c8                	mov    %ecx,%eax
  100b4b:	c1 e0 09             	shl    $0x9,%eax
  100b4e:	89 c2                	mov    %eax,%edx
  100b50:	a1 74 7f 10 00       	mov    0x107f74,%eax
  100b55:	c1 e0 0c             	shl    $0xc,%eax
  100b58:	39 c2                	cmp    %eax,%edx
  100b5a:	72 24                	jb     100b80 <mem_check+0x244>
  100b5c:	c7 44 24 0c bc 2e 10 	movl   $0x102ebc,0xc(%esp)
  100b63:	00 
  100b64:	c7 44 24 08 d2 2d 10 	movl   $0x102dd2,0x8(%esp)
  100b6b:	00 
  100b6c:	c7 44 24 04 a3 00 00 	movl   $0xa3,0x4(%esp)
  100b73:	00 
  100b74:	c7 04 24 58 2d 10 00 	movl   $0x102d58,(%esp)
  100b7b:	e8 b4 f7 ff ff       	call   100334 <debug_panic>
        assert(mem_pi2phys(pp1) < mem_npage*PAGESIZE);
  100b80:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
  100b83:	a1 7c 7f 10 00       	mov    0x107f7c,%eax
  100b88:	89 d1                	mov    %edx,%ecx
  100b8a:	29 c1                	sub    %eax,%ecx
  100b8c:	89 c8                	mov    %ecx,%eax
  100b8e:	c1 e0 09             	shl    $0x9,%eax
  100b91:	89 c2                	mov    %eax,%edx
  100b93:	a1 74 7f 10 00       	mov    0x107f74,%eax
  100b98:	c1 e0 0c             	shl    $0xc,%eax
  100b9b:	39 c2                	cmp    %eax,%edx
  100b9d:	72 24                	jb     100bc3 <mem_check+0x287>
  100b9f:	c7 44 24 0c e4 2e 10 	movl   $0x102ee4,0xc(%esp)
  100ba6:	00 
  100ba7:	c7 44 24 08 d2 2d 10 	movl   $0x102dd2,0x8(%esp)
  100bae:	00 
  100baf:	c7 44 24 04 a4 00 00 	movl   $0xa4,0x4(%esp)
  100bb6:	00 
  100bb7:	c7 04 24 58 2d 10 00 	movl   $0x102d58,(%esp)
  100bbe:	e8 71 f7 ff ff       	call   100334 <debug_panic>
        assert(mem_pi2phys(pp2) < mem_npage*PAGESIZE);
  100bc3:	8b 55 f0             	mov    0xfffffff0(%ebp),%edx
  100bc6:	a1 7c 7f 10 00       	mov    0x107f7c,%eax
  100bcb:	89 d1                	mov    %edx,%ecx
  100bcd:	29 c1                	sub    %eax,%ecx
  100bcf:	89 c8                	mov    %ecx,%eax
  100bd1:	c1 e0 09             	shl    $0x9,%eax
  100bd4:	89 c2                	mov    %eax,%edx
  100bd6:	a1 74 7f 10 00       	mov    0x107f74,%eax
  100bdb:	c1 e0 0c             	shl    $0xc,%eax
  100bde:	39 c2                	cmp    %eax,%edx
  100be0:	72 24                	jb     100c06 <mem_check+0x2ca>
  100be2:	c7 44 24 0c 0c 2f 10 	movl   $0x102f0c,0xc(%esp)
  100be9:	00 
  100bea:	c7 44 24 08 d2 2d 10 	movl   $0x102dd2,0x8(%esp)
  100bf1:	00 
  100bf2:	c7 44 24 04 a5 00 00 	movl   $0xa5,0x4(%esp)
  100bf9:	00 
  100bfa:	c7 04 24 58 2d 10 00 	movl   $0x102d58,(%esp)
  100c01:	e8 2e f7 ff ff       	call   100334 <debug_panic>

	// temporarily steal the rest of the free pages
	fl = mem_freelist;
  100c06:	a1 70 7f 10 00       	mov    0x107f70,%eax
  100c0b:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	mem_freelist = 0;
  100c0e:	c7 05 70 7f 10 00 00 	movl   $0x0,0x107f70
  100c15:	00 00 00 

	// should be no free memory
	assert(mem_alloc() == 0);
  100c18:	e8 db fc ff ff       	call   1008f8 <mem_alloc>
  100c1d:	85 c0                	test   %eax,%eax
  100c1f:	74 24                	je     100c45 <mem_check+0x309>
  100c21:	c7 44 24 0c 32 2f 10 	movl   $0x102f32,0xc(%esp)
  100c28:	00 
  100c29:	c7 44 24 08 d2 2d 10 	movl   $0x102dd2,0x8(%esp)
  100c30:	00 
  100c31:	c7 44 24 04 ac 00 00 	movl   $0xac,0x4(%esp)
  100c38:	00 
  100c39:	c7 04 24 58 2d 10 00 	movl   $0x102d58,(%esp)
  100c40:	e8 ef f6 ff ff       	call   100334 <debug_panic>

        // free and re-allocate?
        mem_free(pp0);
  100c45:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  100c48:	89 04 24             	mov    %eax,(%esp)
  100c4b:	e8 ca fc ff ff       	call   10091a <mem_free>
        mem_free(pp1);
  100c50:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  100c53:	89 04 24             	mov    %eax,(%esp)
  100c56:	e8 bf fc ff ff       	call   10091a <mem_free>
        mem_free(pp2);
  100c5b:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  100c5e:	89 04 24             	mov    %eax,(%esp)
  100c61:	e8 b4 fc ff ff       	call   10091a <mem_free>
	pp0 = pp1 = pp2 = 0;
  100c66:	c7 45 f0 00 00 00 00 	movl   $0x0,0xfffffff0(%ebp)
  100c6d:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  100c70:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  100c73:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  100c76:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
	pp0 = mem_alloc(); assert(pp0 != 0);
  100c79:	e8 7a fc ff ff       	call   1008f8 <mem_alloc>
  100c7e:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  100c81:	83 7d e8 00          	cmpl   $0x0,0xffffffe8(%ebp)
  100c85:	75 24                	jne    100cab <mem_check+0x36f>
  100c87:	c7 44 24 0c 6b 2e 10 	movl   $0x102e6b,0xc(%esp)
  100c8e:	00 
  100c8f:	c7 44 24 08 d2 2d 10 	movl   $0x102dd2,0x8(%esp)
  100c96:	00 
  100c97:	c7 44 24 04 b3 00 00 	movl   $0xb3,0x4(%esp)
  100c9e:	00 
  100c9f:	c7 04 24 58 2d 10 00 	movl   $0x102d58,(%esp)
  100ca6:	e8 89 f6 ff ff       	call   100334 <debug_panic>
	pp1 = mem_alloc(); assert(pp1 != 0);
  100cab:	e8 48 fc ff ff       	call   1008f8 <mem_alloc>
  100cb0:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  100cb3:	83 7d ec 00          	cmpl   $0x0,0xffffffec(%ebp)
  100cb7:	75 24                	jne    100cdd <mem_check+0x3a1>
  100cb9:	c7 44 24 0c 74 2e 10 	movl   $0x102e74,0xc(%esp)
  100cc0:	00 
  100cc1:	c7 44 24 08 d2 2d 10 	movl   $0x102dd2,0x8(%esp)
  100cc8:	00 
  100cc9:	c7 44 24 04 b4 00 00 	movl   $0xb4,0x4(%esp)
  100cd0:	00 
  100cd1:	c7 04 24 58 2d 10 00 	movl   $0x102d58,(%esp)
  100cd8:	e8 57 f6 ff ff       	call   100334 <debug_panic>
	pp2 = mem_alloc(); assert(pp2 != 0);
  100cdd:	e8 16 fc ff ff       	call   1008f8 <mem_alloc>
  100ce2:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
  100ce5:	83 7d f0 00          	cmpl   $0x0,0xfffffff0(%ebp)
  100ce9:	75 24                	jne    100d0f <mem_check+0x3d3>
  100ceb:	c7 44 24 0c 7d 2e 10 	movl   $0x102e7d,0xc(%esp)
  100cf2:	00 
  100cf3:	c7 44 24 08 d2 2d 10 	movl   $0x102dd2,0x8(%esp)
  100cfa:	00 
  100cfb:	c7 44 24 04 b5 00 00 	movl   $0xb5,0x4(%esp)
  100d02:	00 
  100d03:	c7 04 24 58 2d 10 00 	movl   $0x102d58,(%esp)
  100d0a:	e8 25 f6 ff ff       	call   100334 <debug_panic>
	assert(pp0);
  100d0f:	83 7d e8 00          	cmpl   $0x0,0xffffffe8(%ebp)
  100d13:	75 24                	jne    100d39 <mem_check+0x3fd>
  100d15:	c7 44 24 0c 86 2e 10 	movl   $0x102e86,0xc(%esp)
  100d1c:	00 
  100d1d:	c7 44 24 08 d2 2d 10 	movl   $0x102dd2,0x8(%esp)
  100d24:	00 
  100d25:	c7 44 24 04 b6 00 00 	movl   $0xb6,0x4(%esp)
  100d2c:	00 
  100d2d:	c7 04 24 58 2d 10 00 	movl   $0x102d58,(%esp)
  100d34:	e8 fb f5 ff ff       	call   100334 <debug_panic>
	assert(pp1 && pp1 != pp0);
  100d39:	83 7d ec 00          	cmpl   $0x0,0xffffffec(%ebp)
  100d3d:	74 08                	je     100d47 <mem_check+0x40b>
  100d3f:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  100d42:	3b 45 e8             	cmp    0xffffffe8(%ebp),%eax
  100d45:	75 24                	jne    100d6b <mem_check+0x42f>
  100d47:	c7 44 24 0c 8a 2e 10 	movl   $0x102e8a,0xc(%esp)
  100d4e:	00 
  100d4f:	c7 44 24 08 d2 2d 10 	movl   $0x102dd2,0x8(%esp)
  100d56:	00 
  100d57:	c7 44 24 04 b7 00 00 	movl   $0xb7,0x4(%esp)
  100d5e:	00 
  100d5f:	c7 04 24 58 2d 10 00 	movl   $0x102d58,(%esp)
  100d66:	e8 c9 f5 ff ff       	call   100334 <debug_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
  100d6b:	83 7d f0 00          	cmpl   $0x0,0xfffffff0(%ebp)
  100d6f:	74 10                	je     100d81 <mem_check+0x445>
  100d71:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  100d74:	3b 45 ec             	cmp    0xffffffec(%ebp),%eax
  100d77:	74 08                	je     100d81 <mem_check+0x445>
  100d79:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  100d7c:	3b 45 e8             	cmp    0xffffffe8(%ebp),%eax
  100d7f:	75 24                	jne    100da5 <mem_check+0x469>
  100d81:	c7 44 24 0c 9c 2e 10 	movl   $0x102e9c,0xc(%esp)
  100d88:	00 
  100d89:	c7 44 24 08 d2 2d 10 	movl   $0x102dd2,0x8(%esp)
  100d90:	00 
  100d91:	c7 44 24 04 b8 00 00 	movl   $0xb8,0x4(%esp)
  100d98:	00 
  100d99:	c7 04 24 58 2d 10 00 	movl   $0x102d58,(%esp)
  100da0:	e8 8f f5 ff ff       	call   100334 <debug_panic>
	assert(mem_alloc() == 0);
  100da5:	e8 4e fb ff ff       	call   1008f8 <mem_alloc>
  100daa:	85 c0                	test   %eax,%eax
  100dac:	74 24                	je     100dd2 <mem_check+0x496>
  100dae:	c7 44 24 0c 32 2f 10 	movl   $0x102f32,0xc(%esp)
  100db5:	00 
  100db6:	c7 44 24 08 d2 2d 10 	movl   $0x102dd2,0x8(%esp)
  100dbd:	00 
  100dbe:	c7 44 24 04 b9 00 00 	movl   $0xb9,0x4(%esp)
  100dc5:	00 
  100dc6:	c7 04 24 58 2d 10 00 	movl   $0x102d58,(%esp)
  100dcd:	e8 62 f5 ff ff       	call   100334 <debug_panic>

	// give free list back
	mem_freelist = fl;
  100dd2:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  100dd5:	a3 70 7f 10 00       	mov    %eax,0x107f70

	// free the pages we took
	mem_free(pp0);
  100dda:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  100ddd:	89 04 24             	mov    %eax,(%esp)
  100de0:	e8 35 fb ff ff       	call   10091a <mem_free>
	mem_free(pp1);
  100de5:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  100de8:	89 04 24             	mov    %eax,(%esp)
  100deb:	e8 2a fb ff ff       	call   10091a <mem_free>
	mem_free(pp2);
  100df0:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  100df3:	89 04 24             	mov    %eax,(%esp)
  100df6:	e8 1f fb ff ff       	call   10091a <mem_free>

	cprintf("mem_check() succeeded!\n");
  100dfb:	c7 04 24 43 2f 10 00 	movl   $0x102f43,(%esp)
  100e02:	e8 ea 15 00 00       	call   1023f1 <cprintf>
}
  100e07:	c9                   	leave  
  100e08:	c3                   	ret    
  100e09:	90                   	nop    
  100e0a:	90                   	nop    
  100e0b:	90                   	nop    

00100e0c <cpu_init>:
};


void cpu_init()
{
  100e0c:	55                   	push   %ebp
  100e0d:	89 e5                	mov    %esp,%ebp
  100e0f:	83 ec 18             	sub    $0x18,%esp
	cpu *c = cpu_cur();
  100e12:	e8 47 00 00 00       	call   100e5e <cpu_cur>
  100e17:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)

	// Load the GDT
	struct pseudodesc gdt_pd = {
		sizeof(c->gdt) - 1, (uint32_t) c->gdt };
  100e1a:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  100e1d:	66 c7 45 f6 37 00    	movw   $0x37,0xfffffff6(%ebp)
  100e23:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
	asm volatile("lgdt %0" : : "m" (gdt_pd));
  100e26:	0f 01 55 f6          	lgdtl  0xfffffff6(%ebp)

	// Reload all segment registers.
	asm volatile("movw %%ax,%%gs" :: "a" (CPU_GDT_UDATA|3));
  100e2a:	b8 23 00 00 00       	mov    $0x23,%eax
  100e2f:	8e e8                	movl   %eax,%gs
	asm volatile("movw %%ax,%%fs" :: "a" (CPU_GDT_UDATA|3));
  100e31:	b8 23 00 00 00       	mov    $0x23,%eax
  100e36:	8e e0                	movl   %eax,%fs
	asm volatile("movw %%ax,%%es" :: "a" (CPU_GDT_KDATA));
  100e38:	b8 10 00 00 00       	mov    $0x10,%eax
  100e3d:	8e c0                	movl   %eax,%es
	asm volatile("movw %%ax,%%ds" :: "a" (CPU_GDT_KDATA));
  100e3f:	b8 10 00 00 00       	mov    $0x10,%eax
  100e44:	8e d8                	movl   %eax,%ds
	asm volatile("movw %%ax,%%ss" :: "a" (CPU_GDT_KDATA));
  100e46:	b8 10 00 00 00       	mov    $0x10,%eax
  100e4b:	8e d0                	movl   %eax,%ss
	asm volatile("ljmp %0,$1f\n 1:\n" :: "i" (CPU_GDT_KCODE)); // reload CS
  100e4d:	ea 54 0e 10 00 08 00 	ljmp   $0x8,$0x100e54

	// We don't need an LDT.
	asm volatile("lldt %%ax" :: "a" (0));
  100e54:	b8 00 00 00 00       	mov    $0x0,%eax
  100e59:	0f 00 d0             	lldt   %ax
}
  100e5c:	c9                   	leave  
  100e5d:	c3                   	ret    

00100e5e <cpu_cur>:

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  100e5e:	55                   	push   %ebp
  100e5f:	89 e5                	mov    %esp,%ebp
  100e61:	83 ec 28             	sub    $0x28,%esp
static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  100e64:	89 65 fc             	mov    %esp,0xfffffffc(%ebp)
        return esp;
  100e67:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  100e6a:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  100e6d:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  100e70:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  100e75:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	assert(c->magic == CPU_MAGIC);
  100e78:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  100e7b:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
  100e81:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  100e86:	74 24                	je     100eac <cpu_cur+0x4e>
  100e88:	c7 44 24 0c 5b 2f 10 	movl   $0x102f5b,0xc(%esp)
  100e8f:	00 
  100e90:	c7 44 24 08 71 2f 10 	movl   $0x102f71,0x8(%esp)
  100e97:	00 
  100e98:	c7 44 24 04 50 00 00 	movl   $0x50,0x4(%esp)
  100e9f:	00 
  100ea0:	c7 04 24 86 2f 10 00 	movl   $0x102f86,(%esp)
  100ea7:	e8 88 f4 ff ff       	call   100334 <debug_panic>
	return c;
  100eac:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
}
  100eaf:	c9                   	leave  
  100eb0:	c3                   	ret    
  100eb1:	90                   	nop    
  100eb2:	90                   	nop    
  100eb3:	90                   	nop    

00100eb4 <trap_init_idt>:


static void
trap_init_idt(void)
{
  100eb4:	55                   	push   %ebp
  100eb5:	89 e5                	mov    %esp,%ebp
  100eb7:	83 ec 18             	sub    $0x18,%esp
	extern segdesc gdt[];
	
	panic("trap_init() not implemented.");
  100eba:	c7 44 24 08 a0 2f 10 	movl   $0x102fa0,0x8(%esp)
  100ec1:	00 
  100ec2:	c7 44 24 04 25 00 00 	movl   $0x25,0x4(%esp)
  100ec9:	00 
  100eca:	c7 04 24 bd 2f 10 00 	movl   $0x102fbd,(%esp)
  100ed1:	e8 5e f4 ff ff       	call   100334 <debug_panic>

00100ed6 <trap_init>:
}

void
trap_init(void)
{
  100ed6:	55                   	push   %ebp
  100ed7:	89 e5                	mov    %esp,%ebp
  100ed9:	83 ec 08             	sub    $0x8,%esp
	// The first time we get called on the bootstrap processor,
	// initialize the IDT.  Other CPUs will share the same IDT.
	if (cpu_onboot())
  100edc:	e8 20 00 00 00       	call   100f01 <cpu_onboot>
  100ee1:	85 c0                	test   %eax,%eax
  100ee3:	74 05                	je     100eea <trap_init+0x14>
		trap_init_idt();
  100ee5:	e8 ca ff ff ff       	call   100eb4 <trap_init_idt>

	// Load the IDT into this processor's IDT register.
	asm volatile("lidt %0" : : "m" (idt_pd));
  100eea:	0f 01 1d 00 60 10 00 	lidtl  0x106000

	// Check for the correct IDT and trap handler operation.
	if (cpu_onboot())
  100ef1:	e8 0b 00 00 00       	call   100f01 <cpu_onboot>
  100ef6:	85 c0                	test   %eax,%eax
  100ef8:	74 05                	je     100eff <trap_init+0x29>
		trap_check_kernel();
  100efa:	e8 da 02 00 00       	call   1011d9 <trap_check_kernel>
}
  100eff:	c9                   	leave  
  100f00:	c3                   	ret    

00100f01 <cpu_onboot>:
}

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  100f01:	55                   	push   %ebp
  100f02:	89 e5                	mov    %esp,%ebp
  100f04:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  100f07:	e8 0d 00 00 00       	call   100f19 <cpu_cur>
  100f0c:	3d 00 50 10 00       	cmp    $0x105000,%eax
  100f11:	0f 94 c0             	sete   %al
  100f14:	0f b6 c0             	movzbl %al,%eax
}
  100f17:	c9                   	leave  
  100f18:	c3                   	ret    

00100f19 <cpu_cur>:
  100f19:	55                   	push   %ebp
  100f1a:	89 e5                	mov    %esp,%ebp
  100f1c:	83 ec 28             	sub    $0x28,%esp
static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  100f1f:	89 65 fc             	mov    %esp,0xfffffffc(%ebp)
        return esp;
  100f22:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  100f25:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  100f28:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  100f2b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  100f30:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	assert(c->magic == CPU_MAGIC);
  100f33:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  100f36:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
  100f3c:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  100f41:	74 24                	je     100f67 <cpu_cur+0x4e>
  100f43:	c7 44 24 0c c9 2f 10 	movl   $0x102fc9,0xc(%esp)
  100f4a:	00 
  100f4b:	c7 44 24 08 df 2f 10 	movl   $0x102fdf,0x8(%esp)
  100f52:	00 
  100f53:	c7 44 24 04 50 00 00 	movl   $0x50,0x4(%esp)
  100f5a:	00 
  100f5b:	c7 04 24 f4 2f 10 00 	movl   $0x102ff4,(%esp)
  100f62:	e8 cd f3 ff ff       	call   100334 <debug_panic>
	return c;
  100f67:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
}
  100f6a:	c9                   	leave  
  100f6b:	c3                   	ret    

00100f6c <trap_name>:

const char *trap_name(int trapno)
{
  100f6c:	55                   	push   %ebp
  100f6d:	89 e5                	mov    %esp,%ebp
  100f6f:	83 ec 04             	sub    $0x4,%esp
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
  100f72:	8b 45 08             	mov    0x8(%ebp),%eax
  100f75:	83 f8 13             	cmp    $0x13,%eax
  100f78:	77 0f                	ja     100f89 <trap_name+0x1d>
		return excnames[trapno];
  100f7a:	8b 45 08             	mov    0x8(%ebp),%eax
  100f7d:	8b 04 85 60 31 10 00 	mov    0x103160(,%eax,4),%eax
  100f84:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  100f87:	eb 07                	jmp    100f90 <trap_name+0x24>
	return "(unknown trap)";
  100f89:	c7 45 fc eb 30 10 00 	movl   $0x1030eb,0xfffffffc(%ebp)
  100f90:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
}
  100f93:	c9                   	leave  
  100f94:	c3                   	ret    

00100f95 <trap_print_regs>:

void
trap_print_regs(pushregs *regs)
{
  100f95:	55                   	push   %ebp
  100f96:	89 e5                	mov    %esp,%ebp
  100f98:	83 ec 08             	sub    $0x8,%esp
	cprintf("  edi  0x%08x\n", regs->edi);
  100f9b:	8b 45 08             	mov    0x8(%ebp),%eax
  100f9e:	8b 00                	mov    (%eax),%eax
  100fa0:	89 44 24 04          	mov    %eax,0x4(%esp)
  100fa4:	c7 04 24 b0 31 10 00 	movl   $0x1031b0,(%esp)
  100fab:	e8 41 14 00 00       	call   1023f1 <cprintf>
	cprintf("  esi  0x%08x\n", regs->esi);
  100fb0:	8b 45 08             	mov    0x8(%ebp),%eax
  100fb3:	8b 40 04             	mov    0x4(%eax),%eax
  100fb6:	89 44 24 04          	mov    %eax,0x4(%esp)
  100fba:	c7 04 24 bf 31 10 00 	movl   $0x1031bf,(%esp)
  100fc1:	e8 2b 14 00 00       	call   1023f1 <cprintf>
	cprintf("  ebp  0x%08x\n", regs->ebp);
  100fc6:	8b 45 08             	mov    0x8(%ebp),%eax
  100fc9:	8b 40 08             	mov    0x8(%eax),%eax
  100fcc:	89 44 24 04          	mov    %eax,0x4(%esp)
  100fd0:	c7 04 24 ce 31 10 00 	movl   $0x1031ce,(%esp)
  100fd7:	e8 15 14 00 00       	call   1023f1 <cprintf>
//	cprintf("  oesp 0x%08x\n", regs->oesp);	don't print - useless
	cprintf("  ebx  0x%08x\n", regs->ebx);
  100fdc:	8b 45 08             	mov    0x8(%ebp),%eax
  100fdf:	8b 40 10             	mov    0x10(%eax),%eax
  100fe2:	89 44 24 04          	mov    %eax,0x4(%esp)
  100fe6:	c7 04 24 dd 31 10 00 	movl   $0x1031dd,(%esp)
  100fed:	e8 ff 13 00 00       	call   1023f1 <cprintf>
	cprintf("  edx  0x%08x\n", regs->edx);
  100ff2:	8b 45 08             	mov    0x8(%ebp),%eax
  100ff5:	8b 40 14             	mov    0x14(%eax),%eax
  100ff8:	89 44 24 04          	mov    %eax,0x4(%esp)
  100ffc:	c7 04 24 ec 31 10 00 	movl   $0x1031ec,(%esp)
  101003:	e8 e9 13 00 00       	call   1023f1 <cprintf>
	cprintf("  ecx  0x%08x\n", regs->ecx);
  101008:	8b 45 08             	mov    0x8(%ebp),%eax
  10100b:	8b 40 18             	mov    0x18(%eax),%eax
  10100e:	89 44 24 04          	mov    %eax,0x4(%esp)
  101012:	c7 04 24 fb 31 10 00 	movl   $0x1031fb,(%esp)
  101019:	e8 d3 13 00 00       	call   1023f1 <cprintf>
	cprintf("  eax  0x%08x\n", regs->eax);
  10101e:	8b 45 08             	mov    0x8(%ebp),%eax
  101021:	8b 40 1c             	mov    0x1c(%eax),%eax
  101024:	89 44 24 04          	mov    %eax,0x4(%esp)
  101028:	c7 04 24 0a 32 10 00 	movl   $0x10320a,(%esp)
  10102f:	e8 bd 13 00 00       	call   1023f1 <cprintf>
}
  101034:	c9                   	leave  
  101035:	c3                   	ret    

00101036 <trap_print>:

void
trap_print(trapframe *tf)
{
  101036:	55                   	push   %ebp
  101037:	89 e5                	mov    %esp,%ebp
  101039:	83 ec 18             	sub    $0x18,%esp
	cprintf("TRAP frame at %p\n", tf);
  10103c:	8b 45 08             	mov    0x8(%ebp),%eax
  10103f:	89 44 24 04          	mov    %eax,0x4(%esp)
  101043:	c7 04 24 19 32 10 00 	movl   $0x103219,(%esp)
  10104a:	e8 a2 13 00 00       	call   1023f1 <cprintf>
	trap_print_regs(&tf->regs);
  10104f:	8b 45 08             	mov    0x8(%ebp),%eax
  101052:	89 04 24             	mov    %eax,(%esp)
  101055:	e8 3b ff ff ff       	call   100f95 <trap_print_regs>
	cprintf("  es   0x----%04x\n", tf->es);
  10105a:	8b 45 08             	mov    0x8(%ebp),%eax
  10105d:	0f b7 40 28          	movzwl 0x28(%eax),%eax
  101061:	0f b7 c0             	movzwl %ax,%eax
  101064:	89 44 24 04          	mov    %eax,0x4(%esp)
  101068:	c7 04 24 2b 32 10 00 	movl   $0x10322b,(%esp)
  10106f:	e8 7d 13 00 00       	call   1023f1 <cprintf>
	cprintf("  ds   0x----%04x\n", tf->ds);
  101074:	8b 45 08             	mov    0x8(%ebp),%eax
  101077:	0f b7 40 2c          	movzwl 0x2c(%eax),%eax
  10107b:	0f b7 c0             	movzwl %ax,%eax
  10107e:	89 44 24 04          	mov    %eax,0x4(%esp)
  101082:	c7 04 24 3e 32 10 00 	movl   $0x10323e,(%esp)
  101089:	e8 63 13 00 00       	call   1023f1 <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->trapno, trap_name(tf->trapno));
  10108e:	8b 45 08             	mov    0x8(%ebp),%eax
  101091:	8b 40 30             	mov    0x30(%eax),%eax
  101094:	89 04 24             	mov    %eax,(%esp)
  101097:	e8 d0 fe ff ff       	call   100f6c <trap_name>
  10109c:	89 c2                	mov    %eax,%edx
  10109e:	8b 45 08             	mov    0x8(%ebp),%eax
  1010a1:	8b 40 30             	mov    0x30(%eax),%eax
  1010a4:	89 54 24 08          	mov    %edx,0x8(%esp)
  1010a8:	89 44 24 04          	mov    %eax,0x4(%esp)
  1010ac:	c7 04 24 51 32 10 00 	movl   $0x103251,(%esp)
  1010b3:	e8 39 13 00 00       	call   1023f1 <cprintf>
	cprintf("  err  0x%08x\n", tf->err);
  1010b8:	8b 45 08             	mov    0x8(%ebp),%eax
  1010bb:	8b 40 34             	mov    0x34(%eax),%eax
  1010be:	89 44 24 04          	mov    %eax,0x4(%esp)
  1010c2:	c7 04 24 63 32 10 00 	movl   $0x103263,(%esp)
  1010c9:	e8 23 13 00 00       	call   1023f1 <cprintf>
	cprintf("  eip  0x%08x\n", tf->eip);
  1010ce:	8b 45 08             	mov    0x8(%ebp),%eax
  1010d1:	8b 40 38             	mov    0x38(%eax),%eax
  1010d4:	89 44 24 04          	mov    %eax,0x4(%esp)
  1010d8:	c7 04 24 72 32 10 00 	movl   $0x103272,(%esp)
  1010df:	e8 0d 13 00 00       	call   1023f1 <cprintf>
	cprintf("  cs   0x----%04x\n", tf->cs);
  1010e4:	8b 45 08             	mov    0x8(%ebp),%eax
  1010e7:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
  1010eb:	0f b7 c0             	movzwl %ax,%eax
  1010ee:	89 44 24 04          	mov    %eax,0x4(%esp)
  1010f2:	c7 04 24 81 32 10 00 	movl   $0x103281,(%esp)
  1010f9:	e8 f3 12 00 00       	call   1023f1 <cprintf>
	cprintf("  flag 0x%08x\n", tf->eflags);
  1010fe:	8b 45 08             	mov    0x8(%ebp),%eax
  101101:	8b 40 40             	mov    0x40(%eax),%eax
  101104:	89 44 24 04          	mov    %eax,0x4(%esp)
  101108:	c7 04 24 94 32 10 00 	movl   $0x103294,(%esp)
  10110f:	e8 dd 12 00 00       	call   1023f1 <cprintf>
	cprintf("  esp  0x%08x\n", tf->esp);
  101114:	8b 45 08             	mov    0x8(%ebp),%eax
  101117:	8b 40 44             	mov    0x44(%eax),%eax
  10111a:	89 44 24 04          	mov    %eax,0x4(%esp)
  10111e:	c7 04 24 a3 32 10 00 	movl   $0x1032a3,(%esp)
  101125:	e8 c7 12 00 00       	call   1023f1 <cprintf>
	cprintf("  ss   0x----%04x\n", tf->ss);
  10112a:	8b 45 08             	mov    0x8(%ebp),%eax
  10112d:	0f b7 40 48          	movzwl 0x48(%eax),%eax
  101131:	0f b7 c0             	movzwl %ax,%eax
  101134:	89 44 24 04          	mov    %eax,0x4(%esp)
  101138:	c7 04 24 b2 32 10 00 	movl   $0x1032b2,(%esp)
  10113f:	e8 ad 12 00 00       	call   1023f1 <cprintf>
}
  101144:	c9                   	leave  
  101145:	c3                   	ret    

00101146 <trap>:

void gcc_noreturn
trap(trapframe *tf)
{
  101146:	55                   	push   %ebp
  101147:	89 e5                	mov    %esp,%ebp
  101149:	83 ec 28             	sub    $0x28,%esp
	// The user-level environment may have set the DF flag,
	// and some versions of GCC rely on DF being clear.
	asm volatile("cld" ::: "cc");
  10114c:	fc                   	cld    

	// If this trap was anticipated, just use the designated handler.
	cpu *c = cpu_cur();
  10114d:	e8 c7 fd ff ff       	call   100f19 <cpu_cur>
  101152:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	if (c->recover)
  101155:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  101158:	8b 80 a0 00 00 00    	mov    0xa0(%eax),%eax
  10115e:	85 c0                	test   %eax,%eax
  101160:	74 1e                	je     101180 <trap+0x3a>
		c->recover(tf, c->recoverdata);
  101162:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  101165:	8b 90 a0 00 00 00    	mov    0xa0(%eax),%edx
  10116b:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  10116e:	8b 80 a4 00 00 00    	mov    0xa4(%eax),%eax
  101174:	89 44 24 04          	mov    %eax,0x4(%esp)
  101178:	8b 45 08             	mov    0x8(%ebp),%eax
  10117b:	89 04 24             	mov    %eax,(%esp)
  10117e:	ff d2                	call   *%edx

	trap_print(tf);
  101180:	8b 45 08             	mov    0x8(%ebp),%eax
  101183:	89 04 24             	mov    %eax,(%esp)
  101186:	e8 ab fe ff ff       	call   101036 <trap_print>
	panic("unhandled trap");
  10118b:	c7 44 24 08 c5 32 10 	movl   $0x1032c5,0x8(%esp)
  101192:	00 
  101193:	c7 44 24 04 80 00 00 	movl   $0x80,0x4(%esp)
  10119a:	00 
  10119b:	c7 04 24 bd 2f 10 00 	movl   $0x102fbd,(%esp)
  1011a2:	e8 8d f1 ff ff       	call   100334 <debug_panic>

001011a7 <trap_check_recover>:
}


// Helper function for trap_check_recover(), below:
// handles "anticipated" traps by simply resuming at a new EIP.
static void gcc_noreturn
trap_check_recover(trapframe *tf, void *recoverdata)
{
  1011a7:	55                   	push   %ebp
  1011a8:	89 e5                	mov    %esp,%ebp
  1011aa:	83 ec 18             	sub    $0x18,%esp
	trap_check_args *args = recoverdata;
  1011ad:	8b 45 0c             	mov    0xc(%ebp),%eax
  1011b0:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	tf->eip = (uint32_t) args->reip;	// Use recovery EIP on return
  1011b3:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  1011b6:	8b 00                	mov    (%eax),%eax
  1011b8:	89 c2                	mov    %eax,%edx
  1011ba:	8b 45 08             	mov    0x8(%ebp),%eax
  1011bd:	89 50 38             	mov    %edx,0x38(%eax)
	args->trapno = tf->trapno;		// Return trap number
  1011c0:	8b 45 08             	mov    0x8(%ebp),%eax
  1011c3:	8b 40 30             	mov    0x30(%eax),%eax
  1011c6:	89 c2                	mov    %eax,%edx
  1011c8:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  1011cb:	89 50 04             	mov    %edx,0x4(%eax)
	trap_return(tf);
  1011ce:	8b 45 08             	mov    0x8(%ebp),%eax
  1011d1:	89 04 24             	mov    %eax,(%esp)
  1011d4:	e8 27 03 00 00       	call   101500 <trap_return>

001011d9 <trap_check_kernel>:
}

// Check for correct handling of traps from kernel mode.
// Called on the boot CPU after trap_init() and trap_setup().
void
trap_check_kernel(void)
{
  1011d9:	55                   	push   %ebp
  1011da:	89 e5                	mov    %esp,%ebp
  1011dc:	83 ec 28             	sub    $0x28,%esp
static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  1011df:	8c 4d fe             	movw   %cs,0xfffffffe(%ebp)
        return cs;
  1011e2:	0f b7 45 fe          	movzwl 0xfffffffe(%ebp),%eax
	assert((read_cs() & 3) == 0);	// better be in kernel mode!
  1011e6:	0f b7 c0             	movzwl %ax,%eax
  1011e9:	83 e0 03             	and    $0x3,%eax
  1011ec:	85 c0                	test   %eax,%eax
  1011ee:	74 24                	je     101214 <trap_check_kernel+0x3b>
  1011f0:	c7 44 24 0c d4 32 10 	movl   $0x1032d4,0xc(%esp)
  1011f7:	00 
  1011f8:	c7 44 24 08 df 2f 10 	movl   $0x102fdf,0x8(%esp)
  1011ff:	00 
  101200:	c7 44 24 04 94 00 00 	movl   $0x94,0x4(%esp)
  101207:	00 
  101208:	c7 04 24 bd 2f 10 00 	movl   $0x102fbd,(%esp)
  10120f:	e8 20 f1 ff ff       	call   100334 <debug_panic>

	cpu *c = cpu_cur();
  101214:	e8 00 fd ff ff       	call   100f19 <cpu_cur>
  101219:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
	c->recover = trap_check_recover;
  10121c:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10121f:	c7 80 a0 00 00 00 a7 	movl   $0x1011a7,0xa0(%eax)
  101226:	11 10 00 
	trap_check(&c->recoverdata);
  101229:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10122c:	05 a4 00 00 00       	add    $0xa4,%eax
  101231:	89 04 24             	mov    %eax,(%esp)
  101234:	e8 96 00 00 00       	call   1012cf <trap_check>
	c->recover = NULL;	// No more mr. nice-guy; traps are real again
  101239:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10123c:	c7 80 a0 00 00 00 00 	movl   $0x0,0xa0(%eax)
  101243:	00 00 00 

	cprintf("trap_check_kernel() succeeded!\n");
  101246:	c7 04 24 ec 32 10 00 	movl   $0x1032ec,(%esp)
  10124d:	e8 9f 11 00 00       	call   1023f1 <cprintf>
}
  101252:	c9                   	leave  
  101253:	c3                   	ret    

00101254 <trap_check_user>:

// Check for correct handling of traps from user mode.
// Called from user() in kern/init.c, only in lab 1.
// We assume the "current cpu" is always the boot cpu;
// this true only because lab 1 doesn't start any other CPUs.
void
trap_check_user(void)
{
  101254:	55                   	push   %ebp
  101255:	89 e5                	mov    %esp,%ebp
  101257:	83 ec 28             	sub    $0x28,%esp
static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  10125a:	8c 4d fe             	movw   %cs,0xfffffffe(%ebp)
        return cs;
  10125d:	0f b7 45 fe          	movzwl 0xfffffffe(%ebp),%eax
	assert((read_cs() & 3) == 3);	// better be in user mode!
  101261:	0f b7 c0             	movzwl %ax,%eax
  101264:	83 e0 03             	and    $0x3,%eax
  101267:	83 f8 03             	cmp    $0x3,%eax
  10126a:	74 24                	je     101290 <trap_check_user+0x3c>
  10126c:	c7 44 24 0c 0c 33 10 	movl   $0x10330c,0xc(%esp)
  101273:	00 
  101274:	c7 44 24 08 df 2f 10 	movl   $0x102fdf,0x8(%esp)
  10127b:	00 
  10127c:	c7 44 24 04 a5 00 00 	movl   $0xa5,0x4(%esp)
  101283:	00 
  101284:	c7 04 24 bd 2f 10 00 	movl   $0x102fbd,(%esp)
  10128b:	e8 a4 f0 ff ff       	call   100334 <debug_panic>

	cpu *c = &cpu_boot;	// cpu_cur doesn't work from user mode!
  101290:	c7 45 f8 00 50 10 00 	movl   $0x105000,0xfffffff8(%ebp)
	c->recover = trap_check_recover;
  101297:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10129a:	c7 80 a0 00 00 00 a7 	movl   $0x1011a7,0xa0(%eax)
  1012a1:	11 10 00 
	trap_check(&c->recoverdata);
  1012a4:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1012a7:	05 a4 00 00 00       	add    $0xa4,%eax
  1012ac:	89 04 24             	mov    %eax,(%esp)
  1012af:	e8 1b 00 00 00       	call   1012cf <trap_check>
	c->recover = NULL;	// No more mr. nice-guy; traps are real again
  1012b4:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1012b7:	c7 80 a0 00 00 00 00 	movl   $0x0,0xa0(%eax)
  1012be:	00 00 00 

	cprintf("trap_check_user() succeeded!\n");
  1012c1:	c7 04 24 21 33 10 00 	movl   $0x103321,(%esp)
  1012c8:	e8 24 11 00 00       	call   1023f1 <cprintf>
}
  1012cd:	c9                   	leave  
  1012ce:	c3                   	ret    

001012cf <trap_check>:

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
  1012cf:	55                   	push   %ebp
  1012d0:	89 e5                	mov    %esp,%ebp
  1012d2:	57                   	push   %edi
  1012d3:	56                   	push   %esi
  1012d4:	53                   	push   %ebx
  1012d5:	83 ec 3c             	sub    $0x3c,%esp
	volatile int cookie = 0xfeedface;
  1012d8:	c7 45 ec ce fa ed fe 	movl   $0xfeedface,0xffffffec(%ebp)
	volatile trap_check_args args;
	*argsp = (void*)&args;	// provide args needed for trap recovery
  1012df:	8b 55 08             	mov    0x8(%ebp),%edx
  1012e2:	8d 45 e4             	lea    0xffffffe4(%ebp),%eax
  1012e5:	89 02                	mov    %eax,(%edx)

	// Try a divide by zero trap.
	// Be careful when using && to take the address of a label:
	// some versions of GCC (4.4.2 at least) will incorrectly try to
	// eliminate code it thinks is _only_ reachable via such a pointer.
	args.reip = after_div0;
  1012e7:	c7 45 e4 f5 12 10 00 	movl   $0x1012f5,0xffffffe4(%ebp)
	asm volatile("div %0,%0; after_div0:" : : "r" (0));
  1012ee:	b8 00 00 00 00       	mov    $0x0,%eax
  1012f3:	f7 f0                	div    %eax

001012f5 <after_div0>:
	assert(args.trapno == T_DIVIDE);
  1012f5:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  1012f8:	85 c0                	test   %eax,%eax
  1012fa:	74 24                	je     101320 <after_div0+0x2b>
  1012fc:	c7 44 24 0c 3f 33 10 	movl   $0x10333f,0xc(%esp)
  101303:	00 
  101304:	c7 44 24 08 df 2f 10 	movl   $0x102fdf,0x8(%esp)
  10130b:	00 
  10130c:	c7 44 24 04 c5 00 00 	movl   $0xc5,0x4(%esp)
  101313:	00 
  101314:	c7 04 24 bd 2f 10 00 	movl   $0x102fbd,(%esp)
  10131b:	e8 14 f0 ff ff       	call   100334 <debug_panic>

	// Make sure we got our correct stack back with us.
	// The asm ensures gcc uses ebp/esp to get the cookie.
	asm volatile("" : : : "eax","ebx","ecx","edx","esi","edi");
	assert(cookie == 0xfeedface);
  101320:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  101323:	3d ce fa ed fe       	cmp    $0xfeedface,%eax
  101328:	74 24                	je     10134e <after_div0+0x59>
  10132a:	c7 44 24 0c 57 33 10 	movl   $0x103357,0xc(%esp)
  101331:	00 
  101332:	c7 44 24 08 df 2f 10 	movl   $0x102fdf,0x8(%esp)
  101339:	00 
  10133a:	c7 44 24 04 ca 00 00 	movl   $0xca,0x4(%esp)
  101341:	00 
  101342:	c7 04 24 bd 2f 10 00 	movl   $0x102fbd,(%esp)
  101349:	e8 e6 ef ff ff       	call   100334 <debug_panic>

	// Breakpoint trap
	args.reip = after_breakpoint;
  10134e:	c7 45 e4 56 13 10 00 	movl   $0x101356,0xffffffe4(%ebp)
	asm volatile("int3; after_breakpoint:");
  101355:	cc                   	int3   

00101356 <after_breakpoint>:
	assert(args.trapno == T_BRKPT);
  101356:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  101359:	83 f8 03             	cmp    $0x3,%eax
  10135c:	74 24                	je     101382 <after_breakpoint+0x2c>
  10135e:	c7 44 24 0c 6c 33 10 	movl   $0x10336c,0xc(%esp)
  101365:	00 
  101366:	c7 44 24 08 df 2f 10 	movl   $0x102fdf,0x8(%esp)
  10136d:	00 
  10136e:	c7 44 24 04 cf 00 00 	movl   $0xcf,0x4(%esp)
  101375:	00 
  101376:	c7 04 24 bd 2f 10 00 	movl   $0x102fbd,(%esp)
  10137d:	e8 b2 ef ff ff       	call   100334 <debug_panic>

	// Overflow trap
	args.reip = after_overflow;
  101382:	c7 45 e4 91 13 10 00 	movl   $0x101391,0xffffffe4(%ebp)
	asm volatile("addl %0,%0; into; after_overflow:" : : "r" (0x70000000));
  101389:	b8 00 00 00 70       	mov    $0x70000000,%eax
  10138e:	01 c0                	add    %eax,%eax
  101390:	ce                   	into   

00101391 <after_overflow>:
	assert(args.trapno == T_OFLOW);
  101391:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  101394:	83 f8 04             	cmp    $0x4,%eax
  101397:	74 24                	je     1013bd <after_overflow+0x2c>
  101399:	c7 44 24 0c 83 33 10 	movl   $0x103383,0xc(%esp)
  1013a0:	00 
  1013a1:	c7 44 24 08 df 2f 10 	movl   $0x102fdf,0x8(%esp)
  1013a8:	00 
  1013a9:	c7 44 24 04 d4 00 00 	movl   $0xd4,0x4(%esp)
  1013b0:	00 
  1013b1:	c7 04 24 bd 2f 10 00 	movl   $0x102fbd,(%esp)
  1013b8:	e8 77 ef ff ff       	call   100334 <debug_panic>

	// Bounds trap
	args.reip = after_bound;
  1013bd:	c7 45 e4 da 13 10 00 	movl   $0x1013da,0xffffffe4(%ebp)
	int bounds[2] = { 1, 3 };
  1013c4:	c7 45 dc 01 00 00 00 	movl   $0x1,0xffffffdc(%ebp)
  1013cb:	c7 45 e0 03 00 00 00 	movl   $0x3,0xffffffe0(%ebp)
	asm volatile("boundl %0,%1; after_bound:" : : "r" (0), "m" (bounds[0]));
  1013d2:	b8 00 00 00 00       	mov    $0x0,%eax
  1013d7:	62 45 dc             	bound  %eax,0xffffffdc(%ebp)

001013da <after_bound>:
	assert(args.trapno == T_BOUND);
  1013da:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  1013dd:	83 f8 05             	cmp    $0x5,%eax
  1013e0:	74 24                	je     101406 <after_bound+0x2c>
  1013e2:	c7 44 24 0c 9a 33 10 	movl   $0x10339a,0xc(%esp)
  1013e9:	00 
  1013ea:	c7 44 24 08 df 2f 10 	movl   $0x102fdf,0x8(%esp)
  1013f1:	00 
  1013f2:	c7 44 24 04 da 00 00 	movl   $0xda,0x4(%esp)
  1013f9:	00 
  1013fa:	c7 04 24 bd 2f 10 00 	movl   $0x102fbd,(%esp)
  101401:	e8 2e ef ff ff       	call   100334 <debug_panic>

	// Illegal instruction trap
	args.reip = after_illegal;
  101406:	c7 45 e4 0f 14 10 00 	movl   $0x10140f,0xffffffe4(%ebp)
	asm volatile("ud2; after_illegal:");	// guaranteed to be undefined
  10140d:	0f 0b                	ud2a   

0010140f <after_illegal>:
	assert(args.trapno == T_ILLOP);
  10140f:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  101412:	83 f8 06             	cmp    $0x6,%eax
  101415:	74 24                	je     10143b <after_illegal+0x2c>
  101417:	c7 44 24 0c b1 33 10 	movl   $0x1033b1,0xc(%esp)
  10141e:	00 
  10141f:	c7 44 24 08 df 2f 10 	movl   $0x102fdf,0x8(%esp)
  101426:	00 
  101427:	c7 44 24 04 df 00 00 	movl   $0xdf,0x4(%esp)
  10142e:	00 
  10142f:	c7 04 24 bd 2f 10 00 	movl   $0x102fbd,(%esp)
  101436:	e8 f9 ee ff ff       	call   100334 <debug_panic>

	// General protection fault due to invalid segment load
	args.reip = after_gpfault;
  10143b:	c7 45 e4 49 14 10 00 	movl   $0x101449,0xffffffe4(%ebp)
	asm volatile("movl %0,%%fs; after_gpfault:" : : "r" (-1));
  101442:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  101447:	8e e0                	movl   %eax,%fs

00101449 <after_gpfault>:
	assert(args.trapno == T_GPFLT);
  101449:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  10144c:	83 f8 0d             	cmp    $0xd,%eax
  10144f:	74 24                	je     101475 <after_gpfault+0x2c>
  101451:	c7 44 24 0c c8 33 10 	movl   $0x1033c8,0xc(%esp)
  101458:	00 
  101459:	c7 44 24 08 df 2f 10 	movl   $0x102fdf,0x8(%esp)
  101460:	00 
  101461:	c7 44 24 04 e4 00 00 	movl   $0xe4,0x4(%esp)
  101468:	00 
  101469:	c7 04 24 bd 2f 10 00 	movl   $0x102fbd,(%esp)
  101470:	e8 bf ee ff ff       	call   100334 <debug_panic>
static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  101475:	8c 4d f2             	movw   %cs,0xfffffff2(%ebp)
        return cs;
  101478:	0f b7 45 f2          	movzwl 0xfffffff2(%ebp),%eax

	// General protection fault due to privilege violation
	if (read_cs() & 3) {
  10147c:	0f b7 c0             	movzwl %ax,%eax
  10147f:	83 e0 03             	and    $0x3,%eax
  101482:	85 c0                	test   %eax,%eax
  101484:	74 3a                	je     1014c0 <after_priv+0x2c>
		args.reip = after_priv;
  101486:	c7 45 e4 94 14 10 00 	movl   $0x101494,0xffffffe4(%ebp)
		asm volatile("lidt %0; after_priv:" : : "m" (idt_pd));
  10148d:	0f 01 1d 00 60 10 00 	lidtl  0x106000

00101494 <after_priv>:
		assert(args.trapno == T_GPFLT);
  101494:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  101497:	83 f8 0d             	cmp    $0xd,%eax
  10149a:	74 24                	je     1014c0 <after_priv+0x2c>
  10149c:	c7 44 24 0c c8 33 10 	movl   $0x1033c8,0xc(%esp)
  1014a3:	00 
  1014a4:	c7 44 24 08 df 2f 10 	movl   $0x102fdf,0x8(%esp)
  1014ab:	00 
  1014ac:	c7 44 24 04 ea 00 00 	movl   $0xea,0x4(%esp)
  1014b3:	00 
  1014b4:	c7 04 24 bd 2f 10 00 	movl   $0x102fbd,(%esp)
  1014bb:	e8 74 ee ff ff       	call   100334 <debug_panic>
	}

	// Make sure our stack cookie is still with us
	assert(cookie == 0xfeedface);
  1014c0:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  1014c3:	3d ce fa ed fe       	cmp    $0xfeedface,%eax
  1014c8:	74 24                	je     1014ee <after_priv+0x5a>
  1014ca:	c7 44 24 0c 57 33 10 	movl   $0x103357,0xc(%esp)
  1014d1:	00 
  1014d2:	c7 44 24 08 df 2f 10 	movl   $0x102fdf,0x8(%esp)
  1014d9:	00 
  1014da:	c7 44 24 04 ee 00 00 	movl   $0xee,0x4(%esp)
  1014e1:	00 
  1014e2:	c7 04 24 bd 2f 10 00 	movl   $0x102fbd,(%esp)
  1014e9:	e8 46 ee ff ff       	call   100334 <debug_panic>

	*argsp = NULL;	// recovery mechanism not needed anymore
  1014ee:	8b 45 08             	mov    0x8(%ebp),%eax
  1014f1:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}
  1014f7:	83 c4 3c             	add    $0x3c,%esp
  1014fa:	5b                   	pop    %ebx
  1014fb:	5e                   	pop    %esi
  1014fc:	5f                   	pop    %edi
  1014fd:	5d                   	pop    %ebp
  1014fe:	c3                   	ret    
  1014ff:	90                   	nop    

00101500 <trap_return>:
trap_return:
/*
 * Lab 1: Your code here for trap_return
 */
1:	jmp	1b		// just spin
  101500:	eb fe                	jmp    101500 <trap_return>
  101502:	90                   	nop    
  101503:	90                   	nop    

00101504 <video_init>:
static uint16_t crt_pos;

void
video_init(void)
{
  101504:	55                   	push   %ebp
  101505:	89 e5                	mov    %esp,%ebp
  101507:	83 ec 30             	sub    $0x30,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	/* Get a pointer to the memory-mapped text display buffer. */
	cp = (uint16_t*) mem_ptr(CGA_BUF);
  10150a:	c7 45 d4 00 80 0b 00 	movl   $0xb8000,0xffffffd4(%ebp)
	was = *cp;
  101511:	8b 45 d4             	mov    0xffffffd4(%ebp),%eax
  101514:	0f b7 00             	movzwl (%eax),%eax
  101517:	66 89 45 da          	mov    %ax,0xffffffda(%ebp)
	*cp = (uint16_t) 0xA55A;
  10151b:	8b 45 d4             	mov    0xffffffd4(%ebp),%eax
  10151e:	66 c7 00 5a a5       	movw   $0xa55a,(%eax)
	if (*cp != 0xA55A) {
  101523:	8b 45 d4             	mov    0xffffffd4(%ebp),%eax
  101526:	0f b7 00             	movzwl (%eax),%eax
  101529:	66 3d 5a a5          	cmp    $0xa55a,%ax
  10152d:	74 13                	je     101542 <video_init+0x3e>
		cp = (uint16_t*) mem_ptr(MONO_BUF);
  10152f:	c7 45 d4 00 00 0b 00 	movl   $0xb0000,0xffffffd4(%ebp)
		addr_6845 = MONO_BASE;
  101536:	c7 05 60 7f 10 00 b4 	movl   $0x3b4,0x107f60
  10153d:	03 00 00 
  101540:	eb 14                	jmp    101556 <video_init+0x52>
	} else {
		*cp = was;
  101542:	8b 55 d4             	mov    0xffffffd4(%ebp),%edx
  101545:	0f b7 45 da          	movzwl 0xffffffda(%ebp),%eax
  101549:	66 89 02             	mov    %ax,(%edx)
		addr_6845 = CGA_BASE;
  10154c:	c7 05 60 7f 10 00 d4 	movl   $0x3d4,0x107f60
  101553:	03 00 00 
	}
	
	/* Extract cursor location */
	outb(addr_6845, 14);
  101556:	a1 60 7f 10 00       	mov    0x107f60,%eax
  10155b:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
  10155e:	c6 45 e3 0e          	movb   $0xe,0xffffffe3(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  101562:	0f b6 45 e3          	movzbl 0xffffffe3(%ebp),%eax
  101566:	8b 55 e4             	mov    0xffffffe4(%ebp),%edx
  101569:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
  10156a:	a1 60 7f 10 00       	mov    0x107f60,%eax
  10156f:	83 c0 01             	add    $0x1,%eax
  101572:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101575:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
  101578:	ec                   	in     (%dx),%al
  101579:	88 45 eb             	mov    %al,0xffffffeb(%ebp)
	return data;
  10157c:	0f b6 45 eb          	movzbl 0xffffffeb(%ebp),%eax
  101580:	0f b6 c0             	movzbl %al,%eax
  101583:	c1 e0 08             	shl    $0x8,%eax
  101586:	89 45 dc             	mov    %eax,0xffffffdc(%ebp)
	outb(addr_6845, 15);
  101589:	a1 60 7f 10 00       	mov    0x107f60,%eax
  10158e:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
  101591:	c6 45 f3 0f          	movb   $0xf,0xfffffff3(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  101595:	0f b6 45 f3          	movzbl 0xfffffff3(%ebp),%eax
  101599:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  10159c:	ee                   	out    %al,(%dx)
	pos |= inb(addr_6845 + 1);
  10159d:	a1 60 7f 10 00       	mov    0x107f60,%eax
  1015a2:	83 c0 01             	add    $0x1,%eax
  1015a5:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  1015a8:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  1015ab:	ec                   	in     (%dx),%al
  1015ac:	88 45 fb             	mov    %al,0xfffffffb(%ebp)
	return data;
  1015af:	0f b6 45 fb          	movzbl 0xfffffffb(%ebp),%eax
  1015b3:	0f b6 c0             	movzbl %al,%eax
  1015b6:	09 45 dc             	or     %eax,0xffffffdc(%ebp)

	crt_buf = (uint16_t*) cp;
  1015b9:	8b 45 d4             	mov    0xffffffd4(%ebp),%eax
  1015bc:	a3 64 7f 10 00       	mov    %eax,0x107f64
	crt_pos = pos;
  1015c1:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  1015c4:	66 a3 68 7f 10 00    	mov    %ax,0x107f68
}
  1015ca:	c9                   	leave  
  1015cb:	c3                   	ret    

001015cc <video_putc>:



void
video_putc(int c)
{
  1015cc:	55                   	push   %ebp
  1015cd:	89 e5                	mov    %esp,%ebp
  1015cf:	53                   	push   %ebx
  1015d0:	83 ec 44             	sub    $0x44,%esp
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
  1015d3:	8b 45 08             	mov    0x8(%ebp),%eax
  1015d6:	b0 00                	mov    $0x0,%al
  1015d8:	85 c0                	test   %eax,%eax
  1015da:	75 07                	jne    1015e3 <video_putc+0x17>
		c |= 0x0700;
  1015dc:	81 4d 08 00 07 00 00 	orl    $0x700,0x8(%ebp)

	switch (c & 0xff) {
  1015e3:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
  1015e7:	89 45 c4             	mov    %eax,0xffffffc4(%ebp)
  1015ea:	83 7d c4 09          	cmpl   $0x9,0xffffffc4(%ebp)
  1015ee:	0f 84 c0 00 00 00    	je     1016b4 <video_putc+0xe8>
  1015f4:	83 7d c4 09          	cmpl   $0x9,0xffffffc4(%ebp)
  1015f8:	7f 0b                	jg     101605 <video_putc+0x39>
  1015fa:	83 7d c4 08          	cmpl   $0x8,0xffffffc4(%ebp)
  1015fe:	74 16                	je     101616 <video_putc+0x4a>
  101600:	e9 ed 00 00 00       	jmp    1016f2 <video_putc+0x126>
  101605:	83 7d c4 0a          	cmpl   $0xa,0xffffffc4(%ebp)
  101609:	74 50                	je     10165b <video_putc+0x8f>
  10160b:	83 7d c4 0d          	cmpl   $0xd,0xffffffc4(%ebp)
  10160f:	74 5a                	je     10166b <video_putc+0x9f>
  101611:	e9 dc 00 00 00       	jmp    1016f2 <video_putc+0x126>
	case '\b':
		if (crt_pos > 0) {
  101616:	0f b7 05 68 7f 10 00 	movzwl 0x107f68,%eax
  10161d:	66 85 c0             	test   %ax,%ax
  101620:	0f 84 f0 00 00 00    	je     101716 <video_putc+0x14a>
			crt_pos--;
  101626:	0f b7 05 68 7f 10 00 	movzwl 0x107f68,%eax
  10162d:	83 e8 01             	sub    $0x1,%eax
  101630:	66 a3 68 7f 10 00    	mov    %ax,0x107f68
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
  101636:	0f b7 05 68 7f 10 00 	movzwl 0x107f68,%eax
  10163d:	0f b7 c0             	movzwl %ax,%eax
  101640:	01 c0                	add    %eax,%eax
  101642:	89 c2                	mov    %eax,%edx
  101644:	a1 64 7f 10 00       	mov    0x107f64,%eax
  101649:	01 c2                	add    %eax,%edx
  10164b:	8b 45 08             	mov    0x8(%ebp),%eax
  10164e:	b0 00                	mov    $0x0,%al
  101650:	83 c8 20             	or     $0x20,%eax
  101653:	66 89 02             	mov    %ax,(%edx)
		}
		break;
  101656:	e9 bb 00 00 00       	jmp    101716 <video_putc+0x14a>
	case '\n':
		crt_pos += CRT_COLS;
  10165b:	0f b7 05 68 7f 10 00 	movzwl 0x107f68,%eax
  101662:	83 c0 50             	add    $0x50,%eax
  101665:	66 a3 68 7f 10 00    	mov    %ax,0x107f68
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
  10166b:	0f b7 0d 68 7f 10 00 	movzwl 0x107f68,%ecx
  101672:	0f b7 15 68 7f 10 00 	movzwl 0x107f68,%edx
  101679:	0f b7 c2             	movzwl %dx,%eax
  10167c:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
  101682:	c1 e8 10             	shr    $0x10,%eax
  101685:	89 c3                	mov    %eax,%ebx
  101687:	66 c1 eb 06          	shr    $0x6,%bx
  10168b:	66 89 5d ca          	mov    %bx,0xffffffca(%ebp)
  10168f:	0f b7 45 ca          	movzwl 0xffffffca(%ebp),%eax
  101693:	c1 e0 02             	shl    $0x2,%eax
  101696:	66 03 45 ca          	add    0xffffffca(%ebp),%ax
  10169a:	c1 e0 04             	shl    $0x4,%eax
  10169d:	89 d3                	mov    %edx,%ebx
  10169f:	66 29 c3             	sub    %ax,%bx
  1016a2:	66 89 5d ca          	mov    %bx,0xffffffca(%ebp)
  1016a6:	89 c8                	mov    %ecx,%eax
  1016a8:	66 2b 45 ca          	sub    0xffffffca(%ebp),%ax
  1016ac:	66 a3 68 7f 10 00    	mov    %ax,0x107f68
		break;
  1016b2:	eb 62                	jmp    101716 <video_putc+0x14a>
	case '\t':
		video_putc(' ');
  1016b4:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  1016bb:	e8 0c ff ff ff       	call   1015cc <video_putc>
		video_putc(' ');
  1016c0:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  1016c7:	e8 00 ff ff ff       	call   1015cc <video_putc>
		video_putc(' ');
  1016cc:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  1016d3:	e8 f4 fe ff ff       	call   1015cc <video_putc>
		video_putc(' ');
  1016d8:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  1016df:	e8 e8 fe ff ff       	call   1015cc <video_putc>
		video_putc(' ');
  1016e4:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  1016eb:	e8 dc fe ff ff       	call   1015cc <video_putc>
		break;
  1016f0:	eb 24                	jmp    101716 <video_putc+0x14a>
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
  1016f2:	0f b7 0d 68 7f 10 00 	movzwl 0x107f68,%ecx
  1016f9:	0f b7 c1             	movzwl %cx,%eax
  1016fc:	01 c0                	add    %eax,%eax
  1016fe:	89 c2                	mov    %eax,%edx
  101700:	a1 64 7f 10 00       	mov    0x107f64,%eax
  101705:	01 c2                	add    %eax,%edx
  101707:	8b 45 08             	mov    0x8(%ebp),%eax
  10170a:	66 89 02             	mov    %ax,(%edx)
  10170d:	8d 41 01             	lea    0x1(%ecx),%eax
  101710:	66 a3 68 7f 10 00    	mov    %ax,0x107f68
		break;
	}

	// What is the purpose of this?
  // if the crt position is creater than the crt area
	if (crt_pos >= CRT_SIZE) {
  101716:	0f b7 05 68 7f 10 00 	movzwl 0x107f68,%eax
  10171d:	66 3d cf 07          	cmp    $0x7cf,%ax
  101721:	76 5e                	jbe    101781 <video_putc+0x1b5>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS,
  101723:	a1 64 7f 10 00       	mov    0x107f64,%eax
  101728:	05 a0 00 00 00       	add    $0xa0,%eax
  10172d:	8b 15 64 7f 10 00    	mov    0x107f64,%edx
  101733:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
  10173a:	00 
  10173b:	89 44 24 04          	mov    %eax,0x4(%esp)
  10173f:	89 14 24             	mov    %edx,(%esp)
  101742:	e8 1b 0f 00 00       	call   102662 <memmove>
			(CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
  101747:	c7 45 d8 80 07 00 00 	movl   $0x780,0xffffffd8(%ebp)
  10174e:	eb 18                	jmp    101768 <video_putc+0x19c>
			// crt_buf[i] = 0x0700 | ' ';
			crt_buf[i] = 0x0700 | '#';
  101750:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  101753:	01 c0                	add    %eax,%eax
  101755:	89 c2                	mov    %eax,%edx
  101757:	a1 64 7f 10 00       	mov    0x107f64,%eax
  10175c:	8d 04 02             	lea    (%edx,%eax,1),%eax
  10175f:	66 c7 00 23 07       	movw   $0x723,(%eax)
  101764:	83 45 d8 01          	addl   $0x1,0xffffffd8(%ebp)
  101768:	81 7d d8 cf 07 00 00 	cmpl   $0x7cf,0xffffffd8(%ebp)
  10176f:	7e df                	jle    101750 <video_putc+0x184>
		crt_pos -= CRT_COLS;
  101771:	0f b7 05 68 7f 10 00 	movzwl 0x107f68,%eax
  101778:	83 e8 50             	sub    $0x50,%eax
  10177b:	66 a3 68 7f 10 00    	mov    %ax,0x107f68
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
  101781:	a1 60 7f 10 00       	mov    0x107f60,%eax
  101786:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)
  101789:	c6 45 df 0e          	movb   $0xe,0xffffffdf(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  10178d:	0f b6 45 df          	movzbl 0xffffffdf(%ebp),%eax
  101791:	8b 55 e0             	mov    0xffffffe0(%ebp),%edx
  101794:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
  101795:	0f b7 05 68 7f 10 00 	movzwl 0x107f68,%eax
  10179c:	66 c1 e8 08          	shr    $0x8,%ax
  1017a0:	0f b6 d0             	movzbl %al,%edx
  1017a3:	a1 60 7f 10 00       	mov    0x107f60,%eax
  1017a8:	83 c0 01             	add    $0x1,%eax
  1017ab:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  1017ae:	88 55 e7             	mov    %dl,0xffffffe7(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  1017b1:	0f b6 45 e7          	movzbl 0xffffffe7(%ebp),%eax
  1017b5:	8b 55 e8             	mov    0xffffffe8(%ebp),%edx
  1017b8:	ee                   	out    %al,(%dx)
	outb(addr_6845, 15);
  1017b9:	a1 60 7f 10 00       	mov    0x107f60,%eax
  1017be:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
  1017c1:	c6 45 ef 0f          	movb   $0xf,0xffffffef(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  1017c5:	0f b6 45 ef          	movzbl 0xffffffef(%ebp),%eax
  1017c9:	8b 55 f0             	mov    0xfffffff0(%ebp),%edx
  1017cc:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos);
  1017cd:	0f b7 05 68 7f 10 00 	movzwl 0x107f68,%eax
  1017d4:	0f b6 d0             	movzbl %al,%edx
  1017d7:	a1 60 7f 10 00       	mov    0x107f60,%eax
  1017dc:	83 c0 01             	add    $0x1,%eax
  1017df:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  1017e2:	88 55 f7             	mov    %dl,0xfffffff7(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  1017e5:	0f b6 45 f7          	movzbl 0xfffffff7(%ebp),%eax
  1017e9:	8b 55 f8             	mov    0xfffffff8(%ebp),%edx
  1017ec:	ee                   	out    %al,(%dx)
}
  1017ed:	83 c4 44             	add    $0x44,%esp
  1017f0:	5b                   	pop    %ebx
  1017f1:	5d                   	pop    %ebp
  1017f2:	c3                   	ret    
  1017f3:	90                   	nop    

001017f4 <kbd_proc_data>:
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
  1017f4:	55                   	push   %ebp
  1017f5:	89 e5                	mov    %esp,%ebp
  1017f7:	83 ec 38             	sub    $0x38,%esp
  1017fa:	c7 45 ec 64 00 00 00 	movl   $0x64,0xffffffec(%ebp)
static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101801:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
  101804:	ec                   	in     (%dx),%al
  101805:	88 45 eb             	mov    %al,0xffffffeb(%ebp)
	return data;
  101808:	0f b6 45 eb          	movzbl 0xffffffeb(%ebp),%eax
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
  10180c:	0f b6 c0             	movzbl %al,%eax
  10180f:	83 e0 01             	and    $0x1,%eax
  101812:	85 c0                	test   %eax,%eax
  101814:	75 0c                	jne    101822 <kbd_proc_data+0x2e>
		return -1;
  101816:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,0xffffffd8(%ebp)
  10181d:	e9 69 01 00 00       	jmp    10198b <kbd_proc_data+0x197>
  101822:	c7 45 f4 60 00 00 00 	movl   $0x60,0xfffffff4(%ebp)
static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101829:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  10182c:	ec                   	in     (%dx),%al
  10182d:	88 45 f3             	mov    %al,0xfffffff3(%ebp)
	return data;
  101830:	0f b6 45 f3          	movzbl 0xfffffff3(%ebp),%eax

	data = inb(KBDATAP);
  101834:	88 45 ea             	mov    %al,0xffffffea(%ebp)

	if (data == 0xE0) {
  101837:	80 7d ea e0          	cmpb   $0xe0,0xffffffea(%ebp)
  10183b:	75 19                	jne    101856 <kbd_proc_data+0x62>
		// E0 escape character
		shift |= E0ESC;
  10183d:	a1 6c 7f 10 00       	mov    0x107f6c,%eax
  101842:	83 c8 40             	or     $0x40,%eax
  101845:	a3 6c 7f 10 00       	mov    %eax,0x107f6c
		return 0;
  10184a:	c7 45 d8 00 00 00 00 	movl   $0x0,0xffffffd8(%ebp)
  101851:	e9 35 01 00 00       	jmp    10198b <kbd_proc_data+0x197>
	} else if (data & 0x80) {
  101856:	0f b6 45 ea          	movzbl 0xffffffea(%ebp),%eax
  10185a:	84 c0                	test   %al,%al
  10185c:	79 53                	jns    1018b1 <kbd_proc_data+0xbd>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
  10185e:	a1 6c 7f 10 00       	mov    0x107f6c,%eax
  101863:	83 e0 40             	and    $0x40,%eax
  101866:	85 c0                	test   %eax,%eax
  101868:	75 0c                	jne    101876 <kbd_proc_data+0x82>
  10186a:	0f b6 45 ea          	movzbl 0xffffffea(%ebp),%eax
  10186e:	83 e0 7f             	and    $0x7f,%eax
  101871:	88 45 df             	mov    %al,0xffffffdf(%ebp)
  101874:	eb 07                	jmp    10187d <kbd_proc_data+0x89>
  101876:	0f b6 45 ea          	movzbl 0xffffffea(%ebp),%eax
  10187a:	88 45 df             	mov    %al,0xffffffdf(%ebp)
  10187d:	0f b6 45 df          	movzbl 0xffffffdf(%ebp),%eax
  101881:	88 45 ea             	mov    %al,0xffffffea(%ebp)
		shift &= ~(shiftcode[data] | E0ESC);
  101884:	0f b6 45 ea          	movzbl 0xffffffea(%ebp),%eax
  101888:	0f b6 80 20 60 10 00 	movzbl 0x106020(%eax),%eax
  10188f:	83 c8 40             	or     $0x40,%eax
  101892:	0f b6 c0             	movzbl %al,%eax
  101895:	f7 d0                	not    %eax
  101897:	89 c2                	mov    %eax,%edx
  101899:	a1 6c 7f 10 00       	mov    0x107f6c,%eax
  10189e:	21 d0                	and    %edx,%eax
  1018a0:	a3 6c 7f 10 00       	mov    %eax,0x107f6c
		return 0;
  1018a5:	c7 45 d8 00 00 00 00 	movl   $0x0,0xffffffd8(%ebp)
  1018ac:	e9 da 00 00 00       	jmp    10198b <kbd_proc_data+0x197>
	} else if (shift & E0ESC) {
  1018b1:	a1 6c 7f 10 00       	mov    0x107f6c,%eax
  1018b6:	83 e0 40             	and    $0x40,%eax
  1018b9:	85 c0                	test   %eax,%eax
  1018bb:	74 11                	je     1018ce <kbd_proc_data+0xda>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
  1018bd:	80 4d ea 80          	orb    $0x80,0xffffffea(%ebp)
		shift &= ~E0ESC;
  1018c1:	a1 6c 7f 10 00       	mov    0x107f6c,%eax
  1018c6:	83 e0 bf             	and    $0xffffffbf,%eax
  1018c9:	a3 6c 7f 10 00       	mov    %eax,0x107f6c
	}

	shift |= shiftcode[data];
  1018ce:	0f b6 45 ea          	movzbl 0xffffffea(%ebp),%eax
  1018d2:	0f b6 80 20 60 10 00 	movzbl 0x106020(%eax),%eax
  1018d9:	0f b6 d0             	movzbl %al,%edx
  1018dc:	a1 6c 7f 10 00       	mov    0x107f6c,%eax
  1018e1:	09 d0                	or     %edx,%eax
  1018e3:	a3 6c 7f 10 00       	mov    %eax,0x107f6c
	shift ^= togglecode[data];
  1018e8:	0f b6 45 ea          	movzbl 0xffffffea(%ebp),%eax
  1018ec:	0f b6 80 20 61 10 00 	movzbl 0x106120(%eax),%eax
  1018f3:	0f b6 d0             	movzbl %al,%edx
  1018f6:	a1 6c 7f 10 00       	mov    0x107f6c,%eax
  1018fb:	31 d0                	xor    %edx,%eax
  1018fd:	a3 6c 7f 10 00       	mov    %eax,0x107f6c

	c = charcode[shift & (CTL | SHIFT)][data];
  101902:	a1 6c 7f 10 00       	mov    0x107f6c,%eax
  101907:	83 e0 03             	and    $0x3,%eax
  10190a:	8b 14 85 20 65 10 00 	mov    0x106520(,%eax,4),%edx
  101911:	0f b6 45 ea          	movzbl 0xffffffea(%ebp),%eax
  101915:	8d 04 02             	lea    (%edx,%eax,1),%eax
  101918:	0f b6 00             	movzbl (%eax),%eax
  10191b:	0f b6 c0             	movzbl %al,%eax
  10191e:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
	if (shift & CAPSLOCK) {
  101921:	a1 6c 7f 10 00       	mov    0x107f6c,%eax
  101926:	83 e0 08             	and    $0x8,%eax
  101929:	85 c0                	test   %eax,%eax
  10192b:	74 22                	je     10194f <kbd_proc_data+0x15b>
		if ('a' <= c && c <= 'z')
  10192d:	83 7d e4 60          	cmpl   $0x60,0xffffffe4(%ebp)
  101931:	7e 0c                	jle    10193f <kbd_proc_data+0x14b>
  101933:	83 7d e4 7a          	cmpl   $0x7a,0xffffffe4(%ebp)
  101937:	7f 06                	jg     10193f <kbd_proc_data+0x14b>
			c += 'A' - 'a';
  101939:	83 6d e4 20          	subl   $0x20,0xffffffe4(%ebp)
  10193d:	eb 10                	jmp    10194f <kbd_proc_data+0x15b>
		else if ('A' <= c && c <= 'Z')
  10193f:	83 7d e4 40          	cmpl   $0x40,0xffffffe4(%ebp)
  101943:	7e 0a                	jle    10194f <kbd_proc_data+0x15b>
  101945:	83 7d e4 5a          	cmpl   $0x5a,0xffffffe4(%ebp)
  101949:	7f 04                	jg     10194f <kbd_proc_data+0x15b>
			c += 'a' - 'A';
  10194b:	83 45 e4 20          	addl   $0x20,0xffffffe4(%ebp)
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
  10194f:	a1 6c 7f 10 00       	mov    0x107f6c,%eax
  101954:	f7 d0                	not    %eax
  101956:	83 e0 06             	and    $0x6,%eax
  101959:	85 c0                	test   %eax,%eax
  10195b:	75 28                	jne    101985 <kbd_proc_data+0x191>
  10195d:	81 7d e4 e9 00 00 00 	cmpl   $0xe9,0xffffffe4(%ebp)
  101964:	75 1f                	jne    101985 <kbd_proc_data+0x191>
		cprintf("Rebooting!\n");
  101966:	c7 04 24 df 33 10 00 	movl   $0x1033df,(%esp)
  10196d:	e8 7f 0a 00 00       	call   1023f1 <cprintf>
  101972:	c7 45 fc 92 00 00 00 	movl   $0x92,0xfffffffc(%ebp)
  101979:	c6 45 fb 03          	movb   $0x3,0xfffffffb(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  10197d:	0f b6 45 fb          	movzbl 0xfffffffb(%ebp),%eax
  101981:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  101984:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
  101985:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  101988:	89 45 d8             	mov    %eax,0xffffffd8(%ebp)
  10198b:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
}
  10198e:	c9                   	leave  
  10198f:	c3                   	ret    

00101990 <kbd_intr>:

void
kbd_intr(void)
{
  101990:	55                   	push   %ebp
  101991:	89 e5                	mov    %esp,%ebp
  101993:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
  101996:	c7 04 24 f4 17 10 00 	movl   $0x1017f4,(%esp)
  10199d:	e8 ea e7 ff ff       	call   10018c <cons_intr>
}
  1019a2:	c9                   	leave  
  1019a3:	c3                   	ret    

001019a4 <kbd_init>:

void
kbd_init(void)
{
  1019a4:	55                   	push   %ebp
  1019a5:	89 e5                	mov    %esp,%ebp
}
  1019a7:	5d                   	pop    %ebp
  1019a8:	c3                   	ret    
  1019a9:	90                   	nop    
  1019aa:	90                   	nop    
  1019ab:	90                   	nop    

001019ac <delay>:

// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
  1019ac:	55                   	push   %ebp
  1019ad:	89 e5                	mov    %esp,%ebp
  1019af:	83 ec 20             	sub    $0x20,%esp
  1019b2:	c7 45 e4 84 00 00 00 	movl   $0x84,0xffffffe4(%ebp)
static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  1019b9:	8b 55 e4             	mov    0xffffffe4(%ebp),%edx
  1019bc:	ec                   	in     (%dx),%al
  1019bd:	88 45 e3             	mov    %al,0xffffffe3(%ebp)
	return data;
  1019c0:	c7 45 ec 84 00 00 00 	movl   $0x84,0xffffffec(%ebp)
  1019c7:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
  1019ca:	ec                   	in     (%dx),%al
  1019cb:	88 45 eb             	mov    %al,0xffffffeb(%ebp)
  1019ce:	c7 45 f4 84 00 00 00 	movl   $0x84,0xfffffff4(%ebp)
  1019d5:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  1019d8:	ec                   	in     (%dx),%al
  1019d9:	88 45 f3             	mov    %al,0xfffffff3(%ebp)
  1019dc:	c7 45 fc 84 00 00 00 	movl   $0x84,0xfffffffc(%ebp)
  1019e3:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  1019e6:	ec                   	in     (%dx),%al
  1019e7:	88 45 fb             	mov    %al,0xfffffffb(%ebp)
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
  1019ea:	c9                   	leave  
  1019eb:	c3                   	ret    

001019ec <serial_proc_data>:

static int
serial_proc_data(void)
{
  1019ec:	55                   	push   %ebp
  1019ed:	89 e5                	mov    %esp,%ebp
  1019ef:	83 ec 14             	sub    $0x14,%esp
  1019f2:	c7 45 f4 fd 03 00 00 	movl   $0x3fd,0xfffffff4(%ebp)
static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  1019f9:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  1019fc:	ec                   	in     (%dx),%al
  1019fd:	88 45 f3             	mov    %al,0xfffffff3(%ebp)
	return data;
  101a00:	0f b6 45 f3          	movzbl 0xfffffff3(%ebp),%eax
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
  101a04:	0f b6 c0             	movzbl %al,%eax
  101a07:	83 e0 01             	and    $0x1,%eax
  101a0a:	85 c0                	test   %eax,%eax
  101a0c:	75 09                	jne    101a17 <serial_proc_data+0x2b>
		return -1;
  101a0e:	c7 45 ec ff ff ff ff 	movl   $0xffffffff,0xffffffec(%ebp)
  101a15:	eb 18                	jmp    101a2f <serial_proc_data+0x43>
  101a17:	c7 45 fc f8 03 00 00 	movl   $0x3f8,0xfffffffc(%ebp)
static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101a1e:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  101a21:	ec                   	in     (%dx),%al
  101a22:	88 45 fb             	mov    %al,0xfffffffb(%ebp)
	return data;
  101a25:	0f b6 45 fb          	movzbl 0xfffffffb(%ebp),%eax
	return inb(COM1+COM_RX);
  101a29:	0f b6 c0             	movzbl %al,%eax
  101a2c:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  101a2f:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
}
  101a32:	c9                   	leave  
  101a33:	c3                   	ret    

00101a34 <serial_intr>:

void
serial_intr(void)
{
  101a34:	55                   	push   %ebp
  101a35:	89 e5                	mov    %esp,%ebp
  101a37:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
  101a3a:	a1 80 7f 10 00       	mov    0x107f80,%eax
  101a3f:	85 c0                	test   %eax,%eax
  101a41:	74 0c                	je     101a4f <serial_intr+0x1b>
		cons_intr(serial_proc_data);
  101a43:	c7 04 24 ec 19 10 00 	movl   $0x1019ec,(%esp)
  101a4a:	e8 3d e7 ff ff       	call   10018c <cons_intr>
}
  101a4f:	c9                   	leave  
  101a50:	c3                   	ret    

00101a51 <serial_putc>:

void
serial_putc(int c)
{
  101a51:	55                   	push   %ebp
  101a52:	89 e5                	mov    %esp,%ebp
  101a54:	83 ec 20             	sub    $0x20,%esp
	if (!serial_exists)
  101a57:	a1 80 7f 10 00       	mov    0x107f80,%eax
  101a5c:	85 c0                	test   %eax,%eax
  101a5e:	74 4f                	je     101aaf <serial_putc+0x5e>
		return;

	int i;
	for (i = 0;
  101a60:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
  101a67:	eb 09                	jmp    101a72 <serial_putc+0x21>
	     i++)
		delay();
  101a69:	e8 3e ff ff ff       	call   1019ac <delay>
  101a6e:	83 45 ec 01          	addl   $0x1,0xffffffec(%ebp)
  101a72:	c7 45 f4 fd 03 00 00 	movl   $0x3fd,0xfffffff4(%ebp)
static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101a79:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  101a7c:	ec                   	in     (%dx),%al
  101a7d:	88 45 f3             	mov    %al,0xfffffff3(%ebp)
	return data;
  101a80:	0f b6 45 f3          	movzbl 0xfffffff3(%ebp),%eax
  101a84:	0f b6 c0             	movzbl %al,%eax
  101a87:	83 e0 20             	and    $0x20,%eax
  101a8a:	85 c0                	test   %eax,%eax
  101a8c:	75 09                	jne    101a97 <serial_putc+0x46>
  101a8e:	81 7d ec ff 31 00 00 	cmpl   $0x31ff,0xffffffec(%ebp)
  101a95:	7e d2                	jle    101a69 <serial_putc+0x18>
	
	outb(COM1 + COM_TX, c);
  101a97:	8b 45 08             	mov    0x8(%ebp),%eax
  101a9a:	0f b6 c0             	movzbl %al,%eax
  101a9d:	c7 45 fc f8 03 00 00 	movl   $0x3f8,0xfffffffc(%ebp)
  101aa4:	88 45 fb             	mov    %al,0xfffffffb(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  101aa7:	0f b6 45 fb          	movzbl 0xfffffffb(%ebp),%eax
  101aab:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  101aae:	ee                   	out    %al,(%dx)
}
  101aaf:	c9                   	leave  
  101ab0:	c3                   	ret    

00101ab1 <serial_init>:

void
serial_init(void)
{
  101ab1:	55                   	push   %ebp
  101ab2:	89 e5                	mov    %esp,%ebp
  101ab4:	83 ec 50             	sub    $0x50,%esp
  101ab7:	c7 45 b4 fa 03 00 00 	movl   $0x3fa,0xffffffb4(%ebp)
  101abe:	c6 45 b3 00          	movb   $0x0,0xffffffb3(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  101ac2:	0f b6 45 b3          	movzbl 0xffffffb3(%ebp),%eax
  101ac6:	8b 55 b4             	mov    0xffffffb4(%ebp),%edx
  101ac9:	ee                   	out    %al,(%dx)
  101aca:	c7 45 bc fb 03 00 00 	movl   $0x3fb,0xffffffbc(%ebp)
  101ad1:	c6 45 bb 80          	movb   $0x80,0xffffffbb(%ebp)
  101ad5:	0f b6 45 bb          	movzbl 0xffffffbb(%ebp),%eax
  101ad9:	8b 55 bc             	mov    0xffffffbc(%ebp),%edx
  101adc:	ee                   	out    %al,(%dx)
  101add:	c7 45 c4 f8 03 00 00 	movl   $0x3f8,0xffffffc4(%ebp)
  101ae4:	c6 45 c3 0c          	movb   $0xc,0xffffffc3(%ebp)
  101ae8:	0f b6 45 c3          	movzbl 0xffffffc3(%ebp),%eax
  101aec:	8b 55 c4             	mov    0xffffffc4(%ebp),%edx
  101aef:	ee                   	out    %al,(%dx)
  101af0:	c7 45 cc f9 03 00 00 	movl   $0x3f9,0xffffffcc(%ebp)
  101af7:	c6 45 cb 00          	movb   $0x0,0xffffffcb(%ebp)
  101afb:	0f b6 45 cb          	movzbl 0xffffffcb(%ebp),%eax
  101aff:	8b 55 cc             	mov    0xffffffcc(%ebp),%edx
  101b02:	ee                   	out    %al,(%dx)
  101b03:	c7 45 d4 fb 03 00 00 	movl   $0x3fb,0xffffffd4(%ebp)
  101b0a:	c6 45 d3 03          	movb   $0x3,0xffffffd3(%ebp)
  101b0e:	0f b6 45 d3          	movzbl 0xffffffd3(%ebp),%eax
  101b12:	8b 55 d4             	mov    0xffffffd4(%ebp),%edx
  101b15:	ee                   	out    %al,(%dx)
  101b16:	c7 45 dc fc 03 00 00 	movl   $0x3fc,0xffffffdc(%ebp)
  101b1d:	c6 45 db 00          	movb   $0x0,0xffffffdb(%ebp)
  101b21:	0f b6 45 db          	movzbl 0xffffffdb(%ebp),%eax
  101b25:	8b 55 dc             	mov    0xffffffdc(%ebp),%edx
  101b28:	ee                   	out    %al,(%dx)
  101b29:	c7 45 e4 f9 03 00 00 	movl   $0x3f9,0xffffffe4(%ebp)
  101b30:	c6 45 e3 01          	movb   $0x1,0xffffffe3(%ebp)
  101b34:	0f b6 45 e3          	movzbl 0xffffffe3(%ebp),%eax
  101b38:	8b 55 e4             	mov    0xffffffe4(%ebp),%edx
  101b3b:	ee                   	out    %al,(%dx)
  101b3c:	c7 45 ec fd 03 00 00 	movl   $0x3fd,0xffffffec(%ebp)
  101b43:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
  101b46:	ec                   	in     (%dx),%al
  101b47:	88 45 eb             	mov    %al,0xffffffeb(%ebp)
  101b4a:	0f b6 45 eb          	movzbl 0xffffffeb(%ebp),%eax
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
  101b4e:	3c ff                	cmp    $0xff,%al
  101b50:	0f 95 c0             	setne  %al
  101b53:	0f b6 c0             	movzbl %al,%eax
  101b56:	a3 80 7f 10 00       	mov    %eax,0x107f80
  101b5b:	c7 45 f4 fa 03 00 00 	movl   $0x3fa,0xfffffff4(%ebp)
static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101b62:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  101b65:	ec                   	in     (%dx),%al
  101b66:	88 45 f3             	mov    %al,0xfffffff3(%ebp)
	return data;
  101b69:	c7 45 fc f8 03 00 00 	movl   $0x3f8,0xfffffffc(%ebp)
  101b70:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  101b73:	ec                   	in     (%dx),%al
  101b74:	88 45 fb             	mov    %al,0xfffffffb(%ebp)
	(void) inb(COM1+COM_IIR);
	(void) inb(COM1+COM_RX);
}
  101b77:	c9                   	leave  
  101b78:	c3                   	ret    
  101b79:	90                   	nop    
  101b7a:	90                   	nop    
  101b7b:	90                   	nop    

00101b7c <nvram_read>:


unsigned
nvram_read(unsigned reg)
{
  101b7c:	55                   	push   %ebp
  101b7d:	89 e5                	mov    %esp,%ebp
  101b7f:	83 ec 10             	sub    $0x10,%esp
	outb(IO_RTC, reg);
  101b82:	8b 45 08             	mov    0x8(%ebp),%eax
  101b85:	0f b6 c0             	movzbl %al,%eax
  101b88:	c7 45 f4 70 00 00 00 	movl   $0x70,0xfffffff4(%ebp)
  101b8f:	88 45 f3             	mov    %al,0xfffffff3(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  101b92:	0f b6 45 f3          	movzbl 0xfffffff3(%ebp),%eax
  101b96:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  101b99:	ee                   	out    %al,(%dx)
  101b9a:	c7 45 fc 71 00 00 00 	movl   $0x71,0xfffffffc(%ebp)
  101ba1:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  101ba4:	ec                   	in     (%dx),%al
  101ba5:	88 45 fb             	mov    %al,0xfffffffb(%ebp)
  101ba8:	0f b6 45 fb          	movzbl 0xfffffffb(%ebp),%eax
	return inb(IO_RTC+1);
  101bac:	0f b6 c0             	movzbl %al,%eax
}
  101baf:	c9                   	leave  
  101bb0:	c3                   	ret    

00101bb1 <nvram_read16>:

unsigned
nvram_read16(unsigned r)
{
  101bb1:	55                   	push   %ebp
  101bb2:	89 e5                	mov    %esp,%ebp
  101bb4:	53                   	push   %ebx
  101bb5:	83 ec 04             	sub    $0x4,%esp
	return nvram_read(r) | (nvram_read(r + 1) << 8);
  101bb8:	8b 45 08             	mov    0x8(%ebp),%eax
  101bbb:	89 04 24             	mov    %eax,(%esp)
  101bbe:	e8 b9 ff ff ff       	call   101b7c <nvram_read>
  101bc3:	89 c3                	mov    %eax,%ebx
  101bc5:	8b 45 08             	mov    0x8(%ebp),%eax
  101bc8:	83 c0 01             	add    $0x1,%eax
  101bcb:	89 04 24             	mov    %eax,(%esp)
  101bce:	e8 a9 ff ff ff       	call   101b7c <nvram_read>
  101bd3:	c1 e0 08             	shl    $0x8,%eax
  101bd6:	09 d8                	or     %ebx,%eax
}
  101bd8:	83 c4 04             	add    $0x4,%esp
  101bdb:	5b                   	pop    %ebx
  101bdc:	5d                   	pop    %ebp
  101bdd:	c3                   	ret    

00101bde <nvram_write>:

void
nvram_write(unsigned reg, unsigned datum)
{
  101bde:	55                   	push   %ebp
  101bdf:	89 e5                	mov    %esp,%ebp
  101be1:	83 ec 10             	sub    $0x10,%esp
	outb(IO_RTC, reg);
  101be4:	8b 45 08             	mov    0x8(%ebp),%eax
  101be7:	0f b6 c0             	movzbl %al,%eax
  101bea:	c7 45 f4 70 00 00 00 	movl   $0x70,0xfffffff4(%ebp)
  101bf1:	88 45 f3             	mov    %al,0xfffffff3(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  101bf4:	0f b6 45 f3          	movzbl 0xfffffff3(%ebp),%eax
  101bf8:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  101bfb:	ee                   	out    %al,(%dx)
	outb(IO_RTC+1, datum);
  101bfc:	8b 45 0c             	mov    0xc(%ebp),%eax
  101bff:	0f b6 c0             	movzbl %al,%eax
  101c02:	c7 45 fc 71 00 00 00 	movl   $0x71,0xfffffffc(%ebp)
  101c09:	88 45 fb             	mov    %al,0xfffffffb(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  101c0c:	0f b6 45 fb          	movzbl 0xfffffffb(%ebp),%eax
  101c10:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  101c13:	ee                   	out    %al,(%dx)
}
  101c14:	c9                   	leave  
  101c15:	c3                   	ret    
  101c16:	90                   	nop    
  101c17:	90                   	nop    

00101c18 <getuint>:
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static uintmax_t
getuint(printstate *st, va_list *ap)
{
  101c18:	55                   	push   %ebp
  101c19:	89 e5                	mov    %esp,%ebp
  101c1b:	83 ec 08             	sub    $0x8,%esp
	if (st->flags & F_LL)
  101c1e:	8b 45 08             	mov    0x8(%ebp),%eax
  101c21:	8b 40 18             	mov    0x18(%eax),%eax
  101c24:	83 e0 02             	and    $0x2,%eax
  101c27:	85 c0                	test   %eax,%eax
  101c29:	74 22                	je     101c4d <getuint+0x35>
		return va_arg(*ap, unsigned long long);
  101c2b:	8b 45 0c             	mov    0xc(%ebp),%eax
  101c2e:	8b 00                	mov    (%eax),%eax
  101c30:	8d 50 08             	lea    0x8(%eax),%edx
  101c33:	8b 45 0c             	mov    0xc(%ebp),%eax
  101c36:	89 10                	mov    %edx,(%eax)
  101c38:	8b 45 0c             	mov    0xc(%ebp),%eax
  101c3b:	8b 00                	mov    (%eax),%eax
  101c3d:	83 e8 08             	sub    $0x8,%eax
  101c40:	8b 10                	mov    (%eax),%edx
  101c42:	8b 48 04             	mov    0x4(%eax),%ecx
  101c45:	89 55 f8             	mov    %edx,0xfffffff8(%ebp)
  101c48:	89 4d fc             	mov    %ecx,0xfffffffc(%ebp)
  101c4b:	eb 51                	jmp    101c9e <getuint+0x86>
	else if (st->flags & F_L)
  101c4d:	8b 45 08             	mov    0x8(%ebp),%eax
  101c50:	8b 40 18             	mov    0x18(%eax),%eax
  101c53:	83 e0 01             	and    $0x1,%eax
  101c56:	84 c0                	test   %al,%al
  101c58:	74 23                	je     101c7d <getuint+0x65>
		return va_arg(*ap, unsigned long);
  101c5a:	8b 45 0c             	mov    0xc(%ebp),%eax
  101c5d:	8b 00                	mov    (%eax),%eax
  101c5f:	8d 50 04             	lea    0x4(%eax),%edx
  101c62:	8b 45 0c             	mov    0xc(%ebp),%eax
  101c65:	89 10                	mov    %edx,(%eax)
  101c67:	8b 45 0c             	mov    0xc(%ebp),%eax
  101c6a:	8b 00                	mov    (%eax),%eax
  101c6c:	83 e8 04             	sub    $0x4,%eax
  101c6f:	8b 00                	mov    (%eax),%eax
  101c71:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  101c74:	c7 45 fc 00 00 00 00 	movl   $0x0,0xfffffffc(%ebp)
  101c7b:	eb 21                	jmp    101c9e <getuint+0x86>
	else
		return va_arg(*ap, unsigned int);
  101c7d:	8b 45 0c             	mov    0xc(%ebp),%eax
  101c80:	8b 00                	mov    (%eax),%eax
  101c82:	8d 50 04             	lea    0x4(%eax),%edx
  101c85:	8b 45 0c             	mov    0xc(%ebp),%eax
  101c88:	89 10                	mov    %edx,(%eax)
  101c8a:	8b 45 0c             	mov    0xc(%ebp),%eax
  101c8d:	8b 00                	mov    (%eax),%eax
  101c8f:	83 e8 04             	sub    $0x4,%eax
  101c92:	8b 00                	mov    (%eax),%eax
  101c94:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  101c97:	c7 45 fc 00 00 00 00 	movl   $0x0,0xfffffffc(%ebp)
  101c9e:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  101ca1:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
}
  101ca4:	c9                   	leave  
  101ca5:	c3                   	ret    

00101ca6 <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static intmax_t
getint(printstate *st, va_list *ap)
{
  101ca6:	55                   	push   %ebp
  101ca7:	89 e5                	mov    %esp,%ebp
  101ca9:	83 ec 08             	sub    $0x8,%esp
	if (st->flags & F_LL)
  101cac:	8b 45 08             	mov    0x8(%ebp),%eax
  101caf:	8b 40 18             	mov    0x18(%eax),%eax
  101cb2:	83 e0 02             	and    $0x2,%eax
  101cb5:	85 c0                	test   %eax,%eax
  101cb7:	74 22                	je     101cdb <getint+0x35>
		return va_arg(*ap, long long);
  101cb9:	8b 45 0c             	mov    0xc(%ebp),%eax
  101cbc:	8b 00                	mov    (%eax),%eax
  101cbe:	8d 50 08             	lea    0x8(%eax),%edx
  101cc1:	8b 45 0c             	mov    0xc(%ebp),%eax
  101cc4:	89 10                	mov    %edx,(%eax)
  101cc6:	8b 45 0c             	mov    0xc(%ebp),%eax
  101cc9:	8b 00                	mov    (%eax),%eax
  101ccb:	83 e8 08             	sub    $0x8,%eax
  101cce:	8b 10                	mov    (%eax),%edx
  101cd0:	8b 48 04             	mov    0x4(%eax),%ecx
  101cd3:	89 55 f8             	mov    %edx,0xfffffff8(%ebp)
  101cd6:	89 4d fc             	mov    %ecx,0xfffffffc(%ebp)
  101cd9:	eb 53                	jmp    101d2e <getint+0x88>
	else if (st->flags & F_L)
  101cdb:	8b 45 08             	mov    0x8(%ebp),%eax
  101cde:	8b 40 18             	mov    0x18(%eax),%eax
  101ce1:	83 e0 01             	and    $0x1,%eax
  101ce4:	84 c0                	test   %al,%al
  101ce6:	74 24                	je     101d0c <getint+0x66>
		return va_arg(*ap, long);
  101ce8:	8b 45 0c             	mov    0xc(%ebp),%eax
  101ceb:	8b 00                	mov    (%eax),%eax
  101ced:	8d 50 04             	lea    0x4(%eax),%edx
  101cf0:	8b 45 0c             	mov    0xc(%ebp),%eax
  101cf3:	89 10                	mov    %edx,(%eax)
  101cf5:	8b 45 0c             	mov    0xc(%ebp),%eax
  101cf8:	8b 00                	mov    (%eax),%eax
  101cfa:	83 e8 04             	sub    $0x4,%eax
  101cfd:	8b 00                	mov    (%eax),%eax
  101cff:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  101d02:	89 c1                	mov    %eax,%ecx
  101d04:	c1 f9 1f             	sar    $0x1f,%ecx
  101d07:	89 4d fc             	mov    %ecx,0xfffffffc(%ebp)
  101d0a:	eb 22                	jmp    101d2e <getint+0x88>
	else
		return va_arg(*ap, int);
  101d0c:	8b 45 0c             	mov    0xc(%ebp),%eax
  101d0f:	8b 00                	mov    (%eax),%eax
  101d11:	8d 50 04             	lea    0x4(%eax),%edx
  101d14:	8b 45 0c             	mov    0xc(%ebp),%eax
  101d17:	89 10                	mov    %edx,(%eax)
  101d19:	8b 45 0c             	mov    0xc(%ebp),%eax
  101d1c:	8b 00                	mov    (%eax),%eax
  101d1e:	83 e8 04             	sub    $0x4,%eax
  101d21:	8b 00                	mov    (%eax),%eax
  101d23:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  101d26:	89 c2                	mov    %eax,%edx
  101d28:	c1 fa 1f             	sar    $0x1f,%edx
  101d2b:	89 55 fc             	mov    %edx,0xfffffffc(%ebp)
  101d2e:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  101d31:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
}
  101d34:	c9                   	leave  
  101d35:	c3                   	ret    

00101d36 <putpad>:

// Print padding characters, and an optional sign before a number.
static void
putpad(printstate *st)
{
  101d36:	55                   	push   %ebp
  101d37:	89 e5                	mov    %esp,%ebp
  101d39:	83 ec 08             	sub    $0x8,%esp
	while (--st->width >= 0)
  101d3c:	eb 1a                	jmp    101d58 <putpad+0x22>
		st->putch(st->padc, st->putdat);
  101d3e:	8b 45 08             	mov    0x8(%ebp),%eax
  101d41:	8b 08                	mov    (%eax),%ecx
  101d43:	8b 45 08             	mov    0x8(%ebp),%eax
  101d46:	8b 50 04             	mov    0x4(%eax),%edx
  101d49:	8b 45 08             	mov    0x8(%ebp),%eax
  101d4c:	8b 40 08             	mov    0x8(%eax),%eax
  101d4f:	89 54 24 04          	mov    %edx,0x4(%esp)
  101d53:	89 04 24             	mov    %eax,(%esp)
  101d56:	ff d1                	call   *%ecx
  101d58:	8b 45 08             	mov    0x8(%ebp),%eax
  101d5b:	8b 40 0c             	mov    0xc(%eax),%eax
  101d5e:	8d 50 ff             	lea    0xffffffff(%eax),%edx
  101d61:	8b 45 08             	mov    0x8(%ebp),%eax
  101d64:	89 50 0c             	mov    %edx,0xc(%eax)
  101d67:	8b 45 08             	mov    0x8(%ebp),%eax
  101d6a:	8b 40 0c             	mov    0xc(%eax),%eax
  101d6d:	85 c0                	test   %eax,%eax
  101d6f:	79 cd                	jns    101d3e <putpad+0x8>
}
  101d71:	c9                   	leave  
  101d72:	c3                   	ret    

00101d73 <putstr>:

// Print a string with a specified maximum length (-1=unlimited),
// with any appropriate left or right field padding.
static void
putstr(printstate *st, const char *str, int maxlen)
{
  101d73:	55                   	push   %ebp
  101d74:	89 e5                	mov    %esp,%ebp
  101d76:	53                   	push   %ebx
  101d77:	83 ec 24             	sub    $0x24,%esp
	const char *lim;		// find where the string actually ends
	if (maxlen < 0)
  101d7a:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  101d7e:	79 18                	jns    101d98 <putstr+0x25>
		lim = strchr(str, 0);	// find the terminating null
  101d80:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  101d87:	00 
  101d88:	8b 45 0c             	mov    0xc(%ebp),%eax
  101d8b:	89 04 24             	mov    %eax,(%esp)
  101d8e:	e8 16 08 00 00       	call   1025a9 <strchr>
  101d93:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
  101d96:	eb 2c                	jmp    101dc4 <putstr+0x51>
	else if ((lim = memchr(str, 0, maxlen)) == NULL)
  101d98:	8b 45 10             	mov    0x10(%ebp),%eax
  101d9b:	89 44 24 08          	mov    %eax,0x8(%esp)
  101d9f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  101da6:	00 
  101da7:	8b 45 0c             	mov    0xc(%ebp),%eax
  101daa:	89 04 24             	mov    %eax,(%esp)
  101dad:	e8 f4 09 00 00       	call   1027a6 <memchr>
  101db2:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
  101db5:	83 7d f4 00          	cmpl   $0x0,0xfffffff4(%ebp)
  101db9:	75 09                	jne    101dc4 <putstr+0x51>
		lim = str + maxlen;
  101dbb:	8b 45 10             	mov    0x10(%ebp),%eax
  101dbe:	03 45 0c             	add    0xc(%ebp),%eax
  101dc1:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	st->width -= (lim-str);		// deduct string length from field width
  101dc4:	8b 45 08             	mov    0x8(%ebp),%eax
  101dc7:	8b 48 0c             	mov    0xc(%eax),%ecx
  101dca:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  101dcd:	8b 45 0c             	mov    0xc(%ebp),%eax
  101dd0:	89 d3                	mov    %edx,%ebx
  101dd2:	29 c3                	sub    %eax,%ebx
  101dd4:	89 d8                	mov    %ebx,%eax
  101dd6:	89 ca                	mov    %ecx,%edx
  101dd8:	29 c2                	sub    %eax,%edx
  101dda:	8b 45 08             	mov    0x8(%ebp),%eax
  101ddd:	89 50 0c             	mov    %edx,0xc(%eax)

	if (!(st->flags & F_RPAD))	// print left-side padding
  101de0:	8b 45 08             	mov    0x8(%ebp),%eax
  101de3:	8b 40 18             	mov    0x18(%eax),%eax
  101de6:	83 e0 10             	and    $0x10,%eax
  101de9:	85 c0                	test   %eax,%eax
  101deb:	75 32                	jne    101e1f <putstr+0xac>
		putpad(st);		// (also leaves st->width == 0)
  101ded:	8b 45 08             	mov    0x8(%ebp),%eax
  101df0:	89 04 24             	mov    %eax,(%esp)
  101df3:	e8 3e ff ff ff       	call   101d36 <putpad>
	while (str < lim) {
  101df8:	eb 25                	jmp    101e1f <putstr+0xac>
		char ch = *str++;
  101dfa:	8b 45 0c             	mov    0xc(%ebp),%eax
  101dfd:	0f b6 00             	movzbl (%eax),%eax
  101e00:	88 45 fb             	mov    %al,0xfffffffb(%ebp)
  101e03:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
			st->putch(ch, st->putdat);
  101e07:	8b 45 08             	mov    0x8(%ebp),%eax
  101e0a:	8b 08                	mov    (%eax),%ecx
  101e0c:	8b 45 08             	mov    0x8(%ebp),%eax
  101e0f:	8b 40 04             	mov    0x4(%eax),%eax
  101e12:	0f be 55 fb          	movsbl 0xfffffffb(%ebp),%edx
  101e16:	89 44 24 04          	mov    %eax,0x4(%esp)
  101e1a:	89 14 24             	mov    %edx,(%esp)
  101e1d:	ff d1                	call   *%ecx
  101e1f:	8b 45 0c             	mov    0xc(%ebp),%eax
  101e22:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  101e25:	72 d3                	jb     101dfa <putstr+0x87>
	}
	putpad(st);			// print right-side padding
  101e27:	8b 45 08             	mov    0x8(%ebp),%eax
  101e2a:	89 04 24             	mov    %eax,(%esp)
  101e2d:	e8 04 ff ff ff       	call   101d36 <putpad>
}
  101e32:	83 c4 24             	add    $0x24,%esp
  101e35:	5b                   	pop    %ebx
  101e36:	5d                   	pop    %ebp
  101e37:	c3                   	ret    

00101e38 <genint>:

// Generate a number (base <= 16) in reverse order into a string buffer.
static char *
genint(printstate *st, char *p, uintmax_t num)
{
  101e38:	55                   	push   %ebp
  101e39:	89 e5                	mov    %esp,%ebp
  101e3b:	53                   	push   %ebx
  101e3c:	83 ec 24             	sub    $0x24,%esp
  101e3f:	8b 45 10             	mov    0x10(%ebp),%eax
  101e42:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
  101e45:	8b 45 14             	mov    0x14(%ebp),%eax
  101e48:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= st->base)
  101e4b:	8b 45 08             	mov    0x8(%ebp),%eax
  101e4e:	8b 40 1c             	mov    0x1c(%eax),%eax
  101e51:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  101e54:	89 c2                	mov    %eax,%edx
  101e56:	c1 fa 1f             	sar    $0x1f,%edx
  101e59:	89 55 ec             	mov    %edx,0xffffffec(%ebp)
  101e5c:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  101e5f:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  101e62:	77 54                	ja     101eb8 <genint+0x80>
  101e64:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
  101e67:	3b 55 f4             	cmp    0xfffffff4(%ebp),%edx
  101e6a:	72 08                	jb     101e74 <genint+0x3c>
  101e6c:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  101e6f:	3b 45 f0             	cmp    0xfffffff0(%ebp),%eax
  101e72:	77 44                	ja     101eb8 <genint+0x80>
		p = genint(st, p, num / st->base);	// output higher digits
  101e74:	8b 45 08             	mov    0x8(%ebp),%eax
  101e77:	8b 40 1c             	mov    0x1c(%eax),%eax
  101e7a:	89 c2                	mov    %eax,%edx
  101e7c:	c1 fa 1f             	sar    $0x1f,%edx
  101e7f:	89 44 24 08          	mov    %eax,0x8(%esp)
  101e83:	89 54 24 0c          	mov    %edx,0xc(%esp)
  101e87:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  101e8a:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  101e8d:	89 04 24             	mov    %eax,(%esp)
  101e90:	89 54 24 04          	mov    %edx,0x4(%esp)
  101e94:	e8 57 09 00 00       	call   1027f0 <__udivdi3>
  101e99:	89 44 24 08          	mov    %eax,0x8(%esp)
  101e9d:	89 54 24 0c          	mov    %edx,0xc(%esp)
  101ea1:	8b 45 0c             	mov    0xc(%ebp),%eax
  101ea4:	89 44 24 04          	mov    %eax,0x4(%esp)
  101ea8:	8b 45 08             	mov    0x8(%ebp),%eax
  101eab:	89 04 24             	mov    %eax,(%esp)
  101eae:	e8 85 ff ff ff       	call   101e38 <genint>
  101eb3:	89 45 0c             	mov    %eax,0xc(%ebp)
  101eb6:	eb 1b                	jmp    101ed3 <genint+0x9b>
	else if (st->signc >= 0)
  101eb8:	8b 45 08             	mov    0x8(%ebp),%eax
  101ebb:	8b 40 14             	mov    0x14(%eax),%eax
  101ebe:	85 c0                	test   %eax,%eax
  101ec0:	78 11                	js     101ed3 <genint+0x9b>
		*p++ = st->signc;			// output leading sign
  101ec2:	8b 45 08             	mov    0x8(%ebp),%eax
  101ec5:	8b 40 14             	mov    0x14(%eax),%eax
  101ec8:	89 c2                	mov    %eax,%edx
  101eca:	8b 45 0c             	mov    0xc(%ebp),%eax
  101ecd:	88 10                	mov    %dl,(%eax)
  101ecf:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
	*p++ = "0123456789abcdef"[num % st->base];	// output this digit
  101ed3:	8b 45 08             	mov    0x8(%ebp),%eax
  101ed6:	8b 40 1c             	mov    0x1c(%eax),%eax
  101ed9:	89 c2                	mov    %eax,%edx
  101edb:	c1 fa 1f             	sar    $0x1f,%edx
  101ede:	8b 4d f0             	mov    0xfffffff0(%ebp),%ecx
  101ee1:	8b 5d f4             	mov    0xfffffff4(%ebp),%ebx
  101ee4:	89 44 24 08          	mov    %eax,0x8(%esp)
  101ee8:	89 54 24 0c          	mov    %edx,0xc(%esp)
  101eec:	89 0c 24             	mov    %ecx,(%esp)
  101eef:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  101ef3:	e8 28 0a 00 00       	call   102920 <__umoddi3>
  101ef8:	05 ec 33 10 00       	add    $0x1033ec,%eax
  101efd:	0f b6 10             	movzbl (%eax),%edx
  101f00:	8b 45 0c             	mov    0xc(%ebp),%eax
  101f03:	88 10                	mov    %dl,(%eax)
  101f05:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
	return p;
  101f09:	8b 45 0c             	mov    0xc(%ebp),%eax
}
  101f0c:	83 c4 24             	add    $0x24,%esp
  101f0f:	5b                   	pop    %ebx
  101f10:	5d                   	pop    %ebp
  101f11:	c3                   	ret    

00101f12 <putint>:

// Print an integer with any appropriate field padding.
static void
putint(printstate *st, uintmax_t num, int base)
{
  101f12:	55                   	push   %ebp
  101f13:	89 e5                	mov    %esp,%ebp
  101f15:	83 ec 48             	sub    $0x48,%esp
  101f18:	8b 45 0c             	mov    0xc(%ebp),%eax
  101f1b:	89 45 c8             	mov    %eax,0xffffffc8(%ebp)
  101f1e:	8b 45 10             	mov    0x10(%ebp),%eax
  101f21:	89 45 cc             	mov    %eax,0xffffffcc(%ebp)
	char buf[30], *p = buf;		// big enough for any 64-bit int in octal
  101f24:	8d 45 de             	lea    0xffffffde(%ebp),%eax
  101f27:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	st->base = base;		// select base for genint
  101f2a:	8b 55 08             	mov    0x8(%ebp),%edx
  101f2d:	8b 45 14             	mov    0x14(%ebp),%eax
  101f30:	89 42 1c             	mov    %eax,0x1c(%edx)
	p = genint(st, p, num);		// output to the string buffer
  101f33:	8b 45 c8             	mov    0xffffffc8(%ebp),%eax
  101f36:	8b 55 cc             	mov    0xffffffcc(%ebp),%edx
  101f39:	89 44 24 08          	mov    %eax,0x8(%esp)
  101f3d:	89 54 24 0c          	mov    %edx,0xc(%esp)
  101f41:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  101f44:	89 44 24 04          	mov    %eax,0x4(%esp)
  101f48:	8b 45 08             	mov    0x8(%ebp),%eax
  101f4b:	89 04 24             	mov    %eax,(%esp)
  101f4e:	e8 e5 fe ff ff       	call   101e38 <genint>
  101f53:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	putstr(st, buf, p-buf);		// print it with left/right padding
  101f56:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  101f59:	8d 45 de             	lea    0xffffffde(%ebp),%eax
  101f5c:	89 d1                	mov    %edx,%ecx
  101f5e:	29 c1                	sub    %eax,%ecx
  101f60:	89 c8                	mov    %ecx,%eax
  101f62:	89 44 24 08          	mov    %eax,0x8(%esp)
  101f66:	8d 45 de             	lea    0xffffffde(%ebp),%eax
  101f69:	89 44 24 04          	mov    %eax,0x4(%esp)
  101f6d:	8b 45 08             	mov    0x8(%ebp),%eax
  101f70:	89 04 24             	mov    %eax,(%esp)
  101f73:	e8 fb fd ff ff       	call   101d73 <putstr>
}
  101f78:	c9                   	leave  
  101f79:	c3                   	ret    

00101f7a <vprintfmt>:

#ifndef PIOS_KERNEL	// the kernel doesn't need or want floating-point
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

// Main function to format and print a string.
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  101f7a:	55                   	push   %ebp
  101f7b:	89 e5                	mov    %esp,%ebp
  101f7d:	57                   	push   %edi
  101f7e:	83 ec 54             	sub    $0x54,%esp
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
  101f81:	8d 7d c8             	lea    0xffffffc8(%ebp),%edi
  101f84:	fc                   	cld    
  101f85:	ba 00 00 00 00       	mov    $0x0,%edx
  101f8a:	b8 08 00 00 00       	mov    $0x8,%eax
  101f8f:	89 c1                	mov    %eax,%ecx
  101f91:	89 d0                	mov    %edx,%eax
  101f93:	f3 ab                	rep stos %eax,%es:(%edi)
  101f95:	8b 45 08             	mov    0x8(%ebp),%eax
  101f98:	89 45 c8             	mov    %eax,0xffffffc8(%ebp)
  101f9b:	8b 45 0c             	mov    0xc(%ebp),%eax
  101f9e:	89 45 cc             	mov    %eax,0xffffffcc(%ebp)
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  101fa1:	eb 1c                	jmp    101fbf <vprintfmt+0x45>
			if (ch == '\0')
  101fa3:	83 7d c4 00          	cmpl   $0x0,0xffffffc4(%ebp)
  101fa7:	0f 84 73 03 00 00    	je     102320 <vprintfmt+0x3a6>
				return;
			putch(ch, putdat);
  101fad:	8b 45 0c             	mov    0xc(%ebp),%eax
  101fb0:	89 44 24 04          	mov    %eax,0x4(%esp)
  101fb4:	8b 55 c4             	mov    0xffffffc4(%ebp),%edx
  101fb7:	89 14 24             	mov    %edx,(%esp)
  101fba:	8b 45 08             	mov    0x8(%ebp),%eax
  101fbd:	ff d0                	call   *%eax
  101fbf:	8b 45 10             	mov    0x10(%ebp),%eax
  101fc2:	0f b6 00             	movzbl (%eax),%eax
  101fc5:	0f b6 c0             	movzbl %al,%eax
  101fc8:	89 45 c4             	mov    %eax,0xffffffc4(%ebp)
  101fcb:	83 7d c4 25          	cmpl   $0x25,0xffffffc4(%ebp)
  101fcf:	0f 95 c0             	setne  %al
  101fd2:	83 45 10 01          	addl   $0x1,0x10(%ebp)
  101fd6:	84 c0                	test   %al,%al
  101fd8:	75 c9                	jne    101fa3 <vprintfmt+0x29>
		}

		// Process a %-escape sequence
		st.padc = ' ';
  101fda:	c7 45 d0 20 00 00 00 	movl   $0x20,0xffffffd0(%ebp)
		st.width = -1;
  101fe1:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,0xffffffd4(%ebp)
		st.prec = -1;
  101fe8:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,0xffffffd8(%ebp)
		st.signc = -1;
  101fef:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,0xffffffdc(%ebp)
		st.flags = 0;
  101ff6:	c7 45 e0 00 00 00 00 	movl   $0x0,0xffffffe0(%ebp)
		st.base = 10;
  101ffd:	c7 45 e4 0a 00 00 00 	movl   $0xa,0xffffffe4(%ebp)
  102004:	eb 00                	jmp    102006 <vprintfmt+0x8c>
		uintmax_t num;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  102006:	8b 45 10             	mov    0x10(%ebp),%eax
  102009:	0f b6 00             	movzbl (%eax),%eax
  10200c:	0f b6 c0             	movzbl %al,%eax
  10200f:	89 45 c4             	mov    %eax,0xffffffc4(%ebp)
  102012:	8b 45 c4             	mov    0xffffffc4(%ebp),%eax
  102015:	83 45 10 01          	addl   $0x1,0x10(%ebp)
  102019:	83 e8 20             	sub    $0x20,%eax
  10201c:	89 45 b8             	mov    %eax,0xffffffb8(%ebp)
  10201f:	83 7d b8 58          	cmpl   $0x58,0xffffffb8(%ebp)
  102023:	0f 87 c8 02 00 00    	ja     1022f1 <vprintfmt+0x377>
  102029:	8b 55 b8             	mov    0xffffffb8(%ebp),%edx
  10202c:	8b 04 95 04 34 10 00 	mov    0x103404(,%edx,4),%eax
  102033:	ff e0                	jmp    *%eax

		// modifier flags
		case '-': // pad on the right instead of the left
			st.flags |= F_RPAD;
  102035:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  102038:	83 c8 10             	or     $0x10,%eax
  10203b:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)
			goto reswitch;
  10203e:	eb c6                	jmp    102006 <vprintfmt+0x8c>

		case '+': // prefix positive numeric values with a '+' sign
			st.signc = '+';
  102040:	c7 45 dc 2b 00 00 00 	movl   $0x2b,0xffffffdc(%ebp)
			goto reswitch;
  102047:	eb bd                	jmp    102006 <vprintfmt+0x8c>

		case ' ': // prefix signless numeric values with a space
			if (st.signc < 0)	// (but only if no '+' is specified)
  102049:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  10204c:	85 c0                	test   %eax,%eax
  10204e:	79 b6                	jns    102006 <vprintfmt+0x8c>
				st.signc = ' ';
  102050:	c7 45 dc 20 00 00 00 	movl   $0x20,0xffffffdc(%ebp)
			goto reswitch;
  102057:	eb ad                	jmp    102006 <vprintfmt+0x8c>

		// width or precision field
		case '0':
			if (!(st.flags & F_DOT))
  102059:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  10205c:	83 e0 08             	and    $0x8,%eax
  10205f:	85 c0                	test   %eax,%eax
  102061:	75 07                	jne    10206a <vprintfmt+0xf0>
				st.padc = '0'; // pad with 0's instead of spaces
  102063:	c7 45 d0 30 00 00 00 	movl   $0x30,0xffffffd0(%ebp)
		case '1': case '2': case '3': case '4':
		case '5': case '6': case '7': case '8': case '9':
			for (st.prec = 0; ; ++fmt) {
  10206a:	c7 45 d8 00 00 00 00 	movl   $0x0,0xffffffd8(%ebp)
				st.prec = st.prec * 10 + ch - '0';
  102071:	8b 55 d8             	mov    0xffffffd8(%ebp),%edx
  102074:	89 d0                	mov    %edx,%eax
  102076:	c1 e0 02             	shl    $0x2,%eax
  102079:	01 d0                	add    %edx,%eax
  10207b:	01 c0                	add    %eax,%eax
  10207d:	03 45 c4             	add    0xffffffc4(%ebp),%eax
  102080:	83 e8 30             	sub    $0x30,%eax
  102083:	89 45 d8             	mov    %eax,0xffffffd8(%ebp)
				ch = *fmt;
  102086:	8b 45 10             	mov    0x10(%ebp),%eax
  102089:	0f b6 00             	movzbl (%eax),%eax
  10208c:	0f be c0             	movsbl %al,%eax
  10208f:	89 45 c4             	mov    %eax,0xffffffc4(%ebp)
				if (ch < '0' || ch > '9')
  102092:	83 7d c4 2f          	cmpl   $0x2f,0xffffffc4(%ebp)
  102096:	7e 20                	jle    1020b8 <vprintfmt+0x13e>
  102098:	83 7d c4 39          	cmpl   $0x39,0xffffffc4(%ebp)
  10209c:	7f 1a                	jg     1020b8 <vprintfmt+0x13e>
  10209e:	83 45 10 01          	addl   $0x1,0x10(%ebp)
					break;
			}
  1020a2:	eb cd                	jmp    102071 <vprintfmt+0xf7>
			goto gotprec;

		case '*':
			st.prec = va_arg(ap, int);
  1020a4:	8b 45 14             	mov    0x14(%ebp),%eax
  1020a7:	83 c0 04             	add    $0x4,%eax
  1020aa:	89 45 14             	mov    %eax,0x14(%ebp)
  1020ad:	8b 45 14             	mov    0x14(%ebp),%eax
  1020b0:	83 e8 04             	sub    $0x4,%eax
  1020b3:	8b 00                	mov    (%eax),%eax
  1020b5:	89 45 d8             	mov    %eax,0xffffffd8(%ebp)
		gotprec:
			if (!(st.flags & F_DOT)) {	// haven't seen a '.' yet?
  1020b8:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  1020bb:	83 e0 08             	and    $0x8,%eax
  1020be:	85 c0                	test   %eax,%eax
  1020c0:	0f 85 40 ff ff ff    	jne    102006 <vprintfmt+0x8c>
				st.width = st.prec;	// then it's a field width
  1020c6:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  1020c9:	89 45 d4             	mov    %eax,0xffffffd4(%ebp)
				st.prec = -1;
  1020cc:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,0xffffffd8(%ebp)
			}
			goto reswitch;
  1020d3:	e9 2e ff ff ff       	jmp    102006 <vprintfmt+0x8c>

		case '.':
			st.flags |= F_DOT;
  1020d8:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  1020db:	83 c8 08             	or     $0x8,%eax
  1020de:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)
			goto reswitch;
  1020e1:	e9 20 ff ff ff       	jmp    102006 <vprintfmt+0x8c>

		case '#':
			st.flags |= F_ALT;
  1020e6:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  1020e9:	83 c8 04             	or     $0x4,%eax
  1020ec:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)
			goto reswitch;
  1020ef:	e9 12 ff ff ff       	jmp    102006 <vprintfmt+0x8c>

		// long flag (doubled for long long)
		case 'l':
			st.flags |= (st.flags & F_L) ? F_LL : F_L;
  1020f4:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  1020f7:	89 45 bc             	mov    %eax,0xffffffbc(%ebp)
  1020fa:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  1020fd:	83 e0 01             	and    $0x1,%eax
  102100:	84 c0                	test   %al,%al
  102102:	74 09                	je     10210d <vprintfmt+0x193>
  102104:	c7 45 c0 02 00 00 00 	movl   $0x2,0xffffffc0(%ebp)
  10210b:	eb 07                	jmp    102114 <vprintfmt+0x19a>
  10210d:	c7 45 c0 01 00 00 00 	movl   $0x1,0xffffffc0(%ebp)
  102114:	8b 45 bc             	mov    0xffffffbc(%ebp),%eax
  102117:	0b 45 c0             	or     0xffffffc0(%ebp),%eax
  10211a:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)
			goto reswitch;
  10211d:	e9 e4 fe ff ff       	jmp    102006 <vprintfmt+0x8c>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  102122:	8b 45 14             	mov    0x14(%ebp),%eax
  102125:	83 c0 04             	add    $0x4,%eax
  102128:	89 45 14             	mov    %eax,0x14(%ebp)
  10212b:	8b 45 14             	mov    0x14(%ebp),%eax
  10212e:	83 e8 04             	sub    $0x4,%eax
  102131:	8b 10                	mov    (%eax),%edx
  102133:	8b 45 0c             	mov    0xc(%ebp),%eax
  102136:	89 44 24 04          	mov    %eax,0x4(%esp)
  10213a:	89 14 24             	mov    %edx,(%esp)
  10213d:	8b 45 08             	mov    0x8(%ebp),%eax
  102140:	ff d0                	call   *%eax
			break;
  102142:	e9 78 fe ff ff       	jmp    101fbf <vprintfmt+0x45>

		// string
		case 's': {
			const char *s;
			if ((s = va_arg(ap, char *)) == NULL)
  102147:	8b 45 14             	mov    0x14(%ebp),%eax
  10214a:	83 c0 04             	add    $0x4,%eax
  10214d:	89 45 14             	mov    %eax,0x14(%ebp)
  102150:	8b 45 14             	mov    0x14(%ebp),%eax
  102153:	83 e8 04             	sub    $0x4,%eax
  102156:	8b 00                	mov    (%eax),%eax
  102158:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
  10215b:	83 7d f4 00          	cmpl   $0x0,0xfffffff4(%ebp)
  10215f:	75 07                	jne    102168 <vprintfmt+0x1ee>
				s = "(null)";
  102161:	c7 45 f4 fd 33 10 00 	movl   $0x1033fd,0xfffffff4(%ebp)
			putstr(&st, s, st.prec);
  102168:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  10216b:	89 44 24 08          	mov    %eax,0x8(%esp)
  10216f:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  102172:	89 44 24 04          	mov    %eax,0x4(%esp)
  102176:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
  102179:	89 04 24             	mov    %eax,(%esp)
  10217c:	e8 f2 fb ff ff       	call   101d73 <putstr>
			break;
  102181:	e9 39 fe ff ff       	jmp    101fbf <vprintfmt+0x45>
		    }

		// (signed) decimal
		case 'd':
			num = getint(&st, &ap);
  102186:	8d 45 14             	lea    0x14(%ebp),%eax
  102189:	89 44 24 04          	mov    %eax,0x4(%esp)
  10218d:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
  102190:	89 04 24             	mov    %eax,(%esp)
  102193:	e8 0e fb ff ff       	call   101ca6 <getint>
  102198:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  10219b:	89 55 ec             	mov    %edx,0xffffffec(%ebp)
			if ((intmax_t) num < 0) {
  10219e:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  1021a1:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
  1021a4:	85 d2                	test   %edx,%edx
  1021a6:	79 1a                	jns    1021c2 <vprintfmt+0x248>
				num = -(intmax_t) num;
  1021a8:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  1021ab:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
  1021ae:	f7 d8                	neg    %eax
  1021b0:	83 d2 00             	adc    $0x0,%edx
  1021b3:	f7 da                	neg    %edx
  1021b5:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  1021b8:	89 55 ec             	mov    %edx,0xffffffec(%ebp)
				st.signc = '-';
  1021bb:	c7 45 dc 2d 00 00 00 	movl   $0x2d,0xffffffdc(%ebp)
			}
			putint(&st, num, 10);
  1021c2:	c7 44 24 0c 0a 00 00 	movl   $0xa,0xc(%esp)
  1021c9:	00 
  1021ca:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  1021cd:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
  1021d0:	89 44 24 04          	mov    %eax,0x4(%esp)
  1021d4:	89 54 24 08          	mov    %edx,0x8(%esp)
  1021d8:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
  1021db:	89 04 24             	mov    %eax,(%esp)
  1021de:	e8 2f fd ff ff       	call   101f12 <putint>
			break;
  1021e3:	e9 d7 fd ff ff       	jmp    101fbf <vprintfmt+0x45>

		// unsigned decimal
		case 'u':
			putint(&st, getuint(&st, &ap), 10);
  1021e8:	8d 45 14             	lea    0x14(%ebp),%eax
  1021eb:	89 44 24 04          	mov    %eax,0x4(%esp)
  1021ef:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
  1021f2:	89 04 24             	mov    %eax,(%esp)
  1021f5:	e8 1e fa ff ff       	call   101c18 <getuint>
  1021fa:	c7 44 24 0c 0a 00 00 	movl   $0xa,0xc(%esp)
  102201:	00 
  102202:	89 44 24 04          	mov    %eax,0x4(%esp)
  102206:	89 54 24 08          	mov    %edx,0x8(%esp)
  10220a:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
  10220d:	89 04 24             	mov    %eax,(%esp)
  102210:	e8 fd fc ff ff       	call   101f12 <putint>
			break;
  102215:	e9 a5 fd ff ff       	jmp    101fbf <vprintfmt+0x45>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putint(&st, getuint(&st, &ap), 8);
  10221a:	8d 45 14             	lea    0x14(%ebp),%eax
  10221d:	89 44 24 04          	mov    %eax,0x4(%esp)
  102221:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
  102224:	89 04 24             	mov    %eax,(%esp)
  102227:	e8 ec f9 ff ff       	call   101c18 <getuint>
  10222c:	c7 44 24 0c 08 00 00 	movl   $0x8,0xc(%esp)
  102233:	00 
  102234:	89 44 24 04          	mov    %eax,0x4(%esp)
  102238:	89 54 24 08          	mov    %edx,0x8(%esp)
  10223c:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
  10223f:	89 04 24             	mov    %eax,(%esp)
  102242:	e8 cb fc ff ff       	call   101f12 <putint>
			break;
  102247:	e9 73 fd ff ff       	jmp    101fbf <vprintfmt+0x45>

		// (unsigned) hexadecimal
		case 'x':
			putint(&st, getuint(&st, &ap), 16);
  10224c:	8d 45 14             	lea    0x14(%ebp),%eax
  10224f:	89 44 24 04          	mov    %eax,0x4(%esp)
  102253:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
  102256:	89 04 24             	mov    %eax,(%esp)
  102259:	e8 ba f9 ff ff       	call   101c18 <getuint>
  10225e:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
  102265:	00 
  102266:	89 44 24 04          	mov    %eax,0x4(%esp)
  10226a:	89 54 24 08          	mov    %edx,0x8(%esp)
  10226e:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
  102271:	89 04 24             	mov    %eax,(%esp)
  102274:	e8 99 fc ff ff       	call   101f12 <putint>
			break;
  102279:	e9 41 fd ff ff       	jmp    101fbf <vprintfmt+0x45>

		// pointer
		case 'p':
			putch('0', putdat);
  10227e:	8b 45 0c             	mov    0xc(%ebp),%eax
  102281:	89 44 24 04          	mov    %eax,0x4(%esp)
  102285:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  10228c:	8b 45 08             	mov    0x8(%ebp),%eax
  10228f:	ff d0                	call   *%eax
			putch('x', putdat);
  102291:	8b 45 0c             	mov    0xc(%ebp),%eax
  102294:	89 44 24 04          	mov    %eax,0x4(%esp)
  102298:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  10229f:	8b 45 08             	mov    0x8(%ebp),%eax
  1022a2:	ff d0                	call   *%eax
			putint(&st, (uintptr_t) va_arg(ap, void *), 16);
  1022a4:	8b 45 14             	mov    0x14(%ebp),%eax
  1022a7:	83 c0 04             	add    $0x4,%eax
  1022aa:	89 45 14             	mov    %eax,0x14(%ebp)
  1022ad:	8b 45 14             	mov    0x14(%ebp),%eax
  1022b0:	83 e8 04             	sub    $0x4,%eax
  1022b3:	8b 00                	mov    (%eax),%eax
  1022b5:	ba 00 00 00 00       	mov    $0x0,%edx
  1022ba:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
  1022c1:	00 
  1022c2:	89 44 24 04          	mov    %eax,0x4(%esp)
  1022c6:	89 54 24 08          	mov    %edx,0x8(%esp)
  1022ca:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
  1022cd:	89 04 24             	mov    %eax,(%esp)
  1022d0:	e8 3d fc ff ff       	call   101f12 <putint>
			break;
  1022d5:	e9 e5 fc ff ff       	jmp    101fbf <vprintfmt+0x45>

#ifndef PIOS_KERNEL
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
#endif	// ! PIOS_KERNEL

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  1022da:	8b 45 0c             	mov    0xc(%ebp),%eax
  1022dd:	89 44 24 04          	mov    %eax,0x4(%esp)
  1022e1:	8b 55 c4             	mov    0xffffffc4(%ebp),%edx
  1022e4:	89 14 24             	mov    %edx,(%esp)
  1022e7:	8b 45 08             	mov    0x8(%ebp),%eax
  1022ea:	ff d0                	call   *%eax
			break;
  1022ec:	e9 ce fc ff ff       	jmp    101fbf <vprintfmt+0x45>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  1022f1:	8b 45 0c             	mov    0xc(%ebp),%eax
  1022f4:	89 44 24 04          	mov    %eax,0x4(%esp)
  1022f8:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  1022ff:	8b 45 08             	mov    0x8(%ebp),%eax
  102302:	ff d0                	call   *%eax
			for (fmt--; fmt[-1] != '%'; fmt--)
  102304:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  102308:	eb 04                	jmp    10230e <vprintfmt+0x394>
  10230a:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  10230e:	8b 45 10             	mov    0x10(%ebp),%eax
  102311:	83 e8 01             	sub    $0x1,%eax
  102314:	0f b6 00             	movzbl (%eax),%eax
  102317:	3c 25                	cmp    $0x25,%al
  102319:	75 ef                	jne    10230a <vprintfmt+0x390>
				/* do nothing */;
			break;
		}
	}
  10231b:	e9 9f fc ff ff       	jmp    101fbf <vprintfmt+0x45>
}
  102320:	83 c4 54             	add    $0x54,%esp
  102323:	5f                   	pop    %edi
  102324:	5d                   	pop    %ebp
  102325:	c3                   	ret    
  102326:	90                   	nop    
  102327:	90                   	nop    

00102328 <putch>:


static void
putch(int ch, struct printbuf *b)
{
  102328:	55                   	push   %ebp
  102329:	89 e5                	mov    %esp,%ebp
  10232b:	83 ec 08             	sub    $0x8,%esp
	b->buf[b->idx++] = ch; // idx returns current value, not incremented value
  10232e:	8b 45 0c             	mov    0xc(%ebp),%eax
  102331:	8b 08                	mov    (%eax),%ecx
  102333:	8b 45 08             	mov    0x8(%ebp),%eax
  102336:	89 c2                	mov    %eax,%edx
  102338:	8b 45 0c             	mov    0xc(%ebp),%eax
  10233b:	88 54 08 08          	mov    %dl,0x8(%eax,%ecx,1)
  10233f:	8d 51 01             	lea    0x1(%ecx),%edx
  102342:	8b 45 0c             	mov    0xc(%ebp),%eax
  102345:	89 10                	mov    %edx,(%eax)
	if (b->idx == CPUTS_MAX-1) {
  102347:	8b 45 0c             	mov    0xc(%ebp),%eax
  10234a:	8b 00                	mov    (%eax),%eax
  10234c:	3d ff 00 00 00       	cmp    $0xff,%eax
  102351:	75 24                	jne    102377 <putch+0x4f>
		b->buf[b->idx] = 0;
  102353:	8b 45 0c             	mov    0xc(%ebp),%eax
  102356:	8b 10                	mov    (%eax),%edx
  102358:	8b 45 0c             	mov    0xc(%ebp),%eax
  10235b:	c6 44 10 08 00       	movb   $0x0,0x8(%eax,%edx,1)
		cputs(b->buf);
  102360:	8b 45 0c             	mov    0xc(%ebp),%eax
  102363:	83 c0 08             	add    $0x8,%eax
  102366:	89 04 24             	mov    %eax,(%esp)
  102369:	e8 9b df ff ff       	call   100309 <cputs>
		b->idx = 0;
  10236e:	8b 45 0c             	mov    0xc(%ebp),%eax
  102371:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	}
	b->cnt++;
  102377:	8b 45 0c             	mov    0xc(%ebp),%eax
  10237a:	8b 40 04             	mov    0x4(%eax),%eax
  10237d:	8d 50 01             	lea    0x1(%eax),%edx
  102380:	8b 45 0c             	mov    0xc(%ebp),%eax
  102383:	89 50 04             	mov    %edx,0x4(%eax)
}
  102386:	c9                   	leave  
  102387:	c3                   	ret    

00102388 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  102388:	55                   	push   %ebp
  102389:	89 e5                	mov    %esp,%ebp
  10238b:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  102391:	c7 85 f8 fe ff ff 00 	movl   $0x0,0xfffffef8(%ebp)
  102398:	00 00 00 
	b.cnt = 0;
  10239b:	c7 85 fc fe ff ff 00 	movl   $0x0,0xfffffefc(%ebp)
  1023a2:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  1023a5:	ba 28 23 10 00       	mov    $0x102328,%edx
  1023aa:	8b 45 0c             	mov    0xc(%ebp),%eax
  1023ad:	89 44 24 0c          	mov    %eax,0xc(%esp)
  1023b1:	8b 45 08             	mov    0x8(%ebp),%eax
  1023b4:	89 44 24 08          	mov    %eax,0x8(%esp)
  1023b8:	8d 85 f8 fe ff ff    	lea    0xfffffef8(%ebp),%eax
  1023be:	89 44 24 04          	mov    %eax,0x4(%esp)
  1023c2:	89 14 24             	mov    %edx,(%esp)
  1023c5:	e8 b0 fb ff ff       	call   101f7a <vprintfmt>

	b.buf[b.idx] = 0;
  1023ca:	8b 85 f8 fe ff ff    	mov    0xfffffef8(%ebp),%eax
  1023d0:	c6 84 05 00 ff ff ff 	movb   $0x0,0xffffff00(%ebp,%eax,1)
  1023d7:	00 
	cputs(b.buf);
  1023d8:	8d 85 f8 fe ff ff    	lea    0xfffffef8(%ebp),%eax
  1023de:	83 c0 08             	add    $0x8,%eax
  1023e1:	89 04 24             	mov    %eax,(%esp)
  1023e4:	e8 20 df ff ff       	call   100309 <cputs>

	return b.cnt;
  1023e9:	8b 85 fc fe ff ff    	mov    0xfffffefc(%ebp),%eax
}
  1023ef:	c9                   	leave  
  1023f0:	c3                   	ret    

001023f1 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  1023f1:	55                   	push   %ebp
  1023f2:	89 e5                	mov    %esp,%ebp
  1023f4:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  1023f7:	8d 45 08             	lea    0x8(%ebp),%eax
  1023fa:	83 c0 04             	add    $0x4,%eax
  1023fd:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
	cnt = vcprintf(fmt, ap);
  102400:	8b 55 08             	mov    0x8(%ebp),%edx
  102403:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  102406:	89 44 24 04          	mov    %eax,0x4(%esp)
  10240a:	89 14 24             	mov    %edx,(%esp)
  10240d:	e8 76 ff ff ff       	call   102388 <vcprintf>
  102412:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	va_end(ap);

	return cnt;
  102415:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
}
  102418:	c9                   	leave  
  102419:	c3                   	ret    
  10241a:	90                   	nop    
  10241b:	90                   	nop    

0010241c <strlen>:
#define ASM 1

int
strlen(const char *s)
{
  10241c:	55                   	push   %ebp
  10241d:	89 e5                	mov    %esp,%ebp
  10241f:	83 ec 10             	sub    $0x10,%esp
	int n;

	for (n = 0; *s != '\0'; s++)
  102422:	c7 45 fc 00 00 00 00 	movl   $0x0,0xfffffffc(%ebp)
  102429:	eb 08                	jmp    102433 <strlen+0x17>
		n++;
  10242b:	83 45 fc 01          	addl   $0x1,0xfffffffc(%ebp)
  10242f:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  102433:	8b 45 08             	mov    0x8(%ebp),%eax
  102436:	0f b6 00             	movzbl (%eax),%eax
  102439:	84 c0                	test   %al,%al
  10243b:	75 ee                	jne    10242b <strlen+0xf>
	return n;
  10243d:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
}
  102440:	c9                   	leave  
  102441:	c3                   	ret    

00102442 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  102442:	55                   	push   %ebp
  102443:	89 e5                	mov    %esp,%ebp
  102445:	83 ec 10             	sub    $0x10,%esp
	char *ret;

	ret = dst;
  102448:	8b 45 08             	mov    0x8(%ebp),%eax
  10244b:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	while ((*dst++ = *src++) != '\0')
  10244e:	8b 45 0c             	mov    0xc(%ebp),%eax
  102451:	0f b6 10             	movzbl (%eax),%edx
  102454:	8b 45 08             	mov    0x8(%ebp),%eax
  102457:	88 10                	mov    %dl,(%eax)
  102459:	8b 45 08             	mov    0x8(%ebp),%eax
  10245c:	0f b6 00             	movzbl (%eax),%eax
  10245f:	84 c0                	test   %al,%al
  102461:	0f 95 c0             	setne  %al
  102464:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  102468:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
  10246c:	84 c0                	test   %al,%al
  10246e:	75 de                	jne    10244e <strcpy+0xc>
		/* do nothing */;
	return ret;
  102470:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
}
  102473:	c9                   	leave  
  102474:	c3                   	ret    

00102475 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size)
{
  102475:	55                   	push   %ebp
  102476:	89 e5                	mov    %esp,%ebp
  102478:	83 ec 10             	sub    $0x10,%esp
	size_t i;
	char *ret;

	ret = dst;
  10247b:	8b 45 08             	mov    0x8(%ebp),%eax
  10247e:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	for (i = 0; i < size; i++) {
  102481:	c7 45 f8 00 00 00 00 	movl   $0x0,0xfffffff8(%ebp)
  102488:	eb 21                	jmp    1024ab <strncpy+0x36>
		*dst++ = *src;
  10248a:	8b 45 0c             	mov    0xc(%ebp),%eax
  10248d:	0f b6 10             	movzbl (%eax),%edx
  102490:	8b 45 08             	mov    0x8(%ebp),%eax
  102493:	88 10                	mov    %dl,(%eax)
  102495:	83 45 08 01          	addl   $0x1,0x8(%ebp)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
  102499:	8b 45 0c             	mov    0xc(%ebp),%eax
  10249c:	0f b6 00             	movzbl (%eax),%eax
  10249f:	84 c0                	test   %al,%al
  1024a1:	74 04                	je     1024a7 <strncpy+0x32>
			src++;
  1024a3:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
  1024a7:	83 45 f8 01          	addl   $0x1,0xfffffff8(%ebp)
  1024ab:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1024ae:	3b 45 10             	cmp    0x10(%ebp),%eax
  1024b1:	72 d7                	jb     10248a <strncpy+0x15>
	}
	return ret;
  1024b3:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
}
  1024b6:	c9                   	leave  
  1024b7:	c3                   	ret    

001024b8 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  1024b8:	55                   	push   %ebp
  1024b9:	89 e5                	mov    %esp,%ebp
  1024bb:	83 ec 10             	sub    $0x10,%esp
	char *dst_in;

	dst_in = dst;
  1024be:	8b 45 08             	mov    0x8(%ebp),%eax
  1024c1:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	if (size > 0) {
  1024c4:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  1024c8:	74 2f                	je     1024f9 <strlcpy+0x41>
		while (--size > 0 && *src != '\0')
  1024ca:	eb 13                	jmp    1024df <strlcpy+0x27>
			*dst++ = *src++;
  1024cc:	8b 45 0c             	mov    0xc(%ebp),%eax
  1024cf:	0f b6 10             	movzbl (%eax),%edx
  1024d2:	8b 45 08             	mov    0x8(%ebp),%eax
  1024d5:	88 10                	mov    %dl,(%eax)
  1024d7:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  1024db:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
  1024df:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  1024e3:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  1024e7:	74 0a                	je     1024f3 <strlcpy+0x3b>
  1024e9:	8b 45 0c             	mov    0xc(%ebp),%eax
  1024ec:	0f b6 00             	movzbl (%eax),%eax
  1024ef:	84 c0                	test   %al,%al
  1024f1:	75 d9                	jne    1024cc <strlcpy+0x14>
		*dst = '\0';
  1024f3:	8b 45 08             	mov    0x8(%ebp),%eax
  1024f6:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  1024f9:	8b 55 08             	mov    0x8(%ebp),%edx
  1024fc:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  1024ff:	89 d1                	mov    %edx,%ecx
  102501:	29 c1                	sub    %eax,%ecx
  102503:	89 c8                	mov    %ecx,%eax
}
  102505:	c9                   	leave  
  102506:	c3                   	ret    

00102507 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  102507:	55                   	push   %ebp
  102508:	89 e5                	mov    %esp,%ebp
	while (*p && *p == *q)
  10250a:	eb 08                	jmp    102514 <strcmp+0xd>
		p++, q++;
  10250c:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  102510:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
  102514:	8b 45 08             	mov    0x8(%ebp),%eax
  102517:	0f b6 00             	movzbl (%eax),%eax
  10251a:	84 c0                	test   %al,%al
  10251c:	74 10                	je     10252e <strcmp+0x27>
  10251e:	8b 45 08             	mov    0x8(%ebp),%eax
  102521:	0f b6 10             	movzbl (%eax),%edx
  102524:	8b 45 0c             	mov    0xc(%ebp),%eax
  102527:	0f b6 00             	movzbl (%eax),%eax
  10252a:	38 c2                	cmp    %al,%dl
  10252c:	74 de                	je     10250c <strcmp+0x5>
	return (int) ((unsigned char) *p - (unsigned char) *q);
  10252e:	8b 45 08             	mov    0x8(%ebp),%eax
  102531:	0f b6 00             	movzbl (%eax),%eax
  102534:	0f b6 d0             	movzbl %al,%edx
  102537:	8b 45 0c             	mov    0xc(%ebp),%eax
  10253a:	0f b6 00             	movzbl (%eax),%eax
  10253d:	0f b6 c0             	movzbl %al,%eax
  102540:	89 d1                	mov    %edx,%ecx
  102542:	29 c1                	sub    %eax,%ecx
  102544:	89 c8                	mov    %ecx,%eax
}
  102546:	5d                   	pop    %ebp
  102547:	c3                   	ret    

00102548 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  102548:	55                   	push   %ebp
  102549:	89 e5                	mov    %esp,%ebp
  10254b:	83 ec 04             	sub    $0x4,%esp
	while (n > 0 && *p && *p == *q)
  10254e:	eb 0c                	jmp    10255c <strncmp+0x14>
		n--, p++, q++;
  102550:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  102554:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  102558:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
  10255c:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  102560:	74 1a                	je     10257c <strncmp+0x34>
  102562:	8b 45 08             	mov    0x8(%ebp),%eax
  102565:	0f b6 00             	movzbl (%eax),%eax
  102568:	84 c0                	test   %al,%al
  10256a:	74 10                	je     10257c <strncmp+0x34>
  10256c:	8b 45 08             	mov    0x8(%ebp),%eax
  10256f:	0f b6 10             	movzbl (%eax),%edx
  102572:	8b 45 0c             	mov    0xc(%ebp),%eax
  102575:	0f b6 00             	movzbl (%eax),%eax
  102578:	38 c2                	cmp    %al,%dl
  10257a:	74 d4                	je     102550 <strncmp+0x8>
	if (n == 0)
  10257c:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  102580:	75 09                	jne    10258b <strncmp+0x43>
		return 0;
  102582:	c7 45 fc 00 00 00 00 	movl   $0x0,0xfffffffc(%ebp)
  102589:	eb 19                	jmp    1025a4 <strncmp+0x5c>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  10258b:	8b 45 08             	mov    0x8(%ebp),%eax
  10258e:	0f b6 00             	movzbl (%eax),%eax
  102591:	0f b6 d0             	movzbl %al,%edx
  102594:	8b 45 0c             	mov    0xc(%ebp),%eax
  102597:	0f b6 00             	movzbl (%eax),%eax
  10259a:	0f b6 c0             	movzbl %al,%eax
  10259d:	89 d1                	mov    %edx,%ecx
  10259f:	29 c1                	sub    %eax,%ecx
  1025a1:	89 4d fc             	mov    %ecx,0xfffffffc(%ebp)
  1025a4:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
}
  1025a7:	c9                   	leave  
  1025a8:	c3                   	ret    

001025a9 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  1025a9:	55                   	push   %ebp
  1025aa:	89 e5                	mov    %esp,%ebp
  1025ac:	83 ec 08             	sub    $0x8,%esp
  1025af:	8b 45 0c             	mov    0xc(%ebp),%eax
  1025b2:	88 45 fc             	mov    %al,0xfffffffc(%ebp)
	while (*s != c)
  1025b5:	eb 1c                	jmp    1025d3 <strchr+0x2a>
		if (*s++ == 0)
  1025b7:	8b 45 08             	mov    0x8(%ebp),%eax
  1025ba:	0f b6 00             	movzbl (%eax),%eax
  1025bd:	84 c0                	test   %al,%al
  1025bf:	0f 94 c0             	sete   %al
  1025c2:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  1025c6:	84 c0                	test   %al,%al
  1025c8:	74 09                	je     1025d3 <strchr+0x2a>
			return NULL;
  1025ca:	c7 45 f8 00 00 00 00 	movl   $0x0,0xfffffff8(%ebp)
  1025d1:	eb 11                	jmp    1025e4 <strchr+0x3b>
  1025d3:	8b 45 08             	mov    0x8(%ebp),%eax
  1025d6:	0f b6 00             	movzbl (%eax),%eax
  1025d9:	3a 45 fc             	cmp    0xfffffffc(%ebp),%al
  1025dc:	75 d9                	jne    1025b7 <strchr+0xe>
	return (char *) s;
  1025de:	8b 45 08             	mov    0x8(%ebp),%eax
  1025e1:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  1025e4:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
}
  1025e7:	c9                   	leave  
  1025e8:	c3                   	ret    

001025e9 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  1025e9:	55                   	push   %ebp
  1025ea:	89 e5                	mov    %esp,%ebp
  1025ec:	57                   	push   %edi
  1025ed:	83 ec 14             	sub    $0x14,%esp
	char *p;

	if (n == 0)
  1025f0:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  1025f4:	75 08                	jne    1025fe <memset+0x15>
		return v;
  1025f6:	8b 45 08             	mov    0x8(%ebp),%eax
  1025f9:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  1025fc:	eb 5b                	jmp    102659 <memset+0x70>
	if ((int)v%4 == 0 && n%4 == 0) {
  1025fe:	8b 45 08             	mov    0x8(%ebp),%eax
  102601:	83 e0 03             	and    $0x3,%eax
  102604:	85 c0                	test   %eax,%eax
  102606:	75 3f                	jne    102647 <memset+0x5e>
  102608:	8b 45 10             	mov    0x10(%ebp),%eax
  10260b:	83 e0 03             	and    $0x3,%eax
  10260e:	85 c0                	test   %eax,%eax
  102610:	75 35                	jne    102647 <memset+0x5e>
		c &= 0xFF;
  102612:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
		c = (c<<24)|(c<<16)|(c<<8)|c;
  102619:	8b 45 0c             	mov    0xc(%ebp),%eax
  10261c:	89 c2                	mov    %eax,%edx
  10261e:	c1 e2 18             	shl    $0x18,%edx
  102621:	8b 45 0c             	mov    0xc(%ebp),%eax
  102624:	c1 e0 10             	shl    $0x10,%eax
  102627:	09 c2                	or     %eax,%edx
  102629:	8b 45 0c             	mov    0xc(%ebp),%eax
  10262c:	c1 e0 08             	shl    $0x8,%eax
  10262f:	09 d0                	or     %edx,%eax
  102631:	09 45 0c             	or     %eax,0xc(%ebp)
		asm volatile("cld; rep stosl\n"
  102634:	8b 45 10             	mov    0x10(%ebp),%eax
  102637:	89 c1                	mov    %eax,%ecx
  102639:	c1 e9 02             	shr    $0x2,%ecx
  10263c:	8b 7d 08             	mov    0x8(%ebp),%edi
  10263f:	8b 45 0c             	mov    0xc(%ebp),%eax
  102642:	fc                   	cld    
  102643:	f3 ab                	rep stos %eax,%es:(%edi)
  102645:	eb 0c                	jmp    102653 <memset+0x6a>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  102647:	8b 7d 08             	mov    0x8(%ebp),%edi
  10264a:	8b 45 0c             	mov    0xc(%ebp),%eax
  10264d:	8b 4d 10             	mov    0x10(%ebp),%ecx
  102650:	fc                   	cld    
  102651:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
  102653:	8b 45 08             	mov    0x8(%ebp),%eax
  102656:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  102659:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
}
  10265c:	83 c4 14             	add    $0x14,%esp
  10265f:	5f                   	pop    %edi
  102660:	5d                   	pop    %ebp
  102661:	c3                   	ret    

00102662 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  102662:	55                   	push   %ebp
  102663:	89 e5                	mov    %esp,%ebp
  102665:	57                   	push   %edi
  102666:	56                   	push   %esi
  102667:	83 ec 10             	sub    $0x10,%esp
	const char *s;
	char *d;
	
	s = src;
  10266a:	8b 45 0c             	mov    0xc(%ebp),%eax
  10266d:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
	d = dst;
  102670:	8b 45 08             	mov    0x8(%ebp),%eax
  102673:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	if (s < d && s + n > d) {
  102676:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  102679:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  10267c:	73 63                	jae    1026e1 <memmove+0x7f>
  10267e:	8b 45 10             	mov    0x10(%ebp),%eax
  102681:	03 45 f0             	add    0xfffffff0(%ebp),%eax
  102684:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  102687:	76 58                	jbe    1026e1 <memmove+0x7f>
		s += n;
  102689:	8b 45 10             	mov    0x10(%ebp),%eax
  10268c:	01 45 f0             	add    %eax,0xfffffff0(%ebp)
		d += n;
  10268f:	8b 45 10             	mov    0x10(%ebp),%eax
  102692:	01 45 f4             	add    %eax,0xfffffff4(%ebp)
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  102695:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  102698:	83 e0 03             	and    $0x3,%eax
  10269b:	85 c0                	test   %eax,%eax
  10269d:	75 2d                	jne    1026cc <memmove+0x6a>
  10269f:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  1026a2:	83 e0 03             	and    $0x3,%eax
  1026a5:	85 c0                	test   %eax,%eax
  1026a7:	75 23                	jne    1026cc <memmove+0x6a>
  1026a9:	8b 45 10             	mov    0x10(%ebp),%eax
  1026ac:	83 e0 03             	and    $0x3,%eax
  1026af:	85 c0                	test   %eax,%eax
  1026b1:	75 19                	jne    1026cc <memmove+0x6a>
			asm volatile("std; rep movsl\n"
  1026b3:	8b 7d f4             	mov    0xfffffff4(%ebp),%edi
  1026b6:	83 ef 04             	sub    $0x4,%edi
  1026b9:	8b 75 f0             	mov    0xfffffff0(%ebp),%esi
  1026bc:	83 ee 04             	sub    $0x4,%esi
  1026bf:	8b 45 10             	mov    0x10(%ebp),%eax
  1026c2:	89 c1                	mov    %eax,%ecx
  1026c4:	c1 e9 02             	shr    $0x2,%ecx
  1026c7:	fd                   	std    
  1026c8:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  1026ca:	eb 12                	jmp    1026de <memmove+0x7c>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  1026cc:	8b 7d f4             	mov    0xfffffff4(%ebp),%edi
  1026cf:	83 ef 01             	sub    $0x1,%edi
  1026d2:	8b 75 f0             	mov    0xfffffff0(%ebp),%esi
  1026d5:	83 ee 01             	sub    $0x1,%esi
  1026d8:	8b 4d 10             	mov    0x10(%ebp),%ecx
  1026db:	fd                   	std    
  1026dc:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  1026de:	fc                   	cld    
  1026df:	eb 3d                	jmp    10271e <memmove+0xbc>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  1026e1:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  1026e4:	83 e0 03             	and    $0x3,%eax
  1026e7:	85 c0                	test   %eax,%eax
  1026e9:	75 27                	jne    102712 <memmove+0xb0>
  1026eb:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  1026ee:	83 e0 03             	and    $0x3,%eax
  1026f1:	85 c0                	test   %eax,%eax
  1026f3:	75 1d                	jne    102712 <memmove+0xb0>
  1026f5:	8b 45 10             	mov    0x10(%ebp),%eax
  1026f8:	83 e0 03             	and    $0x3,%eax
  1026fb:	85 c0                	test   %eax,%eax
  1026fd:	75 13                	jne    102712 <memmove+0xb0>
			asm volatile("cld; rep movsl\n"
  1026ff:	8b 45 10             	mov    0x10(%ebp),%eax
  102702:	89 c1                	mov    %eax,%ecx
  102704:	c1 e9 02             	shr    $0x2,%ecx
  102707:	8b 7d f4             	mov    0xfffffff4(%ebp),%edi
  10270a:	8b 75 f0             	mov    0xfffffff0(%ebp),%esi
  10270d:	fc                   	cld    
  10270e:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  102710:	eb 0c                	jmp    10271e <memmove+0xbc>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  102712:	8b 7d f4             	mov    0xfffffff4(%ebp),%edi
  102715:	8b 75 f0             	mov    0xfffffff0(%ebp),%esi
  102718:	8b 4d 10             	mov    0x10(%ebp),%ecx
  10271b:	fc                   	cld    
  10271c:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
  10271e:	8b 45 08             	mov    0x8(%ebp),%eax
}
  102721:	83 c4 10             	add    $0x10,%esp
  102724:	5e                   	pop    %esi
  102725:	5f                   	pop    %edi
  102726:	5d                   	pop    %ebp
  102727:	c3                   	ret    

00102728 <memcpy>:

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
  102728:	55                   	push   %ebp
  102729:	89 e5                	mov    %esp,%ebp
  10272b:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
  10272e:	8b 45 10             	mov    0x10(%ebp),%eax
  102731:	89 44 24 08          	mov    %eax,0x8(%esp)
  102735:	8b 45 0c             	mov    0xc(%ebp),%eax
  102738:	89 44 24 04          	mov    %eax,0x4(%esp)
  10273c:	8b 45 08             	mov    0x8(%ebp),%eax
  10273f:	89 04 24             	mov    %eax,(%esp)
  102742:	e8 1b ff ff ff       	call   102662 <memmove>
}
  102747:	c9                   	leave  
  102748:	c3                   	ret    

00102749 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  102749:	55                   	push   %ebp
  10274a:	89 e5                	mov    %esp,%ebp
  10274c:	83 ec 14             	sub    $0x14,%esp
	const uint8_t *s1 = (const uint8_t *) v1;
  10274f:	8b 45 08             	mov    0x8(%ebp),%eax
  102752:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
	const uint8_t *s2 = (const uint8_t *) v2;
  102755:	8b 45 0c             	mov    0xc(%ebp),%eax
  102758:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)

	while (n-- > 0) {
  10275b:	eb 33                	jmp    102790 <memcmp+0x47>
		if (*s1 != *s2)
  10275d:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  102760:	0f b6 10             	movzbl (%eax),%edx
  102763:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  102766:	0f b6 00             	movzbl (%eax),%eax
  102769:	38 c2                	cmp    %al,%dl
  10276b:	74 1b                	je     102788 <memcmp+0x3f>
			return (int) *s1 - (int) *s2;
  10276d:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  102770:	0f b6 00             	movzbl (%eax),%eax
  102773:	0f b6 d0             	movzbl %al,%edx
  102776:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  102779:	0f b6 00             	movzbl (%eax),%eax
  10277c:	0f b6 c0             	movzbl %al,%eax
  10277f:	89 d1                	mov    %edx,%ecx
  102781:	29 c1                	sub    %eax,%ecx
  102783:	89 4d ec             	mov    %ecx,0xffffffec(%ebp)
  102786:	eb 19                	jmp    1027a1 <memcmp+0x58>
		s1++, s2++;
  102788:	83 45 f8 01          	addl   $0x1,0xfffffff8(%ebp)
  10278c:	83 45 fc 01          	addl   $0x1,0xfffffffc(%ebp)
  102790:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  102794:	83 7d 10 ff          	cmpl   $0xffffffff,0x10(%ebp)
  102798:	75 c3                	jne    10275d <memcmp+0x14>
	}

	return 0;
  10279a:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  1027a1:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
}
  1027a4:	c9                   	leave  
  1027a5:	c3                   	ret    

001027a6 <memchr>:

void *
memchr(const void *s, int c, size_t n)
{
  1027a6:	55                   	push   %ebp
  1027a7:	89 e5                	mov    %esp,%ebp
  1027a9:	83 ec 14             	sub    $0x14,%esp
	const void *ends = (const char *) s + n;
  1027ac:	8b 45 08             	mov    0x8(%ebp),%eax
  1027af:	8b 55 10             	mov    0x10(%ebp),%edx
  1027b2:	01 d0                	add    %edx,%eax
  1027b4:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	for (; s < ends; s++)
  1027b7:	eb 19                	jmp    1027d2 <memchr+0x2c>
		if (*(const unsigned char *) s == (unsigned char) c)
  1027b9:	8b 45 08             	mov    0x8(%ebp),%eax
  1027bc:	0f b6 10             	movzbl (%eax),%edx
  1027bf:	8b 45 0c             	mov    0xc(%ebp),%eax
  1027c2:	38 c2                	cmp    %al,%dl
  1027c4:	75 08                	jne    1027ce <memchr+0x28>
			return (void *) s;
  1027c6:	8b 45 08             	mov    0x8(%ebp),%eax
  1027c9:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  1027cc:	eb 13                	jmp    1027e1 <memchr+0x3b>
  1027ce:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  1027d2:	8b 45 08             	mov    0x8(%ebp),%eax
  1027d5:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  1027d8:	72 df                	jb     1027b9 <memchr+0x13>
	return NULL;
  1027da:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  1027e1:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
}
  1027e4:	c9                   	leave  
  1027e5:	c3                   	ret    
  1027e6:	90                   	nop    
  1027e7:	90                   	nop    
  1027e8:	90                   	nop    
  1027e9:	90                   	nop    
  1027ea:	90                   	nop    
  1027eb:	90                   	nop    
  1027ec:	90                   	nop    
  1027ed:	90                   	nop    
  1027ee:	90                   	nop    
  1027ef:	90                   	nop    

001027f0 <__udivdi3>:
  1027f0:	55                   	push   %ebp
  1027f1:	89 e5                	mov    %esp,%ebp
  1027f3:	57                   	push   %edi
  1027f4:	56                   	push   %esi
  1027f5:	83 ec 1c             	sub    $0x1c,%esp
  1027f8:	8b 45 10             	mov    0x10(%ebp),%eax
  1027fb:	8b 55 14             	mov    0x14(%ebp),%edx
  1027fe:	8b 7d 0c             	mov    0xc(%ebp),%edi
  102801:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
  102804:	89 c1                	mov    %eax,%ecx
  102806:	8b 45 08             	mov    0x8(%ebp),%eax
  102809:	85 d2                	test   %edx,%edx
  10280b:	89 d6                	mov    %edx,%esi
  10280d:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  102810:	75 1e                	jne    102830 <__udivdi3+0x40>
  102812:	39 f9                	cmp    %edi,%ecx
  102814:	0f 86 8d 00 00 00    	jbe    1028a7 <__udivdi3+0xb7>
  10281a:	89 fa                	mov    %edi,%edx
  10281c:	f7 f1                	div    %ecx
  10281e:	89 c1                	mov    %eax,%ecx
  102820:	89 c8                	mov    %ecx,%eax
  102822:	89 f2                	mov    %esi,%edx
  102824:	83 c4 1c             	add    $0x1c,%esp
  102827:	5e                   	pop    %esi
  102828:	5f                   	pop    %edi
  102829:	5d                   	pop    %ebp
  10282a:	c3                   	ret    
  10282b:	90                   	nop    
  10282c:	8d 74 26 00          	lea    0x0(%esi),%esi
  102830:	39 fa                	cmp    %edi,%edx
  102832:	0f 87 98 00 00 00    	ja     1028d0 <__udivdi3+0xe0>
  102838:	0f bd c2             	bsr    %edx,%eax
  10283b:	83 f0 1f             	xor    $0x1f,%eax
  10283e:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
  102841:	74 7f                	je     1028c2 <__udivdi3+0xd2>
  102843:	b8 20 00 00 00       	mov    $0x20,%eax
  102848:	8b 55 f0             	mov    0xfffffff0(%ebp),%edx
  10284b:	2b 45 e4             	sub    0xffffffe4(%ebp),%eax
  10284e:	89 c1                	mov    %eax,%ecx
  102850:	d3 ea                	shr    %cl,%edx
  102852:	0f b6 4d e4          	movzbl 0xffffffe4(%ebp),%ecx
  102856:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  102859:	89 f0                	mov    %esi,%eax
  10285b:	d3 e0                	shl    %cl,%eax
  10285d:	09 c2                	or     %eax,%edx
  10285f:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  102862:	89 55 e0             	mov    %edx,0xffffffe0(%ebp)
  102865:	89 fa                	mov    %edi,%edx
  102867:	d3 e0                	shl    %cl,%eax
  102869:	0f b6 4d ec          	movzbl 0xffffffec(%ebp),%ecx
  10286d:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
  102870:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  102873:	d3 e8                	shr    %cl,%eax
  102875:	0f b6 4d e4          	movzbl 0xffffffe4(%ebp),%ecx
  102879:	d3 e2                	shl    %cl,%edx
  10287b:	0f b6 4d ec          	movzbl 0xffffffec(%ebp),%ecx
  10287f:	09 d0                	or     %edx,%eax
  102881:	d3 ef                	shr    %cl,%edi
  102883:	89 fa                	mov    %edi,%edx
  102885:	f7 75 e0             	divl   0xffffffe0(%ebp)
  102888:	89 d1                	mov    %edx,%ecx
  10288a:	89 c7                	mov    %eax,%edi
  10288c:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  10288f:	f7 e7                	mul    %edi
  102891:	39 d1                	cmp    %edx,%ecx
  102893:	89 c6                	mov    %eax,%esi
  102895:	89 55 dc             	mov    %edx,0xffffffdc(%ebp)
  102898:	72 6f                	jb     102909 <__udivdi3+0x119>
  10289a:	39 ca                	cmp    %ecx,%edx
  10289c:	74 5e                	je     1028fc <__udivdi3+0x10c>
  10289e:	89 f9                	mov    %edi,%ecx
  1028a0:	31 f6                	xor    %esi,%esi
  1028a2:	e9 79 ff ff ff       	jmp    102820 <__udivdi3+0x30>
  1028a7:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  1028aa:	85 c0                	test   %eax,%eax
  1028ac:	74 32                	je     1028e0 <__udivdi3+0xf0>
  1028ae:	89 f2                	mov    %esi,%edx
  1028b0:	89 f8                	mov    %edi,%eax
  1028b2:	f7 f1                	div    %ecx
  1028b4:	89 c6                	mov    %eax,%esi
  1028b6:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  1028b9:	f7 f1                	div    %ecx
  1028bb:	89 c1                	mov    %eax,%ecx
  1028bd:	e9 5e ff ff ff       	jmp    102820 <__udivdi3+0x30>
  1028c2:	39 d7                	cmp    %edx,%edi
  1028c4:	77 2a                	ja     1028f0 <__udivdi3+0x100>
  1028c6:	8b 55 f0             	mov    0xfffffff0(%ebp),%edx
  1028c9:	39 55 e8             	cmp    %edx,0xffffffe8(%ebp)
  1028cc:	73 22                	jae    1028f0 <__udivdi3+0x100>
  1028ce:	66 90                	xchg   %ax,%ax
  1028d0:	31 c9                	xor    %ecx,%ecx
  1028d2:	31 f6                	xor    %esi,%esi
  1028d4:	e9 47 ff ff ff       	jmp    102820 <__udivdi3+0x30>
  1028d9:	8d b4 26 00 00 00 00 	lea    0x0(%esi),%esi
  1028e0:	b8 01 00 00 00       	mov    $0x1,%eax
  1028e5:	31 d2                	xor    %edx,%edx
  1028e7:	f7 75 f0             	divl   0xfffffff0(%ebp)
  1028ea:	89 c1                	mov    %eax,%ecx
  1028ec:	eb c0                	jmp    1028ae <__udivdi3+0xbe>
  1028ee:	66 90                	xchg   %ax,%ax
  1028f0:	b9 01 00 00 00       	mov    $0x1,%ecx
  1028f5:	31 f6                	xor    %esi,%esi
  1028f7:	e9 24 ff ff ff       	jmp    102820 <__udivdi3+0x30>
  1028fc:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  1028ff:	0f b6 4d e4          	movzbl 0xffffffe4(%ebp),%ecx
  102903:	d3 e0                	shl    %cl,%eax
  102905:	39 c6                	cmp    %eax,%esi
  102907:	76 95                	jbe    10289e <__udivdi3+0xae>
  102909:	8d 4f ff             	lea    0xffffffff(%edi),%ecx
  10290c:	31 f6                	xor    %esi,%esi
  10290e:	e9 0d ff ff ff       	jmp    102820 <__udivdi3+0x30>
  102913:	90                   	nop    
  102914:	90                   	nop    
  102915:	90                   	nop    
  102916:	90                   	nop    
  102917:	90                   	nop    
  102918:	90                   	nop    
  102919:	90                   	nop    
  10291a:	90                   	nop    
  10291b:	90                   	nop    
  10291c:	90                   	nop    
  10291d:	90                   	nop    
  10291e:	90                   	nop    
  10291f:	90                   	nop    

00102920 <__umoddi3>:
  102920:	55                   	push   %ebp
  102921:	89 e5                	mov    %esp,%ebp
  102923:	57                   	push   %edi
  102924:	56                   	push   %esi
  102925:	83 ec 30             	sub    $0x30,%esp
  102928:	8b 55 14             	mov    0x14(%ebp),%edx
  10292b:	8b 45 10             	mov    0x10(%ebp),%eax
  10292e:	8b 75 08             	mov    0x8(%ebp),%esi
  102931:	8b 7d 0c             	mov    0xc(%ebp),%edi
  102934:	85 d2                	test   %edx,%edx
  102936:	c7 45 d0 00 00 00 00 	movl   $0x0,0xffffffd0(%ebp)
  10293d:	89 c1                	mov    %eax,%ecx
  10293f:	c7 45 d4 00 00 00 00 	movl   $0x0,0xffffffd4(%ebp)
  102946:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  102949:	89 55 e8             	mov    %edx,0xffffffe8(%ebp)
  10294c:	89 75 f0             	mov    %esi,0xfffffff0(%ebp)
  10294f:	89 7d e0             	mov    %edi,0xffffffe0(%ebp)
  102952:	75 1c                	jne    102970 <__umoddi3+0x50>
  102954:	39 f8                	cmp    %edi,%eax
  102956:	89 fa                	mov    %edi,%edx
  102958:	0f 86 d4 00 00 00    	jbe    102a32 <__umoddi3+0x112>
  10295e:	89 f0                	mov    %esi,%eax
  102960:	f7 f1                	div    %ecx
  102962:	89 55 d0             	mov    %edx,0xffffffd0(%ebp)
  102965:	c7 45 d4 00 00 00 00 	movl   $0x0,0xffffffd4(%ebp)
  10296c:	eb 12                	jmp    102980 <__umoddi3+0x60>
  10296e:	66 90                	xchg   %ax,%ax
  102970:	8b 4d e0             	mov    0xffffffe0(%ebp),%ecx
  102973:	39 4d e8             	cmp    %ecx,0xffffffe8(%ebp)
  102976:	76 18                	jbe    102990 <__umoddi3+0x70>
  102978:	89 75 d0             	mov    %esi,0xffffffd0(%ebp)
  10297b:	89 7d d4             	mov    %edi,0xffffffd4(%ebp)
  10297e:	66 90                	xchg   %ax,%ax
  102980:	8b 45 d0             	mov    0xffffffd0(%ebp),%eax
  102983:	8b 55 d4             	mov    0xffffffd4(%ebp),%edx
  102986:	83 c4 30             	add    $0x30,%esp
  102989:	5e                   	pop    %esi
  10298a:	5f                   	pop    %edi
  10298b:	5d                   	pop    %ebp
  10298c:	c3                   	ret    
  10298d:	8d 76 00             	lea    0x0(%esi),%esi
  102990:	0f bd 45 e8          	bsr    0xffffffe8(%ebp),%eax
  102994:	83 f0 1f             	xor    $0x1f,%eax
  102997:	89 45 dc             	mov    %eax,0xffffffdc(%ebp)
  10299a:	0f 84 c0 00 00 00    	je     102a60 <__umoddi3+0x140>
  1029a0:	b8 20 00 00 00       	mov    $0x20,%eax
  1029a5:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
  1029a8:	2b 45 dc             	sub    0xffffffdc(%ebp),%eax
  1029ab:	8b 7d ec             	mov    0xffffffec(%ebp),%edi
  1029ae:	8b 75 f0             	mov    0xfffffff0(%ebp),%esi
  1029b1:	89 c1                	mov    %eax,%ecx
  1029b3:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
  1029b6:	d3 ea                	shr    %cl,%edx
  1029b8:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  1029bb:	0f b6 4d dc          	movzbl 0xffffffdc(%ebp),%ecx
  1029bf:	d3 e0                	shl    %cl,%eax
  1029c1:	09 c2                	or     %eax,%edx
  1029c3:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  1029c6:	d3 e7                	shl    %cl,%edi
  1029c8:	0f b6 4d e4          	movzbl 0xffffffe4(%ebp),%ecx
  1029cc:	89 55 f4             	mov    %edx,0xfffffff4(%ebp)
  1029cf:	8b 55 e0             	mov    0xffffffe0(%ebp),%edx
  1029d2:	d3 e8                	shr    %cl,%eax
  1029d4:	0f b6 4d dc          	movzbl 0xffffffdc(%ebp),%ecx
  1029d8:	d3 e2                	shl    %cl,%edx
  1029da:	09 d0                	or     %edx,%eax
  1029dc:	8b 55 e0             	mov    0xffffffe0(%ebp),%edx
  1029df:	d3 e6                	shl    %cl,%esi
  1029e1:	0f b6 4d e4          	movzbl 0xffffffe4(%ebp),%ecx
  1029e5:	d3 ea                	shr    %cl,%edx
  1029e7:	f7 75 f4             	divl   0xfffffff4(%ebp)
  1029ea:	89 55 cc             	mov    %edx,0xffffffcc(%ebp)
  1029ed:	f7 e7                	mul    %edi
  1029ef:	39 55 cc             	cmp    %edx,0xffffffcc(%ebp)
  1029f2:	0f 82 a5 00 00 00    	jb     102a9d <__umoddi3+0x17d>
  1029f8:	3b 55 cc             	cmp    0xffffffcc(%ebp),%edx
  1029fb:	0f 84 94 00 00 00    	je     102a95 <__umoddi3+0x175>
  102a01:	8b 4d cc             	mov    0xffffffcc(%ebp),%ecx
  102a04:	29 c6                	sub    %eax,%esi
  102a06:	19 d1                	sbb    %edx,%ecx
  102a08:	89 4d cc             	mov    %ecx,0xffffffcc(%ebp)
  102a0b:	0f b6 4d dc          	movzbl 0xffffffdc(%ebp),%ecx
  102a0f:	89 f2                	mov    %esi,%edx
  102a11:	8b 45 cc             	mov    0xffffffcc(%ebp),%eax
  102a14:	d3 ea                	shr    %cl,%edx
  102a16:	0f b6 4d e4          	movzbl 0xffffffe4(%ebp),%ecx
  102a1a:	d3 e0                	shl    %cl,%eax
  102a1c:	0f b6 4d dc          	movzbl 0xffffffdc(%ebp),%ecx
  102a20:	09 c2                	or     %eax,%edx
  102a22:	8b 45 cc             	mov    0xffffffcc(%ebp),%eax
  102a25:	89 55 d0             	mov    %edx,0xffffffd0(%ebp)
  102a28:	d3 e8                	shr    %cl,%eax
  102a2a:	89 45 d4             	mov    %eax,0xffffffd4(%ebp)
  102a2d:	e9 4e ff ff ff       	jmp    102980 <__umoddi3+0x60>
  102a32:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  102a35:	85 c0                	test   %eax,%eax
  102a37:	74 17                	je     102a50 <__umoddi3+0x130>
  102a39:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  102a3c:	8b 55 e8             	mov    0xffffffe8(%ebp),%edx
  102a3f:	f7 f1                	div    %ecx
  102a41:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  102a44:	f7 f1                	div    %ecx
  102a46:	e9 17 ff ff ff       	jmp    102962 <__umoddi3+0x42>
  102a4b:	90                   	nop    
  102a4c:	8d 74 26 00          	lea    0x0(%esi),%esi
  102a50:	b8 01 00 00 00       	mov    $0x1,%eax
  102a55:	31 d2                	xor    %edx,%edx
  102a57:	f7 75 ec             	divl   0xffffffec(%ebp)
  102a5a:	89 c1                	mov    %eax,%ecx
  102a5c:	eb db                	jmp    102a39 <__umoddi3+0x119>
  102a5e:	66 90                	xchg   %ax,%ax
  102a60:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  102a63:	39 45 e0             	cmp    %eax,0xffffffe0(%ebp)
  102a66:	77 19                	ja     102a81 <__umoddi3+0x161>
  102a68:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
  102a6b:	39 55 f0             	cmp    %edx,0xfffffff0(%ebp)
  102a6e:	73 11                	jae    102a81 <__umoddi3+0x161>
  102a70:	8b 55 f0             	mov    0xfffffff0(%ebp),%edx
  102a73:	8b 4d e0             	mov    0xffffffe0(%ebp),%ecx
  102a76:	89 55 d0             	mov    %edx,0xffffffd0(%ebp)
  102a79:	89 4d d4             	mov    %ecx,0xffffffd4(%ebp)
  102a7c:	e9 ff fe ff ff       	jmp    102980 <__umoddi3+0x60>
  102a81:	8b 4d e0             	mov    0xffffffe0(%ebp),%ecx
  102a84:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  102a87:	2b 45 ec             	sub    0xffffffec(%ebp),%eax
  102a8a:	1b 4d e8             	sbb    0xffffffe8(%ebp),%ecx
  102a8d:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
  102a90:	89 4d e0             	mov    %ecx,0xffffffe0(%ebp)
  102a93:	eb db                	jmp    102a70 <__umoddi3+0x150>
  102a95:	39 f0                	cmp    %esi,%eax
  102a97:	0f 86 64 ff ff ff    	jbe    102a01 <__umoddi3+0xe1>
  102a9d:	29 f8                	sub    %edi,%eax
  102a9f:	1b 55 f4             	sbb    0xfffffff4(%ebp),%edx
  102aa2:	e9 5a ff ff ff       	jmp    102a01 <__umoddi3+0xe1>
