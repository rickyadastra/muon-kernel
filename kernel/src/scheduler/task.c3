module scheduler::task;

import arch;
import muon;
import scheduler @public;

macro Task*? create(EntryPointFn entryPoint = null, usz stackSize = 2, TaskState state = READY) {
    uptr? stackBase;
    if (entryPoint != null && stackSize > 0) {
        // TODO: move stack setup in TaskSpace.init
        stackBase = mem::alloc_pages(stackSize);
        if (catch stackBase) return task::INIT_STACK_FAIL?;
    }
    
    Task* task = mem::alloc(Task.sizeof);

    task.id = scheduler::nextTaskId.add(1);
    task.state = state;

    if (entryPoint != null && stackSize > 0) {
        task.taskStackBase = (void*)stackBase!;
        task.taskStackSize = stackSize;
        task.context.init(entryPoint, stackBase, stackBase+stackSize*mem::page_size())!;
    }

    logging::debug("Task #%d created", task.id);
    return task;
}

macro void? destroy(Task* task) {
    if (task.taskStackBase != null) {
        mem::free_pages((uptr)task.taskStackBase, task.taskStackSize)!;
    }

    mem::free(task);
    logging::debug("Task #%d destroyed", task.id);
}

fn void? spawn(EntryPointFn entryPoint, usz stackSize = 2) {
    if (stackSize < 1) return INIT_STACK_TOO_SMALL?;
    
    Task* task = create(entryPoint, stackSize)!;
    scheduler::enqueue_task(task);
}

fn void terminate() {
    scheduler::lock_scheduler();

    scheduler::currentTask.state = TERMINATED;
    scheduler::enqueue_terminated_task(scheduler::currentTask);
    scheduler::wake_task(scheduler::cleanupTask);

    scheduler::unlock_scheduler();

    yield();
}

alias VoidFn = fn void();

fn void yield() @naked {
    scheduler::lock_scheduler();

    prepare_yielding();
    ((VoidFn)&scheduler::schedule_rr)();
    complete_yielding();

    scheduler::unlock_scheduler();
    exit_yielding();
}

fn void sleep() {
    scheduler::lock_scheduler();
    defer scheduler::unlock_scheduler();

    scheduler::currentTask.state = WAITING;
    logging::debug("Sleep task %d", scheduler::currentTask.id);

    yield();
}
