// PC MUX: selects next PC value
module mux_pc (
    input [15:0] PC_hold,
    input [15:0] PC_inc,
    input [15:0] PC_imm,
    input [15:0] PC_dr,
    input [1:0] CondPC,
    output reg [15:0] out
);

    always @(*) begin
        case (CondPC)
            2'b00: out = PC_hold;
            2'b01: out = PC_inc;
            2'b10: out = PC_imm;
            2'b11: out = PC_dr;
            default: out = PC_hold;
        endcase
    end

endmodule
