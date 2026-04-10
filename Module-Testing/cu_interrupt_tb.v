`timescale 1ns / 1ns

// cu_interrupt_tb: Tests for CU interrupt states 78-97 (v3.1)
// Covers: INTR_CHECK (78), INTR_SAVE_1-6 (79-84), INTR_VECTOR (85),
//         INTR_JUMP_1-2 (86-87), IRET_1-7 (88-94), EI_1 (95), DI_1 (96), WAIT_1 (97)
module cu_interrupt_tb;

    // --- Inputs to CU ---
    reg        clk, rst_n;
    reg  [5:0] opcode;
    reg        regaddr;
    reg [15:0] ir_out;
    reg        Z, N, C, O;
    reg        alu_end, alu_exc, mining_done;
    reg        intr_pending;
    reg  [1:0] irq_id;

    // --- Outputs from CU (control bus) ---
    wire        ldAR;
    wire  [1:0] condAR;
    wire        ldDR;
    wire  [2:0] condDR;
    wire        ldIR, incPC, ldPC, ldPCfromDR;
    wire        ldX, ldY, ldA, memWR, ldFLAG;
    wire        incSP, decSP, alu_start;
    wire  [1:0] condALU;
    wire        incrX, decrX, incrY, decrY;
    wire        use_direct_flag, use_imm_a, use_xy_for_flags;
    wire        mining_start, use_mining_result, use_dr_for_a, use_movr_flags;
    wire        finish;
    wire        io_we, io_re, ivt_mode;

    // --- New interrupt-specific outputs ---
    wire        intr_ack, set_I, clr_I, use_packed_flags;
    wire  [1:0] saved_irq_id;

    // --- Composite buses for easy comparison ---
    // ctrl_bus matches cu_tb.v format (33 bits, excludes interrupt signals)
    wire [32:0] ctrl_bus;
    assign ctrl_bus = {
        ldAR, condAR, ldDR, condDR, ldIR, incPC, ldPC, ldPCfromDR,
        ldX, ldY, ldA, memWR, ldFLAG, incSP, decSP, alu_start, condALU,
        incrX, decrX, incrY, decrY, use_direct_flag, use_imm_a, use_xy_for_flags,
        mining_start, use_mining_result, use_dr_for_a, use_movr_flags, finish
    };

    // intr_bus: {intr_ack, set_I, clr_I, use_packed_flags, ivt_mode}
    wire [4:0] intr_bus;
    assign intr_bus = {intr_ack, set_I, clr_I, use_packed_flags, ivt_mode};

    // --- CU instantiation ---
    cu uut (
        .clk(clk), .rst_n(rst_n),
        .opcode(opcode), .regaddr(regaddr), .ir_out(ir_out),
        .Z(Z), .N(N), .C(C), .O(O),
        .alu_end(alu_end), .alu_exc(alu_exc), .mining_done(mining_done),
        .ldAR(ldAR), .condAR(condAR),
        .ldDR(ldDR), .condDR(condDR),
        .ldIR(ldIR), .incPC(incPC), .ldPC(ldPC), .ldPCfromDR(ldPCfromDR),
        .ldX(ldX), .ldY(ldY), .ldA(ldA),
        .memWR(memWR), .ldFLAG(ldFLAG),
        .incSP(incSP), .decSP(decSP),
        .alu_start(alu_start), .condALU(condALU),
        .incrX(incrX), .decrX(decrX), .incrY(incrY), .decrY(decrY),
        .use_direct_flag(use_direct_flag), .use_imm_a(use_imm_a),
        .use_xy_for_flags(use_xy_for_flags),
        .mining_start(mining_start), .use_mining_result(use_mining_result),
        .use_dr_for_a(use_dr_for_a), .use_movr_flags(use_movr_flags),
        .finish(finish),
        .io_we(io_we), .io_re(io_re), .ivt_mode(ivt_mode),
        .intr_pending(intr_pending), .irq_id(irq_id),
        .intr_ack(intr_ack), .set_I(set_I), .clr_I(clr_I),
        .use_packed_flags(use_packed_flags), .saved_irq_id(saved_irq_id)
    );

    // --- Test counters ---
    integer test_count = 0;
    integer pass_count = 0;
    integer fail_count = 0;

    // --- Check helpers ---
    task check_ctrl;
        input [511:0] name;
        input  [32:0] exp_ctrl;
        begin
            test_count = test_count + 1;
            if (ctrl_bus == exp_ctrl) begin
                $display("Test %2d PASS: %s", test_count, name);
                pass_count = pass_count + 1;
            end else begin
                $display("Test %2d FAIL: %s", test_count, name);
                $display("  -> ctrl_bus exp=%h  got=%h", exp_ctrl, ctrl_bus);
                fail_count = fail_count + 1;
            end
        end
    endtask

    task check_intr;
        input [511:0] name;
        input   [4:0] exp_intr;  // {intr_ack, set_I, clr_I, use_packed_flags, ivt_mode}
        begin
            test_count = test_count + 1;
            if (intr_bus == exp_intr) begin
                $display("Test %2d PASS: %s", test_count, name);
                pass_count = pass_count + 1;
            end else begin
                $display("Test %2d FAIL: %s", test_count, name);
                $display("  -> intr_bus exp=%b  got=%b", exp_intr, intr_bus);
                fail_count = fail_count + 1;
            end
        end
    endtask

    task check_saved_irq;
        input [511:0] name;
        input   [1:0] exp_id;
        begin
            test_count = test_count + 1;
            if (saved_irq_id == exp_id) begin
                $display("Test %2d PASS: %s", test_count, name);
                pass_count = pass_count + 1;
            end else begin
                $display("Test %2d FAIL: %s", test_count, name);
                $display("  -> saved_irq_id exp=%b  got=%b", exp_id, saved_irq_id);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // --- Clock ---
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // reset_to_decode: leaves FSM in DECODE state (intr_pending=0 must be set before call)
    task reset_to_decode;
        begin
            rst_n = 0;
            #1;
            rst_n = 1;
            @(negedge clk);  // LOAD_ADDR
            @(negedge clk);  // LOAD_INSTR
            @(negedge clk);  // INTR_CHECK (intr_pending=0 → DECODE)
            // Now in DECODE
        end
    endtask

    // Opcode constants for new instructions
    localparam OP_EI   = 6'b101000;
    localparam OP_DI   = 6'b101001;
    localparam OP_IRET = 6'b111010;
    localparam OP_WAIT = 6'b111011;

    // ctrl_bus expected values for interrupt states
    // Bit layout: ldAR[32] condAR[31:30] ldDR[29] condDR[28:26] ldIR[25] incPC[24]
    //             ldPC[23] ldPCfromDR[22] ldX[21] ldY[20] ldA[19] memWR[18] ldFLAG[17]
    //             incSP[16] decSP[15] alu_start[14] condALU[13:12] incrX[11] decrX[10]
    //             incrY[9] decrY[8] use_direct_flag[7] use_imm_a[6] use_xy_for_flags[5]
    //             mining_start[4] use_mining_result[3] use_dr_for_a[2] use_movr_flags[1] finish[0]
    localparam CTRL_NONE       = 33'h000000000; // no signals
    localparam CTRL_LOAD_ADDR  = 33'h100000000; // ldAR=1, condAR=00
    localparam CTRL_SAVE_1_4   = 33'h140000000; // ldAR=1, condAR=01  (INTR_SAVE_1/4, IRET_2/5)
    localparam CTRL_SAVE_2     = 33'h03C000000; // ldDR=1, condDR=111 (INTR_SAVE_2)
    localparam CTRL_SAVE_3_6   = 33'h000048000; // memWR=1, decSP=1   (INTR_SAVE_3/6)
    localparam CTRL_SAVE_5     = 33'h02C000000; // ldDR=1, condDR=011 (INTR_SAVE_5, PC to stack)
    localparam CTRL_VECTOR     = 33'h1C0000000; // ldAR=1, condAR=11  (INTR_VECTOR)
    localparam CTRL_JUMP_1_3_6 = 33'h020000000; // ldDR=1, condDR=000 (INTR_JUMP_1, IRET_3/6)
    localparam CTRL_JUMP_2     = 33'h000C00000; // ldPC=1, ldPCfromDR=1
    localparam CTRL_IRET_1     = 33'h000010000; // incSP=1
    localparam CTRL_IRET_4     = 33'h000C10000; // ldPC=1, ldPCfromDR=1, incSP=1
    localparam CTRL_IRET_7     = 33'h000020000; // ldFLAG=1

    // intr_bus: {intr_ack, set_I, clr_I, use_packed_flags, ivt_mode}
    localparam INTR_NONE       = 5'b00000;
    localparam INTR_EI         = 5'b01000; // set_I=1
    localparam INTR_DI         = 5'b00100; // clr_I=1
    localparam INTR_SAVE_1_SIG = 5'b10100; // intr_ack=1, clr_I=1
    localparam INTR_VECTOR_SIG = 5'b00001; // ivt_mode=1
    localparam INTR_IRET_7_SIG = 5'b01010; // set_I=1, use_packed_flags=1

    // =======================================================================
    // Main test sequence
    // =======================================================================
    initial begin
        // Initialise all inputs
        rst_n = 1; opcode = 6'b0; regaddr = 0; ir_out = 16'h0;
        Z = 0; N = 0; C = 0; O = 0;
        alu_end = 0; alu_exc = 0; mining_done = 0;
        intr_pending = 0; irq_id = 2'b00;

        // -------------------------------------------------------------------
        // Section 1: EI instruction — sets I_flag
        // After reset_to_decode (DECODE), 1 @negedge → EI_1
        // -------------------------------------------------------------------
        reset_to_decode();
        opcode = OP_EI;
        @(negedge clk);  // DECODE → EI_1
        check_ctrl("EI_1: no ctrl signals (I_flag set internally)", CTRL_NONE);
        check_intr("EI_1: set_I=1, others=0", INTR_EI);

        // EI_1 → LOAD_ADDR (I_flag becomes 1 at this posedge)
        @(negedge clk);
        check_ctrl("LOAD_ADDR after EI", CTRL_LOAD_ADDR);

        // -------------------------------------------------------------------
        // Section 2: DI instruction — clears I_flag
        // -------------------------------------------------------------------
        reset_to_decode();
        opcode = OP_DI;
        @(negedge clk);  // DECODE → DI_1
        check_ctrl("DI_1: no ctrl signals", CTRL_NONE);
        check_intr("DI_1: clr_I=1, others=0", INTR_DI);

        // -------------------------------------------------------------------
        // Section 3: INTR_CHECK does NOT fire when I_flag=0
        // After DI, I_flag=0. Run a new fetch with intr_pending=1.
        // INTR_CHECK should pass through to DECODE (not INTR_SAVE_1).
        // -------------------------------------------------------------------
        intr_pending = 1;
        @(negedge clk);  // DI_1 → LOAD_ADDR
        @(negedge clk);  // LOAD_ADDR → LOAD_INSTR
        @(negedge clk);  // LOAD_INSTR → INTR_CHECK
        @(negedge clk);  // INTR_CHECK (I_flag=0) → DECODE (not INTR_SAVE_1!)
        check_ctrl("INTR_CHECK (I_flag=0, intr_pending=1): passes to DECODE", CTRL_NONE);
        check_intr("INTR_CHECK (I_flag=0): no interrupt signals", INTR_NONE);
        intr_pending = 0;

        // -------------------------------------------------------------------
        // Section 4: Full interrupt save chain (INTR_SAVE_1 → INTR_JUMP_2)
        // Sequence: reset → EI → new fetch with intr_pending=1 → INTR_CHECK fires
        // -------------------------------------------------------------------
        reset_to_decode();
        opcode = OP_EI;
        @(negedge clk);  // EI_1 (I_flag←1 at this posedge)
        @(negedge clk);  // LOAD_ADDR (I_flag=1)
        @(negedge clk);  // LOAD_INSTR
        intr_pending = 1; irq_id = 2'b10;  // MINE interrupt (id=2)
        @(negedge clk);  // INTR_CHECK: I_flag=1, intr_pending=1 → INTR_SAVE_1 next
        check_ctrl("INTR_CHECK (I_flag=1, intr_pending=1): no signals", CTRL_NONE);
        check_intr("INTR_CHECK (I_flag=1): no interrupt signals", INTR_NONE);

        @(negedge clk);  // INTR_SAVE_1: intr_ack=1, clr_I=1, AR←SP; saved_irq_id←irq_id here
        check_ctrl("INTR_SAVE_1: ldAR=1, condAR=01", CTRL_SAVE_1_4);
        check_intr("INTR_SAVE_1: intr_ack=1, clr_I=1", INTR_SAVE_1_SIG);

        @(negedge clk);  // INTR_SAVE_2: DR←packed FLAGS (condDR=111); saved_irq_id captured
        check_ctrl("INTR_SAVE_2: ldDR=1, condDR=111 (packed FLAGS)", CTRL_SAVE_2);
        check_intr("INTR_SAVE_2: no interrupt signals", INTR_NONE);
        check_saved_irq("INTR_SAVE_2: saved_irq_id=2 (MINE, captured at INTR_SAVE_1)", 2'b10);

        @(negedge clk);  // INTR_SAVE_3: mem[SP]←FLAGS, SP--
        check_ctrl("INTR_SAVE_3: memWR=1, decSP=1", CTRL_SAVE_3_6);

        @(negedge clk);  // INTR_SAVE_4: AR←SP (decremented)
        check_ctrl("INTR_SAVE_4: ldAR=1, condAR=01", CTRL_SAVE_1_4);

        @(negedge clk);  // INTR_SAVE_5: DR←PC (return address)
        check_ctrl("INTR_SAVE_5: ldDR=1, condDR=011 (PC)", CTRL_SAVE_5);

        @(negedge clk);  // INTR_SAVE_6: mem[SP]←PC, SP--
        check_ctrl("INTR_SAVE_6: memWR=1, decSP=1", CTRL_SAVE_3_6);

        @(negedge clk);  // INTR_VECTOR: AR←190+saved_irq_id, ivt_mode=1
        check_ctrl("INTR_VECTOR: ldAR=1, condAR=11 (IVT address)", CTRL_VECTOR);
        check_intr("INTR_VECTOR: ivt_mode=1", INTR_VECTOR_SIG);

        @(negedge clk);  // INTR_JUMP_1: DR←mem[IVT entry]
        check_ctrl("INTR_JUMP_1: ldDR=1, condDR=000", CTRL_JUMP_1_3_6);

        @(negedge clk);  // INTR_JUMP_2: PC←DR (ISR address)
        check_ctrl("INTR_JUMP_2: ldPC=1, ldPCfromDR=1", CTRL_JUMP_2);

        @(negedge clk);  // LOAD_ADDR (I_flag=0 from clr_I in INTR_SAVE_1)
        check_ctrl("LOAD_ADDR after interrupt save: back to fetch", CTRL_LOAD_ADDR);
        intr_pending = 0;

        // -------------------------------------------------------------------
        // Section 5: IRET chain (IRET_1 → IRET_7 → LOAD_ADDR)
        // -------------------------------------------------------------------
        reset_to_decode();
        opcode = OP_IRET;
        @(negedge clk);  // DECODE → IRET_1
        check_ctrl("IRET_1: incSP=1 (SP++ to saved PC)", CTRL_IRET_1);
        check_intr("IRET_1: no interrupt signals", INTR_NONE);

        @(negedge clk);  // IRET_2: AR←SP
        check_ctrl("IRET_2: ldAR=1, condAR=01", CTRL_SAVE_1_4);

        @(negedge clk);  // IRET_3: DR←mem[SP] = saved PC
        check_ctrl("IRET_3: ldDR=1, condDR=000", CTRL_JUMP_1_3_6);

        @(negedge clk);  // IRET_4: PC←DR, incSP (SP++ to saved FLAGS)
        check_ctrl("IRET_4: ldPC=1, ldPCfromDR=1, incSP=1", CTRL_IRET_4);

        @(negedge clk);  // IRET_5: AR←SP
        check_ctrl("IRET_5: ldAR=1, condAR=01", CTRL_SAVE_1_4);

        @(negedge clk);  // IRET_6: DR←mem[SP] = saved FLAGS word
        check_ctrl("IRET_6: ldDR=1, condDR=000", CTRL_JUMP_1_3_6);

        @(negedge clk);  // IRET_7: restore ZNCO from DR[15:12], re-enable interrupts
        check_ctrl("IRET_7: ldFLAG=1 (flags restore)", CTRL_IRET_7);
        check_intr("IRET_7: use_packed_flags=1, set_I=1", INTR_IRET_7_SIG);

        @(negedge clk);  // LOAD_ADDR (I_flag=1 from set_I in IRET_7)
        check_ctrl("LOAD_ADDR after IRET: I_flag restored", CTRL_LOAD_ADDR);

        // -------------------------------------------------------------------
        // Section 6: WAIT instruction — idles until intr_pending, then exits
        // I_flag=1 at this point (set by IRET_7). intr_pending=0.
        // -------------------------------------------------------------------
        @(negedge clk);  // LOAD_INSTR
        @(negedge clk);  // INTR_CHECK (I_flag=1, intr_pending=0 → DECODE)
        opcode = OP_WAIT;
        @(negedge clk);  // DECODE → WAIT_1
        check_ctrl("WAIT_1: no ctrl signals (CPU idle)", CTRL_NONE);
        check_intr("WAIT_1: no interrupt signals", INTR_NONE);

        @(negedge clk);  // stays in WAIT_1 (intr_pending=0)
        check_ctrl("WAIT_1: stays idle (no interrupt)", CTRL_NONE);

        // Trigger interrupt: WAIT_1 detects intr_pending → exits to INTR_CHECK
        intr_pending = 1;
        @(negedge clk);  // WAIT_1 (intr_pending=1) → INTR_CHECK
        check_ctrl("INTR_CHECK after WAIT exit: no signals", CTRL_NONE);

        @(negedge clk);  // INTR_CHECK (I_flag=1) → INTR_SAVE_1
        check_ctrl("INTR_SAVE_1 from WAIT: ldAR=1, condAR=01", CTRL_SAVE_1_4);
        check_intr("INTR_SAVE_1 from WAIT: intr_ack=1, clr_I=1", INTR_SAVE_1_SIG);

        intr_pending = 0;

        // -------------------------------------------------------------------
        // Section 7: WAIT with I_flag=0 — must stay in WAIT_1 forever
        // After the last reset_to_decode, I_flag=0. Set intr_pending=1.
        // INTR_CHECK passes through to DECODE (I_flag=0). WAIT stays stuck.
        // -------------------------------------------------------------------
        reset_to_decode();
        // I_flag=0 after reset. Do NOT run EI. Drive WAIT opcode.
        opcode = OP_WAIT;
        intr_pending = 1;         // interrupt is pending but I_flag=0
        @(negedge clk);           // DECODE → WAIT_1
        check_ctrl("WAIT_1 (I_flag=0): no ctrl signals", CTRL_NONE);
        check_intr("WAIT_1 (I_flag=0): no interrupt signals", INTR_NONE);

        @(negedge clk);           // WAIT_1 (intr_pending=1) → INTR_CHECK
        check_ctrl("INTR_CHECK from WAIT (I_flag=0): no signals", CTRL_NONE);
        check_intr("INTR_CHECK from WAIT (I_flag=0): no interrupt signals", INTR_NONE);

        @(negedge clk);           // INTR_CHECK (I_flag=0) → DECODE (not INTR_SAVE_1)
        check_ctrl("DECODE after INTR_CHECK (I_flag=0): back to DECODE", CTRL_NONE);
        // OP_WAIT in DECODE → WAIT_1 again (stuck loop, not accepting interrupt)
        @(negedge clk);
        check_ctrl("WAIT_1 again (I_flag=0): CPU still idle, not servicing IRQ", CTRL_NONE);
        intr_pending = 0;

        // -------------------------------------------------------------------
        // Section 8: Nested interrupt blocked during save (I_flag=0 in ISR)
        // Run EI, trigger interrupt → INTR_SAVE_1 sets clr_I.
        // Assert intr_pending again during save → INTR_CHECK routes to DECODE.
        // -------------------------------------------------------------------
        reset_to_decode();
        opcode = OP_EI;
        @(negedge clk);  // EI_1 (I_flag←1 at posedge)
        @(negedge clk);  // LOAD_ADDR
        @(negedge clk);  // LOAD_INSTR
        intr_pending = 1; irq_id = 2'b01;  // KBD interrupt
        @(negedge clk);  // INTR_CHECK → INTR_SAVE_1 (I_flag=1, intr_pending=1)
        @(negedge clk);  // INTR_SAVE_1: intr_ack=1, clr_I=1 (I_flag will be 0)
        check_ctrl("INTR_SAVE_1 nested test: ldAR=1, condAR=01", CTRL_SAVE_1_4);
        check_intr("INTR_SAVE_1 nested test: intr_ack=1, clr_I=1", INTR_SAVE_1_SIG);

        // Keep intr_pending=1 through the entire save chain (simulates nested request)
        @(negedge clk);  // INTR_SAVE_2
        @(negedge clk);  // INTR_SAVE_3
        @(negedge clk);  // INTR_SAVE_4
        @(negedge clk);  // INTR_SAVE_5
        @(negedge clk);  // INTR_SAVE_6
        @(negedge clk);  // INTR_VECTOR
        @(negedge clk);  // INTR_JUMP_1
        @(negedge clk);  // INTR_JUMP_2
        @(negedge clk);  // LOAD_ADDR (ISR starts, I_flag=0)
        @(negedge clk);  // LOAD_INSTR
        @(negedge clk);  // INTR_CHECK (I_flag=0 from clr_I) → DECODE, not INTR_SAVE_1!
        check_ctrl("INTR_CHECK during ISR (I_flag=0): routes to DECODE", CTRL_NONE);
        check_intr("INTR_CHECK during ISR: no interrupt signals (blocked)", INTR_NONE);
        intr_pending = 0;

        // -------------------------------------------------------------------
        // Section 9: All 4 saved_irq_id values captured correctly
        // -------------------------------------------------------------------
        // Test irq_id=0 (TIMER)
        reset_to_decode();
        opcode = OP_EI;
        @(negedge clk);  // EI_1
        @(negedge clk);  // LOAD_ADDR
        @(negedge clk);  // LOAD_INSTR
        intr_pending = 1; irq_id = 2'b00;  // TIMER
        @(negedge clk);  // INTR_CHECK → INTR_SAVE_1
        @(negedge clk);  // INTR_SAVE_1: captures irq_id=0
        @(negedge clk);  // INTR_SAVE_2: saved_irq_id now stable
        check_saved_irq("INTR_SAVE_2: saved_irq_id=0 (TIMER)", 2'b00);
        intr_pending = 0;

        // Test irq_id=1 (KBD)
        reset_to_decode();
        opcode = OP_EI;
        @(negedge clk); @(negedge clk); @(negedge clk);
        intr_pending = 1; irq_id = 2'b01;
        @(negedge clk);  // INTR_CHECK
        @(negedge clk);  // INTR_SAVE_1
        @(negedge clk);  // INTR_SAVE_2
        check_saved_irq("INTR_SAVE_2: saved_irq_id=1 (KBD)", 2'b01);
        intr_pending = 0;

        // Test irq_id=3 (EXT)
        reset_to_decode();
        opcode = OP_EI;
        @(negedge clk); @(negedge clk); @(negedge clk);
        intr_pending = 1; irq_id = 2'b11;
        @(negedge clk);  // INTR_CHECK
        @(negedge clk);  // INTR_SAVE_1
        @(negedge clk);  // INTR_SAVE_2
        check_saved_irq("INTR_SAVE_2: saved_irq_id=3 (EXT)", 2'b11);
        intr_pending = 0;

        // -------------------------------------------------------------------
        // Summary
        // -------------------------------------------------------------------
        $display("-------------------------------------------");
        $display("Simulare Finalizata!");
        $display("Total Teste: %d", test_count);
        $display("Teste PASS : %d", pass_count);
        $display("Teste FAIL : %d", fail_count);
        $display("-------------------------------------------");

        #100; $stop;
    end

    initial begin
        #50000;
        $display("\nERROR: Testbench timeout!");
        $finish;
    end

endmodule
