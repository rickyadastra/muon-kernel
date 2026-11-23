#!/usr/bin/env bash

echo "Compiling kernel with integration tests"
c3c compile \
    --trust=full \
    --use-stdlib=no \
    --link-libc=no \
    --warn-builtin=no \
    --x86cpu=baseline \
    --linker=builtin \
    --no-entry \
    --testfn muon::test::run_all \
    --panicfn muon::panicfn \
    --target elf-x64 \
    --lib boson_protocol \
    --libdir boot/boson/lib \
    --sources kernel/** boot/boot.c3i boot/adapters/boson.c3 libs/** test/** \
    --build-dir .build/muon \
    --output-dir .build/muon \
    -o muon-test.elf \
    -D BOOT_BOSON \
    -D LOG_INFO \
    -D ANSI_COLORS_NO \
    -D ARCH_X86_64 \
    -D TEST_ENABLED \
    -z -Tscripts/x86_64.ld \
    -z -zmax-page-size=0x1000 \
    -z -ztext \
    --testing

echo "Compiling boson bootloader"
make -C boot/boson BUILD_DIR=../../.build/boson

echo "Preparing test fat.img"
dd if=/dev/zero of=fat-test.img bs=1k count=1440
mformat -i fat-test.img -f 1440 ::
mmd -i fat-test.img ::/EFI
mmd -i fat-test.img ::/EFI/BOOT
mcopy -i fat-test.img .build/boson/boson.efi ::/EFI/BOOT/BOOTX64.EFI
mcopy -i fat-test.img .build/muon/muon-test.elf ::/EFI/BOOT/muon.sys

echo "Launching integration test on QEMU..."
qemu-system-x86_64 -bios /usr/share/ovmf/OVMF.fd \
    -net none -m 1G -enable-kvm -cpu host \
    -serial file:test-result.log \
    -nographic -no-reboot \
    -device isa-debug-exit,iobase=0xf4,iosize=0x04 \
    -drive file=fat-test.img,format=raw \
    -monitor none

rm fat-test.img
echo "Integration test completed"
cat test-result.log | grep -F [muon::test] --color=never

rm test-result.log
