#!/bin/bash

# CPU Test Runner Script
# This script assembles the test program, initializes memory, and runs the CPU testbench
# Automatically compiles all .v files from the CPU/ directory (excluding testbenches)
#
# Usage:
#   ./run_cpu_test.sh [ASM_FILE] [TESTBENCH_FILE]
#
# Arguments:
#   ASM_FILE        - Assembly file to compile (default: test_program.asm)
#   TESTBENCH_FILE  - Testbench to run (default: Module-Testing/cpu_tb.v)
#                     Can be just filename (e.g., cpu_tb.v) or full path
#
# Examples:
#   ./run_cpu_test.sh                          # Use defaults
#   ./run_cpu_test.sh my_test.asm              # Custom ASM, default TB
#   ./run_cpu_test.sh test_program.asm a_tb.v  # Both custom
#   ./run_cpu_test.sh "" memory_tb.v           # Default ASM, custom TB

# Function to show usage
show_usage() {
    cat << EOF
CPU Test Runner Script

Usage:
  $0 [ASM_FILE] [TESTBENCH_FILE]

Arguments:
  ASM_FILE        - Assembly file to compile (default: test_program.asm)
  TESTBENCH_FILE  - Testbench to run (default: Module-Testing/cpu_tb.v)
                    Can be just filename (e.g., cpu_tb.v) or full path

Examples:
  $0                          # Use defaults
  $0 my_test.asm              # Custom ASM, default testbench
  $0 test_program.asm a_tb.v  # Custom ASM and testbench
  $0 "" memory_tb.v           # Default ASM, custom testbench

Available testbenches in Module-Testing/:
$(ls -1 Module-Testing/*.v 2>/dev/null | sed 's|Module-Testing/||' | sed 's/^/  /' || echo "  (none found)")
EOF
    exit 0
}

# Check for help flag
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    show_usage
fi

set -e  # Exit on error

# Default values
DEFAULT_ASM="test_program.asm"
DEFAULT_TB="Module-Testing/cpu_tb.v"
TB_DIR="Module-Testing"

# Parse arguments
ASM_FILE="${1:-$DEFAULT_ASM}"
TB_FILE="${2:-$DEFAULT_TB}"

# Handle empty string as "use default"
[ "$ASM_FILE" = "" ] && ASM_FILE="$DEFAULT_ASM"
[ "$TB_FILE" = "" ] && TB_FILE="$DEFAULT_TB"

# If TB_FILE is just a filename (no path separator), check root first, then TB_DIR
if [[ "$TB_FILE" != */* ]]; then
    if [ -f "$TB_FILE" ]; then
        # File exists in root, use it
        TB_FILE="$TB_FILE"
    else
        # Look in TB_DIR
        TB_FILE="$TB_DIR/$TB_FILE"
    fi
fi

# Derive simulation output name from testbench filename
TB_BASENAME=$(basename "$TB_FILE" .v)
SIM_OUT="${TB_BASENAME}_sim"

echo "========================================"
echo "CPU Test Runner"
echo "  ASM file: $ASM_FILE"
echo "  Testbench: $TB_FILE"
echo "  Output: $SIM_OUT"
echo "========================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Validate input files exist
if [ ! -f "$ASM_FILE" ]; then
    echo -e "${RED}Error:${NC} Assembly file '$ASM_FILE' not found"
    exit 1
fi

if [ ! -f "$TB_FILE" ]; then
    echo -e "${RED}Error:${NC} Testbench file '$TB_FILE' not found"
    echo ""
    echo "Available testbenches in $TB_DIR/:"
    ls -1 "$TB_DIR"/*.v 2>/dev/null || echo "  (none found)"
    exit 1
fi

# Validate required dependencies
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}Error:${NC} python3 not found. Please install Python 3."
    exit 1
fi

if ! command -v iverilog &> /dev/null; then
    echo -e "${RED}Error:${NC} iverilog not found. Please install Icarus Verilog."
    exit 1
fi

if ! command -v vvp &> /dev/null; then
    echo -e "${RED}Error:${NC} vvp not found. Please install Icarus Verilog."
    exit 1
fi

# Step 1: Assemble the test program
echo -e "${BLUE}[1/4]${NC} Assembling $ASM_FILE..."
python3 CPU-Assembler/main.py "$ASM_FILE" data_bin_temp.txt
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓${NC} Assembly successful"
else
    echo -e "${RED}✗${NC} Assembly failed"
    exit 1
fi
echo ""

# Step 2: Initialize memory with test data (merged into assembled program)
echo -e "${BLUE}[2/4]${NC} Initializing memory with test data..."
python3 data_init.py --input data_bin_temp.txt --output data_bin.txt
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓${NC} Memory initialization successful"
else
    echo -e "${RED}✗${NC} Memory initialization failed"
    exit 1
fi
echo ""

# Step 3: Compile testbench
echo -e "${BLUE}[3/4]${NC} Compiling testbench: $TB_FILE..."
# Find all .v files in CPU directory, excluding testbenches
CPU_FILES=$(find CPU -name "*.v" ! -name "*_tb*.v")
iverilog -o "$SIM_OUT" $CPU_FILES "$TB_FILE" 2>&1 | grep -v "warning: \$readmemb\|warning: .*_tb"
compile_status=${PIPESTATUS[0]}
true
if [ $compile_status -eq 0 ]; then
    echo -e "${GREEN}✓${NC} Compilation successful (output: $SIM_OUT)"
else
    echo -e "${RED}✗${NC} Compilation failed"
    exit 1
fi
echo ""

# Step 4: Run simulation
echo -e "${BLUE}[4/4]${NC} Running testbench simulation: $SIM_OUT..."
echo "========================================"
echo ""
vvp "$SIM_OUT"
RESULT=$?
echo ""

# Cleanup temporary files
rm -f data_bin_temp.txt

# Check result
if [ $RESULT -eq 0 ]; then
    echo -e "${GREEN}✓${NC} Test completed successfully"
    exit 0
else
    echo -e "${RED}✗${NC} Test failed"
    exit 1
fi
