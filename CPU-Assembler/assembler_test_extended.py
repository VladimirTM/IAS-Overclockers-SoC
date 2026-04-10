"""
Extended assembler test — verifies encoding of instructions not covered by
assembler_test.py / input2.txt:
  EI, DI, IRET, WAIT  (interrupt instructions, v3.1)
  IN, OUT              (I/O instructions)
  BRA                  (branch with label resolution)
  MOVI, ADDI, LSLI     (immediate operands)
"""
import os
import sys

# Locate files relative to this script
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
INPUT_FILE    = os.path.join(SCRIPT_DIR, "test_input_extended.asm")
OUTPUT_FILE   = os.path.join(SCRIPT_DIR, "output_extended.txt")
EXPECTED_FILE = os.path.join(SCRIPT_DIR, "expected_extended.txt")

# Run the assembler
sys.path.insert(0, SCRIPT_DIR)
from main import assemble

try:
    assemble(INPUT_FILE, OUTPUT_FILE)
except Exception as exc:
    print(f"[FAIL] Assembler raised: {exc}")
    sys.exit(1)

# Compare output against expected
with open(OUTPUT_FILE) as f:
    result_lines = [l.strip() for l in f if l.strip()]

with open(EXPECTED_FILE) as f:
    expected_lines = [l.strip() for l in f if l.strip()]

if len(result_lines) != len(expected_lines):
    print(f"[FAIL] Line count mismatch: expected {len(expected_lines)}, got {len(result_lines)}")
    sys.exit(1)

failed = 0
for i, (exp, got) in enumerate(zip(expected_lines, result_lines)):
    if exp != got:
        print(f"[DIFF] Line {i + 1}: expected {exp!r}, got {got!r}")
        failed += 1

if failed == 0:
    total = len(expected_lines)
    print(f"[OK] All {total} lines match")
    print(f"     EI/DI/IRET/WAIT/IN/OUT/BRA/MOVI/ADDI/LSLI encoding verified ✅")
else:
    print(f"[FAIL] {failed} line(s) differ — see diffs above")
    sys.exit(1)
