# Makefile for CPU Testing and Assembly
# Automatically compiles all .v files from the CPU/ directory (excluding testbenches)

# Default values for dynamic parameters
ASM ?= test_program.asm
TB ?= cpu_tb.v
TB_DIR = Module-Testing

# Derive testbench path (handle both full path and basename)
TB_PATH = $(if $(findstring /,$(TB)),$(TB),$(TB_DIR)/$(TB))

# Output simulation binary name (derived from testbench name)
SIM_OUT = $(basename $(notdir $(TB)))_sim

# Default target
.PHONY: all
all: test

# Assemble a program
.PHONY: assemble
assemble:
	@if [ ! -f "$(ASM)" ]; then \
		echo "Error: Assembly file '$(ASM)' not found"; \
		exit 1; \
	fi
	@echo "Assembling $(ASM)..."
	@python3 CPU-Assembler/main.py $(ASM) data_bin.txt
	@echo "✓ Assembly complete"

# Interactive memory init: assemble program, then prompt for custom memory values
# Press ENTER at the prompt to accept defaults, or type 2 to add custom addresses
.PHONY: memory
memory:
	@if [ ! -f "$(ASM)" ]; then \
		echo "Error: Assembly file '$(ASM)' not found"; \
		exit 1; \
	fi
	@echo "Assembling $(ASM)..."
	@python3 CPU-Assembler/main.py $(ASM) data_bin_temp.txt
	@python3 data_init.py --input data_bin_temp.txt --output data_bin.txt
	@rm -f data_bin_temp.txt
	@echo "✓ Memory ready — run 'make quick' to simulate without re-assembling"

