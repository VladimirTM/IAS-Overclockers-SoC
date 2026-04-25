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
            $display("  -> FAIL: got %h, expected %h", out, exp_out);
            fail_count = fail_count + 1;
        end
    end
endtask

initial begin
    clk = 0;
    forever #10 clk = ~clk;
end

initial begin
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

    @(negedge clk);
    CondDR = 3'b000;
    #5;
    check_mux_dr("Select MEM (CondDR=000)", 16'h0001);

    @(negedge clk);
    CondDR = 3'b001;
    #5;
    check_mux_dr("Select X (CondDR=001)", 16'h1111);

    @(negedge clk);
    CondDR = 3'b010;
    #5;
    check_mux_dr("Select Y (CondDR=010)", 16'h2222);

    @(negedge clk);
    CondDR = 3'b011;
    #5;
    check_mux_dr("Select PC (CondDR=011)", 16'h3333);

    @(negedge clk);
    CondDR = 3'b100;
    #5;
    check_mux_dr("Select IMM (CondDR=100)", 16'h4444);

    @(negedge clk);
    CondDR = 3'b101;
    #5;
    check_mux_dr("Select A (CondDR=101)", 16'hAAAA);

    @(negedge clk);
    io_data = 16'hD00D;
    CondDR  = 3'b110;
    #5;
    check_mux_dr("Select io_data (CondDR=110, IN path)", 16'hD00D);

    @(negedge clk);
    io_data = 16'hBEEF;
    CondDR  = 3'b110;
    #5;
    check_mux_dr("Select io_data=0xBEEF (CondDR=110)", 16'hBEEF);

    @(negedge clk);
    flags_Z = 1'b1; flags_N = 1'b0; flags_C = 1'b0; flags_O = 1'b0;
    CondDR  = 3'b111;
    #5;
    check_mux_dr("Packed FLAGS: Z=1 → 0x8000 (CondDR=111)", 16'h8000);

    @(negedge clk);
    flags_Z = 1'b0; flags_N = 1'b1; flags_C = 1'b0; flags_O = 1'b0;
    CondDR  = 3'b111;
    #5;
    check_mux_dr("Packed FLAGS: N=1 → 0x4000 (CondDR=111)", 16'h4000);

    @(negedge clk);
    flags_Z = 1'b1; flags_N = 1'b0; flags_C = 1'b1; flags_O = 1'b0;
    CondDR  = 3'b111;
    #5;
    check_mux_dr("Packed FLAGS: Z=1,C=1 → 0xA000 (CondDR=111)", 16'hA000);

    @(negedge clk);
    flags_Z = 1'b1; flags_N = 1'b1; flags_C = 1'b1; flags_O = 1'b1;
    CondDR  = 3'b111;
    #5;
    check_mux_dr("Packed FLAGS: ZNCO=1111 → 0xF000 (CondDR=111)", 16'hF000);

    @(negedge clk);
    flags_Z = 1'b0; flags_N = 1'b0; flags_C = 1'b0; flags_O = 1'b0;
    CondDR  = 3'b111;
    #5;
    check_mux_dr("Packed FLAGS: ZNCO=0000 → 0x0000 (CondDR=111)", 16'h0000);

    @(negedge clk);
    io_data = 16'hDEAD;
    CondDR  = 3'b000;
    #5;
    check_mux_dr("io_data ignored when CondDR=000", 16'h0001);

    $display("---------------------------------------");
    $display("Simulation done!");
    $display("Total Teste : %d", test_count);
    $display("Teste PASS  : %d", pass_count);
    $display("Teste FAIL  : %d", fail_count);
    $display("---------------------------------------");

    #50; $stop;
end

endmodule
