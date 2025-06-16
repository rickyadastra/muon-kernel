.text
.globl lepton_setjmp
.type lepton_setjmp, @function
lepton_setjmp:
    # rdi = env

    # save return address
    movq (%rsp), %rax
    movq %rax, 0(%rdi)

    # save stack pointer
    movq %rsp,  8(%rdi)

    # save callee-saved registers
    movq %rbp, 16(%rdi)
    movq %r12, 24(%rdi)
    movq %r13, 32(%rdi)
    movq %r14, 40(%rdi)
    movq %r15, 48(%rdi)
    movq %rbx, 56(%rdi)

    # return 0
    xorl %eax, %eax
    ret

.globl lepton_longjmp
.type lepton_longjmp, @function
lepton_longjmp:
    # rdi = env
    # esi = val

    # restore callee-saved
    movq 56(%rdi), %rbx
    movq 48(%rdi), %r15
    movq 40(%rdi), %r14
    movq 32(%rdi), %r13
    movq 24(%rdi), %r12
    movq 16(%rdi), %rbp

    # restore rsp
    movq  8(%rdi), %rsp

    # set return value and jump
    movl %esi, %eax
    jmp *0(%rdi)
