module scheduler::task;

import muon;

fn void TaskContext.save(&self, CpuContext* context) @dynamic {
    logging::printn("saving context: %x", context);
    self.cpuContext = context;
}

fn void TaskContext.load(&self, CpuContext* context) @dynamic {
    logging::printn("loading context: %x", context);
    *context = *self.cpuContext;
}
