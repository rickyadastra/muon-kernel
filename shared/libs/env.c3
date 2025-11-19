module env;

enum ArchType {
	UNKNOWN,
	ARM,          // ARM (little endian): arm, armv.*, xscale
	ARMB,         // ARM (big endian): armeb
	AARCH64,      // AArch64 (little endian): aarch64
	AARCH64_BE,   // AArch64 (big endian): aarch64_be
	AARCH64_32,   // AArch64 (little endian) ILP32: aarch64_32
	ARC,          // ARC: Synopsys ARC
	AVR,          // AVR: Atmel AVR microcontroller
	BPFEL,        // eBPF or extended BPF or 64-bit BPF (little endian)
	BPFEB,        // eBPF or extended BPF or 64-bit BPF (big endian)
	HEXAGON,      // Hexagon: hexagon
	MIPS,         // MIPS: mips, mipsallegrex, mipsr6
	MIPSEL,       // MIPSEL: mipsel, mipsallegrexe, mipsr6el
	MIPS64,       // MIPS64: mips64, mips64r6, mipsn32, mipsn32r6
	MIPS64EL,     // MIPS64EL: mips64el, mips64r6el, mipsn32el, mipsn32r6el
	MSP430,       // MSP430: msp430
	PPC,          // PPC: powerpc
	PPC64,        // PPC64: powerpc64, ppu
	PPC64LE,      // PPC64LE: powerpc64le
	R600,         // R600: AMD GPUs HD2XXX - HD6XXX
	AMDGCN,       // AMDGCN: AMD GCN GPUs
	RISCV32,      // RISC-V (32-bit): riscv32
	RISCV64,      // RISC-V (64-bit): riscv64
	SPARC,        // Sparc: sparc
	SPARCV9,      // Sparcv9: Sparcv9
	SPARCEL,      // Sparc: (endianness = little). NB: 'Sparcle' is a CPU variant
	SYSTEMZ,      // SystemZ: s390x
	TCE,          // TCE (http://tce.cs.tut.fi/): tce
	TCELE,        // TCE little endian (http://tce.cs.tut.fi/): tcele
	THUMB,        // Thumb (little endian): thumb, thumbv.*
	THUMBEB,      // Thumb (big endian): thumbeb
	X86,          // X86: i[3-9]86
	X86_64,       // X86-64: amd64, x86_64
	XCORE,        // XCore: xcore
	NVPTX,        // NVPTX: 32-bit
	NVPTX64,      // NVPTX: 64-bit
	LE32,         // le32: generic little-endian 32-bit CPU (PNaCl)
	LE64,         // le64: generic little-endian 64-bit CPU (PNaCl)
	AMDIL,        // AMDIL
	AMDIL64,      // AMDIL with 64-bit pointers
	HSAIL,        // AMD HSAIL
	HSAIL64,      // AMD HSAIL with 64-bit pointers
	SPIR,         // SPIR: standard portable IR for OpenCL 32-bit version
	SPIR64,       // SPIR: standard portable IR for OpenCL 64-bit version
	KALIMBA,      // Kalimba: generic kalimba
	SHAVE,        // SHAVE: Movidius vector VLIW processors
	LANAI,        // Lanai: Lanai 32-bit
	WASM32,       // WebAssembly with 32-bit pointers
	WASM64,       // WebAssembly with 64-bit pointers
	RSCRIPT32,    // 32-bit RenderScript
	RSCRIPT64,    // 64-bit RenderScript
	XTENSA,       // Xtensa
}

const ArchType ARCH_TYPE = ArchType.from_ordinal($$ARCH_TYPE);
const bool ARCH_32_BIT = $$REGISTER_SIZE == 32;
const bool ARCH_64_BIT = $$REGISTER_SIZE == 64;
const REGISTER_SIZE = $$REGISTER_SIZE;

const bool X86_64 = ARCH_TYPE == X86_64;
