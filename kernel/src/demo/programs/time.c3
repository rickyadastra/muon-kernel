module muon::demo::programs;

import muon;
import process;
import string;
import datetime;
import dev;

const String[7] WEEKDAY_NAMES = { "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat" };
const String[12] MONTH_NAMES = { "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" };

fn int time(SpawnInfo* info) {
    Handle termHandle = info.auxHandles[0];
    logging::printn("Time program started");

    ulong time = timing::get_wallclock();
    ulong uptime = timing::get_uptime();
    Datetime dt = datetime::epoch_to_datetime(time);
    Weekday weekday = dt.weekday();

    Formatter formatter;
    String s = formatter.format("Current datetime is %s %d %s %d, %d:%d:%d UTC", 
        WEEKDAY_NAMES[weekday.ordinal], dt.day, MONTH_NAMES[dt.month-1], dt.year, dt.hour, dt.minute, dt.second)!!;
    term::printn(termHandle, s)!!;

    s = formatter.format("Unix timestamp: %d", time)!!;
    term::printn(termHandle, s)!!;

    term::printn(termHandle, @format_uptime(formatter, uptime))!!;

    logging::printn("Time program exited");
    return 0;
}

macro String? @format_uptime(Formatter #formatter, ulong uptime) {
    ulong seconds = uptime % 60;
    uptime /= 60;
    ulong minutes = uptime % 60;
    uptime /= 60;
    ulong hours = uptime % 24;

    if (hours > 0) {
        return #formatter.format("Uptime: %dh %dm %ds", hours, minutes, seconds);
    } else if (minutes > 0) {
        return #formatter.format("Uptime: %dm %ds", minutes, seconds);
    } else {
        return #formatter.format("Uptime: %ds", seconds);
    }
}
