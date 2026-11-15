ENTRY (kstart)
OUTPUT_FORMAT(elf64-x86-64)
OUTPUT_ARCH(i386:x86-64)

PHDRS
{
    text      PT_LOAD         FLAGS(5); /* Execute + Read */
    rodata    PT_LOAD         FLAGS(4); /* Read only */
    data      PT_LOAD         FLAGS(6); /* Write + Read */
    muon_dbg  0x6D110D09      FLAGS(4); /* Read only */
}

SECTIONS
{
  . = 0xffffffff80000000;

  .text ALIGN (0x1000) : {
    *(.text)
  } : text

  .rodata ALIGN (0x1000) : {
    *(.rodata*)

    . = ALIGN(8);
    __init_array_start = .;
    KEEP(*(SORT_BY_INIT_PRIORITY(.init_array.*)))
    KEEP(*(.init_array))
    __init_array_end = .;
  } : rodata

  .eh_frame ALIGN (0x1000) : {
    *(.eh_frame)
  } : muon_dbg

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