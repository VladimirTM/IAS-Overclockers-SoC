// Z/N/C/O flags; use_packed_flags restores from DR[15:12] (IRET); alu_exc sets O only
module flags (
    input clk,
    input rst_n,
    input ldFLAG,
    input alu_zero,
    input alu_neg,
    input alu_carry,
    input alu_overflow,
    input alu_exc,
    input use_direct_value,
    input use_packed_flags,
    input use_xy_for_flags,  // 1 when source is X/Y (INC/DEC), 0 for MOV/MOVR
    input is_decrement,      // 1 for DEC, 0 for INC (only meaningful with use_xy_for_flags)
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
            if (alu_exc) begin
                Z <= 0; N <= 0; C <= 0; O <= 1;  // division-by-zero
            end else if (use_direct_value) begin
                Z <= (direct_value == 16'h0000);
                N <= direct_value[15];
                if (use_xy_for_flags) begin
                    // C: result is 0 (INC wrapped) or FFFF (DEC underflowed); O: signed boundary crossed
                    C <= is_decrement ? (direct_value == 16'hFFFF) : (direct_value == 16'h0000);
                    O <= is_decrement ? (direct_value == 16'h7FFF) : (direct_value == 16'h8000);
                end else begin
                    C <= 0;
                    O <= 0;
                end
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