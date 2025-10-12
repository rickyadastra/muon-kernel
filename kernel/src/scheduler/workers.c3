module scheduler::worker;

import scheduler @public;

fn void terminated_tasks_cleanup() {
    while (true) {
        scheduler::lock_scheduler();

        if (scheduler::terminatedQueue.is_empty()) {
            scheduler::unlock_scheduler();
            task::sleep();
            continue;
        }

        Task* t = scheduler::terminatedQueue.remove_at(0)!!;
        usz id = t.id;
        task::destroy(t)!!;

        scheduler::unlock_scheduler();
    }
}
