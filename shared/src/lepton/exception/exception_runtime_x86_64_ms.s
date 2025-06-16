.text
.globl lepton_setjmp
lepton_setjmp:
    # rcx = env

    # save return address
    movq (%rsp), %rax
	movq %rax,  0(%rcx)

    # save stack pointer (rsp + 8 = skip return address)
	leaq 8(%rsp), %rax
	movq %rax,  8(%rcx)
    
    # save callee-saved registers
	movq %rbp, 16(%rcx)
	movq %rbx, 24(%rcx)
	movq %rdi, 32(%rcx)
	movq %rsi, 40(%rcx)
	movq %r12, 48(%rcx)
	movq %r13, 56(%rcx)
	movq %r14, 64(%rcx)
	movq %r15, 72(%rcx)

    # return 0
	xorl %eax, %eax
	ret

.text
.globl lepton_longjmp
lepton_longjmp:
    # rcx = env
    # edx = val

    # restore callee-saved
    movq 72(%rcx), %r15
	movq 64(%rcx), %r14
	movq 56(%rcx), %r13
	movq 48(%rcx), %r12
	movq 40(%rcx), %rsi
	movq 32(%rcx), %rdi
	movq 24(%rcx), %rbx
	movq 16(%rcx), %rbp

    # restore rsp
	movq  8(%rcx), %rsp

    # set return value and jump
	movl %edx, %eax
	jmp *0(%rcx)
