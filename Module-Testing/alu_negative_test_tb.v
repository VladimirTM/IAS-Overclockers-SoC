`timescale 1ns/1ps

// Negative Number Test for 16-bit ALU
// Tests signed arithmetic operations with negative operands

module alu_negative_test_tb;

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

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Task to check test result
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
                $display("         Got: OUTBUS=%h, Z=%b N=%b C=%b O=%b", OUTBUS, Z, N, C, O);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // Task to perform ALU operation
    task alu_operation;
        input [5:0] opcode;
        input [15:0] operand1;
        input [15:0] operand2;
        integer wait_cycles;
        begin
            start = 1'b1;
            INBUS = {10'd0, opcode};
            @(posedge clk);
            #1;

            INBUS = operand1;
            @(posedge clk);
            #1;

            INBUS = operand2;
            @(posedge clk);
            #1;

            @(posedge clk);
            #1;

            wait_cycles = 0;
            while (END == 1'b0 && wait_cycles < 100) begin
                @(posedge clk);
                wait_cycles = wait_cycles + 1;
            end

            if (wait_cycles >= 100) begin
                $display("  [ERROR] Timeout!");
            end

            @(posedge clk);
            #1;

            start = 1'b0;
            repeat(2) @(posedge clk);
        end
    endtask

    // Main test sequence
    initial begin
        $display("========================================");
        $display("16-bit ALU Negative Number Tests");
        $display("========================================\n");

        test_count = 0;
        pass_count = 0;
        fail_count = 0;

        // Reset
        rst_b = 0;
        start = 0;
        INBUS = 0;
        repeat(5) @(posedge clk);
        rst_b = 1;
        repeat(2) @(posedge clk);

        $display("=== Signed Subtraction ===");
        // Test 1: 50 - 100 = -50 (0xFFCE)
        alu_operation(6'b001011, 16'd50, 16'd100);
        check_test("SUB: 50 - 100 = -50", OUTBUS == 16'hFFCE && N == 1);

        // Test 2: 0 - 100 = -100 (0xFF9C)
        alu_operation(6'b001011, 16'd0, 16'd100);
        check_test("SUB: 0 - 100 = -100", OUTBUS == 16'hFF9C && N == 1);

        // Test 3: -50 - 50 = -100 (using two's complement input)
        alu_operation(6'b001011, 16'hFFCE, 16'd50);
        check_test("SUB: -50 - 50 = -100", OUTBUS == 16'hFF9C && N == 1);

        $display("\n=== Signed Addition ===");
        // Test 4: -10 + 5 = -5 (0xFFF6 + 0x0005 = 0xFFFB)
        alu_operation(6'b001010, 16'hFFF6, 16'h0005);
        check_test("ADD: -10 + 5 = -5", OUTBUS == 16'hFFFB && N == 1);

        // Test 5: -50 + 100 = 50
        alu_operation(6'b001010, 16'hFFCE, 16'd100);
        check_test("ADD: -50 + 100 = 50", OUTBUS == 16'd50 && N == 0);

        // Test 6: -10 + -5 = -15 (0xFFF6 + 0xFFFB = 0xFFF1)
        alu_operation(6'b001010, 16'hFFF6, 16'hFFFB);
        check_test("ADD: -10 + -5 = -15", OUTBUS == 16'hFFF1 && N == 1);

        $display("\n=== Signed Multiplication ===");
        // Test 7: -10 * 5 = -50 (0xFFF6 * 0x0005 = 0xFFCE)
        alu_operation(6'b001100, 16'hFFF6, 16'd5);
        check_test("MUL: -10 * 5 = -50", OUTBUS == 16'hFFCE && N == 1);

        // Test 8: 10 * -5 = -50 (0x000A * 0xFFFB = 0xFFCE)
        alu_operation(6'b001100, 16'd10, 16'hFFFB);
        check_test("MUL: 10 * -5 = -50", OUTBUS == 16'hFFCE && N == 1);

        // Test 9: -10 * -5 = 50 (0xFFF6 * 0xFFFB = 0x0032)
        alu_operation(6'b001100, 16'hFFF6, 16'hFFFB);
        check_test("MUL: -10 * -5 = 50", OUTBUS == 16'd50 && N == 0);

        $display("\n=== Signed Division ===");
        // Test 10: -100 / 10 = -10 (0xFF9C / 0x000A = 0xFFF6)
        alu_operation(6'b001101, 16'hFF9C, 16'd10);
        check_test("DIV: -100 / 10 = -10", OUTBUS == 16'hFFF6 && N == 1);

        // Test 11: 100 / -10 = -10 (0x0064 / 0xFFF6 = 0xFFF6)
        alu_operation(6'b001101, 16'd100, 16'hFFF6);
        check_test("DIV: 100 / -10 = -10", OUTBUS == 16'hFFF6 && N == 1);

        // Test 12: -100 / -10 = 10 (0xFF9C / 0xFFF6 = 0x000A)
        alu_operation(6'b001101, 16'hFF9C, 16'hFFF6);
        check_test("DIV: -100 / -10 = 10", OUTBUS == 16'd10 && N == 0);

        $display("\n=== Signed Comparison ===");
        // Test 13: CMP -50 with -100 (should be positive, -50 > -100)
        alu_operation(6'b010111, 16'hFFCE, 16'hFF9C);
        check_test("CMP: -50 > -100 (positive)", N == 0 && Z == 0);

        // Test 14: CMP -100 with -50 (should be negative, -100 < -50)
        alu_operation(6'b010111, 16'hFF9C, 16'hFFCE);
        check_test("CMP: -100 < -50 (negative)", N == 1 && Z == 0);

        // Test 15: CMP -50 with -50 (should be zero)
        alu_operation(6'b010111, 16'hFFCE, 16'hFFCE);
        check_test("CMP: -50 == -50 (zero)", Z == 1);

        $display("\n=== Signed Division Edge Cases ===");
        // Test 16: Most negative number / 1 = most negative
        alu_operation(6'b001101, 16'h8000, 16'd1);
        check_test("DIV: -32768 / 1 = -32768", OUTBUS == 16'h8000 && N == 1);

        // Test 17: Positive max / -1 = negative max - 1
        alu_operation(6'b001101, 16'h7FFF, 16'hFFFF);
        check_test("DIV: 32767 / -1 = -32767", OUTBUS == 16'h8001 && N == 1);

        // Test 18: -1 / -1 = 1
        alu_operation(6'b001101, 16'hFFFF, 16'hFFFF);
        check_test("DIV: -1 / -1 = 1", OUTBUS == 16'd1 && N == 0);

        // Test 19: -1 / 1 = -1
        alu_operation(6'b001101, 16'hFFFF, 16'd1);
        check_test("DIV: -1 / 1 = -1", OUTBUS == 16'hFFFF && N == 1);

        // Test 20: 1 / -1 = -1
        alu_operation(6'b001101, 16'd1, 16'hFFFF);
        check_test("DIV: 1 / -1 = -1", OUTBUS == 16'hFFFF && N == 1);

        // Test 21: Division with truncation towards zero: -100 / 3 = -33
        alu_operation(6'b001101, 16'hFF9C, 16'd3);
        check_test("DIV: -100 / 3 = -33 (trunc)", OUTBUS == 16'hFFDF && N == 1);

        // Test 22: Division with truncation: 100 / -3 = -33
        alu_operation(6'b001101, 16'd100, 16'hFFFD);
        check_test("DIV: 100 / -3 = -33 (trunc)", OUTBUS == 16'hFFDF && N == 1);

        // Test 23: -7 / 2 = -3 (truncate towards zero)
        alu_operation(6'b001101, 16'hFFF9, 16'd2);
        check_test("DIV: -7 / 2 = -3", OUTBUS == 16'hFFFD && N == 1);

        // Test 24: Division by power of 2: -16 / 4 = -4
        alu_operation(6'b001101, 16'hFFF0, 16'd4);
        check_test("DIV: -16 / 4 = -4", OUTBUS == 16'hFFFC && N == 1);

        // Summary
        $display("\n========================================");
        $display("Test Summary");
        $display("========================================");
        $display("Passed: %0d", pass_count);
        $display("Failed: %0d", fail_count);
        $display("Total:  %0d", test_count);
        $display("========================================");

        if (fail_count == 0) begin
            $display("\n*** ALL NEGATIVE NUMBER TESTS PASSED! ***\n");
        end else begin
            $display("\n*** SOME TESTS FAILED ***\n");
        end

        $display("========================================\n");
        $finish;
    end

    // Timeout watchdog
    initial begin
        #100000;
        $display("\n*** ERROR: Test timeout! ***");
        $finish;
    end

endmodule
