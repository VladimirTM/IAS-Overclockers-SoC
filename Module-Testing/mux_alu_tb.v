`timescale 1ns / 1ns

module mux_alu_tb;

reg [15:0] opcode, A, X, Y, IMM;
reg regaddr;
reg [1:0] CondALU;
wire [15:0] out;

reg clk;
integer test_count = 0;
integer pass_count = 0;
integer fail_count = 0;

// Instantierea unitatii
mux_alu CUT (
    .opcode(opcode),
    .A(A),
    .X(X),
    .Y(Y),
    .IMM(IMM),
    .regaddr(regaddr),
    .CondALU(CondALU),
    .out(out)
);

// Task-ul de verificare
task check_mux;
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

// Generare clk
initial begin
    clk = 0;
    forever #10 clk = ~clk;
end

initial begin
    // Initializare date de intrare
    opcode = 16'h1010;
    A      = 16'hAAAA;
    X      = 16'hXXXX; // X simulat cu valoare hex
    X      = 16'hBBBB;
    Y      = 16'hCCCC;
    IMM    = 16'hD00D;
    regaddr = 0;
    CondALU = 0;

    $display("========== INCEPERE TESTARE MUX ALU ==========");

    // --- TEST 1: Selectie Opcode (CondALU = 00) ---
    @(negedge clk);
    CondALU = 2'b00;
    #5; // mica pauza pt propagare combinationala
    check_mux("Selectie OPCODE", 16'h1010);

    // --- TEST 2: Selectie Registru A (CondALU = 01) ---
    @(negedge clk);
    CondALU = 2'b01;
    #5;
    check_mux("Selectie A", 16'hAAAA);

    // --- TEST 3: Selectie Registru X (CondALU = 10, regaddr = 0) ---
    @(negedge clk);
    CondALU = 2'b10;
    regaddr = 1'b0;
    #5;
    check_mux("Selectie X (regaddr=0)", 16'hBBBB);

    // --- TEST 4: Selectie Registru Y (CondALU = 10, regaddr = 1) ---
    @(negedge clk);
    CondALU = 2'b10;
    regaddr = 1'b1;
    #5;
    check_mux("Selectie Y (regaddr=1)", 16'hCCCC);

    // --- TEST 5: Selectie Valoare Immediata (CondALU = 11) ---
    @(negedge clk);
    CondALU = 2'b11;
    #5;
    check_mux("Selectie IMM", 16'hD00D);

    // --- TEST 6: Verificare Schimbare Dinamica Date ---
    @(negedge clk);
    IMM = 16'hFFFF;
    #5;
    check_mux("Schimbare data pe intrarea selectata", 16'hFFFF);

    // Raport Final
    $display("---------------------------------------");
    $display("Simulare Finalizata!");
    $display("Total Teste : %d", test_count);
    $display("Teste PASS  : %d", pass_count);
    $display("Teste FAIL  : %d", fail_count);
    $display("---------------------------------------");
    
    $stop;
end

endmodule