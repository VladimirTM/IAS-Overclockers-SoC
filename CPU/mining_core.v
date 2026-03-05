// Mining Core: simplified SHA-256 hash miner
// Implemented using rca, barrel_shifter, and logic_unit sub-components
module mining_core (
    input wire clk,
    input wire reset,
    input wire start,
    input wire [15:0] data_in,
    input wire [15:0] nonce_in,
    input wire [15:0] target,
    output reg [15:0] hash_out,
    output reg [15:0] result_nonce,
    output reg done
);

    localparam [2:0] IDLE = 0, INIT = 1, COMPUTE = 2, CHECK = 3, DONE_STATE = 4;

    reg [2:0] state, next_state;
    reg [15:0] a, b, c, d, e, f, g, h;
    reg [4:0] round;
    reg [15:0] current_nonce;
    reg [15:0] W [0:15];

    wire [15:0] K [0:15];
    assign K[0]  = 16'h428a;
    assign K[1]  = 16'h7137;
    assign K[2]  = 16'hb5c0;
    assign K[3]  = 16'he9b5;
    assign K[4]  = 16'h3956;
    assign K[5]  = 16'h59f1;
    assign K[6]  = 16'h923f;
    assign K[7]  = 16'hab1c;
    assign K[8]  = 16'hd807;
    assign K[9]  = 16'h1283;
    assign K[10] = 16'h2431;
    assign K[11] = 16'h550c;
    assign K[12] = 16'h72be;
    assign K[13] = 16'h80de;
    assign K[14] = 16'h9bdc;
    assign K[15] = 16'hc19b;

    parameter [15:0] H0 = 16'h6a09;
    parameter [15:0] H1 = 16'hbb67;
    parameter [15:0] H2 = 16'h3c6e;
    parameter [15:0] H3 = 16'ha54f;
    parameter [15:0] H4 = 16'h510e;
    parameter [15:0] H5 = 16'h9b05;
    parameter [15:0] H6 = 16'h1f83;
    parameter [15:0] H7 = 16'hd9ab;

    // =========================================================
    // W[0:15] initialization combinational network
    // =========================================================

    // W[2] = data_in ^ current_nonce
    wire [15:0] w2;
    logic_unit lu_w2 (
        .operand1(data_in), .operand2(current_nonce),
        .op_select(2'b10), .result(w2)
    );

    // W[3] = data_in + current_nonce
    wire [16:0] w3_sum;
    rca rca_w3 (
        .x({1'b0, data_in}), .y({1'b0, current_nonce}),
        .cin(1'b0), .z(w3_sum), .cout()
    );

    // W[4] = {data_in[7:0], current_nonce[15:8]} — pure wire, no component needed
    // W[5] = {current_nonce[7:0], data_in[15:8]}  — pure wire, no component needed

    // W[6] = ~(data_in ^ current_nonce)
    wire [15:0] w6_xor, w6;
    logic_unit lu_w6a (
        .operand1(data_in), .operand2(current_nonce),
        .op_select(2'b10), .result(w6_xor)
    );
    logic_unit lu_w6b (
        .operand1(w6_xor), .operand2(16'h0),
        .op_select(2'b11), .result(w6)
    );

    // W[7] = data_in - current_nonce  (two's complement: ~nonce + 1)
    wire [16:0] w7_sum;
    rca rca_w7 (
        .x({1'b0, data_in}), .y({1'b0, ~current_nonce}),
        .cin(1'b1), .z(w7_sum), .cout()
    );

    // W[8] = rotr(data_in, 3) ^ current_nonce
    wire [15:0] w8_rot, w8;
    barrel_shifter bs_w8 (
        .operand(data_in), .shift_amount(5'd3),
        .shift_type(2'b10), .result(w8_rot), .carry_out()
    );
    logic_unit lu_w8 (
        .operand1(w8_rot), .operand2(current_nonce),
        .op_select(2'b10), .result(w8)
    );

    // W[9] = data_in ^ rotr(current_nonce, 5)
    wire [15:0] w9_rot, w9;
    barrel_shifter bs_w9 (
        .operand(current_nonce), .shift_amount(5'd5),
        .shift_type(2'b10), .result(w9_rot), .carry_out()
    );
    logic_unit lu_w9 (
        .operand1(data_in), .operand2(w9_rot),
        .op_select(2'b10), .result(w9)
    );

    // W[10] = (data_in << 2) + current_nonce
    wire [15:0] w10_shift;
    wire [16:0] w10_sum;
    barrel_shifter bs_w10 (
        .operand(data_in), .shift_amount(5'd2),
        .shift_type(2'b00), .result(w10_shift), .carry_out()
    );
    rca rca_w10 (
        .x({1'b0, w10_shift}), .y({1'b0, current_nonce}),
        .cin(1'b0), .z(w10_sum), .cout()
    );

    // W[11] = data_in + (current_nonce >> 3)
    wire [15:0] w11_shift;
    wire [16:0] w11_sum;
    barrel_shifter bs_w11 (
        .operand(current_nonce), .shift_amount(5'd3),
        .shift_type(2'b01), .result(w11_shift), .carry_out()
    );
    rca rca_w11 (
        .x({1'b0, data_in}), .y({1'b0, w11_shift}),
        .cin(1'b0), .z(w11_sum), .cout()
    );

    // W[12] = (data_in & current_nonce) ^ 16'h5a5a
    wire [15:0] w12_and, w12;
    logic_unit lu_w12a (
        .operand1(data_in), .operand2(current_nonce),
        .op_select(2'b00), .result(w12_and)
    );
    logic_unit lu_w12b (
        .operand1(w12_and), .operand2(16'h5a5a),
        .op_select(2'b10), .result(w12)
    );

    // W[13] = (data_in | current_nonce) ^ 16'ha5a5
    wire [15:0] w13_or, w13;
    logic_unit lu_w13a (
        .operand1(data_in), .operand2(current_nonce),
        .op_select(2'b01), .result(w13_or)
    );
    logic_unit lu_w13b (
        .operand1(w13_or), .operand2(16'ha5a5),
        .op_select(2'b10), .result(w13)
    );

    // W[14] = data_in ^ current_nonce ^ 16'hffff
    wire [15:0] w14_xor, w14;
    logic_unit lu_w14a (
        .operand1(data_in), .operand2(current_nonce),
        .op_select(2'b10), .result(w14_xor)
    );
    logic_unit lu_w14b (
        .operand1(w14_xor), .operand2(16'hffff),
        .op_select(2'b10), .result(w14)
    );

    // W[15] = data_in + current_nonce + 16'h1234
    wire [16:0] w15_sum1, w15_sum2;
    rca rca_w15a (
        .x({1'b0, data_in}), .y({1'b0, current_nonce}),
        .cin(1'b0), .z(w15_sum1), .cout()
    );
    rca rca_w15b (
        .x({1'b0, w15_sum1[15:0]}), .y({1'b0, 16'h1234}),
        .cin(1'b0), .z(w15_sum2), .cout()
    );

    // =========================================================
    // SHA-256 round computation combinational network
    // =========================================================

    // sigma1(e) = rotr(e,6) ^ rotr(e,11) ^ rotr(e,15)
    wire [15:0] s1_r6, s1_r11, s1_r15, s1_ab, sigma1_e;
    barrel_shifter bs_s1a (
        .operand(e), .shift_amount(5'd6),
        .shift_type(2'b10), .result(s1_r6), .carry_out()
    );
    barrel_shifter bs_s1b (
        .operand(e), .shift_amount(5'd11),
        .shift_type(2'b10), .result(s1_r11), .carry_out()
    );
    barrel_shifter bs_s1c (
        .operand(e), .shift_amount(5'd15),
        .shift_type(2'b10), .result(s1_r15), .carry_out()
    );
    logic_unit lu_s1a (
        .operand1(s1_r6), .operand2(s1_r11),
        .op_select(2'b10), .result(s1_ab)
    );
    logic_unit lu_s1b (
        .operand1(s1_ab), .operand2(s1_r15),
        .op_select(2'b10), .result(sigma1_e)
    );

    // sigma0(a) = rotr(a,2) ^ rotr(a,7) ^ rotr(a,13)
    wire [15:0] s0_r2, s0_r7, s0_r13, s0_ab, sigma0_a;
    barrel_shifter bs_s0a (
        .operand(a), .shift_amount(5'd2),
        .shift_type(2'b10), .result(s0_r2), .carry_out()
    );
    barrel_shifter bs_s0b (
        .operand(a), .shift_amount(5'd7),
        .shift_type(2'b10), .result(s0_r7), .carry_out()
    );
    barrel_shifter bs_s0c (
        .operand(a), .shift_amount(5'd13),
        .shift_type(2'b10), .result(s0_r13), .carry_out()
    );
    logic_unit lu_s0a (
        .operand1(s0_r2), .operand2(s0_r7),
        .op_select(2'b10), .result(s0_ab)
    );
    logic_unit lu_s0b (
        .operand1(s0_ab), .operand2(s0_r13),
        .op_select(2'b10), .result(sigma0_a)
    );

    // ch(e,f,g) = (e & f) ^ (~e & g)
    wire [15:0] ch1, not_e, ch2, ch_efg;
    logic_unit lu_ch1 (
        .operand1(e), .operand2(f),
        .op_select(2'b00), .result(ch1)
    );
    logic_unit lu_ch2 (
        .operand1(e), .operand2(16'h0),
        .op_select(2'b11), .result(not_e)
    );
    logic_unit lu_ch3 (
        .operand1(not_e), .operand2(g),
        .op_select(2'b00), .result(ch2)
    );
    logic_unit lu_ch4 (
        .operand1(ch1), .operand2(ch2),
        .op_select(2'b10), .result(ch_efg)
    );

    // maj(a,b,c) = (a & b) ^ (a & c) ^ (b & c)
    wire [15:0] maj1, maj2, maj3, maj12, maj_abc;
    logic_unit lu_maj1 (
        .operand1(a), .operand2(b),
        .op_select(2'b00), .result(maj1)
    );
    logic_unit lu_maj2 (
        .operand1(a), .operand2(c),
        .op_select(2'b00), .result(maj2)
    );
    logic_unit lu_maj3 (
        .operand1(b), .operand2(c),
        .op_select(2'b00), .result(maj3)
    );
    logic_unit lu_maj4 (
        .operand1(maj1), .operand2(maj2),
        .op_select(2'b10), .result(maj12)
    );
    logic_unit lu_maj5 (
        .operand1(maj12), .operand2(maj3),
        .op_select(2'b10), .result(maj_abc)
    );

    // T1 = h + sigma1_e + ch_efg + K[round] + W[round]
    wire [16:0] t1_a, t1_b, t1_c, t1_d;
    rca rca_t1a (
        .x({1'b0, h}), .y({1'b0, sigma1_e}),
        .cin(1'b0), .z(t1_a), .cout()
    );
    rca rca_t1b (
        .x({1'b0, t1_a[15:0]}), .y({1'b0, ch_efg}),
        .cin(1'b0), .z(t1_b), .cout()
    );
    rca rca_t1c (
        .x({1'b0, t1_b[15:0]}), .y({1'b0, K[round]}),
        .cin(1'b0), .z(t1_c), .cout()
    );
    rca rca_t1d (
        .x({1'b0, t1_c[15:0]}), .y({1'b0, W[round]}),
        .cin(1'b0), .z(t1_d), .cout()
    );
    wire [15:0] T1_wire;
    assign T1_wire = t1_d[15:0];

    // T2 = sigma0_a + maj_abc
    wire [16:0] t2_sum;
    rca rca_t2 (
        .x({1'b0, sigma0_a}), .y({1'b0, maj_abc}),
        .cin(1'b0), .z(t2_sum), .cout()
    );
    wire [15:0] T2_wire;
    assign T2_wire = t2_sum[15:0];

    // new_a = T1 + T2
    wire [16:0] new_a_sum;
    rca rca_new_a (
        .x({1'b0, T1_wire}), .y({1'b0, T2_wire}),
        .cin(1'b0), .z(new_a_sum), .cout()
    );

    // new_e = d + T1
    wire [16:0] new_e_sum;
    rca rca_new_e (
        .x({1'b0, d}), .y({1'b0, T1_wire}),
        .cin(1'b0), .z(new_e_sum), .cout()
    );

    // hash_comb = (H0 + a) ^ (H4 + e)
    wire [16:0] h_sum1, h_sum2;
    wire [15:0] hash_comb;
    rca rca_h1 (
        .x({1'b0, H0}), .y({1'b0, a}),
        .cin(1'b0), .z(h_sum1), .cout()
    );
    rca rca_h2 (
        .x({1'b0, H4}), .y({1'b0, e}),
        .cin(1'b0), .z(h_sum2), .cout()
    );
    logic_unit lu_hash (
        .operand1(h_sum1[15:0]), .operand2(h_sum2[15:0]),
        .op_select(2'b10), .result(hash_comb)
    );

    // nonce_inc = current_nonce + 1
    wire [16:0] nonce_inc;
    rca rca_nonce (
        .x({1'b0, current_nonce}), .y(17'd1),
        .cin(1'b0), .z(nonce_inc), .cout()
    );

    // =========================================================
    // Sequential FSM
    // =========================================================
    always @(posedge clk or negedge reset) begin
        if (!reset) begin
            state <= IDLE;
            done <= 0;
            hash_out <= 0;
            result_nonce <= 0;
            current_nonce <= 0;
            round <= 0;
            a <= 0; b <= 0; c <= 0; d <= 0;
            e <= 0; f <= 0; g <= 0; h <= 0;
        end else begin
            state <= next_state;

            case (state)
                IDLE: begin
                    done <= 0;
                    if (start) begin
                        current_nonce <= nonce_in;
                    end
                end

                INIT: begin
                    a <= H0;
                    b <= H1;
                    c <= H2;
                    d <= H3;
                    e <= H4;
                    f <= H5;
                    g <= H6;
                    h <= H7;
                    round <= 0;

                    W[0]  <= data_in;
                    W[1]  <= current_nonce;
                    W[2]  <= w2;
                    W[3]  <= w3_sum[15:0];
                    W[4]  <= {data_in[7:0], current_nonce[15:8]};
                    W[5]  <= {current_nonce[7:0], data_in[15:8]};
                    W[6]  <= w6;
                    W[7]  <= w7_sum[15:0];
                    W[8]  <= w8;
                    W[9]  <= w9;
                    W[10] <= w10_sum[15:0];
                    W[11] <= w11_sum[15:0];
                    W[12] <= w12;
                    W[13] <= w13;
                    W[14] <= w14;
                    W[15] <= w15_sum2[15:0];
                end

                COMPUTE: begin
                    a <= new_a_sum[15:0];
                    b <= a;
                    c <= b;
                    d <= c;
                    e <= new_e_sum[15:0];
                    f <= e;
                    g <= f;
                    h <= g;

                    if (round == 15) begin
                        hash_out <= hash_comb;
                    end else begin
                        round <= round + 1;
                    end
                end

                CHECK: begin
                    if (hash_out < target) begin
                        result_nonce <= current_nonce;
                        done <= 1;
                    end else begin
                        current_nonce <= nonce_inc[15:0];
                    end
                end

                DONE_STATE: begin
                    done <= 1;
                end
            endcase
        end
    end

    // =========================================================
    // Next-state logic (combinational)
    // =========================================================
    always @(*) begin
        next_state = state;

        case (state)
            IDLE: begin
                if (start)
                    next_state = INIT;
            end

            INIT: begin
                next_state = COMPUTE;
            end

            COMPUTE: begin
                if (round == 15)
                    next_state = CHECK;
            end

            CHECK: begin
                if (hash_out < target)
                    next_state = DONE_STATE;
                else
                    next_state = INIT;
            end

            DONE_STATE: begin
                if (!start)
                    next_state = IDLE;
            end

            default: next_state = IDLE;
        endcase
    end

endmodule
