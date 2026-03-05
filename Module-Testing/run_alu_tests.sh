#!/bin/bash
# ALU Test Runner Script

echo "========================================="
echo "16-bit ALU Comprehensive Test Suite"
echo "========================================="
echo ""

echo "Compiling ALU modules and testbench..."
iverilog -o alu_test alu_tb.v ../ALU/ALU.v ../ALU/controlUnit.v ../ALU/input_sequencer.v ../ALU/opcode_decoder.v ../ALU/logic_unit.v ../ALU/barrel_shifter.v ../ALU/flag_generator.v ../ALU/rcas.v ../ALU/rca.v ../ALU/mux.v ../ALU/fac.v ../ALU/rgst.v ../ALU/count.v ../ALU/SRT4_PLA.v

if [ $? -eq 0 ]; then
    echo "Compilation successful!"
    echo ""
    echo "Running tests..."
    echo ""
    vvp alu_test
    rm -f alu_test alu_test.vcd
    echo ""
    echo "Test run complete!"
else
    echo "Compilation failed!"
    exit 1
fi
