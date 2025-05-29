file(GLOB_RECURSE LEPTON_SOURCES
    "src/**.c"
)

add_library(lepton_objects OBJECT ${LEPTON_SOURCES})

include_directories(lepton_objects PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/include
)

target_compile_options(lepton_objects PRIVATE 
    ${ARCH_FLAGS}
    -ffreestanding
    -nostdlib
    -mcmodel=kernel
    -fno-pic
    -fms-extensions
)
