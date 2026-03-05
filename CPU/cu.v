// Control Unit: FSM managing instruction execution
module cu (
    input clk,
    input rst_n,
    input [5:0] opcode,
    input regaddr,
    input [15:0] ir_out,
    input Z,
    input N,
    input C,
    input O,
    input alu_end,
    input alu_exc,
    input mining_done,
    output reg ldAR,
    output reg [1:0] condAR,
    output reg ldDR,
    output reg [2:0] condDR,
    output reg ldIR,
    output reg incPC,
    output reg ldPC,
    output reg ldPCfromDR,
    output reg ldX,
    output reg ldY,
    output reg ldA,
    output reg memWR,
    output reg ldFLAG,
    output reg incSP,
    output reg decSP,
    output reg alu_start,
    output reg [1:0] condALU,
    output reg incrX,
    output reg decrX,
    output reg incrY,
    output reg decrY,
    output reg use_direct_flag,
    output reg use_imm_a,
    output reg use_xy_for_flags,
    output reg mining_start,
    output reg use_mining_result,
    output reg use_dr_for_a,
    output reg use_movr_flags,
    output reg finish
);

    localparam OP_HALT  = 6'b000000, OP_LOAD  = 6'b000001, OP_STORE = 6'b000010;
    localparam OP_BRA   = 6'b000011, OP_BRZ   = 6'b000100, OP_BRN   = 6'b000101;
    localparam OP_BRC   = 6'b000110, OP_BRO   = 6'b000111, OP_PUSH  = 6'b001000, OP_RET   = 6'b001001;
    localparam OP_ADD   = 6'b001010, OP_SUB   = 6'b001011, OP_MUL   = 6'b001100, OP_DIV   = 6'b001101;
    localparam OP_MOD   = 6'b001110, OP_LSL   = 6'b001111, OP_LSR   = 6'b010000, OP_RSR   = 6'b010001;
    localparam OP_RSL   = 6'b010010, OP_AND   = 6'b010011, OP_OR    = 6'b010100, OP_XOR   = 6'b010101;
    localparam OP_NOT   = 6'b010110, OP_CMP   = 6'b010111, OP_TST   = 6'b011000, OP_MOV   = 6'b011001;
    localparam OP_INC   = 6'b011010, OP_DEC   = 6'b011011, OP_MINE  = 6'b011100;
    localparam OP_MOVR  = 6'b011101, OP_BGT   = 6'b011110, OP_BLT   = 6'b011111;
    localparam OP_BGE   = 6'b100000, OP_BLE   = 6'b100001, OP_NOP   = 6'b100010;
    localparam OP_ADDI  = 6'b101010, OP_SUBI  = 6'b101011, OP_MULI  = 6'b101100, OP_DIVI  = 6'b101101;
    localparam OP_MODI  = 6'b101110, OP_LSLI  = 6'b101111, OP_LSRI  = 6'b110000, OP_RSRI  = 6'b110001;
    localparam OP_RSLI  = 6'b110010, OP_ANDI  = 6'b110011, OP_ORI   = 6'b110100, OP_XORI  = 6'b110101;
    localparam OP_NOTI  = 6'b110110, OP_CMPI  = 6'b110111, OP_TSTI  = 6'b111000, OP_MOVI  = 6'b111001;
    localparam OP_PUSH_REG = 6'b100011, OP_POP_REG = 6'b100100;
    localparam OP_BNE = 6'b100101;  // 37 decimal - Branch if Not Equal (Z==0)

    localparam LOAD_ADDR = 0, LOAD_INSTR = 1, DECODE = 2, HALT_STATE = 3;
    localparam LOAD_1 = 4, LOAD_2 = 5, LOAD_3 = 6;
    localparam STORE_1 = 7, STORE_2 = 8, STORE_3 = 9;
    localparam BRA_1 = 10;
    localparam BRZ_CHECK = 11, BRZ_TAKE = 12, BRZ_SKIP = 13;
    localparam BRN_CHECK = 14, BRN_TAKE = 15, BRN_SKIP = 16;
    localparam BRC_CHECK = 17, BRC_TAKE = 18, BRC_SKIP = 19;
    localparam BRO_CHECK = 20, BRO_TAKE = 21, BRO_SKIP = 22;
    localparam PUSH_1 = 23, PUSH_2 = 24, PUSH_3 = 25;
    localparam RET_1 = 26, RET_2 = 27, RET_3 = 28, RET_4 = 29, RET_5 = 30;
    localparam ALU_LOAD_OP1 = 31, ALU_LOAD_OP2 = 32, ALU_LOAD_OPC = 33;
    localparam ALU_WAIT = 34, ALU_GET_RESULT = 35, ALU_GET_FLAGS_ONLY = 36;
    localparam MOV_1 = 37, MOV_2 = 38, MOVI_1 = 39;
    localparam INC_1 = 40, INC_2 = 41, DEC_1 = 42, DEC_2 = 43;
    localparam MINE_START = 44, MINE_WAIT = 45, MINE_GET_RESULT = 46;
    localparam MOVR_1 = 47, MOVR_2 = 48, NOP_1 = 49;
    localparam BGT_CHECK = 50, BGT_TAKE = 51, BGT_SKIP = 52;
    localparam BLT_CHECK = 53, BLT_TAKE = 54, BLT_SKIP = 55;
    localparam BGE_CHECK = 56, BGE_TAKE = 57, BGE_SKIP = 58;
    localparam BLE_CHECK = 59, BLE_TAKE = 60, BLE_SKIP = 61;
    localparam PUSH_REG_1 = 62, PUSH_REG_2 = 63, PUSH_REG_3 = 64;
    localparam POP_REG_1 = 65, POP_REG_2 = 66, POP_REG_3 = 67, POP_REG_4 = 68;
    localparam BNE_CHECK = 69, BNE_TAKE = 70, BNE_SKIP = 71;

    reg [6:0] state, next_state;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= LOAD_ADDR;
        else
            state <= next_state;
    end

    always @(*) begin
        next_state = state;

        case (state)
            LOAD_ADDR: begin
                next_state = LOAD_INSTR;
            end

            LOAD_INSTR: begin
                next_state = DECODE;
            end

            DECODE: begin
                case (opcode)
                    OP_HALT:  next_state = HALT_STATE;
                    OP_LOAD:  next_state = LOAD_1;
                    OP_STORE: next_state = STORE_1;
                    OP_BRA:   next_state = BRA_1;
                    OP_BRZ:   next_state = BRZ_CHECK;
                    OP_BRN:   next_state = BRN_CHECK;
                    OP_BRC:   next_state = BRC_CHECK;
                    OP_BRO:   next_state = BRO_CHECK;
                    OP_PUSH:  next_state = PUSH_1;
                    OP_RET:   next_state = RET_1;

                    OP_ADD, OP_SUB, OP_MUL, OP_DIV, OP_MOD,
                    OP_LSL, OP_LSR, OP_RSR, OP_RSL,
                    OP_AND, OP_OR, OP_XOR, OP_NOT,
                    OP_CMP, OP_TST:
                        next_state = ALU_LOAD_OPC;

                    OP_ADDI, OP_SUBI, OP_MULI, OP_DIVI, OP_MODI,
                    OP_LSLI, OP_LSRI, OP_RSRI, OP_RSLI,
                    OP_ANDI, OP_ORI, OP_XORI, OP_NOTI,
                    OP_CMPI, OP_TSTI:
                        next_state = ALU_LOAD_OPC;

                    OP_MOV:   next_state = MOV_1;
                    OP_MOVI:  next_state = MOVI_1;
                    OP_INC:   next_state = INC_1;
                    OP_DEC:   next_state = DEC_1;
                    OP_MINE:  next_state = MINE_START;
                    OP_MOVR:  next_state = MOVR_1;
                    OP_BGT:   next_state = BGT_CHECK;
                    OP_BLT:   next_state = BLT_CHECK;
                    OP_BGE:   next_state = BGE_CHECK;
                    OP_BLE:   next_state = BLE_CHECK;
                    OP_NOP:   next_state = NOP_1;
                    OP_PUSH_REG: next_state = PUSH_REG_1;
                    OP_POP_REG:  next_state = POP_REG_1;
                    OP_BNE:   next_state = BNE_CHECK;

                    default:  next_state = LOAD_ADDR;
                endcase
            end

            HALT_STATE: begin
                next_state = HALT_STATE;
            end

            LOAD_1: next_state = LOAD_2;
            LOAD_2: next_state = LOAD_3;
            LOAD_3: next_state = LOAD_ADDR;

            STORE_1: next_state = STORE_2;
            STORE_2: next_state = STORE_3;
            STORE_3: next_state = LOAD_ADDR;

            BRA_1: next_state = LOAD_ADDR;

            BRZ_CHECK: begin
                if (Z == 1'b1)
                    next_state = BRZ_TAKE;
                else
                    next_state = BRZ_SKIP;
            end
            BRZ_TAKE: next_state = LOAD_ADDR;
            BRZ_SKIP: next_state = LOAD_ADDR;

            BRN_CHECK: begin
                if (N == 1'b1)
                    next_state = BRN_TAKE;
                else
                    next_state = BRN_SKIP;
            end
            BRN_TAKE: next_state = LOAD_ADDR;
            BRN_SKIP: next_state = LOAD_ADDR;

            BRC_CHECK: begin
                if (C == 1'b1)
                    next_state = BRC_TAKE;
                else
                    next_state = BRC_SKIP;
            end
            BRC_TAKE: next_state = LOAD_ADDR;
            BRC_SKIP: next_state = LOAD_ADDR;

            BRO_CHECK: begin
                if (O == 1'b1)
                    next_state = BRO_TAKE;
                else
                    next_state = BRO_SKIP;
            end
            BRO_TAKE: next_state = LOAD_ADDR;
            BRO_SKIP: next_state = LOAD_ADDR;

            PUSH_1: next_state = PUSH_2;
            PUSH_2: next_state = PUSH_3;
            PUSH_3: next_state = LOAD_ADDR;

            RET_1: next_state = RET_2;
            RET_2: next_state = RET_3;
            RET_3: next_state = RET_4;
            RET_4: next_state = RET_5;
            RET_5: next_state = LOAD_ADDR;

            ALU_LOAD_OPC: next_state = ALU_LOAD_OP1;
            ALU_LOAD_OP1: next_state = ALU_LOAD_OP2;
            ALU_LOAD_OP2: next_state = ALU_WAIT;

            ALU_WAIT: begin
                if (alu_end) begin
                    if (opcode == OP_CMP || opcode == OP_TST ||
                        opcode == OP_CMPI || opcode == OP_TSTI)
                        next_state = ALU_GET_FLAGS_ONLY;
                    else
                        next_state = ALU_GET_RESULT;
                end else
                    next_state = ALU_WAIT;
            end

            ALU_GET_RESULT: next_state = LOAD_ADDR;
            ALU_GET_FLAGS_ONLY: next_state = LOAD_ADDR;

            MOV_1:  next_state = MOV_2;
            MOV_2:  next_state = LOAD_ADDR;
            MOVI_1: next_state = LOAD_ADDR;
            INC_1:  next_state = INC_2;
            INC_2:  next_state = LOAD_ADDR;
            DEC_1:  next_state = DEC_2;
            DEC_2:  next_state = LOAD_ADDR;

            MINE_START:       next_state = MINE_WAIT;
            MINE_WAIT: begin
                if (mining_done)
                    next_state = MINE_GET_RESULT;
                else
                    next_state = MINE_WAIT;
            end
            MINE_GET_RESULT:  next_state = LOAD_ADDR;

            MOVR_1:   next_state = MOVR_2;
            MOVR_2:   next_state = LOAD_ADDR;
            NOP_1:    next_state = LOAD_ADDR;

            BGT_CHECK: begin
                if (~Z & (N == O))
                    next_state = BGT_TAKE;
                else
                    next_state = BGT_SKIP;
            end
            BGT_TAKE: next_state = LOAD_ADDR;
            BGT_SKIP: next_state = LOAD_ADDR;

            BLT_CHECK: begin
                if (N != O)
                    next_state = BLT_TAKE;
                else
                    next_state = BLT_SKIP;
            end
            BLT_TAKE: next_state = LOAD_ADDR;
            BLT_SKIP: next_state = LOAD_ADDR;

            BGE_CHECK: begin
                if (N == O)
                    next_state = BGE_TAKE;
                else
                    next_state = BGE_SKIP;
            end
            BGE_TAKE: next_state = LOAD_ADDR;
            BGE_SKIP: next_state = LOAD_ADDR;

            BLE_CHECK: begin
                if (Z | (N != O))
                    next_state = BLE_TAKE;
                else
                    next_state = BLE_SKIP;
            end
            BLE_TAKE: next_state = LOAD_ADDR;
            BLE_SKIP: next_state = LOAD_ADDR;

            PUSH_REG_1: next_state = PUSH_REG_2;
            PUSH_REG_2: next_state = PUSH_REG_3;
            PUSH_REG_3: next_state = LOAD_ADDR;

            POP_REG_1: next_state = POP_REG_2;
            POP_REG_2: next_state = POP_REG_3;
            POP_REG_3: next_state = POP_REG_4;
            POP_REG_4: next_state = LOAD_ADDR;

            BNE_CHECK: begin
                if (Z == 1'b0)
                    next_state = BNE_TAKE;
                else
                    next_state = BNE_SKIP;
            end
            BNE_TAKE: next_state = LOAD_ADDR;
            BNE_SKIP: next_state = LOAD_ADDR;

            default: next_state = LOAD_ADDR;
        endcase
    end

    always @(*) begin
        ldAR = 0;
        condAR = 2'b00;
        ldDR = 0;
        condDR = 3'b000;
        ldIR = 0;
        incPC = 0;
        ldPC = 0;
        ldPCfromDR = 0;
        ldX = 0;
        ldY = 0;
        ldA = 0;
        memWR = 0;
        ldFLAG = 0;
        incSP = 0;
        decSP = 0;
        alu_start = 0;
        condALU = 2'b00;
        incrX = 0;
        decrX = 0;
        incrY = 0;
        decrY = 0;
        use_direct_flag = 0;
        use_imm_a = 0;
        use_xy_for_flags = 0;
        mining_start = 0;
        use_mining_result = 0;
        use_dr_for_a = 0;
        use_movr_flags = 0;
        finish = 0;

        case (state)
            LOAD_ADDR: begin
                ldAR = 1;
                condAR = 2'b00;
            end

            LOAD_INSTR: begin
                ldDR = 1;
                condDR = 3'b000;
                ldIR = 1;
                incPC = 1;
            end

            DECODE: begin
            end

            HALT_STATE: begin
                finish = 1;
            end

            LOAD_1: begin
                ldAR = 1;
                condAR = 2'b10;
            end

            LOAD_2: begin
                ldDR = 1;
                condDR = 3'b000;
            end

            LOAD_3: begin
                if (regaddr == 1'b0) begin
                    ldX = 1;
                end else begin
                    ldY = 1;
                end
            end

            STORE_1: begin
                ldAR = 1;
                condAR = 2'b10;
            end

            STORE_2: begin
                ldDR = 1;
                if (regaddr == 1'b0)
                    condDR = 3'b001;
                else
                    condDR = 3'b010;
            end

            STORE_3: begin
                memWR = 1;
            end

            BRA_1: begin
                ldPC = 1;
                ldPCfromDR = 0;
            end

            BRZ_TAKE, BRN_TAKE, BRC_TAKE, BRO_TAKE,
            BGT_TAKE, BLT_TAKE, BGE_TAKE, BLE_TAKE, BNE_TAKE: begin
                ldPC = 1;
                ldPCfromDR = 0;
            end

            BRZ_SKIP, BRN_SKIP, BRC_SKIP, BRO_SKIP,
            BGT_SKIP, BLT_SKIP, BGE_SKIP, BLE_SKIP, BNE_SKIP: begin
            end

            PUSH_1: begin
                ldAR = 1;
                condAR = 2'b01;
            end

            PUSH_2: begin
                ldDR = 1;
                condDR = 3'b011;
            end

            PUSH_3: begin
                memWR = 1;
                decSP = 1;
                ldPC = 1;
                ldPCfromDR = 0;
            end

            RET_1: begin
                incSP = 1;
            end

            RET_2: begin
                ldAR = 1;
                condAR = 2'b01;
            end

            RET_3: begin
                ldDR = 1;
                condDR = 3'b000;
            end

            RET_4: begin
            end

            RET_5: begin
                ldPC = 1;
                ldPCfromDR = 1;
            end

            ALU_LOAD_OPC: begin
                condALU = 2'b00;
                alu_start = 1;
            end

            ALU_LOAD_OP1: begin
                condALU = 2'b01;
                alu_start = 1;
            end

            ALU_LOAD_OP2: begin
                if (opcode[5] == 1'b0)
                    condALU = 2'b10;
                else
                    condALU = 2'b11;
                alu_start = 1;
            end

            ALU_WAIT: begin
                alu_start = 1;
            end

            ALU_GET_RESULT: begin
                if (!alu_exc) begin
                    ldA = 1;
                    ldFLAG = 1;
                end
            end

            ALU_GET_FLAGS_ONLY: begin
                if (!alu_exc) begin
                    ldA = 0;
                    ldFLAG = 1;
                end
            end

            MOV_1: begin
                ldDR = 1;
                condDR = 3'b100;
            end

            MOV_2: begin
                if (regaddr == 1'b0) begin
                    ldX = 1;
                end else begin
                    ldY = 1;
                end
                ldFLAG = 1;
                use_direct_flag = 1;
            end

            MOVI_1: begin
                ldA = 1;
                use_imm_a = 1;
            end

            INC_1: begin
                if (regaddr == 1'b0) begin
                    incrX = 1;
                end else begin
                    incrY = 1;
                end
            end

            INC_2: begin
                ldFLAG = 1;
                use_direct_flag = 1;
                use_xy_for_flags = 1;
            end

            DEC_1: begin
                if (regaddr == 1'b0) begin
                    decrX = 1;
                end else begin
                    decrY = 1;
                end
            end

            DEC_2: begin
                ldFLAG = 1;
                use_direct_flag = 1;
                use_xy_for_flags = 1;
            end

            MINE_START: begin
                mining_start = 1;
            end

            MINE_WAIT: begin
            end

            MINE_GET_RESULT: begin
                ldX = 1;
                ldA = 1;
                use_mining_result = 1;
            end

            MOVR_1: begin
                ldDR = 1;
                case (ir_out[9:8])
                    2'b00: condDR = 3'b101;
                    2'b01: condDR = 3'b001;
                    2'b10: condDR = 3'b010;
                    default: condDR = 3'b000;
                endcase
            end

            MOVR_2: begin
                case (ir_out[7:6])
                    2'b00: begin
                        ldA = 1;
                        use_dr_for_a = 1;
                    end
                    2'b01: ldX = 1;
                    2'b10: ldY = 1;
                    default: begin end
                endcase
                ldFLAG = 1;
                use_direct_flag = 1;
                use_movr_flags = 1;
            end

            NOP_1: begin
            end

            PUSH_REG_1: begin
                ldAR = 1;
                condAR = 2'b01;
            end

            PUSH_REG_2: begin
                ldDR = 1;
                if (regaddr == 1'b0)
                    condDR = 3'b001;
                else
                    condDR = 3'b010;
            end

            PUSH_REG_3: begin
                memWR = 1;
                decSP = 1;
            end

            POP_REG_1: begin
                incSP = 1;
            end

            POP_REG_2: begin
                ldAR = 1;
                condAR = 2'b01;
            end

            POP_REG_3: begin
                ldDR = 1;
                condDR = 3'b000;
            end

            POP_REG_4: begin
                if (regaddr == 1'b0) begin
                    ldX = 1;
                end else begin
                    ldY = 1;
                end
            end
        endcase
    end

endmodule
