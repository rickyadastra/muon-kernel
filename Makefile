BUILD_DIR 		:= ./.build
TOOLCHAIN_DIR 	:= ./toolchain
FATIMG			:= fat.img

BOSON_BUILDDIR	:= $(BUILD_DIR)/boson
BOSON_TARGET 	:= $(BUILD_DIR)/boson/bootloader/boson.efi

MUON_BUILDDIR	:= $(BUILD_DIR)/muon
MUON_TARGET 	:= $(BUILD_DIR)/muon/muon.elf

C3C				:= c3c
C3C_FLAGS		:= --trust=full --warn-builtin=no
C3C_MIN_VER		:= 0.8.4
C3C_VERSION		:= $(shell $(C3C) --version | awk '/C3 Compiler Version/ {print $$4}')

QEMU			:= qemu-system-x86_64
QEMU_FLAGS		:= -bios /usr/share/ovmf/OVMF.fd \
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

.PHONY: $(BOSON_TARGET) $(MUON_TARGET) $(FATIMG) all run debug

all: boson muon
boson: $(BOSON_TARGET)
muon: $(MUON_TARGET)
$(FATIMG): $(BUILD_DIR)/$(FATIMG)

$(BOSON_TARGET): 
	@echo "[Make] Building boson bootloader"
	@meson compile -C $(BOSON_BUILDDIR)

$(MUON_TARGET): check-ver
	@echo "[Make] Building muon kernel"
	@$(C3C) build $(C3C_FLAGS) --build-dir $(MUON_BUILDDIR) --output-dir $(MUON_BUILDDIR)

setup:
	@meson setup .build/boson . --cross-file $(TOOLCHAIN_DIR)/boson-toolchain.txt -Dtarget=boson-bootloader

clear:
	@rm -rf $(BUILD_DIR)
	@echo "[Make] Cleared build files"

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

check-ver:
	@RES=$$( { echo "$(C3C_VERSION)"; echo "$(C3C_MIN_VER)"; } | sort -V | head -n1 ); \
	if [ "$$RES" != "$(C3C_MIN_VER)" ]; then \
		echo "\nCurrent C3 Compiler version is $(C3C_VERSION), but at least version $(C3C_MIN_VER) is required.\nPlease update c3c (https://c3-lang.org/getting-started/prebuilt-binaries/) and retry.\n"; \
		exit 1; \
	fi \
