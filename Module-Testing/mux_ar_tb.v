`timescale 1ns / 1ns

module mux_ar_tb;

reg [15:0] PC, SP, IMM, AR_EXT;
reg [1:0] CondAR;
wire [15:0] out;

reg clk;
integer test_count = 0;
integer pass_count = 0;
integer fail_count = 0;

mux_ar CUT (
    .PC(PC),
    .SP(SP),
    .IMM(IMM),
    .AR_EXT(AR_EXT),
    .CondAR(CondAR),
    .out(out)
);

// Task-ul de verificare
task check_mux_ar;
    input [511:0] test_name;
    input [15:0] exp_out;

    begin
        test_count = test_count + 1;
        if (out === exp_out) begin
            $display("Test %2d PASS: %s", test_count, test_name);
            pass_count = pass_count + 1;
        end else begin
            $display("Test %2d FAIL: %s", test_count, test_name);
            $display("  -> EROARE: S-a primit %h, se astepta %h", out, exp_out);
            fail_count = fail_count + 1;
        end
    end
endtask

initial begin
    clk = 0;
    forever #10 clk = ~clk;
end

initial begin
    PC     = 16'h1000;
    SP     = 16'h7FFE;
    IMM    = 16'hABCD;
    AR_EXT = 16'h0000;
    CondAR = 2'b00;

    $display("========== INCEPERE TESTARE MUX AR ==========");

    // --- TEST 1: Selectie Program Counter (CondAR = 00) ---
    @(negedge clk);
    CondAR = 2'b00;
    #5;
    check_mux_ar("Selectie PC", 16'h1000);

    // --- TEST 2: Selectie Stack Pointer (CondAR = 01) ---
    @(negedge clk);
    CondAR = 2'b01;
    #5;
    check_mux_ar("Selectie SP", 16'h7FFE);

    // --- TEST 3: Selectie Valoare Immediata (CondAR = 10) ---
    @(negedge clk);
    CondAR = 2'b10;
    #5;
    check_mux_ar("Selectie IMM", 16'hABCD);

    // --- TEST 4: Selectie AR_EXT cu valoare 0 (CondAR = 11) ---
    @(negedge clk);
    AR_EXT = 16'h0000;
    CondAR = 2'b11;
    #5;
    check_mux_ar("Selectie AR_EXT = 0x0000", 16'h0000);

    // --- TEST 5: Actualizare dinamica intrare selectata ---
    @(negedge clk);
    CondAR = 2'b01;
    SP = 16'h1234;
    #5;
    check_mux_ar("Schimbare valoare pe intrarea SP", 16'h1234);

    // --- TEST 6: AR_EXT selectie adresa pagina I/O (CondAR = 11) ---
    @(negedge clk);
    AR_EXT = 16'h0400;  // bit 10 set: adresa spatiu I/O (port 0)
    CondAR = 2'b11;
    #5;
    check_mux_ar("AR_EXT: adresa pagina I/O (bit10=1)", 16'h0400);

    // --- TEST 7: AR_EXT selectie adresa IVT (CondAR = 11) ---
    @(negedge clk);
    AR_EXT = 16'h00BE;  // 190 decimal: baza IVT
    CondAR = 2'b11;
    #5;
    check_mux_ar("AR_EXT: adresa IVT 190", 16'h00BE);

    // --- TEST 8: AR_EXT nu afecteaza alte selectii ---
    @(negedge clk);
    AR_EXT = 16'hDEAD;
    CondAR = 2'b00;  // trebuie sa selecteze PC, nu AR_EXT
    #5;
    check_mux_ar("AR_EXT ignorat cand CondAR=00", 16'h1000);

    // Raport Final
    $display("---------------------------------------");
    $display("Simulare Finalizata!");
    $display("Total Teste : %d", test_count);
    $display("Teste PASS  : %d", pass_count);
    $display("Teste FAIL  : %d", fail_count);
    $display("---------------------------------------");

    #50; $stop;
end

endmodule
