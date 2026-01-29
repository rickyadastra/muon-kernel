<*
    TODO: this is a temporary file to allow testing of APIs without a proper userspace
*>
module process;

import process::task @public;
import process::scheduler @public;
import dev::timing;
import muon::authority;
import lang;
import muon;

struct TaskAccountingLog {
	double turnaroundTime;
	double responseTime;
	double waitTime;
}

macro @entry_void_to_int($f) {
    return (EntryPointFn) fn int (SpawnInfo* info) {
        $f(info);
        return 0;
    };
}

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
fn void exit(int ret = 0) => terminate(scheduler::get_current_task().spawnInfo.taskHandle, ret: ret)!!;

<*
    Terminate a task given its handle
    @param handle : "The handle to the task to terminate"
*>
fn void? terminate(Handle handle, int ret = 0) {
    Task* task = resolve_handle_to_task(scheduler::get_current_task().handles, handle, task::CAN_TERMINATE_RIGHTS)!;
    task::terminate(task, ret);

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

fn void? resume_after_sleep(ResumeContext ctx) @private {
    Task* task = resolve_handle_to_task(ctx.actor.handles, ctx.resumingHandle, task::CAN_RESUME_RIGHTS)!;
    task::resume(task);
}

<*
    Sleep the current task for the given duration (milliseconds)
    @param ms : "The number of milliseconds to sleep"
*>
fn void? sleep_ms(usz ms) => task::sleep_ms(ms);

macro void? remove_handle_from(ObjectTable table, Handle handle) @local {
    if (table.get(handle).object.type == Task.typeid) {
        authority::revoke(table, handle)!;
    } else {
        return handle::TYPE_MISMATCH?;
    }
}

<*
    Detach a task given its handle from the the current one by
    revoking the passed handle
    @param handle : "The handle to the task to detach"
*>
fn void? detach(Handle handle) {
    ObjectTable table = scheduler::get_current_task().handles;
    remove_handle_from(table, handle)!;
}

fn int? wait(Handle handle, TaskAccountingLog* accountingLog = null) {
    Task* curr = scheduler::get_current_task();
    Task* task = resolve_handle_to_task(curr.handles, handle, {})!;
    
    task::wait(awaitor: curr, awaited: task)!;

	if (accountingLog != null) {
		ulong elapsed = task.timeOfCompletition-task.timeOfArrival;
		accountingLog.turnaroundTime = timing::ticks_to_milli(elapsed);
		accountingLog.responseTime = timing::ticks_to_milli(task.timeOfFirstRun-task.timeOfArrival);
		accountingLog.waitTime = accountingLog.turnaroundTime - timing::ticks_to_milli(task.timeTotalBurst);
	}

    int code = task.exitStatus;
    remove_handle_from(curr.handles, handle)!;
    
    return code;
}

<*
    @require id < 3
*>
fn void? set_aux_handle(Handle destTaskHandle, usz id, Handle newHandle) {
    Task* curr = scheduler::get_current_task();
    Task* task = resolve_handle_to_task(curr.handles, destTaskHandle, {})!;

    ObjectTable table = curr.handles;
    KernelObject newObj = table.get(newHandle).object;

    if (table.get(destTaskHandle).object.type == Task.typeid) {
        Handle handle = authority::delegate(table, newHandle, task.handles, {})!;
        newObj.track_ref();
        task.spawnInfo.auxHandles[id] = handle;
        
    } else {
        return handle::TYPE_MISMATCH?;
    }
}

fn void? set_command_line(Handle handle, String cmdline) {
    if (cmdline.len > 0) {
        Task* task = resolve_handle_to_task(scheduler::get_current_task().handles, handle, {})!;
        task::set_command_line(task, cmdline);
    }
}