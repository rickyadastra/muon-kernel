module dev::timing;

import std::collections::linkedlist;
import std::lock;

ulong? wallclock @private = WALLCLOCK_NOT_SET?;

// timer subsystem
Timer timer @private;
LinkedList{TimerEvent} timerEvents @private;
Spinlock lock @private;

fn void? add_timer_event(TimerEvent event) @private {
    lock.acquire();
    defer lock.release();

    if (timerEvents.is_empty()) {
        timerEvents.add(event);
    } else {
        usz i = 0;
        while (try e = timerEvents.get(i) && e.timestamp < event.timestamp) i++;
        timerEvents.insert_at(i, event)!;
    }
}

fn ulong get_current() => wallclock!!;

fn void? serve_timer_events(KernelTime currentTime, any ctx) @private {
    while (try e = timerEvents.first() && e.timestamp <= currentTime) {
        if (e.context == null) e.context = ctx;
        e.callback(&e);

        lock.acquire();
        timerEvents.remove_at(0)!!;
        lock.release();
    }
}

fn TimerEvent schedule_nano(ulong nano, TimerCallbackFn callback, any context = null) {
    ulong deltaTicks = (ulong) (nano * (timer.get_frequency() / 1e9));
    KernelTime time = timer.get_current()+deltaTicks;
    TimerEvent newEvent = {time, callback, context};
    add_timer_event(newEvent)!!;

    if (try event = timerEvents.first() && event.timestamp >= time) timer.set(time);

    return newEvent;
}

fn TimerEvent schedule_micro(ulong micro, TimerCallbackFn callback, any context = null) => schedule_nano(micro * 1_000, callback, context);
fn TimerEvent schedule_milli(ulong milli, TimerCallbackFn callback, any context = null) => schedule_nano(milli * 1_000_000, callback, context);

fn bool TimerEvent.equals(&self, TimerEvent other) @operator(==) {
    return (other.timestamp == self.timestamp &&
            other.callback == self.callback &&
            other.context == self.context);
}

macro TimerEvent.cancel(&self) {
    self.isCancelled = true;
}
