BUILD_DIR 		:= ./build
TOOLCHAIN_DIR 	:= ./toolchain
FATIMG			:= fat.img

BOSON_BUILDDIR	:= $(BUILD_DIR)/boson
BOSON_TARGET 	:= $(BUILD_DIR)/boson/bootloader/boson.efi

QEMU			:= qemu-system-x86_64
QEMU_FLAGS		:= -bios /usr/share/OVMF/OVMF_CODE.fd \
				   -net none

all: boson muon

boson: $(BOSON_TARGET)

.PHONY: $(BOSON_TARGET)
$(BOSON_TARGET): 
	@echo "[Make] Building boson bootloader"
	@meson compile -C $(BOSON_BUILDDIR)

muon:
	@echo "[Make] Building muon kernel"

setup:
	@meson setup build/boson . --cross-file $(TOOLCHAIN_DIR)/boson-toolchain.txt -Dtarget=boson-bootloader

clear:
	@rm -rf $(BUILD_DIR)
	@echo "[Make] Cleared build files"

$(FATIMG): $(BUILD_DIR)/$(FATIMG)

.PHONY: $(FATIMG)
$(BUILD_DIR)/$(FATIMG): boson
	@dd if=/dev/zero of=$@ bs=1k count=1440
	@mformat -i $@ -f 1440 ::
	@mmd -i $@ ::/EFI
	@mmd -i $@ ::/EFI/BOOT
	@mcopy -i $@ $(BOSON_TARGET) ::/EFI/BOOT/BOOTX64.EFI -v

run: $(BUILD_DIR)/$(FATIMG)
	$(QEMU) $(QEMU_FLAGS) -drive file=$<,format=raw
