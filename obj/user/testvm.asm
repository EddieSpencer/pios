
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
4000010c:	e8 75 2a 00 00       	call   40002b86 <main>
	pushl	%eax	// use with main's return value as exit status
40000111:	50                   	push   %eax
	call	exit
40000112:	e8 81 38 00 00       	call   40003998 <exit>
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
40000143:	90                   	nop    

40000144 <fork>:
40000144:	55                   	push   %ebp
40000145:	89 e5                	mov    %esp,%ebp
40000147:	57                   	push   %edi
40000148:	56                   	push   %esi
40000149:	53                   	push   %ebx
4000014a:	81 ec 9c 02 00 00    	sub    $0x29c,%esp
40000150:	8b 45 0c             	mov    0xc(%ebp),%eax
40000153:	88 85 74 fd ff ff    	mov    %al,0xfffffd74(%ebp)
40000159:	c7 44 24 08 50 02 00 	movl   $0x250,0x8(%esp)
40000160:	00 
40000161:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000168:	00 
40000169:	8d 85 78 fd ff ff    	lea    0xfffffd78(%ebp),%eax
4000016f:	89 04 24             	mov    %eax,(%esp)
40000172:	e8 22 36 00 00       	call   40003799 <memset>
40000177:	89 b5 7c fd ff ff    	mov    %esi,0xfffffd7c(%ebp)
4000017d:	89 bd 78 fd ff ff    	mov    %edi,0xfffffd78(%ebp)
40000183:	89 ad 80 fd ff ff    	mov    %ebp,0xfffffd80(%ebp)
40000189:	89 a5 bc fd ff ff    	mov    %esp,0xfffffdbc(%ebp)
4000018f:	c7 85 b0 fd ff ff 9e 	movl   $0x4000019e,0xfffffdb0(%ebp)
40000196:	01 00 40 
40000199:	b8 01 00 00 00       	mov    $0x1,%eax
4000019e:	89 45 cc             	mov    %eax,0xffffffcc(%ebp)
400001a1:	83 7d cc 00          	cmpl   $0x0,0xffffffcc(%ebp)
400001a5:	75 0c                	jne    400001b3 <fork+0x6f>
400001a7:	c7 85 70 fd ff ff 00 	movl   $0x0,0xfffffd70(%ebp)
400001ae:	00 00 00 
400001b1:	eb 60                	jmp    40000213 <fork+0xcf>
400001b3:	c7 85 94 fd ff ff 00 	movl   $0x0,0xfffffd94(%ebp)
400001ba:	00 00 00 
400001bd:	0f b6 95 74 fd ff ff 	movzbl 0xfffffd74(%ebp),%edx
400001c4:	8b 45 08             	mov    0x8(%ebp),%eax
400001c7:	0d 00 10 02 00       	or     $0x21000,%eax
400001cc:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
400001cf:	66 89 55 e2          	mov    %dx,0xffffffe2(%ebp)
400001d3:	8d 85 78 fd ff ff    	lea    0xfffffd78(%ebp),%eax
400001d9:	89 45 dc             	mov    %eax,0xffffffdc(%ebp)
400001dc:	c7 45 d8 00 00 00 40 	movl   $0x40000000,0xffffffd8(%ebp)
400001e3:	c7 45 d4 00 00 00 40 	movl   $0x40000000,0xffffffd4(%ebp)
400001ea:	c7 45 d0 00 00 00 b0 	movl   $0xb0000000,0xffffffd0(%ebp)
400001f1:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
400001f4:	83 c8 01             	or     $0x1,%eax
400001f7:	8b 5d dc             	mov    0xffffffdc(%ebp),%ebx
400001fa:	0f b7 55 e2          	movzwl 0xffffffe2(%ebp),%edx
400001fe:	8b 75 d8             	mov    0xffffffd8(%ebp),%esi
40000201:	8b 7d d4             	mov    0xffffffd4(%ebp),%edi
40000204:	8b 4d d0             	mov    0xffffffd0(%ebp),%ecx
40000207:	cd 30                	int    $0x30
40000209:	c7 85 70 fd ff ff 01 	movl   $0x1,0xfffffd70(%ebp)
40000210:	00 00 00 
40000213:	8b 85 70 fd ff ff    	mov    0xfffffd70(%ebp),%eax
40000219:	81 c4 9c 02 00 00    	add    $0x29c,%esp
4000021f:	5b                   	pop    %ebx
40000220:	5e                   	pop    %esi
40000221:	5f                   	pop    %edi
40000222:	5d                   	pop    %ebp
40000223:	c3                   	ret    

40000224 <join>:
40000224:	55                   	push   %ebp
40000225:	89 e5                	mov    %esp,%ebp
40000227:	57                   	push   %edi
40000228:	56                   	push   %esi
40000229:	53                   	push   %ebx
4000022a:	81 ec ac 02 00 00    	sub    $0x2ac,%esp
40000230:	8b 45 0c             	mov    0xc(%ebp),%eax
40000233:	88 85 74 fd ff ff    	mov    %al,0xfffffd74(%ebp)
40000239:	0f b6 95 74 fd ff ff 	movzbl 0xfffffd74(%ebp),%edx
40000240:	8b 45 08             	mov    0x8(%ebp),%eax
40000243:	80 cc 10             	or     $0x10,%ah
40000246:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
40000249:	66 89 55 e2          	mov    %dx,0xffffffe2(%ebp)
4000024d:	8d 85 78 fd ff ff    	lea    0xfffffd78(%ebp),%eax
40000253:	89 45 dc             	mov    %eax,0xffffffdc(%ebp)
40000256:	c7 45 d8 00 00 00 40 	movl   $0x40000000,0xffffffd8(%ebp)
4000025d:	c7 45 d4 00 00 00 40 	movl   $0x40000000,0xffffffd4(%ebp)
40000264:	c7 45 d0 00 00 c0 af 	movl   $0xafc00000,0xffffffd0(%ebp)
4000026b:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
4000026e:	83 c8 02             	or     $0x2,%eax
40000271:	8b 5d dc             	mov    0xffffffdc(%ebp),%ebx
40000274:	0f b7 55 e2          	movzwl 0xffffffe2(%ebp),%edx
40000278:	8b 75 d8             	mov    0xffffffd8(%ebp),%esi
4000027b:	8b 7d d4             	mov    0xffffffd4(%ebp),%edi
4000027e:	8b 4d d0             	mov    0xffffffd0(%ebp),%ecx
40000281:	cd 30                	int    $0x30
40000283:	8b 95 a8 fd ff ff    	mov    0xfffffda8(%ebp),%edx
40000289:	8b 45 10             	mov    0x10(%ebp),%eax
4000028c:	39 c2                	cmp    %eax,%edx
4000028e:	74 59                	je     400002e9 <join+0xc5>
40000290:	8b 85 b0 fd ff ff    	mov    0xfffffdb0(%ebp),%eax
40000296:	89 44 24 04          	mov    %eax,0x4(%esp)
4000029a:	c7 04 24 40 56 00 40 	movl   $0x40005640,(%esp)
400002a1:	e8 eb 2b 00 00       	call   40002e91 <cprintf>
400002a6:	8b 85 bc fd ff ff    	mov    0xfffffdbc(%ebp),%eax
400002ac:	89 44 24 04          	mov    %eax,0x4(%esp)
400002b0:	c7 04 24 4f 56 00 40 	movl   $0x4000564f,(%esp)
400002b7:	e8 d5 2b 00 00       	call   40002e91 <cprintf>
400002bc:	8b 95 a8 fd ff ff    	mov    0xfffffda8(%ebp),%edx
400002c2:	8b 45 10             	mov    0x10(%ebp),%eax
400002c5:	89 44 24 10          	mov    %eax,0x10(%esp)
400002c9:	89 54 24 0c          	mov    %edx,0xc(%esp)
400002cd:	c7 44 24 08 60 56 00 	movl   $0x40005660,0x8(%esp)
400002d4:	40 
400002d5:	c7 44 24 04 51 00 00 	movl   $0x51,0x4(%esp)
400002dc:	00 
400002dd:	c7 04 24 88 56 00 40 	movl   $0x40005688,(%esp)
400002e4:	e8 ef 28 00 00       	call   40002bd8 <debug_panic>
400002e9:	81 c4 ac 02 00 00    	add    $0x2ac,%esp
400002ef:	5b                   	pop    %ebx
400002f0:	5e                   	pop    %esi
400002f1:	5f                   	pop    %edi
400002f2:	5d                   	pop    %ebp
400002f3:	c3                   	ret    

400002f4 <gentrap>:
400002f4:	55                   	push   %ebp
400002f5:	89 e5                	mov    %esp,%ebp
400002f7:	83 ec 28             	sub    $0x28,%esp
400002fa:	c7 45 f8 01 00 00 00 	movl   $0x1,0xfffffff8(%ebp)
40000301:	c7 45 fc 03 00 00 00 	movl   $0x3,0xfffffffc(%ebp)
40000308:	8b 45 08             	mov    0x8(%ebp),%eax
4000030b:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
4000030e:	83 7d ec 30          	cmpl   $0x30,0xffffffec(%ebp)
40000312:	77 31                	ja     40000345 <gentrap+0x51>
40000314:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
40000317:	8b 04 95 ac 56 00 40 	mov    0x400056ac(,%edx,4),%eax
4000031e:	ff e0                	jmp    *%eax
40000320:	b8 00 00 00 00       	mov    $0x0,%eax
40000325:	f7 f0                	div    %eax
40000327:	cc                   	int3   
40000328:	b8 00 00 00 70       	mov    $0x70000000,%eax
4000032d:	01 c0                	add    %eax,%eax
4000032f:	ce                   	into   
40000330:	b8 00 00 00 00       	mov    $0x0,%eax
40000335:	62 45 f8             	bound  %eax,0xfffffff8(%ebp)
40000338:	0f 0b                	ud2a   
4000033a:	0f 01 5d 08          	lidtl  0x8(%ebp)
4000033e:	b8 03 00 00 00       	mov    $0x3,%eax
40000343:	cd 30                	int    $0x30
40000345:	8b 45 08             	mov    0x8(%ebp),%eax
40000348:	89 44 24 0c          	mov    %eax,0xc(%esp)
4000034c:	c7 44 24 08 99 56 00 	movl   $0x40005699,0x8(%esp)
40000353:	40 
40000354:	c7 44 24 04 69 00 00 	movl   $0x69,0x4(%esp)
4000035b:	00 
4000035c:	c7 04 24 88 56 00 40 	movl   $0x40005688,(%esp)
40000363:	e8 70 28 00 00       	call   40002bd8 <debug_panic>

40000368 <trapcheck>:
40000368:	55                   	push   %ebp
40000369:	89 e5                	mov    %esp,%ebp
4000036b:	83 ec 18             	sub    $0x18,%esp
4000036e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000375:	00 
40000376:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
4000037d:	e8 c2 fd ff ff       	call   40000144 <fork>
40000382:	85 c0                	test   %eax,%eax
40000384:	75 0b                	jne    40000391 <trapcheck+0x29>
40000386:	8b 45 08             	mov    0x8(%ebp),%eax
40000389:	89 04 24             	mov    %eax,(%esp)
4000038c:	e8 63 ff ff ff       	call   400002f4 <gentrap>
40000391:	8b 45 08             	mov    0x8(%ebp),%eax
40000394:	89 44 24 08          	mov    %eax,0x8(%esp)
40000398:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000039f:	00 
400003a0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
400003a7:	e8 78 fe ff ff       	call   40000224 <join>
400003ac:	c9                   	leave  
400003ad:	c3                   	ret    

400003ae <cputsfaultchild>:
400003ae:	55                   	push   %ebp
400003af:	89 e5                	mov    %esp,%ebp
400003b1:	53                   	push   %ebx
400003b2:	83 ec 10             	sub    $0x10,%esp
400003b5:	8b 45 08             	mov    0x8(%ebp),%eax
400003b8:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
400003bb:	b8 00 00 00 00       	mov    $0x0,%eax
400003c0:	8b 5d f8             	mov    0xfffffff8(%ebp),%ebx
400003c3:	cd 30                	int    $0x30
400003c5:	83 c4 10             	add    $0x10,%esp
400003c8:	5b                   	pop    %ebx
400003c9:	5d                   	pop    %ebp
400003ca:	c3                   	ret    

400003cb <loadcheck>:
400003cb:	55                   	push   %ebp
400003cc:	89 e5                	mov    %esp,%ebp
400003ce:	83 ec 28             	sub    $0x28,%esp
400003d1:	c7 45 fc 00 7b 00 40 	movl   $0x40007b00,0xfffffffc(%ebp)
400003d8:	eb 5c                	jmp    40000436 <loadcheck+0x6b>
400003da:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
400003dd:	0f b6 00             	movzbl (%eax),%eax
400003e0:	84 c0                	test   %al,%al
400003e2:	74 20                	je     40000404 <loadcheck+0x39>
400003e4:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
400003e7:	0f b6 00             	movzbl (%eax),%eax
400003ea:	0f b6 c0             	movzbl %al,%eax
400003ed:	89 44 24 08          	mov    %eax,0x8(%esp)
400003f1:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
400003f4:	89 44 24 04          	mov    %eax,0x4(%esp)
400003f8:	c7 04 24 70 57 00 40 	movl   $0x40005770,(%esp)
400003ff:	e8 8d 2a 00 00       	call   40002e91 <cprintf>
40000404:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
40000407:	0f b6 00             	movzbl (%eax),%eax
4000040a:	84 c0                	test   %al,%al
4000040c:	74 24                	je     40000432 <loadcheck+0x67>
4000040e:	c7 44 24 0c 77 57 00 	movl   $0x40005777,0xc(%esp)
40000415:	40 
40000416:	c7 44 24 08 7f 57 00 	movl   $0x4000577f,0x8(%esp)
4000041d:	40 
4000041e:	c7 44 24 04 9b 00 00 	movl   $0x9b,0x4(%esp)
40000425:	00 
40000426:	c7 04 24 88 56 00 40 	movl   $0x40005688,(%esp)
4000042d:	e8 a6 27 00 00       	call   40002bd8 <debug_panic>
40000432:	83 45 fc 01          	addl   $0x1,0xfffffffc(%ebp)
40000436:	81 7d fc 28 9c 00 40 	cmpl   $0x40009c28,0xfffffffc(%ebp)
4000043d:	72 9b                	jb     400003da <loadcheck+0xf>
4000043f:	c7 04 24 94 57 00 40 	movl   $0x40005794,(%esp)
40000446:	e8 46 2a 00 00       	call   40002e91 <cprintf>
4000044b:	c9                   	leave  
4000044c:	c3                   	ret    

4000044d <forkcheck>:
4000044d:	55                   	push   %ebp
4000044e:	89 e5                	mov    %esp,%ebp
40000450:	83 ec 18             	sub    $0x18,%esp
40000453:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000045a:	00 
4000045b:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000462:	e8 dd fc ff ff       	call   40000144 <fork>
40000467:	85 c0                	test   %eax,%eax
40000469:	75 0c                	jne    40000477 <forkcheck+0x2a>
4000046b:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
40000472:	e8 7d fe ff ff       	call   400002f4 <gentrap>
40000477:	c7 44 24 08 30 00 00 	movl   $0x30,0x8(%esp)
4000047e:	00 
4000047f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000486:	00 
40000487:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
4000048e:	e8 91 fd ff ff       	call   40000224 <join>
40000493:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
4000049a:	e8 c9 fe ff ff       	call   40000368 <trapcheck>
4000049f:	c7 04 24 03 00 00 00 	movl   $0x3,(%esp)
400004a6:	e8 bd fe ff ff       	call   40000368 <trapcheck>
400004ab:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
400004b2:	e8 b1 fe ff ff       	call   40000368 <trapcheck>
400004b7:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
400004be:	e8 a5 fe ff ff       	call   40000368 <trapcheck>
400004c3:	c7 04 24 06 00 00 00 	movl   $0x6,(%esp)
400004ca:	e8 99 fe ff ff       	call   40000368 <trapcheck>
400004cf:	c7 04 24 0d 00 00 00 	movl   $0xd,(%esp)
400004d6:	e8 8d fe ff ff       	call   40000368 <trapcheck>
400004db:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400004e2:	00 
400004e3:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
400004ea:	e8 55 fc ff ff       	call   40000144 <fork>
400004ef:	85 c0                	test   %eax,%eax
400004f1:	75 0c                	jne    400004ff <forkcheck+0xb2>
400004f3:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
400004fa:	e8 f5 fd ff ff       	call   400002f4 <gentrap>
400004ff:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
40000506:	00 
40000507:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
4000050e:	e8 31 fc ff ff       	call   40000144 <fork>
40000513:	85 c0                	test   %eax,%eax
40000515:	75 0c                	jne    40000523 <forkcheck+0xd6>
40000517:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
4000051e:	e8 d1 fd ff ff       	call   400002f4 <gentrap>
40000523:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
4000052a:	00 
4000052b:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000532:	e8 0d fc ff ff       	call   40000144 <fork>
40000537:	85 c0                	test   %eax,%eax
40000539:	75 0c                	jne    40000547 <forkcheck+0xfa>
4000053b:	c7 04 24 03 00 00 00 	movl   $0x3,(%esp)
40000542:	e8 ad fd ff ff       	call   400002f4 <gentrap>
40000547:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
4000054e:	00 
4000054f:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000556:	e8 e9 fb ff ff       	call   40000144 <fork>
4000055b:	85 c0                	test   %eax,%eax
4000055d:	75 0c                	jne    4000056b <forkcheck+0x11e>
4000055f:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
40000566:	e8 89 fd ff ff       	call   400002f4 <gentrap>
4000056b:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
40000572:	00 
40000573:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
4000057a:	e8 c5 fb ff ff       	call   40000144 <fork>
4000057f:	85 c0                	test   %eax,%eax
40000581:	75 0c                	jne    4000058f <forkcheck+0x142>
40000583:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
4000058a:	e8 65 fd ff ff       	call   400002f4 <gentrap>
4000058f:	c7 44 24 04 05 00 00 	movl   $0x5,0x4(%esp)
40000596:	00 
40000597:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
4000059e:	e8 a1 fb ff ff       	call   40000144 <fork>
400005a3:	85 c0                	test   %eax,%eax
400005a5:	75 0c                	jne    400005b3 <forkcheck+0x166>
400005a7:	c7 04 24 06 00 00 00 	movl   $0x6,(%esp)
400005ae:	e8 41 fd ff ff       	call   400002f4 <gentrap>
400005b3:	c7 44 24 04 06 00 00 	movl   $0x6,0x4(%esp)
400005ba:	00 
400005bb:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
400005c2:	e8 7d fb ff ff       	call   40000144 <fork>
400005c7:	85 c0                	test   %eax,%eax
400005c9:	75 0c                	jne    400005d7 <forkcheck+0x18a>
400005cb:	c7 04 24 0d 00 00 00 	movl   $0xd,(%esp)
400005d2:	e8 1d fd ff ff       	call   400002f4 <gentrap>
400005d7:	c7 44 24 08 30 00 00 	movl   $0x30,0x8(%esp)
400005de:	00 
400005df:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400005e6:	00 
400005e7:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
400005ee:	e8 31 fc ff ff       	call   40000224 <join>
400005f3:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
400005fa:	00 
400005fb:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
40000602:	00 
40000603:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
4000060a:	e8 15 fc ff ff       	call   40000224 <join>
4000060f:	c7 44 24 08 03 00 00 	movl   $0x3,0x8(%esp)
40000616:	00 
40000617:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
4000061e:	00 
4000061f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000626:	e8 f9 fb ff ff       	call   40000224 <join>
4000062b:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
40000632:	00 
40000633:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
4000063a:	00 
4000063b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000642:	e8 dd fb ff ff       	call   40000224 <join>
40000647:	c7 44 24 08 05 00 00 	movl   $0x5,0x8(%esp)
4000064e:	00 
4000064f:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
40000656:	00 
40000657:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
4000065e:	e8 c1 fb ff ff       	call   40000224 <join>
40000663:	c7 44 24 08 06 00 00 	movl   $0x6,0x8(%esp)
4000066a:	00 
4000066b:	c7 44 24 04 05 00 00 	movl   $0x5,0x4(%esp)
40000672:	00 
40000673:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
4000067a:	e8 a5 fb ff ff       	call   40000224 <join>
4000067f:	c7 44 24 08 0d 00 00 	movl   $0xd,0x8(%esp)
40000686:	00 
40000687:	c7 44 24 04 06 00 00 	movl   $0x6,0x4(%esp)
4000068e:	00 
4000068f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000696:	e8 89 fb ff ff       	call   40000224 <join>
4000069b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400006a2:	00 
400006a3:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
400006aa:	e8 95 fa ff ff       	call   40000144 <fork>
400006af:	85 c0                	test   %eax,%eax
400006b1:	75 0e                	jne    400006c1 <forkcheck+0x274>
400006b3:	b8 00 00 00 00       	mov    $0x0,%eax
400006b8:	8b 00                	mov    (%eax),%eax
400006ba:	b8 03 00 00 00       	mov    $0x3,%eax
400006bf:	cd 30                	int    $0x30
400006c1:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
400006c8:	00 
400006c9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400006d0:	00 
400006d1:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
400006d8:	e8 47 fb ff ff       	call   40000224 <join>
400006dd:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400006e4:	00 
400006e5:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
400006ec:	e8 53 fa ff ff       	call   40000144 <fork>
400006f1:	85 c0                	test   %eax,%eax
400006f3:	75 0e                	jne    40000703 <forkcheck+0x2b6>
400006f5:	b8 fc ff ff 3f       	mov    $0x3ffffffc,%eax
400006fa:	8b 00                	mov    (%eax),%eax
400006fc:	b8 03 00 00 00       	mov    $0x3,%eax
40000701:	cd 30                	int    $0x30
40000703:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
4000070a:	00 
4000070b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000712:	00 
40000713:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
4000071a:	e8 05 fb ff ff       	call   40000224 <join>
4000071f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000726:	00 
40000727:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
4000072e:	e8 11 fa ff ff       	call   40000144 <fork>
40000733:	85 c0                	test   %eax,%eax
40000735:	75 0e                	jne    40000745 <forkcheck+0x2f8>
40000737:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
4000073c:	8b 00                	mov    (%eax),%eax
4000073e:	b8 03 00 00 00       	mov    $0x3,%eax
40000743:	cd 30                	int    $0x30
40000745:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
4000074c:	00 
4000074d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000754:	00 
40000755:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
4000075c:	e8 c3 fa ff ff       	call   40000224 <join>
40000761:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000768:	00 
40000769:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000770:	e8 cf f9 ff ff       	call   40000144 <fork>
40000775:	85 c0                	test   %eax,%eax
40000777:	75 0e                	jne    40000787 <forkcheck+0x33a>
40000779:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
4000077e:	8b 00                	mov    (%eax),%eax
40000780:	b8 03 00 00 00       	mov    $0x3,%eax
40000785:	cd 30                	int    $0x30
40000787:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
4000078e:	00 
4000078f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000796:	00 
40000797:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
4000079e:	e8 81 fa ff ff       	call   40000224 <join>
400007a3:	c7 04 24 ae 57 00 40 	movl   $0x400057ae,(%esp)
400007aa:	e8 e2 26 00 00       	call   40002e91 <cprintf>
400007af:	c9                   	leave  
400007b0:	c3                   	ret    

400007b1 <protcheck>:
400007b1:	55                   	push   %ebp
400007b2:	89 e5                	mov    %esp,%ebp
400007b4:	57                   	push   %edi
400007b5:	56                   	push   %esi
400007b6:	53                   	push   %ebx
400007b7:	81 ec bc 01 00 00    	sub    $0x1bc,%esp
400007bd:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400007c4:	00 
400007c5:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
400007cc:	e8 73 f9 ff ff       	call   40000144 <fork>
400007d1:	85 c0                	test   %eax,%eax
400007d3:	75 1e                	jne    400007f3 <protcheck+0x42>
400007d5:	c7 85 58 fe ff ff 00 	movl   $0x0,0xfffffe58(%ebp)
400007dc:	00 00 00 
400007df:	b8 00 00 00 00       	mov    $0x0,%eax
400007e4:	8b 9d 58 fe ff ff    	mov    0xfffffe58(%ebp),%ebx
400007ea:	cd 30                	int    $0x30
400007ec:	b8 03 00 00 00       	mov    $0x3,%eax
400007f1:	cd 30                	int    $0x30
400007f3:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
400007fa:	00 
400007fb:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000802:	00 
40000803:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
4000080a:	e8 15 fa ff ff       	call   40000224 <join>
4000080f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000816:	00 
40000817:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
4000081e:	e8 21 f9 ff ff       	call   40000144 <fork>
40000823:	85 c0                	test   %eax,%eax
40000825:	75 1e                	jne    40000845 <protcheck+0x94>
40000827:	c7 85 5c fe ff ff ff 	movl   $0x3fffffff,0xfffffe5c(%ebp)
4000082e:	ff ff 3f 
40000831:	b8 00 00 00 00       	mov    $0x0,%eax
40000836:	8b 9d 5c fe ff ff    	mov    0xfffffe5c(%ebp),%ebx
4000083c:	cd 30                	int    $0x30
4000083e:	b8 03 00 00 00       	mov    $0x3,%eax
40000843:	cd 30                	int    $0x30
40000845:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
4000084c:	00 
4000084d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000854:	00 
40000855:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
4000085c:	e8 c3 f9 ff ff       	call   40000224 <join>
40000861:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000868:	00 
40000869:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000870:	e8 cf f8 ff ff       	call   40000144 <fork>
40000875:	85 c0                	test   %eax,%eax
40000877:	75 1e                	jne    40000897 <protcheck+0xe6>
40000879:	c7 85 60 fe ff ff 00 	movl   $0xf0000000,0xfffffe60(%ebp)
40000880:	00 00 f0 
40000883:	b8 00 00 00 00       	mov    $0x0,%eax
40000888:	8b 9d 60 fe ff ff    	mov    0xfffffe60(%ebp),%ebx
4000088e:	cd 30                	int    $0x30
40000890:	b8 03 00 00 00       	mov    $0x3,%eax
40000895:	cd 30                	int    $0x30
40000897:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
4000089e:	00 
4000089f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400008a6:	00 
400008a7:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
400008ae:	e8 71 f9 ff ff       	call   40000224 <join>
400008b3:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400008ba:	00 
400008bb:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
400008c2:	e8 7d f8 ff ff       	call   40000144 <fork>
400008c7:	85 c0                	test   %eax,%eax
400008c9:	75 1e                	jne    400008e9 <protcheck+0x138>
400008cb:	c7 85 64 fe ff ff ff 	movl   $0xffffffff,0xfffffe64(%ebp)
400008d2:	ff ff ff 
400008d5:	b8 00 00 00 00       	mov    $0x0,%eax
400008da:	8b 9d 64 fe ff ff    	mov    0xfffffe64(%ebp),%ebx
400008e0:	cd 30                	int    $0x30
400008e2:	b8 03 00 00 00       	mov    $0x3,%eax
400008e7:	cd 30                	int    $0x30
400008e9:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
400008f0:	00 
400008f1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400008f8:	00 
400008f9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000900:	e8 1f f9 ff ff       	call   40000224 <join>
40000905:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000090c:	00 
4000090d:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000914:	e8 2b f8 ff ff       	call   40000144 <fork>
40000919:	85 c0                	test   %eax,%eax
4000091b:	75 6c                	jne    40000989 <protcheck+0x1d8>
4000091d:	c7 85 7c fe ff ff 00 	movl   $0x1000,0xfffffe7c(%ebp)
40000924:	10 00 00 
40000927:	66 c7 85 7a fe ff ff 	movw   $0x0,0xfffffe7a(%ebp)
4000092e:	00 00 
40000930:	c7 85 74 fe ff ff 00 	movl   $0x0,0xfffffe74(%ebp)
40000937:	00 00 00 
4000093a:	c7 85 70 fe ff ff 00 	movl   $0x0,0xfffffe70(%ebp)
40000941:	00 00 00 
40000944:	c7 85 6c fe ff ff 00 	movl   $0x0,0xfffffe6c(%ebp)
4000094b:	00 00 00 
4000094e:	c7 85 68 fe ff ff 00 	movl   $0x0,0xfffffe68(%ebp)
40000955:	00 00 00 
40000958:	8b 85 7c fe ff ff    	mov    0xfffffe7c(%ebp),%eax
4000095e:	83 c8 01             	or     $0x1,%eax
40000961:	8b 9d 74 fe ff ff    	mov    0xfffffe74(%ebp),%ebx
40000967:	0f b7 95 7a fe ff ff 	movzwl 0xfffffe7a(%ebp),%edx
4000096e:	8b b5 70 fe ff ff    	mov    0xfffffe70(%ebp),%esi
40000974:	8b bd 6c fe ff ff    	mov    0xfffffe6c(%ebp),%edi
4000097a:	8b 8d 68 fe ff ff    	mov    0xfffffe68(%ebp),%ecx
40000980:	cd 30                	int    $0x30
40000982:	b8 03 00 00 00       	mov    $0x3,%eax
40000987:	cd 30                	int    $0x30
40000989:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40000990:	00 
40000991:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000998:	00 
40000999:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
400009a0:	e8 7f f8 ff ff       	call   40000224 <join>
400009a5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400009ac:	00 
400009ad:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
400009b4:	e8 8b f7 ff ff       	call   40000144 <fork>
400009b9:	85 c0                	test   %eax,%eax
400009bb:	75 6c                	jne    40000a29 <protcheck+0x278>
400009bd:	c7 85 94 fe ff ff 00 	movl   $0x1000,0xfffffe94(%ebp)
400009c4:	10 00 00 
400009c7:	66 c7 85 92 fe ff ff 	movw   $0x0,0xfffffe92(%ebp)
400009ce:	00 00 
400009d0:	c7 85 8c fe ff ff ff 	movl   $0x3fffffff,0xfffffe8c(%ebp)
400009d7:	ff ff 3f 
400009da:	c7 85 88 fe ff ff 00 	movl   $0x0,0xfffffe88(%ebp)
400009e1:	00 00 00 
400009e4:	c7 85 84 fe ff ff 00 	movl   $0x0,0xfffffe84(%ebp)
400009eb:	00 00 00 
400009ee:	c7 85 80 fe ff ff 00 	movl   $0x0,0xfffffe80(%ebp)
400009f5:	00 00 00 
400009f8:	8b 85 94 fe ff ff    	mov    0xfffffe94(%ebp),%eax
400009fe:	83 c8 01             	or     $0x1,%eax
40000a01:	8b 9d 8c fe ff ff    	mov    0xfffffe8c(%ebp),%ebx
40000a07:	0f b7 95 92 fe ff ff 	movzwl 0xfffffe92(%ebp),%edx
40000a0e:	8b b5 88 fe ff ff    	mov    0xfffffe88(%ebp),%esi
40000a14:	8b bd 84 fe ff ff    	mov    0xfffffe84(%ebp),%edi
40000a1a:	8b 8d 80 fe ff ff    	mov    0xfffffe80(%ebp),%ecx
40000a20:	cd 30                	int    $0x30
40000a22:	b8 03 00 00 00       	mov    $0x3,%eax
40000a27:	cd 30                	int    $0x30
40000a29:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40000a30:	00 
40000a31:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000a38:	00 
40000a39:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000a40:	e8 df f7 ff ff       	call   40000224 <join>
40000a45:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000a4c:	00 
40000a4d:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000a54:	e8 eb f6 ff ff       	call   40000144 <fork>
40000a59:	85 c0                	test   %eax,%eax
40000a5b:	75 6c                	jne    40000ac9 <protcheck+0x318>
40000a5d:	c7 85 ac fe ff ff 00 	movl   $0x1000,0xfffffeac(%ebp)
40000a64:	10 00 00 
40000a67:	66 c7 85 aa fe ff ff 	movw   $0x0,0xfffffeaa(%ebp)
40000a6e:	00 00 
40000a70:	c7 85 a4 fe ff ff 00 	movl   $0xf0000000,0xfffffea4(%ebp)
40000a77:	00 00 f0 
40000a7a:	c7 85 a0 fe ff ff 00 	movl   $0x0,0xfffffea0(%ebp)
40000a81:	00 00 00 
40000a84:	c7 85 9c fe ff ff 00 	movl   $0x0,0xfffffe9c(%ebp)
40000a8b:	00 00 00 
40000a8e:	c7 85 98 fe ff ff 00 	movl   $0x0,0xfffffe98(%ebp)
40000a95:	00 00 00 
40000a98:	8b 85 ac fe ff ff    	mov    0xfffffeac(%ebp),%eax
40000a9e:	83 c8 01             	or     $0x1,%eax
40000aa1:	8b 9d a4 fe ff ff    	mov    0xfffffea4(%ebp),%ebx
40000aa7:	0f b7 95 aa fe ff ff 	movzwl 0xfffffeaa(%ebp),%edx
40000aae:	8b b5 a0 fe ff ff    	mov    0xfffffea0(%ebp),%esi
40000ab4:	8b bd 9c fe ff ff    	mov    0xfffffe9c(%ebp),%edi
40000aba:	8b 8d 98 fe ff ff    	mov    0xfffffe98(%ebp),%ecx
40000ac0:	cd 30                	int    $0x30
40000ac2:	b8 03 00 00 00       	mov    $0x3,%eax
40000ac7:	cd 30                	int    $0x30
40000ac9:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40000ad0:	00 
40000ad1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000ad8:	00 
40000ad9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000ae0:	e8 3f f7 ff ff       	call   40000224 <join>
40000ae5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000aec:	00 
40000aed:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000af4:	e8 4b f6 ff ff       	call   40000144 <fork>
40000af9:	85 c0                	test   %eax,%eax
40000afb:	75 6c                	jne    40000b69 <protcheck+0x3b8>
40000afd:	c7 85 c4 fe ff ff 00 	movl   $0x1000,0xfffffec4(%ebp)
40000b04:	10 00 00 
40000b07:	66 c7 85 c2 fe ff ff 	movw   $0x0,0xfffffec2(%ebp)
40000b0e:	00 00 
40000b10:	c7 85 bc fe ff ff ff 	movl   $0xffffffff,0xfffffebc(%ebp)
40000b17:	ff ff ff 
40000b1a:	c7 85 b8 fe ff ff 00 	movl   $0x0,0xfffffeb8(%ebp)
40000b21:	00 00 00 
40000b24:	c7 85 b4 fe ff ff 00 	movl   $0x0,0xfffffeb4(%ebp)
40000b2b:	00 00 00 
40000b2e:	c7 85 b0 fe ff ff 00 	movl   $0x0,0xfffffeb0(%ebp)
40000b35:	00 00 00 
40000b38:	8b 85 c4 fe ff ff    	mov    0xfffffec4(%ebp),%eax
40000b3e:	83 c8 01             	or     $0x1,%eax
40000b41:	8b 9d bc fe ff ff    	mov    0xfffffebc(%ebp),%ebx
40000b47:	0f b7 95 c2 fe ff ff 	movzwl 0xfffffec2(%ebp),%edx
40000b4e:	8b b5 b8 fe ff ff    	mov    0xfffffeb8(%ebp),%esi
40000b54:	8b bd b4 fe ff ff    	mov    0xfffffeb4(%ebp),%edi
40000b5a:	8b 8d b0 fe ff ff    	mov    0xfffffeb0(%ebp),%ecx
40000b60:	cd 30                	int    $0x30
40000b62:	b8 03 00 00 00       	mov    $0x3,%eax
40000b67:	cd 30                	int    $0x30
40000b69:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40000b70:	00 
40000b71:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000b78:	00 
40000b79:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000b80:	e8 9f f6 ff ff       	call   40000224 <join>
40000b85:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000b8c:	00 
40000b8d:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000b94:	e8 ab f5 ff ff       	call   40000144 <fork>
40000b99:	85 c0                	test   %eax,%eax
40000b9b:	75 6c                	jne    40000c09 <protcheck+0x458>
40000b9d:	c7 85 dc fe ff ff 00 	movl   $0x1000,0xfffffedc(%ebp)
40000ba4:	10 00 00 
40000ba7:	66 c7 85 da fe ff ff 	movw   $0x0,0xfffffeda(%ebp)
40000bae:	00 00 
40000bb0:	c7 85 d4 fe ff ff 00 	movl   $0x0,0xfffffed4(%ebp)
40000bb7:	00 00 00 
40000bba:	c7 85 d0 fe ff ff 00 	movl   $0x0,0xfffffed0(%ebp)
40000bc1:	00 00 00 
40000bc4:	c7 85 cc fe ff ff 00 	movl   $0x0,0xfffffecc(%ebp)
40000bcb:	00 00 00 
40000bce:	c7 85 c8 fe ff ff 00 	movl   $0x0,0xfffffec8(%ebp)
40000bd5:	00 00 00 
40000bd8:	8b 85 dc fe ff ff    	mov    0xfffffedc(%ebp),%eax
40000bde:	83 c8 02             	or     $0x2,%eax
40000be1:	8b 9d d4 fe ff ff    	mov    0xfffffed4(%ebp),%ebx
40000be7:	0f b7 95 da fe ff ff 	movzwl 0xfffffeda(%ebp),%edx
40000bee:	8b b5 d0 fe ff ff    	mov    0xfffffed0(%ebp),%esi
40000bf4:	8b bd cc fe ff ff    	mov    0xfffffecc(%ebp),%edi
40000bfa:	8b 8d c8 fe ff ff    	mov    0xfffffec8(%ebp),%ecx
40000c00:	cd 30                	int    $0x30
40000c02:	b8 03 00 00 00       	mov    $0x3,%eax
40000c07:	cd 30                	int    $0x30
40000c09:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40000c10:	00 
40000c11:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000c18:	00 
40000c19:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000c20:	e8 ff f5 ff ff       	call   40000224 <join>
40000c25:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000c2c:	00 
40000c2d:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000c34:	e8 0b f5 ff ff       	call   40000144 <fork>
40000c39:	85 c0                	test   %eax,%eax
40000c3b:	75 6c                	jne    40000ca9 <protcheck+0x4f8>
40000c3d:	c7 85 f4 fe ff ff 00 	movl   $0x1000,0xfffffef4(%ebp)
40000c44:	10 00 00 
40000c47:	66 c7 85 f2 fe ff ff 	movw   $0x0,0xfffffef2(%ebp)
40000c4e:	00 00 
40000c50:	c7 85 ec fe ff ff ff 	movl   $0x3fffffff,0xfffffeec(%ebp)
40000c57:	ff ff 3f 
40000c5a:	c7 85 e8 fe ff ff 00 	movl   $0x0,0xfffffee8(%ebp)
40000c61:	00 00 00 
40000c64:	c7 85 e4 fe ff ff 00 	movl   $0x0,0xfffffee4(%ebp)
40000c6b:	00 00 00 
40000c6e:	c7 85 e0 fe ff ff 00 	movl   $0x0,0xfffffee0(%ebp)
40000c75:	00 00 00 
40000c78:	8b 85 f4 fe ff ff    	mov    0xfffffef4(%ebp),%eax
40000c7e:	83 c8 02             	or     $0x2,%eax
40000c81:	8b 9d ec fe ff ff    	mov    0xfffffeec(%ebp),%ebx
40000c87:	0f b7 95 f2 fe ff ff 	movzwl 0xfffffef2(%ebp),%edx
40000c8e:	8b b5 e8 fe ff ff    	mov    0xfffffee8(%ebp),%esi
40000c94:	8b bd e4 fe ff ff    	mov    0xfffffee4(%ebp),%edi
40000c9a:	8b 8d e0 fe ff ff    	mov    0xfffffee0(%ebp),%ecx
40000ca0:	cd 30                	int    $0x30
40000ca2:	b8 03 00 00 00       	mov    $0x3,%eax
40000ca7:	cd 30                	int    $0x30
40000ca9:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40000cb0:	00 
40000cb1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000cb8:	00 
40000cb9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000cc0:	e8 5f f5 ff ff       	call   40000224 <join>
40000cc5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000ccc:	00 
40000ccd:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000cd4:	e8 6b f4 ff ff       	call   40000144 <fork>
40000cd9:	85 c0                	test   %eax,%eax
40000cdb:	75 6c                	jne    40000d49 <protcheck+0x598>
40000cdd:	c7 85 0c ff ff ff 00 	movl   $0x1000,0xffffff0c(%ebp)
40000ce4:	10 00 00 
40000ce7:	66 c7 85 0a ff ff ff 	movw   $0x0,0xffffff0a(%ebp)
40000cee:	00 00 
40000cf0:	c7 85 04 ff ff ff 00 	movl   $0xf0000000,0xffffff04(%ebp)
40000cf7:	00 00 f0 
40000cfa:	c7 85 00 ff ff ff 00 	movl   $0x0,0xffffff00(%ebp)
40000d01:	00 00 00 
40000d04:	c7 85 fc fe ff ff 00 	movl   $0x0,0xfffffefc(%ebp)
40000d0b:	00 00 00 
40000d0e:	c7 85 f8 fe ff ff 00 	movl   $0x0,0xfffffef8(%ebp)
40000d15:	00 00 00 
40000d18:	8b 85 0c ff ff ff    	mov    0xffffff0c(%ebp),%eax
40000d1e:	83 c8 02             	or     $0x2,%eax
40000d21:	8b 9d 04 ff ff ff    	mov    0xffffff04(%ebp),%ebx
40000d27:	0f b7 95 0a ff ff ff 	movzwl 0xffffff0a(%ebp),%edx
40000d2e:	8b b5 00 ff ff ff    	mov    0xffffff00(%ebp),%esi
40000d34:	8b bd fc fe ff ff    	mov    0xfffffefc(%ebp),%edi
40000d3a:	8b 8d f8 fe ff ff    	mov    0xfffffef8(%ebp),%ecx
40000d40:	cd 30                	int    $0x30
40000d42:	b8 03 00 00 00       	mov    $0x3,%eax
40000d47:	cd 30                	int    $0x30
40000d49:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40000d50:	00 
40000d51:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000d58:	00 
40000d59:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000d60:	e8 bf f4 ff ff       	call   40000224 <join>
40000d65:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000d6c:	00 
40000d6d:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000d74:	e8 cb f3 ff ff       	call   40000144 <fork>
40000d79:	85 c0                	test   %eax,%eax
40000d7b:	75 6c                	jne    40000de9 <protcheck+0x638>
40000d7d:	c7 85 24 ff ff ff 00 	movl   $0x1000,0xffffff24(%ebp)
40000d84:	10 00 00 
40000d87:	66 c7 85 22 ff ff ff 	movw   $0x0,0xffffff22(%ebp)
40000d8e:	00 00 
40000d90:	c7 85 1c ff ff ff ff 	movl   $0xffffffff,0xffffff1c(%ebp)
40000d97:	ff ff ff 
40000d9a:	c7 85 18 ff ff ff 00 	movl   $0x0,0xffffff18(%ebp)
40000da1:	00 00 00 
40000da4:	c7 85 14 ff ff ff 00 	movl   $0x0,0xffffff14(%ebp)
40000dab:	00 00 00 
40000dae:	c7 85 10 ff ff ff 00 	movl   $0x0,0xffffff10(%ebp)
40000db5:	00 00 00 
40000db8:	8b 85 24 ff ff ff    	mov    0xffffff24(%ebp),%eax
40000dbe:	83 c8 02             	or     $0x2,%eax
40000dc1:	8b 9d 1c ff ff ff    	mov    0xffffff1c(%ebp),%ebx
40000dc7:	0f b7 95 22 ff ff ff 	movzwl 0xffffff22(%ebp),%edx
40000dce:	8b b5 18 ff ff ff    	mov    0xffffff18(%ebp),%esi
40000dd4:	8b bd 14 ff ff ff    	mov    0xffffff14(%ebp),%edi
40000dda:	8b 8d 10 ff ff ff    	mov    0xffffff10(%ebp),%ecx
40000de0:	cd 30                	int    $0x30
40000de2:	b8 03 00 00 00       	mov    $0x3,%eax
40000de7:	cd 30                	int    $0x30
40000de9:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40000df0:	00 
40000df1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000df8:	00 
40000df9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000e00:	e8 1f f4 ff ff       	call   40000224 <join>
40000e05:	c7 44 24 08 c8 57 00 	movl   $0x400057c8,0x8(%esp)
40000e0c:	40 
40000e0d:	c7 44 24 04 de 00 00 	movl   $0xde,0x4(%esp)
40000e14:	00 
40000e15:	c7 04 24 88 56 00 40 	movl   $0x40005688,(%esp)
40000e1c:	e8 21 1e 00 00       	call   40002c42 <debug_warn>
40000e21:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000e28:	00 
40000e29:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000e30:	e8 0f f3 ff ff       	call   40000144 <fork>
40000e35:	85 c0                	test   %eax,%eax
40000e37:	75 0e                	jne    40000e47 <protcheck+0x696>
40000e39:	b8 00 00 40 40       	mov    $0x40400000,%eax
40000e3e:	8b 00                	mov    (%eax),%eax
40000e40:	b8 03 00 00 00       	mov    $0x3,%eax
40000e45:	cd 30                	int    $0x30
40000e47:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40000e4e:	00 
40000e4f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000e56:	00 
40000e57:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000e5e:	e8 c1 f3 ff ff       	call   40000224 <join>
40000e63:	c7 44 24 08 c8 57 00 	movl   $0x400057c8,0x8(%esp)
40000e6a:	40 
40000e6b:	c7 44 24 04 e1 00 00 	movl   $0xe1,0x4(%esp)
40000e72:	00 
40000e73:	c7 04 24 88 56 00 40 	movl   $0x40005688,(%esp)
40000e7a:	e8 c3 1d 00 00       	call   40002c42 <debug_warn>
40000e7f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000e86:	00 
40000e87:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000e8e:	e8 b1 f2 ff ff       	call   40000144 <fork>
40000e93:	85 c0                	test   %eax,%eax
40000e95:	75 0e                	jne    40000ea5 <protcheck+0x6f4>
40000e97:	b8 00 00 c0 ef       	mov    $0xefc00000,%eax
40000e9c:	8b 00                	mov    (%eax),%eax
40000e9e:	b8 03 00 00 00       	mov    $0x3,%eax
40000ea3:	cd 30                	int    $0x30
40000ea5:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40000eac:	00 
40000ead:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000eb4:	00 
40000eb5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000ebc:	e8 63 f3 ff ff       	call   40000224 <join>
40000ec1:	c7 44 24 08 c8 57 00 	movl   $0x400057c8,0x8(%esp)
40000ec8:	40 
40000ec9:	c7 44 24 04 e3 00 00 	movl   $0xe3,0x4(%esp)
40000ed0:	00 
40000ed1:	c7 04 24 88 56 00 40 	movl   $0x40005688,(%esp)
40000ed8:	e8 65 1d 00 00       	call   40002c42 <debug_warn>
40000edd:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000ee4:	00 
40000ee5:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000eec:	e8 53 f2 ff ff       	call   40000144 <fork>
40000ef1:	85 c0                	test   %eax,%eax
40000ef3:	75 0e                	jne    40000f03 <protcheck+0x752>
40000ef5:	b8 00 00 80 ef       	mov    $0xef800000,%eax
40000efa:	8b 00                	mov    (%eax),%eax
40000efc:	b8 03 00 00 00       	mov    $0x3,%eax
40000f01:	cd 30                	int    $0x30
40000f03:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40000f0a:	00 
40000f0b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000f12:	00 
40000f13:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000f1a:	e8 05 f3 ff ff       	call   40000224 <join>
40000f1f:	c7 44 24 08 c8 57 00 	movl   $0x400057c8,0x8(%esp)
40000f26:	40 
40000f27:	c7 44 24 04 e5 00 00 	movl   $0xe5,0x4(%esp)
40000f2e:	00 
40000f2f:	c7 04 24 88 56 00 40 	movl   $0x40005688,(%esp)
40000f36:	e8 07 1d 00 00       	call   40002c42 <debug_warn>
40000f3b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000f42:	00 
40000f43:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000f4a:	e8 f5 f1 ff ff       	call   40000144 <fork>
40000f4f:	85 c0                	test   %eax,%eax
40000f51:	75 1e                	jne    40000f71 <protcheck+0x7c0>
40000f53:	c7 85 28 ff ff ff 00 	movl   $0x40400000,0xffffff28(%ebp)
40000f5a:	00 40 40 
40000f5d:	b8 00 00 00 00       	mov    $0x0,%eax
40000f62:	8b 9d 28 ff ff ff    	mov    0xffffff28(%ebp),%ebx
40000f68:	cd 30                	int    $0x30
40000f6a:	b8 03 00 00 00       	mov    $0x3,%eax
40000f6f:	cd 30                	int    $0x30
40000f71:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40000f78:	00 
40000f79:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000f80:	00 
40000f81:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000f88:	e8 97 f2 ff ff       	call   40000224 <join>
40000f8d:	c7 44 24 08 c8 57 00 	movl   $0x400057c8,0x8(%esp)
40000f94:	40 
40000f95:	c7 44 24 04 e7 00 00 	movl   $0xe7,0x4(%esp)
40000f9c:	00 
40000f9d:	c7 04 24 88 56 00 40 	movl   $0x40005688,(%esp)
40000fa4:	e8 99 1c 00 00       	call   40002c42 <debug_warn>
40000fa9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000fb0:	00 
40000fb1:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000fb8:	e8 87 f1 ff ff       	call   40000144 <fork>
40000fbd:	85 c0                	test   %eax,%eax
40000fbf:	75 1e                	jne    40000fdf <protcheck+0x82e>
40000fc1:	c7 85 2c ff ff ff 00 	movl   $0xefc00000,0xffffff2c(%ebp)
40000fc8:	00 c0 ef 
40000fcb:	b8 00 00 00 00       	mov    $0x0,%eax
40000fd0:	8b 9d 2c ff ff ff    	mov    0xffffff2c(%ebp),%ebx
40000fd6:	cd 30                	int    $0x30
40000fd8:	b8 03 00 00 00       	mov    $0x3,%eax
40000fdd:	cd 30                	int    $0x30
40000fdf:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40000fe6:	00 
40000fe7:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000fee:	00 
40000fef:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000ff6:	e8 29 f2 ff ff       	call   40000224 <join>
40000ffb:	c7 44 24 08 c8 57 00 	movl   $0x400057c8,0x8(%esp)
40001002:	40 
40001003:	c7 44 24 04 e9 00 00 	movl   $0xe9,0x4(%esp)
4000100a:	00 
4000100b:	c7 04 24 88 56 00 40 	movl   $0x40005688,(%esp)
40001012:	e8 2b 1c 00 00       	call   40002c42 <debug_warn>
40001017:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000101e:	00 
4000101f:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40001026:	e8 19 f1 ff ff       	call   40000144 <fork>
4000102b:	85 c0                	test   %eax,%eax
4000102d:	75 1e                	jne    4000104d <protcheck+0x89c>
4000102f:	c7 85 30 ff ff ff 00 	movl   $0xef800000,0xffffff30(%ebp)
40001036:	00 80 ef 
40001039:	b8 00 00 00 00       	mov    $0x0,%eax
4000103e:	8b 9d 30 ff ff ff    	mov    0xffffff30(%ebp),%ebx
40001044:	cd 30                	int    $0x30
40001046:	b8 03 00 00 00       	mov    $0x3,%eax
4000104b:	cd 30                	int    $0x30
4000104d:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40001054:	00 
40001055:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000105c:	00 
4000105d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40001064:	e8 bb f1 ff ff       	call   40000224 <join>
40001069:	c7 44 24 08 c8 57 00 	movl   $0x400057c8,0x8(%esp)
40001070:	40 
40001071:	c7 44 24 04 eb 00 00 	movl   $0xeb,0x4(%esp)
40001078:	00 
40001079:	c7 04 24 88 56 00 40 	movl   $0x40005688,(%esp)
40001080:	e8 bd 1b 00 00       	call   40002c42 <debug_warn>
40001085:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000108c:	00 
4000108d:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40001094:	e8 ab f0 ff ff       	call   40000144 <fork>
40001099:	85 c0                	test   %eax,%eax
4000109b:	75 6c                	jne    40001109 <protcheck+0x958>
4000109d:	c7 85 48 ff ff ff 00 	movl   $0x1000,0xffffff48(%ebp)
400010a4:	10 00 00 
400010a7:	66 c7 85 46 ff ff ff 	movw   $0x0,0xffffff46(%ebp)
400010ae:	00 00 
400010b0:	c7 85 40 ff ff ff 00 	movl   $0x40400000,0xffffff40(%ebp)
400010b7:	00 40 40 
400010ba:	c7 85 3c ff ff ff 00 	movl   $0x0,0xffffff3c(%ebp)
400010c1:	00 00 00 
400010c4:	c7 85 38 ff ff ff 00 	movl   $0x0,0xffffff38(%ebp)
400010cb:	00 00 00 
400010ce:	c7 85 34 ff ff ff 00 	movl   $0x0,0xffffff34(%ebp)
400010d5:	00 00 00 
400010d8:	8b 85 48 ff ff ff    	mov    0xffffff48(%ebp),%eax
400010de:	83 c8 01             	or     $0x1,%eax
400010e1:	8b 9d 40 ff ff ff    	mov    0xffffff40(%ebp),%ebx
400010e7:	0f b7 95 46 ff ff ff 	movzwl 0xffffff46(%ebp),%edx
400010ee:	8b b5 3c ff ff ff    	mov    0xffffff3c(%ebp),%esi
400010f4:	8b bd 38 ff ff ff    	mov    0xffffff38(%ebp),%edi
400010fa:	8b 8d 34 ff ff ff    	mov    0xffffff34(%ebp),%ecx
40001100:	cd 30                	int    $0x30
40001102:	b8 03 00 00 00       	mov    $0x3,%eax
40001107:	cd 30                	int    $0x30
40001109:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40001110:	00 
40001111:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001118:	00 
40001119:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40001120:	e8 ff f0 ff ff       	call   40000224 <join>
40001125:	c7 44 24 08 c8 57 00 	movl   $0x400057c8,0x8(%esp)
4000112c:	40 
4000112d:	c7 44 24 04 ed 00 00 	movl   $0xed,0x4(%esp)
40001134:	00 
40001135:	c7 04 24 88 56 00 40 	movl   $0x40005688,(%esp)
4000113c:	e8 01 1b 00 00       	call   40002c42 <debug_warn>
40001141:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001148:	00 
40001149:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40001150:	e8 ef ef ff ff       	call   40000144 <fork>
40001155:	85 c0                	test   %eax,%eax
40001157:	75 6c                	jne    400011c5 <protcheck+0xa14>
40001159:	c7 85 60 ff ff ff 00 	movl   $0x1000,0xffffff60(%ebp)
40001160:	10 00 00 
40001163:	66 c7 85 5e ff ff ff 	movw   $0x0,0xffffff5e(%ebp)
4000116a:	00 00 
4000116c:	c7 85 58 ff ff ff 00 	movl   $0xefc00000,0xffffff58(%ebp)
40001173:	00 c0 ef 
40001176:	c7 85 54 ff ff ff 00 	movl   $0x0,0xffffff54(%ebp)
4000117d:	00 00 00 
40001180:	c7 85 50 ff ff ff 00 	movl   $0x0,0xffffff50(%ebp)
40001187:	00 00 00 
4000118a:	c7 85 4c ff ff ff 00 	movl   $0x0,0xffffff4c(%ebp)
40001191:	00 00 00 
40001194:	8b 85 60 ff ff ff    	mov    0xffffff60(%ebp),%eax
4000119a:	83 c8 01             	or     $0x1,%eax
4000119d:	8b 9d 58 ff ff ff    	mov    0xffffff58(%ebp),%ebx
400011a3:	0f b7 95 5e ff ff ff 	movzwl 0xffffff5e(%ebp),%edx
400011aa:	8b b5 54 ff ff ff    	mov    0xffffff54(%ebp),%esi
400011b0:	8b bd 50 ff ff ff    	mov    0xffffff50(%ebp),%edi
400011b6:	8b 8d 4c ff ff ff    	mov    0xffffff4c(%ebp),%ecx
400011bc:	cd 30                	int    $0x30
400011be:	b8 03 00 00 00       	mov    $0x3,%eax
400011c3:	cd 30                	int    $0x30
400011c5:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
400011cc:	00 
400011cd:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400011d4:	00 
400011d5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
400011dc:	e8 43 f0 ff ff       	call   40000224 <join>
400011e1:	c7 44 24 08 c8 57 00 	movl   $0x400057c8,0x8(%esp)
400011e8:	40 
400011e9:	c7 44 24 04 ef 00 00 	movl   $0xef,0x4(%esp)
400011f0:	00 
400011f1:	c7 04 24 88 56 00 40 	movl   $0x40005688,(%esp)
400011f8:	e8 45 1a 00 00       	call   40002c42 <debug_warn>
400011fd:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001204:	00 
40001205:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
4000120c:	e8 33 ef ff ff       	call   40000144 <fork>
40001211:	85 c0                	test   %eax,%eax
40001213:	75 6c                	jne    40001281 <protcheck+0xad0>
40001215:	c7 85 78 ff ff ff 00 	movl   $0x1000,0xffffff78(%ebp)
4000121c:	10 00 00 
4000121f:	66 c7 85 76 ff ff ff 	movw   $0x0,0xffffff76(%ebp)
40001226:	00 00 
40001228:	c7 85 70 ff ff ff 00 	movl   $0xef800000,0xffffff70(%ebp)
4000122f:	00 80 ef 
40001232:	c7 85 6c ff ff ff 00 	movl   $0x0,0xffffff6c(%ebp)
40001239:	00 00 00 
4000123c:	c7 85 68 ff ff ff 00 	movl   $0x0,0xffffff68(%ebp)
40001243:	00 00 00 
40001246:	c7 85 64 ff ff ff 00 	movl   $0x0,0xffffff64(%ebp)
4000124d:	00 00 00 
40001250:	8b 85 78 ff ff ff    	mov    0xffffff78(%ebp),%eax
40001256:	83 c8 01             	or     $0x1,%eax
40001259:	8b 9d 70 ff ff ff    	mov    0xffffff70(%ebp),%ebx
4000125f:	0f b7 95 76 ff ff ff 	movzwl 0xffffff76(%ebp),%edx
40001266:	8b b5 6c ff ff ff    	mov    0xffffff6c(%ebp),%esi
4000126c:	8b bd 68 ff ff ff    	mov    0xffffff68(%ebp),%edi
40001272:	8b 8d 64 ff ff ff    	mov    0xffffff64(%ebp),%ecx
40001278:	cd 30                	int    $0x30
4000127a:	b8 03 00 00 00       	mov    $0x3,%eax
4000127f:	cd 30                	int    $0x30
40001281:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40001288:	00 
40001289:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001290:	00 
40001291:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40001298:	e8 87 ef ff ff       	call   40000224 <join>
4000129d:	c7 44 24 08 c8 57 00 	movl   $0x400057c8,0x8(%esp)
400012a4:	40 
400012a5:	c7 44 24 04 f1 00 00 	movl   $0xf1,0x4(%esp)
400012ac:	00 
400012ad:	c7 04 24 88 56 00 40 	movl   $0x40005688,(%esp)
400012b4:	e8 89 19 00 00       	call   40002c42 <debug_warn>
400012b9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400012c0:	00 
400012c1:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
400012c8:	e8 77 ee ff ff       	call   40000144 <fork>
400012cd:	85 c0                	test   %eax,%eax
400012cf:	75 4e                	jne    4000131f <protcheck+0xb6e>
400012d1:	c7 45 90 00 10 00 00 	movl   $0x1000,0xffffff90(%ebp)
400012d8:	66 c7 45 8e 00 00    	movw   $0x0,0xffffff8e(%ebp)
400012de:	c7 45 88 00 00 40 40 	movl   $0x40400000,0xffffff88(%ebp)
400012e5:	c7 45 84 00 00 00 00 	movl   $0x0,0xffffff84(%ebp)
400012ec:	c7 45 80 00 00 00 00 	movl   $0x0,0xffffff80(%ebp)
400012f3:	c7 85 7c ff ff ff 00 	movl   $0x0,0xffffff7c(%ebp)
400012fa:	00 00 00 
400012fd:	8b 45 90             	mov    0xffffff90(%ebp),%eax
40001300:	83 c8 02             	or     $0x2,%eax
40001303:	8b 5d 88             	mov    0xffffff88(%ebp),%ebx
40001306:	0f b7 55 8e          	movzwl 0xffffff8e(%ebp),%edx
4000130a:	8b 75 84             	mov    0xffffff84(%ebp),%esi
4000130d:	8b 7d 80             	mov    0xffffff80(%ebp),%edi
40001310:	8b 8d 7c ff ff ff    	mov    0xffffff7c(%ebp),%ecx
40001316:	cd 30                	int    $0x30
40001318:	b8 03 00 00 00       	mov    $0x3,%eax
4000131d:	cd 30                	int    $0x30
4000131f:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40001326:	00 
40001327:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000132e:	00 
4000132f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40001336:	e8 e9 ee ff ff       	call   40000224 <join>
4000133b:	c7 44 24 08 c8 57 00 	movl   $0x400057c8,0x8(%esp)
40001342:	40 
40001343:	c7 44 24 04 f3 00 00 	movl   $0xf3,0x4(%esp)
4000134a:	00 
4000134b:	c7 04 24 88 56 00 40 	movl   $0x40005688,(%esp)
40001352:	e8 eb 18 00 00       	call   40002c42 <debug_warn>
40001357:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000135e:	00 
4000135f:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40001366:	e8 d9 ed ff ff       	call   40000144 <fork>
4000136b:	85 c0                	test   %eax,%eax
4000136d:	75 48                	jne    400013b7 <protcheck+0xc06>
4000136f:	c7 45 a8 00 10 00 00 	movl   $0x1000,0xffffffa8(%ebp)
40001376:	66 c7 45 a6 00 00    	movw   $0x0,0xffffffa6(%ebp)
4000137c:	c7 45 a0 00 00 c0 ef 	movl   $0xefc00000,0xffffffa0(%ebp)
40001383:	c7 45 9c 00 00 00 00 	movl   $0x0,0xffffff9c(%ebp)
4000138a:	c7 45 98 00 00 00 00 	movl   $0x0,0xffffff98(%ebp)
40001391:	c7 45 94 00 00 00 00 	movl   $0x0,0xffffff94(%ebp)
40001398:	8b 45 a8             	mov    0xffffffa8(%ebp),%eax
4000139b:	83 c8 02             	or     $0x2,%eax
4000139e:	8b 5d a0             	mov    0xffffffa0(%ebp),%ebx
400013a1:	0f b7 55 a6          	movzwl 0xffffffa6(%ebp),%edx
400013a5:	8b 75 9c             	mov    0xffffff9c(%ebp),%esi
400013a8:	8b 7d 98             	mov    0xffffff98(%ebp),%edi
400013ab:	8b 4d 94             	mov    0xffffff94(%ebp),%ecx
400013ae:	cd 30                	int    $0x30
400013b0:	b8 03 00 00 00       	mov    $0x3,%eax
400013b5:	cd 30                	int    $0x30
400013b7:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
400013be:	00 
400013bf:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400013c6:	00 
400013c7:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
400013ce:	e8 51 ee ff ff       	call   40000224 <join>
400013d3:	c7 44 24 08 c8 57 00 	movl   $0x400057c8,0x8(%esp)
400013da:	40 
400013db:	c7 44 24 04 f5 00 00 	movl   $0xf5,0x4(%esp)
400013e2:	00 
400013e3:	c7 04 24 88 56 00 40 	movl   $0x40005688,(%esp)
400013ea:	e8 53 18 00 00       	call   40002c42 <debug_warn>
400013ef:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400013f6:	00 
400013f7:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
400013fe:	e8 41 ed ff ff       	call   40000144 <fork>
40001403:	85 c0                	test   %eax,%eax
40001405:	75 48                	jne    4000144f <protcheck+0xc9e>
40001407:	c7 45 c0 00 10 00 00 	movl   $0x1000,0xffffffc0(%ebp)
4000140e:	66 c7 45 be 00 00    	movw   $0x0,0xffffffbe(%ebp)
40001414:	c7 45 b8 00 00 80 ef 	movl   $0xef800000,0xffffffb8(%ebp)
4000141b:	c7 45 b4 00 00 00 00 	movl   $0x0,0xffffffb4(%ebp)
40001422:	c7 45 b0 00 00 00 00 	movl   $0x0,0xffffffb0(%ebp)
40001429:	c7 45 ac 00 00 00 00 	movl   $0x0,0xffffffac(%ebp)
40001430:	8b 45 c0             	mov    0xffffffc0(%ebp),%eax
40001433:	83 c8 02             	or     $0x2,%eax
40001436:	8b 5d b8             	mov    0xffffffb8(%ebp),%ebx
40001439:	0f b7 55 be          	movzwl 0xffffffbe(%ebp),%edx
4000143d:	8b 75 b4             	mov    0xffffffb4(%ebp),%esi
40001440:	8b 7d b0             	mov    0xffffffb0(%ebp),%edi
40001443:	8b 4d ac             	mov    0xffffffac(%ebp),%ecx
40001446:	cd 30                	int    $0x30
40001448:	b8 03 00 00 00       	mov    $0x3,%eax
4000144d:	cd 30                	int    $0x30
4000144f:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40001456:	00 
40001457:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000145e:	00 
4000145f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40001466:	e8 b9 ed ff ff       	call   40000224 <join>
4000146b:	c7 44 24 08 c8 57 00 	movl   $0x400057c8,0x8(%esp)
40001472:	40 
40001473:	c7 44 24 04 f7 00 00 	movl   $0xf7,0x4(%esp)
4000147a:	00 
4000147b:	c7 04 24 88 56 00 40 	movl   $0x40005688,(%esp)
40001482:	e8 bb 17 00 00       	call   40002c42 <debug_warn>
40001487:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000148e:	00 
4000148f:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40001496:	e8 a9 ec ff ff       	call   40000144 <fork>
4000149b:	85 c0                	test   %eax,%eax
4000149d:	75 1e                	jne    400014bd <protcheck+0xd0c>
4000149f:	b8 00 01 00 40       	mov    $0x40000100,%eax
400014a4:	89 85 50 fe ff ff    	mov    %eax,0xfffffe50(%ebp)
400014aa:	8b 85 50 fe ff ff    	mov    0xfffffe50(%ebp),%eax
400014b0:	c7 00 ef be ad de    	movl   $0xdeadbeef,(%eax)
400014b6:	b8 03 00 00 00       	mov    $0x3,%eax
400014bb:	cd 30                	int    $0x30
400014bd:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
400014c4:	00 
400014c5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400014cc:	00 
400014cd:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
400014d4:	e8 4b ed ff ff       	call   40000224 <join>
400014d9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400014e0:	00 
400014e1:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
400014e8:	e8 57 ec ff ff       	call   40000144 <fork>
400014ed:	85 c0                	test   %eax,%eax
400014ef:	75 21                	jne    40001512 <protcheck+0xd61>
400014f1:	b8 27 56 00 40       	mov    $0x40005627,%eax
400014f6:	83 e8 04             	sub    $0x4,%eax
400014f9:	89 85 54 fe ff ff    	mov    %eax,0xfffffe54(%ebp)
400014ff:	8b 85 54 fe ff ff    	mov    0xfffffe54(%ebp),%eax
40001505:	c7 00 ef be ad de    	movl   $0xdeadbeef,(%eax)
4000150b:	b8 03 00 00 00       	mov    $0x3,%eax
40001510:	cd 30                	int    $0x30
40001512:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40001519:	00 
4000151a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001521:	00 
40001522:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40001529:	e8 f6 ec ff ff       	call   40000224 <join>
4000152e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001535:	00 
40001536:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
4000153d:	e8 02 ec ff ff       	call   40000144 <fork>
40001542:	85 c0                	test   %eax,%eax
40001544:	75 49                	jne    4000158f <protcheck+0xdde>
40001546:	b8 00 01 00 40       	mov    $0x40000100,%eax
4000154b:	c7 45 d8 00 10 00 00 	movl   $0x1000,0xffffffd8(%ebp)
40001552:	66 c7 45 d6 00 00    	movw   $0x0,0xffffffd6(%ebp)
40001558:	89 45 d0             	mov    %eax,0xffffffd0(%ebp)
4000155b:	c7 45 cc 00 00 00 00 	movl   $0x0,0xffffffcc(%ebp)
40001562:	c7 45 c8 00 00 00 00 	movl   $0x0,0xffffffc8(%ebp)
40001569:	c7 45 c4 00 00 00 00 	movl   $0x0,0xffffffc4(%ebp)
40001570:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
40001573:	83 c8 02             	or     $0x2,%eax
40001576:	8b 5d d0             	mov    0xffffffd0(%ebp),%ebx
40001579:	0f b7 55 d6          	movzwl 0xffffffd6(%ebp),%edx
4000157d:	8b 75 cc             	mov    0xffffffcc(%ebp),%esi
40001580:	8b 7d c8             	mov    0xffffffc8(%ebp),%edi
40001583:	8b 4d c4             	mov    0xffffffc4(%ebp),%ecx
40001586:	cd 30                	int    $0x30
40001588:	b8 03 00 00 00       	mov    $0x3,%eax
4000158d:	cd 30                	int    $0x30
4000158f:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40001596:	00 
40001597:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000159e:	00 
4000159f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
400015a6:	e8 79 ec ff ff       	call   40000224 <join>
400015ab:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400015b2:	00 
400015b3:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
400015ba:	e8 85 eb ff ff       	call   40000144 <fork>
400015bf:	85 c0                	test   %eax,%eax
400015c1:	75 4c                	jne    4000160f <protcheck+0xe5e>
400015c3:	b8 27 56 00 40       	mov    $0x40005627,%eax
400015c8:	83 e8 04             	sub    $0x4,%eax
400015cb:	c7 45 f0 00 10 00 00 	movl   $0x1000,0xfffffff0(%ebp)
400015d2:	66 c7 45 ee 00 00    	movw   $0x0,0xffffffee(%ebp)
400015d8:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
400015db:	c7 45 e4 00 00 00 00 	movl   $0x0,0xffffffe4(%ebp)
400015e2:	c7 45 e0 00 00 00 00 	movl   $0x0,0xffffffe0(%ebp)
400015e9:	c7 45 dc 00 00 00 00 	movl   $0x0,0xffffffdc(%ebp)
400015f0:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
400015f3:	83 c8 02             	or     $0x2,%eax
400015f6:	8b 5d e8             	mov    0xffffffe8(%ebp),%ebx
400015f9:	0f b7 55 ee          	movzwl 0xffffffee(%ebp),%edx
400015fd:	8b 75 e4             	mov    0xffffffe4(%ebp),%esi
40001600:	8b 7d e0             	mov    0xffffffe0(%ebp),%edi
40001603:	8b 4d dc             	mov    0xffffffdc(%ebp),%ecx
40001606:	cd 30                	int    $0x30
40001608:	b8 03 00 00 00       	mov    $0x3,%eax
4000160d:	cd 30                	int    $0x30
4000160f:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40001616:	00 
40001617:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000161e:	00 
4000161f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40001626:	e8 f9 eb ff ff       	call   40000224 <join>
4000162b:	c7 04 24 cd 57 00 40 	movl   $0x400057cd,(%esp)
40001632:	e8 5a 18 00 00       	call   40002e91 <cprintf>
40001637:	81 c4 bc 01 00 00    	add    $0x1bc,%esp
4000163d:	5b                   	pop    %ebx
4000163e:	5e                   	pop    %esi
4000163f:	5f                   	pop    %edi
40001640:	5d                   	pop    %ebp
40001641:	c3                   	ret    

40001642 <memopcheck>:
40001642:	55                   	push   %ebp
40001643:	89 e5                	mov    %esp,%ebp
40001645:	57                   	push   %edi
40001646:	56                   	push   %esi
40001647:	53                   	push   %ebx
40001648:	81 ec 5c 02 00 00    	sub    $0x25c,%esp
4000164e:	c7 85 bc fd ff ff 00 	movl   $0x40401000,0xfffffdbc(%ebp)
40001655:	10 40 40 
40001658:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000165f:	00 
40001660:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40001667:	e8 d8 ea ff ff       	call   40000144 <fork>
4000166c:	85 c0                	test   %eax,%eax
4000166e:	75 0f                	jne    4000167f <memopcheck+0x3d>
40001670:	8b 85 bc fd ff ff    	mov    0xfffffdbc(%ebp),%eax
40001676:	8b 00                	mov    (%eax),%eax
40001678:	b8 03 00 00 00       	mov    $0x3,%eax
4000167d:	cd 30                	int    $0x30
4000167f:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40001686:	00 
40001687:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000168e:	00 
4000168f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40001696:	e8 89 eb ff ff       	call   40000224 <join>
4000169b:	c7 85 f8 fd ff ff 00 	movl   $0x300,0xfffffdf8(%ebp)
400016a2:	03 00 00 
400016a5:	66 c7 85 f6 fd ff ff 	movw   $0x0,0xfffffdf6(%ebp)
400016ac:	00 00 
400016ae:	c7 85 f0 fd ff ff 00 	movl   $0x0,0xfffffdf0(%ebp)
400016b5:	00 00 00 
400016b8:	c7 85 ec fd ff ff 00 	movl   $0x0,0xfffffdec(%ebp)
400016bf:	00 00 00 
400016c2:	8b 85 bc fd ff ff    	mov    0xfffffdbc(%ebp),%eax
400016c8:	89 85 e8 fd ff ff    	mov    %eax,0xfffffde8(%ebp)
400016ce:	c7 85 e4 fd ff ff 00 	movl   $0x1000,0xfffffde4(%ebp)
400016d5:	10 00 00 
400016d8:	8b 85 f8 fd ff ff    	mov    0xfffffdf8(%ebp),%eax
400016de:	83 c8 02             	or     $0x2,%eax
400016e1:	8b 9d f0 fd ff ff    	mov    0xfffffdf0(%ebp),%ebx
400016e7:	0f b7 95 f6 fd ff ff 	movzwl 0xfffffdf6(%ebp),%edx
400016ee:	8b b5 ec fd ff ff    	mov    0xfffffdec(%ebp),%esi
400016f4:	8b bd e8 fd ff ff    	mov    0xfffffde8(%ebp),%edi
400016fa:	8b 8d e4 fd ff ff    	mov    0xfffffde4(%ebp),%ecx
40001700:	cd 30                	int    $0x30
40001702:	8b 85 bc fd ff ff    	mov    0xfffffdbc(%ebp),%eax
40001708:	8b 00                	mov    (%eax),%eax
4000170a:	85 c0                	test   %eax,%eax
4000170c:	74 24                	je     40001732 <memopcheck+0xf0>
4000170e:	c7 44 24 0c e7 57 00 	movl   $0x400057e7,0xc(%esp)
40001715:	40 
40001716:	c7 44 24 08 7f 57 00 	movl   $0x4000577f,0x8(%esp)
4000171d:	40 
4000171e:	c7 44 24 04 0a 01 00 	movl   $0x10a,0x4(%esp)
40001725:	00 
40001726:	c7 04 24 88 56 00 40 	movl   $0x40005688,(%esp)
4000172d:	e8 a6 14 00 00       	call   40002bd8 <debug_panic>
40001732:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001739:	00 
4000173a:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40001741:	e8 fe e9 ff ff       	call   40000144 <fork>
40001746:	85 c0                	test   %eax,%eax
40001748:	75 1f                	jne    40001769 <memopcheck+0x127>
4000174a:	8b 85 bc fd ff ff    	mov    0xfffffdbc(%ebp),%eax
40001750:	89 85 d0 fd ff ff    	mov    %eax,0xfffffdd0(%ebp)
40001756:	8b 85 d0 fd ff ff    	mov    0xfffffdd0(%ebp),%eax
4000175c:	c7 00 ef be ad de    	movl   $0xdeadbeef,(%eax)
40001762:	b8 03 00 00 00       	mov    $0x3,%eax
40001767:	cd 30                	int    $0x30
40001769:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40001770:	00 
40001771:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001778:	00 
40001779:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40001780:	e8 9f ea ff ff       	call   40000224 <join>
40001785:	c7 85 10 fe ff ff 00 	movl   $0x700,0xfffffe10(%ebp)
4000178c:	07 00 00 
4000178f:	66 c7 85 0e fe ff ff 	movw   $0x0,0xfffffe0e(%ebp)
40001796:	00 00 
40001798:	c7 85 08 fe ff ff 00 	movl   $0x0,0xfffffe08(%ebp)
4000179f:	00 00 00 
400017a2:	c7 85 04 fe ff ff 00 	movl   $0x0,0xfffffe04(%ebp)
400017a9:	00 00 00 
400017ac:	8b 85 bc fd ff ff    	mov    0xfffffdbc(%ebp),%eax
400017b2:	89 85 00 fe ff ff    	mov    %eax,0xfffffe00(%ebp)
400017b8:	c7 85 fc fd ff ff 00 	movl   $0x1000,0xfffffdfc(%ebp)
400017bf:	10 00 00 
400017c2:	8b 85 10 fe ff ff    	mov    0xfffffe10(%ebp),%eax
400017c8:	83 c8 02             	or     $0x2,%eax
400017cb:	8b 9d 08 fe ff ff    	mov    0xfffffe08(%ebp),%ebx
400017d1:	0f b7 95 0e fe ff ff 	movzwl 0xfffffe0e(%ebp),%edx
400017d8:	8b b5 04 fe ff ff    	mov    0xfffffe04(%ebp),%esi
400017de:	8b bd 00 fe ff ff    	mov    0xfffffe00(%ebp),%edi
400017e4:	8b 8d fc fd ff ff    	mov    0xfffffdfc(%ebp),%ecx
400017ea:	cd 30                	int    $0x30
400017ec:	8b 85 bc fd ff ff    	mov    0xfffffdbc(%ebp),%eax
400017f2:	c7 00 ef be ad de    	movl   $0xdeadbeef,(%eax)
400017f8:	c7 85 28 fe ff ff 00 	movl   $0x100,0xfffffe28(%ebp)
400017ff:	01 00 00 
40001802:	66 c7 85 26 fe ff ff 	movw   $0x0,0xfffffe26(%ebp)
40001809:	00 00 
4000180b:	c7 85 20 fe ff ff 00 	movl   $0x0,0xfffffe20(%ebp)
40001812:	00 00 00 
40001815:	c7 85 1c fe ff ff 00 	movl   $0x0,0xfffffe1c(%ebp)
4000181c:	00 00 00 
4000181f:	8b 85 bc fd ff ff    	mov    0xfffffdbc(%ebp),%eax
40001825:	89 85 18 fe ff ff    	mov    %eax,0xfffffe18(%ebp)
4000182b:	c7 85 14 fe ff ff 00 	movl   $0x1000,0xfffffe14(%ebp)
40001832:	10 00 00 
40001835:	8b 85 28 fe ff ff    	mov    0xfffffe28(%ebp),%eax
4000183b:	83 c8 02             	or     $0x2,%eax
4000183e:	8b 9d 20 fe ff ff    	mov    0xfffffe20(%ebp),%ebx
40001844:	0f b7 95 26 fe ff ff 	movzwl 0xfffffe26(%ebp),%edx
4000184b:	8b b5 1c fe ff ff    	mov    0xfffffe1c(%ebp),%esi
40001851:	8b bd 18 fe ff ff    	mov    0xfffffe18(%ebp),%edi
40001857:	8b 8d 14 fe ff ff    	mov    0xfffffe14(%ebp),%ecx
4000185d:	cd 30                	int    $0x30
4000185f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001866:	00 
40001867:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
4000186e:	e8 d1 e8 ff ff       	call   40000144 <fork>
40001873:	85 c0                	test   %eax,%eax
40001875:	75 0f                	jne    40001886 <memopcheck+0x244>
40001877:	8b 85 bc fd ff ff    	mov    0xfffffdbc(%ebp),%eax
4000187d:	8b 00                	mov    (%eax),%eax
4000187f:	b8 03 00 00 00       	mov    $0x3,%eax
40001884:	cd 30                	int    $0x30
40001886:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
4000188d:	00 
4000188e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001895:	00 
40001896:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
4000189d:	e8 82 e9 ff ff       	call   40000224 <join>
400018a2:	c7 85 40 fe ff ff 00 	movl   $0x300,0xfffffe40(%ebp)
400018a9:	03 00 00 
400018ac:	66 c7 85 3e fe ff ff 	movw   $0x0,0xfffffe3e(%ebp)
400018b3:	00 00 
400018b5:	c7 85 38 fe ff ff 00 	movl   $0x0,0xfffffe38(%ebp)
400018bc:	00 00 00 
400018bf:	c7 85 34 fe ff ff 00 	movl   $0x0,0xfffffe34(%ebp)
400018c6:	00 00 00 
400018c9:	8b 85 bc fd ff ff    	mov    0xfffffdbc(%ebp),%eax
400018cf:	89 85 30 fe ff ff    	mov    %eax,0xfffffe30(%ebp)
400018d5:	c7 85 2c fe ff ff 00 	movl   $0x1000,0xfffffe2c(%ebp)
400018dc:	10 00 00 
400018df:	8b 85 40 fe ff ff    	mov    0xfffffe40(%ebp),%eax
400018e5:	83 c8 02             	or     $0x2,%eax
400018e8:	8b 9d 38 fe ff ff    	mov    0xfffffe38(%ebp),%ebx
400018ee:	0f b7 95 3e fe ff ff 	movzwl 0xfffffe3e(%ebp),%edx
400018f5:	8b b5 34 fe ff ff    	mov    0xfffffe34(%ebp),%esi
400018fb:	8b bd 30 fe ff ff    	mov    0xfffffe30(%ebp),%edi
40001901:	8b 8d 2c fe ff ff    	mov    0xfffffe2c(%ebp),%ecx
40001907:	cd 30                	int    $0x30
40001909:	8b 85 bc fd ff ff    	mov    0xfffffdbc(%ebp),%eax
4000190f:	8b 00                	mov    (%eax),%eax
40001911:	3d ef be ad de       	cmp    $0xdeadbeef,%eax
40001916:	74 24                	je     4000193c <memopcheck+0x2fa>
40001918:	c7 44 24 0c 00 58 00 	movl   $0x40005800,0xc(%esp)
4000191f:	40 
40001920:	c7 44 24 08 7f 57 00 	movl   $0x4000577f,0x8(%esp)
40001927:	40 
40001928:	c7 44 24 04 11 01 00 	movl   $0x111,0x4(%esp)
4000192f:	00 
40001930:	c7 04 24 88 56 00 40 	movl   $0x40005688,(%esp)
40001937:	e8 9c 12 00 00       	call   40002bd8 <debug_panic>
4000193c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001943:	00 
40001944:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
4000194b:	e8 f4 e7 ff ff       	call   40000144 <fork>
40001950:	85 c0                	test   %eax,%eax
40001952:	75 1f                	jne    40001973 <memopcheck+0x331>
40001954:	8b 85 bc fd ff ff    	mov    0xfffffdbc(%ebp),%eax
4000195a:	89 85 d4 fd ff ff    	mov    %eax,0xfffffdd4(%ebp)
40001960:	8b 85 d4 fd ff ff    	mov    0xfffffdd4(%ebp),%eax
40001966:	c7 00 ef be ad de    	movl   $0xdeadbeef,(%eax)
4000196c:	b8 03 00 00 00       	mov    $0x3,%eax
40001971:	cd 30                	int    $0x30
40001973:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
4000197a:	00 
4000197b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001982:	00 
40001983:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
4000198a:	e8 95 e8 ff ff       	call   40000224 <join>
4000198f:	c7 85 58 fe ff ff 00 	movl   $0x700,0xfffffe58(%ebp)
40001996:	07 00 00 
40001999:	66 c7 85 56 fe ff ff 	movw   $0x0,0xfffffe56(%ebp)
400019a0:	00 00 
400019a2:	c7 85 50 fe ff ff 00 	movl   $0x0,0xfffffe50(%ebp)
400019a9:	00 00 00 
400019ac:	c7 85 4c fe ff ff 00 	movl   $0x0,0xfffffe4c(%ebp)
400019b3:	00 00 00 
400019b6:	8b 85 bc fd ff ff    	mov    0xfffffdbc(%ebp),%eax
400019bc:	89 85 48 fe ff ff    	mov    %eax,0xfffffe48(%ebp)
400019c2:	c7 85 44 fe ff ff 00 	movl   $0x1000,0xfffffe44(%ebp)
400019c9:	10 00 00 
400019cc:	8b 85 58 fe ff ff    	mov    0xfffffe58(%ebp),%eax
400019d2:	83 c8 02             	or     $0x2,%eax
400019d5:	8b 9d 50 fe ff ff    	mov    0xfffffe50(%ebp),%ebx
400019db:	0f b7 95 56 fe ff ff 	movzwl 0xfffffe56(%ebp),%edx
400019e2:	8b b5 4c fe ff ff    	mov    0xfffffe4c(%ebp),%esi
400019e8:	8b bd 48 fe ff ff    	mov    0xfffffe48(%ebp),%edi
400019ee:	8b 8d 44 fe ff ff    	mov    0xfffffe44(%ebp),%ecx
400019f4:	cd 30                	int    $0x30
400019f6:	c7 85 bc fd ff ff 00 	movl   $0x40400000,0xfffffdbc(%ebp)
400019fd:	00 40 40 
40001a00:	c7 85 70 fe ff ff 00 	movl   $0x10000,0xfffffe70(%ebp)
40001a07:	00 01 00 
40001a0a:	66 c7 85 6e fe ff ff 	movw   $0x0,0xfffffe6e(%ebp)
40001a11:	00 00 
40001a13:	c7 85 68 fe ff ff 00 	movl   $0x0,0xfffffe68(%ebp)
40001a1a:	00 00 00 
40001a1d:	c7 85 64 fe ff ff 00 	movl   $0x0,0xfffffe64(%ebp)
40001a24:	00 00 00 
40001a27:	8b 85 bc fd ff ff    	mov    0xfffffdbc(%ebp),%eax
40001a2d:	89 85 60 fe ff ff    	mov    %eax,0xfffffe60(%ebp)
40001a33:	c7 85 5c fe ff ff 00 	movl   $0x400000,0xfffffe5c(%ebp)
40001a3a:	00 40 00 
40001a3d:	8b 85 70 fe ff ff    	mov    0xfffffe70(%ebp),%eax
40001a43:	83 c8 02             	or     $0x2,%eax
40001a46:	8b 9d 68 fe ff ff    	mov    0xfffffe68(%ebp),%ebx
40001a4c:	0f b7 95 6e fe ff ff 	movzwl 0xfffffe6e(%ebp),%edx
40001a53:	8b b5 64 fe ff ff    	mov    0xfffffe64(%ebp),%esi
40001a59:	8b bd 60 fe ff ff    	mov    0xfffffe60(%ebp),%edi
40001a5f:	8b 8d 5c fe ff ff    	mov    0xfffffe5c(%ebp),%ecx
40001a65:	cd 30                	int    $0x30
40001a67:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001a6e:	00 
40001a6f:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40001a76:	e8 c9 e6 ff ff       	call   40000144 <fork>
40001a7b:	85 c0                	test   %eax,%eax
40001a7d:	75 0f                	jne    40001a8e <memopcheck+0x44c>
40001a7f:	8b 85 bc fd ff ff    	mov    0xfffffdbc(%ebp),%eax
40001a85:	8b 00                	mov    (%eax),%eax
40001a87:	b8 03 00 00 00       	mov    $0x3,%eax
40001a8c:	cd 30                	int    $0x30
40001a8e:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40001a95:	00 
40001a96:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001a9d:	00 
40001a9e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40001aa5:	e8 7a e7 ff ff       	call   40000224 <join>
40001aaa:	c7 85 88 fe ff ff 00 	movl   $0x300,0xfffffe88(%ebp)
40001ab1:	03 00 00 
40001ab4:	66 c7 85 86 fe ff ff 	movw   $0x0,0xfffffe86(%ebp)
40001abb:	00 00 
40001abd:	c7 85 80 fe ff ff 00 	movl   $0x0,0xfffffe80(%ebp)
40001ac4:	00 00 00 
40001ac7:	c7 85 7c fe ff ff 00 	movl   $0x0,0xfffffe7c(%ebp)
40001ace:	00 00 00 
40001ad1:	8b 85 bc fd ff ff    	mov    0xfffffdbc(%ebp),%eax
40001ad7:	89 85 78 fe ff ff    	mov    %eax,0xfffffe78(%ebp)
40001add:	c7 85 74 fe ff ff 00 	movl   $0x1000,0xfffffe74(%ebp)
40001ae4:	10 00 00 
40001ae7:	8b 85 88 fe ff ff    	mov    0xfffffe88(%ebp),%eax
40001aed:	83 c8 02             	or     $0x2,%eax
40001af0:	8b 9d 80 fe ff ff    	mov    0xfffffe80(%ebp),%ebx
40001af6:	0f b7 95 86 fe ff ff 	movzwl 0xfffffe86(%ebp),%edx
40001afd:	8b b5 7c fe ff ff    	mov    0xfffffe7c(%ebp),%esi
40001b03:	8b bd 78 fe ff ff    	mov    0xfffffe78(%ebp),%edi
40001b09:	8b 8d 74 fe ff ff    	mov    0xfffffe74(%ebp),%ecx
40001b0f:	cd 30                	int    $0x30
40001b11:	8b 85 bc fd ff ff    	mov    0xfffffdbc(%ebp),%eax
40001b17:	8b 00                	mov    (%eax),%eax
40001b19:	85 c0                	test   %eax,%eax
40001b1b:	74 24                	je     40001b41 <memopcheck+0x4ff>
40001b1d:	c7 44 24 0c e7 57 00 	movl   $0x400057e7,0xc(%esp)
40001b24:	40 
40001b25:	c7 44 24 08 7f 57 00 	movl   $0x4000577f,0x8(%esp)
40001b2c:	40 
40001b2d:	c7 44 24 04 1a 01 00 	movl   $0x11a,0x4(%esp)
40001b34:	00 
40001b35:	c7 04 24 88 56 00 40 	movl   $0x40005688,(%esp)
40001b3c:	e8 97 10 00 00       	call   40002bd8 <debug_panic>
40001b41:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001b48:	00 
40001b49:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40001b50:	e8 ef e5 ff ff       	call   40000144 <fork>
40001b55:	85 c0                	test   %eax,%eax
40001b57:	75 1f                	jne    40001b78 <memopcheck+0x536>
40001b59:	8b 85 bc fd ff ff    	mov    0xfffffdbc(%ebp),%eax
40001b5f:	89 85 d8 fd ff ff    	mov    %eax,0xfffffdd8(%ebp)
40001b65:	8b 85 d8 fd ff ff    	mov    0xfffffdd8(%ebp),%eax
40001b6b:	c7 00 ef be ad de    	movl   $0xdeadbeef,(%eax)
40001b71:	b8 03 00 00 00       	mov    $0x3,%eax
40001b76:	cd 30                	int    $0x30
40001b78:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40001b7f:	00 
40001b80:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001b87:	00 
40001b88:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40001b8f:	e8 90 e6 ff ff       	call   40000224 <join>
40001b94:	c7 85 a0 fe ff ff 00 	movl   $0x10000,0xfffffea0(%ebp)
40001b9b:	00 01 00 
40001b9e:	66 c7 85 9e fe ff ff 	movw   $0x0,0xfffffe9e(%ebp)
40001ba5:	00 00 
40001ba7:	c7 85 98 fe ff ff 00 	movl   $0x0,0xfffffe98(%ebp)
40001bae:	00 00 00 
40001bb1:	c7 85 94 fe ff ff 00 	movl   $0x0,0xfffffe94(%ebp)
40001bb8:	00 00 00 
40001bbb:	8b 85 bc fd ff ff    	mov    0xfffffdbc(%ebp),%eax
40001bc1:	89 85 90 fe ff ff    	mov    %eax,0xfffffe90(%ebp)
40001bc7:	c7 85 8c fe ff ff 00 	movl   $0x400000,0xfffffe8c(%ebp)
40001bce:	00 40 00 
40001bd1:	8b 85 a0 fe ff ff    	mov    0xfffffea0(%ebp),%eax
40001bd7:	83 c8 02             	or     $0x2,%eax
40001bda:	8b 9d 98 fe ff ff    	mov    0xfffffe98(%ebp),%ebx
40001be0:	0f b7 95 9e fe ff ff 	movzwl 0xfffffe9e(%ebp),%edx
40001be7:	8b b5 94 fe ff ff    	mov    0xfffffe94(%ebp),%esi
40001bed:	8b bd 90 fe ff ff    	mov    0xfffffe90(%ebp),%edi
40001bf3:	8b 8d 8c fe ff ff    	mov    0xfffffe8c(%ebp),%ecx
40001bf9:	cd 30                	int    $0x30
40001bfb:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001c02:	00 
40001c03:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40001c0a:	e8 35 e5 ff ff       	call   40000144 <fork>
40001c0f:	85 c0                	test   %eax,%eax
40001c11:	75 0f                	jne    40001c22 <memopcheck+0x5e0>
40001c13:	8b 85 bc fd ff ff    	mov    0xfffffdbc(%ebp),%eax
40001c19:	8b 00                	mov    (%eax),%eax
40001c1b:	b8 03 00 00 00       	mov    $0x3,%eax
40001c20:	cd 30                	int    $0x30
40001c22:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40001c29:	00 
40001c2a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001c31:	00 
40001c32:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40001c39:	e8 e6 e5 ff ff       	call   40000224 <join>
40001c3e:	c7 85 b8 fe ff ff 00 	movl   $0x700,0xfffffeb8(%ebp)
40001c45:	07 00 00 
40001c48:	66 c7 85 b6 fe ff ff 	movw   $0x0,0xfffffeb6(%ebp)
40001c4f:	00 00 
40001c51:	c7 85 b0 fe ff ff 00 	movl   $0x0,0xfffffeb0(%ebp)
40001c58:	00 00 00 
40001c5b:	c7 85 ac fe ff ff 00 	movl   $0x0,0xfffffeac(%ebp)
40001c62:	00 00 00 
40001c65:	8b 85 bc fd ff ff    	mov    0xfffffdbc(%ebp),%eax
40001c6b:	89 85 a8 fe ff ff    	mov    %eax,0xfffffea8(%ebp)
40001c71:	c7 85 a4 fe ff ff 00 	movl   $0x1000,0xfffffea4(%ebp)
40001c78:	10 00 00 
40001c7b:	8b 85 b8 fe ff ff    	mov    0xfffffeb8(%ebp),%eax
40001c81:	83 c8 02             	or     $0x2,%eax
40001c84:	8b 9d b0 fe ff ff    	mov    0xfffffeb0(%ebp),%ebx
40001c8a:	0f b7 95 b6 fe ff ff 	movzwl 0xfffffeb6(%ebp),%edx
40001c91:	8b b5 ac fe ff ff    	mov    0xfffffeac(%ebp),%esi
40001c97:	8b bd a8 fe ff ff    	mov    0xfffffea8(%ebp),%edi
40001c9d:	8b 8d a4 fe ff ff    	mov    0xfffffea4(%ebp),%ecx
40001ca3:	cd 30                	int    $0x30
40001ca5:	8b 85 bc fd ff ff    	mov    0xfffffdbc(%ebp),%eax
40001cab:	c7 00 ef be ad de    	movl   $0xdeadbeef,(%eax)
40001cb1:	c7 85 d0 fe ff ff 00 	movl   $0x10000,0xfffffed0(%ebp)
40001cb8:	00 01 00 
40001cbb:	66 c7 85 ce fe ff ff 	movw   $0x0,0xfffffece(%ebp)
40001cc2:	00 00 
40001cc4:	c7 85 c8 fe ff ff 00 	movl   $0x0,0xfffffec8(%ebp)
40001ccb:	00 00 00 
40001cce:	c7 85 c4 fe ff ff 00 	movl   $0x0,0xfffffec4(%ebp)
40001cd5:	00 00 00 
40001cd8:	8b 85 bc fd ff ff    	mov    0xfffffdbc(%ebp),%eax
40001cde:	89 85 c0 fe ff ff    	mov    %eax,0xfffffec0(%ebp)
40001ce4:	c7 85 bc fe ff ff 00 	movl   $0x400000,0xfffffebc(%ebp)
40001ceb:	00 40 00 
40001cee:	8b 85 d0 fe ff ff    	mov    0xfffffed0(%ebp),%eax
40001cf4:	83 c8 02             	or     $0x2,%eax
40001cf7:	8b 9d c8 fe ff ff    	mov    0xfffffec8(%ebp),%ebx
40001cfd:	0f b7 95 ce fe ff ff 	movzwl 0xfffffece(%ebp),%edx
40001d04:	8b b5 c4 fe ff ff    	mov    0xfffffec4(%ebp),%esi
40001d0a:	8b bd c0 fe ff ff    	mov    0xfffffec0(%ebp),%edi
40001d10:	8b 8d bc fe ff ff    	mov    0xfffffebc(%ebp),%ecx
40001d16:	cd 30                	int    $0x30
40001d18:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001d1f:	00 
40001d20:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40001d27:	e8 18 e4 ff ff       	call   40000144 <fork>
40001d2c:	85 c0                	test   %eax,%eax
40001d2e:	75 0f                	jne    40001d3f <memopcheck+0x6fd>
40001d30:	8b 85 bc fd ff ff    	mov    0xfffffdbc(%ebp),%eax
40001d36:	8b 00                	mov    (%eax),%eax
40001d38:	b8 03 00 00 00       	mov    $0x3,%eax
40001d3d:	cd 30                	int    $0x30
40001d3f:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40001d46:	00 
40001d47:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001d4e:	00 
40001d4f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40001d56:	e8 c9 e4 ff ff       	call   40000224 <join>
40001d5b:	c7 85 e8 fe ff ff 00 	movl   $0x300,0xfffffee8(%ebp)
40001d62:	03 00 00 
40001d65:	66 c7 85 e6 fe ff ff 	movw   $0x0,0xfffffee6(%ebp)
40001d6c:	00 00 
40001d6e:	c7 85 e0 fe ff ff 00 	movl   $0x0,0xfffffee0(%ebp)
40001d75:	00 00 00 
40001d78:	c7 85 dc fe ff ff 00 	movl   $0x0,0xfffffedc(%ebp)
40001d7f:	00 00 00 
40001d82:	8b 85 bc fd ff ff    	mov    0xfffffdbc(%ebp),%eax
40001d88:	89 85 d8 fe ff ff    	mov    %eax,0xfffffed8(%ebp)
40001d8e:	c7 85 d4 fe ff ff 00 	movl   $0x1000,0xfffffed4(%ebp)
40001d95:	10 00 00 
40001d98:	8b 85 e8 fe ff ff    	mov    0xfffffee8(%ebp),%eax
40001d9e:	83 c8 02             	or     $0x2,%eax
40001da1:	8b 9d e0 fe ff ff    	mov    0xfffffee0(%ebp),%ebx
40001da7:	0f b7 95 e6 fe ff ff 	movzwl 0xfffffee6(%ebp),%edx
40001dae:	8b b5 dc fe ff ff    	mov    0xfffffedc(%ebp),%esi
40001db4:	8b bd d8 fe ff ff    	mov    0xfffffed8(%ebp),%edi
40001dba:	8b 8d d4 fe ff ff    	mov    0xfffffed4(%ebp),%ecx
40001dc0:	cd 30                	int    $0x30
40001dc2:	8b 85 bc fd ff ff    	mov    0xfffffdbc(%ebp),%eax
40001dc8:	8b 00                	mov    (%eax),%eax
40001dca:	85 c0                	test   %eax,%eax
40001dcc:	74 24                	je     40001df2 <memopcheck+0x7b0>
40001dce:	c7 44 24 0c e7 57 00 	movl   $0x400057e7,0xc(%esp)
40001dd5:	40 
40001dd6:	c7 44 24 08 7f 57 00 	movl   $0x4000577f,0x8(%esp)
40001ddd:	40 
40001dde:	c7 44 24 04 23 01 00 	movl   $0x123,0x4(%esp)
40001de5:	00 
40001de6:	c7 04 24 88 56 00 40 	movl   $0x40005688,(%esp)
40001ded:	e8 e6 0d 00 00       	call   40002bd8 <debug_panic>
40001df2:	c7 85 c0 fd ff ff 00 	movl   $0x40000000,0xfffffdc0(%ebp)
40001df9:	00 00 40 
40001dfc:	c7 85 c4 fd ff ff 00 	movl   $0x40400000,0xfffffdc4(%ebp)
40001e03:	00 40 40 
40001e06:	c7 85 00 ff ff ff 00 	movl   $0x20000,0xffffff00(%ebp)
40001e0d:	00 02 00 
40001e10:	66 c7 85 fe fe ff ff 	movw   $0x0,0xfffffefe(%ebp)
40001e17:	00 00 
40001e19:	c7 85 f8 fe ff ff 00 	movl   $0x0,0xfffffef8(%ebp)
40001e20:	00 00 00 
40001e23:	8b 85 c0 fd ff ff    	mov    0xfffffdc0(%ebp),%eax
40001e29:	89 85 f4 fe ff ff    	mov    %eax,0xfffffef4(%ebp)
40001e2f:	8b 85 c4 fd ff ff    	mov    0xfffffdc4(%ebp),%eax
40001e35:	89 85 f0 fe ff ff    	mov    %eax,0xfffffef0(%ebp)
40001e3b:	c7 85 ec fe ff ff 00 	movl   $0x400000,0xfffffeec(%ebp)
40001e42:	00 40 00 
40001e45:	8b 85 00 ff ff ff    	mov    0xffffff00(%ebp),%eax
40001e4b:	83 c8 02             	or     $0x2,%eax
40001e4e:	8b 9d f8 fe ff ff    	mov    0xfffffef8(%ebp),%ebx
40001e54:	0f b7 95 fe fe ff ff 	movzwl 0xfffffefe(%ebp),%edx
40001e5b:	8b b5 f4 fe ff ff    	mov    0xfffffef4(%ebp),%esi
40001e61:	8b bd f0 fe ff ff    	mov    0xfffffef0(%ebp),%edi
40001e67:	8b 8d ec fe ff ff    	mov    0xfffffeec(%ebp),%ecx
40001e6d:	cd 30                	int    $0x30
40001e6f:	ba 27 56 00 40       	mov    $0x40005627,%edx
40001e74:	b8 00 01 00 40       	mov    $0x40000100,%eax
40001e79:	89 d1                	mov    %edx,%ecx
40001e7b:	29 c1                	sub    %eax,%ecx
40001e7d:	89 c8                	mov    %ecx,%eax
40001e7f:	89 44 24 08          	mov    %eax,0x8(%esp)
40001e83:	8b 85 c4 fd ff ff    	mov    0xfffffdc4(%ebp),%eax
40001e89:	89 44 24 04          	mov    %eax,0x4(%esp)
40001e8d:	8b 85 c0 fd ff ff    	mov    0xfffffdc0(%ebp),%eax
40001e93:	89 04 24             	mov    %eax,(%esp)
40001e96:	e8 5e 1a 00 00       	call   400038f9 <memcmp>
40001e9b:	85 c0                	test   %eax,%eax
40001e9d:	74 24                	je     40001ec3 <memopcheck+0x881>
40001e9f:	c7 44 24 0c 24 58 00 	movl   $0x40005824,0xc(%esp)
40001ea6:	40 
40001ea7:	c7 44 24 08 7f 57 00 	movl   $0x4000577f,0x8(%esp)
40001eae:	40 
40001eaf:	c7 44 24 04 29 01 00 	movl   $0x129,0x4(%esp)
40001eb6:	00 
40001eb7:	c7 04 24 88 56 00 40 	movl   $0x40005688,(%esp)
40001ebe:	e8 15 0d 00 00       	call   40002bd8 <debug_panic>
40001ec3:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001eca:	00 
40001ecb:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40001ed2:	e8 6d e2 ff ff       	call   40000144 <fork>
40001ed7:	85 c0                	test   %eax,%eax
40001ed9:	75 1f                	jne    40001efa <memopcheck+0x8b8>
40001edb:	8b 85 c4 fd ff ff    	mov    0xfffffdc4(%ebp),%eax
40001ee1:	89 85 dc fd ff ff    	mov    %eax,0xfffffddc(%ebp)
40001ee7:	8b 85 dc fd ff ff    	mov    0xfffffddc(%ebp),%eax
40001eed:	c7 00 ef be ad de    	movl   $0xdeadbeef,(%eax)
40001ef3:	b8 03 00 00 00       	mov    $0x3,%eax
40001ef8:	cd 30                	int    $0x30
40001efa:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40001f01:	00 
40001f02:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001f09:	00 
40001f0a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40001f11:	e8 0e e3 ff ff       	call   40000224 <join>
40001f16:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001f1d:	00 
40001f1e:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40001f25:	e8 1a e2 ff ff       	call   40000144 <fork>
40001f2a:	85 c0                	test   %eax,%eax
40001f2c:	75 14                	jne    40001f42 <memopcheck+0x900>
40001f2e:	8b 85 c4 fd ff ff    	mov    0xfffffdc4(%ebp),%eax
40001f34:	05 fc ff 3f 00       	add    $0x3ffffc,%eax
40001f39:	8b 00                	mov    (%eax),%eax
40001f3b:	b8 03 00 00 00       	mov    $0x3,%eax
40001f40:	cd 30                	int    $0x30
40001f42:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40001f49:	00 
40001f4a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001f51:	00 
40001f52:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40001f59:	e8 c6 e2 ff ff       	call   40000224 <join>
40001f5e:	c7 85 c8 fd ff ff 00 	movl   $0x40800000,0xfffffdc8(%ebp)
40001f65:	00 80 40 
40001f68:	c7 85 18 ff ff ff 00 	movl   $0x10000,0xffffff18(%ebp)
40001f6f:	00 01 00 
40001f72:	66 c7 85 16 ff ff ff 	movw   $0x0,0xffffff16(%ebp)
40001f79:	00 00 
40001f7b:	c7 85 10 ff ff ff 00 	movl   $0x0,0xffffff10(%ebp)
40001f82:	00 00 00 
40001f85:	c7 85 0c ff ff ff 00 	movl   $0x0,0xffffff0c(%ebp)
40001f8c:	00 00 00 
40001f8f:	8b 85 c4 fd ff ff    	mov    0xfffffdc4(%ebp),%eax
40001f95:	89 85 08 ff ff ff    	mov    %eax,0xffffff08(%ebp)
40001f9b:	c7 85 04 ff ff ff 00 	movl   $0x400000,0xffffff04(%ebp)
40001fa2:	00 40 00 
40001fa5:	8b 85 18 ff ff ff    	mov    0xffffff18(%ebp),%eax
40001fab:	83 c8 01             	or     $0x1,%eax
40001fae:	8b 9d 10 ff ff ff    	mov    0xffffff10(%ebp),%ebx
40001fb4:	0f b7 95 16 ff ff ff 	movzwl 0xffffff16(%ebp),%edx
40001fbb:	8b b5 0c ff ff ff    	mov    0xffffff0c(%ebp),%esi
40001fc1:	8b bd 08 ff ff ff    	mov    0xffffff08(%ebp),%edi
40001fc7:	8b 8d 04 ff ff ff    	mov    0xffffff04(%ebp),%ecx
40001fcd:	cd 30                	int    $0x30
40001fcf:	c7 85 30 ff ff ff 00 	movl   $0x20000,0xffffff30(%ebp)
40001fd6:	00 02 00 
40001fd9:	66 c7 85 2e ff ff ff 	movw   $0x0,0xffffff2e(%ebp)
40001fe0:	00 00 
40001fe2:	c7 85 28 ff ff ff 00 	movl   $0x0,0xffffff28(%ebp)
40001fe9:	00 00 00 
40001fec:	8b 85 c4 fd ff ff    	mov    0xfffffdc4(%ebp),%eax
40001ff2:	89 85 24 ff ff ff    	mov    %eax,0xffffff24(%ebp)
40001ff8:	8b 85 c8 fd ff ff    	mov    0xfffffdc8(%ebp),%eax
40001ffe:	89 85 20 ff ff ff    	mov    %eax,0xffffff20(%ebp)
40002004:	c7 85 1c ff ff ff 00 	movl   $0x400000,0xffffff1c(%ebp)
4000200b:	00 40 00 
4000200e:	8b 85 30 ff ff ff    	mov    0xffffff30(%ebp),%eax
40002014:	83 c8 02             	or     $0x2,%eax
40002017:	8b 9d 28 ff ff ff    	mov    0xffffff28(%ebp),%ebx
4000201d:	0f b7 95 2e ff ff ff 	movzwl 0xffffff2e(%ebp),%edx
40002024:	8b b5 24 ff ff ff    	mov    0xffffff24(%ebp),%esi
4000202a:	8b bd 20 ff ff ff    	mov    0xffffff20(%ebp),%edi
40002030:	8b 8d 1c ff ff ff    	mov    0xffffff1c(%ebp),%ecx
40002036:	cd 30                	int    $0x30
40002038:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000203f:	00 
40002040:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40002047:	e8 f8 e0 ff ff       	call   40000144 <fork>
4000204c:	85 c0                	test   %eax,%eax
4000204e:	75 0f                	jne    4000205f <memopcheck+0xa1d>
40002050:	8b 85 c8 fd ff ff    	mov    0xfffffdc8(%ebp),%eax
40002056:	8b 00                	mov    (%eax),%eax
40002058:	b8 03 00 00 00       	mov    $0x3,%eax
4000205d:	cd 30                	int    $0x30
4000205f:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40002066:	00 
40002067:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000206e:	00 
4000206f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40002076:	e8 a9 e1 ff ff       	call   40000224 <join>
4000207b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40002082:	00 
40002083:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
4000208a:	e8 b5 e0 ff ff       	call   40000144 <fork>
4000208f:	85 c0                	test   %eax,%eax
40002091:	75 14                	jne    400020a7 <memopcheck+0xa65>
40002093:	8b 85 c8 fd ff ff    	mov    0xfffffdc8(%ebp),%eax
40002099:	05 fc ff 3f 00       	add    $0x3ffffc,%eax
4000209e:	8b 00                	mov    (%eax),%eax
400020a0:	b8 03 00 00 00       	mov    $0x3,%eax
400020a5:	cd 30                	int    $0x30
400020a7:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
400020ae:	00 
400020af:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400020b6:	00 
400020b7:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
400020be:	e8 61 e1 ff ff       	call   40000224 <join>
400020c3:	c7 85 48 ff ff ff 00 	movl   $0x300,0xffffff48(%ebp)
400020ca:	03 00 00 
400020cd:	66 c7 85 46 ff ff ff 	movw   $0x0,0xffffff46(%ebp)
400020d4:	00 00 
400020d6:	c7 85 40 ff ff ff 00 	movl   $0x0,0xffffff40(%ebp)
400020dd:	00 00 00 
400020e0:	c7 85 3c ff ff ff 00 	movl   $0x0,0xffffff3c(%ebp)
400020e7:	00 00 00 
400020ea:	8b 85 c8 fd ff ff    	mov    0xfffffdc8(%ebp),%eax
400020f0:	89 85 38 ff ff ff    	mov    %eax,0xffffff38(%ebp)
400020f6:	c7 85 34 ff ff ff 00 	movl   $0x400000,0xffffff34(%ebp)
400020fd:	00 40 00 
40002100:	8b 85 48 ff ff ff    	mov    0xffffff48(%ebp),%eax
40002106:	83 c8 02             	or     $0x2,%eax
40002109:	8b 9d 40 ff ff ff    	mov    0xffffff40(%ebp),%ebx
4000210f:	0f b7 95 46 ff ff ff 	movzwl 0xffffff46(%ebp),%edx
40002116:	8b b5 3c ff ff ff    	mov    0xffffff3c(%ebp),%esi
4000211c:	8b bd 38 ff ff ff    	mov    0xffffff38(%ebp),%edi
40002122:	8b 8d 34 ff ff ff    	mov    0xffffff34(%ebp),%ecx
40002128:	cd 30                	int    $0x30
4000212a:	8b 85 c8 fd ff ff    	mov    0xfffffdc8(%ebp),%eax
40002130:	8b 00                	mov    (%eax),%eax
40002132:	85 c0                	test   %eax,%eax
40002134:	74 24                	je     4000215a <memopcheck+0xb18>
40002136:	c7 44 24 0c 49 58 00 	movl   $0x40005849,0xc(%esp)
4000213d:	40 
4000213e:	c7 44 24 08 7f 57 00 	movl   $0x4000577f,0x8(%esp)
40002145:	40 
40002146:	c7 44 24 04 34 01 00 	movl   $0x134,0x4(%esp)
4000214d:	00 
4000214e:	c7 04 24 88 56 00 40 	movl   $0x40005688,(%esp)
40002155:	e8 7e 0a 00 00       	call   40002bd8 <debug_panic>
4000215a:	8b 85 c8 fd ff ff    	mov    0xfffffdc8(%ebp),%eax
40002160:	05 fc ff 3f 00       	add    $0x3ffffc,%eax
40002165:	8b 00                	mov    (%eax),%eax
40002167:	85 c0                	test   %eax,%eax
40002169:	74 24                	je     4000218f <memopcheck+0xb4d>
4000216b:	c7 44 24 0c 64 58 00 	movl   $0x40005864,0xc(%esp)
40002172:	40 
40002173:	c7 44 24 08 7f 57 00 	movl   $0x4000577f,0x8(%esp)
4000217a:	40 
4000217b:	c7 44 24 04 35 01 00 	movl   $0x135,0x4(%esp)
40002182:	00 
40002183:	c7 04 24 88 56 00 40 	movl   $0x40005688,(%esp)
4000218a:	e8 49 0a 00 00       	call   40002bd8 <debug_panic>
4000218f:	c7 85 60 ff ff ff 00 	movl   $0x20000,0xffffff60(%ebp)
40002196:	00 02 00 
40002199:	66 c7 85 5e ff ff ff 	movw   $0x0,0xffffff5e(%ebp)
400021a0:	00 00 
400021a2:	c7 85 58 ff ff ff 00 	movl   $0x0,0xffffff58(%ebp)
400021a9:	00 00 00 
400021ac:	8b 85 c0 fd ff ff    	mov    0xfffffdc0(%ebp),%eax
400021b2:	89 85 54 ff ff ff    	mov    %eax,0xffffff54(%ebp)
400021b8:	8b 85 c4 fd ff ff    	mov    0xfffffdc4(%ebp),%eax
400021be:	89 85 50 ff ff ff    	mov    %eax,0xffffff50(%ebp)
400021c4:	c7 85 4c ff ff ff 00 	movl   $0x400000,0xffffff4c(%ebp)
400021cb:	00 40 00 
400021ce:	8b 85 60 ff ff ff    	mov    0xffffff60(%ebp),%eax
400021d4:	83 c8 01             	or     $0x1,%eax
400021d7:	8b 9d 58 ff ff ff    	mov    0xffffff58(%ebp),%ebx
400021dd:	0f b7 95 5e ff ff ff 	movzwl 0xffffff5e(%ebp),%edx
400021e4:	8b b5 54 ff ff ff    	mov    0xffffff54(%ebp),%esi
400021ea:	8b bd 50 ff ff ff    	mov    0xffffff50(%ebp),%edi
400021f0:	8b 8d 4c ff ff ff    	mov    0xffffff4c(%ebp),%ecx
400021f6:	cd 30                	int    $0x30
400021f8:	c7 85 78 ff ff ff 00 	movl   $0x20000,0xffffff78(%ebp)
400021ff:	00 02 00 
40002202:	66 c7 85 76 ff ff ff 	movw   $0x0,0xffffff76(%ebp)
40002209:	00 00 
4000220b:	c7 85 70 ff ff ff 00 	movl   $0x0,0xffffff70(%ebp)
40002212:	00 00 00 
40002215:	8b 85 c4 fd ff ff    	mov    0xfffffdc4(%ebp),%eax
4000221b:	89 85 6c ff ff ff    	mov    %eax,0xffffff6c(%ebp)
40002221:	8b 85 c8 fd ff ff    	mov    0xfffffdc8(%ebp),%eax
40002227:	89 85 68 ff ff ff    	mov    %eax,0xffffff68(%ebp)
4000222d:	c7 85 64 ff ff ff 00 	movl   $0x400000,0xffffff64(%ebp)
40002234:	00 40 00 
40002237:	8b 85 78 ff ff ff    	mov    0xffffff78(%ebp),%eax
4000223d:	83 c8 02             	or     $0x2,%eax
40002240:	8b 9d 70 ff ff ff    	mov    0xffffff70(%ebp),%ebx
40002246:	0f b7 95 76 ff ff ff 	movzwl 0xffffff76(%ebp),%edx
4000224d:	8b b5 6c ff ff ff    	mov    0xffffff6c(%ebp),%esi
40002253:	8b bd 68 ff ff ff    	mov    0xffffff68(%ebp),%edi
40002259:	8b 8d 64 ff ff ff    	mov    0xffffff64(%ebp),%ecx
4000225f:	cd 30                	int    $0x30
40002261:	ba 27 56 00 40       	mov    $0x40005627,%edx
40002266:	b8 00 01 00 40       	mov    $0x40000100,%eax
4000226b:	89 d1                	mov    %edx,%ecx
4000226d:	29 c1                	sub    %eax,%ecx
4000226f:	89 c8                	mov    %ecx,%eax
40002271:	89 44 24 08          	mov    %eax,0x8(%esp)
40002275:	8b 85 c8 fd ff ff    	mov    0xfffffdc8(%ebp),%eax
4000227b:	89 44 24 04          	mov    %eax,0x4(%esp)
4000227f:	8b 85 c0 fd ff ff    	mov    0xfffffdc0(%ebp),%eax
40002285:	89 04 24             	mov    %eax,(%esp)
40002288:	e8 6c 16 00 00       	call   400038f9 <memcmp>
4000228d:	85 c0                	test   %eax,%eax
4000228f:	74 24                	je     400022b5 <memopcheck+0xc73>
40002291:	c7 44 24 0c 8c 58 00 	movl   $0x4000588c,0xc(%esp)
40002298:	40 
40002299:	c7 44 24 08 7f 57 00 	movl   $0x4000577f,0x8(%esp)
400022a0:	40 
400022a1:	c7 44 24 04 3a 01 00 	movl   $0x13a,0x4(%esp)
400022a8:	00 
400022a9:	c7 04 24 88 56 00 40 	movl   $0x40005688,(%esp)
400022b0:	e8 23 09 00 00       	call   40002bd8 <debug_panic>
400022b5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400022bc:	00 
400022bd:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
400022c4:	e8 7b de ff ff       	call   40000144 <fork>
400022c9:	85 c0                	test   %eax,%eax
400022cb:	75 1f                	jne    400022ec <memopcheck+0xcaa>
400022cd:	8b 85 c8 fd ff ff    	mov    0xfffffdc8(%ebp),%eax
400022d3:	89 85 e0 fd ff ff    	mov    %eax,0xfffffde0(%ebp)
400022d9:	8b 85 e0 fd ff ff    	mov    0xfffffde0(%ebp),%eax
400022df:	c7 00 ef be ad de    	movl   $0xdeadbeef,(%eax)
400022e5:	b8 03 00 00 00       	mov    $0x3,%eax
400022ea:	cd 30                	int    $0x30
400022ec:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
400022f3:	00 
400022f4:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400022fb:	00 
400022fc:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40002303:	e8 1c df ff ff       	call   40000224 <join>
40002308:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000230f:	00 
40002310:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40002317:	e8 28 de ff ff       	call   40000144 <fork>
4000231c:	85 c0                	test   %eax,%eax
4000231e:	75 14                	jne    40002334 <memopcheck+0xcf2>
40002320:	8b 85 c8 fd ff ff    	mov    0xfffffdc8(%ebp),%eax
40002326:	05 fc ff 3f 00       	add    $0x3ffffc,%eax
4000232b:	8b 00                	mov    (%eax),%eax
4000232d:	b8 03 00 00 00       	mov    $0x3,%eax
40002332:	cd 30                	int    $0x30
40002334:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
4000233b:	00 
4000233c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40002343:	00 
40002344:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
4000234b:	e8 d4 de ff ff       	call   40000224 <join>
40002350:	c7 85 c0 fd ff ff 00 	movl   $0x40000000,0xfffffdc0(%ebp)
40002357:	00 00 40 
4000235a:	8b 85 c0 fd ff ff    	mov    0xfffffdc0(%ebp),%eax
40002360:	05 00 00 40 00       	add    $0x400000,%eax
40002365:	89 85 c4 fd ff ff    	mov    %eax,0xfffffdc4(%ebp)
4000236b:	8b 85 c4 fd ff ff    	mov    0xfffffdc4(%ebp),%eax
40002371:	05 00 00 40 00       	add    $0x400000,%eax
40002376:	89 85 c8 fd ff ff    	mov    %eax,0xfffffdc8(%ebp)
4000237c:	c7 85 cc fd ff ff 00 	movl   $0x3ff000,0xfffffdcc(%ebp)
40002383:	f0 3f 00 
40002386:	8b 85 cc fd ff ff    	mov    0xfffffdcc(%ebp),%eax
4000238c:	03 85 c0 fd ff ff    	add    0xfffffdc0(%ebp),%eax
40002392:	c7 45 90 00 07 00 00 	movl   $0x700,0xffffff90(%ebp)
40002399:	66 c7 45 8e 00 00    	movw   $0x0,0xffffff8e(%ebp)
4000239f:	c7 45 88 00 00 00 00 	movl   $0x0,0xffffff88(%ebp)
400023a6:	c7 45 84 00 00 00 00 	movl   $0x0,0xffffff84(%ebp)
400023ad:	89 45 80             	mov    %eax,0xffffff80(%ebp)
400023b0:	c7 85 7c ff ff ff 00 	movl   $0x1000,0xffffff7c(%ebp)
400023b7:	10 00 00 
400023ba:	8b 45 90             	mov    0xffffff90(%ebp),%eax
400023bd:	83 c8 02             	or     $0x2,%eax
400023c0:	8b 5d 88             	mov    0xffffff88(%ebp),%ebx
400023c3:	0f b7 55 8e          	movzwl 0xffffff8e(%ebp),%edx
400023c7:	8b 75 84             	mov    0xffffff84(%ebp),%esi
400023ca:	8b 7d 80             	mov    0xffffff80(%ebp),%edi
400023cd:	8b 8d 7c ff ff ff    	mov    0xffffff7c(%ebp),%ecx
400023d3:	cd 30                	int    $0x30
400023d5:	8b 85 cc fd ff ff    	mov    0xfffffdcc(%ebp),%eax
400023db:	03 85 c0 fd ff ff    	add    0xfffffdc0(%ebp),%eax
400023e1:	c7 00 ef be ad de    	movl   $0xdeadbeef,(%eax)
400023e7:	8b 85 cc fd ff ff    	mov    0xfffffdcc(%ebp),%eax
400023ed:	03 85 c0 fd ff ff    	add    0xfffffdc0(%ebp),%eax
400023f3:	c7 45 a8 00 01 00 00 	movl   $0x100,0xffffffa8(%ebp)
400023fa:	66 c7 45 a6 00 00    	movw   $0x0,0xffffffa6(%ebp)
40002400:	c7 45 a0 00 00 00 00 	movl   $0x0,0xffffffa0(%ebp)
40002407:	c7 45 9c 00 00 00 00 	movl   $0x0,0xffffff9c(%ebp)
4000240e:	89 45 98             	mov    %eax,0xffffff98(%ebp)
40002411:	c7 45 94 00 10 00 00 	movl   $0x1000,0xffffff94(%ebp)
40002418:	8b 45 a8             	mov    0xffffffa8(%ebp),%eax
4000241b:	83 c8 02             	or     $0x2,%eax
4000241e:	8b 5d a0             	mov    0xffffffa0(%ebp),%ebx
40002421:	0f b7 55 a6          	movzwl 0xffffffa6(%ebp),%edx
40002425:	8b 75 9c             	mov    0xffffff9c(%ebp),%esi
40002428:	8b 7d 98             	mov    0xffffff98(%ebp),%edi
4000242b:	8b 4d 94             	mov    0xffffff94(%ebp),%ecx
4000242e:	cd 30                	int    $0x30
40002430:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40002437:	00 
40002438:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
4000243f:	e8 00 dd ff ff       	call   40000144 <fork>
40002444:	85 c0                	test   %eax,%eax
40002446:	75 15                	jne    4000245d <memopcheck+0xe1b>
40002448:	8b 85 cc fd ff ff    	mov    0xfffffdcc(%ebp),%eax
4000244e:	03 85 c0 fd ff ff    	add    0xfffffdc0(%ebp),%eax
40002454:	8b 00                	mov    (%eax),%eax
40002456:	b8 03 00 00 00       	mov    $0x3,%eax
4000245b:	cd 30                	int    $0x30
4000245d:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40002464:	00 
40002465:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000246c:	00 
4000246d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40002474:	e8 ab dd ff ff       	call   40000224 <join>
40002479:	c7 45 c0 00 00 02 00 	movl   $0x20000,0xffffffc0(%ebp)
40002480:	66 c7 45 be 00 00    	movw   $0x0,0xffffffbe(%ebp)
40002486:	c7 45 b8 00 00 00 00 	movl   $0x0,0xffffffb8(%ebp)
4000248d:	8b 85 c0 fd ff ff    	mov    0xfffffdc0(%ebp),%eax
40002493:	89 45 b4             	mov    %eax,0xffffffb4(%ebp)
40002496:	8b 85 c4 fd ff ff    	mov    0xfffffdc4(%ebp),%eax
4000249c:	89 45 b0             	mov    %eax,0xffffffb0(%ebp)
4000249f:	c7 45 ac 00 00 40 00 	movl   $0x400000,0xffffffac(%ebp)
400024a6:	8b 45 c0             	mov    0xffffffc0(%ebp),%eax
400024a9:	83 c8 01             	or     $0x1,%eax
400024ac:	8b 5d b8             	mov    0xffffffb8(%ebp),%ebx
400024af:	0f b7 55 be          	movzwl 0xffffffbe(%ebp),%edx
400024b3:	8b 75 b4             	mov    0xffffffb4(%ebp),%esi
400024b6:	8b 7d b0             	mov    0xffffffb0(%ebp),%edi
400024b9:	8b 4d ac             	mov    0xffffffac(%ebp),%ecx
400024bc:	cd 30                	int    $0x30
400024be:	c7 45 d8 00 00 02 00 	movl   $0x20000,0xffffffd8(%ebp)
400024c5:	66 c7 45 d6 00 00    	movw   $0x0,0xffffffd6(%ebp)
400024cb:	c7 45 d0 00 00 00 00 	movl   $0x0,0xffffffd0(%ebp)
400024d2:	8b 85 c4 fd ff ff    	mov    0xfffffdc4(%ebp),%eax
400024d8:	89 45 cc             	mov    %eax,0xffffffcc(%ebp)
400024db:	8b 85 c8 fd ff ff    	mov    0xfffffdc8(%ebp),%eax
400024e1:	89 45 c8             	mov    %eax,0xffffffc8(%ebp)
400024e4:	c7 45 c4 00 00 40 00 	movl   $0x400000,0xffffffc4(%ebp)
400024eb:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
400024ee:	83 c8 02             	or     $0x2,%eax
400024f1:	8b 5d d0             	mov    0xffffffd0(%ebp),%ebx
400024f4:	0f b7 55 d6          	movzwl 0xffffffd6(%ebp),%edx
400024f8:	8b 75 cc             	mov    0xffffffcc(%ebp),%esi
400024fb:	8b 7d c8             	mov    0xffffffc8(%ebp),%edi
400024fe:	8b 4d c4             	mov    0xffffffc4(%ebp),%ecx
40002501:	cd 30                	int    $0x30
40002503:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000250a:	00 
4000250b:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40002512:	e8 2d dc ff ff       	call   40000144 <fork>
40002517:	85 c0                	test   %eax,%eax
40002519:	75 15                	jne    40002530 <memopcheck+0xeee>
4000251b:	8b 85 cc fd ff ff    	mov    0xfffffdcc(%ebp),%eax
40002521:	03 85 c8 fd ff ff    	add    0xfffffdc8(%ebp),%eax
40002527:	8b 00                	mov    (%eax),%eax
40002529:	b8 03 00 00 00       	mov    $0x3,%eax
4000252e:	cd 30                	int    $0x30
40002530:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40002537:	00 
40002538:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000253f:	00 
40002540:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40002547:	e8 d8 dc ff ff       	call   40000224 <join>
4000254c:	8b 85 cc fd ff ff    	mov    0xfffffdcc(%ebp),%eax
40002552:	03 85 c8 fd ff ff    	add    0xfffffdc8(%ebp),%eax
40002558:	c7 45 f0 00 03 00 00 	movl   $0x300,0xfffffff0(%ebp)
4000255f:	66 c7 45 ee 00 00    	movw   $0x0,0xffffffee(%ebp)
40002565:	c7 45 e8 00 00 00 00 	movl   $0x0,0xffffffe8(%ebp)
4000256c:	c7 45 e4 00 00 00 00 	movl   $0x0,0xffffffe4(%ebp)
40002573:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)
40002576:	c7 45 dc 00 10 00 00 	movl   $0x1000,0xffffffdc(%ebp)
4000257d:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
40002580:	83 c8 02             	or     $0x2,%eax
40002583:	8b 5d e8             	mov    0xffffffe8(%ebp),%ebx
40002586:	0f b7 55 ee          	movzwl 0xffffffee(%ebp),%edx
4000258a:	8b 75 e4             	mov    0xffffffe4(%ebp),%esi
4000258d:	8b 7d e0             	mov    0xffffffe0(%ebp),%edi
40002590:	8b 4d dc             	mov    0xffffffdc(%ebp),%ecx
40002593:	cd 30                	int    $0x30
40002595:	8b 85 cc fd ff ff    	mov    0xfffffdcc(%ebp),%eax
4000259b:	03 85 c8 fd ff ff    	add    0xfffffdc8(%ebp),%eax
400025a1:	8b 00                	mov    (%eax),%eax
400025a3:	3d ef be ad de       	cmp    $0xdeadbeef,%eax
400025a8:	74 24                	je     400025ce <memopcheck+0xf8c>
400025aa:	c7 44 24 0c b4 58 00 	movl   $0x400058b4,0xc(%esp)
400025b1:	40 
400025b2:	c7 44 24 08 7f 57 00 	movl   $0x4000577f,0x8(%esp)
400025b9:	40 
400025ba:	c7 44 24 04 49 01 00 	movl   $0x149,0x4(%esp)
400025c1:	00 
400025c2:	c7 04 24 88 56 00 40 	movl   $0x40005688,(%esp)
400025c9:	e8 0a 06 00 00       	call   40002bd8 <debug_panic>
400025ce:	c7 04 24 dd 58 00 40 	movl   $0x400058dd,(%esp)
400025d5:	e8 b7 08 00 00       	call   40002e91 <cprintf>
400025da:	81 c4 5c 02 00 00    	add    $0x25c,%esp
400025e0:	5b                   	pop    %ebx
400025e1:	5e                   	pop    %esi
400025e2:	5f                   	pop    %edi
400025e3:	5d                   	pop    %ebp
400025e4:	c3                   	ret    

400025e5 <pqsort>:
400025e5:	55                   	push   %ebp
400025e6:	89 e5                	mov    %esp,%ebp
400025e8:	83 ec 38             	sub    $0x38,%esp
400025eb:	8b 45 08             	mov    0x8(%ebp),%eax
400025ee:	3b 45 0c             	cmp    0xc(%ebp),%eax
400025f1:	0f 83 23 01 00 00    	jae    4000271a <pqsort+0x135>
400025f7:	8b 45 08             	mov    0x8(%ebp),%eax
400025fa:	8b 00                	mov    (%eax),%eax
400025fc:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
400025ff:	8b 45 08             	mov    0x8(%ebp),%eax
40002602:	83 c0 04             	add    $0x4,%eax
40002605:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
40002608:	8b 45 0c             	mov    0xc(%ebp),%eax
4000260b:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
4000260e:	eb 42                	jmp    40002652 <pqsort+0x6d>
40002610:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
40002613:	8b 00                	mov    (%eax),%eax
40002615:	3b 45 ec             	cmp    0xffffffec(%ebp),%eax
40002618:	7d 06                	jge    40002620 <pqsort+0x3b>
4000261a:	83 45 f0 04          	addl   $0x4,0xfffffff0(%ebp)
4000261e:	eb 32                	jmp    40002652 <pqsort+0x6d>
40002620:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
40002623:	8b 00                	mov    (%eax),%eax
40002625:	3b 45 ec             	cmp    0xffffffec(%ebp),%eax
40002628:	7e 06                	jle    40002630 <pqsort+0x4b>
4000262a:	83 6d f4 04          	subl   $0x4,0xfffffff4(%ebp)
4000262e:	eb 22                	jmp    40002652 <pqsort+0x6d>
40002630:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
40002633:	8b 00                	mov    (%eax),%eax
40002635:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
40002638:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
4000263b:	8b 10                	mov    (%eax),%edx
4000263d:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
40002640:	89 10                	mov    %edx,(%eax)
40002642:	8b 55 f0             	mov    0xfffffff0(%ebp),%edx
40002645:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
40002648:	89 02                	mov    %eax,(%edx)
4000264a:	83 45 f0 04          	addl   $0x4,0xfffffff0(%ebp)
4000264e:	83 6d f4 04          	subl   $0x4,0xfffffff4(%ebp)
40002652:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
40002655:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
40002658:	76 b6                	jbe    40002610 <pqsort+0x2b>
4000265a:	8b 45 08             	mov    0x8(%ebp),%eax
4000265d:	8b 00                	mov    (%eax),%eax
4000265f:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
40002662:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
40002665:	83 e8 04             	sub    $0x4,%eax
40002668:	8b 10                	mov    (%eax),%edx
4000266a:	8b 45 08             	mov    0x8(%ebp),%eax
4000266d:	89 10                	mov    %edx,(%eax)
4000266f:	8b 55 f0             	mov    0xfffffff0(%ebp),%edx
40002672:	83 ea 04             	sub    $0x4,%edx
40002675:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
40002678:	89 02                	mov    %eax,(%edx)
4000267a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40002681:	00 
40002682:	c7 04 24 10 00 04 00 	movl   $0x40010,(%esp)
40002689:	e8 b6 da ff ff       	call   40000144 <fork>
4000268e:	85 c0                	test   %eax,%eax
40002690:	75 1c                	jne    400026ae <pqsort+0xc9>
40002692:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
40002695:	83 e8 08             	sub    $0x8,%eax
40002698:	89 44 24 04          	mov    %eax,0x4(%esp)
4000269c:	8b 45 08             	mov    0x8(%ebp),%eax
4000269f:	89 04 24             	mov    %eax,(%esp)
400026a2:	e8 3e ff ff ff       	call   400025e5 <pqsort>
400026a7:	b8 03 00 00 00       	mov    $0x3,%eax
400026ac:	cd 30                	int    $0x30
400026ae:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
400026b5:	00 
400026b6:	c7 04 24 10 00 04 00 	movl   $0x40010,(%esp)
400026bd:	e8 82 da ff ff       	call   40000144 <fork>
400026c2:	85 c0                	test   %eax,%eax
400026c4:	75 1c                	jne    400026e2 <pqsort+0xfd>
400026c6:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
400026c9:	83 c2 04             	add    $0x4,%edx
400026cc:	8b 45 0c             	mov    0xc(%ebp),%eax
400026cf:	89 44 24 04          	mov    %eax,0x4(%esp)
400026d3:	89 14 24             	mov    %edx,(%esp)
400026d6:	e8 0a ff ff ff       	call   400025e5 <pqsort>
400026db:	b8 03 00 00 00       	mov    $0x3,%eax
400026e0:	cd 30                	int    $0x30
400026e2:	c7 44 24 08 30 00 00 	movl   $0x30,0x8(%esp)
400026e9:	00 
400026ea:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400026f1:	00 
400026f2:	c7 04 24 00 00 03 00 	movl   $0x30000,(%esp)
400026f9:	e8 26 db ff ff       	call   40000224 <join>
400026fe:	c7 44 24 08 30 00 00 	movl   $0x30,0x8(%esp)
40002705:	00 
40002706:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
4000270d:	00 
4000270e:	c7 04 24 00 00 03 00 	movl   $0x30000,(%esp)
40002715:	e8 0a db ff ff       	call   40000224 <join>
4000271a:	c9                   	leave  
4000271b:	c3                   	ret    

4000271c <matmult>:
4000271c:	55                   	push   %ebp
4000271d:	89 e5                	mov    %esp,%ebp
4000271f:	83 ec 38             	sub    $0x38,%esp
40002722:	c7 45 e8 00 00 00 00 	movl   $0x0,0xffffffe8(%ebp)
40002729:	e9 a1 00 00 00       	jmp    400027cf <matmult+0xb3>
4000272e:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
40002735:	e9 87 00 00 00       	jmp    400027c1 <matmult+0xa5>
4000273a:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
4000273d:	c1 e0 03             	shl    $0x3,%eax
40002740:	03 45 ec             	add    0xffffffec(%ebp),%eax
40002743:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
40002746:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
40002749:	0f b6 c0             	movzbl %al,%eax
4000274c:	89 44 24 04          	mov    %eax,0x4(%esp)
40002750:	c7 04 24 10 00 04 00 	movl   $0x40010,(%esp)
40002757:	e8 e8 d9 ff ff       	call   40000144 <fork>
4000275c:	85 c0                	test   %eax,%eax
4000275e:	75 5d                	jne    400027bd <matmult+0xa1>
40002760:	c7 45 f8 00 00 00 00 	movl   $0x0,0xfffffff8(%ebp)
40002767:	c7 45 f0 00 00 00 00 	movl   $0x0,0xfffffff0(%ebp)
4000276e:	eb 2c                	jmp    4000279c <matmult+0x80>
40002770:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
40002773:	c1 e0 05             	shl    $0x5,%eax
40002776:	89 c2                	mov    %eax,%edx
40002778:	03 55 08             	add    0x8(%ebp),%edx
4000277b:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
4000277e:	8b 0c 82             	mov    (%edx,%eax,4),%ecx
40002781:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
40002784:	c1 e0 05             	shl    $0x5,%eax
40002787:	89 c2                	mov    %eax,%edx
40002789:	03 55 0c             	add    0xc(%ebp),%edx
4000278c:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
4000278f:	8b 04 82             	mov    (%edx,%eax,4),%eax
40002792:	0f af c1             	imul   %ecx,%eax
40002795:	01 45 f8             	add    %eax,0xfffffff8(%ebp)
40002798:	83 45 f0 01          	addl   $0x1,0xfffffff0(%ebp)
4000279c:	83 7d f0 07          	cmpl   $0x7,0xfffffff0(%ebp)
400027a0:	7e ce                	jle    40002770 <matmult+0x54>
400027a2:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
400027a5:	c1 e0 05             	shl    $0x5,%eax
400027a8:	89 c1                	mov    %eax,%ecx
400027aa:	03 4d 10             	add    0x10(%ebp),%ecx
400027ad:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
400027b0:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
400027b3:	89 04 91             	mov    %eax,(%ecx,%edx,4)
400027b6:	b8 03 00 00 00       	mov    $0x3,%eax
400027bb:	cd 30                	int    $0x30
400027bd:	83 45 ec 01          	addl   $0x1,0xffffffec(%ebp)
400027c1:	83 7d ec 07          	cmpl   $0x7,0xffffffec(%ebp)
400027c5:	0f 8e 6f ff ff ff    	jle    4000273a <matmult+0x1e>
400027cb:	83 45 e8 01          	addl   $0x1,0xffffffe8(%ebp)
400027cf:	83 7d e8 07          	cmpl   $0x7,0xffffffe8(%ebp)
400027d3:	0f 8e 55 ff ff ff    	jle    4000272e <matmult+0x12>
400027d9:	c7 45 e8 00 00 00 00 	movl   $0x0,0xffffffe8(%ebp)
400027e0:	eb 41                	jmp    40002823 <matmult+0x107>
400027e2:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
400027e9:	eb 2e                	jmp    40002819 <matmult+0xfd>
400027eb:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
400027ee:	c1 e0 03             	shl    $0x3,%eax
400027f1:	03 45 ec             	add    0xffffffec(%ebp),%eax
400027f4:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
400027f7:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
400027fa:	0f b6 c0             	movzbl %al,%eax
400027fd:	c7 44 24 08 30 00 00 	movl   $0x30,0x8(%esp)
40002804:	00 
40002805:	89 44 24 04          	mov    %eax,0x4(%esp)
40002809:	c7 04 24 00 00 03 00 	movl   $0x30000,(%esp)
40002810:	e8 0f da ff ff       	call   40000224 <join>
40002815:	83 45 ec 01          	addl   $0x1,0xffffffec(%ebp)
40002819:	83 7d ec 07          	cmpl   $0x7,0xffffffec(%ebp)
4000281d:	7e cc                	jle    400027eb <matmult+0xcf>
4000281f:	83 45 e8 01          	addl   $0x1,0xffffffe8(%ebp)
40002823:	83 7d e8 07          	cmpl   $0x7,0xffffffe8(%ebp)
40002827:	7e b9                	jle    400027e2 <matmult+0xc6>
40002829:	c9                   	leave  
4000282a:	c3                   	ret    

4000282b <mergecheck>:
4000282b:	55                   	push   %ebp
4000282c:	89 e5                	mov    %esp,%ebp
4000282e:	83 ec 18             	sub    $0x18,%esp
40002831:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40002838:	00 
40002839:	c7 04 24 10 00 04 00 	movl   $0x40010,(%esp)
40002840:	e8 ff d8 ff ff       	call   40000144 <fork>
40002845:	85 c0                	test   %eax,%eax
40002847:	75 11                	jne    4000285a <mergecheck+0x2f>
40002849:	c7 05 00 7b 00 40 ef 	movl   $0xdeadbeef,0x40007b00
40002850:	be ad de 
40002853:	b8 03 00 00 00       	mov    $0x3,%eax
40002858:	cd 30                	int    $0x30
4000285a:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
40002861:	00 
40002862:	c7 04 24 10 00 04 00 	movl   $0x40010,(%esp)
40002869:	e8 d6 d8 ff ff       	call   40000144 <fork>
4000286e:	85 c0                	test   %eax,%eax
40002870:	75 11                	jne    40002883 <mergecheck+0x58>
40002872:	c7 05 20 9c 00 40 fe 	movl   $0xabadcafe,0x40009c20
40002879:	ca ad ab 
4000287c:	b8 03 00 00 00       	mov    $0x3,%eax
40002881:	cd 30                	int    $0x30
40002883:	a1 00 7b 00 40       	mov    0x40007b00,%eax
40002888:	85 c0                	test   %eax,%eax
4000288a:	74 24                	je     400028b0 <mergecheck+0x85>
4000288c:	c7 44 24 0c 00 5e 00 	movl   $0x40005e00,0xc(%esp)
40002893:	40 
40002894:	c7 44 24 08 7f 57 00 	movl   $0x4000577f,0x8(%esp)
4000289b:	40 
4000289c:	c7 44 24 04 d1 01 00 	movl   $0x1d1,0x4(%esp)
400028a3:	00 
400028a4:	c7 04 24 88 56 00 40 	movl   $0x40005688,(%esp)
400028ab:	e8 28 03 00 00       	call   40002bd8 <debug_panic>
400028b0:	a1 20 9c 00 40       	mov    0x40009c20,%eax
400028b5:	85 c0                	test   %eax,%eax
400028b7:	74 24                	je     400028dd <mergecheck+0xb2>
400028b9:	c7 44 24 0c 07 5e 00 	movl   $0x40005e07,0xc(%esp)
400028c0:	40 
400028c1:	c7 44 24 08 7f 57 00 	movl   $0x4000577f,0x8(%esp)
400028c8:	40 
400028c9:	c7 44 24 04 d1 01 00 	movl   $0x1d1,0x4(%esp)
400028d0:	00 
400028d1:	c7 04 24 88 56 00 40 	movl   $0x40005688,(%esp)
400028d8:	e8 fb 02 00 00       	call   40002bd8 <debug_panic>
400028dd:	c7 44 24 08 30 00 00 	movl   $0x30,0x8(%esp)
400028e4:	00 
400028e5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400028ec:	00 
400028ed:	c7 04 24 00 00 03 00 	movl   $0x30000,(%esp)
400028f4:	e8 2b d9 ff ff       	call   40000224 <join>
400028f9:	c7 44 24 08 30 00 00 	movl   $0x30,0x8(%esp)
40002900:	00 
40002901:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
40002908:	00 
40002909:	c7 04 24 00 00 03 00 	movl   $0x30000,(%esp)
40002910:	e8 0f d9 ff ff       	call   40000224 <join>
40002915:	a1 00 7b 00 40       	mov    0x40007b00,%eax
4000291a:	3d ef be ad de       	cmp    $0xdeadbeef,%eax
4000291f:	74 24                	je     40002945 <mergecheck+0x11a>
40002921:	c7 44 24 0c 0e 5e 00 	movl   $0x40005e0e,0xc(%esp)
40002928:	40 
40002929:	c7 44 24 08 7f 57 00 	movl   $0x4000577f,0x8(%esp)
40002930:	40 
40002931:	c7 44 24 04 d4 01 00 	movl   $0x1d4,0x4(%esp)
40002938:	00 
40002939:	c7 04 24 88 56 00 40 	movl   $0x40005688,(%esp)
40002940:	e8 93 02 00 00       	call   40002bd8 <debug_panic>
40002945:	a1 20 9c 00 40       	mov    0x40009c20,%eax
4000294a:	3d fe ca ad ab       	cmp    $0xabadcafe,%eax
4000294f:	74 24                	je     40002975 <mergecheck+0x14a>
40002951:	c7 44 24 0c 1e 5e 00 	movl   $0x40005e1e,0xc(%esp)
40002958:	40 
40002959:	c7 44 24 08 7f 57 00 	movl   $0x4000577f,0x8(%esp)
40002960:	40 
40002961:	c7 44 24 04 d4 01 00 	movl   $0x1d4,0x4(%esp)
40002968:	00 
40002969:	c7 04 24 88 56 00 40 	movl   $0x40005688,(%esp)
40002970:	e8 63 02 00 00       	call   40002bd8 <debug_panic>
40002975:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000297c:	00 
4000297d:	c7 04 24 10 00 04 00 	movl   $0x40010,(%esp)
40002984:	e8 bb d7 ff ff       	call   40000144 <fork>
40002989:	85 c0                	test   %eax,%eax
4000298b:	75 11                	jne    4000299e <mergecheck+0x173>
4000298d:	a1 20 9c 00 40       	mov    0x40009c20,%eax
40002992:	a3 00 7b 00 40       	mov    %eax,0x40007b00
40002997:	b8 03 00 00 00       	mov    $0x3,%eax
4000299c:	cd 30                	int    $0x30
4000299e:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
400029a5:	00 
400029a6:	c7 04 24 10 00 04 00 	movl   $0x40010,(%esp)
400029ad:	e8 92 d7 ff ff       	call   40000144 <fork>
400029b2:	85 c0                	test   %eax,%eax
400029b4:	75 11                	jne    400029c7 <mergecheck+0x19c>
400029b6:	a1 00 7b 00 40       	mov    0x40007b00,%eax
400029bb:	a3 20 9c 00 40       	mov    %eax,0x40009c20
400029c0:	b8 03 00 00 00       	mov    $0x3,%eax
400029c5:	cd 30                	int    $0x30
400029c7:	a1 00 7b 00 40       	mov    0x40007b00,%eax
400029cc:	3d ef be ad de       	cmp    $0xdeadbeef,%eax
400029d1:	74 24                	je     400029f7 <mergecheck+0x1cc>
400029d3:	c7 44 24 0c 0e 5e 00 	movl   $0x40005e0e,0xc(%esp)
400029da:	40 
400029db:	c7 44 24 08 7f 57 00 	movl   $0x4000577f,0x8(%esp)
400029e2:	40 
400029e3:	c7 44 24 04 d9 01 00 	movl   $0x1d9,0x4(%esp)
400029ea:	00 
400029eb:	c7 04 24 88 56 00 40 	movl   $0x40005688,(%esp)
400029f2:	e8 e1 01 00 00       	call   40002bd8 <debug_panic>
400029f7:	a1 20 9c 00 40       	mov    0x40009c20,%eax
400029fc:	3d fe ca ad ab       	cmp    $0xabadcafe,%eax
40002a01:	74 24                	je     40002a27 <mergecheck+0x1fc>
40002a03:	c7 44 24 0c 1e 5e 00 	movl   $0x40005e1e,0xc(%esp)
40002a0a:	40 
40002a0b:	c7 44 24 08 7f 57 00 	movl   $0x4000577f,0x8(%esp)
40002a12:	40 
40002a13:	c7 44 24 04 d9 01 00 	movl   $0x1d9,0x4(%esp)
40002a1a:	00 
40002a1b:	c7 04 24 88 56 00 40 	movl   $0x40005688,(%esp)
40002a22:	e8 b1 01 00 00       	call   40002bd8 <debug_panic>
40002a27:	c7 44 24 08 30 00 00 	movl   $0x30,0x8(%esp)
40002a2e:	00 
40002a2f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40002a36:	00 
40002a37:	c7 04 24 00 00 03 00 	movl   $0x30000,(%esp)
40002a3e:	e8 e1 d7 ff ff       	call   40000224 <join>
40002a43:	c7 44 24 08 30 00 00 	movl   $0x30,0x8(%esp)
40002a4a:	00 
40002a4b:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
40002a52:	00 
40002a53:	c7 04 24 00 00 03 00 	movl   $0x30000,(%esp)
40002a5a:	e8 c5 d7 ff ff       	call   40000224 <join>
40002a5f:	a1 20 9c 00 40       	mov    0x40009c20,%eax
40002a64:	3d ef be ad de       	cmp    $0xdeadbeef,%eax
40002a69:	74 24                	je     40002a8f <mergecheck+0x264>
40002a6b:	c7 44 24 0c 2e 5e 00 	movl   $0x40005e2e,0xc(%esp)
40002a72:	40 
40002a73:	c7 44 24 08 7f 57 00 	movl   $0x4000577f,0x8(%esp)
40002a7a:	40 
40002a7b:	c7 44 24 04 dc 01 00 	movl   $0x1dc,0x4(%esp)
40002a82:	00 
40002a83:	c7 04 24 88 56 00 40 	movl   $0x40005688,(%esp)
40002a8a:	e8 49 01 00 00       	call   40002bd8 <debug_panic>
40002a8f:	a1 00 7b 00 40       	mov    0x40007b00,%eax
40002a94:	3d fe ca ad ab       	cmp    $0xabadcafe,%eax
40002a99:	74 24                	je     40002abf <mergecheck+0x294>
40002a9b:	c7 44 24 0c 3e 5e 00 	movl   $0x40005e3e,0xc(%esp)
40002aa2:	40 
40002aa3:	c7 44 24 08 7f 57 00 	movl   $0x4000577f,0x8(%esp)
40002aaa:	40 
40002aab:	c7 44 24 04 dc 01 00 	movl   $0x1dc,0x4(%esp)
40002ab2:	00 
40002ab3:	c7 04 24 88 56 00 40 	movl   $0x40005688,(%esp)
40002aba:	e8 19 01 00 00       	call   40002bd8 <debug_panic>
40002abf:	b8 fc 78 00 40       	mov    $0x400078fc,%eax
40002ac4:	89 44 24 04          	mov    %eax,0x4(%esp)
40002ac8:	c7 04 24 00 75 00 40 	movl   $0x40007500,(%esp)
40002acf:	e8 11 fb ff ff       	call   400025e5 <pqsort>
40002ad4:	c7 44 24 08 00 04 00 	movl   $0x400,0x8(%esp)
40002adb:	00 
40002adc:	c7 44 24 04 00 59 00 	movl   $0x40005900,0x4(%esp)
40002ae3:	40 
40002ae4:	c7 04 24 00 75 00 40 	movl   $0x40007500,(%esp)
40002aeb:	e8 09 0e 00 00       	call   400038f9 <memcmp>
40002af0:	85 c0                	test   %eax,%eax
40002af2:	74 24                	je     40002b18 <mergecheck+0x2ed>
40002af4:	c7 44 24 0c 50 5e 00 	movl   $0x40005e50,0xc(%esp)
40002afb:	40 
40002afc:	c7 44 24 08 7f 57 00 	movl   $0x4000577f,0x8(%esp)
40002b03:	40 
40002b04:	c7 44 24 04 e1 01 00 	movl   $0x1e1,0x4(%esp)
40002b0b:	00 
40002b0c:	c7 04 24 88 56 00 40 	movl   $0x40005688,(%esp)
40002b13:	e8 c0 00 00 00       	call   40002bd8 <debug_panic>
40002b18:	c7 44 24 08 20 9b 00 	movl   $0x40009b20,0x8(%esp)
40002b1f:	40 
40002b20:	c7 44 24 04 00 7a 00 	movl   $0x40007a00,0x4(%esp)
40002b27:	40 
40002b28:	c7 04 24 00 79 00 40 	movl   $0x40007900,(%esp)
40002b2f:	e8 e8 fb ff ff       	call   4000271c <matmult>
40002b34:	c7 44 24 08 00 01 00 	movl   $0x100,0x8(%esp)
40002b3b:	00 
40002b3c:	c7 44 24 04 00 5d 00 	movl   $0x40005d00,0x4(%esp)
40002b43:	40 
40002b44:	c7 04 24 20 9b 00 40 	movl   $0x40009b20,(%esp)
40002b4b:	e8 a9 0d 00 00       	call   400038f9 <memcmp>
40002b50:	85 c0                	test   %eax,%eax
40002b52:	74 24                	je     40002b78 <mergecheck+0x34d>
40002b54:	c7 44 24 0c 84 5e 00 	movl   $0x40005e84,0xc(%esp)
40002b5b:	40 
40002b5c:	c7 44 24 08 7f 57 00 	movl   $0x4000577f,0x8(%esp)
40002b63:	40 
40002b64:	c7 44 24 04 e7 01 00 	movl   $0x1e7,0x4(%esp)
40002b6b:	00 
40002b6c:	c7 04 24 88 56 00 40 	movl   $0x40005688,(%esp)
40002b73:	e8 60 00 00 00       	call   40002bd8 <debug_panic>
40002b78:	c7 04 24 a4 5e 00 40 	movl   $0x40005ea4,(%esp)
40002b7f:	e8 0d 03 00 00       	call   40002e91 <cprintf>
40002b84:	c9                   	leave  
40002b85:	c3                   	ret    

40002b86 <main>:
40002b86:	8d 4c 24 04          	lea    0x4(%esp),%ecx
40002b8a:	83 e4 f0             	and    $0xfffffff0,%esp
40002b8d:	ff 71 fc             	pushl  0xfffffffc(%ecx)
40002b90:	55                   	push   %ebp
40002b91:	89 e5                	mov    %esp,%ebp
40002b93:	51                   	push   %ecx
40002b94:	83 ec 04             	sub    $0x4,%esp
40002b97:	c7 04 24 bf 5e 00 40 	movl   $0x40005ebf,(%esp)
40002b9e:	e8 ee 02 00 00       	call   40002e91 <cprintf>
40002ba3:	e8 23 d8 ff ff       	call   400003cb <loadcheck>
40002ba8:	e8 a0 d8 ff ff       	call   4000044d <forkcheck>
40002bad:	e8 ff db ff ff       	call   400007b1 <protcheck>
40002bb2:	e8 8b ea ff ff       	call   40001642 <memopcheck>
40002bb7:	e8 6f fc ff ff       	call   4000282b <mergecheck>
40002bbc:	c7 04 24 d4 5e 00 40 	movl   $0x40005ed4,(%esp)
40002bc3:	e8 c9 02 00 00       	call   40002e91 <cprintf>
40002bc8:	b8 00 00 00 00       	mov    $0x0,%eax
40002bcd:	83 c4 04             	add    $0x4,%esp
40002bd0:	59                   	pop    %ecx
40002bd1:	5d                   	pop    %ebp
40002bd2:	8d 61 fc             	lea    0xfffffffc(%ecx),%esp
40002bd5:	c3                   	ret    
40002bd6:	90                   	nop    
40002bd7:	90                   	nop    

40002bd8 <debug_panic>:
40002bd8:	55                   	push   %ebp
40002bd9:	89 e5                	mov    %esp,%ebp
40002bdb:	83 ec 28             	sub    $0x28,%esp
40002bde:	8d 45 10             	lea    0x10(%ebp),%eax
40002be1:	83 c0 04             	add    $0x4,%eax
40002be4:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
40002be7:	a1 24 9c 00 40       	mov    0x40009c24,%eax
40002bec:	85 c0                	test   %eax,%eax
40002bee:	74 15                	je     40002c05 <debug_panic+0x2d>
40002bf0:	a1 24 9c 00 40       	mov    0x40009c24,%eax
40002bf5:	89 44 24 04          	mov    %eax,0x4(%esp)
40002bf9:	c7 04 24 00 5f 00 40 	movl   $0x40005f00,(%esp)
40002c00:	e8 8c 02 00 00       	call   40002e91 <cprintf>
40002c05:	8b 45 0c             	mov    0xc(%ebp),%eax
40002c08:	89 44 24 08          	mov    %eax,0x8(%esp)
40002c0c:	8b 45 08             	mov    0x8(%ebp),%eax
40002c0f:	89 44 24 04          	mov    %eax,0x4(%esp)
40002c13:	c7 04 24 05 5f 00 40 	movl   $0x40005f05,(%esp)
40002c1a:	e8 72 02 00 00       	call   40002e91 <cprintf>
40002c1f:	8b 55 10             	mov    0x10(%ebp),%edx
40002c22:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
40002c25:	89 44 24 04          	mov    %eax,0x4(%esp)
40002c29:	89 14 24             	mov    %edx,(%esp)
40002c2c:	e8 f7 01 00 00       	call   40002e28 <vcprintf>
40002c31:	c7 04 24 1b 5f 00 40 	movl   $0x40005f1b,(%esp)
40002c38:	e8 54 02 00 00       	call   40002e91 <cprintf>
40002c3d:	e8 97 0d 00 00       	call   400039d9 <abort>

40002c42 <debug_warn>:
40002c42:	55                   	push   %ebp
40002c43:	89 e5                	mov    %esp,%ebp
40002c45:	83 ec 28             	sub    $0x28,%esp
40002c48:	8d 45 10             	lea    0x10(%ebp),%eax
40002c4b:	83 c0 04             	add    $0x4,%eax
40002c4e:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
40002c51:	8b 45 0c             	mov    0xc(%ebp),%eax
40002c54:	89 44 24 08          	mov    %eax,0x8(%esp)
40002c58:	8b 45 08             	mov    0x8(%ebp),%eax
40002c5b:	89 44 24 04          	mov    %eax,0x4(%esp)
40002c5f:	c7 04 24 1d 5f 00 40 	movl   $0x40005f1d,(%esp)
40002c66:	e8 26 02 00 00       	call   40002e91 <cprintf>
40002c6b:	8b 55 10             	mov    0x10(%ebp),%edx
40002c6e:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
40002c71:	89 44 24 04          	mov    %eax,0x4(%esp)
40002c75:	89 14 24             	mov    %edx,(%esp)
40002c78:	e8 ab 01 00 00       	call   40002e28 <vcprintf>
40002c7d:	c7 04 24 1b 5f 00 40 	movl   $0x40005f1b,(%esp)
40002c84:	e8 08 02 00 00       	call   40002e91 <cprintf>
40002c89:	c9                   	leave  
40002c8a:	c3                   	ret    

40002c8b <debug_dump>:
40002c8b:	55                   	push   %ebp
40002c8c:	89 e5                	mov    %esp,%ebp
40002c8e:	56                   	push   %esi
40002c8f:	53                   	push   %ebx
40002c90:	81 ec b0 00 00 00    	sub    $0xb0,%esp
40002c96:	8b 45 14             	mov    0x14(%ebp),%eax
40002c99:	03 45 10             	add    0x10(%ebp),%eax
40002c9c:	89 44 24 10          	mov    %eax,0x10(%esp)
40002ca0:	8b 45 10             	mov    0x10(%ebp),%eax
40002ca3:	89 44 24 0c          	mov    %eax,0xc(%esp)
40002ca7:	8b 45 0c             	mov    0xc(%ebp),%eax
40002caa:	89 44 24 08          	mov    %eax,0x8(%esp)
40002cae:	8b 45 08             	mov    0x8(%ebp),%eax
40002cb1:	89 44 24 04          	mov    %eax,0x4(%esp)
40002cb5:	c7 04 24 38 5f 00 40 	movl   $0x40005f38,(%esp)
40002cbc:	e8 d0 01 00 00       	call   40002e91 <cprintf>
40002cc1:	8b 45 14             	mov    0x14(%ebp),%eax
40002cc4:	83 c0 0f             	add    $0xf,%eax
40002cc7:	83 e0 f0             	and    $0xfffffff0,%eax
40002cca:	89 45 14             	mov    %eax,0x14(%ebp)
40002ccd:	e9 df 00 00 00       	jmp    40002db1 <debug_dump+0x126>
40002cd2:	8b 45 10             	mov    0x10(%ebp),%eax
40002cd5:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
40002cd8:	c7 45 e8 00 00 00 00 	movl   $0x0,0xffffffe8(%ebp)
40002cdf:	eb 71                	jmp    40002d52 <debug_dump+0xc7>
40002ce1:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
40002ce4:	89 85 6c ff ff ff    	mov    %eax,0xffffff6c(%ebp)
40002cea:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
40002ced:	03 45 ec             	add    0xffffffec(%ebp),%eax
40002cf0:	0f b6 00             	movzbl (%eax),%eax
40002cf3:	0f b6 c0             	movzbl %al,%eax
40002cf6:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
40002cf9:	83 7d f4 1f          	cmpl   $0x1f,0xfffffff4(%ebp)
40002cfd:	7e 12                	jle    40002d11 <debug_dump+0x86>
40002cff:	83 7d f4 7e          	cmpl   $0x7e,0xfffffff4(%ebp)
40002d03:	7f 0c                	jg     40002d11 <debug_dump+0x86>
40002d05:	c7 85 74 ff ff ff 01 	movl   $0x1,0xffffff74(%ebp)
40002d0c:	00 00 00 
40002d0f:	eb 0a                	jmp    40002d1b <debug_dump+0x90>
40002d11:	c7 85 74 ff ff ff 00 	movl   $0x0,0xffffff74(%ebp)
40002d18:	00 00 00 
40002d1b:	8b 85 74 ff ff ff    	mov    0xffffff74(%ebp),%eax
40002d21:	85 c0                	test   %eax,%eax
40002d23:	74 11                	je     40002d36 <debug_dump+0xab>
40002d25:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
40002d28:	03 45 ec             	add    0xffffffec(%ebp),%eax
40002d2b:	0f b6 00             	movzbl (%eax),%eax
40002d2e:	88 85 73 ff ff ff    	mov    %al,0xffffff73(%ebp)
40002d34:	eb 07                	jmp    40002d3d <debug_dump+0xb2>
40002d36:	c6 85 73 ff ff ff 2e 	movb   $0x2e,0xffffff73(%ebp)
40002d3d:	0f b6 95 73 ff ff ff 	movzbl 0xffffff73(%ebp),%edx
40002d44:	8b 85 6c ff ff ff    	mov    0xffffff6c(%ebp),%eax
40002d4a:	88 54 05 84          	mov    %dl,0xffffff84(%ebp,%eax,1)
40002d4e:	83 45 e8 01          	addl   $0x1,0xffffffe8(%ebp)
40002d52:	83 7d e8 0f          	cmpl   $0xf,0xffffffe8(%ebp)
40002d56:	7e 89                	jle    40002ce1 <debug_dump+0x56>
40002d58:	c6 45 94 00          	movb   $0x0,0xffffff94(%ebp)
40002d5c:	8b 45 10             	mov    0x10(%ebp),%eax
40002d5f:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
40002d62:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
40002d65:	83 c0 0c             	add    $0xc,%eax
40002d68:	8b 10                	mov    (%eax),%edx
40002d6a:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
40002d6d:	83 c0 08             	add    $0x8,%eax
40002d70:	8b 08                	mov    (%eax),%ecx
40002d72:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
40002d75:	83 c0 04             	add    $0x4,%eax
40002d78:	8b 18                	mov    (%eax),%ebx
40002d7a:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
40002d7d:	8b 30                	mov    (%eax),%esi
40002d7f:	8d 45 84             	lea    0xffffff84(%ebp),%eax
40002d82:	89 44 24 18          	mov    %eax,0x18(%esp)
40002d86:	89 54 24 14          	mov    %edx,0x14(%esp)
40002d8a:	89 4c 24 10          	mov    %ecx,0x10(%esp)
40002d8e:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
40002d92:	89 74 24 08          	mov    %esi,0x8(%esp)
40002d96:	8b 45 10             	mov    0x10(%ebp),%eax
40002d99:	89 44 24 04          	mov    %eax,0x4(%esp)
40002d9d:	c7 04 24 61 5f 00 40 	movl   $0x40005f61,(%esp)
40002da4:	e8 e8 00 00 00       	call   40002e91 <cprintf>
40002da9:	83 6d 14 10          	subl   $0x10,0x14(%ebp)
40002dad:	83 45 10 10          	addl   $0x10,0x10(%ebp)
40002db1:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
40002db5:	0f 8f 17 ff ff ff    	jg     40002cd2 <debug_dump+0x47>
40002dbb:	81 c4 b0 00 00 00    	add    $0xb0,%esp
40002dc1:	5b                   	pop    %ebx
40002dc2:	5e                   	pop    %esi
40002dc3:	5d                   	pop    %ebp
40002dc4:	c3                   	ret    
40002dc5:	90                   	nop    
40002dc6:	90                   	nop    
40002dc7:	90                   	nop    

40002dc8 <putch>:


static void
putch(int ch, struct printbuf *b)
{
40002dc8:	55                   	push   %ebp
40002dc9:	89 e5                	mov    %esp,%ebp
40002dcb:	83 ec 08             	sub    $0x8,%esp
	b->buf[b->idx++] = ch;
40002dce:	8b 45 0c             	mov    0xc(%ebp),%eax
40002dd1:	8b 08                	mov    (%eax),%ecx
40002dd3:	8b 45 08             	mov    0x8(%ebp),%eax
40002dd6:	89 c2                	mov    %eax,%edx
40002dd8:	8b 45 0c             	mov    0xc(%ebp),%eax
40002ddb:	88 54 08 08          	mov    %dl,0x8(%eax,%ecx,1)
40002ddf:	8d 51 01             	lea    0x1(%ecx),%edx
40002de2:	8b 45 0c             	mov    0xc(%ebp),%eax
40002de5:	89 10                	mov    %edx,(%eax)
	if (b->idx == CPUTS_MAX-1) {
40002de7:	8b 45 0c             	mov    0xc(%ebp),%eax
40002dea:	8b 00                	mov    (%eax),%eax
40002dec:	3d ff 00 00 00       	cmp    $0xff,%eax
40002df1:	75 24                	jne    40002e17 <putch+0x4f>
		b->buf[b->idx] = 0;
40002df3:	8b 45 0c             	mov    0xc(%ebp),%eax
40002df6:	8b 10                	mov    (%eax),%edx
40002df8:	8b 45 0c             	mov    0xc(%ebp),%eax
40002dfb:	c6 44 10 08 00       	movb   $0x0,0x8(%eax,%edx,1)
		cputs(b->buf);
40002e00:	8b 45 0c             	mov    0xc(%ebp),%eax
40002e03:	83 c0 08             	add    $0x8,%eax
40002e06:	89 04 24             	mov    %eax,(%esp)
40002e09:	e8 de 0b 00 00       	call   400039ec <cputs>
		b->idx = 0;
40002e0e:	8b 45 0c             	mov    0xc(%ebp),%eax
40002e11:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	}
	b->cnt++;
40002e17:	8b 45 0c             	mov    0xc(%ebp),%eax
40002e1a:	8b 40 04             	mov    0x4(%eax),%eax
40002e1d:	8d 50 01             	lea    0x1(%eax),%edx
40002e20:	8b 45 0c             	mov    0xc(%ebp),%eax
40002e23:	89 50 04             	mov    %edx,0x4(%eax)
}
40002e26:	c9                   	leave  
40002e27:	c3                   	ret    

40002e28 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
40002e28:	55                   	push   %ebp
40002e29:	89 e5                	mov    %esp,%ebp
40002e2b:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
40002e31:	c7 85 f8 fe ff ff 00 	movl   $0x0,0xfffffef8(%ebp)
40002e38:	00 00 00 
	b.cnt = 0;
40002e3b:	c7 85 fc fe ff ff 00 	movl   $0x0,0xfffffefc(%ebp)
40002e42:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
40002e45:	ba c8 2d 00 40       	mov    $0x40002dc8,%edx
40002e4a:	8b 45 0c             	mov    0xc(%ebp),%eax
40002e4d:	89 44 24 0c          	mov    %eax,0xc(%esp)
40002e51:	8b 45 08             	mov    0x8(%ebp),%eax
40002e54:	89 44 24 08          	mov    %eax,0x8(%esp)
40002e58:	8d 85 f8 fe ff ff    	lea    0xfffffef8(%ebp),%eax
40002e5e:	89 44 24 04          	mov    %eax,0x4(%esp)
40002e62:	89 14 24             	mov    %edx,(%esp)
40002e65:	e8 b4 03 00 00       	call   4000321e <vprintfmt>

	b.buf[b.idx] = 0;
40002e6a:	8b 85 f8 fe ff ff    	mov    0xfffffef8(%ebp),%eax
40002e70:	c6 84 05 00 ff ff ff 	movb   $0x0,0xffffff00(%ebp,%eax,1)
40002e77:	00 
	cputs(b.buf);
40002e78:	8d 85 f8 fe ff ff    	lea    0xfffffef8(%ebp),%eax
40002e7e:	83 c0 08             	add    $0x8,%eax
40002e81:	89 04 24             	mov    %eax,(%esp)
40002e84:	e8 63 0b 00 00       	call   400039ec <cputs>

	return b.cnt;
40002e89:	8b 85 fc fe ff ff    	mov    0xfffffefc(%ebp),%eax
}
40002e8f:	c9                   	leave  
40002e90:	c3                   	ret    

40002e91 <cprintf>:

int
cprintf(const char *fmt, ...)
{
40002e91:	55                   	push   %ebp
40002e92:	89 e5                	mov    %esp,%ebp
40002e94:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
40002e97:	8d 45 08             	lea    0x8(%ebp),%eax
40002e9a:	83 c0 04             	add    $0x4,%eax
40002e9d:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
	cnt = vcprintf(fmt, ap);
40002ea0:	8b 55 08             	mov    0x8(%ebp),%edx
40002ea3:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
40002ea6:	89 44 24 04          	mov    %eax,0x4(%esp)
40002eaa:	89 14 24             	mov    %edx,(%esp)
40002ead:	e8 76 ff ff ff       	call   40002e28 <vcprintf>
40002eb2:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
	va_end(ap);

	return cnt;
40002eb5:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
}
40002eb8:	c9                   	leave  
40002eb9:	c3                   	ret    
40002eba:	90                   	nop    
40002ebb:	90                   	nop    

40002ebc <getuint>:
40002ebc:	55                   	push   %ebp
40002ebd:	89 e5                	mov    %esp,%ebp
40002ebf:	83 ec 08             	sub    $0x8,%esp
40002ec2:	8b 45 08             	mov    0x8(%ebp),%eax
40002ec5:	8b 40 18             	mov    0x18(%eax),%eax
40002ec8:	83 e0 02             	and    $0x2,%eax
40002ecb:	85 c0                	test   %eax,%eax
40002ecd:	74 22                	je     40002ef1 <getuint+0x35>
40002ecf:	8b 45 0c             	mov    0xc(%ebp),%eax
40002ed2:	8b 00                	mov    (%eax),%eax
40002ed4:	8d 50 08             	lea    0x8(%eax),%edx
40002ed7:	8b 45 0c             	mov    0xc(%ebp),%eax
40002eda:	89 10                	mov    %edx,(%eax)
40002edc:	8b 45 0c             	mov    0xc(%ebp),%eax
40002edf:	8b 00                	mov    (%eax),%eax
40002ee1:	83 e8 08             	sub    $0x8,%eax
40002ee4:	8b 10                	mov    (%eax),%edx
40002ee6:	8b 48 04             	mov    0x4(%eax),%ecx
40002ee9:	89 55 f8             	mov    %edx,0xfffffff8(%ebp)
40002eec:	89 4d fc             	mov    %ecx,0xfffffffc(%ebp)
40002eef:	eb 51                	jmp    40002f42 <getuint+0x86>
40002ef1:	8b 45 08             	mov    0x8(%ebp),%eax
40002ef4:	8b 40 18             	mov    0x18(%eax),%eax
40002ef7:	83 e0 01             	and    $0x1,%eax
40002efa:	84 c0                	test   %al,%al
40002efc:	74 23                	je     40002f21 <getuint+0x65>
40002efe:	8b 45 0c             	mov    0xc(%ebp),%eax
40002f01:	8b 00                	mov    (%eax),%eax
40002f03:	8d 50 04             	lea    0x4(%eax),%edx
40002f06:	8b 45 0c             	mov    0xc(%ebp),%eax
40002f09:	89 10                	mov    %edx,(%eax)
40002f0b:	8b 45 0c             	mov    0xc(%ebp),%eax
40002f0e:	8b 00                	mov    (%eax),%eax
40002f10:	83 e8 04             	sub    $0x4,%eax
40002f13:	8b 00                	mov    (%eax),%eax
40002f15:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
40002f18:	c7 45 fc 00 00 00 00 	movl   $0x0,0xfffffffc(%ebp)
40002f1f:	eb 21                	jmp    40002f42 <getuint+0x86>
40002f21:	8b 45 0c             	mov    0xc(%ebp),%eax
40002f24:	8b 00                	mov    (%eax),%eax
40002f26:	8d 50 04             	lea    0x4(%eax),%edx
40002f29:	8b 45 0c             	mov    0xc(%ebp),%eax
40002f2c:	89 10                	mov    %edx,(%eax)
40002f2e:	8b 45 0c             	mov    0xc(%ebp),%eax
40002f31:	8b 00                	mov    (%eax),%eax
40002f33:	83 e8 04             	sub    $0x4,%eax
40002f36:	8b 00                	mov    (%eax),%eax
40002f38:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
40002f3b:	c7 45 fc 00 00 00 00 	movl   $0x0,0xfffffffc(%ebp)
40002f42:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
40002f45:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
40002f48:	c9                   	leave  
40002f49:	c3                   	ret    

40002f4a <getint>:
40002f4a:	55                   	push   %ebp
40002f4b:	89 e5                	mov    %esp,%ebp
40002f4d:	83 ec 08             	sub    $0x8,%esp
40002f50:	8b 45 08             	mov    0x8(%ebp),%eax
40002f53:	8b 40 18             	mov    0x18(%eax),%eax
40002f56:	83 e0 02             	and    $0x2,%eax
40002f59:	85 c0                	test   %eax,%eax
40002f5b:	74 22                	je     40002f7f <getint+0x35>
40002f5d:	8b 45 0c             	mov    0xc(%ebp),%eax
40002f60:	8b 00                	mov    (%eax),%eax
40002f62:	8d 50 08             	lea    0x8(%eax),%edx
40002f65:	8b 45 0c             	mov    0xc(%ebp),%eax
40002f68:	89 10                	mov    %edx,(%eax)
40002f6a:	8b 45 0c             	mov    0xc(%ebp),%eax
40002f6d:	8b 00                	mov    (%eax),%eax
40002f6f:	83 e8 08             	sub    $0x8,%eax
40002f72:	8b 10                	mov    (%eax),%edx
40002f74:	8b 48 04             	mov    0x4(%eax),%ecx
40002f77:	89 55 f8             	mov    %edx,0xfffffff8(%ebp)
40002f7a:	89 4d fc             	mov    %ecx,0xfffffffc(%ebp)
40002f7d:	eb 53                	jmp    40002fd2 <getint+0x88>
40002f7f:	8b 45 08             	mov    0x8(%ebp),%eax
40002f82:	8b 40 18             	mov    0x18(%eax),%eax
40002f85:	83 e0 01             	and    $0x1,%eax
40002f88:	84 c0                	test   %al,%al
40002f8a:	74 24                	je     40002fb0 <getint+0x66>
40002f8c:	8b 45 0c             	mov    0xc(%ebp),%eax
40002f8f:	8b 00                	mov    (%eax),%eax
40002f91:	8d 50 04             	lea    0x4(%eax),%edx
40002f94:	8b 45 0c             	mov    0xc(%ebp),%eax
40002f97:	89 10                	mov    %edx,(%eax)
40002f99:	8b 45 0c             	mov    0xc(%ebp),%eax
40002f9c:	8b 00                	mov    (%eax),%eax
40002f9e:	83 e8 04             	sub    $0x4,%eax
40002fa1:	8b 00                	mov    (%eax),%eax
40002fa3:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
40002fa6:	89 c1                	mov    %eax,%ecx
40002fa8:	c1 f9 1f             	sar    $0x1f,%ecx
40002fab:	89 4d fc             	mov    %ecx,0xfffffffc(%ebp)
40002fae:	eb 22                	jmp    40002fd2 <getint+0x88>
40002fb0:	8b 45 0c             	mov    0xc(%ebp),%eax
40002fb3:	8b 00                	mov    (%eax),%eax
40002fb5:	8d 50 04             	lea    0x4(%eax),%edx
40002fb8:	8b 45 0c             	mov    0xc(%ebp),%eax
40002fbb:	89 10                	mov    %edx,(%eax)
40002fbd:	8b 45 0c             	mov    0xc(%ebp),%eax
40002fc0:	8b 00                	mov    (%eax),%eax
40002fc2:	83 e8 04             	sub    $0x4,%eax
40002fc5:	8b 00                	mov    (%eax),%eax
40002fc7:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
40002fca:	89 c2                	mov    %eax,%edx
40002fcc:	c1 fa 1f             	sar    $0x1f,%edx
40002fcf:	89 55 fc             	mov    %edx,0xfffffffc(%ebp)
40002fd2:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
40002fd5:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
40002fd8:	c9                   	leave  
40002fd9:	c3                   	ret    

40002fda <putpad>:
40002fda:	55                   	push   %ebp
40002fdb:	89 e5                	mov    %esp,%ebp
40002fdd:	83 ec 08             	sub    $0x8,%esp
40002fe0:	eb 1a                	jmp    40002ffc <putpad+0x22>
40002fe2:	8b 45 08             	mov    0x8(%ebp),%eax
40002fe5:	8b 08                	mov    (%eax),%ecx
40002fe7:	8b 45 08             	mov    0x8(%ebp),%eax
40002fea:	8b 50 04             	mov    0x4(%eax),%edx
40002fed:	8b 45 08             	mov    0x8(%ebp),%eax
40002ff0:	8b 40 08             	mov    0x8(%eax),%eax
40002ff3:	89 54 24 04          	mov    %edx,0x4(%esp)
40002ff7:	89 04 24             	mov    %eax,(%esp)
40002ffa:	ff d1                	call   *%ecx
40002ffc:	8b 45 08             	mov    0x8(%ebp),%eax
40002fff:	8b 40 0c             	mov    0xc(%eax),%eax
40003002:	8d 50 ff             	lea    0xffffffff(%eax),%edx
40003005:	8b 45 08             	mov    0x8(%ebp),%eax
40003008:	89 50 0c             	mov    %edx,0xc(%eax)
4000300b:	8b 45 08             	mov    0x8(%ebp),%eax
4000300e:	8b 40 0c             	mov    0xc(%eax),%eax
40003011:	85 c0                	test   %eax,%eax
40003013:	79 cd                	jns    40002fe2 <putpad+0x8>
40003015:	c9                   	leave  
40003016:	c3                   	ret    

40003017 <putstr>:
40003017:	55                   	push   %ebp
40003018:	89 e5                	mov    %esp,%ebp
4000301a:	53                   	push   %ebx
4000301b:	83 ec 24             	sub    $0x24,%esp
4000301e:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
40003022:	79 18                	jns    4000303c <putstr+0x25>
40003024:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000302b:	00 
4000302c:	8b 45 0c             	mov    0xc(%ebp),%eax
4000302f:	89 04 24             	mov    %eax,(%esp)
40003032:	e8 22 07 00 00       	call   40003759 <strchr>
40003037:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
4000303a:	eb 2c                	jmp    40003068 <putstr+0x51>
4000303c:	8b 45 10             	mov    0x10(%ebp),%eax
4000303f:	89 44 24 08          	mov    %eax,0x8(%esp)
40003043:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000304a:	00 
4000304b:	8b 45 0c             	mov    0xc(%ebp),%eax
4000304e:	89 04 24             	mov    %eax,(%esp)
40003051:	e8 00 09 00 00       	call   40003956 <memchr>
40003056:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
40003059:	83 7d f4 00          	cmpl   $0x0,0xfffffff4(%ebp)
4000305d:	75 09                	jne    40003068 <putstr+0x51>
4000305f:	8b 45 10             	mov    0x10(%ebp),%eax
40003062:	03 45 0c             	add    0xc(%ebp),%eax
40003065:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
40003068:	8b 45 08             	mov    0x8(%ebp),%eax
4000306b:	8b 48 0c             	mov    0xc(%eax),%ecx
4000306e:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
40003071:	8b 45 0c             	mov    0xc(%ebp),%eax
40003074:	89 d3                	mov    %edx,%ebx
40003076:	29 c3                	sub    %eax,%ebx
40003078:	89 d8                	mov    %ebx,%eax
4000307a:	89 ca                	mov    %ecx,%edx
4000307c:	29 c2                	sub    %eax,%edx
4000307e:	8b 45 08             	mov    0x8(%ebp),%eax
40003081:	89 50 0c             	mov    %edx,0xc(%eax)
40003084:	8b 45 08             	mov    0x8(%ebp),%eax
40003087:	8b 40 18             	mov    0x18(%eax),%eax
4000308a:	83 e0 10             	and    $0x10,%eax
4000308d:	85 c0                	test   %eax,%eax
4000308f:	75 32                	jne    400030c3 <putstr+0xac>
40003091:	8b 45 08             	mov    0x8(%ebp),%eax
40003094:	89 04 24             	mov    %eax,(%esp)
40003097:	e8 3e ff ff ff       	call   40002fda <putpad>
4000309c:	eb 25                	jmp    400030c3 <putstr+0xac>
4000309e:	8b 45 0c             	mov    0xc(%ebp),%eax
400030a1:	0f b6 00             	movzbl (%eax),%eax
400030a4:	88 45 fb             	mov    %al,0xfffffffb(%ebp)
400030a7:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
400030ab:	8b 45 08             	mov    0x8(%ebp),%eax
400030ae:	8b 08                	mov    (%eax),%ecx
400030b0:	8b 45 08             	mov    0x8(%ebp),%eax
400030b3:	8b 40 04             	mov    0x4(%eax),%eax
400030b6:	0f be 55 fb          	movsbl 0xfffffffb(%ebp),%edx
400030ba:	89 44 24 04          	mov    %eax,0x4(%esp)
400030be:	89 14 24             	mov    %edx,(%esp)
400030c1:	ff d1                	call   *%ecx
400030c3:	8b 45 0c             	mov    0xc(%ebp),%eax
400030c6:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
400030c9:	72 d3                	jb     4000309e <putstr+0x87>
400030cb:	8b 45 08             	mov    0x8(%ebp),%eax
400030ce:	89 04 24             	mov    %eax,(%esp)
400030d1:	e8 04 ff ff ff       	call   40002fda <putpad>
400030d6:	83 c4 24             	add    $0x24,%esp
400030d9:	5b                   	pop    %ebx
400030da:	5d                   	pop    %ebp
400030db:	c3                   	ret    

400030dc <genint>:
400030dc:	55                   	push   %ebp
400030dd:	89 e5                	mov    %esp,%ebp
400030df:	53                   	push   %ebx
400030e0:	83 ec 24             	sub    $0x24,%esp
400030e3:	8b 45 10             	mov    0x10(%ebp),%eax
400030e6:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
400030e9:	8b 45 14             	mov    0x14(%ebp),%eax
400030ec:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
400030ef:	8b 45 08             	mov    0x8(%ebp),%eax
400030f2:	8b 40 1c             	mov    0x1c(%eax),%eax
400030f5:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
400030f8:	89 c2                	mov    %eax,%edx
400030fa:	c1 fa 1f             	sar    $0x1f,%edx
400030fd:	89 55 ec             	mov    %edx,0xffffffec(%ebp)
40003100:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
40003103:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
40003106:	77 54                	ja     4000315c <genint+0x80>
40003108:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
4000310b:	3b 55 f4             	cmp    0xfffffff4(%ebp),%edx
4000310e:	72 08                	jb     40003118 <genint+0x3c>
40003110:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
40003113:	3b 45 f0             	cmp    0xfffffff0(%ebp),%eax
40003116:	77 44                	ja     4000315c <genint+0x80>
40003118:	8b 45 08             	mov    0x8(%ebp),%eax
4000311b:	8b 40 1c             	mov    0x1c(%eax),%eax
4000311e:	89 c2                	mov    %eax,%edx
40003120:	c1 fa 1f             	sar    $0x1f,%edx
40003123:	89 44 24 08          	mov    %eax,0x8(%esp)
40003127:	89 54 24 0c          	mov    %edx,0xc(%esp)
4000312b:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
4000312e:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
40003131:	89 04 24             	mov    %eax,(%esp)
40003134:	89 54 24 04          	mov    %edx,0x4(%esp)
40003138:	e8 33 22 00 00       	call   40005370 <__udivdi3>
4000313d:	89 44 24 08          	mov    %eax,0x8(%esp)
40003141:	89 54 24 0c          	mov    %edx,0xc(%esp)
40003145:	8b 45 0c             	mov    0xc(%ebp),%eax
40003148:	89 44 24 04          	mov    %eax,0x4(%esp)
4000314c:	8b 45 08             	mov    0x8(%ebp),%eax
4000314f:	89 04 24             	mov    %eax,(%esp)
40003152:	e8 85 ff ff ff       	call   400030dc <genint>
40003157:	89 45 0c             	mov    %eax,0xc(%ebp)
4000315a:	eb 1b                	jmp    40003177 <genint+0x9b>
4000315c:	8b 45 08             	mov    0x8(%ebp),%eax
4000315f:	8b 40 14             	mov    0x14(%eax),%eax
40003162:	85 c0                	test   %eax,%eax
40003164:	78 11                	js     40003177 <genint+0x9b>
40003166:	8b 45 08             	mov    0x8(%ebp),%eax
40003169:	8b 40 14             	mov    0x14(%eax),%eax
4000316c:	89 c2                	mov    %eax,%edx
4000316e:	8b 45 0c             	mov    0xc(%ebp),%eax
40003171:	88 10                	mov    %dl,(%eax)
40003173:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
40003177:	8b 45 08             	mov    0x8(%ebp),%eax
4000317a:	8b 40 1c             	mov    0x1c(%eax),%eax
4000317d:	89 c2                	mov    %eax,%edx
4000317f:	c1 fa 1f             	sar    $0x1f,%edx
40003182:	8b 4d f0             	mov    0xfffffff0(%ebp),%ecx
40003185:	8b 5d f4             	mov    0xfffffff4(%ebp),%ebx
40003188:	89 44 24 08          	mov    %eax,0x8(%esp)
4000318c:	89 54 24 0c          	mov    %edx,0xc(%esp)
40003190:	89 0c 24             	mov    %ecx,(%esp)
40003193:	89 5c 24 04          	mov    %ebx,0x4(%esp)
40003197:	e8 04 23 00 00       	call   400054a0 <__umoddi3>
4000319c:	05 80 5f 00 40       	add    $0x40005f80,%eax
400031a1:	0f b6 10             	movzbl (%eax),%edx
400031a4:	8b 45 0c             	mov    0xc(%ebp),%eax
400031a7:	88 10                	mov    %dl,(%eax)
400031a9:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
400031ad:	8b 45 0c             	mov    0xc(%ebp),%eax
400031b0:	83 c4 24             	add    $0x24,%esp
400031b3:	5b                   	pop    %ebx
400031b4:	5d                   	pop    %ebp
400031b5:	c3                   	ret    

400031b6 <putint>:
400031b6:	55                   	push   %ebp
400031b7:	89 e5                	mov    %esp,%ebp
400031b9:	83 ec 48             	sub    $0x48,%esp
400031bc:	8b 45 0c             	mov    0xc(%ebp),%eax
400031bf:	89 45 c8             	mov    %eax,0xffffffc8(%ebp)
400031c2:	8b 45 10             	mov    0x10(%ebp),%eax
400031c5:	89 45 cc             	mov    %eax,0xffffffcc(%ebp)
400031c8:	8d 45 de             	lea    0xffffffde(%ebp),%eax
400031cb:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
400031ce:	8b 55 08             	mov    0x8(%ebp),%edx
400031d1:	8b 45 14             	mov    0x14(%ebp),%eax
400031d4:	89 42 1c             	mov    %eax,0x1c(%edx)
400031d7:	8b 45 c8             	mov    0xffffffc8(%ebp),%eax
400031da:	8b 55 cc             	mov    0xffffffcc(%ebp),%edx
400031dd:	89 44 24 08          	mov    %eax,0x8(%esp)
400031e1:	89 54 24 0c          	mov    %edx,0xc(%esp)
400031e5:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
400031e8:	89 44 24 04          	mov    %eax,0x4(%esp)
400031ec:	8b 45 08             	mov    0x8(%ebp),%eax
400031ef:	89 04 24             	mov    %eax,(%esp)
400031f2:	e8 e5 fe ff ff       	call   400030dc <genint>
400031f7:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
400031fa:	8b 55 fc             	mov    0xfffffffc(%ebp),%edx
400031fd:	8d 45 de             	lea    0xffffffde(%ebp),%eax
40003200:	89 d1                	mov    %edx,%ecx
40003202:	29 c1                	sub    %eax,%ecx
40003204:	89 c8                	mov    %ecx,%eax
40003206:	89 44 24 08          	mov    %eax,0x8(%esp)
4000320a:	8d 45 de             	lea    0xffffffde(%ebp),%eax
4000320d:	89 44 24 04          	mov    %eax,0x4(%esp)
40003211:	8b 45 08             	mov    0x8(%ebp),%eax
40003214:	89 04 24             	mov    %eax,(%esp)
40003217:	e8 fb fd ff ff       	call   40003017 <putstr>
4000321c:	c9                   	leave  
4000321d:	c3                   	ret    

4000321e <vprintfmt>:
4000321e:	55                   	push   %ebp
4000321f:	89 e5                	mov    %esp,%ebp
40003221:	57                   	push   %edi
40003222:	83 ec 54             	sub    $0x54,%esp
40003225:	8d 7d c8             	lea    0xffffffc8(%ebp),%edi
40003228:	fc                   	cld    
40003229:	ba 00 00 00 00       	mov    $0x0,%edx
4000322e:	b8 08 00 00 00       	mov    $0x8,%eax
40003233:	89 c1                	mov    %eax,%ecx
40003235:	89 d0                	mov    %edx,%eax
40003237:	f3 ab                	rep stos %eax,%es:(%edi)
40003239:	8b 45 08             	mov    0x8(%ebp),%eax
4000323c:	89 45 c8             	mov    %eax,0xffffffc8(%ebp)
4000323f:	8b 45 0c             	mov    0xc(%ebp),%eax
40003242:	89 45 cc             	mov    %eax,0xffffffcc(%ebp)
40003245:	eb 1c                	jmp    40003263 <vprintfmt+0x45>
40003247:	83 7d c4 00          	cmpl   $0x0,0xffffffc4(%ebp)
4000324b:	0f 84 73 03 00 00    	je     400035c4 <vprintfmt+0x3a6>
40003251:	8b 45 0c             	mov    0xc(%ebp),%eax
40003254:	89 44 24 04          	mov    %eax,0x4(%esp)
40003258:	8b 55 c4             	mov    0xffffffc4(%ebp),%edx
4000325b:	89 14 24             	mov    %edx,(%esp)
4000325e:	8b 45 08             	mov    0x8(%ebp),%eax
40003261:	ff d0                	call   *%eax
40003263:	8b 45 10             	mov    0x10(%ebp),%eax
40003266:	0f b6 00             	movzbl (%eax),%eax
40003269:	0f b6 c0             	movzbl %al,%eax
4000326c:	89 45 c4             	mov    %eax,0xffffffc4(%ebp)
4000326f:	83 7d c4 25          	cmpl   $0x25,0xffffffc4(%ebp)
40003273:	0f 95 c0             	setne  %al
40003276:	83 45 10 01          	addl   $0x1,0x10(%ebp)
4000327a:	84 c0                	test   %al,%al
4000327c:	75 c9                	jne    40003247 <vprintfmt+0x29>
4000327e:	c7 45 d0 20 00 00 00 	movl   $0x20,0xffffffd0(%ebp)
40003285:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,0xffffffd4(%ebp)
4000328c:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,0xffffffd8(%ebp)
40003293:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,0xffffffdc(%ebp)
4000329a:	c7 45 e0 00 00 00 00 	movl   $0x0,0xffffffe0(%ebp)
400032a1:	c7 45 e4 0a 00 00 00 	movl   $0xa,0xffffffe4(%ebp)
400032a8:	eb 00                	jmp    400032aa <vprintfmt+0x8c>
400032aa:	8b 45 10             	mov    0x10(%ebp),%eax
400032ad:	0f b6 00             	movzbl (%eax),%eax
400032b0:	0f b6 c0             	movzbl %al,%eax
400032b3:	89 45 c4             	mov    %eax,0xffffffc4(%ebp)
400032b6:	8b 45 c4             	mov    0xffffffc4(%ebp),%eax
400032b9:	83 45 10 01          	addl   $0x1,0x10(%ebp)
400032bd:	83 e8 20             	sub    $0x20,%eax
400032c0:	89 45 b8             	mov    %eax,0xffffffb8(%ebp)
400032c3:	83 7d b8 58          	cmpl   $0x58,0xffffffb8(%ebp)
400032c7:	0f 87 c8 02 00 00    	ja     40003595 <vprintfmt+0x377>
400032cd:	8b 55 b8             	mov    0xffffffb8(%ebp),%edx
400032d0:	8b 04 95 98 5f 00 40 	mov    0x40005f98(,%edx,4),%eax
400032d7:	ff e0                	jmp    *%eax
400032d9:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
400032dc:	83 c8 10             	or     $0x10,%eax
400032df:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)
400032e2:	eb c6                	jmp    400032aa <vprintfmt+0x8c>
400032e4:	c7 45 dc 2b 00 00 00 	movl   $0x2b,0xffffffdc(%ebp)
400032eb:	eb bd                	jmp    400032aa <vprintfmt+0x8c>
400032ed:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
400032f0:	85 c0                	test   %eax,%eax
400032f2:	79 b6                	jns    400032aa <vprintfmt+0x8c>
400032f4:	c7 45 dc 20 00 00 00 	movl   $0x20,0xffffffdc(%ebp)
400032fb:	eb ad                	jmp    400032aa <vprintfmt+0x8c>
400032fd:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
40003300:	83 e0 08             	and    $0x8,%eax
40003303:	85 c0                	test   %eax,%eax
40003305:	75 07                	jne    4000330e <vprintfmt+0xf0>
40003307:	c7 45 d0 30 00 00 00 	movl   $0x30,0xffffffd0(%ebp)
4000330e:	c7 45 d8 00 00 00 00 	movl   $0x0,0xffffffd8(%ebp)
40003315:	8b 55 d8             	mov    0xffffffd8(%ebp),%edx
40003318:	89 d0                	mov    %edx,%eax
4000331a:	c1 e0 02             	shl    $0x2,%eax
4000331d:	01 d0                	add    %edx,%eax
4000331f:	01 c0                	add    %eax,%eax
40003321:	03 45 c4             	add    0xffffffc4(%ebp),%eax
40003324:	83 e8 30             	sub    $0x30,%eax
40003327:	89 45 d8             	mov    %eax,0xffffffd8(%ebp)
4000332a:	8b 45 10             	mov    0x10(%ebp),%eax
4000332d:	0f b6 00             	movzbl (%eax),%eax
40003330:	0f be c0             	movsbl %al,%eax
40003333:	89 45 c4             	mov    %eax,0xffffffc4(%ebp)
40003336:	83 7d c4 2f          	cmpl   $0x2f,0xffffffc4(%ebp)
4000333a:	7e 20                	jle    4000335c <vprintfmt+0x13e>
4000333c:	83 7d c4 39          	cmpl   $0x39,0xffffffc4(%ebp)
40003340:	7f 1a                	jg     4000335c <vprintfmt+0x13e>
40003342:	83 45 10 01          	addl   $0x1,0x10(%ebp)
40003346:	eb cd                	jmp    40003315 <vprintfmt+0xf7>
40003348:	8b 45 14             	mov    0x14(%ebp),%eax
4000334b:	83 c0 04             	add    $0x4,%eax
4000334e:	89 45 14             	mov    %eax,0x14(%ebp)
40003351:	8b 45 14             	mov    0x14(%ebp),%eax
40003354:	83 e8 04             	sub    $0x4,%eax
40003357:	8b 00                	mov    (%eax),%eax
40003359:	89 45 d8             	mov    %eax,0xffffffd8(%ebp)
4000335c:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
4000335f:	83 e0 08             	and    $0x8,%eax
40003362:	85 c0                	test   %eax,%eax
40003364:	0f 85 40 ff ff ff    	jne    400032aa <vprintfmt+0x8c>
4000336a:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
4000336d:	89 45 d4             	mov    %eax,0xffffffd4(%ebp)
40003370:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,0xffffffd8(%ebp)
40003377:	e9 2e ff ff ff       	jmp    400032aa <vprintfmt+0x8c>
4000337c:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
4000337f:	83 c8 08             	or     $0x8,%eax
40003382:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)
40003385:	e9 20 ff ff ff       	jmp    400032aa <vprintfmt+0x8c>
4000338a:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
4000338d:	83 c8 04             	or     $0x4,%eax
40003390:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)
40003393:	e9 12 ff ff ff       	jmp    400032aa <vprintfmt+0x8c>
40003398:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
4000339b:	89 45 bc             	mov    %eax,0xffffffbc(%ebp)
4000339e:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
400033a1:	83 e0 01             	and    $0x1,%eax
400033a4:	84 c0                	test   %al,%al
400033a6:	74 09                	je     400033b1 <vprintfmt+0x193>
400033a8:	c7 45 c0 02 00 00 00 	movl   $0x2,0xffffffc0(%ebp)
400033af:	eb 07                	jmp    400033b8 <vprintfmt+0x19a>
400033b1:	c7 45 c0 01 00 00 00 	movl   $0x1,0xffffffc0(%ebp)
400033b8:	8b 45 bc             	mov    0xffffffbc(%ebp),%eax
400033bb:	0b 45 c0             	or     0xffffffc0(%ebp),%eax
400033be:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)
400033c1:	e9 e4 fe ff ff       	jmp    400032aa <vprintfmt+0x8c>
400033c6:	8b 45 14             	mov    0x14(%ebp),%eax
400033c9:	83 c0 04             	add    $0x4,%eax
400033cc:	89 45 14             	mov    %eax,0x14(%ebp)
400033cf:	8b 45 14             	mov    0x14(%ebp),%eax
400033d2:	83 e8 04             	sub    $0x4,%eax
400033d5:	8b 10                	mov    (%eax),%edx
400033d7:	8b 45 0c             	mov    0xc(%ebp),%eax
400033da:	89 44 24 04          	mov    %eax,0x4(%esp)
400033de:	89 14 24             	mov    %edx,(%esp)
400033e1:	8b 45 08             	mov    0x8(%ebp),%eax
400033e4:	ff d0                	call   *%eax
400033e6:	e9 78 fe ff ff       	jmp    40003263 <vprintfmt+0x45>
400033eb:	8b 45 14             	mov    0x14(%ebp),%eax
400033ee:	83 c0 04             	add    $0x4,%eax
400033f1:	89 45 14             	mov    %eax,0x14(%ebp)
400033f4:	8b 45 14             	mov    0x14(%ebp),%eax
400033f7:	83 e8 04             	sub    $0x4,%eax
400033fa:	8b 00                	mov    (%eax),%eax
400033fc:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
400033ff:	83 7d f4 00          	cmpl   $0x0,0xfffffff4(%ebp)
40003403:	75 07                	jne    4000340c <vprintfmt+0x1ee>
40003405:	c7 45 f4 91 5f 00 40 	movl   $0x40005f91,0xfffffff4(%ebp)
4000340c:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
4000340f:	89 44 24 08          	mov    %eax,0x8(%esp)
40003413:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
40003416:	89 44 24 04          	mov    %eax,0x4(%esp)
4000341a:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
4000341d:	89 04 24             	mov    %eax,(%esp)
40003420:	e8 f2 fb ff ff       	call   40003017 <putstr>
40003425:	e9 39 fe ff ff       	jmp    40003263 <vprintfmt+0x45>
4000342a:	8d 45 14             	lea    0x14(%ebp),%eax
4000342d:	89 44 24 04          	mov    %eax,0x4(%esp)
40003431:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
40003434:	89 04 24             	mov    %eax,(%esp)
40003437:	e8 0e fb ff ff       	call   40002f4a <getint>
4000343c:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
4000343f:	89 55 ec             	mov    %edx,0xffffffec(%ebp)
40003442:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
40003445:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
40003448:	85 d2                	test   %edx,%edx
4000344a:	79 1a                	jns    40003466 <vprintfmt+0x248>
4000344c:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
4000344f:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
40003452:	f7 d8                	neg    %eax
40003454:	83 d2 00             	adc    $0x0,%edx
40003457:	f7 da                	neg    %edx
40003459:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
4000345c:	89 55 ec             	mov    %edx,0xffffffec(%ebp)
4000345f:	c7 45 dc 2d 00 00 00 	movl   $0x2d,0xffffffdc(%ebp)
40003466:	c7 44 24 0c 0a 00 00 	movl   $0xa,0xc(%esp)
4000346d:	00 
4000346e:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
40003471:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
40003474:	89 44 24 04          	mov    %eax,0x4(%esp)
40003478:	89 54 24 08          	mov    %edx,0x8(%esp)
4000347c:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
4000347f:	89 04 24             	mov    %eax,(%esp)
40003482:	e8 2f fd ff ff       	call   400031b6 <putint>
40003487:	e9 d7 fd ff ff       	jmp    40003263 <vprintfmt+0x45>
4000348c:	8d 45 14             	lea    0x14(%ebp),%eax
4000348f:	89 44 24 04          	mov    %eax,0x4(%esp)
40003493:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
40003496:	89 04 24             	mov    %eax,(%esp)
40003499:	e8 1e fa ff ff       	call   40002ebc <getuint>
4000349e:	c7 44 24 0c 0a 00 00 	movl   $0xa,0xc(%esp)
400034a5:	00 
400034a6:	89 44 24 04          	mov    %eax,0x4(%esp)
400034aa:	89 54 24 08          	mov    %edx,0x8(%esp)
400034ae:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
400034b1:	89 04 24             	mov    %eax,(%esp)
400034b4:	e8 fd fc ff ff       	call   400031b6 <putint>
400034b9:	e9 a5 fd ff ff       	jmp    40003263 <vprintfmt+0x45>
400034be:	8d 45 14             	lea    0x14(%ebp),%eax
400034c1:	89 44 24 04          	mov    %eax,0x4(%esp)
400034c5:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
400034c8:	89 04 24             	mov    %eax,(%esp)
400034cb:	e8 ec f9 ff ff       	call   40002ebc <getuint>
400034d0:	c7 44 24 0c 08 00 00 	movl   $0x8,0xc(%esp)
400034d7:	00 
400034d8:	89 44 24 04          	mov    %eax,0x4(%esp)
400034dc:	89 54 24 08          	mov    %edx,0x8(%esp)
400034e0:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
400034e3:	89 04 24             	mov    %eax,(%esp)
400034e6:	e8 cb fc ff ff       	call   400031b6 <putint>
400034eb:	e9 73 fd ff ff       	jmp    40003263 <vprintfmt+0x45>
400034f0:	8d 45 14             	lea    0x14(%ebp),%eax
400034f3:	89 44 24 04          	mov    %eax,0x4(%esp)
400034f7:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
400034fa:	89 04 24             	mov    %eax,(%esp)
400034fd:	e8 ba f9 ff ff       	call   40002ebc <getuint>
40003502:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
40003509:	00 
4000350a:	89 44 24 04          	mov    %eax,0x4(%esp)
4000350e:	89 54 24 08          	mov    %edx,0x8(%esp)
40003512:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
40003515:	89 04 24             	mov    %eax,(%esp)
40003518:	e8 99 fc ff ff       	call   400031b6 <putint>
4000351d:	e9 41 fd ff ff       	jmp    40003263 <vprintfmt+0x45>
40003522:	8b 45 0c             	mov    0xc(%ebp),%eax
40003525:	89 44 24 04          	mov    %eax,0x4(%esp)
40003529:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
40003530:	8b 45 08             	mov    0x8(%ebp),%eax
40003533:	ff d0                	call   *%eax
40003535:	8b 45 0c             	mov    0xc(%ebp),%eax
40003538:	89 44 24 04          	mov    %eax,0x4(%esp)
4000353c:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
40003543:	8b 45 08             	mov    0x8(%ebp),%eax
40003546:	ff d0                	call   *%eax
40003548:	8b 45 14             	mov    0x14(%ebp),%eax
4000354b:	83 c0 04             	add    $0x4,%eax
4000354e:	89 45 14             	mov    %eax,0x14(%ebp)
40003551:	8b 45 14             	mov    0x14(%ebp),%eax
40003554:	83 e8 04             	sub    $0x4,%eax
40003557:	8b 00                	mov    (%eax),%eax
40003559:	ba 00 00 00 00       	mov    $0x0,%edx
4000355e:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
40003565:	00 
40003566:	89 44 24 04          	mov    %eax,0x4(%esp)
4000356a:	89 54 24 08          	mov    %edx,0x8(%esp)
4000356e:	8d 45 c8             	lea    0xffffffc8(%ebp),%eax
40003571:	89 04 24             	mov    %eax,(%esp)
40003574:	e8 3d fc ff ff       	call   400031b6 <putint>
40003579:	e9 e5 fc ff ff       	jmp    40003263 <vprintfmt+0x45>
4000357e:	8b 45 0c             	mov    0xc(%ebp),%eax
40003581:	89 44 24 04          	mov    %eax,0x4(%esp)
40003585:	8b 55 c4             	mov    0xffffffc4(%ebp),%edx
40003588:	89 14 24             	mov    %edx,(%esp)
4000358b:	8b 45 08             	mov    0x8(%ebp),%eax
4000358e:	ff d0                	call   *%eax
40003590:	e9 ce fc ff ff       	jmp    40003263 <vprintfmt+0x45>
40003595:	8b 45 0c             	mov    0xc(%ebp),%eax
40003598:	89 44 24 04          	mov    %eax,0x4(%esp)
4000359c:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
400035a3:	8b 45 08             	mov    0x8(%ebp),%eax
400035a6:	ff d0                	call   *%eax
400035a8:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
400035ac:	eb 04                	jmp    400035b2 <vprintfmt+0x394>
400035ae:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
400035b2:	8b 45 10             	mov    0x10(%ebp),%eax
400035b5:	83 e8 01             	sub    $0x1,%eax
400035b8:	0f b6 00             	movzbl (%eax),%eax
400035bb:	3c 25                	cmp    $0x25,%al
400035bd:	75 ef                	jne    400035ae <vprintfmt+0x390>
400035bf:	e9 9f fc ff ff       	jmp    40003263 <vprintfmt+0x45>
400035c4:	83 c4 54             	add    $0x54,%esp
400035c7:	5f                   	pop    %edi
400035c8:	5d                   	pop    %ebp
400035c9:	c3                   	ret    
400035ca:	90                   	nop    
400035cb:	90                   	nop    

400035cc <strlen>:
400035cc:	55                   	push   %ebp
400035cd:	89 e5                	mov    %esp,%ebp
400035cf:	83 ec 10             	sub    $0x10,%esp
400035d2:	c7 45 fc 00 00 00 00 	movl   $0x0,0xfffffffc(%ebp)
400035d9:	eb 08                	jmp    400035e3 <strlen+0x17>
400035db:	83 45 fc 01          	addl   $0x1,0xfffffffc(%ebp)
400035df:	83 45 08 01          	addl   $0x1,0x8(%ebp)
400035e3:	8b 45 08             	mov    0x8(%ebp),%eax
400035e6:	0f b6 00             	movzbl (%eax),%eax
400035e9:	84 c0                	test   %al,%al
400035eb:	75 ee                	jne    400035db <strlen+0xf>
400035ed:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
400035f0:	c9                   	leave  
400035f1:	c3                   	ret    

400035f2 <strcpy>:
400035f2:	55                   	push   %ebp
400035f3:	89 e5                	mov    %esp,%ebp
400035f5:	83 ec 10             	sub    $0x10,%esp
400035f8:	8b 45 08             	mov    0x8(%ebp),%eax
400035fb:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
400035fe:	8b 45 0c             	mov    0xc(%ebp),%eax
40003601:	0f b6 10             	movzbl (%eax),%edx
40003604:	8b 45 08             	mov    0x8(%ebp),%eax
40003607:	88 10                	mov    %dl,(%eax)
40003609:	8b 45 08             	mov    0x8(%ebp),%eax
4000360c:	0f b6 00             	movzbl (%eax),%eax
4000360f:	84 c0                	test   %al,%al
40003611:	0f 95 c0             	setne  %al
40003614:	83 45 08 01          	addl   $0x1,0x8(%ebp)
40003618:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
4000361c:	84 c0                	test   %al,%al
4000361e:	75 de                	jne    400035fe <strcpy+0xc>
40003620:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
40003623:	c9                   	leave  
40003624:	c3                   	ret    

40003625 <strncpy>:
40003625:	55                   	push   %ebp
40003626:	89 e5                	mov    %esp,%ebp
40003628:	83 ec 10             	sub    $0x10,%esp
4000362b:	8b 45 08             	mov    0x8(%ebp),%eax
4000362e:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
40003631:	c7 45 f8 00 00 00 00 	movl   $0x0,0xfffffff8(%ebp)
40003638:	eb 21                	jmp    4000365b <strncpy+0x36>
4000363a:	8b 45 0c             	mov    0xc(%ebp),%eax
4000363d:	0f b6 10             	movzbl (%eax),%edx
40003640:	8b 45 08             	mov    0x8(%ebp),%eax
40003643:	88 10                	mov    %dl,(%eax)
40003645:	83 45 08 01          	addl   $0x1,0x8(%ebp)
40003649:	8b 45 0c             	mov    0xc(%ebp),%eax
4000364c:	0f b6 00             	movzbl (%eax),%eax
4000364f:	84 c0                	test   %al,%al
40003651:	74 04                	je     40003657 <strncpy+0x32>
40003653:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
40003657:	83 45 f8 01          	addl   $0x1,0xfffffff8(%ebp)
4000365b:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
4000365e:	3b 45 10             	cmp    0x10(%ebp),%eax
40003661:	72 d7                	jb     4000363a <strncpy+0x15>
40003663:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
40003666:	c9                   	leave  
40003667:	c3                   	ret    

40003668 <strlcpy>:
40003668:	55                   	push   %ebp
40003669:	89 e5                	mov    %esp,%ebp
4000366b:	83 ec 10             	sub    $0x10,%esp
4000366e:	8b 45 08             	mov    0x8(%ebp),%eax
40003671:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
40003674:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
40003678:	74 2f                	je     400036a9 <strlcpy+0x41>
4000367a:	eb 13                	jmp    4000368f <strlcpy+0x27>
4000367c:	8b 45 0c             	mov    0xc(%ebp),%eax
4000367f:	0f b6 10             	movzbl (%eax),%edx
40003682:	8b 45 08             	mov    0x8(%ebp),%eax
40003685:	88 10                	mov    %dl,(%eax)
40003687:	83 45 08 01          	addl   $0x1,0x8(%ebp)
4000368b:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
4000368f:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
40003693:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
40003697:	74 0a                	je     400036a3 <strlcpy+0x3b>
40003699:	8b 45 0c             	mov    0xc(%ebp),%eax
4000369c:	0f b6 00             	movzbl (%eax),%eax
4000369f:	84 c0                	test   %al,%al
400036a1:	75 d9                	jne    4000367c <strlcpy+0x14>
400036a3:	8b 45 08             	mov    0x8(%ebp),%eax
400036a6:	c6 00 00             	movb   $0x0,(%eax)
400036a9:	8b 55 08             	mov    0x8(%ebp),%edx
400036ac:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
400036af:	89 d1                	mov    %edx,%ecx
400036b1:	29 c1                	sub    %eax,%ecx
400036b3:	89 c8                	mov    %ecx,%eax
400036b5:	c9                   	leave  
400036b6:	c3                   	ret    

400036b7 <strcmp>:
400036b7:	55                   	push   %ebp
400036b8:	89 e5                	mov    %esp,%ebp
400036ba:	eb 08                	jmp    400036c4 <strcmp+0xd>
400036bc:	83 45 08 01          	addl   $0x1,0x8(%ebp)
400036c0:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
400036c4:	8b 45 08             	mov    0x8(%ebp),%eax
400036c7:	0f b6 00             	movzbl (%eax),%eax
400036ca:	84 c0                	test   %al,%al
400036cc:	74 10                	je     400036de <strcmp+0x27>
400036ce:	8b 45 08             	mov    0x8(%ebp),%eax
400036d1:	0f b6 10             	movzbl (%eax),%edx
400036d4:	8b 45 0c             	mov    0xc(%ebp),%eax
400036d7:	0f b6 00             	movzbl (%eax),%eax
400036da:	38 c2                	cmp    %al,%dl
400036dc:	74 de                	je     400036bc <strcmp+0x5>
400036de:	8b 45 08             	mov    0x8(%ebp),%eax
400036e1:	0f b6 00             	movzbl (%eax),%eax
400036e4:	0f b6 d0             	movzbl %al,%edx
400036e7:	8b 45 0c             	mov    0xc(%ebp),%eax
400036ea:	0f b6 00             	movzbl (%eax),%eax
400036ed:	0f b6 c0             	movzbl %al,%eax
400036f0:	89 d1                	mov    %edx,%ecx
400036f2:	29 c1                	sub    %eax,%ecx
400036f4:	89 c8                	mov    %ecx,%eax
400036f6:	5d                   	pop    %ebp
400036f7:	c3                   	ret    

400036f8 <strncmp>:
400036f8:	55                   	push   %ebp
400036f9:	89 e5                	mov    %esp,%ebp
400036fb:	83 ec 04             	sub    $0x4,%esp
400036fe:	eb 0c                	jmp    4000370c <strncmp+0x14>
40003700:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
40003704:	83 45 08 01          	addl   $0x1,0x8(%ebp)
40003708:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
4000370c:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
40003710:	74 1a                	je     4000372c <strncmp+0x34>
40003712:	8b 45 08             	mov    0x8(%ebp),%eax
40003715:	0f b6 00             	movzbl (%eax),%eax
40003718:	84 c0                	test   %al,%al
4000371a:	74 10                	je     4000372c <strncmp+0x34>
4000371c:	8b 45 08             	mov    0x8(%ebp),%eax
4000371f:	0f b6 10             	movzbl (%eax),%edx
40003722:	8b 45 0c             	mov    0xc(%ebp),%eax
40003725:	0f b6 00             	movzbl (%eax),%eax
40003728:	38 c2                	cmp    %al,%dl
4000372a:	74 d4                	je     40003700 <strncmp+0x8>
4000372c:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
40003730:	75 09                	jne    4000373b <strncmp+0x43>
40003732:	c7 45 fc 00 00 00 00 	movl   $0x0,0xfffffffc(%ebp)
40003739:	eb 19                	jmp    40003754 <strncmp+0x5c>
4000373b:	8b 45 08             	mov    0x8(%ebp),%eax
4000373e:	0f b6 00             	movzbl (%eax),%eax
40003741:	0f b6 d0             	movzbl %al,%edx
40003744:	8b 45 0c             	mov    0xc(%ebp),%eax
40003747:	0f b6 00             	movzbl (%eax),%eax
4000374a:	0f b6 c0             	movzbl %al,%eax
4000374d:	89 d1                	mov    %edx,%ecx
4000374f:	29 c1                	sub    %eax,%ecx
40003751:	89 4d fc             	mov    %ecx,0xfffffffc(%ebp)
40003754:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
40003757:	c9                   	leave  
40003758:	c3                   	ret    

40003759 <strchr>:
40003759:	55                   	push   %ebp
4000375a:	89 e5                	mov    %esp,%ebp
4000375c:	83 ec 08             	sub    $0x8,%esp
4000375f:	8b 45 0c             	mov    0xc(%ebp),%eax
40003762:	88 45 fc             	mov    %al,0xfffffffc(%ebp)
40003765:	eb 1c                	jmp    40003783 <strchr+0x2a>
40003767:	8b 45 08             	mov    0x8(%ebp),%eax
4000376a:	0f b6 00             	movzbl (%eax),%eax
4000376d:	84 c0                	test   %al,%al
4000376f:	0f 94 c0             	sete   %al
40003772:	83 45 08 01          	addl   $0x1,0x8(%ebp)
40003776:	84 c0                	test   %al,%al
40003778:	74 09                	je     40003783 <strchr+0x2a>
4000377a:	c7 45 f8 00 00 00 00 	movl   $0x0,0xfffffff8(%ebp)
40003781:	eb 11                	jmp    40003794 <strchr+0x3b>
40003783:	8b 45 08             	mov    0x8(%ebp),%eax
40003786:	0f b6 00             	movzbl (%eax),%eax
40003789:	3a 45 fc             	cmp    0xfffffffc(%ebp),%al
4000378c:	75 d9                	jne    40003767 <strchr+0xe>
4000378e:	8b 45 08             	mov    0x8(%ebp),%eax
40003791:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
40003794:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
40003797:	c9                   	leave  
40003798:	c3                   	ret    

40003799 <memset>:
40003799:	55                   	push   %ebp
4000379a:	89 e5                	mov    %esp,%ebp
4000379c:	57                   	push   %edi
4000379d:	83 ec 14             	sub    $0x14,%esp
400037a0:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
400037a4:	75 08                	jne    400037ae <memset+0x15>
400037a6:	8b 45 08             	mov    0x8(%ebp),%eax
400037a9:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
400037ac:	eb 5b                	jmp    40003809 <memset+0x70>
400037ae:	8b 45 08             	mov    0x8(%ebp),%eax
400037b1:	83 e0 03             	and    $0x3,%eax
400037b4:	85 c0                	test   %eax,%eax
400037b6:	75 3f                	jne    400037f7 <memset+0x5e>
400037b8:	8b 45 10             	mov    0x10(%ebp),%eax
400037bb:	83 e0 03             	and    $0x3,%eax
400037be:	85 c0                	test   %eax,%eax
400037c0:	75 35                	jne    400037f7 <memset+0x5e>
400037c2:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
400037c9:	8b 45 0c             	mov    0xc(%ebp),%eax
400037cc:	89 c2                	mov    %eax,%edx
400037ce:	c1 e2 18             	shl    $0x18,%edx
400037d1:	8b 45 0c             	mov    0xc(%ebp),%eax
400037d4:	c1 e0 10             	shl    $0x10,%eax
400037d7:	09 c2                	or     %eax,%edx
400037d9:	8b 45 0c             	mov    0xc(%ebp),%eax
400037dc:	c1 e0 08             	shl    $0x8,%eax
400037df:	09 d0                	or     %edx,%eax
400037e1:	09 45 0c             	or     %eax,0xc(%ebp)
400037e4:	8b 45 10             	mov    0x10(%ebp),%eax
400037e7:	89 c1                	mov    %eax,%ecx
400037e9:	c1 e9 02             	shr    $0x2,%ecx
400037ec:	8b 7d 08             	mov    0x8(%ebp),%edi
400037ef:	8b 45 0c             	mov    0xc(%ebp),%eax
400037f2:	fc                   	cld    
400037f3:	f3 ab                	rep stos %eax,%es:(%edi)
400037f5:	eb 0c                	jmp    40003803 <memset+0x6a>
400037f7:	8b 7d 08             	mov    0x8(%ebp),%edi
400037fa:	8b 45 0c             	mov    0xc(%ebp),%eax
400037fd:	8b 4d 10             	mov    0x10(%ebp),%ecx
40003800:	fc                   	cld    
40003801:	f3 aa                	rep stos %al,%es:(%edi)
40003803:	8b 45 08             	mov    0x8(%ebp),%eax
40003806:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
40003809:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
4000380c:	83 c4 14             	add    $0x14,%esp
4000380f:	5f                   	pop    %edi
40003810:	5d                   	pop    %ebp
40003811:	c3                   	ret    

40003812 <memmove>:
40003812:	55                   	push   %ebp
40003813:	89 e5                	mov    %esp,%ebp
40003815:	57                   	push   %edi
40003816:	56                   	push   %esi
40003817:	83 ec 10             	sub    $0x10,%esp
4000381a:	8b 45 0c             	mov    0xc(%ebp),%eax
4000381d:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
40003820:	8b 45 08             	mov    0x8(%ebp),%eax
40003823:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
40003826:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
40003829:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
4000382c:	73 63                	jae    40003891 <memmove+0x7f>
4000382e:	8b 45 10             	mov    0x10(%ebp),%eax
40003831:	03 45 f0             	add    0xfffffff0(%ebp),%eax
40003834:	3b 45 f4             	cmp    0xfffffff4(%ebp),%eax
40003837:	76 58                	jbe    40003891 <memmove+0x7f>
40003839:	8b 45 10             	mov    0x10(%ebp),%eax
4000383c:	01 45 f0             	add    %eax,0xfffffff0(%ebp)
4000383f:	8b 45 10             	mov    0x10(%ebp),%eax
40003842:	01 45 f4             	add    %eax,0xfffffff4(%ebp)
40003845:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
40003848:	83 e0 03             	and    $0x3,%eax
4000384b:	85 c0                	test   %eax,%eax
4000384d:	75 2d                	jne    4000387c <memmove+0x6a>
4000384f:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
40003852:	83 e0 03             	and    $0x3,%eax
40003855:	85 c0                	test   %eax,%eax
40003857:	75 23                	jne    4000387c <memmove+0x6a>
40003859:	8b 45 10             	mov    0x10(%ebp),%eax
4000385c:	83 e0 03             	and    $0x3,%eax
4000385f:	85 c0                	test   %eax,%eax
40003861:	75 19                	jne    4000387c <memmove+0x6a>
40003863:	8b 7d f4             	mov    0xfffffff4(%ebp),%edi
40003866:	83 ef 04             	sub    $0x4,%edi
40003869:	8b 75 f0             	mov    0xfffffff0(%ebp),%esi
4000386c:	83 ee 04             	sub    $0x4,%esi
4000386f:	8b 45 10             	mov    0x10(%ebp),%eax
40003872:	89 c1                	mov    %eax,%ecx
40003874:	c1 e9 02             	shr    $0x2,%ecx
40003877:	fd                   	std    
40003878:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
4000387a:	eb 12                	jmp    4000388e <memmove+0x7c>
4000387c:	8b 7d f4             	mov    0xfffffff4(%ebp),%edi
4000387f:	83 ef 01             	sub    $0x1,%edi
40003882:	8b 75 f0             	mov    0xfffffff0(%ebp),%esi
40003885:	83 ee 01             	sub    $0x1,%esi
40003888:	8b 4d 10             	mov    0x10(%ebp),%ecx
4000388b:	fd                   	std    
4000388c:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
4000388e:	fc                   	cld    
4000388f:	eb 3d                	jmp    400038ce <memmove+0xbc>
40003891:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
40003894:	83 e0 03             	and    $0x3,%eax
40003897:	85 c0                	test   %eax,%eax
40003899:	75 27                	jne    400038c2 <memmove+0xb0>
4000389b:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
4000389e:	83 e0 03             	and    $0x3,%eax
400038a1:	85 c0                	test   %eax,%eax
400038a3:	75 1d                	jne    400038c2 <memmove+0xb0>
400038a5:	8b 45 10             	mov    0x10(%ebp),%eax
400038a8:	83 e0 03             	and    $0x3,%eax
400038ab:	85 c0                	test   %eax,%eax
400038ad:	75 13                	jne    400038c2 <memmove+0xb0>
400038af:	8b 45 10             	mov    0x10(%ebp),%eax
400038b2:	89 c1                	mov    %eax,%ecx
400038b4:	c1 e9 02             	shr    $0x2,%ecx
400038b7:	8b 7d f4             	mov    0xfffffff4(%ebp),%edi
400038ba:	8b 75 f0             	mov    0xfffffff0(%ebp),%esi
400038bd:	fc                   	cld    
400038be:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
400038c0:	eb 0c                	jmp    400038ce <memmove+0xbc>
400038c2:	8b 7d f4             	mov    0xfffffff4(%ebp),%edi
400038c5:	8b 75 f0             	mov    0xfffffff0(%ebp),%esi
400038c8:	8b 4d 10             	mov    0x10(%ebp),%ecx
400038cb:	fc                   	cld    
400038cc:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
400038ce:	8b 45 08             	mov    0x8(%ebp),%eax
400038d1:	83 c4 10             	add    $0x10,%esp
400038d4:	5e                   	pop    %esi
400038d5:	5f                   	pop    %edi
400038d6:	5d                   	pop    %ebp
400038d7:	c3                   	ret    

400038d8 <memcpy>:
400038d8:	55                   	push   %ebp
400038d9:	89 e5                	mov    %esp,%ebp
400038db:	83 ec 0c             	sub    $0xc,%esp
400038de:	8b 45 10             	mov    0x10(%ebp),%eax
400038e1:	89 44 24 08          	mov    %eax,0x8(%esp)
400038e5:	8b 45 0c             	mov    0xc(%ebp),%eax
400038e8:	89 44 24 04          	mov    %eax,0x4(%esp)
400038ec:	8b 45 08             	mov    0x8(%ebp),%eax
400038ef:	89 04 24             	mov    %eax,(%esp)
400038f2:	e8 1b ff ff ff       	call   40003812 <memmove>
400038f7:	c9                   	leave  
400038f8:	c3                   	ret    

400038f9 <memcmp>:
400038f9:	55                   	push   %ebp
400038fa:	89 e5                	mov    %esp,%ebp
400038fc:	83 ec 14             	sub    $0x14,%esp
400038ff:	8b 45 08             	mov    0x8(%ebp),%eax
40003902:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
40003905:	8b 45 0c             	mov    0xc(%ebp),%eax
40003908:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
4000390b:	eb 33                	jmp    40003940 <memcmp+0x47>
4000390d:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
40003910:	0f b6 10             	movzbl (%eax),%edx
40003913:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
40003916:	0f b6 00             	movzbl (%eax),%eax
40003919:	38 c2                	cmp    %al,%dl
4000391b:	74 1b                	je     40003938 <memcmp+0x3f>
4000391d:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
40003920:	0f b6 00             	movzbl (%eax),%eax
40003923:	0f b6 d0             	movzbl %al,%edx
40003926:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
40003929:	0f b6 00             	movzbl (%eax),%eax
4000392c:	0f b6 c0             	movzbl %al,%eax
4000392f:	89 d1                	mov    %edx,%ecx
40003931:	29 c1                	sub    %eax,%ecx
40003933:	89 4d ec             	mov    %ecx,0xffffffec(%ebp)
40003936:	eb 19                	jmp    40003951 <memcmp+0x58>
40003938:	83 45 f8 01          	addl   $0x1,0xfffffff8(%ebp)
4000393c:	83 45 fc 01          	addl   $0x1,0xfffffffc(%ebp)
40003940:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
40003944:	83 7d 10 ff          	cmpl   $0xffffffff,0x10(%ebp)
40003948:	75 c3                	jne    4000390d <memcmp+0x14>
4000394a:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
40003951:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
40003954:	c9                   	leave  
40003955:	c3                   	ret    

40003956 <memchr>:
40003956:	55                   	push   %ebp
40003957:	89 e5                	mov    %esp,%ebp
40003959:	83 ec 14             	sub    $0x14,%esp
4000395c:	8b 45 08             	mov    0x8(%ebp),%eax
4000395f:	8b 55 10             	mov    0x10(%ebp),%edx
40003962:	01 d0                	add    %edx,%eax
40003964:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
40003967:	eb 19                	jmp    40003982 <memchr+0x2c>
40003969:	8b 45 08             	mov    0x8(%ebp),%eax
4000396c:	0f b6 10             	movzbl (%eax),%edx
4000396f:	8b 45 0c             	mov    0xc(%ebp),%eax
40003972:	38 c2                	cmp    %al,%dl
40003974:	75 08                	jne    4000397e <memchr+0x28>
40003976:	8b 45 08             	mov    0x8(%ebp),%eax
40003979:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
4000397c:	eb 13                	jmp    40003991 <memchr+0x3b>
4000397e:	83 45 08 01          	addl   $0x1,0x8(%ebp)
40003982:	8b 45 08             	mov    0x8(%ebp),%eax
40003985:	3b 45 fc             	cmp    0xfffffffc(%ebp),%eax
40003988:	72 df                	jb     40003969 <memchr+0x13>
4000398a:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
40003991:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
40003994:	c9                   	leave  
40003995:	c3                   	ret    
40003996:	90                   	nop    
40003997:	90                   	nop    

40003998 <exit>:
40003998:	55                   	push   %ebp
40003999:	89 e5                	mov    %esp,%ebp
4000399b:	83 ec 18             	sub    $0x18,%esp
4000399e:	8b 15 34 61 00 40    	mov    0x40006134,%edx
400039a4:	8b 45 08             	mov    0x8(%ebp),%eax
400039a7:	89 42 0c             	mov    %eax,0xc(%edx)
400039aa:	a1 34 61 00 40       	mov    0x40006134,%eax
400039af:	c7 40 08 01 00 00 00 	movl   $0x1,0x8(%eax)
400039b6:	b8 03 00 00 00       	mov    $0x3,%eax
400039bb:	cd 30                	int    $0x30
400039bd:	c7 44 24 08 fc 60 00 	movl   $0x400060fc,0x8(%esp)
400039c4:	40 
400039c5:	c7 44 24 04 1b 00 00 	movl   $0x1b,0x4(%esp)
400039cc:	00 
400039cd:	c7 04 24 22 61 00 40 	movl   $0x40006122,(%esp)
400039d4:	e8 ff f1 ff ff       	call   40002bd8 <debug_panic>

400039d9 <abort>:
400039d9:	55                   	push   %ebp
400039da:	89 e5                	mov    %esp,%ebp
400039dc:	83 ec 08             	sub    $0x8,%esp
400039df:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
400039e6:	e8 ad ff ff ff       	call   40003998 <exit>
400039eb:	90                   	nop    

400039ec <cputs>:
400039ec:	55                   	push   %ebp
400039ed:	89 e5                	mov    %esp,%ebp
400039ef:	53                   	push   %ebx
400039f0:	83 ec 10             	sub    $0x10,%esp
400039f3:	8b 45 08             	mov    0x8(%ebp),%eax
400039f6:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
400039f9:	b8 00 00 00 00       	mov    $0x0,%eax
400039fe:	8b 5d f8             	mov    0xfffffff8(%ebp),%ebx
40003a01:	cd 30                	int    $0x30
40003a03:	83 c4 10             	add    $0x10,%esp
40003a06:	5b                   	pop    %ebx
40003a07:	5d                   	pop    %ebp
40003a08:	c3                   	ret    
40003a09:	90                   	nop    
40003a0a:	90                   	nop    
40003a0b:	90                   	nop    

40003a0c <fileino_alloc>:
40003a0c:	55                   	push   %ebp
40003a0d:	89 e5                	mov    %esp,%ebp
40003a0f:	83 ec 28             	sub    $0x28,%esp
40003a12:	c7 45 fc 04 00 00 00 	movl   $0x4,0xfffffffc(%ebp)
40003a19:	eb 27                	jmp    40003a42 <fileino_alloc+0x36>
40003a1b:	8b 15 34 61 00 40    	mov    0x40006134,%edx
40003a21:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
40003a24:	6b c0 5c             	imul   $0x5c,%eax,%eax
40003a27:	01 d0                	add    %edx,%eax
40003a29:	05 10 10 00 00       	add    $0x1010,%eax
40003a2e:	0f b6 40 04          	movzbl 0x4(%eax),%eax
40003a32:	84 c0                	test   %al,%al
40003a34:	75 08                	jne    40003a3e <fileino_alloc+0x32>
40003a36:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
40003a39:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
40003a3c:	eb 3b                	jmp    40003a79 <fileino_alloc+0x6d>
40003a3e:	83 45 fc 01          	addl   $0x1,0xfffffffc(%ebp)
40003a42:	81 7d fc ff 00 00 00 	cmpl   $0xff,0xfffffffc(%ebp)
40003a49:	7e d0                	jle    40003a1b <fileino_alloc+0xf>
40003a4b:	c7 44 24 08 38 61 00 	movl   $0x40006138,0x8(%esp)
40003a52:	40 
40003a53:	c7 44 24 04 2a 00 00 	movl   $0x2a,0x4(%esp)
40003a5a:	00 
40003a5b:	c7 04 24 57 61 00 40 	movl   $0x40006157,(%esp)
40003a62:	e8 db f1 ff ff       	call   40002c42 <debug_warn>
40003a67:	a1 34 61 00 40       	mov    0x40006134,%eax
40003a6c:	c7 00 07 00 00 00    	movl   $0x7,(%eax)
40003a72:	c7 45 ec ff ff ff ff 	movl   $0xffffffff,0xffffffec(%ebp)
40003a79:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
40003a7c:	c9                   	leave  
40003a7d:	c3                   	ret    

40003a7e <fileino_create>:
40003a7e:	55                   	push   %ebp
40003a7f:	89 e5                	mov    %esp,%ebp
40003a81:	83 ec 28             	sub    $0x28,%esp
40003a84:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
40003a88:	75 24                	jne    40003aae <fileino_create+0x30>
40003a8a:	c7 44 24 0c 65 61 00 	movl   $0x40006165,0xc(%esp)
40003a91:	40 
40003a92:	c7 44 24 08 6f 61 00 	movl   $0x4000616f,0x8(%esp)
40003a99:	40 
40003a9a:	c7 44 24 04 36 00 00 	movl   $0x36,0x4(%esp)
40003aa1:	00 
40003aa2:	c7 04 24 57 61 00 40 	movl   $0x40006157,(%esp)
40003aa9:	e8 2a f1 ff ff       	call   40002bd8 <debug_panic>
40003aae:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
40003ab2:	74 0a                	je     40003abe <fileino_create+0x40>
40003ab4:	8b 45 10             	mov    0x10(%ebp),%eax
40003ab7:	0f b6 00             	movzbl (%eax),%eax
40003aba:	84 c0                	test   %al,%al
40003abc:	75 24                	jne    40003ae2 <fileino_create+0x64>
40003abe:	c7 44 24 0c 84 61 00 	movl   $0x40006184,0xc(%esp)
40003ac5:	40 
40003ac6:	c7 44 24 08 6f 61 00 	movl   $0x4000616f,0x8(%esp)
40003acd:	40 
40003ace:	c7 44 24 04 37 00 00 	movl   $0x37,0x4(%esp)
40003ad5:	00 
40003ad6:	c7 04 24 57 61 00 40 	movl   $0x40006157,(%esp)
40003add:	e8 f6 f0 ff ff       	call   40002bd8 <debug_panic>
40003ae2:	8b 45 10             	mov    0x10(%ebp),%eax
40003ae5:	89 04 24             	mov    %eax,(%esp)
40003ae8:	e8 df fa ff ff       	call   400035cc <strlen>
40003aed:	83 f8 3f             	cmp    $0x3f,%eax
40003af0:	7e 24                	jle    40003b16 <fileino_create+0x98>
40003af2:	c7 44 24 0c a1 61 00 	movl   $0x400061a1,0xc(%esp)
40003af9:	40 
40003afa:	c7 44 24 08 6f 61 00 	movl   $0x4000616f,0x8(%esp)
40003b01:	40 
40003b02:	c7 44 24 04 38 00 00 	movl   $0x38,0x4(%esp)
40003b09:	00 
40003b0a:	c7 04 24 57 61 00 40 	movl   $0x40006157,(%esp)
40003b11:	e8 c2 f0 ff ff       	call   40002bd8 <debug_panic>
40003b16:	c7 45 fc 04 00 00 00 	movl   $0x4,0xfffffffc(%ebp)
40003b1d:	eb 4a                	jmp    40003b69 <fileino_create+0xeb>
40003b1f:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
40003b22:	8b 55 08             	mov    0x8(%ebp),%edx
40003b25:	6b c0 5c             	imul   $0x5c,%eax,%eax
40003b28:	01 d0                	add    %edx,%eax
40003b2a:	05 10 10 00 00       	add    $0x1010,%eax
40003b2f:	8b 00                	mov    (%eax),%eax
40003b31:	3b 45 0c             	cmp    0xc(%ebp),%eax
40003b34:	75 2f                	jne    40003b65 <fileino_create+0xe7>
40003b36:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
40003b39:	6b c0 5c             	imul   $0x5c,%eax,%eax
40003b3c:	05 10 10 00 00       	add    $0x1010,%eax
40003b41:	03 45 08             	add    0x8(%ebp),%eax
40003b44:	8d 50 04             	lea    0x4(%eax),%edx
40003b47:	8b 45 10             	mov    0x10(%ebp),%eax
40003b4a:	89 44 24 04          	mov    %eax,0x4(%esp)
40003b4e:	89 14 24             	mov    %edx,(%esp)
40003b51:	e8 61 fb ff ff       	call   400036b7 <strcmp>
40003b56:	85 c0                	test   %eax,%eax
40003b58:	75 0b                	jne    40003b65 <fileino_create+0xe7>
40003b5a:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
40003b5d:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
40003b60:	e9 a7 00 00 00       	jmp    40003c0c <fileino_create+0x18e>
40003b65:	83 45 fc 01          	addl   $0x1,0xfffffffc(%ebp)
40003b69:	81 7d fc ff 00 00 00 	cmpl   $0xff,0xfffffffc(%ebp)
40003b70:	7e ad                	jle    40003b1f <fileino_create+0xa1>
40003b72:	c7 45 fc 04 00 00 00 	movl   $0x4,0xfffffffc(%ebp)
40003b79:	eb 5a                	jmp    40003bd5 <fileino_create+0x157>
40003b7b:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
40003b7e:	8b 55 08             	mov    0x8(%ebp),%edx
40003b81:	6b c0 5c             	imul   $0x5c,%eax,%eax
40003b84:	01 d0                	add    %edx,%eax
40003b86:	05 10 10 00 00       	add    $0x1010,%eax
40003b8b:	0f b6 40 04          	movzbl 0x4(%eax),%eax
40003b8f:	84 c0                	test   %al,%al
40003b91:	75 3e                	jne    40003bd1 <fileino_create+0x153>
40003b93:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
40003b96:	8b 55 08             	mov    0x8(%ebp),%edx
40003b99:	6b c0 5c             	imul   $0x5c,%eax,%eax
40003b9c:	01 d0                	add    %edx,%eax
40003b9e:	8d 90 10 10 00 00    	lea    0x1010(%eax),%edx
40003ba4:	8b 45 0c             	mov    0xc(%ebp),%eax
40003ba7:	89 02                	mov    %eax,(%edx)
40003ba9:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
40003bac:	6b c0 5c             	imul   $0x5c,%eax,%eax
40003baf:	05 10 10 00 00       	add    $0x1010,%eax
40003bb4:	03 45 08             	add    0x8(%ebp),%eax
40003bb7:	8d 50 04             	lea    0x4(%eax),%edx
40003bba:	8b 45 10             	mov    0x10(%ebp),%eax
40003bbd:	89 44 24 04          	mov    %eax,0x4(%esp)
40003bc1:	89 14 24             	mov    %edx,(%esp)
40003bc4:	e8 29 fa ff ff       	call   400035f2 <strcpy>
40003bc9:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
40003bcc:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
40003bcf:	eb 3b                	jmp    40003c0c <fileino_create+0x18e>
40003bd1:	83 45 fc 01          	addl   $0x1,0xfffffffc(%ebp)
40003bd5:	81 7d fc ff 00 00 00 	cmpl   $0xff,0xfffffffc(%ebp)
40003bdc:	7e 9d                	jle    40003b7b <fileino_create+0xfd>
40003bde:	c7 44 24 08 bc 61 00 	movl   $0x400061bc,0x8(%esp)
40003be5:	40 
40003be6:	c7 44 24 04 49 00 00 	movl   $0x49,0x4(%esp)
40003bed:	00 
40003bee:	c7 04 24 57 61 00 40 	movl   $0x40006157,(%esp)
40003bf5:	e8 48 f0 ff ff       	call   40002c42 <debug_warn>
40003bfa:	a1 34 61 00 40       	mov    0x40006134,%eax
40003bff:	c7 00 07 00 00 00    	movl   $0x7,(%eax)
40003c05:	c7 45 ec ff ff ff ff 	movl   $0xffffffff,0xffffffec(%ebp)
40003c0c:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
40003c0f:	c9                   	leave  
40003c10:	c3                   	ret    

40003c11 <fileino_read>:
40003c11:	55                   	push   %ebp
40003c12:	89 e5                	mov    %esp,%ebp
40003c14:	83 ec 38             	sub    $0x38,%esp
40003c17:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
40003c1b:	7e 45                	jle    40003c62 <fileino_read+0x51>
40003c1d:	81 7d 08 ff 00 00 00 	cmpl   $0xff,0x8(%ebp)
40003c24:	7f 3c                	jg     40003c62 <fileino_read+0x51>
40003c26:	8b 15 34 61 00 40    	mov    0x40006134,%edx
40003c2c:	8b 45 08             	mov    0x8(%ebp),%eax
40003c2f:	6b c0 5c             	imul   $0x5c,%eax,%eax
40003c32:	01 d0                	add    %edx,%eax
40003c34:	05 10 10 00 00       	add    $0x1010,%eax
40003c39:	0f b6 40 04          	movzbl 0x4(%eax),%eax
40003c3d:	84 c0                	test   %al,%al
40003c3f:	74 21                	je     40003c62 <fileino_read+0x51>
40003c41:	8b 15 34 61 00 40    	mov    0x40006134,%edx
40003c47:	8b 45 08             	mov    0x8(%ebp),%eax
40003c4a:	6b c0 5c             	imul   $0x5c,%eax,%eax
40003c4d:	01 d0                	add    %edx,%eax
40003c4f:	05 58 10 00 00       	add    $0x1058,%eax
40003c54:	8b 00                	mov    (%eax),%eax
40003c56:	25 00 70 00 00       	and    $0x7000,%eax
40003c5b:	3d 00 10 00 00       	cmp    $0x1000,%eax
40003c60:	74 24                	je     40003c86 <fileino_read+0x75>
40003c62:	c7 44 24 0c dc 61 00 	movl   $0x400061dc,0xc(%esp)
40003c69:	40 
40003c6a:	c7 44 24 08 6f 61 00 	movl   $0x4000616f,0x8(%esp)
40003c71:	40 
40003c72:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
40003c79:	00 
40003c7a:	c7 04 24 57 61 00 40 	movl   $0x40006157,(%esp)
40003c81:	e8 52 ef ff ff       	call   40002bd8 <debug_panic>
40003c86:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
40003c8a:	79 24                	jns    40003cb0 <fileino_read+0x9f>
40003c8c:	c7 44 24 0c ef 61 00 	movl   $0x400061ef,0xc(%esp)
40003c93:	40 
40003c94:	c7 44 24 08 6f 61 00 	movl   $0x4000616f,0x8(%esp)
40003c9b:	40 
40003c9c:	c7 44 24 04 59 00 00 	movl   $0x59,0x4(%esp)
40003ca3:	00 
40003ca4:	c7 04 24 57 61 00 40 	movl   $0x40006157,(%esp)
40003cab:	e8 28 ef ff ff       	call   40002bd8 <debug_panic>
40003cb0:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
40003cb4:	75 24                	jne    40003cda <fileino_read+0xc9>
40003cb6:	c7 44 24 0c f8 61 00 	movl   $0x400061f8,0xc(%esp)
40003cbd:	40 
40003cbe:	c7 44 24 08 6f 61 00 	movl   $0x4000616f,0x8(%esp)
40003cc5:	40 
40003cc6:	c7 44 24 04 5a 00 00 	movl   $0x5a,0x4(%esp)
40003ccd:	00 
40003cce:	c7 04 24 57 61 00 40 	movl   $0x40006157,(%esp)
40003cd5:	e8 fe ee ff ff       	call   40002bd8 <debug_panic>
40003cda:	a1 34 61 00 40       	mov    0x40006134,%eax
40003cdf:	8d 90 10 10 00 00    	lea    0x1010(%eax),%edx
40003ce5:	8b 45 08             	mov    0x8(%ebp),%eax
40003ce8:	6b c0 5c             	imul   $0x5c,%eax,%eax
40003ceb:	8d 04 02             	lea    (%edx,%eax,1),%eax
40003cee:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
40003cf1:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
40003cf4:	8b 40 4c             	mov    0x4c(%eax),%eax
40003cf7:	3d 00 00 40 00       	cmp    $0x400000,%eax
40003cfc:	76 24                	jbe    40003d22 <fileino_read+0x111>
40003cfe:	c7 44 24 0c 04 62 00 	movl   $0x40006204,0xc(%esp)
40003d05:	40 
40003d06:	c7 44 24 08 6f 61 00 	movl   $0x4000616f,0x8(%esp)
40003d0d:	40 
40003d0e:	c7 44 24 04 60 00 00 	movl   $0x60,0x4(%esp)
40003d15:	00 
40003d16:	c7 04 24 57 61 00 40 	movl   $0x40006157,(%esp)
40003d1d:	e8 b6 ee ff ff       	call   40002bd8 <debug_panic>
40003d22:	c7 45 f0 00 00 00 00 	movl   $0x0,0xfffffff0(%ebp)
40003d29:	e9 ba 00 00 00       	jmp    40003de8 <fileino_read+0x1d7>
40003d2e:	8b 45 18             	mov    0x18(%ebp),%eax
40003d31:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
40003d34:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
40003d37:	8b 50 4c             	mov    0x4c(%eax),%edx
40003d3a:	8b 45 0c             	mov    0xc(%ebp),%eax
40003d3d:	89 d1                	mov    %edx,%ecx
40003d3f:	29 c1                	sub    %eax,%ecx
40003d41:	89 c8                	mov    %ecx,%eax
40003d43:	ba 00 00 00 00       	mov    $0x0,%edx
40003d48:	f7 75 14             	divl   0x14(%ebp)
40003d4b:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
40003d4e:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
40003d51:	89 45 d8             	mov    %eax,0xffffffd8(%ebp)
40003d54:	8b 4d f8             	mov    0xfffffff8(%ebp),%ecx
40003d57:	89 4d dc             	mov    %ecx,0xffffffdc(%ebp)
40003d5a:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
40003d5d:	39 45 dc             	cmp    %eax,0xffffffdc(%ebp)
40003d60:	76 06                	jbe    40003d68 <fileino_read+0x157>
40003d62:	8b 4d d8             	mov    0xffffffd8(%ebp),%ecx
40003d65:	89 4d dc             	mov    %ecx,0xffffffdc(%ebp)
40003d68:	8b 45 dc             	mov    0xffffffdc(%ebp),%eax
40003d6b:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
40003d6e:	8b 45 0c             	mov    0xc(%ebp),%eax
40003d71:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
40003d74:	8b 52 4c             	mov    0x4c(%edx),%edx
40003d77:	39 d0                	cmp    %edx,%eax
40003d79:	72 07                	jb     40003d82 <fileino_read+0x171>
40003d7b:	c7 45 f4 00 00 00 00 	movl   $0x0,0xfffffff4(%ebp)
40003d82:	83 7d f4 00          	cmpl   $0x0,0xfffffff4(%ebp)
40003d86:	7e 44                	jle    40003dcc <fileino_read+0x1bb>
40003d88:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
40003d8b:	89 c1                	mov    %eax,%ecx
40003d8d:	0f af 4d 14          	imul   0x14(%ebp),%ecx
40003d91:	8b 45 08             	mov    0x8(%ebp),%eax
40003d94:	c1 e0 16             	shl    $0x16,%eax
40003d97:	8d 90 00 00 00 80    	lea    0x80000000(%eax),%edx
40003d9d:	8b 45 0c             	mov    0xc(%ebp),%eax
40003da0:	8d 04 02             	lea    (%edx,%eax,1),%eax
40003da3:	89 4c 24 08          	mov    %ecx,0x8(%esp)
40003da7:	89 44 24 04          	mov    %eax,0x4(%esp)
40003dab:	8b 45 10             	mov    0x10(%ebp),%eax
40003dae:	89 04 24             	mov    %eax,(%esp)
40003db1:	e8 5c fa ff ff       	call   40003812 <memmove>
40003db6:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
40003db9:	0f af 45 14          	imul   0x14(%ebp),%eax
40003dbd:	01 45 10             	add    %eax,0x10(%ebp)
40003dc0:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
40003dc3:	01 45 f0             	add    %eax,0xfffffff0(%ebp)
40003dc6:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
40003dc9:	29 45 18             	sub    %eax,0x18(%ebp)
40003dcc:	83 7d 18 00          	cmpl   $0x0,0x18(%ebp)
40003dd0:	74 20                	je     40003df2 <fileino_read+0x1e1>
40003dd2:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
40003dd5:	8b 40 48             	mov    0x48(%eax),%eax
40003dd8:	25 00 80 00 00       	and    $0x8000,%eax
40003ddd:	85 c0                	test   %eax,%eax
40003ddf:	74 11                	je     40003df2 <fileino_read+0x1e1>
40003de1:	b8 03 00 00 00       	mov    $0x3,%eax
40003de6:	cd 30                	int    $0x30
40003de8:	83 7d 18 00          	cmpl   $0x0,0x18(%ebp)
40003dec:	0f 85 3c ff ff ff    	jne    40003d2e <fileino_read+0x11d>
40003df2:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
40003df5:	c9                   	leave  
40003df6:	c3                   	ret    

40003df7 <fileino_write>:
40003df7:	55                   	push   %ebp
40003df8:	89 e5                	mov    %esp,%ebp
40003dfa:	57                   	push   %edi
40003dfb:	56                   	push   %esi
40003dfc:	53                   	push   %ebx
40003dfd:	83 ec 5c             	sub    $0x5c,%esp
40003e00:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
40003e04:	7e 45                	jle    40003e4b <fileino_write+0x54>
40003e06:	81 7d 08 ff 00 00 00 	cmpl   $0xff,0x8(%ebp)
40003e0d:	7f 3c                	jg     40003e4b <fileino_write+0x54>
40003e0f:	8b 15 34 61 00 40    	mov    0x40006134,%edx
40003e15:	8b 45 08             	mov    0x8(%ebp),%eax
40003e18:	6b c0 5c             	imul   $0x5c,%eax,%eax
40003e1b:	01 d0                	add    %edx,%eax
40003e1d:	05 10 10 00 00       	add    $0x1010,%eax
40003e22:	0f b6 40 04          	movzbl 0x4(%eax),%eax
40003e26:	84 c0                	test   %al,%al
40003e28:	74 21                	je     40003e4b <fileino_write+0x54>
40003e2a:	8b 15 34 61 00 40    	mov    0x40006134,%edx
40003e30:	8b 45 08             	mov    0x8(%ebp),%eax
40003e33:	6b c0 5c             	imul   $0x5c,%eax,%eax
40003e36:	01 d0                	add    %edx,%eax
40003e38:	05 58 10 00 00       	add    $0x1058,%eax
40003e3d:	8b 00                	mov    (%eax),%eax
40003e3f:	25 00 70 00 00       	and    $0x7000,%eax
40003e44:	3d 00 10 00 00       	cmp    $0x1000,%eax
40003e49:	74 24                	je     40003e6f <fileino_write+0x78>
40003e4b:	c7 44 24 0c dc 61 00 	movl   $0x400061dc,0xc(%esp)
40003e52:	40 
40003e53:	c7 44 24 08 6f 61 00 	movl   $0x4000616f,0x8(%esp)
40003e5a:	40 
40003e5b:	c7 44 24 04 94 00 00 	movl   $0x94,0x4(%esp)
40003e62:	00 
40003e63:	c7 04 24 57 61 00 40 	movl   $0x40006157,(%esp)
40003e6a:	e8 69 ed ff ff       	call   40002bd8 <debug_panic>
40003e6f:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
40003e73:	79 24                	jns    40003e99 <fileino_write+0xa2>
40003e75:	c7 44 24 0c ef 61 00 	movl   $0x400061ef,0xc(%esp)
40003e7c:	40 
40003e7d:	c7 44 24 08 6f 61 00 	movl   $0x4000616f,0x8(%esp)
40003e84:	40 
40003e85:	c7 44 24 04 95 00 00 	movl   $0x95,0x4(%esp)
40003e8c:	00 
40003e8d:	c7 04 24 57 61 00 40 	movl   $0x40006157,(%esp)
40003e94:	e8 3f ed ff ff       	call   40002bd8 <debug_panic>
40003e99:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
40003e9d:	75 24                	jne    40003ec3 <fileino_write+0xcc>
40003e9f:	c7 44 24 0c f8 61 00 	movl   $0x400061f8,0xc(%esp)
40003ea6:	40 
40003ea7:	c7 44 24 08 6f 61 00 	movl   $0x4000616f,0x8(%esp)
40003eae:	40 
40003eaf:	c7 44 24 04 96 00 00 	movl   $0x96,0x4(%esp)
40003eb6:	00 
40003eb7:	c7 04 24 57 61 00 40 	movl   $0x40006157,(%esp)
40003ebe:	e8 15 ed ff ff       	call   40002bd8 <debug_panic>
40003ec3:	a1 34 61 00 40       	mov    0x40006134,%eax
40003ec8:	8d 90 10 10 00 00    	lea    0x1010(%eax),%edx
40003ece:	8b 45 08             	mov    0x8(%ebp),%eax
40003ed1:	6b c0 5c             	imul   $0x5c,%eax,%eax
40003ed4:	8d 04 02             	lea    (%edx,%eax,1),%eax
40003ed7:	89 45 b8             	mov    %eax,0xffffffb8(%ebp)
40003eda:	8b 45 b8             	mov    0xffffffb8(%ebp),%eax
40003edd:	8b 40 4c             	mov    0x4c(%eax),%eax
40003ee0:	3d 00 00 40 00       	cmp    $0x400000,%eax
40003ee5:	76 24                	jbe    40003f0b <fileino_write+0x114>
40003ee7:	c7 44 24 0c 04 62 00 	movl   $0x40006204,0xc(%esp)
40003eee:	40 
40003eef:	c7 44 24 08 6f 61 00 	movl   $0x4000616f,0x8(%esp)
40003ef6:	40 
40003ef7:	c7 44 24 04 99 00 00 	movl   $0x99,0x4(%esp)
40003efe:	00 
40003eff:	c7 04 24 57 61 00 40 	movl   $0x40006157,(%esp)
40003f06:	e8 cd ec ff ff       	call   40002bd8 <debug_panic>
40003f0b:	8b 45 14             	mov    0x14(%ebp),%eax
40003f0e:	0f af 45 18          	imul   0x18(%ebp),%eax
40003f12:	89 45 bc             	mov    %eax,0xffffffbc(%ebp)
40003f15:	8b 45 0c             	mov    0xc(%ebp),%eax
40003f18:	03 45 bc             	add    0xffffffbc(%ebp),%eax
40003f1b:	89 45 c0             	mov    %eax,0xffffffc0(%ebp)
40003f1e:	8b 45 0c             	mov    0xc(%ebp),%eax
40003f21:	3b 45 c0             	cmp    0xffffffc0(%ebp),%eax
40003f24:	77 09                	ja     40003f2f <fileino_write+0x138>
40003f26:	81 7d c0 00 00 40 00 	cmpl   $0x400000,0xffffffc0(%ebp)
40003f2d:	76 17                	jbe    40003f46 <fileino_write+0x14f>
40003f2f:	a1 34 61 00 40       	mov    0x40006134,%eax
40003f34:	c7 00 03 00 00 00    	movl   $0x3,(%eax)
40003f3a:	c7 45 b0 ff ff ff ff 	movl   $0xffffffff,0xffffffb0(%ebp)
40003f41:	e9 f1 00 00 00       	jmp    40004037 <fileino_write+0x240>
40003f46:	8b 45 b8             	mov    0xffffffb8(%ebp),%eax
40003f49:	8b 40 4c             	mov    0x4c(%eax),%eax
40003f4c:	3b 45 c0             	cmp    0xffffffc0(%ebp),%eax
40003f4f:	0f 83 b5 00 00 00    	jae    4000400a <fileino_write+0x213>
40003f55:	c7 45 cc 00 10 00 00 	movl   $0x1000,0xffffffcc(%ebp)
40003f5c:	8b 45 b8             	mov    0xffffffb8(%ebp),%eax
40003f5f:	8b 40 4c             	mov    0x4c(%eax),%eax
40003f62:	03 45 cc             	add    0xffffffcc(%ebp),%eax
40003f65:	83 e8 01             	sub    $0x1,%eax
40003f68:	89 45 d0             	mov    %eax,0xffffffd0(%ebp)
40003f6b:	8b 45 d0             	mov    0xffffffd0(%ebp),%eax
40003f6e:	ba 00 00 00 00       	mov    $0x0,%edx
40003f73:	f7 75 cc             	divl   0xffffffcc(%ebp)
40003f76:	8b 45 d0             	mov    0xffffffd0(%ebp),%eax
40003f79:	29 d0                	sub    %edx,%eax
40003f7b:	89 45 c4             	mov    %eax,0xffffffc4(%ebp)
40003f7e:	c7 45 d4 00 10 00 00 	movl   $0x1000,0xffffffd4(%ebp)
40003f85:	8b 45 d4             	mov    0xffffffd4(%ebp),%eax
40003f88:	03 45 c0             	add    0xffffffc0(%ebp),%eax
40003f8b:	83 e8 01             	sub    $0x1,%eax
40003f8e:	89 45 d8             	mov    %eax,0xffffffd8(%ebp)
40003f91:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
40003f94:	ba 00 00 00 00       	mov    $0x0,%edx
40003f99:	f7 75 d4             	divl   0xffffffd4(%ebp)
40003f9c:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
40003f9f:	29 d0                	sub    %edx,%eax
40003fa1:	89 45 c8             	mov    %eax,0xffffffc8(%ebp)
40003fa4:	8b 45 c8             	mov    0xffffffc8(%ebp),%eax
40003fa7:	3b 45 c4             	cmp    0xffffffc4(%ebp),%eax
40003faa:	76 55                	jbe    40004001 <fileino_write+0x20a>
40003fac:	8b 55 c4             	mov    0xffffffc4(%ebp),%edx
40003faf:	8b 45 c8             	mov    0xffffffc8(%ebp),%eax
40003fb2:	89 c1                	mov    %eax,%ecx
40003fb4:	29 d1                	sub    %edx,%ecx
40003fb6:	8b 45 08             	mov    0x8(%ebp),%eax
40003fb9:	c1 e0 16             	shl    $0x16,%eax
40003fbc:	8d 90 00 00 00 80    	lea    0x80000000(%eax),%edx
40003fc2:	8b 45 c4             	mov    0xffffffc4(%ebp),%eax
40003fc5:	8d 04 02             	lea    (%edx,%eax,1),%eax
40003fc8:	c7 45 f0 00 07 00 00 	movl   $0x700,0xfffffff0(%ebp)
40003fcf:	66 c7 45 ee 00 00    	movw   $0x0,0xffffffee(%ebp)
40003fd5:	c7 45 e8 00 00 00 00 	movl   $0x0,0xffffffe8(%ebp)
40003fdc:	c7 45 e4 00 00 00 00 	movl   $0x0,0xffffffe4(%ebp)
40003fe3:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)
40003fe6:	89 4d dc             	mov    %ecx,0xffffffdc(%ebp)
40003fe9:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
40003fec:	83 c8 02             	or     $0x2,%eax
40003fef:	8b 5d e8             	mov    0xffffffe8(%ebp),%ebx
40003ff2:	0f b7 55 ee          	movzwl 0xffffffee(%ebp),%edx
40003ff6:	8b 75 e4             	mov    0xffffffe4(%ebp),%esi
40003ff9:	8b 7d e0             	mov    0xffffffe0(%ebp),%edi
40003ffc:	8b 4d dc             	mov    0xffffffdc(%ebp),%ecx
40003fff:	cd 30                	int    $0x30
40004001:	8b 55 b8             	mov    0xffffffb8(%ebp),%edx
40004004:	8b 45 c0             	mov    0xffffffc0(%ebp),%eax
40004007:	89 42 4c             	mov    %eax,0x4c(%edx)
4000400a:	8b 45 08             	mov    0x8(%ebp),%eax
4000400d:	c1 e0 16             	shl    $0x16,%eax
40004010:	8d 90 00 00 00 80    	lea    0x80000000(%eax),%edx
40004016:	8b 45 0c             	mov    0xc(%ebp),%eax
40004019:	01 c2                	add    %eax,%edx
4000401b:	8b 45 bc             	mov    0xffffffbc(%ebp),%eax
4000401e:	89 44 24 08          	mov    %eax,0x8(%esp)
40004022:	8b 45 10             	mov    0x10(%ebp),%eax
40004025:	89 44 24 04          	mov    %eax,0x4(%esp)
40004029:	89 14 24             	mov    %edx,(%esp)
4000402c:	e8 e1 f7 ff ff       	call   40003812 <memmove>
40004031:	8b 45 18             	mov    0x18(%ebp),%eax
40004034:	89 45 b0             	mov    %eax,0xffffffb0(%ebp)
40004037:	8b 45 b0             	mov    0xffffffb0(%ebp),%eax
4000403a:	83 c4 5c             	add    $0x5c,%esp
4000403d:	5b                   	pop    %ebx
4000403e:	5e                   	pop    %esi
4000403f:	5f                   	pop    %edi
40004040:	5d                   	pop    %ebp
40004041:	c3                   	ret    

40004042 <fileino_stat>:
40004042:	55                   	push   %ebp
40004043:	89 e5                	mov    %esp,%ebp
40004045:	83 ec 28             	sub    $0x28,%esp
40004048:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
4000404c:	7e 3d                	jle    4000408b <fileino_stat+0x49>
4000404e:	81 7d 08 ff 00 00 00 	cmpl   $0xff,0x8(%ebp)
40004055:	7f 34                	jg     4000408b <fileino_stat+0x49>
40004057:	8b 15 34 61 00 40    	mov    0x40006134,%edx
4000405d:	8b 45 08             	mov    0x8(%ebp),%eax
40004060:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004063:	01 d0                	add    %edx,%eax
40004065:	05 10 10 00 00       	add    $0x1010,%eax
4000406a:	0f b6 40 04          	movzbl 0x4(%eax),%eax
4000406e:	84 c0                	test   %al,%al
40004070:	74 19                	je     4000408b <fileino_stat+0x49>
40004072:	8b 15 34 61 00 40    	mov    0x40006134,%edx
40004078:	8b 45 08             	mov    0x8(%ebp),%eax
4000407b:	6b c0 5c             	imul   $0x5c,%eax,%eax
4000407e:	01 d0                	add    %edx,%eax
40004080:	05 58 10 00 00       	add    $0x1058,%eax
40004085:	8b 00                	mov    (%eax),%eax
40004087:	85 c0                	test   %eax,%eax
40004089:	75 24                	jne    400040af <fileino_stat+0x6d>
4000408b:	c7 44 24 0c 1d 62 00 	movl   $0x4000621d,0xc(%esp)
40004092:	40 
40004093:	c7 44 24 08 6f 61 00 	movl   $0x4000616f,0x8(%esp)
4000409a:	40 
4000409b:	c7 44 24 04 c0 00 00 	movl   $0xc0,0x4(%esp)
400040a2:	00 
400040a3:	c7 04 24 57 61 00 40 	movl   $0x40006157,(%esp)
400040aa:	e8 29 eb ff ff       	call   40002bd8 <debug_panic>
400040af:	a1 34 61 00 40       	mov    0x40006134,%eax
400040b4:	8d 90 10 10 00 00    	lea    0x1010(%eax),%edx
400040ba:	8b 45 08             	mov    0x8(%ebp),%eax
400040bd:	6b c0 5c             	imul   $0x5c,%eax,%eax
400040c0:	8d 04 02             	lea    (%edx,%eax,1),%eax
400040c3:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
400040c6:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
400040c9:	8b 00                	mov    (%eax),%eax
400040cb:	85 c0                	test   %eax,%eax
400040cd:	7e 4c                	jle    4000411b <fileino_stat+0xd9>
400040cf:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
400040d2:	8b 00                	mov    (%eax),%eax
400040d4:	3d ff 00 00 00       	cmp    $0xff,%eax
400040d9:	7f 40                	jg     4000411b <fileino_stat+0xd9>
400040db:	8b 15 34 61 00 40    	mov    0x40006134,%edx
400040e1:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
400040e4:	8b 00                	mov    (%eax),%eax
400040e6:	6b c0 5c             	imul   $0x5c,%eax,%eax
400040e9:	01 d0                	add    %edx,%eax
400040eb:	05 10 10 00 00       	add    $0x1010,%eax
400040f0:	0f b6 40 04          	movzbl 0x4(%eax),%eax
400040f4:	84 c0                	test   %al,%al
400040f6:	74 23                	je     4000411b <fileino_stat+0xd9>
400040f8:	8b 15 34 61 00 40    	mov    0x40006134,%edx
400040fe:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
40004101:	8b 00                	mov    (%eax),%eax
40004103:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004106:	01 d0                	add    %edx,%eax
40004108:	05 58 10 00 00       	add    $0x1058,%eax
4000410d:	8b 00                	mov    (%eax),%eax
4000410f:	25 00 70 00 00       	and    $0x7000,%eax
40004114:	3d 00 20 00 00       	cmp    $0x2000,%eax
40004119:	74 24                	je     4000413f <fileino_stat+0xfd>
4000411b:	c7 44 24 0c 31 62 00 	movl   $0x40006231,0xc(%esp)
40004122:	40 
40004123:	c7 44 24 08 6f 61 00 	movl   $0x4000616f,0x8(%esp)
4000412a:	40 
4000412b:	c7 44 24 04 c3 00 00 	movl   $0xc3,0x4(%esp)
40004132:	00 
40004133:	c7 04 24 57 61 00 40 	movl   $0x40006157,(%esp)
4000413a:	e8 99 ea ff ff       	call   40002bd8 <debug_panic>
4000413f:	8b 55 0c             	mov    0xc(%ebp),%edx
40004142:	8b 45 08             	mov    0x8(%ebp),%eax
40004145:	89 02                	mov    %eax,(%edx)
40004147:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
4000414a:	8b 50 48             	mov    0x48(%eax),%edx
4000414d:	8b 45 0c             	mov    0xc(%ebp),%eax
40004150:	89 50 04             	mov    %edx,0x4(%eax)
40004153:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
40004156:	8b 40 4c             	mov    0x4c(%eax),%eax
40004159:	89 c2                	mov    %eax,%edx
4000415b:	8b 45 0c             	mov    0xc(%ebp),%eax
4000415e:	89 50 08             	mov    %edx,0x8(%eax)
40004161:	b8 00 00 00 00       	mov    $0x0,%eax
40004166:	c9                   	leave  
40004167:	c3                   	ret    

40004168 <fileino_truncate>:
40004168:	55                   	push   %ebp
40004169:	89 e5                	mov    %esp,%ebp
4000416b:	57                   	push   %edi
4000416c:	56                   	push   %esi
4000416d:	53                   	push   %ebx
4000416e:	81 ec 8c 00 00 00    	sub    $0x8c,%esp
40004174:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
40004178:	7e 09                	jle    40004183 <fileino_truncate+0x1b>
4000417a:	81 7d 08 ff 00 00 00 	cmpl   $0xff,0x8(%ebp)
40004181:	7e 24                	jle    400041a7 <fileino_truncate+0x3f>
40004183:	c7 44 24 0c 49 62 00 	movl   $0x40006249,0xc(%esp)
4000418a:	40 
4000418b:	c7 44 24 08 6f 61 00 	movl   $0x4000616f,0x8(%esp)
40004192:	40 
40004193:	c7 44 24 04 d4 00 00 	movl   $0xd4,0x4(%esp)
4000419a:	00 
4000419b:	c7 04 24 57 61 00 40 	movl   $0x40006157,(%esp)
400041a2:	e8 31 ea ff ff       	call   40002bd8 <debug_panic>
400041a7:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
400041ab:	78 09                	js     400041b6 <fileino_truncate+0x4e>
400041ad:	81 7d 0c 00 00 40 00 	cmpl   $0x400000,0xc(%ebp)
400041b4:	7e 24                	jle    400041da <fileino_truncate+0x72>
400041b6:	c7 44 24 0c 60 62 00 	movl   $0x40006260,0xc(%esp)
400041bd:	40 
400041be:	c7 44 24 08 6f 61 00 	movl   $0x4000616f,0x8(%esp)
400041c5:	40 
400041c6:	c7 44 24 04 d5 00 00 	movl   $0xd5,0x4(%esp)
400041cd:	00 
400041ce:	c7 04 24 57 61 00 40 	movl   $0x40006157,(%esp)
400041d5:	e8 fe e9 ff ff       	call   40002bd8 <debug_panic>
400041da:	8b 15 34 61 00 40    	mov    0x40006134,%edx
400041e0:	8b 45 08             	mov    0x8(%ebp),%eax
400041e3:	6b c0 5c             	imul   $0x5c,%eax,%eax
400041e6:	01 d0                	add    %edx,%eax
400041e8:	05 5c 10 00 00       	add    $0x105c,%eax
400041ed:	8b 00                	mov    (%eax),%eax
400041ef:	89 45 90             	mov    %eax,0xffffff90(%ebp)
400041f2:	c7 45 9c 00 10 00 00 	movl   $0x1000,0xffffff9c(%ebp)
400041f9:	8b 15 34 61 00 40    	mov    0x40006134,%edx
400041ff:	8b 45 08             	mov    0x8(%ebp),%eax
40004202:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004205:	01 d0                	add    %edx,%eax
40004207:	05 5c 10 00 00       	add    $0x105c,%eax
4000420c:	8b 00                	mov    (%eax),%eax
4000420e:	03 45 9c             	add    0xffffff9c(%ebp),%eax
40004211:	83 e8 01             	sub    $0x1,%eax
40004214:	89 45 a0             	mov    %eax,0xffffffa0(%ebp)
40004217:	8b 45 a0             	mov    0xffffffa0(%ebp),%eax
4000421a:	ba 00 00 00 00       	mov    $0x0,%edx
4000421f:	f7 75 9c             	divl   0xffffff9c(%ebp)
40004222:	8b 45 a0             	mov    0xffffffa0(%ebp),%eax
40004225:	29 d0                	sub    %edx,%eax
40004227:	89 45 94             	mov    %eax,0xffffff94(%ebp)
4000422a:	c7 45 a4 00 10 00 00 	movl   $0x1000,0xffffffa4(%ebp)
40004231:	8b 45 0c             	mov    0xc(%ebp),%eax
40004234:	03 45 a4             	add    0xffffffa4(%ebp),%eax
40004237:	83 e8 01             	sub    $0x1,%eax
4000423a:	89 45 a8             	mov    %eax,0xffffffa8(%ebp)
4000423d:	8b 45 a8             	mov    0xffffffa8(%ebp),%eax
40004240:	ba 00 00 00 00       	mov    $0x0,%edx
40004245:	f7 75 a4             	divl   0xffffffa4(%ebp)
40004248:	8b 45 a8             	mov    0xffffffa8(%ebp),%eax
4000424b:	29 d0                	sub    %edx,%eax
4000424d:	89 45 98             	mov    %eax,0xffffff98(%ebp)
40004250:	8b 45 0c             	mov    0xc(%ebp),%eax
40004253:	3b 45 90             	cmp    0xffffff90(%ebp),%eax
40004256:	0f 86 88 00 00 00    	jbe    400042e4 <fileino_truncate+0x17c>
4000425c:	8b 55 94             	mov    0xffffff94(%ebp),%edx
4000425f:	8b 45 98             	mov    0xffffff98(%ebp),%eax
40004262:	89 c1                	mov    %eax,%ecx
40004264:	29 d1                	sub    %edx,%ecx
40004266:	8b 45 08             	mov    0x8(%ebp),%eax
40004269:	c1 e0 16             	shl    $0x16,%eax
4000426c:	8d 90 00 00 00 80    	lea    0x80000000(%eax),%edx
40004272:	8b 45 94             	mov    0xffffff94(%ebp),%eax
40004275:	8d 04 02             	lea    (%edx,%eax,1),%eax
40004278:	c7 45 c0 00 07 00 00 	movl   $0x700,0xffffffc0(%ebp)
4000427f:	66 c7 45 be 00 00    	movw   $0x0,0xffffffbe(%ebp)
40004285:	c7 45 b8 00 00 00 00 	movl   $0x0,0xffffffb8(%ebp)
4000428c:	c7 45 b4 00 00 00 00 	movl   $0x0,0xffffffb4(%ebp)
40004293:	89 45 b0             	mov    %eax,0xffffffb0(%ebp)
40004296:	89 4d ac             	mov    %ecx,0xffffffac(%ebp)
40004299:	8b 45 c0             	mov    0xffffffc0(%ebp),%eax
4000429c:	83 c8 02             	or     $0x2,%eax
4000429f:	8b 5d b8             	mov    0xffffffb8(%ebp),%ebx
400042a2:	0f b7 55 be          	movzwl 0xffffffbe(%ebp),%edx
400042a6:	8b 75 b4             	mov    0xffffffb4(%ebp),%esi
400042a9:	8b 7d b0             	mov    0xffffffb0(%ebp),%edi
400042ac:	8b 4d ac             	mov    0xffffffac(%ebp),%ecx
400042af:	cd 30                	int    $0x30
400042b1:	8b 45 0c             	mov    0xc(%ebp),%eax
400042b4:	89 c1                	mov    %eax,%ecx
400042b6:	2b 4d 90             	sub    0xffffff90(%ebp),%ecx
400042b9:	8b 45 08             	mov    0x8(%ebp),%eax
400042bc:	c1 e0 16             	shl    $0x16,%eax
400042bf:	8d 90 00 00 00 80    	lea    0x80000000(%eax),%edx
400042c5:	8b 45 90             	mov    0xffffff90(%ebp),%eax
400042c8:	8d 04 02             	lea    (%edx,%eax,1),%eax
400042cb:	89 4c 24 08          	mov    %ecx,0x8(%esp)
400042cf:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400042d6:	00 
400042d7:	89 04 24             	mov    %eax,(%esp)
400042da:	e8 ba f4 ff ff       	call   40003799 <memset>
400042df:	e9 a5 00 00 00       	jmp    40004389 <fileino_truncate+0x221>
400042e4:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
400042e8:	7e 57                	jle    40004341 <fileino_truncate+0x1d9>
400042ea:	b8 00 00 40 00       	mov    $0x400000,%eax
400042ef:	89 c1                	mov    %eax,%ecx
400042f1:	2b 4d 98             	sub    0xffffff98(%ebp),%ecx
400042f4:	8b 45 08             	mov    0x8(%ebp),%eax
400042f7:	c1 e0 16             	shl    $0x16,%eax
400042fa:	8d 90 00 00 00 80    	lea    0x80000000(%eax),%edx
40004300:	8b 45 98             	mov    0xffffff98(%ebp),%eax
40004303:	8d 04 02             	lea    (%edx,%eax,1),%eax
40004306:	c7 45 d8 00 01 00 00 	movl   $0x100,0xffffffd8(%ebp)
4000430d:	66 c7 45 d6 00 00    	movw   $0x0,0xffffffd6(%ebp)
40004313:	c7 45 d0 00 00 00 00 	movl   $0x0,0xffffffd0(%ebp)
4000431a:	c7 45 cc 00 00 00 00 	movl   $0x0,0xffffffcc(%ebp)
40004321:	89 45 c8             	mov    %eax,0xffffffc8(%ebp)
40004324:	89 4d c4             	mov    %ecx,0xffffffc4(%ebp)
40004327:	8b 45 d8             	mov    0xffffffd8(%ebp),%eax
4000432a:	83 c8 02             	or     $0x2,%eax
4000432d:	8b 5d d0             	mov    0xffffffd0(%ebp),%ebx
40004330:	0f b7 55 d6          	movzwl 0xffffffd6(%ebp),%edx
40004334:	8b 75 cc             	mov    0xffffffcc(%ebp),%esi
40004337:	8b 7d c8             	mov    0xffffffc8(%ebp),%edi
4000433a:	8b 4d c4             	mov    0xffffffc4(%ebp),%ecx
4000433d:	cd 30                	int    $0x30
4000433f:	eb 48                	jmp    40004389 <fileino_truncate+0x221>
40004341:	8b 45 08             	mov    0x8(%ebp),%eax
40004344:	c1 e0 16             	shl    $0x16,%eax
40004347:	2d 00 00 00 80       	sub    $0x80000000,%eax
4000434c:	c7 45 f0 00 00 01 00 	movl   $0x10000,0xfffffff0(%ebp)
40004353:	66 c7 45 ee 00 00    	movw   $0x0,0xffffffee(%ebp)
40004359:	c7 45 e8 00 00 00 00 	movl   $0x0,0xffffffe8(%ebp)
40004360:	c7 45 e4 00 00 00 00 	movl   $0x0,0xffffffe4(%ebp)
40004367:	89 45 e0             	mov    %eax,0xffffffe0(%ebp)
4000436a:	c7 45 dc 00 00 40 00 	movl   $0x400000,0xffffffdc(%ebp)
40004371:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
40004374:	83 c8 02             	or     $0x2,%eax
40004377:	8b 5d e8             	mov    0xffffffe8(%ebp),%ebx
4000437a:	0f b7 55 ee          	movzwl 0xffffffee(%ebp),%edx
4000437e:	8b 75 e4             	mov    0xffffffe4(%ebp),%esi
40004381:	8b 7d e0             	mov    0xffffffe0(%ebp),%edi
40004384:	8b 4d dc             	mov    0xffffffdc(%ebp),%ecx
40004387:	cd 30                	int    $0x30
40004389:	8b 15 34 61 00 40    	mov    0x40006134,%edx
4000438f:	8b 45 08             	mov    0x8(%ebp),%eax
40004392:	8b 4d 0c             	mov    0xc(%ebp),%ecx
40004395:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004398:	01 d0                	add    %edx,%eax
4000439a:	05 5c 10 00 00       	add    $0x105c,%eax
4000439f:	89 08                	mov    %ecx,(%eax)
400043a1:	8b 1d 34 61 00 40    	mov    0x40006134,%ebx
400043a7:	8b 55 08             	mov    0x8(%ebp),%edx
400043aa:	6b c2 5c             	imul   $0x5c,%edx,%eax
400043ad:	01 d8                	add    %ebx,%eax
400043af:	05 54 10 00 00       	add    $0x1054,%eax
400043b4:	8b 00                	mov    (%eax),%eax
400043b6:	8d 48 01             	lea    0x1(%eax),%ecx
400043b9:	6b c2 5c             	imul   $0x5c,%edx,%eax
400043bc:	01 d8                	add    %ebx,%eax
400043be:	05 54 10 00 00       	add    $0x1054,%eax
400043c3:	89 08                	mov    %ecx,(%eax)
400043c5:	b8 00 00 00 00       	mov    $0x0,%eax
400043ca:	81 c4 8c 00 00 00    	add    $0x8c,%esp
400043d0:	5b                   	pop    %ebx
400043d1:	5e                   	pop    %esi
400043d2:	5f                   	pop    %edi
400043d3:	5d                   	pop    %ebp
400043d4:	c3                   	ret    

400043d5 <fileino_flush>:
400043d5:	55                   	push   %ebp
400043d6:	89 e5                	mov    %esp,%ebp
400043d8:	83 ec 18             	sub    $0x18,%esp
400043db:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
400043df:	7e 09                	jle    400043ea <fileino_flush+0x15>
400043e1:	81 7d 08 ff 00 00 00 	cmpl   $0xff,0x8(%ebp)
400043e8:	7e 24                	jle    4000440e <fileino_flush+0x39>
400043ea:	c7 44 24 0c 49 62 00 	movl   $0x40006249,0xc(%esp)
400043f1:	40 
400043f2:	c7 44 24 08 6f 61 00 	movl   $0x4000616f,0x8(%esp)
400043f9:	40 
400043fa:	c7 44 24 04 f4 00 00 	movl   $0xf4,0x4(%esp)
40004401:	00 
40004402:	c7 04 24 57 61 00 40 	movl   $0x40006157,(%esp)
40004409:	e8 ca e7 ff ff       	call   40002bd8 <debug_panic>
4000440e:	8b 15 34 61 00 40    	mov    0x40006134,%edx
40004414:	8b 45 08             	mov    0x8(%ebp),%eax
40004417:	6b c0 5c             	imul   $0x5c,%eax,%eax
4000441a:	01 d0                	add    %edx,%eax
4000441c:	05 5c 10 00 00       	add    $0x105c,%eax
40004421:	8b 08                	mov    (%eax),%ecx
40004423:	8b 15 34 61 00 40    	mov    0x40006134,%edx
40004429:	8b 45 08             	mov    0x8(%ebp),%eax
4000442c:	6b c0 5c             	imul   $0x5c,%eax,%eax
4000442f:	01 d0                	add    %edx,%eax
40004431:	05 68 10 00 00       	add    $0x1068,%eax
40004436:	8b 00                	mov    (%eax),%eax
40004438:	39 c1                	cmp    %eax,%ecx
4000443a:	76 07                	jbe    40004443 <fileino_flush+0x6e>
4000443c:	b8 03 00 00 00       	mov    $0x3,%eax
40004441:	cd 30                	int    $0x30
40004443:	b8 00 00 00 00       	mov    $0x0,%eax
40004448:	c9                   	leave  
40004449:	c3                   	ret    

4000444a <filedesc_alloc>:
4000444a:	55                   	push   %ebp
4000444b:	89 e5                	mov    %esp,%ebp
4000444d:	83 ec 14             	sub    $0x14,%esp
40004450:	c7 45 fc 00 00 00 00 	movl   $0x0,0xfffffffc(%ebp)
40004457:	eb 30                	jmp    40004489 <filedesc_alloc+0x3f>
40004459:	8b 15 34 61 00 40    	mov    0x40006134,%edx
4000445f:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
40004462:	c1 e0 04             	shl    $0x4,%eax
40004465:	01 d0                	add    %edx,%eax
40004467:	83 c0 10             	add    $0x10,%eax
4000446a:	8b 00                	mov    (%eax),%eax
4000446c:	85 c0                	test   %eax,%eax
4000446e:	75 15                	jne    40004485 <filedesc_alloc+0x3b>
40004470:	a1 34 61 00 40       	mov    0x40006134,%eax
40004475:	8d 50 10             	lea    0x10(%eax),%edx
40004478:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
4000447b:	c1 e0 04             	shl    $0x4,%eax
4000447e:	01 c2                	add    %eax,%edx
40004480:	89 55 ec             	mov    %edx,0xffffffec(%ebp)
40004483:	eb 1f                	jmp    400044a4 <filedesc_alloc+0x5a>
40004485:	83 45 fc 01          	addl   $0x1,0xfffffffc(%ebp)
40004489:	81 7d fc ff 00 00 00 	cmpl   $0xff,0xfffffffc(%ebp)
40004490:	7e c7                	jle    40004459 <filedesc_alloc+0xf>
40004492:	a1 34 61 00 40       	mov    0x40006134,%eax
40004497:	c7 00 04 00 00 00    	movl   $0x4,(%eax)
4000449d:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
400044a4:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
400044a7:	c9                   	leave  
400044a8:	c3                   	ret    

400044a9 <filedesc_open>:
400044a9:	55                   	push   %ebp
400044aa:	89 e5                	mov    %esp,%ebp
400044ac:	83 ec 38             	sub    $0x38,%esp
400044af:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
400044b3:	75 1a                	jne    400044cf <filedesc_open+0x26>
400044b5:	e8 90 ff ff ff       	call   4000444a <filedesc_alloc>
400044ba:	89 45 08             	mov    %eax,0x8(%ebp)
400044bd:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
400044c1:	75 0c                	jne    400044cf <filedesc_open+0x26>
400044c3:	c7 45 e4 00 00 00 00 	movl   $0x0,0xffffffe4(%ebp)
400044ca:	e9 24 02 00 00       	jmp    400046f3 <filedesc_open+0x24a>
400044cf:	8b 45 08             	mov    0x8(%ebp),%eax
400044d2:	8b 00                	mov    (%eax),%eax
400044d4:	85 c0                	test   %eax,%eax
400044d6:	74 24                	je     400044fc <filedesc_open+0x53>
400044d8:	c7 44 24 0c 88 62 00 	movl   $0x40006288,0xc(%esp)
400044df:	40 
400044e0:	c7 44 24 08 6f 61 00 	movl   $0x4000616f,0x8(%esp)
400044e7:	40 
400044e8:	c7 44 24 04 17 01 00 	movl   $0x117,0x4(%esp)
400044ef:	00 
400044f0:	c7 04 24 57 61 00 40 	movl   $0x40006157,(%esp)
400044f7:	e8 dc e6 ff ff       	call   40002bd8 <debug_panic>
400044fc:	8b 45 10             	mov    0x10(%ebp),%eax
400044ff:	83 e0 20             	and    $0x20,%eax
40004502:	85 c0                	test   %eax,%eax
40004504:	74 12                	je     40004518 <filedesc_open+0x6f>
40004506:	8b 45 14             	mov    0x14(%ebp),%eax
40004509:	25 ff 01 00 00       	and    $0x1ff,%eax
4000450e:	89 c2                	mov    %eax,%edx
40004510:	80 ce 10             	or     $0x10,%dh
40004513:	89 55 e8             	mov    %edx,0xffffffe8(%ebp)
40004516:	eb 07                	jmp    4000451f <filedesc_open+0x76>
40004518:	c7 45 e8 00 00 00 00 	movl   $0x0,0xffffffe8(%ebp)
4000451f:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
40004522:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
40004525:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
40004528:	89 44 24 04          	mov    %eax,0x4(%esp)
4000452c:	8b 45 0c             	mov    0xc(%ebp),%eax
4000452f:	89 04 24             	mov    %eax,(%esp)
40004532:	e8 01 06 00 00       	call   40004b38 <dir_walk>
40004537:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
4000453a:	83 7d fc 00          	cmpl   $0x0,0xfffffffc(%ebp)
4000453e:	79 0c                	jns    4000454c <filedesc_open+0xa3>
40004540:	c7 45 e4 00 00 00 00 	movl   $0x0,0xffffffe4(%ebp)
40004547:	e9 a7 01 00 00       	jmp    400046f3 <filedesc_open+0x24a>
4000454c:	83 7d fc 00          	cmpl   $0x0,0xfffffffc(%ebp)
40004550:	7e 3d                	jle    4000458f <filedesc_open+0xe6>
40004552:	81 7d fc ff 00 00 00 	cmpl   $0xff,0xfffffffc(%ebp)
40004559:	7f 34                	jg     4000458f <filedesc_open+0xe6>
4000455b:	8b 15 34 61 00 40    	mov    0x40006134,%edx
40004561:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
40004564:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004567:	01 d0                	add    %edx,%eax
40004569:	05 10 10 00 00       	add    $0x1010,%eax
4000456e:	0f b6 40 04          	movzbl 0x4(%eax),%eax
40004572:	84 c0                	test   %al,%al
40004574:	74 19                	je     4000458f <filedesc_open+0xe6>
40004576:	8b 15 34 61 00 40    	mov    0x40006134,%edx
4000457c:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
4000457f:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004582:	01 d0                	add    %edx,%eax
40004584:	05 58 10 00 00       	add    $0x1058,%eax
40004589:	8b 00                	mov    (%eax),%eax
4000458b:	85 c0                	test   %eax,%eax
4000458d:	75 24                	jne    400045b3 <filedesc_open+0x10a>
4000458f:	c7 44 24 0c 1d 62 00 	movl   $0x4000621d,0xc(%esp)
40004596:	40 
40004597:	c7 44 24 08 6f 61 00 	movl   $0x4000616f,0x8(%esp)
4000459e:	40 
4000459f:	c7 44 24 04 21 01 00 	movl   $0x121,0x4(%esp)
400045a6:	00 
400045a7:	c7 04 24 57 61 00 40 	movl   $0x40006157,(%esp)
400045ae:	e8 25 e6 ff ff       	call   40002bd8 <debug_panic>
400045b3:	8b 15 34 61 00 40    	mov    0x40006134,%edx
400045b9:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
400045bc:	6b c0 5c             	imul   $0x5c,%eax,%eax
400045bf:	01 d0                	add    %edx,%eax
400045c1:	05 58 10 00 00       	add    $0x1058,%eax
400045c6:	8b 00                	mov    (%eax),%eax
400045c8:	25 00 00 01 00       	and    $0x10000,%eax
400045cd:	85 c0                	test   %eax,%eax
400045cf:	74 17                	je     400045e8 <filedesc_open+0x13f>
400045d1:	a1 34 61 00 40       	mov    0x40006134,%eax
400045d6:	c7 00 0a 00 00 00    	movl   $0xa,(%eax)
400045dc:	c7 45 e4 00 00 00 00 	movl   $0x0,0xffffffe4(%ebp)
400045e3:	e9 0b 01 00 00       	jmp    400046f3 <filedesc_open+0x24a>
400045e8:	8b 45 10             	mov    0x10(%ebp),%eax
400045eb:	83 e0 40             	and    $0x40,%eax
400045ee:	85 c0                	test   %eax,%eax
400045f0:	74 60                	je     40004652 <filedesc_open+0x1a9>
400045f2:	8b 45 10             	mov    0x10(%ebp),%eax
400045f5:	83 e0 02             	and    $0x2,%eax
400045f8:	85 c0                	test   %eax,%eax
400045fa:	75 33                	jne    4000462f <filedesc_open+0x186>
400045fc:	c7 44 24 08 a0 62 00 	movl   $0x400062a0,0x8(%esp)
40004603:	40 
40004604:	c7 44 24 04 2e 01 00 	movl   $0x12e,0x4(%esp)
4000460b:	00 
4000460c:	c7 04 24 57 61 00 40 	movl   $0x40006157,(%esp)
40004613:	e8 2a e6 ff ff       	call   40002c42 <debug_warn>
40004618:	a1 34 61 00 40       	mov    0x40006134,%eax
4000461d:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
40004623:	c7 45 e4 00 00 00 00 	movl   $0x0,0xffffffe4(%ebp)
4000462a:	e9 c4 00 00 00       	jmp    400046f3 <filedesc_open+0x24a>
4000462f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40004636:	00 
40004637:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
4000463a:	89 04 24             	mov    %eax,(%esp)
4000463d:	e8 26 fb ff ff       	call   40004168 <fileino_truncate>
40004642:	85 c0                	test   %eax,%eax
40004644:	79 0c                	jns    40004652 <filedesc_open+0x1a9>
40004646:	c7 45 e4 00 00 00 00 	movl   $0x0,0xffffffe4(%ebp)
4000464d:	e9 a1 00 00 00       	jmp    400046f3 <filedesc_open+0x24a>
40004652:	8b 55 08             	mov    0x8(%ebp),%edx
40004655:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
40004658:	89 02                	mov    %eax,(%edx)
4000465a:	8b 55 08             	mov    0x8(%ebp),%edx
4000465d:	8b 45 10             	mov    0x10(%ebp),%eax
40004660:	89 42 04             	mov    %eax,0x4(%edx)
40004663:	8b 45 10             	mov    0x10(%ebp),%eax
40004666:	83 e0 10             	and    $0x10,%eax
40004669:	85 c0                	test   %eax,%eax
4000466b:	74 1a                	je     40004687 <filedesc_open+0x1de>
4000466d:	8b 15 34 61 00 40    	mov    0x40006134,%edx
40004673:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
40004676:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004679:	01 d0                	add    %edx,%eax
4000467b:	05 5c 10 00 00       	add    $0x105c,%eax
40004680:	8b 00                	mov    (%eax),%eax
40004682:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
40004685:	eb 07                	jmp    4000468e <filedesc_open+0x1e5>
40004687:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
4000468e:	8b 45 08             	mov    0x8(%ebp),%eax
40004691:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
40004694:	89 50 08             	mov    %edx,0x8(%eax)
40004697:	8b 45 08             	mov    0x8(%ebp),%eax
4000469a:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
400046a1:	a1 34 61 00 40       	mov    0x40006134,%eax
400046a6:	83 c0 10             	add    $0x10,%eax
400046a9:	3b 45 08             	cmp    0x8(%ebp),%eax
400046ac:	77 1b                	ja     400046c9 <filedesc_open+0x220>
400046ae:	a1 34 61 00 40       	mov    0x40006134,%eax
400046b3:	83 c0 10             	add    $0x10,%eax
400046b6:	05 00 10 00 00       	add    $0x1000,%eax
400046bb:	3b 45 08             	cmp    0x8(%ebp),%eax
400046be:	76 09                	jbe    400046c9 <filedesc_open+0x220>
400046c0:	8b 45 08             	mov    0x8(%ebp),%eax
400046c3:	8b 00                	mov    (%eax),%eax
400046c5:	85 c0                	test   %eax,%eax
400046c7:	75 24                	jne    400046ed <filedesc_open+0x244>
400046c9:	c7 44 24 0c d0 62 00 	movl   $0x400062d0,0xc(%esp)
400046d0:	40 
400046d1:	c7 44 24 08 6f 61 00 	movl   $0x4000616f,0x8(%esp)
400046d8:	40 
400046d9:	c7 44 24 04 3c 01 00 	movl   $0x13c,0x4(%esp)
400046e0:	00 
400046e1:	c7 04 24 57 61 00 40 	movl   $0x40006157,(%esp)
400046e8:	e8 eb e4 ff ff       	call   40002bd8 <debug_panic>
400046ed:	8b 45 08             	mov    0x8(%ebp),%eax
400046f0:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
400046f3:	8b 45 e4             	mov    0xffffffe4(%ebp),%eax
400046f6:	c9                   	leave  
400046f7:	c3                   	ret    

400046f8 <filedesc_read>:
400046f8:	55                   	push   %ebp
400046f9:	89 e5                	mov    %esp,%ebp
400046fb:	83 ec 28             	sub    $0x28,%esp
400046fe:	a1 34 61 00 40       	mov    0x40006134,%eax
40004703:	83 c0 10             	add    $0x10,%eax
40004706:	3b 45 08             	cmp    0x8(%ebp),%eax
40004709:	77 28                	ja     40004733 <filedesc_read+0x3b>
4000470b:	a1 34 61 00 40       	mov    0x40006134,%eax
40004710:	83 c0 10             	add    $0x10,%eax
40004713:	05 00 10 00 00       	add    $0x1000,%eax
40004718:	3b 45 08             	cmp    0x8(%ebp),%eax
4000471b:	76 16                	jbe    40004733 <filedesc_read+0x3b>
4000471d:	8b 45 08             	mov    0x8(%ebp),%eax
40004720:	8b 00                	mov    (%eax),%eax
40004722:	85 c0                	test   %eax,%eax
40004724:	74 0d                	je     40004733 <filedesc_read+0x3b>
40004726:	8b 45 08             	mov    0x8(%ebp),%eax
40004729:	8b 40 04             	mov    0x4(%eax),%eax
4000472c:	83 e0 01             	and    $0x1,%eax
4000472f:	85 c0                	test   %eax,%eax
40004731:	75 24                	jne    40004757 <filedesc_read+0x5f>
40004733:	c7 44 24 0c e4 62 00 	movl   $0x400062e4,0xc(%esp)
4000473a:	40 
4000473b:	c7 44 24 08 6f 61 00 	movl   $0x4000616f,0x8(%esp)
40004742:	40 
40004743:	c7 44 24 04 4e 01 00 	movl   $0x14e,0x4(%esp)
4000474a:	00 
4000474b:	c7 04 24 57 61 00 40 	movl   $0x40006157,(%esp)
40004752:	e8 81 e4 ff ff       	call   40002bd8 <debug_panic>
40004757:	a1 34 61 00 40       	mov    0x40006134,%eax
4000475c:	8d 90 10 10 00 00    	lea    0x1010(%eax),%edx
40004762:	8b 45 08             	mov    0x8(%ebp),%eax
40004765:	8b 00                	mov    (%eax),%eax
40004767:	6b c0 5c             	imul   $0x5c,%eax,%eax
4000476a:	8d 04 02             	lea    (%edx,%eax,1),%eax
4000476d:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
40004770:	8b 45 08             	mov    0x8(%ebp),%eax
40004773:	8b 50 08             	mov    0x8(%eax),%edx
40004776:	8b 45 08             	mov    0x8(%ebp),%eax
40004779:	8b 08                	mov    (%eax),%ecx
4000477b:	8b 45 14             	mov    0x14(%ebp),%eax
4000477e:	89 44 24 10          	mov    %eax,0x10(%esp)
40004782:	8b 45 10             	mov    0x10(%ebp),%eax
40004785:	89 44 24 0c          	mov    %eax,0xc(%esp)
40004789:	8b 45 0c             	mov    0xc(%ebp),%eax
4000478c:	89 44 24 08          	mov    %eax,0x8(%esp)
40004790:	89 54 24 04          	mov    %edx,0x4(%esp)
40004794:	89 0c 24             	mov    %ecx,(%esp)
40004797:	e8 75 f4 ff ff       	call   40003c11 <fileino_read>
4000479c:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
4000479f:	83 7d fc 00          	cmpl   $0x0,0xfffffffc(%ebp)
400047a3:	79 16                	jns    400047bb <filedesc_read+0xc3>
400047a5:	a1 34 61 00 40       	mov    0x40006134,%eax
400047aa:	8b 10                	mov    (%eax),%edx
400047ac:	8b 45 08             	mov    0x8(%ebp),%eax
400047af:	89 50 0c             	mov    %edx,0xc(%eax)
400047b2:	c7 45 ec ff ff ff ff 	movl   $0xffffffff,0xffffffec(%ebp)
400047b9:	eb 5a                	jmp    40004815 <filedesc_read+0x11d>
400047bb:	8b 45 08             	mov    0x8(%ebp),%eax
400047be:	8b 40 08             	mov    0x8(%eax),%eax
400047c1:	89 c2                	mov    %eax,%edx
400047c3:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
400047c6:	0f af 45 10          	imul   0x10(%ebp),%eax
400047ca:	8d 04 02             	lea    (%edx,%eax,1),%eax
400047cd:	89 c2                	mov    %eax,%edx
400047cf:	8b 45 08             	mov    0x8(%ebp),%eax
400047d2:	89 50 08             	mov    %edx,0x8(%eax)
400047d5:	83 7d fc 00          	cmpl   $0x0,0xfffffffc(%ebp)
400047d9:	74 34                	je     4000480f <filedesc_read+0x117>
400047db:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
400047de:	8b 50 4c             	mov    0x4c(%eax),%edx
400047e1:	8b 45 08             	mov    0x8(%ebp),%eax
400047e4:	8b 40 08             	mov    0x8(%eax),%eax
400047e7:	39 c2                	cmp    %eax,%edx
400047e9:	73 24                	jae    4000480f <filedesc_read+0x117>
400047eb:	c7 44 24 0c fc 62 00 	movl   $0x400062fc,0xc(%esp)
400047f2:	40 
400047f3:	c7 44 24 08 6f 61 00 	movl   $0x4000616f,0x8(%esp)
400047fa:	40 
400047fb:	c7 44 24 04 59 01 00 	movl   $0x159,0x4(%esp)
40004802:	00 
40004803:	c7 04 24 57 61 00 40 	movl   $0x40006157,(%esp)
4000480a:	e8 c9 e3 ff ff       	call   40002bd8 <debug_panic>
4000480f:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
40004812:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
40004815:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
40004818:	c9                   	leave  
40004819:	c3                   	ret    

4000481a <filedesc_write>:
4000481a:	55                   	push   %ebp
4000481b:	89 e5                	mov    %esp,%ebp
4000481d:	83 ec 28             	sub    $0x28,%esp
40004820:	a1 34 61 00 40       	mov    0x40006134,%eax
40004825:	83 c0 10             	add    $0x10,%eax
40004828:	3b 45 08             	cmp    0x8(%ebp),%eax
4000482b:	77 28                	ja     40004855 <filedesc_write+0x3b>
4000482d:	a1 34 61 00 40       	mov    0x40006134,%eax
40004832:	83 c0 10             	add    $0x10,%eax
40004835:	05 00 10 00 00       	add    $0x1000,%eax
4000483a:	3b 45 08             	cmp    0x8(%ebp),%eax
4000483d:	76 16                	jbe    40004855 <filedesc_write+0x3b>
4000483f:	8b 45 08             	mov    0x8(%ebp),%eax
40004842:	8b 00                	mov    (%eax),%eax
40004844:	85 c0                	test   %eax,%eax
40004846:	74 0d                	je     40004855 <filedesc_write+0x3b>
40004848:	8b 45 08             	mov    0x8(%ebp),%eax
4000484b:	8b 40 04             	mov    0x4(%eax),%eax
4000484e:	83 e0 02             	and    $0x2,%eax
40004851:	85 c0                	test   %eax,%eax
40004853:	75 24                	jne    40004879 <filedesc_write+0x5f>
40004855:	c7 44 24 0c 1f 63 00 	movl   $0x4000631f,0xc(%esp)
4000485c:	40 
4000485d:	c7 44 24 08 6f 61 00 	movl   $0x4000616f,0x8(%esp)
40004864:	40 
40004865:	c7 44 24 04 66 01 00 	movl   $0x166,0x4(%esp)
4000486c:	00 
4000486d:	c7 04 24 57 61 00 40 	movl   $0x40006157,(%esp)
40004874:	e8 5f e3 ff ff       	call   40002bd8 <debug_panic>
40004879:	a1 34 61 00 40       	mov    0x40006134,%eax
4000487e:	8d 90 10 10 00 00    	lea    0x1010(%eax),%edx
40004884:	8b 45 08             	mov    0x8(%ebp),%eax
40004887:	8b 00                	mov    (%eax),%eax
40004889:	6b c0 5c             	imul   $0x5c,%eax,%eax
4000488c:	8d 04 02             	lea    (%edx,%eax,1),%eax
4000488f:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
40004892:	8b 45 08             	mov    0x8(%ebp),%eax
40004895:	8b 40 04             	mov    0x4(%eax),%eax
40004898:	83 e0 10             	and    $0x10,%eax
4000489b:	85 c0                	test   %eax,%eax
4000489d:	74 0e                	je     400048ad <filedesc_write+0x93>
4000489f:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
400048a2:	8b 40 4c             	mov    0x4c(%eax),%eax
400048a5:	89 c2                	mov    %eax,%edx
400048a7:	8b 45 08             	mov    0x8(%ebp),%eax
400048aa:	89 50 08             	mov    %edx,0x8(%eax)
400048ad:	8b 45 08             	mov    0x8(%ebp),%eax
400048b0:	8b 50 08             	mov    0x8(%eax),%edx
400048b3:	8b 45 08             	mov    0x8(%ebp),%eax
400048b6:	8b 08                	mov    (%eax),%ecx
400048b8:	8b 45 14             	mov    0x14(%ebp),%eax
400048bb:	89 44 24 10          	mov    %eax,0x10(%esp)
400048bf:	8b 45 10             	mov    0x10(%ebp),%eax
400048c2:	89 44 24 0c          	mov    %eax,0xc(%esp)
400048c6:	8b 45 0c             	mov    0xc(%ebp),%eax
400048c9:	89 44 24 08          	mov    %eax,0x8(%esp)
400048cd:	89 54 24 04          	mov    %edx,0x4(%esp)
400048d1:	89 0c 24             	mov    %ecx,(%esp)
400048d4:	e8 1e f5 ff ff       	call   40003df7 <fileino_write>
400048d9:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
400048dc:	83 7d fc 00          	cmpl   $0x0,0xfffffffc(%ebp)
400048e0:	79 19                	jns    400048fb <filedesc_write+0xe1>
400048e2:	a1 34 61 00 40       	mov    0x40006134,%eax
400048e7:	8b 10                	mov    (%eax),%edx
400048e9:	8b 45 08             	mov    0x8(%ebp),%eax
400048ec:	89 50 0c             	mov    %edx,0xc(%eax)
400048ef:	c7 45 ec ff ff ff ff 	movl   $0xffffffff,0xffffffec(%ebp)
400048f6:	e9 9c 00 00 00       	jmp    40004997 <filedesc_write+0x17d>
400048fb:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
400048fe:	3b 45 14             	cmp    0x14(%ebp),%eax
40004901:	74 24                	je     40004927 <filedesc_write+0x10d>
40004903:	c7 44 24 0c 37 63 00 	movl   $0x40006337,0xc(%esp)
4000490a:	40 
4000490b:	c7 44 24 08 6f 61 00 	movl   $0x4000616f,0x8(%esp)
40004912:	40 
40004913:	c7 44 24 04 73 01 00 	movl   $0x173,0x4(%esp)
4000491a:	00 
4000491b:	c7 04 24 57 61 00 40 	movl   $0x40006157,(%esp)
40004922:	e8 b1 e2 ff ff       	call   40002bd8 <debug_panic>
40004927:	8b 45 08             	mov    0x8(%ebp),%eax
4000492a:	8b 40 04             	mov    0x4(%eax),%eax
4000492d:	83 e0 10             	and    $0x10,%eax
40004930:	85 c0                	test   %eax,%eax
40004932:	75 0f                	jne    40004943 <filedesc_write+0x129>
40004934:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
40004937:	8b 40 44             	mov    0x44(%eax),%eax
4000493a:	8d 50 01             	lea    0x1(%eax),%edx
4000493d:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
40004940:	89 50 44             	mov    %edx,0x44(%eax)
40004943:	8b 45 08             	mov    0x8(%ebp),%eax
40004946:	8b 40 08             	mov    0x8(%eax),%eax
40004949:	89 c2                	mov    %eax,%edx
4000494b:	8b 45 10             	mov    0x10(%ebp),%eax
4000494e:	0f af 45 14          	imul   0x14(%ebp),%eax
40004952:	8d 04 02             	lea    (%edx,%eax,1),%eax
40004955:	89 c2                	mov    %eax,%edx
40004957:	8b 45 08             	mov    0x8(%ebp),%eax
4000495a:	89 50 08             	mov    %edx,0x8(%eax)
4000495d:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
40004960:	8b 50 4c             	mov    0x4c(%eax),%edx
40004963:	8b 45 08             	mov    0x8(%ebp),%eax
40004966:	8b 40 08             	mov    0x8(%eax),%eax
40004969:	39 c2                	cmp    %eax,%edx
4000496b:	73 24                	jae    40004991 <filedesc_write+0x177>
4000496d:	c7 44 24 0c 47 63 00 	movl   $0x40006347,0xc(%esp)
40004974:	40 
40004975:	c7 44 24 08 6f 61 00 	movl   $0x4000616f,0x8(%esp)
4000497c:	40 
4000497d:	c7 44 24 04 7c 01 00 	movl   $0x17c,0x4(%esp)
40004984:	00 
40004985:	c7 04 24 57 61 00 40 	movl   $0x40006157,(%esp)
4000498c:	e8 47 e2 ff ff       	call   40002bd8 <debug_panic>
40004991:	8b 45 14             	mov    0x14(%ebp),%eax
40004994:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
40004997:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
4000499a:	c9                   	leave  
4000499b:	c3                   	ret    

4000499c <filedesc_seek>:
4000499c:	55                   	push   %ebp
4000499d:	89 e5                	mov    %esp,%ebp
4000499f:	83 ec 28             	sub    $0x28,%esp
400049a2:	a1 34 61 00 40       	mov    0x40006134,%eax
400049a7:	83 c0 10             	add    $0x10,%eax
400049aa:	3b 45 08             	cmp    0x8(%ebp),%eax
400049ad:	77 1b                	ja     400049ca <filedesc_seek+0x2e>
400049af:	a1 34 61 00 40       	mov    0x40006134,%eax
400049b4:	83 c0 10             	add    $0x10,%eax
400049b7:	05 00 10 00 00       	add    $0x1000,%eax
400049bc:	3b 45 08             	cmp    0x8(%ebp),%eax
400049bf:	76 09                	jbe    400049ca <filedesc_seek+0x2e>
400049c1:	8b 45 08             	mov    0x8(%ebp),%eax
400049c4:	8b 00                	mov    (%eax),%eax
400049c6:	85 c0                	test   %eax,%eax
400049c8:	75 24                	jne    400049ee <filedesc_seek+0x52>
400049ca:	c7 44 24 0c d0 62 00 	movl   $0x400062d0,0xc(%esp)
400049d1:	40 
400049d2:	c7 44 24 08 6f 61 00 	movl   $0x4000616f,0x8(%esp)
400049d9:	40 
400049da:	c7 44 24 04 88 01 00 	movl   $0x188,0x4(%esp)
400049e1:	00 
400049e2:	c7 04 24 57 61 00 40 	movl   $0x40006157,(%esp)
400049e9:	e8 ea e1 ff ff       	call   40002bd8 <debug_panic>
400049ee:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
400049f2:	74 30                	je     40004a24 <filedesc_seek+0x88>
400049f4:	83 7d 10 01          	cmpl   $0x1,0x10(%ebp)
400049f8:	74 2a                	je     40004a24 <filedesc_seek+0x88>
400049fa:	83 7d 10 02          	cmpl   $0x2,0x10(%ebp)
400049fe:	74 24                	je     40004a24 <filedesc_seek+0x88>
40004a00:	c7 44 24 0c 5c 63 00 	movl   $0x4000635c,0xc(%esp)
40004a07:	40 
40004a08:	c7 44 24 08 6f 61 00 	movl   $0x4000616f,0x8(%esp)
40004a0f:	40 
40004a10:	c7 44 24 04 89 01 00 	movl   $0x189,0x4(%esp)
40004a17:	00 
40004a18:	c7 04 24 57 61 00 40 	movl   $0x40006157,(%esp)
40004a1f:	e8 b4 e1 ff ff       	call   40002bd8 <debug_panic>
40004a24:	a1 34 61 00 40       	mov    0x40006134,%eax
40004a29:	8d 90 10 10 00 00    	lea    0x1010(%eax),%edx
40004a2f:	8b 45 08             	mov    0x8(%ebp),%eax
40004a32:	8b 00                	mov    (%eax),%eax
40004a34:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004a37:	8d 04 02             	lea    (%edx,%eax,1),%eax
40004a3a:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
40004a3d:	8b 45 0c             	mov    0xc(%ebp),%eax
40004a40:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
40004a43:	83 7d 10 01          	cmpl   $0x1,0x10(%ebp)
40004a47:	75 0b                	jne    40004a54 <filedesc_seek+0xb8>
40004a49:	8b 45 08             	mov    0x8(%ebp),%eax
40004a4c:	8b 40 08             	mov    0x8(%eax),%eax
40004a4f:	01 45 fc             	add    %eax,0xfffffffc(%ebp)
40004a52:	eb 15                	jmp    40004a69 <filedesc_seek+0xcd>
40004a54:	83 7d 10 02          	cmpl   $0x2,0x10(%ebp)
40004a58:	75 0f                	jne    40004a69 <filedesc_seek+0xcd>
40004a5a:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
40004a5d:	8b 50 4c             	mov    0x4c(%eax),%edx
40004a60:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
40004a63:	8d 04 02             	lea    (%edx,%eax,1),%eax
40004a66:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
40004a69:	83 7d fc 00          	cmpl   $0x0,0xfffffffc(%ebp)
40004a6d:	79 24                	jns    40004a93 <filedesc_seek+0xf7>
40004a6f:	c7 44 24 0c 9b 63 00 	movl   $0x4000639b,0xc(%esp)
40004a76:	40 
40004a77:	c7 44 24 08 6f 61 00 	movl   $0x4000616f,0x8(%esp)
40004a7e:	40 
40004a7f:	c7 44 24 04 92 01 00 	movl   $0x192,0x4(%esp)
40004a86:	00 
40004a87:	c7 04 24 57 61 00 40 	movl   $0x40006157,(%esp)
40004a8e:	e8 45 e1 ff ff       	call   40002bd8 <debug_panic>
40004a93:	8b 55 08             	mov    0x8(%ebp),%edx
40004a96:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
40004a99:	89 42 08             	mov    %eax,0x8(%edx)
40004a9c:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
40004a9f:	c9                   	leave  
40004aa0:	c3                   	ret    

40004aa1 <filedesc_close>:
40004aa1:	55                   	push   %ebp
40004aa2:	89 e5                	mov    %esp,%ebp
40004aa4:	83 ec 18             	sub    $0x18,%esp
40004aa7:	a1 34 61 00 40       	mov    0x40006134,%eax
40004aac:	83 c0 10             	add    $0x10,%eax
40004aaf:	3b 45 08             	cmp    0x8(%ebp),%eax
40004ab2:	77 1b                	ja     40004acf <filedesc_close+0x2e>
40004ab4:	a1 34 61 00 40       	mov    0x40006134,%eax
40004ab9:	83 c0 10             	add    $0x10,%eax
40004abc:	05 00 10 00 00       	add    $0x1000,%eax
40004ac1:	3b 45 08             	cmp    0x8(%ebp),%eax
40004ac4:	76 09                	jbe    40004acf <filedesc_close+0x2e>
40004ac6:	8b 45 08             	mov    0x8(%ebp),%eax
40004ac9:	8b 00                	mov    (%eax),%eax
40004acb:	85 c0                	test   %eax,%eax
40004acd:	75 24                	jne    40004af3 <filedesc_close+0x52>
40004acf:	c7 44 24 0c d0 62 00 	movl   $0x400062d0,0xc(%esp)
40004ad6:	40 
40004ad7:	c7 44 24 08 6f 61 00 	movl   $0x4000616f,0x8(%esp)
40004ade:	40 
40004adf:	c7 44 24 04 a1 01 00 	movl   $0x1a1,0x4(%esp)
40004ae6:	00 
40004ae7:	c7 04 24 57 61 00 40 	movl   $0x40006157,(%esp)
40004aee:	e8 e5 e0 ff ff       	call   40002bd8 <debug_panic>
40004af3:	8b 45 08             	mov    0x8(%ebp),%eax
40004af6:	8b 00                	mov    (%eax),%eax
40004af8:	85 c0                	test   %eax,%eax
40004afa:	7e 0c                	jle    40004b08 <filedesc_close+0x67>
40004afc:	8b 45 08             	mov    0x8(%ebp),%eax
40004aff:	8b 00                	mov    (%eax),%eax
40004b01:	3d ff 00 00 00       	cmp    $0xff,%eax
40004b06:	7e 24                	jle    40004b2c <filedesc_close+0x8b>
40004b08:	c7 44 24 0c a7 63 00 	movl   $0x400063a7,0xc(%esp)
40004b0f:	40 
40004b10:	c7 44 24 08 6f 61 00 	movl   $0x4000616f,0x8(%esp)
40004b17:	40 
40004b18:	c7 44 24 04 a2 01 00 	movl   $0x1a2,0x4(%esp)
40004b1f:	00 
40004b20:	c7 04 24 57 61 00 40 	movl   $0x40006157,(%esp)
40004b27:	e8 ac e0 ff ff       	call   40002bd8 <debug_panic>
40004b2c:	8b 45 08             	mov    0x8(%ebp),%eax
40004b2f:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
40004b35:	c9                   	leave  
40004b36:	c3                   	ret    
40004b37:	90                   	nop    

40004b38 <dir_walk>:
40004b38:	55                   	push   %ebp
40004b39:	89 e5                	mov    %esp,%ebp
40004b3b:	53                   	push   %ebx
40004b3c:	83 ec 24             	sub    $0x24,%esp
40004b3f:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
40004b43:	74 0a                	je     40004b4f <dir_walk+0x17>
40004b45:	8b 45 08             	mov    0x8(%ebp),%eax
40004b48:	0f b6 00             	movzbl (%eax),%eax
40004b4b:	84 c0                	test   %al,%al
40004b4d:	75 24                	jne    40004b73 <dir_walk+0x3b>
40004b4f:	c7 44 24 0c c0 63 00 	movl   $0x400063c0,0xc(%esp)
40004b56:	40 
40004b57:	c7 44 24 08 d8 63 00 	movl   $0x400063d8,0x8(%esp)
40004b5e:	40 
40004b5f:	c7 44 24 04 16 00 00 	movl   $0x16,0x4(%esp)
40004b66:	00 
40004b67:	c7 04 24 ed 63 00 40 	movl   $0x400063ed,(%esp)
40004b6e:	e8 65 e0 ff ff       	call   40002bd8 <debug_panic>
40004b73:	a1 34 61 00 40       	mov    0x40006134,%eax
40004b78:	8b 40 04             	mov    0x4(%eax),%eax
40004b7b:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
40004b7e:	8b 45 08             	mov    0x8(%ebp),%eax
40004b81:	0f b6 00             	movzbl (%eax),%eax
40004b84:	3c 2f                	cmp    $0x2f,%al
40004b86:	75 2a                	jne    40004bb2 <dir_walk+0x7a>
40004b88:	c7 45 f0 03 00 00 00 	movl   $0x3,0xfffffff0(%ebp)
40004b8f:	83 45 08 01          	addl   $0x1,0x8(%ebp)
40004b93:	8b 45 08             	mov    0x8(%ebp),%eax
40004b96:	0f b6 00             	movzbl (%eax),%eax
40004b99:	3c 2f                	cmp    $0x2f,%al
40004b9b:	74 f2                	je     40004b8f <dir_walk+0x57>
40004b9d:	8b 45 08             	mov    0x8(%ebp),%eax
40004ba0:	0f b6 00             	movzbl (%eax),%eax
40004ba3:	84 c0                	test   %al,%al
40004ba5:	75 0b                	jne    40004bb2 <dir_walk+0x7a>
40004ba7:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
40004baa:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
40004bad:	e9 67 05 00 00       	jmp    40005119 <dir_walk+0x5e1>
40004bb2:	83 7d f0 00          	cmpl   $0x0,0xfffffff0(%ebp)
40004bb6:	7e 45                	jle    40004bfd <dir_walk+0xc5>
40004bb8:	81 7d f0 ff 00 00 00 	cmpl   $0xff,0xfffffff0(%ebp)
40004bbf:	7f 3c                	jg     40004bfd <dir_walk+0xc5>
40004bc1:	8b 15 34 61 00 40    	mov    0x40006134,%edx
40004bc7:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
40004bca:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004bcd:	01 d0                	add    %edx,%eax
40004bcf:	05 10 10 00 00       	add    $0x1010,%eax
40004bd4:	0f b6 40 04          	movzbl 0x4(%eax),%eax
40004bd8:	84 c0                	test   %al,%al
40004bda:	74 21                	je     40004bfd <dir_walk+0xc5>
40004bdc:	8b 15 34 61 00 40    	mov    0x40006134,%edx
40004be2:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
40004be5:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004be8:	01 d0                	add    %edx,%eax
40004bea:	05 58 10 00 00       	add    $0x1058,%eax
40004bef:	8b 00                	mov    (%eax),%eax
40004bf1:	25 00 70 00 00       	and    $0x7000,%eax
40004bf6:	3d 00 20 00 00       	cmp    $0x2000,%eax
40004bfb:	74 24                	je     40004c21 <dir_walk+0xe9>
40004bfd:	c7 44 24 0c fa 63 00 	movl   $0x400063fa,0xc(%esp)
40004c04:	40 
40004c05:	c7 44 24 08 d8 63 00 	movl   $0x400063d8,0x8(%esp)
40004c0c:	40 
40004c0d:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
40004c14:	00 
40004c15:	c7 04 24 ed 63 00 40 	movl   $0x400063ed,(%esp)
40004c1c:	e8 b7 df ff ff       	call   40002bd8 <debug_panic>
40004c21:	8b 15 34 61 00 40    	mov    0x40006134,%edx
40004c27:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
40004c2a:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004c2d:	01 d0                	add    %edx,%eax
40004c2f:	05 10 10 00 00       	add    $0x1010,%eax
40004c34:	8b 00                	mov    (%eax),%eax
40004c36:	85 c0                	test   %eax,%eax
40004c38:	7e 7c                	jle    40004cb6 <dir_walk+0x17e>
40004c3a:	8b 15 34 61 00 40    	mov    0x40006134,%edx
40004c40:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
40004c43:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004c46:	01 d0                	add    %edx,%eax
40004c48:	05 10 10 00 00       	add    $0x1010,%eax
40004c4d:	8b 00                	mov    (%eax),%eax
40004c4f:	3d ff 00 00 00       	cmp    $0xff,%eax
40004c54:	7f 60                	jg     40004cb6 <dir_walk+0x17e>
40004c56:	8b 0d 34 61 00 40    	mov    0x40006134,%ecx
40004c5c:	8b 15 34 61 00 40    	mov    0x40006134,%edx
40004c62:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
40004c65:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004c68:	01 d0                	add    %edx,%eax
40004c6a:	05 10 10 00 00       	add    $0x1010,%eax
40004c6f:	8b 00                	mov    (%eax),%eax
40004c71:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004c74:	01 c8                	add    %ecx,%eax
40004c76:	05 10 10 00 00       	add    $0x1010,%eax
40004c7b:	0f b6 40 04          	movzbl 0x4(%eax),%eax
40004c7f:	84 c0                	test   %al,%al
40004c81:	74 33                	je     40004cb6 <dir_walk+0x17e>
40004c83:	8b 0d 34 61 00 40    	mov    0x40006134,%ecx
40004c89:	8b 15 34 61 00 40    	mov    0x40006134,%edx
40004c8f:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
40004c92:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004c95:	01 d0                	add    %edx,%eax
40004c97:	05 10 10 00 00       	add    $0x1010,%eax
40004c9c:	8b 00                	mov    (%eax),%eax
40004c9e:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004ca1:	01 c8                	add    %ecx,%eax
40004ca3:	05 58 10 00 00       	add    $0x1058,%eax
40004ca8:	8b 00                	mov    (%eax),%eax
40004caa:	25 00 70 00 00       	and    $0x7000,%eax
40004caf:	3d 00 20 00 00       	cmp    $0x2000,%eax
40004cb4:	74 24                	je     40004cda <dir_walk+0x1a2>
40004cb6:	c7 44 24 0c 10 64 00 	movl   $0x40006410,0xc(%esp)
40004cbd:	40 
40004cbe:	c7 44 24 08 d8 63 00 	movl   $0x400063d8,0x8(%esp)
40004cc5:	40 
40004cc6:	c7 44 24 04 24 00 00 	movl   $0x24,0x4(%esp)
40004ccd:	00 
40004cce:	c7 04 24 ed 63 00 40 	movl   $0x400063ed,(%esp)
40004cd5:	e8 fe de ff ff       	call   40002bd8 <debug_panic>
40004cda:	c7 45 f4 01 00 00 00 	movl   $0x1,0xfffffff4(%ebp)
40004ce1:	e9 39 02 00 00       	jmp    40004f1f <dir_walk+0x3e7>
40004ce6:	83 7d f4 00          	cmpl   $0x0,0xfffffff4(%ebp)
40004cea:	0f 8e 2b 02 00 00    	jle    40004f1b <dir_walk+0x3e3>
40004cf0:	81 7d f4 ff 00 00 00 	cmpl   $0xff,0xfffffff4(%ebp)
40004cf7:	0f 8f 1e 02 00 00    	jg     40004f1b <dir_walk+0x3e3>
40004cfd:	8b 15 34 61 00 40    	mov    0x40006134,%edx
40004d03:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
40004d06:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004d09:	01 d0                	add    %edx,%eax
40004d0b:	05 10 10 00 00       	add    $0x1010,%eax
40004d10:	0f b6 40 04          	movzbl 0x4(%eax),%eax
40004d14:	84 c0                	test   %al,%al
40004d16:	0f 84 ff 01 00 00    	je     40004f1b <dir_walk+0x3e3>
40004d1c:	8b 15 34 61 00 40    	mov    0x40006134,%edx
40004d22:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
40004d25:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004d28:	01 d0                	add    %edx,%eax
40004d2a:	05 10 10 00 00       	add    $0x1010,%eax
40004d2f:	8b 00                	mov    (%eax),%eax
40004d31:	3b 45 f0             	cmp    0xfffffff0(%ebp),%eax
40004d34:	0f 85 e1 01 00 00    	jne    40004f1b <dir_walk+0x3e3>
40004d3a:	8b 15 34 61 00 40    	mov    0x40006134,%edx
40004d40:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
40004d43:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004d46:	05 10 10 00 00       	add    $0x1010,%eax
40004d4b:	8d 04 02             	lea    (%edx,%eax,1),%eax
40004d4e:	83 c0 04             	add    $0x4,%eax
40004d51:	89 04 24             	mov    %eax,(%esp)
40004d54:	e8 73 e8 ff ff       	call   400035cc <strlen>
40004d59:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
40004d5c:	8b 4d f8             	mov    0xfffffff8(%ebp),%ecx
40004d5f:	8b 15 34 61 00 40    	mov    0x40006134,%edx
40004d65:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
40004d68:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004d6b:	05 10 10 00 00       	add    $0x1010,%eax
40004d70:	8d 04 02             	lea    (%edx,%eax,1),%eax
40004d73:	83 c0 04             	add    $0x4,%eax
40004d76:	89 4c 24 08          	mov    %ecx,0x8(%esp)
40004d7a:	89 44 24 04          	mov    %eax,0x4(%esp)
40004d7e:	8b 45 08             	mov    0x8(%ebp),%eax
40004d81:	89 04 24             	mov    %eax,(%esp)
40004d84:	e8 70 eb ff ff       	call   400038f9 <memcmp>
40004d89:	85 c0                	test   %eax,%eax
40004d8b:	0f 85 8a 01 00 00    	jne    40004f1b <dir_walk+0x3e3>
40004d91:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
40004d94:	03 45 08             	add    0x8(%ebp),%eax
40004d97:	0f b6 00             	movzbl (%eax),%eax
40004d9a:	84 c0                	test   %al,%al
40004d9c:	0f 85 cc 00 00 00    	jne    40004e6e <dir_walk+0x336>
40004da2:	83 7d f4 00          	cmpl   $0x0,0xfffffff4(%ebp)
40004da6:	7e 48                	jle    40004df0 <dir_walk+0x2b8>
40004da8:	81 7d f4 ff 00 00 00 	cmpl   $0xff,0xfffffff4(%ebp)
40004daf:	7f 3f                	jg     40004df0 <dir_walk+0x2b8>
40004db1:	8b 15 34 61 00 40    	mov    0x40006134,%edx
40004db7:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
40004dba:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004dbd:	01 d0                	add    %edx,%eax
40004dbf:	05 10 10 00 00       	add    $0x1010,%eax
40004dc4:	0f b6 40 04          	movzbl 0x4(%eax),%eax
40004dc8:	84 c0                	test   %al,%al
40004dca:	74 24                	je     40004df0 <dir_walk+0x2b8>
40004dcc:	8b 15 34 61 00 40    	mov    0x40006134,%edx
40004dd2:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
40004dd5:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004dd8:	01 d0                	add    %edx,%eax
40004dda:	05 58 10 00 00       	add    $0x1058,%eax
40004ddf:	8b 00                	mov    (%eax),%eax
40004de1:	85 c0                	test   %eax,%eax
40004de3:	74 0b                	je     40004df0 <dir_walk+0x2b8>
40004de5:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
40004de8:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
40004deb:	e9 29 03 00 00       	jmp    40005119 <dir_walk+0x5e1>
40004df0:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
40004df4:	75 17                	jne    40004e0d <dir_walk+0x2d5>
40004df6:	a1 34 61 00 40       	mov    0x40006134,%eax
40004dfb:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
40004e01:	c7 45 e8 ff ff ff ff 	movl   $0xffffffff,0xffffffe8(%ebp)
40004e08:	e9 0c 03 00 00       	jmp    40005119 <dir_walk+0x5e1>
40004e0d:	8b 1d 34 61 00 40    	mov    0x40006134,%ebx
40004e13:	8b 55 f4             	mov    0xfffffff4(%ebp),%edx
40004e16:	6b c2 5c             	imul   $0x5c,%edx,%eax
40004e19:	01 d8                	add    %ebx,%eax
40004e1b:	05 54 10 00 00       	add    $0x1054,%eax
40004e20:	8b 00                	mov    (%eax),%eax
40004e22:	8d 48 01             	lea    0x1(%eax),%ecx
40004e25:	6b c2 5c             	imul   $0x5c,%edx,%eax
40004e28:	01 d8                	add    %ebx,%eax
40004e2a:	05 54 10 00 00       	add    $0x1054,%eax
40004e2f:	89 08                	mov    %ecx,(%eax)
40004e31:	8b 15 34 61 00 40    	mov    0x40006134,%edx
40004e37:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
40004e3a:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004e3d:	01 d0                	add    %edx,%eax
40004e3f:	8d 90 58 10 00 00    	lea    0x1058(%eax),%edx
40004e45:	8b 45 0c             	mov    0xc(%ebp),%eax
40004e48:	89 02                	mov    %eax,(%edx)
40004e4a:	8b 15 34 61 00 40    	mov    0x40006134,%edx
40004e50:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
40004e53:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004e56:	01 d0                	add    %edx,%eax
40004e58:	05 5c 10 00 00       	add    $0x105c,%eax
40004e5d:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
40004e63:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
40004e66:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
40004e69:	e9 ab 02 00 00       	jmp    40005119 <dir_walk+0x5e1>
40004e6e:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
40004e71:	03 45 08             	add    0x8(%ebp),%eax
40004e74:	0f b6 00             	movzbl (%eax),%eax
40004e77:	3c 2f                	cmp    $0x2f,%al
40004e79:	0f 85 9c 00 00 00    	jne    40004f1b <dir_walk+0x3e3>
40004e7f:	83 7d f4 00          	cmpl   $0x0,0xfffffff4(%ebp)
40004e83:	7e 45                	jle    40004eca <dir_walk+0x392>
40004e85:	81 7d f4 ff 00 00 00 	cmpl   $0xff,0xfffffff4(%ebp)
40004e8c:	7f 3c                	jg     40004eca <dir_walk+0x392>
40004e8e:	8b 15 34 61 00 40    	mov    0x40006134,%edx
40004e94:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
40004e97:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004e9a:	01 d0                	add    %edx,%eax
40004e9c:	05 10 10 00 00       	add    $0x1010,%eax
40004ea1:	0f b6 40 04          	movzbl 0x4(%eax),%eax
40004ea5:	84 c0                	test   %al,%al
40004ea7:	74 21                	je     40004eca <dir_walk+0x392>
40004ea9:	8b 15 34 61 00 40    	mov    0x40006134,%edx
40004eaf:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
40004eb2:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004eb5:	01 d0                	add    %edx,%eax
40004eb7:	05 58 10 00 00       	add    $0x1058,%eax
40004ebc:	8b 00                	mov    (%eax),%eax
40004ebe:	25 00 70 00 00       	and    $0x7000,%eax
40004ec3:	3d 00 20 00 00       	cmp    $0x2000,%eax
40004ec8:	74 17                	je     40004ee1 <dir_walk+0x3a9>
40004eca:	a1 34 61 00 40       	mov    0x40006134,%eax
40004ecf:	c7 00 05 00 00 00    	movl   $0x5,(%eax)
40004ed5:	c7 45 e8 ff ff ff ff 	movl   $0xffffffff,0xffffffe8(%ebp)
40004edc:	e9 38 02 00 00       	jmp    40005119 <dir_walk+0x5e1>
40004ee1:	83 45 f8 01          	addl   $0x1,0xfffffff8(%ebp)
40004ee5:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
40004ee8:	03 45 08             	add    0x8(%ebp),%eax
40004eeb:	0f b6 00             	movzbl (%eax),%eax
40004eee:	3c 2f                	cmp    $0x2f,%al
40004ef0:	74 ef                	je     40004ee1 <dir_walk+0x3a9>
40004ef2:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
40004ef5:	03 45 08             	add    0x8(%ebp),%eax
40004ef8:	0f b6 00             	movzbl (%eax),%eax
40004efb:	84 c0                	test   %al,%al
40004efd:	75 0b                	jne    40004f0a <dir_walk+0x3d2>
40004eff:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
40004f02:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
40004f05:	e9 0f 02 00 00       	jmp    40005119 <dir_walk+0x5e1>
40004f0a:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
40004f0d:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
40004f10:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
40004f13:	01 45 08             	add    %eax,0x8(%ebp)
40004f16:	e9 97 fc ff ff       	jmp    40004bb2 <dir_walk+0x7a>
40004f1b:	83 45 f4 01          	addl   $0x1,0xfffffff4(%ebp)
40004f1f:	81 7d f4 ff 00 00 00 	cmpl   $0xff,0xfffffff4(%ebp)
40004f26:	0f 8e ba fd ff ff    	jle    40004ce6 <dir_walk+0x1ae>
40004f2c:	8b 45 08             	mov    0x8(%ebp),%eax
40004f2f:	0f b6 00             	movzbl (%eax),%eax
40004f32:	3c 2e                	cmp    $0x2e,%al
40004f34:	75 2c                	jne    40004f62 <dir_walk+0x42a>
40004f36:	8b 45 08             	mov    0x8(%ebp),%eax
40004f39:	83 c0 01             	add    $0x1,%eax
40004f3c:	0f b6 00             	movzbl (%eax),%eax
40004f3f:	84 c0                	test   %al,%al
40004f41:	74 0d                	je     40004f50 <dir_walk+0x418>
40004f43:	8b 45 08             	mov    0x8(%ebp),%eax
40004f46:	83 c0 01             	add    $0x1,%eax
40004f49:	0f b6 00             	movzbl (%eax),%eax
40004f4c:	3c 2f                	cmp    $0x2f,%al
40004f4e:	75 12                	jne    40004f62 <dir_walk+0x42a>
40004f50:	c7 45 f8 01 00 00 00 	movl   $0x1,0xfffffff8(%ebp)
40004f57:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
40004f5a:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
40004f5d:	e9 2f fe ff ff       	jmp    40004d91 <dir_walk+0x259>
40004f62:	8b 45 08             	mov    0x8(%ebp),%eax
40004f65:	0f b6 00             	movzbl (%eax),%eax
40004f68:	3c 2e                	cmp    $0x2e,%al
40004f6a:	75 4b                	jne    40004fb7 <dir_walk+0x47f>
40004f6c:	8b 45 08             	mov    0x8(%ebp),%eax
40004f6f:	83 c0 01             	add    $0x1,%eax
40004f72:	0f b6 00             	movzbl (%eax),%eax
40004f75:	3c 2e                	cmp    $0x2e,%al
40004f77:	75 3e                	jne    40004fb7 <dir_walk+0x47f>
40004f79:	8b 45 08             	mov    0x8(%ebp),%eax
40004f7c:	83 c0 02             	add    $0x2,%eax
40004f7f:	0f b6 00             	movzbl (%eax),%eax
40004f82:	84 c0                	test   %al,%al
40004f84:	74 0d                	je     40004f93 <dir_walk+0x45b>
40004f86:	8b 45 08             	mov    0x8(%ebp),%eax
40004f89:	83 c0 02             	add    $0x2,%eax
40004f8c:	0f b6 00             	movzbl (%eax),%eax
40004f8f:	3c 2f                	cmp    $0x2f,%al
40004f91:	75 24                	jne    40004fb7 <dir_walk+0x47f>
40004f93:	c7 45 f8 02 00 00 00 	movl   $0x2,0xfffffff8(%ebp)
40004f9a:	8b 15 34 61 00 40    	mov    0x40006134,%edx
40004fa0:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
40004fa3:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004fa6:	01 d0                	add    %edx,%eax
40004fa8:	05 10 10 00 00       	add    $0x1010,%eax
40004fad:	8b 00                	mov    (%eax),%eax
40004faf:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
40004fb2:	e9 da fd ff ff       	jmp    40004d91 <dir_walk+0x259>
40004fb7:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
40004fbb:	74 17                	je     40004fd4 <dir_walk+0x49c>
40004fbd:	c7 44 24 04 2f 00 00 	movl   $0x2f,0x4(%esp)
40004fc4:	00 
40004fc5:	8b 45 08             	mov    0x8(%ebp),%eax
40004fc8:	89 04 24             	mov    %eax,(%esp)
40004fcb:	e8 89 e7 ff ff       	call   40003759 <strchr>
40004fd0:	85 c0                	test   %eax,%eax
40004fd2:	74 17                	je     40004feb <dir_walk+0x4b3>
40004fd4:	a1 34 61 00 40       	mov    0x40006134,%eax
40004fd9:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
40004fdf:	c7 45 e8 ff ff ff ff 	movl   $0xffffffff,0xffffffe8(%ebp)
40004fe6:	e9 2e 01 00 00       	jmp    40005119 <dir_walk+0x5e1>
40004feb:	8b 45 08             	mov    0x8(%ebp),%eax
40004fee:	89 04 24             	mov    %eax,(%esp)
40004ff1:	e8 d6 e5 ff ff       	call   400035cc <strlen>
40004ff6:	83 f8 3f             	cmp    $0x3f,%eax
40004ff9:	7e 17                	jle    40005012 <dir_walk+0x4da>
40004ffb:	a1 34 61 00 40       	mov    0x40006134,%eax
40005000:	c7 00 06 00 00 00    	movl   $0x6,(%eax)
40005006:	c7 45 e8 ff ff ff ff 	movl   $0xffffffff,0xffffffe8(%ebp)
4000500d:	e9 07 01 00 00       	jmp    40005119 <dir_walk+0x5e1>
40005012:	e8 f5 e9 ff ff       	call   40003a0c <fileino_alloc>
40005017:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
4000501a:	83 7d f4 00          	cmpl   $0x0,0xfffffff4(%ebp)
4000501e:	79 0c                	jns    4000502c <dir_walk+0x4f4>
40005020:	c7 45 e8 ff ff ff ff 	movl   $0xffffffff,0xffffffe8(%ebp)
40005027:	e9 ed 00 00 00       	jmp    40005119 <dir_walk+0x5e1>
4000502c:	83 7d f4 00          	cmpl   $0x0,0xfffffff4(%ebp)
40005030:	7e 33                	jle    40005065 <dir_walk+0x52d>
40005032:	81 7d f4 ff 00 00 00 	cmpl   $0xff,0xfffffff4(%ebp)
40005039:	7f 2a                	jg     40005065 <dir_walk+0x52d>
4000503b:	83 7d f4 00          	cmpl   $0x0,0xfffffff4(%ebp)
4000503f:	7e 48                	jle    40005089 <dir_walk+0x551>
40005041:	81 7d f4 ff 00 00 00 	cmpl   $0xff,0xfffffff4(%ebp)
40005048:	7f 3f                	jg     40005089 <dir_walk+0x551>
4000504a:	8b 15 34 61 00 40    	mov    0x40006134,%edx
40005050:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
40005053:	6b c0 5c             	imul   $0x5c,%eax,%eax
40005056:	01 d0                	add    %edx,%eax
40005058:	05 10 10 00 00       	add    $0x1010,%eax
4000505d:	0f b6 40 04          	movzbl 0x4(%eax),%eax
40005061:	84 c0                	test   %al,%al
40005063:	74 24                	je     40005089 <dir_walk+0x551>
40005065:	c7 44 24 0c 34 64 00 	movl   $0x40006434,0xc(%esp)
4000506c:	40 
4000506d:	c7 44 24 08 d8 63 00 	movl   $0x400063d8,0x8(%esp)
40005074:	40 
40005075:	c7 44 24 04 6f 00 00 	movl   $0x6f,0x4(%esp)
4000507c:	00 
4000507d:	c7 04 24 ed 63 00 40 	movl   $0x400063ed,(%esp)
40005084:	e8 4f db ff ff       	call   40002bd8 <debug_panic>
40005089:	8b 15 34 61 00 40    	mov    0x40006134,%edx
4000508f:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
40005092:	6b c0 5c             	imul   $0x5c,%eax,%eax
40005095:	05 10 10 00 00       	add    $0x1010,%eax
4000509a:	8d 04 02             	lea    (%edx,%eax,1),%eax
4000509d:	8d 50 04             	lea    0x4(%eax),%edx
400050a0:	8b 45 08             	mov    0x8(%ebp),%eax
400050a3:	89 44 24 04          	mov    %eax,0x4(%esp)
400050a7:	89 14 24             	mov    %edx,(%esp)
400050aa:	e8 43 e5 ff ff       	call   400035f2 <strcpy>
400050af:	8b 15 34 61 00 40    	mov    0x40006134,%edx
400050b5:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
400050b8:	6b c0 5c             	imul   $0x5c,%eax,%eax
400050bb:	01 d0                	add    %edx,%eax
400050bd:	8d 90 10 10 00 00    	lea    0x1010(%eax),%edx
400050c3:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
400050c6:	89 02                	mov    %eax,(%edx)
400050c8:	8b 15 34 61 00 40    	mov    0x40006134,%edx
400050ce:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
400050d1:	6b c0 5c             	imul   $0x5c,%eax,%eax
400050d4:	01 d0                	add    %edx,%eax
400050d6:	05 54 10 00 00       	add    $0x1054,%eax
400050db:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
400050e1:	8b 15 34 61 00 40    	mov    0x40006134,%edx
400050e7:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
400050ea:	6b c0 5c             	imul   $0x5c,%eax,%eax
400050ed:	01 d0                	add    %edx,%eax
400050ef:	8d 90 58 10 00 00    	lea    0x1058(%eax),%edx
400050f5:	8b 45 0c             	mov    0xc(%ebp),%eax
400050f8:	89 02                	mov    %eax,(%edx)
400050fa:	8b 15 34 61 00 40    	mov    0x40006134,%edx
40005100:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
40005103:	6b c0 5c             	imul   $0x5c,%eax,%eax
40005106:	01 d0                	add    %edx,%eax
40005108:	05 5c 10 00 00       	add    $0x105c,%eax
4000510d:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
40005113:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
40005116:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
40005119:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
4000511c:	83 c4 24             	add    $0x24,%esp
4000511f:	5b                   	pop    %ebx
40005120:	5d                   	pop    %ebp
40005121:	c3                   	ret    

40005122 <opendir>:
40005122:	55                   	push   %ebp
40005123:	89 e5                	mov    %esp,%ebp
40005125:	83 ec 28             	sub    $0x28,%esp
40005128:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
4000512f:	00 
40005130:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
40005137:	00 
40005138:	8b 45 08             	mov    0x8(%ebp),%eax
4000513b:	89 44 24 04          	mov    %eax,0x4(%esp)
4000513f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40005146:	e8 5e f3 ff ff       	call   400044a9 <filedesc_open>
4000514b:	89 45 f8             	mov    %eax,0xfffffff8(%ebp)
4000514e:	83 7d f8 00          	cmpl   $0x0,0xfffffff8(%ebp)
40005152:	75 0c                	jne    40005160 <opendir+0x3e>
40005154:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
4000515b:	e9 c1 00 00 00       	jmp    40005221 <opendir+0xff>
40005160:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
40005163:	8b 00                	mov    (%eax),%eax
40005165:	85 c0                	test   %eax,%eax
40005167:	7e 44                	jle    400051ad <opendir+0x8b>
40005169:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
4000516c:	8b 00                	mov    (%eax),%eax
4000516e:	3d ff 00 00 00       	cmp    $0xff,%eax
40005173:	7f 38                	jg     400051ad <opendir+0x8b>
40005175:	8b 15 34 61 00 40    	mov    0x40006134,%edx
4000517b:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
4000517e:	8b 00                	mov    (%eax),%eax
40005180:	6b c0 5c             	imul   $0x5c,%eax,%eax
40005183:	01 d0                	add    %edx,%eax
40005185:	05 10 10 00 00       	add    $0x1010,%eax
4000518a:	0f b6 40 04          	movzbl 0x4(%eax),%eax
4000518e:	84 c0                	test   %al,%al
40005190:	74 1b                	je     400051ad <opendir+0x8b>
40005192:	8b 15 34 61 00 40    	mov    0x40006134,%edx
40005198:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
4000519b:	8b 00                	mov    (%eax),%eax
4000519d:	6b c0 5c             	imul   $0x5c,%eax,%eax
400051a0:	01 d0                	add    %edx,%eax
400051a2:	05 58 10 00 00       	add    $0x1058,%eax
400051a7:	8b 00                	mov    (%eax),%eax
400051a9:	85 c0                	test   %eax,%eax
400051ab:	75 24                	jne    400051d1 <opendir+0xaf>
400051ad:	c7 44 24 0c 62 64 00 	movl   $0x40006462,0xc(%esp)
400051b4:	40 
400051b5:	c7 44 24 08 d8 63 00 	movl   $0x400063d8,0x8(%esp)
400051bc:	40 
400051bd:	c7 44 24 04 83 00 00 	movl   $0x83,0x4(%esp)
400051c4:	00 
400051c5:	c7 04 24 ed 63 00 40 	movl   $0x400063ed,(%esp)
400051cc:	e8 07 da ff ff       	call   40002bd8 <debug_panic>
400051d1:	a1 34 61 00 40       	mov    0x40006134,%eax
400051d6:	8d 90 10 10 00 00    	lea    0x1010(%eax),%edx
400051dc:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
400051df:	8b 00                	mov    (%eax),%eax
400051e1:	6b c0 5c             	imul   $0x5c,%eax,%eax
400051e4:	8d 04 02             	lea    (%edx,%eax,1),%eax
400051e7:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
400051ea:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
400051ed:	8b 40 48             	mov    0x48(%eax),%eax
400051f0:	25 00 70 00 00       	and    $0x7000,%eax
400051f5:	3d 00 20 00 00       	cmp    $0x2000,%eax
400051fa:	74 1f                	je     4000521b <opendir+0xf9>
400051fc:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
400051ff:	89 04 24             	mov    %eax,(%esp)
40005202:	e8 9a f8 ff ff       	call   40004aa1 <filedesc_close>
40005207:	a1 34 61 00 40       	mov    0x40006134,%eax
4000520c:	c7 00 05 00 00 00    	movl   $0x5,(%eax)
40005212:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
40005219:	eb 06                	jmp    40005221 <opendir+0xff>
4000521b:	8b 45 f8             	mov    0xfffffff8(%ebp),%eax
4000521e:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
40005221:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
40005224:	c9                   	leave  
40005225:	c3                   	ret    

40005226 <closedir>:
40005226:	55                   	push   %ebp
40005227:	89 e5                	mov    %esp,%ebp
40005229:	83 ec 08             	sub    $0x8,%esp
4000522c:	8b 45 08             	mov    0x8(%ebp),%eax
4000522f:	89 04 24             	mov    %eax,(%esp)
40005232:	e8 6a f8 ff ff       	call   40004aa1 <filedesc_close>
40005237:	b8 00 00 00 00       	mov    $0x0,%eax
4000523c:	c9                   	leave  
4000523d:	c3                   	ret    

4000523e <readdir>:
4000523e:	55                   	push   %ebp
4000523f:	89 e5                	mov    %esp,%ebp
40005241:	83 ec 28             	sub    $0x28,%esp
40005244:	a1 34 61 00 40       	mov    0x40006134,%eax
40005249:	83 c0 10             	add    $0x10,%eax
4000524c:	3b 45 08             	cmp    0x8(%ebp),%eax
4000524f:	77 1f                	ja     40005270 <readdir+0x32>
40005251:	a1 34 61 00 40       	mov    0x40006134,%eax
40005256:	83 c0 10             	add    $0x10,%eax
40005259:	05 00 10 00 00       	add    $0x1000,%eax
4000525e:	3b 45 08             	cmp    0x8(%ebp),%eax
40005261:	76 0d                	jbe    40005270 <readdir+0x32>
40005263:	8b 45 08             	mov    0x8(%ebp),%eax
40005266:	8b 00                	mov    (%eax),%eax
40005268:	85 c0                	test   %eax,%eax
4000526a:	0f 85 a1 00 00 00    	jne    40005311 <readdir+0xd3>
40005270:	c7 44 24 0c 7a 64 00 	movl   $0x4000647a,0xc(%esp)
40005277:	40 
40005278:	c7 44 24 08 d8 63 00 	movl   $0x400063d8,0x8(%esp)
4000527f:	40 
40005280:	c7 44 24 04 9a 00 00 	movl   $0x9a,0x4(%esp)
40005287:	00 
40005288:	c7 04 24 ed 63 00 40 	movl   $0x400063ed,(%esp)
4000528f:	e8 44 d9 ff ff       	call   40002bd8 <debug_panic>
40005294:	83 7d fc 00          	cmpl   $0x0,0xfffffffc(%ebp)
40005298:	7e 77                	jle    40005311 <readdir+0xd3>
4000529a:	81 7d fc ff 00 00 00 	cmpl   $0xff,0xfffffffc(%ebp)
400052a1:	7f 6e                	jg     40005311 <readdir+0xd3>
400052a3:	8b 15 34 61 00 40    	mov    0x40006134,%edx
400052a9:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
400052ac:	6b c0 5c             	imul   $0x5c,%eax,%eax
400052af:	01 d0                	add    %edx,%eax
400052b1:	05 10 10 00 00       	add    $0x1010,%eax
400052b6:	0f b6 40 04          	movzbl 0x4(%eax),%eax
400052ba:	84 c0                	test   %al,%al
400052bc:	74 53                	je     40005311 <readdir+0xd3>
400052be:	8b 15 34 61 00 40    	mov    0x40006134,%edx
400052c4:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
400052c7:	6b c0 5c             	imul   $0x5c,%eax,%eax
400052ca:	01 d0                	add    %edx,%eax
400052cc:	05 58 10 00 00       	add    $0x1058,%eax
400052d1:	8b 00                	mov    (%eax),%eax
400052d3:	85 c0                	test   %eax,%eax
400052d5:	74 3a                	je     40005311 <readdir+0xd3>
400052d7:	8b 15 34 61 00 40    	mov    0x40006134,%edx
400052dd:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
400052e0:	6b c0 5c             	imul   $0x5c,%eax,%eax
400052e3:	01 d0                	add    %edx,%eax
400052e5:	05 10 10 00 00       	add    $0x1010,%eax
400052ea:	8b 10                	mov    (%eax),%edx
400052ec:	8b 45 08             	mov    0x8(%ebp),%eax
400052ef:	8b 00                	mov    (%eax),%eax
400052f1:	39 c2                	cmp    %eax,%edx
400052f3:	75 1c                	jne    40005311 <readdir+0xd3>
400052f5:	8b 15 34 61 00 40    	mov    0x40006134,%edx
400052fb:	8b 45 fc             	mov    0xfffffffc(%ebp),%eax
400052fe:	6b c0 5c             	imul   $0x5c,%eax,%eax
40005301:	05 10 10 00 00       	add    $0x1010,%eax
40005306:	8d 04 02             	lea    (%edx,%eax,1),%eax
40005309:	83 c0 04             	add    $0x4,%eax
4000530c:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
4000530f:	eb 2b                	jmp    4000533c <readdir+0xfe>
40005311:	8b 45 08             	mov    0x8(%ebp),%eax
40005314:	8b 40 08             	mov    0x8(%eax),%eax
40005317:	89 45 fc             	mov    %eax,0xfffffffc(%ebp)
4000531a:	81 7d fc ff 00 00 00 	cmpl   $0xff,0xfffffffc(%ebp)
40005321:	0f 9e c1             	setle  %cl
40005324:	8d 50 01             	lea    0x1(%eax),%edx
40005327:	8b 45 08             	mov    0x8(%ebp),%eax
4000532a:	89 50 08             	mov    %edx,0x8(%eax)
4000532d:	84 c9                	test   %cl,%cl
4000532f:	0f 85 5f ff ff ff    	jne    40005294 <readdir+0x56>
40005335:	c7 45 ec 00 00 00 00 	movl   $0x0,0xffffffec(%ebp)
4000533c:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
4000533f:	c9                   	leave  
40005340:	c3                   	ret    

40005341 <rewinddir>:
40005341:	55                   	push   %ebp
40005342:	89 e5                	mov    %esp,%ebp
40005344:	8b 45 08             	mov    0x8(%ebp),%eax
40005347:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
4000534e:	5d                   	pop    %ebp
4000534f:	c3                   	ret    

40005350 <seekdir>:
40005350:	55                   	push   %ebp
40005351:	89 e5                	mov    %esp,%ebp
40005353:	8b 55 08             	mov    0x8(%ebp),%edx
40005356:	8b 45 0c             	mov    0xc(%ebp),%eax
40005359:	89 42 08             	mov    %eax,0x8(%edx)
4000535c:	5d                   	pop    %ebp
4000535d:	c3                   	ret    

4000535e <telldir>:
4000535e:	55                   	push   %ebp
4000535f:	89 e5                	mov    %esp,%ebp
40005361:	8b 45 08             	mov    0x8(%ebp),%eax
40005364:	8b 40 08             	mov    0x8(%eax),%eax
40005367:	5d                   	pop    %ebp
40005368:	c3                   	ret    
40005369:	90                   	nop    
4000536a:	90                   	nop    
4000536b:	90                   	nop    
4000536c:	90                   	nop    
4000536d:	90                   	nop    
4000536e:	90                   	nop    
4000536f:	90                   	nop    

40005370 <__udivdi3>:
40005370:	55                   	push   %ebp
40005371:	89 e5                	mov    %esp,%ebp
40005373:	57                   	push   %edi
40005374:	56                   	push   %esi
40005375:	83 ec 1c             	sub    $0x1c,%esp
40005378:	8b 45 10             	mov    0x10(%ebp),%eax
4000537b:	8b 55 14             	mov    0x14(%ebp),%edx
4000537e:	8b 7d 0c             	mov    0xc(%ebp),%edi
40005381:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
40005384:	89 c1                	mov    %eax,%ecx
40005386:	8b 45 08             	mov    0x8(%ebp),%eax
40005389:	85 d2                	test   %edx,%edx
4000538b:	89 d6                	mov    %edx,%esi
4000538d:	89 45 e8             	mov    %eax,0xffffffe8(%ebp)
40005390:	75 1e                	jne    400053b0 <__udivdi3+0x40>
40005392:	39 f9                	cmp    %edi,%ecx
40005394:	0f 86 8d 00 00 00    	jbe    40005427 <__udivdi3+0xb7>
4000539a:	89 fa                	mov    %edi,%edx
4000539c:	f7 f1                	div    %ecx
4000539e:	89 c1                	mov    %eax,%ecx
400053a0:	89 c8                	mov    %ecx,%eax
400053a2:	89 f2                	mov    %esi,%edx
400053a4:	83 c4 1c             	add    $0x1c,%esp
400053a7:	5e                   	pop    %esi
400053a8:	5f                   	pop    %edi
400053a9:	5d                   	pop    %ebp
400053aa:	c3                   	ret    
400053ab:	90                   	nop    
400053ac:	8d 74 26 00          	lea    0x0(%esi),%esi
400053b0:	39 fa                	cmp    %edi,%edx
400053b2:	0f 87 98 00 00 00    	ja     40005450 <__udivdi3+0xe0>
400053b8:	0f bd c2             	bsr    %edx,%eax
400053bb:	83 f0 1f             	xor    $0x1f,%eax
400053be:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
400053c1:	74 7f                	je     40005442 <__udivdi3+0xd2>
400053c3:	b8 20 00 00 00       	mov    $0x20,%eax
400053c8:	8b 55 f0             	mov    0xfffffff0(%ebp),%edx
400053cb:	2b 45 e4             	sub    0xffffffe4(%ebp),%eax
400053ce:	89 c1                	mov    %eax,%ecx
400053d0:	d3 ea                	shr    %cl,%edx
400053d2:	0f b6 4d e4          	movzbl 0xffffffe4(%ebp),%ecx
400053d6:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
400053d9:	89 f0                	mov    %esi,%eax
400053db:	d3 e0                	shl    %cl,%eax
400053dd:	09 c2                	or     %eax,%edx
400053df:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
400053e2:	89 55 e0             	mov    %edx,0xffffffe0(%ebp)
400053e5:	89 fa                	mov    %edi,%edx
400053e7:	d3 e0                	shl    %cl,%eax
400053e9:	0f b6 4d ec          	movzbl 0xffffffec(%ebp),%ecx
400053ed:	89 45 f4             	mov    %eax,0xfffffff4(%ebp)
400053f0:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
400053f3:	d3 e8                	shr    %cl,%eax
400053f5:	0f b6 4d e4          	movzbl 0xffffffe4(%ebp),%ecx
400053f9:	d3 e2                	shl    %cl,%edx
400053fb:	0f b6 4d ec          	movzbl 0xffffffec(%ebp),%ecx
400053ff:	09 d0                	or     %edx,%eax
40005401:	d3 ef                	shr    %cl,%edi
40005403:	89 fa                	mov    %edi,%edx
40005405:	f7 75 e0             	divl   0xffffffe0(%ebp)
40005408:	89 d1                	mov    %edx,%ecx
4000540a:	89 c7                	mov    %eax,%edi
4000540c:	8b 45 f4             	mov    0xfffffff4(%ebp),%eax
4000540f:	f7 e7                	mul    %edi
40005411:	39 d1                	cmp    %edx,%ecx
40005413:	89 c6                	mov    %eax,%esi
40005415:	89 55 dc             	mov    %edx,0xffffffdc(%ebp)
40005418:	72 6f                	jb     40005489 <__udivdi3+0x119>
4000541a:	39 ca                	cmp    %ecx,%edx
4000541c:	74 5e                	je     4000547c <__udivdi3+0x10c>
4000541e:	89 f9                	mov    %edi,%ecx
40005420:	31 f6                	xor    %esi,%esi
40005422:	e9 79 ff ff ff       	jmp    400053a0 <__udivdi3+0x30>
40005427:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
4000542a:	85 c0                	test   %eax,%eax
4000542c:	74 32                	je     40005460 <__udivdi3+0xf0>
4000542e:	89 f2                	mov    %esi,%edx
40005430:	89 f8                	mov    %edi,%eax
40005432:	f7 f1                	div    %ecx
40005434:	89 c6                	mov    %eax,%esi
40005436:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
40005439:	f7 f1                	div    %ecx
4000543b:	89 c1                	mov    %eax,%ecx
4000543d:	e9 5e ff ff ff       	jmp    400053a0 <__udivdi3+0x30>
40005442:	39 d7                	cmp    %edx,%edi
40005444:	77 2a                	ja     40005470 <__udivdi3+0x100>
40005446:	8b 55 f0             	mov    0xfffffff0(%ebp),%edx
40005449:	39 55 e8             	cmp    %edx,0xffffffe8(%ebp)
4000544c:	73 22                	jae    40005470 <__udivdi3+0x100>
4000544e:	66 90                	xchg   %ax,%ax
40005450:	31 c9                	xor    %ecx,%ecx
40005452:	31 f6                	xor    %esi,%esi
40005454:	e9 47 ff ff ff       	jmp    400053a0 <__udivdi3+0x30>
40005459:	8d b4 26 00 00 00 00 	lea    0x0(%esi),%esi
40005460:	b8 01 00 00 00       	mov    $0x1,%eax
40005465:	31 d2                	xor    %edx,%edx
40005467:	f7 75 f0             	divl   0xfffffff0(%ebp)
4000546a:	89 c1                	mov    %eax,%ecx
4000546c:	eb c0                	jmp    4000542e <__udivdi3+0xbe>
4000546e:	66 90                	xchg   %ax,%ax
40005470:	b9 01 00 00 00       	mov    $0x1,%ecx
40005475:	31 f6                	xor    %esi,%esi
40005477:	e9 24 ff ff ff       	jmp    400053a0 <__udivdi3+0x30>
4000547c:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
4000547f:	0f b6 4d e4          	movzbl 0xffffffe4(%ebp),%ecx
40005483:	d3 e0                	shl    %cl,%eax
40005485:	39 c6                	cmp    %eax,%esi
40005487:	76 95                	jbe    4000541e <__udivdi3+0xae>
40005489:	8d 4f ff             	lea    0xffffffff(%edi),%ecx
4000548c:	31 f6                	xor    %esi,%esi
4000548e:	e9 0d ff ff ff       	jmp    400053a0 <__udivdi3+0x30>
40005493:	90                   	nop    
40005494:	90                   	nop    
40005495:	90                   	nop    
40005496:	90                   	nop    
40005497:	90                   	nop    
40005498:	90                   	nop    
40005499:	90                   	nop    
4000549a:	90                   	nop    
4000549b:	90                   	nop    
4000549c:	90                   	nop    
4000549d:	90                   	nop    
4000549e:	90                   	nop    
4000549f:	90                   	nop    

400054a0 <__umoddi3>:
400054a0:	55                   	push   %ebp
400054a1:	89 e5                	mov    %esp,%ebp
400054a3:	57                   	push   %edi
400054a4:	56                   	push   %esi
400054a5:	83 ec 30             	sub    $0x30,%esp
400054a8:	8b 55 14             	mov    0x14(%ebp),%edx
400054ab:	8b 45 10             	mov    0x10(%ebp),%eax
400054ae:	8b 75 08             	mov    0x8(%ebp),%esi
400054b1:	8b 7d 0c             	mov    0xc(%ebp),%edi
400054b4:	85 d2                	test   %edx,%edx
400054b6:	c7 45 d0 00 00 00 00 	movl   $0x0,0xffffffd0(%ebp)
400054bd:	89 c1                	mov    %eax,%ecx
400054bf:	c7 45 d4 00 00 00 00 	movl   $0x0,0xffffffd4(%ebp)
400054c6:	89 45 ec             	mov    %eax,0xffffffec(%ebp)
400054c9:	89 55 e8             	mov    %edx,0xffffffe8(%ebp)
400054cc:	89 75 f0             	mov    %esi,0xfffffff0(%ebp)
400054cf:	89 7d e0             	mov    %edi,0xffffffe0(%ebp)
400054d2:	75 1c                	jne    400054f0 <__umoddi3+0x50>
400054d4:	39 f8                	cmp    %edi,%eax
400054d6:	89 fa                	mov    %edi,%edx
400054d8:	0f 86 d4 00 00 00    	jbe    400055b2 <__umoddi3+0x112>
400054de:	89 f0                	mov    %esi,%eax
400054e0:	f7 f1                	div    %ecx
400054e2:	89 55 d0             	mov    %edx,0xffffffd0(%ebp)
400054e5:	c7 45 d4 00 00 00 00 	movl   $0x0,0xffffffd4(%ebp)
400054ec:	eb 12                	jmp    40005500 <__umoddi3+0x60>
400054ee:	66 90                	xchg   %ax,%ax
400054f0:	8b 4d e0             	mov    0xffffffe0(%ebp),%ecx
400054f3:	39 4d e8             	cmp    %ecx,0xffffffe8(%ebp)
400054f6:	76 18                	jbe    40005510 <__umoddi3+0x70>
400054f8:	89 75 d0             	mov    %esi,0xffffffd0(%ebp)
400054fb:	89 7d d4             	mov    %edi,0xffffffd4(%ebp)
400054fe:	66 90                	xchg   %ax,%ax
40005500:	8b 45 d0             	mov    0xffffffd0(%ebp),%eax
40005503:	8b 55 d4             	mov    0xffffffd4(%ebp),%edx
40005506:	83 c4 30             	add    $0x30,%esp
40005509:	5e                   	pop    %esi
4000550a:	5f                   	pop    %edi
4000550b:	5d                   	pop    %ebp
4000550c:	c3                   	ret    
4000550d:	8d 76 00             	lea    0x0(%esi),%esi
40005510:	0f bd 45 e8          	bsr    0xffffffe8(%ebp),%eax
40005514:	83 f0 1f             	xor    $0x1f,%eax
40005517:	89 45 dc             	mov    %eax,0xffffffdc(%ebp)
4000551a:	0f 84 c0 00 00 00    	je     400055e0 <__umoddi3+0x140>
40005520:	b8 20 00 00 00       	mov    $0x20,%eax
40005525:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
40005528:	2b 45 dc             	sub    0xffffffdc(%ebp),%eax
4000552b:	8b 7d ec             	mov    0xffffffec(%ebp),%edi
4000552e:	8b 75 f0             	mov    0xfffffff0(%ebp),%esi
40005531:	89 c1                	mov    %eax,%ecx
40005533:	89 45 e4             	mov    %eax,0xffffffe4(%ebp)
40005536:	d3 ea                	shr    %cl,%edx
40005538:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
4000553b:	0f b6 4d dc          	movzbl 0xffffffdc(%ebp),%ecx
4000553f:	d3 e0                	shl    %cl,%eax
40005541:	09 c2                	or     %eax,%edx
40005543:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
40005546:	d3 e7                	shl    %cl,%edi
40005548:	0f b6 4d e4          	movzbl 0xffffffe4(%ebp),%ecx
4000554c:	89 55 f4             	mov    %edx,0xfffffff4(%ebp)
4000554f:	8b 55 e0             	mov    0xffffffe0(%ebp),%edx
40005552:	d3 e8                	shr    %cl,%eax
40005554:	0f b6 4d dc          	movzbl 0xffffffdc(%ebp),%ecx
40005558:	d3 e2                	shl    %cl,%edx
4000555a:	09 d0                	or     %edx,%eax
4000555c:	8b 55 e0             	mov    0xffffffe0(%ebp),%edx
4000555f:	d3 e6                	shl    %cl,%esi
40005561:	0f b6 4d e4          	movzbl 0xffffffe4(%ebp),%ecx
40005565:	d3 ea                	shr    %cl,%edx
40005567:	f7 75 f4             	divl   0xfffffff4(%ebp)
4000556a:	89 55 cc             	mov    %edx,0xffffffcc(%ebp)
4000556d:	f7 e7                	mul    %edi
4000556f:	39 55 cc             	cmp    %edx,0xffffffcc(%ebp)
40005572:	0f 82 a5 00 00 00    	jb     4000561d <__umoddi3+0x17d>
40005578:	3b 55 cc             	cmp    0xffffffcc(%ebp),%edx
4000557b:	0f 84 94 00 00 00    	je     40005615 <__umoddi3+0x175>
40005581:	8b 4d cc             	mov    0xffffffcc(%ebp),%ecx
40005584:	29 c6                	sub    %eax,%esi
40005586:	19 d1                	sbb    %edx,%ecx
40005588:	89 4d cc             	mov    %ecx,0xffffffcc(%ebp)
4000558b:	0f b6 4d dc          	movzbl 0xffffffdc(%ebp),%ecx
4000558f:	89 f2                	mov    %esi,%edx
40005591:	8b 45 cc             	mov    0xffffffcc(%ebp),%eax
40005594:	d3 ea                	shr    %cl,%edx
40005596:	0f b6 4d e4          	movzbl 0xffffffe4(%ebp),%ecx
4000559a:	d3 e0                	shl    %cl,%eax
4000559c:	0f b6 4d dc          	movzbl 0xffffffdc(%ebp),%ecx
400055a0:	09 c2                	or     %eax,%edx
400055a2:	8b 45 cc             	mov    0xffffffcc(%ebp),%eax
400055a5:	89 55 d0             	mov    %edx,0xffffffd0(%ebp)
400055a8:	d3 e8                	shr    %cl,%eax
400055aa:	89 45 d4             	mov    %eax,0xffffffd4(%ebp)
400055ad:	e9 4e ff ff ff       	jmp    40005500 <__umoddi3+0x60>
400055b2:	8b 45 ec             	mov    0xffffffec(%ebp),%eax
400055b5:	85 c0                	test   %eax,%eax
400055b7:	74 17                	je     400055d0 <__umoddi3+0x130>
400055b9:	8b 45 e0             	mov    0xffffffe0(%ebp),%eax
400055bc:	8b 55 e8             	mov    0xffffffe8(%ebp),%edx
400055bf:	f7 f1                	div    %ecx
400055c1:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
400055c4:	f7 f1                	div    %ecx
400055c6:	e9 17 ff ff ff       	jmp    400054e2 <__umoddi3+0x42>
400055cb:	90                   	nop    
400055cc:	8d 74 26 00          	lea    0x0(%esi),%esi
400055d0:	b8 01 00 00 00       	mov    $0x1,%eax
400055d5:	31 d2                	xor    %edx,%edx
400055d7:	f7 75 ec             	divl   0xffffffec(%ebp)
400055da:	89 c1                	mov    %eax,%ecx
400055dc:	eb db                	jmp    400055b9 <__umoddi3+0x119>
400055de:	66 90                	xchg   %ax,%ax
400055e0:	8b 45 e8             	mov    0xffffffe8(%ebp),%eax
400055e3:	39 45 e0             	cmp    %eax,0xffffffe0(%ebp)
400055e6:	77 19                	ja     40005601 <__umoddi3+0x161>
400055e8:	8b 55 ec             	mov    0xffffffec(%ebp),%edx
400055eb:	39 55 f0             	cmp    %edx,0xfffffff0(%ebp)
400055ee:	73 11                	jae    40005601 <__umoddi3+0x161>
400055f0:	8b 55 f0             	mov    0xfffffff0(%ebp),%edx
400055f3:	8b 4d e0             	mov    0xffffffe0(%ebp),%ecx
400055f6:	89 55 d0             	mov    %edx,0xffffffd0(%ebp)
400055f9:	89 4d d4             	mov    %ecx,0xffffffd4(%ebp)
400055fc:	e9 ff fe ff ff       	jmp    40005500 <__umoddi3+0x60>
40005601:	8b 4d e0             	mov    0xffffffe0(%ebp),%ecx
40005604:	8b 45 f0             	mov    0xfffffff0(%ebp),%eax
40005607:	2b 45 ec             	sub    0xffffffec(%ebp),%eax
4000560a:	1b 4d e8             	sbb    0xffffffe8(%ebp),%ecx
4000560d:	89 45 f0             	mov    %eax,0xfffffff0(%ebp)
40005610:	89 4d e0             	mov    %ecx,0xffffffe0(%ebp)
40005613:	eb db                	jmp    400055f0 <__umoddi3+0x150>
40005615:	39 f0                	cmp    %esi,%eax
40005617:	0f 86 64 ff ff ff    	jbe    40005581 <__umoddi3+0xe1>
4000561d:	29 f8                	sub    %edi,%eax
4000561f:	1b 55 f4             	sbb    0xfffffff4(%ebp),%edx
40005622:	e9 5a ff ff ff       	jmp    40005581 <__umoddi3+0xe1>
