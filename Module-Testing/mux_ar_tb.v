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
    PC     = 16'h1000;
    SP     = 16'h7FFE;
    IMM    = 16'hABCD;
    AR_EXT = 16'h0000;
    CondAR = 2'b00;

    @(negedge clk);
    CondAR = 2'b00;
    #5;
    check_mux_ar("Select PC (CondAR=00)", 16'h1000);

    @(negedge clk);
    CondAR = 2'b01;
    #5;
    check_mux_ar("Select SP (CondAR=01)", 16'h7FFE);

    @(negedge clk);
    CondAR = 2'b10;
    #5;
    check_mux_ar("Select IMM (CondAR=10)", 16'hABCD);

    @(negedge clk);
    AR_EXT = 16'h0000;
    CondAR = 2'b11;
    #5;
    check_mux_ar("Select AR_EXT=0x0000 (CondAR=11)", 16'h0000);

    @(negedge clk);
    CondAR = 2'b01;
    SP = 16'h1234;
    #5;
    check_mux_ar("Dynamic change on SP input", 16'h1234);

    @(negedge clk);
    AR_EXT = 16'h0400;  // bit 10 set: I/O space (port 0)
    CondAR = 2'b11;
    #5;
    check_mux_ar("AR_EXT: I/O page address (bit10=1)", 16'h0400);

    @(negedge clk);
    AR_EXT = 16'h00BE;  // 190 decimal: IVT base
    CondAR = 2'b11;
    #5;
    check_mux_ar("AR_EXT: IVT address 190", 16'h00BE);

    @(negedge clk);
    AR_EXT = 16'hDEAD;
    CondAR = 2'b00;  // should select PC, not AR_EXT
    #5;
    check_mux_ar("AR_EXT ignored when CondAR=00", 16'h1000);

    $display("---------------------------------------");
    $display("Simulation done!");
    $display("Total Teste : %d", test_count);
    $display("Teste PASS  : %d", pass_count);
    $display("Teste FAIL  : %d", fail_count);
    $display("---------------------------------------");

    #50; $stop;
end

endmodule
