`timescale 1ns / 1ns

module rca_tb;

reg [16:0] x, y;
reg cin;
wire [16:0] z;
wire cout;

reg clk;
integer test_count = 0;
integer pass_count = 0;
integer fail_count = 0;

rca CUT (
    .x(x),
    .y(y),
    .cin(cin),
    .z(z),
    .cout(cout)
);

// Task-ul de verificare
task check_rca;
    input [511:0] test_name;
    input [16:0] exp_z;
    input exp_cout;
    
    begin
        test_count = test_count + 1;
        if (z === exp_z && cout === exp_cout) begin
            $display("Test %2d PASS: %s", test_count, test_name);
            pass_count = pass_count + 1;
        end else begin
            $display("Test %2d FAIL: %s", test_count, test_name);
            $display("  -> EROARE: S-a primit Z=%h Cout=%b, se astepta Z=%h Cout=%b", 
                     z, cout, exp_z, exp_cout);
            fail_count = fail_count + 1;
        end
    end
endtask

initial begin
    clk = 0;
    forever #10 clk = ~clk;
end

initial begin
    x = 0;
    y = 0;
    cin = 0;

    $display("========== INCEPERE TESTARE RIPPLE CARRY ADDER (17 BITI) ==========");

    // --- TEST 1: Adunare simpla fara carry ---
    @(negedge clk);
    x = 17'h00001;
    y = 17'h00002;
    cin = 0;
    #5;
    check_rca("Adunare 1 + 2", 17'h00003, 1'b0);

    // --- TEST 2: Adunare cu Carry In ---
    @(negedge clk);
    x = 17'h0000A;
    y = 17'h00005;
    cin = 1;
    #5;
    check_rca("Adunare A + 5 + Cin(1)", 17'h00010, 1'b0);

    // --- TEST 3: Propagare Carry prin tot lantul ---
    @(negedge clk);
    x = 17'h1FFFF;
    y = 17'h00000;
    cin = 1;
    #5;
    // 1FFFF + 1 = 20000, dar pe 17 biti ramane 00000 si cout = 1
    check_rca("Propagare carry (toate 1 + Cin)", 17'h00000, 1'b1);

    // --- TEST 4: Suma maxima fara Cout ---
    @(negedge clk);
    x = 17'h0AAAA;
    y = 17'h05555;
    cin = 0;
    #5;
    check_rca("Suma alternanta AAAA + 5555", 17'h0FFFF, 1'b0);

    // --- TEST 5: Carry Out pe bitul 17 ---
    @(negedge clk);
    x = 17'h10000;
    y = 17'h10000;
    cin = 0;
    #5;
    check_rca("Depasire 17 biti (Cout)", 17'h00000, 1'b1);

    // --- TEST 6: Valori aleatoare ---
    @(negedge clk);
    x = 17'h12345;
    y = 17'h01234;
    cin = 1;
    #5;
    check_rca("Adunare random", 17'h1357A, 1'b0);

    $display("---------------------------------------");
    $display("Simulare Finalizata!");
    $display("Total Teste : %d", test_count);
    $display("Teste PASS  : %d", pass_count);
    $display("Teste FAIL  : %d", fail_count);
    $display("---------------------------------------");
    
    #50; $stop;
end

endmodule