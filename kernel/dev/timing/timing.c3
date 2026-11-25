module dev::timing;

import std::collections::linkedlist;
import std::lock;
import arch::mem;
import muon;

ulong? wallclock @private = WALLCLOCK_NOT_SET~;

// timesource
TimeSource timeSource @private;
KernelTime bootTime @private;

// timer subsystem
Timer timer @private;
LinkedList{TimerEvent*} timerEvents @private;
Spinlock lock @private;

fn TimerEvent*? add_timer_event(TimerEvent event) @private {
    lock.acquire();
    defer lock.release();

    TimerEvent* ev = mem::alloc(TimerEvent::size);
    *ev = event;

    if (timerEvents.is_empty()) {
        timerEvents.add(ev);
    } else {
        usz i = 0;
        while (try e = timerEvents.get(i) && e.timestamp < event.timestamp) i++;
        timerEvents.insert_at(i, ev)!;
    }

    return ev;
}

fn ulong get_wallclock() => wallclock!!;
macro ulong get_ticks() => timer.get_current();
fn ulong get_uptime() => timer ? (timer.get_current() - bootTime) / (ulong)timer.get_frequency() : 0;
fn ulong get_uptime_us() {
	if (!timer) return 0;
	ulong delta = timer.get_current() - bootTime;
	ulong freq = (ulong)timer.get_frequency();
	return (delta / freq) * 1_000_000 + ((delta % freq) * 1_000_000) / freq;
} 

macro @ticks_convert(ulong #ticks, double #scale) @local => ((double)#ticks * #scale) / timer.get_frequency();
macro ticks_to_nano(ulong ticks) => @ticks_convert(ticks, 1e9);
macro ticks_to_micro(ulong ticks) => @ticks_convert(ticks, 1e6);
macro ticks_to_milli(ulong ticks) => @ticks_convert(ticks, 1e3);

fn void? serve_timer_events(KernelTime currentTime, any ctx) @private {
    while (try e = timerEvents.first() && e.timestamp <= currentTime) {
        if (!e.isCancelled) {
            if (e.context == null) e.context = ctx;
            e.callback(e);
        }

        lock.acquire();
        TimerEvent* ev = timerEvents.remove_at(0)!!;
        mem::free(ev);
        lock.release();
    }
}

fn TimerEvent* schedule_nano(ulong nano, TimerCallbackFn callback, any context = null, KernelTime since = 0) {
    ulong deltaTicks = (ulong) (nano * (timer.get_frequency() / 1e9));
    KernelTime time = (since > 0 ? since : timer.get_current()) + deltaTicks;
    TimerEvent* newEvent = add_timer_event({time, callback, context, false})!!;

    if (try event = timerEvents.first() && event.timestamp >= time) timer.set(time);

    return newEvent;
}

fn TimerEvent* schedule_micro(ulong micro, TimerCallbackFn callback, any context = null, KernelTime since = 0) 
	=> schedule_nano(micro * 1_000, callback, context, since);
fn TimerEvent* schedule_milli(ulong milli, TimerCallbackFn callback, any context = null, KernelTime since = 0) 
	=> schedule_nano(milli * 1_000_000, callback, context, since);

fn bool TimerEvent.equals(&self, TimerEvent other) @operator(==) {
    return (other.timestamp == self.timestamp &&
            other.callback == self.callback &&
            other.context == self.context);
}

macro TimerEvent.cancel(&self) {
    self.isCancelled = true;
}
