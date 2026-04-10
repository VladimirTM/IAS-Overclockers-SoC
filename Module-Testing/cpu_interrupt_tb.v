`timescale 1ns / 1ns

// cpu_interrupt_tb: End-to-end integration test for interrupt system (v3.1)
//
// Uses ext_irq (testbench-controlled pulse) as the interrupt source to avoid
// the level-latch re-trigger issue with KBD/MINE level signals.
// ext_irq → irq_id=3 → IVT[193] holds ISR address.
//
// Memory layout (preloaded at time #1):
//   0:  MOVI 15       A=0xF for IER
//   1:  OUT 48        IER = 0xF (all sources enabled)
//   2:  EI
//   3:  WAIT
//   4:  BRA 3         loop back to WAIT after IRET returns
//   5:  END           should never be reached
//   20: MOV X, 42     ISR: X=42
//   21: ST X, 200     mem[200] = 42
//   22: IRET
//   193: 20           IVT[3] = EXT ISR at addr 20
module cpu_interrupt_tb;

    reg  clk, rst_n;
    reg  ext_irq_reg;

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
        .kbd_data_in(16'h0000),
        .kbd_strobe(1'b0),
        .disp_data_out(disp_data_out),
        .disp_we(disp_we)
    );

    // -----------------------------------------------------------------------
    // Clock
    // -----------------------------------------------------------------------
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // -----------------------------------------------------------------------
    // Check helper
    // -----------------------------------------------------------------------
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

    // -----------------------------------------------------------------------
    // Main stimulus
    // -----------------------------------------------------------------------
    initial begin
        ext_irq_reg = 1'b0;
        rst_n       = 1'b0;

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
        // IVT entries at 190-193
        dut.mem_inst.mem[190] = 16'd22;  // timer ISR → dummy IRET
        dut.mem_inst.mem[191] = 16'd22;  // kbd   ISR → dummy IRET
        dut.mem_inst.mem[192] = 16'd22;  // mine  ISR → dummy IRET
        dut.mem_inst.mem[193] = 16'd20;  // ext   ISR → addr 20

        // Release reset
        @(negedge clk);
        rst_n = 1'b1;

        // -------------------------------------------------------------------
        // Tests 1-3: Setup executes and CPU enters WAIT_1
        // Allow 200 cycles for MOVI + OUT + EI + WAIT fetch
        // -------------------------------------------------------------------
        repeat(200) @(posedge clk);

        check_test("CPU in WAIT_1 (state=97) after EI+OUT setup", dut.cu_inst.state === 7'd97);
        check_test("I_flag=1 after EI instruction", dut.cu_inst.I_flag === 1'b1);

        // No interrupt yet — CPU should stay in WAIT_1
        repeat(5) @(posedge clk);
        check_test("CPU stays in WAIT_1 with no pending interrupt", dut.cu_inst.state === 7'd97);

        // -------------------------------------------------------------------
        // Tests 4-7: EXT interrupt fires, ISR stores 42, IRET returns
        // -------------------------------------------------------------------
        // Pulse ext_irq for one cycle — single pulse, no re-latch issue
        @(negedge clk);
        ext_irq_reg = 1'b1;
        @(negedge clk);
        ext_irq_reg = 1'b0;

        // Wait for: WAIT_1 exit + 9 save states + ISR(3 instr) + IRET + BRA + WAIT_1
        // Approximately: 1+9+21+9+5+5 = 50 cycles
        repeat(200) @(posedge clk);

        check_test("CPU back in WAIT_1 after EXT ISR + IRET + BRA",
                   dut.cu_inst.state === 7'd97);
        check_test("EXT ISR stored X=42 to mem[200]",
                   dut.mem_inst.mem[200] === 16'd42);
        check_test("X register holds 42 (set by ISR MOV X,42)",
                   X_out === 16'd42);
        check_test("I_flag=1 after IRET (interrupts re-enabled)",
                   dut.cu_inst.I_flag === 1'b1);

        // -------------------------------------------------------------------
        // Tests 8: Second interrupt cycle with different ISR result
        // Change ISR to store 99 instead (patch mem[20] MOV X,99)
        // -------------------------------------------------------------------
        // MOV X, 99: 011001 + 0 + 001100011 = 0110010001100011
        dut.mem_inst.mem[20] = 16'b0110010001100011;  // MOV X, 99

        @(negedge clk);
        ext_irq_reg = 1'b1;
        @(negedge clk);
        ext_irq_reg = 1'b0;

        repeat(200) @(posedge clk);

        check_test("2nd EXT interrupt: mem[200] updated to 99",
                   dut.mem_inst.mem[200] === 16'd99);

        // -------------------------------------------------------------------
        // Summary
        // -------------------------------------------------------------------
        $display("---------------------------------------");
        $display("Simulare Finalizata!");
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
