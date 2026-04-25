`timescale 1ns/1ps

module TB_MUX1_RegisterX;

    reg clk;
    reg rst_n;
    reg ldX;
    reg incrX;
    reg decrX;
    reg [15:0] D_in;
    wire [15:0] X;

    register_x U2 (
        .clk(clk),
        .rst_n(rst_n),
        .ldX(ldX),
        .incrX(incrX),
        .decrX(decrX),
        .D_in(D_in),
        .X(X)
    );

    integer test_count = 0;
    integer pass_count = 0;
    integer fail_count = 0;

    task check_test_REG;
        input [511:0] test_name;
        input [15:0] exp_rez;
        reg res_ok;
        begin
            test_count = test_count + 1;
            res_ok = (X === exp_rez);
            if (res_ok) begin
                $display("Test %2d PASS: %s", test_count, test_name);
                pass_count = pass_count + 1;
            end else begin
                $display("Test %2d FAIL: %s", test_count, test_name);
                $display("  -> expected %h, got %h", exp_rez, X);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        clk = 0;
        forever #2.5 clk = ~clk;
    end

    initial begin
        rst_n = 0; ldX = 0; incrX = 0; decrX = 0; D_in = 0;

        $display("----- Start Register_X Test -----");

        rst_n = 0;
        ldX = 0;
        incrX = 0;
        decrX = 0;
        D_in = 16'h0000;

        @(posedge clk); #1;
        check_test_REG("Reset: X=0x0000", 16'h0000);

        rst_n = 1;
        @(posedge clk); #1;

        // LOAD
        D_in = 16'h1234;
        ldX = 1;
        @(posedge clk);
        #1 ldX = 0;
        check_test_REG("LOAD: X=0x1234", 16'h1234);

        // INC
        incrX = 1;
        @(posedge clk); #1 incrX = 0;
        check_test_REG("INC: X=0x1235", 16'h1235);

        // DEC
        decrX = 1;
        @(posedge clk);
        #1 decrX = 0;
        check_test_REG("DEC: X=0x1234", 16'h1234);

        // HOLD
        D_in = 16'h9999;
        @(posedge clk); #1;
        check_test_REG("HOLD: X=0x1234", 16'h1234);

        // INC + DEC simultaneous — no change
        incrX = 1;
        decrX = 1;
        @(posedge clk); #1 incrX = 0; decrX = 0;
        check_test_REG("INC+DEC: X=0x1234", 16'h1234);

        // LOAD + INC — LOAD wins
        D_in = 16'hFFFF;
        ldX = 1;
        incrX = 1;
        @(posedge clk); #1 ldX = 0; incrX = 0;
        check_test_REG("LOAD+INC: X=0xFFFF", 16'hFFFF);

        $display("---------------------------------------");
        $display("Simulation complete");
        $display("Total: %d", test_count);
        $display("Pass:  %d", pass_count);
        $display("Fail:  %d", fail_count);
        $display("---------------------------------------");

        #20 $stop;
    end

    initial begin
        #5000;
        $display("\nERROR: Testbench timeout!");
        $finish;
    end

endmodule
