// X Register: general-purpose register with inc/dec
module register_x (
    input clk,
    input reset,
    input ldX,
    input incrX,
    input decrX,
    input [15:0] D_in,
    output reg [15:0] X
);

    always @(posedge clk or negedge reset) begin
        if (!reset) begin
            X <= 16'h0000;
        end
        else begin
            if (ldX) begin
                X <= D_in;
            end
            else if (incrX && !decrX) begin
                X <= X + 1;
            end
            else if (decrX && !incrX) begin
                X <= X - 1;
            end
        end
    end

endmodule
