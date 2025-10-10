module scheduler;

import arch;
import dev::timing;
import std::collections::linkedlist;
import std::atomic;
import muon;

usz interruptDisableCounter @local = 0;
LinkedList{Task*} taskQueue @private;
Task* currentTask @private;
Task* idleTask @private;
Atomic{usz} nextTaskId @local;

const usz PREEMPT_INTERVAL_NANO = 1000_000_000;

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
    idleTask = task;
}

macro schedule_next_preempt() => timing::schedule_nano(PREEMPT_INTERVAL_NANO, &scheduler::schedule);

fn void schedule_next_rr(CpuContext* ctx) @private {
    lock_scheduler();
    defer unlock_scheduler();

    Task* nextTask;

    // save current context
    currentTask.context.save(ctx);

    // set current state and add to queue if needed
    if (currentTask != idleTask && currentTask.state == RUNNING) {
        logging::debug("enqueue current");
        currentTask.state = READY;
        taskQueue.add(currentTask);
    }

    // pick next task
    if (!taskQueue.is_empty()) {
        logging::debug("pick next");
        nextTask = taskQueue.remove_at(0)!!;
    } else {
        logging::debug("pick idle");
        nextTask = idleTask;
    }

    // no context load if it's the same
    if (nextTask == currentTask) {
        nextTask.state = RUNNING;
        return;
    }

    // change state, current and load context
    nextTask.state = RUNNING;
    currentTask = nextTask;
    nextTask.context.load(ctx);
}

fn void schedule(TimerEvent* timer) {
    lock_scheduler();
    defer unlock_scheduler();

    logging::printn("SCHEDULER PREEMPT");

    CpuContext* ctx = (CpuContext*)timer.context;
    schedule_next_rr(ctx);

    schedule_next_preempt();
}

fn void start() {
    schedule_next_preempt();
}
