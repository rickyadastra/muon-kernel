module dev::timing::rtc;

import datetime;
import dev::port;
import muon::logging;

Port rtc @local = RTC_PORT;

macro char @rtc_read(reg, bool disableNMIs = true) @local {
    if (disableNMIs) reg |= RTC_DISABLE_NMI;

    rtc.out8(RTC_REGSEL_OFFSET, (char)reg);
    return rtc.in8(RTC_REGDATA_OFFSET);
}

macro void @rtc_write(reg, #data, bool disableNMIs = true) @local {
    if (disableNMIs) reg |= RTC_DISABLE_NMI;
    
    rtc.out8(RTC_REGSEL_OFFSET, (char)reg);
    rtc.out8(RTC_REGDATA_OFFSET, (char)#data);
}

macro char @bcd_to_binary(#bcd) @local => ((#bcd & 0xF0) >> 1) + ((#bcd & 0xF0) >> 3) + (#bcd & 0xf);

fn void set_update_interrupt(bool value) {
    RTCStatusRegB reg = (RTCStatusRegB)@rtc_read(RTCRegister.STATUS_B);
    reg.enableUpdateEndInterrupt = value;
    @rtc_write(RTCRegister.STATUS_B, reg);

    @rtc_read(RTCRegister.STATUS_C, disableNMIs: false);
}

fn void enable_update_interrupt() => set_update_interrupt(true);
fn void disable_update_interrupt() => set_update_interrupt(false);

// reading status reg C is mandatory to acknoledge interrupt
fn void acknoledge_interrupt() => @rtc_read(RTCRegister.STATUS_C, disableNMIs: false);

fn Datetime? get_datetime() {
    RTCStatusRegA regA = (RTCStatusRegA)@rtc_read(RTCRegister.STATUS_A);
    if (regA.updateInProgress) return UPDATE_IN_PROGRESS?;

    RTCStatusRegB regB = (RTCStatusRegB)@rtc_read(RTCRegister.STATUS_B);

    char year = @rtc_read(RTCRegister.YEAR);
    char month = @rtc_read(RTCRegister.MONTH);
    char day = @rtc_read(RTCRegister.DAY);
    char hour = @rtc_read(RTCRegister.HOURS);
    char mins = @rtc_read(RTCRegister.MINUTES);
    char secs = @rtc_read(RTCRegister.SECONDS);

    // convert BCD to decimal if needed
    if (!regB.enableBinaryFormat) {
        year = @bcd_to_binary(year);
        month = @bcd_to_binary(month);
        day = @bcd_to_binary(day);
        hour = @bcd_to_binary(hour);
        mins = @bcd_to_binary(mins);
        secs = @bcd_to_binary(secs);
    }

    return datetime::to_datetime(year + BASE_YEAR, month, day, hour, mins, secs);
}
