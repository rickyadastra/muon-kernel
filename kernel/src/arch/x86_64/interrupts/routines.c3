module arch::interrupts;

attrdef @IntRoutine = @noreturn, @naked;

macro pushall() @local {
    asm {
        pushq $rax;
        pushq $rbx;
        pushq $rcx;
        pushq $rdx;
        pushq $rsi;
        pushq $rdi;
        pushq $rbp;
        pushq $r8;
        pushq $r9;
        pushq $r10;
        pushq $r11;
        pushq $r12;
        pushq $r13;
        pushq $r14;
        pushq $r15;
    };
}

macro popall() @local {
    asm {
        popq $r15;
        popq $r14;
        popq $r13;
        popq $r12;
        popq $r11;
        popq $r10;
        popq $r9;
        popq $r8;
        popq $rbp;
        popq $rdi;
        popq $rsi;
        popq $rdx;
        popq $rcx;
        popq $rbx;
        popq $rax;
    };
}

alias InterruptHandler = fn void();

fn void exception_routine() @IntRoutine @private @export @extern("exception_routine") {
    asm { cld; }
    pushall();

    asm { movq $rdi, $rsp; }
    ((InterruptHandler)&exception_handler)();
    asm { movq $rsp, $rax; }

    popall();
    asm {
        addq $rsp, 24;
        iretq;
    }
}

fn void interrupt_routine() @IntRoutine @private @extern("interrupt_routine") {
    asm { cld; }
    pushall();

    asm { movq $rdi, $rsp; }
    ((InterruptHandler)&interrupt_handler)();
    asm { movq $rsp, $rax; }

    popall();
    asm {
        addq $rsp, 24;
        iretq;
    }
}

fn void idt_load() @naked {
    asm ("lidt (%rsi)");
}

macro @irq_exception(#num) @local {
    $if (#num >= KnownInterrupt.len) ||| !(KnownInterrupt.from_ordinal(#num).has_error_code):
        asm { push 0xff; }
    $endif
    
    asm { push (#num); };
    asm("jmp exception_routine");
}

macro InterruptHandler @irq($i) {
    var $_i = $i; 
    return fn () @IntRoutine { @irq_exception($i); };
}

macro InterruptHandler[*] construct_irqs($n) {
    InterruptHandler[$n] $irqs;

    $for var $i = 0; $i < $n; $i++:
        $irqs[$i] = @irq($i);
    $endfor
    
    return $irqs;
}

const usz IRQS = 48;
InterruptHandler[*] irqs @export = construct_irqs(IRQS);
