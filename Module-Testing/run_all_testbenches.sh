#!/bin/bash

# 1. CONFIGURATION:
# Set the relative path to your design modules here.
DESIGN_DIR="../CPU"
# Set the name of the testbench file you want to SKIP.
# Leave empty "" if you don't want to exclude anything.
EXCLUDE_FILE="cpu_tb.v"

TOTAL_RUNS=0
TOTAL_PASS=0
TOTAL_FAIL=0

echo "----------------------------------------"
echo "Starting Simulation Run"
echo "----------------------------------------"

# Check if the design directory actually exists
if [ ! -d "$DESIGN_DIR" ]; then
    echo "Error: Design directory '$DESIGN_DIR' not found."
    exit 1
fi

rm -f *.out

for tb_file in *_tb.v; do
	# CHECK: Is this the file we want to exclude?
    if [ "$tb_file" == "$EXCLUDE_FILE" ]; then
        echo "Skipping excluded file: $tb_file (requires assembled program - run 'make test' instead)"
        echo ""
        continue
    fi

    base_name=$(basename "$tb_file" .v)

    echo "Processing: $tb_file"

    # 2. COMPILE:
    # We redirect stderr to stdout (2>&1) and use grep -v to hide lines with "warning".
    # We capture the exit code of iverilog specifically using PIPESTATUS.
    iverilog -o "${base_name}.out" "$tb_file" "$DESIGN_DIR"/*.v 2>&1 | grep -v "warning"

    # Capture the exit code of the FIRST command in the pipe (iverilog), not grep.
    compile_status=${PIPESTATUS[0]}

    if [ $compile_status -eq 0 ]; then
        echo "  > Compilation Successful. Running Simulation..."
        echo "  ------------------------------------"

        # -N flag prevents the simulator from entering interactive mode on $stop
        output=$(vvp -N "${base_name}.out" 2>&1)
        echo "$output"

        # Parse PASS/FAIL counts (handles "Teste PASS : N", "Passed: N", and "Pass:  N" formats)
        pass=$(echo "$output" | grep -oE '(Teste PASS|Passed|Pass)[[:space:]]*:[[:space:]]*[0-9]+' | grep -oE '[0-9]+$')
        fail=$(echo "$output" | grep -oE '(Teste FAIL|Failed|Fail)[[:space:]]*:[[:space:]]*[0-9]+' | grep -oE '[0-9]+$')
        if [ -n "$pass" ]; then
            TOTAL_PASS=$((TOTAL_PASS + pass))
            TOTAL_RUNS=$((TOTAL_RUNS + 1))
        fi
        if [ -n "$fail" ]; then
            TOTAL_FAIL=$((TOTAL_FAIL + fail))
        fi

        echo "  ------------------------------------"
    else
        echo "  > Compilation FAILED for $tb_file"
        TOTAL_FAIL=$((TOTAL_FAIL + 1))
    fi
    echo ""
done

# Clean up generated output files and VCD files
rm -f *.out *.vcd

echo "========================================"
echo "All simulations finished."
if [ "$TOTAL_PASS" -gt 0 ] || [ "$TOTAL_FAIL" -gt 0 ]; then
    echo "Total Testbenches Run : $TOTAL_RUNS"
    echo "Total Tests PASS      : $TOTAL_PASS"
    echo "Total Tests FAIL      : $TOTAL_FAIL"
fi
echo "========================================"
