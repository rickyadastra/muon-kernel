import arch;
import muon, muon::boot;
import lang, env;

BootContext bootCtx @local;

fn void kstart(void* bootParam) @export("kstart") {
    lang::init_runtime();

	boot::@to_boot_context(bootCtx, bootParam);

    muon::kmain(&bootCtx);
    
    muon::panic("muon::kmain() returned");
}
