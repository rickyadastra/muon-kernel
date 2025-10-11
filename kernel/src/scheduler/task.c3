module scheduler::task;

import arch;
import muon;
import scheduler @public;

fn void? spawn(EntryPointFn entryPoint, usz stackSize = 2) {
    if (stackSize < 1) return INIT_STACK_TOO_SMALL?;
    
    // TODO: move stack setup in TaskSpace.init
    uptr? stackBase = mem::alloc_pages(stackSize);
    if (catch stackBase) return task::INIT_STACK_FAIL?;

    Task* task = mem::alloc(Task.sizeof);

    task.id = scheduler::nextTaskId.add(1);
    task.state = READY;
    task.context.init(entryPoint, stackBase, stackBase+stackSize*mem::page_size());

    scheduler::enqueue_task(task);
}

fn void terminate() {
    muon::panic("task ended");
}

