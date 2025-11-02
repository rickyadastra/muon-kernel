module scheduler::worker;

import scheduler @public;
import muon;
import resource;
import dev::timing;
import arch::mem;

fn void terminated_tasks_cleanup() {
    while (true) {
        scheduler::lock_scheduler();
        logging::debug("scheduler lock acquired");

        if (scheduler::terminatedQueue.is_empty()) {
            logging::debug("terminated queue is empty, releasing lock");
            scheduler::unlock_scheduler();
            logging::debug("lock released, going to sleep");
            task::suspend()!!;
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

        // cancel event and free its context
        clear_pending_event(t);

        task::destroy(t)!!;

        logging::debug("handle table lock released");
        scheduler::unlock_scheduler();
        logging::debug("scheduler lock releasing");
    }
}

fn void clear_pending_event(Task* task) @private {
    if (task.pendingEvent != null) {
        logging::printn("clearing event pending on task #%d", task.id);
        mem::free(task.pendingEvent.context);
        task.pendingEvent.cancel();
    }
}
