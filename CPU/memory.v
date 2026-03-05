// Memory: 1KB (1024 x 16-bit words)
module memory (
    input clk,
    input [9:0] addr,
    input [15:0] data_in,
    input we,
    output [15:0] data_out
);
    reg [15:0] mem [0:1023];

    initial begin
        $readmemb("data_bin.txt", mem);
    end
    
    always @(posedge clk) begin
        if (we)
            mem[addr] <= data_in;
    end
    
    assign data_out = mem[addr];
    
endmodule