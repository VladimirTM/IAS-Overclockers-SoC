`timescale 1ns/1ns

module data_register_tb;
  
    reg clk;
    reg rst;
    reg ldDR;
    reg [15:0] DR_in;
    wire [15:0] DR_out;
    
    reg [15:0] mem;
    reg [15:0] X;
    reg [15:0] Y;
    reg [15:0] PC;
    reg [15:0] IMM;
    reg [15:0] A;
    reg [2:0]  CondDR;
    wire [15:0] mux_out;

    data_register uut_dr (
        .ldDR(ldDR),
        .clk(clk),
        .rst_n(rst),
        .DR_in(DR_in),
        .DR_out(DR_out)
    );

    mux_dr uut_mux (
        .mem(mem),
        .X(X),
        .Y(Y),
        .PC(PC),
        .IMM(IMM),
        .A(A),
        .io_data(16'h0000),
        .flags_Z(1'b0),
        .flags_N(1'b0),
        .flags_C(1'b0),
        .flags_O(1'b0),
        .CondDR(CondDR),
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
        res_ok = (DR_out == exp_rez);

        if (res_ok) begin
          
            $display("Test %2d PASS: %s", test_count, test_name);
            pass_count = pass_count + 1;
            
        end else begin
          
            $display("Test %2d FAIL: %s", test_count, test_name);
            $display("  -> FAIL: got %h, expected %h", DR_out, exp_rez);
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
            $display("  -> FAIL: got %h, expected %h", mux_out, exp_rez);
            fail_count = fail_count + 1;
            
        end
    end
endtask
    
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    initial begin
        rst = 1;
        ldDR = 0;
        DR_in = 0;
        mem = 16'hAAAA;
        X = 16'hBBBB;
        Y = 16'hCCCC;
        PC = 16'hDDDD;
        IMM = 16'hDEAD;
        A = 16'hABCD;
        CondDR = 3'b000;
        
        /*
        ========================================
            DR and muxDR Module Testbench
        ========================================
        */
        
        /*
        ========================================
            dr SubModule Testbench
        ========================================
        */
        
        @ (negedge clk);
        rst = 0;
        DR_in = 16'hFFFF;
        ldDR = 1;
        @ (posedge clk);
        @ (negedge clk);
        rst = 1; // done like this for iverilog testing script
        check_test("Reset: DR_out = 16'h0000", 16'h0000);
        
        @ (negedge clk);
        ldDR = 1;
        DR_in = 16'h1234;
        @ (negedge clk);
        check_test("Load Data: DR_out = 16'h1234", 16'h1234);
        
        @ (negedge clk);
        rst = 1;
        @ (negedge clk);
        rst = 0;
        
        @ (negedge clk);
        rst = 1;
        ldDR = 1;
        DR_in = 16'h5678;
        @ (negedge clk);
        ldDR = 0;
        check_test("Load Data: DR_out = 16'h5678", 16'h5678);
        
        @ (negedge clk);
        ldDR = 1;
        DR_in = 16'hABCD;
        @ (negedge clk);
        check_test("Load Data: DR_out = 16'hABCD", 16'hABCD);
        
        @ (negedge clk);
        ldDR = 0;
        DR_in = 16'hFFFF;
        @ (negedge clk);
        check_test("Hold Data: DR_out = 16'hABCD", 16'hABCD);
        
        @ (negedge clk);
        check_test("Hold Data: DR_out = 16'hABCD", 16'hABCD);
        
        /*
        ========================================
            mux_dr SubModule Testbench
        ========================================
        */
        
        CondDR = 3'b000;
        #1;
        
        check_test_MUX("CondDR=000 (mem): mux_out = mem", mem);
        
        CondDR = 3'b001;
        #1;
        
        check_test_MUX("CondDR=001 (X): mux_out = X", X);
        
        CondDR = 3'b010;
        #1;
        
        check_test_MUX("CondDR=010 (Y): mux_out = Y", Y);
        
        CondDR = 3'b011;
        #1;
        
        check_test_MUX("CondDR=011 (PC): mux_out = PC", PC);
        
        CondDR = 3'b100;
        #1;
        
        check_test_MUX("CondDR=100 (IMM): mux_out = IMM", IMM);
        
        CondDR = 3'b101;
        #1;
        
        check_test_MUX("CondDR=101 (A): mux_out = A", 16'hABCD);
        
        CondDR = 3'b110;
        #1;
        
        check_test_MUX("CondDR=110 (io_data=0): mux_out = 16'h0000", 16'h0000);

        CondDR = 3'b111;
        #1;

        check_test_MUX("CondDR=111 (flags=0): mux_out = 16'h0000", 16'h0000);
        
        /*
        ========================================
            DR and muxDR SubModule Integration Testbench
        ========================================
        */
        
        @ (negedge clk);
        ldDR = 1;
        CondDR = 3'b000;
        #1;
        DR_in = mux_out;
        @ (negedge clk);
        check_test("Selected mem -> DR_out = mem", mem);
        
        @ (negedge clk);
        CondDR = 3'b001;
        #1;
        DR_in = mux_out;
        @ (negedge clk);
        check_test("Selected X -> DR_out = X", X);
        
        @ (negedge clk);
        CondDR = 3'b010;
        #1;
        DR_in = mux_out;
        @ (negedge clk);
        check_test("Selected Y -> DR_out = Y", Y);
        
        @ (negedge clk);
        CondDR = 3'b011;
        #1;
        DR_in = mux_out;
        @ (negedge clk);
        check_test("Selected PC -> DR_out = PC", PC);
        
        @ (negedge clk);
        CondDR = 3'b100;
        #1;
        DR_in = mux_out;
        @ (negedge clk);
        check_test("Selected IMM -> DR_out = IMM", IMM);
        
        @ (negedge clk);
        CondDR = 3'b101;
        #1;
        DR_in = mux_out;
        @ (negedge clk);
        check_test("Selected A -> DR_out = A", 16'hABCD);
        
        @ (negedge clk);
        CondDR = 3'b110;
        #1;
        DR_in = mux_out;
        @ (negedge clk);
        check_test("Selected io_data=0 (110) -> DR_out = 16'h0000", 16'h0000);

        @ (negedge clk);
        CondDR = 3'b111;
        #1;
        DR_in = mux_out;
        @ (negedge clk);
        check_test("Selected flags=0 (111) -> DR_out = 16'h0000", 16'h0000);
        
        /*
        ========================================
            dr SubModule Reset during operation Testbench
        ========================================
        */
        
        @ (negedge clk);
        ldDR = 1;
        DR_in = 16'h9999;
        @ (posedge clk);
        rst = 0;
        #1;
        check_test("Reset during operation: DR_out = 16'h0000", 16'h0000);
        @ (negedge clk);
        rst = 1;
        check_test("Reset during operation: DR_out = 16'h0000", 16'h0000);
        @ (posedge clk);
        check_test("Reset during operation: DR_out = 16'h0000", 16'h0000);
        @ (negedge clk);
        check_test("Reset during operation: DR_out = 16'h9999", DR_in);
        
        $display("---------------------------------------");
        $display("Simulation done!");
        $display("Total Teste: %d", test_count);
        $display("Teste PASS : %d", pass_count);
        $display("Teste FAIL : %d", fail_count);
        $display("---------------------------------------");
    
        #100; $stop;
    end
    
    /*
    // don't know if this is used for easyEDA iverilog, modelsim gives design error
    initial begin
        $dumpfile("dr_mux_tb.vcd");
        $dumpvars(0, DR_muxDR_tb);
    end
    */
    
    initial begin
        #5000;
        $display("\nERROR: Testbench timeout!");
        $finish;
    end
endmodule