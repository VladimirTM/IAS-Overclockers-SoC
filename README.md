# IAS-Overclockers: 16-bit CPU with Cryptocurrency Mining

> A 16-bit General Purpose Processor with ASIP (Application-Specific Instruction Set Processor) extension for cryptocurrency mining acceleration and Memory-Mapped I/O (MMIO) peripheral support.

---

## Overview

The **IAS-Overclockers** project is an educational 16-bit CPU implementation developed as part of the FIC (Faculty of Engineering) course project. This processor combines traditional general-purpose computing capabilities with specialized hardware for cryptocurrency mining operations.

At its core, the CPU features a complete 16-bit von Neumann architecture with 54 instructions, including arithmetic, logic, memory, and control flow operations. What makes this processor unique is its **MINE instruction** - a specialized ASIP extension that implements SHA-256-based hash computation for cryptocurrency mining acceleration.

**New Instruction Extensions** (v2.0):

- **JMP**: Single-instruction jump with return address save (replaces PUSH+BRA pseudo-instruction)
- **PUSH X/Y**: Push X or Y register onto stack
- **POP X/Y**: Pop from stack into X or Y register
- **MOVR**: Register-to-register moves between A, X, and Y
- **BGT, BLT, BGE, BLE**: Conditional branches for greater/less than comparisons
- **BEQ, BNE**: Branch if equal / not equal (for equality comparisons)
- **NOP**: No operation for timing and alignment

**New I/O Extensions** (v3.0 — MMIO Foundation):

- **IN port**: Read 16-bit value from memory-mapped I/O port into accumulator A
- **OUT port**: Write accumulator A to memory-mapped I/O port
- **Memory-Mapped I/O Controller**: Keyboard, display, timer, and mining-result peripherals accessible via addresses with bit 10 set (I/O space)
- Port map: KBD_DATA (0), KBD_STATUS (1), DISP_DATA (16), TIMER_CTRL (32), TIMER_PERIOD (33), TIMER_COUNT (34), IER (48), IFR (49), MINE_HASH (64), MINE_NONCE (65)

This project demonstrates advanced concepts in digital design, including CPU architecture, instruction set design, finite state machines, and hardware-software co-design through the integration of specialized acceleration cores.

---

## Features

- **16-bit General Purpose Processor** with von Neumann architecture
- **56 Instructions**: 29 core operations + 24 extensions + MINE + **IN + OUT** (BEQ is alias for BRZ)
- **Application-Specific Extension**: Cryptocurrency mining core with SHA-256-based hashing
- **Memory-Mapped I/O**: Peripheral controller (keyboard, display, timer, mining result ports) accessed via `IN`/`OUT` instructions; bit 10 of address register selects I/O space vs RAM
- **Complete Toolchain**:
  - Python-based assembler for assembly-to-machine-code translation (supports comma-separated operands)
  - Interactive memory initialization tool
  - Comprehensive testbench suite
- **Robust Testing**: 24 module testbenches with 524 test cases (all PASS)
- **Build Automation**: Makefile-based workflow with shell script wrappers
- **Waveform Analysis**: VCD file generation for GTKWave debugging

---

## Architecture

### Registers

The CPU provides a rich set of 16-bit registers for flexible programming:

- **Accumulator (A)**: Primary register for ALU operations and immediate values
- **General Purpose Registers**:
  - **X**: First general-purpose register
  - **Y**: Second general-purpose register
- **Special Purpose Registers**:
  - **PC** (Program Counter): Tracks current instruction address
  - **SP** (Stack Pointer): Manages stack operations
  - **AR** (Address Register): Holds memory addresses
  - **DR** (Data Register): Holds data for memory operations
  - **IR** (Instruction Register): Stores current instruction
- **Flag Register** (4-bit): Status flags for conditional operations
  - **Z** (Zero): Set when result is zero
  - **N** (Negative): Set when result is negative
  - **C** (Carry): Set on unsigned overflow/borrow
  - **O** (Overflow): Set on signed overflow

### Core Components

- **16-bit ALU**: Performs arithmetic, logic, shift, and rotate operations with flag generation
- **Control Unit**: 78-state FSM (states 0–77) managing fetch-decode-execute; 6 new states for IN/OUT; states 78–97 reserved for interrupt system (see Roadmap)
- **Unified Memory**: 1024 x 16-bit words (10-bit addressing) for instructions, data, and stack
- **I/O Controller** (`io_controller.v`): Memory-mapped peripheral controller; keyboard latch with IRQ, display output with write-enable pulse, free-running timer with configurable period and periodic/one-shot mode, mining result latch; read path is fully combinational (mandatory for single-cycle `IN` instruction)
- **Mining Core**: SHA-256-based hash computation engine for proof-of-work operations
- **Sign Extend Unit**: Converts 9-bit signed immediates to 16-bit values
- **Address Routing**: `ar_out[10] = 0` → RAM; `ar_out[10] = 1` → I/O controller (the `AR_EXT` mux input, `CondAR = 2'b11`, is used by `IN`/`OUT` and will be reused for IVT access during interrupt handling)

### Instruction Format

Instructions are 16 bits wide with the following encoding:

**Memory & Branch Instructions** (10-bit address):

```
┌─────────┬────────────┐
│ Opcode  │  Address   │
│ 6 bits  │  10 bits   │
└─────────┴────────────┘
```

**ALU Instructions** (register select + 9-bit immediate):

