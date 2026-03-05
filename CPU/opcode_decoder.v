// Opcode decoder: maps CPU opcodes to ALU operation types
module opcode_decoder (
    input [5:0] opcode,
    output reg [3:0] operation_type,
    output reg is_compare
);

    localparam OP_ADD = 4'd0;
    localparam OP_SUB = 4'd1;
    localparam OP_MUL = 4'd2;
    localparam OP_DIV = 4'd3;
    localparam OP_MOD = 4'd4;
    localparam OP_AND = 4'd5;
    localparam OP_OR  = 4'd6;
    localparam OP_XOR = 4'd7;
    localparam OP_NOT = 4'd8;
    localparam OP_LSL = 4'd9;
    localparam OP_LSR = 4'd10;
    localparam OP_RSR = 4'd11;
    localparam OP_RSL = 4'd12;

    localparam CPU_ADD  = 6'b001010, CPU_ADDI = 6'b101010;
    localparam CPU_SUB  = 6'b001011, CPU_SUBI = 6'b101011;
    localparam CPU_MUL  = 6'b001100, CPU_MULI = 6'b101100;
    localparam CPU_DIV  = 6'b001101, CPU_DIVI = 6'b101101;
    localparam CPU_MOD  = 6'b001110, CPU_MODI = 6'b101110;
    localparam CPU_AND  = 6'b010011, CPU_ANDI = 6'b110011;
    localparam CPU_OR   = 6'b010100, CPU_ORI  = 6'b110100;
    localparam CPU_XOR  = 6'b010101, CPU_XORI = 6'b110101;
    localparam CPU_NOT  = 6'b010110, CPU_NOTI = 6'b110110;
    localparam CPU_LSL  = 6'b001111, CPU_LSLI = 6'b101111;
    localparam CPU_LSR  = 6'b010000, CPU_LSRI = 6'b110000;
    localparam CPU_RSR  = 6'b010001, CPU_RSRI = 6'b110001;
    localparam CPU_RSL  = 6'b010010, CPU_RSLI = 6'b110010;
    localparam CPU_CMP  = 6'b010111, CPU_CMPI = 6'b110111;
    localparam CPU_TST  = 6'b011000, CPU_TSTI = 6'b111000;

    always @(*) begin
        is_compare = 1'b0;
        case (opcode)
            CPU_ADD, CPU_ADDI: operation_type = OP_ADD;
            CPU_SUB, CPU_SUBI: operation_type = OP_SUB;
            CPU_MUL, CPU_MULI: operation_type = OP_MUL;
            CPU_DIV, CPU_DIVI: operation_type = OP_DIV;
            CPU_MOD, CPU_MODI: operation_type = OP_MOD;
            CPU_AND, CPU_ANDI: operation_type = OP_AND;
            CPU_OR,  CPU_ORI:  operation_type = OP_OR;
            CPU_XOR, CPU_XORI: operation_type = OP_XOR;
            CPU_NOT, CPU_NOTI: operation_type = OP_NOT;
            CPU_LSL, CPU_LSLI: operation_type = OP_LSL;
            CPU_LSR, CPU_LSRI: operation_type = OP_LSR;
            CPU_RSR, CPU_RSRI: operation_type = OP_RSR;
            CPU_RSL, CPU_RSLI: operation_type = OP_RSL;
            CPU_CMP, CPU_CMPI: begin
                operation_type = OP_SUB;
                is_compare = 1'b1;
            end
            CPU_TST, CPU_TSTI: begin
                operation_type = OP_AND;
                is_compare = 1'b1;
            end
            default: operation_type = OP_ADD;
        endcase
    end

endmodule
