`timescale 1ns/1ns

module flags_tb;

    reg clk;
    reg rst_n;
    reg ldFLAG;
    
    reg alu_zero;
    reg alu_neg;
    reg alu_carry;
    reg alu_overflow;
    reg use_direct_value;
    reg [15:0] direct_value;
    
    wire Z;
    wire N;
    wire C;
    wire O;

    flags uut_flags (
        .clk(clk),
        .rst_n(rst_n),
        .ldFLAG(ldFLAG),
        .alu_zero(alu_zero),
        .alu_neg(alu_neg),
        .alu_carry(alu_carry),
        .alu_overflow(alu_overflow),
        .use_direct_value(use_direct_value),
        .direct_value(direct_value),
        .Z(Z),
        .N(N),
        .C(C),
        .O(O)
    );

    integer test_count = 0;
    integer pass_count = 0;
    integer fail_count = 0;
    
    task check_test;
        input [511:0] test_name;
        input exp_Z;
        input exp_N;
        input exp_C;
        input exp_O;
        
        reg res_ok;
        begin
            test_count = test_count + 1;
            res_ok = (Z === exp_Z) && (N === exp_N) && (C === exp_C) && (O === exp_O);

            if (res_ok) begin
                $display("Test %2d PASS: %s", test_count, test_name);
                pass_count = pass_count + 1;
            end else begin
                $display("Test %2d FAIL: %s", test_count, test_name);
                $display("  -> EROARE: ZNCO primit %b%b%b%b, se astepta %b%b%b%b", Z, N, C, O, exp_Z, exp_N, exp_C, exp_O);
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
        ldFLAG = 0;
        alu_zero = 0;
        alu_neg = 0;
        alu_carry = 0;
        alu_overflow = 0;
        use_direct_value = 0;
        direct_value = 16'h0000;
        
        /*
        ========================================
               FLAGS Module Testbench
        ========================================
        */
        
        /*
        ========================================
             Reset Test
        ========================================
        */
        @ (negedge clk);
        rst_n = 0;
        ldFLAG = 1;
        alu_zero = 1;
        alu_overflow = 1;
        @ (posedge clk);
        @ (negedge clk);
        rst_n = 1; // done like this for iverilog testing script
        check_test("Reset: ZNCO = 0000", 0, 0, 0, 0);

        /*
        ========================================
             ALU Input Mode Tests
        ========================================
        */
        
        @ (negedge clk);
        ldFLAG = 1;
        use_direct_value = 0;
        alu_zero = 1;
        alu_neg = 0;
        alu_carry = 1;
        alu_overflow = 0;
        @ (negedge clk);
        check_test("ALU Inputs -> ZNCO = 1010", 1, 0, 1, 0);
        
        alu_zero = 0;
        alu_neg = 1;
        alu_carry = 0;
        alu_overflow = 1;
        @ (negedge clk);
        check_test("ALU Inputs -> ZNCO = 0101", 0, 1, 0, 1);
        
        ldFLAG = 0;
        alu_zero = 1;
        alu_neg = 0;
        alu_carry = 1;
        alu_overflow = 0;
        @ (negedge clk);
        check_test("Hold Data -> ZNCO = 0101", 0, 1, 0, 1);

        /*
        ========================================
             Direct Value Mode Tests
        ========================================
        */
        
        @ (negedge clk);
        ldFLAG = 1;
        use_direct_value = 1;
        direct_value = 16'h0000;
        alu_zero = 0;
        alu_neg = 1;
        alu_carry = 1; 
        alu_overflow = 1;
        @ (negedge clk);
        check_test("Direct Val 0x0000 -> ZNCO = 1000", 1, 0, 0, 0);
        
        direct_value = 16'hFFFF;
        @ (negedge clk);
        check_test("Direct Val 0xFFFF -> ZNCO = 0100", 0, 1, 0, 0);
        
        direct_value = 16'h0001;
        @ (negedge clk);
        check_test("Direct Val 0x0001 -> ZNCO = 0000", 0, 0, 0, 0);

        /*
        ========================================
            Reset during operation Testbench
        ========================================
        */
        
        @ (negedge clk);
        ldFLAG = 1;
        use_direct_value = 0;
        alu_zero = 1;
        alu_neg = 1; 
        alu_carry = 1;
        alu_overflow = 1;
        @ (posedge clk);
        rst_n = 0;
        #1;
        check_test("Reset during op: ZNCO = 0000", 0, 0, 0, 0);
        
        @ (negedge clk);
        rst_n = 1;
        check_test("After Reset release: ZNCO = 0000", 0, 0, 0, 0);
        
        
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