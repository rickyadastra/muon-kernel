module process::monitor;

import muon::authority;
import arch::mem;
import process::scheduler @public;
import process::task;
import lang;
import std::collections;

struct TaskSnapshot {
    ulong id;
    TaskState state;
	
	int exitStatus;
	ulong timeOfArrival;
	ulong timeOfCompletion;
	ulong timeOfFirstRun;
	ulong timeTotalBurst;
	ulong timeOfLastSchedule;

	bool hasPendingEvent;
	bool hasAwaitingTask;

	usz references;
	String command;
}

struct SchedulerMonitor (KernelObject) {
	RefCount refcount;
}

fn usz SchedulerMonitor.get_ref_count(&self) @dynamic => self.refcount.load();
fn void SchedulerMonitor.track_ref(&self) @dynamic => self.refcount.increment();
fn void SchedulerMonitor.drop_ref(&self) @dynamic => self.refcount.decrement();

macro SchedulerMonitor*? resolve_handle_to_monitor(Handle handle, ObjectRights rights = {}) @local {
    KernelObject obj = handle::resolve(scheduler::get_current_task().handles, handle, (ObjectRights)rights)!;
    return anycast(obj, SchedulerMonitor);
}

<*
    Create a new SchedulerMonitor object, register it and add handle to current task
    @require scheduler::get_current_task() != null
*>
fn Handle? create() {
    SchedulerMonitor* mon = (SchedulerMonitor*)mem::alloc(SchedulerMonitor.sizeof);

    // create handle for scheduler monitor in current task and track it
    Handle handle = scheduler::get_current_task().handles.insert(mon, {})!;
    mon.track_ref();

    // register object
    object::register(mon);

    return handle;
}

<*
	@require snapshots != null
*>
fn TaskSnapshot[]? fetch(Handle handle, TaskSnapshot[]* snapshots) {
    SchedulerMonitor* monitor = resolve_handle_to_monitor(handle, {})!;
    
	scheduler::lock_scheduler();
	defer scheduler::unlock_scheduler();

	Iterator{Task*} it = scheduler::allTasks.iterator();
	defer it.destroy();

	foreach (usz i, TaskSnapshot* &snapshot : snapshots) {
		if (!it.has_next()) break;
		Task* task = it.next()!!;

		snapshot.id = task.id;
		snapshot.state = task.state;

		snapshot.exitStatus = task.exitStatus;
		snapshot.timeOfArrival = task.timeOfArrival;
		snapshot.timeOfCompletion = task.timeOfCompletion;
		snapshot.timeOfFirstRun = task.timeOfFirstRun;
		snapshot.timeTotalBurst = task.timeTotalBurst;
		snapshot.timeOfLastSchedule = task.timeOfLastSchedule;

		snapshot.hasPendingEvent = task.pendingEvent != null;
		snapshot.hasAwaitingTask = task.pendingAwaitor != null;
		snapshot.references = task.get_ref_count();
		snapshot.command = task.spawnInfo.commandLine;
	}

	return (*snapshots)[:scheduler::allTasks.size];
}
