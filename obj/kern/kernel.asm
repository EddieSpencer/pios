
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
  10005a:	e8 4a 26 00 00       	call   1026a9 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
  10005f:	e8 f5 01 00 00       	call   100259 <cons_init>

	// Lab 1: test cprintf and debug_trace
	cprintf("1234 decimal is %o octal!\n", 1234);
  100064:	c7 44 24 04 d2 04 00 	movl   $0x4d2,0x4(%esp)
  10006b:	00 
  10006c:	c7 04 24 80 2b 10 00 	movl   $0x102b80,(%esp)
  100073:	e8 39 24 00 00       	call   1024b1 <cprintf>
	debug_check();
  100078:	e8 3b 05 00 00       	call   1005b8 <debug_check>

	// Initialize and load the bootstrap CPU's GDT, TSS, and IDT.
	cpu_init();
  10007d:	e8 3e 0e 00 00       	call   100ec0 <cpu_init>
	trap_init();
  100082:	e8 03 0f 00 00       	call   100f8a <trap_init>

	// Physical memory detection/initialization.
	// Can't call mem_alloc until after we do this!
	mem_init();
  100087:	e8 6c 07 00 00       	call   1007f8 <mem_init>


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
  1000d5:	c7 44 24 0c 9b 2b 10 	movl   $0x102b9b,0xc(%esp)
  1000dc:	00 
  1000dd:	c7 44 24 08 b1 2b 10 	movl   $0x102bb1,0x8(%esp)
  1000e4:	00 
  1000e5:	c7 44 24 04 50 00 00 	movl   $0x50,0x4(%esp)
  1000ec:	00 
  1000ed:	c7 04 24 c6 2b 10 00 	movl   $0x102bc6,(%esp)
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
  100104:	c7 04 24 d3 2b 10 00 	movl   $0x102bd3,(%esp)
  10010b:	e8 a1 23 00 00       	call   1024b1 <cprintf>
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
  100121:	c7 44 24 0c e0 2b 10 	movl   $0x102be0,0xc(%esp)
  100128:	00 
  100129:	c7 44 24 08 b1 2b 10 	movl   $0x102bb1,0x8(%esp)
  100130:	00 
  100131:	c7 44 24 04 50 00 00 	movl   $0x50,0x4(%esp)
  100138:	00 
  100139:	c7 04 24 07 2c 10 00 	movl   $0x102c07,(%esp)
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
  100156:	c7 44 24 0c 14 2c 10 	movl   $0x102c14,0xc(%esp)
  10015d:	00 
  10015e:	c7 44 24 08 b1 2b 10 	movl   $0x102bb1,0x8(%esp)
  100165:	00 
  100166:	c7 44 24 04 51 00 00 	movl   $0x51,0x4(%esp)
  10016d:	00 
  10016e:	c7 04 24 07 2c 10 00 	movl   $0x102c07,(%esp)
  100175:	e8 ba 01 00 00       	call   100334 <debug_panic>

	// Check that we're in user mode and can handle traps from there.
	trap_check_user();
  10017a:	e8 89 11 00 00       	call   101308 <trap_check_user>

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
  1001dd:	e8 12 19 00 00       	call   101af4 <serial_intr>
	kbd_intr();
  1001e2:	e8 69 18 00 00       	call   101a50 <kbd_intr>

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
  100247:	e8 c5 18 00 00       	call   101b11 <serial_putc>
	video_putc(c);
  10024c:	8b 45 08             	mov    0x8(%ebp),%eax
  10024f:	89 04 24             	mov    %eax,(%esp)
  100252:	e8 35 14 00 00       	call   10168c <video_putc>
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
  100268:	e8 57 13 00 00       	call   1015c4 <video_init>
	kbd_init();
  10026d:	e8 f2 17 00 00       	call   101a64 <kbd_init>
	serial_init();
  100272:	e8 fa 18 00 00       	call   101b71 <serial_init>

	if (!serial_exists)
  100277:	a1 80 7f 10 00       	mov    0x107f80,%eax
  10027c:	85 c0                	test   %eax,%eax
  10027e:	75 1c                	jne    10029c <cons_init+0x43>
		warn("Serial port does not exist!\n");
  100280:	c7 44 24 08 4c 2c 10 	movl   $0x102c4c,0x8(%esp)
  100287:	00 
  100288:	c7 44 24 04 69 00 00 	movl   $0x69,0x4(%esp)
  10028f:	00 
  100290:	c7 04 24 69 2c 10 00 	movl   $0x102c69,(%esp)
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
  1002e0:	c7 44 24 0c 75 2c 10 	movl   $0x102c75,0xc(%esp)
  1002e7:	00 
  1002e8:	c7 44 24 08 8b 2c 10 	movl   $0x102c8b,0x8(%esp)
  1002ef:	00 
  1002f0:	c7 44 24 04 50 00 00 	movl   $0x50,0x4(%esp)
  1002f7:	00 
  1002f8:	c7 04 24 a0 2c 10 00 	movl   $0x102ca0,(%esp)
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
  100377:	c7 04 24 b0 2c 10 00 	movl   $0x102cb0,(%esp)
  10037e:	e8 2e 21 00 00       	call   1024b1 <cprintf>
	vcprintf(fmt, ap);
  100383:	8b 55 10             	mov    0x10(%ebp),%edx
  100386:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  100389:	89 44 24 04          	mov    %eax,0x4(%esp)
  10038d:	89 14 24             	mov    %edx,(%esp)
  100390:	e8 b3 20 00 00       	call   102448 <vcprintf>
	cprintf("\n");
  100395:	c7 04 24 c8 2c 10 00 	movl   $0x102cc8,(%esp)
  10039c:	e8 10 21 00 00       	call   1024b1 <cprintf>
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
  1003cc:	c7 04 24 ca 2c 10 00 	movl   $0x102cca,(%esp)
  1003d3:	e8 d9 20 00 00       	call   1024b1 <cprintf>
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
  10040f:	c7 04 24 d7 2c 10 00 	movl   $0x102cd7,(%esp)
  100416:	e8 96 20 00 00       	call   1024b1 <cprintf>
	vcprintf(fmt, ap);
  10041b:	8b 55 10             	mov    0x10(%ebp),%edx
  10041e:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  100421:	89 44 24 04          	mov    %eax,0x4(%esp)
  100425:	89 14 24             	mov    %edx,(%esp)
  100428:	e8 1b 20 00 00       	call   102448 <vcprintf>
	cprintf("\n");
  10042d:	c7 04 24 c8 2c 10 00 	movl   $0x102cc8,(%esp)
  100434:	e8 78 20 00 00       	call   1024b1 <cprintf>
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
  10043e:	56                   	push   %esi
  10043f:	53                   	push   %ebx
  100440:	83 ec 30             	sub    $0x30,%esp

  uint32_t *frame = (uint32_t *) ebp;
  100443:	8b 45 08             	mov    0x8(%ebp),%eax
  100446:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)

  int i;

  // Print the eip of the last n frames,
  // where n is DEBUG_TRACEFRAMES
  for (i = 0; i < DEBUG_TRACEFRAMES && frame; i++) {
  100449:	c7 45 f4 00 00 00 00 	movl   $0x0,0xfffffff4(%ebp)
  100450:	e9 a2 00 00 00       	jmp    1004f7 <debug_trace+0xbc>
    // print relevent information about the stack
    cprintf("ebp: %08x ", frame[0]);
  100455:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  100458:	8b 00                	mov    (%eax),%eax
  10045a:	89 44 24 04          	mov    %eax,0x4(%esp)
  10045e:	c7 04 24 f1 2c 10 00 	movl   $0x102cf1,(%esp)
  100465:	e8 47 20 00 00       	call   1024b1 <cprintf>
    cprintf("eip: %08x ", frame[1]);
  10046a:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  10046d:	83 c0 04             	add    $0x4,%eax
  100470:	8b 00                	mov    (%eax),%eax
  100472:	89 44 24 04          	mov    %eax,0x4(%esp)
  100476:	c7 04 24 fc 2c 10 00 	movl   $0x102cfc,(%esp)
  10047d:	e8 2f 20 00 00       	call   1024b1 <cprintf>
    cprintf("args: %08x %08x %08x %08x %08x ", frame[2], frame[3], frame[4], frame[5], frame[6]);
  100482:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  100485:	83 c0 18             	add    $0x18,%eax
  100488:	8b 10                	mov    (%eax),%edx
  10048a:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  10048d:	83 c0 14             	add    $0x14,%eax
  100490:	8b 08                	mov    (%eax),%ecx
  100492:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  100495:	83 c0 10             	add    $0x10,%eax
  100498:	8b 18                	mov    (%eax),%ebx
  10049a:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  10049d:	83 c0 0c             	add    $0xc,%eax
  1004a0:	8b 30                	mov    (%eax),%esi
  1004a2:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  1004a5:	83 c0 08             	add    $0x8,%eax
  1004a8:	8b 00                	mov    (%eax),%eax
  1004aa:	89 54 24 14          	mov    %edx,0x14(%esp)
  1004ae:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  1004b2:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  1004b6:	89 74 24 08          	mov    %esi,0x8(%esp)
  1004ba:	89 44 24 04          	mov    %eax,0x4(%esp)
  1004be:	c7 04 24 08 2d 10 00 	movl   $0x102d08,(%esp)
  1004c5:	e8 e7 1f 00 00       	call   1024b1 <cprintf>
    cprintf("\n"); 
  1004ca:	c7 04 24 c8 2c 10 00 	movl   $0x102cc8,(%esp)
  1004d1:	e8 db 1f 00 00       	call   1024b1 <cprintf>

    // add information to eips array
    eips[i] = frame[1];             // eip saved at ebp + 1
  1004d6:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  1004d9:	c1 e0 02             	shl    $0x2,%eax
  1004dc:	89 c2                	mov    %eax,%edx
  1004de:	03 55 0c             	add    0xc(%ebp),%edx
  1004e1:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  1004e4:	83 c0 04             	add    $0x4,%eax
  1004e7:	8b 00                	mov    (%eax),%eax
  1004e9:	89 02                	mov    %eax,(%edx)

    // move to the next frame up the stack
    frame = (uint32_t*)frame[0];  // prev ebp saved at ebp 0
  1004eb:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  1004ee:	8b 00                	mov    (%eax),%eax
  1004f0:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
  1004f3:	83 45 f4 01          	addl   $0x1,0xfffffff4(%ebp)
  1004f7:	83 7d f4 09          	cmpl   $0x9,0xfffffff4(%ebp)
  1004fb:	7f 1f                	jg     10051c <debug_trace+0xe1>
  1004fd:	83 7d f0 00          	cmpl   $0x0,0xfffffff0(%ebp)
  100501:	0f 85 4e ff ff ff    	jne    100455 <debug_trace+0x1a>
  }

  // if the there are less than DEBUG_TRACEFRAMES frames,
  // print the rest as null
  for (i; i < DEBUG_TRACEFRAMES; i++) {
  100507:	eb 13                	jmp    10051c <debug_trace+0xe1>
    eips[i] = 0; 
  100509:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  10050c:	c1 e0 02             	shl    $0x2,%eax
  10050f:	03 45 0c             	add    0xc(%ebp),%eax
  100512:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  100518:	83 45 f4 01          	addl   $0x1,0xfffffff4(%ebp)
  10051c:	83 7d f4 09          	cmpl   $0x9,0xfffffff4(%ebp)
  100520:	7e e7                	jle    100509 <debug_trace+0xce>
  }
}
  100522:	83 c4 30             	add    $0x30,%esp
  100525:	5b                   	pop    %ebx
  100526:	5e                   	pop    %esi
  100527:	5d                   	pop    %ebp
  100528:	c3                   	ret    

00100529 <f3>:


static void gcc_noinline f3(int r, uint32_t *e) { debug_trace(read_ebp(), e); }
  100529:	55                   	push   %ebp
  10052a:	89 e5                	mov    %esp,%ebp
  10052c:	83 ec 18             	sub    $0x18,%esp
static gcc_inline uint32_t
read_ebp(void)
{
        uint32_t ebp;
        __asm __volatile("movl %%ebp,%0" : "=rm" (ebp));
  10052f:	89 6d fc             	mov    %ebp,0xfffffffc(%ebp)
        return ebp;
  100532:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  100535:	89 c2                	mov    %eax,%edx
  100537:	8b 45 0c             	mov    0xc(%ebp),%eax
  10053a:	89 44 24 04          	mov    %eax,0x4(%esp)
  10053e:	89 14 24             	mov    %edx,(%esp)
  100541:	e8 f5 fe ff ff       	call   10043b <debug_trace>
  100546:	c9                   	leave  
  100547:	c3                   	ret    

00100548 <f2>:
static void gcc_noinline f2(int r, uint32_t *e) { r & 2 ? f3(r,e) : f3(r,e); }
  100548:	55                   	push   %ebp
  100549:	89 e5                	mov    %esp,%ebp
  10054b:	83 ec 08             	sub    $0x8,%esp
  10054e:	8b 45 08             	mov    0x8(%ebp),%eax
  100551:	83 e0 02             	and    $0x2,%eax
  100554:	85 c0                	test   %eax,%eax
  100556:	74 14                	je     10056c <f2+0x24>
  100558:	8b 45 0c             	mov    0xc(%ebp),%eax
  10055b:	89 44 24 04          	mov    %eax,0x4(%esp)
  10055f:	8b 45 08             	mov    0x8(%ebp),%eax
  100562:	89 04 24             	mov    %eax,(%esp)
  100565:	e8 bf ff ff ff       	call   100529 <f3>
  10056a:	eb 12                	jmp    10057e <f2+0x36>
  10056c:	8b 45 0c             	mov    0xc(%ebp),%eax
  10056f:	89 44 24 04          	mov    %eax,0x4(%esp)
  100573:	8b 45 08             	mov    0x8(%ebp),%eax
  100576:	89 04 24             	mov    %eax,(%esp)
  100579:	e8 ab ff ff ff       	call   100529 <f3>
  10057e:	c9                   	leave  
  10057f:	c3                   	ret    

00100580 <f1>:
static void gcc_noinline f1(int r, uint32_t *e) { r & 1 ? f2(r,e) : f2(r,e); }
  100580:	55                   	push   %ebp
  100581:	89 e5                	mov    %esp,%ebp
  100583:	83 ec 08             	sub    $0x8,%esp
  100586:	8b 45 08             	mov    0x8(%ebp),%eax
  100589:	83 e0 01             	and    $0x1,%eax
  10058c:	84 c0                	test   %al,%al
  10058e:	74 14                	je     1005a4 <f1+0x24>
  100590:	8b 45 0c             	mov    0xc(%ebp),%eax
  100593:	89 44 24 04          	mov    %eax,0x4(%esp)
  100597:	8b 45 08             	mov    0x8(%ebp),%eax
  10059a:	89 04 24             	mov    %eax,(%esp)
  10059d:	e8 a6 ff ff ff       	call   100548 <f2>
  1005a2:	eb 12                	jmp    1005b6 <f1+0x36>
  1005a4:	8b 45 0c             	mov    0xc(%ebp),%eax
  1005a7:	89 44 24 04          	mov    %eax,0x4(%esp)
  1005ab:	8b 45 08             	mov    0x8(%ebp),%eax
  1005ae:	89 04 24             	mov    %eax,(%esp)
  1005b1:	e8 92 ff ff ff       	call   100548 <f2>
  1005b6:	c9                   	leave  
  1005b7:	c3                   	ret    

001005b8 <debug_check>:

// Test the backtrace implementation for correct operation
void
debug_check(void)
{
  1005b8:	55                   	push   %ebp
  1005b9:	89 e5                	mov    %esp,%ebp
  1005bb:	81 ec c8 00 00 00    	sub    $0xc8,%esp
	uint32_t eips[4][DEBUG_TRACEFRAMES];
	int r, i;

	// produce several related backtraces...
	for (i = 0; i < 4; i++)
  1005c1:	c7 45 fc 00 00 00 00 	movl   $0x0,0xfffffffc(%ebp)
  1005c8:	eb 2a                	jmp    1005f4 <debug_check+0x3c>
		f1(i, eips[i]);
  1005ca:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  1005cd:	89 d0                	mov    %edx,%eax
  1005cf:	c1 e0 02             	shl    $0x2,%eax
  1005d2:	01 d0                	add    %edx,%eax
  1005d4:	c1 e0 03             	shl    $0x3,%eax
  1005d7:	89 c2                	mov    %eax,%edx
  1005d9:	8d 85 58 ff ff ff    	lea    0xffffff58(%ebp),%eax
  1005df:	01 d0                	add    %edx,%eax
  1005e1:	89 44 24 04          	mov    %eax,0x4(%esp)
  1005e5:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  1005e8:	89 04 24             	mov    %eax,(%esp)
  1005eb:	e8 90 ff ff ff       	call   100580 <f1>
  1005f0:	83 45 fc 01          	addl   $0x1,0xfffffffc(%ebp)
  1005f4:	83 7d fc 03          	cmpl   $0x3,0xfffffffc(%ebp)
  1005f8:	7e d0                	jle    1005ca <debug_check+0x12>

	// ...and make sure they come out correctly.
	for (r = 0; r < 4; r++)
  1005fa:	c7 45 f8 00 00 00 00 	movl   $0x0,0xfffffff8(%ebp)
  100601:	e9 bc 00 00 00       	jmp    1006c2 <debug_check+0x10a>
		for (i = 0; i < DEBUG_TRACEFRAMES; i++) {
  100606:	c7 45 fc 00 00 00 00 	movl   $0x0,0xfffffffc(%ebp)
  10060d:	e9 a2 00 00 00       	jmp    1006b4 <debug_check+0xfc>
			assert((eips[r][i] != 0) == (i < 5));
  100612:	8b 55 f8             	mov    0xfffffff8(%ebp),%edx
  100615:	8b 4d fc             	mov    0xfffffffc(%ebp),%ecx
  100618:	89 d0                	mov    %edx,%eax
  10061a:	c1 e0 02             	shl    $0x2,%eax
  10061d:	01 d0                	add    %edx,%eax
  10061f:	01 c0                	add    %eax,%eax
  100621:	01 c8                	add    %ecx,%eax
  100623:	8b 84 85 58 ff ff ff 	mov    0xffffff58(%ebp,%eax,4),%eax
  10062a:	85 c0                	test   %eax,%eax
  10062c:	0f 95 c2             	setne  %dl
  10062f:	83 7d fc 04          	cmpl   $0x4,0xfffffffc(%ebp)
  100633:	0f 9e c0             	setle  %al
  100636:	31 d0                	xor    %edx,%eax
  100638:	84 c0                	test   %al,%al
  10063a:	74 24                	je     100660 <debug_check+0xa8>
  10063c:	c7 44 24 0c 28 2d 10 	movl   $0x102d28,0xc(%esp)
  100643:	00 
  100644:	c7 44 24 08 45 2d 10 	movl   $0x102d45,0x8(%esp)
  10064b:	00 
  10064c:	c7 44 24 04 79 00 00 	movl   $0x79,0x4(%esp)
  100653:	00 
  100654:	c7 04 24 5a 2d 10 00 	movl   $0x102d5a,(%esp)
  10065b:	e8 d4 fc ff ff       	call   100334 <debug_panic>
			if (i >= 2)
  100660:	83 7d fc 01          	cmpl   $0x1,0xfffffffc(%ebp)
  100664:	7e 4a                	jle    1006b0 <debug_check+0xf8>
				assert(eips[r][i] == eips[0][i]);
  100666:	8b 55 f8             	mov    0xfffffff8(%ebp),%edx
  100669:	8b 4d fc             	mov    0xfffffffc(%ebp),%ecx
  10066c:	89 d0                	mov    %edx,%eax
  10066e:	c1 e0 02             	shl    $0x2,%eax
  100671:	01 d0                	add    %edx,%eax
  100673:	01 c0                	add    %eax,%eax
  100675:	01 c8                	add    %ecx,%eax
  100677:	8b 94 85 58 ff ff ff 	mov    0xffffff58(%ebp,%eax,4),%edx
  10067e:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  100681:	8b 84 85 58 ff ff ff 	mov    0xffffff58(%ebp,%eax,4),%eax
  100688:	39 c2                	cmp    %eax,%edx
  10068a:	74 24                	je     1006b0 <debug_check+0xf8>
  10068c:	c7 44 24 0c 67 2d 10 	movl   $0x102d67,0xc(%esp)
  100693:	00 
  100694:	c7 44 24 08 45 2d 10 	movl   $0x102d45,0x8(%esp)
  10069b:	00 
  10069c:	c7 44 24 04 7b 00 00 	movl   $0x7b,0x4(%esp)
  1006a3:	00 
  1006a4:	c7 04 24 5a 2d 10 00 	movl   $0x102d5a,(%esp)
  1006ab:	e8 84 fc ff ff       	call   100334 <debug_panic>
  1006b0:	83 45 fc 01          	addl   $0x1,0xfffffffc(%ebp)
  1006b4:	83 7d fc 09          	cmpl   $0x9,0xfffffffc(%ebp)
  1006b8:	0f 8e 54 ff ff ff    	jle    100612 <debug_check+0x5a>
  1006be:	83 45 f8 01          	addl   $0x1,0xfffffff8(%ebp)
  1006c2:	83 7d f8 03          	cmpl   $0x3,0xfffffff8(%ebp)
  1006c6:	0f 8e 3a ff ff ff    	jle    100606 <debug_check+0x4e>
		}
	assert(eips[0][0] == eips[1][0]);
  1006cc:	8b 95 58 ff ff ff    	mov    0xffffff58(%ebp),%edx
  1006d2:	8b 45 80             	mov    0xffffff80(%ebp),%eax
  1006d5:	39 c2                	cmp    %eax,%edx
  1006d7:	74 24                	je     1006fd <debug_check+0x145>
  1006d9:	c7 44 24 0c 80 2d 10 	movl   $0x102d80,0xc(%esp)
  1006e0:	00 
  1006e1:	c7 44 24 08 45 2d 10 	movl   $0x102d45,0x8(%esp)
  1006e8:	00 
  1006e9:	c7 44 24 04 7d 00 00 	movl   $0x7d,0x4(%esp)
  1006f0:	00 
  1006f1:	c7 04 24 5a 2d 10 00 	movl   $0x102d5a,(%esp)
  1006f8:	e8 37 fc ff ff       	call   100334 <debug_panic>
	assert(eips[2][0] == eips[3][0]);
  1006fd:	8b 55 a8             	mov    0xffffffa8(%ebp),%edx
  100700:	8b 45 d0             	mov    0xffffffd0(%ebp),%eax
  100703:	39 c2                	cmp    %eax,%edx
  100705:	74 24                	je     10072b <debug_check+0x173>
  100707:	c7 44 24 0c 99 2d 10 	movl   $0x102d99,0xc(%esp)
  10070e:	00 
  10070f:	c7 44 24 08 45 2d 10 	movl   $0x102d45,0x8(%esp)
  100716:	00 
  100717:	c7 44 24 04 7e 00 00 	movl   $0x7e,0x4(%esp)
  10071e:	00 
  10071f:	c7 04 24 5a 2d 10 00 	movl   $0x102d5a,(%esp)
  100726:	e8 09 fc ff ff       	call   100334 <debug_panic>
	assert(eips[1][0] != eips[2][0]);
  10072b:	8b 55 80             	mov    0xffffff80(%ebp),%edx
  10072e:	8b 45 a8             	mov    0xffffffa8(%ebp),%eax
  100731:	39 c2                	cmp    %eax,%edx
  100733:	75 24                	jne    100759 <debug_check+0x1a1>
  100735:	c7 44 24 0c b2 2d 10 	movl   $0x102db2,0xc(%esp)
  10073c:	00 
  10073d:	c7 44 24 08 45 2d 10 	movl   $0x102d45,0x8(%esp)
  100744:	00 
  100745:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
  10074c:	00 
  10074d:	c7 04 24 5a 2d 10 00 	movl   $0x102d5a,(%esp)
  100754:	e8 db fb ff ff       	call   100334 <debug_panic>
	assert(eips[0][1] == eips[2][1]);
  100759:	8b 95 5c ff ff ff    	mov    0xffffff5c(%ebp),%edx
  10075f:	8b 45 ac             	mov    0xffffffac(%ebp),%eax
  100762:	39 c2                	cmp    %eax,%edx
  100764:	74 24                	je     10078a <debug_check+0x1d2>
  100766:	c7 44 24 0c cb 2d 10 	movl   $0x102dcb,0xc(%esp)
  10076d:	00 
  10076e:	c7 44 24 08 45 2d 10 	movl   $0x102d45,0x8(%esp)
  100775:	00 
  100776:	c7 44 24 04 80 00 00 	movl   $0x80,0x4(%esp)
  10077d:	00 
  10077e:	c7 04 24 5a 2d 10 00 	movl   $0x102d5a,(%esp)
  100785:	e8 aa fb ff ff       	call   100334 <debug_panic>
	assert(eips[1][1] == eips[3][1]);
  10078a:	8b 55 84             	mov    0xffffff84(%ebp),%edx
  10078d:	8b 45 d4             	mov    0xffffffd4(%ebp),%eax
  100790:	39 c2                	cmp    %eax,%edx
  100792:	74 24                	je     1007b8 <debug_check+0x200>
  100794:	c7 44 24 0c e4 2d 10 	movl   $0x102de4,0xc(%esp)
  10079b:	00 
  10079c:	c7 44 24 08 45 2d 10 	movl   $0x102d45,0x8(%esp)
  1007a3:	00 
  1007a4:	c7 44 24 04 81 00 00 	movl   $0x81,0x4(%esp)
  1007ab:	00 
  1007ac:	c7 04 24 5a 2d 10 00 	movl   $0x102d5a,(%esp)
  1007b3:	e8 7c fb ff ff       	call   100334 <debug_panic>
	assert(eips[0][1] != eips[1][1]);
  1007b8:	8b 95 5c ff ff ff    	mov    0xffffff5c(%ebp),%edx
  1007be:	8b 45 84             	mov    0xffffff84(%ebp),%eax
  1007c1:	39 c2                	cmp    %eax,%edx
  1007c3:	75 24                	jne    1007e9 <debug_check+0x231>
  1007c5:	c7 44 24 0c fd 2d 10 	movl   $0x102dfd,0xc(%esp)
  1007cc:	00 
  1007cd:	c7 44 24 08 45 2d 10 	movl   $0x102d45,0x8(%esp)
  1007d4:	00 
  1007d5:	c7 44 24 04 82 00 00 	movl   $0x82,0x4(%esp)
  1007dc:	00 
  1007dd:	c7 04 24 5a 2d 10 00 	movl   $0x102d5a,(%esp)
  1007e4:	e8 4b fb ff ff       	call   100334 <debug_panic>

	cprintf("debug_check() succeeded!\n");
  1007e9:	c7 04 24 16 2e 10 00 	movl   $0x102e16,(%esp)
  1007f0:	e8 bc 1c 00 00       	call   1024b1 <cprintf>
}
  1007f5:	c9                   	leave  
  1007f6:	c3                   	ret    
  1007f7:	90                   	nop    

001007f8 <mem_init>:
void mem_check(void);

void
mem_init(void)
{
  1007f8:	55                   	push   %ebp
  1007f9:	89 e5                	mov    %esp,%ebp
  1007fb:	83 ec 38             	sub    $0x38,%esp
	if (!cpu_onboot())	// only do once, on the boot CPU
  1007fe:	e8 3e 01 00 00       	call   100941 <cpu_onboot>
  100803:	85 c0                	test   %eax,%eax
  100805:	0f 84 34 01 00 00    	je     10093f <mem_init+0x147>
		return;

	// Determine how much base (<640K) and extended (>1MB) memory
	// is available in the system (in bytes),
	// by reading the PC's BIOS-managed nonvolatile RAM (NVRAM).
	// The NVRAM tells us how many kilobytes there are.
	// Since the count is 16 bits, this gives us up to 64MB of RAM;
	// additional RAM beyond that would have to be detected another way.
	size_t basemem = ROUNDDOWN(nvram_read16(NVRAM_BASELO)*1024, PAGESIZE);
  10080b:	c7 04 24 15 00 00 00 	movl   $0x15,(%esp)
  100812:	e8 5a 14 00 00       	call   101c71 <nvram_read16>
  100817:	c1 e0 0a             	shl    $0xa,%eax
  10081a:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  10081d:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  100820:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  100825:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
	size_t extmem = ROUNDDOWN(nvram_read16(NVRAM_EXTLO)*1024, PAGESIZE);
  100828:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
  10082f:	e8 3d 14 00 00       	call   101c71 <nvram_read16>
  100834:	c1 e0 0a             	shl    $0xa,%eax
  100837:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  10083a:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  10083d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  100842:	89 45 ec             	mov    %eax,0xffffffec(%ebp)

	warn("Assuming we have 1GB of memory!");
  100845:	c7 44 24 08 30 2e 10 	movl   $0x102e30,0x8(%esp)
  10084c:	00 
  10084d:	c7 44 24 04 2f 00 00 	movl   $0x2f,0x4(%esp)
  100854:	00 
  100855:	c7 04 24 50 2e 10 00 	movl   $0x102e50,(%esp)
  10085c:	e8 91 fb ff ff       	call   1003f2 <debug_warn>
	extmem = 1024*1024*1024 - MEM_EXT;	// assume 1GB total memory
  100861:	c7 45 ec 00 00 f0 3f 	movl   $0x3ff00000,0xffffffec(%ebp)

	// The maximum physical address is the top of extended memory.
	mem_max = MEM_EXT + extmem;
  100868:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  10086b:	05 00 00 10 00       	add    $0x100000,%eax
  100870:	a3 78 7f 10 00       	mov    %eax,0x107f78

	// Compute the total number of physical pages (including I/O holes)
	mem_npage = mem_max / PAGESIZE;
  100875:	a1 78 7f 10 00       	mov    0x107f78,%eax
  10087a:	c1 e8 0c             	shr    $0xc,%eax
  10087d:	a3 74 7f 10 00       	mov    %eax,0x107f74

	cprintf("Physical memory: %dK available, ", (int)(mem_max/1024));
  100882:	a1 78 7f 10 00       	mov    0x107f78,%eax
  100887:	c1 e8 0a             	shr    $0xa,%eax
  10088a:	89 44 24 04          	mov    %eax,0x4(%esp)
  10088e:	c7 04 24 5c 2e 10 00 	movl   $0x102e5c,(%esp)
  100895:	e8 17 1c 00 00       	call   1024b1 <cprintf>
	cprintf("base = %dK, extended = %dK\n",
  10089a:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  10089d:	c1 e8 0a             	shr    $0xa,%eax
  1008a0:	89 c2                	mov    %eax,%edx
  1008a2:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  1008a5:	c1 e8 0a             	shr    $0xa,%eax
  1008a8:	89 54 24 08          	mov    %edx,0x8(%esp)
  1008ac:	89 44 24 04          	mov    %eax,0x4(%esp)
  1008b0:	c7 04 24 7d 2e 10 00 	movl   $0x102e7d,(%esp)
  1008b7:	e8 f5 1b 00 00       	call   1024b1 <cprintf>
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
  1008bc:	c7 45 f0 70 7f 10 00 	movl   $0x107f70,0xfffffff0(%ebp)
	int i;
	for (i = 0; i < mem_npage; i++) {
  1008c3:	c7 45 f4 00 00 00 00 	movl   $0x0,0xfffffff4(%ebp)
  1008ca:	eb 42                	jmp    10090e <mem_init+0x116>
		// A free page has no references to it.
		mem_pageinfo[i].refcount = 0;
  1008cc:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  1008cf:	c1 e0 03             	shl    $0x3,%eax
  1008d2:	89 c2                	mov    %eax,%edx
  1008d4:	a1 7c 7f 10 00       	mov    0x107f7c,%eax
  1008d9:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1008dc:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)

		// Add the page to the end of the free list.
		*freetail = &mem_pageinfo[i];
  1008e3:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  1008e6:	c1 e0 03             	shl    $0x3,%eax
  1008e9:	89 c2                	mov    %eax,%edx
  1008eb:	a1 7c 7f 10 00       	mov    0x107f7c,%eax
  1008f0:	01 c2                	add    %eax,%edx
  1008f2:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  1008f5:	89 10                	mov    %edx,(%eax)
		freetail = &mem_pageinfo[i].free_next;
  1008f7:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  1008fa:	c1 e0 03             	shl    $0x3,%eax
  1008fd:	89 c2                	mov    %eax,%edx
  1008ff:	a1 7c 7f 10 00       	mov    0x107f7c,%eax
  100904:	8d 04 02             	lea    (%edx,%eax,1),%eax
  100907:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
  10090a:	83 45 f4 01          	addl   $0x1,0xfffffff4(%ebp)
  10090e:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  100911:	a1 74 7f 10 00       	mov    0x107f74,%eax
  100916:	39 c2                	cmp    %eax,%edx
  100918:	72 b2                	jb     1008cc <mem_init+0xd4>
	}
	*freetail = NULL;	// null-terminate the freelist
  10091a:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  10091d:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

	// ...and remove this when you're ready.
	panic("mem_init() not implemented");
  100923:	c7 44 24 08 99 2e 10 	movl   $0x102e99,0x8(%esp)
  10092a:	00 
  10092b:	c7 44 24 04 5f 00 00 	movl   $0x5f,0x4(%esp)
  100932:	00 
  100933:	c7 04 24 50 2e 10 00 	movl   $0x102e50,(%esp)
  10093a:	e8 f5 f9 ff ff       	call   100334 <debug_panic>

	// Check to make sure the page allocator seems to work correctly.
	mem_check();
}
  10093f:	c9                   	leave  
  100940:	c3                   	ret    

00100941 <cpu_onboot>:
}

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  100941:	55                   	push   %ebp
  100942:	89 e5                	mov    %esp,%ebp
  100944:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  100947:	e8 0d 00 00 00       	call   100959 <cpu_cur>
  10094c:	3d 00 50 10 00       	cmp    $0x105000,%eax
  100951:	0f 94 c0             	sete   %al
  100954:	0f b6 c0             	movzbl %al,%eax
}
  100957:	c9                   	leave  
  100958:	c3                   	ret    

