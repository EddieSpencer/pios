
obj/boot/bootother.elf:     file format elf32-i386

Disassembly of section .text:

00001000 <start>:
	.long bioscall

bootother:

	cli                         # Disable interrupts
    1000:	08 10                	or     %dl,(%eax)
    1002:	00 00                	add    %al,(%eax)
    1004:	54                   	push   %esp
    1005:	10 00                	adc    %al,(%eax)
	...

00001008 <bootother>:
    1008:	fa                   	cli    

	# Set up the important data segment registers (DS, ES, SS).
	xorw    %ax,%ax             # Segment number zero
    1009:	31 c0                	xor    %eax,%eax
	movw    %ax,%ds             # -> Data Segment
    100b:	8e d8                	movl   %eax,%ds
	movw    %ax,%es             # -> Extra Segment
    100d:	8e c0                	movl   %eax,%es
	movw    %ax,%ss             # -> Stack Segment
    100f:	8e d0                	movl   %eax,%ss

	# Switch from real to protected mode, using a bootstrap GDT
	# and segment translation that makes virtual addresses 
	# identical to physical addresses, so that the 
	# effective memory map does not change during the switch.
	lgdt    gdtdesc
    1011:	0f 01 16             	lgdtl  (%esi)
    1014:	b4 11                	mov    $0x11,%ah
	movl    %cr0, %eax
    1016:	0f 20 c0             	mov    %cr0,%eax
	orl     $CR0_PE, %eax
    1019:	66 83 c8 01          	or     $0x1,%ax
	movl    %eax, %cr0
    101d:	0f 22 c0             	mov    %eax,%cr0

	# Jump to next instruction, but in 32-bit code segment.
	# Switches processor into 32-bit mode.
	ljmp    $(SEG_KCODE<<3), $start32
    1020:	ea 25 10 08 00 66 b8 	ljmp   $0xb866,$0x81025

00001025 <start32>:

.code32                       # Assemble for 32-bit mode
start32:
	# Set up the protected-mode data segment registers
	movw    $(SEG_KDATA<<3), %ax    # Our data segment selector
    1025:	66 b8 10 00          	mov    $0x10,%ax
	movw    %ax, %ds                # -> DS: Data Segment
    1029:	8e d8                	movl   %eax,%ds
	movw    %ax, %es                # -> ES: Extra Segment
    102b:	8e c0                	movl   %eax,%es
	movw    %ax, %ss                # -> SS: Stack Segment
    102d:	8e d0                	movl   %eax,%ss
	movw    $0, %ax                 # Zero segments not ready for use
    102f:	66 b8 00 00          	mov    $0x0,%ax
	movw    %ax, %fs                # -> FS
    1033:	8e e0                	movl   %eax,%fs
	movw    %ax, %gs                # -> GS
    1035:	8e e8                	movl   %eax,%gs

	# Set up the stack pointer and call into C.
	movl    start-4, %esp
    1037:	8b 25 fc 0f 00 00    	mov    0xffc,%esp
	call	*(start-8)
    103d:	ff 15 f8 0f 00 00    	call   *0xff8

	# If the call returns (it shouldn't), trigger a Bochs
	# breakpoint if running under Bochs, then loop.
	movw    $0x8a00, %ax            # 0x8a00 -> port 0x8a00
    1043:	66 b8 00 8a          	mov    $0x8a00,%ax
	movw    %ax, %dx
    1047:	66 89 c2             	mov    %ax,%dx
	outw    %ax, %dx
    104a:	66 ef                	out    %ax,(%dx)
	movw    $0x8e00, %ax            # 0x8e00 -> port 0x8a00
    104c:	66 b8 00 8e          	mov    $0x8e00,%ax
	outw    %ax, %dx
    1050:	66 ef                	out    %ax,(%dx)

00001052 <spin>:
spin:
	jmp     spin
    1052:	eb fe                	jmp    1052 <spin>

00001054 <bioscall>:


