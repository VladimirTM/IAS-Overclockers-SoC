`timescale 1ns / 1ns

module program_counter_tb;

reg clk, rst_n, incPC, ldPC, ldPCfromDR;
reg [15:0] in_pc_imm, in_pc_dr;
wire [15:0] pc_out;

integer test_count = 0;
integer pass_count = 0;
integer fail_count = 0;

program_counter CUT (
    .clk(clk),
    .rst_n(rst_n),
    .incPC(incPC),
    .ldPC(ldPC),
    .ldPCfromDR(ldPCfromDR),
    .in_pc_imm(in_pc_imm),
    .in_pc_dr(in_pc_dr),
    .pc_out(pc_out)
);

task check_pc;
    input [511:0] test_name;
    input [15:0] exp_pc;

    begin
        test_count = test_count + 1;
        if (pc_out === exp_pc) begin
            $display("Test %2d PASS: %s", test_count, test_name);
            pass_count = pass_count + 1;
        end else begin
            $display("Test %2d FAIL: %s", test_count, test_name);
            $display("  -> FAIL: got PC=%h, expected %h", pc_out, exp_pc);
            fail_count = fail_count + 1;
        end
    end
endtask

initial begin
    clk = 0;
    forever #10 clk = ~clk;
end

initial begin
    rst_n = 1;
    incPC = 0;
    ldPC = 0;
    ldPCfromDR = 0;
    in_pc_imm = 16'h1000;
    in_pc_dr = 16'hABCD;

    @(negedge clk); rst_n = 0;
    #5;
    check_pc("Reset: PC=0", 16'h0000);

    @(negedge clk); rst_n = 1;

    @(negedge clk);
    incPC = 1;
    @(posedge clk);
    #5;
    check_pc("Increment: 0→1", 16'h0001);

    @(negedge clk);
    @(posedge clk);
    #5;
    check_pc("Increment: 1→2", 16'h0002);

    @(negedge clk);
    incPC = 0;
    @(posedge clk);
    #5;
    check_pc("Hold", 16'h0002);

    @(negedge clk);
    ldPC = 1;
    ldPCfromDR = 0;
    in_pc_imm = 16'h55AA;
    @(posedge clk);
    #5;
    check_pc("Load from IMM (branch)", 16'h55AA);

    @(negedge clk);
    ldPCfromDR = 1;
    in_pc_dr = 16'hF00D;
    @(posedge clk);
    #5;
    check_pc("Load from DR (indirect jump)", 16'hF00D);

    // ldPC takes priority over incPC
    @(negedge clk);
    incPC = 1;
    ldPC = 1;
    ldPCfromDR = 0;
    in_pc_imm = 16'h1234;
    @(posedge clk);
    #5;
    check_pc("Load overrides Increment", 16'h1234);

    $display("---------------------------------------");
    $display("Simulation done!");
    $display("Total Teste : %d", test_count);
    $display("Teste PASS  : %d", pass_count);
    $display("Teste FAIL  : %d", fail_count);
    $display("---------------------------------------");

    #50; $stop;
end

endmodule