00100959 <cpu_cur>:
  100959:	55                   	push   %ebp
  10095a:	89 e5                	mov    %esp,%ebp
  10095c:	83 ec 28             	sub    $0x28,%esp
static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  10095f:	89 65 fc             	mov    %esp,0xfffffffc(%ebp)
        return esp;
  100962:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  100965:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  100968:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10096b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  100970:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	assert(c->magic == CPU_MAGIC);
  100973:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  100976:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
  10097c:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  100981:	74 24                	je     1009a7 <cpu_cur+0x4e>
  100983:	c7 44 24 0c b4 2e 10 	movl   $0x102eb4,0xc(%esp)
  10098a:	00 
  10098b:	c7 44 24 08 ca 2e 10 	movl   $0x102eca,0x8(%esp)
  100992:	00 
  100993:	c7 44 24 04 50 00 00 	movl   $0x50,0x4(%esp)
  10099a:	00 
  10099b:	c7 04 24 df 2e 10 00 	movl   $0x102edf,(%esp)
  1009a2:	e8 8d f9 ff ff       	call   100334 <debug_panic>
	return c;
  1009a7:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
}
  1009aa:	c9                   	leave  
  1009ab:	c3                   	ret    

001009ac <mem_alloc>:

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
  1009ac:	55                   	push   %ebp
  1009ad:	89 e5                	mov    %esp,%ebp
  1009af:	83 ec 18             	sub    $0x18,%esp
	// Fill this function in
	// Fill this function in.
	panic("mem_alloc not implemented.");
  1009b2:	c7 44 24 08 ec 2e 10 	movl   $0x102eec,0x8(%esp)
  1009b9:	00 
  1009ba:	c7 44 24 04 75 00 00 	movl   $0x75,0x4(%esp)
  1009c1:	00 
  1009c2:	c7 04 24 50 2e 10 00 	movl   $0x102e50,(%esp)
  1009c9:	e8 66 f9 ff ff       	call   100334 <debug_panic>

001009ce <mem_free>:
}

//
// Return a page to the free list, given its pageinfo pointer.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
mem_free(pageinfo *pi)
{
  1009ce:	55                   	push   %ebp
  1009cf:	89 e5                	mov    %esp,%ebp
  1009d1:	83 ec 18             	sub    $0x18,%esp
	// Fill this function in.
	panic("mem_free not implemented.");
  1009d4:	c7 44 24 08 07 2f 10 	movl   $0x102f07,0x8(%esp)
  1009db:	00 
  1009dc:	c7 44 24 04 80 00 00 	movl   $0x80,0x4(%esp)
  1009e3:	00 
  1009e4:	c7 04 24 50 2e 10 00 	movl   $0x102e50,(%esp)
  1009eb:	e8 44 f9 ff ff       	call   100334 <debug_panic>

001009f0 <mem_check>:
}

//
// Check the physical page allocator (mem_alloc(), mem_free())
// for correct operation after initialization via mem_init().
//
void
mem_check()
{
  1009f0:	55                   	push   %ebp
  1009f1:	89 e5                	mov    %esp,%ebp
  1009f3:	83 ec 38             	sub    $0x38,%esp
	pageinfo *pp, *pp0, *pp1, *pp2;
	pageinfo *fl;
	int i;

        // if there's a page that shouldn't be on
        // the free list, try to make sure it
        // eventually causes trouble.
	int freepages = 0;
  1009f6:	c7 45 fc 00 00 00 00 	movl   $0x0,0xfffffffc(%ebp)
	for (pp = mem_freelist; pp != 0; pp = pp->free_next) {
  1009fd:	a1 70 7f 10 00       	mov    0x107f70,%eax
  100a02:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
  100a05:	eb 35                	jmp    100a3c <mem_check+0x4c>
		memset(mem_pi2ptr(pp), 0x97, 128);
  100a07:	8b 55 e4             	mov    0xffffffe4(%ebp),%edx
  100a0a:	a1 7c 7f 10 00       	mov    0x107f7c,%eax
  100a0f:	89 d1                	mov    %edx,%ecx
  100a11:	29 c1                	sub    %eax,%ecx
  100a13:	89 c8                	mov    %ecx,%eax
  100a15:	c1 e0 09             	shl    $0x9,%eax
  100a18:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
  100a1f:	00 
  100a20:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
  100a27:	00 
  100a28:	89 04 24             	mov    %eax,(%esp)
  100a2b:	e8 79 1c 00 00       	call   1026a9 <memset>
		freepages++;
  100a30:	83 45 fc 01          	addl   $0x1,0xfffffffc(%ebp)
  100a34:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  100a37:	8b 00                	mov    (%eax),%eax
  100a39:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
  100a3c:	83 7d e4 00          	cmpl   $0x0,0xffffffe4(%ebp)
  100a40:	75 c5                	jne    100a07 <mem_check+0x17>
	}
	cprintf("mem_check: %d free pages\n", freepages);
  100a42:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  100a45:	89 44 24 04          	mov    %eax,0x4(%esp)
  100a49:	c7 04 24 21 2f 10 00 	movl   $0x102f21,(%esp)
  100a50:	e8 5c 1a 00 00       	call   1024b1 <cprintf>
	assert(freepages < mem_npage);	// can't have more free than total!
  100a55:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  100a58:	a1 74 7f 10 00       	mov    0x107f74,%eax
  100a5d:	39 c2                	cmp    %eax,%edx
  100a5f:	72 24                	jb     100a85 <mem_check+0x95>
  100a61:	c7 44 24 0c 3b 2f 10 	movl   $0x102f3b,0xc(%esp)
  100a68:	00 
  100a69:	c7 44 24 08 ca 2e 10 	movl   $0x102eca,0x8(%esp)
  100a70:	00 
  100a71:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
  100a78:	00 
  100a79:	c7 04 24 50 2e 10 00 	movl   $0x102e50,(%esp)
  100a80:	e8 af f8 ff ff       	call   100334 <debug_panic>
	assert(freepages > 16000);	// make sure it's in the right ballpark
  100a85:	81 7d fc 80 3e 00 00 	cmpl   $0x3e80,0xfffffffc(%ebp)
  100a8c:	7f 24                	jg     100ab2 <mem_check+0xc2>
  100a8e:	c7 44 24 0c 51 2f 10 	movl   $0x102f51,0xc(%esp)
  100a95:	00 
  100a96:	c7 44 24 08 ca 2e 10 	movl   $0x102eca,0x8(%esp)
  100a9d:	00 
  100a9e:	c7 44 24 04 98 00 00 	movl   $0x98,0x4(%esp)
  100aa5:	00 
  100aa6:	c7 04 24 50 2e 10 00 	movl   $0x102e50,(%esp)
  100aad:	e8 82 f8 ff ff       	call   100334 <debug_panic>

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
  100ab2:	c7 45 f0 00 00 00 00 	movl   $0x0,0xfffffff0(%ebp)
  100ab9:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  100abc:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  100abf:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  100ac2:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
	pp0 = mem_alloc(); assert(pp0 != 0);
  100ac5:	e8 e2 fe ff ff       	call   1009ac <mem_alloc>
  100aca:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  100acd:	83 7d e8 00          	cmpl   $0x0,0xffffffe8(%ebp)
  100ad1:	75 24                	jne    100af7 <mem_check+0x107>
  100ad3:	c7 44 24 0c 63 2f 10 	movl   $0x102f63,0xc(%esp)
  100ada:	00 
  100adb:	c7 44 24 08 ca 2e 10 	movl   $0x102eca,0x8(%esp)
  100ae2:	00 
  100ae3:	c7 44 24 04 9c 00 00 	movl   $0x9c,0x4(%esp)
  100aea:	00 
  100aeb:	c7 04 24 50 2e 10 00 	movl   $0x102e50,(%esp)
  100af2:	e8 3d f8 ff ff       	call   100334 <debug_panic>
	pp1 = mem_alloc(); assert(pp1 != 0);
  100af7:	e8 b0 fe ff ff       	call   1009ac <mem_alloc>
  100afc:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  100aff:	83 7d ec 00          	cmpl   $0x0,0xffffffec(%ebp)
  100b03:	75 24                	jne    100b29 <mem_check+0x139>
  100b05:	c7 44 24 0c 6c 2f 10 	movl   $0x102f6c,0xc(%esp)
  100b0c:	00 
  100b0d:	c7 44 24 08 ca 2e 10 	movl   $0x102eca,0x8(%esp)
  100b14:	00 
  100b15:	c7 44 24 04 9d 00 00 	movl   $0x9d,0x4(%esp)
  100b1c:	00 
  100b1d:	c7 04 24 50 2e 10 00 	movl   $0x102e50,(%esp)
  100b24:	e8 0b f8 ff ff       	call   100334 <debug_panic>
	pp2 = mem_alloc(); assert(pp2 != 0);
  100b29:	e8 7e fe ff ff       	call   1009ac <mem_alloc>
  100b2e:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
  100b31:	83 7d f0 00          	cmpl   $0x0,0xfffffff0(%ebp)
  100b35:	75 24                	jne    100b5b <mem_check+0x16b>
  100b37:	c7 44 24 0c 75 2f 10 	movl   $0x102f75,0xc(%esp)
  100b3e:	00 
  100b3f:	c7 44 24 08 ca 2e 10 	movl   $0x102eca,0x8(%esp)
  100b46:	00 
  100b47:	c7 44 24 04 9e 00 00 	movl   $0x9e,0x4(%esp)
  100b4e:	00 
  100b4f:	c7 04 24 50 2e 10 00 	movl   $0x102e50,(%esp)
  100b56:	e8 d9 f7 ff ff       	call   100334 <debug_panic>

	assert(pp0);
  100b5b:	83 7d e8 00          	cmpl   $0x0,0xffffffe8(%ebp)
  100b5f:	75 24                	jne    100b85 <mem_check+0x195>
  100b61:	c7 44 24 0c 7e 2f 10 	movl   $0x102f7e,0xc(%esp)
  100b68:	00 
  100b69:	c7 44 24 08 ca 2e 10 	movl   $0x102eca,0x8(%esp)
  100b70:	00 
  100b71:	c7 44 24 04 a0 00 00 	movl   $0xa0,0x4(%esp)
  100b78:	00 
  100b79:	c7 04 24 50 2e 10 00 	movl   $0x102e50,(%esp)
  100b80:	e8 af f7 ff ff       	call   100334 <debug_panic>
	assert(pp1 && pp1 != pp0);
  100b85:	83 7d ec 00          	cmpl   $0x0,0xffffffec(%ebp)
  100b89:	74 08                	je     100b93 <mem_check+0x1a3>
  100b8b:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  100b8e:	3b 45 e8             	cmp    0xffffffe8(%ebp),%eax
  100b91:	75 24                	jne    100bb7 <mem_check+0x1c7>
  100b93:	c7 44 24 0c 82 2f 10 	movl   $0x102f82,0xc(%esp)
  100b9a:	00 
  100b9b:	c7 44 24 08 ca 2e 10 	movl   $0x102eca,0x8(%esp)
  100ba2:	00 
  100ba3:	c7 44 24 04 a1 00 00 	movl   $0xa1,0x4(%esp)
  100baa:	00 
  100bab:	c7 04 24 50 2e 10 00 	movl   $0x102e50,(%esp)
  100bb2:	e8 7d f7 ff ff       	call   100334 <debug_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
  100bb7:	83 7d f0 00          	cmpl   $0x0,0xfffffff0(%ebp)
  100bbb:	74 10                	je     100bcd <mem_check+0x1dd>
  100bbd:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  100bc0:	3b 45 ec             	cmp    0xffffffec(%ebp),%eax
  100bc3:	74 08                	je     100bcd <mem_check+0x1dd>
  100bc5:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  100bc8:	3b 45 e8             	cmp    0xffffffe8(%ebp),%eax
  100bcb:	75 24                	jne    100bf1 <mem_check+0x201>
  100bcd:	c7 44 24 0c 94 2f 10 	movl   $0x102f94,0xc(%esp)
  100bd4:	00 
  100bd5:	c7 44 24 08 ca 2e 10 	movl   $0x102eca,0x8(%esp)
  100bdc:	00 
  100bdd:	c7 44 24 04 a2 00 00 	movl   $0xa2,0x4(%esp)
  100be4:	00 
  100be5:	c7 04 24 50 2e 10 00 	movl   $0x102e50,(%esp)
  100bec:	e8 43 f7 ff ff       	call   100334 <debug_panic>
        assert(mem_pi2phys(pp0) < mem_npage*PAGESIZE);
  100bf1:	8b 55 e8             	mov    0xffffffe8(%ebp),%edx
  100bf4:	a1 7c 7f 10 00       	mov    0x107f7c,%eax
  100bf9:	89 d1                	mov    %edx,%ecx
  100bfb:	29 c1                	sub    %eax,%ecx
  100bfd:	89 c8                	mov    %ecx,%eax
  100bff:	c1 e0 09             	shl    $0x9,%eax
  100c02:	89 c2                	mov    %eax,%edx
  100c04:	a1 74 7f 10 00       	mov    0x107f74,%eax
  100c09:	c1 e0 0c             	shl    $0xc,%eax
  100c0c:	39 c2                	cmp    %eax,%edx
  100c0e:	72 24                	jb     100c34 <mem_check+0x244>
  100c10:	c7 44 24 0c b4 2f 10 	movl   $0x102fb4,0xc(%esp)
  100c17:	00 
  100c18:	c7 44 24 08 ca 2e 10 	movl   $0x102eca,0x8(%esp)
  100c1f:	00 
  100c20:	c7 44 24 04 a3 00 00 	movl   $0xa3,0x4(%esp)
  100c27:	00 
  100c28:	c7 04 24 50 2e 10 00 	movl   $0x102e50,(%esp)
  100c2f:	e8 00 f7 ff ff       	call   100334 <debug_panic>
        assert(mem_pi2phys(pp1) < mem_npage*PAGESIZE);
  100c34:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
  100c37:	a1 7c 7f 10 00       	mov    0x107f7c,%eax
  100c3c:	89 d1                	mov    %edx,%ecx
  100c3e:	29 c1                	sub    %eax,%ecx
  100c40:	89 c8                	mov    %ecx,%eax
  100c42:	c1 e0 09             	shl    $0x9,%eax
  100c45:	89 c2                	mov    %eax,%edx
  100c47:	a1 74 7f 10 00       	mov    0x107f74,%eax
  100c4c:	c1 e0 0c             	shl    $0xc,%eax
  100c4f:	39 c2                	cmp    %eax,%edx
  100c51:	72 24                	jb     100c77 <mem_check+0x287>
  100c53:	c7 44 24 0c dc 2f 10 	movl   $0x102fdc,0xc(%esp)
  100c5a:	00 
  100c5b:	c7 44 24 08 ca 2e 10 	movl   $0x102eca,0x8(%esp)
  100c62:	00 
  100c63:	c7 44 24 04 a4 00 00 	movl   $0xa4,0x4(%esp)
  100c6a:	00 
  100c6b:	c7 04 24 50 2e 10 00 	movl   $0x102e50,(%esp)
  100c72:	e8 bd f6 ff ff       	call   100334 <debug_panic>
        assert(mem_pi2phys(pp2) < mem_npage*PAGESIZE);
  100c77:	8b 55 f0             	mov    0xfffffff0(%ebp),%edx
  100c7a:	a1 7c 7f 10 00       	mov    0x107f7c,%eax
  100c7f:	89 d1                	mov    %edx,%ecx
  100c81:	29 c1                	sub    %eax,%ecx
  100c83:	89 c8                	mov    %ecx,%eax
  100c85:	c1 e0 09             	shl    $0x9,%eax
  100c88:	89 c2                	mov    %eax,%edx
  100c8a:	a1 74 7f 10 00       	mov    0x107f74,%eax
  100c8f:	c1 e0 0c             	shl    $0xc,%eax
  100c92:	39 c2                	cmp    %eax,%edx
  100c94:	72 24                	jb     100cba <mem_check+0x2ca>
  100c96:	c7 44 24 0c 04 30 10 	movl   $0x103004,0xc(%esp)
  100c9d:	00 
  100c9e:	c7 44 24 08 ca 2e 10 	movl   $0x102eca,0x8(%esp)
  100ca5:	00 
  100ca6:	c7 44 24 04 a5 00 00 	movl   $0xa5,0x4(%esp)
  100cad:	00 
  100cae:	c7 04 24 50 2e 10 00 	movl   $0x102e50,(%esp)
  100cb5:	e8 7a f6 ff ff       	call   100334 <debug_panic>

	// temporarily steal the rest of the free pages
	fl = mem_freelist;
  100cba:	a1 70 7f 10 00       	mov    0x107f70,%eax
  100cbf:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	mem_freelist = 0;
  100cc2:	c7 05 70 7f 10 00 00 	movl   $0x0,0x107f70
  100cc9:	00 00 00 

	// should be no free memory
	assert(mem_alloc() == 0);
  100ccc:	e8 db fc ff ff       	call   1009ac <mem_alloc>
  100cd1:	85 c0                	test   %eax,%eax
  100cd3:	74 24                	je     100cf9 <mem_check+0x309>
  100cd5:	c7 44 24 0c 2a 30 10 	movl   $0x10302a,0xc(%esp)
  100cdc:	00 
  100cdd:	c7 44 24 08 ca 2e 10 	movl   $0x102eca,0x8(%esp)
  100ce4:	00 
  100ce5:	c7 44 24 04 ac 00 00 	movl   $0xac,0x4(%esp)
  100cec:	00 
  100ced:	c7 04 24 50 2e 10 00 	movl   $0x102e50,(%esp)
  100cf4:	e8 3b f6 ff ff       	call   100334 <debug_panic>

        // free and re-allocate?
        mem_free(pp0);
  100cf9:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  100cfc:	89 04 24             	mov    %eax,(%esp)
  100cff:	e8 ca fc ff ff       	call   1009ce <mem_free>
        mem_free(pp1);
  100d04:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  100d07:	89 04 24             	mov    %eax,(%esp)
  100d0a:	e8 bf fc ff ff       	call   1009ce <mem_free>
        mem_free(pp2);
  100d0f:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  100d12:	89 04 24             	mov    %eax,(%esp)
  100d15:	e8 b4 fc ff ff       	call   1009ce <mem_free>
	pp0 = pp1 = pp2 = 0;
  100d1a:	c7 45 f0 00 00 00 00 	movl   $0x0,0xfffffff0(%ebp)
  100d21:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  100d24:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  100d27:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  100d2a:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
	pp0 = mem_alloc(); assert(pp0 != 0);
  100d2d:	e8 7a fc ff ff       	call   1009ac <mem_alloc>
  100d32:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  100d35:	83 7d e8 00          	cmpl   $0x0,0xffffffe8(%ebp)
  100d39:	75 24                	jne    100d5f <mem_check+0x36f>
  100d3b:	c7 44 24 0c 63 2f 10 	movl   $0x102f63,0xc(%esp)
  100d42:	00 
  100d43:	c7 44 24 08 ca 2e 10 	movl   $0x102eca,0x8(%esp)
  100d4a:	00 
  100d4b:	c7 44 24 04 b3 00 00 	movl   $0xb3,0x4(%esp)
  100d52:	00 
  100d53:	c7 04 24 50 2e 10 00 	movl   $0x102e50,(%esp)
  100d5a:	e8 d5 f5 ff ff       	call   100334 <debug_panic>
	pp1 = mem_alloc(); assert(pp1 != 0);
  100d5f:	e8 48 fc ff ff       	call   1009ac <mem_alloc>
  100d64:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  100d67:	83 7d ec 00          	cmpl   $0x0,0xffffffec(%ebp)
  100d6b:	75 24                	jne    100d91 <mem_check+0x3a1>
  100d6d:	c7 44 24 0c 6c 2f 10 	movl   $0x102f6c,0xc(%esp)
  100d74:	00 
  100d75:	c7 44 24 08 ca 2e 10 	movl   $0x102eca,0x8(%esp)
  100d7c:	00 
  100d7d:	c7 44 24 04 b4 00 00 	movl   $0xb4,0x4(%esp)
  100d84:	00 
  100d85:	c7 04 24 50 2e 10 00 	movl   $0x102e50,(%esp)
  100d8c:	e8 a3 f5 ff ff       	call   100334 <debug_panic>
	pp2 = mem_alloc(); assert(pp2 != 0);
  100d91:	e8 16 fc ff ff       	call   1009ac <mem_alloc>
  100d96:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
  100d99:	83 7d f0 00          	cmpl   $0x0,0xfffffff0(%ebp)
  100d9d:	75 24                	jne    100dc3 <mem_check+0x3d3>
  100d9f:	c7 44 24 0c 75 2f 10 	movl   $0x102f75,0xc(%esp)
  100da6:	00 
  100da7:	c7 44 24 08 ca 2e 10 	movl   $0x102eca,0x8(%esp)
  100dae:	00 
  100daf:	c7 44 24 04 b5 00 00 	movl   $0xb5,0x4(%esp)
  100db6:	00 
  100db7:	c7 04 24 50 2e 10 00 	movl   $0x102e50,(%esp)
  100dbe:	e8 71 f5 ff ff       	call   100334 <debug_panic>
	assert(pp0);
  100dc3:	83 7d e8 00          	cmpl   $0x0,0xffffffe8(%ebp)
  100dc7:	75 24                	jne    100ded <mem_check+0x3fd>
  100dc9:	c7 44 24 0c 7e 2f 10 	movl   $0x102f7e,0xc(%esp)
  100dd0:	00 
  100dd1:	c7 44 24 08 ca 2e 10 	movl   $0x102eca,0x8(%esp)
  100dd8:	00 
  100dd9:	c7 44 24 04 b6 00 00 	movl   $0xb6,0x4(%esp)
  100de0:	00 
  100de1:	c7 04 24 50 2e 10 00 	movl   $0x102e50,(%esp)
  100de8:	e8 47 f5 ff ff       	call   100334 <debug_panic>
	assert(pp1 && pp1 != pp0);
  100ded:	83 7d ec 00          	cmpl   $0x0,0xffffffec(%ebp)
  100df1:	74 08                	je     100dfb <mem_check+0x40b>
  100df3:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  100df6:	3b 45 e8             	cmp    0xffffffe8(%ebp),%eax
  100df9:	75 24                	jne    100e1f <mem_check+0x42f>
  100dfb:	c7 44 24 0c 82 2f 10 	movl   $0x102f82,0xc(%esp)
  100e02:	00 
  100e03:	c7 44 24 08 ca 2e 10 	movl   $0x102eca,0x8(%esp)
  100e0a:	00 
  100e0b:	c7 44 24 04 b7 00 00 	movl   $0xb7,0x4(%esp)
  100e12:	00 
  100e13:	c7 04 24 50 2e 10 00 	movl   $0x102e50,(%esp)
  100e1a:	e8 15 f5 ff ff       	call   100334 <debug_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
  100e1f:	83 7d f0 00          	cmpl   $0x0,0xfffffff0(%ebp)
  100e23:	74 10                	je     100e35 <mem_check+0x445>
  100e25:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  100e28:	3b 45 ec             	cmp    0xffffffec(%ebp),%eax
  100e2b:	74 08                	je     100e35 <mem_check+0x445>
  100e2d:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  100e30:	3b 45 e8             	cmp    0xffffffe8(%ebp),%eax
  100e33:	75 24                	jne    100e59 <mem_check+0x469>
  100e35:	c7 44 24 0c 94 2f 10 	movl   $0x102f94,0xc(%esp)
  100e3c:	00 
  100e3d:	c7 44 24 08 ca 2e 10 	movl   $0x102eca,0x8(%esp)
  100e44:	00 
  100e45:	c7 44 24 04 b8 00 00 	movl   $0xb8,0x4(%esp)
  100e4c:	00 
  100e4d:	c7 04 24 50 2e 10 00 	movl   $0x102e50,(%esp)
  100e54:	e8 db f4 ff ff       	call   100334 <debug_panic>
	assert(mem_alloc() == 0);
  100e59:	e8 4e fb ff ff       	call   1009ac <mem_alloc>
  100e5e:	85 c0                	test   %eax,%eax
  100e60:	74 24                	je     100e86 <mem_check+0x496>
  100e62:	c7 44 24 0c 2a 30 10 	movl   $0x10302a,0xc(%esp)
  100e69:	00 
  100e6a:	c7 44 24 08 ca 2e 10 	movl   $0x102eca,0x8(%esp)
  100e71:	00 
  100e72:	c7 44 24 04 b9 00 00 	movl   $0xb9,0x4(%esp)
  100e79:	00 
  100e7a:	c7 04 24 50 2e 10 00 	movl   $0x102e50,(%esp)
  100e81:	e8 ae f4 ff ff       	call   100334 <debug_panic>

	// give free list back
	mem_freelist = fl;
  100e86:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  100e89:	a3 70 7f 10 00       	mov    %eax,0x107f70

	// free the pages we took
	mem_free(pp0);
  100e8e:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  100e91:	89 04 24             	mov    %eax,(%esp)
  100e94:	e8 35 fb ff ff       	call   1009ce <mem_free>
	mem_free(pp1);
  100e99:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  100e9c:	89 04 24             	mov    %eax,(%esp)
  100e9f:	e8 2a fb ff ff       	call   1009ce <mem_free>
	mem_free(pp2);
  100ea4:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  100ea7:	89 04 24             	mov    %eax,(%esp)
  100eaa:	e8 1f fb ff ff       	call   1009ce <mem_free>

	cprintf("mem_check() succeeded!\n");
  100eaf:	c7 04 24 3b 30 10 00 	movl   $0x10303b,(%esp)
  100eb6:	e8 f6 15 00 00       	call   1024b1 <cprintf>
}
  100ebb:	c9                   	leave  
  100ebc:	c3                   	ret    
  100ebd:	90                   	nop    
  100ebe:	90                   	nop    
  100ebf:	90                   	nop    