```
┌─────────┬──────────┬─────────────┐
│ Opcode  │ Reg Addr │  Immediate  │
│ 6 bits  │  1 bit   │   9 bits    │
└─────────┴──────────┴─────────────┘
```

- Register Address: 0 = X register, 1 = Y register
- Immediate Range: -256 to 255 (9-bit signed)

---

## Instruction Set

The CPU supports 54 instructions organized into the following categories:

### Control Flow

| Instruction | Description                                         |
| ----------- | --------------------------------------------------- |
| `END`       | Halt program execution                              |
| `JMP addr`  | Jump to address (pushes PC to stack, then branches) |
| `RET`       | Return from procedure (pop PC from stack)           |
| `BRA addr`  | Branch always (unconditional jump)                  |
| `BRZ addr`  | Branch if Zero flag is set                          |
| `BRN addr`  | Branch if Negative flag is set                      |
| `BRC addr`  | Branch if Carry flag is set                         |
| `BRO addr`  | Branch if Overflow flag is set                      |
| `BGT addr`  | Branch if Greater Than (signed comparison)          |
| `BLT addr`  | Branch if Less Than (signed comparison)             |
| `BGE addr`  | Branch if Greater or Equal (signed comparison)      |
| `BLE addr`  | Branch if Less or Equal (signed comparison)         |
| `BEQ addr`  | Branch if Equal (Z flag set, after CMP)             |
| `BNE addr`  | Branch if Not Equal (Z flag clear, after CMP)       |
| `NOP`       | No operation (timing/alignment)                     |

### Memory Operations

| Instruction | Description                            |
| ----------- | -------------------------------------- |
| `LD X addr` | Load value from memory into X register |
| `LD Y addr` | Load value from memory into Y register |
| `ST X addr` | Store X register value to memory       |
| `ST Y addr` | Store Y register value to memory       |
| `PUSH X`    | Push X register onto stack             |
| `PUSH Y`    | Push Y register onto stack             |
| `POP X`     | Pop from stack into X register         |
| `POP Y`     | Pop from stack into Y register         |

### Arithmetic (Register Operations)

| Instruction       | Description                                             |
| ----------------- | ------------------------------------------------------- |
| `ADD X` / `ADD Y` | A = A + X/Y                                             |
| `SUB X` / `SUB Y` | A = A - X/Y                                             |
| `MUL X` / `MUL Y` | A = A \* X/Y (signed multiplication)                    |
| `DIV X` / `DIV Y` | A = A / X/Y (signed division, truncates towards zero)   |
| `MOD X` / `MOD Y` | A = A mod X/Y (signed remainder, follows dividend sign) |
| `INC X` / `INC Y` | Increment X/Y register                                  |
| `DEC X` / `DEC Y` | Decrement X/Y register                                  |

### Arithmetic (Immediate Operations)

| Instruction | Description                                         |
| ----------- | --------------------------------------------------- |
| `MOVI imm`  | A = immediate value                                 |
| `ADDI imm`  | A = A + immediate (signed)                          |
| `SUBI imm`  | A = A - immediate (signed)                          |
| `MULI imm`  | A = A \* immediate (signed)                         |
| `DIVI imm`  | A = A / immediate (signed, truncates towards zero)  |
| `MODI imm`  | A = A mod immediate (signed, follows dividend sign) |

### Shift & Rotate

| Instruction | Description                          |
| ----------- | ------------------------------------ |
| `LSL X/Y`   | Logical Shift Left by X/Y positions  |
| `LSR X/Y`   | Logical Shift Right by X/Y positions |
| `RSL X/Y`   | Rotate Shift Left by X/Y positions   |
| `RSR X/Y`   | Rotate Shift Right by X/Y positions  |
| `LSLI imm`  | Logical Shift Left by immediate      |
| `LSRI imm`  | Logical Shift Right by immediate     |
| `RSLI imm`  | Rotate Shift Left by immediate       |
| `RSRI imm`  | Rotate Shift Right by immediate      |

### Logical Operations

| Instruction | Description                      |
| ----------- | -------------------------------- |
| `AND X/Y`   | A = A AND X/Y (bitwise)          |
| `OR X/Y`    | A = A OR X/Y (bitwise)           |
| `XOR X/Y`   | A = A XOR X/Y (bitwise)          |
| `NOT X/Y`   | A = NOT A (bitwise complement of accumulator; operand is unused) |
| `ANDI imm`  | A = A AND immediate              |
| `ORI imm`   | A = A OR immediate               |
| `XORI imm`  | A = A XOR immediate              |
| `NOTI imm`  | A = NOT A (bitwise complement of accumulator; immediate is unused) |

### Comparison & Test

| Instruction    | Description                              |
| -------------- | ---------------------------------------- |
| `CMP X/Y`      | Compare A with X/Y (set flags)           |
| `TST X/Y`      | Test A with X/Y (bitwise AND, set flags) |
| `CMPI imm`     | Compare A with immediate                 |
| `TSTI imm`     | Test A with immediate                    |
| `MOV X/Y, imm` | Move immediate value to X/Y register     |

### Register-to-Register Moves

| Instruction | Description                            |
| ----------- | -------------------------------------- |
| `MOVR A, X` | Copy X register to Accumulator (A = X) |
| `MOVR A, Y` | Copy Y register to Accumulator (A = Y) |
| `MOVR X, A` | Copy Accumulator to X register (X = A) |
| `MOVR X, Y` | Copy Y register to X register (X = Y)  |
| `MOVR Y, A` | Copy Accumulator to Y register (Y = A) |
| `MOVR Y, X` | Copy X register to Y register (Y = X)  |

