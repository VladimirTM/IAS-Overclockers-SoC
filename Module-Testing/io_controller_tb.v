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

    // ---------------------------------------------------------------------------
    // Helper tasks
    // ---------------------------------------------------------------------------

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

    // Write one word to an I/O port (takes effect on next posedge)
    task io_write;
        input [9:0]  addr;
        input [15:0] data;
        begin
            @(negedge clk);
            io_addr    = addr;
            io_data_in = data;
            io_we      = 1'b1;
            io_re      = 1'b0;
            @(posedge clk);  // write registered on this edge
            #1;
            io_we = 1'b0;
        end
    endtask

    // Read one word from an I/O port (combinational; sample after negedge)
    task io_read;
        input  [9:0]  addr;
        output [15:0] data;
        begin
            @(negedge clk);
            io_addr = addr;
            io_re   = 1'b1;
            io_we   = 1'b0;
            #5;
            data = io_data_out;  // combinational output valid immediately
            @(posedge clk);      // side-effects (e.g. clear latch) on this edge
            #1;
            io_re = 1'b0;
        end
    endtask

    // ---------------------------------------------------------------------------
    // Clock
    // ---------------------------------------------------------------------------
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 10 ns period
    end

    // ---------------------------------------------------------------------------
    // Stimulus
    // ---------------------------------------------------------------------------
    reg [15:0] rd;  // scratch read register

    initial begin
        // ---- Reset ----
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

        $display("========== INCEPERE TESTARE IO CONTROLLER ==========");

        // ================================================================
        // SECTIUNEA 1: Reset state
        // ================================================================
        $display("--- Reset State ---");

        check("Reset: kbd_irq = 0",    kbd_irq    === 1'b0);
        check("Reset: timer_irq = 0",  timer_irq  === 1'b0);
        check("Reset: mining_irq = 0", mining_irq === 1'b0);
        check("Reset: ier_out = 0",    ier_out    === 4'h0);

        // ================================================================
        // SECTIUNEA 2: Keyboard — latch si IRQ
        // ================================================================
        $display("--- Keyboard ---");

        // Strobe cu date
        @(negedge clk);
        kbd_data_in = 16'h0041;  // 'A'
        kbd_strobe  = 1'b1;
        @(posedge clk); #1;
        kbd_strobe  = 1'b0;

        check("KBD: kbd_irq setat dupa strobe", kbd_irq === 1'b1);

        // Citeste KBD_STATUS (port 1): bit 0 = data ready
        @(negedge clk);
        io_addr = 10'd1; io_re = 1'b1; #5;
        check("KBD_STATUS: bit0=1 (data ready)", io_data_out[0] === 1'b1);
        @(posedge clk); #1; io_re = 1'b0;

        // Citeste KBD_DATA (port 0): trebuie sa returneze 'A' si sa stearga IRQ
        @(negedge clk);
        io_addr = 10'd0; io_re = 1'b1; #5;
        check("KBD_DATA: valoare corecta (0x0041)", io_data_out === 16'h0041);
        @(posedge clk); #1; io_re = 1'b0;

        // Un ciclu dupa citire IRQ trebuie sa fie 0
        @(negedge clk); #1;
        check("KBD: kbd_irq sters dupa citire KBD_DATA", kbd_irq === 1'b0);

        // KBD_STATUS trebuie sa fie 0 acum
        @(negedge clk);
        io_addr = 10'd1; io_re = 1'b1; #5;
        check("KBD_STATUS: bit0=0 (buffer gol)", io_data_out[0] === 1'b0);
        @(posedge clk); #1; io_re = 1'b0;

        // Al doilea strobe cu data diferita
        @(negedge clk);
        kbd_data_in = 16'h005A;  // 'Z'
        kbd_strobe  = 1'b1;
        @(posedge clk); #1;
        kbd_strobe  = 1'b0;

        @(negedge clk);
        io_addr = 10'd0; io_re = 1'b1; #5;
        check("KBD_DATA: al doilea caracter (0x005A)", io_data_out === 16'h005A);
        @(posedge clk); #1; io_re = 1'b0;

        // ================================================================
        // SECTIUNEA 3: Display
        // ================================================================
        $display("--- Display ---");

        // Scrie la DISP_DATA (port 16)
        @(negedge clk);
        io_addr    = 10'd16;
        io_data_in = 16'h0048;  // 'H'
        io_we      = 1'b1; io_re = 1'b0;
        @(posedge clk); #1;
        io_we = 1'b0;

        check("DISP: disp_we puls dupa scriere", disp_we === 1'b1);
        check("DISP: disp_data_out = 0x0048", disp_data_out === 16'h0048);

        // Urmatorul ciclu disp_we trebuie sa dispara (puls de un ciclu)
        @(posedge clk); #1;
        check("DISP: disp_we revine la 0", disp_we === 1'b0);

        // DISP_STATUS (port 17): mereu 0 (niciodata ocupat)
        @(negedge clk);
        io_addr = 10'd17; io_re = 1'b1; #5;
        check("DISP_STATUS: mereu 0", io_data_out === 16'h0000);
        @(posedge clk); #1; io_re = 1'b0;

        // ================================================================
        // SECTIUNEA 4: IER (Interrupt Enable Register)
        // ================================================================
        $display("--- IER ---");

        // Scrie IER = 0xF (toate intreruperile activate)
        @(negedge clk);
        io_addr    = 10'd48;
        io_data_in = 16'h000F;
        io_we      = 1'b1; io_re = 1'b0;
        @(posedge clk); #1;
        io_we = 1'b0;

        check("IER: ier_out = 0xF dupa scriere", ier_out === 4'hF);

        // Citeste IER (port 48): trebuie sa returneze 0xF
        @(negedge clk);
        io_addr = 10'd48; io_re = 1'b1; #5;
        check("IER: citire returneaza 0x000F", io_data_out === 16'h000F);
        @(posedge clk); #1; io_re = 1'b0;

        // Scrie IER = 0x5 (bitmask partial)
        @(negedge clk);
        io_addr    = 10'd48;
        io_data_in = 16'h0005;
        io_we      = 1'b1; io_re = 1'b0;
        @(posedge clk); #1;
        io_we = 1'b0;

        check("IER: ier_out = 0x5 dupa suprascriere", ier_out === 4'h5);

        // Reseteaza IER la 0
        @(negedge clk);
        io_addr    = 10'd48;
        io_data_in = 16'h0000;
        io_we      = 1'b1; io_re = 1'b0;
        @(posedge clk); #1;
        io_we = 1'b0;

        // ================================================================
        // SECTIUNEA 5: Mining accelerator
        // ================================================================
        $display("--- Mining Accelerator ---");

        // Simuleaza rising edge pe mining_done_in
        @(negedge clk);
        mining_hash_in  = 16'hCAFE;
        mining_nonce_in = 16'h1234;
        mining_done_in  = 1'b1;
        @(posedge clk); #1;  // rising edge: latch rezultate

        check("MINE: mining_irq setat dupa done", mining_irq === 1'b1);

        // Citeste MINE_HASH (port 64)
        @(negedge clk);
        io_addr = 10'd64; io_re = 1'b1; #5;
        check("MINE_HASH: valoare corecta (0xCAFE)", io_data_out === 16'hCAFE);
        @(posedge clk); #1; io_re = 1'b0;

        // Dupa citire port 64, mining_irq trebuie sters
        @(negedge clk); #1;
        check("MINE: mining_irq sters dupa citire MINE_HASH", mining_irq === 1'b0);

        // Citeste MINE_NONCE (port 65) — IRQ deja sters, nonce inca disponibil
        mining_done_in = 1'b0;
        @(negedge clk);
        io_addr = 10'd65; io_re = 1'b1; #5;
        check("MINE_NONCE: valoare corecta (0x1234)", io_data_out === 16'h1234);
        @(posedge clk); #1; io_re = 1'b0;

        // Al doilea eveniment mining: hash si nonce diferite
        @(negedge clk);
        mining_hash_in  = 16'hDEAD;
        mining_nonce_in = 16'hBEEF;
        mining_done_in  = 1'b1;
        @(posedge clk); #1;

        check("MINE: mining_irq reactivat la al doilea done", mining_irq === 1'b1);

        @(negedge clk);
        io_addr = 10'd64; io_re = 1'b1; #5;
        check("MINE_HASH: al doilea rezultat (0xDEAD)", io_data_out === 16'hDEAD);
        @(posedge clk); #1; io_re = 1'b0;

        mining_done_in = 1'b0;
        @(negedge clk);
        io_addr = 10'd65; io_re = 1'b1; #5;
        check("MINE_NONCE: al doilea nonce (0xBEEF)", io_data_out === 16'hBEEF);
        @(posedge clk); #1; io_re = 1'b0;

        // ================================================================
        // SECTIUNEA 6: IFR (Interrupt Flag Register, port 49)
        // ================================================================
        $display("--- IFR ---");

        // Curata starea: citeste portul 64 pentru a sterge mining_irq
        @(negedge clk);
        io_addr = 10'd64; io_re = 1'b1;
        @(posedge clk); #1; io_re = 1'b0;

        // Forteaza un kbd_irq
        @(negedge clk);
        kbd_data_in = 16'h0058;  // 'X'
        kbd_strobe  = 1'b1;
        @(posedge clk); #1;
        kbd_strobe  = 1'b0;

        // Citeste IFR: bit0=timer, bit1=kbd, bit2=mining
        @(negedge clk);
        io_addr = 10'd49; io_re = 1'b1; #5;
        check("IFR: bit1 (kbd_irq) setat", io_data_out[1] === 1'b1);
        check("IFR: bit2 (mining_irq) = 0", io_data_out[2] === 1'b0);
        @(posedge clk); #1; io_re = 1'b0;

        // Sterge kbd_irq prin citire KBD_DATA
        @(negedge clk);
        io_addr = 10'd0; io_re = 1'b1;
        @(posedge clk); #1; io_re = 1'b0;

        @(negedge clk);
        io_addr = 10'd49; io_re = 1'b1; #5;
        check("IFR: toate bitii 0 dupa stergere", io_data_out[2:0] === 3'b000);
        @(posedge clk); #1; io_re = 1'b0;

        // ================================================================
        // SECTIUNEA 7: Timer
        // ================================================================
        $display("--- Timer ---");

        timer_irq_seen = 1'b0;

        // Seteaza perioada la 4 cicluri (port 33)
        @(negedge clk);
        io_addr    = 10'd33;
        io_data_in = 16'h0004;
        io_we      = 1'b1; io_re = 1'b0;
        @(posedge clk); #1; io_we = 1'b0;

        // Verifica TIMER_PERIOD citit inapoi (port 33)
        @(negedge clk);
        io_addr = 10'd33; io_re = 1'b1; #5;
        check("TIMER_PERIOD: citire returneaza 4", io_data_out === 16'h0004);
        @(posedge clk); #1; io_re = 1'b0;

        // Activa timerul one-shot (port 32, bit0=enable, bit1=periodic=0)
        @(negedge clk);
        io_addr    = 10'd32;
        io_data_in = 16'h0001;  // enable=1, periodic=0
        io_we      = 1'b1; io_re = 1'b0;
        @(posedge clk); #1; io_we = 1'b0;

        // Verifica TIMER_CTRL citit inapoi (port 32)
        @(negedge clk);
        io_addr = 10'd32; io_re = 1'b1; #5;
        check("TIMER_CTRL: enable=1 periodic=0", io_data_out[1:0] === 2'b01);
        @(posedge clk); #1; io_re = 1'b0;

        // Asteapta suficiente cicluri pentru a se declansa IRQ (period+2 marje)
        repeat(8) @(posedge clk);
        #1;

        check("TIMER: timer_irq_seen dupa period cicluri", timer_irq_seen === 1'b1);

        // Verifica TIMER_COUNT (port 34) — dupa one-shot se opreste la valoare >= period
        @(negedge clk);
        io_addr = 10'd34; io_re = 1'b1; #5;
        check("TIMER_COUNT: citire nu blocheaza", io_data_out !== 16'hXXXX);
        @(posedge clk); #1; io_re = 1'b0;

        // Reseteaza si testeaza timer periodic (period=3)
        timer_irq_seen = 1'b0;

        @(negedge clk);
        io_addr    = 10'd33;
        io_data_in = 16'h0003;
        io_we      = 1'b1; io_re = 1'b0;
        @(posedge clk); #1; io_we = 1'b0;

        @(negedge clk);
        io_addr    = 10'd32;
        io_data_in = 16'h0003;  // enable=1, periodic=1
        io_we      = 1'b1; io_re = 1'b0;
        @(posedge clk); #1; io_we = 1'b0;

        // Asteapta doua perioade (3+3=6 cicluri + marje)
        repeat(10) @(posedge clk); #1;

        check("TIMER: periodic — timer_irq_seen dupa mai multe perioade", timer_irq_seen === 1'b1);

        // Dezactiveaza timerul
        @(negedge clk);
        io_addr    = 10'd32;
        io_data_in = 16'h0000;
        io_we      = 1'b1; io_re = 1'b0;
        @(posedge clk); #1; io_we = 1'b0;

        // ================================================================
        // SECTIUNEA 8: Adrese necunoscute — trebuie sa returneze 0
        // ================================================================
        $display("--- Adrese necunoscute ---");

        @(negedge clk);
        io_addr = 10'd100; io_re = 1'b1; #5;
        check("Adresa necunoscuta 100: returneaza 0", io_data_out === 16'h0000);
        @(posedge clk); #1; io_re = 1'b0;

        @(negedge clk);
        io_addr = 10'd511; io_re = 1'b1; #5;
        check("Adresa necunoscuta 511: returneaza 0", io_data_out === 16'h0000);
        @(posedge clk); #1; io_re = 1'b0;

        // ================================================================
        // Raport Final
        // ================================================================
        $display("---------------------------------------");
        $display("Simulare Finalizata!");
        $display("Total Teste : %d", test_count);
        $display("Teste PASS  : %d", pass_count);
        $display("Teste FAIL  : %d", fail_count);
        $display("---------------------------------------");

        #50; $stop;
    end

    // Timeout
    initial begin
        #50000;
        $display("\nERROR: Testbench timeout!");
        $finish;
    end

endmodule
