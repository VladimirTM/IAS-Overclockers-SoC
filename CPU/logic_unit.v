// Logic unit: bitwise operations (AND, OR, XOR, NOT)
module logic_unit (
    input [15:0] operand1,
    input [15:0] operand2,
    input [1:0] op_select,
    output reg [15:0] result
);

    localparam AND_OP = 2'b00;
    localparam OR_OP  = 2'b01;
    localparam XOR_OP = 2'b10;
    localparam NOT_OP = 2'b11;

    always @(*) begin
        case (op_select)
            AND_OP:  result = operand1 & operand2;
            OR_OP:   result = operand1 | operand2;
            XOR_OP:  result = operand1 ^ operand2;
            NOT_OP:  result = ~operand1;
            default: result = 16'd0;
        endcase
    end

endmodule