### I/O Operations (v3.0)

| Instruction  | Opcode   | Description                                                       |
| ------------ | -------- | ----------------------------------------------------------------- |
| `IN port`    | `100110` | A ← mem-mapped I/O port (10-bit port address, 0–1023)             |
| `OUT port`   | `100111` | I/O port ← A (10-bit port address, 0–1023)                        |

**Instruction encoding** (both use full 10-bit port address in `[9:0]`):
```
IN  port : [15:10]=100110 | [9:0]=port_address
OUT port : [15:10]=100111 | [9:0]=port_address
```

**I/O Port Map:**

| Port | Hex   | R/W | Name         | Description                                         |
|------|-------|-----|--------------|-----------------------------------------------------|
| 0    | 0x000 | R   | KBD_DATA     | Keyboard ASCII; read clears latch and kbd_irq       |
| 1    | 0x001 | R   | KBD_STATUS   | bit 0 = data ready                                  |
| 16   | 0x010 | W   | DISP_DATA    | Display character output (disp_we pulse)            |
| 17   | 0x011 | R   | DISP_STATUS  | Always 0 (display never busy)                       |
| 32   | 0x020 | R/W | TIMER_CTRL   | bit 0 = enable, bit 1 = periodic                    |
| 33   | 0x021 | R/W | TIMER_PERIOD | Timer reload value; write also resets counter       |
| 34   | 0x022 | R   | TIMER_COUNT  | Current counter value                               |
| 48   | 0x030 | R/W | IER          | Interrupt Enable Register (4-bit)                   |
| 49   | 0x031 | R   | IFR          | Interrupt Flag Register `[2:mining, 1:kbd, 0:timer]`|
| 64   | 0x040 | R   | MINE_HASH    | Latched mining hash; read clears mining_irq         |
| 65   | 0x041 | R   | MINE_NONCE   | Latched mining nonce                                |

### ASIP Extension

| Instruction | Description                                         |
| ----------- | --------------------------------------------------- |
| `MINE`      | Cryptocurrency mining operation (see section below) |

---

## MINE Instruction - ASIP Extension

The **MINE instruction** is the unique ASIP (Application-Specific Instruction Set Processor) extension that sets this CPU apart. It implements cryptocurrency mining acceleration through hardware-based SHA-256 hash computation.

### Purpose

Cryptocurrency mining requires finding a "nonce" (number used once) that, when combined with data and hashed, produces a result below a target difficulty threshold. This is the basis of proof-of-work systems used in blockchain technology.

### Operation

**Inputs** (loaded into registers before MINE):

- **X Register**: Data to be hashed (e.g., block header data)
- **Y Register**: Starting nonce value
- **A Register**: Target difficulty threshold

**Execution**:

1. The mining core takes the data (X) and nonce (Y)
2. Computes SHA-256-style hash with 16-round compression function
3. Compares hash result against target threshold (A)
4. If hash ≥ target: increments nonce and repeats
5. If hash < target: mining complete, winning nonce found

**Output**:

- **X Register**: Contains the winning nonce that produces a hash below the target
- **A Register**: Contains the final hash value
- **Flags**: Updated based on mining completion status

### Algorithm

The mining core implements a simplified SHA-256 algorithm:

- 16-round compression function (educational simplification of standard 64 rounds)
- Uses SHA-256-style operations: rotation, choice (ch), majority (maj), sigma functions
- Hardware-accelerated for faster computation than software implementation

### Example Usage

```assembly
# Cryptocurrency Mining Example
LD X 496          # Load block data from memory address 496
LD Y 497          # Load starting nonce from memory address 497
MOVI 255          # Set target difficulty (lower = harder)
MINE              # Execute mining operation
                  # X now contains winning nonce, A contains hash
ST X 498          # Store result nonce to memory
END
```

### Educational Context

This implementation demonstrates:

- How ASIPs extend general-purpose processors with specialized instructions
- Hardware acceleration for computationally intensive tasks
- Real-world application of digital design principles
- Integration of custom cores into existing CPU architectures

**Note**: This is a simplified educational implementation. Production cryptocurrency mining uses full SHA-256 (or other algorithms) with optimized hardware and much larger data widths.

---

## Getting Started

### Prerequisites

Before running the CPU simulator, ensure you have the following tools installed:

- **Icarus Verilog** (iverilog, vvp): Open-source Verilog simulator

  ```bash
  # macOS (Homebrew)
  brew install icarus-verilog

  # Ubuntu/Debian
  sudo apt-get install iverilog
  ```

- **Python 3.x**: For the assembler and memory initialization tools

  ```bash
  python3 --version  # Check if installed
  ```

- **Make**: Build automation tool (usually pre-installed on Unix systems)

  ```bash
  make --version  # Check if installed
  ```

- **GTKWave** (optional): For viewing waveform files

  ```bash
  # macOS
  brew install gtkwave

  # Ubuntu/Debian
  sudo apt-get install gtkwave
  ```

---

## Usage

### Quick Test

Run the comprehensive test suite to validate all instructions:

```bash
make test
```

Or run the simple testbench for a basic register dump:

```bash
make simple
```

Run all 24 module unit testbenches:

```bash
make modules
```

Run module tests then CPU integration test with a combined summary:

```bash
make test-all
```

### Custom Assembly Programs

Test your own assembly programs:

```bash
make test ASM=my_program.asm       # Comprehensive test
make simple ASM=my_program.asm     # Simple register dump
```

### Build Pipeline

For step-by-step control over the build process:

```bash
# 1. Assemble your program (converts .asm to machine code)
make assemble ASM=test_program.asm

# 2. Initialize memory with test data (interactive — press Enter to accept defaults)
make memory

# 3. Compile Verilog modules to simulation binary
make compile

# 4. Run the simulation
make run
```

### Alternative Methods

Use shell scripts for convenience:

```bash
# Simple test with default program
./run_simple_test.sh

# Simple test with custom program
./run_simple_test.sh my_program.asm

# Full control over testbench selection
./run_cpu_test.sh test_program.asm Module-Testing/cpu_tb.v
```

### Cleanup

Remove generated files:

```bash
make clean        # Remove simulation binaries and VCD files
make distclean    # Deep clean (also removes assembled binaries)
```

### Help

View all available make targets:

```bash
make help
```

---

## Writing Assembly Programs

### Example Program

Here's a comprehensive example demonstrating various instruction types:

```assembly
; Example: Arithmetic, Control Flow, and Mining Operations
; This program demonstrates CPU capabilities including new instructions

; ==========================================
; Load Initial Values
; ==========================================
LD X, 284             ; Load X from memory address 284 (value: 15)
LD Y, 285             ; Load Y from memory address 285 (value: 7)

; Store values to different addresses
ST X, 274             ; Store X to memory address 274
ST Y, 275             ; Store Y to memory address 275

; ==========================================
; Arithmetic Operations
; ==========================================
MOVI 100              ; Load immediate: A = 100
ADD X                 ; Add: A = A + X = 100 + 15 = 115
SUB X                 ; Subtract: A = A - X = 115 - 15 = 100
MUL Y                 ; Multiply: A = A * Y = 100 * 7 = 700
DIV Y                 ; Divide: A = A / Y = 700 / 7 = 100
MOD Y                 ; Modulo: A = A mod Y = 100 mod 7 = 2

; ==========================================
; Register-to-Register Moves (NEW)
; ==========================================
MOVI 42               ; A = 42
MOVR X, A             ; X = A (X now 42)
MOVR Y, X             ; Y = X (Y now 42)
MOVR A, Y             ; A = Y (A still 42)

; ==========================================
; Conditional Branches (NEW)
; ==========================================
MOVI 10               ; A = 10
MOV X, 5              ; X = 5
CMP X                 ; Compare A (10) with X (5)
BGT greater           ; Branch if A > X (10 > 5, taken!)
END                   ; Never reached
greater: NOP          ; No operation, continue

MOVI 3                ; A = 3
MOV X, 7              ; X = 7
CMP X                 ; Compare A (3) with X (7)
BLT less              ; Branch if A < X (3 < 7, taken!)
END                   ; Never reached
less: NOP             ; Continue

; ==========================================
; Shift Operations
; ==========================================
MOVI 3                ; A = 3
LSL X                 ; Logical shift left: A = 3 << 7
MOVI 16               ; A = 16
LSR X                 ; Logical shift right: A = 16 >> 7

; ==========================================
; Logical Operations
; ==========================================
MOVI 170              ; A = 170 (binary: 10101010)
AND X                 ; A = A AND X
MOVI 15               ; A = 15
OR X                  ; A = A OR X
MOVI 85               ; A = 85
XOR X                 ; A = A XOR X
NOT X                 ; A = NOT A

; ==========================================
; Register Manipulation
; ==========================================
MOV X, 42             ; Move immediate 42 to X register
INC X                 ; Increment X: X = 43
DEC X                 ; Decrement X: X = 42

; ==========================================
; Cryptocurrency Mining Example
; ==========================================
LD X, 496             ; Load data to hash (value: 0x1234)
LD Y, 497             ; Load starting nonce (value: 0)
MOVI 255              ; Set target difficulty (A = 255)
MINE                  ; Execute mining - finds nonce where hash < target
                      ; X register now contains winning nonce, A contains hash

; ==========================================
; End Program
; ==========================================
END                   ; Halt CPU execution
```

### Assembly Programming Notes

**Syntax Rules:**

- One instruction per line
- Instructions are case-insensitive (MOVI = movi)
- Comments start with `;` and extend to end of line
- Labels are supported: `loop: MOVI 0` (label name followed by colon)
- Whitespace is flexible (spaces/tabs for indentation)
- Multi-operand instructions use comma-separated syntax: `LD X, 284`, `MOVR X, A`, `MOV X, 42`

**Immediate Value Range:**

- 9-bit signed integers: **-256 to 255**
- Values outside this range will cause assembly errors

**Memory Layout:**

- **Program Memory**: Addresses 0-199 (200 instruction maximum)
- **Data Memory**: Addresses 200-1023 (824 words available)
- **Stack**: Grows downward from address 1023

**Procedure Calls:**

- `JMP label`: Jump to subroutine (single instruction, saves return address on stack)
  - Automatically pushes PC and branches to label
  - Use with `RET` to return from subroutine

**Register Stack Operations:**

- `PUSH X/Y` and `POP X/Y` allow saving/restoring register state
- Stack grows downward from 0x3FF (1023)
- Useful for preserving register values across function calls

**Tips:**

- Initialize data at any address (0-1023) using data_init.py tool (supports negative values)
- Use labels for loops and branches (more readable than raw addresses)
- Test small programs first with `make simple` for quick register dumps
- Use `make test` with comprehensive testbench for full validation

---

## Project Structure

