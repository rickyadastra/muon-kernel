module dev::interrupts::apic;

import arch;
import dev::acpi;
import dev::mmio;
import dev::interrupts;
import dev::timing;
import mem::vmm;
import muon::logging;

const uint SPURIOUS_INTERR_VECTOR_VALUE = 0x100 | KnownInterrupt.SPURIOUS_INTERRUPT.num; // 0x100: enable APIC
const usz MAX_IOAPIC_COUNT = 8;
const uint LEGACY_IRQ_BASE = 0x20;

MADTable* madt @local;
MemIO lapic @local;
char lapicId @local = char.max;
usz ioapicCount @local = 0;
IOApic[MAX_IOAPIC_COUNT] ioapics @local; 

macro @lapic_write(#reg, #data) => lapic.write32((ulong)#reg, #data);
macro uint @lapic_read(#reg) => lapic.read32((ulong)#reg);

fn void? setup_lapic() @private {
    APICBaseMSR msr = (APICBaseMSR)cpu::read_msr(ModelSpecificRegister.APIC);
    if (!msr.globalEnable) return APIC_DISABLED?;

    msr.baseAddr = lapic >> 12;
    cpu::write_msr(ModelSpecificRegister.APIC, (ulong)msr);
    @lapic_write(LAPICRegister.SPURIOUS_INTERR_VECTOR, SPURIOUS_INTERR_VECTOR_VALUE);
}

macro lapic_eoi() => @lapic_write(LAPICRegister.EOI, 0);

fn void lapic_set_lvt(char lint, InterruptFlags flags, KnownInterrupt interrupt, bool nonMaskable = false) @local {
    LAPICRegister lintReg = lint == 0 ? LAPICRegister.LVT_LINT0 : LAPICRegister.LVT_LINT1;
    LocalVectorEntry nmiLvt = {
        .vector = interrupt.num,
        .nonMaskable = nonMaskable,
        .activeOnLow = flags.activeOnLow,
        .triggerOnLevel = flags.triggerOnLevel,
        .masked = false,
    };

    @lapic_write(lintReg, (uint)nmiLvt);
}

fn IOApic? ioapic_register(IOAPICRecord* ioApicRecord) @local {
    MemIO ioapic = vmm::map_mmio(ioApicRecord.ioApicAddr)!;

    ioapic.write32(IOAPIC_REGSEL, (uint)IOAPICRegister.IOAPIC_VER);
    usz lines = ((IOAPICVerReg)ioapic.read32(IOAPIC_REGWIN)).maxRedirectEntry + 1l;
    
    ioapics[ioapicCount] = {
        .record = ioApicRecord,
        .managedIntLines = lines - ioApicRecord.globalSystemInterruptBase,
        .mmAddr = ioapic,
    };

    IOApic ioa = ioapics[ioapicCount];
    ioapicCount++;

    return ioa;
}

fn void ioapic_set_redirect(uint gsi, char irq, InterruptFlags flags, char destinationLapicId = lapicId, bool masked = false) @private {    
    foreach (IOApic ioapic : ioapics[:ioapicCount]) {
        if (gsi >= ioapic.record.globalSystemInterruptBase && gsi < ioapic.record.globalSystemInterruptBase + ioapic.managedIntLines) {
            IOAPICRedirectionEntry redEntry = {
                .vector = LEGACY_IRQ_BASE + irq,
                .deliveryMode = DeliveryMode.FIXED,
                .deliveryStatus = false,
                .useLogicalDestination = false,
                .activeOnLow = flags.activeOnLow,
                .triggerOnLevel = flags.triggerOnLevel,
                .masked = masked,
                .destination = destinationLapicId,
            };

            // register iso to redtbl
            ioapic.mmAddr.write32(IOAPIC_REGSEL, (uint)IOAPICRegister.IOAPIC_REDTBL_BASE + (gsi*2));
            ioapic.mmAddr.write32(IOAPIC_REGWIN, (uint)((ulong)redEntry & uint.max));

            ioapic.mmAddr.write32(IOAPIC_REGSEL, (uint)IOAPICRegister.IOAPIC_REDTBL_BASE + (gsi*2) + 1);
            ioapic.mmAddr.write32(IOAPIC_REGWIN, (uint)(((ulong)redEntry >> 32) & uint.max));
        }
    }
}

fn void ioapic_set_mask(uint gsi, bool masked, bool cancelPending) @private {    
    foreach (IOApic ioapic : ioapics[:ioapicCount]) {
        if (gsi >= ioapic.record.globalSystemInterruptBase && gsi < ioapic.record.globalSystemInterruptBase + ioapic.managedIntLines) {
            IOAPICRedirectionEntry entryLow;

            ioapic.mmAddr.write32(IOAPIC_REGSEL, (uint)IOAPICRegister.IOAPIC_REDTBL_BASE + (gsi*2));
            entryLow = (IOAPICRedirectionEntry)(ulong)ioapic.mmAddr.read32(IOAPIC_REGWIN);

            entryLow.masked = masked;
            if (cancelPending) entryLow.deliveryStatus = false;

            // register iso to redtbl
            ioapic.mmAddr.write32(IOAPIC_REGSEL, (uint)IOAPICRegister.IOAPIC_REDTBL_BASE + (gsi*2));
            ioapic.mmAddr.write32(IOAPIC_REGWIN, (uint)((ulong)entryLow & uint.max));
        }
    }
}

fn IOAPICRedirectionEntry ioapic_get_redirect(uint gsi) {
    foreach (IOApic ioapic : ioapics[:ioapicCount]) {
        if (gsi >= ioapic.record.globalSystemInterruptBase && gsi < ioapic.record.globalSystemInterruptBase + ioapic.managedIntLines) {
            uint low, high;

            ioapic.mmAddr.write32(IOAPIC_REGSEL, (uint)IOAPICRegister.IOAPIC_REDTBL_BASE + (gsi*2));
            low = ioapic.mmAddr.read32(IOAPIC_REGWIN);

            ioapic.mmAddr.write32(IOAPIC_REGSEL, (uint)IOAPICRegister.IOAPIC_REDTBL_BASE + (gsi*2) + 1);
            high = ioapic.mmAddr.read32(IOAPIC_REGWIN);

            return (IOAPICRedirectionEntry)((ulong)high << 32 | low);
        }
    }

    return {};
}

fn void? parse_madt(MADTable* madt) @local {
    RecordHeader* recordPtr = &madt.firstRecord;
    while ((uptr)recordPtr < ((uptr)madt + madt.length)) {
        // logging::debug("record @ %x of type: %d, length: %d bytes", recordPtr, recordPtr.type, recordPtr.length);

        if (recordPtr.type == RecordType.LOCAL_APIC) {
            LocalAPICRecord* lapicRecord = (LocalAPICRecord*)recordPtr;

            // set the Local APIC ID for the CPU that will handle all interrupts
            if (lapicId == char.max) lapicId = lapicRecord.apicId;

            logging::debug("Found Local APIC #%d (ACPI Processor ID: %d)", lapicRecord.apicId, lapicRecord.acpiProcessorId);

        } else if (recordPtr.type == RecordType.IO_APIC) {
            IOApic ioApic = ioapic_register((IOAPICRecord*)recordPtr)!;
            
            logging::debug("Found IOAPIC #%d @ %x (%x) managing interrupts %d-%d (%d lines)", ioApic.record.ioApicId, ioApic.record.ioApicAddr, 
                            ioApic.record, ioApic.record.globalSystemInterruptBase, ioApic.managedIntLines - 1, ioApic.managedIntLines);
        
        } else if (recordPtr.type == RecordType.IO_APIC_ISO) {
            IOAPICSourceOverrideRecord* isoRecord = (IOAPICSourceOverrideRecord*)recordPtr;

            char irq = isoRecord.irqSource;
            uint gsi = isoRecord.globalSystemInterrupt;
            String trigger = isoRecord.flags.triggerOnLevel ? "LEVEL" : "EDGE";
            String active = isoRecord.flags.activeOnLow ? "LOW" : "HIGH";

            logging::debug("Found IOAPIC Override for IRQ #%d to GSI #%d (%s %s)", irq, gsi, trigger, active);

            ioapic_set_redirect(gsi, irq, isoRecord.flags);

        } else if (recordPtr.type == RecordType.LOCAL_APIC_NMI) {
            LocalAPICNonMaskableIntsRecord* nmiRecord = (LocalAPICNonMaskableIntsRecord*)recordPtr;

            char lint = nmiRecord.lintNumber;
            char procId = nmiRecord.acpiProcessorId;
            String trigger = nmiRecord.flags.triggerOnLevel ? "LEVEL" : "EDGE";
            String active = nmiRecord.flags.activeOnLow ? "LOW" : "HIGH";            

            logging::debug("Found Local APIC NMI for LINT #%d on CPU #%d (%s %s)", lint, procId, trigger, active);

            // TODO: support multiple CPUs and register NMI on each one
            lapic_set_lvt(lint, nmiRecord.flags, KnownInterrupt.NONMASKABLE_INTERRUPT, nonMaskable: true);
        }

        recordPtr = (RecordHeader*)((uptr)recordPtr + recordPtr.length);
    }
}

fn uint get_gsi_override(char irq) @private {
    RecordHeader* recordPtr = &madt.firstRecord;
    while ((uptr)recordPtr < ((uptr)madt + madt.length)) {
        if (recordPtr.type == RecordType.IO_APIC_ISO) {
            IOAPICSourceOverrideRecord* isoRecord = (IOAPICSourceOverrideRecord*)recordPtr;

            if (isoRecord.irqSource == irq) return isoRecord.globalSystemInterrupt;
        }

        recordPtr = (RecordHeader*)((uptr)recordPtr + recordPtr.length);
    }

    return irq;
}

fn void timer_enable(APICTimerMode mode) @private {
    LocalVectorEntry lvt = {
        .vector = KnownInterrupt.APIC_TIMER.num,
        .masked = false,
        .timerMode = mode,
    };

    @lapic_write(LAPICRegister.LVT_TIMER, (uint)lvt);
}

fn void APICTscTimer.set(&self, ulong delta, TimerCallbackFn callback = null) @dynamic {
    cpu::write_msr(ModelSpecificRegister.TSC_DEADLINE, cpu::read_tsc()+delta);
}

fn void APICTscTimer.cancel(&self) @dynamic {
    cpu::write_msr(ModelSpecificRegister.TSC_DEADLINE, 0); // writing 0 disarms the local-APIC timer
}

fn double APICTscTimer.get_frequency(&self) @dynamic {
    return self.frequency;
}

fn void? init() {
    arch::cpu::disable_interrupts();

    madt = (MADTable*)acpi::get_acpi_table(SIGNATURE)!;
    lapic = vmm::map_mmio(madt.localApicAddr)!;
    
    setup_lapic()!;

    pic::remap();
    pic::disable();
    
    parse_madt(madt)!;
}
