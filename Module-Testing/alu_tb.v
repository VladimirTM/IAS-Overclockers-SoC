`timescale 1ns/1ps

// 16-bit ALU Comprehensive Testbench
// Tests all 14 operations: arithmetic, logical, shift/rotate, and compare
// Verifies sequential 3-cycle input protocol and flag generation

module ALU_tb;

    reg clk;
    reg rst_b;
    reg start;
    reg [15:0] INBUS;
    wire [15:0] OUTBUS;
    wire Z, N, C, O, EXC, END;

    integer test_count;
    integer pass_count;
    integer fail_count;

    // Instantiate ALU
    ALU dut (
        .clk(clk),
        .rst_b(rst_b),
        .start(start),
        .INBUS(INBUS),
        .OUTBUS(OUTBUS),
        .Z(Z),
        .N(N),
        .C(C),
        .O(O),
        .EXC(EXC),
        .END(END)
    );

    // Clock generation - 10ns period (100MHz)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Waveform dumping
    initial begin
        $dumpfile("alu_test.vcd");
        $dumpvars(0, ALU_tb);
        $dumpvars(0, dut.seq);
        $dumpvars(0, dut.decoder);
        $dumpvars(0, dut.cu);
    end

    // Task to check and report test result
    task check_test;
        input [255:0] test_name;
        input pass;
        begin
            test_count = test_count + 1;
            if (pass) begin
                $display("Test %2d PASS: %s", test_count, test_name);
                pass_count = pass_count + 1;
            end else begin
                $display("Test %2d FAIL: %s", test_count, test_name);
                $display("         Expected result match or flags correct");
                $display("         Got: OUTBUS=%h, Z=%b N=%b C=%b O=%b", OUTBUS, Z, N, C, O);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // Task to perform ALU operation with sequential protocol
    task alu_operation;
        input [5:0] opcode;
        input [15:0] operand1;
        input [15:0] operand2;
        integer wait_cycles;
        begin
            // Cycle 1: Set up opcode and start BEFORE clock edge
            start = 1'b1;
            INBUS = {10'd0, opcode};
            @(posedge clk);
            #1; // Let signals settle

            // Cycle 2: Set up operand1 BEFORE clock edge
            INBUS = operand1;
            @(posedge clk);
            #1;

            // Cycle 3: Set up operand2 BEFORE clock edge
            INBUS = operand2;
            @(posedge clk);
            #1;

            // Wait one more cycle for sequencer to reach DONE
            @(posedge clk);
            #1;

            // Wait for END signal (with timeout)
            wait_cycles = 0;
            while (END == 1'b0 && wait_cycles < 100) begin
                @(posedge clk);
                wait_cycles = wait_cycles + 1;
                // Debug: Print first few cycles for logic/shift tests
                if (wait_cycles <= 10 && test_count >= 14 && test_count <= 16) begin
                    #1;
                    $display("    Cycle %0d: core_start=%b op_type=%d FSM_st=%b l0=%b l1=%b logic_result=%h OUTBUS=%h END=%b",
                             wait_cycles, dut.core_start, dut.operation_type, dut.cu.st, dut.l0, dut.l1, dut.logic_result, OUTBUS, END);
                end
            end

            if (wait_cycles >= 100) begin
                $display("  [ERROR] Timeout waiting for END signal!");
                $display("  Final: core_start=%b op_type=%d FSM=%b",
                         dut.core_start, dut.operation_type, dut.cu.st);
            end

            // Wait one more clock cycle and let signals settle
            @(posedge clk);
            #1; // Small delay to allow outputs to settle

            // Deassert start and allow settling
            start = 1'b0;
            repeat(2) @(posedge clk);
        end
    endtask

    // Main test sequence
    initial begin
        $display("========================================");
        $display("16-bit ALU Comprehensive Test");
        $display("========================================\n");

        test_count = 0;
        pass_count = 0;
        fail_count = 0;

        // Initialize
        rst_b = 0;
        start = 0;
        INBUS = 0;
        #15;
        rst_b = 1;
        #10;

        // ===== Arithmetic Operations =====
        $display("=== Arithmetic Operations ===");

        // Test 1: ADD 100 + 50 = 150
        alu_operation(6'b001010, 16'd100, 16'd50);
        check_test("ADD: 100 + 50 = 150", OUTBUS == 16'd150 && Z == 0 && O == 0);

        // Test 2: ADD with overflow (32767 + 1 = -32768)
        alu_operation(6'b001010, 16'h7FFF, 16'h0001);
        check_test("ADD: Overflow (32767+1)", OUTBUS == 16'h8000 && N == 1 && O == 1);

        // Test 3: ADD with carry (65535 + 1 = 0)
        alu_operation(6'b001010, 16'hFFFF, 16'h0001);
        check_test("ADD: Carry (65535+1=0)", OUTBUS == 16'h0000 && Z == 1 && C == 1);

        // Test 4: SUB 100 - 50 = 50
        alu_operation(6'b001011, 16'd100, 16'd50);
        check_test("SUB: 100 - 50 = 50", OUTBUS == 16'd50 && Z == 0);

        // Test 5: SUB result negative (50 - 100 = -50)
        alu_operation(6'b001011, 16'd50, 16'd100);
        check_test("SUB: 50 - 100 (negative)", OUTBUS == 16'hFFCE && N == 1);

        // Test 6: SUB result zero (100 - 100 = 0)
        alu_operation(6'b001011, 16'd100, 16'd100);
        check_test("SUB: 100 - 100 = 0", OUTBUS == 16'd0 && Z == 1);

        // Test 7: MUL 100 * 50 = 5000
        alu_operation(6'b001100, 16'd100, 16'd50);
        check_test("MUL: 100 * 50 = 5000", OUTBUS == 16'd5000);

        // Test 8: MUL 200 * 200 = 40000
        alu_operation(6'b001100, 16'd200, 16'd200);
        check_test("MUL: 200 * 200 = 40000", OUTBUS == 16'd40000);

        // Test 9: MUL small (5 * 3 = 15)
        alu_operation(6'b001100, 16'd5, 16'd3);
        check_test("MUL: 5 * 3 = 15", OUTBUS == 16'd15);

        // Test 10: DIV 100 / 10 = 10
        alu_operation(6'b001101, 16'd100, 16'd10);
        check_test("DIV: 100 / 10 = 10", OUTBUS == 16'd10);

        // Test 11: DIV 212 / 5 = 42
        alu_operation(6'b001101, 16'd212, 16'd5);
        check_test("DIV: 212 / 5 = 42", OUTBUS == 16'd42);

        // Test 12: DIV 1000 / 7 = 142
        alu_operation(6'b001101, 16'd1000, 16'd7);
        $display("[DEBUG] After Test 12 (DIV): FSM state=%b A0=%b D11=%b END=%b",
                 dut.cu.st, dut.cu.st[0], dut.cu.st[23], END);
        check_test("DIV: 1000 / 7 = 142", OUTBUS == 16'd142);

        // Test 13: MOD 107 % 10 = 7
        $display("\n[DEBUG] Test 13: MOD");
        alu_operation(6'b001110, 16'd107, 16'd10);
        $display("[DEBUG] After MOD: OUTBUS=%h operation_type=%d core_start=%b",
                 OUTBUS, dut.operation_type, dut.core_start);
        $display("[DEBUG]   FSM state vector: %b (should have exactly one 1)", dut.cu.st);
        $display("[DEBUG]   A0=%b D0=%b D10=%b d18_state=%b d17=%b END=%b",
                 dut.cu.st[0], dut.cu.st[12], dut.cu.st[22], dut.cu.st[24], dut.d17, END);
        check_test("MOD: 107 % 10 = 7", OUTBUS == 16'd7);

        // Test 14: MOD 100 % 7 = 2
        alu_operation(6'b001110, 16'd100, 16'd7);
        check_test("MOD: 100 % 7 = 2", OUTBUS == 16'd2);

        // ===== Logical Operations =====
        $display("\n=== Logical Operations ===");

        // Test 15: AND 0xF0F0 & 0x0FF0 = 0x00F0
        $display("\n[DEBUG] Test 15: AND");
        alu_operation(6'b010011, 16'hF0F0, 16'h0FF0);
        $display("[DEBUG] After AND: OUTBUS=%h operation_type=%d l1=%b END=%b",
                 OUTBUS, dut.operation_type, dut.l1, END);
        check_test("AND: F0F0 & 0FF0 = 00F0", OUTBUS == 16'h00F0);

        // Test 16: AND result zero
        alu_operation(6'b010011, 16'hFF00, 16'h00FF);
        check_test("AND: FF00 & 00FF = 0 (zero)", OUTBUS == 16'h0000 && Z == 1);

        // Test 17: OR 0xF0F0 | 0x0FF0 = 0xFFF0
        alu_operation(6'b010100, 16'hF0F0, 16'h0FF0);
        check_test("OR: F0F0 | 0FF0 = FFF0", OUTBUS == 16'hFFF0 && N == 1);

        // Test 18: OR 0x00F0 | 0x0F00 = 0x0FF0
        alu_operation(6'b010100, 16'h00F0, 16'h0F00);
        check_test("OR: 00F0 | 0F00 = 0FF0", OUTBUS == 16'h0FF0);

        // Test 19: XOR 0xFFFF ^ 0xFFFF = 0x0000
        alu_operation(6'b010101, 16'hFFFF, 16'hFFFF);
        check_test("XOR: FFFF ^ FFFF = 0 (zero)", OUTBUS == 16'h0000 && Z == 1);

        // Test 20: XOR 0xF0F0 ^ 0x0F0F = 0xFFFF
        alu_operation(6'b010101, 16'hF0F0, 16'h0F0F);
        check_test("XOR: F0F0 ^ 0F0F = FFFF", OUTBUS == 16'hFFFF && N == 1);

        // Test 21: NOT ~0xF0F0 = 0x0F0F
        alu_operation(6'b010110, 16'hF0F0, 16'h0000);
        check_test("NOT: ~F0F0 = 0F0F", OUTBUS == 16'h0F0F);

        // Test 22: NOT ~0x0000 = 0xFFFF
        alu_operation(6'b010110, 16'h0000, 16'h0000);
        check_test("NOT: ~0000 = FFFF", OUTBUS == 16'hFFFF && N == 1);

        // ===== Shift/Rotate Operations =====
        $display("\n=== Shift/Rotate Operations ===");

        // Test 23: LSL 0x0001 << 4 = 0x0010
        $display("\n[DEBUG] Test 23: LSL");
        alu_operation(6'b001111, 16'h0001, 16'd4);
        $display("[DEBUG] After LSL: OUTBUS=%h operation_type=%d sh1=%b END=%b",
                 OUTBUS, dut.operation_type, dut.sh1, END);
        check_test("LSL: 0001 << 4 = 0010", OUTBUS == 16'h0010);

        // Test 24: LSL with carry (0x8000 << 1)
        alu_operation(6'b001111, 16'h8000, 16'd1);
        check_test("LSL: 8000 << 1 (carry)", OUTBUS == 16'h0000 && Z == 1 && C == 1);

        // Test 25: LSL 0xFFFF << 8 = 0xFF00
        alu_operation(6'b001111, 16'hFFFF, 16'd8);
        check_test("LSL: FFFF << 8 = FF00", OUTBUS == 16'hFF00 && N == 1);

        // Test 26: LSR 0x1000 >> 4 = 0x0100
        alu_operation(6'b010000, 16'h1000, 16'd4);
        check_test("LSR: 1000 >> 4 = 0100", OUTBUS == 16'h0100);

        // Test 27: LSR with carry (0x0001 >> 1)
        alu_operation(6'b010000, 16'h0001, 16'd1);
        check_test("LSR: 0001 >> 1 (carry)", OUTBUS == 16'h0000 && Z == 1 && C == 1);

        // Test 28: LSR 0xFF00 >> 8 = 0x00FF
        alu_operation(6'b010000, 16'hFF00, 16'd8);
        check_test("LSR: FF00 >> 8 = 00FF", OUTBUS == 16'h00FF);

        // Test 29: RSR 0x8001 rotate right 1 = 0xC000
        alu_operation(6'b010001, 16'h8001, 16'd1);
        check_test("RSR: 8001 rotate right 1", OUTBUS == 16'hC000);

        // Test 30: RSL 0x8001 rotate left 1 = 0x0003
        alu_operation(6'b010010, 16'h8001, 16'd1);
        check_test("RSL: 8001 rotate left 1", OUTBUS == 16'h0003);

        // Test 31: Shift by 0 (no change)
        alu_operation(6'b001111, 16'h1234, 16'd0);
        check_test("LSL: 1234 << 0 = 1234", OUTBUS == 16'h1234);

        // ===== Compare Operations =====
        $display("\n=== Compare Operations ===");

        // Test 32: CMP equal (100 - 100 = 0)
        alu_operation(6'b010111, 16'd100, 16'd100);
        check_test("CMP: 100 == 100 (zero)", Z == 1);

        // Test 33: CMP less than (50 - 100 < 0)
        alu_operation(6'b010111, 16'd50, 16'd100);
        check_test("CMP: 50 < 100 (negative)", N == 1);

        // Test 34: CMP greater than (200 - 100 > 0)
        alu_operation(6'b010111, 16'd200, 16'd100);
        check_test("CMP: 200 > 100 (positive)", N == 0 && Z == 0);

        // Test 35: TST zero result (0xF0F0 & 0x0000 = 0)
        alu_operation(6'b011000, 16'hF0F0, 16'h0000);
        check_test("TST: F0F0 & 0000 (zero)", Z == 1);

        // Test 36: TST negative result (0xFFFF & 0x8000)
        alu_operation(6'b011000, 16'hFFFF, 16'h8000);
        check_test("TST: FFFF & 8000 (negative)", N == 1);

        // ===== Immediate Variants =====
        $display("\n=== Immediate Operations ===");

        // Test 37: ADDI 100 + 25 = 125
        alu_operation(6'b101010, 16'd100, 16'd25);
        check_test("ADDI: 100 + 25 = 125", OUTBUS == 16'd125);

        // Test 38: SUBI 100 - 25 = 75
        alu_operation(6'b101011, 16'd100, 16'd25);
        check_test("SUBI: 100 - 25 = 75", OUTBUS == 16'd75);

        // Test 39: MULI 10 * 10 = 100
        alu_operation(6'b101100, 16'd10, 16'd10);
        check_test("MULI: 10 * 10 = 100", OUTBUS == 16'd100);

        // Test 40: ANDI 0xFF00 & 0x00FF = 0x0000
        alu_operation(6'b110011, 16'hFF00, 16'h00FF);
        check_test("ANDI: FF00 & 00FF = 0", OUTBUS == 16'h0000 && Z == 1);

        // Test 41: LSLI 0x0001 << 8 = 0x0100
        alu_operation(6'b101111, 16'h0001, 16'd8);
        check_test("LSLI: 0001 << 8 = 0100", OUTBUS == 16'h0100);

        // ===== Edge Cases =====
        $display("\n=== Edge Cases ===");

        // Test 42: ADD zero operands
        alu_operation(6'b001010, 16'd0, 16'd0);
        check_test("ADD: 0 + 0 = 0 (zero)", OUTBUS == 16'd0 && Z == 1);

        // Test 43: ADD maximum value
        alu_operation(6'b001010, 16'hFFFF, 16'h0000);
        check_test("ADD: FFFF + 0 = FFFF", OUTBUS == 16'hFFFF && N == 1);

        // Test 44: MUL by zero
        alu_operation(6'b001100, 16'd1234, 16'd0);
        check_test("MUL: 1234 * 0 = 0", OUTBUS == 16'd0 && Z == 1);

        // Test 45: DIV by 1
        alu_operation(6'b001101, 16'd12345, 16'd1);
        check_test("DIV: 12345 / 1 = 12345", OUTBUS == 16'd12345);

        // Test 46: MOD by same number (100 % 100 = 0)
        alu_operation(6'b001110, 16'd100, 16'd100);
        check_test("MOD: 100 % 100 = 0", OUTBUS == 16'd0 && Z == 1);

        // ===== Test Summary =====
        $display("\n========================================");
        $display("Test Summary");
        $display("========================================");
        $display("Passed: %0d", pass_count);
        $display("Failed: %0d", fail_count);
        $display("Total:  %0d", test_count);

        if (fail_count == 0)
            $display("\n*** ALL TESTS PASSED! ***\n");
        else
            $display("\n*** SOME TESTS FAILED ***\n");

        $display("========================================\n");
        #100;
        $finish;
    end

    // Timeout watchdog (500us)
    initial begin
        #500000;
        $display("\n*** ERROR: Test timeout! ***");
        $finish;
    end

endmodule