```
IAS-Overclockers/
├── CPU/                          # Core processor Verilog modules
│   ├── cpu.v                    # Top-level CPU integration module (MMIO routing added)
│   ├── cu.v                     # Control Unit (78-state FSM; IN/OUT states 72-77)
│   ├── io_controller.v          # [NEW v3.0] Memory-mapped I/O peripheral controller
│   ├── alu.v                    # 16-bit Arithmetic Logic Unit
│   ├── mining_core.v            # SHA-256 cryptocurrency mining core
│   ├── memory.v                 # Unified instruction/data memory (1024 words)
│   ├── accumulator.v            # Accumulator (A register)
│   ├── register_x.v             # X general-purpose register
│   ├── register_y.v             # Y general-purpose register
│   ├── program_counter.v        # Program Counter (PC)
│   ├── stack_pointer.v          # Stack Pointer (SP)
│   ├── address_register.v       # Address Register (AR)
│   ├── data_register.v          # Data Register (DR)
│   ├── instruction_register.v   # Instruction Register (IR)
│   ├── seu.v                    # Sign Extend Unit (9-bit → 16-bit)
│   ├── mux_ar.v                 # Address Register mux (+ AR_EXT input for I/O/IVT)
│   ├── mux_dr.v                 # Data Register mux (+ io_data and packed-flags inputs)
│   ├── mux_alu.v                # ALU operand multiplexer
│   └── ...                      # Additional support modules
│
├── CPU-Assembler/                # Python-based assembler toolchain
│   ├── main.py                  # Assembly-to-machine-code translator
│   ├── opcode_table.py          # Instruction opcode definitions
│   └── ...                      # Assembler utilities
│
├── Module-Testing/               # Component-level testbenches
│   ├── cpu_tb.v                 # Comprehensive CPU validation
│   ├── alu_tb.v                 # ALU unit tests
│   ├── memory_tb.v              # Memory module tests
│   ├── accumulator_tb.v         # Accumulator register tests
│   ├── io_controller_tb.v       # [NEW v3.0] I/O controller tests (34 tests)
│   ├── mux_ar_tb.v              # Address mux tests (updated: AR_EXT routing, 8 tests)
│   ├── mux_dr_tb.v              # Data mux tests (updated: io_data/flags paths, 14 tests)
│   ├── register_x_tb.v          # X register tests
│   ├── register_y_tb.v          # Y register tests
│   ├── data_register_tb.v       # Data register + mux_dr integration tests
│   └── ...                      # Additional component tests
│
├── cpu_tb.v                      # Simple register dump testbench (root level)
├── test_program.asm              # Example assembly program (tests all instructions)
├── data_init.py                  # Interactive memory initialization (supports negative values)
├── data_bin.txt                  # Generated machine code + initialized memory
│
├── Makefile                      # Build automation and test targets
├── run_cpu_test.sh               # General test runner script
├── run_simple_test.sh            # Simple test convenience wrapper
│
├── Project_original_specs.pdf    # FIC course project specification
└── README.md                     # This file
```

### Key Files Explained

- **cpu.v**: Top-level module that interconnects all CPU components
- **cu.v**: Control unit with 72-state FSM managing instruction execution phases
- **mining_core.v**: The ASIP extension implementing cryptocurrency mining
- **main.py**: Assembler that translates `.asm` files to 16-bit binary machine code
- **data_init.py**: Tool for initializing memory (supports decimal, hex, and negative values)
- **cpu_tb.v** (Module-Testing/): Comprehensive testbench validating all instructions
- **cpu_tb.v** (root): Simple testbench showing final register state

---

## Testing

### Test Infrastructure

The project includes comprehensive testing at multiple levels:

**Component Testing (24 Module Testbenches):**

- Individual modules tested in isolation (Module-Testing/ directory)
- Automated test runner script: `run_all_testbenches.sh`
- Tests for all CPU components: ALU, registers, memory, control unit, muxes, I/O controller, etc.

**Integrated CPU Testing:**

- Comprehensive testbench validates all instructions including new I/O extensions
- Tests include: memory operations, ALU, branches (including BEQ/BNE), stack operations, I/O controller peripheral paths

**Module Test Summary:**
| Module | Tests | Status | Notes |
|--------|-------|--------|-------|
| alu_negative_test_tb.v | 24 | ✓ PASS | |
| accumulator_tb.v | 10 | ✓ PASS | |
| alu_tb.v | 46 | ✓ PASS | |
| ar_tb.v | 14 | ✓ PASS | Updated: AR_EXT port added |
| cu_tb.v | 251 | ✓ PASS | |
| data_register_tb.v | 26 | ✓ PASS | Updated: io_data/flags ports added |
| flags_tb.v | 9 | ✓ PASS | |
| io_controller_tb.v | 34 | ✓ PASS | **NEW v3.0**: kbd, display, timer, mining, IER/IFR |
| ir_tb.v | 6 | ✓ PASS | |
| memory_tb.v | 8 | ✓ PASS | |
| mining_core_tb.v | 3 | ✓ PASS | |
| mux_alu_tb.v | 6 | ✓ PASS | |
| mux_ar_tb.v | 8 | ✓ PASS | Updated: AR_EXT routing tests added |
| mux_dr_tb.v | 14 | ✓ PASS | Updated: io_data + packed FLAGS path tests |
| mux_pc_tb.v | 5 | ✓ PASS | |
| opcode_decoder_tb.v | 7 | ✓ PASS | |
| program_counter_tb.v | 7 | ✓ PASS | |
| rca_tb.v | 6 | ✓ PASS | |
| rcas_tb.v | 6 | ✓ PASS | |
| register_x_tb.v | 7 | ✓ PASS | |
| register_y_tb.v | 7 | ✓ PASS | |
| rgst_tb.v | 7 | ✓ PASS | |
| seu_tb.v | 6 | ✓ PASS | |
| stack_pointer_tb.v | 7 | ✓ PASS | |
| **Total** | **524** | **✓ PASS** | 24 testbenches, 0 failures |

