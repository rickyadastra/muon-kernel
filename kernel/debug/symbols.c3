module muon::debug;

import std::core::string;

import muon::log, muon::boot;
import mem;

faultdef SYMBOLS_UNAVAILABLE, SYMBOL_NOT_FOUND;

const ulong KERNEL_SYM_MAGIC = 0x4D554F4E5F53594D; // "MUON_SYM"

struct KernelSymbol {
	ulong startAddress;
	uint size;
	uint nameOffset;
}

struct KernelSymbolTable {
	ulong magic;
	uint numSymbols;
	uint strtabSize;
	KernelSymbol[*] symbols;
}

macro KernelSymbol[] KernelSymbolTable.get_symbols(&self) => self.symbols[:self.numSymbols];
macro char[] KernelSymbolTable.get_strtab(&self) => ((char*)self + KernelSymbolTable::size + self.numSymbols*KernelSymbol::size)[:self.strtabSize];

struct SymbolResult {
	String name;
	ulong offset;
}

KernelSymbolTable* symbolTable @local;

fn void load_symbols(ModulesBootContext modulesCtx) {
	foreach (Module* &mod : modulesCtx.get_modules()) {
		uptr data = vmm::@phys(mod.address);

		if (mod.get_name() == "muon.sym" && *((ulong*)data) == KERNEL_SYM_MAGIC) {
			symbolTable = (KernelSymbolTable*)data;
			log::debug("Symbol table module found and loaded @ %x (%d symbols)", data, symbolTable.numSymbols);
			break;
		}
	}

	if (symbolTable == null) {
		log::warn("Symbol table could not be found, symbolication won't be available");
		return;
	}
}

fn KernelSymbol? find_symbol(uptr pc) @private {
	if (symbolTable == null) return SYMBOLS_UNAVAILABLE~;

	KernelSymbol[] syms = symbolTable.get_symbols();
	
	sz min = 0;
	sz max = symbolTable.numSymbols-1l;

	// todo: extract binary search to std::sort
	
	while (min <= max && min >= 0 && max < symbolTable.numSymbols) {
		sz mid = min + ((max - min) / 2);
		KernelSymbol candidate = syms[mid];

		if (pc < candidate.startAddress) {
			if (mid == 0) break;
			max = mid - 1;
		} else if (pc >= candidate.startAddress + candidate.size) {
			min = mid + 1;
		} else {
			return candidate;
		}
	}

	return SYMBOL_NOT_FOUND~;
}

fn SymbolResult? resolve_symbol(uptr pc) {
	if (symbolTable == null) return SYMBOLS_UNAVAILABLE~;

	char[] strtab = symbolTable.get_strtab();
	KernelSymbol sym = find_symbol(pc)!;

	// return default name if not found
	ZString s = (ZString)(strtab.ptr + sym.nameOffset);

	return { 
		.name = s.str_view(), 
		.offset = pc - sym.startAddress
	};
}
