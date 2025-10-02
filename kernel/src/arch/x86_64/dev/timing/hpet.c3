module dev::timing::hpet;

import dev::acpi;
import dev::mmio;
import muon::logging;
import mem::vmm;

HPETTable hpetTable @local;
MemIO hpetMmio @local;
usz timerCount @private;
ulong period @private;
double frequency @private;

macro @hpet_read(#reg, $Type = ulong) => ($Type)hpetMmio.read64((uint)#reg);
macro @hpet_write(#reg, #data) => hpetMmio.write64((uint)#reg, (ulong)#data);

macro @hpet_timer_read(#n, #reg, $Type = ulong) => @hpet_read((uint)#reg + (0x20l * #n), $Type);
macro @hpet_timer_write(#n, #reg, #data) => @hpet_write((uint)#reg + (0x20l * #n), #data);

<*
    @require #timer <= timerCount
*>
macro bool @test_timer_routing(#timer, #route) @local {
    TimerCapabConfigRegister reg = @hpet_timer_read(#timer, HPETRegister.TIMER_CONFIG_CAPAB_BASE, TimerCapabConfigRegister);
    reg.interruptRoute = #route;
    @hpet_timer_write(#timer, HPETRegister.TIMER_CONFIG_CAPAB_BASE, reg);
    reg = @hpet_timer_read(#timer, HPETRegister.TIMER_CONFIG_CAPAB_BASE, TimerCapabConfigRegister);

    return reg.interruptRoute == #route;
}

<*
    @require timer <= timerCount
*>
fn void? init_timer(char timer) @local {
    if (!@test_timer_routing(timer, TIMER_IRQ_BASE+timer)) return UNSUPPORTED_ROUTING?;

    TimerCapabConfigRegister timerCapreg = @hpet_timer_read(timer, HPETRegister.TIMER_CONFIG_CAPAB_BASE, TimerCapabConfigRegister);
    timerCapreg.interruptRoute = TIMER_IRQ_BASE+timer;
    timerCapreg.useLevelTriggeredInterrupt = true;
    @hpet_timer_write(timer, HPETRegister.TIMER_CONFIG_CAPAB_BASE, timerCapreg);
}

fn void? init() {
    hpetTable = *(HPETTable*)acpi::get_acpi_table(SIGNATURE)!;
    assert(hpetTable.address.addressSpaceId == AddressSpaceID.SYSTEM_MEMORY, "ACPI GenericAddress has unsuppoted \"System IO\" ID");
    hpetMmio = vmm::map_mmio(hpetTable.address.address)!;

    // store timer count and frequency
    GeneralCapabIDRegister capreg = @hpet_read(HPETRegister.GENERAL_CAPABILITIES_ID, GeneralCapabIDRegister);
    GeneralConfigRegister configReg = @hpet_read(HPETRegister.GENERAL_CONFIGURATION, GeneralConfigRegister);

    timerCount = capreg.timerCount+1ul;
    period = capreg.clockPeriod;
    frequency = FREQUENCY_FEMTO / capreg.clockPeriod;

    // init timer 0
    init_timer(0)!;

    // enable legacy replacement mode and main counter
    configReg.enableLegacyReplacement = false;
    configReg.enableMainCounter = true;
    @hpet_write(HPETRegister.GENERAL_CONFIGURATION, (ulong)configReg);
}

macro ulong @femto_to_ticks(usz #femto) {
    ulong ticks = #femto / period;
    if (ticks < hpetTable.minimumPeriodicClockTick) ticks = hpetTable.minimumPeriodicClockTick;
    return ticks;
}

<*
    @require timer <= timerCount
*>
fn void set_oneshot_millis(usz timer, double millis) {
    TimerCapabConfigRegister reg = @hpet_timer_read(timer, HPETRegister.TIMER_CONFIG_CAPAB_BASE, TimerCapabConfigRegister);

    reg.timerMode = TimerMode.ONESHOT;
    reg.enableInterrupt = true;

    ulong ticks = @femto_to_ticks((ulong)(millis * 1e12));
    ulong mainCounter = @hpet_read(HPETRegister.MAIN_COUNTER_VALUE);

    @hpet_timer_write(timer, HPETRegister.TIMER_COMPARATOR_VALUE_BASE, mainCounter+ticks);
    @hpet_timer_write(timer, HPETRegister.TIMER_CONFIG_CAPAB_BASE, reg);

    logging::debug("Next interrupt in %d ticks", ticks);
}

macro void @timer_eoi(usz #timer) @local {
    if (#timer == 0) { // hardcoded oneshot timer
        ulong intr = @hpet_read(HPETRegister.GENERAL_INTR_STATUS);
        if ((intr << #timer) & 1) @hpet_write(HPETRegister.GENERAL_INTR_STATUS, 1 << #timer);
    }
}

fn void timer_fired(ulong irq) {
    usz timer = 0;
    switch (irq) {
        case TIMER_IRQ_BASE:
            timer = 0;
    }

    @timer_eoi(timer);
}
