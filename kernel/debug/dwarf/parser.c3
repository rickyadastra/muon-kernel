module muon::debug::dwarf;

import muon::log;

faultdef CIE_NOT_FOUND, FDE_NOT_FOUND, MULTIPLE_CIE;

macro @foreach_entry(char[] data; @body(Header* header)) @local {
	Header* h = (Header*)data.ptr;
	
	while ((uptr)h < (uptr)data.ptr + data.len) {
		// break on terminator
		if ((uptr)h > (uptr)data.ptr && h.cieId == 0) break;

		@body(h);

		h = (Header*)((uptr)h + h.length + $Typeof(h.length)::size);
	}
}

fn CieData CommonInfoEntry.parse(&entry) {
	CieData data;

	usz len;
	for (len=0; entry.augmentation[len]!='\0'; len++);
	String aug = data.aug = (String)entry.augmentation[:len];

	data.codeAlignFactor = (char)read_uleb128(&&(char*)((uptr)entry + CommonInfoEntry::size + aug.len + 1));
	data.dataAlignFactor = (ichar)read_sleb128(&&(char*)((uptr)entry + CommonInfoEntry::size + aug.len + 2));
	data.returnAddrReg = (RegId)read_uleb128(&&(char*)((uptr)entry + CommonInfoEntry::size + aug.len + 3));
	data.augData = (((ushort)*(char*)((uptr)entry + CommonInfoEntry::size + aug.len + 4)) << 8) |
		*(char*)((uptr)entry + CommonInfoEntry::size + aug.len + 5);

	char* instrPtr = (char*)((uptr)entry + CommonInfoEntry::size + aug.len + 6);
	usz instrLen = entry.length - (usz)(instrPtr - (char*)entry) + 4;
	data.instructions = instrPtr[:instrLen];

	return data;
}

fn CieData? find_cie(char[] data) {
	CieData cieData;
	bool found = false;

	@foreach_entry(data; h) {
		if (h.cieId == 0) {
			if (!found) {
				cieData = ((Cie*)h).parse();
				found = true;
			} else {
				return MULTIPLE_CIE~;
			}
		}
	};

	if (!found) return CIE_NOT_FOUND~;
	return cieData;
}

fn void validate_cie(CieData cieData) {
	assert(cieData.codeAlignFactor == EXPECTED_CODE_ALIGN);
	assert(cieData.dataAlignFactor == EXPECTED_DATA_ALIGN);
	assert(cieData.returnAddrReg == EXPECTED_RETURN_ADDR);
	assert(cieData.aug == EXPECTED_AUGS);
	assert(cieData.augData == EXPECTED_AUG_DATA);
}

fn FdeData FrameDescriptionEntry.parse(&entry) {
	FdeData data;

	data.initialLocation = (uptr)&entry.initialLocation + (ulong)(int)entry.initialLocation;
	data.locationRange = (usz)entry.addrRange;

	char* instrPtr = (char*)((uptr)entry + FrameDescriptionEntry::size);
	usz instrLen = entry.length - (usz)(instrPtr - (char*)entry) + 4;
	data.instructions = instrPtr[:instrLen];

	return data;
}

fn FdeData? find_fde(char[] data, uptr pc) {
	FdeData fdeData;

	@foreach_entry(data; h) {
		if (h.cieId != 0) {
			FdeData fde = ((Fde*)h).parse();
			if (pc >= fde.initialLocation && pc < fde.initialLocation + fde.locationRange) {
				return fde;
			}
		}
	};

	return FDE_NOT_FOUND~;
}
