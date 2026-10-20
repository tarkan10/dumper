# dumper

A minimalist, zero-dependency system hardware, firmware, and core metrics dumper written in pure `x86_64` Assembly for Linux. Designed for absolute performance, raw system calls, and minimal footprint without `libc`.

## Features

* **System & Kernel Identity**: Hostname and detailed kernel version information.
* **Hardware & Firmware (DMI)**: System manufacturer, product name, serial number, motherboard model, and complete BIOS details (vendor, version, date).
* **System Metrics & Topology**: Uptime, active task count, total and free RAM computation.
* **Processor Hardware Specs**: Comprehensive CPU architecture and specifications parsed directly via raw system streams.

## Requirements

* Linux (`x86_64`)
* `nasm` (Netwide Assembler)
* `ld` (GNU Linker)
* Root privileges (`sudo`) to read restricted hardware and DMI attributes.

## Compilation

Assemble and link the binary manually with zero external dependencies:

```bash
nasm -f elf64 dumper.asm -o dumper.o
ld -s dumper.o -o dumper

## Usage
'''bash
sudo ./dumper
