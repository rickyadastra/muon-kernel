module process::scheduler;

import arch;
import dev::timing;
import std::collections;
import std::atomic;
import muon;
import process::task @public;
import process::worker;

usz interruptDisableCounter @local = 0;

LinkedList{Task*} taskQueue @private;           // task that can be run
LinkedList{Task*} terminatedQueue @private;     // task that are terminated but still referenced
LinkedList{Task*} cleanupQueue @private;        // task awaiting cleanup

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
    cleanupQueue = linkedlist::init{Task*}(mem::get_allocator());

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
		currentTask.timeTotalBurst += (timing::get_ticks() - currentTask.timeOfLastSchedule);
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
	nextTask.timeOfLastSchedule = timing::get_ticks();
	if (nextTask.timeOfFirstRun == 0) nextTask.timeOfFirstRun = nextTask.timeOfLastSchedule;
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
	@ensure interruptDisableCounter == 0
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
    @return "true if task is removed from queue"
*>
macro bool dequeue_task(Task* task) {
    return taskQueue.remove(task);
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
    @require task != null
*>
macro enqueue_awaiting_cleanup_task(Task* task) {
    lock_scheduler();
    defer unlock_scheduler();

    logging::debug("enqueue task %d (awaiting cleanup)", task.id);

    cleanupQueue.add(task);
}

macro check_other_terminated_tasks() {
    lock_scheduler();
    defer unlock_scheduler();

    if (!terminatedQueue.is_empty()) {
        MutableIterator{Task*} it = terminatedQueue.mutable_iterator();
        defer it.destroy();

        while (it.has_next()) {
            Task* task = it.next()!!;
            if (task.get_ref_count() == 0) {
                it.remove();
                task::prepare_cleanup(task);
            }
        }
    }
}

<*
    @ensure return != null
*>
macro Task* get_current_task() {
    lock_scheduler();
    defer unlock_scheduler();

    return currentTask;
}
