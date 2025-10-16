module std::lock::spinlock;

import env;
import std::atomic;

typedef Spinlock = Atomic{uint};
const uint ACQUIRED = 1;
const uint AVAILABLE = 0;

macro spinlock_hint(ArchType $arch) @local {
    $switch $arch:
        $case ArchType.X86_64:
            asm("pause");
        $default:
            $error("Unsupported architecture");
    $endswitch
}

macro Spinlock.acquire(&self) {
    while (!self.compare_exchange(AVAILABLE, ACQUIRED, success: AtomicOrdering.ACQUIRE, failure: AtomicOrdering.RELAXED)) {
        while (self.load(ordering: AtomicOrdering.RELAXED) != AVAILABLE) {
            spinlock_hint();
        }
    }
}

macro Spinlock.release(&self) {
    self.store(AVAILABLE, ordering: AtomicOrdering.RELEASE);
}
