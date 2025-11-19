BUILD_DIR 		:= ./build
TOOLCHAIN_DIR 	:= ./toolchain
FATIMG			:= fat.img

BOSON_BUILDDIR	:= $(BUILD_DIR)/boson
BOSON_TARGET 	:= $(BUILD_DIR)/boson/bootloader/boson.efi

MUON_BUILDDIR	:= $(BUILD_DIR)/muon
MUON_TARGET 	:= $(BUILD_DIR)/muon/kernel/muon.elf

QEMU			:= qemu-system-x86_64
QEMU_FLAGS		:= -bios /usr/share/OVMF/OVMF_CODE.fd \
				   -net none -m 1G -enable-kvm -cpu host \
				   -chardev pty,id=COM2 -serial chardev:COM2 \
				   -chardev pty,id=COM3 -serial chardev:COM3 #-cpu qemu64,+popcnt,+tsc,+tsc-deadline
QEMU_RUN		:= -serial stdio
QEMU_DEBUG 		:= -serial file:serial.log -s -S -d cpu_reset,int \
				   -D qemu.log

GDB				= gdb
GDB_FLAGS 		= -ex "target remote localhost:1234" \
				  -ex "layout split" \
				  -ex "set scheduler-locking step" \
				  -ex "set disassembly-flavor att" \
				  -ex "focus cmd" \
				  -ex "set confirm off" \
				  -ex "symbol-file ${MUON_TARGET}" \
				  -ex "hbr arch.panic"

all: boson muon

boson: $(BOSON_TARGET)

.PHONY: $(BOSON_TARGET)
$(BOSON_TARGET): 
	@echo "[Make] Building boson bootloader"
	@meson compile -C $(BOSON_BUILDDIR)

muon: $(MUON_TARGET)

.PHONY: $(MUON_TARGET)
$(MUON_TARGET):
	@echo "[Make] Building muon kernel"
	@meson compile -C $(MUON_BUILDDIR)

setup:
	@meson setup build/boson . --cross-file $(TOOLCHAIN_DIR)/boson-toolchain.txt -Dtarget=boson-bootloader
	@meson setup build/muon . --cross-file $(TOOLCHAIN_DIR)/muon-toolchain.txt -Dtarget=muon-kernel

clear:
	@rm -rf $(BUILD_DIR)
	@echo "[Make] Cleared build files"

$(FATIMG): $(BUILD_DIR)/$(FATIMG)

.PHONY: $(FATIMG)
$(BUILD_DIR)/$(FATIMG): boson muon
	@dd if=/dev/zero of=$@ bs=1k count=1440
	@mformat -i $@ -f 1440 ::
	@mmd -i $@ ::/EFI
	@mmd -i $@ ::/EFI/BOOT
	@mcopy -i $@ $(BOSON_TARGET) ::/EFI/BOOT/BOOTX64.EFI
	@mcopy -i $@ $(MUON_TARGET) ::/EFI/BOOT/muon.sys

run: $(BUILD_DIR)/$(FATIMG)
	$(QEMU) $(QEMU_RUN) $(QEMU_FLAGS) -drive file=$<,format=raw

debug: $(BUILD_DIR)/$(FATIMG)
	@$(QEMU) $(QEMU_DEBUG) $(QEMU_FLAGS) -drive file=$<,format=raw &
	@$(GDB) $(GDB_FLAGS)
