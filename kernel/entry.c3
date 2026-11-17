import arch;
import muon, muon::boot;
import lang, env;

BootContext bootCtx @local;

fn void kstart(void* bootParam) @export("kstart") {
    lang::init_runtime();
    logging::init();

	boot::@to_boot_context(bootCtx, bootParam);
	if (bootCtx.bootloader == UNKNOWN) muon::panic("Unknown bootloader, halting");

    muon::kmain(&bootCtx);
    
    muon::panic("muon::kmain() returned");
}
