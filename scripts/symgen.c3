module symgen;

import std::io;
import std::io::file;
import std::collections::list;

// Magic number identical to the one read by Muon
const ulong KERNEL_SYM_MAGIC = 0x4D554F4E5F53594D; // "MUON_SYM"

// Standard ELF64 constants
const uint SHT_SYMTAB = 2;
const uint SHT_STRTAB = 3;
const char STT_FUNC   = 2;

// Standard ELF64 structures
struct Elf64Header {
	char[16] ident;
	ushort type;
	ushort machine;
	uint version;
	ulong entry;
	ulong phoff;
	ulong shoff;
	uint flags;
	ushort ehsize;
	ushort phentsize;
	ushort phnum;
	ushort shentsize;
	ushort shnum;
	ushort shstrndx;
}

struct Elf64SectionHeader {
	uint name;
	uint type;
	ulong flags;
	ulong addr;
	ulong offset;
	ulong size;
	uint link;
	uint info;
	ulong addralign;
	ulong entsize;
}

struct Elf64Symbol {
	uint name;
	char info;
	char other;
	ushort shndx;
	ulong value;
	ulong size;
}

// Output structures passed to Muon
struct KernelSymbol {
	ulong startAddress; // Function start address (STT_FUNC)
	uint size; // Function size in bytes
	uint nameOffset; // Offset within the string table
}

struct KernelSymbolHeader {
	ulong magic;
	uint numSymbols;
	uint strtabSize;
	KernelSymbol[*] symbols;
}

fn int main(String[] args) {
	if (args.len < 3) {
		io::printn("Usage: symgen <kernel.elf> <kernel.sym>");
		return 1;
	}

	// 1. Load the ELF binary entirely into memory
	char[]? elfDataRes = file::load_temp(args[1]);
	if (catch err = elfDataRes)	{
		io::printfn("Error: Failed to read file '%s' (%s).", args[1], err);
		return 1;
	}
	char[] elfData = elfDataRes;

	if (elfData.len < Elf64Header::size)	{
		io::printn("Error: File size too small for ELF header.");
		return 1;
	}

	Elf64Header* ehdr = (Elf64Header*)elfData.ptr;

	if (ehdr.ident[0] != 0x7F || ehdr.ident[1] != 'E' || ehdr.ident[2] != 'L' || ehdr.ident[3] != 'F'
		|| ehdr.ident[4] != 2) {
		io::printn("Error: The file is not a valid 64-bit ELF binary.");
		return 1;
	}

	if (ehdr.shoff == 0 || ehdr.shnum == 0 || ehdr.shoff + (ulong)ehdr.shnum * Elf64SectionHeader::size > (ulong)elfData.len) {
		io::printn("Error: ELF section header table missing or corrupted.");
		return 1;
	}

	Elf64SectionHeader* shdrTable = (Elf64SectionHeader*)(elfData.ptr + ehdr.shoff);

	Elf64SectionHeader* symtabHdr = null;
	Elf64SectionHeader* strtabHdr = null;

	// 2. Locate .symtab and .strtab sections in the ELF
	for (ushort i = 0; i < ehdr.shnum; i++) {
		if (shdrTable[i].type == SHT_SYMTAB) {
			symtabHdr = &shdrTable[i];
			// The .strtab section associated with .symtab is indicated by the e_link field
			if (symtabHdr.link < ehdr.shnum) {
				strtabHdr = &shdrTable[symtabHdr.link];
			}
			break;
		}
	}

	if (symtabHdr == null || strtabHdr == null)	{
		io::printn("Error: Unable to find .symtab or .strtab section in ELF.");
		return 1;
	}

	if (symtabHdr.offset + symtabHdr.size > (ulong)elfData.len
		|| strtabHdr.offset + strtabHdr.size > (ulong)elfData.len) {
		io::printn("Error: .symtab or .strtab section out of file bounds.");
		return 1;
	}

	Elf64Symbol* syms = (Elf64Symbol*)(elfData.ptr + symtabHdr.offset);
	char* rawStrtab = (char*)(elfData.ptr + strtabHdr.offset);
	usz numElfSyms  = symtabHdr.size / Elf64Symbol::size;

	List{KernelSymbol} extractedSymbols;
	extractedSymbols.init(mem);
	defer extractedSymbols.free();

	List{char} outputStrtab;
	outputStrtab.init(mem);
	defer outputStrtab.free();

	// 3. Scan and filter (Function symbols only: STT_FUNC)
	for (usz i = 0; i < numElfSyms; i++) {
		char symType = syms[i].info & 0x0F;

		// Filter only function symbols with a valid address
		if (symType == STT_FUNC && syms[i].value != 0 && syms[i].name != 0)	{
			if (syms[i].name >= strtabHdr.size) continue;

			char* namePtr = rawStrtab + syms[i].name;
			sz nameLen    = ((ZString)namePtr).len();
			if (nameLen == 0) continue;

			// Append the string to the output buffer
			uint nameOffset = (uint)outputStrtab.len();
			for (sz j = 0; j <= nameLen; j++) {
				outputStrtab.push(namePtr[j]); // Include the null terminator '\0'
			}

			KernelSymbol ksym = { .startAddress = syms[i].value, .size = (uint)syms[i].size, .nameOffset = nameOffset };

			extractedSymbols.push(ksym);
		}
	}

	// 4. Sort symbols array by startAddress (for binary search in Muon)
	for (sz i = 0; i < extractedSymbols.len(); i++)	{
		for (sz j = i + 1; j < extractedSymbols.len(); j++)	{
			if (extractedSymbols[i].startAddress > extractedSymbols[j].startAddress) {
				KernelSymbol temp = extractedSymbols[i];
				extractedSymbols[i] = extractedSymbols[j];
				extractedSymbols[j] = temp;
			}
		}
	}

	// 5. Build the final binary file
	KernelSymbolHeader header = {
		.magic = KERNEL_SYM_MAGIC,
		.numSymbols = (uint)extractedSymbols.len(),
		.strtabSize = (uint)outputStrtab.len()
	};

	File? outFileRes = file::open(args[2], "wb");
	if (catch err = outFileRes)	{
		io::printfn("Error: Failed to create output file '%s' (%s).", args[2], err);
		return 1;
	}
	File outFile = outFileRes;
	defer (void)outFile.close();

	if (catch err = outFile.write(((char*)&header)[:KernelSymbolHeader::size])) {
		io::printfn("Error writing header: %s", err);
		return 1;
	}
	if (extractedSymbols.len() > 0)	{
		if (catch err = outFile.write(((char*)extractedSymbols.entries)[:extractedSymbols.len() * KernelSymbol::size])) {
			io::printfn("Error writing symbols: %s", err);
			return 1;
		}
	}
	if (outputStrtab.len() > 0) {
		if (catch err = outFile.write(outputStrtab.array_view())) {
			io::printfn("Error writing string table: %s", err);
			return 1;
		}
	}

	io::printfn("Successfully extracted %d symbols.", extractedSymbols.len());
	return 0;
}