**Control Unit Testing (cu_tb.v):**

- 251 comprehensive FSM tests covering all 72 states
- Tests all instruction categories including new extensions:
  - Memory operations (LD, ST, PUSH X/Y, POP X/Y)
  - Arithmetic (ADD, SUB, MUL, DIV, MOD with registers and immediates)
  - Logical operations (AND, OR, XOR, NOT)
  - Shift and rotate operations (LSL, LSR, RSL, RSR)
  - Control flow (JMP, BRA, BRZ, BRN, BRC, BRO, BGT, BLT, BGE, BLE, BEQ, BNE, RET, END, NOP)
  - Register manipulation (MOV, MOVR, INC, DEC)
  - ASIP extension (MINE)

### Running Module Tests

Run all 24 module testbenches (including `alu_negative_test_tb.v` and the new `io_controller_tb.v`):

```bash
make modules                                        # from repo root (preferred)
cd Module-Testing && bash run_all_testbenches.sh    # equivalent, direct
```

The script runs all `*_tb.v` files (including `alu_negative_test_tb.v`), prints per-testbench results, and reports a combined PASS/FAIL total. `cpu_tb.v` is excluded — use `make test` (which assembles the program first) to run that testbench.

### Test Output Format

Tests provide detailed feedback:

```
Processing: cu_tb.v
Test  1 PASS: State LOAD_ADDR: ldAR=1
Test  2 PASS: State LOAD_INSTR: ldDR=ldIR=incPC=1
...
Test 229 PASS: PUSH_REG_1 (ldAR=1, condAR=01)
Test 230 PASS: PUSH_REG_2 (ldDR=1, condDR=001 for X)
Test 231 PASS: PUSH_REG_3 (memWR=1, decSP=1)
...
Test 249 PASS: POP_REG_4 Y (ldY=1)
Test 250 PASS: Return to LOAD_ADDR after POP Y
Test 251 PASS: State HALT: finish=1
---------------------------------------
Simulare Finalizata!
Total Teste:         251
Teste PASS :         251
Teste FAIL :           0
---------------------------------------
```

### Waveform Analysis

For debugging and visualization:

- VCD (Value Change Dump) files generated during simulation
- View with GTKWave: `make wave` (if VCD file exists)
- Traces include all signals: registers, control signals, FSM states, memory accesses

---

## Development

### Team

**IAS-Overclockers**

This project was developed as a collaborative team effort for the FIC course, demonstrating skills in:

- Hardware design and Verilog implementation
- CPU architecture and digital logic
- Assembler and toolchain development
- Comprehensive testing and validation
- Project management and milestone tracking

### Project Milestones

1. ✅ **General Purpose Processor Implementation**
   - 16-bit CPU architecture
   - Core instruction set (29 instructions)
   - Control unit FSM
   - ALU integration
   - Memory subsystem
   - Testing infrastructure

2. ✅ **ASIP Extension**
   - Cryptocurrency mining core design
   - SHA-256-based hash algorithm implementation
   - MINE instruction integration
   - Mining testbench validation

3. ✅ **Testing and Validation**
   - Comprehensive test suite (24 module testbenches, 524 tests)
   - All instruction categories validated
   - Build automation and toolchain
   - Documentation

4. ✅ **Memory-Mapped I/O Foundation (v3.0)**
   - `io_controller.v`: keyboard, display, timer, mining-result peripherals
   - `IN` / `OUT` instructions (opcodes 38/39, 6 new FSM states 72–77)
   - `ar_out[10]` routing: RAM vs I/O space; `mem_we_gated` prevents spurious RAM writes
   - `mux_ar` AR_EXT path (`CondAR=2'b11`) for I/O page and future IVT access
   - `mux_dr` io_data path (`CondDR=3'b110`) and packed-FLAGS path (`CondDR=3'b111`)
   - Assembler support for `IN port` / `OUT port`
   - 34-test `io_controller_tb.v` covering all peripherals
   - Zero regressions across all 524 tests

5. 🔄 **Interrupt System (v3.1 — In Progress)**
   - `interrupt_controller.v` (pending)
   - EI / DI / IRET / WAIT instructions (pending)
   - CU states 78–97 for interrupt save/restore/return (pending)
   - `flags.v` `use_packed_flags` path (pending)
   - IVT at addresses 190–193 (pending)

---

## Technical Details

### Control Flow

**Instruction Execution Cycle:**
The CPU uses a 72-state Finite State Machine (FSM) in the control unit to manage instruction execution:

1. **Fetch**: Load instruction from memory at PC address
2. **Decode**: Parse opcode and operands
3. **Execute**: Perform operation (may take multiple cycles)
4. **Write-Back**: Store results to registers/memory
5. **Update PC**: Increment program counter or branch

**Multi-Cycle Operations:**

- ALU operations use a 3-cycle input sequencing protocol
- Division/modulo add 2 pre-processing cycles for sign handling (total ~14-18 cycles)
- Memory operations require address setup and data transfer cycles
- Mining operations take variable cycles depending on difficulty

**State Machine Details:**

