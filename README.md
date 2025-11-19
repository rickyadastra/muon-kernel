<p align="center">
  <img src="https://i.imgur.com/bxSeMca.png" height=224/>
  <br><br>
  A minimalist, capability-based, <b>C3 x86-64 kernel</b> with a <b>C UEFI bootloader</b>, pre-emptive multitasking and soon-to-come modern features. Also an open-source personal and academic project.
  <br><br>
  <a href="https://c3-lang.org/"><img alt="Language C3" src="https://img.shields.io/badge/Language-C3-3381ff"></a>
  <a href="https://github.com/boyter/scc"><img alt="Total lines" src="https://sloc.xyz/github/rickyadastra/muon-kernel"/></a>
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
The full milestone breakdown is available [here](MILESTONES.md).

- [x] 🚀 **Milestone 0** – Bootloader
- [x] 🏗️ **Milestone 0.1** – Foundations
- [x] 📗 **Milestone 0.2** – Memory Management
- [x] 🕹️ **Milestone 0.3** – Interrupts and Timing
- [x] 🐎 **Milestone 0.4** – Kernel mode scheduler (cooperative round-robin)
   - [x] Task/Thread structure with context and stack
   - [x] Preemptive context switch via timer interrupt
   - [x] FPU context save and restore
   - [x] Process functions `create()`, `start()` and `terminate()`/`exit()`
   - [x] Cooperative task `yield()` function
   - [x] `sleep_ms()` and `suspend()`/`resume()` functions
   - [x] `wait()` and `detach()` functions
   - [x] Synchronization primitives via Semaphore object
   - [x] **Basic shell to launch programs**
- [ ] 👥 **Milestone 0.5** - Userspace
   - *TBD*
- [ ] 🔐 **Milestone 0.6** - Capability System
   - [x] `Handle` and `ObjectTable` implementations
   - [ ] Per-Task private capability space
   - [ ] Kernel-wide capability implementation
   - *More TBD*
- [ ] 📁 **Milestone 0.7** - File System basics
   - *TBD*

# Milestone 0.4 Highlights
[Milestone 0.4 - muon kernel shell](https://github.com/user-attachments/assets/808684f5-9305-41c7-af35-20fffe0cb870)

The video above shows muon kernel shell (mush) running on serial port COM3 on QEMU. The port is linked to PTY and available for minicom (or any other terminal emulator) on `/dev/pts/X` where X is chosen by QEMU based on available pseudo-terminal endpoints. 

The shell itself is an independent process and recognizes many commands such as `clear`, `help`, `time`, `sleep` and more as shown in the `help` command output. Most notable commands are: 
- `time` that demonstrates the internal wallclock being updated every second
- `rand` that generates a [hardware-backed random number](https://en.wikipedia.org/wiki/Hardware_random_number_generator) via the `rdrand` instruction
- `spawner` that creates up to 4 child processes that prints "Hello world" to the terminal output

After the shell starts a program (one of `sleep`, `spawner` or `time`) it waits for the new task to terminate and return before resuming execution, ensuring no time slices are assigned to it.

> [!NOTE]
> While the shell is supposed to shutdown VirtualBox, it is not yet fully compatible with the kernel.

You can explore the shell code [here](https://github.com/rickyadastra/muon-kernel/tree/demo/kernel-shell/kernel/src/demo).


# Why C3?
[C3](https://c3-lang.org/) is a C evolution aiming to be safer and more powerful while being familiar to the old C. It provides several additions useful to kernel programming like more granular bitstructs, methods, semantic macros and zero-overhead error checks, being fully compatible with the C ABI.

A quick overview of the main differences from C development:
- **no `include/` dir and header `.h` files** – files are logically grouped in modules; to keep source code tidy, module interface and implementation are split in `*.c3i` and `*.c3` files respectively
- **clearer functions** – thanks to the module system, each function can be called via its module name using `module::function` thus having a code that is simpler to read. New and existing types can have methods when they represent a mutable object
- **semantic macros** – enable powerful meta-programming stuff like [defining a list of lambdas for IRQs](/kernel/src/arch/x86_64/interrupts/routines.c3#L98:L109) at compile time
- **runtime types and reflection** – possibility to access types, enum and qualified method names, and much more
