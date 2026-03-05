// ALU MUX: selects ALU input (opcode, operands, immediate)
module mux_alu (
    input [15:0] opcode,
    input [15:0] A,
    input [15:0] X,
    input [15:0] Y,
    input [15:0] IMM,
    input regaddr,
    input [1:0] CondALU,
    output reg [15:0] out
);

    always @(*) begin
        case (CondALU)
            2'b00: out = opcode;
            2'b01: out = A;
            2'b10: begin
                if (regaddr == 1'b0)
                    out = X;
                else
                    out = Y;
            end
            2'b11: out = IMM;
            default: out = opcode;
        endcase
    end

endmodule
