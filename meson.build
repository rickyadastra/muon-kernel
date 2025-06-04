project(
    'project-root',
    'c'
)

target = get_option('target')

subdir('shared')

if target == 'boson-bootloader'
    subdir('bootloader')
elif target == 'muon-kernel'
    subdir('kernel')
endif
