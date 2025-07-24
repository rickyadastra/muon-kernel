#include "x86_64/gdt.h"
#include "base/int.h"

extern void load_gdt(GDTRegister* reg);

INHERITCLASS(GDTManager, GDTMANAGER_ONLY_METHODS, OBJECT_METHODS)

GDTEntry GDTManager_construct_entry(UPtr base, UPtr limit, UInt8 access, UInt8 flags) {
    return (GDTEntry){
        .limit_low = (UInt16)(limit & 0xffff),
        .limit_high = (UInt8)((limit >> 16) & 0x0f),
        .base_low = (UInt16)(base & 0xffff),
        .base_mid = (UInt8)((base >> 16) & 0xff),
        .base_high = (UInt8)((base >> 24) & 0xff),
        .access = access,
        .flags = flags
    };
}

void GDTManager_setup(GDTManager* self) {
    // Null descriptor: 0x00
    self->gdt[0] = IGDTManager.construct_entry(0, 0, 0, 0);

    // Kernel code & data segments: 0x08 0x10
    self->gdt[1] = IGDTManager.construct_entry(0, 0xfffff, GDTAccessByte.PRESENT | GDTAccessByte.RW | GDTAccessByte.EXEC, GDTFlag.B64_CODE);
    self->gdt[2] = IGDTManager.construct_entry(0, 0xfffff, GDTAccessByte.PRESENT | GDTAccessByte.RW                     , GDTFlag.B64_DATA);

    // User code & data segments: 0x18 0x20
    self->gdt[3] = IGDTManager.construct_entry(0, 0xfffff, GDTAccessByte.PRESENT | GDTAccessByte.RW | GDTAccessByte.EXEC | GDTAccessByte.USER, GDTFlag.B64_CODE);
    self->gdt[4] = IGDTManager.construct_entry(0, 0xfffff, GDTAccessByte.PRESENT | GDTAccessByte.RW | GDTAccessByte.USER                     , GDTFlag.B64_DATA);
}

void GDTManager_install(GDTManager* self) {
    GDTRegister gdtr = (GDTRegister){
        .address = (UPtr)self->gdt,
        .size = sizeof(GDTEntry)*GDT_ENTRIES
    };

    load_gdt(&gdtr);
}

PACKAGECLASS(GDTManager, Object, GDTMANAGER_ONLY_METHODS, OBJECT_METHODS)