.code32
.globl bioscall
bioscall:
	//we are still in 32-bit mode.

	pushal
    1054:	60                   	pusha  
	pushl %fs
    1055:	0f a0                	push   %fs
	pushl %gs
    1057:	0f a8                	push   %gs
	pushl %ds
    1059:	1e                   	push   %ds
	pushl %es
    105a:	06                   	push   %es
	pushl %ss
    105b:	16                   	push   %ss

	pushl %ebx
    105c:	53                   	push   %ebx
	pushl %esi
    105d:	56                   	push   %esi
	pushl %edi
    105e:	57                   	push   %edi
	pushl %ebp
    105f:	55                   	push   %ebp

	movl $(BIOSCALL_MEM_START+PROT_ESP),%eax
    1060:	b8 e8 0b 00 00       	mov    $0xbe8,%eax
	movl %esp,(%eax)
    1065:	89 20                	mov    %esp,(%eax)

	//save the protected mode IDT and GDT
	sidt BIOSCALL_MEM_START+IDT_MEM_LOC
    1067:	0f 01 0d f0 0b 00 00 	sidtl  0xbf0
	sgdt BIOSCALL_MEM_START+GDT_MEM_LOC
    106e:	0f 01 05 f6 0b 00 00 	sgdtl  0xbf6

	//start the transition into real mode
	cli
    1075:	fa                   	cli    

	// disable paging 
//TODO:: Save the paging bit in a location and restore it. Dont disable and enable (since bios may be called w or w/o paging)
	movl    %cr0,%eax
    1076:	0f 20 c0             	mov    %cr0,%eax
	//andl    $~CR0_PG,%eax
	movl    %eax,%cr0
    1079:	0f 22 c0             	mov    %eax,%cr0

	//flush TLB
	movl $0,%eax
    107c:	b8 00 00 00 00       	mov    $0x0,%eax
	movl  %eax,%cr3
    1081:	0f 22 d8             	mov    %eax,%cr3


	lgdt gdtdesc
    1084:	0f 01 15 b4 11 00 00 	lgdtl  0x11b4
	ljmp  $(SEG_CODE_16<<3),$1f
    108b:	ea 92 10 00 00 18 00 	ljmp   $0x18,$0x1092

.code16
1:
	//in 16 bit protected mode

	movw $(SEG_DATA_16<<3),%ax
    1092:	b8 20 00 8e d8       	mov    $0xd88e0020,%eax
	movw %ax,%ds
	movw %ax,%ss
    1097:	8e d0                	movl   %eax,%ss
	movw %ax,%es
    1099:	8e c0                	movl   %eax,%es
	movw %ax,%fs
    109b:	8e e0                	movl   %eax,%fs
	movw %ax,%gs
    109d:	8e e8                	movl   %eax,%gs

	lidt realidtptr
    109f:	0f 01 1e             	lidtl  (%esi)
    10a2:	ba 11 bd fe 0f       	mov    $0xffebd11,%edx

	//patch the int instruction
	movw $(start-BIOSREGS_SIZE+BIOSREGS_INT_NO),%bp 
	movb (%bp),%al
    10a7:	8a 46 00             	mov    0x0(%esi),%al
	movb %al,int_call+1
    10aa:	a2 04 11 0f 20       	mov    %al,0x200f1104


	//disable protection bit
	movl %cr0,%eax
    10af:	c0 66 83 e0          	shlb   $0xe0,0xffffff83(%esi)
	andl $~CR0_PE,%eax
    10b3:	fe 0f                	decb   (%edi)
	movl %eax,%cr0
    10b5:	22 c0                	and    %al,%al

	ljmp $0,$1f
    10b7:	ea bc 10 00 00 31 c0 	ljmp   $0xc031,$0x10bc