00100ec0 <cpu_init>:
};


void cpu_init()
{
  100ec0:	55                   	push   %ebp
  100ec1:	89 e5                	mov    %esp,%ebp
  100ec3:	83 ec 18             	sub    $0x18,%esp
	cpu *c = cpu_cur();
  100ec6:	e8 47 00 00 00       	call   100f12 <cpu_cur>
  100ecb:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)

	// Load the GDT
	struct pseudodesc gdt_pd = {
		sizeof(c->gdt) - 1, (uint32_t) c->gdt };
  100ece:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  100ed1:	66 c7 45 f6 37 00    	movw   $0x37,0xfffffff6(%ebp)
  100ed7:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
	asm volatile("lgdt %0" : : "m" (gdt_pd));
  100eda:	0f 01 55 f6          	lgdtl  0xfffffff6(%ebp)

	// Reload all segment registers.
	asm volatile("movw %%ax,%%gs" :: "a" (CPU_GDT_UDATA|3));
  100ede:	b8 23 00 00 00       	mov    $0x23,%eax
  100ee3:	8e e8                	movl   %eax,%gs
	asm volatile("movw %%ax,%%fs" :: "a" (CPU_GDT_UDATA|3));
  100ee5:	b8 23 00 00 00       	mov    $0x23,%eax
  100eea:	8e e0                	movl   %eax,%fs
	asm volatile("movw %%ax,%%es" :: "a" (CPU_GDT_KDATA));
  100eec:	b8 10 00 00 00       	mov    $0x10,%eax
  100ef1:	8e c0                	movl   %eax,%es
	asm volatile("movw %%ax,%%ds" :: "a" (CPU_GDT_KDATA));
  100ef3:	b8 10 00 00 00       	mov    $0x10,%eax
  100ef8:	8e d8                	movl   %eax,%ds
	asm volatile("movw %%ax,%%ss" :: "a" (CPU_GDT_KDATA));
  100efa:	b8 10 00 00 00       	mov    $0x10,%eax
  100eff:	8e d0                	movl   %eax,%ss
	asm volatile("ljmp %0,$1f\n 1:\n" :: "i" (CPU_GDT_KCODE)); // reload CS
  100f01:	ea 08 0f 10 00 08 00 	ljmp   $0x8,$0x100f08

	// We don't need an LDT.
	asm volatile("lldt %%ax" :: "a" (0));
  100f08:	b8 00 00 00 00       	mov    $0x0,%eax
  100f0d:	0f 00 d0             	lldt   %ax
}
  100f10:	c9                   	leave  
  100f11:	c3                   	ret    

00100f12 <cpu_cur>:

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  100f12:	55                   	push   %ebp
  100f13:	89 e5                	mov    %esp,%ebp
  100f15:	83 ec 28             	sub    $0x28,%esp
static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  100f18:	89 65 fc             	mov    %esp,0xfffffffc(%ebp)
        return esp;
  100f1b:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  100f1e:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  100f21:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  100f24:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  100f29:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	assert(c->magic == CPU_MAGIC);
  100f2c:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  100f2f:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
  100f35:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  100f3a:	74 24                	je     100f60 <cpu_cur+0x4e>
  100f3c:	c7 44 24 0c 53 30 10 	movl   $0x103053,0xc(%esp)
  100f43:	00 
  100f44:	c7 44 24 08 69 30 10 	movl   $0x103069,0x8(%esp)
  100f4b:	00 
  100f4c:	c7 44 24 04 50 00 00 	movl   $0x50,0x4(%esp)
  100f53:	00 
  100f54:	c7 04 24 7e 30 10 00 	movl   $0x10307e,(%esp)
  100f5b:	e8 d4 f3 ff ff       	call   100334 <debug_panic>
	return c;
  100f60:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
}
  100f63:	c9                   	leave  
  100f64:	c3                   	ret    
  100f65:	90                   	nop    
  100f66:	90                   	nop    
  100f67:	90                   	nop    

00100f68 <trap_init_idt>:


static void
trap_init_idt(void)
{
  100f68:	55                   	push   %ebp
  100f69:	89 e5                	mov    %esp,%ebp
  100f6b:	83 ec 18             	sub    $0x18,%esp
	extern segdesc gdt[];
	
	panic("trap_init() not implemented.");
  100f6e:	c7 44 24 08 a0 30 10 	movl   $0x1030a0,0x8(%esp)
  100f75:	00 
  100f76:	c7 44 24 04 25 00 00 	movl   $0x25,0x4(%esp)
  100f7d:	00 
  100f7e:	c7 04 24 bd 30 10 00 	movl   $0x1030bd,(%esp)
  100f85:	e8 aa f3 ff ff       	call   100334 <debug_panic>

00100f8a <trap_init>:
}

void
trap_init(void)
{
  100f8a:	55                   	push   %ebp
  100f8b:	89 e5                	mov    %esp,%ebp
  100f8d:	83 ec 08             	sub    $0x8,%esp
	// The first time we get called on the bootstrap processor,
	// initialize the IDT.  Other CPUs will share the same IDT.
	if (cpu_onboot())
  100f90:	e8 20 00 00 00       	call   100fb5 <cpu_onboot>
  100f95:	85 c0                	test   %eax,%eax
  100f97:	74 05                	je     100f9e <trap_init+0x14>
		trap_init_idt();
  100f99:	e8 ca ff ff ff       	call   100f68 <trap_init_idt>

	// Load the IDT into this processor's IDT register.
	asm volatile("lidt %0" : : "m" (idt_pd));
  100f9e:	0f 01 1d 00 60 10 00 	lidtl  0x106000

	// Check for the correct IDT and trap handler operation.
	if (cpu_onboot())
  100fa5:	e8 0b 00 00 00       	call   100fb5 <cpu_onboot>
  100faa:	85 c0                	test   %eax,%eax
  100fac:	74 05                	je     100fb3 <trap_init+0x29>
		trap_check_kernel();
  100fae:	e8 da 02 00 00       	call   10128d <trap_check_kernel>
}
  100fb3:	c9                   	leave  
  100fb4:	c3                   	ret    

00100fb5 <cpu_onboot>:
}

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  100fb5:	55                   	push   %ebp
  100fb6:	89 e5                	mov    %esp,%ebp
  100fb8:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  100fbb:	e8 0d 00 00 00       	call   100fcd <cpu_cur>
  100fc0:	3d 00 50 10 00       	cmp    $0x105000,%eax
  100fc5:	0f 94 c0             	sete   %al
  100fc8:	0f b6 c0             	movzbl %al,%eax
}
  100fcb:	c9                   	leave  
  100fcc:	c3                   	ret    

00100fcd <cpu_cur>:
  100fcd:	55                   	push   %ebp
  100fce:	89 e5                	mov    %esp,%ebp
  100fd0:	83 ec 28             	sub    $0x28,%esp
static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  100fd3:	89 65 fc             	mov    %esp,0xfffffffc(%ebp)
        return esp;
  100fd6:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  100fd9:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  100fdc:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  100fdf:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  100fe4:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	assert(c->magic == CPU_MAGIC);
  100fe7:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  100fea:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
  100ff0:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  100ff5:	74 24                	je     10101b <cpu_cur+0x4e>
  100ff7:	c7 44 24 0c c9 30 10 	movl   $0x1030c9,0xc(%esp)
  100ffe:	00 
  100fff:	c7 44 24 08 df 30 10 	movl   $0x1030df,0x8(%esp)
  101006:	00 
  101007:	c7 44 24 04 50 00 00 	movl   $0x50,0x4(%esp)
  10100e:	00 
  10100f:	c7 04 24 f4 30 10 00 	movl   $0x1030f4,(%esp)
  101016:	e8 19 f3 ff ff       	call   100334 <debug_panic>
	return c;
  10101b:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
}
  10101e:	c9                   	leave  
  10101f:	c3                   	ret    

00101020 <trap_name>:

const char *trap_name(int trapno)
{
  101020:	55                   	push   %ebp
  101021:	89 e5                	mov    %esp,%ebp
  101023:	83 ec 04             	sub    $0x4,%esp
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
  101026:	8b 45 08             	mov    0x8(%ebp),%eax
  101029:	83 f8 13             	cmp    $0x13,%eax
  10102c:	77 0f                	ja     10103d <trap_name+0x1d>
		return excnames[trapno];
  10102e:	8b 45 08             	mov    0x8(%ebp),%eax
  101031:	8b 04 85 60 32 10 00 	mov    0x103260(,%eax,4),%eax
  101038:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
  10103b:	eb 07                	jmp    101044 <trap_name+0x24>
	return "(unknown trap)";
  10103d:	c7 45 fc eb 31 10 00 	movl   $0x1031eb,0xfffffffc(%ebp)
  101044:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
}
  101047:	c9                   	leave  
  101048:	c3                   	ret    

00101049 <trap_print_regs>:

void
trap_print_regs(pushregs *regs)
{
  101049:	55                   	push   %ebp
  10104a:	89 e5                	mov    %esp,%ebp
  10104c:	83 ec 08             	sub    $0x8,%esp
	cprintf("  edi  0x%08x\n", regs->edi);
  10104f:	8b 45 08             	mov    0x8(%ebp),%eax
  101052:	8b 00                	mov    (%eax),%eax
  101054:	89 44 24 04          	mov    %eax,0x4(%esp)
  101058:	c7 04 24 b0 32 10 00 	movl   $0x1032b0,(%esp)
  10105f:	e8 4d 14 00 00       	call   1024b1 <cprintf>
	cprintf("  esi  0x%08x\n", regs->esi);
  101064:	8b 45 08             	mov    0x8(%ebp),%eax
  101067:	8b 40 04             	mov    0x4(%eax),%eax
  10106a:	89 44 24 04          	mov    %eax,0x4(%esp)
  10106e:	c7 04 24 bf 32 10 00 	movl   $0x1032bf,(%esp)
  101075:	e8 37 14 00 00       	call   1024b1 <cprintf>
	cprintf("  ebp  0x%08x\n", regs->ebp);
  10107a:	8b 45 08             	mov    0x8(%ebp),%eax
  10107d:	8b 40 08             	mov    0x8(%eax),%eax
  101080:	89 44 24 04          	mov    %eax,0x4(%esp)
  101084:	c7 04 24 ce 32 10 00 	movl   $0x1032ce,(%esp)
  10108b:	e8 21 14 00 00       	call   1024b1 <cprintf>
//	cprintf("  oesp 0x%08x\n", regs->oesp);	don't print - useless
	cprintf("  ebx  0x%08x\n", regs->ebx);
  101090:	8b 45 08             	mov    0x8(%ebp),%eax
  101093:	8b 40 10             	mov    0x10(%eax),%eax
  101096:	89 44 24 04          	mov    %eax,0x4(%esp)
  10109a:	c7 04 24 dd 32 10 00 	movl   $0x1032dd,(%esp)
  1010a1:	e8 0b 14 00 00       	call   1024b1 <cprintf>
	cprintf("  edx  0x%08x\n", regs->edx);
  1010a6:	8b 45 08             	mov    0x8(%ebp),%eax
  1010a9:	8b 40 14             	mov    0x14(%eax),%eax
  1010ac:	89 44 24 04          	mov    %eax,0x4(%esp)
  1010b0:	c7 04 24 ec 32 10 00 	movl   $0x1032ec,(%esp)
  1010b7:	e8 f5 13 00 00       	call   1024b1 <cprintf>
	cprintf("  ecx  0x%08x\n", regs->ecx);
  1010bc:	8b 45 08             	mov    0x8(%ebp),%eax
  1010bf:	8b 40 18             	mov    0x18(%eax),%eax
  1010c2:	89 44 24 04          	mov    %eax,0x4(%esp)
  1010c6:	c7 04 24 fb 32 10 00 	movl   $0x1032fb,(%esp)
  1010cd:	e8 df 13 00 00       	call   1024b1 <cprintf>
	cprintf("  eax  0x%08x\n", regs->eax);
  1010d2:	8b 45 08             	mov    0x8(%ebp),%eax
  1010d5:	8b 40 1c             	mov    0x1c(%eax),%eax
  1010d8:	89 44 24 04          	mov    %eax,0x4(%esp)
  1010dc:	c7 04 24 0a 33 10 00 	movl   $0x10330a,(%esp)
  1010e3:	e8 c9 13 00 00       	call   1024b1 <cprintf>
}
  1010e8:	c9                   	leave  
  1010e9:	c3                   	ret    

001010ea <trap_print>:

void
trap_print(trapframe *tf)
{
  1010ea:	55                   	push   %ebp
  1010eb:	89 e5                	mov    %esp,%ebp
  1010ed:	83 ec 18             	sub    $0x18,%esp
	cprintf("TRAP frame at %p\n", tf);
  1010f0:	8b 45 08             	mov    0x8(%ebp),%eax
  1010f3:	89 44 24 04          	mov    %eax,0x4(%esp)
  1010f7:	c7 04 24 19 33 10 00 	movl   $0x103319,(%esp)
  1010fe:	e8 ae 13 00 00       	call   1024b1 <cprintf>
	trap_print_regs(&tf->regs);
  101103:	8b 45 08             	mov    0x8(%ebp),%eax
  101106:	89 04 24             	mov    %eax,(%esp)
  101109:	e8 3b ff ff ff       	call   101049 <trap_print_regs>
	cprintf("  es   0x----%04x\n", tf->es);
  10110e:	8b 45 08             	mov    0x8(%ebp),%eax
  101111:	0f b7 40 28          	movzwl 0x28(%eax),%eax
  101115:	0f b7 c0             	movzwl %ax,%eax
  101118:	89 44 24 04          	mov    %eax,0x4(%esp)
  10111c:	c7 04 24 2b 33 10 00 	movl   $0x10332b,(%esp)
  101123:	e8 89 13 00 00       	call   1024b1 <cprintf>
	cprintf("  ds   0x----%04x\n", tf->ds);
  101128:	8b 45 08             	mov    0x8(%ebp),%eax
  10112b:	0f b7 40 2c          	movzwl 0x2c(%eax),%eax
  10112f:	0f b7 c0             	movzwl %ax,%eax
  101132:	89 44 24 04          	mov    %eax,0x4(%esp)
  101136:	c7 04 24 3e 33 10 00 	movl   $0x10333e,(%esp)
  10113d:	e8 6f 13 00 00       	call   1024b1 <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->trapno, trap_name(tf->trapno));
  101142:	8b 45 08             	mov    0x8(%ebp),%eax
  101145:	8b 40 30             	mov    0x30(%eax),%eax
  101148:	89 04 24             	mov    %eax,(%esp)
  10114b:	e8 d0 fe ff ff       	call   101020 <trap_name>
  101150:	89 c2                	mov    %eax,%edx
  101152:	8b 45 08             	mov    0x8(%ebp),%eax
  101155:	8b 40 30             	mov    0x30(%eax),%eax
  101158:	89 54 24 08          	mov    %edx,0x8(%esp)
  10115c:	89 44 24 04          	mov    %eax,0x4(%esp)
  101160:	c7 04 24 51 33 10 00 	movl   $0x103351,(%esp)
  101167:	e8 45 13 00 00       	call   1024b1 <cprintf>
	cprintf("  err  0x%08x\n", tf->err);
  10116c:	8b 45 08             	mov    0x8(%ebp),%eax
  10116f:	8b 40 34             	mov    0x34(%eax),%eax
  101172:	89 44 24 04          	mov    %eax,0x4(%esp)
  101176:	c7 04 24 63 33 10 00 	movl   $0x103363,(%esp)
  10117d:	e8 2f 13 00 00       	call   1024b1 <cprintf>
	cprintf("  eip  0x%08x\n", tf->eip);
  101182:	8b 45 08             	mov    0x8(%ebp),%eax
  101185:	8b 40 38             	mov    0x38(%eax),%eax
  101188:	89 44 24 04          	mov    %eax,0x4(%esp)
  10118c:	c7 04 24 72 33 10 00 	movl   $0x103372,(%esp)
  101193:	e8 19 13 00 00       	call   1024b1 <cprintf>
	cprintf("  cs   0x----%04x\n", tf->cs);
  101198:	8b 45 08             	mov    0x8(%ebp),%eax
  10119b:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
  10119f:	0f b7 c0             	movzwl %ax,%eax
  1011a2:	89 44 24 04          	mov    %eax,0x4(%esp)
  1011a6:	c7 04 24 81 33 10 00 	movl   $0x103381,(%esp)
  1011ad:	e8 ff 12 00 00       	call   1024b1 <cprintf>
	cprintf("  flag 0x%08x\n", tf->eflags);
  1011b2:	8b 45 08             	mov    0x8(%ebp),%eax
  1011b5:	8b 40 40             	mov    0x40(%eax),%eax
  1011b8:	89 44 24 04          	mov    %eax,0x4(%esp)
  1011bc:	c7 04 24 94 33 10 00 	movl   $0x103394,(%esp)
  1011c3:	e8 e9 12 00 00       	call   1024b1 <cprintf>
	cprintf("  esp  0x%08x\n", tf->esp);
  1011c8:	8b 45 08             	mov    0x8(%ebp),%eax
  1011cb:	8b 40 44             	mov    0x44(%eax),%eax
  1011ce:	89 44 24 04          	mov    %eax,0x4(%esp)
  1011d2:	c7 04 24 a3 33 10 00 	movl   $0x1033a3,(%esp)
  1011d9:	e8 d3 12 00 00       	call   1024b1 <cprintf>
	cprintf("  ss   0x----%04x\n", tf->ss);
  1011de:	8b 45 08             	mov    0x8(%ebp),%eax
  1011e1:	0f b7 40 48          	movzwl 0x48(%eax),%eax
  1011e5:	0f b7 c0             	movzwl %ax,%eax
  1011e8:	89 44 24 04          	mov    %eax,0x4(%esp)
  1011ec:	c7 04 24 b2 33 10 00 	movl   $0x1033b2,(%esp)
  1011f3:	e8 b9 12 00 00       	call   1024b1 <cprintf>
}
  1011f8:	c9                   	leave  
  1011f9:	c3                   	ret    

001011fa <trap>:

void gcc_noreturn
trap(trapframe *tf)
{
  1011fa:	55                   	push   %ebp
  1011fb:	89 e5                	mov    %esp,%ebp
  1011fd:	83 ec 28             	sub    $0x28,%esp
	// The user-level environment may have set the DF flag,
	// and some versions of GCC rely on DF being clear.
	asm volatile("cld" ::: "cc");
  101200:	fc                   	cld    

	// If this trap was anticipated, just use the designated handler.
	cpu *c = cpu_cur();
  101201:	e8 c7 fd ff ff       	call   100fcd <cpu_cur>
  101206:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	if (c->recover)
  101209:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  10120c:	8b 80 a0 00 00 00    	mov    0xa0(%eax),%eax
  101212:	85 c0                	test   %eax,%eax
  101214:	74 1e                	je     101234 <trap+0x3a>
		c->recover(tf, c->recoverdata);
  101216:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  101219:	8b 90 a0 00 00 00    	mov    0xa0(%eax),%edx
  10121f:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  101222:	8b 80 a4 00 00 00    	mov    0xa4(%eax),%eax
  101228:	89 44 24 04          	mov    %eax,0x4(%esp)
  10122c:	8b 45 08             	mov    0x8(%ebp),%eax
  10122f:	89 04 24             	mov    %eax,(%esp)
  101232:	ff d2                	call   *%edx

	trap_print(tf);
  101234:	8b 45 08             	mov    0x8(%ebp),%eax
  101237:	89 04 24             	mov    %eax,(%esp)
  10123a:	e8 ab fe ff ff       	call   1010ea <trap_print>
	panic("unhandled trap");
  10123f:	c7 44 24 08 c5 33 10 	movl   $0x1033c5,0x8(%esp)
  101246:	00 
  101247:	c7 44 24 04 80 00 00 	movl   $0x80,0x4(%esp)
  10124e:	00 
  10124f:	c7 04 24 bd 30 10 00 	movl   $0x1030bd,(%esp)
  101256:	e8 d9 f0 ff ff       	call   100334 <debug_panic>

0010125b <trap_check_recover>:
}


// Helper function for trap_check_recover(), below:
// handles "anticipated" traps by simply resuming at a new EIP.
static void gcc_noreturn
trap_check_recover(trapframe *tf, void *recoverdata)
{
  10125b:	55                   	push   %ebp
  10125c:	89 e5                	mov    %esp,%ebp
  10125e:	83 ec 18             	sub    $0x18,%esp
	trap_check_args *args = recoverdata;
  101261:	8b 45 0c             	mov    0xc(%ebp),%eax
  101264:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	tf->eip = (uint32_t) args->reip;	// Use recovery EIP on return
  101267:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  10126a:	8b 00                	mov    (%eax),%eax
  10126c:	89 c2                	mov    %eax,%edx
  10126e:	8b 45 08             	mov    0x8(%ebp),%eax
  101271:	89 50 38             	mov    %edx,0x38(%eax)
	args->trapno = tf->trapno;		// Return trap number
  101274:	8b 45 08             	mov    0x8(%ebp),%eax
  101277:	8b 40 30             	mov    0x30(%eax),%eax
  10127a:	89 c2                	mov    %eax,%edx
  10127c:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  10127f:	89 50 04             	mov    %edx,0x4(%eax)
	trap_return(tf);
  101282:	8b 45 08             	mov    0x8(%ebp),%eax
  101285:	89 04 24             	mov    %eax,(%esp)
  101288:	e8 33 03 00 00       	call   1015c0 <trap_return>

0010128d <trap_check_kernel>:
}

// Check for correct handling of traps from kernel mode.
// Called on the boot CPU after trap_init() and trap_setup().
void
trap_check_kernel(void)
{
  10128d:	55                   	push   %ebp
  10128e:	89 e5                	mov    %esp,%ebp
  101290:	83 ec 28             	sub    $0x28,%esp
static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  101293:	8c 4d fe             	movw   %cs,0xfffffffe(%ebp)
        return cs;
  101296:	0f b7 45 fe          	movzwl 0xfffffffe(%ebp),%eax
	assert((read_cs() & 3) == 0);	// better be in kernel mode!
  10129a:	0f b7 c0             	movzwl %ax,%eax
  10129d:	83 e0 03             	and    $0x3,%eax
  1012a0:	85 c0                	test   %eax,%eax
  1012a2:	74 24                	je     1012c8 <trap_check_kernel+0x3b>
  1012a4:	c7 44 24 0c d4 33 10 	movl   $0x1033d4,0xc(%esp)
  1012ab:	00 
  1012ac:	c7 44 24 08 df 30 10 	movl   $0x1030df,0x8(%esp)
  1012b3:	00 
  1012b4:	c7 44 24 04 94 00 00 	movl   $0x94,0x4(%esp)
  1012bb:	00 
  1012bc:	c7 04 24 bd 30 10 00 	movl   $0x1030bd,(%esp)
  1012c3:	e8 6c f0 ff ff       	call   100334 <debug_panic>

	cpu *c = cpu_cur();
  1012c8:	e8 00 fd ff ff       	call   100fcd <cpu_cur>
  1012cd:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
	c->recover = trap_check_recover;
  1012d0:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1012d3:	c7 80 a0 00 00 00 5b 	movl   $0x10125b,0xa0(%eax)
  1012da:	12 10 00 
	trap_check(&c->recoverdata);
  1012dd:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1012e0:	05 a4 00 00 00       	add    $0xa4,%eax
  1012e5:	89 04 24             	mov    %eax,(%esp)
  1012e8:	e8 96 00 00 00       	call   101383 <trap_check>
	c->recover = NULL;	// No more mr. nice-guy; traps are real again
  1012ed:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1012f0:	c7 80 a0 00 00 00 00 	movl   $0x0,0xa0(%eax)
  1012f7:	00 00 00 

	cprintf("trap_check_kernel() succeeded!\n");
  1012fa:	c7 04 24 ec 33 10 00 	movl   $0x1033ec,(%esp)
  101301:	e8 ab 11 00 00       	call   1024b1 <cprintf>
}
  101306:	c9                   	leave  
  101307:	c3                   	ret    

00101308 <trap_check_user>:

