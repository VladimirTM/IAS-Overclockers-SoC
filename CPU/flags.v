// Flags Register: Z(zero), N(negative), C(carry), O(overflow)
module flags (
    input clk,
    input rst_n,
    input ldFLAG,
    input alu_zero,
    input alu_neg,
    input alu_carry,
    input alu_overflow,
    input use_direct_value,
    input [15:0] direct_value,
    output reg Z,
    output reg N,
    output reg C,
    output reg O
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            Z <= 0;
            N <= 0;
            C <= 0;
            O <= 0;
        end
        else if (ldFLAG) begin
            if (use_direct_value) begin
                Z <= (direct_value == 16'h0000);
                N <= direct_value[15];
                C <= 0;
                O <= 0;
            end else begin
                Z <= alu_zero;
                N <= alu_neg;
                C <= alu_carry;
                O <= alu_overflow;
            end
        end
    end

endmodule