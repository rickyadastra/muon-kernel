project(
    'project-root',
    'c'
)

target = get_option('target')
arch = 'x86_64'

if target == 'boson-bootloader'
    subdir = 'bootloader'
    abi = 'ms'
elif target == 'muon-kernel'
    subdir = 'kernel'
    abi = 'sysv'
endif

subdir('shared')
subdir(subdir)
