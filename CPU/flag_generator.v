// Flag generator: computes Z, N, C, O flags
module flag_generator (
    input [15:0] result,
    input [16:0] extended_result,
    input [3:0] operation_type,
    input [15:0] operand1,
    input [15:0] operand2,
    input shift_carry,
    output reg Z,
    output reg N,
    output reg C,
    output reg O
);

    localparam OP_ADD = 4'd0;
    localparam OP_SUB = 4'd1;
    localparam OP_MUL = 4'd2;
    localparam OP_DIV = 4'd3;
    localparam OP_MOD = 4'd4;
    localparam OP_AND = 4'd5;
    localparam OP_OR  = 4'd6;
    localparam OP_XOR = 4'd7;
    localparam OP_NOT = 4'd8;
    localparam OP_LSL = 4'd9;
    localparam OP_LSR = 4'd10;
    localparam OP_RSR = 4'd11;
    localparam OP_RSL = 4'd12;

    always @(*) begin
        Z = (result == 16'd0);
        N = result[15];

        case (operation_type)
            OP_ADD: begin
                C = extended_result[16];
            end

            OP_SUB: begin
                C = ~extended_result[16];
            end

            OP_LSL, OP_LSR, OP_RSR, OP_RSL: begin
                C = shift_carry;
            end

            OP_MUL: begin
                C = (extended_result[16:15] != 2'b00) && (extended_result[16:15] != 2'b11);
            end

            default: begin
                C = 1'b0;
            end
        endcase

        case (operation_type)
            OP_ADD: begin
                O = (operand1[15] == operand2[15]) && (result[15] != operand1[15]);
            end

            OP_SUB: begin
                O = (operand1[15] != operand2[15]) && (result[15] != operand1[15]);
            end

            OP_MUL: begin
                O = (extended_result[16:15] != {2{result[15]}});
            end

            default: begin
                O = 1'b0;
            end
        endcase
    end

endmodule
