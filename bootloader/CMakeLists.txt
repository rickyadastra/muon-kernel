if (NOT DEFINED BOOTLOADER)
    message(STATUS "Bootloader not defined, defaulting to boson")
    set(BOOTLOADER boson CACHE STRING "Bootloader")
endif()

message(STATUS "Bootloader: ${BOOTLOADER}")

set(FAT_IMAGE ${CMAKE_BINARY_DIR}/fat.img)
add_subdirectory(${BOOTLOADER})

add_custom_command(
    OUTPUT ${FAT_IMAGE}
    COMMAND dd if=/dev/zero of=${FAT_IMAGE} bs=1k count=1440
    COMMAND mformat -i ${FAT_IMAGE} -f 1440 ::
    COMMAND mmd -i ${FAT_IMAGE} ::/EFI
    COMMAND mmd -i ${FAT_IMAGE} ::/EFI/BOOT
    DEPENDS uefi-app
    COMMENT "[bootloader] Making FAT image ${FAT_IMAGE}"
)

add_custom_target(fat-image-create ALL
    DEPENDS ${FAT_IMAGE}
)

add_custom_target(fat-image-copy
    COMMAND mcopy -o -i ${FAT_IMAGE} ${UEFI_EXPORT} ::/EFI/BOOT
    DEPENDS fat-image-create
    COMMENT "[bootloader] Copying updated files to FAT image"
)
