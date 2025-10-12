module scheduler;

import arch;
import dev::timing;
import std::collections::linkedlist;
import std::atomic;
import muon;

usz interruptDisableCounter @local = 0;
LinkedList{Task*} taskQueue @private;
LinkedList{Task*} terminatedQueue @private;
Task* currentTask @private;
Task* idleTask @private;
Task* cleanupTask @private;
Atomic{usz} nextTaskId @private;

const usz PREEMPT_INTERVAL_NANO = 25_000_000; // 25ms

macro lock_scheduler() @private {
    cpu::disable_interrupts();
    interruptDisableCounter++;
}

macro unlock_scheduler() @private {
    interruptDisableCounter--;
    if (!interruptDisableCounter) cpu::enable_interrupts();
}

fn void? init() {
    lock_scheduler();
    defer unlock_scheduler();

    taskQueue = linkedlist::init{Task*}(mem::get_allocator());
    terminatedQueue = linkedlist::init{Task*}(mem::get_allocator());

    // setup bootstrap task
    Task* task = task::create()!;
    idleTask = task;

    // setup terminated_tasks_cleanup
    Task* worker = task::create(&worker::terminated_tasks_cleanup, state: WAITING)!;
    cleanupTask = worker;

    currentTask = idleTask;
}

fn void start() {
    schedule_next_preempt_event();
}

macro schedule_next_preempt_event() => timing::schedule_nano(PREEMPT_INTERVAL_NANO, &scheduler::schedule_preempt_handler);

fn Task* schedule_next_ready_task() @private {
    lock_scheduler();
    defer unlock_scheduler();

    // set current state and add to queue if needed
    if (currentTask != idleTask && currentTask != cleanupTask && currentTask.state == RUNNING) {
        currentTask.state = READY;
        enqueue_task(currentTask);
    }

    // pick next task
    Task* nextTask;
    
    if (!taskQueue.is_empty()) {
        nextTask = taskQueue.remove_at(0)!!;
        logging::debug("pick task %d", nextTask.id);
    } else {
        logging::debug("pick idle");
        nextTask = idleTask;
    }

    // no context load if it's the same
    if (nextTask == currentTask) {
        nextTask.state = RUNNING;
        return currentTask;
    }

    // change state, current and load context
    nextTask.state = RUNNING;
    currentTask = nextTask;

    return nextTask;
}

fn void schedule_rr(CpuContext* ctx) {
    lock_scheduler();
    defer unlock_scheduler();
    
    currentTask.context.save_from(ctx);
    Task* nextTask = schedule_next_ready_task();
    nextTask.context.load_to(ctx);
}

fn void schedule_preempt_handler(TimerEvent* timer) {
    lock_scheduler();
    defer unlock_scheduler();

    schedule_rr((CpuContext*)timer.context);

    schedule_next_preempt_event();
}

macro enqueue_task(Task* task) {
    lock_scheduler();
    defer unlock_scheduler();

    logging::debug("enqueue task %d", task.id);

    taskQueue.add(task);
}

macro enqueue_terminated_task(Task* task) {
    lock_scheduler();
    defer unlock_scheduler();

    logging::debug("enqueue task %d (terminated)", task.id);

    terminatedQueue.add(task);
}

macro wake_task(Task* task) {
    lock_scheduler();
    defer unlock_scheduler();

    if (task.state == WAITING) {
        task.state = READY;
        enqueue_task(task);
    }
}
