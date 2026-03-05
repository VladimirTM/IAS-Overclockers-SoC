`timescale 1ns / 1ns

module accumulator_tb;

reg clk;
reg reset;
reg ldA;
reg use_imm;
reg [15:0] D_in;
reg [15 : 0] imm_in;
wire [15:0] A; 

accumulator uut_a (
    .clk(clk),
    .reset(reset),
    .ldA(ldA),
    .use_imm (use_imm),
    .D_in(D_in),
    .imm_in (imm_in),
    .A(A)
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
        res_ok = (A == exp_rez);

        if (res_ok) begin
          
            $display("Test %2d PASS: %s", test_count, test_name);
            pass_count = pass_count + 1;
            
        end else begin
          
            $display("Test %2d FAIL: %s", test_count, test_name);
            $display("  -> EROARE REZULTAT: S-a primit %h, se astepta %h", A, exp_rez);
            fail_count = fail_count + 1;
            
        end
    end
endtask

parameter halfT = 5; 

initial begin
    clk = 0; 
    forever #(halfT) clk = ~clk; 
end

initial begin
    // Init›ializare
    reset = 1;
    ldA = 0;
    use_imm = 0;
    D_in = 16'hAAAA;
    imm_in = 16'hEEEE;
    
    @ (posedge clk);
    reset = 0;
    @ (negedge clk);
    reset = 1;
    
    @ (posedge clk);
    check_test ("Reset: A = 16'h0000", 16'h0000);
    
    @ (negedge clk);
    ldA = 1;
    @ (negedge clk);
    check_test ("Load Data: A = D_in", D_in);
    
    ldA = 0;
    D_in = 16'hDEAD;
    @ (negedge clk);
    check_test ("Hold Data: A = 16'hAAAA", 16'hAAAA);
    
    use_imm = 1;
    D_in = 16'hDEAD;
    imm_in = 16'hDAED;
    @ (negedge clk);
    check_test ("Hold Data: A = 16'hAAAA", 16'hAAAA);
    
    ldA = 1;
    use_imm = 1;
    D_in = 16'hBEEF;
    imm_in = 16'hEEEE;
    @ (negedge clk);
    check_test ("Load immData: A = imm_in", imm_in);
    
    ldA = 0;
    D_in = 16'hDEAD;
    imm_in = 16'hDAED;
    @ (negedge clk);
    check_test ("Hold immData: A = 16'hEEEE", 16'hEEEE);
    
    ldA = 0;
    use_imm = 0;
    @ (negedge clk);
    check_test ("Hold immData: A = 16'hEEEE", 16'hEEEE);
    
    ldA = 1;
    use_imm = 0;
    D_in = 16'hAAAA;
    @ (negedge clk);
    check_test ("Load Data: A = D_in", D_in);
    
    @ (posedge clk);
    reset = 0;
    @ (negedge clk);
    reset = 1;
    check_test ("Reset: A = 16'h0000", 16'h0000);
    
    @ (negedge clk);
    check_test ("Load Data: A = D_in", D_in);

    $display("---------------------------------------");
    $display("Simulare Finalizata!");
    $display("Total Teste: %d", test_count);
    $display("Teste PASS : %d", pass_count);
    $display("Teste FAIL : %d", fail_count);
    $display("---------------------------------------");
    
    #100; $stop;
end

/*
// don't know if this is used for easyEDA iverilog, modelsim gives design error
initial begin
    $dumpfile("Register_A.vcd"); 
    $dumpvars(0, Register_A_tb); 
end
*/

endmodule