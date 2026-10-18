<p align="center">
  <img src="assets/logo.png" height=180/>
  <br>
  A capability-based <b>C3 x86-64 microkernel</b>; an open-source personal and academic project.
  <br><br>
  <a href="https://c3-lang.org/"><img alt="Language C3" src="https://img.shields.io/badge/Language-C3-3381ff"></a>
  <a href="https://github.com/boyter/scc"><img alt="Total lines" src="https://sloc.xyz/github/rickyadastra/muon-kernel"/></a>
  <a href="#milestones"><img alt="Language C3" src="https://img.shields.io/badge/Current_Milestone-0.4-white"></a>
</p>

## Features
- Physical and virtual memory manager via modern optimizations 
- Timer interrupt handling for kernel-wide event system
- Capability-based security model via opaque handles
- Pre-emptive round-robin scheduler with cooperation

## Getting Started
### Requirements
On Ubuntu 24.04, install [`c3c`](https://c3-lang.org/getting-started/prebuilt-binaries/#installing-on-ubuntu) by following the official guide, and the tools required to build and run the image using the folllowing command:
```sh
sudo apt install mtools qemu-systems-x86 ovmf
```
To run QEMU with KVM acceleration, enable KVM and ensure your user has access to `/dev/kvm`. If you're using WSL2, follow this [KVM setup guide](https://serverfault.com/a/1115773).

### Prepare the Bootloader
- **Boson Bootloader**: make sure you have cloned the Boson Bootloader submodule ([`boot/boson`](boot/boson)) and you have installed all the required dependencies. 

*Other bootloaders are not supported at the moment.*

### Compile and Run
The compilation pass is executed by C3's project system.
The Makefile orchestrates version checks, directory guards and ordered compilation of the bootloader and the kernel binaries. 
The following commands are available:

```sh
make [all]     # build bootloader and kernel binaries
make boson     # build bootloader binary, .build/boson/boson.efi
make muon      # build kernel binary, .build/muon/muon.elf
make image     # create .build/fat.img then copy bootloader and kernel binaries
make run       # create the image and run it in QEMU with OVMF
make debug     # create and run the image, opening GDB for debugging
```
To clear the build directory and rebuild all artifacts from scratch, run:
```sh
make clear
```

## Milestones
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

### Milestone 0.4 Highlights
[Milestone 0.4 - muon kernel shell](https://github.com/user-attachments/assets/808684f5-9305-41c7-af35-20fffe0cb870)

The video above shows muon kernel shell (mush) running on serial port COM3 on QEMU. The port is linked to PTY and available for minicom (or any other terminal emulator) on `/dev/pts/X` where X is chosen by QEMU based on available pseudo-terminal endpoints. 

The shell itself is an independent process and recognizes many commands such as `clear`, `help`, `time`, `sleep` and more as shown in the `help` command output. Most notable commands are: 
- `time` that demonstrates the internal wallclock being updated every second
- `rand` that generates a [hardware-backed random number](https://en.wikipedia.org/wiki/Hardware_random_number_generator) via the `rdrand` instruction
- `spawner` that creates up to 4 child processes that prints "Hello world" to the terminal output

After the shell starts a program (one of `sleep`, `spawner` or `time`) it waits for the new task to terminate and return before resuming execution, ensuring no time slices are assigned to it.

> [!NOTE]
> As for now, the shell can only shutdown QEMU and VirtualBox.

You can explore the shell code [here](https://github.com/rickyadastra/muon-kernel/tree/demo/kernel-shell/kernel/src/demo).

## Project Structure
| Path | Contents |
| ---- | -------- |
| `kernel/` | Architecture-agnostic kernel sources |
| `kernel/arch` | Architecture-dependent kernel sources |
| `shared/libs` | C3 libraries for kernel-wide definitons and utility macros |
| `scripts/` | Build and linker scripts |
| `.build/` | Build-time folder containing binaries and FAT image |

## Development
> [!WARNING]
> Muon is currently under active development and, as such, its interfaces and features may change or be removed without notice. It is **NOT** intended for daily use and probably won't be for a *very* long time.

Build settings are defined in the [`project.json`](project.json) configuration file.
The [`Makefile`](Makefile) provides targets for creating individual binaries, the image and running or debugging it in QEMU.
The default OVMF path is `/usr/share/ovmf/OVMF.fd`.

## Why C3?
The choice of [C3](https://c3-lang.org/) over more established and widely used languages, stems from a personal desire to try something new that is, at the same time, modern and effective.
C3 is a C evolution aiming to be safer, more powerful and ergonomic while keeping the familiarity and hardware control of C. 
It provides several useful additions for kernel programming, such as granular bitstructs, methods, semantic macros and zero-overhead error checks, all while being fully compatible with the C ABI.

Some of the most notable differences with C are: 
- the **absence of header files**, since now all of the source code is logically grouped in modules; to keep source code tidy, module interface and implementation are split in `*.c3i` and `*.c3` files respectively
- an **improved types system** allowing the definition of new, distinct types, structures and enums with associated values, along C-style type aliases and constant enums; it also allows compile-time and runtime **type reflection**
- new **semantic macros** that enable powerful meta-programming tricks like [defining a list of lambda functions for IRQs](/kernel/arch/x86_64/interrupts/routines.c3#L98:L109) at compile time
