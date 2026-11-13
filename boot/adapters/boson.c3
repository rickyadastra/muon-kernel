module muon::boot @feat(BOOT_BOSON); 
import boson::protocol;

const BibRevision BIB_REVISION = { 1, 0 };

macro void? @from_boson_bib(BootContext #bootCtx, void* #bootParam) @feat(BOOT_BOSON) {
	BootInfoBlock* bib = ((BootInfoBlock*)#bootParam);
	if (bib.magic != protocol::MAGIC) return INVALID_BOOTLOADER~;
	if (bib.revision.major > BIB_REVISION.major) return INVALID_BOOTLOADER~;
	
	#bootCtx = { .bootloader = BOSON };

	bib.@foreach_tag(; i, tag) {
		switch (tag.id) {
			case RSDP: 
				#bootCtx.rsdpAddr = (uptr)((TagRsdp*)tag).rsdp;
			case STACK: 
				TagStack* stack = (TagStack*)tag;
				#bootCtx.stack.base = stack.base;
				#bootCtx.stack.size = stack.size;
			case MEMORY_MAP: 
				TagMemoryMap* memoryMap = (TagMemoryMap*)tag;
				#bootCtx.memory.totalBytes = memoryMap.totalBytes;
				#bootCtx.memory.mapRegionsCount = memoryMap.numOfEntries;
				
				foreach (usz j, MemoryEntry me : memoryMap.entries[:memoryMap.numOfEntries]) {
					#bootCtx.memory.mapRegions[j] = {
						.type = MemoryRegionType::from_ordinal(me.type.ordinal),
						.base = me.base,
						.baseVirt = me.baseVirt,
						.size = me.length,
					};
				}
		}
	};
}
