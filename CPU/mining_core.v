// Mining Core: simplified SHA-256 hash miner
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
    reg [15:0] a_next, b_next, c_next, d_next;
    reg [15:0] e_next, f_next, g_next, h_next;
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

    function [15:0] rotr;
        input [15:0] x;
        input [3:0] n;
        begin
            rotr = (x >> n) | (x << (16 - n));
        end
    endfunction

    function [15:0] shr;
        input [15:0] x;
        input [3:0] n;
        begin
            shr = x >> n;
        end
    endfunction

    function [15:0] ch;
        input [15:0] x, y, z;
        begin
            ch = (x & y) ^ (~x & z);
        end
    endfunction

    function [15:0] maj;
        input [15:0] x, y, z;
        begin
            maj = (x & y) ^ (x & z) ^ (y & z);
        end
    endfunction

    function [15:0] sigma0;
        input [15:0] x;
        begin
            sigma0 = rotr(x, 2) ^ rotr(x, 7) ^ rotr(x, 13);
        end
    endfunction

    function [15:0] sigma1;
        input [15:0] x;
        begin
            sigma1 = rotr(x, 6) ^ rotr(x, 11) ^ rotr(x, 15);
        end
    endfunction

    function [15:0] ssig0;
        input [15:0] x;
        begin
            ssig0 = rotr(x, 7) ^ rotr(x, 14) ^ shr(x, 3);
        end
    endfunction

    function [15:0] ssig1;
        input [15:0] x;
        begin
            ssig1 = rotr(x, 10) ^ rotr(x, 13) ^ shr(x, 2);
        end
    endfunction

    wire [15:0] T1, T2;
    assign T1 = h + sigma1(e) + ch(e, f, g) + K[round] + W[round];
    assign T2 = sigma0(a) + maj(a, b, c);

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

                    W[0] <= data_in;
                    W[1] <= current_nonce;
                    W[2] <= data_in ^ current_nonce;
                    W[3] <= data_in + current_nonce;
                    W[4] <= {data_in[7:0], current_nonce[15:8]};
                    W[5] <= {current_nonce[7:0], data_in[15:8]};
                    W[6] <= ~(data_in ^ current_nonce);
                    W[7] <= data_in - current_nonce;
                    W[8] <= rotr(data_in, 3) ^ current_nonce;
                    W[9] <= data_in ^ rotr(current_nonce, 5);
                    W[10] <= (data_in << 2) + current_nonce;
                    W[11] <= data_in + (current_nonce >> 3);
                    W[12] <= (data_in & current_nonce) ^ 16'h5a5a;
                    W[13] <= (data_in | current_nonce) ^ 16'ha5a5;
                    W[14] <= data_in ^ current_nonce ^ 16'hffff;
                    W[15] <= data_in + current_nonce + 16'h1234;
                end

                COMPUTE: begin
                    a <= T1 + T2;
                    b <= a;
                    c <= b;
                    d <= c;
                    e <= d + T1;
                    f <= e;
                    g <= f;
                    h <= g;

                    if (round == 15) begin
                        hash_out <= (H0 + a) ^ (H4 + e);
                    end else begin
                        round <= round + 1;
                    end
                end

                CHECK: begin
                    if (hash_out < target) begin
                        result_nonce <= current_nonce;
                        done <= 1;
                    end else begin
                        current_nonce <= current_nonce + 1;
                    end
                end

                DONE_STATE: begin
                    done <= 1;
                end
            endcase
        end
    end

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
