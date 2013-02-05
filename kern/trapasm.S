/*
 * Trap handler entry and exit code, written in assembly language.
 *
 * Copyright (C) 1997 Massachusetts Institute of Technology
 * See section "MIT License" in the file LICENSES for licensing terms.
 *
 * Derived from the MIT Exokernel and JOS.
 * Adapted for PIOS by Bryan Ford at Yale University.
 */

#include <inc/mmu.h>
#include <inc/trap.h>

#include <kern/cpu.h>



/* The TRAPHANDLER macro defines a globally-visible function for handling
 * a trap.  It pushes a trap number onto the stack, then jumps to _alltraps.
 * Use TRAPHANDLER for traps where the CPU automatically pushes an error code.
 */ 
#define TRAPHANDLER(name, num)						\
	.globl name;		/* define global symbol for 'name' */	\
	.type name, @function;	/* symbol type is function */		\
	.align 2;		/* align function definition */		\
	name:			/* function starts here */		\
	pushl $(num);							\
	jmp _alltraps

/* Use TRAPHANDLER_NOEC for traps where the CPU doesn't push an error code.
 * It pushes a 0 in place of the error code, so the trap frame has the same
 * format in either case.
 */
#define TRAPHANDLER_NOEC(name, num)					\
	.globl name;							\
	.type name, @function;						\
	.align 2;							\
	name:								\
	pushl $0;							\
	pushl $(num);							\
	jmp _alltraps

.text

/*
 * Lab 1: Your code here for generating entry points for the different traps.
 */
