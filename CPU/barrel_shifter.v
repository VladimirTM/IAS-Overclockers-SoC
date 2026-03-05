// Barrel shifter: single-cycle shift/rotate operations
module barrel_shifter (
    input [15:0] operand,
    input [4:0] shift_amount,
    input [1:0] shift_type,
    output reg [15:0] result,
    output reg carry_out
);

    localparam LSL = 2'b00;
    localparam LSR = 2'b01;
    localparam RSR = 2'b10;
    localparam RSL = 2'b11;

    always @(*) begin
        case (shift_type)
            LSL: begin
                result = operand << shift_amount;
                if (shift_amount == 5'd0)
                    carry_out = 1'b0;
                else if (shift_amount <= 5'd16)
                    carry_out = operand[16 - shift_amount];
                else
                    carry_out = 1'b0;
            end

            LSR: begin
                result = operand >> shift_amount;
                if (shift_amount == 5'd0)
                    carry_out = 1'b0;
                else if (shift_amount <= 5'd16)
                    carry_out = operand[shift_amount - 1];
                else
                    carry_out = 1'b0;
            end

            RSR: begin
                result = (operand >> shift_amount) | (operand << (16 - shift_amount));
                if (shift_amount == 5'd0)
                    carry_out = 1'b0;
                else
                    carry_out = operand[shift_amount - 1];
            end

            RSL: begin
                result = (operand << shift_amount) | (operand >> (16 - shift_amount));
                if (shift_amount == 5'd0)
                    carry_out = 1'b0;
                else
                    carry_out = operand[16 - shift_amount];
            end

            default: begin
                result = 16'd0;
                carry_out = 1'b0;
            end
        endcase
    end

endmodule
