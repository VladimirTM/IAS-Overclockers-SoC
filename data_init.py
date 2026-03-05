#!/usr/bin/env python3
"""
Script to initialize memory with test data for CPU testbench.
This script allows dynamic initialization of memory addresses with custom values.

Usage:
  python3 data_init.py                                    # Interactive mode, creates empty memory
  python3 data_init.py --input file.txt --output out.txt  # Read assembled program, apply inits
  python3 data_init.py --defaults                         # Non-interactive, use defaults only
"""

import sys
import os
import argparse


def initialize_memory(input_file=None, output_file='data_bin.txt', non_interactive=False):
    """Initialize memory with test data.

    Args:
        input_file: Path to assembled program (if provided, reads this first)
        output_file: Path to output file
        non_interactive: If True, skip prompts and use defaults only
    """

    # Read existing binary or create empty memory space
    if input_file and os.path.exists(input_file):
        with open(input_file, 'r') as f:
            lines = [line.strip() for line in f.readlines()]
        print(f"Loaded assembled program from {input_file} ({len(lines)} lines)")
    else:
        lines = []
        if input_file:
            print(f"Warning: Input file '{input_file}' not found, starting with empty memory")

    # Ensure we have 1024 lines (full memory space)
    while len(lines) < 1024:
        lines.append('0' * 16)

    # Default values (backward compatibility)
    default_initializations = {
        284: 15,      # Memory[284] = 0x000F (initial X value)
        285: 7,       # Memory[285] = 0x0007 (initial Y value)
        496: 0x1234,  # Memory[496] = 0x1234 (data to hash)
        497: 0        # Memory[497] = 0x0000 (starting nonce)
    }

    print("=" * 50)
    print("Memory Initialization Tool")
    print("=" * 50)
    print()
    print("Default memory values:")
    for addr, val in sorted(default_initializations.items()):
        print(f"  Address {addr} (0x{addr:03X}): {val} (0x{val:04X})")
    print()
    print("Options:")
    print("  1. Use defaults (press ENTER)")
    print("  2. Add custom memory initializations")
    print()

    # Check if running non-interactively (pipe or --defaults flag)
    if non_interactive or not sys.stdin.isatty() or os.environ.get('NON_INTERACTIVE') == '1':
        print("Running in non-interactive mode - using defaults")
        choice = "1"
    else:
        choice = input("Your choice (1 or 2, default=1): ").strip()

    # Start with defaults
    initializations = default_initializations.copy()

    if choice == "2":
        print()
        print("Enter memory initializations (address and value).")
        print("Address range: 0-1023 (decimal or 0xHEX)")
        print("Value range: -32768 to 65535 (decimal, 0xHEX, or negative)")
        print("  Negative values are stored as 16-bit two's complement")
        print("Type 'done' when finished, 'list' to see current values.")
        print()

        while True:
            try:
                addr_input = input("Enter address (or 'done'/'list'): ").strip()

                if addr_input.lower() == 'done':
                    break

                if addr_input.lower() == 'list':
                    print("\nCurrent memory initializations:")
                    for addr, val in sorted(initializations.items()):
                        # Show signed interpretation if MSB is set
                        if val >= 0x8000:
                            signed_val = val - 0x10000
                            print(f"  Address {addr} (0x{addr:03X}): {signed_val} (0x{val:04X})")
                        else:
                            print(f"  Address {addr} (0x{addr:03X}): {val} (0x{val:04X})")
                    print()
                    continue

                # Parse address (support decimal and hex)
                if addr_input.startswith('0x') or addr_input.startswith('0X'):
                    addr = int(addr_input, 16)
                else:
                    addr = int(addr_input)

                # Validate address range
                if addr < 0 or addr >= 1024:
                    print(f"  Error: Address must be 0-1023, got {addr}")
                    continue

                # Get value
                val_input = input(f"Enter value for address {addr}: ").strip()

                # Parse value (support decimal, hex, and negative)
                if val_input.startswith('0x') or val_input.startswith('0X'):
                    val = int(val_input, 16)
                elif val_input.startswith('-0x') or val_input.startswith('-0X'):
                    val = -int(val_input[1:], 16)
                else:
                    val = int(val_input)

                # Validate value range (16-bit signed/unsigned)
                if val < -32768 or val > 65535:
                    print(f"  Error: Value must be -32768 to 65535, got {val}")
                    continue

                # Convert negative to two's complement
                if val < 0:
                    stored_val = val & 0xFFFF
                    print(f"  Set Memory[{addr}] = {val} -> 0x{stored_val:04X} (two's complement)")
                else:
                    stored_val = val
                    print(f"  Set Memory[{addr}] = {val} (0x{stored_val:04X})")

                # Store initialization
                initializations[addr] = stored_val
                print()

            except ValueError as e:
                print(f"  Error: Invalid input. Please enter numeric values.")
                print()
            except KeyboardInterrupt:
                print("\n\nInterrupted. Using current initializations.")
                break

    # Apply initializations to memory
    print()
    print("Applying memory initializations...")
    for addr, val in sorted(initializations.items()):
        lines[addr] = f'{val:016b}'
        print(f"  Memory[{addr}] (0x{addr:03X}) = {val} (0x{val:04X}) = 0b{val:016b}")

    # Write back to file
    with open(output_file, 'w') as f:
        for line in lines:
            f.write(line + '\n')

    print()
    print(f"Memory initialized successfully!")
    print(f"  Total addresses initialized: {len(initializations)}")
    print(f"  Output file: {output_file} ({len(lines)} lines)")


def main():
    parser = argparse.ArgumentParser(
        description='Initialize CPU memory with test data',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog='''
Examples:
  %(prog)s                                    # Interactive mode, creates empty memory
  %(prog)s --input assembled.txt              # Read assembled program, interactive init
  %(prog)s --input assembled.txt --output out.txt  # Specify both input and output
  %(prog)s --defaults                         # Non-interactive, use defaults only
        '''
    )
    parser.add_argument('--input', '-i', dest='input_file',
                        help='Input file containing assembled program')
    parser.add_argument('--output', '-o', dest='output_file', default='data_bin.txt',
                        help='Output file for initialized memory (default: data_bin.txt)')
    parser.add_argument('--defaults', '-d', action='store_true',
                        help='Non-interactive mode, use default values only')

    args = parser.parse_args()

    initialize_memory(
        input_file=args.input_file,
        output_file=args.output_file,
        non_interactive=args.defaults
    )


if __name__ == '__main__':
    main()
