// Instruction Register: holds current instruction
module instruction_register (
    input clk,
    input rst_n,
    input ldIR,
    input [15:0] in_instruction,
    output reg [15:0] instruction
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            instruction <= 16'h0000;
        end 
        else if (ldIR) begin
            instruction <= in_instruction;
        end
    end

endmodule