module arch::interrupts;

fn InterruptStack* exception_handler(InterruptStack* stack) @private {
    return stack;
}

fn InterruptStack* interrupt_handler(InterruptStack* stack) @private {
    return stack;
}

