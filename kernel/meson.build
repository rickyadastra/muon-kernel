muon_c3c = 'c3c'
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
    'src/dev/serial.c3',
    'src/dev/port.c3',
    'src/entry.c3'
]

muon_sources_asm = files(
    'src/arch/@0@/dev/port.s'.format(arch)
)

c3_objs = []
c3_objs += custom_target(
    input: muon_sources,
    output: 'muon_c3.o',
    command: [
        'c3c', 'compile-only',
        '@INPUT@',
        '-o', '@OUTPUT@',
        '--link-libc=no',
        '--use-stdlib=no',
        '--build-dir', 'kernel/',
        '--single-module=yes'
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
