module dev::interrupts::apic;

import arch;
import dev::acpi;
import dev::mmio;
import dev::interrupts;

import muon::logging;

MADTable madt @local;
MemIO lapic @local;

const uint SPURIOUS_INTERR_VECTOR_VALUE = 0x100 | KnownInterrupt.SPURIOUS_INTERRUPT.num; // 0x100: enable APIC

macro @lapic_write(#reg, #data) => lapic.write32((ulong)#reg, #data);
macro uint @lapic_read(#reg) => lapic.read32((ulong)#reg);

fn void? enable_lapic() @private {
    APICBaseMSR msr = (APICBaseMSR)cpu::read_msr(ModelSpecificRegister.APIC);
    if (!msr.globalEnable) return APIC_DISABLED?;

    msr.baseAddr = lapic >> 12;
    cpu::write_msr(ModelSpecificRegister.APIC, (ulong)msr);
    @lapic_write(LAPICRegister.SPURIOUS_INTERR_VECTOR, SPURIOUS_INTERR_VECTOR_VALUE);
}

fn void? init() {
    arch::cpu::disable_interrupts();

    madt = *(MADTable*)acpi::get_acpi_table(SIGNATURE)!;
    lapic = madt.localApicAddr;
    
    enable_lapic()!;

    pic::remap();
    pic::disable();
}
