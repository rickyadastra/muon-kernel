module dev::interrupts::apic;

import arch;
import dev::acpi;
import dev::mmio;
import dev::interrupts;

const uint SPURIOUS_INTERR_VECTOR_VALUE = 0x100 | KnownInterrupt.SPURIOUS_INTERRUPT.num; // 0x100: enable APIC
const usz MAX_IOAPIC_COUNT = 16;

MADTable* madt @local;
MemIO lapic @local;
usz ioapic_count @local = 0;
IOAPICRecord[MAX_IOAPIC_COUNT] ioapics @local; 

macro @lapic_write(#reg, #data) => lapic.write32((ulong)#reg, #data);
macro uint @lapic_read(#reg) => lapic.read32((ulong)#reg);

fn void? setup_lapic() @private {
    APICBaseMSR msr = (APICBaseMSR)cpu::read_msr(ModelSpecificRegister.APIC);
    if (!msr.globalEnable) return APIC_DISABLED?;

    msr.baseAddr = lapic >> 12;
    cpu::write_msr(ModelSpecificRegister.APIC, (ulong)msr);
    @lapic_write(LAPICRegister.SPURIOUS_INTERR_VECTOR, SPURIOUS_INTERR_VECTOR_VALUE);
}

fn void? init() {
    arch::cpu::disable_interrupts();

    madt = (MADTable*)acpi::get_acpi_table(SIGNATURE)!;
    lapic = madt.localApicAddr;
    
    setup_lapic()!;

    pic::remap();
    pic::disable();

    // IOAPIC needs VMM to access MMIO registers!
    
    /* RecordHeader* recordPtr = &madt.firstRecord;
    while ((uptr)recordPtr < ((uptr)madt + madt.length)) {
        if (recordPtr.type == RecordType.IO_APIC) {
            ioapics[ioapic_count++] = *(IOAPICRecord*)recordPtr;

            MemIO ioapic = ((IOAPICRecord*)recordPtr).ioApicAddr;
            ioapic.write32(IOAPIC_REGSEL, (uint)IOAPICRegister.IOAPIC_VER);
            logging::printn("max redirections: %d", ((IOAPICVerReg)ioapic.read32(IOAPIC_DATA)).maxRedirectIndex);
        }
        recordPtr = (RecordHeader*)((uptr)recordPtr + recordPtr.length);
    } */ 
}
