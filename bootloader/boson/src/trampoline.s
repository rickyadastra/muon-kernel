.global start_kernel
.text
start_kernel:
.global trampolineStart
trampolineStart:
    movq %rcx, %rsp
    movq %rcx, %rbp

    movq %rdx, %cr3
    movq $0xbeef, %rax
    cli

    pushq %r8
    retq
    hlt

.global trampolineEnd
trampolineEnd:
