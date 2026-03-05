`timescale 1ns / 1ns

module mux_dr_tb;

reg [15:0] mem, X, Y, PC, IMM, A;
reg [2:0] CondDR;
wire [15:0] out;

reg clk;
integer test_count = 0;
integer pass_count = 0;
integer fail_count = 0;

mux_dr CUT (
    .mem(mem),
    .X(X),
    .Y(Y),
    .PC(PC),
    .IMM(IMM),
    .A(A),
    .CondDR(CondDR),
    .out(out)
);

// Task-ul de verificare
task check_mux_dr;
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
    // Initializare date de intrare
    mem = 16'h0001; // Valori sugestive pentru identificare usoara
    X   = 16'h1111;
    Y   = 16'h2222;
    PC  = 16'h3333;
    IMM = 16'h4444;
    A   = 16'hAAAA;
    CondDR = 3'b111; // Incepem cu o stare default

    $display("========== INCEPERE TESTARE MUX DR ==========");

    // --- TEST 1: Selectie Memorie (000) ---
    @(negedge clk);
    CondDR = 3'b000;
    #5;
    check_mux_dr("Selectie MEM", 16'h0001);

    // --- TEST 2: Selectie Registru X (001) ---
    @(negedge clk);
    CondDR = 3'b001;
    #5;
    check_mux_dr("Selectie X", 16'h1111);

    // --- TEST 3: Selectie Registru Y (010) ---
    @(negedge clk);
    CondDR = 3'b010;
    #5;
    check_mux_dr("Selectie Y", 16'h2222);

    // --- TEST 4: Selectie Program Counter (011) ---
    @(negedge clk);
    CondDR = 3'b011;
    #5;
    check_mux_dr("Selectie PC", 16'h3333);

    // --- TEST 5: Selectie Immediat (100) ---
    @(negedge clk);
    CondDR = 3'b100;
    #5;
    check_mux_dr("Selectie IMM", 16'h4444);

    // --- TEST 6: Verificare Cazul Default (ex: 101) ---
    @(negedge clk);
    CondDR = 3'b101;
    #5;
    check_mux_dr("Selectie A", 16'hAAAA);

    // --- TEST 7: Verificare Cazul Default (ex: 111) ---
    @(negedge clk);
    CondDR = 3'b111;
    #5;
    check_mux_dr("Verificare Default (111 -> 0)", 16'h0000);

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