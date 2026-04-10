def test_assembler(expected_file, output_file="output.txt"):
    # Compare assembler output against expected file; report first differing line
    with open(output_file) as f:
        result_lines = [line.strip() for line in f.readlines() if line.strip()]

    with open(expected_file) as f:
        expected_lines = [line.strip() for line in f.readlines() if line.strip()]

        if len(expected_lines) != len(result_lines):
            print(f"[FAIL] Numar diferit de linii!")
            print(f"  Expected lines: {len(expected_lines)}")
            print(f"  Got lines:      {len(result_lines)}")
            return

        # compara fiecare linie
        all_good = True
        for i in range(len(expected_lines)):
            expected = expected_lines[i]
            result = result_lines[i]

            if expected != result:
                print(f"[DIFF] Linia {i + 1}:")
                print(f"   Expected: {expected}")
                print(f"   Got:      {result}")
                all_good = False

        if all_good:
            print("[OK] Test passed ✅ ")
        else:
            print("[FAIL] Test failed ❌")

test_assembler("expected_output2.txt")