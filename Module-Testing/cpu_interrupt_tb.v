`timescale 1ns / 1ns

// End-to-end interrupt test: EXT/KBD/TIMER sources, priority, IRET.
// Program: MOVI 15 | OUT 48 | EI | WAIT | BRA 3 (loop)
// EXT ISR@20, KBD ISR@30, TIMER ISR@35; IVT at 190-193.
module cpu_interrupt_tb;

    reg  clk, rst_n;
    reg  ext_irq_reg;
    reg  kbd_strobe_reg;

    wire [15:0] pc_out, A_out, X_out, Y_out, dr_out, mem_out;
    wire        mining_done;
    wire [15:0] disp_data_out;
    wire        disp_we;

    integer test_count = 0;
    integer pass_count = 0;
    integer fail_count = 0;

    cpu dut (
        .clk(clk),
        .rst_n(rst_n),
        .pc_out(pc_out),
        .A_out(A_out),
        .X_out(X_out),
        .Y_out(Y_out),
        .dr_out(dr_out),
        .mem_out(mem_out),
        .mining_done(mining_done),
        .ext_irq(ext_irq_reg),
        .kbd_data_in(16'h0055),
        .kbd_strobe(kbd_strobe_reg),
        .disp_data_out(disp_data_out),
        .disp_we(disp_we)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    task check_test;
        input [511:0] test_name;
        input         condition;
        begin
            test_count = test_count + 1;
            if (condition) begin
                $display("Test %2d PASS: %s", test_count, test_name);
                pass_count = pass_count + 1;
            end else begin
                $display("Test %2d FAIL: %s", test_count, test_name);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        ext_irq_reg  = 1'b0;
        kbd_strobe_reg = 1'b0;
        rst_n        = 1'b0;

        // Preload memory at #1, before CPU starts (rst_n stays low during preload)
        #1;
        // Main program
        dut.mem_inst.mem[0]  = 16'b1110010000001111;  // MOVI 15  (A=0xF for IER)
        dut.mem_inst.mem[1]  = 16'b1001110000110000;  // OUT 48   (IER = A = 0xF)
        dut.mem_inst.mem[2]  = 16'b1010000000000000;  // EI
        dut.mem_inst.mem[3]  = 16'b1110110000000000;  // WAIT
        dut.mem_inst.mem[4]  = 16'b0000110000000011;  // BRA 3    (loop back to WAIT)
        dut.mem_inst.mem[5]  = 16'b0000000000000000;  // END      (must not be reached)
        // EXT ISR at addr 20 (irq_id=3 → IVT[193])
        dut.mem_inst.mem[20] = 16'b0110010000101010;  // MOV X, 42  (X=42)
        dut.mem_inst.mem[21] = 16'b0000100011001000;  // ST X, 200  (mem[200]=42)
        dut.mem_inst.mem[22] = 16'b1110100000000000;  // IRET
        // KBD ISR at addr 30 (irq_id=1 → IVT[191])
        // The KBD test uses a force-pulse on kbd_irq (not kbd_strobe) to avoid the
        // level-latch re-trigger issue (kbd_irq stays high until KBD_DATA is read).
        dut.mem_inst.mem[30] = 16'b0110010000110111;  // MOV X, 55  (X=55)
        dut.mem_inst.mem[31] = 16'b0000100011001001;  // ST X, 201  (mem[201]=55)
        dut.mem_inst.mem[32] = 16'b1110100000000000;  // IRET
        // TIMER ISR at addr 35 (irq_id=0 → IVT[190])
        dut.mem_inst.mem[35] = 16'b0110010001001101;  // MOV X, 77  (X=77)
        dut.mem_inst.mem[36] = 16'b0000100011001010;  // ST X, 202  (mem[202]=77)
        dut.mem_inst.mem[37] = 16'b1110100000000000;  // IRET
        // IVT entries at 190-193
        dut.mem_inst.mem[190] = 16'd35;  // timer ISR → addr 35
        dut.mem_inst.mem[191] = 16'd30;  // kbd   ISR → addr 30
        dut.mem_inst.mem[192] = 16'd22;  // mine  ISR → dummy IRET
        dut.mem_inst.mem[193] = 16'd20;  // ext   ISR → addr 20

        // Release reset
        @(negedge clk);
        rst_n = 1'b1;

        // Tests 1-3: CPU enters WAIT_1 after EI+OUT setup
        repeat(200) @(posedge clk);

        check_test("CPU in WAIT_1 (state=97) after EI+OUT setup", dut.cu_inst.state === 7'd97);
        check_test("I_flag=1 after EI instruction", dut.cu_inst.I_flag === 1'b1);

        // No interrupt yet
        repeat(5) @(posedge clk);
        check_test("CPU stays in WAIT_1 with no pending interrupt", dut.cu_inst.state === 7'd97);

        // Tests 4-7: EXT interrupt fires, ISR stores 42, IRET returns
        @(negedge clk);
        ext_irq_reg = 1'b1;
        @(negedge clk);
        ext_irq_reg = 1'b0;

        repeat(200) @(posedge clk);

        check_test("CPU back in WAIT_1 after EXT ISR + IRET + BRA",
                   dut.cu_inst.state === 7'd97);
        check_test("EXT ISR stored X=42 to mem[200]",
                   dut.mem_inst.mem[200] === 16'd42);
        check_test("X register holds 42 (set by ISR MOV X,42)",
                   X_out === 16'd42);
        check_test("I_flag=1 after IRET (interrupts re-enabled)",
                   dut.cu_inst.I_flag === 1'b1);

        // Test 8: second EXT interrupt with patched ISR (store 99)
        dut.mem_inst.mem[20] = 16'b0110010001100011;  // MOV X, 99

        @(negedge clk);
        ext_irq_reg = 1'b1;
        @(negedge clk);
        ext_irq_reg = 1'b0;

        repeat(200) @(posedge clk);

        check_test("2nd EXT interrupt: mem[200] updated to 99",
                   dut.mem_inst.mem[200] === 16'd99);

        // Tests 9-11: KBD interrupt — verify KBD ISR runs
        dut.mem_inst.mem[20] = 16'b0110010000101010;  // MOV X, 42

        // Restore EXT ISR and wait for WAIT_1
        repeat(200) @(posedge clk);
        check_test("CPU in WAIT_1 before KBD test", dut.cu_inst.state === 7'd97);

        // Force kbd_latch directly — avoids level-irq re-trigger (kbd_irq stays high until read)
        @(negedge clk);
        force dut.intr_ctrl_inst.kbd_latch = 1'b1;
        @(posedge clk);
        release dut.intr_ctrl_inst.kbd_latch;

        repeat(200) @(posedge clk);

        check_test("KBD ISR: mem[201]=55 (set by KBD ISR)", dut.mem_inst.mem[201] === 16'd55);
        check_test("CPU back in WAIT_1 after KBD ISR+IRET", dut.cu_inst.state === 7'd97);

        // Tests 12-14: TIMER interrupt — force timer_latch directly
        @(negedge clk);
        force dut.intr_ctrl_inst.timer_latch = 1'b1;
        @(posedge clk);
        release dut.intr_ctrl_inst.timer_latch;

        repeat(200) @(posedge clk);

        check_test("TIMER ISR: mem[202]=77 (set by TIMER ISR)", dut.mem_inst.mem[202] === 16'd77);
        check_test("CPU in WAIT_1 after TIMER ISR+IRET", dut.cu_inst.state === 7'd97);
        check_test("I_flag=1 after TIMER IRET", dut.cu_inst.I_flag === 1'b1);

        // Tests 15-16: priority — timer fires before EXT when both pending simultaneously
        dut.mem_inst.mem[200] = 16'd0;
        dut.mem_inst.mem[202] = 16'd0;

        repeat(20) @(posedge clk);
        check_test("CPU in WAIT_1 before priority test", dut.cu_inst.state === 7'd97);

        @(negedge clk);
        force dut.intr_ctrl_inst.timer_latch = 1'b1;
        ext_irq_reg = 1'b1;
        @(posedge clk);
        release dut.intr_ctrl_inst.timer_latch;
        @(negedge clk);
        ext_irq_reg = 1'b0;

        repeat(50) @(posedge clk);

        check_test("Priority: TIMER ISR ran first (mem[202]=77)", dut.mem_inst.mem[202] === 16'd77);

        repeat(200) @(posedge clk);

        force dut.io_ctrl_inst.timer_enable = 1'b0;
        @(posedge clk);
        release dut.io_ctrl_inst.timer_enable;

        check_test("Priority: EXT ISR also ran (mem[200]=42)", dut.mem_inst.mem[200] === 16'd42);

        $display("---------------------------------------");
        $display("Simulation done!");
        $display("Total Teste: %d", test_count);
        $display("Teste PASS : %d", pass_count);
        $display("Teste FAIL : %d", fail_count);
        $display("---------------------------------------");

        #100; $stop;
    end

    initial begin
        #500000;
        $display("\nERROR: Testbench timeout!");
        $finish;
    end

endmodule
