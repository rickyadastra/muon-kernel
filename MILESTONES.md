# Milestones
This sections collects all completed milestones with their tasks and descriptions.

### 🚀 Milestone 0 – Bootloader
- Boson UEFI loader and ELF loading
- Setup kernel page tables (identity + higher-half mapping)
- Setup kernel stack and call C entry point
### 🏗️ Milestone 0.1 – Foundations
- UART serial logging driver (output)
- Global Descriptor Table
- Interrupt Descriptor Table
- Exception handlers (page fault, GPF, etc.)
### 📗 Milestone 0.2 – Memory Management
- Physical frame allocator (bitmap allocator)
- Virtual memory mapping (paging interface)
- Kernel heap allocator (buddy allocator)
- Page Fault verbose handler
### 🕹️ Milestone 0.3 – Interrupts and Timing
- Interrupt Routing (PIC disable, local APIC configuration)
- IOAPIC configuration (VMM mapping and MMIO setup)
- UART serial interrupt-based driver (input)
- HPET timer for LAPIC timer calibration
- Local APIC timer for event scheduling
### 🐎 Milestone 0.4 – Kernel mode scheduler (cooperative round-robin)
- Task/Thread structure with context and stack
- Preemptive context switch via timer interrupt
- FPU context save and restore
- Process functions `create()`, `start()` and `terminate()`/`exit()`
- Cooperative task `yield()` function
- `sleep_ms()` and `suspend()`/`resume()` functions
- `wait()` and `detach()` functions
- Synchronization primitives via Semaphore object
- **Basic shell to launch programs**
