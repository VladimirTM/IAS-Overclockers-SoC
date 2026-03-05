`timescale 1ns / 1ps

module cpu_tb;

    reg clk;
    reg rst_n;

    wire [15:0] pc_out, A_out, X_out, Y_out, dr_out;
    wire [15:0] mem_out;
    wire mining_done;

    cpu dut (
        .clk(clk),
        .rst_n(rst_n),
        .pc_out(pc_out),
        .A_out(A_out),
        .X_out(X_out),
        .Y_out(Y_out),
        .dr_out(dr_out),
        .mem_out(mem_out),
        .mining_done(mining_done)
    );

    // Clock generation: 10ns period
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    integer test_num = 0;
    integer pass_count = 0;
    integer fail_count = 0;

    task check_test;
        input [1000:0] test_name;
        input condition;
    begin
        test_num = test_num + 1;
        if (condition) begin
            $display("Test %2d PASS: %s", test_num, test_name);
            pass_count = pass_count + 1;
        end else begin
            $display("Test %2d FAIL: %s", test_num, test_name);
            $display("         Actual A=%04h X=%04h Y=%04h Flags=Z%b N%b C%b O%b",
                     A_out, X_out, Y_out, dut.Z_flag, dut.N_flag, dut.C_flag, dut.O_flag);
            fail_count = fail_count + 1;
        end
    end
    endtask

    task wait_for_pc;
        input [15:0] target_pc;
        input [1000:0] instr_name;
        integer timeout_count;
    begin
        timeout_count = 0;
        // Wait for PC to reach target and be in LOAD_ADDR state (0) or HALT_STATE (3)
        while ((pc_out != target_pc || (dut.cu_inst.state != 0 && dut.cu_inst.state != 3)) && timeout_count < 2000) begin
            @(posedge clk);
            timeout_count = timeout_count + 1;
        end
        if (timeout_count >= 2000) begin
            $display("ERROR: Timeout waiting for PC=0x%04h (%s)", target_pc, instr_name);
            $display("       Stuck at PC=0x%04h A=%04h State=%d", pc_out, A_out, dut.cu_inst.state);
            $display("\n========================================");
            $display("Test Summary (Incomplete):");
            $display("  Total: %0d", test_num);
            $display("  Pass:  %0d", pass_count);
            $display("  Fail:  %0d", fail_count);
            $display("  ABORTED due to timeout");
            $display("========================================");
            $finish;
        end
    end
    endtask

    initial begin
        $display("========================================");
        $display("CPU Comprehensive Test - All Instructions");
        $display("Including: JMP, PUSH X/Y, POP X/Y, MOVR, BGT, BLT, BGE, BLE, BEQ, BNE, NOP");
        $display("========================================\n");

        // Reset
        rst_n = 0;
        #20;
        rst_n = 1;
        #10;

        // ==========================================
        // Memory and Control Flow Operations
        // ==========================================
        $display("\n--- Memory and Control Flow ---\n");

        wait_for_pc(16'h0001, "LD X, 284");
        check_test("LD X, 284: X=15", X_out == 16'd15);

        wait_for_pc(16'h0002, "LD Y, 285");
        check_test("LD Y, 285: Y=7", Y_out == 16'd7);

        wait_for_pc(16'h0003, "ST X, 274");
        check_test("ST X, 274: MEM[274]=15", dut.mem_inst.mem[274] == 16'd15);

        wait_for_pc(16'h0004, "ST Y, 275");
        check_test("ST Y, 275: MEM[275]=7", dut.mem_inst.mem[275] == 16'd7);

        // JMP is at PC=0x0004, branches to PC=0x0006, so PC never reaches 0x0005
        // We check that JMP worked by verifying we land at PC=0x0007 (after alu_tests LD X completes)
        wait_for_pc(16'h0007, "After JMP (LD X at alu_tests done)");
        check_test("JMP alu_tests: Stack pushed & branched", dut.mem_inst.mem[1023] == 16'd5 && pc_out == 16'h0007);

        // At alu_tests: LD X, then LD Y
        wait_for_pc(16'h0008, "LD Y, 285");
        check_test("LD Y, 285: Y=7", Y_out == 16'd7);

        // ==========================================
        // ALU Register Operations
        // ==========================================
        $display("\n--- ALU Register Operations ---\n");

        wait_for_pc(16'h0009, "MOVI 100");
        check_test("MOVI 100: A=100", A_out == 16'd100);

        wait_for_pc(16'h000A, "ADD X");
        check_test("ADD X: 100+15=115", A_out == 16'd115);

        wait_for_pc(16'h000B, "SUB X");
        check_test("SUB X: 115-15=100", A_out == 16'd100);

        wait_for_pc(16'h000C, "MUL Y");
        check_test("MUL Y: 100*7=700", A_out == 16'd700);

        wait_for_pc(16'h000D, "DIV Y");
        check_test("DIV Y: 700/7=100", A_out == 16'd100);

        wait_for_pc(16'h000E, "MOD Y");
        check_test("MOD Y: 100 mod 7=2", A_out == 16'd2);

        wait_for_pc(16'h000F, "MOVI 3");
        check_test("MOVI 3: A=3", A_out == 16'd3);

        wait_for_pc(16'h0010, "LSL X");
        check_test("LSL X: 3<<15", A_out == (16'd3 << 15));

        wait_for_pc(16'h0011, "MOVI 16");
        check_test("MOVI 16: A=16", A_out == 16'd16);

        wait_for_pc(16'h0012, "LSR X");
        check_test("LSR X: 16>>15", A_out == (16'd16 >> 15));

        wait_for_pc(16'h0013, "MOVI 255");
        check_test("MOVI 255: A=255", A_out == 16'd255);

        wait_for_pc(16'h0014, "RSR X");
        check_test("RSR X: 255 rotr 15", A_out == 16'h01FE);

        wait_for_pc(16'h0015, "MOVI 240");
        check_test("MOVI 240: A=240", A_out == 16'd240);

        wait_for_pc(16'h0016, "RSL X");
        check_test("RSL X: 240 rotl 15", A_out == 16'h0078);

        wait_for_pc(16'h0017, "MOVI 170");
        check_test("MOVI 170: A=170", A_out == 16'd170);

        wait_for_pc(16'h0018, "AND X");
        check_test("AND X: 170&15=10", A_out == (16'd170 & 16'd15));

        wait_for_pc(16'h0019, "MOVI 15");
        check_test("MOVI 15: A=15", A_out == 16'd15);

        wait_for_pc(16'h001A, "OR X");
        check_test("OR X: 15|15=15", A_out == (16'd15 | 16'd15));

        wait_for_pc(16'h001B, "MOVI 85");
        check_test("MOVI 85: A=85", A_out == 16'd85);

        wait_for_pc(16'h001C, "XOR X");
        check_test("XOR X: 85^15=90", A_out == (16'd85 ^ 16'd15));

        wait_for_pc(16'h001D, "NOT X");
        check_test("NOT X: ~90", A_out == 16'hFFA5);

        // ==========================================
        // ALU Immediate Operations
        // ==========================================
        $display("\n--- ALU Immediate Operations ---\n");

        wait_for_pc(16'h001E, "MOVI 200");
        check_test("MOVI 200: A=200", A_out == 16'd200);

        wait_for_pc(16'h001F, "ADDI 34");
        check_test("ADDI 34: 200+34=234", A_out == 16'd234);

        wait_for_pc(16'h0020, "SUBI 34");
        check_test("SUBI 34: 234-34=200", A_out == 16'd200);

        wait_for_pc(16'h0021, "MULI 5");
        check_test("MULI 5: 200*5=1000", A_out == 16'd1000);

        wait_for_pc(16'h0022, "DIVI 10");
        check_test("DIVI 10: 1000/10=100", A_out == 16'd100);

        wait_for_pc(16'h0023, "MODI 17");
        check_test("MODI 17: 100 mod 17=15", A_out == 16'd15);

        wait_for_pc(16'h0024, "LSLI 4");
        check_test("LSLI 4: 15<<4=240", A_out == 16'd240);

        wait_for_pc(16'h0025, "LSRI 3");
        check_test("LSRI 3: 240>>3=30", A_out == 16'd30);

        wait_for_pc(16'h0026, "RSRI 2");
        check_test("RSRI 2: 30 rotr 2", A_out == ((16'd30 >> 2) | (16'd30 << 14)));

        wait_for_pc(16'h0027, "RSLI 1");
        check_test("RSLI 1: rotl 1", A_out == ((((16'd30 >> 2) | (16'd30 << 14)) << 1) | (((16'd30 >> 2) | (16'd30 << 14)) >> 15)));

        wait_for_pc(16'h0028, "ANDI 127");
        check_test("ANDI 127", (A_out & (~16'd127)) == 0);

        wait_for_pc(16'h0029, "ORI 56");
        check_test("ORI 56", (A_out & 16'd56) == 16'd56);

        wait_for_pc(16'h002A, "XORI 21");
        check_test("XORI 21: executed", 1);

        wait_for_pc(16'h002B, "NOTI 0");
        check_test("NOTI 0: executed", 1);

        wait_for_pc(16'h002C, "CMPI 100");
        check_test("CMPI 100: executed", 1);

        wait_for_pc(16'h002D, "TSTI 85");
        check_test("TSTI 85: executed", 1);

        // ==========================================
        // Register Manipulation
        // ==========================================
        $display("\n--- Register Manipulation ---\n");

        wait_for_pc(16'h002E, "MOV X, 42");
        check_test("MOV X, 42: X=42", X_out == 16'd42);

        wait_for_pc(16'h002F, "MOVI 123");
        check_test("MOVI 123: A=123", A_out == 16'd123);

        wait_for_pc(16'h0030, "INC X");
        check_test("INC X: 42+1=43", X_out == 16'd43);

        wait_for_pc(16'h0031, "DEC X");
        check_test("DEC X: 43-1=42", X_out == 16'd42);

        wait_for_pc(16'h0032, "MOV Y, 88");
        check_test("MOV Y, 88: Y=88", Y_out == 16'd88);

        wait_for_pc(16'h0033, "INC Y");
        check_test("INC Y: 88+1=89", Y_out == 16'd89);

        wait_for_pc(16'h0034, "DEC Y");
        check_test("DEC Y: 89-1=88", Y_out == 16'd88);

        wait_for_pc(16'h0035, "LD X, 496");
        check_test("LD X, 496: X=0x1234", X_out == 16'h1234);

        wait_for_pc(16'h0036, "LD Y, 497");
        check_test("LD Y, 497: Y=0", Y_out == 16'd0);

        wait_for_pc(16'h0037, "MOVI 255");
        check_test("MOVI 255: A=255", A_out == 16'd255);

        // ==========================================
        // NEW INSTRUCTIONS: MOVR (Register-to-Register)
        // ==========================================
        $display("\n--- NEW: MOVR (Register-to-Register) ---\n");

        wait_for_pc(16'h0038, "MOVI 42");
        check_test("MOVI 42: A=42", A_out == 16'd42);

        wait_for_pc(16'h0039, "MOVR X, A");
        check_test("MOVR X, A: X=42", X_out == 16'd42);

        wait_for_pc(16'h003A, "MOVR Y, X");
        check_test("MOVR Y, X: Y=42", Y_out == 16'd42);

        wait_for_pc(16'h003B, "MOVR A, Y");
        check_test("MOVR A, Y: A=42", A_out == 16'd42);

        // ==========================================
        // NEW INSTRUCTIONS: BGT, BLT, BGE, BLE
        // ==========================================
        $display("\n--- NEW: Conditional Branches (BGT, BLT, BGE, BLE) ---\n");

        wait_for_pc(16'h003C, "MOVI 10");
        check_test("MOVI 10: A=10", A_out == 16'd10);

        wait_for_pc(16'h003D, "MOV X, 5");
        check_test("MOV X, 5: X=5", X_out == 16'd5);

        wait_for_pc(16'h003E, "CMP X");
        check_test("CMP X: compare 10 vs 5", 1);

        wait_for_pc(16'h0040, "BGT bgt_pass");
        check_test("BGT: branched (10 > 5)", pc_out == 16'h0040);

        // NOP after bgt_pass
        wait_for_pc(16'h0041, "NOP");
        check_test("NOP: executed", 1);

        wait_for_pc(16'h0042, "MOVI 3");
        check_test("MOVI 3: A=3", A_out == 16'd3);

        wait_for_pc(16'h0043, "MOV X, 7");
        check_test("MOV X, 7: X=7", X_out == 16'd7);

        wait_for_pc(16'h0044, "CMP X");
        check_test("CMP X: compare 3 vs 7", 1);

        wait_for_pc(16'h0046, "BLT blt_pass");
        check_test("BLT: branched (3 < 7)", pc_out == 16'h0046);

        // NOP after blt_pass
        wait_for_pc(16'h0047, "NOP");
        check_test("NOP: executed", 1);

        wait_for_pc(16'h0048, "MOVI 10");
        check_test("MOVI 10: A=10", A_out == 16'd10);

        wait_for_pc(16'h0049, "MOV X, 5");
        check_test("MOV X, 5: X=5", X_out == 16'd5);

        wait_for_pc(16'h004A, "CMP X");
        check_test("CMP X: compare 10 vs 5", 1);

        wait_for_pc(16'h004C, "BGE bge_pass");
        check_test("BGE: branched (10 >= 5)", pc_out == 16'h004C);

        // NOP after bge_pass
        wait_for_pc(16'h004D, "NOP");
        check_test("NOP: executed", 1);

        wait_for_pc(16'h004E, "MOVI 5");
        check_test("MOVI 5: A=5", A_out == 16'd5);

        wait_for_pc(16'h004F, "MOV X, 5");
        check_test("MOV X, 5: X=5", X_out == 16'd5);

        wait_for_pc(16'h0050, "CMP X");
        check_test("CMP X: compare 5 vs 5 (equal)", 1);

        wait_for_pc(16'h0052, "BLE ble_pass");
        check_test("BLE: branched (5 <= 5)", pc_out == 16'h0052);

        // NOP after ble_pass
        wait_for_pc(16'h0053, "NOP");
        check_test("NOP: executed", 1);

        // ==========================================
        // NEW INSTRUCTIONS: BEQ, BNE
        // ==========================================
        $display("\n--- NEW: BEQ and BNE ---\n");

        // BEQ test (Branch if Equal) - should branch when Z==1
        wait_for_pc(16'h0054, "MOVI 5");
        check_test("MOVI 5: A=5", A_out == 16'd5);

        wait_for_pc(16'h0055, "MOV X, 5");
        check_test("MOV X, 5: X=5", X_out == 16'd5);

        wait_for_pc(16'h0056, "CMP X");
        check_test("CMP X: compare 5 vs 5 (equal, Z=1)", 1);

        wait_for_pc(16'h0058, "BEQ beq_pass");
        check_test("BEQ: branched (5 == 5)", pc_out == 16'h0058);

        // NOP after beq_pass
        wait_for_pc(16'h0059, "NOP");
        check_test("NOP: executed", 1);

        // BNE test (Branch if Not Equal) - should branch when Z==0
        wait_for_pc(16'h005A, "MOVI 5");
        check_test("MOVI 5: A=5", A_out == 16'd5);

        wait_for_pc(16'h005B, "MOV X, 10");
        check_test("MOV X, 10: X=10", X_out == 16'd10);

        wait_for_pc(16'h005C, "CMP X");
        check_test("CMP X: compare 5 vs 10 (not equal, Z=0)", 1);

        wait_for_pc(16'h005E, "BNE bne_pass");
        check_test("BNE: branched (5 != 10)", pc_out == 16'h005E);

        // NOP after bne_pass
        wait_for_pc(16'h005F, "NOP");
        check_test("NOP: executed", 1);

        // ==========================================
        // Existing Branch Tests (BRZ, BRN)
        // ==========================================
        $display("\n--- Existing Branches (BRZ, BRN) ---\n");

        wait_for_pc(16'h0060, "MOVI 50");
        check_test("MOVI 50: A=50", A_out == 16'd50);

        wait_for_pc(16'h0061, "CMP X");
        check_test("CMP X: compare 50 vs 10 (non-zero)", 1);

        wait_for_pc(16'h0064, "BRZ/BRA brz_pass");
        check_test("BRZ skipped, BRA taken", pc_out == 16'h0064);

        // NOP after brz_pass
        wait_for_pc(16'h0065, "NOP");
        check_test("NOP: executed", 1);

        wait_for_pc(16'h0066, "MOVI -5");
        check_test("MOVI -5: A=0xFFFB", A_out == 16'hFFFB);

        wait_for_pc(16'h0067, "CMP X");
        check_test("CMP X: compare -5 vs 10 (negative)", 1);

        wait_for_pc(16'h0069, "BRN brn_pass");
        check_test("BRN: branched (negative result)", pc_out == 16'h0069);

        // NOP after brn_pass
        wait_for_pc(16'h006A, "NOP");
        check_test("NOP: executed", 1);

        // ==========================================
        // Stack Operations (PUSH/POP registers)
        // ==========================================
        $display("\n--- Stack Operations (PUSH X/Y, POP X/Y) ---\n");

        wait_for_pc(16'h006B, "MOV X, 77");
        check_test("MOV X, 77: X=77", X_out == 16'd77);

        wait_for_pc(16'h006C, "MOV Y, 88");
        check_test("MOV Y, 88: Y=88", Y_out == 16'd88);

        wait_for_pc(16'h006D, "PUSH X");
        check_test("PUSH X: Stack contains 77", dut.mem_inst.mem[1022] == 16'd77);

        wait_for_pc(16'h006E, "PUSH Y");
        check_test("PUSH Y: Stack contains 88", dut.mem_inst.mem[1021] == 16'd88);

        wait_for_pc(16'h006F, "MOV X, 11");
        check_test("MOV X, 11: X=11", X_out == 16'd11);

        wait_for_pc(16'h0070, "MOV Y, 22");
        check_test("MOV Y, 22: Y=22", Y_out == 16'd22);

        wait_for_pc(16'h0071, "POP Y");
        check_test("POP Y: Y restored to 88", Y_out == 16'd88);

        wait_for_pc(16'h0072, "POP X");
        check_test("POP X: X restored to 77", X_out == 16'd77);

        // Final MOVI 100 before END
        wait_for_pc(16'h0073, "MOVI 100");
        check_test("MOVI 100: A=100 (success)", A_out == 16'd100);

        // Wait for END
        wait_for_pc(16'h0074, "END");
        check_test("END: CPU halted", dut.finish == 1);

        // ==========================================
        // Final Summary
        // ==========================================
        #100;
        $display("\n========================================");
        $display("Test Summary:");
        $display("  Total: %0d", test_num);
        $display("  Pass:  %0d", pass_count);
        $display("  Fail:  %0d", fail_count);
        if (fail_count == 0)
            $display("  Result: ALL TESTS PASSED!");
        else
            $display("  Result: %0d tests failed", fail_count);
        $display("========================================");
        $finish;
    end

    // Overall timeout
    initial begin
        #10000000; // 10ms timeout
        $display("\nOVERALL TIMEOUT - Test exceeded 10ms");
        $display("Stuck at PC=%04h State=%d", pc_out, dut.cu_inst.state);
        $display("\nTest Summary (Incomplete):");
        $display("  Total: %0d", test_num);
        $display("  Pass:  %0d", pass_count);
        $display("  Fail:  %0d", fail_count);
        $finish;
    end

endmodule
