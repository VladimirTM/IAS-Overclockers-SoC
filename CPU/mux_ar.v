// AR MUX — condAR: 00=PC  01=SP  10=IMM  11=AR_EXT (I/O page / IVT)
module mux_ar (
    input [15:0] PC,
    input [15:0] SP,
    input [15:0] IMM,
    input [15:0] AR_EXT,
    input [1:0] CondAR,
    output reg [15:0] out
);

    always @(*) begin
        case(CondAR)
            2'b00: out = PC;
            2'b01: out = SP;
            2'b10: out = IMM;
            2'b11: out = AR_EXT;  // I/O page or IVT entry
            default: out = 16'h0000;
        endcase
    end

endmodule