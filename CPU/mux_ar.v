// AR MUX: selects source for address register
module mux_ar (
    input [15:0] PC,
    input [15:0] SP,
    input [15:0] IMM,
    input [1:0] CondAR,
    output reg [15:0] out
);

    always @(*) begin
        case(CondAR)
            2'b00: out = PC;
            2'b01: out = SP;
            2'b10: out = IMM;
            default: out = 16'h0000;
        endcase
    end
  
endmodule