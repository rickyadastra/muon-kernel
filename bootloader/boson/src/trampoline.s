.global start_kernel
.text
start_kernel:
.global trampolineStart
trampolineStart:
    # void start_kernel(UPtr stack, UPtr pml4, UPtr entry, BootloaderPayload* payload);
    # void start_kernel(rcx,        rdx,       r8,         r9);
    
    # rcx: stackEnd
    # rdx: pml4
    # r8:  entry 
    # r9:  payload -> rdi

    movq %rcx, %rsp
    movq %rcx, %rbp

    movq %rdx, %cr3
    cli

    movq %r9, %rdi
    sub $8, %rsp        # ensure 16 byte stack alignment
    pushq %r8
    retq
    hlt

.global trampolineEnd
trampolineEnd:
