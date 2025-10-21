module scheduler::worker;

import scheduler @public;
import muon;
import resource;

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
        
        // destroy handles
        t.handles.lock.acquire();
        logging::debug("handle table lock acquired");

        foreach (usz idx, HandleEntry* &entry : t.handles.entries) {
            if (!entry.valid()) continue;

            // if (entry.data == t || entry.parent == t) entry.clear();

            logging::printn("Task(%d).handles[%d]: resource=%x (%s), gen=%d, salt=%d, perms=%x", t.id, idx, entry.resource, entry.type.nameof, entry.generation, entry.salt, entry.perms);
        }

        t.handles.lock.release();

        task::destroy(t)!!;

        logging::debug("handle table lock released");
        scheduler::unlock_scheduler();
        logging::debug("scheduler lock releasing");
    }
}
