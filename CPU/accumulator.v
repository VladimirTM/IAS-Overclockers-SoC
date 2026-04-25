// Accumulator: ALU result register with immediate support
module accumulator (
    input clk,
    input rst_n,
    input ldA,
    input use_imm,
    input [15:0] D_in,
    input [15:0] imm_in,
    output reg [15:0] A
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            A <= 16'h0000;
        end
        else begin
            if (ldA) begin
                if (use_imm)
                    A <= imm_in;
                else
                    A <= D_in;
            end
        end
    end

endmodule