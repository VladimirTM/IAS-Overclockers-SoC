`timescale 1ns/1ps

module TB_MUX1_RegisterX;

    // ----------------------
    // Semnale pentru MUX1
    // ----------------------
    reg [15:0] IMM_DR;
    reg [15:0] DR;
    reg MOV;
    wire [15:0] Result;

    /* // Instan?iere MUX1 - Asumat? implicit conform codului original
    MUX_X a(
        .MOV(MOV),
        .IMM_DR(IMM_DR),
        .DR(DR),
        .Result(Result)
    );
    */

    // ----------------------
    // Semnale pentru Register_X
    // ----------------------
    reg clk;
    reg reset;        // active LOW
    reg ldX;
    reg incrX;
    reg decrX;
    reg [15:0] D_in;
    wire [15:0] X;

    // Instan?iere Register_X
    register_x U2 (
        .clk(clk),
        .reset(reset),
        .ldX(ldX),
        .incrX(incrX),
        .decrX(decrX),
        .D_in(D_in),
        .X(X)
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

    // Task adaptat pentru verificarea Registrului (X)
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
                $display("  -> EROARE: Rezultat primit %h, se astepta %h", X, exp_rez);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // ----------------------
    // Clock Generation
    // ----------------------
    initial begin
        clk = 0;
        forever #2.5 clk = ~clk;  // perioada 5 ns
    end

    // ----------------------
    // Test Sequence
    // ----------------------
    initial begin
        
        // Initializari
        IMM_DR = 0; DR = 0; MOV = 0;
        reset = 0; ldX = 0; incrX = 0; decrX = 0; D_in = 0;

        /*
        ========================================
             Register_X Testbench
        ========================================
        */

        $display("----- Start Simulare MUX1 + Register_X -----");


        // ----------------------
        // TEST Register_X
        // ----------------------
        reset = 0; // activez reset (active LOW)
        ldX = 0;
        incrX = 0;
        decrX = 0;
        D_in = 16'h0000;

        @(posedge clk); #1;
        check_test_REG("Reset activ -> X (trebuie 0000)", 16'h0000);

        reset = 1; // dezactivez reset
        @(posedge clk); #1;

        // LOAD
        D_in = 16'h1234;
        ldX = 1;
        @(posedge clk);
        #1 ldX = 0;
        check_test_REG("LOAD -> X (trebuie 1234)", 16'h1234);

        // INC
        incrX = 1;
        @(posedge clk); #1 incrX = 0;
        check_test_REG("INC -> X (trebuie 1235)", 16'h1235);

        // DEC
        decrX = 1;
        @(posedge clk);
        #1 decrX = 0;
        check_test_REG("DEC -> X (trebuie 1234)", 16'h1234);

        // HOLD
        D_in = 16'h9999;
        @(posedge clk); #1;
        check_test_REG("HOLD -> X (trebuie 1234)", 16'h1234);

        // INC + DEC simultan ? nu se schimb?
        incrX = 1;
        decrX = 1;
        @(posedge clk); #1 incrX = 0; decrX = 0;
        check_test_REG("INC+DEC -> X (trebuie 1234)", 16'h1234);

        // LOAD + INC ? LOAD are prioritate
        D_in = 16'hFFFF;
        ldX = 1;
        incrX = 1;
        @(posedge clk); #1 ldX = 0; incrX = 0;
        check_test_REG("LOAD+INC -> X (trebuie FFFF)", 16'hFFFF);

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
    // Waveform dump
    initial begin
        $dumpfile("tb_mux1_registerx.vcd");
        $dumpvars(0, TB_MUX1_RegisterX);
    end
    */

    // Timeout safety
    initial begin
        #5000;
        $display("\nERROR: Testbench timeout!");
        $finish;
    end

endmodule
