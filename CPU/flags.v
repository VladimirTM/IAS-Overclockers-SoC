// Flags Register — Z/N/C/O condition codes
// use_direct_value=0: all four flags from ALU; =1: Z/N from direct_value word, C/O cleared
// use_packed_flags=1: restore all four flags from direct_value[15:12] (used by IRET)
module flags (
    input clk,
    input rst_n,
    input ldFLAG,
    input alu_zero,
    input alu_neg,
    input alu_carry,
    input alu_overflow,
    input use_direct_value,
    input use_packed_flags,
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
            end else if (use_packed_flags) begin
                Z <= direct_value[15];
                N <= direct_value[14];
                C <= direct_value[13];
                O <= direct_value[12];
            end else begin
                Z <= alu_zero;
                N <= alu_neg;
                C <= alu_carry;
                O <= alu_overflow;
            end
        end
    end

endmodule