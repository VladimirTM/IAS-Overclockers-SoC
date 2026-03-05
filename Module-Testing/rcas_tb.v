`timescale 1ns / 1ns

module rcas_tb;

reg [16:0] x, y;
reg op;
wire [16:0] z;

reg clk;
integer test_count = 0;
integer pass_count = 0;
integer fail_count = 0;

rcas CUT (
    .x(x),
    .y(y),
    .op(op),
    .z(z)
);

// Task-ul de verificare
task check_rcas;
    input [511:0] test_name;
    input [16:0] exp_z;
    
    begin
        test_count = test_count + 1;
        if (z === exp_z) begin
            $display("Test %2d PASS: %s", test_count, test_name);
            pass_count = pass_count + 1;
        end else begin
            $display("Test %2d FAIL: %s", test_count, test_name);
            $display("  -> EROARE: S-a primit Z=%h, se astepta %h", z, exp_z);
            fail_count = fail_count + 1;
        end
    end
endtask

initial begin
    clk = 0;
    forever #10 clk = ~clk;
end

initial begin
    x = 0; y = 0; op = 0;

    $display("========== INCEPERE TESTARE ADDER-SUBTRACTOR (17 BITI) ==========");

    // --- TEST 1: Adunare Simpla (op = 0) ---
    @(negedge clk);
    op = 0; x = 17'd100; y = 17'd50;
    #5;
    check_rcas("ADUNARE: 100 + 50", 17'd150);

    // --- TEST 2: Scadere Simpla (op = 1) ---
    @(negedge clk);
    op = 1; x = 17'd100; y = 17'd50;
    #5;
    check_rcas("SCADERE: 100 - 50", 17'd50);

    // --- TEST 3: Scadere cu rezultat negativ (op = 1) ---
    @(negedge clk);
    op = 1; x = 17'd10; y = 17'd20;
    #5;
    // 10 - 20 = -10. In complement fata de 2 pe 17 biti:
    // -10 este 1FFFF - 10 + 1 = 1FFF6
    check_rcas("SCADERE: 10 - 20 (Rezultat Negativ)", 17'h1FFF6);

    // --- TEST 4: Scadere din zero (op = 1) ---
    @(negedge clk);
    op = 1; x = 17'd0; y = 17'd1;
    #5;
    // 0 - 1 = -1 (Toate biturile 1 in complement fata de 2)
    check_rcas("SCADERE: 0 - 1", 17'h1FFFF);

    // --- TEST 5: Adunare cu depasire (op = 0) ---
    @(negedge clk);
    op = 0; x = 17'h1FFFF; y = 17'h00001;
    #5;
    // Depasirea (carry out) este ignorata de portul z, deci revine la 0
    check_rcas("ADUNARE: Max + 1 (Overflow)", 17'h00000);

    // --- TEST 6: Scadere Numar din el insusi (op = 1) ---
    @(negedge clk);
    op = 1; x = 17'h12345; y = 17'h12345;
    #5;
    check_rcas("SCADERE: X - X", 17'h00000);

    $display("---------------------------------------");
    $display("Simulare Finalizata!");
    $display("Total Teste : %d", test_count);
    $display("Teste PASS  : %d", pass_count);
    $display("Teste FAIL  : %d", fail_count);
    $display("---------------------------------------");
    
    #50; $stop;
end

endmodule