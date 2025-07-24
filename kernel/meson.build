muon_cc = meson.get_compiler('c')
arch = host_machine.cpu()

add_project_arguments('-include', 'base.h', language: 'c')
add_project_arguments('-include', 'lepton.h', language: 'c')

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

muon_arch_sources = files(
    'src/arch/@0@/devices/port.c'.format(arch),
    'src/arch/@0@/devices/serial.c'.format(arch),
    'src/arch/@0@/gdt.c'.format(arch),
    'src/arch/@0@/gdts.s'.format(arch),
    'src/arch/@0@/arch.c'.format(arch)
)

muon_common_sources = files(
)

muon_sources = muon_arch_sources + muon_common_sources + libcore_sources + liblepton_sources

muon_inc = include_directories(
    'include',
)

executable(
    'muon.elf',
    muon_sources,
    include_directories: [muon_inc, shared_inc],
    c_args: compile_args,
    link_args: link_args,
    install: false
)
