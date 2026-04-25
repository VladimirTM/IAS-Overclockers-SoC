`timescale 1ns / 1ns

module instruction_register_tb;

reg clk;
reg rst_n;
reg ldIR;
reg [15:0] in_instruction;

wire [15:0] instruction; 

instruction_register uut_ir (
    .clk(clk),
    .rst_n(rst_n),
    .ldIR(ldIR),
    .in_instruction(in_instruction),
    .instruction(instruction)
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
        res_ok = (instruction == exp_rez);

        if (res_ok) begin
          
            $display("Test %2d PASS: %s", test_count, test_name);
            pass_count = pass_count + 1;
            
        end else begin
          
            $display("Test %2d FAIL: %s", test_count, test_name);
            $display("  -> FAIL: got %h, expected %h", instruction, exp_rez);
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
    rst_n = 1;
    ldIR = 0;
    in_instruction = 16'hFFFF;
    
    @ (negedge clk);
    rst_n = 0;
    @ (posedge clk);
    rst_n = 1;
    @ (negedge clk);
    check_test ("Reset: instruction = 16'h0000", 16'h0000);
    
    in_instruction = 16'hAAAA;
    ldIR = 1;
    @ (negedge clk);
    check_test ("Load Data: instruction = 16'hAAAA", 16'hAAAA);
    
    ldIR = 0;
    in_instruction = 16'hDEAD;
    @ (negedge clk);
    check_test ("Hold Data: instruction = 16'hAAAA", 16'hAAAA);
    
    ldIR = 1;
    in_instruction = 16'hBEEF;
    @ (negedge clk);
    check_test ("Load Data: instruction = 16'hBEEF", 16'hBEEF);
    
    in_instruction = 16'hCAFE;
    @ (posedge clk);
    rst_n = 0;
    @ (negedge clk);
    rst_n = 1;
    check_test ("Reset: instruction = 16'h0000", 16'h0000);
    
    ldIR = 1;
    in_instruction = 16'hCAFE;
    @ (negedge clk);
    check_test ("Load Data: instruction = 16'hCAFE", 16'hCAFE);

    $display("---------------------------------------");
    $display("Simulation done!");
    $display("Total Teste: %d", test_count);
    $display("Teste PASS : %d", pass_count);
    $display("Teste FAIL : %d", fail_count);
    $display("---------------------------------------");
    
    #100; $stop;
end

/*
initial begin
    $dumpfile("ir_waves.vcd");
    $dumpvars(0, ir_tb); 
end
*/

endmodule