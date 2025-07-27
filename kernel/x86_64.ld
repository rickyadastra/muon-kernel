ENTRY (kstart)
OUTPUT_FORMAT(elf64-x86-64)
OUTPUT_ARCH(i386:x86-64)

PHDRS
{
    text    PT_LOAD    FLAGS((1 << 0) | (1 << 2)) ; /* Execute + Read */
    rodata  PT_LOAD    FLAGS((1 << 2)) ;            /* Read only */
    data    PT_LOAD    FLAGS((1 << 1) | (1 << 2)) ; /* Write + Read */
}

SECTIONS
{
  . = 0xffffffff80000000;

  .text ALIGN (0x1000) : {
    *(.text)
  } : text

  .rodata ALIGN (0x1000) : {
    *(.rodata*)
  } : rodata

  .data ALIGN (0x1000) : {
    *(.data*)
  } : data

  .bss : {
    sbss = .;
    *(COMMON)
    *(.bss)
    ebss = .;
  } : data
}