//real mode begins
1:

	// reload the real stack segment
	xorw %ax,%ax
	movw %ax,%ss
    10be:	8e d0                	movl   %eax,%ss
	movw %ax,%ds
    10c0:	8e d8                	movl   %eax,%ds
	movw %ax,%es
    10c2:	8e c0                	movl   %eax,%es
	movw %ax,%fs
    10c4:	8e e0                	movl   %eax,%fs
	movw %ax,%gs
    10c6:	8e e8                	movl   %eax,%gs

	//set up the real mode sp
	movw REAL_STACK_HI,%sp
    10c8:	8b 26                	mov    (%esi),%esp
    10ca:	b8 0b bd e2 0f       	mov    $0xfe2bd0b,%eax
	
	//load the registers needed by the BIOS
	movw $(start-BIOSREGS_SIZE+BIOSREGS_EAX),%bp
	movl (%bp),%eax
    10cf:	66 8b 46 00          	mov    0x0(%esi),%ax
	movw $(start-BIOSREGS_SIZE+BIOSREGS_EBX),%bp
    10d3:	bd e6 0f 66 8b       	mov    $0x8b660fe6,%ebp
	movl (%bp),%ebx
    10d8:	5e                   	pop    %esi
    10d9:	00 bd ea 0f 66 8b    	add    %bh,0x8b660fea(%ebp)
	movw $(start-BIOSREGS_SIZE+BIOSREGS_ECX),%bp
	movl (%bp),%ecx
    10df:	4e                   	dec    %esi
    10e0:	00 bd ee 0f 66 8b    	add    %bh,0x8b660fee(%ebp)
	movw $(start-BIOSREGS_SIZE+BIOSREGS_EDX),%bp
	movl (%bp),%edx
    10e6:	56                   	push   %esi
    10e7:	00 bd f2 0f 66 8b    	add    %bh,0x8b660ff2(%ebp)
	movw $(start-BIOSREGS_SIZE+BIOSREGS_ESI),%bp
	movl (%bp),%esi
    10ed:	76 00                	jbe    10ef <bioscall+0x9b>
	movw $(start-BIOSREGS_SIZE+BIOSREGS_EDI),%bp
    10ef:	bd f6 0f 66 8b       	mov    $0x8b660ff6,%ebp
	movl (%bp),%edi
    10f4:	7e 00                	jle    10f6 <bioscall+0xa2>
	movw $(start-BIOSREGS_SIZE+BIOSREGS_DS),%bp
    10f6:	bd fa 0f 8e 5e       	mov    $0x5e8e0ffa,%ebp
	movw (%bp),%ds
    10fb:	00 bd fc 0f 8e 46    	add    %bh,0x468e0ffc(%ebp)
	movw $(start-BIOSREGS_SIZE+BIOSREGS_ES),%bp
	movw (%bp),%es
    1101:	00 fa                	add    %bh,%dl

00001103 <int_call>:

	//make the bios call
	cli
int_call:
	int $0
    1103:	cd 00                	int    $0x0


	//move the register values back to the struct
	movw $(start-BIOSREGS_SIZE+BIOSREGS_EAX),%bp
    1105:	bd e2 0f 66 89       	mov    $0x89660fe2,%ebp
	movl %eax,(%bp)
    110a:	46                   	inc    %esi
    110b:	00 bd e6 0f 66 89    	add    %bh,0x89660fe6(%ebp)
	movw $(start-BIOSREGS_SIZE+BIOSREGS_EBX),%bp
	movl %ebx,(%bp)
    1111:	5e                   	pop    %esi
    1112:	00 bd ea 0f 66 89    	add    %bh,0x89660fea(%ebp)
	movw $(start-BIOSREGS_SIZE+BIOSREGS_ECX),%bp
	movl %ecx,(%bp)
    1118:	4e                   	dec    %esi
    1119:	00 bd ee 0f 66 89    	add    %bh,0x89660fee(%ebp)
	movw $(start-BIOSREGS_SIZE+BIOSREGS_EDX),%bp
	movl %edx,(%bp)
    111f:	56                   	push   %esi
    1120:	00 bd f2 0f 66 89    	add    %bh,0x89660ff2(%ebp)
	movw $(start-BIOSREGS_SIZE+BIOSREGS_ESI),%bp
	movl %esi,(%bp)
    1126:	76 00                	jbe    1128 <int_call+0x25>
	movw $(start-BIOSREGS_SIZE+BIOSREGS_EDI),%bp
    1128:	bd f6 0f 66 89       	mov    $0x89660ff6,%ebp
	movl %edi,(%bp)
    112d:	7e 00                	jle    112f <int_call+0x2c>
	movw $(start-BIOSREGS_SIZE+BIOSREGS_DS),%bp
    112f:	bd fa 0f 8c 5e       	mov    $0x5e8c0ffa,%ebp
	movw %ds,(%bp)
    1134:	00 bd fc 0f 8c 46    	add    %bh,0x468c0ffc(%ebp)
	movw $(start-BIOSREGS_SIZE+BIOSREGS_ES),%bp
	movw %es,(%bp)
    113a:	00 0f                	add    %cl,(%edi)

	//check the carry flag
	setc %al
    113c:	92                   	xchg   %eax,%edx
    113d:	c0 bd ff 0f 88 46 00 	sarb   $0x0,0x46880fff(%ebp)
	movw $(start-BIOSREGS_SIZE+BIOSREGS_CF),%bp
	movb %al,(%bp)

	//prepare to go back in 32 bit