// Check for correct handling of traps from user mode.
// Called from user() in kern/init.c, only in lab 1.
// We assume the "current cpu" is always the boot cpu;
// this true only because lab 1 doesn't start any other CPUs.
void
trap_check_user(void)
{
  101308:	55                   	push   %ebp
  101309:	89 e5                	mov    %esp,%ebp
  10130b:	83 ec 28             	sub    $0x28,%esp
static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  10130e:	8c 4d fe             	movw   %cs,0xfffffffe(%ebp)
        return cs;
  101311:	0f b7 45 fe          	movzwl 0xfffffffe(%ebp),%eax
	assert((read_cs() & 3) == 3);	// better be in user mode!
  101315:	0f b7 c0             	movzwl %ax,%eax
  101318:	83 e0 03             	and    $0x3,%eax
  10131b:	83 f8 03             	cmp    $0x3,%eax
  10131e:	74 24                	je     101344 <trap_check_user+0x3c>
  101320:	c7 44 24 0c 0c 34 10 	movl   $0x10340c,0xc(%esp)
  101327:	00 
  101328:	c7 44 24 08 df 30 10 	movl   $0x1030df,0x8(%esp)
  10132f:	00 
  101330:	c7 44 24 04 a5 00 00 	movl   $0xa5,0x4(%esp)
  101337:	00 
  101338:	c7 04 24 bd 30 10 00 	movl   $0x1030bd,(%esp)
  10133f:	e8 f0 ef ff ff       	call   100334 <debug_panic>

	cpu *c = &cpu_boot;	// cpu_cur doesn't work from user mode!
  101344:	c7 45 f8 00 50 10 00 	movl   $0x105000,0xfffffff8(%ebp)
	c->recover = trap_check_recover;
  10134b:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10134e:	c7 80 a0 00 00 00 5b 	movl   $0x10125b,0xa0(%eax)
  101355:	12 10 00 
	trap_check(&c->recoverdata);
  101358:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10135b:	05 a4 00 00 00       	add    $0xa4,%eax
  101360:	89 04 24             	mov    %eax,(%esp)
  101363:	e8 1b 00 00 00       	call   101383 <trap_check>
	c->recover = NULL;	// No more mr. nice-guy; traps are real again
  101368:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10136b:	c7 80 a0 00 00 00 00 	movl   $0x0,0xa0(%eax)
  101372:	00 00 00 

	cprintf("trap_check_user() succeeded!\n");
  101375:	c7 04 24 21 34 10 00 	movl   $0x103421,(%esp)
  10137c:	e8 30 11 00 00       	call   1024b1 <cprintf>
}
  101381:	c9                   	leave  
  101382:	c3                   	ret    

00101383 <trap_check>:

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
  101383:	55                   	push   %ebp
  101384:	89 e5                	mov    %esp,%ebp
  101386:	57                   	push   %edi
  101387:	56                   	push   %esi
  101388:	53                   	push   %ebx
  101389:	83 ec 3c             	sub    $0x3c,%esp
	volatile int cookie = 0xfeedface;
  10138c:	c7 45 ec ce fa ed fe 	movl   $0xfeedface,0xffffffec(%ebp)
	volatile trap_check_args args;
	*argsp = (void*)&args;	// provide args needed for trap recovery
  101393:	8b 55 08             	mov    0x8(%ebp),%edx
  101396:	8d 45 e4             	lea    0xffffffe4(%ebp),%eax
  101399:	89 02                	mov    %eax,(%edx)

	// Try a divide by zero trap.
	// Be careful when using && to take the address of a label:
	// some versions of GCC (4.4.2 at least) will incorrectly try to
	// eliminate code it thinks is _only_ reachable via such a pointer.
	args.reip = after_div0;
  10139b:	c7 45 e4 a9 13 10 00 	movl   $0x1013a9,0xffffffe4(%ebp)
	asm volatile("div %0,%0; after_div0:" : : "r" (0));
  1013a2:	b8 00 00 00 00       	mov    $0x0,%eax
  1013a7:	f7 f0                	div    %eax

001013a9 <after_div0>:
	assert(args.trapno == T_DIVIDE);
  1013a9:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  1013ac:	85 c0                	test   %eax,%eax
  1013ae:	74 24                	je     1013d4 <after_div0+0x2b>
  1013b0:	c7 44 24 0c 3f 34 10 	movl   $0x10343f,0xc(%esp)
  1013b7:	00 
  1013b8:	c7 44 24 08 df 30 10 	movl   $0x1030df,0x8(%esp)
  1013bf:	00 
  1013c0:	c7 44 24 04 c5 00 00 	movl   $0xc5,0x4(%esp)
  1013c7:	00 
  1013c8:	c7 04 24 bd 30 10 00 	movl   $0x1030bd,(%esp)
  1013cf:	e8 60 ef ff ff       	call   100334 <debug_panic>

	// Make sure we got our correct stack back with us.
	// The asm ensures gcc uses ebp/esp to get the cookie.
	asm volatile("" : : : "eax","ebx","ecx","edx","esi","edi");
	assert(cookie == 0xfeedface);
  1013d4:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  1013d7:	3d ce fa ed fe       	cmp    $0xfeedface,%eax
  1013dc:	74 24                	je     101402 <after_div0+0x59>
  1013de:	c7 44 24 0c 57 34 10 	movl   $0x103457,0xc(%esp)
  1013e5:	00 
  1013e6:	c7 44 24 08 df 30 10 	movl   $0x1030df,0x8(%esp)
  1013ed:	00 
  1013ee:	c7 44 24 04 ca 00 00 	movl   $0xca,0x4(%esp)
  1013f5:	00 
  1013f6:	c7 04 24 bd 30 10 00 	movl   $0x1030bd,(%esp)
  1013fd:	e8 32 ef ff ff       	call   100334 <debug_panic>

	// Breakpoint trap
	args.reip = after_breakpoint;
  101402:	c7 45 e4 0a 14 10 00 	movl   $0x10140a,0xffffffe4(%ebp)
	asm volatile("int3; after_breakpoint:");
  101409:	cc                   	int3   

0010140a <after_breakpoint>:
	assert(args.trapno == T_BRKPT);
  10140a:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  10140d:	83 f8 03             	cmp    $0x3,%eax
  101410:	74 24                	je     101436 <after_breakpoint+0x2c>
  101412:	c7 44 24 0c 6c 34 10 	movl   $0x10346c,0xc(%esp)
  101419:	00 
  10141a:	c7 44 24 08 df 30 10 	movl   $0x1030df,0x8(%esp)
  101421:	00 
  101422:	c7 44 24 04 cf 00 00 	movl   $0xcf,0x4(%esp)
  101429:	00 
  10142a:	c7 04 24 bd 30 10 00 	movl   $0x1030bd,(%esp)
  101431:	e8 fe ee ff ff       	call   100334 <debug_panic>

	// Overflow trap
	args.reip = after_overflow;
  101436:	c7 45 e4 45 14 10 00 	movl   $0x101445,0xffffffe4(%ebp)
	asm volatile("addl %0,%0; into; after_overflow:" : : "r" (0x70000000));
  10143d:	b8 00 00 00 70       	mov    $0x70000000,%eax
  101442:	01 c0                	add    %eax,%eax
  101444:	ce                   	into   

00101445 <after_overflow>:
	assert(args.trapno == T_OFLOW);
  101445:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  101448:	83 f8 04             	cmp    $0x4,%eax
  10144b:	74 24                	je     101471 <after_overflow+0x2c>
  10144d:	c7 44 24 0c 83 34 10 	movl   $0x103483,0xc(%esp)
  101454:	00 
  101455:	c7 44 24 08 df 30 10 	movl   $0x1030df,0x8(%esp)
  10145c:	00 
  10145d:	c7 44 24 04 d4 00 00 	movl   $0xd4,0x4(%esp)
  101464:	00 
  101465:	c7 04 24 bd 30 10 00 	movl   $0x1030bd,(%esp)
  10146c:	e8 c3 ee ff ff       	call   100334 <debug_panic>

	// Bounds trap
	args.reip = after_bound;
  101471:	c7 45 e4 8e 14 10 00 	movl   $0x10148e,0xffffffe4(%ebp)
	int bounds[2] = { 1, 3 };
  101478:	c7 45 dc 01 00 00 00 	movl   $0x1,0xffffffdc(%ebp)
  10147f:	c7 45 e0 03 00 00 00 	movl   $0x3,0xffffffe0(%ebp)
	asm volatile("boundl %0,%1; after_bound:" : : "r" (0), "m" (bounds[0]));
  101486:	b8 00 00 00 00       	mov    $0x0,%eax
  10148b:	62 45 dc             	bound  %eax,0xffffffdc(%ebp)

0010148e <after_bound>:
	assert(args.trapno == T_BOUND);
  10148e:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  101491:	83 f8 05             	cmp    $0x5,%eax
  101494:	74 24                	je     1014ba <after_bound+0x2c>
  101496:	c7 44 24 0c 9a 34 10 	movl   $0x10349a,0xc(%esp)
  10149d:	00 
  10149e:	c7 44 24 08 df 30 10 	movl   $0x1030df,0x8(%esp)
  1014a5:	00 
  1014a6:	c7 44 24 04 da 00 00 	movl   $0xda,0x4(%esp)
  1014ad:	00 
  1014ae:	c7 04 24 bd 30 10 00 	movl   $0x1030bd,(%esp)
  1014b5:	e8 7a ee ff ff       	call   100334 <debug_panic>

	// Illegal instruction trap
	args.reip = after_illegal;
  1014ba:	c7 45 e4 c3 14 10 00 	movl   $0x1014c3,0xffffffe4(%ebp)
	asm volatile("ud2; after_illegal:");	// guaranteed to be undefined
  1014c1:	0f 0b                	ud2a   

001014c3 <after_illegal>:
	assert(args.trapno == T_ILLOP);
  1014c3:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  1014c6:	83 f8 06             	cmp    $0x6,%eax
  1014c9:	74 24                	je     1014ef <after_illegal+0x2c>
  1014cb:	c7 44 24 0c b1 34 10 	movl   $0x1034b1,0xc(%esp)
  1014d2:	00 
  1014d3:	c7 44 24 08 df 30 10 	movl   $0x1030df,0x8(%esp)
  1014da:	00 
  1014db:	c7 44 24 04 df 00 00 	movl   $0xdf,0x4(%esp)
  1014e2:	00 
  1014e3:	c7 04 24 bd 30 10 00 	movl   $0x1030bd,(%esp)
  1014ea:	e8 45 ee ff ff       	call   100334 <debug_panic>

	// General protection fault due to invalid segment load
	args.reip = after_gpfault;
  1014ef:	c7 45 e4 fd 14 10 00 	movl   $0x1014fd,0xffffffe4(%ebp)
	asm volatile("movl %0,%%fs; after_gpfault:" : : "r" (-1));
  1014f6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  1014fb:	8e e0                	movl   %eax,%fs

001014fd <after_gpfault>:
	assert(args.trapno == T_GPFLT);
  1014fd:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  101500:	83 f8 0d             	cmp    $0xd,%eax
  101503:	74 24                	je     101529 <after_gpfault+0x2c>
  101505:	c7 44 24 0c c8 34 10 	movl   $0x1034c8,0xc(%esp)
  10150c:	00 
  10150d:	c7 44 24 08 df 30 10 	movl   $0x1030df,0x8(%esp)
  101514:	00 
  101515:	c7 44 24 04 e4 00 00 	movl   $0xe4,0x4(%esp)
  10151c:	00 
  10151d:	c7 04 24 bd 30 10 00 	movl   $0x1030bd,(%esp)
  101524:	e8 0b ee ff ff       	call   100334 <debug_panic>
static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  101529:	8c 4d f2             	movw   %cs,0xfffffff2(%ebp)
        return cs;
  10152c:	0f b7 45 f2          	movzwl 0xfffffff2(%ebp),%eax

	// General protection fault due to privilege violation
	if (read_cs() & 3) {
  101530:	0f b7 c0             	movzwl %ax,%eax
  101533:	83 e0 03             	and    $0x3,%eax
  101536:	85 c0                	test   %eax,%eax
  101538:	74 3a                	je     101574 <after_priv+0x2c>
		args.reip = after_priv;
  10153a:	c7 45 e4 48 15 10 00 	movl   $0x101548,0xffffffe4(%ebp)
		asm volatile("lidt %0; after_priv:" : : "m" (idt_pd));
  101541:	0f 01 1d 00 60 10 00 	lidtl  0x106000

00101548 <after_priv>:
		assert(args.trapno == T_GPFLT);
  101548:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  10154b:	83 f8 0d             	cmp    $0xd,%eax
  10154e:	74 24                	je     101574 <after_priv+0x2c>
  101550:	c7 44 24 0c c8 34 10 	movl   $0x1034c8,0xc(%esp)
  101557:	00 
  101558:	c7 44 24 08 df 30 10 	movl   $0x1030df,0x8(%esp)
  10155f:	00 
  101560:	c7 44 24 04 ea 00 00 	movl   $0xea,0x4(%esp)
  101567:	00 
  101568:	c7 04 24 bd 30 10 00 	movl   $0x1030bd,(%esp)
  10156f:	e8 c0 ed ff ff       	call   100334 <debug_panic>
	}

	// Make sure our stack cookie is still with us
	assert(cookie == 0xfeedface);
  101574:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  101577:	3d ce fa ed fe       	cmp    $0xfeedface,%eax
  10157c:	74 24                	je     1015a2 <after_priv+0x5a>
  10157e:	c7 44 24 0c 57 34 10 	movl   $0x103457,0xc(%esp)
  101585:	00 
  101586:	c7 44 24 08 df 30 10 	movl   $0x1030df,0x8(%esp)
  10158d:	00 
  10158e:	c7 44 24 04 ee 00 00 	movl   $0xee,0x4(%esp)
  101595:	00 
  101596:	c7 04 24 bd 30 10 00 	movl   $0x1030bd,(%esp)
  10159d:	e8 92 ed ff ff       	call   100334 <debug_panic>

	*argsp = NULL;	// recovery mechanism not needed anymore
  1015a2:	8b 45 08             	mov    0x8(%ebp),%eax
  1015a5:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}
  1015ab:	83 c4 3c             	add    $0x3c,%esp
  1015ae:	5b                   	pop    %ebx
  1015af:	5e                   	pop    %esi
  1015b0:	5f                   	pop    %edi
  1015b1:	5d                   	pop    %ebp
  1015b2:	c3                   	ret    
  1015b3:	90                   	nop    
  1015b4:	90                   	nop    
  1015b5:	90                   	nop    
  1015b6:	90                   	nop    
  1015b7:	90                   	nop    
  1015b8:	90                   	nop    
  1015b9:	90                   	nop    
  1015ba:	90                   	nop    
  1015bb:	90                   	nop    
  1015bc:	90                   	nop    
  1015bd:	90                   	nop    
  1015be:	90                   	nop    
  1015bf:	90                   	nop    

001015c0 <trap_return>:
trap_return:
/*
 * Lab 1: Your code here for trap_return
 */
1:	jmp	1b		// just spin
  1015c0:	eb fe                	jmp    1015c0 <trap_return>
  1015c2:	90                   	nop    
  1015c3:	90                   	nop    

001015c4 <video_init>:
static uint16_t crt_pos;

