muon_c3c = find_program('c3c', required: true, version: '>=0.7.7')
arch = host_machine.cpu()

linker_file = '@0@.ld'.format(arch)

configure_file(
  input: linker_file,
  output: linker_file,
  copy: true
)

if arch == 'x86_64'
    elf_target = 'elf-x64'
else
    error('Unknown arch target for muon')
endif

c3_compile_args = [
    '--link-libc=no',
    '--use-stdlib=no',
    '--x86cpu=baseline',        # TODO: add AVX support
    '--build-dir', 'kernel/',
    '--single-module=yes',
    '--target', elf_target,
    '--panicfn', 'arch::panicfn',
    '--trust=full',
]

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
    f'src/arch/@arch@/cpu/cpu.c3',
    f'src/arch/@arch@/cpu/cpuid.c3',
    f'src/arch/@arch@/cpu/gdt.c3',
    f'src/arch/@arch@/cpu/gdt.c3i',
    f'src/arch/@arch@/cpu/idt.c3',
    f'src/arch/@arch@/cpu/idt.c3i',
    f'src/arch/@arch@/cpu/sse.c3',
    f'src/arch/@arch@/cpu/sse.c3i',
    f'src/arch/@arch@/cpu/tss.c3',
    f'src/arch/@arch@/cpu/tss.c3i',

    f'src/arch/@arch@/dev/acpi/acpi.c3',
    f'src/arch/@arch@/dev/acpi/acpi.c3i',

    f'src/arch/@arch@/dev/interrupts/apic.c3',
    f'src/arch/@arch@/dev/interrupts/apic.c3i',
    f'src/arch/@arch@/dev/interrupts/pic.c3',

    f'src/arch/@arch@/dev/timing/hpet.c3',
    f'src/arch/@arch@/dev/timing/hpet.c3i',
    f'src/arch/@arch@/dev/timing/pit.c3',
    f'src/arch/@arch@/dev/timing/rtc.c3',
    f'src/arch/@arch@/dev/timing/rtc.c3i',
    f'src/arch/@arch@/dev/timing/timing.c3',

    f'src/arch/@arch@/mem/mem.c3',
    f'src/arch/@arch@/mem/pagefault.c3',
    f'src/arch/@arch@/mem/paging.c3',
    f'src/arch/@arch@/mem/paging.c3i',

    f'src/arch/@arch@/interrupts/handlers.c3',
    f'src/arch/@arch@/interrupts/interrupts.c3',
    f'src/arch/@arch@/interrupts/interrupts.c3i',
    f'src/arch/@arch@/interrupts/routines.c3',

    f'src/arch/@arch@/process/task.c3i',
    f'src/arch/@arch@/process/task.c3',
    
    f'src/arch/@arch@/arch.c3',
    f'src/arch/@arch@/random.c3',

    ########################################

    f'src/mem/pmm.c3',
    f'src/mem/vmm.c3',
    f'src/mem/vmm.c3i',

    f'src/dev/mmio.c3',
    f'src/dev/port.c3',
    f'src/dev/serial.c3',
    f'src/dev/serial.c3i',

    f'src/authority/authority.c3',
    f'src/authority/handle.c3',
    f'src/authority/object.c3',
    f'src/authority/object.c3i',
    f'src/authority/table.c3',

    f'src/dev/timing/timing.c3',
    f'src/dev/timing/timing.c3i',

    f'src/process/monitor.c3',
    f'src/process/process.c3',
    f'src/process/scheduler.c3',
    f'src/process/task.c3',
    f'src/process/task.c3i',
    f'src/process/workers.c3',

    f'src/sync/semaphore.c3',

    f'src/demo/shell.c3',
    f'src/demo/term.c3',
    f'src/demo/programs/forge.c3',
    f'src/demo/programs/random.c3',
    f'src/demo/programs/sleep.c3',
    f'src/demo/programs/spawner.c3',
    f'src/demo/programs/time.c3',
    f'src/demo/programs/monitor.c3',
    f'src/demo/programs/spinner.c3',

    f'src/entry.c3',
    f'src/logging.c3',
    f'src/muon.c3',
    f'src/muon.c3i',

    f'test/test.c3t',
    f'test/scheduler.c3t',
    f'test/scheduler_fpu.c3t',
]

muon_sources_asm = files(
    f'src/arch/@arch@/dev/port.s',
    f'src/arch/@arch@/cpu/gdt.s',
)

c3_objs = []
c3_objs += custom_target(
    input: files(muon_sources) + libsharedc3_sources,
    output: 'muon_c3.o',
    command: [
        muon_c3c, 'compile-only',
        '@INPUT@',
        '-o', '@OUTPUT@',
    ] + c3_compile_args,
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
