// Program Counter: tracks instruction address
module program_counter (
    input clk,
    input rst_n,
    input incPC,
    input ldPC,
    input ldPCfromDR,
    input [15:0] in_pc_imm,
    input [15:0] in_pc_dr,
    output reg [15:0] pc_out
);

    wire [15:0] pc_inc;
    wire [15:0] mux_out;
    wire [1:0] condPC;

    assign pc_inc = pc_out + 1;

    assign condPC = (ldPC && ldPCfromDR) ? 2'b11 :
                    (ldPC && !ldPCfromDR) ? 2'b10 :
                    (incPC) ? 2'b01 :
                    2'b00;

    mux_pc mux_pc_inst (
        .PC_hold(pc_out),
        .PC_inc(pc_inc),
        .PC_imm(in_pc_imm),
        .PC_dr(in_pc_dr),
        .CondPC(condPC),
        .out(mux_out)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc_out <= 16'h0000;
        end
        else begin
            pc_out <= mux_out;
        end
    end

endmodule