void
video_init(void)
{
  1015c4:	55                   	push   %ebp
  1015c5:	89 e5                	mov    %esp,%ebp
  1015c7:	83 ec 30             	sub    $0x30,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	/* Get a pointer to the memory-mapped text display buffer. */
	cp = (uint16_t*) mem_ptr(CGA_BUF);
  1015ca:	c7 45 d4 00 80 0b 00 	movl   $0xb8000,0xffffffd4(%ebp)
	was = *cp;
  1015d1:	8b 45 d4             	mov    0xffffffd4(%ebp),%eax
  1015d4:	0f b7 00             	movzwl (%eax),%eax
  1015d7:	66 89 45 da          	mov    %ax,0xffffffda(%ebp)
	*cp = (uint16_t) 0xA55A;
  1015db:	8b 45 d4             	mov    0xffffffd4(%ebp),%eax
  1015de:	66 c7 00 5a a5       	movw   $0xa55a,(%eax)
	if (*cp != 0xA55A) {
  1015e3:	8b 45 d4             	mov    0xffffffd4(%ebp),%eax
  1015e6:	0f b7 00             	movzwl (%eax),%eax
  1015e9:	66 3d 5a a5          	cmp    $0xa55a,%ax
  1015ed:	74 13                	je     101602 <video_init+0x3e>
		cp = (uint16_t*) mem_ptr(MONO_BUF);
  1015ef:	c7 45 d4 00 00 0b 00 	movl   $0xb0000,0xffffffd4(%ebp)
		addr_6845 = MONO_BASE;
  1015f6:	c7 05 60 7f 10 00 b4 	movl   $0x3b4,0x107f60
  1015fd:	03 00 00 
  101600:	eb 14                	jmp    101616 <video_init+0x52>
	} else {
		*cp = was;
  101602:	8b 55 d4             	mov    0xffffffd4(%ebp),%edx
  101605:	0f b7 45 da          	movzwl 0xffffffda(%ebp),%eax
  101609:	66 89 02             	mov    %ax,(%edx)
		addr_6845 = CGA_BASE;
  10160c:	c7 05 60 7f 10 00 d4 	movl   $0x3d4,0x107f60
  101613:	03 00 00 
	}
	
	/* Extract cursor location */
	outb(addr_6845, 14);
  101616:	a1 60 7f 10 00       	mov    0x107f60,%eax
  10161b:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
  10161e:	c6 45 e3 0e          	movb   $0xe,0xffffffe3(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  101622:	0f b6 45 e3          	movzbl 0xffffffe3(%ebp),%eax
  101626:	8b 55 e4             	mov    0xffffffe4(%ebp),%edx
  101629:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
  10162a:	a1 60 7f 10 00       	mov    0x107f60,%eax
  10162f:	83 c0 01             	add    $0x1,%eax
  101632:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101635:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
  101638:	ec                   	in     (%dx),%al
  101639:	88 45 eb             	mov    %al,0xffffffeb(%ebp)
	return data;
  10163c:	0f b6 45 eb          	movzbl 0xffffffeb(%ebp),%eax
  101640:	0f b6 c0             	movzbl %al,%eax
  101643:	c1 e0 08             	shl    $0x8,%eax
  101646:	89 45 dc             	mov    %eax,0xffffffdc(%ebp)
	outb(addr_6845, 15);
  101649:	a1 60 7f 10 00       	mov    0x107f60,%eax
  10164e:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
  101651:	c6 45 f3 0f          	movb   $0xf,0xfffffff3(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  101655:	0f b6 45 f3          	movzbl 0xfffffff3(%ebp),%eax
  101659:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  10165c:	ee                   	out    %al,(%dx)
	pos |= inb(addr_6845 + 1);
  10165d:	a1 60 7f 10 00       	mov    0x107f60,%eax
  101662:	83 c0 01             	add    $0x1,%eax
  101665:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101668:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  10166b:	ec                   	in     (%dx),%al
  10166c:	88 45 fb             	mov    %al,0xfffffffb(%ebp)
	return data;
  10166f:	0f b6 45 fb          	movzbl 0xfffffffb(%ebp),%eax
  101673:	0f b6 c0             	movzbl %al,%eax
  101676:	09 45 dc             	or     %eax,0xffffffdc(%ebp)

	crt_buf = (uint16_t*) cp;
  101679:	8b 45 d4             	mov    0xffffffd4(%ebp),%eax
  10167c:	a3 64 7f 10 00       	mov    %eax,0x107f64
	crt_pos = pos;
  101681:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  101684:	66 a3 68 7f 10 00    	mov    %ax,0x107f68
}
  10168a:	c9                   	leave  
  10168b:	c3                   	ret    

0010168c <video_putc>:



void
video_putc(int c)
{
  10168c:	55                   	push   %ebp
  10168d:	89 e5                	mov    %esp,%ebp
  10168f:	53                   	push   %ebx
  101690:	83 ec 44             	sub    $0x44,%esp
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
  101693:	8b 45 08             	mov    0x8(%ebp),%eax
  101696:	b0 00                	mov    $0x0,%al
  101698:	85 c0                	test   %eax,%eax
  10169a:	75 07                	jne    1016a3 <video_putc+0x17>
		c |= 0x0700;
  10169c:	81 4d 08 00 07 00 00 	orl    $0x700,0x8(%ebp)

	switch (c & 0xff) {
  1016a3:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
  1016a7:	89 45 c4             	mov    %eax,0xffffffc4(%ebp)
  1016aa:	83 7d c4 09          	cmpl   $0x9,0xffffffc4(%ebp)
  1016ae:	0f 84 c0 00 00 00    	je     101774 <video_putc+0xe8>
  1016b4:	83 7d c4 09          	cmpl   $0x9,0xffffffc4(%ebp)
  1016b8:	7f 0b                	jg     1016c5 <video_putc+0x39>
  1016ba:	83 7d c4 08          	cmpl   $0x8,0xffffffc4(%ebp)
  1016be:	74 16                	je     1016d6 <video_putc+0x4a>
  1016c0:	e9 ed 00 00 00       	jmp    1017b2 <video_putc+0x126>
  1016c5:	83 7d c4 0a          	cmpl   $0xa,0xffffffc4(%ebp)
  1016c9:	74 50                	je     10171b <video_putc+0x8f>
  1016cb:	83 7d c4 0d          	cmpl   $0xd,0xffffffc4(%ebp)
  1016cf:	74 5a                	je     10172b <video_putc+0x9f>
  1016d1:	e9 dc 00 00 00       	jmp    1017b2 <video_putc+0x126>
	case '\b':
		if (crt_pos > 0) {
  1016d6:	0f b7 05 68 7f 10 00 	movzwl 0x107f68,%eax
  1016dd:	66 85 c0             	test   %ax,%ax
  1016e0:	0f 84 f0 00 00 00    	je     1017d6 <video_putc+0x14a>
			crt_pos--;
  1016e6:	0f b7 05 68 7f 10 00 	movzwl 0x107f68,%eax
  1016ed:	83 e8 01             	sub    $0x1,%eax
  1016f0:	66 a3 68 7f 10 00    	mov    %ax,0x107f68
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
  1016f6:	0f b7 05 68 7f 10 00 	movzwl 0x107f68,%eax
  1016fd:	0f b7 c0             	movzwl %ax,%eax
  101700:	01 c0                	add    %eax,%eax
  101702:	89 c2                	mov    %eax,%edx
  101704:	a1 64 7f 10 00       	mov    0x107f64,%eax
  101709:	01 c2                	add    %eax,%edx
  10170b:	8b 45 08             	mov    0x8(%ebp),%eax
  10170e:	b0 00                	mov    $0x0,%al
  101710:	83 c8 20             	or     $0x20,%eax
  101713:	66 89 02             	mov    %ax,(%edx)
		}
		break;
  101716:	e9 bb 00 00 00       	jmp    1017d6 <video_putc+0x14a>
	case '\n':
		crt_pos += CRT_COLS;
  10171b:	0f b7 05 68 7f 10 00 	movzwl 0x107f68,%eax
  101722:	83 c0 50             	add    $0x50,%eax
  101725:	66 a3 68 7f 10 00    	mov    %ax,0x107f68
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
  10172b:	0f b7 0d 68 7f 10 00 	movzwl 0x107f68,%ecx
  101732:	0f b7 15 68 7f 10 00 	movzwl 0x107f68,%edx
  101739:	0f b7 c2             	movzwl %dx,%eax
  10173c:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
  101742:	c1 e8 10             	shr    $0x10,%eax
  101745:	89 c3                	mov    %eax,%ebx
  101747:	66 c1 eb 06          	shr    $0x6,%bx
  10174b:	66 89 5d ca          	mov    %bx,0xffffffca(%ebp)
  10174f:	0f b7 45 ca          	movzwl 0xffffffca(%ebp),%eax
  101753:	c1 e0 02             	shl    $0x2,%eax
  101756:	66 03 45 ca          	add    0xffffffca(%ebp),%ax
  10175a:	c1 e0 04             	shl    $0x4,%eax
  10175d:	89 d3                	mov    %edx,%ebx
  10175f:	66 29 c3             	sub    %ax,%bx
  101762:	66 89 5d ca          	mov    %bx,0xffffffca(%ebp)
  101766:	89 c8                	mov    %ecx,%eax
  101768:	66 2b 45 ca          	sub    0xffffffca(%ebp),%ax
  10176c:	66 a3 68 7f 10 00    	mov    %ax,0x107f68
		break;
  101772:	eb 62                	jmp    1017d6 <video_putc+0x14a>
	case '\t':
		video_putc(' ');
  101774:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  10177b:	e8 0c ff ff ff       	call   10168c <video_putc>
		video_putc(' ');
  101780:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  101787:	e8 00 ff ff ff       	call   10168c <video_putc>
		video_putc(' ');
  10178c:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  101793:	e8 f4 fe ff ff       	call   10168c <video_putc>
		video_putc(' ');
  101798:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  10179f:	e8 e8 fe ff ff       	call   10168c <video_putc>
		video_putc(' ');
  1017a4:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  1017ab:	e8 dc fe ff ff       	call   10168c <video_putc>
		break;
  1017b0:	eb 24                	jmp    1017d6 <video_putc+0x14a>
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
  1017b2:	0f b7 0d 68 7f 10 00 	movzwl 0x107f68,%ecx
  1017b9:	0f b7 c1             	movzwl %cx,%eax
  1017bc:	01 c0                	add    %eax,%eax
  1017be:	89 c2                	mov    %eax,%edx
  1017c0:	a1 64 7f 10 00       	mov    0x107f64,%eax
  1017c5:	01 c2                	add    %eax,%edx
  1017c7:	8b 45 08             	mov    0x8(%ebp),%eax
  1017ca:	66 89 02             	mov    %ax,(%edx)
  1017cd:	8d 41 01             	lea    0x1(%ecx),%eax
  1017d0:	66 a3 68 7f 10 00    	mov    %ax,0x107f68
		break;
	}

	// What is the purpose of this?
  // if the crt position is creater than the crt area
	if (crt_pos >= CRT_SIZE) {
  1017d6:	0f b7 05 68 7f 10 00 	movzwl 0x107f68,%eax
  1017dd:	66 3d cf 07          	cmp    $0x7cf,%ax
  1017e1:	76 5e                	jbe    101841 <video_putc+0x1b5>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS,
  1017e3:	a1 64 7f 10 00       	mov    0x107f64,%eax
  1017e8:	05 a0 00 00 00       	add    $0xa0,%eax
  1017ed:	8b 15 64 7f 10 00    	mov    0x107f64,%edx
  1017f3:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
  1017fa:	00 
  1017fb:	89 44 24 04          	mov    %eax,0x4(%esp)
  1017ff:	89 14 24             	mov    %edx,(%esp)
  101802:	e8 1b 0f 00 00       	call   102722 <memmove>
			(CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
  101807:	c7 45 d8 80 07 00 00 	movl   $0x780,0xffffffd8(%ebp)
  10180e:	eb 18                	jmp    101828 <video_putc+0x19c>
			// crt_buf[i] = 0x0700 | ' ';
			crt_buf[i] = 0x0700 | ' ';
  101810:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  101813:	01 c0                	add    %eax,%eax
  101815:	89 c2                	mov    %eax,%edx
  101817:	a1 64 7f 10 00       	mov    0x107f64,%eax
  10181c:	8d 04 02             	lea    (%edx,%eax,1),%eax
  10181f:	66 c7 00 20 07       	movw   $0x720,(%eax)
  101824:	83 45 d8 01          	addl   $0x1,0xffffffd8(%ebp)
  101828:	81 7d d8 cf 07 00 00 	cmpl   $0x7cf,0xffffffd8(%ebp)
  10182f:	7e df                	jle    101810 <video_putc+0x184>
		crt_pos -= CRT_COLS;
  101831:	0f b7 05 68 7f 10 00 	movzwl 0x107f68,%eax
  101838:	83 e8 50             	sub    $0x50,%eax
  10183b:	66 a3 68 7f 10 00    	mov    %ax,0x107f68
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
  101841:	a1 60 7f 10 00       	mov    0x107f60,%eax
  101846:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)
  101849:	c6 45 df 0e          	movb   $0xe,0xffffffdf(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  10184d:	0f b6 45 df          	movzbl 0xffffffdf(%ebp),%eax
  101851:	8b 55 e0             	mov    0xffffffe0(%ebp),%edx
  101854:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
  101855:	0f b7 05 68 7f 10 00 	movzwl 0x107f68,%eax
  10185c:	66 c1 e8 08          	shr    $0x8,%ax
  101860:	0f b6 d0             	movzbl %al,%edx
  101863:	a1 60 7f 10 00       	mov    0x107f60,%eax
  101868:	83 c0 01             	add    $0x1,%eax
  10186b:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  10186e:	88 55 e7             	mov    %dl,0xffffffe7(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  101871:	0f b6 45 e7          	movzbl 0xffffffe7(%ebp),%eax
  101875:	8b 55 e8             	mov    0xffffffe8(%ebp),%edx
  101878:	ee                   	out    %al,(%dx)
	outb(addr_6845, 15);
  101879:	a1 60 7f 10 00       	mov    0x107f60,%eax
  10187e:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
  101881:	c6 45 ef 0f          	movb   $0xf,0xffffffef(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  101885:	0f b6 45 ef          	movzbl 0xffffffef(%ebp),%eax
  101889:	8b 55 f0             	mov    0xfffffff0(%ebp),%edx
  10188c:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos);
  10188d:	0f b7 05 68 7f 10 00 	movzwl 0x107f68,%eax
  101894:	0f b6 d0             	movzbl %al,%edx
  101897:	a1 60 7f 10 00       	mov    0x107f60,%eax
  10189c:	83 c0 01             	add    $0x1,%eax
  10189f:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  1018a2:	88 55 f7             	mov    %dl,0xfffffff7(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  1018a5:	0f b6 45 f7          	movzbl 0xfffffff7(%ebp),%eax
  1018a9:	8b 55 f8             	mov    0xfffffff8(%ebp),%edx
  1018ac:	ee                   	out    %al,(%dx)
}
  1018ad:	83 c4 44             	add    $0x44,%esp
  1018b0:	5b                   	pop    %ebx
  1018b1:	5d                   	pop    %ebp
  1018b2:	c3                   	ret    
  1018b3:	90                   	nop    

001018b4 <kbd_proc_data>:
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
  1018b4:	55                   	push   %ebp
  1018b5:	89 e5                	mov    %esp,%ebp
  1018b7:	83 ec 38             	sub    $0x38,%esp
  1018ba:	c7 45 ec 64 00 00 00 	movl   $0x64,0xffffffec(%ebp)
static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  1018c1:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
  1018c4:	ec                   	in     (%dx),%al
  1018c5:	88 45 eb             	mov    %al,0xffffffeb(%ebp)
	return data;
  1018c8:	0f b6 45 eb          	movzbl 0xffffffeb(%ebp),%eax
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
  1018cc:	0f b6 c0             	movzbl %al,%eax
  1018cf:	83 e0 01             	and    $0x1,%eax
  1018d2:	85 c0                	test   %eax,%eax
  1018d4:	75 0c                	jne    1018e2 <kbd_proc_data+0x2e>
		return -1;
  1018d6:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,0xffffffd8(%ebp)
  1018dd:	e9 69 01 00 00       	jmp    101a4b <kbd_proc_data+0x197>
  1018e2:	c7 45 f4 60 00 00 00 	movl   $0x60,0xfffffff4(%ebp)
static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  1018e9:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  1018ec:	ec                   	in     (%dx),%al
  1018ed:	88 45 f3             	mov    %al,0xfffffff3(%ebp)
	return data;
  1018f0:	0f b6 45 f3          	movzbl 0xfffffff3(%ebp),%eax

	data = inb(KBDATAP);
  1018f4:	88 45 ea             	mov    %al,0xffffffea(%ebp)

	if (data == 0xE0) {
  1018f7:	80 7d ea e0          	cmpb   $0xe0,0xffffffea(%ebp)
  1018fb:	75 19                	jne    101916 <kbd_proc_data+0x62>
		// E0 escape character
		shift |= E0ESC;
  1018fd:	a1 6c 7f 10 00       	mov    0x107f6c,%eax
  101902:	83 c8 40             	or     $0x40,%eax
  101905:	a3 6c 7f 10 00       	mov    %eax,0x107f6c
		return 0;
  10190a:	c7 45 d8 00 00 00 00 	movl   $0x0,0xffffffd8(%ebp)
  101911:	e9 35 01 00 00       	jmp    101a4b <kbd_proc_data+0x197>
	} else if (data & 0x80) {
  101916:	0f b6 45 ea          	movzbl 0xffffffea(%ebp),%eax
  10191a:	84 c0                	test   %al,%al
  10191c:	79 53                	jns    101971 <kbd_proc_data+0xbd>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
  10191e:	a1 6c 7f 10 00       	mov    0x107f6c,%eax
  101923:	83 e0 40             	and    $0x40,%eax
  101926:	85 c0                	test   %eax,%eax
  101928:	75 0c                	jne    101936 <kbd_proc_data+0x82>
  10192a:	0f b6 45 ea          	movzbl 0xffffffea(%ebp),%eax
  10192e:	83 e0 7f             	and    $0x7f,%eax
  101931:	88 45 df             	mov    %al,0xffffffdf(%ebp)
  101934:	eb 07                	jmp    10193d <kbd_proc_data+0x89>
  101936:	0f b6 45 ea          	movzbl 0xffffffea(%ebp),%eax
  10193a:	88 45 df             	mov    %al,0xffffffdf(%ebp)
  10193d:	0f b6 45 df          	movzbl 0xffffffdf(%ebp),%eax
  101941:	88 45 ea             	mov    %al,0xffffffea(%ebp)
		shift &= ~(shiftcode[data] | E0ESC);
  101944:	0f b6 45 ea          	movzbl 0xffffffea(%ebp),%eax
  101948:	0f b6 80 20 60 10 00 	movzbl 0x106020(%eax),%eax
  10194f:	83 c8 40             	or     $0x40,%eax
  101952:	0f b6 c0             	movzbl %al,%eax
  101955:	f7 d0                	not    %eax
  101957:	89 c2                	mov    %eax,%edx
  101959:	a1 6c 7f 10 00       	mov    0x107f6c,%eax
  10195e:	21 d0                	and    %edx,%eax
  101960:	a3 6c 7f 10 00       	mov    %eax,0x107f6c
		return 0;
  101965:	c7 45 d8 00 00 00 00 	movl   $0x0,0xffffffd8(%ebp)
  10196c:	e9 da 00 00 00       	jmp    101a4b <kbd_proc_data+0x197>
	} else if (shift & E0ESC) {
  101971:	a1 6c 7f 10 00       	mov    0x107f6c,%eax
  101976:	83 e0 40             	and    $0x40,%eax
  101979:	85 c0                	test   %eax,%eax
  10197b:	74 11                	je     10198e <kbd_proc_data+0xda>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
  10197d:	80 4d ea 80          	orb    $0x80,0xffffffea(%ebp)
		shift &= ~E0ESC;
  101981:	a1 6c 7f 10 00       	mov    0x107f6c,%eax
  101986:	83 e0 bf             	and    $0xffffffbf,%eax
  101989:	a3 6c 7f 10 00       	mov    %eax,0x107f6c
	}

	shift |= shiftcode[data];
  10198e:	0f b6 45 ea          	movzbl 0xffffffea(%ebp),%eax
  101992:	0f b6 80 20 60 10 00 	movzbl 0x106020(%eax),%eax
  101999:	0f b6 d0             	movzbl %al,%edx
  10199c:	a1 6c 7f 10 00       	mov    0x107f6c,%eax
  1019a1:	09 d0                	or     %edx,%eax
  1019a3:	a3 6c 7f 10 00       	mov    %eax,0x107f6c
	shift ^= togglecode[data];
  1019a8:	0f b6 45 ea          	movzbl 0xffffffea(%ebp),%eax
  1019ac:	0f b6 80 20 61 10 00 	movzbl 0x106120(%eax),%eax
  1019b3:	0f b6 d0             	movzbl %al,%edx
  1019b6:	a1 6c 7f 10 00       	mov    0x107f6c,%eax
  1019bb:	31 d0                	xor    %edx,%eax
  1019bd:	a3 6c 7f 10 00       	mov    %eax,0x107f6c

	c = charcode[shift & (CTL | SHIFT)][data];
  1019c2:	a1 6c 7f 10 00       	mov    0x107f6c,%eax
  1019c7:	83 e0 03             	and    $0x3,%eax
  1019ca:	8b 14 85 20 65 10 00 	mov    0x106520(,%eax,4),%edx
  1019d1:	0f b6 45 ea          	movzbl 0xffffffea(%ebp),%eax
  1019d5:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1019d8:	0f b6 00             	movzbl (%eax),%eax
  1019db:	0f b6 c0             	movzbl %al,%eax
  1019de:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
	if (shift & CAPSLOCK) {
  1019e1:	a1 6c 7f 10 00       	mov    0x107f6c,%eax
  1019e6:	83 e0 08             	and    $0x8,%eax
  1019e9:	85 c0                	test   %eax,%eax
  1019eb:	74 22                	je     101a0f <kbd_proc_data+0x15b>
		if ('a' <= c && c <= 'z')
  1019ed:	83 7d e4 60          	cmpl   $0x60,0xffffffe4(%ebp)
  1019f1:	7e 0c                	jle    1019ff <kbd_proc_data+0x14b>
  1019f3:	83 7d e4 7a          	cmpl   $0x7a,0xffffffe4(%ebp)
  1019f7:	7f 06                	jg     1019ff <kbd_proc_data+0x14b>
			c += 'A' - 'a';
  1019f9:	83 6d e4 20          	subl   $0x20,0xffffffe4(%ebp)
  1019fd:	eb 10                	jmp    101a0f <kbd_proc_data+0x15b>
		else if ('A' <= c && c <= 'Z')
  1019ff:	83 7d e4 40          	cmpl   $0x40,0xffffffe4(%ebp)
  101a03:	7e 0a                	jle    101a0f <kbd_proc_data+0x15b>
  101a05:	83 7d e4 5a          	cmpl   $0x5a,0xffffffe4(%ebp)
  101a09:	7f 04                	jg     101a0f <kbd_proc_data+0x15b>
			c += 'a' - 'A';
  101a0b:	83 45 e4 20          	addl   $0x20,0xffffffe4(%ebp)
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
  101a0f:	a1 6c 7f 10 00       	mov    0x107f6c,%eax
  101a14:	f7 d0                	not    %eax
  101a16:	83 e0 06             	and    $0x6,%eax
  101a19:	85 c0                	test   %eax,%eax
  101a1b:	75 28                	jne    101a45 <kbd_proc_data+0x191>
  101a1d:	81 7d e4 e9 00 00 00 	cmpl   $0xe9,0xffffffe4(%ebp)
  101a24:	75 1f                	jne    101a45 <kbd_proc_data+0x191>
		cprintf("Rebooting!\n");
  101a26:	c7 04 24 df 34 10 00 	movl   $0x1034df,(%esp)
  101a2d:	e8 7f 0a 00 00       	call   1024b1 <cprintf>
  101a32:	c7 45 fc 92 00 00 00 	movl   $0x92,0xfffffffc(%ebp)
  101a39:	c6 45 fb 03          	movb   $0x3,0xfffffffb(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  101a3d:	0f b6 45 fb          	movzbl 0xfffffffb(%ebp),%eax
  101a41:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  101a44:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
  101a45:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
  101a48:	89 45 d8             	mov    %eax,0xffffffd8(%ebp)
  101a4b:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
}
  101a4e:	c9                   	leave  
  101a4f:	c3                   	ret    

00101a50 <kbd_intr>:

void
kbd_intr(void)
{
  101a50:	55                   	push   %ebp
  101a51:	89 e5                	mov    %esp,%ebp
  101a53:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
  101a56:	c7 04 24 b4 18 10 00 	movl   $0x1018b4,(%esp)
  101a5d:	e8 2a e7 ff ff       	call   10018c <cons_intr>
}
  101a62:	c9                   	leave  
  101a63:	c3                   	ret    

00101a64 <kbd_init>:

void
kbd_init(void)
{
  101a64:	55                   	push   %ebp
  101a65:	89 e5                	mov    %esp,%ebp
}
  101a67:	5d                   	pop    %ebp
  101a68:	c3                   	ret    
  101a69:	90                   	nop    
  101a6a:	90                   	nop    
  101a6b:	90                   	nop    

00101a6c <delay>:

// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
  101a6c:	55                   	push   %ebp
  101a6d:	89 e5                	mov    %esp,%ebp
  101a6f:	83 ec 20             	sub    $0x20,%esp
  101a72:	c7 45 e4 84 00 00 00 	movl   $0x84,0xffffffe4(%ebp)
static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101a79:	8b 55 e4             	mov    0xffffffe4(%ebp),%edx
  101a7c:	ec                   	in     (%dx),%al
  101a7d:	88 45 e3             	mov    %al,0xffffffe3(%ebp)
	return data;
  101a80:	c7 45 ec 84 00 00 00 	movl   $0x84,0xffffffec(%ebp)
  101a87:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
  101a8a:	ec                   	in     (%dx),%al
  101a8b:	88 45 eb             	mov    %al,0xffffffeb(%ebp)
  101a8e:	c7 45 f4 84 00 00 00 	movl   $0x84,0xfffffff4(%ebp)
  101a95:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  101a98:	ec                   	in     (%dx),%al
  101a99:	88 45 f3             	mov    %al,0xfffffff3(%ebp)
  101a9c:	c7 45 fc 84 00 00 00 	movl   $0x84,0xfffffffc(%ebp)
  101aa3:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  101aa6:	ec                   	in     (%dx),%al
  101aa7:	88 45 fb             	mov    %al,0xfffffffb(%ebp)
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
  101aaa:	c9                   	leave  
  101aab:	c3                   	ret    

00101aac <serial_proc_data>:

static int
serial_proc_data(void)
{
  101aac:	55                   	push   %ebp
  101aad:	89 e5                	mov    %esp,%ebp
  101aaf:	83 ec 14             	sub    $0x14,%esp
  101ab2:	c7 45 f4 fd 03 00 00 	movl   $0x3fd,0xfffffff4(%ebp)
static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101ab9:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  101abc:	ec                   	in     (%dx),%al
  101abd:	88 45 f3             	mov    %al,0xfffffff3(%ebp)
	return data;
  101ac0:	0f b6 45 f3          	movzbl 0xfffffff3(%ebp),%eax
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
  101ac4:	0f b6 c0             	movzbl %al,%eax
  101ac7:	83 e0 01             	and    $0x1,%eax
  101aca:	85 c0                	test   %eax,%eax
  101acc:	75 09                	jne    101ad7 <serial_proc_data+0x2b>
		return -1;
  101ace:	c7 45 ec ff ff ff ff 	movl   $0xffffffff,0xffffffec(%ebp)
  101ad5:	eb 18                	jmp    101aef <serial_proc_data+0x43>
  101ad7:	c7 45 fc f8 03 00 00 	movl   $0x3f8,0xfffffffc(%ebp)
static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101ade:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  101ae1:	ec                   	in     (%dx),%al
  101ae2:	88 45 fb             	mov    %al,0xfffffffb(%ebp)
	return data;
  101ae5:	0f b6 45 fb          	movzbl 0xfffffffb(%ebp),%eax
	return inb(COM1+COM_RX);
  101ae9:	0f b6 c0             	movzbl %al,%eax
  101aec:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  101aef:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
}
  101af2:	c9                   	leave  
  101af3:	c3                   	ret    

00101af4 <serial_intr>:

void
serial_intr(void)
{
  101af4:	55                   	push   %ebp
  101af5:	89 e5                	mov    %esp,%ebp
  101af7:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
  101afa:	a1 80 7f 10 00       	mov    0x107f80,%eax
  101aff:	85 c0                	test   %eax,%eax
  101b01:	74 0c                	je     101b0f <serial_intr+0x1b>
		cons_intr(serial_proc_data);
  101b03:	c7 04 24 ac 1a 10 00 	movl   $0x101aac,(%esp)
  101b0a:	e8 7d e6 ff ff       	call   10018c <cons_intr>
}
  101b0f:	c9                   	leave  
  101b10:	c3                   	ret    

00101b11 <serial_putc>:

void
serial_putc(int c)
{
  101b11:	55                   	push   %ebp
  101b12:	89 e5                	mov    %esp,%ebp
  101b14:	83 ec 20             	sub    $0x20,%esp
	if (!serial_exists)
  101b17:	a1 80 7f 10 00       	mov    0x107f80,%eax
  101b1c:	85 c0                	test   %eax,%eax
  101b1e:	74 4f                	je     101b6f <serial_putc+0x5e>
		return;

	int i;
	for (i = 0;
  101b20:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
  101b27:	eb 09                	jmp    101b32 <serial_putc+0x21>
	     i++)
		delay();
  101b29:	e8 3e ff ff ff       	call   101a6c <delay>
  101b2e:	83 45 ec 01          	addl   $0x1,0xffffffec(%ebp)
  101b32:	c7 45 f4 fd 03 00 00 	movl   $0x3fd,0xfffffff4(%ebp)
static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101b39:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  101b3c:	ec                   	in     (%dx),%al
  101b3d:	88 45 f3             	mov    %al,0xfffffff3(%ebp)
	return data;
  101b40:	0f b6 45 f3          	movzbl 0xfffffff3(%ebp),%eax
  101b44:	0f b6 c0             	movzbl %al,%eax
  101b47:	83 e0 20             	and    $0x20,%eax
  101b4a:	85 c0                	test   %eax,%eax
  101b4c:	75 09                	jne    101b57 <serial_putc+0x46>
  101b4e:	81 7d ec ff 31 00 00 	cmpl   $0x31ff,0xffffffec(%ebp)
  101b55:	7e d2                	jle    101b29 <serial_putc+0x18>
	
	outb(COM1 + COM_TX, c);
  101b57:	8b 45 08             	mov    0x8(%ebp),%eax
  101b5a:	0f b6 c0             	movzbl %al,%eax
  101b5d:	c7 45 fc f8 03 00 00 	movl   $0x3f8,0xfffffffc(%ebp)
  101b64:	88 45 fb             	mov    %al,0xfffffffb(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  101b67:	0f b6 45 fb          	movzbl 0xfffffffb(%ebp),%eax
  101b6b:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  101b6e:	ee                   	out    %al,(%dx)
}
  101b6f:	c9                   	leave  
  101b70:	c3                   	ret    

00101b71 <serial_init>:

void
serial_init(void)
{
  101b71:	55                   	push   %ebp
  101b72:	89 e5                	mov    %esp,%ebp
  101b74:	83 ec 50             	sub    $0x50,%esp
  101b77:	c7 45 b4 fa 03 00 00 	movl   $0x3fa,0xffffffb4(%ebp)
  101b7e:	c6 45 b3 00          	movb   $0x0,0xffffffb3(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  101b82:	0f b6 45 b3          	movzbl 0xffffffb3(%ebp),%eax
  101b86:	8b 55 b4             	mov    0xffffffb4(%ebp),%edx
  101b89:	ee                   	out    %al,(%dx)
  101b8a:	c7 45 bc fb 03 00 00 	movl   $0x3fb,0xffffffbc(%ebp)
  101b91:	c6 45 bb 80          	movb   $0x80,0xffffffbb(%ebp)
  101b95:	0f b6 45 bb          	movzbl 0xffffffbb(%ebp),%eax
  101b99:	8b 55 bc             	mov    0xffffffbc(%ebp),%edx
  101b9c:	ee                   	out    %al,(%dx)
  101b9d:	c7 45 c4 f8 03 00 00 	movl   $0x3f8,0xffffffc4(%ebp)
  101ba4:	c6 45 c3 0c          	movb   $0xc,0xffffffc3(%ebp)
  101ba8:	0f b6 45 c3          	movzbl 0xffffffc3(%ebp),%eax
  101bac:	8b 55 c4             	mov    0xffffffc4(%ebp),%edx
  101baf:	ee                   	out    %al,(%dx)
  101bb0:	c7 45 cc f9 03 00 00 	movl   $0x3f9,0xffffffcc(%ebp)
  101bb7:	c6 45 cb 00          	movb   $0x0,0xffffffcb(%ebp)
  101bbb:	0f b6 45 cb          	movzbl 0xffffffcb(%ebp),%eax
  101bbf:	8b 55 cc             	mov    0xffffffcc(%ebp),%edx
  101bc2:	ee                   	out    %al,(%dx)
  101bc3:	c7 45 d4 fb 03 00 00 	movl   $0x3fb,0xffffffd4(%ebp)
  101bca:	c6 45 d3 03          	movb   $0x3,0xffffffd3(%ebp)
  101bce:	0f b6 45 d3          	movzbl 0xffffffd3(%ebp),%eax
  101bd2:	8b 55 d4             	mov    0xffffffd4(%ebp),%edx
  101bd5:	ee                   	out    %al,(%dx)
  101bd6:	c7 45 dc fc 03 00 00 	movl   $0x3fc,0xffffffdc(%ebp)
  101bdd:	c6 45 db 00          	movb   $0x0,0xffffffdb(%ebp)
  101be1:	0f b6 45 db          	movzbl 0xffffffdb(%ebp),%eax
  101be5:	8b 55 dc             	mov    0xffffffdc(%ebp),%edx
  101be8:	ee                   	out    %al,(%dx)
  101be9:	c7 45 e4 f9 03 00 00 	movl   $0x3f9,0xffffffe4(%ebp)
  101bf0:	c6 45 e3 01          	movb   $0x1,0xffffffe3(%ebp)
  101bf4:	0f b6 45 e3          	movzbl 0xffffffe3(%ebp),%eax
  101bf8:	8b 55 e4             	mov    0xffffffe4(%ebp),%edx
  101bfb:	ee                   	out    %al,(%dx)
  101bfc:	c7 45 ec fd 03 00 00 	movl   $0x3fd,0xffffffec(%ebp)
  101c03:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
  101c06:	ec                   	in     (%dx),%al
  101c07:	88 45 eb             	mov    %al,0xffffffeb(%ebp)
  101c0a:	0f b6 45 eb          	movzbl 0xffffffeb(%ebp),%eax
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
  101c0e:	3c ff                	cmp    $0xff,%al
  101c10:	0f 95 c0             	setne  %al
  101c13:	0f b6 c0             	movzbl %al,%eax
  101c16:	a3 80 7f 10 00       	mov    %eax,0x107f80
  101c1b:	c7 45 f4 fa 03 00 00 	movl   $0x3fa,0xfffffff4(%ebp)
static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  101c22:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  101c25:	ec                   	in     (%dx),%al
  101c26:	88 45 f3             	mov    %al,0xfffffff3(%ebp)
	return data;
  101c29:	c7 45 fc f8 03 00 00 	movl   $0x3f8,0xfffffffc(%ebp)
  101c30:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  101c33:	ec                   	in     (%dx),%al
  101c34:	88 45 fb             	mov    %al,0xfffffffb(%ebp)
	(void) inb(COM1+COM_IIR);
	(void) inb(COM1+COM_RX);
}
  101c37:	c9                   	leave  
  101c38:	c3                   	ret    
  101c39:	90                   	nop    
  101c3a:	90                   	nop    
  101c3b:	90                   	nop    

00101c3c <nvram_read>:


unsigned
nvram_read(unsigned reg)
{
  101c3c:	55                   	push   %ebp
  101c3d:	89 e5                	mov    %esp,%ebp
  101c3f:	83 ec 10             	sub    $0x10,%esp
	outb(IO_RTC, reg);
  101c42:	8b 45 08             	mov    0x8(%ebp),%eax
  101c45:	0f b6 c0             	movzbl %al,%eax
  101c48:	c7 45 f4 70 00 00 00 	movl   $0x70,0xfffffff4(%ebp)
  101c4f:	88 45 f3             	mov    %al,0xfffffff3(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  101c52:	0f b6 45 f3          	movzbl 0xfffffff3(%ebp),%eax
  101c56:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  101c59:	ee                   	out    %al,(%dx)
  101c5a:	c7 45 fc 71 00 00 00 	movl   $0x71,0xfffffffc(%ebp)
  101c61:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  101c64:	ec                   	in     (%dx),%al
  101c65:	88 45 fb             	mov    %al,0xfffffffb(%ebp)
  101c68:	0f b6 45 fb          	movzbl 0xfffffffb(%ebp),%eax
	return inb(IO_RTC+1);
  101c6c:	0f b6 c0             	movzbl %al,%eax
}
  101c6f:	c9                   	leave  
  101c70:	c3                   	ret    

00101c71 <nvram_read16>:

unsigned
nvram_read16(unsigned r)
{
  101c71:	55                   	push   %ebp
  101c72:	89 e5                	mov    %esp,%ebp
  101c74:	53                   	push   %ebx
  101c75:	83 ec 04             	sub    $0x4,%esp
	return nvram_read(r) | (nvram_read(r + 1) << 8);
  101c78:	8b 45 08             	mov    0x8(%ebp),%eax
  101c7b:	89 04 24             	mov    %eax,(%esp)
  101c7e:	e8 b9 ff ff ff       	call   101c3c <nvram_read>
  101c83:	89 c3                	mov    %eax,%ebx
  101c85:	8b 45 08             	mov    0x8(%ebp),%eax
  101c88:	83 c0 01             	add    $0x1,%eax
  101c8b:	89 04 24             	mov    %eax,(%esp)
  101c8e:	e8 a9 ff ff ff       	call   101c3c <nvram_read>
  101c93:	c1 e0 08             	shl    $0x8,%eax
  101c96:	09 d8                	or     %ebx,%eax
}
  101c98:	83 c4 04             	add    $0x4,%esp
  101c9b:	5b                   	pop    %ebx
  101c9c:	5d                   	pop    %ebp
  101c9d:	c3                   	ret    

00101c9e <nvram_write>:

void
nvram_write(unsigned reg, unsigned datum)
{
  101c9e:	55                   	push   %ebp
  101c9f:	89 e5                	mov    %esp,%ebp
  101ca1:	83 ec 10             	sub    $0x10,%esp
	outb(IO_RTC, reg);
  101ca4:	8b 45 08             	mov    0x8(%ebp),%eax
  101ca7:	0f b6 c0             	movzbl %al,%eax
  101caa:	c7 45 f4 70 00 00 00 	movl   $0x70,0xfffffff4(%ebp)
  101cb1:	88 45 f3             	mov    %al,0xfffffff3(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  101cb4:	0f b6 45 f3          	movzbl 0xfffffff3(%ebp),%eax
  101cb8:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  101cbb:	ee                   	out    %al,(%dx)
	outb(IO_RTC+1, datum);
  101cbc:	8b 45 0c             	mov    0xc(%ebp),%eax
  101cbf:	0f b6 c0             	movzbl %al,%eax
  101cc2:	c7 45 fc 71 00 00 00 	movl   $0x71,0xfffffffc(%ebp)
  101cc9:	88 45 fb             	mov    %al,0xfffffffb(%ebp)

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  101ccc:	0f b6 45 fb          	movzbl 0xfffffffb(%ebp),%eax
  101cd0:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  101cd3:	ee                   	out    %al,(%dx)
}
  101cd4:	c9                   	leave  
  101cd5:	c3                   	ret    
  101cd6:	90                   	nop    
  101cd7:	90                   	nop    

00101cd8 <getuint>:
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static uintmax_t
getuint(printstate *st, va_list *ap)
{
  101cd8:	55                   	push   %ebp
  101cd9:	89 e5                	mov    %esp,%ebp
  101cdb:	83 ec 08             	sub    $0x8,%esp
	if (st->flags & F_LL)
  101cde:	8b 45 08             	mov    0x8(%ebp),%eax
  101ce1:	8b 40 18             	mov    0x18(%eax),%eax
  101ce4:	83 e0 02             	and    $0x2,%eax
  101ce7:	85 c0                	test   %eax,%eax
  101ce9:	74 22                	je     101d0d <getuint+0x35>
		return va_arg(*ap, unsigned long long);
  101ceb:	8b 45 0c             	mov    0xc(%ebp),%eax
  101cee:	8b 00                	mov    (%eax),%eax
  101cf0:	8d 50 08             	lea    0x8(%eax),%edx
  101cf3:	8b 45 0c             	mov    0xc(%ebp),%eax
  101cf6:	89 10                	mov    %edx,(%eax)
  101cf8:	8b 45 0c             	mov    0xc(%ebp),%eax
  101cfb:	8b 00                	mov    (%eax),%eax
  101cfd:	83 e8 08             	sub    $0x8,%eax
  101d00:	8b 10                	mov    (%eax),%edx
  101d02:	8b 48 04             	mov    0x4(%eax),%ecx
  101d05:	89 55 f8             	mov    %edx,0xfffffff8(%ebp)
  101d08:	89 4d fc             	mov    %ecx,0xfffffffc(%ebp)
  101d0b:	eb 51                	jmp    101d5e <getuint+0x86>
	else if (st->flags & F_L)
  101d0d:	8b 45 08             	mov    0x8(%ebp),%eax
  101d10:	8b 40 18             	mov    0x18(%eax),%eax
  101d13:	83 e0 01             	and    $0x1,%eax
  101d16:	84 c0                	test   %al,%al
  101d18:	74 23                	je     101d3d <getuint+0x65>
		return va_arg(*ap, unsigned long);
  101d1a:	8b 45 0c             	mov    0xc(%ebp),%eax
  101d1d:	8b 00                	mov    (%eax),%eax
  101d1f:	8d 50 04             	lea    0x4(%eax),%edx
  101d22:	8b 45 0c             	mov    0xc(%ebp),%eax
  101d25:	89 10                	mov    %edx,(%eax)
  101d27:	8b 45 0c             	mov    0xc(%ebp),%eax
  101d2a:	8b 00                	mov    (%eax),%eax
  101d2c:	83 e8 04             	sub    $0x4,%eax
  101d2f:	8b 00                	mov    (%eax),%eax
  101d31:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  101d34:	c7 45 fc 00 00 00 00 	movl   $0x0,0xfffffffc(%ebp)
  101d3b:	eb 21                	jmp    101d5e <getuint+0x86>
	else
		return va_arg(*ap, unsigned int);
  101d3d:	8b 45 0c             	mov    0xc(%ebp),%eax
  101d40:	8b 00                	mov    (%eax),%eax
  101d42:	8d 50 04             	lea    0x4(%eax),%edx
  101d45:	8b 45 0c             	mov    0xc(%ebp),%eax
  101d48:	89 10                	mov    %edx,(%eax)
  101d4a:	8b 45 0c             	mov    0xc(%ebp),%eax
  101d4d:	8b 00                	mov    (%eax),%eax
  101d4f:	83 e8 04             	sub    $0x4,%eax
  101d52:	8b 00                	mov    (%eax),%eax
  101d54:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  101d57:	c7 45 fc 00 00 00 00 	movl   $0x0,0xfffffffc(%ebp)
  101d5e:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  101d61:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
}
  101d64:	c9                   	leave  
  101d65:	c3                   	ret    

00101d66 <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static intmax_t
getint(printstate *st, va_list *ap)
{
  101d66:	55                   	push   %ebp
  101d67:	89 e5                	mov    %esp,%ebp
  101d69:	83 ec 08             	sub    $0x8,%esp
	if (st->flags & F_LL)
  101d6c:	8b 45 08             	mov    0x8(%ebp),%eax
  101d6f:	8b 40 18             	mov    0x18(%eax),%eax
  101d72:	83 e0 02             	and    $0x2,%eax
  101d75:	85 c0                	test   %eax,%eax
  101d77:	74 22                	je     101d9b <getint+0x35>
		return va_arg(*ap, long long);
  101d79:	8b 45 0c             	mov    0xc(%ebp),%eax
  101d7c:	8b 00                	mov    (%eax),%eax
  101d7e:	8d 50 08             	lea    0x8(%eax),%edx
  101d81:	8b 45 0c             	mov    0xc(%ebp),%eax
  101d84:	89 10                	mov    %edx,(%eax)
  101d86:	8b 45 0c             	mov    0xc(%ebp),%eax
  101d89:	8b 00                	mov    (%eax),%eax
  101d8b:	83 e8 08             	sub    $0x8,%eax
  101d8e:	8b 10                	mov    (%eax),%edx
  101d90:	8b 48 04             	mov    0x4(%eax),%ecx
  101d93:	89 55 f8             	mov    %edx,0xfffffff8(%ebp)
  101d96:	89 4d fc             	mov    %ecx,0xfffffffc(%ebp)
  101d99:	eb 53                	jmp    101dee <getint+0x88>
	else if (st->flags & F_L)
  101d9b:	8b 45 08             	mov    0x8(%ebp),%eax
  101d9e:	8b 40 18             	mov    0x18(%eax),%eax
  101da1:	83 e0 01             	and    $0x1,%eax
  101da4:	84 c0                	test   %al,%al
  101da6:	74 24                	je     101dcc <getint+0x66>
		return va_arg(*ap, long);
  101da8:	8b 45 0c             	mov    0xc(%ebp),%eax
  101dab:	8b 00                	mov    (%eax),%eax
  101dad:	8d 50 04             	lea    0x4(%eax),%edx
  101db0:	8b 45 0c             	mov    0xc(%ebp),%eax
  101db3:	89 10                	mov    %edx,(%eax)
  101db5:	8b 45 0c             	mov    0xc(%ebp),%eax
  101db8:	8b 00                	mov    (%eax),%eax
  101dba:	83 e8 04             	sub    $0x4,%eax
  101dbd:	8b 00                	mov    (%eax),%eax
  101dbf:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  101dc2:	89 c1                	mov    %eax,%ecx
  101dc4:	c1 f9 1f             	sar    $0x1f,%ecx
  101dc7:	89 4d fc             	mov    %ecx,0xfffffffc(%ebp)
  101dca:	eb 22                	jmp    101dee <getint+0x88>
	else
		return va_arg(*ap, int);
  101dcc:	8b 45 0c             	mov    0xc(%ebp),%eax
  101dcf:	8b 00                	mov    (%eax),%eax
  101dd1:	8d 50 04             	lea    0x4(%eax),%edx
  101dd4:	8b 45 0c             	mov    0xc(%ebp),%eax
  101dd7:	89 10                	mov    %edx,(%eax)
  101dd9:	8b 45 0c             	mov    0xc(%ebp),%eax
  101ddc:	8b 00                	mov    (%eax),%eax
  101dde:	83 e8 04             	sub    $0x4,%eax
  101de1:	8b 00                	mov    (%eax),%eax
  101de3:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  101de6:	89 c2                	mov    %eax,%edx
  101de8:	c1 fa 1f             	sar    $0x1f,%edx
  101deb:	89 55 fc             	mov    %edx,0xfffffffc(%ebp)
  101dee:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  101df1:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
}
  101df4:	c9                   	leave  
  101df5:	c3                   	ret    

00101df6 <putpad>:

// Print padding characters, and an optional sign before a number.
static void
putpad(printstate *st)
{
  101df6:	55                   	push   %ebp
  101df7:	89 e5                	mov    %esp,%ebp
  101df9:	83 ec 08             	sub    $0x8,%esp
	while (--st->width >= 0)
  101dfc:	eb 1a                	jmp    101e18 <putpad+0x22>
		st->putch(st->padc, st->putdat);
  101dfe:	8b 45 08             	mov    0x8(%ebp),%eax
  101e01:	8b 08                	mov    (%eax),%ecx
  101e03:	8b 45 08             	mov    0x8(%ebp),%eax
  101e06:	8b 50 04             	mov    0x4(%eax),%edx
  101e09:	8b 45 08             	mov    0x8(%ebp),%eax
  101e0c:	8b 40 08             	mov    0x8(%eax),%eax
  101e0f:	89 54 24 04          	mov    %edx,0x4(%esp)
  101e13:	89 04 24             	mov    %eax,(%esp)
  101e16:	ff d1                	call   *%ecx
  101e18:	8b 45 08             	mov    0x8(%ebp),%eax
  101e1b:	8b 40 0c             	mov    0xc(%eax),%eax
  101e1e:	8d 50 ff             	lea    0xffffffff(%eax),%edx
  101e21:	8b 45 08             	mov    0x8(%ebp),%eax
  101e24:	89 50 0c             	mov    %edx,0xc(%eax)
  101e27:	8b 45 08             	mov    0x8(%ebp),%eax
  101e2a:	8b 40 0c             	mov    0xc(%eax),%eax
  101e2d:	85 c0                	test   %eax,%eax
  101e2f:	79 cd                	jns    101dfe <putpad+0x8>
}
  101e31:	c9                   	leave  
  101e32:	c3                   	ret    

00101e33 <putstr>:

// Print a string with a specified maximum length (-1=unlimited),
// with any appropriate left or right field padding.
static void
putstr(printstate *st, const char *str, int maxlen)
{
  101e33:	55                   	push   %ebp
  101e34:	89 e5                	mov    %esp,%ebp
  101e36:	53                   	push   %ebx
  101e37:	83 ec 24             	sub    $0x24,%esp
	const char *lim;		// find where the string actually ends
	if (maxlen < 0)
  101e3a:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  101e3e:	79 18                	jns    101e58 <putstr+0x25>
		lim = strchr(str, 0);	// find the terminating null
  101e40:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  101e47:	00 
  101e48:	8b 45 0c             	mov    0xc(%ebp),%eax
  101e4b:	89 04 24             	mov    %eax,(%esp)
  101e4e:	e8 16 08 00 00       	call   102669 <strchr>
  101e53:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
  101e56:	eb 2c                	jmp    101e84 <putstr+0x51>
	else if ((lim = memchr(str, 0, maxlen)) == NULL)
  101e58:	8b 45 10             	mov    0x10(%ebp),%eax
  101e5b:	89 44 24 08          	mov    %eax,0x8(%esp)
  101e5f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  101e66:	00 
  101e67:	8b 45 0c             	mov    0xc(%ebp),%eax
  101e6a:	89 04 24             	mov    %eax,(%esp)
  101e6d:	e8 f4 09 00 00       	call   102866 <memchr>
  101e72:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
  101e75:	83 7d f4 00          	cmpl   $0x0,0xfffffff4(%ebp)
  101e79:	75 09                	jne    101e84 <putstr+0x51>
		lim = str + maxlen;
  101e7b:	8b 45 10             	mov    0x10(%ebp),%eax
  101e7e:	03 45 0c             	add    0xc(%ebp),%eax
  101e81:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	st->width -= (lim-str);		// deduct string length from field width
  101e84:	8b 45 08             	mov    0x8(%ebp),%eax
  101e87:	8b 48 0c             	mov    0xc(%eax),%ecx
  101e8a:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  101e8d:	8b 45 0c             	mov    0xc(%ebp),%eax
  101e90:	89 d3                	mov    %edx,%ebx
  101e92:	29 c3                	sub    %eax,%ebx
  101e94:	89 d8                	mov    %ebx,%eax
  101e96:	89 ca                	mov    %ecx,%edx
  101e98:	29 c2                	sub    %eax,%edx
  101e9a:	8b 45 08             	mov    0x8(%ebp),%eax
  101e9d:	89 50 0c             	mov    %edx,0xc(%eax)

	if (!(st->flags & F_RPAD))	// print left-side padding
  101ea0:	8b 45 08             	mov    0x8(%ebp),%eax
  101ea3:	8b 40 18             	mov    0x18(%eax),%eax
  101ea6:	83 e0 10             	and    $0x10,%eax
  101ea9:	85 c0                	test   %eax,%eax
  101eab:	75 32                	jne    101edf <putstr+0xac>
		putpad(st);		// (also leaves st->width == 0)
  101ead:	8b 45 08             	mov    0x8(%ebp),%eax
  101eb0:	89 04 24             	mov    %eax,(%esp)
  101eb3:	e8 3e ff ff ff       	call   101df6 <putpad>
	while (str < lim) {
  101eb8:	eb 25                	jmp    101edf <putstr+0xac>
		char ch = *str++;
  101eba:	8b 45 0c             	mov    0xc(%ebp),%eax
  101ebd:	0f b6 00             	movzbl (%eax),%eax
  101ec0:	88 45 fb             	mov    %al,0xfffffffb(%ebp)
  101ec3:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
			st->putch(ch, st->putdat);
  101ec7:	8b 45 08             	mov    0x8(%ebp),%eax
  101eca:	8b 08                	mov    (%eax),%ecx
  101ecc:	8b 45 08             	mov    0x8(%ebp),%eax
  101ecf:	8b 40 04             	mov    0x4(%eax),%eax
  101ed2:	0f be 55 fb          	movsbl 0xfffffffb(%ebp),%edx
  101ed6:	89 44 24 04          	mov    %eax,0x4(%esp)
  101eda:	89 14 24             	mov    %edx,(%esp)
  101edd:	ff d1                	call   *%ecx
  101edf:	8b 45 0c             	mov    0xc(%ebp),%eax
  101ee2:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  101ee5:	72 d3                	jb     101eba <putstr+0x87>
	}
	putpad(st);			// print right-side padding
  101ee7:	8b 45 08             	mov    0x8(%ebp),%eax
  101eea:	89 04 24             	mov    %eax,(%esp)
  101eed:	e8 04 ff ff ff       	call   101df6 <putpad>
}
  101ef2:	83 c4 24             	add    $0x24,%esp
  101ef5:	5b                   	pop    %ebx
  101ef6:	5d                   	pop    %ebp
  101ef7:	c3                   	ret    

00101ef8 <genint>:

// Generate a number (base <= 16) in reverse order into a string buffer.
static char *
genint(printstate *st, char *p, uintmax_t num)
{
  101ef8:	55                   	push   %ebp
  101ef9:	89 e5                	mov    %esp,%ebp
  101efb:	53                   	push   %ebx
  101efc:	83 ec 24             	sub    $0x24,%esp
  101eff:	8b 45 10             	mov    0x10(%ebp),%eax
  101f02:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
  101f05:	8b 45 14             	mov    0x14(%ebp),%eax
  101f08:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= st->base)
  101f0b:	8b 45 08             	mov    0x8(%ebp),%eax
  101f0e:	8b 40 1c             	mov    0x1c(%eax),%eax
  101f11:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  101f14:	89 c2                	mov    %eax,%edx
  101f16:	c1 fa 1f             	sar    $0x1f,%edx
  101f19:	89 55 ec             	mov    %edx,0xffffffec(%ebp)
  101f1c:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  101f1f:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  101f22:	77 54                	ja     101f78 <genint+0x80>
  101f24:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
  101f27:	3b 55 f4             	cmp    0xfffffff4(%ebp),%edx
  101f2a:	72 08                	jb     101f34 <genint+0x3c>
  101f2c:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  101f2f:	3b 45 f0             	cmp    0xfffffff0(%ebp),%eax
  101f32:	77 44                	ja     101f78 <genint+0x80>
		p = genint(st, p, num / st->base);	// output higher digits
  101f34:	8b 45 08             	mov    0x8(%ebp),%eax
  101f37:	8b 40 1c             	mov    0x1c(%eax),%eax
  101f3a:	89 c2                	mov    %eax,%edx
  101f3c:	c1 fa 1f             	sar    $0x1f,%edx
  101f3f:	89 44 24 08          	mov    %eax,0x8(%esp)
  101f43:	89 54 24 0c          	mov    %edx,0xc(%esp)
  101f47:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  101f4a:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
  101f4d:	89 04 24             	mov    %eax,(%esp)
  101f50:	89 54 24 04          	mov    %edx,0x4(%esp)
  101f54:	e8 57 09 00 00       	call   1028b0 <__udivdi3>
  101f59:	89 44 24 08          	mov    %eax,0x8(%esp)
  101f5d:	89 54 24 0c          	mov    %edx,0xc(%esp)
  101f61:	8b 45 0c             	mov    0xc(%ebp),%eax
  101f64:	89 44 24 04          	mov    %eax,0x4(%esp)
  101f68:	8b 45 08             	mov    0x8(%ebp),%eax
  101f6b:	89 04 24             	mov    %eax,(%esp)
  101f6e:	e8 85 ff ff ff       	call   101ef8 <genint>
  101f73:	89 45 0c             	mov    %eax,0xc(%ebp)
  101f76:	eb 1b                	jmp    101f93 <genint+0x9b>
	else if (st->signc >= 0)
  101f78:	8b 45 08             	mov    0x8(%ebp),%eax
  101f7b:	8b 40 14             	mov    0x14(%eax),%eax
  101f7e:	85 c0                	test   %eax,%eax
  101f80:	78 11                	js     101f93 <genint+0x9b>
		*p++ = st->signc;			// output leading sign
  101f82:	8b 45 08             	mov    0x8(%ebp),%eax
  101f85:	8b 40 14             	mov    0x14(%eax),%eax
  101f88:	89 c2                	mov    %eax,%edx
  101f8a:	8b 45 0c             	mov    0xc(%ebp),%eax
  101f8d:	88 10                	mov    %dl,(%eax)
  101f8f:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
	*p++ = "0123456789abcdef"[num % st->base];	// output this digit
  101f93:	8b 45 08             	mov    0x8(%ebp),%eax
  101f96:	8b 40 1c             	mov    0x1c(%eax),%eax
  101f99:	89 c2                	mov    %eax,%edx
  101f9b:	c1 fa 1f             	sar    $0x1f,%edx
  101f9e:	8b 4d f0             	mov    0xfffffff0(%ebp),%ecx
  101fa1:	8b 5d f4             	mov    0xfffffff4(%ebp),%ebx
  101fa4:	89 44 24 08          	mov    %eax,0x8(%esp)
  101fa8:	89 54 24 0c          	mov    %edx,0xc(%esp)
  101fac:	89 0c 24             	mov    %ecx,(%esp)
  101faf:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  101fb3:	e8 28 0a 00 00       	call   1029e0 <__umoddi3>
  101fb8:	05 ec 34 10 00       	add    $0x1034ec,%eax
  101fbd:	0f b6 10             	movzbl (%eax),%edx
  101fc0:	8b 45 0c             	mov    0xc(%ebp),%eax
  101fc3:	88 10                	mov    %dl,(%eax)
  101fc5:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
	return p;
  101fc9:	8b 45 0c             	mov    0xc(%ebp),%eax
}
  101fcc:	83 c4 24             	add    $0x24,%esp
  101fcf:	5b                   	pop    %ebx
  101fd0:	5d                   	pop    %ebp
  101fd1:	c3                   	ret    

00101fd2 <putint>:

// Print an integer with any appropriate field padding.
static void
putint(printstate *st, uintmax_t num, int base)
{
  101fd2:	55                   	push   %ebp
  101fd3:	89 e5                	mov    %esp,%ebp
  101fd5:	83 ec 48             	sub    $0x48,%esp
  101fd8:	8b 45 0c             	mov    0xc(%ebp),%eax
  101fdb:	89 45 c8             	mov    %eax,0xffffffc8(%ebp)
  101fde:	8b 45 10             	mov    0x10(%ebp),%eax
  101fe1:	89 45 cc             	mov    %eax,0xffffffcc(%ebp)
	char buf[30], *p = buf;		// big enough for any 64-bit int in octal
  101fe4:	8d 45 de             	lea    0xffffffde(%ebp),%eax
  101fe7:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	st->base = base;		// select base for genint
  101fea:	8b 55 08             	mov    0x8(%ebp),%edx
  101fed:	8b 45 14             	mov    0x14(%ebp),%eax
  101ff0:	89 42 1c             	mov    %eax,0x1c(%edx)
	p = genint(st, p, num);		// output to the string buffer
  101ff3:	8b 45 c8             	mov    0xffffffc8(%ebp),%eax
  101ff6:	8b 55 cc             	mov    0xffffffcc(%ebp),%edx
  101ff9:	89 44 24 08          	mov    %eax,0x8(%esp)
  101ffd:	89 54 24 0c          	mov    %edx,0xc(%esp)
  102001:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  102004:	89 44 24 04          	mov    %eax,0x4(%esp)
  102008:	8b 45 08             	mov    0x8(%ebp),%eax
  10200b:	89 04 24             	mov    %eax,(%esp)
  10200e:	e8 e5 fe ff ff       	call   101ef8 <genint>
  102013:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	putstr(st, buf, p-buf);		// print it with left/right padding
  102016:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
  102019:	8d 45 de             	lea    0xffffffde(%ebp),%eax
  10201c:	89 d1                	mov    %edx,%ecx
  10201e:	29 c1                	sub    %eax,%ecx
  102020:	89 c8                	mov    %ecx,%eax
  102022:	89 44 24 08          	mov    %eax,0x8(%esp)
  102026:	8d 45 de             	lea    0xffffffde(%ebp),%eax
  102029:	89 44 24 04          	mov    %eax,0x4(%esp)
  10202d:	8b 45 08             	mov    0x8(%ebp),%eax
  102030:	89 04 24             	mov    %eax,(%esp)
  102033:	e8 fb fd ff ff       	call   101e33 <putstr>
}
  102038:	c9                   	leave  
  102039:	c3                   	ret    

0010203a <vprintfmt>:

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
  10203a:	55                   	push   %ebp
  10203b:	89 e5                	mov    %esp,%ebp
  10203d:	57                   	push   %edi
  10203e:	83 ec 54             	sub    $0x54,%esp
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
  102041:	8d 7d c8             	lea    0xffffffc8(%ebp),%edi
  102044:	fc                   	cld    
  102045:	ba 00 00 00 00       	mov    $0x0,%edx
  10204a:	b8 08 00 00 00       	mov    $0x8,%eax
  10204f:	89 c1                	mov    %eax,%ecx
  102051:	89 d0                	mov    %edx,%eax
  102053:	f3 ab                	rep stos %eax,%es:(%edi)
  102055:	8b 45 08             	mov    0x8(%ebp),%eax
  102058:	89 45 c8             	mov    %eax,0xffffffc8(%ebp)
  10205b:	8b 45 0c             	mov    0xc(%ebp),%eax
  10205e:	89 45 cc             	mov    %eax,0xffffffcc(%ebp)
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  102061:	eb 1c                	jmp    10207f <vprintfmt+0x45>
			if (ch == '\0')
  102063:	83 7d c4 00          	cmpl   $0x0,0xffffffc4(%ebp)
  102067:	0f 84 73 03 00 00    	je     1023e0 <vprintfmt+0x3a6>
				return;
			putch(ch, putdat);
  10206d:	8b 45 0c             	mov    0xc(%ebp),%eax
  102070:	89 44 24 04          	mov    %eax,0x4(%esp)
  102074:	8b 55 c4             	mov    0xffffffc4(%ebp),%edx
  102077:	89 14 24             	mov    %edx,(%esp)
  10207a:	8b 45 08             	mov    0x8(%ebp),%eax
  10207d:	ff d0                	call   *%eax
  10207f:	8b 45 10             	mov    0x10(%ebp),%eax
  102082:	0f b6 00             	movzbl (%eax),%eax
  102085:	0f b6 c0             	movzbl %al,%eax
  102088:	89 45 c4             	mov    %eax,0xffffffc4(%ebp)
  10208b:	83 7d c4 25          	cmpl   $0x25,0xffffffc4(%ebp)
  10208f:	0f 95 c0             	setne  %al
  102092:	83 45 10 01          	addl   $0x1,0x10(%ebp)
  102096:	84 c0                	test   %al,%al
  102098:	75 c9                	jne    102063 <vprintfmt+0x29>
		}

		// Process a %-escape sequence
		st.padc = ' ';
  10209a:	c7 45 d0 20 00 00 00 	movl   $0x20,0xffffffd0(%ebp)
		st.width = -1;
  1020a1:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,0xffffffd4(%ebp)
		st.prec = -1;
  1020a8:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,0xffffffd8(%ebp)
		st.signc = -1;
  1020af:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,0xffffffdc(%ebp)
		st.flags = 0;
  1020b6:	c7 45 e0 00 00 00 00 	movl   $0x0,0xffffffe0(%ebp)
		st.base = 10;
  1020bd:	c7 45 e4 0a 00 00 00 	movl   $0xa,0xffffffe4(%ebp)
  1020c4:	eb 00                	jmp    1020c6 <vprintfmt+0x8c>
		uintmax_t num;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  1020c6:	8b 45 10             	mov    0x10(%ebp),%eax
  1020c9:	0f b6 00             	movzbl (%eax),%eax
  1020cc:	0f b6 c0             	movzbl %al,%eax
  1020cf:	89 45 c4             	mov    %eax,0xffffffc4(%ebp)
  1020d2:	8b 45 c4             	mov    0xffffffc4(%ebp),%eax
  1020d5:	83 45 10 01          	addl   $0x1,0x10(%ebp)
  1020d9:	83 e8 20             	sub    $0x20,%eax
  1020dc:	89 45 b8             	mov    %eax,0xffffffb8(%ebp)
  1020df:	83 7d b8 58          	cmpl   $0x58,0xffffffb8(%ebp)
  1020e3:	0f 87 c8 02 00 00    	ja     1023b1 <vprintfmt+0x377>
  1020e9:	8b 55 b8             	mov    0xffffffb8(%ebp),%edx
  1020ec:	8b 04 95 04 35 10 00 	mov    0x103504(,%edx,4),%eax
  1020f3:	ff e0                	jmp    *%eax

		// modifier flags
		case '-': // pad on the right instead of the left
			st.flags |= F_RPAD;
  1020f5:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  1020f8:	83 c8 10             	or     $0x10,%eax
  1020fb:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)
			goto reswitch;
  1020fe:	eb c6                	jmp    1020c6 <vprintfmt+0x8c>

		case '+': // prefix positive numeric values with a '+' sign
			st.signc = '+';
  102100:	c7 45 dc 2b 00 00 00 	movl   $0x2b,0xffffffdc(%ebp)
			goto reswitch;
  102107:	eb bd                	jmp    1020c6 <vprintfmt+0x8c>

		case ' ': // prefix signless numeric values with a space
			if (st.signc < 0)	// (but only if no '+' is specified)
  102109:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
  10210c:	85 c0                	test   %eax,%eax
  10210e:	79 b6                	jns    1020c6 <vprintfmt+0x8c>
				st.signc = ' ';
  102110:	c7 45 dc 20 00 00 00 	movl   $0x20,0xffffffdc(%ebp)
			goto reswitch;
  102117:	eb ad                	jmp    1020c6 <vprintfmt+0x8c>

		// width or precision field
		case '0':
			if (!(st.flags & F_DOT))
  102119:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  10211c:	83 e0 08             	and    $0x8,%eax
  10211f:	85 c0                	test   %eax,%eax
  102121:	75 07                	jne    10212a <vprintfmt+0xf0>
				st.padc = '0'; // pad with 0's instead of spaces
  102123:	c7 45 d0 30 00 00 00 	movl   $0x30,0xffffffd0(%ebp)
		case '1': case '2': case '3': case '4':
		case '5': case '6': case '7': case '8': case '9':
			for (st.prec = 0; ; ++fmt) {
  10212a:	c7 45 d8 00 00 00 00 	movl   $0x0,0xffffffd8(%ebp)
				st.prec = st.prec * 10 + ch - '0';
  102131:	8b 55 d8             	mov    0xffffffd8(%ebp),%edx
  102134:	89 d0                	mov    %edx,%eax
  102136:	c1 e0 02             	shl    $0x2,%eax
  102139:	01 d0                	add    %edx,%eax
  10213b:	01 c0                	add    %eax,%eax
  10213d:	03 45 c4             	add    0xffffffc4(%ebp),%eax
  102140:	83 e8 30             	sub    $0x30,%eax
  102143:	89 45 d8             	mov    %eax,0xffffffd8(%ebp)
				ch = *fmt;
  102146:	8b 45 10             	mov    0x10(%ebp),%eax
  102149:	0f b6 00             	movzbl (%eax),%eax
  10214c:	0f be c0             	movsbl %al,%eax
  10214f:	89 45 c4             	mov    %eax,0xffffffc4(%ebp)
				if (ch < '0' || ch > '9')
  102152:	83 7d c4 2f          	cmpl   $0x2f,0xffffffc4(%ebp)
  102156:	7e 20                	jle    102178 <vprintfmt+0x13e>
  102158:	83 7d c4 39          	cmpl   $0x39,0xffffffc4(%ebp)
  10215c:	7f 1a                	jg     102178 <vprintfmt+0x13e>
  10215e:	83 45 10 01          	addl   $0x1,0x10(%ebp)
					break;
			}
  102162:	eb cd                	jmp    102131 <vprintfmt+0xf7>
			goto gotprec;

		case '*':
			st.prec = va_arg(ap, int);
  102164:	8b 45 14             	mov    0x14(%ebp),%eax
  102167:	83 c0 04             	add    $0x4,%eax
  10216a:	89 45 14             	mov    %eax,0x14(%ebp)
  10216d:	8b 45 14             	mov    0x14(%ebp),%eax
  102170:	83 e8 04             	sub    $0x4,%eax
  102173:	8b 00                	mov    (%eax),%eax
  102175:	89 45 d8             	mov    %eax,0xffffffd8(%ebp)
		gotprec:
			if (!(st.flags & F_DOT)) {	// haven't seen a '.' yet?
  102178:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  10217b:	83 e0 08             	and    $0x8,%eax
  10217e:	85 c0                	test   %eax,%eax
  102180:	0f 85 40 ff ff ff    	jne    1020c6 <vprintfmt+0x8c>
				st.width = st.prec;	// then it's a field width
  102186:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  102189:	89 45 d4             	mov    %eax,0xffffffd4(%ebp)
				st.prec = -1;
  10218c:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,0xffffffd8(%ebp)
			}
			goto reswitch;
  102193:	e9 2e ff ff ff       	jmp    1020c6 <vprintfmt+0x8c>

		case '.':
			st.flags |= F_DOT;
  102198:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  10219b:	83 c8 08             	or     $0x8,%eax
  10219e:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)
			goto reswitch;
  1021a1:	e9 20 ff ff ff       	jmp    1020c6 <vprintfmt+0x8c>

		case '#':
			st.flags |= F_ALT;
  1021a6:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  1021a9:	83 c8 04             	or     $0x4,%eax
  1021ac:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)
			goto reswitch;
  1021af:	e9 12 ff ff ff       	jmp    1020c6 <vprintfmt+0x8c>

		// long flag (doubled for long long)
		case 'l':
			st.flags |= (st.flags & F_L) ? F_LL : F_L;
  1021b4:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  1021b7:	89 45 bc             	mov    %eax,0xffffffbc(%ebp)
  1021ba:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  1021bd:	83 e0 01             	and    $0x1,%eax
  1021c0:	84 c0                	test   %al,%al
  1021c2:	74 09                	je     1021cd <vprintfmt+0x193>
  1021c4:	c7 45 c0 02 00 00 00 	movl   $0x2,0xffffffc0(%ebp)
  1021cb:	eb 07                	jmp    1021d4 <vprintfmt+0x19a>
  1021cd:	c7 45 c0 01 00 00 00 	movl   $0x1,0xffffffc0(%ebp)
  1021d4:	8b 45 bc             	mov    0xffffffbc(%ebp),%eax
  1021d7:	0b 45 c0             	or     0xffffffc0(%ebp),%eax
  1021da:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)
			goto reswitch;
  1021dd:	e9 e4 fe ff ff       	jmp    1020c6 <vprintfmt+0x8c>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  1021e2:	8b 45 14             	mov    0x14(%ebp),%eax
  1021e5:	83 c0 04             	add    $0x4,%eax
  1021e8:	89 45 14             	mov    %eax,0x14(%ebp)
  1021eb:	8b 45 14             	mov    0x14(%ebp),%eax
  1021ee:	83 e8 04             	sub    $0x4,%eax
  1021f1:	8b 10                	mov    (%eax),%edx
  1021f3:	8b 45 0c             	mov    0xc(%ebp),%eax
  1021f6:	89 44 24 04          	mov    %eax,0x4(%esp)
  1021fa:	89 14 24             	mov    %edx,(%esp)
  1021fd:	8b 45 08             	mov    0x8(%ebp),%eax
  102200:	ff d0                	call   *%eax
			break;
  102202:	e9 78 fe ff ff       	jmp    10207f <vprintfmt+0x45>

		// string
		case 's': {
			const char *s;
			if ((s = va_arg(ap, char *)) == NULL)
  102207:	8b 45 14             	mov    0x14(%ebp),%eax
  10220a:	83 c0 04             	add    $0x4,%eax
  10220d:	89 45 14             	mov    %eax,0x14(%ebp)
  102210:	8b 45 14             	mov    0x14(%ebp),%eax
  102213:	83 e8 04             	sub    $0x4,%eax
  102216:	8b 00                	mov    (%eax),%eax
  102218:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
  10221b:	83 7d f4 00          	cmpl   $0x0,0xfffffff4(%ebp)
  10221f:	75 07                	jne    102228 <vprintfmt+0x1ee>
				s = "(null)";
  102221:	c7 45 f4 fd 34 10 00 	movl   $0x1034fd,0xfffffff4(%ebp)
			putstr(&st, s, st.prec);
  102228:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
  10222b:	89 44 24 08          	mov    %eax,0x8(%esp)
  10222f:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  102232:	89 44 24 04          	mov    %eax,0x4(%esp)
  102236:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
  102239:	89 04 24             	mov    %eax,(%esp)
  10223c:	e8 f2 fb ff ff       	call   101e33 <putstr>
			break;
  102241:	e9 39 fe ff ff       	jmp    10207f <vprintfmt+0x45>
		    }

		// (signed) decimal
		case 'd':
			num = getint(&st, &ap);
  102246:	8d 45 14             	lea    0x14(%ebp),%eax
  102249:	89 44 24 04          	mov    %eax,0x4(%esp)
  10224d:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
  102250:	89 04 24             	mov    %eax,(%esp)
  102253:	e8 0e fb ff ff       	call   101d66 <getint>
  102258:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  10225b:	89 55 ec             	mov    %edx,0xffffffec(%ebp)
			if ((intmax_t) num < 0) {
  10225e:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  102261:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
  102264:	85 d2                	test   %edx,%edx
  102266:	79 1a                	jns    102282 <vprintfmt+0x248>
				num = -(intmax_t) num;
  102268:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  10226b:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
  10226e:	f7 d8                	neg    %eax
  102270:	83 d2 00             	adc    $0x0,%edx
  102273:	f7 da                	neg    %edx
  102275:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  102278:	89 55 ec             	mov    %edx,0xffffffec(%ebp)
				st.signc = '-';
  10227b:	c7 45 dc 2d 00 00 00 	movl   $0x2d,0xffffffdc(%ebp)
			}
			putint(&st, num, 10);
  102282:	c7 44 24 0c 0a 00 00 	movl   $0xa,0xc(%esp)
  102289:	00 
  10228a:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  10228d:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
  102290:	89 44 24 04          	mov    %eax,0x4(%esp)
  102294:	89 54 24 08          	mov    %edx,0x8(%esp)
  102298:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
  10229b:	89 04 24             	mov    %eax,(%esp)
  10229e:	e8 2f fd ff ff       	call   101fd2 <putint>
			break;
  1022a3:	e9 d7 fd ff ff       	jmp    10207f <vprintfmt+0x45>

		// unsigned decimal
		case 'u':
			putint(&st, getuint(&st, &ap), 10);
  1022a8:	8d 45 14             	lea    0x14(%ebp),%eax
  1022ab:	89 44 24 04          	mov    %eax,0x4(%esp)
  1022af:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
  1022b2:	89 04 24             	mov    %eax,(%esp)
  1022b5:	e8 1e fa ff ff       	call   101cd8 <getuint>
  1022ba:	c7 44 24 0c 0a 00 00 	movl   $0xa,0xc(%esp)
  1022c1:	00 
  1022c2:	89 44 24 04          	mov    %eax,0x4(%esp)
  1022c6:	89 54 24 08          	mov    %edx,0x8(%esp)
  1022ca:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
  1022cd:	89 04 24             	mov    %eax,(%esp)
  1022d0:	e8 fd fc ff ff       	call   101fd2 <putint>
			break;
  1022d5:	e9 a5 fd ff ff       	jmp    10207f <vprintfmt+0x45>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putint(&st, getuint(&st, &ap), 8);
  1022da:	8d 45 14             	lea    0x14(%ebp),%eax
  1022dd:	89 44 24 04          	mov    %eax,0x4(%esp)
  1022e1:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
  1022e4:	89 04 24             	mov    %eax,(%esp)
  1022e7:	e8 ec f9 ff ff       	call   101cd8 <getuint>
  1022ec:	c7 44 24 0c 08 00 00 	movl   $0x8,0xc(%esp)
  1022f3:	00 
  1022f4:	89 44 24 04          	mov    %eax,0x4(%esp)
  1022f8:	89 54 24 08          	mov    %edx,0x8(%esp)
  1022fc:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
  1022ff:	89 04 24             	mov    %eax,(%esp)
  102302:	e8 cb fc ff ff       	call   101fd2 <putint>
			break;
  102307:	e9 73 fd ff ff       	jmp    10207f <vprintfmt+0x45>

		// (unsigned) hexadecimal
		case 'x':
			putint(&st, getuint(&st, &ap), 16);
  10230c:	8d 45 14             	lea    0x14(%ebp),%eax
  10230f:	89 44 24 04          	mov    %eax,0x4(%esp)
  102313:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
  102316:	89 04 24             	mov    %eax,(%esp)
  102319:	e8 ba f9 ff ff       	call   101cd8 <getuint>
  10231e:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
  102325:	00 
  102326:	89 44 24 04          	mov    %eax,0x4(%esp)
  10232a:	89 54 24 08          	mov    %edx,0x8(%esp)
  10232e:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
  102331:	89 04 24             	mov    %eax,(%esp)
  102334:	e8 99 fc ff ff       	call   101fd2 <putint>
			break;
  102339:	e9 41 fd ff ff       	jmp    10207f <vprintfmt+0x45>

		// pointer
		case 'p':
			putch('0', putdat);
  10233e:	8b 45 0c             	mov    0xc(%ebp),%eax
  102341:	89 44 24 04          	mov    %eax,0x4(%esp)
  102345:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  10234c:	8b 45 08             	mov    0x8(%ebp),%eax
  10234f:	ff d0                	call   *%eax
			putch('x', putdat);
  102351:	8b 45 0c             	mov    0xc(%ebp),%eax
  102354:	89 44 24 04          	mov    %eax,0x4(%esp)
  102358:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  10235f:	8b 45 08             	mov    0x8(%ebp),%eax
  102362:	ff d0                	call   *%eax
			putint(&st, (uintptr_t) va_arg(ap, void *), 16);
  102364:	8b 45 14             	mov    0x14(%ebp),%eax
  102367:	83 c0 04             	add    $0x4,%eax
  10236a:	89 45 14             	mov    %eax,0x14(%ebp)
  10236d:	8b 45 14             	mov    0x14(%ebp),%eax
  102370:	83 e8 04             	sub    $0x4,%eax
  102373:	8b 00                	mov    (%eax),%eax
  102375:	ba 00 00 00 00       	mov    $0x0,%edx
  10237a:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
  102381:	00 
  102382:	89 44 24 04          	mov    %eax,0x4(%esp)
  102386:	89 54 24 08          	mov    %edx,0x8(%esp)
  10238a:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
  10238d:	89 04 24             	mov    %eax,(%esp)
  102390:	e8 3d fc ff ff       	call   101fd2 <putint>
			break;
  102395:	e9 e5 fc ff ff       	jmp    10207f <vprintfmt+0x45>

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
  10239a:	8b 45 0c             	mov    0xc(%ebp),%eax
  10239d:	89 44 24 04          	mov    %eax,0x4(%esp)
  1023a1:	8b 55 c4             	mov    0xffffffc4(%ebp),%edx
  1023a4:	89 14 24             	mov    %edx,(%esp)
  1023a7:	8b 45 08             	mov    0x8(%ebp),%eax
  1023aa:	ff d0                	call   *%eax
			break;
  1023ac:	e9 ce fc ff ff       	jmp    10207f <vprintfmt+0x45>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  1023b1:	8b 45 0c             	mov    0xc(%ebp),%eax
  1023b4:	89 44 24 04          	mov    %eax,0x4(%esp)
  1023b8:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  1023bf:	8b 45 08             	mov    0x8(%ebp),%eax
  1023c2:	ff d0                	call   *%eax
			for (fmt--; fmt[-1] != '%'; fmt--)
  1023c4:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  1023c8:	eb 04                	jmp    1023ce <vprintfmt+0x394>
  1023ca:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  1023ce:	8b 45 10             	mov    0x10(%ebp),%eax
  1023d1:	83 e8 01             	sub    $0x1,%eax
  1023d4:	0f b6 00             	movzbl (%eax),%eax
  1023d7:	3c 25                	cmp    $0x25,%al
  1023d9:	75 ef                	jne    1023ca <vprintfmt+0x390>
				/* do nothing */;
			break;
		}
	}
  1023db:	e9 9f fc ff ff       	jmp    10207f <vprintfmt+0x45>
}
  1023e0:	83 c4 54             	add    $0x54,%esp
  1023e3:	5f                   	pop    %edi
  1023e4:	5d                   	pop    %ebp
  1023e5:	c3                   	ret    
  1023e6:	90                   	nop    
  1023e7:	90                   	nop    

001023e8 <putch>:


static void
putch(int ch, struct printbuf *b)
{
  1023e8:	55                   	push   %ebp
  1023e9:	89 e5                	mov    %esp,%ebp
  1023eb:	83 ec 08             	sub    $0x8,%esp
	b->buf[b->idx++] = ch; // idx returns current value, not incremented value
  1023ee:	8b 45 0c             	mov    0xc(%ebp),%eax
  1023f1:	8b 08                	mov    (%eax),%ecx
  1023f3:	8b 45 08             	mov    0x8(%ebp),%eax
  1023f6:	89 c2                	mov    %eax,%edx
  1023f8:	8b 45 0c             	mov    0xc(%ebp),%eax
  1023fb:	88 54 08 08          	mov    %dl,0x8(%eax,%ecx,1)
  1023ff:	8d 51 01             	lea    0x1(%ecx),%edx
  102402:	8b 45 0c             	mov    0xc(%ebp),%eax
  102405:	89 10                	mov    %edx,(%eax)
	if (b->idx == CPUTS_MAX-1) {
  102407:	8b 45 0c             	mov    0xc(%ebp),%eax
  10240a:	8b 00                	mov    (%eax),%eax
  10240c:	3d ff 00 00 00       	cmp    $0xff,%eax
  102411:	75 24                	jne    102437 <putch+0x4f>
		b->buf[b->idx] = 0;
  102413:	8b 45 0c             	mov    0xc(%ebp),%eax
  102416:	8b 10                	mov    (%eax),%edx
  102418:	8b 45 0c             	mov    0xc(%ebp),%eax
  10241b:	c6 44 10 08 00       	movb   $0x0,0x8(%eax,%edx,1)
		cputs(b->buf);
  102420:	8b 45 0c             	mov    0xc(%ebp),%eax
  102423:	83 c0 08             	add    $0x8,%eax
  102426:	89 04 24             	mov    %eax,(%esp)
  102429:	e8 db de ff ff       	call   100309 <cputs>
		b->idx = 0;
  10242e:	8b 45 0c             	mov    0xc(%ebp),%eax
  102431:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	}
	b->cnt++;
  102437:	8b 45 0c             	mov    0xc(%ebp),%eax
  10243a:	8b 40 04             	mov    0x4(%eax),%eax
  10243d:	8d 50 01             	lea    0x1(%eax),%edx
  102440:	8b 45 0c             	mov    0xc(%ebp),%eax
  102443:	89 50 04             	mov    %edx,0x4(%eax)
}
  102446:	c9                   	leave  
  102447:	c3                   	ret    

00102448 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  102448:	55                   	push   %ebp
  102449:	89 e5                	mov    %esp,%ebp
  10244b:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  102451:	c7 85 f8 fe ff ff 00 	movl   $0x0,0xfffffef8(%ebp)
  102458:	00 00 00 
	b.cnt = 0;
  10245b:	c7 85 fc fe ff ff 00 	movl   $0x0,0xfffffefc(%ebp)
  102462:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  102465:	ba e8 23 10 00       	mov    $0x1023e8,%edx
  10246a:	8b 45 0c             	mov    0xc(%ebp),%eax
  10246d:	89 44 24 0c          	mov    %eax,0xc(%esp)
  102471:	8b 45 08             	mov    0x8(%ebp),%eax
  102474:	89 44 24 08          	mov    %eax,0x8(%esp)
  102478:	8d 85 f8 fe ff ff    	lea    0xfffffef8(%ebp),%eax
  10247e:	89 44 24 04          	mov    %eax,0x4(%esp)
  102482:	89 14 24             	mov    %edx,(%esp)
  102485:	e8 b0 fb ff ff       	call   10203a <vprintfmt>

	b.buf[b.idx] = 0;
  10248a:	8b 85 f8 fe ff ff    	mov    0xfffffef8(%ebp),%eax
  102490:	c6 84 05 00 ff ff ff 	movb   $0x0,0xffffff00(%ebp,%eax,1)
  102497:	00 
	cputs(b.buf);
  102498:	8d 85 f8 fe ff ff    	lea    0xfffffef8(%ebp),%eax
  10249e:	83 c0 08             	add    $0x8,%eax
  1024a1:	89 04 24             	mov    %eax,(%esp)
  1024a4:	e8 60 de ff ff       	call   100309 <cputs>

	return b.cnt;
  1024a9:	8b 85 fc fe ff ff    	mov    0xfffffefc(%ebp),%eax
}
  1024af:	c9                   	leave  
  1024b0:	c3                   	ret    

001024b1 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  1024b1:	55                   	push   %ebp
  1024b2:	89 e5                	mov    %esp,%ebp
  1024b4:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  1024b7:	8d 45 08             	lea    0x8(%ebp),%eax
  1024ba:	83 c0 04             	add    $0x4,%eax
  1024bd:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
	cnt = vcprintf(fmt, ap);
  1024c0:	8b 55 08             	mov    0x8(%ebp),%edx
  1024c3:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  1024c6:	89 44 24 04          	mov    %eax,0x4(%esp)
  1024ca:	89 14 24             	mov    %edx,(%esp)
  1024cd:	e8 76 ff ff ff       	call   102448 <vcprintf>
  1024d2:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	va_end(ap);

	return cnt;
  1024d5:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
}
  1024d8:	c9                   	leave  
  1024d9:	c3                   	ret    
  1024da:	90                   	nop    
  1024db:	90                   	nop    

