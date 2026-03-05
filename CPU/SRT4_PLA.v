module SRT4_PLA (
    input signed [5:0] P,
    input [3:0] b,
    output reg signed [2:0] q
);

    always @(*) begin
        case (b)
            8:  if      (P >= -12 && P <= -7) q = -2;
                else if (P >= -6  && P <= -3) q = -1;
                else if (P >= -2  && P <=  1) q =  0;
                else if (P >=  2  && P <=  5) q =  1;
                else if (P >=  6  && P <= 11) q =  2;
                else q = 0;

            9:  if      (P >= -14 && P <= -8) q = -2;
                else if (P >= -7  && P <= -3) q = -1;
                else if (P >= -3  && P <=  2) q =  0;
                else if (P >=  2  && P <=  6) q =  1;
                else if (P >=  7  && P <= 13) q =  2;
                else q = 0;

            10: if      (P >= -15 && P <= -9) q = -2;
                else if (P >= -8  && P <= -3) q = -1;
                else if (P >= -3  && P <=  2) q = 0;
                else if (P >=  2  && P <=  7) q = 1;
                else if (P >=  8  && P <= 14) q = 2;
                else q = 0;

            11: if      (P >= -16 && P <= -9) q = -2;
                else if (P >= -9  && P <= -3) q = -1;
                else if (P >= -3  && P <=  2) q =  0;
                else if (P >=  2  && P <=  8) q =  1;
                else if (P >=  8  && P <= 15) q =  2;
                else q = 0;

            12: if      (P >= -18 && P <= -10) q = -2;
                else if (P >= -10 && P <= -4)  q = -1;
                else if (P >= -4  && P <=  3)  q =  0;
                else if (P >=  3  && P <=  9)  q =  1;
                else if (P >=  9  && P <= 17)  q =  2;
                else q = 0;

            13: if      (P >= -19 && P <= -11) q = -2;
                else if (P >= -10 && P <= -4)  q = -1;
                else if (P >= -4  && P <=  3)  q =  0;
                else if (P >=  3  && P <=  9)  q =  1;
                else if (P >= 10  && P <= 18)  q =  2;
                else q = 0;

            14: if      (P >= -20 && P <= -11) q = -2;
                else if (P >= -11 && P <= -4)  q = -1;
                else if (P >= -4  && P <=  3)  q =  0;
                else if (P >=  3  && P <= 10)  q =  1;
                else if (P >= 10  && P <= 19)  q =  2;
                else q = 0;

            15: if      (P >= -22 && P <= -12) q = -2;
                else if (P >= -12 && P <= -4)  q = -1;
                else if (P >= -5  && P <=  4)  q =  0;
                else if (P >=  3  && P <= 11)  q =  1;
                else if (P >= 11  && P <= 21)  q =  2;
                else q = 0;

            default: q = 0;
        endcase
    end
endmodule