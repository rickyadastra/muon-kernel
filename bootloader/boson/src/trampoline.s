.global start_kernel
.text
start_kernel:
.global trampolineStart
trampolineStart:
    movq %rcx, %rsp

    movq %rdx, %cr3
    movq $0xbeef, %rax
    cli
    hlt

.global trampolineEnd
trampolineEnd:
