#!/bin/bash

# 1. CONFIGURATION: 
# Set the relative path to your design modules here.
DESIGN_DIR="../CPU"
# Set the name of the testbench file you want to SKIP.
# Leave empty "" if you don't want to exclude anything.
EXCLUDE_FILE="cpu_tb.v"

echo "----------------------------------------"
echo "Starting Simulation Run"
echo "----------------------------------------"

# [cite_start]Check if the design directory actually exists [cite: 1]
if [ ! -d "$DESIGN_DIR" ]; then
    echo "Error: Design directory '$DESIGN_DIR' not found."
    exit 1
fi

rm -f *.out

for tb_file in *_tb.v; do
	# CHECK: Is this the file we want to exclude?
    if [ "$tb_file" == "$EXCLUDE_FILE" ]; then
        echo "Skipping excluded file: $tb_file"
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
        
        # [cite_start]CHANGED: Added -N flag. [cite: 1]
        # [cite_start]This prevents the simulator from entering interactive mode on $stop [cite: 1]
        vvp -N "${base_name}.out"
        
        echo "  ------------------------------------"
    else
        echo "  > Compilation FAILED for $tb_file"
    fi
    echo ""
done

# Clean up generated output files and VCD files
rm -f *.out *.vcd

echo "All simulations finished."