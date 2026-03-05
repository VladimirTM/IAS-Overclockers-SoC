// Address Register: holds memory address for fetch/store
module address_register (
    input clk,
    input rst_n,
    input ldAR,
    input [15:0] in_address,
    output reg [15:0] out_address
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_address <= 16'h0000;
        end 
        else if (ldAR) begin
            out_address <= in_address;
        end
    end

endmodule