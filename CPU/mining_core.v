// Mining Core: simplified SHA-256 hash miner
module mining_core (
    input clk,
    input rst_n,
    input start,
    input [15:0] data_in,
    input [15:0] nonce_in,
    input [15:0] target,
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

    integer _wi;
    initial begin
        for (_wi = 0; _wi < 16; _wi = _wi + 1) W[_wi] = 16'h0000;
    end

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

    localparam [15:0] H0 = 16'h6a09;
    localparam [15:0] H1 = 16'hbb67;
    localparam [15:0] H2 = 16'h3c6e;
    localparam [15:0] H3 = 16'ha54f;
    localparam [15:0] H4 = 16'h510e;
    localparam [15:0] H5 = 16'h9b05;
    localparam [15:0] H6 = 16'h1f83;
    localparam [15:0] H7 = 16'hd9ab;

    // W-schedule combinatorial values (computed from data_in and current_nonce)
    wire [15:0] w2  = data_in ^ current_nonce;
    wire [15:0] w3  = data_in + current_nonce;
    wire [15:0] w6  = ~(data_in ^ current_nonce);
    wire [15:0] w7  = data_in - current_nonce;
    wire [15:0] w8  = ((data_in  >> 3)  | (data_in  << 13)) ^ current_nonce;
    wire [15:0] w9  = data_in ^ ((current_nonce >> 5) | (current_nonce << 11));
    wire [15:0] w10 = (data_in << 2) + current_nonce;
    wire [15:0] w11 = data_in + (current_nonce >> 3);
    wire [15:0] w12 = (data_in & current_nonce) ^ 16'h5a5a;
    wire [15:0] w13 = (data_in | current_nonce) ^ 16'ha5a5;
    wire [15:0] w14 = data_in ^ current_nonce ^ 16'hffff;
    wire [15:0] w15 = data_in + current_nonce + 16'h1234;

    // SHA-256 round functions
    wire [15:0] sigma1_e = ((e >> 6)  | (e << 10)) ^ ((e >> 11) | (e << 5))  ^ ((e >> 15) | (e << 1));
    wire [15:0] sigma0_a = ((a >> 2)  | (a << 14)) ^ ((a >> 7)  | (a << 9))  ^ ((a >> 13) | (a << 3));
    wire [15:0] ch_efg   = (e & f) ^ (~e & g);
    wire [15:0] maj_abc  = (a & b) ^ (a & c) ^ (b & c);
    wire [15:0] T1       = h + sigma1_e + ch_efg + K[round] + W[round];
    wire [15:0] T2       = sigma0_a + maj_abc;
    wire [15:0] new_a    = T1 + T2;
    wire [15:0] new_e    = d + T1;
    wire [15:0] hash_final = (H0 + new_a) ^ (H4 + new_e);
    wire [15:0] nonce_inc  = current_nonce + 1'b1;

    // Sequential FSM
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
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
                    if (start)
                        current_nonce <= nonce_in;
                end

                INIT: begin
                    a <= H0; b <= H1; c <= H2; d <= H3;
                    e <= H4; f <= H5; g <= H6; h <= H7;
                    round <= 0;
                    W[0]  <= data_in;
                    W[1]  <= current_nonce;
                    W[2]  <= w2;
                    W[3]  <= w3;
                    W[4]  <= {data_in[7:0], current_nonce[15:8]};
                    W[5]  <= {current_nonce[7:0], data_in[15:8]};
                    W[6]  <= w6;
                    W[7]  <= w7;
                    W[8]  <= w8;
                    W[9]  <= w9;
                    W[10] <= w10;
                    W[11] <= w11;
                    W[12] <= w12;
                    W[13] <= w13;
                    W[14] <= w14;
                    W[15] <= w15;
                end

                COMPUTE: begin
                    a <= new_a; b <= a; c <= b; d <= c;
                    e <= new_e; f <= e; g <= f; h <= g;
                    if (round == 15)
                        hash_out <= hash_final;
                    else
                        round <= round + 1;
                end

                CHECK: begin
                    if (hash_out < target) begin
                        result_nonce <= current_nonce;
                        done <= 1;
                    end else if (current_nonce == 16'hFFFF) begin
                        done <= 1;
                    end else begin
                        current_nonce <= nonce_inc;
                    end
                end

                DONE_STATE: begin
                    done <= 1;
                end
            endcase
        end
    end

    // Next-state logic
    always @(*) begin
        next_state = state;
        case (state)
            IDLE:       if (start)          next_state = INIT;
            INIT:                           next_state = COMPUTE;
            COMPUTE:    if (round == 15)    next_state = CHECK;
            CHECK: begin
                if (hash_out < target)          next_state = DONE_STATE;
                else if (current_nonce == 16'hFFFF) next_state = DONE_STATE;
                else                            next_state = INIT;
            end
            DONE_STATE: if (!start)         next_state = IDLE;
            default:                        next_state = IDLE;
        endcase
    end

endmodule
