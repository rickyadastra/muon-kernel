module muon::debug::dwarf;

import muon::debug @public;

faultdef CIE_NOT_FOUND, FDE_NOT_FOUND;

struct CieData {
	char codeAlignFactor;
	ichar dataAlignFactor;
	RegId returnAddrReg;
	String aug;
	ushort augData;
	char* instructions;
	usz instructionsLen; 
}

struct FdeData {
	uptr initialLocation;
	usz locationRange;
	char* instructions;
	usz instructionsLen;
}

macro bool Header.is_cie(self) => self.cieId == 0; 

fn CieData CommonInfoEntry.parse(&entry) {
	CieData data;

	usz len;
	for (len=0; entry.augmentation[len]!='\0'; len++);
	String aug = data.aug = (String)entry.augmentation[:len];

	data.codeAlignFactor = (char)decode_uleb128(&&(char*)((uptr)entry + CommonInfoEntry.sizeof + aug.len + 1));
	data.dataAlignFactor = (ichar)decode_sleb128(&&(char*)((uptr)entry + CommonInfoEntry.sizeof + aug.len + 2));
	data.returnAddrReg = (RegId)decode_uleb128(&&(char*)((uptr)entry + CommonInfoEntry.sizeof + aug.len + 3));
	data.augData = (((ushort)*(char*)((uptr)entry + CommonInfoEntry.sizeof + aug.len + 4)) << 8) |
		*(char*)((uptr)entry + CommonInfoEntry.sizeof + aug.len + 5);
	data.instructions = (char*)((uptr)entry + CommonInfoEntry.sizeof + aug.len + 6);
	data.instructionsLen = entry.length - (data.instructions-(char*)entry) + 4;

	return data;
}

fn FdeData FrameDescriptionEntry.parse(&entry) {
	FdeData data;
	
	data.initialLocation = (uptr)&entry.initialLocation + (int)entry.initialLocation;
	data.locationRange = (usz)entry.addrRange;
	data.instructions = (char*)((uptr)entry + FrameDescriptionEntry.sizeof);
	data.instructionsLen = entry.length - (data.instructions-(char*)entry) + 4;

	return data;
}

macro @next_entry(Header* #hdr) => #hdr = (Header*)((uptr)#hdr + #hdr.length + Header.length.sizeof);

fn CieData? find_cie() {
	Header* hdr = (Header*)debug::tableAddr;

	for (usz i=0; (uptr)hdr < debug::tableAddr + debug::tableSize; i++) {
		if (hdr.is_cie()) {
			CommonInfoEntry* entry = (CommonInfoEntry*)hdr;
			CieData data = entry.parse();

			assert(data.codeAlignFactor == CODE_ALIGN);
			assert(data.dataAlignFactor == DATA_ALIGN);
			assert(data.returnAddrReg == RETURN_ADDR);
			assert(data.aug == AUGS);
			assert(data.augData == AUG_DATA);

			return data;
		}

		@next_entry(hdr);
	}

	return CIE_NOT_FOUND?;
}

fn FdeData? find_fde(uptr ip) {
	Header* hdr = (Header*)debug::tableAddr;

	for (usz i=0; (uptr)hdr < debug::tableAddr + debug::tableSize; i++) {
		if (!hdr.is_cie()) {
			FrameDescriptionEntry* entry = (FrameDescriptionEntry*)hdr;
			FdeData data = entry.parse();

			if (ip >= data.initialLocation 
					&& ip < data.initialLocation + data.locationRange) {
				return data;
			}
		}

		@next_entry(hdr);
	}

	return FDE_NOT_FOUND?;
}
