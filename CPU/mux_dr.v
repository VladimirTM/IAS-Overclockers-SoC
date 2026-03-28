// DR MUX — condDR: 000=mem  001=X  010=Y  011=PC  100=IMM  101=A  110=io_data  111=packed_flags
// Packed flags (3'b111): [15]=Z [14]=N [13]=C [12]=O [11:0]=0
module mux_dr (
    input [15:0] mem,
    input [15:0] X,
    input [15:0] Y,
    input [15:0] PC,
    input [15:0] IMM,
    input [15:0] A,
    input [15:0] io_data,
    input        flags_Z,
    input        flags_N,
    input        flags_C,
    input        flags_O,
    input [2:0] CondDR,
    output reg [15:0] out
);

    always @(*) begin
        case(CondDR)
            3'b000: out = mem;
            3'b001: out = X;
            3'b010: out = Y;
            3'b011: out = PC;
            3'b100: out = IMM;
            3'b101: out = A;
            3'b110: out = io_data;
            3'b111: out = {flags_Z, flags_N, flags_C, flags_O, 12'b0}; // packed flags save
            default: out = 16'h0000;
        endcase
    end

endmodule