muon_c3c = find_program('c3c', required: true, version: '>=0.7.4')
muon_gcc = find_program('x86_64-elf-gcc', required: true, version: '>=9.4.0')
arch = host_machine.cpu()

linker_file = '@0@.ld'.format(arch)

configure_file(
  input: linker_file,
  output: linker_file,
  copy: true
)

compile_args = [
    '-g',
    '-Wall',
    '-Wl,-Wunknown-pragmas',
    '-ffreestanding',
    '-fno-stack-protector',
	'-mno-red-zone',
    '-fms-extensions',
    '-mcmodel=kernel',
    '-DSYSV_ABI',
]

link_args = [
    '-T', 'kernel/'+linker_file,
    '-nostdlib',
    '-zmax-page-size=0x1000',
    '-static',
    '-ztext',
]

muon_sources = [
    f'src/arch/@arch@/arch.types.c3',
    f'src/arch/@arch@/gdt.types.c3',
    f'src/arch/@arch@/interrupts/interrupts.types.c3',
    'src/dev/serial.types.c3',
    ########################################
    f'src/arch/@arch@/arch.c3',
    f'src/arch/@arch@/gdt.c3',
    f'src/arch/@arch@/interrupts/routines.c3',
    f'src/arch/@arch@/interrupts/handlers.c3',
    f'src/arch/@arch@/interrupts/interrupts.c3',
    'src/dev/serial.c3',
    'src/dev/port.c3',
    'src/entry.c3'
]

muon_sources_asm = files(
    f'src/arch/@arch@/dev/port.s',
    f'src/arch/@arch@/gdt.s',
)

c3_objs = []
c3_objs += custom_target(
    input: muon_sources,
    output: 'muon_c3.o',
    command: [
        muon_c3c, 'compile-only',
        '@INPUT@',
        '-o', '@OUTPUT@',
        '--link-libc=no',
        '--use-stdlib=no',
        '--build-dir', 'kernel/',
        '--single-module=yes',
    ],
    build_by_default: true
)

executable(
    'muon.elf',
    muon_sources_asm,
    objects: c3_objs,
    c_args: compile_args,
    link_args: link_args,
    install: false
)
