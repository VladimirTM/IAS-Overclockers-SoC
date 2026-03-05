// Sign Extension Unit: 9-bit to 16-bit sign extension
module seu (
    input [8:0] in_imm,
    output [15:0] out_ext
);

    assign out_ext = { {7{in_imm[8]}}, in_imm };

endmodule