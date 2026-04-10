// Interrupt Controller — 4-source fixed-priority interrupt controller
// Priority: TIMER(0) > KBD(1) > MINE(2) > EXT(3)
// intr_pending and irq_id are combinational outputs.
// I_flag gating is done externally in the CU at INTR_CHECK state.
module interrupt_controller (
    input        clk,
    input        rst_n,
    // IRQ sources: timer_irq is a single-cycle pulse; kbd/mining/ext are level signals
    input        timer_irq,
    input        kbd_irq,
    input        mining_irq,
    input        ext_irq,
    input  [3:0] ier,       // Interrupt Enable Register: bit0=TIMER,1=KBD,2=MINE,3=EXT
    input        I_flag,    // CPU interrupt-enable flag (received; gating is done in CU)
    input        intr_ack,  // CU asserts for one cycle in INTR_SAVE_1 to clear winning IRQ
    output reg       intr_pending,
    output reg [1:0] irq_id    // 0=TIMER, 1=KBD, 2=MINE, 3=EXT
);

    reg timer_latch, kbd_latch, mine_latch, ext_latch;

    // Latch logic: set on source assertion, clear on ack of the winning source
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            timer_latch <= 1'b0;
            kbd_latch   <= 1'b0;
            mine_latch  <= 1'b0;
            ext_latch   <= 1'b0;
        end else begin
            if (timer_irq)   timer_latch <= 1'b1;
            if (kbd_irq)     kbd_latch   <= 1'b1;
            if (mining_irq)  mine_latch  <= 1'b1;
            if (ext_irq)     ext_latch   <= 1'b1;
            if (intr_ack) begin
                case (irq_id)
                    2'd0: timer_latch <= 1'b0;
                    2'd1: kbd_latch   <= 1'b0;
                    2'd2: mine_latch  <= 1'b0;
                    2'd3: ext_latch   <= 1'b0;
                endcase
            end
        end
    end

    // Combinational: mask latches against IER, then priority-encode
    wire [3:0] masked = {ext_latch & ier[3], mine_latch & ier[2],
                         kbd_latch & ier[1],  timer_latch & ier[0]};

    always @(*) begin
        intr_pending = |masked;
        if      (masked[0]) irq_id = 2'd0;  // TIMER — highest priority
        else if (masked[1]) irq_id = 2'd1;  // KBD
        else if (masked[2]) irq_id = 2'd2;  // MINE
        else                irq_id = 2'd3;  // EXT (or default when nothing pending)
    end

endmodule
