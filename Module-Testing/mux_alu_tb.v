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
    opcode  = 16'h1010;
    A       = 16'hAAAA;
    X       = 16'hBBBB;
    Y       = 16'hCCCC;
    IMM     = 16'hD00D;
    regaddr = 0;
    CondALU = 0;

    @(negedge clk);
    CondALU = 2'b00;
    #5;
    check_mux("Select OPCODE (CondALU=00)", 16'h1010);

    @(negedge clk);
    CondALU = 2'b01;
    #5;
    check_mux("Select A (CondALU=01)", 16'hAAAA);

    @(negedge clk);
    CondALU = 2'b10;
    regaddr = 1'b0;
    #5;
    check_mux("Select X (CondALU=10, regaddr=0)", 16'hBBBB);

    @(negedge clk);
    CondALU = 2'b10;
    regaddr = 1'b1;
    #5;
    check_mux("Select Y (CondALU=10, regaddr=1)", 16'hCCCC);

    @(negedge clk);
    CondALU = 2'b11;
    #5;
    check_mux("Select IMM (CondALU=11)", 16'hD00D);

    @(negedge clk);
    IMM = 16'hFFFF;
    #5;
    check_mux("Dynamic update on selected input", 16'hFFFF);

    $display("---------------------------------------");
    $display("Simulation done!");
    $display("Total Teste : %d", test_count);
    $display("Teste PASS  : %d", pass_count);
    $display("Teste FAIL  : %d", fail_count);
    $display("---------------------------------------");

    $stop;
end

endmodule
