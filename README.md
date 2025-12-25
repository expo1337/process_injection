# Overview

This project is a simple **proof‑of‑concept** for Windows process injection written in Rust with a custom x64 shellcode payload.
The injected shellcode performs a PEB walk to dynamically resolve WinAPI functions and ultimately spawns a `MessageBoxA` from `user32.dll` inside the target process.

# Building and running

### Prerequisites

-   Windows 10/11 x64
-   Rust toolchain (stable) with  `cargo`  installed.​
-   NASM (Netwide Assembler) for building the shellcode (optional).
-   A 64‑bit target process to inject into (e.g.  `notepad.exe`).


### Build steps

1.  Clone the repository:

    -   `git clone https://github.com/expo1337/process-injection`

    -   `cd process-injection`

2.  Build the shellcode (or use your own):

    -   `cd shellcode`

    -   `nasm -f bin messagebox.asm -o messagebox.bin`

3.  Update shellcode bytes:

    -   Convert  `messagebox.bin`  to a Rust byte array (e.g. with a small helper or  `xxd -i`  equivalent) and replace the  `shellcode`  array in the Rust source. You can also use something like [Defuse Online Assembler](https://defuse.ca/online-x86-assembler.htm) to completely skip the `nasm` part.

4.  Build the injector:

    -   `cd ..`

    -   `cargo build --release`


# Usage

1.  Start a target 64‑bit process (e.g. open  `notepad.exe`).

2.  Find its PID (Task Manager, Process Hacker, etc.).

3.  Run the injector from an elevated terminal if needed:

    -   `target\release\injector.exe`

4.  When prompted:

    -   Enter the PID of the target process, or

    -   Use  `q`  to quit.

5.  If the injection succeeds, a message box with the configured text and caption should appear in the context of the target process.


# Warning

### Legal Notice

This project is intended **for educational and research purposes**, such as understanding how process injection and dynamic API resolution work on Windows.​
Do not use this code against systems you do not own or explicitly have permission to test.
I am not liable for any damages resulting from the use of the information.

### Shellcode Warning

The shellcode provided in this project is **intended** to be safe to run on your device.

However, you should always read and understand what the shellcode does before executing it, and **you should never run random or untrusted code from the internet** on any system that contains important data or that you do not fully control.
