module process::worker;

import process @public;
import muon;
import dev::timing;
import arch::mem;

fn void terminated_tasks_cleanup() {
    while (true) {
        scheduler::lock_scheduler();
        log::debug("scheduler lock acquired");

        if (scheduler::cleanupQueue.is_empty()) {
            log::debug("cleanup queue is empty, releasing lock");
            scheduler::unlock_scheduler();
            log::debug("lock released, going to sleep");
            process::suspend()!!;
            log::debug("back from sleep");
            continue;
        }

        Task* t = scheduler::cleanupQueue.remove_at(0)!!;
        assert(t.get_ref_count() == 0);

        // cancel event and free its context
        clear_pending_event(t);

        // unregister object and cleanup resources
    	scheduler::drop_task(t);
        object::unregister(t)!!;
        task::destroy(t)!!;

        log::debug("handle table lock released");
        scheduler::unlock_scheduler();
        log::debug("scheduler lock releasing");
    }
}

fn void clear_pending_event(Task* task) @private {
    if (task.pendingEvent != null) {
        log::debug("clearing event pending on task #%d", task.id);
        mem::free(task.pendingEvent.context);
        task.pendingEvent.cancel();
    }
}
