module process::task;

import lang;
import arch;
import muon;
import process @public;
import dev::timing;
import std::lock;

fn usz Task.get_ref_count(&self) @dynamic => self.refcount.load();

fn void Task.track_ref(&self) @dynamic {
    usz v = self.refcount.increment()+1;
    logging::printn("Task@%x's refcount after track_ref(): %d", self, v);
}

fn void Task.drop_ref(&self) @dynamic {
    usz v = self.refcount.decrement()-1;
    logging::printn("Task@%x's refcount after drop_ref(): %d", self, v);
}

<*
    @param[&in] owner
    @param[&in] task
*>
macro Handle? create_handle(Task* owner, Task* task, TaskObjectRights rights = {}) => owner.handles.insert(task, (ObjectRights)rights);

fn Task*? create(EntryPointFn entryPoint = null, usz stackSize = DEFAULT_KERNEL_STACK_SIZE, TaskState state = READY,
                Task* parent = scheduler::get_current_task()) @private {
    if (stackSize < DEFAULT_KERNEL_STACK_SIZE) return INIT_STACK_TOO_SMALL?;
    
    uptr? stackBase;
    if (entryPoint != null && stackSize > 0) {
        // TODO: move stack setup in TaskSpace.init
        stackBase = mem::alloc_pages(stackSize);
        if (catch stackBase) return task::INIT_STACK_FAIL?;
    }
    
    Task* task = mem::alloc(Task.sizeof);

    task.id = scheduler::nextTaskId.add(1);
    task.state = state;
    task.handles.init(object::MAX_TABLE_SIZE)!;

    // create self handle
    Handle? selfHandle = create_handle(task, task, DEFAULT_SELF); 
    if (catch selfHandle) return INIT_SELF_HANDLE_FAIL?;
    task.track_ref();

    task.spawnInfo = (SpawnInfo*)mem::alloc(SpawnInfo.sizeof); // TODO: map to read only page in userspace
    task.spawnInfo.taskHandle = selfHandle;

    // parent will receive a handle to the new task, track it
    if (parent != null) task.track_ref();

    if (entryPoint != null && stackSize > 0) {
        task.taskStackBase = (void*)stackBase!;
        task.taskStackSize = stackSize;
        task.context.init(entryPoint, stackBase, stackBase+stackSize*mem::page_size(), task.spawnInfo)!;
    }

    logging::debug("Task #%d created, stack %x-%x", task.id, stackBase, stackBase+stackSize*mem::page_size())!;

    object::register(task);
    return task;
}

fn void? destroy(Task* task) @private {
    if (task.taskStackBase != null) {
        mem::free_pages((uptr)task.taskStackBase, task.taskStackSize)!;
    }

    task.handles.destroy()!;
    mem::free(task);

    logging::debug("Task #%d destroyed", task.id);
}

<*
    This naked function is called when returning from the task entry point to address
    stack not being aligned to 8 byte on a function call to comply with System V ABI
    requirements. 

    TODO: move to arch-dependant task.c3
*>
fn void exit_trampoline() @naked @private {
    asm { movl $edi, $eax; }; // move return value to first param
    ((VoidFn)&process::exit)();
}

<*
    @require task != null
*>
macro resume(Task* task) {
    if (task.state == SUSPENDED) {
        task.state = READY;
        scheduler::enqueue_task(task);
    }
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

macro prepare_cleanup(Task* task) {
    logging::printn("Task #%d is ready for cleanup", task.id);

    task.state = CLEANUP;
    scheduler::enqueue_awaiting_cleanup_task(task);
    resume(scheduler::cleanupTask);
}

<*
    @require task != null
*>
fn void terminate(Task* task, int ret) {
    scheduler::lock_scheduler();

    if (scheduler::dequeue_task(task)) logging::debug("removed terminated task from ready queue");
    task.handles.remove_all();

    // resume awaitor
    if (task.pendingAwaitor != null) {
        logging::printn("Resuming awaitor Task #%x", task.pendingAwaitor);
        resume(task.pendingAwaitor);
    }

    // if current task is not referenced anymore, schedule cleanup
    if (task.get_ref_count() == 0) {
        prepare_cleanup(task);
    } else {
        task.state = TERMINATED;
        task.exitStatus = ret;
        scheduler::enqueue_terminated_task(task);
    }

    scheduler::check_other_terminated_tasks();

    bool shouldYield = scheduler::get_current_task() == task;
    scheduler::unlock_scheduler();
    
    if (shouldYield) yield();
}

macro bool do_suspend(Task* task) @private {
    scheduler::lock_scheduler();
    defer scheduler::unlock_scheduler();
    
    task.state = SUSPENDED;
    return scheduler::get_current_task() == task;
}

<*
    @require task != null
*>
fn void suspend(Task* task) {
    scheduler::lock_scheduler();
    bool shouldYield = do_suspend(task);
    scheduler::unlock_scheduler();
    
    if (shouldYield) yield();
}

<*
    @param[&inout] awaitor : "The task suspended until awaited terminates"
    @param[&inout] awaited : "The task that notifies awaitor when terminated"
*>
fn void? wait(Task* awaitor, Task* awaited) {
    scheduler::lock_scheduler();

    if (awaited.state == TERMINATED) {
        logging::printn("Task #%d will NOT wait for already terminated task #%d", awaitor.id, awaited.id);
        scheduler::unlock_scheduler();

    } else {
        logging::printn("Task #%d will wait for task #%d", awaitor.id, awaited.id);
        
        awaited.pendingAwaitor = awaitor;
        bool shouldYield = do_suspend(awaitor);
        scheduler::unlock_scheduler();

        yield();
    }
}

fn void? sleep_ms(usz ms) {
    scheduler::lock_scheduler();
    defer scheduler::unlock_scheduler();

    Task* task = scheduler::get_current_task();
    ResumeContext* resCtx = mem::alloc(ResumeContext.sizeof);
    resCtx.resumingHandle = task.spawnInfo.taskHandle;
    resCtx.actor = task;
    
    TimerEvent* event = timing::schedule_milli(ms, fn void(TimerEvent* e) {
        ResumeContext*? resumeCtx = anycast(e.context, ResumeContext);

        if (catch ex = resumeCtx) {
            logging::printn("error after sleep: %s", ex.nameof);

        } else {
            // clear pending event
            resumeCtx.actor.pendingEvent = null;

            // resume task if is suspended
            if (resumeCtx.actor.state == TaskState.SUSPENDED) {
                if (catch exx = process::resume_after_sleep(*resumeCtx)) {
                    logging::printn("error after sleep: %s", exx.nameof);
                }
            }
        }

        // free event context
        mem::free(e.context);

    }, (any)resCtx);

    task.pendingEvent = event;
    suspend(task);
}

fn void block(Task* task) {
    scheduler::lock_scheduler();
    defer scheduler::unlock_scheduler();
    
    task.state = BLOCKED;
}
