cmake_minimum_required(VERSION 3.10)
project(muon_kernel C)

if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release)
endif()

# Abilita la generazione del compile_commands.json (utile per clang-tidy)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_C_STANDARD 11)

add_subdirectory(kernel)

set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_C_COMPILER "x86_64-elf-gcc")
set(CMAKE_ASM_COMPILER "x86_64-elf-gcc")

# set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -m64 -ffreestanding -nostdlib -Wall -Wextra")
# set(CMAKE_ASM_FLAGS "${CMAKE_ASM_FLAGS} -m64")

# if(CMAKE_BUILD_TYPE STREQUAL "Debug")
#     set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -g")
# endif()

# set(CMAKE_LINKER_FLAGS "${CMAKE_LINKER_FLAGS} -ffreestanding -nostdlib")

include_directories(${CMAKE_SOURCE_DIR}/include)

# file(GLOB SOURCES "${CMAKE_SOURCE_DIR}/kernel/src/*.c")

# add_executable(muon.elf ${SOURCES})

# #target_link_options(muon_kernel.elf PRIVATE "-T${CMAKE_SOURCE_DIR}/linker.ld")

