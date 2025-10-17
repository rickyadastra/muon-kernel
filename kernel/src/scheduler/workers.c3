module scheduler::worker;

import scheduler @public;
import muon;

fn void terminated_tasks_cleanup() {
    while (true) {
        scheduler::lock_scheduler();
        logging::debug("scheduler lock acquired");

        if (scheduler::terminatedQueue.is_empty()) {
            logging::debug("terminated queue is empty, releasing lock");
            scheduler::unlock_scheduler();
            logging::debug("lock released, going to sleep");
            task::sleep();
            logging::debug("back from sleep");
            continue;
        }

        logging::debug("removing and destroying task");
        Task* t = scheduler::terminatedQueue.remove_at(0)!!;
        task::destroy(t)!!;
        
        // destroy handles
        task::taskHandleTable.lock.acquire();
        logging::debug("handle table lock acquired");

        foreach (usz idx, TaskHandleEntry* &entry : task::taskHandleTable.entries) {
            if (!entry.valid) continue;

            // if (entry.data == t || entry.parent == t) entry.clear();

            logging::printn("handle[%d]: valid=%d, data=%x, parent=%x, gen=%d, salt=%d, perms=%x", idx, entry.valid, entry.data, entry.parent, entry.generation, entry.salt, entry.perms);
        }

        task::taskHandleTable.lock.release();
        logging::debug("handle table lock released");
        scheduler::unlock_scheduler();
        logging::debug("scheduler lock releasing");
    }
}
