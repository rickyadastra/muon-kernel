module arch;

import dev::serial;

macro void @log(#log, #msg) @private {
    if (#log != null) #log.write(#msg);
}

fn void init(Serial* log = null) {
    gdt::setup();
    @log(log, "GDT install complete\n");

    gdt::install();
    @log(log, "GDT install complete\n");
}

fn void idle() {
    asm("hlt");
}
