# Risc Machine

The Risc Machine, is an abstract machine with registers. Think of it as an arm machine with
normal instruction names. It is not however an abstraction of existing hardware, but only
of that subset that we need.

Our primary objective is to compile typed code to this level, so the register machine has:
- object access instructions
- object load
- object oriented call semantics
- extended (and extensible) branching
- normal integer operators

All data is in objects.

The register machine is aware of Parfait objects, and specifically uses Message and Frame to
express call semantics.

## Calls and syscalls

The Risc Machine only uses 1 fixed register, the currently worked on Message. (and assumes a
program counter and flags, neither of which are directly manipulated)

There is no stack, rather messages form a linked list, and preparing to call, the data is
pre-filled into the next message. Calling then means moving the new message to the current
one and jumping to the address of the method. Returning is the somewhat reverse process.

Syscalls are implemented by *one* Syscall instruction. The Risc machine does not specify/limit
the meaning or number of syscalls. This is implemented by the level below, eg the arm/interpreter.

## Interpreter

There is an interpreter that can interpret programs compiled to the risc instruction set.
This is very handy for debugging (and nothing else).

Even more handy is the graphical interface for the interpreter, which is in it's own repository:
rubyx-debugger.

## Arm / Elf

There is also a (very straightforward) transformation to arm instructions.
Together with the also quite minimal elf module, arm binaries can be produced.

These binaries have no external dependencies and in fact can not even call c at the moment
(only syscalls :-)).
