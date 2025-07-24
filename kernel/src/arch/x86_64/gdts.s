.text
.globl load_gdt
load_gdt:
    cli
    lgdt (%rdi)

    movl $0x10, %eax
    movw %ax, %ds
    movw %ax, %es
    movw %ax, %ss

    pushq $0x08
    leaq ret_from_gdt_load(%rip), %rax
    pushq %rax
    retfq

ret_from_gdt_load:
    ret