- 78 active states (0–77) with states 78–97 reserved for the interrupt system (see Roadmap)
  - 47 original states (fetch, decode, ALU, memory, branches, stack)
  - 3 for signed division (D_PRE1/D_PRE2, D_POST)
  - 12 for conditional branches (MOVR_1/MOVR_2, NOP_1, BGT/BLT/BGE/BLE with CHECK/TAKE/SKIP)
  - 7 for stack operations (PUSH_REG_1/2/3, POP_REG_1/2/3/4)
  - 3 for BNE instruction (BNE_CHECK/TAKE/SKIP)
  - **6 new (v3.0)**: IN_1/IN_2/IN_3 (states 72–74) for `IN` instruction; OUT_1/OUT_2/OUT_3 (states 75–77) for `OUT` instruction
- Conditional branches evaluate flags and update PC accordingly
- BEQ uses same states as BRZ (alias), BNE has dedicated states
- Stack operations coordinate SP updates with memory access
- Division states: D_PRE1/D_PRE2 extract signs, D0-D10 perform SRT4, D_POST applies sign
- JMP reuses PUSH_1/2/3 states but adds branch in PUSH_3
- **IN** instruction: IN_1 loads AR with I/O page address → IN_2 asserts `io_re` and latches `io_data_out` into DR → IN_3 loads A from DR
- **OUT** instruction: OUT_1 loads AR with I/O page address → OUT_2 loads DR from A → OUT_3 asserts `io_we`

### Memory Organization

**Unified Memory Architecture:**

- **Capacity**: 1024 words × 16 bits (2 KB total)
- **Addressing**: 10-bit addresses (0x000 - 0x3FF)

**Memory Map:**

```
0x000 - 0x0C7  (0-199)    Program Memory (200 instructions max)
0x0C8 - 0x3FE  (200-1022) Data Memory (823 words)
0x3FF  (1023)             Stack Top (grows downward to 0x0C8)
```

**Memory Access:**

- Single-port memory (one read or write per cycle)
- Synchronous access on clock edge
- Supports instruction fetch, data load/store, and stack operations

**Stack Implementation:**

- Stack Pointer (SP) initialized to 0x3FF (top of memory)
- JMP: Write PC to stack, decrement SP, branch to target
- PUSH X/Y: Write register to stack, decrement SP
- POP X/Y: Increment SP, read from stack to register
- RET: Increment SP, read return address, branch to it
- Stack grows downward toward data memory

### Flag Updates

The 4-bit Flag Register stores condition codes for branch instructions:

**Flags Updated By:**

- All ALU arithmetic operations (ADD, SUB, MUL, DIV, MOD)
- All ALU logical operations (AND, OR, XOR, NOT)
- Comparison operations (CMP, TST)
- Shift and rotate operations (LSL, LSR, RSL, RSR)

**Flags Partially Updated (Z, N only):**

- Register increment/decrement (INC, DEC)
- Register moves (MOV, MOVR)

**Flags NOT Updated By:**

- Memory operations (LD, ST, PUSH, POP)
- Control flow (BRA, BRZ, etc.)
- Immediate loads (MOVI)

**Flag Definitions:**

