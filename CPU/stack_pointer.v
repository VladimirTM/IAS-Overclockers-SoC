// Stack Pointer: grows downward from 0x03FF
module stack_pointer (
    input clk,
    input rst_n,
    input incSP,
    input decSP,
    output reg [15:0] sp_out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sp_out <= 16'h03ff;
        end 
        else if (incSP) begin
            sp_out <= sp_out + 1;
        end
        else if (decSP) begin
            sp_out <= sp_out - 1;
        end
    end

endmodule