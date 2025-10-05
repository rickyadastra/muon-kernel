module dev::timing;

import std::collections::linkedlist;

uint128? wallclock @private = WALLCLOCK_NOT_SET?;

// timer subsystem
Timer timer @private;
LinkedList{TimerEvent} timerEvents @private;

fn void? add_timer_event(TimerEvent event) @private {
    if (timerEvents.is_empty()) {
        timerEvents.add(event);
    } else {
        usz i = 0;
        while (try e = timerEvents.get(i) && e.timestamp < event.timestamp) i++;
        timerEvents.insert_at(i, event)!;
    }
}

fn void? serve_timer_events(KernelTime currentTime) @private {
    while (try e = timerEvents.first() && e.timestamp <= currentTime) {
        timerEvents.remove_at(0)!!;
        e.callback(&timer);
    }
}

fn void schedule_nano(ulong nano, TimerCallbackFn callback) {
    ulong deltaTicks = (ulong) (nano * (timer.get_frequency() / 1e9));
    KernelTime time = timer.get_current()+deltaTicks;

    add_timer_event({time, callback})!!;
    if (try event = timerEvents.first() && event.timestamp >= time) timer.set(time);
}

fn void schedule_micro(ulong micro, TimerCallbackFn callback) => schedule_nano(micro * 1_000, callback);
fn void schedule_milli(ulong milli, TimerCallbackFn callback) => schedule_nano(milli * 1_000_000, callback);
