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
TRAPHANDLER_NOEC(trap_divide,T_DIVIDE)
//TRAPHANDLER(trap_debug,T_DEBUG)
TRAPHANDLER_NOEC(trap_nmi,T_NMI)
TRAPHANDLER_NOEC(trap_brkpt,T_BRKPT)
TRAPHANDLER_NOEC(trap_oflow,T_OFLOW)
TRAPHANDLER_NOEC(trap_bound,T_BOUND)
TRAPHANDLER_NOEC(trap_illop,T_ILLOP)
TRAPHANDLER_NOEC(trap_device,T_DEVICE)
TRAPHANDLER_NOEC(trap_dblflt,T_DBLFLT)
TRAPHANDLER     (trap_tss,T_TSS)
TRAPHANDLER     (trap_segnp,T_SEGNP)
TRAPHANDLER     (trap_stack,T_STACK)
TRAPHANDLER     (trap_gpflt,T_GPFLT)
TRAPHANDLER     (trap_pgflt,T_PGFLT)
TRAPHANDLER_NOEC(trap_fperr,T_FPERR)
TRAPHANDLER_NOEC(trap_align,T_ALIGN)
TRAPHANDLER     (trap_mchk,T_MCHK)
TRAPHANDLER_NOEC(trap_simd,T_SIMD)
TRAPHANDLER     (trap_secev,T_SECEV) //Not is intel doc
TRAPHANDLER_NOEC(trap_irq0,T_IRQ0)
TRAPHANDLER_NOEC(trap_syscall,T_SYSCALL)
TRAPHANDLER_NOEC(trap_ltimer,T_LTIMER)
TRAPHANDLER_NOEC(trap_lerror,T_LERROR)
//TRAPHANDLER   (trap_default,T_DEFAULT)
//TRAPHANDLER   (trap_icnt,T_ICNT)

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

