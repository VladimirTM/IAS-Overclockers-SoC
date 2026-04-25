`timescale 1ns/1ps

module TB_MUX_Y_Register_Y;

    reg clk;
    reg rst_n;
    reg ldY;
    reg incrY;
    reg decrY;
    reg [15:0] D_in;
    wire [15:0] Y;

    // DUT
    register_y R1 (
        .clk(clk),
        .rst_n(rst_n),
        .ldY(ldY),
        .incrY(incrY),
        .decrY(decrY),
        .D_in(D_in),
        .Y(Y)
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
            res_ok = (Y === exp_rez);
            if (res_ok) begin
                $display("Test %2d PASS: %s", test_count, test_name);
                pass_count = pass_count + 1;
            end else begin
                $display("Test %2d FAIL: %s", test_count, test_name);
                $display("  -> expected %h, got %h", exp_rez, Y);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // Clock generation
    initial begin
        clk = 0;
        forever #2.5 clk = ~clk;
    end

    initial begin
        rst_n = 0; ldY = 0; incrY = 0; decrY = 0; D_in = 0;

        $display("----- Start Register_Y Test -----");

        rst_n = 0;
        ldY = 0;
        incrY = 0;
        decrY = 0;
        D_in = 16'h0000;

        @(posedge clk); #1;
        check_test_REG("Reset: Y=0x0000", 16'h0000);

        rst_n = 1;
        @(posedge clk); #1;

        // LOAD
        D_in = 16'h1234;
        ldY = 1;
        @(posedge clk);
        #1 ldY = 0;
        check_test_REG("LOAD: Y=0x1234", 16'h1234);

        // INC
        incrY = 1;
        @(posedge clk); #1 incrY = 0;
        check_test_REG("INC: Y=0x1235", 16'h1235);

        // DEC
        decrY = 1;
        @(posedge clk);
        #1 decrY = 0;
        check_test_REG("DEC: Y=0x1234", 16'h1234);

        // HOLD
        D_in = 16'hBBBB;
        @(posedge clk); #1;
        check_test_REG("HOLD: Y=0x1234", 16'h1234);

        // INC + DEC simultaneous — no change
        incrY = 1;
        decrY = 1;
        @(posedge clk); #1 incrY = 0; decrY = 0;
        check_test_REG("INC+DEC: Y=0x1234", 16'h1234);

        // LOAD + INC — LOAD wins
        D_in = 16'hFFFF;
        ldY = 1;
        incrY = 1;
        @(posedge clk); #1 ldY = 0; incrY = 0;
        check_test_REG("LOAD+INC: Y=0xFFFF", 16'hFFFF);

        $display("---------------------------------------");
        $display("Simulation complete");
        $display("Total: %d", test_count);
        $display("Pass:  %d", pass_count);
        $display("Fail:  %d", fail_count);
        $display("---------------------------------------");

        #20 $stop;
    end

    // Timeout safety
    initial begin
        #5000;
        $display("\nERROR: Testbench timeout!");
        $finish;
    end

endmodule
