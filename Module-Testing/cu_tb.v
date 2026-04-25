`timescale 1ns / 1ns

module cu_tb;

    reg clk;
    reg rst_n;
    reg [5:0] opcode;
    reg regaddr;
    reg [15:0] ir_out;
    reg Z, N, C, O;
    reg alu_end;
    reg alu_exc;
    reg mining_done;

    wire ldAR;
    wire [1:0] condAR;
    wire ldDR;
    wire [2:0] condDR;
    wire ldIR;
    wire incPC;
    wire ldPC;
    wire ldPCfromDR;
    wire ldX;
    wire ldY;
    wire ldA;
    wire memWR;
    wire ldFLAG;
    wire incSP;
    wire decSP;
    wire alu_start;
    wire [1:0] condALU;
    wire incrX;
    wire decrX;
    wire incrY;
    wire decrY;
    wire use_direct_flag;
    wire use_imm_a;
    wire use_xy_for_flags;
    wire mining_start;
    wire use_mining_result;
    wire use_dr_for_a;
    wire use_movr_flags;
    wire finish;
    wire io_we, io_re, ivt_mode;

    cu uut_cu (
        .clk(clk),
        .rst_n(rst_n),
        .opcode(opcode),
        .regaddr(regaddr),
        .ir_out(ir_out),
        .Z(Z), .N(N), .C(C), .O(O),
        .alu_end(alu_end),
        .alu_exc(alu_exc),
        .mining_done(mining_done),
        .ldAR(ldAR),
        .condAR(condAR),
        .ldDR(ldDR),
        .condDR(condDR),
        .ldIR(ldIR),
        .incPC(incPC),
        .ldPC(ldPC),
        .ldPCfromDR(ldPCfromDR),
        .ldX(ldX),
        .ldY(ldY),
        .ldA(ldA),
        .memWR(memWR),
        .ldFLAG(ldFLAG),
        .incSP(incSP),
        .decSP(decSP),
        .alu_start(alu_start),
        .condALU(condALU),
        .incrX(incrX),
        .decrX(decrX),
        .incrY(incrY),
        .decrY(decrY),
        .use_direct_flag(use_direct_flag),
        .use_imm_a(use_imm_a),
        .use_xy_for_flags(use_xy_for_flags),
        .mining_start(mining_start),
        .use_mining_result(use_mining_result),
        .use_dr_for_a(use_dr_for_a),
        .use_movr_flags(use_movr_flags),
        .finish(finish),
        // I/O control ports
        .io_we(io_we),
        .io_re(io_re),
        .ivt_mode(ivt_mode),
        // Interrupt system ports (inactive for this testbench)
        .intr_pending(1'b0),
        .irq_id(2'b00),
        .intr_ack(),
        .set_I(),
        .clr_I(),
        .use_packed_flags(),
        .saved_irq_id()
    );

    wire [32:0] ctrl_bus;
    assign ctrl_bus = {
        ldAR, condAR, ldDR, condDR, ldIR, incPC, ldPC, ldPCfromDR,
        ldX, ldY, ldA, memWR, ldFLAG, incSP, decSP, alu_start, condALU,
        incrX, decrX, incrY, decrY, use_direct_flag, use_imm_a, use_xy_for_flags,
        mining_start, use_mining_result, use_dr_for_a, use_movr_flags, finish
    };

    // opCode values copied from original module
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
    localparam OP_PUSH_REG = 6'b100011, OP_POP_REG = 6'b100100;
    localparam OP_BNE = 6'b100101;
    localparam OP_ADDI  = 6'b101010, OP_SUBI  = 6'b101011, OP_MULI  = 6'b101100, OP_DIVI  = 6'b101101;
    localparam OP_MODI  = 6'b101110, OP_LSLI  = 6'b101111, OP_LSRI  = 6'b110000, OP_RSRI  = 6'b110001;
    localparam OP_RSLI  = 6'b110010, OP_ANDI  = 6'b110011, OP_ORI   = 6'b110100, OP_XORI  = 6'b110101;
    localparam OP_NOTI  = 6'b110110, OP_CMPI  = 6'b110111, OP_TSTI  = 6'b111000, OP_MOVI  = 6'b111001;

    integer test_count = 0;
    integer pass_count = 0;
    integer fail_count = 0;

    task check_test;
        input [511:0] test_name;
        input [32:0] exp_ctrl_bus;
        reg res_ok;
        begin
            test_count = test_count + 1;
            res_ok = (ctrl_bus == exp_ctrl_bus);

            if (res_ok) begin
                $display("Test %2d PASS: %s", test_count, test_name);
                pass_count = pass_count + 1;
            end else begin
                $display("Test %2d FAIL: %s", test_count, test_name);
                $display("  -> FAIL: got %h, expected %h", ctrl_bus, exp_ctrl_bus);
                fail_count = fail_count + 1;
            end
        end
    endtask
    
    // Drive FSM to DECODE state
    task reset_to_decode;
        begin
            rst_n = 0;
            #1;
            rst_n = 1;
            @(negedge clk); // LOAD_ADDR
            @(negedge clk); // LOAD_INSTR
            // INTR_CHECK (v3.1: between LOAD_INSTR and DECODE)
            @(negedge clk); // DECODE
        end
    endtask

    parameter halfT = 5; 
    initial begin
        clk = 0;
        forever #(halfT) clk = ~clk; 
    end

    initial begin
        
        rst_n = 1;
        opcode = 0;
        regaddr = 0;
        Z = 0; N = 0; C = 0; O = 0;
        alu_end = 0;
        alu_exc = 0;
        mining_done = 0;

        /*
        ========================================
             Reset Sequence Test
        ========================================
        */
        
        @(negedge clk);
        rst_n = 0;
        @(posedge clk);
        @(negedge clk); // done like this for iverilog testing script
        rst_n = 1;
        
        check_test("State LOAD_ADDR: ldAR=1", 33'h100000000);

        /*
        ========================================
             Fetch Cycle Test
        ========================================
        */
        @(negedge clk);
        check_test("State LOAD_INSTR: ldDR=ldIR=incPC=1", 33'h023000000);

        @(negedge clk);
        check_test("State INTR_CHECK: No signals", 33'h000000000);

        /*
        ========================================
             Instruction Test: LOAD (Reg X)
        ========================================
        */
        
        opcode = OP_LOAD;
        regaddr = 0; // X
        @(negedge clk); // v3.1: advance INTR_CHECK → DECODE (intr_pending=0)
        @(negedge clk);
        check_test("Inst LOAD (Step 1): ldAR, condAR=10", 33'h180000000);

        @(negedge clk);
        check_test("Inst LOAD (Step 2): ldDR", 33'h020000000);

        @(negedge clk);
        check_test("Inst LOAD (Step 3): ldX=1", 33'h000200000);

        @(negedge clk);
        check_test("Return to LOAD_ADDR", 33'h100000000);

        /*
        ========================================
             Instruction Test: ALU ADD
        ========================================
        */
        @(negedge clk); // LOAD_INSTR
        check_test("State LOAD_INSTR: ldDR=ldIR=incPC=1", 33'h023000000);
        @(negedge clk); // INTR_CHECK (no signals when intr_pending=0)
        check_test("State INTR_CHECK: No signals", 33'h000000000);

        opcode = OP_ADD;
        regaddr = 0;
        @(negedge clk); // v3.1: advance INTR_CHECK → DECODE

        // DECODE -> ALU_LOAD_OPC
        // alu_start=1 (bit 11), condALU=00 (bits 10-9) -> 0x00000800
        @(negedge clk);
        check_test("ALU Step 1 (OPC): alu_start", 33'h000004000);

        // ALU_LOAD_OPC -> ALU_LOAD_OP1
        // alu_start=1, condALU=01 -> 0x00000A00
        @(negedge clk);
        check_test("ALU Step 2 (OP1): alu_start, condALU=01", 33'h000005000);

        @(negedge clk);
        check_test("ALU Step 3 (OP2): alu_start, condALU=10", 33'h000006000);

        alu_end = 0; // wait for alu_end
        @(negedge clk);
        check_test("ALU Wait: alu_start active", 33'h000004000);

        alu_end = 1; // signal ALU done
        @(negedge clk);
        check_test("ALU Get Result: ldA, ldFLAG", 33'h0000A0000);

        alu_end = 0; // deassert alu_end

        /*
        ========================================
             Instruction Test: BRZ (Branch if Zero)
        ========================================
        */
        @(negedge clk); // LOAD_ADDR
        check_test("Return to LOAD_ADDR", 33'h100000000);
        @(negedge clk); // LOAD_INSTR
        check_test("State LOAD_INSTR: ldDR=ldIR=incPC=1", 33'h023000000);
        @(negedge clk); // INTR_CHECK (no signals when intr_pending=0)
        check_test("State INTR_CHECK: No signals", 33'h000000000);

        opcode = OP_BRZ;
        Z = 1; // Z=1: branch taken
        @(negedge clk); // v3.1: advance INTR_CHECK → DECODE
        @(negedge clk);
        check_test("State BRZ_CHECK: No signals", 33'h000000000);

        @(negedge clk);
        check_test("State BRZ_TAKE: ldPC=1", 33'h000800000);

        @(negedge clk); // LOAD_ADDR
        check_test("Return to LOAD_ADDR", 33'h100000000);
        @(negedge clk); // LOAD_INSTR
        check_test("State LOAD_INSTR: ldDR=ldIR=incPC=1", 33'h023000000);
        @(negedge clk); // INTR_CHECK (no signals when intr_pending=0)
        check_test("State INTR_CHECK: No signals", 33'h000000000);

        opcode = OP_BRZ;
        Z = 0; // Z=0: branch skipped
        @(negedge clk); // v3.1: advance INTR_CHECK → DECODE
        @(negedge clk);
        check_test("State BRZ_CHECK: No signals", 33'h000000000);

        @(negedge clk);
        check_test("State BRZ_SKIP: No signals", 33'h000000000);
        
        
        // Conditional branch tests
        
        
        // --- Test BRZ/BEQ (Zero Flag) ---
        // Note: BEQ is an alias for BRZ (same opcode 000100)
        reset_to_decode(); opcode = OP_BRZ; Z = 1; // TAKEN
        @(negedge clk); check_test("BRZ/BEQ_CHECK (Z=1)", 33'h000000000);
        @(negedge clk); check_test("BRZ/BEQ_TAKE (ldPC=1)", 33'h000800000);

        reset_to_decode(); opcode = OP_BRZ; Z = 0; // SKIPPED
        @(negedge clk); check_test("BRZ/BEQ_CHECK (Z=0)", 33'h000000000);
        @(negedge clk); check_test("BRZ/BEQ_SKIP (No Op)", 33'h000000000);

        // --- Test BRN (Negative Flag) ---
        reset_to_decode(); opcode = OP_BRN; N = 1; // TAKEN
        @(negedge clk); check_test("BRN_CHECK (N=1)", 33'h000000000);
        @(negedge clk); check_test("BRN_TAKE (ldPC=1)", 33'h000800000);

        reset_to_decode(); opcode = OP_BRN; N = 0; // SKIPPED
        @(negedge clk); check_test("BRN_CHECK (N=0)", 33'h000000000);
        @(negedge clk); check_test("BRN_SKIP (No Op)", 33'h000000000);

        // --- Test BRC (Carry Flag) ---
        reset_to_decode(); opcode = OP_BRC; C = 1; // TAKEN
        @(negedge clk); check_test("BRC_CHECK (C=1)", 33'h000000000);
        @(negedge clk); check_test("BRC_TAKE (ldPC=1)", 33'h000800000);

        reset_to_decode(); opcode = OP_BRC; C = 0; // SKIPPED
        @(negedge clk); check_test("BRC_CHECK (C=0)", 33'h000000000);
        @(negedge clk); check_test("BRC_SKIP (No Op)", 33'h000000000);

        // --- Test BRO (Overflow Flag) ---
        reset_to_decode(); opcode = OP_BRO; O = 1; // TAKEN
        @(negedge clk); check_test("BRO_CHECK (O=1)", 33'h000000000);
        @(negedge clk); check_test("BRO_TAKE (ldPC=1)", 33'h000800000);

        reset_to_decode(); opcode = OP_BRO; O = 0; // SKIPPED
        @(negedge clk); check_test("BRO_CHECK (O=0)", 33'h000000000);
        @(negedge clk); check_test("BRO_SKIP (No Op)", 33'h000000000);

        
        // BRA (branch always)
        
        reset_to_decode(); opcode = OP_BRA;
        @(negedge clk);
        // BRA_1: ldPC=1 (bit 21) -> 0x00200000
        check_test("State BRA_1: ldPC=1", 33'h000800000);

        
        // ALU operations
        
        
        /* === ALU: bit5=0 (register ops) — result+flags === */

        // --- OP_ADD ---
        reset_to_decode(); opcode = OP_ADD; regaddr = 0; alu_end = 0;
        @(negedge clk); check_test("ADD: ALU_LOAD_OPC", 33'h000004000);
        @(negedge clk); check_test("ADD: ALU_LOAD_OP1", 33'h000005000);
        @(negedge clk); check_test("ADD: ALU_LOAD_OP2 (Low)", 33'h000006000);
        @(negedge clk); check_test("ADD: ALU_WAIT", 33'h000004000);
        alu_end = 1;
        @(negedge clk); check_test("ADD: GET_RESULT", 33'h0000A0000);

        // --- OP_SUB ---
        reset_to_decode(); opcode = OP_SUB; regaddr = 0; alu_end = 0;
        @(negedge clk); check_test("SUB: ALU_LOAD_OPC", 33'h000004000);
        @(negedge clk); check_test("SUB: ALU_LOAD_OP1", 33'h000005000);
        @(negedge clk); check_test("SUB: ALU_LOAD_OP2 (Low)", 33'h000006000);
        @(negedge clk); check_test("SUB: ALU_WAIT", 33'h000004000);
        alu_end = 1;
        @(negedge clk); check_test("SUB: GET_RESULT", 33'h0000A0000);

        // --- OP_MUL ---
        reset_to_decode(); opcode = OP_MUL; regaddr = 0; alu_end = 0;
        @(negedge clk); check_test("MUL: ALU_LOAD_OPC", 33'h000004000);
        @(negedge clk); check_test("MUL: ALU_LOAD_OP1", 33'h000005000);
        @(negedge clk); check_test("MUL: ALU_LOAD_OP2 (Low)", 33'h000006000);
        @(negedge clk); check_test("MUL: ALU_WAIT", 33'h000004000);
        alu_end = 1;
        @(negedge clk); check_test("MUL: GET_RESULT", 33'h0000A0000);

        // --- OP_DIV ---
        reset_to_decode(); opcode = OP_DIV; regaddr = 0; alu_end = 0;
        @(negedge clk); check_test("DIV: ALU_LOAD_OPC", 33'h000004000);
        @(negedge clk); check_test("DIV: ALU_LOAD_OP1", 33'h000005000);
        @(negedge clk); check_test("DIV: ALU_LOAD_OP2 (Low)", 33'h000006000);
        @(negedge clk); check_test("DIV: ALU_WAIT", 33'h000004000);
        alu_end = 1;
        @(negedge clk); check_test("DIV: GET_RESULT", 33'h0000A0000);

        // --- OP_MOD ---
        reset_to_decode(); opcode = OP_MOD; regaddr = 0; alu_end = 0;
        @(negedge clk); check_test("MOD: ALU_LOAD_OPC", 33'h000004000);
        @(negedge clk); check_test("MOD: ALU_LOAD_OP1", 33'h000005000);
        @(negedge clk); check_test("MOD: ALU_LOAD_OP2 (Low)", 33'h000006000);
        @(negedge clk); check_test("MOD: ALU_WAIT", 33'h000004000);
        alu_end = 1;
        @(negedge clk); check_test("MOD: GET_RESULT", 33'h0000A0000);

        // --- OP_LSL ---
        reset_to_decode(); opcode = OP_LSL; regaddr = 0; alu_end = 0;
        @(negedge clk); check_test("LSL: ALU_LOAD_OPC", 33'h000004000);
        @(negedge clk); check_test("LSL: ALU_LOAD_OP1", 33'h000005000);
        @(negedge clk); check_test("LSL: ALU_LOAD_OP2 (Low)", 33'h000006000);
        @(negedge clk); check_test("LSL: ALU_WAIT", 33'h000004000);
        alu_end = 1;
        @(negedge clk); check_test("LSL: GET_RESULT", 33'h0000A0000);

        // --- OP_LSR ---
        reset_to_decode(); opcode = OP_LSR; regaddr = 0; alu_end = 0;
        @(negedge clk); check_test("LSR: ALU_LOAD_OPC", 33'h000004000);
        @(negedge clk); check_test("LSR: ALU_LOAD_OP1", 33'h000005000);
        @(negedge clk); check_test("LSR: ALU_LOAD_OP2 (High)", 33'h000006000);
        @(negedge clk); check_test("LSR: ALU_WAIT", 33'h000004000);
        alu_end = 1;
        @(negedge clk); check_test("LSR: GET_RESULT", 33'h0000A0000);

        // --- OP_RSR ---
        reset_to_decode(); opcode = OP_RSR; regaddr = 0; alu_end = 0;
        @(negedge clk); check_test("RSR: ALU_LOAD_OPC", 33'h000004000);
        @(negedge clk); check_test("RSR: ALU_LOAD_OP1", 33'h000005000);
        @(negedge clk); check_test("RSR: ALU_LOAD_OP2 (High)", 33'h000006000);
        @(negedge clk); check_test("RSR: ALU_WAIT", 33'h000004000);
        alu_end = 1;
        @(negedge clk); check_test("RSR: GET_RESULT", 33'h0000A0000);

        // --- OP_RSL ---
        reset_to_decode(); opcode = OP_RSL; regaddr = 0; alu_end = 0;
        @(negedge clk); check_test("RSL: ALU_LOAD_OPC", 33'h000004000);
        @(negedge clk); check_test("RSL: ALU_LOAD_OP1", 33'h000005000);
        @(negedge clk); check_test("RSL: ALU_LOAD_OP2 (High)", 33'h000006000);
        @(negedge clk); check_test("RSL: ALU_WAIT", 33'h000004000);
        alu_end = 1;
        @(negedge clk); check_test("RSL: GET_RESULT", 33'h0000A0000);

        // --- OP_AND ---
        reset_to_decode(); opcode = OP_AND; regaddr = 0; alu_end = 0;
        @(negedge clk); check_test("AND: ALU_LOAD_OPC", 33'h000004000);
        @(negedge clk); check_test("AND: ALU_LOAD_OP1", 33'h000005000);
        @(negedge clk); check_test("AND: ALU_LOAD_OP2 (High)", 33'h000006000);
        @(negedge clk); check_test("AND: ALU_WAIT", 33'h000004000);
        alu_end = 1;
        @(negedge clk); check_test("AND: GET_RESULT", 33'h0000A0000);

        // --- OP_OR ---
        reset_to_decode(); opcode = OP_OR; regaddr = 0; alu_end = 0;
        @(negedge clk); check_test("OR: ALU_LOAD_OPC", 33'h000004000);
        @(negedge clk); check_test("OR: ALU_LOAD_OP1", 33'h000005000);
        @(negedge clk); check_test("OR: ALU_LOAD_OP2 (High)", 33'h000006000);
        @(negedge clk); check_test("OR: ALU_WAIT", 33'h000004000);
        alu_end = 1;
        @(negedge clk); check_test("OR: GET_RESULT", 33'h0000A0000);

        // --- OP_XOR ---
        reset_to_decode(); opcode = OP_XOR; regaddr = 0; alu_end = 0;
        @(negedge clk); check_test("XOR: ALU_LOAD_OPC", 33'h000004000);
        @(negedge clk); check_test("XOR: ALU_LOAD_OP1", 33'h000005000);
        @(negedge clk); check_test("XOR: ALU_LOAD_OP2 (High)", 33'h000006000);
        @(negedge clk); check_test("XOR: ALU_WAIT", 33'h000004000);
        alu_end = 1;
        @(negedge clk); check_test("XOR: GET_RESULT", 33'h0000A0000);

        // --- OP_NOT ---
        reset_to_decode(); opcode = OP_NOT; regaddr = 0; alu_end = 0;
        @(negedge clk); check_test("NOT: ALU_LOAD_OPC", 33'h000004000);
        @(negedge clk); check_test("NOT: ALU_LOAD_OP1", 33'h000005000);
        @(negedge clk); check_test("NOT: ALU_LOAD_OP2 (High)", 33'h000006000);
        @(negedge clk); check_test("NOT: ALU_WAIT", 33'h000004000);
        alu_end = 1;
        @(negedge clk); check_test("NOT: GET_RESULT", 33'h0000A0000);

        // --- OP_CMP ---
        reset_to_decode(); opcode = OP_CMP; regaddr = 0; alu_end = 0;
        @(negedge clk); check_test("CMP: ALU_LOAD_OPC", 33'h000004000);
        @(negedge clk); check_test("CMP: ALU_LOAD_OP1", 33'h000005000);
        @(negedge clk); check_test("CMP: ALU_LOAD_OP2 (High)", 33'h000006000);
        @(negedge clk); check_test("CMP: ALU_WAIT", 33'h000004000);
        alu_end = 1;
        // compare/test: ldFLAG only (no ldA)
        @(negedge clk); check_test("CMP: GET_FLAGS_ONLY", 33'h000020000);

        // --- OP_TST ---
        reset_to_decode(); opcode = OP_TST; regaddr = 0; alu_end = 0;
        @(negedge clk); check_test("TST: ALU_LOAD_OPC", 33'h000004000);
        @(negedge clk); check_test("TST: ALU_LOAD_OP1", 33'h000005000);
        @(negedge clk); check_test("TST: ALU_LOAD_OP2 (High)", 33'h000006000);
        @(negedge clk); check_test("TST: ALU_WAIT", 33'h000004000);
        alu_end = 1;
        @(negedge clk); check_test("TST: GET_FLAGS_ONLY", 33'h000020000);

        /* === ALU: bit5=1 (immediate ops) — condALU=11 vs 10 === */
        
        // --- OP_ADDI ---
        reset_to_decode(); opcode = OP_ADDI; regaddr = 0; alu_end = 0;
        @(negedge clk); check_test("ADDI: ALU_LOAD_OPC", 33'h000004000);
        @(negedge clk); check_test("ADDI: ALU_LOAD_OP1", 33'h000005000);
        @(negedge clk); check_test("ADDI: ALU_LOAD_OP2 (Imm)", 33'h000007000);
        @(negedge clk); check_test("ADDI: ALU_WAIT", 33'h000004000);
        alu_end = 1;
        @(negedge clk); check_test("ADDI: GET_RESULT", 33'h0000A0000);

        // --- OP_SUBI ---
        reset_to_decode(); opcode = OP_SUBI; regaddr = 0; alu_end = 0;
        @(negedge clk); check_test("SUBI: ALU_LOAD_OPC", 33'h000004000);
        @(negedge clk); check_test("SUBI: ALU_LOAD_OP1", 33'h000005000);
        @(negedge clk); check_test("SUBI: ALU_LOAD_OP2 (Imm)", 33'h000007000);
        @(negedge clk); check_test("SUBI: ALU_WAIT", 33'h000004000);
        alu_end = 1;
        @(negedge clk); check_test("SUBI: GET_RESULT", 33'h0000A0000);

        // --- OP_MULI ---
        reset_to_decode(); opcode = OP_MULI; regaddr = 0; alu_end = 0;
        @(negedge clk); check_test("MULI: ALU_LOAD_OPC", 33'h000004000);
        @(negedge clk); check_test("MULI: ALU_LOAD_OP1", 33'h000005000);
        @(negedge clk); check_test("MULI: ALU_LOAD_OP2 (Imm)", 33'h000007000);
        @(negedge clk); check_test("MULI: ALU_WAIT", 33'h000004000);
        alu_end = 1;
        @(negedge clk); check_test("MULI: GET_RESULT", 33'h0000A0000);

        // --- OP_DIVI ---
        reset_to_decode(); opcode = OP_DIVI; regaddr = 0; alu_end = 0;
        @(negedge clk); check_test("DIVI: ALU_LOAD_OPC", 33'h000004000);
        @(negedge clk); check_test("DIVI: ALU_LOAD_OP1", 33'h000005000);
        @(negedge clk); check_test("DIVI: ALU_LOAD_OP2 (Imm)", 33'h000007000);
        @(negedge clk); check_test("DIVI: ALU_WAIT", 33'h000004000);
        alu_end = 1;
        @(negedge clk); check_test("DIVI: GET_RESULT", 33'h0000A0000);

        // --- OP_MODI ---
        reset_to_decode(); opcode = OP_MODI; regaddr = 0; alu_end = 0;
        @(negedge clk); check_test("MODI: ALU_LOAD_OPC", 33'h000004000);
        @(negedge clk); check_test("MODI: ALU_LOAD_OP1", 33'h000005000);
        @(negedge clk); check_test("MODI: ALU_LOAD_OP2 (Imm)", 33'h000007000);
        @(negedge clk); check_test("MODI: ALU_WAIT", 33'h000004000);
        alu_end = 1;
        @(negedge clk); check_test("MODI: GET_RESULT", 33'h0000A0000);

        // --- OP_LSLI ---
        reset_to_decode(); opcode = OP_LSLI; regaddr = 0; alu_end = 0;
        @(negedge clk); check_test("LSLI: ALU_LOAD_OPC", 33'h000004000);
        @(negedge clk); check_test("LSLI: ALU_LOAD_OP1", 33'h000005000);
        @(negedge clk); check_test("LSLI: ALU_LOAD_OP2 (Imm)", 33'h000007000);
        @(negedge clk); check_test("LSLI: ALU_WAIT", 33'h000004000);
        alu_end = 1;
        @(negedge clk); check_test("LSLI: GET_RESULT", 33'h0000A0000);

        // --- OP_LSRI ---
        reset_to_decode(); opcode = OP_LSRI; regaddr = 0; alu_end = 0;
        @(negedge clk); check_test("LSRI: ALU_LOAD_OPC", 33'h000004000);
        @(negedge clk); check_test("LSRI: ALU_LOAD_OP1", 33'h000005000);
        @(negedge clk); check_test("LSRI: ALU_LOAD_OP2 (Imm)", 33'h000007000);
        @(negedge clk); check_test("LSRI: ALU_WAIT", 33'h000004000);
        alu_end = 1;
        @(negedge clk); check_test("LSRI: GET_RESULT", 33'h0000A0000);

        // --- OP_RSRI ---
        reset_to_decode(); opcode = OP_RSRI; regaddr = 0; alu_end = 0;
        @(negedge clk); check_test("RSRI: ALU_LOAD_OPC", 33'h000004000);
        @(negedge clk); check_test("RSRI: ALU_LOAD_OP1", 33'h000005000);
        @(negedge clk); check_test("RSRI: ALU_LOAD_OP2 (Imm)", 33'h000007000);
        @(negedge clk); check_test("RSRI: ALU_WAIT", 33'h000004000);
        alu_end = 1;
        @(negedge clk); check_test("RSRI: GET_RESULT", 33'h0000A0000);

        // --- OP_RSLI ---
        reset_to_decode(); opcode = OP_RSLI; regaddr = 0; alu_end = 0;
        @(negedge clk); check_test("RSLI: ALU_LOAD_OPC", 33'h000004000);
        @(negedge clk); check_test("RSLI: ALU_LOAD_OP1", 33'h000005000);
        @(negedge clk); check_test("RSLI: ALU_LOAD_OP2 (Imm)", 33'h000007000);
        @(negedge clk); check_test("RSLI: ALU_WAIT", 33'h000004000);
        alu_end = 1;
        @(negedge clk); check_test("RSLI: GET_RESULT", 33'h0000A0000);

        // --- OP_ANDI ---
        reset_to_decode(); opcode = OP_ANDI; regaddr = 0; alu_end = 0;
        @(negedge clk); check_test("ANDI: ALU_LOAD_OPC", 33'h000004000);
        @(negedge clk); check_test("ANDI: ALU_LOAD_OP1", 33'h000005000);
        @(negedge clk); check_test("ANDI: ALU_LOAD_OP2 (Imm)", 33'h000007000);
        @(negedge clk); check_test("ANDI: ALU_WAIT", 33'h000004000);
        alu_end = 1;
        @(negedge clk); check_test("ANDI: GET_RESULT", 33'h0000A0000);

        // --- OP_ORI ---
        reset_to_decode(); opcode = OP_ORI; regaddr = 0; alu_end = 0;
        @(negedge clk); check_test("ORI: ALU_LOAD_OPC", 33'h000004000);
        @(negedge clk); check_test("ORI: ALU_LOAD_OP1", 33'h000005000);
        @(negedge clk); check_test("ORI: ALU_LOAD_OP2 (Imm)", 33'h000007000);
        @(negedge clk); check_test("ORI: ALU_WAIT", 33'h000004000);
        alu_end = 1;
        @(negedge clk); check_test("ORI: GET_RESULT", 33'h0000A0000);

        // --- OP_XORI ---
        reset_to_decode(); opcode = OP_XORI; regaddr = 0; alu_end = 0;
        @(negedge clk); check_test("XORI: ALU_LOAD_OPC", 33'h000004000);
        @(negedge clk); check_test("XORI: ALU_LOAD_OP1", 33'h000005000);
        @(negedge clk); check_test("XORI: ALU_LOAD_OP2 (Imm)", 33'h000007000);
        @(negedge clk); check_test("XORI: ALU_WAIT", 33'h000004000);
        alu_end = 1;
        @(negedge clk); check_test("XORI: GET_RESULT", 33'h0000A0000);

        // --- OP_NOTI ---
        reset_to_decode(); opcode = OP_NOTI; regaddr = 0; alu_end = 0;
        @(negedge clk); check_test("NOTI: ALU_LOAD_OPC", 33'h000004000);
        @(negedge clk); check_test("NOTI: ALU_LOAD_OP1", 33'h000005000);
        @(negedge clk); check_test("NOTI: ALU_LOAD_OP2 (Imm)", 33'h000007000);
        @(negedge clk); check_test("NOTI: ALU_WAIT", 33'h000004000);
        alu_end = 1;
        @(negedge clk); check_test("NOTI: GET_RESULT", 33'h0000A0000);

        // --- OP_CMPI ---
        reset_to_decode(); opcode = OP_CMPI; regaddr = 0; alu_end = 0;
        @(negedge clk); check_test("CMPI: ALU_LOAD_OPC", 33'h000004000);
        @(negedge clk); check_test("CMPI: ALU_LOAD_OP1", 33'h000005000);
        @(negedge clk); check_test("CMPI: ALU_LOAD_OP2 (Imm)", 33'h000007000);
        @(negedge clk); check_test("CMPI: ALU_WAIT", 33'h000004000);
        alu_end = 1;
        @(negedge clk); check_test("CMPI: GET_FLAGS_ONLY", 33'h000020000);

        // --- OP_TSTI ---
        reset_to_decode(); opcode = OP_TSTI; regaddr = 0; alu_end = 0;
        @(negedge clk); check_test("TSTI: ALU_LOAD_OPC", 33'h000004000);
        @(negedge clk); check_test("TSTI: ALU_LOAD_OP1", 33'h000005000);
        @(negedge clk); check_test("TSTI: ALU_LOAD_OP2 (Imm)", 33'h000007000);
        @(negedge clk); check_test("TSTI: ALU_WAIT", 33'h000004000);
        alu_end = 1;
        @(negedge clk); check_test("TSTI: GET_FLAGS_ONLY", 33'h000020000);
        
        
        // Memory and stack
        
        
        // --- STORE ---
        reset_to_decode(); opcode = OP_STORE; regaddr = 0; // Store X
        @(negedge clk); check_test("STORE_1 (ldAR)", 33'h180000000);
        @(negedge clk); check_test("STORE_2 (ldDR X)", 33'h024000000); // condDR=001
        @(negedge clk); check_test("STORE_3 (memWR)", 33'h000040000);

        // --- PUSH ---
        reset_to_decode(); opcode = OP_PUSH;
        @(negedge clk); check_test("PUSH_1 (ldAR SP)", 33'h140000000);
        @(negedge clk); check_test("PUSH_2 (ldDR from A)", 33'h02C000000);
        @(negedge clk); check_test("PUSH_3 (memWR, decSP)", 33'h000848000);

        // --- RET ---
        reset_to_decode(); opcode = OP_RET;
        @(negedge clk); check_test("RET_1 (incSP)", 33'h000010000);
        @(negedge clk); check_test("RET_2 (ldAR SP)", 33'h140000000);
        @(negedge clk); check_test("RET_3 (ldDR)", 33'h020000000);
        @(negedge clk); check_test("RET_4 (Wait)", 33'h000000000);
        @(negedge clk); check_test("RET_5 (ldPC)", 33'h000C00000); // ldPC=1, ldPCfromDR=1
        
        
        // Misc: MOV, INC, MINE, HALT
        
        
        // --- MOV (Move Reg to Reg) ---
        reset_to_decode(); opcode = OP_MOV; regaddr = 1; // Mov to Y
        @(negedge clk); check_test("MOV_1 (ldDR from A)", 33'h030000000); // condDR=100
        // MOV_2: ldY=1(bit 18), ldFLAG=1, use_direct_flag=1 -> 0x00048020
        @(negedge clk); check_test("MOV_2 (ldY, Flags)", 33'h000120080);

        // --- MOVI (Move Immediate) ---
        reset_to_decode(); opcode = OP_MOVI;
        // MOVI_1: ldA=1, use_imm_a=1 -> 0x00020010
        @(negedge clk); check_test("MOVI_1", 33'h000080040);

        // --- INC (Increment X) ---
        reset_to_decode(); opcode = OP_INC; regaddr = 0; // Inc X
        @(negedge clk); check_test("INC_1 (incrX)", 33'h000000800);
        // INC_2: ldFLAG, use_direct, use_xy -> 0x00008028
        @(negedge clk); check_test("INC_2 (Update Flags)", 33'h0000200A0);

        // --- MINING ---
        reset_to_decode(); opcode = OP_MINE; mining_done = 0;
        @(negedge clk); check_test("MINE_START", 33'h000000010);
        @(negedge clk); check_test("MINE_WAIT", 33'h000000000);
        mining_done = 1; // Trigger finish
        // MINE_GET_RESULT: ldX=1, ldA=1, use_mining=1 -> 0x000A0002
        @(negedge clk); check_test("MINE_GET_RESULT", 33'h000280008);
        
        /*
        ========================================
             Instruction Tests: New Branches & NOP
        ========================================
        */

        // --- BGT (Branch Greater Than) 011110 ---
        // Logic from cu.v: Taken if (~Z & ~N)
        
        // Case 1: Taken (Z=0, N=0)
        reset_to_decode();
        opcode = 6'b011110; // OP_BGT
        Z = 0; N = 0;
        @(negedge clk); check_test("BGT_CHECK (~Z & ~N)", 33'h000000000);
        @(negedge clk); check_test("BGT_TAKE (ldPC=1)", 33'h000800000);

        // Case 2: Skipped (Z=1 implies Equal)
        reset_to_decode();
        opcode = 6'b011110; 
        Z = 1; N = 0;
        @(negedge clk); check_test("BGT_CHECK (Z=1)", 33'h000000000);
        @(negedge clk); check_test("BGT_SKIP", 33'h000000000);

        // --- BLT (Branch Less Than) 011111 ---
        // Logic from cu.v: Taken if (N & ~Z)
        
        // Case 1: Taken (N=1, Z=0)
        reset_to_decode();
        opcode = 6'b011111; // OP_BLT
        N = 1; Z = 0;
        @(negedge clk); check_test("BLT_CHECK (N & ~Z)", 33'h000000000);
        @(negedge clk); check_test("BLT_TAKE (ldPC=1)", 33'h000800000);

        // Case 2: Skipped (N=0 implies Positive)
        reset_to_decode();
        opcode = 6'b011111; 
        N = 0; Z = 0;
        @(negedge clk); check_test("BLT_CHECK (N=0)", 33'h000000000);
        @(negedge clk); check_test("BLT_SKIP", 33'h000000000);

        // --- BGE (Branch Greater or Equal) 100000 ---
        // Logic from cu.v: Taken if (~N | Z)
        
        // Case 1: Taken (Z=1)
        reset_to_decode();
        opcode = 6'b100000; // OP_BGE
        N = 0; Z = 1;
        @(negedge clk); check_test("BGE_CHECK (Z=1)", 33'h000000000);
        @(negedge clk); check_test("BGE_TAKE (ldPC=1)", 33'h000800000);

        // Case 2: Skipped (N=1, Z=0 implies Less Than)
        reset_to_decode();
        opcode = 6'b100000; 
        N = 1; Z = 0;
        @(negedge clk); check_test("BGE_CHECK (N=1, Z=0)", 33'h000000000);
        @(negedge clk); check_test("BGE_SKIP", 33'h000000000);

        // --- BLE (Branch Less or Equal) 100001 ---
        // Logic from cu.v: Taken if (N | Z)
        
        // Case 1: Taken (N=1)
        reset_to_decode();
        opcode = 6'b100001; // OP_BLE
        N = 1; Z = 0;
        @(negedge clk); check_test("BLE_CHECK (N=1)", 33'h000000000);
        @(negedge clk); check_test("BLE_TAKE (ldPC=1)", 33'h000800000);

        // Case 2: Skipped (N=0, Z=0 implies Greater Than)
        reset_to_decode();
        opcode = 6'b100001;
        N = 0; Z = 0;
        @(negedge clk); check_test("BLE_CHECK (N=0, Z=0)", 33'h000000000);
        @(negedge clk); check_test("BLE_SKIP", 33'h000000000);

        // --- BNE (Branch Not Equal) 100101 ---
        // Logic from cu.v: Taken if (Z == 0)

        // Case 1: Taken (Z=0)
        reset_to_decode();
        opcode = OP_BNE;
        Z = 0; N = 0;
        @(negedge clk); check_test("BNE_CHECK (Z=0)", 33'h000000000);
        @(negedge clk); check_test("BNE_TAKE (ldPC=1)", 33'h000800000);

        // Case 2: Skipped (Z=1 implies Equal)
        reset_to_decode();
        opcode = OP_BNE;
        Z = 1; N = 0;
        @(negedge clk); check_test("BNE_CHECK (Z=1)", 33'h000000000);
        @(negedge clk); check_test("BNE_SKIP", 33'h000000000);

        // --- NOP (No Operation) 100010 ---
        reset_to_decode();
        opcode = 6'b100010; // OP_NOP

        // NOP_1: No signals active (0x000000000)
        @(negedge clk); check_test("NOP_1 (No Op)", 33'h000000000);

        // Returns to LOAD_ADDR: ldAR=1 (bit 32) -> 0x100000000
        @(negedge clk); check_test("Return to LOAD_ADDR", 33'h100000000);

        // --- PUSH_REG (Push Register X/Y) 100011 ---
        // Test PUSH X (regaddr=0)
        reset_to_decode();
        opcode = OP_PUSH_REG;
        regaddr = 1'b0;

        // PUSH_REG_1: ldAR=1, condAR=01 -> bits [32:31] = 101 = 0x140000000
        @(negedge clk); check_test("PUSH_REG_1 (ldAR=1, condAR=01)", 33'h140000000);

        // PUSH_REG_2: ldDR=1, condDR=001 (X) -> bits [29:26] = 1001 = 0x024000000
        @(negedge clk); check_test("PUSH_REG_2 (ldDR=1, condDR=001 for X)", 33'h024000000);

        // PUSH_REG_3: memWR=1 (bit18), decSP=1 (bit15) -> 0x48000
        @(negedge clk); check_test("PUSH_REG_3 (memWR=1, decSP=1)", 33'h000048000);

        // Returns to LOAD_ADDR
        @(negedge clk); check_test("Return to LOAD_ADDR after PUSH X", 33'h100000000);

        // Test PUSH Y (regaddr=1)
        reset_to_decode();
        opcode = OP_PUSH_REG;
        regaddr = 1'b1;

        // PUSH_REG_1: ldAR=1, condAR=01 -> 0x140000000
        @(negedge clk); check_test("PUSH_REG_1 Y (ldAR=1, condAR=01)", 33'h140000000);

        // PUSH_REG_2: ldDR=1, condDR=010 (Y) -> bits [29:26] = 1010 = 0x028000000
        @(negedge clk); check_test("PUSH_REG_2 (ldDR=1, condDR=010 for Y)", 33'h028000000);

        // PUSH_REG_3: memWR=1 (bit18), decSP=1 (bit15) -> 0x48000
        @(negedge clk); check_test("PUSH_REG_3 Y (memWR=1, decSP=1)", 33'h000048000);

        // Returns to LOAD_ADDR
        @(negedge clk); check_test("Return to LOAD_ADDR after PUSH Y", 33'h100000000);

        // --- POP_REG (Pop Register X/Y) 100100 ---
        // Test POP X (regaddr=0)
        reset_to_decode();
        opcode = OP_POP_REG;
        regaddr = 1'b0;

        // POP_REG_1: incSP=1 (bit16) -> 0x10000
        @(negedge clk); check_test("POP_REG_1 (incSP=1)", 33'h000010000);

        // POP_REG_2: ldAR=1, condAR=01 -> 0x140000000
        @(negedge clk); check_test("POP_REG_2 (ldAR=1, condAR=01)", 33'h140000000);

        // POP_REG_3: ldDR=1, condDR=000 (mem) -> bits [29:26] = 1000 = 0x020000000
        @(negedge clk); check_test("POP_REG_3 (ldDR=1, condDR=000 mem)", 33'h020000000);

        // POP_REG_4: ldX=1 -> bit [21] = 0x000200000
        @(negedge clk); check_test("POP_REG_4 X (ldX=1)", 33'h000200000);

        // Returns to LOAD_ADDR
        @(negedge clk); check_test("Return to LOAD_ADDR after POP X", 33'h100000000);

        // Test POP Y (regaddr=1)
        reset_to_decode();
        opcode = OP_POP_REG;
        regaddr = 1'b1;

        // POP_REG_1: incSP=1 (bit16) -> 0x10000
        @(negedge clk); check_test("POP_REG_1 Y (incSP=1)", 33'h000010000);

        // POP_REG_2: ldAR=1, condAR=01 -> 0x140000000
        @(negedge clk); check_test("POP_REG_2 Y (ldAR=1, condAR=01)", 33'h140000000);

        // POP_REG_3: ldDR=1, condDR=000 (mem) -> 0x020000000
        @(negedge clk); check_test("POP_REG_3 Y (ldDR=1, condDR=000 mem)", 33'h020000000);

        // POP_REG_4: ldY=1 -> bit [20] = 0x000100000
        @(negedge clk); check_test("POP_REG_4 Y (ldY=1)", 33'h000100000);

        // Returns to LOAD_ADDR
        @(negedge clk); check_test("Return to LOAD_ADDR after POP Y", 33'h100000000);

        /*
        ========================================
             Instruction Test: HALT
        ========================================
        */
        reset_to_decode();

        opcode = OP_HALT;

        // DECODE -> HALT_STATE
        // HALT_STATE: finish=1 (bit 0) -> 0x000000001
        @(negedge clk);

        check_test("State HALT: finish=1", 33'h000000001);


        $display("---------------------------------------");
        $display("Simulation done!");
        $display("Total Teste: %d", test_count);
        $display("Teste PASS : %d", pass_count);
        $display("Teste FAIL : %d", fail_count);
        $display("---------------------------------------");

        #100; $stop;
    end

    initial begin
        #10000;
        $display("\nERROR: Testbench timeout!");
        $finish;
    end

endmodule