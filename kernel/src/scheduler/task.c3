module scheduler::task;

import lang;
import arch;
import muon;
import scheduler @public;
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
    @param[&in] task
*>
macro Handle? create_handle(Task* owner, Task* task, TaskObjectRights rights = {}) @private {
    Handle handle = owner.handles.insert(task, (ObjectRights)rights)!;

    logging::printn("New handle created on task #%d: %x", owner.id, handle);

    return handle;
}

fn Task*? create(EntryPointFn entryPoint = null, usz stackSize = DEFAULT_KERNEL_STACK_SIZE, TaskState state = READY,
                Task* parent = scheduler::current_task()) @private {
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

macro void? destroy(Task* task) @private {
    if (task.taskStackBase != null) {
        mem::free_pages((uptr)task.taskStackBase, task.taskStackSize)!;
    }

    task.handles.destroy()!;
    mem::free(task);

    logging::debug("Task #%d destroyed", task.id);
}

fn Handle? spawn(EntryPointFn entryPoint) {
    scheduler::lock_scheduler();
    defer scheduler::unlock_scheduler();
    
    Task* parent = scheduler::current_task();
    Task* task = create(entryPoint)!;
    Handle handle = create_handle(parent, task)!;

    scheduler::enqueue_task(task);
    return handle;
}

<*
    This naked function is called when returning from the task entry point to address
    stack not being aligned to 8 byte on a function call to comply with System V ABI
    requirements. 

    TODO: move to arch-dependant task.c3
*>
fn void exit_trampoline() @naked @private {
    exit();
}

fn void exit() {
    terminate(scheduler::current_task().spawnInfo.taskHandle)!!;
}

fn void? terminate(Handle handle) {
    scheduler::lock_scheduler();
    defer scheduler::unlock_scheduler();

    ObjectTable table = scheduler::current_task().handles;
    KernelObject obj = handle::resolve(table, handle, (ObjectRights)(TaskObjectRights){.canTerminate = true})!;

    Task* task = anycast(obj, Task)!;
    logging::debug("Task #%d terminated", task.id);

    scheduler::terminate_task(task);
}

fn void yield() {
    scheduler::yield_task();
}

fn void? suspend(Handle handle = scheduler::current_task().spawnInfo.taskHandle) {
    scheduler::lock_scheduler();
    defer scheduler::unlock_scheduler();

    ObjectTable table = scheduler::current_task().handles;
    KernelObject obj = handle::resolve(table, handle, (ObjectRights)(TaskObjectRights){.canTerminate = true})!;

    Task* task = anycast(obj, Task)!;

    scheduler::suspend_task(task);
}

macro resume(Handle handle) => resume_by_context({handle, scheduler::current_task()});

fn void? resume_by_context(ResumeContext ctx) @local {
    scheduler::lock_scheduler();
    defer scheduler::unlock_scheduler();

    ObjectTable table = ctx.actor.handles;
    KernelObject obj = handle::resolve(table, ctx.resumingHandle, (ObjectRights)(TaskObjectRights){.canTerminate = true})!;

    Task* task = anycast(obj, Task)!;

    scheduler::resume_task(task);
}

fn void? sleep_ms(usz ms) {
    scheduler::lock_scheduler();
    defer scheduler::unlock_scheduler();

    Task* task = scheduler::current_task();
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
                if (catch exx = resume_by_context(*resumeCtx)) {
                    logging::printn("error after sleep: %s", exx.nameof);
                }
            }
        }

        // free event context
        mem::free(e.context);

    }, (any)resCtx);

    task.pendingEvent = event;
    suspend()!;
}

fn void? detach(Handle handle) {
    scheduler::lock_scheduler();
    defer scheduler::unlock_scheduler();

    ObjectTable table = scheduler::current_task().handles;
    authority::revoke(table, handle)!;
}
