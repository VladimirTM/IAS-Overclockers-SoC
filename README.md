# IAS-Overclockers: 16-bit CPU with Cryptocurrency Mining

> A 16-bit General Purpose Processor with ASIP (Application-Specific Instruction Set Processor) extension for cryptocurrency mining acceleration.

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

This project demonstrates advanced concepts in digital design, including CPU architecture, instruction set design, finite state machines, and hardware-software co-design through the integration of specialized acceleration cores.

---

## Features

- **16-bit General Purpose Processor** with von Neumann architecture
- **54 Instructions**: 29 core operations + 24 new extensions + specialized MINE instruction (BEQ is alias for BRZ)
- **Application-Specific Extension**: Cryptocurrency mining core with SHA-256-based hashing
- **Complete Toolchain**:
  - Python-based assembler for assembly-to-machine-code translation (supports comma-separated operands)
  - Interactive memory initialization tool
  - Comprehensive testbench suite
- **Robust Testing**: 22 module testbenches with 400+ test cases (all PASS)
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
- **Control Unit**: 72-state FSM (Finite State Machine) managing the fetch-decode-execute cycle
- **Unified Memory**: 1024 x 16-bit words (10-bit addressing) for instructions, data, and stack
- **Mining Core**: SHA-256-based hash computation engine for proof-of-work operations
- **Sign Extend Unit**: Converts 9-bit signed immediates to 16-bit values

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
| `NOT X/Y`   | A = NOT X/Y (bitwise complement) |
| `ANDI imm`  | A = A AND immediate              |
| `ORI imm`   | A = A OR immediate               |
| `XORI imm`  | A = A XOR immediate              |
| `NOTI imm`  | A = NOT immediate                |

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

# 2. Initialize memory with test data
make init-memory

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
│   ├── cpu.v                    # Top-level CPU integration module
│   ├── cu.v                     # Control Unit (72-state FSM)
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
│   ├── mux_ar.v                 # Address Register multiplexer
│   ├── mux_dr.v                 # Data Register multiplexer
│   ├── mux_alu.v                # ALU operand multiplexer
│   └── ...                      # Additional support modules
│
├── CPU-Assembler/                # Python-based assembler toolchain
│   ├── main.py                  # Assembly-to-machine-code translator
│   ├── opcode_table.py          # Instruction opcode definitions
│   └── ...                      # Assembler utilities
│
├── Module-Testing/               # Component-level testbenches
│   ├── cpu_tb.v                 # Comprehensive 105-test CPU validation
│   ├── alu_tb.v                 # ALU unit tests
│   ├── memory_tb.v              # Memory module tests
│   ├── accumulator_tb.v         # Accumulator register tests
│   ├── register_x_tb.v          # X register tests
│   ├── register_y_tb.v          # Y register tests
│   ├── data_register_tb.v       # Data register tests
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

**Component Testing (22 Module Testbenches):**

- Individual modules tested in isolation (Module-Testing/ directory)
- Automated test runner script: `run_all_testbenches.sh`
- Tests for all CPU components: ALU, registers, memory, control unit, muxes, etc.

**Integrated CPU Testing (105 Tests):**

- Comprehensive testbench validates all 54 instructions
- Tests include: memory operations, ALU, branches (including BEQ/BNE), stack operations
- All 105 tests pass

**Module Test Summary:**
| Module | Tests | Status |
|--------|-------|--------|
| accumulator_tb.v | 10 | ✓ PASS |
| alu_tb.v | 46 | ✓ PASS |
| ar_tb.v | 14 | ✓ PASS |
| cu_tb.v | 251 | ✓ PASS |
| data_register_tb.v | 26 | ✓ PASS |
| flags_tb.v | 9 | ✓ PASS |
| ir_tb.v | 6 | ✓ PASS |
| memory_tb.v | 8 | ✓ PASS |
| mining_core_tb.v | 3 | ✓ PASS |
| mux_alu_tb.v | 6 | ✓ PASS |
| mux_ar_tb.v | 5 | ✓ PASS |
| mux_dr_tb.v | 7 | ✓ PASS |
| mux_pc_tb.v | 5 | ✓ PASS |
| opcode_decoder_tb.v | 7 | ✓ PASS |
| program_counter_tb.v | 7 | ✓ PASS |
| rca_tb.v | 6 | ✓ PASS |
| rcas_tb.v | 6 | ✓ PASS |
| register_x_tb.v | 7 | ✓ PASS |
| register_y_tb.v | 7 | ✓ PASS |
| rgst_tb.v | 7 | ✓ PASS |
| seu_tb.v | 6 | ✓ PASS |
| stack_pointer_tb.v | 7 | ✓ PASS |

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

Run all 22 module testbenches:

```bash
cd Module-Testing && bash run_all_testbenches.sh
```

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
   - Comprehensive 105-test suite
   - All instruction categories validated
   - Build automation and toolchain
   - Documentation

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

- 72 distinct states handle all instruction types
  - 47 original states
  - 3 for signed division (D_PRE1/D_PRE2, D_POST)
  - 12 for conditional branches (MOVR_1/MOVR_2, NOP_1, BGT/BLT/BGE/BLE with CHECK/TAKE/SKIP)
  - 7 for stack operations (PUSH_REG_1/2/3, POP_REG_1/2/3/4)
  - 3 for BNE instruction (BNE_CHECK/TAKE/SKIP)
- Conditional branches evaluate flags and update PC accordingly
- BEQ uses same states as BRZ (alias), BNE has dedicated states
- Stack operations coordinate SP updates with memory access
- Division states: D_PRE1/D_PRE2 extract signs, D0-D10 perform SRT4, D_POST applies sign
- JMP reuses PUSH_1/2/3 states but adds branch in PUSH_3

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

4. **No Interrupt Support**: Sequential execution only
   - No interrupt controller or exception handling
   - All operations run to completion

5. **No Pipelining**: Simple fetch-decode-execute cycle
   - Instructions execute sequentially (not in parallel)
   - Easier to understand and verify
   - Opportunities for future optimization

6. **Single-Port Memory**: One memory access per cycle
   - Cannot fetch instruction and access data simultaneously
   - Typical of simplified educational CPUs

---

## Future Enhancements

Potential improvements for extended learning or follow-on projects:

**Architecture Enhancements:**

- [ ] Expand program memory capacity (support longer programs)
- [ ] Implement pipelined architecture (3-5 stage pipeline)
- [ ] Add interrupt controller for asynchronous events
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

**Last Updated**: January 2026
**Project Status**: Completed and Validated (22 module testbenches, 500+ tests, all passing)
**Version**: 2.1 (with JMP, PUSH/POP, MOVR, BGT, BLT, BGE, BLE, BEQ, BNE, NOP extensions)