TRAPHANDLER(trap000, 0)
TRAPHANDLER(trap001, 1)
TRAPHANDLER(trap002, 2)
TRAPHANDLER(trap003, 3)
TRAPHANDLER(trap004, 4)
TRAPHANDLER(trap005, 5)
TRAPHANDLER(trap006, 6)
TRAPHANDLER(trap007, 7)
TRAPHANDLER(trap010, 8)
TRAPHANDLER(trap011, 9)
TRAPHANDLER(trap012, 10)
TRAPHANDLER(trap013, 11)
TRAPHANDLER(trap014, 12)
TRAPHANDLER(trap015, 13)
TRAPHANDLER(trap016, 14)
TRAPHANDLER(trap017, 15)
TRAPHANDLER(trap020, 16)
TRAPHANDLER(trap021, 17)
TRAPHANDLER(trap022, 18)
TRAPHANDLER(trap023, 19)
TRAPHANDLER(trap024, 20)
TRAPHANDLER(trap025, 21)
TRAPHANDLER(trap026, 22)
TRAPHANDLER(trap027, 23)
TRAPHANDLER(trap030, 24)
TRAPHANDLER(trap031, 25)
TRAPHANDLER(trap032, 26)
TRAPHANDLER(trap033, 27)
TRAPHANDLER(trap034, 28)
TRAPHANDLER(trap035, 29)
TRAPHANDLER(trap036, 30)
TRAPHANDLER(trap037, 31)
TRAPHANDLER(trap040, 32)
TRAPHANDLER(trap041, 33)
TRAPHANDLER(trap042, 34)
TRAPHANDLER(trap043, 35)
TRAPHANDLER(trap044, 36)
TRAPHANDLER(trap045, 37)
TRAPHANDLER(trap046, 38)
TRAPHANDLER(trap047, 39)
TRAPHANDLER(trap050, 40)
TRAPHANDLER(trap051, 41)
TRAPHANDLER(trap052, 42)
TRAPHANDLER(trap053, 43)
TRAPHANDLER(trap054, 44)
TRAPHANDLER(trap055, 45)
TRAPHANDLER(trap056, 46)
TRAPHANDLER(trap057, 47)
TRAPHANDLER(trap060, 48)
TRAPHANDLER(trap061, 49)
TRAPHANDLER(trap062, 50)
TRAPHANDLER(trap063, 51)
TRAPHANDLER(trap064, 52)
TRAPHANDLER(trap065, 53)
TRAPHANDLER(trap066, 54)
TRAPHANDLER(trap067, 55)
TRAPHANDLER(trap070, 56)
TRAPHANDLER(trap071, 57)
TRAPHANDLER(trap072, 58)
TRAPHANDLER(trap073, 59)
TRAPHANDLER(trap074, 60)
TRAPHANDLER(trap075, 61)
TRAPHANDLER(trap076, 62)
TRAPHANDLER(trap077, 63)
TRAPHANDLER(trap100, 64)
TRAPHANDLER(trap101, 65)
TRAPHANDLER(trap102, 66)
TRAPHANDLER(trap103, 67)
TRAPHANDLER(trap104, 68)
TRAPHANDLER(trap105, 69)
TRAPHANDLER(trap106, 70)
TRAPHANDLER(trap107, 71)
TRAPHANDLER(trap110, 72)
TRAPHANDLER(trap111, 73)
TRAPHANDLER(trap112, 74)
TRAPHANDLER(trap113, 75)
TRAPHANDLER(trap114, 76)
TRAPHANDLER(trap115, 77)
TRAPHANDLER(trap116, 78)
TRAPHANDLER(trap117, 79)
TRAPHANDLER(trap120, 80)
TRAPHANDLER(trap121, 81)
TRAPHANDLER(trap122, 82)
TRAPHANDLER(trap123, 83)
TRAPHANDLER(trap124, 84)
TRAPHANDLER(trap125, 85)
TRAPHANDLER(trap126, 86)
TRAPHANDLER(trap127, 87)
TRAPHANDLER(trap130, 88)
TRAPHANDLER(trap131, 89)
TRAPHANDLER(trap132, 90)
TRAPHANDLER(trap133, 91)
TRAPHANDLER(trap134, 92)
TRAPHANDLER(trap135, 93)
TRAPHANDLER(trap136, 94)
TRAPHANDLER(trap137, 95)
TRAPHANDLER(trap140, 96)
TRAPHANDLER(trap141, 97)
TRAPHANDLER(trap142, 98)
TRAPHANDLER(trap143, 99)
TRAPHANDLER(trap144, 100)
TRAPHANDLER(trap145, 101)
TRAPHANDLER(trap146, 102)
TRAPHANDLER(trap147, 103)
TRAPHANDLER(trap150, 104)
TRAPHANDLER(trap151, 105)
TRAPHANDLER(trap152, 106)
TRAPHANDLER(trap153, 107)
TRAPHANDLER(trap154, 108)
TRAPHANDLER(trap155, 109)
TRAPHANDLER(trap156, 110)
TRAPHANDLER(trap157, 111)
TRAPHANDLER(trap160, 112)
TRAPHANDLER(trap161, 113)
TRAPHANDLER(trap162, 114)
TRAPHANDLER(trap163, 115)
TRAPHANDLER(trap164, 116)
TRAPHANDLER(trap165, 117)
TRAPHANDLER(trap166, 118)
TRAPHANDLER(trap167, 119)
TRAPHANDLER(trap170, 120)
TRAPHANDLER(trap171, 121)
TRAPHANDLER(trap172, 122)
TRAPHANDLER(trap173, 123)
TRAPHANDLER(trap174, 124)
TRAPHANDLER(trap175, 125)
TRAPHANDLER(trap176, 126)
TRAPHANDLER(trap177, 127)
TRAPHANDLER(trap200, 128)
TRAPHANDLER(trap201, 129)
TRAPHANDLER(trap202, 130)
TRAPHANDLER(trap203, 131)
TRAPHANDLER(trap204, 132)
TRAPHANDLER(trap205, 133)
TRAPHANDLER(trap206, 134)
TRAPHANDLER(trap207, 135)
TRAPHANDLER(trap210, 136)
TRAPHANDLER(trap211, 137)
TRAPHANDLER(trap212, 138)
TRAPHANDLER(trap213, 139)
TRAPHANDLER(trap214, 140)
TRAPHANDLER(trap215, 141)
TRAPHANDLER(trap216, 142)
TRAPHANDLER(trap217, 143)
TRAPHANDLER(trap220, 144)
TRAPHANDLER(trap221, 145)
TRAPHANDLER(trap222, 146)
TRAPHANDLER(trap223, 147)
TRAPHANDLER(trap224, 148)
TRAPHANDLER(trap225, 149)
TRAPHANDLER(trap226, 150)
TRAPHANDLER(trap227, 151)
TRAPHANDLER(trap230, 152)
TRAPHANDLER(trap231, 153)
TRAPHANDLER(trap232, 154)
TRAPHANDLER(trap233, 155)
TRAPHANDLER(trap234, 156)
TRAPHANDLER(trap235, 157)
TRAPHANDLER(trap236, 158)
TRAPHANDLER(trap237, 159)
TRAPHANDLER(trap240, 160)
TRAPHANDLER(trap241, 161)
TRAPHANDLER(trap242, 162)
TRAPHANDLER(trap243, 163)
TRAPHANDLER(trap244, 164)
TRAPHANDLER(trap245, 165)
TRAPHANDLER(trap246, 166)
TRAPHANDLER(trap247, 167)
TRAPHANDLER(trap250, 168)
TRAPHANDLER(trap251, 169)
TRAPHANDLER(trap252, 170)
TRAPHANDLER(trap253, 171)
TRAPHANDLER(trap254, 172)
TRAPHANDLER(trap255, 173)

/*
 * Lab 1: Your code here for _alltraps
 */
 .globl _alltraps
 _alltraps:
  // Build struct trapframe
  pushal;

  // load CPU_GDT_KDATA into %ds and %es
  mov CPU_GDT_KDATA, %ds;
  mov CPU_GDT_KDATA, %es;

  // push esp to pass a pointer to the trapframe as an argument to trap()
  pushl %esp;

  // call trap
  call trap;
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
1:	jmp	1b		// just spin