- **Zero (Z)**: Set when ALU result is 0x0000
- **Negative (N)**: Set when ALU result MSB = 1 (negative in 2's complement)
- **Carry (C)**: Set on unsigned overflow (addition) or borrow (subtraction)
- **Overflow (O)**: Set on signed overflow (result exceeds signed range)

### Signed Arithmetic Implementation

All arithmetic operations use **two's complement signed representation**:

**Division & Modulo (DIV/DIVI, MOD/MODI):**

- Signed division implemented at FSM control level
- Algorithm: Extract signs → SRT4 on absolute values → Apply result sign
- Truncation: Rounds towards zero (e.g., -7/2 = -3, not -4)
- Remainder sign follows dividend (e.g., -100 mod 3 = -1, 100 mod -3 = 1)
- Hardware: SRT4 (Signed Radix-4) divider works on unsigned magnitudes
- Edge cases handled: -32768 / 1 = -32768, 32767 / -1 = -32767

**Multiplication (MUL/MULI):**

- Booth's algorithm for signed multiplication
- Result sign determined by XOR of operand signs

**Addition & Subtraction (ADD/ADDI, SUB/SUBI):**

- Native two's complement addition/subtraction
- Overflow flag (O) indicates signed range violation

---

## Known Limitations

These are intentional design choices for the educational scope of the project:

1. **Program Memory Size**: Limited to 200 instructions (addresses 0-199)
   - Keeps testbenches manageable
   - Sufficient for demonstrating all instruction types

2. **Immediate Value Range**: 9-bit signed (-256 to 255)
   - Constrained by 16-bit instruction encoding
   - Workaround: Load larger values from memory

3. **Simplified Mining Algorithm**: Educational simplification of SHA-256
   - 16 rounds instead of standard 64 rounds
   - Not suitable for production cryptocurrency mining
   - Demonstrates ASIP concepts effectively

4. **Interrupt System Incomplete** (in progress — see Roadmap)
   - `io_controller.v` exposes `kbd_irq`, `timer_irq`, `mining_irq` outputs but the interrupt controller and CU states are not yet wired
   - `EI`, `DI`, `IRET`, `WAIT` instructions not yet implemented
   - Programs currently run to completion without asynchronous interruption

5. **No Pipelining**: Simple fetch-decode-execute cycle
   - Instructions execute sequentially (not in parallel)
   - Easier to understand and verify
   - Opportunities for future optimization

6. **Single-Port Memory**: One memory access per cycle
   - Cannot fetch instruction and access data simultaneously
   - Typical of simplified educational CPUs

---

## Roadmap — Interrupt System (v3.1, In Progress)

The MMIO foundation is complete. The next phase implements the full interrupt system as specified in `IO_Implementare_Plan.md`. All infrastructure is already in place (I/O controller IRQ outputs, `AR_EXT` mux, `mux_dr` packed-flags case, `ivt_mode` wire).

### What Remains

**New modules:**

| File | Purpose |
|------|---------|
| `CPU/interrupt_controller.v` | 4-source priority encoder (TIMER > KBD > MINE > EXT); masks against IER and I_flag; clears winning source on `intr_ack` |

**Modified files:**

| File | Change Needed |
|------|--------------|
| `CPU/flags.v` | Add `use_packed_flags` input — on IRET restore, unpack `direct_value[15:12]` as `{Z,N,C,O}` |
| `CPU/cu.v` | Add 20 new states (78–97): `INTR_CHECK`, `INTR_SAVE_1..6`, `INTR_VECTOR`, `INTR_JUMP_1/2`, `IRET_1..7`, `EI_1`, `DI_1`, `WAIT_1`; add `I_flag` register; add `OP_EI/OP_DI/OP_IRET/OP_WAIT` opcodes; change `LOAD_INSTR → INTR_CHECK` (was `→ DECODE`) |
| `CPU/cpu.v` | Wire `interrupt_controller`; connect `irq_id` to `ar_ext_in` when `ivt_mode=1` (`ar_ext_in = 16'd190 + {14'b0, irq_id}`); expose `ext_irq` input |
| `CPU-Assembler/main.py` | Add `EI`(40), `DI`(41), `IRET`(58), `WAIT`(59) opcodes (all zero-operand) |

**Interrupt Vector Table (IVT):**

Pre-loaded at addresses 190–193 (just below data region at 200):

| Address | Source | Content |
|---------|--------|---------|
| 190 | TIMER | Address of TIMER ISR |
| 191 | KBD   | Address of KBD ISR   |
| 192 | MINE  | Address of MINE ISR  |
| 193 | EXT   | Address of EXT ISR   |

**New instructions:**

| Mnemonic | Opcode   | Description |
|----------|----------|-------------|
| `EI`     | `101000` | Enable interrupts (`I_flag = 1`) |
| `DI`     | `101001` | Disable interrupts (`I_flag = 0`) |
| `IRET`   | `111010` | Return from interrupt (pop PC then FLAGS, re-enable interrupts) |
| `WAIT`   | `111011` | Halt CPU until interrupt fires (ARM WFI equivalent) |

**Context save/restore on interrupt:**

Automatically pushes FLAGS then PC onto stack on entry; `IRET` pops PC then FLAGS. FLAGS are packed as `{Z,N,C,O,12'b0}` in a 16-bit word. `I_flag` is cleared on interrupt entry and restored on `IRET`.

**New testbenches needed:**

- `Module-Testing/interrupt_controller_tb.v` — 4-source priority, IER masking, intr_ack
- `Module-Testing/cu_interrupt_tb.v` — all 20 new states (78–97), WAIT loop behavior
- `Demo-Programs/io_interrupt_demo.asm` — EI + WAIT + ISR that reads kbd/mining results

---

## Future Enhancements

Potential improvements for extended learning or follow-on projects:

**Architecture Enhancements:**

- [ ] Expand program memory capacity (support longer programs)
- [ ] Implement pipelined architecture (3-5 stage pipeline)
- [ ] Dual-port memory for simultaneous instruction fetch and data access
- [ ] Cache memory for improved performance

**ASIP Extensions:**

- [ ] Optimize mining core (more rounds, faster computation)
- [ ] Floating-point coprocessor for scientific computing
- [ ] Vector processing unit for parallel operations
- [ ] Cryptographic instructions (AES, RSA operations)

**Toolchain Improvements:**

- [ ] Assembler macro support
- [ ] Linker for multi-file programs
- [ ] Debugger with breakpoints and step execution
- [ ] Higher-level compiler (C-like language to assembly)

**Testing & Validation:**

- [ ] Formal verification of critical paths
- [ ] Performance profiling tools
- [ ] Extended test suite with edge cases
- [ ] FPGA implementation and hardware testing

---

## License

This project is developed for educational purposes as part of the FIC course curriculum.

**License**: MIT License (or specify your preferred open-source license)

Feel free to use this project for learning, teaching, or further development. Attribution to the original team is appreciated.

---

## Acknowledgments

We would like to thank:

- **FIC Course Instructors**: For guidance on CPU architecture and digital design principles
- **Team Members**: For collaborative development, testing, and validation efforts
- **Reference Materials**: Computer architecture textbooks and online resources that informed our design decisions
- **Open Source Community**: Icarus Verilog, GTKWave, and Python tool developers

---

## Contributors

**Team**: IAS-Overclockers

_FIC Course Project - 16-bit General Purpose Processor with ASIP Extension_

For questions about this project or collaboration opportunities, please refer to the project documentation and source code comments.

---

**Last Updated**: March 2026
**Project Status**: Active Development — MMIO complete, Interrupt System in progress
**Version**: 3.0 (Memory-Mapped I/O foundation: io_controller, IN/OUT instructions, mux_ar AR_EXT path, mux_dr io_data + packed-flags paths, 6 new CU states 72–77, assembler IN/OUT encoding, 34-test io_controller_tb; 24 module testbenches, 524 tests, all passing)
