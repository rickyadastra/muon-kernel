module muon::authority::object;

import arch::mem;
import std::collections;
import muon;
import std::lock;

LinkedList{KernelObject} objects @local;
Spinlock lock @local;

fn void init() {
    objects = linkedlist::init{KernelObject}(mem::get_allocator());
}

fn void register(KernelObject obj) {
    lock.acquire();
    defer lock.release();

    objects.add(obj);
    log::debug("Registered new object %x", obj.ptr);
    print_info(obj);
}

fn bool? unregister(KernelObject obj) {
    lock.acquire();
    defer lock.release();

    if (obj.get_ref_count() > 0) return STILL_REFERENCED~;
    log::debug("Unregistering object %x", obj.ptr);

    return objects.remove(obj);
}

macro print_info(KernelObject obj) {  
    log::debug("Object %x, refcount: %d", obj.ptr, obj.get_ref_count());
}
