#!/bin/bash
# ALU Test Runner Script

echo "========================================="
echo "16-bit ALU Comprehensive Test Suite"
echo "========================================="
echo ""

echo "Compiling ALU modules and testbench..."
iverilog -o alu_test alu_tb.v ../CPU/alu.v ../CPU/controlUnit.v ../CPU/input_sequencer.v ../CPU/opcode_decoder.v ../CPU/logic_unit.v ../CPU/barrel_shifter.v ../CPU/flag_generator.v ../CPU/rcas.v ../CPU/rca.v ../CPU/mux.v ../CPU/fac.v ../CPU/rgst.v ../CPU/count.v ../CPU/SRT4_PLA.v

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
