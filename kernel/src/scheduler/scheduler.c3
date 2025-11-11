module scheduler;

import arch;
import dev::timing;
import std::collections::linkedlist;
import std::atomic;
import muon;
import scheduler::task @public;

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

macro schedule_next_preempt_event() => timing::schedule_nano(PREEMPT_INTERVAL_NANO, &scheduler::preempt_handler);

<*
    Setup queues, create bootstrap/idle task and workers
*>
fn void? init() {
    lock_scheduler();
    defer unlock_scheduler();

    taskQueue = linkedlist::init{Task*}(mem::get_allocator());
    terminatedQueue = linkedlist::init{Task*}(mem::get_allocator());

    // setup bootstrap task
    Task* task = task::create()!;
    idleTask = task;

    // setup terminated_tasks_cleanup
    Task* worker = task::create(&worker::terminated_tasks_cleanup, state: SUSPENDED, parent: task)!;
    task::create_handle(idleTask, worker)!;
    cleanupTask = worker;

    currentTask = idleTask;
}

<*
    Start preemption by scheduling next timer event
*>
fn void start() {
    schedule_next_preempt_event();
}

<*
    Pick next ready task from queue with round-robin policy
*>
fn Task* pick_next_ready_task() @private {
    lock_scheduler();
    defer unlock_scheduler();

    // set current state and add to queue if needed
    if (currentTask != idleTask && currentTask.state == RUNNING) {
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

<*
    Save given context, pick next task and restore its context
    @param[&inout] ctx
*>
fn void schedule_rr(CpuContext** ctx) {
    lock_scheduler();
    defer unlock_scheduler();
    
    currentTask.context.save_from(*ctx);
    Task* nextTask = pick_next_ready_task();
    nextTask.context.load_to(ctx);
}

<*
    Timer event handler for preemption
*>
fn void preempt_handler(TimerEvent* timer) @private {
    lock_scheduler();
    defer unlock_scheduler();

    schedule_rr((CpuContext**)timer.context);

    schedule_next_preempt_event();
}

<*
    @require task != null
*>
macro enqueue_task(Task* task) {
    lock_scheduler();
    defer unlock_scheduler();

    logging::debug("enqueue task %d", task.id);

    taskQueue.add(task);
}

<*
    @require task != null
*>
macro enqueue_terminated_task(Task* task) {
    lock_scheduler();
    defer unlock_scheduler();

    logging::debug("enqueue task %d (terminated)", task.id);

    terminatedQueue.add(task);
}

<*
    @ensure return != null
*>
macro Task* current_task() {
    lock_scheduler();
    defer unlock_scheduler();

    return currentTask;
}

<*
    @require task != null
*>
macro resume_task(Task* task) {
    lock_scheduler();
    defer unlock_scheduler();

    if (task.state == SUSPENDED) {
        task.state = READY;
        enqueue_task(task);
    }
}

alias VoidFn = fn void();

fn void yield_task() @naked {
    lock_scheduler();

    task::prepare_yielding();
    ((VoidFn)&schedule_rr)();
    task::complete_yielding();

    unlock_scheduler();
    task::exit_yielding();
}

<*
    @require task != null
*>
macro terminate_task(Task* task) {
    lock_scheduler();

    task.state = TERMINATED;
    task.handles.remove_all();
    
    enqueue_terminated_task(task);
    resume_task(scheduler::cleanupTask);

    if (taskQueue.remove(task)) logging::debug("removed terminated task from queue");

    bool shouldYield = currentTask == task;
    unlock_scheduler();
    
    if (shouldYield) yield_task();
}

<*
    @require task != null
*>
macro suspend_task(Task* task) {
    lock_scheduler();
    defer unlock_scheduler();

    task.state = SUSPENDED;
    logging::debug("Sleep task %d", task.id);

    if (currentTask == task) yield_task();
}