001024dc <strlen>:
#define ASM 1

int
strlen(const char *s)
{
  1024dc:	55                   	push   %ebp
  1024dd:	89 e5                	mov    %esp,%ebp
  1024df:	83 ec 10             	sub    $0x10,%esp
	int n;

	for (n = 0; *s != '\0'; s++)
  1024e2:	c7 45 fc 00 00 00 00 	movl   $0x0,0xfffffffc(%ebp)
  1024e9:	eb 08                	jmp    1024f3 <strlen+0x17>
		n++;
  1024eb:	83 45 fc 01          	addl   $0x1,0xfffffffc(%ebp)
  1024ef:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  1024f3:	8b 45 08             	mov    0x8(%ebp),%eax
  1024f6:	0f b6 00             	movzbl (%eax),%eax
  1024f9:	84 c0                	test   %al,%al
  1024fb:	75 ee                	jne    1024eb <strlen+0xf>
	return n;
  1024fd:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
}
  102500:	c9                   	leave  
  102501:	c3                   	ret    

00102502 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  102502:	55                   	push   %ebp
  102503:	89 e5                	mov    %esp,%ebp
  102505:	83 ec 10             	sub    $0x10,%esp
	char *ret;

	ret = dst;
  102508:	8b 45 08             	mov    0x8(%ebp),%eax
  10250b:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	while ((*dst++ = *src++) != '\0')
  10250e:	8b 45 0c             	mov    0xc(%ebp),%eax
  102511:	0f b6 10             	movzbl (%eax),%edx
  102514:	8b 45 08             	mov    0x8(%ebp),%eax
  102517:	88 10                	mov    %dl,(%eax)
  102519:	8b 45 08             	mov    0x8(%ebp),%eax
  10251c:	0f b6 00             	movzbl (%eax),%eax
  10251f:	84 c0                	test   %al,%al
  102521:	0f 95 c0             	setne  %al
  102524:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  102528:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
  10252c:	84 c0                	test   %al,%al
  10252e:	75 de                	jne    10250e <strcpy+0xc>
		/* do nothing */;
	return ret;
  102530:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
}
  102533:	c9                   	leave  
  102534:	c3                   	ret    