//	cli

	//load the protected mode gdt	
	//lgdt gdtdesc
	lidt BIOSCALL_MEM_START+IDT_MEM_LOC
    1144:	0f 01 1e             	lidtl  (%esi)
    1147:	f0 0b 0f             	lock or (%edi),%ecx
	lgdt BIOSCALL_MEM_START+GDT_MEM_LOC
    114a:	01 16                	add    %edx,(%esi)
    114c:	f6 0b                	(bad)  (%ebx)


	// re-enter protected mode
	movl    %cr0, %eax
    114e:	0f 20 c0             	mov    %cr0,%eax
	orl     $CR0_PE, %eax
    1151:	66 83 c8 01          	or     $0x1,%ax
	movl    %eax, %cr0
    1155:	0f 22 c0             	mov    %eax,%cr0

	ljmp    $(SEG_KCODE<<3), $1f
    1158:	ea 5d 11 08 00 66 b8 	ljmp   $0xb866,$0x8115d
.code32
1:      // we are now in a 32-bit protected mode code segment.


	//set the segment registers
	movw    $(SEG_KDATA<<3), %ax    # Our data segment selector
    115f:	10 00                	adc    %al,(%eax)
	movw    %ax, %ds                # -> DS: Data Segment
    1161:	8e d8                	movl   %eax,%ds
	movw    %ax, %es                # -> ES: Extra Segment
    1163:	8e c0                	movl   %eax,%es
	movw    %ax, %ss                # -> SS: Stack Segment
    1165:	8e d0                	movl   %eax,%ss
	movw    $0, %ax                 # Zero segments not ready for use
    1167:	66 b8 00 00          	mov    $0x0,%ax
	movw    %ax, %fs                # -> FS
    116b:	8e e0                	movl   %eax,%fs
	movw    %ax, %gs                # -> GS
    116d:	8e e8                	movl   %eax,%gs

	//enable paging
	movl    %cr0,%eax
    116f:	0f 20 c0             	mov    %cr0,%eax
	//orl    $CR0_PG,%eax
	movl    %eax,%cr0
    1172:	0f 22 c0             	mov    %eax,%cr0


	//restore protected mode stack
	movl $(BIOSCALL_MEM_START+PROT_ESP),%eax
    1175:	b8 e8 0b 00 00       	mov    $0xbe8,%eax
	movl (%eax),%esp
    117a:	8b 20                	mov    (%eax),%esp


	popl %ebp
    117c:	5d                   	pop    %ebp
	popl %edi
    117d:	5f                   	pop    %edi
	popl %esi
    117e:	5e                   	pop    %esi
	popl %ebx
    117f:	5b                   	pop    %ebx

	popl %ss
    1180:	17                   	pop    %ss
	popl %es
    1181:	07                   	pop    %es
	popl %ds
    1182:	1f                   	pop    %ds
	popl %gs
    1183:	0f a9                	pop    %gs
	popl %fs
    1185:	0f a1                	pop    %fs
	popal
    1187:	61                   	popa   

	ret
    1188:	c3                   	ret    
    1189:	8d 76 00             	lea    0x0(%esi),%esi

0000118c <gdt>:
	...
    1194:	ff                   	(bad)  
    1195:	ff 00                	incl   (%eax)
    1197:	00 00                	add    %al,(%eax)
    1199:	9a cf 00 ff ff 00 00 	lcall  $0x0,$0xffff00cf
    11a0:	00 92 cf 00 0f 00    	add    %dl,0xf00cf(%edx)
    11a6:	00 00                	add    %al,(%eax)
    11a8:	00 9a 20 00 0f 00    	add    %bl,0xf0020(%edx)
    11ae:	00 00                	add    %al,(%eax)
    11b0:	00 92 20 00 27 00    	add    %dl,0x270020(%edx)

000011b4 <gdtdesc>:
    11b4:	27                   	daa    
    11b5:	00 8c 11 00 00 ff 03 	add    %cl,0x3ff0000(%ecx,%edx,1)

000011ba <realidtptr>:
    11ba:	ff 03                	incl   (%ebx)
    11bc:	00 00                	add    %al,(%eax)
	...
