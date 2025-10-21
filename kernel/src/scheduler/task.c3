module scheduler::task;

import arch;
import muon;
import scheduler @public;
import dev::timing;
import resource;
import random;
import std::lock;

<*
    @param[&in] task
*>
macro Handle? create_handle(Task* owner, Task* task, TaskHandlePerms perms = {}) @private {
    owner.handles.lock.acquire();
    defer owner.handles.lock.release();

    Handle handle = owner.handles.insert(task, ResourceType.TASK, (HandlePerms)perms)!;

    logging::printn("New handle created on task #%d: %x", owner.id, handle);

    return handle;
}

macro Task*? create(EntryPointFn entryPoint = null, usz stackSize = DEFAULT_KERNEL_STACK_SIZE, TaskState state = READY) @private {
    uptr? stackBase;
    if (entryPoint != null && stackSize > 0) {
        // TODO: move stack setup in TaskSpace.init
        stackBase = mem::alloc_pages(stackSize);
        if (catch stackBase) return task::INIT_STACK_FAIL?;
    }
    
    Task* task = mem::alloc(Task.sizeof);

    task.id = scheduler::nextTaskId.add(1);
    task.state = state;
    task.handles.init(168)!;

    if (entryPoint != null && stackSize > 0) {
        task.taskStackBase = (void*)stackBase!;
        task.taskStackSize = stackSize;
        task.context.init(entryPoint, stackBase, stackBase+stackSize*mem::page_size())!;
    }

    logging::debug("Task #%d created, stack %x-%x", task.id, stackBase, stackBase+stackSize*mem::page_size())!;
    return task;
}

macro void? destroy(Task* task) @private {
    if (task.taskStackBase != null) {
        mem::free_pages((uptr)task.taskStackBase, task.taskStackSize)!;
    }

    task.handles.destroy()!;
    mem::free(task);

    logging::debug("Task #%d destroyed", task.id);
}

fn Handle? spawn(EntryPointFn entryPoint, usz stackSize = DEFAULT_KERNEL_STACK_SIZE) {
    if (stackSize < 1) return INIT_STACK_TOO_SMALL?;

    scheduler::lock_scheduler();
    defer scheduler::unlock_scheduler();
    
    Task* task = create(entryPoint, stackSize)!;
    Handle handle = create_handle(scheduler::current_task(), task)!;

    scheduler::enqueue_task(task);
    return handle;
}

fn void terminate() {
    scheduler::terminate_task(scheduler::current_task());
}

fn void yield() @SchedulerYieldFn {
    scheduler::yield_task();
}

fn void sleep() @SchedulerYieldFn {
    scheduler::suspend_task(scheduler::current_task());
}

fn void sleep_milli(usz ms) {
    // scheduler::lock_scheduler();

    // // Task* callerTask = scheduler::currentTask;
    // // timing::schedule_milli(ms, fn void(TimerEvent* e) => scheduler::wake_task(callerTask));
    // sleep();
    // scheduler::unlock_scheduler();
}
