`timescale 1ns / 1ns

module mux_dr_tb;

reg [15:0] mem, X, Y, PC, IMM, A;
reg [15:0] io_data;
reg        flags_Z, flags_N, flags_C, flags_O;
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
    .io_data(io_data),
    .flags_Z(flags_Z),
    .flags_N(flags_N),
    .flags_C(flags_C),
    .flags_O(flags_O),
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
    mem     = 16'h0001;
    X       = 16'h1111;
    Y       = 16'h2222;
    PC      = 16'h3333;
    IMM     = 16'h4444;
    A       = 16'hAAAA;
    io_data = 16'h0000;
    flags_Z = 1'b0;
    flags_N = 1'b0;
    flags_C = 1'b0;
    flags_O = 1'b0;
    CondDR  = 3'b000;

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

    // --- TEST 6: Selectie Acumulator (101) ---
    @(negedge clk);
    CondDR = 3'b101;
    #5;
    check_mux_dr("Selectie A", 16'hAAAA);

    // --- TEST 7: Selectie io_data (110) - calea IN instruction ---
    @(negedge clk);
    io_data = 16'hD00D;
    CondDR  = 3'b110;
    #5;
    check_mux_dr("Selectie io_data (cale IN)", 16'hD00D);

    // --- TEST 8: io_data alt valoare (110) ---
    @(negedge clk);
    io_data = 16'hBEEF;
    CondDR  = 3'b110;
    #5;
    check_mux_dr("Selectie io_data = 0xBEEF", 16'hBEEF);

    // --- TEST 9: Flags impachetate Z=1,N=0,C=0,O=0 -> 0x8000 (111) ---
    @(negedge clk);
    flags_Z = 1'b1; flags_N = 1'b0; flags_C = 1'b0; flags_O = 1'b0;
    CondDR  = 3'b111;
    #5;
    check_mux_dr("FLAGS impachetate: Z=1 -> 0x8000", 16'h8000);

    // --- TEST 10: Flags impachetate Z=0,N=1,C=0,O=0 -> 0x4000 (111) ---
    @(negedge clk);
    flags_Z = 1'b0; flags_N = 1'b1; flags_C = 1'b0; flags_O = 1'b0;
    CondDR  = 3'b111;
    #5;
    check_mux_dr("FLAGS impachetate: N=1 -> 0x4000", 16'h4000);

    // --- TEST 11: Flags impachetate Z=1,N=0,C=1,O=0 -> 0xA000 (111) ---
    @(negedge clk);
    flags_Z = 1'b1; flags_N = 1'b0; flags_C = 1'b1; flags_O = 1'b0;
    CondDR  = 3'b111;
    #5;
    check_mux_dr("FLAGS impachetate: Z=1,C=1 -> 0xA000", 16'hA000);

    // --- TEST 12: Flags impachetate Z=1,N=1,C=1,O=1 -> 0xF000 (111) ---
    @(negedge clk);
    flags_Z = 1'b1; flags_N = 1'b1; flags_C = 1'b1; flags_O = 1'b1;
    CondDR  = 3'b111;
    #5;
    check_mux_dr("FLAGS impachetate: ZNCO=1111 -> 0xF000", 16'hF000);

    // --- TEST 13: Flags impachetate toate 0 -> 0x0000 (111) ---
    @(negedge clk);
    flags_Z = 1'b0; flags_N = 1'b0; flags_C = 1'b0; flags_O = 1'b0;
    CondDR  = 3'b111;
    #5;
    check_mux_dr("FLAGS impachetate: ZNCO=0000 -> 0x0000", 16'h0000);

    // --- TEST 14: io_data nu afecteaza alte selectii ---
    @(negedge clk);
    io_data = 16'hDEAD;
    CondDR  = 3'b000;
    #5;
    check_mux_dr("io_data ignorat cand CondDR=000", 16'h0001);

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
