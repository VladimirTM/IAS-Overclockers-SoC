//Testare stack_pointer_tb.v

`timescale 1ns / 1ns

module stack_pointer_tb;

    reg clk;
    reg rst_n;
    reg incSP;
    reg decSP;
    wire [15:0] sp_out;

    integer test_count = 0;
    integer pass_count = 0;
    integer fail_count = 0;

    stack_pointer DUT (
        .clk(clk),
        .rst_n(rst_n),
        .incSP(incSP),
        .decSP(decSP),
        .sp_out(sp_out)
    );

    task check_test;
        input [255:0] test_name;
        input [15:0] expected_sp;
        begin
            test_count = test_count + 1;
            if (sp_out === expected_sp) begin
                $display("Test %2d PASS: %s (SP: %h)", 
                          test_count, test_name, sp_out);
                pass_count = pass_count + 1;
            end else begin
                $display("Test %2d FAIL: %s | Asteptat: %h | Actual: %h", 
                          test_count, test_name, expected_sp, sp_out);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end

    initial begin
        // Initializare semnale
        rst_n = 1;
        incSP = 0;
        decSP = 0;

        $display("--- INCEPUT TESTARE STACK POINTER ---");

        // --- TEST 1: Reset (Valoarea initiala trebuie sa fie 0x03FF) ---
        @(negedge clk);
        rst_n = 0;
        @(negedge clk);
        rst_n = 1;
        check_test("Reset state (0x03FF)", 16'h03FF);

        // --- TEST 2: Decrementare (Push) ---
        // 03FF -> 03FE
        @(negedge clk);
        decSP = 1;
        @(negedge clk);
        decSP = 0;
        check_test("Decrement SP (Push)", 16'h03FE);

        // --- TEST 3: Decrementare multipla ---
        // 03FE -> 03FD
        @(negedge clk);
        decSP = 1;
        @(negedge clk);
        decSP = 0;
        check_test("Decrement SP again", 16'h03FD);

        // --- TEST 4: Incrementare (Pop) ---
        // 03FD -> 03FE
        @(negedge clk);
        incSP = 1;
        @(negedge clk);
        incSP = 0;
        check_test("Increment SP (Pop)", 16'h03FE);

        // --- TEST 5: Revenire la baza ---
        // 03FE -> 03FF
        @(negedge clk);
        incSP = 1;
        @(negedge clk);
        incSP = 0;
        check_test("Back to base 0x03FF", 16'h03FF);

        // --- TEST 6: Prioritate (Daca ambele sunt 1, incSP castiga conform codului) ---
        // 03FF -> 0400
        @(negedge clk);
        incSP = 1;
        decSP = 1;
        @(negedge clk);
        incSP = 0;
        decSP = 0;
        check_test("Priority check (incSP over decSP)", 16'h0400);

        // --- TEST 7: Reset in timpul functionarii ---
        @(negedge clk);
        rst_n = 0;
        @(negedge clk);
        rst_n = 1;
        check_test("Mid-operation Reset", 16'h03FF);

        // --- Raport Final ---
        $display("\n-------------------------------------------");
        $display("Simulare STACK POINTER Finalizata!");
        $display("Total Teste: %d", test_count);
        $display("Teste PASS : %d", pass_count);
        $display("Teste FAIL : %d", fail_count);
        $display("-------------------------------------------");

        $finish;
    end

endmodule