00102535 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size)
{
  102535:	55                   	push   %ebp
  102536:	89 e5                	mov    %esp,%ebp
  102538:	83 ec 10             	sub    $0x10,%esp
	size_t i;
	char *ret;

	ret = dst;
  10253b:	8b 45 08             	mov    0x8(%ebp),%eax
  10253e:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	for (i = 0; i < size; i++) {
  102541:	c7 45 f8 00 00 00 00 	movl   $0x0,0xfffffff8(%ebp)
  102548:	eb 21                	jmp    10256b <strncpy+0x36>
		*dst++ = *src;
  10254a:	8b 45 0c             	mov    0xc(%ebp),%eax
  10254d:	0f b6 10             	movzbl (%eax),%edx
  102550:	8b 45 08             	mov    0x8(%ebp),%eax
  102553:	88 10                	mov    %dl,(%eax)
  102555:	83 45 08 01          	addl   $0x1,0x8(%ebp)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
  102559:	8b 45 0c             	mov    0xc(%ebp),%eax
  10255c:	0f b6 00             	movzbl (%eax),%eax
  10255f:	84 c0                	test   %al,%al
  102561:	74 04                	je     102567 <strncpy+0x32>
			src++;
  102563:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
  102567:	83 45 f8 01          	addl   $0x1,0xfffffff8(%ebp)
  10256b:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  10256e:	3b 45 10             	cmp    0x10(%ebp),%eax
  102571:	72 d7                	jb     10254a <strncpy+0x15>
	}
	return ret;
  102573:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
}
  102576:	c9                   	leave  
  102577:	c3                   	ret    

00102578 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  102578:	55                   	push   %ebp
  102579:	89 e5                	mov    %esp,%ebp
  10257b:	83 ec 10             	sub    $0x10,%esp
	char *dst_in;

	dst_in = dst;
  10257e:	8b 45 08             	mov    0x8(%ebp),%eax
  102581:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	if (size > 0) {
  102584:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  102588:	74 2f                	je     1025b9 <strlcpy+0x41>
		while (--size > 0 && *src != '\0')
  10258a:	eb 13                	jmp    10259f <strlcpy+0x27>
			*dst++ = *src++;
  10258c:	8b 45 0c             	mov    0xc(%ebp),%eax
  10258f:	0f b6 10             	movzbl (%eax),%edx
  102592:	8b 45 08             	mov    0x8(%ebp),%eax
  102595:	88 10                	mov    %dl,(%eax)
  102597:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  10259b:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
  10259f:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  1025a3:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  1025a7:	74 0a                	je     1025b3 <strlcpy+0x3b>
  1025a9:	8b 45 0c             	mov    0xc(%ebp),%eax
  1025ac:	0f b6 00             	movzbl (%eax),%eax
  1025af:	84 c0                	test   %al,%al
  1025b1:	75 d9                	jne    10258c <strlcpy+0x14>
		*dst = '\0';
  1025b3:	8b 45 08             	mov    0x8(%ebp),%eax
  1025b6:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  1025b9:	8b 55 08             	mov    0x8(%ebp),%edx
  1025bc:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  1025bf:	89 d1                	mov    %edx,%ecx
  1025c1:	29 c1                	sub    %eax,%ecx
  1025c3:	89 c8                	mov    %ecx,%eax
}
  1025c5:	c9                   	leave  
  1025c6:	c3                   	ret    

001025c7 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  1025c7:	55                   	push   %ebp
  1025c8:	89 e5                	mov    %esp,%ebp
	while (*p && *p == *q)
  1025ca:	eb 08                	jmp    1025d4 <strcmp+0xd>
		p++, q++;
  1025cc:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  1025d0:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
  1025d4:	8b 45 08             	mov    0x8(%ebp),%eax
  1025d7:	0f b6 00             	movzbl (%eax),%eax
  1025da:	84 c0                	test   %al,%al
  1025dc:	74 10                	je     1025ee <strcmp+0x27>
  1025de:	8b 45 08             	mov    0x8(%ebp),%eax
  1025e1:	0f b6 10             	movzbl (%eax),%edx
  1025e4:	8b 45 0c             	mov    0xc(%ebp),%eax
  1025e7:	0f b6 00             	movzbl (%eax),%eax
  1025ea:	38 c2                	cmp    %al,%dl
  1025ec:	74 de                	je     1025cc <strcmp+0x5>
	return (int) ((unsigned char) *p - (unsigned char) *q);
  1025ee:	8b 45 08             	mov    0x8(%ebp),%eax
  1025f1:	0f b6 00             	movzbl (%eax),%eax
  1025f4:	0f b6 d0             	movzbl %al,%edx
  1025f7:	8b 45 0c             	mov    0xc(%ebp),%eax
  1025fa:	0f b6 00             	movzbl (%eax),%eax
  1025fd:	0f b6 c0             	movzbl %al,%eax
  102600:	89 d1                	mov    %edx,%ecx
  102602:	29 c1                	sub    %eax,%ecx
  102604:	89 c8                	mov    %ecx,%eax
}
  102606:	5d                   	pop    %ebp
  102607:	c3                   	ret    

00102608 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  102608:	55                   	push   %ebp
  102609:	89 e5                	mov    %esp,%ebp
  10260b:	83 ec 04             	sub    $0x4,%esp
	while (n > 0 && *p && *p == *q)
  10260e:	eb 0c                	jmp    10261c <strncmp+0x14>
		n--, p++, q++;
  102610:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  102614:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  102618:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
  10261c:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  102620:	74 1a                	je     10263c <strncmp+0x34>
  102622:	8b 45 08             	mov    0x8(%ebp),%eax
  102625:	0f b6 00             	movzbl (%eax),%eax
  102628:	84 c0                	test   %al,%al
  10262a:	74 10                	je     10263c <strncmp+0x34>
  10262c:	8b 45 08             	mov    0x8(%ebp),%eax
  10262f:	0f b6 10             	movzbl (%eax),%edx
  102632:	8b 45 0c             	mov    0xc(%ebp),%eax
  102635:	0f b6 00             	movzbl (%eax),%eax
  102638:	38 c2                	cmp    %al,%dl
  10263a:	74 d4                	je     102610 <strncmp+0x8>
	if (n == 0)
  10263c:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  102640:	75 09                	jne    10264b <strncmp+0x43>
		return 0;
  102642:	c7 45 fc 00 00 00 00 	movl   $0x0,0xfffffffc(%ebp)
  102649:	eb 19                	jmp    102664 <strncmp+0x5c>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  10264b:	8b 45 08             	mov    0x8(%ebp),%eax
  10264e:	0f b6 00             	movzbl (%eax),%eax
  102651:	0f b6 d0             	movzbl %al,%edx
  102654:	8b 45 0c             	mov    0xc(%ebp),%eax
  102657:	0f b6 00             	movzbl (%eax),%eax
  10265a:	0f b6 c0             	movzbl %al,%eax
  10265d:	89 d1                	mov    %edx,%ecx
  10265f:	29 c1                	sub    %eax,%ecx
  102661:	89 4d fc             	mov    %ecx,0xfffffffc(%ebp)
  102664:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
}
  102667:	c9                   	leave  
  102668:	c3                   	ret    

00102669 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  102669:	55                   	push   %ebp
  10266a:	89 e5                	mov    %esp,%ebp
  10266c:	83 ec 08             	sub    $0x8,%esp
  10266f:	8b 45 0c             	mov    0xc(%ebp),%eax
  102672:	88 45 fc             	mov    %al,0xfffffffc(%ebp)
	while (*s != c)
  102675:	eb 1c                	jmp    102693 <strchr+0x2a>
		if (*s++ == 0)
  102677:	8b 45 08             	mov    0x8(%ebp),%eax
  10267a:	0f b6 00             	movzbl (%eax),%eax
  10267d:	84 c0                	test   %al,%al
  10267f:	0f 94 c0             	sete   %al
  102682:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  102686:	84 c0                	test   %al,%al
  102688:	74 09                	je     102693 <strchr+0x2a>
			return NULL;
  10268a:	c7 45 f8 00 00 00 00 	movl   $0x0,0xfffffff8(%ebp)
  102691:	eb 11                	jmp    1026a4 <strchr+0x3b>
  102693:	8b 45 08             	mov    0x8(%ebp),%eax
  102696:	0f b6 00             	movzbl (%eax),%eax
  102699:	3a 45 fc             	cmp    0xfffffffc(%ebp),%al
  10269c:	75 d9                	jne    102677 <strchr+0xe>
	return (char *) s;
  10269e:	8b 45 08             	mov    0x8(%ebp),%eax
  1026a1:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
  1026a4:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
}
  1026a7:	c9                   	leave  
  1026a8:	c3                   	ret    

