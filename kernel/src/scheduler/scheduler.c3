module scheduler;

import arch;
import std::collections::linkedlist;

usz interruptDisableCounter @local = 0;
LinkedList{Task*} taskQueue @private;

macro lock_scheduler() @local {
    cpu::disable_interrupts();
    interruptDisableCounter++;
}

macro unlock_scheduler() @local {
    interruptDisableCounter--;
    if (!interruptDisableCounter) cpu::enable_interrupts();
}

fn void init() {
    lock_scheduler();
    defer unlock_scheduler();

    taskQueue = linkedlist::init{Task*}(mem::get_allocator());
}
