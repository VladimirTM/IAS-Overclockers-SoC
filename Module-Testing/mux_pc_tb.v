`timescale 1ns / 1ns

module mux_pc_tb;

reg [15:0] PC_hold, PC_inc, PC_imm, PC_dr;
reg [1:0] CondPC;
wire [15:0] out;

reg clk;
integer test_count = 0;
integer pass_count = 0;
integer fail_count = 0;

mux_pc CUT (
    .PC_hold(PC_hold),
    .PC_inc(PC_inc),
    .PC_imm(PC_imm),
    .PC_dr(PC_dr),
    .CondPC(CondPC),
    .out(out)
);

task check_mux_pc;
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
    PC_hold = 16'hAAAA;
    PC_inc  = 16'hBBBB;
    PC_imm  = 16'hCCCC;
    PC_dr   = 16'hDDDD;
    CondPC  = 2'b00;

    @(negedge clk);
    CondPC = 2'b00;
    #5;
    check_mux_pc("Select PC_HOLD (CondPC=00)", 16'hAAAA);

    @(negedge clk);
    CondPC = 2'b01;
    #5;
    check_mux_pc("Select PC_INC (CondPC=01)", 16'hBBBB);

    @(negedge clk);
    CondPC = 2'b10;
    #5;
    check_mux_pc("Select PC_IMM (CondPC=10, branch/jump)", 16'hCCCC);

    @(negedge clk);
    CondPC = 2'b11;
    #5;
    check_mux_pc("Select PC_DR (CondPC=11, indirect)", 16'hDDDD);

    @(negedge clk);
    CondPC = 2'b10;
    PC_imm = 16'hF00F;
    #5;
    check_mux_pc("Dynamic update PC_IMM", 16'hF00F);

    $display("---------------------------------------");
    $display("Simulation done!");
    $display("Total Teste : %d", test_count);
    $display("Teste PASS  : %d", pass_count);
    $display("Teste FAIL  : %d", fail_count);
    $display("---------------------------------------");

    #50; $stop;
end

endmodule
