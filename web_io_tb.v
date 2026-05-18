`timescale 1ns/1ps

module web_io_tb;
    reg clk;
    reg rst_n;
    reg [15:0] kbd_data_in;
    reg kbd_strobe;

    wire [15:0] disp_data_out;
    wire        disp_we;
    wire [15:0] pc_out, A_out, X_out, Y_out, dr_out, mem_out;
    wire        mining_done;

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
        .ext_irq(1'b0),
        .kbd_data_in(kbd_data_in),
        .kbd_strobe(kbd_strobe),
        .disp_data_out(disp_data_out),
        .disp_we(disp_we)
    );

    initial begin clk = 0; forever #5 clk = ~clk; end

    // Print each character written to the display port
    always @(posedge clk) begin
        if (disp_we)
            $display("DISP:%c", disp_data_out[7:0]);
    end

    // Keyboard feeder: reads kbd_input.txt, strobes one char at a time.
    // After each strobe it waits for the CPU to read KBD_DATA (kbd_irq goes low),
    // with a 2000-cycle hard cap so programs that ignore keyboard don't deadlock.
    reg  [7:0]  kbd_chars [0:255];
    integer     kbd_count, kbd_idx, kbd_fd, fchar, wait_cyc;

    initial begin
        kbd_count = 0;
        kbd_fd    = $fopen("kbd_input.txt", "r");
        if (kbd_fd != 0) begin
            fchar = $fgetc(kbd_fd);
            while (fchar >= 0 && kbd_count < 256) begin
                kbd_chars[kbd_count] = fchar[7:0];
                kbd_count = kbd_count + 1;
                fchar     = $fgetc(kbd_fd);
            end
            $fclose(kbd_fd);
        end
    end

    initial begin
        kbd_data_in = 16'h0000;
        kbd_strobe  = 1'b0;
        kbd_idx     = 0;

        @(posedge rst_n);       // wait for reset to release
        repeat(4) @(posedge clk);

        while (kbd_idx < kbd_count) begin
            // Assert strobe for exactly one clock
            @(posedge clk);
            #1;
            kbd_data_in = {8'h00, kbd_chars[kbd_idx]};
            kbd_strobe  = 1'b1;
            @(posedge clk);
            #1;
            kbd_strobe  = 1'b0;
            kbd_idx     = kbd_idx + 1;

            // Wait for CPU to consume character (kbd_irq goes low), cap at 2000 cycles
            wait_cyc = 0;
            while (dut.io_ctrl_inst.kbd_irq == 1'b1 && wait_cyc < 2000) begin
                @(posedge clk);
                wait_cyc = wait_cyc + 1;
            end

            // Brief inter-character gap (8 cycles)
            repeat(8) @(posedge clk);
        end
    end

    // Main: wait for END instruction, then signal done
    initial begin
        rst_n = 0;
        #20;
        rst_n = 1;
        wait (dut.finish == 1);
        #20;
        $display("SIM_DONE");
        $finish;
    end

    // Hard timeout: 5 ms (500 000 cycles at 100 MHz)
    initial begin
        #5000000;
        $display("SIM_TIMEOUT");
        $finish;
    end

endmodule
