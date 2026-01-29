module muon::sync::semaphore;

import std::atomic;
import std::collections;
import process;
import process::scheduler @public;
import muon::authority;
import arch::mem;
import lang;

struct Semaphore (KernelObject) {
    Atomic{usz} value;
    LinkedList{Task*} queue;
    RefCount refcount;
}

fn usz Semaphore.get_ref_count(&self) @dynamic => self.refcount.load();
fn void Semaphore.track_ref(&self) @dynamic => self.refcount.increment();
fn void Semaphore.drop_ref(&self) @dynamic => self.refcount.decrement();

fn void Semaphore.wait(&self) @private {
    scheduler::lock_scheduler();

    // if a resource is available take it and exit 
    if (self.value.load() > 0) {
        self.value.decrement();
        scheduler::unlock_scheduler();
        return;
    }

    Task* curr = scheduler::get_current_task();
    task::block(curr);
    self.queue.add(curr);
    scheduler::unlock_scheduler();
    task::yield();
}

fn void Semaphore.signal(&self) @private {
    scheduler::lock_scheduler();
    defer scheduler::unlock_scheduler();
    
    if (!self.queue.is_empty()) {
        Task* task = self.queue.remove_at(0)!!;
        task.state = READY;
        scheduler::enqueue_task(task);

    } else {
        self.value.increment();
    }
}

fn Semaphore* alloc() @private {
    Semaphore* s = (Semaphore*)mem::alloc(Semaphore.sizeof);
    s.queue = linkedlist::init{Task*}(mem::get_allocator());
    return s;
}

macro Semaphore*? resolve_handle_to_sem(Handle handle, ObjectRights rights = {}) @local {
    KernelObject obj = handle::resolve(scheduler::get_current_task().handles, handle, (ObjectRights)rights)!;
    return anycast(obj, Semaphore);
}

<*
    Create a new Semaphore object, register it and add handle to current task
    @require scheduler::get_current_task() != null
*>
fn Handle? create(usz initialValue) {
    Semaphore* s = alloc();
    s.value.store(initialValue);

    // create handle for semaphore in current task and track it
    Handle handle = scheduler::get_current_task().handles.insert(s, {})!;
    s.track_ref();

    // register object
    object::register(s);

    return handle;
}

fn void? wait(Handle handle) {
    Semaphore* sem = resolve_handle_to_sem(handle, {})!;
    sem.wait();
}

fn void? signal(Handle handle) {
    Semaphore* sem = resolve_handle_to_sem(handle, {})!;
    sem.signal();
}
