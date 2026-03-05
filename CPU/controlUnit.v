// Control Unit: FSM managing all ALU operations
module controlUnit (
    input clk,
    input rst_b,
    input core_start,
    input [3:0] operation_type,
    input is_compare,
    input [2:0] cazM,
    input M_7,
    input A_8,
    input [2:0] q,
    input CNT3,
    input CNT0,
    input shift_done,
    output s0, s1, s2, s3, s4,
    output m0, m1, m2, m3, m4, m5, m6, m7, m8,
    output d0, d1, d2, d3, d4, d5, d6, d7, d8, d9, d10, d11, d12, d13, d14, d15, d16, d17,
    output d18,
    output d_pre1, d_pre2, d_post,
    output l0, l1,
    output sh0, sh1,
    output logic_enable,
    output shift_start,
    output END,
    output idle
);

    localparam A0 = 0;
    localparam S0 = 1;
    localparam S1 = 2;
    localparam S2 = 3;
    localparam S4 = 4;
    localparam M0 = 5;
    localparam M1 = 6;
    localparam M2 = 7;
    localparam M5 = 8;
    localparam M6 = 9;
    localparam M7 = 10;
    localparam M8 = 11;
    localparam D0 = 12;
    localparam D1 = 13;
    localparam D2 = 14;
    localparam D3 = 15;
    localparam D4 = 16;
    localparam D5 = 17;
    localparam D6 = 18;
    localparam D7 = 19;
    localparam D8 = 20;
    localparam D9 = 21;
    localparam D10 = 22;
    localparam D11 = 23;
    localparam D18 = 24;
    localparam D_PRE1 = 29;
    localparam D_PRE2 = 30;
    localparam D_POST = 31;
    localparam L0 = 25;
    localparam L1 = 26;
    localparam SH0 = 27;
    localparam SH1 = 28;

    reg [31:0] st;
    wire [31:0] st_next;

    assign st_next[A0] = (st[A0] & ~core_start) | st[S4] | st[M8] | st[D11] | st[D18] | st[L1] | st[SH1];

    assign st_next[S0] = st[A0] & core_start & (operation_type == 4'd0 | operation_type == 4'd1);
    assign st_next[S1] = st[S0];
    assign st_next[S2] = st[S1];
    assign st_next[S4] = st[S2];

    assign st_next[M0] = st[A0] & core_start & (operation_type == 4'd2);
    assign st_next[M1] = st[M0];
    assign st_next[M2] = (st[M1] | st[M6]) & ((~cazM[2] & cazM[0]) | (cazM[1] & ~cazM[0]) | (cazM[2] & ~cazM[1]));
    assign st_next[M5] = ((st[M1] | st[M6]) & ((~cazM[2] & ~cazM[1] & ~cazM[0]) | (cazM[2] & cazM[1] & cazM[0]))) | st[M2];
    assign st_next[M6] = st[M5] & ~CNT3;
    assign st_next[M7] = st[M5] & CNT3;
    assign st_next[M8] = st[M7];

    // Sign pre-processing states
    assign st_next[D_PRE1] = st[A0] & core_start & (operation_type == 4'd3 | operation_type == 4'd4);
    assign st_next[D_PRE2] = st[D_PRE1];
    assign st_next[D0] = st[D_PRE2];

    // Division states
    assign st_next[D1] = st[D0];
    assign st_next[D2] = (st[D1] | st[D2]) & ~M_7;
    assign st_next[D3] = (st[D1] | st[D2]) & M_7 | st[D6];
    assign st_next[D4] = st[D3];
    assign st_next[D5] = st[D4];
    assign st_next[D6] = st[D5] & ~CNT3;
    assign st_next[D7] = st[D5] & CNT3 & A_8;
    assign st_next[D8] = st[D5] & CNT3 & ~A_8 | st[D7];
    assign st_next[D9] = (st[D8] | st[D9]) & ~CNT0;
    assign st_next[D10] = (st[D8] | st[D9]) & CNT0;

    // Sign post-processing state
    assign st_next[D_POST] = st[D10];
    assign st_next[D11] = st[D_POST] & (operation_type == 4'd3);
    assign st_next[D18] = st[D_POST] & (operation_type == 4'd4);

    assign st_next[L0] = st[A0] & core_start & (operation_type >= 4'd5 & operation_type <= 4'd8);
    assign st_next[L1] = st[L0];

    assign st_next[SH0] = st[A0] & core_start & (operation_type >= 4'd9 & operation_type <= 4'd12);
    assign st_next[SH1] = st[SH0] & shift_done;

    assign s0 = st[S0];
    assign s1 = st[S1];
    assign s2 = st[S2];
    assign s3 = (operation_type == 4'd1);
    assign s4 = st[S4];

    assign m0 = st[M0];
    assign m1 = st[M1];
    assign m2 = st[M2] & ((~cazM[2] & cazM[0]) | (cazM[1] & ~cazM[0]) | (cazM[2] & ~cazM[1]));
    assign m3 = st[M2] & ((~cazM[2] & cazM[1] & cazM[0]) | (cazM[2] & ~cazM[1] & ~cazM[0]));
    assign m4 = st[M2] & ((cazM[2] & ~cazM[1]) | (cazM[2] & ~cazM[0]));
    assign m5 = st[M5];
    assign m6 = st[M6];
    assign m7 = st[M7];
    assign m8 = st[M8];

    assign d0 = st[D0];
    assign d1 = st[D1];
    assign d2 = st[D2];
    assign d3 = st[D3];
    assign d4 = st[D4];
    assign d5 = st[D4] & (q[2] & q[1] & ~q[0]);
    assign d6 = st[D4] & (q[2] & q[1] & q[0]);
    assign d7 = st[D4] & (~q[2] & ~q[1] & q[0]);
    assign d8 = st[D4] & (~q[2] & q[1] & ~q[0]);
    assign d9 = (st[D5] & ((~q[2] & ~q[1] & q[0]) | (q[1] & ~q[0]) | (q[2] & q[1]))) | st[D7];
    assign d10 = st[D5] & (q[1] & ~q[0]);
    assign d11 = st[D5] & ((~q[2] & ~q[1] & q[0]) | (~q[2] & q[1] & ~q[0])) | st[D8];
    assign d12 = st[D6];
    assign d13 = st[D7];
    assign d14 = st[D8];
    assign d15 = st[D9];
    assign d16 = st[D10] & (operation_type == 4'd3);
    assign d17 = st[D11];
    assign d18 = st[D18];
    assign d_pre1 = st[D_PRE1];
    assign d_pre2 = st[D_PRE2];
    assign d_post = st[D_POST];

    assign l0 = st[L0];
    assign l1 = st[L1];
    assign sh0 = st[SH0];
    assign sh1 = st[SH1];

    assign logic_enable = st[L0];
    assign shift_start = st[SH0];

    always @(negedge clk or negedge rst_b) begin
        if (rst_b == 0) begin
            st <= 0;
            st[A0] <= 1;
        end
        else if (clk == 0)
            st <= st_next;
    end

    assign END = s4 | m7 | m8 | d16 | d17 | d18 | l1 | sh1;
    assign idle = st[A0];

endmodule