001026a9 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  1026a9:	55                   	push   %ebp
  1026aa:	89 e5                	mov    %esp,%ebp
  1026ac:	57                   	push   %edi
  1026ad:	83 ec 14             	sub    $0x14,%esp
	char *p;

	if (n == 0)
  1026b0:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  1026b4:	75 08                	jne    1026be <memset+0x15>
		return v;
  1026b6:	8b 45 08             	mov    0x8(%ebp),%eax
  1026b9:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  1026bc:	eb 5b                	jmp    102719 <memset+0x70>
	if ((int)v%4 == 0 && n%4 == 0) {
  1026be:	8b 45 08             	mov    0x8(%ebp),%eax
  1026c1:	83 e0 03             	and    $0x3,%eax
  1026c4:	85 c0                	test   %eax,%eax
  1026c6:	75 3f                	jne    102707 <memset+0x5e>
  1026c8:	8b 45 10             	mov    0x10(%ebp),%eax
  1026cb:	83 e0 03             	and    $0x3,%eax
  1026ce:	85 c0                	test   %eax,%eax
  1026d0:	75 35                	jne    102707 <memset+0x5e>
		c &= 0xFF;
  1026d2:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
		c = (c<<24)|(c<<16)|(c<<8)|c;
  1026d9:	8b 45 0c             	mov    0xc(%ebp),%eax
  1026dc:	89 c2                	mov    %eax,%edx
  1026de:	c1 e2 18             	shl    $0x18,%edx
  1026e1:	8b 45 0c             	mov    0xc(%ebp),%eax
  1026e4:	c1 e0 10             	shl    $0x10,%eax
  1026e7:	09 c2                	or     %eax,%edx
  1026e9:	8b 45 0c             	mov    0xc(%ebp),%eax
  1026ec:	c1 e0 08             	shl    $0x8,%eax
  1026ef:	09 d0                	or     %edx,%eax
  1026f1:	09 45 0c             	or     %eax,0xc(%ebp)
		asm volatile("cld; rep stosl\n"
  1026f4:	8b 45 10             	mov    0x10(%ebp),%eax
  1026f7:	89 c1                	mov    %eax,%ecx
  1026f9:	c1 e9 02             	shr    $0x2,%ecx
  1026fc:	8b 7d 08             	mov    0x8(%ebp),%edi
  1026ff:	8b 45 0c             	mov    0xc(%ebp),%eax
  102702:	fc                   	cld    
  102703:	f3 ab                	rep stos %eax,%es:(%edi)
  102705:	eb 0c                	jmp    102713 <memset+0x6a>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  102707:	8b 7d 08             	mov    0x8(%ebp),%edi
  10270a:	8b 45 0c             	mov    0xc(%ebp),%eax
  10270d:	8b 4d 10             	mov    0x10(%ebp),%ecx
  102710:	fc                   	cld    
  102711:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
  102713:	8b 45 08             	mov    0x8(%ebp),%eax
  102716:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  102719:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
}
  10271c:	83 c4 14             	add    $0x14,%esp
  10271f:	5f                   	pop    %edi
  102720:	5d                   	pop    %ebp
  102721:	c3                   	ret    

00102722 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  102722:	55                   	push   %ebp
  102723:	89 e5                	mov    %esp,%ebp
  102725:	57                   	push   %edi
  102726:	56                   	push   %esi
  102727:	83 ec 10             	sub    $0x10,%esp
	const char *s;
	char *d;
	
	s = src;
  10272a:	8b 45 0c             	mov    0xc(%ebp),%eax
  10272d:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
	d = dst;
  102730:	8b 45 08             	mov    0x8(%ebp),%eax
  102733:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
	if (s < d && s + n > d) {
  102736:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  102739:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  10273c:	73 63                	jae    1027a1 <memmove+0x7f>
  10273e:	8b 45 10             	mov    0x10(%ebp),%eax
  102741:	03 45 f0             	add    0xfffffff0(%ebp),%eax
  102744:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
  102747:	76 58                	jbe    1027a1 <memmove+0x7f>
		s += n;
  102749:	8b 45 10             	mov    0x10(%ebp),%eax
  10274c:	01 45 f0             	add    %eax,0xfffffff0(%ebp)
		d += n;
  10274f:	8b 45 10             	mov    0x10(%ebp),%eax
  102752:	01 45 f4             	add    %eax,0xfffffff4(%ebp)
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  102755:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  102758:	83 e0 03             	and    $0x3,%eax
  10275b:	85 c0                	test   %eax,%eax
  10275d:	75 2d                	jne    10278c <memmove+0x6a>
  10275f:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  102762:	83 e0 03             	and    $0x3,%eax
  102765:	85 c0                	test   %eax,%eax
  102767:	75 23                	jne    10278c <memmove+0x6a>
  102769:	8b 45 10             	mov    0x10(%ebp),%eax
  10276c:	83 e0 03             	and    $0x3,%eax
  10276f:	85 c0                	test   %eax,%eax
  102771:	75 19                	jne    10278c <memmove+0x6a>
			asm volatile("std; rep movsl\n"
  102773:	8b 7d f4             	mov    0xfffffff4(%ebp),%edi
  102776:	83 ef 04             	sub    $0x4,%edi
  102779:	8b 75 f0             	mov    0xfffffff0(%ebp),%esi
  10277c:	83 ee 04             	sub    $0x4,%esi
  10277f:	8b 45 10             	mov    0x10(%ebp),%eax
  102782:	89 c1                	mov    %eax,%ecx
  102784:	c1 e9 02             	shr    $0x2,%ecx
  102787:	fd                   	std    
  102788:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  10278a:	eb 12                	jmp    10279e <memmove+0x7c>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  10278c:	8b 7d f4             	mov    0xfffffff4(%ebp),%edi
  10278f:	83 ef 01             	sub    $0x1,%edi
  102792:	8b 75 f0             	mov    0xfffffff0(%ebp),%esi
  102795:	83 ee 01             	sub    $0x1,%esi
  102798:	8b 4d 10             	mov    0x10(%ebp),%ecx
  10279b:	fd                   	std    
  10279c:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  10279e:	fc                   	cld    
  10279f:	eb 3d                	jmp    1027de <memmove+0xbc>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  1027a1:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  1027a4:	83 e0 03             	and    $0x3,%eax
  1027a7:	85 c0                	test   %eax,%eax
  1027a9:	75 27                	jne    1027d2 <memmove+0xb0>
  1027ab:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  1027ae:	83 e0 03             	and    $0x3,%eax
  1027b1:	85 c0                	test   %eax,%eax
  1027b3:	75 1d                	jne    1027d2 <memmove+0xb0>
  1027b5:	8b 45 10             	mov    0x10(%ebp),%eax
  1027b8:	83 e0 03             	and    $0x3,%eax
  1027bb:	85 c0                	test   %eax,%eax
  1027bd:	75 13                	jne    1027d2 <memmove+0xb0>
			asm volatile("cld; rep movsl\n"
  1027bf:	8b 45 10             	mov    0x10(%ebp),%eax
  1027c2:	89 c1                	mov    %eax,%ecx
  1027c4:	c1 e9 02             	shr    $0x2,%ecx
  1027c7:	8b 7d f4             	mov    0xfffffff4(%ebp),%edi
  1027ca:	8b 75 f0             	mov    0xfffffff0(%ebp),%esi
  1027cd:	fc                   	cld    
  1027ce:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  1027d0:	eb 0c                	jmp    1027de <memmove+0xbc>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  1027d2:	8b 7d f4             	mov    0xfffffff4(%ebp),%edi
  1027d5:	8b 75 f0             	mov    0xfffffff0(%ebp),%esi
  1027d8:	8b 4d 10             	mov    0x10(%ebp),%ecx
  1027db:	fc                   	cld    
  1027dc:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
  1027de:	8b 45 08             	mov    0x8(%ebp),%eax
}
  1027e1:	83 c4 10             	add    $0x10,%esp
  1027e4:	5e                   	pop    %esi
  1027e5:	5f                   	pop    %edi
  1027e6:	5d                   	pop    %ebp
  1027e7:	c3                   	ret    

001027e8 <memcpy>:

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
  1027e8:	55                   	push   %ebp
  1027e9:	89 e5                	mov    %esp,%ebp
  1027eb:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
  1027ee:	8b 45 10             	mov    0x10(%ebp),%eax
  1027f1:	89 44 24 08          	mov    %eax,0x8(%esp)
  1027f5:	8b 45 0c             	mov    0xc(%ebp),%eax
  1027f8:	89 44 24 04          	mov    %eax,0x4(%esp)
  1027fc:	8b 45 08             	mov    0x8(%ebp),%eax
  1027ff:	89 04 24             	mov    %eax,(%esp)
  102802:	e8 1b ff ff ff       	call   102722 <memmove>
}
  102807:	c9                   	leave  
  102808:	c3                   	ret    

00102809 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  102809:	55                   	push   %ebp
  10280a:	89 e5                	mov    %esp,%ebp
  10280c:	83 ec 14             	sub    $0x14,%esp
	const uint8_t *s1 = (const uint8_t *) v1;
  10280f:	8b 45 08             	mov    0x8(%ebp),%eax
  102812:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
	const uint8_t *s2 = (const uint8_t *) v2;
  102815:	8b 45 0c             	mov    0xc(%ebp),%eax
  102818:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)

	while (n-- > 0) {
  10281b:	eb 33                	jmp    102850 <memcmp+0x47>
		if (*s1 != *s2)
  10281d:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  102820:	0f b6 10             	movzbl (%eax),%edx
  102823:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  102826:	0f b6 00             	movzbl (%eax),%eax
  102829:	38 c2                	cmp    %al,%dl
  10282b:	74 1b                	je     102848 <memcmp+0x3f>
			return (int) *s1 - (int) *s2;
  10282d:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
  102830:	0f b6 00             	movzbl (%eax),%eax
  102833:	0f b6 d0             	movzbl %al,%edx
  102836:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
  102839:	0f b6 00             	movzbl (%eax),%eax
  10283c:	0f b6 c0             	movzbl %al,%eax
  10283f:	89 d1                	mov    %edx,%ecx
  102841:	29 c1                	sub    %eax,%ecx
  102843:	89 4d ec             	mov    %ecx,0xffffffec(%ebp)
  102846:	eb 19                	jmp    102861 <memcmp+0x58>
		s1++, s2++;
  102848:	83 45 f8 01          	addl   $0x1,0xfffffff8(%ebp)
  10284c:	83 45 fc 01          	addl   $0x1,0xfffffffc(%ebp)
  102850:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  102854:	83 7d 10 ff          	cmpl   $0xffffffff,0x10(%ebp)
  102858:	75 c3                	jne    10281d <memcmp+0x14>
	}

	return 0;
  10285a:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  102861:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
}
  102864:	c9                   	leave  
  102865:	c3                   	ret    

00102866 <memchr>:

void *
memchr(const void *s, int c, size_t n)
{
  102866:	55                   	push   %ebp
  102867:	89 e5                	mov    %esp,%ebp
  102869:	83 ec 14             	sub    $0x14,%esp
	const void *ends = (const char *) s + n;
  10286c:	8b 45 08             	mov    0x8(%ebp),%eax
  10286f:	8b 55 10             	mov    0x10(%ebp),%edx
  102872:	01 d0                	add    %edx,%eax
  102874:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	for (; s < ends; s++)
  102877:	eb 19                	jmp    102892 <memchr+0x2c>
		if (*(const unsigned char *) s == (unsigned char) c)
  102879:	8b 45 08             	mov    0x8(%ebp),%eax
  10287c:	0f b6 10             	movzbl (%eax),%edx
  10287f:	8b 45 0c             	mov    0xc(%ebp),%eax
  102882:	38 c2                	cmp    %al,%dl
  102884:	75 08                	jne    10288e <memchr+0x28>
			return (void *) s;
  102886:	8b 45 08             	mov    0x8(%ebp),%eax
  102889:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  10288c:	eb 13                	jmp    1028a1 <memchr+0x3b>
  10288e:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  102892:	8b 45 08             	mov    0x8(%ebp),%eax
  102895:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
  102898:	72 df                	jb     102879 <memchr+0x13>
	return NULL;
  10289a:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
  1028a1:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
}
  1028a4:	c9                   	leave  
  1028a5:	c3                   	ret    
  1028a6:	90                   	nop    
  1028a7:	90                   	nop    
  1028a8:	90                   	nop    
  1028a9:	90                   	nop    
  1028aa:	90                   	nop    
  1028ab:	90                   	nop    
  1028ac:	90                   	nop    
  1028ad:	90                   	nop    
  1028ae:	90                   	nop    
  1028af:	90                   	nop    

001028b0 <__udivdi3>:
  1028b0:	55                   	push   %ebp
  1028b1:	89 e5                	mov    %esp,%ebp
  1028b3:	57                   	push   %edi
  1028b4:	56                   	push   %esi
  1028b5:	83 ec 1c             	sub    $0x1c,%esp
  1028b8:	8b 45 10             	mov    0x10(%ebp),%eax
  1028bb:	8b 55 14             	mov    0x14(%ebp),%edx
  1028be:	8b 7d 0c             	mov    0xc(%ebp),%edi
  1028c1:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
  1028c4:	89 c1                	mov    %eax,%ecx
  1028c6:	8b 45 08             	mov    0x8(%ebp),%eax
  1028c9:	85 d2                	test   %edx,%edx
  1028cb:	89 d6                	mov    %edx,%esi
  1028cd:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
  1028d0:	75 1e                	jne    1028f0 <__udivdi3+0x40>
  1028d2:	39 f9                	cmp    %edi,%ecx
  1028d4:	0f 86 8d 00 00 00    	jbe    102967 <__udivdi3+0xb7>
  1028da:	89 fa                	mov    %edi,%edx
  1028dc:	f7 f1                	div    %ecx
  1028de:	89 c1                	mov    %eax,%ecx
  1028e0:	89 c8                	mov    %ecx,%eax
  1028e2:	89 f2                	mov    %esi,%edx
  1028e4:	83 c4 1c             	add    $0x1c,%esp
  1028e7:	5e                   	pop    %esi
  1028e8:	5f                   	pop    %edi
  1028e9:	5d                   	pop    %ebp
  1028ea:	c3                   	ret    
  1028eb:	90                   	nop    
  1028ec:	8d 74 26 00          	lea    0x0(%esi),%esi
  1028f0:	39 fa                	cmp    %edi,%edx
  1028f2:	0f 87 98 00 00 00    	ja     102990 <__udivdi3+0xe0>
  1028f8:	0f bd c2             	bsr    %edx,%eax
  1028fb:	83 f0 1f             	xor    $0x1f,%eax
  1028fe:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
  102901:	74 7f                	je     102982 <__udivdi3+0xd2>
  102903:	b8 20 00 00 00       	mov    $0x20,%eax
  102908:	8b 55 f0             	mov    0xfffffff0(%ebp),%edx
  10290b:	2b 45 e4             	sub    0xffffffe4(%ebp),%eax
  10290e:	89 c1                	mov    %eax,%ecx
  102910:	d3 ea                	shr    %cl,%edx
  102912:	0f b6 4d e4          	movzbl 0xffffffe4(%ebp),%ecx
  102916:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  102919:	89 f0                	mov    %esi,%eax
  10291b:	d3 e0                	shl    %cl,%eax
  10291d:	09 c2                	or     %eax,%edx
  10291f:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  102922:	89 55 e0             	mov    %edx,0xffffffe0(%ebp)
  102925:	89 fa                	mov    %edi,%edx
  102927:	d3 e0                	shl    %cl,%eax
  102929:	0f b6 4d ec          	movzbl 0xffffffec(%ebp),%ecx
  10292d:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
  102930:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  102933:	d3 e8                	shr    %cl,%eax
  102935:	0f b6 4d e4          	movzbl 0xffffffe4(%ebp),%ecx
  102939:	d3 e2                	shl    %cl,%edx
  10293b:	0f b6 4d ec          	movzbl 0xffffffec(%ebp),%ecx
  10293f:	09 d0                	or     %edx,%eax
  102941:	d3 ef                	shr    %cl,%edi
  102943:	89 fa                	mov    %edi,%edx
  102945:	f7 75 e0             	divl   0xffffffe0(%ebp)
  102948:	89 d1                	mov    %edx,%ecx
  10294a:	89 c7                	mov    %eax,%edi
  10294c:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
  10294f:	f7 e7                	mul    %edi
  102951:	39 d1                	cmp    %edx,%ecx
  102953:	89 c6                	mov    %eax,%esi
  102955:	89 55 dc             	mov    %edx,0xffffffdc(%ebp)
  102958:	72 6f                	jb     1029c9 <__udivdi3+0x119>
  10295a:	39 ca                	cmp    %ecx,%edx
  10295c:	74 5e                	je     1029bc <__udivdi3+0x10c>
  10295e:	89 f9                	mov    %edi,%ecx
  102960:	31 f6                	xor    %esi,%esi
  102962:	e9 79 ff ff ff       	jmp    1028e0 <__udivdi3+0x30>
  102967:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  10296a:	85 c0                	test   %eax,%eax
  10296c:	74 32                	je     1029a0 <__udivdi3+0xf0>
  10296e:	89 f2                	mov    %esi,%edx
  102970:	89 f8                	mov    %edi,%eax
  102972:	f7 f1                	div    %ecx
  102974:	89 c6                	mov    %eax,%esi
  102976:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  102979:	f7 f1                	div    %ecx
  10297b:	89 c1                	mov    %eax,%ecx
  10297d:	e9 5e ff ff ff       	jmp    1028e0 <__udivdi3+0x30>
  102982:	39 d7                	cmp    %edx,%edi
  102984:	77 2a                	ja     1029b0 <__udivdi3+0x100>
  102986:	8b 55 f0             	mov    0xfffffff0(%ebp),%edx
  102989:	39 55 e8             	cmp    %edx,0xffffffe8(%ebp)
  10298c:	73 22                	jae    1029b0 <__udivdi3+0x100>
  10298e:	66 90                	xchg   %ax,%ax
  102990:	31 c9                	xor    %ecx,%ecx
  102992:	31 f6                	xor    %esi,%esi
  102994:	e9 47 ff ff ff       	jmp    1028e0 <__udivdi3+0x30>
  102999:	8d b4 26 00 00 00 00 	lea    0x0(%esi),%esi
  1029a0:	b8 01 00 00 00       	mov    $0x1,%eax
  1029a5:	31 d2                	xor    %edx,%edx
  1029a7:	f7 75 f0             	divl   0xfffffff0(%ebp)
  1029aa:	89 c1                	mov    %eax,%ecx
  1029ac:	eb c0                	jmp    10296e <__udivdi3+0xbe>
  1029ae:	66 90                	xchg   %ax,%ax
  1029b0:	b9 01 00 00 00       	mov    $0x1,%ecx
  1029b5:	31 f6                	xor    %esi,%esi
  1029b7:	e9 24 ff ff ff       	jmp    1028e0 <__udivdi3+0x30>
  1029bc:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  1029bf:	0f b6 4d e4          	movzbl 0xffffffe4(%ebp),%ecx
  1029c3:	d3 e0                	shl    %cl,%eax
  1029c5:	39 c6                	cmp    %eax,%esi
  1029c7:	76 95                	jbe    10295e <__udivdi3+0xae>
  1029c9:	8d 4f ff             	lea    0xffffffff(%edi),%ecx
  1029cc:	31 f6                	xor    %esi,%esi
  1029ce:	e9 0d ff ff ff       	jmp    1028e0 <__udivdi3+0x30>
  1029d3:	90                   	nop    
  1029d4:	90                   	nop    
  1029d5:	90                   	nop    
  1029d6:	90                   	nop    
  1029d7:	90                   	nop    
  1029d8:	90                   	nop    
  1029d9:	90                   	nop    
  1029da:	90                   	nop    
  1029db:	90                   	nop    
  1029dc:	90                   	nop    
  1029dd:	90                   	nop    
  1029de:	90                   	nop    
  1029df:	90                   	nop    

001029e0 <__umoddi3>:
  1029e0:	55                   	push   %ebp
  1029e1:	89 e5                	mov    %esp,%ebp
  1029e3:	57                   	push   %edi
  1029e4:	56                   	push   %esi
  1029e5:	83 ec 30             	sub    $0x30,%esp
  1029e8:	8b 55 14             	mov    0x14(%ebp),%edx
  1029eb:	8b 45 10             	mov    0x10(%ebp),%eax
  1029ee:	8b 75 08             	mov    0x8(%ebp),%esi
  1029f1:	8b 7d 0c             	mov    0xc(%ebp),%edi
  1029f4:	85 d2                	test   %edx,%edx
  1029f6:	c7 45 d0 00 00 00 00 	movl   $0x0,0xffffffd0(%ebp)
  1029fd:	89 c1                	mov    %eax,%ecx
  1029ff:	c7 45 d4 00 00 00 00 	movl   $0x0,0xffffffd4(%ebp)
  102a06:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
  102a09:	89 55 e8             	mov    %edx,0xffffffe8(%ebp)
  102a0c:	89 75 f0             	mov    %esi,0xfffffff0(%ebp)
  102a0f:	89 7d e0             	mov    %edi,0xffffffe0(%ebp)
  102a12:	75 1c                	jne    102a30 <__umoddi3+0x50>
  102a14:	39 f8                	cmp    %edi,%eax
  102a16:	89 fa                	mov    %edi,%edx
  102a18:	0f 86 d4 00 00 00    	jbe    102af2 <__umoddi3+0x112>
  102a1e:	89 f0                	mov    %esi,%eax
  102a20:	f7 f1                	div    %ecx
  102a22:	89 55 d0             	mov    %edx,0xffffffd0(%ebp)
  102a25:	c7 45 d4 00 00 00 00 	movl   $0x0,0xffffffd4(%ebp)
  102a2c:	eb 12                	jmp    102a40 <__umoddi3+0x60>
  102a2e:	66 90                	xchg   %ax,%ax
  102a30:	8b 4d e0             	mov    0xffffffe0(%ebp),%ecx
  102a33:	39 4d e8             	cmp    %ecx,0xffffffe8(%ebp)
  102a36:	76 18                	jbe    102a50 <__umoddi3+0x70>
  102a38:	89 75 d0             	mov    %esi,0xffffffd0(%ebp)
  102a3b:	89 7d d4             	mov    %edi,0xffffffd4(%ebp)
  102a3e:	66 90                	xchg   %ax,%ax
  102a40:	8b 45 d0             	mov    0xffffffd0(%ebp),%eax
  102a43:	8b 55 d4             	mov    0xffffffd4(%ebp),%edx
  102a46:	83 c4 30             	add    $0x30,%esp
  102a49:	5e                   	pop    %esi
  102a4a:	5f                   	pop    %edi
  102a4b:	5d                   	pop    %ebp
  102a4c:	c3                   	ret    
  102a4d:	8d 76 00             	lea    0x0(%esi),%esi
  102a50:	0f bd 45 e8          	bsr    0xffffffe8(%ebp),%eax
  102a54:	83 f0 1f             	xor    $0x1f,%eax
  102a57:	89 45 dc             	mov    %eax,0xffffffdc(%ebp)
  102a5a:	0f 84 c0 00 00 00    	je     102b20 <__umoddi3+0x140>
  102a60:	b8 20 00 00 00       	mov    $0x20,%eax
  102a65:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
  102a68:	2b 45 dc             	sub    0xffffffdc(%ebp),%eax
  102a6b:	8b 7d ec             	mov    0xffffffec(%ebp),%edi
  102a6e:	8b 75 f0             	mov    0xfffffff0(%ebp),%esi
  102a71:	89 c1                	mov    %eax,%ecx
  102a73:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
  102a76:	d3 ea                	shr    %cl,%edx
  102a78:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  102a7b:	0f b6 4d dc          	movzbl 0xffffffdc(%ebp),%ecx
  102a7f:	d3 e0                	shl    %cl,%eax
  102a81:	09 c2                	or     %eax,%edx
  102a83:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  102a86:	d3 e7                	shl    %cl,%edi
  102a88:	0f b6 4d e4          	movzbl 0xffffffe4(%ebp),%ecx
  102a8c:	89 55 f4             	mov    %edx,0xfffffff4(%ebp)
  102a8f:	8b 55 e0             	mov    0xffffffe0(%ebp),%edx
  102a92:	d3 e8                	shr    %cl,%eax
  102a94:	0f b6 4d dc          	movzbl 0xffffffdc(%ebp),%ecx
  102a98:	d3 e2                	shl    %cl,%edx
  102a9a:	09 d0                	or     %edx,%eax
  102a9c:	8b 55 e0             	mov    0xffffffe0(%ebp),%edx
  102a9f:	d3 e6                	shl    %cl,%esi
  102aa1:	0f b6 4d e4          	movzbl 0xffffffe4(%ebp),%ecx
  102aa5:	d3 ea                	shr    %cl,%edx
  102aa7:	f7 75 f4             	divl   0xfffffff4(%ebp)
  102aaa:	89 55 cc             	mov    %edx,0xffffffcc(%ebp)
  102aad:	f7 e7                	mul    %edi
  102aaf:	39 55 cc             	cmp    %edx,0xffffffcc(%ebp)
  102ab2:	0f 82 a5 00 00 00    	jb     102b5d <__umoddi3+0x17d>
  102ab8:	3b 55 cc             	cmp    0xffffffcc(%ebp),%edx
  102abb:	0f 84 94 00 00 00    	je     102b55 <__umoddi3+0x175>
  102ac1:	8b 4d cc             	mov    0xffffffcc(%ebp),%ecx
  102ac4:	29 c6                	sub    %eax,%esi
  102ac6:	19 d1                	sbb    %edx,%ecx
  102ac8:	89 4d cc             	mov    %ecx,0xffffffcc(%ebp)
  102acb:	0f b6 4d dc          	movzbl 0xffffffdc(%ebp),%ecx
  102acf:	89 f2                	mov    %esi,%edx
  102ad1:	8b 45 cc             	mov    0xffffffcc(%ebp),%eax
  102ad4:	d3 ea                	shr    %cl,%edx
  102ad6:	0f b6 4d e4          	movzbl 0xffffffe4(%ebp),%ecx
  102ada:	d3 e0                	shl    %cl,%eax
  102adc:	0f b6 4d dc          	movzbl 0xffffffdc(%ebp),%ecx
  102ae0:	09 c2                	or     %eax,%edx
  102ae2:	8b 45 cc             	mov    0xffffffcc(%ebp),%eax
  102ae5:	89 55 d0             	mov    %edx,0xffffffd0(%ebp)
  102ae8:	d3 e8                	shr    %cl,%eax
  102aea:	89 45 d4             	mov    %eax,0xffffffd4(%ebp)
  102aed:	e9 4e ff ff ff       	jmp    102a40 <__umoddi3+0x60>
  102af2:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
  102af5:	85 c0                	test   %eax,%eax
  102af7:	74 17                	je     102b10 <__umoddi3+0x130>
  102af9:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
  102afc:	8b 55 e8             	mov    0xffffffe8(%ebp),%edx
  102aff:	f7 f1                	div    %ecx
  102b01:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  102b04:	f7 f1                	div    %ecx
  102b06:	e9 17 ff ff ff       	jmp    102a22 <__umoddi3+0x42>
  102b0b:	90                   	nop    
  102b0c:	8d 74 26 00          	lea    0x0(%esi),%esi
  102b10:	b8 01 00 00 00       	mov    $0x1,%eax
  102b15:	31 d2                	xor    %edx,%edx
  102b17:	f7 75 ec             	divl   0xffffffec(%ebp)
  102b1a:	89 c1                	mov    %eax,%ecx
  102b1c:	eb db                	jmp    102af9 <__umoddi3+0x119>
  102b1e:	66 90                	xchg   %ax,%ax
  102b20:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
  102b23:	39 45 e0             	cmp    %eax,0xffffffe0(%ebp)
  102b26:	77 19                	ja     102b41 <__umoddi3+0x161>
  102b28:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
  102b2b:	39 55 f0             	cmp    %edx,0xfffffff0(%ebp)
  102b2e:	73 11                	jae    102b41 <__umoddi3+0x161>
  102b30:	8b 55 f0             	mov    0xfffffff0(%ebp),%edx
  102b33:	8b 4d e0             	mov    0xffffffe0(%ebp),%ecx
  102b36:	89 55 d0             	mov    %edx,0xffffffd0(%ebp)
  102b39:	89 4d d4             	mov    %ecx,0xffffffd4(%ebp)
  102b3c:	e9 ff fe ff ff       	jmp    102a40 <__umoddi3+0x60>
  102b41:	8b 4d e0             	mov    0xffffffe0(%ebp),%ecx
  102b44:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
  102b47:	2b 45 ec             	sub    0xffffffec(%ebp),%eax
  102b4a:	1b 4d e8             	sbb    0xffffffe8(%ebp),%ecx
  102b4d:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
  102b50:	89 4d e0             	mov    %ecx,0xffffffe0(%ebp)
  102b53:	eb db                	jmp    102b30 <__umoddi3+0x150>
  102b55:	39 f0                	cmp    %esi,%eax
  102b57:	0f 86 64 ff ff ff    	jbe    102ac1 <__umoddi3+0xe1>
  102b5d:	29 f8                	sub    %edi,%eax
  102b5f:	1b 55 f4             	sbb    0xfffffff4(%ebp),%edx
  102b62:	e9 5a ff ff ff       	jmp    102ac1 <__umoddi3+0xe1>
