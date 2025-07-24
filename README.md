<p align="center">
  <img src="https://i.imgur.com/bxSeMca.png" height=224/>
  </br>
  A minimal, capability-based, <b>x86-64 kernel</b> with <b>UEFI bootloader</b>, OOP-like structure in C, pre-emptive multitasking and soon-to-come modern features. Also an open-source educational and study project.
</p>

# Core Features
1. **Boson** – UEFI bootloader
   - Loads and parses ELF kernel binaries
   - Initializes PML4 page tables and long-mode environment

2. **Lepton** – Pure-C OOP framework
   - Simulated classes, interfaces, and exceptions with minimal overhead
   - Organized kernel modules with structured dispatch and lifecycle
   - Java-like syntax with class and interfaces inheritance

3. **Muon** – Minimal and modern kernel
   - Capability-based security and resource sharing via handles and IDs
   - Pre-emptive round-robin scheduler via timer IRQs
   - Modern set of syscalls

# Milestones
- [x] 🚀 **Milestone 0** – Bootloader
   - [x] Boson UEFI loader and ELF loading
   - [x] Setup kernel page tables (identity + higher-half mapping)
   - [x] Setup kernel stack and call C entry point
- [ ] 🏗️ **Milestone 0.1** – Foundations
   - [x] UART serial logging driver (output)
   - [ ] Global Descriptor Table
   - [ ] Interrupt Descriptor Table
   - [ ] Exception handlers (page fault, GPF, etc.)
   - [ ] HPET timer driver for preemptive IRQ
   - [ ] UART serial interrupt-based driver (input)
- [ ] 📗 **Milestone 0.2** – Memory Management
   - [ ] Physical frame allocator (bitmap slab allocator)
   - [ ] Virtual memory mapping (paging interface)
   - [ ] Kernel heap allocator (buddy allocator)
- [ ] 🐎 **Milestone 0.3** – Kernel mode scheduler
   - [ ] Task/Thread structure with context and stack
   - [ ] Cooperative `yield()` function 
   - [ ] Preemptive switch via timer interrupt
   - [ ] Basic shell to launch programs
