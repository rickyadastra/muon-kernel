<p align="center">
  <img src="https://i.imgur.com/7lzQi0P.png" height=224/>
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
- [ ] **Milestone 0** – Boot & Foundation 
   - [x] UEFI bootloader to kernel entry
   - [x] UEFI memory map passing to kernel
   - [ ] Kernel ports and UART driver
   - [ ] Kernel serial port driver
