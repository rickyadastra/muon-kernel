module arch::mem;

import muon::logging;
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

    logging::print("Page fault at address %x. ", cpu::read_cr2());
    logging::printn("Tried to %s a %s page in %s mode.", action, presence, privilege);

    interrupts::@print_stack(stack, intr);
    arch::panic();

    return stack;
}
