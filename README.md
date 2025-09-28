<p align="center">
  <img src="https://i.imgur.com/bxSeMca.png" height=224/>
  </br>
  A minimalist, capability-based, <b>C3 x86-64 kernel</b> with a <b>C UEFI bootloader</b>, pre-emptive multitasking and soon-to-come modern features. Also an open-source personal and academic project. 
</p>

# Core Features
1. **Boson** – UEFI bootloader
   - Loads and parses ELF kernel binaries
   - Initializes PML4 page tables and long-mode environment

2. **Lepton** – Pure-C OOP framework (bootloader only)
   - Simulated classes, interfaces, and exceptions with minimal overhead
   - Organized kernel modules with structured dispatch and lifecycle
   - Java-like syntax with class and interfaces inheritance

3. **Muon** – Minimal and modern kernel written in C3
   - Capability-based security and resource sharing via handles and IDs
   - Pre-emptive round-robin scheduler via timer IRQs
   - Modern set of syscalls

# Milestones
- [x] 🚀 **Milestone 0** – Bootloader
   - [x] Boson UEFI loader and ELF loading
   - [x] Setup kernel page tables (identity + higher-half mapping)
   - [x] Setup kernel stack and call C entry point
- [x] 🏗️ **Milestone 0.1** – Foundations
   - [x] UART serial logging driver (output)
   - [x] Global Descriptor Table
   - [x] Interrupt Descriptor Table
   - [x] Exception handlers (page fault, GPF, etc.)
- [x] 📗 **Milestone 0.2** – Memory Management
   - [x] Physical frame allocator (bitmap allocator)
   - [x] Virtual memory mapping (paging interface)
   - [x] Kernel heap allocator (buddy allocator)
   - [x] Page Fault verbose handler
- [ ] 🕹️ **Milestone 0.3** – Interrupts and Timing
   - [x] Interrupt Routing (PIC disable, local APIC configuration)
   - [x] IOAPIC configuration (VMM mapping and MMIO setup)
   - [x] UART serial interrupt-based driver (input)
   - [ ] Local APIC timer for scheduler preemption 
   - [ ] HPET timer for `sleep()` and LAPIC timer calibration
- [ ] 🐎 **Milestone 0.4** – Kernel mode scheduler
   - [ ] Task/Thread structure with context and stack
   - [ ] Cooperative `yield()` function 
   - [ ] Preemptive switch via timer interrupt
   - [ ] Basic shell to launch programs

## Why C3?
[C3](https://c3-lang.org/) is a C evolution aiming to be safer and more powerful while being familiar to the old C. It provides several additions useful to kernel programming like more granular bitstructs, methods, semantic macros and zero-overhead error checks, being fully compatible with the C ABI.

A quick overview of the main differences from C development:
- **no `include/` dir and header `.h` files** – files are logically grouped in modules; to keep source code tidy, module interface and implementation are split in `*.c3i` and `*.c3` files respectively
- **clearer functions** – thanks to the module system, each function can be called via its module name using `module::function` thus having a code that is simpler to read. New and existing types can have methods when they represent a mutable object
- **semantic macros** – enable powerful meta-programming stuff like [defining a list of lambdas for IRQs](/kernel/src/arch/x86_64/interrupts/routines.c3#L98:L109) at compile time
- **runtime types and reflection** – possibility to access types, enum and qualified method names, and much more
