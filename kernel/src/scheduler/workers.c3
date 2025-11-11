module scheduler::worker;

import scheduler @public;
import muon;
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

        logging::printn("removing and destroying task");
        Task* t = scheduler::terminatedQueue.remove_at(0)!!;

        // cancel event and free its context
        clear_pending_event(t);

        if (t.get_ref_count() == 0) {
            object::unregister(t)!!;
            task::destroy(t)!!;
        }

        logging::debug("handle table lock released");
        scheduler::unlock_scheduler();
        logging::debug("scheduler lock releasing");
    }
}

fn void clear_pending_event(Task* task) @private {
    if (task.pendingEvent != null) {
        logging::debug("clearing event pending on task #%d", task.id);
        mem::free(task.pendingEvent.context);
        task.pendingEvent.cancel();
    }
}
