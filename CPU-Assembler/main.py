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
    # Immediate value operations
    "MOVI": '111001',
    "ADDI": '101010', "SUBI": '101011', "MULI": '101100',
    "DIVI": '101101', "MODI": '101110',
    "LSLI": '101111', "LSRI": '110000', "RSRI": '110001', "RSLI": '110010',
    "ANDI": '110011', "ORI": '110100', "XORI": '110101', "NOTI": '110110',
    "CMPI": '110111', "TSTI": '111000',
}

MEMORY_SIZE = 1024  # Total memory lines in output file


def to_twos_complement(value, bits):
    """Convert signed integer to two's complement binary string."""
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


def encode_instruction(instruction, labels):
    """Convert assembly instruction to 16-bit binary machine code."""
    words = instruction.split()
    opcode = words[0]
    binary = OPCODE[opcode]
    op_value = int(binary, 2)

    # Instructions with no operands: END (0), RET (9), MINE (28), NOP (34)
    # Format: opcode + 10 zero bits
    if op_value in {0, 9, 28, 34}:
        return binary + '0' * 10

    # Memory operations: LD (1), ST (2)
    # Format: opcode + reg_bit (0=X, 1=Y) + 9-bit address
    if op_value in {1, 2}:
        reg_bit = '0' if parse_operand(words[1]) == 'X' else '1'
        address = format(int(parse_operand(words[2])), '09b')
        return binary + reg_bit + address

    # Branch instructions: BRA-BRO (3-7), JMP (8), BGT-BLE (30-33), BNE (37)
    # Format: opcode + 10-bit address
    if op_value == 8 or (3 <= op_value <= 7) or (30 <= op_value <= 33) or op_value == 37:
        address = format(labels[words[1]], '010b')
        return binary + address

    # MOVR (29): Register-to-register move
    # Format: opcode + src_reg (2 bits) + dst_reg (2 bits) + 6 zero bits
    if op_value == 29:
        reg_map = {'A': '00', 'X': '01', 'Y': '10'}
        dst_reg = reg_map[parse_operand(words[1]).upper()]
        src_reg = reg_map[parse_operand(words[2]).upper()]
        return binary + src_reg + dst_reg + '000000'

    # MOV instruction (25): Move immediate to register
    # Format: opcode + reg_bit (0=X, 1=Y) + 9-bit immediate value
    if op_value == 25:
        reg_bit = '0' if parse_operand(words[1]) == 'X' else '1'
        immediate = to_twos_complement(int(parse_operand(words[2])), 9)
        return binary + reg_bit + immediate

    # Register operations: ADD-TST (10-24), INC (26), DEC (27)
    # Format: opcode + reg_bit (0=X, 1=Y) + 9 zero bits
    if (10 <= op_value <= 24) or op_value in {26, 27}:
        reg_bit = '0' if parse_operand(words[1]) == 'X' else '1'
        return binary + reg_bit + '0' * 9

    # PUSH/POP register operations: PUSH (35), POP (36)
    # Format: opcode + reg_bit (0=X, 1=Y) + 9 zero bits
    if op_value in {35, 36}:
        reg_bit = '0' if parse_operand(words[1]) == 'X' else '1'
        return binary + reg_bit + '0' * 9

    # MOVI (57): Move immediate value to register
    # Format: opcode + 0 + 9-bit immediate value
    if op_value == 57:
        immediate = to_twos_complement(int(words[1]), 9)
        return binary + '0' + immediate

    # Immediate operations: ADDI-TSTI (42-56)
    # Format: opcode + 0 + 9-bit immediate value
    if 42 <= op_value <= 56:
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
        # Count instructions (all instructions are now single)
        instruction_address += 1

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
