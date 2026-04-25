`timescale 1ns / 1ns

module opcode_decoder_tb;

reg [5:0] opcode;
wire [3:0] operation_type;
wire is_compare;

reg clk;
integer test_count = 0;
integer pass_count = 0;
integer fail_count = 0;

opcode_decoder CUT (
    .opcode(opcode),
    .operation_type(operation_type),
    .is_compare(is_compare)
);

task check_decoder;
    input [511:0] test_name;
    input [3:0] exp_op;
    input exp_comp;

    begin
        test_count = test_count + 1;
        if (operation_type === exp_op && is_compare === exp_comp) begin
            $display("Test %2d PASS: %s", test_count, test_name);
            pass_count = pass_count + 1;
        end else begin
            $display("Test %2d FAIL: %s", test_count, test_name);
            $display("  -> FAIL: got Op=%d Comp=%b, expected Op=%d Comp=%b",
                     operation_type, is_compare, exp_op, exp_comp);
            fail_count = fail_count + 1;
        end
    end
endtask

initial begin
    clk = 0;
    forever #10 clk = ~clk;
end

initial begin
    opcode = 6'b000000;

    @(negedge clk);
    opcode = 6'b001010; // CPU_ADD
    #5;
    check_decoder("CPU_ADD → OP_ADD, is_compare=0", 4'd0, 1'b0);

    @(negedge clk);
    opcode = 6'b101011; // CPU_SUBI
    #5;
    check_decoder("CPU_SUBI → OP_SUB, is_compare=0", 4'd1, 1'b0);

    @(negedge clk);
    opcode = 6'b010011; // CPU_AND
    #5;
    check_decoder("CPU_AND → OP_AND, is_compare=0", 4'd5, 1'b0);

    // CMP: type=SUB, is_compare=1
    @(negedge clk);
    opcode = 6'b010111;
    #5;
    check_decoder("CPU_CMP → OP_SUB, is_compare=1", 4'd1, 1'b1);

    // TST: type=AND, is_compare=1
    @(negedge clk);
    opcode = 6'b111000;
    #5;
    check_decoder("CPU_TSTI → OP_AND, is_compare=1", 4'd5, 1'b1);

    @(negedge clk);
    opcode = 6'b001111; // CPU_LSL
    #5;
    check_decoder("CPU_LSL → OP_LSL", 4'd9, 1'b0);

    @(negedge clk);
    opcode = 6'b111111; // undefined opcode
    #5;
    check_decoder("Undefined opcode (default: OP_ADD)", 4'd0, 1'b0);

    $display("---------------------------------------");
    $display("Simulation done!");
    $display("Total Teste : %d", test_count);
    $display("Teste PASS  : %d", pass_count);
    $display("Teste FAIL  : %d", fail_count);
    $display("---------------------------------------");

    #50; $stop;
end

endmodule
