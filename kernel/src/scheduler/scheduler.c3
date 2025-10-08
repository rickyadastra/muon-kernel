module scheduler;

import arch;
import std::collections::linkedlist;
import std::atomic;

usz interruptDisableCounter @local = 0;
LinkedList{Task*} taskQueue @private;
Task* currentTask @private;
Atomic{usz} nextTaskId @local;

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

    // setup bootstrap task
    Task* task = mem::alloc(Task.sizeof);
    task.state = RUNNING;
    task.id = nextTaskId.add(1);

    currentTask = task;
}
