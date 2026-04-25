`timescale 1ns / 1ns

module rcas_tb;

reg [16:0] x, y;
reg op;
wire [16:0] z;

reg clk;
integer test_count = 0;
integer pass_count = 0;
integer fail_count = 0;

rcas CUT (
    .x(x),
    .y(y),
    .op(op),
    .z(z)
);

task check_rcas;
    input [511:0] test_name;
    input [16:0] exp_z;

    begin
        test_count = test_count + 1;
        if (z === exp_z) begin
            $display("Test %2d PASS: %s", test_count, test_name);
            pass_count = pass_count + 1;
        end else begin
            $display("Test %2d FAIL: %s", test_count, test_name);
            $display("  -> FAIL: got Z=%h, expected %h", z, exp_z);
            fail_count = fail_count + 1;
        end
    end
endtask

initial begin
    clk = 0;
    forever #10 clk = ~clk;
end

initial begin
    x = 0; y = 0; op = 0;

    @(negedge clk);
    op = 0; x = 17'd100; y = 17'd50;
    #5;
    check_rcas("ADD: 100 + 50", 17'd150);

    @(negedge clk);
    op = 1; x = 17'd100; y = 17'd50;
    #5;
    check_rcas("SUB: 100 - 50", 17'd50);

    @(negedge clk);
    op = 1; x = 17'd10; y = 17'd20;
    #5;
    // 10 - 20 = -10 in 17-bit two's complement:
    // -10 = 1FFF6
    check_rcas("SUB: 10 - 20 (negative result)", 17'h1FFF6);

    @(negedge clk);
    op = 1; x = 17'd0; y = 17'd1;
    #5;
    // 0 - 1 = -1 (all bits set in two's complement)
    check_rcas("SUB: 0 - 1", 17'h1FFFF);

    @(negedge clk);
    op = 0; x = 17'h1FFFF; y = 17'h00001;
    #5;
    // carry out ignored by z port; result wraps to 0
    check_rcas("ADD: Max + 1 (overflow)", 17'h00000);

    @(negedge clk);
    op = 1; x = 17'h12345; y = 17'h12345;
    #5;
    check_rcas("SUB: X - X", 17'h00000);

    $display("---------------------------------------");
    $display("Simulation done!");
    $display("Total Teste : %d", test_count);
    $display("Teste PASS  : %d", pass_count);
    $display("Teste FAIL  : %d", fail_count);
    $display("---------------------------------------");

    #50; $stop;
end

endmodule
