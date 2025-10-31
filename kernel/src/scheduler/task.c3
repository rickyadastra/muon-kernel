module scheduler::task;

import lang;
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

fn Task*? create(EntryPointFn entryPoint = null, usz stackSize = DEFAULT_KERNEL_STACK_SIZE, TaskState state = READY,
                    SpawnHandle[] extraHandles = {}, Task* parent = scheduler::current_task()) @private {
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
    task.handles.init(MAX_HANDLE_TABLE_SIZE)!;

    // create self handle
    Handle? selfHandle = create_handle(task, task, DEFAULT_SELF); 
    if (catch selfHandle) return INIT_SELF_HANDLE_FAIL?;

    // create spawnInfo
    if (try spawnInfoPtr = mem::alloc_pages(1)) {
        task.spawnInfo = (SpawnInfo*)spawnInfoPtr; // TODO: map to read only page in userspace
        task.spawnInfo.taskHandle = selfHandle;

        // root task isn't supposed to have handles passed on creation
        if (parent != null) {
            if (extraHandles.len > 0) {
                parent.handles.lock.acquire();
                defer parent.handles.lock.release();

                task.handles.lock.acquire();
                defer task.handles.lock.release();
                
                foreach (usz idx, SpawnHandle* &handle : extraHandles) {
                    logging::printn("Task(%d).spawnhandles[%d]: %x (%s) from parent Task #%d", task.id, idx, handle.handle, handle.type.nameof, parent.id);
                    parent.handles.copy_handle_to(task.handles, handle.handle, handle.type)!;
                }
            }
        } else {
            if (extraHandles.len > 0) return INIT_SPAWN_HANDLES_FAIL?;
        }

    } else {
        return INIT_SPAWN_INFO_FAIL?;
    }

    if (entryPoint != null && stackSize > 0) {
        task.taskStackBase = (void*)stackBase!;
        task.taskStackSize = stackSize;
        task.context.init(entryPoint, stackBase, stackBase+stackSize*mem::page_size(), task.spawnInfo)!;
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

fn Handle? spawn(EntryPointFn entryPoint, SpawnHandle... extraHandles) {
    scheduler::lock_scheduler();
    defer scheduler::unlock_scheduler();
    
    Task* task = create(entryPoint, extraHandles: extraHandles)!;
    Handle handle = create_handle(scheduler::current_task(), task)!;

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

    HandleTable table = scheduler::current_task().handles;
    Task* task = anycast(table.resolve_handle(handle, (HandlePerms)(TaskHandlePerms){.canTerminate = true})!, Task)!;

    scheduler::terminate_task(task);
}

fn void yield() {
    scheduler::yield_task();
}

fn void? suspend(Handle handle = scheduler::current_task().spawnInfo.taskHandle) {
    scheduler::lock_scheduler();
    defer scheduler::unlock_scheduler();

    HandleTable table = scheduler::current_task().handles;
    Task* task = anycast(table.resolve_handle(handle, (HandlePerms)(TaskHandlePerms){.canSuspend = true})!, Task)!;

    scheduler::suspend_task(task);
}

macro resume(Handle handle) => resume_by_context({handle, scheduler::current_task()});

fn void? resume_by_context(ResumeContext ctx) @local {
    scheduler::lock_scheduler();
    defer scheduler::unlock_scheduler();

    HandleTable table = ctx.actor.handles;
    Task* task = anycast(table.resolve_handle(ctx.resumingHandle, (HandlePerms)(TaskHandlePerms){.canResume = true})!, Task)!;

    scheduler::resume_task(task);
}

fn void? sleep_ms(usz ms) {
    scheduler::lock_scheduler();
    defer scheduler::unlock_scheduler();

    Task* task = scheduler::current_task();
    ResumeContext* resCtx = mem::alloc(ResumeContext.sizeof);
    resCtx.resumingHandle = task.spawnInfo.taskHandle;
    resCtx.actor = task;
    
    timing::schedule_milli(ms, fn void(TimerEvent* e) {
        ResumeContext*? resumeCtx = anycast(e.context, ResumeContext);

        if (catch ex = resumeCtx) {
            logging::printn("error after sleep: %s", ex.nameof);

        } else {
            // resume task if is suspended
            if (resumeCtx.actor.state == TaskState.SUSPENDED) {
                logging::printn("sleep ended");
                if (catch exx = resume_by_context(*resumeCtx)) {
                    logging::printn("error after sleep: %s", exx.nameof);
                }
            }
        }

        // free event context
        mem::free(e.context);

    }, (any)resCtx);

    suspend()!;
}
