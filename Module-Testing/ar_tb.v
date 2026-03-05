`timescale 1ns/1ns

module address_register_tb;
  
    reg clk;
    reg rst_n;
    reg ldAR;
    reg [15:0] in_address;
    wire [15:0] out_address;
    
    reg [15:0] PC;
    reg [15:0] SP;
    reg [15:0] IMM;
    reg [1:0] CondAR;
    wire [15:0] mux_out;
    
    address_register uut_ar (
        .clk(clk),
        .rst_n(rst_n),
        .ldAR(ldAR),
        .in_address(in_address),
        .out_address(out_address)
    );
    
    mux_ar uut_mux (
        .PC(PC),
        .SP(SP),
        .IMM(IMM),
        .CondAR(CondAR),
        .out(mux_out)
    );

    integer test_count = 0;
    integer pass_count = 0;
    integer fail_count = 0;
    
    task check_test;
        input [511:0] test_name;
        input [15:0] exp_rez;
        
        reg res_ok;
        begin
          
            test_count = test_count + 1;
            res_ok = (out_address == exp_rez);

            if (res_ok) begin
                $display("Test %2d PASS: %s", test_count, test_name);
                pass_count = pass_count + 1;
            end else begin
                $display("Test %2d FAIL: %s", test_count, test_name);
                $display("  -> EROARE REZULTAT: S-a primit %h, se astepta %h", out_address, exp_rez);
                fail_count = fail_count + 1;
            end
        end
    endtask

    task check_test_MUX;
        input [511:0] test_name;
        input [15:0] exp_rez;
        
        reg res_ok;
        begin
          
            test_count = test_count + 1;
            res_ok = (mux_out == exp_rez);

            if (res_ok) begin
                $display("Test %2d PASS: %s", test_count, test_name);
                pass_count = pass_count + 1;
            end else begin
                $display("Test %2d FAIL: %s", test_count, test_name);
                $display("  -> EROARE REZULTAT: S-a primit %h, se astepta %h", mux_out, exp_rez);
                fail_count = fail_count + 1;
            end
        end
    endtask
    
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    initial begin
        
        rst_n = 1;
        ldAR = 0;
        in_address = 0;
        
        // Valori de test pentru intrarile MUX
        PC  = 16'hAAAA; // Valoare test PC
        SP  = 16'hBBBB; // Valoare test SP
        IMM = 16'hCCCC; // Valoare test IMM
        
        CondAR = 2'b00;
        
        /*
        ========================================
            AR and muxAR Module Testbench
        ========================================
        */
        
        /*
        ========================================
            AR SubModule Testbench
        ========================================
        */
        
        @ (negedge clk);
        rst_n = 0;
        in_address = 16'hFFFF;
        ldAR = 1;
        @ (posedge clk);
        @ (negedge clk);
        rst_n = 1; // done like this for iverilog testing script
        check_test("Reset: out_address = 16'h0000", 16'h0000);
        
        ldAR = 1;
        in_address = 16'h1234;
        @ (negedge clk);
        check_test("Load Data: out_address = in_address", in_address);
        
        in_address = 16'h5678;
        @ (negedge clk);
        ldAR = 0;
        check_test("Load Data: out_address = in_address", in_address);
        
        in_address = 16'hDEAD;
        @ (negedge clk);
        check_test("Hold Data: out_address = 16'h5678", 16'h5678);
        
        
        /*
        ========================================
            mux_ar SubModule Testbench
        ========================================
        */

        CondAR = 2'b00;
        #1;
        check_test_MUX("CondAR=00 (PC): mux_out = PC", PC);
        
        CondAR = 2'b01;
        #1;
        check_test_MUX("CondAR=01 (SP): mux_out = SP", SP);
        
        CondAR = 2'b10;
        #1;
        check_test_MUX("CondAR=10 (IMM): mux_out = IMM", IMM);
        
        CondAR = 2'b11;
        #1;
        check_test_MUX("CondAR=11 (defaultCase): mux_out = 0000", 16'h0000);

        
        /*
        ========================================
            AR and muxAR Integration Testbench
        ========================================
        */
        
        @ (negedge clk);
        ldAR = 1;
        CondAR = 2'b00;
        #1;
        in_address = mux_out;
        @ (negedge clk);
        check_test("Selected PC -> out_address = PC", PC);
        
        @ (negedge clk);
        CondAR = 2'b01;
        #1;
        in_address = mux_out;
        @ (negedge clk);
        check_test("Selected SP -> out_address = SP", SP);
        
        @ (negedge clk);
        CondAR = 2'b10;
        #1;
        in_address = mux_out;
        @ (negedge clk);
        check_test("Selected IMM -> out_address = IMM", IMM);
        
        @ (negedge clk);
        CondAR = 2'b11;
        #1;
        in_address = mux_out;
        @ (negedge clk);
        check_test("Selected defaultCase -> out_address = 16'h0000", 16'h0000);


        /*
        ========================================
            Reset during operation Testbench
        ========================================
        */
        
        @ (negedge clk);
        ldAR = 1;
        in_address = 16'h9999;
        @ (posedge clk);
        rst_n = 0;
        #1;
        check_test("Reset during op: out_address = 16'h0000", 16'h0000);
        
        @ (negedge clk);
        rst_n = 1;
        check_test("After Reset release: out_address = 16'h0000", 16'h0000);
        
        
        $display("---------------------------------------");
        $display("Simulare Finalizata!");
        $display("Total Teste: %d", test_count);
        $display("Teste PASS : %d", pass_count);
        $display("Teste FAIL : %d", fail_count);
        $display("---------------------------------------");
    
        #100; $stop;
    end
    
    initial begin
        #5000;
        $display("\nERROR: Testbench timeout!");
        $finish;
    end
endmodule