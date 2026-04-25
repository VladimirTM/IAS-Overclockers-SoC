// Y Register: general-purpose register with inc/dec
module register_y (
    input clk,
    input rst_n,
    input ldY,
    input incrY,
    input decrY,
    input [15:0] D_in,
    output reg [15:0] Y
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            Y <= 16'h0000;
        end
        else begin
            if (ldY) begin
                Y <= D_in;
            end
            else if (incrY && !decrY) begin
                Y <= Y + 1;
            end
            else if (decrY && !incrY) begin
                Y <= Y - 1;
            end
            // incrY && decrY: mutually exclusive per CU design — no change
        end
    end

endmodule