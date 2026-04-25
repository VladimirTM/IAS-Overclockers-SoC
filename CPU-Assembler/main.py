import re

# Instruction set: 16-bit encoding (6-bit opcode + 10-bit operand)
OPCODE = {
    # Control flow and system
    "END": '000000',
    "BRA": '000011', "BRZ": '000100', "BRN": '000101',
    "BRC": '000110', "BRO": '000111', "BEQ": '000100',  # BEQ is alias for BRZ
    "JMP": '001000', "RET": '001001',
    # Memory operations
    "LD": '000001', "ST": '000010',
    # Arithmetic operations (register)
    "ADD": '001010', "SUB": '001011', "MUL": '001100',
    "DIV": '001101', "MOD": '001110',
    # Shift operations (register)
    "LSL": '001111', "LSR": '010000', "RSR": '010001', "RSL": '010010',
    # Logical operations (register)
    "AND": '010011', "OR": '010100', "XOR": '010101', "NOT": '010110',
    # Comparison operations (register)
    "CMP": '010111', "TST": '011000', "MOV": '011001',
    # Data movement and increment/decrement (register)
    "INC": '011010', "DEC": '011011',
    # Mining and new instructions
    "MINE": '011100', "MOVR": '011101',
    "BGT": '011110', "BLT": '011111', "BGE": '100000', "BLE": '100001',
    "NOP": '100010',
    "PUSH": '100011', "POP": '100100',
    "BNE": '100101',  # Branch if Not Equal (Z==0)
    "IN":   '100110',  # Read I/O port → A
    "OUT":  '100111',  # Write A → I/O port
    # Interrupt instructions (v3.1)
    "EI":   '101000',  # Enable interrupts
    "DI":   '101001',  # Disable interrupts
    "IRET": '111010',  # Return from interrupt
    "WAIT": '111011',  # Halt until interrupt
    # Immediate value operations
    "MOVI": '111001',
    "ADDI": '101010', "SUBI": '101011', "MULI": '101100',
    "DIVI": '101101', "MODI": '101110',
    "LSLI": '101111', "LSRI": '110000', "RSRI": '110001', "RSLI": '110010',
    "ANDI": '110011', "ORI": '110100', "XORI": '110101', "NOTI": '110110',
    "CMPI": '110111', "TSTI": '111000',
}

MEMORY_SIZE = 1024  # Total memory lines in output file

# Opcode groups by encoding format
_OP_NO_OPERAND = {0, 9, 28, 34, 40, 41, 58, 59}           # END, RET, MINE, NOP, EI, DI, IRET, WAIT
_OP_MEMORY     = {1, 2}                                   # LD, ST
_OP_IO         = {38, 39}                                 # IN, OUT
_OP_BRANCH     = {3, 4, 5, 6, 7, 8, 30, 31, 32, 33, 37} # BRA/BRZ/BRN/BRC/BRO/JMP/BGT/BLT/BGE/BLE/BNE
_OP_REG_ARITH  = set(range(10, 25)) | {26, 27, 35, 36}   # ADD-TST, INC, DEC, PUSH, POP
_OP_IMM_ARITH  = set(range(42, 57))                       # ADDI-TSTI
_REG_MAP = {'A': '00', 'X': '01', 'Y': '10'}


def _reg_bit(operand: str) -> str:
    """Return '0' for X register, '1' for Y register (regaddr field)."""
    return '0' if operand.strip().upper() == 'X' else '1'


def to_twos_complement(value, bits):
    """Convert signed integer to two's complement binary string."""
    min_val = -(1 << (bits - 1))
    max_val = (1 << (bits - 1)) - 1
    if not (min_val <= value <= max_val):
        raise ValueError(f"Immediate {value} out of {bits}-bit signed range [{min_val}, {max_val}]")
    if value < 0:
        value = (1 << bits) + value
    return format(value, f'0{bits}b')


def parse_operand(operand):
    """Strip trailing comma from operand."""
    return operand.rstrip(',')


def extract_label(instruction, line_number, labels):
    """Extract and store label if present, return True if found."""
    words = instruction.split()
    if words and words[0].endswith(':'):
        labels[words[0][:-1]] = line_number
        return True
    return False


def _require_words(words, n, opcode):
    """Raise ValueError if words has fewer than n tokens (opcode + n-1 operands)."""
    if len(words) < n:
        raise ValueError(f"'{opcode}' requires {n - 1} operand(s), got {len(words) - 1}")


