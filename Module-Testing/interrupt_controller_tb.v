`timescale 1ns / 1ns

// interrupt_controller_tb: Tests for 4-source priority interrupt controller
module interrupt_controller_tb;

    reg        clk, rst_n;
    reg        timer_irq, kbd_irq, mining_irq, ext_irq;
    reg  [3:0] ier;
    reg        I_flag;
    reg        intr_ack;

    wire       intr_pending;
    wire [1:0] irq_id;

    integer test_count = 0;
    integer pass_count = 0;
    integer fail_count = 0;

    interrupt_controller CUT (
        .clk(clk),
        .rst_n(rst_n),
        .timer_irq(timer_irq),
        .kbd_irq(kbd_irq),
        .mining_irq(mining_irq),
        .ext_irq(ext_irq),
        .ier(ier),
        .I_flag(I_flag),
        .intr_ack(intr_ack),
        .intr_pending(intr_pending),
        .irq_id(irq_id)
    );

    // -----------------------------------------------------------------------
    // Helper tasks
    // -----------------------------------------------------------------------

    task check;
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

    // Pulse an IRQ line for one clock cycle
    task pulse_irq;
        input which;   // 0=TIMER, 1=KBD, 2=MINE, 3=EXT
        begin
            @ (negedge clk);
            case (which)
                0: timer_irq   = 1;
                1: kbd_irq     = 1;
                2: mining_irq  = 1;
                3: ext_irq     = 1;
            endcase
            @ (negedge clk);
            case (which)
                0: timer_irq   = 0;
                1: kbd_irq     = 0;
                2: mining_irq  = 0;
                3: ext_irq     = 0;
            endcase
        end
    endtask

    // Send intr_ack for one clock cycle
    task do_ack;
        begin
            @ (negedge clk);
            intr_ack = 1;
            @ (negedge clk);
            intr_ack = 0;
        end
    endtask

    // -----------------------------------------------------------------------
    // Clock
    // -----------------------------------------------------------------------
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // -----------------------------------------------------------------------
    // Main test sequence
    // -----------------------------------------------------------------------
    initial begin
        // Initialise signals
        rst_n      = 1;
        timer_irq  = 0;
        kbd_irq    = 0;
        mining_irq = 0;
        ext_irq    = 0;
        ier        = 4'hF;  // all enabled by default
        I_flag     = 1;
        intr_ack   = 0;

        // ------------------------------------------------------------------
        // Test 1: Reset clears all latches
        // ------------------------------------------------------------------
        @ (negedge clk);
        rst_n = 0;
        @ (negedge clk);
        rst_n = 1;
        @ (negedge clk);
        check("Reset: intr_pending = 0", intr_pending == 1'b0);

        // ------------------------------------------------------------------
        // Test 2: TIMER pulse is latched
        // ------------------------------------------------------------------
        pulse_irq(0);
        @ (negedge clk);
        check("TIMER pulse latched: intr_pending = 1", intr_pending == 1'b1);
        check("TIMER pulse: irq_id = 0", irq_id == 2'd0);

        // ------------------------------------------------------------------
        // Test 3: intr_ack clears TIMER latch
        // ------------------------------------------------------------------
        do_ack();
        @ (negedge clk);
        check("TIMER ack: intr_pending cleared", intr_pending == 1'b0);

        // ------------------------------------------------------------------
        // Test 4: IER masking — TIMER fires but ier[0] = 0
        // ------------------------------------------------------------------
        ier = 4'hE;  // disable TIMER
        pulse_irq(0);
        @ (negedge clk);
        check("TIMER masked (ier[0]=0): intr_pending = 0", intr_pending == 1'b0);
        // Re-enable and ack to clear latch
        ier = 4'hF;
        @ (negedge clk);
        check("TIMER unmasked: intr_pending = 1", intr_pending == 1'b1);
        do_ack();
        @ (negedge clk);

        // ------------------------------------------------------------------
        // Test 5: KBD level signal — stays pending over multiple cycles
        // ------------------------------------------------------------------
        @ (negedge clk);
        kbd_irq = 1;
        @ (negedge clk); @ (negedge clk); @ (negedge clk);
        check("KBD level: intr_pending stays 1", intr_pending == 1'b1);
        check("KBD level: irq_id = 1", irq_id == 2'd1);

        // ------------------------------------------------------------------
        // Test 6: Priority — TIMER beats KBD when both pending
        // ------------------------------------------------------------------
        pulse_irq(0);   // pulse TIMER; kbd_irq still high
        @ (negedge clk);
        check("Priority: TIMER>KBD, irq_id = 0", irq_id == 2'd0);
        check("Priority: intr_pending = 1", intr_pending == 1'b1);

        // ------------------------------------------------------------------
        // Test 7: After acking TIMER, KBD becomes top
        // ------------------------------------------------------------------
        do_ack();        // ack TIMER (irq_id was 0)
        @ (negedge clk);
        check("After TIMER ack: irq_id = 1 (KBD)", irq_id == 2'd1);
        check("After TIMER ack: intr_pending still 1", intr_pending == 1'b1);

        // Clear KBD
        kbd_irq = 0;
        do_ack();        // ack KBD
        @ (negedge clk);
        check("After KBD ack: intr_pending = 0", intr_pending == 1'b0);

        // ------------------------------------------------------------------
        // Test 8: MINE source — irq_id = 2
        // ------------------------------------------------------------------
        @ (negedge clk);
        mining_irq = 1;
        @ (negedge clk);
        check("MINE pending: irq_id = 2", irq_id == 2'd2);
        mining_irq = 0;
        do_ack();
        @ (negedge clk);
        check("MINE ack: intr_pending = 0", intr_pending == 1'b0);

        // ------------------------------------------------------------------
        // Test 9: EXT source — irq_id = 3
        // ------------------------------------------------------------------
        @ (negedge clk);
        ext_irq = 1;
        @ (negedge clk);
        check("EXT pending: irq_id = 3", irq_id == 2'd3);
        ext_irq = 0;
        do_ack();
        @ (negedge clk);
        check("EXT ack: intr_pending = 0", intr_pending == 1'b0);

        // ------------------------------------------------------------------
        // Test 10: All 4 sources — TIMER wins
        // ------------------------------------------------------------------
        @ (negedge clk);
        kbd_irq    = 1;
        mining_irq = 1;
        ext_irq    = 1;
        pulse_irq(0);    // TIMER pulse
        @ (negedge clk);
        check("All 4 sources: irq_id = 0 (TIMER wins)", irq_id == 2'd0);
        // Clean up
        kbd_irq    = 0;
        mining_irq = 0;
        ext_irq    = 0;
        do_ack();
        @ (negedge clk); @ (negedge clk);
        // Ack remaining latches
        do_ack(); @ (negedge clk);
        do_ack(); @ (negedge clk);
        do_ack(); @ (negedge clk);

        // ------------------------------------------------------------------
        // Test 11: IER masking — all disabled
        // ------------------------------------------------------------------
        ier = 4'h0;
        pulse_irq(0);
        @ (negedge clk);
        check("All IER=0: intr_pending = 0 despite TIMER pulse", intr_pending == 1'b0);
        ier = 4'hF;
        // Clear residual latch
        do_ack();
        @ (negedge clk);

        // ------------------------------------------------------------------
        // Test 12: KBD re-asserts latch if still high after ack
        // ------------------------------------------------------------------
        @ (negedge clk);
        kbd_irq = 1;
        @ (negedge clk);
        intr_ack = 1;  // ack while kbd_irq still high
        @ (negedge clk);
        intr_ack = 0;
        @ (negedge clk);
        check("KBD re-latches if level still high after ack", intr_pending == 1'b1);
        kbd_irq = 0;
        do_ack();
        @ (negedge clk);
        check("KBD cleared after drop + ack", intr_pending == 1'b0);

        // ------------------------------------------------------------------
        // Test 13: KBD > MINE priority
        // ------------------------------------------------------------------
        @ (negedge clk);
        kbd_irq    = 1;
        mining_irq = 1;
        ier = 4'hF;
        @ (negedge clk);
        check("Priority KBD>MINE: irq_id = 1 (KBD wins)", irq_id == 2'd1);
        check("Priority KBD>MINE: intr_pending = 1", intr_pending == 1'b1);
        // Clean up: ack KBD, then MINE
        kbd_irq = 0;
        do_ack();   // ack KBD (irq_id=1)
        @ (negedge clk);
        check("After KBD ack: irq_id = 2 (MINE next)", irq_id == 2'd2);
        mining_irq = 0;
        do_ack();
        @ (negedge clk);
        check("After MINE ack: intr_pending = 0", intr_pending == 1'b0);

        // ------------------------------------------------------------------
        // Test 14: MINE > EXT priority
        // ------------------------------------------------------------------
        @ (negedge clk);
        mining_irq = 1;
        ext_irq    = 1;
        @ (negedge clk);
        check("Priority MINE>EXT: irq_id = 2 (MINE wins)", irq_id == 2'd2);
        check("Priority MINE>EXT: intr_pending = 1", intr_pending == 1'b1);
        // Clean up
        mining_irq = 0;
        do_ack();   // ack MINE (irq_id=2)
        @ (negedge clk);
        check("After MINE ack: irq_id = 3 (EXT next)", irq_id == 2'd3);
        ext_irq = 0;
        do_ack();
        @ (negedge clk);
        check("After EXT ack: intr_pending = 0", intr_pending == 1'b0);

        // ------------------------------------------------------------------
        // Test 15: All 4 sources — ack sequence yields correct irq_id order
        // ------------------------------------------------------------------
        @ (negedge clk);
        kbd_irq    = 1;
        mining_irq = 1;
        ext_irq    = 1;
        pulse_irq(0);    // TIMER pulse → all 4 latched
        @ (negedge clk);
        check("All 4: initial irq_id = 0 (TIMER highest)", irq_id == 2'd0);

        kbd_irq    = 0;
        mining_irq = 0;
        ext_irq    = 0;
        do_ack();   // ack TIMER
        @ (negedge clk);
        check("After TIMER ack: irq_id = 1 (KBD)", irq_id == 2'd1);
        do_ack();   // ack KBD
        @ (negedge clk);
        check("After KBD ack: irq_id = 2 (MINE)", irq_id == 2'd2);
        do_ack();   // ack MINE
        @ (negedge clk);
        check("After MINE ack: irq_id = 3 (EXT)", irq_id == 2'd3);
        do_ack();   // ack EXT
        @ (negedge clk);
        check("After all acks: intr_pending = 0", intr_pending == 1'b0);

        // ------------------------------------------------------------------
        // Summary
        // ------------------------------------------------------------------
        $display("---------------------------------------");
        $display("Simulare Finalizata!");
        $display("Total Teste: %d", test_count);
        $display("Teste PASS : %d", pass_count);
        $display("Teste FAIL : %d", fail_count);
        $display("---------------------------------------");

        #100; $stop;
    end

    initial begin
        #50000;
        $display("\nERROR: Testbench timeout!");
        $finish;
    end

endmodule
