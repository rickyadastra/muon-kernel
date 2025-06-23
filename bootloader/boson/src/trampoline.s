.global start_kernel
.text
start_kernel:
.global trampolineStart
trampolineStart:
    # rcx: stackEnd
    # rdx: pml4
    # r8:  entry 
    movq %rcx, %rsp
    movq %rcx, %rbp

    movq %rdx, %cr3
    cli

    pushq %r8
    retq
    hlt

.global trampolineEnd
trampolineEnd:
