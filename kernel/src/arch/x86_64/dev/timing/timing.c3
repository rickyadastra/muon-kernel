module dev::timing;

import datetime;
import muon::logging;

uint128? wallclock @local = WALLCLOCK_NOT_SET?;

fn void get_wallclock_callback(ulong irq) {
    if (try utime = rtc::get_datetime().seconds_since_epoch()) {
        logging::debug("Wallclock set to %d", utime);
        wallclock = utime;
    }

    rtc::acknoledge_interrupt();
    rtc::disable_update_interrupt();
}