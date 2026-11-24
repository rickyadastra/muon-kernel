module arch::mem;

import muon, muon::log;
import arch::cpu;
import arch::interrupts @public;

bitstruct PageFaultErrorCode : uint {
    bool present : 0;
    bool write : 1;
    bool user : 2;
    bool reservedSet : 3;
    bool fetchOnNoExecute : 4;
    bool protectionKeyViolation : 5;
    bool shadowStackAccess : 6;
    bool sgxViolation : 15;
}

fn InterruptStack* pagefault_handler(InterruptStack* stack, KnownInterrupt intr) @private {
    PageFaultErrorCode errorCode = (PageFaultErrorCode)(uint)stack.error_code;

    String action = errorCode.write ? "write" : errorCode.fetchOnNoExecute ? "fetch an instruction from" : "read";
    String presence = errorCode.present ? "present" : "non-present";
    String privilege = errorCode.user ? "user" : "kernel";

    log::error("Page fault @ %x. Tried to %s a %s page in %s mode.", cpu::read_cr2(), action, presence, privilege);
    log::error("Program counter (RIP) was %x", stack.rip);

	muon::@panic_with_extra("fatal page fault") {
    	interrupts::@print_context(stack, intr);

		log::printp("\nBacktrace:\n");
		debug::print_backtrace_from(stack.rip, stack.rsp);
	};

    return stack;
}
