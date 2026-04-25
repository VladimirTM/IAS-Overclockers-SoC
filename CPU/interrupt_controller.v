// Fixed-priority interrupt controller: TIMER(0)>KBD(1)>MINE(2)>EXT(3)
// intr_pending/irq_id are combinational; I_flag gating is in the CU.
module interrupt_controller (
    input        clk,
    input        rst_n,
    input        timer_irq,  // single-cycle pulse
    input        kbd_irq,
    input        mining_irq,
    input        ext_irq,
    input  [3:0] ier,       // bit0=TIMER,1=KBD,2=MINE,3=EXT
    input        I_flag,
    input        intr_ack,  // one-cycle pulse from CU (INTR_SAVE_1) clears winning IRQ
    output reg       intr_pending,
    output reg [1:0] irq_id,   // 0=TIMER, 1=KBD, 2=MINE, 3=EXT
    output           ext_pending  // raw EXT latch state for IFR register
);

    reg timer_latch, kbd_latch, mine_latch, ext_latch;

    // 2-FF synchroniser for asynchronous ext_irq to prevent metastability
    reg ext_irq_s1, ext_irq_sync;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ext_irq_s1   <= 1'b0;
            ext_irq_sync <= 1'b0;
        end else begin
            ext_irq_s1   <= ext_irq;
            ext_irq_sync <= ext_irq_s1;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            timer_latch <= 1'b0;
            kbd_latch   <= 1'b0;
            mine_latch  <= 1'b0;
            ext_latch   <= 1'b0;
        end else begin
            // Clear acked source first; set-on-same-cycle wins via last-NBA
            if (intr_ack) begin
                case (irq_id)
                    2'd0: timer_latch <= 1'b0;
                    2'd1: kbd_latch   <= 1'b0;
                    2'd2: mine_latch  <= 1'b0;
                    2'd3: ext_latch   <= 1'b0;
                endcase
            end
            if (timer_irq)   timer_latch <= 1'b1;
            if (kbd_irq)     kbd_latch   <= 1'b1;
            if (mining_irq)  mine_latch  <= 1'b1;
            if (ext_irq_sync) ext_latch  <= 1'b1;
        end
    end

    assign ext_pending = ext_latch;

    // Combinational priority encoder
    wire [3:0] masked = {ext_latch & ier[3], mine_latch & ier[2],
                         kbd_latch & ier[1],  timer_latch & ier[0]};

    always @(*) begin
        intr_pending = |masked;
        if      (masked[0]) irq_id = 2'd0;  // TIMER — highest priority
        else if (masked[1]) irq_id = 2'd1;  // KBD
        else if (masked[2]) irq_id = 2'd2;  // MINE
        else if (masked[3]) irq_id = 2'd3;  // EXT
        else                irq_id = 2'd0;  // nothing pending — safe default
    end

endmodule
