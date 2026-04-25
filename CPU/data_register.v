// Data Register: buffers data to/from memory
module data_register (
    input ldDR,
    input clk,
    input rst_n,
    input [15:0] DR_in,
    output reg [15:0] DR_out
);

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            DR_out <= 16'h0000;
        else if(ldDR)
            DR_out <= DR_in;
    end
  
endmodule