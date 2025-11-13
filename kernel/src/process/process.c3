<*
    TODO: this is a temporary file to allow testing of APIs without a proper userspace
*>
module process;

import process::task @public;
import process::scheduler @public;
import muon::authority;
import lang;
import muon;

macro Task*? resolve_handle_to_task(ObjectTable table, Handle handle, TaskObjectRights rights = {}) @local {
    KernelObject obj = handle::resolve(table, handle, (ObjectRights)rights)!;
    return anycast(obj, Task);
}

<*
    Create a new task with the given entry point
    @param entryPoint : "The entry point to start the task from"
    @return "the handle to the newly created task"
*>
fn Handle? create(EntryPointFn entryPoint) {
    Task* parent = scheduler::get_current_task();

    // parent is null only for init task, which can do whatever it want
    if (parent != null) {
        ObjectSlot* slot = parent.handles.get(parent.spawnInfo.taskHandle);
        if (!handle::check_rights(*slot, (ObjectRights)task::CAN_CREATE_RIGHTS)) return handle::NO_PERMISSION?;
    }

    Task* task = task::create(entryPoint, parent: parent)!;
    Handle handle = task::create_handle(parent, task)!;

    return handle;
}

<*
    Start a new task given its handle
    @param handle : "The handle to the task to start"
*>
fn void? start(Handle handle) {
    Task* task = resolve_handle_to_task(scheduler::get_current_task().handles, handle)!;
    scheduler::enqueue_task(task);
}

<*
    Create a new task and start it immediately
    @param entryPoint : "The entry point to start the task from"
    @return "the handle to the newly created task"
*>
macro Handle? spawn(EntryPointFn entryPoint) {
    Handle handle = create(entryPoint)!;
    start(handle)!;
    
    return handle;
}

<*
    Exit the current task
*>
fn void exit() => terminate(scheduler::get_current_task().spawnInfo.taskHandle)!!;

<*
    Terminate a task given its handle
    @param handle : "The handle to the task to terminate"
*>
fn void? terminate(Handle handle) {
    Task* task = resolve_handle_to_task(scheduler::get_current_task().handles, handle, task::CAN_TERMINATE_RIGHTS)!;
    task::terminate(task);

    logging::debug("Task #%d terminated", task.id);
}

<*
    Yield the current task execution
*>
fn void yield() => task::yield();

<*
    Suspend a task given its handle
    @param handle : "The handle to the task to suspend"
*>
fn void? suspend(Handle handle = scheduler::get_current_task().spawnInfo.taskHandle) {
    Task* task = resolve_handle_to_task(scheduler::get_current_task().handles, handle, task::CAN_SUSPEND_RIGHTS)!;
    task::suspend(task);

    logging::debug("Task #%d suspended", task.id);
}

<*
    Resume a task given its handle
    @param handle : "The handle to the task to resume"
*>
fn void? resume(Handle handle) {
    Task* task = resolve_handle_to_task(scheduler::get_current_task().handles, handle, task::CAN_RESUME_RIGHTS)!;
    task::resume(task);
}

fn void? resume_after_sleep(ResumeContext ctx) {
    Task* task = resolve_handle_to_task(ctx.actor.handles, ctx.resumingHandle, task::CAN_RESUME_RIGHTS)!;
    task::resume(task);
}

<*
    Sleep the current task for the given duration (milliseconds)
    @param ms : "The number of milliseconds to sleep"
*>
fn void? sleep_ms(usz ms) => task::sleep_ms(ms);

<*
    Detach a task given its handle from the the current one by
    revoking the passed handle
    @param handle : "The handle to the task to detach"
*>
fn void? detach(Handle handle) {
    ObjectTable table = scheduler::get_current_task().handles;

    if (table.get(handle).object.type == Task.typeid) {
        authority::revoke(table, handle)!;
    } else {
        return handle::TYPE_MISMATCH?;
    }
}

fn void? wait(Handle handle) {
    Task* curr = scheduler::get_current_task();
    Task* task = resolve_handle_to_task(curr.handles, handle, {})!;
    
    logging::printn("Task #%d will wait for task #%d", curr.id, task.id);
    
    task::set_waiting_task(awaitor: curr, awaited: task);
    task::suspend(curr);
}