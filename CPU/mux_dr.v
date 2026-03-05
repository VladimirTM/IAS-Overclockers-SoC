// DR MUX: selects source for data register
module mux_dr (
    input [15:0] mem,
    input [15:0] X,
    input [15:0] Y,
    input [15:0] PC,
    input [15:0] IMM,
    input [15:0] A,
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
            default: out = 16'h0000;
        endcase
    end

endmodule