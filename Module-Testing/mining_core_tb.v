`timescale 1ns / 1ns

module mining_core_tb;

reg clk, rst_n, start;
reg [15:0] data_in, nonce_in, target;
wire [15:0] hash_out, result_nonce;
wire done;

integer test_count = 0;
integer pass_count = 0;
integer fail_count = 0;

mining_core CUT (
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .data_in(data_in),
    .nonce_in(nonce_in),
    .target(target),
    .hash_out(hash_out),
    .result_nonce(result_nonce),
    .done(done)
);

task check_mining;
    input [511:0] test_name;
    input [15:0] exp_target;
    reg valid;
    begin
        test_count = test_count + 1;
        valid = done && (hash_out < exp_target);
        if (valid) begin
            $display("Test %2d PASS: %s", test_count, test_name);
            $display("  -> Nonce: %h, Hash: %h (< target %h)", result_nonce, hash_out, exp_target);
            pass_count = pass_count + 1;
        end else begin
            $display("Test %2d FAIL: %s", test_count, test_name);
            if (!done)
                $display("  -> ERROR: done not asserted");
            if (hash_out >= exp_target)
                $display("  -> ERROR: hash %h >= target %h", hash_out, exp_target);
            fail_count = fail_count + 1;
        end
    end
endtask

// Clock: 20ns period
initial begin
    clk = 0;
    forever #10 clk = ~clk;
end

initial begin
    rst_n = 1;
    start = 0;
    data_in = 0;
    nonce_in = 0;
    target = 0;
end

initial begin
    $display("========== Mining Core Test ==========");

    // Test 1: large target — any hash passes
    @(negedge clk); rst_n = 0;
    @(negedge clk); rst_n = 1; start = 1;
    data_in = 16'hAAAA;
    nonce_in = 16'h0000;
    target = 16'hFFFF;
    @(negedge clk); start = 0;

    @(posedge done);
    @ (negedge clk);
    check_mining("Target=0xFFFF (immediate)", 16'hFFFF);

    // Test 2: medium target
    @(negedge clk); rst_n = 0;
    @(negedge clk); rst_n = 1; start = 1;
    data_in = 16'h1234;
    nonce_in = 16'h0000;
    target = 16'h4000;
    @(negedge clk); start = 0;

    @(posedge done);
    @ (negedge clk);
    check_mining("Target=0x4000 (medium)", 16'h4000);

    // Test 3: start from non-zero nonce
    @(negedge clk); rst_n = 0;
    @(negedge clk); rst_n = 1; start = 1;
    data_in = 16'hABCD;
    nonce_in = 16'h00FF;
    target = 16'h7FFF;
    @(negedge clk); start = 0;

    @(posedge done);
    @ (negedge clk);
    check_mining("Nonce start=0x00FF", 16'h7FFF);

    $display("---------------------------------------");
    $display("Simulation complete");
    $display("Total: %d", test_count);
    $display("Pass:  %d", pass_count);
    $display("Fail:  %d", fail_count);
    $display("---------------------------------------");

    #100; $stop;
end

// Debug: print hash on every CHECK state
always @(posedge clk) begin
    if (CUT.state == 3)
        $display("[DEBUG] Nonce: %h | Hash: %h", CUT.current_nonce, hash_out);
end

endmodule
