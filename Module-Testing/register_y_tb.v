`timescale 1ns/1ps

module TB_MUX_Y_Register_Y;

    // ----------------------
    // Semnale pentru MUX_Y
    // ----------------------
    reg MOV;
    reg [15:0] IMM_DR;
    reg [15:0] DR;
    wire [15:0] Result;

    /* MUX_Y M1 (
        .MOV(MOV),
        .IMM_DR(IMM_DR),
        .DR(DR),
        .Result(Result)
    );
    */

    // ----------------------
    // Semnale pentru Register_Y
    // ----------------------
    reg clk;
    reg reset;       // active LOW
    reg ldY;
    reg incrY;
    reg decrY;
    reg [15:0] D_in;
    wire [15:0] Y;

    register_y R1 (
        .clk(clk),
        .reset(reset),
        .ldY(ldY),
        .incrY(incrY),
        .decrY(decrY),
        .D_in(D_in),
        .Y(Y)
    );

    // ----------------------
    // Statistici si Task-uri (Model flags_tb)
    // ----------------------
    integer test_count = 0;
    integer pass_count = 0;
    integer fail_count = 0;

    // Task adaptat pentru verificarea MUX (Result)
    task check_test_MUX;
        input [511:0] test_name;
        input [15:0] exp_rez;
        reg res_ok;
        begin
            test_count = test_count + 1;
            res_ok = (Result === exp_rez);

            if (res_ok) begin
                $display("Test %2d PASS: %s", test_count, test_name);
                pass_count = pass_count + 1;
            end else begin
                $display("Test %2d FAIL: %s", test_count, test_name);
                $display("  -> EROARE: Rezultat primit %h, se astepta %h", Result, exp_rez);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // Task adaptat pentru verificarea Registrului (Y)
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
                $display("  -> EROARE: Rezultat primit %h, se astepta %h", Y, exp_rez);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // ----------------------
    // Clock Generation
    // ----------------------
    initial begin
        clk = 0;
        forever #2.5 clk = ~clk;
    end

    // ----------------------
    // Test sequence
    // ----------------------
    initial begin
        
        // Initializari
        IMM_DR = 0; DR = 0; MOV = 0;
        reset = 0; ldY = 0; incrY = 0; decrY = 0; D_in = 0;

        /*
        ========================================
             Register_Y Testbench
        ========================================
        */

        $display("----- START SIMULARE MUX_Y + Register_Y -----");

        // Test Register_Y
        reset = 0;
        ldY = 0;
        incrY = 0;
        decrY = 0;
        D_in = 16'h0000;

        @(posedge clk); #1;
        check_test_REG("Reset activ LOW -> Y (trebuie 0000)", 16'h0000);

        reset = 1;
        @(posedge clk); #1;
        
        // LOAD
        D_in = 16'h1234;
        ldY = 1;
        @(posedge clk);
        #1 ldY = 0;
        check_test_REG("LOAD -> Y (trebuie 1234)", 16'h1234);

        // INC
        incrY = 1;
        @(posedge clk); #1 incrY = 0;
        check_test_REG("INC -> Y (trebuie 1235)", 16'h1235);

        // DEC
        decrY = 1;
        @(posedge clk);
        #1 decrY = 0;
        check_test_REG("DEC -> Y (trebuie 1234)", 16'h1234);

        // HOLD
        D_in = 16'hBBBB;
        @(posedge clk); #1;
        check_test_REG("HOLD -> Y (trebuie 1234)", 16'h1234);

        // INC + DEC simultaneous
        incrY = 1;
        decrY = 1;
        @(posedge clk); #1 incrY = 0; decrY = 0;
        check_test_REG("INC+DEC -> Y (trebuie 1234)", 16'h1234);

        // LOAD + INC (LOAD wins)
        D_in = 16'hFFFF;
        ldY = 1;
        incrY = 1;
        @(posedge clk); #1 ldY = 0; incrY = 0;
        check_test_REG("LOAD+INC -> Y (trebuie FFFF)", 16'hFFFF);

        // ----------------------
        // Summary
        // ----------------------
        $display("---------------------------------------");
        $display("Simulare Finalizata!");
        $display("Total Teste: %d", test_count);
        $display("Teste PASS : %d", pass_count);
        $display("Teste FAIL : %d", fail_count);
        $display("---------------------------------------");

        #20 $stop;
    end

    /*
    // Waveform
    initial begin
        $dumpfile("tb_mux_y_register_y.vcd");
        $dumpvars(0, TB_MUX_Y_Register_Y);
    end
    */

    // Timeout safety
    initial begin
        #5000;
        $display("\nERROR: Testbench timeout!");
        $finish;
    end

endmodule