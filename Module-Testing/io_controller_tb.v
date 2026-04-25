`timescale 1ns / 1ns

// io_controller_tb: Tests for keyboard, display, timer, mining, and IER/IFR registers
module io_controller_tb;

    reg         clk, rst_n;
    reg  [9:0]  io_addr;
    reg  [15:0] io_data_in;
    reg         io_we, io_re;
    wire [15:0] io_data_out;

    // Keyboard peripheral
    reg  [15:0] kbd_data_in;
    reg         kbd_strobe;

    // Display peripheral
    wire [15:0] disp_data_out;
    wire        disp_we;

    // Mining accelerator
    reg  [15:0] mining_hash_in;
    reg  [15:0] mining_nonce_in;
    reg         mining_done_in;

    // Interrupt outputs
    wire        kbd_irq;
    wire        timer_irq;
    wire        mining_irq;
    wire [3:0]  ier_out;

    integer test_count = 0;
    integer pass_count = 0;
    integer fail_count = 0;

    // Latch to capture single-cycle timer_irq pulse
    reg timer_irq_seen;
    always @(posedge clk)
        if (timer_irq) timer_irq_seen <= 1'b1;

    io_controller CUT (
        .clk(clk),
        .rst_n(rst_n),
        .io_addr(io_addr),
        .io_data_in(io_data_in),
        .io_we(io_we),
        .io_re(io_re),
        .io_data_out(io_data_out),
        .kbd_data_in(kbd_data_in),
        .kbd_strobe(kbd_strobe),
        .disp_data_out(disp_data_out),
        .disp_we(disp_we),
        .mining_hash_in(mining_hash_in),
        .mining_nonce_in(mining_nonce_in),
        .mining_done_in(mining_done_in),
        .kbd_irq(kbd_irq),
        .timer_irq(timer_irq),
        .mining_irq(mining_irq),
        .ier_out(ier_out)
    );

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

    // Write one word to an I/O port
    task io_write;
        input [9:0]  addr;
        input [15:0] data;
        begin
            @(negedge clk);
            io_addr    = addr;
            io_data_in = data;
            io_we      = 1'b1;
            io_re      = 1'b0;
            @(posedge clk);
            #1;
            io_we = 1'b0;
        end
    endtask

    // Read one word from an I/O port (combinational)
    task io_read;
        input  [9:0]  addr;
        output [15:0] data;
        begin
            @(negedge clk);
            io_addr = addr;
            io_re   = 1'b1;
            io_we   = 1'b0;
            #5;
            data = io_data_out;
            @(posedge clk);
            #1;
            io_re = 1'b0;
        end
    endtask

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    reg [15:0] rd;

    initial begin
        rst_n          = 1'b0;
        io_addr        = 10'h000;
        io_data_in     = 16'h0000;
        io_we          = 1'b0;
        io_re          = 1'b0;
        kbd_data_in    = 16'h0000;
        kbd_strobe     = 1'b0;
        mining_hash_in = 16'h0000;
        mining_nonce_in= 16'h0000;
        mining_done_in = 1'b0;
        timer_irq_seen = 1'b0;

        @(negedge clk); @(negedge clk);
        rst_n = 1'b1;
        @(negedge clk);

        // Section 1: reset state

        check("Reset: kbd_irq = 0",    kbd_irq    === 1'b0);
        check("Reset: timer_irq = 0",  timer_irq  === 1'b0);
        check("Reset: mining_irq = 0", mining_irq === 1'b0);
        check("Reset: ier_out = 0",    ier_out    === 4'h0);

        // Section 2: keyboard latch and IRQ
        @(negedge clk);
        kbd_data_in = 16'h0041;  // 'A'
        kbd_strobe  = 1'b1;
        @(posedge clk); #1;
        kbd_strobe  = 1'b0;

        check("KBD: kbd_irq set after strobe", kbd_irq === 1'b1);

        @(negedge clk);
        io_addr = 10'd1; io_re = 1'b1; #5;
        check("KBD_STATUS: bit0=1 (data ready)", io_data_out[0] === 1'b1);
        @(posedge clk); #1; io_re = 1'b0;

        @(negedge clk);
        io_addr = 10'd0; io_re = 1'b1; #5;
        check("KBD_DATA: correct value (0x0041)", io_data_out === 16'h0041);
        @(posedge clk); #1; io_re = 1'b0;

        @(negedge clk); #1;
        check("KBD: kbd_irq cleared after KBD_DATA read", kbd_irq === 1'b0);

        @(negedge clk);
        io_addr = 10'd1; io_re = 1'b1; #5;
        check("KBD_STATUS: bit0=0 (buffer empty)", io_data_out[0] === 1'b0);
        @(posedge clk); #1; io_re = 1'b0;

        @(negedge clk);
        kbd_data_in = 16'h005A;
        kbd_strobe  = 1'b1;
        @(posedge clk); #1;
        kbd_strobe  = 1'b0;

        @(negedge clk);
        io_addr = 10'd0; io_re = 1'b1; #5;
        check("KBD_DATA: second character (0x005A)", io_data_out === 16'h005A);
        @(posedge clk); #1; io_re = 1'b0;

        // Section 3: display
        @(negedge clk);
        io_addr    = 10'd16;
        io_data_in = 16'h0048;
        io_we      = 1'b1; io_re = 1'b0;
        @(posedge clk); #1;
        io_we = 1'b0;

        check("DISP: disp_we pulses on write", disp_we === 1'b1);
        check("DISP: disp_data_out = 0x0048", disp_data_out === 16'h0048);

        @(posedge clk); #1;
        check("DISP: disp_we returns to 0", disp_we === 1'b0);

        @(negedge clk);
        io_addr = 10'd17; io_re = 1'b1; #5;
        check("DISP_STATUS: always 0", io_data_out === 16'h0000);
        @(posedge clk); #1; io_re = 1'b0;

        // Section 4: IER (Interrupt Enable Register)
        @(negedge clk);
        io_addr    = 10'd48;
        io_data_in = 16'h000F;
        io_we      = 1'b1; io_re = 1'b0;
        @(posedge clk); #1;
        io_we = 1'b0;

        check("IER: ier_out = 0xF after write", ier_out === 4'hF);

        @(negedge clk);
        io_addr = 10'd48; io_re = 1'b1; #5;
        check("IER: read returns 0x000F", io_data_out === 16'h000F);
        @(posedge clk); #1; io_re = 1'b0;

        @(negedge clk);
        io_addr    = 10'd48;
        io_data_in = 16'h0005;
        io_we      = 1'b1; io_re = 1'b0;
        @(posedge clk); #1;
        io_we = 1'b0;

        check("IER: ier_out = 0x5 after overwrite", ier_out === 4'h5);

        // Section 4b: IER masking — io_controller raises all IRQs; masking is downstream
        // IER = 4'b0101: timer(bit0)=1, kbd(bit1)=0, mining(bit2)=1, ext(bit3)=0
        @(negedge clk);
        io_addr    = 10'd48;
        io_data_in = 16'h0005;  // IER = 4'b0101
        io_we      = 1'b1; io_re = 1'b0;
        @(posedge clk); #1;
        io_we = 1'b0;

        check("IER mask 0b0101: ier_out = 4'h5", ier_out === 4'h5);

        @(negedge clk);
        kbd_data_in = 16'hABCD;
        kbd_strobe  = 1'b1;
        @(posedge clk); #1;
        kbd_strobe  = 1'b0;

        check("IER mask: kbd_irq fires (masking done downstream)", kbd_irq === 1'b1);

        @(negedge clk);
        mining_hash_in  = 16'h1111;
        mining_nonce_in = 16'h2222;
        mining_done_in  = 1'b1;
        @(posedge clk); #1;
        mining_done_in  = 1'b0;

        check("IER mask: mining_irq fires (IER[2]=1)", mining_irq === 1'b1);

        @(negedge clk);
        io_addr = 10'd49; io_re = 1'b1; #5;
        check("IER mask: IFR[1] (kbd) = 1", io_data_out[1] === 1'b1);
        check("IER mask: IFR[2] (mining) = 1", io_data_out[2] === 1'b1);
        @(posedge clk); #1; io_re = 1'b0;

        check("IER mask: ier_out still 4'h5 (unchanged)", ier_out === 4'h5);

        @(negedge clk);
        io_addr = 10'd0; io_re = 1'b1;  // read KBD_DATA to clear kbd_irq
        @(posedge clk); #1; io_re = 1'b0;
        @(negedge clk);
        io_addr = 10'd64; io_re = 1'b1;
        @(posedge clk); #1; io_re = 1'b0;

        @(negedge clk);
        io_addr    = 10'd48;
        io_data_in = 16'h0000;
        io_we      = 1'b1; io_re = 1'b0;
        @(posedge clk); #1;
        io_we = 1'b0;

        // Section 5: mining accelerator
        @(negedge clk);
        mining_hash_in  = 16'hCAFE;
        mining_nonce_in = 16'h1234;
        mining_done_in  = 1'b1;
        @(posedge clk); #1;

        check("MINE: mining_irq set after done", mining_irq === 1'b1);

        @(negedge clk);
        io_addr = 10'd64; io_re = 1'b1; #5;
        check("MINE_HASH: correct value (0xCAFE)", io_data_out === 16'hCAFE);
        @(posedge clk); #1; io_re = 1'b0;

        @(negedge clk); #1;
        check("MINE: mining_irq cleared after MINE_HASH read", mining_irq === 1'b0);

        mining_done_in = 1'b0;
        @(negedge clk);
        io_addr = 10'd65; io_re = 1'b1; #5;
        check("MINE_NONCE: correct value (0x1234)", io_data_out === 16'h1234);
        @(posedge clk); #1; io_re = 1'b0;

        @(negedge clk);
        mining_hash_in  = 16'hDEAD;
        mining_nonce_in = 16'hBEEF;
        mining_done_in  = 1'b1;
        @(posedge clk); #1;

        check("MINE: mining_irq re-asserted on second done", mining_irq === 1'b1);

        @(negedge clk);
        io_addr = 10'd64; io_re = 1'b1; #5;
        check("MINE_HASH: second result (0xDEAD)", io_data_out === 16'hDEAD);
        @(posedge clk); #1; io_re = 1'b0;

        mining_done_in = 1'b0;
        @(negedge clk);
        io_addr = 10'd65; io_re = 1'b1; #5;
        check("MINE_NONCE: second nonce (0xBEEF)", io_data_out === 16'hBEEF);
        @(posedge clk); #1; io_re = 1'b0;

        // Section 6: IFR (Interrupt Flag Register, port 49)
        @(negedge clk);
        io_addr = 10'd64; io_re = 1'b1;
        @(posedge clk); #1; io_re = 1'b0;

        @(negedge clk);
        kbd_data_in = 16'h0058;
        kbd_strobe  = 1'b1;
        @(posedge clk); #1;
        kbd_strobe  = 1'b0;

        @(negedge clk);
        io_addr = 10'd49; io_re = 1'b1; #5;
        check("IFR: bit1 (kbd_irq) set", io_data_out[1] === 1'b1);
        check("IFR: bit2 (mining_irq) = 0", io_data_out[2] === 1'b0);
        @(posedge clk); #1; io_re = 1'b0;

        @(negedge clk);
        io_addr = 10'd0; io_re = 1'b1;
        @(posedge clk); #1; io_re = 1'b0;

        @(negedge clk);
        io_addr = 10'd49; io_re = 1'b1; #5;
        check("IFR: all bits 0 after clear", io_data_out[2:0] === 3'b000);
        @(posedge clk); #1; io_re = 1'b0;

        // Section 7: timer
        timer_irq_seen = 1'b0;

        @(negedge clk);
        io_addr    = 10'd33;
        io_data_in = 16'h0004;
        io_we      = 1'b1; io_re = 1'b0;
        @(posedge clk); #1; io_we = 1'b0;

        @(negedge clk);
        io_addr = 10'd33; io_re = 1'b1; #5;
        check("TIMER_PERIOD: read returns 4", io_data_out === 16'h0004);
        @(posedge clk); #1; io_re = 1'b0;

        @(negedge clk);
        io_addr    = 10'd32;
        io_data_in = 16'h0001;
        io_we      = 1'b1; io_re = 1'b0;
        @(posedge clk); #1; io_we = 1'b0;

        @(negedge clk);
        io_addr = 10'd32; io_re = 1'b1; #5;
        check("TIMER_CTRL: enable=1 periodic=0", io_data_out[1:0] === 2'b01);
        @(posedge clk); #1; io_re = 1'b0;

        repeat(8) @(posedge clk);
        #1;

        check("TIMER: timer_irq_seen after period cycles", timer_irq_seen === 1'b1);

        @(negedge clk);
        io_addr = 10'd34; io_re = 1'b1; #5;
        check("TIMER_COUNT: read does not block", io_data_out !== 16'hXXXX);
        @(posedge clk); #1; io_re = 1'b0;

        timer_irq_seen = 1'b0;

        @(negedge clk);
        io_addr    = 10'd33;
        io_data_in = 16'h0003;
        io_we      = 1'b1; io_re = 1'b0;
        @(posedge clk); #1; io_we = 1'b0;

        @(negedge clk);
        io_addr    = 10'd32;
        io_data_in = 16'h0003;
        io_we      = 1'b1; io_re = 1'b0;
        @(posedge clk); #1; io_we = 1'b0;

        repeat(10) @(posedge clk); #1;

        check("TIMER: periodic — timer_irq_seen after multiple periods", timer_irq_seen === 1'b1);

        @(negedge clk);
        io_addr    = 10'd32;
        io_data_in = 16'h0000;
        io_we      = 1'b1; io_re = 1'b0;
        @(posedge clk); #1; io_we = 1'b0;

        // Section 8: unknown addresses return 0
        @(negedge clk);
        io_addr = 10'd100; io_re = 1'b1; #5;
        check("Unknown addr 100: returns 0", io_data_out === 16'h0000);
        @(posedge clk); #1; io_re = 1'b0;

        @(negedge clk);
        io_addr = 10'd511; io_re = 1'b1; #5;
        check("Unknown addr 511: returns 0", io_data_out === 16'h0000);
        @(posedge clk); #1; io_re = 1'b0;

        // Section 9: timer disabled mid-count — IRQ must not fire

        timer_irq_seen = 1'b0;

        @(negedge clk);
        io_addr    = 10'd33;
        io_data_in = 16'h0014;
        io_we      = 1'b1; io_re = 1'b0;
        @(posedge clk); #1; io_we = 1'b0;

        @(negedge clk);
        io_addr    = 10'd32;
        io_data_in = 16'h0001;
        io_we      = 1'b1; io_re = 1'b0;
        @(posedge clk); #1; io_we = 1'b0;

        repeat(10) @(posedge clk);

        @(negedge clk);
        io_addr    = 10'd32;
        io_data_in = 16'h0000;
        io_we      = 1'b1; io_re = 1'b0;
        @(posedge clk); #1; io_we = 1'b0;

        repeat(30) @(posedge clk);
        #1;

        check("Timer disabled mid-count: timer_irq_seen = 0", timer_irq_seen === 1'b0);

        // Section 10: MINE_NONCE read (port 65) also clears mining_irq
        @(negedge clk);
        mining_hash_in  = 16'hABCD;
        mining_nonce_in = 16'h5678;
        mining_done_in  = 1'b1;
        @(posedge clk); #1;

        check("MINE: mining_irq set after done pulse", mining_irq === 1'b1);

        mining_done_in = 1'b0;

        @(negedge clk);
        io_addr = 10'd65; io_re = 1'b1; #5;
        check("MINE_NONCE read: data correct (0x5678)", io_data_out === 16'h5678);
        @(posedge clk); #1; io_re = 1'b0;

        @(negedge clk); #1;
        check("MINE_NONCE read clears mining_irq", mining_irq === 1'b0);

        $display("---------------------------------------");
        $display("Simulation done!");
        $display("Total Teste : %d", test_count);
        $display("Teste PASS  : %d", pass_count);
        $display("Teste FAIL  : %d", fail_count);
        $display("---------------------------------------");

        #50; $stop;
    end

    initial begin
        #50000;
        $display("\nERROR: Testbench timeout!");
        $finish;
    end

endmodule