def encode_instruction(instruction, labels):
    """Encode one assembly instruction to a 16-bit binary string."""
    words = instruction.split()
    opcode = words[0].upper()
    if opcode not in OPCODE:
        raise ValueError(f"Unknown opcode: '{opcode}'")
    binary = OPCODE[opcode]
    op_value = int(binary, 2)

    # END, RET, MINE, NOP, EI, DI, IRET, WAIT — no operand
    if op_value in _OP_NO_OPERAND:
        return binary + '0' * 10

    # LD, ST — opcode + reg_bit(0=X,1=Y) + 9-bit address
    if op_value in _OP_MEMORY:
        _require_words(words, 3, opcode)
        address = format(int(parse_operand(words[2])), '09b')
        return binary + _reg_bit(parse_operand(words[1])) + address

    # IN, OUT — opcode + 10-bit port address
    if op_value in _OP_IO:
        _require_words(words, 2, opcode)
        port_val = int(parse_operand(words[1]))
        if not (0 <= port_val <= 1023):
            raise ValueError(f"Port address {port_val} out of range [0, 1023]")
        port = format(port_val, '010b')
        return binary + port

    # Branch instructions — opcode + 10-bit label address
    if op_value in _OP_BRANCH:
        _require_words(words, 2, opcode)
        if words[1] not in labels:
            raise ValueError(f"Undefined label: '{words[1]}'")
        address = format(labels[words[1]], '010b')
        return binary + address

    # MOVR — opcode + src_reg(2) + dst_reg(2) + 000000
    if op_value == 29:
        _require_words(words, 3, opcode)
        dst_name = parse_operand(words[1]).upper()
        src_name = parse_operand(words[2]).upper()
        if dst_name not in _REG_MAP:
            raise ValueError(f"Unknown register '{dst_name}' in MOVR (expected A, X, or Y)")
        if src_name not in _REG_MAP:
            raise ValueError(f"Unknown register '{src_name}' in MOVR (expected A, X, or Y)")
        dst_reg = _REG_MAP[dst_name]
        src_reg = _REG_MAP[src_name]
        return binary + src_reg + dst_reg + '000000'

    # MOV — opcode + reg_bit + 9-bit signed immediate
    if op_value == 25:
        _require_words(words, 3, opcode)
        immediate = to_twos_complement(int(parse_operand(words[2])), 9)
        return binary + _reg_bit(parse_operand(words[1])) + immediate

    # ADD-TST, INC, DEC, PUSH, POP — opcode + reg_bit + 9 zeros
    if op_value in _OP_REG_ARITH:
        _require_words(words, 2, opcode)
        return binary + _reg_bit(parse_operand(words[1])) + '0' * 9

    # MOVI — opcode + 0 + 9-bit signed immediate
    if opcode == 'MOVI':
        _require_words(words, 2, opcode)
        immediate = to_twos_complement(int(words[1]), 9)
        return binary + '0' + immediate

    # ADDI-TSTI — opcode + 0 + 9-bit signed immediate
    if op_value in _OP_IMM_ARITH:
        _require_words(words, 2, opcode)
        immediate = to_twos_complement(int(words[1]), 9)
        return binary + '0' + immediate

    return binary


def assemble(input_file, output_file):
    """Assemble source file to binary machine code."""
    # Read and clean input
    with open(input_file) as f:
        lines = [line.strip() for line in f]

    # First pass: extract labels and count instruction addresses
    labels = {}
    cleaned_lines = []
    instruction_address = 0

    for line in lines:
        # Remove comments (everything after ; or #)
        if ';' in line:
            line = line[:line.index(';')].strip()
        if '#' in line:
            line = line[:line.index('#')].strip()

        # Skip empty lines
        if not line:
            continue

        # Handle labels
        if ':' in line:
            label_end = line.index(':')
            label_name = line[:label_end].strip()
            labels[label_name] = instruction_address
            line = line[label_end + 1:].strip()
            if not line:
                continue

        cleaned_lines.append(line)
        instruction_address += 1

    if instruction_address > MEMORY_SIZE:
        raise ValueError(f"Program too large: {instruction_address} instructions exceed memory size of {MEMORY_SIZE}")

    # Second pass: encode instructions and write output
    with open(output_file, 'w') as f:
        for instruction in cleaned_lines:
            f.write(encode_instruction(instruction, labels) + '\n')

        # Pad with zeros to fill memory
        remaining = MEMORY_SIZE - instruction_address
        for _ in range(remaining):
            f.write('0' * 16 + '\n')


if __name__ == "__main__":
    import sys

    # Parse command line arguments
    if len(sys.argv) >= 3:
        assemble(sys.argv[1], sys.argv[2])
    else:
        assemble("input.txt", "output.txt")
