.globl arch_out8
arch_out8:
    movw %di, %dx
    movb %sil, %al
    out %al, %dx
    ret

.globl arch_out16
arch_out16:
    movw %di, %dx
    movw %si, %ax
    out %ax, %dx
    ret

.globl arch_out32
arch_out32:
    movw %di, %dx
    movl %esi, %eax
    out %eax, %dx
    ret

.globl arch_in8
arch_in8:
    movw %di, %dx
    xorl %eax, %eax
    in %dx, %al
    ret

.globl arch_in16
arch_in16:
    movw %di, %dx
    xorl %eax, %eax
    in %dx, %ax
    ret

.globl arch_in32
arch_in32:
    movw %di, %dx
    in %dx, %eax
    ret
