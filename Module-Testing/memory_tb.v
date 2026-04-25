`timescale 1ns / 1ns

module memory_tb;

reg clk;
reg [9:0] addr;
reg [15:0] data_in;
reg we;
wire [15:0] data_out;

memory uut_mem (
    .clk(clk),
    .addr(addr),
    .data_in(data_in),
    .we(we),
    .data_out(data_out)
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
        res_ok = (data_out == exp_rez);

        if (res_ok) begin
            $display("Test %2d PASS: %s", test_count, test_name);
            pass_count = pass_count + 1;
        end else begin
            $display("Test %2d FAIL: %s", test_count, test_name);
            $display("  -> FAIL: got %h, expected %h", data_out, exp_rez);
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
    
    we = 0;
    addr = 0;
    data_in = 16'h0000;
    
    #(halfT * 4);
    
    @ (negedge clk);
    check_test ("Read Addr 0: data_out = 16'h0000", 16'h0000);
    
    @ (negedge clk);
    we = 1;
    addr = 10'd0;
    data_in = 16'hAAAA;
    @ (posedge clk);
    @ (negedge clk);
    we = 0; // done like this for iverilog testing script
    check_test ("Write/Read Addr 0: data_out = 16'hAAAA", 16'hAAAA);
    
    @ (negedge clk);
    check_test ("Hold Data Addr 0: data_out = 16'hAAAA", 16'hAAAA);
    
    we = 1;
    addr = 10'd512;
    data_in = 16'hBEEF;
    @ (posedge clk);
    @ (negedge clk);
    we = 0; // done like this for iverilog testing script
    check_test ("Write/Read Addr 512: data_out = 16'hBEEF", 16'hBEEF);

    we = 0;
    addr = 10'd512;
    data_in = 16'hFFFF;
    @ (negedge clk);
    check_test ("Hold Data Addr 512: data_out = 16'hBEEF", 16'hBEEF);
    
    we = 0;
    addr = 10'd0;
    @ (negedge clk);
    check_test ("Hold Data Addr 0: data_out = 16'hAAAA", 16'hAAAA);

    we = 1;
    addr = 10'd512;
    data_in = 16'h1234;
    
    @ (negedge clk);
    we = 0; // done like this for iverilog testing script
    check_test ("Overwrite Addr 512: data_out = 16'h1234", 16'h1234);
    
    addr = 10'd256;
    @ (negedge clk);
    check_test ("Hold Data Addr 256: data_out = 16'h0000", 16'h0000);

    $display("---------------------------------------");
    $display("Simulation done!");
    $display("Total Teste: %d", test_count);
    $display("Teste PASS : %d", pass_count);
    $display("Teste FAIL : %d", fail_count);
    $display("---------------------------------------");
    
    #100; $stop;
end

/* memory.v uses $readmemb("data_bin.txt", mem); ensure the file exists in the sim directory,
   otherwise write/read tests above still pass. */

endmodule