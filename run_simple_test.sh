#!/bin/bash

# Simple CPU Test Runner - Uses cpu_tb.v for basic register dump
# This is a convenience wrapper around run_cpu_test.sh for the simple testbench
#
# Usage:
#   ./run_simple_test.sh [ASM_FILE]
#
# Arguments:
#   ASM_FILE - Assembly file to compile (default: test_program.asm)
#
# Examples:
#   ./run_simple_test.sh                  # Use default test_program.asm
#   ./run_simple_test.sh my_test.asm      # Run with custom assembly file

# Default assembly file
ASM_FILE="${1:-test_program.asm}"

echo "========================================"
echo "Simple CPU Test (Register Dump)"
echo "  ASM file: $ASM_FILE"
echo "  Testbench: cpu_tb.v (root)"
echo "========================================"
echo ""

# Run the test with cpu_tb.v (in root directory)
./run_cpu_test.sh "$ASM_FILE" cpu_tb.v
