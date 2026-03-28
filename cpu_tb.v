`timescale 1ns/1ps

module cpu_tb;
    // Clock and reset signals
    reg clk;
    reg rst_n;

    // Loop variable for memory dump
    integer i;

    // CPU output wires
    wire [15:0] pc_out, A_out, X_out, Y_out, dr_out, mem_out;
    wire mining_done;
    wire [15:0] disp_data_out;
    wire disp_we;

    // Instantiate CPU
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
        .kbd_data_in(16'h0000),
        .kbd_strobe(1'b0),
        .disp_data_out(disp_data_out),
        .disp_we(disp_we)
    );

    // Clock generation: 10ns period (100MHz)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Main test sequence
    initial begin
        $display("\n========================================");
        $display("        CPU TESTBENCH - START");
        $display("========================================\n");

        // Apply reset
        $display("Applying reset...");
        rst_n = 0;
        #20;
        rst_n = 1;
        $display("Reset released. CPU running...\n");

        // Wait for CPU to halt
        wait(dut.finish == 1);
        #20;  // Wait a bit after halt signal

        // Print comprehensive register report
        $display("\n╔════════════════════════════════════════╗");
        $display("║         CPU EXECUTION COMPLETE         ║");
        $display("╚════════════════════════════════════════╝\n");

        $display("┌─────────────────────────────────────────┐");
        $display("│         REGISTER STATE REPORT           │");
        $display("├─────────────────────────────────────────┤");

        // Program Counter and Instruction Register
        $display("│ Program Counter (PC):                   │");
        $display("│   Hex: 0x%04h     Dec: %5d          │", pc_out, pc_out);
        $display("├─────────────────────────────────────────┤");
        $display("│ Instruction Register (IR):              │");
        $display("│   Hex: 0x%04h     Bin: %016b │", dut.ir_out, dut.ir_out);
        $display("│   Opcode: 0x%02h (%6b)                │", dut.opcode, dut.opcode);
        $display("│   RegAddr: %b                            │", dut.regaddr);
        $display("├─────────────────────────────────────────┤");

        // General Purpose Registers
        $display("│ General Purpose Registers:              │");
        $display("│   X:  0x%04h   Dec: %6d (s: %6d) │", X_out, X_out, $signed(X_out));
        $display("│   Y:  0x%04h   Dec: %6d (s: %6d) │", Y_out, Y_out, $signed(Y_out));
        $display("│   A:  0x%04h   Dec: %6d (s: %6d) │", A_out, A_out, $signed(A_out));
        $display("├─────────────────────────────────────────┤");

        // Address and Data Registers
        $display("│ Address & Data Registers:               │");
        $display("│   AR: 0x%04h   Dec: %5d            │", dut.ar_out, dut.ar_out);
        $display("│   DR: 0x%04h   Dec: %6d (s: %6d) │", dr_out, dr_out, $signed(dr_out));
        $display("│   MEM: 0x%04h  Dec: %6d (s: %6d) │", mem_out, mem_out, $signed(mem_out));
        $display("├─────────────────────────────────────────┤");

        // Stack Pointer
        $display("│ Stack Pointer (SP):                     │");
        $display("│   Hex: 0x%04h     Dec: %5d          │", dut.sp_out, dut.sp_out);
        $display("├─────────────────────────────────────────┤");

        // Flags
        $display("│ Status Flags:                           │");
        $display("│   Zero (Z):        %b                    │", dut.Z_flag);
        $display("│   Negative (N):    %b                    │", dut.N_flag);
        $display("│   Carry (C):       %b                    │", dut.C_flag);
        $display("│   Overflow (O):    %b                    │", dut.O_flag);
        $display("│   Flag Value: %b%b%b%b                     │", dut.Z_flag, dut.N_flag, dut.C_flag, dut.O_flag);
        $display("├─────────────────────────────────────────┤");

        // Mining status
        $display("│ Mining Status:                          │");
        $display("│   Mining Done:     %b                    │", mining_done);
        $display("└─────────────────────────────────────────┘\n");

        // Memory dump (first 16 locations and stack area)
        $display("┌─────────────────────────────────────────┐");
        $display("│          MEMORY DUMP (Sample)           │");
        $display("├─────────────────────────────────────────┤");
        $display("│ First 16 memory locations:              │");
        for (i = 0; i < 16; i = i + 1) begin
            $display("│   [0x%03h] = 0x%04h                     │", i, dut.mem_inst.mem[i]);
        end

        $display("├─────────────────────────────────────────┤");
        $display("│ Stack area (0x3F0 - 0x3FF):            │");
        for (i = 16'h3F0; i < 16'h400; i = i + 1) begin
            if (dut.mem_inst.mem[i] != 16'h0000) begin
                $display("│   [0x%03h] = 0x%04h  %s            │", i, dut.mem_inst.mem[i],
                        (i == dut.sp_out) ? "<- SP" : "      ");
            end
        end
        $display("└─────────────────────────────────────────┘\n");

        // Execution statistics
        $display("┌─────────────────────────────────────────┐");
        $display("│        EXECUTION STATISTICS             │");
        $display("├─────────────────────────────────────────┤");
        $display("│ Simulation time:  %0t ns              │", $time);
        $display("│ Clock cycles:     %0d                  │", $time / 10);
        $display("│ Final PC:         0x%04h                 │", pc_out);
        $display("│ Halted:           %s                   │", dut.finish ? "YES" : "NO ");
        $display("│ Control State:    %0d                    │", dut.cu_inst.state);
        $display("└─────────────────────────────────────────┘\n");

        $display("========================================");
        $display("        TESTBENCH COMPLETE");
        $display("========================================\n");

        $finish;
    end

    // Timeout watchdog (prevents infinite loops)
    initial begin
        #1000000;  // 1ms timeout
        $display("\n╔════════════════════════════════════════╗");
        $display("║   ERROR: SIMULATION TIMEOUT!           ║");
        $display("╠════════════════════════════════════════╣");
        $display("║ CPU did not halt within timeout period ║");
        $display("╚════════════════════════════════════════╝\n");

        $display("Current State:");
        $display("  PC:    0x%04h", pc_out);
        $display("  A:     0x%04h", A_out);
        $display("  X:     0x%04h", X_out);
        $display("  Y:     0x%04h", Y_out);
        $display("  State: %0d", dut.cu_inst.state);
        $display("  Finish: %b", dut.finish);
        $display("  Opcode: 0x%02h\n", dut.opcode);

        $finish;
    end

    // Optional: Waveform dump for debugging
    initial begin
        $dumpfile("cpu_tb.vcd");
        $dumpvars(0, cpu_tb);
    end

    // Optional: Monitor PC changes during execution
    always @(posedge clk) begin
        if (dut.cu_inst.state == 0 && dut.ldIR) begin
            $display("[%0t] PC=0x%04h  Executing: 0x%04h (Opcode: 0x%02h)  A=0x%04h X=0x%04h Y=0x%04h",
                    $time, pc_out, mem_out, mem_out[15:10], A_out, X_out, Y_out);
        end
    end

endmodule
