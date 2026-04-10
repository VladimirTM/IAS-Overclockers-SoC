// I/O Controller: keyboard, display, timer, and mining peripherals over a 10-bit port bus
module io_controller (
    input             clk,
    input             rst_n,
    // CPU I/O bus
    input  [9:0]      io_addr,
    input  [15:0]     io_data_in,
    input             io_we,
    input             io_re,
    output reg [15:0] io_data_out,
    // Keyboard peripheral
    input  [15:0]     kbd_data_in,
    input             kbd_strobe,
    // Display peripheral
    output reg [15:0] disp_data_out,
    output reg        disp_we,
    // Mining accelerator (read-only ports 64-65)
    input  [15:0]     mining_hash_in,
    input  [15:0]     mining_nonce_in,
    input             mining_done_in,
    // Interrupt outputs
    output reg        kbd_irq,
    output reg        timer_irq,
    output reg        mining_irq,
    output reg [3:0]  ier_out
);

    // I/O port addresses (10-bit)
    localparam [9:0]
        KBD_DATA     = 10'd0,   // read clears latch + kbd_irq
        KBD_STATUS   = 10'd1,   // bit 0 = key ready
        DISP_DATA    = 10'd16,  // write pulses disp_we
        DISP_STATUS  = 10'd17,
        TIMER_CTRL   = 10'd32,  // bit0=enable, bit1=periodic
        TIMER_PERIOD = 10'd33,  // write also resets counter
        TIMER_COUNT  = 10'd34,
        IER_ADDR     = 10'd48,  // interrupt enable [3:0]
        IFR_ADDR     = 10'd49,  // interrupt flags  [2]=mining [1]=kbd [0]=timer
        MINE_HASH    = 10'd64,  // read clears mining_irq
        MINE_NONCE   = 10'd65;

    // ---- Keyboard registers ----
    reg [15:0] kbd_latch;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            kbd_latch <= 16'h0000;
            kbd_irq   <= 1'b0;
        end else if (kbd_strobe) begin
            kbd_latch <= kbd_data_in;
            kbd_irq   <= 1'b1;
        end else if (io_re && io_addr == KBD_DATA) begin
            kbd_latch <= 16'h0000;
            kbd_irq   <= 1'b0;
        end
    end

    // ---- Timer ----
    reg [15:0] timer_count;
    reg [15:0] timer_period;
    reg        timer_enable;
    reg        timer_periodic;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            timer_count    <= 16'h0000;
            timer_period   <= 16'hFFFF;
            timer_enable   <= 1'b0;
            timer_periodic <= 1'b0;
            timer_irq      <= 1'b0;
        end else begin
            timer_irq <= 1'b0;

            if (io_we && io_addr == TIMER_CTRL) begin
                timer_enable   <= io_data_in[0];
                timer_periodic <= io_data_in[1];
            end

            if (io_we && io_addr == TIMER_PERIOD) begin
                timer_period <= io_data_in;
                timer_count  <= 16'h0000;
            end

            if (timer_enable) begin
                if (timer_count == timer_period) begin
                    timer_irq <= 1'b1;
                    if (timer_periodic)
                        timer_count <= 16'h0000;
                    else
                        timer_enable <= 1'b0;
                end else begin
                    timer_count <= timer_count + 1'b1;
                end
            end
        end
    end

    // ---- Mining result latch ----
    reg [15:0] mining_hash_latch;
    reg [15:0] mining_nonce_latch;
    reg        mining_done_prev;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mining_hash_latch  <= 16'h0000;
            mining_nonce_latch <= 16'h0000;
            mining_irq         <= 1'b0;
            mining_done_prev   <= 1'b0;
        end else begin
            mining_done_prev <= mining_done_in;
            if (mining_done_in && !mining_done_prev) begin  // mining_done rising edge
                mining_hash_latch  <= mining_hash_in;
                mining_nonce_latch <= mining_nonce_in;
                mining_irq         <= 1'b1;
            end else if (io_re && (io_addr == MINE_HASH || io_addr == MINE_NONCE)) begin  // read clears irq
                mining_irq <= 1'b0;
            end
        end
    end

    // ---- IER register (port 48) ----
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            ier_out <= 4'b0000;
        else if (io_we && io_addr == IER_ADDR)
            ier_out <= io_data_in[3:0];
    end

    // ---- Display (port 16): single-cycle disp_we pulse ----
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            disp_data_out <= 16'h0000;
            disp_we       <= 1'b0;
        end else begin
            disp_we <= 1'b0;
            if (io_we && io_addr == DISP_DATA) begin
                disp_data_out <= io_data_in;
                disp_we       <= 1'b1;
            end
        end
    end

    // Combinational read — io_data_out valid same cycle as io_re
    always @(*) begin
        io_data_out = 16'h0000;
        if (io_re) begin
            case (io_addr)
                KBD_DATA:     io_data_out = kbd_latch;
                KBD_STATUS:   io_data_out = {15'b0, kbd_irq};
                DISP_STATUS:  io_data_out = 16'h0000;
                TIMER_CTRL:   io_data_out = {14'b0, timer_periodic, timer_enable};
                TIMER_PERIOD: io_data_out = timer_period;
                TIMER_COUNT:  io_data_out = timer_count;
                IER_ADDR:     io_data_out = {12'b0, ier_out};
                IFR_ADDR:     io_data_out = {13'b0, mining_irq, kbd_irq, timer_irq};
                MINE_HASH:    io_data_out = mining_hash_latch;
                MINE_NONCE:   io_data_out = mining_nonce_latch;
                default:      io_data_out = 16'h0000;
            endcase
        end
    end

endmodule