# Compile the testbench
.PHONY: compile
compile:
	@if [ ! -f "$(TB_PATH)" ]; then \
		echo "Error: Testbench file '$(TB_PATH)' not found"; \
		echo "Available testbenches in $(TB_DIR)/:"; \
		ls -1 $(TB_DIR)/*.v 2>/dev/null || echo "  (none found)"; \
		exit 1; \
	fi
	@echo "Compiling testbench: $(TB_PATH)..."
	@iverilog -o $(SIM_OUT) $(shell find CPU -name "*.v" ! -name "*_tb*.v") $(TB_PATH) >compile_errors.tmp 2>&1; \
	  istat=$$?; \
	  grep -v "warning: .readmemb\|warning: .*_tb" compile_errors.tmp || true; \
	  rm -f compile_errors.tmp; \
	  if [ $$istat -ne 0 ]; then echo "Compilation failed"; exit 1; fi
	@echo "✓ Compilation complete (output: $(SIM_OUT))"

# Run the simulation
.PHONY: run
run:
	@if [ ! -f "$(SIM_OUT)" ]; then \
		echo "Error: Simulation binary '$(SIM_OUT)' not found. Run 'make compile' first."; \
		exit 1; \
	fi
	@echo "Running simulation: $(SIM_OUT)..."
	@vvp $(SIM_OUT)

# Full test: assemble, init memory, compile, and run
.PHONY: test
test:
	@echo "========================================"
	@echo "Running Full CPU Test Suite"
	@echo "  ASM file: $(ASM)"
	@echo "  Testbench: $(TB_PATH)"
	@echo "========================================"
	@echo ""
	@if [ ! -f "$(ASM)" ]; then \
		echo "Error: Assembly file '$(ASM)' not found"; \
		exit 1; \
	fi
	@if [ ! -f "$(TB_PATH)" ]; then \
		echo "Error: Testbench file '$(TB_PATH)' not found"; \
		echo "Available testbenches in $(TB_DIR)/:"; \
		ls -1 $(TB_DIR)/*.v 2>/dev/null || echo "  (none found)"; \
		exit 1; \
	fi
	@python3 CPU-Assembler/main.py $(ASM) data_bin_temp.txt
	@python3 data_init.py --input data_bin_temp.txt --output data_bin.txt --defaults
	@iverilog -o $(SIM_OUT) $(shell find CPU -name "*.v" ! -name "*_tb*.v") $(TB_PATH) >compile_errors.tmp 2>&1; \
	  istat=$$?; \
	  grep -v "warning: .readmemb\|warning: .*_tb" compile_errors.tmp || true; \
	  rm -f compile_errors.tmp; \
	  if [ $$istat -ne 0 ]; then echo "Compilation failed"; exit 1; fi
	@echo ""
	@vvp $(SIM_OUT)
	@rm -f data_bin_temp.txt

# Assemble a custom program (usage: make asm PROGRAM=myprogram.asm)
.PHONY: asm
asm:
	@if [ -z "$(PROGRAM)" ]; then \
		echo "Error: Please specify PROGRAM=yourfile.asm"; \
		exit 1; \
	fi
	@echo "Assembling $(PROGRAM)..."
	@python3 CPU-Assembler/main.py $(PROGRAM) data_bin.txt
	@echo "✓ Assembly complete"

# Quick test (compile and run without reassembly)
.PHONY: quick
quick: compile run

# Simple test (uses root cpu_tb.v for basic register dump)
.PHONY: simple
simple:
	@echo "========================================"
	@echo "Running Simple CPU Test"
	@echo "  ASM file: $(ASM)"
	@echo "  Testbench: cpu_tb.v (root)"
	@echo "========================================"
	@echo ""
	@python3 CPU-Assembler/main.py $(ASM) data_bin_temp.txt
	@python3 data_init.py --input data_bin_temp.txt --output data_bin.txt --defaults
	@iverilog -o cpu_tb_sim $(shell find CPU -name "*.v" ! -name "*_tb*.v") cpu_tb.v >compile_errors.tmp 2>&1; \
	  istat=$$?; \
	  grep -v "warning: .readmemb\|warning: .*_tb" compile_errors.tmp || true; \
	  rm -f compile_errors.tmp; \
	  if [ $$istat -ne 0 ]; then echo "Compilation failed"; exit 1; fi
	@echo ""
	@vvp cpu_tb_sim
	@rm -f data_bin_temp.txt

# Run all module-level unit testbenches
.PHONY: modules
modules:
	@cd $(TB_DIR) && bash run_all_testbenches.sh

# Run module tests then CPU integration test, with a combined summary
.PHONY: test-all
test-all:
	@module_out=$$(cd $(TB_DIR) && bash run_all_testbenches.sh 2>&1); \
	 echo "$$module_out"; \
	 mod_pass=$$(echo "$$module_out" | grep "Total Tests PASS" | grep -oE '[0-9]+$$'); \
	 mod_fail=$$(echo "$$module_out" | grep "Total Tests FAIL" | grep -oE '[0-9]+$$'); \
	 mod_pass=$${mod_pass:-0}; mod_fail=$${mod_fail:-0}; \
	 echo ""; \
	 cpu_out=$$($(MAKE) --no-print-directory test 2>&1); \
	 echo "$$cpu_out"; \
	 cpu_pass=$$(echo "$$cpu_out" | grep "^  Pass:" | grep -oE '[0-9]+$$'); \
	 cpu_fail=$$(echo "$$cpu_out" | grep "^  Fail:" | grep -oE '[0-9]+$$'); \
	 cpu_pass=$${cpu_pass:-0}; cpu_fail=$${cpu_fail:-0}; \
	 total_pass=$$((mod_pass + cpu_pass)); \
	 total_fail=$$((mod_fail + cpu_fail)); \
	 echo ""; \
	 echo "========================================"; \
	 echo "           COMBINED SUMMARY             "; \
	 echo "========================================"; \
	 printf "  Module tests    %4d pass  %2d fail\n" $$mod_pass $$mod_fail; \
	 printf "  CPU integration %4d pass  %2d fail\n" $$cpu_pass $$cpu_fail; \
	 echo "  ----------------------------------------"; \
	 printf "  Total           %4d pass  %2d fail\n" $$total_pass $$total_fail; \
	 if [ "$$total_fail" -eq 0 ]; then \
	   echo "  Result: ALL TESTS PASSED!"; \
	 else \
	   echo "  Result: $$total_fail TESTS FAILED"; \
	   exit 1; \
	 fi; \
	 echo "========================================"

# Clean generated files
.PHONY: clean
clean:
	@echo "Cleaning generated files..."
	@rm -f cpu_tb_sim memory_tb_sim a_tb_sim x_tb_sim y_tb_sim dr_tb_sim
	@rm -f *_tb_sim cpu_all_instructions_tb.vcd
	@rm -f data_bin_temp.txt
	@rm -f *.vcd
	@echo "✓ Clean complete"

# Deep clean (removes data_bin.txt too - use with caution)
.PHONY: distclean
distclean: clean
	@echo "Deep cleaning (removes assembled binaries)..."
	@rm -f data_bin.txt
	@echo "✓ Deep clean complete - run 'make test' to rebuild"

# View waveform (requires gtkwave)
.PHONY: wave
wave:
	@if [ -f cpu_all_instructions_tb.vcd ]; then \
		gtkwave cpu_all_instructions_tb.vcd & \
	else \
		echo "Error: No waveform file found. Run 'make test' first."; \
	fi

# Show help
.PHONY: help
help:
	@echo "Available targets:"
	@echo "  make test                              - Full test with comprehensive testbench"
	@echo "  make test ASM=file.asm                 - Test with custom ASM file"
	@echo "  make test TB=testbench.v               - Test with custom testbench"
	@echo "  make test ASM=file.asm TB=testbench.v  - Test with both custom"
	@echo ""
	@echo "  make modules                           - Run all module unit testbenches"
	@echo "  make test-all                          - Run module tests then CPU integration test"
	@echo ""
	@echo "  make simple                            - Simple test (shows register dump)"
	@echo "  make simple ASM=file.asm               - Simple test with custom ASM file"
	@echo ""
	@echo "  make memory                            - Assemble + interactive memory init (Enter=defaults)"
	@echo "  make memory ASM=file.asm               - Same with custom ASM file"
	@echo ""
	@echo "  make assemble                          - Assemble default ASM file"
	@echo "  make assemble ASM=file.asm             - Assemble custom ASM file"
	@echo "  make compile                           - Compile default testbench"
	@echo "  make compile TB=testbench.v            - Compile custom testbench"
	@echo "  make run                               - Run the simulation"
	@echo "  make quick                             - Compile and run (skip assembly)"
	@echo ""
	@echo "  make asm PROGRAM=file.asm              - Assemble a custom program (legacy)"
	@echo "  make clean                             - Remove generated files"
	@echo "  make distclean                         - Deep clean (removes assembled binaries)"
	@echo "  make wave                              - View waveform with gtkwave"
	@echo "  make help                              - Show this help message"
	@echo ""
	@echo "Current defaults:"
	@echo "  ASM file: $(ASM)"
	@echo "  Testbench: $(TB_PATH)"
	@echo ""
	@echo "Available testbenches in $(TB_DIR)/:"
	@ls -1 $(TB_DIR)/*.v 2>/dev/null | sed 's|$(TB_DIR)/||' || echo "  (none found)"
