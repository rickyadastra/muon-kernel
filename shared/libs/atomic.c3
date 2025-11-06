module std::atomic;

enum AtomicOrdering : int {
    NOT_ATOMIC,         // Not atomic
    UNORDERED,          // No lock
    RELAXED,            // Consistent ordering
    ACQUIRE,            // Barrier locking load/store
    RELEASE,            // Barrier releasing load/store
    ACQUIRE_RELEASE,    // Barrier fence to load/store
    SEQ_CONSISTENT,     // Acquire semantics, ordered with other seq_consistent
}

macro fetch_add(ptr, y, AtomicOrdering $ordering = SEQ_CONSISTENT, bool $volatile = false, usz $alignment = 0) {
    $if $alignment == 0:
        $alignment = $typeof(*ptr).sizeof;
    $endif
    return $$atomic_fetch_add(ptr, y, $volatile, $ordering.ordinal, $alignment); 
}

macro fetch_sub(ptr, y, AtomicOrdering $ordering = SEQ_CONSISTENT, bool $volatile = false, usz $alignment = 0) {
    $if $alignment == 0:
        $alignment = $typeof(*ptr).sizeof;
    $endif
    return $$atomic_fetch_sub(ptr, y, $volatile, $ordering.ordinal, $alignment); 
}

module std::atomic::types{Type};

struct Atomic {
    Type data;
}

<*
    @param ordering : "The ordering, cannot be release or acquire-release."
    @require ordering != RELEASE && ordering != ACQUIRE_RELEASE : "Release and acquire-release are not valid for load"
*>
macro Type Atomic.load(&self, AtomicOrdering ordering = SEQ_CONSISTENT) {
    Type* data = &self.data;
    switch(ordering) {
        case NOT_ATOMIC: return $$atomic_load(data, false, AtomicOrdering.NOT_ATOMIC.ordinal);
        case UNORDERED: return $$atomic_load(data, false, AtomicOrdering.UNORDERED.ordinal);
        case RELAXED: return $$atomic_load(data, false, AtomicOrdering.RELAXED.ordinal);
        case ACQUIRE: return $$atomic_load(data, false, AtomicOrdering.ACQUIRE.ordinal);
        case SEQ_CONSISTENT: return $$atomic_load(data, false, AtomicOrdering.SEQ_CONSISTENT.ordinal);
        case ACQUIRE_RELEASE:
        case RELEASE: $$unreachable();
    }
}

<*
    @param ordering : "The ordering, cannot be acquire or acquire-release."
    @require ordering != ACQUIRE && ordering != ACQUIRE_RELEASE : "Acquire and acquire-release are not valid for store"
*>
macro void Atomic.store(&self, Type value, AtomicOrdering ordering = SEQ_CONSISTENT) {
    Type* data = &self.data;
    switch(ordering) {
        case NOT_ATOMIC: $$atomic_store(data, value, false, AtomicOrdering.NOT_ATOMIC.ordinal);
        case UNORDERED: $$atomic_store(data, value, false, AtomicOrdering.UNORDERED.ordinal);
        case RELAXED: $$atomic_store(data, value, false, AtomicOrdering.RELAXED.ordinal);
        case RELEASE: $$atomic_store(data, value, false, AtomicOrdering.RELEASE.ordinal);
        case SEQ_CONSISTENT: $$atomic_store(data, value, false, AtomicOrdering.SEQ_CONSISTENT.ordinal);
        case ACQUIRE_RELEASE:
        case ACQUIRE: $$unreachable();
    }
}

<*
 @require $success != AtomicOrdering.NOT_ATOMIC && $success != AtomicOrdering.UNORDERED : "Acquire ordering is not valid."
 @require $failure != AtomicOrdering.RELEASE && $failure != AtomicOrdering.ACQUIRE_RELEASE : "Acquire release is not valid."
*>
macro Atomic.compare_exchange(&self, compare, value, AtomicOrdering $success = SEQ_CONSISTENT, AtomicOrdering $failure = SEQ_CONSISTENT, bool $volatile = true, bool $weak = false, usz $alignment = 0) {
	return $$compare_exchange(&self.data, compare, value, $volatile, $weak, $success.ordinal, $failure.ordinal, $alignment);
}

macro @atomic_exec(#func, data, value, ordering) @local {
    switch(ordering) {
        case RELAXED: return #func(data, value, RELAXED);
        case ACQUIRE: return #func(data, value, ACQUIRE);
        case RELEASE: return #func(data, value, RELEASE);
        case ACQUIRE_RELEASE: return #func(data, value, ACQUIRE_RELEASE);
        case SEQ_CONSISTENT: return #func(data, value, SEQ_CONSISTENT);
        default: $$unreachable();
    }
}

macro Type Atomic.add(&self, Type value, AtomicOrdering ordering = SEQ_CONSISTENT) {
    Type* data = &self.data;
    return @atomic_exec(atomic::fetch_add, data, value, ordering);
}

macro Type Atomic.sub(&self, Type value, AtomicOrdering ordering = SEQ_CONSISTENT) {
    Type* data = &self.data;
    return @atomic_exec(atomic::fetch_sub, data, value, ordering);
}

macro Type Atomic.increment(&self, AtomicOrdering ordering = SEQ_CONSISTENT) {
    Type* data = &self.data;
    return @atomic_exec(atomic::fetch_add, data, 1, ordering);
}

macro Type Atomic.decrement(&self, AtomicOrdering ordering = SEQ_CONSISTENT) {
    Type* data = &self.data;
    return @atomic_exec(atomic::fetch_sub, data, 1, ordering);
}
