//Testare rgst_tb.v

`timescale 1ns / 1ns

module rgst_tb;

    parameter W = 8;

    reg clk, rst_b, ld, clr, shftL1, shftL2, shftR1, shftR2, incr;
    reg in1;
    reg [1:0] in2;
    reg [W-1:0] d;
    wire [W-1:0] q;

    integer test_count = 0;
    integer pass_count = 0;
    integer fail_count = 0;

    rgst #(W) DUT (
        .clk(clk), .rst_b(rst_b), .ld(ld), .clr(clr),
        .shftL1(shftL1), .shftL2(shftL2), .shftR1(shftR1), .shftR2(shftR2),
        .incr(incr), .in1(in1), .in2(in2), .d(d), .q(q)
    );

    task check_test;
        input [255:0] test_name;
        input [W-1:0] expected_q;
        begin
            test_count = test_count + 1;
            if (q === expected_q) begin
                $display("Test %2d PASS: %s (Valoare: %b)", test_count, test_name, q);
                pass_count = pass_count + 1;
            end else begin
                $display("Test %2d FAIL: %s | Asteptat: %b | Actual: %b", 
                          test_count, test_name, expected_q, q);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end

    initial begin
        // --- Resetare Initiala ---
        rst_b = 0; ld = 0; clr = 0; shftL1 = 0; shftL2 = 0; 
        shftR1 = 0; shftR2 = 0; incr = 0; in1 = 0; in2 = 0; d = 0;
        #25 rst_b = 1;

        // --- TEST 1: Load (ld) ---
        @(negedge clk);
        d = 8'b1010_1010; ld = 1;
        @(negedge clk);
        ld = 0;
        check_test("Load 10101010", 8'b1010_1010);

        // --- TEST 2: Shift Left 1 bit (shftL1) ---
        // 10101010 << 1 (in1=1) -> 01010101
        @(negedge clk);
        shftL1 = 1; in1 = 1;
        @(negedge clk);
        shftL1 = 0;
        check_test("Shift Left 1 (in1=1)", 8'b0101_0101);

        // --- TEST 3: Shift Left 2 bits (shftL2) ---
        // 01010101 << 2 (in2=11) -> 01010111
        @(negedge clk);
        shftL2 = 1; in2 = 2'b11;
        @(negedge clk);
        shftL2 = 0;
        check_test("Shift Left 2 (in2=11)", 8'b0101_0111);

        // --- TEST 4: Increment (incr) ---
        // 01010111 + 1 -> 01011000
        @(negedge clk);
        incr = 1;
        @(negedge clk);
        incr = 0;
        check_test("Increment", 8'b0101_1000);

        // --- TEST 5: Shift Right 1 bit (shftR1) ---
        // 01011000 >> 1 (in1=1) -> 10101100
        @(negedge clk);
        shftR1 = 1; in1 = 1;
        @(negedge clk);
        shftR1 = 0;
        check_test("Shift Right 1 (in1=1)", 8'b1010_1100);

        // --- TEST 6: Shift Right 2 bits (shftR2) ---
        // 10101100 >> 2 (in2=00) -> 00101011
        @(negedge clk);
        shftR2 = 1; in2 = 2'b00;
        @(negedge clk);
        shftR2 = 0;
        check_test("Shift Right 2 (in2=00)", 8'b0010_1011);

        // --- TEST 7: Clear (clr) ---
        @(negedge clk);
        clr = 1;
        @(negedge clk);
        clr = 0;
        check_test("Clear Register", 8'b0000_0000);

        $display("\n-------------------------------------------");
        $display("Simulation done!");
        $display("Total Teste: %d", test_count);
        $display("Teste PASS : %d", pass_count);
        $display("Teste FAIL : %d", fail_count);
        $display("-------------------------------------------");

        $finish;
    end

endmodule